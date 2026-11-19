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

import functools
import itertools
from typing import TYPE_CHECKING, Literal

import cutlass
from cutlass import testing

from cutlass.kernels.rubin.gemm.base.blackwell_dense_gemm_persistent import (
    PersistentDenseGemmKernel as BlackwellDenseGemmPersistentKernel,
)
from cutlass.kernels.rubin.gemm.dense_gemm_persistent_tma_report_valid import (
    SM107ReportValidGemmKernel,
    bmm,
)
from cutlass.operators.arch import TargetSm
from cutlass.operators.arguments import (
    DenseTensor,
    GemmArguments,
)
from cutlass.operators.arguments.tile_scheduler_settings import RasterOrder
from cutlass.operators.metadata import (
    DataDrivenSyncConsumerMetadata,
    DataDrivenSyncMetadata,
    DataDrivenSyncProducerMetadata,
    DenseTensorConstraints,
    EarlyStartMetadata,
    GemmOperandsMetadata,
    OperatorMetadata,
    ProgrammaticDependentLaunchMetadata,
)
from cutlass.operators.metadata.design.sm107 import Sm107DesignMetadata
from cutlass.operators.metadata.design.tile_scheduler import (
    TileSchedulerMetadata,
    TileSwizzleRasterizationMetadata,
)
from cutlass.operators.mma import RubinTcgen05Mma
from cutlass.operators.typing import AnyValue
from cutlass.operators.utils.common import tuple_to_string
from cutlass.operators.utils.device import to_cuda_stream
from cutlass.operators.utils.tensor import (
    normalized_major_stride,
    strides_to_layout_string,
)

from ...cutedsl import CuTeDSLProvider
from ...cutedsl.operator import CuteDslOperator

if TYPE_CHECKING:
    from collections.abc import Callable

    from cutlass.operators.arguments import EpilogueArguments
    from cutlass.operators.artifact import CompiledArtifact
    from cutlass.operators.device_properties import DeviceProperties


