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

// RUN: cute-opt -cute-to-base --split-input-file %s | FileCheck %s

// Tests `cute-to-base` lowering for `cute.make_layout`.

// -----

// Fully static shape and stride.
// CHECK-LABEL: func.func @layout_static
// CHECK-NOT:     cute.make_layout
// CHECK:         %[[P:.+]] = ub.poison : !llvm.struct<(struct<()>, struct<()>)>
// CHECK-COUNT-2: llvm.insertvalue
// CHECK:         return
func.func @layout_static() -> !cute.layout<"(2,3):(1,2)"> {
  %s = cute.make_shape () : () -> !cute.shape<"(2,3)">
  %d = cute.make_stride () : () -> !cute.stride<"(1,2)">
  %r = cute.make_layout (%s, %d)
       : (!cute.shape<"(2,3)">, !cute.stride<"(1,2)">) -> !cute.layout<"(2,3):(1,2)">
  return %r : !cute.layout<"(2,3):(1,2)">
}

// -----

// Dynamic shape + dynamic stride leaf (single dyn each).
// CHECK-LABEL: func.func @layout_explicit_dyn
// CHECK-SAME:    (%[[A:.+]]: i32, %[[B:.+]]: i32)
// CHECK-NOT:     cute.make_layout
// CHECK:         %[[P:.+]] = ub.poison : !llvm.struct<(i32, i32)>
// CHECK:         %[[V0:.+]] = llvm.insertvalue %[[A]], %[[P]][0]
// CHECK:         %[[V1:.+]] = llvm.insertvalue %[[B]], %[[V0]][1]
// CHECK:         return
func.func @layout_explicit_dyn(%a: i32, %b: i32) -> !cute.layout<"(?,4):(?,1)"> {
  %s = cute.make_shape (%a) : (i32) -> !cute.shape<"(?,4)">
  %st = cute.make_stride (%b) : (i32) -> !cute.stride<"(?,1)">
  %r = cute.make_layout (%s, %st)
       : (!cute.shape<"(?,4)">, !cute.stride<"(?,1)">) -> !cute.layout<"(?,4):(?,1)">
  return %r : !cute.layout<"(?,4):(?,1)">
}

// -----

// Dynamic shape + fully-static stride.
// CHECK-LABEL: func.func @layout_dyn_shape_static_stride
// CHECK-SAME:    (%[[A:.+]]: i32)
// CHECK-NOT:     cute.make_layout
// CHECK:         %[[P:.+]] = ub.poison : !llvm.struct<(i32, struct<()>)>
// CHECK:         %[[V0:.+]] = llvm.insertvalue %[[A]], %[[P]][0]
// CHECK:         %[[V1:.+]] = llvm.insertvalue %{{.+}}, %[[V0]][1]
// CHECK:         return
func.func @layout_dyn_shape_static_stride(%a: i32)
    -> !cute.layout<"(?,4):(4,1)"> {
  %s = cute.make_shape (%a) : (i32) -> !cute.shape<"(?,4)">
  %st = cute.make_stride () : () -> !cute.stride<"(4,1)">
  %r = cute.make_layout (%s, %st)
       : (!cute.shape<"(?,4)">, !cute.stride<"(4,1)">) -> !cute.layout<"(?,4):(4,1)">
  return %r : !cute.layout<"(?,4):(4,1)">
}

// -----

// Dynamic-scale scaled-basis stride `?@0`.
// CHECK-LABEL: func.func @layout_dyn_basis_stride
// CHECK-SAME:    (%[[A:.+]]: i32, %[[B:.+]]: i32)
// CHECK-NOT:     cute.make_layout
// CHECK:         %[[P:.+]] = ub.poison : !llvm.struct<(i32, i32)>
// CHECK:         %[[V0:.+]] = llvm.insertvalue %[[A]], %[[P]][0]
// CHECK:         %[[V1:.+]] = llvm.insertvalue %[[B]], %[[V0]][1]
// CHECK:         return
func.func @layout_dyn_basis_stride(%a: i32, %b: i32)
    -> !cute.layout<"(?,3):(?@0,1@1)"> {
  %s = cute.make_shape (%a) : (i32) -> !cute.shape<"(?,3)">
  %st = cute.make_stride (%b) : (i32) -> !cute.stride<"(?@0,1@1)">
  %r = cute.make_layout (%s, %st)
       : (!cute.shape<"(?,3)">, !cute.stride<"(?@0,1@1)">) -> !cute.layout<"(?,3):(?@0,1@1)">
  return %r : !cute.layout<"(?,3):(?@0,1@1)">
}

// -----

// Static shape + scaled-basis stride with one dynamic scale.
// CHECK-LABEL: func.func @layout_static_shape_dyn_basis_stride
// CHECK-SAME:    (%[[A:.+]]: i32)
// CHECK-NOT:     cute.make_layout
// CHECK:         %[[P:.+]] = ub.poison : !llvm.struct<(struct<()>, i32)>
// CHECK:         %[[V0:.+]] = llvm.insertvalue %{{.+}}, %[[P]][0]
// CHECK:         %[[V1:.+]] = llvm.insertvalue %[[A]], %[[V0]][1]
// CHECK:         return
func.func @layout_static_shape_dyn_basis_stride(%a: i32)
    -> !cute.layout<"(2,3):(?@0,1@1)"> {
  %s = cute.make_shape () : () -> !cute.shape<"(2,3)">
  %st = cute.make_stride (%a) : (i32) -> !cute.stride<"(?@0,1@1)">
  %r = cute.make_layout (%s, %st)
       : (!cute.shape<"(2,3)">, !cute.stride<"(?@0,1@1)">) -> !cute.layout<"(2,3):(?@0,1@1)">
  return %r : !cute.layout<"(2,3):(?@0,1@1)">
}

