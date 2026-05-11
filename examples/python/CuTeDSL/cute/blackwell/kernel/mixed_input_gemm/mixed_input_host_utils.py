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

from typing import Optional

import torch

import cutlass
import cutlass.cute as cute
import cutlass.torch as cutlass_torch
import cutlass.utils.mixed_input_helpers as mixed_input_utils
from cutlass.cute.runtime import from_dlpack

"""
This file contains common host-side utilities for mixed-input GEMM.
"""


def create_cumsum_tensor(
    num_groups: int,
    fused_n: int,
    alignment: int,
    uniform_distribution: bool = False,
) -> tuple[cute.Tensor, torch.Tensor]:
    """
    Create a tensor of shape (num_groups + 1) recording the cumulative sum of the elements in each group.
    """
    assert fused_n % alignment == 0, "fused_n must be divisible by alignment"
    if uniform_distribution:
        # keep a uniform distribution for debug and performance collection
        group_counts = torch.tensor([fused_n // num_groups] * num_groups)
    else:
        # sample group sizes with equal probability for each group
        probs = torch.ones(num_groups) / num_groups
        group_sizes = torch.multinomial(probs, fused_n // alignment, replacement=True)
        group_counts = torch.bincount(group_sizes, minlength=num_groups) * alignment
    print(group_counts.tolist())

    # Create cumulative sum
    cumsum_torch = torch.cat([torch.tensor([0]), group_counts.cumsum(0)])
    print(cumsum_torch.tolist())

    cumsum_tensor, _ = cutlass_torch.cute_tensor_like(
        cumsum_torch, cutlass.Int32, is_dynamic_layout=False
    )

    return cumsum_tensor, cumsum_torch.to("cpu")


def create_i4_tensor_and_scale(
    l: int,
    m: int,
    k: int,
    is_m_major: bool,
    dtype: type[cutlass.Numeric],
    shuffle_a: bool,
    scale_granularity_m: int,
    scale_granularity_k: int,
    is_dynamic_layout: bool = True,
    init_config: tuple = (
        cutlass_torch.TensorInitType.RANDOM,
        cutlass_torch.RandomInitConfig(min_val=-7, max_val=6),
    ),
    divisibility: int = 16,
    transformed_dtype: Optional[type[cutlass.Numeric]] = None,
) -> tuple[
    cute.Tensor,
    torch.Tensor,
    torch.Tensor,
    cute.Tensor,
    torch.Tensor,
    torch.Tensor,
]:
    """
    Create quantized 4-bit tensor and corresponding scale tensor.
    """
    lb_4b = -8 if dtype == cutlass.Int4 else 0
    up_4b = 7 if dtype == cutlass.Int4 else 15
    if not (
        init_config[0] == cutlass_torch.TensorInitType.RANDOM
        or init_config[0] == cutlass_torch.TensorInitType.SCALAR
    ):
        raise ValueError(
            "Only random and scalar initialization is supported for 4bit data type"
        )

    # Construct reference tensor in f32
    ref_fp32 = cutlass_torch.matrix(l, m, k, is_m_major, cutlass.Float32, *init_config)
    # Generate scale data and perform quantization
    num_scales = k // scale_granularity_k
    ref = ref_fp32.to(dtype=cutlass_torch.dtype(transformed_dtype)).reshape(
        m, num_scales, scale_granularity_k, l
    )
    # Get elements with maximum absolute value to compute scaling factors
    a_max = (
        torch.maximum(ref / up_4b, ref / lb_4b)
        if dtype == cutlass.Int4
        else ref / up_4b
    )
    a_scales, _ = torch.max(a_max, dim=2, keepdim=True)
    a_scale_inv = torch.where(a_scales == 0, 0, 1 / a_scales)
    a_quant = ref * a_scale_inv
    # Convert values to integer to avoid computation errors
    a_quant = a_quant.to(dtype=torch.int32).reshape((m, k, l)).to(dtype=torch.float32)
    # Construct cute scale tensor
    a_scales = a_scales.random_(-3, 3).reshape((m, num_scales, l))
    # Scale tensor is always m-major
    a_scales = a_scales.permute(2, 1, 0).contiguous().permute(2, 1, 0).to(device="cuda")
    if shuffle_a:
        # shuffle within each group of 8 elements
        perm = torch.tensor([0, 2, 1, 3, 4, 6, 5, 7], device=a_quant.device)
        a_shuffled = (
            a_quant.view(m, k // 8, 8, l)[:, :, perm, :]
            .reshape(a_quant.shape)
            .permute(2, 0, 1)
            .contiguous()
            .permute(1, 2, 0)
        )
        # Construct A quantized tensor
        cute_a_quant_tensor, torch_a_quant_tensor = cutlass_torch.cute_tensor_like(
            a_shuffled,
            dtype,
            is_dynamic_layout=is_dynamic_layout,
            assumed_align=divisibility,
        )
    else:
        # Construct A quantized tensor
        cute_a_quant_tensor, torch_a_quant_tensor = cutlass_torch.cute_tensor_like(
            a_quant,
            dtype,
            is_dynamic_layout=is_dynamic_layout,
            assumed_align=divisibility,
        )
    cute_scale_tensor = from_dlpack(a_scales, assumed_align=divisibility)
    for i, stride in enumerate(a_scales.stride()):
        if stride == 1:
            leading_dim = i
            break
    if is_dynamic_layout:
        cute_scale_tensor = cute_scale_tensor.mark_layout_dynamic(
            leading_dim=leading_dim
        )

    return (
        cute_a_quant_tensor,
        torch_a_quant_tensor,
        a_quant.to("cpu"),
        cute_scale_tensor,
        a_scales,
        a_scales.to("cpu"),
    )


def create_tensor_a(
    l: int,
    m: int,
    k: int,
    a_major: str,
    a_dtype: type[cutlass.Numeric],
    shuffle_a: bool,
    scale_granularity_m: int = 0,
    scale_granularity_k: int = 0,
    transformed_dtype: Optional[type[cutlass.Numeric]] = None,
) -> tuple[cute.Tensor, Optional[cute.Tensor], torch.Tensor, Optional[torch.Tensor]]:
    """
    Create tensor A and scale tensor.
    """
    a_scale_tensor = None
    a_scale_torch_cpu = None
    if a_dtype in (cutlass.Int4,):
        (
            a_tensor,
            a_torch_gpu,
            a_torch_cpu,
            a_scale_tensor,
            a_scale_torch_gpu,
            a_scale_torch_cpu,
        ) = create_i4_tensor_and_scale(
            l,
            m,
            k,
            a_major == "m",
            a_dtype,
            shuffle_a,
            scale_granularity_m,
            scale_granularity_k,
            divisibility=mixed_input_utils.get_divisibility(m if a_major == "m" else k),
            transformed_dtype=transformed_dtype,
        )
    else:
        a_torch_cpu = cutlass_torch.matrix(
            l,
            m,
            k,
            a_major == "m",
            a_dtype,
        )
        a_tensor, _ = cutlass_torch.cute_tensor_like(
            a_torch_cpu,
            a_dtype,
            is_dynamic_layout=True,
            assumed_align=mixed_input_utils.get_divisibility(
                m if a_major == "m" else k
            ),
        )
    return a_tensor, a_scale_tensor, a_torch_cpu, a_scale_torch_cpu


def create_tensors_for_contiguous_grouped_mixed_input_gemm(
    l: int,
    m: int,
    n: int,
    k: int,
    a_major: str,
    b_major: str,
    c_major: str,
    a_dtype: type[cutlass.Numeric],
    b_dtype: type[cutlass.Numeric],
    c_dtype: type[cutlass.Numeric],
    shuffle_a: bool = False,
    scale_granularity_m: int = 0,
    scale_granularity_k: int = 0,
    uniform_group_sizes: bool = False,
) -> tuple:
    """
    Create all input and output tensors for the contiguous grouped mixed-input GEMM.
    """
    a_tensor, a_scale_tensor, a_torch_cpu, a_scale_torch_cpu = create_tensor_a(
        l,
        m,
        k,
        a_major,
        a_dtype,
        shuffle_a,
        scale_granularity_m,
        scale_granularity_k,
        b_dtype,
    )

    # In GROUP mode, l specifies the number of groups. We'll fuse group into the n mode for tensor B and C.
    # Batch mode will be set to 1.
    num_groups = l
    fused_n = n * num_groups
    b_torch_cpu = cutlass_torch.matrix(
        1,  # batch=1
        fused_n,
        k,
        b_major == "n",
        b_dtype,
        cutlass_torch.TensorInitType.RANDOM,
        cutlass_torch.RandomInitConfig(min_val=-10, max_val=10),
    )
    b_tensor, _ = cutlass_torch.cute_tensor_like(
        b_torch_cpu,
        b_dtype,
        is_dynamic_layout=True,
        assumed_align=mixed_input_utils.get_divisibility(n if b_major == "n" else k),
    )

    c_torch_cpu = cutlass_torch.matrix(
        1,  # batch=1
        m,
        fused_n,
        c_major == "m",
        c_dtype,
    )
    c_tensor, c_torch_gpu = cutlass_torch.cute_tensor_like(
        c_torch_cpu,
        c_dtype,
        is_dynamic_layout=True,
        assumed_align=mixed_input_utils.get_divisibility(m if c_major == "m" else n),
    )
    c_tensor = c_tensor.mark_compact_shape_dynamic(
        mode=(0 if c_major == "m" else 1),
        stride_order=(2, 1, 0) if c_major == "m" else (2, 0, 1),
        divisibility=mixed_input_utils.get_divisibility(m if c_major == "m" else n),
    )
    # We need to ensure mode N satisfies 16B alignment for each group
    alignment_n = 16 * 8 // b_dtype.width
    cumsum_tensor, cumsum_torch = create_cumsum_tensor(
        num_groups, fused_n, alignment_n, uniform_distribution=uniform_group_sizes
    )

    return (
        a_tensor,
        a_scale_tensor,
        b_tensor,
        cumsum_tensor,
        c_tensor,
        a_torch_cpu,
        a_scale_torch_cpu,
        b_torch_cpu,
        cumsum_torch,
        c_torch_gpu,
    )


def create_tensors_for_batched_mixed_input_gemm(
    l: int,
    m: int,
    n: int,
    k: int,
    a_major: str,
    b_major: str,
    c_major: str,
    a_dtype: type[cutlass.Numeric],
    b_dtype: type[cutlass.Numeric],
    c_dtype: type[cutlass.Numeric],
    shuffle_a: bool = False,
    scale_granularity_m: int = 0,
    scale_granularity_k: int = 0,
) -> tuple:
    """
    Create all input and output tensors for the batched mixed-input GEMM.
    """
    torch.manual_seed(2025)

    a_tensor, a_scale_tensor, a_torch_cpu, a_scale_torch_cpu = create_tensor_a(
        l,
        m,
        k,
        a_major,
        a_dtype,
        shuffle_a,
        scale_granularity_m,
        scale_granularity_k,
        b_dtype,
    )

    b_torch_cpu = cutlass_torch.matrix(
        l,
        n,
        k,
        b_major == "n",
        b_dtype,
        cutlass_torch.TensorInitType.RANDOM,
        cutlass_torch.RandomInitConfig(min_val=-10, max_val=10),
    )
    c_torch_cpu = cutlass_torch.matrix(
        l,
        m,
        n,
        c_major == "m",
        c_dtype,
    )

    b_tensor, _ = cutlass_torch.cute_tensor_like(
        b_torch_cpu,
        b_dtype,
        is_dynamic_layout=True,
        assumed_align=mixed_input_utils.get_divisibility(n if b_major == "n" else k),
    )
    c_tensor, c_torch_gpu = cutlass_torch.cute_tensor_like(
        c_torch_cpu,
        c_dtype,
        is_dynamic_layout=True,
        assumed_align=mixed_input_utils.get_divisibility(m if c_major == "m" else n),
    )
    c_tensor = c_tensor.mark_compact_shape_dynamic(
        mode=(0 if c_major == "m" else 1),
        stride_order=(2, 1, 0) if c_major == "m" else (2, 0, 1),
        divisibility=mixed_input_utils.get_divisibility(m if c_major == "m" else n),
    )

    return (
        a_tensor,
        a_scale_tensor,
        b_tensor,
        c_tensor,
        a_torch_cpu,
        a_scale_torch_cpu,
        b_torch_cpu,
        c_torch_gpu,
    )


def run_contiguous_grouped_ref_and_compare(
    a_torch_cpu: torch.Tensor,
    b_torch_cpu: torch.Tensor,
    a_scale_torch_cpu: Optional[torch.Tensor],
    cumsum_torch_cpu: torch.Tensor,
    c_torch_gpu: torch.Tensor,
    c_dtype: type[cutlass.Numeric],
    tolerance: float,
) -> None:
    """
    Compare kernel result with reference computation.
    """
    kernel_result = c_torch_gpu.cpu()
    assert kernel_result.shape[2] == 1, "batch mode must be 1"
    kernel_result = kernel_result.reshape(
        kernel_result.shape[0], kernel_result.shape[1]
    )
    # Compute reference result
    a_for_gemm = a_torch_cpu
    if a_scale_torch_cpu is not None:
        scale_shape = a_scale_torch_cpu.shape
        a_shape = a_torch_cpu.shape
        a_scale_torch_cpu = a_scale_torch_cpu.to(dtype=torch.float32).reshape(
            scale_shape[0], scale_shape[1], 1, scale_shape[2]
        )
        a_torch_cpu = a_torch_cpu.to(dtype=torch.float32).reshape(
            a_torch_cpu.shape[0], scale_shape[1], -1, a_torch_cpu.shape[2]
        )
        a_for_gemm = (a_torch_cpu * a_scale_torch_cpu).reshape(a_shape)
    # A in (m, k, l), b in (n, k), c in (m, n)
    assert cumsum_torch_cpu.shape[0] == a_for_gemm.shape[-1] + 1, (
        "cumsum tensor must have one more element than a_for_gemm"
    )
    assert b_torch_cpu.shape[2] == 1, (
        "b_torch_cpu must have a singleton dimension in the last position"
    )
    prev_idx = 0
    ref = torch.zeros((a_for_gemm.shape[0], b_torch_cpu.shape[0]), dtype=torch.float32)
    for group_idx in range(1, cumsum_torch_cpu.shape[0]):
        # No computation for current group
        if cumsum_torch_cpu[group_idx] == prev_idx:
            continue
        # Get A slice for current group
        sliced_a = a_for_gemm[:, :, group_idx - 1]
        # Get B slice for current group
        sliced_b = b_torch_cpu[prev_idx : cumsum_torch_cpu[group_idx], :, 0]
        sliced_ref = torch.einsum(
            "mk,nk->mn",
            sliced_a.to(dtype=torch.float32),
            sliced_b.to(dtype=torch.float32),
        )
        ref[:, prev_idx : cumsum_torch_cpu[group_idx]] = sliced_ref
        prev_idx = cumsum_torch_cpu[group_idx]
    # Convert ref to c_dtype
    _, ref_torch_gpu = cutlass_torch.cute_tensor_like(
        ref, c_dtype, is_dynamic_layout=True, assumed_align=16
    )
    ref_result = ref_torch_gpu.cpu()

    # Assert close results
    torch.testing.assert_close(kernel_result, ref_result, atol=tolerance, rtol=1e-05)


def run_batched_mixed_input_ref_and_compare(
    a_torch_cpu: torch.Tensor,
    b_torch_cpu: torch.Tensor,
    a_scale_torch_cpu: Optional[torch.Tensor],
    c_torch_gpu: torch.Tensor,
    c_dtype: type[cutlass.Numeric],
    tolerance: float,
) -> None:
    """
    Compare kernel result with reference computation.
    """
    kernel_result = c_torch_gpu.cpu()
    # Compute reference result
    if a_scale_torch_cpu is not None:
        scale_shape = a_scale_torch_cpu.shape
        a_shape = a_torch_cpu.shape
        a_scale_torch_cpu = a_scale_torch_cpu.to(dtype=torch.float32).reshape(
            scale_shape[0], scale_shape[1], 1, scale_shape[2]
        )
        a_torch_cpu = a_torch_cpu.to(dtype=torch.float32).reshape(
            a_torch_cpu.shape[0], scale_shape[1], -1, a_torch_cpu.shape[2]
        )
        a_dequant = a_torch_cpu * a_scale_torch_cpu
        ref = torch.einsum(
            "mkl,nkl->mnl",
            a_dequant.reshape(a_shape),
            b_torch_cpu.to(dtype=torch.float32),
        )
    else:
        ref = torch.einsum(
            "mkl,nkl->mnl",
            a_torch_cpu.to(dtype=torch.float32),
            b_torch_cpu.to(dtype=torch.float32),
        )
    # Convert ref to c_dtype
    _, ref_torch_gpu = cutlass_torch.cute_tensor_like(
        ref, c_dtype, is_dynamic_layout=True, assumed_align=16
    )
    ref_result = ref_torch_gpu.cpu()

    # Assert close results
    torch.testing.assert_close(kernel_result, ref_result, atol=tolerance, rtol=1e-05)
