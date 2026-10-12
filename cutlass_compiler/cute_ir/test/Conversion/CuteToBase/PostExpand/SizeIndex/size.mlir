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

// Full pipeline lowering for `cute.size`.

// -----
// Fully-static shape.
// CHECK-LABEL: func.func @size_shape_static
// CHECK:         ub.poison : !llvm.struct<()>
// CHECK-NEXT:    return
func.func @size_shape_static(%arg0: !cute.shape<"(5,2)">) -> !cute.int_tuple<"10"> {
  %0 = cute.size(%arg0) : (!cute.shape<"(5,2)">) -> !cute.int_tuple<"10">
  return %0 : !cute.int_tuple<"10">
}

// -----
// Dynamic-leaf shape: cute.size becomes `arith.muli dyn, 5` on i32.
// CHECK-LABEL: func.func @size_shape_dynamic
// CHECK-SAME:    [[ARG:%.+]]: i32
// CHECK:         [[C5:%.+]] = arith.constant 5 : i32
// CHECK:         [[R:%.+]] = arith.muli [[ARG]], [[C5]] overflow<nsw> : i32
// CHECK:         return [[R]] : i32
func.func @size_shape_dynamic(%arg0: !cute.shape<"(5,?)">)
    -> !cute.int_tuple<"?"> {
  %0 = cute.size(%arg0) : (!cute.shape<"(5,?)">) -> !cute.int_tuple<"?">
  return %0 : !cute.int_tuple<"?">
}

// -----
// Dynamic int_tuple with nested static factors.
// the static factors (3, 7) on the dynamic leaf.
// CHECK-LABEL: func.func @size_tuple_dynamic
// CHECK-SAME:    [[ARG:%.+]]: i32
// CHECK-COUNT-2: arith.muli {{.+}} overflow<nsw> : i32
// CHECK-NOT:     arith.muli
// CHECK:         return
func.func @size_tuple_dynamic(%arg0: !cute.int_tuple<"(?,(3,7))">)
    -> !cute.int_tuple<"?"> {
  %0 = cute.size(%arg0)
      : (!cute.int_tuple<"(?,(3,7))">) -> !cute.int_tuple<"?">
  return %0 : !cute.int_tuple<"?">
}

// -----
// Fully-static layout: cute.size folds to a static int_tuple, which
// cute-to-base lowers to a single ub.poison.
// CHECK-LABEL: func.func @size_layout_static
// CHECK:         ub.poison : !llvm.struct<()>
// CHECK-NEXT:    return
func.func @size_layout_static(%arg0: !cute.layout<"(5):(1)">)
    -> !cute.int_tuple<"5"> {
  %0 = cute.size(%arg0) : (!cute.layout<"(5):(1)">) -> !cute.int_tuple<"5">
  return %0 : !cute.int_tuple<"5">
}

// -----
// Dynamic layout: input arrives as `!llvm.struct<(i32, i32)>` (one i32 for
// the dynamic shape leaf, one for the dynamic stride). cute.size extracts
// the shape leaf and multiplies by the static factor 5.
// CHECK-LABEL: func.func @size_layout_dynamic
// CHECK-SAME:    [[ARG:%.+]]: !llvm.struct<(i32, i32)>
// CHECK:         [[SHAPE:%.+]] = llvm.extractvalue [[ARG]][0]
// CHECK:         [[C5:%.+]] = arith.constant 5 : i32
// CHECK:         [[R:%.+]] = arith.muli [[SHAPE]], [[C5]] overflow<nsw> : i32
// CHECK:         return [[R]] : i32
func.func @size_layout_dynamic(%arg0: !cute.layout<"(5,?):(1,?)">)
    -> !cute.int_tuple<"?"> {
  %0 = cute.size(%arg0)
      : (!cute.layout<"(5,?):(1,?)">) -> !cute.int_tuple<"?">
  return %0 : !cute.int_tuple<"?">
}

// -----
// Layout with mode `[3]` over a deeply-nested layout: the sub-shape at
// mode 3 is `((4,?),1)`, whose size = 4 * ? * 1 = `?`. The
// pipeline extracts the dynamic leaf and multiplies by the static 4.
// CHECK-LABEL: func.func @size_layout_dynamic_with_mode
// CHECK-SAME:    [[ARG:%.+]]: !llvm.struct
// CHECK:         [[DYN:%.+]] = llvm.extractvalue [[ARG]]
// CHECK:         [[C4:%.+]] = arith.constant 4 : i32
// CHECK:         [[R:%.+]] = arith.muli [[DYN]], [[C4]] overflow<nsw> : i32
// CHECK:         return [[R]] : i32
func.func @size_layout_dynamic_with_mode(
    %arg0: !cute.layout<"(5,2,(3,7),((4,?),1)):(1,2,(0,0),((3,?),?))">)
    -> !cute.int_tuple<"?"> {
  %0 = cute.size<[3]>(%arg0)
      : (!cute.layout<"(5,2,(3,7),((4,?),1)):(1,2,(0,0),((3,?),?))">)
     -> !cute.int_tuple<"?">
  return %0 : !cute.int_tuple<"?">
}
