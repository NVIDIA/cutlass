//===- CuteTypes.td - Cute dialect type definitions --------*- tablegen -*-===//
//

// Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation
// and/or other materials provided with the distribution.
//
// 3. Neither the name of the copyright holder nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

//===----------------------------------------------------------------------===//

#ifndef CUTE_IR_DIALECT_CUTE_IR_CUTE_TYPES_TD
#define CUTE_IR_DIALECT_CUTE_IR_CUTE_TYPES_TD

include "mlir/IR/BuiltinTypeInterfaces.td"
include "mlir/Interfaces/DataLayoutInterfaces.td"
include "cute_ir/Dialect/Cute/IR/CuteDialect.td"
include "cute_ir/Dialect/Cute/IR/CuteAttrs.td"
include "cute_ir/Dialect/Cute/IR/CuteTypeInterfaces.td"

//===----------------------------------------------------------------------===//
// IntTupleType
//===----------------------------------------------------------------------===//

def Cute_IntTupleType
    : Cute_Type<"IntTuple", "int_tuple",
                [DeclareTypeInterfaceMethods<Cute_MaybeStaticTypeInterface>,
                 DeclareTypeInterfaceMethods<DataLayoutTypeInterface,
                     ["getTypeSize", "getTypeSizeInBits", "getABIAlignment",
                      "getPreferredAlignment", "getIndexBitwidth",
                      "areCompatible", "verifyEntries"]>]> {
  let summary = "Scalar integer or recursive tuple of integers";
  let description = [{
    An ``IntTuple`` models a CuTe integer tuple: either a single integer (depth 0)
    or a tuple of ``IntTuple`` elements (depth ≥ 1), arbitrarily nested.

    Leaf values:

    - static integer — compile-time constant
    - dynamic integer — runtime value (``?``), default i32 width; ``?{i64}``
      for an i64-wide dynamic.

    Assembly format — ``< "string" >`` where the string is the canonical
    printed form of the integer tuple.

    **Examples**

    ```mlir
    !cute.int_tuple<"1">                   // depth-0, scalar static 1
    !cute.int_tuple<"?">                   // depth-0, scalar dynamic (i32)
    !cute.int_tuple<"?{i64}">              // depth-0, scalar dynamic (i64)
    !cute.int_tuple<"(1,2)">               // depth-1, rank-2 static tuple
    !cute.int_tuple<"(1,(2,3))">           // depth-2, nested static tuple
    !cute.int_tuple<"(?,32)">              // depth-1, mixed: dynamic + static
    !cute.int_tuple<"(?,?{i64})">          // depth-1, mixed widths
    ```
  }];

  let parameters = (ins
    Cute_Param<"IntTupleAttr", "Stores the underlying int_tuple value">:$attr
  );
  let hasCustomAssemblyFormat = 1;

  let builders = [
    TypeBuilder<(ins "cutegen::int_tuple":$value), [{
      return $_get($_ctxt, IntTupleAttr::get($_ctxt, std::move(value)));
    }]>
  ];

  let extraClassDeclaration = [{
    /// Underlying cutegen algebra type.
    using algebra_t = cutegen::int_tuple;
    /// Returns the underlying int_tuple (delegates to the attribute).
    cutegen::int_tuple const &getRef() const { return getAttr().getRef(); }
  }];
}

//===----------------------------------------------------------------------===//
// CoordType
//===----------------------------------------------------------------------===//