@CuTeDSLProvider.register
class Sm107DenseGemmDataDrivenSyncOperator(CuteDslOperator):
    """Data-driven sync dense GEMM operator for SM107."""

    supported_args_type = GemmArguments
    designed_for_min_cc = 107

    def __init__(self, metadata: OperatorMetadata):
        super().__init__(metadata)

        operands: GemmOperandsMetadata = metadata.operands
        design: Sm107DesignMetadata = metadata.design
        _, mma_tiler, _ = _mma_shapes(
            operands.A.dtype,
            operands.B.dtype,
            design.tile_shape[1],
            design.use_2cta_mma,
            design.enable_breuse,
        )

        pdl = design.pdl
        pdl_early_launch_dependent = pdl.early_launch_dependent
        pdl_early_start = pdl.early_start is not None

        data_driven_sync_metadata = design.data_driven_sync
        is_data_driven_producer = data_driven_sync_metadata.producer is not None
        is_data_driven_consumer = data_driven_sync_metadata.consumer is not None

        producer_sentinel_init = (
            is_data_driven_producer
            and data_driven_sync_metadata.producer.output_sentinel_prefill
        )

        self.pdl_early_launch_next = pdl_early_launch_dependent
        self.pdl_early_start = pdl_early_start
        self.check_b_valid = is_data_driven_consumer
        self.eager_launch_next = pdl_early_launch_dependent or is_data_driven_producer

        tile_scheduler = design.tile_scheduler
        if tile_scheduler is not None:
            # Sanity checks to avoid creating invalid tile scheduler designs
            assert isinstance(tile_scheduler, TileSchedulerMetadata), (
                f"{tile_scheduler}"
            )
            assert isinstance(
                tile_scheduler.rasterization,
                TileSwizzleRasterizationMetadata,
            ), f"{tile_scheduler}"
            assert (
                tile_scheduler.rasterization.swizzle_size is not None
                and len(tile_scheduler.rasterization.swizzle_size) == 1
            ), f"{tile_scheduler}"
            assert tile_scheduler.rasterization.swizzle_order is not AnyValue, (
                f"{tile_scheduler}"
            )
            assert len(tile_scheduler.rasterization.raster_order) == 1, (
                f"{tile_scheduler}"
            )

        swizzle_size = 1
        raster_along = "m"
        if tile_scheduler is not None:
            swizzle_size = tile_scheduler.rasterization.swizzle_size[0]
            if tile_scheduler.rasterization.raster_order[0] is RasterOrder.ALONG_N:  # noqa: SIM108
                raster_along = "n"
            elif tile_scheduler.rasterization.raster_order[0] is RasterOrder.ALONG_M:  # noqa: SIM108
                raster_along = "m"
            else:
                assert False, f"Unsupported raster order: {tile_scheduler}"  # noqa: B011
        elif tile_scheduler is not None:
            assert False, f"Unsupported tile scheduler design: {tile_scheduler}"  # noqa: B011

        self.impl = SM107ReportValidGemmKernel(
            acc_dtype=operands.accumulator_type,
            use_2cta_instrs=design.use_2cta_mma,
            mma_tiler_mn=mma_tiler[:2],
            cluster_shape_mn=design.cluster_shape[:2],
            use_tma_store=design.use_tma_store,
            swizzle_size=swizzle_size,
            raster_along=raster_along,
            producer_sentinel_init=producer_sentinel_init,
            positive_zero_only=is_data_driven_producer,
        )

    def _compile(
        self, args: GemmArguments, target_sm: TargetSm | None = None
    ) -> CompiledArtifact:
        return self.cute_compile(
            bmm,
            self.impl,
            args.A.tensor,
            args.B.tensor,
            args.out.tensor,
            cutlass.Int32(0),
            cutlass.cute.runtime.make_fake_stream(),
            self.pdl_early_launch_next,
            self.pdl_early_start,
            self.check_b_valid,
            self.eager_launch_next,
            target_sm=target_sm,
        )

    def _run(
        self,
        args: GemmArguments,
        compiled_artifact: CompiledArtifact,
        stream,
        workspace=None,
        *,
        device_properties: DeviceProperties,
    ) -> None:
        self.cute_run(
            compiled_artifact.compiled_obj,
            args.A.tensor,
            args.B.tensor,
            args.out.tensor,
            device_properties.max_active_clusters(self.impl.cluster_shape_mn),
            to_cuda_stream(stream),
        )

    @classmethod
    def _generate_operators(
        cls,
        metadata_filter: Callable[[OperatorMetadata], bool],
        epilogue_args: EpilogueArguments | None = None,
        target_sm: TargetSm | None = None,
        args: GemmArguments | None = None,
    ) -> list[Sm107DenseGemmDataDrivenSyncOperator]:
        if epilogue_args is not None:
            return []

        operators = []
        for operand_keys in _valid_operand_combos(args):
            operands = _make_operands_metadata(**operand_keys)
            operands_name = _operands_name_part(operands)
            for design, design_name in _valid_designs(
                operand_keys["a_dtype"], operand_keys["b_dtype"]
            ):
                metadata = OperatorMetadata(
                    operands=operands,
                    design=design,
                    operator_name=operands_name + "_" + design_name,
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
    # Every value the kernel accepts for each operand parameter. Only a subset
    # of the cross product is legal, checked by _kernel_accepts_operands below.
    operand_keys = {
        "a_dtype": (cutlass.Float16,),
        "b_dtype": (cutlass.Float16,),
        "out_dtype": (cutlass.Float16,),
        "acc_dtype": (cutlass.Float32,),
        "a_major": ("k",),
        "b_major": ("n", "k"),
        "c_major": ("m", "n"),
    }

    if args is not None:
        requested_keys = _operand_keys_from_args(args)
        if requested_keys is None:
            return []
        # Arguments may only narrow the space above, never widen it.
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
    """Return the single operand configuration ``args`` asks for, or ``None``.

    The result carries one value per operand parameter, keyed as the enumerated
    space in ``_generate_operators`` is, so that it narrows that space by dict
    update. ``None`` means this operator cannot serve ``args`` at all.
    """
    if not isinstance(args, GemmArguments):
        return None
    if not (isinstance(args.A, DenseTensor) and isinstance(args.B, DenseTensor)):
        return None

    def major(operand: DenseTensor, row_major: str, col_major: str) -> str | None:
        """Name of the contiguous mode, or None if no mode has unit stride."""
        stride = normalized_major_stride(
            operand.shape, operand.stride, prepend_zeros_to_rank=3
        )
        major_mode = {(0, 0, 1): row_major, (0, 1, 0): col_major}.get(stride)
        assert major_mode is not None
        return major_mode

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
    a_dtype: cutlass.Numeric,
    b_dtype: cutlass.Numeric,
    out_dtype: cutlass.Numeric,
    acc_dtype: cutlass.Numeric,
    a_major: Literal["m", "k"],
    b_major: Literal["n", "k"],
    c_major: Literal["m", "n"],
) -> bool:
    """Return whether the kernel supports this operand configuration."""
    if acc_dtype is not cutlass.Float32:
        return False

    return _is_valid_dtypes(a_dtype, b_dtype, out_dtype) and _is_valid_layouts(
        a_major, b_major, c_major
    )


