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

static cutegen::stride mkStride(const char *s) {
  return cutegen::from_string<cutegen::stride>(s).value();
}

// ---- StrideAttr
// --------------------------------------------------------------

TEST_F(CuteTest, StrideAttr_Uniquing) {
  auto a1 = StrideAttr::get(&ctx, mkStride("(16,32)"));
  auto a2 = StrideAttr::get(&ctx, mkStride("(16,32)"));
  EXPECT_EQ(a1, a2);
}

// ---- StrideType
// --------------------------------------------------------------

TEST_F(CuteTest, StrideType_ScalarStatic) {
  auto ty = StrideType::get(&ctx, mkStride("1"));
  EXPECT_TRUE(ty.isStatic());
  EXPECT_EQ(ty.getRef(), mkStride("1"));
}

TEST_F(CuteTest, StrideType_ScalarDynamic) {
  auto ty = StrideType::get(&ctx, mkStride("?"));
  EXPECT_FALSE(ty.isStatic());
}

TEST_F(CuteTest, StrideType_ScaledBasis_Static) {
  // A static scaled basis (e.g. 4@0) is static — no dynamic parts.
  auto ty = StrideType::get(&ctx, mkStride("4@0"));
  EXPECT_TRUE(ty.isStatic());
}

TEST_F(CuteTest, StrideType_ScaledBasis_Dynamic) {
  // A dynamic scaled basis (e.g. ?@0) is not static.
  auto ty = StrideType::get(&ctx, mkStride("?@0"));
  EXPECT_FALSE(ty.isStatic());
}

TEST_F(CuteTest, StrideType_Depth1_Static) {
  auto ty = StrideType::get(&ctx, mkStride("(16,32)"));
  EXPECT_TRUE(ty.isStatic());
}

TEST_F(CuteTest, StrideType_Depth1_Mixed) {
  auto ty = StrideType::get(&ctx, mkStride("(16,?)"));
  EXPECT_FALSE(ty.isStatic());
}

TEST_F(CuteTest, StrideType_Depth1_WithScaledBasis) {
  // `StrideType::verify` rejects mixed nonzero-int + scaled-basis forms.
  // Use a zero-int leaf (allowed) alongside a dynamic scaled-basis.
  auto ty = StrideType::get(&ctx, mkStride("(0,?@0)"));
  EXPECT_FALSE(ty.isStatic());
}

TEST_F(CuteTest, StrideType_Depth2_Static) {
  auto ty = StrideType::get(&ctx, mkStride("(16,(32,4))"));
  EXPECT_TRUE(ty.isStatic());
}

TEST_F(CuteTest, StrideType_Uniquing_Same) {
  auto t1 = StrideType::get(&ctx, mkStride("(16,32)"));
  auto t2 = StrideType::get(&ctx, mkStride("(16,32)"));
  EXPECT_EQ(t1, t2);
}

TEST_F(CuteTest, StrideType_Uniquing_Different) {
  auto t1 = StrideType::get(&ctx, mkStride("(16,32)"));
  auto t2 = StrideType::get(&ctx, mkStride("(16,64)"));
  EXPECT_NE(t1, t2);
}

TEST_F(CuteTest, StrideType_AttrMatchesRef) {
  // Zero-int leaves are allowed alongside scaled-basis leaves; mixed
  // nonzero-int + scaled-basis is rejected by `StrideType::verify`.
  auto val = mkStride("(0,?@0)");
  auto ty = StrideType::get(&ctx, val);
  EXPECT_EQ(ty.getRef(), ty.getAttr().getRef());
}
