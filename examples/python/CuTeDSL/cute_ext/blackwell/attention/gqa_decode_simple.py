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
from typing import Tuple, Type
from functools import partial
import cuda.bindings.driver as cuda
import torch
import torch.nn.functional as F

import cutlass
from cutlass import cute
from cutlass import testing
import cutlass.torch as cutlass_torch
import cutlass.pipeline as pipeline
from cutlass.cute import experimental as cute_ext
from cutlass.cute.runtime import from_dlpack
import cutlass.utils.blackwell_helpers as sm100_utils
from cutlass.cute.nvgpu import tcgen05, OperandMajorMode
from cutlass.cute.typing import Int32, Float32

LOG2_E = math.log2(math.e)

exp2 = partial(cute.math.exp2, fastmath=True)
warp_fmax = partial(cute.arch.warp_redux_sync, kind="fmax", nan=True)
smem_fmax = partial(cute.arch.atomic_fmax, sem="relaxed", scope="cta")

torch_cutlass_dtype_map = {
    torch.float16: cutlass.Float16,
    torch.bfloat16: cutlass.BFloat16,
    torch.float32: cutlass.Float32,
}

warp_threads = 32
warpgroup_warps = 4
warpgroup_threads = warpgroup_warps * warp_threads


class GroupedQueryAttentionDecode:
    def __init__(self, g_tile, seq_tile, head_dim, dtype, decode_grid):
        self.g_tile = g_tile
        self.seq_tile = seq_tile
        self.head_dim = head_dim
        self.dtype = dtype
        self.acc_dtype = cutlass.Float32
        self.decode_grid = decode_grid

        assert head_dim > 0 and head_dim % 64 == 0
        assert g_tile in (8, 16, 32)
        assert seq_tile == 128, "Only support seq_tile = 128 for now"

    def can_implement(self, problem_shape):
        _b, h_q, h_k, _s_k, d = problem_shape
        if d != self.head_dim:
            raise ValueError(f"KV head dim ({d}) mismatch with {self.head_dim=}")
        if h_q % h_k != 0:
            raise ValueError(
                f"Number of Q heads ({h_q}) must be divisible by KV heads ({h_k})"
            )
        if d % 64 != 0:
            raise ValueError(f"KV head dim ({d}) must be divisible by 64")

    @staticmethod
    def make_gmem_view(gmem_tensor: cute.Tensor, shape: tuple, order: tuple):
        return cute.make_tensor(
            gmem_tensor.iterator,
            cute.make_ordered_layout(shape=shape, order=order),
        )

    @cute.experimental.jit
    def __call__(
        self,
        # problem_shape: (b, h_q, h_k, s_k, d)
        problem_shape: Tuple[Int32, Int32, Int32, Int32, Int32],
        gmem_Q: cute.Tensor,  # Expected shape: (b, h_q, d)
        gmem_K: cute.Tensor,  # Expected shape: (b, h_k, s_k, d)
        gmem_V: cute.Tensor,  # Expected shape: (b, h_k, s_k, d)
        gmem_O_part: cute.Tensor,  # Expected shape: (b, h_q, kv_splits, d)
        gmem_M_part: cute.Tensor,  # Expected shape: (b, h_q, kv_splits)
        gmem_L_part: cute.Tensor,  # Expected shape: (b, h_q, kv_splits)
        gmem_O_final: cute.Tensor,  # Expected shape: (b, h_q, d)
        scale_s_log2_e: Float32,
        stream: cuda.CUstream,
    ):
        block = (12 * warp_threads, 1, 1)
        cluster = (1, 1, 1)
        smem = cute.Int64(cutlass.memory.get_smem_capacity_in_bytes("sm_100"))

        d = self.head_dim
        b, h_q, h_k, s_k, _d = problem_shape
        g = h_q // h_k  # head_group_size
        l_blks = b * h_k
        kv_splits = self.decode_grid[0]
        g_tile = self.g_tile

        # Reinterpret public tensors as GEMM views with M/N/K modes leading.
        # KQ phase: K^T is A (M = seq_len, K = head_dim),
        # Q is B (N = head_group_size, K = head_dim).
        gmem_K_kq = self.make_gmem_view(gmem_K, (s_k, d, l_blks), (1, 0, 2))
        gmem_Q_kq = self.make_gmem_view(gmem_Q, (g, d, l_blks), (1, 0, 2))
        # VP phase: V is A (M = head_dim), P is B (N = head_group_size).
        gmem_V_vp = self.make_gmem_view(gmem_V, (d, s_k, l_blks), (0, 1, 2))
        # One O_part per CTA (per kv_split), not per seq_tile
        gmem_O_part_decode = self.make_gmem_view(
            gmem_O_part, (d, g, kv_splits, l_blks), (0, 2, 1, 3)
        )
        # Online softmax outputs: one M_part (colmax) and L_part (colsum) per CTA
        gmem_M_part_decode = self.make_gmem_view(
            gmem_M_part, (kv_splits, g, l_blks), (0, 1, 2)
        )
        gmem_L_part_decode = self.make_gmem_view(
            gmem_L_part, (kv_splits, g, l_blks), (0, 1, 2)
        )

        # MMA tiling
        # For KQ MMA, K^T is operand A (M = seq_len = 128, K = head_dim),
        # Q is operand B (N = head_group_size, K = head_dim)
        # For VP MMA, V is operand A (M = head_dim, K = seq_tile = 128),
        # P is operand B (N = head_group_size, K = seq_tile = 128)
        # Notes:
        # 1. To make accumulator use the canonical TMEM layout for softmax
        #    and VP correction, we need to set mma_tile_m = 128 even when
        #    head_dim == 64.
        # 2. To reuse the same buffer for K and V, set mma_tile_k = 64 even
        #    though KQ and VP have different K-dim sizes (head_dim vs seq_tile).
        mma_tile_m = 128
        mma_tile_n = g_tile
        mma_tile_k = 64
        self.mma_tile_mnk = (mma_tile_m, mma_tile_n, mma_tile_k)

        # Stage counts
        self.Q_stages = cute.ceil_div(d, mma_tile_k)
        self.P_stages = 4
        self.S_stages = 4
        self.O_stages = 1
        # Reserve SMEM for all non-KV SMEM buffers first, then use the remaining capacity
        # for as many shared KV stages as possible.
        mbarrier_bits = 64
        pipe_stage_bits = mbarrier_bits * 2  # producer + consumer bookkeeping
        mk_stage_bits = mma_tile_m * mma_tile_k * self.dtype.width
        nk_stage_bits = mma_tile_n * mma_tile_k * self.dtype.width
        hs_stage_bits = g_tile * self.seq_tile * self.dtype.width
        smem_alloc_bits = 0
        smem_alloc_bits += g_tile * self.acc_dtype.width  # smem_M
        smem_alloc_bits += 4 * g_tile * self.acc_dtype.width  # smem_L_ps
        smem_alloc_bits += (
            self.Q_stages * nk_stage_bits + pipe_stage_bits
        )  # smem_Q + q_load_mbar reserve
        smem_alloc_bits += self.P_stages * (
            hs_stage_bits + pipe_stage_bits
        )  # smem_P + P_pipe
        smem_alloc_bits += self.S_stages * pipe_stage_bits  # S_pipe
        smem_alloc_bits += self.O_stages * pipe_stage_bits  # O_pipe
        smem_capacity_bits = cutlass.memory.get_smem_capacity_in_bytes("sm_100") * 8
        self.KV_stages = (smem_capacity_bits - smem_alloc_bits) // (
            mk_stage_bits + pipe_stage_bits
        )

        # KQ MMA tile
        # Contracting dimension head_dim, which is the fastest changing dimension
        # in both the K and Q tensors, so they are both K-major mode
        kq_a_leading_mode = OperandMajorMode.K
        kq_b_leading_mode = OperandMajorMode.K
        tiled_mma_kq = sm100_utils.make_trivial_tiled_mma(
            self.dtype,
            kq_a_leading_mode,
            kq_b_leading_mode,
            self.acc_dtype,
            tcgen05.CtaGroup.ONE,
            self.mma_tile_mnk[:2],
        )

        # VP MMA tiling
        # Logical P blocks have shape (seq_tile, g_tile) and are staged in
        # SMEM as VP-B tiles. Thus the VP contracting dimension is seq_tile.
        # It is neither the fastest-changing dimension in V nor in staged P,
        # so both operands use MN-major mode.
        vp_a_leading_mode = OperandMajorMode.MN
        vp_b_leading_mode = OperandMajorMode.MN
        tiled_mma_vp = sm100_utils.make_trivial_tiled_mma(
            self.dtype,
            vp_a_leading_mode,
            vp_b_leading_mode,
            self.acc_dtype,
            tcgen05.CtaGroup.ONE,
            self.mma_tile_mnk[:2],
        )

        smem_Q_layout_staged = sm100_utils.make_smem_layout_b(
            tiled_mma_kq, self.mma_tile_mnk, self.dtype, self.Q_stages
        )
        smem_K_layout_staged = sm100_utils.make_smem_layout_a(
            tiled_mma_kq, self.mma_tile_mnk, self.dtype, self.KV_stages
        )
        smem_V_layout_staged = sm100_utils.make_smem_layout_a(
            tiled_mma_vp, self.mma_tile_mnk, self.dtype, self.KV_stages
        )
        smem_O_layout_atom = tcgen05.make_smem_layout_atom(
            tcgen05.mma.SmemLayoutAtomKind.MN_SW128, gmem_O_part.element_type
        )

        O_shape = (max(self.head_dim, mma_tile_m), g_tile)
        smem_O_layout = cute.tile_to_shape(smem_O_layout_atom, O_shape, order=(1, 0))
        smem_O_layout = cute.flat_divide(smem_O_layout, (mma_tile_m, g_tile))

        self.decode_kernel(
            problem_shape,
            gmem_Q_kq,
            gmem_K_kq,
            gmem_V_vp,
            gmem_O_part_decode,
            gmem_M_part_decode,
            gmem_L_part_decode,
            scale_s_log2_e,
            tiled_mma_kq,
            tiled_mma_vp,
            smem_Q_layout_staged,
            smem_K_layout_staged,
            smem_V_layout_staged,
            smem_O_layout,
        ).launch(
            grid=self.decode_grid,
            block=block,
            cluster=cluster,
            smem=smem,
            stream=stream,
        )

        # O_part, M_part, L_part have different logical shapes in reduction kernel
        # than in decode kernel, make new tensors for reduction kernel
        gmem_O_part_reduction = self.make_gmem_view(
            gmem_O_part, (d, kv_splits, h_q, b), (0, 1, 2, 3)
        )
        gmem_M_part_reduction = self.make_gmem_view(
            gmem_M_part, (kv_splits, h_q, b), (0, 1, 2)
        )
        gmem_L_part_reduction = self.make_gmem_view(
            gmem_L_part, (kv_splits, h_q, b), (0, 1, 2)
        )
        gmem_O_final_reduction = self.make_gmem_view(
            gmem_O_final, (d, h_q, b), (0, 1, 2)
        )

        d_per_blk = 128
        d_blks = cute.ceil_div(d, d_per_blk)
        s_blks = cute.ceil_div(s_k, self.seq_tile)
        # Oversplit decode grids can produce empty split CTAs that publish neutral M/L partials
        # (M=-inf, L=0) without writing O_part. Skip those entries entirely so reduction does
        # not read undefined O_part or hit -inf/-inf correction cases
        reduction_kv_splits = min(kv_splits, s_blks)
        self.reduction_kernel(
            gmem_O_part_reduction,
            gmem_M_part_reduction,
            gmem_L_part_reduction,
            gmem_O_final_reduction,
            reduction_kv_splits,
        ).launch(
            grid=(d_blks, h_q, b),
            block=(d_per_blk, 1, 1),
            cluster=(1, 1, 1),
            stream=stream,
        )

    @cute.experimental.kernel
    def decode_kernel(
        self,
        problem_shape: Tuple[Int32, Int32, Int32, Int32, Int32],
        gmem_Q: cute.Tensor,
        gmem_K: cute.Tensor,
        gmem_V: cute.Tensor,
        gmem_O_part: cute.Tensor,
        gmem_M_part: cute.Tensor,
        gmem_L_part: cute.Tensor,
        scale_s_log2_e: Float32,
        tiled_mma_kq: cute.TiledMma,
        tiled_mma_vp: cute.TiledMma,
        smem_Q_layout_staged: cute.ComposedLayout,
        smem_K_layout_staged: cute.ComposedLayout,
        smem_V_layout_staged: cute.ComposedLayout,
        smem_O_layout: cute.ComposedLayout,
    ):
        # Fused kernel with in-kernel online softmax:
        # KQ MMA -> softmax -> VP MMA -> correction -> split partials
        # 12 warps (384 threads):
        #   warps 0-3:  correction + O_part staging (online softmax accumulation)
        #   warps 4-7:  softmax (consumer of KQ, producer of P for VP)
        #   warp 8:     TMA load K + Q
        #   warp 9:     TMA load V (runs in parallel with KQ phase)
        #   warp 10:    KQ MMA
        #   warp 11:    VP MMA
        #
        # Each CTA processes multiple seq_tile blocks. Correction warps maintain
        # running O_acc, l_acc, m_prev across iterations, producing a single
        # merged O_part per CTA (indexed by kv_split).
        correction_warpgroup_id = 0
        softmax_warpgroup_id = 1
        mma_kq_warp_id = 2 * warpgroup_warps + 0
        mma_vp_warp_id = 2 * warpgroup_warps + 1
        tma_kv_warp_id = 2 * warpgroup_warps + 2
        tma_qo_warp_id = 2 * warpgroup_warps + 3
        reduction_warp_id = tma_kv_warp_id
        tid_x, _, _ = cute.arch.thread_idx()
        warp_idx = cute.arch.warp_idx()
        warp_idx = cute.arch.make_warp_uniform(warp_idx)
        lane_idx = cute.arch.lane_idx()
        warpgroup_idx = warp_idx // warpgroup_warps
        warpgroup_widx = warp_idx % warpgroup_warps

        d = self.head_dim
        _b, h_q, h_k, s_k, _d = problem_shape
        g = h_q // h_k  # head_group_size
        seq_tile = self.seq_tile
        g_tile = self.g_tile
        s_blks = cute.ceil_div(s_k, seq_tile)
        kv_splits = self.decode_grid[0]

        mma_tile_mnk = self.mma_tile_mnk
        (mma_tile_m, mma_tile_n, mma_tile_k) = self.mma_tile_mnk

        mma_kq_instr_shape_k = cute.size(tiled_mma_kq.shape_mnk, mode=[2])
        KQ_num_instr_k = mma_tile_k // mma_kq_instr_shape_k
        KQ_num_k_tiles = cute.ceil_div(d, mma_tile_k)

        mma_vp_instr_shape_k = cute.size(tiled_mma_vp.shape_mnk, mode=[2])
        VP_num_instr_k = mma_tile_k // mma_vp_instr_shape_k
        VP_num_m_tiles = cute.ceil_div(d, mma_tile_m)
        VP_num_k_tiles = cute.ceil_div(seq_tile, mma_tile_k)

        cta_s, cta_h, cta_l = cute.arch.block_idx()
        exit_early = cta_s >= s_blks

        # Helper functions for allocation
        def smem_alloc(dtype, layout, alignment=1024):
            return cute_ext.allocate(
                dtype, cutlass.AddressSpace.smem, layout, alignment=alignment
            )

        def tmem_alloc(dtype, layout, alignment=16):
            return cute_ext.allocate(
                dtype, cutlass.AddressSpace.tmem, layout, alignment=alignment
            )

        def rmem_alloc(dtype, layout, alignment=32):
            return cute_ext.allocate(
                dtype, cutlass.AddressSpace.rmem, layout, alignment=alignment
            )

        # SMEM buffer
        smem_Q = smem_alloc(self.dtype, smem_Q_layout_staged)

        # K and V use different layout views over the same physical allocation.
        # The shared KV pipeline determines when a stage can be reused for V after
        # KQ has finished consuming that K tile.
        smem_KV = smem_alloc(self.dtype, smem_K_layout_staged)
        smem_K = smem_KV
        smem_V_iter = cute.recast_ptr(
            smem_KV.iterator, smem_V_layout_staged.inner, dtype=self.dtype
        )
        smem_V = cute.make_tensor(smem_V_iter, smem_V_layout_staged.outer)

        # O_part store happens after the KV pipelines are drained, so the same physical
        # SMEM allocation used by the shared KV buffer can be safely reinterpreted as O.
        # smem_O_layout's row factorization depends on the output dtype.
        smem_O_iter = cute.recast_ptr(
            smem_KV.iterator, smem_O_layout.inner, dtype=gmem_O_part.element_type
        )
        smem_O_tma = cute.make_tensor(smem_O_iter, smem_O_layout.outer)

        # Softmax produces one P tile of size (mma_tile_m, mma_tile_n) for one
        # seq_tile block. In VP MMA, P will be used as operand B, so mma_tile_m
        # becomes the contraction dimension (K-dim), so put it in the 3rd position
        # in the tiler smem_P_tiler_nm.
        # VP MMA will later read the same storage through a different view that
        # splits the K dimension into mma_tile_k-sized subtiles.
        smem_P_tiler_nm = (None, mma_tile_n, mma_tile_m)
        smem_P_layout_staged = sm100_utils.make_smem_layout_b(
            tiled_mma_vp, smem_P_tiler_nm, self.dtype, self.P_stages
        )
        smem_P = smem_alloc(self.dtype, smem_P_layout_staged)
        # Reinterpret the staged P tile as an MMA-B view with an explicit
        # split-K dimension. This lets VP consume one mma_tile_k chunk of P per
        # V tile while reusing the exact same SMEM storage written by softmax.
        thrblk_mma_vp = tiled_mma_vp.get_slice(0)
        thrblk_mma_kq = tiled_mma_kq.get_slice(0)
        smem_P_nk_tile = thrblk_mma_vp.partition_shape_B((mma_tile_n, mma_tile_k))
        smem_P_nk = cute.local_tile(smem_P, smem_P_nk_tile, (0, 0, None, None))

        # TMEM S/P use the KQ accumulator layout:
        # ((128, g_tile), 1, 1, stages):((65536, 1), 0, 0, g_tile).
        # TMEM O keeps one persistent slot per VP M tile.
        tmem_S_layout = cute_ext.make_tmem_layout_acc(
            tiled_mma_kq, mma_tile_mnk, self.S_stages
        )
        tmem_P_layout = cute_ext.make_tmem_layout_acc(tiled_mma_kq, mma_tile_mnk, 1)
        tmem_O_layout = cute.make_layout(
            shape=((128, g_tile), 1, 1, VP_num_m_tiles, self.O_stages),
            stride=((65536, 1), 0, 0, g_tile, 0),
        )
        tmem_S = tmem_alloc(self.acc_dtype, tmem_S_layout)
        tmem_P = tmem_alloc(self.acc_dtype, tmem_P_layout)
        tmem_O = tmem_alloc(self.acc_dtype, tmem_O_layout)

        # Softmax and correction share TMEM <-> RMEM copy atoms because their
        # source blocks have the same shape (mma_tile_m = 128, g_tile). P and O
        # use separate RMEM -> SMEM atoms because P is QKV dtype while O_part is FP32.
        # When copied to RMEM, each thread holds one row of the S/P/O block:
        # ((g_tile, 1), 1, 1):(1, 0), 0, 0)
        # g_tile can only be 8, 16, 32, use appropriate repetition for better performance
        tmem_P_stage0 = tmem_P[(None, None), 0, 0, 0]
        tmem_copy_rep = tcgen05.Repetition(g_tile)
        ld_op = tcgen05.Ld32x32bOp(tmem_copy_rep, tcgen05.Pack.NONE)
        st_op = tcgen05.St32x32bOp(tmem_copy_rep, tcgen05.Unpack.NONE)
        copy_atom_t2r = cute.make_copy_atom(ld_op, self.acc_dtype)
        copy_atom_r2t = cute.make_copy_atom(st_op, self.acc_dtype)
        copy_atom_r2s_P = cute.make_copy_atom(cute.nvgpu.CopyUniversalOp(), self.dtype)
        copy_atom_r2s_O = cute.make_copy_atom(
            cute.nvgpu.CopyUniversalOp(), gmem_O_part.element_type
        )
        tiled_copy_t2r = tcgen05.make_tmem_copy(copy_atom_t2r, tmem_P_stage0)
        tiled_copy_r2t = tcgen05.make_tmem_copy(copy_atom_r2t, tmem_P_stage0)
        tiled_copy_r2s_P = cute.make_tiled_copy_D(copy_atom_r2s_P, tiled_copy_t2r)
        tiled_copy_r2s_O = cute.make_tiled_copy_D(copy_atom_r2s_O, tiled_copy_t2r)
        tid_x_in_group = tid_x % warpgroup_threads
        thr_t2r_copy = tiled_copy_t2r.get_slice(tid_x_in_group)
        thr_r2t_copy = tiled_copy_r2t.get_slice(tid_x_in_group)
        thr_r2s_copy_P = tiled_copy_r2s_P.get_slice(tid_x_in_group)
        thr_r2s_copy_O = tiled_copy_r2s_O.get_slice(tid_x_in_group)
        rmem_SPO_layout = thr_t2r_copy.partition_D(tmem_P_stage0).layout
        assert rmem_SPO_layout.shape[0] == (g_tile, 1)

        # SMEM buffers shared between softmax and correction warps
        # smem_M: holds column-max values (m_new) for softmax -> correction
        smem_M = smem_alloc(self.acc_dtype, rmem_SPO_layout)
        # smem_L_ps: holds per-warp final L partial sums for reduction writeback
        smem_L_ps_layout = cute.make_layout(
            shape=(4, g_tile),
            stride=(g_tile, 1),
        )
        smem_L_ps = smem_alloc(self.acc_dtype, smem_L_ps_layout)

        lane_store_max = lane_idx < g_tile
        prefetch_iters = 2
        prefetch_tiles = prefetch_iters * kv_splits

        softmax_nbar = pipeline.NamedBarrier(1, warpgroup_threads)
        m_producer_nbar = pipeline.NamedBarrier(2, 2 * warpgroup_threads)
        m_consumer_nbar = pipeline.NamedBarrier(3, 2 * warpgroup_threads)
        p_producer_nbar = pipeline.NamedBarrier(4, 2 * warpgroup_threads)
        p_consumer_nbar = pipeline.NamedBarrier(5, 2 * warpgroup_threads)
        m_final_nbar = pipeline.NamedBarrier(6, warpgroup_threads + warp_threads)
        l_final_nbar = pipeline.NamedBarrier(7, warpgroup_threads + warp_threads)
        # KQ and VP walk the same KV pipeline at different times. These two
        # barriers provide the hand-off points between their local consumer
        # states:
        # - mma_order_vp_nbar: VP has finished skipping/consuming the V-side
        #   tiles from older iterations, so KQ may now treat the shared state
        #   as pointing at the K-side tiles for its current iteration.
        # - mma_order_kq_nbar: KQ has finished the K-side tiles for the current
        #   iteration, so VP may now advance to and consume the matching V-side
        #   tiles from the same shared KV stream.
        mma_order_kq_nbar = pipeline.NamedBarrier(10, 2 * warp_threads)
        mma_order_vp_nbar = pipeline.NamedBarrier(11, 2 * warp_threads)
        # O_part lives in the KV SMEM region, which is not used anymore after
        # the KV pipelines are drained, so a single named barrier is enough.
        O_final_nbar = pipeline.NamedBarrier(9, 5 * warp_threads)

        # Pipelines
        # Typical pipeline patterns in this code:
        # producer_try_acquire -> producer_acquire_and_get_stage -> producer_commit_and_advance
        # consumer_try_wait -> consumer_wait_and_get_stage -> consumer_release_and_advance
        # producer_try_acquire and consumer_try_wait are non-blocking for better pipeline scheduling
        # This single mbarrier guards the whole staged Q preload, so it expects the
        # total bytes across all Q stages rather than per-stage bytes.
        q_load_mbar_ptr = smem_alloc(
            cutlass.Int64, cute.make_layout(1), alignment=8
        ).iterator
        if warp_idx == tma_qo_warp_id:
            nk_stage_bits = mma_tile_n * mma_tile_k * self.dtype.width
            q_tx_bytes = self.Q_stages * nk_stage_bits // 8
            with cute.arch.elect_one():
                cute.arch.mbarrier_init(q_load_mbar_ptr, 1)
                cute.arch.mbarrier_init_fence()
                cute.arch.mbarrier_arrive_and_expect_tx(q_load_mbar_ptr, q_tx_bytes)
        # Shared TMA KV -> MMA pipeline, consumed by both KQ MMA and VP MMA at different times,
        # requires explicit ordering via mma_order_kq_nbar and mma_order_vp_nbar
        KV_pipe = cute_ext.TMAToUMMAPipeline.create(
            num_stages=self.KV_stages,
            mma_operation_type=cute_ext.OperationTypeEnum.SM100_MMA_1SM_SS,
        )
        # KQ MMA -> softmax
        S_pipe = cute_ext.UMMAtoAsyncPipeline.create(
            num_stages=self.S_stages,
            mma_operation_type=cute_ext.OperationTypeEnum.SM100_MMA_1SM_SS,
            consumer=cute_ext.OperationTypeEnum.SM100_COPY_T2R,
            consumer_arv_count=warpgroup_threads,
        )
        # Softmax -> VP MMA
        P_pipe = cute_ext.AsyncToUMMAPipeline.create(
            num_stages=self.P_stages,
            producer=cute_ext.OperationTypeEnum.SM100_COPY_R2T,
            producer_arv_count=warpgroup_threads,
            mma_operation_type=cute_ext.OperationTypeEnum.SM100_MMA_1SM_SS,
        )
        # VP MMA -> correction
        O_pipe = cute_ext.UMMAtoAsyncPipeline.create(
            num_stages=self.O_stages,
            mma_operation_type=cute_ext.OperationTypeEnum.SM100_MMA_1SM_SS,
            consumer=cute_ext.OperationTypeEnum.SM100_COPY_T2R,
            consumer_arv_count=warpgroup_threads,
        )
        cute.arch.sync_threads()

        # Some split CTAs can start past the end of the sequence when
        # kv_splits > s_blks. Those CTAs must not enter the main pipeline
        # at all, otherwise they can block forever on handoff barriers that
        # no valid producer will ever signal. Instead, publish the neutral
        # M/L state for this split and let the reduction path retire it.
        if exit_early:
            if warpgroup_idx == softmax_warpgroup_id:
                if warpgroup_widx == 0 and lane_store_max:
                    smem_M[lane_idx] = -Float32.inf
                m_final_nbar.arrive()
            elif warpgroup_idx == correction_warpgroup_id:
                if lane_idx < g_tile:
                    smem_L_ps[warpgroup_widx, lane_idx] = Float32(0.0)
                l_final_nbar.arrive()

        # TMA load Q and TMA store O
        elif warp_idx == tma_qo_warp_id:
            # gmem_Q_local.shape = (Q_tiler, KQ_num_k_tiles)
            Q_tiler = (mma_tile_n, mma_tile_k)
            Q_coord = (cta_h, None, cta_l)
            gmem_Q_local = cute.local_tile(gmem_Q, Q_tiler, Q_coord)
            tBgQ = thrblk_mma_kq.partition_B(gmem_Q_local)
            for k in cutlass.range_constexpr(KQ_num_k_tiles):
                gQ_k = tBgQ[None, None, None, k]
                smem_Q_q_idx = smem_Q[None, None, None, k]
                # update_expect_tx=False: do not automatically update the mbarrier's
                # transaction bytes since they are already initialized
                cute_ext.tma_load(
                    gQ_k,
                    smem_Q_q_idx,
                    q_load_mbar_ptr.value,
                    update_expect_tx=False,
                )

            # gmem_O_part_div.shape =
            # (O_part_tiler, (VP_num_m_tiles, h_blks, kv_splits, l_blks))
            O_part_tiler = (mma_tile_m, mma_tile_n)
            gmem_O_part_div = cute.zipped_divide(gmem_O_part, O_part_tiler)
            O_final_nbar.arrive_and_wait()
            for dm in cutlass.range_constexpr(VP_num_m_tiles):
                O_block_coord = (dm, cta_h, cta_s, cta_l)
                gmem_O_part_local = gmem_O_part_div[(None, None), O_block_coord]
                cute_ext.tma_store(
                    smem_O_tma[None, None, dm, 0],
                    gmem_O_part_local,
                )
            cute.arch.cp_async_bulk_commit_group()
            cute.arch.cp_async_bulk_wait_group(0, read=True)

        # TMA load KV
        elif warp_idx == tma_kv_warp_id:
            # gmem_K_div.shape = (KV_tiler, (s_blks, KQ_num_k_tiles, l_blks))
            # gmem_V_local.shape = ((d, seq_tile), l_blks), built from the real
            # sequence length so the last block can be partial without host-side padding.
            KV_tiler = (mma_tile_m, mma_tile_k)
            gmem_K_div = cute.zipped_divide(gmem_K, KV_tiler)
            kv_token = cutlass.Boolean(True)  # Producer always acquires first
            for s in cutlass.range(cta_s, prefetch_tiles + s_blks, kv_splits):
                if s < s_blks:
                    # gmem_K_s.shape = (KV_tiler, KQ_num_k_tiles)
                    gmem_K_s = gmem_K_div[(None, None), (s, None, cta_l)]
                    tAgK = thrblk_mma_kq.partition_A(gmem_K_s)
                    for k in cutlass.range_constexpr(KQ_num_k_tiles):
                        gK_k = tAgK[None, None, None, k]
                        k_stage_token, k_idx = KV_pipe.producer_acquire_and_get_stage(
                            token=kv_token
                        )
                        k_mbar = cute_ext.get_mbarrier(k_stage_token)
                        smem_K_kidx = smem_K[None, None, None, k_idx]
                        cute_ext.tma_load(gK_k, smem_K_kidx, k_mbar)
                        KV_pipe.producer_commit_and_advance()
                        kv_token = KV_pipe.producer_try_acquire()

                if s >= prefetch_tiles:
                    # Take one logical seq_tile-sized view from the true V tensor,
                    # then divide that local block into VP MMA tiles. The last block
                    # may be smaller than seq_tile in GMEM; CuTe keeps that shape.
                    v_block_coord = (0, s - prefetch_tiles, cta_l)
                    gmem_V_local = cute.local_tile(gmem_V, (d, seq_tile), v_block_coord)
                    gmem_V_s = cute.zipped_divide(gmem_V_local, KV_tiler)
                    for sk in cutlass.range_constexpr(VP_num_k_tiles):
                        gmem_V_sk = gmem_V_s[(None, None), (None, sk)]
                        tAgV = thrblk_mma_vp.partition_A(gmem_V_sk)
                        for dm in cutlass.range_constexpr(VP_num_m_tiles):
                            gV_k = tAgV[None, None, None, dm]
                            v_stage_token, v_idx = (
                                KV_pipe.producer_acquire_and_get_stage(token=kv_token)
                            )
                            v_mbar = cute_ext.get_mbarrier(v_stage_token)
                            smem_V_vidx = smem_V[None, None, None, v_idx]
                            cute_ext.tma_load(gV_k, smem_V_vidx, v_mbar)
                            KV_pipe.producer_commit_and_advance()
                            kv_token = KV_pipe.producer_try_acquire()

        # KQ MMA (waits for K and Q from TMA)
        elif warp_idx == mma_kq_warp_id:
            vp_tiles_per_iter = VP_num_m_tiles * VP_num_k_tiles
            mma_atom = cute.make_mma_atom(tiled_mma_kq.op)

            # Wait until all Q blocks are loaded
            cute.arch.mbarrier_wait(q_load_mbar_ptr, phase=0)

            for s in cutlass.range(cta_s, s_blks, kv_splits):
                s_token = S_pipe.producer_try_acquire()
                mma_atom.set(tcgen05.Field.ACCUMULATE, False)

                # When it comes to the prefetch_iters+1 and later iterations, the
                # pipeline loads both K and V tiles. KQ must manually skip over the
                # V tiles already consumed by VP, so its local consumer state points
                # at the next vp_tiles_per_iter tiles for the current sequence iteration.
                if s >= cta_s + (prefetch_iters + 1) * kv_splits:
                    for _ in cutlass.range_constexpr(vp_tiles_per_iter):
                        KV_pipe.consumer_state = KV_pipe.increment_state(
                            KV_pipe.consumer_state
                        )
                mma_order_vp_nbar.arrive_and_wait()
                k_token = KV_pipe.consumer_try_wait()

                _s_stage_token, kq_idx = S_pipe.producer_acquire_and_get_stage(
                    token=s_token
                )
                tmem_S_sliced = tmem_S[None, None, None, kq_idx]
                for k_tidx in cutlass.range_constexpr(KQ_num_k_tiles):
                    _k_stage_token, K_sidx = KV_pipe.consumer_wait_and_get_stage(
                        token=k_token
                    )
                    for instr_idx in cutlass.range_constexpr(KQ_num_instr_k):
                        K_slice = smem_K[None, None, instr_idx, K_sidx]
                        Q_slice = smem_Q[None, None, instr_idx, k_tidx]
                        cute_ext.dot(
                            mma_atom,
                            K_slice,
                            Q_slice,
                            tmem_S_sliced,
                        )
                        mma_atom.set(tcgen05.Field.ACCUMULATE, True)
                    if k_tidx == KQ_num_k_tiles - 1:
                        mma_order_kq_nbar.arrive()
                    KV_pipe.consumer_release_and_advance()
                    if k_tidx != KQ_num_k_tiles - 1:
                        k_token = KV_pipe.consumer_try_wait()
                S_pipe.producer_commit_and_advance()

            # Drain the KQ-only tail of the warmup window. VP still has
            # prefetch_iters iterations of V-side latency behind it, so KQ waits
            # for VP to catch up before retiring the remaining K-only tiles.
            for _ in cutlass.range_constexpr(prefetch_iters):
                mma_order_vp_nbar.arrive_and_wait()
                mma_order_kq_nbar.arrive()

        # VP MMA (waits for V from TMA + P from softmax)
        elif warp_idx == mma_vp_warp_id:
            kq_tiles_per_iter = KQ_num_k_tiles
            mma_atom = cute.make_mma_atom(tiled_mma_vp.op)

            mma_order_vp_nbar.arrive()
            # VP tiles are loaded prefetch_iters later than KQ tiles. For each
            # prefetch iteration, VP advances past kq_tiles_per_iter KQ tiles
            # to match the KQ tiles loaded by KQ for the same prefetch iteration.
            for prefetch_iter in cutlass.range_constexpr(prefetch_iters):
                if cta_s + prefetch_iter * kv_splits < s_blks:
                    for _ in cutlass.range_constexpr(kq_tiles_per_iter):
                        KV_pipe.consumer_state = KV_pipe.increment_state(
                            KV_pipe.consumer_state
                        )
                mma_order_kq_nbar.arrive_and_wait()
                mma_order_vp_nbar.arrive()

            for s in cutlass.range(cta_s, s_blks, kv_splits):
                # KV is at s + prefetch_iters * kv_splits due to prefetch,
                # if it's not past s_blks, the pipeline loads both K and V tiles.
                # VP must manually skip over the K tiles already consumed by KQ,
                # so its local consumer state points at the next kq_tiles_per_iter
                # tiles for the current sequence iteration.
                if s + prefetch_iters * kv_splits < s_blks:
                    for _ in cutlass.range_constexpr(kq_tiles_per_iter):
                        KV_pipe.consumer_state = KV_pipe.increment_state(
                            KV_pipe.consumer_state
                        )
                mma_order_kq_nbar.arrive_and_wait()

                p_token = P_pipe.consumer_try_wait()
                v_token = KV_pipe.consumer_try_wait()
                o_token = O_pipe.producer_try_acquire()

                _p_stage_token, p_idx = P_pipe.consumer_wait_and_get_stage(
                    token=p_token
                )
                _o_stage_token, _idx = O_pipe.producer_acquire_and_get_stage(
                    token=o_token
                )
                for k_tidx in cutlass.range_constexpr(VP_num_k_tiles):
                    for dm in cutlass.range_constexpr(VP_num_m_tiles):
                        _v_stage_token, v_sidx = KV_pipe.consumer_wait_and_get_stage(
                            token=v_token
                        )
                        tmem_O_sliced = tmem_O[None, None, None, dm, 0]
                        # O now lives persistently in TMEM, so VP always accumulates
                        # onto the correction-updated state for this dm tile.
                        mma_atom.set(tcgen05.Field.ACCUMULATE, True)
                        for instr_idx in cutlass.range_constexpr(VP_num_instr_k):
                            V_slice = smem_V[None, None, instr_idx, v_sidx]
                            P_slice = smem_P_nk[None, None, instr_idx, k_tidx, p_idx]
                            cute_ext.dot(
                                mma_atom,
                                V_slice,
                                P_slice,
                                tmem_O_sliced,
                            )
                            mma_atom.set(cute.nvgpu.tcgen05.Field.ACCUMULATE, True)
                        if dm == VP_num_m_tiles - 1 and k_tidx == VP_num_k_tiles - 1:
                            mma_order_vp_nbar.arrive()
                        KV_pipe.consumer_release_and_advance()
                        if dm != VP_num_m_tiles - 1 or k_tidx != VP_num_k_tiles - 1:
                            v_token = KV_pipe.consumer_try_wait()
                P_pipe.consumer_release_and_advance()
                O_pipe.producer_commit_and_advance()
            O_pipe.producer_tail()

        # Softmax consumer of KQ, producer of P for VP.
        # Passes m_new through smem_M and full P tiles through TMEM.
        elif warpgroup_idx == softmax_warpgroup_id:
            rmem_S = rmem_alloc(self.acc_dtype, rmem_SPO_layout)
            rmem_P = rmem_alloc(self.dtype, rmem_SPO_layout)
            rmem_M = rmem_alloc(self.acc_dtype, rmem_SPO_layout)

            # Layout for creating a view of smem_P for RMEM->SMEM copy
            smem_P_view_layout = cute.make_layout(
                shape=(mma_tile_m, mma_tile_n),
                stride=(mma_tile_n, 1),
            )

            # Keep smem_M as the running colmax across sequence tiles.
            if warpgroup_widx == 0 and lane_store_max:
                smem_M[lane_idx] = -Float32.inf
            softmax_nbar.sync()

            for s in cutlass.range(cta_s, s_blks, kv_splits):
                s_token = S_pipe.consumer_try_wait()
                p_token = P_pipe.producer_try_acquire()

                _s_stage_token, acc_idx = S_pipe.consumer_wait_and_get_stage(
                    token=s_token
                )
                # tmem_S_sliced.shape = (128, g_tile)
                tmem_S_sliced = tmem_S[(None, None), 0, 0, acc_idx]

                # Copy S block from TMEM to RMEM
                cute_ext.partition_and_copy(thr_t2r_copy, tmem_S_sliced, rmem_S)
                cute.arch.fence_view_async_tmem_load()
                S_pipe.consumer_release_and_advance()

                # When the last sequence block is partial, rows past the true sequence
                # length must be masked out explicitly, or they will contribute bogus
                # probabilities during softmax
                valid_rows = s_k - s * seq_tile
                if tid_x_in_group >= valid_rows:
                    rmem_S.fill(-Float32.inf)

                # Wait for correction warps to finish reading the previous smem_M.
                m_consumer_nbar.arrive_and_wait()

                # smem_fmax reduces values across all threads that have the same ptr,
                # let i-th thread in each warp store the max value of i-th column.
                lane_max = -Float32.inf
                for j in cutlass.range_constexpr(g_tile):
                    rmem_M[j] = warp_fmax(rmem_S[j])
                    if j == lane_idx:
                        lane_max = rmem_M[j]
                lane_max *= scale_s_log2_e
                if lane_store_max:
                    smem_M_ptr = smem_M.iterator + smem_M.layout(lane_idx)
                    smem_fmax(smem_M_ptr, lane_max)

                if s + kv_splits >= s_blks:
                    m_final_nbar.arrive()
                m_producer_nbar.arrive_and_wait()
                # smem_M now holds the running m_new for this tile.
                cute.autovec_copy(smem_M, rmem_M)

                # Compute P = exp2(S*scale - M)
                rmem_S.store(exp2(rmem_S.load() * scale_s_log2_e - rmem_M.load()))

                # Publish the full P tile to TMEM for correction before signaling it.
                p_consumer_nbar.arrive_and_wait()
                cute_ext.partition_and_copy(thr_r2t_copy, rmem_S, tmem_P_stage0)
                cute.arch.fence_view_async_tmem_store()
                p_producer_nbar.arrive()

                # Convert P to self.dtype, copy to smem_P for VP MMA
                rmem_P.store(rmem_S.load().to(self.dtype))

                # Copy P from RMEM to the correct stage of smem_P for VP MMA
                _p_stage_token, p_sidx = P_pipe.producer_acquire_and_get_stage(
                    token=p_token
                )
                smem_P_staged = smem_P[None, None, None, p_sidx]
                smem_P_view = cute.make_tensor(
                    smem_P_staged.iterator, smem_P_view_layout
                )
                cute_ext.partition_and_copy(thr_r2s_copy_P, rmem_P, smem_P_view)
                # Fence SMEM writes so VP MMA warp can see them
                cute.arch.fence_view_async_shared()
                P_pipe.producer_commit_and_advance()

        # Correction warps: online softmax accumulation and split O_part staging
        # Receives m_new and P tiles from softmax via SMEM/TMEM barriers,
        # receives VP_new from VP MMA via O_pipe.
        # Maintains running O_acc, l_acc, m_prev across seq_tile iterations.
        elif warpgroup_idx == correction_warpgroup_id:
            rmem_P = rmem_alloc(self.acc_dtype, rmem_SPO_layout)
            rmem_O_acc = rmem_alloc(self.acc_dtype, rmem_SPO_layout)
            rmem_O_store = rmem_alloc(gmem_O_part.element_type, rmem_SPO_layout)

            # Per-head-group running state: m_prev (max), m_new, l_acc partial (sum), alpha
            rmem_m_old = rmem_alloc(self.acc_dtype, rmem_SPO_layout)
            rmem_m_new = rmem_alloc(self.acc_dtype, rmem_SPO_layout)
            rmem_l_acc = rmem_alloc(self.acc_dtype, rmem_SPO_layout)
            rmem_alpha = rmem_alloc(self.acc_dtype, rmem_SPO_layout)
            rmem_m_old.fill(-Float32.inf)
            rmem_l_acc.fill(Float32(0.0))

            # Initialize consumer barriers so softmax can proceed on first iteration.
            m_consumer_nbar.arrive()
            p_consumer_nbar.arrive()

            # Initialize persistent TMEM O. The zeroes written from rmem_O_acc
            # become the starting value stored in TMEM O; VP then accumulates on
            # top of that TMEM state from the first iteration onward.
            rmem_O_acc.fill(Float32(0.0))
            for dm in cutlass.range_constexpr(VP_num_m_tiles):
                tmem_O_sliced = tmem_O[(None, None), 0, 0, dm, 0]
                cute_ext.partition_and_copy(thr_r2t_copy, rmem_O_acc, tmem_O_sliced)
            cute.arch.fence_view_async_tmem_store()

            # Load first M/P, then start the online loop on the remaining tiles.
            m_producer_nbar.arrive_and_wait()
            cute.autovec_copy(smem_M, rmem_m_old)
            m_consumer_nbar.arrive()

            p_producer_nbar.arrive_and_wait()
            cute_ext.partition_and_copy(thr_t2r_copy, tmem_P_stage0, rmem_P)
            cute.arch.fence_view_async_tmem_load()
            p_consumer_nbar.arrive()

            rmem_l_acc.store(rmem_P.load())

            for s in cutlass.range(cta_s + kv_splits, s_blks, kv_splits):
                # Load next m_new and release smem_M immediately after reading it.
                m_producer_nbar.arrive_and_wait()
                cute.autovec_copy(smem_M, rmem_m_new)
                m_consumer_nbar.arrive()

                # Compute correction = exp2(m_prev - m_new)
                rmem_alpha.store(exp2(rmem_m_old.load() - rmem_m_new.load()))

                # Wait for VP MMA's previous iteration, then scale running O in TMEM.
                o_token = O_pipe.consumer_try_wait()
                _o_stage_token, _idx = O_pipe.consumer_wait_and_get_stage(token=o_token)
                for dm in cutlass.range_constexpr(VP_num_m_tiles):
                    tmem_O_sliced = tmem_O[(None, None), 0, 0, dm, 0]
                    cute_ext.partition_and_copy(thr_t2r_copy, tmem_O_sliced, rmem_O_acc)
                    cute.arch.fence_view_async_tmem_load()

                    rmem_O_acc.store(rmem_O_acc.load() * rmem_alpha.load())

                    cute_ext.partition_and_copy(thr_r2t_copy, rmem_O_acc, tmem_O_sliced)
                cute.arch.fence_view_async_tmem_store()
                O_pipe.consumer_release_and_advance()

                # Load next P and update running L.
                p_producer_nbar.arrive_and_wait()
                cute_ext.partition_and_copy(thr_t2r_copy, tmem_P_stage0, rmem_P)
                cute.arch.fence_view_async_tmem_load()
                p_consumer_nbar.arrive()

                rmem_l_acc.store(rmem_l_acc.load() * rmem_alpha.load() + rmem_P.load())
                rmem_m_old.store(rmem_m_new.load())

            # Reduce L within the correction warpgroup, then hand the final
            # M/L values to the dedicated reduction warp for the GMEM writeback.
            for gi in cutlass.range_constexpr(g_tile):
                rmem_l_acc[gi] = cute.arch.warp_reduction_sum(rmem_l_acc[gi])
                if lane_idx == 0:
                    smem_L_ps[warpgroup_widx, gi] = rmem_l_acc[gi]
            l_final_nbar.arrive()

            # Load the split-local numerator tiles from persistent TMEM O, then
            # hand the populated SMEM buffer to the QO TMA warp for O_part store.
            o_token = O_pipe.consumer_try_wait()
            _o_stage_token, _idx = O_pipe.consumer_wait_and_get_stage(token=o_token)
            for dm in cutlass.range_constexpr(VP_num_m_tiles):
                tmem_O_sliced = tmem_O[(None, None), 0, 0, dm, 0]
                cute_ext.partition_and_copy(thr_t2r_copy, tmem_O_sliced, rmem_O_acc)
                cute.arch.fence_view_async_tmem_load()

                rmem_O_store.store(rmem_O_acc.load().to(gmem_O_part.element_type))

                smem_O_tma_sliced = smem_O_tma[None, None, dm, 0]
                cute_ext.partition_and_copy(
                    thr_r2s_copy_O, rmem_O_store, smem_O_tma_sliced
                )
            O_pipe.consumer_release_and_advance()
            cute.arch.fence_proxy("async.shared", space="cta")
            O_final_nbar.arrive()

        if warp_idx == reduction_warp_id:
            m_final_nbar.arrive_and_wait()
            l_final_nbar.arrive_and_wait()

            ML_part_tiler = (1, g_tile)
            ML_part_coord = (cta_s, cta_h, cta_l)
            gmem_L_part_local = cute.local_tile(
                gmem_L_part, ML_part_tiler, ML_part_coord
            )
            gmem_M_part_local = cute.local_tile(
                gmem_M_part, ML_part_tiler, ML_part_coord
            )

            lane_store_max &= cta_h * g_tile + lane_idx < g
            if lane_store_max:
                l_sum01 = smem_L_ps[0, lane_idx] + smem_L_ps[1, lane_idx]
                l_sum23 = smem_L_ps[2, lane_idx] + smem_L_ps[3, lane_idx]
                gmem_M_part_local[0, lane_idx] = smem_M[lane_idx]
                gmem_L_part_local[0, lane_idx] = l_sum01 + l_sum23

    @cute.experimental.kernel
    def reduction_kernel(
        self,
        gmem_O_part: cute.Tensor,  # (d, kv_splits, h_q, b)
        gmem_M_part: cute.Tensor,  # (kv_splits, h_q, b), per-CTA running max
        gmem_L_part: cute.Tensor,  # (kv_splits, h_q, b), per-CTA running sum
        gmem_O_final: cute.Tensor,  # (d, h_q, b)
        reduction_kv_splits: Int32,
    ):
        d_blk_idx, coord_h, coord_b = cute.arch.block_idx()
        d_per_blk, _, _ = cute.arch.block_dim()
        d_idx, _, _ = cute.arch.thread_idx()
        coord_d = d_blk_idx * d_per_blk + d_idx

        if coord_d < gmem_O_final.shape[0]:
            m_max = -Float32.inf
            numer = Float32(0.0)
            denom = Float32(0.0)
            for split_idx in cutlass.range(reduction_kv_splits):
                split_m = gmem_M_part[split_idx, coord_h, coord_b]
                split_l = gmem_L_part[split_idx, coord_h, coord_b]
                if split_m > m_max:
                    correction = exp2(m_max - split_m)
                    numer *= correction
                    denom *= correction
                    m_max = split_m

                w_scale = exp2(split_m - m_max)
                numer += w_scale * gmem_O_part[coord_d, split_idx, coord_h, coord_b]
                denom += w_scale * split_l

            gmem_O_final[coord_d, coord_h, coord_b] = (numer / denom).to(
                gmem_O_final.element_type
            )


