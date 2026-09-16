.. Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
.. SPDX-License-Identifier: BSD-3-Clause
..
.. Redistribution and use in source and binary forms, with or without
.. modification, are permitted provided that the following conditions are met:
..
.. 1. Redistributions of source code must retain the above copyright notice, this
.. list of conditions and the following disclaimer.
..
.. 2. Redistributions in binary form must reproduce the above copyright notice,
.. this list of conditions and the following disclaimer in the documentation
.. and/or other materials provided with the distribution.
..
.. 3. Neither the name of the copyright holder nor the names of its
.. contributors may be used to endorse or promote products derived from
.. this software without specific prior written permission.
..
.. THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
.. AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
.. IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
.. DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
.. FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
.. DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
.. SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
.. CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
.. OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
.. OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

Advanced Layout Constructors
============================

The primitive ``cute.make_layout`` op builds a layout from explicit shape and
stride components.  These three advanced constructors derive a new compact
layout from an existing layout's shape or structure, without the caller having
to compute strides manually.  Each op accepts the source value as an operand
and infers the result layout type automatically.

.. list-table::
   :header-rows: 1
   :widths: 28 72

   * - Op
     - When to use
   * - ``cute.make_ordered_layout``
     - Compact layout with an **explicit mode ordering** specified by the caller.
   * - ``cute.make_layout_like``
     - Compact layout that **preserves the relative stride ordering** of an
       existing layout.
   * - ``cute.make_identity_layout``
     - **Identity layout** that maps each coordinate to its own position using
       scaled-basis strides, useful as a tile-coordinate layout.

---------------------------------------------------------------------------

``cute.make_ordered_layout``
----------------------------

Constructs a compact layout from a shape and an explicit ordering tuple.
Each mode is assigned a relative priority: the mode with the smallest order
value receives stride 1 (least major), and subsequent strides are prefix
products of the shape taken in ascending order priority.

The ordering tuple must have the same hierarchical structure as the shape
(same rank and nesting depth), and its values must be static integers.
Shape extents may be dynamic.

.. code-block::

   // Column-major: order (0,1) → strides (1,4) for shape (4,2)
   %l = cute.make_ordered_layout(%s, %o)
          : (!cute.shape<"(4,2)">, !cute.int_tuple<"(0,1)">)
         -> !cute.layout<"(4,2):(1,4)">

   // Row-major: order (1,0) → strides (2,1) for shape (4,2)
   %l = cute.make_ordered_layout(%s, %o)
          : (!cute.shape<"(4,2)">, !cute.int_tuple<"(1,0)">)
         -> !cute.layout<"(4,2):(2,1)">

   // Four modes, arbitrary order
   %l = cute.make_ordered_layout(%s, %o)
          : (!cute.shape<"(4,3,8,2)">, !cute.int_tuple<"(2,1,3,0)">)
         -> !cute.layout<"(4,3,8,2):(6,2,24,1)">

   // Dynamic extent — the ? leaf flows through to the result stride
   %l = cute.make_ordered_layout(%s, %o)
          : (!cute.shape<"(4,3,?,2)">, !cute.int_tuple<"(2,1,3,4)">)
         -> !cute.layout<"(4,3,?,2):(3,1,12,?)">

When two modes have the same order value they are treated as equivalent in
priority and their relative order is left-to-right.

---------------------------------------------------------------------------

``cute.make_layout_like``
--------------------------

Given a source layout, produces a new compact layout that has the same
shape and the same relative mode ordering as the source.  The mode with the
smallest non-zero source stride receives stride 1; the rest receive strides
in ascending order of the original stride magnitudes.  The result represents
the same data arrangement — column-major, row-major, or any custom ordering
— but with contiguous (no-gap) strides.

Modes that have a static zero stride in the source are preserved as
zero-stride modes in the result — the result shape keeps their original
extent and only the non-zero strides get re-normalised. For example,
``(2,3,4,5):(0,42,1,0)`` produces ``(2,3,4,5):(0,4,1,0)``: the two
0-strides pass through, the non-zero ``42`` / ``1`` modes get the
strides they would have in a compact layout that ignored the
zero-stride modes.

