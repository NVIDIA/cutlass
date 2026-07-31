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

// RUN: cute-opt %s -split-input-file | FileCheck %s
// RUN: cute-opt %s -split-input-file | cute-opt | FileCheck %s
// RUN: cute-opt -mlir-print-op-generic %s -split-input-file | cute-opt | FileCheck %s

// Tests round-trip for cute.tuple_product_each.

// -----

// Flat shape: each element is already a leaf, result is unchanged. Result
// kind matches input kind (shape -> shape).
// CHECK-LABEL: func.func @product_each_flat_shape
// CHECK-SAME:  (%[[SRC:.+]]: !cute.shape<"(4,3,2)">)
func.func @product_each_flat_shape(%src: !cute.shape<"(4,3,2)">) -> !cute.shape<"(4,3,2)"> {
  // CHECK: %[[R:.+]] = cute.tuple_product_each(%[[SRC]]) : (!cute.shape<"(4,3,2)">) -> !cute.shape<"(4,3,2)">
  %r = cute.tuple_product_each(%src) : (!cute.shape<"(4,3,2)">) -> !cute.shape<"(4,3,2)">
  return %r : !cute.shape<"(4,3,2)">
}

// -----

// Nested int_tuple: each top-level element's subtree is collapsed to its product.
// CHECK-LABEL: func.func @product_each_nested_int_tuple
// CHECK-SAME:  (%[[SRC:.+]]: !cute.int_tuple<"(2,(3,4))">)
func.func @product_each_nested_int_tuple(%src: !cute.int_tuple<"(2,(3,4))">) -> !cute.int_tuple<"(2,12)"> {
  // CHECK: %[[R:.+]] = cute.tuple_product_each(%[[SRC]]) : (!cute.int_tuple<"(2,(3,4))">) -> !cute.int_tuple<"(2,12)">
  %r = cute.tuple_product_each(%src) : (!cute.int_tuple<"(2,(3,4))">) -> !cute.int_tuple<"(2,12)">
  return %r : !cute.int_tuple<"(2,12)">
}

// -----

// Deeper nested int_tuple.
// CHECK-LABEL: func.func @product_each_deeper
// CHECK-SAME:  (%[[SRC:.+]]: !cute.int_tuple<"(4,(16,32))">)
func.func @product_each_deeper(%src: !cute.int_tuple<"(4,(16,32))">) -> !cute.int_tuple<"(4,512)"> {
  // CHECK: %[[R:.+]] = cute.tuple_product_each(%[[SRC]]) : (!cute.int_tuple<"(4,(16,32))">) -> !cute.int_tuple<"(4,512)">
  %r = cute.tuple_product_each(%src) : (!cute.int_tuple<"(4,(16,32))">) -> !cute.int_tuple<"(4,512)">
  return %r : !cute.int_tuple<"(4,512)">
}

// -----

// Flat with one dynamic: each element is a leaf, dynamic element passes
// through unchanged. Result kind matches input kind (shape -> shape).
// CHECK-LABEL: func.func @product_each_flat_dynamic
// CHECK-SAME:  (%[[SRC:.+]]: !cute.shape<"(4,?)">)
func.func @product_each_flat_dynamic(%src: !cute.shape<"(4,?)">) -> !cute.shape<"(4,?)"> {
  // CHECK: %[[R:.+]] = cute.tuple_product_each(%[[SRC]]) : (!cute.shape<"(4,?)">) -> !cute.shape<"(4,?)">
  %r = cute.tuple_product_each(%src) : (!cute.shape<"(4,?)">) -> !cute.shape<"(4,?)">
  return %r : !cute.shape<"(4,?)">
}

// -----

// Nested with dynamic inner: div accumulates the static co-factor.
// CHECK-LABEL: func.func @product_each_nested_dynamic_inner
// CHECK-SAME:  (%[[SRC:.+]]: !cute.int_tuple<"(2,(3,?))">)
func.func @product_each_nested_dynamic_inner(%src: !cute.int_tuple<"(2,(3,?))">) -> !cute.int_tuple<"(2,?)"> {
  // CHECK: %[[R:.+]] = cute.tuple_product_each(%[[SRC]]) : (!cute.int_tuple<"(2,(3,?))">) -> !cute.int_tuple<"(2,?)">
  %r = cute.tuple_product_each(%src) : (!cute.int_tuple<"(2,(3,?))">) -> !cute.int_tuple<"(2,?)">
  return %r : !cute.int_tuple<"(2,?)">
}

