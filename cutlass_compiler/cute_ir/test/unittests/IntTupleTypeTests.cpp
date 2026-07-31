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

#include "CuteTest.h"

using namespace mlir;
using namespace mlir::cutlass_compiler::cute;
using namespace mlir::cutlass_compiler::cute::test;

static cutegen::int_tuple mkTup(const char *s) {
  return cutegen::from_string<cutegen::int_tuple>(s).value();
}

//===----------------------------------------------------------------------===//
// IntTupleAttr — construction and accessors
//===----------------------------------------------------------------------===//

TEST_F(CuteTest, IntTupleAttr_Uniquing_SameValue) {
  auto a = IntTupleAttr::get(&ctx, mkTup("(1,2)"));
  auto b = IntTupleAttr::get(&ctx, mkTup("(1,2)"));
  EXPECT_EQ(a, b);
}

TEST_F(CuteTest, IntTupleAttr_Uniquing_DifferentValue) {
  auto a = IntTupleAttr::get(&ctx, mkTup("(1,2)"));
  auto b = IntTupleAttr::get(&ctx, mkTup("(1,3)"));
  EXPECT_NE(a, b);
}

//===----------------------------------------------------------------------===//
// IntTupleType — construction, isStatic, and uniquing
//===----------------------------------------------------------------------===//

TEST_F(CuteTest, IntTupleType_ScalarStatic_IsStatic) {
  auto ty = IntTupleType::get(&ctx, mkTup("1"));
  ASSERT_TRUE(ty);
  EXPECT_TRUE(ty.isStatic());
}

TEST_F(CuteTest, IntTupleType_ScalarDynamic_NotStatic) {
  auto ty = IntTupleType::get(&ctx, mkTup("?"));
  ASSERT_TRUE(ty);
  EXPECT_FALSE(ty.isStatic());
}

TEST_F(CuteTest, IntTupleType_Depth1_AllStatic) {
  auto ty = IntTupleType::get(&ctx, mkTup("(32,64)"));
  ASSERT_TRUE(ty);
  EXPECT_TRUE(ty.isStatic());
}

TEST_F(CuteTest, IntTupleType_Depth1_Mixed_NotStatic) {
  auto ty = IntTupleType::get(&ctx, mkTup("(?,32)"));
  ASSERT_TRUE(ty);
  EXPECT_FALSE(ty.isStatic());
}

TEST_F(CuteTest, IntTupleType_Depth2_Static) {
  auto ty = IntTupleType::get(&ctx, mkTup("(1,(2,3))"));
  ASSERT_TRUE(ty);
  EXPECT_TRUE(ty.isStatic());
}

TEST_F(CuteTest, IntTupleType_Depth2_DynamicLeaf_NotStatic) {
  auto ty = IntTupleType::get(&ctx, mkTup("(1,(?,3))"));
  ASSERT_TRUE(ty);
  EXPECT_FALSE(ty.isStatic());
}

TEST_F(CuteTest, IntTupleType_GetRef) {
  auto tup = mkTup("(4,8)");
  auto ty = IntTupleType::get(&ctx, tup);
  EXPECT_EQ(cutegen::to_string(ty.getRef()), cutegen::to_string(tup));
}

TEST_F(CuteTest, IntTupleType_Uniquing_SameValue) {
  auto a = IntTupleType::get(&ctx, mkTup("(1,2)"));
  auto b = IntTupleType::get(&ctx, mkTup("(1,2)"));
  EXPECT_EQ(a, b);
}

TEST_F(CuteTest, IntTupleType_Uniquing_DifferentValue) {
  auto a = IntTupleType::get(&ctx, mkTup("(1,2)"));
  auto b = IntTupleType::get(&ctx, mkTup("(1,3)"));
  EXPECT_NE(a, b);
}
