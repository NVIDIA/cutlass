.. _tcgen05_programming:

tcgen05 MMA Programming Guide
==============================

Blackwell (SM100) introduces the **tcgen05** family of PTX instructions — the
5th-generation Tensor Core MMA (matrix multiply-accumulate) operations. They
compute ``D = A * B + C`` with 2x–4x the throughput of Hopper's WGMMA
instructions, depending on data type.

Key architectural characteristics:

* **Tensor Memory (TMEM):** A new on-chip memory dedicated to the accumulator
  (and, optionally, operand A). tcgen05 MMA reads and writes the accumulator
  in TMEM directly, freeing the register file for other work.
* **Single-thread launch:** Only one thread issues the MMA instruction.
* **CTA-pair cooperation:** Two adjacent CTAs can jointly execute a single
  MMA, doubling the tile size without extra synchronization logic.

This guide shows how to program these operations through the CuTe Python
DSL, using SMEM for operands A and B, and TMEM for the accumulator.

.. contents:: **Contents**
   :local:
   :depth: 2

Global Memory (GMEM) to MMA data flow overview
----------------------------------------------

Tcgen05 MMA instructions requires us to stage A input operands in Shared Memory (SMEM) or Tensor Memory (TMEM),
and B input operands in SMEM. The accumulator is always stored in TMEM.

The diagram below traces the full data flow of a tcgen05 GEMM kernel, for the most
common case where A and B matrices are stored in GMEM, and the output matrix --read from TMEM--
is written to GMEM.

There are 3 parallel tracks where each has 2 sub-tracks. Three parallel tracks are
for operands A, B, and C/D, respectively. The two sub-tracks are for copying data between different memory
spaces and for MMA execution.

- **Operand A** (and symmetrically **Operand B**):

  - First, we need to create SMEM tensors for A and B matrices: ``sA`` and ``sB``. These
    tensors are physically allocated tensors that are the destination of copy and the source operands
    for the MMA instructions.
  - Next the **data copy flow** creates the tensor views for copying data from GMEM to SMEM.
    It starts with ``mA`` tensor that represents the matrix A in global memory.
    ``mA`` → ``local_tile`` → ``gA`` operation creates the local tile view of A that is the
    slice of A matrix needed to compute the given MMA's output tile partitioning.
    ``gA`` → ``partition_A`` → ``tCgA`` partitions the full MMA sized tile into smaller tiles which
    are needed to copy the correct portion of A/B matrix to SMEM by individual CTAs cooperating
    for the MMA (1CTA vs 2CTA pair MMA cases).
    Then ``tma_partition`` produces TMA views ``tAsA``, ``tAgA``, and the loop copies tiles from
    GMEM into SMEM via ``copy(tma, tAgA[k], tAsA[stage])``.
  - In parallel, the **MMA flow** turns the SMEM tensors into iterable tensors of SMEM descriptors for MMA instructions.
    ``sA`` (the same shared-memory allocation written by TMA) → ``make_fragment_A`` → ``tCrA``
    (they are passed to ``cute.gemm()``). Note that the SMEM descriptors are views created
    from the SMEM tensor that is interpretable by the MMA instructions.

- **Accumulator C/D**:

  - **TMEM accumulator flow** (gemm input/output): ``make_fragment_C(MMA_partition_shape_C)`` → ``tCtAcc``,
    which serves as the accumulator input/output of ``cute.gemm()`` (and MMA instruction).
  - **Output flow** (GMEM destination): The LDTM loads results into registers and a final store writes them
    to global memory. ``mC`` → ``local_tile`` → ``gC``
    → ``partition_C`` → ``tCgC``. This path creates the tensor views that will be stored to GMEM.

.. code-block:: text

   Operand A Dataflow Path               Operand B Dataflow Path                 Accumulator C/D Dataflow Path
   ───────────────────────               ───────────────────────                 ─────────────────────────────

  mA: (M, K)           [GMEM]             mB: (N, K)            [GMEM]             ┌──── TMEM ──────────┐
   │                                       │                                       │ partition_shape_C()│
   │ local_tile(mA, mma_tiler, coord)      │ local_tile(mB, mma_tiler, coord)      │ make_fragment_C()  │
   ▼                                       ▼                                       │ bind to tmem_ptr   │
  gA: (BM, BK, k)      [GMEM]             gB: (BN, BK, k)       [GMEM]             └───────┬────────────┘
   │                                       │                                               │
   │ thr_mma.partition_A(gA)               │ thr_mma.partition_B(gB)               tCtAcc:(MMA,MMA_M,MMA_N) [TMEM]
   ▼                                       ▼                                               │
  tCgA:(MMA,MMA_M,      [GMEM]            tCgB:(MMA,MMA_N,      [GMEM]                     │
         MMA_K,k)                                MMA_K,k)                                  │
   │                                       │                                               │        mC: (M, N)     [GMEM]
   │  ┌──── SMEM ─────────┐                │  ┌──── SMEM ─────────┐                        │        │
   │  │ sA = alloc(layout)│                │  │ sB = alloc(layout)│                        │        │ local_tile
   │  └──┬────────┬───────┘                │  └──┬────────┬───────┘                        │        ▼
   │     │        │                        │     │        │                                │        gC: (BM, BN)   [GMEM]
   │     │   make_fragment_A(sA)           │     │   make_fragment_B(sB)                   │        │ partition_C
   │     │        │                        │     │        │                                │        ▼
   │     │        ▼                        │     │        ▼                                │        tCgC:(MMA,MMA_M,
   │     │  tCrA:(MMA,MMA_M,               │     │  tCrB:(MMA,MMA_N,                       │              MMA_N)
   │     │        MMA_K,STAGE)             │     │        MMA_K,STAGE)                     │        [GMEM] (epi dest)
   │     │  [SMEM descriptors]             │     │  [SMEM descriptors]                     │        │
   │     │        └─────────────┐          │     │        └─────────────┐                  │        │
   ╰─────┤                      │          ╰─────┤                      │                  │        │
         ▼                      │                ▼                      │                  │        │
   tma_partition(tma,           │              tma_partition(tma,       │                  │        │
    sA, tCgA)                   │               sB, tCgB)               │                  │        │
    → tAsA, tAgA                │               → tBsB, tBgB            │                  │        │
         ▼                      │                    ▼                  │                  │        │
     ┌───┴────────────────────┐ │             ┌──────┴─────────────────┐│                  │        │
     │ TMA copy loop (A path):│ │             │ TMA copy loop (B path):││                  │        │
     │ copy(tma, tAgA[k],     │ │             │ copy(tma, tBgB[k],     ││                  │        │
     │      tAsA[stage])      │ │             │      tBsB[stage])      ││                  │        │
  ┌─▶│ (writes into sA;       │ │         ┌──▶│ (writes into sB;       ││                  │        │
  │  │  tCrA reads same sA)   │ │         │   │  tCrB reads same sB)   ││                  │        │
  │  │ repeat for next k/stage│ │         │   │ repeat for next k/stage││                  │        │
  │  └────────────────────────┘ │         │   └────────────────────────┘│                  │        │
  │        │                    │         │         │                   │                  │        │
  └────────┘                    ▼         └─────────┘                   ▼                  ▼        │
                                └───────┬───────────────────────────────┴──────────────────┘        │
                                        │                                                           │
                                        ▼                                                           │
                               ┌──────────────────────────────────────────────┐                     │
                               │ GEMM Loop:                                   |                     │
                               | cute.gemm(tiled_mma,                         │                     │
                               │  tCtAcc,       D (output),                   │                     │
                          ┌──▶ │  tCrA[stage],  A (SMEM desc -> sA),          │                     │
                          │    │  tCrB[stage],  B (SMEM desc -> sB),          │                     │
                          │    │  tCtAcc)       C (accumulator input)         │                     │
                          │    └──────────────────────────────────────────────┘                     │
                          │       │     │                                                           │
                          └───────┘     |                                                           │
                                        ▼                                                           │
                                  Epilogue:                                                         │
                                  t2r = make_tmem_copy(LdOp, tCtAcc)                                │
                                  tTR_tAcc = t2r.partition_S(tCtAcc)                                │
                                  tTR_gC   = t2r.partition_D(tCgC) ◀────────────────────────────────┘
                                  tTR_rAcc = make_rmem_tensor(...)
                                        │
                                        ▼
                                  LDTM: copy(t2r, tTR_tAcc, tTR_rAcc)
                                  [TMEM → RMEM]
                                        │
                                        ▼
                                  Store: copy(atom, tTR_rAcc, tTR_gC)
                                  [RMEM → GMEM]


**Naming convention:**

* ``mma_tiler_mnk`` = ``(BM, BN, BK)`` — per-CTA (or per-CTA-pair) MMA tile
* ``mX`` = a global tensor, such as ``mA``, ``mB``, ``mC``
* ``gX`` = MMA-tiler tiled GMEM slice, e.g. ``(BM, BK, k)`` for A
* ``tCgX`` = CTA-partitioned GMEM tensor, e.g. ``(MMA, MMA_M, MMA_K, k)`` for A
* ``sX`` = SMEM allocation (``sA``, ``sB``)
* ``tCrX`` = SMEM-descriptor MMA fragment, e.g. ``(MMA, MMA_M, MMA_K, STAGE)`` for A
* ``tCtX`` = TMEM tensor; ``tCtAcc`` = TMEM accumulator ``(MMA, MMA_M, MMA_N[, ACC_STAGE])``
* ``tAsA`` / ``tBsB`` = TMA-partitioned SMEM views of A / B
* ``tAgA`` / ``tBgB`` = TMA-partitioned GMEM views of A / B
* ``tTR_*`` = T2R (TMEM→RMEM) partitioned tensors used in the epilogue


Setting up the TiledMMA, MMA Ops
---------------------------------

As shown in the data flow overview, CuTe DSL provides many utilities to tile/partition
the global memory tensors, and create fragment views of SMEM and TMEM tensors for MMA instructions.

