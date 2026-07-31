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

// Tests error cases for cute.tuple_product.

// -----

// Operand kind not in {int_tuple, shape}.
func.func @bad_operand_coord(%a: !cute.coord<"(2,3)">) {
  // expected-error@+1 {{'cute.tuple_product' op operand #0 must be Scalar integer or recursive tuple of integers or Scalar integer or recursive tuple of shape extents, but got '!cute.coord<"(2,3)">'}}
  %r = cute.tuple_product(%a) : (!cute.coord<"(2,3)">) -> !cute.int_tuple<"6">
  return
}

// -----

// Layout.
func.func @bad_operand_layout(%a: !cute.layout<"(2,3):(1,2)">) {
  // expected-error@+1 {{'cute.tuple_product' op operand #0 must be Scalar integer or recursive tuple of integers or Scalar integer or recursive tuple of shape extents, but got '!cute.layout<"(2,3):(1,2)">'}}
  %r = cute.tuple_product(%a) : (!cute.layout<"(2,3):(1,2)">) -> !cute.int_tuple<"6">
  return
}

// -----

// Result kind mismatch.
func.func @result_kind_mismatch(%a: !cute.shape<"(2,3)">) {
  // expected-error@+2 {{'cute.tuple_product' op inferred type(s) '!cute.shape<"6">' are incompatible with return type(s) of operation '!cute.int_tuple<"6">'}}
  // expected-error@+1 {{'cute.tuple_product' op failed to infer returned types}}
  %r = cute.tuple_product(%a) : (!cute.shape<"(2,3)">) -> !cute.int_tuple<"6">
  return
}

// -----

// Wrong static product value.
// inferred product `24` for input `(2,(3,4))`.
func.func @wrong_static_value(%a: !cute.int_tuple<"(2,(3,4))">) {
  // expected-error@+2 {{'cute.tuple_product' op inferred type(s) '!cute.int_tuple<"24">' are incompatible with return type(s) of operation '!cute.int_tuple<"5">'}}
  // expected-error@+1 {{'cute.tuple_product' op failed to infer returned types}}
  %r = cute.tuple_product(%a) : (!cute.int_tuple<"(2,(3,4))">) -> !cute.int_tuple<"5">
  return
}
