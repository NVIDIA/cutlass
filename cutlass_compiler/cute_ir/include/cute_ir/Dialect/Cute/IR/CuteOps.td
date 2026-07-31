//===- CuteOps.td - Cute dialect op definitions -------------*- tablegen -*-===//
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

#ifndef CUTE_IR_DIALECT_CUTE_IR_CUTE_OPS_TD
#define CUTE_IR_DIALECT_CUTE_IR_CUTE_OPS_TD

include "cute_ir/Dialect/Cute/IR/CuteDialect.td"
include "cute_ir/Dialect/Cute/IR/CuteTypes.td"
include "mlir/Interfaces/InferTypeOpInterface.td"
include "mlir/Interfaces/SideEffectInterfaces.td"

//===----------------------------------------------------------------------===//
// StaticOp
//===----------------------------------------------------------------------===//

def Cute_StaticOp : Cute_Op<"static", [Pure, ConstantLike]> {
  let cuteSpecGroup = "Constructor";
  let summary = "Materialize a compile-time constant CuTe value";
  let description = [{
    Produces a compile-time constant whose value is fully encoded in the
    result type. Takes no operands. Two ``cute.static`` ops with identical
    result types represent the same value.

    **Preconditions**

    - None — this op takes no operands.

    **Postconditions**

    - The result is a static CuTe type with no dynamic (``?``) slots.
    - Accepts any of ``!cute.layout``, ``!cute.shape``, ``!cute.stride``,
      ``!cute.tile``, ``!cute.swizzle``, ``!cute.composed_layout``,
      ``!cute.int_tuple``, or ``!cute.coord`` (each with no ``?`` slots).

    **Examples**

    ```mlir
    %0 = cute.static : !cute.layout<"(2,3):(1,2)">
    %1 = cute.static : !cute.stride<"(1,4)">
    %2 = cute.static : !cute.shape<"5">
    ```
  }];

  let arguments = (ins);
  let results = (outs Cute_Arg<Cute_MaybeStaticTypeInterface, "static CuTe value">:$result);
  let assemblyFormat = "attr-dict `:` type($result)";

  let hasVerifier = 1;
  let hasFolder = 1;
}

//===----------------------------------------------------------------------===//
// PrintOp
//===----------------------------------------------------------------------===//

def Cute_AnyType : AnyTypeOf<[
    Cute_IntTupleType, Cute_CoordType,
    Cute_ShapeType, Cute_StrideType, Cute_LayoutType,
    Cute_TileType, Cute_ComposedLayoutType, Cute_SwizzleType
], "any CuTe type">;

def Cute_PrintOp : Cute_Op<"print", [MemoryEffects<[MemWrite]>]> {
  let cuteSpecGroup = "Diagnostics";
  let summary = "Print a CuTe value at runtime for debugging";
  let description = [{
    Prints the runtime value of a CuTe operand to stdout for debugging.
    Has side effects. Produces no result.

    **Preconditions**

    - ``$value`` is any CuTe type (static or dynamic, scalar or tuple).

    **Postconditions**

    - None — this op produces no result.

    **Examples**

    ```mlir
    cute.print(%x) : !cute.layout<"(2,3):(1,2)">
    cute.print(%y) : !cute.stride<"?">
    ```
  }];

  let arguments = (ins Cute_Arg<Cute_AnyType, "CuTe value to print">:$value);
  let results = (outs);
  let assemblyFormat = "`(` $value `)` `:` type($value) attr-dict";
}

//===----------------------------------------------------------------------===//
// MakeIntTupleOp
//===----------------------------------------------------------------------===//

def Cute_MakeIntTupleOp : Cute_Op<"make_int_tuple", [Pure]> {
  let cuteSpecGroup = "Constructor";
  let summary = "Construct an IntTuple from its runtime-valued leaves";
  let description = [{
    Constructs an ``!cute.int_tuple`` by supplying runtime values for its
    dynamic slots. The result type specifies the full tuple structure;
    static values are encoded in the type itself and require no operand.
    Each ``?`` (dynamic) slot in the result type requires exactly one
    operand, supplied left-to-right in depth-first traversal order
    across the tuple tree. Zero operands are valid when the result type
    has no ``?`` slots (fully static).

    **Preconditions**

    - Each operand fills one ``?`` slot, in depth-first left-to-right order:

      - ``i32`` or ``i64`` fills a scalar ``?`` leaf; bit-width must match the
        slot's width annotation.

      - rank-1 ``!cute.int_tuple`` (holding a single integer or dynamic-
        integer element) fills a nested sub-tuple slot; higher-rank
        sub-tuples are rejected.

    - The number of operands equals the number of ``?`` slots in the
      result type.

    **Postconditions**

    - Result is the ``!cute.int_tuple`` whose structure matches the result
      type and whose dynamic leaves take the operand values.

    **Examples**

    ```mlir
    // fully static — no operands
    %t = cute.make_int_tuple() : () -> !cute.int_tuple<"4">

    // scalar dynamic — one i32 leaf
    %t = cute.make_int_tuple(%n) : (i32) -> !cute.int_tuple<"?">

    // flat tuple, two dynamic leaves
    %t = cute.make_int_tuple(%m, %n) : (i32, i32) -> !cute.int_tuple<"(?,?)">

    // nested sub-tuple as operand
    %inner = cute.make_int_tuple(%k) : (i32) -> !cute.int_tuple<"?">
    %t = cute.make_int_tuple(%m, %inner)
           : (i32, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?,?)">

    // fully static tuple — no operands
    %t = cute.make_int_tuple() : () -> !cute.int_tuple<"(4,3)">
    ```

    **Errors**

    - too few operands for the `?` slots

      ```mlir
      %0 = cute.make_int_tuple(%n) : (i64) -> !cute.int_tuple<"(?,?)">
      ```

    - too many operands for the `?` slots

      ```mlir
      %0 = cute.make_int_tuple(%m, %n) : (i64, i64) -> !cute.int_tuple<"(?,3)">
      ```

    - operand width mismatch (i64 supplied for an i32-width `?` slot)

      ```mlir
      %0 = cute.make_int_tuple(%n) : (i64) -> !cute.int_tuple<"?">
      ```

    - depth>0 int_tuple operand rejected

      ```mlir
      %0 = cute.make_int_tuple(%t)
             : (!cute.int_tuple<"(?,?)">) -> !cute.int_tuple<"(?,?)">
      ```
  }];

  let arguments = (ins
    Cute_Arg<Variadic<Cute_IntegerType>, "dynamic elements">:$operands
  );
  let results = (outs
    Cute_Arg<Cute_IntTupleType, "assembled int_tuple">:$result
  );
  let assemblyFormat = [{ `(` $operands `)` attr-dict `:` functional-type($operands, $result) }];

  let builders = [
    /// Algebra-type convenience builder: derives the result type and
    /// dynamic operand list from the given int_tuple value.
    OpBuilder<(ins "cutegen::int_tuple":$val), [{
      llvm::SmallVector<cutegen::mlir_dynamic_t> dynModes;
      cutegen::collect_dynamics(dynModes, val);
      llvm::SmallVector<mlir::Value> dynElems;
      dynElems.reserve(dynModes.size());
      for (const auto &d : dynModes) {
        assert(d.get_value() && "mlir_dynamic_t must carry an mlir::Value");
        mlir::Value v = d.get_value();
        dynElems.push_back(v);
      }
      build($_builder, $_state,
            IntTupleType::get($_builder.getContext(), val), dynElems);
    }]>
  ];

  let hasVerifier = 1;
}

//===----------------------------------------------------------------------===//
// MakeShapeOp
//===----------------------------------------------------------------------===//

def Cute_MakeShapeOp : Cute_Op<"make_shape", [Pure]> {
  let cuteSpecGroup = "Constructor";

  let summary = "Construct a Shape from its runtime-valued leaves";
  let description = [{
    Constructs a ``!cute.shape`` by supplying runtime values for its
    dynamic slots. The result type specifies the full shape structure;
    static extents are encoded in the type itself and require no
    operand. Each ``?`` (dynamic) extent in the result type requires
    exactly one operand, supplied left-to-right in depth-first traversal
    order across the shape tree. Zero operands are valid when the
    result type has no ``?`` slots (fully static).

    **Preconditions**

    - Each operand fills one ``?`` slot, in depth-first left-to-right order:

      - ``i32`` or ``i64`` fills a scalar ``?`` extent; bit-width must match
        the slot's width annotation.

      - rank-1 ``!cute.shape`` fills a nested sub-shape slot; higher-rank
        sub-shapes are rejected.

    - The number of operands equals the number of ``?`` slots in the
      result type.

    **Postconditions**

    - Result is the ``!cute.shape`` whose structure matches the result
      type and whose dynamic leaves take the operand values.

    **Examples**

    ```mlir
    %s = cute.make_shape() : () -> !cute.shape<"(128,64)">
    %s = cute.make_shape(%m, %n) : (i32, i32) -> !cute.shape<"(?,?)">
    %s = cute.make_shape(%m) : (i32) -> !cute.shape<"(?,64)">
    ```

    **Errors**

    - too few operands for the `?` slots

      ```mlir
      %0 = cute.make_shape(%n) : (i64) -> !cute.shape<"(?,?)">
      ```

    - too many operands for the `?` slots

      ```mlir
      %0 = cute.make_shape(%m, %n) : (i64, i64) -> !cute.shape<"(?,3)">
      ```

    - operand width mismatch (i64 supplied for an i32-width `?` slot)

      ```mlir
      %0 = cute.make_shape(%n) : (i64) -> !cute.shape<"?">
      ```

    - non-integer-leaf operand rejected at ODS level

      ```mlir
      %0 = cute.make_shape(%t) : (!cute.shape<"(?,?)">) -> !cute.shape<"(?,?)">
      ```
  }];

  let arguments = (ins
    Cute_Arg<Variadic<Cute_IntegerType>, "dynamic elements">:$operands
  );
  let results = (outs
    Cute_Arg<Cute_ShapeType, "assembled shape">:$result
  );
  let assemblyFormat = [{ `(` $operands `)` attr-dict `:` functional-type($operands, $result) }];

  let builders = [
    /// Algebra-type convenience builder: derives the result type and
    /// dynamic operand list from the given shape value.
    OpBuilder<(ins "cutegen::shape":$val), [{
      llvm::SmallVector<cutegen::mlir_dynamic_t> dynModes;
      cutegen::collect_dynamics(dynModes, val);
      llvm::SmallVector<mlir::Value> dynElems;
      dynElems.reserve(dynModes.size());
      for (const auto &d : dynModes) {
        assert(d.get_value() && "mlir_dynamic_t must carry an mlir::Value");
        mlir::Value v = d.get_value();
        dynElems.push_back(v);
      }
      build($_builder, $_state,
            ShapeType::get($_builder.getContext(), val), dynElems);
    }]>
  ];

  let hasVerifier = 1;
}

//===----------------------------------------------------------------------===//
// MakeStrideOp
//===----------------------------------------------------------------------===//

def Cute_MakeStrideOp : Cute_Op<"make_stride", [Pure]> {
  let cuteSpecGroup = "Constructor";
  let summary = "Construct a Stride from its runtime-valued leaves";
  let description = [{
    Constructs a ``!cute.stride`` by supplying runtime values for its
    dynamic slots. The result type specifies the full stride structure;
    static strides and static scaled-basis elements (e.g. ``4@0``) are
    encoded in the type itself and require no operand. Each ``?`` slot —
    including the dynamic scale component of a ``?@M`` (dynamic-scale,
    static-basis) element — requires exactly one operand, supplied
    left-to-right in depth-first traversal order. Zero operands are
    valid when the result type has no ``?`` slots (fully static).

    **Preconditions**

    - Each operand fills one ``?`` slot, in depth-first left-to-right order:

      - ``i32`` or ``i64`` fills a scalar ``?`` stride or the dynamic scale of
        a ``?@M`` element; bit-width must match the slot's width annotation.

      - rank-1 ``!cute.stride`` fills a nested sub-stride slot; higher-rank
        sub-strides are rejected.

    - The number of operands equals the number of ``?`` slots in the
      result type.

    **Postconditions**

    - Result is the ``!cute.stride`` whose structure matches the result
      type and whose dynamic leaves take the operand values.

    **Examples**

    ```mlir
    %d = cute.make_stride() : () -> !cute.stride<"(1,4)">
    %d = cute.make_stride(%s) : (i32) -> !cute.stride<"?">
    %d = cute.make_stride(%s) : (i32) -> !cute.stride<"?@0">
    %d = cute.make_stride() : () -> !cute.stride<"4@0">
    ```

    **Errors**

    - too few operands for the `?` slots

      ```mlir
      %0 = cute.make_stride(%s) : (i64) -> !cute.stride<"(?,?)">
      ```

    - too many operands for the `?` slots

      ```mlir
      %0 = cute.make_stride(%s, %t) : (i64, i64) -> !cute.stride<"(1,?)">
      ```

    - operand width mismatch (i64 supplied for an i32-width `?` slot)

      ```mlir
      %0 = cute.make_stride(%s) : (i64) -> !cute.stride<"?">
      ```

    - non-integer-leaf operand rejected at ODS level

      ```mlir
      %0 = cute.make_stride(%t) : (!cute.stride<"(?,?)">) -> !cute.stride<"(?,?)">
      ```
  }];

  let arguments = (ins
    Cute_Arg<Variadic<Cute_IntegerType>, "dynamic elements">:$operands
  );
  let results = (outs
    Cute_Arg<Cute_StrideType, "assembled stride">:$result
  );
  let assemblyFormat = [{ `(` $operands `)` attr-dict `:` functional-type($operands, $result) }];

  let builders = [
    /// Algebra-type convenience builder: derives the result type and
    /// dynamic operand list from the given stride value.
    OpBuilder<(ins "cutegen::stride":$val), [{
      llvm::SmallVector<cutegen::mlir_dynamic_t> dynModes;
      cutegen::collect_dynamics(dynModes, val);
      llvm::SmallVector<mlir::Value> dynElems;
      dynElems.reserve(dynModes.size());
      for (const auto &d : dynModes) {
        assert(d.get_value() && "mlir_dynamic_t must carry an mlir::Value");
        mlir::Value v = d.get_value();
        dynElems.push_back(v);
      }
      build($_builder, $_state,
            StrideType::get($_builder.getContext(), val), dynElems);
    }]>
  ];

  let hasVerifier = 1;
}

//===----------------------------------------------------------------------===//
// MakeCoordOp
//===----------------------------------------------------------------------===//

def Cute_MakeCoordOp : Cute_Op<"make_coord", [Pure]> {
  let cuteSpecGroup = "Constructor";
  let summary = "Construct a Coord from its runtime-valued leaves";
  let description = [{
    Constructs a ``!cute.coord`` by supplying runtime values for its
    dynamic slots. The result type specifies the full coordinate
    structure; static values and underscore (``_``) placeholder slots are
    encoded in the type itself and require no operand. Each ``?``
    (dynamic) slot requires exactly one operand, supplied left-to-right
    in depth-first traversal order. Zero operands are valid when the
    result type has no ``?`` slots (fully static, or all dynamic-looking
    slots are underscores).

    **Preconditions**

    - Each operand fills one ``?`` slot, in depth-first left-to-right order:

      - ``i32`` or ``i64`` fills a scalar ``?`` coordinate component;
        bit-width must match the slot's width annotation.

      - rank-1 ``!cute.coord`` fills a nested sub-coord slot; higher-rank
        sub-coords are rejected.

    - Underscore (``_``) slots are static and consume no operand.
    - The number of operands equals the number of ``?`` slots in the
      result type.

    **Postconditions**

    - Result is the ``!cute.coord`` whose structure matches the result
      type and whose dynamic leaves take the operand values.

    **Examples**

    ```mlir
    %c = cute.make_coord() : () -> !cute.coord<"(1,2)">
    %c = cute.make_coord(%i, %j) : (i32, i32) -> !cute.coord<"(?,?)">
    %c = cute.make_coord(%i) : (i32) -> !cute.coord<"(?,_)">
    ```

    **Errors**

    - too few operands — underscore does not count as a dynamic leaf

      ```mlir
      %0 = cute.make_coord() : () -> !cute.coord<"(?,_)">
      ```

    - too many operands for the `?` slots

      ```mlir
      %0 = cute.make_coord(%i, %j) : (i64, i64) -> !cute.coord<"(?,2)">
      ```

    - operand width mismatch (i64 supplied for an i32-width `?` slot)

      ```mlir
      %0 = cute.make_coord(%i) : (i64) -> !cute.coord<"?">
      ```

    - non-integer-leaf operand rejected at ODS level

      ```mlir
      %0 = cute.make_coord(%t) : (!cute.coord<"(?,?)">) -> !cute.coord<"(?,?)">
      ```
  }];

  let arguments = (ins
    Cute_Arg<Variadic<Cute_IntegerType>, "dynamic elements">:$operands
  );
  let results = (outs
    Cute_Arg<Cute_CoordType, "assembled coord">:$result
  );
  let assemblyFormat = [{ `(` $operands `)` attr-dict `:` functional-type($operands, $result) }];

  let builders = [
    /// Algebra-type convenience builder: derives the result type and
    /// dynamic operand list from the given coord value.
    OpBuilder<(ins "cutegen::coord":$val), [{
      llvm::SmallVector<cutegen::mlir_dynamic_t> dynModes;
      cutegen::collect_dynamics(dynModes, val);
      llvm::SmallVector<mlir::Value> dynElems;
      dynElems.reserve(dynModes.size());
      for (const auto &d : dynModes) {
        assert(d.get_value() && "mlir_dynamic_t must carry an mlir::Value");
        mlir::Value v = d.get_value();
        dynElems.push_back(v);
      }
      build($_builder, $_state,
            CoordType::get($_builder.getContext(), val), dynElems);
    }]>
  ];

  let hasVerifier = 1;
}

//===----------------------------------------------------------------------===//
// MakeLayoutOp
//===----------------------------------------------------------------------===//

/// Operand to make_layout: shape or stride component.
def Cute_LayoutComponent
    : AnyTypeOf<[Cute_ShapeType, Cute_StrideType],
                "!cute.shape or !cute.stride">;

def Cute_MakeLayoutOp : Cute_Op<"make_layout",
    [Pure, DeclareOpInterfaceMethods<InferTypeOpInterface>]> {
  let cuteSpecGroup = "Constructor";
  let summary = "Construct a Layout from an explicit shape and stride";
  let description = [{
    Constructs a ``!cute.layout`` from a ``!cute.shape`` and a ``!cute.stride``
    operand. Both operands are required and must exactly match the
    shape and stride components of the result type.

    **Preconditions**

    - Operand ``$shape`` is a ``!cute.shape`` and exactly matches the
      result's shape.

    - Operand ``$stride`` is a ``!cute.stride`` and exactly matches the
      result's stride.

    **Postconditions**

    - Result is the ``!cute.layout`` whose shape and stride match the
      result type, with dynamic leaves taking values from the operands.

    **Examples**

    ```mlir
    %l = cute.make_layout(%s, %d)
           : (!cute.shape<"(?,2)">, !cute.stride<"(?,4)">) -> !cute.layout<"(?,2):(?,4)">
    ```

    **Errors**

    - shape operand does not match result shape

      ```mlir
      %l = cute.make_layout(%s, %d)
             : (!cute.shape<"(?,2)">, !cute.stride<"(?,4)">) -> !cute.layout<"(4,2):(?,4)">
      ```

    - stride operand does not match result stride

      ```mlir
      %l = cute.make_layout(%s, %d)
             : (!cute.shape<"(?,2)">, !cute.stride<"(?,8)">) -> !cute.layout<"(?,2):(?,4)">
      ```
  }];

  let arguments = (ins
    Cute_Arg<Cute_ShapeType, "shape">:$shape,
    Cute_Arg<Cute_StrideType, "stride">:$stride
  );
  let results = (outs
    Cute_Arg<Cute_LayoutType, "assembled layout">:$layout
  );
  let assemblyFormat = [{
    `(` $shape `,` $stride `)` attr-dict `:`
    functional-type(operands, $layout)
  }];

}

//===----------------------------------------------------------------------===//
// MakeTileOp
//===----------------------------------------------------------------------===//

def Cute_MakeTileOp : Cute_Op<"make_tile", [Pure]> {
  let cuteSpecGroup = "Constructor";
  let summary = "Construct a Tile from its runtime-valued integer leaves";
  let description = [{
    Constructs a ``!cute.tile`` by supplying runtime values for the
    dynamic integer leaves of its constituent layouts. A tile is a
    fixed-length tuple of layout slots and underscore (``_``) slots,
    fully described by the result type.

    Operands are assigned to ``?`` leaves across all constituent layouts
    in left-to-right, depth-first order: all dynamic leaves of the
    first layout slot are filled first, then the second, and so on.
    Underscore slots and fully-static layout slots carry no leaves and
    consume no operands. Zero operands are valid when every layout
    slot is fully static or underscore.

    **Preconditions**

    - Each operand fills one ``?`` leaf, in left-to-right depth-first
      order across all constituent layout shapes and strides:

      - ``i32`` or ``i64`` fills a scalar ``?`` leaf; bit-width must match
        the slot's width annotation.

      - rank-1 ``!cute.int_tuple`` fills a nested sub-tuple integer leaf;
        higher-rank sub-tuples are rejected.

    - Underscore (``_``) slots and fully-static layout slots consume no
      operand.

    - The number of operands equals the total count of ``?`` leaves
      across all constituent layout shapes and strides in the result
      type.

    **Postconditions**

    - Result is the ``!cute.tile`` whose layout slots, underscores, and
      dynamic-leaf values match the result type with operands filling
      the ``?`` slots in order.

    **Examples**

    ```mlir
    // fully static — no operands
    %t = cute.make_tile() : () -> !cute.tile<"[(2,3):(1,2)]">

    // underscore slot — no operands
    %t = cute.make_tile() : () -> !cute.tile<"[_]">

    // static layout + underscore — no operands
    %t = cute.make_tile() : () -> !cute.tile<"[(2,3):(1,2);_]">

    // one dynamic layout with 2 leaves (one shape ?, one stride ?)
    %t = cute.make_tile(%m, %n) : (i32, i32) -> !cute.tile<"[(?,3):(1,?)]">

    // dynamic layout + underscore (underscore contributes no leaves)
    %t = cute.make_tile(%m, %n) : (i32, i32) -> !cute.tile<"[(?,3):(1,?);_]">

    // two dynamic layouts, 2 leaves each
    %t = cute.make_tile(%m, %n, %p, %q) : (i32, i32, i32, i32)
           -> !cute.tile<"[(?,3):(1,?);(?,2):(1,?)]">
    ```

    **Errors**

    - too many operands for a fully-static tile

      ```mlir
      %t = cute.make_tile(%n) : (i64) -> !cute.tile<"[(2,3):(1,2)]">
      ```

    - too many operands for an underscore tile

      ```mlir
      %t = cute.make_tile(%n) : (i64) -> !cute.tile<"[_]">
      ```

    - too few operands for a dynamic layout slot

      ```mlir
      %t = cute.make_tile() : () -> !cute.tile<"[(?,3):(1,?)]">
      ```

    - operand width mismatch (i64 supplied for i32-width `?` leaf)

      ```mlir
      %t = cute.make_tile(%n) : (i64) -> !cute.tile<"[?:1]">
      ```

    - depth>0 int_tuple operand rejected at ODS level

      ```mlir
      %tile = cute.make_tile(%t)
                : (!cute.int_tuple<"(?,?)">) -> !cute.tile<"[(?,?):(1,?)]">
      ```
  }];

  let arguments = (ins
    Cute_Arg<Variadic<Cute_IntegerType>, "dynamic integer leaves">:$operands
  );
  let results = (outs
    Cute_Arg<Cute_TileType, "assembled tile">:$result
  );
  let assemblyFormat = [{ `(` $operands `)` attr-dict `:` functional-type($operands, $result) }];

  let builders = [
    /// Algebra-type convenience builder: derives the result type and
    /// dynamic operand list from the given tile value.
    OpBuilder<(ins "cutegen::tile":$val), [{
      llvm::SmallVector<cutegen::mlir_dynamic_t> dynModes;
      cutegen::collect_dynamics(dynModes, val);
      llvm::SmallVector<mlir::Value> dynElems;
      dynElems.reserve(dynModes.size());
      for (const auto &d : dynModes) {
        assert(d.get_value() && "mlir_dynamic_t must carry an mlir::Value");
        mlir::Value v = d.get_value();
        dynElems.push_back(v);
      }
      build($_builder, $_state,
            TileType::get($_builder.getContext(), val), dynElems);
    }]>
  ];

  let hasVerifier = 1;
}

//===----------------------------------------------------------------------===//
// MakeComposedLayoutOp
//===----------------------------------------------------------------------===//

/// Operand to make_composed_layout: the inner A component — either a layout or swizzle.
def Cute_InnerComponent
    : AnyTypeOf<[Cute_LayoutType, Cute_SwizzleType],
                "!cute.layout or !cute.swizzle">;

def Cute_MakeComposedLayoutOp : Cute_Op<"make_composed_layout",
    [Pure, DeclareOpInterfaceMethods<InferTypeOpInterface>]> {
  let cuteSpecGroup = "Constructor";
  let summary = "Construct a ComposedLayout from inner (layout or swizzle), offset, and outer";
  let description = [{
    Constructs a ``!cute.composed_layout`` from three operands. A
    composed layout represents the function composition
    ``inner ∘ offset ∘ outer``. For a coordinate ``c``, evaluation proceeds
    as ``inner(offset + outer(c))``. The result type is inferred from the
    three operand types.

    **Preconditions**

    - ``$inner`` (the A component, applied last) is ``!cute.layout`` or
      ``!cute.swizzle``; its kind must match the A component encoded in
      the result type.

      - When ``$inner`` is ``!cute.layout``, the result A must be an affine
        layout that exactly matches the operand.

      - When ``$inner`` is ``!cute.swizzle``, the result A must be a
        swizzle whose parameters exactly match the operand.

    - ``$offset`` is ``!cute.int_tuple`` and exactly matches the offset
      component encoded in the result type.

    - ``$outer`` is ``!cute.layout`` (the B component, applied first) and
      exactly matches the B layout component of the result type.

    **Postconditions**

    - Result is the ``!cute.composed_layout`` whose A, offset, and B
      components match the three operands and the result type.

    **Examples**

    ```mlir
    // Layout A, scalar offset, static outer
    %cl = cute.make_composed_layout(%a, %off, %b)
            : (!cute.layout<"(4,5):(1,4)">, !cute.int_tuple<"2">,
               !cute.layout<"(2,3):(1,2)">)
           -> !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">

    // Swizzle A, zero offset, static outer
    %cl = cute.make_composed_layout(%sw, %off, %b)
            : (!cute.swizzle<"S<3,5,4>">, !cute.int_tuple<"0">,
               !cute.layout<"(8,4):(1,8)">)
           -> !cute.composed_layout<"S<3,5,4> o 0 o (8,4):(1,8)">
    ```

    **Errors**

    - inner layout does not match result A

      ```mlir
      %cl = cute.make_composed_layout(%a, %off, %b)
              : (!cute.layout<"(4,5):(2,8)">, !cute.int_tuple<"2">,
                 !cute.layout<"(2,3):(1,2)">)
             -> !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">
      ```

    - inner is a layout but result A is a swizzle

      ```mlir
      %cl = cute.make_composed_layout(%a, %off, %b)
              : (!cute.layout<"(4,5):(1,4)">, !cute.int_tuple<"2">,
                 !cute.layout<"(2,3):(1,2)">)
             -> !cute.composed_layout<"S<3,5,4> o 2 o (2,3):(1,2)">
      ```

    - inner is a swizzle but result A is a layout

      ```mlir
      %cl = cute.make_composed_layout(%sw, %off, %b)
              : (!cute.swizzle<"S<3,5,4>">, !cute.int_tuple<"2">,
                 !cute.layout<"(2,3):(1,2)">)
             -> !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">
      ```

    - swizzle params don't match result A

      ```mlir
      %cl = cute.make_composed_layout(%sw, %off, %b)
              : (!cute.swizzle<"S<1,5,4>">, !cute.int_tuple<"2">,
                 !cute.layout<"(2,3):(1,2)">)
             -> !cute.composed_layout<"S<3,5,4> o 2 o (2,3):(1,2)">
      ```

    - offset operand does not match result offset

      ```mlir
      %cl = cute.make_composed_layout(%a, %off, %b)
              : (!cute.layout<"(4,5):(1,4)">, !cute.int_tuple<"5">,
                 !cute.layout<"(2,3):(1,2)">)
             -> !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">
      ```
  }];

  let arguments = (ins
    Cute_Arg<Cute_InnerComponent, "inner layout or swizzle">:$inner,
    Cute_Arg<Cute_IntTupleType, "offset int_tuple">:$offset,
    Cute_Arg<Cute_LayoutType, "outer layout">:$outer
  );
  let results = (outs
    Cute_Arg<Cute_ComposedLayoutType, "assembled composed layout">:$result
  );
  let assemblyFormat = [{
    `(` $inner `,` $offset `,` $outer `)` attr-dict `:`
    `(` type($inner) `,` type($offset) `,` type($outer) `)` `->` type($result)
  }];
}


//===----------------------------------------------------------------------===//
// Advanced Constructors
//===----------------------------------------------------------------------===//

/// Tiler operand for divide ops: accepts any of the three CuTe tiler forms —
/// a layout (shape + strides), a tile (recursive layout/underscore sequence),
/// or a plain shape (extents only, mapped to a unit-stride tile internally).
def Cute_DividerType
    : AnyTypeOf<[Cute_LayoutType, Cute_TileType, Cute_ShapeType],
                "!cute.layout, !cute.tile, or !cute.shape">;

//===----------------------------------------------------------------------===//
// MakeLayoutLikeOp
//===----------------------------------------------------------------------===//

def Cute_MakeLayoutLikeOp : Cute_Op<"make_layout_like",
    [Pure, DeclareOpInterfaceMethods<InferTypeOpInterface>]> {
  let cuteSpecGroup = "AdvancedConstructors";
  let summary = "Compact layout with same shape and major-ness-ordered strides as source";
  let description = [{
    Given a source layout, produces a new compact layout that preserves
    the shape and the relative ordering of non-zero strides. The mode
    with the smallest non-zero source stride receives stride 1;
    remaining modes receive strides in ascending order of the source
    stride magnitudes. Modes with a zero stride in the source have
    their shape filtered to 1 for the ordering step, but the result
    shape is always the same as the source shape.

    If the source is a ``!cute.composed_layout``, the operation is
    applied to the B (outer) layout component and returns a plain
    ``!cute.layout``.

    **Preconditions**

    - ``$src`` is ``!cute.layout`` or ``!cute.composed_layout``.
    - When ``$src`` is ``!cute.layout``, its strides are plain integers
      (static or dynamic). Scaled-basis strides are rejected because
      ordering by magnitude is undefined for them.

    - When ``$src`` is ``!cute.composed_layout``:

      - the A component must be a Swizzle (a layout A is rejected);
      - the B (outer) layout's strides are plain integers (no
        scaled-basis).

    **Postconditions**

    - Result is a ``!cute.layout`` whose shape equals the source shape
      (or, for composed sources, the outer B layout's shape).

    - The result's strides are compact and ordered by the source's
      stride magnitudes (smallest non-zero stride becomes 1; others
      ascend in source-magnitude order).

    **Examples**

    ```mlir
    // Rank-1 strided layout → compact
    %r = cute.make_layout_like(%src) : !cute.layout<"8:2"> -> !cute.layout<"8:1">

    // Row-major layout — relative ordering preserved, strides normalized
    %r = cute.make_layout_like(%src)
           : !cute.layout<"(4,2):(4,1)"> -> !cute.layout<"(4,2):(2,1)">

    // Composed layout source — applies to outer B component
    %r = cute.make_layout_like(%src)
           : !cute.composed_layout<"S<3,4,3> o 6 o (8,2):(2,16)">
          -> !cute.layout<"(8,2):(1,8)">
    ```

    **Errors**

    - source is not a layout or composed_layout

      ```mlir
      %r = cute.make_layout_like(%src)
             : !cute.shape<"(4,2)"> -> !cute.layout<"(4,2):(1,4)">
      ```

    - scaled-basis strides in source layout

      ```mlir
      %r = cute.make_layout_like(%src)
             : !cute.layout<"(4,2):(1@0,1@1)"> -> !cute.layout<"(4,2):(1,4)">
      ```

    - composed source has a layout A (only Swizzle A is supported)

      ```mlir
      %r = cute.make_layout_like(%src)
             : !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">
            -> !cute.layout<"(2,3):(1,2)">
      ```
  }];

  let arguments = (ins
    Cute_Arg<Cute_AnyLayoutType, "source layout">:$src
  );
  let results = (outs
    Cute_Arg<Cute_LayoutType, "compact ordered layout">:$result
  );
  let assemblyFormat = "`(` $src `)` attr-dict `:` type($src) `->` qualified(type($result))";
}

