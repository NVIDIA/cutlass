.. _wgmma_programming:

Warpgroup MMA Programming Guide
================================

Hopper (SM90a) introduced the **warpgroup-level MMA** PTX instruction family
``wgmma.mma_async.sync.aligned``. A warpgroup (128 threads / 4 warps)
cooperates on one asynchronous ``D = A * B + C`` matrix multiply-accumulate.

Key architectural characteristics:

* **Warpgroup scope:** One MMA is issued collectively by a 128-thread
  warpgroup rather than by a single warp.
* **Asynchronous issue model:** WGMMA instructions are ordered with
  ``cute.nvgpu.warpgroup.fence()``, ``commit_group()``, and ``wait_group()``.
* **Descriptor-based operand path:** Operand B is sourced from staged shared
  memory. Operand A can be sourced either from shared memory descriptors or
  from registers via ``OperandSource``.
* **Register accumulator:** The accumulator lives in RMEM and serves as both
  the input C and output D of ``cute.gemm()``.
* **Architecture-specific operand layouts:** F16/BF16 supports K-major and
  MN-major dense layouts when A comes from SMEM. FP8 and INT8 variants are
  K-major only.

The dense DSL op classes currently exposed are ``MmaF16BF16Op`` (F16/BF16),
``MmaF8Op`` (FP8 E4M3/E5M2), and ``MmaI8Op`` (INT8/UINT8); see
`Setting up the TiledMMA, MMA Ops`_ for their full constructor parameters,
instruction K extents, and major-mode constraints.

This guide outlines the CuTe Python DSL programming model for WGMMA kernels:
stage operands in SMEM, build fragment descriptors, launch asynchronous
warpgroup MMAs, and stage the RMEM accumulator back to GMEM in the epilogue.


.. contents:: **Contents**
   :local:
   :depth: 2

Global Memory (GMEM) to MMA data flow overview
----------------------------------------------

WGMMA instructions require us to stage B input operands in Shared Memory (SMEM),
while A input operands can be sourced from either SMEM or registers (RMEM).
SMEM operands are read asynchronously by the hardware via SMEM descriptors.
The accumulator is always kept in registers (RMEM) of the warpgroup.

The diagram below traces the full data flow of a WGMMA GEMM kernel, for the most
common case where A and B matrices are stored in GMEM and both are staged through
SMEM (``a_src=SMEM``), and the output matrix --accumulated in RMEM-- is written
back to GMEM through an SMEM staging buffer.

There are 3 parallel tracks where each has 2 sub-tracks. Three parallel tracks are
for operands A, B, and C/D, respectively. The two sub-tracks are for copying data between different memory
spaces and for MMA execution.

- **Operand A** (and symmetrically **Operand B**):

  - First, we need to create SMEM tensors for A and B matrices: ``sA`` and ``sB``. These
    tensors are physically allocated tensors that are the destination of TMA copy and
    the source operands for the WGMMA instructions.
  - Next the **data copy flow** creates the tensor views for copying data from GMEM to SMEM.
    It starts with ``mA`` tensor that represents the matrix A in global memory.
    Then ``mA`` → ``local_tile`` → ``gA`` operation creates the local tile view of A that is the
    slice of A matrix needed to compute the given CTA's output tile.
    Then ``tma_partition(tma, sA, gA)`` produces TMA views ``tAsA``, ``tAgA``,
    and the loop copies tiles from GMEM into SMEM via ``copy(tma, tAgA[k], tAsA[stage])``.
  - In parallel, the **MMA flow** turns the SMEM tensor into an iterable tensor of SMEM descriptors
    for the WGMMA instructions. ``sA`` (the same shared-memory allocation written by TMA)
    → ``partition_A`` → ``tCsA`` (MMA-partitioned SMEM view)
    → ``make_fragment_A`` → ``tCrA`` (SMEM descriptor passed to ``cute.gemm()``).
    Note that the SMEM descriptor is a view created from the SMEM tensor that is
    interpretable by the WGMMA instructions.

- **Accumulator C/D**:

  - **RMEM accumulator flow** (gemm input/output): ``partition_C(gC)`` → ``tCgC``
    → ``make_rmem_tensor(tCgC.shape)`` → ``acc``, which serves as both the accumulator
    input (C) and output (D) of ``cute.gemm()`` (and the WGMMA instruction).
  - **Output flow** (RMEM → SMEM → GMEM): After the main loop, the accumulator is
    type-converted and copied from registers to SMEM via ``stmatrix`` (R2S copy),
    then stored to global memory via TMA store (S2G copy):
    ``mC`` → ``local_tile`` → ``gC`` → ``partition_C`` → ``tCgC`` on the destination side,
    and ``tRS_rAcc``/``tRS_sD`` / ``bSG_sD``/``bSG_gD`` views drive the two copy stages.

