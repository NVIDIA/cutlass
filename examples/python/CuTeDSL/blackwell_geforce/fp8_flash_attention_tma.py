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

"""
FP8 Flash Attention v2 for SM120 — TMA + warp specialization variant.

Combines the BF16 TMA kernel's infrastructure (TMA loads, warp specialization,
multi-stage KV pipeline, mbarrier sync) with the FP8 inline-PTX MMA path.

Key differences from FP8FlashAttentionSm120Opt (CpAsync):
  - TMA (cp.async.bulk) instead of CpAsync for GMEM→SMEM
  - 1 dedicated DMA warp + 4 MMA warps (warp specialization)
  - kv_stages=2 double-buffered K/V SMEM via PipelineTmaAsync
  - mbarrier-based producer/consumer sync
  - Default tile sizing M=128, N=32 (canonical for SM120 TMA + FP8), vs M=64, N=32

Key differences from BF16 TMA (FlashAttentionForwardSm120Tma):
  - FP8 e4m3 MMA via inline PTX kind::f8f6f4.m16n8k32 (no atom in cutlass-dsl 4.4.2)
  - All Q/K/V via inline-PTX ldmatrix.x4(.trans) on swizzled SMEM (manual
    swizzle bit-math: addr ^ (((addr >> 7) & ((1<<B)-1)) << 4))
  - Register-resident P via warp-shuffle redistribution (no sP_f32 SMEM)
  - Per-thread bridge required: gid/tip swap in f8f6f4 B operand layout means
    ldmatrix output doesn't directly produce B-operand register layout (Q: 4
    shuffles/call; K: 8 shuffles + 4 prmt; V: 16 shuffles + 8 selp + 4 prmt)

Output dtype:
  - FP32 (default): pass torch.float32 output tensor (use make_cute_f32)
  - BF16:           pass torch.bfloat16 output (use make_cute_bf16) — single-
    instruction cvt.rn.bf16x2.f32 + packed Int32 store. Matches the production
    FP8 attention pattern (FP8 in, BF16 out).

Perf (DGX Spark / SM121a, sum-time over the 16-config Aneureka matrix,
median of 50 iters per config, F32 output, N=32 default):
  - 1.10x vs FP8FlashAttentionSm120Opt
  - 0.91x vs FlashAttentionForwardSm120Tma (BF16 TMA, BF16 output)
  - With per-shape N picked by `benchmark_fp8_vs_bf16.py` (N=64 only on
    non-causal D=128 high-CTA shapes): 0.93x of BF16 TMA sum-time, with
    multiple configs ≥1.0x of BF16 (e.g. B=1 S=512 D=64: 1.04x; B=1 S=2048
    D=64: 1.06x; B=4 S=512 D=64: 1.03x).
  - Decisive peak on B=4 S=1024 D=128 non-causal: 1.47x of FP8 Opt at N=64.
  - Remaining gap to BF16 TMA is structural — the f8f6f4 layout's bridge
    cost (esp. PV's V bridge: 16 shuffles + 8 selp + 4 prmt per ldmatrix call)
    can't be eliminated without an FP8 m16n8k32 TiledMma atom (CUTLASS #3044).
"""

import argparse
from typing import Type

import torch
import cuda.bindings.driver as cuda

import cutlass
import cutlass.cute as cute
import cutlass.cute.testing as testing
import cutlass.torch as cutlass_torch
from cutlass.cute.nvgpu import cpasync
from cutlass.cute.runtime import from_dlpack
from cutlass.cutlass_dsl import T, dsl_user_op
from cutlass._mlir import ir
from cutlass._mlir.dialects import llvm
from cutlass.cute.typing import Int32, Float32
import cutlass.pipeline as pipeline
import cutlass.utils as utils


# /////////////////////////////////////////////////////////////////////////////
# Inline PTX helpers (copied from fp8_flash_attention.py)
# /////////////////////////////////////////////////////////////////////////////

@dsl_user_op
def mma_f8f6f4_m16n8k32_e4m3(
    a0, a1, a2, a3, b0, b1, c0, c1, c2, c3,
    *, loc=None, ip=None,
):
    """kind::f8f6f4.m16n8k32.row.col.f32.e4m3.e4m3.f32"""
    vals = [Int32(x).ir_value(loc=loc, ip=ip) for x in [a0, a1, a2, a3, b0, b1]]
    accs = [Float32(x).ir_value(loc=loc, ip=ip) for x in [c0, c1, c2, c3]]
    ret = llvm.inline_asm(
        ir.Type.parse("!llvm.struct<(f32,f32,f32,f32)>"),
        vals + accs,
        "mma.sync.aligned.kind::f8f6f4.m16n8k32.row.col.f32.e4m3.e4m3.f32 "
        "{$0,$1,$2,$3},{$4,$5,$6,$7},{$8,$9},{$10,$11,$12,$13};",
        "=f,=f,=f,=f,r,r,r,r,r,r,f,f,f,f",
        has_side_effects=True, asm_dialect=0, loc=loc, ip=ip,
    )
    return tuple(
        Float32(llvm.extractvalue(T.f32(), ret, [i], loc=loc, ip=ip))
        for i in range(4)
    )


@dsl_user_op
def bitcast_f32_to_i32(val, *, loc=None, ip=None):
    f32_ir = Float32(val).ir_value(loc=loc, ip=ip)
    return Int32(llvm.bitcast(T.i32(), f32_ir, loc=loc, ip=ip))


@dsl_user_op
def bitcast_i32_to_f32(val, *, loc=None, ip=None):
    i32_ir = Int32(val).ir_value(loc=loc, ip=ip)
    return Float32(llvm.bitcast(T.f32(), i32_ir, loc=loc, ip=ip))


@dsl_user_op
def transpose_4x4_bytes(r0, r1, r2, r3, *, loc=None, ip=None):
    """Transpose a 4x4 byte matrix in registers using prmt.b32."""
    args = [Int32(x).ir_value(loc=loc, ip=ip) for x in [r0, r1, r2, r3]]
    ret = llvm.inline_asm(
        ir.Type.parse("!llvm.struct<(i32,i32,i32,i32)>"),
        args,
        "{\n\t"
        ".reg .b32 lo01, hi01, lo23, hi23;\n\t"
        "prmt.b32 lo01, $4, $5, 0x5140;\n\t"
        "prmt.b32 hi01, $4, $5, 0x7362;\n\t"
        "prmt.b32 lo23, $6, $7, 0x5140;\n\t"
        "prmt.b32 hi23, $6, $7, 0x7362;\n\t"
        "prmt.b32 $0, lo01, lo23, 0x5410;\n\t"
        "prmt.b32 $1, lo01, lo23, 0x7632;\n\t"
        "prmt.b32 $2, hi01, hi23, 0x5410;\n\t"
        "prmt.b32 $3, hi01, hi23, 0x7632;\n\t"
        "}",
        "=r,=r,=r,=r,r,r,r,r",
        has_side_effects=False, asm_dialect=0, loc=loc, ip=ip,
    )
    return tuple(
        Int32(llvm.extractvalue(T.i32(), ret, [i], loc=loc, ip=ip))
        for i in range(4)
    )


@dsl_user_op
def prmt_b32(a, b, selector, *, loc=None, ip=None):
    """prmt.b32: per-byte permutation between two i32 sources.

    Each of the 4 output bytes is selected by 4 bits of `selector` (low 16 bits):
    bits [3:0] → out[0], [7:4] → out[1], [11:8] → out[2], [15:12] → out[3].
    A nibble value 0..3 picks bytes 0..3 of `a`; 4..7 picks bytes 0..3 of `b`.
    """
    args = [Int32(x).ir_value(loc=loc, ip=ip) for x in [a, b, selector]]
    return Int32(llvm.inline_asm(
        T.i32(), args,
        "prmt.b32 $0, $1, $2, $3;",
        "=r,r,r,r",
        has_side_effects=False, asm_dialect=0, loc=loc, ip=ip,
    ))


@dsl_user_op
def selp_b32(a, b, cond_i32, *, loc=None, ip=None):
    """selp.b32: result = (cond != 0) ? a : b. Inline-PTX bypasses any DSL
    ternary issues with Int32 selection (notably: post-selection values get
    read by `shuffle_sync` from the SOURCE lane's post-selection state, which
    differs by source thread's q).  Pattern is shuffle-r0/r2-individually
    then select locally."""
    args = [Int32(x).ir_value(loc=loc, ip=ip) for x in [a, b, cond_i32]]
    return Int32(llvm.inline_asm(
        T.i32(), args,
        "{ .reg .pred p; setp.ne.s32 p, $3, 0; selp.b32 $0, $1, $2, p; }",
        "=r,r,r,r",
        has_side_effects=False, asm_dialect=0, loc=loc, ip=ip,
    ))


@dsl_user_op
def cvta_to_shared_u32(ptr, *, loc=None, ip=None):
    """Convert a CuTe SMEM Pointer to a u32 in PTX shared address space.

    PTX `ldmatrix` and friends take a u32 SMEM-space address ([..r..] operand).
    The cutlass-dsl `Pointer.llvm_ptr` returns an LLVM ptr already in
    addrspace(3) for SMEM tensors; ptrtoint to i32 truncates that to the
    32-bit shared address.
    """
    return Int32(llvm.ptrtoint(T.i32(), ptr.llvm_ptr, loc=loc, ip=ip))


