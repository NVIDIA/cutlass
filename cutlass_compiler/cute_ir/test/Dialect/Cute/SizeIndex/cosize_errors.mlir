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

// Tests error cases for cute.cosize.

// -----

// Operand kind not in the allowed layout set.
func.func @bad_operand_shape(%s: !cute.shape<"(4,8)">) {
  // expected-error@+1 {{'cute.cosize' op operand #0 must be}}
  %r = cute.cosize(%s) : (!cute.shape<"(4,8)">) -> !cute.int_tuple<"32">
  return
}

// -----

// Mode index out of range for a rank-3 layout.
func.func @cosize_mode_out_of_range(%src: !cute.layout<"(4,3,2):(1,4,12)">) {
  // expected-error@+2 {{expects mode index in [0, 3) at depth 0, but got 3}}
  // expected-error@+1 {{'cute.cosize' op failed to infer returned types}}
  %r = cute.cosize <[3]>(%src) : (!cute.layout<"(4,3,2):(1,4,12)">) -> !cute.int_tuple<"1">
  return
}

// -----

// Negative top-level mode index is rejected at depth 0.
func.func @cosize_negative_mode(%src: !cute.layout<"(4,3,2):(1,4,12)">) {
  // expected-error@+2 {{expects mode index in [0, 3) at depth 0, but got -1}}
  // expected-error@+1 {{'cute.cosize' op failed to infer returned types}}
  %r = cute.cosize <[-1]>(%src) : (!cute.layout<"(4,3,2):(1,4,12)">) -> !cute.int_tuple<"1">
  return
}

// -----

// Negative nested mode index is rejected at the descending depth.
func.func @cosize_nested_negative_mode(
    %src: !cute.layout<"(4,(3,2)):(1,(4,12))">) {
  // expected-error@+2 {{expects mode index in [0, 2) at depth 1, but got -1}}
  // expected-error@+1 {{'cute.cosize' op failed to infer returned types}}
  %r = cute.cosize <[1,-1]>(%src)
       : (!cute.layout<"(4,(3,2)):(1,(4,12))">) -> !cute.int_tuple<"1">
  return
}

// -----

// Affine-inner composed layout.
func.func @cosize_affine_inner_composed(
    %src: !cute.composed_layout<"(2,3):(1,2) o 0 o (4,5):(1,4)">) {
  // expected-error@+2 {{expects composed_layout inner to be a swizzle (cosize is undefined for affine inner), but got '!cute.composed_layout<"(2,3):(1,2) o 0 o (4,5):(1,4)">'}}
  // expected-error@+1 {{'cute.cosize' op failed to infer returned types}}
  %r = cute.cosize(%src)
       : (!cute.composed_layout<"(2,3):(1,2) o 0 o (4,5):(1,4)">)
      -> !cute.int_tuple<"20">
  return
}

// -----

// Descent past a scalar leaf.
func.func @cosize_descent_past_scalar(%src: !cute.layout<"(4,3,2):(1,4,12)">) {
  // expected-error@+2 {{expects mode indices to stop at a scalar leaf, but got 1 extra index after depth 1}}
  // expected-error@+1 {{'cute.cosize' op failed to infer returned types}}
  %r = cute.cosize <[1, 0]>(%src)
       : (!cute.layout<"(4,3,2):(1,4,12)">) -> !cute.int_tuple<"9">
  return
}

// -----

// Many trailing zeros on a layout's scalar sub-layout — same rejection.
func.func @cosize_descent_past_scalar_many_extras(
    %src: !cute.layout<"(4,3,2):(1,4,12)">) {
  // expected-error@+2 {{expects mode indices to stop at a scalar leaf, but got 2 extra indices after depth 1}}
  // expected-error@+1 {{'cute.cosize' op failed to infer returned types}}
  %r = cute.cosize <[1, 0, 0]>(%src)
       : (!cute.layout<"(4,3,2):(1,4,12)">) -> !cute.int_tuple<"9">
  return
}
