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
// `attach-nvvm-target` — cutlass_compiler wrapper around the upstream
// `gpu-nvvm-attach-target` pass. Annotates every `gpu.module` with an
// `#nvvm.target<chip = ..., features = ...>` attribute that downstream
// binary emission (`emit-gpu-binary`) consumes.
//
//===----------------------------------------------------------------------===//

#include "base/Conversion/BaseToTargets/Passes.h"

#include "mlir/Dialect/GPU/IR/GPUDialect.h"
#include "mlir/Dialect/GPU/Transforms/Passes.h"
#include "mlir/Dialect/LLVMIR/LLVMDialect.h"
#include "mlir/Dialect/LLVMIR/NVVMDialect.h"
#include "mlir/Pass/Pass.h"
#include "mlir/Pass/PassManager.h"

namespace mlir::cutlass_compiler::base {
#define GEN_PASS_DEF_ATTACHNVVMTARGET
#include "base/Conversion/BaseToTargets/Passes.h.inc"
} // namespace mlir::cutlass_compiler::base

using namespace mlir;
using namespace mlir::cutlass_compiler::base;

namespace {

struct AttachNVVMTargetPass
    : public mlir::cutlass_compiler::base::impl::AttachNVVMTargetBase<
          AttachNVVMTargetPass> {
  using AttachNVVMTargetBase::AttachNVVMTargetBase;

  void runOnOperation() override {
    ModuleOp module = getOperation();

    // Forward this pass's options to `gpu-nvvm-attach-target`. The
    // upstream defaults for the unset fields (`triple`,
    // `moduleMatcher`, fast/ftz flags, etc.) are kept as-is — cutlass_compiler
    // doesn't expose them yet.
    GpuNVVMAttachTargetOptions attachOpts;
    attachOpts.chip = chip;
    attachOpts.features = features;
    attachOpts.optLevel = optLevel;

    OpPassManager pm(module.getOperationName());
    pm.addPass(createGpuNVVMAttachTarget(attachOpts));

    if (failed(runPipeline(pm, module))) {
      signalPassFailure();
      return;
    }
  }
};

} // namespace
