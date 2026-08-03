// clang-format off
/***************************************************************************************************
 * Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this
 * list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 **************************************************************************************************/
// clang-format on

//===----------------------------------------------------------------------===//
//

// Cute-to-base type converter. Maps each cute type to its LLVM struct
// lowering via cutegen's cg::get_llvm_type (which uses the sparse_flat
// representation: only dynamic leaves materialize as struct fields).
//

//===----------------------------------------------------------------------===//

#include "cute_ir/Conversion/CuteToBase/CuteTypeConverter.h"

#include "cute_ir/Dialect/Cute/IR/CuteDialect.h"

#include "cutegen/cutegen_mlir.hpp"

#include "mlir/Dialect/LLVMIR/LLVMTypes.h"
#include "mlir/IR/Builders.h"
#include "mlir/Transforms/DialectConversion.h"

namespace cg = cutegen;

namespace mlir::cutlass_compiler::cute {

namespace {

/// Helper for the rec-var-backed cute types (shape, stride, int_tuple,
/// coord, tile). Defers to cutegen's sparse_flat LLVM layout — for a fully
/// static type the result is LLVM struct() (empty); each dynamic leaf
/// adds its integer field.
template <typename T>
std::optional<Type> convertRecvarType(T orig) {
  OpBuilder builder(orig.getContext());
  return cg::get_llvm_type(builder, orig.getRef());
}

std::optional<Type> convertLayoutType(LayoutType orig) {
  OpBuilder builder(orig.getContext());
  return cg::get_llvm_type(builder, orig.getRef());
}

std::optional<Type> convertComposedLayoutType(ComposedLayoutType orig) {
  OpBuilder builder(orig.getContext());
  return cg::get_llvm_type(builder, orig.getRef());
}

/// Swizzle is a compile-time-only object — its parameters live in the type
/// signature only, so the runtime representation is an empty struct.
std::optional<Type> convertSwizzleType(SwizzleType orig) {
  return LLVM::LLVMStructType::getLiteral(orig.getContext(),
                                          SmallVector<Type>{});
}

} // namespace

void configCuteToBaseTypeConverter(TypeConverter &converter) {
  // Pass-through fallback first so non-cute types flow through unchanged
  // (e.g. i32, f32, MLIR builtin types). Registering this BEFORE the
  // cute-specific conversions matters: TypeConverter walks registered
  // conversions in reverse order, so cute conversions take precedence.
  // Without this, isSignatureLegal rejects any function whose arg/result
  // types contain non-cute types (i32 args, memref returns, ...).
  converter.addConversion([](Type ty) { return ty; });

  converter.addConversion(convertRecvarType<ShapeType>);
  converter.addConversion(convertRecvarType<StrideType>);
  converter.addConversion(convertRecvarType<IntTupleType>);
  converter.addConversion(convertRecvarType<CoordType>);
  converter.addConversion(convertRecvarType<TileType>);
  converter.addConversion(convertLayoutType);
  converter.addConversion(convertComposedLayoutType);
  converter.addConversion(convertSwizzleType);

  // Source / target materializers emit same-type
  // unrealized_conversion_cast ops at conversion boundaries (notably
  // function arguments and returns) when cute types persist across the
  // boundary. Downstream reconcile-unrealized-casts cleans them up.
  auto materialize = [](OpBuilder &b, Type resultType, ValueRange inputs,
                        Location loc) -> Value {
    return UnrealizedConversionCastOp::create(b, loc, resultType, inputs)
        .getResult(0);
  };
  converter.addSourceMaterialization(materialize);
  converter.addTargetMaterialization(materialize);
}

} // namespace mlir::cutlass_compiler::cute
