.. _wmma_programming:

Warp-Level MMA Instructions Programming Guide
=============================================

Ampere (SM80) introduced the modern **warp-level MMA** PTX instruction
family ``mma.sync.aligned``. A warp (32 threads) cooperates on one
synchronous ``D = A * B + C`` matrix multiply-accumulate; later
architectures extended the family with new data types and shapes — FP8 on
Ada (SM89) and block-scaled MX FP4 on Blackwell (SM120a) — while keeping
the same warp-synchronous issue model.

Key architectural characteristics:

* **Warp scope:** One MMA is issued collectively by a 32-thread warp
  rather than by a warpgroup or a single thread.
* **Synchronous issue model:** ``mma.sync.aligned`` completes in program
  order within the warp; no fences or commit/wait groups are required.
* **Register-resident operands and accumulator:** A, B, and C/D all live
  in the register file (RMEM). Each thread holds a small fragment of every
  operand in its own registers.
* **SMEM → RMEM loading:** Operands A and B are staged in shared memory
  and loaded into register fragments via ``ldmatrix`` — a warp-collective
  SMEM→RMEM load that distributes tiles in the exact layout the MMA
  expects — or via regular shared-memory loads.
* **Fixed operand layout:** A is row-major (K-major) and B is col-major
  (K-major); transpose is not supported at the instruction level.

The dense DSL op classes currently exposed are ``MmaF16BF16Op`` (F16/BF16,
SM80+), ``MmaFP8Op`` (FP8 E4M3/E5M2, SM89+), and ``MmaMXF4Op`` /
``MmaMXF4NVF4Op`` (block-scaled MX FP4, SM120a+); see `Setting up the
TiledMMA, MMA Ops`_ for their full constructor parameters, instruction
shapes, and architecture requirements.

.. {$nv-internal-release begin}

Internal builds additionally expose ``MmaF16BF16SparseOp`` (2:4 structured
sparsity, SM80+).

.. {$nv-internal-release end}

This guide outlines the CuTe Python DSL programming model for warp-level
MMA kernels: stage operands in SMEM, load register fragments with
``ldmatrix`` or regular shared-memory loads, launch warp-synchronous MMAs, and stage the RMEM accumulator
back to GMEM in the epilogue.


.. contents:: **Contents**
   :local:
   :depth: 2

Global Memory (GMEM) to MMA data flow overview
----------------------------------------------

Warp MMA (``mma.sync.aligned``) instructions require all operands --A, B, and
the accumulator C/D-- to live in registers (RMEM) of the 32 threads of the warp.
Operand data must therefore be explicitly loaded into registers before each MMA
instruction. The most common way to implement these GEMMs is to stage A and B
from GMEM into SMEM with ``cp.async``, then use ``ldmatrix`` (an SMEM→RMEM
warp-collective load) to fill the A/B register fragments just before ``cute.gemm()``.

The diagram below traces the full data flow of a warp MMA GEMM kernel, for the most
common case where A and B matrices are stored in GMEM and staged through SMEM
via ``cp.async``, and the output matrix --accumulated in RMEM-- is written back
to GMEM through an SMEM staging buffer for coalesced vectorized stores.

There are 3 parallel tracks where each has 2 sub-tracks. Three parallel tracks are
for operands A, B, and C/D, respectively. The two sub-tracks are for copying data between different memory
spaces and for MMA execution.

- **Operand A** (and symmetrically **Operand B**):

  - First, we need to create SMEM tensors for A and B matrices: ``sA`` and ``sB``.
    These tensors are physically allocated tensors that are the staging destination
    of ``cp.async`` and the source of ``ldmatrix`` for the warp MMA instructions.
  - Next the **data copy flow** creates the tensor views for copying data from GMEM to SMEM.
    It starts with ``mA`` tensor that represents the matrix A in global memory.
    Then ``mA`` → ``local_tile`` → ``gA`` operation creates the local tile view of A that is
    the slice of A matrix needed to compute the given CTA's output tile.
    A copy partition maps this tile to per-thread copy views (``tAgA``, ``tAsA``),
    and the multi-stage ``cp.async`` pipeline performs
    ``copy(tiled_copy_A, tAgA[k], tAsA[stage])``.
  - In parallel, the **MMA flow** turns the staged SMEM tensor into register fragments
    consumed by the warp MMA. From the SMEM allocation ``sA``, MMA partitioning
    produces the SMEM operand view ``tCsA = partition_A(sA)`` and the register-fragment
    layout ``tCrA = make_fragment_A(tCsA)``. A dedicated S2R/``ldmatrix`` path then
    retiles the source and destination (``partition_S`` on SMEM, ``retile`` on RMEM)
    and executes ``copy(s2r_A, tCsA_copy_view[k_blk], tCrA_copy_view[k_blk])``
    per k-block, filling the ``tCrA`` registers read by ``cute.gemm()``.

- **Accumulator C/D**:

  - **RMEM accumulator flow** (MMA input/output): output tile views are formed by
    ``mC`` → ``local_tile`` → ``gC`` → ``partition_C`` → ``tCgC``, then
    ``make_fragment_C(tCgC)`` creates the register accumulator ``tCrC``.
    Warp MMA keeps C/D entirely in RMEM, and ``tCrC`` is both the input C
    and output D of ``cute.gemm()``.
  - **Epilogue flow** (RMEM → SMEM → RMEM → GMEM): the epilogue converts accumulator
    values (for example ``tCrD = epilogue_op(tCrC)``), stages them through SMEM
    (``autovec_copy(tCrD, tCsC)``), reloads them into registers with the epilogue
    copy layout, and performs coalesced vectorized GMEM stores via
    ``copy(tiled_copy_C, tCrC_epi, tCgC_epi)``.