// -----

// Dynamic shape + mixed static/dynamic-scale basis stride `(1@0,?@1)`.
// CHECK-LABEL: func.func @layout_mixed_basis_stride
// CHECK-SAME:    (%[[A:.+]]: i32, %[[B:.+]]: i32)
// CHECK-NOT:     cute.make_layout
// CHECK:         %[[P:.+]] = ub.poison : !llvm.struct<(i32, i32)>
// CHECK:         %[[V0:.+]] = llvm.insertvalue %[[A]], %[[P]][0]
// CHECK:         %[[V1:.+]] = llvm.insertvalue %[[B]], %[[V0]][1]
// CHECK:         return
func.func @layout_mixed_basis_stride(%a: i32, %b: i32)
    -> !cute.layout<"(?,3):(1@0,?@1)"> {
  %s = cute.make_shape (%a) : (i32) -> !cute.shape<"(?,3)">
  %st = cute.make_stride (%b) : (i32) -> !cute.stride<"(1@0,?@1)">
  %r = cute.make_layout (%s, %st)
       : (!cute.shape<"(?,3)">, !cute.stride<"(1@0,?@1)">) -> !cute.layout<"(?,3):(1@0,?@1)">
  return %r : !cute.layout<"(?,3):(1@0,?@1)">
}

// -----

// Depth-2 hierarchical basis stride `(?@0@0,?@1@0)`.
// CHECK-LABEL: func.func @layout_hierarchical_basis_stride
// CHECK-SAME:    (%[[A:.+]]: i32, %[[B:.+]]: i32)
// CHECK-NOT:     cute.make_layout
// CHECK:         ub.poison : !llvm.struct<(i32, i32)>
// CHECK-DAG:     llvm.insertvalue %[[A]],
// CHECK-DAG:     llvm.insertvalue %[[B]],
// CHECK:         ub.poison : !llvm.struct<(struct<()>, struct<(i32, i32)>)>
// CHECK-COUNT-2: llvm.insertvalue
// CHECK:         return %{{.+}} : !llvm.struct<(struct<()>, struct<(i32, i32)>)>
func.func @layout_hierarchical_basis_stride(%a: i32, %b: i32)
    -> !cute.layout<"(2,3):(?@0@0,?@1@0)"> {
  %s = cute.make_shape () : () -> !cute.shape<"(2,3)">
  %st = cute.make_stride (%a, %b) : (i32, i32) -> !cute.stride<"(?@0@0,?@1@0)">
  %r = cute.make_layout (%s, %st)
       : (!cute.shape<"(2,3)">, !cute.stride<"(?@0@0,?@1@0)">) -> !cute.layout<"(2,3):(?@0@0,?@1@0)">
  return %r : !cute.layout<"(2,3):(?@0@0,?@1@0)">
}

// -----

// Rank-1 scalar dynamic shape and stride (`?:?`).
// CHECK-LABEL: func.func @layout_rank1_scalar
// CHECK-SAME:    (%[[A:.+]]: i32, %[[B:.+]]: i32)
// CHECK-NOT:     cute.make_layout
// CHECK:         %[[P:.+]] = ub.poison : !llvm.struct<(i32, i32)>
// CHECK:         %[[V0:.+]] = llvm.insertvalue %[[A]], %[[P]][0]
// CHECK:         %[[V1:.+]] = llvm.insertvalue %[[B]], %[[V0]][1]
// CHECK:         return
func.func @layout_rank1_scalar(%a: i32, %b: i32) -> !cute.layout<"?:?"> {
  %s = cute.make_shape (%a) : (i32) -> !cute.shape<"?">
  %st = cute.make_stride (%b) : (i32) -> !cute.stride<"?">
  %r = cute.make_layout (%s, %st) : (!cute.shape<"?">, !cute.stride<"?">) -> !cute.layout<"?:?">
  return %r : !cute.layout<"?:?">
}

// -----

// Nested rank-2 shape with all-dynamic leaves.
// CHECK-LABEL: func.func @layout_nested_2op_dyn
// CHECK-SAME:    (%[[S:.+]]: !llvm.struct<(i32, i32, i32)>, %[[D:.+]]: !llvm.struct<(i32, i32, i32)>)
// CHECK-NOT:     cute.make_layout
// CHECK:         %[[P:.+]] = ub.poison : !llvm.struct<(struct<(i32, i32, i32)>, struct<(i32, i32, i32)>)>
// CHECK:         %[[V0:.+]] = llvm.insertvalue %[[S]], %[[P]][0]
// CHECK:         %[[V1:.+]] = llvm.insertvalue %[[D]], %[[V0]][1]
// CHECK:         return
func.func @layout_nested_2op_dyn(
    %s: !cute.shape<"(?,(?,?))">,
    %d: !cute.stride<"(?,(?,?))">
) -> !cute.layout<"(?,(?,?)):(?,(?,?))"> {
  %r = cute.make_layout (%s, %d)
       : (!cute.shape<"(?,(?,?))">, !cute.stride<"(?,(?,?))">) -> !cute.layout<"(?,(?,?)):(?,(?,?))">
  return %r : !cute.layout<"(?,(?,?)):(?,(?,?))">
}
