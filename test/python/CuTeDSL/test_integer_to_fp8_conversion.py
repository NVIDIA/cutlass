# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary

"""Regression tests for integer-to-FP8 CuTe DSL casts."""

import unittest

import torch

import cutlass
import cutlass.cute as cute
from cutlass.cute.runtime import from_dlpack


@cute.kernel
def _cast_int_to_fp8(
    src: cute.Tensor, dst: cute.Tensor, dtype: cutlass.Constexpr[type]
):
    tidx, _, _ = cute.arch.thread_idx()
    dst[tidx] = src[tidx].to(dtype)


@cute.jit
def _run_cast(
    src: cute.Tensor, dst: cute.Tensor, dtype: cutlass.Constexpr[type]
):
    _cast_int_to_fp8(src, cute.recast_tensor(dst, dtype), dtype).launch(
        grid=[1, 1, 1], block=[4, 1, 1]
    )


@unittest.skipUnless(torch.cuda.is_available(), "needs a CUDA GPU")
class TestIntegerToFP8Conversion(unittest.TestCase):
    def test_numeric_conversion_for_integer_widths_and_fp8_formats(self):
        if torch.cuda.get_device_capability() < (8, 9):
            self.skipTest("FP8 conversion requires compute capability 8.9 or newer")

        cases = (
            (torch.int8, cutlass.Float8E4M3FN, torch.float8_e4m3fn),
            (torch.int8, cutlass.Float8E5M2, torch.float8_e5m2),
            (torch.int16, cutlass.Float8E4M3FN, torch.float8_e4m3fn),
            (torch.int16, cutlass.Float8E5M2, torch.float8_e5m2),
        )
        for src_dtype, dst_dtype, torch_dst_dtype in cases:
            with self.subTest(src_dtype=src_dtype, dst_dtype=dst_dtype):
                src = torch.tensor([-16, 1, 2, 3], dtype=src_dtype, device="cuda")
                dst = torch.empty(4, dtype=torch.uint8, device="cuda")

                _run_cast(from_dlpack(src), from_dlpack(dst), dst_dtype)
                torch.cuda.synchronize()

                actual = dst.view(torch_dst_dtype).float()
                expected = src.float().to(torch_dst_dtype).float()
                torch.testing.assert_close(actual, expected)


if __name__ == "__main__":
    unittest.main()