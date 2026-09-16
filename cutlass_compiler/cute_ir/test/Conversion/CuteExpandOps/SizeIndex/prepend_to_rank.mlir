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

// Tests `cute-expand-ops` lowering for `cute.prepend_to_rank`.

// -----

// Static shape rank 2 → rank 4: result fully resolved.
// CHECK-LABEL: func.func @expand_static_shape
// CHECK-NOT:   cute.prepend_to_rank
// CHECK:       cute.static : !cute.shape<"(1,1,4,8)">
func.func @expand_static_shape(%in: !cute.shape<"(4,8)">,
                                %e: !cute.shape<"1">)
    -> !cute.shape<"(1,1,4,8)"> {
  %r = cute.prepend_to_rank<4>(%in, %e)
         : !cute.shape<"(4,8)">, !cute.shape<"1">
  return %r : !cute.shape<"(1,1,4,8)">
}

// -----

// Dynamic shape: cutegen rebuilds the rank-N result via make_shape.
// CHECK-LABEL: func.func @expand_shape_dynamic
// CHECK-NOT:   cute.prepend_to_rank
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_shape
// CHECK-SAME:  -> !cute.shape<"(1,1,?,8)">
func.func @expand_shape_dynamic(%in: !cute.shape<"(?,8)">,
                                 %e: !cute.shape<"1">)
    -> !cute.shape<"(1,1,?,8)"> {
  %r = cute.prepend_to_rank<4>(%in, %e)
         : !cute.shape<"(?,8)">, !cute.shape<"1">
  return %r : !cute.shape<"(1,1,?,8)">
}

// -----

// Static layout rank 1 → rank 3 with identity padding.
// CHECK-LABEL: func.func @expand_static_layout
// CHECK-NOT:   cute.prepend_to_rank
// CHECK:       cute.static : !cute.layout<"(1,1,4):(0,0,1)">
func.func @expand_static_layout(%in: !cute.layout<"4:1">,
                                 %e: !cute.layout<"1:0">)
    -> !cute.layout<"(1,1,4):(0,0,1)"> {
  %r = cute.prepend_to_rank<3>(%in, %e)
         : !cute.layout<"4:1">, !cute.layout<"1:0">
  return %r : !cute.layout<"(1,1,4):(0,0,1)">
}

// -----

// Dynamic layout: rebuild via make_layout.
// CHECK-LABEL: func.func @expand_layout_dynamic
// CHECK-NOT:   cute.prepend_to_rank
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_layout
// CHECK-SAME:  -> !cute.layout<"(1,?):(0,?)">
func.func @expand_layout_dynamic(%in: !cute.layout<"?:?">,
                                  %e: !cute.layout<"1:0">)
    -> !cute.layout<"(1,?):(0,?)"> {
  %r = cute.prepend_to_rank<2>(%in, %e)
         : !cute.layout<"?:?">, !cute.layout<"1:0">
  return %r : !cute.layout<"(1,?):(0,?)">
}

// -----

// Dynamic composed layout.
// CHECK-LABEL: func.func @expand_composed_dynamic
// CHECK-NOT:   cute.prepend_to_rank
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_composed_layout
// CHECK-SAME:  -> <"(4,5):(1,4) o 0 o (1,?,3):(0,?,4)">
func.func @expand_composed_dynamic(
    %in: !cute.composed_layout<"(4,5):(1,4) o 0 o (?,3):(?,4)">,
    %e: !cute.layout<"1:0">)
    -> !cute.composed_layout<"(4,5):(1,4) o 0 o (1,?,3):(0,?,4)"> {
  %r = cute.prepend_to_rank<3>(%in, %e)
         : !cute.composed_layout<"(4,5):(1,4) o 0 o (?,3):(?,4)">,
           !cute.layout<"1:0">
  return %r : !cute.composed_layout<"(4,5):(1,4) o 0 o (1,?,3):(0,?,4)">
}

// -----

// Dynamic stride: spot-check tuple-like rebuild via make_stride.
// CHECK-LABEL: func.func @expand_stride_dynamic
// CHECK-NOT:   cute.prepend_to_rank
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_stride
// CHECK-SAME:  -> !cute.stride<"(0,0,?,4)">
func.func @expand_stride_dynamic(%in: !cute.stride<"(?,4)">,
                                  %e: !cute.stride<"0">)
    -> !cute.stride<"(0,0,?,4)"> {
  %r = cute.prepend_to_rank<4>(%in, %e)
         : !cute.stride<"(?,4)">, !cute.stride<"0">
  return %r : !cute.stride<"(0,0,?,4)">
}

// -----

// Coord spot-check (mirror of append's case for symmetry).
// CHECK-LABEL: func.func @expand_coord_dynamic
// CHECK-NOT:   cute.prepend_to_rank
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_coord
// CHECK-SAME:  -> !cute.coord<"(0,0,?,2)">
func.func @expand_coord_dynamic(%in: !cute.coord<"(?,2)">,
                                 %e: !cute.coord<"0">)
    -> !cute.coord<"(0,0,?,2)"> {
  %r = cute.prepend_to_rank<4>(%in, %e)
         : !cute.coord<"(?,2)">, !cute.coord<"0">
  return %r : !cute.coord<"(0,0,?,2)">
}

