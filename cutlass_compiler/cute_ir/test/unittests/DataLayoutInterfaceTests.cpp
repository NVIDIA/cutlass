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

#include "cute_ir/Dialect/Cute/IR/CuteDialect.h"

#include "mlir/Dialect/LLVMIR/LLVMTypes.h"
#include "mlir/IR/Builders.h"
#include "mlir/Interfaces/DataLayoutInterfaces.h"

#include "CuteTest.h"

using namespace mlir;
using namespace mlir::cutlass_compiler::cute;
using namespace mlir::cutlass_compiler::cute::test;

/// A fully static int_tuple lowers to an empty LLVM struct, so it is
/// zero-sized.
TEST_F(CuteTest, DataLayout_IntTupleStatic_ZeroSizedStruct) {
  DataLayout dl;
  auto ty = IntTupleType::get(
      &ctx, cutegen::from_string<cutegen::int_tuple>("(1,2)").value());
  EXPECT_EQ(ty.getTypeSize(dl, {}), llvm::TypeSize::getFixed(0));
  EXPECT_EQ(ty.getTypeSizeInBits(dl, {}), llvm::TypeSize::getFixed(0));
}

/// A scalar dynamic int_tuple lowers to a *bare integer* (not a struct). That
/// integer does not implement DataLayoutTypeInterface, so areCompatible /
/// verifyEntries must fall back to their defaults instead of crashing, while
/// the size / alignment queries still delegate to the integer.
TEST_F(CuteTest, DataLayout_IntTupleScalarDynamic_BareInteger) {
  DataLayout dl;
  OpBuilder builder(&ctx);
  auto ty = IntTupleType::get(
      &ctx, cutegen::from_string<cutegen::int_tuple>("?").value());

  Type lowered = cutegen::get_llvm_type(builder, ty.getRef());
  // Precondition for what this test is covering: the lowering really is a
  // bare integer rather than an aggregate.
  ASSERT_TRUE(isa<IntegerType>(lowered));

  EXPECT_EQ(ty.getTypeSize(dl, {}), dl.getTypeSize(lowered));
  EXPECT_EQ(ty.getTypeSizeInBits(dl, {}), dl.getTypeSizeInBits(lowered));
  EXPECT_EQ(ty.getABIAlignment(dl, {}), dl.getTypeABIAlignment(lowered));
  EXPECT_EQ(ty.getPreferredAlignment(dl, {}),
            dl.getTypePreferredAlignment(lowered));

  // Bare-integer path: no interface to delegate to -> safe defaults.
  DataLayoutIdentifiedEntryMap identified;
  EXPECT_TRUE(ty.areCompatible({}, {}, DataLayoutSpecInterface{}, identified));
  EXPECT_TRUE(succeeded(ty.verifyEntries({}, UnknownLoc::get(&ctx))));
}

/// A layout with a dynamic leaf lowers to an aggregate LLVM struct; the size
/// and alignment queries must match a direct query on that lowered struct.
TEST_F(CuteTest, DataLayout_Layout_MatchesLoweredStruct) {
  DataLayout dl;
  OpBuilder builder(&ctx);
  auto ty = LayoutType::get(
      &ctx, cutegen::from_string<cutegen::layout>("(?,3):(1,2)").value());

  Type lowered = cutegen::get_llvm_type(builder, ty.getRef());
  ASSERT_TRUE(isa<LLVM::LLVMStructType>(lowered));

  EXPECT_EQ(ty.getTypeSize(dl, {}), dl.getTypeSize(lowered));
  EXPECT_EQ(ty.getTypeSizeInBits(dl, {}), dl.getTypeSizeInBits(lowered));
  EXPECT_EQ(ty.getABIAlignment(dl, {}), dl.getTypeABIAlignment(lowered));
  EXPECT_EQ(ty.getPreferredAlignment(dl, {}),
            dl.getTypePreferredAlignment(lowered));
}

/// A coord with multiple dynamic leaves lowers to an aggregate LLVM struct
/// (the `_` wildcard is compile-time and contributes no field, and a single
/// dynamic leaf would collapse to a bare integer); the size and alignment
/// queries must match a direct query on that lowered struct.
TEST_F(CuteTest, DataLayout_Coord_MatchesLoweredStruct) {
  DataLayout dl;
  OpBuilder builder(&ctx);
  auto ty = CoordType::get(
      &ctx, cutegen::from_string<cutegen::coord>("(_,?,?)").value());

  Type lowered = cutegen::get_llvm_type(builder, ty.getRef());
  ASSERT_TRUE(isa<LLVM::LLVMStructType>(lowered));

  EXPECT_EQ(ty.getTypeSize(dl, {}), dl.getTypeSize(lowered));
  EXPECT_EQ(ty.getTypeSizeInBits(dl, {}), dl.getTypeSizeInBits(lowered));
  EXPECT_EQ(ty.getABIAlignment(dl, {}), dl.getTypeABIAlignment(lowered));
  EXPECT_EQ(ty.getPreferredAlignment(dl, {}),
            dl.getTypePreferredAlignment(lowered));
}

