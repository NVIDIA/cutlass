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

// Full pipeline lowering for `cute.tuple_product`.

// -----
// Fully-static int_tuple: cute.tuple_product folds at compile time.
// CHECK-LABEL: func.func @tp_static_int_tuple
// CHECK:         ub.poison : !llvm.struct<()>
// CHECK-NEXT:    return
func.func @tp_static_int_tuple(%arg0: !cute.int_tuple<"(2,(3,4))">)
    -> !cute.int_tuple<"24"> {
  %0 = cute.tuple_product(%arg0)
      : (!cute.int_tuple<"(2,(3,4))">) -> !cute.int_tuple<"24">
  return %0 : !cute.int_tuple<"24">
}

// -----
// Fully-static shape: same fold path, kind-preserving result.
// CHECK-LABEL: func.func @tp_static_shape
// CHECK:         ub.poison : !llvm.struct<()>
// CHECK-NEXT:    return
func.func @tp_static_shape(%arg0: !cute.shape<"(2,(3,4))">)
    -> !cute.shape<"24"> {
  %0 = cute.tuple_product(%arg0)
      : (!cute.shape<"(2,(3,4))">) -> !cute.shape<"24">
  return %0 : !cute.shape<"24">
}

// -----
// Empty int_tuple: empty product is the identity (1), fully static.
// CHECK-LABEL: func.func @tp_empty
// CHECK:         ub.poison : !llvm.struct<()>
// CHECK-NEXT:    return
func.func @tp_empty(%arg0: !cute.int_tuple<"()">) -> !cute.int_tuple<"1"> {
  %0 = cute.tuple_product(%arg0)
      : (!cute.int_tuple<"()">) -> !cute.int_tuple<"1">
  return %0 : !cute.int_tuple<"1">
}

// -----
// Scalar dynamic input.
// CHECK-LABEL: func.func @tp_scalar_dynamic
// CHECK-SAME:    [[ARG:%.+]]: i32
// CHECK:         return [[ARG]] : i32
func.func @tp_scalar_dynamic(%arg0: !cute.int_tuple<"?">) -> !cute.int_tuple<"?"> {
  %0 = cute.tuple_product(%arg0)
      : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
  return %0 : !cute.int_tuple<"?">
}

// -----
// Flat dynamic int_tuple: two dynamic leaves arrive in an LLVM struct;
// product is one `arith.muli`.
// CHECK-LABEL: func.func @tp_dyn_int_tuple
// CHECK-SAME:    [[ARG:%.+]]: !llvm.struct<(i32, i32)>
// CHECK:         [[A:%.+]] = llvm.extractvalue [[ARG]][0]
// CHECK:         [[B:%.+]] = llvm.extractvalue [[ARG]][1]
// CHECK:         [[R:%.+]] = arith.muli [[A]], [[B]] overflow<nsw> : i32
// CHECK:         return [[R]] : i32
func.func @tp_dyn_int_tuple(%arg0: !cute.int_tuple<"(?,?)">) -> !cute.int_tuple<"?"> {
  %0 = cute.tuple_product(%arg0)
      : (!cute.int_tuple<"(?,?)">) -> !cute.int_tuple<"?">
  return %0 : !cute.int_tuple<"?">
}

// -----
// Dynamic shape with one static factor: chain extractvalue + a static
// `arith.constant 3` + two `arith.muli` (the static factor materializes
// as a constant multiplied into the dynamic chain).
// CHECK-LABEL: func.func @tp_dyn_shape_div
// CHECK-SAME:    [[ARG:%.+]]: !llvm.struct<(i32, i32)>
// CHECK:         llvm.extractvalue [[ARG]][0]
// CHECK:         llvm.extractvalue [[ARG]][1]
// CHECK:         arith.constant 3 : i32
// CHECK-COUNT-2: arith.muli {{.+}} overflow<nsw> : i32
// CHECK-NOT:     arith.muli
// CHECK:         return {{.+}} : i32
func.func @tp_dyn_shape_div(%arg0: !cute.shape<"(?,(3,?))">)
    -> !cute.shape<"?"> {
  %0 = cute.tuple_product(%arg0)
      : (!cute.shape<"(?,(3,?))">) -> !cute.shape<"?">
  return %0 : !cute.shape<"?">
}
