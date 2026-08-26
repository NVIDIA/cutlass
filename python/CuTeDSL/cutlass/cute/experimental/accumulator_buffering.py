# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/latest/media/docs/pythonDSL/license.html
#
# Any use, reproduction, disclosure, or distribution of this software
# and related documentation outside the scope permitted by the EULA
# is strictly prohibited.

"""Planning and pipeline-safe access for TMEM accumulator buffering.

Overlapping ping-pong uses two logical accumulator views backed by one
shortened TMEM allocation. Correctness couples that storage layout to a
one-stage synchronization pipeline, phase-based view selection, reverse drain
of one view, and early consumer release. This module packages those choices so
kernel authors cannot configure them independently by accident.
"""

from dataclasses import dataclass
from enum import Enum
from typing import Optional, Sequence, Type, cast

import cutlass
from cutlass import cute
from cutlass._mlir import ir
from cutlass.cutlass_dsl import Integer, Numeric

from .pipeline import GenericPipelineBase


class AccumulatorBufferingKind(Enum):
    """Physical relationship between logical accumulator views."""

    DISJOINT = "disjoint"
    OVERLAPPING = "overlapping"


class AccumulatorOverlapPolicy(Enum):
    """Policy used to choose a legal overlap width."""

    MINIMUM_LEGAL_FIT = "minimum_legal_fit"


@dataclass(frozen=True)
class TmemAllocationRequest:
    """One owning TMEM allocation packed after the accumulator.

    ``alignment_columns`` uses the allocator's 32-bit TMEM-column unit, not
    bytes. Requests must appear in the same order as their kernel allocations.
    """

    name: str
    columns: int
    alignment_columns: int

    def __post_init__(self) -> None:
        if not self.name:
            raise ValueError("TMEM allocation request name must be non-empty")
        if self.columns < 0:
            raise ValueError(
                f"TMEM allocation {self.name!r} has negative columns: {self.columns}"
            )
        if self.alignment_columns <= 0:
            raise ValueError(
                f"TMEM allocation {self.name!r} has non-positive alignment: "
                f"{self.alignment_columns}"
            )

    @staticmethod
    def from_layout(
        name: str,
        layout: cute.Layout,
        dtype: Type[Numeric],
        *,
        alignment_bytes: int,
    ) -> "TmemAllocationRequest":
        """Build a request from the same layout/alignment passed to allocate."""
        if alignment_bytes <= 0 or alignment_bytes % 4 != 0:
            raise ValueError(
                "TMEM alignment must be a positive multiple of the 4-byte "
                f"column size, got {alignment_bytes}"
            )
        return TmemAllocationRequest(
            name=name,
            columns=_compute_tmem_cols_from_layout(layout, dtype),
            alignment_columns=alignment_bytes // 4,
        )


@dataclass(frozen=True)
class _AccumulatorPlanSelection:
    kind: AccumulatorBufferingKind
    storage_depth: int
    synchronization_depth: int
    one_stage_columns: int
    stage_stride_columns: int
    physical_columns: int
    overlap_columns: int
    release_after_t2r_ordinal: int
    allocation_offsets: tuple[int, ...]
    packed_columns: int


