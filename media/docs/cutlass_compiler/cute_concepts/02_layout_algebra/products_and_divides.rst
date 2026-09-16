Products and Divides
====================

The **product** family of operations builds a hierarchical layout by
replicating one layout against another.  The **divide** family is its
dual: it splits an input layout according to a tile.  Together they
form the foundation of CuTe's tiling and partitioning utilities — most
collective-kernel partition routines reduce to a single product or
divide.

.. contents::
   :local:
   :depth: 2

---------------------------------------------------------------------------

Products
--------

The product family replicates one layout (the **input**, conceptually a
"block") across another (the **tiler**). The mental model: treat every
element of the tiler as a copy of the block, and the result describes
where each copy lives in the codomain. Six variants differ only in how
they group the resulting modes:

==================== ===================================================================
Op                    Result grouping for input ``(M,N)`` and tiler ``(TilerM,TilerN)``
==================== ===================================================================
``logical_product``   ``((M,TilerM), (N,TilerN), …)`` — pair per axis
``zipped_product``    ``((M,N), (TilerM,TilerN,…))`` — group input vs tile
``tiled_product``     ``((M,N), TilerM, TilerN, …)`` — input grouped, tile flat
``flat_product``      ``(M, N, TilerM, TilerN, …)`` — everything flat
``blocked_product``   ``((M,TilerM), (N,TilerN), …)`` — input inner, tile outer
``raked_product``     ``((TilerM,M), (TilerN,N), …)`` — pair per axis swapped
==================== ===================================================================

All six share the same underlying construction: the result pairs the
input ``A`` with the layout of where each copy of ``A`` lives in the
codomain, ``A* ∘ B``.

.. code-block::

   %a = cute.static : !cute.layout<"(2,2):(4,1)">
   %b = cute.static : !cute.layout<"6:1">

   %lp = cute.logical_product(%a, %b)
           : (!cute.layout<"(2,2):(4,1)">, !cute.layout<"6:1">)
          -> !cute.layout<"((2,2),(2,3)):((4,1),(2,8))">

The result reads as a rank-2 layout: mode 0 is the original tile (a
4-element 2×2 layout), and mode 1 ``(2,3):(2,8)`` enumerates the 6
disjoint positions in the codomain where copies of the tile live.

The tiler can itself be rank-2 — its shape and stride flow through
into the second mode of the result:

.. code-block::

   %a  = cute.static : !cute.layout<"(2,2):(4,1)">
   %b2 = cute.static : !cute.layout<"(3,2):(2,1)">

   %lp2 = cute.logical_product(%a, %b2)
            : (!cute.layout<"(2,2):(4,1)">, !cute.layout<"(3,2):(2,1)">)
           -> !cute.layout<"((2,2),(3,2)):((4,1),(8,2))">

Same input ``%a`` and same number of copies (6), but the tiler's
rank-2 ``(3,2)`` shape now appears in mode 1 of the result instead of
the flat ``(2,3)`` that the rank-1 ``6:1`` produced.

When to use which variant:

- ``logical_product`` and ``blocked_product`` are the most common
  starting points — they pair input and tile per axis. Each tile
  position holds a contiguous copy of the block.
- ``raked_product`` swaps the per-axis pair order so the blocks are
  *interleaved* with each other rather than laid out contiguously —
  cyclic instead of blocked replication.
- ``flat_product`` is useful when downstream consumers want unnested
  modes.
- ``zipped_product`` / ``tiled_product`` keep the input and tile sides
  separate, which simplifies later partitioning.

**Where this comes up.**

- ``logical_product`` — pair fragment-value counts with value-domain
  layouts when partitioning a copy or MMA atom.
- ``blocked_product`` — build sparse-MMA metadata layouts by blocking
  thread × sparse-index dimensions.
- ``raked_product`` — cyclically interleave threads through values in
  copy atoms for efficient memory-access patterns.
- ``zipped_product`` / ``tiled_product`` / ``flat_product`` — usually
  reached indirectly through ``logical_product`` followed by hand
  unpacking, when a specific mode grouping is needed downstream.

The six variants on the same input + tiler
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Side-by-side, with input ``(3,4):(4,1)`` and tiler ``(2,5):(1,2)``:

