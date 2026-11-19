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

"""Operator API integration for Rubin contiguous grouped block-scaled GEMM."""

from __future__ import annotations

import itertools
import math
from functools import cache
from typing import TYPE_CHECKING

import cutlass
import cutlass.cute as cute

from cutlass.kernels.rubin.grouped_gemm.sm107_contiguous_grouped_blockscaled_gemm_adapter import (
    Sm107BlockScaledContiguousGroupedGemmAdapter,
)
from cutlass.operators.arch import TargetSm
from cutlass.operators.arguments import (
    DenseTensor,
    EpilogueArgumentsBase,
    IndexPtrGroupedGemmArguments,
    PerGroupScaleEpilogueArguments,
    ScaledOperand,
    ScaleMode,
    ScaleSwizzleMode,
)
from cutlass.operators.device_properties import query_max_active_clusters
from cutlass.operators.metadata import (
    DenseTensorConstraints,
    IndexPtrGroupedGemmOperandsMetadata,
    OperatorMetadata,
    PerGroupScaleEpilogueMetadata,
    ScaledOperandConstraints,
    Sm107DesignMetadata,
)
from cutlass.operators.mma import RubinTcgen05Mma
from cutlass.operators.providers.cutedsl import CuTeDSLProvider
from cutlass.operators.providers.cutedsl.operator import CuteDslOperator
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
    from cutlass.operators.workspace import Workspace


