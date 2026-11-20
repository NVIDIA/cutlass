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
Unit tests for keeping unsigned element types on pointers.

MLIR integers are signless, so a pointer rebuilt from its MLIR value alone
reads Uint8 data as Int8. The tests read Uint8 values above 127 through a
pointer kernel argument, ``ptr + k``, a loop-carried pointer, and
``make_tensor`` over ``Tensor.iterator``, and check they come back unchanged.
They need a CUDA GPU and skip without one.
"""

import unittest

import torch

import cutlass
import cutlass.cute as cute
from cutlass.cute.runtime import from_dlpack, make_ptr

VALUES = [200, 128, 255, 1]


@cute.kernel
def _read(a: cute.Tensor, p: cute.Pointer, out: cute.Tensor):
    t = cute.make_tensor(a.iterator, a.layout)
    q = p
    for _ in cutlass.range(1):
        q = q + 0
    for i in cutlass.range_constexpr(4):
        out[0, i] = t[i].to(cutlass.Float32)
        out[1, i] = cute.make_tensor(p, cute.make_layout(4))[i].to(cutlass.Float32)
        out[2, i] = cute.make_tensor(p + i, cute.make_layout(1))[0].to(cutlass.Float32)
        out[3, i] = cute.make_tensor(q, cute.make_layout(4))[i].to(cutlass.Float32)


@cute.jit
def _launch(a: cute.Tensor, p: cute.Pointer, out: cute.Tensor):
    _read(a, p, out).launch(grid=[1, 1, 1], block=[1, 1, 1])


@unittest.skipUnless(torch.cuda.is_available(), "needs a CUDA GPU")
class UnsignedPointerTest(unittest.TestCase):
    def test_uint8_reads_unchanged(self):
        x = torch.tensor(VALUES, dtype=torch.uint8, device="cuda")
        out = torch.zeros(4, 4, device="cuda")
        p = make_ptr(
            cutlass.Uint8, x.data_ptr(), cute.AddressSpace.gmem, assumed_align=4
        )
        _launch(from_dlpack(x), p, from_dlpack(out))
        torch.cuda.synchronize()
        for row, path in enumerate(
            [
                "make_tensor(iterator)",
                "pointer argument",
                "ptr + k",
                "loop-carried pointer",
            ]
        ):
            with self.subTest(path=path):
                self.assertEqual(out[row].tolist(), [float(v) for v in VALUES])


if __name__ == "__main__":
    unittest.main()
