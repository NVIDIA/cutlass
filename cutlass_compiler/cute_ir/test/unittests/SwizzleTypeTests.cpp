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

static cutegen::swizzle mkSwizzle(const char *s) {
  return cutegen::from_string<cutegen::swizzle>(s).value();
}

// ---- SwizzleAttr ------------------------------------------------------------

TEST_F(CuteTest, SwizzleAttr_Uniquing) {
  auto a1 = SwizzleAttr::get(&ctx, mkSwizzle("S<3,5,4>"));
  auto a2 = SwizzleAttr::get(&ctx, mkSwizzle("S<3,5,4>"));
  EXPECT_EQ(a1, a2);
}

// ---- SwizzleType ------------------------------------------------------------

TEST_F(CuteTest, SwizzleType_Identity) {
  auto ty = SwizzleType::get(&ctx, mkSwizzle("S<0,4,3>"));
  EXPECT_TRUE(ty.isStatic());
  EXPECT_EQ(ty.getRef(), mkSwizzle("S<0,4,3>"));
}

TEST_F(CuteTest, SwizzleType_NonIdentity) {
  auto ty = SwizzleType::get(&ctx, mkSwizzle("S<3,5,4>"));
  EXPECT_TRUE(ty.isStatic());
}

TEST_F(CuteTest, SwizzleType_NegativeShift) {
  // Negative shift values are valid swizzle parameters.
  auto ty = SwizzleType::get(&ctx, mkSwizzle("S<2,0,-3>"));
  EXPECT_TRUE(ty.isStatic());
}

TEST_F(CuteTest, SwizzleType_Uniquing_Same) {
  auto t1 = SwizzleType::get(&ctx, mkSwizzle("S<3,5,4>"));
  auto t2 = SwizzleType::get(&ctx, mkSwizzle("S<3,5,4>"));
  EXPECT_EQ(t1, t2);
}

TEST_F(CuteTest, SwizzleType_Uniquing_Different) {
  auto t1 = SwizzleType::get(&ctx, mkSwizzle("S<3,5,4>"));
  auto t2 = SwizzleType::get(&ctx, mkSwizzle("S<1,0,2>"));
  EXPECT_NE(t1, t2);
}

TEST_F(CuteTest, SwizzleType_AttrMatchesRef) {
  auto val = mkSwizzle("S<3,5,4>");
  auto ty = SwizzleType::get(&ctx, val);
  EXPECT_EQ(ty.getRef(), ty.getAttr().getRef());
}
