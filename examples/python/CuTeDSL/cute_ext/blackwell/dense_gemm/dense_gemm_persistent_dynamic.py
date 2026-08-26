# Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:

# 1. Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.

# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.

# 3. Neither the name of the copyright holder nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.

# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import argparse
import os
import sys

import torch
from typing import Type, Tuple

import cutlass
from cutlass.cute import experimental as cute_ext
from cutlass.base_dsl.typing import Numeric
from cutlass import cute as cute
from cutlass.cute.typing import Int128
from cutlass import utils
from cutlass import torch as cutlass_torch
import cutlass.utils.blackwell_helpers as sm100_utils
from cutlass import testing

if __name__ == "__main__":
    current_dir = os.path.dirname(os.path.abspath(__file__))
    sys.path.insert(0, os.path.join(current_dir, "../../../"))

from helpers import cli_helper as cli


"""
A high-performance cluster launch control(CLC) dynamic persistent batched dense GEMM example
for the NVIDIA Blackwell SM100 architecture using CUTE experimental API.

The CLC dynamic persistent scheduling technique performs dynamic loading balancing.
It has the ability to adapt available SMs rather than a statically selected number. To support this,
a new instruction is introduced to query for a new tile to compute. This new instruction is similar
to programmatic multicast in context of clusters in that the same starting tile ID for a given cluster
is broadcasted to all threadblocks in the cluster.
See `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#parallel-synchronization-and-communication-instructions-clusterlaunchcontrol-try-cancel>`.

This GEMM kernel combines:
- CLC dynamic persistent tile scheduling from examples/cute_ext/blackwell/dense_gemm/dense_gemm_persistent_dynamic.py
- Experimental IR-based API structure from examples/cute_ext/blackwell/dense_gemm/dense_gemm.py

Example usage:

.. code-block:: bash

    python examples/cute_ext/blackwell/dense_gemm/dense_gemm_persistent_dynamic.py  \
      --ab_dtype Float16 --c_dtype Float16 --acc_dtype Float32               \
      --mma_tiler_mn 256,128                                                  \
      --mnkl 8192,8192,8192,1
"""