@functools.cache
def _valid_designs(
    a_dtype: cutlass.Numeric,
    b_dtype: cutlass.Numeric,
) -> tuple[tuple[Sm107DesignMetadata, str], ...]:
    """Enumerate the designs the kernel accepts for given operand dtypes, and part of the kernel name it decides.

    Cached as there is a fixed set of design combinations that will be repeatedly used.
    Narrowing by runtime data-driven sync performance controls happens downstream via
    ``Sm107DesignMetadata.supports``, not here.
    """
    # Maximal list of independent design parameters
    # Other design parameters are not independent: they are derived from the
    # parameters below and/or operand dtypes (see _mma_shapes).
    design_keys = {
        "use_tma_store": (True,),
        "use_2cta_mma": (False, True),
        # F16/BF16 MMA does not support the Bkeep/Breuse collector ops (see
        # _mma_shapes), and SM107ReportValidGemmKernel never forwards this flag to
        # the kernel, so True would silently be a no-op duplicate of False.
        "enable_breuse": (False,),
        "tile_n": (64, 128, 256),
        "cluster_shape": tuple(
            (cluster_m, cluster_n, 1)
            for cluster_m in (1, 2, 4)  # max deliberate capped to 4 by kernel
            for cluster_n in (1, 2, 4)
        ),
        "data_driven_sync": tuple(_valid_data_driven_sync_designs()),
        "pdl": tuple(_valid_pdl_designs()),
        "tile_scheduler": tuple(_valid_tile_scheduler_designs()),
    }

    designs = []
    for design_values in itertools.product(*design_keys.values()):
        design_combo = dict(zip(design_keys, design_values))
        if design_combo["use_2cta_mma"] and design_combo["cluster_shape"][0] == 1:
            continue
        if (
            not design_combo["use_2cta_mma"]
            and design_combo["cluster_shape"][0] > 2
            and design_combo["data_driven_sync"].consumer is not None
        ):
            continue

        cta_tile_shape, mma_tiler, mma_inst_shape = _mma_shapes(
            a_dtype,
            b_dtype,
            design_combo["tile_n"],
            design_combo["use_2cta_mma"],
            enable_breuse=design_combo["enable_breuse"],
        )
        if not _is_valid_mma_tiler_and_cluster_shape(
            mma_inst_shape,
            mma_tiler,
            design_combo["cluster_shape"],
            design_combo["use_2cta_mma"],
            design_combo["use_tma_store"],
        ):
            continue

        design = Sm107DesignMetadata(
            mma_instruction_type=RubinTcgen05Mma,
            use_tma_store=design_combo["use_tma_store"],
            use_2cta_mma=design_combo["use_2cta_mma"],
            enable_breuse=design_combo["enable_breuse"],
            tile_shape=cta_tile_shape,
            cluster_shape=design_combo["cluster_shape"],
            data_driven_sync=design_combo["data_driven_sync"],
            pdl=design_combo["pdl"],
            tile_scheduler=design_combo["tile_scheduler"],
        )
        designs.append((design, _design_name_part(design)))
    return tuple(designs)


