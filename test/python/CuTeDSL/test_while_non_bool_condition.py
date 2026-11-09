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
Unit tests for ``while`` loops whose condition is a runtime Int32 or Float32.

``if n:`` already treats a non-Boolean value as ``n != 0``; ``while n:``
should do the same. The kernels count down from a runtime value and write
the number of iterations. They need a CUDA GPU and skip without one.
"""

import unittest

import torch

import cutlass.cute as cute
from cutlass import Float32, Int32
from cutlass.cute.runtime import from_dlpack


def _count_down(dtype):
    @cute.kernel
    def kernel(out: cute.Tensor, start: Int32):
        n = dtype(start)
        count = Int32(0)
        while n:
            n -= 1
            count += 1
        out[0] = count

    @cute.jit
    def launch(out: cute.Tensor, start: Int32):
        kernel(out, start).launch(grid=[1, 1, 1], block=[1, 1, 1])

    return launch


@unittest.skipUnless(torch.cuda.is_available(), "needs a CUDA GPU")
class WhileNonBoolConditionTest(unittest.TestCase):
    def test_count_down(self):
        for dtype in (Int32, Float32):
            launch = None
            for start in (0, 1, 7):
                with self.subTest(dtype=dtype.__name__, start=start):
                    out = torch.full((1,), -1, dtype=torch.int32, device="cuda")
                    if launch is None:
                        launch = cute.compile(
                            _count_down(dtype), from_dlpack(out), Int32(start)
                        )
                    launch(from_dlpack(out), Int32(start))
                    torch.cuda.synchronize()
                    self.assertEqual(out.item(), start)


if __name__ == "__main__":
    unittest.main()
