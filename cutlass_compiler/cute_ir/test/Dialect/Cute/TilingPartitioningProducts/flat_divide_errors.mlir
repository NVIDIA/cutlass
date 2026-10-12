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

// RUN: cute-opt -verify-diagnostics --split-input-file %s

// Tests error cases for `cute.flat_divide`.

// -----

// Operand kind not in Cute_AnyLayoutType.
func.func @bad_operand_shape(%s: !cute.shape<"(4,8)">, %t: !cute.shape<"(2,4)">) {
  // expected-error@+1 {{'cute.flat_divide' op operand #0 must be}}
  %r = cute.flat_divide(%s, %t)
         : (!cute.shape<"(4,8)">, !cute.shape<"(2,4)">) -> !cute.layout<"1:0">
  return
}

// -----

// Shape tiler rank > input rank.
func.func @shape_rank_exceeds_input(
    %a: !cute.layout<"24:1">,
    %b: !cute.shape<"(4,6)">) {
  // expected-error @below {{expects rank(tiler) <= rank(input), but got rank 2 tiler and rank 1 input}}
  // expected-error @below {{op failed to infer returned types}}
  %r = cute.flat_divide(%a, %b)
         : (!cute.layout<"24:1">, !cute.shape<"(4,6)">)
        -> !cute.layout<"(4,6,1):(1,4,0)">
  return
}

// -----

// Tile tiler rank > input rank.
func.func @tile_rank_exceeds_input(
    %a: !cute.layout<"24:1">,
    %b: !cute.tile<"[4:1;6:1]">) {
  // expected-error @below {{expects rank(tiler) <= rank(input), but got rank 2 tiler and rank 1 input}}
  // expected-error @below {{op failed to infer returned types}}
  %r = cute.flat_divide(%a, %b)
         : (!cute.layout<"24:1">, !cute.tile<"[4:1;6:1]">)
        -> !cute.layout<"(4,6,1):(1,4,0)">
  return
}

// -----

// Composed input — rank-check applies to the B component.
func.func @composed_shape_rank_exceeds_b(
    %a: !cute.composed_layout<"S<3,4,3> o 0 o 24:1">,
    %b: !cute.shape<"(4,6)">) {
  // expected-error @below {{expects rank(tiler) <= rank(input), but got rank 2 tiler and rank 1 input}}
  // expected-error @below {{op failed to infer returned types}}
  %r = cute.flat_divide(%a, %b)
         : (!cute.composed_layout<"S<3,4,3> o 0 o 24:1">, !cute.shape<"(4,6)">)
        -> !cute.composed_layout<"S<3,4,3> o 0 o ((4,6),1):((1,4),0)">
  return
}

// -----

// Layout tiler rank > input rank.
func.func @layout_tiler_rank_exceeds_input_ok(
    %a: !cute.layout<"24:1">,
    %b: !cute.layout<"(4,6):(1,4)">)
    -> !cute.layout<"(4,6,1):(1,4,24)"> {
  %r = cute.flat_divide(%a, %b)
         : (!cute.layout<"24:1">, !cute.layout<"(4,6):(1,4)">)
        -> !cute.layout<"(4,6,1):(1,4,24)">
  return %r : !cute.layout<"(4,6,1):(1,4,24)">
}

// -----

// Layout tiler with non-static stride and rank > 1.
func.func @layout_tiler_dyn_stride_rank_gt_1(
    %a: !cute.layout<"(6,8):(8,1)">,
    %b: !cute.layout<"(?,?):(?,?)">) {
  // expected-error @below {{expects tiler to have a static stride or to be rank-1, but got tiler (?,?):(?,?)}}
  // expected-error @below {{op failed to infer returned types}}
  %r = cute.flat_divide(%a, %b)
         : (!cute.layout<"(6,8):(8,1)">, !cute.layout<"(?,?):(?,?)">)
        -> !cute.layout<"1:1">
  return
}

// -----

