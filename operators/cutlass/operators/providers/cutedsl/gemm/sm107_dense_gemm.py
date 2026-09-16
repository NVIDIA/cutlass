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

import itertools
from collections.abc import Callable, Generator

import cutlass
import cutlass.cute as cute

import cutlass.operators.utils.generate as generate
from cutlass.kernels.rubin.gemm.dense_gemm_universal import (
    Sm107DenseGemmUniversal,
)
from cutlass.kernels.rubin.gemm.dense_gemm_universal import (
    bmm as _operator_bmm,
)
from cutlass.operators.arch import TargetSm
from cutlass.operators.arguments import DenseTensor, EpilogueArguments, GemmArguments
from cutlass.operators.artifact import CompiledArtifact
from cutlass.operators.metadata import (
    GemmOperandsMetadata,
    OperatorMetadata,
    Sm107DesignMetadata,
)
from cutlass.operators.mma import RubinTcgen05Mma
from cutlass.operators.providers.cutedsl import CuTeDSLProvider
from cutlass.operators.providers.cutedsl.integration_utils.mma import (
    get_max_active_clusters,
)
from cutlass.operators.providers.cutedsl.operator import CuteDslOperator
from cutlass.operators.status import Status
from cutlass.operators.utils.common import tuple_to_string
from cutlass.operators.utils.device import to_cuda_stream
from cutlass.operators.utils.tensor import (
    normalized_major_stride,
    strides_to_layout_string,
)


