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
Unit tests for ``range`` and ``cutlass.range`` with a runtime step.

A runtime step may be negative, so the loop bounds are chosen at runtime, and
that choice needs start and stop of one type. The tests mix Int32 and Int64
bounds, as in a grid-stride loop over more than 2**31 elements, and check the
iteration count and the sum of the induction variable against Python.
They need a CUDA GPU and skip without one.
"""

import unittest

import torch

import cutlass
import cutlass.cute as cute
from cutlass import Int32, Int64
from cutlass.cute.runtime import from_dlpack

TYPES = {"i32": Int32, "i64": Int64}

CASES = [
    (3, 1000, 7, ("i32", "i64", "i32")),
    (3, 1000, 7, ("i64", "i32", "i32")),
    (3, 1000, 7, ("i32", "i32", "i64")),
    (999, -1, -3, ("i32", "i64", "i32")),
    (999, 2, -5, ("i64", "i64", "i64")),
    (999, -1, -3, ("i32", "i32", "i32")),
]


def _compile_and_run(start, stop, step, types, use_cutlass_range):
    start_t, stop_t, step_t = (TYPES[t] for t in types)

    @cute.kernel
    def kernel(out: cute.Tensor, a: Int64, b: Int64, c: Int64):
        count = Int64(0)
        total = Int64(0)
        if cutlass.const_expr(use_cutlass_range):
            for i in cutlass.range(start_t(a), stop_t(b), step_t(c)):
                count = count + 1
                total = total + Int64(i)
        else:
            for i in range(start_t(a), stop_t(b), step_t(c)):
                count = count + 1
                total = total + Int64(i)
        out[0] = count
        out[1] = total

    @cute.jit
    def launch(out: cute.Tensor, a: Int64, b: Int64, c: Int64):
        kernel(out, a, b, c).launch(grid=[1, 1, 1], block=[1, 1, 1])

    out = torch.zeros(2, dtype=torch.int64, device="cuda")
    launch(from_dlpack(out), Int64(start), Int64(stop), Int64(step))
    torch.cuda.synchronize()
    return out.tolist()


@unittest.skipUnless(torch.cuda.is_available(), "needs a CUDA GPU")
class RangeRuntimeStepTest(unittest.TestCase):
    def test_mixed_integer_bounds(self):
        for use_cutlass_range in (False, True):
            for start, stop, step, types in CASES:
                with self.subTest(
                    cutlass_range=use_cutlass_range,
                    bounds=(start, stop, step),
                    types=types,
                ):
                    expected = range(start, stop, step)
                    self.assertEqual(
                        _compile_and_run(start, stop, step, types, use_cutlass_range),
                        [len(expected), sum(expected)],
                    )


if __name__ == "__main__":
    unittest.main()
