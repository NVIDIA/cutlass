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

// RUN: cute-opt -cute-fold-static -cute-expand-ops -cute-to-base \
// RUN:   --split-input-file %s \
// RUN:   | cute-opt -reconcile-unrealized-casts --split-input-file \
// RUN:   | FileCheck %s

// Full pipeline lowering for `cute.dice`.

// -----
// Fully-static dice: input + coord both static; folds to `ub.poison`.
// CHECK-LABEL: func.func @dice_all_static_folds_to_poison
// CHECK:         ub.poison : !llvm.struct<(struct<()>, struct<()>)>
// CHECK-NEXT:    return
func.func @dice_all_static_folds_to_poison(
    %a: !cute.layout<"(2,3,4):(1,2,6)">,
    %c: !cute.coord<"(_,1,_)">)
    -> !cute.layout<"(3):(2)"> {
  %r = cute.dice(%a, %c) : !cute.layout<"(2,3,4):(1,2,6)">, !cute.coord<"(_,1,_)">
  return %r : !cute.layout<"(3):(2)">
}

// -----
// Dynamic layout, static coord.
// CHECK-LABEL: func.func @dice_dyn_layout_extract_insert
// CHECK-SAME:    [[L:%.+]]: !llvm.struct<(i32, i32)>
// CHECK:         llvm.extractvalue [[L]][0] : !llvm.struct<(i32, i32)>
// CHECK:         ub.poison : !llvm.struct<()>
// CHECK:         ub.poison : !llvm.struct<(i32, struct<()>)>
// CHECK:         llvm.insertvalue
// CHECK:         llvm.insertvalue
// CHECK:         return
func.func @dice_dyn_layout_extract_insert(
    %a: !cute.layout<"(?,5):(1,?)">,
    %c: !cute.coord<"(1,_)">) -> !cute.layout<"(?):(1)"> {
  %r = cute.dice(%a, %c) : !cute.layout<"(?,5):(1,?)">, !cute.coord<"(1,_)">
  return %r : !cute.layout<"(?):(1)">
}

// -----
// Dynamic shape, scalar dyn leaf passes through directly.
// CHECK-LABEL: func.func @dice_shape_dyn_passthrough
// CHECK-SAME:    %[[S:.+]]: i32, {{.+}}
// CHECK-NEXT:    return %[[S]] : i32
func.func @dice_shape_dyn_passthrough(
    %a: !cute.shape<"(2,?,4)">,
    %c: !cute.coord<"(_,1,_)">) -> !cute.shape<"(?)"> {
  %r = cute.dice(%a, %c) : !cute.shape<"(2,?,4)">, !cute.coord<"(_,1,_)">
  return %r : !cute.shape<"(?)">
}

// -----
// Composed input with dynamic A, offset, and B — coord keeps mode 0 of B.
// CHECK-LABEL: func.func @dice_composed_multi_slot_dyn
// CHECK-NOT:     arith.addi
// CHECK:         %[[B_KEPT_SH:.+]] = llvm.extractvalue %{{.+}}[0, 0, 0]
// CHECK:         %[[B_KEPT_ST:.+]] = llvm.extractvalue %{{.+}}[0, 1, 0]
// CHECK:         %[[OFF:.+]] = llvm.extractvalue %{{.+}}[1] : !llvm.struct<{{.+}}, i32, {{.+}}>
// CHECK:         llvm.extractvalue %{{.+}}[2,
// CHECK:         llvm.insertvalue
// CHECK:         return
func.func @dice_composed_multi_slot_dyn(
    %a: !cute.composed_layout<"(?,?):(?,?) o ? o (?,?):(?,?)">,
    %c: !cute.coord<"(1,_)">)
    -> !cute.composed_layout<"(?,?):(?,?) o ? o (?):(?)"> {
  %r = cute.dice(%a, %c)
       : !cute.composed_layout<"(?,?):(?,?) o ? o (?,?):(?,?)">,
         !cute.coord<"(1,_)">
  return %r : !cute.composed_layout<"(?,?):(?,?) o ? o (?):(?)">
}

// -----
// Composed input with static A/offset, dynamic B outer.
// CHECK-LABEL: func.func @dice_composed_affine_dyn_outer
// CHECK-NOT:     arith.addi
// CHECK:         llvm.extractvalue %{{.+}}[0, 0]
// CHECK:         llvm.extractvalue %{{.+}}[0, 1, 0]
// CHECK:         ub.poison : !llvm.struct<(i32, i32)>
// CHECK:         llvm.insertvalue
// CHECK:         llvm.insertvalue
// CHECK:         return
func.func @dice_composed_affine_dyn_outer(
    %a: !cute.composed_layout<"(4,5):(1,4) o 2 o (?,3,4):(?,4,?)">,
    %c: !cute.coord<"(1,1,_)">)
    -> !cute.composed_layout<"(4,5):(1,4) o 2 o (?,3):(?,4)"> {
  %r = cute.dice(%a, %c)
       : !cute.composed_layout<"(4,5):(1,4) o 2 o (?,3,4):(?,4,?)">,
         !cute.coord<"(1,1,_)">
  return %r : !cute.composed_layout<"(4,5):(1,4) o 2 o (?,3):(?,4)">
}