@dsl_user_op
def ldmatrix_x4_trans_b16(smem_addr, *, loc=None, ip=None):
    """ldmatrix.sync.aligned.m8n8.x4.trans.shared.b16 — load 4 transposed 8x8
    b16 matrices.  Each lane provides one 16-byte-aligned shared-space u32
    address pointing to an 8-b16 row.  Returns 4 i32 per thread (8 b16 = 8 FP8
    pairs total).  Lane mapping: lane t supplies addr for matrix `t/8`, row `t%8`.
    """
    addr_ir = Int32(smem_addr).ir_value(loc=loc, ip=ip)
    ret = llvm.inline_asm(
        ir.Type.parse("!llvm.struct<(i32,i32,i32,i32)>"),
        [addr_ir],
        "ldmatrix.sync.aligned.m8n8.x4.trans.shared.b16 {$0,$1,$2,$3}, [$4];",
        "=r,=r,=r,=r,r",
        has_side_effects=True, asm_dialect=0, loc=loc, ip=ip,
    )
    return tuple(
        Int32(llvm.extractvalue(T.i32(), ret, [i], loc=loc, ip=ip))
        for i in range(4)
    )


@dsl_user_op
def ldmatrix_x4_b16(smem_addr, *, loc=None, ip=None):
    """ldmatrix.sync.aligned.m8n8.x4.shared.b16 (NO trans) — load 4 b16
    matrices in natural row-major order. Used for Q loading where sQ's
    [m, d] layout already matches MMA A operand's m × k orientation.
    """
    addr_ir = Int32(smem_addr).ir_value(loc=loc, ip=ip)
    ret = llvm.inline_asm(
        ir.Type.parse("!llvm.struct<(i32,i32,i32,i32)>"),
        [addr_ir],
        "ldmatrix.sync.aligned.m8n8.x4.shared.b16 {$0,$1,$2,$3}, [$4];",
        "=r,=r,=r,=r,r",
        has_side_effects=True, asm_dialect=0, loc=loc, ip=ip,
    )
    return tuple(
        Int32(llvm.extractvalue(T.i32(), ret, [i], loc=loc, ip=ip))
        for i in range(4)
    )


@dsl_user_op
def cvt_f32x2_to_bf16x2(v0, v1, *, loc=None, ip=None):
    """Pack 2 FP32 → 2 BF16 in a 32-bit register (low: v0, high: v1).

    Uses cvt.rn.bf16x2.f32 — single PTX instruction, no rounding penalty.
    """
    args = [Float32(x).ir_value(loc=loc, ip=ip) for x in [v0, v1]]
    return Int32(llvm.inline_asm(
        T.i32(), args,
        "cvt.rn.bf16x2.f32 $0, $2, $1;",
        "=r,f,f",
        has_side_effects=False, asm_dialect=0, loc=loc, ip=ip,
    ))


@dsl_user_op
def cvt_f32_to_fp8x4(v0, v1, v2, v3, *, loc=None, ip=None):
    """Pack 4 FP32 → 4 FP8 e4m3 bytes in uint32."""
    args = [Float32(x).ir_value(loc=loc, ip=ip) for x in [v0, v1, v2, v3]]
    return Int32(llvm.inline_asm(
        T.i32(), args,
        "{\n\t"
        ".reg .b16 lo, hi;\n\t"
        "cvt.rn.satfinite.e4m3x2.f32 lo, $2, $1;\n\t"
        "cvt.rn.satfinite.e4m3x2.f32 hi, $4, $3;\n\t"
        "mov.b32 $0, {lo, hi};\n\t"
        "}",
        "=r,f,f,f,f",
        has_side_effects=False, asm_dialect=0, loc=loc, ip=ip,
    ))


# Register-resident P uses warp shuffles that redistribute the m16n8k32 C-layout
# (per-thread QK output) into the m16n8k32 A-layout (per-thread PV input),
# skipping the sP_f32 SMEM round-trip.  See `fp8_mma_layout.md` for derivation
# of the source-lane formula `src_lane_a = gid*4 + (tip%2)*2`.
# The pattern is inlined in the kernel rather than factored into a helper
# because cutlass-dsl's preprocessing of dynamic Boolean ternaries doesn't
# compose cleanly across function-call boundaries.


# /////////////////////////////////////////////////////////////////////////////
# FP8 Flash Attention with TMA + warp specialization
# /////////////////////////////////////////////////////////////////////////////