.. code-block:: text

   Operand A Dataflow Path               Operand B Dataflow Path                 Accumulator C/D Dataflow Path
   ───────────────────────               ───────────────────────                 ─────────────────────────────

  mA: (M, K)           [GMEM]             mB: (N, K)            [GMEM]             ┌──── RMEM ──────────┐
   │                                       │                                       │ make_rmem_tensor() │
   │ local_tile(mA, cta_tiler, coord)      │ local_tile(mB, cta_tiler, coord)      │ acc: accumulator   │
   ▼                                       ▼                                       └───────┬────────────┘
  gA: (BM, BK, k)      [GMEM]             gB: (BN, BK, k)       [GMEM]                     │
   │                                       │                                       acc:(MMA,MMA_M,MMA_N) [RMEM]
   │  ┌──── SMEM ─────────┐                │  ┌──── SMEM ─────────┐                         │
   │  │ sA = alloc(layout)│                │  │ sB = alloc(layout)│                         │        mC: (M, N)     [GMEM]
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
   │     │        MMA_K,PIPE)              │     │        MMA_K,PIPE)                       │        │
   │     │  [SMEM descriptors]             │     │  [SMEM descriptors]                      │        │
   │     │        └─────────────┐          │     │        └─────────────┐                   │        │
   ╰─────┤                      │          ╰─────┤                      │                   │        │
         ▼                      │                ▼                      │                   │        │
   tma_partition(tma,           │              tma_partition(tma,       │                   │        │
    sA, gA)                     │               sB, gB)                 │                   │        │
    → tAsA, tAgA                │               → tBsB, tBgB            │                   │        │
         ▼                      │                    ▼                  │                   │        │
     ┌───┴────────────────────┐ │             ┌──────┴─────────────────┐│                   │        │
     │ TMA copy loop (A path):│ │             │ TMA copy loop (B path):││                   │        │
     │ copy(tma, tAgA[k],     │ │             │ copy(tma, tBgB[k],     ││                   │        │
     │      tAsA[stage])      │ │             │      tBsB[stage])      ││                   │        │
  ┌─▶│ (writes into sA;       │ │         ┌──▶│ (writes into sB;       ││                   │        │
  │  │  tCrA reads same sA)   │ │         │   │  tCrB reads same sB)   ││                   │        │
  │  │ repeat for next k/stage│ │         │   │ repeat for next k/stage││                   │        │
  │  └────────────────────────┘ │         │   └────────────────────────┘│                   │        │
  │        │                    │         │         │                   │                   │        │
  └────────┘                    ▼         └─────────┘                   ▼                   ▼        │
                                └───────┬───────────────────────────────┴───────────────────┘        │
                                        │                                                            │
                                        ▼                                                            │
                               ┌──────────────────────────────────────────────┐                      │
                               │ GEMM Loop:                                   |                      │
                               │ warpgroup.fence()                            │                      │
                               │ cute.gemm(tiled_mma,                         │                      │
                               │  acc,          D (output, RMEM),             │                      │
                          ┌──▶ │  tCrA[stage],  A (SMEM desc -> sA),          │                      │
                          │    │  tCrB[stage],  B (SMEM desc -> sB),          │                      │
                          │    │  acc)          C (accumulator, RMEM)         │                      │
                          │    │ warpgroup.commit_group()                     │                      │
                          │    │ warpgroup.wait_group(n)                      │                      │
                          │    └──────────────────────────────────────────────┘                      │
                          │       │     │                                                            │
                          └───────┘     |                                                            │
                                        ▼                                                            │
                                  Epilogue:                                                          │
                                  tRS_rAcc = retile(acc)                                             │
                                  tRS_rD   = type_convert(tRS_rAcc)                                  │
                                        │                                                            │
                                        ▼                                                            │
                                  R2S: copy(tiled_copy_r2s, tRS_rD, tRS_sD)                          │
                                  [RMEM → SMEM via stmatrix]                                         │
                                        │                                                            │
                                        ▼                                                            │
                                  sC = alloc(epi_layout) [SMEM]                                      │
                                  bSG_sD, bSG_gD = tma_partition(tma_c, sC, gC) ◀───────────────────┘
                                        │
                                        ▼
                                  S2G: copy(tma_c, bSG_sD[stage], bSG_gD[coord])
                                  [SMEM → GMEM via TMA store]

**Naming convention:**

* cta_tiler = (BM, BN, BK) = CTA-wide tiler dimensions
* ``mX`` = a global tensor, e.g., (M, K) for A
* ``gX`` = CTA-tiled GMEM slice, e.g., (BM, BK, k) for A
* ``sX`` = SMEM allocation, e.g., (BM, BK, PIPE) for A
* ``tAsA``/``tBsB`` = TMA-partitioned SMEM views
* ``tAgA``/``tBgB`` = TMA-partitioned GMEM views
* ``tCsX`` = MMA-partitioned SMEM view, e.g., (MMA, MMA_M, MMA_K, PIPE) for A
* ``tCrX`` = SMEM descriptor fragment, e.g., (MMA, MMA_M, MMA_K, PIPE) for A
* ``acc`` = RMEM accumulator, (MMA, MMA_M, MMA_N)
* ``tCgC`` = MMA-partitioned GMEM, (MMA, MMA_M, MMA_N)
* ``tRS_rAcc``/``tRS_sD`` = epilogue retile views for R2S (RMEM → SMEM) copy
* ``bSG_sD``/``bSG_gD`` = TMA-partitioned SMEM/GMEM views for epilogue store
* MMA = warpgroup atom thread-value layout; MMA_M/MMA_N/MMA_K = repeat counts
  (e.g., BM/inst_M), k = outer K-tiles, PIPE = pipeline stages

Setting up the TiledMMA, MMA Ops
---------------------------------

As shown in the data flow overview, CuTe DSL provides many utilities to tile/partition
the global memory tensors, and create fragment views of SMEM tensors for MMA instructions.

To utilize these functions, we need to setup the TiledMMA, MMA Ops first.

Creating a WGMMA Op
~~~~~~~~~~~~~~~~~~~~

A WGMMA op describes the hardware instruction to use, it has parameters like
data types, instruction shape, operand A source (SMEM or RMEM),
and operand major modes.

.. code-block:: python

   import cutlass
   import cutlass.cute as cute
   from cutlass.cute.nvgpu import OperandMajorMode
   import cutlass.cute.nvgpu.warpgroup as warpgroup

   op = warpgroup.MmaF16BF16Op(
       cutlass.Float16,                   # A/B element type
       cutlass.Float32,                   # accumulator type
       (64, 128, 16),                     # instruction shape (M, N, K)
       warpgroup.OperandSource.SMEM,      # A operand from shared memory
       OperandMajorMode.K,                # A is K-major
       OperandMajorMode.K,                # B is K-major
   )

The key parameters are:

- **Instruction shape** ``(M, N, K)``: determines the size of one hardware MMA
  instruction. WGMMA requires ``M = 64`` and ``8 <= N <= 256`` in steps of 8.
  K is fixed by the op class (16 for F16/BF16, 32 for FP8 and INT8).
