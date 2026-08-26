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
from cutlass import utils
from cutlass import torch as cutlass_torch
from cutlass.torch import dtype as torch_dtype
import cutlass.utils.blackwell_helpers as sm100_utils
from cutlass import testing

if __name__ == "__main__":
    current_dir = os.path.dirname(os.path.abspath(__file__))
    sys.path.insert(0, os.path.join(current_dir, "../../../"))

from helpers import cli_helper as cli

"""
A high-performance persistent batched dense GEMM (D = alpha * A * B + beta * C) example
for the NVIDIA Blackwell SM100 architecture using CUTE experimental API.

- Matrix A is MxKxL, L is batch dimension, A can be row-major("K") or column-major("M")
- Matrix B is NxKxL, L is batch dimension, B can be row-major("N") or column-major("K")
- Matrix C is MxNxL, L is batch dimension, C can be row-major("N") or column-major("M")
- Matrix D is MxNxL, L is batch dimension, D can be row-major("N") or column-major("M")
- alpha and beta are float scalars

This GEMM kernel supports the following features:
    - Utilizes Tensor Memory Access (TMA) for efficient memory operations
    - Utilizes Blackwell's tcgen05.mma for matrix multiply-accumulate (MMA) operations
      (including 2cta mma instructions)
    - Implements TMA multicast with cluster to reduce L2 memory traffic
    - Support persistent tile scheduling to better overlap memory load/store with mma
      between tiles
    - Support warp specialization to avoid explicit pipelining between mainloop load and mma
    - TMA-based C loading via cute_ext.GenericPipeline with a dedicated C-load warp

This GEMM works as follows:
1. DMA warp (warp 5): Load A and B matrices from GMEM to SMEM using TMA operations.
2. C-load warp (warp 6): Load C matrix subtiles from GMEM to SMEM using TMA operations
   via a GenericPipeline (TMA producer, epilogue consumer).
3. MMA warp (warp 4): Perform matrix multiply-accumulate using tcgen05.mma instruction.
4. Epilogue warps (warps 0-3):
    - Load completed accumulator from TMEM to RMEM using tcgen05.ld.
    - Wait for C subtile from SMEM (via GenericPipeline consumer), copy to RMEM.
    - Compute D = alpha * accumulator + beta * C in epilogue dtype precision.
    - Optionally apply an elementwise epilogue_op.
    - Type convert D to output type.
    - Store D from RMEM to SMEM to GMEM with TMA operations.

Example usage:

.. code-block:: bash

    python examples/cute_ext/blackwell/dense_gemm/dense_gemm_alpha_beta_persistent.py   \\
      --ab_dtype Float16 --c_dtype Float16 --d_dtype Float16                     \\
      --acc_dtype Float32 --epi_dtype Float32                                    \\
      --mma_tiler_mn 128,128 --cluster_shape_mn 1,1                             \\
      --mnkl 256,256,512,1 --alpha 2.0 --beta 1.0

Constraints:
* Supported input data types: fp16, bf16, tf32
* A/B tensor must have the same data type
* C/D tensor must have the same major order
* Mma tiler M must be 64/128 (use_2cta_instrs=False) or 128/256 (use_2cta_instrs=True)
* Mma tiler N must be 32-256, step 32
* Cluster shape M/N must be positive and power of 2, total cluster size <= 16
* Cluster shape M must be multiple of 2 if use_2cta_instrs=True
* The contiguous dimension of A/B/C/D tensors must be at least 16 bytes aligned
"""


