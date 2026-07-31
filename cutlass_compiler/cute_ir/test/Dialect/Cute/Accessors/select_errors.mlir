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

// RUN: cute-opt %s --split-input-file -verify-diagnostics

// Tests error cases for cute.select.

// -----

// Mode index out of range: layout (4,8):(1,4) has rank 2, index 5 is invalid.
func.func @mode_out_of_range(%l: !cute.layout<"(4,8):(1,4)">) {
  // expected-error@+2 {{expects mode index in [0, 2), but got 5}}
  // expected-error@+1 {{'cute.select' op failed to infer returned types}}
  %r = cute.select<[5]>(%l) : !cute.layout<"(4,8):(1,4)"> -> !cute.layout<"(4):(1)">
  return
}

// -----

// Mode index out of range on a shape: (4,8,2) has rank 3, index 3 is invalid.
func.func @mode_out_of_range_shape(%s: !cute.shape<"(4,8,2)">) {
  // expected-error@+2 {{expects mode index in [0, 3), but got 3}}
  // expected-error@+1 {{'cute.select' op failed to infer returned types}}
  %r = cute.select<[3]>(%s) : !cute.shape<"(4,8,2)"> -> !cute.shape<"(4)">
  return
}

// -----

// Negative mode index is out of range.
func.func @negative_mode(%i: !cute.int_tuple<"(1,2,3)">) {
  // expected-error@+2 {{expects mode index in [0, 3), but got -1}}
  // expected-error@+1 {{'cute.select' op failed to infer returned types}}
  %r = cute.select<[-1]>(%i) : !cute.int_tuple<"(1,2,3)"> -> !cute.int_tuple<"(1)">
  return
}

// -----

// Operand kind not an indexable type.
func.func @bad_operand_swizzle(%sw: !cute.swizzle<"S<3,5,4>">) {
  // expected-error@+1 {{'cute.select' op operand #0 must be !cute.shape, !cute.int_tuple, !cute.coord, !cute.stride, !cute.tile, !cute.layout, or !cute.composed_layout, but got '!cute.swizzle<"S<3,5,4>">'}}
  %r = cute.select<[0]>(%sw) : !cute.swizzle<"S<3,5,4>"> -> !cute.swizzle<"S<3,5,4>">
  return
}

// -----

// Declared result kind doesn't match the input kind.
func.func @result_wrong_kind(%s: !cute.shape<"(4,2)">) {
  // expected-error@+2 {{'cute.select' op inferred type(s) '!cute.shape<"(4)">' are incompatible with return type(s) of operation '!cute.coord<"(4)">'}}
  // expected-error@+1 {{'cute.select' op failed to infer returned types}}
  %r = cute.select<[0]>(%s) : !cute.shape<"(4,2)"> -> !cute.coord<"(4)">
  return
}

// -----

// Same kind but wrong sub-value: select<[0]>(shape "(4,2)") infers
// shape "(4)" but the result is declared as shape "(2)". Caught by
// InferTypeOpInterface.
func.func @result_wrong_value(%s: !cute.shape<"(4,2)">) {
  // expected-error@+2 {{'cute.select' op inferred type(s) '!cute.shape<"(4)">' are incompatible with return type(s) of operation '!cute.shape<"(2)">'}}
  // expected-error@+1 {{'cute.select' op failed to infer returned types}}
  %r = cute.select<[0]>(%s) : !cute.shape<"(4,2)"> -> !cute.shape<"(2)">
  return
}

// -----

// Tile operand: declaring a bare layout result is wrong — cute.select
// on a tile returns a tile wrapping the picked slots, not the bare
// layout of a single slot.
func.func @tile_result_unwrapped(%t: !cute.tile<"[(4,8):(1,4);(2,3):(1,2)]">) {
  // expected-error@+2 {{'cute.select' op inferred type(s) '!cute.tile<"[(4,8):(1,4)]">' are incompatible with return type(s) of operation '!cute.layout<"(4,8):(1,4)">'}}
  // expected-error@+1 {{'cute.select' op failed to infer returned types}}
  %r = cute.select<[0]>(%t) : !cute.tile<"[(4,8):(1,4);(2,3):(1,2)]"> -> !cute.layout<"(4,8):(1,4)">
  return
}

// -----

// ComposedLayout operand: declaring a plain layout result is wrong —
// cute.select on a composed_layout slices the outer B but keeps the
// composed structure (inner + offset preserved), so the result is
// still a composed_layout.
func.func @composed_result_unwrapped(%cl: !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">) {
  // expected-error@+2 {{'cute.select' op inferred type(s) '!cute.composed_layout<"(4,5):(1,4) o 2 o (2):(1)">' are incompatible with return type(s) of operation '!cute.layout<"(2):(1)">'}}
  // expected-error@+1 {{'cute.select' op failed to infer returned types}}
  %r = cute.select<[0]>(%cl) : !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)"> -> !cute.layout<"(2):(1)">
  return
}
