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

// RUN: cute-opt -cute-fold-static --split-input-file %s | FileCheck %s

// cute-fold-static: ops with dynamic result types are not folded.

// -----

//===----------------------------------------------------------------------===//
// Constructors
//===----------------------------------------------------------------------===//

// CHECK-LABEL: func.func @no_fold_make_int_tuple
// CHECK-SAME:  (%[[N:.+]]: i32)
// CHECK-NEXT:    %[[R:.+]] = cute.make_int_tuple(%[[N]]) : (i32) -> !cute.int_tuple<"?">
// CHECK-NEXT:    return %[[R]]
func.func @no_fold_make_int_tuple(%n: i32) -> !cute.int_tuple<"?"> {
  %r = cute.make_int_tuple(%n) : (i32) -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}

// -----

// CHECK-LABEL: func.func @no_fold_make_shape
// CHECK-SAME:  (%[[N:.+]]: i32)
// CHECK-NEXT:    %[[R:.+]] = cute.make_shape(%[[N]]) : (i32) -> !cute.shape<"(?,4)">
// CHECK-NEXT:    return %[[R]]
func.func @no_fold_make_shape(%n: i32) -> !cute.shape<"(?,4)"> {
  %r = cute.make_shape(%n) : (i32) -> !cute.shape<"(?,4)">
  return %r : !cute.shape<"(?,4)">
}

// -----

// CHECK-LABEL: func.func @no_fold_make_stride
// CHECK-SAME:  (%[[S:.+]]: i32)
// CHECK-NEXT:    %[[R:.+]] = cute.make_stride(%[[S]]) : (i32) -> !cute.stride<"?">
// CHECK-NEXT:    return %[[R]]
func.func @no_fold_make_stride(%s: i32) -> !cute.stride<"?"> {
  %r = cute.make_stride(%s) : (i32) -> !cute.stride<"?">
  return %r : !cute.stride<"?">
}

// -----

// CHECK-LABEL: func.func @no_fold_make_coord
// CHECK-SAME:  (%[[I:.+]]: i32, %[[J:.+]]: i32)
// CHECK-NEXT:    %[[R:.+]] = cute.make_coord(%[[I]], %[[J]]) : (i32, i32) -> !cute.coord<"(?,?)">
// CHECK-NEXT:    return %[[R]]
func.func @no_fold_make_coord(%i: i32, %j: i32) -> !cute.coord<"(?,?)"> {
  %r = cute.make_coord(%i, %j) : (i32, i32) -> !cute.coord<"(?,?)">
  return %r : !cute.coord<"(?,?)">
}

// -----

// Dynamic operand propagates through to a dynamic result.
// CHECK-LABEL: func.func @no_fold_make_layout
// CHECK-SAME:  (%[[N:.+]]: i32)
// CHECK-NEXT:    %[[S:.+]] = cute.make_shape(%[[N]]) : (i32) -> !cute.shape<"(?,4)">
// CHECK-NEXT:    %[[D:.+]] = cute.make_stride(%[[N]]) : (i32) -> !cute.stride<"(1,?)">
// CHECK-NEXT:    %[[L:.+]] = cute.make_layout(%[[S]], %[[D]]) : (!cute.shape<"(?,4)">, !cute.stride<"(1,?)">) -> !cute.layout<"(?,4):(1,?)">
// CHECK-NEXT:    return %[[L]]
func.func @no_fold_make_layout(%n: i32) -> !cute.layout<"(?,4):(1,?)"> {
  %s = cute.make_shape(%n) : (i32) -> !cute.shape<"(?,4)">
  %d = cute.make_stride(%n) : (i32) -> !cute.stride<"(1,?)">
  %l = cute.make_layout(%s, %d) : (!cute.shape<"(?,4)">, !cute.stride<"(1,?)">) -> !cute.layout<"(?,4):(1,?)">
  return %l : !cute.layout<"(?,4):(1,?)">
}

// -----

// CHECK-LABEL: func.func @no_fold_make_tile
// CHECK:         %[[R:.+]] = cute.make_tile
// CHECK-SAME:                  -> !cute.tile<"[(?,3):(1,?)]">
// CHECK-NEXT:    return %[[R]]
func.func @no_fold_make_tile(%m: i32, %n: i32) -> !cute.tile<"[(?,3):(1,?)]"> {
  %r = cute.make_tile(%m, %n) : (i32, i32) -> !cute.tile<"[(?,3):(1,?)]">
  return %r : !cute.tile<"[(?,3):(1,?)]">
}

