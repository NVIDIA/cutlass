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

// RUN: cute-opt -cute-fold-static -cute-expand-ops --split-input-file %s | FileCheck %s --check-prefix=FOLD-FIRST
// RUN: cute-opt -cute-expand-ops -cute-fold-static --split-input-file %s | FileCheck %s --check-prefix=EXPAND-FIRST

// Pipeline `--cute-fold-static --cute-expand-ops` is idempotent —
// running fold-static first must not break expand-ops.
//
// One test per op, grouped by category. Each test asserts
// the op is gone and a key marker lands in both pass orderings:
//   - static-fold path: `cute.static` (cute-typed result) or
//     `arith.constant` (i1 result for elem_less/equal)
//   - dynamic expansion: `cute.get_scalars` + a `cute.make_*` constructor
//
// Coverage alternates static and dynamic flavors for variety; we don't
// exhaustively cover every operand-kind combination — see the per-op
// tests under each category subdirectory for that.

//===----------------------------------------------------------------------===//
// AdvancedConstructors
//===----------------------------------------------------------------------===//

// FOLD-FIRST-LABEL: func.func @fold_make_layout_like
// FOLD-FIRST-NOT:     cute.make_layout_like
// FOLD-FIRST:         cute.static
// EXPAND-FIRST-LABEL: func.func @fold_make_layout_like
// EXPAND-FIRST-NOT:     cute.make_layout_like
// EXPAND-FIRST:         cute.static
func.func @fold_make_layout_like(%a: !cute.layout<"(2,4):(4,1)">)
    -> !cute.layout<"(2,4):(4,1)"> {
  %r = cute.make_layout_like(%a)
         : !cute.layout<"(2,4):(4,1)"> -> !cute.layout<"(2,4):(4,1)">
  return %r : !cute.layout<"(2,4):(4,1)">
}

// -----

// FOLD-FIRST-LABEL: func.func @fold_make_ordered_layout
// FOLD-FIRST-NOT:     cute.make_ordered_layout
// FOLD-FIRST:         cute.static
// EXPAND-FIRST-LABEL: func.func @fold_make_ordered_layout
// EXPAND-FIRST-NOT:     cute.make_ordered_layout
// EXPAND-FIRST:         cute.static
func.func @fold_make_ordered_layout(%s: !cute.shape<"(2,3,4)">,
                                     %o: !cute.int_tuple<"(2,1,3)">)
    -> !cute.layout<"(2,3,4):(3,1,6)"> {
  %r = cute.make_ordered_layout(%s, %o)
         : (!cute.shape<"(2,3,4)">, !cute.int_tuple<"(2,1,3)">)
        -> !cute.layout<"(2,3,4):(3,1,6)">
  return %r : !cute.layout<"(2,3,4):(3,1,6)">
}

// -----

// FOLD-FIRST-LABEL: func.func @fold_make_identity_layout_dynamic
// FOLD-FIRST-NOT:     cute.make_identity_layout
// FOLD-FIRST:         cute.get_scalars<{only_dynamic}>
// FOLD-FIRST:         cute.make_layout
// EXPAND-FIRST-LABEL: func.func @fold_make_identity_layout_dynamic
// EXPAND-FIRST-NOT:     cute.make_identity_layout
// EXPAND-FIRST:         cute.get_scalars<{only_dynamic}>
// EXPAND-FIRST:         cute.make_layout
func.func @fold_make_identity_layout_dynamic(%s: !cute.shape<"(?,4)">)
    -> !cute.layout<"(?,4):(1@0,1@1)"> {
  %r = cute.make_identity_layout(%s)
         : !cute.shape<"(?,4)"> -> !cute.layout<"(?,4):(1@0,1@1)">
  return %r : !cute.layout<"(?,4):(1@0,1@1)">
}

//===----------------------------------------------------------------------===//
// Accessors
//===----------------------------------------------------------------------===//

// FOLD-FIRST-LABEL: func.func @fold_get_shape
// FOLD-FIRST-NOT:     cute.get_shape
// FOLD-FIRST:         cute.static
// EXPAND-FIRST-LABEL: func.func @fold_get_shape
// EXPAND-FIRST-NOT:     cute.get_shape
// EXPAND-FIRST:         cute.static
func.func @fold_get_shape(%a: !cute.layout<"(2,3):(1,2)">)
    -> !cute.shape<"(2,3)"> {
  %r = cute.get_shape(%a)
         : !cute.layout<"(2,3):(1,2)"> -> !cute.shape<"(2,3)">
  return %r : !cute.shape<"(2,3)">
}

// -----

// FOLD-FIRST-LABEL: func.func @fold_get_stride_dynamic
// FOLD-FIRST-NOT:     cute.get_stride
// FOLD-FIRST:         cute.get_scalars<{only_dynamic}>
// FOLD-FIRST:         cute.make_stride
// EXPAND-FIRST-LABEL: func.func @fold_get_stride_dynamic
// EXPAND-FIRST-NOT:     cute.get_stride
// EXPAND-FIRST:         cute.get_scalars<{only_dynamic}>
// EXPAND-FIRST:         cute.make_stride
func.func @fold_get_stride_dynamic(%a: !cute.layout<"(2,3):(1,?)">)
    -> !cute.stride<"(1,?)"> {
  %r = cute.get_stride(%a)
         : !cute.layout<"(2,3):(1,?)"> -> !cute.stride<"(1,?)">
  return %r : !cute.stride<"(1,?)">
}

// -----

