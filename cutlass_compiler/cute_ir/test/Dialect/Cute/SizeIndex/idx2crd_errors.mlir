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

// Tests error cases for cute.idx2crd.

// -----

// Operand kind not Cute_IntTupleType.
func.func @bad_operand_layout(%l: !cute.layout<"(4,8):(1,4)">, %s: !cute.shape<"(4,8)">) {
  // expected-error@+1 {{'cute.idx2crd' op operand #0 must be}}
  %r = cute.idx2crd(%l, %s)
         : (!cute.layout<"(4,8):(1,4)">, !cute.shape<"(4,8)">) -> !cute.coord<"(?,?)">
  return
}

// -----

// Static rank-3 index with rank-2 shape: index rank > 1 and rank mismatch.
func.func @idx2crd_rank_mismatch_static(
    %idx: !cute.int_tuple<"(1,2,3)">, %s: !cute.shape<"(4,8)">) {
  // expected-error@+2 {{expects index rank 2 (to match shape rank) or scalar, but got 3}}
  // expected-error@+1 {{'cute.idx2crd' op failed to infer returned types}}
  %r = cute.idx2crd(%idx, %s) : (!cute.int_tuple<"(1,2,3)">, !cute.shape<"(4,8)">) -> !cute.coord<"(?,?)">
  return
}

// -----

// Dynamic rank-3 index with rank-2 shape: index rank > 1 and rank mismatch.
func.func @idx2crd_rank_mismatch_dynamic(
    %idx: !cute.int_tuple<"(?,?,?)">, %s: !cute.shape<"(4,8)">) {
  // expected-error@+2 {{expects index rank 2 (to match shape rank) or scalar, but got 3}}
  // expected-error@+1 {{'cute.idx2crd' op failed to infer returned types}}
  %r = cute.idx2crd(%idx, %s) : (!cute.int_tuple<"(?,?,?)">, !cute.shape<"(4,8)">) -> !cute.coord<"(?,?)">
  return
}

// -----

// Wrong static result value.
func.func @idx2crd_wrong_static_value(
    %idx: !cute.int_tuple<"9">, %s: !cute.shape<"(4,8)">) {
  // expected-error@+2 {{'cute.idx2crd' op inferred type(s) '!cute.coord<"(1,2)">' are incompatible with return type(s) of operation '!cute.coord<"(0,0)">'}}
  // expected-error@+1 {{'cute.idx2crd' op failed to infer returned types}}
  %r = cute.idx2crd(%idx, %s) : (!cute.int_tuple<"9">, !cute.shape<"(4,8)">) -> !cute.coord<"(0,0)">
  return
}

// -----

// Wrong result profile.
func.func @idx2crd_wrong_result_profile(
    %idx: !cute.int_tuple<"?">, %s: !cute.shape<"(4,(2,3))">) {
  // expected-error@+2 {{'cute.idx2crd' op inferred type(s) '!cute.coord<"(?,(?,?))">' are incompatible with return type(s) of operation '!cute.coord<"(?,?,?)">'}}
  // expected-error@+1 {{'cute.idx2crd' op failed to infer returned types}}
  %r = cute.idx2crd(%idx, %s) : (!cute.int_tuple<"?">, !cute.shape<"(4,(2,3))">) -> !cute.coord<"(?,?,?)">
  return
}

// -----

// Non-int_tuple index.
func.func @idx2crd_non_int_tuple_index(%idx: i32, %s: !cute.shape<"(4,8)">) {
  // expected-error@+1 {{'cute.idx2crd' op operand #0 must be Scalar integer or recursive tuple of integers, but got 'i32'}}
  %r = cute.idx2crd(%idx, %s) : (i32, !cute.shape<"(4,8)">) -> !cute.coord<"(?,?)">
  return
}

// -----

// Non-shape second operand.
func.func @idx2crd_non_shape_input(
    %idx: !cute.int_tuple<"9">, %l: !cute.layout<"(4,8):(1,4)">) {
  // expected-error@+1 {{'cute.idx2crd' op operand #1 must be Scalar integer or recursive tuple of shape extents, but got '!cute.layout<"(4,8):(1,4)">'}}
  %r = cute.idx2crd(%idx, %l) : (!cute.int_tuple<"9">, !cute.layout<"(4,8):(1,4)">) -> !cute.coord<"(?,?)">
  return
}

// -----

// wrong return kind.
func.func @idx2crd_wrong_return_kind(
    %idx: !cute.int_tuple<"?">, %s: !cute.shape<"(4,2)">) {
  // expected-error@+1 {{'cute.idx2crd' op result #0 must be Scalar integer, underscore wildcard, or recursive tuple of coordinates, but got '!cute.int_tuple<"(?,?)">'}}
  %r = cute.idx2crd(%idx, %s) : (!cute.int_tuple<"?">, !cute.shape<"(4,2)">) -> !cute.int_tuple<"(?,?)">
  return
}

// -----

// nested rank mismatch.
func.func @idx2crd_nested_rank_mismatch(
    %idx: !cute.int_tuple<"(?,(?,?))">, %s: !cute.shape<"(?,(?,?,?))">) {
  // expected-error@+2 {{unable to compute idx2crd for index '!cute.int_tuple<"(?,(?,?))">' and shape '!cute.shape<"(?,(?,?,?))">'}}
  // expected-error@+1 {{'cute.idx2crd' op failed to infer returned types}}
  %r = cute.idx2crd(%idx, %s) : (!cute.int_tuple<"(?,(?,?))">, !cute.shape<"(?,(?,?,?))">) -> !cute.coord<"(?,(?,?))">
  return
}
