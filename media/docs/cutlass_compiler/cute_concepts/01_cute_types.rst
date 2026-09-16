CuTe Algebra Types
==================

This chapter introduces CuTe's three core building blocks — **Shape**,
**Stride**, and **Layout** — and the CuTe dialect types that represent
them.

At the highest level:

- A **Shape** describes the *extents* of a multidimensional space: how
  many elements there are along each mode, possibly nested into a
  hierarchy of sub-modes.  In the dialect: ``!cute.shape``.
- A **Stride** describes the *step size* the linear index advances by
  when each mode's coordinate advances by one.  It has the same
  hierarchical structure as its shape.  In the dialect: ``!cute.stride``.
- A **Layout** pairs a shape with a stride.  Conceptually, it is the
  function that takes a coordinate within the shape and returns a linear
  index, computed as the inner product of the coordinate with the stride.
  In the dialect: ``!cute.layout``.

Everything else in this chapter — coordinates, hierarchical modes,
static vs dynamic leaves, injectivity, composition — flows from this
trio.  The rest of cute's type and op surface is built on top of these
three concepts.

In this document, we cover:

.. contents::
   :local:
   :depth: 2

---------------------------------------------------------------------------

Shape and Stride
----------------

A ``Shape`` (``!cute.shape``) is a tuple of extents; a ``Stride``
(``!cute.stride``) is a tuple of step sizes.  Each leaf is either a static
integer (plain numbers like ``1``, ``16``, ``128``) or a dynamic integer
written as ``?``.  Both shape and stride may be arbitrarily nested, and
both must have the same hierarchical structure (they must be *congruent*).

.. code-block::

   !cute.shape<"(4,2)">          // flat shape: 4 rows, 2 columns
   !cute.shape<"(2,(2,2))">      // hierarchical: 2 rows, 2×2 column sub-mode
   !cute.stride<"(1,4)">         // column-major strides for a matrix
   !cute.stride<"(2,1)">         // row-major strides for a matrix
   !cute.stride<"(4,(2,1))">     // strides matching the hierarchical shape above

Constructing shapes and strides
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Use ``cute.make_shape`` and ``cute.make_stride`` to build values at runtime.
Fully static values need no operands and are equivalent to ``cute.static``:

.. code-block::

   // static shape — no operands
   %s = cute.make_shape() : () -> !cute.shape<"(128,64)">

   // dynamic extent
   %s = cute.make_shape(%m) : (i32) -> !cute.shape<"(?,64)">

   // both extents dynamic
   %s = cute.make_shape(%m, %n) : (i32, i32) -> !cute.shape<"(?,?)">

   // static stride — no operands
   %d = cute.make_stride() : () -> !cute.stride<"(1,4)">

   // dynamic stride
   %d = cute.make_stride(%s) : (i32) -> !cute.stride<"?">

   // dynamic scale of a basis element
   %d = cute.make_stride(%s) : (i32) -> !cute.stride<"?@0">

---------------------------------------------------------------------------

Int tuples
----------

``!cute.int_tuple`` is the underlying integer-tuple type that shape,
stride, and coord all wrap.  Most ops accept the kind that fits the
semantics (a shape extent, a stride step, a coordinate component), but
some — particularly the arithmetic and predicate ops in
:doc:`05_arithmetic` — work on plain int-tuples
directly.

.. code-block::

   !cute.int_tuple<"(4,3)">          // flat int-tuple
   !cute.int_tuple<"(2,(3,4))">      // hierarchical
   !cute.int_tuple<"?">              // dynamic scalar
   !cute.int_tuple<"(?,?)">          // two dynamic leaves

Use ``cute.make_int_tuple`` to assemble an int-tuple at runtime — the
analogue of ``cute.make_shape`` / ``cute.make_stride``:

.. code-block::

   // static — no operands
   %t = cute.make_int_tuple() : () -> !cute.int_tuple<"(4,3)">

   // single dynamic leaf
   %t = cute.make_int_tuple(%n) : (i32) -> !cute.int_tuple<"?">

   // two dynamic leaves
   %t = cute.make_int_tuple(%m, %n) : (i32, i32) -> !cute.int_tuple<"(?,?)">

---------------------------------------------------------------------------

Layout
------

A *layout* is CuTe's core abstraction: a function that maps coordinates
to linear indices.  Layouts present a common interface to multidimensional
array access that abstracts away how elements are organised in memory.
A row-major and a column-major MxN layout can be treated identically in
software; only the layout changes.

