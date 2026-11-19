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

"""Performance metrics and verification for CUTLASS profiler.

This module provides post-execution analysis:
- PerfMetrics: operation-independent throughput and bandwidth metrics
- Correctness verification against PyTorch reference
"""

from __future__ import annotations

from dataclasses import dataclass

import torch

from cutlass.utils.gemm.tensor_utils import decode_float4e2m1fn, unpack_scale_factors

import cutlass.operators as ops
from cutlass.operators.utils.common import ceil_div
from cutlass.operators.utils.dtype import torch_type_from_cutlass_type


def get_clamp_torch_dtypes():
    """Get the torch dtypes that will be clamped under ClampOnRestrictedDtypes."""
    clamp_torch_dtypes = {
        torch.float8_e4m3fn,
        torch.float8_e5m2,
    }
    return clamp_torch_dtypes


def clamp_to_finite_range(reference: torch.Tensor, dtype: torch.dtype) -> torch.Tensor:
    """Clamp tensor to the finite range of dtype (for satfinite output types)."""
    if dtype not in get_clamp_torch_dtypes():
        return reference
    if not dtype.is_floating_point:
        raise ValueError(f"Unsupported dtype: {dtype}")
    info = torch.finfo(dtype)
    return torch.clamp(reference, max=info.max, min=info.min)


# =============================================================================
# Performance Metrics
# =============================================================================


@dataclass
class PerfMetrics:
    """Performance metrics for a generic operation.

    This class encapsulates the metrics data and the formulas used to
    compute them.
    """

    operator_runtime_ms: float  # average operator time per iteration in milliseconds
    flop_count: int  # floating-point operations performed, not a rate
    total_bytes: int  # total bytes transferred

    @classmethod
    def from_workload(
        cls, operator_runtime_ms: float, flop_count: int, total_bytes: int
    ) -> PerfMetrics:
        """Create metrics from an exact FLOP count and storage footprint."""
        if operator_runtime_ms < 0:
            raise ValueError("operator_runtime_ms must be non-negative")
        if flop_count < 0:
            raise ValueError("flop_count must be non-negative")
        if total_bytes < 0:
            raise ValueError("total_bytes must be non-negative")
        return cls(
            operator_runtime_ms=operator_runtime_ms,
            flop_count=flop_count,
            total_bytes=total_bytes,
        )

    @staticmethod
    def _flop_per_second(flop_count: int, operator_runtime_ms: float) -> float:
        """Return the floating-point operations executed per second."""
        if operator_runtime_ms < 0:
            raise ValueError("operator_runtime_ms must be non-negative")
        if operator_runtime_ms == 0:
            return 0.0
        return flop_count / (operator_runtime_ms * 1e-3)

    @staticmethod
    def _bandwidth(num_bytes: int, operator_runtime_ms: float) -> tuple[float, float]:
        """Calculate memory bandwidth in GB/s and GiB/s."""
        if operator_runtime_ms < 0:
            raise ValueError("operator_runtime_ms must be non-negative")
        if operator_runtime_ms == 0:
            return (0.0, 0.0)

        time_seconds = operator_runtime_ms * 1e-3
        bandwidth_gb_per_sec = num_bytes / time_seconds / 1e9
        bandwidth_gib_per_sec = num_bytes / time_seconds / (1024**3)
        return (bandwidth_gb_per_sec, bandwidth_gib_per_sec)

    @property
    def tflop_per_sec(self) -> float:
        """Compute throughput in TFLOP/s (tera floating-point ops per second)."""
        flop_per_second = self._flop_per_second(
            self.flop_count, self.operator_runtime_ms
        )
        return flop_per_second / 1e12

    @property
    def flop_per_byte(self) -> float:
        """Arithmetic intensity: FLOPs executed per byte transferred."""
        if self.total_bytes == 0:
            return float("inf")
        return self.flop_count / self.total_bytes

    @property
    def bandwidth_gb_per_sec(self) -> float:
        """Memory bandwidth in GB/s (decimal, 10^9 bytes per second)."""
        bandwidth_gb_per_sec, _ = self._bandwidth(
            self.total_bytes, self.operator_runtime_ms
        )
        return bandwidth_gb_per_sec

    @property
    def bandwidth_gib_per_sec(self) -> float:
        """Memory bandwidth in GiB/s (binary, 2^30 bytes per second)."""
        _, bandwidth_gib_per_sec = self._bandwidth(
            self.total_bytes, self.operator_runtime_ms
        )
        return bandwidth_gib_per_sec


