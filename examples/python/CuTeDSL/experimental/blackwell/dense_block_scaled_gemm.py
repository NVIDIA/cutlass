# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
from typing import Type, Tuple
from dataclasses import dataclass
import torch
import cutlass
from cutlass import (
    cute as cute,
    utils as utils,
)
from cutlass.cute import experimental as cute_ext
from cutlass.cute.runtime import from_dlpack
from cutlass.cute.nvgpu import cpasync, tcgen05
import cutlass.utils.blackwell_helpers as sm100_utils
import cutlass.utils.blockscaled_layout as blockscaled_utils

"""

This is an implementation of dense block scaled GEMM.

"""
class BlockScaledDenseGemmKernel:
    def __init__(
        self,
        mma_inst_mn: tuple[int, int],
        mma_dtype: tuple[Type[cutlass.Numeric], Type[cutlass.Numeric]],
        sf_dtype: Type[cutlass.Numeric],
        sf_vec_size: int,
        epilogue_op=lambda x: x,
    ):
        self.ab_dtype, self.acc_dtype = mma_dtype
        self.sf_dtype = sf_dtype
        self.sf_vec_size = sf_vec_size
        self.mma_inst_shape_mn = mma_inst_mn
        self.use_2cta_instrs = False
        self.cta_group = (
            tcgen05.CtaGroup.TWO if self.use_2cta_instrs else tcgen05.CtaGroup.ONE
        )

        self.epilogue_op = epilogue_op
        # TODO: instead of using max shared memory, we should define a SharedStorage and then
        # query its size.
        self.smem_capacity = utils.get_smem_capacity_in_bytes("sm_100")

        # Stages
        self.num_acc_stages = 1 if self.mma_inst_shape_mn[1] == 256 else 2

        # TODO: provide a computation for this so that it is not fixed;
        # fitting as many stages as there is available shared memory
        self.num_main_stages = 4

        self.tma_store_stages = 4

    @cute.experimental.jit
    def __call__(
        self,
        mA: cute.Tensor,
        mSFA: cute.Tensor,
        mB: cute.Tensor,
        mSFB: cute.Tensor,
        mC: cute.Tensor,
    ):
        tile_mn = (*self.mma_inst_shape_mn, 1)
        div = cute.tiled_divide(mC, tile_mn)
        grid = (div.shape[1], div.shape[2], div.shape[3])
        self.kernel(mA, mSFA, mB, mSFB, mC).launch(
            grid=grid,
            # Using a total of 6 warps (1x load + 1x mma + 4x epilogue)
            block=(192, 1, 1),
            cluster=(1, 1, 1),
            smem=self.smem_capacity,
        )

    @cute.experimental.kernel
    def kernel(
        self,
        mA: cute.Tensor,
        mSFA: cute.Tensor,
        mB: cute.Tensor,
        mSFB: cute.Tensor,
        mC: cute.Tensor,
    ):
        # Prologue
        tidx, _, _ = cute.arch.thread_idx()
        warp_idx = cute.arch.warp_idx()
        warp_idx = cute.arch.make_warp_uniform(warp_idx)
        cta_m, cta_n, cta_l = cute.arch.block_idx()

        a_dtype: Type[cutlass.Numeric] = mA.element_type
        sf_dtype: Type[cutlass.Numeric] = mSFA.element_type
        c_dtype: Type[cutlass.Numeric] = mC.element_type
        a_major_mode = utils.LayoutEnum.from_tensor(mA).mma_major_mode()
        b_major_mode = utils.LayoutEnum.from_tensor(mB).mma_major_mode()
        d_layout = utils.LayoutEnum.from_tensor(mC)

        tiled_mma = sm100_utils.make_blockscaled_trivial_tiled_mma(
            a_dtype,
            a_major_mode,
            b_major_mode,
            sf_dtype,
            self.sf_vec_size,
            self.cta_group,
            self.mma_inst_shape_mn,
        )

        mma_inst_shape_k = cute.size(tiled_mma.shape_mnk, mode=[2])
        mma_inst_tile_k = 4
        mma_tiler_mnk = (
            self.mma_inst_shape_mn[0],
            self.mma_inst_shape_mn[1],
            mma_inst_shape_k * mma_inst_tile_k,
        )

        tiler_mk = (mma_tiler_mnk[0], mma_tiler_mnk[2])
        tiler_nk = (mma_tiler_mnk[1], mma_tiler_mnk[2])
        tiler_mn = (mma_tiler_mnk[0], mma_tiler_mnk[1])

        # ((Atom_M, Rest_M),(Atom_K, Rest_K), RestL)
        sfa_layout = blockscaled_utils.tile_atom_to_shape_SF(mA.shape, self.sf_vec_size)
        sfa_tensor = cute.make_tensor(mSFA.iterator, sfa_layout)

        # ((Atom_N, Rest_N),(Atom_K, Rest_K), RestL)
        sfb_layout = blockscaled_utils.tile_atom_to_shape_SF(mB.shape, self.sf_vec_size)
        sfb_tensor = cute.make_tensor(mSFB.iterator, sfb_layout)

        gA = cute.zipped_divide(mA, tiler_mk)
        gB = cute.zipped_divide(mB, tiler_nk)
        gSFA = cute.zipped_divide(sfa_tensor, tiler_mk)
        gSFB = cute.zipped_divide(sfb_tensor, tiler_nk)
        gC = cute.zipped_divide(mC, tiler_mn)

        gA_tile = gA[(None, None), (cta_m, None, cta_l)]
        gB_tile = gB[(None, None), (cta_n, None, cta_l)]
        gSFA_tile = gSFA[(None, None), (cta_m, None, cta_l)]
        gSFB_tile = gSFB[(None, None), (cta_n, None, cta_l)]
        gC_tile = gC[(None, None), (cta_m, cta_n, cta_l)]

        # Shared memory layouts for A/B/SFA/SFB/D
        # (MMA, MMA_M, MMA_K, PIPE)
        a_smem_layout_staged = sm100_utils.make_smem_layout_a(
            tiled_mma,
            mma_tiler_mnk,
            self.ab_dtype,
            self.num_main_stages,
        )

        # (MMA, MMA_N, MMA_K, PIPE)
        b_smem_layout_staged = sm100_utils.make_smem_layout_b(
            tiled_mma,
            mma_tiler_mnk,
            self.ab_dtype,
            self.num_main_stages,
        )

        # (MMA, MMA_M, MMA_K, PIPE)
        sfa_smem_layout_staged = blockscaled_utils.make_smem_layout_sfa(
            tiled_mma,
            mma_tiler_mnk,
            self.sf_vec_size,
            self.num_main_stages,
        )

        # (MMA, MMA_N, MMA_K, PIPE)
        sfb_smem_layout_staged = blockscaled_utils.make_smem_layout_sfb(
            tiled_mma,
            mma_tiler_mnk,
            self.sf_vec_size,
            self.num_main_stages,
        )

        cta_tile_shape_mnk = cute.shape_div(
            mma_tiler_mnk, (cute.size(tiled_mma.thr_id.shape), 1, 1)
        )
        epi_tile = sm100_utils.compute_epilogue_tile_shape(
            cta_tile_shape_mnk,
            self.use_2cta_instrs,
            d_layout,
            c_dtype,
        )
        smem_epi_staged_layout = sm100_utils.make_smem_layout_epi(
            c_dtype,
            d_layout,
            epi_tile,
            self.tma_store_stages,
        )

        # UMMA ACC TMEM Layout
        # ((MMA_M, MMA_N), REST_MMA_M, REST_MMA_N, ACC_STAGES)
        tmem_accs_layout = cute_ext.make_tmem_layout_acc(
            tiled_mma, mma_tiler_mnk, self.num_acc_stages
        )

        sfa_tmem_layout = blockscaled_utils.make_tmem_layout_sfa(
            tiled_mma,
            mma_tiler_mnk,
            self.sf_vec_size,
            cute.slice_(sfa_smem_layout_staged, (None, None, None, 0)),
        )

        sfb_tmem_layout = blockscaled_utils.make_tmem_layout_sfb(
            tiled_mma,
            mma_tiler_mnk,
            self.sf_vec_size,
            cute.slice_(sfb_smem_layout_staged, (None, None, None, 0)),
        )

        # Allocate UMMA Buffers
        buffer_smem_a = cute_ext.allocate(
            self.ab_dtype,
            cute.AddressSpace.smem,
            a_smem_layout_staged,
            alignment=1024,
        )

        buffer_smem_b = cute_ext.allocate(
            self.ab_dtype,
            cute.AddressSpace.smem,
            b_smem_layout_staged,
            alignment=1024,
        )

        buffer_smem_sfa = cute_ext.allocate(
            self.sf_dtype,
            cute.AddressSpace.smem,
            sfa_smem_layout_staged,
            alignment=1024,
        )

        buffer_smem_sfb = cute_ext.allocate(
            self.sf_dtype,
            cute.AddressSpace.smem,
            sfb_smem_layout_staged,
            alignment=1024,
        )

        buffer_tmem_accs = cute_ext.allocate(
            self.acc_dtype,
            cute.AddressSpace.tmem,
            tmem_accs_layout,
            alignment=16,
        )

        buffer_tmem_sfa = cute_ext.allocate(
            self.sf_dtype,
            cute.AddressSpace.tmem,
            sfa_tmem_layout,
            alignment=16,
        )

        buffer_tmem_sfb = cute_ext.allocate(
            self.sf_dtype,
            cute.AddressSpace.tmem,
            sfb_tmem_layout,
            alignment=16,
        )

        buffer_tmem_sfa_compact = cute.filter_zeros(buffer_tmem_sfa)
        buffer_tmem_sfb_compact = cute.filter_zeros(buffer_tmem_sfb)

        # Make S2T CopyAtom and tiledCopy
        copy_atom_s2t = cute.make_copy_atom(
            tcgen05.Cp4x32x128bOp(self.cta_group),
            self.sf_dtype,
        )

        tiled_copy_s2t_sfa = cute.nvgpu.tcgen05.make_s2t_copy(
            copy_atom_s2t, buffer_tmem_sfa_compact
        )
        tiled_copy_s2t_sfb = cute.nvgpu.tcgen05.make_s2t_copy(
            copy_atom_s2t, buffer_tmem_sfb_compact
        )

        # Allocate SMEM buffer for C
        buffer_smem_d = cute_ext.allocate(
            c_dtype,
            cute.AddressSpace.smem,
            smem_epi_staged_layout,
            alignment=1024,
        )

        # Create the TMEM load atom
        copy_atom_t2r = sm100_utils.get_tmem_load_op(
            cta_tile_shape_mnk,
            d_layout,
            c_dtype,
            self.acc_dtype,
            epi_tile,
            self.use_2cta_instrs,
        )

        # Derive tiled_copy_t2r from the allocated TMEM buffer
        accumulators = cute.zipped_divide(buffer_tmem_accs, ((epi_tile), 1))
        acc_epi_div = accumulators[((None, None), 0), 0]
        tiled_copy_t2r = tcgen05.make_tmem_copy(copy_atom_t2r, acc_epi_div)
        thr_copy_t2r = tiled_copy_t2r.get_slice(tidx)

        # Derive per-thread RMEM layout for the T2R epilogue copy
        gC_tile_epi = cute.flat_divide(gC_tile, epi_tile)
        acc_epi_rmem_layout = cute_ext.make_t2r_rmem_layout(
            tiled_copy_t2r, gC_tile_epi, tidx
        )

        # Allocate RMEM buffers
        buffer_rmem_t2r = cute_ext.allocate(
            self.acc_dtype,
            cute.AddressSpace.rmem,
            acc_epi_rmem_layout,
            alignment=32,
        )
        buffer_rmem_r2s = cute_ext.allocate(
            c_dtype,
            cute.AddressSpace.rmem,
            acc_epi_rmem_layout,
            alignment=32,
        )

        # TMA -> UMMA
        mainloop_pipe = cute_ext.TMAToUMMAPipeline.create(
            num_stages=self.num_main_stages,
            mma_operation_type=cute_ext.OperationTypeEnum.SM100_MMA_1SM_SS,
        )

        # UMMA -> TMEM
        acc_pipe = cute_ext.UMMAtoAsyncPipeline.create(
            num_stages=self.num_acc_stages,
            mma_operation_type=cute_ext.OperationTypeEnum.SM100_MMA_1SM_SS,
            consumer=cute_ext.OperationTypeEnum.SM100_COPY_T2R,
            consumer_arv_count=128,
        )

        # warp assignment: [0]-tma_store, [0-3]-epi, [4]-mma, [5]-tma_load
        tma_store_warp_id = 0
        mma_warp_id = 4
        tma_load_warp_id = 5
        is_tma_load_warp = warp_idx == tma_load_warp_id
        is_mma_warp = warp_idx == mma_warp_id
        is_epi_warp = warp_idx < 4

        # SMEM -> GMEM
        tma_store_pipe = cute_ext.TMAStorePipeline(
            stages=self.tma_store_stages,
            arv_count=128,
            barrier_id=1,
            tma_warp_id=tma_store_warp_id,
        )

        k_tile_size = cute.size(gA, mode=[1, 1])

        if is_tma_load_warp:
            for k_tile_idx in cutlass.range(0, k_tile_size, 1, unroll=1):
                gA_k = gA_tile[None, None, k_tile_idx]
                gB_k = gB_tile[None, None, k_tile_idx]
                gSFA_k = gSFA_tile[None, None, k_tile_idx]
                gSFB_k = gSFB_tile[None, None, k_tile_idx]

                # Scoped state management - pipeline object manages state internally
                (
                    producer_stage_token,
                    stage_idx,
                ) = mainloop_pipe.producer_acquire_and_get_stage()
                mbar = cute_ext.get_mbarrier(producer_stage_token)
                ## producer_body begin ##
                buffer_smem_a_sliced = buffer_smem_a[None, None, None, stage_idx]
                buffer_smem_b_sliced = buffer_smem_b[None, None, None, stage_idx]
                buffer_smem_sfa_sliced = buffer_smem_sfa[None, None, None, stage_idx]
                buffer_smem_sfb_sliced = buffer_smem_sfb[None, None, None, stage_idx]

                a_cta_v_map = cute_ext.get_cta_v_map_ab(
                    mA, mma_tiler_mnk, tiled_mma, "A"
                )
                b_cta_v_map = cute_ext.get_cta_v_map_ab(
                    mB, mma_tiler_mnk, tiled_mma, "B"
                )
                sfa_cta_v_map = cute_ext.get_cta_v_map_ab(
                    sfa_tensor, mma_tiler_mnk, tiled_mma, "SFA"
                )
                sfb_cta_v_map = cute_ext.get_cta_v_map_ab(
                    sfb_tensor, mma_tiler_mnk, tiled_mma, "SFB"
                )

                cute_ext.tma_load(
                    gA_k,
                    buffer_smem_a_sliced,
                    mbar,
                    cta_v_map=a_cta_v_map,
                )
                cute_ext.tma_load(
                    gB_k,
                    buffer_smem_b_sliced,
                    mbar,
                    cta_v_map=b_cta_v_map,
                )
                cute_ext.tma_load(
                    gSFA_k,
                    buffer_smem_sfa_sliced,
                    mbar,
                    cta_v_map=sfa_cta_v_map,
                )
                cute_ext.tma_load(
                    gSFB_k,
                    buffer_smem_sfb_sliced,
                    mbar,
                    cta_v_map=sfb_cta_v_map,
                )
                ## producer_body end ##
                mainloop_pipe.producer_commit_and_advance()

        if is_mma_warp:
            producer_stage_token, acc_stage_idx = (
                acc_pipe.producer_acquire_and_get_stage()
            )
            ## acc_producer_body begin ##
            accumulators_sliced = buffer_tmem_accs[None, None, None, acc_stage_idx]

            mma_atom = cute.make_mma_atom(tiled_mma.op)
            mma_atom.set(cute.nvgpu.tcgen05.Field.ACCUMULATE, False)

            filtered_buffer_smem_sfa = cute.filter_zeros(buffer_smem_sfa)
            filtered_buffer_smem_sfb = cute.filter_zeros(buffer_smem_sfb)

            for k_tile_idx in cutlass.range(0, k_tile_size, 1, unroll=1):
                # Scoped state management - pipeline object manages consumer state internally
                (
                    _,
                    mainloop_idx,
                ) = mainloop_pipe.consumer_wait_and_get_stage()
                ## tma_consumer_body begin ##
                buffer_smem_a_sliced_stage = buffer_smem_a[
                    (None, None, None, mainloop_idx)
                ]
                buffer_smem_b_sliced_stage = buffer_smem_b[
                    (None, None, None, mainloop_idx)
                ]
                filtered_buffer_smem_sfa_sliced_stage = filtered_buffer_smem_sfa[
                    (None, None, None, mainloop_idx)
                ]
                filtered_buffer_smem_sfb_sliced_stage = filtered_buffer_smem_sfb[
                    (None, None, None, mainloop_idx)
                ]

                # Copy SFA/SFB from SMEM to TMEM (UTCCP)
                src_partitioned_SFA = cute_ext.partition(
                    filtered_buffer_smem_sfa_sliced_stage,
                    cute.Int32(0),
                    layout_tv=tiled_copy_s2t_sfa.layout_src_tv_tiled,
                    tiler=cute.core._pack_tile(tiled_copy_s2t_sfa.tiler_mn),
                )
                dst_partitioned_SFA = cute_ext.partition(
                    buffer_tmem_sfa_compact,
                    cute.Int32(0),
                    layout_tv=tiled_copy_s2t_sfa.layout_dst_tv_tiled,
                    tiler=cute.core._pack_tile(tiled_copy_s2t_sfa.tiler_mn),
                )

                cute_ext.copy(
                    src_partitioned_SFA, dst_partitioned_SFA, copy_atom=copy_atom_s2t
                )

                src_partitioned_SFB = cute_ext.partition(
                    filtered_buffer_smem_sfb_sliced_stage,
                    cute.Int32(0),
                    layout_tv=tiled_copy_s2t_sfb.layout_src_tv_tiled,
                    tiler=cute.core._pack_tile(tiled_copy_s2t_sfb.tiler_mn),
                )
                dst_partitioned_SFB = cute_ext.partition(
                    buffer_tmem_sfb_compact,
                    cute.Int32(0),
                    layout_tv=tiled_copy_s2t_sfb.layout_dst_tv_tiled,
                    tiler=cute.core._pack_tile(tiled_copy_s2t_sfb.tiler_mn),
                )

                cute_ext.copy(
                    src_partitioned_SFB, dst_partitioned_SFB, copy_atom=copy_atom_s2t
                )

                for k_block_idx in cutlass.range(mma_inst_tile_k, unroll_full=True):
                    buffer_smem_a_sliced = buffer_smem_a_sliced_stage[
                        None, None, k_block_idx
                    ]
                    buffer_smem_b_sliced = buffer_smem_b_sliced_stage[
                        None, None, k_block_idx
                    ]

                    cute_ext.dot_block_scaled(
                        mma_atom,
                        cute.append_ones(buffer_smem_a_sliced, up_to_rank=3),
                        buffer_tmem_sfa[None, None, k_block_idx],
                        cute.append_ones(buffer_smem_b_sliced, up_to_rank=3),
                        buffer_tmem_sfb[None, None, k_block_idx],
                        accumulators_sliced,
                    )
                    mma_atom.set(cute.nvgpu.tcgen05.Field.ACCUMULATE, True)

                ## tma_consumer_body end ##
                mainloop_pipe.consumer_release_and_advance()

            ## acc_producer_body end ##
            acc_pipe.producer_commit_and_advance()

        if is_epi_warp:
            _, acc_stage_idx = acc_pipe.consumer_wait_and_get_stage()
            ## acc_consume_body begin ##
            tmem_acc_stage = buffer_tmem_accs[
                (None, None), 0, 0, acc_stage_idx
            ]  # (MMA_M, MMA_N)
            # (EPI_TILE_M, EPI_TILE_N, EPI_REST_M, EPI_REST_N)
            # we have an implicit assumption that EPI_REST_M == 1
            tmem_acc_epi_stage = cute.flat_divide(tmem_acc_stage, epi_tile)

            subtile_cnt = cute.size(tmem_acc_epi_stage.shape, mode=[3])  # EPI_REST_N
            for subtile_idx in range(subtile_cnt):
                # TMEM -> RMEM
                cute_ext.partition_and_copy(
                    thr_copy_t2r,
                    tmem_acc_epi_stage[(None, None, 0, subtile_idx)],
                    buffer_rmem_t2r,
                )

                # RMEM -> RMEM
                buffer_rmem_r2s.store(
                    self.epilogue_op(buffer_rmem_t2r.load().to(c_dtype))
                )

                # Acquire pipeline stage and synchronize before RMEM->SMEM copy
                tma_store_pipe.acquire_sync()
                tma_store_idx = tma_store_pipe.get_index()

                # RMEM -> SMEM
                tiled_copy_r2s = cute.make_tiled_copy_D(
                    cute.make_copy_atom(cute.nvgpu.CopyUniversalOp(), c_dtype),
                    tiled_copy_t2r,
                )
                cute_ext.partition_and_copy(
                    tiled_copy_r2s.get_slice(tidx),
                    buffer_rmem_r2s,
                    buffer_smem_d[None, None, tma_store_idx],
                )

                # Fence SMEM writes and synchronize before TMA store
                tma_store_pipe.commit_sync()

                # SMEM -> GMEM (only designated TMA store warp performs TMA store)
                if warp_idx == tma_store_warp_id:
                    c_cta_v_map = cute_ext.get_cta_v_map_c(mC, epi_tile)
                    cute_ext.tma_store(
                        buffer_smem_d[None, None, tma_store_idx],
                        gC_tile_epi[(None, None, 0, subtile_idx)],
                        cta_v_map=c_cta_v_map,
                    )

                # Release pipeline stage and advance
                tma_store_pipe.release_advance()

            tma_store_pipe.tail()
            acc_pipe.consumer_release_and_advance()


