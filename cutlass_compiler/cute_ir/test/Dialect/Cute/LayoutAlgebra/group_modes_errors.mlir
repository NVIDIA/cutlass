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

// Tests error cases for cute.group_modes.

// -----

// Operand kind not in Cute_AnyLayoutType.
func.func @bad_operand_shape(%s: !cute.shape<"(4,8)">) {
  // expected-error@+1 {{'cute.group_modes' op operand #0 must be}}
  %r = cute.group_modes<0, 1>(%s) : (!cute.shape<"(4,8)">) -> !cute.shape<"(4,8)">
  return
}

// -----

// begin >= end: empty range is rejected.
func.func @begin_ge_end(
    %input: !cute.layout<"(4,5,6):(1,4,20)">) {
  // expected-error@+2 {{expects begin < end, but got begin=2, end=1}}
  // expected-error@+1 {{'cute.group_modes' op failed to infer returned types}}
  %r = cute.group_modes<2, 1>(%input)
         : (!cute.layout<"(4,5,6):(1,4,20)">) -> !cute.layout<"1:0">
  return
}

// -----

// begin == end: zero-length range is also rejected.
func.func @begin_eq_end(
    %input: !cute.layout<"(4,5,6):(1,4,20)">) {
  // expected-error@+2 {{expects begin < end, but got begin=2, end=2}}
  // expected-error@+1 {{'cute.group_modes' op failed to infer returned types}}
  %r = cute.group_modes<2, 2>(%input)
         : (!cute.layout<"(4,5,6):(1,4,20)">) -> !cute.layout<"1:0">
  return
}

// -----

// end > rank: out-of-bounds range is rejected.
func.func @end_gt_rank(
    %input: !cute.layout<"(4,5,6):(1,4,20)">) {
  // expected-error@+2 {{expects end <= rank(input)=3, but got end=4}}
  // expected-error@+1 {{'cute.group_modes' op failed to infer returned types}}
  %r = cute.group_modes<1, 4>(%input)
         : (!cute.layout<"(4,5,6):(1,4,20)">) -> !cute.layout<"1:0">
  return
}

// -----

// end > rank on composed layout: rank is layout_b rank.
func.func @composed_end_gt_rank(
    %input: !cute.composed_layout<"(4,5):(1,4) o 2 o (3,4,5):(1,3,12)">) {
  // expected-error@+2 {{expects end <= rank(input)=3, but got end=4}}
  // expected-error@+1 {{'cute.group_modes' op failed to infer returned types}}
  %r = cute.group_modes<0, 4>(%input)
         : (!cute.composed_layout<"(4,5):(1,4) o 2 o (3,4,5):(1,3,12)">)
        -> !cute.composed_layout<"(4,5):(1,4) o 2 o (3,4,5):(1,3,12)">
  return
}

// -----

// Dynamic shapes/strides do not affect rank out-of-bounds.
func.func @dyn_end_gt_rank(
    %input: !cute.layout<"(?,?,?):(?,?,?)">) {
  // expected-error@+2 {{expects end <= rank(input)=3, but got end=4}}
  // expected-error@+1 {{'cute.group_modes' op failed to infer returned types}}
  %r = cute.group_modes<1, 4>(%input)
         : (!cute.layout<"(?,?,?):(?,?,?)">) -> !cute.layout<"1:0">
  return
}

// -----

// begin >= end on a dynamic layout.
func.func @dyn_begin_ge_end(
    %input: !cute.layout<"(?,?,?):(?,?,?)">) {
  // expected-error@+2 {{expects begin < end, but got begin=2, end=1}}
  // expected-error@+1 {{'cute.group_modes' op failed to infer returned types}}
  %r = cute.group_modes<2, 1>(%input)
         : (!cute.layout<"(?,?,?):(?,?,?)">) -> !cute.layout<"1:0">
  return
}

// -----

// begin < 0.
func.func @neg_begin(
    %input: !cute.layout<"(4,5,6):(1,4,20)">) {
  // expected-error@+2 {{expects 0 <= begin, but got begin=-1}}
  // expected-error@+1 {{'cute.group_modes' op failed to infer returned types}}
  %r = cute.group_modes<-1, 2>(%input)
         : (!cute.layout<"(4,5,6):(1,4,20)">) -> !cute.layout<"1:0">
  return
}

// -----

// begin < 0 on a composed layout.
func.func @composed_neg_begin(
    %input: !cute.composed_layout<"(4,5):(1,4) o 2 o (3,4,5):(1,3,12)">) {
  // expected-error@+2 {{expects 0 <= begin, but got begin=-2}}
  // expected-error@+1 {{'cute.group_modes' op failed to infer returned types}}
  %r = cute.group_modes<-2, 2>(%input)
         : (!cute.composed_layout<"(4,5):(1,4) o 2 o (3,4,5):(1,3,12)">)
        -> !cute.composed_layout<"(4,5):(1,4) o 2 o (3,4,5):(1,3,12)">
  return
}

// -----

// Result-kind mismatch.
func.func @wrong_result_type(%input: !cute.layout<"(4,5,6):(1,4,20)">) {
  // expected-error@+2 {{'cute.group_modes' op inferred type(s) '!cute.layout<"((4,5),6):((1,4),20)">' are incompatible with return type(s) of operation '!cute.composed_layout<"(2,5):(1,4) o 2 o ((4,5),6):((1,4),20)">'}}
  // expected-error@+1 {{'cute.group_modes' op failed to infer returned types}}
  %r = cute.group_modes<0, 2>(%input)
         : (!cute.layout<"(4,5,6):(1,4,20)">)
        -> !cute.composed_layout<"(2,5):(1,4) o 2 o ((4,5),6):((1,4),20)">
  return
}

// -----

// Symmetric result-kind mismatch.
func.func @composed_wrong_result_type(
    %input: !cute.composed_layout<"(4,5):(1,4) o 2 o (4,5,6):(1,4,20)">) {
  // expected-error@+2 {{'cute.group_modes' op inferred type(s) '!cute.composed_layout<"(4,5):(1,4) o 2 o ((4,5),6):((1,4),20)">' are incompatible with return type(s) of operation '!cute.layout<"((4,5),6):((1,4),20)">'}}
  // expected-error@+1 {{'cute.group_modes' op failed to infer returned types}}
  %r = cute.group_modes<0, 2>(%input)
         : (!cute.composed_layout<"(4,5):(1,4) o 2 o (4,5,6):(1,4,20)">)
        -> !cute.layout<"((4,5),6):((1,4),20)">
  return
}
