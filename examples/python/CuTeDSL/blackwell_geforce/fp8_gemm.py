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
FP8 GEMM example for NVIDIA Blackwell GeForce SM120 architecture using CuTe DSL.

Computes C = A @ B^T where A and B are FP8 (e4m3) and C is FP32, using SM120's
``mma.sync.aligned.kind::f8f6f4.m16n8k32`` tensor core instruction via inline PTX.

SM120 FP8 MMA Register Layout
==============================

The ``kind::f8f6f4`` instruction has a **different** register layout from the standard
``m16n8k32`` integer MMA. The key differences are:

1. **A register ordering is K-paired, not row-paired:**
   Standard m16n8k32: {upper_k0, upper_k16, lower_k0, lower_k16}
   kind::f8f6f4:      {upper_k0, lower_k0, upper_k16, lower_k16}

2. **B register split is along K, not N:**
   Standard m16n8k32: b0 -> N=0..3, b1 -> N=4..7 (N-split)
   kind::f8f6f4:      b0 -> K=0..15, b1 -> K=16..31 (K-split)

3. **B loading indices are swapped:**
   Standard: b0 = sB_f32[tip, gid]  (tip indexes N, gid indexes K-groups)
   kind::f8f6f4: b0 = sB_f32[gid, tip]  (gid indexes N, tip indexes K-groups)

