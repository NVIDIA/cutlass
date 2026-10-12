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

// Tests error cases for cute.shape_div.

// -----

// Operand kind not shape.
func.func @bad_operand_layout(%l: !cute.layout<"(4,8):(1,4)">, %b: !cute.shape<"(2,4)">) {
  // expected-error@+1 {{'cute.shape_div' op operand #0 must be}}
  %r = cute.shape_div(%l, %b) : (!cute.layout<"(4,8):(1,4)">, !cute.shape<"(2,4)">) -> !cute.shape<"(2,2)">
  return
}

// -----

// Zero divisor: shape_div cannot divide by zero.
func.func @zero_divisor(%a: !cute.shape<"4">, %b: !cute.shape<"0">) {
  // expected-error@+2 {{expects valid operands, but cannot compute shape_div for '!cute.shape<"4">' and '!cute.shape<"0">': divisor is zero}}
  // expected-error@+1 {{'cute.shape_div' op failed to infer returned types}}
  %r = cute.shape_div(%a, %b) : (!cute.shape<"4">, !cute.shape<"0">) -> !cute.shape<"?">
  return
}

// -----

// Indivisible pair: neither 7%3==0 nor 3%7==0.
func.func @indivisible(%a: !cute.shape<"7">, %b: !cute.shape<"3">) {
  // expected-error@+2 {{expects valid operands, but cannot compute shape_div for '!cute.shape<"7">' and '!cute.shape<"3">': 7 is not divisible by 3 (neither 7 % 3 == 0 nor 3 % 7 == 0)}}
  // expected-error@+1 {{'cute.shape_div' op failed to infer returned types}}
  %r = cute.shape_div(%a, %b) : (!cute.shape<"7">, !cute.shape<"3">) -> !cute.shape<"?">
  return
}

// -----

// Nested zero divisor — zero leaf inside a sub-tuple position.
func.func @nested_zero_divisor(
    %a: !cute.shape<"((8,10),(6,4))">,
    %b: !cute.shape<"((2,5),(3,0))">) {
  // expected-error@+2 {{expects valid operands, but cannot compute shape_div for '!cute.shape<"((8,10),(6,4))">' and '!cute.shape<"((2,5),(3,0))">': divisor is zero}}
  // expected-error@+1 {{'cute.shape_div' op failed to infer returned types}}
  %r = cute.shape_div(%a, %b)
       : (!cute.shape<"((8,10),(6,4))">, !cute.shape<"((2,5),(3,0))">)
      -> !cute.shape<"(?,?)">
  return
}

// -----

func.func @result_rank_mismatch(%a: !cute.shape<"(8,10)">, %b: !cute.shape<"(2,5)">) {
  // expected-error@+2 {{'cute.shape_div' op inferred type(s) '!cute.shape<"(4,2)">' are incompatible with return type(s) of operation '!cute.shape<"(4,2,9)">'}}
  // expected-error@+1 {{'cute.shape_div' op failed to infer returned types}}
  %r = cute.shape_div(%a, %b) : (!cute.shape<"(8,10)">, !cute.shape<"(2,5)">) -> !cute.shape<"(4,2,9)">
  return
}
