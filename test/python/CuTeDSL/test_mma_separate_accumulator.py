# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/latest/media/docs/pythonDSL/license.html
#
# Any use, reproduction, disclosure, or distribution of this software
# and related documentation outside the scope permitted by the EULA
# is strictly prohibited.

"""
Unit tests for MMAs whose ``C`` accumulator is a separate tensor from ``D``.

`cute.mma_atom_call` and `cute.gemm` compute ``D = A * B + C``. With a register
``C`` distinct from ``D``, the lowering used to write the result to ``C`` and
leave ``D`` unwritten, so storing ``D`` stored undefined values and the kernel
could be eliminated entirely (NVIDIA/cutlass#3689). Each case checks ``D``
against a reference and that ``C`` is left unchanged, and compares with the
in-place form where ``C`` and ``D`` are the same tensor.
"""

import unittest

import cutlass
import cutlass.cute as cute
from cutlass import BFloat16, Float32

try:
    import torch
    from cutlass.cute.runtime import from_dlpack

    HAS_CUDA = torch.cuda.is_available()
except ImportError:
    HAS_CUDA = False


# One m16n8k16 mma.sync, in native per-lane fragments ([lane, value]).
@cute.kernel
def _mma_sync_kernel(
    gA: cute.Tensor,
    gB: cute.Tensor,
    gD: cute.Tensor,
    gC: cute.Tensor,
    atom: cute.MmaAtom,
    in_place: cutlass.Constexpr,
):
    lane, _, _ = cute.arch.thread_idx()
    rA = cute.make_rmem_tensor((8,), BFloat16)
    rB = cute.make_rmem_tensor((4,), BFloat16)
    rC = cute.make_rmem_tensor((4,), Float32)
    rD = cute.make_rmem_tensor((4,), Float32)
    cute.autovec_copy(gA[lane, None], rA)
    cute.autovec_copy(gB[lane, None], rB)
    rC.fill(1.0)
    if cutlass.const_expr(in_place):
        rD.store(rC.load())
        cute.mma_atom_call(atom, rD, rA, rB, rD)
    else:
        cute.mma_atom_call(atom, rD, rA, rB, rC)
    cute.autovec_copy(rD, gD[lane, None])
    cute.autovec_copy(rC, gC[lane, None])


@cute.jit
def _mma_sync(
    gA: cute.Tensor,
    gB: cute.Tensor,
    gD: cute.Tensor,
    gC: cute.Tensor,
    in_place: cutlass.Constexpr,
):
    op = cute.nvgpu.warp.MmaF16BF16Op(BFloat16, Float32, (16, 8, 16))
    atom = cute.make_mma_atom(op)
    _mma_sync_kernel(gA, gB, gD, gC, atom, in_place).launch(
        grid=(1, 1, 1), block=(32, 1, 1)
    )


# One scalar FMA through the universal MMA atom.
@cute.kernel
def _fma_kernel(g: cute.Tensor, atom: cute.MmaAtom, in_place: cutlass.Constexpr):
    rA = cute.make_rmem_tensor((1,), Float32)
    rB = cute.make_rmem_tensor((1,), Float32)
    rC = cute.make_rmem_tensor((1,), Float32)
    rD = cute.make_rmem_tensor((1,), Float32)
    rA[0] = g[0]
    rB[0] = g[1]
    rC[0] = g[2]
    rD.fill(-1.0)
    if cutlass.const_expr(in_place):
        rD.store(rC.load())
        cute.mma_atom_call(atom, rD, rA, rB, rD)
    else:
        cute.mma_atom_call(atom, rD, rA, rB, rC)
    g[3] = rD[0]
    g[4] = rC[0]


@cute.jit
def _fma(g: cute.Tensor, in_place: cutlass.Constexpr):
    atom = cute.make_mma_atom(cute.nvgpu.MmaUniversalOp(Float32))
    _fma_kernel(g, atom, in_place).launch(grid=(1, 1, 1), block=(1, 1, 1))