# =============================================================================
# Verification
# =============================================================================


@dataclass(frozen=True)
class ReferenceTolerances:
    """Recommended ``(atol, rtol)`` for reference-checking a result."""

    atol: float
    rtol: float


# Below this K, accumulation error is negligible under the low-variance integer
# initialization the profiler uses by default (see operand_factory's "auto"
# mode), so the comparison can be exact.
_K_TOLERANCE_THRESHOLD = 512
# rtol at K == _K_TOLERANCE_THRESHOLD for an fp16 accumulator. Chosen to sit
# close to fp16's own ULP (~9.8e-4).
_BASE_RTOL = 0.001
# Tuned so an fp16 accumulator reaches rtol ~0.005 at K ~1500:
# 0.001 * (1500/512)**1.5 ~= 0.00501.
_RTOL_GROWTH_EXPONENT = 1.5


def reference_tolerances(accumulator_type, k: int) -> ReferenceTolerances:
    """Recommend reference-check tolerances from the accumulator dtype and K.

    Accumulation error grows with the number of terms summed along K and with
    the accumulator's ULP, so a single fixed tolerance is either too loose to
    catch real errors on small problems or too tight on large ones.

    Integer accumulators are exact. For float accumulators, K below
    ``_K_TOLERANCE_THRESHOLD`` is exact under low-variance integer inputs;
    above it, rtol scales with K and with the accumulator's ULP relative to
    fp16's. atol stays 0.0 throughout: the error being modelled is
    proportional to the magnitude being accumulated.

    :param accumulator_type: CUTLASS accumulator numeric type.
    :param k: Contraction extent. For grouped problems, the largest per-group K.

    :return: Recommended tolerances.
    :rtype: ReferenceTolerances
    """
    if k < 0:
        raise ValueError(f"k must be non-negative, got {k}")

    torch_dtype = torch_type_from_cutlass_type(accumulator_type)
    # torch has no is_integer, so identify integers by elimination.
    if not torch_dtype.is_floating_point and not torch_dtype.is_complex:
        return ReferenceTolerances(atol=0.0, rtol=0.0)
    if not torch_dtype.is_floating_point:
        raise ValueError(f"Unsupported accumulator dtype: {torch_dtype}")

    if k < _K_TOLERANCE_THRESHOLD:
        return ReferenceTolerances(atol=0.0, rtol=0.0)

    ulp = torch.finfo(torch_dtype).eps
    fp16_ulp = torch.finfo(torch.float16).eps
    rtol = (
        _BASE_RTOL
        * (ulp / fp16_ulp)
        * (k / _K_TOLERANCE_THRESHOLD) ** _RTOL_GROWTH_EXPONENT
    )
    return ReferenceTolerances(atol=0.0, rtol=rtol)


def gemm_reference_tolerances(args: ops.GemmArguments) -> ReferenceTolerances:
    """Recommend tolerances for a dense or scaled GEMM problem."""
    return reference_tolerances(args.accumulator_type, args.problem_size.K)


def grouped_gemm_reference_tolerances(
    args: ops.IndexPtrGroupedGemmArguments,
) -> ReferenceTolerances:
    """Recommend tolerances for a contiguous-offset grouped GEMM problem.

    Uses the largest per-group K, so the tolerance covers the group that
    accumulates the most terms.
    """
    return reference_tolerances(args.accumulator_type, _grouped_gemm_max_k(args))


