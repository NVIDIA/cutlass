# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/latest/media/docs/pythonDSL/license.html

import pytest
import torch

import cutlass
import cutlass.cute as cute
from cutlass.cute.runtime import from_dlpack


@cute.kernel
def _decode_kernel(codes: cute.Tensor, output: cute.Tensor):
    thread_idx, _, _ = cute.arch.thread_idx()
    if thread_idx < 256:
        output[thread_idx] = (
            codes[thread_idx].bitcast(cutlass.FloatNV8E5M3FNU).to(cutlass.Float32)
        )


@cute.jit
def _decode(codes: cute.Tensor, output: cute.Tensor):
    _decode_kernel(codes, output).launch(grid=[1, 1, 1], block=[256, 1, 1])


@pytest.mark.L0
def test_float_nv8e5m3fnu_to_float32_decodes_top_binade_as_finite():
    """UE5M3 codes 248-254 are finite and 255 is the sole NaN."""
    if not torch.cuda.is_available():
        pytest.skip("CUDA is required")

    codes = torch.arange(256, dtype=torch.uint8, device="cuda")
    output = torch.empty(256, dtype=torch.float32, device="cuda")
    _decode(from_dlpack(codes), from_dlpack(output))
    torch.cuda.synchronize()

    expected = []
    for code in range(255):
        exponent, mantissa = code >> 3, code & 7
        value = (
            2.0**-14 * (mantissa / 8)
            if exponent == 0
            else 2.0 ** (exponent - 15) * (1 + mantissa / 8)
        )
        expected.append(value)
    torch.testing.assert_close(
        output[:255],
        torch.tensor(expected, dtype=torch.float32, device="cuda"),
        rtol=0,
        atol=0,
    )
    assert torch.isnan(output[255])
    assert torch.isfinite(output[:255]).all()
