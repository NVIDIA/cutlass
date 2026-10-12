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

// Tests verifier error cases for cute.make_layout.

// -----

// Operand #0 not a shape.
func.func @bad_first_operand(%l: !cute.layout<"(4,2):(1,4)">,
                              %d: !cute.stride<"(1,4)">) {
  // expected-error@+1 {{'cute.make_layout' op operand #0 must be}}
  %r = cute.make_layout(%l, %d)
       : (!cute.layout<"(4,2):(1,4)">, !cute.stride<"(1,4)">) -> !cute.layout<"(4,2):(1,4)">
  return
}

// -----

// Operand #1 not a stride.
func.func @bad_second_operand(%s1: !cute.shape<"(?,2)">, %s2: !cute.shape<"(?,4)">) {
  // expected-error@+1 {{'cute.make_layout' op operand #1 must be}}
  %l = cute.make_layout(%s1, %s2)
       : (!cute.shape<"(?,2)">, !cute.shape<"(?,4)">) -> !cute.layout<"(?,2):(?,4)">
  return
}

// -----

// Shape operand does not match result shape.
func.func @shape_mismatch(%s: !cute.shape<"(?,2)">, %d: !cute.stride<"(1,4)">) {
  // expected-error@+2 {{'cute.make_layout' op inferred type(s) '!cute.layout<"(?,2):(1,4)">' are incompatible with return type(s) of operation '!cute.layout<"(4,2):(1,4)">'}}
  // expected-error@+1 {{'cute.make_layout' op failed to infer returned types}}
  %l = cute.make_layout(%s, %d)
       : (!cute.shape<"(?,2)">, !cute.stride<"(1,4)">) -> !cute.layout<"(4,2):(1,4)">
  return
}

// -----

// Stride operand does not match result stride.
func.func @stride_mismatch(%s: !cute.shape<"(?,2)">, %d: !cute.stride<"(?,8)">) {
  // expected-error@+2 {{'cute.make_layout' op inferred type(s) '!cute.layout<"(?,2):(?,8)">' are incompatible with return type(s) of operation '!cute.layout<"(?,2):(?,4)">'}}
  // expected-error@+1 {{'cute.make_layout' op failed to infer returned types}}
  %l = cute.make_layout(%s, %d)
       : (!cute.shape<"(?,2)">, !cute.stride<"(?,8)">) -> !cute.layout<"(?,2):(?,4)">
  return
}

// -----

// Nested shape operand does not match result nested shape.
func.func @nested_shape_mismatch(%s: !cute.shape<"((?,2),(3,5))">,
                                  %d: !cute.stride<"((1,4),(1,3))">) {
  // expected-error@+2 {{'cute.make_layout' op inferred type(s) '!cute.layout<"((?,2),(3,5)):((1,4),(1,3))">' are incompatible with return type(s) of operation '!cute.layout<"((4,2),(3,5)):((1,4),(1,3))">'}}
  // expected-error@+1 {{'cute.make_layout' op failed to infer returned types}}
  %l = cute.make_layout(%s, %d)
       : (!cute.shape<"((?,2),(3,5))">, !cute.stride<"((1,4),(1,3))">)
      -> !cute.layout<"((4,2),(3,5)):((1,4),(1,3))">
  return
}

// -----

// Basis stride operand has reversed indices vs the result type.
func.func @basis_stride_mismatch(%s: !cute.shape<"(2,3)">,
                                  %d: !cute.stride<"(1@1,1@0)">) {
  // expected-error@+2 {{'cute.make_layout' op inferred type(s) '!cute.layout<"(2,3):(1@1,1@0)">' are incompatible with return type(s) of operation '!cute.layout<"(2,3):(1@0,1@1)">'}}
  // expected-error@+1 {{'cute.make_layout' op failed to infer returned types}}
  %l = cute.make_layout(%s, %d)
       : (!cute.shape<"(2,3)">, !cute.stride<"(1@1,1@0)">) -> !cute.layout<"(2,3):(1@0,1@1)">
  return
}
