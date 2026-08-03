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

static cutegen::composed_layout mkComposed(const char *s) {
  return cutegen::from_string<cutegen::composed_layout>(s).value();
}

// ---- ComposedLayoutAttr -----------------------------------------------------

TEST_F(CuteTest, ComposedLayoutAttr_Uniquing) {
  auto a1 = ComposedLayoutAttr::get(
      &ctx, mkComposed("(4,5):(1,4) o 2 o (2,3):(1,2)"));
  auto a2 = ComposedLayoutAttr::get(
      &ctx, mkComposed("(4,5):(1,4) o 2 o (2,3):(1,2)"));
  EXPECT_EQ(a1, a2);
}

// ---- ComposedLayoutType -----------------------------------------------------

TEST_F(CuteTest, ComposedLayoutType_StaticLayoutA) {
  auto ty = ComposedLayoutType::get(
      &ctx, mkComposed("(4,5):(1,4) o 2 o (2,3):(1,2)"));
  EXPECT_TRUE(ty.isStatic());
  EXPECT_EQ(ty.getRef(), mkComposed("(4,5):(1,4) o 2 o (2,3):(1,2)"));
}

TEST_F(CuteTest, ComposedLayoutType_StaticSwizzleA) {
  auto ty =
      ComposedLayoutType::get(&ctx, mkComposed("S<3,5,4> o 2 o (2,3):(1,2)"));
  EXPECT_TRUE(ty.isStatic());
}

TEST_F(CuteTest, ComposedLayoutType_ZeroOffset) {
  auto ty =
      ComposedLayoutType::get(&ctx, mkComposed("S<3,5,4> o 0 o (8,4):(1,8)"));
  EXPECT_TRUE(ty.isStatic());
}

TEST_F(CuteTest, ComposedLayoutType_TupleOffset) {
  auto ty = ComposedLayoutType::get(
      &ctx, mkComposed("(4,5):(1,4) o (0,0) o (2,3):(1@0,1@1)"));
  EXPECT_TRUE(ty.isStatic());
}

TEST_F(CuteTest, ComposedLayoutType_DynamicB) {
  auto ty =
      ComposedLayoutType::get(&ctx, mkComposed("S<3,5,4> o 0 o (?,3):(1,2)"));
  EXPECT_FALSE(ty.isStatic());
}

// Partial-dynamic combinations — pin each of the three is_static
// sub-checks (b_ok, off_ok, a_ok) in `ComposedLayoutType::isStatic`.

TEST_F(CuteTest, ComposedLayoutType_DynamicOffset) {
  // b_ok=true, off_ok=false, a_ok=true (affine static A).
  auto ty = ComposedLayoutType::get(
      &ctx, mkComposed("(4,5):(1,4) o ? o (2,3):(1,2)"));
  EXPECT_FALSE(ty.isStatic());
}

TEST_F(CuteTest, ComposedLayoutType_DynamicAffineA) {
  // b_ok=true, off_ok=true, a_ok=false (affine dynamic A).
  // Swizzle A is always static, so dyn-A is only meaningful for the
  // affine-A branch (`is_a_swizzle() || is_static(layout_a())`).
  auto ty = ComposedLayoutType::get(
      &ctx, mkComposed("(?,5):(1,?) o 2 o (2,3):(1,2)"));
  EXPECT_FALSE(ty.isStatic());
}

TEST_F(CuteTest, ComposedLayoutType_DynamicAffineB) {
  // b_ok=false, off_ok=true, a_ok=true (affine static A, dyn B).
  // Mirror of `DynamicB` but with an affine A instead of a swizzle —
  // exercises the affine-A path through `a_ok`.
  auto ty = ComposedLayoutType::get(
      &ctx, mkComposed("(4,5):(1,4) o 2 o (?,3):(1,2)"));
  EXPECT_FALSE(ty.isStatic());
}

TEST_F(CuteTest, ComposedLayoutType_Uniquing_Same) {
  auto t1 = ComposedLayoutType::get(
      &ctx, mkComposed("(4,5):(1,4) o 2 o (2,3):(1,2)"));
  auto t2 = ComposedLayoutType::get(
      &ctx, mkComposed("(4,5):(1,4) o 2 o (2,3):(1,2)"));
  EXPECT_EQ(t1, t2);
}

TEST_F(CuteTest, ComposedLayoutType_Uniquing_Different) {
  auto t1 = ComposedLayoutType::get(
      &ctx, mkComposed("(4,5):(1,4) o 2 o (2,3):(1,2)"));
  auto t2 =
      ComposedLayoutType::get(&ctx, mkComposed("S<3,5,4> o 2 o (2,3):(1,2)"));
  EXPECT_NE(t1, t2);
}

TEST_F(CuteTest, ComposedLayoutType_AttrMatchesRef) {
  auto val = mkComposed("S<3,5,4> o 0 o (?,3):(1,2)");
  auto ty = ComposedLayoutType::get(&ctx, val);
  EXPECT_EQ(ty.getRef(), ty.getAttr().getRef());
}
