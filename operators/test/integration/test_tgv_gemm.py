# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

"""Integration tests for the TGV low-latency GEMM Operator.

TGV is optimized for narrow-batch decode inference (small M).
It requires specific layouts:
  A (activation): row-major (K-contiguous)
  B (weight): col-major (K-contiguous)
  C (output): row-major (N-contiguous)
"""

import logging

import torch

import cutlass.operators as ops
from cutlass.operators.providers.cutedsl.gemm.sm100_tgv_gemm import TgvGemmOperator
from cutlass.operators.utils.device import device_or_env_target_sm

torch.manual_seed(2026)
logger = logging.getLogger(__name__)


def _make_col_major_B(K, N, L=None, dtype=torch.float16):
    """Create a col-major B tensor (K-contiguous) as expected by TGV.

    Allocates as (N, K) row-major then transposes, so K has stride 1.
    """
    if L is not None:
        B = torch.randint(-1, 2, (L, N, K), device="cuda", dtype=dtype)
        return B.transpose(-1, -2)  # (L, K, N) with K stride=1
    B = torch.randint(-1, 2, (N, K), device="cuda", dtype=dtype)
    return B.t()  # (K, N) with K stride=1


def _get_tgv_operators(args):
    """Get only TGV operators from the manifest."""

    def metadata_filter(metadata):
        return metadata.operator_class is TgvGemmOperator

    return ops.get_operators(
        args,
        target_sm=device_or_env_target_sm(),
        metadata_filter=metadata_filter,
    )


def test_tgv_not_returned_for_row_major_B():
    """TGV Operator should NOT be returned when B is row-major (N-contiguous)."""
    M, K, N = 16, 256, 128
    dtype = torch.float16
    A = torch.randint(-1, 2, (M, K), device="cuda", dtype=dtype)
    # Standard row-major B — NOT K-contiguous
    B = torch.randint(-1, 2, (K, N), device="cuda", dtype=dtype)
    D = torch.empty((M, N), device="cuda", dtype=dtype)

    args = ops.GemmArguments(A, B, D, torch.float32)
    tgv_operators = _get_tgv_operators(args)

    assert len(tgv_operators) == 0, (
        f"Expected no TGV operators for row-major B, got {len(tgv_operators)}"
    )
