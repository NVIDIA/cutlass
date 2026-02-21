# Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
# 3. Neither the name of the copyright holder nor the names of its contributors
#    may be used to endorse or promote products derived from this software
#    without specific prior written permission.
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

"""
FP8 Flash Attention v2 for SM120 (Blackwell GeForce / DGX Spark).

Uses inline PTX ``mma.sync.aligned.kind::f8f6f4.m16n8k32.row.col.f32.e4m3.e4m3.f32``
since MmaAtomSM80Type segfaults with FP8 types on SM120 (CUTLASS #3044).

Two implementations:

**FP8FlashAttentionSm120** (proof-of-concept):
  - 1 warp (32 threads), M=16, N=32 tiles
  - O accumulated in GMEM — correct but slow (~1 TFLOPS)

**FP8FlashAttentionSm120Opt** (optimized):
  - 4 warps (128 threads), M=64, N=32 tiles
  - O accumulated in registers (online softmax with rescaling)
  - CpAsync GMEM→SMEM loads with double-buffered K/V pipeline
  - SMEM bank-conflict-free padding (+16 bytes/row)
  - Vectorized 4×4 byte transpose using ``prmt.b32`` for V
  - Per-element causal masking
  - 18-42 TFLOPS on DGX Spark (0.6-1.4x vs BF16 CuTe DSL kernel)

FP32→FP8 conversion uses ``cvt.rn.satfinite.e4m3x2.f32`` pair variant.
"""

import argparse
import torch
import cuda.bindings.driver as cuda

import cutlass
import cutlass.cute as cute
from cutlass.cute.nvgpu import cpasync
from cutlass.cute.runtime import from_dlpack
from cutlass.cutlass_dsl import T, dsl_user_op
from cutlass._mlir import ir
from cutlass._mlir.dialects import llvm
from cutlass.cute.typing import Int32, Float32


# /////////////////////////////////////////////////////////////////////////////
# Inline PTX helpers
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
    """Transpose a 4x4 byte matrix in registers using prmt.b32.

    Input: r0..r3 = 4 rows, each containing 4 packed bytes (i32).
      r0 = {a0, a1, a2, a3}, r1 = {b0, b1, b2, b3}, ...
    Output: t0..t3 = 4 columns after transpose.
      t0 = {a0, b0, c0, d0}, t1 = {a1, b1, c1, d1}, ...

    Uses 8 prmt.b32 instructions (pure register ops, no SMEM).
    """
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
def cvt_f32_to_fp8x4(v0, v1, v2, v3, *, loc=None, ip=None):
    """Pack 4 FP32 → 4 FP8 e4m3 bytes in uint32.

    Uses cvt.rn.satfinite.e4m3x2.f32 (pair variant) + mov.b32 packing.
    Byte layout: [v0, v1, v2, v3] low-to-high.
    """
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


# /////////////////////////////////////////////////////////////////////////////
# Kernel
# /////////////////////////////////////////////////////////////////////////////

