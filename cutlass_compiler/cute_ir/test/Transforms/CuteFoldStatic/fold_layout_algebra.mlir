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

// cute-fold-static: layout-algebra ops with fully-static results fold to cute.static.

// -----

//===----------------------------------------------------------------------===//
// composition
//===----------------------------------------------------------------------===//

// CHECK-LABEL: func.func @fold_composition_layout
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.layout<"(2,4):(1,2)">
// CHECK-NEXT:    return %[[R]]
func.func @fold_composition_layout(
    %outer: !cute.layout<"(4,8):(1,4)">,
    %inner: !cute.layout<"(2,4):(1,2)">) -> !cute.layout<"(2,4):(1,2)"> {
  %r = cute.composition(%outer, %inner)
         : (!cute.layout<"(4,8):(1,4)">, !cute.layout<"(2,4):(1,2)">)
        -> !cute.layout<"(2,4):(1,2)">
  return %r : !cute.layout<"(2,4):(1,2)">
}

// -----

// CHECK-LABEL: func.func @fold_composition_composed_layout
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">
// CHECK-NEXT:    return %[[R]]
func.func @fold_composition_composed_layout(
    %outer: !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">,
    %inner: !cute.layout<"(2,3):(1,2)">)
    -> !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)"> {
  %r = cute.composition(%outer, %inner)
         : (!cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">,
            !cute.layout<"(2,3):(1,2)">)
        -> !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">
  return %r : !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">
}

// -----

//===----------------------------------------------------------------------===//
// coalesce
//===----------------------------------------------------------------------===//

// CHECK-LABEL: func.func @fold_coalesce_layout
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.layout<"20:1">
// CHECK-NEXT:    return %[[R]]
func.func @fold_coalesce_layout(%input: !cute.layout<"(4,5):(1,4)">)
    -> !cute.layout<"20:1"> {
  %r = cute.coalesce(%input) : (!cute.layout<"(4,5):(1,4)">) -> !cute.layout<"20:1">
  return %r : !cute.layout<"20:1">
}

// -----

// CHECK-LABEL: func.func @fold_coalesce_composed_layout
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.composed_layout<"(4,5):(1,4) o 2 o 20:1">
// CHECK-NEXT:    return %[[R]]
func.func @fold_coalesce_composed_layout(
    %input: !cute.composed_layout<"(4,5):(1,4) o 2 o (4,5):(1,4)">)
    -> !cute.composed_layout<"(4,5):(1,4) o 2 o 20:1"> {
  %r = cute.coalesce(%input)
         : (!cute.composed_layout<"(4,5):(1,4) o 2 o (4,5):(1,4)">)
        -> !cute.composed_layout<"(4,5):(1,4) o 2 o 20:1">
  return %r : !cute.composed_layout<"(4,5):(1,4) o 2 o 20:1">
}

// -----

//===----------------------------------------------------------------------===//
// complement (layout only)
//===----------------------------------------------------------------------===//

// CHECK-LABEL: func.func @fold_complement
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.layout<"2:1">
// CHECK-NEXT:    return %[[R]]
func.func @fold_complement(%input: !cute.layout<"3:2">,
                           %cotarget: !cute.shape<"6">) -> !cute.layout<"2:1"> {
  %r = cute.complement(%input, %cotarget)
         : (!cute.layout<"3:2">, !cute.shape<"6">) -> !cute.layout<"2:1">
  return %r : !cute.layout<"2:1">
}

// -----

//===----------------------------------------------------------------------===//
// group_modes
//===----------------------------------------------------------------------===//

// CHECK-LABEL: func.func @fold_group_modes_layout
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.layout<"((4,5),6):((1,4),20)">
// CHECK-NEXT:    return %[[R]]
func.func @fold_group_modes_layout(%input: !cute.layout<"(4,5,6):(1,4,20)">)
    -> !cute.layout<"((4,5),6):((1,4),20)"> {
  %r = cute.group_modes<0, 2>(%input)
         : (!cute.layout<"(4,5,6):(1,4,20)">)
        -> !cute.layout<"((4,5),6):((1,4),20)">
  return %r : !cute.layout<"((4,5),6):((1,4),20)">
}

// -----

// CHECK-LABEL: func.func @fold_group_modes_composed_layout
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.composed_layout<"(4,5):(1,4) o 2 o ((3,4),5):((1,3),12)">
// CHECK-NEXT:    return %[[R]]
func.func @fold_group_modes_composed_layout(
    %input: !cute.composed_layout<"(4,5):(1,4) o 2 o (3,4,5):(1,3,12)">)
    -> !cute.composed_layout<"(4,5):(1,4) o 2 o ((3,4),5):((1,3),12)"> {
  %r = cute.group_modes<0, 2>(%input)
         : (!cute.composed_layout<"(4,5):(1,4) o 2 o (3,4,5):(1,3,12)">)
        -> !cute.composed_layout<"(4,5):(1,4) o 2 o ((3,4),5):((1,3),12)">
  return %r : !cute.composed_layout<"(4,5):(1,4) o 2 o ((3,4),5):((1,3),12)">
}