@dataclass(frozen=True)
class AccumulatorBufferingPlan:
    """Validated compile-time accumulator storage and drain schedule."""

    kind: AccumulatorBufferingKind
    storage_depth: int
    synchronization_depth: int
    one_stage_columns: int
    stage_stride_columns: int
    physical_columns: int
    overlap_columns: int
    release_after_t2r_ordinal: int
    allocation_offsets: tuple[int, ...]
    packed_columns: int
    storage_layout: cute.Layout

    def __post_init__(self) -> None:
        if self.one_stage_columns <= 0:
            raise ValueError("one accumulator view must occupy positive TMEM columns")
        if self.kind is AccumulatorBufferingKind.DISJOINT:
            if self.storage_depth <= 0:
                raise ValueError("disjoint accumulator depth must be positive")
            if self.synchronization_depth != self.storage_depth:
                raise ValueError(
                    "disjoint accumulator storage and synchronization depths must match"
                )
            if self.overlap_columns != 0:
                raise ValueError("disjoint accumulators cannot have overlap columns")
            if self.stage_stride_columns != self.one_stage_columns:
                raise ValueError(
                    "disjoint accumulator stride must equal one-view columns"
                )
            if self.physical_columns != self.storage_depth * self.one_stage_columns:
                raise ValueError("disjoint accumulator footprint is inconsistent")
        else:
            if self.storage_depth != 2 or self.synchronization_depth != 1:
                raise ValueError(
                    "overlapping accumulators require storage depth 2 and "
                    "synchronization depth 1"
                )
            if not 0 < self.overlap_columns < self.one_stage_columns:
                raise ValueError(
                    "overlap columns must be positive and smaller than one view"
                )
            if self.stage_stride_columns != (
                self.one_stage_columns - self.overlap_columns
            ):
                raise ValueError("overlapping accumulator stride is inconsistent")
            if self.physical_columns != (
                2 * self.one_stage_columns - self.overlap_columns
            ):
                raise ValueError("overlapping accumulator footprint is inconsistent")

    @property
    def uses_overlap(self) -> bool:
        """Whether this plan uses aliased accumulator views."""
        return self.kind is AccumulatorBufferingKind.OVERLAPPING

    def producer_acquire_and_get_view(
        self,
        pipeline: GenericPipelineBase,
        buffer: cute.Tensor,
    ) -> cute.Tensor:
        """Acquire and select the producer view before pipeline advance.

        The coupled pipeline helper is intentional: exposing an aliased view
        before its acquire would let the next producer overwrite data that the
        consumer has not finished draining.
        """
        if cutlass.const_expr(self.uses_overlap):
            selector = pipeline.producer_acquire_and_get_phase() ^ 1
        else:
            _, selector = pipeline.producer_acquire_and_get_stage()
        return _select_last_mode(buffer, cast(cute.Int32, selector))

    def consumer_wait_and_get_view(
        self,
        pipeline: GenericPipelineBase,
        buffer: cute.Tensor,
    ) -> tuple[cute.Tensor, "AccumulatorDrain"]:
        """Wait and select the consumer view before release/advance.

        Waiting and view selection stay coupled so callers cannot drain an
        aliased view before the matching producer commit becomes visible.
        """
        if cutlass.const_expr(self.uses_overlap):
            selector = pipeline.consumer_wait_and_get_phase()
        else:
            _, selector = pipeline.consumer_wait_and_get_stage()
        view = _select_last_mode(buffer, selector)
        return view, AccumulatorDrain(self, pipeline, selector)


class AccumulatorDrain:
    """Loop-carried accumulator pipeline plus its compile-time drain plan."""

    def __init__(
        self,
        plan: AccumulatorBufferingPlan,
        pipeline: GenericPipelineBase,
        consumer_selector: cute.Int32,
    ) -> None:
        self.plan = plan
        self.pipeline = pipeline
        self.consumer_selector = consumer_selector

    def __extract_mlir_values__(self) -> list[ir.Value]:
        """Extract the dynamic pipeline and selector fields."""
        return self.pipeline.__extract_mlir_values__() + [
            self.consumer_selector.ir_value()
        ]

    def __new_from_mlir_values__(self, values: list[ir.Value]) -> "AccumulatorDrain":
        """Rebuild dynamic fields while preserving the compile-time plan."""
        new = AccumulatorDrain.__new__(AccumulatorDrain)
        new.plan = self.plan
        new.pipeline = self.pipeline.__class__.__new_from_mlir_values__(values[:-1])
        new.consumer_selector = cute.Int32(0).__new_from_mlir_values__([values[-1]])  # type: ignore[attr-defined]
        return new


