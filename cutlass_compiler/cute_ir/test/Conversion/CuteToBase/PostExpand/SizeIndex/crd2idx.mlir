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

// Full pipeline lowering for `cute.crd2idx`.

// -----
// Static coord and static shape.
// CHECK-LABEL: func.func @crd2idx_static
// CHECK:         ub.poison : !llvm.struct<()>
// CHECK-NEXT:    return
func.func @crd2idx_static(%c: !cute.coord<"(1,2)">, %s: !cute.shape<"(4,8)">)
    -> !cute.int_tuple<"9"> {
  %r = cute.crd2idx(%c, %s)
         : (!cute.coord<"(1,2)">, !cute.shape<"(4,8)">) -> !cute.int_tuple<"9">
  return %r : !cute.int_tuple<"9">
}

// -----
// Dynamic coord, static shape.
// The first mode's prefix product is 1 so its multiply is implicit.
// CHECK-LABEL: func.func @crd2idx_dyn_coord
// CHECK-SAME:    [[C:%.+]]: !llvm.struct<(i32, i32)>
// CHECK:         [[C0:%.+]] = llvm.extractvalue [[C]][0]
// CHECK:         [[C1:%.+]] = llvm.extractvalue [[C]][1]
// CHECK:         arith.constant 4 : i32
// CHECK:         arith.muli {{.+}}, {{.+}} overflow<nsw> : i32
// CHECK:         arith.addi {{.+}}, {{.+}} overflow<nsw> : i32
// CHECK:         return {{.+}} : i32
func.func @crd2idx_dyn_coord(%c: !cute.coord<"(?,?)">,
                             %s: !cute.shape<"(4,8)">)
    -> !cute.int_tuple<"?"> {
  %r = cute.crd2idx(%c, %s)
         : (!cute.coord<"(?,?)">, !cute.shape<"(4,8)">) -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}

// -----
// Static coord, dynamic shape: an unknown extent propagates into the
// column-major weighting, so the result is dynamic. With coord = (1,2)
// and shape = (?,8), the result is 1 + 2*? — one arith.muli + arith.addi.
// Only the dynamic extent of `shape` is passed at the LLVM boundary (the
// fully-static coord lowers to an empty struct), so the second arg is i32.
// CHECK-LABEL: func.func @crd2idx_dyn_shape
// CHECK-SAME:    !llvm.struct<()>, [[S:%.+]]: i32
// CHECK:         arith.muli {{.+}} overflow<nsw> : i32
// CHECK:         arith.addi {{.+}} overflow<nsw> : i32
// CHECK:         return {{.+}} : i32
func.func @crd2idx_dyn_shape(%c: !cute.coord<"(1,2)">,
                             %s: !cute.shape<"(?,8)">)
    -> !cute.int_tuple<"?"> {
  %r = cute.crd2idx(%c, %s)
         : (!cute.coord<"(1,2)">, !cute.shape<"(?,8)">) -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}

// -----
// Fully dynamic: both coord and shape values arrive in LLVM structs; the
// prefix-product weight for mode 1 is shape[0] (dynamic) → arith.muli builds
// the weight, then another arith.muli + arith.addi combines the coord.
// CHECK-LABEL: func.func @crd2idx_dyn_both
// CHECK-SAME:    [[C:%.+]]: !llvm.struct<(i32, i32)>, [[S:%.+]]: !llvm.struct<(i32, i32)>
// CHECK:         llvm.extractvalue [[C]][0]
// CHECK:         llvm.extractvalue [[C]][1]
// CHECK:         llvm.extractvalue [[S]][0]
// CHECK:         arith.muli {{.+}} overflow<nsw> : i32
// CHECK:         arith.addi {{.+}} overflow<nsw> : i32
// CHECK:         return {{.+}} : i32
func.func @crd2idx_dyn_both(%c: !cute.coord<"(?,?)">,
                            %s: !cute.shape<"(?,?)">)
    -> !cute.int_tuple<"?"> {
  %r = cute.crd2idx(%c, %s)
         : (!cute.coord<"(?,?)">, !cute.shape<"(?,?)">) -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}

// -----
// Nested static: ((1,2),3) on ((4,8),6) → 1 + 2*4 + 3*32 = 105.
// Static result lowers to `ub.poison`.
// CHECK-LABEL: func.func @crd2idx_static_nested
// CHECK-NOT:     cute.crd2idx
// CHECK-NOT:     arith.muli
// CHECK-NOT:     arith.addi
// CHECK:         %[[P:.+]] = ub.poison : !llvm.struct<()>
// CHECK:         return %[[P]]
func.func @crd2idx_static_nested(%c: !cute.coord<"((1,2),3)">,
                                 %s: !cute.shape<"((4,8),6)">)
    -> !cute.int_tuple<"105"> {
  %r = cute.crd2idx(%c, %s)
         : (!cute.coord<"((1,2),3)">, !cute.shape<"((4,8),6)">)
        -> !cute.int_tuple<"105">
  return %r : !cute.int_tuple<"105">
}
