# Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:

# 1. Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.

# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.

# 3. Neither the name of the copyright holder nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.

# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

"""
Unit tests for block-scaled reference routing. Does not require a GPU.

``scaled_dense_gemm_reference`` sends a config either to ``torch._scaled_mm``
or to the emulated float32 reference.
"""

import pytest
import torch

from test_utils.gemm import needs_emulated_scaled_reference

FP4 = torch.float4_e2m1fn_x2
E4M3 = torch.float8_e4m3fn
E5M2 = torch.float8_e5m2
E8M0 = torch.float8_e8m0fnu


@pytest.mark.parametrize(
    ("a_dtype", "b_dtype", "scale_dtype", "sf_vec_size"),
    [
        # NVFP4: FP4 operands with E4M3 scales over a 16-element block.
        (FP4, FP4, E4M3, 16),
        # MXFP8: torch handles E8M0 scales over a 32-element block.
        (E4M3, E4M3, E8M0, 32),
        (E5M2, E4M3, E8M0, 32),
    ],
)
def test_torch_scaled_mm_configs_are_not_emulated(
    a_dtype, b_dtype, scale_dtype, sf_vec_size
):
    assert not needs_emulated_scaled_reference(
        a_dtype, b_dtype, scale_dtype, scale_dtype, sf_vec_size
    )


@pytest.mark.parametrize(
    ("a_dtype", "b_dtype", "scale_dtype", "sf_vec_size"),
    [
        # E5M2 x E5M2 is rejected outright by torch.
        (E5M2, E5M2, E8M0, 32),
        # MXFP4: FP4 with E8M0 scales is outside torch's FP4 support.
        (FP4, FP4, E8M0, 32),
        (FP4, FP4, E8M0, 16),
        # FP4 with E4M3 scales over vec size 32. torch assumes
        # vec size 16 based on dtypes and silently returns a wrong result.
        (FP4, FP4, E4M3, 32),
    ],
)
def test_configs_outside_torch_support_are_emulated(
    a_dtype, b_dtype, scale_dtype, sf_vec_size
):
    assert needs_emulated_scaled_reference(
        a_dtype, b_dtype, scale_dtype, scale_dtype, sf_vec_size
    )


@pytest.mark.parametrize("sf_vec_size", [16, 32])
def test_either_operand_triggers_the_fp4_scale_dtype_check(sf_vec_size):
    """One FP4 operand with an unsupported scale dtype is enough to emulate."""
    assert needs_emulated_scaled_reference(FP4, E4M3, E8M0, E8M0, sf_vec_size)
    assert needs_emulated_scaled_reference(E4M3, FP4, E8M0, E8M0, sf_vec_size)
