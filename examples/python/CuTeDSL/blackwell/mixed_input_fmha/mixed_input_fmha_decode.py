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
import enum
import math
import time
from typing import Type, Tuple
from functools import partial

import torch
import torch.nn.functional as F
from torch.nn.functional import scaled_dot_product_attention
from torch.nn.attention import SDPBackend, sdpa_kernel

import cuda.bindings.driver as cuda

import cutlass
import cutlass.cute as cute
import cutlass.cute.nvgpu.tcgen05 as tcgen05
import cutlass.utils as utils
import cutlass.pipeline as pipeline
import cutlass.torch as cutlass_torch
import cutlass.utils.blackwell_helpers as sm100_utils
import cutlass.cute.testing as testing
from cutlass.cute.runtime import from_dlpack
from cutlass.cute.typing import Int32, Int64, Float32, Pointer, AddressSpace

from cutlass._mlir.dialects import nvvm, llvm

# Kernel invariants
mma_modes = (0, 1, 2)
mma_dice = (None, None, None) # (MMA, #MMA_M, #MMA_K)
cpy_dice = (None, *mma_dice) # (CPY, #CPY_MMA, #CPY_M, #CPY_K)
warp_threads = 32
warpgroup_warps = 4
warpgroup_threads = 128

# Math helpers
log2_e = math.log2(math.e) # change exponential base
use_tensor_ssa_math = False # experimental
fadd2 = partial(cute.arch.add_packed_f32x2, ftz=False, rnd=nvvm.FPRoundingMode.RN)
fmul2 = partial(cute.arch.mul_packed_f32x2, ftz=False, rnd=nvvm.FPRoundingMode.RN)
ffma2 = partial(cute.arch.fma_packed_f32x2, ftz=False, rnd=nvvm.FPRoundingMode.RN)
exp2 = partial(cute.math.exp2, fastmath=True)

