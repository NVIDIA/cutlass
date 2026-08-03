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

// RUN: cute-opt -cute-expand-ops --split-input-file %s | FileCheck %s

// Tests `cute-expand-ops` lowering for `cute.composed_get_offset`.

// -----

// CHECK-LABEL: func.func @expand_static
// CHECK-NOT:   cute.composed_get_offset
// CHECK:       cute.static : !cute.int_tuple<"2">
func.func @expand_static(
    %cl: !cute.composed_layout<"(4,8):(1,4) o 2 o (2,4):(1,2)">)
    -> !cute.int_tuple<"2"> {
  %r = cute.composed_get_offset(%cl)
         : !cute.composed_layout<"(4,8):(1,4) o 2 o (2,4):(1,2)">
        -> !cute.int_tuple<"2">
  return %r : !cute.int_tuple<"2">
}

// -----

// CHECK-LABEL: func.func @expand_dynamic
// CHECK-NOT:   cute.composed_get_offset
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       %[[R:.+]] = cute.make_int_tuple
// CHECK-SAME:            -> !cute.int_tuple<"?">
func.func @expand_dynamic(
    %cl: !cute.composed_layout<"(4,8):(1,4) o ? o (2,4):(1,2)">)
    -> !cute.int_tuple<"?"> {
  %r = cute.composed_get_offset(%cl)
         : !cute.composed_layout<"(4,8):(1,4) o ? o (2,4):(1,2)">
        -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}

// -----

// Dynamic tuple offset — exercises the multi-leaf `buildArithTuple`
// path: cgInput.offset() produces a 2-leaf int_tuple `(?,?)` that
// rebuilds via `cute.make_int_tuple(%0#0, %0#1)` rather than the
// scalar bare-i32 form from `@expand_dynamic`.
// CHECK-LABEL: func.func @expand_dyn_tuple_offset
// CHECK-NOT:   cute.composed_get_offset
// CHECK:       %[[D:.+]]:2 = cute.get_scalars<{only_dynamic}>
// CHECK:       %[[R:.+]] = cute.make_int_tuple(%[[D]]#0, %[[D]]#1)
// CHECK-SAME:            -> !cute.int_tuple<"(?,?)">
func.func @expand_dyn_tuple_offset(
    %cl: !cute.composed_layout<"(4,8):(1,4) o (?,?) o (2,4):(1,2)">)
    -> !cute.int_tuple<"(?,?)"> {
  %r = cute.composed_get_offset(%cl)
         : !cute.composed_layout<"(4,8):(1,4) o (?,?) o (2,4):(1,2)">
        -> !cute.int_tuple<"(?,?)">
  return %r : !cute.int_tuple<"(?,?)">
}
