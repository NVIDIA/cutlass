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

// RUN: base-opt -attach-nvvm-target "-attach-nvvm-target=chip=sm_90" \
// RUN:   -emit-gpu-binary=compilation-target=bin %s | FileCheck %s
//
// Multi-arch attach with compilation-target=bin produces one cubin per arch.
// Mirrors attach_target_chained_diff_opts.mlir (fatbin); only target differs.

// CHECK-LABEL: gpu.binary @kernel
// First #gpu.object: sm_80 with cubin payload (ELF magic).
// CHECK-SAME: #gpu.object<#nvvm.target<chip = "sm_80">,
// CHECK-SAME: bin = "\7FELF
// Second #gpu.object: sm_90 with cubin payload.
// CHECK-SAME: #gpu.object<#nvvm.target<chip = "sm_90">,
// CHECK-SAME: bin = "\7FELF
gpu.module @kernel {
  llvm.func @noop() attributes {gpu.kernel, nvvm.kernel} {
    llvm.return
  }
}
