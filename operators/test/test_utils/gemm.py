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

import torch

import cutlass
import cutlass.torch
from cutlass.utils.gemm.tensor_utils import decode_float4e2m1fn, unpack_scale_factors

import cutlass.operators as ops
from cutlass.operators.utils.common import ceil_div
from cutlass.operators.utils.device import device_or_env_target_sm
from cutlass.operators.utils.dtype import torch_storage_packing_factor

from . import reference_check

################################################################################
# Reference computation
################################################################################


def clamp_to_finite_range(reference: torch.Tensor, dtype: torch.dtype) -> torch.Tensor:
    """
    Clamps the reference tensor to the range of the given dtype if the
    dtype is determined to be a narrow precision dtype.
    """
    if dtype not in reference_check.get_clamp_torch_dtypes():
        return reference
    if dtype.is_floating_point:
        info = torch.finfo(dtype)
    else:
        raise ValueError(f"Unsupported dtype: {dtype}")
    return torch.clamp(reference, max=info.max, min=info.min)


def dense_gemm_reference(
    args: ops.GemmArguments, ref_as_acc_dtype: bool = False
) -> torch.Tensor:
    """
    Computes the reference result for a dense GEMM operation.

    Args:
        args (cutlass.operators.arguments.GemmArguments): The arguments for the GEMM operation
        ref_as_acc_dtype (bool): Option to return reference tensor as accumulator dtype. The default
        behavior is to return the reference tensor as the output dtype.

    Returns:
        The reference result for the GEMM operation
    """
    if not isinstance(args.A, ops.DenseTensor):
        raise ValueError(f"Expected args.A to be a DenseTensor, got {type(args.A)}")
    if not isinstance(args.B, ops.DenseTensor):
        raise ValueError(f"Expected args.B to be a DenseTensor, got {type(args.B)}")
    if not isinstance(args.out, ops.DenseTensor):
        raise ValueError(f"Expected args.out to be a DenseTensor, got {type(args.out)}")

    A_tensor = args.A.tensor.runtime_tensor
    match A_tensor:
        case torch.Tensor():
            B_tensor = args.B.tensor.runtime_tensor
            assert isinstance(B_tensor, torch.Tensor)
            reference = A_tensor.to(torch.float32) @ B_tensor.to(torch.float32)
            if not ref_as_acc_dtype:
                # pytorch and numpy, following the IEEE standard, converts to Inf or NaN
                # but our kernels use satfinite. To make them the same output we have to
                # clamp on narrow precision output dtypes.
                torch_dtype = cutlass.torch.dtype(args.out.dtype)
                reference = clamp_to_finite_range(reference, torch_dtype).to(
                    torch_dtype
                )
            return reference
        case _:
            raise NotImplementedError(f"Unsupported tensor type: {type(A_tensor)}")


def _decode_fp4_packed(tensor: torch.Tensor, pack_dim: int) -> torch.Tensor:
    """Decode a ``float4_e2m1fn_x2`` tensor to float32 via :func:`decode_float4e2m1fn`.

    CuTe DSL's :func:`decode_float4e2m1fn` expects 2x-overallocated ``uint8``
    tensors (one byte per logical element) as produced by
    ``create_gemm_tensor_torch``.  Operator API tests use PyTorch's
    tightly-packed ``float4_e2m1fn_x2`` (two values per byte, ``K_packed =
    K / 2``).  This adapter flattens, pads to the over-allocated size, decodes,
    and reshapes back.
    """
    u8 = tensor.view(torch.uint8)
    ndim = u8.dim()

    if pack_dim != ndim - 1:
        perm = [i for i in range(ndim) if i != pack_dim] + [pack_dim]
        u8 = u8.permute(perm).contiguous()
        inv_perm = [0] * ndim
        for i, p in enumerate(perm):
            inv_perm[p] = i
    else:
        inv_perm = list(range(ndim))

    total = u8.numel()
    padded = torch.zeros(1, 2 * total, 1, dtype=torch.uint8, device=tensor.device)
    padded[0, :total, 0] = u8.flatten()
    decoded = decode_float4e2m1fn(padded).flatten()

    out_shape = list(u8.shape)
    out_shape[-1] *= 2
    return decoded.reshape(out_shape).permute(inv_perm)


