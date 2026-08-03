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

// RUN: cute-opt -cute-fold-static --split-input-file %s | FileCheck %s

// cute-fold-static: arithmetic ops with fully-static operands fold to cute.static.

// -----

//===----------------------------------------------------------------------===//
// tuple_add
//===----------------------------------------------------------------------===//

// CHECK-LABEL: func.func @fold_tuple_add_int_tuple
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.int_tuple<"(4,6)">
// CHECK-NEXT:    return %[[R]]
func.func @fold_tuple_add_int_tuple() -> !cute.int_tuple<"(4,6)"> {
  %a = cute.make_int_tuple() : () -> !cute.int_tuple<"(1,2)">
  %b = cute.make_int_tuple() : () -> !cute.int_tuple<"(3,4)">
  %r = cute.tuple_add(%a, %b)
         : (!cute.int_tuple<"(1,2)">, !cute.int_tuple<"(3,4)">)
        -> !cute.int_tuple<"(4,6)">
  return %r : !cute.int_tuple<"(4,6)">
}

// -----

// CHECK-LABEL: func.func @fold_tuple_add_shape
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.shape<"(8,12)">
// CHECK-NEXT:    return %[[R]]
func.func @fold_tuple_add_shape() -> !cute.shape<"(8,12)"> {
  %a = cute.make_shape() : () -> !cute.shape<"(6,8)">
  %b = cute.make_shape() : () -> !cute.shape<"(2,4)">
  %r = cute.tuple_add(%a, %b)
         : (!cute.shape<"(6,8)">, !cute.shape<"(2,4)">) -> !cute.shape<"(8,12)">
  return %r : !cute.shape<"(8,12)">
}

// -----

//===----------------------------------------------------------------------===//
// tuple_sub
//===----------------------------------------------------------------------===//

// CHECK-LABEL: func.func @fold_tuple_sub_int_tuple
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.int_tuple<"(4,6)">
// CHECK-NEXT:    return %[[R]]
func.func @fold_tuple_sub_int_tuple() -> !cute.int_tuple<"(4,6)"> {
  %a = cute.make_int_tuple() : () -> !cute.int_tuple<"(5,8)">
  %b = cute.make_int_tuple() : () -> !cute.int_tuple<"(1,2)">
  %r = cute.tuple_sub(%a, %b)
         : (!cute.int_tuple<"(5,8)">, !cute.int_tuple<"(1,2)">)
        -> !cute.int_tuple<"(4,6)">
  return %r : !cute.int_tuple<"(4,6)">
}

// -----

// CHECK-LABEL: func.func @fold_tuple_sub_shape
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.shape<"(4,6)">
// CHECK-NEXT:    return %[[R]]
func.func @fold_tuple_sub_shape() -> !cute.shape<"(4,6)"> {
  %a = cute.make_shape() : () -> !cute.shape<"(5,8)">
  %b = cute.make_shape() : () -> !cute.shape<"(1,2)">
  %r = cute.tuple_sub(%a, %b)
         : (!cute.shape<"(5,8)">, !cute.shape<"(1,2)">) -> !cute.shape<"(4,6)">
  return %r : !cute.shape<"(4,6)">
}

// -----

//===----------------------------------------------------------------------===//
// ceil_div
//===----------------------------------------------------------------------===//

// CHECK-LABEL: func.func @fold_ceil_div_int_tuple
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.int_tuple<"(3,3)">
// CHECK-NEXT:    return %[[R]]
func.func @fold_ceil_div_int_tuple() -> !cute.int_tuple<"(3,3)"> {
  %a = cute.make_int_tuple() : () -> !cute.int_tuple<"(8,10)">
  %b = cute.make_int_tuple() : () -> !cute.int_tuple<"(3,4)">
  %r = cute.ceil_div(%a, %b)
         : (!cute.int_tuple<"(8,10)">, !cute.int_tuple<"(3,4)">)
        -> !cute.int_tuple<"(3,3)">
  return %r : !cute.int_tuple<"(3,3)">
}

// -----

