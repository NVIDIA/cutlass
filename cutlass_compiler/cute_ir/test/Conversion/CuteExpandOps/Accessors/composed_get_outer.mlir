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

// Tests `cute-expand-ops` lowering for `cute.composed_get_outer`.

// -----

// CHECK-LABEL: func.func @expand_static
// CHECK-NOT:   cute.composed_get_outer
// CHECK:       cute.static : !cute.layout<"(2,4):(1,2)">
func.func @expand_static(
    %cl: !cute.composed_layout<"(4,8):(1,4) o 0 o (2,4):(1,2)">)
    -> !cute.layout<"(2,4):(1,2)"> {
  %r = cute.composed_get_outer(%cl)
         : !cute.composed_layout<"(4,8):(1,4) o 0 o (2,4):(1,2)">
        -> !cute.layout<"(2,4):(1,2)">
  return %r : !cute.layout<"(2,4):(1,2)">
}

// -----

// CHECK-LABEL: func.func @expand_dynamic
// CHECK-NOT:   cute.composed_get_outer
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_layout
// CHECK-SAME:  -> !cute.layout<"(?,4):(1,?)">
func.func @expand_dynamic(
    %cl: !cute.composed_layout<"(4,5):(1,4) o 0 o (?,4):(1,?)">)
    -> !cute.layout<"(?,4):(1,?)"> {
  %r = cute.composed_get_outer(%cl)
         : !cute.composed_layout<"(4,5):(1,4) o 0 o (?,4):(1,?)">
        -> !cute.layout<"(?,4):(1,?)">
  return %r : !cute.layout<"(?,4):(1,?)">
}

// -----

// Scaled-basis outer (static).
// CHECK-LABEL: func.func @expand_scaled_basis_static
// CHECK-NOT:   cute.composed_get_outer
// CHECK:       cute.static : !cute.layout<"(4,8):(1@0,1@1)">
func.func @expand_scaled_basis_static(
    %cl: !cute.composed_layout<"(4,8):(1,4) o 0 o (4,8):(1@0,1@1)">)
    -> !cute.layout<"(4,8):(1@0,1@1)"> {
  %r = cute.composed_get_outer(%cl)
         : !cute.composed_layout<"(4,8):(1,4) o 0 o (4,8):(1@0,1@1)">
        -> !cute.layout<"(4,8):(1@0,1@1)">
  return %r : !cute.layout<"(4,8):(1@0,1@1)">
}

// -----

// Scaled-basis outer (dynamic): dynamic stride leaves rebuild.
// CHECK-LABEL: func.func @expand_scaled_basis_dynamic
// CHECK-NOT:   cute.composed_get_outer
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_layout
// CHECK-SAME:  -> !cute.layout<"(?,?):(?@0,?@1)">
func.func @expand_scaled_basis_dynamic(
    %cl: !cute.composed_layout<"(4,8):(1,4) o 0 o (?,?):(?@0,?@1)">)
    -> !cute.layout<"(?,?):(?@0,?@1)"> {
  %r = cute.composed_get_outer(%cl)
         : !cute.composed_layout<"(4,8):(1,4) o 0 o (?,?):(?@0,?@1)">
        -> !cute.layout<"(?,?):(?@0,?@1)">
  return %r : !cute.layout<"(?,?):(?@0,?@1)">
}

// -----

// Nested outer with dynamic leaves at multiple depths.
// CHECK-LABEL: func.func @expand_nested_dynamic
// CHECK-NOT:   cute.composed_get_outer
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_layout
// CHECK-SAME:  -> !cute.layout<"((?,3),4):((1,?),?)">
func.func @expand_nested_dynamic(
    %cl: !cute.composed_layout<"(4,5):(1,4) o 0 o ((?,3),4):((1,?),?)">)
    -> !cute.layout<"((?,3),4):((1,?),?)"> {
  %r = cute.composed_get_outer(%cl)
         : !cute.composed_layout<"(4,5):(1,4) o 0 o ((?,3),4):((1,?),?)">
        -> !cute.layout<"((?,3),4):((1,?),?)">
  return %r : !cute.layout<"((?,3),4):((1,?),?)">
}

// -----

// Flat scaled-basis outer (dynamic), with a tuple offset that matches
// the affine A profile. Demonstrates the non-nested basis case.
// CHECK-LABEL: func.func @expand_flat_basis_dynamic
// CHECK-NOT:   cute.composed_get_outer
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_layout
// CHECK-SAME:  -> !cute.layout<"(?,?):(?@0,?@1)">
func.func @expand_flat_basis_dynamic(
    %cl: !cute.composed_layout<"(4,5):(1,4) o (1,2) o (?,?):(?@0,?@1)">)
    -> !cute.layout<"(?,?):(?@0,?@1)"> {
  %r = cute.composed_get_outer(%cl)
         : !cute.composed_layout<"(4,5):(1,4) o (1,2) o (?,?):(?@0,?@1)">
        -> !cute.layout<"(?,?):(?@0,?@1)">
  return %r : !cute.layout<"(?,?):(?@0,?@1)">
}