def run_gqa_decode(
    Q,
    K,
    V,
    O_part,
    M_part,
    L_part,
    O_final,
    seq_tile,
    g_tile,
    decode_grid,
    warmup_iter=0,
    bench_iter=0,
    use_cold_l2=False,
):
    b, h_q, d = Q.shape
    _b, h_k, s_k, _d = K.shape
    g = h_q // h_k
    assert h_q == h_k * g
    problem_shape = (b, h_q, h_k, s_k, d)

    dtype = torch_cutlass_dtype_map[Q.dtype]
    for name, workspace in (
        ("O_part", O_part),
        ("M_part", M_part),
        ("L_part", L_part),
    ):
        if workspace.dtype != torch.float32:
            raise TypeError(
                f"kernel reduction expects {name} dtype torch.float32, got {workspace.dtype}"
            )
    gmem_Q = from_dlpack(Q.detach(), assumed_align=16)
    gmem_K = from_dlpack(K.detach(), assumed_align=16)
    gmem_V = from_dlpack(V.detach(), assumed_align=16)
    gmem_O_part = from_dlpack(O_part.detach(), assumed_align=16)
    gmem_M_part = from_dlpack(M_part.detach(), assumed_align=16)
    gmem_L_part = from_dlpack(L_part.detach(), assumed_align=16)
    gmem_O_final = from_dlpack(O_final.detach(), assumed_align=16)
    scale_s_log2_e = 1.0 / math.sqrt(d) * LOG2_E

    gqa_decode = GroupedQueryAttentionDecode(
        g_tile=g_tile,
        seq_tile=seq_tile,
        head_dim=d,
        dtype=dtype,
        decode_grid=decode_grid,
    )
    gqa_decode.can_implement(problem_shape)

    current_stream = cutlass_torch.default_stream()
    compiled_gqa_decode = cute_ext.compile(
        gqa_decode,
        problem_shape,
        gmem_Q,
        gmem_K,
        gmem_V,
        gmem_O_part,
        gmem_M_part,
        gmem_L_part,
        gmem_O_final,
        scale_s_log2_e,
        current_stream,
    )
    compiled_gqa_decode.engine.initialize()

    # Run once on the caller-provided tensors for reference check
    compiled_gqa_decode(
        problem_shape,
        gmem_Q,
        gmem_K,
        gmem_V,
        gmem_O_part,
        gmem_M_part,
        gmem_L_part,
        gmem_O_final,
        scale_s_log2_e,
        current_stream,
    )

    if bench_iter <= 0:
        return 0.0, 0.0, 0.0

    # Create non-default stream for CUDA graph profiling
    torch_stream = torch.cuda.Stream()
    profile_stream = cuda.CUstream(torch_stream.cuda_stream)

    def workspace_generator():
        q_torch = torch.randn_like(Q)
        k_torch = torch.randn_like(K)
        v_torch = torch.randn_like(V)
        o_part_torch = torch.empty_like(O_part)
        m_part_torch = torch.empty_like(M_part)
        l_part_torch = torch.empty_like(L_part)
        o_final_torch = torch.empty_like(O_final)

        q_cute = from_dlpack(q_torch.detach(), assumed_align=16)
        k_cute = from_dlpack(k_torch.detach(), assumed_align=16)
        v_cute = from_dlpack(v_torch.detach(), assumed_align=16)
        o_part_cute = from_dlpack(o_part_torch.detach(), assumed_align=16)
        m_part_cute = from_dlpack(m_part_torch.detach(), assumed_align=16)
        l_part_cute = from_dlpack(l_part_torch.detach(), assumed_align=16)
        o_final_cute = from_dlpack(o_final_torch.detach(), assumed_align=16)

        jit_args = testing.JitArguments(
            problem_shape,
            q_cute,
            k_cute,
            v_cute,
            o_part_cute,
            m_part_cute,
            l_part_cute,
            o_final_cute,
            scale_s_log2_e,
            profile_stream,
        )
        return jit_args

    # Cycling through enough freshly allocated workspaces evicts the previous
    # iteration's K/V from L2, so every timed iteration reads them from DRAM.
    workspace_count = 1
    if use_cold_l2:
        one_workspace_bytes = sum(
            t.nbytes for t in (Q, K, V, O_part, M_part, L_part, O_final)
        )
        workspace_count = testing.get_workspace_count(
            one_workspace_bytes, warmup_iter, bench_iter
        )

    runtime_us = testing.benchmark(
        compiled_gqa_decode,
        warmup_iterations=warmup_iter,
        iterations=bench_iter,
        stream=profile_stream,
        workspace_generator=workspace_generator,
        workspace_count=workspace_count,
        use_cuda_graphs=True,
    )

    qkvo_bytes = Q.nbytes + K.nbytes + V.nbytes + O_final.nbytes
    terabytes_per_s = qkvo_bytes / runtime_us * 1e-6
    flops = b * h_q * 1 * s_k * d * 2 * 2
    teraflops_per_s = flops / runtime_us * 1e-6
    return runtime_us, terabytes_per_s, teraflops_per_s


