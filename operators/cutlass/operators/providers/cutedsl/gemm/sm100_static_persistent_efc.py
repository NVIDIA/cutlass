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

"""Operator-API wrapper for the SM100 persistent dense GEMM with EFC epilogues.

``Sm100PersistentDenseGemmEFCOperator`` adds the dense-operand rules (dtype
menus including fp8 mixing, majors, alignment) and the SM100 design menus to
the shared ``_PersistentDenseGemmEFCOperatorBase``
(``static_persistent_efc_base``).  Its kernel, ``PersistentDenseGemmEFCKernel``,
is a batch-layout adapter over the example ``DenseGemmEFC``.
"""

from __future__ import annotations

import itertools
from typing import TYPE_CHECKING

import cutlass

import cutlass.operators.utils.generate as generate
from cutlass.operators.arguments import (
    DenseTensor,
    GemmArguments,
)
from cutlass.operators.metadata import (
    GemmOperandsMetadata,
)
from cutlass.operators.providers.cutedsl import CuTeDSLProvider
from cutlass.operators.utils.deprecation import deprecated_module_attributes
from cutlass.operators.utils.tensor import (
    normalized_major_stride,
)

from .implementations.sm100_static_persistent_efc_impl import (
    PersistentDenseGemmEFCKernel,
)
from .static_persistent_efc_base import _PersistentDenseGemmEFCOperatorBase

if TYPE_CHECKING:
    from collections.abc import Generator


