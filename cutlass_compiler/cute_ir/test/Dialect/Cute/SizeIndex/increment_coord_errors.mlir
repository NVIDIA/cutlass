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

// Tests error cases for cute.increment_coord. Each failure mode in
// `inferReturnTypes` (`cg::is_congruent`, `cg::has_underscore`,
// `cg::is_valid`) gets its own pinned diagnostic.

// -----

// Operand kind not Cute_CoordType.
func.func @bad_operand_layout(%l: !cute.layout<"(4,8):(1,4)">, %s: !cute.shape<"(4,8)">) {
  // expected-error@+1 {{'cute.increment_coord' op operand #0 must be}}
  %r = cute.increment_coord(%l, %s)
         : (!cute.layout<"(4,8):(1,4)">, !cute.shape<"(4,8)">) -> !cute.coord<"(?,?)">
  return
}

// -----

// Static non-leaf coord whose rank (3) exceeds shape rank (2):
func.func @increment_coord_rank_mismatch_static(
    %c: !cute.coord<"(1,2,3)">, %s: !cute.shape<"(4,8)">) {
  // expected-error@+2 {{expects coord to be congruent with shape, but got '!cute.coord<"(1,2,3)">' and '!cute.shape<"(4,8)">'}}
  // expected-error@+1 {{'cute.increment_coord' op failed to infer returned types}}
  %r = cute.increment_coord(%c, %s)
       : (!cute.coord<"(1,2,3)">, !cute.shape<"(4,8)">) -> !cute.coord<"?">
  return
}

// -----

// Dynamic non-leaf coord whose rank (3) exceeds shape rank (2).
func.func @increment_coord_rank_mismatch_dynamic(
    %c: !cute.coord<"(?,?,?)">, %s: !cute.shape<"(4,8)">) {
  // expected-error@+2 {{expects coord to be congruent with shape, but got '!cute.coord<"(?,?,?)">' and '!cute.shape<"(4,8)">'}}
  // expected-error@+1 {{'cute.increment_coord' op failed to infer returned types}}
  %r = cute.increment_coord(%c, %s)
       : (!cute.coord<"(?,?,?)">, !cute.shape<"(4,8)">) -> !cute.coord<"?">
  return
}

// -----

// Structural mismatch: coord is hierarchical, shape is flat (same rank but incompatible nesting).
func.func @increment_coord_structure_mismatch(
    %c: !cute.coord<"((0,0),0,0)">, %s: !cute.shape<"(3,3,3)">) {
  // expected-error@+2 {{expects coord to be congruent with shape, but got '!cute.coord<"((0,0),0,0)">' and '!cute.shape<"(3,3,3)">'}}
  // expected-error@+1 {{'cute.increment_coord' op failed to infer returned types}}
  %r = cute.increment_coord(%c, %s)
       : (!cute.coord<"((0,0),0,0)">, !cute.shape<"(3,3,3)">) -> !cute.coord<"((0,0),0,0)">
  return
}

// -----

// Coord contains an underscore wildcard.
func.func @increment_coord_has_underscore(
    %c: !cute.coord<"(_,0,0)">, %s: !cute.shape<"(3,3,3)">) {
  // expected-error@+2 {{expects coord to be free of underscore wildcards, but got '!cute.coord<"(_,0,0)">'}}
  // expected-error@+1 {{'cute.increment_coord' op failed to infer returned types}}
  %r = cute.increment_coord(%c, %s)
       : (!cute.coord<"(_,0,0)">, !cute.shape<"(3,3,3)">) -> !cute.coord<"(?,0,0)">
  return
}
