//===- CuteTypeInterfaces.td - Cute type interface definitions -*-tablegen-*-===//
//
//
//===----------------------------------------------------------------------===//

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

#ifndef CUTE_IR_DIALECT_CUTE_IR_CUTE_TYPE_INTERFACES_TD
#define CUTE_IR_DIALECT_CUTE_IR_CUTE_TYPE_INTERFACES_TD

include "mlir/IR/OpBase.td"
include "cute_ir/Dialect/Cute/IR/CuteDialect.td"

//===----------------------------------------------------------------------===//
// MaybeStaticTypeInterface
//===----------------------------------------------------------------------===//

def Cute_MaybeStaticTypeInterface
    : Cute_TypeInterface<"MaybeStaticTypeInterface"> {
  let summary = "Type interface for CuTe types that may be fully static";
  let description = [{
    Implemented by all CuTe algebra types. Returns true when every
    dimension of the type is a compile-time constant (no dynamic extents
    or strides). Used by ``CuteFoldStatic`` to identify ops whose results
    can be folded to ``cute.static`` at compile time.

    Also exposes ``getValueAttr()`` — a non-null ``Attribute`` representation
    of the type's compile-time value. This is what ``cute.static`` (a
    ``ConstantLike`` op) returns from its ``fold`` method, satisfying MLIR's
    contract that every ``ConstantLike`` op be foldable into an attribute.
    For the attr-backed algebra types the underlying type-parameter
    attribute (e.g. ``ShapeAttr``, ``LayoutAttr``) serves as the value
    attribute.
  }];

  let methods = [
    InterfaceMethod<
      "Returns true if this type is fully static (no dynamic dimensions).",
      "bool", "isStatic">,
    InterfaceMethod<
      [{Returns a non-null `Attribute` representation of this type's
        compile-time value, suitable as a `ConstantLike` fold result.}],
      "::mlir::Attribute", "getValueAttr">
  ];
}

#endif // CUTE_IR_DIALECT_CUTE_IR_CUTE_TYPE_INTERFACES_TD