@CuTeDSLProvider.register
class Sm107DenseGemmOperator(CuteDslOperator):
    """Operator exposing Rubin FP8 x FP8 dense GEMM kernel."""

    supported_args_type = GemmArguments
    designed_for_min_cc = 107

    def __init__(self, metadata: OperatorMetadata):
        if not self._valid_metadata(metadata):
            raise ValueError(f"Unsupported SM107 mixed-cluster metadata: {metadata}")
        super().__init__(metadata)

        design = metadata.design
        mma_ctas = 2 if design.use_2cta_mma else 1
        breuse_factor = 2 if design.enable_breuse else 1
        mma_tiler = (
            design.tile_shape[0] * mma_ctas,
            design.tile_shape[1],
            design.tile_shape[2],
        )
        mma_inst_shape = (
            design.tile_shape[0] * mma_ctas // breuse_factor,
            design.tile_shape[1],
            design.tile_shape[2] // 2,
        )
        # to disable preferred cluster behavior: operator uses fallback=None, kernel uses fallback=preferred
        fallback_cluster_shape_mn = (
            design.fallback_cluster_shape[:2]
            if design.fallback_cluster_shape is not None
            else design.cluster_shape[:2]
        )
        self.impl = Sm107DenseGemmUniversal(
            acc_dtype=metadata.operands.accumulator_type,
            use_2cta_instrs=design.use_2cta_mma,
            mma_tiler=mma_tiler,
            mma_inst_shape=mma_inst_shape,
            preferred_cluster_shape_mn=design.cluster_shape[:2],
            fallback_cluster_shape_mn=fallback_cluster_shape_mn,
            use_tma_store=design.use_tma_store,
        )

    def _supports(
        self, args: GemmArguments, target_sm: TargetSm | None = None
    ) -> Status:
        """Delegate problem-dependent validation to the mixed-cluster kernel."""
        major_strides = {(0, 1, 0): 0, (0, 0, 1): 1}
        normalized_strides = (
            normalized_major_stride(
                args.A.shape, args.A.stride, prepend_zeros_to_rank=3
            ),
            normalized_major_stride(
                args.B.shape, args.B.stride, prepend_zeros_to_rank=3
            ),
            normalized_major_stride(
                args.out.shape, args.out.stride, prepend_zeros_to_rank=3
            ),
        )
        if any(stride not in major_strides for stride in normalized_strides):
            return Status.fail(
                f"Unsupported tensor major strides: {normalized_strides}"
            )

        a_major = ("m", "k")[major_strides[normalized_strides[0]]]
        b_major = ("k", "n")[major_strides[normalized_strides[1]]]
        c_major = ("m", "n")[major_strides[normalized_strides[2]]]
        if not Sm107DenseGemmUniversal.can_implement(
            mnkl=tuple(args.problem_size),
            a_dtype=args.A.dtype,
            b_dtype=args.B.dtype,
            c_dtype=args.out.dtype,
            acc_dtype=args.accumulator_type,
            a_major=a_major,
            b_major=b_major,
            c_major=c_major,
            mma_tiler=self.impl.mma_tiler,
            mma_inst_shape=self.impl.mma_inst_shape,
            preferred_cluster_shape_mn=self.impl.cluster_shape_mn,
            fallback_cluster_shape_mn=self.impl.fallback_cluster_shape_mn,
        ):
            return Status.fail(
                f"SM107 mixed-cluster kernel cannot implement problem "
                f"{tuple(args.problem_size)}"
            )
        return Status.success()

    def _compile(
        self, args: GemmArguments, target_sm: TargetSm | None = None
    ) -> CompiledArtifact:
        stream = cute.runtime.make_fake_stream()
        preferred_max_active_clusters = get_max_active_clusters(
            self.impl.preferred_cluster_shape_mn
        )
        fallback_max_active_clusters = get_max_active_clusters(
            self.impl.fallback_cluster_shape_mn
        )
        return self.cute_compile(
            _operator_bmm,
            self.impl,
            args.A.tensor,
            args.B.tensor,
            args.out.tensor,
            preferred_max_active_clusters,
            fallback_max_active_clusters,
            stream,
            lambda x: x,
            target_sm=target_sm,
        )

    def _run(
        self,
        args: GemmArguments,
        compiled_artifact: CompiledArtifact,
        stream,
        workspace=None,
    ) -> None:
        """Run a compiled Rubin mixed-cluster GEMM."""
        self.cute_run(
            compiled_artifact.compiled_obj,
            args.A.tensor,
            args.B.tensor,
            args.out.tensor,
            to_cuda_stream(stream),
        )

    @staticmethod
    def _valid_operands(operands: GemmOperandsMetadata) -> bool:
        """Return whether operands match the initial Rubin FP8 integration."""
        if not isinstance(operands, GemmOperandsMetadata):
            return False
        fp8_dtypes = {cutlass.Float8E4M3FN, cutlass.Float8E5M2}
        if operands.A.dtype not in fp8_dtypes or operands.B.dtype not in fp8_dtypes:
            return False
        valid_c_dtypes = {
            cutlass.Float32: {
                cutlass.Float32,
                cutlass.BFloat16,
                cutlass.Float16,
                cutlass.Float8E4M3FN,
                cutlass.Float8E5M2,
            },
            cutlass.Float16: {
                cutlass.Float16,
                cutlass.BFloat16,
            },
        }
        if operands.out.dtype not in valid_c_dtypes.get(
            operands.accumulator_type, set()
        ):
            return False
        valid_major_strides = {(0, 0, 1), (0, 1, 0)}
        return all(
            operand.stride in valid_major_strides
            for operand in (operands.A, operands.B, operands.out)
        )

    @staticmethod
    def _metadata_operands_from_args(
        args: GemmArguments,
    ) -> Generator[GemmOperandsMetadata, None, None]:
        """Yield operand metadata corresponding to compatible runtime arguments."""
        if any(not isinstance(arg, DenseTensor) for arg in (args.A, args.B, args.out)):
            return

        a_stride = normalized_major_stride(
            args.A.shape, args.A.stride, prepend_zeros_to_rank=3
        )
        b_stride = normalized_major_stride(
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
            a_stride,
            b_stride,
            out_stride,
            alignment_bytes=16,
        )
        if Sm107DenseGemmOperator._valid_operands(operands):
            yield operands

    @staticmethod
    def _inst_shape_mnk(
        operands: GemmOperandsMetadata, design: Sm107DesignMetadata
    ) -> tuple[int, int, int]:
        """Return the instruction shape for the given design."""
        shape_k = RubinTcgen05Mma.shape_k(operands)
        inst_m = 256 if design.use_2cta_mma else 128
        return (inst_m, design.tile_shape[1], shape_k)

    @staticmethod
    def _valid_metadata(metadata: OperatorMetadata) -> bool:
        """Return whether metadata satisfies the mixed-cluster kernel constraints."""
        if not Sm107DenseGemmOperator._valid_operands(metadata.operands):
            return False
        if metadata.epilogue is not None:
            return False

        design = metadata.design
        if not isinstance(design, Sm107DesignMetadata):
            return False
        if design.mma_instruction_type is not RubinTcgen05Mma:
            return False
        if not design.use_tma_store:
            return False
        if design.tile_scheduler is not None:
            return False

        mma_inst_shape_mnk = Sm107DenseGemmOperator._inst_shape_mnk(
            metadata.operands, design
        )

        def valid_mma_inst_shape(
            mma_inst_shape_mnk: tuple[int, int, int], design: Sm107DesignMetadata
        ) -> bool:
            mma_inst_shape_n = mma_inst_shape_mnk[1]
            if mma_inst_shape_n not in range(32, 257, 32):
                return False
            # Breuse uses two accumulator stages except for N=256, where the
            # kernel uses one. N=160/192/224 rounds each stage to 512 TMEM
            # columns, so two stages require 1024 columns and exceed SM107's
            # 576-column limit.
            if design.enable_breuse and 128 < mma_inst_shape_n < 256:
                return False
            return True

        if not valid_mma_inst_shape(mma_inst_shape_mnk, design):
            return False

        def valid_tile_shape(
            mma_inst_shape_mnk: tuple[int, int, int], design: Sm107DesignMetadata
        ) -> bool:
            mma_ctas = 2 if design.use_2cta_mma else 1
            instruction_tiles_m = 2 if design.enable_breuse else 1
            expected_tile_m = mma_inst_shape_mnk[0] * instruction_tiles_m // mma_ctas

            return (
                design.tile_shape[0] == expected_tile_m
                and design.tile_shape[2] % mma_inst_shape_mnk[2] == 0
            )

        if not valid_tile_shape(mma_inst_shape_mnk, design):
            return False

        def valid_cluster_shape(shape: tuple[int, ...], mma_ctas: int) -> bool:
            cluster_m, cluster_n, cluster_l = shape
            return (
                cluster_l == 1
                and cluster_m % mma_ctas == 0
                and cluster_m * cluster_n <= 16
                and cluster_m & (cluster_m - 1) == 0
                and cluster_n & (cluster_n - 1) == 0
            )

        mma_ctas = 2 if design.use_2cta_mma else 1
        if not valid_cluster_shape(design.cluster_shape, mma_ctas):
            return False
        if design.fallback_cluster_shape is not None and not valid_cluster_shape(
            design.fallback_cluster_shape, mma_ctas
        ):
            return False
        return True

    @classmethod
    def _generate_operators(
        cls,
        metadata_filter: Callable[[OperatorMetadata], bool],
        epilogue_args: EpilogueArguments | None = None,
        target_sm: TargetSm | None = None,
        args: GemmArguments | None = None,
    ) -> list[CuteDslOperator]:
        """Generate Rubin FP8 mixed-cluster Operator configurations."""
        if epilogue_args is not None:
            return []

        fp8_dtypes = (cutlass.Float8E4M3FN, cutlass.Float8E5M2)
        # accumulator and output dtype configs
        acc_c_dtype_configs = (
            (cutlass.Float32, cutlass.Float32),
            (cutlass.Float32, cutlass.BFloat16),
            (cutlass.Float32, cutlass.Float16),
            (cutlass.Float32, cutlass.Float8E4M3FN),
            (cutlass.Float32, cutlass.Float8E5M2),
            (cutlass.Float16, cutlass.BFloat16),
            (cutlass.Float16, cutlass.Float16),
        )
        # enable_breuse
        enable_breuse_configs = (False, True)

        # mma_inst_shape_mn
        # (use_2cta_mma, mma_inst_shape_m, mma_inst_shape_n)
        mma_inst_shape_mn_configs = tuple(
            (use_2cta_mma, mma_inst_shape_m, mma_inst_shape_n)
            for use_2cta_mma, mma_inst_shape_m in (
                # 1CTA
                (False, 128),
                # 2CTA
                (True, 256),
            )
            for mma_inst_shape_n in range(32, 257, 32)
        )

        preferred_cluster_shapes = tuple(
            (cluster_m, cluster_n, 1)
            for cluster_m, cluster_n in itertools.product((1, 2, 4, 8, 16), repeat=2)
            if cluster_m * cluster_n <= Sm107DesignMetadata.max_cluster_size
        )
        fallback_cluster_shapes = ((1, 1, 1), (2, 1, 1), (1, 2, 1))
        cluster_shape_pairs = tuple(
            (preferred_shape, fallback_shape)
            for preferred_shape, fallback_shape in itertools.product(
                preferred_cluster_shapes, fallback_cluster_shapes
            )
            if (
                preferred_shape != fallback_shape
                and preferred_shape[0] % fallback_shape[0] == 0
                and preferred_shape[1] % fallback_shape[1] == 0
            )
        )

        if args is not None:
            operands_generator = cls._metadata_operands_from_args(args)
        else:
            operand_configs = {
                "a_dtype": fp8_dtypes,
                "b_dtype": fp8_dtypes,
                "a_stride": ((0, 0, 1), (0, 1, 0)),
                "b_stride": ((0, 0, 1), (0, 1, 0)),
                "out_stride": ((0, 0, 1), (0, 1, 0)),
            }
            operands_generator = (
                generate.construct_dense_gemm_operands(
                    a_dtype,
                    b_dtype,
                    c_dtype,
                    acc_dtype,
                    a_stride,
                    b_stride,
                    out_stride,
                    alignment_bytes=16,
                )
                for (
                    a_dtype,
                    b_dtype,
                    a_stride,
                    b_stride,
                    out_stride,
                    (acc_dtype, c_dtype),
                ) in itertools.product(*operand_configs.values(), acc_c_dtype_configs)
            )
        operators = []
        for operands in operands_generator:
            # The source kernel uses two K=64 instruction phases per mainloop tile.
            tile_k = RubinTcgen05Mma.shape_k(operands) * 2
            for (
                (use_2cta_mma, mma_inst_shape_m, mma_inst_shape_n),
                enable_breuse,
                (cluster_shape, fallback_cluster_shape),
            ) in itertools.product(
                mma_inst_shape_mn_configs,
                enable_breuse_configs,
                cluster_shape_pairs,
            ):
                mma_ctas = 2 if use_2cta_mma else 1
                instruction_tiles_m = 2 if enable_breuse else 1
                tile_m = mma_inst_shape_m * instruction_tiles_m // mma_ctas
                design = Sm107DesignMetadata(
                    mma_instruction_type=RubinTcgen05Mma,
                    use_2cta_mma=use_2cta_mma,
                    tile_shape=(tile_m, mma_inst_shape_n, tile_k),
                    cluster_shape=cluster_shape,
                    fallback_cluster_shape=fallback_cluster_shape,
                    use_tma_store=True,
                    enable_breuse=enable_breuse,
                )
                name = cls._operator_name(operands, design)
                metadata = OperatorMetadata(
                    operands=operands,
                    design=design,
                    operator_name=name,
                    operator_class=cls,
                    supported_targets=TargetSm.get_supported_targets(design, operands),
                    epilogue=None,
                )
                if cls._valid_metadata(metadata) and metadata_filter(metadata):
                    operators.append(cls(metadata))
        return operators

    @staticmethod
    def _operator_name(
        operands: GemmOperandsMetadata, design: Sm107DesignMetadata
    ) -> str:
        """Build a unique descriptive name for a Rubin Operator instance."""
        return (
            "cutedsl.PersistentDenseGemmMixedClustersOperator_sm107"
            "_{layout}"
            "_A{A}_B{B}_out{out}_acc{acc}"
            "_{num_cta}cta"
            "_cluster{cluster_shape}"
            "{fallback}"
            "_tile{tile}"
            "{_breuse}"
            "{_tma_store}"
        ).format(
            layout=strides_to_layout_string(
                operands.A.stride, operands.B.stride, operands.out.stride
            ),
            A=operands.A.dtype,
            B=operands.B.dtype,
            out=operands.out.dtype,
            acc=operands.accumulator_type,
            num_cta=("2" if design.use_2cta_mma else "1"),
            cluster_shape=tuple_to_string(design.cluster_shape),
            fallback=""
            if design.fallback_cluster_shape is None
            else f"_fallback{tuple_to_string(design.fallback_cluster_shape)}",
            tile=tuple_to_string(design.tile_shape),
            _breuse="_breuse" if design.enable_breuse else "",
            _tma_store="_tma_store" if design.use_tma_store else "",
        )
