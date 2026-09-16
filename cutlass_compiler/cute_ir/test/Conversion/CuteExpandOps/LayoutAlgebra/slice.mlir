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

// Tests `cute-expand-ops` lowering for `cute.slice`.

// -----

// CHECK-LABEL: func.func @expand_static
// CHECK-NOT:   cute.slice
// CHECK:       cute.static : !cute.layout<"(3):(2)">
func.func @expand_static(%src: !cute.layout<"(2,3,4):(1,2,6)">,
                          %crd: !cute.coord<"(0,_,1)">)
    -> !cute.layout<"(3):(2)"> {
  %r = cute.slice(%src, %crd)
         : !cute.layout<"(2,3,4):(1,2,6)">, !cute.coord<"(0,_,1)">
  return %r : !cute.layout<"(3):(2)">
}

// -----

// CHECK-LABEL: func.func @expand_layout_dynamic
// CHECK-NOT:   cute.slice
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_layout
// CHECK-SAME:  -> !cute.layout<"(?,4):(?,?)">
func.func @expand_layout_dynamic(%src: !cute.layout<"(2,?,4):(1,?,?)">,
                                  %crd: !cute.coord<"(0,_,_)">)
    -> !cute.layout<"(?,4):(?,?)"> {
  %r = cute.slice(%src, %crd)
         : !cute.layout<"(2,?,4):(1,?,?)">, !cute.coord<"(0,_,_)">
  return %r : !cute.layout<"(?,4):(?,?)">
}

// -----

// Composed layout: slicing the dynamic mode leaves only static content, folding to cute.static.
// CHECK-LABEL: func.func @expand_composed_layout_dynamic_to_static
// CHECK-NOT:   cute.slice
// CHECK:       cute.static : !cute.composed_layout<"(4,5):(1,4) o 2 o (3):(4)">
func.func @expand_composed_layout_dynamic_to_static(
    %src: !cute.composed_layout<"(4,5):(1,4) o 2 o (?,3):(?,4)">,
    %crd: !cute.coord<"(0,_)">)
    -> !cute.composed_layout<"(4,5):(1,4) o 2 o (3):(4)"> {
  %r = cute.slice(%src, %crd)
         : !cute.composed_layout<"(4,5):(1,4) o 2 o (?,3):(?,4)">,
           !cute.coord<"(0,_)">
  return %r : !cute.composed_layout<"(4,5):(1,4) o 2 o (3):(4)">
}

// -----

// Composed layout with dynamic result — slicing a dynamic-stride mode makes the offset dynamic.
// CHECK-LABEL: func.func @expand_composed_layout_keeps_dynamic
// CHECK-NOT:   cute.slice
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_composed_layout
// CHECK-SAME:  -> <"(4,5):(1,4) o ? o (?,3):(?,4)">
func.func @expand_composed_layout_keeps_dynamic(
    %src: !cute.composed_layout<"(4,5):(1,4) o 2 o (?,3,4):(?,4,?)">,
    %crd: !cute.coord<"(_,_,1)">)
    -> !cute.composed_layout<"(4,5):(1,4) o ? o (?,3):(?,4)"> {
  %r = cute.slice(%src, %crd)
         : !cute.composed_layout<"(4,5):(1,4) o 2 o (?,3,4):(?,4,?)">,
           !cute.coord<"(_,_,1)">
  return %r : !cute.composed_layout<"(4,5):(1,4) o ? o (?,3):(?,4)">
}

// -----

// Shape input with a dynamic leaf preserved — slice rebuilds via
// `cute.make_shape` consuming only the kept dynamic leaf.
// CHECK-LABEL: func.func @expand_shape_dynamic
// CHECK-NOT:   cute.slice
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_shape
// CHECK-SAME:  -> !cute.shape<"(?,3)">
func.func @expand_shape_dynamic(%src: !cute.shape<"(?,2,3)">,
                                 %crd: !cute.coord<"(_,1,_)">)
    -> !cute.shape<"(?,3)"> {
  %r = cute.slice(%src, %crd) : !cute.shape<"(?,2,3)">, !cute.coord<"(_,1,_)">
  return %r : !cute.shape<"(?,3)">
}

// -----