def _grouped_gemm_max_k(args: ops.IndexPtrGroupedGemmArguments) -> int:
    """Return the largest per-group contraction extent.

    Only K-offset problems vary K per group; for M- and N-offset problems every
    group shares A's trailing extent.
    """
    if args.offsets_along != "k":
        return int(args.A.shape[-1])

    offsets = args.offsets.tensor.runtime_tensor
    boundaries = [int(value) for value in offsets.detach().cpu().tolist()]
    extents = [end - start for start, end in zip([0, *boundaries], boundaries)]
    return max(extents, default=0)


@dataclass
class VerificationResult:
    """Result of verification against reference implementation."""

    passed: bool  # whether verification passed
    max_abs_error: float  # maximum absolute error
    max_rel_error: float  # maximum relative error
    error_message: str | None = None  # error details if failed


def compute_reference_gemm(
    A: torch.Tensor,
    B: torch.Tensor,
    accumulator_dtype: torch.dtype,
    out_dtype: torch.dtype,
    use_cpu: bool = False,
) -> torch.Tensor:
    """Compute reference GEMM using PyTorch.

    Performs matrix multiplication in higher precision for accurate reference values,
    then converts to the output dtype.

    :param A: Input matrix A
    :type A: torch.Tensor
    :param B: Input matrix B
    :type B: torch.Tensor
    :param accumulator_dtype: Data type for accumulation.
    :type accumulator_dtype: torch.dtype
    :param out_dtype: Output data type.
    :type out_dtype: torch.dtype
    :param use_cpu: Whether to force CPU computation. Useful for NCU trace mode. Defaults to False.
    :type use_cpu: bool

    :return: Reference output tensor
    :rtype: torch.Tensor
    """
    # move to cpu if requested
    if use_cpu:
        A = A.cpu()
        B = B.cpu()

    # accumulate in higher precision
    A_acc = A.to(accumulator_dtype)
    B_acc = B.to(accumulator_dtype)

    result = torch.matmul(A_acc, B_acc)

    # convert to output dtype (may differ from input, e.g. fp16 inputs -> fp32 output).
    # pytorch and numpy, following the IEEE standard, converts to Inf or NaN
    # but our kernels use satfinite. To make them the same output we have to
    # clamp on narrow precision output dtypes.
    result = clamp_to_finite_range(result, out_dtype).to(out_dtype)

    return result


def _decode_fp4_packed(tensor: torch.Tensor, pack_dim: int) -> torch.Tensor:
    """Decode a tightly packed FP4 tensor to float32 along pack_dim."""
    storage = tensor.view(torch.uint8)
    ndim = storage.dim()
    if pack_dim < 0:
        pack_dim += ndim
    if not 0 <= pack_dim < ndim:
        raise ValueError(f"Invalid FP4 packing dimension {pack_dim} for rank {ndim}")

    if pack_dim != ndim - 1:
        permutation = [dim for dim in range(ndim) if dim != pack_dim] + [pack_dim]
        storage = storage.permute(permutation).contiguous()
        inverse_permutation = [0] * ndim
        for dim, original_dim in enumerate(permutation):
            inverse_permutation[original_dim] = dim
    else:
        inverse_permutation = list(range(ndim))

    packed_elements = storage.numel()
    padded = torch.zeros(
        (1, 2 * packed_elements, 1),
        dtype=torch.uint8,
        device=tensor.device,
    )
    padded[0, :packed_elements, 0] = storage.flatten()
    decoded = decode_float4e2m1fn(padded).flatten()

    decoded_shape = list(storage.shape)
    decoded_shape[-1] *= 2
    return decoded.reshape(decoded_shape).permute(inverse_permutation)


