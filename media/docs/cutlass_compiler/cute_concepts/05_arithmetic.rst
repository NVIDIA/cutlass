Arithmetic on Cute Values
=========================

The Arithmetic op group provides per-leaf integer arithmetic and
comparison primitives on tuple-like CuTe values (``!cute.int_tuple``,
``!cute.shape``, ``!cute.coord``).  The ops fall into two categories:

- **Tuple arithmetic** — produce a new tuple with element-wise
  arithmetic on each leaf.
- **Predicate ops** — return a single ``i1`` boolean.

.. contents::
   :local:
   :depth: 2

---------------------------------------------------------------------------

Tuple add / sub
---------------

``cute.tuple_add`` and ``cute.tuple_sub`` perform element-wise
addition / subtraction on two int-tuples or two shapes.  When the inputs
have different ranks, the shorter input is padded on the right with the
longer input's trailing modes (i.e. extra modes on the long side flow
through unchanged).

For ``cute.tuple_add``, a top-level static scalar zero is a two-sided
identity for a complete tuple operand.  This does not make a scalar
compatible with a nested tuple mode.

.. code-block::

   %a = cute.static : !cute.int_tuple<"(3,4)">
   %b = cute.static : !cute.int_tuple<"(1,2)">
   %r = cute.tuple_add(%a, %b)
          : (!cute.int_tuple<"(3,4)">, !cute.int_tuple<"(1,2)">)
         -> !cute.int_tuple<"(4,6)">

   // Rank mismatch — extra rhs leaf passes through unchanged.
   %c = cute.static : !cute.int_tuple<"(1,2)">
   %d = cute.static : !cute.int_tuple<"(4,5,6)">
   %r2 = cute.tuple_add(%c, %d)
           : (!cute.int_tuple<"(1,2)">, !cute.int_tuple<"(4,5,6)">)
          -> !cute.int_tuple<"(5,7,6)">

``cute.tuple_sub`` computes ``a - b`` on aligned leaves.  A top-level
static scalar zero is an identity only on the right: ``x - 0`` is valid
for a tuple ``x``, but ``0 - x`` is not.

.. code-block::

   %a = cute.static : !cute.int_tuple<"(5,8)">
   %b = cute.static : !cute.int_tuple<"(1,2)">
   %r = cute.tuple_sub(%a, %b)
          : (!cute.int_tuple<"(5,8)">, !cute.int_tuple<"(1,2)">)
         -> !cute.int_tuple<"(4,6)">

**Where this comes up.** Coordinate offsets — adding or subtracting
a delta tuple from a base coordinate to step through a tensor.

---------------------------------------------------------------------------

Shape / ceil division
---------------------

``cute.shape_div`` accepts and returns ``!cute.shape`` values.  At each
recursive step it handles four cases:

* tuple / tuple: recurse over paired modes.  The ranks must match at every
  step where both current values are tuples; each paired mode may then select
  any of these four cases, so mixed nesting is valid.
* tuple / scalar: visit the dividend modes from left to right.  Each mode
  consumes the part of the divisor that it can divide, and the remainder is
  passed to the next mode.
* scalar / tuple: reduce the divisor to the product of its leaves, then divide.
* scalar / scalar: the divisor must be nonzero, and one side must divide the
  other.  The result is the quotient rounded away from zero, which selects the
  factor not already consumed by the other operand.

.. code-block::

   // Same-rank: per-leaf integer division
   %a = cute.static : !cute.shape<"(8,10)">
   %b = cute.static : !cute.shape<"(2,5)">
   %r = cute.shape_div(%a, %b)
          : (!cute.shape<"(8,10)">, !cute.shape<"(2,5)">)
         -> !cute.shape<"(4,2)">

   // Rank-1 divisor spread across a rank-3 dividend
   %c = cute.static : !cute.shape<"(4,5,6)">
   %d = cute.static : !cute.shape<"40">
   %r2 = cute.shape_div(%c, %d)
           : (!cute.shape<"(4,5,6)">, !cute.shape<"40">)
          -> !cute.shape<"(1,1,3)">

``cute.ceil_div`` accepts an ``!cute.int_tuple`` or ``!cute.shape`` input.
Its tiler may independently be an ``!cute.int_tuple``, ``!cute.shape``, or
``!cute.tile``.  The result kind follows the input kind.

For an integer-tuple or shape tiler, the operation follows the same four-case
tuple/scalar structure as ``cute.shape_div``, but its tuple / tuple rule
requires ``rank(input) >= rank(tiler)`` and passes trailing input modes through
unchanged.  Scalar division rounds up.  In the tuple / scalar case the
remaining tiler is updated after every mode as
``ceil_div(remaining_tiler, input_mode)``.  A tile tiler instead uses the
shape/tile rules; it may change the result profile while preserving the input
kind.

.. code-block::

   %a = cute.static : !cute.int_tuple<"(8,10)">
   %b = cute.static : !cute.int_tuple<"(3,4)">
   %r = cute.ceil_div(%a, %b)
          : (!cute.int_tuple<"(8,10)">, !cute.int_tuple<"(3,4)">)
         -> !cute.int_tuple<"(3,3)">

   // A tile tiler can change the result profile.
   %count = cute.ceil_div(%input, %tile)
       : (!cute.int_tuple<"(8,16)">, !cute.tile<"((4,8)):((1,4))">)
      -> !cute.int_tuple<"4">

**Where this comes up.** Computing tile counts for partitioning —
``ceil_div(tensor_shape, tile_shape)`` is the per-axis number of tiles
needed to cover a non-evenly-divisible tensor.

---------------------------------------------------------------------------

Predicates: ``equal`` and ``elem_less``
----------------------------------------

``cute.equal`` accepts ``!cute.int_tuple``, ``!cute.shape``, ``!cute.coord``,
``!cute.stride``, and ``!cute.layout`` operands of the same kind.  It returns
``i1`` true iff their values are equal.  Statically different structures or
values compare false; dynamic operands with the same profile are compared
leaf by leaf.

``cute.elem_less`` accepts operands independently drawn from
``!cute.int_tuple``, ``!cute.shape``, and ``!cute.coord``.  Their tuple
hierarchies must be congruent.  It returns ``i1`` true iff every lhs leaf is
strictly less than the corresponding rhs leaf.

.. code-block::

   // equal — structural identity over two int_tuples
   %a = cute.static : !cute.int_tuple<"(3,4)">
   %b = cute.static : !cute.int_tuple<"(3,4)">
   %e = cute.equal(%a, %b)
          : (!cute.int_tuple<"(3,4)">, !cute.int_tuple<"(3,4)">) -> i1

   // elem_less — leaf-wise strict less-than
   %lo = cute.static : !cute.coord<"(3,4)">
   %hi = cute.static : !cute.shape<"(5,6)">
   %ok = cute.elem_less(%lo, %hi)
           : (!cute.coord<"(3,4)">, !cute.shape<"(5,6)">) -> i1

**Where this comes up.** Bounds checks — ``elem_less(coord, shape)``
is the canonical "is this coordinate in range?" predicate, used to
guard tail-block accesses.