To utilize these functions, we need to setup the TiledMMA, MMA Ops first.

Creating a tcgen05 MMA Op
~~~~~~~~~~~~~~~~~~~~~~~~~~

A tcgen05 MMA op describes the hardware instruction to use, it has parameters like
data types, instruction shape, CTA group, operand A source (SMEM or TMEM),
and operand major modes.

.. code-block:: python

   import cutlass
   import cutlass.cute as cute
   from cutlass.cute.nvgpu import tcgen05, OperandMajorMode

   op = tcgen05.MmaF16BF16Op(
       cutlass.Float16,              # A/B element type
       cutlass.Float32,              # accumulator type
       (128, 256, 16),               # instruction shape (M, N, K)
       tcgen05.CtaGroup.ONE,         # CTA group
       tcgen05.OperandSource.SMEM,   # A operand from shared memory
       OperandMajorMode.K,           # A is K-major
       OperandMajorMode.K,           # B is K-major
   )

The key parameters are:

- **Instruction shape** ``(M, N, K)``: determines the size of one hardware MMA
  instruction. Larger M and N amortize instruction overhead.
- **OperandSource**: ``SMEM`` reads A from a shared memory descriptor; ``TMEM``
  reads A directly from tensor memory.
- **OperandMajorMode**: ``K`` for K-major (default), ``MN`` for transposed layout.
  Transpose A requires ``a_src=SMEM``; when ``a_src=TMEM``, A is always K-major.


CuTe DSL provides implementation of many tcgen05 MMA ops:

.. list-table:: tcgen05 MMA ops
   :header-rows: 1
   :widths: 30 24 46

   * - PTX name
     - Python class
     - Constructor parameters
   * - ``tcgen05.mma.cta_group::{cg}.kind::tf32``
     - ``tcgen05.MmaTF32Op``
     - ``instruction_shape, cta_group, a_src, a_major_mode, b_major_mode``
   * - ``tcgen05.mma.cta_group::{cg}.kind::f16``
     - ``tcgen05.MmaF16BF16Op``
     - ``ab_dtype, acc_dtype, instruction_shape, cta_group, a_src, a_major_mode, b_major_mode``
   * - ``tcgen05.mma.cta_group::{cg}.kind::i8``
     - ``tcgen05.MmaI8Op``
     - ``ab_dtype, instruction_shape, cta_group, a_src, a_major_mode, b_major_mode``
   * - ``tcgen05.mma.cta_group::{cg}.kind::f8f6f4``
     - ``tcgen05.MmaF8F6F4Op``
     - ``a_dtype, b_dtype, acc_dtype, instruction_shape, cta_group, a_src, a_major_mode, b_major_mode``
   * - ``tcgen05.mma.cta_group::{cg}.kind::mxf8f6f4.block_scale``
     - ``tcgen05.MmaMXF8F6F4Op``
     - ``a_dtype, b_dtype, instruction_shape, cta_group, a_src, a_major_mode, b_major_mode``
   * - ``tcgen05.mma.cta_group::{cg}.kind::mxf4.block_scale``
     - ``tcgen05.MmaMXF4Op``
     - ``instruction_shape, cta_group, a_src``
   * - ``tcgen05.mma.cta_group::{cg}.kind::mxf4nvf4.block_scale``
     - ``tcgen05.MmaMXF4NVF4Op``
     - ``sf_dtype, instruction_shape, cta_group, a_src``


Creating a Tiled MMA
~~~~~~~~~~~~~~~~~~~~~

A ``TiledMma`` tiles the MMA atom across the thread block. You can pass the op
directly or create an explicit atom first.

.. code-block:: python

   # Option 1: directly from op (common shorthand)
   tiled_mma = cute.make_tiled_mma(op)

   # Option 2: explicit atom creation
   atom = cute.make_mma_atom(op)
   tiled_mma = cute.make_tiled_mma(atom)


Spatial tiling with a repeat count (using ``atom_layout_mnk``)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

A repeat tuple ``(M_rep, N_rep, K_rep)`` replicates the atom across the M, N, and K dimensions, producing
a larger tiled MMA that covers a bigger CTA tile.

.. code-block:: python

  tiled_mma = cute.make_tiled_mma(atom, (2, 2, 1))

The coordinates of atoms could be thought as a 4D coordinate: (v, m, n, k).
v is the CTAs for a single MMA (for CtaGroup.ONE always 0, for CtaGroup.TWO always 0 or 1),
m is the M dimension repeat count, n is the N dimension repeat count, and k is the K dimension repeat count.

.. code-block:: text

  MMA Atom CtaGroup.ONE                 make_tiled_mma(atom, (2, 2, 1))
  +---------------+                     +----------------+----------------+
  |               |                     |                |                | ^
  |  128 x 256    |                     | Atom (0,0,0,0) | Atom (0,0,1,0) | |
  |    x 16       |   --(2,2,1)-->      |  128 x 256     |  128 x 256     | | 2 x M_atom
  |               |      repeat         |    x 16        |    x 16        | |  = 256
  |               |                     |                |                | |
  +---------------+                     +----------------+----------------+ |
                                        |                |                | |
                                        | Atom (0,1,0,0) | Atom (0,1,1,0) | |
                                        |  128 x 256     |  128 x 256     | |
                                        |    x 16        |    x 16        | |
                                        |                |                | v
                                        +----------------+----------------+
                                        <---- 2 x N_atom = 512 -------->
                                        K unchanged = 16

.. code-block:: text

  MMA Atom CtaGroup.TWO                 make_tiled_mma(atom, (2, 2, 1))
  +---------------+                     +----------------+----------------+
  | CTA v = 0     |                     | Atom (0,0,0,0) | Atom (0,0,1,0) | ^
  |  128 x 256    |                     |  128 x 256     |  128 x 256     | |
  |    x 16       |                     |    x 16        |    x 16        | | 2CTA Atom
  +...............+                     +................+................+ |
  | CTA v = 1     |   --(2,2,1)-->      | Atom (1,0,0,0) | Atom (1,0,1,0) | |
  |  128 x 256    |      repeat         |  128 x 256     |  128 x 256     | |
  |    x 16       |                     |    x 16        |    x 16        | v
  +---------------+                     +----------------+----------------+
                                        | Atom (0,1,0,0) | Atom (0,1,1,0) | ^
                                        |  128 x 256     |  128 x 256     | |
                                        |    x 16        |    x 16        | | 2CTA Atom
                                        +................+................+ |
                                        | Atom (1,1,0,0) | Atom (1,1,1,0) | |
                                        |  128 x 256     |  128 x 256     | |
                                        |    x 16        |    x 16        | v
                                        +----------------+----------------+
                                        <---- 2 x N_atom = 512 -------->
                                        Per CTA: 2 x M_atom = 256
                                        Cluster M (v*m*128): 512
                                        K unchanged = 16


Custom tile permutation with ``permutation_mnk``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

``make_tiled_mma`` accepts an optional ``permutation_mnk`` argument that
controls how the atom tiles are laid out across the M, N, and K dimensions.
``permutation_mnk`` is a tuple of layouts or ints that represent the tile size and reordering of values.
These permutation operations could be applied to optimize the data access patterns for MMAs.

For example, with ``inst_m=256`` and 2 atoms in M (total M tile = 512),
a permutation can interleave the two atoms' M rows:

.. code-block:: python

   # inst_m=256, inst_n=256, inst_k=16
   m_layout = cute.make_layout(
         shape=(128, 2, 2),      # (inst_m // 2, 2, 2)
         stride=(1, 256, 128),   # (1, inst_m, inst_m // 2)
   )
   tiled_mma = cute.make_tiled_mma(
         atom,
         atom_layout_mnk=(1, 1, 1),
         permutation_mnk=(m_layout, 256, 16),
   )

The layout ``(128,2,2):(1,256,128)`` maps logical flat indices to physical
M rows in colex order (mode 0 fastest), interleaving the two atoms' halves:

.. code-block:: text

   Without permutation                                     With permutation_mnk
   (sequential, default)                                   m_layout = (128,2,2):(1,256,128)

   +---------------+ ^                ^                   +---------------+ ^
   | MMA 0 top     | | 128  CTA 0     |                   | MMA 0 top     | | 128  CTA 0
   | rows 0-127    | |                |                   | rows 0-127    | |
   +...............+ +                |  Tile 0           +---------------+ v
   | MMA 0 bottom  | | 128  CTA 1     |                   | MMA 1 top     | | 128  CTA 0
   | rows 128-255  | |                |                   | rows 128-255  | |
   +---------------+ v                v                   +---------------+ v
   | MMA 1 top     | ^                ^                   | MMA 0 bottom  | | 128  CTA 1
   | rows 256-383  | | 128  CTA 0     |                   | rows 256-383  | |
   +...............+ +                |  Tile 1           +---------------+ v
   | MMA 1 bottom  | | 128  CTA 1     |                   | MMA 1 bottom  | | 128  CTA 1
   | rows 384-511  | |                |                   | rows 384-511  | |
   +---------------+ v                v                   +---------------+ v
   <-- inst_N=256 ->                                      <-- inst_N=256 ->
   inst_K = 16                                            inst_K = 16

   Tile 0: rows 0-255   (contiguous)                      Tile 0: rows {0-127, 256-383}
   Tile 1: rows 256-511 (contiguous)                      Tile 1: rows {128-255, 384-511}
   CTA 0 owns rows {0-127, 256-383}                       CTA 0 owns rows {0-127, 256-383}
   CTA 1 owns rows {128-255, 384-511}                     CTA 1 owns rows {128-255, 384-511}

When ``permutation_mnk`` is not provided (default), the tile ordering is
sequential and no permutation is applied.

Creating Trivial Tiled MMA
~~~~~~~~~~~~~~~~~~~~~~~~~~~

