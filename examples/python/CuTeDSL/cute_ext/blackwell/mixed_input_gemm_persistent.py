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
import sys
from pathlib import Path

import torch
from typing import Type, Tuple

import cuda.bindings.driver as cuda

import cutlass
from cutlass.cute import experimental as cute_ext
from cutlass.base_dsl.typing import Numeric
from cutlass import cute as cute
import cutlass.pipeline as pipeline
from cutlass import utils
from cutlass import tensor_utils
from cutlass import memory
from cutlass import torch as cutlass_torch
import cutlass.utils.blackwell_helpers as sm100_utils
import cutlass.utils.mixed_input_helpers as mixed_input_utils
from cutlass.experimental import primitives


import cutlass.testing as testing

if __name__ == "__main__":
    _cutedsl_root = Path(__file__).resolve().parents[2]
    sys.path.insert(0, str(_cutedsl_root))
    sys.path.insert(0, str(_cutedsl_root / "cute"))

from helpers.static_persistent_tile_scheduler import (
    PersistentTileSchedulerParams,
    StaticPersistentTileScheduler,
)
from blackwell.kernel.mixed_input_gemm import mixed_input_host_utils as mihu


class MixedInputPersistentDenseGemmKernel:
    def __init__(
        self,
        mnk_tiler: tuple[int, int, int],
        a_dtype: Type[Numeric],
        b_dtype: Type[Numeric],
        acc_dtype: Type[Numeric],
        tmem_output_dtype: Type[Numeric],
        max_active_clusters: int,
        shuffle_a: bool,
        cluster_shape_mn: Tuple[int, int],
        use_2cta_instrs: bool,
        epilogue_op=lambda x: x,
        swizzle_size: int = 1,
        raster_along_m: bool = True,
    ):
        self.mnk_tiler = mnk_tiler
        self.a_dtype = a_dtype
        self.b_dtype = b_dtype
        self.acc_dtype = acc_dtype
        self.tmem_output_dtype = tmem_output_dtype
        self.epilogue_op = epilogue_op
        self.cluster_shape = (*cluster_shape_mn, 1)
        cluster_shape_mn_selfcast = (2, 1) if use_2cta_instrs else (1, 1)
        self.use_tma_multicast = cluster_shape_mn != cluster_shape_mn_selfcast
        self.use_2cta_instrs = use_2cta_instrs
        self.max_active_clusters = max_active_clusters
        self.scale_mode = mixed_input_utils.TransformMode.ConvertOnly
        self.shuffle_a = shuffle_a
        if swizzle_size <= 0:
            raise ValueError(
                f"swizzle_size must be a positive integer, got {swizzle_size}"
            )
        self.swizzle_size = swizzle_size
        self.raster_along_m = raster_along_m

    def compute_stages(
        self,
        mA: cute.Tensor,
        mB: cute.Tensor,
        mD: cute.Tensor,
    ) -> tuple[int, int, int, int]:
        """
        Compute pipeline stage counts from SMEM/TMEM capacity.

        The accumulator pipeline gets as many stages as fit in tensor memory.
        Shared memory is then split between the load-to-transform buffers
        (quantized A and B), the transform-to-MMA buffers (converted A), and
        the epilogue store buffers (C), with leftover capacity spent on extra
        epilogue stages.

        :return: (load2trans_stage, trans2mma_stage, acc_stage, tma_store_stage)
        """
        # Mirror the tiled MMA and tile shapes constructed in kernel().
        if cutlass.const_expr(self.use_2cta_instrs):
            cta_group = cute.nvgpu.tcgen05.CtaGroup.TWO
        else:
            cta_group = cute.nvgpu.tcgen05.CtaGroup.ONE
        tiled_mma = sm100_utils.make_trivial_tiled_mma(
            a_dtype=self.b_dtype,
            b_dtype=self.b_dtype,
            a_leading_mode=tensor_utils.LayoutEnum.from_tensor(mA).mma_major_mode(),
            b_leading_mode=tensor_utils.LayoutEnum.from_tensor(mB).mma_major_mode(),
            acc_dtype=self.acc_dtype,
            cta_group=cta_group,
            mma_tiler_mn=self.mnk_tiler[:2],
        )
        mma_inst_shape_k = cute.size(tiled_mma.shape_mnk, mode=[2])
        mma_inst_tile_k = 4
        mnk_tiler = (
            self.mnk_tiler[0],
            self.mnk_tiler[1],
            mma_inst_shape_k * mma_inst_tile_k,
        )
        num_mma_ctas = cute.size(tiled_mma.thr_id.shape)
        cta_tile_shape_mnk = cute.shape_div(mnk_tiler, (num_mma_ctas, 1, 1))

        # Accumulator stages: as many accumulator buffers as fit in TMEM.
        acc_shape = tiled_mma.partition_shape_C(mnk_tiler[:2])
        tCtAcc_one_stage = tiled_mma.make_fragment_C(cute.append(acc_shape, 1))
        num_tmem_acc_cols_per_stage = memory.get_num_tmem_alloc_cols(
            tCtAcc_one_stage, True
        )
        sm100_tmem_cols = cute.arch.get_max_tmem_alloc_cols("sm_100")
        acc_stage = sm100_tmem_cols // num_tmem_acc_cols_per_stage

        smem_capacity = memory.get_smem_capacity_in_bytes("sm_100")
        smem_buffer_align_bytes = 1024
        # One full/empty mbarrier pair per pipeline stage.
        bytes_per_pipeline_stage = 16

        # Epilogue C buffer, sized like cute_ext.epilogue_tma_store allocates it.
        c_layout = tensor_utils.LayoutEnum.from_tensor(mD)
        epi_tile = sm100_utils.compute_epilogue_tile_shape(
            cta_tile_shape_mnk,
            self.use_2cta_instrs,
            c_layout,
            self.tmem_output_dtype,
        )
        c_bytes_per_stage = cute.size_in_bytes(
            self.tmem_output_dtype,
            sm100_utils.make_smem_layout_epi(
                self.tmem_output_dtype, c_layout, epi_tile, 1
            ),
        )
        tma_store_stage = 2
        carveout_smem_bytes = (
            bytes_per_pipeline_stage * acc_stage + c_bytes_per_stage * tma_store_stage
        )

        a_load_bytes_per_stage = cute.round_up(
            cute.size_in_bytes(
                self.a_dtype,
                cute.make_layout((cta_tile_shape_mnk[0], cta_tile_shape_mnk[2])),
            ),
            smem_buffer_align_bytes,
        )
        b_load_bytes_per_stage = cute.round_up(
            cute.size_in_bytes(
                self.b_dtype,
                cute.make_layout(
                    (cta_tile_shape_mnk[1] // num_mma_ctas, cta_tile_shape_mnk[2])
                ),
            ),
            smem_buffer_align_bytes,
        )
        # A and B are staged together by the load2trans pipeline; the A and B
        # pipelines each need an mbarrier pair per stage.
        ab_load_bytes_per_stage = (
            a_load_bytes_per_stage
            + b_load_bytes_per_stage
            + 2 * bytes_per_pipeline_stage
        )
        # Transformed A is stored in the MMA dtype (b_dtype).
        a_transform_bytes_per_stage = (
            cute.round_up(
                cute.size_in_bytes(
                    self.b_dtype,
                    cute.make_layout((cta_tile_shape_mnk[0], cta_tile_shape_mnk[2])),
                ),
                smem_buffer_align_bytes,
            )
            + bytes_per_pipeline_stage
        )

        trans2mma_stage = (smem_capacity - carveout_smem_bytes) // (
            ab_load_bytes_per_stage + a_transform_bytes_per_stage
        )
        load2trans_stage = (
            smem_capacity
            - carveout_smem_bytes
            - trans2mma_stage * a_transform_bytes_per_stage
        ) // ab_load_bytes_per_stage
        if load2trans_stage < 2 or trans2mma_stage < 2 or acc_stage < 1:
            raise ValueError("Not enough SMEM or TMEM capacity for selected tile size")

        # Spend leftover SMEM on extra epilogue stages.
        tma_store_stage += (
            smem_capacity
            - carveout_smem_bytes
            - load2trans_stage * ab_load_bytes_per_stage
            - trans2mma_stage * a_transform_bytes_per_stage
        ) // c_bytes_per_stage

        return load2trans_stage, trans2mma_stage, acc_stage, tma_store_stage

    @cute.jit
    def __call__(
        self,
        mA: cute.Tensor,
        mB: cute.Tensor,
        mD: cute.Tensor,
        stream: cuda.CUstream,
    ):
        (
            self.load2trans_stage,
            self.trans2mma_stage,
            self.acc_stage,
            self.tma_store_stage,
        ) = self.compute_stages(mA, mB, mD)

        cta_tile_mnk = (
            self.mnk_tiler[0] // 2 if self.use_2cta_instrs else self.mnk_tiler[0],
            self.mnk_tiler[1],
            1,
        )
        num_ctas_mnl = cute.ceil_div(mD.shape, cta_tile_mnk)
        tile_sched_params = PersistentTileSchedulerParams(
            num_ctas_mnl,
            self.cluster_shape,
            swizzle_size=self.swizzle_size,
            raster_along_m=self.raster_along_m,
        )
        grid = StaticPersistentTileScheduler.get_grid_shape(
            tile_sched_params, self.max_active_clusters
        )

        @cute.struct
        class SharedStorage:
            a_load2trans_full_mbar_ptr: cute.struct.MemRange[
                cutlass.Int64, self.load2trans_stage
            ]
            a_load2trans_empty_mbar_ptr: cute.struct.MemRange[
                cutlass.Int64, self.load2trans_stage
            ]
            a_trans2mma_full_mbar_ptr: cute.struct.MemRange[
                cutlass.Int64, self.trans2mma_stage
            ]
            a_trans2mma_empty_mbar_ptr: cute.struct.MemRange[
                cutlass.Int64, self.trans2mma_stage
            ]

        self.shared_storage = SharedStorage

        self.kernel(mA, mB, mD, tile_sched_params).launch(
            grid=grid,
            block=(12 * 32, 1, 1),
            cluster=self.cluster_shape,
            stream=stream,
        )

    @cute.kernel
    def kernel(
        self,
        mA: cute.Tensor,
        mB: cute.Tensor,
        mD: cute.Tensor,
        tile_sched_params: PersistentTileSchedulerParams,
    ):
        if cutlass.const_expr(self.use_2cta_instrs):
            cta_group = cute.nvgpu.tcgen05.CtaGroup.TWO
        else:
            cta_group = cute.nvgpu.tcgen05.CtaGroup.ONE
        tiled_mma = sm100_utils.make_trivial_tiled_mma(
            a_dtype=self.b_dtype,
            b_dtype=self.b_dtype,
            a_leading_mode=tensor_utils.LayoutEnum.from_tensor(mA).mma_major_mode(),
            b_leading_mode=tensor_utils.LayoutEnum.from_tensor(mB).mma_major_mode(),
            acc_dtype=self.acc_dtype,
            cta_group=cta_group,
            mma_tiler_mn=self.mnk_tiler[:2],
        )

        mma_inst_shape_k = cute.size(tiled_mma.shape_mnk, mode=[2])
        mma_inst_tile_k = 4

        # Tiler for 2xSM if use 2xSM, otherwise it's for 1 SM/cta.
        mnk_tiler = (
            self.mnk_tiler[0],
            self.mnk_tiler[1],
            mma_inst_shape_k * mma_inst_tile_k,
        )

        # Tiler down to 1 SM
        # For 2xSM, each CTA loads half of mma_M for A and half of mma_N for B.
        # The accumulator is split along M only (each CTA holds full N columns).
        num_mma_ctas = cute.size(tiled_mma.thr_id.shape)
        cta_tile_shape_mnk = cute.shape_div(mnk_tiler, (num_mma_ctas, 1, 1))
        # A is tiled (M/2, K) for 2CTA
        a_tiler_mk = (cta_tile_shape_mnk[0], cta_tile_shape_mnk[2])
        # B is tiled (N/2, K) for 2CTA
        b_tiler_nk = (cta_tile_shape_mnk[1] // num_mma_ctas, cta_tile_shape_mnk[2])

        gA = cute.zipped_divide(mA, a_tiler_mk)
        gB = cute.zipped_divide(mB, b_tiler_nk)

        cta_m, cta_n, cta_l = cute.arch.block_idx()

        # Cluster layout for 2-CTA coordination
        cluster_layout_vmnk = cute.tiled_divide(
            cute.make_layout(self.cluster_shape),
            (tiled_mma.thr_id.shape,),
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

        # Compute A/B/C shared memory layout
        a_quant_smem_layout_staged = sm100_utils.make_smem_layout_a(
            tiled_mma,
            mnk_tiler,
            mA.dtype,
            self.load2trans_stage,
        )
        a_smem_layout_staged = sm100_utils.make_smem_layout_a(
            tiled_mma,
            mnk_tiler,
            self.b_dtype,  # NB
            self.trans2mma_stage,
        )
        b_smem_layout_staged = sm100_utils.make_smem_layout_b(
            tiled_mma,
            mnk_tiler,
            self.b_dtype,
            self.load2trans_stage,
        )

        # UMMA ACC TMEM Layout
        tmem_layout = cute_ext.make_tmem_layout_acc(
            tiled_mma, mnk_tiler, self.acc_stage
        )

        bufferA_quant = cute_ext.allocate(
            mA.dtype,
            cute.AddressSpace.smem,
            a_quant_smem_layout_staged,
            alignment=1024,
        )

        # Allocate UMMA Buffers
        bufferA = cute_ext.allocate(
            mB.dtype,  # NB
            cute.AddressSpace.smem,
            a_smem_layout_staged,
            alignment=1024,
        )

        bufferB = cute_ext.allocate(
            mB.dtype,
            cute.AddressSpace.smem,
            b_smem_layout_staged,
            alignment=1024,
        )

        bufferAcc = cute_ext.allocate(
            self.acc_dtype,
            cute.AddressSpace.tmem,
            tmem_layout,
            alignment=16,
            is2cta=self.use_2cta_instrs,
        )

        a_tma_operation_type = cute_ext.OperationTypeEnum.SM90_TMA_LOAD
        if cutlass.const_expr(self.use_2cta_instrs):
            mma_operation_type = cute_ext.OperationTypeEnum.SM100_MMA_2SM_SS
            if cutlass.const_expr(self.use_tma_multicast):
                b_tma_operation_type = (
                    cute_ext.OperationTypeEnum.SM100_TMA_LOAD_2SM_MULTICAST
                )
            else:
                b_tma_operation_type = cute_ext.OperationTypeEnum.SM100_TMA_LOAD_2SM
        else:
            mma_operation_type = cute_ext.OperationTypeEnum.SM100_MMA_1SM_SS
            if cutlass.const_expr(self.use_tma_multicast):
                b_tma_operation_type = (
                    cute_ext.OperationTypeEnum.SM90_TMA_LOAD_MULTICAST
                )
            else:
                b_tma_operation_type = cute_ext.OperationTypeEnum.SM90_TMA_LOAD

        cvt_thread_count = 128

        multicast_mode_a = 2  # multicast across the "N" dimension of the cluster
        multicast_mode_b = 1  # multicast across the "M" dimension of the cluster
        # TMA -> conversion pipeline for A
        smem = cutlass.memory.SmemAllocator()
        storage = smem.allocate(self.shared_storage)
        a_copy_size = cute.size_in_bytes(
            self.a_dtype, cute.slice_(a_quant_smem_layout_staged, (None, None, None, 0))
        )
        tidx, _, _ = cute.arch.thread_idx()

        warp_idx = cute.arch.warp_idx()
        warp_idx = cute.arch.make_warp_uniform(warp_idx)
        # warp assignment: [0]-tma_store, [0-3]-epi, [4]-mma, [5]-tma_load,
        # [6-7]-unused, [8-11]-transform
        tma_store_warp_id = 0
        mma_warp_id = 4
        tma_load_warp_id = 5
        cvt_lead_warp_id = 8
        is_tma_thr = warp_idx == tma_load_warp_id
        is_mma_thr = warp_idx == mma_warp_id
        is_epi_thr = warp_idx < 4
        is_cvt_thr = warp_idx >= cvt_lead_warp_id

        transform_thread_tidx = (
            tidx - 32 * cvt_lead_warp_id if tidx >= 32 * cvt_lead_warp_id else tidx
        )

        a_load2trans_pipeline = pipeline.PipelineTmaAsync.create(
            barrier_storage=storage.a_load2trans_full_mbar_ptr.data_ptr(),
            num_stages=self.load2trans_stage,
            producer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread),
            consumer_group=pipeline.CooperativeGroup(
                pipeline.Agent.Warp,
                cute.arch.constants.WARPS_PER_WARPGROUP,
            ),
            tx_count=a_copy_size,
            cta_layout_vmnk=cluster_layout_vmnk,
            tidx=transform_thread_tidx,
            mcast_mode_mn=(1, 0),  # multicast for A will only happen on the M-mode
            enable_multicast_signaling=True,
        )

        # conversion -> UMMA pipeline for A
        cta_v_size = cute.size(cluster_layout_vmnk, mode=[0])
        trans2mma_pipeline = pipeline.PipelineAsyncUmma.create(
            barrier_storage=storage.a_trans2mma_full_mbar_ptr.data_ptr(),
            num_stages=self.trans2mma_stage,
            producer_group=pipeline.CooperativeGroup(
                pipeline.Agent.Thread,
                cta_v_size * cute.arch.constants.THREADS_PER_WARPGROUP,
            ),
            consumer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread),
            cta_layout_vmnk=cluster_layout_vmnk,
        )

        # TMA -> UMMA pipeline for B
        mainloop_b_pipe = cute_ext.TMAToUMMAPipeline.create(
            num_stages=self.load2trans_stage,
            mma_operation_type=mma_operation_type,
            tma_operation_type=b_tma_operation_type,
            cluster_layout_vmnk=cluster_layout_vmnk,
        )

        acc_pipe = cute_ext.UMMAtoAsyncPipeline.create(
            num_stages=self.acc_stage,
            mma_operation_type=mma_operation_type,
            consumer=cute_ext.OperationTypeEnum.SM100_COPY_T2R,
            consumer_release_threads_per_cta=128,
            cluster_layout_vmnk=cluster_layout_vmnk,
        )

        tma_store_pipe = cute_ext.TMAStorePipeline(
            stages=self.tma_store_stage,
            arv_count=128,
            barrier_id=1,
            tma_warp_id=tma_store_warp_id,
        )

        k_tile_size = cute.size(gA, mode=[1, 1])

        #
        # Persistent tile scheduling loop
        #
        tile_sched = StaticPersistentTileScheduler.create(
            tile_sched_params, cute.arch.block_idx(), cute.arch.grid_dim()
        )
        work_tile = tile_sched.initial_work_tile_info()
        gA_mkl = cute.local_tile(
            mA, cute.slice_(mnk_tiler, (None, 0, None)), (None, None, None)
        )
        gB_nkl = cute.local_tile(
            mB, cute.slice_(mnk_tiler, (0, None, None)), (None, None, None)
        )
        tCgA = thr_mma.partition_A(gA_mkl)
        tCgB = thr_mma.partition_B(gB_nkl)

        if is_tma_thr:
            a_load2trans_producer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Producer, self.load2trans_stage
            )
            while work_tile.is_valid_tile:
                # Get tile coord from tile scheduler
                # The tile scheduler takes into account splitting of the M mode for 2CTA instructions
                cur_tile_coord = work_tile.tile_idx
                # Load the A tile for the current CTA
                # We can use the cur_tile_coord to index into the gA tensor directly
                # Each CTA in the pair loads a half of the M tile
                mma_tile_coord_m = cur_tile_coord[0] // cluster_layout_v_size
                tAgA_slice = tCgA[
                    (None, None, None, mma_tile_coord_m, None, cur_tile_coord[2])
                ]
                tBgB_slice = tCgB[
                    (None, None, None, cur_tile_coord[1], None, cur_tile_coord[2])
                ]
                a_load2trans_producer_state.reset_count()
                for k in cutlass.range(0, k_tile_size, 1, unroll=1):
                    gA_k = tAgA_slice[(None, None, None, k)]
                    gB_k = tBgB_slice[(None, None, None, k)]
                    # Scoped state management - pipeline object manages state internally
                    a_load2trans_pipeline.producer_acquire(a_load2trans_producer_state)
                    a_idx = a_load2trans_producer_state.index
                    (
                        b_producer_stage_token,
                        b_idx,
                    ) = mainloop_b_pipe.producer_acquire_and_get_stage()
                    b_mbar = cute_ext.get_mbarrier(b_producer_stage_token)
                    ## producer_body begin ##
                    bufferA_sliced = bufferA_quant[None, None, None, a_idx]
                    bufferB_sliced = bufferB[None, None, None, b_idx]
                    a_cta_v_map = cute_ext.get_cta_v_map_ab(
                        mA, mnk_tiler, tiled_mma, "A"
                    )
                    b_cta_v_map = cute_ext.get_cta_v_map_ab(
                        mB, mnk_tiler, tiled_mma, "B"
                    )

                    a_mbar = a_load2trans_pipeline.producer_get_barrier(
                        a_load2trans_producer_state
                    ).value
                    cute_ext.tma_load(
                        gA_k,
                        bufferA_sliced,
                        a_mbar,
                        vmnk_layout=cluster_layout_vmnk,
                        cta_v_map=a_cta_v_map,
                        tma_operation_type=a_tma_operation_type,
                        multicast_mode=multicast_mode_a,
                        update_expect_tx=False,
                    )
                    cute_ext.tma_load(
                        gB_k,
                        bufferB_sliced,
                        b_mbar,
                        vmnk_layout=cluster_layout_vmnk,
                        cta_v_map=b_cta_v_map,
                        tma_operation_type=b_tma_operation_type,
                        multicast_mode=multicast_mode_b,
                    )
                    ## producer_body end ##
                    a_load2trans_pipeline.producer_commit(a_load2trans_producer_state)
                    a_load2trans_producer_state.advance()
                    mainloop_b_pipe.producer_commit_and_advance()
                # Advance to next tile
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()

            a_load2trans_pipeline.producer_tail(a_load2trans_producer_state)
            mainloop_b_pipe.producer_tail()

        if is_cvt_thr:
            copy_atom_a_transform = cute.make_copy_atom(
                cute.nvgpu.CopyUniversalOp(),
                self.b_dtype,
                num_bits_per_copy=32,
            )
            # Partition tensors for transform input and output and set up the copy atom
            # used for loading and storing transformed A tensor
            # Construct tiled_copy satisfying 8 contiguous elts per copy atom
            reg2smem_tiled_copy = cute.make_cotiled_copy(
                copy_atom_a_transform,
                cute.make_layout((128, 8), stride=(8, 1)),
                bufferA[(None, None, None, 0)].layout,  # type: ignore[union-attr]
            )
            thr_reg2smem_tiled_copy = reg2smem_tiled_copy.get_slice(
                transform_thread_tidx
            )
            tAsA_input = thr_reg2smem_tiled_copy.partition_S(bufferA_quant)
            tAsA_transform = thr_reg2smem_tiled_copy.partition_D(bufferA)
            # make rmem tensor for input A and transformed A
            tArA = cute.make_rmem_tensor(
                tAsA_input[(None, None, None, None, 0)].shape, tAsA_input.element_type
            )
            tArA_transform = cute.make_rmem_tensor(
                tAsA_input[(None, None, None, None, 0)].shape, self.b_dtype
            )
            transform_tiler_size = min(
                cute.size(cute.coalesce(tAsA_input.layout), mode=[0]), 64
            )
            transform_tiler = cute.make_layout(transform_tiler_size)
            tArA_load = cute.flat_divide(tArA, transform_tiler)
            tArA_load = cute.group_modes(tArA_load, 1, cute.rank(tArA_load))
            tArA_transform_store = cute.flat_divide(tArA_transform, transform_tiler)
            tArA_transform_store = cute.group_modes(
                tArA_transform_store, 1, cute.rank(tArA_transform_store)
            )
            a_load2trans_consumer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Consumer,
                self.load2trans_stage,
            )
            trans2mma_producer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Producer,
                self.trans2mma_stage,
            )
            while work_tile.is_valid_tile:
                a_load2trans_consumer_state.reset_count()
                trans2mma_producer_state.reset_count()
                for k in cutlass.range(0, k_tile_size, 1, unroll=1):
                    a_load2trans_pipeline.consumer_wait(a_load2trans_consumer_state)
                    input_idx = a_load2trans_consumer_state.index
                    # Load A from shared memory
                    tAsA_input_slice = tAsA_input[(None, None, None, None, input_idx)]
                    tAsA_input_slice = cute.flat_divide(
                        tAsA_input_slice, transform_tiler
                    )
                    tAsA_input_slice = cute.group_modes(
                        tAsA_input_slice, 1, cute.rank(tAsA_input_slice)
                    )
                    for idx in cutlass.range_constexpr(cute.size(tArA_load, mode=[1])):
                        # Load A from shared memory
                        cute.autovec_copy(
                            tAsA_input_slice[(None, idx)],
                            tArA_load[(None, idx)],
                        )
                        # Convert it to mma dtype
                        tensor_transformed = mixed_input_utils.cvt_tensor_a(
                            tArA_load[(None, idx)], self.b_dtype, self.shuffle_a
                        )
                        tArA_transform_store[(None, idx)].store(tensor_transformed)
                    trans2mma_pipeline.producer_acquire(trans2mma_producer_state)
                    output_idx = trans2mma_producer_state.index
                    # Store transformed A to tensor memory or shared memory
                    mixed_input_utils.store_transformed_a(
                        tArA_transform,
                        tAsA_transform[(None, None, None, None, output_idx)],
                        copy_atom_a=None,
                    )

                    a_load2trans_pipeline.consumer_release(a_load2trans_consumer_state)
                    a_load2trans_consumer_state.advance()
                    # Make the generic-proxy SMEM stores of transformed A visible
                    # to the async proxy (UMMA) before releasing the consumer.
                    primitives.fence_proxy(
                        kind=primitives.Proxy.ASYNC_SHARED,
                        space=primitives.SharedSpace.shared_cta,
                    )
                    trans2mma_pipeline.producer_commit(trans2mma_producer_state)
                    trans2mma_producer_state.advance()
                # Advance to next tile
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()
            trans2mma_pipeline.producer_tail(trans2mma_producer_state)

        if is_mma_thr and is_leader_cta:
            trans2mma_consumer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Consumer, self.trans2mma_stage
            )
            while work_tile.is_valid_tile:
                _, idx = acc_pipe.producer_acquire_and_get_stage()
                accumulators_sliced = bufferAcc[None, None, None, idx]

                mma_atom = cute.make_mma_atom(tiled_mma.op)
                mma_atom.set(cute.nvgpu.tcgen05.Field.ACCUMULATE, False)

                for _k_tile in cutlass.range(0, k_tile_size, 1, unroll=1):
                    trans2mma_pipeline.consumer_wait(trans2mma_consumer_state)
                    a_buffer_stage_idx = trans2mma_consumer_state.index
                    _, b_buffer_stage_idx = (
                        mainloop_b_pipe.consumer_wait_and_get_stage()
                    )
                    for k_instr_tile in cutlass.range(
                        mma_inst_tile_k, unroll_full=True
                    ):
                        a_buffer_sliced = bufferA[
                            None, None, k_instr_tile, a_buffer_stage_idx
                        ]
                        b_buffer_sliced = bufferB[
                            None, None, k_instr_tile, b_buffer_stage_idx
                        ]
                        cute_ext.dot(
                            mma_atom,
                            a_buffer_sliced,
                            b_buffer_sliced,
                            accumulators_sliced,
                        )
                        mma_atom.set(cute.nvgpu.tcgen05.Field.ACCUMULATE, True)
                    trans2mma_pipeline.consumer_release(trans2mma_consumer_state)
                    trans2mma_consumer_state.advance()
                    mainloop_b_pipe.consumer_release_and_advance()

                acc_pipe.producer_commit_and_advance()
                # Advance to next tile
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()

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
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()

    def can_implement(
        mnkl: tuple[int, int, int, int],
        a_dtype: type[cutlass.Numeric],
        b_dtype: type[cutlass.Numeric],
        c_dtype: type[cutlass.Numeric],
        a_major: str,
        b_major: str,
        c_major: str,
        scale_granularity_m: int,
        scale_granularity_k: int,
        mma_tiler: tuple[int, int, int],
        cluster_shape_mn: tuple[int, int],
        use_2cta_instrs: bool,
        use_tma_store: bool,
    ) -> bool:
        """
        Check if the kernel can be implemented for the given tensor shapes and data types.
        """
        m, n, k, l = mnkl

        if not mixed_input_utils.is_valid_mma_tiler_and_cluster_shape(
            mma_tiler, cluster_shape_mn, use_2cta_instrs
        ):
            return False

        if scale_granularity_m != 0:
            return False
        if scale_granularity_k != 0:
            return False

        if not mixed_input_utils.is_valid_tensor_alignment(
            m,
            n,
            k,
            a_dtype,
            b_dtype,
            c_dtype,
            b_dtype,
            a_major,
            b_major,
            c_major,
            mma_tiler,
            use_2cta_instrs,
            cluster_shape_mn,
            scale_granularity_m,
            scale_granularity_k,
        ):
            return False
        if not use_tma_store:
            return False
        return True


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
    a_dtype: Type[Numeric],
    b_dtype: Type[Numeric],
    c_dtype: Type[Numeric],
    acc_dtype: Type[Numeric],
    a_major: str,
    b_major: str,
    c_major: str,
    mma_tiler_mnk: Tuple[int, int],
    cluster_shape_mn: Tuple[int, int],
    use_2cta_instrs: bool,
    tolerance: float = 1e-02,
    warmup_iterations: int = 0,
    iterations: int = 1,
    skip_ref_check: bool = False,
    use_cold_l2: bool = False,
    *,
    benchmark: str = "default",
    swizzle_size: int = 1,
    raster_along: str = "m",
    **kwargs,
):
    """Execute a batched dense GEMM operation on Blackwell architecture with performance benchmarking.

    This function prepares input tensors, configures and launches the GEMM kernel,
    optionally performs reference validation, and benchmarks the execution performance.

    :param mnkl: Problem size (M, N, K, L)
    :type mnkl: Tuple[int, int, int, int]
    :param mma_tiler_mnk: MMA tiling size.
    :type mma_tiler_mnk: Tuple[int, int, int]
    :param a_dtype: Data type for input tensor A
    :type a_dtype: Type[Numeric]
    :param b_dtype: Data type for input tensor B
    :type b_dtype: Type[Numeric]
    :param c_dtype: Data type for output tensor C
    :type c_dtype: Type[Numeric]
    :param swizzle_size: Tile-scheduler swizzle size in cluster units; 1 disables rasterization.
    :type swizzle_size: int
    :param raster_along: Rasterize clusters along "m" or "n"; only used when swizzle_size > 1.
    :type raster_along: str
    """

    m, n, k, l = mnkl

    scale_granularity_m = 0
    scale_granularity_k = 0
    use_tma_store = True

    # Check if given configuration is supported
    if not MixedInputPersistentDenseGemmKernel.can_implement(
        mnkl,
        a_dtype,
        b_dtype,
        c_dtype,
        a_major,
        b_major,
        c_major,
        scale_granularity_m,
        scale_granularity_k,
        mma_tiler_mnk,
        cluster_shape_mn,
        use_2cta_instrs,
        use_tma_store,
    ):
        raise testing.CantImplementError("GEMM configuration not supported")

    sm100_utils.check_gemm_tma_alignment(
        m,
        n,
        k,
        a_dtype,
        b_dtype,
        c_dtype,
        a_major,
        b_major,
        c_major,
        output_tensor_name="C",
    )

    shuffle_a = mixed_input_utils.is_shuffle_a(
        a_major,
        k,
        a_dtype,
        b_dtype,
        scale_granularity_k,
    )
    (
        a_tensor,
        a_scale_tensor,
        b_tensor,
        c_tensor,
        a_torch_cpu,
        a_scale_torch_cpu,
        b_torch_cpu,
        c_torch_gpu,
    ) = mihu.create_tensors_for_batched_mixed_input_gemm(
        l,
        m,
        n,
        k,
        a_major,
        b_major,
        c_major,
        a_dtype,
        b_dtype,
        c_dtype,
        shuffle_a,
        scale_granularity_m,
        scale_granularity_k,
    )

    max_active_clusters = utils.HardwareInfo().get_max_active_clusters(
        cluster_shape_mn[0] * cluster_shape_mn[1]
    )

    # Get current CUDA stream from PyTorch
    torch_stream = torch.cuda.current_stream()
    # Get the raw stream pointer as a CUstream
    current_stream = cuda.CUstream(torch_stream.cuda_stream)
    mixed_input_gemm = MixedInputPersistentDenseGemmKernel(
        mnk_tiler=mma_tiler_mnk,
        a_dtype=a_dtype,
        b_dtype=b_dtype,
        acc_dtype=acc_dtype,
        tmem_output_dtype=c_dtype,
        max_active_clusters=max_active_clusters,
        shuffle_a=shuffle_a,
        cluster_shape_mn=cluster_shape_mn,
        use_2cta_instrs=use_2cta_instrs,
        swizzle_size=swizzle_size,
        raster_along_m=(raster_along == "m"),
    )

    compiled_mixed_input_gemm = cute.compile(
        mixed_input_gemm,
        a_tensor,
        b_tensor,
        c_tensor,
        current_stream,
    )
    if hasattr(compiled_mixed_input_gemm.engine, "initialize"):
        compiled_mixed_input_gemm.engine.initialize()

    if not skip_ref_check:
        compiled_mixed_input_gemm(
            a_tensor,
            b_tensor,
            c_tensor,
            current_stream,
        )

        mihu.run_batched_mixed_input_ref_and_compare(
            a_torch_cpu, b_torch_cpu, a_scale_torch_cpu, c_torch_gpu, c_dtype, tolerance
        )

    if benchmark == "none":
        return 0

    # Early return if no performance measurement is needed
    if iterations <= 0:
        return

    def generate_tensors():
        (
            a_tensor,
            a_scale_tensor,
            b_tensor,
            c_tensor,
            a_torch_cpu,
            a_scale_torch_cpu,
            b_torch_cpu,
            c_torch_gpu,
        ) = mihu.create_tensors_for_batched_mixed_input_gemm(
            l,
            m,
            n,
            k,
            a_major,
            b_major,
            c_major,
            a_dtype,
            b_dtype,
            c_dtype,
            shuffle_a,
            scale_granularity_m,
            scale_granularity_k,
        )
        return testing.JitArguments(a_tensor, b_tensor, c_tensor, current_stream)

    workspace_count = 1
    if use_cold_l2:
        one_workspace_bytes = (
            a_torch_cpu.numel() * a_torch_cpu.element_size()
            + b_torch_cpu.numel() * b_torch_cpu.element_size()
            + c_torch_gpu.numel() * c_torch_gpu.element_size()
        )
        workspace_count = testing.get_workspace_count(
            one_workspace_bytes, warmup_iterations, iterations
        )

    exec_time = testing.benchmark(
        compiled_mixed_input_gemm,
        workspace_generator=generate_tensors,
        workspace_count=workspace_count,
        stream=current_stream,
        warmup_iterations=warmup_iterations,
        iterations=iterations,
        use_cupti=benchmark == "cupti",
    )

    return exec_time


