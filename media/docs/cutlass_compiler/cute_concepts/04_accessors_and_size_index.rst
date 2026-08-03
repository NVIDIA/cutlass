Accessors and Size / Indexing
=============================

This chapter covers two related groups of ops:

- **Accessors** — read individual modes, leaves, or scalar values out of
  CuTe values (layouts, tiles, composed layouts, tuples).  These ops do
  not change semantics; they pull existing structure out into SSA values
  the rest of the IR can use.
- **Size and indexing** — compute scalar quantities (size, cosize,
  product) and convert between coordinates and linear indices.

Both groups are pure (no side effects) and accept any compatible cute
value as input.  For exact operand types, result types, and assembly
formats, see the :doc:`dialect reference <../cute_dialect>`.

.. contents::
   :local:
   :depth: 2

---------------------------------------------------------------------------

Accessors
---------

The accessor ops pull a component out of an existing CuTe value.  They
are the read side of the constructor ops in
:doc:`01_cute_types`.

.. list-table::
   :header-rows: 1
   :widths: 30 70

   * - Op
     - What it does
   * - ``cute.get_shape``
     - Extract the shape from a layout, composed layout, or tile.
   * - ``cute.get_stride``
     - Extract the stride from a layout.
   * - ``cute.composed_get_inner``
     - Extract the inner (``A``) component from a composed layout.
   * - ``cute.composed_get_offset``
     - Extract the offset from a composed layout.
   * - ``cute.composed_get_outer``
     - Extract the outer (``B``) layout from a composed layout.
   * - ``cute.get``
     - Extract a sub-value by hierarchical mode index.
   * - ``cute.select``
     - Build a new value from a chosen subset of top-level modes.
   * - ``cute.get_leaves``
     - Flatten a tuple-like value into one SSA result per leaf.
   * - ``cute.get_scalars``
     - Extract scalar integers (``i32``) from a CuTe value.
   * - ``cute.get_layouts_from_tile``
     - Extract every layout slot from a tile, skipping underscores.

Layout / stride / shape extraction
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

``cute.get_shape`` and ``cute.get_stride`` return the corresponding
component of a layout as a CuTe value of the matching type:

.. code-block::

   %l = cute.static : !cute.layout<"(4,8):(1,4)">

   %s = cute.get_shape(%l)
          : !cute.layout<"(4,8):(1,4)"> -> !cute.shape<"(4,8)">

   %d = cute.get_stride(%l)
          : !cute.layout<"(4,8):(1,4)"> -> !cute.stride<"(1,4)">

``cute.get_shape`` also accepts a composed layout or a tile.  For a
tile, the result is the concatenation of the per-slot shapes.

Composed-layout component extraction
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

A ``!cute.composed_layout`` is internally ``A ∘ offset ∘ B``.  Three
ops pull each component out:

.. code-block::

   %cl = cute.static
           : !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">

   %a   = cute.composed_get_inner(%cl)
            : !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">
           -> !cute.layout<"(4,5):(1,4)">
   %off = cute.composed_get_offset(%cl)
            : !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">
           -> !cute.int_tuple<"2">
   %b   = cute.composed_get_outer(%cl)
            : !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">
           -> !cute.layout<"(2,3):(1,2)">

When ``A`` is a swizzle, ``cute.composed_get_inner`` returns a
``!cute.swizzle`` instead.

Mode extraction: ``cute.get`` and ``cute.select``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

``cute.get`` takes a hierarchical index list (as the ``<[...]>`` attribute)
and returns the sub-value at that path.  An empty list returns the
input unchanged.

.. code-block::

   %l = cute.static : !cute.layout<"((4,2),(3,8)):((1,4),(8,24))">

   // First top-level mode
   %m0 = cute.get<[0]> (%l)
           : !cute.layout<"((4,2),(3,8)):((1,4),(8,24))">
          -> !cute.layout<"(4,2):(1,4)">

   // Drill into mode (0, 1): the inner 2:4 sub-layout
   %m01 = cute.get<[0, 1]> (%l)
            : !cute.layout<"((4,2),(3,8)):((1,4),(8,24))">
           -> !cute.layout<"2:4">

