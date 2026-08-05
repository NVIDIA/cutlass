.. _rts_validation:

Validation
==========

Overview
--------

``TaskManager.__init__()`` prints each captured task schedule and runs
the validation checks before code generation proceeds.  It validates the
captured ``ScheduleResult`` passed through ``schedule=``.

Complete Check List
-------------------

- **Captured domain validity** - A schedule must have a valid domain source.
  Static domains need a non-zero step; dynamic domains need a ``get_domain``
  provider.
- **Resource stage roles** - A resource listed in ``src_resources`` may only be
  read (consumer stages); a resource listed in ``dst_resources`` may only be
  written (producer stages).  A task cannot use a resource in the role it did not
  declare.
- **Dependency graph is realizable** - The dependency graph lists, for each
  resource, the upstream resources that must be produced and consumed before it.
  Every resource named there must be one the tasks actually use, and each
  upstream/downstream relationship must be backed by a task that reads the
  upstream resource and a task that writes the downstream one.  Otherwise the
  graph states an ordering that no schedule realizes.
- **Every resource is in the graph** - Every resource a task reads or writes
  must appear in the dependency graph, so a missing ordering relationship cannot
  slip through unchecked.
- **Schedule resource coverage** - Every resource declared on a task must
  actually be used by entries in that task's captured schedule.
- **Work bracketing** - Consumer work must be bracketed by ``wait`` and
  ``release``.  Producer work must be bracketed by ``acquire`` and ``commit``.
  ``try_`` operations must precede their blocking operations.
- **WorkQueue placement** - In a persistent kernel either all tasks are
  persistent or none are, and every task must run the WorkQueue epilogue
  (``wait`` / ``get_and_advance_work_tile`` / ``release``) only in the tail of
  its schedule -- never in the head or main loop -- so every CTA advances the
  queue exactly once per tile.
- **DMA ordering** - An upstream buffer cannot be released before downstream DMA
  producer work has consumed it.
- **Exhaustive interleaving** - A separate checker simulates every legal
  ordering of the tasks' steps to catch problems no single task's schedule
  reveals, including deadlocks, physical SMEM/TMEM aliasing races, and PDL
  launches that can run before a PDL wait.
- **Pipeline thread counts and bytes** - The developer still specifies the
  barrier arrival counts (cooperative-group sizes) and TMA transaction bytes on
  each pipeline; TS recomputes the expected values from the pipeline type, task
  warp counts, cluster layout, and signaling mode and checks the developer's
  values against them.  On a mismatch the raised error states the exact value it
  expected.
- **Leader-routed producer completions** - When a TMA producer routes its
  completion through a single leader (one warp or one CTA) that arms the
  transaction barrier on behalf of several producing warps or CTAs, the declared
  ``num_bytes`` must cover the bytes of all of them.  TS checks the aggregate
  using ``num_bytes_per_warp_per_cta`` (see :ref:`rts_patterns`).
- **Interleaved pipelines** - A resource with ``interleave_stride > 1`` must
  have ``num_stages`` divisible by each stride.  Asymmetric acquire/commit or
  wait/release strides require the corresponding advance flag and separate
  tasks for those roles.  Every task that uses an interleaved side must either
  provide one warp per lane or split its loop domain into one task per lane;
  domain-derived lanes additionally require matching opening and closing
  strides.  ``UmmaUmma`` and ``ClcFetchAsync`` do not support interleaving;
  the remaining pipeline-type restrictions are described in
  :ref:`rts_patterns`.
- **CTA layout consistency** - All pipelined resources in a kernel must declare
  the same ``cta_layout_vmnk`` (the same cluster decomposition, i.e. the same
  number of CTAs in the cluster).  Resources without a pipeline (e.g. plain GMEM)
  may leave it unset; two pipelines that disagree on the cluster shape are
  rejected.
- **Head/loop producer overlap** - A pipelined producer that runs in both the
  head and the main loop is flagged (a warning), because head work and the
  loop's first iteration both see ``loop_offset = 0``; a producer that addresses
  data by ``loop_offset`` would then target the same tile.  Produce in the head
  only or the loop only.
- **Named work dispatch** - When a resource has several work methods, the method
  called in the schedule selects which one runs; the label must resolve to a
  decorated ``@consumer_work`` or ``@producer_work`` method on the resource.
