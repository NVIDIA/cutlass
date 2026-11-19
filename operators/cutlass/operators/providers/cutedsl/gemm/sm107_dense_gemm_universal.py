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

"""Rubin dense GEMM exposed with the composable tile scheduler.

This operator drives the Rubin dense GEMM kernel's tile scheduler:
the designs it generates each name a persistence / reduction / rasterization
strategy, and the swizzle size and raster order travel as launch arguments so
one artifact serves every value.
"""

from __future__ import annotations

import itertools
from functools import cache, cached_property
from typing import TYPE_CHECKING, Literal

import cutlass
import cutlass.cute as cute
from cutlass import testing
from cutlass.cutlass_dsl import Boolean, Int32

import cutlass.operators.utils.generate as generate
from cutlass.kernels.rubin.gemm.base.dense_gemm_persistent import (
    SM107PersistentDenseGemmKernel,
)
from cutlass.kernels.rubin.gemm.dense_gemm_universal import (
    Sm107DenseGemmUniversal,
)
from cutlass.kernels.rubin.gemm.dense_gemm_universal import (
    bmm as _operator_bmm,
)
from cutlass.operators.arch import TargetSm
from cutlass.operators.arguments import DenseTensor, EpilogueArguments, GemmArguments
from cutlass.operators.metadata import (
    GemmOperandsMetadata,
    OperatorMetadata,
    Sm107DesignMetadata,
)
from cutlass.operators.metadata.design.tile_scheduler import (
    ClusterSplitKReductionMetadata,
)
from cutlass.operators.mma import RubinTcgen05Mma
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
    from collections.abc import Callable

    from cutlass.operators.artifact import CompiledArtifact
    from cutlass.operators.device_properties import (
        DeviceProperties,
    )
    from cutlass.operators.workspace import Workspace


