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

// RUN: env CUTLASS_COMPILER_TEST_BASE=0 %cutlass-compiler-run-host %s | FileCheck %s

// Runtime-dynamic AdvancedConstructors; leaves are opaque to the JIT, any arith is permitted.


// CHECK-COUNT-2: (4,3):(1,4)
// CHECK-COUNT-2: (5,2):(1@0,1@1)
// CHECK-COUNT-2: (6,2):(1,6)
// CHECK-COUNT-2: (8,2):(1,8)
// CHECK-COUNT-2: (2,(3,4)):(1@0,(1@0@1,1@1@1))

//===----------------------------------------------------------------------===//
// libc bridge: getenv/atoi for the runtime-dynamic baseline.
//===----------------------------------------------------------------------===//

llvm.func @getenv(!llvm.ptr) -> !llvm.ptr
llvm.func @atoi(!llvm.ptr) -> i32

llvm.mlir.global internal constant @cutlass_compiler_env_name("CUTLASS_COMPILER_TEST_BASE\00") {addr_space = 0 : i32}

func.func private @read_base() -> i32 {
  %name_addr = llvm.mlir.addressof @cutlass_compiler_env_name : !llvm.ptr
  %name = llvm.getelementptr %name_addr[0, 0]
        : (!llvm.ptr) -> !llvm.ptr, !llvm.array<15 x i8>
  %env = llvm.call @getenv(%name) : (!llvm.ptr) -> !llvm.ptr
  %v = llvm.call @atoi(%env) : (!llvm.ptr) -> i32
  return %v : i32
}

//===----------------------------------------------------------------------===//
// Per-op helpers.
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

// Composed-source helpers.
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
// Entry point.
//===----------------------------------------------------------------------===//

func.func @main() {
  %base = func.call @read_base() : () -> i32

  // make_layout_like
  %o4 = arith.constant 4 : i32
  %x4 = arith.addi %base, %o4 : i32
  %sh1 = cute.make_shape (%x4) : (i32) -> !cute.shape<"(?,3)">
  %src1_stride = cute.make_stride (%x4) : (i32) -> !cute.stride<"(1,?)">
  %src1 = cute.make_layout (%sh1, %src1_stride) : (!cute.shape<"(?,3)">, !cute.stride<"(1,?)">) -> !cute.layout<"(?,3):(1,?)">
  %r1 = cute.make_layout_like(%src1)
       : !cute.layout<"(?,3):(1,?)"> -> !cute.layout<"(?,3):(1,?)">
  cute.print(%r1) : !cute.layout<"(?,3):(1,?)">
  %r1b = func.call @h_make_layout_like(%x4) : (i32) -> !cute.layout<"(?,3):(1,?)">
  cute.print(%r1b) : !cute.layout<"(?,3):(1,?)">

  // make_identity_layout
  %o5 = arith.constant 5 : i32
  %x5 = arith.addi %base, %o5 : i32
  %sh2 = cute.make_shape (%x5) : (i32) -> !cute.shape<"(?,2)">
  %r2 = cute.make_identity_layout(%sh2)
       : !cute.shape<"(?,2)"> -> !cute.layout<"(?,2):(1@0,1@1)">
  cute.print(%r2) : !cute.layout<"(?,2):(1@0,1@1)">
  %r2b = func.call @h_make_identity_layout(%x5)
       : (i32) -> !cute.layout<"(?,2):(1@0,1@1)">
  cute.print(%r2b) : !cute.layout<"(?,2):(1@0,1@1)">

  // make_ordered_layout
  %o6 = arith.constant 6 : i32
  %x6 = arith.addi %base, %o6 : i32
  %sh3 = cute.make_shape (%x6) : (i32) -> !cute.shape<"(?,2)">
  %ord = cute.static : !cute.int_tuple<"(0,1)">
  %r3 = cute.make_ordered_layout(%sh3, %ord)
       : (!cute.shape<"(?,2)">, !cute.int_tuple<"(0,1)">) -> !cute.layout<"(?,2):(1,?)">
  cute.print(%r3) : !cute.layout<"(?,2):(1,?)">
  %r3b = func.call @h_make_ordered_layout(%x6) : (i32) -> !cute.layout<"(?,2):(1,?)">
  cute.print(%r3b) : !cute.layout<"(?,2):(1,?)">

  // make_layout_like composed — shape_leaf=8, stride_leaf=16.
  %o8 = arith.constant 8 : i32
  %x8 = arith.addi %base, %o8 : i32
  %o16 = arith.constant 16 : i32
  %x16 = arith.addi %base, %o16 : i32
  %sh5 = cute.make_shape (%x8) : (i32) -> !cute.shape<"(?,2)">
  %st5 = cute.make_stride (%x16) : (i32) -> !cute.stride<"(2,?)">
  %outer5 = cute.make_layout (%sh5, %st5)
        : (!cute.shape<"(?,2)">, !cute.stride<"(2,?)">) -> !cute.layout<"(?,2):(2,?)">
  %sw = cute.static : !cute.swizzle<"S<3,4,3>">
  %off = cute.static : !cute.int_tuple<"6">
  %src5 = cute.make_composed_layout (%sw, %off, %outer5)
        : (!cute.swizzle<"S<3,4,3>">, !cute.int_tuple<"6">, !cute.layout<"(?,2):(2,?)">)
       -> !cute.composed_layout<"S<3,4,3> o 6 o (?,2):(2,?)">
  %r5 = cute.make_layout_like(%src5)
       : !cute.composed_layout<"S<3,4,3> o 6 o (?,2):(2,?)"> -> !cute.layout<"(?,2):(1,?)">
  cute.print(%r5) : !cute.layout<"(?,2):(1,?)">
  %r5b = func.call @h_make_layout_like_composed(%x8, %x16)
       : (i32, i32) -> !cute.layout<"(?,2):(1,?)">
  cute.print(%r5b) : !cute.layout<"(?,2):(1,?)">

  // make_identity_layout nested — inner_leaf=3.
  %o3 = arith.constant 3 : i32
  %x3 = arith.addi %base, %o3 : i32
  %sh7 = cute.make_shape (%x3) : (i32) -> !cute.shape<"(2,(?,4))">
  %r7 = cute.make_identity_layout(%sh7)
       : !cute.shape<"(2,(?,4))"> -> !cute.layout<"(2,(?,4)):(1@0,(1@0@1,1@1@1))">
  cute.print(%r7) : !cute.layout<"(2,(?,4)):(1@0,(1@0@1,1@1@1))">
  %r7b = func.call @h_make_identity_layout_nested(%x3)
       : (i32) -> !cute.layout<"(2,(?,4)):(1@0,(1@0@1,1@1@1))">
  cute.print(%r7b) : !cute.layout<"(2,(?,4)):(1@0,(1@0@1,1@1@1))">

  return
}