- **SMEM capacity** - The allocated shared-memory requirements must fit the
  supplied allocator capacity.
- **TMEM capacity** - The allocated tensor-memory requirements must fit the
  supplied allocator capacity.
- **Value routing** - A value handed between work methods (a
  ``TaskLocalVariable`` token) must be written before it is read, must flow from
  a consumer read into a producer write (not backwards), and -- when the same
  value is written more than once -- readers must take the most recent write.
  TS rejects a value that is read with no prior writer or routed the wrong way.
- **Ping-pong resources** - A resource that is both produced and consumed against
  itself (a self-edge in the dependency graph) needs a pipeline configuration and
  a task that participates on both the producer and consumer sides.  See
  :ref:`rts_patterns`.
- **Split-consumer signaling** - In a *split-consumer* pattern the ``wait`` and
  the ``release`` of a pipeline happen in different tasks.
  ``consumer_wait_signaling_threads`` may be set only when such a pattern is
  actually present; setting it otherwise is rejected.  See :ref:`rts_patterns`.
- **Persistent skip predicate** - ``skip_if`` must be a valid ``WorkQueue``
  method because skipped-tile execution still has to advance the same work
  queue.
- **Warp-group register consistency** - Tasks in the same warp-group register
  partition must agree on their requested register count.
- **Register budget** - The requested task register budgets must fit the
  hardware register budget.
- **PipelineGroup consistency** - Members of a pipeline group must use
  compatible pipeline configurations and must be wired consistently through their
  tasks.  See :ref:`rts_pipeline_groups`.

Task and Schedule Construction
------------------------------

TS tasks should be built from the ``ScheduleResult`` returned by a
captured schedule:

.. code-block:: python

    @schedule
    def copy_schedule(src: InputGmemResource,
                      dst: OutputGmemResource) -> None:
        with domain_loop(0, num_entries, 1):
            value = src.load()
            dst.store(value=value)

    copy_task = Task(
        name="copy",
        src_resources=[src],
        dst_resources=[dst],
        warp_idx=0,
        num_warps=1,
        schedule=copy_schedule(src, dst),
    )

The captured schedule owns the domain, schedule entries, slot routing, loop
guards, and persistent skip metadata.

Static domains must advance:

.. code-block:: python

    @schedule
    def bad_domain_schedule(src: InputGmemResource) -> None:
        with domain_loop(0, num_entries, 0):
            src.load()

This schedule is not allowed because a zero step cannot make progress through
the loop domain.  For dynamic domains, the schedule must name a task method that
computes the domain bound for the current work tile.

Dependency Graph and Resource Coverage
--------------------------------------

The dependency graph states the intended ordering: each key is a downstream
resource and each value lists the upstream resources that must be consumed before
it is produced.  Every resource a task uses must appear in the graph, and every
edge must be backed by a task that realizes it.  The load task below reads
``gmem_a`` and writes ``smem_a``:

.. code-block:: python

    @schedule
    def load_schedule(gmem_a: GmemAResource,
                      smem_a: SmemAResource) -> None:
        with domain_loop(0, num_k_tiles, 1):
            coord_k, coord_m, coord_n = gmem_a.compute_coords()
            smem_a.try_acquire()
            smem_a.acquire()
            smem_a.tma_load_a(coord_k=coord_k, coord_m=coord_m)
            smem_a.commit()

    load_task = Task(
        name="load_a",
        src_resources=[gmem_a],
        dst_resources=[smem_a],
        warp_idx=0,
        num_warps=1,
        schedule=load_schedule(gmem_a, smem_a),
    )

**Rejected -- resource missing from the graph.**  ``gmem_a`` and ``smem_a`` are
used by the task but the graph does not mention them, so TS cannot check the
ordering and rejects the build (``... does not appear in
resource_dependency_graph``):

.. code-block:: python

    task_manager = TaskManager(
        tasks=[load_task],
        resource_dependency_graph={},     # gmem_a / smem_a not declared
    )

**Fix.**  Declare the edge so the upstream/downstream relationship is checked:

.. code-block:: python

    task_manager = TaskManager(
        tasks=[load_task],
        resource_dependency_graph={smem_a: [gmem_a]},
    )