Complete Register Mapping (gid = tid // 4, tip = tid % 4)
----------------------------------------------------------

A registers (row-major A[16, 32], sA_f32 = recast to Float32 giving shape [16, 8]):
  a0 = sA_f32[gid,   tip]     -> A[gid,   tip*4 : tip*4+3]     (rows 0-7,  K=0..15)
  a1 = sA_f32[gid+8, tip]     -> A[gid+8, tip*4 : tip*4+3]     (rows 8-15, K=0..15)
  a2 = sA_f32[gid,   tip+4]   -> A[gid,   tip*4+16 : tip*4+19] (rows 0-7,  K=16..31)
  a3 = sA_f32[gid+8, tip+4]   -> A[gid+8, tip*4+16 : tip*4+19] (rows 8-15, K=16..31)

B registers (row-major B[8, 32], sB_f32 = recast to Float32 giving shape [8, 8]):
  b0 = sB_f32[gid, tip]       -> B[gid, tip*4 : tip*4+3]       (all N, K=0..15)
  b1 = sB_f32[gid, tip+4]     -> B[gid, tip*4+16 : tip*4+19]   (all N, K=16..31)

C/D layout (standard PTX ISA):
  d0 -> C[gid,   tip*2]
  d1 -> C[gid,   tip*2+1]
  d2 -> C[gid+8, tip*2]
  d3 -> C[gid+8, tip*2+1]

Why not use CuTe's MmaAtom?
============================

CuTe's ``MmaAtomSM80Type`` segfaults when configured with FP8 types on SM120 because
the MLIR backend lacks a lowering path for the ``kind::f8f6f4`` PTX variant (see Issue
#3044). This example works around this via inline PTX assembly using ``llvm.inline_asm``.

Why not use ldmatrix?
=====================

SM120's ``ldmatrix`` only supports 16-bit element types. For FP8, we use direct 32-bit
scalar loads (recast SMEM to Float32, then bitcast to Int32) with the natural row-major
SMEM layout. This avoids the cross-thread swizzling that ldmatrix performs and requires
different SMEM indexing than the CuTe ThrVal layouts used for ldmatrix-based kernels.

To run this example:

.. code-block:: bash

    python examples/python/CuTeDSL/blackwell_geforce/fp8_gemm.py
    python examples/python/CuTeDSL/blackwell_geforce/fp8_gemm.py --M 128 --N 64 --K 256

Constraints:
  * M must be a multiple of 16, N a multiple of 8, K a multiple of 32.
  * Only FP8 e4m3 (Float8E4M3FN) inputs are supported.
  * Output is FP32.
  * Requires SM120 or later (Blackwell GeForce / DGX Spark).
"""

import argparse

import torch
import cuda.bindings.driver as cuda

import cutlass
import cutlass.cute as cute
from cutlass.cute.runtime import from_dlpack
from cutlass.cutlass_dsl import T, dsl_user_op
from cutlass._mlir import ir
from cutlass._mlir.dialects import llvm
from cutlass.cute.typing import Int32, Float32


# /////////////////////////////////////////////////////////////////////////////
# Inline PTX MMA wrapper
# /////////////////////////////////////////////////////////////////////////////

@dsl_user_op
def mma_f8f6f4_m16n8k32_e4m3(
    a0, a1, a2, a3, b0, b1, c0, c1, c2, c3,
    *, loc=None, ip=None,
):
    """Emit mma.sync.aligned.kind::f8f6f4.m16n8k32.row.col.f32.e4m3.e4m3.f32.

    Args:
        a0..a3: Int32 — A matrix fragment registers (4 x uint32, 16 FP8 values)
        b0, b1: Int32 — B matrix fragment registers (2 x uint32, 8 FP8 values)
        c0..c3: Float32 — C accumulator registers (4 x f32)

    Returns:
        Tuple of 4 Float32 — D result registers
    """
    a0_ir = Int32(a0).ir_value(loc=loc, ip=ip)
    a1_ir = Int32(a1).ir_value(loc=loc, ip=ip)
    a2_ir = Int32(a2).ir_value(loc=loc, ip=ip)
    a3_ir = Int32(a3).ir_value(loc=loc, ip=ip)
    b0_ir = Int32(b0).ir_value(loc=loc, ip=ip)
    b1_ir = Int32(b1).ir_value(loc=loc, ip=ip)
    c0_ir = Float32(c0).ir_value(loc=loc, ip=ip)
    c1_ir = Float32(c1).ir_value(loc=loc, ip=ip)
    c2_ir = Float32(c2).ir_value(loc=loc, ip=ip)
    c3_ir = Float32(c3).ir_value(loc=loc, ip=ip)
    ret = llvm.inline_asm(
        ir.Type.parse("!llvm.struct<(f32,f32,f32,f32)>"),
        [a0_ir, a1_ir, a2_ir, a3_ir, b0_ir, b1_ir,
         c0_ir, c1_ir, c2_ir, c3_ir],
        "mma.sync.aligned.kind::f8f6f4.m16n8k32.row.col.f32.e4m3.e4m3.f32 "
        "{$0,$1,$2,$3},{$4,$5,$6,$7},{$8,$9},{$10,$11,$12,$13};",
        "=f,=f,=f,=f,r,r,r,r,r,r,f,f,f,f",
        has_side_effects=True, asm_dialect=0, loc=loc, ip=ip,
    )
    return (Float32(llvm.extractvalue(T.f32(), ret, [0], loc=loc, ip=ip)),
            Float32(llvm.extractvalue(T.f32(), ret, [1], loc=loc, ip=ip)),
            Float32(llvm.extractvalue(T.f32(), ret, [2], loc=loc, ip=ip)),
            Float32(llvm.extractvalue(T.f32(), ret, [3], loc=loc, ip=ip)))


@dsl_user_op
def bitcast_f32_to_i32(val, *, loc=None, ip=None):
    """Bitcast a Float32 value to Int32 (reinterpret 4 FP8 bytes as uint32)."""
    f32_ir = Float32(val).ir_value(loc=loc, ip=ip)
    i32_ir = llvm.bitcast(T.i32(), f32_ir, loc=loc, ip=ip)
    return Int32(i32_ir)


# /////////////////////////////////////////////////////////////////////////////
# FP8 Tiled GEMM kernel
# /////////////////////////////////////////////////////////////////////////////

class FP8GemmSm120:
    """FP8 GEMM for SM120: C[M,N] = A[M,K] @ B[N,K]^T.

    Each CTA computes one (16, 8) output tile, looping over K in chunks of 32.
    Grid: (M//16, N//8, 1), Block: (32, 1, 1) — one warp per tile.
    """

    def __init__(self, K: int):
        self._K = K

    @cute.jit
    def __call__(self, mA: cute.Tensor, mB: cute.Tensor, mC: cute.Tensor,
                 stream: cuda.CUstream):
        fp8 = cutlass.Float8E4M3FN

        # SMEM layouts for one MMA tile: A[16, 32] and B[8, 32] in FP8
        sA_layout = cute.make_layout((16, 32), stride=(32, 1))
        sB_layout = cute.make_layout((8, 32), stride=(32, 1))

        @cute.struct
        class SharedStorage:
            sA: cute.struct.Align[
                cute.struct.MemRange[fp8, cute.cosize(sA_layout)], 128
            ]
            sB: cute.struct.Align[
                cute.struct.MemRange[fp8, cute.cosize(sB_layout)], 128
            ]

        # Global -> Shared copy: 64-bit (8 FP8 elements) per copy
        g2s_bits = 64
        g2s_elems = g2s_bits // fp8.width
        g2s_atom = cute.make_copy_atom(
            cute.nvgpu.CopyUniversalOp(), fp8, num_bits_per_copy=g2s_bits,
        )
        t_dim = 32 // g2s_elems
        num_m = 32 // t_dim
        tv_layout = cute.make_layout((num_m, t_dim), stride=(t_dim, 1))
        v_layout = cute.make_layout((1, g2s_elems))
        g2s_tiled = cute.make_tiled_copy_tv(g2s_atom, tv_layout, v_layout)

        grid_dim = (
            cute.ceil_div(mC.shape[1], 16),
            cute.ceil_div(mC.shape[3], 8),
            1,
        )

        self.kernel(mA, mB, mC, sA_layout, sB_layout, g2s_tiled, SharedStorage,
        ).launch(grid=grid_dim, block=[32, 1, 1], stream=stream,
                 smem=SharedStorage.size_in_bytes())

    @cute.kernel
    def kernel(self, mA: cute.Tensor, mB: cute.Tensor, mC: cute.Tensor,
               sA_layout: cute.Layout, sB_layout: cute.Layout,
               g2s_tiled: cute.TiledCopy, SharedStorage: cutlass.Constexpr):
        tidx, _, _ = cute.arch.thread_idx()
        m_block, n_block, _ = cute.arch.block_idx()
        smem = cutlass.utils.SmemAllocator()
        storage = smem.allocate(SharedStorage)
        sA = storage.sA.get_tensor(sA_layout)
        sB = storage.sB.get_tensor(sB_layout)

        # Thread decomposition for MMA fragment indexing
        gid = tidx // 4   # 0..7: indexes rows for A/B, columns for C
        tip = tidx % 4    # 0..3: indexes K-groups (4 consecutive FP8 values)

        # Initialize FP32 accumulators
        acc0 = cutlass.Float32(0.0)
        acc1 = cutlass.Float32(0.0)
        acc2 = cutlass.Float32(0.0)
        acc3 = cutlass.Float32(0.0)

        n_k_tiles = self._K // 32

        for k_tile in range(n_k_tiles):
            # Load A[m_block*16 : (m_block+1)*16, k_tile*32 : (k_tile+1)*32]
            gA = cute.local_tile(mA[0, None, 0, None], (16, 32), (m_block, k_tile))
            # Load B[n_block*8 : (n_block+1)*8, k_tile*32 : (k_tile+1)*32]
            gB = cute.local_tile(mB[0, None, 0, None], (8, 32), (n_block, k_tile))

            thr_g2s = g2s_tiled.get_slice(tidx)
            cute.copy(g2s_tiled, thr_g2s.partition_S(gA), thr_g2s.partition_D(sA))
            cute.copy(g2s_tiled, thr_g2s.partition_S(gB), thr_g2s.partition_D(sB))
            cute.arch.sync_threads()

            # Recast SMEM to Float32 view for 4-byte (4 FP8) loads
            sA_f32 = cute.recast_tensor(sA, cutlass.Float32)  # shape: (16, 8)
            sB_f32 = cute.recast_tensor(sB, cutlass.Float32)  # shape: (8, 8)

            # Load A registers: kind::f8f6f4 ordering
            # a0 -> rows 0-7,  K first half;  a1 -> rows 8-15, K first half
            # a2 -> rows 0-7,  K second half; a3 -> rows 8-15, K second half
            a0 = bitcast_f32_to_i32(sA_f32[gid,     tip])
            a1 = bitcast_f32_to_i32(sA_f32[gid + 8, tip])
            a2 = bitcast_f32_to_i32(sA_f32[gid,     tip + 4])
            a3 = bitcast_f32_to_i32(sA_f32[gid + 8, tip + 4])

            # Load B registers: K-split ordering (gid indexes N, tip indexes K)
            b0 = bitcast_f32_to_i32(sB_f32[gid, tip])
            b1 = bitcast_f32_to_i32(sB_f32[gid, tip + 4])

            # Accumulate: D = A * B^T + C
            acc0, acc1, acc2, acc3 = mma_f8f6f4_m16n8k32_e4m3(
                a0, a1, a2, a3, b0, b1, acc0, acc1, acc2, acc3,
            )

            cute.arch.sync_threads()

        # Store results using PTX ISA C/D layout
        mC[0, m_block * 16 + gid,     0, n_block * 8 + tip * 2]     = acc0
        mC[0, m_block * 16 + gid,     0, n_block * 8 + tip * 2 + 1] = acc1
        mC[0, m_block * 16 + gid + 8, 0, n_block * 8 + tip * 2]     = acc2
        mC[0, m_block * 16 + gid + 8, 0, n_block * 8 + tip * 2 + 1] = acc3


# /////////////////////////////////////////////////////////////////////////////
# Helper functions
# /////////////////////////////////////////////////////////////////////////////

def make_cute_fp8_tensor(t):
    """Wrap a torch FP8 tensor as a CuTe tensor."""
    fp8 = cutlass.Float8E4M3FN
    t_u8 = t.view(torch.uint8)
    ct = from_dlpack(t_u8, assumed_align=16).mark_layout_dynamic(
        leading_dim=3).mark_compact_shape_dynamic(
        mode=3, stride_order=t_u8.dim_order(),
        divisibility=(128 // fp8.width))
    ct.element_type = fp8
    return ct


def make_cute_f32_tensor(t):
    """Wrap a torch FP32 tensor as a CuTe tensor."""
    return from_dlpack(t, assumed_align=16).mark_layout_dynamic(
        leading_dim=3).mark_compact_shape_dynamic(
        mode=3, stride_order=t.dim_order(), divisibility=4)


def run(M: int, N: int, K: int):
    """Run FP8 GEMM and verify against reference."""
    assert M % 16 == 0, f"M ({M}) must be a multiple of 16"
    assert N % 8 == 0, f"N ({N}) must be a multiple of 8"
    assert K % 32 == 0, f"K ({K}) must be a multiple of 32"

    stream = cuda.CUstream(torch.cuda.current_stream().cuda_stream)

    # Create random FP8 data
    torch.manual_seed(42)
    a_data = torch.randn(1, M, 1, K, dtype=torch.float32, device='cuda') * 0.3
    b_data = torch.randn(1, N, 1, K, dtype=torch.float32, device='cuda') * 0.3
    a_fp8 = a_data.to(torch.float8_e4m3fn)
    b_fp8 = b_data.to(torch.float8_e4m3fn)

    # Reference: compute in FP32 using FP8-quantized values
    ref = a_fp8.squeeze().float() @ b_fp8.squeeze().float().T  # (M, N)

    # CuTe tensors
    a_c = make_cute_fp8_tensor(a_fp8)
    b_c = make_cute_fp8_tensor(b_fp8)
    c_f32 = torch.zeros(1, M, 1, N, dtype=torch.float32, device='cuda')
    c_c = make_cute_f32_tensor(c_f32)

    # Compile and run
    kern = FP8GemmSm120(K)
    compiled = cute.compile(kern, a_c, b_c, c_c, stream)
    compiled(a_c, b_c, c_c, stream)
    torch.cuda.synchronize()

    # Verify
    result = c_f32.squeeze()
    max_diff = (result - ref.squeeze()).abs().max().item()
    return max_diff


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="FP8 GEMM for Blackwell GeForce SM120"
    )
    parser.add_argument("--M", type=int, default=None,
                        help="M dimension (default: run test suite)")
    parser.add_argument("--N", type=int, default=None)
    parser.add_argument("--K", type=int, default=None)
    args = parser.parse_args()

    if args.M is not None and args.N is not None and args.K is not None:
        max_diff = run(args.M, args.N, args.K)
        status = "PASS" if max_diff < 0.1 else "FAIL"
        print(f"{status} | M={args.M} N={args.N} K={args.K} | max_diff={max_diff:.6f}")
    else:
        # Run test suite
        configs = [
            (16, 8, 32, "Single MMA tile"),
            (16, 8, 64, "K=64 (2 K-iterations)"),
            (16, 8, 128, "K=128 (4 K-iterations)"),
            (32, 16, 64, "2x2 MMA tiles"),
            (64, 32, 128, "4x4 MMA tiles"),
            (128, 64, 256, "8x8 MMA tiles"),
            (128, 128, 128, "8x16 MMA tiles"),
        ]
        all_pass = True
        for M, N, K, desc in configs:
            max_diff = run(M, N, K)
            status = "PASS" if max_diff < 0.1 else "FAIL"
            if status == "FAIL":
                all_pass = False
            print(f"{status} | {desc:25s} | M={M:3d} N={N:3d} K={K:3d} | "
                  f"max_diff={max_diff:.6f}")
        print(f"\n{'PASS' if all_pass else 'FAIL'}")
