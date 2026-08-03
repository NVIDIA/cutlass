Core Layout Algebra Ops
=======================

This page covers the layout-algebra ops that combine, simplify, and
re-index layouts.  See :doc:`products_and_divides`
for the ops that *replicate* or *split* a layout against a tile.

.. contents::
   :local:
   :depth: 2

---------------------------------------------------------------------------

Coalesce
--------

``cute.coalesce`` is the "simplify" operation on a layout.  It returns a
layout that is functionally equivalent to its input (same map from
1-D integer index to linear offset), but with the smallest possible
number of modes.  The input and the result have the same ``size``.

.. code-block::

   %a = cute.static : !cute.layout<"(2,(1,6)):(1,(6,2))">
   %r = cute.coalesce(%a)
          : (!cute.layout<"(2,(1,6)):(1,(6,2))">)
         -> !cute.layout<"12:1">

The result ``12:1`` is a rank-1, depth-1 layout that is equivalent to
the original 2-D, depth-2 input as a function from integers to
integers — but materially simpler.

The rules are local: for every adjacent pair ``s0:d0 ++ s1:d1`` of
flattened modes,

1. drop modes with size 1,
2. fuse a contiguous pair when ``d1 == s0 * d0`` (the second mode
   extends the first into a single contiguous run), and
3. otherwise keep them separate.

**Where this comes up.**  ``coalesce`` is the simplification step behind
almost every layout-algebra pipeline. It is infrequently used directly in
kernel code.

By-mode coalesce
~~~~~~~~~~~~~~~~

A ``profile`` operand (a ``!cute.coord``) controls the profile of the final
result, and the modes that coalesce reaches: modes corresponding to integers in the profile are
coalesced, modes corresponding to tuples in the profile are coalesced
**recursively**.

.. code-block::

   %a   = cute.static : !cute.layout<"(3,(4,5)):(8,(1,4))">
   %p   = cute.static : !cute.coord<"(1,1)">
   %r   = cute.coalesce(%a, %p)
            : (!cute.layout<"(3,(4,5)):(8,(1,4))">,
               !cute.coord<"(1,1)">)
           -> !cute.layout<"(3,20):(8,1)">

Here the result stays rank-2 — coalesce only fired inside each mode,
fusing the inner ``(4,5):(1,4)`` into a single ``20:1``.

---------------------------------------------------------------------------

Composition
-----------

A layout is a function from coordinates to linear indices, so the
composition of two layouts is just **mathematical function
composition**: ``cute.composition`` composes two layouts ``A`` and
``B`` to produce ``R := A ∘ B``, the function such that
``R(c) == A(B(c))`` — apply ``B`` first, then ``A`` — just like
``(f ∘ g)(x) = f(g(x))``. The operation lies at the heart of nearly
every higher-level operation in the algebra: slicing, products,
divides, and complement all reduce to compositions in their
definitions.

.. code-block::

   %a = cute.static : !cute.layout<"(6,2):(8,2)">
   %b = cute.static : !cute.layout<"(4,3):(3,1)">
   %r = cute.composition(%a, %b)
          : (!cute.layout<"(6,2):(8,2)">, !cute.layout<"(4,3):(3,1)">)
         -> !cute.layout<"((2,2),3):((24,2),8)">

Reading the result: composition walks each coordinate of ``B`` and
looks the resulting index up in ``A``.  Here ``B`` has size 12 and
``A``'s mode-0 size is 6, so ``B``'s first axis (size 4) is split
into ``(2,2)`` to align with ``A``'s mode boundary — that's why the
result's first top-level mode is ``(2,2)`` instead of ``4``.  The
strides ``((24,2),8)`` are chosen so that ``R(c) == A(B(c))`` for
every coordinate ``c``.  For the first few values:

::

   R(0) = A(B(0)) = A(0) = 0
   R(1) = A(B(1)) = A(3) = 24
   R(2) = A(B(2)) = A(6) = 2
   R(3) = A(B(3)) = A(9) = 26
   ...

The rhs of a composition may be a layout, a tile, or a shape.  Each
form has its own semantics:

- **layout** — full functional composition (the example above).

