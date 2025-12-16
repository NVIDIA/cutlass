# Copyright (c) 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

import itertools
from collections.abc import Callable, Generator

import cutlass

from cutlass_api.arguments import (
    EpilogueArguments,
    GemmArguments,
)
from cutlass_api.artifact import CompiledArtifact
from cutlass_api.metadata import (
    EpilogueMetadata,
    GemmOperandsMetadata,
    KernelMetadata,
    Sm100DesignMetadata,
    TensorAttributes,
)
from cutlass_api.providers.cutedsl import CuTeDSLProvider
from cutlass_api.providers.cutedsl.evt.converter import EFCConverter
from cutlass_api.providers.cutedsl.kernel import CuteDslKernel
from cutlass_api.providers.cutedsl.utils import get_max_active_clusters
from cutlass_api.status import Status
from cutlass_api.utils import (
    TensorWrapper,
    strides_to_layout_string,
    to_cuda_stream,
    tuple_to_string,
)

from .implementations.sm100_static_persistent_efc_impl import (
    PersistentDenseGemmEFCKernelImpl,
)


@CuTeDSLProvider.register
class PersistentDenseGemmEFCKernel(CuteDslKernel):
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
    - CLI argument parsing (extensible via CLIParser.more_parsing())
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
        - TFloat32
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

    _valid_ab_acc_combinations = {
        cutlass.Float16: {cutlass.Float16, cutlass.Float32},
        cutlass.BFloat16: {cutlass.Float32},
        cutlass.TFloat32: {cutlass.Float32},
        cutlass.Uint8: {cutlass.Int32},
        cutlass.Int8: {cutlass.Int32},
        cutlass.Float8E4M3FN: {cutlass.Float16, cutlass.Float32},
        cutlass.Float8E5M2: {cutlass.Float16, cutlass.Float32},
    }

    def __init__(self, metadata: KernelMetadata):
        self.metadata = metadata

        if metadata.epilogue is not None:
            epilogue_op = EFCConverter.convert(
                metadata.epilogue.traced_epilogue.dag_ir,
                metadata.epilogue.parameter_names,
            )
        else:
            epilogue_op = EFCConverter.identity_efc

        mma_tiler_mn = (metadata.design.tile_shape[0], metadata.design.tile_shape[1])
        cluster_shape_mn = (
            metadata.design.cluster_shape[0],
            metadata.design.cluster_shape[1],
        )

        self.impl = PersistentDenseGemmEFCKernelImpl(
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

        if ab_dtype not in PersistentDenseGemmEFCKernel._valid_ab_acc_combinations:
            return False

        # Check compatibility between accumulator type and AB type
        if (
            acc_dtype
            not in PersistentDenseGemmEFCKernel._valid_ab_acc_combinations[ab_dtype]
        ):
            return False

        return True

    @staticmethod
    def _valid_design(design: Sm100DesignMetadata) -> bool:
        """
        Check if the design metadata is valid.

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
    def _valid_metadata(metadata: KernelMetadata) -> bool:
        if not PersistentDenseGemmEFCKernel._valid_operands(metadata.operands):
            return False

        if not PersistentDenseGemmEFCKernel._valid_design(metadata.design):
            return False

        return True

    @staticmethod
    def _metadata_operand_combinations() -> Generator[GemmOperandsMetadata, None, None]:
        """
        Generator that yields all valid GemmOperandsMetadata combinations
        based on the validation rules in _valid_operands.
        """
        row_major_stride = (0, 0, 1)
        col_major_stride = (0, 1, 0)
        alignment = 16

        for (
            ab_dtype,
            valid_acc_dtypes,
        ) in PersistentDenseGemmEFCKernel._valid_ab_acc_combinations.items():
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
                        # Create TensorAttributes for A, B, and out tensors
                        a_attrs = TensorAttributes(
                            dtype=ab_dtype, stride=stride_A, alignment=alignment
                        )
                        b_attrs = TensorAttributes(
                            dtype=ab_dtype, stride=stride_B, alignment=alignment
                        )
                        out_attrs = TensorAttributes(
                            dtype=out_dtype, stride=stride_out, alignment=alignment
                        )

                        # Create and yield the GemmOperandsMetadata
                        operands = GemmOperandsMetadata(
                            A=a_attrs,
                            B=b_attrs,
                            out=out_attrs,
                            accumulator_type=acc_dtype,
                        )

                        yield operands

    def _supports(self, args: GemmArguments) -> Status:
        if args.epilogue is not None:
            fusion_metadata = EpilogueMetadata.from_args(args.epilogue)
            if not self._valid_fusion(fusion_metadata):
                return Status.fail("Provided epilogue fusion is not supported by this kernel")

        return Status.success()

    def compile(self, args: GemmArguments, cc: int = None) -> CompiledArtifact:
        stream = cutlass.cute.runtime.make_fake_stream()
        max_active_clusters = get_max_active_clusters(self.impl.cluster_shape_mn)

        if args.epilogue is not None:
            epilogue_params = args.epilogue.parameters
        else:
            epilogue_params = [args.out]

        epilogue_params = [
            e.compile_time_tensor if isinstance(e, TensorWrapper) else e
            for e in epilogue_params
        ]

        # EFC needs special handling for supplemental arguments
        self.impl.efc.compile(epilogue_params)
        compiled_gemm = self.cute_compile(
            self.impl,
            args.A,
            args.B,
            max_active_clusters,
            stream,
            self.impl.efc.jit.pack_arguments(*epilogue_params),
        )

        # Wrap the compiled kernel to handle supplemental argument packing at launch time
        def wrapped_launch(a_tensor, b_tensor, stream, *supplemental_args):
            runtime_args = [
                e.runtime_tensor if isinstance(e, TensorWrapper) else e
                for e in supplemental_args
            ]
            return compiled_gemm(
                a_tensor,
                b_tensor,
                stream,
                self.impl.efc.jit.pack_arguments(*runtime_args),
            )

        return CompiledArtifact(wrapped_launch, self)

    def _run(
        self,
        args: GemmArguments,
        compiled_artifact: CompiledArtifact,
        stream,
        workspace=None,
    ) -> None:
        stream = to_cuda_stream(stream)

        if args.epilogue is not None:
            epilogue_params = args.epilogue.parameters
        else:
            epilogue_params = [args.out]

        compiled_gemm = compiled_artifact.compiled_obj
        self.cute_run(compiled_gemm, args.A, args.B, stream, *epilogue_params)

    @staticmethod
    def generate_kernels(
        metadata_filter: Callable[[KernelMetadata], bool],
        epilogue_args: EpilogueArguments = None,
        cc: int = None,
    ) -> list["PersistentDenseGemmEFCKernel"]:
        """
        Returns a list of all possible configurations of PersistentDenseGemmEFCKernel that
        adhere to constraints passed in under kwargs.
        """
        if cc is not None and cc not in [100, 101, 103]:
            return []

        design_params = {
            "use_2cta_mma": [True, False],
            "tile_shape": [
                (M, N, 256) for M in [64, 128, 256] for N in [32, 64, 128, 256]
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
            if not PersistentDenseGemmEFCKernel._valid_fusion(epilogue_metadata):
                return []
        else:
            epilogue_metadata = None

        from itertools import product

        param_names = list(design_params.keys())
        param_values = [design_params[name] for name in param_names]

        kernel_list = []
        for operands in PersistentDenseGemmEFCKernel._metadata_operand_combinations():
            for values in product(*param_values):
                design = Sm100DesignMetadata(**dict(zip(param_names, values)))
                kernel_name = "cutedsl.PersistentDenseGemmEFCKernel_sm100_{layout}_A{A}_B{B}_out{out}_acc{acc}_{num_cta}cta_cluster{cluster}_tile{tile}{_tma_store}".format(
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

                metadata = KernelMetadata(
                    operands=operands,
                    design=design,
                    kernel_name=kernel_name,
                    kernel_class=PersistentDenseGemmEFCKernel,
                    min_cc=100,
                    epilogue=epilogue_metadata,
                )

                if PersistentDenseGemmEFCKernel._valid_metadata(
                    metadata
                ) and metadata_filter(metadata):
                    kernel_list.append(
                        PersistentDenseGemmEFCKernel(metadata)
                    )

        return kernel_list
