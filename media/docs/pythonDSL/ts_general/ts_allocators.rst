.. _rts_allocators:

Allocators
==========

Overview
--------

TS SMEM and TMEM allocators declare physical memory layout once and expose offsets to
resources through ``StageInfo.context``.  They serve two purposes:

- TS reorders memory regions to minimize padding waste and fragmentation.
- TS uses the declared memory regions for each resource to verify the absence
  of race conditions when several regions are aliased.

The barrier allocator serves a slightly different purpose, which is efficient
coalesced initialization in the kernel prologue, for better performance.

Declaring Requirements
----------------------

Resources declare SMEM and TMEM by returning ``SmemAllocation`` and
``TmemAllocation`` instances from ``get_smem_requirements()`` and
``get_tmem_requirements()``.
The allocation objects are cached on the resource so every requirement query
returns the same object and therefore the same assigned offset:

.. code-block:: python

    self._alloc_smem = SmemAllocation(
        "smem_data",
        dtype=cutlass.Float16,
        count=num_stages * tile_size,
        alignment=128,
    )

    def get_smem_requirements(self):
        return [self._alloc_smem]

This snippet declares TMEM columns for an accumulator resource.  TMEM
requirements are also cached on the resource and returned from
``get_tmem_requirements()``:

.. code-block:: python

    self._alloc_acc = TmemAllocation("tmem_acc", mma_tiler_mnk[1] * acc_stages)

    def get_tmem_requirements(self):
        return [self._alloc_acc]

SMEM Lifecycle
--------------

The allocator flow is:

.. code-block:: python

    allocator = SmemAllocator()
    allocator.add_resource(smem_resource)
    allocator.compute_layout()

    task_manager = TaskManager(
        tasks=[...],
        resource_dependency_graph={...},
        smem_allocator=allocator,
    )
    task_manager.setup_resources_and_tasks()

``compute_layout()`` assigns offsets and is idempotent-guarded; a second call
raises.  During setup, ``allocate()`` emits one unified SMEM block and
``assign_barrier_ptrs()`` patches pipeline barrier pointers.  Work methods read
the base pointer through ``stage_info.context.smem_base``.

TMEM Lifecycle
--------------

TMEM allocation is column-based and has no alignment.  ``TmemAllocator`` only
computes column offsets; it does not emit allocation intrinsics.

The kernel reserves a small SMEM slot for the TMEM base pointer through
``SmemAllocator.add_tmem_ptr(...)``.  The setup code derives
``context.tmem_ptr_i32`` from the unified SMEM block, then brackets
``task_manager.run()`` with ``nvvm.tcgen05_alloc`` and
``nvvm.tcgen05_dealloc`` so TMEM lifetime matches the task execution:

.. code-block:: python

    tmem_ptr_alloc = allocator.add_tmem_ptr(
        SmemAllocation("tmem_ptr", dtype=cutlass.Int32, count=1, alignment=4)
    )

    task_manager.setup_resources_and_tasks()
    tmem_ptr_i32 = allocator.get(tmem_ptr_alloc)
    nvvm.tcgen05_alloc(tmem_ptr_i32, num_tmem_cols)
    ...
    task_manager.run()
    ...
    nvvm.tcgen05_dealloc(tmem_ptr, num_tmem_cols)

Barrier Lifecycle
-----------------

By default each pipelined resource self-allocates and initializes its
``full`` / ``empty`` mbarriers.  A ``BarrierAllocator`` instead coalesces every
pipeline's mbarriers into one array and initializes it in one vectorized pass.

The barrier allocator flow is:

.. code-block:: python

    barrier_allocator = BarrierAllocator()
    barrier_allocator.add_resource(smem_res)
    barrier_allocator.add_pipeline_group("ab_sync", ab_sync)
    barrier_allocator.compute_layout()
    barrier_allocator.set_backing(smem_allocator)

    task_manager = TaskManager(
        tasks=[...],
        resource_dependency_graph={...},
        smem_allocator=smem_allocator,
        barrier_allocator=barrier_allocator,
    )
    task_manager.setup_resources_and_tasks()

``compute_layout()`` buckets similar barriers to simplify the initialization code.
During setup, TS allocates the array, patches each resource/group's ``barrier_ptr``
and runs the vectorized ``initialize()``.

Aliasing
--------

Two resources that never use shared memory at the same time can share one
physical region instead of each getting its own.  This is declared with
``add_alias_group(phases)``, passing the resources' allocation objects (the
``_alloc*`` handles each resource creates in its constructor).  Each *phase* is
a list of allocations that coexist (so they get back-to-back offsets), and every
phase reuses the same base offset.  The region is sized to the largest phase.

.. code-block:: python

    # A and B tiles are dead once the mainloop finishes, so the epilogue
    # staging buffer reuses their shared memory.
    allocator.add_alias_group([
        [smem_ab_resource._alloc_a, smem_ab_resource._alloc_b],  # phase 0
        [gmem_d_resource._alloc_staging],                        # phase 1
    ])
    allocator.compute_layout()

Both phases map onto a single shared-memory region.  In phase 0 ``_alloc_a`` and
``_alloc_b`` sit back-to-back; in phase 1 ``_alloc_staging`` reuses the very
same bytes::

    base offset                              base + region size
    |                                                 |
    v                                                 v
    +------------------------+------------------------+
    |        alloc_a         |        alloc_b         |  phase 0 (mainloop)
    |         (4 KB)         |         (4 KB)         |
    +------------------------+------------------------+
    |                  alloc_staging                  |  phase 1 (epilogue)
    |                     (8 KB)                      |
    +-------------------------------------------------+
    |<------------- one physical region ------------->|

The region is sized to the largest phase: ``max(4 KB + 4 KB, 8 KB) = 8 KB``.
Because the phases share bytes, TS must prove they never touch the region at
the same time -- that is what the exhaustive aliasing check verifies (see
:ref:`rts_validation`).

Default SMEM alignment is 128 bytes.  Pipeline mbarrier storage is accounted
separately as 16 bytes per stage and patched by ``assign_barrier_ptrs()``.

Checker Coupling
----------------

If two aliased resources are accessed at the same time by *different* tasks and
one of them writes, the checker reports an ``aliasing race`` (see
:ref:`rts_validation`).  Suppose ``tmem_vec`` aliases ``tmem_sp``.  A writer
task keeps producing ``tmem_sp``, while a reader task reads ``tmem_sp``,
releases it, and only then ``tmem_vec`` uses the same aliased region as scratch
space.  Once ``tmem_sp`` is released the writer reacquires and overwrites it,
but the reader is still reading the same bytes through ``tmem_vec``::

    step | WriterTask (produces tmem_sp) | ReaderTask (reads tmem_vec ~ tmem_sp)
    -----+-------------------------------+--------------------------------------
      1  | write tmem_sp                 |
      2  | commit ---------------------->| wait tmem_sp
      3  |                               | read tmem_sp
      4  |                               | release tmem_sp   (frees the region)
      5  | write tmem_sp AGAIN           | read tmem_vec   <- overwritten bytes!

At step 5 both tasks touch the same physical bytes concurrently.  The writer
overwrites ``tmem_sp`` while the reader uses ``tmem_vec``, so ``tmem_vec`` reads
corrupted data.