**Rejected -- edge with no backing task.**  Here the graph claims ``smem_a``
depends on ``gmem_a``, but the only task neither reads ``gmem_a`` nor writes
``smem_a``, so the ordering requirement has no schedule that realizes it:

.. code-block:: python

    task_manager = TaskManager(
        tasks=[compute_task],             # does not read gmem_a or write smem_a
        resource_dependency_graph={smem_a: [gmem_a]},
    )

**Fix.**  Include a task that has ``gmem_a`` in ``src_resources`` and ``smem_a``
in ``dst_resources`` (the ``load_task`` above), so the declared edge is backed by
a real producer/consumer.

Resource Roles
--------------

A task's resource declarations determine which stage families it may use:

.. code-block:: python

    @schedule
    def bad_role_schedule(smem_a: SmemAResource) -> None:
        with domain_loop(0, num_k_tiles, 1):
            smem_a.acquire()
            smem_a.produce_tile()
            smem_a.commit()

    bad_task = Task(
        name="bad_role",
        src_resources=[smem_a],
        dst_resources=[],
        warp_idx=0,
        num_warps=1,
        schedule=bad_role_schedule(smem_a),
    )

This schedule is not allowed because the task declares ``smem_a`` as a source
resource but uses producer-side operations on it.  Producer stages belong to
``dst_resources``; consumer stages belong to ``src_resources``.

Work Bracketing and DMA Ordering
--------------------------------

Pipeline stages must be owned before they are used and released only after the
dependent work has consumed them.

.. code-block:: python

    @schedule
    def bad_load_schedule(gmem_a: GmemAResource,
                          smem_a: SmemAResource) -> None:
        with domain_loop(0, num_k_tiles, 1):
            coord_k, coord_m, coord_n = gmem_a.compute_coords()
            smem_a.tma_load_a(coord_k=coord_k, coord_m=coord_m)   # work before acquire
            smem_a.acquire()
            smem_a.commit()

The ``acquire`` / ``commit`` bracket is balanced, but the producer work
(``tma_load_a``) runs *before* the ``acquire`` -- it writes into ``smem_a``
before owning a stage.  The write must sit *inside* the bracket so no other
producer can still own that stage while it is being filled.  The fix moves the
work between ``acquire`` and ``commit``:

.. code-block:: python

    @schedule
    def load_schedule(gmem_a: GmemAResource,
                      smem_a: SmemAResource) -> None:
        with domain_loop(0, num_k_tiles, 1):
            coord_k, coord_m, coord_n = gmem_a.compute_coords()
            smem_a.acquire()
            smem_a.tma_load_a(coord_k=coord_k, coord_m=coord_m)
            smem_a.commit()

DMA ordering adds a further constraint for buffers filled by a DMA engine (a TMA
load): the consumer must not **release** the buffer before the downstream work
that actually reads it has run.  ``smem_a`` below is filled by TMA (a ``TmaUmma``
pipeline) and consumed by the MMA that produces ``tmem_c``:

.. code-block:: python

    @schedule
    def bad_dma_order_schedule(smem_a: SmemAResource,
                               tmem_c: TmemCResource) -> None:
        with domain_loop(0, num_k_tiles, 1):
            smem_a.wait()
            desc_a = smem_a.build_desc()      # consumer work
            smem_a.release()                  # released before the MMA reads it
            tmem_c.acquire()
            tmem_c.mma(desc_a=desc_a)         # downstream producer work reads smem_a
            tmem_c.commit()

The bracket is balanced and the wait/work window is present, but ``smem_a`` is
released *before* ``tmem_c.mma`` -- the downstream producer work that actually
reads the tile.  After the release the next TMA load may overwrite ``smem_a``
while the MMA still needs it.  The fix releases ``smem_a`` only after the MMA has
consumed it:

.. code-block:: python

    @schedule
    def mma_schedule(smem_a: SmemAResource,
                     tmem_c: TmemCResource) -> None:
        with domain_loop(0, num_k_tiles, 1):
            smem_a.wait()
            desc_a = smem_a.build_desc()
            tmem_c.acquire()
            tmem_c.mma(desc_a=desc_a)
            smem_a.release()                  # release after the MMA read
            tmem_c.commit()

