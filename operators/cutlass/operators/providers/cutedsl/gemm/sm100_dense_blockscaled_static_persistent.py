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

from __future__ import annotations

import itertools
from typing import TYPE_CHECKING

import cutlass
import cutlass.cute as cute
import cutlass.utils as utils
from cutlass.cute.nvgpu.common import OperandMajorMode

from cutlass.operators.arch import TargetSm
from cutlass.operators.arguments import (
    DenseTensor,
    EpilogueArguments,
    GemmArguments,
    ScaledOperand,
    ScaleMode,
    ScaleSwizzleMode,
)
from cutlass.operators.metadata import (
    DenseTensorConstraints,
    DesignMetadata,
    EpilogueMetadata,
    GemmOperandsMetadata,
    OperatorMetadata,
    ScaledOperandConstraints,
    Sm100DesignMetadata,
)
from cutlass.operators.mma import BlackwellTcgen05Mma
from cutlass.operators.providers.cutedsl import CuTeDSLProvider
from cutlass.operators.providers.cutedsl import integration_utils as cutedsl_utils
from cutlass.operators.providers.cutedsl.operator import CuteDslOperator
from cutlass.operators.status import Status
from cutlass.operators.utils.common import tuple_to_string
from cutlass.operators.utils.device import to_cuda_stream
from cutlass.operators.utils.tensor import (
    normalized_major_stride,
    strides_to_layout_string,
)

from .implementations.sm100_dense_blockscaled_static_persistent_impl import (
    PersistentDenseBlockScaledGemmKernel,
)

if TYPE_CHECKING:
    from collections.abc import Callable, Generator

    from cutlass.operators.artifact import CompiledArtifact


