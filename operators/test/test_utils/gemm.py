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
import cutlass.cute as cute
import cutlass.torch
from cutlass.utils.gemm.tensor_utils import decode_float4e2m1fn, unpack_scale_factors

import cutlass.operators as ops
from cutlass.operators.utils.common import ceil_div
from cutlass.operators.utils.dtype import torch_storage_packing_factor

from .common import reference_device

################################################################################
# Reference computation
################################################################################


def _get_clamp_torch_dtypes() -> set[torch.dtype]:
    """Get the torch dtypes that use satfinite conversion in CUTLASS."""
    return {
        torch.float8_e4m3fn,
        torch.float8_e5m2,
    }


def clamp_to_finite_range(reference: torch.Tensor, dtype: torch.dtype) -> torch.Tensor:
    """Clamp tensor to the finite range of dtype for satfinite output types."""
    if dtype not in _get_clamp_torch_dtypes():
        return reference
    if not dtype.is_floating_point:
        raise ValueError(f"Unsupported dtype: {dtype}")
    info = torch.finfo(dtype)
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
            device = reference_device()
            reference = A_tensor.to(device).to(torch.float32) @ B_tensor.to(device).to(
                torch.float32
            )
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


def _decode_float_nv8e5m3fnu(u8: torch.Tensor) -> torch.Tensor:
    """Decode ``FloatNV8E5M3FNU`` bytes to float32.

    UE5M3 is an 8-bit unsigned format: 5-bit exponent (bias 15) and 3-bit
    mantissa.  Normal values are ``2^(exp-15) * (1 + mant/8)``.  This is the
    format used for NVFP4 scale factors that have no torch dtype.
    """
    bits = u8.to(torch.int32)
    exp = bits >> 3
    mant = bits & 7
    return torch.ldexp(1.0 + mant.to(torch.float32) / 8.0, exp - 15)


def _cute_storage_as_uint8(scale: cute.Tensor) -> torch.Tensor:
    """Copy the raw device bytes backing a CuTe tensor into a uint8 tensor."""
    from cuda.bindings import runtime as cudart

    shape = tuple(int(x) for x in scale.shape)
    out = torch.empty(shape, dtype=torch.uint8, device="cuda")
    (status,) = cudart.cudaMemcpy(
        out.data_ptr(),
        int(scale.iterator._pointer),
        out.numel(),
        cudart.cudaMemcpyKind.cudaMemcpyDeviceToDevice,
    )
    if status != cudart.cudaError_t.cudaSuccess:
        raise RuntimeError(f"cudaMemcpy failed while reading scale factors: {status}")
    return out


def _scale_runtime_as_f32(scale, device: torch.device) -> torch.Tensor:
    """Convert a scale runtime tensor to float32 on ``device`` for the reference.

    Torch-native SF dtypes (e.g. ``float8_e8m0fnu``) convert with ``.to(f32)``.
    ``FloatNV8E5M3FNU`` has no torch dtype and ``cute.testing.convert`` leaves
    the destination zeroed for it, so decode its bytes directly.  Remaining
    CuTe SF tensors go through ``cute.testing.convert``.
    """
    if isinstance(scale, torch.Tensor):
        return scale.to(device).to(torch.float32)

    if scale.element_type is cutlass.FloatNV8E5M3FNU:
        return _decode_float_nv8e5m3fnu(_cute_storage_as_uint8(scale).to(device))

    # The destination cute view must wrap the CUDA tensor that is returned;
    # building it from a host copy leaves the device buffer untouched.
    shape = tuple(int(x) for x in scale.shape)
    f32 = torch.zeros(shape, dtype=torch.float32, device="cuda")
    f32_cute, _ = cutlass.torch.cute_tensor_like(
        f32, cutlass.Float32, True, assumed_align=16
    )
    cute.testing.convert(scale, f32_cute)
    return f32.to(device)


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

    # Everything below runs on `device`, so move the operands there first.
    # Sub-byte and 8-bit dtypes copy across devices fine (it is a memcpy); it is
    # the *casts* that are unimplemented on CPU for float4_e2m1fn_x2, which the
    # _decode_fp4_packed branch below already avoids.
    device = reference_device()
    A = A.to(device)
    B = B.to(device)
    scale_A = _scale_runtime_as_f32(args.A.scale.tensor.runtime_tensor, device)
    scale_B = _scale_runtime_as_f32(args.B.scale.tensor.runtime_tensor, device)
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
    # unpack_scale_factors builds its index on scale_A/scale_B's device, which
    # _scale_runtime_as_f32 has already put on `device`.
    sfa_expanded = unpack_scale_factors(scale_A, sf_vec_size, M, K, L).permute(2, 0, 1)[
        :, :M, :K
    ]  # (L, M, K)
    sfb_expanded = unpack_scale_factors(scale_B, sf_vec_size, N, K, L).permute(2, 0, 1)[
        :, :N, :K
    ]  # (L, N, K)

    # --- apply scale factors and matmul ---
    A_scaled = A_f32 * sfa_expanded  # (L, M, K)
    B_scaled = B_f32 * sfb_expanded.transpose(1, 2)  # (L, K, N)
    reference = A_scaled @ B_scaled  # (L, M, N)

    if is_2d:
        reference = reference.squeeze(0)

    if not ref_as_acc_dtype:
        reference = clamp_to_finite_range(reference, out_dtype).to(out_dtype)

    return reference