CuTe also provides an algebra of layouts: they can be combined, sliced, and
tiled to express sophisticated partitioning of data over threads.

A ``Layout`` (``!cute.layout``) is a ``(Shape, Stride)`` pair that maps any
coordinate within the Shape to a linear index via the inner product with the
Stride.

.. code-block::

   !cute.layout<"8:1">                         // rank-1 contiguous vector
   !cute.layout<"8:2">                         // rank-1 strided vector
   !cute.layout<"(4,2):(1,4)">                 // 4×2 column-major
   !cute.layout<"(4,2):(2,1)">                 // 4×2 row-major
   !cute.layout<"(2,(2,2)):(4,(2,1))">         // 4×2 hierarchical column mode
   !cute.layout<"((2,3),(4,5)):((1,2),(3,4))"> // nested shape and stride
   !cute.layout<"(?,64):(1,?)">                // dynamic shape and stride

Shape-only strings are valid; compact (column-major) strides are inferred:

.. code-block::

   !cute.layout<"(4,2)">   // same as !cute.layout<"(4,2):(1,4)">

A layout is *static* only when every shape and stride leaf is a static
integer; otherwise it is *dynamic*.

Constructing layouts
~~~~~~~~~~~~~~~~~~~~

Use ``cute.make_layout`` to assemble a layout from a ``!cute.shape`` and a
``!cute.stride`` operand.  Both operands are required and must exactly
match the shape and stride components of the result type:

.. code-block::

   %s = cute.make_shape(%m)  : (i32) -> !cute.shape<"(?,2)">
   %d = cute.make_stride(%n) : (i32) -> !cute.stride<"(?,4)">
   %l = cute.make_layout(%s, %d)
          : (!cute.shape<"(?,2)">, !cute.stride<"(?,4)">)
         -> !cute.layout<"(?,2):(?,4)">

Fully static layouts are materialised as compile-time constants with
``cute.static``:

.. code-block::

   %l = cute.static : !cute.layout<"(4,2):(1,4)">

Mapping examples
~~~~~~~~~~~~~~~~

The layout function produces an index as the inner product of the natural
coordinate with the stride.

**Rank-1 contiguous vector** ``!cute.layout<"8:1">``::

   Coord:  0  1  2  3  4  5  6  7
   Index:  0  1  2  3  4  5  6  7

**Rank-1 strided vector** ``!cute.layout<"8:2">``::

   Coord:  0   1   2   3   4   5   6   7
   Index:  0   2   4   6   8  10  12  14

**4×2 column-major** ``!cute.layout<"(4,2):(1,4)">``::

        col  0   1
   row 0  |  0   4
   row 1  |  1   5
   row 2  |  2   6
   row 3  |  3   7

**4×2 row-major** ``!cute.layout<"(4,2):(2,1)">``::

        col  0   1
   row 0  |  0   1
   row 1  |  2   3
   row 2  |  4   5
   row 3  |  6   7

**Hierarchical column mode** ``!cute.layout<"(2,(2,2)):(4,(2,1))">``::

        col  0   1   2   3
   row 0  |  0   2   1   3
   row 1  |  4   6   5   7

The column-major and hierarchical-column-mode examples are both logically
4×2 and can be indexed with the same 2-D coordinates — only the mapping
differs.

Coordinates
~~~~~~~~~~~

Every layout accepts multiple equivalent coordinate forms:

- **1-D integer** — iterates the domain in colexicographic (column-major)
  order regardless of the layout's shape hierarchy.
- **R-D tuple** — one integer per top-level mode.
- **Natural (h-D) tuple** — congruent to the shape; one integer per leaf.

All three forms are equivalent; the 1-D integer ``i`` corresponds to the
``i``-th colexicographic enumeration of the R-D coordinates.

In the dialect, a coordinate is a value of type ``!cute.coord``.  The
type's string follows the same paren-tuple notation as a shape, plus a
special wildcard ``_`` that selects all elements of a mode (used for
slicing):

.. code-block::

   !cute.coord<"(1,2)">    // rank-2 coordinate
   !cute.coord<"(1,_)">    // fix first mode, select all of second

Use ``cute.make_coord`` to build a coordinate at runtime.  Underscore
slots and static values need no operand; each ``?`` slot requires one
``i32`` operand, in left-to-right order.  Fully static coordinates are
materialised with ``cute.static``:

.. code-block::

   %c = cute.make_coord(%i, %j) : (i32, i32) -> !cute.coord<"(?,?)">
   %c = cute.make_coord(%i)     : (i32)       -> !cute.coord<"(?,_)">
   %c = cute.static            : !cute.coord<"(1,2)">