.. code-block:: text

   Operand A Dataflow Path                 Operand B Dataflow Path                 Accumulator C/D Dataflow Path
   ───────────────────────                 ───────────────────────                 ─────────────────────────────

  mA: (M, K)           [GMEM]             mB: (N, K)            [GMEM]             ┌──── RMEM ──────────┐
   │                                       │                                       │ make_fragment_C()  │
   │ local_tile(mA, cta_tiler, coord)      │ local_tile(mB, cta_tiler, coord)      │ tCrC: accumulator  │
   ▼                                       ▼                                       └───────┬────────────┘
  gA: (BM, BK, k)      [GMEM]             gB: (BN, BK, k)       [GMEM]                     │
   │                                       │                                       tCrC:(MMA,MMA_M,MMA_N) [RMEM]
   │  ┌──── SMEM ─────────┐                │  ┌──── SMEM ─────────┐                         │
   │  │ sA: (BM,BK,PIPE)  │                │  │ sB: (BN,BK,PIPE)  │                         │        mC: (M, N)     [GMEM]
   │  └──┬────────┬───────┘                │  └──┬────────┬───────┘                         │        │
   │     │        │                        │     │        │                                 │        │ local_tile
   │     │  thr_mma.partition_A(sA)        │     │  thr_mma.partition_B(sB)                 │        ▼
   │     │        ▼                        │     │        ▼                                 │        gC: (BM, BN)   [GMEM]
   │     │  tCsA:(MMA,MMA_M,               │     │  tCsB:(MMA,MMA_N,                        │        │ partition_C
   │     │        MMA_K,PIPE) [SMEM]       │     │        MMA_K,PIPE) [SMEM]                │        ▼
   │     │        │                        │     │        │                                 │        tCgC:(MMA,MMA_M,
   │     │  make_fragment_A(tCsA)          │     │  make_fragment_B(tCsB)                   │              MMA_N)
   │     │        ▼                        │     │        ▼                                 │        [GMEM] (epi dest)
   │     │  tCrA:(MMA,MMA_M,               │     │  tCrB:(MMA,MMA_N,                        │        │
   │     │        MMA_K) [RMEM]            │     │        MMA_K) [RMEM]                     │        │
   │     │        │                        │     │        │                                 │        │
   │     │  S2R retiling (ldmatrix):       │     │  S2R retiling (ldmatrix):                │        │
   │     │   s2r_A = make_tiled_copy_A(    │     │   s2r_B = make_tiled_copy_B(             │        │
   │     │             ldmatrix, mma)      │     │             ldmatrix, mma)               │        │
   │     │   tCsA_copy_view =              │     │   tCsB_copy_view =                       │        │
   │     │     s2r_A.partition_S(sA)       │     │     s2r_B.partition_S(sB)                │        │
   │     │   tCrA_copy_view = retile(tCrA) │     │   tCrB_copy_view = retile(tCrB)          │        │
   │     │        └─────────────┐          │     │        └─────────────┐                   │        │
   ╰─────┤                      │          ╰─────┤                      │                   │        │
         ▼                      │                ▼                      │                   │        │
   tAgA = thr_copy_A.           │              tBgB = thr_copy_B.       │                   │        │
            partition_S(gA)     │                       partition_S(gB) │                   │        │
   tAsA = thr_copy_A.           │              tBsB = thr_copy_B.       │                   │        │
            partition_D(sA)     │                       partition_D(sB) │                   │        │
         |                      │                    |                  │                   │        │
         ▼                      │                    ▼                  │                   │        │
     ┌───┴────────────────────┐ │             ┌──────┴─────────────────┐│                   │        │
     │ cp.async loop (k-tile):│ │             │ cp.async loop (k-tile):││                   │        │
     │ copy(tiled_copy_A,     │ │             │ copy(tiled_copy_B,     ││                   │        │
     │      tAgA[k],          │ │             │      tBgB[k],          ││                   │        │
  ┌─▶│      tAsA[stage])      │ │         ┌──▶│      tBsB[stage])      ││                   │        │
  │  │ (writes into sA;       │ │         │   │ (writes into sB;       ││                   │        │
  │  │  ldmatrix reads sA)    │ │         │   │  ldmatrix reads sB)    ││                   │        │
  │  │ repeat for next k/stage│ │         │   │ repeat for next k/stage││                   │        │
  │  └────────────────────────┘ │         │   └────────────────────────┘│                   │        │
  │        │                    │         │         │                   │                   │        │
  └────────┘                    ▼         └─────────┘                   ▼                   ▼        │
                                └───────┬───────────────────────────────┴───────────────────┘        │
                                        │                                                            │
                                        ▼                                                            │
                          ┌────────────────────────────────────────────────────────┐                 │
                          │ MMA loop (k_blk):                                      │                 │
                          │ S2R: copy(s2r_A, tCsA_copy_view[k_blk],                │                 │
                          │                  tCrA_copy_view[k_blk])                │                 │
                          │ S2R: copy(s2r_B, tCsB_copy_view[k_blk],                │                 │
                          │                  tCrB_copy_view[k_blk])                │                 │
                          │      [SMEM → RMEM via ldmatrix; fills tCrA/tCrB]       │                 │
                          │                                                        │                 │
                          │ cute.gemm(tiled_mma,                                   │                 │
                     ┌──▶ │  tCrC,         D (output, RMEM),                       │                 │
                     │    │  tCrA[k_blk],  A (RMEM),                               │                 │
                     │    │  tCrB[k_blk],  B (RMEM),                               │                 │
                     │    │  tCrC)         C (accumulator, RMEM)                   │                 │
                     │    └────────────────────────────────────────────────────────┘                 │
                     │       │     │                                                                 │
                     └───────┘     |                                                                 │
                                   ▼                                                                 │
                             Epilogue:                                                               │
                             tCrD = epilogue_op(tCrC)       [RMEM]                                   │
                                   │                                                                 │
                                   ▼                                                                 │
                             sC = alloc(sC_layout) [SMEM]                                            │
                             tCsC = thr_mma.partition_C(sC)                                          │
                             R2S: autovec_copy(tCrD, tCsC)                                           │
                             [RMEM → SMEM]                                                           │
                                   │                                                                 │
                                   ▼                                                                 │
                             tCsC_epi = thr_copy_C.partition_S(sC)                                   │
                             tCgC_epi = thr_copy_C.partition_D(gC) ◀─────────────────────────────────┘
                             tCrC_epi = make_fragment_like(...)
                             S2R: autovec_copy(tCsC_epi, tCrC_epi)
                             [SMEM → RMEM]
                                   │
                                   ▼
                             Store: copy(tiled_copy_C, tCrC_epi, tCgC_epi)
                             [RMEM → GMEM]

**Naming convention:**

* ``mma_tiler`` = ``(BM, BN, BK)`` (CTA tiler dimensions)
* ``mX`` = global tensor (for example A as ``(M, K)``)
* ``gX`` = CTA-tiled GMEM slice (for example ``(BM, BK, k)`` for A)
* ``sX`` = SMEM allocation (for example ``(BM, BK, PIPE)``)
* ``tAgA`` / ``tAsA`` = ``cp.async`` source/destination partitions
  (``CPY, CPY_M, CPY_K, ...``)
* ``tCsX`` = MMA-partitioned SMEM view (for example ``(MMA, MMA_M, MMA_K, PIPE)``)
* ``tCrX`` = register fragment (for example ``(MMA, MMA_M, MMA_K)``)
* ``tCrC`` = RMEM accumulator (``MMA, MMA_M, MMA_N``)
* ``tCgC`` = MMA-partitioned GMEM view for output (``MMA, MMA_M, MMA_N``)
* ``tCsA_copy_view`` / ``tCrA_copy_view`` = ``ldmatrix`` retile views for SMEM→RMEM
  copy (from ``partition_S(sA)`` and ``retile(tCrA)`` on the S2R tiled copy;
  C++ equivalents: ``tXsA`` / ``tXrA``)
* ``MMA`` = atom thread-value layout; ``MMA_M/MMA_N/MMA_K`` = repeat counts
  (for example ``BM/inst_M``), ``k`` = outer K-tiles, ``PIPE`` = pipeline stages


Setting up the TiledMMA, MMA Ops
---------------------------------

As shown in the data flow overview, CuTe DSL provides many utilities to tile/partition
the global memory tensors, and create fragment views of SMEM and register tensors for MMA instructions.

To utilize these functions, we need to setup the TiledMMA, MMA Ops first.

Creating a Warp MMA Op
~~~~~~~~~~~~~~~~~~~~~~~

A warp MMA op describes the hardware ``mma.sync.aligned`` instruction to use,
it has parameters like data types and instruction shape. The operand layout is
fixed (A = row-major, B = col-major).

.. code-block:: python

   import cutlass
   import cutlass.cute as cute
   from cutlass.cute.nvgpu import warp

   op = warp.MmaF16BF16Op(
       cutlass.Float16,     # A/B element type
       cutlass.Float32,     # accumulator type
       (16, 8, 16),         # instruction shape (M, N, K)
   )

The key parameters are:

- **Instruction shape** ``(M, N, K)``: determines the size of one hardware MMA
  instruction. Valid shapes depend on the data type (see ops table below).
- **A/B element type** (``ab_dtype``) and **accumulator type** (``acc_dtype``):
  ``Float32`` is always a valid accumulator; ``Float16`` is only valid for F16
  inputs. Each op restricts ``ab_dtype`` to a specific family (F16/BF16, FP8,
  MXF4, etc.).
- **Operand layout**: fixed to A = row-major (K-major), B = col-major (K-major).
  Transpose is not supported. All 32 threads in a warp cooperate on each
  instruction.


CuTe DSL provides implementation of many warp-level MMA ops:

.. list-table:: warp-level MMA ops
   :header-rows: 1
   :widths: 34 22 34 10

   * - PTX name
     - Python class
     - Constructor parameters
     - SM Arch
   * - ``mma.sync.aligned.m16n8k{K}.row.col.{acc}.f16.f16`` / ``.bf16.bf16``
     - ``warp.MmaF16BF16Op``
     - ``ab_dtype, acc_dtype, shape_mnk``
     - ``sm_80+``
   * - ``mma.sync.aligned.m16n8k{K}.row.col.{acc}.{e4m3|e5m2}.{e4m3|e5m2}``
     - ``warp.MmaFP8Op``
     - ``ab_dtype, acc_dtype, shape_mnk``
     - ``sm_89+``
   * - ``mma.sync.aligned.kind::mxf4.block_scale.m16n8k64``
     - ``warp.MmaMXF4Op``
     - ``ab_dtype, acc_dtype, sf_type``
     - ``sm_120a+``
   * - ``mma.sync.aligned.kind::mxf4nvf4.block_scale.m16n8k64``
     - ``warp.MmaMXF4NVF4Op``
     - ``ab_dtype, acc_dtype, sf_type``
     - ``sm_120a+``

.. {$nv-internal-release begin}

Internal builds additionally provide:

