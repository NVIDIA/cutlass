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

// Tests error cases for cute.get_leaves.

// -----

// Operand is not one of the allowed tuple-like types.
func.func @bad_operand_composed_layout(
    %cl: !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">) {
  // expected-error@+1 {{expects $input to be !cute.shape, !cute.stride, !cute.coord, !cute.int_tuple, or !cute.tile, but got '!cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">'}}
  %r = cute.get_leaves(%cl)
       : !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">
  return
}

// -----

// Same operand-type rejection for a !cute.layout input.
func.func @bad_operand_layout(%l: !cute.layout<"(4,8):(1,4)">) {
  // expected-error@+1 {{expects $input to be !cute.shape, !cute.stride, !cute.coord, !cute.int_tuple, or !cute.tile, but got '!cute.layout<"(4,8):(1,4)">'}}
  %r = cute.get_leaves(%l) : !cute.layout<"(4,8):(1,4)">
  return
}

// -----

// Declared result count is less than the input's leaf count.
func.func @result_count_too_few(%s: !cute.shape<"(4,(2,3))">) {
  // expected-error@+2 {{'cute.get_leaves' op inferred type(s) '!cute.shape<"4">', '!cute.shape<"2">', '!cute.shape<"3">' are incompatible with return type(s) of operation '!cute.shape<"4">', '!cute.shape<"2">'}}
  // expected-error@+1 {{'cute.get_leaves' op failed to infer returned types}}
  %r:2 = "cute.get_leaves"(%s)
           : (!cute.shape<"(4,(2,3))">) -> (!cute.shape<"4">, !cute.shape<"2">)
  return
}

// -----

// Declared result kind does not match the input kind — input is
// !cute.shape but results are declared as !cute.stride.
func.func @result_kind_mismatch(%s: !cute.shape<"(4,2)">) {
  // expected-error@+2 {{'cute.get_leaves' op inferred type(s) '!cute.shape<"4">', '!cute.shape<"2">' are incompatible with return type(s) of operation '!cute.stride<"4">', '!cute.stride<"2">'}}
  // expected-error@+1 {{'cute.get_leaves' op failed to infer returned types}}
  %r:2 = "cute.get_leaves"(%s)
           : (!cute.shape<"(4,2)">) -> (!cute.stride<"4">, !cute.stride<"2">)
  return
}