// -----

// CHECK-LABEL: func.func @no_fold_make_composed_layout
// CHECK:         %[[R:.+]] = cute.make_composed_layout
// CHECK:         return %[[R]]
func.func @no_fold_make_composed_layout(
    %a: !cute.layout<"(?,5):(1,?)">,
    %off: !cute.int_tuple<"0">,
    %b: !cute.layout<"(2,3):(1,2)">)
    -> !cute.composed_layout<"(?,5):(1,?) o 0 o (2,3):(1,2)"> {
  %r = cute.make_composed_layout(%a, %off, %b)
         : (!cute.layout<"(?,5):(1,?)">, !cute.int_tuple<"0">,
            !cute.layout<"(2,3):(1,2)">)
        -> !cute.composed_layout<"(?,5):(1,?) o 0 o (2,3):(1,2)">
  return %r : !cute.composed_layout<"(?,5):(1,?) o 0 o (2,3):(1,2)">
}

// -----

// CHECK-LABEL: func.func @no_fold_make_layout_like
// CHECK:         %[[R:.+]] = cute.make_layout_like
// CHECK:         return %[[R]]
func.func @no_fold_make_layout_like(%src: !cute.layout<"(?,2):(?,1)">)
    -> !cute.layout<"(?,2):(2,1)"> {
  %r = cute.make_layout_like(%src)
         : !cute.layout<"(?,2):(?,1)"> -> !cute.layout<"(?,2):(2,1)">
  return %r : !cute.layout<"(?,2):(2,1)">
}

// -----

// CHECK-LABEL: func.func @no_fold_make_ordered_layout
// CHECK:         %[[R:.+]] = cute.make_ordered_layout
// CHECK:         return %[[R]]
func.func @no_fold_make_ordered_layout(
    %s: !cute.shape<"(4,3,?,2)">,
    %o: !cute.int_tuple<"(2,1,3,4)">)
    -> !cute.layout<"(4,3,?,2):(3,1,12,?)"> {
  %r = cute.make_ordered_layout(%s, %o)
         : (!cute.shape<"(4,3,?,2)">, !cute.int_tuple<"(2,1,3,4)">)
        -> !cute.layout<"(4,3,?,2):(3,1,12,?)">
  return %r : !cute.layout<"(4,3,?,2):(3,1,12,?)">
}

// -----

// CHECK-LABEL: func.func @no_fold_make_identity_layout
// CHECK:         %[[R:.+]] = cute.make_identity_layout
// CHECK:         return %[[R]]
func.func @no_fold_make_identity_layout(%s: !cute.shape<"(?,3)">)
    -> !cute.layout<"(?,3):(1@0,1@1)"> {
  %r = cute.make_identity_layout(%s)
         : !cute.shape<"(?,3)"> -> !cute.layout<"(?,3):(1@0,1@1)">
  return %r : !cute.layout<"(?,3):(1@0,1@1)">
}

// -----

//===----------------------------------------------------------------------===//
// Accessors
//===----------------------------------------------------------------------===//

// CHECK-LABEL: func.func @no_fold_get_shape
// CHECK:         %[[R:.+]] = cute.get_shape
// CHECK:         return %[[R]]
func.func @no_fold_get_shape(%l: !cute.layout<"(?,4):(1,?)">)
    -> !cute.shape<"(?,4)"> {
  %r = cute.get_shape(%l) : !cute.layout<"(?,4):(1,?)"> -> !cute.shape<"(?,4)">
  return %r : !cute.shape<"(?,4)">
}

// -----

// CHECK-LABEL: func.func @no_fold_get_stride
// CHECK:         %[[R:.+]] = cute.get_stride
// CHECK:         return %[[R]]
func.func @no_fold_get_stride(%l: !cute.layout<"(?,4):(1,?)">)
    -> !cute.stride<"(1,?)"> {
  %r = cute.get_stride(%l) : !cute.layout<"(?,4):(1,?)"> -> !cute.stride<"(1,?)">
  return %r : !cute.stride<"(1,?)">
}

// -----