@cute.experimental.jit
def cvt_sf_MKL_to_M32x4xrm_K4xrk_L(
    sf_ref_tensor: cute.Tensor,
    sf_mma_tensor: cute.Tensor,
):
    """
    Convert scale factor tensor from MKL layout to mma specification
    M(32x4xrest_m)xK(4xrest_k)xL layout
    """
    # sf_mma_tensor has flatten shape (32, 4, rest_m, 4, rest_k, l)
    # group to ((32, 4, rest_m), (4, rest_k), l)
    sf_mma_tensor = cute.group_modes(sf_mma_tensor, 0, 3)
    sf_mma_tensor = cute.group_modes(sf_mma_tensor, 1, 3)
    for i in cutlass.range(cute.size(sf_ref_tensor)):
        mkl_coord = sf_ref_tensor.layout.get_hier_coord(i)
        sf_mma_tensor[mkl_coord] = sf_ref_tensor[mkl_coord]


# TODO: add residual support (C)
@dataclass
class BlockScaledGemmTestbed:
    """
    Testbed for block-scaled GEMM operations on Blackwell (SM100) architecture.

    This class manages test data and tensors for block-scaled matrix multiplication:
        D = (A * scale_factor_A) @ (B * scale_factor_B)

    The testbed maintains three representations of each tensor:
    1. Reference tensors (f32 on CPU) - used for reference computation and validation
    2. CUTE tensors - device tensors passed directly to CUDA kernels
    3. PyTorch tensors - mirrors of CUTE tensors for host-side operations

    Attributes:
        a_ref, b_ref: Reference input matrices (f32 format)
        sfa_ref, sfb_ref: Reference scale factors for A and B matrices (f32 format)
        d_ref: Reference output matrice (f32 format)

        a_tensor, b_tensor: CUTE tensors for input matrices (device)
        sfa_tensor, sfb_tensor: CUTE tensors for scale factors (device)
        d_tensor: CUTE tensors for output (device)

        a_torch, b_torch: PyTorch mirrors of A and B CUTE tensors
        sfa_torch, sfb_torch: PyTorch mirrors of scale factor CUTE tensors
        d_torch: PyTorch mirrors of D CUTE tensors

    The class provides:
    - Automatic tensor creation with proper layouts and alignment
    - Scale factor tensor generation with block-scaled MMA layout
    - Reference checking via einsum-based computation

    Example:
        testbed = BlockScaledGemmTestbed(
            MNKL=(128, 128, 64, 1),
            mma_dtypes=(cutlass.Float16, cutlass.Float16, cutlass.Float32),
            c_dtypes=(cutlass.Float16),
            sf_dtype=cutlass.Float16,
            sf_vec_size=32,
            a_major='m', b_major='n', d_major='m'
        )
        # ... run kernel with testbed.a_tensor, testbed.b_tensor, etc.
        testbed.reference_check()  # Validate results
    """

    import torch

    # Reference tensors (all are in f32 format for simplicity of
    # reference checks)
    a_ref: torch.Tensor
    b_ref: torch.Tensor
    sfa_ref: torch.Tensor
    sfb_ref: torch.Tensor

    # CUTE tensors (to be passed to the device kernel)
    a_tensor: cute.Tensor
    b_tensor: cute.Tensor
    sfa_tensor: cute.Tensor
    sfb_tensor: cute.Tensor
    d_tensor: cute.Tensor

    # PyTorch tensors (mirrors the CUTE tensors above); these tensors
    # can be used on the host, for example if certain trivial epilogue
    # needs to be performed.
    a_torch: torch.Tensor
    b_torch: torch.Tensor
    sfa_torch: torch.Tensor
    sfb_torch: torch.Tensor
    d_torch: torch.Tensor

    def __init__(
        self,
        MNKL: Tuple[int, int, int, int],
        mma_dtypes: tuple[
            Type[cutlass.Numeric], Type[cutlass.Numeric], Type[cutlass.Numeric]
        ],
        c_dtype: Type[cutlass.Numeric],
        sf_dtype: Type[cutlass.Numeric],
        sf_vec_size: int,
        a_major: str,
        b_major: str,
        d_major: str,
    ):
        import cutlass.torch as cutlass_torch

        self.d_major = d_major

        # Problem size
        (M, N, K, L) = MNKL

        a_dtype, b_dtype, _ = mma_dtypes

        assert a_major in ("m", "k"), f"a_major must be 'm' or 'k', got {a_major}"
        assert b_major in ("n", "k"), f"b_major must be 'n' or 'k', got {b_major}"
        assert d_major in ("m", "n"), f"d_major must be 'm' or 'n', got {d_major}"

        self.a_ref = cutlass_torch.matrix(L, M, K, a_major == "m", cutlass.Float32)
        self.b_ref = cutlass_torch.matrix(L, N, K, b_major == "n", cutlass.Float32)
        self.d_temp = cutlass_torch.matrix(L, M, N, d_major == "m", cutlass.Float32)

        self.a_tensor, self.a_torch = cutlass_torch.cute_tensor_like(
            self.a_ref, a_dtype, is_dynamic_layout=True, assumed_align=16
        )
        self.b_tensor, self.b_torch = cutlass_torch.cute_tensor_like(
            self.b_ref, b_dtype, is_dynamic_layout=True, assumed_align=16
        )
        self.d_tensor, self.d_torch = cutlass_torch.cute_tensor_like(
            self.d_temp, c_dtype, is_dynamic_layout=True, assumed_align=16
        )

        # Mark tensor with element divisibility for 16B alignment
        self.a_tensor.mark_compact_shape_dynamic(
            mode=1 if a_major == "k" else 0,
            stride_order=(2, 0, 1) if a_major == "k" else (2, 1, 0),
            divisibility=32 if a_dtype == cutlass.Float4E2M1FN else 16,
        )
        self.b_tensor.mark_compact_shape_dynamic(
            mode=1 if b_major == "k" else 0,
            stride_order=(2, 0, 1) if b_major == "k" else (2, 1, 0),
            divisibility=32 if b_dtype == cutlass.Float4E2M1FN else 16,
        )
        self.d_tensor.mark_compact_shape_dynamic(
            mode=1 if d_major == "k" else 0,
            stride_order=(2, 0, 1) if d_major == "n" else (2, 1, 0),
            divisibility=32 if c_dtype == cutlass.Float4E2M1FN else 16,
        )

        self.sfa_ref, self.sfa_tensor, self.sfa_torch = self.create_scale_factor_tensor(
            L, M, K, sf_vec_size, sf_dtype
        )
        self.sfb_ref, self.sfb_tensor, self.sfb_torch = self.create_scale_factor_tensor(
            L, N, K, sf_vec_size, sf_dtype
        )

    # Create scale factor tensor
    @staticmethod
    def create_scale_factor_tensor(l, mn, k, sf_vec_size, dtype):
        import torch
        import cutlass.torch as cutlass_torch

        def ceil_div(a, b):
            return (a + b - 1) // b

        sf_k = ceil_div(k, sf_vec_size)
        ref_shape = (l, mn, sf_k)
        ref_permute_order = (1, 2, 0)  # MKL

        atom_m = (32, 4)
        atom_k = 4
        mma_shape = (
            l,
            ceil_div(mn, atom_m[0] * atom_m[1]),
            ceil_div(sf_k, atom_k),
            atom_m[0],
            atom_m[1],
            atom_k,
        )
        mma_permute_order = (3, 4, 1, 5, 2, 0)  # M(32x4xrest_m)xK(4xrest_k)xL

        # Create f32 ref torch tensor (cpu)
        ref_f32_torch_tensor_cpu = cutlass_torch.create_and_permute_torch_tensor(
            ref_shape,
            torch.float32,
            permute_order=ref_permute_order,
            init_type=cutlass_torch.TensorInitType.RANDOM,
            init_config=cutlass_torch.RandomInitConfig(
                min_val=1,
                max_val=3,
            ),
        )

        # Create f32 cute torch tensor (cpu)
        cute_f32_torch_tensor_cpu = cutlass_torch.create_and_permute_torch_tensor(
            mma_shape,
            torch.float32,
            permute_order=mma_permute_order,
            init_type=cutlass_torch.TensorInitType.RANDOM,
            init_config=cutlass_torch.RandomInitConfig(
                min_val=0,
                max_val=1,
            ),
        )

        # convert ref f32 tensor to cute f32 tensor
        cvt_sf_MKL_to_M32x4xrm_K4xrk_L(
            from_dlpack(ref_f32_torch_tensor_cpu),
            from_dlpack(cute_f32_torch_tensor_cpu),
        )
        cute_f32_torch_tensor = cute_f32_torch_tensor_cpu.cuda()

        # reshape makes memory contiguous
        ref_f32_torch_tensor_cpu = (
            ref_f32_torch_tensor_cpu.permute(2, 0, 1)
            .unsqueeze(-1)
            .expand(l, mn, sf_k, sf_vec_size)
            .reshape(l, mn, sf_k * sf_vec_size)
            .permute(*ref_permute_order)
        )
        # prune to mkl for reference check.
        ref_f32_torch_tensor_cpu = ref_f32_torch_tensor_cpu[:, :k, :]

        # Create dtype cute torch tensor (cpu)
        cute_tensor, cute_torch_tensor = cutlass_torch.cute_tensor_like(
            cute_f32_torch_tensor_cpu,
            dtype,
            is_dynamic_layout=True,
            assumed_align=16,
        )

        # Convert f32 cute tensor to dtype cute tensor
        cute_tensor = cutlass_torch.convert_cute_tensor(
            cute_f32_torch_tensor,
            cute_tensor,
            dtype,
            is_dynamic_layout=True,
        )
        return ref_f32_torch_tensor_cpu, cute_tensor, cute_torch_tensor

    # Transfers results back to CPU and uses PyTorch's methods to do
    # reference checks
    def reference_check(self):
        import torch

        # Compute reference result, simulate block-scaled GEMV via 2 FFMA
        # based elementwise multiplication and 1 FFMA based matmul computations
        res_a = torch.einsum("mkl,mkl->mkl", self.a_ref, self.sfa_ref)
        res_b = torch.einsum("nkl,nkl->nkl", self.b_ref, self.sfb_ref)
        ref_output = torch.einsum("mkl,nkl->mnl", res_a, res_b)

        # Convert d back to f32 for comparison.
        d_epi_device = self.d_temp.cuda()
        cute.testing.convert(
            self.d_tensor,
            from_dlpack(d_epi_device, assumed_align=16).mark_layout_dynamic(
                leading_dim=(1 if self.d_major == "n" else 0)
            ),
        )

        # abs(actual - expected) <= atol + rtol * abs(expected)
        torch.testing.assert_close(
            d_epi_device.cpu(), ref_output, atol=1e-01, rtol=1e-02
        )
        print("Reference check finished.")