If the source is a ``!cute.composed_layout``, the operation is applied to
the outer (B) layout component and returns a plain ``!cute.layout``.

Input constraints
~~~~~~~~~~~~~~~~~

- **Plain layout** ``!cute.layout``: strides must be plain integers or
  dynamic integers.  Scaled-basis strides (written ``V@M``) are not
  accepted because comparing stride magnitudes is not defined for basis
  values.

- **Composed layout** ``!cute.composed_layout``: the A component must be a
  Swizzle; a layout A component is not supported.  The outer B layout must
  also have plain integer or dynamic integer strides.

.. code-block::

   // Rank-1 strided → compact
   %r = cute.make_layout_like(%src)
          : !cute.layout<"8:2"> -> !cute.layout<"8:1">

   // Column-major — already compact, result unchanged
   %r = cute.make_layout_like(%src)
          : !cute.layout<"(4,2):(1,4)"> -> !cute.layout<"(4,2):(1,4)">

   // Row-major — ordering preserved, strides normalised
   %r = cute.make_layout_like(%src)
          : !cute.layout<"(4,2):(4,1)"> -> !cute.layout<"(4,2):(2,1)">

   // Nested layout — ordering across modes and sub-modes preserved
   %r = cute.make_layout_like(%src)
          : !cute.layout<"(2,(3,4)):(1,(2,8))">
         -> !cute.layout<"(2,(3,4)):(1,(2,6))">

   // Composed layout source — applied to outer B component
   %r = cute.make_layout_like(%src)
          : !cute.composed_layout<"S<3,4,3> o 6 o (8,2):(2,16)">
         -> !cute.layout<"(8,2):(1,8)">

---------------------------------------------------------------------------

``cute.make_identity_layout``
------------------------------

Produces an identity layout for the given shape.  Each leaf mode in the
shape receives a unit scaled-basis stride: the ``k``-th leaf (in
depth-first, left-to-right order across the shape tree) receives stride
``1@k``.  This means coordinate ``c`` under the identity layout maps to
``c`` itself, represented as a multi-dimensional index into an abstract
index space rather than a flat memory offset.

Identity layouts are useful as tile-coordinate layouts that describe the
position of a tile in a partitioned hierarchy without implying any
particular memory arrangement.

Shape extents may be dynamic; the strides are always static scaled-basis
vectors determined entirely by the shape's nesting structure, not by the
runtime extent values.

.. code-block::

   // Scalar shape → stride 1 (the one-dimensional identity)
   %l = cute.make_identity_layout(%s)
          : !cute.shape<"4"> -> !cute.layout<"4:1">

   // Flat shape → per-mode basis strides
   %l = cute.make_identity_layout(%s)
          : !cute.shape<"(4,2)"> -> !cute.layout<"(4,2):(1@0,1@1)">

   // Nested shape → nested basis strides
   //   Leaves in depth-first order: 2 (k=0), 3 (k=1 sub 0), 4 (k=1 sub 1), 5 (k=2)
   %l = cute.make_identity_layout(%s)
          : !cute.shape<"(2,(3,4),5)">
         -> !cute.layout<"(2,(3,4),5):(1@0,(1@0@1,1@1@1),1@2)">

   // Dynamic extent — strides are still static basis vectors
   %l = cute.make_identity_layout(%s)
          : !cute.shape<"(?,3)"> -> !cute.layout<"(?,3):(1@0,1@1)">

For more on scaled-basis strides and how ``V@M`` notation works, see the
*Scaled-basis strides* section in ``01_cute_types.rst``.

---------------------------------------------------------------------------

Summary
-------

.. list-table::
   :header-rows: 1
   :widths: 28 28 44

   * - Op
     - Source
     - Result
   * - ``make_ordered_layout``
     - ``!cute.shape`` + ``!cute.int_tuple`` order
     - Compact layout whose mode ordering matches the given order values.
   * - ``make_layout_like``
     - ``!cute.layout`` or ``!cute.composed_layout``
     - Compact layout with the same shape and the same relative mode
       ordering as the source; no scaled-basis strides allowed in source.
   * - ``make_identity_layout``
     - ``!cute.shape``
     - Layout whose ``k``-th leaf mode has stride ``1@k``; maps
       coordinates to their own multi-dimensional position.
