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

static cutegen::coord mkCoord(const char *s) {
  return cutegen::from_string<cutegen::coord>(s).value();
}

// ---- CoordAttr
// ---------------------------------------------------------------

TEST_F(CuteTest, CoordAttr_Uniquing) {
  auto a1 = CoordAttr::get(&ctx, mkCoord("(1,2)"));
  auto a2 = CoordAttr::get(&ctx, mkCoord("(1,2)"));
  EXPECT_EQ(a1, a2);
}

// ---- CoordType
// ---------------------------------------------------------------

TEST_F(CuteTest, CoordType_ScalarStatic) {
  auto ty = CoordType::get(&ctx, mkCoord("42"));
  EXPECT_TRUE(ty.isStatic());
  EXPECT_EQ(ty.getRef(), mkCoord("42"));
}

TEST_F(CuteTest, CoordType_ScalarDynamic) {
  auto ty = CoordType::get(&ctx, mkCoord("?"));
  EXPECT_FALSE(ty.isStatic());
}

TEST_F(CuteTest, CoordType_Underscore) {
  // Underscore is a compile-time constant — cutegen::is_static returns true.
  auto ty = CoordType::get(&ctx, mkCoord("_"));
  EXPECT_TRUE(ty.isStatic());
}

TEST_F(CuteTest, CoordType_Depth1_Static) {
  auto ty = CoordType::get(&ctx, mkCoord("(1,2)"));
  EXPECT_TRUE(ty.isStatic());
}

TEST_F(CuteTest, CoordType_Depth1_WithUnderscore) {
  // Not static because of the dynamic element, not the underscore.
  auto ty = CoordType::get(&ctx, mkCoord("(_,?)"));
  EXPECT_FALSE(ty.isStatic());
}

TEST_F(CuteTest, CoordType_Depth1_AllUnderscore) {
  // All underscores — every leaf is a compile-time constant.
  auto ty = CoordType::get(&ctx, mkCoord("(_,_,_)"));
  EXPECT_TRUE(ty.isStatic());
}

TEST_F(CuteTest, CoordType_Depth2_Static) {
  auto ty = CoordType::get(&ctx, mkCoord("(1,(2,3))"));
  EXPECT_TRUE(ty.isStatic());
}

TEST_F(CuteTest, CoordType_Uniquing_Same) {
  auto t1 = CoordType::get(&ctx, mkCoord("(_,?)"));
  auto t2 = CoordType::get(&ctx, mkCoord("(_,?)"));
  EXPECT_EQ(t1, t2);
}

TEST_F(CuteTest, CoordType_Uniquing_Different) {
  auto t1 = CoordType::get(&ctx, mkCoord("(1,2)"));
  auto t2 = CoordType::get(&ctx, mkCoord("(1,3)"));
  EXPECT_NE(t1, t2);
}

TEST_F(CuteTest, CoordType_AttrMatchesRef) {
  auto val = mkCoord("(_,?,1)");
  auto ty = CoordType::get(&ctx, val);
  EXPECT_EQ(ty.getRef(), ty.getAttr().getRef());
}
