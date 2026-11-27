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
Unit test for ``abs()`` of unsigned runtime values, on scalars and on
``TensorSSA``.

The absolute value of an unsigned value is the value itself, even with the
top bit set: ``abs(Uint8(200))`` is 200, not 56. The test launches a small
kernel, so it needs a CUDA GPU and skips without one.
"""

import unittest

import torch

import cutlass
import cutlass.cute as cute
from cutlass.cute.runtime import from_dlpack


@cute.kernel
def _abs(src: cute.Tensor, dst: cute.Tensor, vector: cutlass.Constexpr):
    tidx, _, _ = cute.arch.thread_idx()
    if cutlass.const_expr(vector):
        dst.store(abs(src.load()))  # every thread stores the same values
    else:
        dst[tidx] = abs(src[tidx])


@cute.jit
def _launch(
    src: cute.Tensor, dst: cute.Tensor, dtype: cutlass.Constexpr, vector: cutlass.Constexpr
):
    # src and dst hold signed ints of the same width, viewed as dtype in the kernel
    src = cute.recast_tensor(src, dtype)
    dst = cute.recast_tensor(dst, dtype)
    _abs(src, dst, vector).launch(grid=[1, 1, 1], block=[src.shape[0], 1, 1])


@unittest.skipUnless(torch.cuda.is_available(), "needs a CUDA GPU")
class TestAbsUnsigned(unittest.TestCase):
    def test_abs_of_unsigned_is_identity(self):
        for dtype, storage in [
            (cutlass.Uint8, torch.int8),
            (cutlass.Uint16, torch.int16),
            (cutlass.Uint32, torch.int32),
            (cutlass.Uint64, torch.int64),
        ]:
            for vector in (False, True):
                with self.subTest(dtype=dtype.__name__, vector=vector):
                    # Negative in the signed storage, so the top bit is set in dtype
                    src = torch.tensor([-1, -56, -127, 5], dtype=storage, device="cuda")
                    dst = torch.zeros_like(src)
                    _launch(from_dlpack(src), from_dlpack(dst), dtype, vector)
                    torch.cuda.synchronize()
                    self.assertEqual(dst.tolist(), src.tolist())


if __name__ == "__main__":
    unittest.main()