def _emulated_scaled_dense_gemm_reference(
    args: ops.GemmArguments,
    ref_as_acc_dtype: bool = False,
) -> torch.Tensor:
    """Emulated block-scaled GEMM reference: dequantize, apply scales, matmul.

    Works for any data type / scale factor combination without relying on
    ``torch._scaled_mm``.  All arithmetic is performed in float32.

    The computation is::

        A_scaled = A_f32 * expand(SFA)   # (L, M, K)
        B_scaled = B_f32 * expand(SFB)   # (L, K, N)
        D        = A_scaled @ B_scaled   # (L, M, N)

    When block-scaled output is needed in the future, a ``scale_out`` parameter
    can be added here without restructuring the computation.
    """
    A = args.A.quantized.tensor.runtime_tensor
    B = args.B.quantized.tensor.runtime_tensor
    scale_A = args.A.scale.tensor.runtime_tensor
    scale_B = args.B.scale.tensor.runtime_tensor
    out_dtype = cutlass.torch.dtype(args.out.dtype)

    M, N = args.out.shape[-2:]
    packing_A = torch_storage_packing_factor(args.A.quantized.dtype)
    K = A.shape[-1] * packing_A
    is_2d = A.dim() == 2
    L = 1 if is_2d else A.shape[0]
    sf_vec_size = ops.ScaleMode.numel(args.A.mode)

    # --- dequantize A and B to float32 ---
    # float4_e2m1fn_x2 is a sub-byte type: .to(float32) triggers a CUDA
    # device-side assert in PyTorch's fetch_and_cast.  Decode via CuTe DSL's
    # decode_float4e2m1fn (adapted for PyTorch's tightly-packed format).
    # Each operand is checked independently to support mixed FP4 x FP8.
    A_f32 = (
        _decode_fp4_packed(A, pack_dim=A.dim() - 1)
        if A.dtype == torch.float4_e2m1fn_x2
        else A.to(torch.float32)
    )
    B_f32 = (
        _decode_fp4_packed(B, pack_dim=B.dim() - 2)
        if B.dtype == torch.float4_e2m1fn_x2
        else B.to(torch.float32)
    )

    if is_2d:
        A_f32 = A_f32.unsqueeze(0)  # (1, M, K)
        B_f32 = B_f32.unsqueeze(0)  # (1, K, N)

    # --- obtain dense scale factors ---
    # unpack_scale_factors inverts the Swizzle32x4x4 layout directly from
    # the scale tensor in args, returning (MN, K, L) float32.
    # Permute to (L, MN, K) to match our (L, M, K) / (L, K, N) convention.
    device = A_f32.device
    sfa_expanded = (
        unpack_scale_factors(scale_A.to(torch.float32), sf_vec_size, M, K, L)
        .to(device)
        .permute(2, 0, 1)[:, :M, :K]
    )  # (L, M, K)
    sfb_expanded = (
        unpack_scale_factors(scale_B.to(torch.float32), sf_vec_size, N, K, L)
        .to(device)
        .permute(2, 0, 1)[:, :N, :K]
    )  # (L, N, K)

    # --- apply scale factors and matmul ---
    A_scaled = A_f32 * sfa_expanded  # (L, M, K)
    B_scaled = B_f32 * sfb_expanded.transpose(1, 2)  # (L, K, N)
    reference = A_scaled @ B_scaled  # (L, M, N)

    if is_2d:
        reference = reference.squeeze(0)

    if not ref_as_acc_dtype:
        reference = clamp_to_finite_range(reference, out_dtype).to(out_dtype)

    return reference