- **OperandSource**: ``SMEM`` reads A from a shared memory descriptor; ``RMEM``
  reads A directly from registers.
- **OperandMajorMode**: ``K`` for K-major (default), ``MN`` for transposed layout.
  F16/BF16 supports both K-major and MN-major for A and B when ``a_src=SMEM``;
  when ``a_src=RMEM``, only B can be transposed. FP8 and INT8 are K-major only.


CuTe DSL provides implementation of the following WGMMA ops:

.. list-table:: WGMMA ops
   :header-rows: 1
   :widths: 30 24 46

   * - PTX name
     - Python class
     - Constructor parameters
   * - ``wgmma.mma_async.m64n{N}k16.{acc}.f16.f16`` / ``.bf16.bf16``
     - ``warpgroup.MmaF16BF16Op``
     - ``ab_dtype, acc_dtype, instruction_shape, a_src, a_major_mode, b_major_mode``
   * - ``wgmma.mma_async.m64n{N}k32.{acc}.{e4m3|e5m2}.{e4m3|e5m2}``
     - ``warpgroup.MmaF8Op``
     - ``a_dtype, b_dtype, acc_dtype, instruction_shape, a_src, a_major_mode, b_major_mode``
   * - ``wgmma.mma_async.m64n{N}k32.s32.{s8|u8}.{s8|u8}``
     - ``warpgroup.MmaI8Op``
     - ``a_dtype, b_dtype, acc_dtype, instruction_shape, a_src, a_major_mode, b_major_mode``


Creating a Tiled MMA
~~~~~~~~~~~~~~~~~~~~~

A ``TiledMma`` tiles the WGMMA atom across the CTA tile. You can pass the op
directly or create an explicit atom first.

.. code-block:: python

   # Option 1: directly from op (common shorthand)
   tiled_mma = cute.make_tiled_mma(op)

   # Option 2: explicit atom creation
   atom = cute.make_mma_atom(op)
   tiled_mma = cute.make_tiled_mma(atom)

Spatial tiling with a repeat count
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

A repeat tuple ``(M_rep, N_rep, K_rep)`` replicates the WGMMA atom across the
M, N, and K dimensions, producing a larger tiled MMA that covers a bigger CTA
tile with a single ``cute.gemm`` call. Each entry in the repeat tuple
corresponds to one **warpgroup** (128 threads / 4 warps), so ``(2, 1, 1)``
uses two warpgroups — the standard configuration for large Hopper tiles:

.. code-block:: python

   atom = cute.make_mma_atom(op)   # op shape: (64, 128, 16)
   tiled_mma = cute.make_tiled_mma(
       atom,
       atom_layout_mnk=(2, 1, 1),  # 2 warpgroups in M
   )

.. code-block:: text

  WGMMA Atom                             make_tiled_mma(atom, (2, 1, 1))
  +---------------+                      +----------------+
  |               |                      |                | ^
  |   64 x 128    |                      |  Atom (0,0,0)  | |
  |     x 16      |    --(2,1,1)-->      |   64 x 128     | | 2 x M_atom
  |               |       repeat         |     x 16       | |  = 128
  |               |                      | [Warpgroup 0]  | |
  +---------------+                      +----------------+ |
                                         |                | |
                                         |  Atom (1,0,0)  | |
                                         |   64 x 128     | |
                                         |     x 16       | |
                                         | [Warpgroup 1]  | v
                                         +----------------+
                                         <-- N_atom = 128 -->
                                         K unchanged = 16

The Hopper dense GEMM examples
(``examples/cute/hopper/kernel/dense_gemm/dense_gemm.py``) use this pattern.
The helper ``sm90_utils.make_trivial_tiled_mma(...)`` selects the repeat count
automatically:

- ``atom_layout_mnk = (2, 1, 1)`` when both ``tile_M > 64`` and
  ``tile_N > 128`` (two warpgroups reduce register pressure).
- ``atom_layout_mnk = (1, 1, 1)`` otherwise (a single warpgroup suffices).

.. code-block:: python

   import cutlass.utils.hopper_helpers as sm90_utils

   tiled_mma = sm90_utils.make_trivial_tiled_mma(
       a_dtype,
       b_dtype,
       a_major_mode,
       b_major_mode,
       acc_dtype,
       atom_layout_mnk=(2, 1, 1),
       tiler_mn=(64, 128),         # atom instruction shape (M, N)
   )

Custom tile permutation with ``permutation_mnk``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

``make_tiled_mma`` also accepts an optional ``permutation_mnk`` argument that
controls how the tiled atom footprint is laid out across M, N, and K.  At a
high level:

- ``atom_layout_mnk`` tells CuTe how many atoms (warpgroups) to replicate.
- ``permutation_mnk`` tells CuTe how the final tiled footprint is ordered.

``permutation_mnk`` is a tuple of layouts or integers that represent the
tile size and ordering of values along each dimension.  When a mode's
permutation size is larger than the atom layout's natural coverage
(``atom_layout x inst_shape``), each warpgroup receives additional values
to fill the extended region — the warpgroup count stays the same, but each
warpgroup holds more data.

.. code-block:: python

   atom = cute.make_mma_atom(op)   # op shape: (64, 128, 16)
   tiled_mma = cute.make_tiled_mma(
       atom,
       atom_layout_mnk=(2, 1, 1),
       permutation_mnk=(128, 256, 16),   # extend N from 128 to 256
   )

