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
import math
import os
import sys
from typing import Type, Tuple, Optional

import cuda.bindings.driver as cuda
import torch

import cutlass
import cutlass.cute as cute
import cutlass.cute.nvgpu.tcgen05 as tcgen05
import cutlass.utils as utils
import cutlass.pipeline as pipeline
from cutlass.pipeline import pipeline_init_arrive, pipeline_init_wait
import cutlass.utils.blackwell_helpers as sm100_utils
from cutlass.cute.runtime import from_dlpack
from cutlass.cute.typing import Int32, Int64, Float32

if __name__ == "__main__":
    current_dir = os.path.dirname(os.path.abspath(__file__))
    sys.path.insert(0, os.path.join(current_dir, "../.."))

from helpers import fmha_helpers as fmha_utils
from blackwell.mixed_input_fmha import prefill_helpers as prefill_utils


class MixedInputFusedMultiHeadAttentionPrefillD256:
    def __init__(
        self,
        scale_granularity: int,
        qk_acc_dtype: Type[cutlass.Numeric],
        pv_acc_dtype: Type[cutlass.Numeric],
        is_persistent: bool,
        mask_type: fmha_utils.MaskEnum,
    ):
        self.qk_acc_dtype = qk_acc_dtype
        self.pv_acc_dtype = pv_acc_dtype
        self.cta_tiler = (128, 128, 256)
        self.qk_mma_tiler = (
            self.cta_tiler[0] * 2,  # default 2cta
            self.cta_tiler[1],
            min(self.cta_tiler[2], 128),  # avoid too large GemmK
        )
        self.pv_mma_tiler = self.qk_mma_tiler  # keep BMM1 & BMM2 at the same pace
        self.pv_block_tiler = (
            self.pv_mma_tiler[0] // 2,  # default 2cta
            self.pv_mma_tiler[1],
            self.pv_mma_tiler[2],
        )
        self.scale_granularity = scale_granularity
        self.iterations_qk = self.cta_tiler[2] // self.qk_mma_tiler[2]
        self.iterations_pv = self.cta_tiler[2] // self.pv_mma_tiler[1]
        self.cluster_shape_mn = (2, 1)  # use 2x1 cluster by default
        self.tmem_warp_shape_mn = (4, 1)
        self.is_persistent = is_persistent
        self.mask_type = mask_type
        self.transform_warp_ids = (0, 1, 2, 3, 4, 5, 6, 7)  # i8 -> bf16 for kv
        self.softmax_warp_ids = (8, 9, 10, 11)  # softmax
        self.correction_warp_ids = (12, 13, 14, 15)  # correction
        self.mma_warp_id = 16  # mma
        self.load_warp_id = 17  # load
        self.empty_warp_ids = (18, 19)  # empty
        self.num_tmem_alloc_cols = cute.arch.get_max_tmem_alloc_cols("sm_100")
        self.tmem_alloc_sync_bar_id = 1
        self.tmem_s_offset = 256
        self.tmem_p_offset = self.tmem_s_offset
        self.tmem_o_offset = 0
        self.num_regs_softmax = 256
        self.num_regs_correction = 112
        self.num_regs_other = 32
        self.num_regs_transform = 40
        self.buffer_align_bytes = 1024
        self.threads_per_warp = 32
        self.threads_per_cta = self.threads_per_warp * len(
            (
                *self.transform_warp_ids,
                *self.softmax_warp_ids,
                *self.correction_warp_ids,
                self.load_warp_id,
                self.mma_warp_id,
                *self.empty_warp_ids,
            )
        )

    def _setup_attributes(self):
        """Set up configurations and parameters for the FMHA kernel operation.

        This method initializes and configures various attributes required for the
        execution of the fused multi-head attention kernel, mainly about the pipeline stages:

        - Sets up staging parameters for Q, K, V inputs and accumulator data
        - Configures pipeline stages for softmax, correction, and epilogue operations
        """

        self.q_stage = self.iterations_qk
        self.kv_stage = 4
        self.scale_k_stage = self.kv_stage
        self.scale_v_stage = self.kv_stage
        self.qk_acc_stage = 2
        self.pv_acc_stage = 1
        self.kv_trans_stage = 2

    @cute.jit
    def __call__(
        self,
        q_iter: cute.Pointer,
        k_iter: cute.Pointer,
        v_iter: cute.Pointer,
        o_iter: cute.Pointer,
        scale_k_iter: cute.Pointer,
        scale_v_iter: cute.Pointer,
        problem_shape: Tuple[Int32, Int32, Int32, Int32, Int32, Int32],
        scale_softmax_log2: Float32,
        scale_output: Float32,
        window_size_left: Optional[Int32],
        window_size_right: Optional[Int32],
        stream: cuda.CUstream,
    ):
        self._setup_attributes()
        b, s_q, s_k, h_q, h_k, d = problem_shape
        h_r = h_q // h_k
        self.d_r = self.cta_tiler[2] // self.scale_granularity
        # (s, d, ((h_r, h_k), b))
        q_layout = cute.make_layout(
            (s_q, d, ((h_r, h_k), b)),
            stride=(d, 1, ((d * s_q, d * s_q * h_r), h_r * h_k * s_q * d)),
        )
        q = cute.make_tensor(q_iter, q_layout)
        # (s, d, ((h_r, h_k), b)), 0-stride for h_r to broadcast
        k_layout = cute.make_layout(
            (s_k, d, ((h_r, h_k), b)),
            stride=(d, 1, ((0, d * s_k), h_k * s_k * d)),
        )
        k = cute.make_tensor(k_iter, k_layout)
        # (d, s, ((h_r, h_k), b)), 0-stride for h_r to broadcast
        v_layout = cute.make_layout(
            (d, s_k, ((h_r, h_k), b)),
            stride=(1, d, ((0, d * s_k), h_k * s_k * d)),
        )
        v = cute.make_tensor(v_iter, v_layout)
        # (s, d, ((h_r, h_k), b))
        # set divby for better gmem store vectorization
        o_layout = cute.make_layout(
            (s_q, d, ((h_r, h_k), b)),
            stride=(
                cute.assume(d, divby=256),
                1,
                (
                    (
                        cute.assume(d * s_q, divby=256),
                        cute.assume(d * s_q * h_r, divby=256),
                    ),
                    cute.assume(h_r * h_k * s_q * d, divby=256),
                ),
            ),
        )
        o = cute.make_tensor(o_iter, o_layout)
        # (d_r * s, ((h_r, h_k), b))
        scale_k_layout = cute.make_layout(
            (s_k * self.d_r, ((h_r, h_k), b)),
            stride=(1, ((0, self.d_r * s_k), s_k * self.d_r * h_k)),
        )
        scale_k = cute.make_tensor(scale_k_iter, scale_k_layout)
        # (d_r * s, ((h_r, h_k), b))
        scale_v_layout = cute.make_layout(
            (self.d_r * s_k, ((h_r, h_k), b)),
            stride=(1, ((0, self.d_r * s_k), s_k * self.d_r * h_k)),
        )
        scale_v = cute.make_tensor(scale_v_iter, scale_v_layout)

        self.q_dtype = q.element_type
        self.k_dtype = k.element_type
        self.v_dtype = v.element_type
        self.o_dtype = o.element_type
        self.p_dtype = self.q_dtype  # pv should has the same dtype
        self.tilePlikeFP32 = self.qk_mma_tiler[1] // Float32.width * self.p_dtype.width
        self.scale_k_dtype = scale_k.element_type
        self.scale_v_dtype = scale_v.element_type

        self.tile_sched_params, grid = fmha_utils.compute_grid(
            o.shape,
            self.cta_tiler,
            self.is_persistent,
        )

        self.q_major_mode = utils.LayoutEnum.from_tensor(q).mma_major_mode()
        self.k_major_mode = utils.LayoutEnum.from_tensor(k).mma_major_mode()
        self.v_major_mode = utils.LayoutEnum.from_tensor(v).mma_major_mode()
        self.o_layout = utils.LayoutEnum.from_tensor(o)
        cta_group = tcgen05.CtaGroup.TWO
        p_major_mode = tcgen05.OperandMajorMode.K
        p_source = tcgen05.OperandSource.TMEM
        qk_tiled_mma = sm100_utils.make_trivial_tiled_mma(
            self.q_dtype,
            self.q_major_mode,
            self.k_major_mode,
            self.qk_acc_dtype,
            cta_group,
            self.qk_mma_tiler[:2],
        )
        pv_tiled_mma = sm100_utils.make_trivial_tiled_mma(
            self.q_dtype,
            p_major_mode,
            self.v_major_mode,
            self.pv_acc_dtype,
            cta_group,
            self.pv_mma_tiler[:2],
            p_source,
        )
        self.cluster_shape_mnk = (*self.cluster_shape_mn, 1)
        self.cluster_layout_vmnk = cute.tiled_divide(
            cute.make_layout(self.cluster_shape_mnk),
            (qk_tiled_mma.thr_id.shape,),
        )
        self.epi_tile = self.pv_block_tiler[:2]

        q_smem_layout_staged = sm100_utils.make_smem_layout_a(
            qk_tiled_mma,
            self.qk_mma_tiler,
            self.q_dtype,
            self.q_stage,
        )
        k_smem_layout_staged = sm100_utils.make_smem_layout_b(
            qk_tiled_mma,
            self.qk_mma_tiler,
            self.q_dtype,
            self.kv_stage,
        )
        k_smem_layout_staged = cute.make_composed_layout(
            cute.make_swizzle(0, 4, 3), 0, k_smem_layout_staged.outer
        )
        k_trans_smem_layout_staged = sm100_utils.make_smem_layout_b(
            qk_tiled_mma,
            self.qk_mma_tiler,
            self.q_dtype,
            self.kv_trans_stage,
        )
        p_tmem_layout_staged = sm100_utils.make_smem_layout_a(
            pv_tiled_mma,
            self.pv_mma_tiler,
            self.p_dtype,
            self.qk_acc_stage,
        )
        p_tmem_layout = cute.select(p_tmem_layout_staged, mode=[0, 1, 2])
        v_smem_layout_staged = sm100_utils.make_smem_layout_b(
            pv_tiled_mma,
            self.pv_mma_tiler,
            self.q_dtype,
            self.kv_stage,
        )
        v_smem_layout_staged = cute.make_composed_layout(
            cute.make_swizzle(0, 4, 3), 0, v_smem_layout_staged.outer
        )
        v_trans_smem_layout_staged = sm100_utils.make_smem_layout_b(
            pv_tiled_mma,
            self.pv_mma_tiler,
            self.q_dtype,
            self.kv_trans_stage,
        )
        scale_k_smem_layout, self.scale_k_tiler, scale_k_s2r_view_layout = (
            prefill_utils.get_scale_smem_layout(
                self.scale_granularity,
                self.d_r,
                self.qk_mma_tiler,
                self.k_major_mode,
            )
        )
        scale_k_smem_layout_staged = cute.append(
            scale_k_smem_layout,
            cute.make_layout(
                (self.scale_k_stage),
                stride=(cute.cosize(scale_k_smem_layout.outer)),
            ),
        )
        scale_k_s2r_view_layout_staged = cute.append(
            scale_k_s2r_view_layout,
            cute.make_layout(
                (self.scale_k_stage),
                stride=(cute.cosize(scale_k_s2r_view_layout)),
            ),
        )
        scale_v_smem_layout, self.scale_v_tiler, scale_v_s2r_view_layout = (
            prefill_utils.get_scale_smem_layout(
                self.scale_granularity,
                self.d_r,
                self.pv_mma_tiler,
                self.v_major_mode,
            )
        )
        scale_v_smem_layout_staged = cute.append(
            scale_v_smem_layout,
            cute.make_layout(
                (self.scale_v_stage),
                stride=(cute.cosize(scale_v_smem_layout.outer)),
            ),
        )
        scale_v_s2r_view_layout_staged = cute.append(
            scale_v_s2r_view_layout,
            cute.make_layout(
                (self.scale_v_stage),
                stride=(cute.cosize(scale_v_s2r_view_layout)),
            ),
        )

        tma_load_q_op = cute.nvgpu.cpasync.CopyBulkTensorTileG2SOp(cta_group)
        # For TMA Async, use one cta to sync with corresponding cta only
        tma_load_kv_op = cute.nvgpu.cpasync.CopyBulkTensorTileG2SOp(
            tcgen05.CtaGroup.ONE
        )
        q_smem_layout = cute.select(q_smem_layout_staged, mode=[0, 1, 2])
        tma_atom_q, tma_tensor_q = cute.nvgpu.make_tiled_tma_atom_A(
            tma_load_q_op,
            q,
            q_smem_layout,
            self.qk_mma_tiler,
            qk_tiled_mma,
            self.cluster_layout_vmnk.shape,
        )
        # TMA load for K
        k_smem_layout = cute.select(k_smem_layout_staged, mode=[0, 1, 2])
        tma_atom_k, tma_tensor_k = cute.nvgpu.make_tiled_tma_atom_B(
            tma_load_kv_op,
            k,
            k_smem_layout,
            self.qk_mma_tiler,
            qk_tiled_mma,
            self.cluster_layout_vmnk.shape,
        )
        tma_atom_scale_k, tma_tensor_scale_k = cute.nvgpu.cpasync.make_tiled_tma_atom(
            tma_load_kv_op,
            scale_k,
            scale_k_smem_layout,
            (self.scale_k_tiler[0] // 2,),
        )

        # TMA load for V
        v_smem_layout = cute.select(v_smem_layout_staged, mode=[0, 1, 2])
        tma_atom_v, tma_tensor_v = cute.nvgpu.make_tiled_tma_atom_B(
            tma_load_kv_op,
            v,
            v_smem_layout,
            self.pv_mma_tiler,
            pv_tiled_mma,
            self.cluster_layout_vmnk.shape,
        )
        tma_atom_scale_v, tma_tensor_scale_v = cute.nvgpu.cpasync.make_tiled_tma_atom(
            tma_load_kv_op,
            scale_v,
            scale_v_smem_layout,
            self.scale_v_tiler,
        )

        self.tma_copy_q_bytes = cute.size_in_bytes(
            self.q_dtype, q_smem_layout
        ) * cute.size(qk_tiled_mma.thr_id.shape)
        self.tma_copy_kv_bytes = cute.size_in_bytes(self.k_dtype, k_smem_layout)
        self.tma_copy_scale_k_bytes = cute.size_in_bytes(
            self.scale_k_dtype, scale_k_smem_layout
        )
        self.tma_copy_scale_v_bytes = cute.size_in_bytes(
            self.scale_v_dtype, scale_v_smem_layout
        )

        @cute.struct
        class SharedStorage:
            # Pipeline barriers
            load_q_mbar_ptr: cute.struct.MemRange[Int64, self.q_stage * 2]
            load_kv_mbar_ptr: cute.struct.MemRange[Int64, self.kv_stage * 2]
            load_scale_k_mbar_ptr: cute.struct.MemRange[Int64, self.scale_k_stage * 2]
            load_scale_v_mbar_ptr: cute.struct.MemRange[Int64, self.scale_v_stage * 2]
            dequant_kv_mbar_ptr: cute.struct.MemRange[Int64, self.kv_trans_stage * 2]
            mma_s_mbar_ptr: cute.struct.MemRange[Int64, self.qk_acc_stage * 2]
            p_mma_mbar_ptr: cute.struct.MemRange[Int64, self.qk_acc_stage * 2]
            s_corr_mbar_ptr: cute.struct.MemRange[Int64, self.qk_acc_stage * 2]
            sum_mbar_ptr: cute.struct.MemRange[Int64, 2]
            mma_o_mbar_ptr: cute.struct.MemRange[Int64, self.pv_acc_stage * 2]
            tmem_dealloc_mbar_ptr: Int64
            tmem_holding_buf: Int32

        self.shared_storage = SharedStorage

        grid = cute.round_up(grid, self.cluster_shape_mnk)

        # Launch the kernel synchronously
        self.kernel(
            qk_tiled_mma,
            pv_tiled_mma,
            tma_atom_q,
            tma_tensor_q,
            tma_atom_k,
            tma_tensor_k,
            tma_atom_scale_k,
            tma_tensor_scale_k,
            tma_atom_v,
            tma_tensor_v,
            tma_atom_scale_v,
            tma_tensor_scale_v,
            o,
            scale_softmax_log2,
            scale_output,
            window_size_left,
            window_size_right,
            self.cluster_layout_vmnk,
            q_smem_layout_staged,
            k_smem_layout_staged,
            k_trans_smem_layout_staged,
            scale_k_smem_layout_staged,
            scale_k_s2r_view_layout_staged,
            p_tmem_layout,
            v_smem_layout_staged,
            v_trans_smem_layout_staged,
            scale_v_smem_layout_staged,
            scale_v_s2r_view_layout_staged,
            self.epi_tile,
            self.tile_sched_params,
        ).launch(
            grid=grid,
            block=[self.threads_per_cta, 1, 1],
            cluster=self.cluster_shape_mnk,
            stream=stream,
            min_blocks_per_mp=1,
        )

    @cute.kernel
    def kernel(
        self,
        qk_tiled_mma: cute.TiledMma,
        pv_tiled_mma: cute.TiledMma,
        tma_atom_q: cute.CopyAtom,
        mQ_qdl: cute.Tensor,
        tma_atom_k: cute.CopyAtom,
        mK_kdl: cute.Tensor,
        tma_atom_scale_k: cute.CopyAtom,
        mScaleK_kdl: cute.Tensor,
        tma_atom_v: cute.CopyAtom,
        mV_dkl: cute.Tensor,
        tma_atom_scale_v: cute.CopyAtom,
        mScaleV_dkl: cute.Tensor,
        mO_qdl: cute.Tensor,
        scale_softmax_log2: Float32,
        scale_output: Float32,
        window_size_left: Optional[Int32],
        window_size_right: Optional[Int32],
        cluster_layout_vmnk: cute.Layout,
        q_smem_layout_staged: cute.ComposedLayout,
        k_smem_layout_staged: cute.ComposedLayout,
        k_trans_smem_layout_staged: cute.ComposedLayout,
        scale_k_smem_layout_staged: cute.ComposedLayout,
        scale_k_s2r_view_layout_staged: cute.Layout,
        p_tmem_layout: cute.ComposedLayout,
        v_smem_layout_staged: cute.ComposedLayout,
        v_trans_smem_layout_staged: cute.ComposedLayout,
        scale_v_smem_layout_staged: cute.ComposedLayout,
        scale_v_s2r_view_layout_staged: cute.Layout,
        epi_tile: cute.Tile,
        tile_sched_params: fmha_utils.FmhaStaticTileSchedulerParams,
    ):
        warp_idx = cute.arch.make_warp_uniform(cute.arch.warp_idx())
        # Prefetch tma desc
        if warp_idx == self.load_warp_id:
            cute.nvgpu.cpasync.prefetch_descriptor(tma_atom_q)
            cute.nvgpu.cpasync.prefetch_descriptor(tma_atom_k)
            cute.nvgpu.cpasync.prefetch_descriptor(tma_atom_v)
            cute.nvgpu.cpasync.prefetch_descriptor(tma_atom_scale_k)
            cute.nvgpu.cpasync.prefetch_descriptor(tma_atom_scale_v)
        bidx, _, _ = cute.arch.block_idx()
        mma_tile_coord_v = bidx % cute.size(qk_tiled_mma.thr_id.shape)
        cta_rank_in_cluster = cute.arch.make_warp_uniform(
            cute.arch.block_idx_in_cluster()
        )
        block_in_cluster_coord_vmnk = cluster_layout_vmnk.get_flat_coord(
            cta_rank_in_cluster
        )
        # Alloc
        smem = utils.SmemAllocator()
        storage = smem.allocate(self.shared_storage)

        load_q_producer, load_q_consumer = pipeline.PipelineTmaUmma.create(
            num_stages=self.q_stage,
            producer_group=pipeline.CooperativeGroup(
                pipeline.Agent.Thread, len([self.load_warp_id])
            ),
            consumer_group=pipeline.CooperativeGroup(
                pipeline.Agent.Thread, len([self.mma_warp_id])
            ),
            tx_count=self.tma_copy_q_bytes,
            barrier_storage=storage.load_q_mbar_ptr.data_ptr(),
            cta_layout_vmnk=cluster_layout_vmnk,
            defer_sync=True,
        ).make_participants()
        load_kv_producer, load_kv_consumer = pipeline.PipelineTmaAsync.create(
            num_stages=self.kv_stage,
            producer_group=pipeline.CooperativeGroup(
                pipeline.Agent.Thread, len([self.load_warp_id])
            ),
            consumer_group=pipeline.CooperativeGroup(
                pipeline.Agent.Thread,
                len(self.transform_warp_ids) * self.threads_per_warp,
            ),
            tx_count=self.tma_copy_kv_bytes,
            barrier_storage=storage.load_kv_mbar_ptr.data_ptr(),
            tidx=0,
            defer_sync=True,
        ).make_participants()
        load_scale_k_producer, load_scale_k_consumer = pipeline.PipelineTmaAsync.create(
            num_stages=self.scale_k_stage,
            producer_group=pipeline.CooperativeGroup(
                pipeline.Agent.Thread, len([self.load_warp_id])
            ),
            consumer_group=pipeline.CooperativeGroup(
                pipeline.Agent.Thread,
                len(self.transform_warp_ids) * self.threads_per_warp,
            ),
            tx_count=self.tma_copy_scale_k_bytes,
            barrier_storage=storage.load_scale_k_mbar_ptr.data_ptr(),
            tidx=0,
            defer_sync=True,
        ).make_participants()
        load_scale_v_producer, load_scale_v_consumer = pipeline.PipelineTmaAsync.create(
            num_stages=self.scale_v_stage,
            producer_group=pipeline.CooperativeGroup(
                pipeline.Agent.Thread, len([self.load_warp_id])
            ),
            consumer_group=pipeline.CooperativeGroup(
                pipeline.Agent.Thread,
                len(self.transform_warp_ids) * self.threads_per_warp,
            ),
            tx_count=self.tma_copy_scale_v_bytes,
            barrier_storage=storage.load_scale_v_mbar_ptr.data_ptr(),
            tidx=0,
            defer_sync=True,
        ).make_participants()
        dequant_kv_producer, dequant_kv_consumer = pipeline.PipelineAsyncUmma.create(
            num_stages=self.kv_trans_stage,
            producer_group=pipeline.CooperativeGroup(
                pipeline.Agent.Thread,
                len(self.transform_warp_ids)
                * self.threads_per_warp
                * self.cluster_shape_mnk[0],
            ),
            consumer_group=pipeline.CooperativeGroup(
                pipeline.Agent.Thread, len([self.mma_warp_id])
            ),
            barrier_storage=storage.dequant_kv_mbar_ptr.data_ptr(),
            cta_layout_vmnk=cluster_layout_vmnk,
            defer_sync=True,
        ).make_participants()
        mma_s_producer, mma_s_consumer = pipeline.PipelineUmmaAsync.create(
            num_stages=self.qk_acc_stage,
            producer_group=pipeline.CooperativeGroup(
                pipeline.Agent.Thread, len([self.mma_warp_id])
            ),
            consumer_group=pipeline.CooperativeGroup(
                pipeline.Agent.Thread,
                len(self.softmax_warp_ids)
                * self.threads_per_warp
                * self.cluster_shape_mnk[0],
            ),
            barrier_storage=storage.mma_s_mbar_ptr.data_ptr(),
            cta_layout_vmnk=cluster_layout_vmnk,
            defer_sync=True,
        ).make_participants()
        p_mma_producer, p_mma_consumer = pipeline.PipelineAsyncUmma.create(
            num_stages=self.qk_acc_stage,
            producer_group=pipeline.CooperativeGroup(
                pipeline.Agent.Thread,
                len(self.softmax_warp_ids)
                * self.threads_per_warp
                * self.cluster_shape_mnk[0],
            ),
            consumer_group=pipeline.CooperativeGroup(
                pipeline.Agent.Thread, len([self.mma_warp_id])
            ),
            barrier_storage=storage.p_mma_mbar_ptr.data_ptr(),
            cta_layout_vmnk=cluster_layout_vmnk,
            defer_sync=True,
        ).make_participants()
        s_corr_producer, s_corr_consumer = pipeline.PipelineAsync.create(
            num_stages=self.qk_acc_stage,
            producer_group=pipeline.CooperativeGroup(
                pipeline.Agent.Thread,
                self.threads_per_warp * len(self.softmax_warp_ids),
            ),
            consumer_group=pipeline.CooperativeGroup(
                pipeline.Agent.Thread,
                self.threads_per_warp * len(self.correction_warp_ids),
            ),
            barrier_storage=storage.s_corr_mbar_ptr.data_ptr(),
            defer_sync=True,
        ).make_participants()
        sum_producer, sum_consumer = pipeline.PipelineAsync.create(
            num_stages=1,
            producer_group=pipeline.CooperativeGroup(
                pipeline.Agent.Thread,
                self.threads_per_warp * len(self.softmax_warp_ids),
            ),
            consumer_group=pipeline.CooperativeGroup(
                pipeline.Agent.Thread,
                self.threads_per_warp * len(self.correction_warp_ids),
            ),
            barrier_storage=storage.sum_mbar_ptr.data_ptr(),
            defer_sync=True,
        ).make_participants()
        mma_o_producer, mma_o_consumer = pipeline.PipelineUmmaAsync.create(
            num_stages=self.pv_acc_stage,
            producer_group=pipeline.CooperativeGroup(
                pipeline.Agent.Thread, len([self.mma_warp_id])
            ),
            consumer_group=pipeline.CooperativeGroup(
                pipeline.Agent.Thread,
                len(self.correction_warp_ids)
                * self.threads_per_warp
                * self.cluster_shape_mnk[0],
            ),
            barrier_storage=storage.mma_o_mbar_ptr.data_ptr(),
            cta_layout_vmnk=cluster_layout_vmnk,
            defer_sync=True,
        ).make_participants()
        tmem_alloc_barrier = pipeline.NamedBarrier(
            barrier_id=self.tmem_alloc_sync_bar_id,
            num_threads=self.threads_per_warp
            * len(
                (self.mma_warp_id, *self.softmax_warp_ids, *self.correction_warp_ids)
            ),
        )
        # Tensor memory dealloc barrier init
        tmem = utils.TmemAllocator(
            storage.tmem_holding_buf,
            barrier_for_retrieve=tmem_alloc_barrier,
            allocator_warp_id=self.correction_warp_ids[0],
            is_two_cta=True,
            two_cta_tmem_dealloc_mbar_ptr=storage.tmem_dealloc_mbar_ptr,
        )
        # Cluster arrive after barrier init
        pipeline_init_arrive(cluster_shape_mn=cluster_layout_vmnk, is_relaxed=True)

        sK_trans = smem.allocate_tensor(
            element_type=self.q_dtype,
            layout=k_trans_smem_layout_staged.outer,
            swizzle=k_trans_smem_layout_staged.inner,
            byte_alignment=128,
        )
        sV_trans_ptr = cute.recast_ptr(
            sK_trans.iterator, v_trans_smem_layout_staged.inner
        )
        sV_trans = cute.make_tensor(sV_trans_ptr, v_trans_smem_layout_staged.outer)
        sQ = smem.allocate_tensor(
            element_type=self.q_dtype,
            layout=q_smem_layout_staged.outer,
            swizzle=q_smem_layout_staged.inner,
            byte_alignment=128,
        )
        sScaleK = smem.allocate_tensor(
            element_type=self.scale_k_dtype,
            layout=scale_k_smem_layout_staged.outer,
            swizzle=scale_k_smem_layout_staged.inner,
            byte_alignment=128,
        )
        sScaleK_s2r_view = cute.make_tensor(
            sScaleK.iterator, scale_k_s2r_view_layout_staged
        )
        sScaleV = smem.allocate_tensor(
            element_type=self.scale_v_dtype,
            layout=scale_v_smem_layout_staged.outer,
            swizzle=scale_v_smem_layout_staged.inner,
            byte_alignment=128,
        )
        sScaleV_s2r_view = cute.make_tensor(
            sScaleV.iterator, scale_v_s2r_view_layout_staged
        )
        sK = smem.allocate_tensor(
            element_type=self.k_dtype,
            layout=k_smem_layout_staged.outer,
            swizzle=k_smem_layout_staged.inner,
            byte_alignment=128,
        )
        sV_ptr = cute.recast_ptr(sK.iterator, v_smem_layout_staged.inner)
        sV = cute.make_tensor(sV_ptr, v_smem_layout_staged.outer)

        sSum = smem.allocate_tensor(
            element_type=self.qk_acc_dtype,
            layout=cute.make_layout(len(self.softmax_warp_ids) * self.threads_per_warp),
            byte_alignment=128,
        )

        qk_thr_mma = qk_tiled_mma.get_slice(mma_tile_coord_v)
        pv_thr_mma = pv_tiled_mma.get_slice(mma_tile_coord_v)
        tSrQ = qk_thr_mma.make_fragment_A(sQ)
        tSrK_trans = qk_thr_mma.make_fragment_B(sK_trans)
        tOrV_trans = pv_thr_mma.make_fragment_B(sV_trans)
        qk_acc_shape = pv_thr_mma.partition_shape_C(
            (self.qk_mma_tiler[0], self.qk_mma_tiler[1])
        )
        # (atomV, restM, restN, accStage)
        tStS = qk_tiled_mma.make_fragment_C(
            cute.append(qk_acc_shape, self.qk_acc_stage)
        )
        pv_acc_shape = pv_thr_mma.partition_shape_C(
            cute.select(self.pv_mma_tiler, mode=[0, 1])
        )
        # (atomV, restM, restN)
        tOtO = pv_thr_mma.make_fragment_C(pv_acc_shape)
        tOtO_layout = cute.append(
            tOtO.layout,
            cute.make_layout(
                self.iterations_pv,
                stride=self.pv_mma_tiler[1] // self.tmem_warp_shape_mn[1],
            ),
        )
        tStS = cute.make_tensor(tStS.iterator + self.tmem_s_offset, tStS.layout)
        tOtO_staged = cute.make_tensor(tOtO.iterator + self.tmem_o_offset, tOtO_layout)
        # Local_tile partition global tensors
        q_cta_layout = cute.make_layout(
            cute.slice_(cluster_layout_vmnk, (0, 0, None, 0)).shape
        )
        # (bM, bK, restM, restK, loopM, loopK, loopL)
        gQ_qdl = cute.flat_divide(mQ_qdl, cute.select(self.qk_mma_tiler, mode=[0, 2]))
        tSgQ_qdl = qk_thr_mma.partition_A(gQ_qdl)
        tQsQ, tQgQ_qdl = cute.nvgpu.cpasync.tma_partition(
            tma_atom_q,
            block_in_cluster_coord_vmnk[2],
            q_cta_layout,
            cute.group_modes(sQ, 0, 3),
            cute.group_modes(tSgQ_qdl, 0, 3),
        )
        kv_cta_layout = cute.make_layout(
            cute.slice_(cluster_layout_vmnk, (0, None, 0, 0)).shape
        )
        # (bN, bK, loopN, loopK, loopL)
        gK_kdl = cute.flat_divide(mK_kdl, cute.select(self.qk_mma_tiler, mode=[1, 2]))
        tSgK_kdl = qk_thr_mma.partition_B(gK_kdl)
        tKsK, tKgK_kdl = cute.nvgpu.cpasync.tma_partition(
            tma_atom_k,
            block_in_cluster_coord_vmnk[1],
            kv_cta_layout,
            cute.group_modes(sK, 0, 3),
            cute.group_modes(tSgK_kdl, 0, 3),
        )
        # (blk, loopBlk, loopL)
        gScaleK_kdl = cute.flat_divide(mScaleK_kdl, self.scale_k_tiler)
        # Deal with 2cta
        gScaleK_kdl_ = cute.logical_divide(gScaleK_kdl, (self.scale_k_tiler[0] // 2,))[
            (None, mma_tile_coord_v), None, None
        ]
        tKsScaleK, tKgScaleK_kdl = cute.nvgpu.cpasync.tma_partition(
            tma_atom_scale_k,
            block_in_cluster_coord_vmnk[1],
            kv_cta_layout,
            sScaleK,
            gScaleK_kdl_,
        )
        # (bN, bK, loopN, loopK, loopL)
        gV_dkl = cute.flat_divide(mV_dkl, cute.select(self.pv_mma_tiler, mode=[1, 2]))
        tOgV_dkl = pv_thr_mma.partition_B(gV_dkl)
        tVsV, tVgV_dkl = cute.nvgpu.cpasync.tma_partition(
            tma_atom_v,
            block_in_cluster_coord_vmnk[1],
            kv_cta_layout,
            cute.group_modes(sV, 0, 3),
            cute.group_modes(tOgV_dkl, 0, 3),
        )
        # (bBlk, loopBlk, loopL)
        gScaleV_dkl = cute.flat_divide(mScaleV_dkl, self.scale_v_tiler)
        tVsScaleV, tVgScaleV_dkl = cute.nvgpu.cpasync.tma_partition(
            tma_atom_scale_v,
            block_in_cluster_coord_vmnk[1],
            kv_cta_layout,
            sScaleV,
            gScaleV_dkl,
        )
        # (bM, bN, loopM, loopN, loopL)
        gO_qdl = cute.flat_divide(mO_qdl, cute.select(self.pv_block_tiler, mode=[0, 1]))
        cO_qdl = cute.flat_divide(
            cute.make_identity_tensor(mO_qdl.shape),
            cute.select(self.pv_block_tiler, mode=[0, 1]),
        )
        seqlen_q = mQ_qdl.shape[0]
        seqlen_k = mK_kdl.shape[0]
        tile_sched = fmha_utils.create_fmha_static_tile_scheduler(
            tile_sched_params, cute.arch.block_idx(), cute.arch.grid_dim()
        )
        work_tile = tile_sched.initial_work_tile_info()
        # Cluster wait
        pipeline_init_wait(cluster_shape_mn=cluster_layout_vmnk)

        # ///////////////////////////////////////////////////////////////////////////////
        #  Load
        # ///////////////////////////////////////////////////////////////////////////////
        if warp_idx == self.load_warp_id:
            cute.arch.setmaxregister_decrease(self.num_regs_other)
            while work_tile.is_valid_tile:
                curr_block_coord = work_tile.tile_idx
                mma_block_coord = (
                    curr_block_coord[0] // cute.size(qk_tiled_mma.thr_id.shape),
                    curr_block_coord[1],
                    curr_block_coord[2],
                )
                seqlen_kv_loop_steps = fmha_utils.FusedMask.get_trip_count(
                    self.mask_type,
                    mma_block_coord,
                    self.qk_mma_tiler,
                    seqlen_q,
                    seqlen_k,
                    window_size_left,
                    window_size_right,
                )
                # ((atom_v, rest_v), RestK)
                tQgQ = tQgQ_qdl[None, mma_block_coord[0], None, mma_block_coord[2]]
                # ((atom_v, rest_v), RestN, RestK)
                tKgK = tKgK_kdl[None, None, None, mma_block_coord[2]]
                tKgScaleK = tKgScaleK_kdl[None, None, mma_block_coord[2]]
                # ((atom_v, rest_v), RestN, RestK)
                tVgV = tVgV_dkl[None, None, None, mma_block_coord[2]]
                tVgScaleV = tVgScaleV_dkl[None, None, mma_block_coord[2]]
                load_kv_producer, load_scale_k_producer, load_q_producer = (
                    prefill_utils.load_qk(  # Q & K0 & ScaleK0
                        self.iterations_qk,
                        kv_step=0,
                        k_args=(tKgK, tKsK, tma_atom_k, load_kv_producer),
                        scale_k_args=(
                            tKgScaleK,
                            tKsScaleK,
                            tma_atom_scale_k,
                            load_scale_k_producer,
                        ),
                        q_args=(tQgQ, tQsQ, tma_atom_q, load_q_producer),
                    )
                )
                for step in cutlass.range(1, seqlen_kv_loop_steps, 1, unroll=1):
                    load_kv_producer, load_scale_k_producer = (
                        prefill_utils.load_qk(  # Ki & ScaleKi
                            self.iterations_qk,
                            kv_step=step,
                            k_args=(tKgK, tKsK, tma_atom_k, load_kv_producer),
                            scale_k_args=(
                                tKgScaleK,
                                tKsScaleK,
                                tma_atom_scale_k,
                                load_scale_k_producer,
                            ),
                        )
                    )
                    load_kv_producer, load_scale_v_producer = (
                        prefill_utils.load_v(  # Vi-1 & ScaleVi-1
                            self.iterations_pv,
                            kv_step=step - 1,
                            v_args=(tVgV, tVsV, tma_atom_v, load_kv_producer),
                            scale_v_args=(
                                tVgScaleV,
                                tVsScaleV,
                                tma_atom_scale_v,
                                load_scale_v_producer,
                            ),
                        )
                    )
                load_kv_producer, load_scale_v_producer = (
                    prefill_utils.load_v(  # Vend & ScaleVend
                        self.iterations_pv,
                        kv_step=seqlen_kv_loop_steps - 1,
                        v_args=(tVgV, tVsV, tma_atom_v, load_kv_producer),
                        scale_v_args=(
                            tVgScaleV,
                            tVsScaleV,
                            tma_atom_scale_v,
                            load_scale_v_producer,
                        ),
                    )
                )
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()
            load_kv_producer.tail()
            load_scale_k_producer.tail()
            load_scale_v_producer.tail()
            load_q_producer.tail()

        # ///////////////////////////////////////////////////////////////////////////////
        #  MMA
        # ///////////////////////////////////////////////////////////////////////////////
        if warp_idx == self.mma_warp_id:
            cute.arch.setmaxregister_decrease(self.num_regs_other)
            tmem.wait_for_alloc()
            while work_tile.is_valid_tile:
                curr_block_coord = work_tile.tile_idx
                mma_block_coord = (
                    curr_block_coord[0] // cute.size(qk_tiled_mma.thr_id.shape),
                    curr_block_coord[1],
                    curr_block_coord[2],
                )
                seqlen_kv_loop_steps = fmha_utils.FusedMask.get_trip_count(
                    self.mask_type,
                    mma_block_coord,
                    self.qk_mma_tiler,
                    seqlen_q,
                    seqlen_k,
                    window_size_left,
                    window_size_right,
                )
                load_q_releaser = load_q_consumer.clone()
                pv_tiled_mma.set(tcgen05.Field.ACCUMULATE, False)
                if seqlen_kv_loop_steps > 1:
                    mma_s_producer, load_q_consumer, dequant_kv_consumer = (
                        prefill_utils.mma_qk(  # QK0
                            self.iterations_qk,
                            qk_tiled_mma,
                            (tStS, tSrQ, tSrK_trans),
                            (
                                mma_s_producer,
                                load_q_consumer,
                                None,
                                dequant_kv_consumer,
                            ),
                        )
                    )
                    for i in cutlass.range(1, seqlen_kv_loop_steps - 1, 1, unroll=1):
                        mma_s_producer, _, dequant_kv_consumer = (
                            prefill_utils.mma_qk(  # QKi
                                self.iterations_qk,
                                qk_tiled_mma,
                                (tStS, tSrQ, tSrK_trans),
                                (mma_s_producer, None, None, dequant_kv_consumer),
                            )
                        )
                        (
                            pv_tiled_mma,
                            p_mma_consumer,
                            mma_o_producer,
                            dequant_kv_consumer,
                        ) = self.mma_pv(  # PVi
                            (pv_tiled_mma, pv_thr_mma),
                            (tOtO_staged, tStS, tOrV_trans, p_tmem_layout),
                            (p_mma_consumer, mma_o_producer, dequant_kv_consumer),
                        )
                    mma_s_producer, _, dequant_kv_consumer = (
                        prefill_utils.mma_qk(  # QKend needs to release Q
                            self.iterations_qk,
                            qk_tiled_mma,
                            (tStS, tSrQ, tSrK_trans),
                            (
                                mma_s_producer,
                                None,
                                load_q_releaser,
                                dequant_kv_consumer,
                            ),
                        )
                    )
                    (
                        pv_tiled_mma,
                        p_mma_consumer,
                        mma_o_producer,
                        dequant_kv_consumer,
                    ) = self.mma_pv(  # PVend-1
                        (pv_tiled_mma, pv_thr_mma),
                        (tOtO_staged, tStS, tOrV_trans, p_tmem_layout),
                        (p_mma_consumer, mma_o_producer, dequant_kv_consumer),
                    )
                else:
                    mma_s_producer, load_q_consumer, dequant_kv_consumer = (
                        prefill_utils.mma_qk(  # QK0
                            self.iterations_qk,
                            qk_tiled_mma,
                            (tStS, tSrQ, tSrK_trans),
                            (
                                mma_s_producer,
                                load_q_consumer,
                                load_q_releaser,
                                dequant_kv_consumer,
                            ),
                        )
                    )
                pv_tiled_mma, p_mma_consumer, mma_o_producer, dequant_kv_consumer = (
                    self.mma_pv(  # PVend
                        (pv_tiled_mma, pv_thr_mma),
                        (tOtO_staged, tStS, tOrV_trans, p_tmem_layout),
                        (p_mma_consumer, mma_o_producer, dequant_kv_consumer),
                    )
                )
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()
            mma_s_producer.tail()
            mma_o_producer.tail()

        # ///////////////////////////////////////////////////////////////////////////////
        #  Softmax
        # ///////////////////////////////////////////////////////////////////////////////
        if (
            warp_idx < self.correction_warp_ids[0]
            and warp_idx >= self.softmax_warp_ids[0]
        ):
            cute.arch.setmaxregister_increase(self.num_regs_softmax)
            tmem.wait_for_alloc()
            while work_tile.is_valid_tile:
                curr_block_coord = work_tile.tile_idx
                mma_block_coord = (
                    curr_block_coord[0] // cute.size(qk_tiled_mma.thr_id.shape),
                    curr_block_coord[1],
                    curr_block_coord[2],
                )
                seqlen_kv_loop_steps = fmha_utils.FusedMask.get_trip_count(
                    self.mask_type,
                    mma_block_coord,
                    self.qk_mma_tiler,
                    seqlen_q,
                    seqlen_k,
                    window_size_left,
                    window_size_right,
                )
                unmask_steps = fmha_utils.FusedMask.get_unmasked_trip_count(
                    self.mask_type,
                    mma_block_coord,
                    self.qk_mma_tiler,
                    seqlen_q,
                    seqlen_k,
                    window_size_left,
                    window_size_right,
                )
                cS_base = cute.make_identity_tensor(
                    (self.qk_mma_tiler[0], self.qk_mma_tiler[1])
                )
                cS = cute.domain_offset(
                    (mma_block_coord[0] * self.qk_mma_tiler[0], 0), cS_base
                )
                tScS = qk_thr_mma.partition_C(cS)
                row_max = -Float32.inf
                row_max_prev = -Float32.inf
                row_sum = 0.0
                for step in cutlass.range(seqlen_kv_loop_steps, unroll=1):
                    cS_iter = cute.domain_offset((0, step * self.qk_mma_tiler[1]), cS)
                    tScS_iter = qk_thr_mma.partition_C(cS_iter)
                    # Si -> Pi
                    (
                        row_max,
                        row_sum,
                        mma_s_consumer,
                        p_mma_producer,
                        s_corr_producer,
                    ) = self.softmax_step(
                        (step >= unmask_steps, window_size_left, window_size_right),
                        (
                            row_max_prev,
                            row_sum,
                            seqlen_q,
                            seqlen_k,
                            scale_softmax_log2,
                        ),
                        (tStS, tScS_iter),
                        (mma_s_consumer, p_mma_producer, s_corr_producer),
                    )
                    row_max_prev = row_max
                sum_producer = self.store_sum(row_sum, sSum, sum_producer)
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()
            p_mma_producer.tail()
            s_corr_producer.tail()

        # ///////////////////////////////////////////////////////////////////////////////
        #  Correction
        # ///////////////////////////////////////////////////////////////////////////////
        if warp_idx < self.mma_warp_id and warp_idx >= self.correction_warp_ids[0]:
            cute.arch.setmaxregister_increase(self.num_regs_correction)
            tmem.allocate(self.num_tmem_alloc_cols)
            tmem.wait_for_alloc()
            tmem_ptr = tmem.retrieve_ptr(self.qk_acc_dtype)
            while work_tile.is_valid_tile:
                curr_block_coord = work_tile.tile_idx
                mma_block_coord = (
                    curr_block_coord[0] // cute.size(qk_tiled_mma.thr_id.shape),
                    curr_block_coord[1],
                    curr_block_coord[2],
                )
                seqlen_kv_loop_steps = fmha_utils.FusedMask.get_trip_count(
                    self.mask_type,
                    mma_block_coord,
                    self.qk_mma_tiler,
                    seqlen_q,
                    seqlen_k,
                    window_size_left,
                    window_size_right,
                )
                gO_staged = gO_qdl[
                    None, None, curr_block_coord[0], None, curr_block_coord[2]
                ]
                cO_staged = cO_qdl[
                    None, None, curr_block_coord[0], None, curr_block_coord[2]
                ]
                cS = cute.make_identity_tensor(
                    (self.qk_mma_tiler[0], self.qk_mma_tiler[1])
                )
                tScS = qk_thr_mma.partition_C(cS)
                # Empty step as the first step is no need for correction
                stats_handle = s_corr_consumer.wait_and_advance()
                stats_handle.release()
                for step in cutlass.range(1, seqlen_kv_loop_steps, 1, unroll=1):
                    # Oi-1 -> Oi
                    mma_o_consumer, s_corr_consumer = self.correction_rescale(
                        scale_softmax_log2,
                        (s_corr_consumer, tStS, tScS),
                        (mma_o_consumer, tOtO_staged, cO_staged),
                        epi_tile,
                    )
                # O_partial -> O_final
                mma_o_consumer, sum_consumer = self.correction_epilog(
                    (seqlen_q, scale_output),
                    (sum_consumer, sSum),
                    (mma_o_consumer, gO_staged, cO_staged, tOtO_staged),
                    epi_tile,
                )
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()
            tmem.relinquish_alloc_permit()
            tmem.free(tmem_ptr)

        # ///////////////////////////////////////////////////////////////////////////////
        #  Trans
        # ///////////////////////////////////////////////////////////////////////////////
        if warp_idx < self.softmax_warp_ids[0]:
            cute.arch.setmaxregister_decrease(self.num_regs_transform)
            qk_thr_mma_leader_cta = qk_tiled_mma.get_slice(0)
            pv_thr_mma_leader_cta = pv_tiled_mma.get_slice(0)
            sScaleK_ = qk_thr_mma_leader_cta.partition_B(sScaleK_s2r_view)
            sScaleV_ = pv_thr_mma_leader_cta.partition_B(sScaleV_s2r_view)
            while work_tile.is_valid_tile:
                curr_block_coord = work_tile.tile_idx
                mma_block_coord = (
                    curr_block_coord[0] // cute.size(qk_tiled_mma.thr_id.shape),
                    curr_block_coord[1],
                    curr_block_coord[2],
                )
                seqlen_kv_loop_steps = fmha_utils.FusedMask.get_trip_count(
                    self.mask_type,
                    mma_block_coord,
                    self.qk_mma_tiler,
                    seqlen_q,
                    seqlen_k,
                    window_size_left,
                    window_size_right,
                )
                load_kv_consumer, load_scale_k_consumer, dequant_kv_producer = (
                    prefill_utils.dequant_k(  # K0
                        self.iterations_qk,
                        self.transform_warp_ids,
                        (self.k_dtype, self.q_dtype),
                        (sK, sScaleK_, sK_trans),
                        (load_kv_consumer, load_scale_k_consumer, dequant_kv_producer),
                    )
                )
                for step in cutlass.range(1, seqlen_kv_loop_steps, 1, unroll=1):
                    load_kv_consumer, load_scale_k_consumer, dequant_kv_producer = (
                        prefill_utils.dequant_k(  # Ki
                            self.iterations_qk,
                            self.transform_warp_ids,
                            (self.k_dtype, self.q_dtype),
                            (sK, sScaleK_, sK_trans),
                            (
                                load_kv_consumer,
                                load_scale_k_consumer,
                                dequant_kv_producer,
                            ),
                        )
                    )
                    load_kv_consumer, load_scale_v_consumer, dequant_kv_producer = (
                        prefill_utils.dequant_v(  # Vi-1
                            self.iterations_pv,
                            self.transform_warp_ids,
                            (self.v_dtype, self.q_dtype),
                            (sV, sScaleV_, sV_trans),
                            (
                                load_kv_consumer,
                                load_scale_v_consumer,
                                dequant_kv_producer,
                            ),
                        )
                    )
                load_kv_consumer, load_scale_v_consumer, dequant_kv_producer = (
                    prefill_utils.dequant_v(  # Vend
                        self.iterations_pv,
                        self.transform_warp_ids,
                        (self.v_dtype, self.q_dtype),
                        (sV, sScaleV_, sV_trans),
                        (load_kv_consumer, load_scale_v_consumer, dequant_kv_producer),
                    )
                )
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()
            dequant_kv_producer.tail()

        # ///////////////////////////////////////////////////////////////////////////////
        #  Empty
        # ///////////////////////////////////////////////////////////////////////////////
        if warp_idx > self.load_warp_id:
            cute.arch.setmaxregister_decrease(self.num_regs_other)

        return

    @cute.jit
    def mma_pv(
        self,
        mma_args: Tuple,
        tensor_args: Tuple,
        pipeline_args: Tuple,
    ):
        pv_tiled_mma, pv_thr_mma = mma_args
        tOtO_staged, tStS, tOrV_trans, p_tmem_layout = tensor_args
        p_mma_consumer, mma_o_producer, dequant_kv_consumer = pipeline_args
        cta_rank_in_cluster = cute.arch.make_warp_uniform(
            cute.arch.block_idx_in_cluster()
        )
        is_leader_cta = cta_rank_in_cluster % 2 == 0
        if is_leader_cta:
            p_handle = p_mma_consumer.wait_and_advance()
            o_handle = mma_o_producer.acquire_and_advance()
            pv_whether_acc = pv_tiled_mma.get(tcgen05.Field.ACCUMULATE)
            for iter in cutlass.range(self.iterations_pv, unroll=1):
                v_trans_handle = dequant_kv_consumer.wait_and_advance()
                pv_tiled_mma.set(tcgen05.Field.ACCUMULATE, pv_whether_acc)
                tOtO_slice = tOtO_staged[None, None, None, iter]
                tStS_slice = tStS[None, None, None, p_handle.index]
                tP = cute.make_tensor(tStS_slice.iterator, p_tmem_layout.outer)
                tOrP = pv_thr_mma.make_fragment_A(tP)
                tOrP_slice = cute.make_tensor(
                    cute.recast_ptr(tStS_slice.iterator, dtype=self.p_dtype),
                    tOrP.layout,
                )
                tOrV_trans_slice = tOrV_trans[None, None, None, v_trans_handle.index]
                num_kphases = cute.size(tOrV_trans_slice, mode=[2])
                for kphase_idx in cutlass.range(num_kphases, unroll_full=True):
                    kphase_coord = (None, None, kphase_idx)
                    cute.gemm(
                        pv_tiled_mma,
                        tOtO_slice,
                        tOrP_slice[kphase_coord],
                        tOrV_trans_slice[kphase_coord],
                        tOtO_slice,
                    )
                    pv_tiled_mma.set(tcgen05.Field.ACCUMULATE, True)
                v_trans_handle.release()
            o_handle.commit()
            p_handle.release()
        return pv_tiled_mma, p_mma_consumer, mma_o_producer, dequant_kv_consumer

    @cute.jit
    def softmax_step(
        self,
        mask_args: Tuple,
        value_args: Tuple,
        tensor_args: Tuple,
        pipeline_args: Tuple,
    ) -> Tuple[Float32, Float32, pipeline.PipelineConsumer, pipeline.PipelineProducer]:
        need_apply_mask, window_size_left, window_size_right = mask_args
        row_max, row_sum, seqlen_q, seqlen_k, scale_softmax_log2 = value_args
        tStS, tScS = tensor_args
        mma_s_consumer, p_mma_producer, s_corr_producer = pipeline_args
        tidx, _, _ = cute.arch.thread_idx()
        thread_idx = tidx % (self.threads_per_warp * len(self.softmax_warp_ids))
        s_handle = mma_s_consumer.wait_and_advance()
        tStS_slice = tStS[(None, None), 0, 0, s_handle.index]
        tScS_slice = tScS[(None, None), 0, 0]
        tmem_load_atom = cute.make_copy_atom(
            tcgen05.Ld32x32bOp(tcgen05.Repetition(32)), self.qk_acc_dtype
        )
        tmem_tiled_load = tcgen05.make_tmem_copy(tmem_load_atom, tStS_slice)
        thr_load = tmem_tiled_load.get_slice(thread_idx)
        tTMEM_LOADtS = thr_load.partition_S(tStS_slice)
        tTMEM_LOADcS = thr_load.partition_D(tScS_slice)
        tTMEM_LOADrS = cute.make_rmem_tensor(tTMEM_LOADcS.shape, self.qk_acc_dtype)
        cute.copy(tmem_tiled_load, tTMEM_LOADtS, tTMEM_LOADrS)
        cute.arch.fence_view_async_tmem_load()
        s_handle.release()
        if need_apply_mask:
            fmha_utils.FusedMask.apply_mask(
                self.mask_type,
                tTMEM_LOADrS,
                tTMEM_LOADcS,
                seqlen_q,
                seqlen_k,
                window_size_left,
                window_size_right,
            )
        old_row_max = row_max
        row_max = tTMEM_LOADrS.load().reduce(cute.ReductionOp.MAX, row_max, 0)
        row_max_safe = row_max
        if row_max == -cutlass.Float32.inf:
            row_max_safe = 0.0

        stats_handle = s_corr_producer.acquire_and_advance()
        stats_layout = cute.composition(
            tStS_slice.layout, cute.make_layout((tStS_slice.shape[0], 2))
        )
        stats_c_layout = cute.composition(
            tScS_slice.layout, cute.make_layout((tScS_slice.shape[0], 2))
        )
        tOtStats = cute.make_tensor(
            tStS_slice.iterator + self.tilePlikeFP32, stats_layout
        )
        tOcStats = cute.make_tensor(tScS_slice.iterator, stats_c_layout)
        tmem_store_stats_atom = cute.make_copy_atom(
            tcgen05.copy.St32x32bOp(tcgen05.copy.Repetition(2)),
            self.qk_acc_dtype,
        )
        tiled_tmem_store_stats = tcgen05.make_tmem_copy(tmem_store_stats_atom, tOtStats)
        thr_tmem_store_stats = tiled_tmem_store_stats.get_slice(thread_idx)
        tTMEM_STOREcStats = thr_tmem_store_stats.partition_S(tOcStats)
        tTMEM_STORErStats = cute.make_rmem_tensor(
            tTMEM_STOREcStats.shape, self.qk_acc_dtype
        )
        tTMEM_STORErStats[0] = old_row_max
        tTMEM_STORErStats[1] = row_max_safe
        tTMEM_STOREtStats = thr_tmem_store_stats.partition_D(tOtStats)
        cute.copy(tiled_tmem_store_stats, tTMEM_STORErStats, tTMEM_STOREtStats)
        cute.arch.fence_view_async_tmem_store()
        stats_handle.commit()

        scale = scale_softmax_log2
        minus_row_max_scale = (0.0 - row_max_safe) * scale
        tTMEM_STORErP = cute.make_rmem_tensor(tTMEM_LOADrS.shape, self.p_dtype)
        for k in cutlass.range(cute.size(tTMEM_LOADrS), vectorize=True):
            tTMEM_LOADrS[k] = tTMEM_LOADrS[k] * scale + minus_row_max_scale
            tTMEM_LOADrS[k] = cute.math.exp2(tTMEM_LOADrS[k], fastmath=True)
        s_vec = tTMEM_LOADrS.load()
        tTMEM_STORErP.store(s_vec.to(self.p_dtype))

        p_handle = p_mma_producer.acquire_and_advance()
        tmem_store_atom = cute.make_copy_atom(
            tcgen05.St32x32bOp(tcgen05.Repetition(32)), self.qk_acc_dtype
        )
        tilePlikeFP32 = tStS_slice.shape[1] // Float32.width * self.p_dtype.width
        tStS_P_layout = cute.composition(
            tStS_slice.layout, cute.make_layout((tStS_slice.shape[0], tilePlikeFP32))
        )
        tStS_P = cute.make_tensor(tStS_slice.iterator, tStS_P_layout)
        tScS_P_layout = cute.composition(
            tScS_slice.layout, cute.make_layout((tScS_slice.shape[0], tilePlikeFP32))
        )
        tScS_P = cute.make_tensor(tScS_slice.iterator, tScS_P_layout)
        tmem_tiled_store = tcgen05.make_tmem_copy(tmem_store_atom, tStS_P)
        thr_store = tmem_tiled_store.get_slice(thread_idx)
        tTMEM_STOREtP = thr_store.partition_D(tStS_P)
        tTMEM_STOREcS = thr_store.partition_S(tScS_P)
        tTMEM_STORErP_ = cute.make_tensor(
            cute.recast_ptr(tTMEM_STORErP.iterator, dtype=self.qk_acc_dtype),
            tTMEM_STOREcS.shape,
        )
        cute.copy(tmem_tiled_store, tTMEM_STORErP_, tTMEM_STOREtP)
        cute.arch.fence_view_async_tmem_store()

        p_handle.commit()
        acc_scale_ = scale * (old_row_max - row_max_safe)
        acc_scale = cute.math.exp2(acc_scale_, fastmath=True) * 0.5
        # TODO: calc row sum with TensorSSA
        row_sum *= acc_scale
        local_row_sum_0 = (row_sum, row_sum)
        local_row_sum_1 = (0.0, 0.0)
        local_row_sum_2 = (0.0, 0.0)
        local_row_sum_3 = (0.0, 0.0)
        reduction_unroll = 4
        frg_tile = cute.size(tTMEM_LOADrS) // reduction_unroll
        tTMEM_LOADrS_frg = cute.logical_divide(tTMEM_LOADrS, cute.make_layout(frg_tile))
        for j in cutlass.range_constexpr(0, cute.size(tTMEM_LOADrS_frg, mode=[0]), 2):
            local_row_sum_0 = cute.arch.add_packed_f32x2(
                local_row_sum_0, (tTMEM_LOADrS_frg[j, 0], tTMEM_LOADrS_frg[j + 1, 0])
            )
            local_row_sum_1 = cute.arch.add_packed_f32x2(
                local_row_sum_1, (tTMEM_LOADrS_frg[j, 1], tTMEM_LOADrS_frg[j + 1, 1])
            )
            local_row_sum_2 = cute.arch.add_packed_f32x2(
                local_row_sum_2, (tTMEM_LOADrS_frg[j, 2], tTMEM_LOADrS_frg[j + 1, 2])
            )
            local_row_sum_3 = cute.arch.add_packed_f32x2(
                local_row_sum_3, (tTMEM_LOADrS_frg[j, 3], tTMEM_LOADrS_frg[j + 1, 3])
            )
        local_row_sum_0 = cute.arch.add_packed_f32x2(local_row_sum_0, local_row_sum_1)
        local_row_sum_2 = cute.arch.add_packed_f32x2(local_row_sum_2, local_row_sum_3)
        local_row_sum_0 = cute.arch.add_packed_f32x2(local_row_sum_0, local_row_sum_2)
        row_sum = local_row_sum_0[0] + local_row_sum_0[1]
        return row_max, row_sum, mma_s_consumer, p_mma_producer, s_corr_producer

    @cute.jit
    def correction_rescale(
        self,
        scale_softmax_log2: Float32,
        stats_args: tuple,
        o_args: tuple,
        epi_tile: cute.Tile,
    ) -> pipeline.PipelineConsumer:
        (s_corr_consumer, tStS, tScS) = stats_args
        (mma_o_consumer, tOtO_staged, cO_staged) = o_args
        tidx, _, _ = cute.arch.thread_idx()
        thread_idx = tidx % (self.threads_per_warp * len(self.softmax_warp_ids))

        stats_handle = s_corr_consumer.wait_and_advance()
        tStS_slice = tStS[(None, None), 0, 0, stats_handle.index]
        tScS_slice = tScS[(None, None), 0, 0]
        stats_layout = cute.composition(
            tStS_slice.layout, cute.make_layout((tStS_slice.shape[0], 2))
        )
        stats_c_layout = cute.composition(
            tScS_slice.layout, cute.make_layout((tScS_slice.shape[0], 2))
        )
        tOtStats = cute.make_tensor(
            tStS_slice.iterator + self.tilePlikeFP32, stats_layout
        )
        tOcStats = cute.make_tensor(tScS_slice.iterator, stats_c_layout)
        tmem_load_stats_atom = cute.make_copy_atom(
            tcgen05.copy.Ld32x32bOp(tcgen05.copy.Repetition(2)),
            self.qk_acc_dtype,
        )
        tiled_tmem_load_stats = tcgen05.make_tmem_copy(tmem_load_stats_atom, tOtStats)
        thr_tmem_load_stats = tiled_tmem_load_stats.get_slice(thread_idx)
        tTMEM_LOADtStats = thr_tmem_load_stats.partition_S(tOtStats)
        tTMEM_LOADcStats = thr_tmem_load_stats.partition_D(tOcStats)
        tTMEM_LOADrStats = cute.make_rmem_tensor(
            tTMEM_LOADcStats.shape, self.qk_acc_dtype
        )
        cute.copy(tiled_tmem_load_stats, tTMEM_LOADtStats, tTMEM_LOADrStats)

        scale = scale_softmax_log2 * (tTMEM_LOADrStats[0] - tTMEM_LOADrStats[1])
        scale = cute.math.exp2(scale, fastmath=True)
        stats_handle.release()
        o_handle = mma_o_consumer.wait_and_advance()
        for iter in cutlass.range(self.iterations_pv, unroll_full=True):
            tOtO = tOtO_staged[(None, None), 0, 0, iter]
            cO = cO_staged[None, None, iter]
            tOtO_epi = cute.zipped_divide(tOtO, epi_tile)
            cO_epi = cute.zipped_divide(cO, epi_tile)
            tmem_load_atom = cute.make_copy_atom(
                tcgen05.Ld32x32bOp(tcgen05.Repetition(16)),
                self.pv_acc_dtype,
            )
            tmem_tiled_load = tcgen05.make_tmem_copy(tmem_load_atom, tOtO_epi)
            thr_load = tmem_tiled_load.get_slice(thread_idx)
            tmem_store_atom = cute.make_copy_atom(
                tcgen05.St32x32bOp(tcgen05.Repetition(16)),
                self.pv_acc_dtype,
            )
            tmem_store_atom = tcgen05.make_tmem_copy(tmem_store_atom, tOtO_epi)
            thr_store = tmem_store_atom.get_slice(thread_idx)
            tTMEM_LOADtO = thr_load.partition_S(tOtO_epi)
            tTMEM_LOADcO = thr_load.partition_D(cO_epi)
            tTMEM_STOREtO = thr_store.partition_D(tOtO_epi)
            tTMrO = cute.make_rmem_tensor_like(
                cute.append(
                    cute.make_layout(tTMEM_LOADcO[None, 0, 0].shape),
                    cute.make_layout(
                        2, stride=cute.size(tTMEM_LOADcO[None, 0, 0].shape)
                    ),
                ),
                self.pv_acc_dtype,
            )
            tTMEM_LOADtO_0 = tTMEM_LOADtO[None, 0, 0]
            cute.copy(tmem_tiled_load, tTMEM_LOADtO_0, tTMrO[None, 0])
            iter_num = cute.size(tTMEM_LOADtO, mode=[1])
            for i in cutlass.range(1, iter_num, unroll_full=True):
                tTMEM_LOADtO_i = tTMEM_LOADtO[None, i, 0]
                cute.copy(tmem_tiled_load, tTMEM_LOADtO_i, tTMrO[None, i % 2])
                for j in cutlass.range(
                    cute.size(tTMrO, mode=[0]), unroll_full=True, vectorize=True
                ):
                    tTMrO[j, (i - 1) % 2] = tTMrO[j, (i - 1) % 2] * scale
                tTMEM_STOREtO_prev_i = tTMEM_STOREtO[None, i - 1, 0]
                cute.copy(
                    tmem_store_atom, tTMrO[None, (i - 1) % 2], tTMEM_STOREtO_prev_i
                )

            for j in cutlass.range(
                cute.size(tTMrO, mode=[0]), unroll_full=True, vectorize=True
            ):
                tTMrO[j, (iter_num - 1) % 2] = tTMrO[j, (iter_num - 1) % 2] * scale
            cute.copy(
                tmem_store_atom,
                tTMrO[None, (iter_num - 1) % 2],
                tTMEM_STOREtO[None, iter_num - 1, 0],
            )
        cute.arch.fence_view_async_tmem_store()
        o_handle.release()
        return mma_o_consumer, s_corr_consumer

    @cute.jit
    def correction_epilog(
        self,
        value_args: Tuple,
        sum_args: Tuple,
        o_args: Tuple,
        epi_tile: cute.Tile,
    ) -> Tuple[pipeline.PipelineConsumer, pipeline.PipelineProducer]:
        (seqlen_q, scale_output) = value_args
        (sum_consumer, sSum) = sum_args
        (mma_o_consumer, gO_staged, cO_staged, tOtO_staged) = o_args
        tidx, _, _ = cute.arch.thread_idx()
        thread_idx = tidx % (self.threads_per_warp * len(self.softmax_warp_ids))
        sum_handle = sum_consumer.wait_and_advance()
        row_sum = sSum[thread_idx]
        cute.arch.fence_view_async_shared()
        sum_handle.release()
        scale = scale_output / row_sum
        o_handle = mma_o_consumer.wait_and_advance()
        for iter in cutlass.range(self.iterations_pv):
            gO = gO_staged[None, None, iter]
            cO = cO_staged[None, None, iter]
            tOtO = tOtO_staged[(None, None), 0, 0, iter]
            tOtO_epi = cute.zipped_divide(tOtO, epi_tile)
            cO_epi = cute.zipped_divide(cO, epi_tile)
            gO_epi = cute.zipped_divide(gO, epi_tile)
            tidx, _, _ = cute.arch.thread_idx()
            thread_idx = tidx % (self.threads_per_warp * len(self.softmax_warp_ids))
            tmem_copy_atom = cute.make_copy_atom(
                tcgen05.copy.Ld32x32bOp(tcgen05.copy.Repetition(32)), self.pv_acc_dtype
            )
            tiled_tmem_load = tcgen05.make_tmem_copy(tmem_copy_atom, tOtO_epi)
            thr_tmem_load = tiled_tmem_load.get_slice(thread_idx)
            tTMEM_LOADtO = thr_tmem_load.partition_S(tOtO_epi)
            tTMEM_LOADgO = thr_tmem_load.partition_D(gO_epi)
            tTMEM_LOADcO = thr_tmem_load.partition_D(cO_epi)
            for i in cutlass.range(cute.size(tTMEM_LOADtO, mode=[1]), unroll_full=True):
                tTMEM_LOADtO_i = tTMEM_LOADtO[None, i, 0]
                tTMEM_LOADgO_i = tTMEM_LOADgO[None, i, 0]
                tTMEM_LOADcO_i = tTMEM_LOADcO[None, i, 0]
                tTMrO = cute.make_rmem_tensor(
                    tTMEM_LOADcO[None, 0, i].shape, self.pv_acc_dtype
                )
                cute.copy(tiled_tmem_load, tTMEM_LOADtO_i, tTMrO)
                for j in cutlass.range(
                    cute.size(tTMrO), unroll_full=True, vectorize=True
                ):
                    tTMrO[j] = tTMrO[j] * scale
                tSMrO = cute.make_rmem_tensor(tTMrO.shape, self.o_dtype)
                o_vec = tTMrO.load()
                tSMrO.store(o_vec.to(self.o_dtype))
                if cute.elem_less(tTMEM_LOADcO_i[0][0], seqlen_q):
                    cute.autovec_copy(tSMrO, tTMEM_LOADgO_i)
        o_handle.release()
        return mma_o_consumer, sum_consumer

    def store_sum(self, row_sum, sSum, sum_producer):
        tidx, _, _ = cute.arch.thread_idx()
        thread_idx = tidx % (self.threads_per_warp * len(self.softmax_warp_ids))
        sum_handle = sum_producer.acquire_and_advance()
        sSum[thread_idx] = row_sum
        cute.arch.fence_view_async_shared()
        sum_handle.commit()
        return sum_producer


def run(
    q_shape: Tuple[int, int, int, int],
    k_shape: Tuple[int, int, int, int],
    q_dtype: Type[cutlass.Numeric],
    kv_dtype: Type[cutlass.Numeric],
    o_dtype: Type[cutlass.Numeric],
    scale_dtype: Type[cutlass.Numeric],
    scale_granularity: int,
    qk_acc_dtype: Type[cutlass.Numeric],
    pv_acc_dtype: Type[cutlass.Numeric],
    is_persistent: bool,
    is_causal: bool,
    scale_q: float,
    scale_k: float,
    scale_v: float,
    inv_scale_o: float,
    scale_softmax: float,
    tolerance: float,
    warmup_iterations: int,
    iterations: int,
    skip_ref_check: bool,
    use_cold_l2: bool = False,
    **kwargs,
):
    print(f"Running Blackwell SM100 Mixed Input FMHA Prefill D256 test with:")
    print(f"  q_shape: {q_shape}")
    print(f"  k_shape: {k_shape}")
    print(f"  q_dtype: {q_dtype}")
    print(f"  kv_dtype: {kv_dtype}")
    print(f"  o_dtype: {o_dtype}")
    print(f"  scale_dtype: {scale_dtype}")
    print(f"  scale_granularity: {scale_granularity}")
    print(f"  qk_acc_dtype: {qk_acc_dtype}")
    print(f"  pv_acc_dtype: {pv_acc_dtype}")
    print(f"  is_persistent: {is_persistent}")
    print(f"  is_causal: {is_causal}")
    print(f"  scale_q: {scale_q}")
    print(f"  scale_k: {scale_k}")
    print(f"  scale_v: {scale_v}")
    print(f"  inv_scale_o: {inv_scale_o}")
    print(f"  scale_softmax: {scale_softmax}")
    print(f"  tolerance: {tolerance}")
    print(f"  warmup_iterations: {warmup_iterations}")
    print(f"  iterations: {iterations}")
    print(f"  skip_ref_check: {skip_ref_check}")
    print(f"  use_cold_l2: {use_cold_l2}")
    import cutlass.torch as cutlass_torch

    # Unpack parameters
    b, h_q, s_q, d = q_shape
    b_, h_k, s_k, d_ = k_shape
    window_size_left, window_size_right = None, None
    if is_causal:
        window_size_right = 0

    if b != b_:
        raise ValueError("q & k must have the same batch size")

    if d != d_:
        raise ValueError("q & k must have the same head dimension")

    if d not in {256}:
        raise ValueError("head dimension must be 256")

    if d % scale_granularity != 0:
        raise ValueError("head dimension must be divisible by scale_granularity")

    if scale_granularity not in {128, 256}:
        raise ValueError("scale_granularity must be 128, 256")

    if h_q % h_k != 0:
        raise ValueError("h_q must be divisible by h_k")

    if isinstance(s_q, tuple) and len(s_q) != b:
        raise ValueError("variable_seqlen s_q must have the length of batch size")
    if isinstance(s_k, tuple) and len(s_k) != b:
        raise ValueError("variable_seqlen s_k must have the length of batch size")

    if q_dtype not in {cutlass.BFloat16}:
        raise ValueError("in_dtype must be BFloat16")

    if o_dtype not in {cutlass.BFloat16}:
        raise ValueError("o_dtype must be BFloat16")

    if kv_dtype not in {cutlass.Int8}:
        raise ValueError("kv_dtype must be Int8")

    if qk_acc_dtype not in {cutlass.Float32}:
        raise ValueError("qk_acc_dtype must be Float32")

    if pv_acc_dtype not in {cutlass.Float32}:
        raise ValueError("pv_acc_dtype must be Float32")

    h_r = h_q // h_k

    if not torch.cuda.is_available():
        raise RuntimeError("GPU is required to run this example!")

    torch.manual_seed(1111)

    def create_tensor(shape, dtype):
        f32_torch_tensor = cutlass_torch.create_and_permute_torch_tensor(
            shape,
            torch.float32,
            permute_order=None,
            init_type=cutlass.torch.TensorInitType.RANDOM,
            init_config=cutlass.torch.RandomInitConfig(
                min_val=-2 if dtype.is_float or dtype.signed else 0, max_val=2
            ),
        )

        _, torch_tensor = cutlass_torch.cute_tensor_like(
            f32_torch_tensor,
            dtype,
            is_dynamic_layout=True,
            assumed_align=32,
        )

        # Create dtype cute tensor with offset (gpu)
        cute_tensor = from_dlpack(torch_tensor, assumed_align=128)
        cute_tensor.element_type = dtype

        return (
            f32_torch_tensor,
            cute_tensor,
            torch_tensor,
        )

    scale_shape = (b, h_k, s_k, d // scale_granularity)

    q_ref, q_tensor, q_torch = create_tensor(q_shape, q_dtype)
    k_ref, k_tensor, k_torch = create_tensor(k_shape, kv_dtype)
    v_ref, v_tensor, v_torch = create_tensor(k_shape, kv_dtype)
    o_ref, o_tensor, o_torch = create_tensor(q_shape, o_dtype)
    scale_k_ref, scale_k_tensor, scale_k_torch = create_tensor(scale_shape, scale_dtype)
    scale_v_ref, scale_v_tensor, scale_v_torch = create_tensor(scale_shape, scale_dtype)

    mask_type = fmha_utils.MaskEnum.WINDOW_MASK_INFERENCE
    if is_causal:
        mask_type = fmha_utils.MaskEnum.WINDOW_MASK_INFERENCE
    else:
        if s_k % 128 != 0:
            mask_type = fmha_utils.MaskEnum.RESIDUAL_MASK

    fmha = MixedInputFusedMultiHeadAttentionPrefillD256(
        scale_granularity,
        qk_acc_dtype,
        pv_acc_dtype,
        is_persistent,
        mask_type,
    )

    # Initialize Stream
    current_stream = cutlass_torch.default_stream()

    if scale_softmax == 0.0:  # default to 1/sqrt(d)
        scale_softmax = 1.0 / math.sqrt(d)
    log2_e = math.log2(
        math.exp(1.0)
    )  # gpu uses exp2 for perf concerns, we need an extra factor 'log2_e' here

    scale_softmax = scale_q * scale_k * scale_softmax
    scale_softmax_log2 = scale_softmax * log2_e
    scale_output = scale_v * inv_scale_o
    problem_size = (b, s_q, s_k, h_q, h_k, d)
    compiled_fmha = cute.compile(
        fmha,
        q_tensor.iterator,
        k_tensor.iterator,
        v_tensor.iterator,
        o_tensor.iterator,
        scale_k_tensor.iterator,
        scale_v_tensor.iterator,
        problem_size,
        scale_softmax_log2,
        scale_output,
        window_size_left if window_size_left is None else Int32(window_size_left),
        window_size_right if window_size_right is None else Int32(window_size_right),
        current_stream,
        options=f"--opt-level 2",
    )

    def run_torch_fmha(
        q, k, v, scale_k, scale_v, scale_softmax=1.0, scale_output=1.0, is_causal=False
    ):
        h_q = q.shape[1]
        h_k = k.shape[1]
        if not h_q == h_k:
            repeat_factor = h_q // h_k
            k = k.repeat_interleave(repeat_factor, dim=1)
            v = v.repeat_interleave(repeat_factor, dim=1)
            scale_k = scale_k.repeat_interleave(repeat_factor, dim=1)
            scale_v = scale_v.repeat_interleave(repeat_factor, dim=1)
        scale_k = (
            scale_k.unsqueeze(-1)
            .repeat(1, 1, 1, 1, k.shape[3] // scale_k.shape[3])
            .reshape(k.shape)
        )
        scale_v = (
            scale_v.unsqueeze(-1)
            .repeat(1, 1, 1, 1, v.shape[3] // scale_v.shape[3])
            .reshape(v.shape)
        )
        batch = q.shape[0]
        ref_list = []
        for batch_idx in range(batch):
            q_i = q[batch_idx]
            k_i = k[batch_idx]
            v_i = v[batch_idx]
            scale_k_i = scale_k[batch_idx]
            scale_v_i = scale_v[batch_idx]
            s_i = torch.einsum("hqd,hkd->hqk", q_i, k_i * scale_k_i) * scale_softmax
            s_q = q_i.shape[1]
            s_k = k_i.shape[1]
            if is_causal:
                q_coords = torch.arange(0, s_q).view(-1, 1)
                k_coords = torch.arange(0, s_k).view(1, -1)
                _mask = k_coords > q_coords + s_k - s_q
                s_i = s_i.masked_fill(_mask, -torch.inf)
            p_i = s_i.softmax(dim=-1)
            ref_i = torch.einsum("hqk,hkd->hqd", p_i, v_i * scale_v_i) * scale_output
            ref_list.append(ref_i)
        ref = torch.stack(ref_list)
        return ref

    if not skip_ref_check:
        # Execute kernel once for reference checking
        compiled_fmha(
            q_tensor.iterator,
            k_tensor.iterator,
            v_tensor.iterator,
            o_tensor.iterator,
            scale_k_tensor.iterator,
            scale_v_tensor.iterator,
            problem_size,
            scale_softmax_log2,
            scale_output,
            window_size_left if window_size_left is None else Int32(window_size_left),
            (
                window_size_right
                if window_size_right is None
                else Int32(window_size_right)
            ),
            current_stream,
        )
        print("Verifying results...")
        o_ref = run_torch_fmha(
            q_ref,
            k_ref,
            v_ref,
            scale_k_ref,
            scale_v_ref,
            scale_softmax,
            scale_output,
            is_causal,
        )

        # convert o back to f32 for comparison
        o_fp32, o_fp32_torch = cutlass_torch.cute_tensor_like(
            torch.empty(*o_torch.shape, dtype=torch.float32),
            Float32,
            is_dynamic_layout=True,
            assumed_align=16,
        )
        cute.testing.convert(o_tensor, o_fp32)
        o_result = o_fp32_torch.cpu()
        torch.testing.assert_close(o_ref, o_result, atol=tolerance, rtol=1e-05)

        print("Results verified successfully!")


if __name__ == "__main__":

    def parse_comma_separated_ints(s: str):
        try:
            return tuple(int(x.strip()) for x in s.split(","))
        except ValueError:
            raise argparse.ArgumentTypeError(
                "Invalid format. Expected comma-separated integers."
            )

    parser = argparse.ArgumentParser(description="Example of FMHA on Blackwell.")

    parser.add_argument(
        "--q_dtype",
        type=cutlass.dtype,
        default=cutlass.BFloat16,
        help="Input data type",
    )

    parser.add_argument(
        "--kv_dtype",
        type=cutlass.dtype,
        default=cutlass.Int8,
        help="Input data type",
    )

    parser.add_argument(
        "--o_dtype",
        type=cutlass.dtype,
        default=cutlass.BFloat16,
        help="Output data type",
    )

    parser.add_argument(
        "--scale_dtype",
        type=cutlass.dtype,
        default=cutlass.BFloat16,
        help="Scale data type",
    )

    parser.add_argument(
        "--scale_granularity",
        type=int,
        default=256,
        help="Scale granularity",
    )

    parser.add_argument(
        "--qk_acc_dtype",
        type=cutlass.dtype,
        default=Float32,
        help="QK accumulator data type",
    )

    parser.add_argument(
        "--pv_acc_dtype",
        type=cutlass.dtype,
        default=Float32,
        help="PV accumulator data type",
    )

    parser.add_argument(
        "--is_persistent",
        action="store_true",
        help="Is persistent",
    )

    parser.add_argument(
        "--is_causal",
        action="store_true",
        help="Whether to use casual mask",
    )

    parser.add_argument(
        "--q_shape",
        type=parse_comma_separated_ints,
        default=(1, 8, 256, 256),
        help="Shape of Q (B, H, S_q, D)",
    )

    parser.add_argument(
        "--k_shape",
        type=parse_comma_separated_ints,
        default=(1, 8, 256, 256),
        help="Shape of K (B, H_k, S_k, D)",
    )

    parser.add_argument(
        "--scale_q",
        type=float,
        default=1.0,
        help="Scaling factors to dequantize Q",
    )

    parser.add_argument(
        "--scale_k",
        type=float,
        default=1.0,
        help="Scaling factors to dequantize K",
    )

    parser.add_argument(
        "--scale_v",
        type=float,
        default=1.0,
        help="Scaling factors to dequantize V",
    )

    parser.add_argument(
        "--inv_scale_o",
        type=float,
        default=1.0,
        help="Scaling factor to quantize O",
    )

    parser.add_argument(
        "--scale_softmax",
        type=float,
        default=0.0,
        help="Scaling factor to scale S (i.e. Q*K); if zero, defaults to 1/sqrt(D)",
    )

    parser.add_argument(
        "--tolerance", type=float, default=1e-01, help="Tolerance for validation"
    )

    parser.add_argument(
        "--warmup_iterations",
        type=int,
        default=0,
        help="Number of iterations for warmup",
    )

    parser.add_argument(
        "--iterations",
        type=int,
        default=1,
        help="Number of iterations after warmup",
    )

    parser.add_argument(
        "--skip_ref_check",
        action="store_true",
        help="Skip reference check",
    )

    parser.add_argument(
        "--use_cold_l2",
        action="store_true",
        default=False,
        help="Use circular buffer tensor sets to ensure L2 cold cache",
    )

    args = parser.parse_args()

    if len(args.q_shape) != 4:
        parser.error("--q_shape must contain exactly 4 values")

    if len(args.k_shape) != 4:
        parser.error("--k_shape must contain exactly 4 values")

    if not torch.cuda.is_available():
        raise RuntimeError("GPU is required to run this example!")

    run(
        args.q_shape,
        args.k_shape,
        args.q_dtype,
        args.kv_dtype,
        args.o_dtype,
        args.scale_dtype,
        args.scale_granularity,
        args.qk_acc_dtype,
        args.pv_acc_dtype,
        args.is_persistent,
        args.is_causal,
        args.scale_q,
        args.scale_k,
        args.scale_v,
        args.inv_scale_o,
        args.scale_softmax,
        args.tolerance,
        args.warmup_iterations,
        args.iterations,
        args.skip_ref_check,
        args.use_cold_l2,
    )

    print("PASS")
