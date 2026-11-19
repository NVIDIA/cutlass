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
from math import lcm
from typing import TYPE_CHECKING

import cutlass
import cutlass.cute as cute

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
from cutlass.operators.metadata import (
    DenseTensorConstraints,
    DesignMetadata,
    EpilogueMetadataBase,
    IndexPtrGroupedGemmOperandsMetadata,
    OperatorMetadata,
    PerGroupScaleEpilogueMetadata,
    ScaledOperandConstraints,
    Sm100DesignMetadata,
)
from cutlass.operators.mma import BlackwellTcgen05Mma
from cutlass.operators.providers.cutedsl import CuTeDSLProvider
from cutlass.operators.providers.cutedsl.operator import CuteDslOperator
from cutlass.operators.status import Status
from cutlass.operators.utils.common import ceil_div, round_up, tuple_to_string
from cutlass.operators.utils.device import to_cuda_stream
from cutlass.operators.utils.tensor import (
    TensorWrapper,
    get_stride_rank,
    normalized_major_stride,
    strides_to_layout_string,
)
from cutlass.operators.workspace import AllocationRequirement, Workspace

from .implementations.sm100_moe_scaled_grouped_gemm_impl import (
    ScaledGroupedGemmKernel,
)

if TYPE_CHECKING:
    from collections.abc import Callable, Generator

    from cutlass.operators.artifact import CompiledArtifact
    from cutlass.operators.device_properties import (
        DeviceProperties,
    )


