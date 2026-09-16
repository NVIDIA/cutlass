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

// Negative tests for !cute.composed_layout type parser.

// -----
// Missing string argument.
// expected-error@+1 {{expected string}}
func.func @missing_string(%a: !cute.composed_layout<32>) {
  return
}

// -----
// Completely unparseable string.
// expected-error@+1 {{failed to parse composed_layout from "not_valid"}}
func.func @bad_string(%a: !cute.composed_layout<"not_valid">) {
  return
}

// -----
// Empty string.
// expected-error@+1 {{failed to parse composed_layout from ""}}
func.func @empty_string(%a: !cute.composed_layout<"">) {
  return
}

// -----
// Swizzle A with scaled-basis strides in outer B.
// expected-error@+1 {{swizzle layout expects scalar `offset` and `outer` without scaled basis, but got 0 and (4,2):(1@0,1@1)}}
func.func @swizzle_a_basis_b(%a: !cute.composed_layout<"S<3,4,3> o 0 o (4,2):(1@0,1@1)">) {
  return
}

// -----
// Zero in outer B's shape.
// expected-error@+1 {{expects positive shape mode, but got "(4,5):(1,4) o 2 o (0,3):(1,2)"}}
func.func @zero_outer_shape(%a: !cute.composed_layout<"(4,5):(1,4) o 2 o (0,3):(1,2)">) {
  return
}

// -----
// Zero in affine A's shape.
// expected-error@+1 {{expects positive shape mode, but got "(0,5):(1,4) o 2 o (2,3):(1,2)"}}
func.func @zero_inner_shape(%a: !cute.composed_layout<"(0,5):(1,4) o 2 o (2,3):(1,2)">) {
  return
}

// -----
// Affine A whose shape profile can't consume `layout_eval(0, outer) + offset`.
// expected-error@+1 {{expects arith sum of `layout_eval(0, outer)` and `offset` to be scalar or weakly congruent to inner shape, but got sum ((0,0)) and inner shape (4,5)}}
func.func @affine_inner_profile_mismatch(%a: !cute.composed_layout<"(4,5):(1,4) o 0 o ((?,?)):((?@0@0,?@1@0))">) {
  return
}

// -----
// Scalar offset cannot be added to a rank-2 `layout_eval(0, outer)` tuple.
// expected-error@+1 {{expects offset and `layout_eval(0, outer)` to be addable, but got 2 and (0,0)}}
func.func @offset_not_addable(%a: !cute.composed_layout<"(6,2):(1,3) o 2 o (2,3):(1@1,2@0)">) {
  return
}

// -----
// Mixed nonzero-int + scaled-basis stride in the outer layout.
// expected-error@+1 {{expects strides to be either all-integer or all-scaled-basis (zero integers allowed when mixed), but got "(1,1@0)"}}
func.func @outer_mixed_int_scaled_basis(%a: !cute.composed_layout<"(4,5):(1,4) o 0 o (2,3):(1,1@0)">) {
  return
}

// -----
// Mixed nonzero-int + scaled-basis stride in the affine-inner layout.
// expected-error@+1 {{expects strides to be either all-integer or all-scaled-basis (zero integers allowed when mixed), but got "(1,1@0)"}}
func.func @inner_mixed_int_scaled_basis(%a: !cute.composed_layout<"(4,5):(1,1@0) o 0 o (2,3):(1,2)">) {
  return
}

// -----
// Ratio-valued scaled-basis stride in the outer layout.
// expected-error@+1 {{expects scaled-basis strides to have integer values, not ratios, but got "(1/2@0,1@1)"}}
func.func @outer_ratio_scaled_basis(%a: !cute.composed_layout<"(4,5):(1,4) o 0 o (2,3):(1/2@0,1@1)">) {
  return
}

// -----
// Ratio-valued scaled-basis stride in the affine-inner layout.
// expected-error@+1 {{expects scaled-basis strides to have integer values, not ratios, but got "(1/2@0,1@1)"}}
func.func @inner_ratio_scaled_basis(%a: !cute.composed_layout<"(4,5):(1/2@0,1@1) o 0 o (2,3):(1,2)">) {
  return
}

// -----
// Mixed-depth basis stride in the outer layout.
// expected-error@+1 {{expects scaled-basis paths to agree on mode-index depth (no path may terminate at a node that another path continues through), but got "(1@1@0,1@0)"}}
func.func @outer_mixed_depth_basis(%a: !cute.composed_layout<"(4,5):(1,4) o 0 o (2,3):(1@1@0,1@0)">) {
  return
}

// -----
// Mixed-depth basis stride in the affine-inner layout.
// expected-error@+1 {{expects scaled-basis paths to agree on mode-index depth (no path may terminate at a node that another path continues through), but got "(1@1@0,1@0)"}}
func.func @inner_mixed_depth_basis(%a: !cute.composed_layout<"(4,5):(1@1@0,1@0) o 0 o (2,3):(1,2)">) {
  return
}

