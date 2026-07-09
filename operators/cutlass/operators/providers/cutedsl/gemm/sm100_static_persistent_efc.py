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

import cutlass.operators.utils.generate as generate
from cutlass.operators.arch import TargetSm
from cutlass.operators.arguments import (
    DenseTensor,
    EpilogueArguments,
    GemmArguments,
    Operand,
)
from cutlass.operators.metadata import (
    EpilogueMetadata,
    GemmOperandsMetadata,
    OperatorMetadata,
    Sm100DesignMetadata,
)
from cutlass.operators.mma import BlackwellTcgen05Mma
from cutlass.operators.providers.cutedsl import CuTeDSLProvider
from cutlass.operators.providers.cutedsl.evt.converter import EFCConverter
from cutlass.operators.providers.cutedsl.integration_utils.mma import (
    get_max_active_clusters,
)
from cutlass.operators.providers.cutedsl.operator import CuteDslOperator
from cutlass.operators.status import Status
from cutlass.operators.utils.common import tuple_to_string
from cutlass.operators.utils.device import to_cuda_stream
from cutlass.operators.utils.tensor import (
    TensorWrapper,
    normalized_major_stride,
    strides_to_layout_string,
)

from .implementations.sm100_static_persistent_efc_impl import (
    PersistentDenseGemmEFCKernel,
)

if TYPE_CHECKING:
    from collections.abc import Callable, Generator

    from cutlass.operators.artifact import CompiledArtifact