class FP8FlashAttentionSm120Tma:
    """FP8 Flash Attention for SM120 using TMA + warp specialization.

    Tile config (defaults — `can_implement` checks alternates):
      - m_block_size=128 (4 MMA warps × 32 rows/warp = 2 m16 row groups)
      - n_block_size=32 (default; N=64 wins on B*H≥64 D=128 non-causal)
      - kv_stages=2 (K/V double-buffered via PipelineTmaAsync)
      - 1 DMA warp + 4 MMA warps = 160 threads/block

    Per-shape N choice: empirically, N=32 wins on causal cases (smaller per-K-
    iter overhead matters when causal halves the work) and small/medium D=64
    shapes. N=64 wins on big-batch non-causal D=128 (more work per iter
    amortizes the bridge cost). The kernel exposes n_block_size; the bench
    `benchmark_fp8_vs_bf16.py` picks per shape automatically.

    SMEM budget at M=128, N=64, D=128, kv_stages=2:
      - sQ FP8: 128*128 = 16 KB
      - sK FP8: 64*128*2 = 16 KB
      - sV FP8: 64*128*2 = 16 KB
      - sP / sVt: NONE — P is held in registers via warp shuffles, V is loaded
        directly from sV via ldmatrix.x4.trans (no transpose-staging buffer).
      - mbar arrays + 1024-byte alignments: ~5 KB
      - Total: ~53 KB (well under 99 KB SM120 budget)
    """

    def __init__(
        self,
        head_dim: int,
        m_block_size: int = 128,
        n_block_size: int = 32,
        num_mma_warps: int = 4,
        kv_stages: int = 2,
        is_causal: bool = False,
    ):
        assert head_dim % 32 == 0
        assert m_block_size % (num_mma_warps * 16) == 0, \
            "m_block_size must be a multiple of num_mma_warps * 16"
        self._head_dim = head_dim
        self._head_dim_padded = (head_dim + 31) // 32 * 32
        self._m_block_size = m_block_size
        self._n_block_size = n_block_size
        self._num_mma_warps = num_mma_warps
        self._kv_stages = kv_stages
        self._is_causal = is_causal
        self._num_threads = (num_mma_warps + 1) * 32  # +1 DMA warp

        self.mma_sync_barrier = pipeline.NamedBarrier(
            barrier_id=1, num_threads=num_mma_warps * 32
        )
        self.load_register_requirement = 40
        self.mma_register_requirement = 232

    @staticmethod
    def can_implement(
        head_dim, m_block_size, n_block_size, num_mma_warps, kv_stages, is_causal,
    ) -> bool:
        """Returns True if the (head_dim, tile sizes, stages) config fits SM120.

        Checks: head_dim multiple of 32; m_block_size compatible with the warp
        tiling (each warp owns 16 rows); SMEM total fits SM120's 99 KB budget.
        """
        if head_dim % 32 != 0:
            return False
        if m_block_size % (num_mma_warps * 16) != 0:
            return False
        if n_block_size % 8 != 0:
            return False
        if num_mma_warps != 4:
            # Per-warp masking + transpose work split currently assume 4 MMA warps.
            return False
        head_dim_padded = (head_dim + 31) // 32 * 32
        # SMEM bytes: sQ + sK + sV + mbar arrays.  sP and sVt are not
        # allocated: P is held in registers via warp shuffles; V is loaded
        # directly via ldmatrix.x4.trans from sV (no transpose staging).
        smem_q = m_block_size * head_dim_padded
        smem_kv = n_block_size * head_dim_padded * kv_stages
        smem_mbar = (1 + 2 * kv_stages * 2) * 8
        align_pad = 1024 * 3
        smem_total = smem_q + smem_kv * 2 + smem_mbar + align_pad
        smem_capacity = utils.get_smem_capacity_in_bytes("sm_120")
        if smem_total > smem_capacity:
            return False
        return True

    @cute.jit
    def __call__(
        self,
        mQ: cute.Tensor,
        mK: cute.Tensor,
        mV: cute.Tensor,
        mO: cute.Tensor,
        softmax_scale: cutlass.Float32,
        stream: cuda.CUstream,
    ):
        fp8 = cutlass.Float8E4M3FN
        D = self._head_dim_padded
        M = self._m_block_size
        N = self._n_block_size

        # /////////////////////////////////////////////////////////////////////
        # SMEM layouts.  All ldmatrix-based: sQ, sK, sV all use TMA-compatible
        # swizzled layout. sQ used by Q register cache load (ldmatrix.x4 no trans),
        # sK and sV used by ldmatrix.x4.trans in QK and PV GEMMs.
        # /////////////////////////////////////////////////////////////////////
        smem_k_block_size_kv, swizzle_bits_kv = (
            (128, 3) if D >= 128 else (64, 2) if D >= 64 else (32, 1)
        )
        sQKV_layout_atom = cute.make_composed_layout(
            cute.make_swizzle(swizzle_bits_kv, 4, 3),
            0,
            cute.make_layout((8, smem_k_block_size_kv), stride=(smem_k_block_size_kv, 1)),
        )
        sQ_layout_staged = cute.tile_to_shape(
            sQKV_layout_atom, (M, D, 1), (0, 1, 2),
        )
        sQ_one_layout = cute.slice_(sQ_layout_staged, (None, None, 0))
        sKV_layout_staged = cute.tile_to_shape(
            sQKV_layout_atom, (N, D, self._kv_stages), (0, 1, 2),
        )
        sKV_one_layout = cute.slice_(sKV_layout_staged, (None, None, 0))
        sV_layout_staged = sKV_layout_staged
        sV_one_layout = sKV_one_layout

        # /////////////////////////////////////////////////////////////////////
        # Reshape tensors for TMA: (batch, seq, head, dim) → (seq, dim, head, batch)
        # /////////////////////////////////////////////////////////////////////
        mQ_for_tma = cute.make_tensor(
            mQ.iterator,
            cute.make_layout(
                (mQ.shape[1], mQ.shape[3], mQ.shape[2], mQ.shape[0]),
                stride=(mQ.stride[1], mQ.stride[3], mQ.stride[2], mQ.stride[0]),
            ),
        )
        mK_for_tma = cute.make_tensor(
            mK.iterator,
            cute.make_layout(
                (mK.shape[1], mK.shape[3], mK.shape[2], mK.shape[0]),
                stride=(mK.stride[1], mK.stride[3], mK.stride[2], mK.stride[0]),
            ),
        )
        mV_for_tma = cute.make_tensor(
            mV.iterator,
            cute.make_layout(
                (mV.shape[1], mV.shape[3], mV.shape[2], mV.shape[0]),
                stride=(mV.stride[1], mV.stride[3], mV.stride[2], mV.stride[0]),
            ),
        )

        # TMA atoms
        tma_op = cpasync.CopyBulkTensorTileG2SOp()
        tma_atom_q, tma_tensor_q = cpasync.make_tiled_tma_atom(
            tma_op, mQ_for_tma, sQ_one_layout,
            (M, D), num_multicast=1,
        )
        tma_atom_k, tma_tensor_k = cpasync.make_tiled_tma_atom(
            tma_op, mK_for_tma, sKV_one_layout,
            (N, D), num_multicast=1,
        )
        tma_atom_v, tma_tensor_v = cpasync.make_tiled_tma_atom(
            tma_op, mV_for_tma, sV_one_layout,
            (N, D), num_multicast=1,
        )

        q_copy_bytes = cute.size_in_bytes(fp8, sQ_one_layout)
        kv_copy_bytes = cute.size_in_bytes(fp8, sKV_one_layout)

        # /////////////////////////////////////////////////////////////////////
        # Shared storage
        # /////////////////////////////////////////////////////////////////////
        @cute.struct
        class SharedStorage:
            q_mbar_ptr: cute.struct.MemRange[cutlass.Int64, 1 * 2]
            k_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self._kv_stages * 2]
            v_mbar_ptr: cute.struct.MemRange[cutlass.Int64, self._kv_stages * 2]
            sQ: cute.struct.Align[
                cute.struct.MemRange[fp8, cute.cosize(sQ_layout_staged)], 1024
            ]
            sK: cute.struct.Align[
                cute.struct.MemRange[fp8, cute.cosize(sKV_layout_staged)], 1024
            ]
            sV: cute.struct.Align[
                cute.struct.MemRange[fp8, cute.cosize(sV_layout_staged)], 1024
            ]

        # Grid: (m_blocks, head*batch, 1)
        num_heads = cute.size(mQ.shape[2])
        num_batches = cute.size(mQ.shape[0])
        grid_dim = (
            cute.ceil_div(mQ.shape[1], M),
            num_heads * num_batches,
            1,
        )
        LOG2_E = 1.4426950408889634074
        softmax_scale_log2 = softmax_scale * LOG2_E

        self.kernel(
            tma_atom_q, tma_tensor_q,
            tma_atom_k, tma_tensor_k,
            tma_atom_v, tma_tensor_v,
            mQ, mK, mV, mO,
            softmax_scale_log2,
            q_copy_bytes,
            kv_copy_bytes,
            sQ_layout_staged,
            sKV_layout_staged,
            sV_layout_staged,
            SharedStorage,
            num_heads,
        ).launch(
            grid=grid_dim,
            block=[self._num_threads, 1, 1],
            cluster=[1, 1, 1],
            smem=SharedStorage.size_in_bytes(),
            stream=stream,
        )

    @cute.kernel
    def kernel(
        self,
        tma_atom_q: cute.CopyAtom,
        mQ_tma: cute.Tensor,
        tma_atom_k: cute.CopyAtom,
        mK_tma: cute.Tensor,
        tma_atom_v: cute.CopyAtom,
        mV_tma: cute.Tensor,
        mQ: cute.Tensor,
        mK: cute.Tensor,
        mV: cute.Tensor,
        mO: cute.Tensor,
        softmax_scale_log2: cutlass.Float32,
        q_copy_bytes: cutlass.Constexpr,
        kv_copy_bytes: cutlass.Constexpr,
        sQ_layout_staged: cute.ComposedLayout,
        sKV_layout_staged: cute.ComposedLayout,
        sV_layout_staged: cute.ComposedLayout,
        SharedStorage: cutlass.Constexpr,
        num_heads: cutlass.Int32,
    ):
        tidx, _, _ = cute.arch.thread_idx()
        m_block, hb_idx, _ = cute.arch.block_idx()
        head_idx = hb_idx % num_heads
        batch_idx = hb_idx // num_heads
        warp_idx = cute.arch.warp_idx()
        warp_idx = cute.arch.make_warp_uniform(warp_idx)

        M = self._m_block_size
        N = self._n_block_size
        D = self._head_dim_padded

        n_block_max = cute.ceil_div(mK.shape[1], N)
        if self._is_causal:
            n_block_max = min(
                cute.ceil_div((m_block + 1) * M, N), n_block_max,
            )

        # /////////////////////////////////////////////////////////////////////
        # SMEM allocation
        # /////////////////////////////////////////////////////////////////////
        smem = cutlass.utils.SmemAllocator()
        storage = smem.allocate(SharedStorage)
        sQ = storage.sQ.get_tensor(
            sQ_layout_staged.outer, swizzle=sQ_layout_staged.inner
        )
        sK = storage.sK.get_tensor(
            sKV_layout_staged.outer, swizzle=sKV_layout_staged.inner
        )
        sV = storage.sV.get_tensor(
            sV_layout_staged.outer, swizzle=sV_layout_staged.inner
        )

        # /////////////////////////////////////////////////////////////////////
        # TMA partition: GMEM tile mapping
        # /////////////////////////////////////////////////////////////////////
        gQ = cute.local_tile(
            mQ_tma, (M, D), (None, 0, None, None),
        )
        tQsQ, tQgQ = cpasync.tma_partition(
            tma_atom_q, 0, cute.make_layout(1),
            cute.group_modes(sQ, 0, 2),
            cute.group_modes(gQ, 0, 2),
        )

        gK = cute.local_tile(
            mK_tma, (N, D), (None, 0, None, None),
        )
        tKsK, tKgK = cpasync.tma_partition(
            tma_atom_k, 0, cute.make_layout(1),
            cute.group_modes(sK, 0, 2),
            cute.group_modes(gK, 0, 2),
        )

        gV = cute.local_tile(
            mV_tma, (N, D), (None, 0, None, None),
        )
        tVsV, tVgV = cpasync.tma_partition(
            tma_atom_v, 0, cute.make_layout(1),
            cute.group_modes(sV, 0, 2),
            cute.group_modes(gV, 0, 2),
        )

        tQgQ_block = tQgQ[(None, m_block, head_idx, batch_idx)]
        tKgK_block = tKgK[(None, None, head_idx, batch_idx)]
        tVgV_block = tVgV[(None, None, head_idx, batch_idx)]

        # /////////////////////////////////////////////////////////////////////
        # Pipelines
        # /////////////////////////////////////////////////////////////////////
        q_pipeline = pipeline.PipelineTmaAsync.create(
            num_stages=1,
            producer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread),
            consumer_group=pipeline.CooperativeGroup(
                pipeline.Agent.Thread, self._num_mma_warps
            ),
            tx_count=q_copy_bytes,
            barrier_storage=storage.q_mbar_ptr.data_ptr(),
        )
        k_pipeline = pipeline.PipelineTmaAsync.create(
            num_stages=self._kv_stages,
            producer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread),
            consumer_group=pipeline.CooperativeGroup(
                pipeline.Agent.Thread, self._num_mma_warps
            ),
            tx_count=kv_copy_bytes,
            barrier_storage=storage.k_mbar_ptr.data_ptr(),
        )
        v_pipeline = pipeline.PipelineTmaAsync.create(
            num_stages=self._kv_stages,
            producer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread),
            consumer_group=pipeline.CooperativeGroup(
                pipeline.Agent.Thread, self._num_mma_warps
            ),
            tx_count=kv_copy_bytes,
            barrier_storage=storage.v_mbar_ptr.data_ptr(),
        )

        pipeline.sync(barrier_id=0)

        if warp_idx == 0:
            cpasync.prefetch_descriptor(tma_atom_q)
            cpasync.prefetch_descriptor(tma_atom_k)
            cpasync.prefetch_descriptor(tma_atom_v)

        # /////////////////////////////////////////////////////////////////////
        # Pipeline states
        # /////////////////////////////////////////////////////////////////////
        q_producer_state = pipeline.make_pipeline_state(
            pipeline.PipelineUserType.Producer, 1
        )
        k_producer_state = pipeline.make_pipeline_state(
            pipeline.PipelineUserType.Producer, self._kv_stages
        )
        v_producer_state = pipeline.make_pipeline_state(
            pipeline.PipelineUserType.Producer, self._kv_stages
        )
        k_consumer_state = pipeline.make_pipeline_state(
            pipeline.PipelineUserType.Consumer, self._kv_stages
        )
        v_consumer_state = pipeline.make_pipeline_state(
            pipeline.PipelineUserType.Consumer, self._kv_stages
        )

        # /////////////////////////////////////////////////////////////////////
        # Warp specialization
        # /////////////////////////////////////////////////////////////////////
        if warp_idx < self._num_mma_warps:
            # === MMA warps (consumer) ===
            cute.arch.setmaxregister_increase(self.mma_register_requirement)

            lane_id = tidx % 32
            gid = lane_id // 4
            tip = lane_id % 4
            # Each warp owns M / num_mma_warps contiguous rows, divided into
            # n_warp_groups m16 row groups.  E.g. M=128, num_warps=4:
            # n_warp_groups=2, each warp covers 32 rows split into two m16
            # groups (rows m_warp_base + 0..15 and m_warp_base + 16..31).
            n_warp_groups = M // (self._num_mma_warps * 16)
            m_warp_base = warp_idx * (M // self._num_mma_warps)
            m_base = m_block * M

            n_k = D // 32         # k-iterations for QK GEMM (32 FP8 per k)
            n_n_sub = N // 8      # n-sub-tiles for QK GEMM (m16n8)
            n_d_tiles = D // 8    # d-tiles for PV register output (m16n8)
            n_pv_k_iters = N // 32  # k-iterations for PV GEMM

            # O accumulators in registers: per row group, n_d_tiles × 4 F32
            o_regs = [
                [[cutlass.Float32(0.0), cutlass.Float32(0.0),
                  cutlass.Float32(0.0), cutlass.Float32(0.0)]
                 for _ in range(n_d_tiles)]
                for _ in range(n_warp_groups)
            ]
            # Per-row-group softmax state.  Within each m16 group, "u" = upper
            # 8 rows (gid), "l" = lower 8 rows (gid+8).
            row_max_u = [cutlass.Float32(-3.4028235e+38) for _ in range(n_warp_groups)]
            row_max_l = [cutlass.Float32(-3.4028235e+38) for _ in range(n_warp_groups)]
            row_sum_u = [cutlass.Float32(0.0) for _ in range(n_warp_groups)]
            row_sum_l = [cutlass.Float32(0.0) for _ in range(n_warp_groups)]

            # Wait for Q
            q_pipeline.consumer_wait(
                pipeline.make_pipeline_state(
                    pipeline.PipelineUserType.Consumer, 1
                )
            )

            # ---- Q caching via ldmatrix.x4 (NO trans) on swizzled sQ.
            # sQ row-major [m, d] matches MMA A operand m × k orientation, so
            # no transpose. Custom matrix layout:
            #   matrix 0: m=m_warp_base + g*16 + 0..7,  d=ki*32 + 0..15
            #   matrix 1: m=m_warp_base + g*16 + 0..7,  d=ki*32 + 16..31
            #   matrix 2: m=m_warp_base + g*16 + 8..15, d=ki*32 + 0..15
            #   matrix 3: m=m_warp_base + g*16 + 8..15, d=ki*32 + 16..31
            # Per thread reg i has 4 FP8 at (m=t%8, d=4*(t/8)..+3) within matrix's range.
            # Bridge to per-thread A operand (gid, tip) = (m=gid, d=tip*4..+3 etc):
            #   src_lane_q = 8*tip + gid
            #   a0 = shfl(reg 0, src_lane_q)  # m=gid, d=tip*4..+3 (K-first-half)
            #   a1 = shfl(reg 2, src_lane_q)  # m=gid+8 (matrix 2)
            #   a2 = shfl(reg 1, src_lane_q)  # m=gid, d=tip*4+16..+19 (K-second-half)
            #   a3 = shfl(reg 3, src_lane_q)  # m=gid+8, K-second-half
            # Q is constant across attention iters → cache the bridge results in registers.
            q_cache = [
                [[None, None, None, None]
                 for _ in range(n_k)]
                for _ in range(n_warp_groups)
            ]
            # Per-lane (m, d_offset) mapping for ldmatrix custom address pattern
            q_warp_lane = tidx % 32
            q_m_high = (q_warp_lane >> 4) & 1   # 0/1: which 8-m-row half
            q_d_high = (q_warp_lane >> 3) & 1   # 0/1: K-first/second-half d
            q_m_in_8 = q_warp_lane & 7
            q_src_lane = 8 * tip + gid
            Q_SWIZZLE_BMASK = cutlass.Int32(
                7 if D >= 128 else 3 if D >= 64 else 1
            )
            for g in cutlass.range_constexpr(n_warp_groups):
                rg = m_warp_base + g * 16
                for ki in cutlass.range_constexpr(n_k):
                    # Per-lane address into sQ
                    m_for_lane = rg + q_m_high * 8 + q_m_in_8
                    d_offset_FP8 = ki * 32 + q_d_high * 16
                    elem_off_Q = m_for_lane * D + d_offset_FP8
                    swizzled_Q = elem_off_Q ^ (((elem_off_Q >> 7) & Q_SWIZZLE_BMASK) << 4)
                    my_ptr_Q = sQ.iterator + swizzled_Q
                    addr_u32_Q = cvta_to_shared_u32(my_ptr_Q)
                    qlm_r0, qlm_r1, qlm_r2, qlm_r3 = ldmatrix_x4_b16(addr_u32_Q)
                    # Bridge: single shuffle per a-register
                    q_cache[g][ki][0] = cute.arch.shuffle_sync(qlm_r0, q_src_lane)
                    q_cache[g][ki][1] = cute.arch.shuffle_sync(qlm_r2, q_src_lane)
                    q_cache[g][ki][2] = cute.arch.shuffle_sync(qlm_r1, q_src_lane)
                    q_cache[g][ki][3] = cute.arch.shuffle_sync(qlm_r3, q_src_lane)

            # Main attention loop
            for n_tile in range(0, n_block_max, 1, unroll=1):
                nb = n_block_max - n_tile - 1

                # ---- Wait for K ready ----
                k_pipeline.consumer_wait(k_consumer_state)
                k_stage = k_consumer_state.index

                # ---- QK GEMM: K loaded via ldmatrix.x4.trans on swizzled sK ----
                # Custom address pattern (analogous to Path A V loading):
                #   matrix 0: seqs (kc*16..kc*16+7),    d=ki*32 + 0..15  (K-first-half)
                #   matrix 1: seqs (kc*16..kc*16+7),    d=ki*32 + 16..31 (K-second-half)
                #   matrix 2: seqs (kc*16+8..kc*16+15), d=ki*32 + 0..15
                #   matrix 3: seqs (kc*16+8..kc*16+15), d=ki*32 + 16..31
                # After ldmatrix.x4.trans, regs 0/2 hold K-first-half data,
                # regs 1/3 hold K-second-half. Bridge: per-thread shuffle r_n
                # from src_la/src_lb, then prmt to byte-extract by g_parity.
                # No selp needed (ni is constexpr → which reg pair to use is
                # known at compile time).
                s_regs = [
                    [[cutlass.Float32(0.0), cutlass.Float32(0.0),
                      cutlass.Float32(0.0), cutlass.Float32(0.0)]
                     for _ in range(n_n_sub)]
                    for _ in range(n_warp_groups)
                ]
                # Lane-to-(seq, d) mapping for the custom ldmatrix address pattern
                k_warp_lane = tidx % 32
                k_seq_high = (k_warp_lane >> 4) & 1   # 0 or 1: which 8-seq half within kc's 16
                k_d_high = (k_warp_lane >> 3) & 1     # 0 or 1: K-first/second-half
                k_seq_in_8 = k_warp_lane & 7
                # Per ki and kc: lane provides addr to (seq, d_offset) within current K-tile.
                #   seq = kc*16 + k_seq_high*8 + k_seq_in_8
                #   d_offset = ki*32 + k_d_high*16 (for d_b16_base, but we use FP8 byte offsets)
                # Source lanes for per-thread bridge (analogous to PV's src_la/src_lb)
                k_src_la = (gid // 2) * 4 + (tip & 1) * 2
                k_src_lb = k_src_la + 1
                # prmt selector: 0x6420 if g_parity 0, 0x7531 if g_parity 1
                k_prmt_sel = cutlass.Int32(0x6420) + (gid & 1) * cutlass.Int32(0x1111)
                # Swizzle bit-mask (same as Path A V loading)
                K_SWIZZLE_BMASK = cutlass.Int32(
                    7 if D >= 128 else 3 if D >= 64 else 1
                )
                # n_n_sub seqs per ki = N/8. ldmatrix covers 16 seqs (2 m16n8) per call.
                qk_n_seq_chunks = n_n_sub // 2  # = N // 16
                for ki in cutlass.range_constexpr(n_k):
                    for kc in cutlass.range_constexpr(qk_n_seq_chunks):
                        # Per-lane address
                        seq_for_lane = kc * 16 + k_seq_high * 8 + k_seq_in_8
                        d_offset_FP8 = ki * 32 + k_d_high * 16
                        # K stage offset within sK
                        k_stage_off = k_stage * N * D
                        elem_off_K = seq_for_lane * D + d_offset_FP8
                        swizzled_K = elem_off_K ^ (((elem_off_K >> 7) & K_SWIZZLE_BMASK) << 4)
                        my_ptr_K = sK.iterator + (k_stage_off + swizzled_K)
                        addr_u32_K = cvta_to_shared_u32(my_ptr_K)
                        klm_r0, klm_r1, klm_r2, klm_r3 = ldmatrix_x4_trans_b16(addr_u32_K)

                        # Bridge for ni = 2*kc (uses regs 0+1)
                        sh_r0_la = cute.arch.shuffle_sync(klm_r0, k_src_la)
                        sh_r0_lb = cute.arch.shuffle_sync(klm_r0, k_src_lb)
                        b0_ni0 = prmt_b32(sh_r0_la, sh_r0_lb, k_prmt_sel)
                        sh_r1_la = cute.arch.shuffle_sync(klm_r1, k_src_la)
                        sh_r1_lb = cute.arch.shuffle_sync(klm_r1, k_src_lb)
                        b1_ni0 = prmt_b32(sh_r1_la, sh_r1_lb, k_prmt_sel)
                        # Bridge for ni = 2*kc + 1 (uses regs 2+3)
                        sh_r2_la = cute.arch.shuffle_sync(klm_r2, k_src_la)
                        sh_r2_lb = cute.arch.shuffle_sync(klm_r2, k_src_lb)
                        b0_ni1 = prmt_b32(sh_r2_la, sh_r2_lb, k_prmt_sel)
                        sh_r3_la = cute.arch.shuffle_sync(klm_r3, k_src_la)
                        sh_r3_lb = cute.arch.shuffle_sync(klm_r3, k_src_lb)
                        b1_ni1 = prmt_b32(sh_r3_la, sh_r3_lb, k_prmt_sel)

                        # MMAs for ni = 2*kc and 2*kc+1, each across n_warp_groups
                        for g in cutlass.range_constexpr(n_warp_groups):
                            a0 = q_cache[g][ki][0]
                            a1 = q_cache[g][ki][1]
                            a2 = q_cache[g][ki][2]
                            a3 = q_cache[g][ki][3]
                            s_regs[g][2*kc][0], s_regs[g][2*kc][1], s_regs[g][2*kc][2], s_regs[g][2*kc][3] = \
                                mma_f8f6f4_m16n8k32_e4m3(
                                    a0, a1, a2, a3, b0_ni0, b1_ni0,
                                    s_regs[g][2*kc][0], s_regs[g][2*kc][1],
                                    s_regs[g][2*kc][2], s_regs[g][2*kc][3])
                            s_regs[g][2*kc+1][0], s_regs[g][2*kc+1][1], s_regs[g][2*kc+1][2], s_regs[g][2*kc+1][3] = \
                                mma_f8f6f4_m16n8k32_e4m3(
                                    a0, a1, a2, a3, b0_ni1, b1_ni1,
                                    s_regs[g][2*kc+1][0], s_regs[g][2*kc+1][1],
                                    s_regs[g][2*kc+1][2], s_regs[g][2*kc+1][3])

                k_pipeline.consumer_release(k_consumer_state)
                k_consumer_state.advance()

                # ---- Mask: OOB (Sk % N != 0) + causal ----
                # OOB applies to all warps/groups uniformly.  Causal additionally
                # masks col > query_pos; query_pos depends on the row group.
                neginf = cutlass.Float32(-3.4028235e+38)
                k_lim = mK.shape[1]
                if cutlass.const_expr(self._is_causal):
                    for g in cutlass.range_constexpr(n_warp_groups):
                        rg = m_base + m_warp_base + g * 16
                        q_u = rg + gid
                        q_l = rg + gid + 8
                        for ni in cutlass.range_constexpr(n_n_sub):
                            c0 = nb * N + ni * 8 + tip * 2
                            c1 = c0 + 1
                            s_regs[g][ni][0] = neginf if c0 > q_u else (
                                neginf if c0 >= k_lim else s_regs[g][ni][0])
                            s_regs[g][ni][1] = neginf if c1 > q_u else (
                                neginf if c1 >= k_lim else s_regs[g][ni][1])
                            s_regs[g][ni][2] = neginf if c0 > q_l else (
                                neginf if c0 >= k_lim else s_regs[g][ni][2])
                            s_regs[g][ni][3] = neginf if c1 > q_l else (
                                neginf if c1 >= k_lim else s_regs[g][ni][3])
                else:
                    for g in cutlass.range_constexpr(n_warp_groups):
                        for ni in cutlass.range_constexpr(n_n_sub):
                            c0 = nb * N + ni * 8 + tip * 2
                            c1 = c0 + 1
                            s_regs[g][ni][0] = neginf if c0 >= k_lim else s_regs[g][ni][0]
                            s_regs[g][ni][1] = neginf if c1 >= k_lim else s_regs[g][ni][1]
                            s_regs[g][ni][2] = neginf if c0 >= k_lim else s_regs[g][ni][2]
                            s_regs[g][ni][3] = neginf if c1 >= k_lim else s_regs[g][ni][3]

                # ---- Online softmax (per row group) ----
                for g in cutlass.range_constexpr(n_warp_groups):
                    lmu = s_regs[g][0][0]
                    lml = s_regs[g][0][2]
                    for ni in cutlass.range_constexpr(n_n_sub):
                        lmu = cute.arch.fmax(lmu, cute.arch.fmax(s_regs[g][ni][0], s_regs[g][ni][1]))
                        lml = cute.arch.fmax(lml, cute.arch.fmax(s_regs[g][ni][2], s_regs[g][ni][3]))
                    lmu = cute.arch.fmax(lmu, cute.arch.shuffle_sync_bfly(
                        lmu, offset=2, mask=-1, mask_and_clamp=31))
                    lmu = cute.arch.fmax(lmu, cute.arch.shuffle_sync_bfly(
                        lmu, offset=1, mask=-1, mask_and_clamp=31))
                    lml = cute.arch.fmax(lml, cute.arch.shuffle_sync_bfly(
                        lml, offset=2, mask=-1, mask_and_clamp=31))
                    lml = cute.arch.fmax(lml, cute.arch.shuffle_sync_bfly(
                        lml, offset=1, mask=-1, mask_and_clamp=31))

                    new_mu = cute.arch.fmax(row_max_u[g], lmu)
                    new_ml = cute.arch.fmax(row_max_l[g], lml)
                    if cutlass.const_expr(self._is_causal):
                        new_mu = cutlass.Float32(0.0) if new_mu == cutlass.Float32(-3.4028235e+38) else new_mu
                        new_ml = cutlass.Float32(0.0) if new_ml == cutlass.Float32(-3.4028235e+38) else new_ml

                    resc_u = cute.math.exp2(
                        row_max_u[g] * softmax_scale_log2 - new_mu * softmax_scale_log2,
                        fastmath=True)
                    resc_l = cute.math.exp2(
                        row_max_l[g] * softmax_scale_log2 - new_ml * softmax_scale_log2,
                        fastmath=True)

                    for dt in cutlass.range_constexpr(n_d_tiles):
                        o_regs[g][dt][0] = o_regs[g][dt][0] * resc_u
                        o_regs[g][dt][1] = o_regs[g][dt][1] * resc_u
                        o_regs[g][dt][2] = o_regs[g][dt][2] * resc_l
                        o_regs[g][dt][3] = o_regs[g][dt][3] * resc_l

                    row_sum_u[g] = row_sum_u[g] * resc_u
                    row_sum_l[g] = row_sum_l[g] * resc_l

                    for ni in cutlass.range_constexpr(n_n_sub):
                        s_regs[g][ni][0] = cute.math.exp2(
                            s_regs[g][ni][0] * softmax_scale_log2 - new_mu * softmax_scale_log2,
                            fastmath=True)
                        s_regs[g][ni][1] = cute.math.exp2(
                            s_regs[g][ni][1] * softmax_scale_log2 - new_mu * softmax_scale_log2,
                            fastmath=True)
                        s_regs[g][ni][2] = cute.math.exp2(
                            s_regs[g][ni][2] * softmax_scale_log2 - new_ml * softmax_scale_log2,
                            fastmath=True)
                        s_regs[g][ni][3] = cute.math.exp2(
                            s_regs[g][ni][3] * softmax_scale_log2 - new_ml * softmax_scale_log2,
                            fastmath=True)
                        row_sum_u[g] = row_sum_u[g] + s_regs[g][ni][0] + s_regs[g][ni][1]
                        row_sum_l[g] = row_sum_l[g] + s_regs[g][ni][2] + s_regs[g][ni][3]

                    row_max_u[g] = new_mu
                    row_max_l[g] = new_ml

                # ---- Register-resident P: shuffle-redistribute s_regs into
                # pa registers for PV — no sP_f32 SMEM round-trip.
                # pa_reg[g][pv_ki][i] holds packed FP8 for warp_group g,
                # pv K-iter pv_ki, position i (0=upper left, 1=lower left,
                # 2=upper right, 3=lower right of the m16n8k32 A operand).
                src_lane_a = gid * 4 + (tip % 2) * 2
                src_lane_b = src_lane_a + 1
                tip_lo = (tip < 2)
                pa_reg = [[[None, None, None, None]
                           for _ in range(n_pv_k_iters)]
                          for _ in range(n_warp_groups)]
                for g in cutlass.range_constexpr(n_warp_groups):
                    for pv_ki in cutlass.range_constexpr(n_pv_k_iters):
                        ni0 = pv_ki * 4
                        # pa0: upper rows (s_regs[ni][0,1]), ni=ni0/ni0+1
                        sh_a0_n0 = cute.arch.shuffle_sync(s_regs[g][ni0  ][0], src_lane_a)
                        sh_a1_n0 = cute.arch.shuffle_sync(s_regs[g][ni0  ][1], src_lane_a)
                        sh_a0_n1 = cute.arch.shuffle_sync(s_regs[g][ni0+1][0], src_lane_a)
                        sh_a1_n1 = cute.arch.shuffle_sync(s_regs[g][ni0+1][1], src_lane_a)
                        sh_b0_n0 = cute.arch.shuffle_sync(s_regs[g][ni0  ][0], src_lane_b)
                        sh_b1_n0 = cute.arch.shuffle_sync(s_regs[g][ni0  ][1], src_lane_b)
                        sh_b0_n1 = cute.arch.shuffle_sync(s_regs[g][ni0+1][0], src_lane_b)
                        sh_b1_n1 = cute.arch.shuffle_sync(s_regs[g][ni0+1][1], src_lane_b)
                        pa0 = cvt_f32_to_fp8x4(
                            sh_a0_n0 if tip_lo else sh_a0_n1,
                            sh_a1_n0 if tip_lo else sh_a1_n1,
                            sh_b0_n0 if tip_lo else sh_b0_n1,
                            sh_b1_n0 if tip_lo else sh_b1_n1,
                        )
                        # pa1: lower rows (s_regs[ni][2,3]), ni=ni0/ni0+1
                        sh_a2_n0 = cute.arch.shuffle_sync(s_regs[g][ni0  ][2], src_lane_a)
                        sh_a3_n0 = cute.arch.shuffle_sync(s_regs[g][ni0  ][3], src_lane_a)
                        sh_a2_n1 = cute.arch.shuffle_sync(s_regs[g][ni0+1][2], src_lane_a)
                        sh_a3_n1 = cute.arch.shuffle_sync(s_regs[g][ni0+1][3], src_lane_a)
                        sh_b2_n0 = cute.arch.shuffle_sync(s_regs[g][ni0  ][2], src_lane_b)
                        sh_b3_n0 = cute.arch.shuffle_sync(s_regs[g][ni0  ][3], src_lane_b)
                        sh_b2_n1 = cute.arch.shuffle_sync(s_regs[g][ni0+1][2], src_lane_b)
                        sh_b3_n1 = cute.arch.shuffle_sync(s_regs[g][ni0+1][3], src_lane_b)
                        pa1 = cvt_f32_to_fp8x4(
                            sh_a2_n0 if tip_lo else sh_a2_n1,
                            sh_a3_n0 if tip_lo else sh_a3_n1,
                            sh_b2_n0 if tip_lo else sh_b2_n1,
                            sh_b3_n0 if tip_lo else sh_b3_n1,
                        )
                        # pa2: upper rows, ni=ni0+2/ni0+3
                        sh_a0_n2 = cute.arch.shuffle_sync(s_regs[g][ni0+2][0], src_lane_a)
                        sh_a1_n2 = cute.arch.shuffle_sync(s_regs[g][ni0+2][1], src_lane_a)
                        sh_a0_n3 = cute.arch.shuffle_sync(s_regs[g][ni0+3][0], src_lane_a)
                        sh_a1_n3 = cute.arch.shuffle_sync(s_regs[g][ni0+3][1], src_lane_a)
                        sh_b0_n2 = cute.arch.shuffle_sync(s_regs[g][ni0+2][0], src_lane_b)
                        sh_b1_n2 = cute.arch.shuffle_sync(s_regs[g][ni0+2][1], src_lane_b)
                        sh_b0_n3 = cute.arch.shuffle_sync(s_regs[g][ni0+3][0], src_lane_b)
                        sh_b1_n3 = cute.arch.shuffle_sync(s_regs[g][ni0+3][1], src_lane_b)
                        pa2 = cvt_f32_to_fp8x4(
                            sh_a0_n2 if tip_lo else sh_a0_n3,
                            sh_a1_n2 if tip_lo else sh_a1_n3,
                            sh_b0_n2 if tip_lo else sh_b0_n3,
                            sh_b1_n2 if tip_lo else sh_b1_n3,
                        )
                        # pa3: lower rows, ni=ni0+2/ni0+3
                        sh_a2_n2 = cute.arch.shuffle_sync(s_regs[g][ni0+2][2], src_lane_a)
                        sh_a3_n2 = cute.arch.shuffle_sync(s_regs[g][ni0+2][3], src_lane_a)
                        sh_a2_n3 = cute.arch.shuffle_sync(s_regs[g][ni0+3][2], src_lane_a)
                        sh_a3_n3 = cute.arch.shuffle_sync(s_regs[g][ni0+3][3], src_lane_a)
                        sh_b2_n2 = cute.arch.shuffle_sync(s_regs[g][ni0+2][2], src_lane_b)
                        sh_b3_n2 = cute.arch.shuffle_sync(s_regs[g][ni0+2][3], src_lane_b)
                        sh_b2_n3 = cute.arch.shuffle_sync(s_regs[g][ni0+3][2], src_lane_b)
                        sh_b3_n3 = cute.arch.shuffle_sync(s_regs[g][ni0+3][3], src_lane_b)
                        pa3 = cvt_f32_to_fp8x4(
                            sh_a2_n2 if tip_lo else sh_a2_n3,
                            sh_a3_n2 if tip_lo else sh_a3_n3,
                            sh_b2_n2 if tip_lo else sh_b2_n3,
                            sh_b3_n2 if tip_lo else sh_b3_n3,
                        )
                        pa_reg[g][pv_ki][0] = pa0
                        pa_reg[g][pv_ki][1] = pa1
                        pa_reg[g][pv_ki][2] = pa2
                        pa_reg[g][pv_ki][3] = pa3

                # ---- Wait for V ready ----
                v_pipeline.consumer_wait(v_consumer_state)
                v_stage = v_consumer_state.index

                # ---- Path A: ldmatrix.x4.trans.b16 directly from sV with
                # SW128 swizzle (manual swizzle in address) — eliminates the
                # software transpose AND reduces ldmatrix bank conflicts.
                # See /tmp/probe_ldmatrix_layout.py for the validated bridge.
                sV_ptr_base = sV.iterator
                stage_off = v_stage * N * D
                warp_lane = tidx % 32
                lane_g_block = warp_lane // 8
                row_in_block = warp_lane & 7
                kv_for_lane = (
                    (lane_g_block & 1) * 16
                    + ((lane_g_block >> 1) & 1) * 8
                    + row_in_block
                )
                pv_gid = warp_lane // 4
                pv_tip = warp_lane % 4
                src_la = (pv_gid // 2) * 4 + (pv_tip & 1) * 2
                src_lb = src_la + 1
                tip_lo_int = cutlass.Int32(1) - ((pv_tip >> 1) & 1)
                prmt_sel = cutlass.Int32(0x6420) + (pv_gid & 1) * cutlass.Int32(0x1111)
                ldmat_n_d_chunks = n_d_tiles // 2
                src_la_b = src_la + 16
                src_lb_b = src_lb + 16
                # Swizzle(B, M=4, S=3) XOR mask. Constexpr selection (D is
                # known at compile time): SW128(B=3)/SW64(B=2)/SW32(B=1).
                SWIZZLE_BMASK = cutlass.Int32(
                    7 if D >= 128 else 3 if D >= 64 else 1
                )
                for pv_ki in cutlass.range_constexpr(n_pv_k_iters):
                    pv_kv_base = pv_ki * 32
                    for dc in cutlass.range_constexpr(ldmat_n_d_chunks):
                        d_chunk_base_fp8 = dc * 16
                        # Logical byte offset within sV stage
                        kv_d_off = (pv_kv_base + kv_for_lane) * D + d_chunk_base_fp8
                        # Apply Swizzle(B,4,3) XOR: ((addr>>7) & ((1<<B)-1)) << 4
                        swizzled_kv_d = kv_d_off ^ (((kv_d_off >> 7) & SWIZZLE_BMASK) << 4)
                        elem_off = stage_off + swizzled_kv_d
                        my_ptr = sV_ptr_base + elem_off
                        addr_u32 = cvta_to_shared_u32(my_ptr)
                        ldm_r0, ldm_r1, ldm_r2, ldm_r3 = ldmatrix_x4_trans_b16(addr_u32)

                        # Bridge: shuffle raw regs, select per q, prmt per g_parity
                        b0_a = prmt_b32(
                            selp_b32(
                                cute.arch.shuffle_sync(ldm_r0, src_la),
                                cute.arch.shuffle_sync(ldm_r2, src_la),
                                tip_lo_int),
                            selp_b32(
                                cute.arch.shuffle_sync(ldm_r0, src_lb),
                                cute.arch.shuffle_sync(ldm_r2, src_lb),
                                tip_lo_int),
                            prmt_sel)
                        b1_a = prmt_b32(
                            selp_b32(
                                cute.arch.shuffle_sync(ldm_r1, src_la),
                                cute.arch.shuffle_sync(ldm_r3, src_la),
                                tip_lo_int),
                            selp_b32(
                                cute.arch.shuffle_sync(ldm_r1, src_lb),
                                cute.arch.shuffle_sync(ldm_r3, src_lb),
                                tip_lo_int),
                            prmt_sel)
                        b0_b = prmt_b32(
                            selp_b32(
                                cute.arch.shuffle_sync(ldm_r0, src_la_b),
                                cute.arch.shuffle_sync(ldm_r2, src_la_b),
                                tip_lo_int),
                            selp_b32(
                                cute.arch.shuffle_sync(ldm_r0, src_lb_b),
                                cute.arch.shuffle_sync(ldm_r2, src_lb_b),
                                tip_lo_int),
                            prmt_sel)
                        b1_b = prmt_b32(
                            selp_b32(
                                cute.arch.shuffle_sync(ldm_r1, src_la_b),
                                cute.arch.shuffle_sync(ldm_r3, src_la_b),
                                tip_lo_int),
                            selp_b32(
                                cute.arch.shuffle_sync(ldm_r1, src_lb_b),
                                cute.arch.shuffle_sync(ldm_r3, src_lb_b),
                                tip_lo_int),
                            prmt_sel)
                        for g in cutlass.range_constexpr(n_warp_groups):
                            pa0 = pa_reg[g][pv_ki][0]
                            pa1 = pa_reg[g][pv_ki][1]
                            pa2 = pa_reg[g][pv_ki][2]
                            pa3 = pa_reg[g][pv_ki][3]
                            o_regs[g][dc*2][0], o_regs[g][dc*2][1], o_regs[g][dc*2][2], o_regs[g][dc*2][3] = \
                                mma_f8f6f4_m16n8k32_e4m3(
                                    pa0, pa1, pa2, pa3, b0_a, b1_a,
                                    o_regs[g][dc*2][0], o_regs[g][dc*2][1],
                                    o_regs[g][dc*2][2], o_regs[g][dc*2][3])
                            o_regs[g][dc*2+1][0], o_regs[g][dc*2+1][1], o_regs[g][dc*2+1][2], o_regs[g][dc*2+1][3] = \
                                mma_f8f6f4_m16n8k32_e4m3(
                                    pa0, pa1, pa2, pa3, b0_b, b1_b,
                                    o_regs[g][dc*2+1][0], o_regs[g][dc*2+1][1],
                                    o_regs[g][dc*2+1][2], o_regs[g][dc*2+1][3])

                # Release V stage after all ldmatrix loads complete
                v_pipeline.consumer_release(v_consumer_state)
                v_consumer_state.advance()

            # ---- Final normalize and store O (per row group) ----
            seq_lim = mO.shape[1]
            for g in cutlass.range_constexpr(n_warp_groups):
                rsu = row_sum_u[g] + cute.arch.shuffle_sync_bfly(
                    row_sum_u[g], offset=2, mask=-1, mask_and_clamp=31)
                rsu = rsu + cute.arch.shuffle_sync_bfly(
                    rsu, offset=1, mask=-1, mask_and_clamp=31)
                rsl = row_sum_l[g] + cute.arch.shuffle_sync_bfly(
                    row_sum_l[g], offset=2, mask=-1, mask_and_clamp=31)
                rsl = rsl + cute.arch.shuffle_sync_bfly(
                    rsl, offset=1, mask=-1, mask_and_clamp=31)

                inv_u = cutlass.Float32(1.0) / rsu if rsu != cutlass.Float32(0.0) else cutlass.Float32(1.0)
                inv_l = cutlass.Float32(1.0) / rsl if rsl != cutlass.Float32(0.0) else cutlass.Float32(1.0)

                rg = m_warp_base + g * 16
                row_u = m_base + rg + gid
                row_l = m_base + rg + gid + 8
                if cutlass.const_expr(mO.element_type == cutlass.BFloat16):
                    # BF16 output: pack 2 BF16 (= 4 bytes) per st via Int32 recast.
                    # Halves bytes vs F32 and halves store instruction count.
                    mO_i32 = cute.recast_tensor(mO, cutlass.Int32)
                    for dt in cutlass.range_constexpr(n_d_tiles):
                        if row_u < seq_lim:
                            packed_u = cvt_f32x2_to_bf16x2(
                                o_regs[g][dt][0] * inv_u,
                                o_regs[g][dt][1] * inv_u,
                            )
                            mO_i32[batch_idx, row_u, head_idx, dt*4 + tip] = packed_u
                        if row_l < seq_lim:
                            packed_l = cvt_f32x2_to_bf16x2(
                                o_regs[g][dt][2] * inv_l,
                                o_regs[g][dt][3] * inv_l,
                            )
                            mO_i32[batch_idx, row_l, head_idx, dt*4 + tip] = packed_l
                else:
                    for dt in cutlass.range_constexpr(n_d_tiles):
                        db = dt * 8
                        if row_u < seq_lim:
                            mO[batch_idx, row_u, head_idx, db + tip*2]     = o_regs[g][dt][0] * inv_u
                            mO[batch_idx, row_u, head_idx, db + tip*2 + 1] = o_regs[g][dt][1] * inv_u
                        if row_l < seq_lim:
                            mO[batch_idx, row_l, head_idx, db + tip*2]     = o_regs[g][dt][2] * inv_l
                            mO[batch_idx, row_l, head_idx, db + tip*2 + 1] = o_regs[g][dt][3] * inv_l

        elif warp_idx == self._num_mma_warps:
            # === DMA warp (producer) ===
            cute.arch.setmaxregister_decrease(self.load_register_requirement)

            # Load Q (once)
            q_pipeline.producer_acquire(q_producer_state)
            cute.copy(
                tma_atom_q, tQgQ_block,
                tQsQ[(None, q_producer_state.index)],
                tma_bar_ptr=q_pipeline.producer_get_barrier(q_producer_state),
            )
            q_pipeline.producer_commit(q_producer_state)

            # Load K, V tiles (high → low for causal/iter order)
            for n_tile in range(0, n_block_max, 1, unroll=1):
                nb = n_block_max - n_tile - 1

                k_pipeline.producer_acquire(k_producer_state)
                cute.copy(
                    tma_atom_k,
                    tKgK_block[(None, nb)],
                    tKsK[(None, k_producer_state.index)],
                    tma_bar_ptr=k_pipeline.producer_get_barrier(k_producer_state),
                )
                k_pipeline.producer_commit(k_producer_state)
                k_producer_state.advance()

                v_pipeline.producer_acquire(v_producer_state)
                cute.copy(
                    tma_atom_v,
                    tVgV_block[(None, nb)],
                    tVsV[(None, v_producer_state.index)],
                    tma_bar_ptr=v_pipeline.producer_get_barrier(v_producer_state),
                )
                v_pipeline.producer_commit(v_producer_state)
                v_producer_state.advance()

            k_pipeline.producer_tail(k_producer_state)
            v_pipeline.producer_tail(v_producer_state)


# /////////////////////////////////////////////////////////////////////////////
# Test / benchmark harness
# /////////////////////////////////////////////////////////////////////////////

def make_cute_fp8(t):
    fp8 = cutlass.Float8E4M3FN
    u8 = t.view(torch.uint8)
    ct = from_dlpack(u8, assumed_align=16).mark_layout_dynamic(
        leading_dim=3).mark_compact_shape_dynamic(
        mode=3, stride_order=u8.dim_order(), divisibility=(128 // fp8.width))
    ct.element_type = fp8
    return ct


def make_cute_f32(t):
    return from_dlpack(t, assumed_align=16).mark_layout_dynamic(
        leading_dim=3).mark_compact_shape_dynamic(
        mode=3, stride_order=t.dim_order(), divisibility=4)


def make_cute_bf16(t):
    """Wrap a torch.bfloat16 tensor for BF16 output mode (2-byte elements,
    matches BF16 TMA's output bandwidth)."""
    return from_dlpack(t, assumed_align=16).mark_layout_dynamic(
        leading_dim=3).mark_compact_shape_dynamic(
        mode=3, stride_order=t.dim_order(), divisibility=8)


def run_test(B, Sq, Sk, H, D, is_causal=False, desc="",
             m_block_size=128, n_block_size=32, kv_stages=2):
    """Correctness test against an FP32 reference.

    Returns True on PASS (max_diff < 0.1).
    """
    scale = 1.0 / (D ** 0.5)
    torch.manual_seed(42)
    q = (torch.randn(B, Sq, H, D, device='cuda') * 0.1).to(torch.float8_e4m3fn)
    k = (torch.randn(B, Sk, H, D, device='cuda') * 0.1).to(torch.float8_e4m3fn)
    v = (torch.randn(B, Sk, H, D, device='cuda') * 0.1).to(torch.float8_e4m3fn)

    # Reference: must permute (B, S, H, D) -> (B, H, S, D) before flattening to
    # (B*H, S, D); a plain view would interleave seq and head, scrambling
    # per-head data for H >= 2 and silently failing the comparison.
    qf = q.float().permute(0, 2, 1, 3).contiguous().view(B * H, Sq, D)
    kf = k.float().permute(0, 2, 1, 3).contiguous().view(B * H, Sk, D)
    vf = v.float().permute(0, 2, 1, 3).contiguous().view(B * H, Sk, D)
    s = torch.bmm(qf, kf.transpose(1, 2)) * scale
    if is_causal:
        mask = torch.triu(torch.ones(Sq, Sk, device='cuda'), diagonal=1).bool()
        s.masked_fill_(mask.unsqueeze(0), float('-inf'))
    p = torch.softmax(s, dim=-1)
    ref = torch.bmm(p, vf).view(B, H, Sq, D).permute(0, 2, 1, 3).contiguous()

    o_f32 = torch.zeros(B, Sq, H, D, dtype=torch.float32, device='cuda')
    stream = cuda.CUstream(torch.cuda.current_stream().cuda_stream)
    kern = FP8FlashAttentionSm120Tma(
        D, m_block_size=m_block_size, n_block_size=n_block_size,
        kv_stages=kv_stages, is_causal=is_causal,
    )
    compiled = cute.compile(
        kern, make_cute_fp8(q), make_cute_fp8(k), make_cute_fp8(v),
        make_cute_f32(o_f32), scale, stream,
    )
    compiled(make_cute_fp8(q), make_cute_fp8(k), make_cute_fp8(v),
             make_cute_f32(o_f32), scale, stream)
    torch.cuda.synchronize()

    diff = (o_f32 - ref).abs()
    max_d = diff.max().item()
    mean_d = diff.mean().item()
    # Also check per-row coverage — if any row is entirely zero, the kernel
    # likely has an indexing bug (some warps not computing their rows).
    row_norms = o_f32.norm(dim=-1).flatten()
    n_zero_rows = (row_norms < 1e-6).sum().item()
    ok = (max_d < 0.05) and (n_zero_rows == 0)
    tag = "tma" + (" causal" if is_causal else "")
    print(f"{'PASS' if ok else 'FAIL'} | {desc:30s} | B={B} Sq={Sq:4d} Sk={Sk:4d} "
          f"H={H} D={D:3d} {tag:12s} | max={max_d:.6f} mean={mean_d:.6f}"
          f" zero_rows={n_zero_rows}")
    return ok


def run_benchmark(
    batch_size, seqlen_q, seqlen_k, num_head, head_dim,
    softmax_scale=None, is_causal=False,
    m_block_size=128, n_block_size=32, kv_stages=2,
    warmup_iterations=10, iterations=50,
    skip_ref_check=False,
):
    """Benchmark FP8 TMA flash attention. Returns avg time in microseconds."""
    import cutlass.cute.testing as testing

    if softmax_scale is None:
        softmax_scale = 1.0 / (head_dim ** 0.5)

    print(f"Running FP8 FA (tma): B={batch_size} Sq={seqlen_q} "
          f"Sk={seqlen_k} H={num_head} D={head_dim} causal={is_causal}")

    torch.manual_seed(42)
    q_torch = (torch.randn(batch_size, seqlen_q, num_head, head_dim,
                           device='cuda') * 0.1).to(torch.float8_e4m3fn)
    k_torch = (torch.randn(batch_size, seqlen_k, num_head, head_dim,
                           device='cuda') * 0.1).to(torch.float8_e4m3fn)
    v_torch = (torch.randn(batch_size, seqlen_k, num_head, head_dim,
                           device='cuda') * 0.1).to(torch.float8_e4m3fn)
    o_torch = torch.zeros(batch_size, seqlen_q, num_head, head_dim,
                          dtype=torch.float32, device='cuda')

    q = make_cute_fp8(q_torch)
    k = make_cute_fp8(k_torch)
    v = make_cute_fp8(v_torch)
    o = make_cute_f32(o_torch)

    stream = cuda.CUstream(torch.cuda.current_stream().cuda_stream)

    kern = FP8FlashAttentionSm120Tma(
        head_dim, m_block_size=m_block_size, n_block_size=n_block_size,
        kv_stages=kv_stages, is_causal=is_causal,
    )
    compiled = cute.compile(kern, q, k, v, o, softmax_scale, stream)

    if not skip_ref_check:
        compiled(q, k, v, o, softmax_scale, stream)
        torch.cuda.synchronize()
        qf = q_torch.float().permute(0, 2, 1, 3).contiguous().view(
            batch_size * num_head, seqlen_q, head_dim)
        kf = k_torch.float().permute(0, 2, 1, 3).contiguous().view(
            batch_size * num_head, seqlen_k, head_dim)
        vf = v_torch.float().permute(0, 2, 1, 3).contiguous().view(
            batch_size * num_head, seqlen_k, head_dim)
        s = torch.bmm(qf, kf.transpose(1, 2)) * softmax_scale
        if is_causal:
            mask = torch.triu(torch.ones(seqlen_q, seqlen_k, device='cuda'),
                              diagonal=1).bool()
            s.masked_fill_(mask.unsqueeze(0), float('-inf'))
        p = torch.softmax(s, dim=-1)
        ref = torch.bmm(p, vf).view(
            batch_size, num_head, seqlen_q, head_dim,
        ).permute(0, 2, 1, 3).contiguous()
        diff = (o_torch - ref).abs().max().item()
        assert diff < 0.1, f"Reference check failed: max_diff={diff}"
        print(f"  Reference check passed (max_diff={diff:.6f})")
        o_torch.zero_()

    def generate_tensors():
        q_w = (torch.randn(batch_size, seqlen_q, num_head, head_dim,
                           device='cuda') * 0.1).to(torch.float8_e4m3fn)
        k_w = (torch.randn(batch_size, seqlen_k, num_head, head_dim,
                           device='cuda') * 0.1).to(torch.float8_e4m3fn)
        v_w = (torch.randn(batch_size, seqlen_k, num_head, head_dim,
                           device='cuda') * 0.1).to(torch.float8_e4m3fn)
        o_w = torch.zeros(batch_size, seqlen_q, num_head, head_dim,
                          dtype=torch.float32, device='cuda')
        jit_args = testing.JitArguments(
            make_cute_fp8(q_w), make_cute_fp8(k_w), make_cute_fp8(v_w),
            make_cute_f32(o_w), softmax_scale, stream,
        )
        jit_args.add_to_scope([q_w, k_w, v_w, o_w])
        return jit_args

    avg_time_us = testing.benchmark(
        compiled,
        workspace_generator=generate_tensors,
        workspace_count=1,
        stream=stream,
        warmup_iterations=warmup_iterations,
        iterations=iterations,
    )

    return avg_time_us


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="FP8 Flash Attention TMA for SM120 (Blackwell GeForce)")
    parser.add_argument("--quick", action="store_true", help="Run minimal tests")
    parser.add_argument("--benchmark", action="store_true",
                        help="Run benchmarks instead of correctness tests")
    parser.add_argument("--batch_size", type=int, default=1)
    parser.add_argument("--seqlen", type=int, default=512)
    parser.add_argument("--num_head", type=int, default=16)
    parser.add_argument("--head_dim", type=int, default=128)
    parser.add_argument("--is_causal", action="store_true")
    parser.add_argument("--m_block_size", type=int, default=128)
    parser.add_argument("--n_block_size", type=int, default=32)
    parser.add_argument("--kv_stages", type=int, default=2)
    parser.add_argument("--warmup_iterations", type=int, default=10)
    parser.add_argument("--iterations", type=int, default=50)
    parser.add_argument("--skip_ref_check", action="store_true")
    args = parser.parse_args()

    if args.benchmark:
        avg_us = run_benchmark(
            args.batch_size, args.seqlen, args.seqlen, args.num_head,
            args.head_dim, is_causal=args.is_causal,
            m_block_size=args.m_block_size, n_block_size=args.n_block_size,
            kv_stages=args.kv_stages,
            warmup_iterations=args.warmup_iterations,
            iterations=args.iterations,
            skip_ref_check=args.skip_ref_check,
        )
        flops = 4 * args.batch_size * args.num_head * args.seqlen * args.seqlen * args.head_dim
        if args.is_causal:
            flops //= 2
        tflops = flops / (avg_us * 1e-6) / 1e12
        print(f"avg time: {avg_us:.2f} us, {tflops:.2f} TFLOPS")
    else:
        # Correctness test sweep
        if args.quick:
            shapes = [(1, 256, 256, 4, 64), (1, 512, 512, 4, 128)]
        else:
            shapes = [
                (1, 256,  256,  1, 64), (1, 256,  256,  4, 128),
                (1, 512,  512,  4, 64), (1, 512,  512,  4, 128),
                (1, 1024, 1024, 4, 64), (1, 1024, 1024, 4, 128),
                (1, 2048, 2048, 4, 64), (1, 2048, 2048, 4, 128),
                # Non-divisible shapes (test OOB masking)
                (1, 300,  300,  4, 128),
                (4, 100,  100,  16, 64),
                (1, 600,  600,  4, 64),
                # Causal sweep
                (1, 512,  512,  4, 128),
                (1, 1024, 1024, 4, 128),
            ]
        all_pass = True
        for B, Sq, Sk, H, D in shapes:
            for causal in [False, True]:
                ok = run_test(B, Sq, Sk, H, D, is_causal=causal,
                              m_block_size=args.m_block_size,
                              n_block_size=args.n_block_size,
                              kv_stages=args.kv_stages)
                all_pass = all_pass and ok
        print(f"\n{'ALL PASS' if all_pass else 'SOME FAILED'}")