// CHECK-LABEL: func.func @fold_ceil_div_shape
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.shape<"(3,3)">
// CHECK-NEXT:    return %[[R]]
func.func @fold_ceil_div_shape() -> !cute.shape<"(3,3)"> {
  %a = cute.make_shape() : () -> !cute.shape<"(8,10)">
  %b = cute.make_shape() : () -> !cute.shape<"(3,4)">
  %r = cute.ceil_div(%a, %b)
         : (!cute.shape<"(8,10)">, !cute.shape<"(3,4)">) -> !cute.shape<"(3,3)">
  return %r : !cute.shape<"(3,3)">
}

// -----

//===----------------------------------------------------------------------===//
// shape_div (shape only)
//===----------------------------------------------------------------------===//

// CHECK-LABEL: func.func @fold_shape_div
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.shape<"(4,2)">
// CHECK-NEXT:    return %[[R]]
func.func @fold_shape_div() -> !cute.shape<"(4,2)"> {
  %a = cute.make_shape() : () -> !cute.shape<"(8,10)">
  %b = cute.make_shape() : () -> !cute.shape<"(2,5)">
  %r = cute.shape_div(%a, %b)
         : (!cute.shape<"(8,10)">, !cute.shape<"(2,5)">) -> !cute.shape<"(4,2)">
  return %r : !cute.shape<"(4,2)">
}

// -----

//===----------------------------------------------------------------------===//
// elem_less — i1 result, folded explicitly via the per-leaf compare walk.
//===----------------------------------------------------------------------===//

// Static int_tuple — true result.
// CHECK-LABEL: func.func @fold_elem_less_int_tuple_true
// CHECK-NEXT:    %[[R:.+]] = arith.constant true
// CHECK-NEXT:    return %[[R]]
func.func @fold_elem_less_int_tuple_true() -> i1 {
  %a = cute.make_int_tuple() : () -> !cute.int_tuple<"(3,4)">
  %b = cute.make_int_tuple() : () -> !cute.int_tuple<"(5,6)">
  %r = cute.elem_less(%a, %b)
         : (!cute.int_tuple<"(3,4)">, !cute.int_tuple<"(5,6)">) -> i1
  return %r : i1
}

// -----

// Static shape — false result.
// CHECK-LABEL: func.func @fold_elem_less_shape_false
// CHECK-NEXT:    %[[R:.+]] = arith.constant false
// CHECK-NEXT:    return %[[R]]
func.func @fold_elem_less_shape_false() -> i1 {
  %a = cute.make_shape() : () -> !cute.shape<"(7,4)">
  %b = cute.make_shape() : () -> !cute.shape<"(5,6)">
  %r = cute.elem_less(%a, %b)
         : (!cute.shape<"(7,4)">, !cute.shape<"(5,6)">) -> i1
  return %r : i1
}

// -----

// Mixed-kind static (coord vs shape).
// CHECK-LABEL: func.func @fold_elem_less_mixed_kind
// CHECK-NEXT:    %[[R:.+]] = arith.constant true
// CHECK-NEXT:    return %[[R]]
func.func @fold_elem_less_mixed_kind() -> i1 {
  %a = cute.make_coord() : () -> !cute.coord<"(3,4)">
  %b = cute.make_shape() : () -> !cute.shape<"(5,6)">
  %r = cute.elem_less(%a, %b)
         : (!cute.coord<"(3,4)">, !cute.shape<"(5,6)">) -> i1
  return %r : i1
}

// -----

// Nested static int_tuple.
// CHECK-LABEL: func.func @fold_elem_less_nested
// CHECK-NEXT:    %[[R:.+]] = arith.constant true
// CHECK-NEXT:    return %[[R]]
func.func @fold_elem_less_nested() -> i1 {
  %a = cute.make_int_tuple() : () -> !cute.int_tuple<"((1,2),3)">
  %b = cute.make_int_tuple() : () -> !cute.int_tuple<"((4,5),6)">
  %r = cute.elem_less(%a, %b)
         : (!cute.int_tuple<"((1,2),3)">, !cute.int_tuple<"((4,5),6)">) -> i1
  return %r : i1
}

// -----

//===----------------------------------------------------------------------===//
// equal — i1 result, folded via MLIR Type identity (uniqued cute types).
//===----------------------------------------------------------------------===//

