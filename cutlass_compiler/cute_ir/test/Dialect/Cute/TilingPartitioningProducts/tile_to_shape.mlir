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

// Tests round-trip for cute.tile_to_shape.

// -----

// Layout input.
// CHECK-LABEL: func.func @tile_to_shape_layout
// CHECK-SAME:  (%[[A:.+]]: !cute.layout<"(3,2):(1,3)">, %[[B:.+]]: !cute.shape<"(6,8)">)
func.func @tile_to_shape_layout(
    %a: !cute.layout<"(3,2):(1,3)">,
    %b: !cute.shape<"(6,8)">) -> !cute.layout<"((3,2),(2,4)):((1,6),(3,12))"> {
  // CHECK: %[[R:.+]] = cute.tile_to_shape(%[[A]], %[[B]]) : (!cute.layout<"(3,2):(1,3)">, !cute.shape<"(6,8)">) -> !cute.layout<"((3,2),(2,4)):((1,6),(3,12))">
  %r = cute.tile_to_shape(%a, %b)
         : (!cute.layout<"(3,2):(1,3)">, !cute.shape<"(6,8)">)
        -> !cute.layout<"((3,2),(2,4)):((1,6),(3,12))">
  return %r : !cute.layout<"((3,2),(2,4)):((1,6),(3,12))">
}

// -----

// ComposedLayout input.
// CHECK-LABEL: func.func @tile_to_shape_composed
func.func @tile_to_shape_composed(
    %a: !cute.composed_layout<"S<3,4,3> o 0 o (3,2):(1,3)">,
    %b: !cute.shape<"(6,8)">) {
  // CHECK: cute.tile_to_shape(%{{.+}}, %{{.+}}) : (!cute.composed_layout<"S<3,4,3> o 0 o (3,2):(1,3)">, !cute.shape<"(6,8)">) -> !cute.composed_layout<"S<3,4,3> o 0 o ((3,2),(2,4)):((1,6),(3,12))">
  %r = cute.tile_to_shape(%a, %b)
         : (!cute.composed_layout<"S<3,4,3> o 0 o (3,2):(1,3)">,
            !cute.shape<"(6,8)">)
        -> !cute.composed_layout<"S<3,4,3> o 0 o ((3,2),(2,4)):((1,6),(3,12))">
  return
}

// -----

// Order = (0,1).
// CHECK-LABEL: func.func @tile_to_shape_order_natural
// CHECK-SAME:  (%[[A:.+]]: !cute.layout<"(128,128):(128,1)">, %[[B:.+]]: !cute.shape<"(1024,512)">, %[[O:.+]]: !cute.int_tuple<"(0,1)">)
func.func @tile_to_shape_order_natural(
    %a: !cute.layout<"(128,128):(128,1)">,
    %b: !cute.shape<"(1024,512)">,
    %o: !cute.int_tuple<"(0,1)">)
    -> !cute.layout<"((128,8),(128,4)):((128,16384),(1,131072))"> {
  // CHECK: %[[R:.+]] = cute.tile_to_shape(%[[A]], %[[B]], %[[O]]) : (!cute.layout<"(128,128):(128,1)">, !cute.shape<"(1024,512)">, !cute.int_tuple<"(0,1)">) -> !cute.layout<"((128,8),(128,4)):((128,16384),(1,131072))">
  %r = cute.tile_to_shape(%a, %b, %o)
         : (!cute.layout<"(128,128):(128,1)">,
            !cute.shape<"(1024,512)">,
            !cute.int_tuple<"(0,1)">)
        -> !cute.layout<"((128,8),(128,4)):((128,16384),(1,131072))">
  return %r : !cute.layout<"((128,8),(128,4)):((128,16384),(1,131072))">
}

// -----

