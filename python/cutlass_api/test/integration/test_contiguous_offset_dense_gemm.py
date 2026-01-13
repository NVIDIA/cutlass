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

import functools
import os
import pytest
import random
import torch

import cutlass_api


torch.manual_seed(2025)
random.seed(2025)


def test_incorrect_offset_length():
    """
    Offset tensors are required to have `problem_count` elements.

    Test that no kernels are found when this is violated.
    """

    problem_count, m, n, k = 12, 8192, 128, 512

    A = torch.empty((1, m, k), device="cuda", dtype=torch.float16)
    B = torch.empty((problem_count, n, k), device="cuda", dtype=torch.float16).permute(
        0, 2, 1
    )
    out = torch.empty((1, m, n), device="cuda", dtype=torch.float32)

    # Incorrect: should have `problem_count` elements
    offsets = torch.empty((problem_count + 1,), device="cuda", dtype=torch.int32)

    args = cutlass_api.arguments.GroupedGemmArguments(
        A=A,
        B=B,
        out=out,
        accumulator_type=torch.float32,
        offsets=offsets,
    )

    kernels = cutlass_api.get_kernels(args, cc=100)
    assert len(kernels) == 0
