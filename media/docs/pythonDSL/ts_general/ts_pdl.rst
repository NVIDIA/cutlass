.. _rts_pdl:

Programmatic Dependent Launch
=============================

Overview
--------

TS models Programmatic Dependent Launch (PDL) through synchronization-only
resources:

- ``PdlWaitBarrier.wait_griddep()`` emits the PDL wait.
- ``PdlLaunchBarrier.launch_griddep()`` emits the dependent-grid launch.

They do not carry payload variables, but they still participate in task
resource lists and dependency graph ordering.

PDL Ordering Problem
--------------------

PDL lets a successor grid start before the predecessor grid has fully
completed.  That makes the wait a correctness boundary: any successor-grid
work that reads predecessor-grid results must execute ``wait_griddep`` before
the first dependent memory access.

TS cannot infer that dependency from the address expression or resource name.
The user must declare it in the resource dependency graph.  When ``gmem_ab``
reads data produced by the predecessor grid, declare ``gmem_ab`` as depending
on ``pdl_wait_resource``.  With that edge, TS treats the
``PdlWaitBarrier`` as an ordering-only upstream resource and checks that the
wait is ordered before the dependent work.  Without that edge, TS sees
``gmem_ab`` and ``pdl_wait_resource`` as independent resources and has no
declared ordering relation to verify.

Code Walkthrough
----------------

The dependency graph must carry the PDL wait edge:

.. code-block:: python

    resource_dependency_graph = {
        gmem_ab: [pdl_wait_resource],
    }

With that graph edge declared, a schedule can emit the wait before the
PDL-dependent work and emit the launch notification after the work that should
unblock the successor grid:

.. code-block:: python

    @schedule
    def load_a_schedule(
        gmem_ab: GmemAbResource,
        smem_a: SmemAbResource,
        wq: WorkQueue,
        pdl_wait_resource: PdlWaitBarrier,
        pdl_launch_resource: PdlLaunchBarrier,
    ) -> None:
        pdl_wait_resource.wait_griddep()
        with work_tile_loop(wq):
            with domain_loop(0, num_k_tiles, 1):
                coord_k, coord_m, coord_n = gmem_ab.compute_coords()
                smem_a.try_acquire()
                smem_a.acquire()
                smem_a.tma_load_a(coord_k=coord_k, coord_m=coord_m)
                smem_a.commit()
            wq.try_wait()
            wq.wait()
            wq.get_and_advance_work_tile()
            wq.release()
        pdl_launch_resource.launch_griddep()

Ordering Rules
--------------

PDL wait resources are listed as upstream dependencies for data resources that
read predecessor-grid results.  Launch barriers are schedule-only notification
resources.

The checker rejects an enabled ``launch_griddep`` path when no
``wait_griddep`` has executed in any task schedule, including skipped-tile
execution.

Use ``TaskManager(assume_pdl_wait_completed=True)`` only when the PDL wait is
emitted outside TS before the first PDL-dependent memory access.