For example, ``!cute.layout<"(3,(2,3)):(3,(12,1))">`` accepts:

.. list-table::
   :header-rows: 1
   :widths: 15 20 25 20

   * - 1-D
     - 2-D
     - Natural
     - Index
   * - ``0``
     - ``(0,0)``
     - ``(0,(0,0))``
     - ``0``
   * - ``3``
     - ``(0,1)``
     - ``(0,(1,0))``
     - ``12``
   * - ``9``
     - ``(0,3)``
     - ``(0,(1,1))``
     - ``13``
   * - ``16``
     - ``(1,5)``
     - ``(1,(1,2))``
     - ``17``

---------------------------------------------------------------------------

Static vs Dynamic Layouts
--------------------------

A layout is **static** when all shape and stride values are known at compile
time.  The compiler can then fold all index arithmetic at compile time.

A layout is **dynamic** when one or more values carry ``?``.  Indices are
computed at runtime.

.. code-block::

   !cute.layout<"(128,64):(1,128)">   // fully static: all arithmetic folds
   !cute.layout<"(?,64):(1,?)">       // dynamic: computed at runtime

---------------------------------------------------------------------------

Scaled-basis strides
--------------------

So far every stride element has been a plain integer that advances the
linear index by a fixed amount.  Sometimes a stride needs to express a
walk along a *named mode* of an outer coordinate space rather than along
a single linear axis.  Cute writes these as **scaled-basis strides**.

A stride element written as ``V@M`` denotes "value ``V`` times the basis
vector for mode ``M``."  Chained indices ``V@Mn@...@M0`` address a
nested mode:

.. code-block::

   !cute.stride<"1@0">       // 1 × e₀ (basis vector for mode 0)
   !cute.stride<"4@1">       // 4 × e₁
   !cute.stride<"1@1@0">     // 1 × E<0,1>  (nested mode 0 inside mode 1)

   !cute.stride<"(1@0,1@1)"> // rank-2 stride in two distinct basis modes

How the mapping changes
~~~~~~~~~~~~~~~~~~~~~~~

A plain-integer stride collapses every coordinate down to a single
scalar linear index.  A scaled-basis stride does **not** — each mode of
the input coordinate is routed to a *different* basis of an outer
coordinate space, and the result is itself a (possibly multi-mode)
coordinate.

For example, take a 2-D layout with shape ``(4,2)`` and the scaled-basis
stride ``(1@0, 1@1)``:

.. code-block:: text

   !cute.layout<"(4,2):(1@0,1@1)">

   Input coord (i, j)  →  i·e₀ + j·e₁  =  (i, j)

   (0,0) →  (0, 0)        (0,1) →  (0, 1)
   (1,0) →  (1, 0)        (1,1) →  (1, 1)
   (2,0) →  (2, 0)        (2,1) →  (2, 1)
   (3,0) →  (3, 0)        (3,1) →  (3, 1)

Now scale the first mode by 2 (``(2@0, 1@1)``):

.. code-block:: text

   !cute.layout<"(4,2):(2@0,1@1)">

   Input coord (i, j)  →  2i·e₀ + j·e₁  =  (2i, j)

   (0,0) →  (0, 0)        (0,1) →  (0, 1)
   (1,0) →  (2, 0)        (1,1) →  (2, 1)
   (2,0) →  (4, 0)        (2,1) →  (4, 1)
   (3,0) →  (6, 0)        (3,1) →  (6, 1)

The result is *not* a flat integer — it is a coordinate in a
two-mode space whose components ``e₀`` and ``e₁`` stay separated.
Compare this with the plain-integer stride case ``(1, 4)`` for the same
shape ``(4,2)``, where ``(i, j) → i + 4j`` collapses both modes onto a
single linear axis.

Scaled-basis strides show up most often as the *output* of layout-algebra
ops; you don't usually write them by hand.

---------------------------------------------------------------------------

Other Types
-----------

The CuTe dialect defines several additional types that extend the basic
layout.

Tile
~~~~

A ``Tile`` (``!cute.tile``) is a sequence of layouts and wildcards in
``[…;…]`` notation, used to describe slicing patterns across mode
hierarchies:

.. code-block::

   !cute.tile<"[(4,2):(1,4);_]">             // slice first mode; pass second through
   !cute.tile<"[(2,3):(1,2);(4,5):(1,4)]">   // two independent slices