def _expand_scale_factors(
    scale: torch.Tensor,
    mode: ops.ScaleMode | tuple[int, ...],
    swizzle: ops.ScaleSwizzleMode,
    outer_extent: int,
    k_extent: int,
    batch_count: int,
) -> torch.Tensor:
    """Expand stored block scales to dense (L, outer, K) factors."""
    expected_elements = ops.ScaledOperand.numel_scale(
        (batch_count, outer_extent, k_extent), mode, swizzle
    )
    if scale.numel() != expected_elements:
        raise ValueError(
            f"Scale tensor has {scale.numel()} elements, expected "
            f"{expected_elements} for shape "
            f"({batch_count}, {outer_extent}, {k_extent})"
        )

    vector_size = ops.ScaleMode.numel(mode)
    scale_f32 = scale.to(torch.float32)
    if swizzle is ops.ScaleSwizzleMode.SwizzleNone:
        k_blocks = ceil_div(k_extent, vector_size)
        return (
            scale_f32.reshape(batch_count, outer_extent, k_blocks)
            .repeat_interleave(vector_size, dim=-1)
            .narrow(-1, 0, k_extent)
        )
    if swizzle is ops.ScaleSwizzleMode.Swizzle32x4x4:
        return unpack_scale_factors(
            scale_f32,
            vector_size,
            outer_extent,
            k_extent,
            batch_count,
        ).permute(2, 0, 1)
    raise ValueError(f"Unsupported scale swizzle: {swizzle}")


def _compute_emulated_reference_scaled_gemm(
    A: torch.Tensor,
    B: torch.Tensor,
    scale_A: torch.Tensor,
    scale_B: torch.Tensor,
    accumulator_dtype: torch.dtype,
    out_dtype: torch.dtype,
    scale_mode_A: ops.ScaleMode | tuple[int, ...],
    scale_mode_B: ops.ScaleMode | tuple[int, ...],
    scale_swizzle_A: ops.ScaleSwizzleMode,
    scale_swizzle_B: ops.ScaleSwizzleMode,
) -> torch.Tensor:
    """Emulate block scaling for FP4/E8M0 and mixed FP4/FP8 operands."""
    fp4_dtype = getattr(torch, "float4_e2m1fn_x2", None)
    A_acc = (
        _decode_fp4_packed(A, pack_dim=A.dim() - 1)
        if A.dtype == fp4_dtype
        else A.to(torch.float32)
    )
    B_acc = (
        _decode_fp4_packed(B, pack_dim=B.dim() - 2)
        if B.dtype == fp4_dtype
        else B.to(torch.float32)
    )

    batch_count, m, k = A_acc.shape
    if B_acc.shape[0] != batch_count or B_acc.shape[1] != k:
        raise ValueError(
            "Scaled GEMM operands have incompatible decoded shapes: "
            f"A={tuple(A_acc.shape)}, B={tuple(B_acc.shape)}"
        )
    n = B_acc.shape[2]

    expanded_scale_A = _expand_scale_factors(
        scale_A,
        scale_mode_A,
        scale_swizzle_A,
        m,
        k,
        batch_count,
    )
    expanded_scale_B = _expand_scale_factors(
        scale_B,
        scale_mode_B,
        scale_swizzle_B,
        n,
        k,
        batch_count,
    )

    A_scaled = (A_acc * expanded_scale_A).to(accumulator_dtype)
    B_scaled = (B_acc * expanded_scale_B.transpose(1, 2)).to(accumulator_dtype)
    reference = torch.matmul(A_scaled, B_scaled)
    return clamp_to_finite_range(reference, out_dtype).to(out_dtype)


