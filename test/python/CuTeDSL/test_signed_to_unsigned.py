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
Unit test for signed to wider unsigned conversions of runtime values.

They sign-extend, as a C cast does: ``Int8(-1).to(Uint32)`` is 0xFFFFFFFF,
not 0xFF. The test launches a small kernel, so it needs a CUDA GPU and skips
without one.
"""

import unittest

import torch

import cutlass
import cutlass.cute as cute
from cutlass.cute.runtime import from_dlpack


@cute.kernel
def _convert(src: cute.Tensor, dst: cute.Tensor, dst_type: cutlass.Constexpr):
    tidx, _, _ = cute.arch.thread_idx()
    dst[tidx] = src[tidx].to(dst_type)


@cute.jit
def _launch(src: cute.Tensor, dst: cute.Tensor, dst_type: cutlass.Constexpr):
    # dst holds signed ints of the same width, viewed as dst_type in the kernel
    dst = cute.recast_tensor(dst, dst_type)
    _convert(src, dst, dst_type).launch(grid=[1, 1, 1], block=[src.shape[0], 1, 1])


@unittest.skipUnless(torch.cuda.is_available(), "needs a CUDA GPU")
class TestSignedToUnsigned(unittest.TestCase):
    def test_widening_sign_extends(self):
        for src_dtype, dst_type, storage in [
            (torch.int8, cutlass.Uint16, torch.int16),
            (torch.int8, cutlass.Uint32, torch.int32),
            (torch.int8, cutlass.Uint64, torch.int64),
            (torch.int16, cutlass.Uint32, torch.int32),
            (torch.int16, cutlass.Uint64, torch.int64),
            (torch.int32, cutlass.Uint64, torch.int64),
        ]:
            with self.subTest(src=src_dtype, dst=dst_type.__name__):
                src = torch.tensor([-1, -128, 0, 5, 127], dtype=src_dtype, device="cuda")
                dst = torch.zeros(5, dtype=storage, device="cuda")
                _launch(from_dlpack(src), from_dlpack(dst), dst_type)
                torch.cuda.synchronize()
                # The sign-extended bits are those of the signed widening
                self.assertEqual(dst.tolist(), src.to(storage).tolist())


if __name__ == "__main__":
    unittest.main()