//===----------------------------------------------------------------------===//
// MakeOrderedLayoutOp
//===----------------------------------------------------------------------===//

def Cute_MakeOrderedLayoutOp : Cute_Op<"make_ordered_layout",
    [Pure, DeclareOpInterfaceMethods<InferTypeOpInterface>]> {
  let cuteSpecGroup = "AdvancedConstructors";
  let summary = "Compact layout with strides in a user-specified mode ordering";
  let description = [{
    Constructs a compact layout from a shape and an explicit ordering
    tuple. The ordering tuple assigns a relative major-ness value to
    each mode: smaller values mean less major (smaller stride).
    Strides are computed as the compact prefix products of the shape
    in ascending order of the order values — the mode with the
    smallest order value receives stride 1.

    **Preconditions**

    - ``$shape`` is ``!cute.shape``; may contain dynamic (``?``) extents.
    - ``$order`` is ``!cute.int_tuple``, *weakly congruent* to ``$shape``:
      same hierarchical structure (rank and nesting depths match;
      leaf values may be scalars).

    - All order values in ``$order`` are static integers.

    **Postconditions**

    - Result shape equals ``$shape``.
    - Result strides are the compact prefix-product strides computed
      from ``$shape`` in ascending order of ``$order`` (smallest order
      value gets stride 1).

    **Examples**

    ```mlir
    // Col-major: order (0,1) → strides (1,4) for shape (4,2)
    %l = cute.make_ordered_layout(%s, %o)
           : (!cute.shape<"(4,2)">, !cute.int_tuple<"(0,1)">) -> !cute.layout<"(4,2):(1,4)">

    // Row-major: order (1,0) → strides (2,1) for shape (4,2)
    %l = cute.make_ordered_layout(%s, %o)
           : (!cute.shape<"(4,2)">, !cute.int_tuple<"(1,0)">) -> !cute.layout<"(4,2):(2,1)">

    // Dynamic shape extent
    %l = cute.make_ordered_layout(%s, %o)
           : (!cute.shape<"(4,3,?,2)">, !cute.int_tuple<"(2,1,3,4)">)
          -> !cute.layout<"(4,3,?,2):(3,1,12,?)">
    ```

    **Errors**

    - order is not weakly congruent to shape (rank mismatch)

      ```mlir
      %l = cute.make_ordered_layout(%s, %o)
             : (!cute.shape<"(4,2)">, !cute.int_tuple<"(0,1,2)">) -> !cute.layout<"(4,2):(1,4)">
      ```

    - declared result layout does not match the computed ordered layout

      ```mlir
      %l = cute.make_ordered_layout(%s, %o)
             : (!cute.shape<"(4,2)">, !cute.int_tuple<"(0,1)">) -> !cute.layout<"(4,2):(2,1)">
      ```
  }];

  let arguments = (ins
    Cute_Arg<Cute_ShapeType,    "shape of the layout">:$shape,
    Cute_Arg<Cute_IntTupleType, "ordering of modes (smaller = less major)">:$order
  );
  let results = (outs
    Cute_Arg<Cute_LayoutType, "ordered compact layout">:$layout
  );
  let assemblyFormat = [{
    `(` $shape `,` $order `)` attr-dict `:`
    `(` qualified(type($shape)) `,` qualified(type($order)) `)` `->` qualified(type($layout))
  }];
}

//===----------------------------------------------------------------------===//
// MakeIdentityLayoutOp
//===----------------------------------------------------------------------===//

def Cute_MakeIdentityLayoutOp : Cute_Op<"make_identity_layout",
    [Pure, DeclareOpInterfaceMethods<InferTypeOpInterface>]> {
  let cuteSpecGroup = "AdvancedConstructors";
  let summary = "Identity layout — scaled-basis stride for each shape mode";
  let description = [{
    Produces an identity layout for the given shape. Each leaf mode in
    the shape receives a unit scaled-basis stride: mode ``k`` of the
    flattened leaf sequence receives stride ``1@k`` (the ``k``-th basis
    vector). For nested shapes, basis indices follow a depth-first
    left-to-right traversal of the shape tree, e.g. shape ``(2,(3,4))``
    produces strides ``(1@0,(1@0@1,1@1@1))``.

    The resulting layout maps any coordinate to its colexicographic
    position in an abstract multi-dimensional index space, useful as a
    tile-coordinate layout for complex tiling hierarchies.

    **Preconditions**

    - ``$shape`` is ``!cute.shape``; may contain dynamic (``?``) extents.

    **Postconditions**

    - Result shape equals ``$shape``.
    - Result strides are static scaled-basis vectors ``1@k`` (or nested
      ``1@i@j...`` for nested shape modes), one per leaf mode in
      depth-first left-to-right order.

    **Examples**

    ```mlir
    // Scalar shape → stride 1
    %l = cute.make_identity_layout(%s) : !cute.shape<"4"> -> !cute.layout<"4:1">

    // Flat shape → per-mode basis strides
    %l = cute.make_identity_layout(%s)
           : !cute.shape<"(4,2)"> -> !cute.layout<"(4,2):(1@0,1@1)">

    // Nested shape → nested basis strides
    %l = cute.make_identity_layout(%s)
           : !cute.shape<"(2,(3,4),5)">
          -> !cute.layout<"(2,(3,4),5):(1@0,(1@0@1,1@1@1),1@2)">

    // Dynamic extent — strides are still static basis vectors
    %l = cute.make_identity_layout(%s)
           : !cute.shape<"(?,3)"> -> !cute.layout<"(?,3):(1@0,1@1)">
    ```

    **Errors**

    - operand is not a shape

      ```mlir
      %l = cute.make_identity_layout(%s)
             : !cute.int_tuple<"(4,2)"> -> !cute.layout<"(4,2):(1@0,1@1)">
      ```

    - declared result layout does not match the computed identity layout

      ```mlir
      %l = cute.make_identity_layout(%s)
             : !cute.shape<"(4,2)"> -> !cute.layout<"(4,2):(1,4)">
      ```
  }];

  let arguments = (ins
    Cute_Arg<Cute_ShapeType, "shape of the identity layout">:$shape
  );
  let results = (outs
    Cute_Arg<Cute_LayoutType, "identity layout">:$result
  );
  let assemblyFormat = "`(` $shape `)` attr-dict `:` qualified(type($shape)) `->` qualified(type($result))";
}

//===----------------------------------------------------------------------===//
// GetShapeOp
//===----------------------------------------------------------------------===//

def Cute_GetShapeOp : Cute_Op<"get_shape", [Pure,
    DeclareOpInterfaceMethods<InferTypeOpInterface>]> {
  let cuteSpecGroup = "Accessors";
  let summary = "Extract the shape from a layout, composed layout, or tile";
  let description = [{
    Returns the ``!cute.shape`` describing the domain of the input.

    Per input kind:

    - ``!cute.layout`` — the layout's shape (e.g. ``(4,8)`` from
      ``(4,8):(1,4)``).

    - ``!cute.composed_layout`` — the shape of the outer B layout.
    - ``!cute.tile`` — a shape whose i-th element is the shape of the
      i-th layout in the tile (e.g. ``[(4,8):(1,4);(2,3):(1,2)]`` →
      ``((4,8),(2,3))``).

    Tile operands with underscore (``_``) slots are rejected: an
    underscore slot has no shape, so it cannot contribute an
    element to the extracted shape. If a tile has underscore slots,
    project the layout slots out first via
    ``cute.get_layouts_from_tile`` and then take the shape of each
    layout.

    **Preconditions**

    - ``$input`` is one of ``!cute.layout``, ``!cute.composed_layout``, or
      ``!cute.tile``.

    - If ``$input`` is a ``!cute.tile``, it must contain no underscore
      slots.

    **Postconditions**

    - Result is ``!cute.shape``.
    - Result equals the layout's shape (for layout / composed_layout
      inputs) or the per-slot shape tuple (for tile inputs).

    **Examples**

    ```mlir
    // From a layout
    %s = cute.get_shape(%l) : !cute.layout<"(4,8):(1,4)"> -> !cute.shape<"(4,8)">

    // From a composed layout — returns B layout's shape
    %s = cute.get_shape(%cl)
           : !cute.composed_layout<"S<3,5,4> o 0 o (8,4):(1,8)">
          -> !cute.shape<"(8,4)">

    // From a tile — one shape entry per layout slot
    %s = cute.get_shape(%t)
           : !cute.tile<"[(4,8):(1,4);(2,3):(1,2)]">
          -> !cute.shape<"((4,8),(2,3))">

    ```

    **Errors**

    - operand is not a layout, composed_layout, or tile

      ```mlir
      %s = cute.get_shape(%x) : !cute.shape<"(4,8)"> -> !cute.shape<"(4,8)">
      ```

    - declared result shape does not match the input's shape

      ```mlir
      %s = cute.get_shape(%l) : !cute.layout<"(4,8):(1,4)"> -> !cute.shape<"(2,3)">
      ```

    - tile operand contains an underscore slot

      ```mlir
      %s = cute.get_shape(%t)
             : !cute.tile<"[(4,8):(1,4);_]"> -> !cute.shape<"((4,8),x)">
      ```
  }];
  let arguments = (ins
    Cute_Arg<AnyTypeOf<[Cute_LayoutType, Cute_ComposedLayoutType, Cute_TileType]>,
             "input layout or tile">:$input
  );
  let results = (outs Cute_Arg<Cute_ShapeType, "shape">:$result);
  let assemblyFormat =
    "`(` $input `)` attr-dict `:` type($input) `->` qualified(type($result))";
}

def Cute_GetStrideOp : Cute_Op<"get_stride", [Pure,
    DeclareOpInterfaceMethods<InferTypeOpInterface>]> {
  let cuteSpecGroup = "Accessors";
  let summary = "Extract the stride from a layout";
  let description = [{
    Returns the ``!cute.stride`` of the input ``!cute.layout``.
    Scaled-basis strides are preserved verbatim.

    **Preconditions**

    - ``$input`` is ``!cute.layout``.

    **Postconditions**

    - Result is ``!cute.stride`` and equals the input layout's stride.

    **Examples**

    ```mlir
    // Plain integer strides
    %s = cute.get_stride(%l) : !cute.layout<"(4,8):(1,4)"> -> !cute.stride<"(1,4)">

    // Scaled-basis strides — preserved verbatim
    %s = cute.get_stride(%l)
           : !cute.layout<"(2,3):(1@0,1@1)"> -> !cute.stride<"(1@0,1@1)">
    ```

    **Errors**

    - operand is not a layout

      ```mlir
      %s = cute.get_stride(%cl)
             : !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">
            -> !cute.stride<"(1,4)">
      ```

    - declared result stride does not match the input layout's stride

      ```mlir
      %s = cute.get_stride(%l) : !cute.layout<"(4,8):(1,4)"> -> !cute.stride<"(2,3)">
      ```
  }];
  let arguments = (ins Cute_Arg<Cute_LayoutType, "input layout">:$input);
  let results = (outs Cute_Arg<Cute_StrideType, "stride">:$result);
  let assemblyFormat =
    "`(` $input `)` attr-dict `:` type($input) `->` qualified(type($result))";
}

//===----------------------------------------------------------------------===//
// ComposedGetInnerOp
//===----------------------------------------------------------------------===//

def Cute_ComposedGetInnerOp : Cute_Op<"composed_get_inner", [Pure,
    DeclareOpInterfaceMethods<InferTypeOpInterface>]> {
  let cuteSpecGroup = "Accessors";
  let summary = "Extract the inner (A) component from a composed layout";
  let description = [{
    Returns the inner A component of the input ``!cute.composed_layout``.
    A composed layout has the form ``A o offset o B``; this op extracts A.

    **Preconditions**

    - ``$input`` is ``!cute.composed_layout``.

    **Postconditions**

    - Result is ``!cute.layout`` when A is an affine layout, or
      ``!cute.swizzle`` when A is a swizzle.

    - Result equals the A component of the input.

    **Examples**

    ```mlir
    // Affine A: result is !cute.layout
    %a = cute.composed_get_inner(%cl)
           : !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">
          -> !cute.layout<"(4,5):(1,4)">

    // Swizzle A: result is !cute.swizzle
    %a = cute.composed_get_inner(%cl)
           : !cute.composed_layout<"S<3,5,4> o 0 o (8,4):(1,8)">
          -> !cute.swizzle<"S<3,5,4>">
    ```

    **Errors**

    - operand is not a composed_layout

      ```mlir
      %a = cute.composed_get_inner(%l)
             : !cute.layout<"(4,5):(1,4)"> -> !cute.layout<"(4,5):(1,4)">
      ```

    - declared result kind does not match the input's A

      ```mlir
      // (input has affine A, but result is declared as a swizzle)
      %a = cute.composed_get_inner(%cl)
             : !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">
            -> !cute.swizzle<"S<3,5,4>">
      ```

    - declared result value does not match the input's A

      ```mlir
      %a = cute.composed_get_inner(%cl)
             : !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">
            -> !cute.layout<"(2,3):(1,2)">
      ```
  }];
  let arguments = (ins
    Cute_Arg<Cute_ComposedLayoutType, "input composed layout">:$input
  );
  let results = (outs
    Cute_Arg<AnyTypeOf<[Cute_LayoutType, Cute_SwizzleType]>,
             "inner A component">:$result
  );
  let assemblyFormat =
    "`(` $input `)` attr-dict `:` type($input) `->` type($result)";
}

//===----------------------------------------------------------------------===//
// ComposedGetOffsetOp
//===----------------------------------------------------------------------===//

def Cute_ComposedGetOffsetOp : Cute_Op<"composed_get_offset", [Pure,
    DeclareOpInterfaceMethods<InferTypeOpInterface>]> {
  let cuteSpecGroup = "Accessors";
  let summary = "Extract the offset from a composed layout";
  let description = [{
    Returns the offset ``!cute.int_tuple`` from the input
    ``!cute.composed_layout`` ``A o offset o B``.

    **Preconditions**

    - ``$input`` is ``!cute.composed_layout``.

    **Postconditions**

    - Result is ``!cute.int_tuple`` and equals the offset component of
      the input.

    **Examples**

    ```mlir
    // Scalar offset
    %off = cute.composed_get_offset(%cl)
             : !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">
            -> !cute.int_tuple<"2">

    // Tuple offset with a scaled-basis outer B
    %off = cute.composed_get_offset(%cl)
             : !cute.composed_layout<"(4,5):(1,4) o (0,0) o (2,3):(1@0,1@1)">
            -> !cute.int_tuple<"(0,0)">
    ```

    **Errors**

    - operand is not a composed_layout

      ```mlir
      %off = cute.composed_get_offset(%l)
               : !cute.layout<"(4,5):(1,4)"> -> !cute.int_tuple<"2">
      ```

    - declared result offset does not match the input's offset

      ```mlir
      %off = cute.composed_get_offset(%cl)
               : !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">
              -> !cute.int_tuple<"5">
      ```
  }];
  let arguments = (ins
    Cute_Arg<Cute_ComposedLayoutType, "input composed layout">:$input
  );
  let results = (outs Cute_Arg<Cute_IntTupleType, "offset">:$result);
  let assemblyFormat =
    "`(` $input `)` attr-dict `:` type($input) `->` qualified(type($result))";
}

//===----------------------------------------------------------------------===//
// ComposedGetOuterOp
//===----------------------------------------------------------------------===//

def Cute_ComposedGetOuterOp : Cute_Op<"composed_get_outer", [Pure,
    DeclareOpInterfaceMethods<InferTypeOpInterface>]> {
  let cuteSpecGroup = "Accessors";
  let summary = "Extract the outer (B) layout from a composed layout";
  let description = [{
    Returns the outer B ``!cute.layout`` from the input
    ``!cute.composed_layout`` ``A o offset o B``.

    **Preconditions**

    - ``$input`` is ``!cute.composed_layout``.

    **Postconditions**

    - Result is ``!cute.layout`` and equals the B (outer) component of
      the input.

    **Examples**

    ```mlir
    %b = cute.composed_get_outer(%cl)
           : !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">
          -> !cute.layout<"(2,3):(1,2)">
    ```

    **Errors**

    - operand is not a composed_layout

      ```mlir
      %b = cute.composed_get_outer(%l)
             : !cute.layout<"(2,3):(1,2)"> -> !cute.layout<"(2,3):(1,2)">
      ```

    - declared result layout does not match the input's B

      ```mlir
      %b = cute.composed_get_outer(%cl)
             : !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">
            -> !cute.layout<"(4,5):(1,4)">
      ```
  }];
  let arguments = (ins
    Cute_Arg<Cute_ComposedLayoutType, "input composed layout">:$input
  );
  let results = (outs Cute_Arg<Cute_LayoutType, "outer B layout">:$result);
  let assemblyFormat =
    "`(` $input `)` attr-dict `:` type($input) `->` type($result)";
}

//===----------------------------------------------------------------------===//
// GetLeavesOp
//===----------------------------------------------------------------------===//

def Cute_GetLeavesOp : Cute_Op<"get_leaves", [Pure,
    DeclareOpInterfaceMethods<InferTypeOpInterface>]> {
  let cuteSpecGroup = "Accessors";
  let summary = "Flatten a tuple-like value and return one result per leaf";
  let description = [{
    Recursively flattens all nesting levels of input and returns one SSA value
    per scalar leaf. Result count and per-result types are fully inferred from
    the input type.

    Per input kind, the leaf result type is:

    - ``!cute.shape`` → one ``!cute.shape`` per scalar leaf.
    - ``!cute.stride`` → one ``!cute.stride`` per scalar leaf.
    - ``!cute.coord`` → one ``!cute.coord`` per scalar leaf.
    - ``!cute.int_tuple`` → one ``!cute.int_tuple`` per scalar leaf.
    - ``!cute.tile`` → one ``!cute.layout`` per layout slot, one
      ``!cute.tile<"_">`` per underscore slot.

    **Preconditions**

    - ``$input`` is one of ``!cute.shape``, ``!cute.stride``, ``!cute.coord``,
      ``!cute.int_tuple``, or ``!cute.tile``.

    - The total leaf count is fully determined at compile time from the CuTe
      type encoded in ``$input``'s MLIR type attribute (e.g., `!cute.shape<"(4,(2,3))">`
      statically encodes 3 leaves).

    **Postconditions**

    - The number of results equals the total number of scalar leaves in ``$input``,
      produced by recursively flattening all levels of nesting.

    - Each result type matches the per-input-kind rules above.

    **Examples**

    ```mlir
    // shape: each leaf is !cute.shape — (4,(2,3)) flattens to three scalars
    %s0, %s1, %s2 = cute.get_leaves(%sh) : !cute.shape<"(4,(2,3))">
    // %s0 : !cute.shape<"4">, %s1 : !cute.shape<"2">, %s2 : !cute.shape<"3">

    // stride: each leaf is !cute.stride
    %t0, %t1 = cute.get_leaves(%st) : !cute.stride<"(1,4)">
    // %t0 : !cute.stride<"1">, %t1 : !cute.stride<"4">

    // coord: each leaf is !cute.coord
    %c0, %c1 = cute.get_leaves(%co) : !cute.coord<"(0,1)">
    // %c0 : !cute.coord<"0">, %c1 : !cute.coord<"1">

    // int_tuple: each leaf is !cute.int_tuple
    %i0, %i1 = cute.get_leaves(%it) : !cute.int_tuple<"(1,2)">
    // %i0 : !cute.int_tuple<"1">, %i1 : !cute.int_tuple<"2">

    // tile: layout slots → !cute.layout, underscore slots → !cute.tile<"_">
    %l0, %l1 = cute.get_leaves(%ti) : !cute.tile<"[(4,8):(1,4);(2,3):(1,2)]">
    // %l0 : !cute.layout<"(4,8):(1,4)">, %l1 : !cute.layout<"(2,3):(1,2)">

    %l0, %u, %l1 = cute.get_leaves(%ti) : !cute.tile<"[(4,8):(1,4);_;(2,3):(1,2)]">
    // %l0 : !cute.layout<"(4,8):(1,4)">, %u : !cute.tile<"_">, %l1 : !cute.layout<"(2,3):(1,2)">
    ```

    **Errors**

    - input is not one of the allowed CuTe tuple types (e.g. composed_layout)

      ```mlir
      %r:1 = cute.get_leaves(%cl)
               : !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">
      ```

    - declared result count does not match the input's leaf count

      ```mlir
      %r:2 = cute.get_leaves(%sh) : !cute.shape<"(4,(2,3))">
      ```
  }];
  let arguments = (ins Cute_Arg<Cute_AnyTupleType, "tuple-like input">:$input);
  let results = (outs
    Cute_Arg<Variadic<AnyTypeOf<[Cute_ShapeType, Cute_StrideType, Cute_CoordType,
                                 Cute_IntTupleType, Cute_LayoutType,
                                 Cute_TileType]>>,
             "depth-1 leaf values">:$results
  );
  let assemblyFormat = "`(` $input `)` attr-dict `:` type($input)";
}

//===----------------------------------------------------------------------===//
// GetScalarsOp
//===----------------------------------------------------------------------===//

def Cute_GetScalarsOp : Cute_Op<"get_scalars", [Pure,
    DeclareOpInterfaceMethods<InferTypeOpInterface>]> {
  let cuteSpecGroup = "Accessors";
  let summary = "Extract scalar integers from a CuTe value";
  let description = [{
    Returns the scalar integers stored in a CuTe value. Result count
    and per-result types are inferred from the input type and from the
    ``only_dynamic`` attribute.

    When ``only_dynamic`` is set, only runtime-dynamic scalars are
    returned. When absent, all scalars (static and dynamic) are
    returned.

    Per input kind:

    - ``!cute.shape``, ``!cute.stride``, ``!cute.coord``, ``!cute.int_tuple``,
      ``!cute.tile`` — each integer leaf emits one ``i32`` or ``i64``
      result, with width matching the leaf's ``?`` annotation (default
      ``i32`` for ``?``). Static leaves emit ``i64`` when ``only_dynamic`` is
      absent.

    - ``!cute.layout`` — scalars from shape, then scalars from stride.
    - ``!cute.composed_layout`` — scalars from A, then offset, then B.
    - ``!cute.swizzle`` — always three ``i32`` results: ``num_bits``,
      ``num_base``, ``num_shift``.

    **Preconditions**

    - ``$cute_value`` is any CuTe type.

    **Postconditions**

    - The number of results equals the count of scalars selected from
      ``$cute_value`` per the rules above (taking ``only_dynamic`` into
      account).

    - Each result is ``i32`` or ``i64``, with width matching the source
      leaf annotation.

    **Examples**

    ```mlir
    // All scalars from a mixed layout: 2 static i64 + 2 dynamic i32
    %s0, %s1, %d0, %d1 = cute.get_scalars (%l) : !cute.layout<"(4,8):(1,?)">

    // Only dynamic scalars: 1 dynamic i32
    %d = cute.get_scalars<{only_dynamic}> (%l) : !cute.layout<"(4,?):(1,4)">

    // Swizzle: always 3 x i32
    %nb, %nbase, %ns = cute.get_scalars (%sw) : !cute.swizzle<"S<3,5,4>">
    ```

    **Errors**

    - declared result count does not match the input's scalar count

      ```mlir
      %s:1 = cute.get_scalars (%l) : !cute.layout<"(4,8):(1,?)">
      ```

    - declared result width does not match a leaf's width annotation

      ```mlir
      // (leaf is i32 ? but result is declared as i64)
      %d = cute.get_scalars<{only_dynamic}> (%l) : !cute.layout<"(4,?):(1,4)">
      // ... where the produced %d is bound to an i64 by the surrounding context
      ```
  }];
  let arguments = (ins
    Cute_Arg<Cute_AnyType, "CuTe value">:$cute_value,
    Cute_Arg<UnitAttr, "if set, return only the dynamic leaves">:$only_dynamic
  );
  let results = (outs
    Cute_Arg<Variadic<AnyIntOfWidths<[32, 64]>>, "extracted scalar integers">:$scalars
  );
  let assemblyFormat = [{
    (`<` `{` `only_dynamic` `}` `>` $only_dynamic^)? `(` $cute_value `)` attr-dict
    `:` qualified(type($cute_value))
  }];
}

//===----------------------------------------------------------------------===//
// GetOp
//===----------------------------------------------------------------------===//

def Cute_GetOp : Cute_Op<"get", [Pure,
    DeclareOpInterfaceMethods<InferTypeOpInterface>]> {
  let cuteSpecGroup = "Accessors";
  let summary = "Extract a mode from a CuTe value by hierarchical index";
  let description = [{
    Extracts the element at the given hierarchical mode path. Modes
    are applied sequentially: ``<[1, 0]>`` means "take element 1, then
    element 0 from that". If ``mode`` is absent (or ``<[]>`` — the empty
    mode array), the input value is returned unchanged (identity).
    The result is always the same kind as the input.

    Per input kind:

    - ``!cute.shape``, ``!cute.int_tuple``, ``!cute.coord``,
      ``!cute.stride``, ``!cute.layout`` — descend into the
      nested-tuple structure; the result is the sub-element at
      the chosen path.

    - ``!cute.tile`` — ``cute.get<[N]>`` selects slot N of the tile.
      The result is a tile wrapping the selected slot, not the
      bare layout / underscore. Picking a layout slot yields
      ``!cute.tile<"L">``; picking an underscore slot yields
      ``!cute.tile<"_">``. Component extraction with the slot's bare
      type can be done by composing with ``cute.get_leaves``.

    - ``!cute.composed_layout`` — ``cute.get<[N]>`` slices the
      composed layout at sub-mode N of the outer B layout,
      preserving the inner A component and offset. The result is
      a new composed layout
      ``A o offset o get<[N]>(B)``, *not* a Layout. Component
      extraction (inner A / offset / outer B alone) belongs to
      ``cute.composed_get_inner`` / ``_offset`` / ``_outer``.

    **Preconditions**

    - ``$input`` is one of ``!cute.shape``, ``!cute.int_tuple``,
      ``!cute.coord``, ``!cute.stride``, ``!cute.tile``, ``!cute.layout``,
      or ``!cute.composed_layout``.

    - Each index in ``$mode`` is in ``[0, rank)`` at its level
      (negative indices and out-of-range indices are rejected).

    - For composed_layout inputs, ``$mode`` indices are interpreted
      against the outer B layout's rank at each level.

    - ``$mode`` indices stop at a scalar leaf. Once the descent
      resolves to a scalar (a shape/stride/coord/int_tuple leaf,
      or a rank-1 layout / composed_layout whose shape is a
      scalar), no further indices are accepted: ``cute.get<[0, 0]>``
      on ``!cute.shape<"(4,2)">`` is a use error, not a no-op.

    **Postconditions**

    - Result has the same kind as ``$input`` (shape→shape,
      tile→tile, composed_layout→composed_layout, etc.). The result
      is always one of the cute kinds; to extract a raw ``i32``,
      ``i64``, or ``index`` for arithmetic, feed the ``cute.get`` result
      through ``cute.get_scalars``.

    - Result equals ``$input`` when ``$mode`` is absent or empty
      (identity).

    - Otherwise, result equals the element reached by descending
      through ``$mode`` indices in order — with the kind-specific
      semantics described above.

    **Examples**

    ```mlir
    // Single-level: extract mode 1 from a shape — result is the nested tuple at that mode
    %r = cute.get<[1]> (%s) : !cute.shape<"(4,(2,3))"> -> !cute.shape<"(2,3)">

    // Single-level: extract mode 0 from a layout — scalar leaf
    %r = cute.get<[0]> (%l) : !cute.layout<"(4,8):(1,4)"> -> !cute.layout<"4:1">

    // Two-level: mode 1 → then mode 0 of that — (4,(2,3)) → (2,3) → 2
    %r = cute.get<[1, 0]> (%s) : !cute.shape<"(4,(2,3))"> -> !cute.shape<"2">

    // Two-level: mode 0 → then mode 1 of that — ((4,2),(3,8)):((1,4),(8,24)) → (4,2):(1,4) → 2:4
    %r = cute.get<[0, 1]> (%l)
           : !cute.layout<"((4,2),(3,8)):((1,4),(8,24))"> -> !cute.layout<"2:4">

    // Three-level: mode 1 → mode 1 → mode 0 — (4,(2,(3,5))) → (2,(3,5)) → (3,5) → 3
    %r = cute.get<[1, 1, 0]> (%s) : !cute.shape<"(4,(2,(3,5)))"> -> !cute.shape<"3">

    // Three-level: mode 0 → mode 0 → mode 1 — deeply nested layout → scalar leaf
    %r = cute.get<[0, 0, 1]> (%l)
           : !cute.layout<"(((4,2),3),(8,16)):(((1,4),8),(24,384))"> -> !cute.layout<"2:4">

    // Identity get (no mode) — returns input unchanged
    %r = cute.get (%s) : !cute.shape<"(4,2)"> -> !cute.shape<"(4,2)">

    // Identity get (empty mode `<[]>`) — same as no-mode form
    %r = cute.get<[]> (%l) : !cute.layout<"(4,8):(1,4)"> -> !cute.layout<"(4,8):(1,4)">

    // Tile operand: result is a single-slot tile, not a bare layout
    %r = cute.get<[0]> (%t)
           : !cute.tile<"[(4,8):(1,4);(2,3):(1,2)]"> -> !cute.tile<"(4,8):(1,4)">

    // Tile operand picking an underscore slot
    %r = cute.get<[1]> (%t)
           : !cute.tile<"[(4,8):(1,4);_]"> -> !cute.tile<"_">

    // ComposedLayout operand: mode 0 applied to outer B, inner+offset preserved
    //   outer B = (2,3):(1,2); get<[0]>(B) = 2:1
    %r = cute.get<[0]> (%cl)
           : !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">
          -> !cute.composed_layout<"(4,5):(1,4) o 2 o 2:1">
    ```

    **Errors**

    - top-level mode index out of range

      ```mlir
      %r = cute.get<[5]>(%l) : !cute.layout<"(4,8):(1,4)"> -> !cute.layout<"(4,8):(1,4)">
      ```

    - negative mode index is out of range

      ```mlir
      %r = cute.get<[-1]>(%i) : !cute.int_tuple<"(1,2,3)"> -> !cute.int_tuple<"1">
      ```

    - nested mode index out of range

      ```mlir
      %r = cute.get<[1, 5]>(%s) : !cute.shape<"(4,(2,3))"> -> !cute.shape<"2">
      ```

    - descent past a scalar leaf — after `[0]` the value is

      ```mlir
      // the scalar `4`, so the trailing `0` has no scalar to descend into
      %r = cute.get<[0, 0]>(%s) : !cute.shape<"(4,2)"> -> !cute.shape<"4">
      ```
  }];
  let arguments = (ins
    Cute_Arg<Cute_AnyIndexableType, "input value">:$input,
    Cute_Arg<OptionalAttr<DenseI32ArrayAttr>, "hierarchical mode path">:$mode
  );
  let results = (outs Cute_Arg<Cute_AnyIndexableType, "result">:$result);
  let assemblyFormat = [{
    (`<` $mode^ `>`)? `(` $input `)` attr-dict
    `:` type($input) `->` type($result)
  }];
}

//===----------------------------------------------------------------------===//
// SelectOp
//===----------------------------------------------------------------------===//

