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

// Tests error cases for `cute.to_int_tuple`.

// -----

// Layouts are not tuple-like.
func.func @bad_operand_layout(%l: !cute.layout<"(4,8):(1,4)">) {
  // expected-error@+1 {{'cute.to_int_tuple' op operand #0 must be}}
  %r = cute.to_int_tuple(%l) : !cute.layout<"(4,8):(1,4)"> -> !cute.int_tuple<"(4,8)">
  return
}

// -----

// Scalar scaled-basis stride — cannot be converted to an int_tuple.
func.func @scaled_basis_scalar(%s: !cute.stride<"4@0">) {
  // expected-error@+2 {{expects source without scaled-basis strides, but got '!cute.stride<"4@0">'}}
  // expected-error@+1 {{'cute.to_int_tuple' op failed to infer returned types}}
  %r = cute.to_int_tuple(%s) : !cute.stride<"4@0"> -> !cute.int_tuple<"4">
  return
}

// -----

// Tuple stride with all-scaled-basis leaves.
func.func @scaled_basis_tuple(%s: !cute.stride<"(?@0,?@1)">) {
  // expected-error@+2 {{expects source without scaled-basis strides, but got '!cute.stride<"(?@0,?@1)">'}}
  // expected-error@+1 {{'cute.to_int_tuple' op failed to infer returned types}}
  %r = cute.to_int_tuple(%s) : !cute.stride<"(?@0,?@1)"> -> !cute.int_tuple<"(1,4)">
  return
}

// -----

// Coord source containing an underscore element. "_" can't be
// used in a coord.
func.func @underscore_in_coord(%c: !cute.coord<"(4,_)">) {
  // expected-error@+2 {{expects source without underscores (_), but got '!cute.coord<"(4,_)">'}}
  // expected-error@+1 {{'cute.to_int_tuple' op failed to infer returned types}}
  %r = cute.to_int_tuple(%c) : !cute.coord<"(4,_)"> -> !cute.int_tuple<"(4,8)">
  return
}

// -----

// Declared result kind is not !cute.int_tuple.
func.func @result_wrong_kind(%s: !cute.shape<"(4,8)">) {
  // expected-error@+1 {{'cute.to_int_tuple' op result #0 must be Scalar integer or recursive tuple of integers, but got '!cute.shape<"(4,8)">'}}
  %r = cute.to_int_tuple(%s) : !cute.shape<"(4,8)"> -> !cute.shape<"(4,8)">
  return
}

// -----

// Declared result is an int_tuple with the wrong values.
func.func @result_wrong_value(%s: !cute.shape<"(4,8)">) {
  // expected-error@+2 {{'cute.to_int_tuple' op inferred type(s) '!cute.int_tuple<"(4,8)">' are incompatible with return type(s) of operation '!cute.int_tuple<"(4,16)">'}}
  // expected-error@+1 {{'cute.to_int_tuple' op failed to infer returned types}}
  %r = cute.to_int_tuple(%s) : !cute.shape<"(4,8)"> -> !cute.int_tuple<"(4,16)">
  return
}