def scaled_dense_gemm_reference(
    args: ops.GemmArguments, ref_as_acc_dtype: bool = False
) -> torch.Tensor:
    """
    Computes the reference result for a scaled dense GEMM operation.

    Args:
        args (cutlass.operators.arguments.GemmArguments): The arguments for the GEMM operation
        ref_as_acc_dtype (bool): Option to return reference tensor as accumulator dtype. The default
        behavior is to return the reference tensor as the output dtype.

    Returns:
        The reference result for the scaled dense GEMM operation
    """

    if not isinstance(args.A, ops.ScaledOperand):
        raise ValueError(f"Expected args.A to be a ScaledOperand, got {type(args.A)}")
    if not isinstance(args.B, ops.ScaledOperand):
        raise ValueError(f"Expected args.B to be a ScaledOperand, got {type(args.B)}")
    if not isinstance(args.out, ops.DenseTensor):
        raise ValueError(f"Expected args.out to be a DenseTensor, got {type(args.out)}")
    if not isinstance(args.A.scale, ops.DenseTensor):
        raise ValueError(
            f"Expected args.A.scale to be a DenseTensor, got {type(args.A.scale)}"
        )
    if not isinstance(args.B.scale, ops.DenseTensor):
        raise ValueError(
            f"Expected args.B.scale to be a DenseTensor, got {type(args.B.scale)}"
        )

    A = args.A.quantized.tensor.runtime_tensor
    B = args.B.quantized.tensor.runtime_tensor
    scale_A = args.A.scale.tensor.runtime_tensor
    scale_B = args.B.scale.tensor.runtime_tensor
    acc_dtype = cutlass.torch.dtype(args.accumulator_type)
    out_dtype = cutlass.torch.dtype(args.out.dtype)

    if not isinstance(A, torch.Tensor):
        raise NotImplementedError(f"Unsupported tensor type: {type(A)}")
    if not isinstance(B, torch.Tensor):
        raise NotImplementedError(f"Unsupported tensor type: {type(B)}")
    if not isinstance(scale_A, torch.Tensor):
        raise NotImplementedError(f"Unsupported tensor type: {type(scale_A)}")
    if not isinstance(scale_B, torch.Tensor):
        raise NotImplementedError(f"Unsupported tensor type: {type(scale_B)}")
    if not isinstance(out_dtype, torch.dtype):
        raise NotImplementedError(f"Unsupported dtype type: {type(out_dtype)}")

    # torch._scaled_mm supports FP4 only with Float8E4M3FN scale factors
    # (matching CuTe DSL's is_emulated_dtype).  Configs torch can't handle (e.g.
    # FP4 + Float8E8M0FNU, mixed FP4 x FP8) use the emulated reference, which
    # supports 2D/3D operands and arbitrary N -- returning here avoids the 3D-only
    # N-padding below.  Each operand is checked independently for mixed configs.
    use_emulated = (
        A.dtype == torch.float4_e2m1fn_x2 and scale_A.dtype != torch.float8_e4m3fn
    ) or (B.dtype == torch.float4_e2m1fn_x2 and scale_B.dtype != torch.float8_e4m3fn)
    if use_emulated:
        return _emulated_scaled_dense_gemm_reference(args, ref_as_acc_dtype)

    # torch._scaled_mm currently requires K and N to be divisible by 16.
    # Given that torch also only supports TN layout for now, and data types are
    # FP8 or smaller, K divisibility >= (alignment_bytes * 8 // dtype.width) = (16 * 8 // 8) = 16.
    # Thus, we only need to pad N. (Operands here are 3D.)
    N = B.shape[-1]
    padded_N = ceil_div(N, 16) * 16
    if padded_N != N:
        N_pad = padded_N - N
        if B.dtype == torch.float4_e2m1fn_x2:
            # Packed FP4: pad at byte level since float32 round-trip changes shape.
            # float4_e2m1fn_x2 and int8 share 1-byte element size, so view is safe.
            B_padded = torch.zeros(
                (B.shape[0], B.shape[1], padded_N),
                dtype=torch.int8,
                device=B.device,
            )
            B_padded[:, :, :N] = B.view(dtype=torch.int8)
            B_padded = B_padded.view(dtype=torch.float4_e2m1fn_x2)
        else:
            B_padded = (
                torch.nn.functional.pad(
                    B.transpose(1, 2).to(torch.float32),
                    (0, 0, 0, N_pad),
                    mode="constant",
                    value=0,
                )
                .to(B.dtype)
                .transpose(1, 2)
            )
    else:
        B_padded = B

    # torch._scaled_mm does not support batch mode. Iterate through each
    # problem in the batch.
    L, M, N = A.shape[0], A.shape[1], B.shape[2]
    scale_A = scale_A.view(L, -1).contiguous()
    scale_B = scale_B.view(L, -1).contiguous()
    reference = torch.empty((L, M, padded_N), device=A.device, dtype=acc_dtype)

    for l_idx in range(L):
        # Use out type of F32 and then convert to out_dtype due to cuBLAS
        # errors occasionally thrown with F8 types.
        # See https://github.com/pytorch/pytorch/issues/160816
        try:
            reference[l_idx, :, :] = torch._scaled_mm(
                A[l_idx, :, :],
                B_padded[l_idx, :, :],
                scale_a=scale_A[l_idx, :],
                scale_b=scale_B[l_idx, :],
                out_dtype=acc_dtype,
            )
        except RuntimeError:
            # cuBLAS may not have an algorithm for this configuration;
            # fall back to emulated reference.
            return _emulated_scaled_dense_gemm_reference(args, ref_as_acc_dtype)

    if not ref_as_acc_dtype:
        reference = clamp_to_finite_range(reference, out_dtype).to(out_dtype)

    # Remove padding from reference
    reference = reference[:, :, :N]

    return reference


