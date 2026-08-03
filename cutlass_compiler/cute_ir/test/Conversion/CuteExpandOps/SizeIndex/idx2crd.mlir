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

// RUN: cute-opt -cute-expand-ops --split-input-file %s | FileCheck %s

// Tests `cute-expand-ops` lowering for `cute.idx2crd`.

// -----

// CHECK-LABEL: func.func @expand_static
// CHECK-NOT:   cute.idx2crd
// CHECK:       cute.static : !cute.coord<"(1,2)">
func.func @expand_static(%idx: !cute.int_tuple<"9">,
                          %sh: !cute.shape<"(4,8)">)
    -> !cute.coord<"(1,2)"> {
  %r = cute.idx2crd(%idx, %sh)
         : (!cute.int_tuple<"9">, !cute.shape<"(4,8)">)
        -> !cute.coord<"(1,2)">
  return %r : !cute.coord<"(1,2)">
}

// -----

// Dynamic index, static shape — coord computed via arith.
// CHECK-LABEL: func.func @expand_dynamic_index
// CHECK-NOT:   cute.idx2crd
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       arith.remsi
// CHECK:       cute.make_coord
// CHECK-SAME:  -> !cute.coord<"(?,?)">
func.func @expand_dynamic_index(%idx: !cute.int_tuple<"?">,
                                 %sh: !cute.shape<"(4,8)">)
    -> !cute.coord<"(?,?)"> {
  %r = cute.idx2crd(%idx, %sh)
         : (!cute.int_tuple<"?">, !cute.shape<"(4,8)">)
        -> !cute.coord<"(?,?)">
  return %r : !cute.coord<"(?,?)">
}

// -----

// Static index, dynamic extent: coord becomes all-dynamic.
// CHECK-LABEL: func.func @expand_dynamic_extent
// CHECK-NOT:   cute.idx2crd
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_coord
// CHECK-SAME:  -> !cute.coord<"(?,?)">
func.func @expand_dynamic_extent(%idx: !cute.int_tuple<"9">,
                                  %sh: !cute.shape<"(?,8)">)
    -> !cute.coord<"(?,?)"> {
  %r = cute.idx2crd(%idx, %sh)
         : (!cute.int_tuple<"9">, !cute.shape<"(?,8)">)
        -> !cute.coord<"(?,?)">
  return %r : !cute.coord<"(?,?)">
}

// -----

// Rank-1 scalar shape with dynamic index: coord is the index, no divsi/remsi.
// CHECK-LABEL: func.func @expand_scalar_shape_dynamic
// CHECK-NOT:   cute.idx2crd
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK-NOT:   arith.divsi
// CHECK-NOT:   arith.remsi
// CHECK:       cute.make_coord
// CHECK-SAME:  -> !cute.coord<"?">
func.func @expand_scalar_shape_dynamic(%idx: !cute.int_tuple<"?">,
                                       %sh: !cute.shape<"5">)
    -> !cute.coord<"?"> {
  %r = cute.idx2crd(%idx, %sh)
         : (!cute.int_tuple<"?">, !cute.shape<"5">) -> !cute.coord<"?">
  return %r : !cute.coord<"?">
}

// -----

// Nested shape with dynamic index.
// CHECK-LABEL: func.func @expand_nested_shape_dynamic
// CHECK-NOT:   cute.idx2crd
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       arith.divsi
// CHECK:       arith.remsi
// CHECK:       arith.divsi
// CHECK:       arith.remsi
// CHECK:       cute.make_coord
// CHECK-SAME:  -> !cute.coord<"(?,(?,?))">
func.func @expand_nested_shape_dynamic(%idx: !cute.int_tuple<"?">,
                                       %sh: !cute.shape<"(4,(2,3))">)
    -> !cute.coord<"(?,(?,?))"> {
  %r = cute.idx2crd(%idx, %sh)
         : (!cute.int_tuple<"?">, !cute.shape<"(4,(2,3))">)
        -> !cute.coord<"(?,(?,?))">
  return %r : !cute.coord<"(?,(?,?))">
}

// -----

// Tuple index matching shape rank: no arith ops.
// CHECK-LABEL: func.func @expand_tuple_passthrough
// CHECK-NOT:   cute.idx2crd
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK-NOT:   arith.divsi
// CHECK-NOT:   arith.remsi
// CHECK:       cute.make_coord
// CHECK-SAME:  -> !cute.coord<"(?,?)">
func.func @expand_tuple_passthrough(%idx: !cute.int_tuple<"(?,?)">,
                                    %sh: !cute.shape<"(4,8)">)
    -> !cute.coord<"(?,?)"> {
  %r = cute.idx2crd(%idx, %sh)
         : (!cute.int_tuple<"(?,?)">, !cute.shape<"(4,8)">)
        -> !cute.coord<"(?,?)">
  return %r : !cute.coord<"(?,?)">
}

// -----

// Empty shape `()`: static fold via `cute.static`.
// CHECK-LABEL: func.func @expand_empty_shape
// CHECK-NOT:   cute.idx2crd
// CHECK:       cute.static : !cute.coord<"()">
func.func @expand_empty_shape(%idx: !cute.int_tuple<"0">,
                              %sh: !cute.shape<"()">)
    -> !cute.coord<"()"> {
  %r = cute.idx2crd(%idx, %sh)
         : (!cute.int_tuple<"0">, !cute.shape<"()">) -> !cute.coord<"()">
  return %r : !cute.coord<"()">
}

