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
// RUN: %cutlass-compiler-run-device %s | FileCheck %s
//
// Dynamic LayoutAlgebra kernel; dyn leaves are kernel-internal arith.constant.
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
// slice / dice on multi-slot dyn composed_layout — pins canonical
// A o offset o B `cute.print` order on-device.
// CHECK: (4,5):(1,4) o 50 o (3):(8)
// CHECK: (4,5):(1,4) o 50 o (8):(1)
// flatten — nested dyn layout (3,(?,5)):(8,(1,4)) at runtime ?=3 → (3,3,5):(8,1,4).
// CHECK: (3,3,5):(8,1,4)
// coalesce — dyn middle blocks static groups on either side from merging.
// CHECK: (20,7,6):(1,9,1)
// complement — rank-1 dyn-stride `(3):(?)` × static shape `12`.
// Runtime stride=2 ⇒ result `(2,2):(1,6)`.
// CHECK: (2,2):(1,6)

module attributes {gpu.container_module} {
  gpu.module @kernel {
    gpu.func @print_all() kernel {
      %tx = gpu.thread_id x
      %c0 = arith.constant 0 : index
      %is_zero = arith.cmpi eq, %tx, %c0 : index
      scf.if %is_zero {
        // composition — dyn outer (?:?) ∘ static inner (5,4):(4,1).
        // outer = 20:2, inner = (5,4):(4,1) ⇒ result (5,4):(8,2).
        %x20 = arith.constant 20 : i32
        %x2c = arith.constant 2 : i32
        %sh_o = cute.make_shape (%x20) : (i32) -> !cute.shape<"?">
        %st_o = cute.make_stride (%x2c) : (i32) -> !cute.stride<"?">
        %outer = cute.make_layout (%sh_o, %st_o)
            : (!cute.shape<"?">, !cute.stride<"?">) -> !cute.layout<"?:?">
        %inner = cute.static : !cute.layout<"(5,4):(4,1)">
        %r1 = cute.composition(%outer, %inner)
            : (!cute.layout<"?:?">, !cute.layout<"(5,4):(4,1)">)
           -> !cute.layout<"(5,4):(?,?)">
        cute.print(%r1) : !cute.layout<"(5,4):(?,?)">

        // 2D dyn layout for the structural ops below.
        %x4 = arith.constant 4 : i32
        %sh = cute.make_shape (%x4) : (i32) -> !cute.shape<"(?,5)">
        %l_stride = cute.make_stride (%x4) : (i32) -> !cute.stride<"(1,?)">
        %l = cute.make_layout (%sh, %l_stride) : (!cute.shape<"(?,5)">, !cute.stride<"(1,?)">) -> !cute.layout<"(?,5):(1,?)">
        // coalesce — type system can't prove contiguity for dyn extents.
        %r2 = cute.coalesce(%l)
            : (!cute.layout<"(?,5):(1,?)">) -> !cute.layout<"(?,5):(1,?)">
        cute.print(%r2) : !cute.layout<"(?,5):(1,?)">

        // group_modes — wrap modes [0, 2) into a sub-tuple.
        %r3 = cute.group_modes<0, 2>(%l)
            : (!cute.layout<"(?,5):(1,?)">) -> !cute.layout<"((?,5)):((1,?))">
        cute.print(%r3) : !cute.layout<"((?,5)):((1,?))">

        // group_modes on composed input — swizzle-A + dyn B.
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

        // recast_layout — dyn (32,?):(1,?) → (8,?):(1,?)
        %x32 = arith.constant 32 : i32
        %sh32 = cute.make_shape (%x32) : (i32) -> !cute.shape<"(32,?)">
        %st32 = cute.make_stride (%x32) : (i32) -> !cute.stride<"(1,?)">
        %lr = cute.make_layout (%sh32, %st32)
            : (!cute.shape<"(32,?)">, !cute.stride<"(1,?)">)
           -> !cute.layout<"(32,?):(1,?)">
        %r4 = cute.recast_layout<32, 8>(%lr)
            : !cute.layout<"(32,?):(1,?)"> -> !cute.layout<"(8,?):(1,?)">
        cute.print(%r4) : !cute.layout<"(8,?):(1,?)">

        // recast_layout on composed input — swizzle-A + dyn B upcast.
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

        // slice — keep the underscore positions; crd (0,_) keeps mode 1.
        %crd_s = cute.static : !cute.coord<"(0,_)">
        %r5 = cute.slice(%l, %crd_s)
            : !cute.layout<"(?,5):(1,?)">, !cute.coord<"(0,_)">
        cute.print(%r5) : !cute.layout<"(5):(?)">

        // dice — crd (1,_) keeps mode 0.
        %crd_d = cute.static : !cute.coord<"(1,_)">
        %r6 = cute.dice(%l, %crd_d)
            : !cute.layout<"(?,5):(1,?)">, !cute.coord<"(1,_)">
        cute.print(%r6) : !cute.layout<"(?):(1)">

        // slice / dice on multi-slot dyn composed_layout — pins the
        // canonical A o offset o B `cute.print` order on-device.
        // Inputs: A=(4,5):(1,4), offset=50, B=(8,3):(1,8); each leaf
        // is dynamic. Result has 7 dyn leaves across all three slots.
        %x5c = arith.constant 5 : i32
        %x1c = arith.constant 1 : i32
        %x50c = arith.constant 50 : i32
        %x8c = arith.constant 8 : i32
        %sd_a_sh = cute.make_shape(%x4, %x5c)
              : (i32, i32) -> !cute.shape<"(?,?)">
        %sd_a_st = cute.make_stride(%x1c, %x4)
              : (i32, i32) -> !cute.stride<"(?,?)">
        %sd_a = cute.make_layout(%sd_a_sh, %sd_a_st)
              : (!cute.shape<"(?,?)">, !cute.stride<"(?,?)">)
             -> !cute.layout<"(?,?):(?,?)">
        %sd_off = cute.make_int_tuple(%x50c) : (i32) -> !cute.int_tuple<"?">
        %sd_b_sh_c = arith.constant 3 : i32
        %sd_b_sh = cute.make_shape(%x8c, %sd_b_sh_c)
              : (i32, i32) -> !cute.shape<"(?,?)">
        %sd_b_st = cute.make_stride(%x1c, %x8c)
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
        %x3 = arith.constant 3 : i32
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
        %xmid = arith.constant 7 : i32
        %smid = arith.constant 9 : i32
        %sh_m = cute.make_shape (%xmid) : (i32) -> !cute.shape<"(4,5,?,3,2)">
        %st_m = cute.make_stride (%smid) : (i32) -> !cute.stride<"(1,4,?,1,3)">
        %lm = cute.make_layout (%sh_m, %st_m)
            : (!cute.shape<"(4,5,?,3,2)">, !cute.stride<"(1,4,?,1,3)">)
           -> !cute.layout<"(4,5,?,3,2):(1,4,?,1,3)">
        %r9 = cute.coalesce(%lm)
            : (!cute.layout<"(4,5,?,3,2):(1,4,?,1,3)">)
           -> !cute.layout<"(20,?,6):(1,?,1)">
        cute.print(%r9) : !cute.layout<"(20,?,6):(1,?,1)">

        // complement — rank-1 dyn-stride input `(3):(?)`. Stride=2 at
        // runtime via kernel-internal arith.constant.
        %cmp_st_v = cute.make_stride (%x2c) : (i32) -> !cute.stride<"(?)">
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
    %c1 = arith.constant 1 : index
    %c4 = arith.constant 4 : index
    gpu.launch_func @kernel::@print_all blocks in (%c1, %c1, %c1) threads in (%c4, %c1, %c1)
    return
  }
}