def Cute_SelectOp : Cute_Op<"select", [Pure,
    DeclareOpInterfaceMethods<InferTypeOpInterface>]> {
  let cuteSpecGroup = "Accessors";
  let summary = "Select top-level modes from a CuTe value";
  let description = [{
    Returns a new value of the same kind containing only the top-level
    modes at the given indices. Indices may be repeated or permuted.
    The result is always wrapped in a tuple, even when a single mode
    is selected. Unlike ``cute.get``, modes apply only at the top level
    — there is no hierarchical descent.

    **Preconditions**

    - ``$input`` is one of ``!cute.shape``, ``!cute.int_tuple``,
      ``!cute.coord``, ``!cute.stride``, ``!cute.tile``, ``!cute.layout``, or
      ``!cute.composed_layout``.

    - Each index in ``$mode`` is in ``[0, rank)`` of ``$input`` (negative
      indices and out-of-range indices are rejected).

    **Postconditions**

    - Result has the same kind as ``$input``.
    - Result has rank equal to ``len($mode)``; mode ``i`` of the result
      equals top-level mode ``$mode[i]`` of ``$input``, copied as-is.

    Per input kind:

    - ``!cute.shape``, ``!cute.int_tuple``, ``!cute.coord``, ``!cute.stride`` —
      pick the named top-level modes and tuple them in the given
      order. Repeated indices duplicate the picked mode.

    - ``!cute.layout`` — pick top-level (shape, stride) pairs; each
      picked mode retains its original shape and stride values.

    - ``!cute.tile`` — pick top-level slots; layout slots and
      underscore slots are treated uniformly (an underscore at the
      picked index appears as an underscore in the result tile).

    - ``!cute.composed_layout`` — ``cute.select`` operates on the
      outer B layout, slicing it to the selected modes. The
      inner A and offset are preserved.

    - Empty mode ``<[]>`` — produces a rank-0 result (e.g.
      ``!cute.shape<"()">``). Contrast with ``cute.get<[]>``, which is
      identity.

    **Examples**

    ```mlir
    // Keep two non-contiguous modes from a rank-3 shape
    %r = cute.select<[0, 2]> (%s)
           : !cute.shape<"(4,2,8)"> -> !cute.shape<"(4,8)">

    // Permute two modes of a layout (indices reordered)
    %r = cute.select<[2, 0]> (%l)
           : !cute.layout<"(4,2,8):(1,4,8)"> -> !cute.layout<"(8,4):(8,1)">

    // Repeat a mode — mode 1 appears twice in the output
    %r = cute.select<[1, 1]> (%i)
           : !cute.int_tuple<"(1,2,3)"> -> !cute.int_tuple<"(2,2)">

    // Single-mode select wraps result in a tuple: (4,8):(1,4) → (4):(1)
    %r = cute.select<[0]> (%l)
           : !cute.layout<"(4,8):(1,4)"> -> !cute.layout<"(4):(1)">

    // Tile: pick two top-level slots; underscore slot at index 1 is
    // copied as-is when selected.
    %r = cute.select<[1, 2]> (%t)
           : !cute.tile<"[(4,8):(1,4);_;(2,3):(1,2)]">
          -> !cute.tile<"[_;(2,3):(1,2)]">

    // ComposedLayout: select applies to outer B; inner + offset kept.
    //   outer B = (2,3,8):(1,2,6); select<[2,0]>(B) = (8,2):(6,1)
    %r = cute.select<[2, 0]> (%cl)
           : !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3,8):(1,2,6)">
          -> !cute.composed_layout<"(4,5):(1,4) o 2 o (8,2):(6,1)">

    // Empty mode produces a rank-0 result.
    %r = cute.select<[]> (%s)
           : !cute.shape<"(4,8)"> -> !cute.shape<"()">
    ```

    **Errors**

    - mode index out of range

      ```mlir
      %r = cute.select<[5]>(%l) : !cute.layout<"(4,8):(1,4)"> -> !cute.layout<"(4):(1)">
      ```

    - mode index out of range on a shape

      ```mlir
      %r = cute.select<[3]>(%s) : !cute.shape<"(4,8,2)"> -> !cute.shape<"(4)">
      ```

    - negative mode index

      ```mlir
      %r = cute.select<[-1]>(%i) : !cute.int_tuple<"(1,2,3)"> -> !cute.int_tuple<"(1)">
      ```
  }];
  let arguments = (ins
    Cute_Arg<Cute_AnyIndexableType, "input value">:$input,
    Cute_Arg<DenseI32ArrayAttr, "top-level mode indices">:$mode
  );
  let results = (outs Cute_Arg<Cute_AnyIndexableType, "result">:$result);
  let assemblyFormat = [{
    `<` $mode `>` `(` $input `)` attr-dict
    `:` type($input) `->` type($result)
  }];
}

//===----------------------------------------------------------------------===//
// ToIntTupleOp
//===----------------------------------------------------------------------===//

def Cute_ToIntTupleOp : Cute_Op<"to_int_tuple", [Pure,
    DeclareOpInterfaceMethods<InferTypeOpInterface>]> {
  let cuteSpecGroup = "Accessors";
  let summary = "Cast a scalar-tuple CuTe type to !cute.int_tuple";
  let description = [{
    Converts a scalar-tuple CuTe type to a ``!cute.int_tuple`` with
    identical integer values. The result type is inferred from the
    source.

    **Preconditions**

    - ``$src`` is one of ``!cute.shape``, ``!cute.stride``, ``!cute.coord``,
      or ``!cute.int_tuple``.

    - ``$src`` must not contain scaled-basis strides (e.g. ``1@0``).
    - ``$src`` must not contain underscore (``_``) elements (reachable
      via ``!cute.coord``, which accepts underscores).

    - ``$src`` must not contain error elements.

    **Postconditions**

    - Result is ``!cute.int_tuple`` with the same hierarchical structure
      and integer values as ``$src`` (interpreting any wrapper kind —
      shape, stride, coord — as a plain integer tuple).
    - Dynamic leaves (``?``) are preserved verbatim through the cast.

    - ``int_tuple`` → ``int_tuple`` is the identity case (allowed; result
      equals source).

    **Examples**

    ```mlir
    // Per-kind static casts.
    %it = cute.to_int_tuple(%s)  : !cute.shape<"(4,8)">  -> !cute.int_tuple<"(4,8)">
    %it = cute.to_int_tuple(%st) : !cute.stride<"(1,4)"> -> !cute.int_tuple<"(1,4)">
    %it = cute.to_int_tuple(%c)  : !cute.coord<"(0,1)">  -> !cute.int_tuple<"(0,1)">

    // Identity: int_tuple → int_tuple.
    %it = cute.to_int_tuple(%i) : !cute.int_tuple<"(2,3)"> -> !cute.int_tuple<"(2,3)">

    // Dynamic source — `?` leaves flow through.
    %it = cute.to_int_tuple(%s) : !cute.shape<"(?,8)"> -> !cute.int_tuple<"(?,8)">

    // Nested tuple — hierarchical structure preserved.
    %it = cute.to_int_tuple(%s)
            : !cute.shape<"(4,(2,3),8)"> -> !cute.int_tuple<"(4,(2,3),8)">

    // Dynamic stride leaf preserved through the cast.
    %it = cute.to_int_tuple(%st)
            : !cute.stride<"(8,?)"> -> !cute.int_tuple<"(8,?)">
    ```

    **Errors**

    - scalar source has a scaled-basis stride

      ```mlir
      %r = cute.to_int_tuple(%s) : !cute.stride<"4@0"> -> !cute.int_tuple<"4">
      ```

    - tuple source has a dynamic scaled-basis component

      ```mlir
      %r = cute.to_int_tuple(%s) : !cute.stride<"(1,?@0)"> -> !cute.int_tuple<"(1,4)">
      ```

    - coord source contains an underscore element

      ```mlir
      %r = cute.to_int_tuple(%c) : !cute.coord<"(4,_)"> -> !cute.int_tuple<"(4,8)">
      ```
  }];
  let arguments = (ins
    Cute_Arg<AnyTypeOf<[Cute_ShapeType, Cute_StrideType, Cute_CoordType,
                        Cute_IntTupleType]>,
             "source scalar-tuple">:$src
  );
  let results = (outs Cute_Arg<Cute_IntTupleType, "int_tuple result">:$result);
  let assemblyFormat =
    "`(` $src `)` attr-dict `:` qualified(type($src)) `->` qualified(type($result))";
}

//===----------------------------------------------------------------------===//
// ToShapeOp
//===----------------------------------------------------------------------===//

def Cute_ToShapeOp : Cute_Op<"to_shape", [Pure,
    DeclareOpInterfaceMethods<InferTypeOpInterface>]> {
  let cuteSpecGroup = "Accessors";
  let summary = "Cast a !cute.int_tuple to !cute.shape";
  let description = [{
    Reinterprets a `!cute.int_tuple` as a `!cute.shape` with identical
    structure and integer values. The result type is inferred from the
    source.

    **Preconditions**

    - `$src` is `!cute.int_tuple`.
    - `$src` must not contain error elements.

    **Postconditions**

    - Result is `!cute.shape` with the same hierarchical structure and
      integer values as `$src`.
    - Dynamic leaves (`?`) are preserved verbatim through the cast.

    **Examples**

    ```mlir
    // Static.
    %s = cute.to_shape(%i) : !cute.int_tuple<"(4,8)"> -> !cute.shape<"(4,8)">

    // Dynamic leaf preserved.
    %s = cute.to_shape(%i) : !cute.int_tuple<"(?,8)"> -> !cute.shape<"(?,8)">

    // Nested — hierarchical structure preserved.
    %s = cute.to_shape(%i)
           : !cute.int_tuple<"(4,(2,3),8)"> -> !cute.shape<"(4,(2,3),8)">
    ```
  }];
  let arguments = (ins
    Cute_Arg<Cute_IntTupleType, "source int_tuple">:$src
  );
  let results = (outs Cute_Arg<Cute_ShapeType, "shape result">:$result);
  let assemblyFormat =
    "`(` $src `)` attr-dict `:` qualified(type($src)) `->` qualified(type($result))";
}

//===----------------------------------------------------------------------===//
// ToStrideOp
//===----------------------------------------------------------------------===//

def Cute_ToStrideOp : Cute_Op<"to_stride", [Pure,
    DeclareOpInterfaceMethods<InferTypeOpInterface>]> {
  let cuteSpecGroup = "Accessors";
  let summary = "Cast a !cute.int_tuple to !cute.stride";
  let description = [{
    Reinterprets a `!cute.int_tuple` as a `!cute.stride` with identical
    structure and integer values. The result type is inferred from the
    source. Because the source is a `!cute.int_tuple`, the result never
    contains scaled-basis leaves (`V@M`); construct those via the
    `!cute.stride` constructor path instead.

    **Preconditions**

    - `$src` is `!cute.int_tuple`.
    - `$src` must not contain error elements.

    **Postconditions**

    - Result is `!cute.stride` with the same hierarchical structure and
      integer values as `$src`.
    - Dynamic leaves (`?`) are preserved verbatim through the cast.

    **Examples**

    ```mlir
    // Static.
    %st = cute.to_stride(%i) : !cute.int_tuple<"(1,4)"> -> !cute.stride<"(1,4)">

    // Dynamic leaf preserved.
    %st = cute.to_stride(%i) : !cute.int_tuple<"(1,?)"> -> !cute.stride<"(1,?)">

    // Nested — hierarchical structure preserved.
    %st = cute.to_stride(%i)
            : !cute.int_tuple<"(1,(4,8),32)"> -> !cute.stride<"(1,(4,8),32)">
    ```
  }];
  let arguments = (ins
    Cute_Arg<Cute_IntTupleType, "source int_tuple">:$src
  );
  let results = (outs Cute_Arg<Cute_StrideType, "stride result">:$result);
  let assemblyFormat =
    "`(` $src `)` attr-dict `:` qualified(type($src)) `->` qualified(type($result))";
}

//===----------------------------------------------------------------------===//
// ToCoordOp
//===----------------------------------------------------------------------===//

def Cute_ToCoordOp : Cute_Op<"to_coord", [Pure,
    DeclareOpInterfaceMethods<InferTypeOpInterface>]> {
  let cuteSpecGroup = "Accessors";
  let summary = "Cast a !cute.int_tuple to !cute.coord";
  let description = [{
    Reinterprets a `!cute.int_tuple` as a `!cute.coord` with identical
    structure and integer values. The result type is inferred from the
    source. Because the source is a `!cute.int_tuple`, the result never
    contains underscore leaves (`_`); construct those via the
    `!cute.coord` constructor path instead.

    **Preconditions**

    - `$src` is `!cute.int_tuple`.
    - `$src` must not contain error elements.

    **Postconditions**

    - Result is `!cute.coord` with the same hierarchical structure and
      integer values as `$src`.
    - Dynamic leaves (`?`) are preserved verbatim through the cast.

    **Examples**

    ```mlir
    // Static.
    %c = cute.to_coord(%i) : !cute.int_tuple<"(0,1)"> -> !cute.coord<"(0,1)">

    // Dynamic leaf preserved.
    %c = cute.to_coord(%i) : !cute.int_tuple<"(?,3)"> -> !cute.coord<"(?,3)">

    // Nested — hierarchical structure preserved.
    %c = cute.to_coord(%i)
           : !cute.int_tuple<"(0,(1,2),3)"> -> !cute.coord<"(0,(1,2),3)">
    ```
  }];
  let arguments = (ins
    Cute_Arg<Cute_IntTupleType, "source int_tuple">:$src
  );
  let results = (outs Cute_Arg<Cute_CoordType, "coord result">:$result);
  let assemblyFormat =
    "`(` $src `)` attr-dict `:` qualified(type($src)) `->` qualified(type($result))";
}

//===----------------------------------------------------------------------===//
// GetLayoutsFromTileOp
//===----------------------------------------------------------------------===//

def Cute_GetLayoutsFromTileOp : Cute_Op<"get_layouts_from_tile", [Pure,
    DeclareOpInterfaceMethods<InferTypeOpInterface>]> {
  let cuteSpecGroup = "Accessors";
  let summary = "Extract all layout elements from a tile, skipping underscores";
  let description = [{
    Flattens the input ``!cute.tile`` (in DFS / left-to-right order) and
    returns one ``!cute.layout`` per layout leaf. Underscore elements are
    silently skipped — the result count equals the number of layout
    leaves in the tile.

    **Preconditions**

    - ``$tile`` is ``!cute.tile``.
    - ``$tile`` contains at least one layout leaf. An all-underscore
      tile (no layout slots at any depth) is a use error — there is
      nothing to extract.

    **Postconditions**

    - The number of results equals the number of layout leaves of
      ``$tile`` after recursive flattening (underscore slots are
      skipped at every depth). The result is always non-empty.

    - Each result is ``!cute.layout`` and equals the corresponding
      layout leaf of ``$tile`` in DFS left-to-right order.

    - Layout leaves preserve their original values verbatim — static,
      dynamic, and scaled-basis strides all flow through unchanged.

    **Examples**

    ```mlir
    // Two-layout tile: two results
    %l0, %l1 = cute.get_layouts_from_tile(%t)
                 : !cute.tile<"[(4,8):(1,4);(2,3):(1,2)]">
    // %l0 : !cute.layout<"(4,8):(1,4)">, %l1 : !cute.layout<"(2,3):(1,2)">

    // Tile with an underscore: only layout slots are returned
    %l0 = cute.get_layouts_from_tile(%t) : !cute.tile<"[4:1;_]">
    // %l0 : !cute.layout<"4:1">

    // Nested tile (tile of tiles): DFS flatten yields all layout
    // leaves in left-to-right order, recursively skipping underscores.
    %l0, %l1, %l2, %l3 = cute.get_layouts_from_tile(%t)
                          : !cute.tile<"[4:1;[2:1;3:1];5:1]">
    // %l0 : !cute.layout<"4:1">, %l1 : !cute.layout<"2:1">,
    // %l2 : !cute.layout<"3:1">, %l3 : !cute.layout<"5:1">

    // Tile with a dynamic layout slot: the dynamic positions flow
    // through to the layout result.
    %l0, %l1 = cute.get_layouts_from_tile(%t)
                 : !cute.tile<"[(?,4):(1,?);(2,3):(1,2)]">
    // %l0 : !cute.layout<"(?,4):(1,?)">, %l1 : !cute.layout<"(2,3):(1,2)">
    ```

    **Errors**

    - parser-level type constraint: operand is not a ``!cute.tile``

      ```mlir
      %l0 = cute.get_layouts_from_tile(%l) : !cute.layout<"(4,8):(1,4)">
      ```

    - result-binding count: declared result count does not match the
      layout-leaf count of the tile

      ```mlir
      %l0 = cute.get_layouts_from_tile(%t) : !cute.tile<"[4:1;_;(2,3):(1,2)]">
      ```

    - all-underscore tile has no layout leaves

      ```mlir
      cute.get_layouts_from_tile(%t) : !cute.tile<"[_;_]">
      ```
  }];
  let arguments = (ins Cute_Arg<Cute_TileType, "input tile">:$tile);
  let results = (outs
    Cute_Arg<Variadic<Cute_LayoutType>, "extracted layout slots">:$layouts
  );
  let assemblyFormat = "`(` $tile `)` attr-dict `:` type($tile)";
}

//===----------------------------------------------------------------------===//
// Layout Algebra ops
//===----------------------------------------------------------------------===//

/// RHS operand for cute.composition — layout, shape, or tile.
def Cute_CompositionRhsType
    : AnyTypeOf<[Cute_LayoutType, Cute_ShapeType, Cute_TileType],
                "!cute.layout, !cute.shape, or !cute.tile">;

//===----------------------------------------------------------------------===//
// CompositionOp
//===----------------------------------------------------------------------===//

def Cute_CompositionOp : Cute_Op<"composition", [
    Pure,
    DeclareOpInterfaceMethods<InferTypeOpInterface>
]> {
  let cuteSpecGroup = "LayoutAlgebra";
  let summary = "Functional composition of two layout-like values: `lhs ∘ rhs`";
  let description = [{
    Given layouts ``lhs : S_lhs -> D_lhs`` and ``rhs : S_rhs -> D_rhs``,
    assuming ``S_lhs`` contains ``D_rhs``, ``cute.composition`` computes
    the functional composition ``lhs ∘ rhs`` that maps a coordinate ``c``
    in the domain of ``rhs`` as ``lhs(rhs(c))``. The ``$lhs`` operand is
    applied last (the outer function); the ``$rhs`` operand is applied
    first (the inner function).

    ``$lhs`` is a layout or composed layout. ``$rhs`` is a layout, shape,
    or tile. The result kind matches ``$lhs``'s kind: a plain-layout
    ``$lhs`` yields a plain-layout result; a composed-layout ``$lhs``
    yields a composed-layout result.

    For composed-layout ``$lhs`` ``A o offset o B``, composition applies
    only to the B (domain) layout; the A component and the offset
    are preserved unchanged in the result.

    **Preconditions**

    - ``$lhs`` is ``!cute.layout`` or ``!cute.composed_layout``.
    - ``$rhs`` is ``!cute.layout``, ``!cute.shape``, or ``!cute.tile``.
    - The pair ``($lhs, $rhs)`` is a valid composition input under
      cutegen's ``composition`` (e.g. ``$rhs``'s strides are compatible
      with ``$lhs``'s mode boundaries; ``$rhs`` is not over-rank for
      shape/tile forms). Specific rejections produce
      ``"expects a valid composition result, but construction failed"``.
      Cutegen accepts ``$rhs`` layouts with scaled-basis strides and
      with hierarchical / nested-tuple strides; both resolve to
      integer strides in the result.

    **Postconditions**

    - Result kind matches ``$lhs``'s kind.
    - For a plain-layout ``$lhs``: result represents ``lhs ∘ rhs``.
    - For a composed-layout ``$lhs`` ``A o offset o B``: result is
      ``A o offset o (B ∘ rhs)`` (A and offset unchanged).

    **Examples**

    ```mlir
    // layout ∘ layout: (20):(2) o (5,4):(4,1).
    // rhs strides 4 and 1 both satisfy divisibility w.r.t. lhs shape 20.
    // Result strides are lhs(rhs_stride): 2*4=8, 2*1=2.
    %r = cute.composition(%lhs, %rhs)
           : (!cute.layout<"(20):(2)">, !cute.layout<"(5,4):(4,1)">)
          -> !cute.layout<"(5,4):(8,2)">

    // layout ∘ shape: (4,8):(1,4) o (2,4).
    // A shape rhs has no explicit strides; it receives natural (column-major)
    // strides from `$lhs`. Result strides come from `$lhs`.
    %r = cute.composition(%lhs, %rhs)
           : (!cute.layout<"(4,8):(1,4)">, !cute.shape<"(2,4)">)
          -> !cute.layout<"(2,4):(1,4)">

    // layout ∘ tile: (4,8):(1,4) o [(2,4):(1,2)].
    // A tile wraps a single layout. The result is a plain layout in
    // hierarchical (wrapped) form: each tile dimension becomes a nested mode.
    %r = cute.composition(%lhs, %rhs)
           : (!cute.layout<"(4,8):(1,4)">, !cute.tile<"[(2,4):(1,2)]">)
          -> !cute.layout<"((2,4)):((1,2))">

    // composed_layout ∘ layout: A o offset o B, where B = (2,3):(1,2).
    // Composition applies only to B; A and offset are preserved.
    %r = cute.composition(%lhs, %rhs)
           : (!cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">,
              !cute.layout<"(2,3):(1,2)">)
          -> !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">

    // composed_layout ∘ shape: same A-offset-B structure; shape rhs applied
    // to B, giving B natural strides. A and offset are unchanged.
    %r = cute.composition(%lhs, %rhs)
           : (!cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">,
              !cute.shape<"(2,3)">)
          -> !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">

    // composed_layout ∘ tile: tile rhs applied to B; result carries the
    // tile-wrapped B in hierarchical form. A and offset are unchanged.
    %r = cute.composition(%lhs, %rhs)
           : (!cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">,
              !cute.tile<"[(2,3):(1,2)]">)
          -> !cute.composed_layout<"(4,5):(1,4) o 2 o ((2,3)):((1,2))">
    ```

    **Errors**

    - declared result layout does not match the inferred composition

      ```mlir
      %r = cute.composition(%lhs, %rhs)
             : (!cute.layout<"(20):(2)">, !cute.layout<"(5,4):(4,1)">)
            -> !cute.layout<"(5,4):(1,1)">
      ```

    - cutegen rejects the composition (e.g. inner-shape over-rank

      ```mlir
      //        for a layout outer, stride divisibility failure, …).
      //        Emits a generic diagnostic.
      %r = cute.composition(%l, %sh)
             : (!cute.layout<"(20):(2)">, !cute.shape<"(5,4)">) -> ...
      ```
  }];

  let arguments = (ins
    Cute_Arg<Cute_AnyLayoutType, "lhs layout">:$lhs,
    Cute_Arg<Cute_CompositionRhsType, "rhs layout/shape/tile">:$rhs
  );
  let results = (outs
    Cute_Arg<Cute_AnyLayoutType, "composition result">:$result
  );
  let assemblyFormat = [{
    `(` $lhs `,` $rhs `)` attr-dict `:`
    `(` type($lhs) `,` type($rhs) `)` `->` type($result)
  }];
}

//===----------------------------------------------------------------------===//
// CoalesceOp
//===----------------------------------------------------------------------===//

def Cute_CoalesceOp : Cute_Op<"coalesce", [
    Pure,
    DeclareOpInterfaceMethods<InferTypeOpInterface>
]> {
  let cuteSpecGroup = "LayoutAlgebra";
  let summary = "Coalesce consecutive compatible modes of a layout";
  let description = [{
    Simplifies a layout by merging consecutive modes that can be
    treated as a single mode without changing the codomain. The merge
    condition involves both shape and stride: two adjacent modes
    ``(n_i, s_i)`` and ``(n_{i+1}, s_{i+1})`` merge when
    ``n_i * s_i == s_{i+1}`` (the stride of the next mode equals the
    size-times-stride of the previous one). The merged mode keeps
    ``s_i`` as its stride and ``n_i * n_{i+1}`` as its size, so the result
    is a new layout — both shape and stride change.

    The optional ``$target_profile`` coord selects a coalescing profile.
    Unlike the merge condition, the profile is shape-structural:
    it partitions the top-level modes into independent coalescing
    groups (each top-level profile element bounds one group) and does
    not constrain stride. A scalar (single-element) profile coalesces
    the whole layout the same as the no-profile form.

    The result is always the same kind as the input. For composed-
    layout inputs only the B (outer) layout is coalesced; the A
    component and the offset are preserved.

    Merge conditions involving dynamic values cannot be evaluated at
    compile time, so the affected modes are left unmerged. Static
    modes that are not blocked by a dynamic neighbor still coalesce
    normally.

    **Preconditions**

    - ``$input`` is ``!cute.layout`` or ``!cute.composed_layout``.
    - When ``$target_profile`` is present, it is ``!cute.coord``.
    - When ``$target_profile`` is a multi-mode coord (rank > 1), its
      rank does not exceed the rank of the layout being coalesced.

    **Postconditions**

    - Result kind matches ``$input``'s kind.
    - For a plain-layout input: result is the maximally coalesced
      layout (subject to profile).

    - For a composed-layout input: result is ``A o offset o coalesce(B)``
      (A and offset unchanged).

    **Examples**

    *Static layouts*

    ```mlir
    // All compatible modes merged into one: 4*1 == 4, so (4,5):(1,4) → 20:1.
    %r = cute.coalesce(%input) : (!cute.layout<"(4,5):(1,4)">) -> !cute.layout<"20:1">

    // Already coalesced: 3*1 ≠ 8, so no merge is possible — result equals input.
    %r = cute.coalesce(%input) : (!cute.layout<"(3,4):(8,1)">) -> !cute.layout<"(3,4):(8,1)">

    // Nested inner mode coalesces: inner (4,5):(1,4) merges to 20:1.
    %r = cute.coalesce(%input)
           : (!cute.layout<"(3,(4,5)):(8,(1,4))">) -> !cute.layout<"(3,20):(8,1)">

    // With target_profile: each top-level mode is coalesced independently.
    %r = cute.coalesce(%input, %prof)
           : (!cute.layout<"(3,(4,5)):(8,(1,4))">, !cute.coord<"(1,1)">)
          -> !cute.layout<"(3,20):(8,1)">

    // Scalar profile coalesces the whole layout, same as the no-profile form.
    %r = cute.coalesce(%input, %prof)
           : (!cute.layout<"(4,5):(1,4)">, !cute.coord<"1">) -> !cute.layout<"20:1">

    // Composed layout: only B is coalesced; A and offset are preserved.
    %r = cute.coalesce(%input)
           : (!cute.composed_layout<"(4,5):(1,4) o 2 o (4,5):(1,4)">)
          -> !cute.composed_layout<"(4,5):(1,4) o 2 o 20:1">
    ```

    *Dynamic layouts*

    ```mlir
    // Dynamic shape in first mode: ?*1==4 is unverifiable — modes kept.
    %r = cute.coalesce(%input) : (!cute.layout<"(?,4):(1,4)">) -> !cute.layout<"(?,4):(1,4)">

    // Dynamic stride in first mode: 4*?==4 is unverifiable — modes kept.
    %r = cute.coalesce(%input) : (!cute.layout<"(4,5):(?,4)">) -> !cute.layout<"(4,5):(?,4)">

    // Fully dynamic rank-1 layout: single-element vector unwraps to scalar form.
    %r = cute.coalesce(%input) : (!cute.layout<"(?):(?)">)  -> !cute.layout<"?:?">

    // Static prefix merges; dynamic tail stays.
    %r = cute.coalesce(%input)
           : (!cute.layout<"(4,5,?):(1,4,?)">) -> !cute.layout<"(20,?):(1,?)">

    // Dynamic mode in the middle blocks its neighbours; static groups on
    // either side coalesce independently: (4,5)→20 and (3,2)→6.
    %r = cute.coalesce(%input)
           : (!cute.layout<"(4,5,?,3,2):(1,4,?,1,3)">) -> !cute.layout<"(20,?,6):(1,?,1)">

    // Dynamic layout with profile: profile does not unlock merges blocked by
    // dynamic values.
    %r = cute.coalesce(%input, %prof)
           : (!cute.layout<"(4,?):(1,4)">, !cute.coord<"(1,1)">) -> !cute.layout<"(4,?):(1,4)">
    ```

    **Errors**

    The profile-rank precondition is checked recursively: at every
    nesting depth, the profile's rank must not exceed the layout's
    rank. Violations are reported with the failing mode-path.

    ```mlir
    // error: profile rank exceeds layout rank (top-level)
    %r = cute.coalesce(%l, %prof)
           : (!cute.layout<"(4,5):(1,4)">, !cute.coord<"(1,1,1)">) -> ...

    // error: profile rank exceeds composed B-layout rank (top-level)
    %r = cute.coalesce(%cl, %prof)
           : (!cute.composed_layout<"S<3,4,3> o 0 o (4,5):(1,4)">,
              !cute.coord<"(1,1,1)">) -> ...

    // error: profile sub-mode rank exceeds layout sub-mode rank
    //        at the recursion point — diagnostic names the path.
    // Top-level ranks match (both 2), but at mode 0 the profile
    // sub-mode (1,1) has rank 2 while the layout sub-mode `4` has
    // rank 1. Emits "expects target_profile rank (2) to not exceed
    // the layout rank (1) at mode path [0]".
    %r = cute.coalesce(%l, %prof)
           : (!cute.layout<"(4,(2,3)):(1,(4,8))">,
              !cute.coord<"((1,1),1)">) -> ...
    ```
  }];

  let arguments = (ins
    Cute_Arg<Cute_AnyLayoutType, "input layout">:$input,
    Cute_Arg<Optional<Cute_CoordType>, "coalescing profile (optional)">:$target_profile
  );
  let results = (outs
    Cute_Arg<Cute_AnyLayoutType, "coalesced layout">:$result
  );
  let assemblyFormat = [{
    `(` $input (`,` $target_profile^)? `)` attr-dict `:`
    functional-type(operands, results)
  }];
}

//===----------------------------------------------------------------------===//
// FlattenOp
//===----------------------------------------------------------------------===//

def Cute_FlattenOp : Cute_Op<"flatten", [
    Pure,
    DeclareOpInterfaceMethods<InferTypeOpInterface>
]> {
  let cuteSpecGroup = "LayoutAlgebra";
  let summary = "Flatten a tuple-kind value or layout's mode hierarchy to depth 1";
  let description = [{
    Flattens nested mode trees so the result has a single (depth-1)
    mode list. Restructures nesting only — per-mode leaf values are
    unchanged.

    Accepts any tuple-kind value (`!cute.shape`, `!cute.stride`,
    `!cute.coord`, `!cute.int_tuple`, `!cute.tile`) or a layout
    kind (`!cute.layout`, `!cute.composed_layout`).

    For a `!cute.composed_layout`, the operation is applied to the
    outer layout (`B`); the inner component (`A`) and the offset pass
    through unchanged.

    **Preconditions**

    - `$input` is `!cute.shape`, `!cute.stride`, `!cute.coord`,
      `!cute.int_tuple`, `!cute.tile`, `!cute.layout`, or
      `!cute.composed_layout`.

    **Postconditions**

    - Result kind matches `$input`'s kind.
    - For a tuple-kind input: result has depth 1, concatenating all
      leaves in their original order.
    - For a plain-layout input: result has depth 1 with the same
      total rank as the leaves of `$input`'s shape.
    - For a composed-layout input: result is `A o offset o flatten(B)`
      (A and offset unchanged).

    **Examples**

    ```mlir
    // Nested shape flattened to a depth-1 tuple.
    %r = cute.flatten(%src)
           : (!cute.shape<"(3,(4,5))">) -> !cute.shape<"(3,4,5)">

    // Nested static layout flattened to a depth-1 form.
    %r = cute.flatten(%src)
           : (!cute.layout<"(3,(4,5)):(8,(1,4))">)
          -> !cute.layout<"(3,4,5):(8,1,4)">

    // Already flat: depth-1 input passes through unchanged.
    %r = cute.flatten(%src)
           : (!cute.layout<"(4,3):(1,2)">) -> !cute.layout<"(4,3):(1,2)">

    // Composed layout: flatten applied to B only.
    %r = cute.flatten(%src)
           : (!cute.composed_layout<"(4,5):(1,4) o 2 o (3,(4,5)):(8,(1,4))">)
          -> !cute.composed_layout<"(4,5):(1,4) o 2 o (3,4,5):(8,1,4)">
    ```

    **Errors**

    - Operand kind not accepted by the op (e.g. `!cute.swizzle`):

      ```mlir
      // error: 'cute.flatten' op operand #0 must be ...
      %r = cute.flatten(%s)
             : (!cute.swizzle<"S<3,4,3>">) -> !cute.swizzle<"S<3,4,3>">
      ```

    - Declared result type does not match the inferred flatten result
      (declared result preserves the nesting of the input):

      ```mlir
      // error: 'cute.flatten' op inferred type(s)
      //   '!cute.layout<"(3,4,5):(8,1,4)">' are incompatible with
      //   return type(s) of operation
      //   '!cute.layout<"(3,(4,5)):(8,(1,4))">'
      %r = cute.flatten(%src)
             : (!cute.layout<"(3,(4,5)):(8,(1,4))">)
            -> !cute.layout<"(3,(4,5)):(8,(1,4))">
      ```

    - Same inferred-vs-declared mismatch on a composed layout (only
      `B` is flattened; declared `B` still nests):

      ```mlir
      // error: 'cute.flatten' op inferred type(s)
      //   '!cute.composed_layout<"(4,5):(1,4) o 2 o (3,4,5):(8,1,4)">'
      //   are incompatible with return type(s) of operation
      //   '!cute.composed_layout<"(4,5):(1,4) o 2 o (3,(4,5)):(8,(1,4))">'
      %r = cute.flatten(%src)
             : (!cute.composed_layout<"(4,5):(1,4) o 2 o (3,(4,5)):(8,(1,4))">)
            -> !cute.composed_layout<"(4,5):(1,4) o 2 o (3,(4,5)):(8,(1,4))">
      ```
  }];

  let arguments = (ins
    Cute_Arg<Cute_AnyIndexableType, "input value">:$input
  );
  let results = (outs
    Cute_Arg<Cute_AnyIndexableType, "flattened value">:$result
  );
  let assemblyFormat = [{
    `(` $input `)` attr-dict `:` functional-type(operands, results)
  }];
}

