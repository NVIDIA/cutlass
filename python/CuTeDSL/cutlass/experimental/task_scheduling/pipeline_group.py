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

"""PipelineGroup — shared pipeline barriers for fork/merge dataflow patterns.

``PipelineGroup`` is a ``MemoryResource`` subclass (``is_barrier=True``)
that groups multiple data resources (members) under a shared set of
pipeline barriers.  It enables:

- **Merge** (N producers → 1 consumer): multiple producers each fill
  their own member; one consumer waits for all of them.
- **Fork** (1 producer → N consumers): one producer fills all members;
  multiple consumers each read their own member.

Barrier Layout (Heterogeneous)
------------------------------
For N members with S pipeline stages::

    [full_0 × S] [full_1 × S] … [full_{N-1} × S] [shared_empty × S]
    Total entries: (N + 1) × S

Each member's pipeline object receives a pointer to its dedicated full
barrier section and the shared empty barrier.

Allowed Pipeline Types
----------------------
All six public ``PipelineType`` values are supported:

===================  ========  ========  =======================
PipelineType         Producer  Consumer  Pipeline class
===================  ========  ========  =======================
AsyncAsync           async     async     ``PipelineAsync``
TmaAsync             tma       async     ``PipelineTmaAsync``
TmaUmma              tma       umma      ``PipelineTmaUmma``
UmmaAsync            umma      async     ``PipelineUmmaAsync``
AsyncUmma            async     umma      ``TSPipelineAsyncUmma``
UmmaUmma             umma      umma      ``TSPipelineUmmaUmma``
===================  ========  ========  =======================

Valid heterogeneous merge pairs (consumer side homogeneous):

- Consumer = ``async``: AsyncAsync + TmaAsync, AsyncAsync + UmmaAsync,
  TmaAsync + UmmaAsync
- Consumer = ``umma``: TmaUmma + AsyncUmma, TmaUmma + UmmaUmma,
  AsyncUmma + UmmaUmma

Valid heterogeneous fork pairs (producer side homogeneous):

- Producer = ``tma``: TmaAsync + TmaUmma
- Producer = ``async``: AsyncAsync + AsyncUmma
- Producer = ``umma``: UmmaAsync + UmmaUmma

Producer / Consumer Decomposition
----------------------------------
The merge/fork topology is auto-derived from the kind decomposition:

- Producer kinds differ → **Merge**
- Consumer kinds differ → **Fork**
- Both homogeneous → uses explicit ``mode`` parameter
- Both differ → **Error**
"""

from dataclasses import dataclass, field
import cutlass.pipeline as pipeline
import cutlass.cute as cute
import cutlass
from typing import List, Optional, cast

from .resources import MemoryResource, PipelineConfig
from .enums import PipelineGroupMode, PipelineType
from . import pipeline as ts_pipeline


class _GroupMemberRef:
    """Lightweight wrapper identifying "access member *via* its group".

    Instances are produced only by ``PipelineGroup.__getattr__`` —
    writing ``ab_sync.smem_a`` returns a ``_GroupMemberRef`` bound to
    the group and the member resource.  The wrapper is consumed by
    :func:`normalize_and_validate_schedule_list` (in ``task.py``),
    which unwraps it to the underlying member while recording that
    the access was group-qualified.  This distinction lets the
    static checker enforce:

    - Merge groups: every member barrier op must go through the
      group; ``ConsumerRelease`` is additionally only legal at the
      group level (``(ab_sync, ConsumerRelease)``).
    - Fork groups: per-member ops go through ``group.member`` — the
      bare ``member`` is rejected.

    ``_GroupMemberRef`` is **only** valid inside ``schedule_list``
    entries; bare ``MemoryResource`` objects continue to live in
    ``src_resources`` / ``dst_resources`` (those describe data
    dependencies, independent of barrier identity).
    """

    __slots__ = ("group", "member")

    def __init__(self, group: "PipelineGroup", member: MemoryResource) -> None:
        self.group = group
        self.member = member

    def __repr__(self) -> str:  # pragma: no cover - debug aid
        return f"_GroupMemberRef({self.group.name}.{self.member.name})"


