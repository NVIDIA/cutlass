#
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

"""Operator-API wrapper for the SM100 block-scaled (MXFP8) persistent dense
GEMM with EFC epilogues.

``Sm100PersistentBlockScaledGemmEFCOperator`` offers ``GemmArguments`` whose
A and B are ``ScaledOperand`` s -- fp8 quantized tensors with E8M0 block
scales, one per 32 K elements (OCP MXFP8), stored in the 32x4x4 swizzled
layout the Blackwell block-scaled MMA reads -- with the same fused-epilogue
surface as the dense EFC operator.  Discovery, metadata validation, the
``EFCConverter`` bridge and the compile/run plumbing are inherited from
``_PersistentDenseGemmEFCOperatorBase``; this module adds the block-scaled
operand rules (quantized and scale dtypes, scale mode and swizzle, scale
element counts), the block-scaled tile menu (MMA tiler M is the block-scaled
instruction M, 128 or 256, and tile N is 64, 128, 192 or 256; the scale
factors come in 128-row by 4-scale atoms, and at N=64 and N=192 the kernel
shares one staged SFB atom window between neighbouring N tiles), and hands
the scale buffers to the kernel after A/B.

The GPU kernel is ``PersistentDenseBlockScaledGemmEFCKernel``, a batch-layout
adapter over the verbatim example ``DenseGemmEFCBlockScaled``.  The scale
buffers pass through as-is: the operation builds the canonical scale view
from their pointer and A's/B's shape, the same contract as the plain
``Sm100BlockscaledStaticPersistentOperator``.

Configuration note: at tile N=256 the operation runs a single accumulator
stage next to the scale factors in SM100's 512 TMEM columns.  The operator
enumerates it; ranking is the heuristics layer's job.
"""

from __future__ import annotations

import itertools
from typing import TYPE_CHECKING

import cutlass

from cutlass.operators.arguments import (
    DenseTensor,
    GemmArguments,
    ScaledOperand,
    ScaleMode,
    ScaleSwizzleMode,
)
from cutlass.operators.metadata import (
    GemmOperandsMetadata,
    ScaledOperandConstraints,
)
from cutlass.operators.providers.cutedsl import CuTeDSLProvider
from cutlass.operators.providers.cutedsl.gemm.sm100_blockscaled_static_persistent import (
    Sm100BlockscaledStaticPersistentOperator,
)
from cutlass.operators.providers.cutedsl.gemm.static_persistent_efc_base import (
    _PersistentDenseGemmEFCOperatorBase,
)
from cutlass.operators.status import Status
from cutlass.operators.utils.tensor import normalized_major_stride

from .implementations.sm100_dense_blockscaled_static_persistent_efc_impl import (
    PersistentDenseBlockScaledGemmEFCKernel,
)

if TYPE_CHECKING:
    from collections.abc import Generator

    from cutlass.operators.arch import TargetSm

# MXFP8: fp8 quantized operands (formats may mix), E8M0 scales over 32 K
# elements, in the swizzled layout the block-scaled MMA's TMEM copy expects.
_FP8_DTYPES = (cutlass.Float8E4M3FN, cutlass.Float8E5M2)
_SF_DTYPE = cutlass.Float8E8M0FNU
_SCALE_MODE = ScaleMode.Blockwise1x32
_SCALE_SWIZZLE = ScaleSwizzleMode.Swizzle32x4x4


