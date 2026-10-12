//===- CuteAttrs.td - Cute dialect attribute definitions -------*- tablegen -*-===//
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

#ifndef CUTE_IR_DIALECT_CUTE_IR_CUTE_ATTRS_TD
#define CUTE_IR_DIALECT_CUTE_IR_CUTE_ATTRS_TD

include "mlir/IR/OpBase.td"
include "cute_ir/Dialect/Cute/IR/CuteDialect.td"

//===----------------------------------------------------------------------===//
// IntTupleAttr
//===----------------------------------------------------------------------===//

def Cute_IntTupleAttr : Cute_Attr<"IntTuple", "int_tuple"> {
  let summary = "Compile-time int_tuple value";
  let description = [{
    Attribute that stores a compile-time ``int_tuple`` value — a scalar
    integer or a recursive tuple of integers. Used as the sole ODS
    parameter of ``!cute.int_tuple``.

    Leaf forms in the assembly string:

    - static integer (e.g. ``1``, ``32``): compile-time constant.
    - ``?``: dynamic (runtime) integer, default i32 width.
    - ``?{i64}``: dynamic integer, i64 width.

    The attribute uses a quoted-string assembly format. The string
    content matches the canonical textual form of an ``int_tuple``.

    ```
    #cute.int_tuple<"1">           // scalar static 1
    #cute.int_tuple<"?">           // scalar dynamic (i32)
    #cute.int_tuple<"?{i64}">      // scalar dynamic (i64)
    #cute.int_tuple<"(1,2)">       // depth-1 rank-2 tuple
    #cute.int_tuple<"(1,(2,3))">   // depth-2 nested tuple
    #cute.int_tuple<"(?,32)">      // depth-1, first dynamic, second static 32
    ```
  }];

  let parameters = (ins
    Cute_Param<"cutegen::int_tuple", "stored int_tuple value">:$value
  );
  let genStorageClass = 0;
  let hasCustomAssemblyFormat = 1;

  let skipDefaultBuilders = 1;
  let builders = [
    AttrBuilder<(ins "cutegen::int_tuple":$value), [{
      // Nullify SSA-tied dynamic leaves so the stored attr is
      // purely structural and canonicalizes identically whether
      // parser- or programmatically-built.
      cutegen::nullify_dynamics(value);
      assert(cutegen::are_dynamics_null(value));
      return $_get($_ctxt, std::move(value));
    }]>
  ];

  let extraClassDeclaration = [{
    /// Underlying cutegen algebra type.
    using algebra_t = cutegen::int_tuple;
    /// Returns the underlying int_tuple value.
    cutegen::int_tuple const &getRef() const;
  }];
}

//===----------------------------------------------------------------------===//
// CoordAttr
//===----------------------------------------------------------------------===//

def Cute_CoordAttr : Cute_Attr<"Coord", "coord"> {
  let summary = "Compile-time coord value";
  let description = [{
    Attribute that stores a compile-time ``coord`` value — a scalar or
    recursive tuple of coordinate elements. Used as the sole ODS
    parameter of ``!cute.coord``.

    Leaf forms in the assembly string:

    - static integer (e.g. ``1``, ``2``): compile-time constant.
    - underscore (``_``): the CuTe slice wildcard; keeps the corresponding mode.
    - ``?``: dynamic (runtime) integer, default i32 width.
    - ``?{i64}``: dynamic integer, i64 width.

    The attribute uses a quoted-string assembly format. The string
    content matches the canonical textual form of a ``coord``.

    ```
    #cute.coord<"1">           // scalar static 1
    #cute.coord<"_">           // underscore (slice wildcard)
    #cute.coord<"?">           // scalar dynamic
    #cute.coord<"(1,2)">       // rank-2 static coord
    #cute.coord<"(_,?)">       // rank-2: underscore + dynamic
    #cute.coord<"(_,_,?)">     // rank-3: two underscores + dynamic
    #cute.coord<"(1,(2,3))">   // depth-2 nested coord
    ```
  }];

  let parameters = (ins
    Cute_Param<"cutegen::coord", "stored coord value">:$value
  );
  let genStorageClass = 0;
  let hasCustomAssemblyFormat = 1;

  let skipDefaultBuilders = 1;
  let builders = [
    AttrBuilder<(ins "cutegen::coord":$value), [{
      // Nullify SSA-tied dynamic leaves so the stored attr is
      // purely structural and canonicalizes identically whether
      // parser- or programmatically-built.
      cutegen::nullify_dynamics(value);
      assert(cutegen::are_dynamics_null(value));
      return $_get($_ctxt, std::move(value));
    }]>
  ];

  let extraClassDeclaration = [{
    /// Underlying cutegen algebra type.
    using algebra_t = cutegen::coord;
    /// Returns the underlying coord value.
    cutegen::coord const &getRef() const;
  }];
}

