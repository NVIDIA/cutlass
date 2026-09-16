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
// Verify the printed output can be reparsed.
// RUN: cute-opt %s -split-input-file | cute-opt | FileCheck %s
// Verify the generic form round-trips.
// RUN: cute-opt -mlir-print-op-generic %s -split-input-file | cute-opt | FileCheck %s

// Tests parse/print round-trip for cute attribute kinds, attached as
// discardable func.func attributes to exercise parse/print methods.

// -----

// CHECK-LABEL: func.func @int_tuple_attrs
// CHECK-DAG: it_scalar = #cute.int_tuple<"1">
// CHECK-DAG: it_dyn = #cute.int_tuple<"?">
// CHECK-DAG: it_dyn_div = #cute.int_tuple<"?">
// CHECK-DAG: it_tup = #cute.int_tuple<"(1,2)">
// CHECK-DAG: it_nested = #cute.int_tuple<"(1,(2,3))">
func.func @int_tuple_attrs() attributes {
    it_scalar = #cute.int_tuple<"1">,
    it_dyn = #cute.int_tuple<"?">,
    it_dyn_div = #cute.int_tuple<"?">,
    it_tup = #cute.int_tuple<"(1,2)">,
    it_nested = #cute.int_tuple<"(1,(2,3))">} {
  return
}

// -----

// CHECK-LABEL: func.func @shape_attrs
// CHECK-DAG: sh_static = #cute.shape<"(3,4)">
// CHECK-DAG: sh_dyn = #cute.shape<"(?,4)">
// CHECK-DAG: sh_nested = #cute.shape<"((2,3),4)">
func.func @shape_attrs() attributes {
    sh_static = #cute.shape<"(3,4)">,
    sh_dyn = #cute.shape<"(?,4)">,
    sh_nested = #cute.shape<"((2,3),4)">} {
  return
}

// -----

// CHECK-LABEL: func.func @stride_attrs
// CHECK-DAG: st_static = #cute.stride<"(1,4)">
// CHECK-DAG: st_basis = #cute.stride<"(1@0,1@1)">
// CHECK-DAG: st_dyn = #cute.stride<"(?,1)">
func.func @stride_attrs() attributes {
    st_static = #cute.stride<"(1,4)">,
    st_basis = #cute.stride<"(1@0,1@1)">,
    st_dyn = #cute.stride<"(?,1)">} {
  return
}

// -----

// CHECK-LABEL: func.func @coord_attrs
// CHECK-DAG: cd_static = #cute.coord<"(0,1)">
// CHECK-DAG: cd_underscore = #cute.coord<"(_,1)">
// CHECK-DAG: cd_nested = #cute.coord<"((0,1),2)">
func.func @coord_attrs() attributes {
    cd_static = #cute.coord<"(0,1)">,
    cd_underscore = #cute.coord<"(_,1)">,
    cd_nested = #cute.coord<"((0,1),2)">} {
  return
}

// -----

// CHECK-LABEL: func.func @layout_attrs
// CHECK-DAG: ly_static = #cute.layout<"(4,8):(1,4)">
// CHECK-DAG: ly_dyn = #cute.layout<"(?,4):(1,?)">
func.func @layout_attrs() attributes {
    ly_static = #cute.layout<"(4,8):(1,4)">,
    ly_dyn = #cute.layout<"(?,4):(1,?)">} {
  return
}

// -----

// CHECK-LABEL: func.func @tile_attrs
// CHECK-DAG: tl_layouts = #cute.tile<"[(2,3):(1,2);(4,5):(1,4)]">
// CHECK-DAG: tl_underscore = #cute.tile<"[(2,3):(1,2);_]">
func.func @tile_attrs() attributes {
    tl_layouts = #cute.tile<"[(2,3):(1,2);(4,5):(1,4)]">,
    tl_underscore = #cute.tile<"[(2,3):(1,2);_]">} {
  return
}

// -----

// CHECK-LABEL: func.func @composed_layout_attrs
// CHECK-DAG: cl_affine = #cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">
// CHECK-DAG: cl_swizzle = #cute.composed_layout<"S<3,5,4> o 0 o (8,4):(1,8)">
func.func @composed_layout_attrs() attributes {
    cl_affine = #cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">,
    cl_swizzle = #cute.composed_layout<"S<3,5,4> o 0 o (8,4):(1,8)">} {
  return
}

// -----

// CHECK-LABEL: func.func @swizzle_attrs
// CHECK-DAG: sw_canonical = #cute.swizzle<"S<3,5,4>">
// CHECK-DAG: sw_zero = #cute.swizzle<"S<0,0,0>">
func.func @swizzle_attrs() attributes {
    sw_canonical = #cute.swizzle<"S<3,5,4>">,
    sw_zero = #cute.swizzle<"S<0,0,0>">} {
  return
}