def needs_emulated_scaled_reference(
    a_dtype: torch.dtype,
    b_dtype: torch.dtype,
    scale_a_dtype: torch.dtype,
    scale_b_dtype: torch.dtype,
    sf_vec_size: int,
) -> bool:
    """Return whether a block-scaled config must bypass ``torch._scaled_mm``.

    ``torch._scaled_mm`` covers only a few fixed quantization schemes. For
    anything outside them it either raises or silently returns a wrong result.
    This predicate rejects such known configs, for which emulated float32 reference
    should be used instead.

    Args:
        a_dtype (torch.dtype): Storage dtype of the quantized A operand.
        b_dtype (torch.dtype): Storage dtype of the quantized B operand.
        scale_a_dtype (torch.dtype): Dtype of A's scale factors.
        scale_b_dtype (torch.dtype): Dtype of B's scale factors.
        sf_vec_size (int): Quantized elements covered by one scale factor.

    Returns:
        bool: ``True`` if the emulated reference must be used.
    """
    fp4 = torch.float4_e2m1fn_x2
    e4m3 = torch.float8_e4m3fn

    # torch._scaled_mm rejects E5M2 x E5M2
    if a_dtype == torch.float8_e5m2 and b_dtype == torch.float8_e5m2:
        return True

    # torch._scaled_mm supports FP4 only with Float8E4M3FN scale factors
    # (matching CuTe DSL's is_emulated_dtype)
    if a_dtype == fp4 and scale_a_dtype != e4m3:
        return True
    if b_dtype == fp4 and scale_b_dtype != e4m3:
        return True

    # torch._scaled_mm assumes vec size 16 for FP4 with E4M3 scale factors
    # leading to wrong answer for vec size 32
    if (a_dtype == fp4 or b_dtype == fp4) and sf_vec_size != 16:
        return True

    return False


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

    # Emulate when the scales are not torch tensors (SF dtypes with no torch
    # storage, e.g. FloatNV8E5M3FNU), which torch._scaled_mm cannot take.
    #
    # This determines *how* reference is computed. reference_device() determines
    # *where* (on which device) reference is computed.
    if not isinstance(scale_A, torch.Tensor) or not isinstance(scale_B, torch.Tensor):
        return _emulated_scaled_dense_gemm_reference(args, ref_as_acc_dtype)

    if not isinstance(A, torch.Tensor):
        raise NotImplementedError(f"Unsupported tensor type: {type(A)}")
    if not isinstance(B, torch.Tensor):
        raise NotImplementedError(f"Unsupported tensor type: {type(B)}")
    if not isinstance(out_dtype, torch.dtype):
        raise NotImplementedError(f"Unsupported dtype type: {type(out_dtype)}")

    # Configs torch can't handle use the emulated reference, which supports
    # 2D/3D operands and arbitrary N -- returning here avoids the 3D-only
    # N-padding below.  Each operand is checked independently for mixed configs.
    if needs_emulated_scaled_reference(
        A.dtype,
        B.dtype,
        scale_A.dtype,
        scale_B.dtype,
        ops.ScaleMode.numel(args.A.mode),
    ):
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

    # Use out type of F32 and then convert to out_dtype due to cuBLAS
    # errors occasionally thrown with F8 types.
    # See https://github.com/pytorch/pytorch/issues/160816
    try:
        for l_idx in range(L):
            reference[l_idx, :, :] = torch._scaled_mm(
                A[l_idx, :, :],
                B_padded[l_idx, :, :],
                scale_a=scale_A[l_idx, :],
                scale_b=scale_B[l_idx, :],
                out_dtype=acc_dtype,
            )
    except (RuntimeError, ValueError):
        # torch cannot compute this configuration: cuBLAS may have no algorithm
        # for it (RuntimeError), and torch CPU rejects blockwise scaling (ValueError)
        # Either way, use the emulated path if torch failed.
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
    make_random_pow2_scale) every dequantized product and partial sum is an exact
    integer in float32, so the kernel and scaled_dense_gemm_reference accumulate
    bit-identically.

    Args:
        rows (int): The non-K (M or N) dimension size.
        k (int): The K dimension size.

    Raises:
        ValueError: If ``k`` is odd.
    """
    if k % 2 != 0:
        raise ValueError(f"K must be even to tightly pack FP4, got {k}")
    device = reference_device()
    patterns = torch.tensor(_FP4_INT_BYTE_PATTERNS, dtype=torch.uint8, device=device)
    idx = torch.randint(0, patterns.numel(), (rows, k // 2), device=device)
    return patterns[idx].view(torch.float4_e2m1fn_x2).cuda()


def make_random_pow2_scale(numel: int) -> torch.Tensor:
    """Random E8M0 scale factors drawn from the powers of two ``{1, 2, 4}``.

    Power-of-two scales have no fractional bits, so scaling integer operands keeps
    every product and partial sum an exact integer in float32. Accumulation is
    then order-independent.
    """
    device = reference_device()
    lut = torch.tensor([1.0, 2.0, 4.0], device=device)
    idx = torch.randint(0, lut.numel(), (numel,), device=device)
    return lut[idx].to(torch.float8_e8m0fnu).cuda()


# UNPACK_U8 FP6 metadata requires ptr_alignment_bytes =
# (128 elems * 6 bits) // 8 = 96. Default CUDA allocations are typically
# 256B-aligned, and 256 % 96 != 0, so naive buffers fail the Operator API
# pointer-alignment check intermittently.
_FP6_PTR_ALIGNMENT_BYTES = 96


def _aligned_uint8_like(ref: torch.Tensor, alignment: int) -> torch.Tensor:
    """Allocate a ``uint8`` tensor matching ``ref``'s shape/strides with aligned ptr.

    Args:
        ref (torch.Tensor): Layout template (shape and stride).
        alignment (int): Required ``data_ptr() % alignment == 0``.

    Returns:
        torch.Tensor: A ``uint8`` view with the same shape/strides as ``ref``.
    """
    shape = tuple(ref.shape)
    stride = tuple(ref.stride())
    if ref.numel() == 0:
        return torch.empty_like(ref, dtype=torch.uint8)

    # Storage span of a strided tensor is 1 + sum((size_i - 1) * stride_i),
    # not the max over dimensions (that under-allocates multi-dim layouts).
    span = 1 + sum((size - 1) * st for size, st in zip(shape, stride) if size > 0)
    buf = torch.empty(span + alignment, dtype=torch.uint8, device=ref.device)
    offset = (-buf.data_ptr()) % alignment
    view = torch.as_strided(buf, size=shape, stride=stride, storage_offset=offset)
    assert view.data_ptr() % alignment == 0, (
        f"Failed to produce {alignment}B-aligned pointer, got {view.data_ptr()}"
    )
    return view


def make_mxfp6_cute_kmajor(
    rows: int,
    k: int,
    dtype: type[cutlass.Numeric],
    *,
    as_b: bool = False,
) -> tuple[cute.Tensor, torch.Tensor]:
    """Build a K-major MXFP6 CuTe tensor from small-integer float32 values.

    PyTorch has no native FP6 dtype, so Operator API tests allocate via a
    ``uint8`` carrier tagged as ``Float6E2M3FN`` / ``Float6E3M2FN`` and convert
    with :func:`cutlass.torch.convert_cute_tensor`. TVM-FFI is disabled because
    packed FP6x4 is rejected by the ABI.

    The storage pointer is forced to :data:`_FP6_PTR_ALIGNMENT_BYTES` (96)
    alignment so it satisfies Operator API UNPACK_U8 FP6 metadata checks.

    Returns the CuTe tensor together with the float32 source used for the
    emulated reference. Values are drawn from ``{-1, 0, 1}``, which are exactly
    representable in both FP6 encodings.

    Args:
        rows (int): The non-K (M or N) dimension size.
        k (int): The K dimension size.
        dtype (type[cutlass.Numeric]): ``Float6E2M3FN`` or ``Float6E3M2FN``.
        as_b (bool): If True, return a ``(k, rows)`` / ``(K, N)`` K-major
            layout for the B operand; otherwise ``(rows, k)`` / ``(M, K)`` for A.

    Returns:
        tuple: ``(cute_tensor, f32_source)`` with matching logical layout.
    """
    import cutlass.torch as cutlass_torch
    from cutlass.cute.runtime import from_dlpack

    if dtype not in {cutlass.Float6E2M3FN, cutlass.Float6E3M2FN}:
        raise ValueError(f"Expected an FP6 dtype, got {dtype}")

    f32 = torch.randint(-1, 2, (rows, k), device="cuda").to(torch.float32)
    if as_b:
        # (K, N) with unit stride on K.
        f32 = f32.transpose(0, 1)

    storage = _aligned_uint8_like(f32, _FP6_PTR_ALIGNMENT_BYTES)
    cute_tensor = from_dlpack(
        storage,
        assumed_align=_FP6_PTR_ALIGNMENT_BYTES,
        enable_tvm_ffi=False,
    )
    cute_tensor.element_type = dtype
    cute_tensor = cute_tensor.mark_layout_dynamic(
        leading_dim=cutlass_torch.get_leading_dim(storage)
    )
    cute_tensor = cutlass_torch.convert_cute_tensor(
        f32,
        cute_tensor,
        dtype,
        is_dynamic_layout=True,
        enable_tvm_ffi=False,
    )
    return cute_tensor, f32


def make_mxfp6_cute_batched_kmajor(
    L: int,
    rows: int,
    k: int,
    dtype: type[cutlass.Numeric],
    *,
    as_b: bool = False,
) -> tuple[cute.Tensor, torch.Tensor]:
    """Build a batched K-major MXFP6 CuTe tensor ``(L, rows, k)`` or ``(L, k, rows)``.

    Same alignment/conversion rules as :func:`make_mxfp6_cute_kmajor`.
    """
    import cutlass.torch as cutlass_torch
    from cutlass.cute.runtime import from_dlpack

    if dtype not in {cutlass.Float6E2M3FN, cutlass.Float6E3M2FN}:
        raise ValueError(f"Expected an FP6 dtype, got {dtype}")

    f32 = torch.randint(-1, 2, (L, rows, k), device="cuda").to(torch.float32)
    if as_b:
        f32 = f32.transpose(1, 2)  # (L, K, N), K-major

    storage = _aligned_uint8_like(f32, _FP6_PTR_ALIGNMENT_BYTES)
    cute_tensor = from_dlpack(
        storage,
        assumed_align=_FP6_PTR_ALIGNMENT_BYTES,
        enable_tvm_ffi=False,
    )
    cute_tensor.element_type = dtype
    cute_tensor = cute_tensor.mark_layout_dynamic(
        leading_dim=cutlass_torch.get_leading_dim(storage)
    )
    cute_tensor = cutlass_torch.convert_cute_tensor(
        f32,
        cute_tensor,
        dtype,
        is_dynamic_layout=True,
        enable_tvm_ffi=False,
    )
    return cute_tensor, f32


def scaled_dense_gemm_reference_from_f32(
    a_f32: torch.Tensor,
    b_f32: torch.Tensor,
    scale_a: torch.Tensor,
    scale_b: torch.Tensor,
    sf_vec_size: int,
    out_dtype: torch.dtype | None = None,
    ref_as_acc_dtype: bool = False,
) -> torch.Tensor:
    """Emulated block-scaled GEMM reference from retained float32 sources.

    Used when operands are CuTe tensors (e.g. FP6) that cannot be decoded back
    through torch. The float32 sources must already match the values that were
    converted into the CuTe operands.

    ``a_f32`` is ``(M, K)`` or ``(L, M, K)``; ``b_f32`` is ``(K, N)`` or
    ``(L, K, N)``. Scale tensors are the packed Swizzle32x4x4 buffers from args.
    """
    is_2d = a_f32.dim() == 2
    if is_2d:
        a_f32 = a_f32.unsqueeze(0)
        b_f32 = b_f32.unsqueeze(0)

    L, M, K = a_f32.shape
    N = b_f32.shape[-1]

    device = reference_device()
    a_f32 = a_f32.to(device)
    b_f32 = b_f32.to(device)

    sfa_expanded = unpack_scale_factors(
        scale_a.to(device).to(torch.float32), sf_vec_size, M, K, L
    ).permute(2, 0, 1)[:, :M, :K]
    sfb_expanded = unpack_scale_factors(
        scale_b.to(device).to(torch.float32), sf_vec_size, N, K, L
    ).permute(2, 0, 1)[:, :N, :K]

    reference = (a_f32 * sfa_expanded) @ (b_f32 * sfb_expanded.transpose(1, 2))

    if is_2d:
        reference = reference.squeeze(0)

    if not ref_as_acc_dtype:
        if out_dtype is None:
            raise ValueError("out_dtype is required when ref_as_acc_dtype is False")
        reference = clamp_to_finite_range(reference, out_dtype).to(out_dtype)

    return reference