Use ``cute.make_tile`` to build a tile at runtime.  Operands fill the
``?`` leaves across all constituent layout slots, left-to-right.
Underscore slots and static layouts need no operand:

.. code-block::

   // fully static — no operands
   %t = cute.static : !cute.tile<"[(2,3):(1,2)]">

   // one dynamic layout: shape-? and stride-? each need one operand
   %t = cute.make_tile(%m, %n) : (i32, i32) -> !cute.tile<"[(?,3):(1,?)]">

   // dynamic layout + underscore (underscore contributes no leaves)
   %t = cute.make_tile(%m, %n) : (i32, i32) -> !cute.tile<"[(?,3):(1,?);_]">

ComposedLayout
~~~~~~~~~~~~~~

Composed layouts exist for the cases where a plain ``!cute.layout``
isn't expressive enough — typically because the access pattern
involves a swizzle or an outer indirection that cannot collapse into a
single shape/stride pair.

A ``ComposedLayout`` (``!cute.composed_layout``) is an outer mapping
``A`` composed with an inner layout ``B`` via an offset:
``A ∘ offset ∘ B``.  A coordinate ``c`` in the domain of ``B`` maps to
``A(offset + B(c))``.  ``A`` may be a layout or a swizzle; when ``A``
is a swizzle the result is sometimes called a *swizzled layout*. The
outer mapping ``A`` adds a level of indirection that the rest of the
algebra simply applies through to ``B`` rather than trying to fold
into a single affine layout.

.. code-block::

   !cute.composed_layout<"(4,8):(1,4) o 0 o (2,3):(1,2)">
   !cute.composed_layout<"S<3,5,4> o 0 o (8,4):(1,8)">

Use ``cute.make_composed_layout`` to assemble a composed layout from
three pre-built operands — inner (layout or swizzle), offset
(int_tuple), and outer (layout).  The result type is inferred from the
operand types:

.. code-block::

   %a   = cute.static : !cute.layout<"(4,5):(1,4)">
   %off = cute.static : !cute.int_tuple<"2">
   %b   = cute.static : !cute.layout<"(2,3):(1,2)">
   %cl  = cute.make_composed_layout(%a, %off, %b)
            : (!cute.layout<"(4,5):(1,4)">, !cute.int_tuple<"2">,
               !cute.layout<"(2,3):(1,2)">)
           -> !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">

   // Swizzle A:
   %sw  = cute.static : !cute.swizzle<"S<3,5,4>">
   %cl  = cute.make_composed_layout(%sw, %off, %b)
            : (!cute.swizzle<"S<3,5,4>">, !cute.int_tuple<"0">,
               !cute.layout<"(8,4):(1,8)">)
           -> !cute.composed_layout<"S<3,5,4> o 0 o (8,4):(1,8)">

Swizzle
~~~~~~~

A ``Swizzle`` (``!cute.swizzle``) rearranges the bits of an integer
address so that nearby logical offsets land in different shared-memory
banks, eliminating bank conflicts during MMA fragments and similar
access patterns. The parameters ``S<num_bits, num_base, num_shift>``
specify the bit positions involved.

For a given input address ``x``, applying a swizzle:

1. selects an ``num_bits``-wide field from ``x``,
2. shifts that field by ``num_shift`` positions (right when
   ``num_shift`` is positive, left when negative),
3. XORs the shifted bits back into ``x`` in another
   ``num_bits``-wide field offset by ``num_base``.

The rest of ``x`` is untouched. The swizzle ``S<0, …, …>`` is the
identity. Swizzles are always fully static and are materialised with
``cute.static``:

.. code-block::

   !cute.swizzle<"S<3,5,4>">
   !cute.swizzle<"S<0,4,3>">   // identity swizzle (num_bits == 0)

   %sw = cute.static : !cute.swizzle<"S<3,5,4>">


Layouts as Functions: Injective, Surjective, Bijective
-------------------------------------------------------

.. note::

   This is an advanced topic.  You can skip it and come back later — it
   is **not** required to read or write CuTe IR, or to use the layout
   algebra.  The properties below show up only as preconditions and
   postconditions on a handful of ops (``cute.left_inverse``,
   ``cute.right_inverse``, ``cute.complement``); the rest of the dialect
   does not depend on them.

Because a layout *is* a function from coordinates to linear indices,
the standard function-theoretic properties apply.  CuTe (and the
CuTe IR ops that wrap it) leans on these properties heavily: several
operations require the input to be **injective**, others state their
postcondition in terms of **surjectivity**, and the most well-behaved
layouts — column-major and row-major — are **bijective** in the
appropriate sense.