// -----

// Nested with dynamic first in inner tuple.
// CHECK-LABEL: func.func @product_each_nested_dynamic_first
// CHECK-SAME:  (%[[SRC:.+]]: !cute.int_tuple<"(4,(?,8))">)
func.func @product_each_nested_dynamic_first(%src: !cute.int_tuple<"(4,(?,8))">) -> !cute.int_tuple<"(4,?)"> {
  // CHECK: %[[R:.+]] = cute.tuple_product_each(%[[SRC]]) : (!cute.int_tuple<"(4,(?,8))">) -> !cute.int_tuple<"(4,?)">
  %r = cute.tuple_product_each(%src) : (!cute.int_tuple<"(4,(?,8))">) -> !cute.int_tuple<"(4,?)">
  return %r : !cute.int_tuple<"(4,?)">
}

// -----

// Dynamic first element , static nested second element.
// CHECK-LABEL: func.func @product_each_dynamic_first
// CHECK-SAME:  (%[[SRC:.+]]: !cute.int_tuple<"(?,(3,2))">)
func.func @product_each_dynamic_first(%src: !cute.int_tuple<"(?,(3,2))">) -> !cute.int_tuple<"(?,6)"> {
  // CHECK: %[[R:.+]] = cute.tuple_product_each(%[[SRC]]) : (!cute.int_tuple<"(?,(3,2))">) -> !cute.int_tuple<"(?,6)">
  %r = cute.tuple_product_each(%src) : (!cute.int_tuple<"(?,(3,2))">) -> !cute.int_tuple<"(?,6)">
  return %r : !cute.int_tuple<"(?,6)">
}

// -----

// Depth-0 scalar int_tuple: rank-1 convention wraps the scalar to a
// 1-element tuple before applying product per-mode.
// CHECK-LABEL: func.func @product_each_scalar_int_tuple
// CHECK-SAME:  (%[[SRC:.+]]: !cute.int_tuple<"3">)
func.func @product_each_scalar_int_tuple(%src: !cute.int_tuple<"3">) -> !cute.int_tuple<"(3)"> {
  // CHECK: %[[R:.+]] = cute.tuple_product_each(%[[SRC]]) : (!cute.int_tuple<"3">) -> !cute.int_tuple<"(3)">
  %r = cute.tuple_product_each(%src) : (!cute.int_tuple<"3">) -> !cute.int_tuple<"(3)">
  return %r : !cute.int_tuple<"(3)">
}

// -----

// Depth-0 scalar shape: rank-1 convention applies kind-preservingly.
// CHECK-LABEL: func.func @product_each_scalar_shape
// CHECK-SAME:  (%[[SRC:.+]]: !cute.shape<"5">)
func.func @product_each_scalar_shape(%src: !cute.shape<"5">) -> !cute.shape<"(5)"> {
  // CHECK: %[[R:.+]] = cute.tuple_product_each(%[[SRC]]) : (!cute.shape<"5">) -> !cute.shape<"(5)">
  %r = cute.tuple_product_each(%src) : (!cute.shape<"5">) -> !cute.shape<"(5)">
  return %r : !cute.shape<"(5)">
}

// -----

// Empty int_tuple: per-mode product over zero modes stays empty.
// CHECK-LABEL: func.func @product_each_empty_int_tuple
// CHECK-SAME:  (%[[SRC:.+]]: !cute.int_tuple<"()">)
func.func @product_each_empty_int_tuple(%src: !cute.int_tuple<"()">) -> !cute.int_tuple<"()"> {
  // CHECK: %[[R:.+]] = cute.tuple_product_each(%[[SRC]]) : (!cute.int_tuple<"()">) -> !cute.int_tuple<"()">
  %r = cute.tuple_product_each(%src) : (!cute.int_tuple<"()">) -> !cute.int_tuple<"()">
  return %r : !cute.int_tuple<"()">
}