@CuTeDSLProvider.register
class Sm107ContiguousGroupedBlockScaledGemmOperator(CuteDslOperator):
    """Rubin MoE GEMM over tile-aligned groups concatenated along M.

    An auxiliary kernel converts cumulative ``offsets`` to the copied source
    kernel's tile-to-group mapping and valid-tile count in workspace. Every
    offset must be aligned to the selected scheduled tile M because Operator
    discovery does not read device-resident offset values. Callers express that
    invariant through ``offsets_value_divisibility``.

    Requires :class:`PerGroupScaleEpilogueArguments` with ``global_scale_a``
    supplied as the source kernel's per-group ``alpha`` and ``global_scale_b=None``.
    """

    supported_args_type = IndexPtrGroupedGemmArguments
    designed_for_min_cc = 107

    # Each generated operator records one of these tile-alignment requirements.
    # A runtime offset promise may support more than one when it is a multiple.
    _mma_tiler_m_values = (128, 256, 512)

    def __init__(self, metadata: OperatorMetadata):
        super().__init__(metadata)
        operands = metadata.operands
        design = metadata.design
        sf_vec_size = ScaleMode.numel(operands.A.mode)
        mma_inst_shape = self._instruction_shape(operands, design)
        mma_tiler = self._mma_tiler(design)
        self.impl = Sm107BlockScaledContiguousGroupedGemmAdapter(
            sf_vec_size=sf_vec_size,
            mma_inst_shape=mma_inst_shape,
            mma_tiler=mma_tiler,
            cluster_shape_mn=design.cluster_shape[:2],
        )

    @staticmethod
    def _instruction_shape(
        operands: IndexPtrGroupedGemmOperandsMetadata,
        design: Sm107DesignMetadata,
    ) -> tuple[int, int, int]:
        """Derive the source kernel's MMA instruction shape from metadata."""
        instruction_m = 256 if design.use_2cta_mma else 128
        instruction_k = RubinTcgen05Mma.shape_k(operands)
        return (instruction_m, design.tile_shape[1], instruction_k)

    @staticmethod
    def _mma_tiler(
        design: Sm107DesignMetadata,
    ) -> tuple[int, int, int]:
        """Expand the per-CTA design tile across the participating CTAs."""
        mma_ctas = 2 if design.use_2cta_mma else 1
        return (
            design.tile_shape[0] * mma_ctas,
            design.tile_shape[1],
            design.tile_shape[2],
        )

    def _compile(
        self,
        args: IndexPtrGroupedGemmArguments,
        target_sm: TargetSm | None = None,
    ) -> CompiledArtifact:
        stream = cutlass.cute.runtime.make_fake_stream()
        max_active_clusters = query_max_active_clusters(self.impl.cluster_shape_mn)
        return self.cute_compile(
            self.impl,
            args.A.quantized.tensor,
            args.B.quantized.tensor,
            args.out.tensor,
            args.A.scale.tensor,
            args.B.scale.tensor,
            args.offsets.tensor,
            self._make_workspace_pointer(),
            max_active_clusters,
            stream,
            args.epilogue.global_scale_a.tensor,
            target_sm=target_sm,
        )

    def _run(
        self,
        args: IndexPtrGroupedGemmArguments,
        compiled_artifact: CompiledArtifact,
        stream,
        workspace: Workspace | None = None,
        device_properties=None,
    ) -> None:
        if workspace is None:
            raise ValueError(
                "Sm107ContiguousGroupedBlockScaledGemmOperator requires workspace."
            )
        if workspace.alignment_bytes != self.get_workspace_size(args).ptr_alignment:
            raise ValueError(
                "Workspace alignment bytes must match the workspace allocation requirement."
            )
        stream = to_cuda_stream(stream)
        self.cute_run(
            compiled_artifact.compiled_obj,
            args.A.quantized.tensor,
            args.B.quantized.tensor,
            args.out.tensor,
            args.A.scale.tensor,
            args.B.scale.tensor,
            args.offsets.tensor,
            self._make_workspace_pointer(workspace),
            stream,
            args.epilogue.global_scale_a.tensor,
        )

    def _get_workspace_size(
        self, args: IndexPtrGroupedGemmArguments
    ) -> AllocationRequirement:
        return AllocationRequirement(
            size_bytes=self.impl.get_workspace_size(args.A.shape[0]),
            ptr_alignment=self.impl.get_workspace_aligment(),
        )

    @staticmethod
    def _make_workspace_pointer(
        workspace: Workspace | None = None,
    ) -> cute.Pointer:
        """Return the Int32 workspace pointer used by the JIT adapter.

        ``None`` is intentional during compilation: a null-valued fake pointer
        defines the compiled signature. :meth:`_run` rejects a missing runtime
        workspace before invoking the compiled kernel.
        """
        alignment_bytes = (
            Sm107BlockScaledContiguousGroupedGemmAdapter.get_workspace_aligment()
        )
        address = 0 if workspace is None else workspace.data.data_ptr
        return cute.runtime.make_ptr(
            cutlass.Int32,
            address,
            cutlass.AddressSpace.gmem,
            assumed_align=alignment_bytes,
        )

    def _initialize_workspace(
        self, args: IndexPtrGroupedGemmArguments, workspace: Workspace
    ) -> None:
        pass

    @classmethod
    def _major_modes(
        cls,
        operands: IndexPtrGroupedGemmOperandsMetadata,
    ) -> tuple[str, str, str]:
        return cls._major_modes_from_strides(
            operands.A.stride,
            operands.B.stride,
            operands.out.stride,
        )

    @staticmethod
    def _major_modes_from_strides(
        a_stride: tuple[int, ...],
        b_stride: tuple[int, ...],
        out_stride: tuple[int, ...],
    ) -> tuple[str, str, str]:
        """Return the source kernel's names for the contiguous tensor modes."""
        a_major = "k" if a_stride[-2:].index(1) == 1 else "m"
        b_major = "k" if b_stride[-2:].index(1) == 0 else "n"
        out_major = "n" if out_stride[-2:].index(1) == 1 else "m"
        return a_major, b_major, out_major

    @classmethod
    def _construct_operands(
        cls,
        a_dtype: type[cutlass.Numeric],
        b_dtype: type[cutlass.Numeric],
        sf_dtype: type[cutlass.Numeric],
        out_dtype: type[cutlass.Numeric],
        scale_mode: ScaleMode,
        a_stride: tuple[int, ...] = (0, 1),
        b_stride: tuple[int, ...] = (0, 1, 0),
        out_stride: tuple[int, ...] = (0, 1),
        *,
        offsets_value_divisibility: int | None = None,
    ) -> IndexPtrGroupedGemmOperandsMetadata:
        """Construct tensor constraints and validate the offset guarantee."""

        minimum_offsets_value_divisibility = cls._minimum_offsets_value_divisibility(
            a_stride=a_stride,
            a_divisibility=cls._alignment_divisibility(a_dtype),
            out_stride=out_stride,
            out_divisibility=cls._alignment_divisibility(out_dtype),
        )
        if (
            offsets_value_divisibility is not None
            and offsets_value_divisibility % minimum_offsets_value_divisibility != 0
        ):
            raise ValueError(
                "offsets_value_divisibility must be a multiple of the minimum "
                "required by the tensor divisibility constraints "
                f"({minimum_offsets_value_divisibility}), got "
                f"{offsets_value_divisibility}."
            )

        def scale_constraints() -> DenseTensorConstraints:
            return DenseTensorConstraints(
                dtype=sf_dtype,
                stride=None,
                divisibility=cls._alignment_divisibility(sf_dtype),
            )

        def int32_constraints() -> DenseTensorConstraints:
            return DenseTensorConstraints(
                dtype=cutlass.Int32,
                stride=(1,),
                divisibility=1,
            )

        operands = IndexPtrGroupedGemmOperandsMetadata(
            A=ScaledOperandConstraints(
                quantized=DenseTensorConstraints(
                    dtype=a_dtype,
                    stride=a_stride,
                    divisibility=cls._alignment_divisibility(a_dtype),
                ),
                scale=scale_constraints(),
                mode=scale_mode,
                swizzle=ScaleSwizzleMode.Swizzle32x4x4,
            ),
            B=ScaledOperandConstraints(
                quantized=DenseTensorConstraints(
                    dtype=b_dtype,
                    stride=b_stride,
                    divisibility=cls._alignment_divisibility(b_dtype),
                ),
                scale=scale_constraints(),
                mode=scale_mode,
                swizzle=ScaleSwizzleMode.Swizzle32x4x4,
            ),
            out=DenseTensorConstraints(
                dtype=out_dtype,
                stride=out_stride,
                divisibility=cls._alignment_divisibility(out_dtype),
            ),
            offsets=int32_constraints(),
            offsets_along="m",
            accumulator_type=cutlass.Float32,
            offsets_value_divisibility=offsets_value_divisibility,
        )

        return operands

    @classmethod
    def _operand_keys_from_args(
        cls,
        args: IndexPtrGroupedGemmArguments,
    ) -> dict[str, tuple] | None:
        """Return the operand configuration requested by ``args``, or ``None``."""
        if not isinstance(args, IndexPtrGroupedGemmArguments):
            return None
        if args.offsets_along != "m":
            return None
        if not isinstance(args.A, ScaledOperand) or not isinstance(
            args.B, ScaledOperand
        ):
            return None
        if not all(
            isinstance(tensor, DenseTensor)
            for tensor in (
                args.A.quantized,
                args.A.scale,
                args.B.quantized,
                args.B.scale,
                args.out,
                args.offsets,
            )
        ):
            return None
        if (
            args.A.dtype != args.B.dtype
            or args.A.scale.dtype != args.B.scale.dtype
            or not ScaleMode.compare(args.A.mode, args.B.mode)
            or args.A.swizzle is not ScaleSwizzleMode.Swizzle32x4x4
            or args.B.swizzle is not ScaleSwizzleMode.Swizzle32x4x4
            or args.accumulator_type is not cutlass.Float32
            or args.offsets.dtype is not cutlass.Int32
            or args.offsets.stride != (1,)
        ):
            return None

        M, K = args.A.shape
        L, _, N = args.B.shape
        if args.A.scale.numel() != ScaledOperand.numel_scale(
            (1, M, K), args.A.mode, args.A.swizzle
        ) or args.B.scale.numel() != ScaledOperand.numel_scale(
            (L, N, K), args.B.mode, args.B.swizzle
        ):
            return None

        actual_strides = tuple(
            normalized_major_stride(operand.shape, operand.stride)
            for operand in (args.A, args.B, args.out)
        )

        valid_mma_tiler_m_values = tuple(
            mma_tiler_m
            for mma_tiler_m in cls._mma_tiler_m_values
            if args.offsets_value_divisibility % mma_tiler_m == 0
        )
        if not valid_mma_tiler_m_values:
            return None

        return {
            "input_dtype": (args.A.dtype,),
            "sf_dtype": (args.A.scale.dtype,),
            "out_dtype": (args.out.dtype,),
            "scale_mode": (args.A.mode,),
            "a_stride": (actual_strides[0],),
            "b_stride": (actual_strides[1],),
            "out_stride": (actual_strides[2],),
            "offsets_value_divisibility": valid_mma_tiler_m_values,
            "problem_shape": ((M, N, K, L),),
        }

    @classmethod
    def _metadata_operand_combinations(
        cls,
        args: IndexPtrGroupedGemmArguments | None = None,
    ) -> Generator[IndexPtrGroupedGemmOperandsMetadata, None, None]:
        """Yield kernel-supported operands, optionally narrowed by ``args``."""
        operand_keys = {
            "input_dtype": (
                cutlass.Float4E2M1FN,
                cutlass.Float8E4M3FN,
                cutlass.Float8E5M2,
            ),
            "sf_dtype": (cutlass.Float8E4M3FN, cutlass.Float8E8M0FNU),
            "out_dtype": (cutlass.Float32, cutlass.Float16, cutlass.BFloat16),
            "scale_mode": (ScaleMode.Blockwise1x16, ScaleMode.Blockwise1x32),
            "a_stride": ((0, 1), (1, 0)),
            "b_stride": ((0, 1, 0), (0, 0, 1)),
            "out_stride": ((0, 1), (1, 0)),
            "offsets_value_divisibility": cls._mma_tiler_m_values,
            "problem_shape": (None,),
        }

        if args is not None:
            requested_keys = cls._operand_keys_from_args(args)
            if requested_keys is None:
                return
            runtime_keys = {"offsets_value_divisibility", "problem_shape"}
            if any(
                values[0] not in operand_keys[key]
                for key, values in requested_keys.items()
                if key not in runtime_keys
            ):
                return
            operand_keys |= requested_keys

        for operand_values in itertools.product(*operand_keys.values()):
            operand_combo = dict(zip(operand_keys, operand_values))
            if not cls._kernel_accepts_operands(**operand_combo):
                continue
            yield cls._construct_operands(
                operand_combo["input_dtype"],
                operand_combo["input_dtype"],
                operand_combo["sf_dtype"],
                operand_combo["out_dtype"],
                operand_combo["scale_mode"],
                operand_combo["a_stride"],
                operand_combo["b_stride"],
                operand_combo["out_stride"],
                offsets_value_divisibility=operand_combo["offsets_value_divisibility"],
            )

    @classmethod
    def _kernel_accepts_operands(
        cls,
        input_dtype: type[cutlass.Numeric],
        sf_dtype: type[cutlass.Numeric],
        out_dtype: type[cutlass.Numeric],
        scale_mode: ScaleMode,
        a_stride: tuple[int, ...],
        b_stride: tuple[int, ...],
        out_stride: tuple[int, ...],
        offsets_value_divisibility: int | None,
        problem_shape: tuple[int, int, int, int] | None,
    ) -> bool:
        """Return whether the adapter supports one operand configuration."""
        impl = Sm107BlockScaledContiguousGroupedGemmAdapter
        if not impl.is_valid_dtypes_and_scale_factor_vec_size(
            input_dtype,
            input_dtype,
            sf_dtype,
            ScaleMode.numel(scale_mode),
            out_dtype,
        ):
            return False

        major_modes = cls._major_modes_from_strides(a_stride, b_stride, out_stride)
        if not impl.is_valid_layouts(input_dtype, input_dtype, out_dtype, *major_modes):
            return False
        if problem_shape is not None and not impl.is_valid_tensor_alignment(
            *problem_shape,
            input_dtype,
            input_dtype,
            out_dtype,
            *major_modes,
        ):
            return False

        minimum_offsets_value_divisibility = cls._minimum_offsets_value_divisibility(
            a_stride=a_stride,
            a_divisibility=cls._alignment_divisibility(input_dtype),
            out_stride=out_stride,
            out_divisibility=cls._alignment_divisibility(out_dtype),
        )
        return (
            offsets_value_divisibility is None
            or offsets_value_divisibility % minimum_offsets_value_divisibility == 0
        )

    @staticmethod
    def _alignment_divisibility(dtype: type[cutlass.Numeric]) -> int:
        """Return the element divisibility needed for 16-byte alignment."""
        return 16 * 8 // dtype.width

    @staticmethod
    def _minimum_offsets_value_divisibility(
        *,
        a_stride: tuple[int, ...],
        a_divisibility: int,
        out_stride: tuple[int, ...],
        out_divisibility: int,
    ) -> int:
        """Derive the weakest offset guarantee satisfying M tensor constraints."""
        divisibilities = []
        if a_stride[-2] == 1:
            divisibilities.append(a_divisibility)
        if out_stride[-2] == 1:
            divisibilities.append(out_divisibility)
        return math.lcm(*divisibilities)

    @classmethod
    @cache
    def _metadata_design_combinations(
        cls,
        instruction_k: int,
        a_dtype: type[cutlass.Numeric],
        b_dtype: type[cutlass.Numeric],
        mma_tiler_m: int,
    ) -> tuple[tuple[Sm107DesignMetadata, str], ...]:
        """Return cached designs and names."""
        if mma_tiler_m not in cls._mma_tiler_m_values:
            return ()

        mma_instruction_shapes = tuple(
            (instruction_m, instruction_n, instruction_k)
            for instruction_m in (128, 256)
            # if breuse is enabled, mma_tiler_m is equal to instruction_m * 2
            if instruction_m <= mma_tiler_m <= instruction_m * 2
            for instruction_n in (64, 128, 192, 256)
        )
        designs = []
        for instruction_m, instruction_n, instruction_k in mma_instruction_shapes:
            instruction_shape = (
                instruction_m,
                instruction_n,
                instruction_k,
            )
            use_2cta_mma = instruction_m == 256
            mma_ctas = 2 if use_2cta_mma else 1
            enable_breuse = instruction_m * 2 == mma_tiler_m
            cta_tile_m = mma_tiler_m // mma_ctas
            cta_tile_shape = (cta_tile_m, instruction_n, instruction_k * 2)
            mma_tiler = (mma_tiler_m, instruction_n, instruction_k * 2)

            cluster_m = 2 if use_2cta_mma else 1
            for cluster_n in (1, 2, 4):
                cluster_shape_mn = (cluster_m, cluster_n)
                if not Sm107BlockScaledContiguousGroupedGemmAdapter.is_valid_mma_tiler_and_cluster_shape(
                    a_dtype,
                    b_dtype,
                    instruction_shape,
                    mma_tiler,
                    cluster_shape_mn,
                ):
                    continue
                design = Sm107DesignMetadata(
                    mma_instruction_type=RubinTcgen05Mma,
                    use_2cta_mma=use_2cta_mma,
                    tile_shape=cta_tile_shape,
                    cluster_shape=(cluster_m, cluster_n, 1),
                    fallback_cluster_shape=None,
                    use_tma_store=True,
                    enable_breuse=enable_breuse,
                )
                designs.append((design, cls._design_name(design)))
        return tuple(designs)

    @classmethod
    def _generate_operators(
        cls,
        metadata_filter: Callable[[OperatorMetadata], bool],
        epilogue_args: EpilogueArgumentsBase | None = None,
        target_sm: TargetSm | None = None,
        args: IndexPtrGroupedGemmArguments | None = None,
    ) -> list[CuteDslOperator]:
        """Generate source-kernel configurations narrowed by runtime arguments."""
        if not isinstance(epilogue_args, PerGroupScaleEpilogueArguments):
            return []
        if (
            epilogue_args.global_scale_a is None
            or epilogue_args.global_scale_b is not None
        ):
            return []
        epilogue_metadata = PerGroupScaleEpilogueMetadata(
            global_scale_a=DenseTensorConstraints(
                dtype=cutlass.Float32,
                stride=(1,),
                divisibility=1,
                ptr_alignment_bytes=4,
            ),
        )
        operators = []
        for operands in cls._metadata_operand_combinations(args):
            operand_name = cls._operand_name(operands)
            instruction_k = RubinTcgen05Mma.shape_k(operands)
            for design, design_name in cls._metadata_design_combinations(
                instruction_k,
                operands.A.dtype,
                operands.B.dtype,
                operands.offsets_value_divisibility,
            ):
                metadata = OperatorMetadata(
                    operands=operands,
                    design=design,
                    operator_name=(
                        "cutedsl.Sm107ContiguousGroupedBlockScaledGemmOperator"
                        f"_{operand_name}_{design_name}_global_scale_a"
                    ),
                    operator_class=cls,
                    supported_targets=TargetSm.get_supported_targets(design, operands),
                    epilogue=epilogue_metadata,
                )
                if metadata_filter(metadata):
                    operators.append(cls(metadata))
        return operators

    @staticmethod
    def _operand_name(
        operands: IndexPtrGroupedGemmOperandsMetadata,
    ) -> str:
        """Build the operand portion of the canonical name."""
        return (
            "{layout}_A{A}_B{B}_out{out}_SFA{SFA}_SFB{SFB}"
            "_acc{acc}_scale{scale_mode}_swizzle{scale_swizzle}"
            "_offsetdiv{offset_divisibility}"
        ).format(
            layout=strides_to_layout_string(
                operands.A.stride, operands.B.stride, operands.out.stride
            ),
            A=operands.A.dtype,
            B=operands.B.dtype,
            out=operands.out.dtype,
            SFA=operands.A.scale.dtype,
            SFB=operands.B.scale.dtype,
            acc=operands.accumulator_type,
            scale_mode=operands.A.mode.name,
            scale_swizzle=operands.A.swizzle.name,
            offset_divisibility=operands.offsets_value_divisibility,
        )

    @staticmethod
    def _design_name(design: Sm107DesignMetadata) -> str:
        """Build the design portion of the canonical name."""
        return ("{num_cta}cta_cluster{cluster}_tile{tile}{_breuse}{_tma_store}").format(
            num_cta="2" if design.use_2cta_mma else "1",
            cluster=tuple_to_string(design.cluster_shape),
            tile=tuple_to_string(design.tile_shape),
            _breuse="_breuse" if design.enable_breuse else "",
            _tma_store="_tma_store" if design.use_tma_store else "",
        )