//===----------------------------------------------------------------------===//
// ComplementOp
//===----------------------------------------------------------------------===//

def Cute_ComplementOp : Cute_Op<"complement", [
    Pure,
    DeclareOpInterfaceMethods<InferTypeOpInterface>
]> {
  let cuteSpecGroup = "LayoutAlgebra";
  let summary = "Compute the complement layout of a layout, optionally under a cotarget domain";
  let description = [{
    Produces a layout ``L*`` that maps to elements not covered by the
    input layout ``L``. Together ``(L, L*)`` achieves greater surjectivity
    — though ``(L, L*)`` is not always fully surjective.

    In plain terms: think of the codomain as a flat index space.
    Surjective means every element in that space is reachable by at least one
    input index. If ``L`` has a codomain ``{0, 1, ..., 5}`` only reaches indices
    ``{0, 2, 4}``, then ``L*`` reaches the remaining ``{1, 3, 5}``, so together
    they cover more of the domain than ``L`` alone.

    There are two modes, selected by whether ``$cotarget`` is present:

    - With ``$cotarget`` (cotarget-aware): the cotarget bounds the
      codomain over which the complement is taken. ``$cotarget`` can be
      a ``!cute.shape`` or ``!cute.layout`` (only the shape part is used).
      This mode rejects scaled-basis input strides at cutegen level.

    - Without ``$cotarget`` (intrinsic): cutegen computes the
      complement directly from the input layout's stride structure,
      without bounding by a separate codomain. This mode accepts
      scaled-basis input strides (e.g. ``complement(3:1@0) = (1):(3@0)``).

    The result is always a plain ``!cute.layout``.

    **Preconditions**

    - ``$input`` is ``!cute.layout``.
    - When present, ``$cotarget`` is ``!cute.shape`` or ``!cute.layout``.
    - If given non-static input for the intrinsic variant, mixed scaled
      basis-with-ratio-value, etc., the operation will fail with a
      `"expects a valid complement result, but construction failed"` diagnostic.

    **Postconditions**

    - Result is ``!cute.layout``.
    - With ``$cotarget``: result maps to elements of the cotarget
      domain not reached by ``$input``.

    - Without ``$cotarget``: result is the minimal layout that satisfies the
      rest of the post conditions.

    - The result's image fills the codomain of ``$input``
    - The result is weakly congruent to the codomain of ``$input``
    - The result's image is strictly ordered (i.e., ``$result`` evaluated at coordinate ``i`` is
      less than ``$result`` evaluated at coordinate ``i + 1``)
    - The result's image is disjoint from ``$input``'s image.

    **Examples**

    ```mlir
    // Cotarget-aware: input already covers its domain — result is 1:3.
    %r = cute.complement(%input, %cotarget)
           : (!cute.layout<"3:1">, !cute.shape<"3">) -> !cute.layout<"1:3">

    // Cotarget-aware: 3:2 under domain 6 — complement 2:1 fills the gaps.
    %r = cute.complement(%input, %cotarget)
           : (!cute.layout<"3:2">, !cute.shape<"6">) -> !cute.layout<"2:1">

    // Cotarget-aware: layout cotarget (only shape used; stride ignored).
    %r = cute.complement(%input, %cotarget)
           : (!cute.layout<"3:2">, !cute.layout<"6:1">) -> !cute.layout<"2:1">

    // Intrinsic (no cotarget): scaled-basis input accepted.
    %r = cute.complement(%input) : !cute.layout<"3:1@0"> -> !cute.layout<"(1):(3@0)">
    ```

    **Errors**

    - cotarget-aware overload rejects scaled-basis input strides

      ```mlir
      %r = cute.complement(%input, %cotarget)
             : (!cute.layout<"(2,3):(1@0,1@1)">, !cute.shape<"(2,3)">) -> ...
      ```
  }];

  let arguments = (ins
    Cute_Arg<Cute_LayoutType, "input layout">:$input,
    Cute_Arg<Optional<AnyTypeOf<[Cute_LayoutType, Cute_ShapeType],
                                "!cute.layout or !cute.shape">>,
             "optional cotarget domain (absent means the minimal complement "
             "that satisfies the post-conditions)">:$cotarget
  );
  let results = (outs
    Cute_Arg<Cute_LayoutType, "complement layout">:$result
  );
  let assemblyFormat = [{
    `(` $input (`,` $cotarget^)? `)` attr-dict `:`
    functional-type(operands, results)
  }];
}

//===----------------------------------------------------------------------===//
// GroupModesOp
//===----------------------------------------------------------------------===//

def Cute_GroupModesOp : Cute_Op<"group_modes", [
    Pure,
    DeclareOpInterfaceMethods<InferTypeOpInterface>
]> {
  let cuteSpecGroup = "LayoutAlgebra";
  let summary = "Group modes [begin, end) into a single nested mode";
  let description = [{
    Groups the top-level modes in the half-open range ``[begin, end)``
    of the input layout into one nested mode, increasing the hierarchy
    by one level at that position. All modes outside the range are
    left unchanged.

    For example, grouping modes 0 and 1 of ``(4,5,6):(1,4,20)`` produces
    ``((4,5),6):((1,4),20)`` — the first two modes are wrapped into a
    nested pair while mode 2 stays at the top level.

    For a ``!cute.composed_layout`` (``A o offset o B``), grouping is
    applied to the outer (``B``) component; the inner (``A``) component
    and offset are preserved unchanged.

    **Preconditions**

    - ``$input`` is ``!cute.layout`` or ``!cute.composed_layout``.
    - ``0 <= $begin``.
    - ``$begin < $end``.
    - ``$end <= rank($input)`` (for composed inputs, rank of the B
      layout).

    **Postconditions**

    - Result kind matches ``$input``'s kind.
    - For a plain-layout input: result has rank `rank($input) - ($end -
      $begin) + 1``; the modes in ``[$begin, $end)` become a single
      nested mode at position ``$begin``.

    - For a composed-layout input: result is
      ``A o offset o group_modes(B, $begin, $end)`` (A and offset
      unchanged).

    **Examples**

    ```mlir
    // Group first two modes of a rank-3 layout → rank-2 with nested first mode.
    %r = cute.group_modes<0, 2> (%input)
           : (!cute.layout<"(4,5,6):(1,4,20)">) -> !cute.layout<"((4,5),6):((1,4),20)">

    // Group last two modes of a rank-3 layout → rank-2 with nested last mode.
    %r = cute.group_modes<1, 3> (%input)
           : (!cute.layout<"(4,5,6):(1,4,20)">) -> !cute.layout<"(4,(5,6)):(1,(4,20))">

    // Group all modes → rank-1 single nested mode.
    %r = cute.group_modes<0, 3> (%input)
           : (!cute.layout<"(4,5,6):(1,4,20)">) -> !cute.layout<"((4,5,6)):((1,4,20))">

    // Composed layout: grouping applies to B; A and offset unchanged.
    // A = (4,5):(1,4), offset = 2, B = (3,4,5):(1,3,12).
    // Grouping B modes [0,2) nests shape (3,4) and stride (1,3).
    %r = cute.group_modes<0, 2> (%input)
           : (!cute.composed_layout<"(4,5):(1,4) o 2 o (3,4,5):(1,3,12)">)
          -> !cute.composed_layout<"(4,5):(1,4) o 2 o ((3,4),5):((1,3),12)">
    ```

    **Errors**

    - begin < 0 (negative indices are not supported)

      ```mlir
      //        Emits "expects 0 <= begin, but got begin=-1".
      %r = cute.group_modes<-1, 2> (%input)
             : (!cute.layout<"(4,5,6):(1,4,20)">) -> ...
      ```

    - begin > end

      ```mlir
      //        Emits "expects begin < end, but got begin=2, end=1".
      %r = cute.group_modes<2, 1> (%input)
             : (!cute.layout<"(4,5,6):(1,4,20)">) -> ...
      ```

    - begin == end (empty range)

      ```mlir
      //        Emits "expects begin < end, but got begin=1, end=1".
      %r = cute.group_modes<1, 1> (%input)
             : (!cute.layout<"(4,5,6):(1,4,20)">) -> ...
      ```

    - end exceeds layout rank

      ```mlir
      //        Emits "expects end <= rank(input)=3, but got end=4".
      %r = cute.group_modes<0, 4> (%input)
             : (!cute.layout<"(4,5,6):(1,4,20)">) -> ...
      ```

    - end exceeds composed B-layout rank (rank is layout_b rank)

      ```mlir
      %r = cute.group_modes<0, 4> (%input)
             : (!cute.composed_layout<"(4,5):(1,4) o 2 o (3,4,5):(1,3,12)">) -> ...
      ```
  }];

  let arguments = (ins
    Cute_Arg<Cute_AnyLayoutType, "input layout">:$input,
    Cute_Arg<I32Attr, "first mode index of the group (inclusive)">:$begin,
    Cute_Arg<I32Attr, "one past the last mode index of the group">:$end
  );
  let results = (outs
    Cute_Arg<Cute_AnyLayoutType, "grouped layout">:$result
  );
  let assemblyFormat = [{
    `<` $begin `,` $end `>` `(` $input `)` attr-dict `:`
    functional-type($input, $result)
  }];
}

//===----------------------------------------------------------------------===//
// RecastLayoutOp
//===----------------------------------------------------------------------===//

def Cute_RecastLayoutOp : Cute_Op<"recast_layout", [
    Pure,
    DeclareOpInterfaceMethods<InferTypeOpInterface>
]> {
  let cuteSpecGroup = "LayoutAlgebra";
  let summary = "Recast a layout to a different element bit-width";
  let description = [{
    Adjusts a layout so that its indices address elements of a new
    bit-width instead of the original bit-width. This is the
    layout-level counterpart of a C++ ``reinterpret_cast`` on a pointer:
    the same bytes in memory are now viewed as a different element
    type.

    The operation selects a case based on ``$new_type_bits`` (``new``)
    and ``$old_type_bits`` (``old``):

    - **Identity** (``new == old``): no change; the result equals the
      input.

    - **Upcast** (``new % old == 0``, ratio ``R = new / old``): the new
      element is larger, so fewer elements fit in the same memory. The
      stride-1 leaf's extent shrinks by ``R``; other strides are
      reduced (exact division when ``stride % R == 0``, ceiling division
      otherwise).

    - **Downcast** (``old % new == 0``, ratio ``R = old / new``): the
      new element is smaller, so more elements are needed. The stride-1
      leaf's extent grows by ``R``; all other strides are multiplied by
      ``R``.

    - **GCD case** (when neither ``new % old == 0`` nor
      ``old % new == 0``): Let ``G = gcd(new, old)``. The result is
      equivalent to upcasting by ``new/G`` and then downcasting by
      ``old/G``: ``downcast(old/G, upcast(new/G, $src))``.

    For ``!cute.composed_layout`` (``A o O o B``), the recast applies to
    all components:

    - The B layout is recast as above.
    - The offset O is divided by ``R`` (upcast) or multiplied by ``R``
      (downcast). O must be a static integer; for upcast, O must also
      be divisible by ``R``.
    - For a layout A, A is recast as above.
    - For a swizzle A ``S<num_bits, num_base, num_shift>``, the
      *num_base* (pattern-bits) parameter is shifted by ``log2(R)``:
      upcast decreases ``num_base`` by ``log2(R)``; downcast increases
      it. ``num_bits`` and ``num_shift`` are unchanged. The ratio ``R``
      must be a power of 2 when recasting a swizzle.

    **Preconditions**

    - ``$new_type_bits > 0``.
    - ``$old_type_bits > 0``.
    - ``$src`` is ``!cute.layout`` or ``!cute.composed_layout``.
    - For ``!cute.layout``: strides must not use scaled-basis (``@``)
      notation.
    - For ``!cute.composed_layout``: the A and B layout's strides must not use
      scaled-basis notation.
    - For ``!cute.composed_layout``: the offset must be a static integer.
    - For ``!cute.composed_layout`` when upcasting (``new % old == 0``):
      the offset must additionally be divisible by ``R = new / old``.
    - For composed sources with a swizzle A: ``num_base - log2(R)``
      (upcast) must remain non-negative, which requires ``R`` to be a
      power of 2 and ``log2(R) <= num_base``.

    **Postconditions**

    - Result kind matches ``$src``'s kind.
    - For identity recast, result equals ``$src``.
    - For upcast (``R = new / old``): the stride-1 leaf's extent shrinks
      by ``R``; non-unit strides are reduced via ceiling division. When
      all non-unit strides are multiples of ``R`` the division is exact.
    - For downcast (``R = old / new``): the stride-1 leaf's extent grows
      by ``R``; all other strides are multiplied by ``R``.
    - For the GCD case (``G = gcd(new, old)``): the result is as if
      upcast by ``new/G`` then downcast by ``old/G`` were applied in
      sequence.
    - For composed sources with a swizzle A, the result's swizzle has
      ``num_base`` adjusted by ``log2(R)`` per the rule above.

    **Examples**

    ```mlir
    // Upcast ×4: new=32-bit, old=8-bit → ratio 4.
    // Stride-1 mode shape 32 → 8; non-unit stride 32 → 8.
    %r = cute.recast_layout<32, 8> (%src)
           : !cute.layout<"(32,4):(1,32)"> -> !cute.layout<"(8,4):(1,8)">

    // Downcast ×4: new=8-bit, old=32-bit → ratio 4.
    // Stride-1 mode shape 8 → 32; non-unit stride 8 → 32.
    %r = cute.recast_layout<8, 32> (%src)
           : !cute.layout<"(8,4):(1,8)"> -> !cute.layout<"(32,4):(1,32)">

    // Identity: new == old, result equals input.
    %r = cute.recast_layout<32, 32> (%src)
           : !cute.layout<"(8,4):(1,8)"> -> !cute.layout<"(8,4):(1,8)">

    // Composed layout with layout A: recast applied to all components.
    %r = cute.recast_layout<32, 16> (%src)
           : !cute.composed_layout<"(4,5):(1,4) o 2 o (8,4):(1,8)">
          -> !cute.composed_layout<"(2,5):(1,2) o 1 o (4,4):(1,4)">

    // Composed layout with swizzle A: upcast 32→8 shifts num_base
    // by log2(32/8) = 2, so S<3,5,4> → S<3,3,4>.
    %r = cute.recast_layout<32, 8> (%src)
           : !cute.composed_layout<"S<3,5,4> o 0 o (32,?):(1,?)">
          -> !cute.composed_layout<"S<3,3,4> o 0 o (8,?):(1,?)">

    // Downcast ×4 on dynamic layout.
    %r = cute.recast_layout<8, 32> (%src)
           : !cute.layout<"(?,4):(1,?)"> -> !cute.layout<"(?,4):(1,?)">
    ```

    **Errors**

    - new_type_bits is zero

      ```mlir
      %r = cute.recast_layout<0, 8> (%src) : !cute.layout<"(8,4):(1,8)"> to ...
      ```

    - old_type_bits is zero

      ```mlir
      %r = cute.recast_layout<8, 0> (%src) : !cute.layout<"(8,4):(1,8)"> to ...
      ```

    - negative bit-width

      ```mlir
      %r = cute.recast_layout<-32, 8> (%src) : !cute.layout<"(8,4):(1,8)"> to ...
      ```

    - source has scaled-basis strides

      ```mlir
      %r = cute.recast_layout<32, 8> (%src)
             : !cute.layout<"(2,3):(1@0,1@1)"> to ...
      ```

    - upcast of composed layout where offset is not divisible by R
      (here offset 3 is not divisible by R = 32/16 = 2)

      ```mlir
      %r = cute.recast_layout<32, 16> (%src)
             : !cute.composed_layout<"(4,5):(1,4) o 3 o (8,4):(1,8)"> to ...
      ```
  }];

  let arguments = (ins
    Cute_Arg<I32Attr, "new element bit-width">:$new_type_bits,
    Cute_Arg<I32Attr, "old element bit-width">:$old_type_bits,
    Cute_Arg<Cute_AnyLayoutType, "source layout">:$src
  );
  let results = (outs
    Cute_Arg<Cute_AnyLayoutType, "recast layout">:$dst
  );
  let assemblyFormat = [{
    `<` $new_type_bits `,` $old_type_bits `>` `(` $src `)` attr-dict `:`
    qualified(type($src)) `->` qualified(type($dst))
  }];
}

//===----------------------------------------------------------------------===//
// SliceOp
//===----------------------------------------------------------------------===//