Since tcgen05 MMAs have quite large instruction shapes, most common TiledMmas created are
trivial tiled MMAs, with single M, N repetitions, i.e., ``atom_layout_mnk``, and ``permutation_mnk`` are generally unused.
CuTe DSL provides a convenience function ``make_trivial_tiled_mma`` to create such trivial MMAs with
automatic MmaOp kind selection based on the data types.

.. code-block:: python

  import cutlass.utils.blackwell_helpers as sm100_utils

  tiled_mma = sm100_utils.make_trivial_tiled_mma(
        a_dtype,
        b_dtype,
        a_major_mode,
        b_major_mode,
        acc_dtype,
        cta_group,
        mma_tiler_mnk,
  )

  # Equivalent to
  tiled_mma = cute.make_tiled_mma(
        cute.make_mma_atom(
              cute.MmaXyzOp(
                    # ... parameters of MmaXyzOp
              ),
        ),
  )

Partitioning Tensors
--------------------

Before computing MMAs, we want to partition the global memory tensors according to the
tiled MMA layout. For tcgen05, this maps each CTA's work to the correct portion of
the global memory tensors.

We have two steps to partition the global memory tensors:

* Local tile partitioning: partition the global memory tensors into local tiles, each of size ``mma_tiler_mnk``.
  This is the portion of the global memory tensors that will be processed by a single CTA MMA or a 2CTA cooperative MMA.
* MMA partition: partition the local tile into CTA-sized, per-MMA-instruction tiles (note that each CTA needs
  to load its own portion to SMEM for 2CTA cooperative MMA). The per-operand shapes are
  ``(MMA, MMA_M, MMA_K, ...)`` for A, ``(MMA, MMA_N, MMA_K, ...)`` for B, and ``(MMA, MMA_M, MMA_N, ...)`` for C.

Note that for tcgen05, SMEM tensors are not partitioned.
See `Making Fragments`_ for more details.

Trivial TiledMma with CtaGroup.ONE MMAs (single CTA):
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

For the trivial tiled MMAs with CtaGroup.ONE tcgen05 MMA operations, partitioning the mma_tiler sized tile
is an identity operation, i.e., single CTAs' tile is the same as the mma_tiler sized tile.
The main difference between the result of ``local_tile`` and ``partition_[A/B]`` is that, the latter
produces a view that can be iterated in per-MMA instruction fashion.

Example: ``GEMM (M, N, K) = (512, 768, 384)``, ``mma_tiler_mnk = (128, 256, 64)``,
``CtaGroup.ONE``, F16 atom = 128x256x16 (inst_M=128, inst_N=256, inst_K=16).

Global memory tensors:

.. code-block:: text

  mA: (M, K) = (512, 384)       mB: (N, K) = (768, 384)       mC: (M, N) = (512, 768)

       K=384                          K=384                       N=768
     |<----------->|               |<----------->|           |<----------------->|
     +-------------+               +-------------+           +---+---+---+-------+
     |             | ^             |             | ^         |   |   |   |       | ^
     |     mA      | | M=512       |     mB      | | N=768   |   |   |   |       | | M=512
     |             | v             |             | v         |   |   |   |       | v
     +-------------+               +-------------+           +---+---+---+-------+

Tiling with ``mma_tiler_mnk = (BM, BN, BK) = (128, 256, 64)`` gives
M/BM = 512/128 = 4 tiles, N/BN = 768/256 = 3 tiles, K/BK = 384/64 = 6 tiles:

.. code-block:: text

  mA tiled into (M/BM x K/BK)   mB tiled into (N/BN x K/BK)     mC tiled into (M/BM x N/BN)
  = (4 x 6) blocks              = (3 x 6) blocks                = (4 x 3) blocks
                                                                 * coordinates annotated on the matrix
                                                                   are the mma_coord_mn of the GEMM.

    BK=64  x6                     BK=64  x6                        BN=256  x3
  |<--->|                        |<--->|                        |<----->|
  +-----+-----+-- --+            +-----+-----+-- --+            +-------+-------+-------+
  |     |     |..|  | ^          |     |     |..|  | ^          | (0,0) | (0,1) | (0,2) | ^
  |     |     |  |  | | BM=128   |     |     |  |  | | BN=256   |       |       |       | | BM=128
  +-----+-----+-- --+ v          +-----+-----+-- --+ v          +-------+-------+-------+ v
  |     |     |..|  | ^          |     |     |..|  | ^          | (1,0) | (1,1) | (1,2) | ^
  |     |     |  |  | | BM=128   |     |     |  |  | | BN=256   |       |       |       | | BM=128
  +-----+-----+-- --+ v          +-----+-----+-- --+ v          +-------+-------+-------+ v
  |     |     |..|  | ^          |     |     |..|  | ^          | (2,0) | (2,1) | (2,2) | ^
  |     |     |  |  | | BM=128   |     |     |  |  | | BN=256   |       |       |       | | BM=128
  +-----+-----+-- --+ v          +-----+-----+-- --+ v          +-------+-------+-------+ v
  |     |     |..|  | ^                                         | (3,0) | (3,1) | (3,2) | ^
  |     |     |  |  | | BM=128                                  |       |       |       | | BM=128
  +-----+-----+-- --+ v                                         +-------+-------+-------+ v

Each CTA picks one (M-coord, N-coord) coordinate.
For example, CTA at ``mma_coord = (0, 1, :)``.

After ``local_tile`` — one CTA's tile has ``k = K/BK = 384/64 = 6`` tiles to process
for A, B tensors, and a single tile for C tensor:

.. code-block:: text

     gA: (BM, BK, k) = (128, 64, 6)   gB: (BN, BK, k) = (256, 64, 6)   gC: (BM, BN) = (128, 256)
     (k has 6 tiles total: indices 0..5)

          BK=64                              BK=64                                BN=256
        |<----->|                          |<----->|                           |<--------->|
        +-------+---------+-------+        +-------+---------+-------+         +-----------+
        |       |         |       |        |       |         |       |         |           | ^
    BM= | gA k0 | k1...k4 | gA k5 |    BN= | gB k0 | k1...k4 | gB k5 |     BM= |    gC     | 128
    128 |       |         |       |    256 |       |         |       |     128 |           | v
        +-------+---------+-------+        +-------+---------+-------+         +-----------+

``get_slice(0)`` — single CTA owns the full tile.
BM and BN match the atom, BK is split into MMA_K atom-sized steps:

.. code-block:: text

        gA (BK split into MMA_K atoms)                           gC
          inst_K  inst_K  inst_K  inst_K
          =16     =16     =16     =16
        |<--->|<--->|<--->|<--->|
        +-----+-----+-----+-----+--                             +-----------+
        |  0  |  1  |  2  |  3  |..  BM=128  (MMA_M=1)          |           | BM=128
        +-----+-----+-----+-----+                               +-----------+
        |<-- MMA_K = BK/inst_K = 4 -->|

        gB (BK split into MMA_K atoms)
          inst_K  inst_K  inst_K  inst_K
          =16     =16     =16     =16
        |<--->|<--->|<--->|<--->|
        +-----+-----+-----+-----+--
        |  0  |  1  |  2  |  3  |..  BN=256  (MMA_N=1)
        +-----+-----+-----+-----+

After partition (single CTA):

- ``tCgA: (MMA, MMA_M, MMA_K, k) = (MMA, 1, 4, 6)`` — MMA_M = BM/inst_M = 128/128 = 1, MMA_K = BK/inst_K = 64/16 = 4
- ``tCgB: (MMA, MMA_N, MMA_K, k) = (MMA, 1, 4, 6)`` — MMA_N = BN/inst_N = 256/256 = 1, MMA_K = BK/inst_K = 64/16 = 4
- ``tCgC: (MMA, MMA_M, MMA_N) = (MMA, 1, 1)`` — MMA_M = BM/inst_M = 1, MMA_N = BN/inst_N = 1

With CuTe DSL, all these calculations are handled for you provided ``mma_tiler_mnk`` and ``mma_coord``.

.. code-block:: python

   @cute.kernel
   def kernel(tiled_mma: cute.TiledMma, ...):
       gA = cute.local_tile(mA, mma_tiler_mnk, mma_coord, proj=(1, None, 1)) # (BM, BK, k) for A
       gB = cute.local_tile(mB, mma_tiler_mnk, mma_coord, proj=(None, 1, 1)) # (BN, BK, k) for B
       gC = cute.local_tile(mC, mma_tiler_mnk, mma_coord, proj=(1, 1, None)) # (BM, BN) for C

       # Single CTA MMA: cta index is always 0
       thr_mma = tiled_mma.get_slice(0)

       tCgA = thr_mma.partition_A(gA)   # (MMA, MMA_M, MMA_K, num_k_tiles) for A
       tCgB = thr_mma.partition_B(gB)   # (MMA, MMA_N, MMA_K, num_k_tiles) for B
       tCgC = thr_mma.partition_C(gC)   # (MMA, MMA_M, MMA_N) for C

Trivial TiledMma with CtaGroup.TWO MMAs (2-CTA cluster, each CTA owns half the M-tile):
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

With ``CtaGroup.TWO``, two CTAs cooperate on a single tile. The V-coordinate
(0 or 1) identifies which CTA within the pair. ``get_slice(V)`` gives each CTA
its half of the M dimension, while B is fully shared.


Example: ``GEMM (M, N, K) = (512, 768, 384)``, ``mma_tiler_mnk = (256, 256, 64)``,
``CtaGroup.TWO``, F16 MMA atom = 128x256x16 (inst_M=128, inst_N=256, inst_K=16).

Global matrices:

.. code-block:: text

  mA: (M, K) = (512, 384)       mB: (N, K) = (768, 384)        mC: (M, N) = (512, 768)

      K=384                          K=384                            N=768
  |<----------->|               |<----------->|                |<----------------->|
  +-------------+               +-------------+                +---+---+---+-------+
  |             | ^             |             | ^              |   |   |   |       | ^
  |     mA      | | M=512       |     mB      | | N=768        |   |   |   |       | | M=512
  |             | v             |             | v              |   |   |   |       | v
  +-------------+               +-------------+                +---+---+---+-------+

