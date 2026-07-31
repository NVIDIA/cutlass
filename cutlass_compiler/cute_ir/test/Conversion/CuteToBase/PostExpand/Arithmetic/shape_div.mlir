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

// Full pipeline lowering for `cute.shape_div`.

// -----
// Fully-static shape_div: folds to `ub.poison` of the empty result.
// CHECK-LABEL: func.func @shape_div_static_folds_to_poison
// CHECK:         ub.poison : !llvm.struct<()>
// CHECK-NEXT:    return
func.func @shape_div_static_folds_to_poison(
    %a: !cute.shape<"(8,10)">, %b: !cute.shape<"(2,5)">)
    -> !cute.shape<"(4,2)"> {
  %r = cute.shape_div(%a, %b)
       : (!cute.shape<"(8,10)">, !cute.shape<"(2,5)">)
      -> !cute.shape<"(4,2)">
  return %r : !cute.shape<"(4,2)">
}

// -----
// Dynamic lhs, static rhs.
// CHECK-LABEL: func.func @shape_div_dyn_lhs_static_rhs
// CHECK:         llvm.extractvalue %{{.+}}[0]
// CHECK:         llvm.extractvalue %{{.+}}[1]
// CHECK:         arith.constant 2 : i32
// CHECK:         arith.divsi %{{.+}}, %{{.+}} : i32
// CHECK:         arith.cmpi ne
// CHECK:         scf.if
// CHECK:         arith.constant 5 : i32
// CHECK:         arith.divsi %{{.+}}, %{{.+}} : i32
// CHECK:         arith.cmpi ne
// CHECK:         scf.if
// CHECK:         ub.poison : !llvm.struct<(i32, i32)>
// CHECK:         llvm.insertvalue
// CHECK:         llvm.insertvalue
// CHECK:         return
func.func @shape_div_dyn_lhs_static_rhs(
    %a: !cute.shape<"(?,?)">, %b: !cute.shape<"(2,5)">)
    -> !cute.shape<"(?,?)"> {
  %r = cute.shape_div(%a, %b)
       : (!cute.shape<"(?,?)">, !cute.shape<"(2,5)">)
      -> !cute.shape<"(?,?)">
  return %r : !cute.shape<"(?,?)">
}

// -----
// Both dynamic.
// CHECK-LABEL: func.func @shape_div_both_dyn
// CHECK:         llvm.extractvalue %{{.+}}[0]
// CHECK:         llvm.extractvalue %{{.+}}[1]
// CHECK:         llvm.extractvalue %{{.+}}[0]
// CHECK:         llvm.extractvalue %{{.+}}[1]
// CHECK:         arith.divsi %{{.+}}, %{{.+}} : i32
// CHECK:         arith.divsi %{{.+}}, %{{.+}} : i32
// CHECK:         ub.poison : !llvm.struct<(i32, i32)>
// CHECK:         llvm.insertvalue
// CHECK:         llvm.insertvalue
// CHECK:         return
func.func @shape_div_both_dyn(
    %a: !cute.shape<"(?,?)">, %b: !cute.shape<"(?,?)">)
    -> !cute.shape<"(?,?)"> {
  %r = cute.shape_div(%a, %b)
       : (!cute.shape<"(?,?)">, !cute.shape<"(?,?)">)
      -> !cute.shape<"(?,?)">
  return %r : !cute.shape<"(?,?)">
}

// -----
// Scalar dynamic lhs, static rhs.
// CHECK-LABEL: func.func @shape_div_scalar_dyn
// CHECK-NOT:     llvm.extractvalue
// CHECK:         arith.constant 4 : i32
// CHECK:         arith.divsi %{{.+}}, %{{.+}} : i32
// CHECK-NOT:     llvm.insertvalue
// CHECK:         return
func.func @shape_div_scalar_dyn(
    %a: !cute.shape<"?">, %b: !cute.shape<"4">)
    -> !cute.shape<"?"> {
  %r = cute.shape_div(%a, %b)
       : (!cute.shape<"?">, !cute.shape<"4">)
      -> !cute.shape<"?">
  return %r : !cute.shape<"?">
}

// -----
// Nested dynamic shape.
// CHECK-LABEL: func.func @shape_div_nested_dyn
// CHECK:         llvm.extractvalue %{{.+}}[0]
// CHECK:         llvm.extractvalue %{{.+}}[1]
// CHECK:         llvm.extractvalue %{{.+}}[2]
// CHECK:         arith.constant 2 : i32
// CHECK:         arith.divsi %{{.+}}, %{{.+}} : i32
// CHECK:         arith.constant 3 : i32
// CHECK:         arith.divsi %{{.+}}, %{{.+}} : i32
// CHECK:         arith.constant 5 : i32
// CHECK:         arith.divsi %{{.+}}, %{{.+}} : i32
// CHECK:         ub.poison : !llvm.struct<(i32, i32, i32)>
// CHECK:         llvm.insertvalue
// CHECK:         llvm.insertvalue
// CHECK:         llvm.insertvalue
// CHECK:         return
func.func @shape_div_nested_dyn(
    %a: !cute.shape<"((?,?),?)">, %b: !cute.shape<"((2,3),5)">)
    -> !cute.shape<"((?,?),?)"> {
  %r = cute.shape_div(%a, %b)
       : (!cute.shape<"((?,?),?)">, !cute.shape<"((2,3),5)">)
      -> !cute.shape<"((?,?),?)">
  return %r : !cute.shape<"((?,?),?)">
}
