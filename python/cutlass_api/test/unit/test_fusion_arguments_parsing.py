# Copyright (c) 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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


import pytest
import torch

import cutlass_api

pytestmark = pytest.mark.arch("80")


def test_basic_keywords():
    def epi(accum, C, alpha, beta):
        D = (alpha * accum) + (beta * C)
        return D

    cutlass_api.arguments.EpilogueArguments(
        epilogue_fn=epi,
        D=torch.randn(10, 10),
        C=torch.randn(10, 10),
        alpha=1.0,
        beta=1.0,
    )


def test_missing_keywords():
    epifn = """
def epi(accum, C, alpha, beta):
    D = (alpha * accum) + (beta * C)
    F = relu(D)
    return D, F
"""
    try:
        # Missing F
        cutlass_api.arguments.EpilogueArguments(
            epilogue_fn=epifn,
            D=torch.randn(10, 10),
            C=torch.randn(10, 10),
            alpha=1.0,
            beta=1.0,
        )
    except ValueError as e:
        assert "F" in str(e)
    else:
        raise AssertionError("Failed to catch missing keyword")


def test_extra_keywords():
    epifn = """
def epi(accum, C, alpha, beta):
    D = (alpha * accum) + (beta * C)
    F = relu(D)
    return D, F
"""
    try:
        cutlass_api.arguments.EpilogueArguments(
            epilogue_fn=epifn,
            D=torch.randn(10, 10),
            C=torch.randn(10, 10),
            alpha=1.0,
            beta=1.0,
            F=torch.randn(10, 10),
            gamma=3.0,
        )
    except ValueError as e:
        assert "gamma" in str(e)
    else:
        raise AssertionError("Failed to catch extra keyword")
