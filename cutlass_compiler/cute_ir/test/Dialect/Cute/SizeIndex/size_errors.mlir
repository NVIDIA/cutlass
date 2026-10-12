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

// Tests error cases for cute.size.

// -----

// Operand kind not in {shape, int_tuple, layout, composed_layout, tile}.
func.func @bad_operand_swizzle(%sw: !cute.swizzle<"S<3,5,4>">) {
  // expected-error@+1 {{'cute.size' op operand #0 must be}}
  %r = cute.size(%sw) : (!cute.swizzle<"S<3,5,4>">) -> !cute.int_tuple<"1">
  return
}

// -----

// Mode index out of range for a rank-2 shape.
func.func @size_mode_out_of_range(%src: !cute.shape<"(4,3)">) {
  // expected-error@+2 {{expects mode index in [0, 2) at depth 0, but got 2}}
  // expected-error@+1 {{'cute.size' op failed to infer returned types}}
  %r = cute.size <[2]>(%src) : (!cute.shape<"(4,3)">) -> !cute.int_tuple<"1">
  return
}

// -----

// Nested mode: second index out of range for the rank-2 sub-tuple at mode [1].
func.func @size_nested_mode_out_of_range(%src: !cute.shape<"(4,(3,2))">) {
  // expected-error@+2 {{expects mode index in [0, 2) at depth 1, but got 2}}
  // expected-error@+1 {{'cute.size' op failed to infer returned types}}
  %r = cute.size <[1,2]>(%src) : (!cute.shape<"(4,(3,2))">) -> !cute.int_tuple<"1">
  return
}

// -----

// Negative top-level mode index is rejected at depth 0.
func.func @size_negative_mode(%src: !cute.shape<"(4,3)">) {
  // expected-error@+2 {{expects mode index in [0, 2) at depth 0, but got -1}}
  // expected-error@+1 {{'cute.size' op failed to infer returned types}}
  %r = cute.size <[-1]>(%src) : (!cute.shape<"(4,3)">) -> !cute.int_tuple<"1">
  return
}

// -----

// Negative nested mode index is rejected at the descending depth.
func.func @size_nested_negative_mode(%src: !cute.shape<"(4,(3,2))">) {
  // expected-error@+2 {{expects mode index in [0, 2) at depth 1, but got -1}}
  // expected-error@+1 {{'cute.size' op failed to infer returned types}}
  %r = cute.size <[1,-1]>(%src) : (!cute.shape<"(4,(3,2))">) -> !cute.int_tuple<"1">
  return
}

// -----

// Descent past a scalar leaf.
func.func @size_descent_past_scalar_one_extra(%src: !cute.shape<"(4,2)">) {
  // expected-error@+2 {{expects mode indices to stop at a scalar leaf, but got 1 extra index after depth 1}}
  // expected-error@+1 {{'cute.size' op failed to infer returned types}}
  %r = cute.size <[0, 0]>(%src) : (!cute.shape<"(4,2)">) -> !cute.int_tuple<"4">
  return
}

// -----

// Many trailing zeros on a scalar shape leaf — same rejection.
func.func @size_descent_past_scalar_many_extras(%src: !cute.shape<"(4,2)">) {
  // expected-error@+2 {{expects mode indices to stop at a scalar leaf, but got 3 extra indices after depth 1}}
  // expected-error@+1 {{'cute.size' op failed to infer returned types}}
  %r = cute.size <[0, 0, 0, 0]>(%src) : (!cute.shape<"(4,2)">) -> !cute.int_tuple<"4">
  return
}

// -----

// Descent past a scalar in a layout.
func.func @size_descent_past_scalar_layout(%src: !cute.layout<"(4,3,2):(1,4,12)">) {
  // expected-error@+2 {{expects mode indices to stop at a scalar leaf, but got 1 extra index after depth 1}}
  // expected-error@+1 {{'cute.size' op failed to infer returned types}}
  %r = cute.size <[1, 0]>(%src) : (!cute.layout<"(4,3,2):(1,4,12)">) -> !cute.int_tuple<"3">
  return
}
