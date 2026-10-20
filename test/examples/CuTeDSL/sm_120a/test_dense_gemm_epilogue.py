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

import pytest
import torch

import cutlass
import cutlass.cute as cute
import cutlass.torch as cutlass_torch
from cutlass.cute.runtime import from_dlpack
from blackwell_geforce.kernel.dense_gemm.dense_gemm import Sm120GemmKernel, gelu


@cute.jit
def square_epilogue(x):
    return x * x + 0.25


@pytest.mark.L0
@pytest.mark.parametrize("dtype", [torch.float16, torch.bfloat16])
@pytest.mark.parametrize("activation", ["identity", "gelu", "square"])
@pytest.mark.parametrize(
    "mnkl, c_major",
    [((64, 128, 256, 1), "n"), ((192, 256, 512, 2), "m")],
)
def test_dense_gemm_epilogue(dtype, activation, mnkl, c_major):
    """Exercise default, nonlinear and user-defined epilogues before output rounding."""
    if torch.cuda.get_device_capability() != (12, 0):
        pytest.skip("This test requires an SM120 GPU")

    m, n, k, batch = mnkl
    a = (torch.randn(batch, m, k, device="cuda", dtype=dtype) * 0.25).permute(1, 2, 0)
    b = (torch.randn(batch, n, k, device="cuda", dtype=dtype) * 0.25).permute(1, 2, 0)
    if c_major == "n":
        c = torch.empty(batch, m, n, device="cuda", dtype=dtype).permute(1, 2, 0)
    else:
        c = torch.empty(batch, n, m, device="cuda", dtype=dtype).permute(2, 1, 0)

    a_cute = from_dlpack(a, assumed_align=16).mark_layout_dynamic(leading_dim=1)
    b_cute = from_dlpack(b, assumed_align=16).mark_layout_dynamic(leading_dim=1)
    c_cute = from_dlpack(c, assumed_align=16).mark_layout_dynamic(
        leading_dim=1 if c_major == "n" else 0
    )
    stream = cutlass_torch.default_stream()
    max_active_clusters = cutlass.utils.HardwareInfo().get_max_active_clusters(1)
    gemm = Sm120GemmKernel(cutlass.Float32, (128, 128, 64), 4)
    kwargs = {}
    if activation != "identity":
        kwargs["epilogue_op"] = gelu if activation == "gelu" else square_epilogue
    compiled = cute.compile(
        gemm, a_cute, b_cute, c_cute, max_active_clusters, stream, **kwargs
    )
    compiled(a_cute, b_cute, c_cute, stream)
    torch.cuda.synchronize()

    reference = torch.einsum("mkl,nkl->mnl", a.cpu().double(), b.cpu().double())
    if activation == "gelu":
        reference = torch.nn.functional.gelu(reference, approximate="none")
    elif activation == "square":
        reference = reference.square() + 0.25
    reference = reference.to(dtype)
    # FP32 accumulation can land on the other side of an output rounding
    # midpoint than the FP64 reference. Allow one output-precision epsilon.
    torch.testing.assert_close(
        c.cpu(), reference, atol=2e-3, rtol=torch.finfo(dtype).eps
    )
