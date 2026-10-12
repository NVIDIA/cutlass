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

// Tests error cases for cute.layout_eval.

// -----

// Operand kind not Cute_CoordType.
func.func @bad_operand_layout(
    %l: !cute.layout<"(1,2):(1,1)">, %ll: !cute.layout<"(4,8):(1,4)">) {
  // expected-error@+1 {{'cute.layout_eval' op operand #0 must be}}
  %r = cute.layout_eval(%l, %ll)
         : (!cute.layout<"(1,2):(1,1)">, !cute.layout<"(4,8):(1,4)">) -> !cute.int_tuple<"?">
  return
}

// -----

// Static non-leaf coord whose rank exceeds layout shape rank.
func.func @layout_eval_rank_mismatch_static(
    %c: !cute.coord<"(1,2,3)">, %l: !cute.layout<"(4,8):(1,4)">) {
  // expected-error@+2 {{expects coordinate rank 2 (to match layout shape rank) or be a leaf, but got 3}}
  // expected-error@+1 {{'cute.layout_eval' op failed to infer returned types}}
  %r = cute.layout_eval(%c, %l) : (!cute.coord<"(1,2,3)">, !cute.layout<"(4,8):(1,4)">) -> !cute.int_tuple<"?">
  return
}

// -----

// Dynamic non-leaf coord whose rank exceeds layout shape rank.
func.func @layout_eval_rank_mismatch_dynamic(
    %c: !cute.coord<"(?,?,?)">, %l: !cute.layout<"(4,8):(1,4)">) {
  // expected-error@+2 {{expects coordinate rank 2 (to match layout shape rank) or be a leaf, but got 3}}
  // expected-error@+1 {{'cute.layout_eval' op failed to infer returned types}}
  %r = cute.layout_eval(%c, %l) : (!cute.coord<"(?,?,?)">, !cute.layout<"(4,8):(1,4)">) -> !cute.int_tuple<"?">
  return
}

// -----

// Composed-layout coord rank mismatch.
func.func @layout_eval_composed_layout_rank_mismatch(
    %c: !cute.coord<"(?,?,?)">,
    %l: !cute.composed_layout<"S<3,4,6> o 0 o (4,8):(1,4)">) {
  // expected-error@+2 {{expects coordinate rank 2 (to match layout shape rank) or be a leaf, but got 3}}
  // expected-error@+1 {{'cute.layout_eval' op failed to infer returned types}}
  %r = cute.layout_eval(%c, %l)
       : (!cute.coord<"(?,?,?)">,
          !cute.composed_layout<"S<3,4,6> o 0 o (4,8):(1,4)">)
      -> !cute.int_tuple<"?">
  return
}

// -----

// Wrong static result value.
func.func @layout_eval_wrong_static_value(
    %c: !cute.coord<"(1,2)">, %l: !cute.layout<"(4,8):(1,4)">) {
  // expected-error@+2 {{'cute.layout_eval' op inferred type(s) '!cute.int_tuple<"9">' are incompatible with return type(s) of operation '!cute.int_tuple<"0">'}}
  // expected-error@+1 {{'cute.layout_eval' op failed to infer returned types}}
  %r = cute.layout_eval(%c, %l) : (!cute.coord<"(1,2)">, !cute.layout<"(4,8):(1,4)">) -> !cute.int_tuple<"0">
  return
}

// -----

// Wrong scaled-basis result structure.
func.func @layout_eval_scaled_basis_wrong_structure(
    %c: !cute.coord<"(?,?)">, %l: !cute.layout<"(4,8):(1@0,1@1)">) {
  // expected-error@+2 {{'cute.layout_eval' op inferred type(s) '!cute.int_tuple<"(?,?)">' are incompatible with return type(s) of operation '!cute.int_tuple<"?">'}}
  // expected-error@+1 {{'cute.layout_eval' op failed to infer returned types}}
  %r = cute.layout_eval(%c, %l) : (!cute.coord<"(?,?)">, !cute.layout<"(4,8):(1@0,1@1)">) -> !cute.int_tuple<"?">
  return
}

// -----

// Non-coord first operand.
func.func @layout_eval_non_coord_input(
    %c: !cute.int_tuple<"(1,2)">, %l: !cute.layout<"(4,8):(1,4)">) {
  // expected-error@+1 {{'cute.layout_eval' op operand #0 must be Scalar integer, underscore wildcard, or recursive tuple of coordinates, but got '!cute.int_tuple<"(1,2)">'}}
  %r = cute.layout_eval(%c, %l) : (!cute.int_tuple<"(1,2)">, !cute.layout<"(4,8):(1,4)">) -> !cute.int_tuple<"9">
  return
}

// -----

// Non-layout second operand.
func.func @layout_eval_non_layout_input(
    %c: !cute.coord<"(1,2)">, %s: !cute.shape<"(4,8)">) {
  // expected-error@+1 {{'cute.layout_eval' op operand #1 must be !cute.layout or !cute.composed_layout, but got '!cute.shape<"(4,8)">'}}
  %r = cute.layout_eval(%c, %s) : (!cute.coord<"(1,2)">, !cute.shape<"(4,8)">) -> !cute.int_tuple<"9">
  return
}

// -----

// Rank mismatch on a scaled-basis layout.
func.func @layout_eval_scaled_basis_rank_mismatch(
    %c: !cute.coord<"(?,?)">, %l: !cute.layout<"(10,20,30):(1@0,1@1,20@1)">) {
  // expected-error@+2 {{expects coordinate rank 3 (to match layout shape rank) or be a leaf, but got 2}}
  // expected-error@+1 {{'cute.layout_eval' op failed to infer returned types}}
  %r = cute.layout_eval(%c, %l) : (!cute.coord<"(?,?)">, !cute.layout<"(10,20,30):(1@0,1@1,20@1)">) -> !cute.int_tuple<"?">
  return
}
