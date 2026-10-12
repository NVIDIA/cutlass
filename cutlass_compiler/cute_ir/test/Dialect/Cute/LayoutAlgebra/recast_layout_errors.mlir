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

// Tests error cases for cute.recast_layout.

// -----

// Operand kind not in Cute_AnyLayoutType.
func.func @bad_operand_shape(%s: !cute.shape<"(4,8)">) {
  // expected-error@+1 {{'cute.recast_layout' op operand #0 must be}}
  %r = cute.recast_layout<8, 8>(%s) : !cute.shape<"(4,8)"> -> !cute.shape<"(4,8)">
  return
}

// -----

// new_type_bits = 0: zero is not a valid bit-width.
func.func @zero_new_bits(
    %src: !cute.layout<"(32,4):(1,32)">) {
  // expected-error@+2 {{expects new_type_bits to be positive, but got 0}}
  // expected-error@+1 {{'cute.recast_layout' op failed to infer returned types}}
  %r = cute.recast_layout<0, 8>(%src)
         : !cute.layout<"(32,4):(1,32)"> -> !cute.layout<"1:0">
  return
}

// -----

// old_type_bits = 0: zero is not a valid bit-width.
func.func @zero_old_bits(
    %src: !cute.layout<"(32,4):(1,32)">) {
  // expected-error@+2 {{expects old_type_bits to be positive, but got 0}}
  // expected-error@+1 {{'cute.recast_layout' op failed to infer returned types}}
  %r = cute.recast_layout<8, 0>(%src)
         : !cute.layout<"(32,4):(1,32)"> -> !cute.layout<"1:0">
  return
}

// -----

// new_type_bits < 0: negative bit-widths are rejected.
func.func @neg_new_bits(
    %src: !cute.layout<"(32,4):(1,32)">) {
  // expected-error@+2 {{expects new_type_bits to be positive, but got -8}}
  // expected-error@+1 {{'cute.recast_layout' op failed to infer returned types}}
  %r = cute.recast_layout<-8, 8>(%src)
         : !cute.layout<"(32,4):(1,32)"> -> !cute.layout<"1:0">
  return
}

// -----

// old_type_bits < 0: negative bit-widths are rejected.
func.func @neg_old_bits(
    %src: !cute.layout<"(32,4):(1,32)">) {
  // expected-error@+2 {{expects old_type_bits to be positive, but got -4}}
  // expected-error@+1 {{'cute.recast_layout' op failed to infer returned types}}
  %r = cute.recast_layout<8, -4>(%src)
         : !cute.layout<"(32,4):(1,32)"> -> !cute.layout<"1:0">
  return
}

// -----

// Scaled-basis strides are not supported by recast.
func.func @scaled_basis_stride(
    %src: !cute.layout<"(2,3):(1@0,1@1)">) {
  // expected-error@+2 {{expects integer or dynamic strides, but '!cute.layout<"(2,3):(1@0,1@1)">' has scaled-basis strides}}
  // expected-error@+1 {{'cute.recast_layout' op failed to infer returned types}}
  %r = cute.recast_layout<32, 8>(%src)
         : !cute.layout<"(2,3):(1@0,1@1)"> -> !cute.layout<"1:0">
  return
}

// -----

// Scaled-basis on a composed input.
func.func @composed_scaled_basis_stride(
    %src: !cute.composed_layout<"(2,3):(1,3) o (0,0) o (2,3):(1@0,1@1)">) {
  // expected-error@+2 {{expects integer or dynamic strides, but '!cute.composed_layout<"(2,3):(1,3) o (0,0) o (2,3):(1@0,1@1)">' has scaled-basis strides}}
  // expected-error@+1 {{'cute.recast_layout' op failed to infer returned types}}
  %r = cute.recast_layout<32, 8>(%src)
         : !cute.composed_layout<"(2,3):(1,3) o (0,0) o (2,3):(1@0,1@1)">
        -> !cute.composed_layout<"1:0 o 0 o 1:0">
  return
}

// -----

// Type-kind mismatch.
func.func @kind_mismatch_layout_to_composed(
    %src: !cute.layout<"(8,4):(1,8)">) {
  // expected-error@+2 {{op inferred type(s) '!cute.layout<"(2,4):(1,2)">' are incompatible with return type(s) of operation '!cute.composed_layout<"1:0 o 0 o 1:0">'}}
  // expected-error@+1 {{'cute.recast_layout' op failed to infer returned types}}
  %r = cute.recast_layout<32, 8>(%src)
         : !cute.layout<"(8,4):(1,8)"> -> !cute.composed_layout<"1:0 o 0 o 1:0">
  return
}