def run(
    mnkl: Tuple[int, int, int, int],
    mma_inst_mn: Tuple[int, int],
    cluster_shape_mn: Tuple[int, int],
    ab_dtype: Type[cutlass.Numeric],
    sf_dtype: Type[cutlass.Numeric],
    sf_vec_size: int,
    d_dtype: Type[cutlass.Numeric],
    acc_dtype: Type[cutlass.Numeric],
    a_major: str,
    b_major: str,
    d_major: str,
):
    """Execute a batched block scaled dense GEMM operation on Blackwell architecture.

    This function prepares input tensors, configures and launches the GEMM kernel,
    and performs reference validation.

    :param mnkl: Problem size (M, N, K, L)
    :type mnkl: Tuple[int, int, int, int]
    :param mma_inst_mn: MMA instruction shape.
    :type mma_inst_mn: Tuple[int, int]
    :param cluster_shape_mn: Cluster shape.
    :type cluster_shape_mn: Tuple[int, int]
    :param ab_dtype: Data type for input tensors A and B
    :type ab_dtype: Type[Numeric]
    :param sf_dtype: Data type for scale factors (SFA/SFB)
    :type sf_dtype: Type[Numeric]
    :param sf_vec_size: Vector size for the scale factor
    :type sf_vec_size: int
    :param c_dtype: Data type for output tensor D
    :type c_dtype: Type[Numeric]
    :param acc_dtype: Accumulator data type (precision)
    :type acc_dtype: Type[Numeric]
    :param a_major: Major-ness of A tensor (m or k)
    :type a_major: str
    :param b_major: Major-ness of B tensor (n or k)
    :type b_major: str
    :param d_major: Major-ness of D tensor (m or n)
    :type d_major: str
    """
    print("Running Blackwell Dense Block Scaled GEMM test with:")
    print(f"mnkl: {mnkl}")
    print(f"A: {ab_dtype}, B: {ab_dtype}, D: {d_dtype}, Acc dtype: {acc_dtype}")
    print(f"Block scaled MMA with SF: {sf_dtype}, vector size: {sf_vec_size}")
    print(f"Matrix majors - A: {a_major}-major, B: {b_major}-major, D: {d_major}-major")
    print(
        f"Mma Tiler (M, N): {mma_inst_mn}, Cluster Shape: {cluster_shape_mn[0]}x{cluster_shape_mn[1]}x1"
    )
    import torch

    # TODO: add can_implement to exclude unsupported/un-implemented test cases
    if cluster_shape_mn != (1, 1):
        raise RuntimeError("Only 1x1x1 cluster shapes are supported right now.")
    if mma_inst_mn != (128, 128):
        raise RuntimeError("MMA instruction shape not supported yet.")
    if ab_dtype not in (cutlass.Float8E4M3FN, cutlass.Float8E5M2):
        raise RuntimeError("Input data type not supported.")
    if sf_dtype not in (cutlass.Float8E8M0FNU, cutlass.Float8E4M3FN):
        raise RuntimeError("Scale factor data type not supported.")

    if not torch.cuda.is_available():
        raise RuntimeError("A GPU is required to run this example!")

    # Manual seed
    torch.manual_seed(111)

    # Create tensors
    tb = BlockScaledGemmTestbed(
        mnkl,
        (ab_dtype, ab_dtype, acc_dtype),
        d_dtype,
        sf_dtype,
        sf_vec_size,
        a_major,
        b_major,
        d_major,
    )

    # JIT-Compile the device kernel
    block_scaled_gemm = BlockScaledDenseGemmKernel(
        mma_inst_mn=mma_inst_mn,
        mma_dtype=(ab_dtype, acc_dtype),
        sf_dtype=sf_dtype,
        sf_vec_size=sf_vec_size,
    )

    compiled_kernel = cute.experimental.compile(
        block_scaled_gemm,
        tb.a_tensor,
        tb.sfa_tensor,
        tb.b_tensor,
        tb.sfb_tensor,
        tb.d_tensor,
    )

    # Launch the device kernel
    compiled_kernel(
        tb.a_tensor,
        tb.sfa_tensor,
        tb.b_tensor,
        tb.sfb_tensor,
        tb.d_tensor,
    )

    tb.reference_check()


