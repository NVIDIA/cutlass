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

"""Mixed-Input GEMM Operator for the cutlass.operators.

This module provides the API wrapper for the mixed-input GEMM Operator, which supports
GEMM operations where input tensors A and B have different data types:
- A: Narrow precision (Int4, Int8, Uint8)
- B: Wide precision (BFloat16, Float16)

Transform modes:
- Convert-Only: C = type_convert(A) @ B  (for Int8/Uint8)
- Convert-Scale: C = (type_convert(A) * scale) @ B  (for Int4)

Usage with GemmArguments:
- Convert-only mode (Int8/Uint8):
    GemmArguments(A=A_int8, B=B_bf16, out=out, accumulator_type=torch.float32)

- Convert-scale mode (Int4):
    GemmArguments(
        A=ScaledOperand(A_int4, scale, mode=(1, 128), swizzle=ScaleSwizzleMode.SwizzleNone),
        B=B_bf16,
        out=out,
        accumulator_type=torch.float32
    )
"""

from __future__ import annotations

import itertools
from typing import TYPE_CHECKING

import cutlass

from cutlass.operators.arch import TargetSm
from cutlass.operators.arguments import (
    DenseTensor,
    EpilogueArguments,
    GemmArguments,
    ScaledOperand,
    ScaleSwizzleMode,
)
from cutlass.operators.metadata import (
    DenseTensorConstraints,
    DesignMetadata,
    GemmOperandsMetadata,
    OperatorMetadata,
    ScaledOperandConstraints,
    Sm100DesignMetadata,
)
from cutlass.operators.mma import BlackwellTcgen05Mma
from cutlass.operators.providers.cutedsl import CuTeDSLProvider
from cutlass.operators.providers.cutedsl.integration_utils.mma import (
    get_max_active_clusters,
)
from cutlass.operators.providers.cutedsl.operator import CuteDslOperator
from cutlass.operators.status import Status
from cutlass.operators.utils.common import tuple_to_string
from cutlass.operators.utils.device import to_cuda_stream
from cutlass.operators.utils.tensor import (
    normalized_major_stride,
    strides_to_layout_string,
)

from .implementations.sm100_mixed_input_impl import (
    SM100_SMEM_ALIGN,
    MixedInputGemmKernel,
    compute_capacity_config,
)

if TYPE_CHECKING:
    from collections.abc import Callable, Generator

    from cutlass.operators.artifact import CompiledArtifact


def _get_scale_granularity(args: GemmArguments) -> tuple[int, int]:
    """Extract scale granularity from GemmArguments.

    For ScaledOperand A, the mode tuple is (scale_granularity_m, scale_granularity_k).
    For DenseTensor A, returns (0, 0) for convert-only mode.

    :param args: GemmArguments
    :return: Tuple of (scale_granularity_m, scale_granularity_k)
    """
    if isinstance(args.A, ScaledOperand):
        # mode is (scale_granularity_m, scale_granularity_k)
        return (args.A.mode[0], args.A.mode[1])
    return (0, 0)


def _get_a_tensor(args: GemmArguments):
    """Get the quantized A tensor from GemmArguments."""
    if isinstance(args.A, ScaledOperand):
        return args.A.quantized.tensor
    return args.A.tensor


def _get_scale_tensor(args: GemmArguments):
    """Get the scale tensor from GemmArguments, or None if not present."""
    if isinstance(args.A, ScaledOperand):
        return args.A.scale.tensor
    return None