def _compute_stages(
    tiled_mma: cute.TiledMma,
    mnk_tiler: Tuple[int, int, int],
    ab_dtype: Type[Numeric],
    tmem_output_dtype: Type[Numeric],
    mD: cute.Tensor,
    use_2cta_instrs: bool,
    smem_capacity: int,
    occupancy: int = 1,
    reserved_smem_bytes: int = 1024,
) -> Tuple[int, int, int]:
    """Computes the number of pipeline stages for the accumulator, mainloop (A/B),
    and TMA-store epilogue (C).

    Mirrors CuteDSL's two-pass allocation: first fixes A/B stages with 2 initial
    epilogue stages, then grows the epilogue stage count from leftover SMEM.

    :param tiled_mma: The tiled MMA object defining the core computation.
    :param mnk_tiler: The shape (M, N, K) of the MMA tiler.
    :param ab_dtype: Data type of operands A and B.
    :param tmem_output_dtype: Data type written to SMEM for TMA store.
    :param mD: Output tensor D, used to derive the epilogue layout.
    :param use_2cta_instrs: Whether 2-CTA MMA instructions are used.
    :param smem_capacity: Total available shared memory capacity in bytes.
    :param occupancy: Target number of CTAs per SM (default 1 for persistent kernels).
    :param reserved_smem_bytes: Bytes reserved for mbarriers and CLC response buffer.

    :return: (acc_stage, mainloop_stage, tma_store_stage)
    :rtype: Tuple[int, int, int]
    """
    acc_stage = 2
    initial_epi_stage = 2

    ab_bytes_per_stage = cute.size_in_bytes(
        ab_dtype,
        sm100_utils.make_smem_layout_a(tiled_mma, mnk_tiler, ab_dtype, 1),
    ) + cute.size_in_bytes(
        ab_dtype,
        sm100_utils.make_smem_layout_b(tiled_mma, mnk_tiler, ab_dtype, 1),
    )

    cta_tile_shape_mnk = cute.shape_div(
        mnk_tiler, (cute.size(tiled_mma.thr_id.shape), 1, 1)
    )
    d_layout = cutlass.tensor_utils.LayoutEnum.from_tensor(mD)
    epi_tile = sm100_utils.compute_epilogue_tile_shape(
        cta_tile_shape_mnk, use_2cta_instrs, d_layout, tmem_output_dtype
    )
    epi_bytes_per_stage = cute.size_in_bytes(
        tmem_output_dtype,
        sm100_utils.make_smem_layout_epi(tmem_output_dtype, d_layout, epi_tile, 1),
    )
    epi_bytes_initial = epi_bytes_per_stage * initial_epi_stage

    mainloop_stage = max(
        1,
        (smem_capacity // occupancy - epi_bytes_initial - reserved_smem_bytes)
        // ab_bytes_per_stage,
    )

    # Grow epilogue stages from leftover SMEM (mirrors CuteDSL refine step).
    leftover = (
        smem_capacity // occupancy
        - mainloop_stage * ab_bytes_per_stage
        - epi_bytes_initial
        - reserved_smem_bytes
    )
    tma_store_stage = initial_epi_stage + max(0, leftover // epi_bytes_per_stage)

    return acc_stage, mainloop_stage, tma_store_stage


class PersistentDenseGemmKernel:
    def __init__(
        self,
        mn_tiler: tuple[int, int],
        mma_dtype: tuple[Type[Numeric], Type[Numeric]],
        tmem_output_dtype: Type[Numeric],
        use_2cta_instrs: bool = False,
        cluster_shape_mn: tuple[int, int] = (1, 1),
        fallback_cluster_shape_mn: Tuple[int, int] = None,
        epilogue_op=lambda x: x,
    ):
        self.mn_tiler = mn_tiler
        self.ab_dtype, self.acc_dtype = mma_dtype
        self.tmem_output_dtype = tmem_output_dtype
        self.use_2cta_instrs = use_2cta_instrs
        self.swizzle_size = 1
        self.raster_along = "m"
        self.cluster_shape = (cluster_shape_mn[0], cluster_shape_mn[1], 1)
        cluster_shape_mn_selfcast = (2, 1) if use_2cta_instrs else (1, 1)
        # The TMA pipeline uses one op kind for both operand loads, so only use
        # multicast when A and B both have real cluster fan-out.
        self.use_tma_multicast = (
            cluster_shape_mn[0] > cluster_shape_mn_selfcast[0]
            and cluster_shape_mn[1] > cluster_shape_mn_selfcast[1]
        )
        self.epilogue_op = epilogue_op
        if fallback_cluster_shape_mn is None:
            self.fallback_cluster_shape = self.cluster_shape
            fallback_use_tma_multicast = self.use_tma_multicast
        else:
            self.fallback_cluster_shape = (
                fallback_cluster_shape_mn[0],
                fallback_cluster_shape_mn[1],
                1,
            )
            fallback_use_tma_multicast = (
                fallback_cluster_shape_mn[0] > cluster_shape_mn_selfcast[0]
                and fallback_cluster_shape_mn[1] > cluster_shape_mn_selfcast[1]
            )
        self.use_tma_multicast = self.use_tma_multicast or fallback_use_tma_multicast

    @cute.experimental.jit
    def __call__(self, mA: cute.Tensor, mB: cute.Tensor, mD: cute.Tensor):
        _tile_mn = cute.core._pack_shape((*self.mn_tiler, 1))

        # Compute grid size using CLC scheduler
        cta_tile_shape_mnk = (
            self.mn_tiler[0] // 2 if self.use_2cta_instrs else self.mn_tiler[0],
            self.mn_tiler[1],
            1,
        )
        tile_sched_params, grid = self._compute_grid(
            mD,
            cta_tile_shape_mnk,
            self.cluster_shape,
            self.fallback_cluster_shape,
            self.swizzle_size,
            self.raster_along,
        )
        # Compute stages in host JIT context so smem capacity is device-queried
        if cutlass.const_expr(self.use_2cta_instrs):
            cta_group = cute.nvgpu.tcgen05.CtaGroup.TWO
        else:
            cta_group = cute.nvgpu.tcgen05.CtaGroup.ONE
        tiled_mma = sm100_utils.make_trivial_tiled_mma(
            self.ab_dtype,
            self.ab_dtype,
            cutlass.tensor_utils.LayoutEnum.from_tensor(mA).mma_major_mode(),
            cutlass.tensor_utils.LayoutEnum.from_tensor(mB).mma_major_mode(),
            self.acc_dtype,
            cta_group,
            self.mn_tiler,
        )
        mma_inst_shape_k = cute.size(tiled_mma.shape_mnk, mode=[2])
        mma_inst_tile_k = 4
        mnk_tiler = (
            self.mn_tiler[0],
            self.mn_tiler[1],
            mma_inst_shape_k * mma_inst_tile_k,
        )
        smem_capacity = cutlass.memory.get_smem_capacity_in_bytes()
        self.acc_stage, self.mainloop_stage, self.TMA_STORE_STAGE = _compute_stages(
            tiled_mma,
            mnk_tiler,
            self.ab_dtype,
            self.tmem_output_dtype,
            mD,
            self.use_2cta_instrs,
            smem_capacity,
        )
        self.kernel(mA, mB, mD, tile_sched_params).launch(
            grid=grid,
            block=(224, 1, 1),  # 7 warps: 4 epi + 1 mma + 1 tma + 1 sched
            cluster=self.cluster_shape,
            fallback_cluster=self.fallback_cluster_shape,
            smem=cute.Int64(smem_capacity),
        )

    @cute.experimental.kernel
    def kernel(
        self,
        mA: cute.Tensor,
        mB: cute.Tensor,
        mD: cute.Tensor,
        tile_sched_params: utils.ClcDynamicPersistentTileSchedulerParams,
    ):
        # Determine CTA group based on 2-CTA mode
        if cutlass.const_expr(self.use_2cta_instrs):
            cta_group = cute.nvgpu.tcgen05.CtaGroup.TWO
        else:
            cta_group = cute.nvgpu.tcgen05.CtaGroup.ONE

        tiled_mma = sm100_utils.make_trivial_tiled_mma(
            self.ab_dtype,
            self.ab_dtype,
            cutlass.tensor_utils.LayoutEnum.from_tensor(mA).mma_major_mode(),
            cutlass.tensor_utils.LayoutEnum.from_tensor(mB).mma_major_mode(),
            self.acc_dtype,
            cta_group,
            self.mn_tiler,
        )

        mma_inst_shape_k = cute.size(tiled_mma.shape_mnk, mode=[2])
        mma_inst_tile_k = 4
        mnk_tiler = (
            self.mn_tiler[0],
            self.mn_tiler[1],
            mma_inst_shape_k * mma_inst_tile_k,
        )
        mma_m = self.mn_tiler[0]
        mma_n = self.mn_tiler[1]
        mma_k = mma_inst_shape_k

        # Tiler down to 1 SM
        # For 2xSM, each cta loads half of mma_N.
        num_mma_ctas = cute.size(tiled_mma.thr_id.shape)
        cta_tile_shape_mnk = cute.shape_div(mnk_tiler, (num_mma_ctas, 1, 1))
        a_tiler_mk = (cta_tile_shape_mnk[0], cta_tile_shape_mnk[2])
        b_tiler_nk = (cta_tile_shape_mnk[1] // num_mma_ctas, cta_tile_shape_mnk[2])

        gA = cute.zipped_divide(mA, a_tiler_mk)
        gB = cute.zipped_divide(mB, b_tiler_nk)

        acc_stage = self.acc_stage
        mainloop_stage = self.mainloop_stage

        bidx, _, _ = cute.arch.block_idx()
        mma_tile_coord_v = bidx % cute.size(tiled_mma.thr_id.shape)
        is_leader_cta = mma_tile_coord_v == 0
        thr_mma = tiled_mma.get_slice(mma_tile_coord_v)

        # Cluster layout for 2-CTA coordination. Reading the cluster shape via
        # ``block_in_cluster_dim()`` lets the same source specialize per
        # body-clone branch under mixed-cluster (see the mixed-cluster expansion pass).
        cluster_layout_vmnk = cute.tiled_divide(
            cute.make_layout(cute.arch.block_in_cluster_dim()),
            cute.core._pack_shape((cute.size(tiled_mma.thr_id.shape),)),
        )
        cluster_layout_v_size = cute.size(cluster_layout_vmnk.shape[0])

        # Compute A/B/C shared memory layout
        a_smem_layout_staged = sm100_utils.make_smem_layout_a(
            tiled_mma,
            mnk_tiler,
            self.ab_dtype,
            mainloop_stage,
        )
        b_smem_layout_staged = sm100_utils.make_smem_layout_b(
            tiled_mma,
            mnk_tiler,
            self.ab_dtype,
            mainloop_stage,
        )

        cta_tile_shape_mnk = cute.shape_div(
            mnk_tiler, (cute.size(tiled_mma.thr_id.shape), 1, 1)
        )

        # UMMA ACC TMEM Layout
        tmem_layout = cute_ext.make_tmem_layout_acc(tiled_mma, mnk_tiler, acc_stage)

        # Allocate UMMA Buffers
        bufferA = cute_ext.allocate(
            self.ab_dtype,
            cutlass.AddressSpace.smem,
            a_smem_layout_staged,
            alignment=1024,
        )

        bufferB = cute_ext.allocate(
            self.ab_dtype,
            cutlass.AddressSpace.smem,
            b_smem_layout_staged,
            alignment=1024,
        )

        bufferAcc = cute_ext.allocate(
            self.acc_dtype,
            cutlass.AddressSpace.tmem,
            tmem_layout,
            alignment=16,
            is2cta=self.use_2cta_instrs,
        )

        # Allocate CLC response buffer (one 128-bit slot per pipeline stage)
        num_clc_stages = 1
        clc_response_buffer = cute_ext.allocate(
            Int128,
            cutlass.AddressSpace.smem,
            cute.make_layout((num_clc_stages,)),
            alignment=128,
        )

        # Construct the CLC scheduler
        tile_sched = utils.ClcDynamicPersistentTileScheduler.create(
            tile_sched_params,
            cute.arch.block_idx(),
            cute.arch.grid_dim(),
            clc_response_buffer.iterator,
            insert_fence=False,
        )
        work_tile = tile_sched.initial_work_tile_info()
        cur_tile_coord = work_tile.tile_idx
        cta_m, cta_n, cta_l = cur_tile_coord[0], cur_tile_coord[1], cur_tile_coord[2]

        # TMA multicast projection modes
        # A is multicast along M dimension (proj=2), B along N dimension (proj=1)
        tma_mcast_proj_A = 2
        tma_mcast_proj_B = 1

        # Determine pipeline operation types based on 2-CTA mode and TMA multicast
        if cutlass.const_expr(self.use_2cta_instrs):
            mma_operation_type = cute_ext.OperationTypeEnum.SM100_MMA_2SM_SS
            if cutlass.const_expr(self.use_tma_multicast):
                tma_operation_type = (
                    cute_ext.OperationTypeEnum.SM100_TMA_LOAD_2SM_MULTICAST
                )
            else:
                tma_operation_type = cute_ext.OperationTypeEnum.SM100_TMA_LOAD_2SM
        else:
            mma_operation_type = cute_ext.OperationTypeEnum.SM100_MMA_1SM_SS
            if cutlass.const_expr(self.use_tma_multicast):
                tma_operation_type = cute_ext.OperationTypeEnum.SM90_TMA_LOAD_MULTICAST
            else:
                tma_operation_type = cute_ext.OperationTypeEnum.SM90_TMA_LOAD

        # TMA -> UMMA pipeline
        mainloop_pipe = cute_ext.TMAToUMMAPipeline.create(
            num_stages=mainloop_stage,
            mma_operation_type=mma_operation_type,
            tma_operation_type=tma_operation_type,
            cluster_layout_vmnk=cluster_layout_vmnk,
        )

        # UMMA -> Load to tensor memory pipeline
        # For 2-CTA MMA, warpgroup from both peer and leader CTA consumer.release
        acc_pipe_consumer_arv_count = 256 if self.use_2cta_instrs else 128
        acc_pipe = cute_ext.UMMAtoAsyncPipeline.create(
            num_stages=acc_stage,
            mma_operation_type=mma_operation_type,
            consumer=cute_ext.OperationTypeEnum.SM100_COPY_T2R,
            consumer_arv_count=acc_pipe_consumer_arv_count,
            cluster_layout_vmnk=cluster_layout_vmnk,
        )

        # Scheduler -> All
        # Use the dynamic cluster size so under mixed-cluster the arrival count
        # matches whichever cluster shape this CTA was launched with.
        clc_pipe = cute_ext.CLCPipeline.create(
            num_stages=num_clc_stages,
            consumer_arv_count=32 * (1 + cute.size(cluster_layout_vmnk) * 6),
            response_buffer=clc_response_buffer,
        )

        warp_idx = cute.arch.warp_idx()
        warp_idx = cute.arch.make_warp_uniform(warp_idx)

        cta_rank_in_cluster = cute.arch.make_warp_uniform(
            cute.arch.block_idx_in_cluster()
        )
        is_first_cta_in_cluster = cta_rank_in_cluster == 0

        # warp assignment: [0]-tma_store, [0-3]-epi, [4]-mma, [5]-tma_load, [6]-sched
        tma_store_warp_id = 0
        mma_warp_id = 4
        tma_load_warp_id = 5
        sched_warp_id = 6

        is_tma_thr = warp_idx == tma_load_warp_id
        is_mma_thr = warp_idx == mma_warp_id
        is_epi_thr = warp_idx < 4
        is_sched_thr = warp_idx == sched_warp_id

        # store to smem -> TMA store to global
        tma_store_pipe = cute_ext.TMAStorePipeline(
            stages=self.TMA_STORE_STAGE,
            arv_count=128,
            barrier_id=1,
            tma_warp_id=tma_store_warp_id,
        )

        # CLC pipeline for tile scheduling
        # Note: For simplicity, we're using basic synchronization here
        # A full implementation would use PipelineClcFetchAsync as in the original

        k_tile_size = cute.size(gA, mode=[1, 1])
        gA_mkl = cute.local_tile(
            mA, cute.slice_(mnk_tiler, (None, 0, None)), (None, None, None)
        )
        gB_nkl = cute.local_tile(
            mB, cute.slice_(mnk_tiler, (0, None, None)), (None, None, None)
        )
        tCgA_mma = thr_mma.partition_A(gA_mkl)
        tCgB_mma = thr_mma.partition_B(gB_nkl)

        # TMA load warp
        if is_tma_thr:
            while work_tile.is_valid_tile:
                # Get tile coord from tile scheduler
                cur_tile_coord = work_tile.tile_idx
                cta_m, cta_n, cta_l = (
                    cur_tile_coord[0],
                    cur_tile_coord[1],
                    cur_tile_coord[2],
                )

                # N coordinate for 2xSM TMA
                if cutlass.const_expr(self.use_2cta_instrs):
                    gB_tma_coord_n = (
                        cluster_layout_v_size * cta_n + cta_m % cluster_layout_v_size
                    )
                else:
                    gB_tma_coord_n = cta_n

                gA_tile = gA[(None, None), (cta_m, None, cta_l)]
                gB_tile = gB[(None, None), (gB_tma_coord_n, None, cta_l)]
                mma_tile_coord_m = cta_m // cluster_layout_v_size
                tAgA_slice = tCgA_mma[(None, None, None, mma_tile_coord_m, None, cta_l)]
                tBgB_slice = tCgB_mma[(None, None, None, cta_n, None, cta_l)]

                k_tile_size = cute.size(gA, mode=[1, 1])

                for k in cutlass.range(0, k_tile_size, 1, unroll=1):
                    # Scoped state management - pipeline object manages state internally
                    (
                        producer_stage_token,
                        idx,
                    ) = mainloop_pipe.producer_acquire_and_get_stage()
                    mbar = cute_ext.get_mbarrier(producer_stage_token)
                    ## producer_body begin ##
                    bufferA_sliced = bufferA[None, None, None, idx]
                    bufferB_sliced = bufferB[None, None, None, idx]
                    if cutlass.const_expr(self.use_tma_multicast):
                        gA_k = tAgA_slice[(None, None, None, k)]
                        gB_k = tBgB_slice[(None, None, None, k)]
                        cute_ext.tma_load(
                            gA_k,
                            bufferA_sliced,
                            mbar,
                            vmnk_layout=cluster_layout_vmnk,
                            tma_operation_type=tma_operation_type,
                            multicast_mode=tma_mcast_proj_A,
                        )
                        cute_ext.tma_load(
                            gB_k,
                            bufferB_sliced,
                            mbar,
                            vmnk_layout=cluster_layout_vmnk,
                            tma_operation_type=tma_operation_type,
                            multicast_mode=tma_mcast_proj_B,
                        )
                    else:
                        # Non-multicast TMA: tile by per-CTA size, not the full
                        # 2SM MMA tile. mma_m/mma_n span both CTAs (256) while
                        # gA_k/gB_k are already divided to one CTA's share (128).
                        gA_k = gA_tile[None, None, k]
                        tCgA = cute.tiled_divide(gA_k, (cta_tile_shape_mnk[0], mma_k))
                        cute_ext.tma_load(
                            tCgA,
                            bufferA_sliced,
                            mbar,
                            tma_operation_type=tma_operation_type,
                        )
                        gB_k = gB_tile[None, None, k]
                        tCgB = cute.tiled_divide(gB_k, (b_tiler_nk[0], mma_k))
                        cute_ext.tma_load(
                            tCgB,
                            bufferB_sliced,
                            mbar,
                            tma_operation_type=tma_operation_type,
                        )
                    ## producer_body end ##
                    mainloop_pipe.producer_commit_and_advance()

                # Advance to next tile
                clc_pipe.consumer_wait()
                work_tile = tile_sched.get_current_work()
                clc_pipe.consumer_release_and_advance()

            # Drain outstanding consumer releases on mainloop pipeline
            # before TMA warp exits.
            mainloop_pipe.producer_tail()

        # Scheduler warp
        if is_sched_thr and is_first_cta_in_cluster:
            while work_tile.is_valid_tile:
                # Advance to next tile using CLC fetch
                clc_pipe.producer_acquire()
                clc_pipe.issue_next()
                clc_pipe.producer_commit()

                clc_pipe.producer_state = cute_ext.pipeline_advance_iterator(
                    clc_pipe.raw_pipeline, clc_pipe.producer_state
                )

                clc_pipe.consumer_wait()
                work_tile = tile_sched.get_current_work()
                clc_pipe.consumer_release_and_advance()

            # Drain outstanding consumer releases before the producer CTA exits.
            clc_pipe.producer_tail()

        # MMA warp
        if is_mma_thr:
            while work_tile.is_valid_tile:
                if is_leader_cta:
                    _, idx = acc_pipe.producer_acquire_and_get_stage()
                    accumulators_sliced = bufferAcc[None, None, None, idx]

                    (updated_a_pipe, _updated_b_pipe) = cute_ext.mainloop_mma(
                        tiled_mma,
                        bufferA,
                        bufferB,
                        accumulators_sliced,
                        0,
                        k_tile_size,
                        mma_inst_tile_k,
                        mainloop_pipe,
                        mainloop_pipe,
                    )
                    mainloop_pipe = updated_a_pipe

                    acc_pipe.producer_commit_and_advance()

                # Advance to next tile
                clc_pipe.consumer_wait()
                # CLC pipeline has proper fence inside consumer_release.
                # TODO: Update get_current_work to avoid fence inside for CUTE.
                work_tile = tile_sched.get_current_work()
                clc_pipe.consumer_release_and_advance()

            # Drain outstanding consumer releases on accumulator pipeline
            # before MMA warp exits (leader CTA only, since only the leader
            # produces into acc_pipe).
            if is_leader_cta:
                acc_pipe.producer_tail()

        # Epilogue warps
        if is_epi_thr:
            while work_tile.is_valid_tile:
                _, idx = acc_pipe.consumer_wait_and_get_stage()
                accumulators_sliced = bufferAcc[(None, None), 0, 0, idx]

                tma_store_pipe = cute_ext.epilogue_tma_store(
                    cta_tile_shape_mnk,
                    self.use_2cta_instrs,
                    accumulators_sliced,
                    mD,
                    work_tile.tile_idx,
                    tma_store_pipe,
                    tma_store_warp_id,
                    self.epilogue_op,
                )

                acc_pipe.consumer_release_and_advance()

                # Advance to next tile
                clc_pipe.consumer_wait()
                work_tile = tile_sched.get_current_work()
                clc_pipe.consumer_release_and_advance()

    @staticmethod
    def _compute_grid(
        c: cute.Tensor,
        cta_tile_shape_mnk: Tuple[int, int, int],
        cluster_shape: Tuple[int, int, int],
        fallback_cluster_shape: Tuple[int, int, int],
        swizzle_size: int,
        raster_along: str,
    ) -> Tuple[utils.ClcDynamicPersistentTileSchedulerParams, Tuple[int, int, int]]:
        """Use persistent tile scheduler to compute the grid size for the output tensor C."""
        c_shape = cute.slice_(cta_tile_shape_mnk, (None, None, 0))
        gc = cute.zipped_divide(c, tiler=c_shape)
        num_ctas_mnl = gc[(0, (None, None, None))].shape

        tile_sched_params = utils.ClcDynamicPersistentTileSchedulerParams(
            num_ctas_mnl,
            cluster_shape,
            swizzle_size,
            raster_along == "m",
            fallback_cluster_shape_mnk=fallback_cluster_shape,
        )
        grid = utils.ClcDynamicPersistentTileScheduler.get_grid_shape(tile_sched_params)

        return tile_sched_params, grid


def create_tensors(
    l, m, n, k, a_major, b_major, c_major, ab_dtype, c_dtype, zero_init=False
):
    torch.manual_seed(1111)

    # zero_init=True fills operands with zeros instead of random data. All-zero
    # operands cause far less tensor-core switching activity -> much lower power,
    # which keeps the SM clock from throttling on power-capped boards during
    # throughput benchmarking. Use only with skip_ref_check (output is all-zero).
    init_kwargs = (
        dict(
            init_type=cutlass_torch.TensorInitType.SCALAR,
            init_config=cutlass_torch.ScalarInitConfig(value=0.0),
        )
        if zero_init
        else {}
    )

    a_torch_cpu = cutlass_torch.matrix(l, m, k, a_major == "m", ab_dtype, **init_kwargs)
    b_torch_cpu = cutlass_torch.matrix(l, n, k, b_major == "n", ab_dtype, **init_kwargs)
    c_torch_cpu = cutlass_torch.matrix(l, m, n, c_major == "m", c_dtype, **init_kwargs)

    a_tensor, _ = cutlass_torch.cute_tensor_like(
        a_torch_cpu, ab_dtype, is_dynamic_layout=True, assumed_align=16
    )
    b_tensor, _ = cutlass_torch.cute_tensor_like(
        b_torch_cpu, ab_dtype, is_dynamic_layout=True, assumed_align=16
    )
    c_tensor, c_torch_gpu = cutlass_torch.cute_tensor_like(
        c_torch_cpu, c_dtype, is_dynamic_layout=True, assumed_align=16
    )

    return (
        a_tensor,
        b_tensor,
        c_tensor,
        a_torch_cpu,
        b_torch_cpu,
        c_torch_cpu,
        c_torch_gpu,
    )


def compare(a_torch_cpu, b_torch_cpu, c_torch_gpu, c_dtype, tolerance):
    ref = torch.einsum("mkl,nkl->mnl", a_torch_cpu, b_torch_cpu)

    _, ref_torch_gpu = cutlass_torch.cute_tensor_like(
        ref, c_dtype, is_dynamic_layout=True, assumed_align=16
    )
    ref_result = ref_torch_gpu.cpu()
    torch.testing.assert_close(
        c_torch_gpu.cpu(), ref_result, atol=tolerance, rtol=1e-05
    )


def run(
    mnkl: Tuple[int, int, int, int],
    mma_tiler_mn: Tuple[int, int],
    cluster_shape_mn: Tuple[int, int],
    ab_dtype: Type[Numeric],
    c_dtype: Type[Numeric],
    acc_dtype: Type[Numeric],
    a_major: str,
    b_major: str,
    c_major: str,
    warmup_iterations: int = 0,
    iterations: int = 1,
    use_cold_l2: bool = False,
    tolerance: float = 1e-02,
    skip_ref_check: bool = False,
    use_2cta_instrs: bool = False,
    zero_init: bool = False,
    fallback_cluster_shape_mn: Tuple[int, int] = None,
    **kwargs,
):
    """Execute a persistent batched dense GEMM operation on Blackwell architecture with CLC scheduler.

    This function prepares input tensors, configures and launches the persistent GEMM kernel
    with dynamic tile scheduling, optionally performs reference validation, and benchmarks execution.

    :param mnkl: Problem size (M, N, K, L)
    :type mnkl: Tuple[int, int, int, int]
    :param mma_tiler_mn: MMA tiling size.
    :type mma_tiler_mn: Tuple[int, int]
    :param cluster_shape_mn: Cluster shape.
    :type cluster_shape_mn: Tuple[int, int]
    :param ab_dtype: Data type for input tensors A and B
    :type ab_dtype: Type[Numeric]
    :param c_dtype: Data type for output tensor C
    :type c_dtype: Type[Numeric]
    :param acc_dtype: Data type for accumulator
    :type acc_dtype: Type[Numeric]
    :param use_2cta_instrs: Use 2-CTA (2SM) instructions for larger tile sizes
    :type use_2cta_instrs: bool
    """
    cli.print_problem_config(
        "Blackwell Persistent Dense GEMM with CLC scheduler",
        mnkl,
        dtypes={"AB": ab_dtype, "C": c_dtype, "Acc": acc_dtype},
        majors={"A": a_major, "B": b_major, "C": c_major},
        mma_tiler_mn=mma_tiler_mn,
        cluster_shape_mn=cluster_shape_mn,
    )
    if fallback_cluster_shape_mn is not None:
        print(f"Fallback Cluster Shape (M, N): {fallback_cluster_shape_mn}")
    print(f"Use 2-CTA instructions: {use_2cta_instrs}")
    cli.print_benchmark_config(
        tolerance=tolerance,
        warmup_iterations=warmup_iterations,
        iterations=iterations,
        skip_ref_check=skip_ref_check,
        use_cold_l2=use_cold_l2,
    )

    m, n, k, l = mnkl

    sm100_utils.check_gemm_tma_alignment(
        m,
        n,
        k,
        ab_dtype,
        ab_dtype,
        c_dtype,
        a_major,
        b_major,
        c_major,
        output_tensor_name="C",
    )

    a_tensor, b_tensor, c_tensor, a_torch_cpu, b_torch_cpu, c_torch_cpu, c_torch_gpu = (
        create_tensors(
            l,
            m,
            n,
            k,
            a_major,
            b_major,
            c_major,
            ab_dtype,
            c_dtype,
            zero_init=zero_init,
        )
    )
    dense_gemm = PersistentDenseGemmKernel(
        mn_tiler=mma_tiler_mn,
        mma_dtype=(ab_dtype, acc_dtype),
        tmem_output_dtype=c_dtype,
        use_2cta_instrs=use_2cta_instrs,
        cluster_shape_mn=cluster_shape_mn,
        fallback_cluster_shape_mn=fallback_cluster_shape_mn,
    )

    compiled_dense_gemm = cute_ext.compile(dense_gemm, a_tensor, b_tensor, c_tensor)
    compiled_dense_gemm.engine.initialize()

    compiled_dense_gemm(a_tensor, b_tensor, c_tensor)

    if not skip_ref_check:
        compare(a_torch_cpu, b_torch_cpu, c_torch_gpu, c_dtype, tolerance)
        print("check reference: PASS")

    def generate_tensors():
        a_tensor, _ = cutlass_torch.cute_tensor_like(
            a_torch_cpu, ab_dtype, is_dynamic_layout=True, assumed_align=16
        )
        b_tensor, _ = cutlass_torch.cute_tensor_like(
            b_torch_cpu, ab_dtype, is_dynamic_layout=True, assumed_align=16
        )
        c_tensor, _ = cutlass_torch.cute_tensor_like(
            c_torch_cpu, c_dtype, is_dynamic_layout=True, assumed_align=16
        )
        return testing.JitArguments(a_tensor, b_tensor, c_tensor)

    workspace_count = 1
    if use_cold_l2:
        one_workspace_bytes = (
            a_torch_cpu.numel() * a_torch_cpu.element_size()
            + b_torch_cpu.numel() * b_torch_cpu.element_size()
            + c_torch_cpu.numel() * c_torch_cpu.element_size()
        )
        workspace_count = testing.get_workspace_count(
            one_workspace_bytes, warmup_iterations, iterations
        )

    exec_time = testing.benchmark(
        compiled_dense_gemm,
        workspace_generator=generate_tensors,
        workspace_count=workspace_count,
        warmup_iterations=warmup_iterations,
        iterations=iterations,
    )

    return exec_time


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Example of Persistent Dense GEMM with CLC scheduler on Blackwell."
    )

    cli.add_mnkl_arg(parser)
    cli.add_mma_tiler_arg(parser)
    cli.add_cluster_shape_arg(parser)
    cli.add_dtype_args(parser, ab=cutlass.BFloat16, c=cutlass.BFloat16)
    cli.add_major_args(parser)
    cli.add_benchmark_args(parser, tolerance=1e-02)

    parser.add_argument(
        "--fallback_cluster_shape_mn",
        type=cli.comma_separated_ints,
        default=None,
        help="Optional fallback cluster shape (comma-separated). When "
        "provided and different from --cluster_shape_mn, the kernel is "
        "compiled in mixed-cluster mode.",
    )
    parser.add_argument(
        "--use_2cta_instrs",
        action="store_true",
        help="Use 2-CTA (2SM) MMA instructions",
    )
    parser.add_argument(
        "--zero_init",
        action="store_true",
        help="Initialize operands with zeros instead of random data. Lowers "
        "tensor-core switching power to keep the SM clock from throttling on "
        "power-capped boards (timing/benchmark path only; output is all-zero).",
    )

    args = parser.parse_args()

    if len(args.mnkl) != 4:
        parser.error("--mnkl must contain exactly 4 values")

    if len(args.mma_tiler_mn) != 2:
        parser.error("--mma_tiler_mn must contain exactly 2 values")

    if (
        args.fallback_cluster_shape_mn is not None
        and len(args.fallback_cluster_shape_mn) != 2
    ):
        parser.error("--fallback_cluster_shape_mn must contain exactly 2 values")

    exec_time = run(
        args.mnkl,
        args.mma_tiler_mn,
        args.cluster_shape_mn,
        args.ab_dtype,
        args.c_dtype,
        args.acc_dtype,
        args.a_major,
        args.b_major,
        args.c_major,
        args.warmup_iterations,
        args.iterations,
        args.use_cold_l2,
        args.tolerance,
        args.skip_ref_check,
        args.use_2cta_instrs,
        args.zero_init,
        fallback_cluster_shape_mn=args.fallback_cluster_shape_mn,
    )

    print(f"Execution time: {exec_time} microseconds per iteration")
