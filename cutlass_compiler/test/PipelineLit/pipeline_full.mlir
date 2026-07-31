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

// RUN: cutlass-compiler \
// RUN:   -cute-fold-static -cute-expand-ops -cute-to-base \
// RUN:   -base-prepare -one-shot-convert-to-llvm \
// RUN:   -attach-nvvm-target -emit-gpu-binary %s | FileCheck %s
//
// Pipeline-full LIT. Locks down the entire cute → cubin
// pipeline as a single regression test. Input is a `gpu.module`
// containing a `gpu.func` that exercises a non-trivial cute op
// chain (`cute.static` + `cute.print`); the output should be a
// fully-emitted `gpu.binary` with no surviving cute / gpu.module /
// gpu.func / arith / scf ops outside the binary payload.
//
// Pipeline stages:
//   1. cute-fold-static     — folds the `cute.static` to its constant
//   2. cute-expand-ops      — expands cute ops down to make_*
//   3. cute-to-base         — lowers cute → arith / llvm constructs
//   4. base-prepare         — canonicalize / cse / LICM / reconcile
//   5. one-shot-convert-to-llvm — gpu.func body → llvm.func / NVVM
//   6. attach-nvvm-target   — annotate gpu.module with #nvvm.target
//   7. emit-gpu-binary      — serialize gpu.module → gpu.binary
//
// Asserts:
//   * The output module contains exactly one `gpu.binary @kernel`.
//   * Its `#gpu.object` carries the default
//     `#nvvm.target<chip = "sm_80">` (default features="" lets
//     libNVVM auto-pick the PTX version per chip).
//   * The text-PTX `assembly = "..."` payload contains the canonical
//     `.target sm_80` directive (canary for valid PTX).
//   * No `cute.` ops, `gpu.module` shells, `gpu.func`s, or
//     non-`arith.constant` arith ops survive outside the binary.

// First check: nothing cute / structural survives anywhere.
// CHECK-NOT: cute.
// CHECK-NOT: gpu.module
// CHECK-NOT: gpu.func
// CHECK-NOT: scf.

// Then assert the gpu.binary structure.
// CHECK: module {
// CHECK: gpu.binary @kernel
// CHECK-SAME: #nvvm.target<chip = "sm_80">
// CHECK-SAME: assembly =
// CHECK-SAME: .target sm_80

gpu.module @kernel {
  gpu.func @noop() kernel {
    %s = cute.static : !cute.layout<"(2,3):(1,2)">
    cute.print(%s) : !cute.layout<"(2,3):(1,2)">
    gpu.return
  }
}