# cute.gemm with a 2x2 TiledMma of m16n8k16 atoms: each thread's C/D fragment
# has several M and N modes, and K spans two MMA blocks.
@cute.kernel
def _tiled_gemm_kernel(
    gA: cute.Tensor,
    gB: cute.Tensor,
    gC: cute.Tensor,
    gD: cute.Tensor,
    gC_out: cute.Tensor,
    tiled_mma: cute.TiledMma,
    in_place: cutlass.Constexpr,
):
    tidx, _, _ = cute.arch.thread_idx()
    thr_mma = tiled_mma.get_slice(tidx)
    tCgA = thr_mma.partition_A(gA)
    tCgB = thr_mma.partition_B(gB)
    tCgC = thr_mma.partition_C(gC)
    tCrA = tiled_mma.make_fragment_A(tCgA)
    tCrB = tiled_mma.make_fragment_B(tCgB)
    tCrC = tiled_mma.make_fragment_C(tCgC)
    tCrD = tiled_mma.make_fragment_C(tCgC)
    cute.basic_copy(tCgA, tCrA)
    cute.basic_copy(tCgB, tCrB)
    cute.basic_copy(tCgC, tCrC)
    tCrD.fill(-1.0)
    if cutlass.const_expr(in_place):
        tCrD.store(tCrC.load())
        cute.gemm(tiled_mma, tCrD, tCrA, tCrB, tCrD)
    else:
        cute.gemm(tiled_mma, tCrD, tCrA, tCrB, tCrC)
    cute.basic_copy(tCrD, thr_mma.partition_C(gD))
    cute.basic_copy(tCrC, thr_mma.partition_C(gC_out))


@cute.jit
def _tiled_gemm(
    gA: cute.Tensor,
    gB: cute.Tensor,
    gC: cute.Tensor,
    gD: cute.Tensor,
    gC_out: cute.Tensor,
    in_place: cutlass.Constexpr,
):
    op = cute.nvgpu.warp.MmaF16BF16Op(BFloat16, Float32, (16, 8, 16))
    tiled_mma = cute.make_tiled_mma(op, (2, 2, 1))
    _tiled_gemm_kernel(gA, gB, gC, gD, gC_out, tiled_mma, in_place).launch(
        grid=(1, 1, 1), block=(128, 1, 1)
    )


@unittest.skipUnless(HAS_CUDA, "requires torch and a CUDA device")
class TestMmaSeparateAccumulator(unittest.TestCase):
    def test_mma_sync_atom(self):
        """The #3689 reproducer: one mma.sync with a separate zero-filled C."""
        a = torch.ones((32, 8), dtype=torch.bfloat16, device="cuda")
        b = torch.ones((32, 4), dtype=torch.bfloat16, device="cuda")
        for in_place in (False, True):
            with self.subTest(in_place=in_place):
                d = torch.full((32, 4), -1.0, device="cuda")
                c = torch.full((32, 4), -1.0, device="cuda")
                _mma_sync(
                    from_dlpack(a, assumed_align=16),
                    from_dlpack(b, assumed_align=16),
                    from_dlpack(d, assumed_align=16),
                    from_dlpack(c, assumed_align=16),
                    in_place,
                )
                torch.cuda.synchronize()
                # A = B = 1 and K = 16, plus C = 1.
                self.assertTrue(torch.equal(d, torch.full_like(d, 17.0)))
                self.assertTrue(torch.equal(c, torch.full_like(c, 1.0)))

    def test_universal_fma_atom(self):
        for in_place in (False, True):
            with self.subTest(in_place=in_place):
                g = torch.tensor([3.0, 5.0, 1.0, 0.0, 0.0], device="cuda")
                _fma(from_dlpack(g), in_place)
                torch.cuda.synchronize()
                self.assertEqual(g.tolist(), [3.0, 5.0, 1.0, 16.0, 1.0])

    def test_tiled_gemm(self):
        M, N, K = 64, 32, 32
        gen = torch.Generator(device="cuda").manual_seed(0)
        a = torch.randint(-3, 4, (M, K), device="cuda", generator=gen)
        b = torch.randint(-3, 4, (N, K), device="cuda", generator=gen)
        c = torch.randint(-3, 4, (M, N), device="cuda", generator=gen).float()
        a, b = a.to(torch.bfloat16), b.to(torch.bfloat16)
        # Small integers keep every product and sum exact.
        ref = a.float() @ b.float().T + c
        for in_place in (False, True):
            with self.subTest(in_place=in_place):
                d = torch.full((M, N), -1.0, device="cuda")
                c_out = torch.full((M, N), -1.0, device="cuda")
                _tiled_gemm(
                    from_dlpack(a),
                    from_dlpack(b),
                    from_dlpack(c),
                    from_dlpack(d),
                    from_dlpack(c_out),
                    in_place,
                )
                torch.cuda.synchronize()
                self.assertTrue(torch.equal(d, ref))
                self.assertTrue(torch.equal(c_out, c))


if __name__ == "__main__":
    unittest.main()