Injective
~~~~~~~~~

A layout ``L`` is **injective** when distinct coordinates map to
distinct indices.  Formally: for every pair of coordinates
``c1 ≠ c2``, ``L(c1) ≠ L(c2)``.  No two coordinates collide on the
same index.

Most "real" layouts are injective — every column-major and row-major
layout is, as are any layout whose strides are linearly independent
over the shape.  The simplest non-injective layout is one that
contains a **stride-0 mode**: the mode contributes nothing to the
index, so every coordinate value along that axis maps to the same
place.

.. code-block::

   // Injective — every (i, j) ∈ [0,4)×[0,8) produces a unique index.
   !cute.layout<"(4,8):(1,4)">

   // NOT injective — the stride-0 second mode means
   // L(i, 0) = L(i, 1) = ... = L(i, 7) for every i.
   !cute.layout<"(4,8):(1,0)">

Injectivity matters because it is the **precondition** for the
left-inverse operation:

.. code-block::

   // OK — input is injective.
   %a    = cute.static : !cute.layout<"(2,3):(1,2)">
   %linv = cute.left_inverse(%a)
             : (!cute.layout<"(2,3):(1,2)">) -> !cute.layout<"6:1">

A non-injective layout has no left inverse — there is no way to
recover a unique coordinate from an index that multiple coordinates
share. See also :doc:`02_layout_algebra`.

Surjective
~~~~~~~~~~

A layout ``L`` is **surjective onto an index range** ``[0, M)`` when
every index in ``[0, M)`` is hit by at least one coordinate.
Equivalently: ``L`` reaches every element of the range.

Most non-trivial layouts are *not* surjective onto their cosize —
they walk only a subset of the codomain.  For example,
``(2,2):(4,1)`` has cosize 5 but only hits
indices ``{0, 1, 4, 5}`` — the entries ``{2, 3}`` are skipped.

This is exactly the gap that ``cute.complement`` fills.  Given a
layout ``L`` and a target cosize ``M``, ``cute.complement`` produces a
layout ``L*`` such that the **pair** ``(L, L*)`` covers a strictly
larger fraction of ``[0, M)`` than ``L`` alone — increasing
surjectivity onto the target range.

.. code-block::

   %l        = cute.static : !cute.layout<"(2,2):(4,1)">
   %cotarget = cute.static : !cute.shape<"24">

   // L* maps to the indices L misses inside the [0, 24) target.
   %lstar = cute.complement(%l, %cotarget)
              : (!cute.layout<"(2,2):(4,1)">, !cute.shape<"24">)
             -> !cute.layout<"(2,3):(2,8)">

In particular, this is *not* a guarantee of full surjectivity —
``(L, L*)`` may still miss elements depending on the input's
stride structure — but it always reaches **more** of ``[0, M)`` than
``L`` alone.

Bijective
~~~~~~~~~

A layout ``L`` is **bijective onto** ``[0, size(L))`` when it is both
injective *and* surjective onto that range — every coordinate maps to
a unique index, and every index is reached.  The image of ``L`` is
exactly ``[0, size(L))`` with no gaps and no repeats.

Bijective layouts are the most common starting point in practice.
They include:

- **Column-major** layouts like ``(M,N):(1,M)``.
- **Row-major** layouts like ``(M,N):(N,1)``.
- Any **compact** static layout where ``size(L) == cosize(L) + 1``
  (each index in ``[0, size(L))`` is hit exactly once).

.. code-block::

   // Bijective: image = [0, 32), every index hit exactly once.
   !cute.layout<"(4,8):(1,4)">
   !cute.layout<"(4,8):(8,1)">

Bijective layouts are well-behaved for both ``cute.left_inverse``
(since they're injective) and ``cute.right_inverse`` (since they're
surjective onto their cosize).

Congruent
~~~~~~~~~

Two tuples are **congruent** when they have the **same hierarchical
structure** — same rank at every nesting level, with congruent
sub-tuples at corresponding positions.  A shape and a stride that
together form a layout must be congruent: the layout's shape decides
where the parentheses go, and the stride has to follow the same
nesting so each shape leaf has a matching stride leaf.

.. code-block::

   // Congruent: both rank-2, no nesting.
   !cute.shape<"(4,2)">         !cute.stride<"(1,4)">

   // Congruent: matching (2, (2,2)) hierarchy.
   !cute.shape<"(2,(2,2))">     !cute.stride<"(4,(2,1))">

   // NOT congruent: shape is hierarchical, stride is flat.
   !cute.shape<"(2,(2,2))">     !cute.stride<"(4,2,1)">

