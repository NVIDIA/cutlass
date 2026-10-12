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

// cute-fold-static: accessor ops with fully-static result types fold to cute.static.

// -----

// CHECK-LABEL: func.func @fold_get_shape
// CHECK-SAME:  (%[[L:.+]]: !cute.layout<"(4,8):(1,4)">)
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.shape<"(4,8)">
// CHECK-NEXT:    return %[[R]]
func.func @fold_get_shape(%l: !cute.layout<"(4,8):(1,4)">) -> !cute.shape<"(4,8)"> {
  %s = cute.get_shape(%l) : !cute.layout<"(4,8):(1,4)"> -> !cute.shape<"(4,8)">
  return %s : !cute.shape<"(4,8)">
}

// -----

// CHECK-LABEL: func.func @fold_get_stride
// CHECK-SAME:  (%[[L:.+]]: !cute.layout<"(4,8):(1,4)">)
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.stride<"(1,4)">
// CHECK-NEXT:    return %[[R]]
func.func @fold_get_stride(%l: !cute.layout<"(4,8):(1,4)">) -> !cute.stride<"(1,4)"> {
  %d = cute.get_stride(%l) : !cute.layout<"(4,8):(1,4)"> -> !cute.stride<"(1,4)">
  return %d : !cute.stride<"(1,4)">
}

// -----

// composed_get_inner — layout result.
// CHECK-LABEL: func.func @fold_composed_get_inner_layout
// CHECK-SAME:  (%[[CL:.+]]: !cute.composed_layout<"(4,8):(1,4) o 0 o (2,4):(1,2)">)
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.layout<"(4,8):(1,4)">
// CHECK-NEXT:    return %[[R]]
func.func @fold_composed_get_inner_layout(
    %cl: !cute.composed_layout<"(4,8):(1,4) o 0 o (2,4):(1,2)">)
    -> !cute.layout<"(4,8):(1,4)"> {
  %r = cute.composed_get_inner(%cl)
         : !cute.composed_layout<"(4,8):(1,4) o 0 o (2,4):(1,2)">
        -> !cute.layout<"(4,8):(1,4)">
  return %r : !cute.layout<"(4,8):(1,4)">
}

// -----

// composed_get_inner — swizzle result.
// CHECK-LABEL: func.func @fold_composed_get_inner_swizzle
// CHECK-SAME:  (%[[CL:.+]]: !cute.composed_layout<"S<3,5,4> o 0 o (8,4):(1,8)">)
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.swizzle<"S<3,5,4>">
// CHECK-NEXT:    return %[[R]]
func.func @fold_composed_get_inner_swizzle(
    %cl: !cute.composed_layout<"S<3,5,4> o 0 o (8,4):(1,8)">)
    -> !cute.swizzle<"S<3,5,4>"> {
  %r = cute.composed_get_inner(%cl)
         : !cute.composed_layout<"S<3,5,4> o 0 o (8,4):(1,8)">
        -> !cute.swizzle<"S<3,5,4>">
  return %r : !cute.swizzle<"S<3,5,4>">
}

// -----

// CHECK-LABEL: func.func @fold_composed_get_offset
// CHECK-SAME:  (%[[CL:.+]]: !cute.composed_layout<"(4,8):(1,4) o 2 o (2,4):(1,2)">)
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.int_tuple<"2">
// CHECK-NEXT:    return %[[R]]
func.func @fold_composed_get_offset(
    %cl: !cute.composed_layout<"(4,8):(1,4) o 2 o (2,4):(1,2)">)
    -> !cute.int_tuple<"2"> {
  %r = cute.composed_get_offset(%cl)
         : !cute.composed_layout<"(4,8):(1,4) o 2 o (2,4):(1,2)">
        -> !cute.int_tuple<"2">
  return %r : !cute.int_tuple<"2">
}

// -----

// CHECK-LABEL: func.func @fold_composed_get_outer
// CHECK-SAME:  (%[[CL:.+]]: !cute.composed_layout<"(4,8):(1,4) o 0 o (2,4):(1,2)">)
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.layout<"(2,4):(1,2)">
// CHECK-NEXT:    return %[[R]]
func.func @fold_composed_get_outer(
    %cl: !cute.composed_layout<"(4,8):(1,4) o 0 o (2,4):(1,2)">)
    -> !cute.layout<"(2,4):(1,2)"> {
  %r = cute.composed_get_outer(%cl)
         : !cute.composed_layout<"(4,8):(1,4) o 0 o (2,4):(1,2)">
        -> !cute.layout<"(2,4):(1,2)">
  return %r : !cute.layout<"(2,4):(1,2)">
}

// -----

// CHECK-LABEL: func.func @fold_to_int_tuple
// CHECK-SAME:  (%[[S:.+]]: !cute.shape<"(4,8)">)
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.int_tuple<"(4,8)">
// CHECK-NEXT:    return %[[R]]
func.func @fold_to_int_tuple(%s: !cute.shape<"(4,8)">) -> !cute.int_tuple<"(4,8)"> {
  %r = cute.to_int_tuple(%s) : !cute.shape<"(4,8)"> -> !cute.int_tuple<"(4,8)">
  return %r : !cute.int_tuple<"(4,8)">
}

