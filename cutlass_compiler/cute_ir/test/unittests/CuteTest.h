//===- CuteTest.h - Fixture for Cute dialect unit tests ---------*- C++ -*-===//
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

#pragma once

#include "cute_ir/Dialect/Cute/IR/CuteDialect.h"
#include "cute_ir/Registration/Registration.h"

#include "mlir/IR/BuiltinTypes.h"
#include "mlir/IR/MLIRContext.h"

#include <gtest/gtest.h>

namespace mlir::cutlass_compiler::cute::test {

/// Base fixture for Cute dialect C++ unit tests.
///
/// Provides an MLIRContext with all Cute-dependent dialects loaded and a set
/// of pre-built integer types so individual tests do not repeat boilerplate.
class CuteTest : public ::testing::Test {
protected:
  void SetUp() override {
    mlir::DialectRegistry registry;
    registerCuteDialects(registry);
    ctx.appendDialectRegistry(registry);
    ctx.loadAllAvailableDialects();

    i8Ty = mlir::IntegerType::get(&ctx, 8);
    i16Ty = mlir::IntegerType::get(&ctx, 16);
    i32Ty = mlir::IntegerType::get(&ctx, 32);
    i64Ty = mlir::IntegerType::get(&ctx, 64);
    si32Ty = mlir::IntegerType::get(&ctx, 32, mlir::IntegerType::Signed);
    ui32Ty = mlir::IntegerType::get(&ctx, 32, mlir::IntegerType::Unsigned);
  }

  mlir::MLIRContext ctx;

  mlir::IntegerType i8Ty;
  mlir::IntegerType i16Ty;
  mlir::IntegerType i32Ty;  ///< signless i32
  mlir::IntegerType i64Ty;  ///< signless i64
  mlir::IntegerType si32Ty; ///< si32 (signed)
  mlir::IntegerType ui32Ty; ///< ui32 (unsigned)
};

} // namespace mlir::cutlass_compiler::cute::test
