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

// Full pipeline lowering for `cute.elem_less`.

// -----
// Fully-static, true result.
// CHECK-LABEL: func.func @elem_less_static_true
// CHECK-NOT:     llvm.extractvalue
// CHECK-NOT:     arith.cmpi
// CHECK:         %[[T:.+]] = arith.constant true
// CHECK:         return %[[T]]
func.func @elem_less_static_true(
    %a: !cute.int_tuple<"(3,4)">, %b: !cute.int_tuple<"(5,6)">) -> i1 {
  %r = cute.elem_less(%a, %b)
       : (!cute.int_tuple<"(3,4)">, !cute.int_tuple<"(5,6)">) -> i1
  return %r : i1
}

// -----
// Fully-static, false result.
// CHECK-LABEL: func.func @elem_less_static_false
// CHECK-NOT:     llvm.extractvalue
// CHECK-NOT:     arith.cmpi
// CHECK:         %[[F:.+]] = arith.constant false
// CHECK:         return %[[F]]
func.func @elem_less_static_false(
    %a: !cute.shape<"(7,4)">, %b: !cute.shape<"(5,6)">) -> i1 {
  %r = cute.elem_less(%a, %b)
       : (!cute.shape<"(7,4)">, !cute.shape<"(5,6)">) -> i1
  return %r : i1
}

// -----
// Dynamic int_tuple, i32 leaves.
// CHECK-LABEL: func.func @elem_less_dyn_int_tuple
// CHECK-NOT:     arith.constant true
// CHECK:         llvm.extractvalue %{{.+}}[0]
// CHECK:         llvm.extractvalue %{{.+}}[1]
// CHECK:         llvm.extractvalue %{{.+}}[0]
// CHECK:         llvm.extractvalue %{{.+}}[1]
// CHECK:         arith.cmpi slt, %{{.+}}, %{{.+}} : i32
// CHECK:         arith.cmpi slt, %{{.+}}, %{{.+}} : i32
// CHECK:         arith.andi
// CHECK:         return
func.func @elem_less_dyn_int_tuple(
    %a: !cute.int_tuple<"(?,?)">, %b: !cute.int_tuple<"(?,?)">) -> i1 {
  %r = cute.elem_less(%a, %b)
       : (!cute.int_tuple<"(?,?)">, !cute.int_tuple<"(?,?)">) -> i1
  return %r : i1
}

// -----
// Mixed-kind dynamic (coord vs shape).
// CHECK-LABEL: func.func @elem_less_dyn_mixed_kind
// CHECK-NOT:     arith.constant true
// CHECK:         llvm.extractvalue %{{.+}}[0]
// CHECK:         llvm.extractvalue %{{.+}}[1]
// CHECK:         llvm.extractvalue %{{.+}}[0]
// CHECK:         llvm.extractvalue %{{.+}}[1]
// CHECK:         arith.cmpi slt, %{{.+}}, %{{.+}} : i32
// CHECK:         arith.cmpi slt, %{{.+}}, %{{.+}} : i32
// CHECK:         arith.andi
// CHECK:         return
func.func @elem_less_dyn_mixed_kind(
    %a: !cute.coord<"(?,?)">, %b: !cute.shape<"(?,?)">) -> i1 {
  %r = cute.elem_less(%a, %b)
       : (!cute.coord<"(?,?)">, !cute.shape<"(?,?)">) -> i1
  return %r : i1
}

// -----
// Nested dynamic int_tuple.
// CHECK-LABEL: func.func @elem_less_dyn_nested
// CHECK-NOT:     arith.constant true
// CHECK:         llvm.extractvalue %{{.+}}[0]
// CHECK:         llvm.extractvalue %{{.+}}[1]
// CHECK:         llvm.extractvalue %{{.+}}[2]
// CHECK:         llvm.extractvalue %{{.+}}[0]
// CHECK:         llvm.extractvalue %{{.+}}[1]
// CHECK:         llvm.extractvalue %{{.+}}[2]
// CHECK:         arith.cmpi slt, %{{.+}}, %{{.+}} : i32
// CHECK:         arith.cmpi slt, %{{.+}}, %{{.+}} : i32
// CHECK:         arith.andi
// CHECK:         arith.cmpi slt, %{{.+}}, %{{.+}} : i32
// CHECK:         arith.andi
// CHECK:         return
func.func @elem_less_dyn_nested(
    %a: !cute.int_tuple<"((?,?),?)">, %b: !cute.int_tuple<"((?,?),?)">) -> i1 {
  %r = cute.elem_less(%a, %b)
       : (!cute.int_tuple<"((?,?),?)">, !cute.int_tuple<"((?,?),?)">) -> i1
  return %r : i1
}

// -----
// Dynamic int_tuple, i64 leaves.
// CHECK-LABEL: func.func @elem_less_dyn_i64
// CHECK-NOT:     arith.constant true
// CHECK-NOT:     arith.extsi
// CHECK:         llvm.extractvalue %{{.+}}[0] : !llvm.struct<(i64, i64)>
// CHECK:         llvm.extractvalue %{{.+}}[1] : !llvm.struct<(i64, i64)>
// CHECK:         llvm.extractvalue %{{.+}}[0] : !llvm.struct<(i64, i64)>
// CHECK:         llvm.extractvalue %{{.+}}[1] : !llvm.struct<(i64, i64)>
// CHECK:         arith.cmpi slt, %{{.+}}, %{{.+}} : i64
// CHECK:         arith.cmpi slt, %{{.+}}, %{{.+}} : i64
// CHECK:         arith.andi
// CHECK:         return
func.func @elem_less_dyn_i64(
    %a: !cute.int_tuple<"(?{i64},?{i64})">,
    %b: !cute.int_tuple<"(?{i64},?{i64})">) -> i1 {
  %r = cute.elem_less(%a, %b)
       : (!cute.int_tuple<"(?{i64},?{i64})">,
          !cute.int_tuple<"(?{i64},?{i64})">) -> i1
  return %r : i1
}

// -----
// Mixed-width dynamic (i64 lhs, i32 rhs): narrower side sign-extended.
// CHECK-LABEL: func.func @elem_less_dyn_width_promotion
// CHECK-NOT:     arith.constant true
// CHECK:         llvm.extractvalue %{{.+}}[0] : !llvm.struct<(i64, i64)>
// CHECK:         llvm.extractvalue %{{.+}}[1] : !llvm.struct<(i64, i64)>
// CHECK:         llvm.extractvalue %{{.+}}[0] : !llvm.struct<(i32, i32)>
// CHECK:         llvm.extractvalue %{{.+}}[1] : !llvm.struct<(i32, i32)>
// CHECK-DAG:     arith.extsi %{{.+}} : i32 to i64
// CHECK-DAG:     arith.extsi %{{.+}} : i32 to i64
// CHECK-DAG:     arith.cmpi slt, %{{.+}}, %{{.+}} : i64
// CHECK-DAG:     arith.cmpi slt, %{{.+}}, %{{.+}} : i64
// CHECK:         arith.andi
// CHECK:         return
func.func @elem_less_dyn_width_promotion(
    %a: !cute.int_tuple<"(?{i64},?{i64})">, %b: !cute.int_tuple<"(?,?)">) -> i1 {
  %r = cute.elem_less(%a, %b)
       : (!cute.int_tuple<"(?{i64},?{i64})">, !cute.int_tuple<"(?,?)">) -> i1
  return %r : i1
}