Tiling with ``mma_tiler_mnk = (BM, BN, BK) = (256, 256, 64)`` gives
M/BM = 512/256 = 2 tiles in M-mode, N/BN = 768/256 = 3 tiles in N-mode, K/BK = 384/64 = 6 tiles in K-mode:

.. code-block:: text

  mA tiled into (M/BM x K/BK)       mB tiled into (N/BN x K/BK)     mC tiled into (M/BM x N/BN)
  = (2 x 6) blocks                  = (3 x 6) blocks                 = (2 x 3) blocks
                                                                     * coordinates annotated on the matrix
                                                                       are the mma_coord_mn of the GEMM.

    BK=64  x6                       BK=64  x6                         BN=256  x3
  |<--->|                         |<--->|                        |<----->|
  +-----+-----+-- --+             +-----+-----+-- --+            +-------+-------+-------+
  |     |     |..|  | ^           |     |     |..|  | ^          | (0,0) | (0,1) | (0,2) | ^
  |     |     |  |  | | BM=256    |     |     |  |  | | BN=256   |       |       |       | | BM=256
  +-----+-----+-- --+ v           +-----+-----+-- --+ v          +-------+-------+-------+ v
  |     |     |..|  | ^           |     |     |..|  | ^          | (1,0) | (1,1) | (1,2) | ^
  |     |     |  |  | | BM=256    |     |     |  |  | | BN=256   |       |       |       | | BM=256
  +-----+-----+-- --+ v           +-----+-----+-- --+ v          +-------+-------+-------+ v
                                  |     |     |..|  | ^
                                  |     |     |  |  | | BN=256
                                  +-----+-----+-- --+ v

Each CTA pair picks one (M-coord, N-coord) coordinate.
For example, CTA pair at ``mma_coord_mnk = (0, 0, :)``.

.. code-block:: text

     gA: (BM, BK, k) = (256, 64, 6)   gB: (BN, BK, k) = (256, 64, 6)   gC: (BM, BN) = (256, 256)

          BK=64                          BK=64                       BN=256
        |<----->|                     |<----->|                 |<--------->|
        +-------+--                   +-------+--               +-----------+
        |       |..                   |       |..               |           | ^
   BM=  |  gA   | k=6             BN= |  gB   | k=6         BM= |    gC     | 256
    256 |       |                 256 |       |                 |           | v
        +-------+                     +-------+                 +-----------+

``get_slice(V)`` splits BM between CTAs; BK is split into ``MMA_K`` steps:

.. code-block:: text

        gA (BM split, BK split into MMA_K atoms)                gC (BM split)
          inst_K  inst_K  inst_K  inst_K
          =16     =16     =16     =16
        |<--->|<--->|<--->|<--->|
        +-----+-----+-----+-----+--                             +-----------+
        |  0  |  1  |  2  |  3  |..  ^  CTA 0                   |   CTA 0   | ^
        |     |     |     |     |    | BM/2=128 (V=0)           |   (V=0)   | | BM/2=128
        +-----+-----+-----+-----+    v                          +-----------+ v
        |  0  |  1  |  2  |  3  |..  ^  CTA 1                   |   CTA 1   | ^
        |     |     |     |     |    | BM/2=128 (V=1)           |   (V=1)   | | BM/2=128
        +-----+-----+-----+-----+    v                          +-----------+ v
        |<-- MMA_K = BK/inst_K = 4 -->|

        gB (BN split for SMEM loading, BK split into MMA_K atoms)
          inst_K  inst_K  inst_K  inst_K
          =16     =16     =16     =16
        |<--->|<--->|<--->|<--->|
        +-----+-----+-----+-----+--
        |  0  |  1  |  2  |  3  |..  ^  CTA 0
        |     |     |     |     |    | BN/2=128  (V=0)
        +-----+-----+-----+-----+    v
        |  0  |  1  |  2  |  3  |..  ^  CTA 1
        |     |     |     |     |    | BN/2=128  (V=1)
        +-----+-----+-----+-----+    v

Both CTAs consume the full gB for MMA, but for SMEM loading each CTA loads
its N-half.

After partition (per CTA, e.g. CTA 0):

- ``tCgA: (MMA, MMA_M, MMA_K, k) = (MMA, 1, 4, 6)`` — MMA_M = (BM/2)/inst_M = 128/128 = 1, MMA_K = BK/inst_K = 64/16 = 4
- ``tCgB: (MMA, MMA_N, MMA_K, k) = (MMA, 1, 4, 6)`` — MMA_N = BN/inst_N = 256/256 = 1, MMA_K = BK/inst_K = 64/16 = 4
- ``tCgC: (MMA, MMA_M, MMA_N) = (MMA, 1, 1)`` — MMA_M = (BM/2)/inst_M = 1, MMA_N = BN/inst_N = 1

Of course with CuTe DSL none of these calculations are needed.
The DSL handles all the tiling and partitioning for you provided ``mma_tiler_mnk`` and ``mma_coord``.

.. code-block:: python

  @cute.kernel
  def kernel(tiled_mma: cute.TiledMma, cta_layout_vmnk: cute.Layout, ...):
      bidx, bidy, _ = cute.arch.block_idx()

      # V-coordinate: which CTA within the 2-CTA group (0 or 1)
      mma_coord_vmnk = (
          bidx % cute.size(cta_layout_vmnk, mode=[0]),   # V (CTA rank)
          bidx // cute.size(cta_layout_vmnk, mode=[0]),   # M tile
          bidy,                                           # N tile
          None,                                           # K (all tiles)
      )
      mma_coord_mnk = mma_coord_vmnk[1:]

      gA = cute.local_tile(mA, mma_tiler_mnk, mma_coord_mnk, proj=(1, None, 1))
      gB = cute.local_tile(mB, mma_tiler_mnk, mma_coord_mnk, proj=(None, 1, 1))
      gC = cute.local_tile(mC, mma_tiler_mnk, mma_coord_mnk, proj=(1, 1, None))

      # 2-CTA: each CTA passes its V-coordinate to get its half of the work
      thr_mma = tiled_mma.get_slice(mma_coord_vmnk[0])

      tCgA = thr_mma.partition_A(gA)   # (MMA, MMA_M, MMA_K, num_k_tiles)
      tCgB = thr_mma.partition_B(gB)   # (MMA, MMA_N, MMA_K, num_k_tiles)
      tCgC = thr_mma.partition_C(gC)   # (MMA, MMA_M, MMA_N)

.. note:: Annotation `tCgX` means that the tensor is partitioned w.r.t C matrix coordinates, i.e., the output tile of each CTA.

Pre and Post-Conditions for TiledMMA Partitioning
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

* The inputs of the partition should be at least rank-2 tensors.
* The output of the partition will have the layout that is compatible with the MMA atom's operand:
  - For A, the output will have the layout (MMA, MMA_M, MMA_K, ...).
  - For B, the output will have the layout (MMA, MMA_N, MMA_K, ...).
  - For C, the output will have the layout (MMA, MMA_M, MMA_N, ...).
* Note that the partition doesn't enforce any rules on the tensor's memory space or the tensor's data type. It only cares about the layout.


What happens when we use ``atom_layout_mnk``?
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The valid coordinates to ``get_slice`` are the valid coordinates to (v,m,n,k) coordinate space
of the tiled MMA. ``mma_tiler_mnk`` should be updated such that ``mma_tiler_mnk[0] >= mma_shape[0] * |m|``,
``mma_tiler_mnk[1] >= mma_shape[1] * |n|``, and ``mma_tiler_mnk[2] >= mma_shape[2] * |k|``.

The result of the ``partition_A``, ``partition_B``, and ``partition_C`` remain the same.

Making Fragments
-----------------

Fragments are the descriptor-level tensors that the MMA
instruction operates on. For tcgen05:

- **Fragment A**: SMEM descriptor when ``a_src=SMEM``, or a TMEM address when
  ``a_src=TMEM``.
- **Fragment B**: SMEM descriptor pointing into staged shared memory buffers.
- **Fragment C (accumulator)**: lives in Tensor Memory (TMEM), allocated via
  ``TmemAllocator``.

Creating fragment descriptors and descriptor tensors
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Unlike older architectures where fragments live in per-thread registers,
tcgen05 fragments are **descriptors** pointing into SMEM (for A and B) or
**addresses** into TMEM (for the accumulator C). The fragment creation has
three parts:

**1. A and B fragments**

*When A comes from SMEM* (``a_src=OperandSource.SMEM``):

``make_fragment_A`` and ``make_fragment_B`` take the staged SMEM tensors
(``sA``, ``sB``) and produce descriptor tensors that the MMA instruction
consumes. Each descriptor points to one stage's tile in shared memory.

.. code-block:: python

   # 1. Build the SMEM layouts (see "Creating SMEM layouts for A and B")
   # a_smem_layout = sm100_utils.make_smem_layout_a(tiled_mma, mma_tiler_mnk, ...)
   # b_smem_layout = sm100_utils.make_smem_layout_b(tiled_mma, mma_tiler_mnk, ...)

   # 2. Allocate SMEM tensors from those layouts
   # sA = smem.allocate_tensor(layout=a_smem_layout.outer, swizzle=a_smem_layout.inner, ...)
   # sB = smem.allocate_tensor(layout=b_smem_layout.outer, swizzle=b_smem_layout.inner, ...)

   # 3. Create fragment descriptors from the SMEM tensors
   tCrA = tiled_mma.make_fragment_A(sA)  # (MMA, MMA_M, MMA_K, STAGE)
   tCrB = tiled_mma.make_fragment_B(sB)  # (MMA, MMA_N, MMA_K, STAGE)