``cute.select`` builds a new value from a chosen subset of top-level
modes (in the listed order — repeats and reorderings are allowed):

.. code-block::

   %l = cute.static : !cute.layout<"(4,2,8):(1,4,8)">

   // Pick modes 2 and 0, in that order
   %sw = cute.select<[2, 0]> (%l)
           : !cute.layout<"(4,2,8):(1,4,8)"> -> !cute.layout<"(8,4):(8,1)">

   // Pick only mode 0 (still wrapped as a rank-1 value)
   %m0 = cute.select<[0]> (%l)
           : !cute.layout<"(4,8):(1,4)"> -> !cute.layout<"(4):(1)">

Leaf / scalar extraction
~~~~~~~~~~~~~~~~~~~~~~~~

``cute.get_leaves`` and ``cute.get_scalars`` are the two flatten
accessors:

- ``cute.get_leaves`` returns one CuTe-typed result per leaf of the
  input's hierarchy.  Useful when downstream code needs the leaves as
  independent SSA values without recovering them from the CuTe type.
- ``cute.get_scalars`` returns the integer leaves as plain ``i32``
  SSA values.  An optional ``<{only_dynamic}>`` qualifier restricts the
  output to dynamic leaves — convenient when only the runtime values
  are needed.

.. code-block::

   %sh = cute.static : !cute.shape<"(4,(2,3))">

   // Three leaves: !cute.shape<"4">, !cute.shape<"2">, !cute.shape<"3">
   %a, %b, %c = cute.get_leaves(%sh) : !cute.shape<"(4,(2,3))">

   %l = cute.make_layout(%s, %d)
          : (!cute.shape<"(?,8)">, !cute.stride<"(1,?)">)
         -> !cute.layout<"(?,8):(1,?)">

   // All scalar leaves as i32
   %s0, %s1, %s2, %s3 = cute.get_scalars (%l)
                          : !cute.layout<"(?,8):(1,?)">

   // Only the dynamic ones
   %d0, %d1 = cute.get_scalars<{only_dynamic}> (%l)
                : !cute.layout<"(?,8):(1,?)">

Tile accessors
~~~~~~~~~~~~~~

A ``!cute.tile`` is a sequence of layouts and ``_`` wildcards.
``cute.get_layouts_from_tile`` returns every layout slot as a separate
SSA result, skipping the underscores:

.. code-block::

   %t = cute.static : !cute.tile<"[(4,8):(1,4);_;(2,3):(1,2)]">

   %a, %b = cute.get_layouts_from_tile(%t)
              : !cute.tile<"[(4,8):(1,4);_;(2,3):(1,2)]">

The two results are ``!cute.layout<"(4,8):(1,4)">`` and
``!cute.layout<"(2,3):(1,2)">``.

---------------------------------------------------------------------------

Size and indexing
-----------------

These ops compute scalar quantities about a CuTe value or convert
between coordinates and linear indices.

.. list-table::
   :header-rows: 1
   :widths: 30 70

   * - Op
     - What it does
   * - ``cute.size``
     - Multiplicative size of a tuple / layout-like value (optionally
       restricted to a subset of modes).
   * - ``cute.cosize``
     - Codomain size (max-index + 1) of a layout-like value (optionally
       restricted to a subset of modes).
   * - ``cute.tuple_product``
     - Product of every leaf in an ``int_tuple`` or shape.
   * - ``cute.tuple_product_each``
     - Per-top-level-mode product of an ``int_tuple`` or shape.
   * - ``cute.crd2idx``
     - Convert a coordinate to a linear index with respect to a shape.
   * - ``cute.idx2crd``
     - Convert a linear index to a coordinate with respect to a shape.
   * - ``cute.increment_coord``
     - Increment a coordinate by one within its bounding shape.
   * - ``cute.append_to_rank``
     - Append a default element until the rank reaches a target ``N``.
   * - ``cute.prepend_to_rank``
     - Prepend a default element until the rank reaches a target ``N``.

