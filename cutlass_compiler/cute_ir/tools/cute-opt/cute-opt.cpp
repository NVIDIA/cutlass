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

//===- cute-opt.cpp - Cute dialect standalone optimizer driver ------------===//

#include "cute_ir/Registration/Registration.h"

#include "mlir/Conversion/Passes.h"
#include "mlir/Tools/mlir-opt/MlirOptMain.h"
#include "mlir/Transforms/Passes.h"

using namespace mlir;

int main(int argc, char **argv) {
  DialectRegistry registry;

  // Loads the cute dialect and its hard dependencies (arith, func, gpu,
  // LLVM, math, scf, ub) into the dialect registry. No CLI flags —
  // controls parsing / printing only.
  cutlass_compiler::cute::registerCuteDialects(registry);

  // Cute-specific passes:
  //   --cute-fold-static       (Dialect/Cute/Transforms)
  //   --cute-expand-ops        (Conversion/CuteToBase)
  //   --cute-to-base           (Conversion/CuteToBase)
  cutlass_compiler::cute::registerCutePasses();

  // Standard MLIR transform passes:
  //   --canonicalize
  //   --cse
  //   --inline
  //   --symbol-dce
  //   --loop-invariant-code-motion
  //   --mem2reg / --sroa
  //   --remove-dead-values
  //   --sccp
  //   --print-op-stats / --strip-debuginfo / --view-op-graph
  //   --control-flow-sink / --generate-runtime-verification
  //   --composite-fixed-point-pass
  // None of these are required by the cute LIT tests today, but they
  // give users access to the standard cleanup toolkit when authoring or
  // debugging pipelines.
  registerTransformsPasses();

  // Cleans up same-type unrealized_conversion_cast ops left behind by
  // partial dialect conversions (notably --cute-expand-ops). This pass
  // lives in mlir/Conversion/, not mlir/Transforms/, so it isn't
  // registered by registerTransformsPasses above. Available as:
  //   --reconcile-unrealized-casts
  registerReconcileUnrealizedCastsPass();

  return mlir::asMainReturnCode(mlir::MlirOptMain(
      argc, argv, "cute-opt modular optimizer driver\n", registry));
}