/// A shape with multiple dynamic leaves lowers to an aggregate LLVM struct (a
/// single dynamic leaf would collapse to a bare integer); the size and
/// alignment queries must match a direct query on that lowered struct.
TEST_F(CuteTest, DataLayout_Shape_MatchesLoweredStruct) {
  DataLayout dl;
  OpBuilder builder(&ctx);
  auto ty = ShapeType::get(
      &ctx, cutegen::from_string<cutegen::shape>("(?,?)").value());

  Type lowered = cutegen::get_llvm_type(builder, ty.getRef());
  ASSERT_TRUE(isa<LLVM::LLVMStructType>(lowered));

  EXPECT_EQ(ty.getTypeSize(dl, {}), dl.getTypeSize(lowered));
  EXPECT_EQ(ty.getTypeSizeInBits(dl, {}), dl.getTypeSizeInBits(lowered));
  EXPECT_EQ(ty.getABIAlignment(dl, {}), dl.getTypeABIAlignment(lowered));
  EXPECT_EQ(ty.getPreferredAlignment(dl, {}),
            dl.getTypePreferredAlignment(lowered));
}

/// A stride with multiple dynamic leaves lowers to an aggregate LLVM struct (a
/// single dynamic leaf would collapse to a bare integer); the size and
/// alignment queries must match a direct query on that lowered struct.
TEST_F(CuteTest, DataLayout_Stride_MatchesLoweredStruct) {
  DataLayout dl;
  OpBuilder builder(&ctx);
  auto ty = StrideType::get(
      &ctx, cutegen::from_string<cutegen::stride>("(?,?)").value());

  Type lowered = cutegen::get_llvm_type(builder, ty.getRef());
  ASSERT_TRUE(isa<LLVM::LLVMStructType>(lowered));

  EXPECT_EQ(ty.getTypeSize(dl, {}), dl.getTypeSize(lowered));
  EXPECT_EQ(ty.getTypeSizeInBits(dl, {}), dl.getTypeSizeInBits(lowered));
  EXPECT_EQ(ty.getABIAlignment(dl, {}), dl.getTypeABIAlignment(lowered));
  EXPECT_EQ(ty.getPreferredAlignment(dl, {}),
            dl.getTypePreferredAlignment(lowered));
}

/// A tile holding a layout with a dynamic leaf lowers to an aggregate LLVM
/// struct; the size and alignment queries must match a direct query on that
/// lowered struct.
TEST_F(CuteTest, DataLayout_Tile_MatchesLoweredStruct) {
  DataLayout dl;
  OpBuilder builder(&ctx);
  auto ty = TileType::get(
      &ctx, cutegen::from_string<cutegen::tile>("[(?,3):(1,2)]").value());

  Type lowered = cutegen::get_llvm_type(builder, ty.getRef());
  ASSERT_TRUE(isa<LLVM::LLVMStructType>(lowered));

  EXPECT_EQ(ty.getTypeSize(dl, {}), dl.getTypeSize(lowered));
  EXPECT_EQ(ty.getTypeSizeInBits(dl, {}), dl.getTypeSizeInBits(lowered));
  EXPECT_EQ(ty.getABIAlignment(dl, {}), dl.getTypeABIAlignment(lowered));
  EXPECT_EQ(ty.getPreferredAlignment(dl, {}),
            dl.getTypePreferredAlignment(lowered));
}

/// A composed layout with a dynamic leaf in its base layout lowers to an
/// aggregate LLVM struct; the size and alignment queries must match a direct
/// query on that lowered struct.
TEST_F(CuteTest, DataLayout_ComposedLayout_MatchesLoweredStruct) {
  DataLayout dl;
  OpBuilder builder(&ctx);
  auto ty = ComposedLayoutType::get(
      &ctx, cutegen::from_string<cutegen::composed_layout>(
                "(4,5):(1,4) o 2 o (?,3):(1,2)")
                .value());

  Type lowered = cutegen::get_llvm_type(builder, ty.getRef());
  ASSERT_TRUE(isa<LLVM::LLVMStructType>(lowered));

  EXPECT_EQ(ty.getTypeSize(dl, {}), dl.getTypeSize(lowered));
  EXPECT_EQ(ty.getTypeSizeInBits(dl, {}), dl.getTypeSizeInBits(lowered));
  EXPECT_EQ(ty.getABIAlignment(dl, {}), dl.getTypeABIAlignment(lowered));
  EXPECT_EQ(ty.getPreferredAlignment(dl, {}),
            dl.getTypePreferredAlignment(lowered));
}

/// A swizzle is compile-time only; its runtime representation is an empty LLVM
/// struct (mirroring convertSwizzleType), so it is zero-sized and its
/// collection queries return the defaults.
TEST_F(CuteTest, DataLayout_Swizzle_ZeroSizedStruct) {
  DataLayout dl;
  auto ty = SwizzleType::get(
      &ctx, cutegen::from_string<cutegen::swizzle>("S<3,5,4>").value());
  EXPECT_EQ(ty.getTypeSize(dl, {}), llvm::TypeSize::getFixed(0));
  EXPECT_EQ(ty.getTypeSizeInBits(dl, {}), llvm::TypeSize::getFixed(0));

  DataLayoutIdentifiedEntryMap identified;
  EXPECT_TRUE(ty.areCompatible({}, {}, DataLayoutSpecInterface{}, identified));
  EXPECT_TRUE(succeeded(ty.verifyEntries({}, UnknownLoc::get(&ctx))));
}
