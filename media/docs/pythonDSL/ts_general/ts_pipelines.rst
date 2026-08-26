.. _rts_pipelines:

Pipeline Types
==============

A pipelined resource guards its physical storage so that a producer and a
consumer do not access the same data at the same time.  The
producer brackets its writes with ``acquire`` / ``commit`` and the consumer
brackets its reads with ``wait`` / ``release``.  A :class:`PipelineConfig`
attached to the resource (``pipeline_config=``) selects *which* barrier protocol
TS emits for those brackets.

Naming convention
-----------------

Pipeline type names follow the ``<Producer><Consumer>`` convention: the **first**
token is the kind of operation that *writes into* the resource, and the
**second** token is the kind of operation that *reads out of* it.  For example,
``TmaAsync`` is a **TMA** producer feeding an **async-thread** consumer, and
``TmaUmma`` is a **TMA** producer feeding a **UMMA** (tensor-core) consumer.

The operation kinds are:

- **Async** -- plain async threads.  The producer arrives on the barrier with an
  ``mbarrier`` arrive (``AsyncThread``) or a ``cp.async`` arrive
  (``AsyncLoad``); the consumer is a warp that reads SMEM.
- **Tma** -- a TMA bulk-copy fills the buffer; completion is tracked by a
  transaction byte count (``num_bytes``) rather than a thread arrival count.
- **Umma** -- a ``tcgen05`` MMA (or UTCCP) writes or reads TMEM/SMEM; the atom
  itself signals the barrier.
- **Dynamic scheduling** -- a dynamic fetch.

Choosing the right type is kernel developer responsibility
----------------------------------------------------------

The kernel developer must pick the pipeline type that matches the **actual
hardware operation on each side** -- what physically writes the buffer and what
physically reads it.
TS takes that declaration at face value and uses it to:

- emit the correct barrier sequence for ``acquire`` / ``commit`` /
  ``wait`` / ``release``;
- size and place the barrier storage for ``num_stages``;
- check that the transaction bytes (``num_bytes``) cover every producer warp
  across the whole cluster;
- check that the number of arriving producer threads and consuming threads
  matches the producer/consumer cooperative-group sizes and the cluster shape
  (``cta_layout_vmnk``);
- verify that the tasks actually producing and consuming the resource agree with
  this configuration.

If the declared type does not match the real operation, the kernel hangs
or races on hardware.  See :ref:`rts_validation`.

Supported pipeline types
------------------------

.. list-table::
   :header-rows: 1
   :widths: 16 28 40 16

   * - Type
     - Producer -> Consumer
     - Typical use
     - Factory
   * - ``AsyncAsync``
     - async threads -> async threads
     - SMEM filled from registers / cpasync and read by async threads (no TMA, no MMA).
     - ``create_async_async_pipeline_cfg``
   * - ``TmaAsync``
     - TMA -> async threads
     - SMEM tile loaded by TMA and consumed by async threads (copy, epilogue
       staging).
     - ``create_tma_async_pipeline_cfg``
   * - ``TmaUmma``
     - TMA -> UMMA
     - A/B operand SMEM loaded by TMA and consumed by a ``tcgen05`` MMA
       (the GEMM mainloop).
     - ``create_tma_umma_pipeline_cfg``
   * - ``UmmaAsync``
     - UMMA -> async threads
     - TMEM accumulator produced by MMA and consumed by the async threads
       (TMEM-to-register).
     - ``create_umma_async_pipeline_cfg``
   * - ``AsyncUmma``
     - async threads -> UMMA
     - SMEM filled by an async / ``cp.async`` producer and consumed by a
       ``tcgen05`` MMA.
     - ``create_async_umma_pipeline_cfg``
   * - ``UmmaUmma``
     - UMMA / UTCCP -> UMMA
     - A TMEM copy producer feeding an MMA consumer.
     - ``create_umma_umma_pipeline_cfg``
   * - ``ClcFetchAsync``
     - CLC fetch -> async threads
     - The dynamic fetch queue of a dynamic-persistent scheduler.
     - ``create_clc_fetch_async_pipeline_cfg``

Common configuration fields
---------------------------

Every factory returns a :class:`PipelineConfig`.  The simplest fields are:

- ``num_stages`` -- pipeline depth (number of buffering stages).
- ``num_bytes`` -- expected transaction byte count per stage; used by TMA / CLC
  producers and ``0`` otherwise.
- ``producer_group`` / ``consumer_group`` -- the ``CooperativeGroup`` objects
  that define how many threads act on each side.
- ``cta_layout_vmnk`` -- the cluster decomposition; required for UMMA and CLC
  pipelines and for any clustered (multi-CTA) pipeline.
- ``num_bytes_per_warp_per_cta`` -- per-producer-warp, per-CTA byte count for
  leader-routed clustered TMA completion.

The remaining fields control *who* signals barriers and *when* the stage index
advances, and are explained below.

Signaling threads
~~~~~~~~~~~~~~~~~~

``producer_signaling_threads`` and ``consumer_signaling_threads`` decide *which*
threads in the cooperative group actually execute the barrier instructions (the
producer's acquire / commit and the consumer's wait / release).  The three modes
are:

- ``All`` (default) -- every thread in the cooperative group signals.  Correct
  for ordinary single-CTA pipelines.
- ``CtaLeader`` -- only CTA 0 of the cluster signals.  Use it when a single CTA
  drives a multi-CTA (clustered) pipeline, e.g. a 2-CTA MMA producer where one
  CTA issues tensor cores and arms the full barrier.
