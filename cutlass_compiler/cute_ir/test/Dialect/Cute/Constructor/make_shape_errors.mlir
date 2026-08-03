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

// Tests verifier error cases for cute.make_shape.

// -----

// Operand kind not in Cute_IntegerType.
func.func @bad_operand_layout(%l: !cute.layout<"(4,8):(1,4)">) {
  // expected-error@+1 {{'cute.make_shape' op operand #0 must be}}
  %0 = cute.make_shape(%l) : (!cute.layout<"(4,8):(1,4)">) -> !cute.shape<"?">
  return
}

// -----

// Too few operands.
func.func @too_few_operands(%n: i64) {
  // expected-error@+1 {{'cute.make_shape' op expects 2 dynamic operand(s) for result type '!cute.shape<"(?,?)">', but got 1}}
  %0 = cute.make_shape(%n) : (i64) -> !cute.shape<"(?,?)">
  return
}

// -----

// Too many operands.
func.func @too_many_operands(%m: i64, %n: i64) {
  // expected-error@+1 {{'cute.make_shape' op expects 1 dynamic operand(s) for result type '!cute.shape<"(?,3)">', but got 2}}
  %0 = cute.make_shape(%m, %n) : (i64, i64) -> !cute.shape<"(?,3)">
  return
}

// -----

// Non-integer-leaf operand.
func.func @int_shape_wrong_rank(%t: !cute.shape<"(?,?)">) {
  // expected-error@+1 {{'cute.make_shape' op operand #0 must be variadic of i32, i64, or depth-0 !cute.int_tuple, but got '!cute.shape<"(?,?)">'}}
  %0 = cute.make_shape(%t) : (!cute.shape<"(?,?)">) -> !cute.shape<"(?,?)">
  return
}

// -----

// Property mismatch: i64 (width=64) operand vs ? (width=32) dynamic leaf.
func.func @property_mismatch_width(%n: i64) {
  // expected-error@+1 {{'cute.make_shape' op expects operand #0 to have (width=32), but got (width=64)}}
  %0 = cute.make_shape(%n) : (i64) -> !cute.shape<"?">
  return
}

// -----

