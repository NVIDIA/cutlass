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
Unit tests for ``TensorSSA.reduce`` with MAX and MIN on integer tensors.

The tests reduce a (4, 8) tensor over all modes and over mode 1, for signed
and unsigned types with values that differ in order between the two, and
compare with torch. Float32 is checked too. They need a CUDA GPU and skip
without one.
"""

import unittest

import torch

import cutlass
import cutlass.cute as cute
from cutlass.cute.runtime import from_dlpack

ReductionOp = cute.ReductionOp

TYPES = [
    (cutlass.Int32, torch.int32),
    (cutlass.Uint32, torch.uint32),
    (cutlass.Int8, torch.int8),
    (cutlass.Uint8, torch.uint8),
    (cutlass.Float32, torch.float32),
]

INIT = {
    cutlass.Int32: (-(2**31), 2**31 - 1),
    cutlass.Uint32: (0, 2**32 - 1),
    cutlass.Int8: (-128, 127),
    cutlass.Uint8: (0, 255),
    cutlass.Float32: (float("-inf"), float("inf")),
}


def _run(dtype, op, init):
    @cute.kernel
    def kernel(a: cute.Tensor, full: cute.Tensor, rows: cute.Tensor):
        v = a.load()
        full[0] = v.reduce(op, dtype(init), 0)
        rows.store(v.reduce(op, dtype(init), (None, 1)))

    @cute.jit
    def launch(a: cute.Tensor, full: cute.Tensor, rows: cute.Tensor):
        kernel(a, full, rows).launch(grid=[1, 1, 1], block=[1, 1, 1])

    return launch


def _values(t, dtype):
    """Read back a result as Python numbers in the dtype's own order."""
    t = t.cpu()
    if dtype is cutlass.Float32:
        return t.double().tolist()
    same_width = torch.int8 if dtype.width == 8 else torch.int32
    v = t.view(same_width).long()
    if not dtype.signed:
        v = v % 2**dtype.width
    return v.tolist()


@unittest.skipUnless(torch.cuda.is_available(), "needs a CUDA GPU")
class IntegerReduceMinMaxTest(unittest.TestCase):
    def test_min_max(self):
        torch.manual_seed(0)
        for dtype, torch_dtype in TYPES:
            lo, hi = INIT[dtype]
            if dtype is cutlass.Float32:
                a = torch.randn(4, 8, device="cuda")
                ref = a.cpu().double()
            else:
                # Random bit patterns, so signed and unsigned order differ.
                w = dtype.width
                bits = torch.randint(0, 2**w, (4, 8), dtype=torch.int64)
                signed = bits - (bits >= 2 ** (w - 1)).long() * 2**w
                same_width = torch.int8 if w == 8 else torch.int32
                a = signed.to(same_width).view(torch_dtype).cuda()
                ref = signed if dtype.signed else bits
            for op, init, ref_full, ref_rows in (
                (ReductionOp.MAX, lo, ref.max(), ref.amax(dim=1)),
                (ReductionOp.MIN, hi, ref.min(), ref.amin(dim=1)),
            ):
                with self.subTest(dtype=dtype.__name__, op=op):
                    full = torch.zeros(1, dtype=torch_dtype, device="cuda")
                    rows = torch.zeros(4, dtype=torch_dtype, device="cuda")
                    _run(dtype, op, init)(
                        from_dlpack(a), from_dlpack(full), from_dlpack(rows)
                    )
                    torch.cuda.synchronize()
                    self.assertEqual(_values(full, dtype), [ref_full.item()])
                    self.assertEqual(_values(rows, dtype), ref_rows.tolist())


if __name__ == "__main__":
    unittest.main()
