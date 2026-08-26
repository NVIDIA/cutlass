.. _rts_introduction:
.. |TS| replace:: Task Scheduling

Introduction
============

Overview
--------

Modern NVIDIA GPUs expose asynchronous operations such as TMA, tcgen05 MMA,
CLC fetch, and copy to Tensor Memory. Programming them efficiently requires
asynchronous warp-specialized programs where each warp or group of warps is
responsible for a task, such as data loading or math computation.  These tasks
communicate through memory, such as shared memory or tensor memory.

Synchronization with mbarriers and named barriers is needed to prevent
concurrent data accesses.
Barrier behavior depends on the kernel configuration,
the producer/consumer pattern (how many warps are writing and reading data)
between specialized warps, the operation type (TMA, MMA, cpasync, etc),
which threads signal each barrier, and which memory regions overlap in time.  A
wrong arrival count, a missed barrier advance, or a release before the producer
has finished writing can cause a wrong result or a runtime hang.

In bare-metal code, the schedule is implicit. Warp specialization, barrier
arrivals, and phase advancement are scattered across warp branches and mixed
into the kernel body. There is no separate schedule object to inspect, so there
is no deadlock or race checker either.

|TS| makes the schedule explicit. The developer still writes the low-level work
methods for TMA, MMA, and memory operations.  TS adds a checked structure around
that code:

- resources describe the communication objects used by the kernel;
- a dependency graph states which resources must be produced before other
  resources can be produced or consumed;
- schedules record the order of acquire/work/commit and wait/work/release calls;
- tasks bind schedules and resources to a concrete warp range.

|TS| statically checks the schedule for deadlocks, race conditions, and
barrier initialization before lowering the kernel to GPU code. Many
synchronization ordering mistakes fail early instead of becoming runtime hangs
or race conditions.
The warp-role structure is written in one concise place, making the kernel
easier to inspect and review.
Schedule edits and optimizations are easier to audit because |TS| re-checks
the schedule ordering before lowering to GPU code.

Core Terms
----------

**Resource**
  A ``MemoryResource`` or subclass wrapping a physical resource such as global memory,
  shared memory, tensor memory, a persistent tile queue, or a PDL barrier.  A resource may carry
  a pipeline with ``PipelineConfig`` guarding storage with ``acquire`` /
  ``commit`` functions on the producer side and ``wait`` / ``release``
  functions on the consumer side.

**Task**
  A contiguous warp range, described by ``warp_idx`` and ``num_warps``, bound to
  one explicit execution schedule.  A task lists the resources it reads from in
  ``src_resources`` and the resources it writes to in ``dst_resources``.  It may
  also declare a ``num_registers`` budget for warp-group register validation.

**Schedule**
  A function decorated with ``@schedule``.  The schedule function explicitly
  specifies the order of operations on resources plus the synchronization
  primitives used to synchronize concurrent access to those resources. Calling
  the decorated function records resource method calls, but it does not execute the work.  The
  call returns a ``ScheduleResult`` passed to ``Task(schedule=...)``.

**TaskManager**
  The object that ties tasks, the dependency graph, and optional SMEM/TMEM
  allocators together.  It validates the schedule and then runs each task on its
  assigned warps.

**Dependency graph**
  A ``dict`` mapping each resource to the list of resources it depends on. TS
  uses it to verify the order of pipeline operations in the schedule.

Authoring Lifecycle
-------------------

A typical TS kernel is assembled in this order:

1. Declare the resource classes and schedule-facing work methods.
   The ``@producer_work`` and ``@consumer_work`` methods must exist so the
   schedule can call them, but their detailed TMA, MMA, or memory logic can be
   filled after the schedule structure is validated.

2. Instantiate the resources.
   Resources may be plain logical resources, such as a GMEM coordinate source,
   or pipelined resources with a ``PipelineConfig`` that creates the acquire /
   commit and wait / release machinery.

3. Declare the resource dependency graph.
   The graph records the intended dataflow.  For example, if ``smem_a`` is
   filled from ``gmem_a``, then ``smem_a`` depends on ``gmem_a``.  TS uses this
   graph to check that the schedules actually implement the declared ordering.