@CuTeDSLProvider.register
class Sm100PersistentBlockScaledGemmEFCOperator(_PersistentDenseGemmEFCOperatorBase):
    """SM100 block-scaled (MXFP8) persistent dense GEMM with EFC epilogue fusion.

    Args:
        metadata (OperatorMetadata): One validated kernel configuration
            (operands, design, and optional epilogue) to instantiate.

    Note:
        A and B are ``ScaledOperand`` s with fp8 (Float8E4M3FN / Float8E5M2,
        mixable) quantized tensors and Float8E8M0FNU scales in
        ``ScaleMode.Blockwise1x32`` / ``ScaleSwizzleMode.Swizzle32x4x4``; the
        accumulator is Float32.  Output dtypes: see
        ``_valid_acc_out_combinations[Float32]``.  As for the dense operator,
        the epilogue computes in the output dtype.

    Note:
        Design constraints (see the shared ``_valid_design``): MMA tiler M is
        128 (1-CTA) or 256 (2-CTA); tile N is 64, 128, 192 or 256; tile K
        is 128;
        cluster M is a multiple of 2 when ``use_2cta_mma``; cluster M/N are
        positive powers of 2 with product <= 16.
    """

    supported_args_type = GemmArguments
    designed_for_min_cc = 100
    _shim_kernel_type = PersistentDenseBlockScaledGemmEFCKernel

    @classmethod
    def _valid_operands(cls, operands: GemmOperandsMetadata) -> bool:
        if not isinstance(operands, GemmOperandsMetadata):
            return False
        A, B = operands.A, operands.B
        if not isinstance(A, ScaledOperandConstraints) or not isinstance(
            B, ScaledOperandConstraints
        ):
            return False
        if A.dtype not in _FP8_DTYPES or B.dtype not in _FP8_DTYPES:
            return False
        if A.scale.dtype is not _SF_DTYPE or B.scale.dtype is not _SF_DTYPE:
            return False
        if A.mode != _SCALE_MODE or B.mode != _SCALE_MODE:
            return False
        if A.swizzle != _SCALE_SWIZZLE or B.swizzle != _SCALE_SWIZZLE:
            return False
        if operands.accumulator_type is not cutlass.Float32:
            return False
        if operands.out.dtype not in cls._valid_acc_out_combinations[cutlass.Float32]:
            return False

        valid_major_strides = {(0, 0, 1), (0, 1, 0)}
        return all(
            operand.stride in valid_major_strides for operand in (A, B, operands.out)
        )

    @classmethod
    def _valid_tile_shape(cls, design) -> bool:
        """Block-scaled tile-M law: the full MMA tiler M is the block-scaled
        instruction M, 128 single-CTA or 256 two-CTA."""
        return design.tile_shape[0] == (256 if design.use_2cta_mma else 128)

    @classmethod
    def _tile_n_menu(cls) -> tuple[int, ...]:
        # Whole 128-row SFB atoms, or the shared-window halves of one (64)
        # and of two (192); the kernel rejects anything else.
        return (64, 128, 192, 256)

    @classmethod
    def _tile_m_candidates(cls, use_2cta_mma: bool) -> tuple[int, ...]:
        # One block-scaled instruction M per CTA mode (see _valid_tile_shape).
        return (256,) if use_2cta_mma else (128,)

    @classmethod
    def _tile_n_candidates(cls) -> tuple[int, ...]:
        return cls._tile_n_menu()

    @classmethod
    def _mainloop_tensors(cls, args: GemmArguments) -> tuple:
        """The scale buffers follow A/B in the kernel's argument list."""
        return (args.A.scale.tensor, args.B.scale.tensor)

    @classmethod
    def _operand_name_fragment(cls, operands: GemmOperandsMetadata) -> str:
        return (
            f"_A{operands.A.dtype}_B{operands.B.dtype}_out{operands.out.dtype}_SFA{operands.A.scale.dtype}_SFB{operands.B.scale.dtype}_acc{operands.accumulator_type}"
            f"_scale{operands.A.mode}_swizzle{operands.A.swizzle}"
        )

    @classmethod
    def _metadata_operands_from_args(
        cls,
        args: GemmArguments,
    ) -> Generator[GemmOperandsMetadata, None, None]:
        """Yield the GemmOperandsMetadata for scaled fp8 ``args``."""
        if any(not isinstance(x, ScaledOperand) for x in (args.A, args.B)):
            return
        if any(not isinstance(x.quantized, DenseTensor) for x in (args.A, args.B)):
            return
        if any(not isinstance(x.scale, DenseTensor) for x in (args.A, args.B)):
            return
        if not isinstance(args.out, DenseTensor):
            return

        A_stride = normalized_major_stride(
            args.A.shape, args.A.stride, prepend_zeros_to_rank=3
        )
        B_stride = normalized_major_stride(
            args.B.shape, args.B.stride, prepend_zeros_to_rank=3
        )
        out_stride = normalized_major_stride(
            args.out.shape, args.out.stride, prepend_zeros_to_rank=3
        )
        # The divisibility constraints are those of the block-scaled mainloop
        # (TMA alignment of A/B/out, 32-byte scale alignment), shared with
        # the plain block-scaled operator.
        operands = (
            Sm100BlockscaledStaticPersistentOperator._construct_divisible_operands(
                args.A.dtype,
                args.B.dtype,
                args.A.scale.dtype,
                args.B.scale.dtype,
                args.out.dtype,
                args.accumulator_type,
                args.A.mode,
                args.B.mode,
                args.A.swizzle,
                args.B.swizzle,
                A_stride,
                B_stride,
                out_stride,
            )
        )
        if not cls._valid_operands(operands):
            return
        yield operands

    @classmethod
    def _metadata_operand_combinations(
        cls,
    ) -> Generator[GemmOperandsMetadata, None, None]:
        """Every MXFP8 operand combination this operator supports."""
        strides = ((0, 0, 1), (0, 1, 0))
        for a_dtype, b_dtype in itertools.product(_FP8_DTYPES, repeat=2):
            for out_dtype in cls._valid_acc_out_combinations[cutlass.Float32]:
                for stride_A, stride_B, stride_out in itertools.product(
                    strides, repeat=3
                ):
                    yield Sm100BlockscaledStaticPersistentOperator._construct_divisible_operands(
                        a_dtype,
                        b_dtype,
                        _SF_DTYPE,
                        _SF_DTYPE,
                        out_dtype,
                        cutlass.Float32,
                        _SCALE_MODE,
                        _SCALE_MODE,
                        _SCALE_SWIZZLE,
                        _SCALE_SWIZZLE,
                        stride_A,
                        stride_B,
                        stride_out,
                    )

    def _supports(
        self, args: GemmArguments, target_sm: TargetSm | None = None
    ) -> Status:
        """Epilogue support (base) plus the scale buffers' element counts.

        A scale tensor may take any shape; its data is in the layout named
        by the operand's swizzle, so the check is on the element count that
        layout needs for the operand's logical shape.
        """
        if not (status := super()._supports(args, target_sm)):
            return status

        M, N = args.out.shape[-2:]
        K = args.A.shape[-1]
        L = args.A.shape[0] if len(args.A.shape) == 3 else 1
        for name, operand, outer in (("A", args.A, M), ("B", args.B, N)):
            expected = ScaledOperand.numel_scale(
                (L, outer, K), operand.mode, operand.swizzle
            )
            if operand.scale.numel() != expected:
                return Status.fail(
                    f"Scale factor {name} must have {expected} elements for the "
                    f"{operand.swizzle} layout of a ({L}, {outer}, {K}) operand; "
                    f"its shape is {tuple(operand.scale.shape)}."
                )
        return Status.success()