@CuTeDSLProvider.register
class Sm100PersistentDenseGemmEFCOperator(_PersistentDenseGemmEFCOperatorBase):
    """SM100 persistent dense GEMM with custom epilogue fusion via EFC.

    Discovery / compile / run wrapper registered with the CuTe DSL provider for
    ``GemmArguments`` with dense A/B.  Each instance is built from an
    ``OperatorMetadata`` describing one kernel configuration; the shared base
    converts the traced epilogue (if any) into an EFC epilogue function via
    ``EFCConverter`` and instantiates a ``PersistentDenseGemmEFCKernel`` to run
    it.  The kernel provides the GEMM mainloop, TMA memory operations, warp
    specialization, and persistent tile scheduling; this class adds the dense
    operand rules.

    Args:
        metadata (OperatorMetadata): One validated kernel configuration
            (operands, design, and optional epilogue) to instantiate.

    Note:
        Supported A/B data types: Float16, BFloat16, Int8, Uint8,
        Float8E4M3FN, Float8E5M2.  A and B must share a dtype, except that
        the two fp8 formats may mix (the f8f6f4 MMA kind decodes each
        operand's format independently).

    Note:
        Supported accumulator dtypes per A/B dtype: see
        ``_valid_ab_acc_combinations``.  Supported output dtypes per
        accumulator: see ``_valid_acc_out_combinations``.

    Note:
        Design constraints (see ``_valid_design``): MMA tiler M is 64/128
        (1-CTA) or 128/256 (2-CTA); MMA tiler N is 32-256 in steps of 32;
        cluster M is a multiple of 2 when ``use_2cta_mma``; cluster M/N are
        positive powers of 2 with product <= 16.
    """

    supported_args_type = GemmArguments
    designed_for_min_cc = 100
    _shim_kernel_type = PersistentDenseGemmEFCKernel

    _valid_ab_acc_combinations = {
        cutlass.Float16: [cutlass.Float16, cutlass.Float32],
        cutlass.BFloat16: [cutlass.Float32],
        cutlass.Uint8: [cutlass.Int32],
        cutlass.Int8: [cutlass.Int32],
        cutlass.Float8E4M3FN: [cutlass.Float16, cutlass.Float32],
        cutlass.Float8E5M2: [cutlass.Float16, cutlass.Float32],
    }

    _mixable_ab_dtypes = (cutlass.Float8E4M3FN, cutlass.Float8E5M2)

    # Operator names keep the stem of the class name before the rename.  Treat
    # ``operator_name`` as an opaque identifier; select operators of this class
    # with ``metadata.operator_class``.
    _operator_name_stem = "PersistentDenseGemmEFCOperator"

    @classmethod
    def _valid_operands(cls, operands: GemmOperandsMetadata) -> bool:
        if not isinstance(operands, GemmOperandsMetadata):
            return False

        a_dtype = operands.A.dtype
        b_dtype = operands.B.dtype
        if a_dtype != b_dtype and not (
            a_dtype in cls._mixable_ab_dtypes and b_dtype in cls._mixable_ab_dtypes
        ):
            return False

        if a_dtype not in cls._valid_ab_acc_combinations:
            return False

        acc_dtype = operands.accumulator_type
        if acc_dtype not in cls._valid_ab_acc_combinations[a_dtype]:
            return False

        if operands.out.dtype not in cls._valid_acc_out_combinations.get(acc_dtype, ()):
            return False

        valid_major_strides = {(0, 0, 1), (0, 1, 0)}
        return all(
            operand.stride in valid_major_strides
            for operand in (operands.A, operands.B, operands.out)
        )

    @classmethod
    def _valid_tile_shape(cls, design) -> bool:
        """SM100 tile-M law: the full MMA tiler M is one instruction M."""
        use_2cta = design.use_2cta_mma
        return (not use_2cta and design.tile_shape[0] in (64, 128)) or (
            use_2cta and design.tile_shape[0] in (128, 256)
        )

    @classmethod
    def _tile_n_menu(cls) -> tuple[int, ...]:
        return tuple(range(32, 257, 32))

    @classmethod
    def _tile_m_candidates(cls, use_2cta_mma: bool) -> tuple[int, ...]:
        # The instruction M values of each CTA mode (see _valid_tile_shape).
        return (128, 256) if use_2cta_mma else (64, 128)

    @classmethod
    def _tile_n_candidates(cls) -> tuple[int, ...]:
        # Enumerates the power-of-two N tiles; _valid_design accepts every
        # multiple of 32 for designs supplied explicitly.
        return (32, 64, 128, 256)

    @classmethod
    def _metadata_operands_from_args(
        cls,
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
        if any(not isinstance(arg, DenseTensor) for arg in [args.A, args.B, args.out]):
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

        operands = generate.construct_dense_gemm_operands(
            args.A.dtype,
            args.B.dtype,
            args.out.dtype,
            args.accumulator_type,
            A_stride,
            B_stride,
            out_stride,
            alignment_bytes=16,
        )

        if not cls._valid_operands(operands):
            return

        yield operands

    @classmethod
    def _metadata_operand_combinations(
        cls,
    ) -> Generator[GemmOperandsMetadata, None, None]:
        """Generator that yields all valid GemmOperandsMetadata combinations
        based on the validation rules in _valid_operands.
        """
        row_major_stride = (0, 0, 1)
        col_major_stride = (0, 1, 0)
        strides = (row_major_stride, col_major_stride)

        for a_dtype, valid_acc_dtypes in cls._valid_ab_acc_combinations.items():
            b_dtypes = (
                cls._mixable_ab_dtypes
                if a_dtype in cls._mixable_ab_dtypes
                else (a_dtype,)
            )
            for b_dtype, acc_dtype in itertools.product(b_dtypes, valid_acc_dtypes):
                for out_dtype in cls._valid_acc_out_combinations[acc_dtype]:
                    for stride_A, stride_B, stride_out in itertools.product(
                        strides, repeat=3
                    ):
                        yield generate.construct_dense_gemm_operands(
                            a_dtype,
                            b_dtype,
                            out_dtype,
                            acc_dtype,
                            stride_A,
                            stride_B,
                            stride_out,
                            alignment_bytes=16,
                        )


__getattr__ = deprecated_module_attributes(
    __name__,
    {
        "PersistentDenseGemmEFCOperator": f"{__name__}.Sm100PersistentDenseGemmEFCOperator",
        "Operand": "cutlass.operators.Operand",
        "TensorWrapper": "cutlass.operators.utils.tensor.TensorWrapper",
    },
)

if TYPE_CHECKING:
    # Type-checker view of the moved names above (PEP 702), so pyrefly, mypy and
    # pyright can flag their use.  Runtime access goes through ``__getattr__``.
    from typing_extensions import deprecated

    from cutlass.operators import Operand as _Operand
    from cutlass.operators.utils.tensor import TensorWrapper as _TensorWrapper

    @deprecated(
        "Use cutlass.operators.providers.cutedsl.gemm.sm100_static_persistent_efc."
        "Sm100PersistentDenseGemmEFCOperator instead."
    )
    class PersistentDenseGemmEFCOperator(Sm100PersistentDenseGemmEFCOperator): ...

    @deprecated("Use cutlass.operators.Operand instead.")
    class Operand(_Operand): ...

    @deprecated("Use cutlass.operators.utils.tensor.TensorWrapper instead.")
    class TensorWrapper(_TensorWrapper): ...
