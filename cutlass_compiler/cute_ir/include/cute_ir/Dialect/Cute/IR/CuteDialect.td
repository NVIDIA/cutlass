//===- CuteDialect.td - Cute dialect definition -------------*- tablegen -*-===//
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

#ifndef CUTE_IR_DIALECT_CUTE_IR_CUTE_DIALECT_TD
#define CUTE_IR_DIALECT_CUTE_IR_CUTE_DIALECT_TD

include "mlir/IR/DialectBase.td"
include "mlir/IR/OpBase.td"

//===----------------------------------------------------------------------===//
// Cute dialect
//===----------------------------------------------------------------------===//

def Cute_Dialect : Dialect {
  let summary = "Cute dialect for CuTe layout algebra";

  let description = [{
    The ``cute`` dialect models CuTe-style layout algebra types and operations
    for the cutlass_compiler stack.  It provides the
    layout types (IntTuple, Coord, Shape, Stride, Tile, Layout,
    ComposedLayout, Swizzle), constructor and accessor ops, layout algebra
    ops, and tiling/partitioning ops that lower to the ``base`` dialect set.
  }];

  let name = "cute";
  let cppNamespace = "::mlir::cutlass_compiler::cute";

  let dependentDialects = ["arith::ArithDialect"];

  let useDefaultAttributePrinterParser = 1;
  let useDefaultTypePrinterParser = 1;

  let extraClassDeclaration = [{
    /// Registers all Cute attribute classes with the dialect.
    static void registerCuteAttributes(CuteDialect *dialect);
    /// Registers all Cute type classes with the dialect.
    static void registerCuteTypes(CuteDialect *dialect);
  }];
}

//===----------------------------------------------------------------------===//
// ODS base classes — used by every op, type, attribute, and interface in the
// Cute dialect.  All base classes are defined here so they are available
// across every .td file that includes CuteDialect.td.
//

// Naming convention — all defs use the "Cute_" dialect prefix; the tablegen
// generator strips "Cute_" to produce the C++ class name:
//

//   Ops:             def Cute_StaticOp : Cute_Op<"static">                → C++ StaticOp
//   Types:           def Cute_LayoutType : Cute_Type<"Layout", "layout">  → C++ LayoutType
//   Attrs:           def Cute_IntTupleAttr : Cute_Attr<"IntTuple", ...>   → C++ IntTupleAttr
//   Type interfaces: def Cute_MaybeStaticTypeInterface : Cute_TypeInterface<"MaybeStaticTypeInterface">
//                                                                     → C++ MaybeStaticTypeInterface
//

// All generated classes live in namespace ::mlir::cutlass_compiler::cute.
//===----------------------------------------------------------------------===//

/// Base class for all Cute dialect ops.
class Cute_Op<string mnemonic, list<Trait> traits = []> :
    Op<Cute_Dialect, mnemonic, traits> {
  /// Spec section this op belongs to (e.g. "Constructor", "Arithmetic",
  /// "LayoutAlgebra").
  string cuteSpecGroup = "";
}

/// Wraps an op operand or result with a type constraint and a documentation
/// string.  Used in Op arguments / results dags.
class Cute_Arg<Constraint constraint, string desc> : Arg<constraint, desc>;

/// Wraps a TypeDef parameter with a C++ type string and a documentation
/// string.  Pass a non-empty default for parameters with a C++ default.
///   Cute_Param<"mlir::IntegerType", "wrapped integer type">:$subtype
class Cute_Param<string cppType, string desc, string default = "">
    : TypeParameter<cppType, desc> {
  string defaultValue = default;
}

/// Wraps a TypeDef parameter that has a default value of cppType().
/// The accessor returns cppType directly (not std::optional<cppType>).
///   Cute_OptionalParam<"mlir::IntegerType::SignednessSemantics",
///                      "signedness; Signless when absent">:$sign
class Cute_OptionalParam<string cppType, string desc>
    : OptionalParameter<cppType, desc>;

/// Base class for all Cute dialect types.
///   def Cute_LayoutType : Cute_Type<"Layout", "layout"> {}  →  C++ LayoutType
class Cute_Type<string name, string typeMnemonic, list<Trait> traits = []>
    : TypeDef<Cute_Dialect, name, traits> {
  let mnemonic = typeMnemonic;
}

/// Base class for all Cute dialect attributes.
///   def Cute_IntTupleAttr : Cute_Attr<"IntTuple", "int_tuple"> {}  →  C++ IntTupleAttr
class Cute_Attr<string name, string attrMnemonic, list<Trait> traits = []>
    : AttrDef<Cute_Dialect, name, traits> {
  let mnemonic = attrMnemonic;
}

/// Base class for all Cute dialect type interfaces.
///   def Cute_MaybeStaticTypeInterface : Cute_TypeInterface<"MaybeStaticTypeInterface"> {}
///                                                        →  C++ MaybeStaticTypeInterface
class Cute_TypeInterface<string name, list<TypeInterface> interfaces = []>
    : TypeInterface<name, interfaces> {
  let cppNamespace = "::mlir::cutlass_compiler::cute";
}

/// Base class for all Cute dialect op interfaces.
class Cute_OpInterface<string name, list<OpInterface> interfaces = []>
    : OpInterface<name, interfaces> {
  let cppNamespace = "::mlir::cutlass_compiler::cute";
}

/// Base class for all Cute dialect attribute interfaces.
class Cute_AttrInterface<string name, list<AttrInterface> interfaces = []>
    : AttrInterface<name, interfaces> {
  let cppNamespace = "::mlir::cutlass_compiler::cute";
}

#endif // CUTE_IR_DIALECT_CUTE_IR_CUTE_DIALECT_TD