.. list-table:: Internal warp-level MMA ops
   :header-rows: 1
   :widths: 34 22 34 10

   * - PTX name
     - Python class
     - Constructor parameters
     - SM Arch
   * - ``mma.sp.sync.aligned.m16n8k{K}.row.col.{acc}.f16.f16`` / ``.bf16.bf16``
     - ``warp.MmaF16BF16SparseOp``
     - ``ab_dtype, acc_dtype, shape_mnk, sparse_metadata_format``
     - ``sm_80+``

.. {$nv-internal-release end}

Creating a Tiled MMA
~~~~~~~~~~~~~~~~~~~~~

A ``TiledMma`` tiles the MMA atom across the thread block so that multiple
warps cooperate on a larger tile. You can pass the op directly or create an
explicit atom first:

.. code-block:: python

  # Option 1: directly from op (common shorthand)
  tiled_mma = cute.make_tiled_mma(op)

  # Option 2: explicit atom creation
  atom = cute.make_mma_atom(op)
  tiled_mma = cute.make_tiled_mma(atom)

With no extra arguments this wraps a single atom — one warp, one
``(16, 8, K)`` tile. The optional ``atom_layout_mnk`` and
``permutation_mnk`` parameters (described in the subsections below)
control multi-warp tiling and per-thread value layout respectively.

Spatial tiling with a repeat count
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

A repeat tuple ``(M_rep, N_rep, K_rep)`` passed as ``atom_layout_mnk``
replicates the warp MMA atom across the M, N, and K dimensions, producing a
larger tiled MMA that is executed cooperatively by ``M_rep * N_rep * K_rep``
warps in a single ``cute.gemm`` call. Each entry in the repeat tuple
corresponds to one **warp** (32 threads), so ``(2, 2, 1)`` uses four warps —
a common configuration for warp-specialized SM80/SM89 kernels:

.. code-block:: python

   atom = cute.make_mma_atom(op)     # op shape: (16, 8, 16)
   tiled_mma = cute.make_tiled_mma(
       atom,
       atom_layout_mnk=(2, 2, 1),    # 4 warps: 2 in M, 2 in N
   )                                 # total tiled-MMA tile = (32, 16, 16)

The coordinates of atoms could be thought as a 3D coordinate: ``(m, n, k)``.
``m`` is the M repeat index, ``n`` is the N repeat index, and ``k`` is the K
repeat index. Each warp MMA atom is executed by a single warp within a
single CTA.


.. code-block:: text

    Warp MMA Atom (16x8x16)                make_tiled_mma(atom, (2, 2, 1))
    +----------------+                     +----------------+----------------+
    |                |                     |                |                | ^
    |   16 x 8       |                     | Atom (0,0,0)   | Atom (0,1,0)   | |
    |     x 16       |   --(2,2,1)-->      |   16 x 8       |   16 x 8       | | 2 x inst_M
    |                |      repeat         |     x 16       |     x 16       | |  = 32
    |                |                     | [Warp 0]       | [Warp 2]       | |
    +----------------+                     +----------------+----------------+ |
                                          |                |                | |
                                          | Atom (1,0,0)   | Atom (1,1,0)   | |
                                          |   16 x 8       |   16 x 8       | |
                                          |     x 16       |     x 16       | |
                                          | [Warp 1]       | [Warp 3]       | v
                                          +----------------+----------------+
                                          <--- 2 x inst_N = 16 --->
                                          K unchanged = 16


Custom tile permutation with ``permutation_mnk``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

``permutation_mnk`` is an optional third argument to ``make_tiled_mma``.
Each of its three entries is a **per-mode permutation** of the M, N, and
K coordinates inside the tiled MMA. In the common case shown in this
section, each entry is just a size, which is the identity permutation of
that size; in that case ``permutation_mnk`` simply sets the **total tile
footprint** of the tiled MMA along each dimension. When a mode's size is
larger than the atom layout's natural coverage
(``atom_layout x inst_shape``), each thread receives additional values to
fill the extended region — the thread count stays the same, but every
thread holds more data. The general form, where an entry is a
``Layout`` that reorders coordinates inside a mode, is covered in the
subsection below.

The standard convention for warp MMA (used in ``tensorop_gemm.py`` and
throughout the Ampere examples) doubles the N dimension:

.. code-block:: python

   # From examples/cute/ampere/kernel/dense_gemm/tensorop_gemm.py
   permutation_mnk = (
       atom_layout_mnk[0] * mma_inst_shape[0],      # M: matches atom coverage
       atom_layout_mnk[1] * mma_inst_shape[1] * 2,   # N: 2x atom coverage
       atom_layout_mnk[2] * mma_inst_shape[2],        # K: matches atom coverage
   )

   tC = cute.make_layout(atom_layout_mnk)
   tiled_mma = cute.make_tiled_mma(
       op,
       tC,
       permutation_mnk=permutation_mnk,
   )

**Why double N?** The atom's N dimension is only 8 (inst_N = 8). Without
a permutation, each thread's B-operand values span a single 8-wide
N-range, which may not align well with SMEM load widths. The ``* 2``
on N gives each thread's B fragment two 8-wide N-ranges instead of one,
aligning the access pattern with wider contiguous SMEM regions for more
efficient loads.

For ``atom_layout_mnk = (2, 2, 1)`` and ``inst_shape = (16, 8, 16)``:

- Atom coverage = ``(2x16, 2x8, 1x16) = (32, 16, 16)``
- ``permutation_mnk = (32, 32, 16)`` — N extended from 16 to 32

.. code-block:: text

  Without permutation — natural atom coverage (M = 32, N = 16):

  C tile (M=32, N=16)
  +----------------+----------------+
  |                |                | ^
  |   [Warp 0]     |   [Warp 2]     | |
  |    16 x 8      |    16 x 8      | | 2 x inst_M
  |                |                | |  = 32
  +----------------+----------------+ |
  |                |                | |
  |   [Warp 1]     |   [Warp 3]     | |
  |    16 x 8      |    16 x 8      | |
  |                |                | v
  +----------------+----------------+
  <------------- N = 16 ---------->
  (each warp owns one (16, 8) atom;
   thread T0 of Warp 0 holds 4 C values in its 16x8 block)

  With permutation_mnk = (32, 32, 16) — N extended from 16 to 32:

  C tile (M=32, N=32)
  +----------------+----------------+----------------+----------------+
  |                |                |                |                | ^   N = 16 → 32:
  |   [Warp 0]     |   [Warp 2]     |   [Warp 0]     |   [Warp 2]     | |   atom pattern repeats
  |    16 x 8      |    16 x 8      |    16 x 8      |    16 x 8      | |   along N. Each thread
  |                |                |                |                | |   now holds 2x the
  +----------------+----------------+----------------+----------------+ |   values along N
  |                |                |                |                | |   (same threads, more
  |   [Warp 1]     |   [Warp 3]     |   [Warp 1]     |   [Warp 3]     | |   values per thread).
  |    16 x 8      |    16 x 8      |    16 x 8      |    16 x 8      | |
  |                |                |                |                | v
  +----------------+----------------+----------------+----------------+
  <---------------------------- N = 32 ---------------------------->
  |        atom coverage            |          value repeat           |


Reordering coordinates with a per-mode ``Layout``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

So far each entry of ``permutation_mnk`` has been an integer, which is
shorthand for the identity layout ``Layout<Shape<S>, Stride<_1>>`` — the
atom pattern simply tiles to fill an ``S``-wide footprint. The general
form lets each entry be a ``Layout`` that **reorders coordinates inside
that mode** while keeping the same total size. That reordering is what
gives the parameter its name; the integer-only cases used earlier are
just the identity permutation.

The canonical illustration is the SM70 example from
`0t_mma_atom.md <../../cpp/cute/0t_mma_atom.md>`_. Take a 2x2 tiled MMA
of ``SM70_8x8x4_F32F16F16F32_NT`` atoms with a ``32x32x4`` footprint.
Without any M-mode permutation, thread ``T0``'s 8 A-values land at the
following ``(m, k)`` coordinates::

    T0V0 => (0, 0)     T0V4 => (16, 0)
    T0V1 => (1, 0)     T0V5 => (17, 0)
    T0V2 => (2, 0)     T0V6 => (18, 0)
    T0V3 => (3, 0)     T0V7 => (19, 0)

