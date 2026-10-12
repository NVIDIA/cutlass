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
from typing import Optional, Tuple, Type
from functools import partial
import cuda.bindings.driver as cuda
import torch
import torch.nn.functional as F

import cutlass
from cutlass import cute
import cutlass.testing as testing
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
gmem_fmax = partial(cute.arch.atomic_fmax, sem="relaxed", scope="gpu")

torch_cutlass_dtype_map = {
    torch.float16: cutlass.Float16,
    torch.bfloat16: cutlass.BFloat16,
    torch.float32: cutlass.Float32,
}

warp_threads = 32
warpgroup_warps = 4
warpgroup_threads = warpgroup_warps * warp_threads
MIN_MMA_TILE_N = 8
SOFTMAX_WARPGROUPS = 2
CTA_WARPGROUPS = SOFTMAX_WARPGROUPS + 2
MAX_REDUCTION_ITERS = 4  # log2(16), matching the atomic split limit


class GroupedQueryAttentionDecode:
    def __init__(
        self,
        g_tile,
        seq_tile,
        head_dim,
        dtype,
        decode_grid,
        reduction_mode="kernel",
    ):
        self.g_tile = g_tile
        self.seq_tile = seq_tile
        self.head_dim = head_dim
        self.dtype = dtype
        self.acc_dtype = cutlass.Float32
        self.decode_grid = decode_grid
        self.do_kernel_red = reduction_mode == "kernel"
        self.do_atomic_red = reduction_mode == "atomic"

        assert head_dim > 0 and head_dim % 64 == 0
        assert g_tile in (1, 2, 4, 8, 16, 32)
        # seq_tile > 256 is very likely to cause reg spill and bad performance
        assert seq_tile > 0 and seq_tile % 128 == 0 and seq_tile <= 256
        assert self.do_kernel_red ^ self.do_atomic_red

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
        if self.do_atomic_red:
            kv_splits = self.decode_grid[0]
            if kv_splits not in (1, 2, 4, 8, 16):
                raise ValueError(
                    f"atomic reduction requires kv_splits po2 <= 16, got {kv_splits}"
                )

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
        gmem_O_part: Optional[cute.Tensor],  # Expected shape: (kv_splits, b, h_q, d)
        gmem_M_part: Optional[cute.Tensor],  # Expected shape: (b, h_q, kv_splits)
        gmem_L_part: Optional[cute.Tensor],  # Expected shape: (b, h_q, kv_splits)
        gmem_M_final: Optional[cute.Tensor],  # Expected shape: (b, h_q)
        gmem_O_final: cute.Tensor,  # Expected shape: (b, h_q, d)
        scale_s_log2_e: Float32,
        stream: cuda.CUstream,
    ):
        block = (CTA_WARPGROUPS * warpgroup_threads, 1, 1)
        kv_splits = self.decode_grid[0]
        if cutlass.const_expr(self.do_atomic_red):
            cluster = (kv_splits, 1, 1)
        else:
            cluster = (1, 1, 1)
        smem = cute.Int64(cutlass.memory.get_smem_capacity_in_bytes("sm_100"))

        d = self.head_dim
        b, h_q, h_k, s_k, _d = problem_shape
        g = h_q // h_k  # head_group_size
        l_blks = b * h_k
        g_tile = self.g_tile
        seq_tile = self.seq_tile

        # Reinterpret public tensors as GEMM views with M/N/K modes leading.
        # KQ phase: K^T is A (M = seq_len, K = head_dim),
        # Q is B (N = head_group_size, K = head_dim).
        gmem_K_kq = self.make_gmem_view(gmem_K, (s_k, d, l_blks), (1, 0, 2))
        gmem_Q_kq = self.make_gmem_view(gmem_Q, (g, d, l_blks), (1, 0, 2))
        # VP phase: V is A (M = head_dim), P is B (N = head_group_size).
        gmem_V_vp = self.make_gmem_view(gmem_V, (d, s_k, l_blks), (0, 1, 2))
        # Kernel reduction stores one O_part per CTA. Atomic reduction stores
        # directly into O_final and keeps a size-1 split mode so the TMA store
        # tile rank stays identical.
        if cutlass.const_expr(self.do_kernel_red):
            assert gmem_O_part is not None
            assert gmem_M_part is not None
            assert gmem_L_part is not None
            assert gmem_M_final is not None
            gmem_O_store = self.make_gmem_view(
                gmem_O_part,
                (d, g, l_blks, kv_splits),
                (0, 1, 2, 3),
            )
            gmem_M_part_decode = self.make_gmem_view(
                gmem_M_part, (kv_splits, g, l_blks), (0, 1, 2)
            )
            gmem_L_part_decode = self.make_gmem_view(
                gmem_L_part, (kv_splits, g, l_blks), (0, 1, 2)
            )
            gmem_M_final_decode = self.make_gmem_view(gmem_M_final, (g, l_blks), (0, 1))
        else:
            gmem_O_store = self.make_gmem_view(
                gmem_O_final,
                (d, g, l_blks, 1),
                (0, 1, 2, 3),
            )
            gmem_M_part_decode = None
            gmem_L_part_decode = None
            gmem_M_final_decode = None

        # MMA tiling
        # For KQ MMA, K^T is operand A (M = 128-row score subtile, K = head_dim),
        # Q is operand B (N = logical grouped_head_tile, K = head_dim)
        # For VP MMA, V is operand A (M = head_dim, K = seq_tile),
        # P is operand B (N = logical grouped_head_tile, K = seq_tile)
        # Notes:
        # 1. To make accumulator use the canonical TMEM layout for softmax
        #    and VP correction, we need to set mma_tile_m = 128 even when
        #    head_dim == 64.
        # 2. To reuse the same buffer for K and V, we need to set mma_tile_k = 64,
        #    even if KQ and VP may have different K-dim sizes (head_dim vs seq_tile)
        mma_tile_m = 128
        mma_tile_n = max(MIN_MMA_TILE_N, g_tile)
        mma_tile_k = 64
        assert mma_tile_n % g_tile == 0
        tiles_sm = cute.ceil_div(seq_tile, mma_tile_m)
        tiles_dk = cute.ceil_div(d, mma_tile_k)
        tiles_dm = cute.ceil_div(d, mma_tile_m)
        tiles_sk = cute.ceil_div(seq_tile, mma_tile_k)
        self.mma_tile_mnk = (mma_tile_m, mma_tile_n, mma_tile_k)
        self.subtile_cnts = (tiles_sm, tiles_dk, tiles_dm, tiles_sk)

        # Stage counts
        self.Q_stages = tiles_dk
        self.P_stages = 4
        self.S_stages = 4
        self.L_stages = SOFTMAX_WARPGROUPS
        self.O_stages = 2
        # Reserve SMEM for all non-KV SMEM buffers first, then use the remaining capacity
        # for as many shared KV stages as possible.
        mbarrier_bits = 64
        pipe_stage_bits = mbarrier_bits * 2  # producer + consumer bookkeeping
        mk_stage_bits = mma_tile_m * mma_tile_k * self.dtype.width
        nk_stage_bits = mma_tile_n * mma_tile_k * self.dtype.width
        mn_stage_bits = mma_tile_m * mma_tile_n * self.dtype.width
        smem_alloc_bits = 0
        smem_alloc_bits += g_tile * self.acc_dtype.width  # smem_M
        smem_alloc_bits += 4 * g_tile * self.acc_dtype.width  # smem_L_ps
        if cutlass.const_expr(self.do_atomic_red):
            smem_alloc_bits += MAX_REDUCTION_ITERS * g_tile * self.acc_dtype.width * 2
            smem_alloc_bits += MAX_REDUCTION_ITERS * mbarrier_bits * 2
        smem_alloc_bits += (
            self.Q_stages * nk_stage_bits + mbarrier_bits
        )  # smem_Q + q_load_mbar
        smem_alloc_bits += self.P_stages * (
            tiles_sm * mn_stage_bits + pipe_stage_bits
        )  # smem_P + P_pipe
        smem_alloc_bits += self.S_stages * pipe_stage_bits  # S_pipe
        smem_alloc_bits += self.O_stages * pipe_stage_bits  # O_pipe
        smem_capacity_bits = cutlass.memory.get_smem_capacity_in_bytes("sm_100") * 8
        alignment_bits = 1024 - (smem_alloc_bits % 1024)
        remaining_bits = smem_capacity_bits - smem_alloc_bits - alignment_bits
        kv_stages = remaining_bits // mk_stage_bits
        kv_stages -= 1 if kv_stages * pipe_stage_bits > alignment_bits else 0
        assert kv_stages > 0
        self.KV_stages = kv_stages

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
        # SMEM as padded (seq_tile, mma_tile_n) VP-B tiles. Thus the VP
        # contracting dimension is seq_tile. It is neither the fastest-changing
        # dimension in V nor in staged P, so both operands use MN-major mode.
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
            tcgen05.mma.SmemLayoutAtomKind.MN_SW128, gmem_O_store.element_type
        )

        O_shape = (max(self.head_dim, mma_tile_m), mma_tile_n)
        smem_O_layout = cute.tile_to_shape(smem_O_layout_atom, O_shape, order=(1, 0))
        smem_O_layout = cute.flat_divide(smem_O_layout, (mma_tile_m, mma_tile_n))

        self.decode_kernel(
            problem_shape,
            gmem_Q_kq,
            gmem_K_kq,
            gmem_V_vp,
            gmem_O_store,
            gmem_M_part_decode,
            gmem_L_part_decode,
            gmem_M_final_decode,
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
            min_blocks_per_mp=1,
            use_pdl=True,
        )

        d_per_blk = d
        d_per_thr = 32 // self.dtype.width
        thr_per_blk = d_per_blk // d_per_thr
        d_blks = cute.ceil_div(d, d_per_blk)
        s_blks = cute.ceil_div(s_k, self.seq_tile)
        # Oversplit decode grids can produce empty split CTAs that publish neutral M/L partials
        # (M=-inf, L=0) without writing O_part. Skip those entries entirely so reduction does
        # not read undefined O_part or hit -inf/-inf correction cases
        reduction_kv_splits = min(kv_splits, s_blks)
        reduction_smem_bytes = (reduction_kv_splits * 2 + 1) * Float32.width // 8
        if cutlass.const_expr(self.do_kernel_red):
            # O_part, M_part, L_part have different logical shapes in reduction kernel
            # than in decode kernel, make new tensors for reduction kernel
            assert gmem_O_part is not None
            assert gmem_M_part is not None
            assert gmem_L_part is not None
            assert gmem_M_final is not None
            gmem_O_part_reduction = self.make_gmem_view(
                gmem_O_part, (d, h_q, b, kv_splits), (0, 1, 2, 3)
            )
            gmem_M_part_reduction = self.make_gmem_view(
                gmem_M_part, (kv_splits, h_q, b), (0, 1, 2)
            )
            gmem_L_part_reduction = self.make_gmem_view(
                gmem_L_part, (kv_splits, h_q, b), (0, 1, 2)
            )
            gmem_M_final_reduction = self.make_gmem_view(gmem_M_final, (h_q, b), (0, 1))
            gmem_O_final_reduction = self.make_gmem_view(
                gmem_O_final, (d, h_q, b), (0, 1, 2)
            )
            self.reduction_kernel(
                gmem_O_part_reduction,
                gmem_M_part_reduction,
                gmem_L_part_reduction,
                gmem_M_final_reduction,
                gmem_O_final_reduction,
                reduction_kv_splits,
            ).launch(
                grid=(d_blks, h_q, b),
                block=(thr_per_blk, 1, 1),
                cluster=(1, 1, 1),
                stream=stream,
                smem=reduction_smem_bytes,
                min_blocks_per_mp=1,
                use_pdl=True,
            )

    @cute.experimental.kernel
    def decode_kernel(
        self,
        problem_shape: Tuple[Int32, Int32, Int32, Int32, Int32],
        gmem_Q: cute.Tensor,
        gmem_K: cute.Tensor,
        gmem_V: cute.Tensor,
        gmem_O_store: cute.Tensor,
        gmem_M_part: Optional[cute.Tensor],
        gmem_L_part: Optional[cute.Tensor],
        gmem_M_final: Optional[cute.Tensor],
        scale_s_log2_e: Float32,
        tiled_mma_kq: cute.TiledMma,
        tiled_mma_vp: cute.TiledMma,
        smem_Q_layout_staged: cute.ComposedLayout,
        smem_K_layout_staged: cute.ComposedLayout,
        smem_V_layout_staged: cute.ComposedLayout,
        smem_O_layout: cute.ComposedLayout,
    ):
        # Fused kernel with in-kernel online softmax:
        # KQ MMA -> softmax -> VP MMA -> correction -> output
        # 16 warps (512 threads):
        #   warps 0-3:   TMA/MMA warpgroup
        #     - warp 0:  KQ MMA
        #     - warp 1:  VP MMA
        #     - warp 2:  TMA load KV + reduction writeback
        #     - warp 3:  TMA load Q + final O store
        #   warps 4-7:   softmax phase 0
        #   warps 8-11:  softmax phase 1
        #   warps 12-15: correction + final store (online softmax accumulation)
        #
        # Each CTA processes multiple seq_tile blocks. Correction keeps rolling
        # O/L/M state across iterations and emits one merged result per split CTA.
        mma_tma_warpgroup_id = 0
        softmax_warpgroup_ids = tuple(
            range(
                mma_tma_warpgroup_id + 1, mma_tma_warpgroup_id + 1 + SOFTMAX_WARPGROUPS
            )
        )
        correction_warpgroup_id = softmax_warpgroup_ids[-1] + 1
        mma_kq_warp_id = mma_tma_warpgroup_id * warpgroup_warps + 0
        mma_vp_warp_id = mma_tma_warpgroup_id * warpgroup_warps + 1
        tma_kv_warp_id = mma_tma_warpgroup_id * warpgroup_warps + 2
        tma_qo_warp_id = mma_tma_warpgroup_id * warpgroup_warps + 3
        reduction_warp_id = tma_kv_warp_id
        tid_x, _, _ = cute.arch.thread_idx()
        warp_idx = cute.arch.warp_idx()
        warp_idx = cute.arch.make_warp_uniform(warp_idx)
        lane_idx = cute.arch.lane_idx()
        warpgroup_idx = warp_idx // warpgroup_warps
        warpgroup_widx = warp_idx % warpgroup_warps

        d = self.head_dim
        _b, h_q, h_k, s_k, _d = problem_shape
        seq_tile = self.seq_tile
        g_tile = self.g_tile
        s_blks = cute.ceil_div(s_k, seq_tile)
        kv_splits = self.decode_grid[0]

        mma_tile_mnk = self.mma_tile_mnk
        mma_tile_m, mma_tile_n, mma_tile_k = self.mma_tile_mnk
        tiles_sm, tiles_dk, tiles_dm, tiles_sk = self.subtile_cnts

        mma_kq_instr_shape_k = cute.size(tiled_mma_kq.shape_mnk, mode=[2])
        mma_vp_instr_shape_k = cute.size(tiled_mma_vp.shape_mnk, mode=[2])
        KQ_num_instr_k = mma_tile_k // mma_kq_instr_shape_k
        VP_num_instr_k = mma_tile_k // mma_vp_instr_shape_k

        use_reg_reconfig = g_tile > 16
        max_sw_regs_per_wg_thread = 256  # CUDA limitation
        max_hw_regs_per_wg_thread = 64 * 1024 // warpgroup_threads
        mma_tma_regs = 64
        softmax_regs = 120
        correction_regs = min(
            max_sw_regs_per_wg_thread,
            max_hw_regs_per_wg_thread - mma_tma_regs - softmax_regs * 2,
        )
        assert (
            mma_tma_regs + softmax_regs * SOFTMAX_WARPGROUPS + correction_regs
        ) <= max_hw_regs_per_wg_thread

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

        # Final O store happens after the KV pipelines are drained, so the same physical
        # SMEM allocation used by the shared KV buffer can be safely reinterpreted as O
        # smem_O_layout's row factorization depends on the output store dtype.
        smem_O_iter = cute.recast_ptr(
            smem_KV.iterator, smem_O_layout.inner, dtype=gmem_O_store.element_type
        )
        smem_O_tma = cute.make_tensor(smem_O_iter, smem_O_layout.outer)

        # Softmax produces a full (seq_tile, g_tile) P block per sequence iteration.
        # VP consumes the same storage as operand B with the full seq_tile as K-dim.
        smem_P_tiler_nm = (None, mma_tile_n, seq_tile)
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

        # Keep the native MMA accumulator fragment layout for KQ's dot. The
        # softmax warp reinterprets the same storage as a staged `(tiles_sm, stage)`
        # view below so it can consume all S subtiles for one stage with one copy.
        tmem_S_layout = cute_ext.make_tmem_layout_acc(
            tiled_mma_kq, mma_tile_mnk, self.S_stages * tiles_sm
        )
        # Correction now receives a dedicated per-thread colsum buffer instead of
        # re-reading all probability tiles from TMEM.
        tmem_L_layout = cute_ext.make_tmem_layout_acc(
            tiled_mma_kq, mma_tile_mnk, self.L_stages
        )
        tmem_O_layout = cute.make_layout(
            shape=((mma_tile_m, mma_tile_n), 1, 1, tiles_dm, self.O_stages),
            stride=((65536, 1), 0, 0, mma_tile_n, tiles_dm * mma_tile_n),
        )
        tmem_S = tmem_alloc(self.acc_dtype, tmem_S_layout)
        tmem_L = tmem_alloc(self.acc_dtype, tmem_L_layout)
        tmem_O = tmem_alloc(self.acc_dtype, tmem_O_layout)
        tmem_S_staged_layout = cute.make_layout(
            shape=((mma_tile_m, mma_tile_n), 1, 1, tiles_sm, self.S_stages),
            stride=((65536, 1), 0, 0, mma_tile_n, tiles_sm * mma_tile_n),
        )
        tmem_S_staged = cute.make_tensor(tmem_S.iterator, tmem_S_staged_layout)

        # Each staged TMEM block has layout (mma_tile_m, mma_tile_n):(65536, 1).
        # Each participating thread owns one padded N-vector for S/L/O copies.
        tmem_L_stage0 = tmem_L[
            (None, None), 0, 0, 0
        ]  # (mma_tile_m,mma_tile_n):(65536,1)
        tmem_copy_rep = tcgen05.Repetition(g_tile)
        ld_op = tcgen05.Ld32x32bOp(tmem_copy_rep, tcgen05.Pack.NONE)
        st_op = tcgen05.St32x32bOp(tmem_copy_rep, tcgen05.Unpack.NONE)
        copy_atom_t2r = cute.make_copy_atom(ld_op, self.acc_dtype)
        copy_atom_r2t = cute.make_copy_atom(st_op, self.acc_dtype)
        copy_atom_r2s_P = cute.make_copy_atom(cute.nvgpu.CopyUniversalOp(), self.dtype)
        copy_atom_r2s_O = cute.make_copy_atom(
            cute.nvgpu.CopyUniversalOp(), gmem_O_store.element_type
        )
        tiled_copy_t2r = tcgen05.make_tmem_copy(copy_atom_t2r, tmem_L_stage0)
        tiled_copy_r2t = tcgen05.make_tmem_copy(copy_atom_r2t, tmem_L_stage0)
        tiled_copy_r2s_O = cute.make_tiled_copy_D(copy_atom_r2s_O, tiled_copy_t2r)
        tid_x_in_group = tid_x % warpgroup_threads
        thr_t2r_copy = tiled_copy_t2r.get_slice(tid_x_in_group)
        thr_r2t_copy = tiled_copy_r2t.get_slice(tid_x_in_group)
        thr_r2s_copy_O = tiled_copy_r2s_O.get_slice(tid_x_in_group)
        rmem_vec_layout = thr_t2r_copy.partition_D(tmem_L_stage0).layout
        rmem_vec_size = cute.cosize(rmem_vec_layout)
        assert rmem_vec_size == mma_tile_n
        assert rmem_vec_layout.shape == ((g_tile, 1), 1, mma_tile_n // g_tile)

        # SMEM buffers shared between softmax and correction warps
        # smem_M: holds column-max values (m_new) for softmax -> correction
        smem_M = smem_alloc(self.acc_dtype, rmem_vec_layout)
        # smem_L_ps: holds per-warp final L partial sums for the reduction path
        smem_L_ps_layout = cute.make_layout(
            shape=(4, g_tile),
            stride=(g_tile, 1),
        )
        smem_L_ps = smem_alloc(self.acc_dtype, smem_L_ps_layout)
        smem_R = None
        if cutlass.const_expr(self.do_atomic_red):
            # DSMEM scratch used by the split-cluster butterfly reductions for
            # final M and L. Two slots: one for max, one for sum.
            smem_R = smem_alloc(
                self.acc_dtype,
                cute.make_layout((g_tile, MAX_REDUCTION_ITERS, 2)),
            )

        lane_store_max = lane_idx < g_tile
        if warp_idx == tma_qo_warp_id:
            if lane_store_max:
                smem_M[lane_idx] = -Float32.inf

        prefetch_iters = 2
        prefetch_tiles = prefetch_iters * kv_splits

        M_producer_nbar = pipeline.NamedBarrier(2, 2 * warpgroup_threads)
        M_consumer_nbar = pipeline.NamedBarrier(3, 2 * warpgroup_threads)
        L_producer_nbar = pipeline.NamedBarrier(4, 2 * warpgroup_threads)
        L_consumer_nbar = pipeline.NamedBarrier(6, 2 * warpgroup_threads)
        M_final_nbar = pipeline.NamedBarrier(8, warpgroup_threads + warp_threads)
        L_final_nbar = pipeline.NamedBarrier(10, warpgroup_threads + warp_threads)
        # KQ and VP walk the same KV pipeline at different times. These two
        # barriers provide the hand-off points between their local consumer
        # states:
        # - mma_order_VP_nbar: VP has finished skipping/consuming the V-side
        #   tiles from older iterations, so KQ may now treat the shared state
        #   as pointing at the K-side tiles for its current iteration.
        # - mma_order_KQ_nbar: KQ has finished the K-side tiles for the current
        #   iteration, so VP may now advance to and consume the matching V-side
        #   tiles from the same shared KV stream.
        mma_order_KQ_nbar = pipeline.NamedBarrier(11, 2 * warp_threads)
        mma_order_VP_nbar = pipeline.NamedBarrier(12, 2 * warp_threads)
        sM_mutex_nbar = pipeline.NamedBarrier(
            13, SOFTMAX_WARPGROUPS * warpgroup_threads
        )
        # Final O lives in the KV blocks SMEM region, which is not used anymore
        # after the KV pipelines are drained, so a single named barrier is enough
        O_final_nbar = pipeline.NamedBarrier(9, 5 * warp_threads)

        def with_phase(nbar, phase):
            return pipeline.NamedBarrier(nbar.barrier_id + phase, nbar.num_threads)

        reduction_mbars_ptr = None
        if cutlass.const_expr(self.do_atomic_red):
            reduction_mbars = smem_alloc(
                cutlass.Int64,
                cute.make_layout((MAX_REDUCTION_ITERS * 2,)),
                alignment=8,
            )
            reduction_mbars_ptr = reduction_mbars.iterator
            if warp_idx == reduction_warp_id and lane_idx < MAX_REDUCTION_ITERS * 2:
                local_mbar = reduction_mbars_ptr + lane_idx
                expect_tx_bytes = g_tile * self.acc_dtype.width // 8
                cute.arch.mbarrier_init(local_mbar, 1)
                cute.arch.mbarrier_init_fence()
                cute.arch.mbarrier_arrive_and_expect_tx(local_mbar, expect_tx_bytes)
            cute.arch.cluster_arrive_relaxed()

        # Pipelines
        # This single mbarrier guards the whole staged Q preload, so it expects the
        # total bytes across all Q stages rather than per-stage bytes.
        Q_load_mbar = smem_alloc(
            cutlass.Int64, cute.make_layout(1), alignment=8
        ).iterator
        if warp_idx == tma_qo_warp_id:
            # Match the reference logic: this mbarrier guards the whole staged Q
            # preload, so its expected transaction size must equal the actual staged
            # SMEM layout footprint rather than just the logical g_tile*d payload.
            Q_tx_bytes = cute.size_in_bytes(self.dtype, smem_Q_layout_staged)
            with cute.arch.elect_one():
                cute.arch.mbarrier_init(Q_load_mbar, 1)
                cute.arch.mbarrier_init_fence()
                cute.arch.mbarrier_arrive_and_expect_tx(Q_load_mbar, Q_tx_bytes)
        # Shared TMA KV -> MMA pipeline, consumed by both KQ MMA and VP MMA at
        # different times and ordered explicitly via mma_order_KQ_nbar /
        # mma_order_VP_nbar.
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

        if cutlass.const_expr(self.do_atomic_red):
            cute.arch.cluster_wait()
        cute.arch.sync_threads()

        # Some split CTAs can start past the end of the sequence when
        # kv_splits > s_blks. Those CTAs must not enter the main pipeline
        # at all, otherwise they can block forever on handoff barriers that
        # no valid producer will ever signal. Instead, publish the neutral
        # M/L state for this split and let the reduction path retire it.
        if exit_early:
            if warp_idx == reduction_warp_id:
                cute.arch.griddepcontrol_wait()
            if warpgroup_idx == correction_warpgroup_id:
                M_final_nbar.arrive()
                if lane_idx < g_tile:
                    smem_L_ps[warpgroup_widx, lane_idx] = Float32(0.0)
                L_final_nbar.arrive()

        # TMA load Q and TMA store O
        elif warp_idx == tma_qo_warp_id:
            if cutlass.const_expr(use_reg_reconfig):
                cute.arch.setmaxregister_decrease(mma_tma_regs)

            # Slice one logical grouped-head block first, then reinterpret it as a
            # single padded MMA-N tile when g_tile < mma_tile_n.
            Q_tiler = (mma_tile_n, mma_tile_k)
            Q_coord = (cta_h, None, cta_l)
            gmem_Q_block = cute.local_tile(gmem_Q, Q_tiler, Q_coord)
            gmem_Q_local = thrblk_mma_kq.partition_B(gmem_Q_block)
            cute.arch.griddepcontrol_wait()
            for dk in cutlass.range_constexpr(tiles_dk):
                gQ_slice = gmem_Q_local[None, None, None, dk]
                # update_expect_tx=False: do not automatically update the mbarrier's
                # transaction bytes since they are already initialized
                cute_ext.tma_load(
                    gQ_slice,
                    smem_Q[None, None, None, dk],
                    Q_load_mbar.value,
                    update_expect_tx=False,
                )

            # Store one logical grouped-head block per CTA, then reinterpret it as a
            # single padded MMA-N tile so the GMEM destination matches the SMEM O tile
            # even when g_tile < mma_tile_n.
            O_part_tiler = (mma_tile_m, g_tile)
            O_mma_tiler = (mma_tile_m, mma_tile_n)
            O_cta_v_map = cute_ext.get_cta_v_map_c(gmem_O_store, O_mma_tiler)
            O_final_nbar.arrive_and_wait()
            for dm in cutlass.range_constexpr(tiles_dm):
                if cutlass.const_expr(self.do_atomic_red):
                    split_store_idx = 0
                else:
                    split_store_idx = cta_s
                O_block_coord = (dm, cta_h, cta_l, split_store_idx)
                gmem_O_block = cute.local_tile(
                    gmem_O_store, O_part_tiler, O_block_coord
                )
                gmem_O_mma = cute.flat_divide(gmem_O_block, O_mma_tiler)
                if cutlass.const_expr(self.do_atomic_red):
                    # Each split CTA has already scaled its local numerator by
                    # 1 / L_final; TMA reduce-store atomically accumulates the
                    # split contributions directly into O_final.
                    cute_ext.tma_reduce_store(
                        smem_O_tma[None, None, dm, 0],
                        gmem_O_mma[None, None, 0, 0],
                        kind=cute.ReductionKind.ADD,
                        cta_v_map=O_cta_v_map,
                    )
                else:
                    cute_ext.tma_store(
                        smem_O_tma[None, None, dm, 0],
                        gmem_O_mma[None, None, 0, 0],
                        cta_v_map=O_cta_v_map,
                    )
            cute.arch.cp_async_bulk_commit_group()

        # TMA load KV
        elif warp_idx == tma_kv_warp_id:
            if cutlass.const_expr(use_reg_reconfig):
                cute.arch.setmaxregister_decrease(mma_tma_regs)

            # gmem_V_local.shape = ((d, seq_tile), l_blks), built from the real
            # sequence length so the last block can be partial without host-side padding.
            KV_tiler = (mma_tile_m, mma_tile_k)
            cute.arch.griddepcontrol_wait()
            kv_token = cutlass.Boolean(True)  # Producer always acquires first
            for s in cutlass.range(cta_s, prefetch_tiles + s_blks, kv_splits):
                if s < s_blks:
                    k_block_coord = (s, 0, cta_l)
                    gmem_K_local = cute.local_tile(gmem_K, (seq_tile, d), k_block_coord)
                    gmem_K_s = cute.zipped_divide(gmem_K_local, KV_tiler)
                    for sm in cutlass.range_constexpr(tiles_sm):
                        gmem_K_sm = gmem_K_s[(None, None), (sm, None)]
                        tAgK = thrblk_mma_kq.partition_A(gmem_K_sm)
                        for dk in cutlass.range_constexpr(tiles_dk):
                            gK_slice = tAgK[None, None, None, dk]
                            kv_stage_token, kv_idx = (
                                KV_pipe.producer_acquire_and_get_stage(token=kv_token)
                            )
                            kv_mbar = cute_ext.get_mbarrier(kv_stage_token)
                            smem_K_slice = smem_K[None, None, None, kv_idx]
                            cute_ext.tma_load(gK_slice, smem_K_slice, kv_mbar)
                            KV_pipe.producer_commit_and_advance()
                            kv_token = KV_pipe.producer_try_acquire()

                if s >= prefetch_tiles:
                    # Take one logical seq_tile-sized view from the true V tensor,
                    # then divide that local block into VP MMA tiles. The last block
                    # may be smaller than seq_tile in GMEM; CuTe keeps that shape.
                    v_block_coord = (0, s - prefetch_tiles, cta_l)
                    gmem_V_local = cute.local_tile(gmem_V, (d, seq_tile), v_block_coord)
                    gmem_V_s = cute.zipped_divide(gmem_V_local, KV_tiler)
                    for sk in cutlass.range_constexpr(tiles_sk):
                        gmem_V_sk = gmem_V_s[(None, None), (None, sk)]
                        tAgV = thrblk_mma_vp.partition_A(gmem_V_sk)
                        for dm in cutlass.range_constexpr(tiles_dm):
                            gV_slice = tAgV[None, None, None, dm]
                            kv_stage_token, kv_idx = (
                                KV_pipe.producer_acquire_and_get_stage(token=kv_token)
                            )
                            kv_mbar = cute_ext.get_mbarrier(kv_stage_token)
                            smem_V_slice = smem_V[None, None, None, kv_idx]
                            cute_ext.tma_load(gV_slice, smem_V_slice, kv_mbar)
                            KV_pipe.producer_commit_and_advance()
                            kv_token = KV_pipe.producer_try_acquire()

        # KQ MMA (waits for K and Q from TMA)
        elif warp_idx == mma_kq_warp_id:
            if cutlass.const_expr(use_reg_reconfig):
                cute.arch.setmaxregister_decrease(mma_tma_regs)

            vp_tiles_per_iter = tiles_dm * tiles_sk
            mma_atom = cute.make_mma_atom(tiled_mma_kq.op)

            # Wait until all Q blocks are loaded
            cute.arch.mbarrier_wait(Q_load_mbar, phase=0)

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
                mma_order_VP_nbar.arrive_and_wait()
                k_token = KV_pipe.consumer_try_wait()

                _, kq_idx = S_pipe.producer_acquire_and_get_stage(token=s_token)
                for sm in cutlass.range_constexpr(tiles_sm):
                    s_acc_stage = kq_idx * tiles_sm + sm
                    mma_atom.set(tcgen05.Field.ACCUMULATE, False)
                    tmem_S_sliced = tmem_S[None, None, None, s_acc_stage]
                    for dk in cutlass.range_constexpr(tiles_dk):
                        _, K_sidx = KV_pipe.consumer_wait_and_get_stage(token=k_token)
                        for instr_idx in cutlass.range_constexpr(KQ_num_instr_k):
                            K_slice = smem_K[None, None, instr_idx, K_sidx]
                            Q_slice = smem_Q[None, None, instr_idx, dk]
                            cute_ext.dot(mma_atom, K_slice, Q_slice, tmem_S_sliced)
                            mma_atom.set(tcgen05.Field.ACCUMULATE, True)
                        KV_pipe.consumer_release_and_advance()
                        if sm == tiles_sm - 1 and dk == tiles_dk - 1:
                            mma_order_KQ_nbar.arrive()
                        else:
                            k_token = KV_pipe.consumer_try_wait()
                S_pipe.producer_commit_and_advance()

            # Drain the KQ-only tail of the warmup window. VP still has
            # prefetch_iters iterations of V-side latency behind it, so KQ waits
            # for VP to catch up before retiring the remaining K-only tiles.
            for _ in cutlass.range_constexpr(prefetch_iters):
                mma_order_VP_nbar.arrive_and_wait()
                mma_order_KQ_nbar.arrive()

        # VP MMA (waits for V from TMA + P from softmax)
        elif warp_idx == mma_vp_warp_id:
            if cutlass.const_expr(use_reg_reconfig):
                cute.arch.setmaxregister_decrease(mma_tma_regs)

            kq_tiles_per_iter = tiles_sm * tiles_dk
            iters_s = cute.ceil_div(s_blks - cta_s, kv_splits)
            mma_atom = cute.make_mma_atom(tiled_mma_vp.op)

            mma_order_VP_nbar.arrive()
            # VP tiles are loaded prefetch_iters later than KQ tiles. For each
            # prefetch iteration, VP advances past kq_tiles_per_iter KQ tiles
            # to match the KQ tiles loaded by KQ for the same prefetch iteration.
            for prefetch_iter in cutlass.range_constexpr(prefetch_iters):
                if cta_s + prefetch_iter * kv_splits < s_blks:
                    for _ in cutlass.range_constexpr(kq_tiles_per_iter):
                        KV_pipe.consumer_state = KV_pipe.increment_state(
                            KV_pipe.consumer_state
                        )
                mma_order_KQ_nbar.arrive_and_wait()
                mma_order_VP_nbar.arrive()

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
                mma_order_KQ_nbar.arrive_and_wait()

                p_token = P_pipe.consumer_try_wait()
                v_token = KV_pipe.consumer_try_wait()
                o_token = O_pipe.producer_try_acquire()

                _, p_idx = P_pipe.consumer_wait_and_get_stage(token=p_token)
                _, o_idx = O_pipe.producer_acquire_and_get_stage(token=o_token)
                for dk in cutlass.range_constexpr(tiles_sk):
                    for dm in cutlass.range_constexpr(tiles_dm):
                        _, v_sidx = KV_pipe.consumer_wait_and_get_stage(token=v_token)
                        tmem_O_sliced = tmem_O[None, None, None, dm, o_idx]
                        # O now lives persistently in TMEM, so VP always accumulates
                        # onto the correction-updated state for this dm tile.
                        mma_atom.set(tcgen05.Field.ACCUMULATE, True)
                        for instr_idx in cutlass.range_constexpr(VP_num_instr_k):
                            V_slice = smem_V[None, None, instr_idx, v_sidx]
                            P_slice = smem_P_nk[None, None, instr_idx, dk, p_idx]
                            cute_ext.dot(mma_atom, V_slice, P_slice, tmem_O_sliced)
                            mma_atom.set(cute.nvgpu.tcgen05.Field.ACCUMULATE, True)
                        if dm == tiles_dm - 1 and dk == tiles_sk - 1:
                            mma_order_VP_nbar.arrive()
                        KV_pipe.consumer_release_and_advance()
                        if dm != tiles_dm - 1 or dk != tiles_sk - 1:
                            v_token = KV_pipe.consumer_try_wait()
                P_pipe.consumer_release_and_advance()
                O_pipe.producer_commit_and_advance()
            if iters_s == 1:
                # Correction retires two O slots in its rolling-window tail.
                # Publish the second slot as the pre-zeroed empty buffer when
                # there is only one real sequence iteration.
                o_token = O_pipe.producer_try_acquire()
                _, _o_idx = O_pipe.producer_acquire_and_get_stage(token=o_token)
                O_pipe.producer_commit_and_advance()
            O_pipe.producer_tail()

        # Softmax consumer of KQ, producer of P for VP
        # Two warpgroup phases alternate on S/L handoff while sharing one running-M buffer
        elif warpgroup_idx in softmax_warpgroup_ids:
            if cutlass.const_expr(use_reg_reconfig):
                cute.arch.setmaxregister_decrease(softmax_regs)

            iters_s = cute.ceil_div(s_blks - cta_s, kv_splits)

            # Per-iteration softmax data flow:
            # tmem_S_stage0: (mma_tile_m, mma_tile_n, tiles_sm):(65536, 1, mma_tile_n)
            # tmem_S_stage -> rmem_S: physical (mma_tile_n, tiles_sm) per thread
            # rmem_S -> scores: logical (g_tile, tiles_sm), excluding padded N lanes
            # scores -> rmem_M_valid: reduce tiles_sm to per-head max (g_tile,)
            # scores + rmem_M_valid -> probs: f32 probabilities (g_tile, tiles_sm)
            # probs -> rmem_P: output dtype P staging, padded to (mma_tile_n, tiles_sm)
            # rmem_P -> smem_P_view: SMEM P tile (mma_tile_m, mma_tile_n, tiles_sm)
            # probs -> rmem_L_valid -> tmem_L_phase: per-head colsum (g_tile,)
            # Keep repetition at g_tile for g_tile < mma_tile_n so padded lanes
            # in later subtiles are not copied as valid scores.
            tmem_S_stage0 = tmem_S_staged[(None, None), 0, 0, None, 0]
            tmem_copy_rep_S = tcgen05.Repetition(g_tile)
            if cutlass.const_expr(mma_tile_n == g_tile and tiles_sm > 1):
                tmem_copy_rep_S = tcgen05.Repetition(g_tile * tiles_sm)
            copy_atom_t2r_S = cute.make_copy_atom(
                tcgen05.Ld32x32bOp(tmem_copy_rep_S, tcgen05.Pack.NONE),
                self.acc_dtype,
            )
            tiled_copy_t2r_S = tcgen05.make_tmem_copy(copy_atom_t2r_S, tmem_S_stage0)
            tiled_copy_r2s_P = cute.make_tiled_copy_D(copy_atom_r2s_P, tiled_copy_t2r_S)
            thr_t2r_copy_S = tiled_copy_t2r_S.get_slice(tid_x_in_group)
            thr_r2s_copy_P = tiled_copy_r2s_P.get_slice(tid_x_in_group)
            rmem_S_layout = thr_t2r_copy_S.partition_D(tmem_S_stage0).layout
            assert cute.cosize(rmem_S_layout) == mma_tile_n * tiles_sm
            # rmem_S_layout is the physical T2R destination. Its exact nesting
            # depends on the copy atom, but its cosize is mma_tile_n * tiles_sm.

            # rmem_vec_layout.shape: ((g_tile, 1), 1, mma_tile_n // g_tile)
            rmem_P_layout = cute.make_layout(
                (*rmem_vec_layout.shape, tiles_sm),
                stride=(*rmem_vec_layout.stride, rmem_vec_size),
            )
            rmem_scores_layout = cute.make_layout(
                shape=(g_tile, tiles_sm),
                stride=(1, rmem_vec_size),
            )
            smem_P_view_layout = cute.make_layout(
                shape=(mma_tile_m, mma_tile_n, tiles_sm),
                stride=(mma_tile_n, 1, mma_tile_m * mma_tile_n),
            )

            rmem_S = rmem_alloc(self.acc_dtype, rmem_S_layout)
            rmem_P = rmem_alloc(self.dtype, rmem_P_layout)
            rmem_L = rmem_alloc(self.acc_dtype, rmem_vec_layout)
            rmem_M = rmem_alloc(self.acc_dtype, rmem_vec_layout)
            rmem_scores = cute.make_tensor(rmem_S.iterator, rmem_scores_layout)
            rmem_probs = cute.make_tensor(rmem_P.iterator, rmem_scores_layout)
            # rmem_{L,M}_valid: valid (g_tile,) slice of padded rmem_vec_layout
            rmem_L_valid = rmem_L[(None, 0), 0, 0]
            rmem_M_valid = rmem_M[(None, 0), 0, 0]

            phase = warpgroup_idx - softmax_warpgroup_ids[0]
            phase_M_acquire_nbar = with_phase(sM_mutex_nbar, phase)
            phase_M_release_nbar = with_phase(sM_mutex_nbar, phase ^ 1)
            phase_L_consumer_nbar = with_phase(L_consumer_nbar, phase)
            phase_L_producer_nbar = with_phase(L_producer_nbar, phase)
            tmem_L_phase = tmem_L[(None, None), 0, 0, phase]

            # Phase 1 starts one S/P stage later than phase 0 so the two
            # softmax warpgroups naturally interleave on odd/even iterations
            if phase == 1:
                S_pipe.consumer_state = S_pipe.increment_state(S_pipe.consumer_state)
                P_pipe.producer_state = P_pipe.increment_state(P_pipe.producer_state)
                phase_M_release_nbar.arrive()
                if iters_s == 1:
                    # The rolling-window correction tail always consumes both
                    # L phases. Publish the odd slot as the pre-zeroed empty
                    # buffer when there is only one real sequence iteration
                    phase_L_producer_nbar.arrive()

            for iter_idx in cutlass.range(phase, iters_s, SOFTMAX_WARPGROUPS):
                s = cta_s + iter_idx * kv_splits
                s_token = S_pipe.consumer_try_wait()
                p_token = P_pipe.producer_try_acquire()

                # Load S: tmem_S_stage -> rmem_S, physical (mma_tile_n, tiles_sm)
                _, s_idx = S_pipe.consumer_wait_and_get_stage(token=s_token)
                rmem_M.fill(-Float32.inf)
                tmem_S_stage = tmem_S_staged[(None, None), 0, 0, None, s_idx]
                cute_ext.partition_and_copy(thr_t2r_copy_S, tmem_S_stage, rmem_S)
                cute.arch.fence_view_async_tmem_load()
                S_pipe.consumer_release_and_advance()

                valid_rows = s_k - s * seq_tile
                for sm in cutlass.range_constexpr(tiles_sm):
                    if tid_x_in_group + sm * mma_tile_m >= valid_rows:
                        rmem_scores[None, sm].fill(-Float32.inf)

                # Reduce colmax: scores (g_tile, tiles_sm) -> rmem_M_valid (g_tile,)
                scores = rmem_scores.load()
                rmem_M_valid.store(
                    scores.reduce(
                        cute.ReductionOp.MAX,
                        -Float32.inf,
                        (None, 0),  # Keep mode-0, reduce on mode-1 (tiles_sm)
                    ).reshape((g_tile,))
                )

                # smem_fmax reduces values across all threads that have the same ptr,
                # let i-th thread in each warp store the max value of i-th column.
                lane_max = -Float32.inf
                for j in cutlass.range_constexpr(g_tile):
                    rmem_M[j] = warp_fmax(rmem_M[j])
                    if j == lane_idx:
                        lane_max = rmem_M[j]
                lane_max *= scale_s_log2_e

                # Only one softmax phase may update the shared smem_M buffer at
                # a time, and correction must finish reading the previous value
                # before we publish the new one
                phase_M_acquire_nbar.arrive_and_wait()
                M_consumer_nbar.arrive_and_wait()
                if lane_store_max:
                    smem_M_ptr = smem_M.iterator + smem_M.layout(lane_idx)
                    smem_fmax(smem_M_ptr, lane_max)

                M_producer_nbar.arrive_and_wait()
                cute.autovec_copy(smem_M, rmem_M)
                phase_M_release_nbar.arrive()

                # Acquire P before computing probs so the f32 result can be
                # converted and published as soon as it is produced.
                _, p_idx = P_pipe.producer_acquire_and_get_stage(token=p_token)

                # Compute probs: scores (g_tile, tiles_sm) -> M (g_tile, 1)
                rmem_colmax = rmem_M_valid.load().reshape((g_tile, 1))
                probs = exp2(scale_s_log2_e * scores - rmem_colmax)

                if cutlass.const_expr(g_tile < mma_tile_n):
                    rmem_P.fill(self.dtype(0))

                # Publish P: probs -> rmem_P -> smem_P_view
                rmem_probs.store(probs.to(self.dtype))
                smem_P_view = cute.make_tensor(
                    smem_P[None, None, None, p_idx].iterator, smem_P_view_layout
                )
                cute_ext.partition_and_copy(thr_r2s_copy_P, rmem_P, smem_P_view)
                cute.arch.fence_view_async_shared()
                P_pipe.producer_commit_and_advance()

                # Reduce colsum: probs (g_tile, tiles_sm) -> rmem_L_valid (g_tile,)
                rmem_L_valid.store(
                    probs.reduce(
                        cute.ReductionOp.ADD,
                        Float32(0.0),
                        (None, 0),  # Keep mode-0, reduce on mode-1 (tiles_sm)
                    ).reshape((g_tile,))
                )

                # Publish L: rmem_L -> tmem_L_phase
                phase_L_consumer_nbar.arrive_and_wait()
                cute_ext.partition_and_copy(thr_r2t_copy, rmem_L, tmem_L_phase)
                cute.arch.fence_view_async_tmem_store()
                phase_L_producer_nbar.arrive()

                # Advance by one extra stage so this phase continues walking only
                # its own parity of sequence iterations
                S_pipe.consumer_state = S_pipe.increment_state(S_pipe.consumer_state)
                P_pipe.producer_state = P_pipe.increment_state(P_pipe.producer_state)

        # Correction retires rolling O/L TMEM slots and publishes final M/L/O partials.
        elif warpgroup_idx == correction_warpgroup_id:
            if cutlass.const_expr(use_reg_reconfig):
                cute.arch.setmaxregister_increase(correction_regs)

            # Correction data flow:
            # smem_M -> M_prev2/M_prev/M_cur: rolling per-head maxima
            # tmem_L_phase -> rmem_L: current live colsum, shape rmem_vec_layout
            # rmem_L_acc: retired-history colsum, shape rmem_vec_layout x O_stages
            # tmem_O_phase -> rmem_O_acc -> tmem_O_phase: rescale retired O slots
            # final two tmem_O phases -> rmem_O_tail -> smem_O_tma: staged final O
            # rmem_vec_layout: padded vector, shape ((g_tile,1),1,mma_tile_n//g_tile)
            L_slot_layout_shape = (*rmem_vec_layout.shape, self.O_stages)
            L_slot_layout_stride = (*rmem_vec_layout.stride, rmem_vec_size)
            rmem_L_slot_layout = cute.make_layout(
                L_slot_layout_shape, stride=L_slot_layout_stride
            )
            # rmem_L: current live colsum loaded from TMEM
            rmem_L = rmem_alloc(self.acc_dtype, rmem_vec_layout)
            # rmem_L_final: final colsum after merging retired and live phases
            rmem_L_final = rmem_alloc(self.acc_dtype, rmem_vec_layout)
            # rmem_corr: per-head correction factor exp2(M_old - M_new)
            rmem_corr = rmem_alloc(self.acc_dtype, rmem_vec_layout)
            # rmem_L_acc: retired-history colsum accumulator, one slot per phase
            rmem_L_acc = rmem_alloc(self.acc_dtype, rmem_L_slot_layout)

            rmem_L_acc.fill(Float32(0.0))
            iters_s = cute.ceil_div(s_blks - cta_s, kv_splits)

            # Seed both rolling O slots with zero. Also seed the odd L slot so the
            # `iters_s == 1` tail can still consume a dummy previous phase.
            rmem_zero = rmem_alloc(self.acc_dtype, rmem_vec_layout)
            rmem_zero.fill(Float32(0.0))
            for phase in cutlass.range_constexpr(self.O_stages):
                for dm in cutlass.range_constexpr(tiles_dm):
                    tmem_O_sliced = tmem_O[(None, None), 0, 0, dm, phase]
                    cute_ext.partition_and_copy(thr_r2t_copy, rmem_zero, tmem_O_sliced)
            tmem_L_stage1 = tmem_L[(None, None), 0, 0, 1]
            cute_ext.partition_and_copy(thr_r2t_copy, rmem_zero, tmem_L_stage1)
            cute.arch.fence_view_async_tmem_store()

            # Initialize consumer barriers so softmax can proceed on the first iteration.
            M_consumer_nbar.arrive()
            for phase in cutlass.range_constexpr(SOFTMAX_WARPGROUPS):
                with_phase(L_consumer_nbar, phase).arrive()

            # Preload the first two maxima. After this, `M_prev2` / `M_prev`
            # hold the two live max values that bracket the rolling window tail.
            M_prev2, M_prev = -Float32.inf, -Float32.inf
            for preload_idx in cutlass.range_constexpr(self.O_stages):
                M_prev2 = M_prev
                if not (preload_idx == 1 and iters_s == 1):
                    M_producer_nbar.arrive_and_wait()
                    M_prev = Float32(0.0)
                    if lane_store_max:
                        M_prev = smem_M[lane_idx]
                    M_consumer_nbar.arrive()

            phase = 0
            for s in cutlass.range(iters_s - self.O_stages, unroll=self.O_stages):
                # Load colsum of s-2 and notify softmax
                with_phase(L_producer_nbar, phase).arrive_and_wait()
                tmem_L_phase = tmem_L[(None, None), 0, 0, phase]
                cute_ext.partition_and_copy(thr_t2r_copy, tmem_L_phase, rmem_L)
                cute.arch.fence_view_async_tmem_load()
                with_phase(L_consumer_nbar, phase).arrive()

                # Load colmax of s
                M_producer_nbar.arrive_and_wait()
                if s == iters_s - self.O_stages - 1:
                    M_final_nbar.arrive()
                M_cur = Float32(0.0)
                if lane_store_max:
                    M_cur = smem_M[lane_idx]
                M_consumer_nbar.arrive()

                o_token = O_pipe.consumer_try_wait()
                _, _o_idx = O_pipe.consumer_wait_and_get_stage(token=o_token)

                # Compute correction of s-2
                rmem_corr_lane = exp2(M_prev2 - M_cur)
                for gi in cutlass.range_constexpr(g_tile):
                    rmem_corr[gi] = cute.arch.shuffle_sync(rmem_corr_lane, gi)

                # Correct O of s-2 and notify MMA VP
                for dm in cutlass.range_constexpr(tiles_dm):
                    tmem_O_sliced = tmem_O[(None, None), 0, 0, dm, phase]
                    rmem_O_acc = rmem_alloc(self.acc_dtype, rmem_vec_layout)
                    cute_ext.partition_and_copy(thr_t2r_copy, tmem_O_sliced, rmem_O_acc)
                    cute.arch.fence_view_async_tmem_load()
                    rmem_O_acc.store(rmem_O_acc.load() * rmem_corr.load())
                    cute_ext.partition_and_copy(thr_r2t_copy, rmem_O_acc, tmem_O_sliced)
                cute.arch.fence_view_async_tmem_store()
                O_pipe.consumer_release_and_advance()

                # Correct colsum of s-2
                rmem_L_acc_phase = rmem_L_acc[None, None, None, phase]
                rmem_L.store(rmem_L.load() * rmem_corr.load())
                rmem_L_acc_phase.store(
                    rmem_L_acc_phase.load() * rmem_corr.load() + rmem_L.load()
                )

                # Advance loop
                M_prev2, M_prev = M_prev, M_cur
                phase ^= 1

            # Final M is published only after correction owns the last live max state.
            if iters_s <= self.O_stages:
                M_final_nbar.arrive()

            # Compute correction of s-1
            rmem_corr_lane = exp2(M_prev2 - M_prev)
            for gi in cutlass.range_constexpr(g_tile):
                rmem_corr[gi] = cute.arch.shuffle_sync(rmem_corr_lane, gi)

            # Load colsum of s-1 and s. `tail_phase` is the physical slot that
            # now holds logical `s-1`; the other slot holds logical `s`.
            tail_phase = iters_s % self.O_stages
            for phase in cutlass.range_constexpr(self.O_stages):
                if tail_phase == phase:
                    final_phase = phase ^ 1

                    with_phase(L_producer_nbar, phase).arrive_and_wait()
                    tmem_L_phase = tmem_L[(None, None), 0, 0, phase]
                    cute_ext.partition_and_copy(thr_t2r_copy, tmem_L_phase, rmem_L)
                    cute.arch.fence_view_async_tmem_load()
                    with_phase(L_consumer_nbar, phase).arrive()

                    with_phase(L_producer_nbar, final_phase).arrive_and_wait()
                    tmem_L_final_phase = tmem_L[(None, None), 0, 0, final_phase]
                    cute_ext.partition_and_copy(
                        thr_t2r_copy, tmem_L_final_phase, rmem_L_final
                    )
                    cute.arch.fence_view_async_tmem_load()
                    with_phase(L_consumer_nbar, final_phase).arrive()

                    rmem_L.store(
                        rmem_L.load() + rmem_L_acc[None, None, None, phase].load()
                    )
                    rmem_L_final.store(
                        rmem_L_final.load()
                        + rmem_L_acc[None, None, None, final_phase].load()
                        + rmem_corr.load() * rmem_L.load()
                    )

            # Reduce one final colsum per logical column and publish the warpgroup
            # partials for the reduction warp
            for gi in cutlass.range_constexpr(g_tile):
                rmem_L_final[gi] = cute.arch.warp_reduction_sum(rmem_L_final[gi])
                if lane_idx == 0:
                    smem_L_ps[warpgroup_widx, gi] = rmem_L_final[gi]
            L_final_nbar.arrive()

            if cutlass.const_expr(self.do_atomic_red):
                # The reduction warp reuses smem_M to publish this split's final
                # scale exp2(M_part - M_final) / L_final. Apply it before the
                # TMA reduce-store so atomic ADD accumulates normalized O.
                M_final_nbar.arrive_and_wait()
                cute.autovec_copy(smem_M, rmem_L)

            # rmem_O_tail: final two live O slots, shape
            # rmem_vec_layout x tiles_dm x O_stages.
            O_slot_layout_shape = (*rmem_vec_layout.shape, tiles_dm, self.O_stages)
            O_slot_layout_stride = (
                *rmem_vec_layout.stride,
                rmem_vec_size,
                tiles_dm * rmem_vec_size,
            )
            rmem_O_slot_layout = cute.make_layout(
                O_slot_layout_shape, stride=O_slot_layout_stride
            )
            rmem_O_tail = rmem_alloc(self.acc_dtype, rmem_O_slot_layout)
            for s in cutlass.range_constexpr(self.O_stages):
                phase = tail_phase ^ s
                o_token = O_pipe.consumer_try_wait()
                _, _o_idx = O_pipe.consumer_wait_and_get_stage(token=o_token)
                cute_ext.partition_and_copy(
                    thr_t2r_copy,
                    tmem_O[(None, None), 0, 0, None, phase],
                    rmem_O_tail[(None, None), None, None, None, s],
                )
                cute.arch.fence_view_async_tmem_load()
                O_pipe.consumer_release_and_advance()

            # Finish the numerator merge for the last two live blocks:
            # O_final = O_s + alpha * O_{s-1}, then stage it for the final store.
            rmem_O_tail_0 = rmem_O_tail[None, None, None, None, 0].load()
            rmem_O_tail_1 = rmem_O_tail[None, None, None, None, 1].load()
            rmem_O_tail_0 = rmem_O_tail_0.reshape((rmem_vec_size, tiles_dm))
            rmem_O_tail_1 = rmem_O_tail_1.reshape((rmem_vec_size, tiles_dm))
            rmem_O_final = (
                rmem_O_tail_1
                + rmem_corr.load().reshape((rmem_vec_size, 1)) * rmem_O_tail_0
            )
            if cutlass.const_expr(self.do_atomic_red):
                rmem_O_final *= rmem_L.load().reshape((rmem_vec_size, 1))
            # Follows the same usage as cute_ext.partition_and_copy but without using
            # an extra rmem buffer as the src argument of cute_ext.partition_and_copy
            smem_O_partitioned = cute_ext.partition(
                smem_O_tma[None, None, None, 0],
                thr_r2s_copy_O.thr_idx,
                layout_tv=thr_r2s_copy_O.layout_dst_tv_tiled,
                tiler=cute.core._pack_tile(thr_r2s_copy_O.tiler_mn),
            )
            smem_O_partitioned.store(
                rmem_O_final.to(gmem_O_store.element_type).reshape(
                    smem_O_partitioned.shape
                )
            )

            # Publish the finalized O tile to SMEM before the TMA/QO warp
            # consumes it for the GMEM store
            cute.arch.fence_view_async_shared()
            O_final_nbar.arrive()

        if warp_idx == reduction_warp_id:
            if cutlass.const_expr(self.do_kernel_red):
                assert gmem_M_part is not None
                assert gmem_L_part is not None
                assert gmem_M_final is not None
                self.reduction_epilogue(
                    g_tile,
                    (cta_s, cta_h, cta_l),
                    lane_idx,
                    M_final_nbar,
                    L_final_nbar,
                    smem_M,
                    smem_L_ps,
                    gmem_M_part,
                    gmem_L_part,
                    gmem_M_final,
                )
            else:
                smem_M_atomic = cute.make_tensor(
                    smem_M.iterator,
                    cute.make_layout(shape=(g_tile,), stride=(1,)),
                )
                smem_L_atomic = cute.make_tensor(
                    smem_L_ps.iterator,
                    cute.make_layout(
                        shape=(g_tile, warpgroup_warps), stride=(1, g_tile)
                    ),
                )
                self.reduction_atomic(
                    g_tile,
                    kv_splits,
                    cta_s,
                    lane_idx,
                    M_final_nbar,
                    L_final_nbar,
                    reduction_mbars_ptr,
                    smem_M_atomic,
                    smem_L_atomic,
                    smem_R,
                )
            cute.arch.griddepcontrol_launch_dependents()

    @staticmethod
    @cute.jit
    def reduction_epilogue(
        g_tile: int,
        block_idx: Tuple[Int32, Int32, Int32],
        lane_idx: Int32,
        M_final_nbar,
        L_final_nbar,
        smem_M: cute.Tensor,
        smem_L_ps: cute.Tensor,
        gmem_M_part: cute.Tensor,
        gmem_L_part: cute.Tensor,
        gmem_M_final: cute.Tensor,
    ):
        cta_s, cta_h, cta_l = block_idx

        ML_part_tiler = (1, g_tile)
        ML_part_coord = (cta_s, cta_h, cta_l)
        gmem_M_part_local = cute.local_tile(gmem_M_part, ML_part_tiler, ML_part_coord)
        gmem_L_part_local = cute.local_tile(gmem_L_part, ML_part_tiler, ML_part_coord)
        M_final_tiler = (g_tile,)
        M_final_coord = (cta_h, cta_l)
        gmem_M_final_local = cute.local_tile(gmem_M_final, M_final_tiler, M_final_coord)

        lane_store_max = lane_idx < g_tile
        lane_store_max &= cta_h * g_tile + lane_idx < gmem_M_final.shape[0]

        cute.arch.fence_acq_rel_cta()  # Keep local tiling ordered after the barriers
        M_final_nbar.arrive_and_wait()
        if lane_store_max:
            M_lane = smem_M[lane_idx]
            gmem_M_part_local[0, lane_idx] = M_lane
            gmem_M_ptr = gmem_M_final_local.iterator + gmem_M_final_local.layout(
                lane_idx
            )
            gmem_fmax(gmem_M_ptr, M_lane)

        L_final_nbar.arrive_and_wait()
        if lane_store_max:
            l_sum01 = smem_L_ps[0, lane_idx] + smem_L_ps[1, lane_idx]
            l_sum23 = smem_L_ps[2, lane_idx] + smem_L_ps[3, lane_idx]
            gmem_L_part_local[0, lane_idx] = l_sum01 + l_sum23

    @staticmethod
    @cute.jit
    def reduction_atomic(
        g_tile: int,
        kv_splits: Int32,
        kv_split_idx: Int32,
        lane_idx: Int32,
        M_final_nbar,
        L_final_nbar,
        reduction_mbars_ptr,
        smem_M: cute.Tensor,
        smem_L: cute.Tensor,
        smem_R: cute.Tensor,
    ):
        colmax_bits = g_tile * Float32.width
        copy_vec_bits = min(colmax_bits, 128)
        dsmem_store_threads = colmax_bits // copy_vec_bits
        dsmem_store_values = copy_vec_bits // Float32.width
        dsmem_store_atom = cute.make_copy_atom(
            cute.nvgpu.cpasync.CopyDsmemStoreOp(),
            Float32,
            num_bits_per_copy=copy_vec_bits,
        )
        dsmem_store_tv_shape = (dsmem_store_threads, dsmem_store_values)
        dsmem_store = cute.make_tiled_copy(
            dsmem_store_atom,
            cute.make_ordered_layout(dsmem_store_tv_shape, order=(1, 0)),
            (g_tile,),
        )
        thr_store = dsmem_store.get_slice(lane_idx)
        thr_smem_M = thr_store.partition_S(smem_M)  # (CPY, #CPY)
        thr_smem_L = thr_store.partition_S(smem_L)  # (CPY, #CPY, warpgroup_warps)
        thr_smem_R = thr_store.partition_S(smem_R)  # (CPY, #CPY, max_red_iters, 2)
        # CPY == number of elements to copy at each time == (dsmem_store_values, 1)
        # #CPY == number of copies to make == (1, )

        rmem_M_shape = thr_store.partition_D(smem_M).shape
        rmem_M_final = cute.make_rmem_tensor(rmem_M_shape, Float32)
        rmem_M_part = cute.make_rmem_tensor(rmem_M_shape, Float32)

        # 1. Wait for correction to publish this split's local running max, then
        # perform a cluster butterfly max-reduction to get M_final for every split
        cute.arch.fence_acq_rel_cta()
        M_final_nbar.arrive_and_wait()
        is_reduction_lane = lane_idx < dsmem_store_threads
        if is_reduction_lane:
            rmem_M_part.store(thr_smem_M.load())
            rmem_M_final.store(rmem_M_part.load())

            # Cluster butterfly reduction
            for red_iter in cutlass.range_constexpr(MAX_REDUCTION_ITERS):
                xor_mask = 0x01 << red_iter
                if xor_mask < kv_splits:
                    peer_idx = kv_split_idx ^ xor_mask
                    thr_smem_R_local = thr_smem_R[None, None, red_iter, 0]
                    thr_smem_R_peer = cute.make_tensor(
                        cute.arch.map_dsmem_ptr(thr_smem_R_local.iterator, peer_idx),
                        thr_smem_R_local.layout,
                    )
                    local_mbar = reduction_mbars_ptr + red_iter
                    peer_mbar = cute.arch.map_dsmem_ptr(local_mbar, peer_idx)
                    cute.copy(
                        dsmem_store_atom,
                        rmem_M_final,
                        thr_smem_R_peer,
                        mbar_ptr=peer_mbar,
                    )
                    cute.arch.fence_acq_rel_cta()
                    cute.arch.mbarrier_wait(local_mbar, phase=0)
                    rmem_M_peer = thr_smem_R_local.load()
                    for elem_idx in cutlass.range_constexpr(cute.size(rmem_M_final)):
                        rmem_M_final[elem_idx] = cute.arch.fmax(
                            rmem_M_final[elem_idx], rmem_M_peer[elem_idx]
                        )

        # 2. Wait for per-warpgroup L partials, reduce them locally, rescale by
        # exp2(M_part - M_final), then butterfly-sum L across split CTAs.
        L_final_nbar.arrive_and_wait()
        if is_reduction_lane:
            # Warpgroup reduction
            rmem_L_sum = thr_smem_L[None, None, 0].load()
            for warp_id in cutlass.range_constexpr(1, warpgroup_warps):
                rmem_L_sum += thr_smem_L[None, None, warp_id].load()

            # Compute final correction and correct local colsum
            rmem_scale = exp2(rmem_M_part.load() - rmem_M_final.load())
            rmem_scale = rmem_scale.reshape(rmem_L_sum.shape)
            rmem_L_sum *= rmem_scale

            # Cluster butterfly reduction
            for red_iter in cutlass.range_constexpr(MAX_REDUCTION_ITERS):
                xor_mask = 0x01 << red_iter
                if xor_mask < kv_splits:
                    peer_idx = kv_split_idx ^ xor_mask
                    rmem_L_local = cute.make_rmem_tensor(rmem_M_shape, Float32)
                    rmem_L_local.store(rmem_L_sum)
                    thr_smem_R_local = thr_smem_R[None, None, red_iter, 1]
                    thr_smem_R_peer = cute.make_tensor(
                        cute.arch.map_dsmem_ptr(thr_smem_R_local.iterator, peer_idx),
                        thr_smem_R_local.layout,
                    )
                    local_mbar = reduction_mbars_ptr + MAX_REDUCTION_ITERS + red_iter
                    peer_mbar = cute.arch.map_dsmem_ptr(local_mbar, peer_idx)
                    cute.copy(
                        dsmem_store_atom,
                        rmem_L_local,
                        thr_smem_R_peer,
                        mbar_ptr=peer_mbar,
                    )
                    cute.arch.fence_acq_rel_cta()
                    cute.arch.mbarrier_wait(local_mbar, phase=0)
                    rmem_L_sum += thr_smem_R_local.load()

            # 3. Publish this split's final scale back through smem_M:
            # exp2(M_part - M_final) / L_final. Correction applies this before
            # the TMA reduce-store of O.
            rmem_inv_L_final = cute.make_rmem_tensor(rmem_L_sum.shape, Float32)
            for elem_idx in cutlass.range(cute.size(rmem_L_sum.shape)):
                rmem_inv_L_final[elem_idx] = cute.arch.rcp_approx(rmem_L_sum[elem_idx])
            thr_smem_M.store(rmem_scale * rmem_inv_L_final.load())

        # 4. Signal correction that smem_M now contains the final O scale.
        M_final_nbar.arrive()

    @cute.experimental.kernel
    def reduction_kernel(
        self,
        gmem_O_part: cute.Tensor,  # (d, h_q, b, kv_splits)
        gmem_M_part: cute.Tensor,  # (kv_splits, h_q, b), per-CTA running max
        gmem_L_part: cute.Tensor,  # (kv_splits, h_q, b), per-CTA running sum
        gmem_M_final: cute.Tensor,  # (h_q, b), final colmax reduced by decode epilogue
        gmem_O_final: cute.Tensor,  # (d, h_q, b)
        reduction_kv_splits: Int32,
    ):
        d_blk_idx, coord_h, coord_b = cute.arch.block_idx()
        tidx, _, _ = cute.arch.thread_idx()
        d_per_blk = self.head_dim
        d_per_thr = 32 // self.dtype.width
        thr_per_blk = d_per_blk // d_per_thr
        d, _h, _b, _splits = gmem_O_part.shape
        not_oob_d = True
        if d % d_per_blk != 0:
            not_oob_d = d_blk_idx * d_per_blk + tidx * d_per_thr < d

        d_tiler = (d_per_blk,)
        coord_O = (d_blk_idx, coord_h, coord_b, None)
        gmem_O_final_tile = cute.local_tile(gmem_O_final, d_tiler, coord_O[:3])
        # Per-block `O_part` tile for this (head, batch), shape:
        # (d_per_blk, reduction_kv_splits)
        gmem_O_part_tile = cute.local_tile(gmem_O_part, d_tiler, coord_O)

        coord_m = (None, coord_h, coord_b)
        # gmem_M_final_local.shape = (1,)
        # gmem_{M,L}_part.shape = (1, kv_splits)
        gmem_M_final_local = cute.local_tile(gmem_M_final, (1,), coord_m[1:])
        gmem_M_part_local = cute.local_tile(gmem_M_part, (1,), coord_m)
        gmem_L_part_local = cute.local_tile(gmem_L_part, (1,), coord_m)

        smem_ptr = cute.arch.get_dyn_smem(Float32)
        partial_layout = cute.make_layout((1, reduction_kv_splits))
        offset = reduction_kv_splits
        # smem_{M,L}_part.shape = (1, reduction_kv_splits)
        # smem_M_final.shape = (1,)
        smem_M_part = cute.make_tensor(smem_ptr, partial_layout)
        smem_L_part = cute.make_tensor(smem_ptr + offset, partial_layout)
        smem_M_final = cute.make_tensor(smem_ptr + 2 * offset, cute.make_layout(1))

        copy_atom = cute.make_copy_atom(cute.nvgpu.CopyUniversalOp(), Float32)
        tv_layout = cute.make_ordered_layout((thr_per_blk, d_per_thr), order=(1, 0))
        tiled_copy = cute.make_tiled_copy(copy_atom, tv_layout, (d_per_blk,))
        thr_copy = tiled_copy.get_slice(tidx)

        thr_gmem_O_part = thr_copy.partition_S(gmem_O_part_tile)
        thr_gmem_O_part = thr_gmem_O_part[None, 0, None]  # (d_per_thr, splits)
        thr_gmem_O_final = thr_copy.partition_D(gmem_O_final_tile)
        thr_gmem_O_final = thr_gmem_O_final[None, 0]  # (d_per_thr, )
        rmem_O_final = cute.zeros_like(thr_gmem_O_final, Float32)

        cute.arch.fence_acq_rel_cta()  # Keep shared-memory views ordered after the PDL wait
        cute.arch.griddepcontrol_wait()

        if tidx == 0:
            # smem_M_final[0] = gmem_M_final_local[0]
            cute_ext.simt_auto_vec_copy(gmem_M_final_local, smem_M_final, async_op=True)

        if tidx < reduction_kv_splits:
            # smem_L_part[0, tidx] = gmem_L_part_local[0, tidx]
            # smem_M_part[0, tidx] = gmem_M_part_local[0, tidx]
            cute_ext.simt_auto_vec_copy(
                gmem_L_part_local[None, tidx], smem_L_part[None, tidx], async_op=True
            )
            cute_ext.simt_auto_vec_copy(
                gmem_M_part_local[None, tidx], smem_M_part[None, tidx], async_op=True
            )

        for split_idx in cutlass.range(
            thr_per_blk + tidx, reduction_kv_splits, thr_per_blk
        ):
            # smem_L_part[0, split_idx] = gmem_L_part_local[0, split_idx]
            # smem_M_part[0, split_idx] = gmem_M_part_local[0, split_idx]
            cute_ext.simt_auto_vec_copy(
                gmem_L_part_local[None, split_idx],
                smem_L_part[None, split_idx],
                async_op=True,
            )
            cute_ext.simt_auto_vec_copy(
                gmem_M_part_local[None, split_idx],
                smem_M_part[None, split_idx],
                async_op=True,
            )

        cute.arch.cp_async_commit_group()
        cute.arch.cp_async_wait_group(0)
        cute.arch.sync_threads()

        max_final = smem_M_final[0]
        sum_final = Float32(0)
        if max_final > -Float32.inf and not_oob_d:
            for split_idx in cutlass.range(reduction_kv_splits, unroll=8):
                max_part = smem_M_part[0, split_idx]
                if max_part > -Float32.inf:
                    correction = exp2(max_part - max_final)
                    sum_final += correction * smem_L_part[0, split_idx]
                    rmem_O_final += correction * thr_gmem_O_part[None, split_idx].load()
            rmem_O_final *= cute.arch.rcp_approx(sum_final)

        cute.arch.griddepcontrol_launch_dependents()

        if not_oob_d:
            thr_gmem_O_final.store(rmem_O_final.to(gmem_O_final.element_type))


def resolve_reduction_mode(reduction_mode, o_dtype, kv_splits):
    if reduction_mode == "auto":
        atomic_valid_o_dtypes = (cutlass.Float32, cutlass.Float16, cutlass.BFloat16)
        if o_dtype in atomic_valid_o_dtypes and kv_splits in (1, 2, 4, 8):
            return "atomic"
        return "kernel"
    if reduction_mode not in ("kernel", "atomic"):
        raise ValueError(
            f"reduction_mode must be 'kernel', 'atomic', or 'auto', got {reduction_mode}"
        )
    return reduction_mode


def run_gqa_decode(
    Q,
    K,
    V,
    O_part,
    M_part,
    L_part,
    M_final,
    O_final,
    seq_tile,
    g_tile,
    decode_grid,
    warmup_iter=0,
    bench_iter=0,
    reduction_mode="auto",
    use_cold_l2=False,
):
    b, h_q, d = Q.shape
    _b, h_k, s_k, _d = K.shape
    g = h_q // h_k
    assert h_q == h_k * g
    problem_shape = (b, h_q, h_k, s_k, d)

    def maybe_from_dlpack(tensor):
        return (
            from_dlpack(tensor.detach(), assumed_align=16)
            if tensor is not None
            else None
        )

    dtype = torch_cutlass_dtype_map[Q.dtype]
    reduction_mode = resolve_reduction_mode(reduction_mode, dtype, decode_grid[0])
    if reduction_mode == "kernel":
        if O_part is None or M_part is None or L_part is None or M_final is None:
            raise ValueError(
                "kernel reduction expects O_part, M_part, L_part, and M_final workspaces"
            )
        for name, workspace in (
            ("O_part", O_part),
            ("M_part", M_part),
            ("L_part", L_part),
            ("M_final", M_final),
        ):
            if workspace.dtype != torch.float32:
                raise TypeError(
                    f"kernel reduction expects {name} dtype torch.float32, got {workspace.dtype}"
                )
    # Atomic reduction accumulates split contributions directly into O_final,
    # must zero it out for correctness
    if reduction_mode == "atomic":
        O_final.zero_()
    elif M_final is not None:
        M_final.fill_(-math.inf)
    gmem_Q = from_dlpack(Q.detach(), assumed_align=16)
    gmem_K = from_dlpack(K.detach(), assumed_align=16)
    gmem_V = from_dlpack(V.detach(), assumed_align=16)
    gmem_O_part = maybe_from_dlpack(O_part)
    gmem_M_part = maybe_from_dlpack(M_part)
    gmem_L_part = maybe_from_dlpack(L_part)
    gmem_M_final = maybe_from_dlpack(M_final)
    gmem_O_final = from_dlpack(O_final.detach(), assumed_align=16)
    scale_s_log2_e = 1.0 / math.sqrt(d) * LOG2_E

    gqa_decode = GroupedQueryAttentionDecode(
        g_tile=g_tile,
        seq_tile=seq_tile,
        head_dim=d,
        dtype=dtype,
        decode_grid=decode_grid,
        reduction_mode=reduction_mode,
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
        gmem_M_final,
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
        gmem_M_final,
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
        o_part_torch = torch.empty_like(O_part) if O_part is not None else None
        m_part_torch = torch.empty_like(M_part) if M_part is not None else None
        l_part_torch = torch.empty_like(L_part) if L_part is not None else None
        m_final_torch = (
            torch.full_like(M_final, -math.inf) if M_final is not None else None
        )
        o_final_torch = (
            torch.zeros_like(O_final)
            if reduction_mode == "atomic"
            else torch.empty_like(O_final)
        )

        q_cute = from_dlpack(q_torch.detach(), assumed_align=16)
        k_cute = from_dlpack(k_torch.detach(), assumed_align=16)
        v_cute = from_dlpack(v_torch.detach(), assumed_align=16)
        o_part_cute = maybe_from_dlpack(o_part_torch)
        m_part_cute = maybe_from_dlpack(m_part_torch)
        l_part_cute = maybe_from_dlpack(l_part_torch)
        m_final_cute = maybe_from_dlpack(m_final_torch)
        o_final_cute = from_dlpack(o_final_torch.detach(), assumed_align=16)

        jit_args = testing.JitArguments(
            problem_shape,
            q_cute,
            k_cute,
            v_cute,
            o_part_cute,
            m_part_cute,
            l_part_cute,
            m_final_cute,
            o_final_cute,
            scale_s_log2_e,
            profile_stream,
        )
        return jit_args

    # Cycling through enough freshly allocated workspaces evicts the previous
    # iteration's K/V from L2, so every timed iteration reads them from DRAM.
    # The split-K workspaces are absent in atomic mode, hence the None filter.
    workspace_count = 1
    if use_cold_l2:
        one_workspace_bytes = sum(
            t.nbytes
            for t in (Q, K, V, O_part, M_part, L_part, M_final, O_final)
            if t is not None
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


def compute_gqa_decode_grid(b, h_q, h_k, s_k, reduction_mode="auto"):
    g = h_q // h_k
    # Match the reference grouped-head tiling heuristic for fp16/bf16 deterministic
    # mode: choose the smallest power-of-two tile that covers the true grouped-head
    # count, capped at 32. Small grouped-head cases can now keep g_tile < 8.
    g_tile = min(next_power_of_2(g), 32)
    h_blks = (g + g_tile - 1) // g_tile
    l_blks = b * h_k
    hardware_info = cutlass.utils.HardwareInfo()
    sm_count = hardware_info.get_device_multiprocessor_count()
    sm_count = 148 if sm_count <= 0 else sm_count
    kv_splits = sm_count // (h_blks * l_blks)  # 1 wave
    kv_splits = max(1, kv_splits)
    if sm_count == 148 and h_blks * l_blks == 32:
        kv_splits = 9  # 2 waves
    # Keep the deterministic split heuristic in line with the reference path:
    # cap oversplitting so each split still covers about 256 K/V tokens on average
    kv_splits = min(kv_splits, math.ceil(s_k / 256))
    if reduction_mode == "atomic" and kv_splits not in (1, 2, 4):
        kv_splits = 8
    return (kv_splits, g_tile, h_blks, l_blks)


def main():
    parser = argparse.ArgumentParser(description="cute_ext GQA flash decode demo.")
    parser.add_argument("--batch_size", "--b", type=int, default=1)
    parser.add_argument("--num_q_heads", "--h_q", type=int, default=64)
    parser.add_argument("--num_kv_heads", "--h_k", type=int, default=8)
    parser.add_argument("--seq_len", "--s", type=int, default=1024)
    parser.add_argument("--head_dim", "--d", type=int, default=128)
    parser.add_argument("--seq_tile", type=int, default=256)
    parser.add_argument("--dtype", choices=["fp16", "bf16"], default="bf16")
    parser.add_argument(
        "--reduction", choices=["kernel", "atomic", "auto"], default="auto"
    )
    parser.add_argument("--atol", type=float, default=2e-2)
    parser.add_argument("--rtol", type=float, default=2e-2)
    parser.add_argument("--warmup_iter", type=int, default=10)
    parser.add_argument("--bench_iter", type=int, default=100)
    parser.add_argument("--use_cold_l2", action="store_true", help="Use cold L2")
    args = parser.parse_args()
    cuda.cuInit(0)
    torch.manual_seed(33550336)
    dtype = torch.float16 if args.dtype == "fp16" else torch.bfloat16

    b, hq, d = args.batch_size, args.num_q_heads, args.head_dim
    hkv, skv = args.num_kv_heads, args.seq_len
    g = hq // hkv
    seq_tile = args.seq_tile

    kv_splits, g_tile, h_blks, l_blks = compute_gqa_decode_grid(
        b, hq, hkv, skv, args.reduction
    )
    reduction_mode = resolve_reduction_mode(
        args.reduction, torch_cutlass_dtype_map[dtype], kv_splits
    )

    print("Problem size and paramaters:")
    print(f"    batch size      = {b}")
    print(f"    num_q_heads     = {hq}")
    print(f"    num_kv_heads    = {hkv}")
    print(f"    head_group_size = {g}")
    print(f"    kv_seqlen       = {skv}")
    print(f"    head_dim        = {d}")
    print(f"    seq_tile        = {seq_tile}")
    print(f"    QKVO dtype      = {dtype}")
    print(f"    reduction mode  = {reduction_mode}")
    print(f"    kv_splits       = {kv_splits}")
    print(f"    use cold L2     = {args.use_cold_l2}")

    Q = torch.randn((b, hq, d), device="cuda", dtype=dtype)
    K = torch.randn((b, hkv, skv, d), device="cuda", dtype=dtype)
    V = torch.randn((b, hkv, skv, d), device="cuda", dtype=dtype)

    Q_sdpa = Q.unsqueeze(2)
    O_torch = F.scaled_dot_product_attention(Q_sdpa, K, V, enable_gqa=True)
    O_torch = O_torch.squeeze(2)
    print("Reference PyTorch scaled_dot_product_attention() completed.")

    O_final = torch.empty((b, hq, d), device=Q.device, dtype=Q.dtype)
    if reduction_mode == "kernel":
        O_part = torch.empty(
            (kv_splits, b, hq, d), device=Q.device, dtype=torch.float32
        )
        M_part = torch.empty((b, hq, kv_splits), device="cuda", dtype=torch.float32)
        L_part = torch.empty((b, hq, kv_splits), device="cuda", dtype=torch.float32)
        M_final = torch.full((b, hq), -math.inf, device="cuda", dtype=torch.float32)
    else:
        O_part = None
        M_part = None
        L_part = None
        M_final = None
    runtime_us, terabytes_per_s, teraflops_per_s = run_gqa_decode(
        Q,
        K,
        V,
        O_part,
        M_part,
        L_part,
        M_final,
        O_final,
        seq_tile,
        g_tile,
        (kv_splits, h_blks, l_blks),
        args.warmup_iter,
        args.bench_iter,
        reduction_mode,
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
    seq_tile: int = 256,
    reduction_mode: str = "auto",
    tolerance: float = 2e-2,
    warmup_iterations: int = 0,
    iterations: int = 0,
    skip_ref_check: bool = False,
    use_cold_l2: bool = False,
    **kwargs,
):
    """Run and benchmark the optimized GQA flash-decode kernel on Blackwell.

    Args:
        batches/seqlen/heads_q/heads_k/headdim: Decode problem shape (s_q == 1).
        q_dtype/kv_dtype/o_dtype: Must all be the same 16-bit float type.
        acc_dtype: Accumulator type. The kernel always accumulates in Float32,
            so Float32 is the only accepted value.
        seq_tile: K/V sequence tile.
        reduction_mode: "kernel", "atomic" or "auto" split-K reduction.
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
            type, if acc_dtype is not Float32, or if heads_q is not a multiple
            of heads_k.
        AssertionError: If reference checking is enabled and the output does
            not match PyTorch SDPA within tolerance.
    """
    print("Running Blackwell GQA Flash Decode (optimized) test with:")
    print(f"\tbatches: {batches}, seqlen: {seqlen}")
    print(f"\theads_q: {heads_q}, heads_k: {heads_k}, headdim: {headdim}")
    print(f"\tq_dtype: {q_dtype}, kv_dtype: {kv_dtype}, o_dtype: {o_dtype}")
    print(f"\tacc_dtype: {acc_dtype}, seq_tile: {seq_tile}")
    print(f"\treduction: {reduction_mode}, tolerance: {tolerance}")
    print(f"\twarmup_iterations: {warmup_iterations}, iterations: {iterations}")
    print(f"\tskip_ref_check: {skip_ref_check}, use_cold_l2: {use_cold_l2}")

    if not (q_dtype is kv_dtype is o_dtype):
        raise ValueError(
            "gqa_decode_opt requires q_dtype == kv_dtype == o_dtype, got "
            f"{q_dtype}, {kv_dtype}, {o_dtype}"
        )
    if q_dtype not in _PERF_TORCH_DTYPES:
        raise ValueError(f"gqa_decode_opt supports Float16/BFloat16, got {q_dtype}")

    if acc_dtype is not cutlass.Float32:
        raise ValueError(
            f"gqa_decode_opt only supports acc_dtype=Float32, got {acc_dtype}"
        )
    if heads_q % heads_k != 0:
        raise ValueError(
            f"heads_q ({heads_q}) must be a multiple of heads_k ({heads_k})"
        )

    cuda.cuInit(0)
    torch.manual_seed(33550336)
    dtype = _PERF_TORCH_DTYPES[q_dtype]

    b, hq, hkv, skv, d = batches, heads_q, heads_k, seqlen, headdim
    kv_splits, g_tile, h_blks, l_blks = compute_gqa_decode_grid(
        b, hq, hkv, skv, reduction_mode
    )
    resolved_reduction = resolve_reduction_mode(
        reduction_mode, torch_cutlass_dtype_map[dtype], kv_splits
    )
    print(f"\tkv_splits: {kv_splits}, g_tile: {g_tile}")
    print(f"\tresolved reduction: {resolved_reduction}")

    Q = torch.randn((b, hq, d), device="cuda", dtype=dtype)
    K = torch.randn((b, hkv, skv, d), device="cuda", dtype=dtype)
    V = torch.randn((b, hkv, skv, d), device="cuda", dtype=dtype)

    O_final = torch.empty((b, hq, d), device=Q.device, dtype=Q.dtype)
    if resolved_reduction == "kernel":
        O_part = torch.empty(
            (kv_splits, b, hq, d), device=Q.device, dtype=torch.float32
        )
        M_part = torch.empty((b, hq, kv_splits), device="cuda", dtype=torch.float32)
        L_part = torch.empty((b, hq, kv_splits), device="cuda", dtype=torch.float32)
        M_final = torch.full((b, hq), -math.inf, device="cuda", dtype=torch.float32)
    else:
        O_part = None
        M_part = None
        L_part = None
        M_final = None

    runtime_us, terabytes_per_s, teraflops_per_s = run_gqa_decode(
        Q,
        K,
        V,
        O_part,
        M_part,
        L_part,
        M_final,
        O_final,
        seq_tile,
        g_tile,
        (kv_splits, h_blks, l_blks),
        warmup_iterations,
        iterations,
        reduction_mode,
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