- ``TaskWarpLeader`` -- only the first warp of the task arms the producer-side
  transaction barrier.  This is orthogonal to CTA ownership and may be combined
  with ``CtaLeader`` (``CtaLeader | TaskWarpLeader``).

``All`` is exclusive and cannot be combined with the others; the only valid
combinations are ``All``, ``CtaLeader``, ``TaskWarpLeader`` and
``CtaLeader | TaskWarpLeader``.

``consumer_wait_signaling_threads`` overrides only the wait side, leaving the
release side on ``consumer_signaling_threads``.  Set it for the split-consumer
pattern, where one task waits on all CTAs while another releases on the leader
CTA only.

TS checks the signaling set against the cooperative-group size and the cluster
shape; see :ref:`rts_validation`.

Interleaved barriers (``interleave_stride``)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

By default a warp that drives a pipeline walks all ``num_stages`` barriers in
order.  ``interleave_stride`` lets several warps share one set of ``num_stages``
barriers: each warp starts at its own offset and advances the stage index by the
stride.  The stride must evenly divide ``num_stages``.

For example, with ``num_stages=4`` and ``interleave_stride=2``, two warps share
the four slots:

- warp 0 visits stages ``0, 2, 0, 2, ...``
- warp 1 visits stages ``1, 3, 1, 3, ...``

Each warp accesses the barrier at the stride specified here, so the two warps
never touch the same slot at the same time.

``interleave_stride`` accepts two forms:

- A single ``int`` applies the same stride to every role.
- A 4-tuple assigns role-specific strides, interpreted as
  ``(producer_acquire, producer_commit, consumer_wait, consumer_release)``.
  Each entry must independently divide ``num_stages``.  Different acquire and
  commit strides require ``advance_on_acquire=True`` and separate tasks for the
  two roles.  Different wait and release strides require
  ``advance_on_wait=True`` and separate tasks.  For example, ``(1, 1, 4, 1)``
  lets four wait warps feed a separate dense release task.

Normally the lane is the task-local warp index, and a task driving a role with
stride ``N`` has ``N`` warps.  A group of sibling tasks may instead split its
loop into ``N`` domain lanes by using compile-time starts ``0..N-1`` and
``domain_loop(start, end, N)``.  Domain-lane mode requires matching
acquire/commit or wait/release strides on each side that uses it.  See
:ref:`rts_patterns` for the complete setup.

Interleaving is supported by ``AsyncAsync``, ``TmaAsync``, ``TmaUmma``,
``UmmaAsync``, and ``AsyncUmma``.  ``TmaAsync`` interleaving is limited to a
single-CTA pipeline.  ``UmmaAsync`` supports interleaving only on its async
consumer side, while ``AsyncUmma`` supports it only on its async producer side.
``UmmaUmma`` and ``ClcFetchAsync`` do not support interleaving.

Split stage advancement (``advance_on_wait`` / ``advance_on_acquire``)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Normally the stage index advances at the *end* of a bracket: the consumer
advances on ``release`` and the producer advances on ``commit``.  One
pipeline-state counter per side is enough, because the work always sits between
the opening op and the advancing closing op.

These flags split that single counter into two so the stage can advance *early*,
at the *start* of the bracket, while a second lagging counter performs the close:

- ``advance_on_wait`` (consumer side) -- ``wait`` advances the stage and records
  the waited stage; a separate state is used by ``release`` to close the older
  stage.  This lets the consumer issue the next ``wait`` before releasing the
  current stage, for deeper overlap.
- ``advance_on_acquire`` (producer side) -- ``acquire`` records the acquired
  stage and advances the producer state immediately; ``work`` uses the recorded
  stage and ``commit`` closes a separate lagging commit state.

In both cases TS keeps **two** counters -- one for the opening op
(``wait`` / ``acquire``) and one for the closing op (``release`` / ``commit``) --
instead of one.  Ordinary warp-lane schedules may assign those counters
different strides when separate tasks drive the two roles.  Domain-lane
schedules require the opening and closing counters on that side to use the same
stride because one task-derived lane owns both states.

Async producer operation (``AsyncThread`` vs ``AsyncLoad``)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

For the async-producer pipelines the developer chooses how the producer arrives on the full
barrier, via ``async_producer_op`` (on ``AsyncAsync``) or
``umma_consumer_producer_op`` (on ``AsyncUmma``):

- ``AsyncThread`` (default) -- regular threads signal completion with an
  ``mbarrier`` arrive *after* they finish writing data.  Use it when the
  producer is ordinary register stores to shared memory.
- ``AsyncLoad`` -- matches ``cp.async`` producers: the copy itself
  arrives on the local per-CTA full barrier via ``cp.async.mbarrier.arrive``, so
  the barrier completes when the async copies land rather than when the issuing
  thread reaches the arrive.

Constructing a config
---------------------

Do not build :class:`PipelineConfig` directly; call a factory and attach the
result to the resource:

.. code-block:: python

    pipeline_config = PipelineConfig.create_tma_umma_pipeline_cfg(
        num_stages=num_ab_stages,
        num_bytes=tile_bytes,
        producer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread),
        consumer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread),
        cta_layout_vmnk=cta_layout_vmnk,
    )

    smem_a = SmemAResource(..., pipeline_config=pipeline_config, name="smem_a")

TS allocates the barrier storage and patches ``barrier_ptr`` during setup, so
``barrier_ptr`` is normally left unset.
