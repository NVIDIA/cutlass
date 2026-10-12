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

// Tests `cute-expand-ops` lowering for `cute.equal`.
// Static same-type operands fold via Type identity; dynamic expands to per-leaf cmpi AND-chain.

// -----

// Static int_tuple, identical type ⇒ folds to `arith.constant true`.
// CHECK-LABEL: func.func @expand_int_tuple_static_true
// CHECK-NOT:   cute.equal
// CHECK-NOT:   cute.get_scalars
// CHECK:       %[[R:.+]] = arith.constant true
// CHECK:       return %[[R]]
func.func @expand_int_tuple_static_true(%a: !cute.int_tuple<"(3,4)">,
                                         %b: !cute.int_tuple<"(3,4)">) -> i1 {
  %r = cute.equal(%a, %b)
         : (!cute.int_tuple<"(3,4)">, !cute.int_tuple<"(3,4)">) -> i1
  return %r : i1
}

// -----

// Static shape, distinct types ⇒ folds to `arith.constant false`.
// CHECK-LABEL: func.func @expand_shape_static_false
// CHECK-NOT:   cute.equal
// CHECK-NOT:   cute.get_scalars
// CHECK:       %[[R:.+]] = arith.constant false
// CHECK:       return %[[R]]
func.func @expand_shape_static_false(%a: !cute.shape<"(3,4)">,
                                      %b: !cute.shape<"(3,5)">) -> i1 {
  %r = cute.equal(%a, %b)
         : (!cute.shape<"(3,4)">, !cute.shape<"(3,5)">) -> i1
  return %r : i1
}

// -----

// Static coord, identical types ⇒ true.
// CHECK-LABEL: func.func @expand_coord
// CHECK-NOT:   cute.equal
// CHECK-NOT:   cute.get_scalars
// CHECK:       %[[R:.+]] = arith.constant true
// CHECK:       return %[[R]]
func.func @expand_coord(%a: !cute.coord<"(0,1)">,
                         %b: !cute.coord<"(0,1)">) -> i1 {
  %r = cute.equal(%a, %b)
         : (!cute.coord<"(0,1)">, !cute.coord<"(0,1)">) -> i1
  return %r : i1
}

// -----

// Dynamic int_tuple — per-leaf eq on i32.
// CHECK-LABEL: func.func @expand_int_tuple_dynamic
// CHECK-NOT:   cute.equal
// CHECK:       cute.get_scalars (%{{.+}}) : !cute.int_tuple<"(?,?)">
// CHECK:       cute.get_scalars (%{{.+}}) : !cute.int_tuple<"(?,?)">
// CHECK-DAG:   arith.cmpi eq, %{{.+}}, %{{.+}} : i32
// CHECK-DAG:   arith.cmpi eq, %{{.+}}, %{{.+}} : i32
// CHECK:       return
func.func @expand_int_tuple_dynamic(%a: !cute.int_tuple<"(?,?)">,
                                     %b: !cute.int_tuple<"(?,?)">) -> i1 {
  %r = cute.equal(%a, %b)
         : (!cute.int_tuple<"(?,?)">, !cute.int_tuple<"(?,?)">) -> i1
  return %r : i1
}

// -----

// Dynamic layout: per-leaf eq across shape and stride leaves.
// CHECK-LABEL: func.func @expand_layout
// CHECK-NOT:   cute.equal
// CHECK:       cute.get_scalars (%{{.+}}) : !cute.layout<"(?,?):(1,?)">
// CHECK:       cute.get_scalars (%{{.+}}) : !cute.layout<"(?,?):(1,?)">
// CHECK-DAG:   arith.cmpi eq, %{{.+}}, %{{.+}} : i32
// CHECK-DAG:   arith.cmpi eq, %{{.+}}, %{{.+}} : i32
// CHECK-DAG:   arith.cmpi eq, %{{.+}}, %{{.+}} : i32
// CHECK-DAG:   arith.cmpi eq, %{{.+}}, %{{.+}} : i32
// CHECK:       return
func.func @expand_layout(%a: !cute.layout<"(?,?):(1,?)">,
                          %b: !cute.layout<"(?,?):(1,?)">) -> i1 {
  %r = cute.equal(%a, %b)
         : (!cute.layout<"(?,?):(1,?)">, !cute.layout<"(?,?):(1,?)">) -> i1
  return %r : i1
}

// -----

// Dynamic stride, i32 leaves.
// CHECK-LABEL: func.func @expand_stride_dynamic
// CHECK-NOT:   cute.equal
// CHECK:       cute.get_scalars (%{{.+}}) : !cute.stride<"(1,?)">
// CHECK:       cute.get_scalars (%{{.+}}) : !cute.stride<"(1,?)">
// CHECK-DAG:   arith.cmpi eq, %{{.+}}, %{{.+}} : i32
// CHECK-DAG:   arith.cmpi eq, %{{.+}}, %{{.+}} : i32
// CHECK:       return
func.func @expand_stride_dynamic(%a: !cute.stride<"(1,?)">,
                                  %b: !cute.stride<"(1,?)">) -> i1 {
  %r = cute.equal(%a, %b)
         : (!cute.stride<"(1,?)">, !cute.stride<"(1,?)">) -> i1
  return %r : i1
}

// -----

// Dynamic int_tuple, i64 leaves.
// CHECK-LABEL: func.func @expand_dyn_i64
// CHECK-NOT:   cute.equal
// CHECK:       cute.get_scalars (%{{.+}}) : !cute.int_tuple<"(?{i64},?{i64})">
// CHECK:       cute.get_scalars (%{{.+}}) : !cute.int_tuple<"(?{i64},?{i64})">
// CHECK-DAG:   arith.cmpi eq, %{{.+}}, %{{.+}} : i64
// CHECK-DAG:   arith.cmpi eq, %{{.+}}, %{{.+}} : i64
// CHECK:       arith.andi
// CHECK:       return
func.func @expand_dyn_i64(%a: !cute.int_tuple<"(?{i64},?{i64})">,
                          %b: !cute.int_tuple<"(?{i64},?{i64})">) -> i1 {
  %r = cute.equal(%a, %b)
         : (!cute.int_tuple<"(?{i64},?{i64})">,
            !cute.int_tuple<"(?{i64},?{i64})">) -> i1
  return %r : i1
}

// -----

// Mixed-width dynamic (i64 lhs, i32 rhs): narrower side sign-extended to i64.
// CHECK-LABEL: func.func @expand_dyn_width_promotion
// CHECK-NOT:   cute.equal
// CHECK:       cute.get_scalars (%{{.+}}) : !cute.int_tuple<"(?{i64},?{i64})">
// CHECK:       cute.get_scalars (%{{.+}}) : !cute.int_tuple<"(?,?)">
// CHECK-DAG:   arith.extsi %{{.+}} : i32 to i64
// CHECK-DAG:   arith.extsi %{{.+}} : i32 to i64
// CHECK-DAG:   arith.cmpi eq, %{{.+}}, %{{.+}} : i64
// CHECK-DAG:   arith.cmpi eq, %{{.+}}, %{{.+}} : i64
// CHECK:       arith.andi
// CHECK:       return
func.func @expand_dyn_width_promotion(%a: !cute.int_tuple<"(?{i64},?{i64})">,
                                       %b: !cute.int_tuple<"(?,?)">) -> i1 {
  %r = cute.equal(%a, %b)
         : (!cute.int_tuple<"(?{i64},?{i64})">,
            !cute.int_tuple<"(?,?)">) -> i1
  return %r : i1
}
