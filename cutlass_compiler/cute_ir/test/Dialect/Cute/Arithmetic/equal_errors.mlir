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

// Tests error cases for cute.equal.

// -----

// Operand kind not in {IntTuple, Shape, Coord, Stride, Layout}.
func.func @bad_operand_composed_layout(
    %a: !cute.composed_layout<"(4,5):(1,4) o 0 o (2,3):(1,2)">,
    %b: !cute.composed_layout<"(4,5):(1,4) o 0 o (2,3):(1,2)">) {
  // expected-error@+1 {{'cute.equal' op operand #0 must be}}
  %r = cute.equal(%a, %b)
         : (!cute.composed_layout<"(4,5):(1,4) o 0 o (2,3):(1,2)">,
            !cute.composed_layout<"(4,5):(1,4) o 0 o (2,3):(1,2)">) -> i1
  return
}

// -----

// Kind mismatch: int_tuple vs shape.
func.func @kind_mismatch_int_tuple_shape(%a: !cute.int_tuple<"(3,4)">, %b: !cute.shape<"(3,4)">) {
  // expected-error@+1 {{'cute.equal' op expects lhs and rhs to be the same kind, but got '!cute.int_tuple<"(3,4)">' and '!cute.shape<"(3,4)">'}}
  %r = cute.equal(%a, %b) : (!cute.int_tuple<"(3,4)">, !cute.shape<"(3,4)">) -> i1
  return
}

// -----

// Kind mismatch: layout vs shape.
func.func @kind_mismatch_layout_shape(%a: !cute.layout<"(4,8):(1,4)">, %b: !cute.shape<"(4,8)">) {
  // expected-error@+1 {{'cute.equal' op expects lhs and rhs to be the same kind, but got '!cute.layout<"(4,8):(1,4)">' and '!cute.shape<"(4,8)">'}}
  %r = cute.equal(%a, %b) : (!cute.layout<"(4,8):(1,4)">, !cute.shape<"(4,8)">) -> i1
  return
}

// -----

// Unsupported operand kind: `!cute.tile`.
func.func @unsupported_kind_tile(%a: !cute.tile<"(2,2)">, %b: !cute.tile<"(2,2)">) {
  // expected-error@+1 {{'cute.equal' op operand #0 must be !cute.int_tuple, !cute.shape, !cute.coord, !cute.stride, or !cute.layout, but got '!cute.tile<"(2,2):(1,2)">'}}
  %r = cute.equal(%a, %b) : (!cute.tile<"(2,2)">, !cute.tile<"(2,2)">) -> i1
  return
}

// -----

// Unsupported operand kind: `!cute.composed_layout` — rejected at the ODS level.
func.func @unsupported_kind_composed_layout(%a: !cute.composed_layout<"(4,5):(1,4) o 0 o (2,3):(1,2)">,
                                             %b: !cute.composed_layout<"(4,5):(1,4) o 0 o (2,3):(1,2)">) {
  // expected-error@+1 {{'cute.equal' op operand #0 must be !cute.int_tuple, !cute.shape, !cute.coord, !cute.stride, or !cute.layout, but got '!cute.composed_layout<"(4,5):(1,4) o 0 o (2,3):(1,2)">'}}
  %r = cute.equal(%a, %b) : (!cute.composed_layout<"(4,5):(1,4) o 0 o (2,3):(1,2)">,
                              !cute.composed_layout<"(4,5):(1,4) o 0 o (2,3):(1,2)">) -> i1
  return
}

// -----

// Unsupported operand kind: `!cute.swizzle` — rejected at the ODS level.
func.func @unsupported_kind_swizzle(%a: !cute.swizzle<"S<3,5,4>">, %b: !cute.swizzle<"S<3,5,4>">) {
  // expected-error@+1 {{'cute.equal' op operand #0 must be !cute.int_tuple, !cute.shape, !cute.coord, !cute.stride, or !cute.layout, but got '!cute.swizzle<"S<3,5,4>">'}}
  %r = cute.equal(%a, %b) : (!cute.swizzle<"S<3,5,4>">, !cute.swizzle<"S<3,5,4>">) -> i1
  return
}
