.. _rts_schedules:

Schedules
=========

Overview
--------

A TS schedule function is a Python function decorated with ``@schedule``.  It
*records* resource method calls; it does not run them.  Calling the decorated
function instantiates a :class:`Schedule` that you pass to
``Task(schedule=...)``.

A schedule must obey these structural rules:

- At most one ``domain_loop`` per schedule (the domain loop).
- At most one ``work_tile_loop`` per schedule.
- At most one ``while_true_loop`` per schedule.
- ``domain_loop`` and ``while_true_loop`` cannot both appear in the same
  schedule (different tasks in one kernel may mix them).

Declaring a Schedule
--------------------

A schedule function takes the resources that participate in it as parameters and
returns nothing.  Inside the body the developer calls producer/consumer methods and
special synchronization methods on those resources to record the schedule.

.. code-block:: python

    @schedule
    def schedule_fn(input_gmem, output_gmem) -> None:
        ...   # record resource method calls on the parameters

    task = Task(..., schedule=schedule_fn(input_gmem_res, output_gmem_res))

The arguments passed when calling ``schedule_fn`` are the actual resource
objects the task operates on.

Manual Pipeline State
---------------------

``@schedule(manual_state=True)`` exposes pipeline cursors as schedule values.
Create them with ``resource.producer_state()`` or
``resource.consumer_state()``, pass ``state=`` to every stage-bearing pipeline
operation and work call, and record cursor motion with ``state.advance()``.

.. code-block:: python

    @schedule(manual_state=True)
    def load_schedule(gmem, smem):
        producer = smem.producer_state()
        with domain_loop(0, num_tiles, 1):
            coord = gmem.compute_coords()
            smem.acquire(state=producer)
            smem.tma_load(coord=coord, state=producer)
            smem.commit(state=producer)
            producer.advance()

``previous()`` creates a read-only view of the preceding ring stage.
``at(stage_idx)`` selects a physical buffer for work; it is not a wait
cursor and is rejected on acquire, wait, commit, and release. Multiple
calls to a state factory create independent cursor slots, which supports
deferred release.

============================  =============================
Call kind                     ``state=`` in manual mode
============================  =============================
Pipeline operations           Required
Producer/consumer work         Required
Auxiliary work                 Required
Non-pipelined/WorkQueue work   Forbidden
Barrier resources              Forbidden
============================  =============================

Manual state cannot be combined with ``advance_on_acquire`` or
``advance_on_wait``. Spell those configurations with explicit cursor slots,
``previous()`` views, and ``advance()`` nodes. ``at()`` does not know correct
phase, so is rejected on barrier operations. Default ``@schedule`` functions remain source-compatible:
finalization desugars their implicit cursor behavior into the same bindings
and ``StateAdvance`` IR consumed by lowering and validation.

Domains
-------

``domain_loop(start, end, step, *, unroll=1)`` defines the loop over the
domain ``range(start, end, step)``.  The current iteration index reaches work
methods through ``stage_info.loop_offset`` (the loop index is read from
``StageInfo``; it is never passed as data).

- ``start``, ``end``, ``step`` -- the loop bounds.  ``start`` and ``step``
  will default to ``0`` and ``1``, respectively, just like Python's
  ``range``.  For a dynamic per-tile domain, pass a ``Task`` method as a bound
  instead of a static integer, which will be invoked for each work tile -- see
  `Dynamic Domain`_.
- ``unroll`` -- unroll hint; defaults to ``1`` (no unrolling).  Pass ``None`` to
  let the compiler choose.

The following schedule uses a grid-stride domain where each thread processes
indices separated by the grid size:

.. code-block:: python

    @schedule
    def schedule_fn(input_gmem: InputGmemResource,
                    output_gmem: OutputGmemResource) -> None:
        threads_per_block = num_warps * 32
        start = bx * threads_per_block + tx
        step = gdimx * threads_per_block
        with domain_loop(start, num_entries, step, unroll=unroll):
            res = input_gmem.get_item()
            output_gmem.set_item(data=res)

Data Flow Between Work Methods
------------------------------

Values move between work methods through ``TaskLocalVariable`` tokens.  A
consumer work method that declares ``returns=`` produces a token when it is
called in the schedule; a producer work method consumes that token as an
argument.  In the example above, ``input_gmem.get_item()`` returns the ``res``
token and ``output_gmem.set_item(data=res)`` consumes it.  The loop index is not
a token -- work methods read it from ``stage_info.loop_offset``.  See
:ref:`rts_resources` for how resources declare these variables.

First, Last, and Periodic Iteration
-----------------------------------

