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

//===- cutlass-lsp-server.cpp - MLIR LSP server for cutlass_compiler -===//
//
// `cutlass-lsp-server` speaks the Language Server Protocol so editors can
// offer hover, go-to-definition, and diagnostics on `.mlir` files that use
// the cute and base dialects together with upstream MLIR dialects.
//
// It registers:
//   - every upstream MLIR dialect (`registerAllDialects` /
//     `registerAllExtensions`), so cross-dialect `.mlir` files resolve
//     cleanly;
//   - the cute layer (via `cutlass_compiler::cute::registerCuteDialects`);
//   - the base layer (via `cutlass_compiler::base::registerBaseDialects`).
//
// Point your editor's MLIR LSP client at the built binary at
// `<build>/tools/cutlass-lsp-server/cutlass-lsp-server`.
//
//===----------------------------------------------------------------------===//

#include "base/Registration/Registration.h"
#include "cute_ir/Registration/Registration.h"

#include "mlir/IR/DialectRegistry.h"
#include "mlir/InitAllDialects.h"
#include "mlir/InitAllExtensions.h"
#include "mlir/Tools/mlir-lsp-server/MlirLspServerMain.h"

using namespace mlir;

int main(int argc, char **argv) {
  DialectRegistry registry;

  // Upstream MLIR dialects + extensions — the LSP has to hover / complete
  // anything the user might have in their `.mlir` file, not just the two
  // layers this project owns.
  registerAllDialects(registry);
  registerAllExtensions(registry);

  // Cute layer.
  cutlass_compiler::cute::registerCuteDialects(registry);

  // Base layer.
  cutlass_compiler::base::registerBaseDialects(registry);

  return failed(MlirLspServerMain(argc, argv, registry));
}
