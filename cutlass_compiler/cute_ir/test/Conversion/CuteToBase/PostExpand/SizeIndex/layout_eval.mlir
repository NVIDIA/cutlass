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

// Full pipeline lowering for `cute.layout_eval`.

// -----
// Static coord and static layout: index resolved at compile time.
// CHECK-LABEL: func.func @layout_eval_static
// CHECK:         ub.poison : !llvm.struct<()>
// CHECK-NEXT:    return
func.func @layout_eval_static(%c: !cute.coord<"(1,2)">, %l: !cute.layout<"(4,8):(1,4)">)
    -> !cute.int_tuple<"9"> {
  %r = cute.layout_eval(%c, %l) : (!cute.coord<"(1,2)">, !cute.layout<"(4,8):(1,4)">) -> !cute.int_tuple<"9">
  return %r : !cute.int_tuple<"9">
}

// -----
// Dynamic coord, static layout.
// CHECK-LABEL: func.func @layout_eval_dyn_coord
// CHECK-SAME:    [[C:%.+]]: !llvm.struct<(i32, i32)>
// CHECK:         [[C0:%.+]] = llvm.extractvalue [[C]][0]
// CHECK:         [[C1:%.+]] = llvm.extractvalue [[C]][1]
// CHECK:         arith.constant 4 : i32
// CHECK:         arith.muli {{.+}}, {{.+}} overflow<nsw> : i32
// CHECK:         arith.addi {{.+}}, {{.+}} overflow<nsw> : i32
// CHECK:         return {{.+}} : i32
func.func @layout_eval_dyn_coord(%c: !cute.coord<"(?,?)">, %l: !cute.layout<"(4,8):(1,4)">)
    -> !cute.int_tuple<"?"> {
  %r = cute.layout_eval(%c, %l) : (!cute.coord<"(?,?)">, !cute.layout<"(4,8):(1,4)">) -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}

// -----
// Fully dynamic coord and layout.
// CHECK-LABEL: func.func @layout_eval_dyn_layout
// CHECK-SAME:    [[C:%.+]]: !llvm.struct<(i32, i32)>, [[L:%.+]]: !llvm.struct<(struct<(i32, i32)>, struct<(i32, i32)>)>
// CHECK:         llvm.extractvalue [[C]][0]
// CHECK:         llvm.extractvalue [[C]][1]
// CHECK:         llvm.extractvalue [[L]][1, 0]
// CHECK:         llvm.extractvalue [[L]][1, 1]
// CHECK:         arith.muli {{.+}} overflow<nsw> : i32
// CHECK:         arith.muli {{.+}} overflow<nsw> : i32
// CHECK:         arith.addi {{.+}} overflow<nsw> : i32
// CHECK:         return {{.+}} : i32
func.func @layout_eval_dyn_layout(%c: !cute.coord<"(?,?)">, %l: !cute.layout<"(?,?):(?,?)">)
    -> !cute.int_tuple<"?"> {
  %r = cute.layout_eval(%c, %l) : (!cute.coord<"(?,?)">, !cute.layout<"(?,?):(?,?)">) -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}

// -----
// Static layout with underscore coord — result is static zero.
// CHECK-LABEL: func.func @layout_eval_plain_layout_underscore_coord
// CHECK-NOT:     cute.layout_eval
// CHECK-NOT:     arith.muli
// CHECK-NOT:     arith.addi
// CHECK:         %[[P:.+]] = ub.poison : !llvm.struct<()>
// CHECK:         return %[[P]]
func.func @layout_eval_plain_layout_underscore_coord(
    %c: !cute.coord<"(_)">, %l: !cute.layout<"(8):(1)">)
    -> !cute.int_tuple<"0"> {
  %r = cute.layout_eval(%c, %l) : (!cute.coord<"(_)">, !cute.layout<"(8):(1)">)
                              -> !cute.int_tuple<"0">
  return %r : !cute.int_tuple<"0">
}

// -----
// Static negative coord — result folds at compile time.
// CHECK-LABEL: func.func @layout_eval_static_negative_coord
// CHECK-NOT:     cute.layout_eval
// CHECK-NOT:     arith.muli
// CHECK-NOT:     arith.addi
// CHECK:         %[[P:.+]] = ub.poison : !llvm.struct<()>
// CHECK:         return %[[P]]
func.func @layout_eval_static_negative_coord(
    %c: !cute.coord<"(_,(-1,0),0)">,
    %l: !cute.layout<"(32,(16384,64),1):(1,(32,524288),0)">)
    -> !cute.int_tuple<"-32"> {
  %r = cute.layout_eval(%c, %l)
       : (!cute.coord<"(_,(-1,0),0)">,
          !cute.layout<"(32,(16384,64),1):(1,(32,524288),0)">)
      -> !cute.int_tuple<"-32">
  return %r : !cute.int_tuple<"-32">
}