def next_power_of_2(x):
    if x <= 0:
        raise ValueError(f"x must be positive, got {x}")
    return 1 << (x - 1).bit_length()


def compute_gqa_decode_grid(b, h_q, h_k, s_k):
    g = h_q // h_k
    # g_tile must <= 32 for smem_fmax to work
    # g_tile * sizeof(acc_dtype) must be a power of 32 for TMA,
    # for FP32 acc_dtype, g_tile must >= 8
    g_tile = max(next_power_of_2(g), 8)
    g_tile = min(g_tile, 32)
    h_blks = (g + g_tile - 1) // g_tile
    l_blks = b * h_k
    hardware_info = cutlass.utils.HardwareInfo()
    sm_count = hardware_info.get_device_multiprocessor_count()
    sm_count = 148 if sm_count <= 0 else sm_count
    kv_splits = sm_count // (h_blks * l_blks)  # 1 wave
    kv_splits = max(1, kv_splits)
    if sm_count == 148 and h_blks * l_blks == 32:
        kv_splits = 9  # 2 waves
    kv_splits = min(kv_splits, math.ceil(s_k / 512))  # At least 512 tokens per split
    return (kv_splits, g_tile, h_blks, l_blks)


def main():
    parser = argparse.ArgumentParser(description="cute_ext GQA flash decode demo.")
    parser.add_argument("--batch_size", "--b", type=int, default=1)
    parser.add_argument("--num_q_heads", "--h_q", type=int, default=64)
    parser.add_argument("--num_kv_heads", "--h_k", type=int, default=8)
    parser.add_argument("--seq_len", "--s", type=int, default=1024)
    parser.add_argument("--head_dim", "--d", type=int, default=128)
    parser.add_argument("--dtype", choices=["fp16", "bf16"], default="bf16")
    parser.add_argument("--atol", type=float, default=2e-2)
    parser.add_argument("--rtol", type=float, default=2e-2)
    parser.add_argument("--warmup_iter", type=int, default=3)
    parser.add_argument("--bench_iter", type=int, default=10)
    parser.add_argument("--use_cold_l2", action="store_true", help="Use cold L2")
    args = parser.parse_args()

    cuda.cuInit(0)
    torch.manual_seed(33550336)
    dtype = torch.float16 if args.dtype == "fp16" else torch.bfloat16

    b, hq, d = args.batch_size, args.num_q_heads, args.head_dim
    hkv, skv = args.num_kv_heads, args.seq_len
    g = hq // hkv
    seq_tile = 128
    kv_splits, g_tile, h_blks, l_blks = compute_gqa_decode_grid(b, hq, hkv, skv)

    print("Problem size and paramaters:")
    print(f"    batch size      = {b}")
    print(f"    num_q_heads     = {hq}")
    print(f"    num_kv_heads    = {hkv}")
    print(f"    head_group_size = {g}")
    print(f"    kv_seqlen       = {skv}")
    print(f"    head_dim        = {d}")
    print(f"    QKVO dtype      = {dtype}")
    print(f"    kv_splits       = {kv_splits}")
    print(f"    use cold L2     = {args.use_cold_l2}")

    Q = torch.randn((b, hq, d), device="cuda", dtype=dtype)
    K = torch.randn((b, hkv, skv, d), device="cuda", dtype=dtype)
    V = torch.randn((b, hkv, skv, d), device="cuda", dtype=dtype)

    Q_sdpa = Q.unsqueeze(2)
    O_torch = F.scaled_dot_product_attention(Q_sdpa, K, V, enable_gqa=True)
    O_torch = O_torch.squeeze(2)
    print("Reference PyTorch scaled_dot_product_attention() completed.")

    O_part = torch.empty((b, hq, kv_splits, d), device=Q.device, dtype=torch.float32)
    O_final = torch.empty((b, hq, d), device=Q.device, dtype=Q.dtype)
    M_part = torch.empty((b, hq, kv_splits), device="cuda", dtype=torch.float32)
    L_part = torch.empty((b, hq, kv_splits), device="cuda", dtype=torch.float32)
    runtime_us, terabytes_per_s, teraflops_per_s = run_gqa_decode(
        Q,
        K,
        V,
        O_part,
        M_part,
        L_part,
        O_final,
        seq_tile,
        g_tile,
        (kv_splits, h_blks, l_blks),
        args.warmup_iter,
        args.bench_iter,
        args.use_cold_l2,
    )

    torch.testing.assert_close(O_final, O_torch, atol=args.atol, rtol=args.rtol)
    diff_max_abs = (O_final - O_torch).abs().max().item()
    print(
        f"[PASS] GQA flash decode matched PyTorch SDPA, diff_max_abs={diff_max_abs:.6e}.\n"
        f"{runtime_us:.3f} us\n"
        f"{terabytes_per_s:.3f} TB/s\n"
        f"{teraflops_per_s:.3f} TFLOPS/s"
    )


