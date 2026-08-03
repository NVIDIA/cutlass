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

// Tests `cute-expand-ops` lowering for `cute.tuple_product`.

// -----

// CHECK-LABEL: func.func @expand_static_int_tuple
// CHECK-NOT:   cute.tuple_product
// CHECK:       cute.static : !cute.int_tuple<"24">
func.func @expand_static_int_tuple(%src: !cute.int_tuple<"(2,(3,4))">)
    -> !cute.int_tuple<"24"> {
  %r = cute.tuple_product(%src)
         : (!cute.int_tuple<"(2,(3,4))">) -> !cute.int_tuple<"24">
  return %r : !cute.int_tuple<"24">
}

// -----

// CHECK-LABEL: func.func @expand_static_shape
// CHECK-NOT:   cute.tuple_product
// CHECK:       cute.static : !cute.shape<"24">
func.func @expand_static_shape(%src: !cute.shape<"(2,(3,4))">)
    -> !cute.shape<"24"> {
  %r = cute.tuple_product(%src)
         : (!cute.shape<"(2,(3,4))">) -> !cute.shape<"24">
  return %r : !cute.shape<"24">
}

// -----

// Dynamic shape.
// CHECK-LABEL: func.func @expand_shape_dynamic
// CHECK-NOT:   cute.tuple_product
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_shape
// CHECK-SAME:  -> !cute.shape<"?">
func.func @expand_shape_dynamic(%src: !cute.shape<"(?,(3,?))">)
    -> !cute.shape<"?"> {
  %r = cute.tuple_product(%src)
         : (!cute.shape<"(?,(3,?))">) -> !cute.shape<"?">
  return %r : !cute.shape<"?">
}

// -----

// CHECK-LABEL: func.func @expand_int_tuple_dynamic
// CHECK-NOT:   cute.tuple_product
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_int_tuple
// CHECK-SAME:  -> !cute.int_tuple<"?">
func.func @expand_int_tuple_dynamic(%src: !cute.int_tuple<"(?,?)">)
    -> !cute.int_tuple<"?"> {
  %r = cute.tuple_product(%src)
         : (!cute.int_tuple<"(?,?)">) -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}

// -----

// Empty input: empty product is 1, folds to cute.static.
// CHECK-LABEL: func.func @expand_empty
// CHECK-NOT:   cute.tuple_product
// CHECK:       cute.static : !cute.int_tuple<"1">
func.func @expand_empty(%src: !cute.int_tuple<"()">) -> !cute.int_tuple<"1"> {
  %r = cute.tuple_product(%src)
         : (!cute.int_tuple<"()">) -> !cute.int_tuple<"1">
  return %r : !cute.int_tuple<"1">
}

// -----

// Scalar dynamic input: product is the scalar itself, no arith.muli.
// CHECK-LABEL: func.func @expand_scalar_dynamic
// CHECK-NOT:   cute.tuple_product
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK-NOT:   arith.muli
// CHECK:       cute.make_int_tuple
// CHECK-SAME:  -> !cute.int_tuple<"?">
func.func @expand_scalar_dynamic(%src: !cute.int_tuple<"?">)
    -> !cute.int_tuple<"?"> {
  %r = cute.tuple_product(%src)
         : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}

// -----

// Deeply-nested dynamic int_tuple: 3 dynamic leaves, 2 chained arith.muli.
// CHECK-LABEL: func.func @expand_int_tuple_deep_dynamic
// CHECK-NOT:   cute.tuple_product
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK-COUNT-2: arith.muli {{.+}} overflow<nsw> : i32
// CHECK-NOT:   arith.muli
// CHECK:       cute.make_int_tuple
// CHECK-SAME:  -> !cute.int_tuple<"?">
func.func @expand_int_tuple_deep_dynamic(%src: !cute.int_tuple<"(?,(?,?))">)
    -> !cute.int_tuple<"?"> {
  %r = cute.tuple_product(%src)
         : (!cute.int_tuple<"(?,(?,?))">) -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}

// -----

// Dynamic shape.
// CHECK-LABEL: func.func @expand_div_propagation
// CHECK-NOT:   cute.tuple_product
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       arith.constant 4 : i32
// CHECK:       arith.muli {{.+}} overflow<nsw> : i32
// CHECK:       cute.make_shape
// CHECK-SAME:  -> !cute.shape<"?">
func.func @expand_div_propagation(%src: !cute.shape<"(4,?)">)
    -> !cute.shape<"?"> {
  %r = cute.tuple_product(%src)
         : (!cute.shape<"(4,?)">) -> !cute.shape<"?">
  return %r : !cute.shape<"?">
}