.. code-block:: text

  Without permutation — natural atom coverage (M = 128, N = 128):

  C tile (M=128, N=128)
  +----------------+
  |                | ^
  | [Warpgroup 0]  | |
  |    64 x 128    | | 2 x inst_M
  |                | |  = 128
  +----------------+ |
  |                | |
  | [Warpgroup 1]  | |
  |    64 x 128    | |
  |                | v
  +----------------+
  <--- N = 128 --->
  (each warpgroup owns one (64, 128) atom)

  With permutation_mnk = (128, 256, 16) — N extended to 256:

  C tile (M=128, N=256)
  +----------------+----------------+
  |                |                | ^    N = 128 → 256:
  | [Warpgroup 0]  | [Warpgroup 0]  | |    atom pattern repeats
  |    64 x 128    |    64 x 128    | |    along N. Each warpgroup
  |                |                | |    now holds 2x the values
  +----------------+----------------+ |    along N (same threads,
  |                |                | |    more data).
  | [Warpgroup 1]  | [Warpgroup 1]  | |
  |    64 x 128    |    64 x 128    | |
  |                |                | v
  +----------------+----------------+
  <------------ N = 256 ------------>
  | atom coverage  |  value repeat  |

**Why WGMMA typically does not need permutation_mnk:**  The WGMMA
instruction already has a large N dimension (64, 128, or 256), so the natural
atom coverage is wide enough that no permutation is needed to align with SMEM
swizzle widths.  The Hopper
dense GEMM examples (``dense_gemm.py``, ``dense_gemm_persistent.py``) use
``atom_layout_mnk`` alone without ``permutation_mnk``.

When ``permutation_mnk`` is not provided (default), the tile ordering is
sequential and no permutation is applied.


Partitioning Tensors
---------------------

Before computing, partition the CTA-tiled tensors according to the
tiled MMA layout. WGMMA partitioning is **warpgroup-oriented**: each
warpgroup (128 threads / 4 warps) receives its own slice of the CTA
tile, sized to match the SMEM descriptors and register accumulators
that the WGMMA instruction expects.

**2-warpgroup example**

``GEMM (M, N, K) = (512, 768, 256)``, ``tile_shape_mnk = (128, 256, 64)``,
F16 WGMMA atom = (64, 256, 16), ``atom_layout_mnk = (2, 1, 1)``,
``num_stages = 4``, 2 warpgroups = 256 threads.

Global matrices:

.. code-block:: text

     mA: (M, K) = (512, 256)       mB: (N, K) = (768, 256)       mC: (M, N) = (512, 768)

          K=256                          K=256                       N=768
        |<--------->|               |<--------->|             |<----------------->|
        +-----------+               +-----------+             +---+---+---+-------+
        |           | ^             |           | ^           |   |   |   |       | ^
        |    mA     | | M=512       |    mB     | | N=768     |   |   |   |       | | M=512
        |           | v             |           | v           |   |   |   |       | v
        +-----------+               +-----------+             +---+---+---+-------+

Tiling with ``tile_shape_mnk = (BM, BN, BK) = (128, 256, 64)`` gives
M/BM = 4 tiles, N/BN = 3 tiles, K/BK = 4 tiles:

.. code-block:: text

    mA tiled into (M/BM x K/BK)    mB tiled into (N/BN x K/BK)   mC tiled into (M/BM x N/BN)
    = (4 x 4) blocks               = (3 x 4) blocks              = (4 x 3) blocks

      BK=64  x4                       BK=64  x4                      BN=256  x3
    |<--->|                         |<--->|                        |<------>|
    +-----+-----+-----+-----+       +-----+-----+-----+-----+      +--------+--------+--------+
    |     |     |     |     | ^     |     |     |     |     | ^    | (0,0)  | (0,1)  | (0,2)  | ^
    |     |     |     |     | |128  |     |     |     |     | |256 |        |        |        | |128
    +-----+-----+-----+-----+ v     +-----+-----+-----+-----+ v    +--------+--------+--------+ v
    |     |     |     |     | ^     |     |     |     |     | ^    | (1,0)  | (1,1)  | (1,2)  | ^
    |     |     |     |     | |128  |     |     |     |     | |256 |        |        |        | |128
    +-----+-----+-----+-----+ v     +-----+-----+-----+-----+ v    +--------+--------+--------+ v
    |     |     |     |     |       |     |     |     |     |      | (2,0)  | (2,1)  | (2,2)  |
    +-----+-----+-----+-----+       +-----+-----+-----+-----+      +--------+--------+--------+
    |     |     |     |     |                                      | (3,0)  | (3,1)  | (3,2)  |
    +-----+-----+-----+-----+                                      +--------+--------+--------+

Each CTA picks one (M-tile, N-tile) coordinate.
For example, CTA at ``tile_coord = (1, 0, :)``.

After ``local_tile`` — one CTA's tile (``k = K/BK = 256/64 = 4``):

.. code-block:: text

     gA: (BM, BK, k) = (128, 64, 4)   gB: (BN, BK, k) = (256, 64, 4)   gC: (BM, BN) = (128, 256)

          BK=64                              BK=64                       BN=256
        |<----->|                         |<----->|                 |<--------->|
        +-------+--                       +-------+--               +-----------+
        |       |..                       |       |..               |           | ^
   BM=  |  gA   | k=4                BN=  |  gB   | k=4         BM= |    gC     | | 128
    128 |       |                    256  |       |             128 |           | v
        +-------+                         +-------+                 +-----------+

SMEM tensors ``sA`` and ``sB`` include a pipeline staging dimension:

.. code-block:: text

     sA: (BM, BK, PIPE) = (128, 64, 4)       sB: (BN, BK, PIPE) = (256, 64, 4)

``get_slice(warp_group_thread_layout(warp_group_idx))`` — each
warpgroup receives its slice of the tiled MMA footprint.
With ``atom_layout_mnk = (2, 1, 1)`` and inst shape ``(64, 256, 16)``,
the tiled MMA covers ``(2x64, 1x256, 16) = (128, 256, 16)`` which
exactly matches the CTA tile in M and N. Each warpgroup owns one
64-row slice of M:

.. code-block:: text

        sA (one pipeline stage, BM=128, BK=64):

        Warpgroup 0's slice               Warpgroup 1's slice
        inst_K  inst_K  inst_K  inst_K
         =16     =16     =16     =16
        |<--->|<--->|<--->|<--->|         |<--->|<--->|<--->|<--->|
        +-----+-----+-----+-----+  ^     +-----+-----+-----+-----+  ^
        |  0  |  1  |  2  |  3  |  |64   |  0  |  1  |  2  |  3  |  |64
        +-----+-----+-----+-----+  v     +-----+-----+-----+-----+  v
        |<-- MMA_K = BK/inst_K = 4 -->|  |<-- MMA_K = 4 ---------->|
        MMA_M = 64/64 = 1                MMA_M = 64/64 = 1

        gC (BM=128, BN=256):

        +---------------------------+  ^
        |  Warpgroup 0: 64 x 256    |  | 64
        |                           |  |
        +---------------------------+  v
        |  Warpgroup 1: 64 x 256    |  ^
        |                           |  | 64
        +---------------------------+  v
        <--------- N = 256 -------->
        MMA_M = 64/64 = 1, MMA_N = 256/256 = 1

After partition (per warpgroup):

- ``tCsA: (MMA, MMA_M, MMA_K, PIPE) = (MMA, 1, 4, 4)`` — MMA_M = BM / (atom_M x inst_M) = 128 / (2x64) = 1, MMA_K = BK / inst_K = 64 / 16 = 4
- ``tCsB: (MMA, MMA_N, MMA_K, PIPE) = (MMA, 1, 4, 4)`` — MMA_N = BN / (atom_N x inst_N) = 256 / (1x256) = 1, MMA_K = 4
- ``tCgC: (MMA, MMA_M, MMA_N) = (MMA, 1, 1)`` — MMA_M = 1, MMA_N = 1

The first mode ``MMA`` contains the atom's **thread x value** layout — it
encodes which registers within a warpgroup hold which matrix elements.
The remaining modes are repeat counts that tile the atom across the
full CTA tile.

.. note:: Because the WGMMA instruction shape is large (64 x {64..256}),
   the tiled MMA footprint typically covers the entire CTA tile in M and N
   with just one or two warpgroups.  This means MMA_M and MMA_N are often 1.
   The MMA_K dimension is where the repeat count is non-trivial (BK / inst_K
   iterations per pipeline stage).

**1-warpgroup example (contrast)**

For a smaller tile ``(128, 128, 64)`` with ``atom_layout_mnk = (1, 1, 1)``,
inst shape ``(64, 128, 16)``, and ``num_stages = 4``,
the tiled MMA covers only ``(64, 128, 16)``.
Now a single warpgroup must iterate over two atom-blocks along M:

- ``tCsA: (MMA, MMA_M, MMA_K, PIPE) = (MMA, 2, 4, 4)`` — MMA_M = 128 / (1x64) = 2
- ``tCsB: (MMA, MMA_N, MMA_K, PIPE) = (MMA, 1, 4, 4)`` — MMA_N = 128 / (1x128) = 1
- ``tCgC: (MMA, MMA_M, MMA_N) = (MMA, 2, 1)``

.. code-block:: python

   # Based on examples/cute/hopper/kernel/dense_gemm/dense_gemm.py
   @cute.kernel
   def kernel(tiled_mma: cute.TiledMma, ...):
       tidx, _, _ = cute.arch.thread_idx()

       # CTA-tiled global tensors
       gA_mkl = cute.local_tile(
           mA_mkl, tile_shape_mnk, tile_coord_mnkl, proj=(1, None, 1)
       )
       gB_nkl = cute.local_tile(
           mB_nkl, tile_shape_mnk, tile_coord_mnkl, proj=(None, 1, 1)
       )
       gC_mnl = cute.local_tile(
           mC_mnl, tile_shape_mnk, tile_coord_mnkl, proj=(1, 1, None)
       )

       # Warpgroup-oriented slicing (128 threads per warpgroup)
       warp_group_idx = cute.arch.make_warp_uniform(
           tidx // num_threads_per_warp_group     # 128
       )
       warp_group_thread_layout = cute.make_layout(
           mma_warp_groups,                        # e.g. 2
           stride=num_threads_per_warp_group,      # 128
       )
       thr_mma = tiled_mma.get_slice(
           warp_group_thread_layout(warp_group_idx)
       )

       # Partition C from global
       tCgC = thr_mma.partition_C(gC_mnl)  # (MMA, MMA_M, MMA_N)

       # Partition A/B from staged SMEM
       tCsA = thr_mma.partition_A(sA)      # (MMA, MMA_M, MMA_K, PIPE)
       tCsB = thr_mma.partition_B(sB)      # (MMA, MMA_N, MMA_K, PIPE)


Pre and Post-Conditions for Partitioning
-----------------------------------------

* The inputs of ``partition_A``, ``partition_B``, and ``partition_C`` should be
  at least rank-2 tensors.
* The output layout is constrained by the selected MMA atom:

  - For A, the output has layout ``(MMA, MMA_M, MMA_K, ...)``.
  - For B, the output has layout ``(MMA, MMA_N, MMA_K, ...)``.
  - For C, the output has layout ``(MMA, MMA_M, MMA_N, ...)``.

* Partitioning reasons about layout, not memory space or element type.
  When ``a_src=OperandSource.RMEM``, the same tiled MMA shape still
  determines the logical A footprint, but A is materialized as a register
  fragment rather than a shared-memory descriptor.


Making Fragments
-----------------

Fragments are the tensors that the WGMMA instruction operates on. For dense
WGMMA:

- **Fragment A**: an SMEM descriptor when ``a_src=OperandSource.SMEM``, or an
  RMEM register fragment when ``a_src=OperandSource.RMEM``.
- **Fragment B**: an SMEM descriptor pointing into staged shared memory buffers.
- **Fragment C (accumulator)**: an RMEM tensor that serves as both the input C
  and output D of ``cute.gemm()``.

WGMMA fragments for A and B are **SMEM descriptors** — the hardware reads
directly from shared memory. There is no explicit SMEM → RMEM copy step for
operands A and B. The accumulator, however, still lives in per-thread
registers (RMEM).