def Cute_CoordType
    : Cute_Type<"Coord", "coord",
                [DeclareTypeInterfaceMethods<Cute_MaybeStaticTypeInterface>,
                 DeclareTypeInterfaceMethods<DataLayoutTypeInterface,
                     ["getTypeSize", "getTypeSizeInBits", "getABIAlignment",
                      "getPreferredAlignment", "getIndexBitwidth",
                      "areCompatible", "verifyEntries"]>]> {
  let summary = "Scalar integer, underscore wildcard, or recursive tuple of coordinates";
  let description = [{
    A ``Coord`` models a CuTe coordinate: either a single leaf value (depth 0)
    or a tuple of ``Coord`` elements (depth ≥ 1), arbitrarily nested.

    Leaf values:

    - static integer — compile-time constant
    - underscore (``_``) — the CuTe slice wildcard
    - dynamic integer — runtime value (``?``), default i32 width;
      ``?{i64}`` for an i64-wide dynamic

    A coordinate is considered static when no leaf is dynamic (no ``?``); the
    ``_`` wildcard is a compile-time slice marker and counts as static.

    Assembly format — ``< "string" >`` where the string is the canonical
    printed form of the coordinate value.

    **Examples**

    ```mlir
    !cute.coord<"1">           // depth-0, scalar static 1
    !cute.coord<"_">           // depth-0, underscore wildcard
    !cute.coord<"?">           // depth-0, scalar dynamic
    !cute.coord<"(1,2)">       // depth-1, rank-2 static
    !cute.coord<"(_,?)">       // depth-1, underscore + dynamic
    !cute.coord<"(_,_,?)">     // depth-1, two underscores + dynamic
    !cute.coord<"(1,(2,3))">   // depth-2, nested static
    ```
  }];

  let parameters = (ins
    Cute_Param<"CoordAttr", "Stores the underlying coord value">:$attr
  );
  let hasCustomAssemblyFormat = 1;

  let builders = [
    TypeBuilder<(ins "cutegen::coord":$value), [{
      return $_get($_ctxt, CoordAttr::get($_ctxt, std::move(value)));
    }]>
  ];

  let extraClassDeclaration = [{
    /// Underlying cutegen algebra type.
    using algebra_t = cutegen::coord;
    /// Returns the underlying coord (delegates to the attribute).
    cutegen::coord const &getRef() const { return getAttr().getRef(); }
  }];
}

//===----------------------------------------------------------------------===//
// ShapeType
//===----------------------------------------------------------------------===//

