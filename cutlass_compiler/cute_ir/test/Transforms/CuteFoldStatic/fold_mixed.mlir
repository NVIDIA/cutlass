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

// RUN: cute-opt -cute-fold-static --split-input-file %s | FileCheck %s

// cute-fold-static: only static ops are folded; dynamic ops are preserved.

// -----

// CHECK-LABEL: func.func @fold_static_keep_dynamic
// CHECK-SAME:  (%[[N:.+]]: i32)
// CHECK-DAG:     %[[STATIC:.+]] = cute.static : !cute.shape<"(2,4)">
// CHECK-DAG:     %[[DYN:.+]] = cute.make_shape(%[[N]]) : (i32) -> !cute.shape<"(?,4)">
// CHECK:         return %[[STATIC]], %[[DYN]] : !cute.shape<"(2,4)">, !cute.shape<"(?,4)">
func.func @fold_static_keep_dynamic(%n: i32) -> (!cute.shape<"(2,4)">, !cute.shape<"(?,4)">) {
  %s_static = cute.make_shape() : () -> !cute.shape<"(2,4)">
  %s_dyn = cute.make_shape(%n) : (i32) -> !cute.shape<"(?,4)">
  return %s_static, %s_dyn : !cute.shape<"(2,4)">, !cute.shape<"(?,4)">
}

// -----

// Dynamic producer with static-typed downstream op — only downstream folds.
// CHECK-LABEL: func.func @fold_static_tail
// CHECK-SAME:  (%[[N:.+]]: i32)
// CHECK-DAG:     %[[DYN:.+]] = cute.make_shape(%[[N]]) : (i32) -> !cute.shape<"(?,4)">
// CHECK-DAG:     %[[FOLDED:.+]] = cute.static : !cute.int_tuple<"8">
// CHECK:         return %[[DYN]], %[[FOLDED]]
func.func @fold_static_tail(%n: i32)
    -> (!cute.shape<"(?,4)">, !cute.int_tuple<"8">) {
  %s = cute.make_shape(%n) : (i32) -> !cute.shape<"(?,4)">
  %t = cute.make_int_tuple() : () -> !cute.int_tuple<"(2,4)">
  %p = cute.tuple_product(%t)
         : (!cute.int_tuple<"(2,4)">) -> !cute.int_tuple<"8">
  return %s, %p : !cute.shape<"(?,4)">, !cute.int_tuple<"8">
}