def compute_reference_scaled_gemm(
    A: torch.Tensor,
    B: torch.Tensor,
    scale_A: torch.Tensor,
    scale_B: torch.Tensor,
    accumulator_dtype: torch.dtype,
    out_dtype: torch.dtype,
    *,
    scale_mode_A: ops.ScaleMode | tuple[int, ...] | None = None,
    scale_mode_B: ops.ScaleMode | tuple[int, ...] | None = None,
    scale_swizzle_A: ops.ScaleSwizzleMode | None = None,
    scale_swizzle_B: ops.ScaleSwizzleMode | None = None,
) -> torch.Tensor:
    """Compute a block-scaled GEMM reference.

    Rank-2 inputs are promoted to a single batch. The native torch._scaled_mm
    path pads N to a multiple of 16 and slices the result back to the requested
    extent. FP4 with E8M0 scales and mixed FP4/FP8 inputs use an emulated path
    that decodes FP4 and expands each operand's scale factors before matmul.
    """
    if A.dim() == 2 and B.dim() == 2:
        is_2d = True
        A_batch = A.unsqueeze(0)
        B_batch = B.unsqueeze(0)
    elif A.dim() == 3 and B.dim() == 3:
        is_2d = False
        A_batch = A
        B_batch = B
    else:
        raise ValueError(
            "Scaled GEMM reference expects A and B to both be rank 2 "
            f"or rank 3, got {A.dim()} and {B.dim()}"
        )

    fp4_dtype = getattr(torch, "float4_e2m1fn_x2", None)
    fp4_scale_dtype = getattr(torch, "float8_e4m3fn", None)
    A_is_fp4 = fp4_dtype is not None and A_batch.dtype == fp4_dtype
    B_is_fp4 = fp4_dtype is not None and B_batch.dtype == fp4_dtype
    use_emulated = (
        (A_is_fp4 != B_is_fp4)
        or (A_is_fp4 and scale_A.dtype != fp4_scale_dtype)
        or (B_is_fp4 and scale_B.dtype != fp4_scale_dtype)
    )

    def emulated_reference() -> torch.Tensor:
        scale_metadata = (
            scale_mode_A,
            scale_mode_B,
            scale_swizzle_A,
            scale_swizzle_B,
        )
        if any(value is None for value in scale_metadata):
            raise ValueError(
                "FP4/E8M0 and mixed FP4/FP8 references require scale modes "
                "and scale swizzles for both operands"
            )
        reference = _compute_emulated_reference_scaled_gemm(
            A_batch,
            B_batch,
            scale_A,
            scale_B,
            accumulator_dtype,
            out_dtype,
            scale_mode_A,
            scale_mode_B,
            scale_swizzle_A,
            scale_swizzle_B,
        )
        return reference.squeeze(0) if is_2d else reference

    if use_emulated:
        return emulated_reference()

    batch_count, m = A_batch.shape[:2]
    n = B_batch.shape[-1]
    padded_n = ceil_div(n, 16) * 16
    if padded_n != n:
        n_padding = padded_n - n
        if fp4_dtype is not None and B_batch.dtype == fp4_dtype:
            B_padded = torch.zeros(
                (batch_count, B_batch.shape[1], padded_n),
                dtype=torch.int8,
                device=B_batch.device,
            )
            B_padded[:, :, :n] = B_batch.view(dtype=torch.int8)
            B_padded = B_padded.view(dtype=fp4_dtype)
        else:
            B_padded = (
                torch.nn.functional.pad(
                    B_batch.transpose(1, 2).to(torch.float32),
                    (0, 0, 0, n_padding),
                    mode="constant",
                    value=0,
                )
                .to(B_batch.dtype)
                .transpose(1, 2)
            )
    else:
        B_padded = B_batch

    scale_A = scale_A.view(batch_count, -1).contiguous()
    scale_B = scale_B.view(batch_count, -1).contiguous()
    reference = torch.empty(
        (batch_count, m, padded_n),
        device=A_batch.device,
        dtype=accumulator_dtype,
    )
    try:
        for batch_idx in range(batch_count):
            reference[batch_idx] = torch._scaled_mm(
                A_batch[batch_idx],
                B_padded[batch_idx],
                scale_a=scale_A[batch_idx],
                scale_b=scale_B[batch_idx],
                out_dtype=accumulator_dtype,
            )
    except RuntimeError:
        return emulated_reference()

    reference = clamp_to_finite_range(reference, out_dtype).to(out_dtype)
    reference = reference[:, :, :n]
    return reference.squeeze(0) if is_2d else reference


def _compare_with_reference(
    out: torch.Tensor,
    reference: torch.Tensor,
    atol: float,
    rtol: float,
) -> VerificationResult:
    """Compare an operator output with a reference tensor."""
    if reference.device != out.device:
        reference = reference.to(out.device)

    diff = torch.abs(out.float() - reference.float())
    max_abs_error = diff.max().item()
    ref_abs = torch.abs(reference.float())
    max_rel_error = (diff / (ref_abs + 1e-10)).max().item()

    try:
        torch.testing.assert_close(out.float(), reference.float(), atol=atol, rtol=rtol)
        passed = True
        error_message = None
    except AssertionError as e:
        passed = False
        error_message = str(e)

    return VerificationResult(
        passed=passed,
        max_abs_error=max_abs_error,
        max_rel_error=max_rel_error,
        error_message=error_message,
    )