``d.first_iter()`` and ``d.last_iter()`` are context managers that run the
operations inside them **only** on the first or last iteration of the domain
loop.  Periodic work uses ``d.every(period, start=0)``, which fires on
zero-based iteration counts ``start, start + period, start + 2 * period, ...``
independent of the loop's concrete ``start`` and ``step``.  Everything outside
these guarded blocks runs on every iteration.  Use the first iteration for
one-time setup (such as an initial acquire), periodic guards for cadence work
(such as advancing a metadata window every ``N`` tiles), and the last iteration
for draining (such as a final commit).  When the loop runs for a single
iteration, that iteration is both the first and the last, so both first/last
blocks execute; a matching periodic guard also runs when count ``0`` matches its
cadence (see :ref:`rts_validation` for the implications).

.. code-block:: python

    @schedule
    def guarded_schedule(smem, page_offsets) -> None:
        with domain_loop(0, num_iters, 1) as d:
            with d.first_iter():
                smem.try_acquire()
            with d.every(4, start=0):
                page_offsets.advance()
            smem.acquire()
            smem.producer_work()
            with d.last_iter():
                smem.commit()

General Conditional Execution
-----------------------------

``when_true(condition)`` and ``when_false(condition)`` are the general block
openers for data-dependent runtime conditions.  Use the domain-loop handle
methods above for iteration-derived conditions, so each guard is tied to the
active ``domain_loop()``.  Data-dependent runtime conditions use ordinary work
outputs declared with ``@consumer_work(returns=...)``; auxiliary methods are a
good fit when the method only computes guard state.  The verifier correlates
them with an auto-derived ``(resource, method, result)`` key or an explicit
``key=`` you provide when two tasks must share the same runtime value.

.. code-block:: python

    from cutlass.experimental.task_scheduling import when_true

    @schedule
    def conditional_schedule(page_offsets, smem) -> None:
        with domain_loop(0, num_iters, 1) as d:
            smem.acquire()
            needs_epilogue = smem.needs_epilogue()
            with when_true(needs_epilogue):
                smem.epilogue()
            smem.commit()

Every runtime condition result must be backed by a ``TaskLocalVariable`` slot.
The same stored token drives runtime execution and exhaustive static schedule
validation.  There is no separate validation-only condition; pass the same
``key=`` on ``when_true`` / ``when_false`` (or reuse the same stored token) when
two tasks must branch on one shared runtime value.  Boolean slots are read
directly; integer-like slots are false only when their stored value is zero.

When one runtime instruction produces multiple guard values, declare one
``TaskLocalVariable`` slot per result with ``@consumer_work(returns=(...))``.
The schedule records one work step that stores every returned value, and each
``when_true`` / ``when_false`` block reads its selected stored result instead of
calling the producing method again.

Combining Conditions
~~~~~~~~~~~~~~~~~~~~~~~~~~~

A guard often depends on more than one thing at a time.  Conditions can be
combined with ``&`` (and), ``|`` (or), and ``~`` (not), so the whole test fits
in one ``when_true`` instead of a nested block per term.  Python's ``and``,
``or``, and ``not`` cannot be overloaded, so they are rejected with an error
that points you at the operators.

.. code-block:: python

    with domain_loop(0, num_iters, 1) as d:
        ready = smem.is_ready()
        urgent = smem.is_urgent()
        with when_true((ready & ~urgent) | d.first):
            smem.handle_tile()

Iteration conditions have two forms.  ``d.first_iter()``, ``d.last_iter()``,
and ``d.every(...)`` are context managers, which is what you want when the
guard has a single term.  ``d.first``, ``d.last``, and
``d.every_pred(period, start=0)`` are the same conditions as plain values, and
those are the ones the operators accept -- a context manager cannot be an
operand.  The module-level ``FIRST_ITER`` and ``LAST_ITER`` constants can be
mixed into an expression as well.

``~`` on an iteration condition means what it says and nothing more:
``~FIRST_ITER`` is every iteration but the first, ``~LAST_ITER`` is every
iteration but the last, and ``~d.every_pred(4)`` is the iterations that fall
off that cadence.  It does not turn "first" into "last".  A loop that runs once
has an iteration that is both first and last, so ``~FIRST_ITER`` and
``~LAST_ITER`` are both false there.  ``when_false(expr)`` is the same thing as
``when_true(~expr)``.
Nesting ``when_true`` blocks still works and means the same as ``&``.  When two
guards have to be treated as the same runtime value, pass ``key=``.  On a
combined expression the key applies to each runtime leaf and leaves the
iteration conditions alone -- an expression built only from iteration
conditions has nothing to correlate, so keying it is an error.


Dynamic While Loops
-------------------

``while_true_loop(init=..., advance=..., verify_num_iters=...)`` records a
dynamic loop whose cursor comes from consumer work hooks rather than a
compile-time ``range``.  ``init`` and ``advance`` must be named consumer work
methods that each return one named ``TaskLocalVariable`` (the loop cursor).
The body repeats until a ``loop.break_loop()`` path fires.

