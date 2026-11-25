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
Unit tests for ``/`` on integer ``TensorSSA`` values.

Like ``Int32 / Int32`` on scalars, true division of integer tensors gives a
Float32 result. The tests divide tensor by tensor, tensor by a Python int and
a Python int by a tensor, store the result into a Float32 tensor and compare
with torch. They need a CUDA GPU and skip without one.
"""

import unittest

import torch

import cutlass
import cutlass.cute as cute
from cutlass.cute.runtime import from_dlpack

TYPES = [
    (cutlass.Int32, torch.int32),
    (cutlass.Int8, torch.int8),
    (cutlass.Uint8, torch.uint8),
]


@cute.kernel
def _kernel(a: cute.Tensor, b: cute.Tensor, o: cute.Tensor):
    x = a.load()
    y = b.load()
    o[(0, None)].store(x / y)
    o[(1, None)].store(x / 4)
    o[(2, None)].store(10 / y)
    o[(3, None)].store((x / y).to(cutlass.Float32))


@cute.jit
def _launch(a: cute.Tensor, b: cute.Tensor, o: cute.Tensor):
    _kernel(a, b, o).launch(grid=[1, 1, 1], block=[1, 1, 1])


@unittest.skipUnless(torch.cuda.is_available(), "needs a CUDA GPU")
class TensorSSATrueDivTest(unittest.TestCase):
    def test_integer_truediv_gives_float32(self):
        b = [2, 2, 3, 4, 7, 5, 1, 8]
        for dtype, torch_dtype in TYPES:
            if dtype.signed:
                a = [7, -7, 1, 9, 100, -3, 0, 5]
            else:
                a = [7, 200, 1, 9, 100, 3, 0, 255]
            with self.subTest(dtype=dtype.__name__):
                a_dev = torch.tensor(a, dtype=torch_dtype, device="cuda")
                b_dev = torch.tensor(b, dtype=torch_dtype, device="cuda")
                o = torch.zeros(4, 8, dtype=torch.float32, device="cuda")
                _launch(from_dlpack(a_dev), from_dlpack(b_dev), from_dlpack(o))
                torch.cuda.synchronize()
                af = torch.tensor(a, dtype=torch.float32)
                bf = torch.tensor(b, dtype=torch.float32)
                ref = torch.stack([af / bf, af / 4, 10 / bf, af / bf])
                torch.testing.assert_close(o.cpu(), ref)


if __name__ == "__main__":
    unittest.main()