TS decides whether a downstream resource counts as a *DMA producer* from its
pipeline type -- specifically, the producer side of its pipeline.  Types whose
producer is an asynchronous hardware engine (a TMA load, a ``tcgen05`` MMA, or a
CLC fetch) -- ``TmaAsync``, ``TmaUmma``, ``UmmaAsync``, ``UmmaUmma``, and
``ClcFetchAsync`` -- complete by a hardware signal, not by the issuing thread, so
the upstream buffer they read must stay live until that producer work runs.  The
ordering rule applies only on edges whose downstream is such a producer; for a
plain downstream (for example a non-pipelined global-memory store) an early
release is harmless and accepted.

Persistent WorkQueue Placement and Loop Guards
----------------------------------------------

Persistent schedules must keep ``WorkQueue`` bookkeeping outside skipped data
work so every launched CTA advances the queue exactly once.

.. code-block:: python

    @schedule
    def bad_skip_schedule(copy_res: CopyResource,
                          wq: WorkQueue) -> None:
        with work_tile_loop(wq, skip_if=CopyWorkQueue.skip_work_tile_if) as wtwl:
            with wtwl.skippable(), domain_loop(0, num_rows, 1):
                copy_res.copy_row()
                wq.try_wait()
                wq.wait()
                wq.get_and_advance_work_tile()
                wq.release()

This schedule is wrong for two reasons.  First, the queue bookkeeping is inside
the ``domain_loop``, so it advances the work tile once per row -- ``num_rows``
times per work-tile iteration -- instead of exactly once; tasks with different
loop lengths would advance by different amounts and fall out of sync.  Second, it
is inside ``skippable()``, so a skipped tile bypasses the advance entirely: the
work tile is never updated, ``work_tile_loop`` keeps seeing the same valid tile,
and the loop never progresses -- an infinite loop on that CTA.  The bookkeeping
must sit in the work-tile tail, outside both the domain loop and the skippable
region:

.. code-block:: python

    @schedule
    def copy_schedule(copy_res: CopyResource,
                      wq: WorkQueue) -> None:
        with work_tile_loop(wq, skip_if=CopyWorkQueue.skip_work_tile_if) as wtwl:
            with wtwl.skippable(), domain_loop(0, num_rows, 1):
                copy_res.copy_row()
            wq.try_wait()                     # tail: runs once per work tile
            wq.wait()
            wq.get_and_advance_work_tile()
            wq.release()

A first- or last-iteration guard is only meaningful *inside* the domain loop, so
placing one outside the loop is rejected:

.. code-block:: python

    @schedule
    def bad_guard_schedule(smem_a: SmemAResource) -> None:
        with domain_loop(0, num_k_tiles, 1) as d:
            smem_a.acquire()
            smem_a.produce_tile()
            smem_a.commit()
        with d.first_iter():                  # illegal: outside the domain loop
            smem_a.try_acquire()

The guard refers to an iteration of the loop, but here the loop has already
closed.  Keep ``d.first_iter()`` / ``d.last_iter()`` blocks inside the
``domain_loop`` body (see :ref:`rts_schedules` for what they do).

PDL Ordering
------------

PDL wait resources are ordering-only resources, but the dependency still has to
be explicit.  If ``gmem_ab`` reads predecessor-grid data, declare the wait as an
upstream dependency of ``gmem_ab``:

.. code-block:: python

    resource_dependency_graph = {
        gmem_ab: [pdl_wait_resource],
    }

    @schedule
    def pdl_load_schedule(gmem_ab: GmemAbResource,
                          smem_a: SmemAResource,
                          pdl_wait_resource: PdlWaitBarrier,
                          pdl_launch_resource: PdlLaunchBarrier) -> None:
        pdl_wait_resource.wait_griddep()
        with domain_loop(0, num_k_tiles, 1):
            coord_k, coord_m, coord_n = gmem_ab.compute_coords()
            smem_a.acquire()
            smem_a.tma_load_a(coord_k=coord_k, coord_m=coord_m)
            smem_a.commit()
        pdl_launch_resource.launch_griddep()

