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
// `base-prepare` — runs canonicalize → cse → LICM →
// reconcile-unrealized-casts on the top-level module and on each nested
// `gpu.module` (MLIR's pass manager does not recurse into nested
// module-like ops; `gpu.module` is a separate symbol scope).
//
//===----------------------------------------------------------------------===//

#include "base/Conversion/BaseToTargets/Passes.h"

#include "mlir/Conversion/ReconcileUnrealizedCasts/ReconcileUnrealizedCasts.h"
#include "mlir/Dialect/Arith/IR/Arith.h"
#include "mlir/Dialect/ControlFlow/IR/ControlFlow.h"
#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/Dialect/GPU/IR/GPUDialect.h"
#include "mlir/Dialect/LLVMIR/LLVMDialect.h"
#include "mlir/Dialect/LLVMIR/NVVMDialect.h"
#include "mlir/Dialect/Math/IR/Math.h"
#include "mlir/Dialect/SCF/IR/SCF.h"
#include "mlir/Dialect/UB/IR/UBOps.h"
#include "mlir/Pass/Pass.h"
#include "mlir/Pass/PassManager.h"
#include "mlir/Transforms/Passes.h"

namespace mlir::cutlass_compiler::base {
#define GEN_PASS_DEF_BASEPREPARE
#include "base/Conversion/BaseToTargets/Passes.h.inc"
} // namespace mlir::cutlass_compiler::base

using namespace mlir;
using namespace mlir::cutlass_compiler::base;

namespace {

struct BasePreparePass
    : public mlir::cutlass_compiler::base::impl::BasePrepareBase<
          BasePreparePass> {
  void runOnOperation() override {
    OpPassManager modulePm(ModuleOp::getOperationName());
    modulePm.addPass(createCanonicalizerPass());
    modulePm.addPass(createCSEPass());
    modulePm.addPass(createLoopInvariantCodeMotionPass());
    modulePm.addPass(createReconcileUnrealizedCastsPass());
    if (failed(runPipeline(modulePm, getOperation()))) {
      signalPassFailure();
      return;
    }

    OpPassManager gpuModulePm(gpu::GPUModuleOp::getOperationName());
    gpuModulePm.addPass(createCanonicalizerPass());
    gpuModulePm.addPass(createCSEPass());
    gpuModulePm.addPass(createLoopInvariantCodeMotionPass());
    gpuModulePm.addPass(createReconcileUnrealizedCastsPass());
    WalkResult walkResult = getOperation()->walk([&](gpu::GPUModuleOp gm) {
      return failed(runPipeline(gpuModulePm, gm)) ? WalkResult::interrupt()
                                                  : WalkResult::advance();
    });
    if (walkResult.wasInterrupted()) {
      signalPassFailure();
    }
  }
};

} // namespace