// Order = (1,0).
// CHECK-LABEL: func.func @tile_to_shape_order_swapped
// CHECK-SAME:  (%[[A:.+]]: !cute.layout<"(128,128):(128,1)">, %[[B:.+]]: !cute.shape<"(1024,512)">, %[[O:.+]]: !cute.int_tuple<"(1,0)">)
func.func @tile_to_shape_order_swapped(
    %a: !cute.layout<"(128,128):(128,1)">,
    %b: !cute.shape<"(1024,512)">,
    %o: !cute.int_tuple<"(1,0)">)
    -> !cute.layout<"((128,8),(128,4)):((128,65536),(1,16384))"> {
  // CHECK: %[[R:.+]] = cute.tile_to_shape(%[[A]], %[[B]], %[[O]]) : (!cute.layout<"(128,128):(128,1)">, !cute.shape<"(1024,512)">, !cute.int_tuple<"(1,0)">) -> !cute.layout<"((128,8),(128,4)):((128,65536),(1,16384))">
  %r = cute.tile_to_shape(%a, %b, %o)
         : (!cute.layout<"(128,128):(128,1)">,
            !cute.shape<"(1024,512)">,
            !cute.int_tuple<"(1,0)">)
        -> !cute.layout<"((128,8),(128,4)):((128,65536),(1,16384))">
  return %r : !cute.layout<"((128,8),(128,4)):((128,65536),(1,16384))">
}

// -----

// Dyn target shape (no order).
// CHECK-LABEL: func.func @tile_to_shape_dyn_shape
// CHECK-SAME:  (%[[A:.+]]: !cute.layout<"(3,2):(1,3)">, %[[B:.+]]: !cute.shape<"(?,?)">)
func.func @tile_to_shape_dyn_shape(
    %a: !cute.layout<"(3,2):(1,3)">,
    %b: !cute.shape<"(?,?)">)
    -> !cute.layout<"((3,?),(2,?)):((1,6),(3,?))"> {
  // CHECK: %[[R:.+]] = cute.tile_to_shape(%[[A]], %[[B]]) : (!cute.layout<"(3,2):(1,3)">, !cute.shape<"(?,?)">) -> !cute.layout<"((3,?),(2,?)):((1,6),(3,?))">
  %r = cute.tile_to_shape(%a, %b)
         : (!cute.layout<"(3,2):(1,3)">, !cute.shape<"(?,?)">)
        -> !cute.layout<"((3,?),(2,?)):((1,6),(3,?))">
  return %r : !cute.layout<"((3,?),(2,?)):((1,6),(3,?))">
}

// -----

// Dyn target shape with explicit swap order = (1,0).
// CHECK-LABEL: func.func @tile_to_shape_dyn_shape_order_swap
// CHECK-SAME:  (%[[A:.+]]: !cute.layout<"(3,2):(1,3)">, %[[B:.+]]: !cute.shape<"(?,?)">, %[[O:.+]]: !cute.int_tuple<"(1,0)">)
func.func @tile_to_shape_dyn_shape_order_swap(
    %a: !cute.layout<"(3,2):(1,3)">,
    %b: !cute.shape<"(?,?)">,
    %o: !cute.int_tuple<"(1,0)">)
    -> !cute.layout<"((3,?),(2,?)):((1,?),(3,6))"> {
  // CHECK: %[[R:.+]] = cute.tile_to_shape(%[[A]], %[[B]], %[[O]]) : (!cute.layout<"(3,2):(1,3)">, !cute.shape<"(?,?)">, !cute.int_tuple<"(1,0)">) -> !cute.layout<"((3,?),(2,?)):((1,?),(3,6))">
  %r = cute.tile_to_shape(%a, %b, %o)
         : (!cute.layout<"(3,2):(1,3)">, !cute.shape<"(?,?)">,
            !cute.int_tuple<"(1,0)">)
        -> !cute.layout<"((3,?),(2,?)):((1,?),(3,6))">
  return %r : !cute.layout<"((3,?),(2,?)):((1,?),(3,6))">
}

// -----