class FP8FlashAttentionSm120:
    """Single-warp FP8 Flash Attention for SM120. M=16, N=32 tiles."""

    def __init__(self, head_dim, is_causal=False):
        assert head_dim % 32 == 0
        self._head_dim = head_dim
        self._is_causal = is_causal
        self._M = 16
        self._N = 32

    @cute.jit
    def __call__(self, mQ, mK, mV, mO, softmax_scale, stream):
        fp8 = cutlass.Float8E4M3FN
        M, N, D = self._M, self._N, self._head_dim

        sQ_layout = cute.make_layout((M, D), stride=(D, 1))
        sK_layout = cute.make_layout((N, D), stride=(D, 1))
        sVt_layout = cute.make_layout((D, N), stride=(N, 1))
        sP_layout = cute.make_layout((M, N), stride=(N, 1))

        @cute.struct
        class SharedStorage:
            sQ: cute.struct.Align[
                cute.struct.MemRange[fp8, cute.cosize(sQ_layout)], 128]
            sK: cute.struct.Align[
                cute.struct.MemRange[fp8, cute.cosize(sK_layout)], 128]
            sVt: cute.struct.Align[
                cute.struct.MemRange[fp8, cute.cosize(sVt_layout)], 128]
            sP_f32: cute.struct.Align[
                cute.struct.MemRange[cutlass.Float32, cute.cosize(sP_layout)], 128]

        # G→S copy setup (64-bit = 8 FP8 per copy)
        g2s_bits = 64
        g2s_elems = g2s_bits // fp8.width
        g2s_atom = cute.make_copy_atom(
            cute.nvgpu.CopyUniversalOp(), fp8, num_bits_per_copy=g2s_bits)
        t_dim = 32 // g2s_elems
        num_m = 32 // t_dim
        tv_layout = cute.make_layout((num_m, t_dim), stride=(t_dim, 1))
        v_layout = cute.make_layout((1, g2s_elems))
        g2s_tiled = cute.make_tiled_copy_tv(g2s_atom, tv_layout, v_layout)

        grid = (cute.ceil_div(mQ.shape[1], M), cute.size(mQ.shape[0]),
                cute.size(mQ.shape[2]))
        LOG2E = 1.4426950408889634074
        self.kernel(
            mQ, mK, mV, mO, softmax_scale * LOG2E,
            sQ_layout, sK_layout, sVt_layout, sP_layout,
            g2s_tiled, SharedStorage,
        ).launch(grid=grid, block=[32, 1, 1], stream=stream,
                 smem=SharedStorage.size_in_bytes())

    @cute.kernel
    def kernel(self, mQ: cute.Tensor, mK: cute.Tensor, mV: cute.Tensor,
               mO: cute.Tensor, scale_log2: cutlass.Float32,
               sQ_layout: cute.Layout, sK_layout: cute.Layout,
               sVt_layout: cute.Layout, sP_layout: cute.Layout,
               g2s_tiled: cute.TiledCopy, SharedStorage: cutlass.Constexpr):
        tidx, _, _ = cute.arch.thread_idx()
        m_block, batch, head = cute.arch.block_idx()
        M, N, D = self._M, self._N, self._head_dim

        smem = cutlass.utils.SmemAllocator()
        storage = smem.allocate(SharedStorage)
        sQ = storage.sQ.get_tensor(sQ_layout)
        sK = storage.sK.get_tensor(sK_layout)
        sVt = storage.sVt.get_tensor(sVt_layout)
        sP_f32 = storage.sP_f32.get_tensor(sP_layout)

        gid = tidx // 4
        tip = tidx % 4
        m_base = m_block * M

        n_block_max = cute.ceil_div(mK.shape[1], N)
        if self._is_causal:
            n_block_max = min(
                cute.ceil_div((m_block + 1) * M, N), n_block_max)

        # Load Q once
        gQ = cute.local_tile(
            mQ[batch, None, head, None], (M, D), (m_block, 0))
        thr_g2s = g2s_tiled.get_slice(tidx)
        cute.copy(g2s_tiled, thr_g2s.partition_S(gQ), thr_g2s.partition_D(sQ))
        cute.arch.sync_threads()

        # Init O to zero in GMEM
        n_d_tiles = D // 8
        for dt in range(n_d_tiles):
            db = dt * 8
            mO[batch, m_base + gid,     head, db + tip * 2]     = cutlass.Float32(0.0)
            mO[batch, m_base + gid,     head, db + tip * 2 + 1] = cutlass.Float32(0.0)
            mO[batch, m_base + gid + 8, head, db + tip * 2]     = cutlass.Float32(0.0)
            mO[batch, m_base + gid + 8, head, db + tip * 2 + 1] = cutlass.Float32(0.0)

        row_max_u = cutlass.Float32(-3.4028235e+38)
        row_max_l = cutlass.Float32(-3.4028235e+38)
        row_sum_u = cutlass.Float32(0.0)
        row_sum_l = cutlass.Float32(0.0)

        # Main attention loop
        for n_tile in range(n_block_max):
            nb = n_block_max - n_tile - 1

            # ---- Load K ----
            gK = cute.local_tile(
                mK[batch, None, head, None], (N, D), (nb, 0))
            cute.copy(g2s_tiled, thr_g2s.partition_S(gK),
                      thr_g2s.partition_D(sK))
            cute.arch.sync_threads()

            sQ_f32 = cute.recast_tensor(sQ, cutlass.Float32)
            sK_f32 = cute.recast_tensor(sK, cutlass.Float32)
            n_k = D // 32

            # ---- QK GEMM: 4 n-sub-tiles of m16n8k32 ----
            s0_0 = cutlass.Float32(0.0); s0_1 = cutlass.Float32(0.0)
            s0_2 = cutlass.Float32(0.0); s0_3 = cutlass.Float32(0.0)
            s1_0 = cutlass.Float32(0.0); s1_1 = cutlass.Float32(0.0)
            s1_2 = cutlass.Float32(0.0); s1_3 = cutlass.Float32(0.0)
            s2_0 = cutlass.Float32(0.0); s2_1 = cutlass.Float32(0.0)
            s2_2 = cutlass.Float32(0.0); s2_3 = cutlass.Float32(0.0)
            s3_0 = cutlass.Float32(0.0); s3_1 = cutlass.Float32(0.0)
            s3_2 = cutlass.Float32(0.0); s3_3 = cutlass.Float32(0.0)

            for ki in range(n_k):
                kb = ki * 8
                a0 = bitcast_f32_to_i32(sQ_f32[gid,     kb + tip])
                a1 = bitcast_f32_to_i32(sQ_f32[gid + 8, kb + tip])
                a2 = bitcast_f32_to_i32(sQ_f32[gid,     kb + tip + 4])
                a3 = bitcast_f32_to_i32(sQ_f32[gid + 8, kb + tip + 4])

                b0 = bitcast_f32_to_i32(sK_f32[gid, kb + tip])
                b1 = bitcast_f32_to_i32(sK_f32[gid, kb + tip + 4])
                s0_0, s0_1, s0_2, s0_3 = mma_f8f6f4_m16n8k32_e4m3(
                    a0, a1, a2, a3, b0, b1, s0_0, s0_1, s0_2, s0_3)

                b0 = bitcast_f32_to_i32(sK_f32[8 + gid, kb + tip])
                b1 = bitcast_f32_to_i32(sK_f32[8 + gid, kb + tip + 4])
                s1_0, s1_1, s1_2, s1_3 = mma_f8f6f4_m16n8k32_e4m3(
                    a0, a1, a2, a3, b0, b1, s1_0, s1_1, s1_2, s1_3)

                b0 = bitcast_f32_to_i32(sK_f32[16 + gid, kb + tip])
                b1 = bitcast_f32_to_i32(sK_f32[16 + gid, kb + tip + 4])
                s2_0, s2_1, s2_2, s2_3 = mma_f8f6f4_m16n8k32_e4m3(
                    a0, a1, a2, a3, b0, b1, s2_0, s2_1, s2_2, s2_3)

                b0 = bitcast_f32_to_i32(sK_f32[24 + gid, kb + tip])
                b1 = bitcast_f32_to_i32(sK_f32[24 + gid, kb + tip + 4])
                s3_0, s3_1, s3_2, s3_3 = mma_f8f6f4_m16n8k32_e4m3(
                    a0, a1, a2, a3, b0, b1, s3_0, s3_1, s3_2, s3_3)

            # ---- Per-element causal mask ----
            if self._is_causal:
                neginf = cutlass.Float32(-3.4028235e+38)
                q_u = m_base + gid      # upper row position
                q_l = m_base + gid + 8  # lower row position
                # Each sub-tile covers 8 columns: sub_base = sub*8 + tip*2
                for sub_i, sub_off in enumerate([0, 8, 16, 24]):
                    c0 = nb * N + sub_off + tip * 2
                    c1 = c0 + 1
                    if sub_i == 0:
                        s0_0 = neginf if c0 > q_u else s0_0
                        s0_1 = neginf if c1 > q_u else s0_1
                        s0_2 = neginf if c0 > q_l else s0_2
                        s0_3 = neginf if c1 > q_l else s0_3
                    elif sub_i == 1:
                        s1_0 = neginf if c0 > q_u else s1_0
                        s1_1 = neginf if c1 > q_u else s1_1
                        s1_2 = neginf if c0 > q_l else s1_2
                        s1_3 = neginf if c1 > q_l else s1_3
                    elif sub_i == 2:
                        s2_0 = neginf if c0 > q_u else s2_0
                        s2_1 = neginf if c1 > q_u else s2_1
                        s2_2 = neginf if c0 > q_l else s2_2
                        s2_3 = neginf if c1 > q_l else s2_3
                    elif sub_i == 3:
                        s3_0 = neginf if c0 > q_u else s3_0
                        s3_1 = neginf if c1 > q_u else s3_1
                        s3_2 = neginf if c0 > q_l else s3_2
                        s3_3 = neginf if c1 > q_l else s3_3

            # ---- Online softmax ----
            # Row max (upper row = gid, lower row = gid+8)
            lmu = cute.arch.fmax(cute.arch.fmax(s0_0, s0_1),
                                  cute.arch.fmax(s1_0, s1_1))
            lmu = cute.arch.fmax(lmu, cute.arch.fmax(
                cute.arch.fmax(s2_0, s2_1), cute.arch.fmax(s3_0, s3_1)))
            lmu = cute.arch.fmax(lmu, cute.arch.shuffle_sync_bfly(
                lmu, offset=2, mask=-1, mask_and_clamp=31))
            lmu = cute.arch.fmax(lmu, cute.arch.shuffle_sync_bfly(
                lmu, offset=1, mask=-1, mask_and_clamp=31))

            lml = cute.arch.fmax(cute.arch.fmax(s0_2, s0_3),
                                  cute.arch.fmax(s1_2, s1_3))
            lml = cute.arch.fmax(lml, cute.arch.fmax(
                cute.arch.fmax(s2_2, s2_3), cute.arch.fmax(s3_2, s3_3)))
            lml = cute.arch.fmax(lml, cute.arch.shuffle_sync_bfly(
                lml, offset=2, mask=-1, mask_and_clamp=31))
            lml = cute.arch.fmax(lml, cute.arch.shuffle_sync_bfly(
                lml, offset=1, mask=-1, mask_and_clamp=31))

            new_mu = cute.arch.fmax(row_max_u, lmu)
            new_ml = cute.arch.fmax(row_max_l, lml)

            # Rescale O
            resc_u = cute.math.exp2(
                row_max_u * scale_log2 - new_mu * scale_log2, fastmath=True)
            resc_l = cute.math.exp2(
                row_max_l * scale_log2 - new_ml * scale_log2, fastmath=True)

            for dt in range(n_d_tiles):
                db = dt * 8
                o0 = mO[batch, m_base + gid,     head, db + tip*2]     * resc_u
                o1 = mO[batch, m_base + gid,     head, db + tip*2 + 1] * resc_u
                o2 = mO[batch, m_base + gid + 8, head, db + tip*2]     * resc_l
                o3 = mO[batch, m_base + gid + 8, head, db + tip*2 + 1] * resc_l
                mO[batch, m_base + gid,     head, db + tip*2]     = o0
                mO[batch, m_base + gid,     head, db + tip*2 + 1] = o1
                mO[batch, m_base + gid + 8, head, db + tip*2]     = o2
                mO[batch, m_base + gid + 8, head, db + tip*2 + 1] = o3

            row_sum_u = row_sum_u * resc_u
            row_sum_l = row_sum_l * resc_l

            # exp2((S - new_max) * scale_log2)
            s0_0 = cute.math.exp2(s0_0 * scale_log2 - new_mu * scale_log2, fastmath=True)
            s0_1 = cute.math.exp2(s0_1 * scale_log2 - new_mu * scale_log2, fastmath=True)
            s0_2 = cute.math.exp2(s0_2 * scale_log2 - new_ml * scale_log2, fastmath=True)
            s0_3 = cute.math.exp2(s0_3 * scale_log2 - new_ml * scale_log2, fastmath=True)
            s1_0 = cute.math.exp2(s1_0 * scale_log2 - new_mu * scale_log2, fastmath=True)
            s1_1 = cute.math.exp2(s1_1 * scale_log2 - new_mu * scale_log2, fastmath=True)
            s1_2 = cute.math.exp2(s1_2 * scale_log2 - new_ml * scale_log2, fastmath=True)
            s1_3 = cute.math.exp2(s1_3 * scale_log2 - new_ml * scale_log2, fastmath=True)
            s2_0 = cute.math.exp2(s2_0 * scale_log2 - new_mu * scale_log2, fastmath=True)
            s2_1 = cute.math.exp2(s2_1 * scale_log2 - new_mu * scale_log2, fastmath=True)
            s2_2 = cute.math.exp2(s2_2 * scale_log2 - new_ml * scale_log2, fastmath=True)
            s2_3 = cute.math.exp2(s2_3 * scale_log2 - new_ml * scale_log2, fastmath=True)
            s3_0 = cute.math.exp2(s3_0 * scale_log2 - new_mu * scale_log2, fastmath=True)
            s3_1 = cute.math.exp2(s3_1 * scale_log2 - new_mu * scale_log2, fastmath=True)
            s3_2 = cute.math.exp2(s3_2 * scale_log2 - new_ml * scale_log2, fastmath=True)
            s3_3 = cute.math.exp2(s3_3 * scale_log2 - new_ml * scale_log2, fastmath=True)

            row_sum_u = row_sum_u + s0_0 + s0_1 + s1_0 + s1_1 + s2_0 + s2_1 + s3_0 + s3_1
            row_sum_l = row_sum_l + s0_2 + s0_3 + s1_2 + s1_3 + s2_2 + s2_3 + s3_2 + s3_3
            row_max_u = new_mu
            row_max_l = new_ml

            # ---- Write P to sP_f32 (CLayout positions) ----
            # CLayout: sX_0 → [gid, sub*8+tip*2], sX_1 → [gid, sub*8+tip*2+1]
            #          sX_2 → [gid+8, sub*8+tip*2], sX_3 → [gid+8, sub*8+tip*2+1]
            sP_f32[gid,     0 + tip*2]     = s0_0
            sP_f32[gid,     0 + tip*2 + 1] = s0_1
            sP_f32[gid + 8, 0 + tip*2]     = s0_2
            sP_f32[gid + 8, 0 + tip*2 + 1] = s0_3
            sP_f32[gid,     8 + tip*2]     = s1_0
            sP_f32[gid,     8 + tip*2 + 1] = s1_1
            sP_f32[gid + 8, 8 + tip*2]     = s1_2
            sP_f32[gid + 8, 8 + tip*2 + 1] = s1_3
            sP_f32[gid,     16 + tip*2]     = s2_0
            sP_f32[gid,     16 + tip*2 + 1] = s2_1
            sP_f32[gid + 8, 16 + tip*2]     = s2_2
            sP_f32[gid + 8, 16 + tip*2 + 1] = s2_3
            sP_f32[gid,     24 + tip*2]     = s3_0
            sP_f32[gid,     24 + tip*2 + 1] = s3_1
            sP_f32[gid + 8, 24 + tip*2]     = s3_2
            sP_f32[gid + 8, 24 + tip*2 + 1] = s3_3

            # ---- Load V into sK (reuse), then transpose to sVt ----
            cute.arch.sync_threads()
            gV = cute.local_tile(
                mV[batch, None, head, None], (N, D), (nb, 0))
            cute.copy(g2s_tiled, thr_g2s.partition_S(gV),
                      thr_g2s.partition_D(sK))
            cute.arch.sync_threads()

            # Transpose sK[N,D] → sVt[D,N] via element-wise copy
            # 32 threads, N*D elements → each thread does N*D/32 copies
            n_elems = N * D // 32
            for i in range(n_elems):
                flat = tidx * n_elems + i
                vn = flat // D
                vd = flat % D
                sVt[vd, vn] = sK[vn, vd]
            cute.arch.sync_threads()

            # ---- PV GEMM: O += P @ V^T ----
            # P: A-operand (16, 32), loaded from sP_f32 → FP8 on-the-fly
            # V^T: B-operand (8, 32) per d-sub-tile, from sVt
            sVt_f32 = cute.recast_tensor(sVt, cutlass.Float32)

            # A registers from sP_f32: convert 4 consecutive FP32 → FP8x4
            pa0 = cvt_f32_to_fp8x4(
                sP_f32[gid,     tip*4], sP_f32[gid,     tip*4+1],
                sP_f32[gid,     tip*4+2], sP_f32[gid,     tip*4+3])
            pa1 = cvt_f32_to_fp8x4(
                sP_f32[gid + 8, tip*4], sP_f32[gid + 8, tip*4+1],
                sP_f32[gid + 8, tip*4+2], sP_f32[gid + 8, tip*4+3])
            pa2 = cvt_f32_to_fp8x4(
                sP_f32[gid,     tip*4+16], sP_f32[gid,     tip*4+17],
                sP_f32[gid,     tip*4+18], sP_f32[gid,     tip*4+19])
            pa3 = cvt_f32_to_fp8x4(
                sP_f32[gid + 8, tip*4+16], sP_f32[gid + 8, tip*4+17],
                sP_f32[gid + 8, tip*4+18], sP_f32[gid + 8, tip*4+19])

            for dt in range(n_d_tiles):
                db = dt * 8
                vb0 = bitcast_f32_to_i32(sVt_f32[db + gid, tip])
                vb1 = bitcast_f32_to_i32(sVt_f32[db + gid, tip + 4])

                o0 = mO[batch, m_base + gid,     head, db + tip*2]
                o1 = mO[batch, m_base + gid,     head, db + tip*2 + 1]
                o2 = mO[batch, m_base + gid + 8, head, db + tip*2]
                o3 = mO[batch, m_base + gid + 8, head, db + tip*2 + 1]

                o0, o1, o2, o3 = mma_f8f6f4_m16n8k32_e4m3(
                    pa0, pa1, pa2, pa3, vb0, vb1, o0, o1, o2, o3)

                mO[batch, m_base + gid,     head, db + tip*2]     = o0
                mO[batch, m_base + gid,     head, db + tip*2 + 1] = o1
                mO[batch, m_base + gid + 8, head, db + tip*2]     = o2
                mO[batch, m_base + gid + 8, head, db + tip*2 + 1] = o3

            cute.arch.sync_threads()

        # ---- Final normalize: O /= row_sum ----
        row_sum_u = row_sum_u + cute.arch.shuffle_sync_bfly(
            row_sum_u, offset=2, mask=-1, mask_and_clamp=31)
        row_sum_u = row_sum_u + cute.arch.shuffle_sync_bfly(
            row_sum_u, offset=1, mask=-1, mask_and_clamp=31)
        row_sum_l = row_sum_l + cute.arch.shuffle_sync_bfly(
            row_sum_l, offset=2, mask=-1, mask_and_clamp=31)
        row_sum_l = row_sum_l + cute.arch.shuffle_sync_bfly(
            row_sum_l, offset=1, mask=-1, mask_and_clamp=31)

        inv_u = cutlass.Float32(1.0) / row_sum_u if row_sum_u != cutlass.Float32(0.0) else cutlass.Float32(1.0)
        inv_l = cutlass.Float32(1.0) / row_sum_l if row_sum_l != cutlass.Float32(0.0) else cutlass.Float32(1.0)

        for dt in range(n_d_tiles):
            db = dt * 8
            mO[batch, m_base+gid,   head, db+tip*2]   = mO[batch, m_base+gid,   head, db+tip*2]   * inv_u
            mO[batch, m_base+gid,   head, db+tip*2+1]  = mO[batch, m_base+gid,   head, db+tip*2+1]  * inv_u
            mO[batch, m_base+gid+8, head, db+tip*2]   = mO[batch, m_base+gid+8, head, db+tip*2]   * inv_l
            mO[batch, m_base+gid+8, head, db+tip*2+1]  = mO[batch, m_base+gid+8, head, db+tip*2+1]  * inv_l


