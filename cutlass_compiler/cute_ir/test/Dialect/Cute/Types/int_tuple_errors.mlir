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

// Negative tests for !cute.int_tuple type parser.

// -----

// Missing string argument.
// expected-error@+1 {{expected string}}
func.func @missing_string(%a: !cute.int_tuple<32>) {
  return
}

// -----

// Completely unparseable string.
// expected-error@+1 {{failed to parse int_tuple from "not_valid"}}
func.func @bad_string(%a: !cute.int_tuple<"not_valid">) {
  return
}

// -----

// Multiple integers without parentheses.
// expected-error@+1 {{failed to parse int_tuple from "1,2"}}
func.func @bare_two_ints(%a: !cute.int_tuple<"1,2">) {
  return
}

// -----

// Three integers without parentheses.
// expected-error@+1 {{failed to parse int_tuple from "1,2,3"}}
func.func @bare_three_ints(%a: !cute.int_tuple<"1,2,3">) {
  return
}

// -----

// Empty string.
// expected-error@+1 {{failed to parse int_tuple from ""}}
func.func @empty_string(%a: !cute.int_tuple<"">) {
  return
}

// -----

// Unclosed left parenthesis.
// expected-error@+1 {{failed to parse int_tuple from "(1,2"}}
func.func @unclosed_paren(%a: !cute.int_tuple<"(1,2">) {
  return
}

// -----

// Extra closing parenthesis after a valid tuple.
// expected-error@+1 {{failed to parse int_tuple from "(1,2))"}}
func.func @extra_close_paren(%a: !cute.int_tuple<"(1,2))"> ) {
  return
}

// -----

// Unclosed nested tuple.
// expected-error@+1 {{failed to parse int_tuple from "(1,(2,3)"}}
func.func @unclosed_nested_paren(%a: !cute.int_tuple<"(1,(2,3)"> ) {
  return
}

// -----

// Double comma — missing element between separators.
// expected-error@+1 {{failed to parse int_tuple from "(1,,2)"}}
func.func @double_comma(%a: !cute.int_tuple<"(1,,2)">) {
  return
}

// -----

// Unrecognised annotation keyword.
// expected-error@+1 {{failed to parse int_tuple from "?{unknown}"}}
func.func @unknown_keyword(%a: !cute.int_tuple<"?{unknown}">) {
  return
}

// -----

// Underscore wildcard `_` is not a valid int_tuple leaf.
// expected-error@+1 {{failed to parse int_tuple from "_"}}
func.func @scalar_underscore(%a: !cute.int_tuple<"_">) {
  return
}

// -----

// Underscore nested inside an int_tuple.
// expected-error@+1 {{failed to parse int_tuple from "(1,_)"}}
func.func @nested_underscore(%a: !cute.int_tuple<"(1,_)">) {
  return
}
