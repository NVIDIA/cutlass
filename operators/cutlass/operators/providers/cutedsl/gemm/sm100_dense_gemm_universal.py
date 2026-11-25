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

from __future__ import annotations

import itertools
from functools import cached_property
from typing import TYPE_CHECKING

import cutlass
import cutlass.cute.runtime
from cutlass.cutlass_dsl import Boolean, Int32

import cutlass.operators.utils.generate as generate
from cutlass.kernels.blackwell.gemm.dense_gemm_universal import (
    PersistentDenseGemmKernel,
    bmm,
)
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
    CLCDynamicPersistentMetadata,
    ClusterSplitKReductionMetadata,
    NoReductionMetadata,
    StaticPersistentMetadata,
)
from cutlass.operators.mma import BlackwellTcgen05Mma
from cutlass.operators.providers.cutedsl import CuTeDSLProvider
from cutlass.operators.providers.cutedsl.integration_utils import (
    scheduling,
)
from cutlass.operators.providers.cutedsl.integration_utils import (
    workspace as workspace_utils,
)
from cutlass.operators.providers.cutedsl.operator import CuteDslOperator
from cutlass.operators.status import Status
from cutlass.operators.utils.common import tuple_to_string
from cutlass.operators.utils.device import to_cuda_stream
from cutlass.operators.utils.tensor import (
    normalized_major_stride,
    strides_to_layout_string,
)
from cutlass.operators.workspace import AllocationRequirement

if TYPE_CHECKING:
    from collections.abc import Callable, Generator

    from cutlass.operators.artifact import CompiledArtifact
    from cutlass.operators.device_properties import (
        DeviceProperties,
    )
    from cutlass.operators.workspace import Workspace


