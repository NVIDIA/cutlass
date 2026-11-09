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
Unit tests for ``cute.math.abs`` and ``cute.math.absi`` on unsigned runtime
values, on scalars and on ``TensorSSA``.

The absolute value of an unsigned value is the value itself, even with the
top bit set: ``cute.math.abs(Uint8(200))`` is 200, not 56. Signed types are
checked too. The tests launch a small kernel, so they need a CUDA GPU and
skip without one.
"""

import unittest

import torch

import cutlass
import cutlass.cute as cute
from cutlass.cute.runtime import from_dlpack

# Each dtype is paired with a signed torch type of the same width; the kernel
# views the data as the dtype.
TYPES = [
    (cutlass.Uint8, torch.int8),
    (cutlass.Uint16, torch.int16),
    (cutlass.Uint32, torch.int32),
    (cutlass.Uint64, torch.int64),
    (cutlass.Int8, torch.int8),
    (cutlass.Int32, torch.int32),
]


def _run(fn, dtype, vector):
    @cute.kernel
    def kernel(src: cute.Tensor, dst: cute.Tensor):
        tidx, _, _ = cute.arch.thread_idx()
        if cutlass.const_expr(vector):
            dst.store(fn(src.load()))  # every thread stores the same values
        else:
            dst[tidx] = fn(src[tidx])

    @cute.jit
    def launch(src: cute.Tensor, dst: cute.Tensor):
        src = cute.recast_tensor(src, dtype)
        dst = cute.recast_tensor(dst, dtype)
        kernel(src, dst).launch(grid=[1, 1, 1], block=[src.shape[0], 1, 1])

    return launch


@unittest.skipUnless(torch.cuda.is_available(), "needs a CUDA GPU")
class MathAbsUnsignedTest(unittest.TestCase):
    def test_abs(self):
        for name in ("abs", "absi"):
            fn = getattr(cute.math, name)
            for dtype, storage in TYPES:
                for vector in (False, True):
                    with self.subTest(fn=name, dtype=dtype.__name__, vector=vector):
                        # Negative in the signed storage, so the top bit is set
                        src = torch.tensor(
                            [-1, -56, -127, 5], dtype=storage, device="cuda"
                        )
                        dst = torch.zeros_like(src)
                        _run(fn, dtype, vector)(from_dlpack(src), from_dlpack(dst))
                        torch.cuda.synchronize()
                        ref = src if not dtype.signed else src.abs()
                        self.assertEqual(dst.tolist(), ref.tolist())


if __name__ == "__main__":
    unittest.main()