// FOLD-FIRST-LABEL: func.func @fold_get_layouts_from_tile
// FOLD-FIRST-NOT:     cute.get_layouts_from_tile
// FOLD-FIRST:         cute.static
// EXPAND-FIRST-LABEL: func.func @fold_get_layouts_from_tile
// EXPAND-FIRST-NOT:     cute.get_layouts_from_tile
// EXPAND-FIRST:         cute.static
func.func @fold_get_layouts_from_tile(%t: !cute.tile<"[(2,3):(1,2);(4,5):(1,4)]">)
    -> (!cute.layout<"(2,3):(1,2)">, !cute.layout<"(4,5):(1,4)">) {
  %r0, %r1 = cute.get_layouts_from_tile(%t)
               : !cute.tile<"[(2,3):(1,2);(4,5):(1,4)]">
  return %r0, %r1 : !cute.layout<"(2,3):(1,2)">, !cute.layout<"(4,5):(1,4)">
}

// -----

// FOLD-FIRST-LABEL: func.func @fold_get_leaves
// FOLD-FIRST-NOT:     cute.get_leaves
// FOLD-FIRST:         cute.static
// EXPAND-FIRST-LABEL: func.func @fold_get_leaves
// EXPAND-FIRST-NOT:     cute.get_leaves
// EXPAND-FIRST:         cute.static
func.func @fold_get_leaves(%t: !cute.int_tuple<"(1,(2,3))">)
    -> (!cute.int_tuple<"1">, !cute.int_tuple<"2">, !cute.int_tuple<"3">) {
  %a, %b, %c = cute.get_leaves(%t) : !cute.int_tuple<"(1,(2,3))">
  return %a, %b, %c
      : !cute.int_tuple<"1">, !cute.int_tuple<"2">, !cute.int_tuple<"3">
}

// -----

// FOLD-FIRST-LABEL: func.func @fold_to_int_tuple_dynamic
// FOLD-FIRST-NOT:     cute.to_int_tuple
// FOLD-FIRST:         cute.get_scalars<{only_dynamic}>
// FOLD-FIRST:         cute.make_int_tuple
// EXPAND-FIRST-LABEL: func.func @fold_to_int_tuple_dynamic
// EXPAND-FIRST-NOT:     cute.to_int_tuple
// EXPAND-FIRST:         cute.get_scalars<{only_dynamic}>
// EXPAND-FIRST:         cute.make_int_tuple
func.func @fold_to_int_tuple_dynamic(%s: !cute.shape<"(?,4)">)
    -> !cute.int_tuple<"(?,4)"> {
  %r = cute.to_int_tuple(%s)
         : !cute.shape<"(?,4)"> -> !cute.int_tuple<"(?,4)">
  return %r : !cute.int_tuple<"(?,4)">
}

// -----