//===----------------------------------------------------------------------===//
// ShapeAttr
//===----------------------------------------------------------------------===//

def Cute_ShapeAttr : Cute_Attr<"Shape", "shape"> {
  let summary = "Compile-time shape value";
  let description = [{
    Attribute that stores a compile-time ``shape`` value — a scalar
    integer or a recursive tuple of shape extents. Used as the sole
    ODS parameter of ``!cute.shape``.

    Leaf forms in the assembly string:

    - static integer (e.g. ``1``, ``32``): compile-time constant.
    - ``?``: dynamic (runtime) integer, default i32 width.
    - ``?{i64}``: dynamic integer, i64 width.

    The attribute uses a quoted-string assembly format. The string
    content matches the canonical textual form of a ``shape``.

    ```
    #cute.shape<"1">           // scalar static 1
    #cute.shape<"?">           // scalar dynamic (i32)
    #cute.shape<"?{i64}">      // scalar dynamic (i64)
    #cute.shape<"(1,2)">       // rank-2 static shape
    #cute.shape<"(?,32)">      // rank-2: dynamic + static 32
    #cute.shape<"(1,(2,3))">   // depth-2 nested shape
    ```
  }];

  let parameters = (ins
    Cute_Param<"cutegen::shape", "stored shape value">:$value
  );
  let genStorageClass = 0;
  let hasCustomAssemblyFormat = 1;

  let skipDefaultBuilders = 1;
  let builders = [
    AttrBuilder<(ins "cutegen::shape":$value), [{
      // Nullify SSA-tied dynamic leaves so the stored attr is
      // purely structural and canonicalizes identically whether
      // parser- or programmatically-built.
      cutegen::nullify_dynamics(value);
      assert(cutegen::are_dynamics_null(value));
      return $_get($_ctxt, std::move(value));
    }]>
  ];

  let extraClassDeclaration = [{
    /// Underlying cutegen algebra type.
    using algebra_t = cutegen::shape;
    /// Returns the underlying shape value.
    cutegen::shape const &getRef() const;
  }];
}

//===----------------------------------------------------------------------===//
// StrideAttr
//===----------------------------------------------------------------------===//

def Cute_StrideAttr : Cute_Attr<"Stride", "stride"> {
  let summary = "Compile-time stride value";
  let description = [{
    Attribute that stores a compile-time ``stride`` value — a scalar or
    recursive tuple of stride elements. Used as the sole ODS parameter
    of ``!cute.stride``.

    Leaf forms in the assembly string:

    - static integer (e.g. ``1``, ``16``): compile-time constant.
    - ``?``: dynamic (runtime) integer, default i32 width.
    - ``?{i64}``: dynamic integer, i64 width.
    - scaled basis (``V@M``): a value scaled by basis vector mode ``M``;
      ``V`` may be static (e.g. ``4@0``) or dynamic (e.g. ``?@0``).

    The attribute uses a quoted-string assembly format. The string
    content matches the canonical textual form of a ``stride``.

    ```
    #cute.stride<"1">           // scalar static stride 1
    #cute.stride<"?">           // scalar dynamic stride
    #cute.stride<"4@0">         // static scaled basis: 4 × e_0
    #cute.stride<"?@0">         // dynamic scaled basis: ? × e_0
    #cute.stride<"(16,32)">     // rank-2 static stride
    #cute.stride<"(16,?)">      // rank-2: static + dynamic
    #cute.stride<"(16,?@0)">    // rank-2: static + dynamic scaled basis
    #cute.stride<"(16,(32,4))"> // depth-2 nested stride
    ```
  }];

  let parameters = (ins
    Cute_Param<"cutegen::stride", "stored stride value">:$value
  );
  let genStorageClass = 0;
  let hasCustomAssemblyFormat = 1;

  let skipDefaultBuilders = 1;
  let builders = [
    AttrBuilder<(ins "cutegen::stride":$value), [{
      // Nullify SSA-tied dynamic leaves so the stored attr is
      // purely structural and canonicalizes identically whether
      // parser- or programmatically-built.
      cutegen::nullify_dynamics(value);
      assert(cutegen::are_dynamics_null(value));
      return $_get($_ctxt, std::move(value));
    }]>
  ];

  let extraClassDeclaration = [{
    /// Underlying cutegen algebra type.
    using algebra_t = cutegen::stride;
    /// Returns the underlying stride value.
    cutegen::stride const &getRef() const;
  }];
}