// Stride input with a dynamic leaf preserved — rebuilds via
// `cute.make_stride`.
// CHECK-LABEL: func.func @expand_stride_dynamic
// CHECK-NOT:   cute.slice
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_stride
// CHECK-SAME:  -> !cute.stride<"(?,4)">
func.func @expand_stride_dynamic(%src: !cute.stride<"(?,2,4)">,
                                  %crd: !cute.coord<"(_,0,_)">)
    -> !cute.stride<"(?,4)"> {
  %r = cute.slice(%src, %crd) : !cute.stride<"(?,2,4)">, !cute.coord<"(_,0,_)">
  return %r : !cute.stride<"(?,4)">
}

// -----

// IntTuple input — same pattern, rebuilds via `cute.make_int_tuple`.
// CHECK-LABEL: func.func @expand_int_tuple_dynamic
// CHECK-NOT:   cute.slice
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_int_tuple
// CHECK-SAME:  -> !cute.int_tuple<"(?,3)">
func.func @expand_int_tuple_dynamic(%src: !cute.int_tuple<"(?,2,3)">,
                                     %crd: !cute.coord<"(_,1,_)">)
    -> !cute.int_tuple<"(?,3)"> {
  %r = cute.slice(%src, %crd) : !cute.int_tuple<"(?,2,3)">, !cute.coord<"(_,1,_)">
  return %r : !cute.int_tuple<"(?,3)">
}

// -----

// Coord input — slice on a coord with one dynamic mode; rebuilds via
// `cute.make_coord`.
// CHECK-LABEL: func.func @expand_coord_dynamic
// CHECK-NOT:   cute.slice
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_coord
// CHECK-SAME:  -> !cute.coord<"(?,3)">
func.func @expand_coord_dynamic(%src: !cute.coord<"(?,2,3)">,
                                 %crd: !cute.coord<"(_,1,_)">)
    -> !cute.coord<"(?,3)"> {
  %r = cute.slice(%src, %crd) : !cute.coord<"(?,2,3)">, !cute.coord<"(_,1,_)">
  return %r : !cute.coord<"(?,3)">
}

// -----

// Affine-A composed slice with dynamic coord — dynamic coord contributes to offset.
// CHECK-LABEL: func.func @expand_composed_affine_offset_increase
// CHECK-NOT:   cute.slice
// CHECK:       %[[CRD_DYN:.+]] = cute.get_scalars<{only_dynamic}>
// CHECK-DAG:   %[[C2:.+]] = arith.constant 2 : i32
// CHECK:       %[[OFF:.+]] = arith.addi %[[C2]], %[[CRD_DYN]]
// CHECK:       %[[B:.+]] = cute.static : !cute.layout<"(3):(8)">
// CHECK:       %[[OFF_T:.+]] = cute.make_int_tuple(%[[OFF]]) : (i32) -> !cute.int_tuple<"?">
// CHECK:       %[[A:.+]] = cute.static : !cute.layout<"(4,5):(1,4)">
// CHECK:       cute.make_composed_layout(%[[A]], %[[OFF_T]], %[[B]])
// CHECK-SAME:  -> <"(4,5):(1,4) o ? o (3):(8)">
func.func @expand_composed_affine_offset_increase(
    %src: !cute.composed_layout<"(4,5):(1,4) o 2 o (8,3):(1,8)">,
    %crd: !cute.coord<"(?,_)">)
    -> !cute.composed_layout<"(4,5):(1,4) o ? o (3):(8)"> {
  %r = cute.slice(%src, %crd)
         : !cute.composed_layout<"(4,5):(1,4) o 2 o (8,3):(1,8)">,
           !cute.coord<"(?,_)">
  return %r : !cute.composed_layout<"(4,5):(1,4) o ? o (3):(8)">
}

// -----

// Swizzle-A composed slice with dynamic coord.
// CHECK-LABEL: func.func @expand_composed_swizzle_dyn_coord_folds_static
// CHECK-NOT:   cute.slice
// CHECK-NOT:   cute.get_scalars
// CHECK-NOT:   arith.addi
// CHECK-NOT:   cute.make_composed_layout
// CHECK:       cute.static : !cute.layout<"(4):(8)">
func.func @expand_composed_swizzle_dyn_coord_folds_static(
    %src: !cute.composed_layout<"S<3,5,4> o 0 o (8,4):(1,8)">,
    %crd: !cute.coord<"(?,_)">)
    -> !cute.layout<"(4):(8)"> {
  %r = cute.slice(%src, %crd)
         : !cute.composed_layout<"S<3,5,4> o 0 o (8,4):(1,8)">,
           !cute.coord<"(?,_)">
  return %r : !cute.layout<"(4):(8)">
}