// -----

//===----------------------------------------------------------------------===//
// recast_layout
//===----------------------------------------------------------------------===//

// CHECK-LABEL: func.func @fold_recast_layout_layout
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.layout<"(8,4):(1,8)">
// CHECK-NEXT:    return %[[R]]
func.func @fold_recast_layout_layout(%src: !cute.layout<"(32,4):(1,32)">)
    -> !cute.layout<"(8,4):(1,8)"> {
  %r = cute.recast_layout<32, 8>(%src)
         : !cute.layout<"(32,4):(1,32)"> -> !cute.layout<"(8,4):(1,8)">
  return %r : !cute.layout<"(8,4):(1,8)">
}

// -----

// CHECK-LABEL: func.func @fold_recast_layout_composed_layout
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.composed_layout<"(2,5):(1,2) o 1 o (4,4):(1,4)">
// CHECK-NEXT:    return %[[R]]
func.func @fold_recast_layout_composed_layout(
    %src: !cute.composed_layout<"(4,5):(1,4) o 2 o (8,4):(1,8)">)
    -> !cute.composed_layout<"(2,5):(1,2) o 1 o (4,4):(1,4)"> {
  %r = cute.recast_layout<32, 16>(%src)
         : !cute.composed_layout<"(4,5):(1,4) o 2 o (8,4):(1,8)">
        -> !cute.composed_layout<"(2,5):(1,2) o 1 o (4,4):(1,4)">
  return %r : !cute.composed_layout<"(2,5):(1,2) o 1 o (4,4):(1,4)">
}

// -----

//===----------------------------------------------------------------------===//
// slice
//===----------------------------------------------------------------------===//

// CHECK-LABEL: func.func @fold_slice_layout
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.layout<"(3):(2)">
// CHECK-NEXT:    return %[[R]]
func.func @fold_slice_layout(%src: !cute.layout<"(2,3,4):(1,2,6)">,
                              %crd: !cute.coord<"(0,_,1)">)
    -> !cute.layout<"(3):(2)"> {
  %r = cute.slice(%src, %crd)
         : !cute.layout<"(2,3,4):(1,2,6)">, !cute.coord<"(0,_,1)">
  return %r : !cute.layout<"(3):(2)">
}

// -----

// CHECK-LABEL: func.func @fold_slice_composed_layout
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.composed_layout<"(4,5):(1,4) o 2 o (3):(4)">
// CHECK-NEXT:    return %[[R]]
func.func @fold_slice_composed_layout(
    %src: !cute.composed_layout<"(4,5):(1,4) o 2 o (4,3):(1,4)">,
    %crd: !cute.coord<"(0,_)">)
    -> !cute.composed_layout<"(4,5):(1,4) o 2 o (3):(4)"> {
  %r = cute.slice(%src, %crd)
         : !cute.composed_layout<"(4,5):(1,4) o 2 o (4,3):(1,4)">,
           !cute.coord<"(0,_)">
  return %r : !cute.composed_layout<"(4,5):(1,4) o 2 o (3):(4)">
}

// -----

//===----------------------------------------------------------------------===//
// dice
//===----------------------------------------------------------------------===//

// CHECK-LABEL: func.func @fold_dice_layout
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.layout<"(3):(2)">
// CHECK-NEXT:    return %[[R]]
func.func @fold_dice_layout(%src: !cute.layout<"(2,3,4):(1,2,6)">,
                             %crd: !cute.coord<"(_,1,_)">)
    -> !cute.layout<"(3):(2)"> {
  %r = cute.dice(%src, %crd)
         : !cute.layout<"(2,3,4):(1,2,6)">, !cute.coord<"(_,1,_)">
  return %r : !cute.layout<"(3):(2)">
}

// -----

// CHECK-LABEL: func.func @fold_dice_composed_layout
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.composed_layout<"(4,5):(1,4) o 2 o (3):(4)">
// CHECK-NEXT:    return %[[R]]
func.func @fold_dice_composed_layout(
    %src: !cute.composed_layout<"(4,5):(1,4) o 2 o (4,3):(1,4)">,
    %crd: !cute.coord<"(_,1)">)
    -> !cute.composed_layout<"(4,5):(1,4) o 2 o (3):(4)"> {
  %r = cute.dice(%src, %crd)
         : !cute.composed_layout<"(4,5):(1,4) o 2 o (4,3):(1,4)">,
           !cute.coord<"(_,1)">
  return %r : !cute.composed_layout<"(4,5):(1,4) o 2 o (3):(4)">
}

