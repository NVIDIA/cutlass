# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the NVIDIA
# End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/latest/media/docs/pythonDSL/license.html
#
# Any use, reproduction, disclosure, or distribution of this software
# and related documentation outside the scope permitted by the EULA
# is strictly prohibited.

"""
Regression tests for scalar indexing into a dynamic hierarchical layout.

The scalar coordinate is expanded through ``idx2crd`` before evaluating the
layout. This keeps the generated index dynamically typed when the layout is
dynamic, avoiding a static/dynamic type mismatch during LLVM lowering.
"""

import unittest

import torch

import cutlass
import cutlass.cute as cute
from cutlass import Int32
from cutlass.cute.runtime import from_dlpack


@cute.kernel
def _hierarchical_kernel(out: cute.Tensor, m: Int32, n: Int32):
    layout = cute.make_layout(((3, m), n))
    reference_layout = cute.make_layout(((3, 4), 5))
    out[0] = layout(0)
    out[1] = layout(1)
    out[2] = layout(2)
    out[3] = layout(3)
    out[4] = layout(13)
    out[5] = cute.crd2idx(1, layout)
    out[6] = layout((1, 0))
    out[7] = reference_layout(1)
    out[8] = reference_layout(2)


@cute.jit
def _hierarchical_launch(out: cute.Tensor, m: Int32, n: Int32):
    _hierarchical_kernel(out, m, n).launch(grid=[1, 1, 1], block=[1, 1, 1])


@cute.kernel
def _all_scalar_indices_kernel(out: cute.Tensor, m: Int32, n: Int32):
    layout = cute.make_layout(((3, m), n))
    for index in cutlass.range_constexpr(35):
        out[index] = layout(index)


@cute.jit
def _all_scalar_indices_launch(out: cute.Tensor, m: Int32, n: Int32):
    _all_scalar_indices_kernel(out, m, n).launch(grid=[1, 1, 1], block=[1, 1, 1])


@cute.kernel
def _strided_kernel(out: cute.Tensor, m: Int32, n: Int32):
    layout = cute.make_layout(
        ((3, m), n),
        stride=((1, 3), 3 * m),
    )
    reference_layout = cute.make_layout(
        ((3, 4), 5),
        stride=((1, 3), 12),
    )
    out[0] = layout(1)
    out[1] = reference_layout(1)


@cute.jit
def _strided_launch(out: cute.Tensor, m: Int32, n: Int32):
    _strided_kernel(out, m, n).launch(grid=[1, 1, 1], block=[1, 1, 1])


@cute.kernel
def _tile_to_shape_kernel(out: cute.Tensor, m: Int32):
    layout = cute.tile_to_shape(
        cute.make_layout((8, 4), stride=(4, 1)),
        (8 * m, 4),
        (0, 1),
    )
    reference_layout = cute.tile_to_shape(
        cute.make_layout((8, 4), stride=(4, 1)),
        (32, 4),
        (0, 1),
    )
    out[0] = layout(1)
    out[1] = layout(9)
    out[2] = reference_layout(1)
    out[3] = reference_layout(9)


@cute.jit
def _tile_to_shape_launch(out: cute.Tensor, m: Int32):
    _tile_to_shape_kernel(out, m).launch(grid=[1, 1, 1], block=[1, 1, 1])


@unittest.skipUnless(torch.cuda.is_available(), "needs a CUDA GPU")
class DynamicLayoutScalarIndexTest(unittest.TestCase):
    def test_hierarchical_layout(self):
        out = torch.full((9,), -1, dtype=torch.int32, device="cuda")
        _hierarchical_launch(from_dlpack(out), Int32(4), Int32(5))
        torch.cuda.synchronize()
        values = out.tolist()
        self.assertEqual(values, [0, 1, 2, 3, 13, 1, 1, 1, 2])
        self.assertEqual(values[1], values[7])
        self.assertEqual(values[2], values[8])

    def test_strided_hierarchical_layout(self):
        out = torch.full((2,), -1, dtype=torch.int32, device="cuda")
        _strided_launch(from_dlpack(out), Int32(4), Int32(5))
        torch.cuda.synchronize()
        self.assertEqual(out[0].item(), out[1].item())

    def test_all_scalar_indices(self):
        out = torch.full((35,), -1, dtype=torch.int32, device="cuda")
        _all_scalar_indices_launch(from_dlpack(out), Int32(4), Int32(5))
        torch.cuda.synchronize()
        self.assertEqual(out.tolist(), list(range(35)))

    def test_tile_to_shape_layout(self):
        out = torch.full((4,), -1, dtype=torch.int32, device="cuda")
        _tile_to_shape_launch(from_dlpack(out), Int32(4))
        torch.cuda.synchronize()
        values = out.tolist()
        self.assertEqual(values, [4, 36, 4, 36])
        self.assertEqual(values[0], values[2])
        self.assertEqual(values[1], values[3])


if __name__ == "__main__":
    unittest.main()
