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

// Tests round-trip for cute.append_to_rank.

// -----

// Shape rank 2 → rank 4: pads two trailing 1s.
// CHECK-LABEL: func.func @append_shape_to_rank4
// CHECK-SAME:  (%[[IN:.+]]: !cute.shape<"(4,8)">, %[[E:.+]]: !cute.shape<"1">)
func.func @append_shape_to_rank4(%in: !cute.shape<"(4,8)">, %e: !cute.shape<"1">) -> !cute.shape<"(4,8,1,1)"> {
  // CHECK: %[[R:.+]] = cute.append_to_rank<4> (%[[IN]], %[[E]]) : !cute.shape<"(4,8)">, !cute.shape<"1">
  %r = cute.append_to_rank<4>(%in, %e) : !cute.shape<"(4,8)">, !cute.shape<"1">
  return %r : !cute.shape<"(4,8,1,1)">
}

// -----

// int_tuple scalar → rank 3.
// CHECK-LABEL: func.func @append_int_tuple_to_rank3
// CHECK-SAME:  (%[[IN:.+]]: !cute.int_tuple<"5">, %[[E:.+]]: !cute.int_tuple<"1">)
func.func @append_int_tuple_to_rank3(%in: !cute.int_tuple<"5">, %e: !cute.int_tuple<"1">) -> !cute.int_tuple<"(5,1,1)"> {
  // CHECK: %[[R:.+]] = cute.append_to_rank<3> (%[[IN]], %[[E]]) : !cute.int_tuple<"5">, !cute.int_tuple<"1">
  %r = cute.append_to_rank<3>(%in, %e) : !cute.int_tuple<"5">, !cute.int_tuple<"1">
  return %r : !cute.int_tuple<"(5,1,1)">
}

// -----

// Stride rank 2 → rank 4: pads two trailing 0 strides.
// CHECK-LABEL: func.func @append_stride_to_rank4
// CHECK-SAME:  (%[[IN:.+]]: !cute.stride<"(4,2)">, %[[E:.+]]: !cute.stride<"0">)
func.func @append_stride_to_rank4(%in: !cute.stride<"(4,2)">, %e: !cute.stride<"0">) -> !cute.stride<"(4,2,0,0)"> {
  // CHECK: %[[R:.+]] = cute.append_to_rank<4> (%[[IN]], %[[E]]) : !cute.stride<"(4,2)">, !cute.stride<"0">
  %r = cute.append_to_rank<4>(%in, %e) : !cute.stride<"(4,2)">, !cute.stride<"0">
  return %r : !cute.stride<"(4,2,0,0)">
}

// -----

// Dynamic element: result has dynamic padding modes.
// CHECK-LABEL: func.func @append_shape_dynamic_element
// CHECK-SAME:  (%[[IN:.+]]: !cute.shape<"(4,8)">, %[[E:.+]]: !cute.shape<"?">)
func.func @append_shape_dynamic_element(%in: !cute.shape<"(4,8)">, %e: !cute.shape<"?">) -> !cute.shape<"(4,8,?,?)"> {
  // CHECK: %[[R:.+]] = cute.append_to_rank<4> (%[[IN]], %[[E]]) : !cute.shape<"(4,8)">, !cute.shape<"?">
  %r = cute.append_to_rank<4>(%in, %e) : !cute.shape<"(4,8)">, !cute.shape<"?">
  return %r : !cute.shape<"(4,8,?,?)">
}

// -----

// Already at target rank (rank == target): input returned unchanged.
// CHECK-LABEL: func.func @append_noop_rank_already_met
// CHECK-SAME:  (%[[IN:.+]]: !cute.shape<"(4,8,2,1)">, %[[E:.+]]: !cute.shape<"1">)
func.func @append_noop_rank_already_met(%in: !cute.shape<"(4,8,2,1)">, %e: !cute.shape<"1">) -> !cute.shape<"(4,8,2,1)"> {
  // CHECK: %[[R:.+]] = cute.append_to_rank<3> (%[[IN]], %[[E]]) : !cute.shape<"(4,8,2,1)">, !cute.shape<"1">
  %r = cute.append_to_rank<3>(%in, %e) : !cute.shape<"(4,8,2,1)">, !cute.shape<"1">
  return %r : !cute.shape<"(4,8,2,1)">
}

// -----

// Target rank < input rank: per `rank(result) == max(rank(input), $rank)`,
// the result equals the input unchanged.
// CHECK-LABEL: func.func @append_noop_rank_less_than_input
// CHECK-SAME:  (%[[IN:.+]]: !cute.shape<"(4,8,2)">, %[[E:.+]]: !cute.shape<"1">)
func.func @append_noop_rank_less_than_input(%in: !cute.shape<"(4,8,2)">, %e: !cute.shape<"1">) -> !cute.shape<"(4,8,2)"> {
  // CHECK: %[[R:.+]] = cute.append_to_rank<2> (%[[IN]], %[[E]]) : !cute.shape<"(4,8,2)">, !cute.shape<"1">
  %r = cute.append_to_rank<2>(%in, %e) : !cute.shape<"(4,8,2)">, !cute.shape<"1">
  return %r : !cute.shape<"(4,8,2)">
}

// -----

// Layout rank 1 → rank 3: pads two identity modes.
// CHECK-LABEL: func.func @append_layout_to_rank3
// CHECK-SAME:  (%[[IN:.+]]: !cute.layout<"4:1">, %[[E:.+]]: !cute.layout<"1:0">)
func.func @append_layout_to_rank3(%in: !cute.layout<"4:1">, %e: !cute.layout<"1:0">) -> !cute.layout<"(4,1,1):(1,0,0)"> {
  // CHECK: %[[R:.+]] = cute.append_to_rank<3> (%[[IN]], %[[E]]) : !cute.layout<"4:1">, !cute.layout<"1:0">
  %r = cute.append_to_rank<3>(%in, %e) : !cute.layout<"4:1">, !cute.layout<"1:0">
  return %r : !cute.layout<"(4,1,1):(1,0,0)">
}