@CuTeDSLProvider.register
class Sm107DenseGemmUniversalOperator(CuteDslOperator):
    """Rubin dense GEMM with a composable tile scheduler.

    :note: Supported A/B data types:
        - Float16/BFloat16 (A and B must match)
        - Float8E4M3FN/Float8E5M2

    :note: Supported accumulator data types:
        - Float32
        - Float16

    :note: Supported C data types:
        - Float32/Float16/BFloat16/Float8E4M3FN/Float8E5M2 (Float32 accumulator)
        - Float16/BFloat16 (Float16 accumulator)

    :note: Constraints:
        - Preferred cluster shape must be an integer multiple of the fallback
        - Cluster shape M must be a multiple of 2 for a 2CTA MMA instruction
        - Cluster shape M/N must be positive powers of 2, total cluster size <= 16
        - Cluster split-K stores from registers, so it excludes the TMA store,
          needs a CTA tile M of 64 or 128, and counts the splits against the
          16-CTA cluster budget
        - Other reduction strategies are generated only with the TMA store
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
        mma_tiler, mma_inst_shape = _mma_shapes(
            operands.A.dtype,
            operands.B.dtype,
            design.tile_shape,
            design.use_2cta_mma,
            design.enable_breuse,
        )
        # design.fallback_cluster_shape=None means no mixed-cluster launch; the kernel
        # expresses that as a fallback shape equal to the preferred shape.
        fallback_cluster_shape_mn = (
            design.fallback_cluster_shape[:2]
            if design.fallback_cluster_shape is not None
            else design.cluster_shape[:2]
        )

        scheduler = design.tile_scheduler
        return Sm107DenseGemmUniversal(
            acc_dtype=metadata.operands.accumulator_type,
            use_2cta_instrs=design.use_2cta_mma,
            mma_tiler=mma_tiler,
            mma_inst_shape=mma_inst_shape,
            preferred_cluster_shape_mn=design.cluster_shape[:2],
            fallback_cluster_shape_mn=fallback_cluster_shape_mn,
            use_tma_store=design.use_tma_store,
            split_k=scheduling.resolve_split_count(scheduler.reduction),
            work_strategy=scheduler.persistence.arg_name(),
            rasterization_strategy=scheduler.rasterization.arg_name(),
            reduction_strategy=scheduler.reduction.arg_name(),
        )

    def _supports(
        self, args: GemmArguments, target_sm: TargetSm | None = None
    ) -> Status:
        """Reject launches whose shape the non-TMA store cannot bound-check."""
        design = self.metadata.design
        if not design.use_tma_store:
            cta_tile_m, cta_tile_n = design.tile_shape[:2]
            cluster_m, cluster_n = design.cluster_shape[:2]
            ps = args.problem_size
            if ps.M % cta_tile_m != 0 or ps.N % cta_tile_n != 0:
                return Status.fail(
                    f"non-TMA store requires the problem shape (M={ps.M}, "
                    f"N={ps.N}) to be divisible by the CTA tile "
                    f"({cta_tile_m}, {cta_tile_n}); this store path has no "
                    "out-of-bounds predication"
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
        stream = cute.runtime.make_fake_stream()
        return self.cute_compile(
            _operator_bmm,
            self.impl,
            args.A.tensor,
            args.B.tensor,
            args.out.tensor,
            stream,
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
        """Run a compiled Rubin universal GEMM."""
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
            predicated_store=True,
        )
        workspace_ptr = workspace_utils.get_gmem_workspace_pointer(
            workspace, self._get_workspace_size(args).size_bytes
        )

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
            args.A.tensor,
            args.B.tensor,
            args.out.tensor,
            to_cuda_stream(stream),
            workspace_ptr,
            Int32(swizzle_size),
            Boolean(raster_along == "m"),
            Int32(max_active_clusters),
        )

    @classmethod
    def _generate_operators(
        cls,
        metadata_filter: Callable[[OperatorMetadata], bool],
        epilogue_args: EpilogueArguments | None = None,
        target_sm: TargetSm | None = None,
        args: GemmArguments | None = None,
    ) -> list[CuteDslOperator]:
        """Returns a list of all possible configurations of Sm107DenseGemmUniversalOperator
        that adhere to constraints passed in under kwargs.
        """
        if epilogue_args is not None:
            return []

        operator_list = []
        for operand_keys in _valid_operand_combos(args):
            operands = _make_operands_metadata(**operand_keys)
            operands_name = _operands_name_part(operands)
            for design in _valid_designs(
                operand_keys["a_dtype"],
                operand_keys["b_dtype"],
                operand_keys["acc_dtype"],
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
                    operator_list.append(cls(metadata))

        return operator_list


################################################################################
# Helpers to enumerate the configuration space
################################################################################


def _valid_operand_combos(args: GemmArguments | None) -> list[dict]:
    """Enumerate operand configurations accepted by the kernel."""
    operand_keys = {
        "a_dtype": (
            cutlass.Float16,
            cutlass.BFloat16,
            cutlass.Float8E4M3FN,
            cutlass.Float8E5M2,
        ),
        "b_dtype": (
            cutlass.Float16,
            cutlass.BFloat16,
            cutlass.Float8E4M3FN,
            cutlass.Float8E5M2,
        ),
        "out_dtype": (
            cutlass.Float32,
            cutlass.Float16,
            cutlass.BFloat16,
            cutlass.Float8E4M3FN,
            cutlass.Float8E5M2,
        ),
        "acc_dtype": (cutlass.Float32, cutlass.Float16),
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
        dict(zip(operand_keys, values))
        for values in itertools.product(*operand_keys.values())
    ]
    return [combo for combo in combos if _kernel_accepts_operands(**combo)]


def _operand_keys_from_args(args: GemmArguments) -> dict[str, tuple] | None:
    """Return the single operand configuration requested by ``args``."""
    if not isinstance(args, GemmArguments):
        return None
    if any(not isinstance(arg, DenseTensor) for arg in (args.A, args.B, args.out)):
        return None

    def major(operand, row_major: str, col_major: str) -> str | None:
        """Return the name of the contiguous mode, if one exists."""
        stride = normalized_major_stride(
            operand.shape, operand.stride, prepend_zeros_to_rank=3
        )
        return {(0, 0, 1): row_major, (0, 1, 0): col_major}.get(stride)

    return {
        "a_dtype": (args.A.dtype,),
        "b_dtype": (args.B.dtype,),
        "out_dtype": (args.out.dtype,),
        "acc_dtype": (args.accumulator_type,),
        "a_major": (major(args.A, "k", "m"),),
        "b_major": (major(args.B, "n", "k"),),
        "c_major": (major(args.out, "n", "m"),),
    }


def _kernel_accepts_operands(
    a_dtype,
    b_dtype,
    out_dtype,
    acc_dtype,
    a_major: Literal["m", "k"],
    b_major: Literal["n", "k"],
    c_major: Literal["m", "n"],
) -> bool:
    """Return whether the kernel supports this operand configuration."""
    try:
        SM107PersistentDenseGemmKernel.check_supported_dtypes(
            a_dtype, b_dtype, out_dtype, acc_dtype
        )
    except testing.CantImplementError:
        return False
    return a_major in ("m", "k") and b_major in ("n", "k") and c_major in ("m", "n")


@cache
def _valid_designs(
    a_dtype,
    b_dtype,
    acc_dtype,
) -> tuple[Sm107DesignMetadata, ...]:
    """Return every design the kernel can compile for one operand configuration."""
    design_keys = {
        "use_2cta_mma": (False, True),
        "enable_breuse": (False, True),
        "use_tma_store": (True, False),
        "tile_m": (64, 128, 256),
        "tile_n": (32, 64, 128, 192, 256),
        "preferred_cluster_shape": tuple(
            (cluster_m, cluster_n, 1)
            for cluster_m in (1, 2, 4, 8, 16)
            for cluster_n in (1, 2, 4, 8, 16)
            if cluster_m * cluster_n <= 16
        ),
        "fallback_cluster_shape": ((1, 1, 1), (1, 2, 1), (2, 1, 1)),
        "tile_scheduler": scheduling.enumerate_tile_schedulers(),
    }

    tile_k = 128 * 8 // a_dtype.width
    designs = []
    for design_values in itertools.product(*design_keys.values()):
        design_combo = dict(zip(design_keys, design_values))
        preferred = design_combo["preferred_cluster_shape"]
        fallback = design_combo["fallback_cluster_shape"]
        if not Sm107DesignMetadata.is_valid_fallback_cluster(preferred, fallback):
            continue

        use_2cta_mma = design_combo["use_2cta_mma"]
        enable_breuse = design_combo["enable_breuse"]
        use_tma_store = design_combo["use_tma_store"]
        tile_scheduler = design_combo["tile_scheduler"]
        is_cluster_splitk = isinstance(
            tile_scheduler.reduction, ClusterSplitKReductionMetadata
        )
        if not use_tma_store and not is_cluster_splitk:
            continue
        cta_tile_shape = (
            design_combo["tile_m"],
            design_combo["tile_n"],
            tile_k,
        )
        mma_tiler, mma_inst_shape = _mma_shapes(
            a_dtype,
            b_dtype,
            cta_tile_shape,
            use_2cta_mma,
            enable_breuse,
        )
        try:
            for cluster_shape in (preferred, fallback):
                SM107PersistentDenseGemmKernel.is_valid_mma_tiler_and_cluster_shape(
                    a_dtype,
                    b_dtype,
                    mma_tiler,
                    mma_inst_shape,
                    use_2cta_mma,
                    cluster_shape[:2],
                    use_tma_store,
                    is_cluster_splitk,
                    acc_dtype,
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

        designs.append(
            Sm107DesignMetadata(
                mma_instruction_type=RubinTcgen05Mma,
                use_tma_store=use_tma_store,
                use_2cta_mma=use_2cta_mma,
                enable_breuse=enable_breuse,
                tile_shape=cta_tile_shape,
                cluster_shape=preferred,
                fallback_cluster_shape=fallback,
                tile_scheduler=tile_scheduler,
            )
        )
    return tuple(designs)


def _mma_shapes(
    a_dtype,
    b_dtype,
    cta_tile_shape: tuple[int, int, int],
    use_2cta_mma: bool,
    enable_breuse: bool,
) -> tuple[tuple[int, int, int], tuple[int, int, int]]:
    """Return the MMA tiler and instruction shape for a CTA tile."""
    mma_ctas = 2 if use_2cta_mma else 1
    instructions_m = 2 if enable_breuse else 1
    mma_tiler = (
        cta_tile_shape[0] * mma_ctas,
        cta_tile_shape[1],
        cta_tile_shape[2],
    )
    mma_inst_shape = (
        mma_tiler[0] // instructions_m,
        cta_tile_shape[1],
        RubinTcgen05Mma.shape_k_for_dtypes(a_dtype, b_dtype),
    )
    return mma_tiler, mma_inst_shape


def _make_operands_metadata(
    a_dtype,
    b_dtype,
    out_dtype,
    acc_dtype,
    a_major: Literal["m", "k"],
    b_major: Literal["n", "k"],
    c_major: Literal["m", "n"],
) -> GemmOperandsMetadata:
    """Build operand metadata from the kernel-facing configuration keys."""
    return generate.construct_dense_gemm_operands(
        a_dtype,
        b_dtype,
        out_dtype,
        acc_dtype,
        (0, 0, 1) if a_major == "k" else (0, 1, 0),
        (0, 0, 1) if b_major == "n" else (0, 1, 0),
        (0, 0, 1) if c_major == "n" else (0, 1, 0),
        alignment_bytes=16,
    )


def _operands_name_part(operands: GemmOperandsMetadata) -> str:
    """Build the operands half of an Operator name."""
    layout = strides_to_layout_string(
        operands.A.stride, operands.B.stride, operands.out.stride
    )
    return (
        "cutedsl.Sm107DenseGemmUniversalOperator"
        f"_{layout}"
        f"_A{operands.A.dtype}_B{operands.B.dtype}_out{operands.out.dtype}"
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
