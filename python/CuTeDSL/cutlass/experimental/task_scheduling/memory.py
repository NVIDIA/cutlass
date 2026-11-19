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

"""Unified memory allocators for the TS framework.

Provides declarative layout mechanisms for SMEM and TMEM: resources
declare requirements as allocation objects, and allocators compute a
flat layout with optional phase-based aliasing.

Typical usage:

.. code-block:: python

    allocator = SmemAllocator()

    # Resources expose their allocations
    for alloc in resource.get_smem_requirements():
        allocator.add(alloc)

    # Optional: alias allocations whose lifetimes don't overlap.
    # Each inner list is a "phase" — allocations within a phase coexist
    # and get sequential offsets.  Different phases reuse the same
    # physical region.
    allocator.add_alias_group([
        [smem_ab._alloc_a, smem_ab._alloc_b],   # phase 1: coexist
        [epilogue._alloc_scratch],                # phase 2: reuses
    ])

    allocator.compute_layout()   # pure Python — sets .offset on each alloc
    # allocator.allocate() called later at DSL-trace time to emit the
    # cutlass.Array(..., space=cutlass.AddressSpace.smem) op.

Classes
-------
SmemAllocation / TmemAllocation
    Describe named SMEM (byte) or TMEM (column) regions. After
    ``compute_layout()``, the ``.offset`` field contains the offset
    from the base of the unified block.

    ``SmemAllocation`` accepts an optional ``dtype`` and ``count``.
    When ``dtype`` is provided without explicit ``size_bytes``, the
    size is auto-computed as ``count * dtype.width // 8``.  The stored
    dtype enables ``SmemAllocator.get()`` to return a typed array
    without re-specifying the element type.

BarrierAllocation
    Describe a group of mbarriers sharing the same initialization count,
    stored contiguously. After ``compute_layout()``, the ``.offset`` field
    contains the offset from the base of the coalesced barrier array.

ResourceContext
    Frozen context object embedded in ``StageInfo``.  Carries ``smem_base`` and
    ``tmem_ptr_i32``.

_LayoutAllocator
    Base class with common declaration and layout logic.

SmemAllocator / TmemAllocator
    Concrete allocators for SMEM bytes (with alignment) and TMEM
    columns (no alignment).  ``SmemAllocator`` can also emit a single
    ``cutlass.Array(..., space=cutlass.AddressSpace.smem)`` call at DSL-trace time.

BarrierAllocator
    Allocator for a coalesced barrier array, bucketed by barrier type and count.
    Provides efficient initialization of the array (individual pipelines must receive
    ``defer_init=True``, the storage and computed offsets).
"""

from dataclasses import dataclass, field, replace
from typing import Any, List, Optional, Tuple, Union, cast

import cutlass
import cutlass.cute as cute
from cutlass import base_dsl
from cutlass.cute.arch.constants import WARP_SIZE
from cutlass.cutlass_dsl import CuTeDSL, Int32, if_generate
from cutlass.pipeline import CooperativeGroup, MbarrierLayout
from cutlass.pipeline.helpers import _get_thread_arrive_count


def _align_up(value: int, alignment: int) -> int:
    # NOTE: alignment must be a power of 2 for the bitwise trick to work.
    assert alignment > 0 and (alignment & (alignment - 1)) == 0, (
        f"alignment must be a power of 2, got {alignment}"
    )
    return (value + alignment - 1) & ~(alignment - 1)