Continuing the CtaGroup.ONE example (m128n256k16 atom,
``mma_tiler_mnk = (128, 256, 64)``, 3 pipeline stages):

.. code-block:: text

  sA is an SMEM tensor with shape (MMA, MMA_M, MMA_K, STAGES),
  allocated with appropriate size (see "Creating SMEM layouts for A and B").

  For 128x256x16 atom, mma_tiler_mnk = (BM, BN, BK) = (128, 256, 64), 3 stages:
   MMA_M = BM/inst_M = 128/128 = 1, MMA_K = BK/inst_K = 64/16 = 4, STAGES = 3

  sA: (MMA, MMA_M=1, MMA_K=4, STAGES=3)

                |<--MMA_K = BK/inst_K = 4-->|
    stage 0:    +------+------+------+------+
                | k=0  | k=1  | k=2  | k=3  |  inst_M=128
                +------+------+------+------+
    stage 1:    +------+------+------+------+
                | k=0  | k=1  | k=2  | k=3  |  inst_M=128
                +------+------+------+------+
    stage 2:    +------+------+------+------+
                | k=0  | k=1  | k=2  | k=3  |  inst_M=128
                +------+------+------+------+

  make_fragment_A(sA) produces SMEM descriptors with the same shape:
  tCrA: (MMA, MMA_M, MMA_K, STAGES) = (MMA, 1, 4, 3)

  Each element is an SMEM descriptor — one per (MMA_K, STAGE) pair.
  Similarly for sB/tCrB with shape (MMA, MMA_N=1, MMA_K=4, STAGE=3).

Each element of ``tCrA`` / ``tCrB`` is an SMEM descriptor that the MMA
hardware reads directly — not a register value. Note that, when we print the
layout of ``tCrA`` (or similarly ``tCrB``), we will see that ``MMA`` dimension
of ``(MMA, MMA_M, MMA_K, STAGES)`` will appear to be ``1``. This is because
this mode is an indivisible SMEM descriptor representing the whole SMEM buffer
that a single MMA instruction will consume.

*When A comes from TMEM* (``a_src=OperandSource.TMEM``):

In use cases like FMHA or mixed-input GEMM, operand A can be sourced from
TMEM instead of SMEM. In this case, ``make_fragment_A`` is called to obtain
the layout, but the fragment is bound to a TMEM pointer instead of an SMEM
tensor:

.. code-block:: python

  # Build the SMEM layout for A (see `Creating SMEM layouts for A and B`_).
  # The layout defines the tile shape the MMA expects, even though the data
  # will live in TMEM.
  # a_smem_layout = sm100_utils.make_smem_layout_a(...)

  # Use make_fragment_A with the outer layout to get the expected shape
  tCrA_layout = tiled_mma.make_fragment_A(a_smem_layout.outer).layout

  # Compute the TMEM pointer offset (A is placed after the accumulator columns).
  # TMEM columns are 32-bit wide, so scale to element offset for narrower types
  # (e.g. Float16: scale = 32 // 16 = 2).
  column_to_element_scale = 32 // acc_dtype.width
  tmem_ptr_a = cute.recast_ptr(
      accumulators.iterator + num_acc_tmem_cols * column_to_element_scale,
      dtype=mma_dtype,
  )

  # Bind to TMEM storage
  tCrA = cute.make_tensor(tmem_ptr_a, tCrA_layout)

The A fragment in TMEM is laid out after the accumulator's TMEM columns.

**2. C fragment (accumulator) — TMEM allocation**

The accumulator lives in Tensor Memory (TMEM), a dedicated on-chip memory
separate from registers and SMEM. Creating the C fragment is a four-step
process:

.. code-block:: python

  # Step 1: Query the partitioned accumulator shape
  acc_shape = tiled_mma.partition_shape_C(mma_tiler_mnk[:2])
  # acc_shape: (MMA, MMA_M, MMA_N) = (MMA, 1, 1)

  # Step 2: Append a staging dimension for ping-pong overlap
  #   Use 1 for simple kernels (no overlap), or 2+ to overlap
  #   MMA and epilogue on different TMEM buffers.
  num_acc_stages = 2
  acc_shape_staged = cute.append(acc_shape, num_acc_stages)

  # Step 3: Create a fragment to establish the layout
  tCtAcc = tiled_mma.make_fragment_C(acc_shape_staged)
  # tCtAcc: (MMA, MMA_M, MMA_N, ACC_STAGE)

  # Step 4: Bind to actual TMEM storage
  tmem_ptr = tmem.retrieve_ptr(cutlass.Float32)
  tCtAcc = cute.make_tensor(tmem_ptr, tCtAcc.layout)

.. code-block:: text

  partition_shape_C((BM, BN) = (128, 256))
   -> (MMA, MMA_M, MMA_N) = (MMA, 1, 1)
       MMA_M = BM/inst_M = 128/128 = 1
       MMA_N = BN/inst_N = 256/256 = 1

  cute.append(acc_shape, 2)
   -> (MMA, 1, 1, 2)

  make_fragment_C(acc_shape_staged)
   -> tCtAcc layout: ((128, 256), 1, 1, 2)

  After binding to TMEM (2-stage ping-pong):
  +---------------------------+---------------------------+
  |  tCtAcc stage 0           |  tCtAcc stage 1           |
  |  128 x 256 accumulators   |  128 x 256 accumulators   |
  |  (Float32)                |  (Float32)                |
  +---------------------------+---------------------------+


Creating SMEM layouts for A and B
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The SMEM layouts define how A and B tiles are stored in shared memory, including
swizzling for bank-conflict-free access. The helper functions handle the
details: partitioned shape from the tiled MMA, swizzle atom selection, tiling to
the MMA shape, and multi-stage buffering.

**Host side** (``@cute.jit``):

.. code-block:: python

   import cutlass.utils.blackwell_helpers as sm100_utils

   # Create SMEM layouts (includes swizzle + staging)
   a_smem_layout = sm100_utils.make_smem_layout_a(
       tiled_mma, mma_tiler_mnk, a.element_type, num_stages,
   )
   b_smem_layout = sm100_utils.make_smem_layout_b(
       tiled_mma, mma_tiler_mnk, b.element_type, num_stages,
   )

``make_smem_layout_a`` and ``make_smem_layout_b`` are convenience helpers that
build a complete, staged SMEM layout in four steps:

1. **Determine the major mode.** The major mode (K-major or MN-major) is read
   from the MMA op's ``a_major_mode`` / ``b_major_mode`` attribute (or can be
   overridden via the ``is_k_major`` keyword argument).

2. **Compute the partitioned SMEM tile shape.** The tiled MMA is asked for the
   partitioned shape of the operand via ``tiled_mma.partition_shape_A``
   (or ``partition_shape_B``). ``cute.dice`` strips the irrelevant mode first
   — for A the ``(M, K)`` portion is kept, for B the ``(N, K)`` portion. The
   result is a hierarchical shape ``((MMA, MMA_MN, MMA_K), repeat_MN, repeat_K)``
   that is flattened into a 2D ``(MN, K)`` size for swizzle selection.

3. **Select and materialise the swizzle atom.** A heuristic
   (``get_smem_layout_atom_ab``) picks the widest swizzle whose contiguous
   size (in bits) evenly divides the major-mode dimension:

   ==========  ==================
   Swizzle     Contiguous bits
   ==========  ==================
   SW128       1024 (128 B)
   SW64        512  (64 B)
   SW32        256  (32 B)
   Interleave  128  (16 B)
   ==========  ==================

   ``make_smem_layout_atom`` then combines the chosen swizzle with a compact
   ``(MN_elems, 8)`` or ``(8, K_elems)`` outer layout (depending on the major
   mode) into a ``ComposedLayout(swizzle, outer)``.

4. **Tile to the MMA shape and append the staging dimension.**
   ``tile_to_mma_shape`` broadcasts the atom to the full partitioned shape
   (with ``num_stages`` appended). The ``order`` argument controls which
   dimension is contiguous: ``(1, 2, 3)`` for K-major (K innermost),
   ``(2, 1, 3)`` for MN-major (MN innermost).

The resulting layout is then fed into SMEM tensors are allocated using
the layout info:

**Kernel side** (``@cute.kernel``):

.. code-block:: python

   smem = cutlass.utils.SmemAllocator()
   sA = smem.allocate_tensor(
       element_type=io_dtype,
       layout=a_smem_layout.outer,
       byte_alignment=128,
       swizzle=a_smem_layout.inner,
   )
   sB = smem.allocate_tensor(
       element_type=io_dtype,
       layout=b_smem_layout.outer,
       byte_alignment=128,
       swizzle=b_smem_layout.inner,
   )

.. note:: **Creating SMEM layouts without utilities**
  If you want to create SMEM layouts without using the utilities, you can do the following:

  .. code-block:: python

    swizzle = cute.Swizzle(3, 4, 3)
    mma_tile = tiled_mma.partition_shape_A((mma_tiler_mnk[0], mma_tiler_mnk[2]))
    smem_tile = tcgen05.tile_to_mma_shape(swizzle, mma_tile, order=(1, 2, 3))


Executing the GEMM (Main Loop)
-------------------------------

The main loop iterates over K-tiles, loading A and B from global memory via TMA
into staged SMEM buffers, then issuing ``cute.gemm`` for each tile. The TMA copy
details are omitted for brevity.

.. code-block:: python

   for k_tile_idx in cutlass.range(num_k_tiles):
      # Wait for TMA load to complete for this K-tile
      ab_full = ab_consumer.wait_and_advance()

      # Set accumulate mode: first tile overwrites, subsequent tiles accumulate
      tiled_mma.set(tcgen05.Field.ACCUMULATE, k_tile_idx != 0)

      # Issue MMA: tCtAcc += tCrA * tCrB
      tile_crd = (None, None, None, ab_full.index)
      cute.gemm(tiled_mma, tCtAcc, tCrA[tile_crd], tCrB[tile_crd], tCtAcc)

      # Release the SMEM buffer for the next TMA load
      ab_full.release()

