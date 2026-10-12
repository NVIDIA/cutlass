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
// All-static Accessors kernel; ops inline in gpu.func.

// CHECK: (2,7)
// CHECK: (2,9)
// CHECK: 11:1
// CHECK: 17
// CHECK: 19
// CHECK: 23
// CHECK: (29,31):(1,29)
// CHECK: (37,41):(1,37)
// CHECK: (43,47):(1,43)
// CHECK: 53
// CHECK: (2,4):(1,2)
// CHECK: (61):(59)
// CHECK: (71,73)
// CHECK: (89,97)
// CHECK: (109@0,1@1)
// CHECK: S<2,3,5>
// CHECK: 113
// CHECK: (127,131):(1,127)
// CHECK: (151,139):(20711,1)
// CHECK: [_;(167,173):(1,167)]
// CHECK: (179,181):(1,179) o 0 o (193,191):(191,1)
// CHECK: (199,197):(1@1,1@0)
// CHECK: ()
// CHECK: (229,229)
// CHECK: (239,241)
// CHECK: (251,257)
// CHECK: (263,269)
// CHECK: (271,(277,281),283)
// CHECK: (293,307):(1,293)
// CHECK: 311:1
// CHECK: 313:1
// CHECK: 317:1
// CHECK: 331:1

module attributes {gpu.container_module} {
  gpu.module @kernel {
    gpu.func @print_all() kernel {
      %tx = gpu.thread_id x
      %c0 = arith.constant 0 : index
      %is_zero = arith.cmpi eq, %tx, %c0 : index
      scf.if %is_zero {
        // get_shape — extract the shape mode of a layout.
        %l_sh = cute.static : !cute.layout<"(2,7):(1,2)">
        %sh = cute.get_shape(%l_sh)
            : !cute.layout<"(2,7):(1,2)"> -> !cute.shape<"(2,7)">
        cute.print(%sh) : !cute.shape<"(2,7)">

        // get_stride — extract the stride mode of a layout.
        %l_st = cute.static : !cute.layout<"(3,5):(2,9)">
        %st = cute.get_stride(%l_st)
            : !cute.layout<"(3,5):(2,9)"> -> !cute.stride<"(2,9)">
        cute.print(%st) : !cute.stride<"(2,9)">

        // get<[mode]> — pick a single mode from a layout (here mode 0).
        %l_g = cute.static : !cute.layout<"(11,13):(1,11)">
        %g = cute.get<[0]> (%l_g)
           : !cute.layout<"(11,13):(1,11)"> -> !cute.layout<"11:1">
        cute.print(%g) : !cute.layout<"11:1">

        // get_leaves — flatten a nested shape to its three leaf shapes.
        %s_lv = cute.static : !cute.shape<"(17,(19,23))">
        %a, %b, %c = cute.get_leaves(%s_lv) : !cute.shape<"(17,(19,23))">
        cute.print(%a) : !cute.shape<"17">
        cute.print(%b) : !cute.shape<"19">
        cute.print(%c) : !cute.shape<"23">

        // get_layouts_from_tile — split a multi-layout tile.
        %t = cute.static : !cute.tile<"[(29,31):(1,29);(37,41):(1,37)]">
        %la, %lb = cute.get_layouts_from_tile(%t)
                 : !cute.tile<"[(29,31):(1,29);(37,41):(1,37)]">
        cute.print(%la) : !cute.layout<"(29,31):(1,29)">
        cute.print(%lb) : !cute.layout<"(37,41):(1,37)">

        // composed_get_inner / offset / outer.
        %cl = cute.static : !cute.composed_layout<"(43,47):(1,43) o 53 o (2,4):(1,2)">
        %in = cute.composed_get_inner(%cl)
            : !cute.composed_layout<"(43,47):(1,43) o 53 o (2,4):(1,2)">
           -> !cute.layout<"(43,47):(1,43)">
        cute.print(%in) : !cute.layout<"(43,47):(1,43)">

        %off = cute.composed_get_offset(%cl)
             : !cute.composed_layout<"(43,47):(1,43) o 53 o (2,4):(1,2)">
            -> !cute.int_tuple<"53">
        cute.print(%off) : !cute.int_tuple<"53">

        %out = cute.composed_get_outer(%cl)
             : !cute.composed_layout<"(43,47):(1,43) o 53 o (2,4):(1,2)">
            -> !cute.layout<"(2,4):(1,2)">
        cute.print(%out) : !cute.layout<"(2,4):(1,2)">

        // select<[mode]> — pick a single mode from a multi-mode layout.
        %l_sel = cute.static : !cute.layout<"(59,61,67):(1,59,3599)">
        %sel = cute.select<[1]> (%l_sel)
             : !cute.layout<"(59,61,67):(1,59,3599)">
            -> !cute.layout<"(61):(59)">
        cute.print(%sel) : !cute.layout<"(61):(59)">

        // to_int_tuple — strip the `shape`/`stride`/`coord` wrapper.
        %s_it = cute.static : !cute.shape<"(71,73)">
        %it = cute.to_int_tuple(%s_it)
            : !cute.shape<"(71,73)"> -> !cute.int_tuple<"(71,73)">
        cute.print(%it) : !cute.int_tuple<"(71,73)">

        // get_shape on a composed_layout — outer B's shape.
        %cl2 = cute.static : !cute.composed_layout<"S<3,4,3> o 0 o (89,97):(1,89)">
        %csh = cute.get_shape(%cl2)
             : !cute.composed_layout<"S<3,4,3> o 0 o (89,97):(1,89)"> -> !cute.shape<"(89,97)">
        cute.print(%csh) : !cute.shape<"(89,97)">

        // get_stride on a layout with scaled-basis strides.
        %l_b = cute.static : !cute.layout<"(101,103):(109@0,1@1)">
        %bst = cute.get_stride(%l_b)
             : !cute.layout<"(101,103):(109@0,1@1)"> -> !cute.stride<"(109@0,1@1)">
        cute.print(%bst) : !cute.stride<"(109@0,1@1)">

        // composed_get_inner on swizzle-A — swizzle output is always static.
        %cl_sw = cute.static : !cute.composed_layout<"S<2,3,5> o 0 o (2,3):(1,2)">
        %sw = cute.composed_get_inner(%cl_sw)
            : !cute.composed_layout<"S<2,3,5> o 0 o (2,3):(1,2)"> -> !cute.swizzle<"S<2,3,5>">
        cute.print(%sw) : !cute.swizzle<"S<2,3,5>">

        // composed_get_offset with offset literal 113.
        %cl_off = cute.static : !cute.composed_layout<"(2,3):(1,2) o 113 o (4,5):(1,4)">
        %ofv = cute.composed_get_offset(%cl_off)
             : !cute.composed_layout<"(2,3):(1,2) o 113 o (4,5):(1,4)"> -> !cute.int_tuple<"113">
        cute.print(%ofv) : !cute.int_tuple<"113">

        // composed_get_outer with static outer (127,131):(1,127).
        %cl_out = cute.static : !cute.composed_layout<"(2,3):(1,2) o 0 o (127,131):(1,127)">
        %outv = cute.composed_get_outer(%cl_out)
             : !cute.composed_layout<"(2,3):(1,2) o 0 o (127,131):(1,127)"> -> !cute.layout<"(127,131):(1,127)">
        cute.print(%outv) : !cute.layout<"(127,131):(1,127)">

        // select<[2, 0]> — permutation on a rank-3 layout.
        %l_sel_perm = cute.static : !cute.layout<"(139,149,151):(1,139,20711)">
        %sel_perm = cute.select<[2, 0]> (%l_sel_perm)
                  : !cute.layout<"(139,149,151):(1,139,20711)">
                 -> !cute.layout<"(151,139):(20711,1)">
        cute.print(%sel_perm) : !cute.layout<"(151,139):(20711,1)">

        // select<[1, 2]> on a tile — picks an underscore slot and a
        // layout slot; the underscore is copied as-is.
        %t_sel = cute.static : !cute.tile<"[(157,163):(1,157);_;(167,173):(1,167)]">
        %sel_tile = cute.select<[1, 2]> (%t_sel)
                  : !cute.tile<"[(157,163):(1,157);_;(167,173):(1,167)]">
                 -> !cute.tile<"[_;(167,173):(1,167)]">
        cute.print(%sel_tile) : !cute.tile<"[_;(167,173):(1,167)]">

        // select<[1, 0]> on a composed_layout — applies to outer B
        // (permutation), inner + offset preserved.
        %cl_sel = cute.static : !cute.composed_layout<"(179,181):(1,179) o 0 o (191,193):(1,191)">
        %sel_cl = cute.select<[1, 0]> (%cl_sel)
                : !cute.composed_layout<"(179,181):(1,179) o 0 o (191,193):(1,191)">
               -> !cute.composed_layout<"(179,181):(1,179) o 0 o (193,191):(191,1)">
        cute.print(%sel_cl) : !cute.composed_layout<"(179,181):(1,179) o 0 o (193,191):(191,1)">

        // select<[1, 0]> on a scaled-basis layout — basis indices
        // follow the picked modes through the reorder.
        %l_sel_sb = cute.static : !cute.layout<"(197,199):(1@0,1@1)">
        %sel_sb = cute.select<[1, 0]> (%l_sel_sb)
                : !cute.layout<"(197,199):(1@0,1@1)">
               -> !cute.layout<"(199,197):(1@1,1@0)">
        cute.print(%sel_sb) : !cute.layout<"(199,197):(1@1,1@0)">

        // select<[]> — empty mode produces a rank-0 result.
        %s_sel_empty = cute.static : !cute.shape<"(211,223)">
        %sel_empty = cute.select<[]> (%s_sel_empty)
                   : !cute.shape<"(211,223)"> -> !cute.shape<"()">
        cute.print(%sel_empty) : !cute.shape<"()">

        // select<[1, 1]> on an int_tuple — repeated index duplicates
        // the picked mode.
        %i_sel_rep = cute.static : !cute.int_tuple<"(227,229,233)">
        %sel_rep = cute.select<[1, 1]> (%i_sel_rep)
                 : !cute.int_tuple<"(227,229,233)"> -> !cute.int_tuple<"(229,229)">
        cute.print(%sel_rep) : !cute.int_tuple<"(229,229)">

        // to_int_tuple — identity case (int_tuple -> int_tuple).
        %it_id_in = cute.static : !cute.int_tuple<"(239,241)">
        %it_id = cute.to_int_tuple(%it_id_in)
               : !cute.int_tuple<"(239,241)"> -> !cute.int_tuple<"(239,241)">
        cute.print(%it_id) : !cute.int_tuple<"(239,241)">

        // to_int_tuple — from stride.
        %it_st_in = cute.static : !cute.stride<"(251,257)">
        %it_st = cute.to_int_tuple(%it_st_in)
               : !cute.stride<"(251,257)"> -> !cute.int_tuple<"(251,257)">
        cute.print(%it_st) : !cute.int_tuple<"(251,257)">

        // to_int_tuple — from coord.
        %it_c_in = cute.static : !cute.coord<"(263,269)">
        %it_c = cute.to_int_tuple(%it_c_in)
              : !cute.coord<"(263,269)"> -> !cute.int_tuple<"(263,269)">
        cute.print(%it_c) : !cute.int_tuple<"(263,269)">

        // to_int_tuple — from a nested shape; hierarchical structure
        // preserved.
        %it_n_in = cute.static : !cute.shape<"(271,(277,281),283)">
        %it_n = cute.to_int_tuple(%it_n_in)
              : !cute.shape<"(271,(277,281),283)">
             -> !cute.int_tuple<"(271,(277,281),283)">
        cute.print(%it_n) : !cute.int_tuple<"(271,(277,281),283)">

        // get_layouts_from_tile — layout + underscore slot; the
        // underscore is silently skipped, only the layout slot is
        // returned.
        %t_us = cute.static : !cute.tile<"[(293,307):(1,293);_]">
        %lu = cute.get_layouts_from_tile(%t_us)
            : !cute.tile<"[(293,307):(1,293);_]">
        cute.print(%lu) : !cute.layout<"(293,307):(1,293)">

        // get_layouts_from_tile — nested tile (tile of tiles). DFS
        // flatten yields all four layout leaves in left-to-right
        // order.
        %t_nested = cute.static : !cute.tile<"[311:1;[313:1;317:1];331:1]">
        %ln0, %ln1, %ln2, %ln3 = cute.get_layouts_from_tile(%t_nested)
                               : !cute.tile<"[311:1;[313:1;317:1];331:1]">
        cute.print(%ln0) : !cute.layout<"311:1">
        cute.print(%ln1) : !cute.layout<"313:1">
        cute.print(%ln2) : !cute.layout<"317:1">
        cute.print(%ln3) : !cute.layout<"331:1">
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