def reference(args: ops.GemmArguments, ref_as_acc_dtype: bool = False) -> torch.Tensor:
    """
    Computes the reference result for a GEMM operation.

    Args:
        args (cutlass.operators.arguments.GemmArguments): The arguments for the GEMM operation
        ref_as_acc_dtype (bool): Option to return reference tensor as accumulator dtype. The default
        behavior is to return the reference tensor as the output dtype.

    Returns:
        The reference result for the GEMM operation
    """
    if (
        isinstance(args.A, ops.DenseTensor)
        and isinstance(args.B, ops.DenseTensor)
        and isinstance(args.out, ops.DenseTensor)
    ):
        return dense_gemm_reference(args, ref_as_acc_dtype=ref_as_acc_dtype)
    elif (
        isinstance(args.A, ops.ScaledOperand)
        and isinstance(args.B, ops.ScaledOperand)
        and isinstance(args.out, ops.DenseTensor)
    ):
        return scaled_dense_gemm_reference(args, ref_as_acc_dtype=ref_as_acc_dtype)
    else:
        raise ValueError(f"No reference implementation found for {args}")


# Byte patterns whose two FP4 (E2M1) nibbles each decode to a small integer in
# {0, +1, -1} (0x0 -> 0.0, 0x2 -> 1.0, 0xA -> -1.0).
_FP4_INT_BYTE_PATTERNS = [0x00, 0x02, 0x0A, 0x20, 0x22, 0x2A, 0xA0, 0xA2, 0xAA]


def make_mxfp4_kmajor(rows: int, k: int) -> torch.Tensor:
    """Build a K-major, tightly-packed MXFP4 operand with integer values in {-1, 0, 1}.

    Returns a ``(rows, k // 2)`` ``torch.float4_e2m1fn_x2`` CUDA tensor (logical
    ``(rows, k)``, K-major). With integer operands and power-of-two scales (see
    make_random_pow2_scale every dequantized product and partial sum is
    an exact integer in float32, so the kernel and scaled_dense_gemm_reference
    accumulate bit-identically.

    Args:
        rows (int): The non-K (M or N) dimension size.
        k (int): The K dimension size.

    Raises:
        ValueError: If ``k`` is odd.
    """
    if k % 2 != 0:
        raise ValueError(f"K must be even to tightly pack FP4, got {k}")
    patterns = torch.tensor(_FP4_INT_BYTE_PATTERNS, dtype=torch.uint8, device="cuda")
    idx = torch.randint(0, patterns.numel(), (rows, k // 2), device="cuda")
    return patterns[idx].view(torch.float4_e2m1fn_x2)


def make_random_pow2_scale(numel: int) -> torch.Tensor:
    """Random E8M0 scale factors drawn from the powers of two ``{1, 2, 4}``.

    Power-of-two scales have no fractional bits, so scaling integer operands keeps
    every product and partial sum an exact integer in float32. Accumulation is
    then order-independent.
    """
    lut = torch.tensor([1.0, 2.0, 4.0], device="cuda")
    idx = torch.randint(0, lut.numel(), (numel,), device="cuda")
    return lut[idx].to(torch.float8_e8m0fnu)
