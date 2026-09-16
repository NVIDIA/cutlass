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

#include "mlir/IR/Builders.h"
#include "mlir/IR/BuiltinOps.h"

#include "CuteTest.h"

using namespace mlir;
using namespace mlir::cutlass_compiler::cute;
using namespace mlir::cutlass_compiler::cute::test;

namespace cg = cutegen;

template <class T>
static T fromStr(const char *s) {
  return cg::from_string<T>(s).value();
}

/// Base fixture with a bare Block and OpBuilder for op construction tests.
class CuteMakeOpTest : public CuteTest {
protected:
  void SetUp() override {
    CuteTest::SetUp();
    loc = mlir::UnknownLoc::get(&ctx);
    b = std::make_unique<mlir::OpBuilder>(&ctx);
    b->setInsertionPointToStart(&block);
  }

  /// Returns the number of operations currently in the test block.
  size_t countOps() {
    return static_cast<size_t>(std::distance(block.begin(), block.end()));
  }

  mlir::LocationAttr loc;
  mlir::Block block;
  std::unique_ptr<mlir::OpBuilder> b;
};

//===----------------------------------------------------------------------===//
// MakeIntTupleOp — cutegen::int_tuple builder
//===----------------------------------------------------------------------===//

TEST_F(CuteMakeOpTest, MakeIntTupleOp_StaticScalar) {
  auto val = fromStr<cg::int_tuple>("4");

  size_t before = countOps();
  auto op = MakeIntTupleOp::create(*b, loc, val);

  ASSERT_TRUE(op);
  EXPECT_EQ(countOps() - before, 1u);
  EXPECT_EQ(op.getNumOperands(), 0u);
  EXPECT_TRUE(op.getResult().getType().isStatic());
  EXPECT_EQ(cg::to_string(op.getResult().getType().getRef()), "4");
  EXPECT_TRUE(mlir::succeeded(op.verify()));
}

TEST_F(CuteMakeOpTest, MakeIntTupleOp_StaticTuple) {
  auto val = fromStr<cg::int_tuple>("(4,3)");

  size_t before = countOps();
  auto op = MakeIntTupleOp::create(*b, loc, val);

  ASSERT_TRUE(op);
  EXPECT_EQ(countOps() - before, 1u);
  EXPECT_EQ(op.getNumOperands(), 0u);
  EXPECT_TRUE(op.getResult().getType().isStatic());
  EXPECT_EQ(cg::to_string(op.getResult().getType().getRef()), "(4,3)");
  EXPECT_TRUE(mlir::succeeded(op.verify()));
}

TEST_F(CuteMakeOpTest, MakeIntTupleOp_DynamicScalar) {
  // Embed an i32 block argument into a mlir_dynamic_t.
  mlir::Value arg = block.addArgument(i32Ty, loc);
  auto d = cg::mlir_dynamic_t(arg, /*listener=*/nullptr);
  cg::int_tuple val(d);

  size_t before = countOps();
  auto op = MakeIntTupleOp::create(*b, loc, val);

  ASSERT_TRUE(op);
  EXPECT_EQ(countOps() - before, 1u);
  EXPECT_EQ(op.getNumOperands(), 1u);
  EXPECT_EQ(op.getOperands()[0], arg);
  EXPECT_FALSE(op.getResult().getType().isStatic());
  EXPECT_TRUE(mlir::succeeded(op.verify()));
}

//===----------------------------------------------------------------------===//
// MakeShapeOp — cutegen::shape builder
//===----------------------------------------------------------------------===//

TEST_F(CuteMakeOpTest, MakeShapeOp_StaticFlat) {
  auto val = fromStr<cg::shape>("(128,64)");

  size_t before = countOps();
  auto op = MakeShapeOp::create(*b, loc, val);

  ASSERT_TRUE(op);
  EXPECT_EQ(countOps() - before, 1u);
  EXPECT_EQ(op.getNumOperands(), 0u);
  EXPECT_TRUE(op.getResult().getType().isStatic());
  EXPECT_TRUE(mlir::succeeded(op.verify()));
}