// -----

// Swizzle composed slice decaying to affine.
// CHECK-LABEL: func.func @expand_swizzle_slice_dynamic_strides
// CHECK-NOT:   cute.slice
// CHECK:       cute.get_scalars<{only_dynamic}> (%{{.+}}) : !cute.coord<"(?,_)">
// CHECK:       cute.make_stride(%{{.+}}, %{{.+}}, %{{.+}}) :
// CHECK-SAME:  (i32,
// CHECK-SAME:  i32,
// CHECK-SAME:  i32)
// CHECK-SAME:  -> !cute.stride<"((0,(1,(?,?,?))))">
// CHECK:       cute.make_layout
// CHECK-SAME:  -> !cute.layout<"((1,(4,(2,2,2)))):((0,(1,(?,?,?))))">
func.func @expand_swizzle_slice_dynamic_strides(
    %src: !cute.composed_layout<"S<3,2,4> o 0 o ((1,(16,1)),(1,(4,8))):((0,(4,0)),(0,(1,64)))">,
    %crd: !cute.coord<"(?,_)">)
    -> !cute.layout<"((1,(4,(2,2,2)))):((0,(1,(?,?,?))))"> {
  %r = cute.slice(%src, %crd)
         : !cute.composed_layout<"S<3,2,4> o 0 o ((1,(16,1)),(1,(4,8))):((0,(4,0)),(0,(1,64)))">,
           !cute.coord<"(?,_)">
  return %r : !cute.layout<"((1,(4,(2,2,2)))):((0,(1,(?,?,?))))">
}

// -----

// Nested layout with scaled-basis strides.
// CHECK-LABEL: func.func @expand_nested_scaled_basis_dyn_shape
// CHECK-NOT:   cute.slice
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_shape(%{{.+}}) : (i32) -> !cute.shape<"((?,3))">
// CHECK:       cute.make_stride() : () -> !cute.stride<"((1@0,1@1))">
// CHECK:       cute.make_layout
// CHECK-SAME:  -> !cute.layout<"((?,3)):((1@0,1@1))">
func.func @expand_nested_scaled_basis_dyn_shape(
    %src: !cute.layout<"((?,3),4):((1@0,1@1),1@2)">,
    %crd: !cute.coord<"(_,1)">) -> !cute.layout<"((?,3)):((1@0,1@1))"> {
  %r = cute.slice(%src, %crd)
         : !cute.layout<"((?,3),4):((1@0,1@1),1@2)">, !cute.coord<"(_,1)">
  return %r : !cute.layout<"((?,3)):((1@0,1@1))">
}

// -----

// Composed affine with scaled-basis B and dynamic shape leaf.
// CHECK-LABEL: func.func @expand_composed_scaled_basis_b_offset_change
// CHECK-NOT:   cute.slice
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_shape(%{{.+}}) : (i32) -> !cute.shape<"(?)">
// CHECK:       cute.make_stride() : () -> !cute.stride<"(1@0)">
// CHECK:       %[[B:.+]] = cute.make_layout(%{{.+}}, %{{.+}}) {{.*}}-> !cute.layout<"(?):(1@0)">
// CHECK:       %[[OFF:.+]] = cute.make_int_tuple() : () -> !cute.int_tuple<"(0,1)">
// CHECK:       %[[A:.+]] = cute.static : !cute.layout<"(4,5):(1,4)">
// CHECK:       cute.make_composed_layout(%[[A]], %[[OFF]], %[[B]])
// CHECK-SAME:  -> <"(4,5):(1,4) o (0,1) o (?):(1@0)">
func.func @expand_composed_scaled_basis_b_offset_change(
    %src: !cute.composed_layout<"(4,5):(1,4) o (0,0) o (?,3):(1@0,1@1)">,
    %crd: !cute.coord<"(_,1)">)
    -> !cute.composed_layout<"(4,5):(1,4) o (0,1) o (?):(1@0)"> {
  %r = cute.slice(%src, %crd)
         : !cute.composed_layout<"(4,5):(1,4) o (0,0) o (?,3):(1@0,1@1)">,
           !cute.coord<"(_,1)">
  return %r : !cute.composed_layout<"(4,5):(1,4) o (0,1) o (?):(1@0)">
}