With that graph edge, TS checks that the PDL wait precedes the work that reads
from ``gmem_ab``.  Without it, ``gmem_ab`` and ``pdl_wait_resource`` are
independent resources from the schedule validator's point of view.

A launch path is not allowed when it can execute before any PDL wait:

.. code-block:: python

    @schedule
    def bad_pdl_launch_schedule(pdl_launch_resource: PdlLaunchBarrier) -> None:
        with domain_loop(0, 1, 1):
            pdl_launch_resource.launch_griddep()

That ordering would notify dependent grids before this grid has waited for its
own predecessor dependency.  The exhaustive checker also evaluates skipped-tile
paths, so a wait hidden inside skipped work does not justify an unconditional
launch.

Named Work and Slot Routing
---------------------------

Captured schedules call the decorated work method directly.  When a resource
has multiple work methods, the method call is the dispatch label:

.. code-block:: python

    @schedule
    def named_work_schedule(src: PacketResource,
                            dst: PacketResource) -> None:
        with domain_loop(0, packet_count, 1):
            header = src.load_header()
            payload = src.load_payload()
            dst.store_header(header=header)
            dst.store_payload(payload=payload)

The captured labels must still resolve to decorated ``@consumer_work`` and
``@producer_work`` methods.  If a label points at a helper that is not a work
method, TS cannot assign it a schedule stage and the schedule is rejected.

The same capture records value routing.  A value must be written before it is
read, and the route must follow the task resource roles:

.. code-block:: python

    @schedule
    def routed_schedule(src: PacketResource,
                        dst: PacketResource) -> None:
        with domain_loop(0, packet_count, 1):
            token = src.load_payload()
            dst.store_payload(token=token)

The route from ``src.load_payload`` to ``dst.store_payload`` is valid because
the writer is a consumer-stage call on a source resource and the reader is a
producer-stage call on a destination resource.  A route in the opposite
direction is not allowed because producer-side values cannot be copied back into
an earlier consumer-stage reader through the same task schedule.

Pipeline Configuration Checks
-----------------------------

Pipeline checks compare the values put on a resource's ``PipelineConfig``
against what the tasks that use the resource can actually emit.  The developer still chooses
those values, but they must be consistent with the warp counts of the producing
and consuming tasks; TS recomputes the expected values and, on a mismatch,
raises an error naming the value it expected.

Consider a ``TmemC`` accumulator produced by a single MMA warp and drained by a
4-warp epilogue task.  The consumer side of its pipeline is released by the
epilogue threads, so its ``consumer_group`` must be sized to that task --
``num_epilogue_warps * 32`` threads:

.. code-block:: python

    num_epilogue_warps = 4

    mma_task   = Task(name="MmaTask",   warp_idx=8, num_warps=1,
                      dst_resources=[tmem_c], ...)
    store_task = Task(name="StoreTask", warp_idx=0, num_warps=num_epilogue_warps,
                      src_resources=[tmem_c], ...)

    cfg = PipelineConfig.create_umma_async_pipeline_cfg(
        num_stages=acc_stages,
        producer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread),
        consumer_group=pipeline.CooperativeGroup(
            pipeline.Agent.Thread, size=num_epilogue_warps * 32),   # the 4 store warps release
        cta_layout_vmnk=(1, 1, 1, 1),
    )

TS derives the expected consumer arrival count from ``StoreTask`` (its
``num_warps``) and checks ``consumer_group.size`` against it; a config sized for
a different warp count is rejected with the expected value in the message.

The *type* of pipeline must match too.  ``UmmaAsync`` is correct here because the
producer is an MMA and the consumer is plain async epilogue threads.  Using, say,
``create_tma_umma_pipeline_cfg`` for ``TmemC`` would declare an MMA *consumer*
(one ``tcgen05`` commit) instead of ``num_epilogue_warps * 32`` thread arrivals,
which cannot match ``StoreTask`` -- so TS rejects it.  The same kind of
mismatch is checked for every pipeline type; see :ref:`rts_pipelines` for the
producer/consumer each type implies.  Clustered resources must additionally agree
on ``cta_layout_vmnk``, since the same logical stage would otherwise refer to
different CTA partitions.