// -----

// Flat static int_tuple: each top-level element is already a leaf, result
// matches input.
// CHECK-LABEL: func.func @product_each_flat_int_tuple
// CHECK-SAME:  (%[[SRC:.+]]: !cute.int_tuple<"(2,3)">)
func.func @product_each_flat_int_tuple(%src: !cute.int_tuple<"(2,3)">) -> !cute.int_tuple<"(2,3)"> {
  // CHECK: %[[R:.+]] = cute.tuple_product_each(%[[SRC]]) : (!cute.int_tuple<"(2,3)">) -> !cute.int_tuple<"(2,3)">
  %r = cute.tuple_product_each(%src) : (!cute.int_tuple<"(2,3)">) -> !cute.int_tuple<"(2,3)">
  return %r : !cute.int_tuple<"(2,3)">
}

// -----

// Nested static shape: per-mode product on the outer tuple, kind preserved.
// CHECK-LABEL: func.func @product_each_nested_static_shape
// CHECK-SAME:  (%[[SRC:.+]]: !cute.shape<"((3,5),2)">)
func.func @product_each_nested_static_shape(%src: !cute.shape<"((3,5),2)">) -> !cute.shape<"(15,2)"> {
  // CHECK: %[[R:.+]] = cute.tuple_product_each(%[[SRC]]) : (!cute.shape<"((3,5),2)">) -> !cute.shape<"(15,2)">
  %r = cute.tuple_product_each(%src) : (!cute.shape<"((3,5),2)">) -> !cute.shape<"(15,2)">
  return %r : !cute.shape<"(15,2)">
}

// -----

// Nested dynamic shape.
// CHECK-LABEL: func.func @product_each_nested_dynamic_shape
// CHECK-SAME:  (%[[SRC:.+]]: !cute.shape<"((?,5),2)">)
func.func @product_each_nested_dynamic_shape(%src: !cute.shape<"((?,5),2)">) -> !cute.shape<"(?,2)"> {
  // CHECK: %[[R:.+]] = cute.tuple_product_each(%[[SRC]]) : (!cute.shape<"((?,5),2)">) -> !cute.shape<"(?,2)">
  %r = cute.tuple_product_each(%src) : (!cute.shape<"((?,5),2)">) -> !cute.shape<"(?,2)">
  return %r : !cute.shape<"(?,2)">
}

// -----

// Flat dynamic int_tuple.
// CHECK-LABEL: func.func @product_each_flat_dynamic_int_tuple
// CHECK-SAME:  (%[[SRC:.+]]: !cute.int_tuple<"(?,?)">)
func.func @product_each_flat_dynamic_int_tuple(%src: !cute.int_tuple<"(?,?)">) -> !cute.int_tuple<"(?,?)"> {
  // CHECK: %[[R:.+]] = cute.tuple_product_each(%[[SRC]]) : (!cute.int_tuple<"(?,?)">) -> !cute.int_tuple<"(?,?)">
  %r = cute.tuple_product_each(%src) : (!cute.int_tuple<"(?,?)">) -> !cute.int_tuple<"(?,?)">
  return %r : !cute.int_tuple<"(?,?)">
}

// -----

// Depth-3 nested int_tuple.
// CHECK-LABEL: func.func @product_each_triple_nested
// CHECK-SAME:  (%[[SRC:.+]]: !cute.int_tuple<"(2,(3,(4,5)))">)
func.func @product_each_triple_nested(%src: !cute.int_tuple<"(2,(3,(4,5)))">) -> !cute.int_tuple<"(2,60)"> {
  // CHECK: %[[R:.+]] = cute.tuple_product_each(%[[SRC]]) : (!cute.int_tuple<"(2,(3,(4,5)))">) -> !cute.int_tuple<"(2,60)">
  %r = cute.tuple_product_each(%src) : (!cute.int_tuple<"(2,(3,(4,5)))">) -> !cute.int_tuple<"(2,60)">
  return %r : !cute.int_tuple<"(2,60)">
}
