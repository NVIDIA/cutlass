.. _rts_pipeline_groups:

Pipeline Groups
===============

Overview
--------

A ``PipelineGroup`` is an optimization for pipelined resources that are driven
together by a single task on one side of the pipeline:

- **Merge** -- several resources are **consumed in the same task** and feed the
  same dependent resource.
- **Fork** -- several resources are **produced in the same task** from the same
  upstream resource.
- **FusedMerge** -- same dataflow as **Merge**, but the producers arrive on a
  shared full barrier instead of one full barrier per member.

When one task drives all of them together on that shared side, they advance in
lock-step, so they can share one barrier instead of arriving on one barrier each.

The canonical Merge case is a GEMM mainloop:

- ``smem_a`` is produced in a ``LoadA`` task and ``smem_b`` in a ``LoadB`` task.
- The ``MMA`` task consumes ``smem_a`` **and** ``smem_b`` in the same iteration
  and produces ``tmem_c``.
- ``tmem_c`` depends on both ``smem_a`` and ``smem_b``.

.. code-block:: python

    resource_dependency_graph = {
        smem_a: [gmem_ab],
        smem_b: [gmem_ab],
        tmem_c: [smem_a, smem_b],   # one dependent for both A and B
        gmem_d: [tmem_c],
    }

Because the ``MMA`` task waits for ``smem_a`` and ``smem_b`` at the same point
and ``tmem_c`` depends on both, the two SMEM resources can share the consumer
barrier: instead of the consumer releasing ``smem_a`` and ``smem_b`` separately,
it releases the group once.  This is the **Merge** pattern.

Merge, Fork and FusedMerge
--------------------------

A group collapses the barrier on whichever side is shared by a single task:

- ``PipelineGroupMode.Merge`` (N producers -> 1 consumer).  Several producer
  tasks each fill their own member; one consumer task reads them all.  Members
  still ``commit()`` individually; the consumer calls ``group.release()`` once.
  (The GEMM example above: ``LoadA`` and ``LoadB`` commit; ``MMA`` releases the
  group.)
- ``PipelineGroupMode.Fork`` (1 producer -> N consumers).  One producer task
  fills all members; several consumer tasks each read their own.  Members still
  ``release()`` individually; the producer calls ``group.commit()`` once.
- ``PipelineGroupMode.FusedMerge`` (N producers -> 1 consumer).  Same dataflow
  as ``Merge``, but the producer side is collapsed as well: all producers arrive
  on one shared full barrier.  The consumer calls ``group.wait()`` and
  ``group.release()`` once.  Each producer still ``commit()`` individually,
  arriving on the shared barrier with its own producer op / transaction count.

A group is a performance optimization only; per-resource barriers are always
correct, and grouping is never automatic -- it has to be opted in explicitly.

Homogeneous vs heterogeneous side
---------------------------------

Each pipeline type has a producer **kind** and a consumer **kind** (see
:ref:`rts_pipelines`): the kinds are ``tma``, ``async`` and ``umma``.  For
example ``TmaUmma`` is producer-kind ``tma`` / consumer-kind ``umma``.

Only the **collapsed side** of a group must be *homogeneous* -- that is, all
members must share the same kind on that side, because they arrive on one shared
barrier:

- **Merge** collapses the consumer side, so all members must have the same
  **consumer kind** (all ``async`` or all ``umma``).  Their producer kinds may
  differ.
- **Fork** collapses the producer side, so all members must have the same
  **producer kind** (all ``tma``, all ``async`` or all ``umma``).  Their
  consumer kinds may differ.
- **FusedMerge** shares ``Merge``'s topology, so it validates against the same
  **consumer kind** rule.  Even though the full barrier is shared, each producer
  arrives on it with its own producer op and transaction-byte count, so producer
  kinds may still differ.

The members are *fully homogeneous* when they share the exact same
``pipeline_type``, and *heterogeneous* when their types differ but the collapsed
kind still matches.  Both are supported and use the same barrier layout (see
`Barrier layout`_); "heterogeneous" simply names the case where types are mixed,
and the allowed mixes are listed below.

Valid heterogeneous combinations:

============  ==============  ===========================================
Mode          Collapsed kind  Allowed member mixes
============  ==============  ===========================================
Merge         consumer async  AsyncAsync + TmaAsync + UmmaAsync
Merge         consumer umma   TmaUmma + AsyncUmma + UmmaUmma
Fork          producer tma    TmaAsync + TmaUmma
Fork          producer async  AsyncAsync + AsyncUmma
Fork          producer umma   UmmaAsync + UmmaUmma
============  ==============  ===========================================

How member configs are merged
-----------------------------

Every member declares its own ``PipelineConfig`` exactly as if it were **not**
grouped -- the same factory call, ``num_stages``, ``num_bytes`` and cooperative
groups would be used for a standalone pipeline.  The special
"grouped" config should not be written.

When the ``PipelineGroup`` is constructed, it takes the members' configs and
tries to merge them behind the scenes:

#. **Validate compatibility** -- all members must share the same ``num_stages``
   and a compatible ``pipeline_type`` on the collapsed side.