// CHECK-LABEL: func.func @no_fold_composed_get_inner
// CHECK:         %[[R:.+]] = cute.composed_get_inner
// CHECK:         return %[[R]]
func.func @no_fold_composed_get_inner(
    %cl: !cute.composed_layout<"(?,4):(1,?) o 0 o (2,4):(1,2)">)
    -> !cute.layout<"(?,4):(1,?)"> {
  %r = cute.composed_get_inner(%cl)
         : !cute.composed_layout<"(?,4):(1,?) o 0 o (2,4):(1,2)">
        -> !cute.layout<"(?,4):(1,?)">
  return %r : !cute.layout<"(?,4):(1,?)">
}

// -----

// CHECK-LABEL: func.func @no_fold_composed_get_offset
// CHECK:         %[[R:.+]] = cute.composed_get_offset
// CHECK:         return %[[R]]
func.func @no_fold_composed_get_offset(
    %cl: !cute.composed_layout<"(4,8):(1,4) o ? o (2,4):(1,2)">)
    -> !cute.int_tuple<"?"> {
  %r = cute.composed_get_offset(%cl)
         : !cute.composed_layout<"(4,8):(1,4) o ? o (2,4):(1,2)">
        -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}

// -----

// CHECK-LABEL: func.func @no_fold_composed_get_outer
// CHECK:         %[[R:.+]] = cute.composed_get_outer
// CHECK:         return %[[R]]
func.func @no_fold_composed_get_outer(
    %cl: !cute.composed_layout<"(4,8):(1,4) o 0 o (?,4):(1,?)">)
    -> !cute.layout<"(?,4):(1,?)"> {
  %r = cute.composed_get_outer(%cl)
         : !cute.composed_layout<"(4,8):(1,4) o 0 o (?,4):(1,?)">
        -> !cute.layout<"(?,4):(1,?)">
  return %r : !cute.layout<"(?,4):(1,?)">
}

// -----

// CHECK-LABEL: func.func @no_fold_to_int_tuple
// CHECK:         %[[R:.+]] = cute.to_int_tuple
// CHECK:         return %[[R]]
func.func @no_fold_to_int_tuple(%s: !cute.shape<"(?,4)">)
    -> !cute.int_tuple<"(?,4)"> {
  %r = cute.to_int_tuple(%s) : !cute.shape<"(?,4)"> -> !cute.int_tuple<"(?,4)">
  return %r : !cute.int_tuple<"(?,4)">
}

// -----

// All leaves are dynamic so both variadic results stay as ops of get_leaves
// and the op is preserved.
// CHECK-LABEL: func.func @no_fold_get_leaves
// CHECK:         %[[R:.+]]:2 = cute.get_leaves
// CHECK:         return %[[R]]#0, %[[R]]#1
func.func @no_fold_get_leaves(%s: !cute.shape<"(?,?)">)
    -> (!cute.shape<"?">, !cute.shape<"?">) {
  %a, %b = cute.get_leaves(%s) : !cute.shape<"(?,?)">
  return %a, %b : !cute.shape<"?">, !cute.shape<"?">
}

// -----

// CHECK-LABEL: func.func @no_fold_get_layouts_from_tile
// CHECK:         %[[R:.+]] = cute.get_layouts_from_tile
// CHECK:         return %[[R]]
func.func @no_fold_get_layouts_from_tile(%t: !cute.tile<"[(?,4):(1,?)]">)
    -> !cute.layout<"(?,4):(1,?)"> {
  %a = cute.get_layouts_from_tile(%t) : !cute.tile<"[(?,4):(1,?)]">
  return %a : !cute.layout<"(?,4):(1,?)">
}

// -----

//===----------------------------------------------------------------------===//
// Indexable: get / select
//===----------------------------------------------------------------------===//

// CHECK-LABEL: func.func @no_fold_get
// CHECK:         %[[R:.+]] = cute.get
// CHECK:         return %[[R]]
func.func @no_fold_get(%v: !cute.layout<"(?,4):(1,?)">) -> !cute.layout<"?:1"> {
  %r = cute.get<[0]>(%v) : !cute.layout<"(?,4):(1,?)"> -> !cute.layout<"?:1">
  return %r : !cute.layout<"?:1">
}

// -----