The **exit formula** is not a separate API.  Each ``break_loop()`` records the
opaque ``when_true`` / ``when_false`` guards that dominate the call (nested
blocks become a conjunction).  The loop exits iff **any** captured break clause
holds:

- ``with when_true(exit): loop.break_loop()`` → exit iff ``exit``
- two breaks under ``when_true(done)`` and ``when_true(error)`` →
  ``done ∨ error``
- nested ``when_true(a): when_true(b): loop.break_loop()`` → ``a ∧ b``
- unconditional ``break_loop()`` → always true (modeled as a single iteration)

Extra flags that wrap ``break_loop()`` **are** part of the exit.  If a
highlight marker must stay free of the exit formula, put it *after* the
break in the same guarded block::

    with when_true(exit_now):
        loop.break_loop()
        with when_true(is_highlight):
            trace.mark_highlight()

not::

    with when_true(exit_now):
        with when_true(is_highlight):
            loop.break_loop()

``verify_num_iters`` selects the modeled iteration counts the verifier
explores.  ``None`` defaults to ``(1, 2)``; an ``int N`` checks exactly ``N``;
a tuple such as ``(1, 2, 3)`` checks each count.  Each count ``N`` is modeled
as ``retry^(N-1) + break``.  Unconditional ``break_loop()`` with any ``N > 1``
is rejected because there is no retry assignment.

The current cursor reaches work methods as ``stage_info.loop_offset``.  Bounds
are ``LOOP_STATE_UNAVAILABLE`` inside a while loop.

.. code-block:: python

    from cutlass.experimental.task_scheduling import when_false, when_true, while_true_loop

    @schedule
    def store_schedule(smem, output_gmem) -> None:
        with while_true_loop(
            init=smem.retry_init,
            advance=smem.retry_advance,
            verify_num_iters=2,
        ) as loop:
            rows_done = smem.rows_done()
            with when_true(rows_done):
                loop.break_loop()
            with when_false(rows_done):
                smem.try_wait()
                smem.wait()
                val = smem.read_smem()
                smem.release()
                output_gmem.store(smem_val=val)

A schedule may contain a ``domain_loop`` or a ``while_true_loop``, not both.
Nesting either inside the other is rejected.  Inside
``work_tile_loop(skip_if=...)``, the while loop must sit in ``wtl.skippable()``.


Persistent Scheduling
---------------------

Persistent schedules wrap the repeating work in ``work_tile_loop(wq)`` over a
``WorkQueue``. It is the programmer's responsibility to ensure that every
participating task waits, advances, and releases the queue at the same logical
boundary.  The typical bookkeeping sequence is:

.. code-block:: python

    wq.try_wait()
    wq.wait()
    wq.get_and_advance_work_tile()
    wq.release()

Static persistent scheduling lowers the queue state to lightweight arithmetic.
CLC dynamic persistent scheduling uses a ``WorkQueue`` that owns a
``ClcFetchAsync`` pipeline: a dedicated scheduler task drives its producer
(fetch) side, while every data task consumes work tiles from it.

Dynamic Domain
--------------

When any domain loop bound is **not the same for every work tile** and must be
computed at runtime per tile, use a dynamic domain.  Most commonly, this applies
to the upper bound of the domain loop.  In this case, provide a ``Task`` subclass
with a ``get_domain_size(self, tile_coord)`` method that returns the per-tile
upper bound, and pass that provider as the ``domain_loop``'s ``end`` bound.
Note that the other bounds are also allowed to be dynamic, and the function name
can be arbitrary. The snippet below shows a variable-length tile whose bound is
computed from an offsets array:

.. code-block:: python

    class DynamicDomainTask(Task):
        def __init__(self, offsets, **kwargs):
            super().__init__(**kwargs)
            self._offsets = offsets

        @cute.jit
        def get_domain_size(self, tile_coord):
            return self._offsets[tile_coord[0] + 1] - self._offsets[tile_coord[0]]

    @schedule
    def main_schedule(src, dst, wq) -> None:
        with work_tile_loop(wq):
            with domain_loop(
                tx,
                DynamicDomainTask.get_domain_size,
                threads_per_block,
            ):
                val = src.load()
                dst.store(val=val)
            wq.try_wait()
            wq.wait()
            wq.get_and_advance_work_tile()
            wq.release()

Skippable Tiles
---------------

``wtwl.skippable()`` is a context manager that runs the operations inside it
**only** on tiles that are not skipped (as decided by the ``skip_if``
predicate); everything outside it runs on every tile.  Use it to wrap the
data-work region while keeping WorkQueue bookkeeping outside, so every launched
CTA still advances the queue.

Where a dynamic domain hands the loop a per-tile callback that *computes* a
bound, ``skip_if`` hands the work-tile loop a per-tile predicate that *decides*
whether the tile runs its skippable work.  Unlike the domain getter's fixed
``get_domain_size(self, tile_coord)`` signature, ``skip_if`` accepts several
forms:

