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

//===- CuteFoldStatic.cpp - Fold static cute values -----------------------===//
//

//===----------------------------------------------------------------------===//

#include "cute_ir/Dialect/Cute/IR/CuteDialect.h"
#include "cute_ir/Dialect/Cute/Transforms/Passes.h"
#include "cute_ir/Dialect/Cute/Transforms/StaticFold.h"

#include "cutegen/cutegen_mlir.hpp"

#include "mlir/Dialect/Arith/IR/Arith.h"
#include "mlir/IR/ImplicitLocOpBuilder.h"
#include "mlir/IR/Iterators.h"
#include "mlir/IR/PatternMatch.h"
#include "mlir/Interfaces/SideEffectInterfaces.h"

#include "llvm/ADT/TypeSwitch.h"

namespace mlir::cutlass_compiler::cute {
#define GEN_PASS_DEF_CUTEFOLDSTATIC
#include "cute_ir/Dialect/Cute/Transforms/Passes.h.inc"
} // namespace mlir::cutlass_compiler::cute

using namespace mlir;
using namespace mlir::cutlass_compiler::cute;
namespace cg = cutegen;

namespace mlir::cutlass_compiler::cute {

LogicalResult tryStaticFoldEqual(EqualOp op, RewriterBase &rewriter) {
  ImplicitLocOpBuilder b(op.getLoc(), rewriter);
  bool result = (op.getLhs().getType() == op.getRhs().getType());
  rewriter.replaceOp(op, arith::ConstantOp::create(
                             b, IntegerAttr::get(b.getI1Type(), result)));
  return success();
}

LogicalResult tryStaticFoldElemLess(ElemLessOp op, RewriterBase &rewriter) {
  ImplicitLocOpBuilder b(op.getLoc(), rewriter);
  bool result = true;
  auto fold = [&](auto lhsRef, auto rhsRef) {
    auto lhsFlat = cg::flatten(lhsRef);
    auto rhsFlat = cg::flatten(rhsRef);
    for (size_t i = 0, n = cg::rank(lhsFlat); i < n; ++i) {
      if (!(lhsFlat[i].as_int64() < rhsFlat[i].as_int64())) {
        result = false;
        return;
      }
    }
  };
  llvm::TypeSwitch<Type>(op.getLhs().getType())
      .Case<IntTupleType, ShapeType, CoordType>([&](auto lhsTy) {
        llvm::TypeSwitch<Type>(op.getRhs().getType())
            .template Case<IntTupleType, ShapeType, CoordType>(
                [&](auto rhsTy) { fold(lhsTy.getRef(), rhsTy.getRef()); })
            .Default([](Type) {
              llvm_unreachable("ODS constrains $rhs to "
                               "IntTupleType|ShapeType|CoordType");
            });
      })
      .Default([](Type) {
        llvm_unreachable("ODS constrains $lhs to "
                         "IntTupleType|ShapeType|CoordType");
      });
  rewriter.replaceOp(op, arith::ConstantOp::create(
                             b, IntegerAttr::get(b.getI1Type(), result)));
  return success();
}

} // namespace mlir::cutlass_compiler::cute

namespace {

struct CuteFoldStaticPass
    : public mlir::cutlass_compiler::cute::impl::CuteFoldStaticBase<
          CuteFoldStaticPass> {
  void runOnOperation() override {
    IRRewriter rewriter(&getContext());

    getOperation()->walk<WalkOrder::PostOrder, ReverseIterator>(
        [&](Operation *op) {
          // Keep existing static materializations.
          if (isa<StaticOp>(op)) {
            return WalkResult::skip();
          }
          // Only pure operations are safe to remove/fold.
          if (!isPure(op)) {
            return WalkResult::skip();
          }
          // Terminators must remain in place.
          if (op->mightHaveTrait<OpTrait::IsTerminator>()) {
            return WalkResult::skip();
          }
          // Dead pure operations can be erased directly.
          if (op->use_empty()) {
            rewriter.eraseOp(op);
            return WalkResult::skip();
          }

          rewriter.setInsertionPoint(op);

          // cute.equal and cute.elem_less produce an i1 result, so the
          // generic MaybeStaticTypeInterface check below skips them. Fold
          // each one explicitly when both operands carry static cute types.
          if (auto eqOp = dyn_cast<EqualOp>(op);
              eqOp && bothOperandsStatic(eqOp)) {
            (void)tryStaticFoldEqual(eqOp, rewriter);
            return WalkResult::skip();
          }
          if (auto elOp = dyn_cast<ElemLessOp>(op);
              elOp && bothOperandsStatic(elOp)) {
            (void)tryStaticFoldElemLess(elOp, rewriter);
            return WalkResult::skip();
          }

          for (Value result : op->getResults()) {
            auto staticInterface =
                dyn_cast<MaybeStaticTypeInterface>(result.getType());
            if (!staticInterface || !staticInterface.isStatic()) {
              continue;
            }

            Value staticValue =
                StaticOp::create(rewriter, op->getLoc(), result.getType());
            rewriter.replaceAllUsesWith(result, staticValue);
          }

          if (op->use_empty()) {
            rewriter.eraseOp(op);
            return WalkResult::skip();
          }
          return WalkResult::advance();
        });
  }
};
} // namespace