def Cute_SliceOp : Cute_Op<"slice", [
    Pure,
    DeclareOpInterfaceMethods<InferTypeOpInterface>
]> {
  let cuteSpecGroup = "LayoutAlgebra";
  let summary = "Slice a value, keeping modes where the coordinate is `_`";
  let description = [{
    Projects a tuple-kind value or layout through a coordinate that
    mixes integer values and underscore wildcards (``_``). Each
    top-level mode of ``input`` is processed according to the
    corresponding element of ``coord``:

    - ``_`` (underscore): the mode is kept in the result.
    - integer ``N``: the mode is removed from the result.

    For tuple-kind inputs (``!cute.shape``, ``!cute.stride``,
    ``!cute.int_tuple``, ``!cute.coord``), slice is pure structural mode
    selection — the integer-marked modes are simply dropped. For
    ``!cute.layout``, the removed modes' fixed indices contribute to
    where the resulting layout maps from; the result captures only
    the underscore-marked modes' shape and stride. For
    ``!cute.composed_layout`` (affine A), the coordinate is applied to
    the outer layout (B); the integer-marked modes' contribution is
    accumulated into the offset.

    Rank-preserving slices use all underscores. ``slice`` is the dual
    of ``dice`` — where dice keeps integer-marked modes and drops
    underscore-marked modes, slice does the inverse.

    **Preconditions**

    - ``$input`` is one of ``!cute.shape``, ``!cute.stride``,
      ``!cute.int_tuple``, ``!cute.coord``, ``!cute.layout``, or
      ``!cute.composed_layout``.

    - ``$coord`` is ``!cute.coord``.
    - ``$coord`` is weakly congruent with ``$input`` (for composed
      inputs, with the outer B layout's shape).

    - For ``!cute.composed_layout`` with swizzle inner: the outer
      layout must be static and ``$coord`` must contain at least one
      underscore.

    **Postconditions**

    - Result kind matches ``$input``'s kind.
    - The result mirrors ``$coord``'s structure with integer-marked
      positions removed; each remaining underscore in ``$coord`` is
      replaced by the corresponding sub-mode of ``$input`` preserved
      verbatim (including any internal nesting). Tuple sub-coords
      recurse with the same rules into the corresponding sub-mode.
      See ``Nesting examples`` below for worked cases.

    - Composed-layout input (affine A): result is
      ``A o offset' o slice(B, $coord)``, where ``offset'`` accumulates
      the integer-marked modes' contribution into the original
      offset.

    **Examples**

    ```mlir
    // Layout: keep mode 1, fix mode 0 at 0 and mode 2 at 1.
    %r = cute.slice(%src, %coord)
           : !cute.layout<"(2,3,4):(1,2,6)">, !cute.coord<"(0,_,1)">
    // result: !cute.layout<"(3):(2)">

    // Shape: keep modes 0 and 2, drop mode 1.
    %r = cute.slice(%src, %coord)
           : !cute.shape<"(2,3,4)">, !cute.coord<"(_,1,_)">
    // result: !cute.shape<"(2,4)">

    // Stride: dynamic stride leaf preserved.
    %r = cute.slice(%src, %coord)
           : !cute.stride<"(?,2,4)">, !cute.coord<"(_,0,_)">
    // result: !cute.stride<"(?,4)">

    // IntTuple: drop a nested static.
    %r = cute.slice(%src, %coord)
           : !cute.int_tuple<"(1,(2,3))">, !cute.coord<"(_,1)">
    // result: !cute.int_tuple<"(1)">

    // Coord: identity (all underscores) — result equals input.
    %r = cute.slice(%src, %coord)
           : !cute.coord<"(0,_,1)">, !cute.coord<"(_,_,_)">
    // result: !cute.coord<"(0,_,1)">

    // ComposedLayout, offset accumulates: fix mode 0 of B at index 1.
    // Original offset 2 + B(1,0) = 2 + 1*1 = 3.
    %r = cute.slice(%src, %coord)
           : !cute.composed_layout<"(4,5):(1,4) o 2 o (8,3):(1,8)">,
             !cute.coord<"(1,_)">
    // result: !cute.composed_layout<"(4,5):(1,4) o 3 o (3):(8)">

    // ComposedLayout, fully-fixed coord: B is sliced to `():()`,
    // and the offset absorbs every fixed-coord contribution.
    // Original offset 2 + B(1,1) = 2 + 1*1 + 1*8 = 11.
    %r = cute.slice(%src, %coord)
           : !cute.composed_layout<"(4,5):(1,4) o 2 o (8,3):(1,8)">,
             !cute.coord<"(1,1)">
    // result: !cute.composed_layout<"(4,5):(1,4) o 11 o ():()">

    // ComposedLayout identity: all-underscore coord leaves the
    // composed value unchanged.
    %r = cute.slice(%src, %coord)
           : !cute.composed_layout<"(4,5):(1,4) o 2 o (8,3):(1,8)">,
             !cute.coord<"(_,_)">
    // result: !cute.composed_layout<"(4,5):(1,4) o 2 o (8,3):(1,8)">

    // --- Nesting examples — the result mirrors `$coord`'s structure ---

    // Scalar underscore: top-level `_` keeps the whole input as a
    // single sub-mode, i.e. slice acts as identity.
    %r = cute.slice(%src, %coord)
           : !cute.layout<"(2,3,4):(1,2,6)">, !cute.coord<"_">
    // result: !cute.layout<"(2,3,4):(1,2,6)">

    // Nested input, top-level underscore: keeps the entire nested
    // `(2,4)` sub-mode (with its internal nesting preserved).
    %r = cute.slice(%src, %coord)
           : !cute.layout<"((2,4),3):((1,2),8)">, !cute.coord<"(_,0)">
    // result: !cute.layout<"((2,4)):((1,2))">

    // Nested input, sub-coord recurses into the nested sub-mode.
    // The sub-coord `(_,0)` keeps `2:1` from `(2,4):(1,2)`; the
    // outer `_` keeps `3:8` as a top-level mode. Sub-coord results
    // flatten at the outer level → `(2, 3):(1, 8)`.
    %r = cute.slice(%src, %coord)
           : !cute.layout<"((2,4),3):((1,2),8)">, !cute.coord<"((_,0),_)">
    // result: !cute.layout<"(2,3):(1,8)">
    ```

    **Errors**

    - coord rank exceeds layout rank

      ```mlir
      %r = cute.slice(%src, %coord)
             : !cute.layout<"(2,3):(1,2)">, !cute.coord<"(_,_,_)">
      ```

    - coord rank exceeds composed B-layout rank

      ```mlir
      %r = cute.slice(%src, %coord)
             : !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">,
               !cute.coord<"(_,_,_)">
      ```

    - swizzle-A composed slice requires static outer layout

      ```mlir
      %r = cute.slice(%src, %coord)
             : !cute.composed_layout<"S<3,5,4> o 0 o (?,4):(1,?)">,
               !cute.coord<"(_,1)">
      ```

    - swizzle-A composed slice requires at least one underscore

      ```mlir
      %r = cute.slice(%src, %coord)
             : !cute.composed_layout<"S<3,5,4> o 0 o (8,4):(1,8)">,
               !cute.coord<"(2,1)">
      ```
  }];

  let arguments = (ins
    Cute_Arg<Cute_SliceableType, "source value">:$input,
    Cute_Arg<Cute_CoordType, "slice coordinate">:$coord
  );
  let results = (outs
    Cute_Arg<Cute_SliceableType, "sliced value">:$result
  );
  let assemblyFormat = [{ `(` operands `)` attr-dict `:` type(operands) }];
}

//===----------------------------------------------------------------------===//
// DiceOp
//===----------------------------------------------------------------------===//

def Cute_DiceOp : Cute_Op<"dice", [
    Pure,
    DeclareOpInterfaceMethods<InferTypeOpInterface>
]> {
  let cuteSpecGroup = "LayoutAlgebra";
  let summary = "Dice a value, keeping modes where the coordinate is an integer";
  let description = [{
    Selects a subset of modes from a tuple-kind value or layout
    according to a fully-static coordinate. Each top-level mode of
    ``input`` is processed according to the corresponding element of
    ``coord``:

    - integer ``N``: the mode is kept in the result.
    - ``_`` (underscore): the mode is discarded from the result.

    ``dice`` is the dual of ``slice``: where ``slice`` keeps underscore
    modes, ``dice`` keeps non-underscore modes. The coordinate must be
    fully static (no ``?`` dynamic elements); use ``cute.slice`` if
    dynamic mode selection is needed.

    For a ``!cute.composed_layout``, the coordinate is applied to the
    outer layout (``B``); the inner layout (``A``) and the offset pass
    through unchanged.

    For tuple-kind mode pick with explicit indices, see
    ``cute.select`` — dice and select are equivalent up to convention
    for tuple inputs (dice uses an underscore-coord; select uses an
    index list).

    **Preconditions**

    - ``$input`` is one of ``!cute.shape``, ``!cute.stride``,
      ``!cute.int_tuple``, ``!cute.coord``, ``!cute.layout``, or
      ``!cute.composed_layout``.

    - ``$coord`` is ``!cute.coord`` and is fully static (no ``?``
      elements).

    - ``$coord`` is weakly congruent with ``$input`` (for composed
      inputs, with the outer B layout's shape).

    **Postconditions**

    - Result kind matches ``$input``'s kind.
    - The result mirrors ``$coord``'s structure with underscore-marked
      positions removed; each remaining integer in ``$coord`` is
      replaced by the corresponding sub-mode of ``$input`` preserved
      verbatim (including any internal nesting). Tuple sub-coords
      recurse with the same rules into the corresponding sub-mode.
      See ``Nesting examples`` below for worked cases.

    - Composed-layout input: result is
      ``A o offset o dice(B, $coord)`` — A and offset are unchanged.

    **Examples**

    ```mlir
    // Layout: keep mode 1 (middle), discard modes 0 and 2.
    %r = cute.dice(%src, %coord)
           : !cute.layout<"(2,3,4):(1,2,6)">, !cute.coord<"(_,1,_)">
    // result: !cute.layout<"(3):(2)">

    // Shape: keep mode 0 only.
    %r = cute.dice(%src, %coord)
           : !cute.shape<"(2,3,4)">, !cute.coord<"(1,_,_)">
    // result: !cute.shape<"(2)">

    // Stride: drop a dynamic mode.
    %r = cute.dice(%src, %coord)
           : !cute.stride<"(?,2,4)">, !cute.coord<"(_,1,1)">
    // result: !cute.stride<"(2,4)">

    // IntTuple: keep a nested mode.
    %r = cute.dice(%src, %coord)
           : !cute.int_tuple<"(1,(2,3))">, !cute.coord<"(_,1)">
    // result: !cute.int_tuple<"((2,3))">

    // Coord: keep modes 1 and 2 with mixed static/underscore content.
    %r = cute.dice(%src, %coord)
           : !cute.coord<"(0,_,1)">, !cute.coord<"(_,1,1)">
    // result: !cute.coord<"(_,1)">

    // ComposedLayout (affine A): dice keeps mode 1 of B; A and
    // offset pass through unchanged.
    %r = cute.dice(%src, %coord)
           : !cute.composed_layout<"(4,5):(1,4) o 2 o (8,3,4):(1,8,24)">,
             !cute.coord<"(_,1,_)">
    // result: !cute.composed_layout<"(4,5):(1,4) o 2 o (3):(8)">

    // ComposedLayout (swizzle A): dice keeps modes 0 and 2 of B;
    // swizzle and offset pass through unchanged.
    %r = cute.dice(%src, %coord)
           : !cute.composed_layout<"S<3,5,4> o 0 o (8,4,2):(1,8,32)">,
             !cute.coord<"(1,_,1)">
    // result: !cute.composed_layout<"S<3,5,4> o 0 o (8,2):(1,32)">

    // --- Nesting examples — the result mirrors `$coord`'s structure ---

    // Scalar integer: top-level `1` keeps the whole input as a
    // single sub-mode, i.e. dice acts as identity.
    %r = cute.dice(%src, %coord)
           : !cute.layout<"(2,3,4):(1,2,6)">, !cute.coord<"1">
    // result: !cute.layout<"(2,3,4):(1,2,6)">

    // Nested input, top-level integer: keeps the entire nested
    // `(2,4)` sub-mode (with its internal nesting preserved).
    %r = cute.dice(%src, %coord)
           : !cute.layout<"((2,4),3):((1,2),8)">, !cute.coord<"(1,_)">
    // result: !cute.layout<"((2,4)):((1,2))">

    // Nested input, sub-coord recurses into the nested sub-mode.
    // The sub-coord `(1,_)` keeps `2:1` from `(2,4):(1,2)`; the
    // outer `_` drops mode 1. Sub-coord results flatten at the
    // outer level → `(2):(1)`.
    %r = cute.dice(%src, %coord)
           : !cute.layout<"((2,4),3):((1,2),8)">, !cute.coord<"((1,_),_)">
    // result: !cute.layout<"(2):(1)">
    ```

    **Errors**

    - coord rank exceeds layout rank

      ```mlir
      %r = cute.dice(%src, %coord)
             : !cute.layout<"(2,3):(1,2)">, !cute.coord<"(1,1,1)">
      ```

    - coord contains a dynamic `?` element (use cute.slice for dynamic

      ```mlir
      //        mode selection)
      %r = cute.dice(%src, %coord)
             : !cute.layout<"(2,3):(1,2)">, !cute.coord<"(?,1)">
      ```

    - coord rank exceeds composed B-layout rank

      ```mlir
      %r = cute.dice(%src, %coord)
             : !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">,
               !cute.coord<"(1,1,1)">
      ```
  }];

  let arguments = (ins
    Cute_Arg<Cute_SliceableType, "source value">:$input,
    Cute_Arg<Cute_CoordType, "static dice coordinate (no '?' elements)">:$coord
  );
  let results = (outs
    Cute_Arg<Cute_SliceableType, "diced value">:$result
  );
  let assemblyFormat = [{ `(` operands `)` attr-dict `:` type(operands) }];
}

//===----------------------------------------------------------------------===//
// RightInverseOp
//===----------------------------------------------------------------------===//

def Cute_RightInverseOp : Cute_Op<"right_inverse", [
    Pure,
    DeclareOpInterfaceMethods<InferTypeOpInterface>
]> {
  let cuteSpecGroup = "LayoutAlgebra";
  let summary = "Right inverse of a static layout";
  let description = [{
    Computes the right inverse of a fully-static layout. The right
    inverse ``R`` satisfies ``layout ∘ R = identity`` on the codomain of
    ``layout``, making it useful for deriving inverse index mappings.

    **Preconditions**

    - ``$input`` is ``!cute.layout``.
    - ``$input`` is fully static (no ``?`` dynamic extents or strides).
    - ``$input``'s strides are either all plain integer or all
      scaled-basis (``@``); mixing the two within a single layout is
      rejected.

    **Postconditions**

    - Result is ``!cute.layout`` and equals the right inverse ``R`` such
      that ``$input ∘ R`` is the identity on ``$input``'s codomain.

    Worked example — column-major ``L = (2,3):(1,2)``

    Treating ``L`` as a function from a 1-D ``integral_coord`` ``i ∈ [0, 6)``
    to an ``index``:

    ```text
    L(integral_coord) = L(coord) = Calculate index = Index
    L(0)              = L(0,0)   = 0*1 + 0*2      = 0
    L(1)              = L(1,0)   = 1*1 + 0*2      = 1
    L(2)              = L(0,1)   = 0*1 + 1*2      = 2
    L(3)              = L(1,1)   = 1*1 + 1*2      = 3
    L(4)              = L(0,2)   = 0*1 + 2*2      = 4
    L(5)              = L(1,2)   = 1*1 + 2*2      = 5
    ```

    ``L`` covers the codomain ``{0..5}`` in order, so it is the identity
    on that range. The right inverse ``R`` must satisfy
    ``L(R(index)) = index``, so here ``R(index) = index`` as well. CuTe
    writes this as the flat 1-D layout ``R = 6:1`` — the domain of ``R``
    matches the codomain of ``L``, so the multi-mode shape is no longer
    needed.

    ``R`` as a function from index to integral_coord:

    ```text
    R(index) = R(Index) = Calculate integral_coord = Integral_coord
    R(0)     = R(0)     = 0*1                     = 0
    R(1)     = R(1)     = 1*1                     = 1
    R(2)     = R(2)     = 2*1                     = 2
    R(3)     = R(3)     = 3*1                     = 3
    R(4)     = R(4)     = 4*1                     = 4
    R(5)     = R(5)     = 5*1                     = 5
    ```

    Composing back: ``L(R(index)) = L(index) = index`` for every index.

    Worked example — row-major ``L = (2,3):(3,1)``

    Same shape, swapped strides, gives a different walk over the codomain:

    ```text
    L(integral_coord) = L(coord) = Calculate index = Index
    L(0)              = L(0,0)   = 0*3 + 0*1      = 0
    L(1)              = L(1,0)   = 1*3 + 0*1      = 3
    L(2)              = L(0,1)   = 0*3 + 1*1      = 1
    L(3)              = L(1,1)   = 1*3 + 1*1      = 4
    L(4)              = L(0,2)   = 0*3 + 2*1      = 2
    L(5)              = L(1,2)   = 1*3 + 2*1      = 5
    ```

    ``L`` produces the permutation ``0, 3, 1, 4, 2, 5`` of the codomain
    ``{0..5}``. The right inverse ``R`` must undo this —
    ``L(R(index)) = index`` requires ``R`` to map
    ``0→0, 1→2, 2→4, 3→1, 4→3, 5→5``. That is precisely the rank-2
    layout ``R = (3,2):(2,1)``. Unlike the column-major case the result
    keeps two modes, because the inverse permutation is itself a
    non-trivial 2-D walk.

    ``R`` as a function from index to integral_coord:

    ```text
    R(index) = R(coord) = Calculate integral_coord = Integral_coord
    R(0)     = R(0,0)   = 0*2 + 0*1               = 0
    R(1)     = R(1,0)   = 1*2 + 0*1               = 2
    R(2)     = R(2,0)   = 2*2 + 0*1               = 4
    R(3)     = R(0,1)   = 0*2 + 1*1               = 1
    R(4)     = R(1,1)   = 1*2 + 1*1               = 3
    R(5)     = R(2,1)   = 2*2 + 1*1               = 5
    ```

    Composing back, ``L(R(index))`` recovers the integral_coord for each input:

    ```text
    L(R(0)) = L(0) = 0
    L(R(1)) = L(2) = 1
    L(R(2)) = L(4) = 2
    L(R(3)) = L(1) = 3
    L(R(4)) = L(3) = 4
    L(R(5)) = L(5) = 5
    ```

    The same pattern generalizes to higher ranks: the rank-3 row-major
    example ``(4,3):(3,1) → (3,4):(4,1)`` below has the modes transposed
    for the same reason.

    **Examples**

    ```mlir
    // Column-major 4×3 → flat right inverse (compact column-major over codomain)
    %r = cute.right_inverse(%src)
           : (!cute.layout<"(4,3):(1,4)">) -> !cute.layout<"12:1">

    // Row-major 4×3 → modes transposed (same shape on the codomain side)
    %r = cute.right_inverse(%src)
           : (!cute.layout<"(4,3):(3,1)">) -> !cute.layout<"(3,4):(4,1)">

    // Already-compact rank-2 input → flat right inverse over codomain
    %r = cute.right_inverse(%src)
           : (!cute.layout<"(2,4):(1,2)">) -> !cute.layout<"8:1">

    // Scaled-basis strides → flattened to plain scalar strides
    %r = cute.right_inverse(%src)
           : (!cute.layout<"(4,3):(1@0,1@1)">) -> !cute.layout<"(4,3):(1,4)">
    ```

    **Errors**

    - dynamic shape (right inverse not computable at compile time)

      ```mlir
      %r = cute.right_inverse(%src) : (!cute.layout<"(?,3):(1,4)">) -> ...
      ```

    - dynamic stride

      ```mlir
      %r = cute.right_inverse(%src) : (!cute.layout<"(4,3):(?,4)">) -> ...
      ```

    - mix of plain-integer and scaled-basis strides

      ```mlir
      %r = cute.right_inverse(%src) : (!cute.layout<"(4,3):(1@0,4)">) -> ...
      ```

    - declared result layout does not match the inferred right inverse

      ```mlir
      %r = cute.right_inverse(%src)
             : (!cute.layout<"(4,3):(1,4)">) -> !cute.layout<"6:1">
      ```
  }];

  let arguments = (ins
    Cute_Arg<Cute_LayoutType, "static input layout">:$input
  );
  let results = (outs
    Cute_Arg<Cute_LayoutType, "right inverse layout">:$result
  );
  let assemblyFormat = [{
    `(` $input `)` attr-dict `:` functional-type(operands, results)
  }];
}

//===----------------------------------------------------------------------===//
// LeftInverseOp
//===----------------------------------------------------------------------===//

def Cute_LeftInverseOp : Cute_Op<"left_inverse", [
    Pure,
    DeclareOpInterfaceMethods<InferTypeOpInterface>
]> {
  let cuteSpecGroup = "LayoutAlgebra";
  let summary = "Left inverse of a static injective layout";
  let description = [{
    Computes the left inverse of a fully-static injective layout. A
    layout is injective when distinct ``integral_coord`` values map
    to distinct ``index`` values (no two integral_coords produce the
    same index). Given an input layout ``L``, the left inverse ``Linv``
    satisfies ``Linv ∘ L = identity`` on the domain of ``L`` — applying
    ``Linv`` to the index that ``L`` produced recovers the original
    integral_coord.

    **Preconditions**

    - ``$input`` is ``!cute.layout``.
    - ``$input`` is fully static (no ``?`` dynamic extents or strides).
    - ``$input`` is injective; non-injective layouts have no left
      inverse and the operation will fail to infer a return type.

    - ``$input``'s strides are either all plain integer or all
      scaled-basis (``@``); mixing the two within a single layout is
      rejected.

    **Postconditions**

    - Result is ``!cute.layout`` and equals the left inverse ``Linv``
      such that ``Linv ∘ $input`` is the identity on ``$input``'s domain.

    Worked example — column-major ``L = (2,3):(1,2)``

    Treating ``L`` as a function from a 1-D ``integral_coord`` ``i ∈ [0, 6)``
    to an ``index``:

    ```text
    L(integral_coord) = L(coord) = Calculate index = Index
    L(0)              = L(0,0)   = 0*1 + 0*2      = 0
    L(1)              = L(1,0)   = 1*1 + 0*2      = 1
    L(2)              = L(0,1)   = 0*1 + 1*2      = 2
    L(3)              = L(1,1)   = 1*1 + 1*2      = 3
    L(4)              = L(0,2)   = 0*1 + 2*2      = 4
    L(5)              = L(1,2)   = 1*1 + 2*2      = 5
    ```

    ``L`` walks ``{0..5}`` in order, so the left inverse is also the
    identity: ``Linv = 6:1``.

    ``Linv`` as a function from index back to integral_coord:

    ```text
    Linv(index) = Linv(coord) = Calculate integral_coord = Integral_coord
    Linv(0)     = Linv(0)     = 0*1                     = 0
    Linv(1)     = Linv(1)     = 1*1                     = 1
    Linv(2)     = Linv(2)     = 2*1                     = 2
    Linv(3)     = Linv(3)     = 3*1                     = 3
    Linv(4)     = Linv(4)     = 4*1                     = 4
    Linv(5)     = Linv(5)     = 5*1                     = 5
    ```

    Composing back: ``Linv(L(i)) = Linv(i) = i`` for every integral_coord ``i``.

    Worked example — row-major ``L = (2,3):(3,1)``

    Same shape, swapped strides, gives a permuted walk over the codomain:

    ```text
    L(integral_coord) = L(coord) = Calculate index = Index
    L(0)              = L(0,0)   = 0*3 + 0*1      = 0
    L(1)              = L(1,0)   = 1*3 + 0*1      = 3
    L(2)              = L(0,1)   = 0*3 + 1*1      = 1
    L(3)              = L(1,1)   = 1*3 + 1*1      = 4
    L(4)              = L(0,2)   = 0*3 + 2*1      = 2
    L(5)              = L(1,2)   = 1*3 + 2*1      = 5
    ```

    ``L`` is injective (no index repeats) and produces the permutation
    ``0, 3, 1, 4, 2, 5``. The left inverse must satisfy
    ``Linv(L(i)) = i``, which requires ``Linv`` to map
    ``0→0, 3→1, 1→2, 4→3, 2→4, 5→5`` — the inverse permutation. That
    is exactly the rank-2 layout ``Linv = (3,2):(2,1)``. The result
    keeps two modes because the inverse permutation is itself a
    non-trivial 2-D walk.

    ``Linv`` as a function from index back to integral_coord:

    ```text
    Linv(index) = Linv(coord) = Calculate integral_coord = Integral_coord
    Linv(0)     = Linv(0,0)   = 0*2 + 0*1                = 0
    Linv(1)     = Linv(1,0)   = 1*2 + 0*1                = 2
    Linv(2)     = Linv(2,0)   = 2*2 + 0*1                = 4
    Linv(3)     = Linv(0,1)   = 0*2 + 1*1                = 1
    Linv(4)     = Linv(1,1)   = 1*2 + 1*1                = 3
    Linv(5)     = Linv(2,1)   = 2*2 + 1*1                = 5
    ```

    Composing back, ``Linv(L(i))`` recovers the original integral_coord
    for each ``i``:

    ```text
    Linv(L(0)) = Linv(0) = 0
    Linv(L(1)) = Linv(3) = 1
    Linv(L(2)) = Linv(1) = 2
    Linv(L(3)) = Linv(4) = 3
    Linv(L(4)) = Linv(2) = 4
    Linv(L(5)) = Linv(5) = 5
    ```

    The same pattern generalizes to higher ranks: the rank-3 row-major
    example ``(4,3):(3,1) → (3,4):(4,1)`` below has the modes transposed
    for the same reason.

    **Examples**

    ```mlir
    // Injective row-major 4×3 → left inverse (modes transposed)
    %r = cute.left_inverse(%src)
           : (!cute.layout<"(4,3):(3,1)">) -> !cute.layout<"(3,4):(4,1)">

    // Injective column-major 4×3 → flat left inverse (compact over codomain)
    %r = cute.left_inverse(%src)
           : (!cute.layout<"(4,3):(1,4)">) -> !cute.layout<"12:1">

    // Scaled-basis strides → flattened to plain scalar strides
    %r = cute.left_inverse(%src)
           : (!cute.layout<"(4,3):(1@0,1@1)">) -> !cute.layout<"(4,3):(1,4)">
    ```

    **Errors**

    - dynamic shape (left inverse not computable at compile time)

      ```mlir
      %r = cute.left_inverse(%src) : (!cute.layout<"(?,3):(3,1)">) -> ...
      ```

    - dynamic stride

      ```mlir
      %r = cute.left_inverse(%src) : (!cute.layout<"(4,3):(?,1)">) -> ...
      ```

    - mix of plain-integer and scaled-basis strides

      ```mlir
      %r = cute.left_inverse(%src) : (!cute.layout<"(4,3):(1@0,1)">) -> ...
      ```

    - declared result layout does not match the inferred left inverse

      ```mlir
      %r = cute.left_inverse(%src)
             : (!cute.layout<"(4,3):(3,1)">) -> !cute.layout<"12:1">
      ```
  }];

  let arguments = (ins
    Cute_Arg<Cute_LayoutType, "static injective input layout">:$input
  );
  let results = (outs
    Cute_Arg<Cute_LayoutType, "left inverse layout">:$result
  );
  let assemblyFormat = [{
    `(` $input `)` attr-dict `:` functional-type(operands, results)
  }];
}

//===----------------------------------------------------------------------===//
// SizeOp
//===----------------------------------------------------------------------===//

def Cute_SizeOp : Cute_Op<"size", [
    Pure, DeclareOpInterfaceMethods<InferTypeOpInterface>]> {
  let cuteSpecGroup = "SizeIndex";
  let summary = "Compute multiplicative size of a tuple/layout-like value";
  let description = [{
    Computes the multiplicative size of ``$input``, optionally at a
    nested ``$mode``. The size is the product of all extents at the
    selected mode (or of the whole input when ``$mode`` is absent).

    For layouts and composed layouts, "size" refers to the domain
    extents (shape), not the codomain (cosize).

    **Preconditions**

    - ``$input`` is one of ``!cute.shape``, ``!cute.int_tuple``,
      ``!cute.layout``, or ``!cute.composed_layout``.

    - When ``$mode`` is present, each index in ``$mode`` is in
      ``[0, rank)`` at its level; ``$mode`` is traversed depth-first: ``mode[0]``
      selects a top-level element, ``mode[1]`` selects within that element's subtuple, etc.
      Each element of ``$mode`` is checked against the rank of the currently selected
      sub-object.

    - ``$mode`` indices stop at a scalar leaf. Once the descent
      resolves to a scalar, no further indices are accepted:
      ``cute.size<[0, 0]>`` on ``!cute.shape<"(4,2)">`` is a use
      error, not a no-op.

    **Postconditions**

    - Result is a scalar ``!cute.int_tuple`` (rank 0, i.e. a single integer value).
    - With no ``$mode``: result equals the product of all extents in
      ``$input``. For composed layouts, this is the size of the base
      layout's shape (Size of B, if the composed layout is ``A o O o B``).

    - With ``$mode``: result equals the size of the sub-object selected by
      ``cute.get<$mode>($input)``, i.e. the product of all extents within
      the selected sub-mode.

    **Examples**

    ```mlir
    %sz = cute.size<[1]> (%shape) : (!cute.shape<"(1,(2,4),9)">) -> !cute.int_tuple<"8">
    %sz = cute.size (%layout) : (!cute.layout<"(4,(16,32)):(1,(4,64))">) -> !cute.int_tuple<"2048">
    ```

    **Errors**

    - top-level mode index out of range

      ```mlir
      %sz = cute.size<[3]> (%src) : (!cute.shape<"(4,3)">) -> !cute.int_tuple<"4">
      ```

    - nested mode index out of range

      ```mlir
      %sz = cute.size<[1, 5]> (%src) : (!cute.shape<"(4,(3,2))">) -> !cute.int_tuple<"3">
      ```

    - descent past a scalar leaf — after `[0]` the value is

      ```mlir
      // the scalar `4`, so the trailing `0` has no scalar to descend into
      %sz = cute.size<[0, 0]> (%src) : (!cute.shape<"(4,2)">) -> !cute.int_tuple<"4">
      ```
  }];
  let arguments = (ins
    Cute_Arg<AnyTypeOf<[Cute_ShapeType, Cute_IntTupleType,
                        Cute_LayoutType, Cute_ComposedLayoutType]>,
             "input tuple/layout-like value">:$input,
    Cute_Arg<OptionalAttr<DenseI32ArrayAttr>, "hierarchical mode path">:$mode
  );
  let results = (outs
    Cute_Arg<Cute_IntTupleType, "computed size as int_tuple">:$result
  );
  let assemblyFormat = [{
    (`<` $mode^ `>`)? `(` $input `)` attr-dict `:`
    functional-type($input, $result)
  }];
}

//===----------------------------------------------------------------------===//
// CosizeOp
//===----------------------------------------------------------------------===//

def Cute_CosizeOp : Cute_Op<"cosize", [
    Pure, DeclareOpInterfaceMethods<InferTypeOpInterface>]> {
  let cuteSpecGroup = "SizeIndex";
  let summary = "Compute codomain size of a layout-like value";
  let description = [{
    Computes the codomain size of ``$input``, optionally at a nested
    ``$mode``. For layouts with integer strides, the cosize of a layout
    ``l`` is the number of distinct indices ``l`` can produce
    (``cosize(l) = l(size(l) - 1) + 1``). For layouts with scaled-basis strides,
    the cosize is computed as the product of the hierarchical codomain coordinate,
    ``size(coshape(l))``, where coshape is the smallest bounding coordinate of the
    codomain.

    **Preconditions**

    - ``$input`` is ``!cute.layout`` or ``!cute.composed_layout``.
    - When ``$mode`` is present, each index in ``$mode`` is in
      ``[0, rank)`` at its level; ``$mode`` is traversed depth-first: ``mode[0]``
      selects a top-level element, ``mode[1]`` selects within that element's subtuple, etc.
      Each element of ``$mode`` is checked against the rank of the currently selected
      sub-object.

    - When ``$input`` is ``!cute.composed_layout``, its inner layout
      must be a swizzle (not affine). ``cosize`` is undefined otherwise.

    - ``$mode`` indices stop at a scalar leaf. Once the descent
      resolves to a rank-1 layout with a scalar shape, no further
      indices are accepted: ``cute.cosize<[1, 0]>`` on
      ``!cute.layout<"(4,3,2):(1,4,12)">`` is a use error — after
      ``[1]`` we land on sub-layout ``3:4`` (scalar), so the trailing
      ``0`` has no scalar to descend into. Use ``<[1]>`` instead.

    **Postconditions**

    - Result is ``!cute.int_tuple`` (a scalar).
    - With no ``$mode``: result equals ``cosize($input)``.
    - With ``$mode``: result equals the cosize of the sub-object selected by
      ``cute.get<$mode>($input)``, i.e. the product of all extents within
      the selected sub-mode.
    - When ``$input`` is ``!cute.composed_layout`` (a o b), the result equals ``cosize(b)``.

    **Examples**

    ```mlir
    %csz = cute.cosize (%layout) : (!cute.layout<"(4,3,2):(1,4,12)">) -> !cute.int_tuple<"24">
    %csz = cute.cosize<[1]> (%layout) : (!cute.layout<"(4,3,2):(1,4,12)">) -> !cute.int_tuple<"9">
    ```

    **Errors**

    - top-level mode index out of range

      ```mlir
      %csz = cute.cosize<[3]> (%src)
               : (!cute.layout<"(4,3,2):(1,4,12)">) -> !cute.int_tuple<"4">
      ```

    - descent past a scalar leaf — use `<[1]>` instead

      ```mlir
      %csz = cute.cosize<[1, 0]> (%src)
               : (!cute.layout<"(4,3,2):(1,4,12)">) -> !cute.int_tuple<"9">
      ```
  }];
  let arguments = (ins
    Cute_Arg<AnyTypeOf<[Cute_LayoutType, Cute_ComposedLayoutType]>,
             "input layout-like value">:$input,
    Cute_Arg<OptionalAttr<DenseI32ArrayAttr>, "hierarchical mode path">:$mode
  );
  let results = (outs
    Cute_Arg<Cute_IntTupleType, "computed cosize as int_tuple">:$result
  );
  let assemblyFormat = [{
    (`<` $mode^ `>`)? `(` $input `)` attr-dict `:`
    functional-type($input, $result)
  }];
}

//===----------------------------------------------------------------------===//
// TupleProductOp
//===----------------------------------------------------------------------===//

def Cute_TupleProductOp : Cute_Op<"tuple_product", [
    Pure, DeclareOpInterfaceMethods<InferTypeOpInterface>]> {
  let cuteSpecGroup = "SizeIndex";
  let summary = "Compute the product of all leaf elements in an int_tuple or shape";
  let description = [{
    Folds all leaf elements of ``$input`` by multiplication. For
    example, ``tuple_product((2,(3,4))) = 24``.

    **Preconditions**

    - ``$input`` is ``!cute.int_tuple`` or ``!cute.shape``.

    **Postconditions**

    - Result kind matches input kind (``shape -> shape``,
      ``int_tuple -> int_tuple``); result is a scalar (rank-1) equal
      to the product of all leaves of ``$input``.

    - When ``$input`` has any dynamic leaves, the result is dynamic.

    **Examples**

    ```mlir
    // Static int_tuple: full numerical product
    %p = cute.tuple_product(%t) : (!cute.int_tuple<"(2,(3,4))">) -> !cute.int_tuple<"24">

    // Dynamic shape with one static leaf: result is dynamic.
    // Result kind matches input kind (shape -> shape).
    %p = cute.tuple_product(%t) : (!cute.shape<"(?,(3,?))">) -> !cute.shape<"?">
    ```

    **Errors**

    - operand is not an int_tuple or shape

      ```mlir
      %p = cute.tuple_product(%c) : (!cute.coord<"(2,3)">) -> !cute.int_tuple<"6">
      ```

    - declared result kind does not match input kind

      ```mlir
      %p = cute.tuple_product(%t)
             : (!cute.shape<"(2,(3,4))">) -> !cute.int_tuple<"24">
      ```

    - declared result does not match the inferred product

      ```mlir
      %p = cute.tuple_product(%t)
             : (!cute.int_tuple<"(2,(3,4))">) -> !cute.int_tuple<"5">
      ```
  }];
  let arguments = (ins
    Cute_Arg<AnyTypeOf<[Cute_IntTupleType, Cute_ShapeType]>,
             "input int_tuple or shape">:$input
  );
  let results = (outs
    Cute_Arg<AnyTypeOf<[Cute_IntTupleType, Cute_ShapeType]>,
             "product of all leaf elements (same kind as input)">:$result
  );
  let assemblyFormat = [{
    `(` $input `)` attr-dict `:` functional-type($input, $result)
  }];
}

//===----------------------------------------------------------------------===//
// TupleProductEachOp
//===----------------------------------------------------------------------===//

def Cute_TupleProductEachOp : Cute_Op<"tuple_product_each", [
    Pure, DeclareOpInterfaceMethods<InferTypeOpInterface>]> {
  let cuteSpecGroup = "SizeIndex";
  let summary = "Compute per-top-level-element product of an int_tuple or shape";
  let description = [{
    Applies ``product()`` to each top-level element of ``$input``, returning a
    depth-1 value of the same kind as ``$input``. A scalar input is first
    wrapped into a 1-element tuple. For example,
    ``tuple_product_each((2,(3,4))) = (2,12)`` and
    ``tuple_product_each((4,3,2)) = (4,3,2)``.

    **Preconditions**

    - ``$input`` is an ``!cute.int_tuple`` or ``!cute.shape``.

    **Postconditions**

    - ``$result`` kind matches ``$input`` kind (``shape -> shape``,
      ``int_tuple -> int_tuple``); it is a depth-1 value whose rank equals
      the rank of ``$input`` (or ``1`` if ``$input`` is a scalar).

    - Each output element is the product of the corresponding top-level
      sub-tuple of ``$input``. A dynamic factor anywhere in a sub-tuple makes
      that output element dynamic.

    **Examples**

    ```mlir
    // Static int_tuple: per-mode product, depth flattened to 1.
    %p = cute.tuple_product_each(%t)
           : (!cute.int_tuple<"(2,(3,4))">) -> !cute.int_tuple<"(2,12)">

    // Dynamic shape: each output mode is dynamic. Result kind matches
    // input kind (shape -> shape).
    %p = cute.tuple_product_each(%t)
           : (!cute.shape<"(?,(3,?))">) -> !cute.shape<"(?,?)">
    ```

    **Errors**

    - ``$result`` kind does not match ``$input`` kind.
    - ``$result`` rank does not match ``$input`` rank (or is not ``1`` for scalar
      input).

    - ``$result`` element does not equal the product of the corresponding
      top-level sub-tuple of ``$input``.
  }];
  let arguments = (ins
    Cute_Arg<AnyTypeOf<[Cute_IntTupleType, Cute_ShapeType]>,
             "input int_tuple or shape">:$input
  );
  let results = (outs
    Cute_Arg<AnyTypeOf<[Cute_IntTupleType, Cute_ShapeType]>,
             "per-element product (same kind as input)">:$result
  );
  let assemblyFormat = [{
    `(` $input `)` attr-dict `:` functional-type($input, $result)
  }];
}

/// Scalar index: i32, i64, or a scalar (single-integer) int_tuple.
def Cute_ScalarIndex
    : AnyTypeOf<[I32, I64, Cute_IntTupleType],
                "i32, i64, or scalar !cute.int_tuple">;

//===----------------------------------------------------------------------===//
// LayoutEvalOp
//===----------------------------------------------------------------------===//

def Cute_LayoutEvalOp : Cute_Op<"layout_eval", [
    Pure, DeclareOpInterfaceMethods<InferTypeOpInterface>]> {
  let cuteSpecGroup = "SizeIndex";
  let summary = "Convert a coordinate to an index with respect to a layout";
  let description = [{
    Computes the dot product of ``$coord`` with the strides of ``$layout``,
    giving the index into the layout's codomain. For a layout with shape
    ``s`` and stride ``d``, this evaluates to ``sum_i coord[i] * d[i]``.

    Result shape depends on the layout's stride form:

    - *Plain integer strides* — ``$result`` is a scalar ``!cute.int_tuple``
      containing ``sum_i coord[i] * stride[i]``.

    - *Scaled-basis strides* (``v@k`` or hierarchical ``v@k@...``) — each
      basis index ``@k`` projects its contribution into a separate axis
      of the codomain. ``$result`` is an ``!cute.int_tuple`` whose
      structure is induced by the basis dimensions of the stride,
      not by the shape's nesting. For flat basis (``(1@0,1@1)``) the
      result is rank-``numBasisDims``; for hierarchical basis
      (``(1@0@0,1@1@0)``) the result groups contributions by *outer*
      basis dim with inner basis dims as sub-tuples.

    **Preconditions**

    - ``$coord`` is either a leaf (scalar) ``!cute.coord`` *or* a non-leaf
      coord whose top-level rank matches ``$layout``'s shape rank
      (for composed layouts, the rank source is the inner B layout
      since the coord flows into B first: ``A(offset + B(coord))``).

    - ``$layout`` is an ``!cute.layout`` or ``!cute.composed_layout``.

    **Postconditions**

    - ``$result`` is an ``!cute.int_tuple`` whose value equals the basis-
      aware dot product ``sum_i coord[i] * stride[i]``. Plain-stride
      layouts produce a scalar; basis-strided layouts produce a tuple
      grouped by basis dim as described above.

    - ``$result`` is static iff every ``coord[i]`` is static and every
      contributing ``stride[i]`` is static; otherwise it is dynamic.

    **Examples**

    ```mlir
    // Static coord and layout: index resolved at compile time.
    %idx = cute.layout_eval(%crd, %layout)
             : (!cute.coord<"(1,2)">, !cute.layout<"(4,8):(1,4)">)
            -> !cute.int_tuple<"9">

    // Dynamic coord, static layout: result is dynamic.
    %idx = cute.layout_eval(%crd, %layout)
             : (!cute.coord<"(?,?)">, !cute.layout<"(4,8):(1,4)">)
            -> !cute.int_tuple<"?">

    // Static coord, dynamic stride: result is dynamic (depends on the stride).
    %idx = cute.layout_eval(%crd, %layout)
             : (!cute.coord<"(1,2)">, !cute.layout<"(4,8):(1,?)">)
            -> !cute.int_tuple<"?">

    // Flat scaled-basis stride: per-basis-dim tuple result. Each
    // natural-coord component lands in its matching basis dimension.
    %idx = cute.layout_eval(%crd, %layout)
             : (!cute.coord<"(1,2)">, !cute.layout<"(4,8):(1@0,1@1)">)
            -> !cute.int_tuple<"(1,2)">

    // Reversed flat basis: stride order is `(1@1,1@0)` so the first
    // coord component contributes to basis dim 1, the second to
    // basis dim 0. Result is per-basis-dim — i.e. `(2,1)` — not
    // per-coord-mode.
    %idx = cute.layout_eval(%crd, %layout)
             : (!cute.coord<"(1,2)">, !cute.layout<"(4,8):(1@1,1@0)">)
            -> !cute.int_tuple<"(2,1)">

    // Nested shape with flat-basis strides over three basis dims.
    // The natural coord `(1,2)` decomposes: rank-0 coord `1` walks
    // the nested mode-0 `(2,3)` as flat index 1 → `(1,0)`; rank-1
    // coord `2` is the mode-1 scalar. Per-basis result: `(1,0,2)`.
    %idx = cute.layout_eval(%crd, %layout)
             : (!cute.coord<"(1,2)">,
                !cute.layout<"((2,3),4):((1@0,1@1),1@2)">)
            -> !cute.int_tuple<"(1,0,2)">

    // Hierarchical scaled-basis stride: result groups by *outer*
    // basis dim, not by outer shape mode.
    %idx = cute.layout_eval(%crd, %layout)
             : (!cute.coord<"0">,
                !cute.layout<"((2,3),4):((1@1@0,1@0@0),1@1)">)
            -> !cute.int_tuple<"((0,0),0)">
    ```

    **Errors**

    - ``$coord``'s profile is not congruent with ``$layout``'s shape.
    - ``$result``'s value or structure disagrees with the basis-aware
      dot product when both sides are static.
  }];
  let arguments = (ins
    Cute_Arg<Cute_CoordType, "coordinate">:$coord,
    Cute_Arg<Cute_AnyLayoutType, "layout or composed layout">:$layout
  );
  let results = (outs
    Cute_Arg<Cute_IntTupleType, "index">:$result
  );
  let assemblyFormat = [{
    `(` $coord `,` $layout `)` attr-dict `:` functional-type(operands, results)
  }];
}

//===----------------------------------------------------------------------===//
// Crd2IdxOp
//===----------------------------------------------------------------------===//

def Cute_Crd2IdxOp : Cute_Op<"crd2idx", [
    Pure, DeclareOpInterfaceMethods<InferTypeOpInterface>]> {
  let cuteSpecGroup = "SizeIndex";
  let summary = "Pack a coordinate into a linear index given a shape";
  let description = [{
    Packs `$coord` into a single linear index using **implicit
    column-major strides** derived from `$shape`. For a shape
    `(s_0, s_1, ..., s_{n-1})` and a coord
    `(c_0, c_1, ..., c_{n-1})` the result is

    `c_0 + c_1 * s_0 + c_2 * s_0 * s_1 + ... + c_{n-1} * s_0 * ... * s_{n-2}`.

    Nested coords / shapes recurse mode-by-mode. The result is
    always a scalar `!cute.int_tuple`.

    This is the structural pack — no layout / stride / order
    operand. Use `cute.layout_eval` instead when the strides come
    from a specific layout.

    **Preconditions:**

    - `$coord` is `!cute.coord` and congruent with `$shape`.
    - `$shape` is `!cute.shape`.

    **Postconditions:**

    - `$result` is a scalar `!cute.int_tuple`.
    - `$result` is static iff every leaf of `$coord` and every contributing extent of `$shape` is static.

    **Examples:**

    ```mlir
    // Static coord (1,2) on shape (4,8) → 1*1 + 2*4 = 9.
    %idx = cute.crd2idx(%crd, %shape)
             : (!cute.coord<"(1,2)">, !cute.shape<"(4,8)">)
            -> !cute.int_tuple<"9">

    // Dynamic coord, static shape → result is dynamic.
    %idx = cute.crd2idx(%crd, %shape)
             : (!cute.coord<"(?,?)">, !cute.shape<"(4,8)">)
            -> !cute.int_tuple<"?">

    // Static coord, dynamic shape → result is dynamic (an unknown
    // extent affects the column-major weighting of later modes).
    %idx = cute.crd2idx(%crd, %shape)
             : (!cute.coord<"(1,2)">, !cute.shape<"(?,8)">)
            -> !cute.int_tuple<"?">
    ```

    **Errors:**

    - Coord rank does not match shape rank:

      ```mlir
      // error: 'cute.crd2idx' op expects coord and shape to be congruent
      %idx = cute.crd2idx(%crd, %shape)
               : (!cute.coord<"(1,2,3)">, !cute.shape<"(4,8)">)
              -> !cute.int_tuple<"?">
      ```

    - Declared result type does not match the inferred index:

      ```mlir
      // error: 'cute.crd2idx' op inferred type(s) '!cute.int_tuple<"9">'
      //   are incompatible with return type(s) of operation
      //   '!cute.int_tuple<"7">'
      %idx = cute.crd2idx(%crd, %shape)
               : (!cute.coord<"(1,2)">, !cute.shape<"(4,8)">)
              -> !cute.int_tuple<"7">
      ```
  }];
  let arguments = (ins
    Cute_Arg<Cute_CoordType, "coordinate">:$coord,
    Cute_Arg<Cute_ShapeType, "shape">:$shape
  );
  let results = (outs
    Cute_Arg<Cute_IntTupleType, "linear index">:$result
  );
  let assemblyFormat = [{
    `(` $coord `,` $shape `)` attr-dict `:` functional-type(operands, results)
  }];
}

//===----------------------------------------------------------------------===//
// Idx2CrdOp
//===----------------------------------------------------------------------===//

def Cute_Idx2CrdOp : Cute_Op<"idx2crd", [
    Pure, DeclareOpInterfaceMethods<InferTypeOpInterface>]> {
  let cuteSpecGroup = "SizeIndex";
  let summary = "Convert an index to a coordinate with respect to a shape";
  let description = [{
    Computes the coordinate corresponding to ``$index`` in colexicographic
    (column-major) order with respect to ``$shape``. For a 1D shape ``s``, the
    result is ``idx mod s``; for higher-rank shapes, the index is unraveled
    digit-by-digit using the running products of ``$shape``'s extents.

    **Preconditions**

    - ``$index`` is either a scalar ``!cute.int_tuple`` (rank ≤ 1)
      *or* a multi-element int_tuple whose rank matches ``$shape``'s
      rank (the latter form pre-decomposes the linear index per
      mode).

    - ``$shape`` is an ``!cute.shape``.

    **Postconditions**

    - ``$result`` is an ``!cute.coord`` whose profile matches ``$shape``.
    - ``$result`` is fully static iff ``$index`` is static and every extent of
      ``$shape`` is static; otherwise every element of the result is dynamic.

    **Examples**

    ```mlir
    // Static index and shape: coord resolved at compile time.
    %crd = cute.idx2crd(%idx, %shape)
             : (!cute.int_tuple<"9">, !cute.shape<"(4,8)">)
            -> !cute.coord<"(1,2)">

    // Dynamic index, static shape: result coord is all-dynamic.
    %crd = cute.idx2crd(%idx, %shape)
             : (!cute.int_tuple<"?">, !cute.shape<"(4,8)">)
            -> !cute.coord<"(?,?)">

    // Static index, dynamic extent: result coord is all-dynamic (an unknown
    // extent affects the column-major walk for both modes).
    %crd = cute.idx2crd(%idx, %shape)
             : (!cute.int_tuple<"9">, !cute.shape<"(?,8)">)
            -> !cute.coord<"(?,?)">
    ```

    **Errors**

    - ``$index``'s rank is greater than 1 and does not match ``$shape``'s rank.
    - ``$result``'s profile is not congruent with ``$shape``.
    - ``$result`` value disagrees with the column-major unravel of ``$index``
      against ``$shape`` when both sides are static.
  }];
  let arguments = (ins
    Cute_Arg<Cute_IntTupleType, "index (scalar int_tuple)">:$index,
    Cute_Arg<Cute_ShapeType, "shape">:$shape
  );
  let results = (outs
    Cute_Arg<Cute_CoordType, "coordinate">:$result
  );
  let assemblyFormat = [{
    `(` $index `,` $shape `)` attr-dict `:` functional-type(operands, results)
  }];
}

//===----------------------------------------------------------------------===//
// IncrementCoordOp
//===----------------------------------------------------------------------===//

def Cute_IncrementCoordOp : Cute_Op<"increment_coord", [
    Pure, DeclareOpInterfaceMethods<InferTypeOpInterface>]> {
  let cuteSpecGroup = "SizeIndex";
  let summary = "Increment a coordinate by one within its bounding shape";
  let description = [{
    Increments ``$coord`` by 1 in column-major (row-first) order within the
    coordinate space bounded by ``$shape``. The coordinate is treated as a
    multi-dimensional digit, so when the lowest mode reaches its extent it
    wraps to 0 and carries into the next mode.

    **Preconditions**

    - ``$coord`` and ``$shape`` are congruent (same hierarchical rank/depth
      structure).

    - ``$coord`` contains no wildcard (``_``) elements.

    **Postconditions**

    - ``$result`` is an ``!cute.coord`` with the same profile as ``$coord``.
    - When all inputs are static, ``$result`` equals the column-major
      successor of ``$coord`` modulo ``$shape`` (wrap-around at the highest
      mode is not specified — callers are expected to keep the iteration
      within ``size($shape)``).

    - Any dynamic element in ``$coord`` or ``$shape`` makes the entire
      ``$result`` dynamic.

    **Examples**

    ```mlir
    // Static: (1,2) + 1 in space (4,8) -> (2,2).
    %r = cute.increment_coord(%c, %s)
           : (!cute.coord<"(1,2)">, !cute.shape<"(4,8)">)
          -> !cute.coord<"(2,2)">

    // Static wrap: (3,2) + 1 in space (4,8) -> (0,3).
    %r = cute.increment_coord(%c, %s)
           : (!cute.coord<"(3,2)">, !cute.shape<"(4,8)">)
          -> !cute.coord<"(0,3)">

    // Dynamic coord: result has the same profile with dynamic values.
    %r = cute.increment_coord(%c, %s)
           : (!cute.coord<"(?,?)">, !cute.shape<"(4,8)">)
          -> !cute.coord<"(?,?)">
    ```

    **Errors**

    - ``$coord`` and ``$shape`` are not congruent.
    - ``$coord`` contains a wildcard (``_``) element.
    - ``$result``'s profile differs from ``$coord``'s profile.
    - ``$result`` value disagrees with the column-major successor of ``$coord``
      modulo ``$shape`` when both sides are static.
  }];
  let arguments = (ins
    Cute_Arg<Cute_CoordType, "coordinate to increment">:$coord,
    Cute_Arg<Cute_ShapeType, "bounding shape">:$shape
  );
  let results = (outs
    Cute_Arg<Cute_CoordType, "incremented coordinate">:$result
  );
  let assemblyFormat = [{
    `(` $coord `,` $shape `)` attr-dict `:` functional-type(operands, results)
  }];
}

//===----------------------------------------------------------------------===//
// AppendToRankOp / PrependToRankOp — shared type alias
//===----------------------------------------------------------------------===//

/// Any cute tuple-like or layout type accepted by append/prepend_to_rank.
def Cute_TupleOrLayoutType
    : AnyTypeOf<[Cute_IntTupleType, Cute_CoordType, Cute_StrideType,
                 Cute_ShapeType, Cute_LayoutType, Cute_ComposedLayoutType],
                "!cute.int_tuple, !cute.coord, !cute.stride, !cute.shape, "
                "!cute.layout, or !cute.composed_layout">;

//===----------------------------------------------------------------------===//
// AppendToRankOp
//===----------------------------------------------------------------------===//

def Cute_AppendToRankOp : Cute_Op<"append_to_rank", [
    Pure, DeclareOpInterfaceMethods<InferTypeOpInterface>]> {
  let cuteSpecGroup = "SizeIndex";
  let summary = "Append element to input until rank reaches N";
  let description = [{
    Repeatedly appends ``$element`` to the right of ``$input`` until the
    result has rank ``$rank``. If ``$input`` already has rank >= ``$rank``, it
    is returned unchanged. Useful for broadening an int_tuple, coord,
    stride, shape, or layout to a target rank using an identity-like
    filler (e.g. ``1`` for a shape, ``1:0`` for a layout).

    **Preconditions**

    - ``$rank`` is a positive integer attribute (``> 0``).
    - ``$input`` and ``$element`` types are compatible:

      - For ``!cute.int_tuple``, ``!cute.coord``, ``!cute.stride``, ``!cute.shape``:
        ``$element`` must be the same kind as ``$input``.

      - For ``!cute.layout``: ``$element`` must be ``!cute.layout``.
      - For ``!cute.composed_layout``: ``$element`` must be ``!cute.layout``.

    **Postconditions**

    - ``$result`` has the same kind as ``$input``.
    - ``rank($result) == max(rank($input), $rank)``.
    - The leading ``rank($input)`` modes of ``$result`` equal ``$input``; any
      trailing modes equal ``$element``.

    **Examples**

    ```mlir
    // Shape rank 2 -> rank 4, padding with shape<"1">.
    // Result: !cute.shape<"(4,8,1,1)">.
    %r = cute.append_to_rank<4> (%in, %e)
           : !cute.shape<"(4,8)">, !cute.shape<"1">

    // Layout rank 1 -> rank 3, padding with identity layout.
    // Result: !cute.layout<"(4,1,1):(1,0,0)">.
    %r = cute.append_to_rank<3> (%in, %e)
           : !cute.layout<"4:1">, !cute.layout<"1:0">

    // Dynamic shape rank 2 -> rank 4 — dynamic extents pass through unchanged.
    // Result: !cute.shape<"(?,8,1,1)">.
    %r = cute.append_to_rank<4> (%in, %e)
           : !cute.shape<"(?,8)">, !cute.shape<"1">

    // No-op: target rank (2) <= input rank (3) — input returned unchanged.
    // Result: !cute.shape<"(4,8,2)">.
    %r = cute.append_to_rank<2> (%in, %e)
           : !cute.shape<"(4,8,2)">, !cute.shape<"1">
    ```

    **Errors**

    - ``$rank`` is not positive.
    - ``$input`` and ``$element`` are not compatible kinds.
  }];
  let arguments = (ins
    Cute_Arg<I32Attr, "target rank N (must be > 0)">:$rank,
    Cute_Arg<Cute_TupleOrLayoutType, "input value to extend to rank N">:$input,
    Cute_Arg<Cute_TupleOrLayoutType, "element used to pad up to rank N">:$element
  );
  let results = (outs
    Cute_Arg<Cute_TupleOrLayoutType, "extended value with rank N">:$result
  );
  let assemblyFormat = [{
    `<` $rank `>` `(` $input `,` $element `)` attr-dict `:`
    qualified(type($input)) `,` qualified(type($element))
  }];
}

//===----------------------------------------------------------------------===//
// PrependToRankOp
//===----------------------------------------------------------------------===//

def Cute_PrependToRankOp : Cute_Op<"prepend_to_rank", [
    Pure, DeclareOpInterfaceMethods<InferTypeOpInterface>]> {
  let cuteSpecGroup = "SizeIndex";
  let summary = "Prepend element to input until rank reaches N";
  let description = [{
    Repeatedly prepends ``$element`` to the left of ``$input`` until the
    result has rank ``$rank``. If ``$input`` already has rank >= ``$rank``, it
    is returned unchanged. Useful for broadening an int_tuple, coord,
    stride, shape, or layout to a target rank using an identity-like
    filler (e.g. ``1`` for a shape, ``1:0`` for a layout).

    **Preconditions**

    - ``$rank`` is a positive integer attribute (``> 0``).
    - ``$input`` and ``$element`` types are compatible:

      - For ``!cute.int_tuple``, ``!cute.coord``, ``!cute.stride``, ``!cute.shape``:
        ``$element`` must be the same kind as ``$input``.

      - For ``!cute.layout``: ``$element`` must be ``!cute.layout``.
      - For ``!cute.composed_layout``: ``$element`` must be ``!cute.layout``.

    **Postconditions**

    - ``$result`` has the same kind as ``$input``.
    - ``rank($result) == max(rank($input), $rank)``.
    - The trailing ``rank($input)`` modes of ``$result`` equal ``$input``; any
      leading modes equal ``$element``.

    **Examples**

    ```mlir
    // Shape rank 2 -> rank 4, padding with shape<"1">.
    // Result: !cute.shape<"(1,1,4,8)">.
    %r = cute.prepend_to_rank<4> (%in, %e)
           : !cute.shape<"(4,8)">, !cute.shape<"1">

    // Layout rank 1 -> rank 3, padding with identity layout.
    // Result: !cute.layout<"(1,1,4):(0,0,1)">.
    %r = cute.prepend_to_rank<3> (%in, %e)
           : !cute.layout<"4:1">, !cute.layout<"1:0">

    // Dynamic shape rank 2 -> rank 4 — dynamic extents pass through unchanged.
    // Result: !cute.shape<"(1,1,?,8)">.
    %r = cute.prepend_to_rank<4> (%in, %e)
           : !cute.shape<"(?,8)">, !cute.shape<"1">

    // No-op: target rank (2) <= input rank (3) — input returned unchanged.
    // Result: !cute.shape<"(4,8,2)">.
    %r = cute.prepend_to_rank<2> (%in, %e)
           : !cute.shape<"(4,8,2)">, !cute.shape<"1">
    ```

    **Errors**

    - ``$rank`` is not positive.
    - ``$input`` and ``$element`` are not compatible kinds.
  }];
  let arguments = (ins
    Cute_Arg<I32Attr, "target rank N (must be > 0)">:$rank,
    Cute_Arg<Cute_TupleOrLayoutType, "input value to extend to rank N">:$input,
    Cute_Arg<Cute_TupleOrLayoutType, "element used to pad up to rank N">:$element
  );
  let results = (outs
    Cute_Arg<Cute_TupleOrLayoutType, "extended value with rank N">:$result
  );
  let assemblyFormat = [{
    `<` $rank `>` `(` $input `,` $element `)` attr-dict `:`
    qualified(type($input)) `,` qualified(type($element))
  }];
}

//===----------------------------------------------------------------------===//
// TupleAddOp
//===----------------------------------------------------------------------===//

def Cute_TupleAddOp : Cute_Op<"tuple_add", [
    Pure, DeclareOpInterfaceMethods<InferTypeOpInterface>]> {
  let cuteSpecGroup = "Arithmetic";
  let summary = "Element-wise addition of two arithmetic tuples";
  let description = [{
    Adds ``$lhs`` and ``$rhs`` element-wise, recursing into nested
    sub-tuples. The two operands must be the same kind
    (``!cute.int_tuple`` or ``!cute.shape``); the result has the same kind.

    When the two operands have different lengths, elements beyond the
    common rank are copied through unchanged from whichever side
    provides them — as if the shorter operand were zero-padded. The
    same rule applies recursively to nested sub-tuples:

    ```
    (1,2,3) + (4,5)   =  (5,7,3)        // lhs extra element passes through
    (1,2)   + (4,5,6) =  (5,7,6)        // rhs extra element passes through
    ((1,2),(3,4),(5,6)) + ((10,11),(20,21))
                       =  ((11,13),(23,25),(5,6))   // extra nested sub-tuple
    ((1,2),(3,4)) + ((10,11),(20,21,22))
                       =  ((11,13),(23,25,22))       // extra inner element
    ```

    **Preconditions**

    - ``$lhs`` and ``$rhs`` are both ``!cute.int_tuple`` or both ``!cute.shape``
      (matching kinds).

    - Scalar-tuple identity — A zero scalar paired with a tuple is
      the additive identity (``0 + t == t + 0 == t``). A non-zero scalar
      mixed with a non-scalar tuple is invalid.

    - Nesting constraint — Within the common rank, both operands
      must mirror each other structurally: at every position
      ``i < min(rank(lhs), rank(rhs))``, either both elements are leaves
      or both are sub-tuples. A leaf-vs-sub-tuple mismatch at any depth
      is invalid.

    **Postconditions**

    - ``$result`` has the same kind as ``$lhs`` / ``$rhs``.
    - ``rank($result) == max(rank($lhs), rank($rhs))``.
    - For positions in the common rank, ``$result[i]`` is the recursive
      element-wise sum of ``$lhs[i]`` and ``$rhs[i]``. Trailing positions
      pass through unchanged from the longer operand.

    **Examples**

    ```mlir
    // Static int_tuple.
    %r = cute.tuple_add(%a, %b)
           : (!cute.int_tuple<"(3,4)">, !cute.int_tuple<"(1,2)">)
          -> !cute.int_tuple<"(4,6)">

    // Static shape.
    %r = cute.tuple_add(%a, %b)
           : (!cute.shape<"(6,8)">, !cute.shape<"(2,4)">)
          -> !cute.shape<"(8,12)">

    // Rank mismatch — extra lhs element passes through unchanged.
    %r = cute.tuple_add(%a, %b)
           : (!cute.int_tuple<"(1,2,3)">, !cute.int_tuple<"(4,5)">)
          -> !cute.int_tuple<"(5,7,3)">

    // Dynamic lhs + static rhs.
    %r = cute.tuple_add(%a, %b)
           : (!cute.int_tuple<"(?,?)">, !cute.int_tuple<"(1,2)">)
          -> !cute.int_tuple<"(?,?)">
    ```

    **Errors**

    - ``$lhs`` and ``$rhs`` have different kinds (e.g. int_tuple vs shape).
    - A non-zero scalar is paired with a non-scalar tuple.
    - Within the common rank, a leaf is paired with a sub-tuple at any
      depth.

    - ``$result`` kind differs from ``$lhs``/``$rhs``, or its rank/values
      disagree with the element-wise sum when both sides are static.
  }];
  let arguments = (ins
    Cute_Arg<Cute_ArithTupleType, "left-hand side">:$lhs,
    Cute_Arg<Cute_ArithTupleType, "right-hand side">:$rhs
  );
  let results = (outs
    Cute_Arg<Cute_ArithTupleType, "element-wise sum">:$result
  );
  let assemblyFormat = [{
    `(` operands `)` attr-dict `:` functional-type(operands, results)
  }];
}

//===----------------------------------------------------------------------===//
// TupleSubOp
//===----------------------------------------------------------------------===//

def Cute_TupleSubOp : Cute_Op<"tuple_sub", [
    Pure, DeclareOpInterfaceMethods<InferTypeOpInterface>]> {
  let cuteSpecGroup = "Arithmetic";
  let summary = "Element-wise subtraction of two arithmetic tuples";
  let description = [{
    Subtracts ``$rhs`` from ``$lhs`` element-wise (``lhs - rhs``), recursing
    into nested sub-tuples. The two operands must be the same kind
    (``!cute.int_tuple`` or ``!cute.shape``); the result has the same kind.

    When the two operands have different lengths, elements beyond the
    common rank are copied through unchanged from whichever side
    provides them — as if the shorter operand were zero-padded. The
    same rule applies recursively to nested sub-tuples:

    ```
    (5,8,3) - (1,2)     =  (4,6,3)      // extra lhs element passes through
    (10,8)  - (3,2,5)   =  (7,6,5)      // extra rhs element passes through
    ((5,8),(3,4),(1,2)) - ((1,2),(1,1))
                         =  ((4,6),(2,3),(1,2))   // extra nested sub-tuple
    ((5,8),(3,4)) - ((1,2),(1,1,1))
                         =  ((4,6),(2,3,1))        // extra inner element
    ```

    **Preconditions**

    - ``$lhs`` and ``$rhs`` are both ``!cute.int_tuple`` or both ``!cute.shape``
      (matching kinds).

    - Scalar-tuple identity — A zero scalar ``$rhs`` paired with a
      non-scalar tuple ``$lhs`` is the additive identity (``t - 0 == t``).
      A zero scalar ``$lhs`` paired with a non-scalar tuple ``$rhs`` is
      invalid (subtraction is not commutative). Any non-zero scalar
      mixed with a non-scalar tuple at the top level is also invalid.

    - Nesting constraint — Within the common rank, both operands
      must mirror each other structurally: at every position
      ``i < min(rank(lhs), rank(rhs))``, either both elements are leaves
      or both are sub-tuples. A leaf-vs-sub-tuple mismatch at any depth
      is invalid.

    **Postconditions**

    - ``$result`` has the same kind as ``$lhs`` / ``$rhs``.
    - ``rank($result) == max(rank($lhs), rank($rhs))``.
    - For positions in the common rank, ``$result[i]`` is the recursive
      element-wise difference ``$lhs[i] - $rhs[i]``. Trailing positions
      pass through unchanged from the longer operand.

    **Examples**

    ```mlir
    // Static int_tuple.
    %r = cute.tuple_sub(%a, %b)
           : (!cute.int_tuple<"(5,8)">, !cute.int_tuple<"(1,2)">)
          -> !cute.int_tuple<"(4,6)">

    // Rank mismatch — extra lhs element passes through unchanged.
    %r = cute.tuple_sub(%a, %b)
           : (!cute.int_tuple<"(5,8,3)">, !cute.int_tuple<"(1,2)">)
          -> !cute.int_tuple<"(4,6,3)">

    // Rank mismatch — extra rhs element passes through unchanged.
    %r = cute.tuple_sub(%a, %b)
           : (!cute.int_tuple<"(10,8)">, !cute.int_tuple<"(3,2,5)">)
          -> !cute.int_tuple<"(7,6,5)">

    // Dynamic lhs + static rhs.
    %r = cute.tuple_sub(%a, %b)
           : (!cute.int_tuple<"(?,?)">, !cute.int_tuple<"(1,2)">)
          -> !cute.int_tuple<"(?,?)">
    ```

    **Errors**

    - ``$lhs`` and ``$rhs`` have different kinds (e.g. shape vs int_tuple).
    - A zero scalar ``$lhs`` is paired with a non-scalar ``$rhs``, or any
      non-zero scalar is paired with a non-scalar tuple at the top
      level.

    - Within the common rank, a leaf is paired with a sub-tuple at any
      depth.

    - ``$result`` kind differs from ``$lhs``/``$rhs``, or its rank/values
      disagree with the element-wise difference when both sides are
      static.
  }];
  let arguments = (ins
    Cute_Arg<Cute_ArithTupleType, "left-hand side">:$lhs,
    Cute_Arg<Cute_ArithTupleType, "right-hand side">:$rhs
  );
  let results = (outs
    Cute_Arg<Cute_ArithTupleType, "element-wise difference">:$result
  );
  let assemblyFormat = [{
    `(` operands `)` attr-dict `:` functional-type(operands, results)
  }];
}

//===----------------------------------------------------------------------===//
// ShapeDivOp
//===----------------------------------------------------------------------===//

def Cute_ShapeDivOp : Cute_Op<"shape_div", [
    NoMemoryEffect,
    DeclareOpInterfaceMethods<ConditionallySpeculatable, ["getSpeculatability"]>,
    DeclareOpInterfaceMethods<InferTypeOpInterface>]> {
  let cuteSpecGroup = "Arithmetic";
  let summary = "CuTe shape division";
  let description = [{
    Divides shape ``$a`` by shape ``$b`` using CuTe's shape-division
    rules. Both operands and the result are ``!cute.shape``. The
    operation has four cases based on the top-level structure of the
    operands:

    - (tuple, tuple) — element-wise ``shape_div`` on corresponding
      elements. The tuple ranks must match; Traverses each element then selects
      independently among these four cases.

    - (tuple, scalar) — sequential consumption: divides the first
      element of ``$a`` by ``$b``, reduces ``$b`` by that amount, and
      repeats across ``$a``. Example: ``shape_div((4,5,6), 40) -> (1,1,3)``.

    - (scalar, tuple) — reduces to ``shape_div($a, product($b))``.
    - (scalar, scalar) — requires ``a % b == 0`` or ``b % a == 0``;
      returns ``a / b`` rounded away from zero (result is 1 or -1 when
      ``|a| < |b|``).

    **Preconditions**

    - ``$a`` and ``$b`` are ``!cute.shape``.
    - At each recursive (tuple, tuple) case, the tuple ranks must match.
    - For (scalar, scalar) leaves the divisor must be non-zero and one
      side must divide the other (``a % b == 0`` or ``b % a == 0``).

    - For (tuple, scalar) the running divisor must be fully consumed
      or remain divisible at each step.

    **Postconditions**

    - ``$result`` is an ``!cute.shape`` whose profile follows the case
      rules above.

    - When all inputs are static, ``$result`` equals the CuTe
      shape-division value; dynamic inputs propagate as dynamic in
      the result.

    **Examples**

    ```mlir
    // Scalar / scalar.
    %r = cute.shape_div(%a, %b)
           : (!cute.shape<"12">, !cute.shape<"4">)
          -> !cute.shape<"3">

    // Tuple / tuple — element-wise.
    %r = cute.shape_div(%a, %b)
           : (!cute.shape<"(8,10)">, !cute.shape<"(2,5)">)
          -> !cute.shape<"(4,2)">

    // Tuple / scalar — sequential consumption.
    %r = cute.shape_div(%a, %b)
           : (!cute.shape<"(4,5,6)">, !cute.shape<"40">)
          -> !cute.shape<"(1,1,3)">
    ```

    **Errors**

    - Unequal ranks at any recursive (tuple, tuple) case.
    - Divisor leaf is zero.
    - (scalar, scalar) leaves where neither side divides the other.
    - ``$result`` shape disagrees with the case-rule value when both
      sides are static.

    ```mlir
    // error: expects valid operands, but cannot compute shape_div for
    //        '!cute.shape<"4">' and '!cute.shape<"0">': divisor is zero
    cute.shape_div(%a, %b) : (!cute.shape<"4">, !cute.shape<"0">) -> ...

    // error: expects valid operands, but cannot compute shape_div for
    //        '!cute.shape<"7">' and '!cute.shape<"3">': 7 is not divisible
    //        by 3 (neither 7 % 3 == 0 nor 3 % 7 == 0)
    cute.shape_div(%a, %b) : (!cute.shape<"7">, !cute.shape<"3">) -> ...
    ```
  }];
  let arguments = (ins
    Cute_Arg<Cute_ShapeType, "dividend shape">:$a,
    Cute_Arg<Cute_ShapeType, "divisor shape">:$b
  );
  let results = (outs
    Cute_Arg<Cute_ShapeType, "shape quotient">:$result
  );
  let assemblyFormat = [{
    `(` operands `)` attr-dict `:` functional-type(operands, results)
  }];
}

//===----------------------------------------------------------------------===//
// CeilDivOp
//===----------------------------------------------------------------------===//

def Cute_CeilDivOp : Cute_Op<"ceil_div", [
    NoMemoryEffect,
    DeclareOpInterfaceMethods<ConditionallySpeculatable, ["getSpeculatability"]>,
    DeclareOpInterfaceMethods<InferTypeOpInterface>]> {
  let cuteSpecGroup = "Arithmetic";
  let summary = "Computes the ceiling division of an arithmetic tuple by an arithmetic or tile tiler.";
  let description = [{
    Computes ``ceil($input / $tiler)`` element-wise. ``$input`` is
    ``!cute.int_tuple`` or ``!cute.shape``. ``$tiler`` is ``!cute.int_tuple``,
    ``!cute.shape``, or ``!cute.tile`` (independently chosen from
    ``$input``). The result has the same kind as ``$input``. An
    ``!cute.int_tuple`` or ``!cute.shape`` tiler preserves the input profile;
    an ``!cute.tile`` tiler may change it.

    For an ``!cute.int_tuple`` or ``!cute.shape`` tiler, the operation has
    four cases based on the top-level structure of the operands:

    - (tuple, tuple) — ``rank($input) >= rank($tiler)`` is required;
      elements of ``$input`` beyond ``rank($tiler)`` are passed through
      unchanged.

    - (tuple, scalar) — sequential consumption: divides the first
      element of ``$input`` by ``$tiler``, reduces ``$tiler`` by that
      amount, and repeats across ``$input``.

    - (scalar, tuple) — reduces to ``ceil_div($input, product($tiler))``.
    - (scalar, scalar) — standard ``ceil(input / tiler)``.

    An ``!cute.tile`` tiler instead uses shape/tile semantics. It preserves
    the input kind but may change the result profile.

    **Preconditions**

    - ``$input`` is ``!cute.int_tuple`` or ``!cute.shape``.
    - ``$tiler`` is ``!cute.int_tuple``, ``!cute.shape``, or ``!cute.tile``.
    - For an arithmetic (tuple, tuple) tiler:
      ``rank($input) >= rank($tiler)``.
    - At every (scalar, scalar) leaf the tiler is non-zero.

    **Postconditions**

    - ``$result`` has the same kind as ``$input``. It has the same profile
      when ``$tiler`` is ``!cute.int_tuple`` or ``!cute.shape``; a
      ``!cute.tile`` tiler may change the profile.
    - When all inputs are static, ``$result`` equals the
      ceiling-division value per the case rules above; dynamic inputs
      propagate as dynamic in the result.

    **Examples**

    ```mlir
    // Scalar / scalar.
    %r = cute.ceil_div(%a, %b)
           : (!cute.int_tuple<"7">, !cute.int_tuple<"3">)
          -> !cute.int_tuple<"3">

    // Tuple / tuple — element-wise.
    %r = cute.ceil_div(%a, %b)
           : (!cute.int_tuple<"(8,10)">, !cute.int_tuple<"(3,4)">)
          -> !cute.int_tuple<"(3,3)">

    // Tuple / tuple with extra input element passing through unchanged.
    %r = cute.ceil_div(%a, %b)
           : (!cute.int_tuple<"(8,10,6)">, !cute.int_tuple<"(3,4)">)
          -> !cute.int_tuple<"(3,3,6)">

    // A tile tiler may change the result profile.
    %r = cute.ceil_div(%a, %tile)
           : (!cute.int_tuple<"(8,16)">, !cute.tile<"((4,8)):((1,4))">)
          -> !cute.int_tuple<"4">
    ```

    **Errors**

    - Tiler leaf is zero.
    - Arithmetic (tuple, tuple) operands where
      ``rank($tiler) > rank($input)``.
    - ``$result`` disagrees with the case-rule value when both sides
      are static.

    ```mlir
    // error: expects valid operands, but cannot compute ceil_div for
    //        '!cute.int_tuple<"(4,8)">' and '!cute.int_tuple<"(2,4,2)">':
    //        rank(tiler)=3 > rank(input)=2
    cute.ceil_div(%a, %b) : (!cute.int_tuple<"(4,8)">, !cute.int_tuple<"(2,4,2)">) -> ...

    // error: expects valid operands, but cannot compute ceil_div for
    //        '!cute.int_tuple<"7">' and '!cute.int_tuple<"0">': tiler is zero
    cute.ceil_div(%a, %b) : (!cute.int_tuple<"7">, !cute.int_tuple<"0">) -> ...
    ```
  }];
  let arguments = (ins
    Cute_Arg<Cute_ArithTupleType, "input (dividend)">:$input,
    Cute_Arg<AnyTypeOf<[Cute_IntTupleType, Cute_ShapeType, Cute_TileType],
                       "!cute.int_tuple, !cute.shape, or !cute.tile">,
             "tiler (divisor)">:$tiler
  );
  let results = (outs
    Cute_Arg<Cute_ArithTupleType, "ceil-divided result">:$result
  );
  let assemblyFormat = [{
    `(` operands `)` attr-dict `:` functional-type(operands, results)
  }];
}

//===----------------------------------------------------------------------===//
// ElemLessOp
//===----------------------------------------------------------------------===//

/// Operand to elem_less: int_tuple, shape, or coord.
def Cute_ElemLessOperandType
    : AnyTypeOf<[Cute_IntTupleType, Cute_ShapeType, Cute_CoordType],
                "!cute.int_tuple, !cute.shape, or !cute.coord">;

def Cute_ElemLessOp : Cute_Op<"elem_less", [Pure]> {
  let cuteSpecGroup = "Arithmetic";
  let hasVerifier = 1;
  let summary = "Element-wise less-than comparison of two CuTe tuple-like values";
  let description = [{
    Returns ``true`` (``i1``) if every leaf of ``$lhs`` is strictly less than
    the corresponding leaf of ``$rhs``, otherwise returns ``false``. Each
    operand may be ``!cute.int_tuple``, ``!cute.shape``, or ``!cute.coord``,
    chosen independently.

    **Preconditions**

    - ``$lhs`` and ``$rhs`` are each ``!cute.int_tuple``, ``!cute.shape``, or
      ``!cute.coord`` (independently chosen).

    - ``$lhs`` and ``$rhs`` are congruent — same hierarchical rank/depth
      structure (matching ranks at every level). Rank or nesting
      mismatches at any depth are rejected.

    **Postconditions**

    - ``$result`` is ``i1``.
    - When all leaves are static, ``$result`` is fully resolved as the
      AND of ``lhs[i] < rhs[i]`` over all leaves.

    - When any leaf is dynamic, ``$result`` is dynamic (an SSA ``i1``
      value whose runtime evaluates the same comparison).

    **Examples**

    ```mlir
    %r = cute.elem_less(%a, %b)
           : (!cute.int_tuple<"(3,4)">, !cute.int_tuple<"(5,6)">)
          -> i1

    %r = cute.elem_less(%a, %b)
           : (!cute.shape<"(3,4)">, !cute.shape<"(5,6)">)
          -> i1

    // Mixed kinds — coord vs shape with matching profile.
    %r = cute.elem_less(%a, %b)
           : (!cute.coord<"(3,4)">, !cute.shape<"(5,6)">)
          -> i1
    ```

    **Errors**

    - ``$lhs`` and ``$rhs`` are not congruent (top-level rank differs, or
      nested structure differs at any depth).

    ```mlir
    // error: 'cute.elem_less' op expects congruent inputs, but got
    //        '!cute.int_tuple<"(3,4)">' and '!cute.int_tuple<"(3,4,5)">'
    cute.elem_less(%a, %b) : (!cute.int_tuple<"(3,4)">, !cute.int_tuple<"(3,4,5)">) -> i1

    // error: 'cute.elem_less' op expects congruent inputs, but got
    //        '!cute.int_tuple<"((1,2),3)">' and '!cute.int_tuple<"(4,5)">'
    cute.elem_less(%a, %b) : (!cute.int_tuple<"((1,2),3)">, !cute.int_tuple<"(4,5)">) -> i1
    ```
  }];
  let arguments = (ins
    Cute_Arg<Cute_ElemLessOperandType, "left-hand side">:$lhs,
    Cute_Arg<Cute_ElemLessOperandType, "right-hand side">:$rhs
  );
  let results = (outs
    Cute_Arg<I1, "less-than result">:$result
  );
  let assemblyFormat = [{
    `(` operands `)` attr-dict `:` functional-type(operands, results)
  }];
}

//===----------------------------------------------------------------------===//
// EqualOp
//===----------------------------------------------------------------------===//

/// Operand to `cute.equal`: the five cute kinds with first-class
/// equality support — `int_tuple`, `shape`, `coord`, `stride`, and
/// `layout`.
def Cute_EqualOperandType
    : AnyTypeOf<[Cute_IntTupleType, Cute_ShapeType, Cute_CoordType,
                 Cute_StrideType, Cute_LayoutType],
                "!cute.int_tuple, !cute.shape, !cute.coord, "
                "!cute.stride, or !cute.layout">;

def Cute_EqualOp : Cute_Op<"equal", [Pure]> {
  let cuteSpecGroup = "Arithmetic";
  let hasVerifier = 1;
  let summary = "Equality comparison of two CuTe values";
  let description = [{
    Returns ``true`` (``i1``) if ``$lhs`` and ``$rhs`` are structurally and
    value-equal, otherwise returns ``false``. Each operand may be
    ``!cute.int_tuple``, ``!cute.shape``, ``!cute.coord``, ``!cute.stride``,
    or ``!cute.layout``, but ``$lhs`` and ``$rhs`` must be the same kind.

    **Preconditions**

    - ``$lhs`` and ``$rhs`` are the same CuTe type kind (e.g. both
      ``!cute.shape``, both ``!cute.layout``, etc.). Cross-kind comparison
      is rejected even when the underlying values look similar
      (e.g. ``int_tuple`` vs ``shape``).

    **Postconditions**

    - ``$result`` is ``i1``.
    - When both operands are fully static, ``$result`` is fully
      resolved by structural and value equality.

    - When either operand has dynamic components, ``$result`` is
      dynamic (an SSA ``i1`` evaluated at runtime).

    **Examples**

    ```mlir
    // Equal int_tuple — true.
    %r = cute.equal(%a, %b)
           : (!cute.int_tuple<"(3,4)">, !cute.int_tuple<"(3,4)">)
          -> i1

    // Different shape values — false.
    %r = cute.equal(%a, %b)
           : (!cute.shape<"(3,4)">, !cute.shape<"(3,5)">)
          -> i1

    // Equal layout — true.
    %r = cute.equal(%a, %b)
           : (!cute.layout<"(4,8):(1,4)">, !cute.layout<"(4,8):(1,4)">)
          -> i1
    ```

    **Errors**

    - ``$lhs`` and ``$rhs`` have different kinds (cross-kind comparison
      is rejected, even with matching profiles).

    ```mlir
    // error: 'cute.equal' op expects lhs and rhs to be the same kind,
    //        but got '!cute.int_tuple<"(3,4)">' and '!cute.shape<"(3,4)">'
    cute.equal(%a, %b) : (!cute.int_tuple<"(3,4)">, !cute.shape<"(3,4)">) -> i1
    ```
  }];
  let arguments = (ins
    Cute_Arg<Cute_EqualOperandType, "left-hand side">:$lhs,
    Cute_Arg<Cute_EqualOperandType, "right-hand side">:$rhs
  );
  let results = (outs
    Cute_Arg<I1, "equality result">:$result
  );
  let assemblyFormat = [{
    `(` operands `)` attr-dict `:` functional-type(operands, results)
  }];
}

//===----------------------------------------------------------------------===//
// LogicalProductOp
//===----------------------------------------------------------------------===//

def Cute_LogicalProductOp : Cute_Op<"logical_product", [
    Pure,
    DeclareOpInterfaceMethods<InferTypeOpInterface>
]> {
  let cuteSpecGroup = "TilingPartitioningProducts";
  let summary = "Logical product of a layout and a tiler";
  let description = [{
    Produces a layout whose domain is the Cartesian product of
    ``$input``'s domain and ``$tiler``'s domain, with ``$tiler`` replicated
    across ``$input``. Formally ``A ⊗ B := (A, A* ∘ B)``, where ``A*`` is
    the complement of ``A`` taken up to ``size(A) * cosize(B)``.

    The result is rank-2: mode-0 is a copy of ``$input`` (``A``, the
    tile); mode-1 walks each tile to a unique position in the
    codomain so the tiles do not overlap. ``logical_product`` is the
    building block used by ``blocked_product``, ``raked_product``,
    ``tiled_product``, ``zipped_product``, and ``flat_product`` — these all
    share the same underlying construction and differ only in mode
    order/grouping:

    Given:

    - ``Layout Shape : (M, N, L, ...)``
    - ``Tiler Shape  : <TileM, TileN>``

    The variants:

    - ``logical_product : ((M,TileM), (N,TileN), L, ...)`` — pair per axis
    - ``zipped_product  : ((M,N), (TileM,TileN,L,...))`` — group input vs tile
    - ``tiled_product   : ((M,N), TileM, TileN, L, ...)`` — input grouped, tile flat
    - ``flat_product    : (M, N, TileM, TileN, L, ...)`` — everything flat
    - ``blocked_product : ((M,TileM), (N,TileN), L, ...)`` — input inner, tile outer
    - ``raked_product   : ((TileM,M), (TileN,N), L, ...)`` — pair per axis swapped (cyclic)

    The 3-step recipe is:

    1. ``A* = complement(A, size(A) * cosize(B))`` — the layout of the
       unique repetitions of ``A`` that together with ``A`` cover that
       codomain.
    2. ``A* ∘ B = composition(A*, B)`` — the layout of where each tile
       lives.
    3. ``result = make_layout(A, A* ∘ B)`` — pair the tile with the
       layout of its repetitions.

    For a coordinate ``(i, j)`` in the result, ``i`` walks within one
    tile (via ``A``) and ``j`` walks across tiles (via ``A* ∘ B``).

    Worked example — ``A = (2,2):(4,1)``, ``B = 6:1``:

    1. `A* = complement(A, size(A) * cosize(B)) = complement((2,2):(4,1), 24)
       = (2,3):(2,8)`.
    2. ``A* ∘ B = composition((2,3):(2,8), 6:1) = (2,3):(2,8)`` (since
       ``B`` is the identity, composition leaves ``A*`` unchanged).
    3. ``result = make_layout(A, A* ∘ B) = ((2,2),(2,3)):((4,1),(2,8))``.

    Mode-0 ``(2,2):(4,1)`` is the original 4-element tile; mode-1
    ``(2,3):(2,8)`` enumerates the 6 disjoint positions where copies
    of that tile live.

    **Preconditions**

    - ``$input`` is ``!cute.layout`` or ``!cute.composed_layout``. The
      ``A`` part (the plain layout itself, or the B-component of a
      composed input) must be fully static — every shape and
      stride leaf is a compile-time integer.

    - The ``A`` part's stride may contain scaled-basis values (e.g.
      ``N@M``).

    - ``$tiler`` is a plain ``!cute.layout``. The tiler's shape and
      stride may be dynamic, but the stride must contain only
      integer leaves — scaled-basis values (e.g. ``N@M``) are not
      supported on the tiler.

    - Cross-operand constraint: when the input's ``A``-stride
      contains scaled-basis values, ``$tiler`` must be fully static
      (shape and stride). Mixing a scaled-basis input with a
      dynamic tiler is not supported.

    **Postconditions**

    - ``$result`` has the same kind as ``$input`` (layout in / layout out;
      composed_layout in / composed_layout out preserving the
      swizzle or layout-A and offset; the product applies to the
      ``B`` part).

    - ``$result`` is rank-2 at the top level: mode-0 equals ``A``;
      mode-1 equals ``A* ∘ B``.

    - ``size($result) == size($input) * size($tiler)``.


    **Examples**

    ```mlir
    // Plain layout input.
    %r = cute.logical_product(%input, %tiler)
           : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(2,5):(1,2)">)
          -> !cute.layout<"((3,4),(2,5)):((4,1),(12,24))">

    // 1-D walkthrough
    %r = cute.logical_product(%input, %tiler)
           : (!cute.layout<"(2,2):(4,1)">, !cute.layout<"6:1">)
          -> !cute.layout<"((2,2),(2,3)):((4,1),(2,8))">

    // Composed-layout input — A/offset preserved; product applies to B.
    %r = cute.logical_product(%input, %tiler)
           : (!cute.composed_layout<"S<3,4,3> o 0 o (5,4):(4,1)">,
              !cute.layout<"(2,5):(1,2)">)
          -> !cute.composed_layout<"S<3,4,3> o 0 o ((5,4),(2,5)):((4,1),(20,40))">

    // Static input × dynamic tiler — tiler dynamism propagates to
    // mode-1 of the result.
    %r = cute.logical_product(%input, %tiler)
           : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(?,?):(1,2)">)
          -> !cute.layout<"((3,4),(?,?)):((4,1),(12,24))">

    // Scaled-basis input — supported when the tiler is fully static.
    // The result's mode-1 stride inherits the scaled-basis components
    // from `complement(input, ...)`.
    %r = cute.logical_product(%input, %tiler)
           : (!cute.layout<"(4,3):(1@0,1@1)">,
              !cute.layout<"(2,5):(1,2)">)
          -> !cute.layout<"((4,3),(2,5)):((1@0,1@1),(4@0,8@0))">
    ```

    **Errors**

    - ``$input``'s ``A`` part is not fully static (e.g. dyn shape or
      stride). Emits ``expects input to be static``.

    - ``$tiler`` has a scaled-basis stride. Emits
      `expects tiler stride to be integer-only (scaled-basis
      strides like 'N@M' are not supported)`.

    - Cross-operand guard: ``$input`` has a scaled-basis stride and
      ``$tiler`` is not fully static. Emits
      `expects tiler to be static when input has scaled-basis
      strides ('N@M')`.

    ```mlir
    // error: dyn shape on input (stride is static but shape is dyn).
    //        Emits "expects input to be static, but got
    //        '!cute.layout<"(?,8):(1,4)">'".
    %r = cute.logical_product(%a, %b)
           : (!cute.layout<"(?,8):(1,4)">, !cute.layout<"(2,4):(1,2)">) -> ...

    // error: dyn stride on input (rank-1 dyn-stride). Emits the same
    //        "expects input to be static" diagnostic — the op
    //        requires the input to be fully static.
    %r = cute.logical_product(%a, %b)
           : (!cute.layout<"?:?">, !cute.layout<"(2,5):(1,2)">) -> ...

    // error: dyn-shape / dyn-stride inside the B-component of a
    //        composed-layout input. Same diagnostic, applied to the
    //        composed_layout type.
    %r = cute.logical_product(%a, %b)
           : (!cute.composed_layout<"S<3,4,3> o 0 o (?,?):(?,?)">,
              !cute.layout<"(2,5):(1,2)">) -> ...

    // error: scaled-basis input combined with dynamic tiler is not
    //        supported (cross-operand pre-check rejects upfront).
    %r = cute.logical_product(%a, %b)
           : (!cute.layout<"(4,3):(1@0,1@1)">,
              !cute.layout<"(?,?):(?,?)">) -> ...
    ```
  }];
  let arguments = (ins
    Cute_Arg<Cute_AnyLayoutType, "lhs input layout">:$lhs,
    Cute_Arg<Cute_LayoutType, "rhs layout">:$rhs
  );
  let results = (outs
    Cute_Arg<Cute_AnyLayoutType, "product layout">:$result
  );
  let assemblyFormat = [{
    `(` operands `)` attr-dict `:` functional-type(operands, results)
  }];
}

//===----------------------------------------------------------------------===//
// ZippedProductOp
//===----------------------------------------------------------------------===//

def Cute_ZippedProductOp : Cute_Op<"zipped_product", [
    Pure,
    DeclareOpInterfaceMethods<InferTypeOpInterface>
]> {
  let cuteSpecGroup = "TilingPartitioningProducts";
  let summary = "Zipped product of a layout and a tiler";
  let description = [{
    Like ``cute.logical_product``, but the output modes are grouped
    by side instead of being paired per-axis: input modes are
    gathered into one nested mode and tile modes into another.

    Given:

    - ``Layout Shape : (M, N, L, ...)``
    - ``Tiler Shape  : <TileM, TileN>``

    The variants:

    - ``logical_product : ((M,TileM), (N,TileN), L, ...)`` — pair per axis
    - ``zipped_product  : ((M,N), (TileM,TileN,L,...))`` — group input vs tile
    - ``tiled_product   : ((M,N), TileM, TileN, L, ...)`` — input grouped, tile flat
    - ``flat_product    : (M, N, TileM, TileN, L, ...)`` — everything flat
    - ``blocked_product : ((M,TileM), (N,TileN), L, ...)`` — input inner, tile outer
    - ``raked_product   : ((TileM,M), (TileN,N), L, ...)`` — pair per axis swapped (cyclic)

    The pairing only differs from ``cute.logical_product`` when the
    tiler describes a per-axis tiling. For a plain layout tiler —
    the only kind this op accepts — ``zipped_product`` and
    ``logical_product`` produce the same result.

    **Preconditions**

    - ``$input`` is ``!cute.layout`` or ``!cute.composed_layout``. The
      ``A`` part (the plain layout itself, or the B-component of a
      composed input) must be fully static — every shape and
      stride leaf is a compile-time integer.

    - The ``A`` part's stride may contain scaled-basis values (e.g.
      ``N@M``).

    - ``$tiler`` is a plain ``!cute.layout``. The tiler's shape and
      stride may be dynamic, but the stride must contain only
      integer leaves — scaled-basis values (e.g. ``N@M``) are not
      supported on the tiler.

    - Cross-operand constraint: when the input's ``A``-stride
      contains scaled-basis values, ``$tiler`` must be fully static
      (shape and stride). Mixing a scaled-basis input with a
      dynamic tiler is not supported.

    **Postconditions**

    - ``$result`` has the same kind as ``$input``. For composed_layout
      input, the swizzle/layout-A and offset are preserved; the
      product applies to the ``B`` part.

    - ``$result``'s top-level structure groups input modes into
      mode-0 and tile modes (plus any trailing ``$input`` modes) into
      mode-1.

    - ``size($result) == size($input) * size($tiler)``.

    **Examples**

    ```mlir
    // Plain layout input.
    %r = cute.zipped_product(%input, %tiler)
           : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(2,5):(1,2)">)
          -> !cute.layout<"((3,4),(2,5)):((4,1),(12,24))">

    // Composed-layout input — A/offset preserved; product applies to B.
    %r = cute.zipped_product(%input, %tiler)
           : (!cute.composed_layout<"S<3,4,3> o 0 o (5,4):(4,1)">,
              !cute.layout<"(2,5):(1,2)">)
          -> !cute.composed_layout<"S<3,4,3> o 0 o ((5,4),(2,5)):((4,1),(20,40))">

    // Static input × dynamic tiler — tiler dynamism propagates to
    // mode-1 of the result.
    %r = cute.zipped_product(%input, %tiler)
           : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(?,?):(1,2)">)
          -> !cute.layout<"((3,4),(?,?)):((4,1),(12,24))">

    // Scaled-basis input — supported when the tiler is fully static.
    %r = cute.zipped_product(%input, %tiler)
           : (!cute.layout<"(4,3):(1@0,1@1)">,
              !cute.layout<"(2,5):(1,2)">)
          -> !cute.layout<"((4,3),(2,5)):((1@0,1@1),(4@0,8@0))">
    ```

    **Errors**

    - ``$input``'s ``A`` part is not fully static (e.g. dyn shape or
      stride). Emits ``expects input to be static``.

    - ``$tiler`` has a scaled-basis stride. Emits
      `expects tiler stride to be integer-only (scaled-basis
      strides like 'N@M' are not supported)`.

    - Cross-operand guard: scaled-basis ``$input`` + non-static
      ``$tiler``. Emits `expects tiler to be static when input has
      scaled-basis strides ('N@M')`.

    ```mlir
    // error: dyn shape on input.
    %r = cute.zipped_product(%a, %b)
           : (!cute.layout<"(?,8):(1,4)">, !cute.layout<"(2,4):(1,2)">) -> ...

    // error: scaled-basis input + dynamic tiler.
    %r = cute.zipped_product(%a, %b)
           : (!cute.layout<"(4,3):(1@0,1@1)">,
              !cute.layout<"(?,?):(?,?)">) -> ...
    ```
  }];
  let arguments = (ins
    Cute_Arg<Cute_AnyLayoutType, "lhs input layout">:$lhs,
    Cute_Arg<Cute_LayoutType, "rhs layout">:$rhs
  );
  let results = (outs
    Cute_Arg<Cute_AnyLayoutType, "product layout">:$result
  );
  let assemblyFormat = [{
    `(` operands `)` attr-dict `:` functional-type(operands, results)
  }];
}