Creating fragment descriptors and accumulator fragments
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Fragment creation has two parts:

**1. A and B fragment descriptors**

``make_fragment_A`` and ``make_fragment_B`` take the MMA-partitioned SMEM
views (``tCsA`` / ``tCsB``) and produce descriptor tensors that the WGMMA
instruction consumes. Each descriptor points to one tile within a pipeline
stage in shared memory.

.. code-block:: python

  # MMA-partitioned SMEM views (see "Partitioning Tensors")
  tCsA = thr_mma.partition_A(sA)   # (MMA, MMA_M, MMA_K, PIPE)
  tCsB = thr_mma.partition_B(sB)   # (MMA, MMA_N, MMA_K, PIPE)

  # SMEM descriptor fragments consumed by cute.gemm()
  tCrA = tiled_mma.make_fragment_A(tCsA)   # (MMA, MMA_M, MMA_K, PIPE)
  tCrB = tiled_mma.make_fragment_B(tCsB)   # (MMA, MMA_N, MMA_K, PIPE)

Continuing the 2-warpgroup example from `Partitioning Tensors`_
(F16 atom = (64, 256, 16), ``tile_shape_mnk = (128, 256, 64)``,
``atom_layout_mnk = (2, 1, 1)``, ``num_stages = 4``):

.. code-block:: text

  tCsA: (MMA, MMA_M=1, MMA_K=4, PIPE=4)
  tCsB: (MMA, MMA_N=1, MMA_K=4, PIPE=4)

  make_fragment_A(tCsA) -> tCrA: (MMA, 1, 4, 4)
  make_fragment_B(tCsB) -> tCrB: (MMA, 1, 4, 4)

  Each element of tCrA/tCrB is an SMEM descriptor — one per
  (MMA_K, PIPE) pair. The hardware reads SMEM directly via the
  descriptor; no explicit SMEM -> RMEM load is needed.

  tCrA per warpgroup (4 pipeline stages, 4 K-blocks each):

                |<-- MMA_K = BK/inst_K = 4 -->|
    stage 0:    +------+------+------+------+
                | k=0  | k=1  | k=2  | k=3  |  inst_M=64 (MMA_M=1)
                +------+------+------+------+
    stage 1:    +------+------+------+------+
                | k=0  | k=1  | k=2  | k=3  |  inst_M=64
                +------+------+------+------+
    stage 2:    +------+------+------+------+
                | k=0  | k=1  | k=2  | k=3  |  inst_M=64
                +------+------+------+------+
    stage 3:    +------+------+------+------+
                | k=0  | k=1  | k=2  | k=3  |  inst_M=64
                +------+------+------+------+

  Similarly for tCrB with shape (MMA, MMA_N=1, MMA_K=4, PIPE=4).

.. note:: WGMMA fragments for A and B are SMEM descriptors — the hardware
  reads SMEM directly, so there is no ``ldmatrix`` retiling step required
  before ``cute.gemm()``.

**When A comes from registers (``OperandSource.RMEM``)**

In fused kernels, the output of one MMA can become the A operand of the
next. The second ``TiledMma`` is created with
``a_src=OperandSource.RMEM``, and ``make_fragment_A`` is **not** used.
Instead:

1. The accumulator's C layout ``(MMA, MMA_M, MMA_N)`` is converted to the
   A layout ``(MMA, MMA_M, MMA_K)`` expected by the second ``TiledMma``.
2. The accumulator values are type-converted and stored into an RMEM tensor
   with the A layout.
3. The resulting RMEM tensor is passed directly to ``cute.gemm()`` as the A
   operand — no SMEM descriptor is involved.

See the Hopper FMHA example (``examples/cute/hopper/kernel/attention/fmha.py``) for the complete pattern.

**2. C fragment (accumulator)**

The accumulator lives in per-thread registers (RMEM). Its shape is derived
from the partitioned C layout. The accumulator starts at zero before the K
loop and is updated in-place by each ``cute.gemm()`` call.

.. code-block:: python

  # Partition C from global (see "Partitioning Tensors")
  tCgC = thr_mma.partition_C(gC_mnl)   # (MMA, MMA_M, MMA_N)

  # Allocate RMEM accumulator with the same shape
  acc_shape = tCgC.shape
  acc = cute.make_rmem_tensor(acc_shape, cutlass.Float32)
  acc.fill(0.0)

For the same running example:

.. code-block:: text

  tCgC: (MMA, MMA_M=1, MMA_N=1)

  make_rmem_tensor(tCgC.shape, Float32) -> acc: (MMA, 1, 1)

  The accumulator stays in RMEM for the entire main loop.
  cute.gemm() reads A/B from SMEM descriptors and accumulates into acc.

  +-----------------------------------+
  |  acc: (MMA, 1, 1) in RMEM         |
  |  64 x 256 elements per warpgroup  |
  |  Float32                          |
  +-----------------------------------+


Creating SMEM layouts for A and B
----------------------------------

The SMEM layouts define how A and B tiles are staged in shared memory,
including swizzling for bank-conflict-free descriptor access. The helper
functions in ``cutlass.utils.hopper_helpers`` handle the details.

**Host side** (``@cute.jit``):

.. code-block:: python

  import cutlass.utils.hopper_helpers as sm90_utils

  # Create SMEM layouts (includes swizzle + staging)
  a_smem_layout = sm90_utils.make_smem_layout_a(
      a_layout,          # LayoutEnum — row-major or col-major
      tile_shape_mnk,    # CTA tile (M, N, K)
      a_dtype,           # element type (e.g. Float16)
      num_stages,        # pipeline depth
  )
  b_smem_layout = sm90_utils.make_smem_layout_b(
      b_layout,
      tile_shape_mnk,
      b_dtype,
      num_stages,
  )
  epi_smem_layout = sm90_utils.make_smem_layout_epi(
      c_dtype,
      c_layout,
      epi_tile,
      epi_stage,
  )