@dataclass(kw_only=True)
class PipelineGroup(MemoryResource):
    """Shared pipeline barriers derived by merging member pipeline configs.

    Each member declares its own ``pipeline_config`` exactly as it would for a
    standalone pipeline. The group validates those member configs and creates a
    shared barrier layout for the side driven by a single task:

    * ``Merge`` collapses the consumer side. Members commit individually, and
      the shared consumer task calls ``group.release()`` once.
    * ``Fork`` collapses the producer side. Members release individually, and
      the shared producer task calls ``group.commit()`` once.

    ``PipelineGroup``:

    1. Validates compatibility (same ``num_stages`` and compatible
       ``pipeline_type`` on the collapsed side).
    2. Derives a merged config from the member configs. The collapsed side's
       cooperative-group size must match across members; the many side keeps
       per-member barriers.
    3. Creates one shared pipeline with ``(N + 1) * num_stages`` barriers.
    4. Re-points each member at the shared barrier allocation.

    Raises ``ValueError`` if member configs are not mergeable.

    When an explicit ``pipeline_config`` is supplied by the caller it is
    validated against the members using the same mode-specific compatibility
    rules. When ``pipeline_config`` is ``None``, it is derived automatically.

    Attributes
    ----------
    members : List[MemoryResource]
        Data resources whose pipelines are merged into this group.
    mode : PipelineGroupMode
        ``Merge`` - N producers, 1 consumer; collapse the consumer side.
        ``Fork`` - 1 producer, N consumers; collapse the producer side.
    """

    members: List["MemoryResource"] = field(default_factory=list)
    mode: cutlass.Constexpr[PipelineGroupMode] = PipelineGroupMode.Merge

    def __post_init__(self) -> None:
        self.is_barrier = True
        if not self.members:
            raise ValueError("PipelineGroup requires at least one member.")
        for m in self.members:
            if m.pipeline_group is not None:
                raise ValueError(
                    f"Member '{m.name}' already belongs to a PipelineGroup."
                )
            m.pipeline_group = self
        if self.pipeline_config is None:
            self.pipeline_config = self._derive_merged_config()
        else:
            self._validate_explicit_config()
        # Pre-resolve the state source for Merge members so barrier ops
        # inside ``@cute.jit`` regions use a uniform attribute access
        # ``resource.state_src`` (see ``MemoryResource.state_src``).
        # Merge: all members share the group's canonical state.
        # Fork: members keep their own state (no override needed).
        # The canonical pipeline state for Merge members lives on the group
        # (``MemoryResource.state_src`` derives it from ``pipeline_group``);
        # Fork members keep their own state.
        if self.mode == PipelineGroupMode.Merge:
            for m in self.members:
                m._state_src_owner = self

    def __getattr__(self, item: str) -> "_GroupMemberRef":
        """Resolve ``group.<member_name>`` to a ``_GroupMemberRef``.

        The lookup uses each member's ``name`` field — e.g. a member
        constructed with ``name="smem_a"`` becomes accessible as
        ``group.smem_a``.  Callers therefore must give members Python-
        identifier names (snake_case by convention) matching how they
        want to reference the member in ``schedule_list`` entries.

        Only invoked when normal attribute lookup fails, so it does
        not shadow dataclass fields (``members``, ``mode``, ...) or
        inherited ``MemoryResource`` attributes.

        Raises ``AttributeError`` on unknown names so callers such
        as ``hasattr`` / ``getattr(..., default)`` still work.
        """
        members = self.__dict__.get("members")
        if members:
            for m in members:
                if getattr(m, "name", None) == item:
                    return _GroupMemberRef(self, m)
        raise AttributeError(
            f"{type(self).__name__!r} object has no attribute {item!r}"
        )

    @property
    def group_pipeline(self) -> cutlass.Constexpr:
        """Access the first member's pipeline for group-level ops.

        Group-level barrier operations (ConsumerRelease for Merge,
        ProducerCommit for Fork) need a pipeline object to call
        ``consumer_release`` / ``producer_commit``.  Instead of aliasing
        ``self.pipeline`` (which breaks under ``inject_leaves``), this
        property reads the first member's pipeline on demand.
        """
        return self.members[0].pipeline

    @property
    def is_heterogeneous(self) -> bool:
        """True when members have different pipeline types.

        Heterogeneous groups maintain per-member full barriers and a
        shared empty barrier, whereas homogeneous groups share a single
        merged pipeline across all members.
        """
        types = {
            m.pipeline_config.pipeline_type
            for m in self.members
            if m.pipeline_config is not None
        }
        return len(types) > 1

    # ── Config derivation / validation ────────────────────────────────

    def _derive_merged_config(self) -> PipelineConfig:
        """Derive a merged ``PipelineConfig`` from member configs."""
        cfgs = []
        for m in self.members:
            if m.pipeline_config is None:
                raise ValueError(
                    f"PipelineGroup member '{m.name}' has no pipeline_config."
                )
            cfgs.append(m.pipeline_config)

        ref = cfgs[0]
        for cfg in cfgs[1:]:
            if cfg.num_stages != ref.num_stages:
                raise ValueError(
                    "PipelineGroup members have mismatched num_stages: "
                    f"{ref.num_stages} vs {cfg.num_stages}."
                )
            if cfg.advance_on_wait != ref.advance_on_wait:
                raise ValueError(
                    "PipelineGroup members have mismatched advance_on_wait."
                )
            if cfg.interleave_strides != ref.interleave_strides:
                raise ValueError(
                    "PipelineGroup members have mismatched interleave_strides: "
                    f"{ref.interleave_strides} vs {cfg.interleave_strides}."
                )
            if cfg.cta_layout_vmnk != ref.cta_layout_vmnk:
                raise ValueError(
                    "PipelineGroup members have mismatched cta_layout_vmnk: "
                    f"{ref.cta_layout_vmnk} vs {cfg.cta_layout_vmnk}."
                )
            if cfg.num_bytes_per_warp_per_cta != ref.num_bytes_per_warp_per_cta:
                raise ValueError(
                    "PipelineGroup members have mismatched "
                    "num_bytes_per_warp_per_cta: "
                    f"{ref.num_bytes_per_warp_per_cta} vs "
                    f"{cfg.num_bytes_per_warp_per_cta}."
                )
            if cfg.mcast_mode_mn != ref.mcast_mode_mn:
                raise ValueError(
                    "PipelineGroup members have mismatched mcast_mode_mn: "
                    f"{ref.mcast_mode_mn} vs {cfg.mcast_mode_mn}."
                )

        all_bytes = [c.num_bytes for c in cfgs]

        # ── Allowed pipeline types ────────────────────────────────
        _ALLOWED_GROUP_TYPES = {
            PipelineType.AsyncAsync,
            PipelineType.TmaAsync,
            PipelineType.TmaUmma,
            PipelineType.UmmaAsync,
            PipelineType.AsyncUmma,
            PipelineType.UmmaUmma,
        }
        for cfg in cfgs:
            if cfg.pipeline_type not in _ALLOWED_GROUP_TYPES:
                raise ValueError(
                    f"PipelineGroup only supports "
                    f"{sorted(t.value for t in _ALLOWED_GROUP_TYPES)} "
                    f"pipeline types, got '{cfg.pipeline_type.value}'."
                )

        # ── Producer / consumer decomposition ─────────────────────
        # Each PipelineType is a (producer_kind, consumer_kind) pair.
        # Merge vs Fork is determined by which side is heterogeneous:
        #   producer kinds differ → Merge  (N producers, 1 consumer)
        #   consumer kinds differ → Fork   (1 producer, N consumers)
        #   both homogeneous      → use explicit self.mode
        #   both differ           → invalid
        _PRODUCER_KIND = {
            PipelineType.AsyncAsync: "async",
            PipelineType.TmaAsync: "tma",
            PipelineType.TmaUmma: "tma",
            PipelineType.UmmaAsync: "umma",
            PipelineType.AsyncUmma: "async",
            PipelineType.UmmaUmma: "umma",
        }
        _CONSUMER_KIND = {
            PipelineType.AsyncAsync: "async",
            PipelineType.TmaAsync: "async",
            PipelineType.TmaUmma: "umma",
            PipelineType.UmmaAsync: "async",
            PipelineType.AsyncUmma: "umma",
            PipelineType.UmmaUmma: "umma",
        }
        _KIND_TO_TYPE = {
            ("tma", "umma"): PipelineType.TmaUmma,
            ("async", "umma"): PipelineType.AsyncUmma,
            ("tma", "async"): PipelineType.TmaAsync,
            ("async", "async"): PipelineType.AsyncAsync,
            ("umma", "async"): PipelineType.UmmaAsync,
            ("umma", "umma"): PipelineType.UmmaUmma,
        }

        producer_kinds = {_PRODUCER_KIND[c.pipeline_type] for c in cfgs}
        consumer_kinds = {_CONSUMER_KIND[c.pipeline_type] for c in cfgs}

        if len(producer_kinds) > 1 and len(consumer_kinds) > 1:
            raise ValueError(
                "PipelineGroup members differ on both producer and "
                "consumer sides — cannot derive a merged pipeline_type. "
                f"Producer kinds: {producer_kinds}, "
                f"consumer kinds: {consumer_kinds}."
            )

        if len(producer_kinds) > 1:
            derived_mode = PipelineGroupMode.Merge
        elif len(consumer_kinds) > 1:
            derived_mode = PipelineGroupMode.Fork
        else:
            derived_mode = self.mode

        member_types = {c.pipeline_type for c in cfgs}
        if len(member_types) > 1 and self.mode != derived_mode:
            raise ValueError(
                f"PipelineGroup mode={self.mode.value} contradicts the "
                f"derived topology ({derived_mode.value}) from member "
                f"pipeline types."
            )

        # ── Cooperative-group size for shared vs per-member barriers ──
        #
        # Merge mode:
        #   shared = empty barrier (consumer side)
        #   per-member / homogeneous-shared = full barrier (producer side)
        #
        # The consumer side (shared empty) uses TMA-override logic:
        # when mixing TMA + non-TMA, pick the non-TMA consumer_group
        # (all threads) and force TmaAsync to also let all threads
        # arrive (is_signaling_thread=True in _build_member_pipeline).
        #
        # The producer side (full barrier) is always SUMMED because
        # in the homogeneous path both producers commit to the same
        # barrier.  In the heterogeneous path each member uses its
        # own per-member config, so the merged value is unused.
        #
        # Fork mode is symmetric: producer side uses TMA-override,
        # consumer side is summed.
        _TMA_TYPES = {PipelineType.TmaAsync, PipelineType.TmaUmma}

        if derived_mode == PipelineGroupMode.Merge:
            tma_cfgs = [c for c in cfgs if c.pipeline_type in _TMA_TYPES]
            non_tma_cfgs = [c for c in cfgs if c.pipeline_type not in _TMA_TYPES]
            if tma_cfgs and non_tma_cfgs:
                sizes = {c.consumer_group.size for c in non_tma_cfgs}
                if len(sizes) != 1:
                    raise ValueError(
                        f"Non-TMA Merge members have different "
                        f"consumer_group.size: {sizes}."
                    )
                merged_cons_size = sizes.pop()
            else:
                sizes = {c.consumer_group.size for c in cfgs}
                if len(sizes) != 1:
                    raise ValueError(
                        f"Merge members have different consumer_group.size: {sizes}."
                    )
                merged_cons_size = sizes.pop()
            merged_prod_size = sum(c.producer_group.size for c in cfgs)
        else:
            tma_cfgs = [c for c in cfgs if c.pipeline_type in _TMA_TYPES]
            non_tma_cfgs = [c for c in cfgs if c.pipeline_type not in _TMA_TYPES]
            if tma_cfgs and non_tma_cfgs:
                sizes = {c.producer_group.size for c in non_tma_cfgs}
                if len(sizes) != 1:
                    raise ValueError(
                        f"Non-TMA Fork members have different "
                        f"producer_group.size: {sizes}."
                    )
                merged_prod_size = sizes.pop()
            else:
                sizes = {c.producer_group.size for c in cfgs}
                if len(sizes) != 1:
                    raise ValueError(
                        f"Fork members have different producer_group.size: {sizes}."
                    )
                merged_prod_size = sizes.pop()
            merged_cons_size = sum(c.consumer_group.size for c in cfgs)

        merged_producer_group = pipeline.CooperativeGroup(
            ref.producer_group.agent,
            size=merged_prod_size,
        )
        merged_consumer_group = pipeline.CooperativeGroup(
            ref.consumer_group.agent,
            size=merged_cons_size,
        )

        # ── Derive merged pipeline_type ───────────────────────────
        # For heterogeneous groups one side (producer or consumer)
        # differs across members.  The merged type only needs to
        # accurately represent the *homogeneous* side because that
        # determines the shared barrier's semantics:
        #   Merge → shared empty  → consumer kind matters
        #   Fork  → shared full   → producer kind matters
        # The varying side is set to "async" as a placeholder —
        # each member's real pipeline type drives
        # _build_member_pipeline() independently.
        if len(member_types) == 1:
            merged_pipeline_type = ref.pipeline_type
        elif derived_mode == PipelineGroupMode.Merge:
            merged_pipeline_type = _KIND_TO_TYPE[("async", consumer_kinds.pop())]
        else:
            merged_pipeline_type = _KIND_TO_TYPE[(producer_kinds.pop(), "async")]

        # Merge: per-member full barriers each armed with own num_bytes.
        #        Merged value = sum (for shared empty, which ignores it).
        # Fork:  one shared full barrier, producer loads data once.
        #        All members must have the same num_bytes.
        if derived_mode == PipelineGroupMode.Fork:
            byte_set = set(all_bytes)
            if len(byte_set) != 1:
                raise ValueError(
                    f"Fork members must have the same num_bytes (one "
                    f"producer loads data once), got: {all_bytes}."
                )
            merged_bytes = byte_set.pop()
        else:
            merged_bytes = sum(all_bytes)

        return PipelineConfig(
            num_stages=ref.num_stages,
            num_bytes=merged_bytes,
            producer_group=merged_producer_group,
            consumer_group=merged_consumer_group,
            pipeline_type=merged_pipeline_type,
            barrier_ptr=ref.barrier_ptr,
            cta_layout_vmnk=ref.cta_layout_vmnk,
            producer_signaling_threads=ref.producer_signaling_threads,
            consumer_signaling_threads=ref.consumer_signaling_threads,
            async_producer_op=(
                ref.async_producer_op
                if merged_pipeline_type == PipelineType.AsyncAsync
                else pipeline.PipelineOp.AsyncThread
            ),
            umma_consumer_producer_op=(
                ref.umma_consumer_producer_op
                if merged_pipeline_type == PipelineType.AsyncUmma
                else pipeline.PipelineOp.AsyncThread
            ),
            num_bytes_per_warp_per_cta=ref.num_bytes_per_warp_per_cta,
            mcast_mode_mn=ref.mcast_mode_mn,
            advance_on_wait=ref.advance_on_wait,
            interleave_stride=ref.interleave_stride,
        )

    def _validate_explicit_config(self) -> None:
        """Validate a user-supplied ``pipeline_config`` against members."""
        _ALLOWED_GROUP_TYPES = {
            PipelineType.AsyncAsync,
            PipelineType.TmaAsync,
            PipelineType.TmaUmma,
            PipelineType.UmmaAsync,
            PipelineType.AsyncUmma,
            PipelineType.UmmaUmma,
        }
        cfg = self.pipeline_config
        assert cfg is not None
        total_bytes = 0
        for m in self.members:
            if m.pipeline_config is None:
                raise ValueError(
                    f"PipelineGroup member '{m.name}' has no pipeline_config."
                )
            mc = m.pipeline_config
            if mc.pipeline_type not in _ALLOWED_GROUP_TYPES:
                raise ValueError(
                    f"PipelineGroup only supports "
                    f"{sorted(t.value for t in _ALLOWED_GROUP_TYPES)} "
                    f"pipeline types, got '{mc.pipeline_type.value}' "
                    f"on member '{m.name}'."
                )
            if mc.num_stages != cfg.num_stages:
                raise ValueError(
                    f"PipelineGroup explicit num_stages ({cfg.num_stages}) "
                    f"differs from member '{m.name}' ({mc.num_stages})."
                )
            if mc.interleave_strides != cfg.interleave_strides:
                raise ValueError(
                    f"PipelineGroup explicit interleave_strides "
                    f"({cfg.interleave_strides}) differ from member "
                    f"'{m.name}' ({mc.interleave_strides})."
                )
            if not self.is_heterogeneous:
                if mc.pipeline_type != cfg.pipeline_type:
                    raise ValueError(
                        f"PipelineGroup explicit pipeline_type "
                        f"({cfg.pipeline_type}) differs from member "
                        f"'{m.name}' ({mc.pipeline_type})."
                    )
            total_bytes += mc.num_bytes
        if total_bytes != cfg.num_bytes:
            raise ValueError(
                f"PipelineGroup explicit num_bytes ({cfg.num_bytes}) != "
                f"sum of member num_bytes ({total_bytes})."
            )

    def create(self) -> None:
        """Create pipeline(s) for this group and assign to members.

        Always uses per-member barriers to avoid double-arming issues
        when multiple producers/consumers call acquire on the same
        shared pipeline.  The layout depends on the mode:

        - *Merge*: per-member full barriers + 1 shared empty barrier.
        - *Fork*: 1 shared full barrier + per-member empty barriers.

        A per-member pipeline object of the correct type is constructed
        and assigned to ``m.pipeline``.  The group's ``self.pipeline``
        is also set for group-level operations (e.g. ``producer_tail``).
        """
        if self.pipeline_config is None:
            return

        self._create_heterogeneous_pipelines()

    def _create_heterogeneous_pipelines(self) -> None:
        """Allocate mode-dependent barrier layout with per-member barriers.

        Always uses per-member barriers on the "many" side to prevent
        double-arming when multiple producers/consumers independently
        call acquire on the same barrier.  Works for both homogeneous
        and heterogeneous groups.

        **Merge** (N producers, 1 consumer) — per-member full barriers,
        shared empty barrier::

            [full_0 × S] [full_1 × S] … [full_{N-1} × S] [shared_empty × S]

        **Fork** (1 producer, N consumers) — shared full barrier,
        per-member empty barriers::

            [shared_full × S] [empty_0 × S] [empty_1 × S] … [empty_{N-1} × S]

        Both layouts use ``(N + 1) × S`` barrier entries total.

        Fork caveat: the schedule has ``ProducerAcquire`` for every
        member, but ``_producer_acquire`` in task.py treats secondary
        members (all except ``members[0]``) differently — it only
        waits on their per-member empty barrier without arming the
        shared full barrier again.
        """
        N = len(self.members)
        assert self.pipeline_config is not None
        S = self.pipeline_config.num_stages
        cfg = self.pipeline_config

        if cfg.barrier_ptr is None:
            raise RuntimeError(
                "PipelineGroup barrier_ptr not set. "
                "Register the group with SmemAllocator.add_pipeline_group() "
                "before calling create()."
            )
        base_ptr = cfg.barrier_ptr

        cta_layout = cfg.cta_layout_vmnk
        if cta_layout is not None and not isinstance(cta_layout, cute.Layout):
            cta_layout = cute.make_layout(cta_layout)

        if self.mode == PipelineGroupMode.Merge:
            # ── Merge: per-member full + shared empty ────────────
            # The shared empty barrier uses the merged config's
            # consumer_group (non-TMA size when mixed).  TmaAsync
            # members are built with is_signaling_thread=True so
            # all threads arrive uniformly.
            shared_empty = self._make_empty_sync_object(
                cfg,
                base_ptr + N * S,
            )
            for i, m in enumerate(self.members):
                assert m.pipeline_config is not None
                full_so = self._make_full_sync_object(
                    m.pipeline_config,
                    base_ptr + i * S,
                )
                m.pipeline = self._build_member_pipeline(
                    m,
                    m.pipeline_config,
                    full_so,
                    shared_empty,
                    cta_layout,
                )
        else:
            # ── Fork: shared full + per-member empty ─────────────
            # Shared full barrier uses the merged config (tx_count =
            # bytes for one load, producer_group = validated-equal).
            # Per-member empties let each consumer release
            # independently with the correct signaling convention.
            shared_full = self._make_full_sync_object(cfg, base_ptr)
            for i, m in enumerate(self.members):
                assert m.pipeline_config is not None
                empty_so = self._make_empty_sync_object(
                    m.pipeline_config,
                    base_ptr + (1 + i) * S,
                )
                m.pipeline = self._build_member_pipeline(
                    m,
                    m.pipeline_config,
                    shared_full,
                    empty_so,
                    cta_layout,
                )

        # Do NOT alias self.pipeline to a member's pipeline object.
        # ``inject_leaves`` (SSA value injection after scf.if / scf.while)
        # breaks Python object identity: after injection ``self.pipeline``
        # and ``members[0].pipeline`` become distinct objects.  The next
        # ``gather_leaves`` call then traverses both, producing extra tree
        # keys (``pipeline_group.pipeline.*``) that weren't in the
        # original snapshot → structural-mismatch DSL error.
        #
        # Leave self.pipeline = None.  Group-level barrier operations
        # (ConsumerRelease / ProducerCommit) access the first member's
        # pipeline via ``group_pipeline``.
        pass

    def _make_full_sync_object(
        self,
        cfg: "PipelineConfig",
        full_ptr: cute.Pointer,
    ) -> pipeline.SyncObject:
        """Build the full (producer-side) sync object from a config.

        The full barrier is armed by the producer and waited-on by the
        consumer.  ``cfg`` supplies the producer agent type and
        cooperative-group size.  For TMA producers, ``tx_count`` is set
        to ``cfg.num_bytes``; for all others it is 0.
        """
        _PRODUCER_OP = {
            PipelineType.AsyncAsync: cfg.async_producer_op,
            PipelineType.TmaAsync: pipeline.PipelineOp.TmaLoad,
            PipelineType.TmaUmma: pipeline.PipelineOp.TmaLoad,
            PipelineType.UmmaAsync: pipeline.PipelineOp.TCGen05Mma,
            PipelineType.AsyncUmma: cfg.umma_consumer_producer_op,
            PipelineType.UmmaUmma: pipeline.PipelineOp.TCGen05Mma,
        }
        if cfg.pipeline_type not in _PRODUCER_OP:
            raise ValueError(
                f"Unsupported pipeline_type for heterogeneous group "
                f"full barrier: {cfg.pipeline_type}."
            )
        producer_op = _PRODUCER_OP[cfg.pipeline_type]
        tx_count = (
            cfg.num_bytes
            if cfg.pipeline_type in {PipelineType.TmaAsync, PipelineType.TmaUmma}
            else 0
        )
        producer_agent = (producer_op, cfg.producer_group)
        return pipeline.PipelineTmaUmma._make_sync_object(
            full_ptr,
            cfg.num_stages,
            producer_agent,
            tx_count,
        )

    def _make_empty_sync_object(
        self,
        cfg: "PipelineConfig",
        empty_ptr: cute.Pointer,
    ) -> pipeline.SyncObject:
        """Build the empty (consumer-side) sync object from a config.

        The empty barrier is signaled by the consumer (release) and
        waited-on by the producer (acquire).  ``cfg`` supplies the
        consumer agent type and cooperative-group size.
        """
        _CONSUMER_OP = {
            PipelineType.AsyncAsync: pipeline.PipelineOp.AsyncThread,
            PipelineType.TmaAsync: pipeline.PipelineOp.AsyncThread,
            PipelineType.TmaUmma: pipeline.PipelineOp.TCGen05Mma,
            PipelineType.UmmaAsync: pipeline.PipelineOp.AsyncThread,
            PipelineType.AsyncUmma: pipeline.PipelineOp.TCGen05Mma,
            PipelineType.UmmaUmma: pipeline.PipelineOp.TCGen05Mma,
        }
        if cfg.pipeline_type not in _CONSUMER_OP:
            raise ValueError(
                f"Unsupported pipeline_type for heterogeneous group "
                f"empty barrier: {cfg.pipeline_type}."
            )
        consumer_op = _CONSUMER_OP[cfg.pipeline_type]
        consumer_agent = (consumer_op, cfg.consumer_group)
        return pipeline.PipelineTmaUmma._make_sync_object(
            empty_ptr,
            cfg.num_stages,
            consumer_agent,
        )

    def _build_member_pipeline(
        self,
        member: MemoryResource,
        member_cfg: "PipelineConfig",
        sync_object_full: pipeline.SyncObject,
        sync_object_empty: pipeline.SyncObject,
        cta_layout: Optional[cute.Layout],
    ) -> object:
        """Construct a pipeline object from pre-built full/empty sync objects.

        The caller is responsible for building the sync objects via
        ``_make_full_sync_object`` / ``_make_empty_sync_object`` and
        deciding which are shared vs per-member.
        """
        ptype = member_cfg.pipeline_type
        S = member_cfg.num_stages

        # ── AsyncAsync ────────────────────────────────────────────
        if ptype == PipelineType.AsyncAsync:
            return pipeline.PipelineAsync(
                sync_object_full,
                sync_object_empty,
                S,
                None,
                None,
            )

        # ── TmaAsync ──────────────────────────────────────────────
        if ptype == PipelineType.TmaAsync:
            _TMA_TYPES = {PipelineType.TmaAsync, PipelineType.TmaUmma}
            has_non_tma = any(
                cast(PipelineConfig, m.pipeline_config).pipeline_type not in _TMA_TYPES
                for m in self.members
            )
            if has_non_tma:
                # Heterogeneous with non-TMA member: override
                # is_signaling_thread so all consumer threads arrive,
                # matching the non-TMA member's all-thread convention.
                dst_rank = None
                is_signaling_thread = True
            else:
                tidx, _, _ = cute.arch.thread_idx()
                effective_layout = (
                    cta_layout
                    if cta_layout is not None
                    else cute.make_layout((1, 1, 1, 1))
                )
                dst_rank, is_signaling_thread = (
                    pipeline.PipelineTmaAsync.init_empty_barrier_arrive_signal(
                        effective_layout,
                        tidx,
                    )
                )
                if cta_layout is None or cute.size(cta_layout) == 1:
                    dst_rank = None
            if member_cfg.producer_signaling_threads.has_task_warp_leader():
                return ts_pipeline.TSPipelineTmaAsync(
                    sync_object_full,
                    sync_object_empty,
                    S,
                    None,
                    dst_rank,
                    cast(cutlass.Boolean, is_signaling_thread),
                    member._producer_task_warp_leader_predicate(
                        include_cta_leader=True,
                    ),
                )
            return pipeline.PipelineTmaAsync(
                sync_object_full,
                sync_object_empty,
                S,
                None,
                dst_rank,
                cast(cutlass.Boolean, is_signaling_thread),
            )

        # ── TmaUmma ─────────────────────────────────────────
        if ptype == PipelineType.TmaUmma:
            if cta_layout is None or cute.size(cta_layout) == 1:
                producer_mask = None
                is_leader_cta = True
            else:
                producer_mask = pipeline.PipelineTmaUmma._compute_mcast_arrival_mask(
                    cta_layout,
                    member_cfg.mcast_mode_mn,
                )
                is_leader_cta = pipeline.PipelineTmaUmma._compute_is_leader_cta(
                    cta_layout,
                )
            cta_group = (
                cute.nvgpu.tcgen05.CtaGroup.ONE
                if cta_layout is None or cute.size(cta_layout, mode=[0]) == 1
                else cute.nvgpu.tcgen05.CtaGroup.TWO
            )
            member_pipeline = pipeline.PipelineTmaUmma(
                sync_object_full,
                sync_object_empty,
                S,
                producer_mask,
                producer_mask,
                is_leader_cta,
                cta_group,
            )
            return member._apply_task_warp_leader_to_tma_umma(member_pipeline)

        # ── UmmaAsync ─────────────────────────────────────
        if ptype == PipelineType.UmmaAsync:
            if cta_layout is None or cute.size(cta_layout) == 1:
                producer_mask = None
            else:
                producer_mask = pipeline.PipelineUmmaAsync._compute_tmem_sync_mask(
                    cta_layout,
                )
            if cta_layout is None or cute.size(cta_layout, mode=[0]) == 1:
                consumer_mask = None
            else:
                consumer_mask = pipeline.PipelineUmmaAsync._compute_peer_cta_rank()
            cta_group = (
                cute.nvgpu.tcgen05.CtaGroup.ONE
                if cta_layout is None or cute.size(cta_layout, mode=[0]) == 1
                else cute.nvgpu.tcgen05.CtaGroup.TWO
            )
            return pipeline.PipelineUmmaAsync(
                sync_object_full,
                sync_object_empty,
                S,
                producer_mask,
                consumer_mask,
                cta_group,
            )

        # ── UmmaUmma ─────────────────────────────────────────────
        if ptype == PipelineType.UmmaUmma:
            if cta_layout is None or cute.size(cta_layout, mode=[0]) == 1:
                producer_mask = None
                consumer_mask = None
            else:
                peer_cta_mask = pipeline.PipelineAsyncUmma._compute_peer_cta_mask(
                    cta_layout,
                )
                producer_mask = peer_cta_mask
                consumer_mask = peer_cta_mask
            cta_group = (
                cute.nvgpu.tcgen05.CtaGroup.ONE
                if cta_layout is None or cute.size(cta_layout, mode=[0]) == 1
                else cute.nvgpu.tcgen05.CtaGroup.TWO
            )
            return ts_pipeline.TSPipelineUmmaUmma(
                sync_object_full,
                sync_object_empty,
                S,
                producer_mask,
                consumer_mask,
                cta_group,
            )

        # ── AsyncUmma ─────────────────────────────────────
        if ptype == PipelineType.AsyncUmma:
            cta_group = (
                cute.nvgpu.tcgen05.CtaGroup.ONE
                if cta_layout is None or cute.size(cta_layout, mode=[0]) == 1
                else cute.nvgpu.tcgen05.CtaGroup.TWO
            )
            if cta_layout is None or cute.size(cta_layout, mode=[0]) == 1:
                producer_mask = None
                consumer_mask = None
            else:
                producer_mask = (
                    None
                    if member_cfg.umma_consumer_producer_op
                    == pipeline.PipelineOp.AsyncLoad
                    else pipeline.PipelineAsyncUmma._compute_leading_cta_rank(
                        cute.size(cta_layout, mode=[0]),
                    )
                )
                consumer_mask = pipeline.PipelineAsyncUmma._compute_peer_cta_mask(
                    cta_layout,
                )
            return ts_pipeline.TSPipelineAsyncUmma(
                sync_object_full,
                sync_object_empty,
                S,
                producer_mask,
                consumer_mask,
                cta_group,
                member_cfg.umma_consumer_producer_op,
            )

        raise ValueError(f"Unsupported pipeline_type for heterogeneous group: {ptype}.")
