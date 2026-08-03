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

// Tests round-trip for cute.tuple_product.

// -----

// Flat shape.
// CHECK-LABEL: func.func @product_flat_shape
// CHECK-SAME:  (%[[SRC:.+]]: !cute.shape<"(4,3)">)
func.func @product_flat_shape(%src: !cute.shape<"(4,3)">) -> !cute.shape<"12"> {
  // CHECK: %[[R:.+]] = cute.tuple_product(%[[SRC]]) : (!cute.shape<"(4,3)">) -> !cute.shape<"12">
  %r = cute.tuple_product(%src) : (!cute.shape<"(4,3)">) -> !cute.shape<"12">
  return %r : !cute.shape<"12">
}

// -----

// Nested int_tuple: product of all leaf elements.
// CHECK-LABEL: func.func @product_nested_int_tuple
// CHECK-SAME:  (%[[SRC:.+]]: !cute.int_tuple<"(2,(3,4))">)
func.func @product_nested_int_tuple(%src: !cute.int_tuple<"(2,(3,4))">) -> !cute.int_tuple<"24"> {
  // CHECK: %[[R:.+]] = cute.tuple_product(%[[SRC]]) : (!cute.int_tuple<"(2,(3,4))">) -> !cute.int_tuple<"24">
  %r = cute.tuple_product(%src) : (!cute.int_tuple<"(2,(3,4))">) -> !cute.int_tuple<"24">
  return %r : !cute.int_tuple<"24">
}

// -----

// Dynamic shape.
// CHECK-LABEL: func.func @product_dynamic_shape
// CHECK-SAME:  (%[[SRC:.+]]: !cute.shape<"(4,(16,32),(?,64))">)
func.func @product_dynamic_shape(
    %src: !cute.shape<"(4,(16,32),(?,64))">) -> !cute.shape<"?"> {
  // CHECK: %[[R:.+]] = cute.tuple_product(%[[SRC]]) : (!cute.shape<"(4,(16,32),(?,64))">) -> !cute.shape<"?">
  %r = cute.tuple_product(%src) : (!cute.shape<"(4,(16,32),(?,64))">) -> !cute.shape<"?">
  return %r : !cute.shape<"?">
}

// -----

// One dynamic extent.
// CHECK-LABEL: func.func @product_one_dynamic
// CHECK-SAME:  (%[[SRC:.+]]: !cute.shape<"(4,?)">)
func.func @product_one_dynamic(%src: !cute.shape<"(4,?)">) -> !cute.shape<"?"> {
  // CHECK: %[[R:.+]] = cute.tuple_product(%[[SRC]]) : (!cute.shape<"(4,?)">) -> !cute.shape<"?">
  %r = cute.tuple_product(%src) : (!cute.shape<"(4,?)">) -> !cute.shape<"?">
  return %r : !cute.shape<"?">
}

// -----

// Dynamic extent.
// CHECK-LABEL: func.func @product_one_dynamic
// CHECK-SAME:  (%[[SRC:.+]]: !cute.shape<"(4,?)">)
func.func @product_one_dynamic(%src: !cute.shape<"(4,?)">) -> !cute.shape<"?"> {
  // CHECK: %[[R:.+]] = cute.tuple_product(%[[SRC]]) : (!cute.shape<"(4,?)">) -> !cute.shape<"?">
  %r = cute.tuple_product(%src) : (!cute.shape<"(4,?)">) -> !cute.shape<"?">
  return %r : !cute.shape<"?">
}

// -----

// Nested with one dynamic leaf.
// CHECK-LABEL: func.func @product_nested_dynamic
// CHECK-SAME:  (%[[SRC:.+]]: !cute.int_tuple<"(4,(16,?))">)
func.func @product_nested_dynamic(%src: !cute.int_tuple<"(4,(16,?))">) -> !cute.int_tuple<"?"> {
  // CHECK: %[[R:.+]] = cute.tuple_product(%[[SRC]]) : (!cute.int_tuple<"(4,(16,?))">) -> !cute.int_tuple<"?">
  %r = cute.tuple_product(%src) : (!cute.int_tuple<"(4,(16,?))">) -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}

// -----

// Depth-0 scalar int_tuple.
// CHECK-LABEL: func.func @product_scalar_int_tuple
// CHECK-SAME:  (%[[SRC:.+]]: !cute.int_tuple<"3">)
func.func @product_scalar_int_tuple(%src: !cute.int_tuple<"3">) -> !cute.int_tuple<"3"> {
  // CHECK: %[[R:.+]] = cute.tuple_product(%[[SRC]]) : (!cute.int_tuple<"3">) -> !cute.int_tuple<"3">
  %r = cute.tuple_product(%src) : (!cute.int_tuple<"3">) -> !cute.int_tuple<"3">
  return %r : !cute.int_tuple<"3">
}

// -----

// Depth-0 scalar shape: rank-1 convention applies to shape kind too.
// CHECK-LABEL: func.func @product_scalar_shape
// CHECK-SAME:  (%[[SRC:.+]]: !cute.shape<"5">)
func.func @product_scalar_shape(%src: !cute.shape<"5">) -> !cute.shape<"5"> {
  // CHECK: %[[R:.+]] = cute.tuple_product(%[[SRC]]) : (!cute.shape<"5">) -> !cute.shape<"5">
  %r = cute.tuple_product(%src) : (!cute.shape<"5">) -> !cute.shape<"5">
  return %r : !cute.shape<"5">
}

