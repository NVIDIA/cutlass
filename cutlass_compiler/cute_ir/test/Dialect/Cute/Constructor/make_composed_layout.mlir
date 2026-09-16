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
// Verify the printed output can be parsed.
// RUN: cute-opt %s -split-input-file | cute-opt | FileCheck %s
// Verify the generic form can be parsed.
// RUN: cute-opt -mlir-print-op-generic %s -split-input-file | cute-opt | FileCheck %s

// -----

// Layout A, scalar offset, static B.
// CHECK-LABEL: func.func @layout_a_static
// CHECK-SAME:  (%[[A:.+]]: !cute.layout<"(4,5):(1,4)">, %[[OFF:.+]]: !cute.int_tuple<"2">, %[[B:.+]]: !cute.layout<"(2,3):(1,2)">)
func.func @layout_a_static(
    %a: !cute.layout<"(4,5):(1,4)">,
    %off: !cute.int_tuple<"2">,
    %b: !cute.layout<"(2,3):(1,2)">
) -> !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)"> {
  // CHECK: %[[CL:.+]] = cute.make_composed_layout(%[[A]], %[[OFF]], %[[B]])
  // CHECK-SAME: "(4,5):(1,4) o 2 o (2,3):(1,2)"
  %cl = cute.make_composed_layout(%a, %off, %b)
          : (!cute.layout<"(4,5):(1,4)">, !cute.int_tuple<"2">, !cute.layout<"(2,3):(1,2)">)
         -> !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">
  // CHECK: return %[[CL]] : !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">
  return %cl : !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">
}

// -----

// Swizzle A, scalar offset, static B.
// CHECK-LABEL: func.func @swizzle_a_static
// CHECK-SAME:  (%[[SW:.+]]: !cute.swizzle<"S<3,5,4>">, %[[OFF:.+]]: !cute.int_tuple<"2">, %[[B:.+]]: !cute.layout<"(2,3):(1,2)">)
func.func @swizzle_a_static(
    %sw: !cute.swizzle<"S<3,5,4>">,
    %off: !cute.int_tuple<"2">,
    %b: !cute.layout<"(2,3):(1,2)">
) -> !cute.composed_layout<"S<3,5,4> o 2 o (2,3):(1,2)"> {
  // CHECK: %[[CL:.+]] = cute.make_composed_layout(%[[SW]], %[[OFF]], %[[B]])
  // CHECK-SAME: "S<3,5,4> o 2 o (2,3):(1,2)"
  %cl = cute.make_composed_layout(%sw, %off, %b)
          : (!cute.swizzle<"S<3,5,4>">, !cute.int_tuple<"2">, !cute.layout<"(2,3):(1,2)">)
         -> !cute.composed_layout<"S<3,5,4> o 2 o (2,3):(1,2)">
  // CHECK: return %[[CL]] : !cute.composed_layout<"S<3,5,4> o 2 o (2,3):(1,2)">
  return %cl : !cute.composed_layout<"S<3,5,4> o 2 o (2,3):(1,2)">
}

// -----

// Swizzle A, zero offset, static B.
// CHECK-LABEL: func.func @swizzle_a_zero_offset
// CHECK-SAME:  (%[[SW:.+]]: !cute.swizzle<"S<3,5,4>">, %[[OFF:.+]]: !cute.int_tuple<"0">, %[[B:.+]]: !cute.layout<"(8,4):(1,8)">)
func.func @swizzle_a_zero_offset(
    %sw: !cute.swizzle<"S<3,5,4>">,
    %off: !cute.int_tuple<"0">,
    %b: !cute.layout<"(8,4):(1,8)">
) -> !cute.composed_layout<"S<3,5,4> o 0 o (8,4):(1,8)"> {
  // CHECK: %[[CL:.+]] = cute.make_composed_layout(%[[SW]], %[[OFF]], %[[B]])
  // CHECK-SAME: "S<3,5,4> o 0 o (8,4):(1,8)"
  %cl = cute.make_composed_layout(%sw, %off, %b)
          : (!cute.swizzle<"S<3,5,4>">, !cute.int_tuple<"0">, !cute.layout<"(8,4):(1,8)">)
         -> !cute.composed_layout<"S<3,5,4> o 0 o (8,4):(1,8)">
  // CHECK: return %[[CL]] : !cute.composed_layout<"S<3,5,4> o 0 o (8,4):(1,8)">
  return %cl : !cute.composed_layout<"S<3,5,4> o 0 o (8,4):(1,8)">
}

// -----

// Layout A, tuple offset, outer B with basis strides.
// CHECK-LABEL: func.func @layout_a_tuple_offset
// CHECK-SAME:  (%[[A:.+]]: !cute.layout<"(4,5):(1,4)">, %[[OFF:.+]]: !cute.int_tuple<"(0,0)">, %[[B:.+]]: !cute.layout<"(2,3):(1@0,1@1)">)
func.func @layout_a_tuple_offset(
    %a: !cute.layout<"(4,5):(1,4)">,
    %off: !cute.int_tuple<"(0,0)">,
    %b: !cute.layout<"(2,3):(1@0,1@1)">
) -> !cute.composed_layout<"(4,5):(1,4) o (0,0) o (2,3):(1@0,1@1)"> {
  // CHECK: %[[CL:.+]] = cute.make_composed_layout(%[[A]], %[[OFF]], %[[B]])
  // CHECK-SAME: "(4,5):(1,4) o (0,0) o (2,3):(1@0,1@1)"
  %cl = cute.make_composed_layout(%a, %off, %b)
          : (!cute.layout<"(4,5):(1,4)">, !cute.int_tuple<"(0,0)">, !cute.layout<"(2,3):(1@0,1@1)">)
         -> !cute.composed_layout<"(4,5):(1,4) o (0,0) o (2,3):(1@0,1@1)">
  // CHECK: return %[[CL]] : !cute.composed_layout<"(4,5):(1,4) o (0,0) o (2,3):(1@0,1@1)">
  return %cl : !cute.composed_layout<"(4,5):(1,4) o (0,0) o (2,3):(1@0,1@1)">
}

// -----

// Swizzle A, zero offset, dynamic B.
// CHECK-LABEL: func.func @swizzle_a_dynamic_b
// CHECK-SAME:  (%[[SW:.+]]: !cute.swizzle<"S<3,5,4>">, %[[OFF:.+]]: !cute.int_tuple<"0">, %[[B:.+]]: !cute.layout<"(?,3):(1,2)">)
func.func @swizzle_a_dynamic_b(
    %sw: !cute.swizzle<"S<3,5,4>">,
    %off: !cute.int_tuple<"0">,
    %b: !cute.layout<"(?,3):(1,2)">
) -> !cute.composed_layout<"S<3,5,4> o 0 o (?,3):(1,2)"> {
  // CHECK: %[[CL:.+]] = cute.make_composed_layout(%[[SW]], %[[OFF]], %[[B]])
  // CHECK-SAME: "S<3,5,4> o 0 o (?,3):(1,2)"
  %cl = cute.make_composed_layout(%sw, %off, %b)
          : (!cute.swizzle<"S<3,5,4>">, !cute.int_tuple<"0">, !cute.layout<"(?,3):(1,2)">)
         -> !cute.composed_layout<"S<3,5,4> o 0 o (?,3):(1,2)">
  // CHECK: return %[[CL]] : !cute.composed_layout<"S<3,5,4> o 0 o (?,3):(1,2)">
  return %cl : !cute.composed_layout<"S<3,5,4> o 0 o (?,3):(1,2)">
}
