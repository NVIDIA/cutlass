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

// Tests error cases for `cute.composition`.

// -----

// Operand kind not in Cute_AnyLayoutType.
func.func @bad_operand_shape(%s: !cute.shape<"(4,8)">, %rhs: !cute.shape<"(2,4)">) {
  // expected-error@+1 {{'cute.composition' op operand #0 must be}}
  %r = cute.composition(%s, %rhs)
         : (!cute.shape<"(4,8)">, !cute.shape<"(2,4)">) -> !cute.layout<"(2,4):(1,2)">
  return
}

// -----

// 1-D outer × 2-mode shape inner. Inner shape has
// more top-level modes than the outer's rank.
func.func @invalid_layout_shape(%l: !cute.layout<"(20):(2)">, %sh: !cute.shape<"(5,4)">) {
  // expected-error@+2 {{expects a valid composition result, but construction failed}}
  // expected-error@+1 {{'cute.composition' op failed to infer returned types}}
  %r = cute.composition(%l, %sh)
         : (!cute.layout<"(20):(2)">, !cute.shape<"(5,4)">)
        -> !cute.layout<"(5,4):(2,10)">
  return
}

// -----

// Wrong declared result type.
func.func @wrong_result_type(%lhs: !cute.layout<"(20):(2)">, %rhs: !cute.layout<"(5,4):(4,1)">) {
  // expected-error@+2 {{inferred type(s) '!cute.layout<"(5,4):(8,2)">' are incompatible with return type(s) of operation '!cute.layout<"(5,4):(1,1)">'}}
  // expected-error@+1 {{'cute.composition' op failed to infer returned types}}
  %r = cute.composition(%lhs, %rhs)
         : (!cute.layout<"(20):(2)">, !cute.layout<"(5,4):(4,1)">)
        -> !cute.layout<"(5,4):(1,1)">
  return
}

// -----

// Scalar inner stride 5 fails the weak divisibility
// condition at the outer mode (shape 4).
func.func @stride_divisibility_scalar(%outer: !cute.layout<"(4,8):(2,1)">,
                                      %inner: !cute.layout<"(33):(5)">) {
  // expected-error@+2 {{expects a valid composition result, but construction failed}}
  // expected-error@+1 {{'cute.composition' op failed to infer returned types}}
  %r = cute.composition(%outer, %inner)
         : (!cute.layout<"(4,8):(2,1)">, !cute.layout<"(33):(5)">)
        -> !cute.layout<"(33):(5)">
  return
}

// -----

// Same divisibility failure with the *bare* scalar form `33:5`
func.func @stride_divisibility_bare_scalar(%outer: !cute.layout<"(4,8):(2,1)">,
                                            %inner: !cute.layout<"33:5">) {
  // expected-error@+2 {{expects a valid composition result, but construction failed}}
  // expected-error@+1 {{'cute.composition' op failed to infer returned types}}
  %r = cute.composition(%outer, %inner)
         : (!cute.layout<"(4,8):(2,1)">, !cute.layout<"33:5">)
        -> !cute.layout<"33:5">
  return
}

// -----

// Vector inner with mode 1 stride 5 fails
// the divisibility condition at outer mode 0 (shape 4).
func.func @stride_divisibility_vector(%outer: !cute.layout<"(4,8):(2,1)">,
                                      %inner: !cute.layout<"(2,5):(1,5)">) {
  // expected-error@+2 {{expects a valid composition result, but construction failed}}
  // expected-error@+1 {{'cute.composition' op failed to infer returned types}}
  %r = cute.composition(%outer, %inner)
         : (!cute.layout<"(4,8):(2,1)">, !cute.layout<"(2,5):(1,5)">)
        -> !cute.layout<"(2,5):(1,5)">
  return
}