# Perf-harness dtype plumbing: Q/K/V/O share one element type in this kernel.
_PERF_TORCH_DTYPES = {
    cutlass.Float16: torch.float16,
    cutlass.BFloat16: torch.bfloat16,
}


def run(
    batches: int = 1,
    seqlen: int = 1024,
    heads_q: int = 64,
    heads_k: int = 8,
    headdim: int = 128,
    q_dtype: Type[cutlass.Numeric] = cutlass.BFloat16,
    kv_dtype: Type[cutlass.Numeric] = cutlass.BFloat16,
    o_dtype: Type[cutlass.Numeric] = cutlass.BFloat16,
    acc_dtype: Type[cutlass.Numeric] = cutlass.Float32,
    seq_tile: int = 128,
    tolerance: float = 2e-2,
    warmup_iterations: int = 0,
    iterations: int = 0,
    skip_ref_check: bool = False,
    use_cold_l2: bool = False,
    **kwargs,
):
    """Run and benchmark the simple GQA flash-decode kernel on Blackwell.

    Args:
        batches/seqlen/heads_q/heads_k/headdim: Decode problem shape (s_q == 1).
        q_dtype/kv_dtype/o_dtype: Must all be the same 16-bit float type.
        acc_dtype: Accumulator type. The kernel always accumulates in Float32,
            so Float32 is the only accepted value.
        seq_tile: K/V sequence tile; this kernel only supports 128.
        tolerance: Reference-check absolute/relative tolerance.
        warmup_iterations/iterations: Benchmark loop counts.
        skip_ref_check: Skip the PyTorch SDPA comparison.
        use_cold_l2: Cycle fresh Q/K/V/output workspaces so every benchmark
            iteration misses L2.
        kwargs: Absorbs the extra BenchmarkConfig fields that perf_benchmark
            passes to every run(); they are not forwarded any further.

    Returns:
        Execution time in microseconds per iteration.

    Raises:
        ValueError: If q/kv/o dtypes are not all the same Float16/BFloat16
            type, if acc_dtype is not Float32, if heads_q is not a multiple of
            heads_k, or if seq_tile is not 128.
        AssertionError: If reference checking is enabled and the output does
            not match PyTorch SDPA within tolerance.
    """
    print("Running Blackwell GQA Flash Decode (simple) test with:")
    print(f"\tbatches: {batches}, seqlen: {seqlen}")
    print(f"\theads_q: {heads_q}, heads_k: {heads_k}, headdim: {headdim}")
    print(f"\tq_dtype: {q_dtype}, kv_dtype: {kv_dtype}, o_dtype: {o_dtype}")
    print(f"\tacc_dtype: {acc_dtype}, seq_tile: {seq_tile}")
    print(f"\ttolerance: {tolerance}")
    print(f"\twarmup_iterations: {warmup_iterations}, iterations: {iterations}")
    print(f"\tskip_ref_check: {skip_ref_check}, use_cold_l2: {use_cold_l2}")

    if not (q_dtype is kv_dtype is o_dtype):
        raise ValueError(
            "gqa_decode_simple requires q_dtype == kv_dtype == o_dtype, got "
            f"{q_dtype}, {kv_dtype}, {o_dtype}"
        )
    if q_dtype not in _PERF_TORCH_DTYPES:
        raise ValueError(f"gqa_decode_simple supports Float16/BFloat16, got {q_dtype}")

    if acc_dtype is not cutlass.Float32:
        raise ValueError(
            f"gqa_decode_simple only supports acc_dtype=Float32, got {acc_dtype}"
        )
    if heads_q % heads_k != 0:
        raise ValueError(
            f"heads_q ({heads_q}) must be a multiple of heads_k ({heads_k})"
        )

    if seq_tile != 128:
        raise ValueError(
            f"gqa_decode_simple only supports seq_tile=128, got {seq_tile}"
        )

    cuda.cuInit(0)
    torch.manual_seed(33550336)
    dtype = _PERF_TORCH_DTYPES[q_dtype]

    b, hq, hkv, skv, d = batches, heads_q, heads_k, seqlen, headdim
    kv_splits, g_tile, h_blks, l_blks = compute_gqa_decode_grid(b, hq, hkv, skv)
    print(f"\tkv_splits: {kv_splits}, g_tile: {g_tile}")

    Q = torch.randn((b, hq, d), device="cuda", dtype=dtype)
    K = torch.randn((b, hkv, skv, d), device="cuda", dtype=dtype)
    V = torch.randn((b, hkv, skv, d), device="cuda", dtype=dtype)

    O_part = torch.empty((b, hq, kv_splits, d), device=Q.device, dtype=torch.float32)
    O_final = torch.empty((b, hq, d), device=Q.device, dtype=Q.dtype)
    M_part = torch.empty((b, hq, kv_splits), device="cuda", dtype=torch.float32)
    L_part = torch.empty((b, hq, kv_splits), device="cuda", dtype=torch.float32)

    runtime_us, terabytes_per_s, teraflops_per_s = run_gqa_decode(
        Q,
        K,
        V,
        O_part,
        M_part,
        L_part,
        O_final,
        seq_tile,
        g_tile,
        (kv_splits, h_blks, l_blks),
        warmup_iterations,
        iterations,
        use_cold_l2,
    )

    if not skip_ref_check:
        O_torch = F.scaled_dot_product_attention(
            Q.unsqueeze(2), K, V, enable_gqa=True
        ).squeeze(2)
        torch.testing.assert_close(O_final, O_torch, atol=tolerance, rtol=tolerance)
        print("check reference: PASS")

    print(
        f"{runtime_us:.3f} us, {terabytes_per_s:.3f} TB/s, {teraflops_per_s:.3f} TFLOPS"
    )
    return runtime_us


if __name__ == "__main__":
    main()
