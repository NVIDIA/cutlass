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
from blackwell_geforce.kernel.blockscaled_gemm import (
    dense_blockscaled_gemm_persistent_cooperative as cooperative,
    dense_blockscaled_gemm_persistent_pingpong as pingpong,
)


@cute.jit
def square_epilogue(x):
    return x * x + 0.25


def make_inputs(mnkl, dtype, ab_dtype, sf_dtype, sf_vec_size):
    m, n, k, batch = mnkl

    def operand(rows):
        # These signed values are exactly representable in both FP4 and FP8.
        ref = (torch.randint(-2, 3, (batch, rows, k)).float() * 0.5).permute(1, 2, 0)
        tensor, storage = cutlass_torch.cute_tensor_like(
            ref, ab_dtype, is_dynamic_layout=True, assumed_align=16
        )
        tensor.mark_compact_shape_dynamic(
            mode=1,
            stride_order=(2, 0, 1),
            divisibility=2 if ab_dtype == cutlass.Float4E2M1FN else 1,
        )
        return ref, tensor, storage

    def scale_factors(rows):
        sf_k = k // sf_vec_size
        padded_rows = (rows + 127) // 128 * 128
        # Powers of two are exact in both E4M3 and E8M0 scale formats.
        scales = 2.0 ** torch.randint(-3, 0, (batch, padded_rows, sf_k))
        # Pack each 128-row x 4-column block in the MMA scale-factor order.
        packed = (
            scales.reshape(batch, padded_rows // 128, 4, 32, sf_k // 4, 4)
            .permute(0, 1, 4, 3, 2, 5)
            .contiguous()
            .permute(3, 4, 1, 5, 2, 0)
        )
        tensor, storage = cutlass_torch.cute_tensor_like(
            packed, sf_dtype, is_dynamic_layout=True, assumed_align=16
        )
        ref = scales[:, :rows].repeat_interleave(sf_vec_size, dim=2).permute(1, 2, 0)
        return ref, tensor, storage

    a, a_tensor, a_storage = operand(m)
    b, b_tensor, b_storage = operand(n)
    sfa, sfa_tensor, sfa_storage = scale_factors(m)
    sfb, sfb_tensor, sfb_storage = scale_factors(n)
    c = torch.empty(batch, m, n, dtype=dtype, device="cuda").permute(1, 2, 0)
    c_tensor = from_dlpack(c, assumed_align=16).mark_layout_dynamic(leading_dim=1)
    reference = torch.einsum("mkl,nkl->mnl", a.double() * sfa, b.double() * sfb)
    tensors = (a_tensor, b_tensor, sfa_tensor, sfb_tensor, c_tensor)
    storage = (a_storage, b_storage, sfa_storage, sfb_storage, c)
    return tensors, storage, reference


@pytest.mark.L0
@pytest.mark.parametrize(
    "schedule", [cooperative, pingpong], ids=["cooperative", "pingpong"]
)
@pytest.mark.parametrize("dtype", [torch.float16, torch.bfloat16])
@pytest.mark.parametrize("activation", ["identity", "gelu", "square"])
@pytest.mark.parametrize(
    "ab_dtype, sf_dtype, sf_vec_size",
    [
        (cutlass.Float4E2M1FN, cutlass.Float8E4M3FN, 16),
        (cutlass.Float8E4M3FN, cutlass.Float8E8M0FNU, 32),
    ],
    ids=["nvfp4", "mxfp8"],
)
@pytest.mark.parametrize(
    "mnkl, epi_tile",
    [((64, 128, 256, 1), (128, 128)), ((192, 256, 512, 2), (64, 32))],
)
def test_blockscaled_gemm_epilogue(
    schedule, dtype, activation, ab_dtype, sf_dtype, sf_vec_size, mnkl, epi_tile
):
    """Check default and custom operations on scaled accumulators before rounding."""
    if torch.cuda.get_device_capability() != (12, 0):
        pytest.skip("This test requires an SM120 GPU")

    tensors, storage, reference = make_inputs(
        mnkl, dtype, ab_dtype, sf_dtype, sf_vec_size
    )
    stream = cutlass_torch.default_stream()
    max_active_clusters = cutlass.utils.HardwareInfo().get_max_active_clusters(1)
    gemm = schedule.Sm120BlockScaledGemmKernel(
        cutlass.Float32, sf_vec_size, (128, 128, 128), epi_tile
    )
    kwargs = {}
    if activation != "identity":
        kwargs["epilogue_op"] = (
            schedule.gelu if activation == "gelu" else square_epilogue
        )
    compiled = cute.compile(gemm, *tensors, max_active_clusters, stream, **kwargs)
    compiled(*tensors, stream)
    torch.cuda.synchronize()

    if activation == "gelu":
        reference = torch.nn.functional.gelu(reference, approximate="none")
    elif activation == "square":
        reference = reference.square() + 0.25
    torch.testing.assert_close(
        storage[-1].cpu(), reference.to(dtype), atol=2e-3, rtol=torch.finfo(dtype).eps
    )