// -----

// get_leaves — static shape.
// CHECK-LABEL: func.func @fold_get_leaves_shape
// CHECK-SAME:  (%[[S:.+]]: !cute.shape<"(4,(2,3))">)
// CHECK-DAG:     %[[R0:.+]] = cute.static : !cute.shape<"4">
// CHECK-DAG:     %[[R1:.+]] = cute.static : !cute.shape<"2">
// CHECK-DAG:     %[[R2:.+]] = cute.static : !cute.shape<"3">
// CHECK:         return %[[R0]], %[[R1]], %[[R2]]
func.func @fold_get_leaves_shape(%s: !cute.shape<"(4,(2,3))">)
    -> (!cute.shape<"4">, !cute.shape<"2">, !cute.shape<"3">) {
  %a, %b, %c = cute.get_leaves(%s) : !cute.shape<"(4,(2,3))">
  return %a, %b, %c : !cute.shape<"4">, !cute.shape<"2">, !cute.shape<"3">
}

// -----

// get_leaves — static int_tuple.
// CHECK-LABEL: func.func @fold_get_leaves_int_tuple
// CHECK-DAG:     %[[R0:.+]] = cute.static : !cute.int_tuple<"1">
// CHECK-DAG:     %[[R1:.+]] = cute.static : !cute.int_tuple<"2">
// CHECK-DAG:     %[[R2:.+]] = cute.static : !cute.int_tuple<"3">
// CHECK:         return %[[R0]], %[[R1]], %[[R2]]
func.func @fold_get_leaves_int_tuple(%i: !cute.int_tuple<"(1,(2,3))">)
    -> (!cute.int_tuple<"1">, !cute.int_tuple<"2">, !cute.int_tuple<"3">) {
  %a, %b, %c = cute.get_leaves(%i) : !cute.int_tuple<"(1,(2,3))">
  return %a, %b, %c
      : !cute.int_tuple<"1">, !cute.int_tuple<"2">, !cute.int_tuple<"3">
}

// -----

// get_leaves — static stride.
// CHECK-LABEL: func.func @fold_get_leaves_stride
// CHECK-DAG:     %[[R0:.+]] = cute.static : !cute.stride<"1">
// CHECK-DAG:     %[[R1:.+]] = cute.static : !cute.stride<"4">
// CHECK-DAG:     %[[R2:.+]] = cute.static : !cute.stride<"8">
// CHECK:         return %[[R0]], %[[R1]], %[[R2]]
func.func @fold_get_leaves_stride(%st: !cute.stride<"(1,(4,8))">)
    -> (!cute.stride<"1">, !cute.stride<"4">, !cute.stride<"8">) {
  %a, %b, %c = cute.get_leaves(%st) : !cute.stride<"(1,(4,8))">
  return %a, %b, %c : !cute.stride<"1">, !cute.stride<"4">, !cute.stride<"8">
}

// -----

// get_leaves — static tile.
// CHECK-LABEL: func.func @fold_get_leaves_tile
// CHECK-DAG:     %[[R0:.+]] = cute.static : !cute.layout<"(4,8):(1,4)">
// CHECK-DAG:     %[[R1:.+]] = cute.static : !cute.layout<"(2,3):(1,2)">
// CHECK:         return %[[R0]], %[[R1]]
func.func @fold_get_leaves_tile(%t: !cute.tile<"[(4,8):(1,4);(2,3):(1,2)]">)
    -> (!cute.layout<"(4,8):(1,4)">, !cute.layout<"(2,3):(1,2)">) {
  %a, %b = cute.get_leaves(%t) : !cute.tile<"[(4,8):(1,4);(2,3):(1,2)]">
  return %a, %b : !cute.layout<"(4,8):(1,4)">, !cute.layout<"(2,3):(1,2)">
}

// -----

// get_layouts_from_tile.
// CHECK-LABEL: func.func @fold_get_layouts_from_tile
// CHECK-DAG:     %[[R0:.+]] = cute.static : !cute.layout<"(4,8):(1,4)">
// CHECK-DAG:     %[[R1:.+]] = cute.static : !cute.layout<"(2,3):(1,2)">
// CHECK:         return %[[R0]], %[[R1]]
func.func @fold_get_layouts_from_tile(
    %t: !cute.tile<"[(4,8):(1,4);(2,3):(1,2)]">)
    -> (!cute.layout<"(4,8):(1,4)">, !cute.layout<"(2,3):(1,2)">) {
  %a, %b = cute.get_layouts_from_tile(%t)
             : !cute.tile<"[(4,8):(1,4);(2,3):(1,2)]">
  return %a, %b : !cute.layout<"(4,8):(1,4)">, !cute.layout<"(2,3):(1,2)">
}