// Composed-layout input with explicit order = (1,0).
// CHECK-LABEL: func.func @tile_to_shape_composed_order_swap
// CHECK-SAME:  (%[[A:.+]]: !cute.composed_layout<"S<3,4,3> o 0 o (3,2):(1,3)">, %[[B:.+]]: !cute.shape<"(6,8)">, %[[O:.+]]: !cute.int_tuple<"(1,0)">)
func.func @tile_to_shape_composed_order_swap(
    %a: !cute.composed_layout<"S<3,4,3> o 0 o (3,2):(1,3)">,
    %b: !cute.shape<"(6,8)">,
    %o: !cute.int_tuple<"(1,0)">)
    -> !cute.composed_layout<"S<3,4,3> o 0 o ((3,2),(2,4)):((1,24),(3,6))"> {
  // CHECK: %[[R:.+]] = cute.tile_to_shape(%[[A]], %[[B]], %[[O]]) : (!cute.composed_layout<"S<3,4,3> o 0 o (3,2):(1,3)">, !cute.shape<"(6,8)">, !cute.int_tuple<"(1,0)">) -> !cute.composed_layout<"S<3,4,3> o 0 o ((3,2),(2,4)):((1,24),(3,6))">
  %r = cute.tile_to_shape(%a, %b, %o)
         : (!cute.composed_layout<"S<3,4,3> o 0 o (3,2):(1,3)">,
            !cute.shape<"(6,8)">, !cute.int_tuple<"(1,0)">)
        -> !cute.composed_layout<"S<3,4,3> o 0 o ((3,2),(2,4)):((1,24),(3,6))">
  return %r : !cute.composed_layout<"S<3,4,3> o 0 o ((3,2),(2,4)):((1,24),(3,6))">
}

// -----

// Block with rank strictly less than target shape.
// CHECK-LABEL: func.func @tile_to_shape_block_rank_less
// CHECK-SAME:  (%[[A:.+]]: !cute.layout<"3:1">, %[[B:.+]]: !cute.shape<"(6,8)">)
func.func @tile_to_shape_block_rank_less(
    %a: !cute.layout<"3:1">,
    %b: !cute.shape<"(6,8)">)
    -> !cute.layout<"((3,2),(1,8)):((1,3),(0,6))"> {
  // CHECK: %[[R:.+]] = cute.tile_to_shape(%[[A]], %[[B]]) : (!cute.layout<"3:1">, !cute.shape<"(6,8)">) -> !cute.layout<"((3,2),(1,8)):((1,3),(0,6))">
  %r = cute.tile_to_shape(%a, %b)
         : (!cute.layout<"3:1">, !cute.shape<"(6,8)">)
        -> !cute.layout<"((3,2),(1,8)):((1,3),(0,6))">
  return %r : !cute.layout<"((3,2),(1,8)):((1,3),(0,6))">
}

// -----

// Rounded-up tiling.
// CHECK-LABEL: func.func @tile_to_shape_rounded_up
// CHECK-SAME:  (%[[A:.+]]: !cute.layout<"(3,3):(1,3)">, %[[B:.+]]: !cute.shape<"(5,8)">)
func.func @tile_to_shape_rounded_up(
    %a: !cute.layout<"(3,3):(1,3)">,
    %b: !cute.shape<"(5,8)">)
    -> !cute.layout<"((3,2),(3,3)):((1,9),(3,18))"> {
  // CHECK: %[[R:.+]] = cute.tile_to_shape(%[[A]], %[[B]]) : (!cute.layout<"(3,3):(1,3)">, !cute.shape<"(5,8)">) -> !cute.layout<"((3,2),(3,3)):((1,9),(3,18))">
  %r = cute.tile_to_shape(%a, %b)
         : (!cute.layout<"(3,3):(1,3)">, !cute.shape<"(5,8)">)
        -> !cute.layout<"((3,2),(3,3)):((1,9),(3,18))">
  return %r : !cute.layout<"((3,2),(3,3)):((1,9),(3,18))">
}

// -----

// Column-major (no explicit order).
// CHECK-LABEL: func.func @CG_TEST_tts_s1_cm
func.func @CG_TEST_tts_s1_cm(
    %a: !cute.layout<"(64,8):(1,64)">,
    %b: !cute.shape<"((128,1),(16,1),1)">) -> !cute.layout<"((64,2),(8,2),(1,1)):((1,512),(64,1024),(0,0))"> {
  // CHECK: cute.tile_to_shape(%{{.+}}, %{{.+}}) : (!cute.layout<"(64,8):(1,64)">, !cute.shape<"((128,1),(16,1),1)">) -> !cute.layout<"((64,2),(8,2),(1,1)):((1,512),(64,1024),(0,0))">
  %r = cute.tile_to_shape(%a, %b)
         : (!cute.layout<"(64,8):(1,64)">, !cute.shape<"((128,1),(16,1),1)">)
        -> !cute.layout<"((64,2),(8,2),(1,1)):((1,512),(64,1024),(0,0))">
  return %r : !cute.layout<"((64,2),(8,2),(1,1)):((1,512),(64,1024),(0,0))">
}