def _align_up(value: int, alignment: int) -> int:
    return ((value + alignment - 1) // alignment) * alignment


def _compute_tmem_cols_from_layout(
    layout: cute.Layout,
    dtype: Type[Numeric],
) -> int:
    """Return a static layout footprint in 32-bit TMEM columns."""
    # Import lazily because ``cutlass.memory`` itself imports ``cutlass.cute``;
    # importing it while the cute package initializes would form a cycle.
    from cutlass.memory.tmem import compute_tmem_cols_from_layout

    return compute_tmem_cols_from_layout(layout, dtype)


def _compute_epilogue_subtile_columns(
    one_stage_layout: cute.Layout,
    accumulator_dtype: Type[Numeric],
    epilogue_tile: cute.Tile,
) -> int:
    """Return the TMEM columns drained by one epilogue T2R iteration.

    The epilogue tile is expressed in accumulator elements, while overlap and
    allocator footprints use 32-bit TMEM columns. Derive the width from the
    same stage view and layout division used by the epilogue instead of
    assuming those units coincide for every accumulator layout.
    """
    # ``make_fragment_C`` nests M/N in the first mode and retains singleton
    # modes consumed by the MMA interface. The epilogue removes those modes
    # before ``flat_divide``; mirror that exact view here.
    stage_coord = ((None, None),) + (0,) * (cute.rank(one_stage_layout) - 1)
    stage_layout = cute.slice_(one_stage_layout, stage_coord)
    divided_layout = cute.flat_divide(stage_layout, epilogue_tile)
    subtile_coord = (None, None) + (0,) * (cute.rank(divided_layout) - 2)
    subtile_layout = cute.slice_(divided_layout, subtile_coord)
    subtile_columns = _compute_tmem_cols_from_layout(subtile_layout, accumulator_dtype)
    if subtile_columns <= 0:
        raise ValueError("epilogue subtile must occupy positive TMEM columns")
    return subtile_columns


def _get_tmem_column_stride_basis(
    one_stage_layout: cute.Layout,
) -> int | Integer | cute.ScaledBasis:
    """Return the native layout stride corresponding to one TMEM N column."""
    outer_stride = one_stage_layout.stride
    if not isinstance(outer_stride, tuple) or not outer_stride:
        raise ValueError(
            "accumulator layout must expose the TMEM N-column stride at stride[0][1]"
        )
    first_mode_stride = outer_stride[0]
    if not isinstance(first_mode_stride, tuple) or len(first_mode_stride) < 2:
        raise ValueError(
            "accumulator layout must expose the TMEM N-column stride at stride[0][1]"
        )
    column_stride_basis = first_mode_stride[1]
    if isinstance(column_stride_basis, tuple):
        raise ValueError(
            "accumulator layout must expose a scalar TMEM N-column stride at "
            "stride[0][1]"
        )
    return column_stride_basis


def _pack_allocations(
    accumulator_columns: int,
    accumulator_alignment_columns: int,
    auxiliary_allocations: Sequence[TmemAllocationRequest],
) -> tuple[int, tuple[int, ...]]:
    offset = _align_up(0, accumulator_alignment_columns)
    offsets = [offset]
    offset += accumulator_columns
    for request in auxiliary_allocations:
        offset = _align_up(offset, request.alignment_columns)
        offsets.append(offset)
        offset += request.columns
    return offset, tuple(offsets)


def _plan_accumulator_buffering_columns(
    *,
    one_stage_columns: int,
    epilogue_subtile_columns: int,
    auxiliary_tmem_allocations: Sequence[TmemAllocationRequest],
    tmem_capacity_columns: int,
    desired_disjoint_depth: int = 2,
    max_auto_disjoint_depth: int = 2,
    allow_overlap: bool = False,
    overlap_alignment_columns: int = 1,
    accumulator_alignment_columns: int = 4,
    overlap_policy: AccumulatorOverlapPolicy = (
        AccumulatorOverlapPolicy.MINIMUM_LEGAL_FIT
    ),
) -> _AccumulatorPlanSelection:
    """Pure integer implementation shared by the DSL planner and unit tests."""
    if one_stage_columns <= 0:
        raise ValueError("one_stage_columns must be positive")
    if epilogue_subtile_columns <= 0:
        raise ValueError("epilogue_subtile_columns must be positive")
    if tmem_capacity_columns <= 0:
        raise ValueError("tmem_capacity_columns must be positive")
    if desired_disjoint_depth <= 0:
        raise ValueError("desired_disjoint_depth must be positive")
    if max_auto_disjoint_depth <= 0:
        raise ValueError("max_auto_disjoint_depth must be positive")
    if overlap_alignment_columns <= 0:
        raise ValueError("overlap_alignment_columns must be positive")
    if accumulator_alignment_columns <= 0:
        raise ValueError("accumulator_alignment_columns must be positive")
    if overlap_policy is not AccumulatorOverlapPolicy.MINIMUM_LEGAL_FIT:
        raise ValueError(f"unsupported accumulator overlap policy: {overlap_policy}")

    max_disjoint_depth = min(desired_disjoint_depth, max_auto_disjoint_depth)
    for disjoint_depth in range(max_disjoint_depth, 1, -1):
        disjoint_columns = disjoint_depth * one_stage_columns
        packed, offsets = _pack_allocations(
            disjoint_columns,
            accumulator_alignment_columns,
            auxiliary_tmem_allocations,
        )
        if packed <= tmem_capacity_columns:
            return _AccumulatorPlanSelection(
                kind=AccumulatorBufferingKind.DISJOINT,
                storage_depth=disjoint_depth,
                synchronization_depth=disjoint_depth,
                one_stage_columns=one_stage_columns,
                stage_stride_columns=one_stage_columns,
                physical_columns=disjoint_columns,
                overlap_columns=0,
                release_after_t2r_ordinal=(
                    (one_stage_columns + epilogue_subtile_columns - 1)
                    // epilogue_subtile_columns
                    - 1
                ),
                allocation_offsets=offsets,
                packed_columns=packed,
            )

    if allow_overlap and max_disjoint_depth >= 2:
        for overlap_columns in range(1, one_stage_columns):
            stage_stride_columns = one_stage_columns - overlap_columns
            if stage_stride_columns % overlap_alignment_columns != 0:
                continue
            physical_columns = 2 * one_stage_columns - overlap_columns
            packed, offsets = _pack_allocations(
                physical_columns,
                accumulator_alignment_columns,
                auxiliary_tmem_allocations,
            )
            if packed <= tmem_capacity_columns:
                release_ordinal = (
                    overlap_columns + epilogue_subtile_columns - 1
                ) // epilogue_subtile_columns - 1
                subtile_count = (
                    one_stage_columns + epilogue_subtile_columns - 1
                ) // epilogue_subtile_columns
                if release_ordinal >= subtile_count:
                    continue
                return _AccumulatorPlanSelection(
                    kind=AccumulatorBufferingKind.OVERLAPPING,
                    storage_depth=2,
                    synchronization_depth=1,
                    one_stage_columns=one_stage_columns,
                    stage_stride_columns=stage_stride_columns,
                    physical_columns=physical_columns,
                    overlap_columns=overlap_columns,
                    release_after_t2r_ordinal=release_ordinal,
                    allocation_offsets=offsets,
                    packed_columns=packed,
                )

    packed, offsets = _pack_allocations(
        one_stage_columns,
        accumulator_alignment_columns,
        auxiliary_tmem_allocations,
    )
    if packed <= tmem_capacity_columns:
        return _AccumulatorPlanSelection(
            kind=AccumulatorBufferingKind.DISJOINT,
            storage_depth=1,
            synchronization_depth=1,
            one_stage_columns=one_stage_columns,
            stage_stride_columns=one_stage_columns,
            physical_columns=one_stage_columns,
            overlap_columns=0,
            release_after_t2r_ordinal=(
                (one_stage_columns + epilogue_subtile_columns - 1)
                // epilogue_subtile_columns
                - 1
            ),
            allocation_offsets=offsets,
            packed_columns=packed,
        )

    requests = ", ".join(
        f"{request.name}={request.columns} cols/align {request.alignment_columns}"
        for request in auxiliary_tmem_allocations
    )
    raise ValueError(
        "insufficient TMEM for one accumulator view: "
        f"accumulator={one_stage_columns} cols, auxiliary=[{requests}], "
        f"aligned_total={packed}, capacity={tmem_capacity_columns}"
    )


def plan_accumulator_buffering(
    *,
    one_stage_layout: cute.Layout,
    accumulator_dtype: Type[Numeric],
    epilogue_tile: Optional[cute.Tile] = None,
    epilogue_subtile_columns: Optional[int] = None,
    auxiliary_tmem_allocations: Sequence[TmemAllocationRequest] = (),
    tmem_capacity_columns: int = 512,
    desired_disjoint_depth: int = 2,
    max_auto_disjoint_depth: int = 2,
    allow_overlap: bool = False,
    overlap_alignment_columns: int = 1,
    accumulator_alignment_bytes: int = 16,
    overlap_policy: AccumulatorOverlapPolicy = (
        AccumulatorOverlapPolicy.MINIMUM_LEGAL_FIT
    ),
) -> AccumulatorBufferingPlan:
    """Plan disjoint or overlapping accumulator buffering and build its layout.

    Auxiliary requests are allocator inputs, not inferred lifetimes. The kernel
    must allocate the accumulator first and then every request in the supplied
    order for the planner's offsets and capacity decision to match the kernel's
    static TMEM allocation. ``epilogue_tile`` should be the same tile passed to
    the epilogue's ``flat_divide``; its footprint is converted from accumulator
    elements to 32-bit TMEM columns. ``epilogue_subtile_columns`` is a direct
    column-unit override intended for callers that already performed that
    conversion and for pure-integer policy tests.
    """
    if accumulator_alignment_bytes <= 0 or accumulator_alignment_bytes % 4 != 0:
        raise ValueError("accumulator_alignment_bytes must be a positive multiple of 4")
    if epilogue_subtile_columns is None:
        if not isinstance(epilogue_tile, tuple) or len(epilogue_tile) < 2:
            raise ValueError(
                "provide epilogue_subtile_columns or a rank-2 epilogue_tile, "
                f"got {epilogue_tile}"
            )
        epilogue_subtile_columns = _compute_epilogue_subtile_columns(
            one_stage_layout,
            accumulator_dtype,
            epilogue_tile,
        )
    elif epilogue_tile is not None:
        raise ValueError(
            "provide only one of epilogue_tile and epilogue_subtile_columns"
        )

    one_stage_columns = _compute_tmem_cols_from_layout(
        one_stage_layout, accumulator_dtype
    )
    selection = _plan_accumulator_buffering_columns(
        one_stage_columns=one_stage_columns,
        epilogue_subtile_columns=epilogue_subtile_columns,
        auxiliary_tmem_allocations=auxiliary_tmem_allocations,
        tmem_capacity_columns=tmem_capacity_columns,
        desired_disjoint_depth=desired_disjoint_depth,
        max_auto_disjoint_depth=max_auto_disjoint_depth,
        allow_overlap=allow_overlap,
        overlap_alignment_columns=overlap_alignment_columns,
        accumulator_alignment_columns=accumulator_alignment_bytes // 4,
        overlap_policy=overlap_policy,
    )

    column_stride_basis = _get_tmem_column_stride_basis(one_stage_layout)
    storage_layout = cute.make_layout(
        cute.append(one_stage_layout.shape, selection.storage_depth),
        stride=cute.append(
            one_stage_layout.stride,
            selection.stage_stride_columns * column_stride_basis,
        ),
    )
    actual_columns = _compute_tmem_cols_from_layout(storage_layout, accumulator_dtype)
    if actual_columns != selection.physical_columns:
        raise ValueError(
            "planned accumulator footprint does not match the constructed layout: "
            f"planned={selection.physical_columns}, actual={actual_columns}"
        )

    return AccumulatorBufferingPlan(
        **selection.__dict__,
        storage_layout=storage_layout,
    )


def _select_last_mode(buffer: cute.Tensor, selector: cute.Int32) -> cute.Tensor:
    slicer = (None,) * (cute.rank(buffer) - 1) + (selector,)
    return cast(cute.Tensor, buffer[slicer])