@CuTeDSLProvider.register
class PersistentDenseBlockScaledGemmOperator(CuteDslOperator):
    supported_args_type = GemmArguments
    designed_for_min_cc = 100

    def __init__(self, metadata: OperatorMetadata):
        super().__init__(metadata)
        self.sf_vec_size = ScaleMode.numel(metadata.operands.A.mode)
        mma_tiler_mn = (metadata.design.tile_shape[0], metadata.design.tile_shape[1])
        cluster_shape_mn = (
            metadata.design.cluster_shape[0],
            metadata.design.cluster_shape[1],
        )
        self.impl = PersistentDenseBlockScaledGemmKernel(
            self.sf_vec_size,
            mma_tiler_mn,
            cluster_shape_mn,
        )

    def _supports(
        self, args: GemmArguments, target_sm: TargetSm | None = None
    ) -> Status:
        M, N = args.out.shape[-2:]
        K = args.A.shape[-1]
        L = args.A.shape[0] if len(args.A.shape) == 3 else 1

        # Shapes of scale factor tensors are not enforced. It is expected that the
        # data underlying the passed in scale factor tensor is in the layout named
        # by the operand's swizzle. We check only that the number of elements is
        # correct for that layout, given the operand's logical shape.
        expected_sfa_elements = ScaledOperand.numel_scale(
            (L, M, K), args.A.mode, args.A.swizzle
        )
        expected_sfb_elements = ScaledOperand.numel_scale(
            (L, N, K), args.B.mode, args.B.swizzle
        )

        if args.A.scale.numel() != expected_sfa_elements:
            return Status.fail(
                f"Scale factor A for tensor A of shape {args.A.shape} must have "
                f"{expected_sfa_elements} elements. Scale factor A is of shape {args.A.scale.shape} "
                f"and has {args.A.scale.numel()} elements."
            )
        if args.B.scale.numel() != expected_sfb_elements:
            return Status.fail(
                f"Scale factor B for tensor B of shape {args.B.shape} must have "
                f"{expected_sfb_elements} elements. Scale factor B is of shape {args.B.scale.shape} "
                f"and has {args.B.scale.numel()} elements."
            )

        return Status.success()

    def _construct_pointers(
        self, args: GemmArguments, nullptr: bool = False
    ) -> tuple[cute.Pointer, cute.Pointer, cute.Pointer, cute.Pointer, cute.Pointer]:
        gmem = cutlass.AddressSpace.gmem
        a_ptr = cutedsl_utils.builders.make_ptr(
            args.A.tensor, nullptr=nullptr, address_space=gmem, assumed_align=16
        )
        b_ptr = cutedsl_utils.builders.make_ptr(
            args.B.tensor, nullptr=nullptr, address_space=gmem, assumed_align=16
        )
        out_ptr = cutedsl_utils.builders.make_ptr(
            args.out.tensor, nullptr=nullptr, address_space=gmem, assumed_align=16
        )
        sfa_ptr = cutedsl_utils.builders.make_ptr(
            args.A.scale, nullptr=nullptr, address_space=gmem, assumed_align=32
        )
        sfb_ptr = cutedsl_utils.builders.make_ptr(
            args.B.scale, nullptr=nullptr, address_space=gmem, assumed_align=32
        )
        return a_ptr, b_ptr, out_ptr, sfa_ptr, sfb_ptr

    @staticmethod
    def _major_modes(
        args: GemmArguments | GemmOperandsMetadata,
    ) -> tuple[
        tuple[OperandMajorMode, str],
        tuple[OperandMajorMode, str],
        tuple[utils.LayoutEnum, str],
    ]:
        # A, B, and out can be of rank 2 or 3. Extract the final two dimensions
        # to determine the major mode
        a_major_mode = (
            (OperandMajorMode.K, "k")
            if args.A.stride[-2:].index(1) == 1
            else (OperandMajorMode.MN, "m")
        )

        b_major_mode = (
            (OperandMajorMode.K, "k")
            if args.B.stride[-2:].index(1) == 0
            else (OperandMajorMode.MN, "n")
        )

        if args.out.stride[-2:].index(1) == 1:
            out_layout = (utils.LayoutEnum.ROW_MAJOR, "n")
        else:
            out_layout = (utils.LayoutEnum.COL_MAJOR, "m")

        return a_major_mode, b_major_mode, out_layout

    def _compile(
        self, args: GemmArguments, target_sm: TargetSm | None = None
    ) -> CompiledArtifact:
        stream = cutlass.cute.runtime.make_fake_stream()
        max_active_clusters = cutedsl_utils.mma.get_max_active_clusters(
            self.impl.cluster_shape_mn
        )

        a_ptr, b_ptr, out_ptr, sfa_ptr, sfb_ptr = self._construct_pointers(
            args, nullptr=True
        )
        fake_problem_shape = (
            cutlass.Int32(0),
            cutlass.Int32(0),
            cutlass.Int32(0),
            cutlass.Int32(0),
        )

        def epilogue_op(x):
            return x

        (a_major_mode, _), (b_major_mode, _), (out_layout, _) = (
            PersistentDenseBlockScaledGemmOperator._major_modes(args)
        )

        return self.cute_compile(
            self.impl,
            a_ptr,
            b_ptr,
            sfa_ptr,
            sfb_ptr,
            out_ptr,
            (a_major_mode, b_major_mode, out_layout),
            fake_problem_shape,
            max_active_clusters,
            stream,
            epilogue_op,
            target_sm=target_sm,
        )

    def _run(
        self,
        args: GemmArguments,
        compiled_artifact: CompiledArtifact,
        stream,
        workspace=None,
    ) -> None:
        stream = to_cuda_stream(stream)
        compiled_gemm = compiled_artifact.compiled_obj

        M, N = args.out.shape[-2:]
        K = args.A.shape[-1]
        L = args.A.shape[0] if len(args.A.shape) == 3 else 1

        a_ptr, b_ptr, out_ptr, sfa_ptr, sfb_ptr = self._construct_pointers(args)
        self.cute_run(
            compiled_gemm, a_ptr, b_ptr, sfa_ptr, sfb_ptr, out_ptr, (M, N, K, L), stream
        )

    @staticmethod
    def _valid_operands(operands: GemmOperandsMetadata) -> bool:
        if not isinstance(operands, GemmOperandsMetadata):
            return False

        # A and B may have the same element type or form a mixed MXFP4 x MXFP8
        # pair (handled below by is_valid_dtypes_and_scale_factor_vec_size).
        # The scale factors A and B must share the same dtype, scale mode, and
        # swizzle mode.
        if operands.A.scale.dtype != operands.B.scale.dtype:
            return False

        if operands.A.mode != operands.B.mode or operands.A.mode not in [
            ScaleMode.Blockwise1x16,
            ScaleMode.Blockwise1x32,
        ]:
            return False

        if (
            operands.A.swizzle != operands.B.swizzle
            or operands.A.swizzle != ScaleSwizzleMode.Swizzle32x4x4
        ):
            return False

        if operands.accumulator_type != cutlass.Float32:
            return False

        a_dtype = operands.A.dtype
        b_dtype = operands.B.dtype
        sf_dtype = operands.A.scale.dtype
        out_dtype = operands.out.dtype

        impl = PersistentDenseBlockScaledGemmKernel
        if not impl.is_valid_dtypes_and_scale_factor_vec_size(
            a_dtype, b_dtype, sf_dtype, ScaleMode.numel(operands.A.mode), out_dtype
        ):
            return False

        (_, a_major), (_, b_major), (_, out_major) = (
            PersistentDenseBlockScaledGemmOperator._major_modes(operands)
        )
        if not impl.is_valid_layouts(
            a_dtype, b_dtype, out_dtype, a_major, b_major, out_major
        ):
            return False

        return True

    @staticmethod
    def _valid_design_metadata(design: DesignMetadata) -> bool:
        if not isinstance(design, Sm100DesignMetadata):
            return False

        mma_tiler_mn = design.tile_shape[:2]
        cluster_shape_mn = design.cluster_shape[:2]
        impl = PersistentDenseBlockScaledGemmKernel
        return impl.is_valid_mma_tiler_and_cluster_shape(mma_tiler_mn, cluster_shape_mn)

    @staticmethod
    def _valid_epilogue_metadata(epilogue: EpilogueMetadata | None) -> bool:
        return epilogue is None

    @staticmethod
    def _valid_metadata(metadata: OperatorMetadata) -> bool:
        if not PersistentDenseBlockScaledGemmOperator._valid_operands(
            metadata.operands
        ):
            return False
        if not PersistentDenseBlockScaledGemmOperator._valid_design_metadata(
            metadata.design
        ):
            return False
        if not PersistentDenseBlockScaledGemmOperator._valid_epilogue_metadata(
            metadata.epilogue
        ):
            return False
        return True

    @staticmethod
    def _construct_divisible_operands(
        a_dtype: cutlass.Numeric,
        b_dtype: cutlass.Numeric,
        sfa_dtype: cutlass.Numeric,
        sfb_dtype: cutlass.Numeric,
        out_dtype: cutlass.Numeric,
        acc_dtype: cutlass.Numeric,
        sfa_scale_mode: ScaleMode,
        sfb_scale_mode: ScaleMode,
        sfa_swizzle: ScaleSwizzleMode,
        sfb_swizzle: ScaleSwizzleMode,
        stride_A: tuple[int, ...],
        stride_B: tuple[int, ...],
        stride_out: tuple[int, ...],
    ) -> GemmOperandsMetadata:
        """Constructs a GemmOperandsMetadata object based on the provided data types and strides and
        with divisibility constraints set based on those required by the kernel.
        """
        alignment_bytes = 16
        a_divisibility = alignment_bytes * 8 // a_dtype.width
        b_divisibility = alignment_bytes * 8 // b_dtype.width
        out_divisibility = alignment_bytes * 8 // out_dtype.width

        # Mixed pairs (e.g. MXFP4 x MXFP8) load the sub-byte operand via the UNPACK
        # TMA, whose contiguous dim must be a multiple of 128 elements.
        # Encoding it as divisibility makes discovery reject unsupported shapes
        unpack_contiguous_divisibility = 128
        if PersistentDenseBlockScaledGemmKernel.needs_unpack_tma(a_dtype, b_dtype):
            if a_dtype.width < 8:
                a_divisibility = max(a_divisibility, unpack_contiguous_divisibility)
            if b_dtype.width < 8:
                b_divisibility = max(b_divisibility, unpack_contiguous_divisibility)

        sf_alignment_bytes = 32
        sfa_divisibility = sf_alignment_bytes * 8 // sfa_dtype.width
        sfb_divisibility = sf_alignment_bytes * 8 // sfb_dtype.width

        return GemmOperandsMetadata(
            A=ScaledOperandConstraints(
                quantized=DenseTensorConstraints(
                    dtype=a_dtype,
                    stride=stride_A,
                    divisibility=a_divisibility,
                ),
                scale=DenseTensorConstraints(
                    dtype=sfa_dtype,
                    stride=None,
                    divisibility=sfa_divisibility,
                ),
                mode=sfa_scale_mode,
                swizzle=sfa_swizzle,
            ),
            B=ScaledOperandConstraints(
                quantized=DenseTensorConstraints(
                    dtype=b_dtype,
                    stride=stride_B,
                    divisibility=b_divisibility,
                ),
                scale=DenseTensorConstraints(
                    dtype=sfb_dtype,
                    stride=None,
                    divisibility=sfb_divisibility,
                ),
                mode=sfb_scale_mode,
                swizzle=sfb_swizzle,
            ),
            out=DenseTensorConstraints(
                dtype=out_dtype,
                stride=stride_out,
                divisibility=out_divisibility,
            ),
            accumulator_type=acc_dtype,
        )

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
        if any(not isinstance(x, ScaledOperand) for x in [args.A, args.B]):
            return
        if not isinstance(args.out, DenseTensor):
            return
        if any(not isinstance(x.scale, DenseTensor) for x in [args.A, args.B]):
            return

        valid_major_strides = {(0, 0, 1), (0, 1, 0)}

        A_stride = normalized_major_stride(
            args.A.shape, args.A.stride, prepend_zeros_to_rank=3
        )
        B_stride = normalized_major_stride(
            args.B.shape, args.B.stride, prepend_zeros_to_rank=3
        )
        out_stride = normalized_major_stride(
            args.out.shape, args.out.stride, prepend_zeros_to_rank=3
        )

        if any(x not in valid_major_strides for x in [A_stride, B_stride, out_stride]):
            return

        yield PersistentDenseBlockScaledGemmOperator._construct_divisible_operands(
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

    @staticmethod
    def _metadata_operand_combinations() -> Generator[
        tuple[GemmOperandsMetadata, int], None, None
    ]:
        """Generator that yields all valid (GemmOperandsMetadata, sf_vec_size) combinations
        based on the validation rules in _valid_operands.
        """
        valid_dtypes = [cutlass.Float8E5M2, cutlass.Float8E4M3FN, cutlass.Float4E2M1FN]

        out_dtypes = [
            cutlass.Float32,
            cutlass.Float16,
            cutlass.BFloat16,
            cutlass.Float8E4M3FN,
            cutlass.Float8E5M2,
        ]

        sf_dtypes = [
            cutlass.Float8E8M0FNU,
            cutlass.Float8E4M3FN,
        ]

        scale_modes = [ScaleMode.Blockwise1x16, ScaleMode.Blockwise1x32]

        row_major_stride = (0, 0, 1)
        col_major_stride = (0, 1, 0)

        def major_str_a(major_tuple: tuple[int, int, int]) -> str:
            return "k" if major_tuple == row_major_stride else "m"

        def major_str_b(major_tuple: tuple[int, int, int]) -> str:
            return "n" if major_tuple == row_major_stride else "k"

        def major_str_out(major_tuple: tuple[int, int, int]) -> str:
            return "n" if major_tuple == row_major_stride else "m"

        Impl = PersistentDenseBlockScaledGemmKernel

        for a_dtype, b_dtype, sf_dtype, scale_mode, out_dtype in itertools.product(
            valid_dtypes, valid_dtypes, sf_dtypes, scale_modes, out_dtypes
        ):
            sf_vec_size = scale_mode[-1]
            if not Impl.is_valid_dtypes_and_scale_factor_vec_size(
                a_dtype, b_dtype, sf_dtype, sf_vec_size, out_dtype
            ):
                continue

            for stride_A, stride_B, stride_out in itertools.product(
                [row_major_stride, col_major_stride], repeat=3
            ):
                a_major = major_str_a(stride_A)
                b_major = major_str_b(stride_B)
                out_major = major_str_out(stride_out)

                if not Impl.is_valid_layouts(
                    a_dtype, b_dtype, out_dtype, a_major, b_major, out_major
                ):
                    continue

                yield PersistentDenseBlockScaledGemmOperator._construct_divisible_operands(
                    a_dtype,
                    b_dtype,
                    sf_dtype,
                    sf_dtype,
                    out_dtype,
                    cutlass.Float32,
                    scale_mode,
                    scale_mode,
                    ScaleSwizzleMode.Swizzle32x4x4,
                    ScaleSwizzleMode.Swizzle32x4x4,
                    stride_A,
                    stride_B,
                    stride_out,
                )

    @classmethod
    def _generate_operators(
        cls,
        metadata_filter: Callable[[OperatorMetadata], bool],
        epilogue_args: EpilogueArguments = None,
        target_sm: TargetSm | None = None,
        args: GemmArguments = None,
    ) -> list[PersistentDenseBlockScaledGemmOperator]:
        """Returns a list of all possible configurations of PersistentDenseBlockScaledGemmOperator that
        adhere to constraints passed in under kwargs.
        """
        design_params = {
            "mma_instruction_type": [BlackwellTcgen05Mma],
            "use_2cta_mma": [True],
            "tile_shape": [
                # Fill in tile shape K based on data type
                (M, N, None)
                for M in [128, 256]
                for N in [64, 128, 192]
            ],
            "cluster_shape": [(M, N, 1) for M in [2, 4] for N in [1, 2, 4]],
            "use_tma_store": [True],
        }

        if epilogue_args is not None:
            return []

        from itertools import product

        # Get the list of tunable parameter names and their possible values
        param_names = list(design_params.keys())

        operator_list = []

        if args is not None:
            operands_generator = cls._metadata_operands_from_args(args)
        else:
            operands_generator = cls._metadata_operand_combinations()

        for operands in operands_generator:
            if not cls._valid_operands(operands):
                continue

            tile_k = BlackwellTcgen05Mma.shape_k(operands) * 4
            design_params["tile_shape"] = [
                (M, N, tile_k) for M, N, _ in design_params["tile_shape"]
            ]
            param_values = [design_params[name] for name in param_names]
            for values in product(*param_values):
                design = Sm100DesignMetadata(**dict(zip(param_names, values)))
                operator_name = "cutedsl.PersistentDenseBlockScaledGemmOperator_sm100_{layout}_A{A}_B{B}_out{out}_SFA{SFA}_SFB{SFB}_acc{acc}_scale{scale_mode}_swizzle{scale_swizzle}_{num_cta}cta_cluster{cluster}_tile{tile}{_tma_store}".format(
                    layout=strides_to_layout_string(
                        operands.A.stride, operands.B.stride, operands.out.stride
                    ),
                    A=operands.A.dtype,
                    B=operands.B.dtype,
                    out=operands.out.dtype,
                    SFA=operands.A.scale.dtype,
                    SFB=operands.B.scale.dtype,
                    acc=operands.accumulator_type,
                    scale_mode=operands.A.mode,
                    scale_swizzle=operands.A.swizzle,
                    num_cta=("2" if design.use_2cta_mma else "1"),
                    cluster=tuple_to_string(design.cluster_shape),
                    tile=tuple_to_string(design.tile_shape),
                    _tma_store="_tma_store" if design.use_tma_store else "",
                )

                metadata = OperatorMetadata(
                    operands=operands,
                    design=design,
                    operator_name=operator_name,
                    operator_class=cls,
                    supported_targets=TargetSm.get_supported_targets(design, operands),
                    epilogue=None,
                )

                metadata_valid = PersistentDenseBlockScaledGemmOperator._valid_metadata(
                    metadata
                )

                if metadata_valid and metadata_filter(metadata):
                    operator_list.append(
                        PersistentDenseBlockScaledGemmOperator(metadata)
                    )

        return operator_list