— two separate runs of 4 along M, with a gap from m=4 to m=15. We may
prefer those 8 values to sit in **one contiguous run** in the logical
M-coordinates (e.g. so register or SMEM layouts pack cleanly). Passing
the M-mode layout ``(4, 4, 2):(1, 8, 4)`` does exactly that: it is a
scatter permutation telling each old m-coord where to go in the new
image.

.. code-block:: text

    old m-coord:  0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31
    new m-coord:  0  1  2  3  8  9 10 11 16 17 18 19 24 25 26 27  4  5  6  7 12 13 14 15 20 21 22 23 28 29 30 31

After the permutation, ``T0``'s 8 A-values occupy ``m = 0..7`` — one
contiguous run — and every other thread's M-values become equally
contiguous. Thread-data ownership and value counts are unchanged; only
the **mapping from values to m-coordinates** is permuted.

In CuTeDSL the permuted entry is built with ``cute.make_layout``;
identity entries stay as integers:

.. code-block:: python

   m_perm = cute.make_layout((4, 4, 2), stride=(1, 8, 4))
   tiled_mma = cute.make_tiled_mma(
       op,                                # SM70_8x8x4 NT atom
       atom_layout_mnk=(2, 2, 1),
       permutation_mnk=(m_perm, 32, 4),   # M: scatter, N/K: identity sizes
   )

The same mechanism applies to the N and K modes — any subset of the
three entries can be an integer (identity) or a ``Layout`` (real
permutation). For warp MMAs the most common case in practice is still
the integer-only form shown earlier in this section; the ``Layout`` form
is the tool you reach for when a register or SMEM layout wants each
thread's fragment to be contiguous in logical coordinates.


Partitioning Tensors
---------------------

Before computing, partition the CTA-tiled tensors according to the
tiled MMA layout. Warp MMA partitioning is **per-thread**: each of
the 32 threads in a warp (or 128 threads across 4 warps) receives
its own slice of the data, sized to match the register fragments
the MMA instruction expects.

Example: ``GEMM (M, N, K) = (512, 512, 256)``,
``cta_tiler = (128, 128, 32)``, ``atom_layout_mnk = (2, 2, 1)``,
F16 atom = m16n8k16, ``permutation_mnk = (32, 32, 16)``,
``num_stages = 4``, 4 warps = 128 threads.

Global matrices:

.. code-block:: text

     mA: (M, K) = (512, 256)       mB: (N, K) = (512, 256)       mC: (M, N) = (512, 512)

          K=256                          K=256                       N=512
        |<--------->|                |<--------->|              |<---------------->|
        +-----------+                +-----------+              +----+----+----+---+
        |           | ^              |           | ^            |    |    |    |   | ^
        |    mA     | | M=512        |    mB     | | N=512      |    |    |    |   | | M=512
        |           | v              |           | v            |    |    |    |   | v
        +-----------+                +-----------+              +----+----+----+---+

Tiling with ``cta_tiler = (BM, BN, BK) = (128, 128, 32)`` gives
M/BM = 4 tiles, N/BN = 4 tiles, K/BK = 8 tiles:

.. code-block:: text

    mA tiled into (M/BM x K/BK)    mB tiled into (N/BN x K/BK)    mC tiled into (M/BM x N/BN)
    = (4 x 8) blocks               = (4 x 8) blocks               = (4 x 4) blocks

      BK=32  x8                       BK=32  x8                       BN=128  x4
    |<-->|                          |<-->|                          |<------>|
    +----+----+-- --+               +----+----+-- --+               +--------+--------+-- --+
    |    |    |..|  | ^  BM=128     |    |    |..|  | ^  BN=128     | (0,0)  | (0,1)  |..   | ^  BM=128
    +----+----+-- --+ v             +----+----+-- --+ v             +--------+--------+     + v
    |    |    |..|  | ^  BM=128     |    |    |..|  | ^  BN=128     | (1,0)  | (1,1)  |..   | ^  BM=128
    +----+----+-- --+ v             +----+----+-- --+ v             +--------+--------+     + v
    |    |    |..|  | ^             |    |    |..|  | ^             |  ...   |  ...   |..   | ^
    +----+----+-- --+ v             +----+----+-- --+ v             +--------+--------+-- --+ v
    |    |    |..|  | ^             |    |    |..|  | ^             | (3,0)  | (3,1)  |..   | ^
    +----+----+-- --+ v             +----+----+-- --+ v             +--------+--------+-- --+ v

Each CTA picks one (M-tile, N-tile) coordinate.
For example, CTA at ``tiler_coord = (0, 1, :)``.

After ``local_tile`` — one CTA's tile (``k = K/BK = 256/32 = 8``):

.. code-block:: text

     gA: (BM, BK, k) = (128, 32, 8)   gB: (BN, BK, k) = (128, 32, 8)   gC: (BM, BN) = (128, 128)

          BK=32                             BK=32                       BN=128
        |<----->|                        |<----->|                  |<-------->|
        +-------+--                      +-------+--                +----------+
        |       |..                      |       |..                |          | ^
   BM=  |  gA   | k=8                BN= |  gB   | k=8          BM= |    gC    | | 128
    128 |       |                    128 |       |              128 |          | v
        +-------+                        +-------+                  +----------+

SMEM tensors ``sA`` and ``sB`` have a pipeline staging dimension:

.. code-block:: text

     sA: (BM, BK, PIPE) = (128, 32, 4)         sB: (BN, BK, PIPE) = (128, 32, 4)

``get_slice(tidx)`` — each thread receives its own per-thread partition.
The tiled MMA footprint is ``permutation_mnk = (32, 32, 16)``, so BM,
BN, and BK are each subdivided into MMA-sized blocks:

.. code-block:: text

        sA: partition into (MMA, MMA_M, MMA_K, PIPE)

        Each SMEM stage (BM=128, BK=32):

        perm_K perm_K                               perm_M=32
          =16    =16                                |<---->|
        |<--->|<--->|                               +------+------+------+------+
        +-----+-----+  ^                            |      |      |      |      | ^
        |  0  |  1  |  |  perm_M=32                 |  0   |  1   |  2   |  3   | | perm_N
        +-----+-----+  v                            |      |      |      |      | v  =32
        |  0  |  1  |  ^                            +------+------+------+------+
        |     |     |  |  perm_M=32                   MMA_N = BN/perm_N = 4
        +-----+-----+  v
        |  0  |  1  |  ^                           sB: partition into (MMA, MMA_N, MMA_K, PIPE)
        |     |     |  |
        +-----+-----+  v                           gC: partition into (MMA, MMA_M, MMA_N)
        |  0  |  1  |  ^
        |     |     |  |
        +-----+-----+  v
          MMA_K = BK/perm_K = 2
          MMA_M = BM/perm_M = 4

After partition (per thread, e.g. thread ``tidx``):

- ``tCsA: (MMA, MMA_M, MMA_K, PIPE) = (MMA, 4, 2, 4)`` — MMA_M = BM/perm_M = 128/32 = 4, MMA_K = BK/perm_K = 32/16 = 2
- ``tCsB: (MMA, MMA_N, MMA_K, PIPE) = (MMA, 4, 2, 4)`` — MMA_N = BN/perm_N = 128/32 = 4, MMA_K = BK/perm_K = 32/16 = 2
- ``tCgC: (MMA, MMA_M, MMA_N) = (MMA, 4, 4)`` — MMA_M = 128/32 = 4, MMA_N = 128/32 = 4

The first mode ``MMA`` contains the atom's **thread × value** layout — it
encodes which registers within a single thread hold which matrix
elements. The remaining modes are repeat counts that tile the atom
across the full CTA tile.

.. code-block:: python

   @cute.kernel
   def kernel(tiled_mma: cute.TiledMma, ...):
       tidx, _, _ = cute.arch.thread_idx()

       # CTA-tiled global tensors
       gA = cute.local_tile(mA, cta_tiler, tiler_coord, proj=(1, None, 1))
       gB = cute.local_tile(mB, cta_tiler, tiler_coord, proj=(None, 1, 1))
       gC = cute.local_tile(mC, cta_tiler, tiler_coord, proj=(1, 1, None))

       # Per-thread partition via the thread index
       thr_mma = tiled_mma.get_slice(tidx)

       # SMEM partitions (used by make_fragment_A/B and ldmatrix retiling)
       tCsA = thr_mma.partition_A(sA)   # (MMA, MMA_M, MMA_K, PIPE)
       tCsB = thr_mma.partition_B(sB)   # (MMA, MMA_N, MMA_K, PIPE)

       # C partitions for epilogue staging (SMEM) and destination (GMEM)
       tCsC = thr_mma.partition_C(sC)   # (MMA, MMA_M, MMA_N)
       tCgC = thr_mma.partition_C(gC)   # (MMA, MMA_M, MMA_N)