// FOLD-FIRST-LABEL: func.func @fold_composed_get_inner
// FOLD-FIRST-NOT:     cute.composed_get_inner
// FOLD-FIRST:         cute.static
// EXPAND-FIRST-LABEL: func.func @fold_composed_get_inner
// EXPAND-FIRST-NOT:     cute.composed_get_inner
// EXPAND-FIRST:         cute.static
func.func @fold_composed_get_inner(
    %c: !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">)
    -> !cute.layout<"(4,5):(1,4)"> {
  %r = cute.composed_get_inner(%c)
         : !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">
        -> !cute.layout<"(4,5):(1,4)">
  return %r : !cute.layout<"(4,5):(1,4)">
}

// -----

// FOLD-FIRST-LABEL: func.func @fold_composed_get_offset_dynamic
// FOLD-FIRST-NOT:     cute.composed_get_offset
// FOLD-FIRST:         cute.get_scalars<{only_dynamic}>
// FOLD-FIRST:         cute.make_int_tuple
// EXPAND-FIRST-LABEL: func.func @fold_composed_get_offset_dynamic
// EXPAND-FIRST-NOT:     cute.composed_get_offset
// EXPAND-FIRST:         cute.get_scalars<{only_dynamic}>
// EXPAND-FIRST:         cute.make_int_tuple
func.func @fold_composed_get_offset_dynamic(
    %c: !cute.composed_layout<"(4,5):(1,4) o ? o (2,3):(1,2)">)
    -> !cute.int_tuple<"?"> {
  %r = cute.composed_get_offset(%c)
         : !cute.composed_layout<"(4,5):(1,4) o ? o (2,3):(1,2)">
        -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}

// -----

// FOLD-FIRST-LABEL: func.func @fold_composed_get_outer
// FOLD-FIRST-NOT:     cute.composed_get_outer
// FOLD-FIRST:         cute.static
// EXPAND-FIRST-LABEL: func.func @fold_composed_get_outer
// EXPAND-FIRST-NOT:     cute.composed_get_outer
// EXPAND-FIRST:         cute.static
func.func @fold_composed_get_outer(
    %c: !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">)
    -> !cute.layout<"(2,3):(1,2)"> {
  %r = cute.composed_get_outer(%c)
         : !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">
        -> !cute.layout<"(2,3):(1,2)">
  return %r : !cute.layout<"(2,3):(1,2)">
}

// -----

// FOLD-FIRST-LABEL: func.func @fold_get
// FOLD-FIRST-NOT:     cute.get<
// FOLD-FIRST:         cute.static
// EXPAND-FIRST-LABEL: func.func @fold_get
// EXPAND-FIRST-NOT:     cute.get<
// EXPAND-FIRST:         cute.static
func.func @fold_get(%a: !cute.shape<"(4,(2,3))">) -> !cute.shape<"(2,3)"> {
  %r = cute.get<[1]>(%a) : !cute.shape<"(4,(2,3))"> -> !cute.shape<"(2,3)">
  return %r : !cute.shape<"(2,3)">
}

// -----

// FOLD-FIRST-LABEL: func.func @fold_select_dynamic
// FOLD-FIRST-NOT:     cute.select
// FOLD-FIRST:         cute.get_scalars<{only_dynamic}>
// FOLD-FIRST:         cute.make_layout
// EXPAND-FIRST-LABEL: func.func @fold_select_dynamic
// EXPAND-FIRST-NOT:     cute.select
// EXPAND-FIRST:         cute.get_scalars<{only_dynamic}>
// EXPAND-FIRST:         cute.make_layout
func.func @fold_select_dynamic(%a: !cute.layout<"(?,3,4):(1,?,?)">)
    -> !cute.layout<"(?,4):(1,?)"> {
  %r = cute.select<[0,2]>(%a)
         : !cute.layout<"(?,3,4):(1,?,?)"> -> !cute.layout<"(?,4):(1,?)">
  return %r : !cute.layout<"(?,4):(1,?)">
}

//===----------------------------------------------------------------------===//
// LayoutAlgebra
//===----------------------------------------------------------------------===//

// FOLD-FIRST-LABEL: func.func @fold_composition
// FOLD-FIRST-NOT:     cute.composition
// FOLD-FIRST:         cute.static
// EXPAND-FIRST-LABEL: func.func @fold_composition
// EXPAND-FIRST-NOT:     cute.composition
// EXPAND-FIRST:         cute.static
func.func @fold_composition(%a: !cute.layout<"(4,8):(1,4)">,
                              %b: !cute.layout<"(2,4):(1,2)">)
    -> !cute.layout<"(2,4):(1,2)"> {
  %r = cute.composition(%a, %b)
         : (!cute.layout<"(4,8):(1,4)">, !cute.layout<"(2,4):(1,2)">)
        -> !cute.layout<"(2,4):(1,2)">
  return %r : !cute.layout<"(2,4):(1,2)">
}

// -----

// FOLD-FIRST-LABEL: func.func @fold_coalesce_dynamic
// FOLD-FIRST-NOT:     cute.coalesce
// FOLD-FIRST:         cute.get_scalars<{only_dynamic}>
// FOLD-FIRST:         cute.make_layout
// EXPAND-FIRST-LABEL: func.func @fold_coalesce_dynamic
// EXPAND-FIRST-NOT:     cute.coalesce
// EXPAND-FIRST:         cute.get_scalars<{only_dynamic}>
// EXPAND-FIRST:         cute.make_layout
func.func @fold_coalesce_dynamic(%a: !cute.layout<"(?):(?)">)
    -> !cute.layout<"?:?"> {
  %r = cute.coalesce(%a)
         : (!cute.layout<"(?):(?)">) -> !cute.layout<"?:?">
  return %r : !cute.layout<"?:?">
}

// -----

// FOLD-FIRST-LABEL: func.func @fold_complement
// FOLD-FIRST-NOT:     cute.complement
// FOLD-FIRST:         cute.static
// EXPAND-FIRST-LABEL: func.func @fold_complement
// EXPAND-FIRST-NOT:     cute.complement
// EXPAND-FIRST:         cute.static
func.func @fold_complement(%a: !cute.layout<"4:1">, %cotarget: !cute.shape<"24">) -> !cute.layout<"6:4"> {
  %r = cute.complement(%a, %cotarget)
         : (!cute.layout<"4:1">, !cute.shape<"24">) -> !cute.layout<"6:4">
  return %r : !cute.layout<"6:4">
}

// -----

// FOLD-FIRST-LABEL: func.func @fold_group_modes_dynamic
// FOLD-FIRST-NOT:     cute.group_modes
// FOLD-FIRST:         cute.get_scalars<{only_dynamic}>
// FOLD-FIRST:         cute.make_layout
// EXPAND-FIRST-LABEL: func.func @fold_group_modes_dynamic
// EXPAND-FIRST-NOT:     cute.group_modes
// EXPAND-FIRST:         cute.get_scalars<{only_dynamic}>
// EXPAND-FIRST:         cute.make_layout
func.func @fold_group_modes_dynamic(%a: !cute.layout<"(?,3,4):(1,?,?)">)
    -> !cute.layout<"((?,3),4):((1,?),?)"> {
  %r = cute.group_modes<0, 2>(%a)
         : (!cute.layout<"(?,3,4):(1,?,?)">) -> !cute.layout<"((?,3),4):((1,?),?)">
  return %r : !cute.layout<"((?,3),4):((1,?),?)">
}

// -----

// FOLD-FIRST-LABEL: func.func @fold_recast_layout
// FOLD-FIRST-NOT:     cute.recast_layout
// FOLD-FIRST:         cute.static
// EXPAND-FIRST-LABEL: func.func @fold_recast_layout
// EXPAND-FIRST-NOT:     cute.recast_layout
// EXPAND-FIRST:         cute.static
func.func @fold_recast_layout(%a: !cute.layout<"(32,4):(1,32)">)
    -> !cute.layout<"(8,4):(1,8)"> {
  %r = cute.recast_layout<32, 8>(%a)
         : !cute.layout<"(32,4):(1,32)"> -> !cute.layout<"(8,4):(1,8)">
  return %r : !cute.layout<"(8,4):(1,8)">
}

// -----

// FOLD-FIRST-LABEL: func.func @fold_slice_dynamic
// FOLD-FIRST-NOT:     cute.slice
// FOLD-FIRST:         cute.get_scalars<{only_dynamic}>
// FOLD-FIRST:         cute.make_layout
// EXPAND-FIRST-LABEL: func.func @fold_slice_dynamic
// EXPAND-FIRST-NOT:     cute.slice
// EXPAND-FIRST:         cute.get_scalars<{only_dynamic}>
// EXPAND-FIRST:         cute.make_layout
func.func @fold_slice_dynamic(%a: !cute.layout<"(2,?,4):(1,?,?)">,
                                %c: !cute.coord<"(0,_,_)">)
    -> !cute.layout<"(?,4):(?,?)"> {
  %r = cute.slice(%a, %c)
         : !cute.layout<"(2,?,4):(1,?,?)">, !cute.coord<"(0,_,_)">
  return %r : !cute.layout<"(?,4):(?,?)">
}

// -----

// FOLD-FIRST-LABEL: func.func @fold_dice
// FOLD-FIRST-NOT:     cute.dice
// FOLD-FIRST:         cute.static
// EXPAND-FIRST-LABEL: func.func @fold_dice
// EXPAND-FIRST-NOT:     cute.dice
// EXPAND-FIRST:         cute.static
func.func @fold_dice(%a: !cute.layout<"(2,3,4):(1,2,6)">,
                      %c: !cute.coord<"(_,1,_)">)
    -> !cute.layout<"(3):(2)"> {
  %r = cute.dice(%a, %c)
         : !cute.layout<"(2,3,4):(1,2,6)">, !cute.coord<"(_,1,_)">
  return %r : !cute.layout<"(3):(2)">
}

// -----

// FOLD-FIRST-LABEL: func.func @fold_right_inverse
// FOLD-FIRST-NOT:     cute.right_inverse
// FOLD-FIRST:         cute.static
// EXPAND-FIRST-LABEL: func.func @fold_right_inverse
// EXPAND-FIRST-NOT:     cute.right_inverse
// EXPAND-FIRST:         cute.static
func.func @fold_right_inverse(%a: !cute.layout<"(4,3):(1,4)">)
    -> !cute.layout<"12:1"> {
  %r = cute.right_inverse(%a)
         : (!cute.layout<"(4,3):(1,4)">) -> !cute.layout<"12:1">
  return %r : !cute.layout<"12:1">
}

// -----

// FOLD-FIRST-LABEL: func.func @fold_left_inverse
// FOLD-FIRST-NOT:     cute.left_inverse
// FOLD-FIRST:         cute.static
// EXPAND-FIRST-LABEL: func.func @fold_left_inverse
// EXPAND-FIRST-NOT:     cute.left_inverse
// EXPAND-FIRST:         cute.static
func.func @fold_left_inverse(%a: !cute.layout<"(4,3):(3,1)">)
    -> !cute.layout<"(3,4):(4,1)"> {
  %r = cute.left_inverse(%a)
         : (!cute.layout<"(4,3):(3,1)">) -> !cute.layout<"(3,4):(4,1)">
  return %r : !cute.layout<"(3,4):(4,1)">
}

//===----------------------------------------------------------------------===//
// Arithmetic
//===----------------------------------------------------------------------===//

// FOLD-FIRST-LABEL: func.func @fold_tuple_add
// FOLD-FIRST-NOT:     cute.tuple_add
// FOLD-FIRST:         cute.static
// EXPAND-FIRST-LABEL: func.func @fold_tuple_add
// EXPAND-FIRST-NOT:     cute.tuple_add
// EXPAND-FIRST:         cute.static
func.func @fold_tuple_add(%a: !cute.shape<"(2,3)">) -> !cute.shape<"(4,6)"> {
  %r = cute.tuple_add(%a, %a)
         : (!cute.shape<"(2,3)">, !cute.shape<"(2,3)">) -> !cute.shape<"(4,6)">
  return %r : !cute.shape<"(4,6)">
}

// -----

// FOLD-FIRST-LABEL: func.func @fold_tuple_sub_dynamic
// FOLD-FIRST-NOT:     cute.tuple_sub
// FOLD-FIRST:         cute.get_scalars<{only_dynamic}>
// FOLD-FIRST:         arith.subi
// EXPAND-FIRST-LABEL: func.func @fold_tuple_sub_dynamic
// EXPAND-FIRST-NOT:     cute.tuple_sub
// EXPAND-FIRST:         cute.get_scalars<{only_dynamic}>
// EXPAND-FIRST:         arith.subi
func.func @fold_tuple_sub_dynamic(%a: !cute.int_tuple<"(?,?)">,
                                    %b: !cute.int_tuple<"(1,2)">)
    -> !cute.int_tuple<"(?,?)"> {
  %r = cute.tuple_sub(%a, %b)
         : (!cute.int_tuple<"(?,?)">, !cute.int_tuple<"(1,2)">)
        -> !cute.int_tuple<"(?,?)">
  return %r : !cute.int_tuple<"(?,?)">
}

// -----

// FOLD-FIRST-LABEL: func.func @fold_ceil_div_dynamic
// FOLD-FIRST-NOT:     cute.ceil_div
// FOLD-FIRST:         cute.get_scalars<{only_dynamic}>
// FOLD-FIRST:         arith.ceildivsi
// EXPAND-FIRST-LABEL: func.func @fold_ceil_div_dynamic
// EXPAND-FIRST-NOT:     cute.ceil_div
// EXPAND-FIRST:         cute.get_scalars<{only_dynamic}>
// EXPAND-FIRST:         arith.ceildivsi
func.func @fold_ceil_div_dynamic(%a: !cute.int_tuple<"(?,?)">,
                                   %b: !cute.int_tuple<"(3,4)">)
    -> !cute.int_tuple<"(?,?)"> {
  %r = cute.ceil_div(%a, %b)
         : (!cute.int_tuple<"(?,?)">, !cute.int_tuple<"(3,4)">)
        -> !cute.int_tuple<"(?,?)">
  return %r : !cute.int_tuple<"(?,?)">
}

// -----

// FOLD-FIRST-LABEL: func.func @fold_shape_div
// FOLD-FIRST-NOT:     cute.shape_div
// FOLD-FIRST:         cute.static
// EXPAND-FIRST-LABEL: func.func @fold_shape_div
// EXPAND-FIRST-NOT:     cute.shape_div
// EXPAND-FIRST:         cute.static
func.func @fold_shape_div(%a: !cute.shape<"12">,
                            %b: !cute.shape<"4">) -> !cute.shape<"3"> {
  %r = cute.shape_div(%a, %b)
         : (!cute.shape<"12">, !cute.shape<"4">) -> !cute.shape<"3">
  return %r : !cute.shape<"3">
}

// -----

// FOLD-FIRST-LABEL: func.func @fold_elem_less
// FOLD-FIRST-NOT:     cute.elem_less
// FOLD-FIRST:         arith.constant true
// EXPAND-FIRST-LABEL: func.func @fold_elem_less
// EXPAND-FIRST-NOT:     cute.elem_less
// EXPAND-FIRST:         arith.constant true
func.func @fold_elem_less(%a: !cute.int_tuple<"(3,4)">,
                            %b: !cute.int_tuple<"(5,6)">) -> i1 {
  %r = cute.elem_less(%a, %b)
         : (!cute.int_tuple<"(3,4)">, !cute.int_tuple<"(5,6)">) -> i1
  return %r : i1
}

// -----

// FOLD-FIRST-LABEL: func.func @fold_equal
// FOLD-FIRST-NOT:     cute.equal
// FOLD-FIRST:         arith.constant true
// EXPAND-FIRST-LABEL: func.func @fold_equal
// EXPAND-FIRST-NOT:     cute.equal
// EXPAND-FIRST:         arith.constant true
func.func @fold_equal(%a: !cute.shape<"(3,4)">,
                       %b: !cute.shape<"(3,4)">) -> i1 {
  %r = cute.equal(%a, %b) : (!cute.shape<"(3,4)">, !cute.shape<"(3,4)">) -> i1
  return %r : i1
}

//===----------------------------------------------------------------------===//
// SizeIndex
//===----------------------------------------------------------------------===//

// FOLD-FIRST-LABEL: func.func @fold_size
// FOLD-FIRST-NOT:     cute.size
// FOLD-FIRST:         cute.static
// EXPAND-FIRST-LABEL: func.func @fold_size
// EXPAND-FIRST-NOT:     cute.size
// EXPAND-FIRST:         cute.static
func.func @fold_size(%a: !cute.layout<"(2,3,4):(1,2,6)">)
    -> !cute.int_tuple<"24"> {
  %r = cute.size(%a)
         : (!cute.layout<"(2,3,4):(1,2,6)">) -> !cute.int_tuple<"24">
  return %r : !cute.int_tuple<"24">
}

// -----

// FOLD-FIRST-LABEL: func.func @fold_cosize_dynamic
// FOLD-FIRST-NOT:     cute.cosize
// FOLD-FIRST:         cute.get_scalars<{only_dynamic}>
// FOLD-FIRST:         cute.make_int_tuple
// EXPAND-FIRST-LABEL: func.func @fold_cosize_dynamic
// EXPAND-FIRST-NOT:     cute.cosize
// EXPAND-FIRST:         cute.get_scalars<{only_dynamic}>
// EXPAND-FIRST:         cute.make_int_tuple
func.func @fold_cosize_dynamic(%a: !cute.layout<"(?,?,?):(?,?,?)">)
    -> !cute.int_tuple<"?"> {
  %r = cute.cosize(%a)
         : (!cute.layout<"(?,?,?):(?,?,?)">) -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}

// -----

// FOLD-FIRST-LABEL: func.func @fold_tuple_product
// FOLD-FIRST-NOT:     cute.tuple_product
// FOLD-FIRST:         cute.static
// EXPAND-FIRST-LABEL: func.func @fold_tuple_product
// EXPAND-FIRST-NOT:     cute.tuple_product
// EXPAND-FIRST:         cute.static
func.func @fold_tuple_product(%a: !cute.int_tuple<"(2,(3,4))">)
    -> !cute.int_tuple<"24"> {
  %r = cute.tuple_product(%a)
         : (!cute.int_tuple<"(2,(3,4))">) -> !cute.int_tuple<"24">
  return %r : !cute.int_tuple<"24">
}

// -----

// FOLD-FIRST-LABEL: func.func @fold_tuple_product_each_dynamic
// FOLD-FIRST-NOT:     cute.tuple_product_each
// FOLD-FIRST:         cute.get_scalars<{only_dynamic}>
// FOLD-FIRST:         cute.make_shape
// EXPAND-FIRST-LABEL: func.func @fold_tuple_product_each_dynamic
// EXPAND-FIRST-NOT:     cute.tuple_product_each
// EXPAND-FIRST:         cute.get_scalars<{only_dynamic}>
// EXPAND-FIRST:         cute.make_shape
func.func @fold_tuple_product_each_dynamic(%a: !cute.shape<"(?,(3,?))">)
    -> !cute.shape<"(?,?)"> {
  %r = cute.tuple_product_each(%a)
         : (!cute.shape<"(?,(3,?))">) -> !cute.shape<"(?,?)">
  return %r : !cute.shape<"(?,?)">
}

// -----

// FOLD-FIRST-LABEL: func.func @fold_layout_eval_dynamic
// FOLD-FIRST-NOT:     cute.layout_eval
// FOLD-FIRST:         cute.get_scalars<{only_dynamic}>
// FOLD-FIRST:         cute.make_int_tuple
// EXPAND-FIRST-LABEL: func.func @fold_layout_eval_dynamic
// EXPAND-FIRST-NOT:     cute.layout_eval
// EXPAND-FIRST:         cute.get_scalars<{only_dynamic}>
// EXPAND-FIRST:         cute.make_int_tuple
func.func @fold_layout_eval_dynamic(%c: !cute.coord<"(?,?)">,
                                  %l: !cute.layout<"(4,8):(1,4)">)
    -> !cute.int_tuple<"?"> {
  %r = cute.layout_eval(%c, %l)
         : (!cute.coord<"(?,?)">, !cute.layout<"(4,8):(1,4)">) -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}

// -----

// Composed-layout counterpart: dynamic coord into a static composed
// layout. fold-static can't fully collapse (coord is dynamic); expand-ops
// drives the explicit 3-step decomposition (B-layout_eval → offset add → A
// apply) — either ordering must leave no surviving `cute.layout_eval`.
// FOLD-FIRST-LABEL: func.func @fold_layout_eval_composed_dynamic
// FOLD-FIRST-NOT:     cute.layout_eval
// FOLD-FIRST:         cute.get_scalars<{only_dynamic}>
// FOLD-FIRST:         cute.make_int_tuple
// EXPAND-FIRST-LABEL: func.func @fold_layout_eval_composed_dynamic
// EXPAND-FIRST-NOT:     cute.layout_eval
// EXPAND-FIRST:         cute.get_scalars<{only_dynamic}>
// EXPAND-FIRST:         cute.make_int_tuple
func.func @fold_layout_eval_composed_dynamic(
    %c: !cute.coord<"?">,
    %l: !cute.composed_layout<"S<1,4,3> o 0 o (32):(32)">)
    -> !cute.int_tuple<"?"> {
  %r = cute.layout_eval(%c, %l)
         : (!cute.coord<"?">,
            !cute.composed_layout<"S<1,4,3> o 0 o (32):(32)">)
        -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}

// -----

// Static-only composed-layout layout_eval — both orderings must collapse to
// `cute.static`. Exercises the basis-B path (cutegen's `operator()` is
// not supported there) end-to-end through both fold orderings.
// FOLD-FIRST-LABEL: func.func @fold_layout_eval_composed_static_basis_b
// FOLD-FIRST-NOT:     cute.layout_eval
// FOLD-FIRST:         cute.static : !cute.int_tuple<"10">
// EXPAND-FIRST-LABEL: func.func @fold_layout_eval_composed_static_basis_b
// EXPAND-FIRST-NOT:     cute.layout_eval
// EXPAND-FIRST:         cute.static : !cute.int_tuple<"10">
func.func @fold_layout_eval_composed_static_basis_b(
    %c: !cute.coord<"3">,
    %l: !cute.composed_layout<"(6,2):(1,3) o (2,1) o (2,3):(1@1,2@0)">)
    -> !cute.int_tuple<"10"> {
  %r = cute.layout_eval(%c, %l)
         : (!cute.coord<"3">,
            !cute.composed_layout<"(6,2):(1,3) o (2,1) o (2,3):(1@1,2@0)">)
        -> !cute.int_tuple<"10">
  return %r : !cute.int_tuple<"10">
}

// -----

// FOLD-FIRST-LABEL: func.func @fold_idx2crd
// FOLD-FIRST-NOT:     cute.idx2crd
// FOLD-FIRST:         cute.static
// EXPAND-FIRST-LABEL: func.func @fold_idx2crd
// EXPAND-FIRST-NOT:     cute.idx2crd
// EXPAND-FIRST:         cute.static
func.func @fold_idx2crd(%i: !cute.int_tuple<"9">,
                          %s: !cute.shape<"(4,8)">) -> !cute.coord<"(1,2)"> {
  %r = cute.idx2crd(%i, %s)
         : (!cute.int_tuple<"9">, !cute.shape<"(4,8)">) -> !cute.coord<"(1,2)">
  return %r : !cute.coord<"(1,2)">
}

// -----

// Dynamic index counterpart: pass-ordering independence — both fold-first
// and expand-first must leave no surviving `cute.idx2crd` and reach the
// arith-based unravel.
// FOLD-FIRST-LABEL: func.func @fold_idx2crd_dynamic
// FOLD-FIRST-NOT:     cute.idx2crd
// FOLD-FIRST:         cute.get_scalars<{only_dynamic}>
// FOLD-FIRST:         cute.make_coord
// EXPAND-FIRST-LABEL: func.func @fold_idx2crd_dynamic
// EXPAND-FIRST-NOT:     cute.idx2crd
// EXPAND-FIRST:         cute.get_scalars<{only_dynamic}>
// EXPAND-FIRST:         cute.make_coord
func.func @fold_idx2crd_dynamic(%i: !cute.int_tuple<"?">,
                                %s: !cute.shape<"(4,8)">) -> !cute.coord<"(?,?)"> {
  %r = cute.idx2crd(%i, %s)
         : (!cute.int_tuple<"?">, !cute.shape<"(4,8)">) -> !cute.coord<"(?,?)">
  return %r : !cute.coord<"(?,?)">
}

// -----

// FOLD-FIRST-LABEL: func.func @fold_increment_coord_dynamic
// FOLD-FIRST-NOT:     cute.increment_coord
// FOLD-FIRST:         cute.get_scalars<{only_dynamic}>
// FOLD-FIRST:         cute.make_coord
// EXPAND-FIRST-LABEL: func.func @fold_increment_coord_dynamic
// EXPAND-FIRST-NOT:     cute.increment_coord
// EXPAND-FIRST:         cute.get_scalars<{only_dynamic}>
// EXPAND-FIRST:         cute.make_coord
func.func @fold_increment_coord_dynamic(%c: !cute.coord<"(?,?)">,
                                          %s: !cute.shape<"(4,8)">)
    -> !cute.coord<"(?,?)"> {
  %r = cute.increment_coord(%c, %s)
         : (!cute.coord<"(?,?)">, !cute.shape<"(4,8)">) -> !cute.coord<"(?,?)">
  return %r : !cute.coord<"(?,?)">
}

// -----

// FOLD-FIRST-LABEL: func.func @fold_append_to_rank
// FOLD-FIRST-NOT:     cute.append_to_rank
// FOLD-FIRST:         cute.static
// EXPAND-FIRST-LABEL: func.func @fold_append_to_rank
// EXPAND-FIRST-NOT:     cute.append_to_rank
// EXPAND-FIRST:         cute.static
func.func @fold_append_to_rank(%a: !cute.shape<"(4,8)">,
                                 %e: !cute.shape<"1">) -> !cute.shape<"(4,8,1,1)"> {
  %r = cute.append_to_rank<4>(%a, %e)
         : !cute.shape<"(4,8)">, !cute.shape<"1">
  return %r : !cute.shape<"(4,8,1,1)">
}

// -----

// FOLD-FIRST-LABEL: func.func @fold_prepend_to_rank_dynamic
// FOLD-FIRST-NOT:     cute.prepend_to_rank
// FOLD-FIRST:         cute.get_scalars<{only_dynamic}>
// FOLD-FIRST:         cute.make_shape
// EXPAND-FIRST-LABEL: func.func @fold_prepend_to_rank_dynamic
// EXPAND-FIRST-NOT:     cute.prepend_to_rank
// EXPAND-FIRST:         cute.get_scalars<{only_dynamic}>
// EXPAND-FIRST:         cute.make_shape
func.func @fold_prepend_to_rank_dynamic(%a: !cute.shape<"(?,8)">,
                                          %e: !cute.shape<"1">)
    -> !cute.shape<"(1,1,?,8)"> {
  %r = cute.prepend_to_rank<4>(%a, %e)
         : !cute.shape<"(?,8)">, !cute.shape<"1">
  return %r : !cute.shape<"(1,1,?,8)">
}

//===----------------------------------------------------------------------===//
// TilingPartitioningProducts
//===----------------------------------------------------------------------===//

// FOLD-FIRST-LABEL: func.func @fold_logical_product
// FOLD-FIRST-NOT:     cute.logical_product
// FOLD-FIRST:         cute.static
// EXPAND-FIRST-LABEL: func.func @fold_logical_product
// EXPAND-FIRST-NOT:     cute.logical_product
// EXPAND-FIRST:         cute.static
func.func @fold_logical_product(%a: !cute.layout<"(2,2):(4,1)">,
                                  %b: !cute.layout<"6:1">)
    -> !cute.layout<"((2,2),(2,3)):((4,1),(2,8))"> {
  %r = cute.logical_product(%a, %b)
         : (!cute.layout<"(2,2):(4,1)">, !cute.layout<"6:1">)
        -> !cute.layout<"((2,2),(2,3)):((4,1),(2,8))">
  return %r : !cute.layout<"((2,2),(2,3)):((4,1),(2,8))">
}

// -----

// FOLD-FIRST-LABEL: func.func @fold_zipped_product
// FOLD-FIRST-NOT:     cute.zipped_product
// FOLD-FIRST:         cute.static
// EXPAND-FIRST-LABEL: func.func @fold_zipped_product
// EXPAND-FIRST-NOT:     cute.zipped_product
// EXPAND-FIRST:         cute.static
func.func @fold_zipped_product(%a: !cute.layout<"(3,4):(4,1)">,
                                 %b: !cute.layout<"(2,5):(1,2)">)
    -> !cute.layout<"((3,4),(2,5)):((4,1),(12,24))"> {
  %r = cute.zipped_product(%a, %b)
         : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(2,5):(1,2)">)
        -> !cute.layout<"((3,4),(2,5)):((4,1),(12,24))">
  return %r : !cute.layout<"((3,4),(2,5)):((4,1),(12,24))">
}

// -----

// FOLD-FIRST-LABEL: func.func @fold_tiled_product
// FOLD-FIRST-NOT:     cute.tiled_product
// FOLD-FIRST:         cute.static
// EXPAND-FIRST-LABEL: func.func @fold_tiled_product
// EXPAND-FIRST-NOT:     cute.tiled_product
// EXPAND-FIRST:         cute.static
func.func @fold_tiled_product(%a: !cute.layout<"(3,4):(4,1)">,
                                %b: !cute.layout<"(2,5):(1,2)">)
    -> !cute.layout<"((3,4),2,5):((4,1),12,24)"> {
  %r = cute.tiled_product(%a, %b)
         : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(2,5):(1,2)">)
        -> !cute.layout<"((3,4),2,5):((4,1),12,24)">
  return %r : !cute.layout<"((3,4),2,5):((4,1),12,24)">
}

// -----

// FOLD-FIRST-LABEL: func.func @fold_flat_product
// FOLD-FIRST-NOT:     cute.flat_product
// FOLD-FIRST:         cute.static
// EXPAND-FIRST-LABEL: func.func @fold_flat_product
// EXPAND-FIRST-NOT:     cute.flat_product
// EXPAND-FIRST:         cute.static
func.func @fold_flat_product(%a: !cute.layout<"(3,4):(4,1)">,
                               %b: !cute.layout<"(2,5):(1,2)">)
    -> !cute.layout<"(3,4,2,5):(4,1,12,24)"> {
  %r = cute.flat_product(%a, %b)
         : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(2,5):(1,2)">)
        -> !cute.layout<"(3,4,2,5):(4,1,12,24)">
  return %r : !cute.layout<"(3,4,2,5):(4,1,12,24)">
}

// -----

// FOLD-FIRST-LABEL: func.func @fold_raked_product
// FOLD-FIRST-NOT:     cute.raked_product
// FOLD-FIRST:         cute.static
// EXPAND-FIRST-LABEL: func.func @fold_raked_product
// EXPAND-FIRST-NOT:     cute.raked_product
// EXPAND-FIRST:         cute.static
func.func @fold_raked_product(%a: !cute.layout<"(3,4):(4,1)">,
                                %b: !cute.layout<"(2,5):(1,2)">)
    -> !cute.layout<"((2,3),(5,4)):((12,4),(24,1))"> {
  %r = cute.raked_product(%a, %b)
         : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(2,5):(1,2)">)
        -> !cute.layout<"((2,3),(5,4)):((12,4),(24,1))">
  return %r : !cute.layout<"((2,3),(5,4)):((12,4),(24,1))">
}

// -----

// FOLD-FIRST-LABEL: func.func @fold_blocked_product
// FOLD-FIRST-NOT:     cute.blocked_product
// FOLD-FIRST:         cute.static
// EXPAND-FIRST-LABEL: func.func @fold_blocked_product
// EXPAND-FIRST-NOT:     cute.blocked_product
// EXPAND-FIRST:         cute.static
func.func @fold_blocked_product(%a: !cute.layout<"(3,4):(4,1)">,
                                  %b: !cute.layout<"(2,5):(1,2)">)
    -> !cute.layout<"((3,2),(4,5)):((4,12),(1,24))"> {
  %r = cute.blocked_product(%a, %b)
         : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(2,5):(1,2)">)
        -> !cute.layout<"((3,2),(4,5)):((4,12),(1,24))">
  return %r : !cute.layout<"((3,2),(4,5)):((4,12),(1,24))">
}

// -----

// FOLD-FIRST-LABEL: func.func @fold_logical_divide_dynamic
// FOLD-FIRST-NOT:     cute.logical_divide
// FOLD-FIRST:         cute.get_scalars<{only_dynamic}>
// FOLD-FIRST:         cute.make_layout
// EXPAND-FIRST-LABEL: func.func @fold_logical_divide_dynamic
// EXPAND-FIRST-NOT:     cute.logical_divide
// EXPAND-FIRST:         cute.get_scalars<{only_dynamic}>
// EXPAND-FIRST:         cute.make_layout
func.func @fold_logical_divide_dynamic(%a: !cute.layout<"(?,8):(8,1)">,
                                          %b: !cute.shape<"(3,4)">)
    -> !cute.layout<"((3,?),(4,2)):((8,24),(1,4))"> {
  %r = cute.logical_divide(%a, %b)
         : (!cute.layout<"(?,8):(8,1)">, !cute.shape<"(3,4)">)
        -> !cute.layout<"((3,?),(4,2)):((8,24),(1,4))">
  return %r : !cute.layout<"((3,?),(4,2)):((8,24),(1,4))">
}

// -----

// FOLD-FIRST-LABEL: func.func @fold_zipped_divide
// FOLD-FIRST-NOT:     cute.zipped_divide
// FOLD-FIRST:         cute.static
// EXPAND-FIRST-LABEL: func.func @fold_zipped_divide
// EXPAND-FIRST-NOT:     cute.zipped_divide
// EXPAND-FIRST:         cute.static
func.func @fold_zipped_divide(%a: !cute.layout<"(6,8):(8,1)">,
                                %b: !cute.shape<"(3,4)">)
    -> !cute.layout<"((3,4),(2,2)):((8,1),(24,4))"> {
  %r = cute.zipped_divide(%a, %b)
         : (!cute.layout<"(6,8):(8,1)">, !cute.shape<"(3,4)">)
        -> !cute.layout<"((3,4),(2,2)):((8,1),(24,4))">
  return %r : !cute.layout<"((3,4),(2,2)):((8,1),(24,4))">
}

// -----

// FOLD-FIRST-LABEL: func.func @fold_tiled_divide
// FOLD-FIRST-NOT:     cute.tiled_divide
// FOLD-FIRST:         cute.static
// EXPAND-FIRST-LABEL: func.func @fold_tiled_divide
// EXPAND-FIRST-NOT:     cute.tiled_divide
// EXPAND-FIRST:         cute.static
func.func @fold_tiled_divide(%a: !cute.layout<"(6,8):(8,1)">,
                               %b: !cute.tile<"[3:1;4:1]">)
    -> !cute.layout<"((3,4),2,2):((8,1),24,4)"> {
  %r = cute.tiled_divide(%a, %b)
         : (!cute.layout<"(6,8):(8,1)">, !cute.tile<"[3:1;4:1]">)
        -> !cute.layout<"((3,4),2,2):((8,1),24,4)">
  return %r : !cute.layout<"((3,4),2,2):((8,1),24,4)">
}

// -----

// FOLD-FIRST-LABEL: func.func @fold_flat_divide
// FOLD-FIRST-NOT:     cute.flat_divide
// FOLD-FIRST:         cute.static
// EXPAND-FIRST-LABEL: func.func @fold_flat_divide
// EXPAND-FIRST-NOT:     cute.flat_divide
// EXPAND-FIRST:         cute.static
func.func @fold_flat_divide(%a: !cute.layout<"(6,8):(8,1)">,
                              %b: !cute.shape<"(3,4)">)
    -> !cute.layout<"(3,4,2,2):(8,1,24,4)"> {
  %r = cute.flat_divide(%a, %b)
         : (!cute.layout<"(6,8):(8,1)">, !cute.shape<"(3,4)">)
        -> !cute.layout<"(3,4,2,2):(8,1,24,4)">
  return %r : !cute.layout<"(3,4,2,2):(8,1,24,4)">
}

// -----

// FOLD-FIRST-LABEL: func.func @fold_tile_to_shape
// FOLD-FIRST-NOT:     cute.tile_to_shape
// FOLD-FIRST:         cute.static
// EXPAND-FIRST-LABEL: func.func @fold_tile_to_shape
// EXPAND-FIRST-NOT:     cute.tile_to_shape
// EXPAND-FIRST:         cute.static
func.func @fold_tile_to_shape(%a: !cute.layout<"(3,2):(1,3)">,
                                %s: !cute.shape<"(6,8)">)
    -> !cute.layout<"((3,2),(2,4)):((1,6),(3,12))"> {
  %r = cute.tile_to_shape(%a, %s)
         : (!cute.layout<"(3,2):(1,3)">, !cute.shape<"(6,8)">)
        -> !cute.layout<"((3,2),(2,4)):((1,6),(3,12))">
  return %r : !cute.layout<"((3,2),(2,4)):((1,6),(3,12))">
}