// -----

// Coord rank 2 → rank 4: pads two trailing 0 coordinates.
// CHECK-LABEL: func.func @append_coord_to_rank4
// CHECK-SAME:  (%[[IN:.+]]: !cute.coord<"(2,3)">, %[[E:.+]]: !cute.coord<"0">)
func.func @append_coord_to_rank4(%in: !cute.coord<"(2,3)">, %e: !cute.coord<"0">) -> !cute.coord<"(2,3,0,0)"> {
  // CHECK: %[[R:.+]] = cute.append_to_rank<4> (%[[IN]], %[[E]]) : !cute.coord<"(2,3)">, !cute.coord<"0">
  %r = cute.append_to_rank<4>(%in, %e) : !cute.coord<"(2,3)">, !cute.coord<"0">
  return %r : !cute.coord<"(2,3,0,0)">
}

// -----

// Composed layout: append pads B with identity modes; A (swizzle) and offset
// pass through unchanged.
// CHECK-LABEL: func.func @append_composed_layout_to_rank4
// CHECK-SAME:  (%[[IN:.+]]: !cute.composed_layout<"S<3,4,3> o 0 o (4,8):(1,4)">, %[[E:.+]]: !cute.layout<"1:0">)
func.func @append_composed_layout_to_rank4(
    %in: !cute.composed_layout<"S<3,4,3> o 0 o (4,8):(1,4)">,
    %e: !cute.layout<"1:0">)
    -> !cute.composed_layout<"S<3,4,3> o 0 o (4,8,1,1):(1,4,0,0)"> {
  // CHECK: %[[R:.+]] = cute.append_to_rank<4> (%[[IN]], %[[E]]) : !cute.composed_layout<"S<3,4,3> o 0 o (4,8):(1,4)">, !cute.layout<"1:0">
  %r = cute.append_to_rank<4>(%in, %e)
         : !cute.composed_layout<"S<3,4,3> o 0 o (4,8):(1,4)">,
           !cute.layout<"1:0">
  return %r : !cute.composed_layout<"S<3,4,3> o 0 o (4,8,1,1):(1,4,0,0)">
}

// -----

// Rank-2 element for padding.
// CHECK-LABEL: func.func @append_layout_nested_element
// CHECK-SAME:  (%[[IN:.+]]: !cute.layout<"(4,8):(1,4)">, %[[E:.+]]: !cute.layout<"(1,2):(1,0)">)
func.func @append_layout_nested_element(
    %in: !cute.layout<"(4,8):(1,4)">,
    %e: !cute.layout<"(1,2):(1,0)">)
    -> !cute.layout<"(4,8,(1,2),(1,2)):(1,4,(1,0),(1,0))"> {
  // CHECK: %[[R:.+]] = cute.append_to_rank<4> (%[[IN]], %[[E]]) : !cute.layout<"(4,8):(1,4)">, !cute.layout<"(1,2):(1,0)">
  %r = cute.append_to_rank<4>(%in, %e)
         : !cute.layout<"(4,8):(1,4)">, !cute.layout<"(1,2):(1,0)">
  return %r : !cute.layout<"(4,8,(1,2),(1,2)):(1,4,(1,0),(1,0))">
}

// -----

// Composed + rank-2 element for padding.
// CHECK-LABEL: func.func @append_composed_layout_nested_element
// CHECK-SAME:  (%[[IN:.+]]: !cute.composed_layout<"S<1,4,3> o 5 o (1,2):(3,4)">, %[[E:.+]]: !cute.layout<"(1,2):(1,0)">)
func.func @append_composed_layout_nested_element(
    %in: !cute.composed_layout<"S<1,4,3> o 5 o (1,2):(3,4)">,
    %e: !cute.layout<"(1,2):(1,0)">)
    -> !cute.composed_layout<"S<1,4,3> o 5 o (1,2,(1,2),(1,2)):(3,4,(1,0),(1,0))"> {
  // CHECK: %[[R:.+]] = cute.append_to_rank<4> (%[[IN]], %[[E]]) : !cute.composed_layout<"S<1,4,3> o 5 o (1,2):(3,4)">, !cute.layout<"(1,2):(1,0)">
  %r = cute.append_to_rank<4>(%in, %e)
         : !cute.composed_layout<"S<1,4,3> o 5 o (1,2):(3,4)">,
           !cute.layout<"(1,2):(1,0)">
  return %r : !cute.composed_layout<"S<1,4,3> o 5 o (1,2,(1,2),(1,2)):(3,4,(1,0),(1,0))">
}

// -----

// Dynamic input: the dynamic extent survives in the result.
// CHECK-LABEL: func.func @append_dynamic_input
// CHECK-SAME:  (%[[IN:.+]]: !cute.shape<"(?,3)">, %[[E:.+]]: !cute.shape<"1">)
func.func @append_dynamic_input(%in: !cute.shape<"(?,3)">, %e: !cute.shape<"1">) -> !cute.shape<"(?,3,1,1)"> {
  // CHECK: %[[R:.+]] = cute.append_to_rank<4> (%[[IN]], %[[E]]) : !cute.shape<"(?,3)">, !cute.shape<"1">
  %r = cute.append_to_rank<4>(%in, %e) : !cute.shape<"(?,3)">, !cute.shape<"1">
  return %r : !cute.shape<"(?,3,1,1)">
}