def Cute_ShapeType
    : Cute_Type<"Shape", "shape",
                [DeclareTypeInterfaceMethods<Cute_MaybeStaticTypeInterface>,
                 DeclareTypeInterfaceMethods<DataLayoutTypeInterface,
                     ["getTypeSize", "getTypeSizeInBits", "getABIAlignment",
                      "getPreferredAlignment", "getIndexBitwidth",
                      "areCompatible", "verifyEntries"]>]> {
  let summary = "Scalar integer or recursive tuple of shape extents";
  let description = [{
    A ``Shape`` models a CuTe shape (extent tuple): either a single integer
    (depth 0) or a tuple of ``Shape`` elements (depth ≥ 1), arbitrarily nested.

    Leaf values:

    - static integer — compile-time constant (typically a positive
      extent, but ``0`` is permitted because some valid uses of
      ``!cute.shape`` carry counts or paddings; positivity is
      enforced where it matters, e.g. in ``!cute.layout``'s verifier
      against the layout's shape mode).

    - dynamic integer — runtime value (``?``), default i32 width;
      ``?{i64}`` for an i64-wide dynamic

    A shape is considered static when no leaf is dynamic (no ``?``).

    Assembly format — ``< "string" >`` where the string is the canonical
    printed form of the shape value.

    **Examples**

    ```mlir
    !cute.shape<"1">           // depth-0, scalar static 1
    !cute.shape<"?">           // depth-0, scalar dynamic (i32)
    !cute.shape<"?{i64}">      // depth-0, scalar dynamic (i64)
    !cute.shape<"(1,2)">       // depth-1, rank-2 static shape
    !cute.shape<"(?,32)">      // depth-1, mixed: dynamic + static
    !cute.shape<"(1,(2,3))">   // depth-2, nested static shape
    ```
  }];

  let parameters = (ins
    Cute_Param<"ShapeAttr", "Stores the underlying shape value">:$attr
  );
  let hasCustomAssemblyFormat = 1;

  let builders = [
    TypeBuilder<(ins "cutegen::shape":$value), [{
      return $_get($_ctxt, ShapeAttr::get($_ctxt, std::move(value)));
    }]>
  ];

  let extraClassDeclaration = [{
    /// Underlying cutegen algebra type.
    using algebra_t = cutegen::shape;
    /// Returns the underlying shape (delegates to the attribute).
    cutegen::shape const &getRef() const { return getAttr().getRef(); }
  }];
}

//===----------------------------------------------------------------------===//
// StrideType
//===----------------------------------------------------------------------===//

def Cute_StrideType
    : Cute_Type<"Stride", "stride",
                [DeclareTypeInterfaceMethods<Cute_MaybeStaticTypeInterface>,
                 DeclareTypeInterfaceMethods<DataLayoutTypeInterface,
                     ["getTypeSize", "getTypeSizeInBits", "getABIAlignment",
                      "getPreferredAlignment", "getIndexBitwidth",
                      "areCompatible", "verifyEntries"]>]> {
  let summary = "Scalar or recursive tuple of stride elements";
  let description = [{
    A ``Stride`` models a CuTe stride: either a single leaf value (depth 0)
    or a tuple of ``Stride`` elements (depth ≥ 1), arbitrarily nested.

    Leaf values:

    - static integer — compile-time constant (e.g. ``1``, ``16``)
    - dynamic integer — runtime value (``?``), default i32 width; ``?{i64}``
      for an i64-wide dynamic

    - scaled basis (``V@Mn@...@M0``) — value scaled by a basis vector; a single
      index ``V@M`` addresses a top-level mode, chained indices ``V@Mn@...@M0``
      address a nested mode (corresponds to ``E<M0,...,Mn>``); ``V``
      may be static (e.g. ``4@0``) or dynamic (e.g. ``?@0``). Note the Mn@...@M0
      order, the last M0 is the outer most mode. For example, ``1@1@0`` is the stride
      for ((x, 1), ...). In other words, ``1@1@0`` is the stride for the mode-1 of the
      mode-0 of the coordinate space.

    A stride is considered static when no leaf is dynamic (no ``?``);

    Assembly format — ``< "string" >`` where the string is the canonical
    printed form of the stride value.

    **Examples**

    ```mlir
    !cute.stride<"1">             // depth-0, scalar static stride 1
    !cute.stride<"?">             // depth-0, scalar dynamic
    !cute.stride<"4@0">           // depth-0, static scaled basis: 4 × e_0
    !cute.stride<"?@0">           // depth-0, dynamic scaled basis
    !cute.stride<"1@1@0">         // depth-0, hierarchical basis: E<0,1>
    !cute.stride<"(16,32)">       // depth-1, rank-2 static stride
    !cute.stride<"(16,?)">        // depth-1, static + dynamic
    !cute.stride<"(0,?@0)">       // depth-1, zero-int + dynamic scaled basis
    !cute.stride<"(1@1@0,2@0)">   // depth-1, hierarchical + regular basis
    !cute.stride<"(16,(32,4))">   // depth-2, nested static stride
    ```
  }];

  let parameters = (ins
    Cute_Param<"StrideAttr", "Stores the underlying stride value">:$attr
  );
  let hasCustomAssemblyFormat = 1;
  let genVerifyDecl = 1;

  let builders = [
    TypeBuilder<(ins "cutegen::stride":$value), [{
      return $_get($_ctxt, StrideAttr::get($_ctxt, std::move(value)));
    }]>
  ];

  let extraClassDeclaration = [{
    /// Underlying cutegen algebra type.
    using algebra_t = cutegen::stride;
    /// Returns the underlying stride (delegates to the attribute).
    cutegen::stride const &getRef() const { return getAttr().getRef(); }
  }];
}

//===----------------------------------------------------------------------===//
// LayoutType
//===----------------------------------------------------------------------===//

def Cute_LayoutType
    : Cute_Type<"Layout", "layout",
                [DeclareTypeInterfaceMethods<Cute_MaybeStaticTypeInterface>,
                 DeclareTypeInterfaceMethods<DataLayoutTypeInterface,
                     ["getTypeSize", "getTypeSizeInBits", "getABIAlignment",
                      "getPreferredAlignment", "getIndexBitwidth",
                      "areCompatible", "verifyEntries"]>]> {
  let summary = "CuTe layout: a shape/stride pair";
  let description = [{
    A ``Layout`` models a CuTe layout: a shape/stride pair that maps a
    coordinate space to an index space.  The shape and stride may be scalar
    (depth 0) or arbitrarily nested tuples (depth ≥ 1).

    Leaf values in the shape:

    - static integer — compile-time constant extent
    - dynamic integer — runtime extent (``?``), default i32 width;
      ``?{i64}`` for an i64-wide dynamic

    Leaf values in the stride:

    - static integer — compile-time constant stride
    - dynamic integer — runtime stride (``?``), default i32 width;
      ``?{i64}`` for i64

    - scaled basis (``V@Mn@...@M0``) — value scaled by a basis vector; a single
      index ``V@M`` addresses a top-level mode, chained indices ``V@Mn@...@M0``
      address a nested mode (corresponds to ``E<M0,...,Mn>``, see !cute.stride)

    A layout is considered static when no leaf is dynamic (no ``?``).

    **Examples**

    1. ``A = !cute.layout<"(2,3):(1,2)">`` — affine rank-2 layout.
       The integral coord enumerates ``size(A) = 2*3 = 6`` positions;
       ``idx2crd`` maps it to the hier coord with column-major order,
       and ``A(c) = c0*1 + c1*2``. This layout is the identity (A(c) = i).

       +--------------------+----------------+------+
       | Integral coord (i) | Hier coord (c) | A(c) |
       +====================+================+======+
       | 0                  | (0, 0)         | 0    |
       +--------------------+----------------+------+
       | 1                  | (1, 0)         | 1    |
       +--------------------+----------------+------+
       | 2                  | (0, 1)         | 2    |
       +--------------------+----------------+------+
       | 3                  | (1, 1)         | 3    |
       +--------------------+----------------+------+
       | 4                  | (0, 2)         | 4    |
       +--------------------+----------------+------+
       | 5                  | (1, 2)         | 5    |
       +--------------------+----------------+------+

    2. ``B = !cute.layout<"((2,3),4):((1@0@0,1@1@0),1@1)">`` — hierarchical
       basis-stride layout. Shape ``((2,3),4)`` has ``size = 6*4 = 24``. The
       basis strides decompose the linear index into a *nested* result
       int_tuple whose shape mirrors the coord: each ``1@Mn@...@M0``
       deposits its scalar contribution at the slot identified by the
       chained mode indices.

       - ``1@0@0`` (E<0,0>) → mode-0 inner-0 of result
       - ``1@1@0`` (E<0,1>) → mode-0 inner-1 of result
       - ``1@1``   (E<1>)   → mode-1 of result

       So for coord ``c = ((c00, c01), c1)``, ``B(c) = ((c00, c01), c1)`` —
       a structural identity that preserves the hierarchy. Spot checks
       (verified via ``cute.layout_eval``):

       +----------------+-------------+
       | Hier coord (c) | B(c)        |
       +================+=============+
       | ((0, 0), 0)    | ((0, 0), 0) |
       +----------------+-------------+
       | ((1, 0), 0)    | ((1, 0), 0) |
       +----------------+-------------+
       | ((0, 1), 0)    | ((0, 1), 0) |
       +----------------+-------------+
       | ((0, 0), 1)    | ((0, 0), 1) |
       +----------------+-------------+
       | ((1, 2), 0)    | ((1, 2), 0) |
       +----------------+-------------+
       | ((1, 2), 3)    | ((1, 2), 3) |
       +----------------+-------------+

    Assembly format — ``< "string" >`` where the string is the canonical
    printed form of the layout.

    **Examples**

    ```mlir
    !cute.layout<"(2,3):(1,2)">                   // static rank-2 layout
    !cute.layout<"(2,3):(?,2)">                   // dynamic stride element
    !cute.layout<"(?,3):(1,2)">                   // dynamic shape element
    !cute.layout<"((2,3),(4,5)):((1,2),(3,4))">   // nested shape and stride
    !cute.layout<"(2,3):(1@0,1@1)">               // scaled-basis strides
    !cute.layout<"((2,3),4):((1@0@0,1@1@0),1@1)"> // hierarchical basis strides (mode-0 rank-2 with depth-2 hierarchical; mode-1 rank-1 single-level)
    ```
  }];

  let parameters = (ins
    Cute_Param<"LayoutAttr", "Stores the underlying layout value">:$attr
  );
  let hasCustomAssemblyFormat = 1;
  let genVerifyDecl = 1;

  let builders = [
    TypeBuilder<(ins "cutegen::layout":$value), [{
      return $_get($_ctxt, LayoutAttr::get($_ctxt, std::move(value)));
    }]>
  ];

  let extraClassDeclaration = [{
    /// Underlying cutegen algebra type.
    using algebra_t = cutegen::layout;
    /// Returns the underlying layout (delegates to the attribute).
    cutegen::layout const &getRef() const { return getAttr().getRef(); }
  }];
}

//===----------------------------------------------------------------------===//
// TileType
//===----------------------------------------------------------------------===//

def Cute_TileType
    : Cute_Type<"Tile", "tile",
                [DeclareTypeInterfaceMethods<Cute_MaybeStaticTypeInterface>,
                 DeclareTypeInterfaceMethods<DataLayoutTypeInterface,
                     ["getTypeSize", "getTypeSizeInBits", "getABIAlignment",
                      "getPreferredAlignment", "getIndexBitwidth",
                      "areCompatible", "verifyEntries"]>]> {
  let summary = "CuTe tile: a recursive sequence of layouts and underscores";
  let description = [{
    A ``Tile`` models a CuTe tiler: a recursive sequence of ``Layout`` elements
    and underscore wildcards (depth ≥ 0).

    Leaf values:

    - layout: a shape/stride pair (the primary tile element)
    - underscore (``_``): the CuTe slice wildcard; keeps the corresponding mode

    ``isStatic()`` returns ``true`` only when all layout leaves are fully static.

    Assembly format — ``< "string" >`` where the string is the canonical
    printed form of the tile, enclosed in brackets with elements separated by
    semicolons.

    **Examples**

    ```mlir
    !cute.tile<"[(2,3):(1,2)]">              // single-layout tile
    !cute.tile<"[(2,3):(1,2);(4,5):(1,4)]">  // two-layout tile
    !cute.tile<"[_]">                        // underscore tile (slice all)
    !cute.tile<"[(2,3):(1,2);_]">            // layout + underscore
    ```
  }];

  let parameters = (ins
    Cute_Param<"TileAttr", "Stores the underlying tile value">:$attr
  );
  let hasCustomAssemblyFormat = 1;
  let genVerifyDecl = 1;

  let builders = [
    TypeBuilder<(ins "cutegen::tile":$value), [{
      return $_get($_ctxt, TileAttr::get($_ctxt, std::move(value)));
    }]>
  ];

  let extraClassDeclaration = [{
    /// Underlying cutegen algebra type.
    using algebra_t = cutegen::tile;
    /// Returns the underlying tile (delegates to the attribute).
    cutegen::tile const &getRef() const { return getAttr().getRef(); }
  }];
}

//===----------------------------------------------------------------------===//
// ComposedLayoutType
//===----------------------------------------------------------------------===//

def Cute_ComposedLayoutType
    : Cute_Type<"ComposedLayout", "composed_layout",
                [DeclareTypeInterfaceMethods<Cute_MaybeStaticTypeInterface>,
                 DeclareTypeInterfaceMethods<DataLayoutTypeInterface,
                     ["getTypeSize", "getTypeSizeInBits", "getABIAlignment",
                      "getPreferredAlignment", "getIndexBitwidth",
                      "areCompatible", "verifyEntries"]>]> {
  let summary = "CuTe composed layout: A ∘ offset ∘ B";
  let description = [{
    A ``ComposedLayout`` models a CuTe composed layout: a three-part composition
    ``A o offset o B`` where a coordinate ``c`` maps to ``A(offset + B(c))``.
    Same as layouts, a composed layout is also a function that maps a coordinate to an index.

    Parts:

    - ``A``: either a layout or a swizzle (the outer mapping or swizzle function)
    - ``offset``: an integer tuple applied between B and A
    - ``B``: the base layout (defines the domain)

    **Examples**

    1. ``!cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">``

       +----------------+----------------+----------------+-------------------------+-------------------------+
       | Integral coord | Hier Coord (c) | B(c) = B index | offset + B(c) = A index | A o offset o B (Result) |
       +================+================+================+=========================+=========================+
       | 0              | (0,0)          | 0              | 0 + 2 = 2               | A(2) = 2                |
       +----------------+----------------+----------------+-------------------------+-------------------------+
       | 1              | (1,0)          | 1              | 1 + 2 = 3               | A(3) = 3                |
       +----------------+----------------+----------------+-------------------------+-------------------------+
       | 2              | (0,1)          | 2              | 2 + 2 = 4               | A(4) = 4                |
       +----------------+----------------+----------------+-------------------------+-------------------------+
       | 3              | (1,1)          | 3              | 3 + 2 = 5               | A(5) = 5                |
       +----------------+----------------+----------------+-------------------------+-------------------------+
       | 4              | (0,2)          | 4              | 4 + 2 = 6               | A(6) = 6                |
       +----------------+----------------+----------------+-------------------------+-------------------------+
       | 5              | (1,2)          | 5              | 5 + 2 = 7               | A(7) = 7                |
       +----------------+----------------+----------------+-------------------------+-------------------------+

    2. ``!cute.composed_layout<"(6,2):(1,3) o (2,1) o (2,3):(1@1,2@0)">``

       B = ``(2,3):(1@1,2@0)`` uses scaled-basis strides — mode 0 of the shape
       contributes its coord to basis dim 1, mode 1 of the shape contributes
       ``2 * coord`` to basis dim 0. So ``B(c)`` returns a rank-2 tuple:
       ``(basis-0-contribution, basis-1-contribution)``. The tuple offset ``(2,1)``
       is added per-component (matching basis-0 / basis-1 slots).
       A = ``(6,2):(1,3)`` then applies its strides to the resulting ``(n0, n1)``
       tuple coord: ``A(n0, n1) = n0 * 1 + n1 * 3``.

       +----------------+----------------+----------------+-------------------------+-------------------------+
       | Integral coord | Hier Coord (c) | B(c) = B index | offset + B(c) = A index | A o offset o B (Result) |
       +================+================+================+=========================+=========================+
       | 0              | (0,0)          | (0,0)          | (0,0) + (2,1) = (2,1)   | A(2,1) =  5             |
       +----------------+----------------+----------------+-------------------------+-------------------------+
       | 1              | (1,0)          | (0,1)          | (0,1) + (2,1) = (2,2)   | A(2,2) =  8             |
       +----------------+----------------+----------------+-------------------------+-------------------------+
       | 2              | (0,1)          | (2,0)          | (2,0) + (2,1) = (4,1)   | A(4,1) =  7             |
       +----------------+----------------+----------------+-------------------------+-------------------------+
       | 3              | (1,1)          | (2,1)          | (2,1) + (2,1) = (4,2)   | A(4,2) = 10             |
       +----------------+----------------+----------------+-------------------------+-------------------------+
       | 4              | (0,2)          | (4,0)          | (4,0) + (2,1) = (6,1)   | A(6,1) =  9             |
       +----------------+----------------+----------------+-------------------------+-------------------------+
       | 5              | (1,2)          | (4,1)          | (4,1) + (2,1) = (6,2)   | A(6,2) = 12             |
       +----------------+----------------+----------------+-------------------------+-------------------------+

    Constraints:

    The ``offset`` parameter is an ``int_tuple`` whose value is added — via
    ``cute.tuple_add`` semantics — to the result of
    ``cute.layout_eval(input_crd, B)``. The sum then flows as the indexing
    argument into ``A``. Because of this, the output profile of
    ``cute.layout_eval(input_crd, B)`` and ``A``'s input profile must be
    compatible.

    1. Profile compatibility with ``cute.layout_eval(input_crd, B)``. The
       sum ``offset + cute.layout_eval(input_crd, B)`` must produce a
       well-formed ``int_tuple`` that ``A`` can consume. In practice this
       means:

       - A scalar offset (``0``, any static integer, ``?``) is always safe
         when ``B`` has plain integer strides: ``cute.layout_eval`` returns a
         scalar integer and scalar + scalar is well-formed.

       - A tuple offset (e.g. ``(0,0)``, ``(1,2)``) is required when ``B``'s
         strides are scaled-basis in a way that makes ``cute.layout_eval``
         return a tuple.

    2. ``A`` is a swizzle. Swizzles consume only scalar indices, so
       the sum ``offset + cute.layout_eval(input_crd, B)`` must be a scalar
       (static or dynamic integer). Any surviving scaled-basis
       structure in the sum is rejected.

    3. ``A`` is a layout (affine). The sum either is a scalar (and
       ``A`` indexes it directly) or must match ``A``'s shape profile so
       each leaf of the sum dispatches to the corresponding mode of
       ``A``. Profile mismatches are rejected.

    4. Positive shape modes. All static shape leaves in ``B`` (and
       in ``A`` when ``A`` is a layout) must be positive.

    Assembly format — ``< "string" >`` where the string is the canonical
    printed form of the composed layout.

    **Examples**

    ```mlir
    !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">          // layout A
    !cute.composed_layout<"(4,5):(1,4) o (2,1) o (2,3):(1@1,2@0)">  // layout A + tuple offset
    !cute.composed_layout<"S<3,5,4> o 2 o (2,3):(1,2)">             // swizzle A
    !cute.composed_layout<"S<0,4,3> o 0 o (8,4):(1,8)">             // identity swizzle
    ```
  }];

  let parameters = (ins
    Cute_Param<"ComposedLayoutAttr", "Stores the underlying composed_layout value">:$attr
  );
  let hasCustomAssemblyFormat = 1;
  let genVerifyDecl = 1;

  let builders = [
    TypeBuilder<(ins "cutegen::composed_layout":$value), [{
      return $_get($_ctxt, ComposedLayoutAttr::get($_ctxt, std::move(value)));
    }]>
  ];

  let extraClassDeclaration = [{
    /// Underlying cutegen algebra type.
    using algebra_t = cutegen::composed_layout;
    /// Returns the underlying composed layout (delegates to the attribute).
    cutegen::composed_layout const &getRef() const { return getAttr().getRef(); }
  }];
}

//===----------------------------------------------------------------------===//
// SwizzleType
//===----------------------------------------------------------------------===//

def Cute_SwizzleType
    : Cute_Type<"Swizzle", "swizzle",
                [DeclareTypeInterfaceMethods<Cute_MaybeStaticTypeInterface>,
                 DeclareTypeInterfaceMethods<DataLayoutTypeInterface,
                     ["getTypeSize", "getTypeSizeInBits", "getABIAlignment",
                      "getPreferredAlignment", "getIndexBitwidth",
                      "areCompatible", "verifyEntries"]>]> {
  let summary = "CuTe swizzle: S<num_bits, num_base, num_shift>";
  let description = [{
    A ``Swizzle`` models a CuTe swizzle function — a bit-manipulation
    transformation parameterized by three compile-time integers:

    - ``num_bits``: the number of bits involved in the XOR
    - ``num_base``: the base bit position
    - ``num_shift``: the shift amount

    Swizzle has no dynamic parts, it is always static.

    Assembly format — ``< "string" >`` where the string is the canonical
    printed form ``S<num_bits,num_base,num_shift>``.

    **Examples**

    ```mlir
    !cute.swizzle<"S<0,4,3>">  // canonical identity swizzle
    !cute.swizzle<"S<3,5,4>">  // non-identity swizzle
    !cute.swizzle<"S<1,0,2>">  // example from CuTe GEMM kernels
    ```
  }];

  let parameters = (ins
    Cute_Param<"SwizzleAttr", "Stores the underlying swizzle value">:$attr
  );
  let hasCustomAssemblyFormat = 1;
  let genVerifyDecl = 1;

  let builders = [
    TypeBuilder<(ins "cutegen::swizzle":$value), [{
      return $_get($_ctxt, SwizzleAttr::get($_ctxt, std::move(value)));
    }]>
  ];

  let extraClassDeclaration = [{
    /// Underlying cutegen algebra type.
    using algebra_t = cutegen::swizzle;
    /// Returns the underlying swizzle (delegates to the attribute).
    cutegen::swizzle const &getRef() const { return getAttr().getRef(); }
  }];
}

//===----------------------------------------------------------------------===//
// Type constraints used by cute dialect ops
//===----------------------------------------------------------------------===//

/// Depth-0 int_tuple type -> an integer value
def Cute_Depth0IntTupleType : Type<
  And<[
    CPred<"::llvm::isa<::mlir::cutlass_compiler::cute::IntTupleType>($_self)">,
    CPred<"cutegen::depth(::llvm::cast<::mlir::cutlass_compiler::cute::IntTupleType>($_self).getRef()) == 0">
  ]>, "depth-0 !cute.int_tuple", Cute_IntTupleType.cppType>;

/// Integer type -> any integer value cute constructor ops accept
def Cute_IntegerType
    : AnyTypeOf<[I32, I64, Cute_Depth0IntTupleType],
                "i32, i64, or depth-0 !cute.int_tuple">;

def Cute_AnyLayoutType
    : AnyTypeOf<[Cute_LayoutType, Cute_ComposedLayoutType],
                "!cute.layout or !cute.composed_layout">;

/// CuTe types supporting mode-index operations (Get, Select).
def Cute_AnyIndexableType : AnyTypeOf<[Cute_ShapeType, Cute_IntTupleType,
                                       Cute_CoordType, Cute_StrideType,
                                       Cute_TileType, Cute_LayoutType,
                                       Cute_ComposedLayoutType],
    "!cute.shape, !cute.int_tuple, !cute.coord, !cute.stride, "
    "!cute.tile, !cute.layout, or !cute.composed_layout">;

/// Types that support element-wise arithmetic: int_tuple and shape only.
def Cute_ArithTupleType
    : AnyTypeOf<[Cute_IntTupleType, Cute_ShapeType],
                "!cute.int_tuple or !cute.shape">;

/// Tuple-like CuTe types, excludes layouts and composed layouts.
/// These type could be casted to int_tuples.
def Cute_AnyTupleType : AnyTypeOf<[Cute_ShapeType, Cute_StrideType,
                                   Cute_CoordType, Cute_IntTupleType,
                                   Cute_TileType],
    "!cute.shape, !cute.stride, !cute.coord, !cute.int_tuple, or !cute.tile">;

/// CuTe types supporting cute.slice / cute.dice operand. Tuple kinds
/// (shape / stride / int_tuple / coord) plus the two layout kinds. Tile
/// is excluded — mode-pick on a tile is expressed via cute.select.
def Cute_SliceableType : AnyTypeOf<[Cute_ShapeType, Cute_StrideType,
                                    Cute_CoordType, Cute_IntTupleType,
                                    Cute_LayoutType,
                                    Cute_ComposedLayoutType],
    "!cute.shape, !cute.stride, !cute.coord, !cute.int_tuple, "
    "!cute.layout, or !cute.composed_layout">;
#endif // CUTE_IR_DIALECT_CUTE_IR_CUTE_TYPES_TD
