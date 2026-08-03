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

// Negative tests for !cute.tile type parser.

// -----

// Missing string argument.
// expected-error@+1 {{expected string}}
func.func @missing_string(%a: !cute.tile<32>) {
  return
}

// -----

// Completely unparseable string.
// expected-error@+1 {{failed to parse tile from "not_valid"}}
func.func @bad_string(%a: !cute.tile<"not_valid">) {
  return
}

// -----

// Empty string.
// expected-error@+1 {{failed to parse tile from ""}}
func.func @empty_string(%a: !cute.tile<"">) {
  return
}

// -----

// Unclosed bracket.
// expected-error@+1 {{failed to parse tile from "[(2,3):(1,2)"}}
func.func @unclosed_bracket(%a: !cute.tile<"[(2,3):(1,2)">) {
  return
}

// -----

// Mixed-depth basis stride inside a tile's layout slot.
// expected-error@+1 {{expects scaled-basis paths to agree on mode-index depth (no path may terminate at a node that another path continues through), but got "(1@1@0,1@0)"}}
func.func @mixed_depth_basis_in_tile_slot(%a: !cute.tile<"[(2,3):(1@1@0,1@0)]">) {
  return
}

// -----

// Mixed nonzero-int + scaled-basis inside a tile's layout slot.
// expected-error@+1 {{expects strides to be either all-integer or all-scaled-basis (zero integers allowed when mixed), but got "(1,1@0)"}}
func.func @mixed_int_scaled_basis_in_tile_slot(%a: !cute.tile<"[(2,3):(1,1@0)]">) {
  return
}