These checks compare arrival counts, not the actual hardware operations.  If a
wrong pipeline type happens to imply the *same* arrival counts as the correct
one, the checks can pass by coincidence -- but the generated kernel still emits
the wrong barrier protocol and its behavior is undefined (it can hang or race).
Choosing the pipeline type that matches the real operations remains the author's
responsibility; this limitation is also noted in `Verification Gaps`_.

Exhaustive Interleaving
-----------------------

The exhaustive checker explores legal interleavings across tasks.  It catches
problems that are not visible from one task's linear schedule alone:

- deadlock, where every task is blocked waiting for an event no task can issue;
- physical SMEM/TMEM aliasing, where overlapping allocations are read and
  written outside a valid pipeline window;
- PDL launch ordering, where a launch can execute before any wait;
- skipped-tile variants of the same ordering rules.

.. code-block:: python

    @schedule
    def producer_schedule(tmem_a: TmemResource) -> None:
        with domain_loop(0, num_k_tiles, 1):
            tmem_a.acquire()
            tmem_a.produce_tile()
            tmem_a.commit()

    @schedule
    def consumer_schedule(tmem_b: TmemResource) -> None:
        with domain_loop(0, num_k_tiles, 1):
            tmem_b.wait()
            tmem_b.consume_tile()
            tmem_b.release()

If ``tmem_a`` and ``tmem_b`` describe overlapping physical TMEM columns but
there is no pipeline relationship that orders the write and read windows, the
schedule is not allowed.  The resources look separate at the Python object
level, but the physical allocation aliases without a pipeline dependency.

The ordering does not have to be direct.  The checker follows the dependency
graph transitively: a chain ``tmem_a -> ... -> tmem_b`` can let the pipelines
along it order ``tmem_a``'s write window before ``tmem_b``'s read window.  But
the chain only helps if it actually keeps the aliased windows apart.  The checker
still simulates every interleaving, and if the overlapping write and read stages
can run **concurrently** in any of them -- the ordering chain does not serialize
those particular windows -- it still flags the race.  Safety requires that no
valid interleaving lets the aliased stages overlap, not merely that a dependency
path exists.

Verification Gaps
-----------------

TS verifies only what it can see: the declared resources, their pipelines, the
dependency graph, and the captured schedule structure.  Anything that happens
*inside* a ``@cute.jit`` work body, or through synchronization primitives TS
does not own, is opaque to it -- a work call is treated as a single black-box
step.  The following situations therefore **cannot be checked statically** and
remain the author's responsibility.

**Inter-CTA communication inside work bodies.**  In a kernel such as split-K, a
CTA may exchange data with its cluster peers -- store into a peer's shared memory
and then arrive on and wait on a barrier for that exchange -- all inside a
producer or consumer work body.  TS has no view of that hand-written
producer/consumer/barrier protocol; it only models the pipelines the developer
declares on resources.  A wrong arrival count or a missing wait in that exchange
can hang or race, and TS will not report it.

**Hand-written or named barriers.**  Likewise, any named barrier (or any other
barrier/mbarrier the developer issues directly) -- whether inside a work body or
anywhere outside the TS schedule -- is invisible to the checker.  TS validates
only the ``acquire`` / ``commit`` / ``wait`` / ``release`` brackets of resources
it owns.  Hand-rolled synchronization can deadlock or produce a wrong result
without any static error.

**TMA transaction byte count.**  TS does **not** verify that the TMA load
instructions actually issued inside a producer work body sum to the ``num_bytes``
declared on the pipeline.  How many bytes are issued depends on the control flow
inside the work body, which TS does not introspect.  If the developer declares
``num_bytes = X`` but issues instructions totaling ``X/2`` or ``2X``, the
transaction barrier expects the wrong byte count -- too few bytes hang the
consumer, too many complete the stage early and race.  What TS *can* check is
that the declared byte count is **internally consistent across the cluster**:
that the per-CTA, per-warp bytes scaled by the number of warps and CTAs doing
the load match the total ``num_bytes`` (via ``num_bytes_per_warp_per_cta``; see
:ref:`rts_pipelines`).  It cannot check the count against the instructions the
developer actually emits.

Warning Mode
------------

``TaskManager(skip_validation=True)`` still runs the checks, but reports
validation failures as warnings.  Use it only when deliberately compiling a
schedule that is known to violate a conservative check and the reason is
understood.
