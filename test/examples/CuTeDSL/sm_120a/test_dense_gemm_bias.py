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


def make_tensors(mnkl, dtype, c_major):
    m, n, k, batch = mnkl
    a = (torch.randn(batch, m, k, device="cuda", dtype=dtype) * 0.25).permute(1, 2, 0)
    b = (torch.randn(batch, n, k, device="cuda", dtype=dtype) * 0.25).permute(1, 2, 0)
    if c_major == "n":
        c = torch.empty(batch, m, n, device="cuda", dtype=dtype).permute(1, 2, 0)
    else:
        c = torch.empty(batch, n, m, device="cuda", dtype=dtype).permute(2, 1, 0)
    tensors = (
        from_dlpack(a, assumed_align=16).mark_layout_dynamic(leading_dim=1),
        from_dlpack(b, assumed_align=16).mark_layout_dynamic(leading_dim=1),
        from_dlpack(c, assumed_align=16).mark_layout_dynamic(
            leading_dim=1 if c_major == "n" else 0
        ),
    )
    return (a, b, c), tensors


@pytest.mark.L0
@pytest.mark.parametrize("dtype", [torch.float16, torch.bfloat16])
@pytest.mark.parametrize("activation", ["identity", "gelu", "square"])
@pytest.mark.parametrize("c_major", ["n", "m"])
@pytest.mark.parametrize("mnkl", [(64, 192, 128, 1), (192, 320, 256, 2)])
def test_dense_gemm_column_bias(dtype, activation, c_major, mnkl):
    """Bias follows global N, broadcasts across M/L, and precedes activation."""
    if torch.cuda.get_device_capability() != (12, 0):
        pytest.skip("This test requires an SM120 GPU")
    (a, b, c), tensors = make_tensors(mnkl, dtype, c_major)
    bias = torch.randn(mnkl[1], device="cuda", dtype=dtype)
    bias_tensor = from_dlpack(bias, assumed_align=16).mark_layout_dynamic(leading_dim=0)
    stream = cutlass_torch.default_stream()
    kwargs = {}
    if activation != "identity":
        kwargs["epilogue_op"] = gelu if activation == "gelu" else square_epilogue
    # Two CTAs force persistent scheduling to visit multiple M/N/batch tiles.
    compiled = cute.compile(
        Sm120GemmKernel(cutlass.Float32, (128, 128, 64), 4),
        *tensors,
        2,
        stream,
        bias=bias_tensor,
        **kwargs,
    )
    compiled(*tensors, stream, bias=bias_tensor)
    torch.cuda.synchronize()
    reference = torch.einsum("mkl,nkl->mnl", a.cpu().double(), b.cpu().double())
    reference += bias.cpu().double()[None, :, None]
    if activation == "gelu":
        reference = torch.nn.functional.gelu(reference, approximate="none")
    elif activation == "square":
        reference = reference.square() + 0.25
    torch.testing.assert_close(
        c.cpu(), reference.to(dtype), atol=2e-3, rtol=torch.finfo(dtype).eps
    )


@pytest.mark.L0
@pytest.mark.parametrize(
    "dtype, delta", [(torch.float16, 2**-11), (torch.bfloat16, 2**-8)]
)
def test_bias_is_added_before_output_rounding(dtype, delta):
    """Rounding the GEMM output before adding -1 would incorrectly produce zero."""
    if torch.cuda.get_device_capability() != (12, 0):
        pytest.skip("This test requires an SM120 GPU")
    (a, b, c), tensors = make_tensors((64, 128, 64, 1), dtype, "n")
    a.zero_()
    b.zero_()
    a[:, 0, :] = 1
    a[:, 1, :] = delta
    b[:, :2, :] = 1
    bias = torch.full((128,), -1, device="cuda", dtype=dtype)
    bias_tensor = from_dlpack(bias, assumed_align=16)
    stream = cutlass_torch.default_stream()
    compiled = cute.compile(
        Sm120GemmKernel(cutlass.Float32, (128, 128, 64), 4),
        *tensors,
        2,
        stream,
        bias=bias_tensor,
    )
    compiled(*tensors, stream, bias=bias_tensor)
    torch.cuda.synchronize()
    torch.testing.assert_close(c, torch.full_like(c, delta), atol=0, rtol=0)


@pytest.mark.L0
@pytest.mark.parametrize(
    "invalid, error_type, message",
    [
        ("dtype", TypeError, "bias dtype must match"),
        ("rank", ValueError, "bias must be a one-dimensional vector"),
        ("stride", ValueError, "bias must be contiguous"),
        ("accumulator", TypeError, "bias requires fp32 accumulation"),
    ],
)
def test_reject_unsupported_bias_metadata(invalid, error_type, message):
    if torch.cuda.get_device_capability() != (12, 0):
        pytest.skip("This test requires an SM120 GPU")
    _storage, tensors = make_tensors((64, 128, 64, 1), torch.float16, "n")
    bias = torch.zeros(128, device="cuda", dtype=torch.float16)
    acc_dtype = cutlass.Float32
    if invalid == "dtype":
        bias = bias.float()
    elif invalid == "rank":
        bias = bias.reshape(1, 128)
    elif invalid == "stride":
        bias = torch.zeros(256, device="cuda", dtype=torch.float16)[::2]
    else:
        acc_dtype = cutlass.Float16
    with pytest.raises(error_type, match=message):
        cute.compile(
            Sm120GemmKernel(acc_dtype, (128, 128, 64), 4),
            *tensors,
            2,
            cutlass_torch.default_stream(),
            bias=from_dlpack(bias, assumed_align=16),
        )
