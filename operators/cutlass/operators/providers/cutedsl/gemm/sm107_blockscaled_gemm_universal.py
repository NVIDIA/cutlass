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

"""Rubin block scaled dense GEMM exposed with the composable tile scheduler."""

from __future__ import annotations

import itertools
from functools import cache, cached_property
from typing import TYPE_CHECKING, Literal

import cutlass
import cutlass.cute as cute
from cutlass import testing
from cutlass.cutlass_dsl import Boolean, Int32

from cutlass.kernels.rubin.gemm.base.dense_blockscaled_gemm_persistent import (
    Sm107BlockScaledPersistentDenseGemmKernel,
)
from cutlass.kernels.rubin.gemm.dense_blockscaled_gemm_universal import (
    Sm107BlockScaledGemmUniversal,
)
from cutlass.kernels.rubin.gemm.dense_blockscaled_gemm_universal import (
    bmm as _operator_bmm,
)
from cutlass.operators.arch import TargetSm
from cutlass.operators.arguments import (
    GemmArguments,
    ScaledOperand,
    ScaleMode,
    ScaleSwizzleMode,
)
from cutlass.operators.metadata import (
    DenseTensorConstraints,
    GemmOperandsMetadata,
    OperatorMetadata,
    ScaledOperandConstraints,
)
from cutlass.operators.metadata.design.sm107 import Sm107DesignMetadata
from cutlass.operators.mma import RubinTcgen05Mma
from cutlass.operators.status import Status
from cutlass.operators.utils.common import tuple_to_string
from cutlass.operators.utils.device import to_cuda_stream
from cutlass.operators.utils.tensor import (
    normalized_major_stride,
    strides_to_layout_string,
)
from cutlass.operators.workspace import AllocationRequirement

from ...cutedsl import CuTeDSLProvider
from ...cutedsl.integration_utils import scheduling
from ...cutedsl.integration_utils import workspace as workspace_utils
from ...cutedsl.integration_utils.builders import make_ptr
from ...cutedsl.operator import CuteDslOperator

if TYPE_CHECKING:
    from collections.abc import Callable

    from cutlass.operators.arguments import EpilogueArguments
    from cutlass.operators.artifact import CompiledArtifact
    from cutlass.operators.device_properties import (
        DeviceProperties,
    )
    from cutlass.operators.workspace import Workspace


