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

#include "base/Conversion/BaseToTargets/Passes.h"
#include "base/Registration/Registration.h"

#include "mlir/Conversion/ArithToLLVM/ArithToLLVM.h"
#include "mlir/Conversion/ControlFlowToLLVM/ControlFlowToLLVM.h"
#include "mlir/Conversion/FuncToLLVM/ConvertFuncToLLVM.h"
#include "mlir/Conversion/MathToLLVM/MathToLLVM.h"
#include "mlir/Conversion/NVVMToLLVM/NVVMToLLVM.h"
#include "mlir/Conversion/UBToLLVM/UBToLLVM.h"
#include "mlir/Dialect/Arith/IR/Arith.h"
#include "mlir/Dialect/ControlFlow/IR/ControlFlow.h"
#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/Dialect/GPU/IR/GPUDialect.h"
#include "mlir/Dialect/LLVMIR/LLVMDialect.h"
#include "mlir/Dialect/LLVMIR/NVVMDialect.h"
#include "mlir/Dialect/Math/IR/Math.h"
#include "mlir/Dialect/SCF/IR/SCF.h"
#include "mlir/Dialect/UB/IR/UBOps.h"
#include "mlir/Target/LLVM/NVVM/Target.h"
#include "mlir/Target/LLVMIR/Dialect/GPU/GPUToLLVMIRTranslation.h"
#include "mlir/Target/LLVMIR/Dialect/LLVMIR/LLVMToLLVMIRTranslation.h"
#include "mlir/Target/LLVMIR/Dialect/NVVM/NVVMToLLVMIRTranslation.h"

using namespace mlir;

namespace mlir::cutlass_compiler::base {

void registerBaseDialects(DialectRegistry &registry) {
  registry
      .insert<arith::ArithDialect, cf::ControlFlowDialect, func::FuncDialect,
              gpu::GPUDialect, LLVM::LLVMDialect, math::MathDialect,
              NVVM::NVVMDialect, scf::SCFDialect, ub::UBDialect>();
  // Register the per-dialect ConvertToLLVMPatternInterface extensions
  // for the dialects OneShotConvertToLLVM lowers via the interface
  // hook. Without these, the interface lookup fails with "interface
  // promised by dialect 'X' but never implemented".
  //
  // Note: SCF does NOT have a dedicated ConvertToLLVMInterface upstream
  // because scf lowers to LLVM via scf→cf→llvm, not directly. The
  // OneShotConvertToLLVM pass itself runs `convert-scf-to-cf` as
  // preprocessing before the one-shot conversion.
  arith::registerConvertArithToLLVMInterface(registry);
  cf::registerConvertControlFlowToLLVMInterface(registry);
  registerConvertFuncToLLVMInterface(registry);
  registerConvertMathToLLVMInterface(registry);
  registerConvertNVVMToLLVMInterface(registry);
  ub::registerConvertUBToLLVMInterface(registry);
  // The NVVM dialect promises a `gpu::TargetAttrInterface` model for
  // its target attribute; the implementation lives in `MLIRNVVMTarget`
  // (linked from `CMakeLists.txt`). Without this registration,
  // `emit-gpu-binary` (and any caller of `gpu-module-to-binary`)
  // crashes at runtime with an "interface promised but never
  // implemented" error.
  NVVM::registerNVVMTargetInterfaceExternalModels(registry);
  // Register the LLVMIR-translation interfaces for GPU / LLVM / NVVM
  // dialects. `gpu-module-to-binary` lowers the gpu.module body to
  // `llvm::Module` via `LLVMTranslationDialectInterface`. Without
  // these registrations, serialization fails with "missing
  // LLVMTranslationDialectInterface registration for dialect for op:
  // gpu.module".
  registerGPUDialectTranslation(registry);
  registerLLVMDialectTranslation(registry);
  registerNVVMDialectTranslation(registry);
  // Note: we deliberately do NOT call
  // `registerConvertToLLVMDependentDialectLoading` here. That helper
  // registers a catch-all extension promising the interface for many
  // dialects, but the implementations live in libraries we don't link
  // which causes a crash at load time when the runtime tries to fetch the
  // promised-but-missing interface. Since we explicitly enumerate the
  // dialects we lower above, we don't need the catch-all.
}

void registerBasePasses() { registerBaseToTargetsPasses(); }

} // namespace mlir::cutlass_compiler::base
