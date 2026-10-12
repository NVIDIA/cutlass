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

// REQUIRES: cutlass_compiler_device
// RUN: env CUTLASS_COMPILER_TEST_BASE=0 %cutlass-compiler-run-device %s | FileCheck %s
//
// Runtime-dynamic LayoutAlgebra kernel; dyn leaves cross host→device via gpu.launch_func args.
// right_inverse and left_inverse require static input and are excluded.

// CHECK: (5,4):(8,2)
// CHECK: (4,5):(1,4)
// CHECK: ((4,5)):((1,4))
// group_modes on composed input — swizzle-A + dyn B.
// CHECK: S<3,4,3> o 0 o ((4,5),6):((1,4),20)
// CHECK: (8,32):(1,8)
// recast_layout on composed input — swizzle-A + dyn B upcast.
// CHECK: S<3,3,4> o 0 o (1,5,6):(1,1,5)
// CHECK: (5):(4)
// CHECK: (4):(1)
// slice / dice on multi-slot dyn composed_layout — runtime-dyn input
// (every leaf flows through `arith.addi %base, %const`). Pins
// canonical A o offset o B `cute.print` order on-device.
// CHECK: (4,5):(1,4) o 50 o (3):(8)
// CHECK: (4,5):(1,4) o 50 o (8):(1)
// flatten — nested dyn layout (3,(?,5)):(8,(1,4)) at runtime ?=3 → (3,3,5):(8,1,4).
// CHECK: (3,3,5):(8,1,4)
// coalesce — dyn middle blocks static groups on either side from merging.
// CHECK: (20,7,6):(1,9,1)
// complement — rank-1 dyn-stride `(3):(?)` × static shape `12`.
// Stride built from %base+2 ⇒ result `(2,2):(1,6)`.
// CHECK: (2,2):(1,6)

module attributes {gpu.container_module} {
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

