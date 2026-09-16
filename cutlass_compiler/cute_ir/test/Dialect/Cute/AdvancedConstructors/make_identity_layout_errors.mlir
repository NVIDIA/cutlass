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

// RUN: cute-opt %s -split-input-file -verify-diagnostics

// Tests error cases for cute.make_identity_layout.

// -----

// Operand kind not a shape.
func.func @bad_operand_layout(%l: !cute.layout<"(4,8):(1,4)">) {
  // expected-error@+1 {{'cute.make_identity_layout' op operand #0 must be}}
  %r = cute.make_identity_layout(%l) : !cute.layout<"(4,8):(1,4)"> -> !cute.layout<"(4,8):(1@0,1@1)">
  return
}

// -----

// Wrong operand type: !cute.int_tuple is not a shape.
func.func @wrong_operand_type(%s: !cute.int_tuple<"(4,2)">) {
  // expected-error@+1 {{operand #0 must be Scalar integer or recursive tuple of shape extents, but got}}
  %l = cute.make_identity_layout(%s) : !cute.int_tuple<"(4,2)"> -> !cute.layout<"(4,2):(1@0,1@1)">
  return
}

// -----

// Result layout does not match the computed identity layout.
func.func @result_mismatch(%s: !cute.shape<"(4,2)">) {
  // expected-error@+2 {{'cute.make_identity_layout' op inferred type(s) '!cute.layout<"(4,2):(1@0,1@1)">' are incompatible with return type(s) of operation '!cute.layout<"(4,2):(1,4)">'}}
  // expected-error@+1 {{'cute.make_identity_layout' op failed to infer returned types}}
  %l = cute.make_identity_layout(%s) : !cute.shape<"(4,2)"> -> !cute.layout<"(4,2):(1,4)">
  return
}
