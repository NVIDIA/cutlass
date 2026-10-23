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
Unit tests for ``cute.arch.movmatrix_trans``. They run a warp on the GPU and
skip without one.
"""

import unittest

import torch

import cutlass
import cutlass.cute as cute
from cutlass import Int32
from cutlass.cute.runtime import from_dlpack


@cute.kernel
def _transpose(t: cute.Tensor, times: cutlass.Constexpr[int]):
    tidx, _, _ = cute.arch.thread_idx()
    x = Int32(t[tidx])
    for _ in cutlass.range_constexpr(times):
        x = cute.arch.movmatrix_trans(x)
    t[tidx] = x


@cute.jit
def _launch(t: cute.Tensor, times: cutlass.Constexpr[int]):
    _transpose(t, times).launch(grid=[1, 1, 1], block=[32, 1, 1])


def _fragment(matrix):
    """Lane ``4 g + t`` holds row ``g``, columns ``2 t`` and ``2 t + 1``."""
    pairs = matrix.reshape(8, 4, 2).reshape(32, 2).to(torch.int32)
    return (pairs[:, 0] & 0xFFFF) | (pairs[:, 1] << 16)


@unittest.skipUnless(torch.cuda.is_available(), "needs a CUDA GPU")
class TestMovMatrix(unittest.TestCase):
    def setUp(self):
        self.matrix = torch.arange(64, dtype=torch.int32).reshape(8, 8) * 3 + 7

    def run_transpose(self, times):
        t = _fragment(self.matrix).cuda()
        cute.compile(_launch, from_dlpack(t), times)(from_dlpack(t))
        return t.cpu()

    def test_transposes(self):
        self.assertTrue(
            torch.equal(self.run_transpose(1), _fragment(self.matrix.T.contiguous()))
        )

    def test_twice_is_identity(self):
        self.assertTrue(torch.equal(self.run_transpose(2), _fragment(self.matrix)))


if __name__ == "__main__":
    unittest.main()