@dataclass
class SmemAllocation:
    """Declares a named SMEM region.

    Attributes
    ----------
    name : str
        Human-readable label for debugging.
    size_bytes : int
        Required size in bytes.  When 0 and ``dtype`` is provided,
        auto-computed as ``count * dtype.width // 8``.
    alignment : int
        Required alignment in bytes (default 128 for TMA).
    dtype : Any
        Optional element type.  When set, enables ``SmemAllocator.get()``
        to return a typed ``cutlass.Array`` without re-specifying the type.
    count : int
        Number of elements (default 1).  Used with ``dtype`` to
        auto-compute ``size_bytes`` and as the shape for ``get()``.
    offset : int
        Byte offset from SMEM base, set by ``SmemAllocator.compute_layout()``.
    """

    name: str
    size_bytes: int = 0
    alignment: int = 128
    dtype: Any = None
    count: int = 1
    offset: int = field(init=False, default=0)

    def __post_init__(self) -> None:
        if self.dtype is not None and self.size_bytes == 0:
            self.size_bytes = self.count * (self.dtype.width // 8)


@dataclass
class TmemAllocation:
    """Declares a named TMEM column region.

    Attributes
    ----------
    name : str
        Human-readable label for debugging.
    num_columns : int
        Number of TMEM columns required.
    offset : int
        Column offset from TMEM base, set by ``TmemAllocator.compute_layout()``.
    """

    name: str
    num_columns: int
    offset: int = field(init=False, default=0)


@dataclass(frozen=True)
class ResourceContext:
    """Read-only context embedded in ``StageInfo``.

    Attributes
    ----------
    smem_base : Any
        ``cutlass.Array`` base pointer for the unified SMEM allocation.
        ``None`` when no ``SmemAllocator`` is in use.
    tmem_ptr_i32 : Any
        Shared-memory ``cutlass.Array[Int32, 1]`` written by
        ``nvvm.tcgen05_alloc``.  Resources use it to derive their TMEM
        addresses via ``tmem_ptr_i32.load()`` + offset.
        ``None`` when TMEM is not in use.
    """

    smem_base: Any = None
    tmem_ptr_i32: Any = None


class _LayoutAllocator:
    """Base class for layout allocators (SMEM, TMEM).

    Provides the common declaration and layout-computation logic.
    Subclasses define how to measure an allocation's size and alignment
    and how to obtain allocations from a resource.

    Alias groups are lists of **phases**.  Allocations within a phase
    coexist and get sequential offsets.  Different phases reuse the
    same physical region (same base offset).  The region is sized to
    ``max(phase_total for each phase)``.
    """

    def __init__(self) -> None:
        self._allocations: List[Any] = []
        self._alias_groups: List[List[List[Any]]] = []
        self._aliased_ids: set = set()
        self._layout_computed: bool = False
        self._total: int = 0

    # -- Subclass hooks -------------------------------------------------------

    def _alloc_size(self, alloc: Any) -> int:
        """Return the size of *alloc* in the allocator's unit."""
        raise NotImplementedError

    def _alloc_alignment(self, alloc: Any) -> int:
        """Return the alignment of *alloc* (1 = no alignment needed)."""
        return 1

    def _get_requirements(self, resource: Any) -> List[Any]:
        """Return allocation objects from *resource*."""
        raise NotImplementedError

    # -- Public API -----------------------------------------------------------

    def add(self, alloc: Any) -> Any:
        """Register a standalone (non-aliased) allocation."""
        self._allocations.append(alloc)
        return alloc

    def add_resource(self, resource: Any) -> None:
        """Register all allocations returned by the resource hook.

        Parameters
        ----------
        resource : Any
            Resource exposing the allocator-specific requirements hook.
        """
        for alloc in self._get_requirements(resource):
            self.add(alloc)

    def add_alias_group(self, phases: List[List[Any]]) -> None:
        """Declare that *phases* share the same physical region.

        Each element of *phases* is a list of allocations that coexist
        (need separate memory).  Different phases reuse the same region
        — they all start at the same base offset.  The region is sized
        to ``max(phase_total)`` across phases.

        Parameters
        ----------
        phases : list of list of allocation objects
            At least 2 phases required.
        """
        if len(phases) < 2:
            raise ValueError("Alias group must contain at least 2 phases")
        self._alias_groups.append([list(p) for p in phases])
        for phase in phases:
            for a in phase:
                self._aliased_ids.add(id(a))

    # -- Layout ---------------------------------------------------------------

    def _layout_phase(self, phase: List[Any], base_offset: int) -> int:
        """Assign offsets to allocations within a phase.

        Returns the cursor position after the last allocation.
        """
        cursor = base_offset
        for alloc in phase:
            offset = _align_up(cursor, self._alloc_alignment(alloc))
            alloc.offset = offset
            cursor = offset + self._alloc_size(alloc)
        return cursor

    def _compute_phase_size(self, phase: List[Any]) -> int:
        """Compute total size of a phase (simulated bump allocation from 0)."""
        cursor = 0
        for a in phase:
            cursor = _align_up(cursor, self._alloc_alignment(a)) + self._alloc_size(a)
        return cursor

    def compute_layout(self) -> None:
        """Assign offsets to every registered allocation.

        1. Partition into standalone allocations and alias groups.
        2. Each alias group becomes one block sized to
           ``max(phase_total)`` with alignment ``max(member alignments)``.
        3. Sort blocks by alignment descending for natural packing.
        4. Bump-allocate blocks.  Within alias groups, every phase is
           laid out from the same base offset.
        """
        if self._layout_computed:
            raise RuntimeError("compute_layout() already called")

        # (block_size, block_alignment, layout_fn)
        blocks: List[tuple] = []

        standalone = [a for a in self._allocations if id(a) not in self._aliased_ids]
        for alloc in standalone:
            blocks.append(
                (
                    self._alloc_size(alloc),
                    self._alloc_alignment(alloc),
                    lambda base, a=alloc: setattr(a, "offset", base),
                )
            )

        for group in self._alias_groups:
            group_size = max(
                (self._compute_phase_size(phase) for phase in group), default=0
            )
            group_alignment = max(
                self._alloc_alignment(a) for phase in group for a in phase
            )

            def _layout_group(base: int, grp: List[List[Any]] = group) -> None:
                for phase in grp:
                    self._layout_phase(phase, base)

            blocks.append((group_size, group_alignment, _layout_group))

        blocks.sort(key=lambda b: b[1], reverse=True)

        cursor = 0
        for size, alignment, layout_fn in blocks:
            offset = _align_up(cursor, alignment)
            layout_fn(offset)
            cursor = offset + size

        self._total = cursor
        self._layout_computed = True

    @property
    def layout_computed(self) -> bool:
        """Whether :meth:`compute_layout` has already run."""
        return self._layout_computed

    @property
    def total(self) -> int:
        """Total units required (available after ``compute_layout()``)."""
        if not self._layout_computed:
            raise RuntimeError("Call compute_layout() first")
        return self._total

    # -- Usage report ---------------------------------------------------------

    def _unit_label(self) -> str:
        """Short label for the allocation unit (e.g. ``"B"`` or ``"cols"``)."""
        return "units"

    def _report_tag(self) -> str:
        """Prefix tag for report lines (e.g. ``"smem-layout"``)."""
        return "layout"

    def _report_title(self) -> str:
        """Title for the usage report."""
        return "Memory Usage Report"

    def _report_extra_lines(self) -> List[str]:
        """Subclass hook for additional summary lines after the totals."""
        return []

    def print_usage_report(self) -> None:
        """Print a human-readable table of all allocations and alias groups."""
        if not self._layout_computed:
            raise RuntimeError("Call compute_layout() before print_usage_report()")

        tag = self._report_tag()
        unit = self._unit_label()

        all_allocs = list(self._allocations)
        for group in self._alias_groups:
            for phase in group:
                for a in phase:
                    if a not in all_allocs:
                        all_allocs.append(a)

        all_allocs.sort(key=lambda a: a.offset)

        has_alignment = any(self._alloc_alignment(a) > 1 for a in all_allocs)

        print(f"\n[{tag}] {self._report_title()}")
        if has_alignment:
            hdr = f"  {'Name':<28} {'Size':>8}  {'Align':>5}  {'Offset':>8}  {'End':>8}"
        else:
            hdr = f"  {'Name':<28} {'Size':>8}  {'Offset':>8}  {'End':>8}"
        print(hdr)
        print(f"  {'─' * (len(hdr) - 2)}")

        for a in all_allocs:
            sz = self._alloc_size(a)
            end = a.offset + sz
            aliased = " *" if id(a) in self._aliased_ids else ""
            if has_alignment:
                print(
                    f"  {a.name + aliased:<28} {sz:>8}  {self._alloc_alignment(a):>5}  "
                    f"{a.offset:>8}  {end:>8}"
                )
            else:
                print(f"  {a.name + aliased:<28} {sz:>8}  {a.offset:>8}  {end:>8}")

        if self._alias_groups:
            print(f"  {'─' * (len(hdr) - 2)}")
            for i, group in enumerate(self._alias_groups, 1):
                print(f"  Alias group {i}:")
                for j, phase in enumerate(group, 1):
                    parts = ", ".join(
                        f"{a.name} ({self._alloc_size(a)} {unit})" for a in phase
                    )
                    print(f"    Phase {j}: {parts}")

        savings = sum(self._alloc_size(a) for a in all_allocs) - self._total
        print(f"  {'─' * (len(hdr) - 2)}")

        for line in self._report_extra_lines():
            print(f"  {line}")

        print(f"  Total:          {self._total:>8} {unit}")
        if savings > 0:
            print(f"  Alias savings:  {savings:>8} {unit}")
        print()


_MBARRIER_BYTES_PER_STAGE = 2 * 8  # 2 × Int64 per pipeline stage
_MBARRIER_ALIGNMENT = 8  # alignment required by mbarrier hardware


class SmemAllocator(_LayoutAllocator):
    """SMEM layout allocator with alignment-aware bump allocation.

    Collects ``SmemAllocation`` objects, computes a flat byte layout
    (with phase-based alias groups), and emits a single
    ``cutlass.Array(..., space=cutlass.AddressSpace.smem)`` at DSL-trace time.

    Also tracks barrier SMEM consumed by pipeline resources (computed
    from ``PipelineConfig.num_stages`` when ``barrier_ptr`` is not
    pre-allocated).  See ``barrier_smem_bytes``.

    Example — epilogue scratch reuses A+B SMEM::

        allocator.add_alias_group([
            [smem_ab._alloc_a, smem_ab._alloc_b],  # phase 1: coexist
            [epilogue._alloc_scratch],               # phase 2: reuses
        ])
    """

    def __init__(self, default_add_barriers: bool = True) -> None:
        """Create an SMEM layout allocator.

        Parameters
        ----------
        default_add_barriers : bool, optional
            Whether to add barriers by default when adding a resource.
            Default is True. Can always be overriden by ``add_resource()``
            by providing the ``add_barriers`` argument.
        """
        super().__init__()
        self._smem_base: Optional[Any] = None
        self._barrier_bytes: int = 0
        self._barrier_resources: List[Any] = []
        self._barrier_groups: List[Any] = []
        self._tmem_ptr_alloc: Optional[SmemAllocation] = None
        self._default_add_barriers: bool = default_add_barriers

    def _alloc_size(self, alloc: SmemAllocation) -> int:
        return alloc.size_bytes

    def _alloc_alignment(self, alloc: SmemAllocation) -> int:
        return alloc.alignment

    def _get_requirements(self, resource: Any) -> List[SmemAllocation]:
        return resource.get_smem_requirements()

    def add_resource(
        self, resource: Any, add_barriers: Optional[bool] = None
    ) -> None:
        """Register data allocations and (optionally) accumulate barrier SMEM.

        Parameters
        ----------
        resource : Any
            Resource exposing ``get_smem_requirements()`` and, optionally,
            a ``pipeline_config`` whose barrier storage should be placed in the
            unified SMEM block.
        add_barriers : Optional[bool]
            Whether this allocator owns the resource's pipeline barriers.
            When ``None`` (the default), the value is resolved from the
            allocator-wide default set via the ``default_add_barriers``.
            A non-``None`` value always overrides that default.

        Notes
        -----
        Resources that belong to a ``PipelineGroup`` (i.e.
        ``resource.pipeline_group is not None``) have their barrier
        SMEM managed by the group, so individual barrier accounting
        is skipped.  Call ``add_pipeline_group()`` to register the
        group's barrier requirements instead.
        """
        if add_barriers is None:
            add_barriers = self._default_add_barriers
        super().add_resource(resource)
        pg = getattr(resource, "pipeline_group", None)
        cfg = getattr(resource, "pipeline_config", None)
        if (
            add_barriers
            and cfg is not None
            and cfg.barrier_ptr is None
            and pg is None
        ):
            barrier_size = cfg.num_stages * _MBARRIER_BYTES_PER_STAGE
            self._barrier_bytes = (
                _align_up(self._barrier_bytes, _MBARRIER_ALIGNMENT) + barrier_size
            )
            self._barrier_resources.append(resource)

    def add_pipeline_group(self, group: Any) -> None:
        """Register a ``PipelineGroup``'s barrier SMEM requirements.

        Individual members' data SMEM should still be registered via
        ``add_resource()``.  Their per-resource barrier accounting is
        automatically skipped (see ``add_resource``).
        """
        cfg = getattr(group, "pipeline_config", None)
        if cfg is None:
            raise ValueError(
                "PipelineGroup has no pipeline_config — call "
                "add_pipeline_group() after the group is constructed."
            )
        S = cfg.num_stages
        barrier_size = (
            group.num_barriers_per_stage * S * _MBARRIER_BYTES_PER_STAGE
        )
        self._barrier_bytes = (
            _align_up(self._barrier_bytes, _MBARRIER_ALIGNMENT) + barrier_size
        )
        self._barrier_groups.append(group)

    def add_tmem_ptr(self, alloc: SmemAllocation) -> SmemAllocation:
        """Register the TMEM-pointer infrastructure slot.

        Parameters
        ----------
        alloc : SmemAllocation
            SMEM allocation that stores the 32-bit TMEM base pointer.

        Returns
        -------
        SmemAllocation
            The same allocation object after registration.

        Notes
        -----
        The allocation is added to the layout like any other, but is
        also remembered so that ``TaskManager.setup_resources_and_tasks``
        can automatically derive the typed ``cutlass.Array`` pointer and
        populate ``ResourceContext.tmem_ptr_i32`` without caller
        intervention.
        """
        self.add(alloc)
        self._tmem_ptr_alloc = alloc
        return alloc

    @property
    def tmem_ptr_alloc(self) -> Optional[SmemAllocation]:
        """The TMEM-pointer allocation, or ``None`` if not registered."""
        return self._tmem_ptr_alloc

    @property
    def barrier_resources(self) -> List[Any]:
        """Resources whose pipeline barriers this allocator owns.
        """
        return self._barrier_resources

    @property
    def barrier_smem_bytes(self) -> int:
        """Total SMEM bytes used for pipeline mbarrier storage.

        Counts ``num_stages × 2 × 8`` for every resource whose
        ``PipelineConfig.barrier_ptr`` is ``None`` (i.e. barrier
        storage will be allocated by ``create_pipeline``).
        """
        return self._barrier_bytes

    @property
    def smem_base(self) -> Any:
        """Unified SMEM base pointer (available after ``allocate()``)."""
        return self._smem_base

    def get(self, alloc: SmemAllocation) -> Any:
        """Derive a typed ``cutlass.Array`` using the dtype/count stored on *alloc*.

        Must be called after ``allocate()``.  Requires ``alloc.dtype``
        to have been set when the ``SmemAllocation`` was constructed.
        For reinterpret-cast access, use ``get_as_type()`` instead.
        """
        if self._smem_base is None:
            raise RuntimeError("Call allocate() before get()")
        if alloc.dtype is None:
            raise TypeError(
                f"Allocation '{alloc.name}' has no dtype; use get_as_type()"
            )
        return cutlass.Array(
            self._smem_base.data_ptr() + alloc.offset,
            dtype=alloc.dtype,
            shape=(alloc.count,),
            addrspace=3,
        )

    def get_as_type(self, alloc: SmemAllocation, dtype: Any, count: int = 1) -> Any:
        """Derive a typed ``cutlass.Array`` with a custom dtype (reinterpret cast).

        Must be called after ``allocate()``.  Use when the desired
        access type differs from the allocation's declared dtype, or
        when the allocation was declared with raw ``size_bytes`` only.
        """
        if self._smem_base is None:
            raise RuntimeError("Call allocate() before get_as_type()")
        return cutlass.Array(
            self._smem_base.data_ptr() + alloc.offset,
            dtype=dtype,
            shape=(count,),
            addrspace=3,
        )

    def get_typed_ptr(self, alloc: SmemAllocation, dtype: Any, count: int = 1) -> Any:
        """Deprecated: use ``get()`` or ``get_as_type()`` instead."""
        return self.get_as_type(alloc, dtype, count)

    @property
    def total_smem_bytes(self) -> int:
        """Total data SMEM bytes (excludes barriers, available after ``compute_layout()``)."""
        return self.total

    def _unit_label(self) -> str:
        return "B"

    def _report_tag(self) -> str:
        return "smem-layout"

    def _report_title(self) -> str:
        return "SMEM Usage Report"

    def _report_extra_lines(self) -> List[str]:
        lines = [f"Data SMEM:        {self._total:>8} B"]
        if self._barrier_bytes:
            lines.append(f"Barrier SMEM:     {self._barrier_bytes:>8} B")
            lines.append(
                f"Total SMEM:       {self._total + self._barrier_bytes:>8} B  "
                f"(data + barriers)"
            )
        return lines

    def allocate(self) -> Any:
        """Emit a single ``cutlass.Array(..., space=cutlass.AddressSpace.smem)`` for the unified layout.

        The allocation covers both data regions and pipeline barrier
        storage, so ``create_pipeline()`` does not need to allocate
        barrier SMEM separately.  Call ``assign_barrier_ptrs()`` after
        this method to pre-set ``barrier_ptr`` on each resource's
        ``PipelineConfig``.

        Returns the ``cutlass.Array`` base pointer.  Must be called at
        DSL-trace time (inside a ``@cute.kernel`` or ``@cute.jit``).
        """
        if not self._layout_computed:
            raise RuntimeError("Call compute_layout() before allocate()")
        if self._smem_base is not None:
            return self._smem_base
        if self._total == 0 and self._barrier_bytes == 0:
            self._smem_base = None
            return None
        all_allocs = list(self._allocations)
        for grp in self._alias_groups:
            for ph in grp:
                for a in ph:
                    if a not in all_allocs:
                        all_allocs.append(a)
        block_align = max((self._alloc_alignment(a) for a in all_allocs), default=128)
        unified_bytes = (
            _align_up(self._total, _MBARRIER_ALIGNMENT) + self._barrier_bytes
        )
        self._smem_base = cutlass.Array(
            cutlass.Uint8,
            unified_bytes,
            space=cutlass.AddressSpace.smem,
            alignment=block_align,
        )
        return self._smem_base

    def assign_barrier_ptrs(self) -> None:
        """Pre-assign barrier storage within the unified SMEM block.

        For each resource that needs pipeline barriers, creates a
        ``cute.Pointer`` into the barrier region (after data) and
        replaces the resource's ``PipelineConfig`` with one that has
        ``barrier_ptr`` set.  This prevents ``create_pipeline()`` from
        allocating barrier SMEM separately.

        Also handles ``PipelineGroup`` entries registered via
        ``add_pipeline_group()``.  Each group receives a single
        pointer spanning ``(N + 1) × S`` barrier entries.

        Must be called after ``allocate()`` at DSL-trace time.
        """
        if self._smem_base is None:
            return
        if not self._barrier_resources and not self._barrier_groups:
            return
        barrier_offset = _align_up(self._total, _MBARRIER_ALIGNMENT)
        for resource in self._barrier_resources:
            pcfg = resource.pipeline_config
            barrier_offset = _align_up(barrier_offset, _MBARRIER_ALIGNMENT)
            if pcfg.barrier_ptr is None:
                ptr = cute.make_ptr(
                    cutlass.Int64,
                    self._smem_base.data_ptr() + barrier_offset,
                    mem_space=cutlass.AddressSpace.smem,
                )
                resource.pipeline_config = replace(pcfg, barrier_ptr=ptr)
            barrier_offset += pcfg.num_stages * _MBARRIER_BYTES_PER_STAGE
        for group in self._barrier_groups:
            gcfg = group.pipeline_config
            S = gcfg.num_stages
            barrier_offset = _align_up(barrier_offset, _MBARRIER_ALIGNMENT)
            if gcfg.barrier_ptr is None:
                ptr = cute.make_ptr(
                    cutlass.Int64,
                    self._smem_base.data_ptr() + barrier_offset,
                    mem_space=cutlass.AddressSpace.smem,
                )
                group.pipeline_config = replace(gcfg, barrier_ptr=ptr)
            barrier_offset += (
                group.num_barriers_per_stage * S * _MBARRIER_BYTES_PER_STAGE
            )


class TmemAllocator(_LayoutAllocator):
    """TMEM column layout allocator (no hardware allocation).

    Collects ``TmemAllocation`` objects and computes column offsets.
    Does **not** emit any allocation intrinsics — the kernel calls
    ``nvvm.tcgen05_alloc`` manually using ``total_tmem_columns``.

    Example::

        tmem_alloc = TmemAllocator()
        tmem_alloc.add_resource(tmem_c_resource)
        tmem_alloc.compute_layout()
        num_cols = tmem_alloc.total_tmem_columns  # pass to tcgen05_alloc
    """

    def _alloc_size(self, alloc: TmemAllocation) -> int:
        return alloc.num_columns

    def _get_requirements(self, resource: Any) -> List[TmemAllocation]:
        return resource.get_tmem_requirements()

    @property
    def total_tmem_columns(self) -> int:
        """Total TMEM columns required (available after ``compute_layout()``)."""
        return self.total

    def _unit_label(self) -> str:
        return "cols"

    def _report_tag(self) -> str:
        return "tmem-layout"

    def _report_title(self) -> str:
        return "TMEM Usage Report"


# Each mbarrier occupies a single Int64 slot (8 bytes).
_BARRIER_DTYPE = cutlass.Int64
_BARRIER_BYTES = _BARRIER_DTYPE.width // 8


@dataclass
class BarrierAllocation:
    """Declares a contiguous run of mbarriers sharing an initialization count.

    Attributes
    ----------
    name : str
        Human-readable label for debugging / usage reports.
    num_barriers : int
        Number of mbarriers in this run (typically ``num_stages``).
    arrive_count : Union[int, Int32]
        Arrival count every barrier in the run is initialized with.  A Python
        ``int`` lets :class:`BarrierAllocator` merge equal-count runs into a
        single init bucket; a dynamic ``Int32`` is supported too but each such
        run forms its own bucket.
    mbarrier_layout : MbarrierLayout
        Hardware mbarrier layout.  Runs of different layouts are never mixed
        within a single vectorized init round; :class:`BarrierAllocator` keeps
        each layout in its own ``WARP_SIZE``-aligned region.
    offset : int
        Element (mbarrier) offset from the base of the coalesced barrier
        array, set by ``BarrierAllocator.compute_layout()``.
    """

    name: str
    num_barriers: int
    arrive_count: Union[int, Int32]
    mbarrier_layout: MbarrierLayout = MbarrierLayout.V0
    offset: int = field(init=False, default=0)

    def __post_init__(self) -> None:
        if self.num_barriers <= 0:
            raise ValueError(
                f"BarrierAllocation '{self.name}' num_barriers must be > 0, "
                f"got {self.num_barriers}"
            )
        # Only static counts can be validated at compile time.
        if isinstance(self.arrive_count, int):
            if self.arrive_count <= 0:
                raise ValueError(
                    f"BarrierAllocation '{self.name}' arrive_count must be > 0, "
                    f"got {self.arrive_count}"
                )
    @classmethod
    def from_group(
        cls,
        name: str,
        num_barriers: int,
        group: CooperativeGroup,
        mbarrier_layout: MbarrierLayout = MbarrierLayout.V0,
    ) -> "BarrierAllocation":
        """Create an allocation whose ``arrive_count`` is derived from a group.
        """
        arrive_count = _get_thread_arrive_count(group)
        return cls(name, num_barriers, arrive_count, mbarrier_layout)


@dataclass
class _BarrierInitGroup:
    """Group of mbarriers that can be initialized together.

    Attributes
    ----------
    mbarrier_layout : MbarrierLayout
        Layout shared by every run in this region.
    start : int
        Offset of the region's first mbarrier, a multiple of ``WARP_SIZE``.
    padded_len : int
        Region length in number of mbarriers, padded to ``WARP_SIZE``.
    buckets : List[Tuple[Union[int, Int32], int]]
        ``(arrive_count, absolute_upper_index)`` pairs.
        ``absolute_upper_index`` is the exclusive upper bound, in mbarrier
        elements from the array base, of the bucket.
    """

    mbarrier_layout: MbarrierLayout
    start: int
    padded_len: int
    buckets: List[Tuple[Union[int, Int32], int]]


class BarrierAllocator:
    """Barrier array allocator.

    Collects ``BarrierAllocation`` objects and computes the offsets within a
    coalesced barrier array. Initializes the array efficiently (vectorized).

    Example::

        barrier_allocator = BarrierAllocator()
        barrier_allocator.add_resource(resource)
        barrier_allocator.compute_layout()
        barrier_allocator.set_backing(smem_allocator)

        # In TaskManager:
        barrier_allocator.allocate()
        barrier_allocator.initialize()
    """

    def __init__(self, init_warp_idx: int = 0) -> None:
        if init_warp_idx < 0:
            raise ValueError(
                f"BarrierAllocator init_warp_idx must be >= 0, "
                f"got {init_warp_idx}"
            )
        self.init_warp_idx = init_warp_idx
        self._by_name: "dict[str, BarrierAllocation]" = {}
        self._layout_computed: bool = False
        self._groups: List[_BarrierInitGroup] = []
        self._used: int = 0
        self._padded: int = 0
        self._base_ptr: Optional[cute.Pointer] = None
        self._allocated: bool = False
        self._smem_alloc: Optional[SmemAllocation] = None
        self._smem_allocator: Optional[SmemAllocator] = None
        self._pipeline_resources: List[Any] = []

    # -- Declaration ----------------------------------------------------------

    def set_backing(
        self,
        smem_allocator: SmemAllocator,
        smem_allocation: Optional[SmemAllocation] = None,
        name: str = "coalesced_barriers",
        register: bool = True,
    ) -> SmemAllocation:
        """Back the coalesced barrier array with an SMEM allocation.

        By default, :meth:`allocate` emits its own ``cutlass.Array`` for the
        mbarriers, producing a second SMEM symbol that is invisible to
        ``smem_allocator``'s accounting.  Calling this instead reserves
        the barrier storage inside ``smem_allocator``'s unified block.

        There are two ways of using this method:
          * Pre-reserve an allocation larger than necessary by passing a
            custom ``SmemAllocation`` (to avoid circular dependencies).
          * Let this method create a fresh allocation. Requires running
            :meth:`compute_layout` first to know the size.

        Parameters
        ----------
        smem_allocator : SmemAllocator
            Allocator whose unified block will host the barrier array.
        smem_allocation : SmemAllocation or None, optional
            When ``None``, an appropriately-sized allocation is created.
            When provided, it must be large enough to hold the barrier array.
        name : str
            Name for the auto-created allocation if applicable.
        register : bool
            Whether to add the allocation to ``smem_allocator``.
            When ``False``, assume the caller already registered it.

        Returns
        -------
        SmemAllocation
            The backing allocation.
        """
        if register and smem_allocator.layout_computed:
            raise RuntimeError(
                "smem_allocator.compute_layout() already called"
            )
        if smem_allocation is None:
            if not register:
                raise ValueError(
                    "register=False but no allocation was provided."
                )
            if not self._layout_computed:
                raise RuntimeError(
                    "Call compute_layout() before set_backing(), or provide "
                    "a sufficiently-sized SmemAllocation."
                )
            smem_allocation = SmemAllocation(
                name=name,
                size_bytes=self.padded_size_bytes,
                alignment=_MBARRIER_ALIGNMENT,
            )
        if register:
            smem_allocator.add(smem_allocation)
        self._smem_alloc = smem_allocation
        self._smem_allocator = smem_allocator
        return smem_allocation

    def add(self, alloc: BarrierAllocation) -> BarrierAllocation:
        """Register a single barrier run.
        """
        if self._layout_computed:
            raise RuntimeError("Cannot add() after compute_layout()")
        if alloc.name in self._by_name:
            raise ValueError(
                f"Barrier name '{alloc.name}' is already used."
            )
        self._by_name[alloc.name] = alloc
        return alloc

    def add_producer_consumer(
        self,
        name: str,
        num_stages: int,
        producer_group: CooperativeGroup,
        consumer_group: CooperativeGroup,
        mbarrier_layout: MbarrierLayout = MbarrierLayout.V0,
    ) -> Tuple[BarrierAllocation, BarrierAllocation]:
        """Register ``full``/``empty`` barrier pair explicitly.

        Lower-level counterpart to :meth:`add_pipeline`: takes the producer /
        consumer cooperative groups directly instead of reading them off a
        :class:`PipelineConfig`.  Returns the ``(full, empty)`` allocations.
        """
        full = self.add(
            BarrierAllocation.from_group(
                f"{name}.full", num_stages, producer_group, mbarrier_layout
            )
        )
        empty = self.add(
            BarrierAllocation.from_group(
                f"{name}.empty", num_stages, consumer_group, mbarrier_layout
            )
        )
        return full, empty

    def add_resource(self, resource: Any) -> None:
        """Register a pipeline resource's ``full``/``empty`` barriers.

        The barrier names are derived from the resource's ``name`` as
        ``{name}.full`` and ``{name}.empty``; the ``num_stages``, cooperative
        groups and mbarrier layouts come from ``resource.pipeline_config``.

        Parameters
        ----------
        resource : Any
            A ``MemoryResource`` with a ``name`` and ``pipeline_config``.
        """
        # No-op if resource is already registered.
        for res in self._pipeline_resources:
            if res is resource:
                return
        name = getattr(resource, "name", "")
        if not name:
            raise ValueError(
                "add_resource() requires a non-empty resource name."
            )
        config = getattr(resource, "pipeline_config", None)
        if config is None:
            raise ValueError(
                f"add_resource() requires resource '{name}' to have a "
                "pipeline_config."
            )
        if config.barrier_ptr is not None:
            raise ValueError(
                f"Resource '{name}' has a pre-supplied pipeline_config."
                "barrier_ptr; it cannot both self-allocate its barriers and "
                "be registered with the BarrierAllocator."
            )
        for key, group, layout in (
            (f"{name}.full", config.producer_group,
             config.full_mbarrier_layout),
            (f"{name}.empty", config.consumer_group,
             config.empty_mbarrier_layout),
        ):
            if key in self._by_name:
                raise ValueError(
                    f"Barrier name '{key}' for resource '{name}' collides with "
                    "an existing barrier; resource names must be unique."
                )
            self.add(
                BarrierAllocation(
                    key,
                    config.num_stages,
                    _get_thread_arrive_count(group),
                    layout,
                )
            )
        self._pipeline_resources.append(resource)

    def owns_resource(self, resource: Any) -> bool:
        """Whether *resource* was registered via :meth:`add_resource`."""
        return any(existing is resource for existing in self._pipeline_resources)

    @property
    def pipeline_resources(self) -> List[Any]:
        """Resources registered via :meth:`add_resource`, in registration order."""
        return self._pipeline_resources

    def validate_barrier_ownership(self, smem_allocator: "SmemAllocator") -> None:
        """Ensure no resource's barriers are owned by both allocators."""
        smem_owned = set(map(id, smem_allocator.barrier_resources))
        conflicts = [
            getattr(res, "name", repr(res))
            for res in self._pipeline_resources
            if id(res) in smem_owned
        ]
        if conflicts:
            raise ValueError(
                "Barriers are owned by both the SMEM allocator and the barrier "
                f"allocator for resource(s): {conflicts}. Pass "
                "add_barriers=False to SmemAllocator.add_resource() for these."
            )

    def add_pipeline_group(
        self,
        name: str,
        group: Any,
    ) -> Tuple[List[BarrierAllocation], List[BarrierAllocation]]:
        """Register a ``PipelineGroup``'s barriers.

        A group shares barriers on a collapsed side and keeps per-member
        barriers on a "many" side::

            Merge (N producers → 1 consumer):
                [full_0 × S] … [full_{N-1} × S] [shared_empty × S]
            Fork  (1 producer → N consumers):
                [shared_full × S] [empty_0 × S] … [empty_{N-1} × S]
            FusedMerge (N producers → 1 consumer):
                [shared_full × S] [shared_empty × S]

        Every barrier is registered independently so the allocator is free to
        place them in separate arrive-count buckets; the group later reads each
        offset back via :meth:`PipelineGroup.assign_coalesced_barriers` and
        builds its sync objects with ``defer_init=True``.

        Parameters
        ----------
        name : str
            Label prefix for the registered barriers.
        group : PipelineGroup
            A ``Merge``, ``Fork``, or ``FusedMerge`` group whose members each
            expose a ``pipeline_config``.

        Returns
        -------
        Tuple[List[BarrierAllocation], List[BarrierAllocation]]
            The ``(full, empty)`` barrier allocations.  On the "many" side
            there is one per member (in member order); on the collapsed
            side there is a single shared allocation.
        """
        from .enums import PipelineGroupMode

        group_cfg = group.pipeline_config
        if group_cfg is None:
            raise ValueError(f"PipelineGroup '{name}' has no pipeline_config.")
        num_stages = group_cfg.num_stages

        def _member_cfg(member: Any) -> Any:
            cfg = member.pipeline_config
            if cfg is None:
                raise ValueError(
                    f"PipelineGroup '{name}' member '{member.name}' has no "
                    f"pipeline_config."
                )
            return cfg
        
        if group.mode == PipelineGroupMode.Merge:
            # Per-member full + one shared empty.
            full_items = [
                (f"{name}.{m.name}.full", _member_cfg(m)) for m in group.members
            ]
            empty_items = [(f"{name}.empty", group_cfg)]
        elif group.mode == PipelineGroupMode.Fork:
            # One shared full + per-member empty.
            full_items = [(f"{name}.full", group_cfg)]
            empty_items = [
                (f"{name}.{m.name}.empty", _member_cfg(m)) for m in group.members
            ]
        elif group.mode == PipelineGroupMode.FusedMerge:
            # One shared full + one shared empty.
            full_items = [(f"{name}.full", group_cfg)]
            empty_items = [(f"{name}.empty", group_cfg)]
        else:
            raise ValueError(
                f"add_pipeline_group() got unsupported group mode "
                f"{group.mode!r} for '{name}'."
            )

        full = [
            self.add(
                BarrierAllocation.from_group(
                    key,
                    num_stages,
                    cfg.producer_group,
                    cfg.full_mbarrier_layout,
                )
            )
            for key, cfg in full_items
        ]
        empty = [
            self.add(
                BarrierAllocation.from_group(
                    key,
                    num_stages,
                    cfg.consumer_group,
                    cfg.empty_mbarrier_layout,
                )
            )
            for key, cfg in empty_items
        ]

        # Record the barrier keys on the group so ``assign()`` can later
        # resolve them to offsets and drive ``assign_coalesced_barriers`` —
        # removing the need for the kernel to wire offsets manually.
        group._coalesced_full_keys = [b.name for b in full]
        group._coalesced_empty_keys = [b.name for b in empty]
        return full, empty

    # -- Layout ---------------------------------------------------------------

    def compute_layout(self) -> None:
        """Group by init compatibility, bucket by arrive count, assign offsets.
        """
        if self._layout_computed:
            raise RuntimeError("compute_layout() already called")

        # Partition by layout, preserving first-seen order for determinism.
        # Note: as of Python 3.7, dicts preserve insertion order.
        by_layout: dict = {}
        for alloc in self._by_name.values():
            by_layout.setdefault(alloc.mbarrier_layout, []).append(alloc)

        cursor = 0
        used = 0
        groups: List[_BarrierInitGroup] = []
        for layout, allocs in by_layout.items():
            region_start = cursor
            # Static counts can be merged/sorted; dynamic Int32 counts cannot be
            # compared at trace time, so each forms its own bucket.
            static_by_count: dict = {}
            dynamic_allocs: List[BarrierAllocation] = []
            for alloc in allocs:
                if isinstance(alloc.arrive_count, int):
                    static_by_count.setdefault(alloc.arrive_count, []).append(
                        alloc
                    )
                else:
                    dynamic_allocs.append(alloc)

            buckets: List[Tuple[Union[int, Int32], int]] = []
            # Static buckets first, ascending by arrive count, for a
            # deterministic layout.  ``_select_arrive_count`` only relies on the
            # upper *index* thresholds being ascending, with no ordering
            # assumption on the arrive counts.
            for arrive_count in sorted(static_by_count):
                for alloc in static_by_count[arrive_count]:
                    alloc.offset = cursor
                    cursor += alloc.num_barriers
                buckets.append((arrive_count, cursor))
            # Dynamic buckets next, one per run, in registration order.
            for alloc in dynamic_allocs:
                alloc.offset = cursor
                cursor += alloc.num_barriers
                buckets.append((alloc.arrive_count, cursor))

            used += cursor - region_start
            # Pad the region (not just the grand total) to a whole number of
            # rounds so the next layout starts on a WARP_SIZE boundary.
            cursor = _align_up(cursor, WARP_SIZE)
            groups.append(
                _BarrierInitGroup(
                    mbarrier_layout=layout,
                    start=region_start,
                    padded_len=cursor - region_start,
                    buckets=buckets,
                )
            )

        self._used = used
        self._padded = cursor
        self._groups = groups
        self._layout_computed = True

    @property
    def layout_computed(self) -> bool:
        """Whether :meth:`compute_layout` has already run."""
        return self._layout_computed

    @property
    def padded_size_bytes(self) -> int:
        """Padded size in bytes."""
        if not self._layout_computed:
            raise RuntimeError("Call compute_layout() first")
        return self._padded * _BARRIER_BYTES

    # -- Allocation / initialization (DSL-trace time) -------------------------

    def allocate(self) -> Optional[cute.Pointer]:
        """Emit the base pointer of the mbarrier array.

        If :meth:`set_backing` was called, the barrier array is carved out of
        the ``SmemAllocator``'s already-materialized unified block.
        Otherwise, emits a standalone ``cutlass.Array`` of mbarriers.

        Must be called at DSL-trace time.  Idempotent: repeated calls return the
        pointer resolved by the first call without allocating again.  Returns
        ``None`` when no barriers were registered.
        """
        if not self._layout_computed:
            raise RuntimeError("Call compute_layout() before allocate()")
        if self._allocated:
            return self._base_ptr
        self._allocated = True
        if self._padded == 0:
            self._base_ptr = None
            return None
        if self._smem_alloc is not None:
            # Point into the SmemAllocator's unified block.  Its ``allocate()``
            # must already have run (TaskManager guarantees this ordering).
            assert self._smem_allocator is not None, "SmemAllocator not set"
            if self.padded_size_bytes > self._smem_alloc.size_bytes:
                raise RuntimeError(
                    f"Backing allocation '{self._smem_alloc.name}' has "
                    f"{self._smem_alloc.size_bytes} B but barriers need "
                    f"{self.padded_size_bytes} B."
                )
            smem_base = self._smem_allocator.smem_base
            if smem_base is None:
                raise RuntimeError(
                    "set_backing(): SmemAllocator.allocate() must run "
                    "before the barrier allocator's allocate()."
                )
            self._base_ptr = cute.make_ptr(
                _BARRIER_DTYPE,
                smem_base.data_ptr() + self._smem_alloc.offset,
                mem_space=cutlass.AddressSpace.smem,
            )
            return self._base_ptr
        barrier_array: cutlass.Array = cutlass.Array(
            _BARRIER_DTYPE,
            self._padded,
            space=cutlass.AddressSpace.smem,
            alignment=_BARRIER_BYTES,
        )
        self._base_ptr = cute.make_ptr(
            _BARRIER_DTYPE,
            barrier_array.data_ptr(),
            mem_space=cutlass.AddressSpace.smem,
        )
        return self._base_ptr

    @property
    def is_allocated(self) -> bool:
        """Whether :meth:`allocate` has already emitted the barrier array."""
        return self._allocated

    @property
    def base_ptr(self) -> Optional[cute.Pointer]:
        """Base pointer of the coalesced barrier array (``None`` if empty)."""
        return self._base_ptr

    # -- Key resolution -------------------------------------------------------

    def offset_of(self, name: str) -> int:
        """Return the array offset (in mbarrier slots) of key ``name``.
        """
        if not self._layout_computed:
            raise RuntimeError("Call compute_layout() before offset_of()")
        alloc = self._by_name.get(name)
        if alloc is None:
            raise KeyError(f"No barrier named '{name}' was registered.")
        return alloc.offset

    def resolve(self, name: str) -> Tuple[cute.Pointer, int]:
        """Return ``(base_ptr, offset)`` for the barrier with key ``name``.

        Must be called after :meth:`allocate`.
        """
        if self._base_ptr is None:
            raise RuntimeError("Call allocate() before resolve().")
        return self._base_ptr, self.offset_of(name)

    def get_ptr(self, name: str) -> cute.Pointer:
        """Return the base pointer of the barrier with key ``name``.

        Must be called after :meth:`allocate`.
        """
        ptr, offset = self.resolve(name)
        return ptr + offset

    @staticmethod
    def _buckets_for_round(
        buckets: List[Tuple[Union[int, Int32], int]],
        round_lo: int,
    ) -> List[Tuple[Union[int, Int32], int]]:
        """Slice ``buckets`` to those overlapping ``[round_lo, round_lo+WARP_SIZE)``.

        * Buckets ending at or before ``round_lo`` are dropped.
        * The first bucket reaching ``round_lo + WARP_SIZE`` covers the whole
          tail of the round, so later buckets are irrelevant.
        """
        round_hi = round_lo + WARP_SIZE
        result: List[Tuple[Union[int, Int32], int]] = []
        for arrive_count, upper in buckets:
            if upper <= round_lo:
                continue
            result.append((arrive_count, upper))
            if upper >= round_hi:
                break
        if not result:
            result = [buckets[-1]]
        return result

    def _select_arrive_count(
        self,
        idx: Int32,
        buckets: List[Tuple[Union[int, Int32], int]],
    ) -> Int32:
        """Build the per-lane arrive count for barrier ``idx`` (dynamic Int32).

        Emits a chain of selects over the region's static bucket thresholds:
        ``idx < t0 ? a0 : (idx < t1 ? a1 : ... : a_last)``.
        """
        # Default to the last bucket's arrive count (covers the highest
        # indices in the region, including padding).
        arrive: Int32 = Int32(buckets[-1][0])
        # Walk earlier buckets in reverse so smaller-index thresholds take
        # precedence through the nested selects.
        for arrive_count, upper in reversed(buckets[:-1]):
            arrive = cast(
                Int32,
                if_generate(
                    idx < upper,
                    lambda a, v=arrive_count: Int32(v),
                    input_args=[arrive],  # type: ignore[list-item]
                    return_types=[Int32],
                ),
            )
        return arrive

    def initialize(self) -> None:
        """Vectorized initialization of all barriers.

        Must be called after ``allocate()`` and before the barrier initialization
        fence + sync. Only the allocator's initializer warp participates; each
        of its 32 lanes initializes one barrier per round.
        """
        if not self._layout_computed:
            raise RuntimeError("Call compute_layout() before initialize()")
        if self._base_ptr is None:
            raise RuntimeError("No barrier storage: call allocate() first.")
        if self._padded == 0:
            return

        base_ptr = self._base_ptr
        # Reuse the linear thread index for both values. Reading %laneid
        # separately adds a high-latency S2R to the barrier-init prologue.
        linear_thread_idx = cute.arch.linear_thread_idx()
        lane = linear_thread_idx & (WARP_SIZE - 1)
        current_warp_idx = cute.arch.make_warp_uniform(
            linear_thread_idx // WARP_SIZE
        )

        def then_body() -> None:
            # Vectorized init is only supported on Blackwell and later.
            use_vectorized_mbarrier_init = (
                cutlass.target_version(min_version="12.9")
                and CuTeDSL._get_dsl().get_arch_enum() >= base_dsl.Arch.sm_100
            )
            if use_vectorized_mbarrier_init:
                # Vectorized init.
                # 32 lanes of a warp each initialize one barrier per round.
                for group in self._groups:
                    init_fn = cute.arch.mbarrier_init
                    num_rounds = group.padded_len // WARP_SIZE
                    for r in range(num_rounds):
                        round_lo = group.start + r * WARP_SIZE
                        round_buckets = self._buckets_for_round(
                            group.buckets, round_lo
                        )
                        idx = round_lo + lane
                        arrive = self._select_arrive_count(idx, round_buckets)
                        init_fn(base_ptr + idx, arrive)
            else:
                # Fallback.
                # A single elected lane walks every barrier sequentially.
                with cute.arch.elect_one():
                    for group in self._groups:
                        init_fn = cute.arch.mbarrier_init
                        lower = group.start
                        for arrive_count, upper in group.buckets:
                            for idx in range(lower, upper):
                                init_fn(base_ptr + idx, Int32(arrive_count))
                            lower = upper

        if_generate(current_warp_idx == self.init_warp_idx, then_body)

    # -- Usage report ---------------------------------------------------------

    def print_usage_report(self) -> None:
        """Print a table of barrier runs, buckets, and padding."""
        if not self._layout_computed:
            raise RuntimeError("Call compute_layout() before print_usage_report()")

        print("\n[barrier-layout] Barrier Usage Report")
        hdr = (
            f"  {'Name':<28} {'Layout':>7} {'Count':>6}  "
            f"{'Arrive':>7}  {'Offset':>7}  {'End':>4}"
        )
        print(hdr)
        print(f"  {'─' * (len(hdr) - 2)}")
        for alloc in sorted(self._by_name.values(), key=lambda a: a.offset):
            end = alloc.offset + alloc.num_barriers
            arrive_str = (
                str(alloc.arrive_count)
                if isinstance(alloc.arrive_count, int)
                else "dynamic"
            )
            print(
                f"  {alloc.name:<28} {alloc.mbarrier_layout.name:>7} "
                f"{alloc.num_barriers:>6}  {arrive_str:>7}  "
                f"{alloc.offset:>7}  {end:>4}"
            )
        print(f"  {'─' * (len(hdr) - 2)}")
        for group in self._groups:
            region_end = group.start + group.padded_len
            print(
                f"  Region {group.mbarrier_layout.name}: "
                f"offsets {group.start}..{region_end} "
                f"({group.padded_len} padded slots)"
            )
            lower = group.start
            for arrive_count, upper in group.buckets:
                arrive_str = (
                    str(arrive_count)
                    if isinstance(arrive_count, int)
                    else "dynamic"
                )
                print(
                    f"    [{lower:>3},{upper:>3}): arrive={arrive_str:<6}"
                )
                lower = upper
        print(f"  Used barriers: {self._used:>3}")
        print(f"  Padded total:  {self._padded:>3}")
        print()
