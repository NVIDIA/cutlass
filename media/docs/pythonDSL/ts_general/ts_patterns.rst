.. _rts_patterns:

Scheduling Patterns
===================

This page collects the advanced warp-specialization patterns that go beyond a
single linear producer/consumer schedule.  Each is optional; reach for it only
when the simpler shapes in :ref:`rts_schedules` do not fit.  The structural rules
that TS enforces for these patterns are listed in :ref:`rts_validation`.

Ping-Pong
---------

Use a *ping-pong* resource when a single buffer is **reused in place** across the
loop by two specialized tasks.  A producer task reads the buffer's current
contents and writes the next contents back into the same slot, and a consumer
task reads the buffer in between.  Everything flows through one physical buffer.

Because the same buffer is produced and consumed against itself across the loop,
it is declared as a **self-edge** in the dependency graph (the resource depends
on itself).  Its pipeline lets TS order the read before the overwrite that
follows: the self-edge tells TS that one task's next ``acquire`` must wait for
the other task's ``release`` of the previous contents, so the two tasks ping-pong
on one slot.

The producer side does the read-and-write inside its ``acquire`` / ``commit``
bracket; the consumer side -- the *other side* -- only reads inside a ``wait`` /
``release`` bracket:

.. code-block:: python

    # Producer side: reads the current contents and writes the next contents
    # back into the same buffer (transform in place).
    @schedule
    def producer_schedule(smem_pp: SmemPingPongResource) -> None:
        with domain_loop(0, num_k_tiles, 1):
            smem_pp.acquire()
            cur = smem_pp.read_current()
            smem_pp.write_next(cur=cur)
            smem_pp.commit()

    # Consumer side (the other task): transforms in place.
    @schedule
    def consumer_schedule(smem_pp: SmemPingPongResource) -> None:
        with domain_loop(0, num_k_tiles, 1):
            smem_pp.wait()
            smem_pp.transform_inplace()
            smem_pp.release()

    # The buffer is the producer's dst and the consumer's src; the self-edge
    # ties the two sides together.
    producer_task = Task(..., dst_resources=[smem_pp])
    consumer_task = Task(..., src_resources=[smem_pp])

    task_manager = TaskManager(
        tasks=[producer_task, consumer_task],
        resource_dependency_graph={smem_pp: [smem_pp]},
    )

Requirements:

- The resource must have a ``pipeline_config`` -- without it TS cannot tell the
  stage being consumed from the next stage being produced.
- The pipeline's **consumer side must be synchronous** -- an ``async`` consumer,
  such as ``AsyncAsync``, ``TmaAsync``, or ``UmmaAsync``.  Pipelines whose
  consumer is a hardware MMA (``TmaUmma``, ``AsyncUmma``, ``UmmaUmma``) are
  rejected: ping-pong depends on the consumer *synchronously* releasing the slot
  so produce and consume strictly alternate on one buffer, but an MMA consumer
  releases asynchronously through hardware, which breaks that alternation.
- The resource must be used on **both** sides: a task (or tasks) that consume it
  (``src_resources``) and produce it (``dst_resources``).

Split-Consumer
--------------

In a *split-consumer* pattern the ``wait`` and the ``release`` of a pipeline
happen in **different tasks**.  One lightweight task observes that the data is
ready (``wait``), and a heavier task does the actual work and ``release``.  E.g. for
cross-CTA synchronization without cluster-wide barrier support, a sync task can
wait on several upstream buffers and then signal a single *proxy* barrier; the
compute task waits only on the proxy, then works on and releases the original
buffers.

TS makes this work through the dependency graph: a *proxy* resource declared
**downstream** of the buffers lets the compute task's ``wait`` on the proxy serve
as the open bracket for its ``work`` on the buffers (no direct ``wait`` needed).

.. code-block:: python

    # proxy is downstream of the two SMEM buffers.
    resource_dependency_graph = {
        smem_a:  [gmem_a, work_queue],
        smem_b:  [gmem_b, work_queue],
        proxy:   [smem_a, smem_b, work_queue],
        tmem_c:  [proxy, work_queue],
    }

    @schedule
    def sync_schedule(smem_a, smem_b, proxy) -> None:      # wait-only consumer
        with domain_loop(0, num_k_tiles, 1):
            smem_a.wait()
            smem_b.wait()
            proxy.acquire()
            proxy.signal_ready()
            proxy.commit()

    @schedule
    def mma_schedule(proxy, smem_a, smem_b, tmem_c) -> None:  # proxy consumer
        with domain_loop(0, num_k_tiles, 1):
            proxy.wait()
            desc_a = smem_a.build_desc()       # work, no direct wait
            desc_b = smem_b.build_desc()
            tmem_c.mma(desc_a=desc_a, desc_b=desc_b)
            smem_a.release()
            smem_b.release()
            proxy.release()

Notes:

- What makes this safe is **transitivity in the dependency graph**: a resource
  declared downstream of the buffers transitively depends on them, so a ``wait``
  on that downstream resource guarantees the buffers are ready.  This is why the
  ``wait`` and the ``release`` can sit in **different tasks** -- the work task
  inherits the buffers' readiness through the graph instead of waiting on them
  directly.
- The buffers' ``release`` must still appear in **some** task so their producers
  can reuse the stage; it need not be the task that issued the ``wait``.
- A task that waits without releasing is a *wait-only consumer*; TS advances its
  pipeline state on the wait automatically so it tracks the right stage.
- If the wait and the release need different CTA signaling (e.g. wait on all CTAs
  but release on the leader CTA only), set ``consumer_wait_signaling_threads`` on
  the ``PipelineConfig`` -- it overrides only the wait side and must differ from
  ``consumer_signaling_threads`` (see :ref:`rts_pipelines`).