@CuTeDSLProvider.register
class MixedInputGemmOperator(CuteDslOperator):
    """Mixed-Input GEMM Operator for NVIDIA Blackwell SM100 architecture.

    This Operator supports GEMM operations where input tensors A and B have different
    data types, with tensor A being transformed to the precision of tensor B before
    matrix multiplication.

    Supported A data types (narrow precision):
    - Int4 (requires scale tensor via ScaledOperand)
    - Int8
    - Uint8

    Supported B data types (wide precision):
    - BFloat16
    - Float16

    Supported accumulator data types:
    - Float32 (required when B is BFloat16)
    - Float16 (only when B is Float16)

    Supported output data types:
    - BFloat16
    - Float16
    - Float32

    Transform modes:
    - Convert-Only: C = type_convert(A) @ B  (for Int8/Uint8 with DenseTensor A)
    - Convert-Scale: C = (type_convert(A) * scale) @ B  (for Int4 with ScaledOperand A)

    Constraints:
    - MMA tiler M must be 64/128 (use_2cta_instrs=False) or 128/256 (use_2cta_instrs=True)
    - MMA tiler N must be 32-256, step 32
    - Cluster shape M must be multiple of 2 if use_2cta_instrs=True
    - Cluster shape M/N must be positive and power of 2, total cluster size <= 16
    - scale_granularity_k must be a multiple of mma_tiler_k
    """

    supported_args_type = GemmArguments
    designed_for_min_cc = 100

    def __init__(self, metadata: OperatorMetadata):
        """Initialize the mixed-input GEMM Operator with specified metadata.

        :param metadata: Operator metadata containing operand and design information
        """
        super().__init__(metadata)

        mma_tiler_mnk = metadata.design.tile_shape  # Full 3-tuple (M, N, K)
        cluster_shape_mn = (
            metadata.design.cluster_shape[0],
            metadata.design.cluster_shape[1],
        )

        # Extract scale granularity from metadata
        scale_granularity_m, scale_granularity_k = self._extract_scale_granularity(
            metadata.operands
        )

        shuffle_a = self._compute_shuffle_a(metadata, scale_granularity_k)

        self.impl = MixedInputGemmKernel(
            scale_granularity_m=scale_granularity_m,
            scale_granularity_k=scale_granularity_k,
            acc_dtype=metadata.operands.accumulator_type,
            use_2cta_instrs=metadata.design.use_2cta_mma,
            mma_tiler_mnk=mma_tiler_mnk,
            cluster_shape_mn=cluster_shape_mn,
            use_tma_store=metadata.design.use_tma_store,
            shuffle_a=shuffle_a,
        )

        self._shuffle_a = shuffle_a

    @staticmethod
    def _extract_scale_granularity(
        operands: GemmOperandsMetadata,
    ) -> tuple[int, int]:
        """Extract scale granularity from operands metadata.

        For mixed-input GEMM, mode is a 2-tuple: (scale_granularity_m, scale_granularity_k)
        For DenseTensor A (convert-only mode), returns (0, 0).
        """
        if isinstance(operands.A, ScaledOperandConstraints):
            mode = getattr(operands.A, "mode", None)
            if isinstance(mode, (tuple, list)) and len(mode) >= 2:
                return (mode[0], mode[1])
        return (0, 0)

    @staticmethod
    def _compute_shuffle_a(
        metadata: OperatorMetadata, scale_granularity_k: int
    ) -> bool:
        """Determine if shuffle should be used for A tensor transformation.

        Shuffle optimization enables a fast Int4→BFloat16 conversion path using the
        hardware intrinsic `cvt_i4_bf16_intrinsic` (see: cutlass.cute.arch.numeric_conversion).

        This intrinsic processes 8 Int4 elements at a time. When shuffle is enabled,
        the input elements are expected in a specific pattern: indices (0,1,2,3,4,5,6,7)
        are reordered to (0,2,1,3,4,6,5,7). This pre-shuffled layout allows the intrinsic
        to produce BFloat16 output in natural order without extra permutation (prmt)
        instructions, improving performance.

        Shuffle optimization requires:
        1. A tensor is K-major (row-major for M×K) - data layout matches shuffle pattern
        2. A dtype is Int4 - intrinsic is specific to Int4
        3. B dtype is BFloat16 - intrinsic only outputs BFloat16 (no Float16 equivalent)
        4. scale_granularity_k >= 8 - sufficient granularity for shuffle pattern

        The intrinsic operates on 8-element groups, but the TMA 16-byte alignment
        for Int4 already guarantees K % 32 == 0, which subsumes K % 8.

        See: cutlass.utils.mixed_input_helpers.is_shuffle_a()
             cutlass.cute.arch.numeric_conversion.cvt_i4_bf16_intrinsic()

        :param metadata: Operator metadata containing operand information
        :param scale_granularity_k: Scale granularity along K dimension
        :return: True if shuffle should be used, False otherwise
        """
        # Get A dtype and stride from metadata
        if isinstance(metadata.operands.A, ScaledOperandConstraints):
            a_dtype = metadata.operands.A.quantized.dtype
            a_stride = metadata.operands.A.quantized.stride
        else:
            a_dtype = metadata.operands.A.dtype
            a_stride = metadata.operands.A.stride

        b_dtype = metadata.operands.B.dtype

        # Check conditions that can be verified at Operator generation time:
        # 1. A dtype is Int4
        # 2. B dtype is BFloat16 (shuffle only supported for BFloat16, not Float16)
        # 3. A is K-major
        # 4. scale_granularity_k >= 8
        if a_dtype == cutlass.Int4 and b_dtype == cutlass.BFloat16:
            # Check if A is K-major (last dimension contiguous)
            # For 3D stride (batch, row, col):
            # (0, 0, 1) means K dimension is contiguous = K-major
            # (0, 1, 0) means M dimension is contiguous = M-major
            is_k_major = a_stride == (0, 0, 1)

            if is_k_major and scale_granularity_k >= 8:
                return True
        return False

    def _supports(
        self, args: GemmArguments, target_sm: TargetSm | None = None
    ) -> Status:
        """Check if the Operator supports the given arguments.

        Checks here are for problem-size-dependent constraints: K divisibility
        by scale_granularity_k and OOB tile alignment. Operand compatibility
        (dtype, stride, divisibility) and epilogue rejection are handled by the
        base class via metadata.supports(); scale_granularity_k/tile_k
        divisibility is handled by _valid_metadata at generation time.

        :param args: The GEMM arguments to check
        :return: Status indicating support
        """
        # Get tensors for dimension checks
        a_tensor = _get_a_tensor(args)
        b_tensor = args.B.tensor

        # Extract dimensions (tensors are in batch-first format: L, M, K or L, K, N)
        k = a_tensor.shape[-1]  # K dimension from A

        tile_m, tile_n, tile_k = self.metadata.design.tile_shape
        use_2cta = self.metadata.design.use_2cta_mma

        # Validate scale granularity constraints that depend on problem size
        _, scale_granularity_k = _get_scale_granularity(args)
        if scale_granularity_k > 0:
            # k must be divisible by scale_granularity_k
            if k % scale_granularity_k != 0:
                return Status.fail(
                    f"K dimension ({k}) must be divisible by "
                    f"scale_granularity_k ({scale_granularity_k})"
                )
            # scale_granularity_k must be divisible by mma_tiler_k
            if scale_granularity_k % tile_k != 0:
                return Status.fail(
                    f"scale_granularity_k ({scale_granularity_k}) must be "
                    f"divisible by mma_tiler_k ({tile_k})"
                )

        # Validate OOB tile constraint when TMA store is disabled
        # Without TMA store, out-of-bounds tiles are not supported
        if not self.metadata.design.use_tma_store:
            m = a_tensor.shape[-2]  # M dimension from A
            n = b_tensor.shape[-1]  # N dimension from B
            cta_tile_m = tile_m // (2 if use_2cta else 1)
            cta_tile_n = tile_n
            if m % cta_tile_m != 0:
                return Status.fail(
                    f"When TMA store is disabled, M dimension ({m}) must be "
                    f"divisible by CTA tile M ({cta_tile_m})"
                )
            if n % cta_tile_n != 0:
                return Status.fail(
                    f"When TMA store is disabled, N dimension ({n}) must be "
                    f"divisible by CTA tile N ({cta_tile_n})"
                )

        return Status.success()

    def _compile(
        self, args: GemmArguments, target_sm: TargetSm | None = None
    ) -> CompiledArtifact:
        """Compile the Operator for the given arguments.

        :param args: The GEMM arguments
        :param target_sm: Target compute capability (optional)
        :return: Compiled artifact
        """
        stream = cutlass.cute.runtime.make_fake_stream()
        max_active_clusters = get_max_active_clusters(self.impl.cluster_shape_mn)

        a_tensor = _get_a_tensor(args)
        scale_tensor = _get_scale_tensor(args)

        return self.cute_compile(
            self.impl,
            a_tensor,
            scale_tensor,
            args.B.tensor,
            args.out.tensor,
            max_active_clusters,
            stream,
            target_sm=target_sm,
        )

    def _run(
        self,
        args: GemmArguments,
        compiled_artifact: CompiledArtifact,
        stream,
        workspace=None,
    ) -> None:
        """Execute the compiled Operator.

        :param args: The GEMM arguments
        :param compiled_artifact: The compiled artifact
        :param stream: CUDA stream for execution
        :param workspace: Optional workspace (unused)
        """
        stream = to_cuda_stream(stream)
        compiled_gemm = compiled_artifact.compiled_obj

        a_tensor = _get_a_tensor(args)
        scale_tensor = _get_scale_tensor(args)

        self.cute_run(
            compiled_gemm,
            a_tensor,
            scale_tensor,
            args.B.tensor,
            args.out.tensor,
            stream,
        )

    @staticmethod
    def _valid_operands(operands: GemmOperandsMetadata) -> bool:
        """Check if the operand metadata represents a valid mixed-input configuration.

        :param operands: The operand metadata to validate
        :return: True if valid, False otherwise
        """
        # Get A dtype
        if isinstance(operands.A, ScaledOperandConstraints):
            a_dtype = operands.A.quantized.dtype
            is_scaled = True
        elif isinstance(operands.A, DenseTensorConstraints):
            a_dtype = operands.A.dtype
            is_scaled = False
        else:
            # Plain OperandConstraints - treat as dense
            a_dtype = operands.A.dtype
            is_scaled = False

        # A must be narrow precision
        narrow_types = [cutlass.Int4, cutlass.Int8, cutlass.Uint8]
        if a_dtype not in narrow_types:
            return False

        # Get B dtype
        if isinstance(operands.B, ScaledOperandConstraints):
            # Mixed-input doesn't support scaled B
            return False
        elif isinstance(operands.B, DenseTensorConstraints):
            b_dtype = operands.B.dtype
        else:
            b_dtype = operands.B.dtype

        # B must be wide precision
        wide_types = [cutlass.BFloat16, cutlass.Float16]
        if b_dtype not in wide_types:
            return False

        # Accumulator type constraints:
        # - BFloat16 B: accumulator must be Float32
        # - Float16 B: accumulator can be Float16 or Float32
        if b_dtype == cutlass.BFloat16 and operands.accumulator_type != cutlass.Float32:
            return False
        if b_dtype == cutlass.Float16 and operands.accumulator_type not in [
            cutlass.Float16,
            cutlass.Float32,
        ]:
            return False

        # Get output dtype
        if isinstance(operands.out, ScaledOperandConstraints):
            return False  # Output shouldn't be scaled
        elif isinstance(operands.out, DenseTensorConstraints):
            out_dtype = operands.out.dtype
        else:
            out_dtype = operands.out.dtype

        # Output must be compatible
        valid_out_types = [cutlass.BFloat16, cutlass.Float16, cutlass.Float32]
        if out_dtype not in valid_out_types:
            return False

        # Accumulator/output type compatibility:
        # - Float16 accumulator can output to 16-bit types (Float16, BFloat16)
        # - Float16 accumulator cannot output to Float32 (no acc_bits=16, d_bits=32 case)
        # - Float32 accumulator can output to any supported type
        # See: cutlass/utils/blackwell_helpers.py acc_bits/d_bits combinations
        if operands.accumulator_type == cutlass.Float16 and out_dtype not in [
            cutlass.Float16,
            cutlass.BFloat16,
        ]:
            return False

        # Validate scale requirements based on A dtype
        a_bit_width = a_dtype.width

        if a_bit_width == 8:  # Int8 or Uint8
            # 8-bit types use convert-only mode (no scale)
            if is_scaled:
                return False
        elif a_bit_width == 4:  # Int4
            # Int4 requires scale
            if not is_scaled:
                return False
            # Apply constraints from mixed_input_helpers.is_valid_scale_granularity
            scale_m, scale_k = MixedInputGemmOperator._extract_scale_granularity(
                operands
            )
            # Constraint: scale_granularity_m must be 1 (per-row scaling)
            if scale_m != 1:
                return False
            # Constraint: scale_granularity_k must be > 0
            if scale_k <= 0:
                return False

        return True

    @staticmethod
    def _valid_design(design: DesignMetadata) -> bool:
        """Check if the design metadata represents a valid configuration.

        Validates hardware constraints of the SM100 tcgen05 MMA instruction:
        - Cluster M must be divisible by 2 in 2CTA mode (CTAs work in pairs)
        - Per-CTA tile M must be 64 or 128 (supported tcgen05 MMA tile sizes)

        :param design: The design metadata to validate
        :return: True if valid, False otherwise
        """
        tile_m = design.tile_shape[0]
        cluster_m = design.cluster_shape[0]

        cta_divisor = 2 if design.use_2cta_mma else 1
        if cluster_m % cta_divisor != 0:
            return False

        cta_tile_m = tile_m // cta_divisor
        if cta_tile_m not in [64, 128]:
            return False

        return True

    @staticmethod
    def _check_capacity(metadata: OperatorMetadata) -> bool:
        """Check if the Operator configuration fits within SMEM/TMEM capacity.

        This uses the shared compute_capacity_config function which is also
        used by the compile-time code, ensuring the checks are identical.

        :param metadata: The operator metadata to validate
        :return: True if capacity is sufficient, False otherwise
        """
        design = metadata.design
        operands = metadata.operands

        tile_m, tile_n, tile_k = design.tile_shape
        use_2cta = design.use_2cta_mma
        cta_divisor = 2 if use_2cta else 1

        # Get A tensor attributes
        if isinstance(operands.A, ScaledOperandConstraints):
            a_dtype = operands.A.quantized.dtype
            a_stride = operands.A.quantized.stride
            scale_mode_is_convert_only = False
            mode = getattr(operands.A, "mode", None)
            if isinstance(mode, (tuple, list)) and len(mode) >= 2:
                scale_granularity_m = mode[0]
                scale_granularity_k = mode[1]
            else:
                scale_granularity_m = 0
                scale_granularity_k = 0
        else:
            a_dtype = operands.A.dtype
            a_stride = operands.A.stride
            scale_mode_is_convert_only = True
            scale_granularity_m = 0
            scale_granularity_k = 0

        # Determine if A uses TMEM (K-major) or SMEM (M-major)
        is_k_major = a_stride == (0, 0, 1)

        # Compute capacity configuration using the shared function
        config = compute_capacity_config(
            cta_tile_m=tile_m // cta_divisor,
            cta_tile_n=tile_n,
            cta_tile_k=tile_k,
            use_2cta=use_2cta,
            a_dtype_width=a_dtype.width,
            b_dtype_width=operands.B.dtype.width,
            mma_dtype_width=operands.B.dtype.width,  # MMA operates in B's precision
            out_dtype_width=operands.out.dtype.width,
            transform_a_source_is_tmem=is_k_major,
            scale_mode_is_convert_only=scale_mode_is_convert_only,
            scale_granularity_m=scale_granularity_m,
            scale_granularity_k=scale_granularity_k,
            use_tma_store=design.use_tma_store,
            smem_align=SM100_SMEM_ALIGN,
        )

        return config.is_valid

    @staticmethod
    def _valid_metadata(metadata: OperatorMetadata) -> bool:
        """Check if the operator metadata is valid.

        :param metadata: The operator metadata to validate
        :return: True if valid, False otherwise
        """
        if not MixedInputGemmOperator._valid_operands(metadata.operands):
            return False
        if not MixedInputGemmOperator._valid_design(metadata.design):
            return False

        # Cross-validate scale granularity against tile shape
        scale_m, scale_k = MixedInputGemmOperator._extract_scale_granularity(
            metadata.operands
        )
        tile_k = metadata.design.tile_shape[2]
        if scale_k > 0 and scale_k % tile_k != 0:
            return False

        if not MixedInputGemmOperator._check_capacity(metadata):
            return False
        return True

    @staticmethod
    def _metadata_operands_from_args(
        args: GemmArguments,
    ) -> Generator[GemmOperandsMetadata, None, None]:
        """Generator that yields all valid GemmOperandsMetadata that correspond to `args` and
        that are supported by this Operator.

        :param args: The arguments to generate operands from.
        :type args: GemmArguments

        :return: A generator of valid GemmOperandsMetadata that correspond to `args` and
        that are supported by this Operator.
        :rtype: Generator[GemmOperandsMetadata, None, None]
        """
        alignment_bytes = 16
        col_major_stride = (0, 1, 0)
        valid_major_strides = {(0, 0, 1), (0, 1, 0)}

        # --- A operand ---
        if isinstance(args.A, ScaledOperand):
            a_quantized = args.A.quantized
            a_dtype = a_quantized.dtype
            A_stride = normalized_major_stride(
                a_quantized.shape, a_quantized.stride, prepend_zeros_to_rank=3
            )
            if A_stride is None or A_stride not in valid_major_strides:
                return
            mode = getattr(args.A, "mode", None)
            if not isinstance(mode, (tuple, list)) or len(mode) < 2:
                return
            scale_m, scale_k = mode[0], mode[1]
            a_attr = ScaledOperandConstraints(
                quantized=DenseTensorConstraints(
                    dtype=a_dtype,
                    stride=A_stride,
                    divisibility=alignment_bytes * 8 // a_dtype.width,
                ),
                scale=DenseTensorConstraints(
                    dtype=args.A.scale.dtype,
                    stride=col_major_stride,
                    divisibility=alignment_bytes * 8 // args.A.scale.dtype.width,
                ),
                mode=(scale_m, scale_k),
                swizzle=args.A.swizzle,
            )
        elif isinstance(args.A, DenseTensor):
            a_dtype = args.A.dtype
            A_stride = normalized_major_stride(
                args.A.shape, args.A.stride, prepend_zeros_to_rank=3
            )
            if A_stride is None or A_stride not in valid_major_strides:
                return
            a_attr = DenseTensorConstraints(
                dtype=a_dtype,
                stride=A_stride,
                divisibility=alignment_bytes * 8 // a_dtype.width,
            )
        else:
            return

        # --- B operand ---
        if not isinstance(args.B, DenseTensor):
            return
        B_stride = normalized_major_stride(
            args.B.shape, args.B.stride, prepend_zeros_to_rank=3
        )
        if B_stride is None or B_stride not in valid_major_strides:
            return
        b_attr = DenseTensorConstraints(
            dtype=args.B.dtype,
            stride=B_stride,
            divisibility=alignment_bytes * 8 // args.B.dtype.width,
        )

        # --- Out operand ---
        out_stride = normalized_major_stride(
            args.out.shape, args.out.stride, prepend_zeros_to_rank=3
        )
        if out_stride is None or out_stride not in valid_major_strides:
            return
        out_attr = DenseTensorConstraints(
            dtype=args.out.dtype,
            stride=out_stride,
            divisibility=alignment_bytes * 8 // args.out.dtype.width,
        )

        operands = GemmOperandsMetadata(
            A=a_attr, B=b_attr, out=out_attr, accumulator_type=args.accumulator_type
        )

        if not MixedInputGemmOperator._valid_operands(operands):
            return

        yield operands

    @staticmethod
    def _metadata_operand_combinations() -> Generator[GemmOperandsMetadata, None, None]:
        """Generate all valid operand metadata combinations for mixed-input GEMM.

        :yield: Valid GemmOperandsMetadata instances
        """
        narrow_dtypes = [cutlass.Int4, cutlass.Int8, cutlass.Uint8]
        wide_dtypes = [cutlass.BFloat16, cutlass.Float16]
        out_dtypes = [cutlass.BFloat16, cutlass.Float16, cutlass.Float32]

        # Scale granularities: (m, k)
        # (0, 0) = convert-only mode (for Int8/Uint8)
        # (1, k) = per-row scaling with k elements sharing a scale along K (for Int4)
        #
        # Note: Unlike the original example which accepts user-specified values,
        # the API must enumerate operators at discovery time, so we pre-define
        # common configurations. These values must satisfy:
        # - scale_granularity_k % mma_tiler_k == 0 (validated at runtime)
        # - k % scale_granularity_k == 0 (validated at runtime)
        #
        # Common values are multiples of typical mma_tiler_k values (64, 128, 256).
        # Users needing other values can extend this list or create custom operators.
        scale_configs = [
            (0, 0),  # convert-only
            (1, 64),  # per-row, 64 elements per scale along K
            (1, 128),  # per-row, 128 elements per scale along K
            (1, 256),  # per-row, 256 elements per scale along K
            (1, 512),  # per-row, 512 elements per scale along K
        ]

        # Layout strides (rank-3): (batch, row, col)
        row_major_stride = (0, 0, 1)
        col_major_stride = (0, 1, 0)

        layout_strides = [
            (row_major_stride, row_major_stride, row_major_stride),
            (row_major_stride, col_major_stride, row_major_stride),
            (col_major_stride, row_major_stride, row_major_stride),
            (col_major_stride, col_major_stride, row_major_stride),
        ]

        alignment_bytes = 16

        for a_dtype in narrow_dtypes:
            for b_dtype in wide_dtypes:
                for out_dtype in out_dtypes:
                    for scale_m, scale_k in scale_configs:
                        for a_stride, b_stride, out_stride in layout_strides:
                            # Calculate divisibility based on alignment
                            a_divisibility = alignment_bytes * 8 // a_dtype.width
                            b_divisibility = alignment_bytes * 8 // b_dtype.width
                            out_divisibility = alignment_bytes * 8 // out_dtype.width

                            # Int4 requires scale (convert-scale mode)
                            if a_dtype == cutlass.Int4:
                                if scale_m == 0 or scale_k == 0:
                                    continue

                                # A is a ScaledOperand
                                a_attr = ScaledOperandConstraints(
                                    quantized=DenseTensorConstraints(
                                        dtype=a_dtype,
                                        stride=a_stride,
                                        divisibility=a_divisibility,
                                    ),
                                    scale=DenseTensorConstraints(
                                        dtype=b_dtype,  # Scale has same type as B
                                        stride=col_major_stride,  # M-major
                                        divisibility=b_divisibility,
                                    ),
                                    mode=(scale_m, scale_k),
                                    swizzle=ScaleSwizzleMode.SwizzleNone,
                                )
                            else:
                                # Int8/Uint8 use convert-only (no scale)
                                if scale_m != 0 or scale_k != 0:
                                    continue

                                # A is a DenseTensor
                                a_attr = DenseTensorConstraints(
                                    dtype=a_dtype,
                                    stride=a_stride,
                                    divisibility=a_divisibility,
                                )

                            # B is always a DenseTensor for mixed-input
                            b_attr = DenseTensorConstraints(
                                dtype=b_dtype,
                                stride=b_stride,
                                divisibility=b_divisibility,
                            )

                            # Output is always a DenseTensor
                            out_attr = DenseTensorConstraints(
                                dtype=out_dtype,
                                stride=out_stride,
                                divisibility=out_divisibility,
                            )

                            # Determine valid accumulator types based on B dtype
                            # and acc/output compatibility
                            if b_dtype == cutlass.BFloat16:
                                valid_acc_types = [cutlass.Float32]
                            else:  # Float16 B
                                # Float16 acc can output to 16-bit types (Float16, BFloat16)
                                # Float32 acc can output to any type
                                if out_dtype in [cutlass.Float16, cutlass.BFloat16]:
                                    valid_acc_types = [cutlass.Float16, cutlass.Float32]
                                else:  # Float32 output
                                    valid_acc_types = [cutlass.Float32]

                            for acc_type in valid_acc_types:
                                yield GemmOperandsMetadata(
                                    A=a_attr,
                                    B=b_attr,
                                    out=out_attr,
                                    accumulator_type=acc_type,
                                )

    @classmethod
    def _generate_operators(
        cls,
        metadata_filter: Callable[[OperatorMetadata], bool],
        epilogue_args: EpilogueArguments = None,
        target_sm: TargetSm | None = None,
        args: GemmArguments = None,
    ) -> list[MixedInputGemmOperator]:
        """Generate all valid MixedInputGemmOperator configurations.

        :param metadata_filter: Filter function for metadata
        :param epilogue_args: Epilogue arguments (unused, returns empty if provided)
        :param target_sm: Target compute capability
        :return: List of valid Operator instances
        """
        # No epilogue support for mixed-input operators currently
        if epilogue_args is not None:
            return []

        design_params = {
            "mma_instruction_type": [BlackwellTcgen05Mma],
            "use_2cta_mma": [True, False],
            "tile_shape": [
                (M, N, K)
                for M in [64, 128, 256]
                for N in [32, 64, 128, 256]
                for K in [64, 128, 256]
            ],
            "cluster_shape": [(M, N, 1) for M in [1, 2] for N in [1, 2]],
            "use_tma_store": [
                True
            ],  # Non-TMA store path disabled due to OOB tile limitations
        }

        param_names = list(design_params.keys())
        param_values = [design_params[name] for name in param_names]

        operator_list = []

        if args is not None:
            operands_generator = cls._metadata_operands_from_args(args)
        else:
            operands_generator = cls._metadata_operand_combinations()

        for operands in operands_generator:
            for values in itertools.product(*param_values):
                design = Sm100DesignMetadata(**dict(zip(param_names, values)))

                # Extract scale mode for naming
                scale_m, scale_k = cls._extract_scale_granularity(operands)
                scale_mode = f"scale{scale_m}x{scale_k}" if scale_m > 0 else "convert"

                # Get A dtype for naming
                if isinstance(operands.A, ScaledOperandConstraints):
                    a_dtype = operands.A.quantized.dtype
                    a_stride = operands.A.quantized.stride
                else:
                    a_dtype = operands.A.dtype
                    a_stride = operands.A.stride

                # Get B dtype
                if isinstance(operands.B, DenseTensorConstraints):
                    b_dtype = operands.B.dtype
                    b_stride = operands.B.stride
                else:
                    b_dtype = operands.B.dtype
                    b_stride = operands.B.stride

                # Get out dtype
                if isinstance(operands.out, DenseTensorConstraints):
                    out_dtype = operands.out.dtype
                    out_stride = operands.out.stride
                else:
                    out_dtype = operands.out.dtype
                    out_stride = operands.out.stride

                layout = strides_to_layout_string(a_stride, b_stride, out_stride)

                operator_name = (
                    f"cutedsl.MixedInputGemmOperator_sm100_{scale_mode}_{layout}"
                    f"A{a_dtype}_B{b_dtype}_out{out_dtype}_"
                    f"acc{operands.accumulator_type}_"
                    f"{'2cta' if design.use_2cta_mma else '1cta'}_"
                    f"cluster{tuple_to_string(design.cluster_shape)}_"
                    f"tile{tuple_to_string(design.tile_shape)}"
                    f"{'_tma_store' if design.use_tma_store else ''}"
                )

                metadata = OperatorMetadata(
                    operands=operands,
                    design=design,
                    operator_name=operator_name,
                    operator_class=cls,
                    supported_targets=TargetSm.get_supported_targets(design, operands),
                    epilogue=None,
                )

                if cls._valid_metadata(metadata) and metadata_filter(metadata):
                    operator_list.append(cls(metadata))

        return operator_list
