//===-- StaticFold.h - Static folding helpers for cute ops ------*- C++ -*-===//
//

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

//===----------------------------------------------------------------------===//
//

// Shared helpers for folding cute ops with fully-static operands. Used by
// cute-fold-static and by the conversion patterns in
// lib/Conversion/CuteToBase/ExpandOps.cpp.
//

//===----------------------------------------------------------------------===//

#ifndef CUTE_IR_DIALECT_CUTE_TRANSFORMS_STATIC_FOLD_H
#define CUTE_IR_DIALECT_CUTE_TRANSFORMS_STATIC_FOLD_H

#include "cute_ir/Dialect/Cute/IR/CuteDialect.h"

#include "mlir/IR/PatternMatch.h"
#include "mlir/Support/LogicalResult.h"

#include "llvm/Support/Casting.h"

namespace mlir::cutlass_compiler::cute {

/// True if both operands of op are static cute types.
template <typename Op>
bool bothOperandsStatic(Op op) {
  auto lhsStatic =
      llvm::dyn_cast<MaybeStaticTypeInterface>(op.getLhs().getType());
  auto rhsStatic =
      llvm::dyn_cast<MaybeStaticTypeInterface>(op.getRhs().getType());
  return lhsStatic && rhsStatic && lhsStatic.isStatic() && rhsStatic.isStatic();
}

/// Static-fold cute.equal via MLIR Type identity (cute types are uniqued).
LogicalResult tryStaticFoldEqual(EqualOp op, RewriterBase &rewriter);

/// Static-fold cute.elem_less by ANDing per-leaf < over the flattened
/// refs. ODS verifier guarantees the operands are congruent.
LogicalResult tryStaticFoldElemLess(ElemLessOp op, RewriterBase &rewriter);

} // namespace mlir::cutlass_compiler::cute

#endif // CUTE_IR_DIALECT_CUTE_TRANSFORMS_STATIC_FOLD_H
