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
// Dynamic Accessors kernel; dyn leaves are kernel-internal arith.constant.

// CHECK: (4,7)
// CHECK: (1,8)
// CHECK: 11:1
// CHECK: 17
// CHECK: 19
// CHECK: 23
// CHECK: 29
// CHECK: 145
// CHECK: (37,3):(1,37)
// CHECK: (43,4):(1,43)
// CHECK: 53
// CHECK: (2,3):(1,2)
// CHECK: (59):(1)
// CHECK: (71,73)
// CHECK: (89,97)
// CHECK: (109@0,1@1)
// CHECK: S<2,3,5>
// CHECK: 113
// CHECK: (127,131):(1,127)
// CHECK: (149,137):(19043,1)
// CHECK: ()
// CHECK: (1,239)
// CHECK: (251,3):(1,257)
// CHECK: (5,269):(1,5)

module attributes {gpu.container_module} {
  gpu.module @kernel {
    gpu.func @print_all() kernel {
      %tx = gpu.thread_id x
      %c0 = arith.constant 0 : index
      %is_zero = arith.cmpi eq, %tx, %c0 : index
      scf.if %is_zero {
        // get_shape — extract shape from a layout with a dyn shape leaf.
        %x4 = arith.constant 4 : i32
        %sh_in1 = cute.make_shape (%x4) : (i32) -> !cute.shape<"(?,7)">
        %l1_stride = cute.make_stride (%x4) : (i32) -> !cute.stride<"(1,?)">
        %l1 = cute.make_layout (%sh_in1, %l1_stride) : (!cute.shape<"(?,7)">, !cute.stride<"(1,?)">) -> !cute.layout<"(?,7):(1,?)">
        %sh1 = cute.get_shape(%l1)
            : !cute.layout<"(?,7):(1,?)"> -> !cute.shape<"(?,7)">
        cute.print(%sh1) : !cute.shape<"(?,7)">

        // get_stride — extract stride from a dyn-stride layout.
        %x8 = arith.constant 8 : i32
        %sh_in2 = cute.make_shape (%x8) : (i32) -> !cute.shape<"(?,3)">
        %l2_stride = cute.make_stride (%x8) : (i32) -> !cute.stride<"(1,?)">
        %l2 = cute.make_layout (%sh_in2, %l2_stride) : (!cute.shape<"(?,3)">, !cute.stride<"(1,?)">) -> !cute.layout<"(?,3):(1,?)">
        %st1 = cute.get_stride(%l2)
            : !cute.layout<"(?,3):(1,?)"> -> !cute.stride<"(1,?)">
        cute.print(%st1) : !cute.stride<"(1,?)">

        // get<[0]> — pick mode 0 from a dyn layout.
        %x11 = arith.constant 11 : i32
        %sh_in3 = cute.make_shape (%x11) : (i32) -> !cute.shape<"(?,5)">
        %l3_stride = cute.make_stride (%x11) : (i32) -> !cute.stride<"(1,?)">
        %l3 = cute.make_layout (%sh_in3, %l3_stride) : (!cute.shape<"(?,5)">, !cute.stride<"(1,?)">) -> !cute.layout<"(?,5):(1,?)">
        %g1 = cute.get<[0]> (%l3)
            : !cute.layout<"(?,5):(1,?)"> -> !cute.layout<"?:1">
        cute.print(%g1) : !cute.layout<"?:1">

        // get_leaves — flatten a nested shape with two dyn leaves.
        %x17 = arith.constant 17 : i32
        %x23 = arith.constant 23 : i32
        %s_lv = cute.make_shape (%x17, %x23)
            : (i32, i32) -> !cute.shape<"(?,(19,?))">
        %a, %b, %c = cute.get_leaves(%s_lv) : !cute.shape<"(?,(19,?))">
        cute.print(%a) : !cute.shape<"?">
        cute.print(%b) : !cute.shape<"19">
        cute.print(%c) : !cute.shape<"?">

        // get_scalars<{only_dynamic}> — extract dyn i32 leaves.
        %x29 = arith.constant 29 : i32
        %x145 = arith.constant 145 : i32
        %sh_in5 = cute.make_shape (%x29) : (i32) -> !cute.shape<"(?,5)">
        %st_in5 = cute.make_stride (%x145) : (i32) -> !cute.stride<"(1,?)">
        %l5 = cute.make_layout (%sh_in5, %st_in5)
            : (!cute.shape<"(?,5)">, !cute.stride<"(1,?)">)
           -> !cute.layout<"(?,5):(1,?)">
        %s1, %s2 = cute.get_scalars<{only_dynamic}>(%l5)
            : !cute.layout<"(?,5):(1,?)">
        gpu.printf "%d\n", %s1 : i32
        gpu.printf "%d\n", %s2 : i32

        // get_layouts_from_tile — single-layout dyn tile, both ?s = 37.
        %x37 = arith.constant 37 : i32
        %t = cute.make_tile (%x37, %x37)
            : (i32, i32) -> !cute.tile<"[(?,3):(1,?)]">
        %lt = cute.get_layouts_from_tile(%t) : !cute.tile<"[(?,3):(1,?)]">
        cute.print(%lt) : !cute.layout<"(?,3):(1,?)">

        // composed_get_inner — extract the inner layout.
        %x43 = arith.constant 43 : i32
        %sh_in7 = cute.make_shape (%x43) : (i32) -> !cute.shape<"(?,4)">
        %inner_stride = cute.make_stride (%x43) : (i32) -> !cute.stride<"(1,?)">
        %inner = cute.make_layout (%sh_in7, %inner_stride) : (!cute.shape<"(?,4)">, !cute.stride<"(1,?)">) -> !cute.layout<"(?,4):(1,?)">
        %off_st = cute.static : !cute.int_tuple<"53">
        %outer_st = cute.static : !cute.layout<"(2,3):(1,2)">
        %cl = cute.make_composed_layout (%inner, %off_st, %outer_st)
            : (!cute.layout<"(?,4):(1,?)">, !cute.int_tuple<"53">,
               !cute.layout<"(2,3):(1,2)">)
           -> !cute.composed_layout<"(?,4):(1,?) o 53 o (2,3):(1,2)">

        %in1 = cute.composed_get_inner(%cl)
            : !cute.composed_layout<"(?,4):(1,?) o 53 o (2,3):(1,2)">
           -> !cute.layout<"(?,4):(1,?)">
        cute.print(%in1) : !cute.layout<"(?,4):(1,?)">

        // composed_get_offset — extract the (static) offset.
        %off1 = cute.composed_get_offset(%cl)
            : !cute.composed_layout<"(?,4):(1,?) o 53 o (2,3):(1,2)">
           -> !cute.int_tuple<"53">
        cute.print(%off1) : !cute.int_tuple<"53">

        // composed_get_outer — extract the (static) outer layout.
        %out1 = cute.composed_get_outer(%cl)
            : !cute.composed_layout<"(?,4):(1,?) o 53 o (2,3):(1,2)">
           -> !cute.layout<"(2,3):(1,2)">
        cute.print(%out1) : !cute.layout<"(2,3):(1,2)">

        // select<[0]> — pick mode 0 from a dyn layout.
        %x59 = arith.constant 59 : i32
        %sh_in10 = cute.make_shape (%x59) : (i32) -> !cute.shape<"(?,5)">
        %l10_stride = cute.make_stride (%x59) : (i32) -> !cute.stride<"(1,?)">
        %l10 = cute.make_layout (%sh_in10, %l10_stride) : (!cute.shape<"(?,5)">, !cute.stride<"(1,?)">) -> !cute.layout<"(?,5):(1,?)">
        %sel1 = cute.select<[0]> (%l10)
            : !cute.layout<"(?,5):(1,?)"> -> !cute.layout<"(?):(1)">
        cute.print(%sel1) : !cute.layout<"(?):(1)">

        // to_int_tuple — strip the shape wrapper.
        %x71 = arith.constant 71 : i32
        %s_it = cute.make_shape (%x71) : (i32) -> !cute.shape<"(?,73)">
        %it1 = cute.to_int_tuple(%s_it)
            : !cute.shape<"(?,73)"> -> !cute.int_tuple<"(?,73)">
        cute.print(%it1) : !cute.int_tuple<"(?,73)">

        // get_shape on composed_layout — shape_leaf=89, stride_leaf=89.
        %x89 = arith.constant 89 : i32
        %sh_cb = cute.make_shape (%x89) : (i32) -> !cute.shape<"(?,97)">
        %st_cb = cute.make_stride (%x89) : (i32) -> !cute.stride<"(1,?)">
        %outer_cb = cute.make_layout (%sh_cb, %st_cb)
            : (!cute.shape<"(?,97)">, !cute.stride<"(1,?)">) -> !cute.layout<"(?,97):(1,?)">
        %sw_cb = cute.static : !cute.swizzle<"S<3,4,3>">
        %off_cb = cute.static : !cute.int_tuple<"0">
        %cl_cb = cute.make_composed_layout (%sw_cb, %off_cb, %outer_cb)
            : (!cute.swizzle<"S<3,4,3>">, !cute.int_tuple<"0">, !cute.layout<"(?,97):(1,?)">)
           -> !cute.composed_layout<"S<3,4,3> o 0 o (?,97):(1,?)">
        %csh = cute.get_shape(%cl_cb)
            : !cute.composed_layout<"S<3,4,3> o 0 o (?,97):(1,?)"> -> !cute.shape<"(?,97)">
        cute.print(%csh) : !cute.shape<"(?,97)">

        // get_stride on layout with dyn-scale basis stride — shape_leaf=101,
        // scale_leaf=109.
        %x101 = arith.constant 101 : i32
        %x109 = arith.constant 109 : i32
        %sh_b = cute.make_shape (%x101) : (i32) -> !cute.shape<"(?,103)">
        %st_b = cute.make_stride (%x109) : (i32) -> !cute.stride<"(?@0,1@1)">
        %l_b = cute.make_layout (%sh_b, %st_b)
            : (!cute.shape<"(?,103)">, !cute.stride<"(?@0,1@1)">)
           -> !cute.layout<"(?,103):(?@0,1@1)">
        %bst = cute.get_stride(%l_b)
            : !cute.layout<"(?,103):(?@0,1@1)"> -> !cute.stride<"(?@0,1@1)">
        cute.print(%bst) : !cute.stride<"(?@0,1@1)">

        // composed_get_inner on swizzle-A — swizzle always static.
        %cl_sw = cute.static : !cute.composed_layout<"S<2,3,5> o 0 o (2,3):(1,2)">
        %sw = cute.composed_get_inner(%cl_sw)
            : !cute.composed_layout<"S<2,3,5> o 0 o (2,3):(1,2)"> -> !cute.swizzle<"S<2,3,5>">
        cute.print(%sw) : !cute.swizzle<"S<2,3,5>">

        // composed_get_offset with dyn scalar offset = 113.
        %x113 = arith.constant 113 : i32
        %inner_v2 = cute.static : !cute.layout<"(2,3):(1,2)">
        %off_v2 = cute.make_int_tuple(%x113) : (i32) -> !cute.int_tuple<"?">
        %outer_v2 = cute.static : !cute.layout<"(4,5):(1,4)">
        %cl_v2 = cute.make_composed_layout(%inner_v2, %off_v2, %outer_v2)
            : (!cute.layout<"(2,3):(1,2)">, !cute.int_tuple<"?">, !cute.layout<"(4,5):(1,4)">)
           -> !cute.composed_layout<"(2,3):(1,2) o ? o (4,5):(1,4)">
        %ofv = cute.composed_get_offset(%cl_v2)
            : !cute.composed_layout<"(2,3):(1,2) o ? o (4,5):(1,4)"> -> !cute.int_tuple<"?">
        cute.print(%ofv) : !cute.int_tuple<"?">

        // composed_get_outer with dyn outer B — shape_leaf=127, stride_leaf=127.
        %x127 = arith.constant 127 : i32
        %inner_v3 = cute.static : !cute.layout<"(2,3):(1,2)">
        %off_v3 = cute.static : !cute.int_tuple<"0">
        %sh_v3 = cute.make_shape(%x127) : (i32) -> !cute.shape<"(?,131)">
        %st_v3 = cute.make_stride(%x127) : (i32) -> !cute.stride<"(1,?)">
        %outer_v3 = cute.make_layout(%sh_v3, %st_v3)
            : (!cute.shape<"(?,131)">, !cute.stride<"(1,?)">) -> !cute.layout<"(?,131):(1,?)">
        %cl_v3 = cute.make_composed_layout(%inner_v3, %off_v3, %outer_v3)
            : (!cute.layout<"(2,3):(1,2)">, !cute.int_tuple<"0">, !cute.layout<"(?,131):(1,?)">)
           -> !cute.composed_layout<"(2,3):(1,2) o 0 o (?,131):(1,?)">
        %outv = cute.composed_get_outer(%cl_v3)
            : !cute.composed_layout<"(2,3):(1,2) o 0 o (?,131):(1,?)"> -> !cute.layout<"(?,131):(1,?)">
        cute.print(%outv) : !cute.layout<"(?,131):(1,?)">

        // select<[2, 0]> permutation on a fully-dyn rank-3 layout.
        // shape leaves = (137, 139, 149); compact strides = (1, 137,
        // 137*139 = 19043). Select picks modes 2 and 0, yielding
        // shape (149, 137) and strides (19043, 1).
        %x137 = arith.constant 137 : i32
        %x139 = arith.constant 139 : i32
        %x149 = arith.constant 149 : i32
        %sh_perm = cute.make_shape(%x137, %x139, %x149)
                 : (i32, i32, i32) -> !cute.shape<"(?,?,?)">
        %l_perm_stride_mul = arith.muli %x137, %x139 : i32
        %l_perm_stride = cute.make_stride (%x137, %l_perm_stride_mul) : (i32, i32) -> !cute.stride<"(1,?,?)">
        %l_perm = cute.make_layout (%sh_perm, %l_perm_stride) : (!cute.shape<"(?,?,?)">, !cute.stride<"(1,?,?)">) -> !cute.layout<"(?,?,?):(1,?,?)">
        %sel_perm = cute.select<[2, 0]> (%l_perm)
                  : !cute.layout<"(?,?,?):(1,?,?)"> -> !cute.layout<"(?,?):(?,1)">
        cute.print(%sel_perm) : !cute.layout<"(?,?):(?,1)">

        // select<[]> on a dyn shape — empty mode produces rank-0 result.
        %x151 = arith.constant 151 : i32
        %x157 = arith.constant 157 : i32
        %sh_empty = cute.make_shape(%x151, %x157)
                  : (i32, i32) -> !cute.shape<"(?,?)">
        %sel_empty = cute.select<[]> (%sh_empty)
                   : !cute.shape<"(?,?)"> -> !cute.shape<"()">
        cute.print(%sel_empty) : !cute.shape<"()">

        // to_int_tuple from a stride with a dyn leaf — values flow
        // through, `?` filled with 239 at runtime.
        %x239 = arith.constant 239 : i32
        %st_dyn = cute.make_stride(%x239) : (i32) -> !cute.stride<"(1,?)">
        %it_st_dyn = cute.to_int_tuple(%st_dyn)
                   : !cute.stride<"(1,?)"> -> !cute.int_tuple<"(1,?)">
        cute.print(%it_st_dyn) : !cute.int_tuple<"(1,?)">

        // get_layouts_from_tile on a multi-layout dyn tile. Tile is
        // `[(?,3):(1,?); (5,?):(1,5)]`: 3 dyn leaves total (shape[0],
        // stride[1], shape[1] across the two layouts), filled with
        // 251, 257, 269 in DFS order.
        %x251 = arith.constant 251 : i32
        %x257 = arith.constant 257 : i32
        %x269 = arith.constant 269 : i32
        %t_multi = cute.make_tile(%x251, %x257, %x269)
                 : (i32, i32, i32) -> !cute.tile<"[(?,3):(1,?);(5,?):(1,5)]">
        %lm0, %lm1 = cute.get_layouts_from_tile(%t_multi)
                   : !cute.tile<"[(?,3):(1,?);(5,?):(1,5)]">
        cute.print(%lm0) : !cute.layout<"(?,3):(1,?)">
        cute.print(%lm1) : !cute.layout<"(5,?):(1,5)">
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