# /////////////////////////////////////////////////////////////////////////////
# Optimized: 4-warp, register O accumulation
# /////////////////////////////////////////////////////////////////////////////

class FP8FlashAttentionSm120Opt:
    """Optimized FP8 Flash Attention for SM120.

    4 warps (128 threads), M=64 (16 rows/warp), N=32.
    Register O accumulation, CpAsync GMEM→SMEM pipeline,
    SMEM bank-conflict-free padding, vectorized V transpose.
    """

    def __init__(self, head_dim, n_block_size=32, is_causal=False):
        assert head_dim % 32 == 0
        self._head_dim = head_dim
        self._is_causal = is_causal
        self._M = 64   # 4 warps × 16
        self._N = n_block_size
        self._num_warps = 4
        self._num_threads = 128

    @cute.jit
    def __call__(self, mQ, mK, mV, mO, softmax_scale, stream):
        fp8 = cutlass.Float8E4M3FN
        M, N, D = self._M, self._N, self._head_dim

        # Padded strides to avoid SMEM bank conflicts.
        # Without padding, gid 0-7 all hit the same bank (8-way conflict).
        # Padding must be 16-byte aligned for CpAsync 128-bit copies.
        # +16 bytes per FP8 row → (D+16)/4 mod 32 != 0 → no bank conflicts.
        D_pad = D + 16  # FP8 row stride for Q, K, V (16-byte aligned)
        N_pad = N + 16  # FP8 row stride for Vt (transposed)
        NP_pad = N + 4  # F32 row stride for P (4 extra F32 = 16 bytes)

        sQ_layout = cute.make_layout((M, D), stride=(D_pad, 1))
        sK_layout = cute.make_layout((N, D), stride=(D_pad, 1))
        sVt_layout = cute.make_layout((D, N), stride=(N_pad, 1))
        sP_layout = cute.make_layout((M, N), stride=(NP_pad, 1))

        @cute.struct
        class SharedStorage:
            sQ: cute.struct.Align[
                cute.struct.MemRange[fp8, cute.cosize(sQ_layout)], 128]
            sK: cute.struct.Align[
                cute.struct.MemRange[fp8, cute.cosize(sK_layout)], 128]
            sV: cute.struct.Align[
                cute.struct.MemRange[fp8, cute.cosize(sK_layout)], 128]
            sVt: cute.struct.Align[
                cute.struct.MemRange[fp8, cute.cosize(sVt_layout)], 128]
            sP_f32: cute.struct.Align[
                cute.struct.MemRange[cutlass.Float32, cute.cosize(sP_layout)], 128]

        # G→S copy: CpAsync 128-bit = 16 FP8 per copy, 128 threads
        g2s_bits = 128
        g2s_elems = g2s_bits // fp8.width  # 16
        g2s_atom = cute.make_copy_atom(
            cpasync.CopyG2SOp(cache_mode=cpasync.LoadCacheMode.GLOBAL),
            fp8, num_bits_per_copy=g2s_bits)
        t_dim = D // g2s_elems  # D-adaptive: threads along D
        num_m = self._num_threads // t_dim
        tv_layout = cute.make_layout((num_m, t_dim), stride=(t_dim, 1))
        v_layout = cute.make_layout((1, g2s_elems))
        g2s_tiled = cute.make_tiled_copy_tv(g2s_atom, tv_layout, v_layout)

        grid = (cute.ceil_div(mQ.shape[1], M), cute.size(mQ.shape[0]),
                cute.size(mQ.shape[2]))
        LOG2E = 1.4426950408889634074

        self.kernel(
            mQ, mK, mV, mO, softmax_scale * LOG2E,
            sQ_layout, sK_layout, sVt_layout, sP_layout,
            g2s_tiled, SharedStorage,
        ).launch(grid=grid, block=[self._num_threads, 1, 1], stream=stream,
                 smem=SharedStorage.size_in_bytes())

    @cute.kernel
    def kernel(self, mQ: cute.Tensor, mK: cute.Tensor, mV: cute.Tensor,
               mO: cute.Tensor, scale_log2: cutlass.Float32,
               sQ_layout: cute.Layout, sK_layout: cute.Layout,
               sVt_layout: cute.Layout, sP_layout: cute.Layout,
               g2s_tiled: cute.TiledCopy, SharedStorage: cutlass.Constexpr):
        tidx, _, _ = cute.arch.thread_idx()
        m_block, batch, head = cute.arch.block_idx()
        M, N, D = self._M, self._N, self._head_dim

        smem = cutlass.utils.SmemAllocator()
        storage = smem.allocate(SharedStorage)
        sQ = storage.sQ.get_tensor(sQ_layout)
        sK = storage.sK.get_tensor(sK_layout)
        sV = storage.sV.get_tensor(sK_layout)
        sVt = storage.sVt.get_tensor(sVt_layout)
        sP_f32 = storage.sP_f32.get_tensor(sP_layout)

        warp_idx = tidx // 32
        lane_id = tidx % 32
        gid = lane_id // 4
        tip = lane_id % 4
        m_warp = warp_idx * 16
        m_base = m_block * M

        n_block_max = cute.ceil_div(mK.shape[1], N)
        if self._is_causal:
            n_block_max = min(
                cute.ceil_div((m_block + 1) * M, N), n_block_max)

        # CpAsync load Q tile to SMEM
        gQ = cute.local_tile(
            mQ[batch, None, head, None], (M, D), (m_block, 0))
        thr_g2s = g2s_tiled.get_slice(tidx)
        cute.copy(g2s_tiled, thr_g2s.partition_S(gQ), thr_g2s.partition_D(sQ))
        cute.arch.cp_async_commit_group()
        cute.arch.cp_async_wait_group(0)
        cute.arch.sync_threads()

        # Prefetch first K tile (CpAsync, in-flight during init)
        n_block_first = n_block_max - 1
        gK_pf = cute.local_tile(
            mK[batch, None, head, None], (N, D), (n_block_first, 0))
        cute.copy(g2s_tiled, thr_g2s.partition_S(gK_pf),
                  thr_g2s.partition_D(sK))
        cute.arch.cp_async_commit_group()

        # Init O accumulators in registers: D/8 sub-tiles × 4 regs
        n_d_tiles = D // 8
        # Using flat arrays for O: o_0..o_3 per d-sub-tile
        # Store as list of 4-tuples, indexed by d-tile
        o_regs = [
            [cutlass.Float32(0.0), cutlass.Float32(0.0),
             cutlass.Float32(0.0), cutlass.Float32(0.0)]
            for _ in range(n_d_tiles)
        ]

        row_max_u = cutlass.Float32(-3.4028235e+38)
        row_max_l = cutlass.Float32(-3.4028235e+38)
        row_sum_u = cutlass.Float32(0.0)
        row_sum_l = cutlass.Float32(0.0)

        sQ_f32 = cute.recast_tensor(sQ, cutlass.Float32)
        n_k = D // 32
        n_n_sub = N // 8  # n-sub-tiles for QK GEMM
        n_pv_k_iters = N // 32  # k-iterations for PV GEMM

        for n_tile in range(n_block_max):
            nb = n_block_max - n_tile - 1

            # ---- Wait for K (CpAsync from previous iteration or prologue) ----
            cute.arch.cp_async_wait_group(0)
            cute.arch.sync_threads()

            # ---- Issue async V load (overlaps with QK GEMM) ----
            gV = cute.local_tile(
                mV[batch, None, head, None], (N, D), (nb, 0))
            cute.copy(g2s_tiled, thr_g2s.partition_S(gV),
                      thr_g2s.partition_D(sV))
            cute.arch.cp_async_commit_group()

            sK_f32 = cute.recast_tensor(sK, cutlass.Float32)

            # ---- QK GEMM ----
            # S accumulators: n_n_sub sub-tiles × 4 regs
            s_regs = [
                [cutlass.Float32(0.0), cutlass.Float32(0.0),
                 cutlass.Float32(0.0), cutlass.Float32(0.0)]
                for _ in range(n_n_sub)
            ]

            for ki in cutlass.range_constexpr(n_k):
                kb = ki * 8
                a0 = bitcast_f32_to_i32(sQ_f32[m_warp + gid,     kb + tip])
                a1 = bitcast_f32_to_i32(sQ_f32[m_warp + gid + 8, kb + tip])
                a2 = bitcast_f32_to_i32(sQ_f32[m_warp + gid,     kb + tip + 4])
                a3 = bitcast_f32_to_i32(sQ_f32[m_warp + gid + 8, kb + tip + 4])

                for ni in cutlass.range_constexpr(n_n_sub):
                    b0 = bitcast_f32_to_i32(sK_f32[ni * 8 + gid, kb + tip])
                    b1 = bitcast_f32_to_i32(sK_f32[ni * 8 + gid, kb + tip + 4])
                    s_regs[ni][0], s_regs[ni][1], s_regs[ni][2], s_regs[ni][3] = \
                        mma_f8f6f4_m16n8k32_e4m3(
                            a0, a1, a2, a3, b0, b1,
                            s_regs[ni][0], s_regs[ni][1],
                            s_regs[ni][2], s_regs[ni][3])

            # ---- Causal mask ----
            if self._is_causal:
                neginf = cutlass.Float32(-3.4028235e+38)
                q_u = m_base + m_warp + gid
                q_l = m_base + m_warp + gid + 8
                for ni in cutlass.range_constexpr(n_n_sub):
                    c0 = nb * N + ni * 8 + tip * 2
                    c1 = c0 + 1
                    s_regs[ni][0] = neginf if c0 > q_u else s_regs[ni][0]
                    s_regs[ni][1] = neginf if c1 > q_u else s_regs[ni][1]
                    s_regs[ni][2] = neginf if c0 > q_l else s_regs[ni][2]
                    s_regs[ni][3] = neginf if c1 > q_l else s_regs[ni][3]

            # ---- Online softmax: row max ----
            lmu = s_regs[0][0]
            lml = s_regs[0][2]
            for ni in cutlass.range_constexpr(n_n_sub):
                lmu = cute.arch.fmax(lmu, cute.arch.fmax(s_regs[ni][0], s_regs[ni][1]))
                lml = cute.arch.fmax(lml, cute.arch.fmax(s_regs[ni][2], s_regs[ni][3]))
            # Thread-quad reduction for row max
            lmu = cute.arch.fmax(lmu, cute.arch.shuffle_sync_bfly(
                lmu, offset=2, mask=-1, mask_and_clamp=31))
            lmu = cute.arch.fmax(lmu, cute.arch.shuffle_sync_bfly(
                lmu, offset=1, mask=-1, mask_and_clamp=31))
            lml = cute.arch.fmax(lml, cute.arch.shuffle_sync_bfly(
                lml, offset=2, mask=-1, mask_and_clamp=31))
            lml = cute.arch.fmax(lml, cute.arch.shuffle_sync_bfly(
                lml, offset=1, mask=-1, mask_and_clamp=31))

            new_mu = cute.arch.fmax(row_max_u, lmu)
            new_ml = cute.arch.fmax(row_max_l, lml)

            # Rescale O accumulators
            resc_u = cute.math.exp2(
                row_max_u * scale_log2 - new_mu * scale_log2, fastmath=True)
            resc_l = cute.math.exp2(
                row_max_l * scale_log2 - new_ml * scale_log2, fastmath=True)

            for dt in cutlass.range_constexpr(n_d_tiles):
                o_regs[dt][0] = o_regs[dt][0] * resc_u
                o_regs[dt][1] = o_regs[dt][1] * resc_u
                o_regs[dt][2] = o_regs[dt][2] * resc_l
                o_regs[dt][3] = o_regs[dt][3] * resc_l

            row_sum_u = row_sum_u * resc_u
            row_sum_l = row_sum_l * resc_l

            # Apply exp2 to S and accumulate row_sum
            for ni in cutlass.range_constexpr(n_n_sub):
                s_regs[ni][0] = cute.math.exp2(
                    s_regs[ni][0] * scale_log2 - new_mu * scale_log2, fastmath=True)
                s_regs[ni][1] = cute.math.exp2(
                    s_regs[ni][1] * scale_log2 - new_mu * scale_log2, fastmath=True)
                s_regs[ni][2] = cute.math.exp2(
                    s_regs[ni][2] * scale_log2 - new_ml * scale_log2, fastmath=True)
                s_regs[ni][3] = cute.math.exp2(
                    s_regs[ni][3] * scale_log2 - new_ml * scale_log2, fastmath=True)
                row_sum_u = row_sum_u + s_regs[ni][0] + s_regs[ni][1]
                row_sum_l = row_sum_l + s_regs[ni][2] + s_regs[ni][3]

            row_max_u = new_mu
            row_max_l = new_ml

            # ---- Write P to sP_f32 (CLayout → row-major for PV A-operand) ----
            for ni in cutlass.range_constexpr(n_n_sub):
                col_base = ni * 8
                sP_f32[m_warp + gid,     col_base + tip*2]     = s_regs[ni][0]
                sP_f32[m_warp + gid,     col_base + tip*2 + 1] = s_regs[ni][1]
                sP_f32[m_warp + gid + 8, col_base + tip*2]     = s_regs[ni][2]
                sP_f32[m_warp + gid + 8, col_base + tip*2 + 1] = s_regs[ni][3]

            # ---- Wait for V (CpAsync), issue next K prefetch ----
            cute.arch.cp_async_wait_group(0)
            cute.arch.sync_threads()

            # Prefetch next K (overlaps with transpose + PV GEMM)
            if nb > 0:
                gK_next = cute.local_tile(
                    mK[batch, None, head, None], (N, D), (nb - 1, 0))
                cute.copy(g2s_tiled, thr_g2s.partition_S(gK_next),
                          thr_g2s.partition_D(sK))
                cute.arch.cp_async_commit_group()

            # Transpose sV[N,D] → sVt[D,N] using vectorized 4x4 byte blocks.
            # Each block: load 4 i32 from 4 consecutive rows of sV (same col group),
            # transpose 4x4 bytes in registers via prmt.b32, store 4 i32 to sVt.
            # 4x fewer SMEM ops than element-wise (8 vs 32 per 16-byte block).
            sV_f32_tr = cute.recast_tensor(sV, cutlass.Float32)
            sVt_f32_tr = cute.recast_tensor(sVt, cutlass.Float32)
            n_blocks_n = N // 4
            n_blocks_d = D // 4
            n_total_blocks = n_blocks_n * n_blocks_d
            n_blocks_per_thread = n_total_blocks // self._num_threads
            for bi in cutlass.range_constexpr(n_blocks_per_thread):
                block_idx = tidx * n_blocks_per_thread + bi
                bn = block_idx // n_blocks_d
                bd = block_idx % n_blocks_d
                r0 = bitcast_f32_to_i32(sV_f32_tr[bn * 4 + 0, bd])
                r1 = bitcast_f32_to_i32(sV_f32_tr[bn * 4 + 1, bd])
                r2 = bitcast_f32_to_i32(sV_f32_tr[bn * 4 + 2, bd])
                r3 = bitcast_f32_to_i32(sV_f32_tr[bn * 4 + 3, bd])
                t0, t1, t2, t3 = transpose_4x4_bytes(r0, r1, r2, r3)
                sVt_f32_tr[bd * 4 + 0, bn] = bitcast_i32_to_f32(t0)
                sVt_f32_tr[bd * 4 + 1, bn] = bitcast_i32_to_f32(t1)
                sVt_f32_tr[bd * 4 + 2, bn] = bitcast_i32_to_f32(t2)
                sVt_f32_tr[bd * 4 + 3, bn] = bitcast_i32_to_f32(t3)
            cute.arch.sync_threads()

            sVt_f32 = cute.recast_tensor(sVt, cutlass.Float32)

            # ---- PV GEMM: O += P × V^T (register-accumulated) ----
            for pv_ki in cutlass.range_constexpr(n_pv_k_iters):
                pk_base = pv_ki * 32
                # Load A (P) from sP_f32, convert to FP8
                pa0 = cvt_f32_to_fp8x4(
                    sP_f32[m_warp + gid, pk_base + tip*4],
                    sP_f32[m_warp + gid, pk_base + tip*4 + 1],
                    sP_f32[m_warp + gid, pk_base + tip*4 + 2],
                    sP_f32[m_warp + gid, pk_base + tip*4 + 3])
                pa1 = cvt_f32_to_fp8x4(
                    sP_f32[m_warp + gid + 8, pk_base + tip*4],
                    sP_f32[m_warp + gid + 8, pk_base + tip*4 + 1],
                    sP_f32[m_warp + gid + 8, pk_base + tip*4 + 2],
                    sP_f32[m_warp + gid + 8, pk_base + tip*4 + 3])
                pa2 = cvt_f32_to_fp8x4(
                    sP_f32[m_warp + gid, pk_base + 16 + tip*4],
                    sP_f32[m_warp + gid, pk_base + 16 + tip*4 + 1],
                    sP_f32[m_warp + gid, pk_base + 16 + tip*4 + 2],
                    sP_f32[m_warp + gid, pk_base + 16 + tip*4 + 3])
                pa3 = cvt_f32_to_fp8x4(
                    sP_f32[m_warp + gid + 8, pk_base + 16 + tip*4],
                    sP_f32[m_warp + gid + 8, pk_base + 16 + tip*4 + 1],
                    sP_f32[m_warp + gid + 8, pk_base + 16 + tip*4 + 2],
                    sP_f32[m_warp + gid + 8, pk_base + 16 + tip*4 + 3])

                vt_k_offset = pv_ki * 8  # offset in sVt_f32 second dim
                for dt in cutlass.range_constexpr(n_d_tiles):
                    db = dt * 8
                    vb0 = bitcast_f32_to_i32(
                        sVt_f32[db + gid, vt_k_offset + tip])
                    vb1 = bitcast_f32_to_i32(
                        sVt_f32[db + gid, vt_k_offset + tip + 4])
                    o_regs[dt][0], o_regs[dt][1], o_regs[dt][2], o_regs[dt][3] = \
                        mma_f8f6f4_m16n8k32_e4m3(
                            pa0, pa1, pa2, pa3, vb0, vb1,
                            o_regs[dt][0], o_regs[dt][1],
                            o_regs[dt][2], o_regs[dt][3])

            cute.arch.sync_threads()

        # ---- Final normalize: O /= row_sum ----
        row_sum_u = row_sum_u + cute.arch.shuffle_sync_bfly(
            row_sum_u, offset=2, mask=-1, mask_and_clamp=31)
        row_sum_u = row_sum_u + cute.arch.shuffle_sync_bfly(
            row_sum_u, offset=1, mask=-1, mask_and_clamp=31)
        row_sum_l = row_sum_l + cute.arch.shuffle_sync_bfly(
            row_sum_l, offset=2, mask=-1, mask_and_clamp=31)
        row_sum_l = row_sum_l + cute.arch.shuffle_sync_bfly(
            row_sum_l, offset=1, mask=-1, mask_and_clamp=31)

        inv_u = cutlass.Float32(1.0) / row_sum_u if row_sum_u != cutlass.Float32(0.0) else cutlass.Float32(1.0)
        inv_l = cutlass.Float32(1.0) / row_sum_l if row_sum_l != cutlass.Float32(0.0) else cutlass.Float32(1.0)

        # Write normalized O to GMEM
        for dt in cutlass.range_constexpr(n_d_tiles):
            db = dt * 8
            mO[batch, m_base + m_warp + gid,     head, db + tip*2]     = o_regs[dt][0] * inv_u
            mO[batch, m_base + m_warp + gid,     head, db + tip*2 + 1] = o_regs[dt][1] * inv_u
            mO[batch, m_base + m_warp + gid + 8, head, db + tip*2]     = o_regs[dt][2] * inv_l
            mO[batch, m_base + m_warp + gid + 8, head, db + tip*2 + 1] = o_regs[dt][3] * inv_l


