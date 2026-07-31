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

// Tests error cases for cute.tuple_product_each.

// -----

// Operand kind not in {int_tuple, shape}.
func.func @bad_operand_coord(%a: !cute.coord<"(2,3)">) {
  // expected-error@+1 {{'cute.tuple_product_each' op operand #0 must be Scalar integer or recursive tuple of integers or Scalar integer or recursive tuple of shape extents, but got '!cute.coord<"(2,3)">'}}
  %r = cute.tuple_product_each(%a) : (!cute.coord<"(2,3)">) -> !cute.int_tuple<"(2,3)">
  return
}

// -----

// Layout is rejected at the ODS level.
func.func @bad_operand_layout(%a: !cute.layout<"(2,3):(1,2)">) {
  // expected-error@+1 {{'cute.tuple_product_each' op operand #0 must be Scalar integer or recursive tuple of integers or Scalar integer or recursive tuple of shape extents, but got '!cute.layout<"(2,3):(1,2)">'}}
  %r = cute.tuple_product_each(%a) : (!cute.layout<"(2,3):(1,2)">) -> !cute.int_tuple<"(2,3)">
  return
}

// -----

// Result kind mismatch: input is `shape`, declared result is `int_tuple`.
// Kind-preserving contract is enforced by InferTypeOpInterface.
func.func @result_kind_mismatch(%a: !cute.shape<"(2,(3,4))">) {
  // expected-error@+2 {{'cute.tuple_product_each' op inferred type(s) '!cute.shape<"(2,12)">' are incompatible with return type(s) of operation '!cute.int_tuple<"(2,12)">'}}
  // expected-error@+1 {{'cute.tuple_product_each' op failed to infer returned types}}
  %r = cute.tuple_product_each(%a) : (!cute.shape<"(2,(3,4))">) -> !cute.int_tuple<"(2,12)">
  return
}

// -----

// Wrong result rank: per-mode product of `(2,(3,4))` has rank 2, but the
// declared result has rank 3. Rejected by InferTypeOpInterface.
func.func @wrong_result_rank(%a: !cute.int_tuple<"(2,(3,4))">) {
  // expected-error@+2 {{'cute.tuple_product_each' op inferred type(s) '!cute.int_tuple<"(2,12)">' are incompatible with return type(s) of operation '!cute.int_tuple<"(2,12,99)">'}}
  // expected-error@+1 {{'cute.tuple_product_each' op failed to infer returned types}}
  %r = cute.tuple_product_each(%a) : (!cute.int_tuple<"(2,(3,4))">) -> !cute.int_tuple<"(2,12,99)">
  return
}

// -----

// Wrong static element value: top-level mode 1 should be 12 (=3*4), not 99.
func.func @wrong_element_value(%a: !cute.int_tuple<"(2,(3,4))">) {
  // expected-error@+2 {{'cute.tuple_product_each' op inferred type(s) '!cute.int_tuple<"(2,12)">' are incompatible with return type(s) of operation '!cute.int_tuple<"(2,99)">'}}
  // expected-error@+1 {{'cute.tuple_product_each' op failed to infer returned types}}
  %r = cute.tuple_product_each(%a) : (!cute.int_tuple<"(2,(3,4))">) -> !cute.int_tuple<"(2,99)">
  return
}