.. code-block::

   %a = cute.static : !cute.layout<"(3,4):(4,1)">
   %t = cute.static : !cute.layout<"(2,5):(1,2)">

   // logical_product — pair input and tile per axis
   %lp = cute.logical_product(%a, %t)
           : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(2,5):(1,2)">)
          -> !cute.layout<"((3,4),(2,5)):((4,1),(12,24))">

   // zipped_product — input modes grouped, tile modes grouped
   %zp = cute.zipped_product(%a, %t)
           : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(2,5):(1,2)">)
          -> !cute.layout<"((3,4),(2,5)):((4,1),(12,24))">

   // tiled_product — input grouped, tile flat
   %tp = cute.tiled_product(%a, %t)
           : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(2,5):(1,2)">)
          -> !cute.layout<"((3,4),2,5):((4,1),12,24)">

   // flat_product — everything flat
   %fp = cute.flat_product(%a, %t)
           : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(2,5):(1,2)">)
          -> !cute.layout<"(3,4,2,5):(4,1,12,24)">

   // blocked_product — per-axis pair, input inner, tile outer
   %bp = cute.blocked_product(%a, %t)
           : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(2,5):(1,2)">)
          -> !cute.layout<"((3,2),(4,5)):((4,12),(1,24))">

   // raked_product — per-axis pair, order swapped (tile inner, input outer)
   %rp = cute.raked_product(%a, %t)
           : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(2,5):(1,2)">)
          -> !cute.layout<"((2,3),(5,4)):((12,4),(24,1))">

Tile to shape
~~~~~~~~~~~~~

``cute.tile_to_shape`` is the **shape-driven product variant**: like
the rest of the product family it replicates a block layout, but the
second operand is the *target shape you want to cover* rather than an
explicit tiler layout.  The replication factor along each top-level
mode is computed automatically as
``ceil(target_shape[i] / block_shape[i])`` — non-divisible cases round
up.  The result groups the input axis with its replication count as a
nested mode, matching the per-axis pairing of ``blocked_product``.

When ``rank(input) < rank(target_shape)``, the block is padded on the
inner side with shape-``1`` modes so each target mode has a
counterpart; strict equality is not required.

.. code-block::

   %block  = cute.static : !cute.layout<"(2,2):(1,2)">
   %target = cute.static : !cute.shape<"(8,8)">
   %r      = cute.tile_to_shape(%block, %target)
               : (!cute.layout<"(2,2):(1,2)">, !cute.shape<"(8,8)">)
              -> !cute.layout<"((2,4),(2,4)):((1,4),(2,16))">

An optional ``$order`` operand (a static ``!cute.int_tuple``) selects
the order in which the target-shape modes are tiled. Default is
column-major: the block repeats across mode 0 first, then mode 1, etc.
Passing ``(1,0,2)`` (for example) flips that — the block repeats
across mode 1 first, mode 0 second, mode 2 last.

---------------------------------------------------------------------------

Divides
-------

The divide family is the dual of the product family: it splits an
input layout according to a tile, instead of replicating it.  Each
variant matches a product variant in its mode-grouping convention.

================== ============================================================================================
Op                  Effect
================== ============================================================================================
``logical_divide``  Per-axis pair: ``(M,N,L,…) ⊘ (TileM,TileN)`` → ``((TileM,M/TileM),(TileN,N/TileN), L, …)``
``zipped_divide``   Group: ``(TileM,TileN), (M/TileM,N/TileN, …)``
``tiled_divide``    Input grouped, tile flat
``flat_divide``     All flat
================== ============================================================================================

.. code-block::

   %a = cute.static : !cute.layout<"(6,8):(8,1)">
   %b = cute.static : !cute.shape<"(3,4)">

   %ld = cute.logical_divide(%a, %b)
           : (!cute.layout<"(6,8):(8,1)">, !cute.shape<"(3,4)">)
          -> !cute.layout<"((3,2),(4,2)):((8,24),(1,4))">

The result is interpreted as: mode 0 walks within one tile (``3×4``),
mode 1 walks across tiles (``2×2``).

The second operand can also be a ``!cute.tile`` — a per-axis sequence
of layouts. Each tile slot drives the divide for its corresponding
input mode independently, and the slot's modes stay grouped in the
result instead of being flattened against the input:

.. code-block::

   %a = cute.static : !cute.layout<"(6,8):(8,1)">
   %t = cute.static : !cute.tile<"[(3):(1);(4):(1)]">

   %ld = cute.logical_divide(%a, %t)
           : (!cute.layout<"(6,8):(8,1)">, !cute.tile<"[(3):(1);(4):(1)]">)
          -> !cute.layout<"(((3),2),((4),2)):(((8),24),((1),4))">

