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

//===- cutlass-compiler.cpp - Comprehensive cutlass_compiler driver ---===//
//
// `cutlass-compiler` is the comprehensive compiler driver for the
// cutlass_compiler project. It registers BOTH the cute and base layers (calling
// each layer's registration library) and exposes every pass available in either
// layer plus the upstream MLIR transforms / cleanup passes.
//
// Use this tool for:
//   - end-to-end / integration scenarios that span multiple layers
//   - user-facing pipeline invocations
//   - debugging IR that mixes cute and base ops/types
//
// For testing in isolation, prefer the per-layer scoped tools:
//   - `cute-opt`  — cute layer
//   - `base-opt`  — base layer
//===----------------------------------------------------------------------===//

#include "base/Registration/Registration.h"
#include "cute_ir/Registration/Registration.h"

#include "mlir/Conversion/Passes.h"
#include "mlir/Tools/mlir-opt/MlirOptMain.h"
#include "mlir/Transforms/Passes.h"

using namespace mlir;

int main(int argc, char **argv) {
  DialectRegistry registry;

  // Cute layer (cute dialect + its hard dependencies — arith, func,
  // gpu, LLVM, math, scf, ub — already overlap with base, but
  // DialectRegistry deduplicates by type ID).
  cutlass_compiler::cute::registerCuteDialects(registry);
  cutlass_compiler::cute::registerCutePasses();

  // Base layer (arith / cf / func / gpu / LLVM / math / NVVM / scf /
  // ub).
  cutlass_compiler::base::registerBaseDialects(registry);
  cutlass_compiler::base::registerBasePasses();

  // Standard MLIR transform passes:
  //   --canonicalize / --cse / --inline / --symbol-dce
  //   --loop-invariant-code-motion / --mem2reg / --sroa
  //   --remove-dead-values / --sccp / --strip-debuginfo / etc.
  registerTransformsPasses();

  // Cleans up same-type `unrealized_conversion_cast` ops left behind
  // by partial dialect conversions:
  //   --reconcile-unrealized-casts
  registerReconcileUnrealizedCastsPass();

  return mlir::asMainReturnCode(mlir::MlirOptMain(
      argc, argv, "cutlass-compiler comprehensive compiler driver\n",
      registry));
}
