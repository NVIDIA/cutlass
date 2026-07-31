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

// Tests error cases for cute.coalesce.

// -----

// Operand kind not in Cute_AnyLayoutType.
func.func @bad_operand_shape(%s: !cute.shape<"(4,8)">) {
  // expected-error@+1 {{'cute.coalesce' op operand #0 must be}}
  %r = cute.coalesce(%s) : (!cute.shape<"(4,8)">) -> !cute.shape<"(4,8)">
  return
}

// -----

// Profile rank exceeds layout rank.
func.func @profile_rank_exceeds_layout_rank(
    %input: !cute.layout<"(3,(4,5)):(8,(1,4))">,
    %prof: !cute.coord<"(1,1,1)">) {
  // expected-error@+2 {{expects target_profile rank (3) to not exceed the layout rank (2)}}
  // expected-error@+1 {{'cute.coalesce' op failed to infer returned types}}
  %r = cute.coalesce(%input, %prof)
         : (!cute.layout<"(3,(4,5)):(8,(1,4))">, !cute.coord<"(1,1,1)">)
        -> !cute.layout<"(3,(4,5)):(8,(1,4))">
  return
}

// -----

// Profile rank exceeds composed layout B rank.
func.func @profile_rank_exceeds_composed_b_rank(
    %input: !cute.composed_layout<"(4,5):(1,4) o 2 o (4,5):(1,4)">,
    %prof: !cute.coord<"(1,1,1)">) {
  // expected-error@+2 {{expects target_profile rank (3) to not exceed the layout rank (2)}}
  // expected-error@+1 {{'cute.coalesce' op failed to infer returned types}}
  %r = cute.coalesce(%input, %prof)
         : (!cute.composed_layout<"(4,5):(1,4) o 2 o (4,5):(1,4)">,
            !cute.coord<"(1,1,1)">)
        -> !cute.composed_layout<"(4,5):(1,4) o 2 o (4,5):(1,4)">
  return
}

// -----

// Nested target_profile depth exceeds the layout depth at an inner mode.
func.func @nested_profile_too_deep(
    %input: !cute.layout<"(4,(2,3)):(1,(4,8))">,
    %prof: !cute.coord<"((1,1),1)">) {
  // expected-error@+2 {{expects target_profile rank (2) to not exceed the layout rank (1) at mode path [0]}}
  // expected-error@+1 {{'cute.coalesce' op failed to infer returned types}}
  %r = cute.coalesce(%input, %prof)
         : (!cute.layout<"(4,(2,3)):(1,(4,8))">, !cute.coord<"((1,1),1)">)
        -> !cute.layout<"(4,(2,3)):(1,(4,8))">
  return
}