Compare with the shape-tiler result above: the within-tile half of
each axis is wrapped (``((3),2)`` vs ``(3,2)``) because the tile slot
``(3):(1)`` is itself a layout — its mode hierarchy carries through.

The second operand can also be a single ``!cute.layout`` — in which
case the divide runs a real composition against the tiler's strides
rather than using it as a per-axis identity tile:

.. code-block::

   %a = cute.static : !cute.layout<"(6,8):(8,1)">
   %b = cute.static : !cute.layout<"(3,4):(1,3)">

   %ld = cute.logical_divide(%a, %b)
           : (!cute.layout<"(6,8):(8,1)">, !cute.layout<"(3,4):(1,3)">)
          -> !cute.layout<"((3,(2,2)),4):((8,(24,1)),2)">

Because the tiler's strides ``(1,3)`` are not the column-major
identity, composition mixes them into the result: the within-tile
mode of axis 0 picks up a nested ``(3,(2,2))`` shape, and the
across-tile walk of axis 1 collapses to a single ``4``. Switching
between a shape, a tile, and a layout as the second operand is the
main lever you have for controlling how the result is structured.

The four divide variants differ only in how the result modes are
grouped. Same input ``(6,8):(8,1)`` and tiler shape ``(3,4)``:

.. code-block::

   %a = cute.static : !cute.layout<"(6,8):(8,1)">
   %b = cute.static : !cute.shape<"(3,4)">

   // logical_divide — per-axis pair: ((within, across), (within, across))
   %ld = cute.logical_divide(%a, %b)
           : (!cute.layout<"(6,8):(8,1)">, !cute.shape<"(3,4)">)
          -> !cute.layout<"((3,2),(4,2)):((8,24),(1,4))">

   // zipped_divide — within-tile modes together, across-tile modes together
   %zd = cute.zipped_divide(%a, %b)
           : (!cute.layout<"(6,8):(8,1)">, !cute.shape<"(3,4)">)
          -> !cute.layout<"((3,4),(2,2)):((8,1),(24,4))">

   // tiled_divide — within-tile modes grouped, across-tile modes flat
   %td = cute.tiled_divide(%a, %b)
           : (!cute.layout<"(6,8):(8,1)">, !cute.shape<"(3,4)">)
          -> !cute.layout<"((3,4),2,2):((8,1),24,4)">

   // flat_divide — everything flat
   %fd = cute.flat_divide(%a, %b)
           : (!cute.layout<"(6,8):(8,1)">, !cute.shape<"(3,4)">)
          -> !cute.layout<"(3,4,2,2):(8,1,24,4)">

Every output above describes the same data: each variant just picks a
different grouping of the same modes, which makes downstream
partitioning (slicing, addressing, indexing) more or less natural
depending on what the consumer wants.

Divides are the foundation of CuTe's partitioning utilities — given a
layout describing a tensor and a tile describing how threads index
into it, divide produces the per-thread sub-layout plus the inter-tile
walk in a single op.

**Where this comes up.**

- ``logical_divide`` — decompose ``C`` / ``A`` / ``B`` matrices into
  per-atom blocks; factor TMA instruction granularity from
  per-thread value counts.
- ``zipped_divide`` — separate the per-thread tile from the rest
  modes; the workhorse of copy and MMA partitioning.
- ``tiled_divide`` / ``flat_divide`` — alternative groupings of the
  same partition, chosen by downstream consumers.

---------------------------------------------------------------------------

Summary
-------

The product and divide families are dual: each builds a hierarchical
layout against a tile, one by replication and the other by splitting.

- **Six product variants** (``logical_product``, ``zipped_product``,
  ``tiled_product``, ``flat_product``, ``blocked_product``,
  ``raked_product``) replicate an input layout across a tiler.  They
  differ only in how the resulting modes are grouped — per-axis
  pair, side-by-side, all-flat, contiguous vs interleaved copies.
- **Four divide variants** (``logical_divide``, ``zipped_divide``,
  ``tiled_divide``, ``flat_divide``) split an input layout by a
  tiler.  Same input + tiler ↔ same indices, different mode
  grouping.
- ``cute.tile_to_shape`` is the shape-driven product variant: the
  second operand is the target shape you want to cover, and the
  per-axis replication factor is ``ceil(target / block)``.

For the exact operand types, result types, and assembly format of each
op, see the :doc:`dialect reference <../../cute_dialect>`.