_workspace_alignment_bytes = 128
_scale_alignment_bytes = 16
_format_specs = (
    (
        "mxfp8",
        cutlass.Float8E4M3FN,
        cutlass.Float8E8M0FNU,
        ScaleMode.Blockwise1x32,
        False,
    ),
    (
        "mxfp4",
        cutlass.Float4E2M1FN,
        cutlass.Float8E8M0FNU,
        ScaleMode.Blockwise1x32,
        False,
    ),
    (
        "nvfp4",
        cutlass.Float4E2M1FN,
        cutlass.Float8E4M3FN,
        ScaleMode.Blockwise1x16,
        True,
    ),
)
_cluster_shape_candidates = (
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
_cta_cluster_shape_candidates = tuple(
    (use_2cta_mma, cluster_shape)
    for use_2cta_mma, cluster_shape in itertools.product(
        (False, True), _cluster_shape_candidates
    )
    if not use_2cta_mma or cluster_shape[0] % 2 == 0
)
_tile_n_candidates = (64, 128, 256)
_tile_k_multipliers = (1, 2, 4, 8)


@CuTeDSLProvider.register
class Sm100MoEScaledGroupedGemmOperator(CuteDslOperator):
    """SM100 persistent grouped GEMM for MXFP8, MXFP4, and NVFP4 operands."""

    supported_args_type = IndexPtrGroupedGemmArguments
    designed_for_min_cc = 100

    def __init__(self, metadata: OperatorMetadata):
        super().__init__(metadata)
        operands = metadata.operands
        self.impl = ScaledGroupedGemmKernel(
            scenario=self._scenario(operands.offsets_along),
            sf_vec_size=ScaleMode.numel(operands.A.mode),
            accumulate_on_output=operands.accumulate_on_output,
            separate_tensormap_init=True,
            scale_offsets_match_data=self._reuses_data_offsets(operands),
            acc_dtype=operands.accumulator_type,
            mma_tiler_mnk=metadata.design.tile_shape,
            cluster_shape_mnk=metadata.design.cluster_shape,
            use_2cta_instrs=metadata.design.use_2cta_mma,
            fixed_expert_cnt=None,
        )

    @staticmethod
    def _scenario(offsets_along: str) -> str:
        if offsets_along == "m":
            return "2Dx3D"
        if offsets_along == "k":
            return "2Dx2D"
        raise ValueError(f"Unsupported offsets axis: {offsets_along!r}")

    @staticmethod
    def _major_modes(
        operands: IndexPtrGroupedGemmArguments | IndexPtrGroupedGemmOperandsMetadata,
    ) -> tuple[str, str, str]:
        a_major = "k" if operands.A.stride[-2:].index(1) == 1 else "m"
        b_major = "k" if operands.B.stride[-2:].index(1) == 0 else "n"
        out_major = "n" if operands.out.stride[-2:].index(1) == 1 else "m"
        return a_major, b_major, out_major

    @staticmethod
    def _format_name(
        operands: IndexPtrGroupedGemmArguments | IndexPtrGroupedGemmOperandsMetadata,
    ) -> str | None:
        if not isinstance(operands.A, (ScaledOperand, ScaledOperandConstraints)):
            return None
        if not isinstance(operands.B, (ScaledOperand, ScaledOperandConstraints)):
            return None

        for (
            format_name,
            data_dtype,
            scale_dtype,
            scale_mode,
            _,
        ) in _format_specs:
            if operands.A.dtype != data_dtype or operands.B.dtype != data_dtype:
                continue
            if (
                operands.A.scale.dtype != scale_dtype
                or operands.B.scale.dtype != scale_dtype
            ):
                continue
            if not ScaleMode.compare(
                operands.A.mode, scale_mode
            ) or not ScaleMode.compare(operands.B.mode, scale_mode):
                continue
            if operands.A.swizzle != ScaleSwizzleMode.Swizzle32x4x4:
                continue
            if operands.B.swizzle != ScaleSwizzleMode.Swizzle32x4x4:
                continue
            return format_name
        return None

    @staticmethod
    def _requires_per_group_scale(
        operands: IndexPtrGroupedGemmArguments | IndexPtrGroupedGemmOperandsMetadata,
    ) -> bool:
        format_name = Sm100MoEScaledGroupedGemmOperator._format_name(operands)
        for candidate_name, _, _, _, requires_per_group_scale in _format_specs:
            if format_name == candidate_name:
                return requires_per_group_scale
        return False

    @staticmethod
    def _scale_padding(offsets_along: str, scale_mode: ScaleMode) -> int:
        """Return the offsets granularity that leaves the grouped side unpadded.

        Each group's scale block is grown to whole layout atoms, so group extents
        that are already multiples of this value need no padding at all.
        """
        if offsets_along == "m":
            return 128
        return ScaleMode.numel(scale_mode) * 4

    @staticmethod
    def _reuses_data_offsets(
        operands: IndexPtrGroupedGemmArguments | IndexPtrGroupedGemmOperandsMetadata,
    ) -> bool:
        """Whether the data offsets already locate the scale-factor blocks.

        Derived rather than declared: an offsets promise that covers the scale
        padding leaves every group unpadded, which makes the two boundary sets
        identical and lets the kernel skip deriving the second one on the device.
        """
        padding = Sm100MoEScaledGroupedGemmOperator._scale_padding(
            operands.offsets_along, operands.A.mode
        )
        return operands.offsets_value_divisibility % padding == 0

    @staticmethod
    def _tma_offsets_divisibility(
        offsets_along: str,
        a_major: str,
        b_major: str,
        out_major: str,
        a_dtype: type[cutlass.Numeric],
        b_dtype: type[cutlass.Numeric],
        out_dtype: type[cutlass.Numeric],
    ) -> int:
        """Return the offsets divisibility this layout needs for its TMA loads.

        A group boundary moves the low bits of a base address only when the
        partitioned axis is that tensor's major mode, so only then does it have to
        be TMA-element aligned. Taken from scalars rather than an operand object so
        that generation can size the divisibility before constructing metadata.
        """

        def tma_elements(dtype: type[cutlass.Numeric]) -> int:
            return 16 * 8 // dtype.width

        required_divisibility = 1
        if offsets_along == "m":
            if a_major == "m":
                required_divisibility = lcm(
                    required_divisibility, tma_elements(a_dtype)
                )
            if out_major == "m":
                required_divisibility = lcm(
                    required_divisibility, tma_elements(out_dtype)
                )
        elif offsets_along == "k":
            if a_major == "k":
                required_divisibility = lcm(
                    required_divisibility, tma_elements(a_dtype)
                )
            if b_major == "k":
                required_divisibility = lcm(
                    required_divisibility, tma_elements(b_dtype)
                )
        return required_divisibility

    @staticmethod
    def _required_offsets_divisibility(
        operands: IndexPtrGroupedGemmArguments | IndexPtrGroupedGemmOperandsMetadata,
    ) -> int:
        """Return :meth:`_tma_offsets_divisibility` for an operand set."""
        a_major, b_major, out_major = Sm100MoEScaledGroupedGemmOperator._major_modes(
            operands
        )
        return Sm100MoEScaledGroupedGemmOperator._tma_offsets_divisibility(
            operands.offsets_along,
            a_major,
            b_major,
            out_major,
            operands.A.dtype,
            operands.B.dtype,
            operands.out.dtype,
        )

    @staticmethod
    def _is_row_major_compact(tensor: DenseTensor) -> bool:
        if len(tensor.shape) != 2 or tensor.stride[-1] != 1:
            return False
        return tensor.shape[0] <= 1 or tensor.stride[0] == tensor.shape[1]

    @staticmethod
    def _exact_scale_status(
        scale: DenseTensor,
        expected_shape: tuple[int, int],
        expected_elements: int,
        operand_name: str,
    ) -> Status:
        if tuple(scale.shape) != expected_shape:
            return Status.fail(
                f"{operand_name}.scale must have shape {expected_shape}, got {scale.shape}."
            )
        if scale.numel() != expected_elements:
            return Status.fail(
                f"{operand_name}.scale must have {expected_elements} elements, got {scale.numel()}."
            )
        return Status.success()

    @staticmethod
    def _scale_extent_status(args: IndexPtrGroupedGemmArguments) -> Status:
        """Validate scale carrier extents and capacities without reading device offsets.

        Scale values must already follow the operand's swizzle. The compact rank-2
        carrier does not describe or validate that physical order; its dimensions
        communicate the padded extents used to reconstruct the kernel layout.

        The grouped extent is a sum of per-group rounded extents and cannot be
        recovered from host-visible data shapes. This validation avoids copying
        device offsets to the host and instead checks the known axis, granularity,
        lower bound, matching dimensions, and exact fixed-side extent. A carrier
        larger than the lower bound is accepted because the kernel derives each
        block's position from the offsets.
        """

        for operand_name, operand in (("A", args.A), ("B", args.B)):
            if not isinstance(operand.scale, DenseTensor):
                return Status.fail(f"{operand_name}.scale must be a DenseTensor.")
            if not Sm100MoEScaledGroupedGemmOperator._is_row_major_compact(
                operand.scale
            ):
                return Status.fail(
                    f"{operand_name}.scale must use a compact row-major rank-2 extent carrier."
                )

        scale_vector_size = ScaleMode.numel(args.A.mode)
        scale_a = args.A.scale
        scale_b = args.B.scale

        if args.offsets_along == "m":
            total_m, reduction_size = args.A.shape
            group_count, b_reduction_size, output_n = args.B.shape
            padded_k_blocks = round_up(ceil_div(reduction_size, scale_vector_size), 4)

            expected_b_shape = (group_count, round_up(output_n, 128) * padded_k_blocks)
            expected_b_elements = ScaledOperand.numel_scale(
                (group_count, output_n, b_reduction_size),
                args.B.mode,
                args.B.swizzle,
            )
            if not (
                status := Sm100MoEScaledGroupedGemmOperator._exact_scale_status(
                    scale_b, expected_b_shape, expected_b_elements, "B"
                )
            ):
                return status

            minimum_padded_rows = round_up(total_m, 128)
            if scale_a.shape[1] != padded_k_blocks:
                return Status.fail(
                    f"A.scale second dimension must be {padded_k_blocks}, got {scale_a.shape[1]}."
                )
            if scale_a.shape[0] % 128 != 0 or scale_a.shape[0] < minimum_padded_rows:
                return Status.fail(
                    "A.scale first dimension must be a multiple of 128 and at least "
                    f"{minimum_padded_rows}, got {scale_a.shape[0]}."
                )
            return Status.success()

        hidden_size, total_k = args.A.shape
        output_n = args.B.shape[1]
        expected_a_rows = round_up(hidden_size, 128)
        expected_b_rows = round_up(output_n, 128)

        if scale_a.shape[0] != expected_a_rows:
            return Status.fail(
                f"A.scale first dimension must be {expected_a_rows}, got {scale_a.shape[0]}."
            )
        if scale_b.shape[0] != expected_b_rows:
            return Status.fail(
                f"B.scale first dimension must be {expected_b_rows}, got {scale_b.shape[0]}."
            )
        if scale_a.shape[1] != scale_b.shape[1]:
            return Status.fail(
                "A.scale and B.scale must have the same grouped scale-column count, got "
                f"{scale_a.shape[1]} and {scale_b.shape[1]}."
            )

        minimum_scale_columns = round_up(ceil_div(total_k, scale_vector_size), 4)
        if scale_a.shape[1] % 4 != 0 or scale_a.shape[1] < minimum_scale_columns:
            return Status.fail(
                "Grouped scale-column count must be a multiple of 4 and at least "
                f"{minimum_scale_columns}, got {scale_a.shape[1]}."
            )
        return Status.success()

    @classmethod
    def _arguments_status(
        cls,
        args: IndexPtrGroupedGemmArguments,
    ) -> Status:
        if not isinstance(args.A, ScaledOperand) or not isinstance(
            args.B, ScaledOperand
        ):
            return Status.fail("A and B must be ScaledOperand instances.")
        if not isinstance(args.out, DenseTensor):
            return Status.fail("out must be a DenseTensor.")
        if args.offsets_along not in ("m", "k"):
            return Status.fail("offsets_along must be either 'm' or 'k'.")

        group_count = args.offsets.shape[0]
        if group_count <= 0:
            return Status.fail("At least one group is required.")

        format_name = cls._format_name(args)
        if format_name is None:
            return Status.fail("A and B do not describe a supported scaled format.")
        requires_per_group_scale = cls._requires_per_group_scale(args)
        if requires_per_group_scale:
            if not isinstance(args.epilogue, PerGroupScaleEpilogueArguments):
                return Status.fail(
                    f"{format_name} requires PerGroupScaleEpilogueArguments."
                )
            for scale_name, global_scale in (
                ("global_scale_a", args.epilogue.global_scale_a),
                ("global_scale_b", args.epilogue.global_scale_b),
            ):
                if global_scale is None:
                    return Status.fail(f"{format_name} requires {scale_name}.")
                if global_scale.shape != (group_count,):
                    return Status.fail(
                        f"{scale_name} must have shape ({group_count},), "
                        f"got {global_scale.shape}."
                    )
        elif args.epilogue is not None:
            return Status.fail(
                "Only the NVFP4 per-group scale fixed epilogue is supported."
            )

        if args.offsets_along == "m":
            total_m, reduction_size = args.A.shape
            expected_b_shape = (group_count, reduction_size, args.out.shape[1])
            expected_out_shape = (total_m, args.B.shape[2])
        else:
            hidden_size, total_k = args.A.shape
            expected_b_shape = (total_k, args.out.shape[2])
            expected_out_shape = (group_count, hidden_size, args.B.shape[1])

        if tuple(args.B.shape) != expected_b_shape:
            return Status.fail(
                f"B must have shape {expected_b_shape}, got {args.B.shape}."
            )
        if tuple(args.out.shape) != expected_out_shape:
            return Status.fail(
                f"out must have shape {expected_out_shape}, got {args.out.shape}."
            )
        if args.offsets.numel() != group_count:
            return Status.fail(f"offsets must contain {group_count} elements.")

        return cls._scale_extent_status(args)

    def _supports(
        self,
        args: IndexPtrGroupedGemmArguments,
        target_sm: TargetSm | None = None,
    ) -> Status:
        if not (status := self._arguments_status(args)):
            return status

        required_divisibility = self._required_offsets_divisibility(args)
        if args.offsets_value_divisibility % required_divisibility != 0:
            return Status.fail(
                "Every cumulative boundary in offsets must be divisible by "
                f"{required_divisibility} for this operand layout; "
                "offsets_value_divisibility currently promises only "
                f"{args.offsets_value_divisibility}."
            )

        return Status.success()

    @staticmethod
    def _compile_workspace_pointer() -> cute.Pointer:
        return cute.runtime.make_ptr(
            cutlass.Uint8,
            0,
            cutlass.AddressSpace.gmem,
            assumed_align=_workspace_alignment_bytes,
        )

    @staticmethod
    def _is_compact_allocation(shape: tuple[int, ...], stride: tuple[int, ...]) -> bool:
        active_modes = sorted(
            (stride[index], shape[index])
            for index in range(len(shape))
            if shape[index] > 1
        )
        expected_stride = 1
        for actual_stride, extent in active_modes:
            if actual_stride != expected_stride:
                return False
            expected_stride *= extent
        return True

    def _runtime_workspace_pointer(
        self,
        args: IndexPtrGroupedGemmArguments,
        workspace: Workspace | None,
    ) -> cute.Pointer:
        if workspace is None:
            raise ValueError(
                "Sm100MoEScaledGroupedGemmOperator requires user workspace."
            )

        required_bytes = self.impl.get_workspace_size(args.offsets.shape[0])
        workspace_data = workspace.data
        if isinstance(workspace_data, bool):
            raise TypeError(
                "workspace.data must be a tensor or integer device address."
            )

        if isinstance(workspace_data, int):
            workspace_address = workspace_data
        else:
            element_size = getattr(workspace_data, "element_size", None)
            if callable(element_size):
                natural_alignment = max(1, int(element_size()))
            else:
                natural_alignment = max(
                    1,
                    int(getattr(getattr(workspace_data, "dtype", None), "itemsize", 1)),
                )
            wrapper = (
                workspace_data
                if isinstance(workspace_data, TensorWrapper)
                else TensorWrapper(workspace_data, alignment_bytes=natural_alignment)
            )
            if not self._is_compact_allocation(wrapper.shape, wrapper.stride):
                raise ValueError("Tensor workspace must be a compact allocation.")
            workspace_bits = wrapper.numel() * wrapper.dtype.width
            if workspace_bits % 8 != 0:
                raise ValueError("Tensor workspace capacity must be byte-addressable.")
            workspace_bytes = workspace_bits // 8
            if workspace_bytes < required_bytes:
                raise ValueError(
                    f"Tensor workspace must provide at least {required_bytes} bytes, got {workspace_bytes}."
                )
            workspace_address = wrapper.data_ptr

        if workspace_address == 0:
            raise ValueError("workspace.data must have a non-zero device address.")
        if workspace_address % _workspace_alignment_bytes != 0:
            raise ValueError(
                f"workspace.data must be {_workspace_alignment_bytes}-byte aligned."
            )

        return cute.runtime.make_ptr(
            cutlass.Uint8,
            workspace_address,
            cutlass.AddressSpace.gmem,
            assumed_align=_workspace_alignment_bytes,
        )

    @staticmethod
    def _global_scale_tensors(
        args: IndexPtrGroupedGemmArguments,
    ) -> tuple[TensorWrapper | None, TensorWrapper | None]:
        if not isinstance(args.epilogue, PerGroupScaleEpilogueArguments):
            return None, None
        return (
            args.epilogue.global_scale_a.tensor,
            args.epilogue.global_scale_b.tensor,
        )

    @staticmethod
    def _compile_scale_tensor(scale: DenseTensor) -> cute.Tensor:
        tensor = scale.tensor
        contiguous_mode = tensor.stride.index(1)
        shape = [cute.SymInt() for _ in tensor.shape]
        shape[contiguous_mode] = cute.SymInt(divisibility=4)
        return cute.runtime.make_fake_compact_tensor(
            tensor.dtype,
            shape,
            stride_order=get_stride_rank(tensor.stride),
            assumed_align=_scale_alignment_bytes,
        )

    @staticmethod
    def _compile_global_scale_tensor(
        global_scale: TensorWrapper | None,
    ) -> cute.Tensor | None:
        if global_scale is None:
            return None
        return cute.runtime.make_fake_compact_tensor(
            global_scale.dtype,
            [cute.SymInt(divisibility=1)],
            stride_order=(0,),
            assumed_align=4,
        )

    def _compile(
        self,
        args: IndexPtrGroupedGemmArguments,
        target_sm: TargetSm | None = None,
    ) -> CompiledArtifact:
        stream = cutlass.cute.runtime.make_fake_stream()
        global_scale_a, global_scale_b = self._global_scale_tensors(args)

        return self.cute_compile(
            self.impl,
            args.A.quantized.tensor,
            args.B.quantized.tensor,
            self._compile_scale_tensor(args.A.scale),
            self._compile_scale_tensor(args.B.scale),
            args.out.tensor,
            args.offsets.tensor,
            self._compile_workspace_pointer(),
            # Placeholder: querying real occupancy would need a GPU to compile.
            cutlass.Int32(0),
            stream,
            self._compile_global_scale_tensor(global_scale_a),
            self._compile_global_scale_tensor(global_scale_b),
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
        stream = to_cuda_stream(stream)
        runtime_workspace = self._runtime_workspace_pointer(args, workspace)
        global_scale_a, global_scale_b = self._global_scale_tensors(args)
        self.cute_run(
            compiled_artifact.compiled_obj,
            args.A.quantized.tensor,
            args.B.quantized.tensor,
            args.A.scale.tensor,
            args.B.scale.tensor,
            args.out.tensor,
            args.offsets.tensor,
            runtime_workspace,
            device_properties.max_active_clusters(self.impl.cluster_shape_mn),
            stream,
            global_scale_a,
            global_scale_b,
        )

    def _get_workspace_size(
        self, args: IndexPtrGroupedGemmArguments
    ) -> AllocationRequirement:
        return AllocationRequirement(
            size_bytes=self.impl.get_workspace_size(args.offsets.shape[0]),
            ptr_alignment=_workspace_alignment_bytes,
        )

    def _initialize_workspace(
        self,
        args: IndexPtrGroupedGemmArguments,
        workspace: Workspace,
    ) -> None:
        # Descriptor initialization is intentionally performed on the launch stream.
        return None

    @staticmethod
    def _valid_operands(operands: IndexPtrGroupedGemmOperandsMetadata) -> bool:
        if not isinstance(operands, IndexPtrGroupedGemmOperandsMetadata):
            return False
        if not isinstance(operands.A, ScaledOperandConstraints):
            return False
        if not isinstance(operands.B, ScaledOperandConstraints):
            return False
        if not isinstance(operands.out, DenseTensorConstraints):
            return False
        if not isinstance(operands.offsets, DenseTensorConstraints):
            return False
        if operands.offsets_along not in ("m", "k"):
            return False
        if operands.out.dtype != cutlass.BFloat16:
            return False
        if operands.accumulator_type != cutlass.Float32:
            return False
        if operands.offsets.dtype != cutlass.Int32 or operands.offsets.stride != (1,):
            return False
        if operands.accumulate_on_output and operands.offsets_along != "k":
            return False
        if Sm100MoEScaledGroupedGemmOperator._format_name(operands) is None:
            return False
        if operands.A.scale.stride != (0, 1) or operands.B.scale.stride != (0, 1):
            return False

        try:
            a_major, b_major, _ = Sm100MoEScaledGroupedGemmOperator._major_modes(
                operands
            )
        except ValueError:
            return False
        if operands.A.dtype == cutlass.Float4E2M1FN and (
            a_major != "k" or b_major != "k"
        ):
            return False

        required_divisibility = (
            Sm100MoEScaledGroupedGemmOperator._required_offsets_divisibility(operands)
        )
        return operands.offsets_value_divisibility % required_divisibility == 0

    @staticmethod
    def _valid_design_metadata(design: DesignMetadata) -> bool:
        if not isinstance(design, Sm100DesignMetadata):
            return False
        if design.mma_instruction_type is not BlackwellTcgen05Mma:
            return False
        if not design.use_tma_store:
            return False

        tile_m, tile_n, tile_k = design.tile_shape
        expected_tile_m = 256 if design.use_2cta_mma else 128
        if tile_m != expected_tile_m or tile_n not in _tile_n_candidates or tile_k <= 0:
            return False

        cluster_m, cluster_n, cluster_k = design.cluster_shape
        if cluster_k != 1 or cluster_m > 4 or cluster_n > 4:
            return False
        if cluster_m <= 0 or cluster_n <= 0 or cluster_m * cluster_n > 16:
            return False
        if cluster_m & (cluster_m - 1) or cluster_n & (cluster_n - 1):
            return False
        if design.use_2cta_mma and cluster_m % 2 != 0:
            return False
        return True

    @staticmethod
    def _valid_epilogue_metadata(epilogue: EpilogueMetadataBase | None) -> bool:
        return epilogue is None or isinstance(epilogue, PerGroupScaleEpilogueMetadata)

    @staticmethod
    def _valid_metadata(metadata: OperatorMetadata) -> bool:
        if not Sm100MoEScaledGroupedGemmOperator._valid_operands(metadata.operands):
            return False
        if not Sm100MoEScaledGroupedGemmOperator._valid_design_metadata(
            metadata.design
        ):
            return False
        if not Sm100MoEScaledGroupedGemmOperator._valid_epilogue_metadata(
            metadata.epilogue
        ):
            return False

        operands = metadata.operands
        requires_per_group_scale = (
            Sm100MoEScaledGroupedGemmOperator._requires_per_group_scale(operands)
        )
        if requires_per_group_scale != isinstance(
            metadata.epilogue, PerGroupScaleEpilogueMetadata
        ):
            return False
        tile_k = metadata.design.tile_shape[2]
        scale_granularity = ScaleMode.numel(operands.A.mode) * 4
        return (
            tile_k % scale_granularity == 0
            and tile_k % BlackwellTcgen05Mma.shape_k(operands) == 0
        )

    @staticmethod
    def _construct_divisible_operands(
        data_dtype: type[cutlass.Numeric],
        scale_dtype: type[cutlass.Numeric],
        scale_mode: ScaleMode,
        a_stride: tuple[int, ...],
        b_stride: tuple[int, ...],
        out_stride: tuple[int, ...],
        offsets_along: str,
        offsets_value_divisibility: int,
        accumulate_on_output: bool,
    ) -> IndexPtrGroupedGemmOperandsMetadata:
        data_divisibility = 16 * 8 // data_dtype.width
        out_divisibility = 16 * 8 // cutlass.BFloat16.width
        scale_constraints = DenseTensorConstraints(
            dtype=scale_dtype,
            stride=(0, 1),
            divisibility=1,
            ptr_alignment_bytes=_scale_alignment_bytes,
        )

        return IndexPtrGroupedGemmOperandsMetadata(
            A=ScaledOperandConstraints(
                quantized=DenseTensorConstraints(
                    dtype=data_dtype,
                    stride=a_stride,
                    divisibility=data_divisibility,
                ),
                scale=scale_constraints,
                mode=scale_mode,
                swizzle=ScaleSwizzleMode.Swizzle32x4x4,
            ),
            B=ScaledOperandConstraints(
                quantized=DenseTensorConstraints(
                    dtype=data_dtype,
                    stride=b_stride,
                    divisibility=data_divisibility,
                ),
                scale=DenseTensorConstraints(
                    dtype=scale_dtype,
                    stride=(0, 1),
                    divisibility=1,
                    ptr_alignment_bytes=_scale_alignment_bytes,
                ),
                mode=scale_mode,
                swizzle=ScaleSwizzleMode.Swizzle32x4x4,
            ),
            out=DenseTensorConstraints(
                dtype=cutlass.BFloat16,
                stride=out_stride,
                divisibility=out_divisibility,
            ),
            offsets=DenseTensorConstraints(
                dtype=cutlass.Int32,
                stride=(1,),
                divisibility=1,
                ptr_alignment_bytes=4,
            ),
            offsets_along=offsets_along,
            accumulator_type=cutlass.Float32,
            offsets_value_divisibility=offsets_value_divisibility,
            accumulate_on_output=accumulate_on_output,
        )

    @staticmethod
    def _metadata_operands_from_args(
        args: IndexPtrGroupedGemmArguments,
    ) -> Generator[IndexPtrGroupedGemmOperandsMetadata, None, None]:
        if args.offsets_along not in ("m", "k"):
            return
        if not isinstance(args.A, ScaledOperand) or not isinstance(
            args.B, ScaledOperand
        ):
            return
        if not isinstance(args.A.quantized, DenseTensor) or not isinstance(
            args.B.quantized, DenseTensor
        ):
            return
        if not isinstance(args.A.scale, DenseTensor) or not isinstance(
            args.B.scale, DenseTensor
        ):
            return
        if not isinstance(args.out, DenseTensor) or not isinstance(
            args.offsets, DenseTensor
        ):
            return
        if args.offsets.dtype != cutlass.Int32:
            return

        a_stride = normalized_major_stride(args.A.shape, args.A.stride)
        b_stride = normalized_major_stride(args.B.shape, args.B.stride)
        out_stride = normalized_major_stride(args.out.shape, args.out.stride)
        if a_stride is None or b_stride is None or out_stride is None:
            return

        a_major, b_major, out_major = Sm100MoEScaledGroupedGemmOperator._major_modes(
            args
        )
        tma_divisibility = Sm100MoEScaledGroupedGemmOperator._tma_offsets_divisibility(
            args.offsets_along,
            a_major,
            b_major,
            out_major,
            args.A.dtype,
            args.B.dtype,
            args.out.dtype,
        )
        if args.offsets_value_divisibility % tma_divisibility != 0:
            return

        # An Operator that reuses the data offsets as its scale-factor offsets
        # computes the same result with strictly less work, so once the caller's
        # promise reaches the scale padding the other one is redundant and is not
        # offered. Exhaustive generation, which has no promise to go on, offers both.
        reuse_divisibility = lcm(
            tma_divisibility,
            Sm100MoEScaledGroupedGemmOperator._scale_padding(
                args.offsets_along, args.A.mode
            ),
        )
        divisibility = (
            reuse_divisibility
            if args.offsets_value_divisibility % reuse_divisibility == 0
            else tma_divisibility
        )

        operands = Sm100MoEScaledGroupedGemmOperator._construct_divisible_operands(
            data_dtype=args.A.dtype,
            scale_dtype=args.A.scale.dtype,
            scale_mode=args.A.mode,
            a_stride=a_stride,
            b_stride=b_stride,
            out_stride=out_stride,
            offsets_along=args.offsets_along,
            offsets_value_divisibility=divisibility,
            accumulate_on_output=args.accumulate_on_output,
        )
        if not Sm100MoEScaledGroupedGemmOperator._valid_operands(operands):
            return
        yield operands

    @staticmethod
    def _layout_strides(
        offsets_along: str,
        a_major: str,
        b_major: str,
        out_major: str,
    ) -> tuple[tuple[int, ...], tuple[int, ...], tuple[int, ...]]:
        a_stride = (0, 1) if a_major == "k" else (1, 0)
        if offsets_along == "m":
            b_stride = (0, 1, 0) if b_major == "k" else (0, 0, 1)
            out_stride = (0, 1) if out_major == "n" else (1, 0)
        else:
            b_stride = (1, 0) if b_major == "k" else (0, 1)
            out_stride = (0, 0, 1) if out_major == "n" else (0, 1, 0)
        return a_stride, b_stride, out_stride

    @staticmethod
    def _metadata_operand_combinations() -> Generator[
        IndexPtrGroupedGemmOperandsMetadata, None, None
    ]:
        for _, data_dtype, scale_dtype, scale_mode, _ in _format_specs:
            input_major_pairs = (
                (("k", "k"),)
                if data_dtype == cutlass.Float4E2M1FN
                else tuple(itertools.product(("k", "m"), ("k", "n")))
            )
            for offsets_along in ("m", "k"):
                accumulate_values = (False,) if offsets_along == "m" else (False, True)
                scale_padding = Sm100MoEScaledGroupedGemmOperator._scale_padding(
                    offsets_along, scale_mode
                )
                for (
                    (a_major, b_major),
                    out_major,
                    accumulate_on_output,
                ) in itertools.product(
                    input_major_pairs,
                    ("n", "m"),
                    accumulate_values,
                ):
                    a_stride, b_stride, out_stride = (
                        Sm100MoEScaledGroupedGemmOperator._layout_strides(
                            offsets_along, a_major, b_major, out_major
                        )
                    )
                    tma_divisibility = (
                        Sm100MoEScaledGroupedGemmOperator._tma_offsets_divisibility(
                            offsets_along,
                            a_major,
                            b_major,
                            out_major,
                            data_dtype,
                            data_dtype,
                            cutlass.BFloat16,
                        )
                    )
                    # One Operator per layout that only needs TMA-aligned offsets and
                    # derives the scale-factor offsets on the device, and one that
                    # needs offsets already locating them and so skips that step.
                    for divisibility in dict.fromkeys(
                        (tma_divisibility, lcm(tma_divisibility, scale_padding))
                    ):
                        yield Sm100MoEScaledGroupedGemmOperator._construct_divisible_operands(
                            data_dtype=data_dtype,
                            scale_dtype=scale_dtype,
                            scale_mode=scale_mode,
                            a_stride=a_stride,
                            b_stride=b_stride,
                            out_stride=out_stride,
                            offsets_along=offsets_along,
                            offsets_value_divisibility=divisibility,
                            accumulate_on_output=accumulate_on_output,
                        )

    @staticmethod
    def _per_group_scale_epilogue_metadata() -> PerGroupScaleEpilogueMetadata:
        scale_constraints = DenseTensorConstraints(
            dtype=cutlass.Float32,
            stride=(1,),
            divisibility=1,
            ptr_alignment_bytes=4,
        )
        return PerGroupScaleEpilogueMetadata(
            global_scale_a=scale_constraints,
            global_scale_b=scale_constraints,
        )

    @staticmethod
    def _metadata_design_combinations(
        operands: IndexPtrGroupedGemmOperandsMetadata,
    ) -> Generator[tuple[Sm100DesignMetadata, str], None, None]:
        instruction_k = BlackwellTcgen05Mma.shape_k(operands)
        scale_granularity = ScaleMode.numel(operands.A.mode) * 4
        tile_k_candidates = (
            instruction_k * multiplier
            for multiplier in _tile_k_multipliers
            if instruction_k * multiplier % scale_granularity == 0
        )

        for (
            use_2cta_mma,
            cluster_shape,
        ), tile_n, tile_k in itertools.product(
            _cta_cluster_shape_candidates,
            _tile_n_candidates,
            tile_k_candidates,
        ):
            tile_shape = (256 if use_2cta_mma else 128, tile_n, tile_k)
            design = Sm100DesignMetadata(
                mma_instruction_type=BlackwellTcgen05Mma,
                use_2cta_mma=use_2cta_mma,
                tile_shape=tile_shape,
                cluster_shape=cluster_shape,
                use_tma_store=True,
            )
            design_name = (
                f"{2 if use_2cta_mma else 1}cta_"
                f"cluster{tuple_to_string(cluster_shape)}_"
                f"tile{tuple_to_string(tile_shape)}"
            )
            yield design, design_name

    @classmethod
    def _generate_operators(
        cls,
        metadata_filter: Callable[[OperatorMetadata], bool],
        epilogue_args: EpilogueArgumentsBase | None = None,
        target_sm: TargetSm | None = None,
        args: IndexPtrGroupedGemmArguments = None,
    ) -> list[Sm100MoEScaledGroupedGemmOperator]:
        if epilogue_args is not None and not isinstance(
            epilogue_args, PerGroupScaleEpilogueArguments
        ):
            return []
        if args is not None and not cls._arguments_status(args):
            return []

        operands_generator = (
            cls._metadata_operands_from_args(args)
            if args is not None
            else cls._metadata_operand_combinations()
        )
        design_cache: dict[
            tuple[type[cutlass.Numeric], int],
            tuple[tuple[Sm100DesignMetadata, str], ...],
        ] = {}
        operator_list = []

        for operands in operands_generator:
            format_name = cls._format_name(operands)
            if format_name is None:
                continue
            requires_per_group_scale = cls._requires_per_group_scale(operands)
            requested_per_group_scale = isinstance(
                epilogue_args, PerGroupScaleEpilogueArguments
            )
            if epilogue_args is not None and not requires_per_group_scale:
                continue
            if (
                args is not None
                and requires_per_group_scale != requested_per_group_scale
            ):
                continue
            epilogue_metadata = (
                cls._per_group_scale_epilogue_metadata()
                if requires_per_group_scale
                else None
            )
            design_key = (
                operands.A.dtype,
                ScaleMode.numel(operands.A.mode),
            )
            design_combinations = design_cache.get(design_key)
            if design_combinations is None:
                design_combinations = tuple(cls._metadata_design_combinations(operands))
                design_cache[design_key] = design_combinations

            scenario = cls._scenario(operands.offsets_along)
            operands_name = (
                "cutedsl.Sm100MoEScaledGroupedGemmOperator_"
                "{scenario}_{format_name}_{layout}_outbf16_accf32_"
                "offsetdiv{offset_divisibility}_{accumulate}"
            ).format(
                scenario=scenario,
                format_name=format_name,
                layout=strides_to_layout_string(
                    operands.A.stride,
                    operands.B.stride,
                    operands.out.stride,
                ),
                offset_divisibility=operands.offsets_value_divisibility,
                accumulate=(
                    "accumulate_on_output"
                    if operands.accumulate_on_output
                    else "overwrite_output"
                ),
            )

            for design, design_name in design_combinations:
                metadata = OperatorMetadata(
                    operands=operands,
                    design=design,
                    operator_name=f"{operands_name}_{design_name}",
                    operator_class=cls,
                    supported_targets=TargetSm.get_supported_targets(design, operands),
                    epilogue=epilogue_metadata,
                )
                if metadata_filter is not None and not metadata_filter(metadata):
                    continue

                operator_list.append(cls(metadata))

        return operator_list
