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

// Full pipeline lowering for `cute.cosize`.

// -----
// Fully-static layout.
// CHECK-LABEL: func.func @cosize_layout_static
// CHECK:         ub.poison : !llvm.struct<()>
// CHECK-NEXT:    return
func.func @cosize_layout_static(%arg0: !cute.layout<"(4,3,2):(1,4,12)">)
    -> !cute.int_tuple<"24"> {
  %0 = cute.cosize(%arg0)
      : (!cute.layout<"(4,3,2):(1,4,12)">) -> !cute.int_tuple<"24">
  return %0 : !cute.int_tuple<"24">
}

// -----
// Static layout + mode: cosize on the picked sub-layout still folds.
// CHECK-LABEL: func.func @cosize_layout_static_mode
// CHECK:         ub.poison : !llvm.struct<()>
// CHECK-NEXT:    return
func.func @cosize_layout_static_mode(%arg0: !cute.layout<"(4,3,2):(1,4,12)">)
    -> !cute.int_tuple<"9"> {
  %0 = cute.cosize<[1]>(%arg0)
      : (!cute.layout<"(4,3,2):(1,4,12)">) -> !cute.int_tuple<"9">
  return %0 : !cute.int_tuple<"9">
}

// -----
// Fully-dynamic flat layout: cute.cosize lowers to a chain of extractvalue
// for the dynamic shape (3 leaves) and stride (3 leaves), three `math.absi`
// over the stride leaves, then arith.muli/divsi/remsi/addi computing
// `Σ (d_i - 1)*|s_i| + 1`.
// CHECK-LABEL: func.func @cosize_layout_dynamic
// CHECK-SAME:    [[ARG:%.+]]: !llvm.struct
// CHECK-COUNT-6: llvm.extractvalue [[ARG]]
// CHECK-COUNT-3: math.absi {{.+}} : i32
// CHECK-NOT:     math.absi
// CHECK:         arith.constant -1 : i32
// CHECK:         arith.constant 1 : i32
// CHECK:         return {{.+}} : i32
func.func @cosize_layout_dynamic(%arg0: !cute.layout<"(?,?,?):(?,?,?)">)
    -> !cute.int_tuple<"?"> {
  %0 = cute.cosize(%arg0)
      : (!cute.layout<"(?,?,?):(?,?,?)">) -> !cute.int_tuple<"?">
  return %0 : !cute.int_tuple<"?">
}

// -----
// Dynamic layout + mode `[1]`: only one sub-layout's leaves are needed, so
// the chain reduces to a single `math.absi` on the picked stride, plus
// `(d - 1) * |s| + 1`.
// CHECK-LABEL: func.func @cosize_layout_dynamic_mode
// CHECK-SAME:    [[ARG:%.+]]: !llvm.struct
// CHECK:         [[D:%.+]] = llvm.extractvalue [[ARG]][0, 1]
// CHECK:         [[S:%.+]] = llvm.extractvalue [[ARG]][1, 1]
// CHECK:         [[ABS:%.+]] = math.absi [[S]] : i32
// CHECK:         [[CM1:%.+]] = arith.constant -1 : i32
// CHECK:         [[DM1:%.+]] = arith.addi [[D]], [[CM1]] overflow<nsw> : i32
// CHECK:         [[MUL:%.+]] = arith.muli [[DM1]], [[ABS]] overflow<nsw> : i32
// CHECK:         [[C1:%.+]] = arith.constant 1 : i32
// CHECK:         [[R:%.+]] = arith.addi [[MUL]], [[C1]] overflow<nsw> : i32
// CHECK:         return [[R]] : i32
func.func @cosize_layout_dynamic_mode(%arg0: !cute.layout<"(?,?,?):(?,?,?)">)
    -> !cute.int_tuple<"?"> {
  %0 = cute.cosize<[1]>(%arg0)
      : (!cute.layout<"(?,?,?):(?,?,?)">) -> !cute.int_tuple<"?">
  return %0 : !cute.int_tuple<"?">
}

// -----
// Fully-static swizzle-composed layout: cute.cosize folds.
// CHECK-LABEL: func.func @cosize_composed_static
// CHECK:         ub.poison : !llvm.struct<()>
// CHECK-NEXT:    return
func.func @cosize_composed_static(
    %arg0: !cute.composed_layout<"S<3,4,6> o 0 o (3,4):(4,1)">)
    -> !cute.int_tuple<"12"> {
  %0 = cute.cosize(%arg0)
      : (!cute.composed_layout<"S<3,4,6> o 0 o (3,4):(4,1)">)
     -> !cute.int_tuple<"12">
  return %0 : !cute.int_tuple<"12">
}

// -----
// Swizzle-composed dynamic outer: cute.cosize over the outer-B layout,
// emitting math.absi + arith chain over the dynamic leaves.
// CHECK-LABEL: func.func @cosize_composed_dynamic
// CHECK-SAME:    [[ARG:%.+]]: !llvm.struct
// CHECK:         llvm.extractvalue [[ARG]]
// CHECK:         math.absi
// CHECK:         arith.constant 1 : i32
// CHECK:         return {{.+}} : i32
func.func @cosize_composed_dynamic(
    %arg0: !cute.composed_layout<"S<3,5,4> o 0 o (?,?):(?,?)">)
    -> !cute.int_tuple<"?"> {
  %0 = cute.cosize(%arg0)
      : (!cute.composed_layout<"S<3,5,4> o 0 o (?,?):(?,?)">)
     -> !cute.int_tuple<"?">
  return %0 : !cute.int_tuple<"?">
}