// CHECK-LABEL: func.func @no_fold_select
// CHECK:         %[[R:.+]] = cute.select
// CHECK:         return %[[R]]
func.func @no_fold_select(%v: !cute.shape<"(4,?,2)">) -> !cute.shape<"(4,?)"> {
  %r = cute.select<[0, 1]>(%v) : !cute.shape<"(4,?,2)"> -> !cute.shape<"(4,?)">
  return %r : !cute.shape<"(4,?)">
}

// -----

//===----------------------------------------------------------------------===//
// Layout algebra
//===----------------------------------------------------------------------===//

// CHECK-LABEL: func.func @no_fold_composition
// CHECK:         %[[R:.+]] = cute.composition
// CHECK:         return %[[R]]
func.func @no_fold_composition(%outer: !cute.layout<"?:?">,
                                %inner: !cute.layout<"4:1">)
    -> !cute.layout<"4:?"> {
  %r = cute.composition(%outer, %inner)
         : (!cute.layout<"?:?">, !cute.layout<"4:1">) -> !cute.layout<"4:?">
  return %r : !cute.layout<"4:?">
}

// -----

// CHECK-LABEL: func.func @no_fold_coalesce
// CHECK:         %[[R:.+]] = cute.coalesce
// CHECK:         return %[[R]]
func.func @no_fold_coalesce(%input: !cute.layout<"(?):(?)">)
    -> !cute.layout<"?:?"> {
  %r = cute.coalesce(%input) : (!cute.layout<"(?):(?)">) -> !cute.layout<"?:?">
  return %r : !cute.layout<"?:?">
}

// -----

// CHECK-LABEL: func.func @no_fold_complement
// CHECK:         %[[R:.+]] = cute.complement
// CHECK:         return %[[R]]
func.func @no_fold_complement(%input: !cute.layout<"?:2">,
                               %cotarget: !cute.shape<"6">)
    -> !cute.layout<"(2,?):(1,?)"> {
  %r = cute.complement(%input, %cotarget)
         : (!cute.layout<"?:2">, !cute.shape<"6">)
        -> !cute.layout<"(2,?):(1,?)">
  return %r : !cute.layout<"(2,?):(1,?)">
}

// -----

// CHECK-LABEL: func.func @no_fold_group_modes
// CHECK:         %[[R:.+]] = cute.group_modes
// CHECK:         return %[[R]]
func.func @no_fold_group_modes(%input: !cute.layout<"(?,5,6):(1,?,?)">)
    -> !cute.layout<"((?,5),6):((1,?),?)"> {
  %r = cute.group_modes<0, 2>(%input)
         : (!cute.layout<"(?,5,6):(1,?,?)">)
        -> !cute.layout<"((?,5),6):((1,?),?)">
  return %r : !cute.layout<"((?,5),6):((1,?),?)">
}

// -----

// CHECK-LABEL: func.func @no_fold_recast_layout
// CHECK:         %[[R:.+]] = cute.recast_layout
// CHECK:         return %[[R]]
func.func @no_fold_recast_layout(%src: !cute.layout<"(32,?):(1,?)">)
    -> !cute.layout<"(8,?):(1,?)"> {
  %r = cute.recast_layout<32, 8>(%src)
         : !cute.layout<"(32,?):(1,?)"> -> !cute.layout<"(8,?):(1,?)">
  return %r : !cute.layout<"(8,?):(1,?)">
}

// -----

// CHECK-LABEL: func.func @no_fold_slice
// CHECK:         %[[R:.+]] = cute.slice
// CHECK:         return %[[R]]
func.func @no_fold_slice(%src: !cute.layout<"(2,?,4):(1,?,?)">,
                          %crd: !cute.coord<"(0,_,1)">)
    -> !cute.layout<"(?):(?)"> {
  %r = cute.slice(%src, %crd)
         : !cute.layout<"(2,?,4):(1,?,?)">, !cute.coord<"(0,_,1)">
  return %r : !cute.layout<"(?):(?)">
}

// -----

// CHECK-LABEL: func.func @no_fold_dice
// CHECK:         %[[R:.+]] = cute.dice
// CHECK:         return %[[R]]
func.func @no_fold_dice(%src: !cute.layout<"(2,?,4):(1,?,?)">,
                         %crd: !cute.coord<"(_,1,_)">)
    -> !cute.layout<"(?):(?)"> {
  %r = cute.dice(%src, %crd)
         : !cute.layout<"(2,?,4):(1,?,?)">, !cute.coord<"(_,1,_)">
  return %r : !cute.layout<"(?):(?)">
}