//===----------------------------------------------------------------------===//
// LayoutAttr
//===----------------------------------------------------------------------===//

def Cute_LayoutAttr : Cute_Attr<"Layout", "layout"> {
  let summary = "Compile-time layout value";
  let description = [{
    Attribute that stores a compile-time ``layout`` value — a
    shape/stride pair. Used as the sole ODS parameter of
    ``!cute.layout``.

    The attribute uses a quoted-string assembly format. The string
    content matches the canonical textual form of a ``layout``
    (``shape:stride``).

    ```
    #cute.layout<"(2,3):(1,2)">                 // static rank-2 layout
    #cute.layout<"(2,3):(?,2)">                 // dynamic stride element
    #cute.layout<"((2,3),(4,5)):((1,2),(3,4))"> // nested shape and stride
    ```
  }];

  let parameters = (ins
    Cute_Param<"cutegen::layout", "stored layout value">:$value
  );
  let genStorageClass = 0;
  let hasCustomAssemblyFormat = 1;

  let skipDefaultBuilders = 1;
  let builders = [
    AttrBuilder<(ins "cutegen::layout":$value), [{
      // Nullify SSA-tied dynamic leaves so the stored attr is
      // purely structural and canonicalizes identically whether
      // parser- or programmatically-built.
      cutegen::nullify_dynamics(value);
      assert(cutegen::are_dynamics_null(value));
      return $_get($_ctxt, std::move(value));
    }]>
  ];

  let extraClassDeclaration = [{
    /// Underlying cutegen algebra type.
    using algebra_t = cutegen::layout;
    /// Returns the underlying layout value.
    cutegen::layout const &getRef() const;
  }];
}

//===----------------------------------------------------------------------===//
// TileAttr
//===----------------------------------------------------------------------===//

def Cute_TileAttr : Cute_Attr<"Tile", "tile"> {
  let summary = "Compile-time tile value";
  let description = [{
    Attribute that stores a compile-time ``tile`` value — a recursive
    sequence of layouts and underscore wildcards. Used as the sole ODS
    parameter of ``!cute.tile``.

    Leaf forms:

    - layout: a shape/stride pair (e.g. ``(2,3):(1,2)``).
    - underscore (``_``): the CuTe slice wildcard.

    The attribute uses a quoted-string assembly format. The string
    content matches the canonical textual form of a ``tile``: square
    brackets with elements separated by semicolons.

    ```
    #cute.tile<"[(2,3):(1,2)]">              // single-layout tile
    #cute.tile<"[(2,3):(1,2);(4,5):(1,4)]"> // two layouts
    #cute.tile<"[_]">                        // underscore tile
    #cute.tile<"[(2,3):(1,2);_]">           // layout + underscore
    ```
  }];

  let parameters = (ins
    Cute_Param<"cutegen::tile", "stored tile value">:$value
  );
  let genStorageClass = 0;
  let hasCustomAssemblyFormat = 1;

  let skipDefaultBuilders = 1;
  let builders = [
    AttrBuilder<(ins "cutegen::tile":$value), [{
      // Nullify SSA-tied dynamic leaves so the stored attr is
      // purely structural and canonicalizes identically whether
      // parser- or programmatically-built.
      cutegen::nullify_dynamics(value);
      assert(cutegen::are_dynamics_null(value));
      return $_get($_ctxt, std::move(value));
    }]>
  ];

  let extraClassDeclaration = [{
    /// Underlying cutegen algebra type.
    using algebra_t = cutegen::tile;
    /// Returns the underlying tile value.
    cutegen::tile const &getRef() const;
  }];
}