``make_smem_layout_a`` and ``make_smem_layout_b`` are convenience helpers that
build a complete, staged SMEM layout in four steps:

1. **Extract the operand tile shape.** For A the ``(M, K)`` portion of
   ``tile_shape_mnk`` is kept via ``cute.slice_``; for B the ``(N, K)``
   portion.

2. **Determine the major mode.** The major mode (K-major or MN-major) is read
   from the layout enum (``a_layout.is_k_major_a()``). The major-mode
   dimension size is used for swizzle selection.

3. **Select and materialise the swizzle atom.** A heuristic
   (``get_smem_layout_atom``) picks the widest swizzle whose contiguous
   size (in bits) evenly divides the major-mode dimension:

   +------------+-----------------+
   | Swizzle    | Contiguous bits |
   +============+=================+
   | SW128      | 1024 (128 B)    |
   +------------+-----------------+
   | SW64       | 512 (64 B)      |
   +------------+-----------------+
   | SW32       | 256 (32 B)      |
   +------------+-----------------+
   | Interleave | 128 (16 B)      |
   +------------+-----------------+

   ``make_smem_layout_atom`` then combines the chosen swizzle with a compact
   outer layout into a ``ComposedLayout(swizzle, outer)``.

4. **Tile to the operand shape and append the staging dimension.**
   ``cute.tile_to_shape`` broadcasts the atom to the full ``(M_or_N, K)``
   shape with ``num_stages`` appended. The ``order`` argument controls which
   dimension is contiguous: ``(0, 1, 2)`` for K-major (K innermost),
   ``(1, 0, 2)`` for MN-major (MN innermost).

For the running F16 example (``tile_shape_mnk = (128, 256, 64)``,
``num_stages = 4``, K-major A, K-major B):

.. code-block:: text

  A operand (K-major, tile = (M=128, K=64)):
    major_mode_size = 64
    64 * 16 bits = 1024 bits → SW128
    atom = make_smem_layout_atom(K_SW128, Float16)
    tile_to_shape(atom, (128, 64, 4), order=(0,1,2))
    -> a_smem_layout: ComposedLayout with shape (128, 64, 4)

  B operand (K-major, tile = (N=256, K=64)):
    major_mode_size = 64
    64 * 16 bits = 1024 bits → SW128
    atom = make_smem_layout_atom(K_SW128, Float16)
    tile_to_shape(atom, (256, 64, 4), order=(0,1,2))
    -> b_smem_layout: ComposedLayout with shape (256, 64, 4)

**Kernel side** (``@cute.kernel``):

The layout and swizzle are passed to shared-memory allocation. The result
is a ``ComposedLayout`` whose ``.outer`` is the logical layout and ``.inner``
is the swizzle:

.. code-block:: python

  # Based on examples/cute/hopper/kernel/dense_gemm/dense_gemm.py
  sA = storage.sA.get_tensor(
      a_smem_layout_staged.outer, swizzle=a_smem_layout_staged.inner
  )
  sB = storage.sB.get_tensor(
      b_smem_layout_staged.outer, swizzle=b_smem_layout_staged.inner
  )

After allocation:

- ``sA`` has shape ``(BM, BK, PIPE) = (128, 64, 4)``.
- ``sB`` has shape ``(BN, BK, PIPE) = (256, 64, 4)``.

These are the staged SMEM tensors consumed by ``partition_A`` /
``partition_B`` and ``make_fragment_A`` / ``make_fragment_B``
(see `Making Fragments`_).

.. note:: If you need finer control, you can build layout atoms directly with
   ``cute.nvgpu.warpgroup.make_smem_layout_atom(...)`` and compose the final
   SMEM layout manually via ``cute.tile_to_shape``.


Executing the GEMM (Main Loop)
-------------------------------

The main loop iterates over K-tiles. The WGMMA-specific part of each
iteration is the **fence / gemm / commit / wait** sequence:

.. code-block:: python

   acc.fill(0.0)
   tiled_mma.set(cute.nvgpu.warpgroup.Field.ACCUMULATE, True)

   for k_tile in cutlass.range(k_pipe_mmas, k_tile_cnt, 1, unroll=1):
       # ... wait for TMA load (pipeline details in dense_gemm.py) ...

       cute.nvgpu.warpgroup.fence()
       tile_crd = (None, None, None, consumer_read.index)
       cute.gemm(tiled_mma, acc, tCrA[tile_crd], tCrB[tile_crd], acc)
       cute.nvgpu.warpgroup.commit_group()
       cute.nvgpu.warpgroup.wait_group(k_pipe_mmas)

       # ... release buffer & advance pipeline (see dense_gemm.py) ...

   cute.nvgpu.warpgroup.wait_group(0)

Key points:

- ``fence()`` orders prior SMEM writes before WGMMA issue.
- ``commit_group()`` publishes queued WGMMA instructions as a group.
- ``wait_group(n)`` waits until at most ``n`` groups remain in flight.
  ``wait_group(0)`` after the loop drains all work before the epilogue.
- ``Field.ACCUMULATE`` — ``True`` accumulates (``D += A*B``),
  ``False`` overwrites (``D = A*B``). The dense GEMM sets ``True`` and
  zero-fills ``acc`` so the first iteration computes ``0 + A*B``.


Complete Workflow
------------------

Putting it all together, a typical Hopper WGMMA GEMM has this structure.
The MMA-relevant steps are highlighted; see ``dense_gemm.py`` for the full
kernel including TMA, pipeline, and epilogue details.

.. code-block:: python

   import cutlass
   import cutlass.cute as cute
   from cutlass.cute.nvgpu import OperandMajorMode
   import cutlass.cute.nvgpu.warpgroup as warpgroup
   import cutlass.utils.hopper_helpers as sm90_utils

   # --- Host side (@cute.jit) ---

   # 1. MMA op + tiled MMA
   op = warpgroup.MmaF16BF16Op(
       cutlass.Float16, cutlass.Float32, (64, 128, 16),
       warpgroup.OperandSource.SMEM, OperandMajorMode.K, OperandMajorMode.K,
   )
   tiled_mma = cute.make_tiled_mma(op)

   # 2. SMEM layouts
   a_smem_layout = sm90_utils.make_smem_layout_a(a_layout, tile_shape_mnk, a_dtype, num_stages)
   b_smem_layout = sm90_utils.make_smem_layout_b(b_layout, tile_shape_mnk, b_dtype, num_stages)

   # 3. TMA copy atoms + kernel launch (see dense_gemm.py)