// -----

//===----------------------------------------------------------------------===//
// Dynamic input with static-result — folds.
//===----------------------------------------------------------------------===//

// slice fixes dynamic mode 0 (coord 0); keeps static mode 1.
// CHECK-LABEL: func.func @fold_slice_dynamic_input
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.layout<"(4):(1)">
// CHECK-NEXT:    return %[[R]]
func.func @fold_slice_dynamic_input(%src: !cute.layout<"(?,4):(?,1)">,
                                     %crd: !cute.coord<"(0,_)">)
    -> !cute.layout<"(4):(1)"> {
  %r = cute.slice(%src, %crd)
         : !cute.layout<"(?,4):(?,1)">, !cute.coord<"(0,_)">
  return %r : !cute.layout<"(4):(1)">
}

// -----

// slice on a composed_layout: outer mode 0 is dynamic but the coord fixes
// it, leaving only the static mode 1.
// CHECK-LABEL: func.func @fold_slice_dynamic_input_composed_layout
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.composed_layout<"(4,5):(1,4) o 2 o (4):(1)">
// CHECK-NEXT:    return %[[R]]
func.func @fold_slice_dynamic_input_composed_layout(
    %src: !cute.composed_layout<"(4,5):(1,4) o 2 o (?,4):(?,1)">,
    %crd: !cute.coord<"(0,_)">)
    -> !cute.composed_layout<"(4,5):(1,4) o 2 o (4):(1)"> {
  %r = cute.slice(%src, %crd)
         : !cute.composed_layout<"(4,5):(1,4) o 2 o (?,4):(?,1)">,
           !cute.coord<"(0,_)">
  return %r : !cute.composed_layout<"(4,5):(1,4) o 2 o (4):(1)">
}

// -----

// dice keeps integer-marked static mode 1; drops the dynamic mode 0.
// CHECK-LABEL: func.func @fold_dice_dynamic_input
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.layout<"(4):(1)">
// CHECK-NEXT:    return %[[R]]
func.func @fold_dice_dynamic_input(%src: !cute.layout<"(?,4):(?,1)">,
                                    %crd: !cute.coord<"(_,1)">)
    -> !cute.layout<"(4):(1)"> {
  %r = cute.dice(%src, %crd)
         : !cute.layout<"(?,4):(?,1)">, !cute.coord<"(_,1)">
  return %r : !cute.layout<"(4):(1)">
}

// -----

// dice on a composed_layout: the dynamic outer mode 0 is dropped; only the
// static mode 1 survives.
// CHECK-LABEL: func.func @fold_dice_dynamic_input_composed_layout
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.composed_layout<"(4,5):(1,4) o 2 o (4):(1)">
// CHECK-NEXT:    return %[[R]]
func.func @fold_dice_dynamic_input_composed_layout(
    %src: !cute.composed_layout<"(4,5):(1,4) o 2 o (?,4):(?,1)">,
    %crd: !cute.coord<"(_,1)">)
    -> !cute.composed_layout<"(4,5):(1,4) o 2 o (4):(1)"> {
  %r = cute.dice(%src, %crd)
         : !cute.composed_layout<"(4,5):(1,4) o 2 o (?,4):(?,1)">,
           !cute.coord<"(_,1)">
  return %r : !cute.composed_layout<"(4,5):(1,4) o 2 o (4):(1)">
}

// -----

//===----------------------------------------------------------------------===//
// right_inverse / left_inverse (layout only)
//===----------------------------------------------------------------------===//

// CHECK-LABEL: func.func @fold_right_inverse
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.layout<"12:1">
// CHECK-NEXT:    return %[[R]]
func.func @fold_right_inverse(%src: !cute.layout<"(4,3):(1,4)">)
    -> !cute.layout<"12:1"> {
  %r = cute.right_inverse(%src)
         : (!cute.layout<"(4,3):(1,4)">) -> !cute.layout<"12:1">
  return %r : !cute.layout<"12:1">
}

// -----

// CHECK-LABEL: func.func @fold_left_inverse
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.layout<"(3,4):(4,1)">
// CHECK-NEXT:    return %[[R]]
func.func @fold_left_inverse(%src: !cute.layout<"(4,3):(3,1)">)
    -> !cute.layout<"(3,4):(4,1)"> {
  %r = cute.left_inverse(%src)
         : (!cute.layout<"(4,3):(3,1)">) -> !cute.layout<"(3,4):(4,1)">
  return %r : !cute.layout<"(3,4):(4,1)">
}
