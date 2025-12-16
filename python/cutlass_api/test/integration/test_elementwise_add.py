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
from cutlass_api.utils import device_cc


@pytest.mark.parametrize(
    "M, N",
    [
        (256, 512),
        (1024, 8192),
    ],
)
@pytest.mark.parametrize(
    "dtype",
    [
        torch.float32,
        torch.float16,
    ],
)
def test_elementwise_add(
    M: int,
    N: int,
    dtype: torch.dtype,
):
    A = torch.randint(-1, 2, (M, N), device="cuda", dtype=dtype)
    B = torch.randint(-1, 2, (M, N), device="cuda", dtype=dtype)
    D = torch.empty((M, N), device="cuda", dtype=dtype)

    args = cutlass_api.arguments.ElementwiseArguments(A=A, B=B, out=D)
    kernels = cutlass_api.get_kernels(args)

    assert len(kernels) > 0
    kernel = kernels[0]
    kernel.run(args)

    reference = A + B

    assert torch.allclose(D, reference)