.. code-block:: python

   # --- Kernel side (@cute.kernel) ---

   # 4. Allocate SMEM
   smem = cutlass.utils.SmemAllocator()
   storage = smem.allocate(SharedStorage)
   sA = storage.sA.get_tensor(
       a_smem_layout.outer, swizzle=a_smem_layout.inner)   # (BM, BK, PIPE)
   sB = storage.sB.get_tensor(
       b_smem_layout.outer, swizzle=b_smem_layout.inner)   # (BN, BK, PIPE)

   # 5. CTA-tiled global tensors
   gA_mkl = cute.local_tile(mA_mkl, tile_shape_mnk, tile_coord, proj=(1, None, 1))
   gB_nkl = cute.local_tile(mB_nkl, tile_shape_mnk, tile_coord, proj=(None, 1, 1))
   gC_mnl = cute.local_tile(mC_mnl, tile_shape_mnk, tile_coord, proj=(1, 1, None))

   # 6. Warpgroup slice, partition & make fragments
   warp_group_idx = cute.arch.make_warp_uniform(tidx // num_threads_per_warp_group)
   warp_group_thread_layout = cute.make_layout(mma_warp_groups, stride=num_threads_per_warp_group)
   thr_mma = tiled_mma.get_slice(warp_group_thread_layout(warp_group_idx))

   tCsA = thr_mma.partition_A(sA)             # (MMA, MMA_M, MMA_K, PIPE)
   tCsB = thr_mma.partition_B(sB)             # (MMA, MMA_N, MMA_K, PIPE)
   tCrA = tiled_mma.make_fragment_A(tCsA)     # SMEM descriptor
   tCrB = tiled_mma.make_fragment_B(tCsB)     # SMEM descriptor
   tCgC = thr_mma.partition_C(gC_mnl)         # (MMA, MMA_M, MMA_N)
   acc  = cute.make_rmem_tensor(tCgC.shape, acc_dtype)

   # 7. TMA pipeline setup + prefetch (see dense_gemm.py)

   # 8. Main loop — fence / gemm / commit / wait
   acc.fill(0.0)
   tiled_mma.set(cute.nvgpu.warpgroup.Field.ACCUMULATE, True)

   for k_tile in cutlass.range(k_pipe_mmas, k_tile_cnt, 1, unroll=1):
       # ... wait for TMA load ...
       cute.nvgpu.warpgroup.fence()
       tile_crd = (None, None, None, consumer_read.index)
       cute.gemm(tiled_mma, acc, tCrA[tile_crd], tCrB[tile_crd], acc)
       cute.nvgpu.warpgroup.commit_group()
       cute.nvgpu.warpgroup.wait_group(k_pipe_mmas)
       # ... release buffer, advance pipeline ...

   cute.nvgpu.warpgroup.wait_group(0)

   # 9. Epilogue: RMEM → SMEM (stmatrix) → GMEM (TMA store)
   # ... (see dense_gemm.py)


.. Beyond Simple Dense MMAs
.. ------------------------

.. The current Python DSL coverage for warpgroup MMA is centered on the three
.. dense ops above. PTX also defines additional WGMMA instruction families that
.. do **not** yet have DSL op classes. These are tracked in the source at
.. ``cutlass/cute/nvgpu/warpgroup/mma.py`` (marked ``✗`` in the instruction
.. table).

.. **Structured-sparse WGMMA** (``wgmma.mma_async.sp``)

.. 2:4 structured sparsity in operand A: out of every 4 consecutive K-elements,
.. exactly 2 are non-zero. The instruction K is **doubled** relative to the
.. dense counterpart (e.g. ``m64nNk32`` for F16/BF16 vs ``m64nNk16`` dense)
.. because A is stored in compressed form. Supported data types include
.. F16/BF16, TF32, FP8, and INT8.

.. Compared to the dense workflow, a sparse kernel would add:

.. - A **compressed A tensor** storing only the non-zero values (half the
..   K-elements), and a **metadata tensor E** encoding which 2 of 4 positions
..   are non-zero.
.. - Extra SMEM layouts, TMA loads, and allocations for both the compressed A
..   and the metadata E.
.. - A metadata staging step each K-tile (SMEM to the MMA instruction).

.. Once DSL support is added, the same fence/commit/wait workflow described in
.. this guide applies, with the additional metadata operand.

.. **Dense TF32 WGMMA** (``m64nNk8``)

.. TF32 (19-bit truncated FP32) inputs with FP32 accumulator.  The instruction
.. K = 8 is smaller than F16's K = 16, so MMA_K repeat counts are larger for
.. the same BK tile size.  Otherwise the workflow is identical to the dense
.. F16/BF16 path — the same SMEM layout, descriptor, and fence/commit/wait
.. pattern applies.

.. **Dense B1 WGMMA** (``m64nNk256``)

.. 1-bit (binary) inputs with INT32 accumulator. The very large instruction
.. K = 256 means each atom consumes 256 bits along K per operand, resulting in
.. small MMA_K repeat counts. This is a niche instruction for binary neural
.. networks.


See also:

- Dense GEMM example: ``examples/cute/hopper/kernel/dense_gemm/dense_gemm.py``
- Persistent GEMM example: ``examples/cute/hopper/kernel/dense_gemm/dense_gemm_persistent.py``
- FMHA example (RMEM A path): ``examples/cute/hopper/kernel/attention/fmha.py``
- Helper utilities: ``cutlass.utils.hopper_helpers``