  gpu.module @kernel {
    gpu.func @print_all(%base: i32) kernel {
      %tx = gpu.thread_id x
      %c0_idx = arith.constant 0 : index
      %is_zero = arith.cmpi eq, %tx, %c0_idx : index
      scf.if %is_zero {
        // composition.
        %o20 = arith.constant 20 : i32
        %o2 = arith.constant 2 : i32
        %x20 = arith.addi %base, %o20 : i32
        %x2 = arith.addi %base, %o2 : i32
        %sh_o = cute.make_shape (%x20) : (i32) -> !cute.shape<"?">
        %st_o = cute.make_stride (%x2) : (i32) -> !cute.stride<"?">
        %outer = cute.make_layout (%sh_o, %st_o)
            : (!cute.shape<"?">, !cute.stride<"?">) -> !cute.layout<"?:?">
        %inner = cute.static : !cute.layout<"(5,4):(4,1)">
        %r1 = cute.composition(%outer, %inner)
            : (!cute.layout<"?:?">, !cute.layout<"(5,4):(4,1)">)
           -> !cute.layout<"(5,4):(?,?)">
        cute.print(%r1) : !cute.layout<"(5,4):(?,?)">

        // 2D dyn layout for structural ops.
        %o4 = arith.constant 4 : i32
        %x4 = arith.addi %base, %o4 : i32
        %sh = cute.make_shape (%x4) : (i32) -> !cute.shape<"(?,5)">
        %l_stride = cute.make_stride (%x4) : (i32) -> !cute.stride<"(1,?)">
        %l = cute.make_layout (%sh, %l_stride) : (!cute.shape<"(?,5)">, !cute.stride<"(1,?)">) -> !cute.layout<"(?,5):(1,?)">
        // coalesce.
        %r2 = cute.coalesce(%l)
            : (!cute.layout<"(?,5):(1,?)">) -> !cute.layout<"(?,5):(1,?)">
        cute.print(%r2) : !cute.layout<"(?,5):(1,?)">

        // group_modes.
        %r3 = cute.group_modes<0, 2>(%l)
            : (!cute.layout<"(?,5):(1,?)">) -> !cute.layout<"((?,5)):((1,?))">
        cute.print(%r3) : !cute.layout<"((?,5)):((1,?))">

        // group_modes on composed input — swizzle-A + dyn B. Stride
        // built from %base + 4 so it stays opaque across host→device.
        %gm_co_sw = cute.static : !cute.swizzle<"S<3,4,3>">
        %gm_co_off = cute.static : !cute.int_tuple<"0">
        %gm_co_sh = cute.make_shape (%x4) : (i32) -> !cute.shape<"(?,5,6)">
        %c5_for_gm_co_b_stride = arith.constant 5 : i32
        %gm_co_b_stride_mul = arith.muli %x4, %c5_for_gm_co_b_stride : i32
        %gm_co_b_stride = cute.make_stride (%x4, %gm_co_b_stride_mul) : (i32, i32) -> !cute.stride<"(1,?,?)">
        %gm_co_b = cute.make_layout (%gm_co_sh, %gm_co_b_stride) : (!cute.shape<"(?,5,6)">, !cute.stride<"(1,?,?)">) -> !cute.layout<"(?,5,6):(1,?,?)">
        %gm_co_in = cute.make_composed_layout(%gm_co_sw, %gm_co_off, %gm_co_b)
            : (!cute.swizzle<"S<3,4,3>">, !cute.int_tuple<"0">,
               !cute.layout<"(?,5,6):(1,?,?)">)
           -> !cute.composed_layout<"S<3,4,3> o 0 o (?,5,6):(1,?,?)">
        %r3c = cute.group_modes<0, 2>(%gm_co_in)
            : (!cute.composed_layout<"S<3,4,3> o 0 o (?,5,6):(1,?,?)">)
           -> !cute.composed_layout<"S<3,4,3> o 0 o ((?,5),6):((1,?),?)">
        cute.print(%r3c) : !cute.composed_layout<"S<3,4,3> o 0 o ((?,5),6):((1,?),?)">

        // recast_layout.
        %o32 = arith.constant 32 : i32
        %x32 = arith.addi %base, %o32 : i32
        %sh32 = cute.make_shape (%x32) : (i32) -> !cute.shape<"(32,?)">
        %st32 = cute.make_stride (%x32) : (i32) -> !cute.stride<"(1,?)">
        %lr = cute.make_layout (%sh32, %st32)
            : (!cute.shape<"(32,?)">, !cute.stride<"(1,?)">)
           -> !cute.layout<"(32,?):(1,?)">
        %r4 = cute.recast_layout<32, 8>(%lr)
            : !cute.layout<"(32,?):(1,?)"> -> !cute.layout<"(8,?):(1,?)">
        cute.print(%r4) : !cute.layout<"(8,?):(1,?)">

        // recast_layout on composed input — swizzle-A + dyn B upcast.
        // B shape built from %x4 (= %base + 4) so it stays opaque.
        %rl_co_sw = cute.static : !cute.swizzle<"S<3,5,4>">
        %rl_co_off = cute.static : !cute.int_tuple<"0">
        %rl_co_sh = cute.make_shape (%x4) : (i32) -> !cute.shape<"(?,5,6)">
        %c5_for_rl_co_b_stride = arith.constant 5 : i32
        %rl_co_b_stride_mul = arith.muli %x4, %c5_for_rl_co_b_stride : i32
        %rl_co_b_stride = cute.make_stride (%x4, %rl_co_b_stride_mul) : (i32, i32) -> !cute.stride<"(1,?,?)">
        %rl_co_b = cute.make_layout (%rl_co_sh, %rl_co_b_stride) : (!cute.shape<"(?,5,6)">, !cute.stride<"(1,?,?)">) -> !cute.layout<"(?,5,6):(1,?,?)">
        %rl_co_in = cute.make_composed_layout(%rl_co_sw, %rl_co_off, %rl_co_b)
            : (!cute.swizzle<"S<3,5,4>">, !cute.int_tuple<"0">,
               !cute.layout<"(?,5,6):(1,?,?)">)
           -> !cute.composed_layout<"S<3,5,4> o 0 o (?,5,6):(1,?,?)">
        %r4c = cute.recast_layout<32, 8>(%rl_co_in)
            : !cute.composed_layout<"S<3,5,4> o 0 o (?,5,6):(1,?,?)">
           -> !cute.composed_layout<"S<3,3,4> o 0 o (?,5,6):(1,?,?)">
        cute.print(%r4c) : !cute.composed_layout<"S<3,3,4> o 0 o (?,5,6):(1,?,?)">

        // slice.
        %crd_s = cute.static : !cute.coord<"(0,_)">
        %r5 = cute.slice(%l, %crd_s)
            : !cute.layout<"(?,5):(1,?)">, !cute.coord<"(0,_)">
        cute.print(%r5) : !cute.layout<"(5):(?)">

        // dice.
        %crd_d = cute.static : !cute.coord<"(1,_)">
        %r6 = cute.dice(%l, %crd_d)
            : !cute.layout<"(?,5):(1,?)">, !cute.coord<"(1,_)">
        cute.print(%r6) : !cute.layout<"(?):(1)">

        // slice / dice on multi-slot dyn composed_layout — runtime-dyn
        // variant. Each leaf is constructed via `addi %base, %const`;
        // at base=0 the runtime values match the inlined-host case.
        // Pins canonical A o offset o B `cute.print` order on-device
        // when every dyn leaf flows through the kernel argument.
        %sd_a4_o = arith.constant 4 : i32
        %sd_a4 = arith.addi %base, %sd_a4_o : i32
        %sd_a5_o = arith.constant 5 : i32
        %sd_a5 = arith.addi %base, %sd_a5_o : i32
        %sd_a1_o = arith.constant 1 : i32
        %sd_a1 = arith.addi %base, %sd_a1_o : i32
        %sd_off50_o = arith.constant 50 : i32
        %sd_off50 = arith.addi %base, %sd_off50_o : i32
        %sd_b8_o = arith.constant 8 : i32
        %sd_b8 = arith.addi %base, %sd_b8_o : i32
        %sd_b3_o = arith.constant 3 : i32
        %sd_b3 = arith.addi %base, %sd_b3_o : i32
        %sd_a_sh = cute.make_shape(%sd_a4, %sd_a5)
              : (i32, i32) -> !cute.shape<"(?,?)">
        %sd_a_st = cute.make_stride(%sd_a1, %sd_a4)
              : (i32, i32) -> !cute.stride<"(?,?)">
        %sd_a = cute.make_layout(%sd_a_sh, %sd_a_st)
              : (!cute.shape<"(?,?)">, !cute.stride<"(?,?)">)
             -> !cute.layout<"(?,?):(?,?)">
        %sd_off = cute.make_int_tuple(%sd_off50)
              : (i32) -> !cute.int_tuple<"?">
        %sd_b_sh = cute.make_shape(%sd_b8, %sd_b3)
              : (i32, i32) -> !cute.shape<"(?,?)">
        %sd_b_st = cute.make_stride(%sd_a1, %sd_b8)
              : (i32, i32) -> !cute.stride<"(?,?)">
        %sd_b = cute.make_layout(%sd_b_sh, %sd_b_st)
              : (!cute.shape<"(?,?)">, !cute.stride<"(?,?)">)
             -> !cute.layout<"(?,?):(?,?)">
        %sd_in = cute.make_composed_layout(%sd_a, %sd_off, %sd_b)
              : (!cute.layout<"(?,?):(?,?)">, !cute.int_tuple<"?">,
                 !cute.layout<"(?,?):(?,?)">)
             -> !cute.composed_layout<"(?,?):(?,?) o ? o (?,?):(?,?)">
        %crd_sc = cute.static : !cute.coord<"(0,_)">
        %r_sc = cute.slice(%sd_in, %crd_sc)
              : !cute.composed_layout<"(?,?):(?,?) o ? o (?,?):(?,?)">,
                !cute.coord<"(0,_)">
        cute.print(%r_sc) : !cute.composed_layout<"(?,?):(?,?) o ? o (?):(?)">
        %crd_dc = cute.static : !cute.coord<"(1,_)">
        %r_dc = cute.dice(%sd_in, %crd_dc)
              : !cute.composed_layout<"(?,?):(?,?) o ? o (?,?):(?,?)">,
                !cute.coord<"(1,_)">
        cute.print(%r_dc) : !cute.composed_layout<"(?,?):(?,?) o ? o (?):(?)">

        // flatten — nested dyn layout (3,(?,5)):(8,(1,4)) at runtime ?=3 →
        // (3,3,5):(8,1,4).
        %c3 = arith.constant 3 : i32
        %x3 = arith.addi %base, %c3 : i32
        %fl_sh = cute.make_shape (%x3) : (i32) -> !cute.shape<"(3,(?,5))">
        %fl_st = cute.static : !cute.stride<"(8,(1,4))">
        %fl_in = cute.make_layout (%fl_sh, %fl_st)
            : (!cute.shape<"(3,(?,5))">, !cute.stride<"(8,(1,4))">)
           -> !cute.layout<"(3,(?,5)):(8,(1,4))">
        %r_fl = cute.flatten(%fl_in)
            : (!cute.layout<"(3,(?,5)):(8,(1,4))">) -> !cute.layout<"(3,?,5):(8,1,4)">
        cute.print(%r_fl) : !cute.layout<"(3,?,5):(8,1,4)">

        // coalesce — dyn middle mode blocks merge. Static groups on either
        // side coalesce independently — (4,5):(1,4) → 20:1 and
        // (3,2):(1,3) → 6:1 — while the dyn middle stays as-is.
        %o7 = arith.constant 7 : i32
        %o9 = arith.constant 9 : i32
        %xmid = arith.addi %base, %o7 : i32
        %smid = arith.addi %base, %o9 : i32
        %sh_m = cute.make_shape (%xmid) : (i32) -> !cute.shape<"(4,5,?,3,2)">
        %st_m = cute.make_stride (%smid) : (i32) -> !cute.stride<"(1,4,?,1,3)">
        %lm = cute.make_layout (%sh_m, %st_m)
            : (!cute.shape<"(4,5,?,3,2)">, !cute.stride<"(1,4,?,1,3)">)
           -> !cute.layout<"(4,5,?,3,2):(1,4,?,1,3)">
        %r9 = cute.coalesce(%lm)
            : (!cute.layout<"(4,5,?,3,2):(1,4,?,1,3)">)
           -> !cute.layout<"(20,?,6):(1,?,1)">
        cute.print(%r9) : !cute.layout<"(20,?,6):(1,?,1)">

        // complement — rank-1 dyn-stride input. Stride built from
        // %base + 2, so it stays opaque across the host->device boundary.
        %o2c = arith.constant 2 : i32
        %cmp_st = arith.addi %base, %o2c : i32
        %cmp_st_v = cute.make_stride (%cmp_st) : (i32) -> !cute.stride<"(?)">
        %cmp_sh = cute.static : !cute.shape<"(3)">
        %cmp_in = cute.make_layout (%cmp_sh, %cmp_st_v)
            : (!cute.shape<"(3)">, !cute.stride<"(?)">) -> !cute.layout<"(3):(?)">
        %cmp_co = cute.static : !cute.shape<"12">
        %r10 = cute.complement(%cmp_in, %cmp_co)
            : (!cute.layout<"(3):(?)">, !cute.shape<"12">)
           -> !cute.layout<"(?,?):(1,?)">
        cute.print(%r10) : !cute.layout<"(?,?):(1,?)">
      }
      gpu.return
    }
  }

  func.func @main() {
    %base = func.call @read_base() : () -> i32
    %c1 = arith.constant 1 : index
    %c4 = arith.constant 4 : index
    gpu.launch_func @kernel::@print_all blocks in (%c1, %c1, %c1) threads in (%c4, %c1, %c1) args(%base : i32)
    return
  }
}
