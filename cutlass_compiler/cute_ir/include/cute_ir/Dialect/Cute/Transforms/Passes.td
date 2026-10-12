//===-- Passes.td - Cute transform pass definitions -----------*- tablegen -*-===//
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

#ifndef CUTE_IR_DIALECT_CUTE_TRANSFORMS_PASSES_TD
#define CUTE_IR_DIALECT_CUTE_TRANSFORMS_PASSES_TD

include "mlir/Pass/PassBase.td"

def CuteFoldStatic : Pass<"cute-fold-static"> {
  let summary = "DCE and fold pure ops with static cute results to cute.static";
  let description = [{
    Eliminates dead pure operations and replaces fully static cute SSA values
    with ``cute.static``.

    Before:

    ```mlir
    %shape = cute.make_shape() : () -> !cute.shape<"(2,4,1)">
    %stride = cute.make_stride() : () -> !cute.stride<"(1,2,4)">
    %layout = cute.make_layout(%shape, %stride)
      : (!cute.shape<"(2,4,1)">, !cute.stride<"(1,2,4)">)
      -> !cute.layout<"(2,4,1):(1,2,4)">
    ```

    After:

    ```mlir
    %layout = cute.static : !cute.layout<"(2,4,1):(1,2,4)">
    ```

    ``cute.equal`` and ``cute.elem_less`` produce ``i1`` results, which the
    generic static-result rule above doesn't catch. The pass folds them
    explicitly to ``arith.constant <bool>`` when both operands carry static
    cute types.
  }];

  let dependentDialects = [
    "::mlir::arith::ArithDialect",
    "::mlir::cutlass_compiler::cute::CuteDialect"
  ];
}

#endif // CUTE_IR_DIALECT_CUTE_TRANSFORMS_PASSES_TD