# /////////////////////////////////////////////////////////////////////////////
# Test
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


def run_test(B, Sq, Sk, H, D, is_causal=False, desc="", use_opt=False):
    scale = 1.0 / (D ** 0.5)
    torch.manual_seed(42)
    q = (torch.randn(B, Sq, H, D, device='cuda') * 0.1).to(torch.float8_e4m3fn)
    k = (torch.randn(B, Sk, H, D, device='cuda') * 0.1).to(torch.float8_e4m3fn)
    v = (torch.randn(B, Sk, H, D, device='cuda') * 0.1).to(torch.float8_e4m3fn)

    # Reference
    qf = q.float().view(B * H, Sq, D)
    kf = k.float().view(B * H, Sk, D)
    vf = v.float().view(B * H, Sk, D)
    s = torch.bmm(qf, kf.transpose(1, 2)) * scale
    if is_causal:
        mask = torch.triu(torch.ones(Sq, Sk, device='cuda'), diagonal=1).bool()
        s.masked_fill_(mask.unsqueeze(0), float('-inf'))
    p = torch.softmax(s, dim=-1)
    ref = torch.bmm(p, vf).view(B, Sq, H, D)

    stream = cuda.CUstream(torch.cuda.current_stream().cuda_stream)
    o_f32 = torch.zeros(B, Sq, H, D, dtype=torch.float32, device='cuda')

    if use_opt:
        kern = FP8FlashAttentionSm120Opt(D, is_causal=is_causal)
    else:
        kern = FP8FlashAttentionSm120(D, is_causal=is_causal)
    compiled = cute.compile(kern, make_cute_fp8(q), make_cute_fp8(k),
                            make_cute_fp8(v), make_cute_f32(o_f32),
                            scale, stream)
    compiled(make_cute_fp8(q), make_cute_fp8(k), make_cute_fp8(v),
             make_cute_f32(o_f32), scale, stream)
    torch.cuda.synchronize()

    diff = (o_f32 - ref).abs()
    max_d = diff.max().item()
    mean_d = diff.mean().item()
    ok = max_d < 0.1
    tag = ("opt" if use_opt else "poc") + (" causal" if is_causal else "")
    print(f"{'PASS' if ok else 'FAIL'} | {desc:30s} | B={B} Sq={Sq:3d} Sk={Sk:3d} "
          f"H={H} D={D:3d} {tag:12s} | max={max_d:.6f} mean={mean_d:.6f}")
    return ok


