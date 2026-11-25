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
from typing import TYPE_CHECKING

import cutlass
import cutlass.cute as cute

from cutlass.operators.arch import TargetSm
from cutlass.operators.arguments import (
    DenseTensor,
    EpilogueArguments,
    IndexPtrGroupedGemmArguments,
)
from cutlass.operators.metadata import (
    DenseTensorConstraints,
    DesignMetadata,
    EpilogueMetadata,
    IndexPtrGroupedGemmOperandsMetadata,
    OperatorMetadata,
    Sm100DesignMetadata,
)
from cutlass.operators.mma import BlackwellTcgen05Mma
from cutlass.operators.providers.cutedsl import CuTeDSLProvider
from cutlass.operators.providers.cutedsl import integration_utils as cutedsl_utils
from cutlass.operators.providers.cutedsl.operator import CuteDslOperator
from cutlass.operators.status import Status
from cutlass.operators.utils.common import tuple_to_string
from cutlass.operators.utils.device import to_cuda_stream
from cutlass.operators.utils.gemm import (
    tensor_output_shape_matches,
    tensor_reduction_mode_matches,
)
from cutlass.operators.utils.tensor import (
    TensorWrapper,
    normalized_major_stride,
    strides_to_layout_string,
)
from cutlass.operators.workspace import AllocationRequirement

from .implementations.sm100_moe_grouped_gemm_impl import GroupedGemmKernel

if TYPE_CHECKING:
    from collections.abc import Callable, Generator

    from cutlass.operators.artifact import CompiledArtifact
    from cutlass.operators.device_properties import (
        DeviceProperties,
    )
    from cutlass.operators.workspace import Workspace


