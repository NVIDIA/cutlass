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

// Tests error cases for `cute.crd2idx`.

// -----

// Operand kind not in Cute_CoordType.
func.func @bad_coord_int_tuple(%c: !cute.int_tuple<"(1,2)">,
                               %s: !cute.shape<"(4,8)">) {
  // expected-error@+1 {{'cute.crd2idx' op operand #0 must be}}
  %r = cute.crd2idx(%c, %s)
         : (!cute.int_tuple<"(1,2)">, !cute.shape<"(4,8)">)
        -> !cute.int_tuple<"9">
  return
}

// -----

// Operand kind not in Cute_ShapeType.
func.func @bad_shape_int_tuple(%c: !cute.coord<"(1,2)">,
                               %s: !cute.int_tuple<"(4,8)">) {
  // expected-error@+1 {{'cute.crd2idx' op operand #1 must be}}
  %r = cute.crd2idx(%c, %s)
         : (!cute.coord<"(1,2)">, !cute.int_tuple<"(4,8)">)
        -> !cute.int_tuple<"9">
  return
}

// -----

// Coord rank does not match shape rank.
func.func @rank_mismatch(%c: !cute.coord<"(1,2,3)">,
                         %s: !cute.shape<"(4,8)">) {
  // expected-error@+2 {{expects coord and shape to be weakly congruent}}
  // expected-error@+1 {{'cute.crd2idx' op failed to infer returned types}}
  %r = cute.crd2idx(%c, %s)
         : (!cute.coord<"(1,2,3)">, !cute.shape<"(4,8)">)
        -> !cute.int_tuple<"?">
  return
}

// -----

// Declared result type does not match the inferred index.
func.func @wrong_result_type(%c: !cute.coord<"(1,2)">,
                             %s: !cute.shape<"(4,8)">) {
  // expected-error@+2 {{'cute.crd2idx' op inferred type(s) '!cute.int_tuple<"9">' are incompatible with return type(s) of operation '!cute.int_tuple<"7">'}}
  // expected-error@+1 {{'cute.crd2idx' op failed to infer returned types}}
  %r = cute.crd2idx(%c, %s)
         : (!cute.coord<"(1,2)">, !cute.shape<"(4,8)">)
        -> !cute.int_tuple<"7">
  return
}
