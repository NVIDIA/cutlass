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

// Tests error cases for cute.append_to_rank.

// -----

// Operand kind outside the allowed set.
func.func @bad_operand_swizzle(
    %sw: !cute.swizzle<"S<3,5,4>">, %e: !cute.swizzle<"S<3,5,4>">) {
  // expected-error@+1 {{expects $input to be !cute.int_tuple, !cute.coord, !cute.stride, !cute.shape, !cute.layout, or !cute.composed_layout, but got '!cute.swizzle<}}
  %r = cute.append_to_rank<2>(%sw, %e)
         : !cute.swizzle<"S<3,5,4>">, !cute.swizzle<"S<3,5,4>">
  return
}

// -----

// Input and element have different kinds.
func.func @append_kind_mismatch(
    %in: !cute.shape<"(4,8)">, %e: !cute.int_tuple<"1">) {
  // expected-error@+1 {{expects input and element to have the same kind, but got '!cute.shape<"(4,8)">' and '!cute.int_tuple<"1">'}}
  %r = cute.append_to_rank<3>(%in, %e) : !cute.shape<"(4,8)">, !cute.int_tuple<"1">
  return
}

// -----

// Rank must be a positive integer.
func.func @append_rank_zero(
    %in: !cute.shape<"(4,8)">, %e: !cute.shape<"1">) {
  // expected-error@+1 {{expects rank to be a positive integer, but got 0}}
  %r = cute.append_to_rank<0>(%in, %e) : !cute.shape<"(4,8)">, !cute.shape<"1">
  return
}

// -----

// composed_layout requires a layout (not shape) element.
func.func @append_composed_bad_element(
    %in: !cute.composed_layout<"S<3,5,4> o 0 o (8,4):(1,8)">,
    %e: !cute.shape<"1">) {
  // expected-error@+1 {{expects element to be !cute.layout when input is !cute.composed_layout, but got '!cute.shape<"1">'}}
  %r = cute.append_to_rank<3>(%in, %e) : !cute.composed_layout<"S<3,5,4> o 0 o (8,4):(1,8)">, !cute.shape<"1">
  return
}

// -----

// composed_layout input + composed_layout element.
func.func @append_composed_composed_element(
    %in: !cute.composed_layout<"S<1,4,3> o 5 o (1,2):(3,4)">,
    %e: !cute.composed_layout<"S<1,4,3> o 5 o (1,2):(1,0)">) {
  // expected-error@+1 {{expects element to be !cute.layout when input is !cute.composed_layout, but got '!cute.composed_layout<"S<1,4,3> o 5 o (1,2):(1,0)">'}}
  %r = cute.append_to_rank<4>(%in, %e)
       : !cute.composed_layout<"S<1,4,3> o 5 o (1,2):(3,4)">,
         !cute.composed_layout<"S<1,4,3> o 5 o (1,2):(1,0)">
  return
}

// -----

// Negative rank.
func.func @append_negative_rank(
    %in: !cute.shape<"(1,2)">, %e: !cute.shape<"3">) {
  // expected-error@+1 {{expects rank to be a positive integer, but got -5}}
  %r = cute.append_to_rank<-5>(%in, %e) : !cute.shape<"(1,2)">, !cute.shape<"3">
  return
}