// -----

// int_tuple spot-check — the fourth tuple-like kind.
// CHECK-LABEL: func.func @expand_int_tuple_dynamic
// CHECK-NOT:   cute.prepend_to_rank
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_int_tuple
// CHECK-SAME:  -> !cute.int_tuple<"(1,1,?,3)">
func.func @expand_int_tuple_dynamic(%in: !cute.int_tuple<"(?,3)">,
                                     %e: !cute.int_tuple<"1">)
    -> !cute.int_tuple<"(1,1,?,3)"> {
  %r = cute.prepend_to_rank<4>(%in, %e)
         : !cute.int_tuple<"(?,3)">, !cute.int_tuple<"1">
  return %r : !cute.int_tuple<"(1,1,?,3)">
}

// -----

// Static composed layout: fully-static result.
// CHECK-LABEL: func.func @expand_static_composed
// CHECK-NOT:   cute.prepend_to_rank
// CHECK:       cute.static : !cute.composed_layout<"(4,5):(1,4) o 0 o (1,4,3):(0,1,4)">
func.func @expand_static_composed(
    %in: !cute.composed_layout<"(4,5):(1,4) o 0 o (4,3):(1,4)">,
    %e: !cute.layout<"1:0">)
    -> !cute.composed_layout<"(4,5):(1,4) o 0 o (1,4,3):(0,1,4)"> {
  %r = cute.prepend_to_rank<3>(%in, %e)
         : !cute.composed_layout<"(4,5):(1,4) o 0 o (4,3):(1,4)">,
           !cute.layout<"1:0">
  return %r : !cute.composed_layout<"(4,5):(1,4) o 0 o (1,4,3):(0,1,4)">
}

// -----

// Mixed widths: i64 input leaf and i32 element, prepended ranks filled with i32.
// CHECK-LABEL: func.func @expand_mixed_in_i64_e_i32
// CHECK-NOT:   cute.prepend_to_rank
// CHECK:       cute.get_scalars<{only_dynamic}> (%{{.+}}) : !cute.shape<"(?{i64},2)">
// CHECK:       cute.get_scalars<{only_dynamic}> (%{{.+}}) : !cute.shape<"?">
// CHECK:       cute.make_shape
// CHECK-SAME:  (i32, i32, i64)
// CHECK-SAME:  -> !cute.shape<"(?,?,?{i64},2)">
func.func @expand_mixed_in_i64_e_i32(%in: !cute.shape<"(?{i64},2)">,
                                      %e: !cute.shape<"?">)
    -> !cute.shape<"(?,?,?{i64},2)"> {
  %r = cute.prepend_to_rank<4>(%in, %e)
         : !cute.shape<"(?{i64},2)">, !cute.shape<"?">
  return %r : !cute.shape<"(?,?,?{i64},2)">
}

// -----

// Reverse mix: input is plain `?` (i32), element is i64.
// CHECK-LABEL: func.func @expand_mixed_in_i32_e_i64
// CHECK-NOT:   cute.prepend_to_rank
// CHECK:       cute.get_scalars<{only_dynamic}> (%{{.+}}) : !cute.shape<"(?,2)">
// CHECK:       cute.get_scalars<{only_dynamic}> (%{{.+}}) : !cute.shape<"?{i64}">
// CHECK:       cute.make_shape
// CHECK-SAME:  (i64, i64, i32)
// CHECK-SAME:  -> !cute.shape<"(?{i64},?{i64},?,2)">
func.func @expand_mixed_in_i32_e_i64(%in: !cute.shape<"(?,2)">,
                                      %e: !cute.shape<"?{i64}">)
    -> !cute.shape<"(?{i64},?{i64},?,2)"> {
  %r = cute.prepend_to_rank<4>(%in, %e)
         : !cute.shape<"(?,2)">, !cute.shape<"?{i64}">
  return %r : !cute.shape<"(?{i64},?{i64},?,2)">
}

// -----

// Both in and e carry i64 dynamic leaves; result mirrors widths across prepended ranks.
// CHECK-LABEL: func.func @expand_both_i64
// CHECK-NOT:   cute.prepend_to_rank
// CHECK:       cute.get_scalars<{only_dynamic}> (%{{.+}}) : !cute.shape<"(?{i64},2)">
// CHECK:       cute.get_scalars<{only_dynamic}> (%{{.+}}) : !cute.shape<"?{i64}">
// CHECK:       cute.make_shape
// CHECK-SAME:  (i64, i64, i64)
// CHECK-SAME:  -> !cute.shape<"(?{i64},?{i64},?{i64},2)">
func.func @expand_both_i64(%in: !cute.shape<"(?{i64},2)">,
                                        %e: !cute.shape<"?{i64}">)
    -> !cute.shape<"(?{i64},?{i64},?{i64},2)"> {
  %r = cute.prepend_to_rank<4>(%in, %e)
         : !cute.shape<"(?{i64},2)">, !cute.shape<"?{i64}">
  return %r : !cute.shape<"(?{i64},?{i64},?{i64},2)">
}
