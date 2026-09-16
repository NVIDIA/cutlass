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

// Tests error cases for `cute.flatten`.

// -----

// Operand kind not accepted by the op (e.g. !cute.swizzle).
func.func @bad_operand_swizzle(%s: !cute.swizzle<"S<3,4,3>">) {
  // expected-error@+1 {{'cute.flatten' op operand #0 must be}}
  %r = cute.flatten(%s) : (!cute.swizzle<"S<3,4,3>">) -> !cute.swizzle<"S<3,4,3>">
  return
}

// -----

// Declared result type does not match the inferred flatten result: nested
// input should flatten to a depth-1 layout but the declared result preserves
// the nesting.
func.func @wrong_result_type(
    %src: !cute.layout<"(3,(4,5)):(8,(1,4))">) {
  // expected-error@+2 {{'cute.flatten' op inferred type(s) '!cute.layout<"(3,4,5):(8,1,4)">' are incompatible with return type(s) of operation '!cute.layout<"(3,(4,5)):(8,(1,4))">'}}
  // expected-error@+1 {{'cute.flatten' op failed to infer returned types}}
  %r = cute.flatten(%src)
         : (!cute.layout<"(3,(4,5)):(8,(1,4))">) -> !cute.layout<"(3,(4,5)):(8,(1,4))">
  return
}

// -----

// Same mismatch on a composed layout: flatten only touches B, but the
// declared composed result still nests B.
func.func @composed_wrong_result_type(
    %src: !cute.composed_layout<"(4,5):(1,4) o 2 o (3,(4,5)):(8,(1,4))">) {
  // expected-error@+2 {{'cute.flatten' op inferred type(s) '!cute.composed_layout<"(4,5):(1,4) o 2 o (3,4,5):(8,1,4)">' are incompatible with return type(s) of operation '!cute.composed_layout<"(4,5):(1,4) o 2 o (3,(4,5)):(8,(1,4))">'}}
  // expected-error@+1 {{'cute.flatten' op failed to infer returned types}}
  %r = cute.flatten(%src)
         : (!cute.composed_layout<"(4,5):(1,4) o 2 o (3,(4,5)):(8,(1,4))">)
        -> !cute.composed_layout<"(4,5):(1,4) o 2 o (3,(4,5)):(8,(1,4))">
  return
}