TEST_F(CuteMakeOpTest, MakeShapeOp_DynamicLeaf) {
  mlir::Value arg = block.addArgument(i32Ty, loc);
  auto d = cg::mlir_dynamic_t(arg, nullptr);
  cg::shape val(d, cg::static_int_t(64));

  size_t before = countOps();
  auto op = MakeShapeOp::create(*b, loc, val);

  ASSERT_TRUE(op);
  EXPECT_EQ(countOps() - before, 1u);
  EXPECT_EQ(op.getNumOperands(), 1u);
  EXPECT_EQ(op.getOperands()[0], arg);
  EXPECT_TRUE(mlir::succeeded(op.verify()));
}

//===----------------------------------------------------------------------===//
// MakeStrideOp — cutegen::stride builder
//===----------------------------------------------------------------------===//

TEST_F(CuteMakeOpTest, MakeStrideOp_StaticFlat) {
  auto val = fromStr<cg::stride>("(1,4)");

  size_t before = countOps();
  auto op = MakeStrideOp::create(*b, loc, val);

  ASSERT_TRUE(op);
  EXPECT_EQ(countOps() - before, 1u);
  EXPECT_EQ(op.getNumOperands(), 0u);
  EXPECT_TRUE(op.getResult().getType().isStatic());
  EXPECT_TRUE(mlir::succeeded(op.verify()));
}

//===----------------------------------------------------------------------===//
// MakeCoordOp — cutegen::coord builder
//===----------------------------------------------------------------------===//

TEST_F(CuteMakeOpTest, MakeCoordOp_StaticFlat) {
  auto val = fromStr<cg::coord>("(1,2)");

  size_t before = countOps();
  auto op = MakeCoordOp::create(*b, loc, val);

  ASSERT_TRUE(op);
  EXPECT_EQ(countOps() - before, 1u);
  EXPECT_EQ(op.getNumOperands(), 0u);
  EXPECT_TRUE(op.getResult().getType().isStatic());
  EXPECT_TRUE(mlir::succeeded(op.verify()));
}

//===----------------------------------------------------------------------===//
// MakeTileOp — cutegen::tile builder
//===----------------------------------------------------------------------===//

TEST_F(CuteMakeOpTest, MakeTileOp_StaticSingleLayout) {
  auto val = fromStr<cg::tile>("[(2,3):(1,2)]");

  size_t before = countOps();
  auto op = MakeTileOp::create(*b, loc, val);

  ASSERT_TRUE(op);
  EXPECT_EQ(countOps() - before, 1u);
  EXPECT_EQ(op.getNumOperands(), 0u);
  EXPECT_TRUE(op.getResult().getType().isStatic());
  EXPECT_TRUE(mlir::succeeded(op.verify()));
}

TEST_F(CuteMakeOpTest, MakeTileOp_StaticUnderscore) {
  auto val = fromStr<cg::tile>("[_]");

  size_t before = countOps();
  auto op = MakeTileOp::create(*b, loc, val);

  ASSERT_TRUE(op);
  EXPECT_EQ(countOps() - before, 1u);
  EXPECT_EQ(op.getNumOperands(), 0u);
  EXPECT_TRUE(mlir::succeeded(op.verify()));
}

//===----------------------------------------------------------------------===//
// MakeLayoutOp — cutegen::layout builders
//===----------------------------------------------------------------------===//

TEST_F(CuteMakeOpTest, MakeLayoutOp_Explicit) {
  mlir::Value sArg = block.addArgument(i32Ty, loc);
  mlir::Value dArg = block.addArgument(i32Ty, loc);
  auto ds = cg::mlir_dynamic_t(sArg, nullptr);
  auto dd = cg::mlir_dynamic_t(dArg, nullptr);
  // (?,2):(?,4) — caller pre-builds shape and stride ops.
  auto shapeVal = cg::shape(ds, cg::static_int_t(2));
  auto strideVal = cg::stride(dd, cg::static_int_t(4));
  auto shapeOp = MakeShapeOp::create(*b, loc, shapeVal);
  auto strideOp = MakeStrideOp::create(*b, loc, strideVal);

  size_t before = countOps();
  auto op =
      MakeLayoutOp::create(*b, loc, shapeOp.getResult(), strideOp.getResult());

  ASSERT_TRUE(op);
  EXPECT_EQ(countOps() - before, 1u);
  EXPECT_EQ(op.getNumOperands(), 2u);
  EXPECT_TRUE(mlir::succeeded(op.verify()));
}

