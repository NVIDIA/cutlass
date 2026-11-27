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

"""Exact short-K checks for the Hopper dense GEMM example.

Run on SM90 with the CuTe DSL example-test dependencies installed::

    python -m pytest test/examples/CuTeDSL/hopper/test_dense_gemm_accumulation.py --target-cc 90 -v

These tests call the example kernel directly, without benchmarking or random
input generation. FP16 WGMMA has instruction K=16; the example groups four
instructions into a K=64 pipeline tile. A single tile therefore already tests
the transition from ACCUMULATE=False to True. Two and three tiles additionally
test retention across the prologue/mainloop boundary.
"""

import cuda.bindings.driver as cuda
import cutlass
import pytest
import torch
from cutlass import cute
from cutlass.cute.runtime import from_dlpack
from hopper.kernel.dense_gemm.dense_gemm import HopperWgmmaGemmKernel

K_TILE = 64
TILE_VALUES = [
    pytest.param((1,), id="one-tile"),
    pytest.param((1, 2), id="two-tiles"),
    pytest.param((1, 2, 4), id="three-tiles"),
    pytest.param((1, 0), id="zero-final-tile"),
    pytest.param((1, -2, 4), id="signed-tiles"),
]


def _make_inputs(tile_values, device):
    # Match the example's (M,K,L), (N,K,L), (M,N,L) layouts with
    # contiguous K for A/B and contiguous N for C. Use one 64x64 CTA.
    k = K_TILE * len(tile_values)
    a = torch.empty((1, 64, k), dtype=torch.float16, device=device)
    for index, value in enumerate(tile_values):
        a[:, :, index * K_TILE : (index + 1) * K_TILE] = value
    b = torch.ones((1, 64, k), dtype=torch.float16, device=device)
    c = torch.full((1, 64, 64), float("nan"), dtype=torch.float32, device=device)
    return a.permute(1, 2, 0), b.permute(1, 2, 0), c.permute(1, 2, 0)


@pytest.mark.L0
@pytest.mark.L1
@pytest.mark.parametrize("tile_values", TILE_VALUES)
def test_dense_gemm_accumulation(tile_values):
    a, b, c = _make_inputs(tile_values, "cuda")
    tensors = tuple(
        from_dlpack(tensor, assumed_align=16).mark_layout_dynamic(leading_dim=1)
        for tensor in (a, b, c)
    )
    stream = cuda.CUstream(torch.cuda.current_stream().cuda_stream)
    gemm = HopperWgmmaGemmKernel(cutlass.Float32, (64, 64), (1, 1))
    compiled = cute.compile(gemm, *tensors, stream)
    compiled(*tensors, stream)
    torch.cuda.synchronize()

    # Every output is sum_k A[k], an exactly representable small integer.
    # In the zero-final-tile case the result must retain the first tile's 64;
    # resetting at each tile or leaving ACCUMULATE false instead returns zero.
    expected = torch.full_like(c, K_TILE * sum(tile_values))
    torch.testing.assert_close(c, expected, rtol=0, atol=0)