Most CuTe ops that take two tuple-like operands (``cute.tuple_add``,
``cute.tuple_sub``, ``cute.crd2idx``, etc.) require their operands to
be congruent — otherwise there's no per-leaf correspondence to walk.

Weakly congruent
~~~~~~~~~~~~~~~~

**Weakly congruent** relaxes congruence: one side can have *less*
hierarchy than the other, as long as the deeper side could be folded
flat to match.  A scalar is weakly congruent with any tuple; a flat
``(N)`` is weakly congruent with any rank-1 hierarchy that has total
size ``N``.

.. code-block::

   // Weakly congruent: scalar matches the whole tuple.
   !cute.int_tuple<"6">         !cute.int_tuple<"(2,3)">

   // Weakly congruent: rank-1 matches a hierarchical rank-1 of the same size.
   !cute.shape<"6">             !cute.shape<"(2,3)">

   // NOT weakly congruent: different rank at the top level.
   !cute.shape<"(2,3)">         !cute.shape<"(2,3,4)">

Ops that promote a coarser operand to match a finer one
(``cute.composition`` with a shape rhs, ``cute.complement`` with a
shape cotarget, ``cute.coalesce`` with a profile) accept weakly
congruent operands — the coarser side is *broadcast* to align with
the finer side rather than requiring exact match.

---------------------------------------------------------------------------

Summary
-------

**The three core types.**

- ``!cute.shape`` and ``!cute.stride`` are nested integer tuples with
  matching hierarchical structure (they must be *congruent*).
- ``!cute.layout`` is the ``(Shape, Stride)`` pair: a function from
  coordinates to linear indices, computed as the inner product of the
  coordinate with the stride.  Hierarchical nesting expresses
  multi-mode access patterns beyond plain row-major and column-major.

**Static vs dynamic.**

- Every leaf is either a static integer (``1``, ``16``, ``128``) or
  the dynamic marker ``?``.  A layout is *static* iff every leaf is
  static; otherwise it is *dynamic* and the missing values are
  supplied at runtime.

**Construction.**

- Fully-static values: ``cute.static : !cute.<type><"...">``.
- Runtime-dynamic values: ``cute.make_shape`` / ``cute.make_stride`` /
  ``cute.make_coord`` consume one ``i32`` per ``?`` slot, and
  ``cute.make_layout(shape, stride)`` combines them.
  ``cute.make_layout`` requires **both** operands.

**Coordinates.**

- ``!cute.coord`` is the multidimensional coordinate type.  Every
  layout accepts 1-D, R-D, and natural h-D coordinate forms; they are
  equivalent via colexicographic enumeration.  The wildcard ``_`` in a
  coord marks axes to slice along or keep (used by ``cute.slice`` /
  ``cute.dice``).

**Scaled-basis strides.**

- A stride leaf ``V@M`` walks along basis mode ``M`` of an outer
  coordinate space instead of collapsing onto a linear index.  These
  appear in advanced layout-algebra outputs and inside
  ``!cute.composed_layout``; you rarely write them by hand.

**Other types layered on layouts.**

- ``!cute.tile`` — a sequence of layouts and ``_`` wildcards for
  per-axis slicing.
- ``!cute.composed_layout`` — an outer mapping (layout or swizzle)
  composed with an inner layout via an offset (``A ∘ offset ∘ B``).
- ``!cute.swizzle`` — a static bit-manipulation function
  ``S<num_bits, num_base, num_shift>`` used to rearrange
  shared-memory bank addresses.

**Layouts as functions.**

================== ================================================ =================================================================================
Property            What it means                                    When CuTe leans on it
================== ================================================ =================================================================================
Injective           ``c1 ≠ c2 ⇒ L(c1) ≠ L(c2)``                      Precondition of ``cute.left_inverse``.
Surjective onto M   Every ``i ∈ [0, M)`` is reached                  Output goal of ``cute.complement``.
Bijective onto M    Injective + surjective onto ``[0, M)``           The "ideal" property for tensor remaps.
Congruent           Same hierarchy at every nesting level            Required for shape/stride pairing, ``tuple_add`` / ``tuple_sub``, ``crd2idx``.
Weakly congruent    One side may have less hierarchy than the other  Allowed for shape-as-rhs in composition / complement / coalesce-profile.
================== ================================================ =================================================================================