.. note:: The ``tCsA`` / ``tCsB`` SMEM partitions are not read directly
   by the GEMM — they establish the **shape** that
   ``make_fragment_A`` / ``make_fragment_B`` use to allocate register
   fragments. Actual SMEM→RMEM data movement goes through the S2R
   ``ldmatrix`` retiling path (see `Making Fragments`_).

Pre and Post-Conditions for Partitioning
-----------------------------------------

* The inputs of the partition should be at least rank-2 tensors.
* The output of the partition will have the layout that is compatible with the MMA atom's operand:

  - For A, the output will have the layout ``(MMA, MMA_M, MMA_K, ...)``.
  - For B, the output will have the layout ``(MMA, MMA_N, MMA_K, ...)``.
  - For C, the output will have the layout ``(MMA, MMA_M, MMA_N, ...)``.

* Note that the partition doesn't enforce any rules on the tensor's memory space or the tensor's data type. It only cares about the layout.


Making Fragments
-----------------

Fragments are the tensors that the warp MMA instruction operates on. For
warp MMA:

- **Fragment A**: per-thread register fragment holding one operand-A K-block.
- **Fragment B**: per-thread register fragment holding one operand-B K-block.
- **Fragment C (accumulator)**: per-thread register fragment that lives in
  RMEM and serves as both the input C and output D of ``cute.gemm()``.

Creating register fragments and ``ldmatrix`` copy views
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Warp MMA fragments are actual per-thread register tensors, not descriptors.
Fragment creation has three parts:

**1. A and B fragments**

``make_fragment_A`` and ``make_fragment_B`` take one stage of the
MMA-partitioned SMEM views (``tCsA`` / ``tCsB``) and allocate register
fragments with a matching thread-local layout. This establishes the shape
only; no data is loaded yet.

.. code-block:: python

   # Per-thread MMA partitions
   # (sA/sB are the staged SMEM tensors — see "Creating SMEM layouts for A and B")
   tCsA = thr_mma.partition_A(sA)   # (MMA, MMA_M, MMA_K, PIPE)
   tCsB = thr_mma.partition_B(sB)   # (MMA, MMA_N, MMA_K, PIPE)

   # Register fragments for one pipeline stage
   tCrA = tiled_mma.make_fragment_A(
       tCsA[None, None, None, 0]
   )  # (MMA, MMA_M, MMA_K)
   tCrB = tiled_mma.make_fragment_B(
       tCsB[None, None, None, 0]
   )  # (MMA, MMA_N, MMA_K)

Continuing the running example from `Partitioning Tensors`_ (F16
``m16n8k16``, ``cta_tiler = (128, 128, 32)``, ``permutation_mnk = (32, 32,
16)``, ``num_stages = 4``):

.. code-block:: text

   tCsA: (MMA, MMA_M=4, MMA_K=2, PIPE=4)
   tCsB: (MMA, MMA_N=4, MMA_K=2, PIPE=4)

   make_fragment_A(tCsA[..., stage]) -> tCrA: (MMA, 4, 2)
   make_fragment_B(tCsB[..., stage]) -> tCrB: (MMA, 4, 2)

Each element of ``tCrA`` / ``tCrB`` is a register value owned by the current
thread. Together, the 32 threads in the warp hold the full operand fragment
that one ``mma.sync.aligned`` instruction consumes.

**2. C fragment (accumulator)**

``make_fragment_C`` allocates the accumulator registers for the CTA tile
slice owned by the current thread. The accumulator usually starts at zero
before the K loop and is updated in-place by each ``cute.gemm()`` call.

.. code-block:: python

   tCgC = thr_mma.partition_C(gC)   # (MMA, MMA_M, MMA_N)
   tCrC = tiled_mma.make_fragment_C(tCgC)
   tCrC.fill(0.0)

For the same running example:

.. code-block:: text

   tCgC: (MMA, MMA_M=4, MMA_N=4)
   make_fragment_C(tCgC) -> tCrC: (MMA, 4, 4)

``tCrC`` stays in registers for the entire main loop and serves as both the
input C and output D argument of ``cute.gemm()``.

**3. SMEM → RMEM load (``ldmatrix`` retiling)**

The register fragments above are storage only — before ``cute.gemm()`` can
consume ``tCrA`` and ``tCrB``, each K-block must be loaded from shared
memory into those registers. This is done via a separate tiled copy built
from an ``ldmatrix`` copy atom and linked to the tiled MMA with
``make_tiled_copy_A`` / ``make_tiled_copy_B``. The copy's ``retile()``
call remaps the MMA fragment's register layout to match what the
``ldmatrix`` instruction writes.

.. code-block:: python

   # 1. Create ldmatrix copy atom → tiled copy tied to the MMA layout
   s2r_atom_A = cute.make_copy_atom(LdMatrix8x8x16bOp(...), dtype)
   s2r_tiled_A = cute.make_tiled_copy_A(s2r_atom_A, tiled_mma)

   # 2. Build SMEM-side and RMEM-side views for the copy
   thr_s2r_A = s2r_tiled_A.get_slice(tidx)
   tCsA_copy_view = thr_s2r_A.partition_S(sA)   # SMEM source
   tCrA_copy_view = thr_s2r_A.retile(tCrA)      # RMEM dest (retiled)

   # 3. Load one k-block from SMEM into the MMA fragment (in the main loop)
   cute.copy(s2r_tiled_A, tCsA_copy_view[None, None, k_block],
             tCrA_copy_view[None, None, k_block])

See ``tensorop_gemm.py`` for the complete implementation including the
``ldmatrix`` transpose flag, FP8 variants, and operand B.


Creating SMEM layouts for A and B
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The SMEM layouts define how A and B tiles are staged in shared memory before
the ``ldmatrix`` loads. For warp MMA, these layouts must satisfy two goals at
the same time:

- **Efficient GMEM -> SMEM copy:** ``cp.async`` should write contiguous
  16-byte regions for each thread.
- **Bank-conflict-free SMEM -> RMEM load:** the later ``ldmatrix`` loads
  should see a swizzled layout that matches the warp MMA operand access
  pattern.

The Ampere dense GEMM example
(``examples/cute/ampere/kernel/dense_gemm/tensorop_gemm.py``) builds these
layouts inline with a helper named ``_make_smem_layout_AB``.

**Host side** (``@cute.jit``):

.. code-block:: python

   # 16 bytes per thread for GMEM -> SMEM copies
   ab_copy_bits = 128

   sA_layout, sA_swizzle = self._make_smem_layout_AB(
       mA.element_type,       # dtype (e.g. Float16)
       self.a_major_mode,     # row-major or col-major
       ab_copy_bits,          # copy width in bits (128 = 16 bytes)
       (self.cta_tiler[0],    # BM
        self.cta_tiler[2],    # BK
        self.num_stages),     # PIPE
   )
   sB_layout, sB_swizzle = self._make_smem_layout_AB(
       mB.element_type,
       self.b_major_mode,
       ab_copy_bits,
       (self.cta_tiler[1],    # BN
        self.cta_tiler[2],    # BK
        self.num_stages),     # PIPE
   )

Here ``smem_tiler`` is ``(M_or_N, K, PIPE)``: ``(BM, BK, PIPE)`` for A and
``(BN, BK, PIPE)`` for B. The helper returns:

- ``sX_layout``: the logical SMEM layout with shape ``(BM_or_BN, BK, PIPE)``.
- ``sX_swizzle``: the swizzle applied when the tensor is materialized in SMEM.

The helper from ``tensorop_gemm.py`` implements the following four steps:

1. **Pick the major-mode size.** For a row-major operand, the contiguous
   dimension is K, so the helper uses ``smem_tiler[1]``. For a col-major
   operand, the contiguous dimension is M or N, so it uses ``smem_tiler[0]``.

2. **Cap the contiguous span at 128 bytes.** This keeps the layout atom within
   the swizzle span used by the example. The cap is 64 elements for F16/BF16
   and 128 elements for FP8.