//===----------------------------------------------------------------------===//
// TiledProductOp
//===----------------------------------------------------------------------===//

def Cute_TiledProductOp : Cute_Op<"tiled_product", [
    Pure,
    DeclareOpInterfaceMethods<InferTypeOpInterface>
]> {
  let cuteSpecGroup = "TilingPartitioningProducts";
  let summary = "Tiled product of a layout and a tiler";
  let description = [{
    Like ``cute.logical_product``, but the tile modes are laid out
    flat alongside the (grouped) input modes. The first mode of the
    result is the grouped input; the remaining modes are the
    individual tile modes laid out flat.

    Given:

    - ``Layout Shape : (M, N, L, ...)``
    - ``Tiler Shape  : <TileM, TileN>``

    The variants:

    - ``logical_product : ((M,TileM), (N,TileN), L, ...)`` — pair per axis
    - ``zipped_product  : ((M,N), (TileM,TileN,L,...))`` — group input vs tile
    - ``tiled_product   : ((M,N), TileM, TileN, L, ...)`` — input grouped, tile flat
    - ``flat_product    : (M, N, TileM, TileN, L, ...)`` — everything flat
    - ``blocked_product : ((M,TileM), (N,TileN), L, ...)`` — input inner, tile outer
    - ``raked_product   : ((TileM,M), (TileN,N), L, ...)`` — pair per axis swapped (cyclic)

    **Preconditions**

    - ``$input`` is ``!cute.layout`` or ``!cute.composed_layout``. The
      ``A`` part (the plain layout itself, or the B-component of a
      composed input) must be fully static — every shape and
      stride leaf is a compile-time integer.

    - The ``A`` part's stride may contain scaled-basis values (e.g.
      ``N@M``).

    - ``$tiler`` is a plain ``!cute.layout``. The tiler's shape and
      stride may be dynamic, but the stride must contain only
      integer leaves — scaled-basis values (e.g. ``N@M``) are not
      supported on the tiler.

    - Cross-operand constraint: when the input's ``A``-stride
      contains scaled-basis values, ``$tiler`` must be fully static
      (shape and stride). Mixing a scaled-basis input with a
      dynamic tiler is not supported.

    **Postconditions**

    - ``$result`` has the same kind as ``$input``. For composed_layout
      input, the swizzle/layout-A and offset are preserved; the
      product applies to the ``B`` part.

    - ``$result``'s mode-0 is the grouped input modes; the remaining
      top-level modes are the tile modes laid out flat.

    - ``size($result) == size($input) * size($tiler)``.

    **Examples**

    ```mlir
    // Plain layout input.
    %r = cute.tiled_product(%input, %tiler)
           : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(2,5):(1,2)">)
          -> !cute.layout<"((3,4),2,5):((4,1),12,24)">

    // Composed-layout input — A/offset preserved; product applies to B.
    %r = cute.tiled_product(%input, %tiler)
           : (!cute.composed_layout<"S<3,4,3> o 0 o (5,4):(4,1)">,
              !cute.layout<"(2,5):(1,2)">)
          -> !cute.composed_layout<"S<3,4,3> o 0 o ((5,4),2,5):((4,1),20,40)">

    // Static input × dynamic tiler — tiler dynamism propagates to
    // mode-1 of the result.
    %r = cute.tiled_product(%input, %tiler)
           : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(?,?):(1,2)">)
          -> !cute.layout<"((3,4),?,?):((4,1),12,24)">

    // Scaled-basis input — supported when the tiler is fully static.
    %r = cute.tiled_product(%input, %tiler)
           : (!cute.layout<"(4,3):(1@0,1@1)">,
              !cute.layout<"(2,5):(1,2)">)
          -> !cute.layout<"((4,3),2,5):((1@0,1@1),4@0,8@0)">
    ```

    **Errors**

    - ``$input``'s ``A`` part is not fully static (e.g. dyn shape or
      stride). Emits ``expects input to be static``.

    - ``$tiler`` has a scaled-basis stride. Emits
      `expects tiler stride to be integer-only (scaled-basis
      strides like 'N@M' are not supported)`.

    - Cross-operand guard: scaled-basis ``$input`` + non-static
      ``$tiler``. Emits `expects tiler to be static when input has
      scaled-basis strides ('N@M')`.

    ```mlir
    // error: dyn shape on input.
    %r = cute.tiled_product(%a, %b)
           : (!cute.layout<"(?,8):(1,4)">, !cute.layout<"(2,4):(1,2)">) -> ...

    // error: scaled-basis input + dynamic tiler.
    %r = cute.tiled_product(%a, %b)
           : (!cute.layout<"(4,3):(1@0,1@1)">,
              !cute.layout<"(?,?):(?,?)">) -> ...
    ```
  }];
  let arguments = (ins
    Cute_Arg<Cute_AnyLayoutType, "lhs input layout">:$lhs,
    Cute_Arg<Cute_LayoutType, "rhs layout">:$rhs
  );
  let results = (outs
    Cute_Arg<Cute_AnyLayoutType, "product layout">:$result
  );
  let assemblyFormat = [{
    `(` operands `)` attr-dict `:` functional-type(operands, results)
  }];
}

