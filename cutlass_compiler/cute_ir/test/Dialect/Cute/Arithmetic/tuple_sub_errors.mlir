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

// Tests error cases for cute.tuple_sub.

// -----

// Operand kind not Cute_ArithTupleType — rejected by the ODS-level type
// constraint. Coord is a cute type but not int_tuple or shape.
func.func @bad_operand_coord(%c: !cute.coord<"(5,8)">, %b: !cute.int_tuple<"(1,2)">) {
  // expected-error@+1 {{'cute.tuple_sub' op operand #0 must be}}
  %r = cute.tuple_sub(%c, %b) : (!cute.coord<"(5,8)">, !cute.int_tuple<"(1,2)">) -> !cute.int_tuple<"(4,6)">
  return
}

// -----

// Kind mismatch.
func.func @kind_mismatch(%a: !cute.shape<"(5,8)">, %b: !cute.int_tuple<"(1,2)">) {
  // expected-error@+2 {{expects lhs and rhs to have the same kind, but got '!cute.shape<"(5,8)">' and '!cute.int_tuple<"(1,2)">'}}
  // expected-error@+1 {{'cute.tuple_sub' op failed to infer returned types}}
  %r = cute.tuple_sub(%a, %b) : (!cute.shape<"(5,8)">, !cute.int_tuple<"(1,2)">) -> !cute.shape<"(4,6)">
  return
}

// -----

// Scalar lhs paired with a tuple rhs — zero lhs is not an identity for
// subtraction (allowZeroLhs=false), so any scalar lhs is rejected.
func.func @lhs_scalar_rhs_tuple(%a: !cute.int_tuple<"2">, %b: !cute.int_tuple<"(3,4)">) {
  // expected-error@+2 {{expects matching structure, but lhs is a scalar and rhs is a tuple: '!cute.int_tuple<"2">' and '!cute.int_tuple<"(3,4)">'}}
  // expected-error@+1 {{'cute.tuple_sub' op failed to infer returned types}}
  %r = cute.tuple_sub(%a, %b) : (!cute.int_tuple<"2">, !cute.int_tuple<"(3,4)">) -> !cute.int_tuple<"(?,?)">
  return
}

// -----

// Zero scalar lhs with a tuple rhs is also rejected (no zero-lhs identity
// for subtraction).
func.func @zero_lhs_scalar_rhs_tuple(%a: !cute.int_tuple<"0">, %b: !cute.int_tuple<"(3,4)">) {
  // expected-error@+2 {{expects matching structure, but lhs is a scalar and rhs is a tuple: '!cute.int_tuple<"0">' and '!cute.int_tuple<"(3,4)">'}}
  // expected-error@+1 {{'cute.tuple_sub' op failed to infer returned types}}
  %r = cute.tuple_sub(%a, %b) : (!cute.int_tuple<"0">, !cute.int_tuple<"(3,4)">) -> !cute.int_tuple<"(?,?)">
  return
}

// -----

// Non-zero scalar rhs paired with a tuple lhs.
func.func @rhs_scalar_lhs_tuple(%a: !cute.int_tuple<"(5,8)">, %b: !cute.int_tuple<"2">) {
  // expected-error@+2 {{expects matching structure, but rhs is a scalar and lhs is a tuple: '!cute.int_tuple<"(5,8)">' and '!cute.int_tuple<"2">'}}
  // expected-error@+1 {{'cute.tuple_sub' op failed to infer returned types}}
  %r = cute.tuple_sub(%a, %b) : (!cute.int_tuple<"(5,8)">, !cute.int_tuple<"2">) -> !cute.int_tuple<"(?,?)">
  return
}

// -----

// Nesting mismatch: element 0 is a sub-tuple in lhs but a scalar in rhs.
func.func @nesting_mismatch(%a: !cute.int_tuple<"((4,2),3)">, %b: !cute.int_tuple<"(1,2)">) {
  // expected-error@+2 {{expects matching nesting at element 0, but got: '!cute.int_tuple<"((4,2),3)">' and '!cute.int_tuple<"(1,2)">'}}
  // expected-error@+1 {{'cute.tuple_sub' op failed to infer returned types}}
  %r = cute.tuple_sub(%a, %b) : (!cute.int_tuple<"((4,2),3)">, !cute.int_tuple<"(1,2)">) -> !cute.int_tuple<"(?,?)">
  return
}

// -----

// Result mismatch.
func.func @result_rank_mismatch(%a: !cute.int_tuple<"(5,8)">, %b: !cute.int_tuple<"(1,2)">) {
  // expected-error@+2 {{'cute.tuple_sub' op inferred type(s) '!cute.int_tuple<"(4,6)">' are incompatible with return type(s) of operation '!cute.int_tuple<"(4,6,9)">'}}
  // expected-error@+1 {{'cute.tuple_sub' op failed to infer returned types}}
  %r = cute.tuple_sub(%a, %b) : (!cute.int_tuple<"(5,8)">, !cute.int_tuple<"(1,2)">) -> !cute.int_tuple<"(4,6,9)">
  return
}
