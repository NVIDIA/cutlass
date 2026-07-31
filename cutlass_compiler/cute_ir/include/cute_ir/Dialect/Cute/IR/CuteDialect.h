//===- CuteDialect.h - Cute dialect declaration -----------------*- C++ -*-===//
//
//
//===----------------------------------------------------------------------===//

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

#ifndef CUTE_IR_DIALECT_CUTE_IR_CUTE_DIALECT_H
#define CUTE_IR_DIALECT_CUTE_IR_CUTE_DIALECT_H

#include "cutegen/cutegen_mlir.hpp"

#include "mlir/IR/BuiltinTypes.h"
#include "mlir/IR/DialectImplementation.h"
#include "mlir/IR/OpImplementation.h"
#include "mlir/Interfaces/DataLayoutInterfaces.h"
#include "mlir/Interfaces/InferTypeOpInterface.h"
#include "mlir/Interfaces/SideEffectInterfaces.h"

// Forward-declare custom attribute storage classes (genStorageClass = 0).
namespace mlir::cutlass_compiler::cute::detail {
struct IntTupleAttrStorage;
struct CoordAttrStorage;
struct ShapeAttrStorage;
struct StrideAttrStorage;
struct LayoutAttrStorage;
struct TileAttrStorage;
struct ComposedLayoutAttrStorage;
struct SwizzleAttrStorage;
} // namespace mlir::cutlass_compiler::cute::detail

// TableGen-generated dialect declaration.
#include "cute_ir/Dialect/Cute/IR/CuteDialect.h.inc"

// TableGen-generated attribute class declarations.
#define GET_ATTRDEF_CLASSES
#include "cute_ir/Dialect/Cute/IR/CuteAttrs.h.inc"

// TableGen-generated type interface declarations.
#include "cute_ir/Dialect/Cute/IR/CuteTypeInterfaces.h.inc"

// TableGen-generated type class declarations.
#define GET_TYPEDEF_CLASSES
#include "cute_ir/Dialect/Cute/IR/CuteTypes.h.inc"

// TableGen-generated op class declarations.
#define GET_OP_CLASSES
#include "cute_ir/Dialect/Cute/IR/CuteOps.h.inc"

#endif // CUTE_IR_DIALECT_CUTE_IR_CUTE_DIALECT_H
