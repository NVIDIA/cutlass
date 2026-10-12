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

// RUN: base-opt -one-shot-convert-to-llvm %s | FileCheck %s

// Tests `one-shot-convert-to-llvm` lowering of arith ops on the host
// side.

// CHECK-LABEL: llvm.func @arith_ops
// CHECK-SAME:    (%[[A:.+]]: i32, %[[B:.+]]: i32)
// CHECK-NOT:     arith.
// CHECK:         %[[ADD:.+]] = llvm.add %[[A]], %[[B]]
// CHECK:         %[[SUB:.+]] = llvm.sub %[[A]], %[[B]]
// CHECK:         %[[MUL:.+]] = llvm.mul %[[A]], %[[B]]
// CHECK:         %[[DIV:.+]] = llvm.sdiv %[[A]], %[[B]]
// CHECK:         %[[CMP:.+]] = llvm.icmp "slt" %[[A]], %[[B]]
// CHECK:         llvm.return
func.func @arith_ops(%a: i32, %b: i32) -> (i32, i32, i32, i32, i1) {
  %add = arith.addi %a, %b : i32
  %sub = arith.subi %a, %b : i32
  %mul = arith.muli %a, %b : i32
  %div = arith.divsi %a, %b : i32
  %cmp = arith.cmpi slt, %a, %b : i32
  return %add, %sub, %mul, %div, %cmp : i32, i32, i32, i32, i1
}
