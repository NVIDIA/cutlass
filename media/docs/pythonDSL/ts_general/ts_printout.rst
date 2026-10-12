.. _rts_printout:

Reading the Printed Output
==========================

Constructing a :class:`TaskManager` runs ``print_and_verify()`` immediately.
With the default ``verbose=True`` it prints, in order:

#. the **schedule table** (one column per task, simulated step by step);
#. the **register budget** summary;
#. the **SMEM / TMEM usage** summary and the allocator usage report;
#. the **exhaustive checker** output, when it is enabled.

All of this is informational and is silenced with ``TaskManager(..., verbose=False)``.
Verification *errors* are raised regardless of ``verbose``; the printout just
makes the reasoning visible.  This page explains each block.

Schedule table
--------------

The schedule table shows every task side by side and walks the combined
``Head + Loop + Tail`` schedule one step at a time from left to right, the way
concurrent warps might execute it.  Each task is a column headed by
``name[warp_start:warp_end)``; section titles are centered between ``=`` rules.

.. code-block:: text

===============================================================
                                                                                              
|         MmaTask[5:6)         |        StoreTask[0:4)        |
                                                                                              
==============>   Full (Head + Loop + Tail)   <===============
                                                                                              
| SmemAb       ConsAux    H  0 | TmemC        ConsAux    H  0 |
| TmemC        ProdAux    H  0 | GmemD        ProdAux    H  0 |
| TmemC        ProdAux    H  1 | TmemC        ConsTrW    T  0 |
| TmemC        ProdTrA    H  0 |                              |
| TmemC        ProdAcq<-  H  0 |                              |
| SmemAb       ConsTrW       0 |                              |
| SmemAb     ->ConsWai       0 |                              |
| SmemAb       ConsWrk       0 |                              |
| TmemC        ProdWrk       0 |                              |
| SmemAb     <-ConsRel       0 |                              |
| TmemC        ProdCmt->  T  0 | TmemC      ->ConsWai    T  0 |
|                              | TmemC        ConsWrk    T  0 |
|                              | GmemD        ProdWrk    T  0 |
|                              | GmemD        ProdWrk    T  1 |
|                              | TmemC      <-ConsRel    T  0 |
                                                               
===============> End Full (Head + Loop + Tail) <===============

    Phase tags:  H — Head (prefetch, before the loop)  |  F — FirstIter
      (first iteration only)  |  L — LastIter (last iteration only)  |
      T — Tail (drain, after the loop)

Each cell is ``<resource> <stage> <phase-tag> <call-idx>``:

- **resource** -- the resource the step touches.
- **stage** -- the pipeline operation (``ConsumerWait``, ``ProducerCommit``, ...).
- **phase-tag** -- ``H`` head, ``F`` first iteration, ``L`` last iteration,
  ``T`` tail; blank for a normal loop-body step.
- **call-idx** -- the call index of the step's schedule slot (distinguishes
  repeated work for the same resource/stage in the same phase).  A schedule that
  needs the index inside the work body passes it explicitly as a compile-time
  argument (see :ref:`rts_constexpr_work_args`).

The simulator also reconciles producer/consumer credits.  If a step can never
make progress it is printed with ``is blocked!`` and the run fails:

.. code-block:: text

     Smem       ConsumerWait    0 is blocked!  NOTE: if the domain is not a
       compile-time Python int, this may be a FALSE POSITIVE (domain defaults
       to 1).  Re-run with a realistic int domain via validate-only mode for
       accurate results.

Unmatched brackets are reported the same way, for example
``1x ProducerCommit from Smem not consumed!`` or
``1x ProducerAcquire from Smem not matched by ConsumerRelease!``.  See
:ref:`rts_validation`.

Register budget
---------------

TS reports the warp-group register reallocation it will request.  One line per
task shows ``num_warps x (default_per_thread - task_per_thread)``; the totals
follow:

.. code-block:: text

    Task  0 'LoadTask            ', numWarps x (defaultMaxNumRegs - numRegsPerThread) = 1 x (168 - 32) = 136
    Task  1 'StoreTask           ', numWarps x (defaultMaxNumRegs - numRegsPerThread) = 4 x (168 - 232) = -256
    Num. regs: 41984 (free reg blocks: 3)
    Reg budget: -120

