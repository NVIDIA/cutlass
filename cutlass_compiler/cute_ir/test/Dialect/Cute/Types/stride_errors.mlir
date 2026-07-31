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

// Negative tests for !cute.stride type parser.

// -----

// Missing string argument.
// expected-error@+1 {{expected string}}
func.func @missing_string(%a: !cute.stride<32>) {
  return
}

// -----

// Completely unparseable string.
// expected-error@+1 {{failed to parse stride from "not_valid"}}
func.func @bad_string(%a: !cute.stride<"not_valid">) {
  return
}

// -----

// Empty string.
// expected-error@+1 {{failed to parse stride from ""}}
func.func @empty_string(%a: !cute.stride<"">) {
  return
}

// -----

// Multiple integers without parentheses.
// expected-error@+1 {{failed to parse stride from "1,2"}}
func.func @bare_two_ints(%a: !cute.stride<"1,2">) {
  return
}

// -----

// Unclosed left parenthesis.
// expected-error@+1 {{failed to parse stride from "(16,32"}}
func.func @unclosed_paren(%a: !cute.stride<"(16,32">) {
  return
}

// -----

// Truncated scaled basis — '@' with no mode number.
// expected-error@+1 {{failed to parse stride from "?@"}}
func.func @truncated_scaled_basis(%a: !cute.stride<"?@">) {
  return
}

// -----

// Mixed nonzero-int + scaled-basis stride.
// expected-error@+1 {{expects strides to be either all-integer or all-scaled-basis (zero integers allowed when mixed), but got "(1,1@0)"}}
func.func @mixed_int_scaled_basis_static(%a: !cute.stride<"(1,1@0)">) {
  return
}

// -----

// Dynamic integer next to a dynamic scaled-basis.
// expected-error@+1 {{expects strides to be either all-integer or all-scaled-basis (zero integers allowed when mixed), but got "(?,?@0)"}}
func.func @mixed_dyn_int_scaled_basis(%a: !cute.stride<"(?,?@0)">) {
  return
}

// -----

// Nested form — mismatch on the inner mode.
// expected-error@+1 {{expects strides to be either all-integer or all-scaled-basis (zero integers allowed when mixed), but got "((1,1@0),2)"}}
func.func @nested_mixed_int_scaled_basis(%a: !cute.stride<"((1,1@0),2)">) {
  return
}

// -----

// Zero-int + scaled-basis is allowed, but a nonzero-int paired with the
// scaled-basis triggers the diagnostic.
// expected-error@+1 {{expects strides to be either all-integer or all-scaled-basis (zero integers allowed when mixed), but got "(0,1@0,2)"}}
func.func @zero_int_then_nonzero_with_basis(%a: !cute.stride<"(0,1@0,2)">) {
  return
}

// -----

// Ratio-valued scaled basis.
// expected-error@+1 {{expects scaled-basis strides to have integer values, not ratios, but got "(1/2@0,1@1)"}}
func.func @scaled_basis_ratio_value(%a: !cute.stride<"(1/2@0,1@1)">) {
  return
}

// -----

// Scalar scaled-basis with a ratio value.
// expected-error@+1 {{expects scaled-basis strides to have integer values, not ratios, but got "1/2@0"}}
func.func @scaled_basis_ratio_value_scalar(%a: !cute.stride<"1/2@0">) {
  return
}

// -----

// Mixed-depth basis stride tuple.
// expected-error@+1 {{expects scaled-basis paths to agree on mode-index depth (no path may terminate at a node that another path continues through), but got "(1@1@0,1@0)"}}
func.func @mixed_depth_basis_simple(%a: !cute.stride<"(1@1@0,1@0)">) {
  return
}

// -----

// Same conflict, opposite order.
// expected-error@+1 {{expects scaled-basis paths to agree on mode-index depth (no path may terminate at a node that another path continues through), but got "(1@0,1@1@0)"}}
func.func @mixed_depth_basis_reversed(%a: !cute.stride<"(1@0,1@1@0)">) {
  return
}

// -----

// Dynamic-valued counterpart.
// expected-error@+1 {{expects scaled-basis paths to agree on mode-index depth (no path may terminate at a node that another path continues through), but got "(?@1@0,?@0)"}}
func.func @mixed_depth_basis_dynamic(%a: !cute.stride<"(?@1@0,?@0)">) {
  return
}

// -----

// Three-deep conflict.
// expected-error@+1 {{expects scaled-basis paths to agree on mode-index depth (no path may terminate at a node that another path continues through), but got "((1@0@0,1@0@1),1@1)"}}
func.func @mixed_depth_basis_three_way(%a: !cute.stride<"((1@0@0,1@0@1),1@1)">) {
  return
}
