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

// Tests error cases for cute.get_shape.

// -----

// Operand kind not in the allowed layout/tile set — rejected by the
// ODS-level type constraint. Shape is a cute type but not a layout or tile.
func.func @bad_operand_shape(%s: !cute.shape<"(4,8)">) {
  // expected-error@+1 {{'cute.get_shape' op operand #0 must be}}
  %r = cute.get_shape(%s) : !cute.shape<"(4,8)"> -> !cute.shape<"(4,8)">
  return
}

// -----

// A tile with an underscore slot is rejected, shape is unknown for "_" slots.
func.func @tile_underscore_with_dynamic_after(%t: !cute.tile<"[(?,3):(1,?);_]">) {
  // expected-error@+2 {{expects a tile operand with no underscore slots, but got '!cute.tile<"[(?,3):(1,?);_]">'}}
  // expected-error@+1 {{'cute.get_shape' op failed to infer returned types}}
  %r = cute.get_shape(%t)
         : !cute.tile<"[(?,3):(1,?);_]"> -> !cute.shape<"((?,3),x)">
  return
}

// -----

// Same rejection regardless of slot order.
func.func @tile_underscore_with_dynamic_before(%t: !cute.tile<"[_;(?,2):(1,?)]">) {
  // expected-error@+2 {{expects a tile operand with no underscore slots, but got '!cute.tile<"[_;(?,2):(1,?)]">'}}
  // expected-error@+1 {{'cute.get_shape' op failed to infer returned types}}
  %r = cute.get_shape(%t)
         : !cute.tile<"[_;(?,2):(1,?)]"> -> !cute.shape<"(x,(?,2))">
  return
}

// -----

// Tile with underscore alongside an all-static slot — also rejected.
func.func @tile_underscore_with_static(%t: !cute.tile<"[(4,8):(1,4);_]">) {
  // expected-error@+2 {{expects a tile operand with no underscore slots, but got '!cute.tile<"[(4,8):(1,4);_]">'}}
  // expected-error@+1 {{'cute.get_shape' op failed to infer returned types}}
  %r = cute.get_shape(%t)
         : !cute.tile<"[(4,8):(1,4);_]"> -> !cute.shape<"((4,8),x)">
  return
}

