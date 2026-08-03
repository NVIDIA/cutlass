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

//===- base-opt.cpp - Base layer standalone optimizer driver --------------===//
//
// `base-opt` is the per-layer scoped optimizer for the `base/` pseudo-
// dialect. It registers ONLY the dialects that may appear in IR after
// `cute-to-base` (arith, cf, func, gpu, LLVM, math, NVVM, scf, ub),
// plus the upstream MLIR transform passes the base lowering pipeline
// consumes (canonicalize, cse, loop-invariant-code-motion,
// reconcile-unrealized-casts).
//
// The cute dialect is INTENTIONALLY NOT REGISTERED — base-opt is the
// strict-isolation testing tool for base-layer passes (BasePrepare,
// OneShotConvertToLLVM, target tails). Test inputs that reference
// `!cute.<type>` or `cute.<op>` will fail to parse here, providing a
// clean boundary that catches accidental cute leakage into base tests.
//
// For end-to-end / integration scenarios that need both layers, use
// `cutlass-compiler` instead.
//===----------------------------------------------------------------------===//

#include "base/Registration/Registration.h"

#include "mlir/Conversion/Passes.h"
#include "mlir/Tools/mlir-opt/MlirOptMain.h"
#include "mlir/Transforms/Passes.h"

using namespace mlir;

int main(int argc, char **argv) {
  DialectRegistry registry;

  // Loads the base dialects (arith / cf / func / gpu / LLVM / math /
  // NVVM / scf / ub) into the registry. Notably absent: the cute
  // dialect — see file-header comment.
  cutlass_compiler::base::registerBaseDialects(registry);

  // Base-namespace passes: BasePrepare, OneShotConvertToLLVM, and the
  // target tails.
  cutlass_compiler::base::registerBasePasses();

  // Standard MLIR transform passes:
  //   --canonicalize / --cse / --loop-invariant-code-motion / etc.
  // Used by `BasePrepare` and available to users for ad-hoc cleanup
  // in pipelines.
  registerTransformsPasses();

  // Cleans up same-type `unrealized_conversion_cast` ops left behind by
  // partial dialect conversions. Available as:
  //   --reconcile-unrealized-casts
  registerReconcileUnrealizedCastsPass();

  return mlir::asMainReturnCode(mlir::MlirOptMain(
      argc, argv, "base-opt modular optimizer driver\n", registry));
}
