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

// RUN: %cutlass-compiler-run-host %s | FileCheck %s
//

// CHECK: (4,3):(1,4)
// CHECK: (5,2):(1@0,1@1)
// CHECK: (6,2):(1,6)
// CHECK: (8,2):(1,8)
// CHECK: (2,(3,4)):(1@0,(1@0@1,1@1@1))

//===----------------------------------------------------------------------===//
// Per-op helpers — opaque-arg boundaries.
//===----------------------------------------------------------------------===//

func.func @h_make_layout_like(%a: i32) -> !cute.layout<"(?,3):(1,?)"> {
  %sh = cute.make_shape (%a) : (i32) -> !cute.shape<"(?,3)">
  %src_stride = cute.make_stride (%a) : (i32) -> !cute.stride<"(1,?)">
  %src = cute.make_layout (%sh, %src_stride) : (!cute.shape<"(?,3)">, !cute.stride<"(1,?)">) -> !cute.layout<"(?,3):(1,?)">
  %r = cute.make_layout_like(%src)
       : !cute.layout<"(?,3):(1,?)"> -> !cute.layout<"(?,3):(1,?)">
  return %r : !cute.layout<"(?,3):(1,?)">
}

func.func @h_make_identity_layout(%a: i32) -> !cute.layout<"(?,2):(1@0,1@1)"> {
  %sh = cute.make_shape (%a) : (i32) -> !cute.shape<"(?,2)">
  %r = cute.make_identity_layout(%sh)
       : !cute.shape<"(?,2)"> -> !cute.layout<"(?,2):(1@0,1@1)">
  return %r : !cute.layout<"(?,2):(1@0,1@1)">
}

func.func @h_make_ordered_layout(%a: i32) -> !cute.layout<"(?,2):(1,?)"> {
  %sh = cute.make_shape (%a) : (i32) -> !cute.shape<"(?,2)">
  %ord = cute.static : !cute.int_tuple<"(0,1)">
  %r = cute.make_ordered_layout(%sh, %ord)
       : (!cute.shape<"(?,2)">, !cute.int_tuple<"(0,1)">) -> !cute.layout<"(?,2):(1,?)">
  return %r : !cute.layout<"(?,2):(1,?)">
}

// Composed-source helpers — take raw i32 leaves, build a dyn outer +
// composed_layout, run the op.

func.func @h_make_layout_like_composed(%a: i32, %b: i32)
    -> !cute.layout<"(?,2):(1,?)"> {
  %sh = cute.make_shape (%a) : (i32) -> !cute.shape<"(?,2)">
  %st = cute.make_stride (%b) : (i32) -> !cute.stride<"(2,?)">
  %outer = cute.make_layout (%sh, %st)
        : (!cute.shape<"(?,2)">, !cute.stride<"(2,?)">) -> !cute.layout<"(?,2):(2,?)">
  %sw = cute.static : !cute.swizzle<"S<3,4,3>">
  %off = cute.static : !cute.int_tuple<"6">
  %src = cute.make_composed_layout (%sw, %off, %outer)
        : (!cute.swizzle<"S<3,4,3>">, !cute.int_tuple<"6">, !cute.layout<"(?,2):(2,?)">)
       -> !cute.composed_layout<"S<3,4,3> o 6 o (?,2):(2,?)">
  %r = cute.make_layout_like(%src)
       : !cute.composed_layout<"S<3,4,3> o 6 o (?,2):(2,?)"> -> !cute.layout<"(?,2):(1,?)">
  return %r : !cute.layout<"(?,2):(1,?)">
}

func.func @h_make_identity_layout_nested(%a: i32)
    -> !cute.layout<"(2,(?,4)):(1@0,(1@0@1,1@1@1))"> {
  %sh = cute.make_shape (%a) : (i32) -> !cute.shape<"(2,(?,4))">
  %r = cute.make_identity_layout(%sh)
       : !cute.shape<"(2,(?,4))"> -> !cute.layout<"(2,(?,4)):(1@0,(1@0@1,1@1@1))">
  return %r : !cute.layout<"(2,(?,4)):(1@0,(1@0@1,1@1@1))">
}

//===----------------------------------------------------------------------===//
// Entry point — helper-call only.
//===----------------------------------------------------------------------===//

func.func @main() {
  %x4 = arith.constant 4 : i32
  %r1 = func.call @h_make_layout_like(%x4) : (i32) -> !cute.layout<"(?,3):(1,?)">
  cute.print(%r1) : !cute.layout<"(?,3):(1,?)">

  %x5 = arith.constant 5 : i32
  %r2 = func.call @h_make_identity_layout(%x5) : (i32) -> !cute.layout<"(?,2):(1@0,1@1)">
  cute.print(%r2) : !cute.layout<"(?,2):(1@0,1@1)">

  %x6 = arith.constant 6 : i32
  %r3 = func.call @h_make_ordered_layout(%x6) : (i32) -> !cute.layout<"(?,2):(1,?)">
  cute.print(%r3) : !cute.layout<"(?,2):(1,?)">

  // Composed-source variants.
  %x8 = arith.constant 8 : i32
  %x16 = arith.constant 16 : i32
  %r5 = func.call @h_make_layout_like_composed(%x8, %x16)
      : (i32, i32) -> !cute.layout<"(?,2):(1,?)">
  cute.print(%r5) : !cute.layout<"(?,2):(1,?)">

  // Nested make_identity_layout — inner_leaf=3.
  %x3 = arith.constant 3 : i32
  %r7 = func.call @h_make_identity_layout_nested(%x3)
      : (i32) -> !cute.layout<"(2,(?,4)):(1@0,(1@0@1,1@1@1))">
  cute.print(%r7) : !cute.layout<"(2,(?,4)):(1@0,(1@0@1,1@1@1))">

  return
}