//===----------------------------------------------------------------------===//
// FlatProductOp
//===----------------------------------------------------------------------===//

def Cute_FlatProductOp : Cute_Op<"flat_product", [
    Pure,
    DeclareOpInterfaceMethods<InferTypeOpInterface>
]> {
  let cuteSpecGroup = "TilingPartitioningProducts";
  let summary = "Flat product of a layout and a tiler";
  let description = [{
    Like ``cute.logical_product``, but every mode (input modes
    followed by tile modes) is laid out flat — the result has no
    nested grouping.

    Given:

    - ``Layout Shape : (M, N, L, ...)``
    - ``Tiler Shape  : <TileM, TileN>``

    The variants:

    - ``logical_product : ((M,TileM), (N,TileN), L, ...)`` — pair per axis
    - ``zipped_product  : ((M,N), (TileM,TileN,L,...))`` — group input vs tile
    - ``tiled_product   : ((M,N), TileM, TileN, L, ...)`` — input grouped, tile flat
    - ``flat_product    : (M, N, TileM, TileN, L, ...)`` — everything flat
    - ``blocked_product : ((M,TileM), (N,TileN), L, ...)`` — input inner, tile outer
    - ``raked_product   : ((TileM,M), (TileN,N), L, ...)`` — pair per axis swapped (cyclic)

    **Preconditions**

    - ``$input`` is ``!cute.layout`` or ``!cute.composed_layout``. The
      ``A`` part (the plain layout itself, or the B-component of a
      composed input) must be fully static — every shape and
      stride leaf is a compile-time integer.

    - The ``A`` part's stride may contain scaled-basis values (e.g.
      ``N@M``).

    - ``$tiler`` is a plain ``!cute.layout``. The tiler's shape and
      stride may be dynamic, but the stride must contain only
      integer leaves — scaled-basis values (e.g. ``N@M``) are not
      supported on the tiler.

    - Cross-operand constraint: when the input's ``A``-stride
      contains scaled-basis values, ``$tiler`` must be fully static
      (shape and stride). Mixing a scaled-basis input with a
      dynamic tiler is not supported.

    **Postconditions**

    - ``$result`` has the same kind as ``$input``. For composed_layout
      input, the swizzle/layout-A and offset are preserved; the
      product applies to the ``B`` part.

    - ``$result`` has no nested grouping at the top level: input
      modes appear flat, followed by tile modes flat.

    - ``size($result) == size($input) * size($tiler)``.

    **Examples**

    ```mlir
    // Plain layout input.
    %r = cute.flat_product(%input, %tiler)
           : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(2,5):(1,2)">)
          -> !cute.layout<"(3,4,2,5):(4,1,12,24)">

    // Composed-layout input — A/offset preserved; product applies to B.
    %r = cute.flat_product(%input, %tiler)
           : (!cute.composed_layout<"S<3,4,3> o 0 o (5,4):(4,1)">,
              !cute.layout<"(2,5):(1,2)">)
          -> !cute.composed_layout<"S<3,4,3> o 0 o (5,4,2,5):(4,1,20,40)">

    // Static input × dynamic tiler — tiler dynamism propagates to
    // mode-1 of the result.
    %r = cute.flat_product(%input, %tiler)
           : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(?,?):(1,2)">)
          -> !cute.layout<"(3,4,?,?):(4,1,12,24)">

    // Scaled-basis input — supported when the tiler is fully static.
    %r = cute.flat_product(%input, %tiler)
           : (!cute.layout<"(4,3):(1@0,1@1)">,
              !cute.layout<"(2,5):(1,2)">)
          -> !cute.layout<"(4,3,2,5):(1@0,1@1,4@0,8@0)">
    ```

    **Errors**

    - ``$input``'s ``A`` part is not fully static (e.g. dyn shape or
      stride). Emits ``expects input to be static``.

    - ``$tiler`` has a scaled-basis stride. Emits
      `expects tiler stride to be integer-only (scaled-basis
      strides like 'N@M' are not supported)`.

    - Cross-operand guard: scaled-basis ``$input`` + non-static
      ``$tiler``. Emits `expects tiler to be static when input has
      scaled-basis strides ('N@M')`.

    ```mlir
    // error: dyn shape on input.
    %r = cute.flat_product(%a, %b)
           : (!cute.layout<"(?,8):(1,4)">, !cute.layout<"(2,4):(1,2)">) -> ...

    // error: scaled-basis input + dynamic tiler.
    %r = cute.flat_product(%a, %b)
           : (!cute.layout<"(4,3):(1@0,1@1)">,
              !cute.layout<"(?,?):(?,?)">) -> ...
    ```
  }];
  let arguments = (ins
    Cute_Arg<Cute_AnyLayoutType, "lhs input layout">:$lhs,
    Cute_Arg<Cute_LayoutType, "rhs layout">:$rhs
  );
  let results = (outs
    Cute_Arg<Cute_AnyLayoutType, "product layout">:$result
  );
  let assemblyFormat = [{
    `(` operands `)` attr-dict `:` functional-type(operands, results)
  }];
}

//===----------------------------------------------------------------------===//
// RakedProductOp
//===----------------------------------------------------------------------===//

def Cute_RakedProductOp : Cute_Op<"raked_product", [
    Pure,
    DeclareOpInterfaceMethods<InferTypeOpInterface>
]> {
  let cuteSpecGroup = "TilingPartitioningProducts";
  let summary = "Raked product of a layout and a tiler";
  let description = [{
    Like ``cute.blocked_product`` but with the tile and input modes
    swapped within each grouped result mode: tile-side modes are
    inner and input-side modes are outer. Copies of the input are
    interleaved ("raked") with the layout-of-tiles instead of laid
    out in contiguous blocks — this is sometimes called a cyclic
    distribution.

    For input shape ``(M, N, ...)`` and tiler shape
    ``(TileM, TileN, ...)``, the result groups modes as
    ``((TileM, M), (TileN, N), ...)`` — compare to
    ``cute.blocked_product`` which groups as
    ``((M, TileM), (N, TileN), ...)``.

    Given:

    - ``Layout Shape : (M, N, L, ...)``
    - ``Tiler Shape  : <TileM, TileN>``

    The variants:

    - ``logical_product : ((M,TileM), (N,TileN), L, ...)`` — pair per axis
    - ``zipped_product  : ((M,N), (TileM,TileN,L,...))`` — group input vs tile
    - ``tiled_product   : ((M,N), TileM, TileN, L, ...)`` — input grouped, tile flat
    - ``flat_product    : (M, N, TileM, TileN, L, ...)`` — everything flat
    - ``blocked_product : ((M,TileM), (N,TileN), L, ...)`` — input inner, tile outer
    - ``raked_product   : ((TileM,M), (TileN,N), L, ...)`` — pair per axis swapped (cyclic)

    **Preconditions**

    - ``$input`` is ``!cute.layout`` or ``!cute.composed_layout``. The
      ``A`` part (the plain layout itself, or the B-component of a
      composed input) must be fully static — every shape and
      stride leaf is a compile-time integer.

    - The ``A`` part's stride may contain scaled-basis values (e.g.
      ``N@M``).

    - ``$tiler`` is a plain ``!cute.layout``. The tiler's shape and
      stride may be dynamic, but the stride must contain only
      integer leaves — scaled-basis values (e.g. ``N@M``) are not
      supported on the tiler.

    - Cross-operand constraint: when the input's ``A``-stride
      contains scaled-basis values, ``$tiler`` must be fully static
      (shape and stride). Mixing a scaled-basis input with a
      dynamic tiler is not supported.

    **Postconditions**

    - ``$result`` has the same kind as ``$input``. For composed_layout
      input, the swizzle/layout-A and offset are preserved; the
      product applies to the ``B`` part.

    - ``$result`` groups one (tile-mode, input-mode) pair per axis
      with tile inner and input outer.

    - ``size($result) == size($input) * size($tiler)``.

    **Examples**

    ```mlir
    // Plain layout input — input modes (3,4) raked inside tile modes (2,5).
    %r = cute.raked_product(%input, %tiler)
           : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(2,5):(1,2)">)
          -> !cute.layout<"((2,3),(5,4)):((12,4),(24,1))">

    // Composed-layout input — A/offset preserved; product applies to B.
    %r = cute.raked_product(%input, %tiler)
           : (!cute.composed_layout<"S<3,4,3> o 0 o (5,4):(4,1)">,
              !cute.layout<"(2,5):(1,2)">)
          -> !cute.composed_layout<"S<3,4,3> o 0 o ((2,5),(5,4)):((20,4),(40,1))">

    // Static input × dynamic tiler — tiler dynamism propagates to
    // mode-1 of the result.
    %r = cute.raked_product(%input, %tiler)
           : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(?,?):(1,2)">)
          -> !cute.layout<"((?,3),(?,4)):((12,4),(24,1))">

    // Scaled-basis input — supported when the tiler is fully static.
    %r = cute.raked_product(%input, %tiler)
           : (!cute.layout<"(4,3):(1@0,1@1)">,
              !cute.layout<"(2,5):(1,2)">)
          -> !cute.layout<"((2,4),(5,3)):((4@0,1@0),(8@0,1@1))">
    ```

    **Errors**

    - ``$input``'s ``A`` part is not fully static (e.g. dyn shape or
      stride). Emits ``expects input to be static``.

    - ``$tiler`` has a scaled-basis stride. Emits
      `expects tiler stride to be integer-only (scaled-basis
      strides like 'N@M' are not supported)`.

    - Cross-operand guard: scaled-basis ``$input`` + non-static
      ``$tiler``. Emits `expects tiler to be static when input has
      scaled-basis strides ('N@M')`.

    ```mlir
    // error: dyn shape on input.
    %r = cute.raked_product(%a, %b)
           : (!cute.layout<"(?,8):(1,4)">, !cute.layout<"(2,4):(1,2)">) -> ...

    // error: scaled-basis input + dynamic tiler.
    %r = cute.raked_product(%a, %b)
           : (!cute.layout<"(4,3):(1@0,1@1)">,
              !cute.layout<"(?,?):(?,?)">) -> ...
    ```
  }];
  let arguments = (ins
    Cute_Arg<Cute_AnyLayoutType, "lhs input layout">:$lhs,
    Cute_Arg<Cute_LayoutType, "rhs layout">:$rhs
  );
  let results = (outs
    Cute_Arg<Cute_AnyLayoutType, "product layout">:$result
  );
  let assemblyFormat = [{
    `(` operands `)` attr-dict `:` functional-type(operands, results)
  }];
}

//===----------------------------------------------------------------------===//
// BlockedProductOp
//===----------------------------------------------------------------------===//

