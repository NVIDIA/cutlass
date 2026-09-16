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

// Tests error cases for cute.make_layout_like.

// -----

// Wrong operand type: !cute.shape is not a layout.
func.func @wrong_src_type(%src: !cute.shape<"(4,2)">) {
  // expected-error@+1 {{operand #0 must be !cute.layout or !cute.composed_layout, but got}}
  %r = cute.make_layout_like(%src) : !cute.shape<"(4,2)"> -> !cute.layout<"(4,2):(1,4)">
  return
}

// -----

// Basis-stride source: ordering by stride magnitude requires plain integers.
func.func @basis_stride_src(%src: !cute.layout<"(4,2):(1@0,1@1)">) {
  // expected-error@+2 {{expects plain integer strides in source layout, but got scaled-basis strides}}
  // expected-error@+1 {{'cute.make_layout_like' op failed to infer returned types}}
  %r = cute.make_layout_like(%src) : !cute.layout<"(4,2):(1@0,1@1)"> -> !cute.layout<"(4,2):(1,4)">
  return
}

// -----

// Composed layout with layout A: only Swizzle A is supported.
func.func @composed_layout_a_src(%src: !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">) {
  // expected-error@+2 {{expects source composed layout to have a Swizzle A component, but got a layout A}}
  // expected-error@+1 {{'cute.make_layout_like' op failed to infer returned types}}
  %r = cute.make_layout_like(%src)
         : !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)"> -> !cute.layout<"(2,3):(1,2)">
  return
}

