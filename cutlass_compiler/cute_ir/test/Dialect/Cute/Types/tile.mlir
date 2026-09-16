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

// Tests parse/print round-trip for !cute.tile types.

// -----

// Single-layout tile.
// CHECK-LABEL: func.func @single_layout
func.func @single_layout(
    // CHECK-SAME: %[[A:.+]]: !cute.tile<"[(2,3):(1,2)]">
    %a: !cute.tile<"[(2,3):(1,2)]">) {
  return
}

// -----

// Two-layout tile.
// CHECK-LABEL: func.func @two_layouts
func.func @two_layouts(
    // CHECK-SAME: %[[A:.+]]: !cute.tile<"[(2,3):(1,2);(4,5):(1,4)]">
    %a: !cute.tile<"[(2,3):(1,2);(4,5):(1,4)]">) {
  return
}

// -----

// Underscore tile (slice all).
// CHECK-LABEL: func.func @underscore
func.func @underscore(
    // CHECK-SAME: %[[A:.+]]: !cute.tile<"[_]">
    %a: !cute.tile<"[_]">) {
  return
}

// -----

// Layout + underscore mixed tile.
// CHECK-LABEL: func.func @mixed
func.func @mixed(
    // CHECK-SAME: %[[A:.+]]: !cute.tile<"[(2,3):(1,2);_]">
    %a: !cute.tile<"[(2,3):(1,2);_]">) {
  return
}

// -----

// Dynamic layout in tile.
// CHECK-LABEL: func.func @dynamic_layout
func.func @dynamic_layout(
    // CHECK-SAME: %[[A:.+]]: !cute.tile<"[(2,3):(?,2)]">
    %a: !cute.tile<"[(2,3):(?,2)]">) {
  return
}

// -----

// Three-element tile.
// CHECK-LABEL: func.func @three_elements
func.func @three_elements(
    // CHECK-SAME: %[[A:.+]]: !cute.tile<"[(2,3):(1,2);_;(4,5):(1,4)]">
    %a: !cute.tile<"[(2,3):(1,2);_;(4,5):(1,4)]">) {
  return
}

// -----

// Tile whose layout uses hierarchical (multi-index) scaled-basis strides.
// CHECK-LABEL: func.func @hierarchical_basis_strides
func.func @hierarchical_basis_strides(
    // CHECK-SAME: %[[A:.+]]: !cute.tile<"[(2,3):(1@0@0,1@1@0)]">
    %a: !cute.tile<"[(2,3):(1@0@0,1@1@0)]">) {
  return
}

// -----

// Tile-of-tile: the second slot is itself a nested tile.
// CHECK-LABEL: func.func @nested_tile
func.func @nested_tile(
    // CHECK-SAME: %[[A:.+]]: !cute.tile<"[?:1;[(?,?):(?,?);_]]">
    %a: !cute.tile<"[?:1;[(?,?):(?,?);_]]">) {
  return
}

// -----

// Tile combining a stride-0 cosize-1 layout slot with a nested
// tile that itself has dynamic + divisible-dynamic strides + an underscore slot.
// CHECK-LABEL: func.func @stride_zero_slot
func.func @stride_zero_slot(
    // CHECK-SAME: %[[A:.+]]: !cute.tile<"[1:0;[(2,?,?):(1,2,?);_]]">
    %a: !cute.tile<"[1:0;[(2,?,?):(1,2,?);_]]">) {
  return
}