def _verify_dense_gemm(
    args: ops.GemmArguments,
    atol: float,
    rtol: float,
    use_cpu: bool = False,
) -> VerificationResult:
    """Verify dense GEMM arguments against a PyTorch matmul reference."""
    A = args.A.tensor.runtime_tensor
    B = args.B.tensor.runtime_tensor
    out = args.out.tensor.runtime_tensor
    runtime_tensors = {"A": A, "B": B, "output": out}
    for name, tensor in runtime_tensors.items():
        if not isinstance(tensor, torch.Tensor):
            raise NotImplementedError(
                f"Unsupported {name} tensor type: {type(tensor).__name__}"
            )

    reference = compute_reference_gemm(
        A,
        B,
        torch_type_from_cutlass_type(args.accumulator_type),
        out.dtype,
        use_cpu=use_cpu,
    )
    return _compare_with_reference(out, reference, atol, rtol)


def _verify_scaled_gemm(
    args: ops.GemmArguments,
    atol: float,
    rtol: float,
    use_cpu: bool = False,
) -> VerificationResult:
    """Verify a block-scaled GEMM with native or emulated scaled matmul.

    This follows the runtime-backed path in scaled_dense_gemm_reference. Native
    PyTorch support is used when available; FP4/E8M0 and mixed FP4/FP8 operands
    are decoded and scaled explicitly. Batched native inputs are evaluated one
    problem at a time because PyTorch does not support batched scaled MM.
    """
    if use_cpu:
        raise ValueError(
            "Scaled GEMM verification requires CUDA because "
            "torch._scaled_mm has no CPU implementation"
        )
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
    out = args.out.tensor.runtime_tensor

    runtime_tensors = {
        "A": A,
        "B": B,
        "A scale": scale_A,
        "B scale": scale_B,
        "output": out,
    }
    for name, tensor in runtime_tensors.items():
        if not isinstance(tensor, torch.Tensor):
            raise NotImplementedError(f"Unsupported {name} tensor type: {type(tensor)}")

    reference = compute_reference_scaled_gemm(
        A,
        B,
        scale_A,
        scale_B,
        torch_type_from_cutlass_type(args.accumulator_type),
        out.dtype,
        scale_mode_A=args.A.mode,
        scale_mode_B=args.B.mode,
        scale_swizzle_A=args.A.swizzle,
        scale_swizzle_B=args.B.swizzle,
    )
    return _compare_with_reference(out, reference, atol, rtol)


def verify_gemm(
    args: ops.GemmArguments,
    atol: float | None = None,
    rtol: float | None = None,
    use_cpu: bool = False,
) -> VerificationResult:
    """Verify dense or scaled GEMM arguments against a PyTorch reference.

    Dense A/B/output operands dispatch to the dense matmul reference. Scaled A
    and B operands with a dense output dispatch to the scaled-MM reference.
    Mixed operand kinds and non-GEMM argument objects are rejected.

    ``atol`` and ``rtol`` default to :func:`gemm_reference_tolerances` for this
    problem; pass either to override just that one.
    """
    if not isinstance(args, ops.GemmArguments):
        raise TypeError(f"Expected args to be GemmArguments, got {type(args).__name__}")

    recommended = gemm_reference_tolerances(args)
    atol = recommended.atol if atol is None else atol
    rtol = recommended.rtol if rtol is None else rtol

    if (
        isinstance(args.A, ops.DenseTensor)
        and isinstance(args.B, ops.DenseTensor)
        and isinstance(args.out, ops.DenseTensor)
    ):
        return _verify_dense_gemm(
            args,
            atol=atol,
            rtol=rtol,
            use_cpu=use_cpu,
        )

    if (
        isinstance(args.A, ops.ScaledOperand)
        and isinstance(args.B, ops.ScaledOperand)
        and isinstance(args.out, ops.DenseTensor)
    ):
        return _verify_scaled_gemm(
            args,
            atol=atol,
            rtol=rtol,
            use_cpu=use_cpu,
        )

    raise TypeError(
        "Unsupported GEMM operand types: "
        f"A={type(args.A).__name__}, B={type(args.B).__name__}, "
        f"out={type(args.out).__name__}; expected three DenseTensor operands "
        "or ScaledOperand A/B with a DenseTensor output"
    )