class PersistentDenseGemmAlphaBetaKernel:
    def __init__(
        self,
        mn_tiler: tuple[int, int],
        mma_dtype: tuple[Type[Numeric], Type[Numeric]],
        tmem_output_dtype: Type[Numeric],
        epi_dtype: Type[Numeric],
        max_active_clusters: int,
        epilogue_op=lambda x: x,
        use_2cta_instrs: bool = False,
        cluster_shape_mn: Tuple[int, int] = (1, 1),
        fallback_cluster_shape_mn: Tuple[int, int] = None,
        max_active_fallback_clusters: int = None,
    ):
        self.mn_tiler = mn_tiler
        self.ab_dtype, self.acc_dtype = mma_dtype
        self.tmem_output_dtype = tmem_output_dtype
        self.epi_dtype = epi_dtype
        self.use_2cta_instrs = use_2cta_instrs
        self.TMA_STORE_STAGE = 2
        self.C_LOAD_STAGE = 2
        self.epilogue_op = epilogue_op
        self.cluster_shape = (cluster_shape_mn[0], cluster_shape_mn[1], 1)
        cluster_shape_mn_selfcast = (2, 1) if use_2cta_instrs else (1, 1)
        self.use_tma_multicast = cluster_shape_mn != cluster_shape_mn_selfcast
        self.max_active_clusters = max_active_clusters
        if fallback_cluster_shape_mn is None:
            self.fallback_cluster_shape = self.cluster_shape
            self.max_active_fallback_clusters = max_active_clusters
        else:
            self.fallback_cluster_shape = (
                fallback_cluster_shape_mn[0],
                fallback_cluster_shape_mn[1],
                1,
            )
            self.max_active_fallback_clusters = (
                max_active_fallback_clusters
                if max_active_fallback_clusters is not None
                else max_active_clusters
            )

    def compute_stages(
        self,
        tiled_mma,
        mnk_tiler,
        ab_dtype,
        epi_tile,
        d_dtype,
        d_layout,
        c_dtype=None,
        c_layout=None,
        num_c_load_stages=0,
        occupancy=1,
    ):
        """Compute pipeline stages dynamically from SMEM capacity.

        Fills shared memory with as many A/B mainloop stages as possible, then
        allocates remaining capacity to epilogue (TMA store) stages.
        Accumulator stages are fixed at 2.

        For alpha-beta kernels, pass c_dtype/c_layout/num_c_load_stages to
        account for C input SMEM alongside D output SMEM.
        """
        num_acc_stage = 2
        num_tma_store_stage = 2
        reserved_smem_bytes = 1024
        smem_capacity = cutlass.memory.get_smem_capacity_in_bytes("sm_100")

        a_smem_layout_one = sm100_utils.make_smem_layout_a(
            tiled_mma,
            mnk_tiler,
            ab_dtype,
            1,
        )
        b_smem_layout_one = sm100_utils.make_smem_layout_b(
            tiled_mma,
            mnk_tiler,
            ab_dtype,
            1,
        )
        d_smem_layout_one = sm100_utils.make_smem_layout_epi(
            d_dtype,
            d_layout,
            epi_tile,
            1,
        )

        ab_bytes_per_stage = cute.size_in_bytes(
            ab_dtype, a_smem_layout_one
        ) + cute.size_in_bytes(ab_dtype, b_smem_layout_one)
        d_bytes_per_stage = cute.size_in_bytes(d_dtype, d_smem_layout_one)
        d_bytes = d_bytes_per_stage * num_tma_store_stage

        c_bytes = 0
        if num_c_load_stages > 0 and c_dtype is not None and c_layout is not None:
            c_smem_layout_one = sm100_utils.make_smem_layout_epi(
                c_dtype,
                c_layout,
                epi_tile,
                1,
            )
            c_bytes_per_stage = cute.size_in_bytes(c_dtype, c_smem_layout_one)
            c_bytes = c_bytes_per_stage * num_c_load_stages

        num_mainloop_stage = (
            smem_capacity // occupancy - (reserved_smem_bytes + c_bytes + d_bytes)
        ) // ab_bytes_per_stage

        remaining_smem = (
            smem_capacity
            - occupancy * ab_bytes_per_stage * num_mainloop_stage
            - occupancy * (reserved_smem_bytes + c_bytes + d_bytes)
        )
        num_tma_store_stage += remaining_smem // (occupancy * d_bytes_per_stage)

        return num_mainloop_stage, num_tma_store_stage, num_acc_stage

    @cute.experimental.jit
    def __call__(
        self,
        mA: cute.Tensor,
        mB: cute.Tensor,
        mC: cute.Tensor,
        mD: cute.Tensor,
        alpha: cutlass.Float32,
        beta: cutlass.Float32,
    ):
        cta_tile_mnk = (
            self.mn_tiler[0] // 2 if self.use_2cta_instrs else self.mn_tiler[0],
            self.mn_tiler[1],
            1,
        )
        num_ctas_mnl = cute.ceil_div(mD.shape, cta_tile_mnk)
        tile_sched_params = utils.PersistentTileSchedulerParams(
            num_ctas_mnl,
            self.cluster_shape,
            fallback_cluster_shape_mnk=self.fallback_cluster_shape,
        )
        grid = utils.StaticPersistentTileScheduler.get_grid_shape(
            tile_sched_params, self.max_active_clusters
        )
        self.kernel(mA, mB, mC, mD, tile_sched_params, alpha, beta).launch(
            grid=grid,
            block=(224, 1, 1),  # 7 warps
            cluster=self.cluster_shape,
            fallback_cluster=self.fallback_cluster_shape,
            smem=cute.Int64(cutlass.memory.get_smem_capacity_in_bytes("sm_100")),
        )

    @cute.experimental.kernel
    def kernel(
        self,
        mA: cute.Tensor,
        mB: cute.Tensor,
        mC: cute.Tensor,
        mD: cute.Tensor,
        tile_sched_params: utils.PersistentTileSchedulerParams,
        alpha: cutlass.Float32,
        beta: cutlass.Float32,
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

        # Tiler for 2xSM if use 2xSM, otherwise it's for 1 SM/cta.
        mnk_tiler = (
            self.mn_tiler[0],
            self.mn_tiler[1],
            mma_inst_shape_k * mma_inst_tile_k,
        )

        d_layout = cutlass.tensor_utils.LayoutEnum.from_tensor(mD)
        d_dtype = mD.element_type
        c_dtype = mC.element_type

        # Tiler down to 1 SM
        # For 2xSM, each CTA loads half of mma_M for A and half of mma_N for B.
        # The accumulator is split along M only (each CTA holds full N columns).
        num_mma_ctas = cute.size(tiled_mma.thr_id.shape)
        cta_tile_shape_mnk = cute.shape_div(mnk_tiler, (num_mma_ctas, 1, 1))
        # A is tiled (M/2, K) for 2CTA
        a_tiler_mk = (cta_tile_shape_mnk[0], cta_tile_shape_mnk[2])
        # B is tiled (N/2, K) for 2CTA
        b_tiler_nk = (cta_tile_shape_mnk[1] // num_mma_ctas, cta_tile_shape_mnk[2])
        # C/D is tiled (M/2, N) for 2CTA because 2-SM UMMA splits accumulator along M only
        c_tiler_mn = (cta_tile_shape_mnk[0], cta_tile_shape_mnk[1])

        gA = cute.zipped_divide(mA, a_tiler_mk)
        gB = cute.zipped_divide(mB, b_tiler_nk)
        gC = cute.zipped_divide(mC, c_tiler_mn)
        gD = cute.zipped_divide(mD, c_tiler_mn)

        c_layout = d_layout  # C and D share major order
        epi_tile = sm100_utils.compute_epilogue_tile_shape(
            cta_tile_shape_mnk,
            self.use_2cta_instrs,
            d_layout,
            d_dtype,
            layout_c=c_layout,
            elem_ty_c=c_dtype,
        )

        # Compute pipeline stages dynamically based on SMEM capacity
        mainloop_stage, tma_store_stage, acc_stage = self.compute_stages(
            tiled_mma,
            mnk_tiler,
            self.ab_dtype,
            epi_tile,
            d_dtype,
            d_layout,
            c_dtype=c_dtype,
            c_layout=c_layout,
            num_c_load_stages=self.C_LOAD_STAGE,
        )

        cta_m, cta_n, cta_l = cute.arch.block_idx()
        tid_x, _, _ = cute.arch.thread_idx()

        # Cluster layout for 2-CTA coordination
        cluster_shape = cute.arch.block_in_cluster_dim()
        cluster_layout_vmnk = cute.tiled_divide(
            cute.make_layout(cluster_shape),
            cute.core._pack_shape((cute.size(tiled_mma.thr_id.shape),)),
        )
        cluster_layout_v_size = cute.size(cluster_layout_vmnk.shape[0])

        # MMA coordinate within cluster
        mma_coord_vmnk = (
            cta_m % cluster_layout_v_size,
            cta_m // cluster_layout_v_size,
            cta_n,
        )
        is_leader_cta = mma_coord_vmnk[0] == 0
        thr_mma = tiled_mma.get_slice(mma_coord_vmnk[0])

        # Compute A/B/C/D shared memory layouts with dynamic stage counts
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
        sd_smem_layout_staged = sm100_utils.make_smem_layout_epi(
            d_dtype,
            d_layout,
            epi_tile,
            tma_store_stage,
        )
        sc_smem_layout_staged = sm100_utils.make_smem_layout_epi(
            c_dtype,
            c_layout,
            epi_tile,
            self.C_LOAD_STAGE,
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

        # Allocate SMEM buffer for D output
        bufferD = cute_ext.allocate(
            d_dtype,
            cutlass.AddressSpace.smem,
            sd_smem_layout_staged,
            alignment=1024,
        )

        # Allocate SMEM buffer for C input (TMA load destination)
        bufferSC = cute_ext.allocate(
            c_dtype,
            cutlass.AddressSpace.smem,
            sc_smem_layout_staged,
            alignment=1024,
        )

        # Create the TMEM load atom
        copy_atom_t2r = sm100_utils.get_tmem_load_op(
            cta_tile_shape_mnk,
            d_layout,
            self.tmem_output_dtype,
            self.acc_dtype,
            epi_tile,
            self.use_2cta_instrs,
        )

        # Take only one stage of the TMEM buffer
        accumulators = cute.zipped_divide(bufferAcc, ((epi_tile), 1))
        acc_epi_div = accumulators[((None, None), 0), 0]

        # Create the TMEM copy atom based on the size of transfer within one iteration of epilogue
        tiled_copy_t2r = cute.nvgpu.tcgen05.make_tmem_copy(copy_atom_t2r, acc_epi_div)

        # RMEM buffers are allocated after tile scheduler init (see below)
        # where work_tile.tile_idx is available for the RMEM layout computation.

        # TMA multicast projection modes
        # A is shared by CTAs with same M (multicast across N, proj=2)
        # B is shared by CTAs with same N (multicast across M, proj=1)
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
        # For 2-CTA MMA, warpgroup from both peer and leader CTA consumer release
        acc_pipe_consumer_arv_count = 256 if self.use_2cta_instrs else 128
        acc_pipe = cute_ext.UMMAtoAsyncPipeline.create(
            num_stages=acc_stage,
            mma_operation_type=mma_operation_type,
            consumer=cute_ext.OperationTypeEnum.SM100_COPY_T2R,
            consumer_arv_count=acc_pipe_consumer_arv_count,
            cluster_layout_vmnk=cluster_layout_vmnk,
        )

        warp_idx = cute.arch.warp_idx()
        warp_idx = cute.arch.make_warp_uniform(warp_idx)
        # warp assignment: [0]-tma_store, [0-3]-epi, [4]-mma, [5]-tma_load, [6]-c_load
        tma_store_warp_id = 0
        mma_warp_id = 4
        tma_load_warp_id = 5
        c_load_warp_id = 6
        is_tma_thr = warp_idx == tma_load_warp_id
        is_mma_thr = warp_idx == mma_warp_id
        is_epi_thr = warp_idx < 4
        is_c_load_thr = warp_idx == c_load_warp_id

        # store to smem -> TMA store to global
        tma_store_pipe = cute_ext.TMAStorePipeline(
            stages=tma_store_stage,
            arv_count=128,
            barrier_id=1,
            tma_warp_id=tma_store_warp_id,
        )

        # TMA -> Epilogue pipeline for C loading
        # C loading is CTA-local (each CTA loads its own portion), so we use SM90_TMA_LOAD
        # (1CTA) even in 2CTA kernels. The VerifyCtaGroupConsistency pass allows this
        # mixed CTA group usage.
        c_load_pipe = cute_ext.GenericPipeline.create(
            producer=cute_ext.OperationTypeEnum.SM90_TMA_LOAD,
            consumer=cute_ext.OperationTypeEnum.LD_SHARED,
            producer_arv_count=32,  # warp 6 (1 warp)
            consumer_arv_count=128,  # warps 0-3 (4 epilogue warps)
            num_stages=self.C_LOAD_STAGE,
        )

        k_tile_size = cute.size(gA, mode=[1, 1])

        #
        # Persistent tile scheduling loop
        #
        tile_sched = utils.StaticPersistentTileScheduler.create(
            tile_sched_params, cute.arch.block_idx(), cute.arch.grid_dim()
        )
        work_tile = tile_sched.initial_work_tile_info()

        # Calculate per-thread RMEM layout using the initial work tile coordinates
        init_tile_coord = work_tile.tile_idx
        gD_tile_tmp = gD[
            (None, None),
            (init_tile_coord[0], init_tile_coord[1], init_tile_coord[2]),
        ]
        gC_mnl_epi_tmp = cute.flat_divide(gD_tile_tmp, epi_tile)
        acc_d_rmem_layout = cute_ext.make_t2r_rmem_layout(
            tiled_copy_t2r,
            gC_mnl_epi_tmp,
            tid_x,
        )
        bufferRAcc = cute_ext.allocate(
            self.acc_dtype,
            cutlass.AddressSpace.rmem,
            acc_d_rmem_layout,
            alignment=32,
        )
        bufferRD = cute_ext.allocate(
            d_dtype,
            cutlass.AddressSpace.rmem,
            acc_d_rmem_layout,
            alignment=32,
        )
        bufferRC = cute_ext.allocate(
            c_dtype,
            cutlass.AddressSpace.rmem,
            acc_d_rmem_layout,
            alignment=32,
        )
        gA_mkl = cute.local_tile(
            mA, cute.slice_(mnk_tiler, (None, 0, None)), (None, None, None)
        )
        gB_nkl = cute.local_tile(
            mB, cute.slice_(mnk_tiler, (0, None, None)), (None, None, None)
        )
        tCgA = thr_mma.partition_A(gA_mkl)
        tCgB = thr_mma.partition_B(gB_nkl)

        if is_tma_thr:
            while work_tile.is_valid_tile:
                # Get tile coord from tile scheduler
                cur_tile_coord = work_tile.tile_idx
                mma_tile_coord_m = cur_tile_coord[0] // cluster_layout_v_size
                tAgA_slice = tCgA[
                    (None, None, None, mma_tile_coord_m, None, cur_tile_coord[2])
                ]
                tBgB_slice = tCgB[
                    (None, None, None, cur_tile_coord[1], None, cur_tile_coord[2])
                ]

                for k in cutlass.range(0, k_tile_size, 1, unroll=1):
                    gA_k = tAgA_slice[(None, None, None, k)]
                    gB_k = tBgB_slice[(None, None, None, k)]
                    producer_stage_token, idx = (
                        mainloop_pipe.producer_acquire_and_get_stage()
                    )
                    mbar = cute_ext.get_mbarrier(producer_stage_token)
                    bufferA_sliced = bufferA[None, None, None, idx]
                    bufferB_sliced = bufferB[None, None, None, idx]
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

                    # For 2-CTA mode, only leader CTA commits
                    if cutlass.const_expr(self.use_2cta_instrs):
                        if is_leader_cta:
                            mainloop_pipe.producer_commit()
                        mainloop_pipe.producer_state = (
                            cute_ext.pipeline_advance_iterator(
                                mainloop_pipe.raw_pipeline,
                                mainloop_pipe.producer_state,
                            )
                        )
                    else:
                        mainloop_pipe.producer_commit_and_advance()

                # Advance to next tile
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()

        if is_mma_thr and is_leader_cta:
            while work_tile.is_valid_tile:
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
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()

        if is_c_load_thr:
            # Pre-compute subtile count using initial work tile coordinates
            init_coord = work_tile.tile_idx
            gC_tile_tmp = gC[
                (None, None),
                (init_coord[0], init_coord[1], init_coord[2]),
            ]
            gC_epi_tmp = cute.flat_divide(gC_tile_tmp, epi_tile)
            subtile_cnt = cute.size(gC_epi_tmp.shape, mode=[3])

            while work_tile.is_valid_tile:
                cur_tile_coord = work_tile.tile_idx
                gC_tile = gC[
                    (None, None),
                    (cur_tile_coord[0], cur_tile_coord[1], cur_tile_coord[2]),
                ]
                gC_mnl_epi = cute.flat_divide(gC_tile, epi_tile)

                for mn in range(subtile_cnt):
                    token, c_idx = c_load_pipe.producer_acquire_and_get_stage()
                    mbar_c = cute_ext.get_mbarrier(token)

                    cute_ext.tma_load(
                        gC_mnl_epi[None, None, 0, mn],
                        bufferSC[None, None, c_idx],
                        mbar_c,
                        tma_operation_type=cute_ext.OperationTypeEnum.SM90_TMA_LOAD,
                    )
                    c_load_pipe.producer_commit_and_advance()

                # Advance to next tile
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()

        if is_epi_thr:
            # S2R copy for reading C from SMEM to RMEM
            tiled_copy_s2r = cute.make_tiled_copy_D(
                cute.make_copy_atom(cute.nvgpu.CopyUniversalOp(), c_dtype),
                tiled_copy_t2r,
            )

            while work_tile.is_valid_tile:
                cur_tile_coord = work_tile.tile_idx
                gD_tile = gD[
                    (None, None),
                    (cur_tile_coord[0], cur_tile_coord[1], cur_tile_coord[2]),
                ]
                gD_mnl_epi = cute.flat_divide(gD_tile, epi_tile)

                _, idx = acc_pipe.consumer_wait_and_get_stage()
                ## acc_consume_body begin ##
                accumulators_sliced = bufferAcc[(None, None), 0, 0, idx]
                acc_epi_div_tiled = cute.flat_divide(accumulators_sliced, epi_tile)
                subtile_cnt = cute.size(acc_epi_div_tiled.shape, mode=[3])

                for mn in range(subtile_cnt):
                    # TMEM -> RMEM
                    cute_ext.partition_and_copy(
                        tiled_copy_t2r.get_slice(tid_x),
                        acc_epi_div_tiled[None, None, 0, mn],
                        bufferRAcc,
                    )

                    # Wait for C TMA load, SMEM -> RMEM
                    _, c_idx = c_load_pipe.consumer_wait_and_get_stage()
                    cute_ext.partition_and_copy(
                        tiled_copy_s2r.get_slice(tid_x),
                        bufferSC[None, None, c_idx],
                        bufferRC,
                    )
                    c_load_pipe.consumer_release_and_advance()

                    # D = epilogue_op(alpha * acc + beta * C)
                    acc_val = bufferRAcc.load().to(self.epi_dtype)
                    c_val = bufferRC.load().to(self.epi_dtype)
                    d_val = self.epilogue_op(
                        alpha.to(self.epi_dtype) * acc_val
                        + beta.to(self.epi_dtype) * c_val
                    ).to(d_dtype)
                    bufferRD.store(d_val)

                    # Acquire pipeline stage and synchronize before RMEM->SMEM copy
                    tma_store_pipe.acquire_sync()
                    store_idx = tma_store_pipe.get_index()

                    # RMEM -> SMEM
                    tiled_copy_r2s = cute.make_tiled_copy_D(
                        cute.make_copy_atom(cute.nvgpu.CopyUniversalOp(), d_dtype),
                        tiled_copy_t2r,
                    )
                    cute_ext.partition_and_copy(
                        tiled_copy_r2s.get_slice(tid_x),
                        bufferRD,
                        bufferD[None, None, store_idx],
                    )

                    # Fence SMEM writes and synchronize before TMA store
                    tma_store_pipe.commit_sync()

                    # SMEM -> GMEM (only designated TMA store warp performs TMA store)
                    if warp_idx == tma_store_warp_id:
                        cute_ext.tma_store(
                            bufferD[None, None, store_idx],
                            gD_mnl_epi[None, None, 0, mn],
                        )

                    # Release pipeline stage and advance
                    tma_store_pipe.release_advance()

                tma_store_pipe.tail()
                acc_pipe.consumer_release_and_advance()

                # Advance to next tile
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()


def prepare_tensors(mnkl, ab_dtype, c_dtype, d_dtype, a_major, b_major, cd_major):
    """Prepare FP32 source tensors on GPU in PyTorch (l,m,k) convention.

    Returns FP32 source tensors and dtype-converted storage tensors.
    """
    m, n, k, l = mnkl

    if a_major == "k":
        a_f32 = torch.empty((l, m, k), dtype=torch.float32, device="cuda")
    elif a_major == "m":
        a_f32 = torch.empty((l, k, m), dtype=torch.float32, device="cuda").permute(
            0, 2, 1
        )

    if b_major == "n":
        b_f32 = torch.empty((l, k, n), dtype=torch.float32, device="cuda")
    elif b_major == "k":
        b_f32 = torch.empty((l, n, k), dtype=torch.float32, device="cuda").permute(
            0, 2, 1
        )

    if cd_major == "n":
        c_f32 = torch.empty((l, m, n), dtype=torch.float32, device="cuda")
        d_f32 = torch.empty((l, m, n), dtype=torch.float32, device="cuda")
    elif cd_major == "m":
        c_f32 = torch.empty((l, n, m), dtype=torch.float32, device="cuda").permute(
            0, 2, 1
        )
        d_f32 = torch.empty((l, n, m), dtype=torch.float32, device="cuda").permute(
            0, 2, 1
        )

    a_f32.random_(-2, 3)
    b_f32.random_(-2, 3)
    c_f32.random_(-2, 3)
    d_f32.random_(-2, 3)

    a_storage = a_f32.to(dtype=torch_dtype(ab_dtype))
    b_storage = b_f32.to(dtype=torch_dtype(ab_dtype))
    c_storage = c_f32.to(dtype=torch_dtype(c_dtype))
    d_storage = d_f32.to(dtype=torch_dtype(d_dtype))

    return (a_f32, b_f32, c_f32, d_f32, a_storage, b_storage, c_storage, d_storage)


def create_tensors(mnkl, ab_dtype, c_dtype, d_dtype, a_major, b_major, cd_major):
    """Create CuTe tensors in (m,k,l) convention for the kernel.

    Uses prepare_tensors for FP32 source data (PyTorch (l,m,k) convention),
    then creates CuTe tensors in (m,k,l) convention via cutlass_torch.matrix/cute_tensor_like.
    The FP32 source data is converted to target dtype and copied to match the CuTe layout.
    """
    torch.manual_seed(1111)
    m, n, k, l = mnkl

    # Get FP32 source data in PyTorch (l,m,k) convention (for reference)
    a_f32, b_f32, c_f32, d_f32, a_storage, b_storage, c_storage, d_storage = (
        prepare_tensors(mnkl, ab_dtype, c_dtype, d_dtype, a_major, b_major, cd_major)
    )

    # Create CuTe tensors in (m,k,l) convention using cutlass_torch.matrix,
    # then copy the data from the GPU storage tensors.
    a_cpu = cutlass_torch.matrix(l, m, k, a_major == "m", ab_dtype)
    b_cpu = cutlass_torch.matrix(l, n, k, b_major == "n", ab_dtype)
    c_cpu = cutlass_torch.matrix(l, m, n, cd_major == "m", c_dtype)
    d_cpu = cutlass_torch.matrix(l, m, n, cd_major == "m", d_dtype)

    # Copy data from GPU storage (l,m,k) to CPU (m,k,l) layout
    # a_storage is (l,m,k) on GPU, a_cpu is (m,k,l) on CPU — same data, different convention
    a_cpu.copy_(a_storage.permute(1, 2, 0))
    b_cpu.copy_(b_storage.permute(2, 1, 0))  # (l,k,n) → (n,k,l)
    c_cpu.copy_(c_storage.permute(1, 2, 0))  # (l,m,n) → (m,n,l)
    d_cpu.copy_(d_storage.permute(1, 2, 0))

    a_tensor, _ = cutlass_torch.cute_tensor_like(
        a_cpu,
        ab_dtype,
        is_dynamic_layout=True,
        assumed_align=16,
    )
    b_tensor, _ = cutlass_torch.cute_tensor_like(
        b_cpu,
        ab_dtype,
        is_dynamic_layout=True,
        assumed_align=16,
    )
    c_tensor, _ = cutlass_torch.cute_tensor_like(
        c_cpu,
        c_dtype,
        is_dynamic_layout=True,
        assumed_align=16,
    )
    d_tensor, d_torch_gpu = cutlass_torch.cute_tensor_like(
        d_cpu,
        d_dtype,
        is_dynamic_layout=True,
        assumed_align=16,
    )

    return (
        a_tensor,
        b_tensor,
        c_tensor,
        d_tensor,
        a_f32,
        b_f32,
        c_f32,
        d_f32,
        d_torch_gpu,
    )


def compare(
    a_f32,
    b_f32,
    c_f32,
    d_torch_gpu,
    alpha_val,
    beta_val,
    epi_dtype,
    d_dtype,
    tolerance,
    ref_epilogue_fn=None,
):
    # Reference: bmm on FP32 GPU tensors in (l,m,k) convention.
    torch_epi_dtype = torch_dtype(epi_dtype)
    torch_d_dtype = torch_dtype(d_dtype)
    torch_alpha = torch.tensor(alpha_val, dtype=torch_epi_dtype)
    torch_beta = torch.tensor(beta_val, dtype=torch_epi_dtype)
    ref = torch.bmm(a_f32, b_f32)
    ref_d = torch_alpha * ref.to(dtype=torch_epi_dtype) + torch_beta * c_f32.to(
        dtype=torch_epi_dtype
    )
    if ref_epilogue_fn is not None:
        ref_d = ref_epilogue_fn(ref_d)
    ref_d = ref_d.to(dtype=torch_d_dtype)

    # d_torch_gpu is (m,n,l) on GPU; ref_d is (l,m,n) on GPU — permute to match
    torch.testing.assert_close(
        d_torch_gpu.permute(2, 0, 1).to(dtype=torch.float32),
        ref_d.to(dtype=torch.float32),
        atol=tolerance,
        rtol=1e-03,
    )


def run(
    mnkl: Tuple[int, int, int, int],
    mma_tiler_mn: Tuple[int, int],
    cluster_shape_mn: Tuple[int, int],
    ab_dtype: Type[Numeric],
    c_dtype: Type[Numeric],
    d_dtype: Type[Numeric],
    acc_dtype: Type[Numeric],
    epi_dtype: Type[Numeric],
    a_major: str,
    b_major: str,
    cd_major: str,
    alpha_val: float = 1.0,
    beta_val: float = 0.0,
    warmup_iterations: int = 0,
    iterations: int = 1,
    use_cold_l2: bool = False,
    tolerance: float = 1e-02,
    skip_ref_check: bool = False,
    use_2cta_instrs: bool = False,
    fallback_cluster_shape_mn: Tuple[int, int] = None,
    **kwargs,
):
    """Execute a persistent batched GEMM: D = alpha * A @ B + beta * C."""
    cli.print_problem_config(
        "Blackwell Dense GEMM Alpha-Beta Persistent",
        mnkl,
        dtypes={"AB": ab_dtype, "C": c_dtype, "D": d_dtype},
        lines=[f"Acc dtype: {acc_dtype}, Epi dtype: {epi_dtype}"],
        majors={"A": a_major, "B": b_major, "C/D": cd_major},
        mma_tiler_mn=mma_tiler_mn,
        cluster_shape_mn=cluster_shape_mn,
    )
    if fallback_cluster_shape_mn is not None:
        print(f"Fallback Cluster Shape (M, N): {fallback_cluster_shape_mn}")
    print(f"Use 2-CTA instructions: {use_2cta_instrs}")
    print(f"alpha: {alpha_val}, beta: {beta_val}")
    cli.print_benchmark_config(
        tolerance=tolerance,
        warmup_iterations=warmup_iterations,
        iterations=iterations,
        skip_ref_check=skip_ref_check,
        use_cold_l2=use_cold_l2,
    )

    m, n, k, l = mnkl

    (
        a_tensor,
        b_tensor,
        c_tensor,
        d_tensor,
        a_f32,
        b_f32,
        c_f32,
        d_f32,
        d_torch_gpu,
    ) = create_tensors(mnkl, ab_dtype, c_dtype, d_dtype, a_major, b_major, cd_major)

    max_active_clusters = utils.HardwareInfo().get_max_active_clusters(
        cluster_shape_mn[0] * cluster_shape_mn[1],
    )
    if fallback_cluster_shape_mn is not None:
        max_active_fallback_clusters = utils.HardwareInfo().get_max_active_clusters(
            fallback_cluster_shape_mn[0] * fallback_cluster_shape_mn[1]
        )
    else:
        max_active_fallback_clusters = None

    gemm = PersistentDenseGemmAlphaBetaKernel(
        mn_tiler=mma_tiler_mn,
        mma_dtype=(ab_dtype, acc_dtype),
        tmem_output_dtype=d_dtype,
        epi_dtype=epi_dtype,
        use_2cta_instrs=use_2cta_instrs,
        cluster_shape_mn=cluster_shape_mn,
        max_active_clusters=max_active_clusters,
        fallback_cluster_shape_mn=fallback_cluster_shape_mn,
        max_active_fallback_clusters=max_active_fallback_clusters,
    )

    alpha = cutlass.Float32(alpha_val)
    beta = cutlass.Float32(beta_val)

    compiled = cute_ext.compile(
        gemm, a_tensor, b_tensor, c_tensor, d_tensor, alpha, beta
    )
    if hasattr(compiled.engine, "initialize"):
        compiled.engine.initialize()

    compiled(a_tensor, b_tensor, c_tensor, d_tensor, alpha, beta)

    if not skip_ref_check:
        compare(
            a_f32,
            b_f32,
            c_f32,
            d_torch_gpu,
            alpha_val,
            beta_val,
            epi_dtype,
            d_dtype,
            tolerance,
        )
        print("check reference: PASS")

    def generate_tensors():
        (a_t, b_t, c_t, d_t, _, _, _, _, _) = create_tensors(
            mnkl,
            ab_dtype,
            c_dtype,
            d_dtype,
            a_major,
            b_major,
            cd_major,
        )
        return testing.JitArguments(a_t, b_t, c_t, d_t, alpha, beta)

    workspace_count = 1
    if use_cold_l2:
        one_workspace_bytes = (
            a_f32.numel() * a_f32.element_size()
            + b_f32.numel() * b_f32.element_size()
            + c_f32.numel() * c_f32.element_size()
            + d_f32.numel() * d_f32.element_size()
        )
        workspace_count = testing.get_workspace_count(
            one_workspace_bytes,
            warmup_iterations,
            iterations,
        )

    exec_time = testing.benchmark(
        compiled,
        workspace_generator=generate_tensors,
        workspace_count=workspace_count,
        warmup_iterations=warmup_iterations,
        iterations=iterations,
    )

    return exec_time


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Example of Dense GEMM Alpha-Beta Persistent on Blackwell.",
    )

    cli.add_mnkl_arg(parser)
    cli.add_mma_tiler_arg(parser)
    cli.add_cluster_shape_arg(parser)
    cli.add_dtype_args(parser, ab=cutlass.Float16, c=cutlass.Float16)
    # C and D share --cd_major here, so declare the majors this kernel takes.
    cli.add_major_args(parser, c=None)

    parser.add_argument(
        "--fallback_cluster_shape_mn",
        type=cli.comma_separated_ints,
        default=None,
        help="Optional fallback cluster shape (comma-separated).",
    )
    parser.add_argument("--d_dtype", type=cutlass.dtype, default=cutlass.Float16)
    parser.add_argument("--epi_dtype", type=cutlass.dtype, default=cutlass.Float32)
    parser.add_argument("--cd_major", choices=["n", "m"], type=str, default="n")
    parser.add_argument("--alpha", type=float, default=1.0)
    parser.add_argument("--beta", type=float, default=0.0)

    cli.add_benchmark_args(parser, tolerance=1e-02)

    parser.add_argument(
        "--use_2cta_instrs",
        action="store_true",
        help="Use 2-CTA (2SM) instructions for larger tile sizes",
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
        args.d_dtype,
        args.acc_dtype,
        args.epi_dtype,
        args.a_major,
        args.b_major,
        args.cd_major,
        args.alpha,
        args.beta,
        args.warmup_iterations,
        args.iterations,
        args.use_cold_l2,
        args.tolerance,
        args.skip_ref_check,
        args.use_2cta_instrs,
        fallback_cluster_shape_mn=args.fallback_cluster_shape_mn,
    )

    print(f"Execution time: {exec_time} microseconds per iteration")
