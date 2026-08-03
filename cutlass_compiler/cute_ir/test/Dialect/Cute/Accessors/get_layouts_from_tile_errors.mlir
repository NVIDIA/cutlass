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

// Tests error cases for cute.get_layouts_from_tile.

// -----

func.func @bad_operand_shape(%s: !cute.shape<"(4,8)">) {
  // expected-error@+1 {{'cute.get_layouts_from_tile' op operand #0 must be}}
  "cute.get_layouts_from_tile"(%s) : (!cute.shape<"(4,8)">) -> ()
  return
}

// -----

// All-underscore tile has no layout leaves
func.func @all_underscore_rejected(%t: !cute.tile<"[_;_]">) {
  // expected-error@+1 {{expects $tile to contain at least one layout slot, but got '!cute.tile<"[_;_]">'}}
  cute.get_layouts_from_tile(%t) : !cute.tile<"[_;_]">
  return
}

// -----

// Nested all-underscore tile — same rejection, deeper structure.
func.func @nested_all_underscore_rejected(%t: !cute.tile<"[[_;_];_]">) {
  // expected-error@+1 {{expects $tile to contain at least one layout slot, but got '!cute.tile<"[[_;_];_]">'}}
  cute.get_layouts_from_tile(%t) : !cute.tile<"[[_;_];_]">
  return
}