- **shape** — equivalent to composing with the column-major layout
  built from that shape (``A ∘ make_layout(shape)``).  The result
  takes its shape from the rhs and inherits ``A``'s strides restricted
  to that shape.

  .. code-block::

     %a = cute.static : !cute.layout<"(4,8):(1,4)">
     %b = cute.static : !cute.shape<"(2,4)">
     %r = cute.composition(%a, %b)
            : (!cute.layout<"(4,8):(1,4)">, !cute.shape<"(2,4)">)
           -> !cute.layout<"(2,4):(1,4)">

- **tile** — decomposes the composition mode-by-mode: ``A`` is composed
  with each layout slot of the tile independently.  Each tile slot is
  itself a layout, so its mode hierarchy carries through into the
  result.  This is the workhorse pattern that enables hierarchical
  tiling.

  .. code-block::

     %a = cute.static : !cute.layout<"(6,4):(4,1)">
     %t = cute.static : !cute.tile<"[(2):(1);(2):(1)]">
     %r = cute.composition(%a, %t)
            : (!cute.layout<"(6,4):(4,1)">, !cute.tile<"[(2):(1);(2):(1)]">)
           -> !cute.layout<"((2),(2)):((4),(1))">

  Each tile slot ``(2):(1)`` is a rank-1 layout, so the result reads
  as ``((2),(2))`` rather than the flat ``(2,2)`` you'd get if the rhs
  were a plain ``(2,2)`` shape.

**Where this comes up.** Composition is the foundation of slice,
product, and divide; nearly every higher-level layout-algebra op is
defined in terms of it. Two ways it shows up directly:

- **Restructuring a layout.** Composing a flat layout with one that
  has the target shape and stride reshapes the access pattern without
  changing the underlying function — e.g. turning ``8:1`` into the
  hierarchical ``(4,2):(1,4)``.
- **Binding an atom layout.** In atom partitioning, composition is the
  step that binds a hardware-specific atom layout to a logical
  thread / value hierarchy, producing the per-thread per-value
  addressing the rest of the kernel indexes with.

---------------------------------------------------------------------------

Complement
----------

For a layout ``A`` and a target cosize ``M``, ``cute.complement``
returns the layout ``A*`` such that appending ``A*`` to ``A``
(via ``cute.append_to_rank``) covers exactly the range ``[0, M)``
with no overlap.  Informally, ``A*`` is the "filler" that, alongside
``A``, walks across the codomain.

.. code-block::

   %a        = cute.static : !cute.layout<"(2,2):(4,1)">
   %cotarget = cute.static : !cute.shape<"(24)">
   %c        = cute.complement(%a, %cotarget)
                 : (!cute.layout<"(2,2):(4,1)">, !cute.shape<"(24)">)
                -> !cute.layout<"(2,3):(2,8)">

The ``cotarget`` operand is optional; the single-operand form finds the
minimal complement layout that covers the holes in the codomain of the input:

.. code-block::

   %c = cute.complement(%a)
          : (!cute.layout<"(2,2):(4,1)">) -> !cute.layout<"(2,1):(2,8)">

Complement is the engine that powers the **product** family — each
product op computes ``A* = complement(A, size(A) * cosize(B))`` and
composes it with ``B``.  See
:doc:`Products and Divides <products_and_divides>`.

**Where this comes up.** Outside of products, ``complement`` rarely
appears directly in kernel code — it is the internal step that builds
the "rest" mode that, together with the input layout, walks the
codomain. Reach for it directly when you need to construct a filler
layout that fits a specific cosize target.

---------------------------------------------------------------------------

Inverses
--------

A layout :math:`A` is a function from 1-D integer coordinates to
linear offsets.  Its **right inverse** :math:`A^{-1}_R` is the layout
that recovers a coordinate from an offset:

.. math::

   A(A^{-1}_R(j)) = j \quad \text{for every } j \text{ in the relevant range.}

Its **left inverse** is the dual:

.. math::

   A^{-1}_L(A(c)) = c.

Equivalently, composition with the right inverse rebuilds the identity
over the inverse's shape:

.. math::

   A \circ A^{-1}_R = \operatorname{identity}(\operatorname{shape}(A^{-1}_R)).

The right inverse is not always unique — a layout with stride-zero
modes has many layouts satisfying the equation above. The form
returned by ``cute.right_inverse`` is canonical but not the only
solution.

.. code-block::

   %a    = cute.static : !cute.layout<"(2,4,6):(4,1,8)">
   %rinv = cute.right_inverse(%a)
             : (!cute.layout<"(2,4,6):(4,1,8)">)
            -> !cute.layout<"(4,2,6):(2,1,8)">

   %linv = cute.left_inverse(%a)
             : (!cute.layout<"(2,4,6):(4,1,8)">)
            -> !cute.layout<"(4,2,6):(2,1,8)">