#. **Derive a merged config** -- ``num_bytes`` is summed across members, and the
   **collapsed (shared) side** cooperative-group size must match across members
   (one task drives it). 
#. **Re-initialize the barriers** -- the group lays out the shared barrier set
   (see `Barrier layout`_) and re-points each member's pipeline at it.

If the configs cannot be matched -- different ``num_stages``, an incompatible
collapsed kind, or mismatched non-collapsed group sizes -- the group raises
``ValueError`` at construction.  (An explicit
``pipeline_config`` can be passed to the group; it is then validated against the members the
same way.)

Barrier layout
--------------

``Merge`` and ``Fork`` always lay out ``(N + 1) * num_stages`` mbarriers: **one
shared barrier on the collapsed side** plus **one private barrier per member on
the many side**.  This is true for both homogeneous and heterogeneous groups --
the many side keeps per-member barriers so its N independent tasks never
double-arm a shared barrier.

``FusedMerge`` collapses both sides and lays out just ``2 * num_stages`` mbarriers.

**Merge** (N producers, 1 consumer) -- per-member full barriers and one shared
empty barrier::

    [full_0 x S] [full_1 x S] ... [full_{N-1} x S] [shared_empty x S]

Each producer commits its own full barrier; the single consumer releases the
shared empty barrier once (``group.release()``), which frees all producers.

**Fork** (1 producer, N consumers) -- one shared full barrier and per-member
empty barriers::

    [shared_full x S] [empty_0 x S] [empty_1 x S] ... [empty_{N-1} x S]

The single producer commits the shared full barrier once (``group.commit()``),
which wakes all consumers; each consumer releases its own empty barrier.

Each barrier is armed only by the task(s) that actually signal it: the shared
barrier uses the collapsed side's matched size, and **each per-member barrier
uses only that member's own config**.

**FusedMerge** (N producers, 1 consumer) -- one shared full and one shared
empty barrier, ``2 * S`` entries total::

    [shared_full x S] [shared_empty x S]

The shared full barrier is initialized once with the combined producer arrive
count (the summed ``producer_group``) and combined transaction bytes.  Each
producer arrives on that same storage through a per-member *view*
(``recast_to_new_op_type``) that overrides only the op type and transaction
count -- so no barrier is re-initialized and no init is double-armed.  The
single consumer waits on the shared full barrier once (``group.wait()``) and
releases the shared empty barrier once (``group.release()``).


Setup
-----

Build each member with its own config, then declare the group and register it
with the allocator (the group owns the shared barrier SMEM, not the members):

.. code-block:: python

    smem_a = SmemAResource(..., pipeline_config=cfg_a, name="smem_a")
    smem_b = SmemBResource(..., pipeline_config=cfg_b, name="smem_b")

    ab_sync = PipelineGroup(
        name="ab_sync",
        members=[smem_a, smem_b],
        mode=PipelineGroupMode.Merge,
    )

    allocator.add_resource(smem_a)
    allocator.add_resource(smem_b)
    allocator.add_pipeline_group(ab_sync)

The group's barrier storage can alternatively be owned by a ``BarrierAllocator``
if registered through its ``add_pipeline_group()`` method.

Captured Schedule Convention
----------------------------

Inside ``@schedule``, use ``group.member`` for per-member operations and the
group object only for the collapsed stage.  Keep the bare resources in
``Task.src_resources`` and ``Task.dst_resources``.

A **Merge** consumer waits each member and releases the group once:

.. code-block:: python

    @schedule
    def store_schedule(output, group):
        with domain_loop(0, num_iters, 1):
            group.smem_a.try_wait()
            group.smem_a.wait()
            group.smem_b.try_wait()
            group.smem_b.wait()
            val_a = group.smem_a.read()
            val_b = group.smem_b.read()
            output.store(val_a=val_a, val_b=val_b)
            group.release()          # one collapsed release for both members

A **Fork** producer acquires each member and commits the group once:

.. code-block:: python

    @schedule
    def load_schedule(group):
        with domain_loop(0, num_k_tiles, 1):
            group.smem_gemm.try_acquire()
            group.smem_gemm.acquire()
            group.smem_act.try_acquire()
            group.smem_act.acquire()
            group.smem_gemm.load()
            group.commit()           # one collapsed commit for both members

A **FusedMerge** consumer waits and releases on the group once:

.. code-block:: python

    @schedule
    def mma_schedule(smem_a, smem_b, tmem, ab_group):
        with domain_loop(0, num_k_tiles, 1):
            ab_group.try_wait()         # one collapsed wait for all members
            ab_group.wait()
            tmem.mma(...)
            ab_group.release()          # one collapsed release for all members

Hard Rules
----------

Do not call ``group.member.release()`` on the collapsed Merge/FusedMerge
consumer side, and do not call ``group.member.commit()`` on the collapsed Fork
producer side.  TS rejects those schedules because the collapsed stage must be
emitted on the group object.  Similarly, do not call ``group.member.wait()``
on the collapsed FusedMerge consumer side.
