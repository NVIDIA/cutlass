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

// Tests `cute-expand-ops` lowering for `cute.right_inverse`. Static results
// fold directly; dynamic-shape results are rebuilt from runtime scalars.

// -----

// CHECK-LABEL: func.func @expand_static
// CHECK-NOT:   cute.right_inverse
// CHECK:       cute.static : !cute.layout<"12:1">
func.func @expand_static(%src: !cute.layout<"(4,3):(1,4)">)
    -> !cute.layout<"12:1"> {
  %r = cute.right_inverse(%src)
         : (!cute.layout<"(4,3):(1,4)">) -> !cute.layout<"12:1">
  return %r : !cute.layout<"12:1">
}

// -----

// CHECK-LABEL: func.func @expand_static_permutation
// CHECK-NOT:   cute.right_inverse
// CHECK:       cute.static : !cute.layout<"(3,4):(4,1)">
func.func @expand_static_permutation(%src: !cute.layout<"(4,3):(3,1)">)
    -> !cute.layout<"(3,4):(4,1)"> {
  %r = cute.right_inverse(%src)
         : (!cute.layout<"(4,3):(3,1)">) -> !cute.layout<"(3,4):(4,1)">
  return %r : !cute.layout<"(3,4):(4,1)">
}

// -----

// Dynamic shape with static integer strides.
// CHECK-LABEL: func.func @expand_dynamic_shape
// CHECK-NOT:   cute.right_inverse
// CHECK:       %[[DYN:.+]] = cute.get_scalars<{only_dynamic}>
// CHECK:       %[[SHAPE:.+]] = cute.make_shape(%[[DYN]]) : (i32) -> !cute.shape<"(16,?)">
// CHECK:       %[[STRIDE:.+]] = cute.make_stride() : () -> !cute.stride<"(1,16)">
// CHECK:       cute.make_layout(%[[SHAPE]], %[[STRIDE]])
func.func @expand_dynamic_shape(%src: !cute.layout<"(16,?):(1,16)">)
    -> !cute.layout<"(16,?):(1,16)"> {
  %r = cute.right_inverse(%src)
         : (!cute.layout<"(16,?):(1,16)">) -> !cute.layout<"(16,?):(1,16)">
  return %r : !cute.layout<"(16,?):(1,16)">
}

// -----

// Dynamic derived stride from the preserved runtime extent.
// CHECK-LABEL: func.func @expand_dynamic_derived_stride
// CHECK-NOT:   cute.right_inverse
// CHECK:       %[[DYN:.+]] = cute.get_scalars<{only_dynamic}>
// CHECK:       %[[SHAPE:.+]] = cute.make_shape() : () -> !cute.shape<"4">
// CHECK:       %[[STRIDE:.+]] = cute.make_stride(%[[DYN]]) : (i32) -> !cute.stride<"?">
// CHECK:       cute.make_layout(%[[SHAPE]], %[[STRIDE]]) : (!cute.shape<"4">, !cute.stride<"?">) -> !cute.layout<"4:?">
func.func @expand_dynamic_derived_stride(%src: !cute.layout<"(?,4):(0,1)">)
    -> !cute.layout<"4:?"> {
  %r = cute.right_inverse(%src)
         : (!cute.layout<"(?,4):(0,1)">) -> !cute.layout<"4:?">
  return %r : !cute.layout<"4:?">
}
