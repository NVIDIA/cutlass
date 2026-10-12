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

// Tests error cases for cute.elem_less.

// -----

// Operand kind not int_tuple/shape/coord.
func.func @bad_operand_layout(%l: !cute.layout<"(3,4):(1,3)">, %b: !cute.int_tuple<"(3,4)">) {
  // expected-error@+1 {{'cute.elem_less' op operand #0 must be}}
  %r = cute.elem_less(%l, %b) : (!cute.layout<"(3,4):(1,3)">, !cute.int_tuple<"(3,4)">) -> i1
  return
}

// -----

// Non-congruent inputs: different rank.
func.func @non_congruent_rank(%a: !cute.int_tuple<"(3,4)">, %b: !cute.int_tuple<"(3,4,5)">) {
  // expected-error@+1 {{'cute.elem_less' op expects congruent inputs, but got '!cute.int_tuple<"(3,4)">' and '!cute.int_tuple<"(3,4,5)">'}}
  %r = cute.elem_less(%a, %b) : (!cute.int_tuple<"(3,4)">, !cute.int_tuple<"(3,4,5)">) -> i1
  return
}

// -----

// Non-congruent inputs: scalar vs tuple.
func.func @non_congruent_scalar_tuple(%a: !cute.int_tuple<"3">, %b: !cute.int_tuple<"(3,4)">) {
  // expected-error@+1 {{'cute.elem_less' op expects congruent inputs, but got '!cute.int_tuple<"3">' and '!cute.int_tuple<"(3,4)">'}}
  %r = cute.elem_less(%a, %b) : (!cute.int_tuple<"3">, !cute.int_tuple<"(3,4)">) -> i1
  return
}
