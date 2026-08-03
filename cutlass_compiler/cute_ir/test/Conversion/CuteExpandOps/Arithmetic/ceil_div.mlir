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

// Tests `cute-expand-ops` lowering for `cute.ceil_div`.

// -----

// (scalar, scalar) static.
// CHECK-LABEL: func.func @expand_scalar_scalar
// CHECK-NOT:   cute.ceil_div
// CHECK:       cute.static : !cute.int_tuple<"3">
func.func @expand_scalar_scalar(%a: !cute.int_tuple<"7">,
                                 %b: !cute.int_tuple<"3">)
    -> !cute.int_tuple<"3"> {
  %r = cute.ceil_div(%a, %b)
         : (!cute.int_tuple<"7">, !cute.int_tuple<"3">)
        -> !cute.int_tuple<"3">
  return %r : !cute.int_tuple<"3">
}

// -----

// (tuple, tuple) static, equal rank — element-wise.
// CHECK-LABEL: func.func @expand_tuple_tuple_static
// CHECK-NOT:   cute.ceil_div
// CHECK:       cute.static : !cute.int_tuple<"(3,3)">
func.func @expand_tuple_tuple_static(%a: !cute.int_tuple<"(8,10)">,
                                      %b: !cute.int_tuple<"(3,4)">)
    -> !cute.int_tuple<"(3,3)"> {
  %r = cute.ceil_div(%a, %b)
         : (!cute.int_tuple<"(8,10)">, !cute.int_tuple<"(3,4)">)
        -> !cute.int_tuple<"(3,3)">
  return %r : !cute.int_tuple<"(3,3)">
}

// -----

// rank(input) > rank(tiler) — extras pass through unchanged.
// CHECK-LABEL: func.func @expand_input_longer
// CHECK-NOT:   cute.ceil_div
// CHECK:       cute.static : !cute.int_tuple<"(3,3,6)">
func.func @expand_input_longer(%a: !cute.int_tuple<"(8,10,6)">,
                                %b: !cute.int_tuple<"(3,4)">)
    -> !cute.int_tuple<"(3,3,6)"> {
  %r = cute.ceil_div(%a, %b)
         : (!cute.int_tuple<"(8,10,6)">, !cute.int_tuple<"(3,4)">)
        -> !cute.int_tuple<"(3,3,6)">
  return %r : !cute.int_tuple<"(3,3,6)">
}

// -----

// Dynamic input, static tiler — element-wise `arith.ceildivsi`.
// CHECK-LABEL: func.func @expand_input_dynamic
// CHECK-NOT:   cute.ceil_div
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK-COUNT-2: arith.ceildivsi {{.+}} : i32
// CHECK-NOT:   arith.ceildivsi
// CHECK:       cute.make_int_tuple
// CHECK-SAME:  -> !cute.int_tuple<"(?,?)">
func.func @expand_input_dynamic(%a: !cute.int_tuple<"(?,?)">,
                                 %b: !cute.int_tuple<"(3,4)">)
    -> !cute.int_tuple<"(?,?)"> {
  %r = cute.ceil_div(%a, %b)
         : (!cute.int_tuple<"(?,?)">, !cute.int_tuple<"(3,4)">)
        -> !cute.int_tuple<"(?,?)">
  return %r : !cute.int_tuple<"(?,?)">
}

// -----

// Cross-kind: int_tuple input, shape tiler — result kind matches input.
// CHECK-LABEL: func.func @expand_cross_kind
// CHECK-NOT:   cute.ceil_div
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       arith.ceildivsi
// CHECK:       cute.make_int_tuple
// CHECK-SAME:  -> !cute.int_tuple<"(?,?)">
func.func @expand_cross_kind(%a: !cute.int_tuple<"(?,?)">,
                              %b: !cute.shape<"(2,3)">)
    -> !cute.int_tuple<"(?,?)"> {
  %r = cute.ceil_div(%a, %b)
         : (!cute.int_tuple<"(?,?)">, !cute.shape<"(2,3)">)
        -> !cute.int_tuple<"(?,?)">
  return %r : !cute.int_tuple<"(?,?)">
}

// -----

// Dynamic shape input, tile tiler.
// CHECK-LABEL: func.func @expand_shape_tile_dyn
// CHECK-NOT:   cute.ceil_div
// CHECK:       arith.ceildivsi
func.func @expand_shape_tile_dyn(%a: !cute.shape<"(?,?)">,
                                 %t: !cute.tile<"(4,8):(1,4)">)
    -> !cute.shape<"?"> {
  %r = cute.ceil_div(%a, %t)
         : (!cute.shape<"(?,?)">, !cute.tile<"(4,8):(1,4)">)
        -> !cute.shape<"?">
  return %r : !cute.shape<"?">
}

// -----

// Dynamic int_tuple input, tile tiler.
// CHECK-LABEL: func.func @expand_int_tuple_tile_dyn
// CHECK-NOT:   cute.ceil_div
// CHECK:       arith.ceildivsi
// CHECK:       cute.make_int_tuple
// CHECK-SAME:  -> !cute.int_tuple<"?">
func.func @expand_int_tuple_tile_dyn(%a: !cute.int_tuple<"(?,?)">,
                                     %t: !cute.tile<"(4,8):(1,4)">)
    -> !cute.int_tuple<"?"> {
  %r = cute.ceil_div(%a, %t)
         : (!cute.int_tuple<"(?,?)">, !cute.tile<"(4,8):(1,4)">)
        -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}