// -----

//===----------------------------------------------------------------------===//
// Arithmetic
//===----------------------------------------------------------------------===//

// CHECK-LABEL: func.func @no_fold_tuple_add
// CHECK:         %[[R:.+]] = cute.tuple_add
// CHECK:         return %[[R]]
func.func @no_fold_tuple_add(%a: !cute.int_tuple<"(?,?)">,
                              %b: !cute.int_tuple<"(?,?)">)
    -> !cute.int_tuple<"(?,?)"> {
  %r = cute.tuple_add(%a, %b)
         : (!cute.int_tuple<"(?,?)">, !cute.int_tuple<"(?,?)">)
        -> !cute.int_tuple<"(?,?)">
  return %r : !cute.int_tuple<"(?,?)">
}

// -----

// CHECK-LABEL: func.func @no_fold_tuple_sub
// CHECK:         %[[R:.+]] = cute.tuple_sub
// CHECK:         return %[[R]]
func.func @no_fold_tuple_sub(%a: !cute.int_tuple<"(?,?)">,
                              %b: !cute.int_tuple<"(?,?)">)
    -> !cute.int_tuple<"(?,?)"> {
  %r = cute.tuple_sub(%a, %b)
         : (!cute.int_tuple<"(?,?)">, !cute.int_tuple<"(?,?)">)
        -> !cute.int_tuple<"(?,?)">
  return %r : !cute.int_tuple<"(?,?)">
}


// -----

// CHECK-LABEL: func.func @no_fold_ceil_div
// CHECK:         %[[R:.+]] = cute.ceil_div
// CHECK:         return %[[R]]
func.func @no_fold_ceil_div(%a: !cute.int_tuple<"(?,?)">,
                             %b: !cute.int_tuple<"(?,?)">)
    -> !cute.int_tuple<"(?,?)"> {
  %r = cute.ceil_div(%a, %b)
         : (!cute.int_tuple<"(?,?)">, !cute.int_tuple<"(?,?)">)
        -> !cute.int_tuple<"(?,?)">
  return %r : !cute.int_tuple<"(?,?)">
}

// -----

// CHECK-LABEL: func.func @no_fold_shape_div
// CHECK:         %[[R:.+]] = cute.shape_div
// CHECK:         return %[[R]]
func.func @no_fold_shape_div(%a: !cute.shape<"(?,?)">,
                              %b: !cute.shape<"(?,?)">)
    -> !cute.shape<"(?,?)"> {
  %r = cute.shape_div(%a, %b)
         : (!cute.shape<"(?,?)">, !cute.shape<"(?,?)">) -> !cute.shape<"(?,?)">
  return %r : !cute.shape<"(?,?)">
}

// -----

// elem_less and equal with dynamic operands are not folded.
// CHECK-LABEL: func.func @no_fold_elem_less
// CHECK:         %[[R:.+]] = cute.elem_less
// CHECK:         return %[[R]]
func.func @no_fold_elem_less(%a: !cute.int_tuple<"(?,?)">,
                              %b: !cute.int_tuple<"(?,?)">) -> i1 {
  %r = cute.elem_less(%a, %b)
         : (!cute.int_tuple<"(?,?)">, !cute.int_tuple<"(?,?)">) -> i1
  return %r : i1
}

// -----

// CHECK-LABEL: func.func @no_fold_equal
// CHECK:         %[[R:.+]] = cute.equal
// CHECK:         return %[[R]]
func.func @no_fold_equal(%a: !cute.int_tuple<"(?,?)">,
                          %b: !cute.int_tuple<"(?,?)">) -> i1 {
  %r = cute.equal(%a, %b)
         : (!cute.int_tuple<"(?,?)">, !cute.int_tuple<"(?,?)">) -> i1
  return %r : i1
}

// -----

//===----------------------------------------------------------------------===//
// Sizes / Coords / Rank
//===----------------------------------------------------------------------===//

