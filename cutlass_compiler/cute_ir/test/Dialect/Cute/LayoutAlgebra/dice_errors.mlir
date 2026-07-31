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

// Tests error cases for cute.dice.

// -----

// Operand kind outside the allowed set.
func.func @bad_operand_swizzle(
    %sw: !cute.swizzle<"S<3,5,4>">,
    %crd: !cute.coord<"(0,_)">) {
  // expected-error@+1 {{expects $input to be !cute.shape, !cute.stride, !cute.int_tuple, !cute.coord, !cute.layout, or !cute.composed_layout, but got '!cute.swizzle<}}
  %r = cute.dice(%sw, %crd)
         : !cute.swizzle<"S<3,5,4>">, !cute.coord<"(0,_)">
  return
}

// -----

// Coord rank (3) > layout rank (2): weakly_congruent fails.
func.func @coord_rank_exceeds_layout(
    %src: !cute.layout<"(8,4):(1,8)">,
    %crd: !cute.coord<"(1,_,1)">) {
  // expected-error@+1 {{expects coord to be weakly congruent with input shape, but got '!cute.layout<"(8,4):(1,8)">' and '!cute.coord<"(1,_,1)">'}}
  %r = cute.dice(%src, %crd)
         : !cute.layout<"(8,4):(1,8)">, !cute.coord<"(1,_,1)">
  return
}

// -----

// Dynamic coord: dice requires a fully-static coordinate (no '?' elements).
func.func @dynamic_coord(
    %src: !cute.layout<"(8,4):(1,8)">,
    %crd: !cute.coord<"(_,?)">) {
  // expected-error@+1 {{expects coord to be static, but got '!cute.coord<"(_,?)">'}}
  %r = cute.dice(%src, %crd)
         : !cute.layout<"(8,4):(1,8)">, !cute.coord<"(_,?)">
  return
}

// -----

// Composed layout outer rank (2) vs coord rank (3): weakly_congruent fails.
func.func @composed_coord_rank_exceeds_outer(
    %src: !cute.composed_layout<"(4,5):(1,4) o 2 o (4,3):(1,4)">,
    %crd: !cute.coord<"(1,_,1)">) {
  // expected-error@+1 {{expects coord to be weakly congruent with input shape, but got '!cute.composed_layout<"(4,5):(1,4) o 2 o (4,3):(1,4)">' and '!cute.coord<"(1,_,1)">'}}
  %r = cute.dice(%src, %crd)
         : !cute.composed_layout<"(4,5):(1,4) o 2 o (4,3):(1,4)">,
           !cute.coord<"(1,_,1)">
  return
}

// -----

// Type-kind mismatch: input is a plain `!cute.layout` but the declared
// result kind is `!cute.composed_layout`.
func.func @kind_mismatch_layout_to_composed(
    %src: !cute.layout<"(2,3):(1,2)">,
    %crd: !cute.coord<"(_,1)">) {
  // expected-error@+2 {{op inferred type(s) '!cute.layout<"(3):(2)">' are incompatible with return type(s) of operation '!cute.composed_layout<"1:0 o 0 o 3:2">'}}
  // expected-error@+1 {{'cute.dice' op failed to infer returned types}}
  %r = "cute.dice"(%src, %crd) :
       (!cute.layout<"(2,3):(1,2)">, !cute.coord<"(_,1)">) ->
       !cute.composed_layout<"1:0 o 0 o 3:2">
  return
}

// -----

// Mirror of the above: input is `!cute.composed_layout` but declared
// result is plain `!cute.layout`.
func.func @kind_mismatch_composed_to_layout(
    %src: !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">,
    %crd: !cute.coord<"(_,1)">) {
  // expected-error@+2 {{op inferred type(s) '!cute.composed_layout<"(4,5):(1,4) o 2 o (3):(2)">' are incompatible with return type(s) of operation '!cute.layout<"(3):(2)">'}}
  // expected-error@+1 {{'cute.dice' op failed to infer returned types}}
  %r = "cute.dice"(%src, %crd) :
       (!cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">, !cute.coord<"(_,1)">) ->
       !cute.layout<"(3):(2)">
  return
}
