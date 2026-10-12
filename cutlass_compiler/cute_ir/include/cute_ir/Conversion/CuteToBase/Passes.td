//===-- Passes.td - cute->base conversion pass definitions -*- tablegen -*-===//
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

#ifndef CUTE_IR_CONVERSION_CUTE_TO_BASE_PASSES_TD
#define CUTE_IR_CONVERSION_CUTE_TO_BASE_PASSES_TD

include "mlir/Pass/PassBase.td"

def CuteExpandOps : Pass<"cute-expand-ops"> {
  let summary = "Expand selected cute ops via dialect conversion patterns";
  let description = [{
    Partial dialect conversion that rewrites high-level cute algebra ops into
    sequences of constructor (``make_*``) ops + ``arith``/``scf`` ops. The base
    constructor ops, ``cute.static``, ``cute.print``, and ``cute.get_scalars`` are
    left legal and are lowered later by ``cute-to-base``.

    Each illegal op rewrites to one of two shapes:

    ```mlir
    // Static result -> fold to cute.static
    %res = cute.algebra_op(%input) : ... -> !type_with_static_modes
    return %res : !type_with_static_modes

    // Becomes:
    %res = cute.static : !type_with_static_modes
    return %res : !type_with_static_modes

    // Dynamic result -> extract dynamic leaves and rebuild via constructors
    %res = cute.algebra_op(%input) : ... -> !type_with_dynamic_modes
    return %res : !type_with_dynamic_modes

    // Becomes:
    %scalars = cute.get_scalars(%input) <{only_dynamic}> : ...
    %t0 = arith.<...>(%scalars#0, %scalars#1) : ...
    ...
    %res = cute.make_<...>(%t0, ...) : !type_with_dynamic_modes
    return %res : !type_with_dynamic_modes
    ```
  }];

  let dependentDialects = [
    "::mlir::arith::ArithDialect",
    "::mlir::math::MathDialect",
    "::mlir::scf::SCFDialect",
    "::mlir::cutlass_compiler::cute::CuteDialect"
  ];
}

def CuteToBase : Pass<"cute-to-base"> {
  let summary = "Lower remaining cute ops to base dialects (LLVM/arith/scf/ub)";
  let description = [{
    Full dialect conversion from ``cute`` to LLVM/arith/scf/ub. Applied after
    ``cute-expand-ops`` has reduced the IR to the 10 surviving constructor /
    static / print / get_scalars ops, this pass lowers each of
    those ops along with all cute types.

    Type conversion: every cute type maps to an LLVM struct holding the
    dynamic leaves only (cutegen's ``llvm_type_sparse_flat_t``):

    - ``!cute.shape``/``stride``/``int_tuple``/``coord``/``tile`` → ``LLVM struct``
      of dynamic-leaf integers.

    - ``!cute.layout`` → ``LLVM struct(shape_struct, stride_struct)``.
    - ``!cute.composed_layout`` →
      ``LLVM struct(inner_struct, offset_struct, outer_struct)``.

    - ``!cute.swizzle`` → ``LLVM struct()`` (empty).

    Lowers ``cute.static``, ``cute.get_scalars``, the 7 constructor ops
    (``make_*``), and ``cute.print`` — ``cute.print`` emits ``gpu.printf``
    inside a GPU module/launch and falls back to ``llvm.call @printf``
    (with a generated ``llvm.mlir.global`` format string) on the host.

  }];

  let dependentDialects = [
    "::mlir::arith::ArithDialect",
    "::mlir::scf::SCFDialect",
    "::mlir::ub::UBDialect",
    "::mlir::LLVM::LLVMDialect",
    "::mlir::gpu::GPUDialect",
    "::mlir::cutlass_compiler::cute::CuteDialect"
  ];
}

#endif // CUTE_IR_CONVERSION_CUTE_TO_BASE_PASSES_TD
