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

// RUN: cute-opt -cute-expand-ops --split-input-file %s | FileCheck %s

// Tests `cute-expand-ops` lowering for `cute.dice`.

// -----

// CHECK-LABEL: func.func @expand_static
// CHECK-NOT:   cute.dice
// CHECK:       cute.static : !cute.layout<"(3):(2)">
func.func @expand_static(%src: !cute.layout<"(2,3,4):(1,2,6)">,
                          %crd: !cute.coord<"(_,1,_)">)
    -> !cute.layout<"(3):(2)"> {
  %r = cute.dice(%src, %crd)
         : !cute.layout<"(2,3,4):(1,2,6)">, !cute.coord<"(_,1,_)">
  return %r : !cute.layout<"(3):(2)">
}

// -----

// Layout dynamic: dice keeps the integer-marked mode (which is dynamic
// here), so the result rebuilds via make_layout.
// CHECK-LABEL: func.func @expand_layout_dynamic
// CHECK-NOT:   cute.dice
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_layout
// CHECK-SAME:  -> !cute.layout<"(?):(?)">
func.func @expand_layout_dynamic(%src: !cute.layout<"(2,?,4):(1,?,?)">,
                                  %crd: !cute.coord<"(_,1,_)">)
    -> !cute.layout<"(?):(?)"> {
  %r = cute.dice(%src, %crd)
         : !cute.layout<"(2,?,4):(1,?,?)">, !cute.coord<"(_,1,_)">
  return %r : !cute.layout<"(?):(?)">
}

// -----

// Composed layout — wrap preserved.
// CHECK-LABEL: func.func @expand_composed_layout_dynamic
// CHECK-NOT:   cute.dice
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_composed_layout
// CHECK-SAME:  -> <"S<3,5,4> o 0 o (?):(?)">
func.func @expand_composed_layout_dynamic(
    %src: !cute.composed_layout<"S<3,5,4> o 0 o (2,?,4):(1,?,?)">,
    %crd: !cute.coord<"(_,1,_)">)
    -> !cute.composed_layout<"S<3,5,4> o 0 o (?):(?)"> {
  %r = cute.dice(%src, %crd)
         : !cute.composed_layout<"S<3,5,4> o 0 o (2,?,4):(1,?,?)">,
           !cute.coord<"(_,1,_)">
  return %r : !cute.composed_layout<"S<3,5,4> o 0 o (?):(?)">
}

// -----

// Shape input with a dynamic leaf in the kept mode — rebuilds via
// `cute.make_shape`.
// CHECK-LABEL: func.func @expand_shape_dynamic
// CHECK-NOT:   cute.dice
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_shape
// CHECK-SAME:  -> !cute.shape<"(?)">
func.func @expand_shape_dynamic(%src: !cute.shape<"(2,?,4)">,
                                 %crd: !cute.coord<"(_,1,_)">)
    -> !cute.shape<"(?)"> {
  %r = cute.dice(%src, %crd) : !cute.shape<"(2,?,4)">, !cute.coord<"(_,1,_)">
  return %r : !cute.shape<"(?)">
}

// -----

// Stride input — rebuilds via `cute.make_stride`.
// CHECK-LABEL: func.func @expand_stride_dynamic
// CHECK-NOT:   cute.dice
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_stride
// CHECK-SAME:  -> !cute.stride<"(?)">
func.func @expand_stride_dynamic(%src: !cute.stride<"(2,?,4)">,
                                  %crd: !cute.coord<"(_,1,_)">)
    -> !cute.stride<"(?)"> {
  %r = cute.dice(%src, %crd) : !cute.stride<"(2,?,4)">, !cute.coord<"(_,1,_)">
  return %r : !cute.stride<"(?)">
}

// -----

// IntTuple input — rebuilds via `cute.make_int_tuple`.
// CHECK-LABEL: func.func @expand_int_tuple_dynamic
// CHECK-NOT:   cute.dice
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_int_tuple
// CHECK-SAME:  -> !cute.int_tuple<"(?)">
func.func @expand_int_tuple_dynamic(%src: !cute.int_tuple<"(2,?,4)">,
                                     %crd: !cute.coord<"(_,1,_)">)
    -> !cute.int_tuple<"(?)"> {
  %r = cute.dice(%src, %crd) : !cute.int_tuple<"(2,?,4)">, !cute.coord<"(_,1,_)">
  return %r : !cute.int_tuple<"(?)">
}

// -----

// Coord input — dice on a coord with one dynamic mode; rebuilds via
// `cute.make_coord`.
// CHECK-LABEL: func.func @expand_coord_dynamic
// CHECK-NOT:   cute.dice
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_coord
// CHECK-SAME:  -> !cute.coord<"(?)">
func.func @expand_coord_dynamic(%src: !cute.coord<"(2,?,4)">,
                                 %crd: !cute.coord<"(_,1,_)">)
    -> !cute.coord<"(?)"> {
  %r = cute.dice(%src, %crd) : !cute.coord<"(2,?,4)">, !cute.coord<"(_,1,_)">
  return %r : !cute.coord<"(?)">
}

