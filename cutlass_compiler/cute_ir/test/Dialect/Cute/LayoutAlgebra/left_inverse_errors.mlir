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

// Tests error cases for cute.left_inverse.

// -----

// Operand kind not Cute_LayoutType.
func.func @bad_operand_composed_layout(
    %cl: !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">) {
  // expected-error@+1 {{'cute.left_inverse' op operand #0 must be}}
  %r = cute.left_inverse(%cl)
         : (!cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">)
        -> !cute.layout<"(2,3):(1,2)">
  return
}

// -----

// Dynamic shape: pre-check rejects before computing the inverse.
func.func @dynamic_shape(
    %src: !cute.layout<"(?,3):(3,1)">) {
  // expected-error@+2 {{expects a static-shape input layout, but got '!cute.layout<"(?,3):(3,1)">'}}
  // expected-error@+1 {{'cute.left_inverse' op failed to infer returned types}}
  %r = cute.left_inverse(%src) : (!cute.layout<"(?,3):(3,1)">) -> !cute.layout<"(3,4):(4,1)">
  return
}

// -----

// Dynamic stride: pre-check rejects (left inverse requires static
// stride; right inverse does not).
func.func @dynamic_stride(
    %src: !cute.layout<"(4,3):(3,?)">) {
  // expected-error@+2 {{expects a static-stride input layout for left inverse, but got '!cute.layout<"(4,3):(3,?)">'}}
  // expected-error@+1 {{'cute.left_inverse' op failed to infer returned types}}
  %r = cute.left_inverse(%src) : (!cute.layout<"(4,3):(3,?)">)  -> !cute.layout<"(3,4):(4,1)">
  return
}

// -----

// Wrong declared result type.
func.func @wrong_result_type(
    %src: !cute.layout<"(4,3):(1,4)">) {
  // expected-error@+2 {{'cute.left_inverse' op inferred type(s) '!cute.layout<"12:1">' are incompatible with return type(s) of operation '!cute.layout<"(3,4):(4,1)">'}}
  // expected-error@+1 {{'cute.left_inverse' op failed to infer returned types}}
  %r = cute.left_inverse(%src) : (!cute.layout<"(4,3):(1,4)">) -> !cute.layout<"(3,4):(4,1)">
  return
}

// Stride not a multiple of the cumulative shape coverage.
func.func @stride_not_multiple_of_cumulative_shape(
    %src: !cute.layout<"(8,4,2):(13,2,1)">) {
  // expected-error@+2 {{unable to compute a left inverse for '!cute.layout<"(8,4,2):(13,2,1)">'}}
  // expected-error@+1 {{'cute.left_inverse' op failed to infer returned types}}
  %r = cute.left_inverse(%src) : (!cute.layout<"(8,4,2):(13,2,1)">) -> !cute.layout<"(8,4,2):(13,2,1)">
  return
}