// -----

// Row-major via `int_tuple(2,1,0)`.
// CHECK-LABEL: func.func @CG_TEST_tts_s1_rm
func.func @CG_TEST_tts_s1_rm(
    %a: !cute.layout<"(64,8):(1,64)">,
    %b: !cute.shape<"((128,1),(16,1),1)">,
    %o: !cute.int_tuple<"(2,1,0)">) -> !cute.layout<"((64,2),(8,2),(1,1)):((1,1024),(64,512),(0,0))"> {
  // CHECK: cute.tile_to_shape(%{{.+}}, %{{.+}}, %{{.+}}) : (!cute.layout<"(64,8):(1,64)">, !cute.shape<"((128,1),(16,1),1)">, !cute.int_tuple<"(2,1,0)">) -> !cute.layout<"((64,2),(8,2),(1,1)):((1,1024),(64,512),(0,0))">
  %r = cute.tile_to_shape(%a, %b, %o)
         : (!cute.layout<"(64,8):(1,64)">, !cute.shape<"((128,1),(16,1),1)">, !cute.int_tuple<"(2,1,0)">)
        -> !cute.layout<"((64,2),(8,2),(1,1)):((1,1024),(64,512),(0,0))">
  return %r : !cute.layout<"((64,2),(8,2),(1,1)):((1,1024),(64,512),(0,0))">
}

// -----

// Target ((64,1),(16,1),1).
// CHECK-LABEL: func.func @CG_TEST_tts_s2_cm
func.func @CG_TEST_tts_s2_cm(
    %a: !cute.layout<"(64,8):(1,64)">,
    %b: !cute.shape<"((64,1),(16,1),1)">) -> !cute.layout<"((64,1),(8,2),(1,1)):((1,0),(64,512),(0,0))"> {
  // CHECK: cute.tile_to_shape(%{{.+}}, %{{.+}}) : (!cute.layout<"(64,8):(1,64)">, !cute.shape<"((64,1),(16,1),1)">) -> !cute.layout<"((64,1),(8,2),(1,1)):((1,0),(64,512),(0,0))">
  %r = cute.tile_to_shape(%a, %b)
         : (!cute.layout<"(64,8):(1,64)">, !cute.shape<"((64,1),(16,1),1)">)
        -> !cute.layout<"((64,1),(8,2),(1,1)):((1,0),(64,512),(0,0))">
  return %r : !cute.layout<"((64,1),(8,2),(1,1)):((1,0),(64,512),(0,0))">
}

// -----

// Block (8,64):(64,1).
// CHECK-LABEL: func.func @CG_TEST_tts_s3_cm
func.func @CG_TEST_tts_s3_cm(
    %a: !cute.layout<"(8,64):(64,1)">,
    %b: !cute.shape<"((128,1),(16,4),1)">) -> !cute.layout<"((8,16),(64,1),(1,1)):((64,512),(1,0),(0,0))"> {
  // CHECK: cute.tile_to_shape(%{{.+}}, %{{.+}}) : (!cute.layout<"(8,64):(64,1)">, !cute.shape<"((128,1),(16,4),1)">) -> !cute.layout<"((8,16),(64,1),(1,1)):((64,512),(1,0),(0,0))">
  %r = cute.tile_to_shape(%a, %b)
         : (!cute.layout<"(8,64):(64,1)">, !cute.shape<"((128,1),(16,4),1)">)
        -> !cute.layout<"((8,16),(64,1),(1,1)):((64,512),(1,0),(0,0))">
  return %r : !cute.layout<"((8,16),(64,1),(1,1)):((64,512),(1,0),(0,0))">
}

// -----

