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
)
from cutlass.operators.metadata import (
    GemmOperandsMetadata,
    OperatorMetadata,
    Sm100DesignMetadata,
)
from cutlass.operators.metadata.design.tile_scheduler import (
    CLCDynamicPersistentTileSchedulerMetadata,
    StaticPersistentTileSchedulerMetadata,
)
from cutlass.operators.mma import BlackwellTcgen05Mma
from cutlass.operators.providers.cutedsl import CuTeDSLProvider
from cutlass.operators.providers.cutedsl.integration_utils.mma import (
    get_max_active_clusters,
)
from cutlass.operators.providers.cutedsl.operator import CuteDslOperator
from cutlass.operators.utils.common import tuple_to_string
from cutlass.operators.utils.device import to_cuda_stream
from cutlass.operators.utils.tensor import (
    normalized_major_stride,
    strides_to_layout_string,
)

from .implementations.operator_helpers import (
    scheduler_metadata_to_enum,
)
from .implementations.sm100_persistent_impl import (
    PersistentDenseGemmKernel,
)

if TYPE_CHECKING:
    from collections.abc import Callable, Generator

    from cutlass.operators.artifact import CompiledArtifact


@CuTeDSLProvider.register
class PersistentDenseGemmOperator(CuteDslOperator):
    """This class implements batched matrix multiplication (C = A @ B) with support for various data types
    and architectural features specific to Blackwell GPUs with persistent tile scheduling and warp specialization.

    :note: In current version, A and B tensor must have the same data type
        - i.e., Float8E4M3FN for A and Float8E5M2 for B is not supported

    :note: Supported A/B data types:
        - Float16/BFloat16
        - Int8/Uint8
        - Float8E4M3FN/Float8E5M2

    :note: Supported accumulator data types:
        - Float32 (for all floating point A/B data types)
        - Float16 (only for fp16 and fp8 A/B data types)
        - Int32 (only for uint8/int8 A/B data types)

    :note: Supported C data types:
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

    def __init__(self, metadata: OperatorMetadata):
        super().__init__(metadata)

        def epilogue_op(x):
            return x

        mma_tiler_mn = (metadata.design.tile_shape[0], metadata.design.tile_shape[1])
        cluster_shape_mn = (
            metadata.design.cluster_shape[0],
            metadata.design.cluster_shape[1],
        )

        self.impl = PersistentDenseGemmKernel(
            metadata.operands.accumulator_type,
            metadata.design.use_2cta_mma,
            mma_tiler_mn,
            cluster_shape_mn,
            metadata.design.use_tma_store,
            scheduler_metadata_to_enum(metadata.design.tile_scheduler),
            epilogue_op,
        )

    def _compile(
        self, args: GemmArguments, target_sm: TargetSm | None = None
    ) -> CompiledArtifact:
        stream = cutlass.cute.runtime.make_fake_stream()
        if self.impl.use_static_persistent_scheduler:
            max_active_clusters = get_max_active_clusters(self.impl.cluster_shape_mn)
        else:
            max_active_clusters = None

        return self.cute_compile(
            self.impl,
            args.A.tensor,
            args.B.tensor,
            args.out.tensor,
            stream,
            max_active_clusters,
            self.impl.epilogue_op,
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
        self.cute_run(
            compiled_gemm, args.A.tensor, args.B.tensor, args.out.tensor, stream
        )

    @staticmethod
    def _valid_operands(operands: GemmOperandsMetadata) -> bool:
        if not isinstance(operands, GemmOperandsMetadata):
            return False

        # In current version, A and B tensor must have the same data type
        # i.e., Float8E4M3FN for A and Float8E5M2 for B is not supported
        if operands.A.dtype != operands.B.dtype:
            return False

        abtype = operands.A.dtype

        # Supported A/B data types:
        #  - Float16/BFloat16
        #  - Int8/Uint8
        #  - Float8E4M3FN/Float8E5M2
        if abtype not in [
            cutlass.Float16,
            cutlass.BFloat16,
            cutlass.Int8,
            cutlass.Uint8,
            cutlass.Float8E4M3FN,
            cutlass.Float8E5M2,
        ]:
            return False

        # Supported accumulator data types:
        #  - Float32 (for all floating point A/B data types)
        #  - Float16 (only for fp16 and fp8 A/B data types)
        #  - Int32 (only for uint8/int8 A/B data types)
        if operands.accumulator_type == cutlass.Float32:
            if not abtype.is_float:
                return False
        elif operands.accumulator_type == cutlass.Float16:
            if abtype not in [
                cutlass.Float16,
                cutlass.Float8E4M3FN,
                cutlass.Float8E5M2,
            ]:
                return False
        elif operands.accumulator_type == cutlass.Int32:
            if abtype not in [cutlass.Uint8, cutlass.Int8]:
                return False
        else:
            return False

        # Supported out data types:
        #  - Float32 (for float32 and int32 accumulator data types)
        #  - Int32 (for float32 and int32 accumulator data types)
        #  - Float16/BFloat16 (for fp16 and fp8 accumulator data types)
        #  - Int8/Uint8 (for uint8/int8 accumulator data types)
        #  - Float8E4M3FN/Float8E5M2 (for float32 accumulator data types)
        if operands.out.dtype == cutlass.Float32 or operands.out.dtype == cutlass.Int32:
            if operands.accumulator_type not in [cutlass.Float32, cutlass.Int32]:
                return False
        elif (
            operands.out.dtype == cutlass.Float16
            or operands.out.dtype == cutlass.BFloat16
        ):
            if operands.accumulator_type not in [
                cutlass.Float32,
                cutlass.Float16,
                cutlass.BFloat16,
            ]:
                return False
        elif operands.out.dtype == cutlass.Int8 or operands.out.dtype == cutlass.Uint8:
            if operands.accumulator_type not in [cutlass.Int32]:
                return False
        elif (
            operands.out.dtype == cutlass.Float8E4M3FN
            or operands.out.dtype == cutlass.Float8E5M2
        ):
            if operands.accumulator_type not in [cutlass.Float32]:
                return False
        else:
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

        if not PersistentDenseGemmOperator._valid_operands(operands):
            return

        yield operands

    @staticmethod
    def _metadata_operand_combinations() -> Generator[GemmOperandsMetadata, None, None]:
        """Generator that yields all valid GemmOperandsMetadata combinations
        based on the validation rules in _valid_operands.
        """
        # Supported A/B data types (must be the same)
        ab_dtypes = [
            cutlass.Float16,
            cutlass.BFloat16,
            cutlass.Int8,
            cutlass.Uint8,
            cutlass.Float8E4M3FN,
            cutlass.Float8E5M2,
        ]

        row_major_stride = (0, 0, 1)
        col_major_stride = (0, 1, 0)

        for ab_dtype in ab_dtypes:
            # Determine valid accumulator types for this A/B dtype
            valid_acc_dtypes = []

            if ab_dtype.is_float:
                valid_acc_dtypes.append(cutlass.Float32)
                if ab_dtype in [
                    cutlass.Float16,
                    cutlass.Float8E4M3FN,
                    cutlass.Float8E5M2,
                ]:
                    valid_acc_dtypes.append(cutlass.Float16)
            else:  # Int8, Uint8
                valid_acc_dtypes.append(cutlass.Int32)

            for acc_dtype in valid_acc_dtypes:
                # Determine valid output types for this accumulator type
                valid_out_dtypes = []

                if acc_dtype == cutlass.Float32:
                    valid_out_dtypes.extend(
                        [
                            cutlass.Float8E4M3FN,
                            cutlass.Float8E5M2,
                            cutlass.Float16,
                            cutlass.BFloat16,
                            cutlass.Float32,
                            cutlass.Int32,
                        ]
                    )
                elif acc_dtype == cutlass.Int32:
                    valid_out_dtypes.extend(
                        [cutlass.Int8, cutlass.Uint8, cutlass.Float32, cutlass.Int32]
                    )
                elif acc_dtype == cutlass.Float16:
                    valid_out_dtypes.extend([cutlass.Float16])

                for out_dtype in valid_out_dtypes:
                    for stride_A, stride_B, stride_out in itertools.product(
                        [row_major_stride, col_major_stride], repeat=3
                    ):
                        operands = generate.construct_dense_gemm_operands(
                            ab_dtype,
                            ab_dtype,
                            out_dtype,
                            acc_dtype,
                            stride_A,
                            stride_B,
                            stride_out,
                            alignment_bytes=16,
                        )
                        yield operands

    @staticmethod
    def _valid_metadata(metadata: OperatorMetadata) -> bool:
        if not PersistentDenseGemmOperator._valid_operands(metadata.operands):
            return False

        design = metadata.design
        if not isinstance(design, Sm100DesignMetadata):
            return False

        cluster_size_m, cluster_size_n, _ = design.cluster_shape

        if cluster_size_m % 2 != 0 and cluster_size_m != 1:
            return False
        if cluster_size_n % 2 != 0 and cluster_size_n != 1:
            return False
        if cluster_size_m * cluster_size_n > 16:
            return False

        tile = design.tile_shape

        # Constraints based on whether 2CTA instructions are used
        if design.use_2cta_mma is not None:
            if design.use_2cta_mma:
                if cluster_size_m % 2 != 0:
                    return False
                if tile is not None and tile[0] not in [
                    128,
                    256,
                ]:
                    return False
            else:
                if tile is not None and tile[0] not in [
                    64,
                    128,
                ]:
                    return False

        if tile is not None and tile[1] not in range(32, 257, 32):
            return False

        if metadata.epilogue is not None:
            return False

        return True

    @classmethod
    def _generate_operators(
        cls,
        metadata_filter: Callable[[OperatorMetadata], bool],
        epilogue_args: EpilogueArguments = None,
        target_sm: TargetSm | None = None,
        args: GemmArguments = None,
    ) -> list[PersistentDenseGemmOperator]:
        """Returns a list of all possible configurations of PersistentDenseGemmOperator that
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
            "tile_scheduler": [
                CLCDynamicPersistentTileSchedulerMetadata(),
                StaticPersistentTileSchedulerMetadata(),
            ],
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
            tile_k = BlackwellTcgen05Mma.shape_k(operands) * 4  # kphase=4
            design_params["tile_shape"] = [
                (M, N, tile_k) for M, N, _ in design_params["tile_shape"]
            ]
            param_values = [design_params[name] for name in param_names]
            for values in product(*param_values):
                design = Sm100DesignMetadata(**dict(zip(param_names, values)))
                operator_name = "cutedsl.PersistentDenseGemmOperator_sm100_{layout}_A{A}_B{B}_out{out}_acc{acc}_{num_cta}cta_cluster{cluster}_tile{tile}_scheduler{scheduler}{_tma_store}".format(
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
                    scheduler=scheduler_metadata_to_enum(design.tile_scheduler).name,
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

                if PersistentDenseGemmOperator._valid_metadata(
                    metadata
                ) and metadata_filter(metadata):
                    operator_list.append(PersistentDenseGemmOperator(metadata))

        return operator_list
