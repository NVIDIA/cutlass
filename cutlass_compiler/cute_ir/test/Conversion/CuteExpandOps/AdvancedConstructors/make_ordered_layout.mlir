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

// Tests `cute-expand-ops` lowering for `cute.make_ordered_layout`.

// -----

// CHECK-LABEL: func.func @expand_static
// CHECK-NOT:   cute.make_ordered_layout
// CHECK:       %[[R:.+]] = cute.static : !cute.layout<"(4,2):(1,4)">
func.func @expand_static() -> !cute.layout<"(4,2):(1,4)"> {
  %s = cute.make_shape() : () -> !cute.shape<"(4,2)">
  %o = cute.make_int_tuple() : () -> !cute.int_tuple<"(0,1)">
  %r = cute.make_ordered_layout(%s, %o)
         : (!cute.shape<"(4,2)">, !cute.int_tuple<"(0,1)">)
        -> !cute.layout<"(4,2):(1,4)">
  return %r : !cute.layout<"(4,2):(1,4)">
}

// -----

// Rank-4 dynamic shape with non-canonical order — strides require
// prefix-product computation across multiple modes, so cutegen emits
// `arith.muli` ops for each cross-mode multiplication. Order (2,1,3,4)
// maps mode 1 → stride 1, mode 0 → stride shape[1], mode 2 → stride
// shape[0]*shape[1], mode 3 → stride shape[0]*shape[1]*shape[2].
// CHECK-LABEL: func.func @expand_dynamic
// CHECK-NOT:     cute.make_ordered_layout
// CHECK:         cute.get_scalars<{only_dynamic}> (%{{.+}})
// CHECK-COUNT-3: arith.muli
// CHECK:         %[[SHAPE:.+]] = cute.make_shape
// CHECK-SAME:                  -> !cute.shape<"(?,?,?,?)">
// CHECK:         %[[STRIDE:.+]] = cute.make_stride
// CHECK:         %[[LAYOUT:.+]] = cute.make_layout(%[[SHAPE]], %[[STRIDE]])
// CHECK-SAME:                   -> !cute.layout<"(?,?,?,?):(?,1,?,?)">
func.func @expand_dynamic(%shape: !cute.shape<"(?,?,?,?)">,
                           %order: !cute.int_tuple<"(2,1,3,4)">)
    -> !cute.layout<"(?,?,?,?):(?,1,?,?)"> {
  %r = cute.make_ordered_layout(%shape, %order)
         : (!cute.shape<"(?,?,?,?)">, !cute.int_tuple<"(2,1,3,4)">)
        -> !cute.layout<"(?,?,?,?):(?,1,?,?)">
  return %r : !cute.layout<"(?,?,?,?):(?,1,?,?)">
}

// -----

// Rank-2 all-dynamic shape with col-major order — the smallest non-static
// case. Each stride prefix-product is a single shape leaf, so cutegen
// doesn't emit any `arith.muli` (in contrast to `@expand_dynamic` above
// which crosses multiple modes and needs multiplications).
// CHECK-LABEL: func.func @expand_all_dynamic_shape
// CHECK-NOT:     cute.make_ordered_layout
// CHECK-NOT:     arith.muli
// CHECK:         cute.get_scalars<{only_dynamic}> (%{{.+}})
// CHECK:         %[[SHAPE:.+]] = cute.make_shape
// CHECK-SAME:                  -> !cute.shape<"(?,?)">
// CHECK:         %[[STRIDE:.+]] = cute.make_stride
// CHECK-SAME:                   -> !cute.stride<"(1,?)">
// CHECK:         %[[LAYOUT:.+]] = cute.make_layout(%[[SHAPE]], %[[STRIDE]])
// CHECK-SAME:                   -> !cute.layout<"(?,?):(1,?)">
func.func @expand_all_dynamic_shape(%shape: !cute.shape<"(?,?)">,
                                     %order: !cute.int_tuple<"(0,1)">)
    -> !cute.layout<"(?,?):(1,?)"> {
  %r = cute.make_ordered_layout(%shape, %order)
         : (!cute.shape<"(?,?)">, !cute.int_tuple<"(0,1)">)
        -> !cute.layout<"(?,?):(1,?)">
  return %r : !cute.layout<"(?,?):(1,?)">
}