// Block (8,64):(64,1), target ((64,1),(16,4),1).
// CHECK-LABEL: func.func @CG_TEST_tts_s4_cm
func.func @CG_TEST_tts_s4_cm(
    %a: !cute.layout<"(8,64):(64,1)">,
    %b: !cute.shape<"((64,1),(16,4),1)">) -> !cute.layout<"((8,8),(64,1),(1,1)):((64,512),(1,0),(0,0))"> {
  // CHECK: cute.tile_to_shape(%{{.+}}, %{{.+}}) : (!cute.layout<"(8,64):(64,1)">, !cute.shape<"((64,1),(16,4),1)">) -> !cute.layout<"((8,8),(64,1),(1,1)):((64,512),(1,0),(0,0))">
  %r = cute.tile_to_shape(%a, %b)
         : (!cute.layout<"(8,64):(64,1)">, !cute.shape<"((64,1),(16,4),1)">)
        -> !cute.layout<"((8,8),(64,1),(1,1)):((64,512),(1,0),(0,0))">
  return %r : !cute.layout<"((8,8),(64,1),(1,1)):((64,512),(1,0),(0,0))">
}

// -----

// Block (8,64):(64,1), flat target (64,128,2).
// CHECK-LABEL: func.func @CG_TEST_tts_s5_cm
func.func @CG_TEST_tts_s5_cm(
    %a: !cute.layout<"(8,64):(64,1)">,
    %b: !cute.shape<"(64,128,2)">) -> !cute.layout<"((8,8),(64,2),(1,2)):((64,512),(1,4096),(0,8192))"> {
  // CHECK: cute.tile_to_shape(%{{.+}}, %{{.+}}) : (!cute.layout<"(8,64):(64,1)">, !cute.shape<"(64,128,2)">) -> !cute.layout<"((8,8),(64,2),(1,2)):((64,512),(1,4096),(0,8192))">
  %r = cute.tile_to_shape(%a, %b)
         : (!cute.layout<"(8,64):(64,1)">, !cute.shape<"(64,128,2)">)
        -> !cute.layout<"((8,8),(64,2),(1,2)):((64,512),(1,4096),(0,8192))">
  return %r : !cute.layout<"((8,8),(64,2),(1,2)):((64,512),(1,4096),(0,8192))">
}

// -----

// Row-major variant.
// CHECK-LABEL: func.func @CG_TEST_tts_s5_rm
func.func @CG_TEST_tts_s5_rm(
    %a: !cute.layout<"(8,64):(64,1)">,
    %b: !cute.shape<"(64,128,2)">,
    %o: !cute.int_tuple<"(2,1,0)">) -> !cute.layout<"((8,8),(64,2),(1,2)):((64,2048),(1,1024),(0,512))"> {
  // CHECK: cute.tile_to_shape(%{{.+}}, %{{.+}}, %{{.+}}) : (!cute.layout<"(8,64):(64,1)">, !cute.shape<"(64,128,2)">, !cute.int_tuple<"(2,1,0)">) -> !cute.layout<"((8,8),(64,2),(1,2)):((64,2048),(1,1024),(0,512))">
  %r = cute.tile_to_shape(%a, %b, %o)
         : (!cute.layout<"(8,64):(64,1)">, !cute.shape<"(64,128,2)">, !cute.int_tuple<"(2,1,0)">)
        -> !cute.layout<"((8,8),(64,2),(1,2)):((64,2048),(1,1024),(0,512))">
  return %r : !cute.layout<"((8,8),(64,2),(1,2)):((64,2048),(1,1024),(0,512))">
}

// -----

// Same block, nested target ((16,4),(64,2),2).
// CHECK-LABEL: func.func @CG_TEST_tts_s6_cm
func.func @CG_TEST_tts_s6_cm(
    %a: !cute.layout<"(8,64):(64,1)">,
    %b: !cute.shape<"((16,4),(64,2),2)">) -> !cute.layout<"((8,8),(64,2),(1,2)):((64,512),(1,4096),(0,8192))"> {
  // CHECK: cute.tile_to_shape(%{{.+}}, %{{.+}}) : (!cute.layout<"(8,64):(64,1)">, !cute.shape<"((16,4),(64,2),2)">) -> !cute.layout<"((8,8),(64,2),(1,2)):((64,512),(1,4096),(0,8192))">
  %r = cute.tile_to_shape(%a, %b)
         : (!cute.layout<"(8,64):(64,1)">, !cute.shape<"((16,4),(64,2),2)">)
        -> !cute.layout<"((8,8),(64,2),(1,2)):((64,512),(1,4096),(0,8192))">
  return %r : !cute.layout<"((8,8),(64,2),(1,2)):((64,512),(1,4096),(0,8192))">
}

