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
    Describe named SMEM (byte) or TMEM (column) regions.  After
    ``compute_layout()``, the ``.offset`` field contains the offset
    from the base of the unified block.

    ``SmemAllocation`` accepts an optional ``dtype`` and ``count``.
    When ``dtype`` is provided without explicit ``size_bytes``, the
    size is auto-computed as ``count * dtype.width // 8``.  The stored
    dtype enables ``SmemAllocator.get()`` to return a typed array
    without re-specifying the element type.

ResourceContext
    Frozen context object embedded in ``StageInfo``.  Carries ``smem_base`` and
    ``tmem_ptr_i32``.

_LayoutAllocator
    Base class with common declaration and layout logic.

SmemAllocator / TmemAllocator
    Concrete allocators for SMEM bytes (with alignment) and TMEM
    columns (no alignment).  ``SmemAllocator`` can also emit a single
    ``cutlass.Array(..., space=cutlass.AddressSpace.smem)`` call at DSL-trace time.
"""

from dataclasses import dataclass, field, replace
from typing import Any, List, Optional

import cutlass
import cutlass.cute as cute


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

    def __init__(self) -> None:
        super().__init__()
        self._smem_base: Optional[Any] = None
        self._barrier_bytes: int = 0
        self._barrier_resources: List[Any] = []
        self._barrier_groups: List[Any] = []
        self._tmem_ptr_alloc: Optional[SmemAllocation] = None

    def _alloc_size(self, alloc: SmemAllocation) -> int:
        return alloc.size_bytes

    def _alloc_alignment(self, alloc: SmemAllocation) -> int:
        return alloc.alignment

    def _get_requirements(self, resource: Any) -> List[SmemAllocation]:
        return resource.get_smem_requirements()

    def add_resource(self, resource: Any) -> None:
        """Register data allocations and accumulate barrier SMEM.

        Parameters
        ----------
        resource : Any
            Resource exposing ``get_smem_requirements()`` and, optionally,
            a ``pipeline_config`` whose barrier storage should be placed in the
            unified SMEM block.

        Notes
        -----
        Resources that belong to a ``PipelineGroup`` (i.e.
        ``resource.pipeline_group is not None``) have their barrier
        SMEM managed by the group, so individual barrier accounting
        is skipped.  Call ``add_pipeline_group()`` to register the
        group's barrier requirements instead.
        """
        super().add_resource(resource)
        pg = getattr(resource, "pipeline_group", None)
        cfg = getattr(resource, "pipeline_config", None)
        if cfg is not None and cfg.barrier_ptr is None and pg is None:
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