if __name__ == "__main__":

    def parse_comma_separated_ints(s: str) -> Tuple[int, ...]:
        try:
            return tuple(int(x.strip()) for x in s.split(","))
        except ValueError:
            raise argparse.ArgumentTypeError(
                "Invalid format. Expected comma-separated integers."
            )

    parser = argparse.ArgumentParser(
        description="Example of Sm100 Dense BlockScaled GEMM."
    )

    parser.add_argument(
        "--mnkl",
        type=parse_comma_separated_ints,
        default=(512, 256, 256, 1),
        help="mnkl dimensions (comma-separated)",
    )
    parser.add_argument(
        "--mma_inst_mn",
        type=parse_comma_separated_ints,
        default=(128, 128),
        help="Mma instruction shape (comma-separated)",
    )
    parser.add_argument(
        "--cluster_shape_mn",
        type=parse_comma_separated_ints,
        default=(1, 1),
        help="Cluster shape (comma-separated)",
    )
    parser.add_argument("--ab_dtype", type=cutlass.dtype, default=cutlass.Float8E4M3FN)
    parser.add_argument("--sf_dtype", type=cutlass.dtype, default=cutlass.Float8E8M0FNU)
    parser.add_argument("--sf_vec_size", type=int, default=32)
    parser.add_argument("--acc_dtype", type=cutlass.dtype, default=cutlass.Float32)
    parser.add_argument("--d_dtype", type=cutlass.dtype, default=cutlass.Float16)
    parser.add_argument("--a_major", choices=["k", "m"], type=str, default="k")
    parser.add_argument("--b_major", choices=["k", "n"], type=str, default="k")
    parser.add_argument("--d_major", choices=["n", "m"], type=str, default="n")

    args = parser.parse_args()

    if len(args.mnkl) != 4:
        parser.error("--mnkl must contain exactly 4 values")

    if len(args.mma_inst_mn) != 2:
        parser.error("--mma_inst_mn must contain exactly 2 values")

    if len(args.cluster_shape_mn) != 2:
        parser.error("--cluster_shape_mn must contain exactly 2 values")

    run(
        args.mnkl,
        args.mma_inst_mn,
        args.cluster_shape_mn,
        args.ab_dtype,
        args.sf_dtype,
        args.sf_vec_size,
        args.d_dtype,
        args.acc_dtype,
        args.a_major,
        args.b_major,
        args.d_major,
    )
