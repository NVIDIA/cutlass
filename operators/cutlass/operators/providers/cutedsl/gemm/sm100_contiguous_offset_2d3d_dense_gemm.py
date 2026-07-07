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

from cutlass.operators.arch import TargetSm
from cutlass.operators.arguments import (
    DenseTensor,
    EpilogueArguments,
    GroupedGemmArguments,
)
from cutlass.operators.metadata import (
    DenseTensorConstraints,
    DesignMetadata,
    EpilogueMetadata,
    GroupedGemmOperandsMetadata,
    OperatorMetadata,
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
from cutlass.operators.utils.gemm import (
    tensor_output_shape_matches,
    tensor_reduction_mode_matches,
)
from cutlass.operators.utils.tensor import (
    normalized_major_stride,
    strides_to_layout_string,
)

from .implementations.sm100_contiguous_offset_2d3d_dense_gemm_impl import (
    ContiguousOffset2D3DGemmDenseKernel,
)

if TYPE_CHECKING:
    from collections.abc import Callable, Generator

    from cutlass.operators.artifact import CompiledArtifact


@CuTeDSLProvider.register
class ContiguousOffset2D3DGemmDenseOperator(CuteDslOperator):
    supported_args_type = GroupedGemmArguments
    designed_for_min_cc = 100

    def __init__(self, metadata: OperatorMetadata):
        super().__init__(metadata)
        mma_tiler_mn = (metadata.design.tile_shape[0], metadata.design.tile_shape[1])
        cluster_shape_mn = (
            metadata.design.cluster_shape[0],
            metadata.design.cluster_shape[1],
        )
        self.impl = ContiguousOffset2D3DGemmDenseKernel(
            metadata.operands.accumulator_type,
            metadata.design.use_2cta_mma,
            mma_tiler_mn,
            cluster_shape_mn,
        )

    def _supports(
        self, args: GroupedGemmArguments, target_sm: TargetSm | None = None
    ) -> Status:
        if not (status := tensor_reduction_mode_matches(args)):
            return status

        if not (status := tensor_output_shape_matches(args)):
            return status

        if len(args.A.shape) == 3 and args.A.shape[0] != 1:
            return Status.fail("Operand A must have batch size 1.")

        if len(args.out.shape) == 3 and args.out.shape[0] != 1:
            return Status.fail("out must have batch size 1.")

        ValidM, N = args.out.shape[-2:]
        K = args.A.shape[-1]
        group_count = args.B.shape[0] if len(args.B.shape) == 3 else 1

        if args.A.shape[-2] != ValidM or args.A.shape[-1] != K:
            return Status.fail(f"A must have shape ({ValidM}, {K}). Got {args.A.shape}")
        if args.B.shape != (group_count, K, N):
            return Status.fail(
                f"B must have shape ({group_count}, {K}, {N}). Got {args.B.shape}"
            )
        if args.out.shape[-2] != ValidM or args.out.shape[-1] != N:
            return Status.fail(
                f"out must have shape ({ValidM}, {N}). Got {args.out.shape}"
            )

        #
        # Check offsets
        #
        if len(args.offsets.shape) != 1:
            return Status.fail(f"offsets must be a 1D tensor. Got {args.offsets.shape}")

        if args.offsets.numel() != group_count:
            return Status.fail(
                f"offsets must have {group_count} elements when offset mode is End and group count is {group_count}."
            )

        return Status.success()

    def _compile(
        self, args: GroupedGemmArguments, target_sm: TargetSm | None = None
    ) -> CompiledArtifact:
        stream = cutlass.cute.runtime.make_fake_stream()
        max_active_clusters = get_max_active_clusters(self.impl.cluster_shape_mn)

        return self.cute_compile(
            self.impl,
            args.A.tensor,
            args.B.tensor,
            args.out.tensor,
            args.offsets.tensor,
            max_active_clusters,
            stream,
            target_sm=target_sm,
        )

    def _run(
        self,
        args: GroupedGemmArguments,
        compiled_artifact: CompiledArtifact,
        stream,
        workspace=None,
    ) -> None:
        stream = to_cuda_stream(stream)
        compiled_gemm = compiled_artifact.compiled_obj
        self.cute_run(
            compiled_gemm,
            args.A.tensor,
            args.B.tensor,
            args.out.tensor,
            args.offsets.tensor,
            stream,
        )

    @staticmethod
    def _valid_operands(operands: GroupedGemmOperandsMetadata) -> bool:
        if operands.accumulator_type != cutlass.Float32:
            return False

        if operands.A.stride[-2:].index(1) != 1:
            # A must be k-major
            return False
        if operands.B.stride[-2:].index(1) != 0:
            # B must be n-major
            return False
        if operands.out.stride[-2:].index(1) != 1:
            # out must be n-major
            return False

        return True

    @staticmethod
    def _valid_design_metadata(design: DesignMetadata) -> bool:
        use_2cta_mma = design.use_2cta_mma
        mma_tiler_mn = design.tile_shape[:2]
        cluster_shape_mn = design.cluster_shape[:2]
        impl = ContiguousOffset2D3DGemmDenseKernel
        return impl.is_valid_mma_tiler_and_cluster_shape(
            use_2cta_mma, mma_tiler_mn, cluster_shape_mn
        )

    @staticmethod
    def _valid_epilogue_metadata(epilogue: EpilogueMetadata | None) -> bool:
        return epilogue is None

    @staticmethod
    def _valid_metadata(metadata: OperatorMetadata) -> bool:
        if not ContiguousOffset2D3DGemmDenseOperator._valid_operands(
            metadata.operands
        ):
            return False
        if not ContiguousOffset2D3DGemmDenseOperator._valid_design_metadata(
            metadata.design
        ):
            return False
        if not ContiguousOffset2D3DGemmDenseOperator._valid_epilogue_metadata(
            metadata.epilogue
        ):
            return False
        return True

    @staticmethod
    def _construct_divisible_operands(
        a_dtype: cutlass.Numeric,
        b_dtype: cutlass.Numeric,
        out_dtype: cutlass.Numeric,
        acc_dtype: cutlass.Numeric,
        stride_A: tuple[int, ...],
        stride_B: tuple[int, ...],
        stride_out: tuple[int, ...],
    ) -> GroupedGemmOperandsMetadata:
        """Constructs a GroupedGemmOperandsMetadata object based on the provided data types and strides and
        with divisibility constraints set based on those required by the kernel.
        """
        alignment_bytes = 16
        offsets_alignment_bytes = 4
        a_divisibility = alignment_bytes * 8 // a_dtype.width
        b_divisibility = alignment_bytes * 8 // b_dtype.width
        out_divisibility = alignment_bytes * 8 // out_dtype.width
        offsets_divisibility = offsets_alignment_bytes * 8 // cutlass.Int32.width

        return GroupedGemmOperandsMetadata(
            A=DenseTensorConstraints(
                dtype=a_dtype,
                stride=stride_A,
                divisibility=a_divisibility,
            ),
            B=DenseTensorConstraints(
                dtype=b_dtype,
                stride=stride_B,
                divisibility=b_divisibility,
            ),
            out=DenseTensorConstraints(
                dtype=out_dtype,
                stride=stride_out,
                divisibility=out_divisibility,
            ),
            offsets=DenseTensorConstraints(
                dtype=cutlass.Int32,
                stride=(1,),
                divisibility=offsets_divisibility,
            ),
            accumulator_type=acc_dtype,
        )

    @staticmethod
    def _metadata_operands_from_args(
        args: GroupedGemmArguments,
    ) -> Generator[GroupedGemmOperandsMetadata, None, None]:
        """Generator that yields all valid GroupedGemmOperandsMetadata that correspond to `args` and
        that are supported by this Operator.

        Args:
            args (GroupedGemmArguments): The arguments to generate operands from.

        Returns:
            Generator[GroupedGemmOperandsMetadata, None, None]: A generator of valid GroupedGemmOperandsMetadata that correspond to `args` and
            that are supported by this Operator.
        """
        if not all(
            isinstance(arg, DenseTensor)
            for arg in [args.A, args.B, args.out, args.offsets]
        ):
            return

        if args.offsets.dtype != cutlass.Int32:
            return

        exp_A_stride = (0, 0, 1)
        exp_B_stride = (0, 1, 0)
        exp_out_stride = (0, 0, 1)

        A_stride = normalized_major_stride(
            args.A.shape, args.A.stride, prepend_zeros_to_rank=3
        )
        B_stride = normalized_major_stride(
            args.B.shape, args.B.stride, prepend_zeros_to_rank=3
        )
        out_stride = normalized_major_stride(
            args.out.shape, args.out.stride, prepend_zeros_to_rank=3
        )

        if A_stride != exp_A_stride:
            return
        if B_stride != exp_B_stride:
            return
        if out_stride != exp_out_stride:
            return

        operands = ContiguousOffset2D3DGemmDenseOperator._construct_divisible_operands(
            args.A.dtype,
            args.B.dtype,
            args.out.dtype,
            args.accumulator_type,
            exp_A_stride,
            exp_B_stride,
            exp_out_stride,
        )

        if not ContiguousOffset2D3DGemmDenseOperator._valid_operands(operands):
            return

        yield operands

    @staticmethod
    def _metadata_operand_combinations() -> Generator[
        tuple[GroupedGemmOperandsMetadata, int], None, None
    ]:
        """Generator that yields all valid (GroupedGemmOperandsMetadata, sf_vec_size) combinations
        based on the validation rules in _valid_operands.
        """
        # Supported A/B data types (must be the same)
        ab_dtypes = [
            cutlass.Float8E5M2,
            cutlass.Float8E4M3FN,
            cutlass.Float16,
            cutlass.BFloat16,
        ]

        out_dtypes = [
            cutlass.Float32,
            cutlass.Float16,
            cutlass.BFloat16,
        ]

        row_major_stride = (0, 0, 1)
        col_major_stride = (0, 1, 0)

        stride_A = row_major_stride
        stride_B = col_major_stride
        stride_out = row_major_stride

        acc_dtype = cutlass.Float32
        Impl = ContiguousOffset2D3DGemmDenseKernel

        for ab_dtype, out_dtype in itertools.product(ab_dtypes, out_dtypes):
            if not Impl.is_valid_dtypes(ab_dtype, acc_dtype, out_dtype):
                continue

            yield ContiguousOffset2D3DGemmDenseOperator._construct_divisible_operands(
                ab_dtype,
                ab_dtype,
                out_dtype,
                acc_dtype,
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
        args: GroupedGemmArguments = None,
    ) -> list[ContiguousOffset2D3DGemmDenseOperator]:
        """Returns a list of all possible configurations of ContiguousOffset2D3DGemmDenseOperator that
        adhere to constraints passed in under kwargs.
        """
        design_params = {
            "mma_instruction_type": [BlackwellTcgen05Mma],
            "use_2cta_mma": [True, False],
            # Fill in tile shape K based on data type
            "tile_shape": [
                (64, 128, None),
                (128, 128, None),
                (256, 128, None),
                (256, 256, None),
            ],
            "cluster_shape": [(M, N, 1) for M in [1, 2, 4] for N in [1, 2, 4]],
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
                operator_name = "cutedsl.ContiguousOffset2D3DGemmDenseOperator_sm100_{layout}_A{A}_B{B}_out{out}_acc{acc}_{num_cta}cta_cluster{cluster}_tile{tile}{_tma_store}".format(
                    layout=strides_to_layout_string(
                        operands.A.stride, operands.B.stride, operands.out.stride
                    ),
                    A=operands.A.dtype,
                    B=operands.B.dtype,
                    out=operands.out.dtype,
                    acc=operands.accumulator_type,
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

                metadata_valid = ContiguousOffset2D3DGemmDenseOperator._valid_metadata(
                    metadata
                )
                if metadata_valid and metadata_filter(metadata):
                    operator_list.append(
                        ContiguousOffset2D3DGemmDenseOperator(metadata)
                    )

        return operator_list