def _valid_pdl_designs() -> list[ProgrammaticDependentLaunchMetadata]:
    """Enumerate the PDL configurations the kernel accepts.

    * Disabled: no PDL.
    * Early-launch only: signals dependents at kernel start.
    * Early-start only: can start before its producer completes, with A
      independent (B is the report_valid-loaded operand and must stay
      dependent, see ``_valid_data_driven_sync_designs``).
    * Both.
    """
    early_start = EarlyStartMetadata(independent_operands=("A",))
    return [
        ProgrammaticDependentLaunchMetadata(),
        ProgrammaticDependentLaunchMetadata(
            early_launch_dependent=True, early_start=None
        ),
        ProgrammaticDependentLaunchMetadata(
            early_launch_dependent=False, early_start=early_start
        ),
        ProgrammaticDependentLaunchMetadata(
            early_launch_dependent=True, early_start=early_start
        ),
    ]


def _valid_data_driven_sync_designs() -> list[DataDrivenSyncMetadata]:
    """Enumerate the data-driven sync configurations the kernel accepts.

    Producer-only, consumer-only, producer+consumer.
    """
    designs = [DataDrivenSyncMetadata()]

    # Kernel only supports streaming-in B
    consumer_metadata = DataDrivenSyncConsumerMetadata(consumed_operands=("B",))

    # Producer-only and Producer+Consumer
    for output_sentinel_prefill in (False, True):
        producer = DataDrivenSyncProducerMetadata(
            minimum_atomic_write_bytes=16,
            output_sentinel_prefill=output_sentinel_prefill,
        )
        designs.append(DataDrivenSyncMetadata(producer=producer, consumer=None))
        designs.append(
            DataDrivenSyncMetadata(producer=producer, consumer=consumer_metadata)
        )

    # Consumer-only
    designs.append(DataDrivenSyncMetadata(producer=None, consumer=consumer_metadata))

    return designs


def _valid_tile_scheduler_designs() -> list[TileSchedulerMetadata | None]:
    from cutlass.operators.metadata import design

    # To be more accurate, we could report tile scheduler design's persistence instead of None
    # But because this is an example kernel to pipeclean integration, we'll leave as opaque None to reduce complexity
    designs = [None]
    return designs