@CuTeDSLProvider.register
class Sm100DenseGemmUniversalOperator(CuteDslOperator):
    """Batched dense GEMM (C = A @ B) on SM100 with a composable tile scheduler.

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
        - Float16/BFloat16 (for fp32, fp16, and fp8 accumulator data types)
        - Int8/Uint8 (for uint8/int8 accumulator data types)
        - Float8E4M3FN/Float8E5M2 (for float32 accumulator data types)

    :note: Constraints:
        - MMA tiler M must be 64/128 (use_2cta_instrs=False) or 128/256 (use_2cta_instrs=True)
        - MMA tiler N must be 32-256, step 32
        - Cluster shape M must be multiple of 2 if use_2cta_instrs=True
        - Cluster shape M/N must be positive and power of 2, total cluster size <= 16
        - A fallback cluster shape, if set, must satisfy the same cluster shape
          constraints and evenly divide the preferred cluster shape
        - If cluster split-K is used, then TMA store is not supported
        - n or m must be divisible by swizzle size * tile shape dimension for the
        given raster order when not using TMA store
    """

    supported_args_type = GemmArguments
    designed_for_min_cc = 100

    def __init__(self, metadata: OperatorMetadata):
        super().__init__(metadata)
        design = metadata.design

        self.mma_tiler_mn = (design.tile_shape[0], design.tile_shape[1])
        self.cluster_shape_mn = (design.cluster_shape[0], design.cluster_shape[1])
        self.fallback_cluster_shape_mn = (
            (design.fallback_cluster_shape[0], design.fallback_cluster_shape[1])
            if design.fallback_cluster_shape is not None
            else None
        )

    @cached_property
    def impl(self):
        """Build this operator's kernel only when compilation or launch needs it."""
        metadata = self.metadata
        design = metadata.design

        scheduler = design.tile_scheduler

        return PersistentDenseGemmKernel(
            metadata.operands.accumulator_type,
            design.use_2cta_mma,
            self.mma_tiler_mn,
            self.cluster_shape_mn,
            design.use_tma_store,
            split_k=scheduling.resolve_split_count(scheduler.reduction),
            work_strategy=scheduler.persistence.arg_name(),
            rasterization_strategy=scheduler.rasterization.arg_name(),
            reduction_strategy=scheduler.reduction.arg_name(),
            fallback_cluster_shape_mn=self.fallback_cluster_shape_mn,
        )

    def _supports(
        self, args: GemmArguments, target_sm: TargetSm | None = None
    ) -> Status:
        """Reject launches this operator's fixed non-TMA store path cannot handle."""
        design = self.metadata.design
        if not design.use_tma_store:
            cta_tile_m = self.mma_tiler_mn[0] // (2 if design.use_2cta_mma else 1)
            cta_tile_n = self.mma_tiler_mn[1]
            ps = args.problem_size
            if ps.M % cta_tile_m != 0 or ps.N % cta_tile_n != 0:
                return Status.fail(
                    f"non-TMA store requires the problem shape (M={ps.M}, "
                    f"N={ps.N}) to be divisible by the CTA tile "
                    f"({cta_tile_m}, {cta_tile_n}); this store path has no "
                    "out-of-bounds predication"
                )
        return Status.success()

    def _compile(
        self, args: GemmArguments, target_sm: TargetSm | None = None
    ) -> CompiledArtifact:
        stream = cutlass.cute.runtime.make_fake_stream()
        return self.cute_compile(
            bmm,
            self.impl,
            args.A.tensor,
            args.B.tensor,
            args.out.tensor,
            stream,
            workspace_utils.null_gmem_pointer(),
            Int32(1),
            Boolean(True),
            Int32(0),  # placeholder for max_active_clusters_fallback
            target_sm=target_sm,
        )

    def _get_workspace_size(self, args: GemmArguments) -> AllocationRequirement:
        """Return the GMEM tile-scheduler workspace required for ``args``."""
        ps = args.problem_size
        size_bytes = self.impl.get_gmem_workspace_size((ps.M, ps.N, ps.L))
        if size_bytes == 0:
            return AllocationRequirement.empty()
        return AllocationRequirement(size_bytes=size_bytes, ptr_alignment=16)

    def _initialize_workspace(self, args: GemmArguments, workspace: Workspace) -> None:
        """Validate and populate the caller-owned GMEM workspace before :meth:`run`."""
        required_bytes = self._get_workspace_size(args).size_bytes
        if required_bytes == 0:
            return

        workspace_utils.check_workspace_size(workspace, required_bytes)
        workspace_bytes_view = workspace_utils.view_workspace_as_bytes(workspace)
        ps = args.problem_size
        self.impl.initialize_workspace(workspace_bytes_view, (ps.M, ps.N, ps.L))

    def _run(
        self,
        args: GemmArguments,
        compiled_artifact: CompiledArtifact,
        stream,
        workspace=None,
        *,
        device_properties: DeviceProperties,
    ) -> None:
        stream = to_cuda_stream(stream)
        ps = args.problem_size
        operands = self.metadata.operands
        design = self.metadata.design
        swizzle_size, raster_along = scheduling.resolve_launch_rasterization(
            args,
            design.tile_scheduler.rasterization,
            self.impl.tile_scheduler_template,
            (ps.M, ps.N, ps.K, ps.L),
            a_element_bytes=operands.A.dtype.width // 8,
            b_element_bytes=operands.B.dtype.width // 8,
            # A non-TMA store implementation currently has no predication,
            # so its traversal must not visit out-of-bounds tiles.
            predicated_store=design.use_tma_store,
        )

        workspace_ptr = workspace_utils.get_gmem_workspace_pointer(
            workspace, self._get_workspace_size(args).size_bytes
        )

        if self.impl.work_strategy == "static":
            max_active_clusters = scheduling.resolve_max_active_clusters(
                device_properties,
                self.fallback_cluster_shape_mn or self.cluster_shape_mn,
                self.impl.split_k,
                self.impl.reduction_strategy,
                self.impl.work_strategy,
            )
        else:
            max_active_clusters = 0  # unused for non-static strategies

        self.cute_run(
            compiled_artifact.compiled_obj,
            args.A.tensor,
            args.B.tensor,
            args.out.tensor,
            stream,
            workspace_ptr,
            Int32(swizzle_size),
            Boolean(raster_along == "m"),
            Int32(max_active_clusters),
        )

    @staticmethod
    def _valid_operands(operands: GemmOperandsMetadata) -> bool:
        """Check the operand data types against PersistentDenseGemmKernel.can_implement.

        :param operands: The operand metadata to validate.
        :type operands: GemmOperandsMetadata

        :return: True if the kernel supports these operands, False otherwise.
        :rtype: bool
        """
        if not isinstance(operands, GemmOperandsMetadata):
            return False

        a_dtype = operands.A.dtype
        b_dtype = operands.B.dtype
        acc_dtype = operands.accumulator_type

        # Supported A/B data types:
        #  - Float16/BFloat16
        #  - Int8/Uint8
        #  - Float8E4M3FN/Float8E5M2
        valid_ab_dtypes = {
            cutlass.Float16,
            cutlass.BFloat16,
            cutlass.Int8,
            cutlass.Uint8,
            cutlass.Float8E4M3FN,
            cutlass.Float8E5M2,
        }
        if a_dtype not in valid_ab_dtypes or b_dtype not in valid_ab_dtypes:
            return False

        # Supported accumulator data types, and the A/B data types each accepts:
        #  - Float32 (for all floating point A/B data types)
        #  - Float16 (only for fp16 and fp8 A/B data types)
        #  - Int32 (only for uint8/int8 A/B data types)
        acc_ab_compatibility = {
            cutlass.Float32: {
                cutlass.Float16,
                cutlass.BFloat16,
                cutlass.Float8E4M3FN,
                cutlass.Float8E5M2,
            },
            cutlass.Float16: {
                cutlass.Float16,
                cutlass.Float8E4M3FN,
                cutlass.Float8E5M2,
            },
            cutlass.Int32: {
                cutlass.Uint8,
                cutlass.Int8,
            },
        }
        if acc_dtype not in acc_ab_compatibility:
            return False
        if (
            a_dtype not in acc_ab_compatibility[acc_dtype]
            or b_dtype not in acc_ab_compatibility[acc_dtype]
        ):
            return False

        # Supported out data types, per accumulator data type:
        #  - Float32 accumulates into any float, fp8 or integer output
        #  - Float16 accumulates into Float16/BFloat16 only
        #  - Int32 accumulates into any float or integer output, but not fp8
        acc_out_compatibility = {
            cutlass.Float32: {
                cutlass.Float32,
                cutlass.Float16,
                cutlass.BFloat16,
                cutlass.Float8E4M3FN,
                cutlass.Float8E5M2,
                cutlass.Int32,
                cutlass.Int8,
                cutlass.Uint8,
            },
            cutlass.Float16: {
                cutlass.BFloat16,
                cutlass.Float16,
            },
            cutlass.Int32: {
                cutlass.BFloat16,
                cutlass.Float16,
                cutlass.Float32,
                cutlass.Int32,
                cutlass.Int8,
                cutlass.Uint8,
            },
        }
        return operands.out.dtype in acc_out_compatibility[acc_dtype]

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

        if not Sm100DenseGemmUniversalOperator._valid_operands(operands):
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
                            cutlass.Int8,
                            cutlass.Uint8,
                        ]
                    )
                elif acc_dtype == cutlass.Int32:
                    valid_out_dtypes.extend(
                        [
                            cutlass.Int8,
                            cutlass.Uint8,
                            cutlass.Float32,
                            cutlass.Int32,
                            cutlass.Float16,
                            cutlass.BFloat16,
                        ]
                    )
                elif acc_dtype == cutlass.Float16:
                    valid_out_dtypes.extend([cutlass.Float16, cutlass.BFloat16])

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
    def _valid_design(design: Sm100DesignMetadata) -> bool:
        if not isinstance(design, Sm100DesignMetadata):
            return False

        def is_power_of_2(x: int) -> bool:
            return x > 0 and (x & (x - 1)) == 0

        cluster_size_m, cluster_size_n, _ = design.cluster_shape
        if not is_power_of_2(cluster_size_m) or not is_power_of_2(cluster_size_n):
            return False

        # Sm100DesignMetadata already checks that the fallback divides the
        # preferred cluster shape.
        fallback_size_m = cluster_size_m
        if design.fallback_cluster_shape is not None:
            fallback_size_m, fallback_size_n, _ = design.fallback_cluster_shape
            if not is_power_of_2(fallback_size_m) or not is_power_of_2(fallback_size_n):
                return False

        tile = design.tile_shape

        # The 2CTA MMA variant halves the tile along M across a CTA pair, so it needs
        # a larger mma tiler M and an even number of CTAs along both clusters' M.
        if design.use_2cta_mma:
            if cluster_size_m % 2 != 0 or fallback_size_m % 2 != 0:
                return False
            if tile[0] not in [128, 256]:
                return False
        elif tile[0] not in [64, 128]:
            return False

        if tile[1] not in range(32, 257, 32):
            return False

        scheduler = design.tile_scheduler
        if scheduler is None:
            return False

        # Cluster split-K changes the cluster size, so it needs to be checked separately
        if (
            not isinstance(scheduler.reduction, ClusterSplitKReductionMetadata)
            and (cluster_size_m * cluster_size_n) > Sm100DesignMetadata.max_cluster_size
        ):
            return False

        cta_tile_m = tile[0] // (2 if design.use_2cta_mma else 1)
        if not scheduling.reduction_fits(
            scheduler.reduction,
            cta_tile_mn=(cta_tile_m, tile[1]),
            cluster_shape_mn=(cluster_size_m, cluster_size_n),
            use_tma_store=design.use_tma_store,
        ):
            return False

        return True

    @staticmethod
    def _valid_operands_for_design(
        operands: GemmOperandsMetadata, design: Sm100DesignMetadata
    ) -> bool:
        # The cluster split-K DSMEM mailbox exchanges and reduces Float32 partials.
        is_cluster_splitk = isinstance(
            design.tile_scheduler.reduction, ClusterSplitKReductionMetadata
        )
        return not is_cluster_splitk or operands.accumulator_type == cutlass.Float32

    @staticmethod
    def _valid_metadata(metadata: OperatorMetadata) -> bool:
        return (
            Sm100DenseGemmUniversalOperator._valid_operands(metadata.operands)
            and metadata.epilogue is None
            and Sm100DenseGemmUniversalOperator._valid_design(metadata.design)
            and Sm100DenseGemmUniversalOperator._valid_operands_for_design(
                metadata.operands, metadata.design
            )
        )

    @classmethod
    def _generate_operators(
        cls,
        metadata_filter: Callable[[OperatorMetadata], bool],
        epilogue_args: EpilogueArguments = None,
        target_sm: TargetSm | None = None,
        args: GemmArguments = None,
    ) -> list[Sm100DenseGemmUniversalOperator]:
        """Returns a list of all possible configurations of Sm100DenseGemmUniversalOperator that
        adhere to constraints passed in under kwargs.
        """

        if epilogue_args is not None:
            return []

        # Co-dependent design parameters are sometimes enumerated as fused
        # axes of legal pairs rather than full cross products for efficiency.

        use_2cta_and_tile_m = [(True, 128), (True, 256), (False, 64), (False, 128)]

        tile_ns = [32, 64, 128, 256]

        cluster_shapes = [
            (M, N, 1)
            for M in [1, 2, 4, 8, 16]
            for N in [1, 2, 4, 8, 16]
            if Sm100DesignMetadata.max_cluster_size >= M * N
        ]

        fallback_cluster_shapes = [(1, 1, 1), (2, 1, 1)]
        cluster_shape_pairs = [
            (cluster_shape, fallback_cluster_shape)
            for cluster_shape in cluster_shapes
            for fallback_cluster_shape in [None, *fallback_cluster_shapes]
            if fallback_cluster_shape is None
            or Sm100DesignMetadata.is_valid_fallback_cluster(
                cluster_shape, fallback_cluster_shape
            )
        ]

        tile_schedulers = scheduling.enumerate_tile_schedulers()

        tma_store_and_scheduler = [
            (
                not isinstance(scheduler.reduction, ClusterSplitKReductionMetadata),
                scheduler,
            )
            for scheduler in tile_schedulers
        ]

        operator_list = []

        if args is not None:
            operands_generator = cls._metadata_operands_from_args(args)
        else:
            operands_generator = cls._metadata_operand_combinations()

        for operands in operands_generator:
            if not cls._valid_operands(operands):
                continue

            tile_k = BlackwellTcgen05Mma.shape_k(operands) * 4  # kphase=4
            for (
                (use_2cta_mma, tile_m),
                tile_n,
                (cluster_shape, fallback_cluster_shape),
                (use_tma_store, tile_scheduler),
            ) in itertools.product(
                use_2cta_and_tile_m,
                tile_ns,
                cluster_shape_pairs,
                tma_store_and_scheduler,
            ):
                # 2CTA MMA needs an even number of CTAs along the cluster's M
                if use_2cta_mma and cluster_shape[0] % 2 != 0:
                    continue

                if fallback_cluster_shape is not None and not (
                    use_tma_store
                    and isinstance(
                        tile_scheduler.persistence,
                        (CLCDynamicPersistentMetadata, StaticPersistentMetadata),
                    )
                    and isinstance(tile_scheduler.reduction, NoReductionMetadata)
                ):
                    continue

                design = Sm100DesignMetadata(
                    mma_instruction_type=BlackwellTcgen05Mma,
                    use_2cta_mma=use_2cta_mma,
                    tile_shape=(tile_m, tile_n, tile_k),
                    cluster_shape=cluster_shape,
                    fallback_cluster_shape=fallback_cluster_shape,
                    use_tma_store=use_tma_store,
                    tile_scheduler=tile_scheduler,
                )
                if not cls._valid_design(design):
                    continue
                if not cls._valid_operands_for_design(operands, design):
                    continue

                operator_name = "cutedsl.Sm100DenseGemmUniversalOperator_{layout}_A{A}_B{B}_out{out}_acc{acc}_{num_cta}cta_cluster{cluster}{fallback}_tile{tile}_scheduler{scheduler}{_tma_store}".format(
                    layout=strides_to_layout_string(
                        operands.A.stride, operands.B.stride, operands.out.stride
                    ),
                    A=operands.A.dtype,
                    B=operands.B.dtype,
                    out=operands.out.dtype,
                    acc=operands.accumulator_type,
                    num_cta=("2" if design.use_2cta_mma else "1"),
                    cluster=tuple_to_string(design.cluster_shape),
                    fallback=""
                    if design.fallback_cluster_shape is None
                    else f"_fallback{tuple_to_string(design.fallback_cluster_shape)}",
                    tile=tuple_to_string(design.tile_shape),
                    scheduler=str(design.tile_scheduler),
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

                if metadata_filter(metadata):
                    operator_list.append(cls(metadata))

        return operator_list