// Layout tiler with rank-1 dyn-stride.
func.func @layout_tiler_rank1_dyn_stride_ok(
    %a: !cute.layout<"24:1">,
    %b: !cute.layout<"?:?">)
    -> !cute.layout<"(?,?,?):(?,1,?)"> {
  %r = cute.flat_divide(%a, %b)
         : (!cute.layout<"24:1">, !cute.layout<"?:?">)
        -> !cute.layout<"(?,?,?):(?,1,?)">
  return %r : !cute.layout<"(?,?,?):(?,1,?)">
}

// -----

// Tile tiler.
func.func @tile_tiler_dyn_layout_component(
    %a: !cute.layout<"(6,8):(8,1)">,
    %b: !cute.tile<"[(?,?):(?,?);4:1]">) {
  // expected-error @below {{expects tiler to have a static stride or to be rank-1, but got tiler (?,?):(?,?) at mode path [0]}}
  // expected-error @below {{op failed to infer returned types}}
  %r = cute.flat_divide(%a, %b)
         : (!cute.layout<"(6,8):(8,1)">, !cute.tile<"[(?,?):(?,?);4:1]">)
        -> !cute.layout<"1:1">
  return
}

// -----

// Nested tile tiler.
func.func @tile_tiler_nested_dyn_layout_component(
    %a: !cute.layout<"(6,8):(8,1)">,
    %b: !cute.tile<"[[3:1;(?,?):(?,?)];4:1]">) {
  // expected-error @below {{expects tiler to have a static stride or to be rank-1, but got tiler (?,?):(?,?) at mode path [0, 1]}}
  // expected-error @below {{op failed to infer returned types}}
  %r = cute.flat_divide(%a, %b)
         : (!cute.layout<"(6,8):(8,1)">, !cute.tile<"[[3:1;(?,?):(?,?)];4:1]">)
        -> !cute.layout<"1:1">
  return
}

// -----

// Tile tiler with scaled-basis layout sub-component.
func.func @tile_tiler_scaled_basis_component(
    %a: !cute.layout<"(4,3):(1@0,1@1)">,
    %b: !cute.tile<"[2:1@0;3:1@1]">) {
  // expected-error @below {{expects layout components of a tile tiler to have integer-only strides (scaled-basis strides like `N@M` are not supported), but got tiler 2:1@0 at mode path [0]}}
  // expected-error @below {{op failed to infer returned types}}
  %r = cute.flat_divide(%a, %b)
         : (!cute.layout<"(4,3):(1@0,1@1)">, !cute.tile<"[2:1@0;3:1@1]">)
        -> !cute.layout<"1:1">
  return
}

// -----

// Scaled-basis input × static rank-2 layout tiler.
func.func @scaled_basis_input_layout_tiler_sentinel(
    %a: !cute.layout<"(4,3):(1@0,1@1)">,
    %b: !cute.layout<"(2,3):(1,2)">) {
  // expected-error @below {{expects valid operands, but cannot compute divide for '!cute.layout<"(4,3):(1@0,1@1)">' and '!cute.layout<"(2,3):(1,2)">'}}
  // expected-error @below {{op failed to infer returned types}}
  %r = cute.flat_divide(%a, %b)
         : (!cute.layout<"(4,3):(1@0,1@1)">, !cute.layout<"(2,3):(1,2)">)
        -> !cute.layout<"1:1">
  return
}

// -----

// Fully-static input × fully-static rank-2 layout tiler.
func.func @static_input_layout_tiler_composition_sentinel(
    %a: !cute.layout<"(12,32):(1,128)">,
    %b: !cute.layout<"(4,8):(1,4)">) {
  // expected-error @below {{expects valid operands, but cannot compute divide for '!cute.layout<"(12,32):(1,128)">' and '!cute.layout<"(4,8):(1,4)">'}}
  // expected-error @below {{op failed to infer returned types}}
  %r = cute.flat_divide(%a, %b)
         : (!cute.layout<"(12,32):(1,128)">, !cute.layout<"(4,8):(1,4)">)
        -> !cute.layout<"1:1">
  return
}