// -----

// Empty int_tuple: the empty product is 1.
// CHECK-LABEL: func.func @product_empty_int_tuple
// CHECK-SAME:  (%[[SRC:.+]]: !cute.int_tuple<"()">)
func.func @product_empty_int_tuple(%src: !cute.int_tuple<"()">) -> !cute.int_tuple<"1"> {
  // CHECK: %[[R:.+]] = cute.tuple_product(%[[SRC]]) : (!cute.int_tuple<"()">) -> !cute.int_tuple<"1">
  %r = cute.tuple_product(%src) : (!cute.int_tuple<"()">) -> !cute.int_tuple<"1">
  return %r : !cute.int_tuple<"1">
}

// -----

// Empty shape: empty product is 1 (kind-preserving).
// CHECK-LABEL: func.func @product_empty_shape
// CHECK-SAME:  (%[[SRC:.+]]: !cute.shape<"()">)
func.func @product_empty_shape(%src: !cute.shape<"()">) -> !cute.shape<"1"> {
  // CHECK: %[[R:.+]] = cute.tuple_product(%[[SRC]]) : (!cute.shape<"()">) -> !cute.shape<"1">
  %r = cute.tuple_product(%src) : (!cute.shape<"()">) -> !cute.shape<"1">
  return %r : !cute.shape<"1">
}

// -----

// Flat static int_tuple: product of all leaves at depth 1.
// CHECK-LABEL: func.func @product_flat_int_tuple
// CHECK-SAME:  (%[[SRC:.+]]: !cute.int_tuple<"(2,3)">)
func.func @product_flat_int_tuple(%src: !cute.int_tuple<"(2,3)">) -> !cute.int_tuple<"6"> {
  // CHECK: %[[R:.+]] = cute.tuple_product(%[[SRC]]) : (!cute.int_tuple<"(2,3)">) -> !cute.int_tuple<"6">
  %r = cute.tuple_product(%src) : (!cute.int_tuple<"(2,3)">) -> !cute.int_tuple<"6">
  return %r : !cute.int_tuple<"6">
}

// -----

// Nested static shape: product across all leaves, result kind preserved.
// CHECK-LABEL: func.func @product_nested_static_shape
// CHECK-SAME:  (%[[SRC:.+]]: !cute.shape<"((3,5),2)">)
func.func @product_nested_static_shape(%src: !cute.shape<"((3,5),2)">) -> !cute.shape<"30"> {
  // CHECK: %[[R:.+]] = cute.tuple_product(%[[SRC]]) : (!cute.shape<"((3,5),2)">) -> !cute.shape<"30">
  %r = cute.tuple_product(%src) : (!cute.shape<"((3,5),2)">) -> !cute.shape<"30">
  return %r : !cute.shape<"30">
}

// -----

// Nested dynamic shape.
// CHECK-LABEL: func.func @product_nested_dynamic_shape
// CHECK-SAME:  (%[[SRC:.+]]: !cute.shape<"((?,5),2)">)
func.func @product_nested_dynamic_shape(%src: !cute.shape<"((?,5),2)">) -> !cute.shape<"?"> {
  // CHECK: %[[R:.+]] = cute.tuple_product(%[[SRC]]) : (!cute.shape<"((?,5),2)">) -> !cute.shape<"?">
  %r = cute.tuple_product(%src) : (!cute.shape<"((?,5),2)">) -> !cute.shape<"?">
  return %r : !cute.shape<"?">
}

// -----

// Flat dynamic int_tuple: no static factors, result is fully dynamic.
// CHECK-LABEL: func.func @product_flat_dynamic_int_tuple
// CHECK-SAME:  (%[[SRC:.+]]: !cute.int_tuple<"(?,?)">)
func.func @product_flat_dynamic_int_tuple(%src: !cute.int_tuple<"(?,?)">) -> !cute.int_tuple<"?"> {
  // CHECK: %[[R:.+]] = cute.tuple_product(%[[SRC]]) : (!cute.int_tuple<"(?,?)">) -> !cute.int_tuple<"?">
  %r = cute.tuple_product(%src) : (!cute.int_tuple<"(?,?)">) -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}

// -----

// Depth-3 nested int_tuple: product across all leaves at depth 3.
// CHECK-LABEL: func.func @product_triple_nested
// CHECK-SAME:  (%[[SRC:.+]]: !cute.int_tuple<"(2,(3,(4,5)))">)
func.func @product_triple_nested(%src: !cute.int_tuple<"(2,(3,(4,5)))">) -> !cute.int_tuple<"120"> {
  // CHECK: %[[R:.+]] = cute.tuple_product(%[[SRC]]) : (!cute.int_tuple<"(2,(3,(4,5)))">) -> !cute.int_tuple<"120">
  %r = cute.tuple_product(%src) : (!cute.int_tuple<"(2,(3,(4,5)))">) -> !cute.int_tuple<"120">
  return %r : !cute.int_tuple<"120">
}