**Worked example.** Take the simpler layout ``A = (2,4):(4,1)``;
both inverses collapse to ``A⁻¹ = (4,2):(2,1)``. Walking each layout
over the 1-D coordinates ``0..7`` gives:

.. code-block:: text

   c        : 0  1  2  3  4  5  6  7
   A(c)     : 0  4  1  5  2  6  3  7      ← (2,4):(4,1)
   A⁻¹(c)   : 0  2  4  6  1  3  5  7      ← (4,2):(2,1)

The right-inverse identity ``A(A⁻¹_R(j)) = j`` reads off by
composing the two rows:

.. code-block:: text

   j               : 0  1  2  3  4  5  6  7
   A⁻¹_R(j)        : 0  2  4  6  1  3  5  7
   A(A⁻¹_R(j))     : 0  1  2  3  4  5  6  7      ← identity

The left-inverse identity ``A⁻¹_L(A(c)) = c`` reads off the other
way:

.. code-block:: text

   c               : 0  1  2  3  4  5  6  7
   A(c)            : 0  4  1  5  2  6  3  7
   A⁻¹_L(A(c))     : 0  1  2  3  4  5  6  7      ← identity

Inverses are used to convert between different coordinate systems —
for example, to convert from the codomain of a layout back to a
multidimensional coordinate, or to "rotate" the way a tensor is
indexed.

**Where this comes up.** Atom partitioning right-inverts the atom's
thread / value layout to map thread-and-value coordinates back into
source-memory coordinates.

---------------------------------------------------------------------------

Slice and Dice
--------------

``cute.slice`` and ``cute.dice`` are the two halves of layout slicing.
They take a layout and a multidimensional coordinate (the slice
pattern); the difference is which modes survive:

- ``cute.slice`` — keeps modes where the slice pattern is ``_``
  (underscore), drops modes where it is an integer.  The result is the
  sub-layout survived by the slicing pattern.
- ``cute.dice`` — keeps modes where the slice pattern is an integer,
  drops the ``_`` ones.  Returns the layout indexed by the integer
  modes alone. The result is the sub-layout survived by the dicing pattern.

.. code-block::

   %a   = cute.static : !cute.layout<"(2,3,4):(1,2,6)">

   // Slice: keep the underscore modes
   %crd = cute.static : !cute.coord<"(0,_,1)">
   %s   = cute.slice(%a, %crd)
            : !cute.layout<"(2,3,4):(1,2,6)">, !cute.coord<"(0,_,1)">

   // Dice: keep the integer modes
   %d   = cute.dice(%a, %crd)
            : !cute.layout<"(2,3,4):(1,2,6)">, !cute.coord<"(0,_,1)">

A common pattern is to call slice with one coordinate to extract a
column / row / tile of a tensor's layout.

**Where this comes up.** Slicing is the fundamental indexing
operation on a layout — any time you want to pull a sub-layout out of
a bigger one (a column, a row, a 2-D tile, a per-thread fragment), the
recipe is the same: build an ``_``-bearing coordinate that names the
axes you want to keep and feed it to ``cute.slice``. ``cute.dice``
covers the dual case where you want the axes you fixed instead.

---------------------------------------------------------------------------

Group Modes
-----------

``cute.group_modes`` reshapes a layout by **bracketing a contiguous
range of its top-level modes into a sub-tuple**.  The two attributes
``<begin, end>`` name the half-open mode range to group; modes outside
that range are passed through unchanged.

.. code-block::

   %a = cute.static : !cute.layout<"(4,5,6):(1,4,20)">

   // Group modes [0, 2) — wrap the first two into a sub-tuple
   %g0 = cute.group_modes<0, 2> (%a)
           : (!cute.layout<"(4,5,6):(1,4,20)">)
          -> !cute.layout<"((4,5),6):((1,4),20)">

   // Group modes [1, 3) — wrap the last two into a sub-tuple
   %g1 = cute.group_modes<1, 3> (%a)
           : (!cute.layout<"(4,5,6):(1,4,20)">)
          -> !cute.layout<"(4,(5,6)):(1,(4,20))">

   // Group all three into a single nested mode
   %g2 = cute.group_modes<0, 3> (%a)
           : (!cute.layout<"(4,5,6):(1,4,20)">)
          -> !cute.layout<"((4,5,6)):((1,4,20))">