// CHECK-LABEL: func.func @no_fold_size
// CHECK:         %[[R:.+]] = cute.size
// CHECK:         return %[[R]]
func.func @no_fold_size(%src: !cute.shape<"(4,(16,32),(?,64))">)
    -> !cute.int_tuple<"?"> {
  %r = cute.size(%src)
         : (!cute.shape<"(4,(16,32),(?,64))">)
        -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}

// -----

// CHECK-LABEL: func.func @no_fold_cosize
// CHECK:         %[[R:.+]] = cute.cosize
// CHECK:         return %[[R]]
func.func @no_fold_cosize(%src: !cute.layout<"(?,?,?):(?,?,?)">)
    -> !cute.int_tuple<"?"> {
  %r = cute.cosize(%src)
         : (!cute.layout<"(?,?,?):(?,?,?)">) -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}

// -----

// CHECK-LABEL: func.func @no_fold_tuple_product
// CHECK:         %[[R:.+]] = cute.tuple_product
// CHECK:         return %[[R]]
func.func @no_fold_tuple_product(%src: !cute.shape<"(4,(16,32),(?,64))">)
    -> !cute.shape<"?"> {
  %r = cute.tuple_product(%src)
         : (!cute.shape<"(4,(16,32),(?,64))">)
        -> !cute.shape<"?">
  return %r : !cute.shape<"?">
}

// -----

// CHECK-LABEL: func.func @no_fold_tuple_product_each
// CHECK:         %[[R:.+]] = cute.tuple_product_each
// CHECK:         return %[[R]]
func.func @no_fold_tuple_product_each(%src: !cute.shape<"(4,(?,32))">)
    -> !cute.shape<"(4,?)"> {
  %r = cute.tuple_product_each(%src)
         : (!cute.shape<"(4,(?,32))">) -> !cute.shape<"(4,?)">
  return %r : !cute.shape<"(4,?)">
}

// -----

// CHECK-LABEL: func.func @no_fold_layout_eval
// CHECK:         %[[R:.+]] = cute.layout_eval
// CHECK:         return %[[R]]
func.func @no_fold_layout_eval(%crd: !cute.coord<"(?,?)">,
                            %l: !cute.layout<"(4,8):(1,4)">)
    -> !cute.int_tuple<"?"> {
  %r = cute.layout_eval(%crd, %l)
         : (!cute.coord<"(?,?)">, !cute.layout<"(4,8):(1,4)">)
        -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}

// -----

// CHECK-LABEL: func.func @no_fold_idx2crd
// CHECK:         %[[R:.+]] = cute.idx2crd
// CHECK:         return %[[R]]
func.func @no_fold_idx2crd(%idx: !cute.int_tuple<"?">,
                            %s: !cute.shape<"(4,8)">) -> !cute.coord<"(?,?)"> {
  %r = cute.idx2crd(%idx, %s)
         : (!cute.int_tuple<"?">, !cute.shape<"(4,8)">) -> !cute.coord<"(?,?)">
  return %r : !cute.coord<"(?,?)">
}

// -----

// CHECK-LABEL: func.func @no_fold_increment_coord
// CHECK:         %[[R:.+]] = cute.increment_coord
// CHECK:         return %[[R]]
func.func @no_fold_increment_coord(%c: !cute.coord<"(?,?)">,
                                    %s: !cute.shape<"(4,8)">)
    -> !cute.coord<"(?,?)"> {
  %r = cute.increment_coord(%c, %s)
         : (!cute.coord<"(?,?)">, !cute.shape<"(4,8)">) -> !cute.coord<"(?,?)">
  return %r : !cute.coord<"(?,?)">
}

// -----

// CHECK-LABEL: func.func @no_fold_append_to_rank
// CHECK:         %[[R:.+]] = cute.append_to_rank
// CHECK:         return %[[R]]
func.func @no_fold_append_to_rank(%in: !cute.shape<"(4,8)">,
                                   %e: !cute.shape<"?">)
    -> !cute.shape<"(4,8,?,?)"> {
  %r = cute.append_to_rank<4>(%in, %e) : !cute.shape<"(4,8)">, !cute.shape<"?">
  return %r : !cute.shape<"(4,8,?,?)">
}

// -----

