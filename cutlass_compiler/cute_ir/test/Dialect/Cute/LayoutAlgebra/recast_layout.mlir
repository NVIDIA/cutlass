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

// RUN: cute-opt %s -split-input-file | FileCheck %s
// Verify the printed output can be parsed.
// RUN: cute-opt %s -split-input-file | cute-opt | FileCheck %s
// Verify the generic form can be parsed.
// RUN: cute-opt -mlir-print-op-generic %s -split-input-file | cute-opt | FileCheck %s
// Tests round-trip for cute.recast_layout.
// -----
// Upcast ×4: new=32-bit, old=8-bit.
// CHECK-LABEL: func.func @upcast_x4
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"(32,4):(1,32)">)
func.func @upcast_x4(
    %src: !cute.layout<"(32,4):(1,32)">) -> !cute.layout<"(8,4):(1,8)"> {
  // CHECK: %[[R:.+]] = cute.recast_layout<32, 8> (%[[SRC]])
  // CHECK-SAME: !cute.layout<"(32,4):(1,32)"> -> !cute.layout<"(8,4):(1,8)">
  %r = cute.recast_layout<32, 8>(%src)
         : !cute.layout<"(32,4):(1,32)"> -> !cute.layout<"(8,4):(1,8)">
  return %r : !cute.layout<"(8,4):(1,8)">
}
// -----
// Downcast ×4: new=8-bit, old=32-bit.
// CHECK-LABEL: func.func @downcast_x4
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"(8,4):(1,8)">)
func.func @downcast_x4(
    %src: !cute.layout<"(8,4):(1,8)">) -> !cute.layout<"(32,4):(1,32)"> {
  // CHECK: %[[R:.+]] = cute.recast_layout<8, 32> (%[[SRC]])
  // CHECK-SAME: !cute.layout<"(8,4):(1,8)"> -> !cute.layout<"(32,4):(1,32)">
  %r = cute.recast_layout<8, 32>(%src)
         : !cute.layout<"(8,4):(1,8)"> -> !cute.layout<"(32,4):(1,32)">
  return %r : !cute.layout<"(32,4):(1,32)">
}
// -----
// Upcast ×8: new=32-bit, old=4-bit.
// CHECK-LABEL: func.func @upcast_x8
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"(128,64):(1,128)">)
func.func @upcast_x8(
    %src: !cute.layout<"(128,64):(1,128)">) -> !cute.layout<"(16,64):(1,16)"> {
  // CHECK: %[[R:.+]] = cute.recast_layout<32, 4> (%[[SRC]])
  // CHECK-SAME: !cute.layout<"(128,64):(1,128)"> -> !cute.layout<"(16,64):(1,16)">
  %r = cute.recast_layout<32, 4>(%src)
         : !cute.layout<"(128,64):(1,128)"> -> !cute.layout<"(16,64):(1,16)">
  return %r : !cute.layout<"(16,64):(1,16)">
}
// -----
// Identity: new == old, result equals input unchanged.
// CHECK-LABEL: func.func @identity
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"(8,4):(1,8)">)
func.func @identity(
    %src: !cute.layout<"(8,4):(1,8)">) -> !cute.layout<"(8,4):(1,8)"> {
  // CHECK: %[[R:.+]] = cute.recast_layout<32, 32> (%[[SRC]])
  // CHECK-SAME: !cute.layout<"(8,4):(1,8)"> -> !cute.layout<"(8,4):(1,8)">
  %r = cute.recast_layout<32, 32>(%src)
         : !cute.layout<"(8,4):(1,8)"> -> !cute.layout<"(8,4):(1,8)">
  return %r : !cute.layout<"(8,4):(1,8)">
}
// -----
// Dynamic layout, upcast ×4: dynamic shape and stride stay `?`.
// CHECK-LABEL: func.func @dyn_upcast
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"(?,4):(1,?)">)
func.func @dyn_upcast(
    %src: !cute.layout<"(?,4):(1,?)">) -> !cute.layout<"(?,4):(1,?)"> {
  // CHECK: %[[R:.+]] = cute.recast_layout<32, 8> (%[[SRC]])
  // CHECK-SAME: !cute.layout<"(?,4):(1,?)"> -> !cute.layout<"(?,4):(1,?)">
  %r = cute.recast_layout<32, 8>(%src)
         : !cute.layout<"(?,4):(1,?)"> -> !cute.layout<"(?,4):(1,?)">
  return %r : !cute.layout<"(?,4):(1,?)">
}
// -----
// Upcast on a layout carrying  constraints.
// CHECK-LABEL: func.func @dyn_upcast_consumes_div
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"(?,4):(1,?)">)
func.func @dyn_upcast_consumes_div(
    %src: !cute.layout<"(?,4):(1,?)">) -> !cute.layout<"(?,4):(1,?)"> {
  // CHECK: %[[R:.+]] = cute.recast_layout<32, 16> (%[[SRC]])
  // CHECK-SAME: !cute.layout<"(?,4):(1,?)"> -> !cute.layout<"(?,4):(1,?)">
  %r = cute.recast_layout<32, 16>(%src)
         : !cute.layout<"(?,4):(1,?)"> -> !cute.layout<"(?,4):(1,?)">
  return %r : !cute.layout<"(?,4):(1,?)">
}
// -----
// Upcast on fully dynamic with stride .
// CHECK-LABEL: func.func @fully_dyn_upcast_consumes_div
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"?:?">)
func.func @fully_dyn_upcast_consumes_div(
    %src: !cute.layout<"?:?">) -> !cute.layout<"?:?"> {
  // CHECK: %[[R:.+]] = cute.recast_layout<32, 16> (%[[SRC]])
  // CHECK-SAME: !cute.layout<"?:?"> -> !cute.layout<"?:?">
  %r = cute.recast_layout<32, 16>(%src)
         : !cute.layout<"?:?"> -> !cute.layout<"?:?">
  return %r : !cute.layout<"?:?">
}
// -----
// Dynamic layout, downcast ×4: shape and stride grow and the result carries `` constraints.
// CHECK-LABEL: func.func @dyn_downcast_adds_div
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"(?,4):(1,?)">)
func.func @dyn_downcast_adds_div(
    %src: !cute.layout<"(?,4):(1,?)">) -> !cute.layout<"(?,4):(1,?)"> {
  // CHECK: %[[R:.+]] = cute.recast_layout<8, 32> (%[[SRC]])
  // CHECK-SAME: !cute.layout<"(?,4):(1,?)"> -> !cute.layout<"(?,4):(1,?)">
  %r = cute.recast_layout<8, 32>(%src)
         : !cute.layout<"(?,4):(1,?)"> -> !cute.layout<"(?,4):(1,?)">
  return %r : !cute.layout<"(?,4):(1,?)">
}
// -----
// Fully dynamic rank-1, downcast ×4: stride gets  since downcast
// multiplies it; shape stays unconstrained.
// CHECK-LABEL: func.func @fully_dyn_downcast
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"?:?">)
func.func @fully_dyn_downcast(
    %src: !cute.layout<"?:?">) -> !cute.layout<"?:?"> {
  // CHECK: %[[R:.+]] = cute.recast_layout<8, 32> (%[[SRC]])
  // CHECK-SAME: !cute.layout<"?:?"> -> !cute.layout<"?:?">
  %r = cute.recast_layout<8, 32>(%src)
         : !cute.layout<"?:?"> -> !cute.layout<"?:?">
  return %r : !cute.layout<"?:?">
}
// -----
// Composed layout: recast is applied to all components (A, offset, B).
// CHECK-LABEL: func.func @composed_upcast_x2
// CHECK-SAME:  (%[[SRC:.+]]: !cute.composed_layout<"(4,5):(1,4) o 2 o (8,4):(1,8)">)
func.func @composed_upcast_x2(
    %src: !cute.composed_layout<"(4,5):(1,4) o 2 o (8,4):(1,8)">)
    -> !cute.composed_layout<"(2,5):(1,2) o 1 o (4,4):(1,4)"> {
  // CHECK: %[[R:.+]] = cute.recast_layout<32, 16> (%[[SRC]])
  // CHECK-SAME: !cute.composed_layout<"(4,5):(1,4) o 2 o (8,4):(1,8)">
  // CHECK-SAME: -> !cute.composed_layout<"(2,5):(1,2) o 1 o (4,4):(1,4)">
  %r = cute.recast_layout<32, 16>(%src)
         : !cute.composed_layout<"(4,5):(1,4) o 2 o (8,4):(1,8)">
        -> !cute.composed_layout<"(2,5):(1,2) o 1 o (4,4):(1,4)">
  return %r : !cute.composed_layout<"(2,5):(1,2) o 1 o (4,4):(1,4)">
}
// -----
// Composed layout with swizzle-A: upcast ×4 changes `num_base`: `S<3,5,4>` → `S<3,3,4>`.
// CHECK-LABEL: func.func @composed_swizzle_upcast
// CHECK-SAME:  (%[[SRC:.+]]: !cute.composed_layout<"S<3,5,4> o 0 o (32,4):(1,32)">)
func.func @composed_swizzle_upcast(
    %src: !cute.composed_layout<"S<3,5,4> o 0 o (32,4):(1,32)">)
    -> !cute.composed_layout<"S<3,3,4> o 0 o (8,4):(1,8)"> {
  // CHECK: %[[R:.+]] = cute.recast_layout<32, 8> (%[[SRC]])
  // CHECK-SAME: !cute.composed_layout<"S<3,5,4> o 0 o (32,4):(1,32)">
  // CHECK-SAME: -> !cute.composed_layout<"S<3,3,4> o 0 o (8,4):(1,8)">
  %r = cute.recast_layout<32, 8>(%src)
         : !cute.composed_layout<"S<3,5,4> o 0 o (32,4):(1,32)">
        -> !cute.composed_layout<"S<3,3,4> o 0 o (8,4):(1,8)">
  return %r : !cute.composed_layout<"S<3,3,4> o 0 o (8,4):(1,8)">
}
// -----
// Composed layout with swizzle-A: downcast ×4 changes `num_base`: `S<3,3,4>` → `S<3,5,4>`.
// CHECK-LABEL: func.func @composed_swizzle_downcast
// CHECK-SAME:  (%[[SRC:.+]]: !cute.composed_layout<"S<3,3,4> o 0 o (8,4):(1,8)">)
func.func @composed_swizzle_downcast(
    %src: !cute.composed_layout<"S<3,3,4> o 0 o (8,4):(1,8)">)
    -> !cute.composed_layout<"S<3,5,4> o 0 o (32,4):(1,32)"> {
  // CHECK: %[[R:.+]] = cute.recast_layout<8, 32> (%[[SRC]])
  // CHECK-SAME: !cute.composed_layout<"S<3,3,4> o 0 o (8,4):(1,8)">
  // CHECK-SAME: -> !cute.composed_layout<"S<3,5,4> o 0 o (32,4):(1,32)">
  %r = cute.recast_layout<8, 32>(%src)
         : !cute.composed_layout<"S<3,3,4> o 0 o (8,4):(1,8)">
        -> !cute.composed_layout<"S<3,5,4> o 0 o (32,4):(1,32)">
  return %r : !cute.composed_layout<"S<3,5,4> o 0 o (32,4):(1,32)">
}
