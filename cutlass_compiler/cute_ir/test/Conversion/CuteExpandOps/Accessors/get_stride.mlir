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

// Tests `cute-expand-ops` lowering for `cute.get_stride`. Layout source only.

// -----

// CHECK-LABEL: func.func @expand_static
// CHECK-NOT:   cute.get_stride
// CHECK:       cute.static : !cute.stride<"(1,4)">
func.func @expand_static(%l: !cute.layout<"(4,8):(1,4)">)
    -> !cute.stride<"(1,4)"> {
  %r = cute.get_stride(%l) : !cute.layout<"(4,8):(1,4)"> -> !cute.stride<"(1,4)">
  return %r : !cute.stride<"(1,4)">
}

// -----

// CHECK-LABEL: func.func @expand_dynamic
// CHECK-NOT:   cute.get_stride
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       %[[D:.+]] = cute.make_stride
// CHECK-SAME:            -> !cute.stride<"(1,?)">
func.func @expand_dynamic(%l: !cute.layout<"(?,4):(1,?)">)
    -> !cute.stride<"(1,?)"> {
  %r = cute.get_stride(%l) : !cute.layout<"(?,4):(1,?)"> -> !cute.stride<"(1,?)">
  return %r : !cute.stride<"(1,?)">
}

// -----

// Scaled-basis stride: identity layout (`1@0,1@1`) is fully static.
// CHECK-LABEL: func.func @expand_scaled_basis_static
// CHECK-NOT:   cute.get_stride
// CHECK:       cute.static : !cute.stride<"(1@0,1@1)">
func.func @expand_scaled_basis_static(%l: !cute.layout<"(4,8):(1@0,1@1)">)
    -> !cute.stride<"(1@0,1@1)"> {
  %r = cute.get_stride(%l)
         : !cute.layout<"(4,8):(1@0,1@1)"> -> !cute.stride<"(1@0,1@1)">
  return %r : !cute.stride<"(1@0,1@1)">
}

// -----

// Scaled-basis stride with dynamic scales (`?@0,?@1`) — dynamic stride
// leaves rebuild via make_stride.
// CHECK-LABEL: func.func @expand_scaled_basis_dynamic
// CHECK-NOT:   cute.get_stride
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       %[[D:.+]] = cute.make_stride
// CHECK-SAME:            -> !cute.stride<"(?@0,?@1)">
func.func @expand_scaled_basis_dynamic(%l: !cute.layout<"(?,?):(?@0,?@1)">)
    -> !cute.stride<"(?@0,?@1)"> {
  %r = cute.get_stride(%l)
         : !cute.layout<"(?,?):(?@0,?@1)"> -> !cute.stride<"(?@0,?@1)">
  return %r : !cute.stride<"(?@0,?@1)">
}

// -----

// Nested layout with dynamic shape and stride leaves at multiple depths.
// CHECK-LABEL: func.func @expand_nested_dynamic
// CHECK-NOT:   cute.get_stride
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       %[[D:.+]] = cute.make_stride
// CHECK-SAME:            -> !cute.stride<"((1,?),?)">
func.func @expand_nested_dynamic(%l: !cute.layout<"((?,3),4):((1,?),?)">)
    -> !cute.stride<"((1,?),?)"> {
  %r = cute.get_stride(%l)
         : !cute.layout<"((?,3),4):((1,?),?)"> -> !cute.stride<"((1,?),?)">
  return %r : !cute.stride<"((1,?),?)">
}

// -----

// Nested scaled-basis stride (static): every nested basis leaf is static.
// CHECK-LABEL: func.func @expand_nested_scaled_basis_static
// CHECK-NOT:   cute.get_stride
// CHECK:       cute.static : !cute.stride<"((1@0@0,1@1@0),1@1)">
func.func @expand_nested_scaled_basis_static(
    %l: !cute.layout<"((4,8),3):((1@0@0,1@1@0),1@1)">)
    -> !cute.stride<"((1@0@0,1@1@0),1@1)"> {
  %r = cute.get_stride(%l)
         : !cute.layout<"((4,8),3):((1@0@0,1@1@0),1@1)">
        -> !cute.stride<"((1@0@0,1@1@0),1@1)">
  return %r : !cute.stride<"((1@0@0,1@1@0),1@1)">
}

// -----

// Nested scaled-basis stride (dynamic): each `?@N@M` leaf rebuilds via
// make_stride with its respective dynamic scalar.
// CHECK-LABEL: func.func @expand_nested_scaled_basis_dynamic
// CHECK-NOT:   cute.get_stride
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       %[[D:.+]] = cute.make_stride
// CHECK-SAME:            -> !cute.stride<"((?@0@0,?@1@0),?@1)">
func.func @expand_nested_scaled_basis_dynamic(
    %l: !cute.layout<"((?,?),?):((?@0@0,?@1@0),?@1)">)
    -> !cute.stride<"((?@0@0,?@1@0),?@1)"> {
  %r = cute.get_stride(%l)
         : !cute.layout<"((?,?),?):((?@0@0,?@1@0),?@1)">
        -> !cute.stride<"((?@0@0,?@1@0),?@1)">
  return %r : !cute.stride<"((?@0@0,?@1@0),?@1)">
}