//===----------------------------------------------------------------------===//
// MakeComposedLayoutOp — pre-built operand builders
//===----------------------------------------------------------------------===//

TEST_F(CuteMakeOpTest, MakeComposedLayoutOp_LayoutA_ExplicitOffset) {
  auto innerL = fromStr<cg::layout>("(4,5):(1,4)");
  auto off = fromStr<cg::int_tuple>("2");
  auto outerL = fromStr<cg::layout>("(2,3):(1,2)");

  auto innerVal =
      StaticOp::create(*b, loc, LayoutType::get(&ctx, innerL)).getResult();
  auto offsetVal = MakeIntTupleOp::create(*b, loc, off).getResult();
  auto outerVal =
      StaticOp::create(*b, loc, LayoutType::get(&ctx, outerL)).getResult();

  size_t before = countOps();
  auto op =
      MakeComposedLayoutOp::create(*b, loc, innerVal, offsetVal, outerVal);

  ASSERT_TRUE(op);
  EXPECT_EQ(countOps() - before, 1u);
  EXPECT_TRUE(mlir::succeeded(op.verify()));
}

TEST_F(CuteMakeOpTest, MakeComposedLayoutOp_SwizzleA_ExplicitOffset) {
  auto sw = fromStr<cg::swizzle>("S<3,5,4>");
  auto off = fromStr<cg::int_tuple>("2");
  auto outerL = fromStr<cg::layout>("(8,4):(1,8)");

  auto innerVal =
      StaticOp::create(*b, loc, SwizzleType::get(&ctx, sw)).getResult();
  auto offsetVal = MakeIntTupleOp::create(*b, loc, off).getResult();
  auto outerVal =
      StaticOp::create(*b, loc, LayoutType::get(&ctx, outerL)).getResult();

  size_t before = countOps();
  auto op =
      MakeComposedLayoutOp::create(*b, loc, innerVal, offsetVal, outerVal);

  ASSERT_TRUE(op);
  EXPECT_EQ(countOps() - before, 1u);
  EXPECT_TRUE(mlir::succeeded(op.verify()));
}

TEST_F(CuteMakeOpTest, MakeComposedLayoutOp_LayoutA_ZeroOffset) {
  auto innerL = fromStr<cg::layout>("(4,5):(1,4)");
  auto outerL = fromStr<cg::layout>("(2,3):(1,2)");
  auto zeroOff = cg::int_tuple(cg::static_int_t(0));

  auto innerVal =
      StaticOp::create(*b, loc, LayoutType::get(&ctx, innerL)).getResult();
  auto offsetVal = MakeIntTupleOp::create(*b, loc, zeroOff).getResult();
  auto outerVal =
      StaticOp::create(*b, loc, LayoutType::get(&ctx, outerL)).getResult();

  size_t before = countOps();
  auto op =
      MakeComposedLayoutOp::create(*b, loc, innerVal, offsetVal, outerVal);

  ASSERT_TRUE(op);
  EXPECT_EQ(countOps() - before, 1u);
  EXPECT_TRUE(mlir::succeeded(op.verify()));
}

TEST_F(CuteMakeOpTest, MakeComposedLayoutOp_SwizzleA_ZeroOffset) {
  auto sw = fromStr<cg::swizzle>("S<3,5,4>");
  auto outerL = fromStr<cg::layout>("(8,4):(1,8)");
  auto zeroOff = cg::int_tuple(cg::static_int_t(0));

  auto innerVal =
      StaticOp::create(*b, loc, SwizzleType::get(&ctx, sw)).getResult();
  auto offsetVal = MakeIntTupleOp::create(*b, loc, zeroOff).getResult();
  auto outerVal =
      StaticOp::create(*b, loc, LayoutType::get(&ctx, outerL)).getResult();

  size_t before = countOps();
  auto op =
      MakeComposedLayoutOp::create(*b, loc, innerVal, offsetVal, outerVal);

  ASSERT_TRUE(op);
  EXPECT_EQ(countOps() - before, 1u);
  EXPECT_TRUE(mlir::succeeded(op.verify()));
}
