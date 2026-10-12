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

// Tests verifier error cases for cute.make_tile.

// -----

// Operand kind not in Cute_IntegerType.
func.func @bad_operand_layout(%l: !cute.layout<"(4,8):(1,4)">) {
  // expected-error@+1 {{'cute.make_tile' op operand #0 must be}}
  %t = cute.make_tile(%l) : (!cute.layout<"(4,8):(1,4)">) -> !cute.tile<"[?:1]">
  return
}

// -----

// Too many operands.
func.func @too_many_operands_static(%n: i64) {
  // expected-error@+1 {{'cute.make_tile' op expects 0 dynamic operand(s) for result type '!cute.tile<"[(2,3):(1,2)]">', but got 1}}
  %t = cute.make_tile(%n) : (i64) -> !cute.tile<"[(2,3):(1,2)]">
  return
}

// -----

// Too many operands.
func.func @too_many_operands_underscore(%n: i64) {
  // expected-error@+1 {{'cute.make_tile' op expects 0 dynamic operand(s) for result type '!cute.tile<"[_]">', but got 1}}
  %t = cute.make_tile(%n) : (i64) -> !cute.tile<"[_]">
  return
}

// -----

// Too few operands.
func.func @too_few_operands() {
  // expected-error@+1 {{'cute.make_tile' op expects 2 dynamic operand(s) for result type '!cute.tile<"[(?,3):(1,?)]">', but got 0}}
  %t = cute.make_tile() : () -> !cute.tile<"[(?,3):(1,?)]">
  return
}

// -----

// Too few operands.
func.func @too_few_two_layouts(%m: i32, %n: i32) {
  // expected-error@+1 {{'cute.make_tile' op expects 4 dynamic operand(s) for result type '!cute.tile<"[(?,3):(1,?);(?,2):(1,?)]">', but got 2}}
  %t = cute.make_tile(%m, %n) : (i32, i32) -> !cute.tile<"[(?,3):(1,?);(?,2):(1,?)]">
  return
}

// -----

// Width mismatch: i64 (width=64) for a ? leaf (width=32) — first operand.
func.func @property_mismatch_width_first(%n: i64) {
  // expected-error@+1 {{'cute.make_tile' op expects operand #0 to have (width=32), but got (width=64)}}
  %t = cute.make_tile(%n) : (i64) -> !cute.tile<"[?:1]">
  return
}

// -----

// Width mismatch on second leaf: correct i32 first, but i64 second.
func.func @property_mismatch_width_second(%m: i32, %n: i64) {
  // expected-error@+1 {{'cute.make_tile' op expects operand #1 to have (width=32), but got (width=64)}}
  %t = cute.make_tile(%m, %n) : (i32, i64) -> !cute.tile<"[(?,3):(1,?)]">
  return
}

// -----

// Depth > 0 int_tuple operand rejected at ODS level.
func.func @int_tuple_wrong_rank(%t: !cute.int_tuple<"(?,?)">) {
  // expected-error@+1 {{'cute.make_tile' op operand #0 must be variadic of i32, i64, or depth-0 !cute.int_tuple, but got '!cute.int_tuple<"(?,?)">'}}
  %tile = cute.make_tile(%t) : (!cute.int_tuple<"(?,?)">) -> !cute.tile<"[(?,?):(1,?)]">
  return
}

