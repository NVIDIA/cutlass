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

// RUN: cute-opt -cute-fold-static -cute-expand-ops -cute-to-base \
// RUN:   --split-input-file %s \
// RUN:   | cute-opt -reconcile-unrealized-casts --split-input-file \
// RUN:   | FileCheck %s

// Full pipeline lowering for `cute.ceil_div`.

// -----
// Fully-static ceil_div: folds to `ub.poison`.
// CHECK-LABEL: func.func @ceil_div_static_folds_to_poison
// CHECK:         ub.poison : !llvm.struct<()>
// CHECK-NEXT:    return
func.func @ceil_div_static_folds_to_poison(
    %a: !cute.int_tuple<"(8,10)">, %b: !cute.int_tuple<"(3,4)">)
    -> !cute.int_tuple<"(3,3)"> {
  %r = cute.ceil_div(%a, %b)
       : (!cute.int_tuple<"(8,10)">, !cute.int_tuple<"(3,4)">)
      -> !cute.int_tuple<"(3,3)">
  return %r : !cute.int_tuple<"(3,3)">
}

// -----
// Dyn lhs, static rhs: per-mode `arith.ceildivsi` against the rhs
// constant, then repack via insertvalue.
// CHECK-LABEL: func.func @ceil_div_dyn_lhs_static_rhs
// CHECK:         llvm.extractvalue %{{.+}}[0]
// CHECK:         llvm.extractvalue %{{.+}}[1]
// CHECK:         arith.constant 3 : i32
// CHECK:         arith.ceildivsi %{{.+}}, %{{.+}} : i32
// CHECK:         arith.constant 4 : i32
// CHECK:         arith.ceildivsi %{{.+}}, %{{.+}} : i32
// CHECK:         ub.poison : !llvm.struct<(i32, i32)>
// CHECK:         llvm.insertvalue
// CHECK:         llvm.insertvalue
// CHECK:         return
func.func @ceil_div_dyn_lhs_static_rhs(
    %a: !cute.int_tuple<"(?,?)">, %b: !cute.int_tuple<"(3,4)">)
    -> !cute.int_tuple<"(?,?)"> {
  %r = cute.ceil_div(%a, %b)
       : (!cute.int_tuple<"(?,?)">, !cute.int_tuple<"(3,4)">)
      -> !cute.int_tuple<"(?,?)">
  return %r : !cute.int_tuple<"(?,?)">
}

// -----
// Both dyn: no constants; `arith.ceildivsi` on extracted SSA
// values directly.
// CHECK-LABEL: func.func @ceil_div_both_dyn
// CHECK:         llvm.extractvalue %{{.+}}[0]
// CHECK:         llvm.extractvalue %{{.+}}[1]
// CHECK:         llvm.extractvalue %{{.+}}[0]
// CHECK:         llvm.extractvalue %{{.+}}[1]
// CHECK-NOT:     arith.constant
// CHECK:         arith.ceildivsi %{{.+}}, %{{.+}} : i32
// CHECK:         arith.ceildivsi %{{.+}}, %{{.+}} : i32
// CHECK:         ub.poison : !llvm.struct<(i32, i32)>
// CHECK:         llvm.insertvalue
// CHECK:         llvm.insertvalue
// CHECK:         return
func.func @ceil_div_both_dyn(
    %a: !cute.int_tuple<"(?,?)">, %b: !cute.int_tuple<"(?,?)">)
    -> !cute.int_tuple<"(?,?)"> {
  %r = cute.ceil_div(%a, %b)
       : (!cute.int_tuple<"(?,?)">, !cute.int_tuple<"(?,?)">)
      -> !cute.int_tuple<"(?,?)">
  return %r : !cute.int_tuple<"(?,?)">
}

// -----
// Scalar dyn lhs, static rhs: sparse_flat collapses to bare `i32`
// + single `arith.ceildivsi`.
// CHECK-LABEL: func.func @ceil_div_scalar_dyn
// CHECK-NOT:     llvm.extractvalue
// CHECK:         arith.constant 3 : i32
// CHECK:         arith.ceildivsi %{{.+}}, %{{.+}} : i32
// CHECK-NOT:     arith.ceildivsi
// CHECK:         return %{{.+}} : i32
func.func @ceil_div_scalar_dyn(
    %a: !cute.int_tuple<"?">, %b: !cute.int_tuple<"3">)
    -> !cute.int_tuple<"?"> {
  %r = cute.ceil_div(%a, %b)
       : (!cute.int_tuple<"?">, !cute.int_tuple<"3">)
      -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}

// -----
// Nested dyn: rank-3 chain — 3× extract + 3× (constant +
// arith.ceildivsi) + 3× insertvalue.
// CHECK-LABEL: func.func @ceil_div_nested_dyn
// CHECK:         llvm.extractvalue %{{.+}}[0]
// CHECK:         llvm.extractvalue %{{.+}}[1]
// CHECK:         llvm.extractvalue %{{.+}}[2]
// CHECK:         arith.constant 3 : i32
// CHECK:         arith.ceildivsi %{{.+}}, %{{.+}} : i32
// CHECK:         arith.constant 4 : i32
// CHECK:         arith.ceildivsi %{{.+}}, %{{.+}} : i32
// CHECK:         arith.constant 5 : i32
// CHECK:         arith.ceildivsi %{{.+}}, %{{.+}} : i32
// CHECK:         ub.poison : !llvm.struct<(i32, i32, i32)>
// CHECK:         llvm.insertvalue
// CHECK:         llvm.insertvalue
// CHECK:         llvm.insertvalue
// CHECK:         return
func.func @ceil_div_nested_dyn(
    %a: !cute.int_tuple<"((?,?),?)">, %b: !cute.int_tuple<"((3,4),5)">)
    -> !cute.int_tuple<"((?,?),?)"> {
  %r = cute.ceil_div(%a, %b)
       : (!cute.int_tuple<"((?,?),?)">, !cute.int_tuple<"((3,4),5)">)
      -> !cute.int_tuple<"((?,?),?)">
  return %r : !cute.int_tuple<"((?,?),?)">
}
