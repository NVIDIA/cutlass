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

// Full pipeline lowering for `cute.append_to_rank`.

// -----
// CHECK-LABEL: func.func @append_shape
// CHECK-SAME:    [[T:%.+]]: !llvm.struct<(i32, i32)>
// CHECK-SAME:    [[X:%.+]]: !llvm.struct<()>
// CHECK:         llvm.extractvalue [[T]][0]
// CHECK:         llvm.extractvalue [[T]][1]
// CHECK:         ub.poison : !llvm.struct<(i32, i32)>
// CHECK-COUNT-2: llvm.insertvalue
// CHECK:         return
func.func @append_shape(
  %arg0 : !cute.shape<"(?,?)">,
  %arg1 : !cute.shape<"1">
) -> !cute.shape<"(?,?,1,1)">
{
  %res = cute.append_to_rank<4>(%arg0, %arg1)
       : !cute.shape<"(?,?)">, !cute.shape<"1">
  return %res : !cute.shape<"(?,?,1,1)">
}

// -----
// Layout: input is a nested struct (shape inner + stride inner). New
// rebuilds the inner shape, inner stride, and outer layout structs each
// with their own ub.poison + insertvalue chain.
// CHECK-LABEL: func.func @append_layout
// CHECK-SAME:    [[T:%.+]]: !llvm.struct<(struct<(i32, i32, i32)>, struct<(i32, i32)>)>
// CHECK-COUNT-5: llvm.extractvalue [[T]]
// CHECK:         ub.poison : !llvm.struct<(i32, i32, i32)>
// CHECK-COUNT-3: llvm.insertvalue
// CHECK:         ub.poison : !llvm.struct<(i32, i32)>
// CHECK-COUNT-2: llvm.insertvalue
// CHECK:         ub.poison : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i32, i32)>)>
// CHECK-COUNT-2: llvm.insertvalue
// CHECK:         return
func.func @append_layout(
  %arg0 : !cute.layout<"(?,?,?):(?,?,1)">,
  %arg1 : !cute.layout<"1:0">
) -> !cute.layout<"(?,?,?,1):(?,?,1,0)">
{
  %res = cute.append_to_rank<4>(%arg0, %arg1)
       : !cute.layout<"(?,?,?):(?,?,1)">, !cute.layout<"1:0">
  return %res : !cute.layout<"(?,?,?,1):(?,?,1,0)">
}

// -----
// Composed layout with a fully-static B: cute-fold-static collapses to
// cute.static, which cute-to-base lowers to a single ub.poison (all
// information lives in the type alone).
// CHECK-LABEL: func.func @append_composed_layout
// CHECK:         ub.poison
// CHECK-NEXT:    return
func.func @append_composed_layout(
  %arg0 : !cute.composed_layout<"S<1,4,3> o 5 o (1,2):(3,4)">,
  %arg1 : !cute.layout<"(1,2):(1,0)">
) -> !cute.composed_layout<"S<1,4,3> o 5 o (1,2,(1,2),(1,2)):(3,4,(1,0),(1,0))">
{
  %res = cute.append_to_rank<4>(%arg0, %arg1)
       : !cute.composed_layout<"S<1,4,3> o 5 o (1,2):(3,4)">,
         !cute.layout<"(1,2):(1,0)">
  return %res : !cute.composed_layout<"S<1,4,3> o 5 o (1,2,(1,2),(1,2)):(3,4,(1,0),(1,0))">
}
