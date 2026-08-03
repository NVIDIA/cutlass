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
// `one-shot-convert-to-llvm` — final lowering pass. Walks every
// `gpu.module` and partial-converts its body to LLVM/NVVM, then partial-
// converts the host module to LLVM. Leaves only `LLVM::*`, `NVVM::*`,
// and the preserved `gpu.module` / `gpu.binary` / `gpu.launch_func`
// shells for the binary-emission pass.
//
//===----------------------------------------------------------------------===//

#include "base/Conversion/BaseToTargets/Passes.h"

#include "mlir/Analysis/DataLayoutAnalysis.h"
#include "mlir/Conversion/ConvertToLLVM/ToLLVMInterface.h"
#include "mlir/Conversion/GPUCommon/GPUCommonPass.h"
#include "mlir/Conversion/GPUToNVVM/GPUToNVVMPass.h"
#include "mlir/Conversion/LLVMCommon/LoweringOptions.h"
#include "mlir/Conversion/LLVMCommon/TypeConverter.h"
#include "mlir/Conversion/SCFToControlFlow/SCFToControlFlow.h"
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
#include "mlir/Transforms/DialectConversion.h"

namespace mlir::cutlass_compiler::base {
#define GEN_PASS_DEF_ONESHOTCONVERTTOLLVM
#include "base/Conversion/BaseToTargets/Passes.h.inc"
} // namespace mlir::cutlass_compiler::base

using namespace mlir;
using namespace mlir::cutlass_compiler::base;

namespace {

/// Host-side partial conversion to LLVM. Per-dialect patterns are
/// pulled in via `ConvertToLLVMPatternInterface`; GPU shells stay legal
/// (their bodies were already converted by `convertGPUModule`).
static LogicalResult convertHostCode(ModuleOp module,
                                     const DataLayoutAnalysis &dlAnalysis) {
  MLIRContext *ctx = module.getContext();
  RewritePatternSet patterns(ctx);

  ConversionTarget target(*ctx);
  target.addLegalDialect<LLVM::LLVMDialect>();

  const DataLayout &dl = dlAnalysis.getAtOrAbove(module);
  LowerToLLVMOptions options(ctx, dl);
  LLVMTypeConverter typeConverter(ctx, options, &dlAnalysis);

  for (Dialect *dialect : ctx->getLoadedDialects()) {
    if (auto iface = dyn_cast<ConvertToLLVMPatternInterface>(dialect)) {
      iface->populateConvertToLLVMConversionPatterns(target, typeConverter,
                                                     patterns);
    }
  }

  target.addLegalOp<gpu::GPUModuleOp, gpu::BinaryOp>();
  target.addDynamicallyLegalOp<gpu::LaunchFuncOp>(
      [&](gpu::LaunchFuncOp op) -> bool { return typeConverter.isLegal(op); });
  populateGpuToLLVMConversionPatterns(typeConverter, patterns);

  return applyPartialConversion(module, target, std::move(patterns));
}

/// GPU module partial conversion to LLVM/NVVM. The gpu→nvvm patterns
/// take precedence for overlapping ops over the generic per-dialect
/// interface population.
static LogicalResult convertGPUModule(gpu::GPUModuleOp gpuModule,
                                      const DataLayoutAnalysis &dlAnalysis) {
  MLIRContext *ctx = gpuModule.getContext();
  RewritePatternSet patterns(ctx);

  ConversionTarget target(*ctx);
  target.addLegalDialect<LLVM::LLVMDialect>();

  const DataLayout &dl = dlAnalysis.getAtOrAbove(gpuModule);
  LowerToLLVMOptions options(ctx, dl);
  LLVMTypeConverter typeConverter(ctx, options, &dlAnalysis);

  configureGpuToNVVMTypeConverter(typeConverter);
  populateGpuToNVVMConversionPatterns(typeConverter, patterns,
                                      /*benefit=*/10);
  configureGpuToNVVMConversionLegality(target);

  // Must run AFTER the gpu→nvvm patterns so they win for overlapping ops.
  for (Dialect *dialect : ctx->getLoadedDialects()) {
    if (auto iface = dyn_cast<ConvertToLLVMPatternInterface>(dialect)) {
      iface->populateConvertToLLVMConversionPatterns(target, typeConverter,
                                                     patterns);
    }
  }

  return applyPartialConversion(gpuModule, target, std::move(patterns));
}

/// Walks gpu.modules first, then converts host code. SCF→CF runs once
/// up front so both phases see only CF ops.
struct OneShotConvertToLLVMPass
    : public mlir::cutlass_compiler::base::impl::OneShotConvertToLLVMBase<
          OneShotConvertToLLVMPass> {
  void runOnOperation() override {
    ModuleOp module = getOperation();

    // Upstream MLIR doesn't expose a ConvertToLLVMInterface for SCF
    // (scf lowers via scf→cf→llvm, not directly), so run convert-scf-to-cf
    // first.
    {
      OpPassManager prepPm(ModuleOp::getOperationName());
      prepPm.addPass(createSCFToControlFlowPass());
      if (failed(runPipeline(prepPm, module))) {
        signalPassFailure();
        return;
      }
    }

    const auto &dlAnalysis = getAnalysis<DataLayoutAnalysis>();

    SmallVector<gpu::GPUModuleOp> gpuModules;
    module->walk([&](gpu::GPUModuleOp gm) { gpuModules.push_back(gm); });
    for (gpu::GPUModuleOp gm : gpuModules) {
      if (failed(convertGPUModule(gm, dlAnalysis))) {
        signalPassFailure();
        return;
      }
    }

    if (failed(convertHostCode(module, dlAnalysis))) {
      signalPassFailure();
    }
  }
};

} // namespace