3. **Build the swizzle.** With ``copy_bits = 128`` (16 bytes), the helper
   derives three arguments for ``make_swizzle``:

   - ``swizzle_bits = log2(major_mode_size * dtype.width / copy_bits)``,
     capped at 3. This is the number of address bits that get XOR'd.
   - ``base_bits = log2(copy_bits / 8)`` — log2 of the copy width in
     bytes (= 4 for 16-byte copies).
   - ``shift_bits = log2(copy_bits / dtype.width)`` — log2 of the copy
     width in elements (= 3 for F16 with 128-bit copies, i.e. 8 elements).

4. **Build an 8-row layout atom and tile it.** The constant 8 comes from
   ``ldmatrix``: each warp-level load touches 8 rows of shared memory
   (32 threads, 4 matrices per load). Row-major uses an atom
   ``(8, major_mode_size):(major_mode_size, 1)`` — 8 rows of contiguous
   K-elements. Col-major uses
   ``(major_mode_size, 8):(1, major_mode_size)`` — contiguous MN-elements
   across 8 K-rows. ``tile_to_shape`` then broadcasts that atom across the
   full ``(M_or_N, K, PIPE)`` SMEM tensor.

For the running F16 example (``cta_tiler = (128, 128, 32)``,
``num_stages = 4``, ``copy_bits = 128``):

.. code-block:: text

   A operand (row-major, smem_tiler = (128, 32, 4)):
     major_mode_size = 32
     atom = (8, 32):(32, 1)
     swizzle = make_swizzle(2, 4, 3)
     tiled layout -> sA: (128, 32, 4)

   B operand (col-major, smem_tiler = (128, 32, 4)):
     major_mode_size = min(128, 64) = 64
     atom = (64, 8):(1, 64)
     swizzle = make_swizzle(3, 4, 3)
     tiled layout -> sB: (128, 32, 4)


**Kernel side** (``@cute.kernel``):

The layout and swizzle are passed to shared-memory allocation:

.. code-block:: python

   @cute.struct
   class SharedStorageAB:
       a: cute.struct.Align[
           cute.struct.MemRange[mA.element_type, cute.cosize(sA_layout)],
           16,
       ]
       b: cute.struct.Align[
           cute.struct.MemRange[mB.element_type, cute.cosize(sB_layout)],
           16,
       ]

   sA = SharedStorageAB(storage).a.get_tensor(sA_layout, swizzle=sA_swizzle)
   sB = SharedStorageAB(storage).b.get_tensor(sB_layout, swizzle=sB_swizzle)

After allocation:

- ``sA`` has shape ``(BM, BK, PIPE)``.
- ``sB`` has shape ``(BN, BK, PIPE)``.

These are the staged SMEM tensors written by ``cp.async`` and later consumed by
``partition_A`` / ``partition_B``, ``make_fragment_A`` / ``make_fragment_B``,
and the ``ldmatrix`` copy views described in `Making Fragments`_.


Executing the GEMM (Main Loop)
-------------------------------

The main loop iterates over K-tiles and, within each tile, over k-blocks
(``num_k_block = BK / perm_K``). Each k-block loads A and B from SMEM into
registers via ``ldmatrix``, then issues ``cute.gemm``.

.. code-block:: python

   tCrC.fill(0.0)

   for k_tile in range(k_tile_count):
       for k_block in cutlass.range(num_k_block, unroll_full=True):
           # Wait for next SMEM stage at the tile boundary
           if k_block == num_k_block - 1:
               cute.arch.cp_async_wait_group(num_smem_stages - 2)
               cute.arch.sync_threads()

           # ldmatrix: prefetch next k-block from SMEM → RMEM
           k_block_next = (k_block + 1) % num_k_block
           cute.copy(tiled_copy_s2r_A, tCsA_p[None, None, k_block_next],
                     tCrA_copy_view[None, None, k_block_next])
           cute.copy(tiled_copy_s2r_B, tCsB_p[None, None, k_block_next],
                     tCrB_copy_view[None, None, k_block_next])

           # cp.async: issue GMEM → SMEM for next K-tile
           # ... (see tensorop_gemm.py for pipeline pointer management)

           # MMA: tCrC += tCrA * tCrB
           cute.gemm(tiled_mma, tCrC, tCrA[None, None, k_block], tCrB[None, None, k_block], tCrC)

   cute.arch.cp_async_wait_group(0)
   cute.arch.sync_threads()

Key points:

- ``cute.gemm`` is **synchronous** — it emits ``mma.sync.aligned``
  instructions. There is no accumulate-mode flag; the accumulator
  (``tCrC``) is always read and written.
- All operands must be in **registers** before ``cute.gemm`` is called.
  The ``ldmatrix`` copies above prefetch the next k-block into
  ``tCrA`` / ``tCrB`` from SMEM each iteration.
- The ``cp.async`` / ``cp_async_wait_group`` calls manage the GMEM→SMEM
  pipeline; see ``tensorop_gemm.py`` for predication, K-residue handling,
  and pipeline pointer management.


Complete Workflow
------------------

Putting it all together, a typical Ampere warp MMA GEMM has this structure:

**Host function** (``@cute.jit``):

.. code-block:: python

   import cutlass
   import cutlass.cute as cute

   @cute.jit
   def host_function(mA: cute.Tensor, mB: cute.Tensor, mC: cute.Tensor, stream):
       # 1. Create the MMA op and tiled MMA
       op = cute.nvgpu.warp.MmaF16BF16Op(cutlass.Float16, cutlass.Float32, (16, 8, 16))
       atom_layout_mnk = (2, 2, 1)
       permutation_mnk = (
           atom_layout_mnk[0] * 16,
           atom_layout_mnk[1] * 8 * 2,
           atom_layout_mnk[2] * 16,
       )
       tC = cute.make_layout(atom_layout_mnk)
       tiled_mma = cute.make_tiled_mma(op, tC, permutation_mnk=permutation_mnk)

       # 2. Create SMEM layouts
       ab_copy_bits = 128
       sA_layout, sA_swizzle = _make_smem_layout_AB(
           mA.element_type, a_major_mode, ab_copy_bits,
           (cta_tiler[0], cta_tiler[2], num_stages),
       )
       sB_layout, sB_swizzle = _make_smem_layout_AB(
           mB.element_type, b_major_mode, ab_copy_bits,
           (cta_tiler[1], cta_tiler[2], num_stages),
       )

       # 3. Launch the kernel
       kernel(mA, mB, mC, ..., tiled_mma, sA_layout, sA_swizzle,
              sB_layout, sB_swizzle).launch(
           grid=grid, block=[128, 1, 1], stream=stream,
       )

**Kernel function** (``@cute.kernel``):

