//===-- Passes.td - base lowering pass definitions ---------*- tablegen -*-===//
//
//
//===----------------------------------------------------------------------===//

// Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation
// and/or other materials provided with the distribution.
//
// 3. Neither the name of the copyright holder nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#ifndef BASE_CONVERSION_BASE_TO_TARGETS_PASSES_TD
#define BASE_CONVERSION_BASE_TO_TARGETS_PASSES_TD

include "mlir/Pass/PassBase.td"

def BasePrepare : Pass<"base-prepare", "::mlir::ModuleOp"> {
  let summary = "Canonicalize and normalize base-dialect IR before LLVM conversion";
  let description = [{
    Pipeline-driven simplification pass that runs the standard MLIR
    cleanup passes on the base-dialect IR coming out of `cute-to-base`,
    producing canonical post-cute IR ready for `OneShotConvertToLLVM`.

    Composed of (in order):

      1. `canonicalize` — strength reduction (mul-by-pow2 → shli, etc.),
          poison + full insertvalue/extractvalue round-trip folding, dead
          arith elimination, constant dedup, GEP literal-index folding,
          and same-type `unrealized_conversion_cast` folding.
      2. `cse` — duplicate arith / constant elimination across siblings.
      3. `loop-invariant-code-motion` — pure arith hoisted out of
          `scf.for`.
      4. `reconcile-unrealized-casts` — defensive sweep for any leftover
          same-type casts canonicalize couldn't fold. Empirically a
          no-op on tested inputs but kept so users only need one
          second-invocation step (`| base-opt -base-prepare`) instead of
          two.

    The sub-pipeline runs on the top-level `builtin.module` AND on each
    `gpu.module` separately, so kernels are normalized in isolation
    alongside host code.

    ```
    cute-opt -cute-fold-static -cute-expand-ops -cute-to-base file.mlir \
      | base-opt -base-prepare
    ```
  }];

  let dependentDialects = [
    "::mlir::arith::ArithDialect",
    "::mlir::cf::ControlFlowDialect",
    "::mlir::func::FuncDialect",
    "::mlir::gpu::GPUDialect",
    "::mlir::LLVM::LLVMDialect",
    "::mlir::math::MathDialect",
    "::mlir::NVVM::NVVMDialect",
    "::mlir::scf::SCFDialect",
    "::mlir::ub::UBDialect"
  ];
}

def OneShotConvertToLLVM : Pass<"one-shot-convert-to-llvm", "::mlir::ModuleOp"> {
  let summary = "Lower every remaining base-dialect op to LLVM (and NVVM, inside gpu.module)";
  let description = [{
    Final lowering pass between `base-prepare` and the target tails.
    After this pass the only ops remaining are `LLVM::*`, `NVVM::*`,
    and the preserved `gpu::GPUModuleOp` / `gpu::BinaryOp` shells
    (their bodies are fully lowered to LLVM/NVVM; the shells stay so
    the downstream binary-emission pass can compile them).

    Architecture:

      1. Walk every `gpu.module` and run a partial conversion on each
         in isolation. Target: `LLVM` legal + NVVM legality via
         `configureGpuToNVVMConversionLegality`. Patterns:
         `populateGpuToNVVMConversionPatterns` plus the
         `ConvertToLLVMPatternInterface` hook (which auto-populates
         arith / scf / cf / math / ub / func patterns).
      2. Run the host partial conversion on the top-level module.
         Target: `LLVM` legal + `gpu.module` / `gpu.binary` /
         `gpu.launch_func` (dynamically) legal so the pre-converted
         GPU shells survive. Patterns: `populateGpuToLLVMConversionPatterns`
         for the host-side `gpu.launch_func` lowering plus the same
         interface hook.

    SCF→CF lowering happens inline within the one-shot — the interface
    hook brings SCF patterns in alongside CF, so a separate
    `convert-scf-to-cf` preprocessing pass is not required.

    Function-signature conversion is NOT this pass's job: cute-typed
    signatures were already converted in `cute-to-base`. `func.func` →
    `llvm.func` happens here structurally via the func-dialect
    interface hook.

    `applyPartialConversion` (not full) per scope — preserves the
    gpu.module shells while still failing loudly on any unlowered op
    via tight target legality.
  }];

  let dependentDialects = [
    "::mlir::arith::ArithDialect",
    "::mlir::cf::ControlFlowDialect",
    "::mlir::func::FuncDialect",
    "::mlir::gpu::GPUDialect",
    "::mlir::LLVM::LLVMDialect",
    "::mlir::math::MathDialect",
    "::mlir::NVVM::NVVMDialect",
    "::mlir::scf::SCFDialect",
    "::mlir::ub::UBDialect"
  ];
}

def AttachNVVMTarget : Pass<"attach-nvvm-target", "::mlir::ModuleOp"> {
  let summary = "Attach an #nvvm.target attribute to each gpu.module";
  let description = [{
    Wraps the upstream `gpu-nvvm-attach-target` pass with cutlass_compiler-specific
    defaults. After this pass each `gpu.module` carries an
    `#nvvm.target<chip = ..., features = ...>` attribute that
    downstream binary emission uses to drive ptxas. The `gpu.module`
    body is unchanged.

    Pair with `emit-gpu-binary` to compile the annotated module to a
    `gpu.binary`. The two passes are intentionally separate so binary
    emission can be skipped (e.g. JIT-execution paths).
  }];

  let options = [
    Option<"chip", "chip", "std::string",
           /*default=*/"\"sm_80\"",
           "Target GPU chip (passed to gpu-nvvm-attach-target).">,
    Option<"features", "features", "std::string",
           /*default=*/"\"\"",
           "NVVM feature flags. Default is empty, which lets libNVVM "
           "pick the minimum required PTX version per chip and avoids "
           "the chip-vs-PTX-version floor errors that come from "
           "pinning. Set to e.g. `+ptx80` to lock the emitted PTX "
           "to a specific version (useful when shipping to older "
           "CUDA drivers with bounded PTX support).">,
    Option<"optLevel", "opt-level", "unsigned",
           /*default=*/"2",
           "Optimization level for the NVVM compiler.">
  ];

  let dependentDialects = [
    "::mlir::gpu::GPUDialect",
    "::mlir::LLVM::LLVMDialect",
    "::mlir::NVVM::NVVMDialect"
  ];
}

def EmitGPUBinary : Pass<"emit-gpu-binary", "::mlir::ModuleOp"> {
  let summary = "Compile each annotated gpu.module into a gpu.binary";
  let description = [{
    Wraps the upstream `gpu-module-to-binary` pass with cutlass_compiler-specific
    defaults. Each `gpu.module` carrying a `#nvvm.target<>` attribute
    (typically attached by `attach-nvvm-target`) is serialized into a
    `gpu.binary`.

    Default `compilation-target` is `isa` — produces text PTX, which
    is easy to inspect in LIT and does not require a working ptxas on
    `$PATH`. Switch to `bin` (cubin) or `fatbin` for runtime use.
  }];

  let options = [
    Option<"compilationTarget", "compilation-target", "std::string",
           /*default=*/"\"isa\"",
           "gpu-module-to-binary mode: `isa` (text PTX, default), "
           "`bin` (cubin), or `fatbin` (multi-arch).">
  ];

  let dependentDialects = [
    "::mlir::gpu::GPUDialect",
    "::mlir::LLVM::LLVMDialect",
    "::mlir::NVVM::NVVMDialect"
  ];
}

#endif // BASE_CONVERSION_BASE_TO_TARGETS_PASSES_TD
