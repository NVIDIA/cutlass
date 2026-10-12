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

// Tests error cases for cute.ceil_div.

// -----

// Operand kind not int_tuple or shape.
func.func @bad_operand_coord(%c: !cute.coord<"(4,8)">, %b: !cute.int_tuple<"(2,4)">) {
  // expected-error@+1 {{'cute.ceil_div' op operand #0 must be}}
  %r = cute.ceil_div(%c, %b) : (!cute.coord<"(4,8)">, !cute.int_tuple<"(2,4)">) -> !cute.int_tuple<"(2,2)">
  return
}

// -----

// rank(tiler) > rank(input) for the tuple/tuple case.
func.func @tiler_rank_exceeds_input(%a: !cute.int_tuple<"(4,8)">, %b: !cute.int_tuple<"(2,4,2)">) {
  // expected-error@+2 {{expects valid operands, but cannot compute ceil_div for '!cute.int_tuple<"(4,8)">' and '!cute.int_tuple<"(2,4,2)">': rank(tiler)=3 > rank(input)=2}}
  // expected-error@+1 {{'cute.ceil_div' op failed to infer returned types}}
  %r = cute.ceil_div(%a, %b) : (!cute.int_tuple<"(4,8)">, !cute.int_tuple<"(2,4,2)">) -> !cute.int_tuple<"(?,?,?)">
  return
}

// -----

// Scalar zero tiler.
func.func @scalar_zero_tiler(%a: !cute.int_tuple<"7">, %b: !cute.int_tuple<"0">) {
  // expected-error@+2 {{expects valid operands, but cannot compute ceil_div for '!cute.int_tuple<"7">' and '!cute.int_tuple<"0">': tiler is zero}}
  // expected-error@+1 {{'cute.ceil_div' op failed to infer returned types}}
  %r = cute.ceil_div(%a, %b) : (!cute.int_tuple<"7">, !cute.int_tuple<"0">) -> !cute.int_tuple<"?">
  return
}

// -----

// Nested zero tiler — zero leaf inside a sub-tuple position.
func.func @nested_zero_tiler(
    %a: !cute.int_tuple<"((8,10),(6,4))">,
    %b: !cute.int_tuple<"((2,5),(3,0))">) {
  // expected-error@+2 {{expects valid operands, but cannot compute ceil_div for '!cute.int_tuple<"((8,10),(6,4))">' and '!cute.int_tuple<"((2,5),(3,0))">'}}
  // expected-error@+1 {{'cute.ceil_div' op failed to infer returned types}}
  %r = cute.ceil_div(%a, %b)
       : (!cute.int_tuple<"((8,10),(6,4))">, !cute.int_tuple<"((2,5),(3,0))">)
      -> !cute.int_tuple<"(?,?)">
  return
}

// -----

// Result-rank mismatch: declared result has rank 3 but produces a rank-2 result.
func.func @result_rank_mismatch(%a: !cute.int_tuple<"(8,10)">, %b: !cute.int_tuple<"(3,4)">) {
  // expected-error@+2 {{'cute.ceil_div' op inferred type(s) '!cute.int_tuple<"(3,3)">' are incompatible with return type(s) of operation '!cute.int_tuple<"(3,3,9)">'}}
  // expected-error@+1 {{'cute.ceil_div' op failed to infer returned types}}
  %r = cute.ceil_div(%a, %b) : (!cute.int_tuple<"(8,10)">, !cute.int_tuple<"(3,4)">) -> !cute.int_tuple<"(3,3,9)">
  return
}
