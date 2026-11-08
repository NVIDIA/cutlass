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
Unit tests for slicing a ``TensorSSA`` with a coordinate.

Each case slices the loaded value and the memory tensor with the same
coordinate and checks that both give the same elements. The cases cover
flat shapes and integer coordinates into nested modes. They need a CUDA GPU
and skip without one.
"""

import math
import unittest

import torch

import cutlass.cute as cute
from cutlass.cute.runtime import from_dlpack

CASES = [
    ((4, 6), (1, None)),
    ((4, 6), (None, 3)),
    ((2, 3, 4), (1, None, 2)),
    (((2, 3), 4), (1, None)),
    (((2, 3), 4), (4, None)),
    (((2, 3), 4), (None, 2)),
    (((2, 3), 4), ((1, None), None)),
    (((2, 3), 4), ((None, 2), 3)),
    ((4, (3, 2)), (None, 1)),
    (((2, 2), (3, 2)), (1, None)),
    (((2, 2), (3, 2)), (None, (1, None))),
    (((2, 2), (3, 2)), (2, (None, 1))),
]


def _size(shape):
    if isinstance(shape, int):
        return shape
    return math.prod(_size(s) for s in shape)


def _run(shape, crd):
    @cute.kernel
    def kernel(a: cute.Tensor, o_ssa: cute.Tensor, o_mem: cute.Tensor):
        t = cute.make_tensor(a.iterator, cute.make_layout(shape))
        s = t[crd]
        res_layout = cute.make_layout(s.shape)
        cute.make_tensor(o_ssa.iterator, res_layout).store(t.load()[crd])
        cute.make_tensor(o_mem.iterator, res_layout).store(s.load())

    @cute.jit
    def launch(a: cute.Tensor, o_ssa: cute.Tensor, o_mem: cute.Tensor):
        kernel(a, o_ssa, o_mem).launch(grid=[1, 1, 1], block=[1, 1, 1])

    return launch


@unittest.skipUnless(torch.cuda.is_available(), "needs a CUDA GPU")
class TensorSSASliceTest(unittest.TestCase):
    def test_slice_matches_memory_tensor(self):
        for shape, crd in CASES:
            with self.subTest(shape=shape, crd=crd):
                n = _size(shape)
                a = torch.arange(n, dtype=torch.float32, device="cuda")
                o_ssa = torch.full((n,), -1.0, device="cuda")
                o_mem = torch.full((n,), -1.0, device="cuda")
                _run(shape, crd)(from_dlpack(a), from_dlpack(o_ssa), from_dlpack(o_mem))
                torch.cuda.synchronize()
                self.assertEqual(o_ssa.tolist(), o_mem.tolist())


if __name__ == "__main__":
    unittest.main()