// -----

// Block (16,32):(1,16), target (32,64,(2,1)) with nested last mode.
// CHECK-LABEL: func.func @CG_TEST_tts_s7_cm
func.func @CG_TEST_tts_s7_cm(
    %a: !cute.layout<"(16,32):(1,16)">,
    %b: !cute.shape<"(32,64,(2,1))">) -> !cute.layout<"((16,2),(32,2),(1,2)):((1,512),(16,1024),(0,2048))"> {
  // CHECK: cute.tile_to_shape(%{{.+}}, %{{.+}}) : (!cute.layout<"(16,32):(1,16)">, !cute.shape<"(32,64,(2,1))">) -> !cute.layout<"((16,2),(32,2),(1,2)):((1,512),(16,1024),(0,2048))">
  %r = cute.tile_to_shape(%a, %b)
         : (!cute.layout<"(16,32):(1,16)">, !cute.shape<"(32,64,(2,1))">)
        -> !cute.layout<"((16,2),(32,2),(1,2)):((1,512),(16,1024),(0,2048))">
  return %r : !cute.layout<"((16,2),(32,2),(1,2)):((1,512),(16,1024),(0,2048))">
}

// -----

// Row-major variant.
// CHECK-LABEL: func.func @CG_TEST_tts_s7_rm
func.func @CG_TEST_tts_s7_rm(
    %a: !cute.layout<"(16,32):(1,16)">,
    %b: !cute.shape<"(32,64,(2,1))">,
    %o: !cute.int_tuple<"(2,1,0)">) -> !cute.layout<"((16,2),(32,2),(1,2)):((1,2048),(16,1024),(0,512))"> {
  // CHECK: cute.tile_to_shape(%{{.+}}, %{{.+}}, %{{.+}}) : (!cute.layout<"(16,32):(1,16)">, !cute.shape<"(32,64,(2,1))">, !cute.int_tuple<"(2,1,0)">) -> !cute.layout<"((16,2),(32,2),(1,2)):((1,2048),(16,1024),(0,512))">
  %r = cute.tile_to_shape(%a, %b, %o)
         : (!cute.layout<"(16,32):(1,16)">, !cute.shape<"(32,64,(2,1))">, !cute.int_tuple<"(2,1,0)">)
        -> !cute.layout<"((16,2),(32,2),(1,2)):((1,2048),(16,1024),(0,512))">
  return %r : !cute.layout<"((16,2),(32,2),(1,2)):((1,2048),(16,1024),(0,512))">
}

// -----