Key points:

- ``tcgen05.Field.ACCUMULATE`` controls whether the MMA accumulates into D
  (``True``) or overwrites D with ``A * B`` (``False``). Set to ``False`` for
  the first K-tile and ``True`` for all subsequent tiles.
- ``cute.gemm`` is asynchronous. Synchronization is handled by the pipeline
  barriers (``cutlass.pipeline.sm100.PipelineTmaUmma``).
- The ``tile_crd`` selects which pipeline stage's SMEM buffer to read from.

Reading the accumulator from TMEM
----------------------------------

.. code-block:: python

   tCtAcc = tiled_mma.make_fragment_C(mma_tiler_mnk[:2]) # (MMA, MMA_M, MMA_N) for C
   # TMEM allocation (done once, before the main loop)
   tmem = cutlass.utils.TmemAllocator(...)
   tmem.allocate(num_cols=512)
   tmem_ptr = tmem.retrieve_ptr(cutlass.Float32)
   tCtAcc = cute.make_tensor(tmem_ptr, tCtAcc.layout)

   # Build copy atom for TMEM → RMEM load
   copy_atom_t2r = cute.make_copy_atom(
       tcgen05.Ld32x32bOp(tcgen05.Repetition.x64),
       cutlass.Float32,
   )
   tiled_copy_t2r = tcgen05.make_tmem_copy(copy_atom_t2r, tCtAcc[(None, None), 0, 0])
   thr_copy_t2r = tiled_copy_t2r.get_slice(tidx)

   # (T2R, T2R_M, NumTiles)
   tTR_tAcc = thr_copy_t2r.partition_S(tCtAcc)
   # (T2R, T2R_M, NumTiles)
   tTR_gC = thr_copy_t2r.partition_D(tCgC)

   # (T2R, T2R_M)
   tTR_rAcc = cute.make_rmem_tensor(tTR_gC[None, None, 0].shape, acc_dtype)

   cute.copy(tiled_copy_t2r, tTR_tAcc[None, None, i], tTR_rAcc)


Complete Workflow
------------------

Putting it all together, a typical Blackwell tcgen05 GEMM has this structure:

**Host function** (``@cute.jit``):

.. code-block:: python

   import cutlass
   import cutlass.cute as cute
   from cutlass.cute.nvgpu import cpasync, tcgen05, OperandMajorMode
   import cutlass.utils.blackwell_helpers as sm100_utils

   @cute.jit
   def host_function(a: cute.Tensor, b: cute.Tensor, c: cute.Tensor):
       # 1. Create the MMA op and tiled MMA
       op = tcgen05.MmaF16BF16Op(
           cutlass.Float16, cutlass.Float32,
           (128, 256, 16),
           tcgen05.CtaGroup.ONE,
           tcgen05.OperandSource.SMEM,
           OperandMajorMode.K,
           OperandMajorMode.K,
       )
       tiled_mma = cute.make_tiled_mma(op)

       # 2. Create SMEM layouts for A and B
       a_smem_layout = sm100_utils.make_smem_layout_a(
           tiled_mma, mma_tiler_mnk, a.element_type, num_stages,
       )
       b_smem_layout = sm100_utils.make_smem_layout_b(
           tiled_mma, mma_tiler_mnk, b.element_type, num_stages,
       )

       # 3. Create TMA copy atoms for global -> shared memory loads
       copy_op = cpasync.CopyBulkTensorTileG2SOp(tcgen05.CtaGroup.ONE)
       tma_a = cute.nvgpu.make_tiled_tma_atom_A(
           copy_op, a, a_smem_layout, mma_tiler_mnk, tiled_mma,
       )
       tma_b = cute.nvgpu.make_tiled_tma_atom_B(
           copy_op, b, b_smem_layout, mma_tiler_mnk, tiled_mma,
       )

       # 4. Launch the kernel
       grid = cute.ceil_div((*c.layout.shape, 1), mma_tiler_mnk[:2])
       kernel(tiled_mma, tma_a, tma_b, c).launch(
           grid=grid, block=(128, 1, 1),
       )

**Kernel function** (``@cute.kernel``):

.. code-block:: python

   @cute.kernel
   def kernel(
       tiled_mma: cute.TiledMma,
       tma_a: cpasync.TmaInfo,
       tma_b: cpasync.TmaInfo,
       mC: cute.Tensor,
   ):
       # -- Setup --
       bidx, bidy, _ = cute.arch.block_idx()
       mma_coord_mnk = (bidx, bidy, None)

       # Global tensors for A and B live inside the TMA descriptor
       mA = tma_a.tma_tensor   # (M, K)
       mB = tma_b.tma_tensor   # (N, K)

       # Allocate SMEM for A, B (staged) and pipeline barriers
       smem = cutlass.utils.SmemAllocator()
       sA = smem.allocate_tensor(...)  # staged SMEM for A
       sB = smem.allocate_tensor(...)  # staged SMEM for B

       # Allocate TMEM for the accumulator
       tmem = cutlass.utils.TmemAllocator(...)
       tmem.allocate(num_cols=512)

       # -- Partition and make fragments --
       # (BM, BK, k)
       gA = cute.local_tile(mA, mma_tiler_mnk, mma_coord_mnk, proj=(1, None, 1))
       # (BN, BK, k)
       gB = cute.local_tile(mB, mma_tiler_mnk, mma_coord_mnk, proj=(None, 1, 1))
       # (BM, BN)
       gC = cute.local_tile(mC, mma_tiler_mnk, mma_coord_mnk, proj=(1, 1, None))

       thr_mma = tiled_mma.get_slice(0)
       tCgA = thr_mma.partition_A(gA)   # (MMA, MMA_M, MMA_K, num_k_tiles)
       tCgB = thr_mma.partition_B(gB)   # (MMA, MMA_N, MMA_K, num_k_tiles)
       tCgC = thr_mma.partition_C(gC)   # (MMA, MMA_M, MMA_N)

       # SMEM descriptor fragments
       tCrA = tiled_mma.make_fragment_A(sA)   # (MMA, MMA_M, MMA_K, STAGE)
       tCrB = tiled_mma.make_fragment_B(sB)   # (MMA, MMA_N, MMA_K, STAGE)

       # TMEM accumulator
       acc_shape = tiled_mma.partition_shape_C(mma_tiler_mnk[:2])
       tCtAcc = tiled_mma.make_fragment_C(acc_shape)  # (MMA, MMA_M, MMA_N)

       # Bind accumulator to TMEM
       tmem.wait_for_alloc()
       tmem_ptr = tmem.retrieve_ptr(cutlass.Float32)
       tCtAcc = cute.make_tensor(tmem_ptr, tCtAcc.layout)

       # TMA partition for global → shared memory copies
       tAsA, tAgA = cute.nvgpu.cpasync.tma_partition(
           tma_a.atom, 0, cute.make_layout(1),
           cute.group_modes(sA, 0, 3), cute.group_modes(tCgA, 0, 3),
       )
       tBsB, tBgB = cute.nvgpu.cpasync.tma_partition(
           tma_b.atom, 0, cute.make_layout(1),
           cute.group_modes(sB, 0, 3), cute.group_modes(tCgB, 0, 3),
       )

       # -- Main loop: iterate over K-tiles --
       num_k_tiles = cute.size(gA, mode=[2])
       for k_tile_idx in cutlass.range(num_k_tiles):
           # TMA load A, B into staged SMEM (producer side)
           # copy(tma_a.atom, tAgA[k], tAsA[stage])
           # copy(tma_b.atom, tBgB[k], tBsB[stage])
           # ... (see pipeline documentation)

           # Wait for data
           ab_full = ab_consumer.wait_and_advance()

           # MMA
           tiled_mma.set(tcgen05.Field.ACCUMULATE, k_tile_idx != 0)
           tile_crd = (None, None, None, ab_full.index)
           cute.gemm(tiled_mma, tCtAcc, tCrA[tile_crd], tCrB[tile_crd], tCtAcc)

           ab_full.release()

       # -- Epilogue: copy accumulator from TMEM to global memory --
       copy_atom_t2r = cute.make_copy_atom(
           tcgen05.Ld32x32bOp(tcgen05.Repetition.x64), cutlass.Float32,
       )
       tiled_copy_t2r = tcgen05.make_tmem_copy(copy_atom_t2r, tCtAcc[(None, None), 0, 0])
       thr_copy_t2r = tiled_copy_t2r.get_slice(tidx)

       tTR_tAcc = thr_copy_t2r.partition_S(tCtAcc)
       tTR_gC   = thr_copy_t2r.partition_D(tCgC)
       tTR_rAcc = cute.make_rmem_tensor(tTR_gC[None, None, 0].shape, acc_dtype)

       # TMEM → RMEM, then RMEM → GMEM
       for i in cutlass.range(num_tiles):
           cute.copy(tiled_copy_t2r, tTR_tAcc[None, None, i], tTR_rAcc)
           cute.copy(store_atom, tTR_rAcc, tTR_gC[None, None, i])


Beyond Simple Dense MMAs
------------------------

The tcgen05 MMA DSL supports more complex MMA operations than just the simple dense MMA.


- Block-scaled MMA

.. {$nv-internal-release begin}

Internal builds additionally provide:

- Sparse MMA

.. {$nv-internal-release end}

.. {$nv-internal-release begin}

Sparse MMA
~~~~~~~~~~

Sparse MMA exploits **X:Y = {1:2, 2:4, 4:8} structured sparsity** in operand A: out of every
Y consecutive K-elements, exactly X are non-zero and Y-X are zero. The
kernel stores the compressed A values separately from the **metadata**
tensor ``E``, which records which 2 of 4 positions are non-zero.

Compared to a dense MMA kernel, a sparse kernel differs in five areas:

**1. MMA op creation** — use ``MmaF16BF16SparseOp`` with an extra
``sparse_metadata_format`` parameter. The instruction K is **doubled**
(32 vs 16 for dense F16/BF16) to account for the compressed operand. The
example here builds its sparse ``TiledMma`` through
``sm100_utils.make_sparse_trivial_tiled_mma(...)``:

.. code-block:: python

   from cutlass.cute.nvgpu.warp.mma import SparseMetadataFormat

   # Dense F16 (for comparison): inst_K = 16
   dense_op = tcgen05.MmaF16BF16Op(
       cutlass.Float16, cutlass.Float32, (128, 256, 16),
       tcgen05.CtaGroup.ONE, tcgen05.OperandSource.SMEM,
       cute.nvgpu.OperandMajorMode.K, cute.nvgpu.OperandMajorMode.K,
   )

   # Sparse F16: inst_K = 32 (2× dense, since A is 2:4 compressed)
   sparse_op = tcgen05.MmaF16BF16SparseOp(
       cutlass.Float16, cutlass.Float32, (128, 256, 32),
       tcgen05.CtaGroup.ONE, tcgen05.OperandSource.SMEM,
       cute.nvgpu.OperandMajorMode.K, cute.nvgpu.OperandMajorMode.K,
       SparseMetadataFormat.TID,
   )

   # The sparse GEMM example uses the public helper
   tiled_mma = sm100_utils.make_sparse_trivial_tiled_mma(
       a_raw_dtype, a_major_mode, b_major_mode, acc_dtype, cta_group,
       mma_tiler_mn=mma_tiler_mnk[:2],
       sparse_metadata_format=SparseMetadataFormat.TID,
   )

**2. Compressed A and metadata E tensors** — operand A is stored with
**half** the K-elements (the two non-zero values per group of 4), using a
``sparse_elem<2, dtype>`` type. The metadata tensor E is a compact bit-field
(``sparse_elem<8, uint8>`` for F16/BF16) that encodes the sparsity pattern.

.. code-block:: python

   # Sparse element types
   a_sparse_dtype = sm100_utils.make_sparse_a_dtype(a_raw_dtype)   # sparse_elem<2, F16>
   e_sparse_dtype = sm100_utils.make_sparse_e_dtype(a_raw_dtype)   # sparse_elem<8, uint8>

   # GMEM layouts for compressed A and metadata E
   sp_a_ptr = cute.recast_ptr(a.iterator, dtype=a_sparse_dtype)
   sp_a_layout = sm100_utils.make_sparse_gmem_layout_a(
       mnkl,
       a_raw_dtype,
       is_k_major=(a_major_mode == cute.nvgpu.OperandMajorMode.K),
       sparsity=2,
   )
   sp_a_tensor = cute.make_tensor(sp_a_ptr, sp_a_layout)

   sp_e_ptr = cute.recast_ptr(e.iterator, dtype=e_sparse_dtype)
   sp_e_layout = sm100_utils.make_sparse_gmem_layout_e(mnkl, a_raw_dtype)
   sp_e_tensor = cute.make_tensor(sp_e_ptr, sp_e_layout)

.. code-block:: text

   Dense A: (M, K)                    Sparse A (compressed): (M, (2, K/2))
   +--+--+--+--+--+--+--+--+         +--+--+--+--+
   | a| 0| b| 0| c| 0| d| 0|   →     | a| b| c| d|   (only non-zeros stored)
   +--+--+--+--+--+--+--+--+         +--+--+--+--+

   Metadata E encodes positions:      E: [00, 10, 00, 10]
   (which 2 of 4 are non-zero)            ↑       ↑
                                       positions of a,b in each group

**3. Extra SMEM layouts, TMA loads, and allocations** — sparse kernels use
dedicated layout helpers for A and E. An additional TMA descriptor loads
the metadata into SMEM alongside A and B. In the example here,
``E`` uses its own logical tile ``mma_tiler_e``:

.. code-block:: python

   # Host side: SMEM layouts
   a_smem_layout = sm100_utils.make_sparse_smem_layout_a(
       tiled_mma, mma_tiler_mnk, a_raw_dtype, num_stages, sparsity=2,
   )
   e_smem_layout = sm100_utils.make_sparse_smem_layout_e(
       tiled_mma, mma_tiler_e, a_raw_dtype, num_stages,
   )

   # Host side: TMA atom for metadata E (note mma_tiler_e and internal_type=Uint64)
   a_op = sm100_utils.cluster_shape_to_tma_atom_A(cluster_shape_mn, tiled_mma.thr_id)
   tma_atom_e, tma_tensor_e = cute.nvgpu.make_tiled_tma_atom_A(
       a_op,
       sp_e_tensor,
       cute.slice_(e_smem_layout, (None, None, None, 0)),
       mma_tiler_e,
       tiled_mma,
       cluster_layout_vmnk.shape,
       internal_type=cutlass.Uint64,
   )

   # Kernel side: SMEM allocation for metadata
   sE = smem.allocate_tensor(
       element_type=e_sparse_dtype,
       layout=e_smem_layout.outer,
       byte_alignment=128,
       swizzle=e_smem_layout.inner,
   )

**4. Metadata TMEM allocation and SMEM→TMEM copy (S2T)** — the metadata
must live in TMEM for the MMA instruction. It is placed **after** the
accumulator columns, and an S2T copy moves it from SMEM to TMEM each
K-tile. The example here also recasts both sides to raw ``uint8``
before building the S2T copy and wraps the SMEM source in an S2T
descriptor tensor:

