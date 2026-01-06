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
    GemmOperandsMetadata,
    KernelMetadata,
    TensorAttributes,
)
from cutlass_api.providers.cutedsl import CuTeDSLProvider
from cutlass_api.providers.cutedsl.kernel import CuteDslKernel
from cutlass_api.status import Status
from cutlass_api.utils import strides_to_layout_string, to_cuda_stream, tuple_to_string
from cutlass_api.metadata import BLASDesignMetadata
from .implementations.sm80_tensorop_gemm_impl import Sm80TensorOpGemmImpl


@CuTeDSLProvider.register
class Sm80TensorOpGemmKernel(CuteDslKernel):
    """This class implements batched matrix multiplication (C = A @ B)

    :note: In current version, A and B tensor must have the same data type

    :note: Supported A/B data types:
        - Float16/BFloat16

    :note: Supported accumulator data types:
        - Float32 (for all floating point A/B data types)
    :note: Supported C data types:
        - Float16/BFloat16  (same as A, B)

    :note: Constraints:
        - MMA tiler M must be 64/128
        - MMA tiler N must be 64/128
    """

    def __init__(self, metadata: KernelMetadata):
        super().__init__(metadata)
        self.impl = Sm80TensorOpGemmImpl(
            metadata.operands.A.dtype,
            metadata.operands.B.dtype,
            metadata.operands.out.dtype,
            metadata.operands.accumulator_type
            )

    def _supports(self, args: GemmArguments) -> Status:

        if args.epilogue is not None:
            return Status.fail("This kernel does not support any epilogue fusion.")
        return Status.success()

    def compile(self, args: GemmArguments, cc: int = None) -> CompiledArtifact:
        stream = cutlass.cute.runtime.make_fake_stream()

        compiled_kernel = self.cute_compile(
            self.impl,
            args.A,
            args.B,
            args.out,
            stream,
        )
        return CompiledArtifact(compiled_kernel, self)

    def _run(
        self,
        args: GemmArguments,
        compiled_artifact: CompiledArtifact,
        stream,
        workspace=None,
    ) -> None:
        stream = to_cuda_stream(stream)
        compiled_gemm = compiled_artifact.compiled_obj
        self.cute_run(compiled_gemm, args.A, args.B, args.out, stream)

    @staticmethod
    def _valid_operands(operands: GemmOperandsMetadata) -> bool:
        if not isinstance(operands, GemmOperandsMetadata):
            return False

        # In current version, A and B tensor must have the same data type
        if operands.A.dtype != operands.B.dtype:
            return False

        # Supported A/B data types:
        if operands.A.dtype not in [cutlass.Float16, cutlass.BFloat16]:
            return False

        # Supported accumulator data types:
        if operands.accumulator_type not in [cutlass.Float32]:
            return False

        # Supported out data types:
        if operands.out.dtype not in [cutlass.Float32, cutlass.Float16, cutlass.BFloat16]:
            return False

        return True

    @staticmethod
    def _metadata_operand_combinations() -> Generator[GemmOperandsMetadata, None, None]:
        """
        Generator that yields all valid GemmOperandsMetadata combinations
        based on the validation rules in _valid_operands.
        """
        # Supported A/B data types (must be the same)
        ab_dtypes = [cutlass.Float16, cutlass.BFloat16]
        valid_acc_dtypes = [cutlass.Float32]
        valid_out_dtypes = ab_dtypes

        # Torch conventions (L, M, K) and (L, K, N)
        row_major_stride = (0, 0, 1)
        col_major_stride = (0, 1, 0)
        alignment_bytes = 16

        for ab_dtype in ab_dtypes:
            for out_dtype in valid_out_dtypes:
                for acc_dtype in valid_acc_dtypes:
                    for stride_A, stride_B, stride_out in itertools.product(
                        [row_major_stride, col_major_stride], repeat=3
                    ):
                        ab_divisibility = alignment_bytes * 8 // ab_dtype.width
                        out_divisibility = alignment_bytes * 8 // out_dtype.width

                        # Create TensorAttributes for A, B, and out tensors
                        a_attrs = TensorAttributes(
                            dtype=ab_dtype,
                            stride=stride_A,
                            divisibility=ab_divisibility,
                        )
                        b_attrs = TensorAttributes(
                            dtype=ab_dtype,
                            stride=stride_B,
                            divisibility=ab_divisibility,
                        )
                        out_attrs = TensorAttributes(
                            dtype=out_dtype,
                            stride=stride_out,
                            divisibility=out_divisibility,
                        )

                        # Create and yield the GemmOperandsMetadata
                        operands = GemmOperandsMetadata(
                            A=a_attrs,
                            B=b_attrs,
                            out=out_attrs,
                            accumulator_type=acc_dtype,
                        )

                        yield operands

    @staticmethod
    def _valid_metadata(metadata: KernelMetadata) -> bool:
        if not Sm80TensorOpGemmKernel._valid_operands(metadata.operands):
            return False

        design = metadata.design
        if not isinstance(design, BLASDesignMetadata):
            return False

        if design.tile_shape is None:
            return False

        # MMA tiler N must be 32/64/128/256
        if design.tile_shape[1] not in [32, 64, 128]:
            return False
        
        # MMA tiler M must be 64/128/256
        if design.tile_shape[0] not in [64, 128]:
            return False

        if metadata.epilogue is not None:
            return False

        return True

    @staticmethod
    def generate_kernels(
        metadata_filter: Callable[[KernelMetadata], bool],
        epilogue_args: EpilogueArguments = None,
        cc: int = None,
    ) -> list["Sm80TensorOpGemmKernel"]:
        """
        Returns a list of all possible configurations of Sm80TensorOpGemmKernel that
        adhere to constraints passed in under kwargs.
        """
        min_cc = 80
        if cc is not None and cc < min_cc:
            return []

        design_params = {
            "tile_shape": [
                (M, N, 32) for M in [64, 128] for N in [64, 128]
            ],
            # SM80 kernels do not currently use cluster_shape for tuning; fix it to a
            # single valid value to satisfy the BLASDesignMetadata interface.
            "cluster_shape": [(1, 1, 1)],
        }

        if epilogue_args is not None:
            return []

        from itertools import product

        # Get the list of tunable parameter names and their possible values
        param_names = list(design_params.keys())
        param_values = [design_params[name] for name in param_names]

        kernel_list = []

        for operands in Sm80TensorOpGemmKernel._metadata_operand_combinations():
            for values in product(*param_values):
                design = BLASDesignMetadata(**dict(zip(param_names, values)))
                kernel_name = "cutedsl.Sm80TensorOpGemmKernel_{layout}_A{A}_B{B}_out{out}_acc{acc}_tile{tile}".format(
                    layout=strides_to_layout_string(
                        operands.A.stride, operands.B.stride, operands.out.stride
                    ),
                    A=operands.A.dtype,
                    B=operands.B.dtype,
                    out=operands.out.dtype,
                    acc=operands.accumulator_type,
                    tile=tuple_to_string(design.tile_shape),
                )

                metadata = KernelMetadata(
                    operands=operands,
                    design=design,
                    kernel_name=kernel_name,
                    kernel_class=Sm80TensorOpGemmKernel,
                    min_cc=min_cc,
                    epilogue=None,
                )

                if Sm80TensorOpGemmKernel._valid_metadata(
                    metadata
                ) and metadata_filter(metadata):
                    kernel_list.append(
                        Sm80TensorOpGemmKernel(metadata)
                    )

        return kernel_list
