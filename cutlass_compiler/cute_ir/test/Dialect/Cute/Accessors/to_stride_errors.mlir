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

// Tests error cases for `cute.to_stride`.

// -----

// Only !cute.int_tuple is accepted as source.
func.func @bad_operand_stride(%s: !cute.stride<"(1,4)">) {
  // expected-error@+1 {{'cute.to_stride' op operand #0 must be}}
  %r = cute.to_stride(%s) : !cute.stride<"(1,4)"> -> !cute.stride<"(1,4)">
  return
}

// -----

// Declared result kind is not !cute.stride.
func.func @result_wrong_kind(%i: !cute.int_tuple<"(1,4)">) {
  // expected-error@+1 {{'cute.to_stride' op result #0 must be Scalar or recursive tuple of stride elements, but got '!cute.int_tuple<"(1,4)">'}}
  %r = cute.to_stride(%i) : !cute.int_tuple<"(1,4)"> -> !cute.int_tuple<"(1,4)">
  return
}

// -----

// Declared result is a stride with the wrong values.
func.func @result_wrong_value(%i: !cute.int_tuple<"(1,4)">) {
  // expected-error@+2 {{'cute.to_stride' op inferred type(s) '!cute.stride<"(1,4)">' are incompatible with return type(s) of operation '!cute.stride<"(1,8)">'}}
  // expected-error@+1 {{'cute.to_stride' op failed to infer returned types}}
  %r = cute.to_stride(%i) : !cute.int_tuple<"(1,4)"> -> !cute.stride<"(1,8)">
  return
}
