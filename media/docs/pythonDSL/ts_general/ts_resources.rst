.. _rts_resources:

Resources
=========

Overview
--------

A resource is an **abstraction over a physical GPU resource** -- a GMEM tensor,
an SMEM tile, a TMEM accumulator, a persistent tile queue, and so on.  It is a
``@dataclass(kw_only=True)`` subclass of ``MemoryResource``.
For one logical piece of the schedule, a resource bundles the data it
owns, an optional pipeline, its producer/consumer work methods, the memory it
allocates, and any task-local variables.

Pipelines
---------

A resource **may or may not have a pipeline** attached.  A pipelined resource
guards its physical storage so a producer and a consumer can work on different
stages concurrently; the developer can attach a pipeline by passing ``pipeline_config=`` at
construction.  A non-pipelined resource (for example a coordinate-only GMEM
input) has no barriers.  See :ref:`rts_pipelines` for the pipeline types and how
to build a ``PipelineConfig``.

Producer and Consumer Work
--------------------------

A resource exposes the points where data enters and leaves it, always *from the
resource's point of view*:

- ``@producer_work`` -- a method that **writes data into** the resource.
- ``@consumer_work`` -- a method that **reads data out of** the resource.

Pipelined producers are bracketed with ``acquire`` / ``commit`` and pipelined
consumers with ``wait`` / ``release`` in the schedule (see :ref:`rts_schedules`).
Data that flows from a consumer to a downstream producer is carried by task-local
variables, described below.

Declaring Memory Requirements
-----------------------------

A resource that uses SMEM or TMEM must declare what it allocates so the allocator
can lay it out and so the verifier knows its physical footprint.  Create the
allocation object once in the constructor and return it from
``get_smem_requirements()`` (or ``get_tmem_requirements()``):

.. code-block:: python

    self._alloc_smem = SmemAllocation(
        "smem_data", dtype=cutlass.Float16, count=num_stages * tile_size, alignment=128
    )

    def get_smem_requirements(self):
        return [self._alloc_smem]

The work methods later read the resolved pointer through
``stage_info.context``.  The full allocator lifecycle, capacity checks, and
aliasing are covered in :ref:`rts_allocators`.

Task-Local Variables
--------------------

Within a single task, work methods on different resources often need to hand
values to one another: a consumer reads a value *out of* its resource, and a
dependent resource's producer work method must write *into* its resource based
on that value.  TS carries these values through ``TaskLocalVariable`` tokens
instead of letting resources share state directly -- the consumer **returns** a
token and the producer **receives** it as an argument, and the schedule
connects the two.

Concretely, the consumer's ``@consumer_work`` returns the value it read; calling
it in the schedule yields a token; the developer passes that token to a ``@producer_work``
method, which uses it to produce its own data.  The canonical pattern:

.. code-block:: python

    @dataclass(kw_only=True)
    class InputGmemResource(MemoryResource):
        source_tensor: cute.Tensor
        num_entries: cutlass.Int32
        num_warps: int
        item: cutlass.Constexpr[TaskLocalVariable] = TaskLocalVariable.uninitialized()

        def __post_init__(self) -> None:
            self.item = TaskLocalVariable(
                dtype=cutlass.Int16,
                default=cutlass.Int16(0),
                docs="Input element loaded for the current grid-stride iteration.",
            )

        @consumer_work(returns=item)
        @cute.jit
        def get_item(self, stage_info: StageInfo) -> cutlass.Int16:
            gid = stage_info.loop_offset
            val = cutlass.Int16(0)
            if gid < self.num_entries:
                val = self.source_tensor[gid]
            return val


    @dataclass(kw_only=True)
    class OutputGmemResource(MemoryResource):
        destination_tensor: cute.Tensor
        num_entries: cutlass.Int32
        num_warps: int

        @producer_work
        @cute.jit
        def set_item(self, stage_info: StageInfo, data: cutlass.Int16) -> None:
            gid = stage_info.loop_offset
            if gid < self.num_entries:
                self.destination_tensor[gid] = data

The schedule wires the token returned by the consumer into the producer:

.. code-block:: python

    @schedule
    def schedule_fn(input_gmem: InputGmemResource,
                    output_gmem: OutputGmemResource) -> None:
        with domain_loop(start, num_entries, step, unroll=unroll):
            res = input_gmem.get_item()
            output_gmem.set_item(data=res)

The declaration has five parts:

- Declare a class attribute initialized with ``TaskLocalVariable.uninitialized()``.
- Bind it in ``__post_init__`` or ``__init__`` with a dtype, default, and docs.
- Mark the consumer with ``@consumer_work(returns=item)`` and return the value.
- Pass the returned token through the schedule body.
- Give the producer a matching parameter, such as ``data`` above.

Auxiliary Work
--------------

Auxiliary work is helper work that sets up some state **without touching the
actual data payload** -- for example computing a descriptor, an offset, or tile
indices, deriving a typed SMEM view, or resetting per-tile bookkeeping.  It does
not read or write the data that the pipeline guards.  Mark such a method with
``WorkAttr.AUXILIARY``.

Auxiliary work is still captured and emitted as part of the schedule, but the
verifier **ignores it for ordering and pipeline checks**.  Because it carries no
data, it may appear anywhere in the schedule: it does not need to sit inside the
``acquire`` / ``commit`` or ``wait`` / ``release`` brackets and is not
constrained by them.

Per-Work-Tile State
-------------------

Per-work-tile state is an ordinary resource field reset by a method called
inside ``work_tile_loop``.  The snippet below resets ``scale_d`` before each
persistent tile so the first MMA initializes the accumulator and later MMAs
accumulate:

.. code-block:: python

    scale_d: cutlass.Boolean = field(init=False, default=None)

    @producer_work(work_attrs=WorkAttr.AUXILIARY)
    @cute.jit
    def init_work_tile_state(self, stage_info: StageInfo) -> None:
        del stage_info
        self.scale_d = False

    @schedule
    def mma_schedule(smem_a, smem_b, tmem_c, wq) -> None:
        with work_tile_loop(wq):
            tmem_c.init_work_tile_state()
            with domain_loop(0, num_k_tiles, 1):
                desc_a_base = smem_a.build_desc_a()
                desc_b_base = smem_b.build_desc_b()
                tmem_c.mma(desc_a_base=desc_a_base,
                           desc_b_base=desc_b_base)

StageInfo
---------

Every work method receives ``StageInfo``.  Common fields are:

- ``loop_offset``: the current ``domain_loop`` iteration.
- ``stage_idx``: the active pipeline stage, or ``None`` for unpipelined work.
- ``barrier``: the active mbarrier pointer, if the resource is pipelined.
- ``work_tile``: the current persistent scheduler tile.

Use ``stage_info.loop_offset`` as the current ``domain_loop`` iteration, such as
a grid-stride element index.  Use ``stage_info.work_tile.tile_idx`` in
persistent schedules to select the active output tile.

When a work method needs to know which repeated call it is (for example, which
subtile of an epilogue) or which schedule section it runs in, the schedule passes
that value explicitly; see :ref:`rts_constexpr_work_args` below.

.. _rts_constexpr_work_args:

Compile-Time Work Arguments
---------------------------

A schedule can pass **compile-time constants** straight into a work method as
keyword arguments.  Unlike task-local variables, which carry *runtime* SSA
values produced by other work, these are ordinary Python values fixed at
schedule-capture time and forwarded verbatim to the work body as
``cutlass.Constexpr``.

Declare the parameter as a keyword-only ``cutlass.Constexpr`` on the work method
and pass it from the schedule:

.. code-block:: python

    @consumer_work(returns=t2r_rmem)
    @cute.jit
    def load_subtile(self, stage_info: StageInfo, *,
                     subtile_idx: cutlass.Constexpr[int]):
        col_offset = subtile_idx * self.t2r_inst_repx
        ...

    @producer_work
    @cute.jit
    def store(self, stage_info: StageInfo, *, t2r_rmem,
              subtile_idx: cutlass.Constexpr[int]):
        col = coordc_n + subtile_idx * 32
        ...

    @schedule
    def store_schedule(tmem_c, gmem_d) -> None:
        tmem_c.wait()
        # Same work methods, called once per subtile with a distinct constant.
        for subtile_idx in cutlass.range_constexpr(subtile_cnt):
            t2r_rmem = tmem_c.load_subtile(subtile_idx=subtile_idx)
            gmem_d.store(t2r_rmem=t2r_rmem, subtile_idx=subtile_idx)
        tmem_c.release()

Because the value is a ``cutlass.Constexpr``, the work body can branch on it with
``cutlass.const_expr(...)`` and the compiler folds the branch away.  Each
distinct call still occupies its own schedule slot, so the printed schedule shows
one step per call (the **call-idx** column in :ref:`rts_printout` numbers them in
order).
