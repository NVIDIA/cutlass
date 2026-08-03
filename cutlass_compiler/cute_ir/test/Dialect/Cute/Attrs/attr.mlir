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

// Tests parse error paths for cute attribute kinds. Each `#cute.X<...>`
// expects a single string operand inside angle brackets; the parser
// can fail on:
//   1. operand isn't a string
//   2. the string content is malformed for the attribute kind
//   3. missing closing `>`

// -----

// Non-string operand inside the cute attribute.
// expected-error@+1 {{expected string}}
func.func @int_tuple_bad_string() attributes {bad = #cute.int_tuple<32>} {
  return
}

// -----

// Empty string content.
// expected-error@+1 {{failed to parse int_tuple from ""}}
func.func @int_tuple_empty() attributes {bad = #cute.int_tuple<"">} {
  return
}

// -----

// Malformed string content.
// expected-error@+1 {{failed to parse shape from "(1,"}}
func.func @shape_bad_string() attributes {bad = #cute.shape<"(1,">} {
  return
}

// -----

// Stride: non-string operand.
// expected-error@+1 {{expected string}}
func.func @stride_bad_string() attributes {bad = #cute.stride<42>} {
  return
}

// -----

// Coord: malformed content.
// expected-error@+1 {{failed to parse coord from "bogus"}}
func.func @coord_bad_string() attributes {bad = #cute.coord<"bogus">} {
  return
}

// -----

// Layout: malformed (unclosed paren).
// expected-error@+1 {{failed to parse layout from "(2,3:(1,2)"}}
func.func @layout_bad_string() attributes {bad = #cute.layout<"(2,3:(1,2)">} {
  return
}

// -----

// Tile: malformed (missing closing bracket).
// expected-error@+1 {{failed to parse tile from "[(2,3):(1,2)"}}
func.func @tile_bad_string() attributes {bad = #cute.tile<"[(2,3):(1,2)">} {
  return
}

// -----

// ComposedLayout: empty.
// expected-error@+1 {{failed to parse composed_layout from ""}}
func.func @composed_layout_empty() attributes {bad = #cute.composed_layout<"">} {
  return
}

// -----

// Swizzle: missing parameters.
// expected-error@+1 {{failed to parse swizzle from "S<1>"}}
func.func @swizzle_bad_string() attributes {bad = #cute.swizzle<"S<1>">} {
  return
}
