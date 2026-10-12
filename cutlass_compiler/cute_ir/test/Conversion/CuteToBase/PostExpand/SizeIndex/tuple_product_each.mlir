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

// Full pipeline lowering for `cute.tuple_product_each`.

// -----
// Fully-static int_tuple: per-mode product folds.
// CHECK-LABEL: func.func @tpe_static_int_tuple
// CHECK:         ub.poison : !llvm.struct<()>
// CHECK-NEXT:    return
func.func @tpe_static_int_tuple(%arg0: !cute.int_tuple<"(2,(3,4))">)
    -> !cute.int_tuple<"(2,12)"> {
  %0 = cute.tuple_product_each(%arg0)
      : (!cute.int_tuple<"(2,(3,4))">) -> !cute.int_tuple<"(2,12)">
  return %0 : !cute.int_tuple<"(2,12)">
}

// -----
// Fully-static shape (flat, already depth-1): identity fold.
// CHECK-LABEL: func.func @tpe_static_shape
// CHECK:         ub.poison : !llvm.struct<()>
// CHECK-NEXT:    return
func.func @tpe_static_shape(%arg0: !cute.shape<"(4,3,2)">)
    -> !cute.shape<"(4,3,2)"> {
  %0 = cute.tuple_product_each(%arg0)
      : (!cute.shape<"(4,3,2)">) -> !cute.shape<"(4,3,2)">
  return %0 : !cute.shape<"(4,3,2)">
}

// -----
// Empty int_tuple: result is the empty tuple, fully static.
// CHECK-LABEL: func.func @tpe_empty
// CHECK:         ub.poison : !llvm.struct<()>
// CHECK-NEXT:    return
func.func @tpe_empty(%arg0: !cute.int_tuple<"()">) -> !cute.int_tuple<"()"> {
  %0 = cute.tuple_product_each(%arg0)
      : (!cute.int_tuple<"()">) -> !cute.int_tuple<"()">
  return %0 : !cute.int_tuple<"()">
}

// -----
// Scalar dynamic input.
// CHECK-LABEL: func.func @tpe_scalar_dynamic
// CHECK-SAME:    [[ARG:%.+]]: i32
// CHECK:         return [[ARG]] : i32
func.func @tpe_scalar_dynamic(%arg0: !cute.int_tuple<"?">)
    -> !cute.int_tuple<"(?)"> {
  %0 = cute.tuple_product_each(%arg0)
      : (!cute.int_tuple<"?">) -> !cute.int_tuple<"(?)">
  return %0 : !cute.int_tuple<"(?)">
}

// -----
// Flat dynamic int_tuple.
// of its input leaf, but the result struct is rebuilt via ub.poison + 2
// insertvalues (since the dialect emits a fresh struct rather than
// `unrealized_conversion_cast`-ing through).
// CHECK-LABEL: func.func @tpe_flat_dyn
// CHECK-SAME:    [[ARG:%.+]]: !llvm.struct<(i32, i32)>
// CHECK:         [[A:%.+]] = llvm.extractvalue [[ARG]][0]
// CHECK:         [[B:%.+]] = llvm.extractvalue [[ARG]][1]
// CHECK:         [[P:%.+]] = ub.poison : !llvm.struct<(i32, i32)>
// CHECK:         [[I0:%.+]] = llvm.insertvalue [[A]], [[P]][0]
// CHECK:         [[I1:%.+]] = llvm.insertvalue [[B]], [[I0]][1]
// CHECK:         return [[I1]] : !llvm.struct<(i32, i32)>
func.func @tpe_flat_dyn(%arg0: !cute.int_tuple<"(?,?)">)
    -> !cute.int_tuple<"(?,?)"> {
  %0 = cute.tuple_product_each(%arg0)
      : (!cute.int_tuple<"(?,?)">) -> !cute.int_tuple<"(?,?)">
  return %0 : !cute.int_tuple<"(?,?)">
}

// -----
// Dynamic shape `(?,(3,?))` → `(?,?)`: mode 0 is a passthrough,
// mode 1 multiplies the dynamic leaf by the static factor 3, then the
// result struct is rebuilt.
// CHECK-LABEL: func.func @tpe_dyn_shape
// CHECK-SAME:    [[ARG:%.+]]: !llvm.struct<(i32, i32)>
// CHECK:         [[A:%.+]] = llvm.extractvalue [[ARG]][0]
// CHECK:         [[B:%.+]] = llvm.extractvalue [[ARG]][1]
// CHECK:         [[C3:%.+]] = arith.constant 3 : i32
// CHECK:         [[M:%.+]] = arith.muli [[B]], [[C3]] overflow<nsw> : i32
// CHECK:         [[P:%.+]] = ub.poison : !llvm.struct<(i32, i32)>
// CHECK:         [[I0:%.+]] = llvm.insertvalue [[A]], [[P]][0]
// CHECK:         [[I1:%.+]] = llvm.insertvalue [[M]], [[I0]][1]
// CHECK:         return [[I1]] : !llvm.struct<(i32, i32)>
func.func @tpe_dyn_shape(%arg0: !cute.shape<"(?,(3,?))">)
    -> !cute.shape<"(?,?)"> {
  %0 = cute.tuple_product_each(%arg0)
      : (!cute.shape<"(?,(3,?))">) -> !cute.shape<"(?,?)">
  return %0 : !cute.shape<"(?,?)">
}
