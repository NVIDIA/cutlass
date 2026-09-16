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

// RUN: cute-opt %s -split-input-file -verify-diagnostics

// Tests error cases for `cute.make_composed_layout`.

// -----

// Inner operand kind not in Cute_InnerComponent — a layout or swizzle.
func.func @bad_operand_shape(
    %s: !cute.shape<"(4,5)">,
    %off: !cute.int_tuple<"2">,
    %b: !cute.layout<"(2,3):(1,2)">
) {
  // expected-error@+1 {{'cute.make_composed_layout' op operand #0 must be}}
  %cl = cute.make_composed_layout(%s, %off, %b)
          : (!cute.shape<"(4,5)">, !cute.int_tuple<"2">, !cute.layout<"(2,3):(1,2)">)
         -> !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">
  return
}

// -----

// Inner layout shape/stride does not match result's layout_a.
func.func @inner_layout_mismatch(
    %a: !cute.layout<"(4,5):(2,8)">,
    %off: !cute.int_tuple<"2">,
    %b: !cute.layout<"(2,3):(1,2)">
) {
  // expected-error@+2 {{'cute.make_composed_layout' op inferred type(s) '!cute.composed_layout<"(4,5):(2,8) o 2 o (2,3):(1,2)">' are incompatible with return type(s) of operation '!cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">'}}
  // expected-error@+1 {{'cute.make_composed_layout' op failed to infer returned types}}
  %cl = cute.make_composed_layout(%a, %off, %b)
          : (!cute.layout<"(4,5):(2,8)">, !cute.int_tuple<"2">, !cute.layout<"(2,3):(1,2)">)
         -> !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">
  return
}

// -----

// Layout operand provided but result A is a swizzle.
func.func @inner_kind_layout_vs_swizzle(
    %a: !cute.layout<"(4,5):(1,4)">,
    %off: !cute.int_tuple<"2">,
    %b: !cute.layout<"(2,3):(1,2)">
) {
  // expected-error@+2 {{'cute.make_composed_layout' op inferred type(s) '!cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">' are incompatible with return type(s) of operation '!cute.composed_layout<"S<3,5,4> o 2 o (2,3):(1,2)">'}}
  // expected-error@+1 {{'cute.make_composed_layout' op failed to infer returned types}}
  %cl = cute.make_composed_layout(%a, %off, %b)
          : (!cute.layout<"(4,5):(1,4)">, !cute.int_tuple<"2">, !cute.layout<"(2,3):(1,2)">)
         -> !cute.composed_layout<"S<3,5,4> o 2 o (2,3):(1,2)">
  return
}

// -----

// Swizzle operand provided but result A is an affine layout.
func.func @inner_kind_swizzle_vs_layout(
    %sw: !cute.swizzle<"S<3,5,4>">,
    %off: !cute.int_tuple<"2">,
    %b: !cute.layout<"(2,3):(1,2)">
) {
  // expected-error@+2 {{'cute.make_composed_layout' op inferred type(s) '!cute.composed_layout<"S<3,5,4> o 2 o (2,3):(1,2)">' are incompatible with return type(s) of operation '!cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">'}}
  // expected-error@+1 {{'cute.make_composed_layout' op failed to infer returned types}}
  %cl = cute.make_composed_layout(%sw, %off, %b)
          : (!cute.swizzle<"S<3,5,4>">, !cute.int_tuple<"2">, !cute.layout<"(2,3):(1,2)">)
         -> !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">
  return
}

// -----

// Swizzle operand params (S<1,5,4>) do not match result's swizzle_a (S<3,5,4>).
func.func @inner_swizzle_mismatch(
    %sw: !cute.swizzle<"S<1,5,4>">,
    %off: !cute.int_tuple<"2">,
    %b: !cute.layout<"(2,3):(1,2)">
) {
  // expected-error@+2 {{'cute.make_composed_layout' op inferred type(s) '!cute.composed_layout<"S<1,5,4> o 2 o (2,3):(1,2)">' are incompatible with return type(s) of operation '!cute.composed_layout<"S<3,5,4> o 2 o (2,3):(1,2)">'}}
  // expected-error@+1 {{'cute.make_composed_layout' op failed to infer returned types}}
  %cl = cute.make_composed_layout(%sw, %off, %b)
          : (!cute.swizzle<"S<1,5,4>">, !cute.int_tuple<"2">, !cute.layout<"(2,3):(1,2)">)
         -> !cute.composed_layout<"S<3,5,4> o 2 o (2,3):(1,2)">
  return
}

// -----

// Offset operand (5) does not match result's offset (2).
func.func @offset_mismatch(
    %a: !cute.layout<"(4,5):(1,4)">,
    %off: !cute.int_tuple<"5">,
    %b: !cute.layout<"(2,3):(1,2)">
) {
  // expected-error@+2 {{'cute.make_composed_layout' op inferred type(s) '!cute.composed_layout<"(4,5):(1,4) o 5 o (2,3):(1,2)">' are incompatible with return type(s) of operation '!cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">'}}
  // expected-error@+1 {{'cute.make_composed_layout' op failed to infer returned types}}
  %cl = cute.make_composed_layout(%a, %off, %b)
          : (!cute.layout<"(4,5):(1,4)">, !cute.int_tuple<"5">, !cute.layout<"(2,3):(1,2)">)
         -> !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">
  return
}

// -----

// Outer layout does not match result's layout_b.
func.func @outer_mismatch(
    %a: !cute.layout<"(4,5):(1,4)">,
    %off: !cute.int_tuple<"2">,
    %b: !cute.layout<"(4,3):(1,4)">
) {
  // expected-error@+2 {{'cute.make_composed_layout' op inferred type(s) '!cute.composed_layout<"(4,5):(1,4) o 2 o (4,3):(1,4)">' are incompatible with return type(s) of operation '!cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">'}}
  // expected-error@+1 {{'cute.make_composed_layout' op failed to infer returned types}}
  %cl = cute.make_composed_layout(%a, %off, %b)
          : (!cute.layout<"(4,5):(1,4)">, !cute.int_tuple<"2">, !cute.layout<"(4,3):(1,4)">)
         -> !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">
  return
}