4. Write and capture schedules.
   A ``@schedule`` function calls resource work methods and synchronization
   methods in the order the task should execute them.  Calling the schedule
   function returns a ``ScheduleResult``; it does not execute GPU work.

5. Create tasks.
   Each ``Task`` receives the resources it reads in ``src_resources``, the
   resources it writes in ``dst_resources``, the captured ``schedule``,
   and a warp assignment through ``warp_idx`` and ``num_warps``.  This maps a
   software task such as "acquire A", "load A", "call MMA", "commit results",
   or "store D" to a concrete group of warps.

6. Create a ``TaskManager`` and verify.
   The manager owns the task list, dependency graph, and optional SMEM/TMEM
   allocators.  ``TaskManager.print_and_verify()`` validates the captured
   schedules as compile-time metadata before the kernel is lowered.  This check
   does not need to launch a GPU kernel; many schedule, barrier, deadlock, and
   race mistakes can be caught before runtime.

7. Fill the producer and consumer work bodies and verify the result.
   After the schedule is structurally correct, implement the actual resource
   logic: address calculation, TMA copies, MMA instructions, stores, and any
   local value transformations.  Then run the kernel-level correctness check
   against the expected result.

The following skeleton shows the pieces in one place:

.. code-block:: python

    # 1. Resource classes declare the schedule-facing operations.
    class GmemAResource(MemoryResource):
        @consumer_work
        def compute_coords(self, stage_info):
            ...

    class SmemAResource(MemoryResource):
        @producer_work
        def tma_load_a(self, stage_info, coord_k, coord_m):
            ...

    # 2. The kernel instantiates resources, optionally with pipeline configs.
    gmem_a = GmemAResource(name="gmem_a")
    smem_a = SmemAResource(
        name="smem_a",
        pipeline_config=smem_a_pipeline_config,
    )

    # 3. The dependency graph states the intended resource ordering.
    resource_dependency_graph = {
        smem_a: [gmem_a],
    }

    # 4. The captured schedule records the task ordering.
    @schedule
    def load_a_schedule(gmem_a: GmemAResource,
                        smem_a: SmemAResource) -> None:
        with domain_loop(0, num_k_tiles, 1):
            coord_k, coord_m, coord_n = gmem_a.compute_coords()
            smem_a.acquire()
            smem_a.tma_load_a(coord_k=coord_k, coord_m=coord_m)
            smem_a.commit()

    # 5. The task binds resources, schedule, and warp assignment.
    load_a_task = Task(
        name="load_a",
        src_resources=[gmem_a],
        dst_resources=[smem_a],
        warp_idx=0,
        num_warps=1,
        schedule=load_a_schedule(gmem_a, smem_a),
    )

    # 6. The manager validates the schedule before lowering.
    task_manager = TaskManager(
        tasks=[load_a_task],
        resource_dependency_graph=resource_dependency_graph,
    )
    task_manager.print_and_verify()

    # 7. Fill the @consumer_work / @producer_work bodies, then run
    #    the kernel correctness check against the expected result.

Producer and Consumer
---------------------

The kernel developer is still responsible for providing the logic
that writes data to a resource (producer work) and reads data from the resource
(consumer work).
The work each resource does is declared as methods decorated with
``@producer_work`` or ``@consumer_work``.

``@consumer_work`` reads a value *out of* the resource.
``@producer_work`` writes a value *into* the resource.

For example, a load task reads coordinates from a GMEM resource and produces a
tile into SMEM:

.. code-block:: text

                          Load task
                           1 warp
   src_resource                                 dst_resource
   +--------------+                          +--------------+
   | InputGmem    | -----------------------> | Smem         |
   +-------------o+                          +o------------o+
                 |                            |            |
                 |                            |            |
         consumer_work()              producer_work()  consumer_work()
         get tile coords              TMA load         load from shared

A task that calls ``consumer_work`` on ``InputGmem`` lists that resource in
``src_resources``.  A task that calls ``producer_work`` on ``Smem`` lists that
resource in ``dst_resources``.