def Cute_BlockedProductOp : Cute_Op<"blocked_product", [
    Pure,
    DeclareOpInterfaceMethods<InferTypeOpInterface>
]> {
  let cuteSpecGroup = "TilingPartitioningProducts";
  let summary = "Blocked product of a layout and a tiler";
  let description = [{
    Like ``cute.logical_product``, but with the natural
    "tile-of-blocks" arrangement: per-axis groupings with input
    modes inner and tile modes outer. For input shape ``(M, N, ...)``
    and tiler shape ``(TileM, TileN, ...)``, the result groups modes
    as ``((M, TileM), (N, TileN), ...)`` — compare to
    ``cute.raked_product`` which swaps each pair to
    ``((TileM, M), (TileN, N), ...)``.

    Given:

    - ``Layout Shape : (M, N, L, ...)``
    - ``Tiler Shape  : <TileM, TileN>``

    The variants:

    - ``logical_product : ((M,TileM), (N,TileN), L, ...)`` — pair per axis
    - ``zipped_product  : ((M,N), (TileM,TileN,L,...))`` — group input vs tile
    - ``tiled_product   : ((M,N), TileM, TileN, L, ...)`` — input grouped, tile flat
    - ``flat_product    : (M, N, TileM, TileN, L, ...)`` — everything flat
    - ``blocked_product : ((M,TileM), (N,TileN), L, ...)`` — input inner, tile outer
    - ``raked_product   : ((TileM,M), (TileN,N), L, ...)`` — pair per axis swapped (cyclic)

    **Preconditions**

    - ``$input`` is ``!cute.layout`` or ``!cute.composed_layout``. The
      ``A`` part (the plain layout itself, or the B-component of a
      composed input) must be fully static — every shape and
      stride leaf is a compile-time integer.

    - The ``A`` part's stride may contain scaled-basis values (e.g.
      ``N@M``).

    - ``$tiler`` is a plain ``!cute.layout``. The tiler's shape and
      stride may be dynamic, but the stride must contain only
      integer leaves — scaled-basis values (e.g. ``N@M``) are not
      supported on the tiler.

    - Cross-operand constraint: when the input's ``A``-stride
      contains scaled-basis values, ``$tiler`` must be fully static
      (shape and stride). Mixing a scaled-basis input with a
      dynamic tiler is not supported.

    **Postconditions**

    - ``$result`` has the same kind as ``$input``. For composed_layout
      input, the swizzle/layout-A and offset are preserved; the
      product applies to the ``B`` part.

    - ``$result`` groups one (input-mode, tile-mode) pair per axis
      with input inner and tile outer.

    - ``size($result) == size($input) * size($tiler)``.

    **Examples**

    ```mlir
    // Plain layout input — input modes (3,4) inner, tile modes (2,5) outer.
    %r = cute.blocked_product(%input, %tiler)
           : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(2,5):(1,2)">)
          -> !cute.layout<"((3,2),(4,5)):((4,12),(1,24))">

    // Composed-layout input — A/offset preserved; product applies to B.
    %r = cute.blocked_product(%input, %tiler)
           : (!cute.composed_layout<"S<3,4,3> o 0 o (5,4):(4,1)">,
              !cute.layout<"(2,5):(1,2)">)
          -> !cute.composed_layout<"S<3,4,3> o 0 o ((5,2),(4,5)):((4,20),(1,40))">

    // Static input × dynamic tiler — tiler dynamism propagates to
    // mode-1 of the result.
    %r = cute.blocked_product(%input, %tiler)
           : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(?,?):(1,2)">)
          -> !cute.layout<"((3,?),(4,?)):((4,12),(1,24))">

    // Scaled-basis input — supported when the tiler is fully static.
    %r = cute.blocked_product(%input, %tiler)
           : (!cute.layout<"(4,3):(1@0,1@1)">,
              !cute.layout<"(2,5):(1,2)">)
          -> !cute.layout<"((4,2),(3,5)):((1@0,4@0),(1@1,8@0))">
    ```

    **Errors**

    - ``$input``'s ``A`` part is not fully static (e.g. dyn shape or
      stride). Emits ``expects input to be static``.

    - ``$tiler`` has a scaled-basis stride. Emits
      `expects tiler stride to be integer-only (scaled-basis
      strides like 'N@M' are not supported)`.

    - Cross-operand guard: scaled-basis ``$input`` + non-static
      ``$tiler``. Emits `expects tiler to be static when input has
      scaled-basis strides ('N@M')`.

    ```mlir
    // error: dyn shape on input.
    %r = cute.blocked_product(%a, %b)
           : (!cute.layout<"(?,8):(1,4)">, !cute.layout<"(2,4):(1,2)">) -> ...

    // error: scaled-basis input + dynamic tiler.
    %r = cute.blocked_product(%a, %b)
           : (!cute.layout<"(4,3):(1@0,1@1)">,
              !cute.layout<"(?,?):(?,?)">) -> ...
    ```
  }];
  let arguments = (ins
    Cute_Arg<Cute_AnyLayoutType, "lhs input layout">:$lhs,
    Cute_Arg<Cute_LayoutType, "rhs layout">:$rhs
  );
  let results = (outs
    Cute_Arg<Cute_AnyLayoutType, "product layout">:$result
  );
  let assemblyFormat = [{
    `(` operands `)` attr-dict `:` functional-type(operands, results)
  }];
}

//===----------------------------------------------------------------------===//
// LogicalDivideOp
//===----------------------------------------------------------------------===//

def Cute_LogicalDivideOp : Cute_Op<"logical_divide", [
    Pure,
    DeclareOpInterfaceMethods<InferTypeOpInterface>
]> {
  let cuteSpecGroup = "TilingPartitioningProducts";
  let summary = "Logical divide of a layout by a tiler";
  let description = [{
    Partitions ``$input`` (``A``) by ``$tiler`` (``B``) into a 2-D layout
    whose mode-0 is the tile part (elements within one tile) and
    mode-1 is the residual part (tile indices). Formally
    ``A ⊘ B := A ∘ (B, B*)``, where ``B*`` is the complement of ``B``
    taken up to ``size(A)``.

    ``logical_divide`` is the building block used by
    ``zipped_divide``, ``tiled_divide``, and ``flat_divide``. The full
    divide family differs only in mode order/grouping:

    Given:

    - ``Layout Shape : (M, N, L, ...)``
    - ``Tiler Shape  : <TileM, TileN>``

    The variants:

    - ``logical_divide : ((TileM,RestM), (TileN,RestN), L, ...)`` — pair per axis
    - ``zipped_divide  : ((TileM,TileN), (RestM,RestN,L,...))`` — group tile vs rest
    - ``tiled_divide   : ((TileM,TileN), RestM, RestN, L, ...)`` — tile grouped, rest flat
    - ``flat_divide    : (TileM, TileN, RestM, RestN, L, ...)`` — everything flat

    The 3-step recipe is:

    1. ``B* = complement(B, size(A))`` — the layout-of-tiles, walking
       the elements of ``A`` not selected by ``B``.
    2. ``(B, B*)`` — concatenate the tiler with its complement.
    3. ``result = composition(A, (B, B*))``.

    For a coordinate ``(i, j)`` in the result, ``i`` walks within one
    tile (via ``B``) and ``j`` walks across tiles (via ``B*``).

    Worked example — ``A = (4,2,3):(2,1,8)``, ``B = 4:2``:

    1. ``B* = complement(B, size(A)) = complement(4:2, 24) = (2,3):(1,8)``.
    2. ``(B, B*) = (4,(2,3)):(2,(1,8))``.
    3. ``result = composition(A, (B, B*)) = ((2,2),(2,3)):((4,1),(2,8))``.

    Mode-0 ``(2,2):(4,1)`` is one 4-element tile; mode-1
    ``(2,3):(2,8)`` walks the 6 disjoint tile positions.

    **Preconditions**

    - ``$input`` is ``!cute.layout`` or ``!cute.composed_layout``. There
      is no static-ness or stride constraint on the input.

    - ``$tiler`` is ``!cute.layout``, ``!cute.tile``, or ``!cute.shape``.
    - For shape and tile tilers, ``rank($tiler) <= rank($input)``
      (or ``rank($input.B)`` for composed input).

    - For layout tilers — and every layout sub-component of a tile
      tiler — the stride must contain only integer leaves (no
      scaled-basis ``N@M``), and the layout must be either rank-1
      or fully-static-stride.

    **Postconditions**

    - ``$result`` has the same type as ``$input`` (layout in / layout
      out; composed_layout in / composed_layout out, with the
      swizzle/layout-A and offset preserved — divide applies to
      the ``B`` part).

    - For shape and layout tilers, ``$result`` is rank-2: mode-0 is
      the tile part ``B``; mode-1 is the residual part ``B*``. For
      tile tilers, the per-mode dispatch produces a per-axis
      grouping that follows the tile structure.

    - ``size($result) == size($input)``.

    **Examples**

    ```mlir
    // Plain layout input, shape tiler.
    %r = cute.logical_divide(%input, %tiler)
           : (!cute.layout<"(6,8):(8,1)">, !cute.shape<"(3,4)">)
          -> !cute.layout<"((3,2),(4,2)):((8,24),(1,4))">

    // 1-D walkthrough (A=(4,2,3):(2,1,8), B=4:2). Layout tiler.
    %r = cute.logical_divide(%input, %tiler)
           : (!cute.layout<"(4,2,3):(2,1,8)">, !cute.layout<"4:2">)
          -> !cute.layout<"((2,2),(2,3)):((4,1),(2,8))">

    // Tile tiler — per-mode divide.
    %r = cute.logical_divide(%input, %tiler)
           : (!cute.layout<"(6,8):(8,1)">, !cute.tile<"[3:1;4:1]">)
          -> !cute.layout<"((3,2),(4,2)):((8,24),(1,4))">

    // Nested tile tiler — outer mode 0 is itself a rank-1 tile,
    // producing an extra level of grouping in the result.
    %r = cute.logical_divide(%input, %tiler)
           : (!cute.layout<"(6,8):(8,1)">, !cute.tile<"[[3:1];4:1]">)
          -> !cute.layout<"(((3,2)),(4,2)):(((8,24)),(1,4))">

    // Composed-layout input — A/offset preserved; divide applies to B.
    %r = cute.logical_divide(%input, %tiler)
           : (!cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">,
              !cute.shape<"(3,4)">)
          -> !cute.composed_layout<"S<3,4,3> o 0 o ((3,2),(4,2)):((8,24),(1,4))">

    // Static scaled-basis layout tiler.
    %r = cute.logical_divide(%input, %tiler)
           : (!cute.layout<"(128,64):(1@1,1@0)">,
              !cute.layout<"2:64@0">)
          -> !cute.layout<"(2,(64,64)):(64@1,(1@1,1@0))">
    ```

    **Errors**

    - rank(tiler) > rank(input) for shape or tile tilers.

      ```mlir
      //        Emits "expects rank(tiler) <= rank(input), but got
      //        rank 2 tiler and rank 1 input".
      %r = cute.logical_divide(%a, %b)
             : (!cute.layout<"24:1">, !cute.shape<"(4,6)">) -> ...
      ```

    - layout tiler with a scaled-basis stride. Emits "expects

      ```mlir
      //        tiler stride to be integer-only (scaled-basis strides
      //        like 'N@M' are not supported), but got tiler
      //        (3,4):(1@0,1@1)". For tile tilers, the diagnostic
      //        includes the mode path to the offending sub-component.
      %r = cute.logical_divide(%a, %b)
             : (!cute.layout<"(6,8):(8,1)">,
                !cute.layout<"(3,4):(1@0,1@1)">) -> ...
      ```

    - dyn-stride rank-2 layout tiler. Emits "expects tiler

      ```mlir
      //        to have a static stride or to be rank-1, but got tiler
      //        (?,?):(?,?)". A rank-1 dyn-stride tiler `?:?` is
      //        accepted.
      %r = cute.logical_divide(%a, %b)
             : (!cute.layout<"(6,8):(8,1)">,
                !cute.layout<"(?,?):(?,?)">) -> ...
      ```

    - nested tile tiler with an inner mode-1 dyn-stride

      ```mlir
      //        rank-2 layout. Diagnostic reports the mode path
      //        `[0, 1]` (outer mode 0, then inner mode 1) for the
      //        offending sub-component.
      %r = cute.logical_divide(%a, %b)
             : (!cute.layout<"(6,8):(8,1)">,
                !cute.tile<"[[3:1;(?,?):(?,?)];4:1]">) -> ...
      ```
  }];
  let arguments = (ins
    Cute_Arg<Cute_AnyLayoutType, "input layout">:$input,
    Cute_Arg<Cute_DividerType, "tiler">:$tiler
  );
  let results = (outs
    Cute_Arg<Cute_AnyLayoutType, "divided layout">:$result
  );
  let assemblyFormat = [{
    `(` operands `)` attr-dict `:` functional-type(operands, results)
  }];
}

//===----------------------------------------------------------------------===//
// ZippedDivideOp
//===----------------------------------------------------------------------===//

def Cute_ZippedDivideOp : Cute_Op<"zipped_divide", [
    Pure,
    DeclareOpInterfaceMethods<InferTypeOpInterface>
]> {
  let cuteSpecGroup = "TilingPartitioningProducts";
  let summary = "Zipped divide of a layout by a tiler";
  let description = [{
    Like ``cute.logical_divide``, but the output modes are grouped
    by side instead of paired per-axis: tile modes are gathered into
    one nested mode and residual modes into another. Mode-0 of the
    result is ``composition($input, $tiler)``; mode-1 is the
    layout-of-tiles.

    Given:

    - ``Layout Shape : (M, N, L, ...)``
    - ``Tiler Shape  : <TileM, TileN>``

    The variants:

    - ``logical_divide : ((TileM,RestM), (TileN,RestN), L, ...)`` — pair per axis
    - ``zipped_divide  : ((TileM,TileN), (RestM,RestN,L,...))`` — group tile vs rest
    - ``tiled_divide   : ((TileM,TileN), RestM, RestN, L, ...)`` — tile grouped, rest flat
    - ``flat_divide    : (TileM, TileN, RestM, RestN, L, ...)`` — everything flat

    **Preconditions**

    - ``$input`` is ``!cute.layout`` or ``!cute.composed_layout``. There
      is no static-ness or stride constraint on the input.

    - ``$tiler`` is ``!cute.layout``, ``!cute.tile``, or ``!cute.shape``.
    - For shape and tile tilers, ``rank($tiler) <= rank($input)``
      (or ``rank($input.B)`` for composed input).

    - For layout tilers — and every layout sub-component of a tile
      tiler — the stride must contain only integer leaves (no
      scaled-basis ``N@M``), and the layout must be either rank-1
      or fully-static-stride.

    **Postconditions**

    - ``$result`` has the same kind as ``$input``. For composed_layout
      input, the swizzle/layout-A and offset are preserved; the
      divide applies to the ``B`` part.

    - ``$result``'s top-level structure groups tile modes into
      mode-0 and residual modes (plus any trailing ``$input`` modes)
      into mode-1.

    - ``size($result) == size($input)``.

    **Examples**

    ```mlir
    // Plain layout input, shape tiler.
    %r = cute.zipped_divide(%input, %tiler)
           : (!cute.layout<"(6,8):(8,1)">, !cute.shape<"(3,4)">)
          -> !cute.layout<"((3,4),(2,2)):((8,1),(24,4))">

    // Composed-layout input — A/offset preserved; divide applies to B.
    %r = cute.zipped_divide(%input, %tiler)
           : (!cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">,
              !cute.shape<"(3,4)">)
          -> !cute.composed_layout<"S<3,4,3> o 0 o ((3,4),(2,2)):((8,1),(24,4))">

    // Tile tiler — per-mode divide.
    %r = cute.zipped_divide(%input, %tiler)
           : (!cute.layout<"(6,8):(8,1)">, !cute.tile<"[(3):(1);(4):(1)]">)
          -> !cute.layout<"(((3),(4)),(2,2)):(((8),(1)),(24,4))">

    // Static scaled-basis layout tiler.
    %r = cute.zipped_divide(%input, %tiler)
           : (!cute.layout<"(128,64):(1@1,1@0)">,
              !cute.layout<"2:64@0">)
          -> !cute.layout<"(2,(64,64)):(64@1,(1@1,1@0))">
    ```

    **Errors**

    - rank(tiler) > rank(input) for shape or tile tilers.

      ```mlir
      //        Emits "expects rank(tiler) <= rank(input), but got
      //        rank 2 tiler and rank 1 input".
      %r = cute.zipped_divide(%a, %b)
             : (!cute.layout<"24:1">, !cute.shape<"(4,6)">) -> ...
      ```

    - layout tiler with a scaled-basis stride. Emits "expects

      ```mlir
      //        tiler stride to be integer-only (scaled-basis strides
      //        like 'N@M' are not supported), but got tiler
      //        (3,4):(1@0,1@1)". For tile tilers, the diagnostic
      //        includes the mode path to the offending sub-component.
      %r = cute.zipped_divide(%a, %b)
             : (!cute.layout<"(6,8):(8,1)">,
                !cute.layout<"(3,4):(1@0,1@1)">) -> ...
      ```

    - dyn-stride rank-2 layout tiler. Emits "expects tiler

      ```mlir
      //        to have a static stride or to be rank-1, but got tiler
      //        (?,?):(?,?)". A rank-1 dyn-stride tiler `?:?` is
      //        accepted.
      %r = cute.zipped_divide(%a, %b)
             : (!cute.layout<"(6,8):(8,1)">,
                !cute.layout<"(?,?):(?,?)">) -> ...
      ```

    - nested tile tiler with an inner mode-1 dyn-stride

      ```mlir
      //        rank-2 layout. Diagnostic reports the mode path
      //        `[0, 1]` (outer mode 0, then inner mode 1) for the
      //        offending sub-component.
      %r = cute.zipped_divide(%a, %b)
             : (!cute.layout<"(6,8):(8,1)">,
                !cute.tile<"[[3:1;(?,?):(?,?)];4:1]">) -> ...
      ```
  }];
  let arguments = (ins
    Cute_Arg<Cute_AnyLayoutType, "input layout">:$input,
    Cute_Arg<Cute_DividerType, "tiler">:$tiler
  );
  let results = (outs
    Cute_Arg<Cute_AnyLayoutType, "divided layout">:$result
  );
  let assemblyFormat = [{
    `(` operands `)` attr-dict `:` functional-type(operands, results)
  }];
}

//===----------------------------------------------------------------------===//
// TiledDivideOp
//===----------------------------------------------------------------------===//

def Cute_TiledDivideOp : Cute_Op<"tiled_divide", [
    Pure,
    DeclareOpInterfaceMethods<InferTypeOpInterface>
]> {
  let cuteSpecGroup = "TilingPartitioningProducts";
  let summary = "Tiled divide of a layout by a tiler";
  let description = [{
    Like ``cute.zipped_divide`` but with the residual mode group
    flattened: only the tile (inner) modes stay grouped. The tile
    sits in mode-0; the rest follows as flat outer modes.

    Given:

    - ``Layout Shape : (M, N, L, ...)``
    - ``Tiler Shape  : <TileM, TileN>``

    The variants:

    - ``logical_divide : ((TileM,RestM), (TileN,RestN), L, ...)`` — pair per axis
    - ``zipped_divide  : ((TileM,TileN), (RestM,RestN,L,...))`` — group tile vs rest
    - ``tiled_divide   : ((TileM,TileN), RestM, RestN, L, ...)`` — tile grouped, rest flat
    - ``flat_divide    : (TileM, TileN, RestM, RestN, L, ...)`` — everything flat

    **Preconditions**

    - ``$input`` is ``!cute.layout`` or ``!cute.composed_layout``. There
      is no static-ness or stride constraint on the input.

    - ``$tiler`` is ``!cute.layout``, ``!cute.tile``, or ``!cute.shape``.
    - For shape and tile tilers, ``rank($tiler) <= rank($input)``
      (or ``rank($input.B)`` for composed input).

    - For layout tilers — and every layout sub-component of a tile
      tiler — the stride must contain only integer leaves (no
      scaled-basis ``N@M``), and the layout must be either rank-1
      or fully-static-stride.

    **Postconditions**

    - ``$result`` has the same kind as ``$input``. For composed_layout
      input, the swizzle/layout-A and offset are preserved; the
      divide applies to the ``B`` part.

    - ``$result``'s mode-0 is the grouped tile modes; the remaining
      top-level modes are the residual modes laid out flat.

    - ``size($result) == size($input)``.

    **Examples**

    ```mlir
    // Plain layout input, shape tiler.
    %r = cute.tiled_divide(%input, %tiler)
           : (!cute.layout<"(6,8):(8,1)">, !cute.shape<"(3,4)">)
          -> !cute.layout<"((3,4),2,2):((8,1),24,4)">

    // Composed-layout input — A/offset preserved; divide applies to B.
    %r = cute.tiled_divide(%input, %tiler)
           : (!cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">,
              !cute.shape<"(3,4)">)
          -> !cute.composed_layout<"S<3,4,3> o 0 o ((3,4),2,2):((8,1),24,4)">

    // Tile tiler — per-mode divide.
    %r = cute.tiled_divide(%input, %tiler)
           : (!cute.layout<"(6,8):(8,1)">, !cute.tile<"[(3):(1);(4):(1)]">)
          -> !cute.layout<"(((3),(4)),2,2):(((8),(1)),24,4)">

    // Static scaled-basis layout tiler.
    %r = cute.tiled_divide(%input, %tiler)
           : (!cute.layout<"(128,64):(1@1,1@0)">,
              !cute.layout<"2:64@0">)
          -> !cute.layout<"(2,64,64):(64@1,1@1,1@0)">
    ```

    **Errors**

    - rank(tiler) > rank(input) for shape or tile tilers.

      ```mlir
      //        Emits "expects rank(tiler) <= rank(input), but got
      //        rank 2 tiler and rank 1 input".
      %r = cute.tiled_divide(%a, %b)
             : (!cute.layout<"24:1">, !cute.shape<"(4,6)">) -> ...
      ```

    - layout tiler with a scaled-basis stride. Emits "expects

      ```mlir
      //        tiler stride to be integer-only (scaled-basis strides
      //        like 'N@M' are not supported), but got tiler
      //        (3,4):(1@0,1@1)". For tile tilers, the diagnostic
      //        includes the mode path to the offending sub-component.
      %r = cute.tiled_divide(%a, %b)
             : (!cute.layout<"(6,8):(8,1)">,
                !cute.layout<"(3,4):(1@0,1@1)">) -> ...
      ```

    - dyn-stride rank-2 layout tiler. Emits "expects tiler

      ```mlir
      //        to have a static stride or to be rank-1, but got tiler
      //        (?,?):(?,?)". A rank-1 dyn-stride tiler `?:?` is
      //        accepted.
      %r = cute.tiled_divide(%a, %b)
             : (!cute.layout<"(6,8):(8,1)">,
                !cute.layout<"(?,?):(?,?)">) -> ...
      ```

    - nested tile tiler with an inner mode-1 dyn-stride

      ```mlir
      //        rank-2 layout. Diagnostic reports the mode path
      //        `[0, 1]` (outer mode 0, then inner mode 1) for the
      //        offending sub-component.
      %r = cute.tiled_divide(%a, %b)
             : (!cute.layout<"(6,8):(8,1)">,
                !cute.tile<"[[3:1;(?,?):(?,?)];4:1]">) -> ...
      ```
  }];
  let arguments = (ins
    Cute_Arg<Cute_AnyLayoutType, "input layout">:$input,
    Cute_Arg<Cute_DividerType, "tiler">:$tiler
  );
  let results = (outs
    Cute_Arg<Cute_AnyLayoutType, "divided layout">:$result
  );
  let assemblyFormat = [{
    `(` operands `)` attr-dict `:` functional-type(operands, results)
  }];
}

//===----------------------------------------------------------------------===//
// FlatDivideOp
//===----------------------------------------------------------------------===//

def Cute_FlatDivideOp : Cute_Op<"flat_divide", [
    Pure,
    DeclareOpInterfaceMethods<InferTypeOpInterface>
]> {
  let cuteSpecGroup = "TilingPartitioningProducts";
  let summary = "Flat divide of a layout by a tiler";
  let description = [{
    Like ``cute.zipped_divide`` but with both mode groups flattened —
    the result has no nested grouping. Tile modes appear first,
    followed by residual modes, all flat.

    Given:

    - ``Layout Shape : (M, N, L, ...)``
    - ``Tiler Shape  : <TileM, TileN>``

    The variants:

    - ``logical_divide : ((TileM,RestM), (TileN,RestN), L, ...)`` — pair per axis
    - ``zipped_divide  : ((TileM,TileN), (RestM,RestN,L,...))`` — group tile vs rest
    - ``tiled_divide   : ((TileM,TileN), RestM, RestN, L, ...)`` — tile grouped, rest flat
    - ``flat_divide    : (TileM, TileN, RestM, RestN, L, ...)`` — everything flat

    **Preconditions**

    - ``$input`` is ``!cute.layout`` or ``!cute.composed_layout``. There
      is no static-ness or stride constraint on the input.

    - ``$tiler`` is ``!cute.layout``, ``!cute.tile``, or ``!cute.shape``.
    - For shape and tile tilers, ``rank($tiler) <= rank($input)``
      (or ``rank($input.B)`` for composed input).

    - For layout tilers — and every layout sub-component of a tile
      tiler — the stride must contain only integer leaves (no
      scaled-basis ``N@M``), and the layout must be either rank-1
      or fully-static-stride.

    **Postconditions**

    - ``$result`` has the same kind as ``$input``. For composed_layout
      input, the swizzle/layout-A and offset are preserved; the
      divide applies to the ``B`` part.

    - ``$result`` has no nested grouping at the top level: tile modes
      appear flat, followed by residual modes flat.

    - ``size($result) == size($input)``.

    **Examples**

    ```mlir
    // Plain layout input, shape tiler.
    %r = cute.flat_divide(%input, %tiler)
           : (!cute.layout<"(6,8):(8,1)">, !cute.shape<"(3,4)">)
          -> !cute.layout<"(3,4,2,2):(8,1,24,4)">

    // Composed-layout input — A/offset preserved; divide applies to B.
    %r = cute.flat_divide(%input, %tiler)
           : (!cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">,
              !cute.shape<"(3,4)">)
          -> !cute.composed_layout<"S<3,4,3> o 0 o (3,4,2,2):(8,1,24,4)">

    // Tile tiler — per-mode divide.
    %r = cute.flat_divide(%input, %tiler)
           : (!cute.layout<"(6,8):(8,1)">, !cute.tile<"[(3):(1);(4):(1)]">)
          -> !cute.layout<"((3),(4),2,2):((8),(1),24,4)">

    // Static scaled-basis layout tiler.
    %r = cute.flat_divide(%input, %tiler)
           : (!cute.layout<"(128,64):(1@1,1@0)">,
              !cute.layout<"2:64@0">)
          -> !cute.layout<"(2,64,64):(64@1,1@1,1@0)">
    ```

    **Errors**

    - rank(tiler) > rank(input) for shape or tile tilers.

      ```mlir
      //        Emits "expects rank(tiler) <= rank(input), but got
      //        rank 2 tiler and rank 1 input".
      %r = cute.flat_divide(%a, %b)
             : (!cute.layout<"24:1">, !cute.shape<"(4,6)">) -> ...
      ```

    - layout tiler with a scaled-basis stride. Emits "expects

      ```mlir
      //        tiler stride to be integer-only (scaled-basis strides
      //        like 'N@M' are not supported), but got tiler
      //        (3,4):(1@0,1@1)". For tile tilers, the diagnostic
      //        includes the mode path to the offending sub-component.
      %r = cute.flat_divide(%a, %b)
             : (!cute.layout<"(6,8):(8,1)">,
                !cute.layout<"(3,4):(1@0,1@1)">) -> ...
      ```

    - dyn-stride rank-2 layout tiler. Emits "expects tiler

      ```mlir
      //        to have a static stride or to be rank-1, but got tiler
      //        (?,?):(?,?)". A rank-1 dyn-stride tiler `?:?` is
      //        accepted.
      %r = cute.flat_divide(%a, %b)
             : (!cute.layout<"(6,8):(8,1)">,
                !cute.layout<"(?,?):(?,?)">) -> ...
      ```

    - nested tile tiler with an inner mode-1 dyn-stride

      ```mlir
      //        rank-2 layout. Diagnostic reports the mode path
      //        `[0, 1]` (outer mode 0, then inner mode 1) for the
      //        offending sub-component.
      %r = cute.flat_divide(%a, %b)
             : (!cute.layout<"(6,8):(8,1)">,
                !cute.tile<"[[3:1;(?,?):(?,?)];4:1]">) -> ...
      ```
  }];
  let arguments = (ins
    Cute_Arg<Cute_AnyLayoutType, "input layout">:$input,
    Cute_Arg<Cute_DividerType, "tiler">:$tiler
  );
  let results = (outs
    Cute_Arg<Cute_AnyLayoutType, "divided layout">:$result
  );
  let assemblyFormat = [{
    `(` operands `)` attr-dict `:` functional-type(operands, results)
  }];
}

//===----------------------------------------------------------------------===//
// TileToShapeOp
//===----------------------------------------------------------------------===//

def Cute_TileToShapeOp : Cute_Op<"tile_to_shape", [
    Pure,
    DeclareOpInterfaceMethods<InferTypeOpInterface>
]> {
  let cuteSpecGroup = "TilingPartitioningProducts";
  let summary = "Tile a block layout to match a target shape";
  let description = [{
    Tiles the block layout ``$input`` to cover the target ``$shape``. For
    each top-level mode ``i`` the per-axis replication factor is
    ``ceil(target_shape[i] / block_shape[i])``; non-divisible cases
    round up. The result groups the input axis with its replication
    count as a nested mode.

    When ``rank($input)`` is less than ``rank($shape)``, the block is
    padded on the inner side with shape-``1`` modes so each target
    mode has a counterpart. Strict equality is not required.

    The optional ``$order`` operand selects the order in which the
    target-shape modes are consumed when laying out the replicated
    block. When absent, the modes are tiled in natural
    (column-major) order — equivalent to passing ``(0,1,...,N-1)``.
    When present, ``$order`` must be a static ``!cute.int_tuple`` that
    is a permutation of ``[0, rank($shape))``: each of the indices
    ``0``, ``1``, …, ``rank($shape) - 1`` appears exactly once. The chosen
    permutation only affects the strides of the replication factors,
    not the result shape. For example, ``$order = (1,0,2)`` tiles
    mode 1 first, then mode 0, then mode 2 — useful for K-major vs
    MN-major layouts.

    **Preconditions**

    - ``$input`` is ``!cute.layout`` or ``!cute.composed_layout``.
    - ``$shape`` is ``!cute.shape``.
    - ``rank($shape) >= rank(shape($input))``.
    - When ``$order`` is present:

      - it is ``!cute.int_tuple`` with every leaf static, and
      - ``rank($order) == rank($shape)``, and
      - it is a permutation of ``[0, rank($shape))`` — every index in
        that half-open interval appears exactly once.

    **Postconditions**

    - ``$result`` has the same kind as ``$input``. For composed_layout
      input, the swizzle / layout-A and offset are preserved; the
      tiling applies to the ``B`` part.

    - ``$result`` has ``rank($shape)`` top-level modes, each grouping
      the (possibly padded) input axis with its per-axis replication
      factor ``ceil(target_shape[i] / block_shape[i])``.

    - ``size($result) >= product($shape)``, with equality iff every
      target mode is exactly divisible by its block mode.

    **Examples**

    ```mlir
    // Plain layout, no order, exact divisibility:
    // 6/3=2, 8/2=4 -> result has nested modes ((3,2),(2,4)).
    %r = cute.tile_to_shape(%input, %shape)
           : (!cute.layout<"(3,2):(1,3)">, !cute.shape<"(6,8)">)
          -> !cute.layout<"((3,2),(2,4)):((1,6),(3,12))">

    // Rounded-up: target 5/3 -> 2, 8/3 -> 3. Result is a valid
    // covering tiling that overshoots the target by one block on
    // each axis.
    %r = cute.tile_to_shape(%input, %shape)
           : (!cute.layout<"(3,3):(1,3)">, !cute.shape<"(5,8)">)
          -> !cute.layout<"((3,2),(3,3)):((1,9),(3,18))">

    // Composed-layout input — A/offset preserved; tiling applies to B.
    %r = cute.tile_to_shape(%input, %shape)
           : (!cute.composed_layout<"S<3,4,3> o 0 o (3,2):(1,3)">,
              !cute.shape<"(6,8)">)
          -> !cute.composed_layout<"S<3,4,3> o 0 o ((3,2),(2,4)):((1,6),(3,12))">

    // Explicit order (0,1) — natural/column-major; result equals the
    // no-order form above (when shapes/strides match).
    %r = cute.tile_to_shape(%input, %shape, %order)
           : (!cute.layout<"(128,128):(128,1)">,
              !cute.shape<"(1024,512)">,
              !cute.int_tuple<"(0,1)">)
          -> !cute.layout<"((128,8),(128,4)):((128,16384),(1,131072))">

    // Swapped order (1,0) — tile mode 1 first, then mode 0. Same
    // shape as the natural case, but the replication strides differ.
    %r = cute.tile_to_shape(%input, %shape, %order)
           : (!cute.layout<"(128,128):(128,1)">,
              !cute.shape<"(1024,512)">,
              !cute.int_tuple<"(1,0)">)
          -> !cute.layout<"((128,8),(128,4)):((128,65536),(1,16384))">
    ```

    **Errors**

    - ``$input`` and ``$result`` have different kinds.
    - ``rank($shape) < rank(shape($input))``.
    - When ``$order`` is present:

      - it is not static,
      - ``rank($order) != rank($shape)``, or
      - it is not a permutation of ``[0, rank($shape))`` — duplicate
        indices, out-of-range indices, or any form of non-zero-based
        indexing all fail.

    - ``$result`` per-axis nesting does not match ``(input_axis, Rk)``.
    - ``size($result) < product($shape)``.
  }];
  let arguments = (ins
    Cute_Arg<Cute_AnyLayoutType, "block layout to tile">:$input,
    Cute_Arg<Cute_ShapeType, "target shape">:$shape,
    Cute_Arg<Optional<Cute_IntTupleType>, "tiling order (optional)">:$order
  );
  let results = (outs
    Cute_Arg<Cute_AnyLayoutType, "tiled layout">:$result
  );
  let assemblyFormat = [{
    `(` $input `,` $shape (`,` $order^)? `)` attr-dict `:`
    functional-type(operands, results)
  }];
}

#endif // CUTE_IR_DIALECT_CUTE_IR_CUTE_OPS_TD
