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

// Tests `cute-expand-ops` lowering for `cute.complement`. Cotarget is
// `LayoutType` or `ShapeType`.

// -----

// CHECK-LABEL: func.func @expand_static_shape_cotarget
// CHECK-NOT:   cute.complement
// CHECK:       cute.static : !cute.layout<"2:1">
func.func @expand_static_shape_cotarget(%input: !cute.layout<"3:2">,
                                         %co: !cute.shape<"6">)
    -> !cute.layout<"2:1"> {
  %r = cute.complement(%input, %co)
         : (!cute.layout<"3:2">, !cute.shape<"6">) -> !cute.layout<"2:1">
  return %r : !cute.layout<"2:1">
}

// -----

// Dynamic: shape cotarget.
// CHECK-LABEL: func.func @expand_shape_cotarget_dynamic
// CHECK-NOT:   cute.complement
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_layout
// CHECK-SAME:  -> !cute.layout<"(2,?):(1,?)">
func.func @expand_shape_cotarget_dynamic(%input: !cute.layout<"?:2">,
                                          %co: !cute.shape<"6">)
    -> !cute.layout<"(2,?):(1,?)"> {
  %r = cute.complement(%input, %co)
         : (!cute.layout<"?:2">, !cute.shape<"6">)
        -> !cute.layout<"(2,?):(1,?)">
  return %r : !cute.layout<"(2,?):(1,?)">
}

// -----

// Layout cotarget — pattern uses `cgCotarget.shape()` internally.
// CHECK-LABEL: func.func @expand_layout_cotarget_static
// CHECK-NOT:   cute.complement
// CHECK:       cute.static : !cute.layout<"2:1">
func.func @expand_layout_cotarget_static(%input: !cute.layout<"3:2">,
                                          %co: !cute.layout<"6:1">)
    -> !cute.layout<"2:1"> {
  %r = cute.complement(%input, %co)
         : (!cute.layout<"3:2">, !cute.layout<"6:1">) -> !cute.layout<"2:1">
  return %r : !cute.layout<"2:1">
}

// -----

// Dynamic layout cotarget — result is dynamic, rebuilt via make_layout.
// CHECK-LABEL: func.func @expand_dyn_layout_cotarget
// CHECK-NOT:   cute.complement
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_layout
// CHECK-SAME:  -> !cute.layout<"(2,?):(1,6)">
func.func @expand_dyn_layout_cotarget(%input: !cute.layout<"3:2">,
                                       %co: !cute.layout<"?:?">)
    -> !cute.layout<"(2,?):(1,6)"> {
  %r = cute.complement(%input, %co)
         : (!cute.layout<"3:2">, !cute.layout<"?:?">)
        -> !cute.layout<"(2,?):(1,6)">
  return %r : !cute.layout<"(2,?):(1,6)">
}

// -----

// Fully-dyn rank-1 input × static shape cotarget — rebuild path with
// fully-dyn input rather than the existing partially-static `?:2`.
// CHECK-LABEL: func.func @expand_fully_dyn_input
// CHECK-NOT:   cute.complement
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_layout
// CHECK-SAME:  -> !cute.layout<"(?,?):(1,?)">
func.func @expand_fully_dyn_input(%input: !cute.layout<"?:?">,
                                   %co: !cute.shape<"12">)
    -> !cute.layout<"(?,?):(1,?)"> {
  %r = cute.complement(%input, %co)
         : (!cute.layout<"?:?">, !cute.shape<"12">)
        -> !cute.layout<"(?,?):(1,?)">
  return %r : !cute.layout<"(?,?):(1,?)">
}

// -----

// Static input with multi-mode dynamic shape cotarget — rebuilt via make_layout.
// CHECK-LABEL: func.func @expand_multi_mode_dyn_cotarget
// CHECK-NOT:   cute.complement
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_layout
// CHECK-SAME:  -> !cute.layout<"(2,?):(1,6)">
func.func @expand_multi_mode_dyn_cotarget(%input: !cute.layout<"3:2">,
                                           %co: !cute.shape<"(?,?)">)
    -> !cute.layout<"(2,?):(1,6)"> {
  %r = cute.complement(%input, %co)
         : (!cute.layout<"3:2">, !cute.shape<"(?,?)">)
        -> !cute.layout<"(2,?):(1,6)">
  return %r : !cute.layout<"(2,?):(1,6)">
}