- **default per-thread** is what TS hands every warp before any task-specific
  ``num_registers``.
- A task that lowers its budget *donates* registers (positive contribution); a
  task that raises it *borrows* them (negative).
- **Num. regs** is the total register-file usage for the block; it must not
  exceed the SM register file.
- **Reg budget** is the net donated/borrowed balance; a negative budget here is
  fine as long as the per-block total fits.

Mismatched budgets inside one warp group, or a per-block total over capacity,
raise an error (see :ref:`rts_validation`).

SMEM and TMEM usage
-------------------

When an allocator is attached, TS prints the totals against the hardware
capacity:

.. code-block:: text

    SMEM usage: 49408 B (data 49152 B + barriers 256 B) / 232448 B capacity
    TMEM usage: 128 columns / 512 columns capacity

``data`` is the buffer bytes laid out by the ``SmemAllocator``; ``barriers`` is
the pipeline mbarrier storage (16 B per stage).  Exceeding either capacity is an
error.

The allocator also prints a per-allocation usage report.  Aliased allocations
are marked with ``*`` and the alias groups are listed with the bytes each phase
needs; ``savings`` is the memory reclaimed by aliasing:

.. code-block:: text

    [smem-layout] Memory Usage Report
      Name                            Size  Align    Offset       End
      ──────────────────────────────────────────────────────────────
      smem_a *                        4096    128         0      4096
      smem_b *                        4096    128      4096      8192
      smem_staging *                  8192    128         0      8192
      ──────────────────────────────────────────────────────────────
      Alias group 1:
        Phase 1: smem_a (4096 B), smem_b (4096 B)
        Phase 2: smem_staging (8192 B)
      ──────────────────────────────────────────────────────────────
      Total:              8192 B
      Saved (aliasing):   8192 B

See :ref:`rts_allocators` for how the layout and alias groups are built.

Exhaustive checker
------------------

When ``exhaustive_deadlock_race_check=True`` (the default), TS runs the BFS
interleaving checker and prints its exploration.  It lists each task's schedule,
any aliased resource pairs it is watching, a timeline for completed states, and
a summary line:

.. code-block:: text

    ========================================================================
    Exhaustive interleaving checker — BFS exploration
    ========================================================================
      Task 0 (LoadTask): [ConsumerWork(InputGmem), ProducerAcquire(Smem), ...]
      Task 1 (StoreTask): [ConsumerWait(Smem), ConsumerWork(Smem), ...]
      Alias pairs:
        TmemSP <-> TmemVec
    ------------------------------------------------------------------------
    State #7  cursors=(5, 7)  ✓ COMPLETE
      timeline (12 steps):
        t  LoadTask              StoreTask
        ─  ────────              ─────────
        0  ConsumerWork(InGmem)  ·
        1  ProducerAcquire(Smem) ·
        2  ·                     ConsumerWait(Smem)
        ...
    ========================================================================
    BFS complete: 7 states explored, 1 complete, 0 deadlock(s), 0 race(s), 0 PDL order violation(s)
    Result: SAFE
    ========================================================================

- The **timeline** has one column per task; only the active task's column shows
  the operation at each time step, so reading a column top-to-bottom recovers
  that task's order with the interleaving gaps visible.
- The **summary** counts the states explored and any deadlocks, aliasing races,
  or PDL ordering violations.  ``Result: SAFE`` means no valid interleaving
  failed; ``Result: UNSAFE`` means at least one did, and an error is raised with
  details (e.g. ``WriterTask writes TmemSP vs ReaderTask cons_work TmemVec``).

If the search reaches its state cap it prints a warning instead of a proof:

.. code-block:: text

    WARNING: exhaustive checker hit max_states=100000 before completing the
    search; no concrete issue was found. Increase max_states or reduce the
    validated schedule size/main-loop length for a complete proof.

This means the search was *incomplete*, not that the schedule is safe.  Keep the
checker on in CI with a compile-time Python ``int`` domain and bump the state
limit; disable it (``exhaustive_deadlock_race_check=False``) in production
kernels for faster compilation.  See :ref:`rts_validation` for the full checker
behavior.