//===----------------------------------------------------------------------===//
// ComposedLayoutAttr
//===----------------------------------------------------------------------===//

def Cute_ComposedLayoutAttr : Cute_Attr<"ComposedLayout", "composed_layout"> {
  let summary = "Compile-time composed_layout value";
  let description = [{
    Attribute that stores a compile-time ``composed_layout`` value — a
    composition ``A o offset o B`` where ``A`` is either a layout or a
    swizzle, ``offset`` is an integer tuple, and ``B`` is the base layout.
    Used as the sole ODS parameter of ``!cute.composed_layout``.

    The attribute uses a quoted-string assembly format. The string
    content matches the canonical textual form of a ``composed_layout``.

    ```
    #cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">  // layout composition
    #cute.composed_layout<"S<3,5,4> o 2 o (2,3):(1,2)">      // swizzle composition
    ```
  }];

  let parameters = (ins
    Cute_Param<"cutegen::composed_layout", "stored composed_layout value">:$value
  );
  let genStorageClass = 0;
  let hasCustomAssemblyFormat = 1;

  let skipDefaultBuilders = 1;
  let builders = [
    AttrBuilder<(ins "cutegen::composed_layout":$value), [{
      // Nullify SSA-tied dynamic leaves so the stored attr is
      // purely structural and canonicalizes identically whether
      // parser- or programmatically-built.
      cutegen::nullify_dynamics(value);
      assert(cutegen::are_dynamics_null(value));
      return $_get($_ctxt, std::move(value));
    }]>
  ];

  let extraClassDeclaration = [{
    /// Underlying cutegen algebra type.
    using algebra_t = cutegen::composed_layout;
    /// Returns the underlying composed_layout value.
    cutegen::composed_layout const &getRef() const;
  }];
}

//===----------------------------------------------------------------------===//
// SwizzleAttr
//===----------------------------------------------------------------------===//

def Cute_SwizzleAttr : Cute_Attr<"Swizzle", "swizzle"> {
  let summary = "Compile-time swizzle value";
  let description = [{
    Attribute that stores a compile-time ``swizzle`` value — a
    bit-manipulation transformation parameterized by ``num_bits``,
    ``num_base``, and ``num_shift``. Used as the sole ODS parameter of
    ``!cute.swizzle``.

    Swizzle has no dynamic parts; ``isStatic()`` always returns ``true``.

    The attribute uses a quoted-string assembly format. The string
    content matches the canonical textual form
    ``S<num_bits,num_base,num_shift>``.

    ```
    #cute.swizzle<"S<0,4,3>">  // canonical identity swizzle
    #cute.swizzle<"S<3,5,4>">  // non-identity swizzle
    ```
  }];

  let parameters = (ins
    Cute_Param<"cutegen::swizzle", "stored swizzle value">:$value
  );
  let genStorageClass = 0;
  let hasCustomAssemblyFormat = 1;

  let skipDefaultBuilders = 1;
  let builders = [
    AttrBuilder<(ins "cutegen::swizzle":$value), [{
      // Nullify SSA-tied dynamic leaves so the stored attr is
      // purely structural and canonicalizes identically whether
      // parser- or programmatically-built.
      cutegen::nullify_dynamics(value);
      assert(cutegen::are_dynamics_null(value));
      return $_get($_ctxt, std::move(value));
    }]>
  ];

  let extraClassDeclaration = [{
    /// Underlying cutegen algebra type.
    using algebra_t = cutegen::swizzle;
    /// Returns the underlying swizzle value.
    cutegen::swizzle const &getRef() const;
  }];
}

#endif // CUTE_IR_DIALECT_CUTE_IR_CUTE_ATTRS_TD
