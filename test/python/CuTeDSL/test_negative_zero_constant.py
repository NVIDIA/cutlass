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
Unit test for ``-0.0`` and ``0.0`` constants in one kernel.

The IR constant cache keys on the Python value, and ``0.0 == -0.0`` with equal
hashes, so whichever zero came first used to stand in for both. The test
launches a small kernel, so it needs a CUDA GPU and skips without one.
"""

import unittest

import torch

import cutlass
import cutlass.cute as cute
from cutlass.cute.runtime import from_dlpack


@cute.kernel
def _store_zeros(dst: cute.Tensor, negative_first: cutlass.Constexpr):
    if cutlass.const_expr(negative_first):
        dst[1] = cutlass.Float32(-0.0)
        dst[0] = cutlass.Float32(0.0)
    else:
        dst[0] = cutlass.Float32(0.0)
        dst[1] = cutlass.Float32(-0.0)


@cute.jit
def _launch(dst: cute.Tensor, negative_first: cutlass.Constexpr):
    _store_zeros(dst, negative_first).launch(grid=[1, 1, 1], block=[1, 1, 1])


@unittest.skipUnless(torch.cuda.is_available(), "needs a CUDA GPU")
class TestNegativeZeroConstant(unittest.TestCase):
    def test_both_zeros_keep_their_sign(self):
        for negative_first in (False, True):
            with self.subTest(negative_first=negative_first):
                dst = torch.full((2,), 7.0, device="cuda")
                _launch(from_dlpack(dst), negative_first)
                torch.cuda.synchronize()
                self.assertEqual(dst.tolist(), [0.0, 0.0])
                self.assertEqual(torch.signbit(dst).tolist(), [False, True])


if __name__ == "__main__":
    unittest.main()