// Identical static int_tuple ⇒ true.
// CHECK-LABEL: func.func @fold_equal_int_tuple_true
// CHECK-NEXT:    %[[R:.+]] = arith.constant true
// CHECK-NEXT:    return %[[R]]
func.func @fold_equal_int_tuple_true() -> i1 {
  %a = cute.make_int_tuple() : () -> !cute.int_tuple<"(3,4)">
  %b = cute.make_int_tuple() : () -> !cute.int_tuple<"(3,4)">
  %r = cute.equal(%a, %b)
         : (!cute.int_tuple<"(3,4)">, !cute.int_tuple<"(3,4)">) -> i1
  return %r : i1
}

// -----

// Distinct static shape ⇒ false.
// CHECK-LABEL: func.func @fold_equal_shape_false
// CHECK-NEXT:    %[[R:.+]] = arith.constant false
// CHECK-NEXT:    return %[[R]]
func.func @fold_equal_shape_false() -> i1 {
  %a = cute.make_shape() : () -> !cute.shape<"(3,4)">
  %b = cute.make_shape() : () -> !cute.shape<"(3,5)">
  %r = cute.equal(%a, %b)
         : (!cute.shape<"(3,4)">, !cute.shape<"(3,5)">) -> i1
  return %r : i1
}

// -----

// Identical static layout ⇒ true.
// CHECK-LABEL: func.func @fold_equal_layout_true
// CHECK-NEXT:    %[[R:.+]] = arith.constant true
// CHECK-NEXT:    return %[[R]]
func.func @fold_equal_layout_true() -> i1 {
  %a_shape = cute.make_shape () : () -> !cute.shape<"(4,8)">
  %a_stride = cute.make_stride () : () -> !cute.stride<"(1,4)">
  %a = cute.make_layout (%a_shape, %a_stride) : (!cute.shape<"(4,8)">, !cute.stride<"(1,4)">) -> !cute.layout<"(4,8):(1,4)">
  %b_shape = cute.make_shape () : () -> !cute.shape<"(4,8)">
  %b_stride = cute.make_stride () : () -> !cute.stride<"(1,4)">
  %b = cute.make_layout (%b_shape, %b_stride) : (!cute.shape<"(4,8)">, !cute.stride<"(1,4)">) -> !cute.layout<"(4,8):(1,4)">
  %r = cute.equal(%a, %b)
         : (!cute.layout<"(4,8):(1,4)">, !cute.layout<"(4,8):(1,4)">) -> i1
  return %r : i1
}

// -----

// Identical static stride ⇒ true. Stride is part of the
// supported operand union for `cute.equal`.
// CHECK-LABEL: func.func @fold_equal_stride_true
// CHECK-NEXT:    %[[R:.+]] = arith.constant true
// CHECK-NEXT:    return %[[R]]
func.func @fold_equal_stride_true() -> i1 {
  %a = cute.make_stride() : () -> !cute.stride<"(1,4)">
  %b = cute.make_stride() : () -> !cute.stride<"(1,4)">
  %r = cute.equal(%a, %b)
         : (!cute.stride<"(1,4)">, !cute.stride<"(1,4)">) -> i1
  return %r : i1
}

// -----

// Distinct static stride ⇒ false. Pins that Type identity drives
// the fold; differing static profiles ⇒ different Type instances.
// CHECK-LABEL: func.func @fold_equal_stride_false
// CHECK-NEXT:    %[[R:.+]] = arith.constant false
// CHECK-NEXT:    return %[[R]]
func.func @fold_equal_stride_false() -> i1 {
  %a = cute.make_stride() : () -> !cute.stride<"(1,4)">
  %b = cute.make_stride() : () -> !cute.stride<"(1,8)">
  %r = cute.equal(%a, %b)
         : (!cute.stride<"(1,4)">, !cute.stride<"(1,8)">) -> i1
  return %r : i1
}

// -----

// Nested static int_tuple — identical nested profile ⇒ Type identity
// fold ⇒ true. Pins fold across deep nesting.
// CHECK-LABEL: func.func @fold_equal_nested_true
// CHECK-NEXT:    %[[R:.+]] = arith.constant true
// CHECK-NEXT:    return %[[R]]
func.func @fold_equal_nested_true() -> i1 {
  %a = cute.make_int_tuple() : () -> !cute.int_tuple<"((1,2),3)">
  %b = cute.make_int_tuple() : () -> !cute.int_tuple<"((1,2),3)">
  %r = cute.equal(%a, %b)
         : (!cute.int_tuple<"((1,2),3)">, !cute.int_tuple<"((1,2),3)">) -> i1
  return %r : i1
}