- a ``WorkQueue`` method or a plain function/lambda
- taking either ``(work_queue, work_tile)`` or just ``(work_tile)``

The snippet below marks only the row-copy work as skippable and keeps queue
bookkeeping outside the skippable region:

.. code-block:: python

    @schedule
    def copy_schedule(copy_res: MemoryResource, wq: WorkQueue) -> None:
        with work_tile_loop(
            wq, skip_if=OversubscribedCopyWorkQueue.skip_work_tile_if
        ) as wtwl:
            with wtwl.skippable(), domain_loop(0, num_rows, 1):
                copy_res.copy_tile_row()
            wq.try_wait()
            wq.wait()
            wq.get_and_advance_work_tile()
            wq.release()

Forwarding Contextual Information
---------------------------------

A work method might require **context that depends on
the call site**. A schedule can forward such values as keyword-only
``cutlass.Constexpr[...]`` parameters:

- **Declare** a keyword-only ``cutlass.Constexpr[...]`` parameter on
  the work method.  The parameter is allowed to declare a default value.
- **Pass** a literal for it at the schedule call site, e.g.
  ``smem.load(slot_index=1)``.  The literal is captured on that call and forwarded
  into the work body when the schedule is traced.

.. code-block:: python

    @schedule
    def schedule_fn(input_gmem: InputGmemResource,
                    output_gmem: OutputGmemResource) -> None:
        frag0 = input_gmem.load(slot_index=0)
        output_gmem.store(frag=frag0, slot_index=1)
        frag1 = input_gmem.load(slot_index=1)
        output_gmem.store(frag=frag1, slot_index=0)

Both ``load`` / ``store`` pairs invoke the same methods; only the compile-time
``slot_index`` literal differs, and each call records its own entry bound to that
value.

Captured Control Flow vs Trace-Time Python
------------------------------------------

The runtime structure of a schedule is expressed only with ``with`` context
managers: ``domain_loop``, ``work_tile_loop``, ``wtwl.skippable()``,
``d.first_iter()``, and ``d.last_iter()``.

Plain Python ``for`` and ``if`` statements inside a ``@schedule`` are
**trace-time metaprogramming**.  They must be compile-time known and are
unrolled into the recorded schedule; they do not become runtime loops or guards.

.. code-block:: python

    @schedule
    def store_schedule(tmem_c, gmem_d, wq) -> None:
        with work_tile_loop(wq):
            with domain_loop(0, num_k_tiles, 1):
                pass
            for subtile_idx in cutlass.range_constexpr(subtile_cnt):
                t2r_rmem = tmem_c.load_subtile(subtile_idx=subtile_idx)
                gmem_d.store(t2r_rmem=t2r_rmem, subtile_idx=subtile_idx)

Here the ``for`` loop is compile-time metaprogramming: because ``subtile_cnt``
is compile-time known, it records one ``load_subtile`` / ``store`` pair per
iteration -- each bound to its own compile-time ``subtile_idx`` (as in
`Forwarding Contextual Information`_) -- rather than a runtime loop in the
captured schedule.

Scheduling Shapes
-----------------

TS supports three main scheduling shapes:

**Non-persistent** -- no ``WorkQueue``.  The launch grid maps directly to logical tiles.

**Static persistent** -- ``work_tile_loop(wq)`` over a ``WorkQueue`` that assigns
the next tile with local arithmetic.  There is **no dedicated scheduler task**:
every task simply ends each work-tile iteration with the standard queue epilogue,
waiting for the tile, advancing to the next one, and releasing the queue:

.. code-block:: python

    with work_tile_loop(wq):
        with domain_loop(0, num_k_tiles, 1):
            ...                              # the task's data work
        wq.try_wait()
        wq.wait()
        wq.get_and_advance_work_tile()
        wq.release()

**Dynamic persistent** -- the ``WorkQueue`` owns a ``ClcFetchAsync`` pipeline
and a **dedicated scheduler task** fetches work tiles from hardware.
A typical scheduler task does no work; it simply *acquires* the queue,
*fetches* the next tile, *commits*, and only then runs the same wait /
advance / release epilogue:

.. code-block:: python

    @schedule
    def scheduler_schedule(wq: WorkQueue) -> None:
        with work_tile_loop(wq):
            wq.try_acquire()
            wq.acquire()
            wq.fetch_work_tile()
            wq.commit()
            wq.try_wait()
            wq.wait()
            wq.get_and_advance_work_tile()
            wq.release()

Every other (data) task uses the same standard epilogue shown above for the
static case -- ``try_wait`` / ``wait`` / ``get_and_advance_work_tile`` /
``release`` -- so a data-task body is identical whether the queue is static or
CLC dynamic; only the presence of the scheduler task and the queue's pipeline
differ.