Interleaved Pipelines
---------------------

An *interleaved* pipeline partitions one set of ``num_stages`` barriers into
lanes that advance by ``interleave_stride``.  A lane can be owned either by one
warp in a multi-warp task or by one task in a group whose loop domains are
split across the lanes (see ``interleave_stride`` in :ref:`rts_pipelines` for
the lane arithmetic).

To use it correctly:

- Set ``interleave_stride`` to the number of lanes sharing the barriers.  A
  single ``int`` applies the same stride to every role; a 4-tuple
  ``(producer_acquire, producer_commit, consumer_wait, consumer_release)``
  controls each role independently.  An asymmetric acquire/commit pair requires
  ``advance_on_acquire=True`` and separate tasks for those roles.  An asymmetric
  wait/release pair similarly requires ``advance_on_wait=True`` and separate
  tasks.
- Make ``num_stages`` divisible by every role's stride.
- For *warp-lane* interleaving, each task that drives an interleaved role has
  ``num_warps == interleave_stride``.  Warp ``i`` owns lane
  ``warp_idx - warp_start``.
- For *domain-lane* interleaving, create one sibling task per lane.  Each task
  has a compile-time ``domain_start`` in ``[0, interleave_stride)`` and
  ``step == interleave_stride``; it owns lane
  ``domain_start % interleave_stride``.  Its ``num_warps`` must differ from the
  stride so TS can distinguish this mode.  The opening and closing strides on
  every domain-interleaved side must match.
- ``AsyncAsync``, ``TmaAsync``, ``TmaUmma``, ``UmmaAsync``, and ``AsyncUmma``
  support interleaving. ``TmaAsync`` is limited to single-CTA pipelines;
  ``UmmaAsync`` supports only consumer-side interleaving and ``AsyncUmma`` only
  producer-side interleaving.  ``UmmaUmma`` and ``ClcFetchAsync`` do not support
  interleaving.

.. code-block:: python

    cfg = PipelineConfig.create_tma_umma_pipeline_cfg(
        num_stages=8,
        num_bytes=tile_bytes,
        producer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread),
        consumer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread),
        cta_layout_vmnk=cta_layout_vmnk,
        interleave_stride=4,        # 4 warps share the 8 stages (lanes 0..3)
    )
    # The task using this resource is declared with num_warps=4, so its four
    # warps own lanes 0..3.

A per-role tuple interleaves only one side.  Here a single dense producer warp
feeds four interleaved consumer-wait warps; ``advance_on_wait`` is required so
the wait and release cursors can advance at different strides:

.. code-block:: python

    cfg = PipelineConfig.create_tma_async_pipeline_cfg(
        num_stages=8,
        num_bytes=tile_bytes,
        producer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread),
        consumer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread),
        cta_layout_vmnk=cta_layout_vmnk,
        advance_on_wait=True,
        interleave_stride=(1, 1, 4, 1),  # only consumer_wait is interleaved
    )
    # The wait task is declared with num_warps=4; the dense producer and the
    # release task each use num_warps=1.

Domain-lane interleaving instead assigns disjoint loop iterations to sibling
tasks.  This abbreviated example uses two four-warp softmax tasks; one handles
even tiles and the other handles odd tiles while both share the same score and
probability pipelines:

.. code-block:: python

    NUM_LANES = 2

    # Consumer and producer role pairs match because both resources derive
    # their lane from each task's domain_start.
    scores_cfg = PipelineConfig.create_umma_async_pipeline_cfg(
        ...,
        interleave_stride=(1, 1, NUM_LANES, NUM_LANES),
    )
    probs_cfg = PipelineConfig.create_async_umma_pipeline_cfg(
        ...,
        interleave_stride=(NUM_LANES, NUM_LANES, 1, 1),
    )

    def make_softmax_task(lane, warp_idx):
        @schedule
        def softmax_lane(scores, probs):
            with domain_loop(lane, num_k_tiles, NUM_LANES):
                scores.wait()
                scores.compute_softmax()
                probs.acquire()
                probs.store()
                probs.commit()
                scores.release()

        return Task(
            src_resources=[scores],
            dst_resources=[probs],
            warp_idx=warp_idx,
            num_warps=4,  # differs from NUM_LANES: select domain-lane mode
            schedule=softmax_lane(scores, probs),
            name=f"SoftmaxLane{lane}",
        )

    softmax_even = make_softmax_task(lane=0, warp_idx=0)
    softmax_odd = make_softmax_task(lane=1, warp_idx=4)

Leader-Routed Completions
-------------------------

By default every producer warp arrives on the transaction barrier.  In a
*leader-routed* completion, a single leader -- one warp (``TaskWarpLeader``)
and/or one CTA (``CtaLeader``) -- arms the TMA transaction barrier on behalf of
all producing warps or CTAs.  The declared
``num_bytes`` must then account for the bytes of **every** producer the leader
covers, not just one.

Declare the per-warp, per-CTA byte count so TS can validate the aggregate:

.. code-block:: python

    cfg = PipelineConfig.create_tma_async_pipeline_cfg(
        num_stages=...,
        num_bytes=total_bytes,                 # sum across all covered producers
        producer_group=...,
        consumer_group=...,
        cta_layout_vmnk=cta_layout_vmnk,       # must be inspectable (a tuple)
        producer_signaling_threads=SignalingThreads.TaskWarpLeader,
        num_bytes_per_warp_per_cta=bytes_one_warp_one_cta,
    )

TS checks that ``num_bytes`` equals ``num_bytes_per_warp_per_cta`` scaled by the
number of producing warps and CTAs in the cluster.  It still cannot check the
bytes against the TMA instructions that were actually issued inside the work body (see
the verification gaps in :ref:`rts_validation`).
