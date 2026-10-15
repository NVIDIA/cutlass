# SPDX-FileCopyrightText: Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
Unit tests for ``cute.arch.load`` / ``cute.arch.store`` with narrow float types.

``nvvm.load.ext`` / ``nvvm.store.ext`` only accept integer, f32 and f64 values
(plus f16/bf16 vectors). An fp8 vector used to pass tracing and then fail in
the NVVM backend (``LLVM Translation failed for operation:
builtin.unrealized_conversion_cast``), an fp8 vector load crashed the
compiler, and f16/bf16/fp8 scalars were rejected by the op verifier. The
wrappers now move such values through a same-width integer bitcast.
"""

import unittest

import torch

import cutlass
import cutlass.cute as cute
from cutlass import (
    BFloat16,
    Float16,
    Float32,
    Float4E2M1FN,
    Float8E4M3FN,
    Float8E5M2,
    Float8E8M0FNU,
    Uint8,
)
from cutlass._mlir import ir
from cutlass.cute.runtime import from_dlpack

ROWS = 32  # one thread per row
N = 32  # elements per row


def _make_store_converted(dtype, via_u8):
    """Each thread converts N f32 values to ``dtype`` and stores the vector into its row."""

    @cute.kernel
    def kernel(out: cute.Tensor):
        tid, _, _ = cute.arch.thread_idx()
        x = cute.make_rmem_tensor(N, Float32)
        for i in cutlass.range_constexpr(N):
            x[i] = Float32(tid + i)
        v = x.load().to(dtype)
        dst = out[tid, None].iterator
        if cutlass.const_expr(via_u8):
            cute.arch.store(dst, v.bitcast(Uint8))
        else:
            cute.arch.store(cute.recast_ptr(dst, dtype=dtype), v)

    @cute.jit
    def entry(out: cute.Tensor):
        kernel(out).launch(grid=(1, 1, 1), block=(ROWS, 1, 1))

    return entry


def _make_vector_roundtrip(dtype):
    """Each thread loads its row as a ``vector<N x dtype>`` and stores it to the output row."""

    @cute.kernel
    def kernel(inp: cute.Tensor, out: cute.Tensor):
        tid, _, _ = cute.arch.thread_idx()
        src = cute.recast_ptr(inp[tid, None].iterator, dtype=dtype)
        dst = cute.recast_ptr(out[tid, None].iterator, dtype=dtype)
        v = cute.arch.load(src, ir.VectorType.get([N], dtype.mlir_type))
        cute.arch.store(dst, v)

    @cute.jit
    def entry(inp: cute.Tensor, out: cute.Tensor):
        kernel(inp, out).launch(grid=(1, 1, 1), block=(ROWS, 1, 1))

    return entry


def _make_scalar_roundtrip(dtype):
    """Each thread copies its row element by element through scalar load/store."""

    @cute.kernel
    def kernel(inp: cute.Tensor, out: cute.Tensor):
        tid, _, _ = cute.arch.thread_idx()
        src = cute.recast_ptr(inp[tid, None].iterator, dtype=dtype)
        dst = cute.recast_ptr(out[tid, None].iterator, dtype=dtype)
        for i in cutlass.range_constexpr(N):
            cute.arch.store(dst + i, cute.arch.load(src + i, dtype))

    @cute.jit
    def entry(inp: cute.Tensor, out: cute.Tensor):
        kernel(inp, out).launch(grid=(1, 1, 1), block=(ROWS, 1, 1))

    return entry


def _make_scalar_store_value(dtype):
    """Each thread stores ``dtype(tid)`` into out[tid]."""

    @cute.kernel
    def kernel(out: cute.Tensor):
        tid, _, _ = cute.arch.thread_idx()
        cute.arch.store(out[tid, None].iterator, dtype(tid))

    @cute.jit
    def entry(out: cute.Tensor):
        kernel(out).launch(grid=(1, 1, 1), block=(ROWS, 1, 1))

    return entry


def _run(entry, *tensors):
    args = [from_dlpack(t, assumed_align=32) for t in tensors]
    cute.compile(entry, *args)(*args)
    torch.cuda.synchronize()


def _bytes(dtype):
    return torch.zeros((ROWS, N * dtype.width // 8), dtype=torch.uint8, device="cuda")


@unittest.skipUnless(torch.cuda.is_available(), "requires a CUDA device")
class TestArchLoadStoreNarrowFloat(unittest.TestCase):
    def test_store_fp8_vector_matches_bitcast_path(self):
        for dtype in (Float8E4M3FN, Float8E5M2):
            with self.subTest(dtype=dtype.__name__):
                direct, via_u8 = _bytes(dtype), _bytes(dtype)
                _run(_make_store_converted(dtype, False), direct)
                _run(_make_store_converted(dtype, True), via_u8)
                self.assertTrue(torch.equal(direct, via_u8))
                self.assertNotEqual(int(direct.sum()), 0)

    def test_vector_roundtrip(self):
        for dtype in (
            Float8E4M3FN,
            Float8E5M2,
            Float8E8M0FNU,
            Float4E2M1FN,
            Float16,
            BFloat16,
        ):
            with self.subTest(dtype=dtype.__name__):
                inp = torch.randint(
                    0,
                    256,
                    (ROWS, N * dtype.width // 8),
                    dtype=torch.uint8,
                    device="cuda",
                )
                out = _bytes(dtype)
                _run(_make_vector_roundtrip(dtype), inp, out)
                self.assertTrue(torch.equal(inp, out))

    def test_scalar_roundtrip(self):
        for dtype in (Float8E4M3FN, Float8E5M2, Float16, BFloat16):
            with self.subTest(dtype=dtype.__name__):
                inp = torch.randint(
                    0,
                    256,
                    (ROWS, N * dtype.width // 8),
                    dtype=torch.uint8,
                    device="cuda",
                )
                out = _bytes(dtype)
                _run(_make_scalar_roundtrip(dtype), inp, out)
                self.assertTrue(torch.equal(inp, out))

    def test_scalar_store_value(self):
        for dtype, torch_dtype in (
            (Float16, torch.float16),
            (BFloat16, torch.bfloat16),
        ):
            with self.subTest(dtype=dtype.__name__):
                out = torch.zeros((ROWS, 1), dtype=torch_dtype, device="cuda")
                _run(_make_scalar_store_value(dtype), out)
                expected = torch.arange(ROWS, dtype=torch_dtype, device="cuda").reshape(
                    ROWS, 1
                )
                self.assertTrue(torch.equal(out, expected))


if __name__ == "__main__":
    unittest.main()