**Where this comes up.** Reshaping a flat layout into a hierarchy
that a downstream ``compose`` / ``slice`` / ``divide`` consumer
expects, without changing any indices.

---------------------------------------------------------------------------

Recast Layout
-------------

``cute.recast_layout<new_bits, old_bits>`` adjusts a layout's stride-1
mode and non-unit strides when the underlying element type bit-width
changes — e.g. lowering an ``f32`` layout to ``f8`` (4× more elements
per stride-1 row) or upcasting ``f8`` to ``f32`` (4× fewer).

The operation selects a case based on the divisibility of ``new`` and
``old``:

- **Identity** (``new == old``): no transformation; the result equals the
  input.

- **Upcast** (``new % old == 0``, ratio ``R = new / old``): the new element
  is larger, so fewer elements fit in the same memory.  The stride-1 mode's
  extent shrinks by ``R`` and every non-unit stride divides by ``R``.

- **Downcast** (``old % new == 0``, ratio ``R = old / new``): the new element
  is smaller, so more elements are needed.  The stride-1 mode's extent grows
  by ``R`` and all other strides are multiplied by ``R``.

- **General** (neither divides the other evenly): let ``G = gcd(new, old)``,
  ``new' = new / G``, ``old' = old / G``.  The operation is equivalent to
  ``downcast(old', upcast(new', layout))`` — first upcast by ``new'``, then
  downcast by ``old'``.

.. code-block::

   // Upcast x4: new = 32-bit, old = 8-bit → ratio 4.
   // Stride-1 mode shape 32 → 8; non-unit stride 32 → 8.
   %src1 = cute.static : !cute.layout<"(32,4):(1,32)">
   %r1   = cute.recast_layout<32, 8> (%src1)
             : !cute.layout<"(32,4):(1,32)"> -> !cute.layout<"(8,4):(1,8)">

   // Downcast x4: new = 8-bit, old = 32-bit → ratio 4.
   // Stride-1 mode shape 8 → 32; non-unit stride 8 → 32.
   %src2 = cute.static : !cute.layout<"(8,4):(1,8)">
   %r2   = cute.recast_layout<8, 32> (%src2)
             : !cute.layout<"(8,4):(1,8)"> -> !cute.layout<"(32,4):(1,32)">

   // Identity recast (new == old) is a no-op.
   %r3   = cute.recast_layout<32, 32> (%src2)
             : !cute.layout<"(8,4):(1,8)"> -> !cute.layout<"(8,4):(1,8)">

   // General case: new = 4-bit, old = 6-bit, neither divides the other.
   // G = gcd(4, 6) = 2  →  new' = 2, old' = 3.
   // Step 1: upcast(2, (8,4):(1,8))   = (4,4):(1,4)
   // Step 2: downcast(3, (4,4):(1,4)) = (12,4):(1,12)
   %src4 = cute.static : !cute.layout<"(8,4):(1,8)">
   %r4   = cute.recast_layout<4, 6> (%src4)
             : !cute.layout<"(8,4):(1,8)"> -> !cute.layout<"(12,4):(1,12)">

**Where this comes up.** Threading layouts through type-conversion
boundaries — going from a quantized storage layout (e.g. 8-bit) to
the compute-element layout (e.g. 32-bit) without manually recomputing
shape and stride.

---------------------------------------------------------------------------

Summary
-------

The core layout-algebra ops mirror the C++ CuTe algebra one-to-one:

- ``cute.coalesce`` simplifies a layout into the smallest equivalent
  shape/stride.
- ``cute.composition`` is functional composition: ``R = A ∘ B`` such
  that ``R(c) = A(B(c))``.
- ``cute.complement`` produces the disjoint filler ``A*`` whose pair
  with ``A`` covers a target cosize.
- ``cute.right_inverse`` / ``cute.left_inverse`` invert a layout's
  coordinate-to-index mapping.
- ``cute.slice`` / ``cute.dice`` split a layout by an underscore
  coordinate pattern.
- ``cute.group_modes`` brackets a contiguous range of top-level modes
  into a sub-tuple.
- ``cute.recast_layout`` adjusts a layout when the element bit-width
  changes (upcast / downcast).

For the exact operand types, result types, and assembly format of each
op, see the :doc:`dialect reference <../../cute_dialect>`.