.. code-block:: python

   # TMEM layout for metadata (placed after accumulator)
   e_tmem_layout = sm100_utils.make_sparse_tmem_layout_e(
       cute.slice_(e_smem_layout_staged, (None, None, None, 0)).shape,
       a_raw_dtype,
   )
   acc_tmem_col_offset = tcgen05.find_tmem_tensor_col_offset(tCtAcc_base)
   if cutlass.const_expr(acc_dtype.width < 32):
       acc_tmem_col_offset = acc_tmem_col_offset * (32 // acc_dtype.width)
   e_tmem_ptr = cute.recast_ptr(
       acc_tmem_ptr + acc_tmem_col_offset, dtype=e_sparse_dtype,
   )
   tCtE = cute.make_tensor(e_tmem_ptr, e_tmem_layout)

   # S2T copy setup (SMEM → TMEM for metadata)
   e_raw_dtype = cutlass.Uint8
   copy_atom_s2t_e = cute.make_copy_atom(
       tcgen05.Cp128x128bOp(cta_group), e_raw_dtype,
   )
   tCtE_recast = cute.recast_tensor(tCtE, e_raw_dtype)
   tiled_copy_s2t_E = tcgen05.make_s2t_copy(copy_atom_s2t_e, tCtE_recast)
   thr_copy_s2t_E = tiled_copy_s2t_E.get_slice(0)

   sE_recast = cute.recast_tensor(sE, e_raw_dtype)
   thr_tCsE_s2t_ = thr_copy_s2t_E.partition_S(sE_recast)
   thr_tCsE_s2t = tcgen05.get_s2t_smem_desc_tensor(
       tiled_copy_s2t_E, thr_tCsE_s2t_
   )
   thr_tCtE_s2t = thr_copy_s2t_E.partition_D(tCtE_recast)

**5. Modified main loop** — each K-tile iteration loads the metadata via
S2T, then sets the ``METADATA`` field on the atom before calling ``gemm``.
The ``gemm`` call signature itself is unchanged; the metadata is implicit
via the atom field. The full kernel also contains leader-CTA
synchronization and optional metadata reuse when ``utccp_reuse_cnt > 1``;
the schematic below keeps only the dataflow-relevant steps:

.. code-block:: python

   tiled_mma.set(tcgen05.Field.ACCUMULATE, False)

   for k_tile in range(k_tile_cnt):
       # S2T: move metadata for the current stage from SMEM to TMEM.
       cute.copy(tiled_copy_s2t_E, e_smem_stage, e_tmem_stage)

       for kblk_idx in cutlass.range(cute.size(tCrA, mode=[2]), unroll_full=True):
           e_idx = metadata_index_for(k_tile, kblk_idx)
           tiled_mma.set(tcgen05.Field.METADATA, tCtE[None, None, e_idx].iterator)
           cute.gemm(tiled_mma, tCtAcc, tCrA_kblk, tCrB_kblk, tCtAcc)
           tiled_mma.set(tcgen05.Field.ACCUMULATE, True)

.. code-block:: text

   Dense main loop (per K-tile):
     set(ACCUMULATE, ...)
     gemm(tiled_mma, tCtAcc, tCrA[s], tCrB[s], tCtAcc)

   Sparse main loop (schematic, per K-tile):
     copy(s2t_E, sE[stage], tCtE)               ← metadata SMEM → TMEM
     set(METADATA, tCtE[e_idx].iterator)        ← point atom at metadata
     set(ACCUMULATE, ...)
     gemm(tiled_mma, tCtAcc, tCrA[s], tCrB[s], tCtAcc)   ← same call

The epilogue (TMEM → RMEM → GMEM) is identical to a dense kernel.

.. {$nv-internal-release end}


Block-scaled MMA
~~~~~~~~~~~~~~~~

Block-scaled MMA multiplies narrow-type matrices (the tcgen05 MXF8 and
MXF4-family ops shown here) with **per-block scale factors** along GEMM-K.
Each ``sf_vec_size`` consecutive K-elements shares one scale factor, so the
hardware computes ``D = (SFA · A) * (SFB · B) + C``. Unlike dense A/B,
SFA/SFB must be staged in **TMEM** before ``gemm``.

Supported ops: ``MmaMXF8F6F4Op``, ``MmaMXF4Op``, ``MmaMXF4NVF4Op``.

Compared to a dense MMA kernel, a block-scaled kernel differs in five areas:

**1. MMA op creation** — block-scaled ops fix the accumulator to FP32 and add
scale-factor typing. The examples usually build ``TiledMma`` through
``sm100_utils.make_blockscaled_trivial_tiled_mma(...)``, which dispatches to
``MmaMXF8F6F4Op``, ``MmaMXF4Op``, or ``MmaMXF4NVF4Op`` from
``(ab_dtype, sf_vec_size)``:

.. code-block:: python

   # Direct op examples
   mxf8_op = tcgen05.MmaMXF8F6F4Op(
       cutlass.Float8E4M3FN, (128, 256, 32),
       tcgen05.CtaGroup.ONE, tcgen05.OperandSource.SMEM,
       cute.nvgpu.OperandMajorMode.K, cute.nvgpu.OperandMajorMode.K,
   )

   # MXF4/NVF4 example (MmaMXF4Op is the sf_vec_size=32 companion)
   nvf4_op = tcgen05.MmaMXF4NVF4Op(
       cutlass.Float8E8M0FNU,     # sf_dtype: UE8M0 or UE4M3
       (128, 256, 64),
       tcgen05.CtaGroup.ONE, tcgen05.OperandSource.SMEM,
   )

   # Helper used by the block-scaled examples here
   tiled_mma = sm100_utils.make_blockscaled_trivial_tiled_mma(
       ab_dtype, a_major_mode, b_major_mode, sf_dtype, sf_vec_size,
       cta_group, mma_tiler_mn,
   )

**2. Extra scale-factor tensors and SMEM layouts** — derive SFA/SFB tensors
from the A/B shapes, then build staged SMEM layouts for them:

.. code-block:: python

   import cutlass.utils.blockscaled_layout as blockscaled_utils

   # Scale-factor tensors
   sfa_layout = blockscaled_utils.tile_atom_to_shape_SF(a_tensor.shape, sf_vec_size)
   sfa_tensor = cute.make_tensor(sfa_ptr, sfa_layout)
   sfb_layout = blockscaled_utils.tile_atom_to_shape_SF(b_tensor.shape, sf_vec_size)
   sfb_tensor = cute.make_tensor(sfb_ptr, sfb_layout)

   # Staged SMEM layouts
   sfa_smem_layout_staged = blockscaled_utils.make_smem_layout_sfa(
       tiled_mma, mma_tiler_mnk, sf_vec_size, num_ab_stage,
   )
   sfb_smem_layout_staged = blockscaled_utils.make_smem_layout_sfb(
       tiled_mma, mma_tiler_mnk, sf_vec_size, num_ab_stage,
   )

**3. Extra TMA loads and SMEM allocations** — there are four GMEM→SMEM loads
instead of two. SFA follows the A-side TMA path; SFB uses
``cluster_shape_to_tma_atom_SFB(...)`` and may use its own tiler/layout in
2CTA kernels. The pipeline byte count also includes the SFA/SFB traffic:

.. code-block:: python

   # TMA atoms for SFA/SFB (note internal_type=Int16 for packing)
   sfa_op = sm100_utils.cluster_shape_to_tma_atom_A(cluster_shape_mn, tiled_mma.thr_id)
   tma_sfa = cute.nvgpu.make_tiled_tma_atom_A(
       sfa_op, sfa_tensor, sfa_smem_layout_staged,
       mma_tiler_mnk, tiled_mma, cluster_layout_vmnk.shape,
       internal_type=cutlass.Int16,
   )

   sfb_op = sm100_utils.cluster_shape_to_tma_atom_SFB(cluster_shape_mn, tiled_mma.thr_id)
   tma_sfb = cute.nvgpu.make_tiled_tma_atom_B(
       sfb_op, sfb_tensor, sfb_smem_layout_staged,
       mma_tiler_sfb, tiled_mma_sfb, cluster_layout_sfb_vmnk.shape,
       internal_type=cutlass.Int16,
   )

   # Kernel side: allocate staged SMEM for scale factors
   sSFA = smem.allocate_tensor(element_type=sf_dtype, layout=tma_sfa.smem_layout, ...)
   sSFB = smem.allocate_tensor(element_type=sf_dtype, layout=tma_sfb.smem_layout, ...)

**4. Scale-factor TMEM allocation and SMEM→TMEM copy (S2T)** — before each
``gemm``, SFA/SFB must be copied from staged SMEM into TMEM. The examples
compact away zero-stride modes and wrap the SMEM source in an S2T descriptor
tensor:

.. code-block:: python

   # TMEM allocation for scale factors
   tCtSFA_layout = blockscaled_utils.make_tmem_layout_sfa(
       tiled_mma, mma_tiler_mnk, sf_vec_size,
       cute.slice_(tma_sfa.smem_layout, (None, None, None, 0)),
   )
   tCtSFA = tmem_pool.allocate_tensor(tCtSFA_layout, sf_dtype)
   tCtSFB_layout = blockscaled_utils.make_tmem_layout_sfb(
       tiled_mma, mma_tiler_mnk, sf_vec_size,
       cute.slice_(tma_sfb.smem_layout, (None, None, None, 0)),
   )
   tCtSFB = tmem_pool.allocate_tensor(tCtSFB_layout, sf_dtype)

   # S2T copy setup (SMEM → TMEM for scale factors)
   copy_atom_s2t = cute.make_copy_atom(
       tcgen05.Cp4x32x128bOp(cta_group), sf_dtype,
   )

   # SFA shown; SFB follows the same pattern.
   tCtSFA_compact = cute.filter_zeros(tCtSFA)
   tiled_copy_s2t_sfa = tcgen05.make_s2t_copy(copy_atom_s2t, tCtSFA_compact)
   thr_copy_s2t_sfa = tiled_copy_s2t_sfa.get_slice(0)
   tCsSFA_compact_s2t = tcgen05.get_s2t_smem_desc_tensor(
       tiled_copy_s2t_sfa,
       thr_copy_s2t_sfa.partition_S(cute.filter_zeros(sSFA)),
   )
   tCtSFA_compact_s2t = thr_copy_s2t_sfa.partition_D(tCtSFA_compact)
   # Repeat with tCtSFB / sSFB to produce:
   # tiled_copy_s2t_sfb, tCsSFB_compact_s2t, and tCtSFB_compact_s2t.

**5. Modified main loop** — per K-tile, load A/B/SFA/SFB into SMEM, copy
SFA/SFB to TMEM, then call ``gemm`` with ``[value, scale]`` operands. The
persistent kernel separates TMA and MMA warps; the tutorial-style loop below
keeps only the operand flow:

.. code-block:: python

   for k_tile in cutlass.range(num_k_tiles):
       # TMA load A, B, SFA, SFB into SMEM
       cute.copy(tma_a.atom,   tAgA[None, ab_empty.count],   tAsA[None, ab_empty.index],   ...)
       cute.copy(tma_b.atom,   tBgB[None, ab_empty.count],   tBsB[None, ab_empty.index],   ...)
       cute.copy(tma_sfa.atom, tAgSFA[None, ab_empty.count], tAsSFA[None, ab_empty.index], ...)
       cute.copy(tma_sfb.atom, tBgSFB[None, ab_empty.count], tBsSFB[None, ab_empty.index], ...)

       ab_full = ab_consumer.wait_and_advance()

       # S2T: copy scale factors from SMEM to TMEM
       s2t_stage_coord = (None, None, None, None, ab_full.index)
       cute.copy(
           tiled_copy_s2t_sfa,
           tCsSFA_compact_s2t[s2t_stage_coord],
           tCtSFA_compact_s2t,
       )
       cute.copy(
           tiled_copy_s2t_sfb,
           tCsSFB_compact_s2t[s2t_stage_coord],
           tCtSFB_compact_s2t,
       )

       # MMA with scale factors passed as [value, scale] pairs
       tiled_mma.set(tcgen05.Field.ACCUMULATE, k_tile != 0)
       tile_crd = (None, None, None, ab_full.index)
       cute.gemm(
           tiled_mma,
           tCtAcc,
           [tCrA[tile_crd], tCtSFA],    # A value (SMEM) + A scale (TMEM)
           [tCrB[tile_crd], tCtSFB],    # B value (SMEM) + B scale (TMEM)
           tCtAcc,
       )

       ab_full.release()

.. code-block:: text

   Dense tcgen05 mainloop (schematic):
     gemm(tiled_mma, tCtAcc, tCrA[s], tCrB[s], tCtAcc)

   Block-scaled tcgen05 mainloop (schematic):
     copy(s2t_sfa, sSFA[stage], tCtSFA)           ← scale A to TMEM
     copy(s2t_sfb, sSFB[stage], tCtSFB)           ← scale B to TMEM
     gemm(tiled_mma, tCtAcc, [tCrA[s], tCtSFA], [tCrB[s], tCtSFB], tCtAcc)

The epilogue (TMEM → RMEM → GMEM) is identical to a dense kernel.

See also:

- Tutorial: step-by-step dense F16 GEMM — ``examples/cute/blackwell/tutorial/tutorial_gemm/fp16_gemm_0.py``
  (and ``fp16_gemm_1.py`` through ``fp16_gemm_6.py`` for progressive optimizations)
- Tutorial: block-scaled NVFP4 GEMM — ``examples/cute/blackwell/tutorial/tutorial_gemm/nvfp4_gemm_0.py``
- Dense GEMM (production): ``examples/cute/blackwell/kernel/dense_gemm/dense_gemm.py``
- Persistent dense GEMM: ``examples/cute/blackwell/kernel/dense_gemm/dense_gemm_persistent.py``
- Block-scaled GEMM: ``examples/cute/blackwell/kernel/blockscaled_gemm/dense_blockscaled_gemm_persistent.py``
- Sparse GEMM: ``examples/cute/blackwell/kernel/sparse_gemm/sparse_gemm_persistent.py``
- Helper utilities: ``cutlass.utils.blackwell_helpers``
- Block-scaled layout utilities: ``cutlass.utils.blockscaled_layout``
