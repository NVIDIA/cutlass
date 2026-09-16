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

// RUN: cute-opt -verify-diagnostics --split-input-file %s

// Tests error cases for `cute.blocked_product`.

// -----

// Operand kind not in Cute_AnyLayoutType.
func.func @bad_operand_shape(%s: !cute.shape<"(4,8)">, %b: !cute.layout<"(2,4):(1,2)">) {
  // expected-error@+1 {{'cute.blocked_product' op operand #0 must be}}
  %r = cute.blocked_product(%s, %b)
         : (!cute.shape<"(4,8)">, !cute.layout<"(2,4):(1,2)">) -> !cute.layout<"1:0">
  return
}

// -----

// Dyn-shape × static-stride.
func.func @dyn_shape_static_stride(
    %a: !cute.layout<"(?,8):(1,4)">,
    %b: !cute.layout<"(2,4):(1,2)">) {
  // expected-error @below {{expects lhs to be static, but got '!cute.layout<"(?,8):(1,4)">'}}
  // expected-error @below {{op failed to infer returned types}}
  %r = cute.blocked_product(%a, %b)
         : (!cute.layout<"(?,8):(1,4)">, !cute.layout<"(2,4):(1,2)">)
        -> !cute.layout<"((?,8),((?,?),(?,?))):((1,4),((?,?),(?,?)))">
  return
}

// -----

// Rank-1 dyn-stride.
func.func @rank1_dyn_stride(
    %a: !cute.layout<"?:?">,
    %b: !cute.layout<"(2,5):(1,2)">) {
  // expected-error @below {{expects lhs to be static, but got '!cute.layout<"?:?">'}}
  // expected-error @below {{op failed to infer returned types}}
  %r = cute.blocked_product(%a, %b)
         : (!cute.layout<"?:?">, !cute.layout<"(2,5):(1,2)">)
        -> !cute.layout<"(?,((?,?),(?,?))):(?,((1,?),(2,?)))">
  return
}

// -----

// Rank > 1 dyn-stride.
func.func @rank2_dyn_stride(
    %a: !cute.layout<"(?,?):(?,?)">,
    %b: !cute.layout<"(2,5):(1,2)">) {
  // expected-error @below {{expects lhs to be static, but got '!cute.layout<"(?,?):(?,?)">'}}
  // expected-error @below {{op failed to infer returned types}}
  %r = cute.blocked_product(%a, %b)
         : (!cute.layout<"(?,?):(?,?)">, !cute.layout<"(2,5):(1,2)">)
        -> !cute.layout<"((?,?),(2,5)):((?,?),(1,2))">
  return
}

// -----

// Composed input — the static-input check applies to the B component
// (the layout being complemented).
func.func @composed_dyn_b(
    %a: !cute.composed_layout<"S<3,4,3> o 0 o (?,?):(?,?)">,
    %b: !cute.layout<"(2,5):(1,2)">) {
  // expected-error @below {{expects lhs to be static, but got '!cute.composed_layout<"S<3,4,3> o 0 o (?,?):(?,?)">'}}
  // expected-error @below {{op failed to infer returned types}}
  %r = cute.blocked_product(%a, %b)
         : (!cute.composed_layout<"S<3,4,3> o 0 o (?,?):(?,?)">,
            !cute.layout<"(2,5):(1,2)">)
        -> !cute.composed_layout<"S<3,4,3> o 0 o ((?,?),(2,5)):((?,?),(1,2))">
  return
}

// -----

// Scaled-basis tiler stride.
func.func @scaled_basis_tiler_stride(
    %a: !cute.layout<"(4,3):(1,4)">,
    %b: !cute.layout<"(2,5):(1@0,1@1)">) {
  // expected-error @below {{expects rhs stride to be integer-only (scaled-basis strides like `N@M` are not supported), but got '!cute.layout<"(2,5):(1@0,1@1)">'}}
  // expected-error @below {{op failed to infer returned types}}
  %r = cute.blocked_product(%a, %b)
         : (!cute.layout<"(4,3):(1,4)">, !cute.layout<"(2,5):(1@0,1@1)">)
        -> !cute.layout<"1:1">
  return
}

// -----

// Scaled-basis lhs + dynamic rhs.
func.func @scaled_basis_lhs_dynamic_rhs(
    %a: !cute.layout<"(4,3):(1@0,1@1)">,
    %b: !cute.layout<"(?,?):(?,?)">) {
  // expected-error @below {{expects rhs to be static when lhs has scaled-basis strides (`N@M`), but got rhs '!cute.layout<"(?,?):(?,?)">'}}
  // expected-error @below {{op failed to infer returned types}}
  %r = cute.blocked_product(%a, %b)
         : (!cute.layout<"(4,3):(1@0,1@1)">, !cute.layout<"(?,?):(?,?)">)
        -> !cute.layout<"1:1">
  return
}