.. code-block:: python

  @cute.kernel
  def kernel(mA: cute.Tensor, mB: cute.Tensor, mC: cute.Tensor,
            ..., tiled_mma: cute.TiledMma):
      tidx, _, _ = cute.arch.thread_idx()
      bidx, bidy, bidz = cute.arch.block_idx()

      # -- CTA-tiled global tensors --
      gA = cute.local_tile(mA[None, None, bidz], cta_tiler, (bidx, bidy, None), proj=(1, None, 1))
      gB = cute.local_tile(mB[None, None, bidz], cta_tiler, (bidx, bidy, None), proj=(None, 1, 1))
      gC = cute.local_tile(mC[None, None, bidz], cta_tiler, (bidx, bidy, None), proj=(1, 1, None))

      # -- Allocate SMEM --
      @cute.struct
      class SharedStorageAB:
          a: cute.struct.Align[cute.struct.MemRange[mA.element_type, cute.cosize(sA_layout)], 16]
          b: cute.struct.Align[cute.struct.MemRange[mB.element_type, cute.cosize(sB_layout)], 16]

      smem = cutlass.utils.SmemAllocator()
      storage = smem.allocate(SharedStorageAB)
      sA = SharedStorageAB(storage).a.get_tensor(sA_layout, swizzle=sA_swizzle)  # (BM, BK, PIPE)
      sB = SharedStorageAB(storage).b.get_tensor(sB_layout, swizzle=sB_swizzle)  # (BN, BK, PIPE)
      sC = ...  # (BM, BN) SMEM for epilogue (non-MMA, see tensorop_gemm.py)

      # -- GMEM → SMEM copy partitions (cp.async) --
      # ... setup tAgA, tAsA, tBgB, tBsB (see tensorop_gemm.py)

      # -- MMA partitions and fragments --
      thr_mma = tiled_mma.get_slice(tidx)
      tCsA = thr_mma.partition_A(sA)   # (MMA, MMA_M, MMA_K, PIPE)
      tCsB = thr_mma.partition_B(sB)   # (MMA, MMA_N, MMA_K, PIPE)
      tCsC = thr_mma.partition_C(sC)   # (MMA, MMA_M, MMA_N)
      tCgC = thr_mma.partition_C(gC)   # (MMA, MMA_M, MMA_N)
      tCrA = tiled_mma.make_fragment_A(tCsA[None, None, None, 0])  # (MMA, MMA_M, MMA_K)
      tCrB = tiled_mma.make_fragment_B(tCsB[None, None, None, 0])  # (MMA, MMA_N, MMA_K)
      tCrC = tiled_mma.make_fragment_C(tCgC)                       # (MMA, MMA_M, MMA_N)
      tCrC.fill(0.0)

      # -- ldmatrix retiling (see "Making Fragments" § SMEM → RMEM load) --
      # ... build tiled_copy_s2r_A/B from LdMatrix8x8x16bOp + make_tiled_copy_A/B
      # ... then: tCsA_copy_view = partition_S(sA), tCrA_copy_view = retile(tCrA), etc.

      # -- Prologue: cp.async fills num_stages-1 SMEM buffers --
      # -- Prefetch first k-block into registers via ldmatrix --
      # ... (see tensorop_gemm.py for predication, residual_k, and pipeline setup)

      # -- Main loop --
      for k_tile in range(k_tile_count):
          for k_block in cutlass.range(num_k_block, unroll_full=True):
              if k_block == num_k_block - 1:
                  cute.arch.cp_async_wait_group(num_smem_stages - 2)
                  cute.arch.sync_threads()

              # ldmatrix: prefetch next k-block from SMEM → RMEM
              # tCsA_p / tCsB_p are per-pipeline-stage slices, e.g.:
              #   tCsA_p = tCsA_copy_view[None, None, None, smem_pipe_read]
              k_block_next = (k_block + 1) % num_k_block
              cute.copy(tiled_copy_s2r_A, tCsA_p[None, None, k_block_next],
                        tCrA_copy_view[None, None, k_block_next])
              cute.copy(tiled_copy_s2r_B, tCsB_p[None, None, k_block_next],
                        tCrB_copy_view[None, None, k_block_next])

              # cp.async: issue GMEM → SMEM for next K-tile
              # ... (see tensorop_gemm.py for pipeline pointer management)

              # MMA
              cute.gemm(tiled_mma, tCrC, tCrA[None, None, k_block],
                        tCrB[None, None, k_block], tCrC)

      # -- Epilogue: RMEM → SMEM → RMEM → GMEM --
      cute.arch.cp_async_wait_group(0)
      cute.arch.sync_threads()
      tCrD = cute.make_fragment_like(tCrC, c_dtype)
      tCrD[None] = epilogue_op(tCrC.load()).to(c_dtype)
      cute.autovec_copy(tCrD, tCsC)   # RMEM → SMEM
      cute.arch.sync_threads()
      # ... reload with epilogue thread layout, then vectorized store to GMEM


Beyond Simple Dense MMAs
------------------------

The warp MMA DSL supports more complex MMA operations beyond simple dense MMA:

- Block-scaled MMA

.. {$nv-internal-release begin}

Internal builds additionally provide:

- Sparse MMA

.. {$nv-internal-release end}

.. {$nv-internal-release begin}

Sparse MMA
~~~~~~~~~~

Sparse MMA exploits **2:4 structured sparsity** in operand A: out of every
4 consecutive K-elements, exactly 2 are non-zero. The hardware consumes a
compressed A operand together with a compact **metadata** tensor ``E`` that
encodes which 2 of 4 positions are non-zero.

Compared to dense MMA, the MMA API differences are:

**1. MMA op creation** — use ``MmaF16BF16SparseOp`` with an extra
``sparse_metadata_format`` parameter. The sparse instruction K is doubled
relative to dense (dense ``m16n8k8`` → sparse ``m16n8k16``, dense
``m16n8k16`` → sparse ``m16n8k32``) because operand A is 2:4 compressed:

.. code-block:: python

  from cutlass.cute.nvgpu.warp.mma import SparseMetadataFormat

  # Dense F16 (for comparison): inst_K = 16
  dense_op = cute.nvgpu.warp.MmaF16BF16Op(
      cutlass.Float16, cutlass.Float32, (16, 8, 16),
  )

  # Sparse F16: inst_K = 32 (2× dense, since A is 2:4 compressed)
  sparse_op = cute.nvgpu.warp.MmaF16BF16SparseOp(
      cutlass.Float16,                         # A/B element type
      cutlass.Float32,                         # accumulator type
      (16, 8, 32),                             # instruction shape (M, N, K)
      SparseMetadataFormat.TID,                # metadata format
  )
  tiled_mma = cute.make_tiled_mma(sparse_op, cute.make_layout((1, 1, 1)))

.. code-block:: text

  Supported instruction shapes for MmaF16BF16SparseOp:

  | A/B Type | Acc Type  | Inst Shape     |
  |----------|-----------|----------------|
  | F16      | F16, F32  | (16,8,16), (16,8,32) |
  | BF16     | F32       | (16,8,16), (16,8,32) |

**2. Compressed A tensor and metadata E** — operand A stores only the
two non-zero values per group of 4 K-elements (half the storage). The
metadata tensor ``E`` records which 2 of 4 positions are non-zero. The
exact bit encoding depends on ``SparseMetadataFormat`` and on how the
implementation packs metadata. In this repository, helper code that
generates 2:4 test inputs packs two 4-bit metadata entries into each
``uint8`` value:

.. code-block:: python

  # Example metadata values used by examples/CuTeDSL/helpers/sparse_utils.py
  # Each nibble selects which 2 of 4 positions are non-zero.
  metadata_values = [0x4, 0x8, 0x9, 0xC, 0xD, 0xE]

.. code-block:: text

  Dense A: (M, K)                    Sparse operands:
  +--+--+--+--+--+--+--+--+         +--+--+--+--+
  | a| 0| b| 0| c| 0| d| 0|   →     | a| b| c| d|   (compressed A values)
  +--+--+--+--+--+--+--+--+         +--+--+--+--+

                                    E stores the non-zero positions
                                    for each 2:4 group.

**3. Fragments** — the dense-style fragment APIs for A, B, and C still
apply to the sparse atom:

.. code-block:: python

  # A/B/C fragments — same public API shape as dense
  tCsA = thr_mma.partition_A(sA)
  tCsB = thr_mma.partition_B(sB)
  tCgC = thr_mma.partition_C(gC)

  tCrA = tiled_mma.make_fragment_A(tCsA[None, None, None, 0])
  tCrB = tiled_mma.make_fragment_B(tCsB[None, None, None, 0])
  tCrC = tiled_mma.make_fragment_C(tCgC)
  tCrC.fill(0.0)

Sparse metadata ``E`` is an auxiliary operand associated with A. The
public warp API and tests in this repository verify op construction and
the ``cute.gemm(..., [A, E], B, ...)`` calling convention, but they do
not provide an end-to-end warp sparse kernel showing the exact
``partition`` / ``copy`` / ``make_fragment`` sequence for ``E``. For
that reason, this document intentionally does not spell out an ``E``
fragment construction sequence that has no example backing it.

**4. Modified gemm call** — the metadata E is passed alongside operand A
as a list. This part of the API is verified by ``cutlass.cute.algorithm.gemm``:

.. code-block:: python

  # Schematic only: E_k is the metadata operand for the same k-slice as A_k.
  A_k = tCrA[None, None, k_block]
  E_k = metadata_k
  B_k = tCrB[None, None, k_block]

  cute.gemm(
      tiled_mma,
      tCrC,
      [A_k, E_k],   # [A, E]
      B_k,
      tCrC,
  )

.. code-block:: text

  Dense gemm call:
    cute.gemm(tiled_mma, tCrC, A_k, B_k, tCrC)

  Sparse gemm call:
    cute.gemm(tiled_mma, tCrC, [A_k, E_k], B_k, tCrC)
                              ^^^^  ^^^
                              A     metadata

The epilogue (RMEM → SMEM → GMEM) is identical to a dense kernel.