// CHECK-LABEL: func.func @no_fold_prepend_to_rank
// CHECK:         %[[R:.+]] = cute.prepend_to_rank
// CHECK:         return %[[R]]
func.func @no_fold_prepend_to_rank(%in: !cute.shape<"(4,8)">,
                                    %e: !cute.shape<"?">)
    -> !cute.shape<"(?,?,4,8)"> {
  %r = cute.prepend_to_rank<4>(%in, %e) : !cute.shape<"(4,8)">, !cute.shape<"?">
  return %r : !cute.shape<"(?,?,4,8)">
}

// -----

//===----------------------------------------------------------------------===//
// Tiling / Partitioning / Products
//===----------------------------------------------------------------------===//

// -----

// CHECK-LABEL: func.func @no_fold_logical_divide
// CHECK:         %[[R:.+]] = cute.logical_divide
// CHECK:         return %[[R]]
func.func @no_fold_logical_divide(%a: !cute.layout<"(?,8):(?,1)">,
                                   %b: !cute.shape<"(3,4)">)
    -> !cute.layout<"((3,?),(4,2)):((?,?),(1,4))"> {
  %r = cute.logical_divide(%a, %b)
         : (!cute.layout<"(?,8):(?,1)">, !cute.shape<"(3,4)">)
        -> !cute.layout<"((3,?),(4,2)):((?,?),(1,4))">
  return %r : !cute.layout<"((3,?),(4,2)):((?,?),(1,4))">
}

// -----

// CHECK-LABEL: func.func @no_fold_zipped_divide
// CHECK:         %[[R:.+]] = cute.zipped_divide
// CHECK:         return %[[R]]
func.func @no_fold_zipped_divide(%a: !cute.layout<"(?,8):(?,1)">,
                                  %b: !cute.shape<"(3,4)">)
    -> !cute.layout<"((3,4),(?,2)):((?,1),(?,4))"> {
  %r = cute.zipped_divide(%a, %b)
         : (!cute.layout<"(?,8):(?,1)">, !cute.shape<"(3,4)">)
        -> !cute.layout<"((3,4),(?,2)):((?,1),(?,4))">
  return %r : !cute.layout<"((3,4),(?,2)):((?,1),(?,4))">
}

// -----

// CHECK-LABEL: func.func @no_fold_tiled_divide
// CHECK:         %[[R:.+]] = cute.tiled_divide
// CHECK:         return %[[R]]
func.func @no_fold_tiled_divide(%a: !cute.layout<"(?,8):(?,1)">,
                                 %b: !cute.shape<"(3,4)">)
    -> !cute.layout<"((3,4),?,2):((?,1),?,4)"> {
  %r = cute.tiled_divide(%a, %b)
         : (!cute.layout<"(?,8):(?,1)">, !cute.shape<"(3,4)">)
        -> !cute.layout<"((3,4),?,2):((?,1),?,4)">
  return %r : !cute.layout<"((3,4),?,2):((?,1),?,4)">
}

// -----

// CHECK-LABEL: func.func @no_fold_flat_divide
// CHECK:         %[[R:.+]] = cute.flat_divide
// CHECK:         return %[[R]]
func.func @no_fold_flat_divide(%a: !cute.layout<"(?,8):(?,1)">,
                                %b: !cute.shape<"(3,4)">)
    -> !cute.layout<"(3,4,?,2):(?,1,?,4)"> {
  %r = cute.flat_divide(%a, %b)
         : (!cute.layout<"(?,8):(?,1)">, !cute.shape<"(3,4)">)
        -> !cute.layout<"(3,4,?,2):(?,1,?,4)">
  return %r : !cute.layout<"(3,4,?,2):(?,1,?,4)">
}

// -----

// CHECK-LABEL: func.func @no_fold_tile_to_shape
// CHECK:         %[[R:.+]] = cute.tile_to_shape
// CHECK:         return %[[R]]
func.func @no_fold_tile_to_shape(%a: !cute.layout<"4:1">,
                                  %b: !cute.shape<"(?,8)">)
    -> !cute.layout<"((4,?),(1,8)):((1,4),(0,?))"> {
  %r = cute.tile_to_shape(%a, %b)
         : (!cute.layout<"4:1">, !cute.shape<"(?,8)">)
        -> !cute.layout<"((4,?),(1,8)):((1,4),(0,?))">
  return %r : !cute.layout<"((4,?),(1,8)):((1,4),(0,?))">
}
