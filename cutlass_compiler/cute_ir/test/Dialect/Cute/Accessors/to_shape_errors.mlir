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

// Tests error cases for `cute.to_shape`.

// -----

// Only !cute.int_tuple is accepted as source — a !cute.shape input is
// rejected by the ODS operand-type constraint.
func.func @bad_operand_shape(%s: !cute.shape<"(4,8)">) {
  // expected-error@+1 {{'cute.to_shape' op operand #0 must be}}
  %r = cute.to_shape(%s) : !cute.shape<"(4,8)"> -> !cute.shape<"(4,8)">
  return
}

// -----

// Declared result kind is not !cute.shape — caught by the ODS
// result-type constraint (Cute_ShapeType), not by the verifier.
func.func @result_wrong_kind(%i: !cute.int_tuple<"(4,8)">) {
  // expected-error@+1 {{'cute.to_shape' op result #0 must be Scalar integer or recursive tuple of shape extents, but got '!cute.int_tuple<"(4,8)">'}}
  %r = cute.to_shape(%i) : !cute.int_tuple<"(4,8)"> -> !cute.int_tuple<"(4,8)">
  return
}

// -----

// Declared result is a shape with the wrong values — InferTypeOpInterface
// rejects with the inferred-vs-declared mismatch.
func.func @result_wrong_value(%i: !cute.int_tuple<"(4,8)">) {
  // expected-error@+2 {{'cute.to_shape' op inferred type(s) '!cute.shape<"(4,8)">' are incompatible with return type(s) of operation '!cute.shape<"(4,16)">'}}
  // expected-error@+1 {{'cute.to_shape' op failed to infer returned types}}
  %r = cute.to_shape(%i) : !cute.int_tuple<"(4,8)"> -> !cute.shape<"(4,16)">
  return
}