.. note:: An end-to-end warp sparse GEMM example is not yet available in the
  examples directory. The closest verified references in this repository are
  ``cutlass_ir/compiler/test/python/not_pytest/sm_80/test_mma_atom.py`` for
  op construction, ``cutlass_ir/compiler/test/python/api/sm_120a/test_nvgpu_warp_mma.py``
  for tiled sparse MMA construction, and
  ``examples/CuTeDSL/helpers/sparse_utils.py`` for
  2:4 metadata packing.

.. {$nv-internal-release end}


Block-scaled MMA
~~~~~~~~~~~~~~~~

Block-scaled MMA multiplies narrow-type matrices (FP4) while applying
**per-block scale factors** along the GEMM-K dimension. Each vector of
``sf_vec_size`` consecutive K-elements shares a single scale factor, so the
hardware computes ``D = (SFA · A) * (SFB · B) + C``. The scale factors live
in **registers** alongside the operands and must be loaded from SMEM before
each ``gemm`` call.

Supported ops: ``MmaMXF4Op`` (SM120a+), ``MmaMXF4NVF4Op`` (SM120a+).

Compared to a dense MMA kernel, a block-scaled kernel has four additional concerns:

**1. MMA op creation** — block-scaled ops fix the data type to FP4
(E2M1) and the accumulator to FP32. The scale-factor type and vector
size distinguish the two ops:

.. code-block:: python

  # MXF4: UE8M0 scales, sf_vec_size = 32
  op = cute.nvgpu.warp.MmaMXF4Op(
      cutlass.Float4E2M1FN,     # A/B element type (fixed: E2M1)
      cutlass.Float32,          # accumulator type (fixed: F32)
      cutlass.Float8E8M0FNU,    # scale-factor type
  )  # instruction shape = (16, 8, 64), sf_vec_size = 32

  # MXF4NVF4: UE4M3 scales, sf_vec_size = 16
  op = cute.nvgpu.warp.MmaMXF4NVF4Op(
      cutlass.Float4E2M1FN,     # A/B element type (fixed: E2M1)
      cutlass.Float32,          # accumulator type (fixed: F32)
      cutlass.Float8E4M3FN,     # scale-factor type
  )  # instruction shape = (16, 8, 64), sf_vec_size = 16

.. code-block:: text

  | Op            | A/B Type | SF Type | Acc  | Inst Shape  | SF Vec Size |
  |---------------|----------|---------|------|-------------|-------------|
  | MmaMXF4Op     | E2M1     | UE8M0   | F32  | (16,8,64)   | 32          |
  | MmaMXF4NVF4Op | E2M1     | UE4M3   | F32  | (16,8,64)   | 16          |

**2. Extra global tensors and SMEM layouts for scale factors** — the host
function creates SFA/SFB tensors and allocates SMEM layouts for them
alongside A and B:

.. code-block:: python

  import cutlass.utils.blockscaled_layout as blockscaled_utils
  import cutlass.utils.blackwell_helpers as sm120_utils

  # Scale-factor global tensors (host side)
  sfa_layout = blockscaled_utils.tile_atom_to_shape_SF(a.shape, sf_vec_size)
  sfa_tensor = cute.make_tensor(sfa.iterator, sfa_layout)
  sfb_layout = blockscaled_utils.tile_atom_to_shape_SF(b.shape, sf_vec_size)
  sfb_tensor = cute.make_tensor(sfb.iterator, sfb_layout)

  # SMEM layouts for scale factors (SM120-specific helper)
  sfa_smem_layout = blockscaled_utils.sm120_make_smem_layout_sfa(
      tiled_mma, tile_shape_mnk, sf_vec_size, num_stages,
  )
  sfb_smem_layout = blockscaled_utils.sm120_make_smem_layout_sfb(
      tiled_mma, tile_shape_mnk, sf_vec_size, num_stages,
  )

**3. SF fragment creation and SMEM→RMEM retiling** — scale-factor
fragments use a ``CopyUniversalOp`` with thread-value layouts derived
from the tiled MMA, rather than the ``ldmatrix``-based path used for
A and B:

.. code-block:: python

  # A/B fragments (same as dense)
  tCrA = tiled_mma.make_fragment_A(tCsA[None, None, None, 0])
  tCrB = tiled_mma.make_fragment_B(tCsB[None, None, None, 0])

  # SF fragments (SM120-specific partition helpers)
  tCrSFA = sm120_utils.partition_fragment_SFA(sSFA[None, None, 0], thr_mma, tidx)
  tCrSFB = sm120_utils.partition_fragment_SFB(sSFB[None, None, 0], thr_mma, tidx)

  # A/B: ldmatrix retiling (same as dense)
  atom_copy_A = cute.make_copy_atom(cute.nvgpu.warp.LdMatrix8x8x16bOp(...), a_dtype)
  smem_tiled_copy_A = cute.make_tiled_copy_A(atom_copy_A, tiled_mma)

  # SF: CopyUniversal with SF-specific thread-value layout
  atom_copy_SF = cute.make_copy_atom(cute.nvgpu.CopyUniversalOp(), sf_dtype)
  smem_tiled_copy_SFA = cute.make_tiled_copy(
      atom_copy_SF,
      sm120_utils.get_layoutSFA_TV(tiled_mma),
      (cute.size(tiled_mma.permutation_mnk[0]), cute.size(tiled_mma.permutation_mnk[2])),
  )
  smem_tiled_copy_SFB = cute.make_tiled_copy(
      atom_copy_SF,
      sm120_utils.get_layoutSFB_TV(tiled_mma),
      (cute.size(tiled_mma.permutation_mnk[1]), cute.size(tiled_mma.permutation_mnk[2])),
  )

**4. Modified main loop** — each k-block loads A, B, SFA, and SFB from
SMEM into registers. The ``cute.gemm`` call passes ``[A, SFA]`` and
``[B, SFB]`` as operand lists:

.. code-block:: python

  for k_block_idx in cutlass.range(num_k_blocks, unroll_full=True):
      # ldmatrix: load A and B from SMEM → RMEM (same as dense)
      cute.copy(smem_tiled_copy_A, tCsA_p[None, None, k_block_next],
                tCrA_copy_view[None, None, k_block_next])
      cute.copy(smem_tiled_copy_B, tCsB_p[None, None, k_block_next],
                tCrB_copy_view[None, None, k_block_next])

      # CopyUniversal: load SFA and SFB from SMEM → RMEM            # NEW
      cute.copy(smem_tiled_copy_SFA,
                cute.filter_zeros(tCsSFA_p)[None, None, k_block_next],
                cute.filter_zeros(tCrSFA_copy_view)[None, None, k_block_next])
      cute.copy(smem_tiled_copy_SFB,
                cute.filter_zeros(tCsSFB_p)[None, None, k_block_next],
                cute.filter_zeros(tCrSFB_copy_view)[None, None, k_block_next])

      # MMA with scale factors passed as [value, scale] pairs
      cute.gemm(
          tiled_mma,
          accumulators,
          [tCrA[None, None, k_block_idx], tCrSFA[None, None, k_block_idx]],  # [A, SFA]
          [tCrB[None, None, k_block_idx], tCrSFB[None, None, k_block_idx]],  # [B, SFB]
          accumulators,
      )

.. code-block:: text

  Dense gemm call:
    cute.gemm(tiled_mma, acc, tCrA[k], tCrB[k], acc)

  Block-scaled gemm call:
    cute.gemm(tiled_mma, acc, [tCrA[k], tCrSFA[k]], [tCrB[k], tCrSFB[k]], acc)
                              ^^^^^^^^  ^^^^^^^^^    ^^^^^^^^  ^^^^^^^^^
                              value     scale        value     scale
                              (RMEM)    (RMEM)       (RMEM)    (RMEM)

Note that ``cute.filter_zeros`` is applied to the SF copy views because
the scale-factor SMEM layouts may contain padding zeros from the TMA
tiling. This strips the padded entries so the copy operates only on
valid elements.

The epilogue (RMEM → SMEM → GMEM) is identical to a dense kernel.


See also:

- Dense GEMM example (Ampere): ``examples/cute/ampere/kernel/dense_gemm/tensorop_gemm.py``
- Block-scaled GEMM example (SM120a): ``examples/cute/blackwell_geforce/kernel/blockscaled_gemm/dense_blockscaled_gemm_persistent_pingpong.py``
- Block-scaled layout utilities: ``cutlass.utils.blockscaled_layout``
- SM120 helper utilities: ``cutlass.utils.blackwell_helpers``