@CuTeDSLProvider.register
class PersistentDenseGemmEFCOperator(CuteDslOperator):
    """Base class for batched GEMM with custom epilogue fusion using EFC.

    This class provides the core infrastructure for persistent batched GEMM operations
    with customizable epilogue fusion. Subclasses define specific epilogue behaviors
    by providing an epilogue configuration function that describes operations on the
    accumulator and supplemental tensors.

    The class handles:
    - GEMM mainloop (A * B computation)
    - TMA-based memory operations
    - Warp specialization
    - Persistent tile scheduling
    - EFC (Epilogue Fusion Configuration) integration
    - Tensor creation and validation

    :param acc_dtype: Data type for accumulation during MMA computation
    :type acc_dtype: type[cutlass.Numeric]
    :param epi_dtype: Data type for epilogue operation
    :type epi_dtype: type[cutlass.Numeric]
    :param use_2cta_instrs: Whether to use CTA group 2 for 2CTA MMA instructions
    :type use_2cta_instrs: bool
    :param mma_tiler_mn: Shape of the Matrix Multiply-Accumulate (MMA) tile (M,N)
    :type mma_tiler_mn: tuple[int, int]
    :param cluster_shape_mn: Cluster dimensions (M,N) for parallel processing
    :type cluster_shape_mn: tuple[int, int]
    :param epilogue_configuration_function: Function defining the epilogue behavior via EFC
    :type epilogue_configuration_function: Callable

    :note: Supported A/B data types:
        - Float16/BFloat16
        - Int8/Uint8
        - Float8E4M3FN/Float8E5M2
        (A and B must have the same data type)

    :note: Supported accumulator data types:
        - Float32 (for all floating point A/B data types)
        - Float16 (only for fp16 and fp8 A/B data types)
        - Int32 (only for uint8/int8 A/B data types)

    :note: Supported supplemental tensor data types (epilogue-dependent):
        - Float32 (for float32 and int32 accumulator data types)
        - Int32 (for float32 and int32 accumulator data types)
        - Float16/BFloat16 (for fp16 and fp8 accumulator data types)
        - Int8/Uint8 (for uint8/int8 accumulator data types)
        - Float8E4M3FN/Float8E5M2 (for float32 accumulator data types)

    :note: Constraints:
        - MMA tiler M must be 64/128 (use_2cta_instrs=False) or 128/256 (use_2cta_instrs=True)
        - MMA tiler N must be 32-256, step 32
        - Cluster shape M must be multiple of 2 if use_2cta_instrs=True
        - Cluster shape M/N must be positive and power of 2, total cluster size <= 16
    """

    supported_args_type = GemmArguments
    designed_for_min_cc = 100

    _valid_ab_acc_combinations = {
        cutlass.Float16: [cutlass.Float16, cutlass.Float32],
        cutlass.BFloat16: [cutlass.Float32],
        cutlass.Uint8: [cutlass.Int32],
        cutlass.Int8: [cutlass.Int32],
        cutlass.Float8E4M3FN: [cutlass.Float16, cutlass.Float32],
        cutlass.Float8E5M2: [cutlass.Float16, cutlass.Float32],
    }

    def __init__(self, metadata: OperatorMetadata):
        super().__init__(metadata)

        if metadata.epilogue is not None:
            epilogue_op = EFCConverter.convert(
                metadata.epilogue.traced_epilogue.dag_ir,
                metadata.epilogue.parameter_names,
                parameter_tensors=metadata.epilogue.tensors,
            )
        else:
            epilogue_op = EFCConverter.identity_efc

        mma_tiler_mn = (metadata.design.tile_shape[0], metadata.design.tile_shape[1])
        cluster_shape_mn = (
            metadata.design.cluster_shape[0],
            metadata.design.cluster_shape[1],
        )

        self.impl = PersistentDenseGemmEFCKernel(
            metadata.operands.accumulator_type,
            metadata.operands.out.dtype,
            metadata.design.use_2cta_mma,
            mma_tiler_mn,
            cluster_shape_mn,
            epilogue_op,
        )

    @staticmethod
    def _valid_fusion(fusion: EpilogueMetadata) -> Status:
        if not isinstance(fusion, EpilogueMetadata):
            return Status.fail("Unsupported epilogue argument type.")
        if not (status := EFCConverter.supports(fusion.traced_epilogue.dag_ir)):
            return status
        return Status.success()

    @staticmethod
    def _valid_operands(operands: GemmOperandsMetadata) -> Status:
        if not isinstance(operands, GemmOperandsMetadata):
            return False

        if operands.A.dtype != operands.B.dtype:
            return False

        ab_dtype = operands.A.dtype
        acc_dtype = operands.accumulator_type

        if ab_dtype not in PersistentDenseGemmEFCOperator._valid_ab_acc_combinations:
            return False

        # Check compatibility between accumulator type and AB type
        if (
            acc_dtype
            not in PersistentDenseGemmEFCOperator._valid_ab_acc_combinations[ab_dtype]
        ):
            return False

        return True

    @staticmethod
    def _valid_design(design: Sm100DesignMetadata) -> bool:
        """Check if the design metadata is valid.

        :param design: The design metadata
        :type design: Sm100DesignMetadata

        :return: True if the design is valid, False otherwise
        :rtype: bool
        """
        if not isinstance(design, Sm100DesignMetadata):
            return False

        use_2cta_instrs = design.use_2cta_mma
        mma_tiler_mn = design.tile_shape
        cluster_shape_mn = design.cluster_shape

        # Check invalid mma tile shape M dimension
        if not (
            (not use_2cta_instrs and mma_tiler_mn[0] in [64, 128])
            or (use_2cta_instrs and mma_tiler_mn[0] in [128, 256])
        ):
            return False

        # Check invalid mma tile shape N dimension
        if mma_tiler_mn[1] not in range(32, 257, 32):
            return False
        # Check illegal cluster shape M dimension
        if cluster_shape_mn[0] % (2 if use_2cta_instrs else 1) != 0:
            return False

        def is_power_of_2(x):
            return x > 0 and (x & (x - 1)) == 0

        # Check invalid cluster shape constraints
        if cluster_shape_mn[0] * cluster_shape_mn[1] > 16:
            return False
        if cluster_shape_mn[0] <= 0 or cluster_shape_mn[1] <= 0:
            return False
        if not is_power_of_2(cluster_shape_mn[0]) or not is_power_of_2(
            cluster_shape_mn[1]
        ):
            return False

        return True

    @staticmethod
    def _valid_metadata(metadata: OperatorMetadata) -> bool:
        if not PersistentDenseGemmEFCOperator._valid_operands(metadata.operands):
            return False

        if not PersistentDenseGemmEFCOperator._valid_design(metadata.design):
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
        if any(not isinstance(arg, DenseTensor) for arg in [args.A, args.B, args.out]):
            return

        if args.A.dtype != args.B.dtype:
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

        if not PersistentDenseGemmEFCOperator._valid_operands(operands):
            return

        yield operands

    @staticmethod
    def _metadata_operand_combinations() -> Generator[GemmOperandsMetadata, None, None]:
        """Generator that yields all valid GemmOperandsMetadata combinations
        based on the validation rules in _valid_operands.
        """
        row_major_stride = (0, 0, 1)
        col_major_stride = (0, 1, 0)

        for (
            ab_dtype,
            valid_acc_dtypes,
        ) in PersistentDenseGemmEFCOperator._valid_ab_acc_combinations.items():
            for acc_dtype in valid_acc_dtypes:
                # Determine valid output types for this accumulator type
                valid_out_dtypes = []

                if acc_dtype == cutlass.Float32:
                    valid_out_dtypes.extend(
                        [
                            cutlass.Float32,
                            cutlass.Int32,
                            cutlass.Float16,
                            cutlass.BFloat16,
                        ]
                    )
                    # Float8 output types only valid with Float32 accumulator
                    valid_out_dtypes.extend([cutlass.Float8E4M3FN, cutlass.Float8E5M2])
                elif acc_dtype == cutlass.Int32:
                    valid_out_dtypes.extend([cutlass.Float32, cutlass.Int32])
                    # Integer output types only valid with Int32 accumulator
                    valid_out_dtypes.extend([cutlass.Int8, cutlass.Uint8])
                elif acc_dtype == cutlass.Float16:
                    valid_out_dtypes.extend([cutlass.Float16, cutlass.BFloat16])

                for out_dtype in valid_out_dtypes:
                    for stride_A, stride_B, stride_out in itertools.product(
                        [row_major_stride, col_major_stride], repeat=3
                    ):
                        yield generate.construct_dense_gemm_operands(
                            ab_dtype,
                            ab_dtype,
                            out_dtype,
                            acc_dtype,
                            stride_A,
                            stride_B,
                            stride_out,
                            alignment_bytes=16,
                        )

    def _supports(
        self, args: GemmArguments, target_sm: TargetSm | None = None
    ) -> Status:
        if args.epilogue is not None:
            fusion_metadata = EpilogueMetadata.from_args(args.epilogue)
            if not self._valid_fusion(fusion_metadata):
                return Status.fail(
                    "Provided epilogue fusion is not supported by this Operator"
                )

        return Status.success()

    def _compile(
        self, args: GemmArguments, target_sm: TargetSm | None = None
    ) -> CompiledArtifact:
        stream = cutlass.cute.runtime.make_fake_stream()
        max_active_clusters = get_max_active_clusters(self.impl.cluster_shape_mn)

        if args.epilogue is not None:
            epilogue_params = [
                e.compile_time_tensor if isinstance(e, TensorWrapper) else e
                for e in args.epilogue.parameters
            ]
        else:
            epilogue_params = [args.out.tensor.compile_time_tensor]

        # EFC needs special handling for supplemental arguments.
        self.impl.efc.compile(*epilogue_params)
        compiled_artifact = self.cute_compile(
            self.impl,
            args.A.tensor,
            args.B.tensor,
            max_active_clusters,
            stream,
            *epilogue_params,
            target_sm=target_sm,
        )

        return compiled_artifact

    def _run(
        self,
        args: GemmArguments,
        compiled_artifact: CompiledArtifact,
        stream,
        workspace=None,
    ) -> None:
        stream = to_cuda_stream(stream)

        epilogue_params = (
            args.epilogue.parameters if args.epilogue is not None else [args.out]
        )

        # Unwrap Operand wrappers (e.g. DenseTensor) to their
        # underlying TensorWrapper so that cute_run can extract the
        # runtime tensor for TVM FFI.
        epilogue_params = [
            e.tensor if isinstance(e, Operand) else e for e in epilogue_params
        ]

        compiled_gemm = compiled_artifact.compiled_obj
        self.cute_run(
            compiled_gemm, args.A.tensor, args.B.tensor, stream, *epilogue_params
        )

    @classmethod
    def _generate_operators(
        cls,
        metadata_filter: Callable[[OperatorMetadata], bool],
        epilogue_args: EpilogueArguments = None,
        target_sm: TargetSm | None = None,
        args: GemmArguments = None,
    ) -> list[PersistentDenseGemmEFCOperator]:
        """Returns a list of all possible configurations of PersistentDenseGemmEFCOperator that
        adhere to constraints passed in under kwargs.
        """
        design_params = {
            "mma_instruction_type": [BlackwellTcgen05Mma],
            "use_2cta_mma": [True, False],
            # Fill in tile shape K based on data type
            "tile_shape": [
                (M, N, None) for M in [64, 128, 256] for N in [32, 64, 128, 256]
            ],
            "cluster_shape": [
                (M, N, 1) for M in [1, 2, 4, 8, 16] for N in [1, 2, 4, 8, 16]
            ],
            "use_tma_store": [True],
        }

        if epilogue_args is not None:
            if not isinstance(epilogue_args, EpilogueArguments):
                return []

            epilogue_metadata = EpilogueMetadata.from_args(epilogue_args)
            if not PersistentDenseGemmEFCOperator._valid_fusion(epilogue_metadata):
                return []
        else:
            epilogue_metadata = None

        from itertools import product

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
                operator_name = "cutedsl.PersistentDenseGemmEFCOperator_sm100_{layout}_A{A}_B{B}_out{out}_acc{acc}_{num_cta}cta_cluster{cluster}_tile{tile}{_tma_store}".format(
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
                    epilogue=epilogue_metadata,
                )

                if PersistentDenseGemmEFCOperator._valid_metadata(
                    metadata
                ) and metadata_filter(metadata):
                    operator_list.append(PersistentDenseGemmEFCOperator(metadata))

        return operator_list