def compute_reference_grouped_gemm(
    A: torch.Tensor,
    B: torch.Tensor,
    offsets: torch.Tensor,
    offsets_along: str,
    accumulator_dtype: torch.dtype,
    out_dtype: torch.dtype,
    use_cpu: bool = False,
) -> torch.Tensor:
    """Compute an M-, N-, or K-offset grouped GEMM reference."""
    if use_cpu:
        A = A.cpu()
        B = B.cpu()
        offsets = offsets.cpu()

    if offsets_along == "m":
        reference_shape = (A.shape[0], B.shape[-1])
    elif offsets_along == "n":
        reference_shape = (A.shape[-2], B.shape[-1])
    elif offsets_along == "k":
        reference_shape = (offsets.shape[0], A.shape[-2], B.shape[-1])
    else:
        raise ValueError(f"Unsupported grouped GEMM offset axis: {offsets_along}")

    reference = torch.empty(
        reference_shape,
        dtype=out_dtype,
        device=A.device,
    )
    start = 0
    for group, end in enumerate(offsets.cpu().tolist()):
        if offsets_along == "m":
            accum = torch.matmul(
                A[start:end, :].to(accumulator_dtype),
                B[group].to(accumulator_dtype),
            )
            target = reference[start:end, :]
        elif offsets_along == "n":
            accum = torch.matmul(
                A[group].to(accumulator_dtype),
                B[:, start:end].to(accumulator_dtype),
            )
            target = reference[:, start:end]
        else:
            accum = torch.matmul(
                A[:, start:end].to(accumulator_dtype),
                B[start:end, :].to(accumulator_dtype),
            )
            target = reference[group]
        target.copy_(clamp_to_finite_range(accum, out_dtype).to(out_dtype))
        start = end
    return reference


def verify_grouped_gemm(
    args: ops.IndexPtrGroupedGemmArguments,
    atol: float | None = None,
    rtol: float | None = None,
    use_cpu: bool = False,
) -> VerificationResult:
    """Verify a contiguous-offset grouped GEMM against independent matmuls.

    ``atol`` and ``rtol`` default to
    :func:`grouped_gemm_reference_tolerances` for this problem; pass either to
    override just that one.
    """
    if not isinstance(args, ops.IndexPtrGroupedGemmArguments):
        raise TypeError(
            "Expected args to be IndexPtrGroupedGemmArguments, "
            f"got {type(args).__name__}"
        )

    operands = {
        "A": args.A,
        "B": args.B,
        "output": args.out,
        "offsets": args.offsets,
    }
    for name, operand in operands.items():
        if not isinstance(operand, ops.DenseTensor):
            raise TypeError(
                f"Expected {name} to be a DenseTensor, got {type(operand).__name__}"
            )

    A = args.A.tensor.runtime_tensor
    B = args.B.tensor.runtime_tensor
    out = args.out.tensor.runtime_tensor
    offsets = args.offsets.tensor.runtime_tensor
    runtime_tensors = {"A": A, "B": B, "output": out, "offsets": offsets}
    for name, tensor in runtime_tensors.items():
        if not isinstance(tensor, torch.Tensor):
            raise NotImplementedError(
                f"Unsupported {name} tensor type: {type(tensor).__name__}"
            )

    recommended = grouped_gemm_reference_tolerances(args)
    atol = recommended.atol if atol is None else atol
    rtol = recommended.rtol if rtol is None else rtol

    reference = compute_reference_grouped_gemm(
        A,
        B,
        offsets,
        args.offsets_along,
        torch_type_from_cutlass_type(args.accumulator_type),
        out.dtype,
        use_cpu=use_cpu,
    )
    return _compare_with_reference(out, reference, atol, rtol)