@CuTeDSLProvider.register
class Sm100PersistentGroupedGemmOperator(CuteDslOperator):
    """Persistent dense SM100 grouped GEMM for MoE forward and weight-gradient shapes."""

    supported_args_type = IndexPtrGroupedGemmArguments
    designed_for_min_cc = 100

    workspace_alignment_bytes = 128
    tensor_alignment_bytes = 16
    valid_major_strides = ((0, 0, 1), (0, 1, 0))
    supported_dtype_configs = (
        (cutlass.BFloat16, cutlass.BFloat16, cutlass.Float32),
        (cutlass.Float16, cutlass.Float16, cutlass.Float16),
        (cutlass.Float16, cutlass.Float32, cutlass.Float32),
    )
    tile_shape_candidates = (
        (64, 32, 16),
        (128, 128, 32),
        (256, 256, 64),
        (128, 128, 128),
    )
    cluster_shape_candidates = (
        (1, 1, 1),
        (1, 2, 1),
        (1, 4, 1),
        (2, 1, 1),
        (2, 2, 1),
        (2, 4, 1),
        (4, 1, 1),
        (4, 2, 1),
        (4, 4, 1),
    )

    def __init__(self, metadata: OperatorMetadata):
        super().__init__(metadata)
        scenario = {"m": "2Dx3D", "k": "2Dx2D"}[metadata.operands.offsets_along]
        self.impl = GroupedGemmKernel(
            scenario=scenario,
            out_dtype=metadata.operands.out.dtype,
            accumulate_on_output=metadata.operands.accumulate_on_output,
            separate_tensormap_init=True,
            fixed_expert_cnt=None,
            acc_dtype=metadata.operands.accumulator_type,
            mma_tiler_mnk=metadata.design.tile_shape,
            cluster_shape_mnk=metadata.design.cluster_shape,
            use_2cta_instrs=metadata.design.use_2cta_mma,
        )

    def _supports(
        self,
        args: IndexPtrGroupedGemmArguments,
        target_sm: TargetSm | None = None,
    ) -> Status:
        if args.offsets_along not in ("m", "k"):
            return Status.fail(
                "Sm100PersistentGroupedGemmOperator supports offsets_along='m' or 'k'."
            )
        if not all(
            isinstance(operand, DenseTensor)
            for operand in (args.A, args.B, args.out, args.offsets)
        ):
            return Status.fail("A, B, out, and offsets must be DenseTensor operands.")
        if args.epilogue is not None:
            return Status.fail("Custom epilogues are not supported.")
        if args.accumulate_on_output and args.offsets_along != "k":
            return Status.fail(
                "accumulate_on_output=True is supported only for offsets_along='k'."
            )
        if not (status := tensor_reduction_mode_matches(args)):
            return status
        if not (status := tensor_output_shape_matches(args)):
            return status

        expert_count = args.offsets.numel()
        if expert_count <= 0:
            return Status.fail("offsets must contain at least one expert boundary.")
        grouped_operand_count = (
            args.B.shape[0] if args.offsets_along == "m" else args.out.shape[0]
        )
        if grouped_operand_count != expert_count:
            grouped_operand_name = "B" if args.offsets_along == "m" else "out"
            return Status.fail(
                f"{grouped_operand_name} must contain {expert_count} expert slices, got {grouped_operand_count}."
            )
        return Status.success()

    @staticmethod
    def _make_workspace_pointer(
        workspace_data, *, allow_null: bool = False
    ) -> cute.Pointer:
        if isinstance(workspace_data, bool):
            raise TypeError(
                "workspace.data must be a tensor or integer device address, not bool."
            )

        if isinstance(workspace_data, int):
            address = workspace_data
            workspace_tensor = None
        else:
            workspace_tensor = TensorWrapper(
                workspace_data,
                alignment_bytes=1,
            )
            address = workspace_tensor.data_ptr

        if address == 0 and not allow_null:
            raise ValueError(
                "workspace.data must reference a non-null device allocation."
            )
        if address % Sm100PersistentGroupedGemmOperator.workspace_alignment_bytes != 0:
            raise ValueError(
                "workspace.data must be aligned to "
                f"{Sm100PersistentGroupedGemmOperator.workspace_alignment_bytes} bytes."
            )

        if workspace_tensor is not None and workspace_tensor.dtype == cutlass.Uint8:
            return cutedsl_utils.builders.make_ptr(
                workspace_tensor,
                address_space=cutlass.AddressSpace.gmem,
                assumed_align=Sm100PersistentGroupedGemmOperator.workspace_alignment_bytes,
            )
        return cute.runtime.make_ptr(
            cutlass.Uint8,
            address,
            cutlass.AddressSpace.gmem,
            Sm100PersistentGroupedGemmOperator.workspace_alignment_bytes,
        )

    def _compile(
        self,
        args: IndexPtrGroupedGemmArguments,
        target_sm: TargetSm | None = None,
    ) -> CompiledArtifact:
        stream = cutlass.cute.runtime.make_fake_stream()
        workspace_ptr = self._make_workspace_pointer(0, allow_null=True)
        return self.cute_compile(
            self.impl,
            args.A.tensor,
            args.B.tensor,
            args.out.tensor,
            args.offsets.tensor,
            None,
            workspace_ptr,
            # Placeholder: querying real occupancy would need a GPU to compile.
            cutlass.Int32(0),
            stream,
            target_sm=target_sm,
        )

    def _run(
        self,
        args: IndexPtrGroupedGemmArguments,
        compiled_artifact: CompiledArtifact,
        stream,
        workspace: Workspace | None = None,
        *,
        device_properties: DeviceProperties,
    ) -> None:
        if workspace is None:
            raise ValueError("Sm100PersistentGroupedGemmOperator requires a workspace.")

        stream = to_cuda_stream(stream)
        workspace_ptr = self._make_workspace_pointer(workspace.data)
        self.cute_run(
            compiled_artifact.compiled_obj,
            args.A.tensor,
            args.B.tensor,
            args.out.tensor,
            args.offsets.tensor,
            None,
            workspace_ptr,
            device_properties.max_active_clusters(self.impl.cluster_shape_mn),
            stream,
        )

    def _get_workspace_size(
        self,
        args: IndexPtrGroupedGemmArguments,
    ) -> AllocationRequirement:
        return AllocationRequirement(
            size_bytes=self.impl.get_workspace_size(args.offsets.numel()),
            ptr_alignment=self.workspace_alignment_bytes,
        )

    def _initialize_workspace(
        self,
        args: IndexPtrGroupedGemmArguments,
        workspace: Workspace,
    ) -> None:
        return None

    @classmethod
    def _required_offsets_value_divisibility(
        cls,
        offsets_along: str,
        a_dtype: cutlass.Numeric,
        b_dtype: cutlass.Numeric,
        out_dtype: cutlass.Numeric,
        a_stride: tuple[int, ...],
        b_stride: tuple[int, ...],
        out_stride: tuple[int, ...],
    ) -> int:
        a_alignment = cls.tensor_alignment_bytes * 8 // a_dtype.width
        b_alignment = cls.tensor_alignment_bytes * 8 // b_dtype.width
        out_alignment = cls.tensor_alignment_bytes * 8 // out_dtype.width
        required_divisibilities = [1]

        if offsets_along == "m":
            if a_stride[-2:].index(1) == 0:
                required_divisibilities.append(a_alignment)
            if out_stride[-2:].index(1) == 0:
                required_divisibilities.append(out_alignment)
        else:
            if a_stride[-2:].index(1) == 1:
                required_divisibilities.append(a_alignment)
            if b_stride[-2:].index(1) == 0:
                required_divisibilities.append(b_alignment)

        return max(required_divisibilities)

    @classmethod
    def _construct_operands(
        cls,
        a_dtype: cutlass.Numeric,
        b_dtype: cutlass.Numeric,
        out_dtype: cutlass.Numeric,
        accumulator_type: cutlass.Numeric,
        a_stride: tuple[int, ...],
        b_stride: tuple[int, ...],
        out_stride: tuple[int, ...],
        offsets_along: str,
        accumulate_on_output: bool,
    ) -> IndexPtrGroupedGemmOperandsMetadata:
        a_divisibility = cls.tensor_alignment_bytes * 8 // a_dtype.width
        b_divisibility = cls.tensor_alignment_bytes * 8 // b_dtype.width
        out_divisibility = cls.tensor_alignment_bytes * 8 // out_dtype.width
        offsets_value_divisibility = cls._required_offsets_value_divisibility(
            offsets_along,
            a_dtype,
            b_dtype,
            out_dtype,
            a_stride,
            b_stride,
            out_stride,
        )
        return IndexPtrGroupedGemmOperandsMetadata(
            A=DenseTensorConstraints(a_dtype, a_stride, a_divisibility),
            B=DenseTensorConstraints(b_dtype, b_stride, b_divisibility),
            out=DenseTensorConstraints(out_dtype, out_stride, out_divisibility),
            offsets=DenseTensorConstraints(cutlass.Int32, (1,), 1),
            offsets_along=offsets_along,
            accumulator_type=accumulator_type,
            offsets_value_divisibility=offsets_value_divisibility,
            accumulate_on_output=accumulate_on_output,
        )

    @classmethod
    def _valid_operands(cls, operands: IndexPtrGroupedGemmOperandsMetadata) -> bool:
        if not isinstance(operands, IndexPtrGroupedGemmOperandsMetadata):
            return False
        if not all(
            isinstance(operand, DenseTensorConstraints)
            for operand in (operands.A, operands.B, operands.out, operands.offsets)
        ):
            return False
        if operands.offsets_along not in ("m", "k"):
            return False
        if operands.accumulate_on_output and operands.offsets_along != "k":
            return False
        if operands.A.dtype != operands.B.dtype:
            return False
        dtype_config = (operands.A.dtype, operands.out.dtype, operands.accumulator_type)
        if dtype_config not in cls.supported_dtype_configs:
            return False
        if operands.offsets.dtype != cutlass.Int32 or operands.offsets.stride != (1,):
            return False
        if any(
            operand.stride not in cls.valid_major_strides
            for operand in (operands.A, operands.B, operands.out)
        ):
            return False

        required_divisibility = cls._required_offsets_value_divisibility(
            operands.offsets_along,
            operands.A.dtype,
            operands.B.dtype,
            operands.out.dtype,
            operands.A.stride,
            operands.B.stride,
            operands.out.stride,
        )
        return operands.offsets_value_divisibility % required_divisibility == 0

    @classmethod
    def _valid_design_metadata(cls, design: DesignMetadata) -> bool:
        if not isinstance(design, Sm100DesignMetadata):
            return False
        if design.mma_instruction_type is not BlackwellTcgen05Mma:
            return False
        if not design.use_tma_store:
            return False
        if design.tile_shape not in cls.tile_shape_candidates:
            return False

        cluster_m, cluster_n, cluster_k = design.cluster_shape
        if cluster_k != 1 or cluster_m <= 0 or cluster_n <= 0:
            return False
        if cluster_m > 4 or cluster_n > 4:
            return False
        if cluster_m * cluster_n > 16:
            return False
        if cluster_m & (cluster_m - 1) or cluster_n & (cluster_n - 1):
            return False

        per_cta_tile_m = design.tile_shape[0] // (2 if design.use_2cta_mma else 1)
        if per_cta_tile_m not in (64, 128):
            return False
        if design.use_2cta_mma and cluster_m % 2 != 0:
            return False
        return True

    @staticmethod
    def _valid_epilogue_metadata(epilogue: EpilogueMetadata | None) -> bool:
        return epilogue is None

    @classmethod
    def _valid_metadata(cls, metadata: OperatorMetadata) -> bool:
        return (
            cls._valid_operands(metadata.operands)
            and cls._valid_design_metadata(metadata.design)
            and cls._valid_epilogue_metadata(metadata.epilogue)
        )

    @classmethod
    def _metadata_operands_from_args(
        cls,
        args: IndexPtrGroupedGemmArguments,
    ) -> Generator[IndexPtrGroupedGemmOperandsMetadata, None, None]:
        if args.offsets_along not in ("m", "k"):
            return
        if args.epilogue is not None:
            return
        if not all(
            isinstance(operand, DenseTensor)
            for operand in (args.A, args.B, args.out, args.offsets)
        ):
            return
        if args.offsets.dtype != cutlass.Int32:
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
        if any(
            stride not in cls.valid_major_strides
            for stride in (a_stride, b_stride, out_stride)
        ):
            return

        operands = cls._construct_operands(
            args.A.dtype,
            args.B.dtype,
            args.out.dtype,
            args.accumulator_type,
            a_stride,
            b_stride,
            out_stride,
            args.offsets_along,
            args.accumulate_on_output,
        )
        if cls._valid_operands(operands) and (
            args.offsets_value_divisibility % operands.offsets_value_divisibility == 0
        ):
            yield operands

    @classmethod
    def _metadata_operand_combinations(
        cls,
    ) -> Generator[IndexPtrGroupedGemmOperandsMetadata, None, None]:
        for a_dtype, out_dtype, accumulator_type in cls.supported_dtype_configs:
            for offsets_along in ("m", "k"):
                accumulation_options = (
                    (False,) if offsets_along == "m" else (False, True)
                )
                for a_stride, b_stride, out_stride in itertools.product(
                    cls.valid_major_strides, repeat=3
                ):
                    for accumulate_on_output in accumulation_options:
                        yield cls._construct_operands(
                            a_dtype,
                            a_dtype,
                            out_dtype,
                            accumulator_type,
                            a_stride,
                            b_stride,
                            out_stride,
                            offsets_along,
                            accumulate_on_output,
                        )

    @classmethod
    def _metadata_design_combinations(
        cls,
    ) -> Generator[tuple[Sm100DesignMetadata, str], None, None]:
        for use_2cta_mma in (False, True):
            tile_shapes = (
                tile_shape
                for tile_shape in cls.tile_shape_candidates
                if tile_shape[0] // (2 if use_2cta_mma else 1) in (64, 128)
            )
            cluster_shapes = (
                cluster_shape
                for cluster_shape in cls.cluster_shape_candidates
                if not use_2cta_mma or cluster_shape[0] % 2 == 0
            )
            for tile_shape, cluster_shape in itertools.product(
                tile_shapes, cluster_shapes
            ):
                design = Sm100DesignMetadata(
                    mma_instruction_type=BlackwellTcgen05Mma,
                    tile_shape=tile_shape,
                    cluster_shape=cluster_shape,
                    use_2cta_mma=use_2cta_mma,
                    use_tma_store=True,
                )
                design_name = (
                    f"{2 if use_2cta_mma else 1}cta_"
                    f"cluster{tuple_to_string(cluster_shape)}_"
                    f"tile{tuple_to_string(tile_shape)}_"
                    "dynamic_experts_separate_tensormap"
                )
                yield design, design_name

    @classmethod
    def _generate_operators(
        cls,
        metadata_filter: Callable[[OperatorMetadata], bool],
        epilogue_args: EpilogueArguments = None,
        target_sm: TargetSm | None = None,
        args: IndexPtrGroupedGemmArguments = None,
    ) -> list[Sm100PersistentGroupedGemmOperator]:
        if epilogue_args is not None:
            return []

        operands_generator = (
            cls._metadata_operands_from_args(args)
            if args is not None
            else cls._metadata_operand_combinations()
        )
        design_combinations = tuple(cls._metadata_design_combinations())
        operators = []
        for operands in operands_generator:
            scenario = "2Dx3D" if operands.offsets_along == "m" else "2Dx2D"
            operands_name = (
                "cutedsl.Sm100PersistentGroupedGemmOperator_"
                "{scenario}_{layout}_A{a}_B{b}_out{out}_acc{acc}_"
                "offsetdiv{offset_divisibility}_{accumulation}"
            ).format(
                scenario=scenario,
                layout=strides_to_layout_string(
                    operands.A.stride,
                    operands.B.stride,
                    operands.out.stride,
                ),
                a=operands.A.dtype,
                b=operands.B.dtype,
                out=operands.out.dtype,
                acc=operands.accumulator_type,
                offset_divisibility=operands.offsets_value_divisibility,
                accumulation=(
                    "accumulate" if operands.accumulate_on_output else "overwrite"
                ),
            )
            for design, design_name in design_combinations:
                metadata = OperatorMetadata(
                    operands=operands,
                    design=design,
                    operator_name=f"{operands_name}_{design_name}",
                    operator_class=cls,
                    supported_targets=TargetSm.get_supported_targets(design, operands),
                    epilogue=None,
                )
                if metadata_filter(metadata):
                    operators.append(cls(metadata))
        return operators
