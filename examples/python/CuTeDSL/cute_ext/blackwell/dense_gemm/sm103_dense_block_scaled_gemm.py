# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
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
from typing import Type, Tuple

import cutlass
import cutlass.cute as cute
from cutlass import testing
from cutlass.cute import experimental as cute_ext
from cutlass.cute.nvgpu import tcgen05
import cutlass.utils.blackwell_helpers as sm103_utils
import cutlass.utils.blockscaled_layout as blockscaled_utils

# run() imports the block-scaled testbed from the sibling sm100 example by its
# package path. Under pytest / the perf harness that root is already on the
# path; when this file is run directly it is not.
if __name__ == "__main__":
    _current_dir = os.path.dirname(os.path.abspath(__file__))
    sys.path.insert(0, os.path.join(_current_dir, "../../../"))

from helpers import cli_helper as cli


"""
This implements FP4 Ultra blockscaled GEMM example for the NVIDIA Blackwell SM103 architecture written in cutlass IR.

List of features which are not yet implemented (future TODOs):
1. MMA_N = 64/192
2. Tile scheduler
"""


class SM103BlockScaledDenseGemmKernel:
    def __init__(
        self,
        mma_inst_mn: Tuple[int, int],
        a_dtype: Type[cutlass.Numeric],
        b_dtype: Type[cutlass.Numeric],
        sf_dtype: Type[cutlass.Numeric],
        sf_vec_size: int,
        cluster_shape_mn: Tuple[int, int],
        epilogue_op=lambda x: x,
    ):
        self.a_dtype = a_dtype
        self.b_dtype = b_dtype
        self.sf_dtype = sf_dtype
        self.acc_dtype = cutlass.Float32

        self.mma_inst_k = 96
        self.mma_per_k_tile = 8
        self.mma_tiler = (*mma_inst_mn, self.mma_per_k_tile * self.mma_inst_k)

        self.cluster_shape_mn = cluster_shape_mn
        self.use_2cta_instrs = mma_inst_mn[0] == 256
        self.cta_group = (
            tcgen05.CtaGroup.TWO if self.use_2cta_instrs else tcgen05.CtaGroup.ONE
        )
        num_mma_ctas = 2 if self.use_2cta_instrs else 1
        cluster_shape_mn_selfcast = (num_mma_ctas, 1)
        self.use_tma_multicast = cluster_shape_mn != cluster_shape_mn_selfcast

        self.cta_tile_shape_mnk = (
            self.mma_tiler[0] // num_mma_ctas,
            self.mma_tiler[1],
            self.mma_tiler[2],
        )

        self.cta_mma_tiler_mk = (self.cta_tile_shape_mnk[0], self.cta_tile_shape_mnk[2])
        self.cta_mma_tiler_nk = (
            self.cta_tile_shape_mnk[1] // num_mma_ctas,
            self.cta_tile_shape_mnk[2],
        )

        # K=128 bytes for TMA load
        self.ab_k_count_per_stage = 256
        self.ab_k_tile_slices = self.cta_tile_shape_mnk[2] // self.ab_k_count_per_stage
        self.ab_tiler_mk = (self.cta_mma_tiler_mk[0], self.ab_k_count_per_stage)
        self.ab_tiler_nk = (self.cta_mma_tiler_nk[0], self.ab_k_count_per_stage)

        self.sfa_tiler_mk = (self.cta_tile_shape_mnk[0], self.cta_tile_shape_mnk[2])
        self.sfb_tiler_nk = (self.cta_tile_shape_mnk[1], self.cta_tile_shape_mnk[2])

        self.sf_vec_size = sf_vec_size
        self.sf_buffers_per_tile_k = 4 if self.sf_vec_size == 16 else 2
        self.mma_per_sf_buffer = 8 // self.sf_buffers_per_tile_k
        self.sf_stride = 6 if self.sf_vec_size == 16 else 3

        self.sfa_tma_tiler_mk = (
            self.sfa_tiler_mk[0],
            self.sfa_tiler_mk[1] // self.sf_buffers_per_tile_k,
        )
        self.sfb_tma_tiler_nk = (
            self.sfb_tiler_nk[0],
            self.sfb_tiler_nk[1] // self.sf_buffers_per_tile_k,
        )

        self.epilogue_op = epilogue_op
        self.smem_capacity = cutlass.memory.get_smem_capacity_in_bytes("sm_103")

        # warp assignment: [0]-tma_store, [0-3]-epi, [4]-mma, [5]-tma_ab, [6]-tma_sf
        self.tma_store_warp_id = 0
        self.mma_warp_id = 4
        self.tma_ab_warp_id = 5
        self.tma_sf_warp_id = 6

    def _setup_attributes(self):
        self.tiled_mma = sm103_utils.sm103_make_blockscaled_trivial_tiled_mma(
            self.sf_dtype,
            self.sf_vec_size,
            self.cta_group,
            self.mma_tiler[0:2],
        )

        self.epi_tile = sm103_utils.compute_epilogue_tile_shape(
            self.cta_tile_shape_mnk,
            self.use_2cta_instrs,
            self.d_layout,
            self.d_dtype,
        )

        self._compute_stages()

    @cute.experimental.jit
    def __call__(
        self,
        mA: cute.Tensor,
        mSFA: cute.Tensor,
        mB: cute.Tensor,
        mSFB: cute.Tensor,
        mD: cute.Tensor,
    ):
        self.d_dtype: Type[cutlass.Numeric] = mD.element_type
        self.d_layout = cutlass.tensor_utils.LayoutEnum.from_tensor(mD)

        self._setup_attributes()

        grid = cute.round_up(
            (
                cute.ceil_div(mD.layout.shape[0], self.cta_tile_shape_mnk[0]),
                cute.ceil_div(mD.layout.shape[1], self.cta_tile_shape_mnk[1]),
                mD.layout.shape[2],
            ),
            self.cluster_shape_mn,
        )

        self.kernel(self.tiled_mma, mA, mSFA, mB, mSFB, mD, self.epi_tile).launch(
            grid=grid,
            block=(224, 1, 1),
            cluster=(*self.cluster_shape_mn, 1),
            smem=self.smem_capacity,
        )

    # GPU device kernel
    @cute.experimental.kernel
    def kernel(
        self,
        tiled_mma: cute.TiledMma,
        mA: cute.Tensor,
        mSFA: cute.Tensor,
        mB: cute.Tensor,
        mSFB: cute.Tensor,
        mD: cute.Tensor,
        epi_tile: cute.Tile,
    ):
        # ========================================================================
        # Cluster and thread setup
        # ========================================================================
        cluster_layout_vmnk = cute.tiled_divide(
            cute.make_layout((*self.cluster_shape_mn, 1)),
            (tiled_mma.thr_id.shape,),
        )
        cluster_layout_sfb_vmnk = cute.tiled_divide(
            cute.make_layout((*self.cluster_shape_mn, 1)),
            (1,),
        )

        warp_idx = cute.arch.warp_idx()
        warp_idx = cute.arch.make_warp_uniform(warp_idx)
        cta_m, cta_n, cta_l = cute.arch.block_idx()
        mma_tile_coord_v = cta_m % cute.size(tiled_mma.thr_id.shape)
        is_leader_cta = mma_tile_coord_v == 0

        # ========================================================================
        # Global tensor setup and tiling
        # ========================================================================
        # Setup scale factor tensors
        sfa_layout = blockscaled_utils.tile_atom_to_shape_SF(mA.shape, self.sf_vec_size)
        sfa_tensor = cute.make_tensor(mSFA.iterator, sfa_layout)
        sfb_layout = blockscaled_utils.tile_atom_to_shape_SF(mB.shape, self.sf_vec_size)
        sfb_tensor = cute.make_tensor(mSFB.iterator, sfb_layout)

        # Divide global tensors into tiles
        gA = cute.zipped_divide(mA, self.cta_mma_tiler_mk)
        gB = cute.zipped_divide(mB, self.cta_mma_tiler_nk)
        gSFA = cute.zipped_divide(sfa_tensor, self.sfa_tiler_mk)
        gSFB = cute.zipped_divide(sfb_tensor, self.sfb_tiler_nk)

        # N coordinate for 2xSM TMA
        if cutlass.const_expr(self.use_2cta_instrs):
            gB_tma_coord_n = cute.size(
                tiled_mma.thr_id.shape
            ) * cta_n + cta_m % cute.size(tiled_mma.thr_id.shape)
        else:
            gB_tma_coord_n = cta_n

        # Extract tiles for this CTA
        gA_tile = gA[(None, None), (cta_m, None, cta_l)]
        gB_tile = gB[(None, None), (gB_tma_coord_n, None, cta_l)]
        gSFA_tile = gSFA[(None, None), (cta_m, None, cta_l)]
        gSFB_tile = gSFB[(None, None), (cta_n, None, cta_l)]
        k_tile_cnt = cute.size(gA, mode=[1, 1])

        # ========================================================================
        # Shared memory layouts
        # ========================================================================
        a_smem_layout_staged = self.make_smem_layout_ab(
            self.a_dtype,
            self.ab_tiler_mk,
            self.mainloop_stage,
        )
        b_smem_layout_staged = self.make_smem_layout_ab(
            self.b_dtype,
            self.ab_tiler_nk,
            self.mainloop_stage,
        )
        sfa_smem_layout_staged = blockscaled_utils.sm103_make_smem_layout_sfa(
            tiled_mma,
            self.mma_tiler,
            self.sf_vec_size,
            self.sf_stage,
        )
        sfb_smem_layout_staged = blockscaled_utils.sm103_make_smem_layout_sfb(
            tiled_mma,
            self.mma_tiler,
            self.sf_vec_size,
            self.sf_stage,
        )

        # ========================================================================
        # Shared memory allocation for operands A, B, SFA, SFB
        # ========================================================================
        sA_tma = cute_ext.allocate(
            self.a_dtype,
            cutlass.AddressSpace.smem,
            a_smem_layout_staged,
            1024,
        )
        sA = cute.make_tensor(
            sA_tma.iterator,
            self.adapt_layout_for_mma_ab(
                a_smem_layout_staged,
                self.cta_mma_tiler_mk[0],
                self.mma_inst_k,
            ),
        )

        sB_tma = cute_ext.allocate(
            self.b_dtype,
            cutlass.AddressSpace.smem,
            b_smem_layout_staged,
            1024,
        )
        sB = cute.make_tensor(
            sB_tma.iterator,
            self.adapt_layout_for_mma_ab(
                b_smem_layout_staged,
                self.cta_mma_tiler_nk[0],
                self.mma_inst_k,
            ),
        )

        sSFA = cute_ext.allocate(
            self.sf_dtype,
            cutlass.AddressSpace.smem,
            sfa_smem_layout_staged,
            1024,
        )
        sSFB = cute_ext.allocate(
            self.sf_dtype,
            cutlass.AddressSpace.smem,
            sfb_smem_layout_staged,
            1024,
        )
        sSFA_filtered = cute.filter_zeros(sSFA)
        sSFB_filtered = cute.filter_zeros(sSFB)

        # ========================================================================
        # Tensor memory (TMEM) allocation for accumulator and scale factors
        # ========================================================================
        tmem_acc_layout = cute_ext.make_tmem_layout_acc(
            tiled_mma, self.mma_tiler, self.acc_stage
        )
        buffer_acc = cute_ext.allocate(
            self.acc_dtype,
            cutlass.AddressSpace.tmem,
            tmem_acc_layout,
            alignment=16,
            is2cta=self.use_2cta_instrs,
        )

        sfa_tmem_layout = blockscaled_utils.make_tmem_layout_sfa(
            tiled_mma,
            self.mma_tiler,
            self.sf_vec_size,
            cute.slice_(sfa_smem_layout_staged, (None, None, None, 0)),
        )
        buffer_tmem_sfa = cute_ext.allocate(
            self.sf_dtype,
            cutlass.AddressSpace.tmem,
            sfa_tmem_layout,
            alignment=16,
            is2cta=self.use_2cta_instrs,
        )

        sfb_tmem_layout = blockscaled_utils.make_tmem_layout_sfb(
            tiled_mma,
            self.mma_tiler,
            self.sf_vec_size,
            cute.slice_(sfb_smem_layout_staged, (None, None, None, 0)),
        )
        buffer_tmem_sfb = cute_ext.allocate(
            self.sf_dtype,
            cutlass.AddressSpace.tmem,
            sfb_tmem_layout,
            alignment=16,
            is2cta=self.use_2cta_instrs,
        )
        buffer_tmem_sfa_compact = cute.filter_zeros(buffer_tmem_sfa)
        buffer_tmem_sfb_compact = cute.filter_zeros(buffer_tmem_sfb)

        # ========================================================================
        # Scale factor copy operations (SMEM to TMEM)
        # ========================================================================
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

        # ========================================================================
        # Scale factor iteration layouts for MMA operations
        # ========================================================================
        mnBasicBlockShape = (32, 4)
        mma_iter_SFA_shape = (
            (mnBasicBlockShape, self.cta_tile_shape_mnk[0] // 128),
            (self.sf_vec_size, 1),
        )
        k_tile_sf_count = (
            self.cta_tile_shape_mnk[2] * self.sf_dtype.width // 8 // self.sf_vec_size
        )
        sSFA_iter_shape = (mma_iter_SFA_shape, 1, k_tile_sf_count)
        sSFA_iter_layout = cute.make_layout(sSFA_iter_shape)

        mma_iter_SFB_shape = (
            (mnBasicBlockShape, self.cta_tile_shape_mnk[1] // 128),
            (self.sf_vec_size, 1),
        )
        sSFB_iter_shape = (mma_iter_SFB_shape, 1, k_tile_sf_count)
        sSFB_iter_layout = cute.make_layout(sSFB_iter_shape)

        tCtSFA_layout_mma = blockscaled_utils.make_tmem_layout_sfa(
            tiled_mma, self.mma_tiler, self.sf_vec_size, sSFA_iter_layout
        )
        tCtSFA_mma = cute.make_tensor(buffer_tmem_sfa.iterator, tCtSFA_layout_mma)

        tCtSFB_layout_mma = blockscaled_utils.make_tmem_layout_sfb(
            tiled_mma, self.mma_tiler, self.sf_vec_size, sSFB_iter_layout
        )
        tCtSFB_mma = cute.make_tensor(buffer_tmem_sfb.iterator, tCtSFB_layout_mma)

        # ========================================================================
        # Pipeline configuration
        # ========================================================================
        # TMA multicast projection modes: A along M dimension (proj=2), B along N dimension (proj=1)
        tma_mcast_proj_A = 2
        tma_mcast_proj_B = 1

        # Determine operation types based on 2-CTA mode and TMA multicast
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

        count_per_stage = 128  # K=128 bytes per A/B TMA load
        count_per_iteration = 48  # K=48 bytes per MMA

        # TMA -> UMMA pipeline (A/B and scale factors)
        mainloop_pipe = cute_ext.TMAToUMMACircularPipeline.create(
            num_stages=self.mainloop_stage,
            tma_operation_type=tma_operation_type,
            mma_operation_type=mma_operation_type,
            cluster_layout_vmnk=cluster_layout_vmnk,
            count_per_stage=count_per_stage,
            count_per_iteration=count_per_iteration,
        )

        sf_pipe = cute_ext.TMAToUMMAPipeline.create(
            num_stages=self.sf_stage,
            mma_operation_type=mma_operation_type,
            tma_operation_type=tma_operation_type,
            cluster_layout_vmnk=cluster_layout_vmnk,
        )

        # UMMA -> Load to tensor memory pipeline (accumulator to register memory)
        # For 2-CTA MMA, warpgroup from both peer and leader CTA consumer.release
        acc_pipe_consumer_arv_count = 256 if self.use_2cta_instrs else 128
        acc_pipe = cute_ext.UMMAtoAsyncPipeline.create(
            num_stages=self.acc_stage,
            mma_operation_type=mma_operation_type,
            consumer=cute_ext.OperationTypeEnum.SM100_COPY_T2R,
            consumer_arv_count=acc_pipe_consumer_arv_count,
            cluster_layout_vmnk=cluster_layout_vmnk,
        )

        # store to smem -> TMA store to global pipeline (store to global memory)
        tma_store_pipe = cute_ext.TMAStorePipeline(
            stages=self.tma_store_stage,
            arv_count=128,
            barrier_id=1,
            tma_warp_id=self.tma_store_warp_id,
        )

        if warp_idx == self.tma_ab_warp_id:
            for k_tile in cutlass.range(0, k_tile_cnt, 1, unroll=1):
                gA_k = cute.zipped_divide(gA_tile[None, None, k_tile], self.ab_tiler_mk)
                gB_k = cute.zipped_divide(gB_tile[None, None, k_tile], self.ab_tiler_nk)

                for k_slice_idx in cutlass.range(
                    self.ab_k_tile_slices, unroll_full=True
                ):
                    (
                        ab_producer_stage_token,
                        ab_producer_stage_idx,
                    ) = mainloop_pipe.producer_acquire_and_get_stage()
                    ab_full_mbar = cute_ext.get_mbarrier(ab_producer_stage_token)

                    cute_ext.tma_load(
                        gA_k[(None, None), k_slice_idx],
                        sA_tma[None, None, ab_producer_stage_idx],
                        ab_full_mbar,
                        vmnk_layout=cluster_layout_vmnk,
                        tma_operation_type=tma_operation_type,
                        multicast_mode=tma_mcast_proj_A,
                    )
                    cute_ext.tma_load(
                        gB_k[(None, None), k_slice_idx],
                        sB_tma[None, None, ab_producer_stage_idx],
                        ab_full_mbar,
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

        if warp_idx == self.tma_sf_warp_id:
            for k_tile in cutlass.range(0, k_tile_cnt, 1, unroll=1):
                gSFA_k = cute.zipped_divide(
                    gSFA_tile[None, None, k_tile],
                    self.sfa_tma_tiler_mk,
                )
                gSFB_k = cute.zipped_divide(
                    gSFB_tile[None, None, k_tile],
                    self.sfb_tma_tiler_nk,
                )

                for sf_slice_idx in cutlass.range(
                    self.sf_buffers_per_tile_k, unroll_full=True
                ):
                    sf_producer_stage_token, sf_producer_stage_idx = (
                        sf_pipe.producer_acquire_and_get_stage()
                    )
                    sf_full_mbar = cute_ext.get_mbarrier(sf_producer_stage_token)

                    sSFA_slice = sSFA[None, None, None, sf_producer_stage_idx]
                    sSFB_slice = sSFB[None, None, None, sf_producer_stage_idx]

                    cute_ext.tma_load(
                        gSFA_k[(None, None), sf_slice_idx],
                        self.adapt_layout_for_tma_sf(sSFA_slice),
                        sf_full_mbar,
                        vmnk_layout=cluster_layout_vmnk,
                        tma_operation_type=tma_operation_type,
                        multicast_mode=tma_mcast_proj_A,
                    )
                    cute_ext.tma_load(
                        gSFB_k[(None, None), sf_slice_idx],
                        self.adapt_layout_for_tma_sf(sSFB_slice),
                        sf_full_mbar,
                        vmnk_layout=cluster_layout_sfb_vmnk,
                        tma_operation_type=tma_operation_type,
                        multicast_mode=tma_mcast_proj_B,
                    )

                    # For 2-CTA mode, only leader CTA commits
                    if cutlass.const_expr(self.use_2cta_instrs):
                        if is_leader_cta:
                            sf_pipe.producer_commit()
                        sf_pipe.producer_state = cute_ext.pipeline_advance_iterator(
                            sf_pipe.raw_pipeline,
                            sf_pipe.producer_state,
                        )
                    else:
                        sf_pipe.producer_commit_and_advance()

        if warp_idx == self.mma_warp_id and is_leader_cta:
            _, acc_stage_idx = acc_pipe.producer_acquire_and_get_stage()

            accumulators_sliced = cute.append_ones(
                buffer_acc[(None, None, None, acc_stage_idx)],
                up_to_rank=3,
            )

            mma_atom = cute.make_mma_atom(tiled_mma.op)
            mma_atom.set(cute.nvgpu.tcgen05.Field.ACCUMULATE, False)

            k_slice_idx = 0
            for k_tile in cutlass.range(0, k_tile_cnt, 1, unroll=1):
                for k_iter in cutlass.range(0, self.mma_per_k_tile, 1, unroll=1):
                    # Conditionally load SFA/SFB depending on sf_vec_size
                    if k_iter % self.mma_per_sf_buffer == 0:
                        _, sf_consumer_stage_idx = sf_pipe.consumer_wait_and_get_stage()

                        sSFA_partitioned = cute_ext.partition(
                            sSFA_filtered[None, None, None, sf_consumer_stage_idx],
                            cute.Int32(0),
                            layout_tv=tiled_copy_s2t_sfa.layout_src_tv_tiled,
                            tiler=cute.core._pack_tile(tiled_copy_s2t_sfa.tiler_mn),
                        )

                        tSFA_partitioned = cute_ext.partition(
                            buffer_tmem_sfa_compact,
                            cute.Int32(0),
                            layout_tv=tiled_copy_s2t_sfa.layout_dst_tv_tiled,
                            tiler=cute.core._pack_tile(tiled_copy_s2t_sfa.tiler_mn),
                        )

                        cute_ext.copy(
                            sSFA_partitioned, tSFA_partitioned, copy_atom=copy_atom_s2t
                        )

                        sSFB_partitioned = cute_ext.partition(
                            sSFB_filtered[None, None, None, sf_consumer_stage_idx],
                            cute.Int32(0),
                            layout_tv=tiled_copy_s2t_sfb.layout_src_tv_tiled,
                            tiler=cute.core._pack_tile(tiled_copy_s2t_sfb.tiler_mn),
                        )

                        tSFB_partitioned = cute_ext.partition(
                            buffer_tmem_sfb_compact,
                            cute.Int32(0),
                            layout_tv=tiled_copy_s2t_sfb.layout_dst_tv_tiled,
                            tiler=cute.core._pack_tile(tiled_copy_s2t_sfb.tiler_mn),
                        )

                        cute_ext.copy(
                            sSFB_partitioned, tSFB_partitioned, copy_atom=copy_atom_s2t
                        )

                        sf_pipe.consumer_release_and_advance()

                    mainloop_pipe.consumer_wait()

                    sf_kblock_coord = (
                        None,
                        0,
                        k_iter % self.mma_per_sf_buffer * self.sf_stride,
                    )

                    cute_ext.dot_block_scaled(
                        mma_atom,
                        sA[None, k_slice_idx],
                        tCtSFA_mma[sf_kblock_coord],
                        sB[None, k_slice_idx],
                        tCtSFB_mma[sf_kblock_coord],
                        accumulators_sliced,
                    )

                    mma_atom.set(cute.nvgpu.tcgen05.Field.ACCUMULATE, True)
                    k_slice_idx += 1

                    mainloop_pipe.consumer_release_and_advance()

            acc_pipe.producer_commit_and_advance()

        if warp_idx < self.mma_warp_id:
            _, acc_stage_idx = acc_pipe.consumer_wait_and_get_stage()
            accumulators_sliced = buffer_acc[(None, None), 0, 0, acc_stage_idx]
            cta_d_tile_coord = (cta_m, cta_n, cta_l)

            tma_store_pipe = cute_ext.epilogue_tma_store(
                self.cta_tile_shape_mnk,
                self.use_2cta_instrs,
                accumulators_sliced,
                mD,
                cta_d_tile_coord,
                tma_store_pipe,
                self.tma_store_warp_id,
                self.epilogue_op,
            )

            acc_pipe.consumer_release_and_advance()

        if cute.size(self.cluster_shape_mn) > 1:
            cute.arch.cluster_arrive()
            cute.arch.cluster_wait()

    def _compute_stages(self):
        self.tma_store_stage = 2

        # Calculate smem layout and size for one stage of A, B, SFA, SFB
        a_smem_layout_stage_one = SM103BlockScaledDenseGemmKernel.make_smem_layout_ab(
            self.a_dtype,
            self.ab_tiler_mk,
            1,
        )
        b_smem_layout_staged_one = SM103BlockScaledDenseGemmKernel.make_smem_layout_ab(
            self.b_dtype,
            self.ab_tiler_nk,
            1,
        )
        sfa_smem_layout_staged_one = blockscaled_utils.sm103_make_smem_layout_sfa(
            self.tiled_mma,
            self.mma_tiler,
            self.sf_vec_size,
            1,
        )
        sfb_smem_layout_staged_one = blockscaled_utils.sm103_make_smem_layout_sfb(
            self.tiled_mma,
            self.mma_tiler,
            self.sf_vec_size,
            1,
        )
        d_smem_layout_staged_one = sm103_utils.make_smem_layout_epi(
            self.d_dtype,
            self.d_layout,
            self.epi_tile,
            1,
        )

        d_bytes_per_stage = cute.size_in_bytes(self.d_dtype, d_smem_layout_staged_one)
        d_bytes = d_bytes_per_stage * self.tma_store_stage

        ab_bytes_per_stage = cute.size_in_bytes(
            self.a_dtype, a_smem_layout_stage_one
        ) + cute.size_in_bytes(self.b_dtype, b_smem_layout_staged_one)
        sf_bytes_per_stage = cute.size_in_bytes(
            self.sf_dtype, sfa_smem_layout_staged_one
        ) + cute.size_in_bytes(self.sf_dtype, sfb_smem_layout_staged_one)

        reserved_bytes = 1024

        self.mainloop_stage = (
            self.smem_capacity - (reserved_bytes + sf_bytes_per_stage + d_bytes)
        ) // ab_bytes_per_stage

        self.sf_stage = (
            self.smem_capacity
            - ab_bytes_per_stage * self.mainloop_stage
            - reserved_bytes
            - d_bytes
        ) // (sf_bytes_per_stage)

        # Add remaining unused smem to epilogue
        self.tma_store_stage += (
            self.smem_capacity
            - ab_bytes_per_stage * self.mainloop_stage
            - sf_bytes_per_stage * self.sf_stage
            - reserved_bytes
            - d_bytes
        ) // (d_bytes_per_stage)

        self.acc_stage = 1 if self.mma_tiler[1] == 256 else 2

    @staticmethod
    def make_smem_layout_ab(
        dtype: Type[cutlass.Numeric],
        tma_tiler: cute.Tile,
        num_stages: int,
    ) -> cute.ComposedLayout:
        atom = tcgen05.make_smem_layout_atom(tcgen05.SmemLayoutAtomKind.K_SW128, dtype)
        layout = tcgen05.tile_to_mma_shape(atom, (tma_tiler, 1, 1, num_stages))
        return cute.make_composed_layout(atom.inner, 0, cute.filter(layout.outer))

    @staticmethod
    def adapt_layout_for_mma_ab(
        smem_layout: cute.ComposedLayout,
        mma_mn: int,
        mma_k: int,
    ) -> cute.ComposedLayout:
        """
        Creates a composed layout for MMA operands A/B to enable circular buffer access.

        The input `smem_layout` has layout (TILE_MN, TILE_K, STAGES).

        The resulting composed layout has:
        - Inner layout: ((TILE_MN, TILE_K), 1, 1, STAGES) - represents the circular buffer.
        - Outer layout: ((MMA_MN, MMA_K), REST_K) - represents the tiled logical MMA operands.
        """
        smem_layout_outer = cute.group_modes(smem_layout.outer, 0, 2)
        inner = cute.select(smem_layout_outer, mode=[0])
        inner = cute.append_ones(inner, up_to_rank=3)
        inner = cute.append(inner, cute.select(smem_layout_outer, mode=[1]))
        rest_k = cute.ceil_div(cute.size(smem_layout_outer), mma_mn * mma_k)
        outer = cute.make_ordered_layout(((mma_mn, mma_k), rest_k), order=((1, 0), 2))
        return cute.make_composed_layout(inner, 0, outer)

    @staticmethod
    def adapt_layout_for_tma_sf(sf_tensor: cute.Tensor) -> cute.Tensor:
        """
        Restructure the scale factor layout for TMA load.
        Input: ((SF_MN, SF_K), SF_MN_REST, SF_K_REST)
        Output: ((SF_MN, SF_MN_REST), (SF_K, SF_K_REST))
        """
        sf_atom = cute.get(sf_tensor.layout, mode=[0])
        sf_tiler = cute.select(sf_tensor.layout, mode=[1, 2])
        sf_layout_tma = cute.make_layout(
            (
                (sf_atom[0].shape, sf_tiler[0].shape),
                (sf_atom[1].shape, sf_tiler[1].shape),
            ),
            stride=(
                (sf_atom[0].stride, sf_tiler[0].stride),
                (sf_atom[1].stride, sf_tiler[1].stride),
            ),
        )
        return cute.make_tensor(sf_tensor.iterator, sf_layout_tma)


def run(
    mnkl: Tuple[int, int, int, int],
    mma_tiler_mn: Tuple[int, int],
    cluster_shape_mn: Tuple[int, int],
    a_dtype: Type[cutlass.Numeric],
    b_dtype: Type[cutlass.Numeric],
    sf_dtype: Type[cutlass.Numeric],
    sf_vec_size: int,
    c_dtype: Type[cutlass.Numeric],
    acc_dtype: Type[cutlass.Numeric],
    a_major: str = "k",
    b_major: str = "k",
    c_major: str = "n",
    warmup_iterations: int = 0,
    iterations: int = 1,
    use_cold_l2: bool = False,
    tolerance: float = 1e-01,
    skip_ref_check: bool = False,
    **kwargs,
) -> float:
    """Run and benchmark the SM103 block-scaled dense GEMM D = (A*SFA) @ (B*SFB).

    Args:
        mnkl: Problem size (M, N, K, L).
        mma_tiler_mn: MMA instruction shape (M, N).
        cluster_shape_mn: Launch cluster shape (M, N).
        a_dtype/b_dtype: Narrow operand types (e.g. Float4E2M1FN).
        sf_dtype/sf_vec_size: Scale-factor type and block vector size.
        c_dtype: Output type.
        acc_dtype: Accumulator type. Block-scaled MMA always accumulates in
            Float32, so Float32 is the only accepted value.
        a_major/b_major/c_major: Operand layouts.
        warmup_iterations/iterations: Benchmark loop counts.
        use_cold_l2: Cycle fresh workspaces so every iteration misses L2.
        skip_ref_check: Skip the reference check.
        tolerance: Accepted for harness compatibility. BlockScaledGemmTestbed
            compares against a decoded reference that is bit-exact, so its
            reference_check() is atol=rtol=0 and takes no tolerance.
        kwargs: Absorbs the extra BenchmarkConfig fields that perf_benchmark
            passes to every run(); they are not forwarded any further.

    Returns:
        Execution time in microseconds per iteration.

    Raises:
        ValueError: If a_dtype != b_dtype, if acc_dtype is not Float32, or if
            a 256-wide MMA tile is paired with an odd cluster_shape_mn[0].
        AssertionError: If reference checking is enabled and the output does
            not match the decoded reference exactly.
    """
    # Imported lazily: this module is the SM103 kernel, the testbed lives with
    # the SM100 block-scaled example and importing it at module scope would make
    # the kernel definition depend on the example harness.
    from cute_ext.blackwell.dense_gemm.dense_block_scaled_gemm import (
        BlockScaledGemmTestbed,
    )

    cli.print_problem_config(
        "SM103 Block Scaled Dense GEMM",
        mnkl,
        dtypes={"A": a_dtype, "B": b_dtype},
        lines=[
            f"SF dtype: {sf_dtype}, SF vec size: {sf_vec_size}",
            f"C dtype: {c_dtype}, Acc dtype: {acc_dtype}",
        ],
        majors={"A": a_major, "B": b_major, "C": c_major},
    )
    print(f"Mma Tiler (M, N): {mma_tiler_mn}, Cluster (M, N): {cluster_shape_mn}")
    cli.print_benchmark_config(
        tolerance=tolerance,
        warmup_iterations=warmup_iterations,
        iterations=iterations,
        skip_ref_check=skip_ref_check,
        use_cold_l2=use_cold_l2,
    )

    if a_dtype is not b_dtype:
        raise ValueError(
            f"SM103 block-scaled GEMM requires a_dtype == b_dtype, "
            f"got {a_dtype} and {b_dtype}"
        )

    # Only Float32 accumulation is supported by this kernel.
    if acc_dtype is not cutlass.Float32:
        raise ValueError(
            f"SM103 block-scaled GEMM only supports acc_dtype=Float32, got {acc_dtype}"
        )
    # 2-CTA MMA pairs CTAs along M, so cluster-M must cover the peer pair.
    if mma_tiler_mn[0] == 256 and cluster_shape_mn[0] % 2 != 0:
        raise ValueError(
            f"mma_tiler_mn[0]=256 requires an even cluster_shape_mn[0], "
            f"got {cluster_shape_mn}"
        )

    def make_testbed():
        return BlockScaledGemmTestbed(
            MNKL=mnkl,
            ab_dtype=a_dtype,
            d_dtype=c_dtype,
            sf_dtype=sf_dtype,
            sf_vec_size=sf_vec_size,
            a_major=a_major,
            b_major=b_major,
            d_major=c_major,
        )

    tb = make_testbed()

    block_scaled_gemm = SM103BlockScaledDenseGemmKernel(
        mma_inst_mn=mma_tiler_mn,
        a_dtype=a_dtype,
        b_dtype=b_dtype,
        sf_dtype=sf_dtype,
        sf_vec_size=sf_vec_size,
        cluster_shape_mn=cluster_shape_mn,
    )

    compiled_kernel = cute_ext.compile(
        block_scaled_gemm,
        tb.a_tensor,
        tb.sfa_tensor,
        tb.b_tensor,
        tb.sfb_tensor,
        tb.d_tensor,
    )
    compiled_kernel.engine.initialize()
    compiled_kernel(
        tb.a_tensor,
        tb.sfa_tensor,
        tb.b_tensor,
        tb.sfb_tensor,
        tb.d_tensor,
    )

    if not skip_ref_check:
        tb.reference_check()
        print("check reference: PASS")

    def generate_tensors():
        workspace_tb = make_testbed()
        jit_args = testing.JitArguments(
            workspace_tb.a_tensor,
            workspace_tb.sfa_tensor,
            workspace_tb.b_tensor,
            workspace_tb.sfb_tensor,
            workspace_tb.d_tensor,
        )
        # Keep the backing Torch tensors alive for the workspace's lifetime.
        jit_args.add_to_scope([workspace_tb])
        return jit_args

    workspace_count = 1
    if use_cold_l2:
        one_workspace_bytes = (
            tb.a_ref.numel() * tb.a_ref.element_size()
            + tb.b_ref.numel() * tb.b_ref.element_size()
            + tb.sfa_gpu.numel() * tb.sfa_gpu.element_size()
            + tb.sfb_gpu.numel() * tb.sfb_gpu.element_size()
            + tb.d_gpu.numel() * tb.d_gpu.element_size()
        )
        workspace_count = testing.get_workspace_count(
            one_workspace_bytes, warmup_iterations, iterations
        )

    exec_time = testing.benchmark(
        compiled_kernel,
        workspace_generator=generate_tensors,
        workspace_count=workspace_count,
        warmup_iterations=warmup_iterations,
        iterations=iterations,
    )

    return exec_time


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Example of Block Scaled Dense GEMM on SM103."
    )

    cli.add_mnkl_arg(parser, default=(8192, 8192, 6144, 1), strict_length=True)
    cli.add_mma_tiler_arg(
        parser,
        default=(256, 256),
        strict_length=True,
        help="Mma instruction shape (comma-separated)",
    )
    cli.add_cluster_shape_arg(parser, default=(4, 4), strict_length=True)
    cli.add_dtype_args(parser, c=cutlass.Float8E5M2)
    cli.add_major_args(parser)
    cli.add_benchmark_args(parser)

    # A, B and the scale factors carry separate dtypes on this kernel.
    parser.add_argument("--a_dtype", type=cutlass.dtype, default=cutlass.Float4E2M1FN)
    parser.add_argument("--b_dtype", type=cutlass.dtype, default=cutlass.Float4E2M1FN)
    parser.add_argument("--sf_dtype", type=cutlass.dtype, default=cutlass.Float8E8M0FNU)
    parser.add_argument("--sf_vec_size", type=int, choices=[16, 32], default=16)

    args = parser.parse_args()

    run(
        args.mnkl,
        args.mma_tiler_mn,
        args.cluster_shape_mn,
        args.a_dtype,
        args.b_dtype,
        args.sf_dtype,
        args.sf_vec_size,
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
    )
    print("PASS")
