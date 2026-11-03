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
Unit tests for dynamic ``Int64`` leaves in a tiler.

``cute.ceil_div``, ``cute.zipped_divide``, ``cute.tiled_divide`` and
``cute.logical_divide`` pack their tiler through ``_pack_tile``. A bare 64-bit
integer leaf used to be typed as a 32-bit tile leaf, so ``cute.make_tile`` failed
IR verification with "expected (div=1, width=32) but got (div=1, width=64)"
(NVIDIA/cutlass#3734). The tile type must carry ``?{i64}`` and the result must be
computed in 64-bit arithmetic.
"""

import unittest

import cutlass.cute as cute
from cutlass import Int32, Int64

try:
    import torch
    from cutlass.cute.runtime import from_dlpack

    _HAS_CUDA = torch.cuda.is_available()
except ImportError:  # pragma: no cover - torch is optional for the compile-only tests
    torch = None
    _HAS_CUDA = False


@cute.jit
def _ceil_div_scalar(a: Int64, b: Int64):
    cute.ceil_div(a, b)


@cute.jit
def _ceil_div_tuple(a: Int64, b: Int64):
    cute.ceil_div((a, 64), (b, 4))


@cute.jit
def _ceil_div_mixed_widths(a: Int64, b: Int32):
    cute.ceil_div((a, 64), (Int64(b), b))


@cute.jit
def _divide_layout_by_int64_tiler(a: Int64, b: Int64):
    layout = cute.make_layout((1024, 64))
    cute.zipped_divide(layout, (b, 8))
    cute.tiled_divide(layout, (b, 8))
    cute.logical_divide(layout, (b, 8))


@cute.jit
def _ceil_div_int32_control(a: Int32, b: Int32):
    cute.ceil_div((a, 64), (b, 4))


@cute.kernel
def _ceil_div_kernel(a: Int64, b: Int64, out: cute.Tensor):
    out[0] = Int64(cute.ceil_div(a, b))
    q = cute.ceil_div((a, 64), (b, 4))
    out[1] = Int64(q[0])
    out[2] = Int64(q[1])
    layout = cute.make_layout((1024, 64))
    tiled = cute.zipped_divide(layout, (b, 8))
    out[3] = Int64(cute.size(tiled, mode=[0]))


@cute.jit
def _ceil_div_launch(a: Int64, b: Int64, out: cute.Tensor):
    _ceil_div_kernel(a, b, out).launch(grid=(1, 1, 1), block=(1, 1, 1))


class TestPackTileInt64Leaves(unittest.TestCase):
    def test_ceil_div_int64_scalar_compiles(self):
        cute.compile(_ceil_div_scalar, Int64(100), Int64(7))

    def test_ceil_div_int64_tuple_compiles(self):
        cute.compile(_ceil_div_tuple, Int64(100), Int64(7))

    def test_ceil_div_mixed_widths_compiles(self):
        cute.compile(_ceil_div_mixed_widths, Int64(100), Int32(7))

    def test_divide_layout_by_int64_tiler_compiles(self):
        cute.compile(_divide_layout_by_int64_tiler, Int64(100), Int64(7))

    def test_ceil_div_int32_still_compiles(self):
        cute.compile(_ceil_div_int32_control, Int32(100), Int32(7))

    @unittest.skipUnless(_HAS_CUDA, "requires a CUDA device")
    def test_ceil_div_int64_values(self):
        out = torch.zeros(4, dtype=torch.int64, device="cuda")
        compiled = cute.compile(_ceil_div_launch, Int64(1), Int64(1), from_dlpack(out))
        # Operands and quotients that do not fit in 32 bits exercise the i64 path.
        for a, b in ((100, 7), (2**33 + 100, 7), (2**40, 2**33 + 1)):
            compiled(Int64(a), Int64(b), from_dlpack(out))
            torch.cuda.synchronize()
            expected = [(a + b - 1) // b, (a + b - 1) // b, 16, b * 8]
            self.assertEqual(out.tolist(), expected, f"ceil_div({a}, {b})")


if __name__ == "__main__":
    unittest.main()