// Nested block ((32,4),(32,4)):((16,4),(0,1)), target (1024,256,2).
// CHECK-LABEL: func.func @CG_TEST_tts_s8_order_213
func.func @CG_TEST_tts_s8_order_213(
    %a: !cute.layout<"((32,4),(32,4)):((16,4),(0,1))">,
    %b: !cute.shape<"(1024,256,2)">,
    %o: !cute.int_tuple<"(1,0,2)">)
    -> !cute.layout<"(((32,4),8),((32,4),2),(1,2)):(((16,4),1024),((0,1),512),(0,8192))"> {
  // CHECK: cute.tile_to_shape(%{{.+}}, %{{.+}}, %{{.+}}) : (!cute.layout<"((32,4),(32,4)):((16,4),(0,1))">, !cute.shape<"(1024,256,2)">, !cute.int_tuple<"(1,0,2)">) -> !cute.layout<"(((32,4),8),((32,4),2),(1,2)):(((16,4),1024),((0,1),512),(0,8192))">
  %r = cute.tile_to_shape(%a, %b, %o)
         : (!cute.layout<"((32,4),(32,4)):((16,4),(0,1))">,
            !cute.shape<"(1024,256,2)">, !cute.int_tuple<"(1,0,2)">)
        -> !cute.layout<"(((32,4),8),((32,4),2),(1,2)):(((16,4),1024),((0,1),512),(0,8192))">
  return %r : !cute.layout<"(((32,4),8),((32,4),2),(1,2)):(((16,4),1024),((0,1),512),(0,8192))">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_tts_s8_order_123
func.func @CG_TEST_tts_s8_order_123(
    %a: !cute.layout<"((32,4),(32,4)):((16,4),(0,1))">,
    %b: !cute.shape<"(1024,256,2)">,
    %o: !cute.int_tuple<"(0,1,2)">)
    -> !cute.layout<"(((32,4),8),((32,4),2),(1,2)):(((16,4),512),((0,1),4096),(0,8192))"> {
  // CHECK: cute.tile_to_shape(%{{.+}}, %{{.+}}, %{{.+}}) : (!cute.layout<"((32,4),(32,4)):((16,4),(0,1))">, !cute.shape<"(1024,256,2)">, !cute.int_tuple<"(0,1,2)">) -> !cute.layout<"(((32,4),8),((32,4),2),(1,2)):(((16,4),512),((0,1),4096),(0,8192))">
  %r = cute.tile_to_shape(%a, %b, %o)
         : (!cute.layout<"((32,4),(32,4)):((16,4),(0,1))">,
            !cute.shape<"(1024,256,2)">, !cute.int_tuple<"(0,1,2)">)
        -> !cute.layout<"(((32,4),8),((32,4),2),(1,2)):(((16,4),512),((0,1),4096),(0,8192))">
  return %r : !cute.layout<"(((32,4),8),((32,4),2),(1,2)):(((16,4),512),((0,1),4096),(0,8192))">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_tts_s8_order_321
func.func @CG_TEST_tts_s8_order_321(
    %a: !cute.layout<"((32,4),(32,4)):((16,4),(0,1))">,
    %b: !cute.shape<"(1024,256,2)">,
    %o: !cute.int_tuple<"(2,1,0)">)
    -> !cute.layout<"(((32,4),8),((32,4),2),(1,2)):(((16,4),2048),((0,1),1024),(0,512))"> {
  // CHECK: cute.tile_to_shape(%{{.+}}, %{{.+}}, %{{.+}}) : (!cute.layout<"((32,4),(32,4)):((16,4),(0,1))">, !cute.shape<"(1024,256,2)">, !cute.int_tuple<"(2,1,0)">) -> !cute.layout<"(((32,4),8),((32,4),2),(1,2)):(((16,4),2048),((0,1),1024),(0,512))">
  %r = cute.tile_to_shape(%a, %b, %o)
         : (!cute.layout<"((32,4),(32,4)):((16,4),(0,1))">,
            !cute.shape<"(1024,256,2)">, !cute.int_tuple<"(2,1,0)">)
        -> !cute.layout<"(((32,4),8),((32,4),2),(1,2)):(((16,4),2048),((0,1),1024),(0,512))">
  return %r : !cute.layout<"(((32,4),8),((32,4),2),(1,2)):(((16,4),2048),((0,1),1024),(0,512))">
}

// -----

// Dynamic block + dynamic target; order (2,1,0) row-major.
// CHECK-LABEL: func.func @CG_TEST_tts_s9_dyn
func.func @CG_TEST_tts_s9_dyn(
    %a: !cute.layout<"((32,4),(?,4)):((16,4),(0,1))">,
    %b: !cute.shape<"(256,?,2)">,
    %o: !cute.int_tuple<"(2,1,0)">)
    -> !cute.layout<"(((32,4),2),((?,4),?),(1,2)):(((16,4),?),((0,1),1024),(0,512))"> {
  // CHECK: cute.tile_to_shape(%{{.+}}, %{{.+}}, %{{.+}}) : (!cute.layout<"((32,4),(?,4)):((16,4),(0,1))">, !cute.shape<"(256,?,2)">, !cute.int_tuple<"(2,1,0)">) -> !cute.layout<"(((32,4),2),((?,4),?),(1,2)):(((16,4),?),((0,1),1024),(0,512))">
  %r = cute.tile_to_shape(%a, %b, %o)
         : (!cute.layout<"((32,4),(?,4)):((16,4),(0,1))">,
            !cute.shape<"(256,?,2)">, !cute.int_tuple<"(2,1,0)">)
        -> !cute.layout<"(((32,4),2),((?,4),?),(1,2)):(((16,4),?),((0,1),1024),(0,512))">
  return %r : !cute.layout<"(((32,4),2),((?,4),?),(1,2)):(((16,4),?),((0,1),1024),(0,512))">
}
