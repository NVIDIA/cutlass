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

// Tests `cute-expand-ops` lowering for `cute.make_layout_like`.

// -----

// Fully static result.
// CHECK-LABEL: func.func @expand_static
// CHECK-NOT:   cute.make_layout_like
// CHECK:       %[[R:.+]] = cute.static : !cute.layout<"(4,2):(2,1)">
func.func @expand_static(%src: !cute.layout<"(4,2):(4,1)">)
    -> !cute.layout<"(4,2):(2,1)"> {
  %r = cute.make_layout_like(%src)
         : !cute.layout<"(4,2):(4,1)"> -> !cute.layout<"(4,2):(2,1)">
  return %r : !cute.layout<"(4,2):(2,1)">
}

// -----

// Dynamic layout source.
// CHECK-LABEL: func.func @expand_dynamic_layout
// CHECK-NOT:     cute.make_layout_like
// CHECK:         %[[SCALARS:.+]]:5 = cute.get_scalars<{only_dynamic}> (%{{.+}})
// CHECK:         arith.muli
// CHECK:         %[[SHAPE:.+]] = cute.make_shape
// CHECK-SAME:                  -> !cute.shape<"(8,?,4,?)">
// CHECK:         %[[STRIDE:.+]] = cute.make_stride
// CHECK-SAME:                   -> !cute.stride<"(?,?,?,1)">
// CHECK:         %[[LAYOUT:.+]] = cute.make_layout(%[[SHAPE]], %[[STRIDE]])
// CHECK-SAME:                   -> !cute.layout<"(8,?,4,?):(?,?,?,1)">
func.func @expand_dynamic_layout(%src: !cute.layout<"(8,?,4,?):(?,?,?,1)">)
    -> !cute.layout<"(8,?,4,?):(?,?,?,1)"> {
  %r = cute.make_layout_like(%src)
         : !cute.layout<"(8,?,4,?):(?,?,?,1)">
        -> !cute.layout<"(8,?,4,?):(?,?,?,1)">
  return %r : !cute.layout<"(8,?,4,?):(?,?,?,1)">
}

// -----

// Dynamic composed_layout source.
// CHECK-LABEL: func.func @expand_dynamic_composed_layout
// CHECK-NOT:     cute.make_layout_like
// CHECK:         cute.get_scalars<{only_dynamic}> (%{{.+}})
// CHECK:         %[[LAYOUT:.+]] = cute.make_layout
// CHECK-SAME:                   -> !cute.layout<"(4,?):(?,1)">
func.func @expand_dynamic_composed_layout(
    %src: !cute.composed_layout<"S<3,4,3> o 0 o (4,?):(?,1)">)
    -> !cute.layout<"(4,?):(?,1)"> {
  %r = cute.make_layout_like(%src)
         : !cute.composed_layout<"S<3,4,3> o 0 o (4,?):(?,1)">
        -> !cute.layout<"(4,?):(?,1)">
  return %r : !cute.layout<"(4,?):(?,1)">
}

// -----

// All-dynamic layout source — both shape and stride carry only `?`. The
// result shape passes through; the result stride is compact
// column-major.
// CHECK-LABEL: func.func @expand_all_dynamic
// CHECK-NOT:     cute.make_layout_like
// CHECK:         cute.get_scalars<{only_dynamic}> (%{{.+}})
// CHECK:         %[[SHAPE:.+]] = cute.make_shape
// CHECK-SAME:                  -> !cute.shape<"(?,?)">
// CHECK:         %[[STRIDE:.+]] = cute.make_stride
// CHECK-SAME:                   -> !cute.stride<"(1,?)">
// CHECK:         %[[LAYOUT:.+]] = cute.make_layout(%[[SHAPE]], %[[STRIDE]])
// CHECK-SAME:                   -> !cute.layout<"(?,?):(1,?)">
func.func @expand_all_dynamic(%src: !cute.layout<"(?,?):(?,?)">)
    -> !cute.layout<"(?,?):(1,?)"> {
  %r = cute.make_layout_like(%src)
         : !cute.layout<"(?,?):(?,?)"> -> !cute.layout<"(?,?):(1,?)">
  return %r : !cute.layout<"(?,?):(1,?)">
}
