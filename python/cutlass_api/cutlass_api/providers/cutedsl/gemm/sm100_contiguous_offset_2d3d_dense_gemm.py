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
import cutlass.utils as utils
import cutlass.cute as cute
from cutlass.cute.runtime import make_ptr

import cutlass_api
from cutlass_api.arguments import (
    EpilogueArguments,
    GroupedGemmArguments,
)
from cutlass_api.artifact import CompiledArtifact
from cutlass_api.metadata import (
    DesignMetadata,
    EpilogueMetadata,
    GroupedGemmOperandsMetadata,
    KernelMetadata,
    Sm100DesignMetadata,
)
from cutlass_api.providers.cutedsl import CuTeDSLProvider
from cutlass_api.providers.cutedsl.kernel import CuteDslKernel
from cutlass_api.providers.cutedsl.utils import get_max_active_clusters
from cutlass_api.status import Status
from cutlass_api.utils import (
    ceil_div,
    round_up,
    strides_to_layout_string,
    to_cuda_stream,
    tuple_to_string,
)

from .implementations.sm100_contiguous_offset_2d3d_dense_gemm_impl import (
    ContiguousOffset2D3DGemmDenseKernelImpl,
)
from .utils import (
    tensor_rank_2_or_3,
    tensor_reduction_mode_matches,
    tensor_output_shape_matches,
)


@CuTeDSLProvider.register
class ContiguousOffset2D3DGemmDenseKernel(CuteDslKernel):
    def __init__(self, metadata: KernelMetadata):
        super().__init__(metadata)
        mma_tiler_mn = (metadata.design.tile_shape[0], metadata.design.tile_shape[1])
        cluster_shape_mn = (
            metadata.design.cluster_shape[0],
            metadata.design.cluster_shape[1],
        )
        self.impl = ContiguousOffset2D3DGemmDenseKernelImpl(
            metadata.operands.accumulator_type,
            metadata.design.use_2cta_mma,
            mma_tiler_mn,
            cluster_shape_mn,
        )

    def _supports(self, args: GroupedGemmArguments) -> Status:
        if not (status := tensor_reduction_mode_matches(args)):
            return status

        if not (status := tensor_output_shape_matches(args)):
            return status

        if len(args.A.shape) == 3 and args.A.shape[0] != 1:
            return Status.fail(
                "Operand A must have batch size 1."
            )

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

    def compile(self, args: GroupedGemmArguments, cc: int = None) -> CompiledArtifact:
        stream = cutlass.cute.runtime.make_fake_stream()
        max_active_clusters = get_max_active_clusters(self.impl.cluster_shape_mn)

        compiled_kernel = self.cute_compile(
            self.impl,
            args.A.tensor,
            args.B.tensor,
            args.out.tensor,
            args.offsets.tensor,
            max_active_clusters,
            stream,
        )
        return CompiledArtifact(compiled_kernel, self)

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
        impl = ContiguousOffset2D3DGemmDenseKernelImpl
        return impl.is_valid_mma_tiler_and_cluster_shape(
            use_2cta_mma, mma_tiler_mn, cluster_shape_mn
        )

    @staticmethod
    def _valid_epilogue_metadata(epilogue: EpilogueMetadata | None) -> bool:
        return epilogue is None

    @staticmethod
    def _valid_metadata(metadata: KernelMetadata) -> bool:
        if not ContiguousOffset2D3DGemmDenseKernel._valid_operands(metadata.operands):
            return False
        if not ContiguousOffset2D3DGemmDenseKernel._valid_design_metadata(
            metadata.design
        ):
            return False
        if not ContiguousOffset2D3DGemmDenseKernel._valid_epilogue_metadata(
            metadata.epilogue
        ):
            return False
        return True

    @staticmethod
    def _metadata_operand_combinations() -> Generator[
        tuple[GroupedGemmOperandsMetadata, int], None, None
    ]:
        """
        Generator that yields all valid (GroupedGemmOperandsMetadata, sf_vec_size) combinations
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
        alignment_bytes = 16
        offsets_alignment_bytes = 4

        stride_A = row_major_stride
        stride_B = col_major_stride
        stride_out = row_major_stride

        acc_dtype = cutlass.Float32
        Impl = ContiguousOffset2D3DGemmDenseKernelImpl

        for ab_dtype, out_dtype in itertools.product(ab_dtypes, out_dtypes):
            if not Impl.is_valid_dtypes(ab_dtype, acc_dtype, out_dtype):
                continue

            ab_divisibility = alignment_bytes * 8 // ab_dtype.width
            out_divisibility = alignment_bytes * 8 // out_dtype.width
            offsets_divisibility = offsets_alignment_bytes * 8 // cutlass.Int32.width

            operands = GroupedGemmOperandsMetadata(
                A=cutlass_api.metadata.DenseTensorAttributes(
                    dtype=ab_dtype,
                    stride=stride_A,
                    divisibility=ab_divisibility,
                ),
                B=cutlass_api.metadata.DenseTensorAttributes(
                    dtype=ab_dtype,
                    stride=stride_B,
                    divisibility=ab_divisibility,
                ),
                out=cutlass_api.metadata.DenseTensorAttributes(
                    dtype=out_dtype,
                    stride=stride_out,
                    divisibility=out_divisibility,
                ),
                offsets=cutlass_api.metadata.DenseTensorAttributes(
                    dtype=cutlass.Int32,
                    stride=(1,),
                    divisibility=offsets_divisibility,
                ),
                accumulator_type=acc_dtype,
            )

            yield operands

    @staticmethod
    def generate_kernels(
        metadata_filter: Callable[[KernelMetadata], bool],
        epilogue_args: EpilogueArguments = None,
        cc: int = None,
    ) -> list["ContiguousOffset2D3DGemmDenseKernel"]:
        """
        Returns a list of all possible configurations of ContiguousOffset2D3DGemmDenseKernel that
        adhere to constraints passed in under kwargs.
        """
        if cc is not None and cc not in [100, 101, 103]:
            return []

        design_params = {
            "use_2cta_mma": [True, False],
            "tile_shape": [
                (64, 128, 128),
                (128, 128, 128),
                (256, 128, 128),
                (256, 256, 128),
            ],
            "cluster_shape": [(M, N, 1) for M in [1, 2, 4] for N in [1, 2, 4]],
            "use_tma_store": [True],
        }

        if epilogue_args is not None:
            return []

        from itertools import product

        # Get the list of tunable parameter names and their possible values
        param_names = list(design_params.keys())
        param_values = [design_params[name] for name in param_names]

        kernel_list = []

        for (
            operands
        ) in ContiguousOffset2D3DGemmDenseKernel._metadata_operand_combinations():
            for values in product(*param_values):
                design = Sm100DesignMetadata(**dict(zip(param_names, values)))
                kernel_name = "cutedsl.ContiguousOffset2D3DGemmDenseKernel_sm100_{layout}_A{A}_B{B}_out{out}_acc{acc}_{num_cta}cta_cluster{cluster}_tile{tile}{_tma_store}".format(
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
                    kernel_class=ContiguousOffset2D3DGemmDenseKernel,
                    min_cc=100,
                    epilogue=None,
                )

                metadata_valid = ContiguousOffset2D3DGemmDenseKernel._valid_metadata(
                    metadata
                )
                if metadata_valid and metadata_filter(metadata):
                    kernel_list.append(ContiguousOffset2D3DGemmDenseKernel(metadata))

        return kernel_list