if __name__ == "__main__":

    def parse_comma_separated_ints(s: str) -> Tuple[int, ...]:
        try:
            return tuple(int(x.strip()) for x in s.split(","))
        except ValueError:
            raise argparse.ArgumentTypeError(
                "Invalid format. Expected comma-separated integers."
            )

    parser = argparse.ArgumentParser(
        description="Example of LIR Dense GEMM on Blackwell."
    )

    parser.add_argument(
        "--mnkl",
        type=parse_comma_separated_ints,
        default=(256, 256, 512, 1),
        help="mnkl dimensions (comma-separated)",
    )
    parser.add_argument(
        "--mma_tiler_mnk",
        type=parse_comma_separated_ints,
        default=(128, 128, 64),
        help="Mma tile shape (comma-separated)",
    )
    parser.add_argument(
        "--cluster_shape_mn",
        type=parse_comma_separated_ints,
        default=(1, 1),
        help="Cluster shape (comma-separated)",
    )

    parser.add_argument("--a_dtype", type=cutlass.dtype, default=cutlass.Int8)
    parser.add_argument("--b_dtype", type=cutlass.dtype, default=cutlass.BFloat16)
    parser.add_argument("--c_dtype", type=cutlass.dtype, default=cutlass.BFloat16)
    parser.add_argument("--acc_dtype", type=cutlass.dtype, default=cutlass.Float32)

    parser.add_argument("--a_major", choices=["k", "m"], type=str, default="k")
    parser.add_argument("--b_major", choices=["k", "n"], type=str, default="k")
    parser.add_argument("--c_major", choices=["n", "m"], type=str, default="n")
    parser.add_argument(
        "--scale_granularity_m",
        type=int,
        default=0,
        help="Scale granularity along M dimension. Only 0 (convert-only) is supported.",
    )
    parser.add_argument(
        "--scale_granularity_k",
        type=int,
        default=0,
        help="Scale granularity along K dimension. Only 0 (convert-only) is supported.",
    )

    parser.add_argument(
        "--use_2cta_instrs", action="store_true", help="Use 2CTA instructions"
    )

    parser.add_argument(
        "--warmup_iterations", type=int, default=0, help="Warmup iterations"
    )
    parser.add_argument(
        "--iterations", type=int, default=1, help="Number of iterations"
    )
    parser.add_argument("--use_cold_l2", action="store_true", help="Use cold L2")
    parser.add_argument(
        "--tolerance", type=float, default=1e-02, help="Tolerance for validation"
    )
    parser.add_argument(
        "--skip_ref_check", action="store_true", help="Skip reference checking"
    )
    parser.add_argument(
        "--benchmark",
        type=str,
        default="default",
        choices=["cupti", "default", "none"],
        help="Benchmark the kernel with cupti or default (cutlass.testing.benchmark) or none",
    )
    parser.add_argument(
        "--swizzle_size",
        type=int,
        default=1,
        help="Swizzling size in the unit of cluster for improving L2 cache hit rate",
    )
    parser.add_argument(
        "--raster_along",
        type=str,
        choices=["m", "n"],
        default="m",
        help="Rasterization order of clusters",
    )

    args = parser.parse_args()

    if len(args.mnkl) != 4:
        parser.error("--mnkl must contain exactly 4 values")

    if len(args.mma_tiler_mnk) != 3:
        parser.error("--mma_tiler_mnk must contain exactly 3 values")

    exec_time = run(
        mnkl=args.mnkl,
        scale_granularity_m=args.scale_granularity_m,
        scale_granularity_k=args.scale_granularity_k,
        mma_tiler_mnk=args.mma_tiler_mnk,
        cluster_shape_mn=args.cluster_shape_mn,
        a_dtype=args.a_dtype,
        b_dtype=args.b_dtype,
        c_dtype=args.c_dtype,
        acc_dtype=args.acc_dtype,
        a_major=args.a_major,
        b_major=args.b_major,
        c_major=args.c_major,
        use_2cta_instrs=args.use_2cta_instrs,
        tolerance=args.tolerance,
        warmup_iterations=args.warmup_iterations,
        iterations=args.iterations,
        use_cold_l2=args.use_cold_l2,
        skip_ref_check=args.skip_ref_check,
        swizzle_size=args.swizzle_size,
        raster_along=args.raster_along,
        benchmark=args.benchmark,
    )

    print(f"Execution time: {exec_time} microseconds per iteration")