class MixedInputFusedMultiHeadAttentionDecode:
    def __init__(
        self,
        headdim,
        block_scaledim, # headdim per scale factor; scale factor shape is (batches, heads_k, seqlen, headdim / block_scaledim)
        grouped_head_tile, # GQA packing tile size, can be less than group size
        dual_convert = False, # Dual warpgroups pingponging on convert stages
        deterministic = False, # If True, cluster reduction is disabled
    ):
        self.headdim = headdim
        self.grouped_head_tile = grouped_head_tile
        self.block_scaledim = block_scaledim
        self.scaledim = headdim // block_scaledim
        self.dual_convert = dual_convert
        self.deterministic = deterministic

        assert headdim % block_scaledim == 0
        assert grouped_head_tile % 8 == 0 and 0 < grouped_head_tile <= 32
        
        warpgroup_id = 0

        self.softmax_warpgroup_id = warpgroup_id
        warpgroup_id += 1

        self.cvt_warpgroup_ids = (warpgroup_id, (warpgroup_id+1) if dual_convert else None)
        cvt_warpgroups = 2 if dual_convert else 1
        warpgroup_id += cvt_warpgroups

        # Why 2 MMA+TMA warps when not MMA bound?
        # Less register pressure per warp promotes concise SASS
        # hides MMA 'switching' latency that gets exposed with less concise SASS
        # We would have 2 leftover warps if we do warpgroup reg realloc
        # and less register pressure gives more realloc flexibility
        self.mma_kq_warp_id = warpgroup_id * warpgroup_warps + 0
        self.mma_vp_warp_id = warpgroup_id * warpgroup_warps + 1
        self.tma_kv_warp_id = warpgroup_id * warpgroup_warps + 2
        self.tma_qo_warp_id = warpgroup_id * warpgroup_warps + 3
        self.mma_tma_warpgroup_id = warpgroup_id
        warpgroup_id += 1

        self.threads_per_cta = warpgroup_id * warpgroup_threads

        self.use_reg_reconfig = grouped_head_tile > 16
        max_regs_per_wg_thread = (64*1024 // warpgroup_threads) # 64K regs per SM
        self.mma_tma_regs = 72
        self.cvt_regs = 112
        self.softmax_regs = min(256, max_regs_per_wg_thread - self.mma_tma_regs
                                        - self.cvt_regs * cvt_warpgroups)
        assert (self.mma_tma_regs + self.softmax_regs + 
                self.cvt_regs * cvt_warpgroups) <= max_regs_per_wg_thread

        self.bs_stages = 2
        self.sp_stages = 2
        self.o_stages = 1

    def can_implement(self, problem_shape, kv_splits, kv_cluster_dim, q_dtype, kv_dtype, o_dtype, acc_dtype):
        b, h_q, h_k, s_k, d = problem_shape

        if h_q % h_k != 0:
            raise ValueError(f"heads_q({h_q}) must be a multiple of heads_k({h_k})")
        
        if kv_splits % kv_cluster_dim != 0:
            raise ValueError(f"kv_splits({kv_splits}) must be a multiple of kv_cluster_dim({kv_cluster_dim})")

        if self.deterministic and kv_cluster_dim != 1:
            raise ValueError(f"kv_cluster_dim({kv_cluster_dim}) must be 1 for determinism")
        
        align_scale_bits = 128 # TMA requirement
        if self.scaledim * q_dtype.width < align_scale_bits:
            align_seq = align_scale_bits // (self.scaledim * q_dtype.width)
            if s_k % align_seq != 0:
                raise ValueError(f"seqlen({s_k}) must be a multiple of {align_seq}")

    @cute.jit
    def __call__(
        self,
        problem_shape: Tuple[Int32, Int32, Int32, Int32, Int32], # b, h_q, h_k, s_k, d
        kv_splits: Int32, # threadblocks per sequence
        kv_cluster_dim: Int32, # threadblocks per partial buffer (atomic reduction)
        q_iter: cute.Pointer,
        k_iter: cute.Pointer,
        v_iter: cute.Pointer,
        k_scale_iter: cute.Pointer,
        v_scale_iter: cute.Pointer,
        o_iter: cute.Pointer,
        m_iter: cute.Pointer, # colmax_s, must be -inf initialized
        l_iter: cute.Pointer, # logsumexp
        o_partial_iter: cute.Pointer, # partial O per kv cluster, must be zero initialized if nondeterminism is enabled
        m_partial_iter: cute.Pointer, # partial colmax_s per kv cluster
        l_partial_iter: cute.Pointer, # partial colsum_p per kv cluster, must be zero initialized if nondeterminism is enabled
        scale_qs: Float32,
        scale_o: Float32,
        stream: cuda.CUstream,
    ):
        ##############################
        # TiledMma creation
        ##############################
        mma_dtype = q_iter.dtype
        acc_dtype = o_partial_iter.dtype
        assert acc_dtype is Float32 # don't support other acc types for now

        # Block tile sets the granularity at which threadblocks consume work
        blk_tile_s = 128
        blk_tile_h = self.grouped_head_tile
        blk_tile_d = self.headdim
        blk_tile_shd = (blk_tile_s, blk_tile_h, blk_tile_d)

        # MMA tile sets the granularity at which TMAs + MMAs are issued
        mma_tile_m = 128
        mma_tile_n = self.grouped_head_tile
        mma_tile_k = 128 if self.headdim % 128 == 0 else 64
        mma_tile_mnk = (mma_tile_m, mma_tile_n, mma_tile_k)
        assert self.headdim % mma_tile_k == 0

        # GEMM1: (S_K, H_R, D, (H_K, B))
        tiled_mma_kq = sm100_utils.make_trivial_tiled_mma(
            mma_dtype,
            tcgen05.OperandMajorMode.K, # K
            tcgen05.OperandMajorMode.K, # Q
            acc_dtype,
            tcgen05.CtaGroup.ONE,
            mma_tile_mnk[:2],
            tcgen05.OperandSource.TMEM, # converted K in tmem
        )

        # GEMM2: (D, H_R, S_K, (H_K, B))
        tiled_mma_vp = sm100_utils.make_trivial_tiled_mma(#
            mma_dtype,
            tcgen05.OperandMajorMode.K, # V
            tcgen05.OperandMajorMode.MN, # P
            acc_dtype,
            tcgen05.CtaGroup.ONE,
            mma_tile_mnk[:2],
            tcgen05.OperandSource.TMEM, # converted V in tmem
        )

        # Calculate Q stages
        self.q_stages = blk_tile_d // mma_tile_k

        # Heuristics to avoid power throttling
        max_cvt_stages = 4 if self.grouped_head_tile == 32 and mma_tile_k == 128 else 8
        max_kv_stages = 8 if mma_tile_k == 128 else 14

        # Calculate KV tmem stages
        tmem_alloc_cols = mma_tile_n * self.sp_stages
        tmem_alloc_cols += mma_tile_n * self.o_stages * (blk_tile_d // mma_tile_m)
        tmem_capacity = 512
        cvt_stage_cols = mma_tile_k * mma_dtype.width // 32
        self.cvt_stages = (tmem_capacity - tmem_alloc_cols) // cvt_stage_cols
        self.cvt_stages = min(self.cvt_stages, max_cvt_stages)

        tmem_alloc_cols += self.cvt_stages * cvt_stage_cols
        self.tmem_alloc_cols = 2 ** math.ceil(math.log2(tmem_alloc_cols)) # Tmem alloc must be PO2

        print(f"\tcvt stages: {self.cvt_stages}")

        # Calculate KV smem stages
        self.mbarrier_reserved_bytes = 768
        smem_alloc_bits = self.mbarrier_reserved_bytes*8
        smem_alloc_bits += mma_tile_n * 2 * acc_dtype.width # colmax + cluster colmax
        smem_alloc_bits += self.scaledim * blk_tile_s * self.bs_stages * mma_dtype.width # block scale
        smem_alloc_bits += mma_tile_n * warpgroup_warps * acc_dtype.width # colsum
        smem_alloc_bits += mma_tile_n * mma_tile_k * self.q_stages * mma_dtype.width # Q
        smem_alloc_bits += mma_tile_m * mma_tile_n * self.sp_stages * mma_dtype.width # P

        smem_capacity = utils.get_smem_capacity_in_bytes("sm_100")
        self.kv_stages = (smem_capacity*8 - smem_alloc_bits) // (mma_tile_m * mma_tile_k * k_iter.dtype.width)
        self.kv_stages = min(self.kv_stages, max_kv_stages)

        print(f"\tkv stages: {self.kv_stages}")

        ##############################
        # TMA creation
        ##############################
        b, h_q, h_k, s_k, d = problem_shape
        h_r = h_q // h_k
        kv_clusters = kv_splits // kv_cluster_dim

        q = cute.make_tensor(q_iter,
            cute.make_ordered_layout(
                shape=(h_r, d, (h_k, b)),
                order=(  1, 0, (  2, 3))
            )
        )

        k = cute.make_tensor(k_iter,
            cute.make_ordered_layout(
                shape=(s_k, d, (h_k, b)),
                order=(  1, 0, (  2, 3))
            )
        )
        assert k_iter.dtype is not q_iter.dtype

        v = cute.make_tensor(v_iter,
            cute.make_ordered_layout(
                shape=(d, s_k, (h_k, b)),
                order=(0,   1, (  2, 3))
            )
        )
        assert v_iter.dtype is k_iter.dtype

        o_partial = cute.make_tensor(o_partial_iter,
            cute.make_ordered_layout(
                shape=(d, h_r, (h_k, b), kv_clusters),
                order=(0,   1, (  2, 3), 4)
            )
        )

        m = cute.make_tensor(m_iter,
            cute.make_ordered_layout(
                shape=(h_r, (h_k, b)),
                order=(  0, (  1, 2)),
            )
        )
        assert m_iter.dtype is acc_dtype

        m_partial = cute.make_tensor(m_partial_iter,
            cute.make_ordered_layout(
                shape=(h_r, (h_k, b), kv_clusters),
                order=(  0, (  1, 2), 3),
            )
        )
        assert m_partial_iter.dtype is acc_dtype

        l_partial = cute.make_tensor(l_partial_iter,
            cute.make_ordered_layout(
                shape=(h_r, (h_k, b), kv_clusters),
                order=(  0, (  1, 2), 3),
            )
        )
        assert l_partial_iter.dtype is acc_dtype

        align_scale_bits = 128 # TMA requirement
        if cutlass.const_expr(self.scaledim * mma_dtype.width >= align_scale_bits):
            scale_layout = cute.make_ordered_layout(
                shape=(self.scaledim, s_k, (h_k, b)),
                order=(0, 1, (2, 3))
            )
        else:
            align_seq = align_scale_bits // (self.scaledim * mma_dtype.width)
            s_ks = (align_seq, s_k // align_seq)
            scale_layout = cute.make_ordered_layout(
                shape=(self.scaledim, s_ks, (h_k, b)),
                order=(0, (1, 2), (3, 4))
            )

        k_scale = cute.make_tensor(k_scale_iter, scale_layout)
        assert k_scale_iter.dtype is mma_dtype

        v_scale = cute.make_tensor(v_scale_iter, scale_layout)
        assert v_scale_iter.dtype is mma_dtype


        # (MMA, MMA_M/N, MMA_K, Stages)
        smem_layout_q = sm100_utils.make_smem_layout_b(tiled_mma_kq, mma_tile_mnk, q_iter.dtype, self.q_stages)
        smem_layout_k = sm100_utils.make_smem_layout_a(tiled_mma_kq, mma_tile_mnk, k_iter.dtype, self.kv_stages)
        smem_layout_v = sm100_utils.make_smem_layout_a(tiled_mma_vp, mma_tile_mnk, v_iter.dtype, self.kv_stages,
                                                       is_k_major=False) # V is always headdim-major (GEMM2 M-major) in gmem+smem

        smem_layout_bs = cute.make_layout((self.scaledim, blk_tile_s, self.bs_stages))

        smem_layout_atom_o = tcgen05.make_smem_layout_atom(tcgen05.mma.SmemLayoutAtomKind.MN_SW128, o_partial_iter.dtype)
        smem_layout_o = cute.tile_to_shape(smem_layout_atom_o, (blk_tile_d, blk_tile_h), order=(1,0))
        smem_layout_o = cute.flat_divide(smem_layout_o, (mma_tile_m, mma_tile_n))

        tma_load_op = cute.nvgpu.cpasync.CopyBulkTensorTileG2SOp()
        tma_store_op = (cute.nvgpu.cpasync.CopyBulkTensorTileS2GOp() if self.deterministic 
                        else cute.nvgpu.cpasync.CopyReduceBulkTensorTileS2GOp())

        tma_atom_q, tma_tensor_q = cute.nvgpu.make_tiled_tma_atom_B(
            tma_load_op, q, cute.select(smem_layout_q, mma_modes), mma_tile_mnk, tiled_mma_kq
        )
        tma_atom_k, tma_tensor_k = cute.nvgpu.make_tiled_tma_atom_A(
            tma_load_op, k, cute.select(smem_layout_k, mma_modes), mma_tile_mnk, tiled_mma_kq
        )
        tma_atom_v, tma_tensor_v = cute.nvgpu.make_tiled_tma_atom_A(
            tma_load_op, v, cute.select(smem_layout_v, mma_modes), mma_tile_mnk, tiled_mma_vp
        )
        tma_atom_ks, tma_tensor_ks = cute.nvgpu.cpasync.make_tiled_tma_atom(
            tma_load_op, k_scale, cute.select(smem_layout_bs, mode=[0,1]), smem_layout_bs.shape[:2]
        )
        tma_atom_vs, tma_tensor_vs = cute.nvgpu.cpasync.make_tiled_tma_atom(
            tma_load_op, v_scale, cute.select(smem_layout_bs, mode=[0,1]), smem_layout_bs.shape[:2]
        )
        tma_atom_o, tma_tensor_o = cute.nvgpu.cpasync.make_tiled_tma_atom(
            tma_store_op, o_partial, cute.select(smem_layout_o, mode=[0,1]), mma_tile_mnk[:2]
        )

        # K scale and V scale will have the same TMA tensor (coord tensor)
        # only difference is base ptr which is stored in copy atom
        tma_tensor_bs = tma_tensor_ks

        ##############################
        # Decode Kernel launch
        ##############################
        scale_qs_log2_e = scale_qs * log2_e

        n_tiles = cute.ceil_div(h_r, blk_tile_h)
        l_tiles = b * h_k
        grid = (kv_splits, n_tiles, l_tiles)

        self.decode(
            blk_tile_shd, mma_tile_mnk, tiled_mma_kq, tiled_mma_vp,
            q_iter.dtype, smem_layout_q, tma_atom_q, tma_tensor_q,
            k_iter.dtype, smem_layout_k, tma_atom_k, tma_tensor_k,
            v_iter.dtype, smem_layout_v, tma_atom_v, tma_tensor_v,
            smem_layout_bs, tma_atom_ks, tma_atom_vs, tma_tensor_bs,
            o_partial_iter.dtype, smem_layout_o, tma_atom_o, tma_tensor_o,
            m, m_partial, l_partial,
            scale_qs, scale_qs_log2_e,
        ).launch(
            grid=grid,
            block=[self.threads_per_cta, 1, 1],
            cluster=[kv_cluster_dim, 1, 1],
            stream=stream,
            min_blocks_per_mp=1,
        )

        ##############################
        # Reduction Kernel launch
        ##############################
        o = cute.make_tensor(o_iter, cute.make_layout((d, h_q, b)))
        m = cute.make_tensor(m_iter, cute.make_layout((h_q, b)))
        l = cute.make_tensor(l_iter, cute.make_layout((h_q, b)))

        o_partial = cute.make_tensor(o_partial_iter, cute.make_layout((d, h_q, b, kv_clusters)))
        m_partial = cute.make_tensor(m_partial_iter, cute.make_layout((h_q, b, kv_clusters)))
        l_partial = cute.make_tensor(l_partial_iter, cute.make_layout((h_q, b, kv_clusters)))

        d_per_blk = 128
        d_blks = cute.ceil_div(d, d_per_blk)

        self.reduction(o, m, l, o_partial, m_partial, l_partial, scale_o).launch(
            grid=[d_blks, h_q, b],
            block=[d_per_blk, 1, 1],
            cluster=[1, 1, 1],
            stream=stream,
        )

    @cute.kernel
    def decode(
        self,
        # MMA
        blk_tile_shd: cute.Tile,
        mma_tile_mnk: cute.Tile,
        tiled_mma_kq: cute.TiledMma,
        tiled_mma_vp: cute.TiledMma,
        # Q
        q_dtype: Type[cutlass.Numeric],
        smem_layout_q: cute.ComposedLayout,
        tma_atom_q: cute.CopyAtom,
        mQ: cute.Tensor,
        # K
        k_dtype: Type[cutlass.Numeric],
        smem_layout_k: cute.ComposedLayout,
        tma_atom_k: cute.CopyAtom,
        mK: cute.Tensor,
        # V
        v_dtype: Type[cutlass.Numeric],
        smem_layout_v: cute.ComposedLayout,
        tma_atom_v: cute.CopyAtom,
        mV: cute.Tensor,
        # K/V block scale
        smem_layout_bs: cute.Layout,
        tma_atom_ks: cute.CopyAtom,
        tma_atom_vs: cute.CopyAtom,
        mBS: cute.Tensor,
        # O
        o_dtype: Type[cutlass.Numeric],
        smem_layout_o: cute.ComposedLayout,
        tma_atom_o: cute.CopyAtom,
        mO: cute.Tensor,
        # Rest
        mM: cute.Tensor,
        mM_partial: cute.Tensor,
        mL_partial: cute.Tensor,
        scale_qs: Float32,
        scale_qs_log2_e: Float32,
    ):
        # Read special registers
        kv_splits, tiles_hr, tiles_hb = cute.arch.grid_dim()
        kv_split_idx, coord_hr, coord_hb = cute.arch.block_idx()
        kv_split_in_cluster, _, _ = cute.arch.block_in_cluster_idx()
        kv_cluster_dim, _, _ = cute.arch.block_in_cluster_dim()
        kv_cluster_idx, _, _ = cute.arch.cluster_idx()
        tidx, _, _ = cute.arch.thread_idx()
        lane_idx = cute.arch.lane_idx()
        warp_idx = cute.arch.make_warp_uniform(tidx // warp_threads)
        warpgroup_idx = cute.arch.make_warp_uniform(tidx // warpgroup_threads)
        warpgroup_tidx = tidx % warpgroup_threads
        warpgroup_widx = warp_idx % warpgroup_warps
        init_warp = 0

        # No multicast
        mcast_coord = 0
        mcast_layout = cute.make_layout((1,1,1,1)) # vmnk

        # Alias types
        mma_dtype = q_dtype
        acc_dtype = o_dtype

        # Shapes for MMA tile indexing (Read TMA partition for example)
        blk_tile_s, blk_tile_h, blk_tile_d = blk_tile_shd
        mma_tile_m, mma_tile_n, mma_tile_k = mma_tile_mnk
        tiles_dm, tiles_sk = cute.ceil_div((blk_tile_d, blk_tile_s), (mma_tile_m, mma_tile_k))
        tiles_dk, tiles_sm = cute.ceil_div((blk_tile_d, blk_tile_s), (mma_tile_k, mma_tile_m))
        tiles_s = cute.ceil_div(mK.shape[0], blk_tile_s)
        iters_s = cute.ceil_div(tiles_s - kv_split_idx, kv_splits)
        prefetch_iters = self.sp_stages - 1
        if iters_s < prefetch_iters:
            prefetch_iters = iters_s
        assert tiles_sm == 1

        # Runtime checks
        exit_early = kv_split_idx >= tiles_s
        do_cluster_reduction = not self.deterministic and kv_cluster_dim > 1
        lane_store_max = mma_tile_n == warp_threads or lane_idx < mma_tile_n

        # Smem alloc helper
        svector_align = 16
        stensor_align = 128
        smem = utils.SmemAllocator()

        ##############################
        # Prefetch TMA descriptor
        ##############################
        if warp_idx == init_warp and not exit_early:
            cute.nvgpu.cpasync.prefetch_descriptor(tma_atom_q)
            cute.nvgpu.cpasync.prefetch_descriptor(tma_atom_k)
            cute.nvgpu.cpasync.prefetch_descriptor(tma_atom_v)
            cute.nvgpu.cpasync.prefetch_descriptor(tma_atom_ks)
            cute.nvgpu.cpasync.prefetch_descriptor(tma_atom_vs)
            cute.nvgpu.cpasync.prefetch_descriptor(tma_atom_o)
        init_warp += 1

        ##############################
        # Tmem Allocation
        ##############################
        tmem_ptr_smem_ptr = smem.allocate_array(Int32)
        if warp_idx == init_warp and not exit_early:
            cute.arch.alloc_tmem(self.tmem_alloc_cols, tmem_ptr_smem_ptr)
        init_warp += 1

        ##############################
        # Pipeline Allocation + Init
        ##############################
        # Allocate Mbarriers
        q_pipeline_ptr = smem.allocate_array(Int64, self.q_stages * 2)
        kv_pipeline_ptr = smem.allocate_array(Int64, self.kv_stages * 2)
        bs_pipeline_ptr = smem.allocate_array(Int64, self.bs_stages * 2)
        cvt_pipeline_ptr = smem.allocate_array(Int64, self.cvt_stages * 2)
        s_pipeline_ptr = smem.allocate_array(Int64, self.sp_stages * 2)
        p_pipeline_ptr = smem.allocate_array(Int64, self.sp_stages * 2)
        o_pipeline_ptr = smem.allocate_array(Int64, self.o_stages * 2)
        m_cluster_full_ptr = smem.allocate_array(Int64) # signal cluster colmax is in split 0 smem

        assert smem._allocated_bytes <= self.mbarrier_reserved_bytes

        # Declare named barriers
        softmax_nbar_id = 1
        mma_kq_nbar_id = 2
        mma_vp_nbar_id = 3

        # Initialize cluster colmax + mbar (even if this split exits early)
        sM_layout = cute.make_layout(shape=(mma_tile_m, mma_tile_n), stride=(0, 1))
        sM_cluster = smem.allocate_tensor(acc_dtype, sM_layout, svector_align)
        if do_cluster_reduction:
            if warp_idx == init_warp and kv_split_in_cluster == 0:
                if lane_store_max:
                    sM_cluster[(0,lane_idx)] = -Float32.inf
                    cute.arch.fence_acq_rel_cluster()
            init_warp += 1

            if warp_idx == init_warp:
                # split 0 waits for one arrive per colmax elt per split in cluster
                # other splits in cluster wait for one arrive from split 0
                arrive_count = (kv_cluster_dim * mma_tile_n) if kv_split_in_cluster == 0 else 1
                cute.arch.mbarrier_init(m_cluster_full_ptr, arrive_count)
                cute.arch.mbarrier_init_fence()
            init_warp += 1

            cute.arch.cluster_arrive_relaxed()

        # Setup up thread cooperatives
        elect_one_cooperative = pipeline.CooperativeGroup(pipeline.Agent.Thread)
        warpgroup_cooperative = pipeline.CooperativeGroup(pipeline.Agent.Thread, warpgroup_threads)
        dual_warpgroup_cooperative = pipeline.CooperativeGroup(pipeline.Agent.Thread, warpgroup_threads * 2)
        mma_group = elect_one_cooperative
        tma_group = elect_one_cooperative
        tma_qo_group = elect_one_cooperative
        cvt_group = warpgroup_cooperative
        softmax_group = warpgroup_cooperative

        # Initialize pipelines
        q_producer, q_consumer = pipeline.PipelineTmaAsync.create(
            num_stages=self.q_stages,
            producer_group=tma_group,
            consumer_group=softmax_group, # Reuse Q consumer mbarriers to sync O store
            tx_count=cute.size_in_bytes(q_dtype, cute.select(smem_layout_q, mma_modes)),
            barrier_storage=q_pipeline_ptr,
            tidx=mcast_coord, cta_layout_vmnk=mcast_layout,
            defer_sync=True,
        ).make_participants()
        kv_producer, kv_consumer = pipeline.PipelineTmaAsync.create(
            num_stages=self.kv_stages,
            producer_group=tma_group, consumer_group=cvt_group,
            tx_count=cute.size_in_bytes(k_dtype, cute.select(smem_layout_k, mma_modes)),
            barrier_storage=kv_pipeline_ptr,
            tidx=mcast_coord, cta_layout_vmnk=mcast_layout,
            defer_sync=True,
        ).make_participants()
        bs_producer, bs_consumer = pipeline.PipelineTmaAsync.create(
            num_stages=self.bs_stages,
            producer_group=tma_qo_group,
            consumer_group=(dual_warpgroup_cooperative if self.dual_convert else cvt_group),
            tx_count=cute.size_in_bytes(mma_dtype, cute.select(smem_layout_bs, mode=[0,1])),
            barrier_storage=bs_pipeline_ptr,
            tidx=mcast_coord, cta_layout_vmnk=mcast_layout,
            defer_sync=True,
        ).make_participants()
        cvt_producer, cvt_consumer = pipeline.PipelineAsyncUmma.create(
            num_stages=self.cvt_stages,
            producer_group=cvt_group, consumer_group=mma_group,
            barrier_storage=cvt_pipeline_ptr,
            defer_sync=True,
        ).make_participants()
        s_producer, s_consumer = pipeline.PipelineUmmaAsync.create(
            num_stages=self.sp_stages,
            producer_group=mma_group, consumer_group=softmax_group,
            barrier_storage=s_pipeline_ptr,
            defer_sync=True,
        ).make_participants()
        p_producer, p_consumer = pipeline.PipelineAsyncUmma.create(
            num_stages=self.sp_stages,
            producer_group=softmax_group, consumer_group=mma_group,
            barrier_storage=p_pipeline_ptr,
            defer_sync=True,
        ).make_participants()
        o_producer, o_consumer = pipeline.PipelineUmmaAsync.create(
            num_stages=self.o_stages,
            producer_group=mma_group, consumer_group=softmax_group,
            barrier_storage=o_pipeline_ptr,
            defer_sync=True,
        ).make_participants()

        # Ensure visibility of cluster mbarrier + colmax init
        if do_cluster_reduction:
            cute.arch.cluster_wait()

        # Ensure visibility of local mbarrier inits and tmem alloc
        cute.arch.sync_threads()

        ##############################
        # MMA Partition + Allocate
        ##############################
        # Threadblock slice
        thrblk_mma_kq = tiled_mma_kq.get_slice(0)
        thrblk_mma_vp = tiled_mma_vp.get_slice(0)

        # M - colmax
        sM = smem.allocate_tensor(acc_dtype, sM_layout, svector_align)
        tCsM = thrblk_mma_kq.partition_C(sM)
        tCsM_cluster = thrblk_mma_kq.partition_C(sM_cluster)

        # L - colsum
        sL_layout = cute.make_layout(shape=(mma_tile_m, mma_tile_n, warpgroup_warps), stride=(0, 1, mma_tile_n))
        sL = smem.allocate_tensor(acc_dtype, sL_layout, svector_align)
        tCsL = thrblk_mma_kq.partition_C(sL)

        # BS - block scale
        sBS = smem.allocate_tensor(mma_dtype, smem_layout_bs, stensor_align) # (SCALE, TILE_S, bs_stages)

        # Q
        tBsQ = smem.allocate_tensor(q_dtype, smem_layout_q.outer, stensor_align, smem_layout_q.inner) # (MMA, #MMA_N, #MMA_K, q_stages)

        # K
        tAsK = smem.allocate_tensor(k_dtype, smem_layout_k.outer, stensor_align, smem_layout_k.inner) # (MMA, #MMA_M, #MMA_K, kv_stages)
        tAtK_cvt_shape = tiled_mma_kq.partition_shape_A((mma_tile_m, mma_tile_k, self.cvt_stages)) # (MMA, #MMA_M, #MMA_K, cvt_stages)
        tAtK_cvt = thrblk_mma_kq.make_fragment_A(tAtK_cvt_shape)

        # V
        tAsV_iterator = cute.recast_ptr(tAsK.iterator, smem_layout_v.inner, dtype=v_dtype) # KV share input buffers
        tAsV = cute.make_tensor(tAsV_iterator, smem_layout_v.outer) # (MMA, #MMA_M, #MMA_K, kv_stages)
        tAtV_cvt_shape = tiled_mma_vp.partition_shape_A((mma_tile_m, mma_tile_k, self.cvt_stages)) # (MMA, #MMA_M, #MMA_K, cvt_stages)
        tAtV_cvt = thrblk_mma_vp.make_fragment_A(tAtV_cvt_shape)

        # S
        tCtS_shape = tiled_mma_kq.partition_shape_C((mma_tile_m, mma_tile_n, self.sp_stages))
        tCtS = thrblk_mma_kq.make_fragment_C(tCtS_shape) # (MMA_MN, #MMA_M=1, #MMA_N=1, sp_stages)

        # P - Treat MN C tile of BMM0 as NM B tile of BMM1
        # (MMA_NK, #MMA_N, #MMA_K=MMA_TILE_M/MMA_K, sp_stages)
        mma_tile_nm = (None, mma_tile_n, mma_tile_m)
        tBsP_nm_layout = sm100_utils.make_smem_layout_b(tiled_mma_vp, mma_tile_nm, mma_dtype, self.sp_stages)
        tBsP_nm = smem.allocate_tensor(mma_dtype, tBsP_nm_layout.outer, stensor_align, tBsP_nm_layout.inner)

        # Tile for NK B tile iteration
        # (MMA_NK, #MMA_N, #MMA_K=MMA_TILE_K/MMA_K, #TILES_SK=MMA_TILE_M/MMA_TILE_K, sp_stages)
        tBsP_nk_tile = thrblk_mma_vp.partition_shape_B((mma_tile_n, mma_tile_k))
        tBsP_nk = cute.local_tile(tBsP_nm, tBsP_nk_tile, (0, 0, None, None))

        # Reshape NM B tile of BMM1 to become MN C tile of BMM0
        # (MMA_NK, #MMA_N, #MMA_K=MMA_TILE_M/MMA_K, sp_stages) ->
        # (MMA_MN, #MMA_M, #MMA_N, sp_stages)
        tCsP_tile = cute.make_ordered_layout(tCtS_shape, order=((2, 0), 3, 1, 4))
        tCsP = cute.composition(tBsP_nm, tCsP_tile)

        # O
        sO_iterator = cute.recast_ptr(tBsQ.iterator, smem_layout_o.inner, dtype=o_dtype) # Reuse QKV smem for O TMA store
        sO_mma = cute.make_tensor(sO_iterator, smem_layout_o.outer) # (MMA_TILE_M, MMA_TILE_N, #TILE_DM, #TILE_HN)
        tCsO = thrblk_mma_vp.partition_C(sO_mma) # (MMA, #MMA_M, #MMA_N, #TILE_DM, #TILE_HN)
        tCtO = thrblk_mma_vp.make_fragment_C(tCsO.shape)

        # Tmem tensor allocation
        tmem_ptr = cute.arch.retrieve_tmem_ptr(Int32, 16, tmem_ptr_smem_ptr)
        tmem_offset = 0

        tAtK_cvt = cute.make_tensor(cute.recast_ptr(tmem_ptr + tmem_offset, dtype=mma_dtype), tAtK_cvt.layout)
        tAtV_cvt = cute.make_tensor(cute.recast_ptr(tmem_ptr + tmem_offset, dtype=mma_dtype), tAtV_cvt.layout)
        tmem_offset += tcgen05.find_tmem_tensor_col_offset(tAtK_cvt)

        tCtS = cute.make_tensor(cute.recast_ptr(tmem_ptr + tmem_offset, dtype=acc_dtype), tCtS.layout)
        tmem_offset += tcgen05.find_tmem_tensor_col_offset(tCtS)

        tCtO = cute.make_tensor(cute.recast_ptr(tmem_ptr + tmem_offset, dtype=acc_dtype), tCtO.layout)
        tmem_offset += tcgen05.find_tmem_tensor_col_offset(tCtO)

        print(f"\t{tmem_offset} tmem cols used, {self.tmem_alloc_cols} tmem cols allocated")
        assert tmem_offset <= self.tmem_alloc_cols

        ##############################
        # Exit early
        ##############################
        if exit_early:
            if do_cluster_reduction and tidx == 0:
                waiting_split_in_cluster = 0
                cute.arch.mbarrier_arrive(
                    m_cluster_full_ptr,
                    waiting_split_in_cluster,
                    arrive_count=mma_tile_n
                )

        ##############################
        # TMA KV Dispatch
        ##############################
        elif warp_idx == self.tma_kv_warp_id:
            # Free registers
            if cutlass.const_expr(self.use_reg_reconfig):
                cute.arch.setmaxregister_decrease(self.mma_tma_regs)

            # Apply block tiler and slice
            gK = cute.local_tile(mK, tiler=(blk_tile_s, blk_tile_d), coord=(None, 0, coord_hb)) # (TILE_S, TILE_D, #TILE_S)
            gV = cute.local_tile(mV, tiler=(blk_tile_d, blk_tile_s), coord=(0, None, coord_hb)) # (TILE_D, TILE_S, #TILE_S)

            # Apply MMA tiler and MMA partition
            gK_mma = cute.flat_divide(gK, (mma_tile_m, mma_tile_k)) # (MMA_TILE_M, MMA_TILE_K, #TILE_SM, #TILE_DK, #TILE_S)
            gV_mma = cute.flat_divide(gV, (mma_tile_m, mma_tile_k)) # (MMA_TILE_M, MMA_TILE_K, #TILE_DM, #TILE_SK, #TILE_S)
            tAgK = thrblk_mma_kq.partition_A(gK_mma) # (MMA, #MMA_M, #MMA_K, #TILE_SM, #TILE_DK, #TILE_S)
            tAgV = thrblk_mma_vp.partition_A(gV_mma) # (MMA, #MMA_M, #MMA_K, #TILE_DM, #TILE_SK, #TILE_S)

            # #TILE_SM=TILE_S/MMA_TILE_M, #TILE_HN=TILE_H/MMA_TILE_N, #TILE_DK=TILE_D/MMA_TILE_K
            # #TILE_DM=TILE_D/MMA_TILE_M, #TILE_HN=TILE_H/MMA_TILE_N, #TILE_SK=TILE_S/MMA_TILE_K
            #
            # Example with TILE_S=MMA_TILE_M=128, TILE_H=MMA_TILE_N=8, MMA_TILE_K=64, TILE_D=512
            # BMM1: MMA=128x8x16, #MMA_M=1, #MMA_N=1, #MMA_K=4, #TILE_SM=1, #TILE_HN=1, #TILE_DK=8, #TILE_S=S/128
            # BMM2: MMA=128x8x16, #MMA_M=1, #MMA_N=1, #MMA_K=4, #TILE_DM=4, #TILE_HN=1, #TILE_SK=2, #TILE_S=S/128

            # TMA partition
            # (MMA, #MMA_M, #MMA_K, Rest...) -> (TMA, Rest...)
            tGSsK, tGSgK = cute.nvgpu.cpasync.tma_partition(
                tma_atom_k, mcast_coord, mcast_layout,
                smem_tensor=cute.group_modes(tAsK, 0, 3),
                gmem_tensor=cute.group_modes(tAgK, 0, 3))

            tGSsV, tGSgV = cute.nvgpu.cpasync.tma_partition(
                tma_atom_v, mcast_coord, mcast_layout,
                smem_tensor=cute.group_modes(tAsV, 0, 3),
                gmem_tensor=cute.group_modes(tAgV, 0, 3))

            #
            # Sequence loop
            #
            prefetch_tiles = prefetch_iters * kv_splits
            for s in cutlass.range(kv_split_idx, prefetch_tiles + tiles_s, kv_splits):
                # Load K
                if s < tiles_s:
                    tGSgK_s = tGSgK[None, None, None, s]
                    for dk in cutlass.range_constexpr(tiles_dk):
                        k_handle = kv_producer.acquire_and_advance()
                        cute.copy(
                            tma_atom_k,
                            tGSgK_s[None, 0, dk],
                            tGSsK[None, k_handle.index],
                            tma_bar_ptr=k_handle.barrier)

                # Load V
                if s >= prefetch_tiles:
                    tGSgV_s = tGSgV[None, None, None, s-prefetch_tiles]
                    for sk in cutlass.range_constexpr(tiles_sk):
                        for dm in cutlass.range_constexpr(tiles_dm):
                            v_handle = kv_producer.acquire_and_advance()
                            cute.copy(
                                tma_atom_v,
                                tGSgV_s[None, dm, sk],
                                tGSsV[None, v_handle.index],
                                tma_bar_ptr=v_handle.barrier)

        ##############################
        # TMA QO Dispatch
        ##############################
        elif warp_idx == self.tma_qo_warp_id:
            # Free registers
            if cutlass.const_expr(self.use_reg_reconfig):
                cute.arch.setmaxregister_decrease(self.mma_tma_regs)

            # Apply block tiler and slice
            gQ = cute.local_tile(mQ, tiler=(blk_tile_h, blk_tile_d), coord=(coord_hr, 0, coord_hb)) # (TILE_H, TILE_D)
            gO = cute.local_tile(mO, tiler=(blk_tile_d, blk_tile_h), coord=(0, coord_hr, coord_hb, kv_cluster_idx)) # (TILE_D, TILE_H)
            gBS = cute.local_tile(mBS, tiler=(self.scaledim, blk_tile_s), coord=(0, None, coord_hb)) # (SCALE, TILE_S, #TILE_S)

            # Apply MMA tiler and MMA partition
            gQ_mma = cute.flat_divide(gQ, (mma_tile_n, mma_tile_k)) # (MMA_TILE_N, MMA_TILE_K, #TILE_HN, #TILE_DK)
            gO_mma = cute.flat_divide(gO, (mma_tile_m, mma_tile_n)) # (MMA_TILE_M, MMA_TILE_N, #TILE_DM, #TILE_HN)
            tBgQ = thrblk_mma_kq.partition_B(gQ_mma) # (MMA, #MMA_N, #MMA_K, #TILE_HN, #TILE_DK)

            # TMA partition
            tGSsQ, tGSgQ = cute.nvgpu.cpasync.tma_partition(
                tma_atom_q, mcast_coord, mcast_layout,
                smem_tensor=cute.group_modes(tBsQ, 0, 3),
                gmem_tensor=cute.group_modes(tBgQ, 0, 3))

            tSGsO, tSGgO = cute.nvgpu.cpasync.tma_partition(
                tma_atom_o, mcast_coord, mcast_layout,
                smem_tensor=cute.group_modes(sO_mma, 0, 2),
                gmem_tensor=cute.group_modes(gO_mma, 0, 2))

            tGSsBS, tGSgBS = cute.nvgpu.cpasync.tma_partition(
                tma_atom_ks, mcast_coord, mcast_layout,
                smem_tensor=cute.group_modes(sBS, 0, 2),
                gmem_tensor=cute.group_modes(gBS, 0, 2))

            # Load Q
            for dk in cutlass.range_constexpr(tiles_dk):
                q_handle = q_producer.acquire_and_advance()
                cute.copy(
                    tma_atom_q,
                    tGSgQ[None, 0, dk], # stages_q == tiles_dk by construction
                    tGSsQ[None, dk],
                    tma_bar_ptr=q_handle.barrier)

            # Sequence Loop
            prefetch_tiles = prefetch_iters * kv_splits
            for s in cutlass.range(kv_split_idx, prefetch_tiles + tiles_s, kv_splits):
                if s < tiles_s:
                    bs_handle = bs_producer.acquire_and_advance()
                    cute.copy(
                        tma_atom_ks,
                        tGSgBS[None, s],
                        tGSsBS[None, bs_handle.index],
                        tma_bar_ptr=bs_handle.barrier)

                if s >= prefetch_tiles:
                    bs_handle = bs_producer.acquire_and_advance()
                    cute.copy(
                        tma_atom_vs,
                        tGSgBS[None, s-prefetch_tiles],
                        tGSsBS[None, bs_handle.index],
                        tma_bar_ptr=bs_handle.barrier)
                    
            # Store O
            for dm in cutlass.range_constexpr(tiles_dm):
                q_producer.acquire_and_advance() # Reuse Q load barriers to sync O store
                cute.copy(
                    tma_atom_o,
                    tSGsO[None, dm, 0],
                    tSGgO[None, dm, 0])

        ##############################
        # Convert Dispatch
        ##############################
        elif warpgroup_idx in self.cvt_warpgroup_ids:
            # Free registers
            if cutlass.const_expr(self.use_reg_reconfig):
                cute.arch.setmaxregister_decrease(self.cvt_regs)

            # Initialize for dual convert if necessary
            convert_warpgroups = 1
            convert_phase = 0
            if cutlass.const_expr(self.dual_convert):
                assert tiles_dk % 2 == 0
                assert (tiles_dm * tiles_sk) % 2 == 0
                convert_warpgroups = 2
                convert_phase = warpgroup_idx % convert_warpgroups
                if convert_phase == 1:
                    kv_consumer.advance()
                    cvt_producer.advance()

            # Construct tiled copy and partition K
            tmem_op_width = 32
            tmem_op_repeat = tcgen05.Repetition(mma_tile_k * mma_dtype.width // tmem_op_width)
            tmem_store_atom_k = cute.make_copy_atom(tcgen05.St32x32bOp(tmem_op_repeat), mma_dtype)
            tmem_store_k = tcgen05.make_tmem_copy(tmem_store_atom_k, tAtK_cvt[*mma_dice, 0])
            thr_store_k = tmem_store_k.get_slice(warpgroup_tidx) # tmem copy is always 128 threads

            tKsK = thr_store_k.partition_S(tAsK)
            tKtK_cvt = thr_store_k.partition_D(tAtK_cvt)

            # Construct tiled copy and partition V
            tmem_op_width = 128
            tmem_op_repeat = tcgen05.Repetition(mma_tile_k * mma_dtype.width // tmem_op_width)
            tmem_store_atom_v = cute.make_copy_atom(tcgen05.St16x128bOp(tmem_op_repeat), mma_dtype)
            tmem_store_v = tcgen05.make_tmem_copy(tmem_store_atom_v, tAtV_cvt[*mma_dice, 0])
            thr_store_v = tmem_store_v.get_slice(warpgroup_tidx)

            smem_load_atom_v = cute.make_copy_atom(cute.nvgpu.warp.LdMatrix16x16x8bOp(num_matrices=2), v_dtype)
            smem_load_v = cute.make_tiled_copy_S(smem_load_atom_v, tmem_store_v)
            thr_load_v = smem_load_v.get_slice(warpgroup_tidx)

            tVsV = thr_load_v.partition_S(tAsV)
            tVrV_shape = smem_load_v.get_slice(0).partition_D(tAsV).shape[:-1]
            tVrV_cvt_shape = thr_store_v.get_slice(0).partition_S(tAtV_cvt).shape[:-1]
            tVtV_cvt = thr_store_v.partition_D(tAtV_cvt)

            # Partition KS - K block scale
            sKS_layout = cute.make_layout(
                shape=(blk_tile_s, (self.block_scaledim, self.scaledim), self.bs_stages),
                stride=(self.scaledim, (0, 1), blk_tile_s * self.scaledim))
            sKS = cute.make_tensor(sBS.iterator, sKS_layout) # (TILE_S, TILE_D, bs_stages)
            # (MMA_TILE_M, MMA_TILE_K, (#TILE_SM, #TILE_DK), bs_stages)
            sKS_mma = cute.group_modes(cute.flat_divide(sKS, (mma_tile_m, mma_tile_k)), 2, 4)
            tAsKS = thrblk_mma_kq.partition_A(sKS_mma) # (MMA, #MMA_M, #MMA_K, (#TILE_SM, #TILE_DK), bs_stages)
            tKsKS = thr_store_k.partition_S(tAsKS) # (CPY, CPY_MMA, CPY_M, CPY_K, #TILE, bs_stages)
            tKrKS = cute.make_rmem_tensor_like(tKsKS[*cpy_dice, None, 0]) # (CPY, CPY_MMA, CPY_M, CPY_K, #TILE)

            # Partition VS - V block scale
            sVS_layout = cute.make_layout(
                shape=((self.block_scaledim, self.scaledim), blk_tile_s, self.bs_stages),
                stride=((0, 1), self.scaledim, blk_tile_s * self.scaledim))
            sVS = cute.make_tensor(sBS.iterator, sVS_layout) # (TILE_D, TILE_S, bs_stages)
            # (MMA_TILE_M, MMA_TILE_K, (#TILE_DM, #TILE_SK), bs_stages)
            sVS_mma = cute.group_modes(cute.flat_divide(sVS, (mma_tile_m, mma_tile_k)), 2, 4)
            tAsVS = thrblk_mma_vp.partition_A(sVS_mma) # (MMA, #MMA_M, #MMA_K, (#TILE_DM, #TILE_SK), bs_stages)
            tVsVS = thr_load_v.partition_D(tAsVS) # (CPY, CPY_MMA, CPY_M, CPY_K, #TILE, bs_stages)
            tVrVS = cute.make_rmem_tensor_like(tVsVS[*cpy_dice, None, 0]) # (CPY, CPY_MMA, CPY_M, CPY_K, #TILE)

            #
            # Sequence loop
            #
            for s in cutlass.range(prefetch_iters + iters_s):
                if s < iters_s:
                    # Load K scale
                    bs_handle = bs_consumer.wait_and_advance()
                    cute.autovec_copy(tKsKS[*cpy_dice, None, bs_handle.index], tKrKS)
                    cute.arch.fence_view_async_shared()
                    bs_handle.release()

                    # Convert and scale K
                    for dk in cutlass.range(tiles_dk // convert_warpgroups, unroll=2):
                        tKrK = cute.make_rmem_tensor(tKsK.shape[:-1], k_dtype)
                        tKrK_cvt = cute.make_rmem_tensor(tKsK.shape[:-1], mma_dtype)

                        kv_handle = kv_consumer.wait_and_advance()
                        cute.autovec_copy(tKsK[*cpy_dice, kv_handle.index], tKrK)
                        cute.arch.fence_view_async_shared()
                        kv_handle.release()

                        coord_dk = dk * convert_warpgroups + convert_phase
                        scale_k = tKrKS[*cpy_dice, coord_dk].load()
                        tKrK_cvt.store(tKrK.load().to(mma_dtype) * scale_k)

                        cvt_handle = cvt_producer.acquire_and_advance()
                        cute.copy(thr_store_k, tKrK_cvt, tKtK_cvt[*cpy_dice, cvt_handle.index])
                        cute.arch.fence_view_async_tmem_store()
                        cvt_handle.commit()

                        # Advance again for dual warpgroups
                        if cutlass.const_expr(self.dual_convert):
                            kv_consumer.advance()
                            cvt_producer.advance()

                if s >= prefetch_iters:
                    # Load V scale
                    bs_handle = bs_consumer.wait_and_advance()
                    cute.autovec_copy(tVsVS[*cpy_dice, None, bs_handle.index], tVrVS)
                    cute.arch.fence_view_async_shared()
                    bs_handle.release()

                    # Convert and scale V
                    for dmsk in cutlass.range(tiles_dm * tiles_sk // convert_warpgroups, unroll=2):
                        tVrV = cute.make_rmem_tensor(tVrV_shape, v_dtype)
                        tVrV_cvt = cute.make_rmem_tensor(tVrV_cvt_shape, mma_dtype)

                        kv_handle = kv_consumer.wait_and_advance()
                        cute.copy(thr_load_v, tVsV[*cpy_dice, kv_handle.index], tVrV)
                        cute.arch.fence_view_async_shared()
                        kv_handle.release()

                        coord_dmsk = dmsk * convert_warpgroups + convert_phase
                        scale_v = tVrVS[*cpy_dice, coord_dmsk].load()
                        tVrV_cvt.store(tVrV.load().to(mma_dtype) * scale_v)

                        cvt_handle = cvt_producer.acquire_and_advance()
                        cute.copy(thr_store_v, tVrV_cvt, tVtV_cvt[*cpy_dice, cvt_handle.index])
                        cute.arch.fence_view_async_tmem_store()
                        cvt_handle.commit()

                        # Advance again for dual warpgroups
                        if cutlass.const_expr(self.dual_convert):
                            kv_consumer.advance()
                            cvt_producer.advance()

        ##############################
        # MMA KQ Dispatch
        ##############################
        elif warp_idx == self.mma_kq_warp_id:
            # Free registers
            if cutlass.const_expr(self.use_reg_reconfig):
                cute.arch.setmaxregister_decrease(self.mma_tma_regs)

            # Setup mma descriptors
            tBsQ_desc = thrblk_mma_kq.make_fragment_B(tBsQ)

            # Wait for Q
            for dk in cutlass.range_constexpr(tiles_dk):
                q_consumer.wait_and_advance()

            # Sequence loop
            s_token = True # Producer always acquires first
            for s in cutlass.range(iters_s):
                # BMM1
                k_token = cvt_consumer.try_wait()
                tiled_mma_kq.set(tcgen05.Field.ACCUMULATE, False)
                s_handle = s_producer.acquire_and_advance(s_token)
                for dk in cutlass.range_constexpr(tiles_dk):
                    is_last_iter = dk == tiles_dk - 1
                    k_handle = cvt_consumer.wait_and_advance(k_token)
                    # Signal BMM2 to start
                    if is_last_iter:
                        cute.arch.barrier_arrive(barrier_id=mma_kq_nbar_id, number_of_threads=64)
                    for mma_k in cutlass.range_constexpr(tAtK_cvt.shape[2]):
                        cute.gemm(
                            tiled_mma_kq,
                            tCtS[*mma_dice, s_handle.index],
                            tAtK_cvt[None, None, mma_k, k_handle.index],
                            tBsQ_desc[None, None, mma_k, dk],
                            tCtS[*mma_dice, s_handle.index],
                        )
                        if dk == 0 and mma_k == 0:
                            tiled_mma_kq.set(tcgen05.Field.ACCUMULATE, True)
                    k_handle.release()
                    if not is_last_iter:
                        k_token = cvt_consumer.try_wait()
                s_handle.commit()

                # Advance and wait for BMM 2
                if s > 0:
                    for _ in cutlass.range_constexpr(tiles_dm * tiles_sk):
                        cvt_consumer.advance()
                    cute.arch.barrier(barrier_id=mma_vp_nbar_id, number_of_threads=64)
                    s_token = s_producer.try_acquire()


        ##############################
        # MMA VP Dispatch
        ##############################
        elif warp_idx == self.mma_vp_warp_id:
            # Free registers
            if cutlass.const_expr(self.use_reg_reconfig):
                cute.arch.setmaxregister_decrease(self.mma_tma_regs)

            # Setup mma descriptors
            tiled_mma_vp.set(tcgen05.Field.ACCUMULATE, True)
            tBsP_desc = thrblk_mma_vp.make_fragment_B(tBsP_nk)

            for _ in cutlass.range_constexpr(tiles_dk):
                cvt_consumer.advance()
            cute.arch.barrier(barrier_id=mma_kq_nbar_id, number_of_threads=64)

            # Sequence loop
            p_token = False
            o_token = True # Producer always acquires first
            for s in cutlass.range(iters_s):
                # Advance and wait for BMM1
                if s < iters_s - 1:
                    for _ in cutlass.range_constexpr(tiles_dk):
                        cvt_consumer.advance()
                    cute.arch.barrier(barrier_id=mma_kq_nbar_id, number_of_threads=64)
                    p_token = p_consumer.try_wait()

                # BMM2
                v_token = cvt_consumer.try_wait()
                p_handle = p_consumer.wait_and_advance(p_token)
                o_handle = o_producer.acquire_and_advance(o_token)
                for sk in cutlass.range_constexpr(tiles_sk):
                    for dm in cutlass.range_constexpr(tiles_dm):
                        is_last_iter = sk == tiles_sk - 1 and dm == tiles_dm - 1
                        v_handle = cvt_consumer.wait_and_advance(v_token)
                        # Signal BMM1 to start
                        if is_last_iter:
                            cute.arch.barrier_arrive(barrier_id=mma_vp_nbar_id, number_of_threads=64)
                        for mma_k in cutlass.range_constexpr(tAtV_cvt.shape[2]):
                            cute.gemm(
                                tiled_mma_vp,
                                tCtO[*mma_dice, dm, 0],
                                tAtV_cvt[None, None, mma_k, v_handle.index],
                                tBsP_desc[None, None, mma_k, sk, p_handle.index],
                                tCtO[*mma_dice, dm, 0],
                            )
                        v_handle.release()
                        if not is_last_iter:
                            v_token = cvt_consumer.try_wait()
                p_handle.release()
                o_handle.commit()
                o_token = o_producer.try_acquire()

            # Wait for signal to dealloc tmem, then dealloc
            o_producer.tail()
            cute.arch.relinquish_tmem_alloc_permit()
            cute.arch.dealloc_tmem(tmem_ptr, self.tmem_alloc_cols)

        ##############################
        # Softmax + Correction Dispatch
        ##############################
        elif warpgroup_idx == self.softmax_warpgroup_id:
            # Alloc registers
            if cutlass.const_expr(self.use_reg_reconfig):
                cute.arch.setmaxregister_increase(self.softmax_regs)

            # Construct tiled copies
            tmem_op_width = 32
            tmem_op_repeat = tcgen05.Repetition(mma_tile_n * acc_dtype.width // tmem_op_width)
            tmem_load_atom_s = cute.make_copy_atom(tcgen05.Ld32x32bOp(tmem_op_repeat), acc_dtype)
            tmem_load_s = tcgen05.make_tmem_copy(tmem_load_atom_s, tCtS[*mma_dice, 0])
            thr_load_s = tmem_load_s.get_slice(warpgroup_tidx)

            tmem_store_atom_o = cute.make_copy_atom(tcgen05.St32x32bOp(tmem_op_repeat), o_dtype)
            tmem_store_o = tcgen05.make_tmem_copy(tmem_store_atom_o, tCtO[*mma_dice, 0, 0])
            thr_store_o = tmem_store_o.get_slice(warpgroup_tidx)

            # Partition S and P
            tStS = thr_load_s.partition_S(tCtS) # (CPY, #CPY_MMA, #CPY_M, #CPY_N, stages_sp)
            tSsP = thr_load_s.partition_D(tCsP) # (CPY, #CPY_MMA, #CPY_M, #CPY_N, stages_sp)

            # Partition O
            tStO = thr_load_s.partition_S(tCtO) # (CPY, #CPY_MMA, #CPY_M, #CPY_N, #TILE_DM, #TILE_HN)
            tSsO = thr_load_s.partition_D(tCsO) # (CPY, #CPY_MMA, #CPY_M, #CPY_N, #TILE_DM, #TILE_HN)
            tSrO = cute.make_rmem_tensor_like(tSsO)

            # Partition colmax and initialize in RF
            tSsM = thr_load_s.partition_D(tCsM) # (CPY, #CPY_MMA, #CPY_M, #CPY_N)
            tSsM_cluster = thr_load_s.partition_D(tCsM_cluster)
            tSrM_prev = cute.make_rmem_tensor_like(tSsM)
            tSrM_prev.fill(-Float32.inf)

            # Partition colsum and initialize in RF
            # Each thread maintains a local colsum in RF, smem reduction happens after loop
            tSsL = thr_load_s.partition_D(tCsL) # (CPY, #CPY_MMA, #CPY_M, #CPY_N, WARPS)
            tSrL = cute.make_rmem_tensor_like(tSsL[*cpy_dice, 0])
            tSrL.fill(Float32(0))

            assert warp_threads >= cute.size(tSsM)

            # get gmem colmax + colsum to store to
            inbound_hr = coord_hr * blk_tile_h + lane_idx < mM.shape[0]
            gM = cute.local_tile(mM, tiler=(mma_tile_n, 1), coord=(coord_hr, coord_hb)) # (TILE_H) = (MMA_TILE_N)
            gM_partial = cute.local_tile(mM_partial, tiler=(mma_tile_n, 1), coord=(coord_hr, coord_hb, kv_cluster_idx))
            gL_partial = cute.local_tile(mL_partial, tiler=(mma_tile_n, 1), coord=(coord_hr, coord_hb, kv_cluster_idx))

            # Initialize O
            tSrO.fill(Float32(0))
            cute.copy(thr_store_o, tSrO, tStO)

            # Initialize colsum and colmax in smem and wait
            if warpgroup_widx == 0 and lane_store_max:
                tSsM[lane_idx] = -Float32.inf
            if warpgroup_widx == 1 and lane_store_max:
                tSsL[lane_idx] = Float32(0)
            cute.arch.barrier(barrier_id=softmax_nbar_id, number_of_threads=warpgroup_threads)

            #
            # Sequence loop
            #
            for s in cutlass.range(iters_s):
                # Load S from tmem
                s_handle = s_consumer.wait_and_advance()
                tSrS = cute.make_rmem_tensor(tSsP.shape[:-1], acc_dtype)
                cute.copy(tmem_load_s, tStS[*cpy_dice, s_handle.index], tSrS)
                cute.arch.fence_view_async_tmem_load()
                s_handle.release()

                # Reduce colmax in warp RF
                tSrM = cute.make_rmem_tensor_like(tSsM)
                tSrM_lane = Float32(0) # Avoid dynamic register indexing
                for i in cutlass.range_constexpr(cute.size(tSrS)):
                    tSrM[i] = warp_fmax(tSrS[i])
                    if i == lane_idx:
                        tSrM_lane = tSrM[i]

                # Reduce colmax in smem
                if lane_store_max:
                    self.smem_fmax(tSsM.iterator + tSsM.layout(lane_idx), tSrM_lane)

                # Wait for colmax then load
                cute.arch.barrier(barrier_id=softmax_nbar_id, number_of_threads=warpgroup_threads)
                cute.autovec_copy(tSsM, tSrM)

                # Compute online softmax
                tSrP = cute.make_rmem_tensor(tSsP.shape[:-1], mma_dtype)
                if cutlass.const_expr(use_tensor_ssa_math):
                    tSrP_f32 = exp2(scale_qs_log2_e * (tSrS.load() - tSrM.load()))
                    tSrP.store(tSrP_f32.to(mma_dtype)) # convert
                else:
                    tSrP_f32 = cute.make_rmem_tensor(tSrS.shape, acc_dtype)
                    for i in cutlass.range_constexpr(0, cute.size(tSrS), 2):
                        p_f32x2 = fadd2((tSrS[i], tSrS[i+1]), (-tSrM[i], -tSrM[i+1]))
                        p_f32x2 = fmul2(p_f32x2, (scale_qs_log2_e, scale_qs_log2_e))
                        tSrP_f32[i] = exp2(p_f32x2[0])
                        tSrP_f32[i+1] = exp2(p_f32x2[1])
                    tSrP.store(tSrP_f32.load().to(mma_dtype))

                # Store P to smem
                p_handle = p_producer.acquire_and_advance()
                cute.autovec_copy(tSrP, tSsP[*cpy_dice, p_handle.index])
                cute.arch.fence_view_async_shared()
                p_handle.commit()

                # Compute correction and correct colsum
                if cutlass.const_expr(use_tensor_ssa_math):
                    correction = exp2(scale_qs_log2_e * (tSrM_prev.load() - tSrM.load()))
                    tSrL.store(tSrL.load() * correction + tSrP_f32)
                else:
                    correction = cute.make_rmem_tensor_like(tSrM)
                    for i in cutlass.range_constexpr(0, cute.size(tSrM), 2):
                        c_f32x2 = fadd2((tSrM_prev[i], tSrM_prev[i+1]), (-tSrM[i], -tSrM[i+1]))
                        c_f32x2 = fmul2(c_f32x2, (scale_qs_log2_e, scale_qs_log2_e))
                        c_f32x2 = (exp2(c_f32x2[0]), exp2(c_f32x2[1]))
                        correction[i] = c_f32x2[0]
                        correction[i+1] = c_f32x2[1]
                        l_f32x2 = ffma2(c_f32x2, (tSrL[i], tSrL[i+1]), (tSrP_f32[i], tSrP_f32[i+1]))
                        tSrL[i] = l_f32x2[0]
                        tSrL[i+1] = l_f32x2[1]

                # Correct O
                if s > 0:
                    # Wait for O
                    o_handle = o_consumer.wait_and_advance()

                    # Apply correction
                    for dm in cutlass.range_constexpr(tiles_dm):
                        tSrO_dm = cute.make_rmem_tensor_like(tSsO[*cpy_dice, 0, 0])
                        cute.copy(thr_load_s, tStO[*cpy_dice, dm, 0], tSrO_dm)

                        for i in cutlass.range_constexpr(0, cute.size(tSrO_dm), 2):
                            o_f32x2 = fmul2((tSrO_dm[i], tSrO_dm[i+1]), (correction[i], correction[i+1]))
                            tSrO_dm[i] = o_f32x2[0]
                            tSrO_dm[i+1] = o_f32x2[1]

                        cute.copy(thr_store_o, tSrO_dm, tStO[*cpy_dice, dm, 0])

                    # Notify MMA
                    cute.arch.fence_view_async_tmem_store()
                    o_handle.release()

                # Update colmax
                tSrM_prev.store(tSrM.load())

            #
            # Softmax Epilogue
            #

            # Reduce colsum in warp RF
            tSrL_lane = Float32(0.0)
            for i in cutlass.range_constexpr(cute.size(tSrL)):
                tSrL[i] = cute.arch.warp_reduction_sum(tSrL[i])
                if i == lane_idx:
                    tSrL_lane = tSrL[i]

            # Store partial colsum in smem
            if lane_store_max:
                tSsL[*cpy_dice, warpgroup_widx][lane_idx] = tSrL_lane

            # Reduce cluster colmax and correct O
            if do_cluster_reduction:
                # Reduce cluster colmax
                if warpgroup_widx == 0:
                    if lane_store_max:
                        self.dsmem_fmax(
                            sM_cluster.iterator + sM_layout((0, lane_idx)),
                            sM[(0, lane_idx)],
                            m_cluster_full_ptr
                        )

                # split 0 waits for cluster colmax to finish reduction
                # other splits wait for split 0 to notify cluster colmax is ready
                cute.arch.mbarrier_wait(m_cluster_full_ptr, phase=0)

                if warpgroup_widx == 0:
                    if kv_split_in_cluster == 0:
                        # notify other splits that cluster colmax is ready in split 0 smem
                        if lane_idx > 0 and lane_idx < kv_cluster_dim:
                            waiting_split_in_cluster = lane_idx
                            cute.arch.mbarrier_arrive(
                                m_cluster_full_ptr, waiting_split_in_cluster, arrive_count=1
                            )
                    else:
                        # other splits copy cluster colmax into local smem
                        if lane_store_max:
                            sM_cluster[0, lane_idx] = self.dsmem_load(
                                sM_cluster.iterator + sM_layout((0, lane_idx))
                            )

                # warpgroup waits for cluster colmax to load into local smem
                cute.arch.barrier(barrier_id=softmax_nbar_id, number_of_threads=warpgroup_threads)

                if warpgroup_widx == 0 and lane_store_max and inbound_hr:
                    # Load colsum and colmax
                    sL_lane_wg = sL[0, lane_idx, None]
                    sL_lane = sL_lane_wg[0] + sL_lane_wg[1] + sL_lane_wg[2] + sL_lane_wg[3]
                    sM_prev_lane = sM[0, lane_idx]
                    sM_lane = sM_cluster[0, lane_idx]

                    # Correct colsum and scale colmax
                    correction = exp2(scale_qs_log2_e * (sM_prev_lane - sM_lane))
                    sL_lane = sL_lane * correction
                    sM_lane = sM_lane * scale_qs

                    # Store colsum and colmax
                    self.gmem_fadd(
                        gL_partial.iterator + gL_partial.layout(lane_idx), sL_lane
                    )
                    self.gmem_fmax(gM.iterator + gM.layout(lane_idx), sM_lane)
                    if kv_split_in_cluster == 0:
                        gM_partial[lane_idx] = sM_lane

                # Load cluster colmax
                tSrM = cute.make_rmem_tensor_like(tSsM)
                cute.autovec_copy(tSsM_cluster, tSrM)

                # Wait and load O
                o_handle = o_consumer.wait_and_advance()
                cute.copy(thr_load_s, tStO, tSrO)
                cute.arch.fence_view_async_tmem_load()
                o_handle.release() # Final release signals tmem dealloc

                # Apply cluster correction
                if cutlass.const_expr(use_tensor_ssa_math):
                    correction = exp2(scale_qs_log2_e * (tSrM_prev.load() - tSrM.load()))
                    tSrO.store(tSrO.load() * correction)
                else:
                    correction = cute.make_rmem_tensor_like(tSsM)
                    for i in cutlass.range_constexpr(0, cute.size(tSrM), 2):
                        c_f32x2 = fadd2((tSrM_prev[i], tSrM_prev[i+1]), (-tSrM[i], -tSrM[i+1]))
                        c_f32x2 = fmul2(c_f32x2, (scale_qs_log2_e, scale_qs_log2_e))
                        correction[i] = exp2(c_f32x2[0])
                        correction[i+1] = exp2(c_f32x2[1])

                    for i in cutlass.range_constexpr(0, cute.size(tSrO), cute.size(correction)):
                        for j in cutlass.range_constexpr(0, cute.size(correction), 2):
                            o_f32x2 = fmul2((tSrO[i+j], tSrO[i+j+1]), (correction[j], correction[j+1]))
                            tSrO[i+j] = o_f32x2[0]
                            tSrO[i+j+1] = o_f32x2[1]
            
            # Wait and load O without cluster correction
            else:
                # Wait for colsum
                cute.arch.barrier(barrier_id=softmax_nbar_id, number_of_threads=warpgroup_threads)

                if warpgroup_widx == 0 and lane_store_max and inbound_hr:
                    # Load colsum and colmax
                    sL_lane_wg = sL[0, lane_idx, None]
                    sL_lane = sL_lane_wg[0] + sL_lane_wg[1] + sL_lane_wg[2] + sL_lane_wg[3]
                    sM_lane = sM[0, lane_idx]

                    # Scale colmax
                    sM_lane = sM_lane * scale_qs

                    # Store colsum and colmax
                    gL_partial[lane_idx] = sL_lane
                    gM_partial[lane_idx] = sM_lane
                    self.gmem_fmax(gM.iterator + gM.layout(lane_idx), sM_lane)

                o_handle = o_consumer.wait_and_advance()
                cute.copy(thr_load_s, tStO, tSrO)
                cute.arch.fence_view_async_tmem_load()
                o_handle.release() # Final release signals tmem dealloc

            # Store O to smem
            for dm in cutlass.range_constexpr(tiles_dm):
                tOrO_dm = tSrO[*cpy_dice, dm, 0]
                tOsO_dm = tSsO[*cpy_dice, dm, 0]

                cute.autovec_copy(tOrO_dm, tOsO_dm)
                cute.arch.fence_view_async_shared()

                # Reuse Q consumer barriers to notify O TMA store
                q_consumer.release()
                q_consumer.advance()


        # Ensure split 0 doesn't exit before all splits read cluster colmax
        if do_cluster_reduction:
            cute.arch.cluster_arrive_relaxed()
            if kv_split_in_cluster == 0 and warp_idx == self.tma_qo_warp_id:
                cute.arch.cluster_wait()

        return

    @staticmethod
    @cute.kernel
    def reduction(
        o : cute.Tensor,
        m : cute.Tensor,
        l : cute.Tensor,
        o_partial : cute.Tensor,
        m_partial : cute.Tensor,
        l_partial : cute.Tensor,
        scale_o : Float32,
    ):
        d_blk_idx, coord_h, coord_b = cute.arch.block_idx()
        d_per_blk, _, _ = cute.arch.block_dim()
        d_idx, _, _ = cute.arch.thread_idx()
        coord_d = d_blk_idx * d_per_blk + d_idx

        o_dhb = Float32(0)
        m_hb = m[coord_h, coord_b]
        l_hb = Float32(0)

        o_partial_dhb = o_partial[coord_d, coord_h, coord_b, None]
        m_partial_hb = m_partial[coord_h, coord_b, None]
        l_partial_hb = l_partial[coord_h, coord_b, None]

        for partial_idx in cutlass.range(o_partial.shape[-1]):
            correction = exp2(log2_e * (m_partial_hb[partial_idx] - m_hb))
            o_dhb += correction * o_partial_dhb[partial_idx]
            l_hb += correction * l_partial_hb[partial_idx]

        if coord_d < o.shape[0]:
            o[coord_d, coord_h, coord_b] = o.element_type(scale_o * (o_dhb / l_hb))

        if d_blk_idx == 0 and d_idx == 0:
            l[coord_h, coord_b] = m_hb + cute.math.log(l_hb, fastmath=False)

        return

    @staticmethod
    @cute.jit
    def _mapa(ptr : Pointer, cta_rank_in_cluster : Int32 = 0):
        llvm_ptr = ptr.llvm_ptr
        return nvvm.mapa_shared_cluster(
            llvm_ptr.type,
            llvm_ptr,
            Int32(cta_rank_in_cluster).ir_value(),
        )

    @cute.jit
    def dsmem_load(self, val_ptr: Pointer):
        val_llvm_ptr = self._mapa(val_ptr, 0)

        ret = llvm.inline_asm(
            Float32.mlir_type,
            [val_llvm_ptr],
            "ld.relaxed.cta.shared::cluster.f32 $0, [$1];",
            "=f,r",
            has_side_effects=False,
            is_align_stack=False,
            asm_dialect=llvm.AsmDialect.AD_ATT,
        )

        return Float32(ret)

    @staticmethod
    @cute.jit
    def warp_fmax(val : Float32):
        ret = llvm.inline_asm(
            Float32.mlir_type,
            [val.ir_value()],
            "redux.sync.max.NaN.f32 $0, $1, 0xffffffff;",
            "=f,f",
            has_side_effects=False,
            is_align_stack=False,
            asm_dialect=llvm.AsmDialect.AD_ATT,
        )
        return Float32(ret)

    @cute.jit
    def smem_fmax(ptr : Pointer, val : Float32):
        # https://stackoverflow.com/a/72461459
        # Works with canonical NaN which warp_redux_fmax should return
        llvm.inline_asm(
            None,
            [ptr.llvm_ptr, val.ir_value()],
            """{\n\t
                .reg .pred p;\n\t
                setp.lt.s32 p, $1, 0x0;
            @p  red.relaxed.shared::cta.min.u32 [$0], $1;\n\t
            @!p red.relaxed.shared::cta.max.s32 [$0], $1;\n\t
            }\n\t""",
            "r,r",
            has_side_effects=True,
            is_align_stack=False,
            asm_dialect=llvm.AsmDialect.AD_ATT,
        )

    @cute.jit
    def dsmem_fmax(self, val_ptr: Pointer, val: Float32, mbar_ptr: Pointer):
        expect_tx_bytes = Int32(Float32.width // 8)
        val_llvm_ptr = self._mapa(val_ptr, 0)
        mbar_llvm_ptr = self._mapa(mbar_ptr, 0)

        nvvm.mbarrier_txn(
            mbar_llvm_ptr,
            expect_tx_bytes.ir_value(),
            kind=nvvm.MBarrierTxnKind.ARRIVE_EXPECT_TX,
            space=nvvm.MBarrierSpaceKind.CLUSTER,
        )

        llvm.inline_asm(
            None,
            [val_llvm_ptr, val.ir_value(), mbar_llvm_ptr],
            """{\n\t
                .reg .pred p;\n\t
                setp.lt.s32 p, $1, 0x0;
            @p  red.async.relaxed.cluster.shared::cluster.mbarrier::complete_tx::bytes.min.u32 [$0], $1, [$2];\n\t
            @!p red.async.relaxed.cluster.shared::cluster.mbarrier::complete_tx::bytes.max.s32 [$0], $1, [$2];\n\t
            }\n\t""",
            "r,r,r",
            has_side_effects=True,
            is_align_stack=False,
            asm_dialect=llvm.AsmDialect.AD_ATT,
        )

    @staticmethod
    @cute.jit
    def gmem_fmax(ptr : Pointer, val : Float32):
        llvm.inline_asm(
            None,
            [ptr.llvm_ptr, val.ir_value()],
            """{\n\t
                .reg .pred p;\n\t
                setp.lt.s32 p, $1, 0x0;
            @p  red.relaxed.gpu.global.min.u32 [$0], $1;\n\t
            @!p red.relaxed.gpu.global.max.s32 [$0], $1;\n\t
            }\n\t""",
            "l,r",
            has_side_effects=True,
            is_align_stack=False,
            asm_dialect=llvm.AsmDialect.AD_ATT,
        )

    @cute.jit
    def smem_fadd(ptr : Pointer, val : Float32):
        # Expensive
        llvm.inline_asm(
            None,
            [ptr.llvm_ptr, val.ir_value()],
            "red.relaxed.shared::cta.add.f32 [$0], $1;",
            "r,f",
            has_side_effects=True,
            is_align_stack=False,
            asm_dialect=llvm.AsmDialect.AD_ATT,
        )

    @staticmethod
    @cute.jit
    def gmem_fadd(ptr : Pointer, val : Float32):
        llvm.inline_asm(
            None,
            [ptr.llvm_ptr, val.ir_value()],
            "red.relaxed.cluster.global.add.f32 [$0], $1;",
            "l,f",
            has_side_effects=True,
            is_align_stack=False,
            asm_dialect=llvm.AsmDialect.AD_ATT,
        )


def run(
    batches : int,
    seqlen : int,
    heads_q : int,
    heads_k : int,
    headdim : int,
    block_scaledim: int,
    kv_splits: int,
    kv_cluster_dim: int,
    q_dtype: Type[cutlass.Numeric],
    kv_dtype: Type[cutlass.Numeric],
    o_dtype: Type[cutlass.Numeric],
    acc_dtype: Type[cutlass.Numeric],
    tolerance: float,
    scale_q: float,
    scale_o: float,
    scale_s: float,
    warmup_iterations: int,
    iterations: int,
    skip_ref_check: bool,
    use_cold_l2: bool = False,
    **kwargs,
):
    print(f"Running Blackwell SM100 Mixed Input FMHA Decode test with:")
    print(f"\tbatches: {batches}, seqlen: {seqlen}")
    print(f"\theads_q: {heads_q}, heads_k: {heads_k}")
    print(f"\theaddim: {headdim}, block_scaledim: {block_scaledim}")
    print(f"\tkv_splits: {kv_splits}, kv_cluster_dim: {kv_cluster_dim}")
    print(f"\tq_dtype: {q_dtype}")
    print(f"\tkv_dtype: {kv_dtype}")
    print(f"\to_dtype: {o_dtype}")
    print(f"\tacc_dtype: {acc_dtype}")
    print(f"\ttolerance: {tolerance}")
    print(f"\tscale_q: {scale_q}")
    print(f"\tscale_o: {scale_o}")
    print(f"\tscale_s: {scale_s}")
    print(f"\twarmup_iterations: {warmup_iterations}")
    print(f"\titerations: {iterations}")
    print(f"\tskip_ref_check: {skip_ref_check}")
    print(f"\tuse_cold_l2: {use_cold_l2}")

    if not torch.cuda.is_available():
        raise RuntimeError("GPU is required to run this example!")

    #
    # Config Kernel
    #
    grouped_heads = heads_q // heads_k
    fmha = MixedInputFusedMultiHeadAttentionDecode(
        headdim=headdim,
        block_scaledim=block_scaledim,
        grouped_head_tile=min(cute.round_up(grouped_heads, 8), 32),
        dual_convert=(headdim > 128),
        deterministic=(kv_cluster_dim == 1),
    )

    if scale_s == 0.0:  # default to 1/sqrt(d)
        scale_s = 1.0 / math.sqrt(headdim)
    scale_qs = scale_q * scale_s

    if kv_splits == 0:
        hardware_info = cutlass.utils.HardwareInfo()
        sm_count = hardware_info.get_device_multiprocessor_count()
        sm_count = 148 if sm_count <= 0 else sm_count
        grid_yz = batches * heads_k * math.ceil(grouped_heads / fmha.grouped_head_tile)
        kv_splits = sm_count // grid_yz # 1 wave
        kv_splits = max(1, kv_splits)
        if sm_count == 148 and grid_yz == 32:
            kv_splits = 9 # 2 waves
        print(f"\tauto kv_splits: {kv_splits}")

    seqlen_q = 1
    seqlen_k = seqlen
    kv_clusters = kv_splits // kv_cluster_dim

    problem_shape = (batches, heads_q, heads_k, seqlen_k, headdim)

    fmha.can_implement(problem_shape, kv_splits, kv_cluster_dim, q_dtype, kv_dtype, o_dtype, acc_dtype)

    #
    # Allocate Tensors
    #
    torch.manual_seed(1111)
    def create_tensor(shape, dtype, init = True):
        init_type = cutlass.torch.TensorInitType.RANDOM
        init_config = cutlass.torch.RandomInitConfig(min_val=-2, max_val=2)

        if init is False or init is None:
            init_type = cutlass.torch.TensorInitType.SKIP
            init_config = None
        elif isinstance(init, int) or isinstance(init, float):
            init_type = cutlass.torch.TensorInitType.SCALAR
            init_config = cutlass.torch.ScalarInitConfig(value=init)
        elif isinstance(init, tuple) or isinstance(init, list):
            if len(init) == 2:
                init_type = cutlass.torch.TensorInitType.RANDOM
                init_config = cutlass.torch.RandomInitConfig(min_val=init[0], max_val=init[1])
            if len(init) == 3:
                init_type = cutlass.torch.TensorInitType.GAUSSIAN
                init_config = cutlass.torch.RandomInitConfig(mean=init[0], std=init[1], scale=init[2])

        f32_torch_tensor = cutlass_torch.create_and_permute_torch_tensor(
            shape,
            torch.float32,
            permute_order=None,
            init_type=init_type,
            init_config=init_config,
        )

        _, torch_tensor = cutlass_torch.cute_tensor_like(
            f32_torch_tensor,
            dtype,
            is_dynamic_layout=True,
            assumed_align=16,
        )

        # Create dtype cute tensor with offset (gpu)
        cute_tensor = from_dlpack(torch_tensor, assumed_align=16)
        cute_tensor.element_type = dtype

        return (
            f32_torch_tensor,
            cute_tensor,
            torch_tensor,
        )

    qo_shape = (kv_clusters, batches, heads_q, seqlen_q, headdim)
    kv_shape = (             batches, heads_k, seqlen_k, headdim)
    scale_shape = (          batches, heads_k, seqlen_k, fmha.scaledim)

    q_ref, q_cute, q_torch = create_tensor(qo_shape[1:], q_dtype, init=[-8,7])
    k_ref, k_cute, k_torch = create_tensor(kv_shape, kv_dtype, init=[-8,7])
    v_ref, v_cute, v_torch = create_tensor(kv_shape, kv_dtype, init=[-8,7])
    k_scale_ref, k_scale_cute, k_scale_torch = create_tensor(scale_shape, q_dtype, init=[-2, 2])
    v_scale_ref, v_scale_cute, v_scale_torch = create_tensor(scale_shape, q_dtype, init=[-2, 2])
    _, o_cute, o_torch = create_tensor(qo_shape[1:], o_dtype, init=False)
    _, m_cute, m_torch = create_tensor(qo_shape[1:-1], acc_dtype, init=-math.inf)
    _, l_cute, l_torch = create_tensor(qo_shape[1:-1], acc_dtype, init=False)
    _, o_partial_cute, o_partial_torch = create_tensor(qo_shape, acc_dtype, init=0)
    _, m_partial_cute, m_partial_torch = create_tensor(qo_shape[:-1], acc_dtype, init=-math.inf)
    _, l_partial_cute, l_partial_torch = create_tensor(qo_shape[:-1], acc_dtype, init=0)

    #
    # Compile
    #
    current_stream = cutlass_torch.default_stream()
    compiled_fmha = cute.compile(
        fmha,
        problem_shape,
        kv_splits,
        kv_cluster_dim,
        q_cute.iterator,
        k_cute.iterator,
        v_cute.iterator,
        k_scale_cute.iterator,
        v_scale_cute.iterator,
        o_cute.iterator,
        m_cute.iterator,
        l_cute.iterator,
        o_partial_cute.iterator,
        m_partial_cute.iterator,
        l_partial_cute.iterator,
        scale_qs,
        scale_o,
        current_stream,
        options=f"--opt-level 2",
    )
    print("Finished Compiling")

    #
    # Refcheck
    #
    def run_torch_fmha(q_ref, k_ref, v_ref, k_scale_ref, v_scale_ref, scale_qs=1.0, scale_o=1.0):
        for i in range(0, headdim // block_scaledim):
            j = i * block_scaledim
            k_ref[..., j:j+block_scaledim] *= k_scale_ref[..., i:i+1]
            v_ref[..., j:j+block_scaledim] *= v_scale_ref[..., i:i+1]

        with sdpa_kernel([SDPBackend.FLASH_ATTENTION, SDPBackend.MATH], set_priority=True):
            o_ref = scaled_dot_product_attention(
                q_ref,
                k_ref,
                v_ref,
                attn_mask=None,
                dropout_p=0.0,
                scale=scale_qs,
                is_causal=False,
                enable_gqa=(heads_q != heads_k),
            )

        return o_ref * scale_o

    if not skip_ref_check:
        # Execute kernel once for reference checking
        print("Running...")
        compiled_fmha(
            problem_shape,
            kv_splits,
            kv_cluster_dim,
            q_cute.iterator,
            k_cute.iterator,
            v_cute.iterator,
            k_scale_cute.iterator,
            v_scale_cute.iterator,
            o_cute.iterator,
            m_cute.iterator,
            l_cute.iterator,
            o_partial_cute.iterator,
            m_partial_cute.iterator,
            l_partial_cute.iterator,
            scale_qs,
            scale_o,
            current_stream,
        )
        print("Verifying results...")
        o_ref = run_torch_fmha(q_ref, k_ref, v_ref, k_scale_ref, v_scale_ref, scale_qs, scale_o)
        torch.testing.assert_close(o_ref, o_torch.float().cpu(), atol=tolerance, rtol=1e-05)

    def generate_tensors():
        _, q_cute, _ = create_tensor(qo_shape[1:], q_dtype, init=[-8,7])
        _, k_cute, _ = create_tensor(kv_shape, kv_dtype, init=[-8,7])
        _, v_cute, _ = create_tensor(kv_shape, kv_dtype, init=[-8,7])
        _, k_scale_cute, _ = create_tensor(scale_shape, q_dtype, init=[-8,7])
        _, v_scale_cute, _ = create_tensor(scale_shape, q_dtype, init=[-8,7])
        _, o_cute, _ = create_tensor(qo_shape[1:], o_dtype, init=False)
        _, m_cute, _ = create_tensor(qo_shape[1:-1], acc_dtype, init=-math.inf)
        _, l_cute, _ = create_tensor(qo_shape[1:-1], acc_dtype, init=False)
        _, o_partial_cute, _ = create_tensor(qo_shape, acc_dtype, init=0)
        _, m_partial_cute, _ = create_tensor(qo_shape[:-1], acc_dtype, init=-math.inf)
        _, l_partial_cute, _ = create_tensor(qo_shape[:-1], acc_dtype, init=0)
        return testing.JitArguments(
            problem_shape,
            kv_splits,
            kv_cluster_dim,
            q_cute.iterator,
            k_cute.iterator,
            v_cute.iterator,
            k_scale_cute.iterator,
            v_scale_cute.iterator,
            o_cute.iterator,
            m_cute.iterator,
            l_cute.iterator,
            o_partial_cute.iterator,
            m_partial_cute.iterator,
            l_partial_cute.iterator,
            scale_qs,
            scale_o,
            current_stream,
        )

    #
    # Profile
    #
    workspace_count = 1
    if use_cold_l2:
        q_torch_effective = q_torch.values() if q_torch.is_nested else q_torch
        k_torch_effective = k_torch.values() if k_torch.is_nested else k_torch
        v_torch_effective = v_torch.values() if v_torch.is_nested else v_torch
        k_scale_torch_effective = k_scale_torch.values() if k_scale_torch.is_nested else k_scale_torch
        v_scale_torch_effective = v_scale_torch.values() if v_scale_torch.is_nested else v_scale_torch
        o_torch_effective = o_torch.values() if o_torch.is_nested else o_torch
        m_torch_effective = m_torch.values() if m_torch.is_nested else m_torch
        l_torch_effective = l_torch.values() if l_torch.is_nested else l_torch
        o_partial_torch_effective = o_partial_torch.values() if o_partial_torch.is_nested else o_partial_torch
        m_partial_torch_effective = m_partial_torch.values() if m_partial_torch.is_nested else m_partial_torch
        l_partial_torch_effective = l_partial_torch.values() if l_partial_torch.is_nested else l_partial_torch
        one_workspace_bytes = (
            q_torch_effective.numel() * q_torch_effective.element_size()
            + k_torch_effective.numel() * k_torch_effective.element_size()
            + v_torch_effective.numel() * v_torch_effective.element_size()
            + k_scale_torch_effective.numel() * k_scale_torch_effective.element_size()
            + v_scale_torch_effective.numel() * v_scale_torch_effective.element_size()
            + o_torch_effective.numel() * o_torch_effective.element_size()
            + m_torch_effective.numel() * m_torch_effective.element_size()
            + l_torch_effective.numel() * l_torch_effective.element_size()
            + o_partial_torch_effective.numel() * o_partial_torch_effective.element_size()
            + m_partial_torch_effective.numel() * m_partial_torch_effective.element_size()
            + l_partial_torch_effective.numel() * l_partial_torch_effective.element_size()
        )
        workspace_count = testing.get_workspace_count(
            one_workspace_bytes, warmup_iterations, iterations
        )

    exec_time = 0.0
    if iterations > 0:
        exec_time = testing.benchmark(
            compiled_fmha,
            workspace_generator=generate_tensors,
            workspace_count=workspace_count,
            stream=current_stream,
            warmup_iterations=warmup_iterations,
            iterations=iterations,
        )
        print(exec_time)

    return exec_time  # Return execution time in microseconds

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
        "--batches","--batch","--b",
        type=int,
        default=1,
        help="batch size"
    )

    parser.add_argument(
        "--seqlen","--seqlen_k","--seq","--s",
        type=int,
        default=1024,
        help="key/value sequence length"
    )

    parser.add_argument(
        "--heads_q","--h_q",
        type=int,
        default=32,
        help="query heads"
    )

    parser.add_argument(
        "--heads_k","--h_k",
        type=int,
        default=4,
        help="key/value heads"
    )

    parser.add_argument(
        "--headdim","--d",
        type=int,
        default=512,
        help="head dimmension"
    )

    parser.add_argument(
        "--block_scaledim","--bs",
        type=int,
        default=512,
        help="headdim per scale factor"
    )

    parser.add_argument(
        "--kv_splits","--splits",
        type=int,
        default=0,
        help="threadblocks per sequence",
    )

    parser.add_argument(
        "--kv_cluster_dim","--cluster",
        type=int,
        default=1,
        help="threadblocks per partial buffer",
    )

    parser.add_argument(
        "--q_dtype",
        type=cutlass.dtype,
        default=cutlass.BFloat16,
        help="query data type",
    )

    parser.add_argument(
        "--kv_dtype",
        type=cutlass.dtype,
        default=cutlass.Int8,
        help="key/value data type",
    )

    parser.add_argument(
        "--o_dtype",
        type=cutlass.dtype,
        default=cutlass.BFloat16,
        help="output data type",
    )

    parser.add_argument(
        "--acc_dtype",
        type=cutlass.dtype,
        default=Float32,
        help="accumulator/reduction data type",
    )

    parser.add_argument(
        "--tolerance", type=float, default=1e-01, help="Tolerance for validation"
    )

    parser.add_argument(
        "--scale_q",
        type=float,
        default=1.0,
        help="query scale factor",
    )

    parser.add_argument(
        "--scale_o",
        type=float,
        default=1.0,
        help="output scale factor",
    )

    parser.add_argument(
        "--scale_s","--scale",
        type=float,
        default=0.0,
        help="score (Q*K) scale factor; if zero, defaults to 1/sqrt(D)",
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
        default=0,
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

    run(
        args.batches,
        args.seqlen,
        args.heads_q,
        args.heads_k,
        args.headdim,
        args.block_scaledim,
        args.kv_splits,
        args.kv_cluster_dim,
        args.q_dtype,
        args.kv_dtype,
        args.o_dtype,
        args.acc_dtype,
        args.tolerance,
        args.scale_q,
        args.scale_o,
        args.scale_s,
        args.warmup_iterations,
        args.iterations,
        args.skip_ref_check,
        args.use_cold_l2,
    )

    print("PASS")
