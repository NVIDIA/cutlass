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
from cutlass.cute.nvgpu.tcgen05 import OperandMajorMode

from cutlass.cute.runtime import make_ptr

import cutlass_api
from cutlass_api.arguments import (
    EpilogueArguments,
    GemmArguments,
)
from cutlass_api.artifact import CompiledArtifact
from cutlass_api.metadata import (
    DenseTensorAttributes,
    DesignMetadata,
    EpilogueMetadata,
    GemmOperandsMetadata,
    KernelMetadata,
    Sm100DesignMetadata,
    ScaledTensorAttributes,
)
from cutlass_api.library import ScaleMode, ScaleSwizzleMode
from cutlass_api.providers.cutedsl import CuTeDSLProvider
from cutlass_api.providers.cutedsl.kernel import CuteDslKernel
from cutlass_api.providers.cutedsl.utils import get_max_active_clusters
from cutlass_api.status import Status
from cutlass_api.utils import ceil_div, round_up, strides_to_layout_string, to_cuda_stream, tuple_to_string

from .implementations.sm100_dense_blockscaled_static_persistent_impl import PersistentDenseBlockScaledGemmKernelImpl


@CuTeDSLProvider.register
class PersistentDenseBlockScaledGemmKernel(CuteDslKernel):
    def __init__(self, metadata: KernelMetadata):
        super().__init__(metadata)
        self.sf_vec_size = metadata.operands.A.mode[-1]
        mma_tiler_mn = (metadata.design.tile_shape[0], metadata.design.tile_shape[1])
        cluster_shape_mn = (
            metadata.design.cluster_shape[0],
            metadata.design.cluster_shape[1],
        )
        self.impl = PersistentDenseBlockScaledGemmKernelImpl(
            self.sf_vec_size,
            mma_tiler_mn,
            cluster_shape_mn,
        )

    def _supports(self, args: GemmArguments) -> Status:
        M, N = args.out.shape[-2:]
        K = args.A.shape[-1]
        L = args.A.shape[0] if len(args.A.shape) == 3 else 1

        # To support 32-4-4 swizzling, the scale factor tensor must be padded to a multiple of 4
        expected_sf_k = round_up(ceil_div(K, self.sf_vec_size), 4)

        # Shapes of scale factor tensors are not enforced. It is expected that the
        # data underlying the passed in scale factor tensor is in 32-4-4 swizzled format.
        # Thus, we check only that the number of elements in the scale factor tensor is correct.
        expected_sfa_elements = L * M * expected_sf_k
        expected_sfb_elements = L * N * expected_sf_k

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

    def _construct_pointers(self, args: GemmArguments, nullptr: bool = False) -> tuple[cute.Pointer, cute.Pointer, cute.Pointer, cute.Pointer, cute.Pointer]:
        def ptr(x): return 0 if nullptr else x.data_ptr
        gmem = cute.AddressSpace.gmem
        a_ptr = make_ptr(args.A.element_type, ptr(args.A), gmem, assumed_align=16)
        b_ptr = make_ptr(args.B.element_type, ptr(args.B), gmem, assumed_align=16)
        out_ptr = make_ptr(args.out.element_type, ptr(args.out), gmem, assumed_align=16)
        sfa_ptr = make_ptr(
            args.A.scale.element_type, ptr(args.A.scale), gmem, assumed_align=32
        )
        sfb_ptr = make_ptr(
            args.B.scale.element_type, ptr(args.B.scale), gmem, assumed_align=32
        )
        return a_ptr, b_ptr, out_ptr, sfa_ptr, sfb_ptr

    @staticmethod
    def _major_modes(args: GemmArguments | GemmOperandsMetadata) -> tuple[tuple[OperandMajorMode, str], tuple[OperandMajorMode, str], tuple[utils.LayoutEnum, str]]:
        # A, B, and out can be of rank 2 or 3. Extract the final two dimensions
        # to determine the major mode
        if args.A.stride[-2:].index(1) == 1:
            a_major_mode = (OperandMajorMode.K, "k")
        else:
            a_major_mode = (OperandMajorMode.MN, "m")

        if args.B.stride[-2:].index(1) == 0:
            b_major_mode = (OperandMajorMode.K, "k")
        else:
            b_major_mode = (OperandMajorMode.MN, "n")

        if args.out.stride[-2:].index(1) == 1:
            out_layout = (utils.LayoutEnum.ROW_MAJOR, "n")
        else:
            out_layout = (utils.LayoutEnum.COL_MAJOR, "m")

        return a_major_mode, b_major_mode, out_layout

    def compile(self, args: GemmArguments, cc: int = None) -> CompiledArtifact:
        stream = cutlass.cute.runtime.make_fake_stream()
        max_active_clusters = get_max_active_clusters(self.impl.cluster_shape_mn)

        a_ptr, b_ptr, out_ptr, sfa_ptr, sfb_ptr = self._construct_pointers(args, nullptr=True)
        fake_problem_shape = (cutlass.Int32(0), cutlass.Int32(0), cutlass.Int32(0), cutlass.Int32(0))
        epilogue_op = lambda x: x

        (a_major_mode, _), (b_major_mode, _), (out_layout, _) = PersistentDenseBlockScaledGemmKernel._major_modes(args)

        compiled_kernel = self.cute_compile(
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

        m, n = args.out.shape[-2:]
        k = args.A.shape[-1]
        l = args.A.shape[0] if len(args.A.shape) == 3 else 1

        a_ptr, b_ptr, out_ptr, sfa_ptr, sfb_ptr = self._construct_pointers(args)
        self.cute_run(compiled_gemm, a_ptr, b_ptr, sfa_ptr, sfb_ptr, out_ptr, (m, n, k, l), stream)

    @staticmethod
    def _valid_operands(operands: GemmOperandsMetadata, sf_vec_size: int) -> bool:
        if not isinstance(operands, GemmOperandsMetadata):
            return False

        # In current version, A and B tensor must have the same data type
        # i.e., Float8E4M3FN for A and Float8E5M2 for B is not supported.
        # The same holds for scale A and scale B.
        if (
            operands.A.dtype != operands.B.dtype
            or operands.A.scale.dtype != operands.B.scale.dtype
        ):
            return False

        if operands.accumulator_type != cutlass.Float32:
            return False

        ab_dtype = operands.A.dtype
        sf_dtype = operands.A.scale.dtype
        out_dtype = operands.out.dtype

        impl = PersistentDenseBlockScaledGemmKernelImpl
        if not impl.is_valid_dtypes_and_scale_factor_vec_size(ab_dtype, sf_dtype, sf_vec_size, out_dtype):
            return False

        (_, a_major), (_, b_major), (_, out_major) = PersistentDenseBlockScaledGemmKernel._major_modes(operands)
        if not impl.is_valid_layouts(ab_dtype, out_dtype, a_major, b_major, out_major):
            return False

        return True

    @staticmethod
    def _valid_design_metadata(design: DesignMetadata) -> bool:
        if not isinstance(design, Sm100DesignMetadata):
            return False

        mma_tiler_mn = design.tile_shape[:2]
        cluster_shape_mn = design.cluster_shape[:2]
        impl = PersistentDenseBlockScaledGemmKernelImpl
        return impl.is_valid_mma_tiler_and_cluster_shape(mma_tiler_mn, cluster_shape_mn)

    @staticmethod
    def _valid_epilogue_metadata(epilogue: EpilogueMetadata | None) -> bool:
        return epilogue is None

    @staticmethod
    def _valid_metadata(metadata: KernelMetadata) -> bool:
        scale_vec = metadata.operands.A.mode

        # Make sure scale vector is in the form (1, 1, ..., 1, sf_vec_size)
        if len(scale_vec) > 1:
            for i in range(0, len(scale_vec) - 1):
                if scale_vec[i] != 1:
                    return False

        sf_vec_size = scale_vec[-1]
        if not PersistentDenseBlockScaledGemmKernel._valid_operands(metadata.operands, sf_vec_size):
            return False
        if not PersistentDenseBlockScaledGemmKernel._valid_design_metadata(metadata.design):
            return False
        if not PersistentDenseBlockScaledGemmKernel._valid_epilogue_metadata(metadata.epilogue):
            return False
        return True

    @staticmethod
    def _metadata_operand_combinations() -> Generator[tuple[GemmOperandsMetadata, int], None, None]:
        """
        Generator that yields all valid (GemmOperandsMetadata, sf_vec_size) combinations
        based on the validation rules in _valid_operands.
        """
        # Supported A/B data types (must be the same)
        ab_dtypes = [
            cutlass.Float8E5M2,
            cutlass.Float8E4M3FN,
        ]

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
        alignment_bytes = 16

        def major_str_a(major_tuple: tuple[int, int, int]) -> str:
            return "k" if major_tuple == row_major_stride else "m"
        def major_str_b(major_tuple: tuple[int, int, int]) -> str:
            return "n" if major_tuple == row_major_stride else "k"
        def major_str_out(major_tuple: tuple[int, int, int]) -> str:
            return "n" if major_tuple == row_major_stride else "m"

        Impl = PersistentDenseBlockScaledGemmKernelImpl

        for ab_dtype, sf_dtype, scale_mode, out_dtype in itertools.product(ab_dtypes, sf_dtypes, scale_modes, out_dtypes):
            sf_vec_size = scale_mode[-1]
            if not Impl.is_valid_dtypes_and_scale_factor_vec_size(ab_dtype, sf_dtype, sf_vec_size, out_dtype):
                continue

            for stride_A, stride_B, stride_out in itertools.product(
                [row_major_stride, col_major_stride], repeat=3
            ):
                a_major = major_str_a(stride_A)
                b_major = major_str_b(stride_B)
                out_major = major_str_out(stride_out)

                if not Impl.is_valid_layouts(ab_dtype, out_dtype, a_major, b_major, out_major):
                    continue

                ab_divisibility = alignment_bytes * 8 // ab_dtype.width
                out_divisibility = alignment_bytes * 8 // out_dtype.width
                sf_divisibility = alignment_bytes * 8 // sf_dtype.width

                operands = GemmOperandsMetadata(
                    A=ScaledTensorAttributes(
                        base=DenseTensorAttributes(
                            dtype=ab_dtype,
                            stride=stride_A,
                            divisibility=ab_divisibility,
                        ),
                        scale=DenseTensorAttributes(
                            dtype=sf_dtype,
                            stride=None,
                            divisibility=sf_divisibility,
                        ),
                        mode=scale_mode,
                        swizzle=ScaleSwizzleMode.Swizzle32x4x4,
                    ),
                    B=ScaledTensorAttributes(
                        base=DenseTensorAttributes(
                            dtype=ab_dtype,
                            stride=stride_B,
                            divisibility=ab_divisibility,
                        ),
                        scale=DenseTensorAttributes(
                            dtype=sf_dtype,
                            stride=None,
                            divisibility=sf_divisibility,
                        ),
                        mode=scale_mode,
                        swizzle=ScaleSwizzleMode.Swizzle32x4x4,
                    ),
                    out=DenseTensorAttributes(
                        dtype=out_dtype,
                        stride=stride_out,
                        divisibility=out_divisibility,
                    ),
                    accumulator_type=cutlass.Float32,
                )

                yield operands

    @staticmethod
    def generate_kernels(
        metadata_filter: Callable[[KernelMetadata], bool],
        epilogue_args: EpilogueArguments = None,
        cc: int = None,
    ) -> list["PersistentDenseBlockScaledGemmKernel"]:
        """
        Returns a list of all possible configurations of PersistentDenseBlockScaledGemmKernel that
        adhere to constraints passed in under kwargs.
        """
        if cc is not None and cc not in [100, 101, 103]:
            return []

        design_params = {
            "use_2cta_mma": [True],
            "tile_shape": [
                (M, N, 256) for M in [128, 256] for N in [64, 128, 192, 256]
            ],
            "cluster_shape": [
                (M, N, 1) for M in [2, 4] for N in [1, 2, 4]
            ],
            "use_tma_store": [True],
        }

        if epilogue_args is not None:
            return []

        from itertools import product

        # Get the list of tunable parameter names and their possible values
        param_names = list(design_params.keys())
        param_values = [design_params[name] for name in param_names]

        kernel_list = []

        for operands in PersistentDenseBlockScaledGemmKernel._metadata_operand_combinations():
            for values in product(*param_values):
                design = Sm100DesignMetadata(**dict(zip(param_names, values)))
                kernel_name = "cutedsl.PersistentDenseBlockScaledGemmKernel_sm100_{layout}_A{A}_B{B}_out{out}_SFA{SFA}_SFB{SFB}_acc{acc}_scale{scale_mode}_swizzle{scale_swizzle}_{num_cta}cta_cluster{cluster}_tile{tile}{_tma_store}".format(
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

                metadata = KernelMetadata(
                    operands=operands,
                    design=design,
                    kernel_name=kernel_name,
                    kernel_class=PersistentDenseBlockScaledGemmKernel,
                    min_cc=100,
                    epilogue=None,
                )

                metadata_valid = PersistentDenseBlockScaledGemmKernel._valid_metadata(metadata)

                if metadata_valid and metadata_filter(metadata):
                    kernel_list.append(PersistentDenseBlockScaledGemmKernel(metadata))

        return kernel_list