Sizes and products
~~~~~~~~~~~~~~~~~~

``cute.size`` and ``cute.cosize`` are the two scalar-summary ops for a
layout.  ``size(L)`` is the number of distinct coordinates the layout
walks; ``cosize(L)`` is one past the maximum linear index it produces.
Both accept an optional mode-index list (``<[...]>``) to restrict the
summary to a subset of modes.

.. code-block::

   %l = cute.static : !cute.layout<"(4,(16,32)):(1,(4,64))">

   // Full size
   %sz = cute.size (%l)
           : (!cute.layout<"(4,(16,32)):(1,(4,64))">)
          -> !cute.int_tuple<"2048">

   // Only mode 1
   %sz1 = cute.size<[1]> (%l)
            : (!cute.layout<"(4,(16,32)):(1,(4,64))">)
           -> !cute.int_tuple<"512">

   // Cosize (max linear index + 1)
   %cs = cute.cosize (%l)
           : (!cute.layout<"(4,3,2):(1,4,12)">)
          -> !cute.int_tuple<"24">

``cute.tuple_product`` reduces an int-tuple or shape to a single scalar
by multiplying every leaf.  ``cute.tuple_product_each`` reduces per
top-level mode:

.. code-block::

   %t = cute.static : !cute.int_tuple<"(2,(3,4))">

   %p  = cute.tuple_product(%t)
           : (!cute.int_tuple<"(2,(3,4))">) -> !cute.int_tuple<"24">

   %pe = cute.tuple_product_each(%t)
           : (!cute.int_tuple<"(2,(3,4))">) -> !cute.int_tuple<"(2,12)">

Coordinate ↔ index conversion
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The conversions between coordinates and column-major linear indices are
exposed as standalone ops.

- ``cute.crd2idx(coord, shape)`` packs the coordinate using the implicit
  column-major strides derived from the shape, producing a linear index.
- ``cute.idx2crd(idx, shape)`` is the dual — given a shape and a linear
  index, it returns the corresponding coordinate in colexicographic
  order.

.. code-block::

   %shape0 = cute.static : !cute.shape<"(4,5)">
   %c      = cute.static : !cute.coord<"(2,1)">

   %i = cute.crd2idx(%c, %shape0)
          : (!cute.coord<"(2,1)">, !cute.shape<"(4,5)">)
         -> !cute.int_tuple<"6">

   %idx   = cute.static : !cute.int_tuple<"9">
   %shape = cute.static : !cute.shape<"(4,8)">
   %crd   = cute.idx2crd(%idx, %shape)
              : (!cute.int_tuple<"9">, !cute.shape<"(4,8)">)
             -> !cute.coord<"(1,2)">

``cute.increment_coord(coord, shape)`` advances a coordinate by one
within its bounding shape (in colexicographic order), wrapping at mode
boundaries:

.. code-block::

   %c = cute.static : !cute.coord<"(3,2)">
   %s = cute.static : !cute.shape<"(4,8)">

   %n = cute.increment_coord(%c, %s)
          : (!cute.coord<"(3,2)">, !cute.shape<"(4,8)">)
         -> !cute.coord<"(0,3)">

Rank padding
~~~~~~~~~~~~

``cute.append_to_rank`` and ``cute.prepend_to_rank`` extend an input
value until its rank reaches the target ``N`` (specified as the
``<N>`` attribute), padding with a caller-supplied default element of
the matching type.  These are mostly used to align ranks before
composing layouts.

.. code-block::

   %in = cute.static : !cute.shape<"(4,8)">
   %e  = cute.static : !cute.shape<"1">

   %r = cute.append_to_rank<4> (%in, %e)
          : !cute.shape<"(4,8)">, !cute.shape<"1">
   //   -> !cute.shape<"(4,8,1,1)">

   %p = cute.prepend_to_rank<4> (%in, %e)
          : !cute.shape<"(4,8)">, !cute.shape<"1">
   //   -> !cute.shape<"(1,1,4,8)">