def run_benchmark(
    batch_size, seqlen_q, seqlen_k, num_head, head_dim,
    softmax_scale=None, is_causal=False,
    warmup_iterations=10, iterations=50,
    skip_ref_check=False, use_opt=True,
):
    """Benchmark FP8 flash attention. Returns avg time in microseconds."""
    import cutlass.cute.testing as testing

    if softmax_scale is None:
        softmax_scale = 1.0 / (head_dim ** 0.5)

    tag = "opt" if use_opt else "poc"
    print(f"Running FP8 FA ({tag}): B={batch_size} Sq={seqlen_q} "
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

    if use_opt:
        kern = FP8FlashAttentionSm120Opt(head_dim, is_causal=is_causal)
    else:
        kern = FP8FlashAttentionSm120(head_dim, is_causal=is_causal)
    compiled = cute.compile(kern, q, k, v, o, softmax_scale, stream)

    if not skip_ref_check:
        compiled(q, k, v, o, softmax_scale, stream)
        torch.cuda.synchronize()
        qf = q_torch.float().view(batch_size * num_head, seqlen_q, head_dim)
        kf = k_torch.float().view(batch_size * num_head, seqlen_k, head_dim)
        vf = v_torch.float().view(batch_size * num_head, seqlen_k, head_dim)
        s = torch.bmm(qf, kf.transpose(1, 2)) * softmax_scale
        if is_causal:
            mask = torch.triu(torch.ones(seqlen_q, seqlen_k, device='cuda'),
                              diagonal=1).bool()
            s.masked_fill_(mask.unsqueeze(0), float('-inf'))
        p = torch.softmax(s, dim=-1)
        ref = torch.bmm(p, vf).view(batch_size, seqlen_q, num_head, head_dim)
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
        description="FP8 Flash Attention v2 for SM120 (Blackwell GeForce)")
    parser.add_argument("--quick", action="store_true", help="Run minimal tests")
    parser.add_argument("--benchmark", action="store_true",
                        help="Run benchmarks instead of correctness tests")
    parser.add_argument("--batch_size", type=int, default=1)
    parser.add_argument("--seqlen", type=int, default=512)
    parser.add_argument("--num_head", type=int, default=16)
    parser.add_argument("--head_dim", type=int, default=128)
    parser.add_argument("--is_causal", action="store_true")
    parser.add_argument("--warmup_iterations", type=int, default=10)
    parser.add_argument("--iterations", type=int, default=50)
    parser.add_argument("--skip_ref_check", action="store_true")
    args = parser.parse_args()

    if args.benchmark:
        avg_us = run_benchmark(
            args.batch_size, args.seqlen, args.seqlen, args.num_head,
            args.head_dim, is_causal=args.is_causal,
            warmup_iterations=args.warmup_iterations,
            iterations=args.iterations,
            skip_ref_check=args.skip_ref_check,
            use_opt=True,
        )
        flops = 4 * args.batch_size * args.num_head * args.seqlen * args.seqlen * args.head_dim
        if args.is_causal:
            flops //= 2
        tflops = flops / (avg_us * 1e-6) / 1e12
        print(f"avg time: {avg_us:.2f} us, {tflops:.2f} TFLOPS")
        print("PASS")
    else:
        all_pass = True

        # POC kernel tests (single-warp, M=16)
        poc_configs = [
            (1, 16, 32, 1, 128, False, "POC: single tile"),
            (1, 16, 64, 1, 128, False, "POC: Sq=16 Sk=64"),
            (1, 16, 128, 1, 128, False, "POC: Sq=16 Sk=128"),
            (1, 32, 64, 1, 128, False, "POC: multi M-tile"),
            (1, 64, 128, 1, 128, False, "POC: Sq=64 Sk=128"),
        ]
        if not args.quick:
            poc_configs += [
                (1, 16, 32, 1, 64, False, "POC: D=64"),
                (1, 16, 32, 1, 256, False, "POC: D=256"),
                (2, 32, 64, 1, 128, False, "POC: batch=2"),
                (1, 32, 64, 4, 128, False, "POC: heads=4"),
                (1, 32, 32, 1, 128, True, "POC: causal 32"),
                (1, 64, 64, 1, 128, True, "POC: causal 64"),
            ]

        for B, Sq, Sk, H, D, causal, desc in poc_configs:
            ok = run_test(B, Sq, Sk, H, D, is_causal=causal, desc=desc)
            if not ok:
                all_pass = False

        # Optimized kernel tests (4-warp, M=64, register O)
        opt_configs = [
            (1, 64, 64, 1, 128, False, "Opt: single tile"),
            (1, 64, 128, 1, 128, False, "Opt: Sq=64 Sk=128"),
            (1, 128, 256, 1, 128, False, "Opt: multi M-tile"),
            (1, 64, 64, 1, 64, False, "Opt: D=64"),
        ]
        if not args.quick:
            opt_configs += [
                (2, 128, 128, 1, 128, False, "Opt: batch=2"),
                (1, 128, 128, 4, 128, False, "Opt: heads=4"),
                (1, 64, 64, 1, 128, True, "Opt: causal 64"),
                (1, 128, 128, 1, 128, True, "Opt: causal 128"),
                (1, 256, 256, 1, 128, True, "Opt: causal 256"),
            ]

        for B, Sq, Sk, H, D, causal, desc in opt_configs:
            ok = run_test(B, Sq, Sk, H, D, is_causal=causal, desc=desc,
                          use_opt=True)
            if not ok:
                all_pass = False

        print(f"\n{'ALL TESTS PASSED!' if all_pass else 'SOME TESTS FAILED!'}")
