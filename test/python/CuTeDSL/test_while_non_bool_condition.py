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
should do the same. Compile host-only JIT functions to check that each
runtime condition produces valid IR, without launching a CUDA kernel.
"""

import unittest

import cutlass.cute as cute
from cutlass import Float32, Int32


def _count_down(dtype):
    @cute.jit
    def count_down(start: Int32):
        n = dtype(start)
        while n:
            n -= 1

    return count_down


class WhileNonBoolConditionTest(unittest.TestCase):
    def test_count_down_compiles(self):
        for dtype in (Int32, Float32):
            with self.subTest(dtype=dtype.__name__):
                cute.compile(_count_down(dtype), Int32(7))


if __name__ == "__main__":
    unittest.main()