// -----

// Affine-A composed dice keeping dynamic B modes.
// CHECK-LABEL: func.func @expand_composed_affine_dyn_outer_keep_dyn
// CHECK-NOT:   cute.dice
// CHECK:       %[[DYN:.+]]:3 = cute.get_scalars<{only_dynamic}>
// CHECK:       %[[SH:.+]] = cute.make_shape(%[[DYN]]#0) : (i32) -> !cute.shape<"(?,3)">
// CHECK:       %[[ST:.+]] = cute.make_stride(%[[DYN]]#1) : (i32) -> !cute.stride<"(?,4)">
// CHECK:       %[[B:.+]] = cute.make_layout(%[[SH]], %[[ST]])
// CHECK-SAME:  -> !cute.layout<"(?,3):(?,4)">
// CHECK:       %[[OFF:.+]] = cute.make_int_tuple() : () -> !cute.int_tuple<"2">
// CHECK:       %[[A:.+]] = cute.static : !cute.layout<"(4,5):(1,4)">
// CHECK:       cute.make_composed_layout(%[[A]], %[[OFF]], %[[B]])
// CHECK-SAME:  -> <"(4,5):(1,4) o 2 o (?,3):(?,4)">
func.func @expand_composed_affine_dyn_outer_keep_dyn(
    %src: !cute.composed_layout<"(4,5):(1,4) o 2 o (?,3,4):(?,4,?)">,
    %crd: !cute.coord<"(1,1,_)">)
    -> !cute.composed_layout<"(4,5):(1,4) o 2 o (?,3):(?,4)"> {
  %r = cute.dice(%src, %crd)
         : !cute.composed_layout<"(4,5):(1,4) o 2 o (?,3,4):(?,4,?)">,
           !cute.coord<"(1,1,_)">
  return %r : !cute.composed_layout<"(4,5):(1,4) o 2 o (?,3):(?,4)">
}

// -----

// Nested layout with scaled-basis stride and dynamic shape — sub-mode kept whole.
// CHECK-LABEL: func.func @expand_nested_scaled_basis_dyn_shape
// CHECK-NOT:   cute.dice
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_shape(%{{.+}}) : (i32) -> !cute.shape<"((?,3))">
// CHECK:       cute.make_stride() : () -> !cute.stride<"((1@0,1@1))">
// CHECK:       cute.make_layout
// CHECK-SAME:  -> !cute.layout<"((?,3)):((1@0,1@1))">
func.func @expand_nested_scaled_basis_dyn_shape(
    %src: !cute.layout<"((?,3),4):((1@0,1@1),1@2)">,
    %crd: !cute.coord<"(1,_)">) -> !cute.layout<"((?,3)):((1@0,1@1))"> {
  %r = cute.dice(%src, %crd)
         : !cute.layout<"((?,3),4):((1@0,1@1),1@2)">, !cute.coord<"(1,_)">
  return %r : !cute.layout<"((?,3)):((1@0,1@1))">
}

// -----

// Composed affine with scaled-basis B and dynamic shape leaf.
// CHECK-LABEL: func.func @expand_composed_scaled_basis_b_preserve_offset
// CHECK-NOT:   cute.dice
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_shape(%{{.+}}) : (i32) -> !cute.shape<"(?)">
// CHECK:       cute.make_stride() : () -> !cute.stride<"(1@0)">
// CHECK:       %[[B:.+]] = cute.make_layout(%{{.+}}, %{{.+}}) {{.*}}-> !cute.layout<"(?):(1@0)">
// CHECK:       %[[OFF:.+]] = cute.make_int_tuple() : () -> !cute.int_tuple<"(0,0)">
// CHECK:       %[[A:.+]] = cute.static : !cute.layout<"(4,5):(1,4)">
// CHECK:       cute.make_composed_layout(%[[A]], %[[OFF]], %[[B]])
// CHECK-SAME:  -> <"(4,5):(1,4) o (0,0) o (?):(1@0)">
func.func @expand_composed_scaled_basis_b_preserve_offset(
    %src: !cute.composed_layout<"(4,5):(1,4) o (0,0) o (?,3):(1@0,1@1)">,
    %crd: !cute.coord<"(1,_)">)
    -> !cute.composed_layout<"(4,5):(1,4) o (0,0) o (?):(1@0)"> {
  %r = cute.dice(%src, %crd)
         : !cute.composed_layout<"(4,5):(1,4) o (0,0) o (?,3):(1@0,1@1)">,
           !cute.coord<"(1,_)">
  return %r : !cute.composed_layout<"(4,5):(1,4) o (0,0) o (?):(1@0)">
}