def _mma_shapes(
    a_dtype: cutlass.Numeric,
    b_dtype: cutlass.Numeric,
    tile_n: int,
    use_2cta_mma: bool,
    enable_breuse: bool,
) -> tuple[tuple[int, int, int], tuple[int, int, int], tuple[int, int, int]]:
    """Return ``(cta_tile_shape, mma_tiler, mma_inst_shape)`` for a f16 configuration."""
    assert a_dtype == cutlass.Float16 and b_dtype == cutlass.Float16
    mma_ctas = 2 if use_2cta_mma else 1
    inst_k = 16

    mma_inst_shape = (128 * mma_ctas, tile_n, inst_k)
    mma_tiler = (mma_inst_shape[0], tile_n, inst_k * 2)
    cta_tile_shape = (mma_tiler[0] // mma_ctas, tile_n, mma_tiler[2])
    return cta_tile_shape, mma_tiler, mma_inst_shape


################################################################################
# Helpers to check valid configs for the kernel
################################################################################


def _is_valid_dtypes(
    a_dtype: cutlass.Numeric, b_dtype: cutlass.Numeric, out_dtype: cutlass.Numeric
) -> bool:
    return all(dtype == cutlass.Float16 for dtype in [a_dtype, b_dtype, out_dtype])


def _is_valid_layouts(
    a_major: Literal["m", "k"], b_major: Literal["n", "k"], c_major: Literal["m", "n"]
) -> bool:
    return a_major == "k"


def _is_valid_mma_tiler_and_cluster_shape(
    mma_inst_shape: tuple[int, int, int],
    mma_tiler: tuple[int, int, int],
    cluster_shape: tuple[int, int, int],
    use_2cta_instrs: bool,
    use_tma_store: bool,
) -> bool:
    if use_2cta_instrs:
        if mma_inst_shape[0] not in [128, 256]:
            return False
    else:
        if mma_inst_shape[0] not in [64, 128]:
            return False
    try:
        BlackwellDenseGemmPersistentKernel.is_valid_mma_tiler_and_cluster_shape(
            mma_tiler[:2],
            cluster_shape[:2],
            use_2cta_instrs,
            use_tma_store,
        )
    except testing.CantImplementError:
        return False
    return True


################################################################################
# Helpers to map one configuration onto the kernel
################################################################################


def _make_operands_metadata(
    a_dtype: cutlass.Numeric,
    b_dtype: cutlass.Numeric,
    out_dtype: cutlass.Numeric,
    acc_dtype: cutlass.Numeric,
    a_major: Literal["m", "k"],
    b_major: Literal["n", "k"],
    c_major: Literal["m", "n"],
) -> GemmOperandsMetadata:
    """Make GemmOperandsMetadata from operand config keys."""
    stride_A = (0, 0, 1) if a_major == "k" else (0, 1, 0)
    stride_B = (0, 0, 1) if b_major == "n" else (0, 1, 0)
    stride_out = (0, 0, 1) if c_major == "n" else (0, 1, 0)

    alignment_bytes = 16

    def elements_per_line(dtype: cutlass.Numeric) -> int:
        return alignment_bytes * 8 // dtype.width

    return GemmOperandsMetadata(
        A=DenseTensorConstraints(
            dtype=a_dtype,
            stride=stride_A,
            divisibility=elements_per_line(a_dtype),
        ),
        B=DenseTensorConstraints(
            dtype=b_dtype,
            stride=stride_B,
            divisibility=elements_per_line(b_dtype),
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
        "cutedsl.Sm107DenseGemmDataDrivenSyncOperator"
        f"_{layout}"
        f"_A{operands.A.dtype}_B{operands.B.dtype}_out{operands.out.dtype}"
        f"_acc{operands.accumulator_type}"
    )


def _design_name_part(design: Sm107DesignMetadata) -> str:
    """Build the design half of an Operator name."""
    return (
        f"{'2' if design.use_2cta_mma else '1'}cta"
        f"_cluster{tuple_to_string(design.cluster_shape)}"
        f"_tile{tuple_to_string(design.tile_shape)}"
        f"{'_tma_store' if design.use_tma_store else ''}"
        f"{data_driven_sync_name_part(design)}"
        f"{pdl_name_part(design)}"
    )


def data_driven_sync_name_part(design: Sm107DesignMetadata) -> str:
    """Build the data-driven-sync half of an Operator name."""
    sync = design.data_driven_sync
    if not sync.is_enabled():
        return ""

    roles = []
    if sync.producer is not None:
        role = "producer"
        if not sync.producer.output_sentinel_prefill:
            role += "_noprefill"
        roles.append(role)
    if sync.consumer is not None:
        role = "consumer"
        if sync.consumer.consumed_operands:
            role += "_consumed" + "".join(sorted(sync.consumer.consumed_operands))
        roles.append(role)

    return "_data_driven_" + "_".join(roles)


def pdl_name_part(design: Sm107DesignMetadata) -> str:
    """Build the PDL half of an Operator name."""
    pdl = design.pdl
    if not pdl.is_enabled():
        return ""

    parts = []
    if pdl.early_launch_dependent:
        parts.append("early_launch")
    if pdl.early_start is not None:
        role = "early_start"
        if pdl.early_start.independent_operands:
            role += "_independent" + "".join(
                sorted(pdl.early_start.independent_operands)
            )
        parts.append(role)

    return "_pdl_" + "_".join(parts)
