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

// Tests that cute.static rejects dynamic result types.

// -----

// cute.static requires a fully static result type.
func.func @static_op_non_static_result() -> !cute.shape<"(?,64)"> {
  // expected-error@+1 {{'cute.static' op expects result to be static, but got}}
  %0 = cute.static : !cute.shape<"(?,64)">
  return %0 : !cute.shape<"(?,64)">
}

// -----

func.func @dynamic_layout() -> !cute.layout<"(2,?):(1,?)"> {
  // expected-error@+1 {{'cute.static' op expects result to be static, but got}}
  %0 = cute.static : !cute.layout<"(2,?):(1,?)">
  return %0 : !cute.layout<"(2,?):(1,?)">
}

// -----

func.func @dynamic_stride() -> !cute.stride<"?"> {
  // expected-error@+1 {{'cute.static' op expects result to be static, but got}}
  %0 = cute.static : !cute.stride<"?">
  return %0 : !cute.stride<"?">
}

// -----

func.func @dynamic_int_tuple() -> !cute.int_tuple<"(1,?)"> {
  // expected-error@+1 {{'cute.static' op expects result to be static, but got}}
  %0 = cute.static : !cute.int_tuple<"(1,?)">
  return %0 : !cute.int_tuple<"(1,?)">
}

// -----

func.func @dynamic_coord() -> !cute.coord<"(?,1)"> {
  // expected-error@+1 {{'cute.static' op expects result to be static, but got}}
  %0 = cute.static : !cute.coord<"(?,1)">
  return %0 : !cute.coord<"(?,1)">
}

// -----

func.func @dynamic_tile() -> !cute.tile<"[(?,3):(1,?)]"> {
  // expected-error@+1 {{'cute.static' op expects result to be static, but got}}
  %0 = cute.static : !cute.tile<"[(?,3):(1,?)]">
  return %0 : !cute.tile<"[(?,3):(1,?)]">
}

// -----

func.func @dynamic_composed_layout()
    -> !cute.composed_layout<"(4,5):(1,4) o ? o (2,3):(1,2)"> {
  // expected-error@+1 {{'cute.static' op expects result to be static, but got}}
  %0 = cute.static : !cute.composed_layout<"(4,5):(1,4) o ? o (2,3):(1,2)">
  return %0 : !cute.composed_layout<"(4,5):(1,4) o ? o (2,3):(1,2)">
}