@CuTeDSLProvider.register
class Sm107BlockScaledGemmUniversalOperator(CuteDslOperator):
    """Rubin block scaled dense GEMM with a composable tile scheduler.

    :note: Supported combinations of A/B data types, SF data types and SF vector size:
        - MXF8: A/B: Float8E5M2/Float8E4M3FN + SF: Float8E8M0FNU + sf_vec_size: 32
        - NVF4: A/B: Float4E2M1FN + SF: Float8E8M0FNU/Float8E4M3FN/FloatNV8E5M3FNU
          + sf_vec_size: 16/32

    :note: Constraints:
        - Cluster shape M/N must be <= 4, because the scale factor multicast
          has a limited scale factor size
        - Cluster split-K stores from registers, so it excludes the TMA store,
          needs a CTA tile M of 64 or 128, and counts the splits against the
          16-CTA cluster budget
        - Non-TMA store requires M and N to be divisible by the CTA tile
    """

    supported_args_type = GemmArguments
    designed_for_min_cc = 107

    @cached_property
    def impl(self):
        """Build this operator's kernel only when compilation or launch needs it."""
        metadata = self.metadata

        operands: GemmOperandsMetadata = metadata.operands
        design: Sm107DesignMetadata = metadata.design
        _, mma_tiler, mma_inst_shape = _mma_shapes(
            operands.A.dtype,
            operands.B.dtype,
            design.tile_shape[1],
            design.use_2cta_mma,
            design.enable_breuse,
        )
        preferred_cluster_shape_mn = design.cluster_shape[:2]
        fallback_cluster_shape_mn = (
            design.fallback_cluster_shape[:2]
            if design.fallback_cluster_shape is not None
            else design.cluster_shape[:2]
        )
        scheduler = design.tile_scheduler

        return Sm107BlockScaledGemmUniversal(
            sf_vec_size=ScaleMode.numel(operands.A.mode),
            mma_inst_shape=mma_inst_shape,
            mma_tiler=mma_tiler,
            preferred_cluster_shape_mn=preferred_cluster_shape_mn,
            fallback_cluster_shape_mn=fallback_cluster_shape_mn,
            prefetch_dist=0,
            use_tma_store=design.use_tma_store,
            split_k=scheduling.resolve_split_count(scheduler.reduction),
            work_strategy=scheduler.persistence.arg_name(),
            rasterization_strategy=scheduler.rasterization.arg_name(),
            reduction_strategy=scheduler.reduction.arg_name(),
        )

    def _supports(
        self, args: GemmArguments, target_sm: TargetSm | None = None
    ) -> Status:
        """Reject problem shapes the non-TMA store cannot safely handle."""
        design = self.metadata.design
        if not design.use_tma_store:
            cta_tile_m, cta_tile_n = design.tile_shape[:2]
            cluster_m, cluster_n = design.cluster_shape[:2]
            ps = args.problem_size
            if ps.M % cta_tile_m != 0 or ps.N % cta_tile_n != 0:
                return Status.fail(
                    f"non-TMA store requires the problem shape (M={ps.M}, "
                    f"N={ps.N}) to be divisible by the CTA tile "
                    f"({cta_tile_m}, {cta_tile_n})"
                )
            if ps.M // cta_tile_m < cluster_m or ps.N // cta_tile_n < cluster_n:
                return Status.fail(
                    f"non-TMA store requires the problem shape (M={ps.M}, "
                    f"N={ps.N}) to cover at least one cluster of CTA tiles "
                    f"({cluster_m * cta_tile_m}, {cluster_n * cta_tile_n})"
                )
        return Status.success()

    def _compile(
        self, args: GemmArguments, target_sm: TargetSm | None = None
    ) -> CompiledArtifact:
        sfa_ptr, sfb_ptr = self._construct_scale_pointers(args, nullptr=True)
        return self.cute_compile(
            _operator_bmm,
            self.impl,
            args.A.quantized.tensor,
            args.B.quantized.tensor,
            sfa_ptr,
            sfb_ptr,
            args.out.tensor,
            cute.runtime.make_fake_stream(),
            workspace_utils.null_gmem_pointer(),
            Int32(1),
            Boolean(True),
            Int32(0),  # placeholder for max_active_clusters_fallback
            lambda x: x,
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
        workspace_bytes = workspace_utils.view_workspace_as_bytes(workspace)
        ps = args.problem_size
        self.impl.initialize_workspace(workspace_bytes, (ps.M, ps.N, ps.L))

    def _run(
        self,
        args: GemmArguments,
        compiled_artifact: CompiledArtifact,
        stream,
        workspace=None,
        *,
        device_properties: DeviceProperties,
    ) -> None:
        ps = args.problem_size
        operands = self.metadata.operands
        design = self.metadata.design
        swizzle_size, raster_along = scheduling.resolve_launch_rasterization(
            args,
            design.tile_scheduler.rasterization,
            self.impl.tile_scheduler_template,
            (ps.M, ps.N, ps.K, ps.L),
            # The raster heuristic only compares the two operands, and whole
            # bytes would round sub-byte element sizes down to zero.
            a_element_bytes=operands.A.dtype.width,
            b_element_bytes=operands.B.dtype.width,
            predicated_store=True,
        )
        workspace_ptr = workspace_utils.get_gmem_workspace_pointer(
            workspace, self._get_workspace_size(args).size_bytes
        )
        sfa_ptr, sfb_ptr = self._construct_scale_pointers(args)

        # The fallback cluster is the smallest the launch can degrade to, so
        # its occupancy bounds the grid. Cluster split-K places its splits in
        # cluster Z, which must also count against residency.
        if self.impl.work_strategy == "static":
            max_active_clusters = scheduling.resolve_max_active_clusters(
                device_properties,
                self.impl.fallback_cluster_shape_mn,
                self.impl.split_k,
                self.impl.reduction_strategy,
                self.impl.work_strategy,
            )
        else:
            max_active_clusters = 0  # unused for non-static strategies
        self.cute_run(
            compiled_artifact.compiled_obj,
            args.A.quantized.tensor,
            args.B.quantized.tensor,
            sfa_ptr,
            sfb_ptr,
            args.out.tensor,
            to_cuda_stream(stream),
            workspace_ptr,
            Int32(swizzle_size),
            Boolean(raster_along == "m"),
            Int32(max_active_clusters),
        )

    @staticmethod
    def _construct_scale_pointers(
        args: GemmArguments, nullptr: bool = False
    ) -> tuple[cute.Pointer, cute.Pointer]:
        """Return GMEM pointers to the A and B scale factors.

        Scale factors cross the TVM-FFI boundary as pointers rather than
        tensors because TVM-FFI has no tensor dtype for ``FloatNV8E5M3FNU``.
        """
        gmem = cutlass.AddressSpace.gmem
        sfa_ptr = make_ptr(
            args.A.scale, nullptr=nullptr, address_space=gmem, assumed_align=32
        )
        sfb_ptr = make_ptr(
            args.B.scale, nullptr=nullptr, address_space=gmem, assumed_align=32
        )
        return sfa_ptr, sfb_ptr

    @classmethod
    def _generate_operators(
        cls,
        metadata_filter: Callable[[OperatorMetadata], bool],
        epilogue_args: EpilogueArguments | None = None,
        target_sm: TargetSm | None = None,
        args: GemmArguments | None = None,
    ) -> list[Sm107BlockScaledGemmUniversalOperator]:
        if epilogue_args is not None:
            return []

        operators = []
        for operand_keys in _valid_operand_combos(args):
            operands = _make_operands_metadata(**operand_keys)
            operands_name = _operands_name_part(operands)
            for design in _valid_designs(
                operand_keys["a_dtype"], operand_keys["b_dtype"]
            ):
                metadata = OperatorMetadata(
                    operands=operands,
                    design=design,
                    operator_name=operands_name + _design_name_part(design),
                    operator_class=cls,
                    supported_targets=TargetSm.get_supported_targets(design, operands),
                    epilogue=None,
                )

                if metadata_filter(metadata):
                    operators.append(cls(metadata))

        return operators


################################################################################
# Helpers to enumerate the configuration space
################################################################################


def _valid_operand_combos(args: GemmArguments | None) -> list[dict]:
    """Enumerate the operand configurations the kernel accepts.

    ``args``, when given, narrows the enumeration to the one configuration it
    describes; an empty result means this operator cannot serve it.
    """
    operand_keys = {
        "a_dtype": (cutlass.Float4E2M1FN, cutlass.Float8E4M3FN, cutlass.Float8E5M2),
        "b_dtype": (cutlass.Float4E2M1FN, cutlass.Float8E4M3FN, cutlass.Float8E5M2),
        "sf_dtype": (
            cutlass.Float8E8M0FNU,
            cutlass.Float8E4M3FN,
            cutlass.FloatNV8E5M3FNU,
        ),
        "out_dtype": (cutlass.Float32, cutlass.Float16, cutlass.BFloat16),
        "acc_dtype": (cutlass.Float32,),
        "sf_vec_size": (16, 32),
        "a_major": ("m", "k"),
        "b_major": ("n", "k"),
        "c_major": ("m", "n"),
    }

    if args is not None:
        requested_keys = _operand_keys_from_args(args)
        if requested_keys is None:
            return []
        if any(
            value not in operand_keys[key] for key, (value,) in requested_keys.items()
        ):
            return []
        operand_keys |= requested_keys

    combos = [
        dict(zip(operand_keys, operand_values))
        for operand_values in itertools.product(*operand_keys.values())
    ]
    return [combo for combo in combos if _kernel_accepts_operands(**combo)]


def _operand_keys_from_args(args: GemmArguments) -> dict[str, tuple] | None:
    """Return the single operand configuration requested by ``args``."""
    if not isinstance(args, GemmArguments):
        return None
    if not (isinstance(args.A, ScaledOperand) and isinstance(args.B, ScaledOperand)):
        return None
    if (
        args.A.swizzle != ScaleSwizzleMode.Swizzle32x4x4
        or args.B.swizzle != ScaleSwizzleMode.Swizzle32x4x4
        or args.A.scale.dtype != args.B.scale.dtype
        or ScaleMode.numel(args.A.mode) != ScaleMode.numel(args.B.mode)
    ):
        return None

    def major(operand, row_major: str, col_major: str) -> str | None:
        """Return the name of the contiguous mode, if one exists."""
        stride = normalized_major_stride(
            operand.shape, operand.stride, prepend_zeros_to_rank=3
        )
        return {(0, 0, 1): row_major, (0, 1, 0): col_major}.get(stride)

    return {
        "a_dtype": (args.A.quantized.dtype,),
        "b_dtype": (args.B.quantized.dtype,),
        "sf_dtype": (args.A.scale.dtype,),
        "out_dtype": (args.out.dtype,),
        "acc_dtype": (args.accumulator_type,),
        "sf_vec_size": (ScaleMode.numel(args.A.mode),),
        "a_major": (major(args.A.quantized, "k", "m"),),
        "b_major": (major(args.B.quantized, "n", "k"),),
        "c_major": (major(args.out, "n", "m"),),
    }


def _kernel_accepts_operands(
    a_dtype: cutlass.Numeric,
    b_dtype: cutlass.Numeric,
    sf_dtype: cutlass.Numeric,
    out_dtype: cutlass.Numeric,
    acc_dtype: cutlass.Numeric,
    sf_vec_size: int,
    a_major: Literal["m", "k"],
    b_major: Literal["n", "k"],
    c_major: Literal["m", "n"],
) -> bool:
    """Return whether the kernel supports this operand configuration."""
    if acc_dtype is not cutlass.Float32:
        return False
    try:
        Sm107BlockScaledPersistentDenseGemmKernel.is_valid_dtypes_and_scale_factor_vec_size(
            a_dtype, b_dtype, sf_dtype, sf_vec_size, out_dtype
        )
        Sm107BlockScaledPersistentDenseGemmKernel.is_valid_layouts(
            a_dtype, b_dtype, out_dtype, a_major, b_major, c_major
        )
    except testing.CantImplementError:
        return False
    return True


@cache
def _valid_designs(
    a_dtype: cutlass.Numeric,
    b_dtype: cutlass.Numeric,
) -> tuple[Sm107DesignMetadata, ...]:
    """Return every design the kernel can compile for one operand configuration."""

    design_keys = {
        "use_2cta_mma": (False, True),
        "enable_breuse": (False, True),
        "use_tma_store": (True, False),
        "tile_n": (64, 128, 256),
        "preferred_cluster_shape": tuple(
            (cluster_m, cluster_n, 1)
            for cluster_m in (1, 2, 4)  # max deliberate capped to 4 by kernel
            for cluster_n in (1, 2, 4)
        ),
        "fallback_cluster_shape": ((1, 1, 1), (1, 2, 1), (2, 1, 1)),
        "tile_scheduler": scheduling.enumerate_tile_schedulers(),
    }

    designs = []
    for design_values in itertools.product(*design_keys.values()):
        design_combo = dict(zip(design_keys, design_values))
        preferred = design_combo["preferred_cluster_shape"]
        fallback = design_combo["fallback_cluster_shape"]
        tile_scheduler = design_combo["tile_scheduler"]
        if not Sm107DesignMetadata.is_valid_fallback_cluster(preferred, fallback):
            continue

        use_tma_store = design_combo["use_tma_store"]
        cta_tile_shape, mma_tiler, mma_inst_shape = _mma_shapes(
            a_dtype,
            b_dtype,
            design_combo["tile_n"],
            design_combo["use_2cta_mma"],
            design_combo["enable_breuse"],
        )
        try:
            for cluster_shape in (preferred, fallback):
                Sm107BlockScaledPersistentDenseGemmKernel.is_valid_mma_tiler_and_cluster_shape(
                    a_dtype, b_dtype, mma_inst_shape, mma_tiler, cluster_shape[:2]
                )
        except testing.CantImplementError:
            continue

        if not scheduling.reduction_fits(
            tile_scheduler.reduction,
            cta_tile_mn=cta_tile_shape[:2],
            cluster_shape_mn=preferred[:2],
            use_tma_store=use_tma_store,
        ):
            continue

        design = Sm107DesignMetadata(
            mma_instruction_type=RubinTcgen05Mma,
            use_tma_store=use_tma_store,
            use_2cta_mma=design_combo["use_2cta_mma"],
            enable_breuse=design_combo["enable_breuse"],
            tile_shape=cta_tile_shape,
            cluster_shape=preferred,
            fallback_cluster_shape=fallback,
            tile_scheduler=tile_scheduler,
        )

        designs.append(design)
    return tuple(designs)


def _mma_shapes(
    a_dtype: cutlass.Numeric,
    b_dtype: cutlass.Numeric,
    tile_n: int,
    use_2cta_mma: bool,
    enable_breuse: bool,
) -> tuple[tuple[int, int, int], tuple[int, int, int], tuple[int, int, int]]:
    """Return ``(cta_tile_shape, mma_tiler, mma_inst_shape)``."""
    mma_ctas = 2 if use_2cta_mma else 1
    instructions_m = 2 if enable_breuse else 1
    is_nvf4 = a_dtype is cutlass.Float4E2M1FN and b_dtype is cutlass.Float4E2M1FN
    inst_k = 128 if is_nvf4 else 64

    mma_inst_shape = (128 * mma_ctas, tile_n, inst_k)
    mma_tiler = (mma_inst_shape[0] * instructions_m, tile_n, inst_k * 2)
    cta_tile_shape = (mma_tiler[0] // mma_ctas, tile_n, mma_tiler[2])
    return cta_tile_shape, mma_tiler, mma_inst_shape


def _make_operands_metadata(
    a_dtype: cutlass.Numeric,
    b_dtype: cutlass.Numeric,
    sf_dtype: cutlass.Numeric,
    out_dtype: cutlass.Numeric,
    acc_dtype: cutlass.Numeric,
    sf_vec_size: int,
    a_major: Literal["m", "k"],
    b_major: Literal["n", "k"],
    c_major: Literal["m", "n"],
) -> GemmOperandsMetadata:
    """Build operand metadata from the kernel-facing configuration keys."""
    stride_a = (0, 0, 1) if a_major == "k" else (0, 1, 0)
    stride_b = (0, 0, 1) if b_major == "n" else (0, 1, 0)
    stride_out = (0, 0, 1) if c_major == "n" else (0, 1, 0)

    alignment_bytes = 16

    def elements_per_line(dtype: cutlass.Numeric) -> int:
        return alignment_bytes * 8 // dtype.width

    def scale_constraints() -> DenseTensorConstraints:
        return DenseTensorConstraints(
            dtype=sf_dtype, stride=None, divisibility=1, ptr_alignment_bytes=32
        )

    scale_mode = (
        ScaleMode.Blockwise1x16 if sf_vec_size == 16 else ScaleMode.Blockwise1x32
    )
    return GemmOperandsMetadata(
        A=ScaledOperandConstraints(
            quantized=DenseTensorConstraints(
                dtype=a_dtype,
                stride=stride_a,
                divisibility=elements_per_line(a_dtype),
            ),
            scale=scale_constraints(),
            mode=scale_mode,
            swizzle=ScaleSwizzleMode.Swizzle32x4x4,
        ),
        B=ScaledOperandConstraints(
            quantized=DenseTensorConstraints(
                dtype=b_dtype,
                stride=stride_b,
                divisibility=elements_per_line(b_dtype),
            ),
            scale=scale_constraints(),
            mode=scale_mode,
            swizzle=ScaleSwizzleMode.Swizzle32x4x4,
        ),
        out=DenseTensorConstraints(
            dtype=out_dtype,
            stride=stride_out,
            divisibility=elements_per_line(out_dtype),
        ),
        accumulator_type=acc_dtype,
    )


def _operands_name_part(operands: GemmOperandsMetadata) -> str:
    """Build the operands half of an Operator name."""
    layout = strides_to_layout_string(
        operands.A.stride, operands.B.stride, operands.out.stride
    )
    # The scale factor swizzle is not part of the name: Swizzle32x4x4 is the
    # only mode this operator generates.
    return (
        "cutedsl.Sm107BlockScaledGemmUniversalOperator"
        f"_{layout}"
        f"_A{operands.A.dtype}_B{operands.B.dtype}_out{operands.out.dtype}"
        f"_SF{operands.A.scale.dtype}x{ScaleMode.numel(operands.A.mode)}"
        f"_acc{operands.accumulator_type}"
    )


def _design_name_part(design: Sm107DesignMetadata) -> str:
    """Build the design half of an Operator name."""
    return (
        f"_{'2' if design.use_2cta_mma else '1'}cta"
        f"_cluster{tuple_to_string(design.cluster_shape)}"
        f"{f'_fallback{tuple_to_string(design.fallback_cluster_shape)}' if design.fallback_cluster_shape is not None else ''}"
        f"_tile{tuple_to_string(design.tile_shape)}"
        f"{'_breuse' if design.enable_breuse else ''}"
        f"_scheduler{design.tile_scheduler}"
        f"{'_tma_store' if design.use_tma_store else ''}"
    )
