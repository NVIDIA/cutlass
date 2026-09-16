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

// RUN: %cutlass-compiler-run-host %s | FileCheck %s
// RUN: cutlass-compiler -cute-fold-static -cute-expand-ops -cute-to-base \
// RUN:     -base-prepare %s | FileCheck --check-prefix=POST-PREP %s
//
// All-static flavor: cute-fold-static evaluates every op; no arith.* survives.
// POST-PREP-NOT: arith.

// CHECK-COUNT-2: ((3,4),(2,5)):((4,1),(12,24))
// CHECK-COUNT-2: ((3,4),(2,5)):((4,1),(12,24))
// CHECK-COUNT-2: ((3,4),2,5):((4,1),12,24)
// CHECK-COUNT-2: (3,4,2,5):(4,1,12,24)
// CHECK-COUNT-2: ((3,2),(4,5)):((4,12),(1,24))
// CHECK-COUNT-2: ((2,3),(5,4)):((12,4),(24,1))
// CHECK-COUNT-2: ((4,3),(2,5)):((1@0,1@1),(3@1,6@1))
// CHECK-COUNT-2: ((4,3),(2,5)):((1@0,1@1),(3@1,6@1))
// CHECK-COUNT-2: ((4,3),2,5):((1@0,1@1),3@1,6@1)
// CHECK-COUNT-2: (4,3,2,5):(1@0,1@1,3@1,6@1)
// CHECK-COUNT-2: ((4,2),(3,5)):((1@0,3@1),(1@1,6@1))
// CHECK-COUNT-2: ((2,4),(5,3)):((3@1,1@0),(6@1,1@1))
// CHECK-COUNT-2: ((3,2),(4,2)):((8,24),(1,4))
// CHECK-COUNT-2: ((3,(2,2)),4):((8,(24,1)),2)
// CHECK-COUNT-2: (((3),2),((4),2)):(((8),24),((1),4))
// CHECK-COUNT-2: S<3,4,3> o 0 o ((3,2),(4,2)):((8,24),(1,4))
// CHECK-COUNT-2: S<3,4,3> o 0 o ((3,(2,2)),4):((8,(24,1)),2)
// CHECK-COUNT-2: S<3,4,3> o 0 o (((3),2),((4),2)):(((8),24),((1),4))
// CHECK-COUNT-2: ((2,2),(3,1)):((1@0,2@0),(1@1,3@1))
// CHECK-COUNT-2: (((2),2),((3),1)):(((1@0),2@0),((1@1),3@1))
// CHECK-COUNT-2: ((3,4),(2,2)):((8,1),(24,4))
// CHECK-COUNT-2: ((3,(2,2)),4):((8,(24,1)),2)
// CHECK-COUNT-2: (((3),(4)),(2,2)):(((8),(1)),(24,4))
// CHECK-COUNT-2: S<3,4,3> o 0 o ((3,4),(2,2)):((8,1),(24,4))
// CHECK-COUNT-2: S<3,4,3> o 0 o ((3,(2,2)),4):((8,(24,1)),2)
// CHECK-COUNT-2: S<3,4,3> o 0 o (((3),(4)),(2,2)):(((8),(1)),(24,4))
// CHECK-COUNT-2: ((2,3),(2,1)):((1@0,1@1),(2@0,3@1))
// CHECK-COUNT-2: (((2),(3)),(2,1)):(((1@0),(1@1)),(2@0,3@1))
// CHECK-COUNT-2: ((3,4),2,2):((8,1),24,4)
// CHECK-COUNT-2: ((3,(2,2)),4):((8,(24,1)),2)
// CHECK-COUNT-2: (((3),(4)),2,2):(((8),(1)),24,4)
// CHECK-COUNT-2: S<3,4,3> o 0 o ((3,4),2,2):((8,1),24,4)
// CHECK-COUNT-2: S<3,4,3> o 0 o ((3,(2,2)),4):((8,(24,1)),2)
// CHECK-COUNT-2: S<3,4,3> o 0 o (((3),(4)),2,2):(((8),(1)),24,4)
// CHECK-COUNT-2: ((2,3),2,1):((1@0,1@1),2@0,3@1)
// CHECK-COUNT-2: (((2),(3)),2,1):(((1@0),(1@1)),2@0,3@1)
// CHECK-COUNT-2: (3,4,2,2):(8,1,24,4)
// CHECK-COUNT-2: (3,(2,2),4):(8,(24,1),2)
// CHECK-COUNT-2: ((3),(4),2,2):((8),(1),24,4)
// CHECK-COUNT-2: S<3,4,3> o 0 o (3,4,2,2):(8,1,24,4)
// CHECK-COUNT-2: S<3,4,3> o 0 o (3,(2,2),4):(8,(24,1),2)
// CHECK-COUNT-2: S<3,4,3> o 0 o ((3),(4),2,2):((8),(1),24,4)
// CHECK-COUNT-2: (2,3,2,1):(1@0,1@1,2@0,3@1)
// CHECK-COUNT-2: ((2),(3),2,1):((1@0),(1@1),2@0,3@1)
// CHECK-COUNT-2: ((3,2),(2,4)):((1,6),(3,12))
// CHECK-COUNT-2: ((3,2),(2,4)):((1,6),(3,12))
// CHECK-COUNT-2: ((3,2),(2,4)):((1,24),(3,6))

//===----------------------------------------------------------------------===//
// Per-op helpers.
//===----------------------------------------------------------------------===//

func.func @h_logical_product(%a: !cute.layout<"(3,4):(4,1)">,
                              %b: !cute.layout<"(2,5):(1,2)">)
    -> !cute.layout<"((3,4),(2,5)):((4,1),(12,24))"> {
  %r = cute.logical_product(%a, %b)
       : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(2,5):(1,2)">)
        -> !cute.layout<"((3,4),(2,5)):((4,1),(12,24))">
  return %r : !cute.layout<"((3,4),(2,5)):((4,1),(12,24))">
}

func.func @h_zipped_product(%a: !cute.layout<"(3,4):(4,1)">,
                             %b: !cute.layout<"(2,5):(1,2)">)
    -> !cute.layout<"((3,4),(2,5)):((4,1),(12,24))"> {
  %r = cute.zipped_product(%a, %b)
       : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(2,5):(1,2)">)
        -> !cute.layout<"((3,4),(2,5)):((4,1),(12,24))">
  return %r : !cute.layout<"((3,4),(2,5)):((4,1),(12,24))">
}

func.func @h_tiled_product(%a: !cute.layout<"(3,4):(4,1)">,
                            %b: !cute.layout<"(2,5):(1,2)">)
    -> !cute.layout<"((3,4),2,5):((4,1),12,24)"> {
  %r = cute.tiled_product(%a, %b)
       : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(2,5):(1,2)">)
        -> !cute.layout<"((3,4),2,5):((4,1),12,24)">
  return %r : !cute.layout<"((3,4),2,5):((4,1),12,24)">
}

func.func @h_flat_product(%a: !cute.layout<"(3,4):(4,1)">,
                           %b: !cute.layout<"(2,5):(1,2)">)
    -> !cute.layout<"(3,4,2,5):(4,1,12,24)"> {
  %r = cute.flat_product(%a, %b)
       : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(2,5):(1,2)">)
        -> !cute.layout<"(3,4,2,5):(4,1,12,24)">
  return %r : !cute.layout<"(3,4,2,5):(4,1,12,24)">
}

func.func @h_blocked_product(%a: !cute.layout<"(3,4):(4,1)">,
                              %b: !cute.layout<"(2,5):(1,2)">)
    -> !cute.layout<"((3,2),(4,5)):((4,12),(1,24))"> {
  %r = cute.blocked_product(%a, %b)
       : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(2,5):(1,2)">)
        -> !cute.layout<"((3,2),(4,5)):((4,12),(1,24))">
  return %r : !cute.layout<"((3,2),(4,5)):((4,12),(1,24))">
}

func.func @h_raked_product(%a: !cute.layout<"(3,4):(4,1)">,
                            %b: !cute.layout<"(2,5):(1,2)">)
    -> !cute.layout<"((2,3),(5,4)):((12,4),(24,1))"> {
  %r = cute.raked_product(%a, %b)
       : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(2,5):(1,2)">)
        -> !cute.layout<"((2,3),(5,4)):((12,4),(24,1))">
  return %r : !cute.layout<"((2,3),(5,4)):((12,4),(24,1))">
}

// Scaled-basis lhs variants — input has SB strides (`1@N`); tiler is
// fully static.

func.func @h_logical_product_scaled_basis_lhs(
    %a: !cute.layout<"(4,3):(1@0,1@1)">,
    %b: !cute.layout<"(2,5):(1,2)">)
    -> !cute.layout<"((4,3),(2,5)):((1@0,1@1),(3@1,6@1))"> {
  %r = cute.logical_product(%a, %b)
       : (!cute.layout<"(4,3):(1@0,1@1)">, !cute.layout<"(2,5):(1,2)">)
        -> !cute.layout<"((4,3),(2,5)):((1@0,1@1),(3@1,6@1))">
  return %r : !cute.layout<"((4,3),(2,5)):((1@0,1@1),(3@1,6@1))">
}

func.func @h_zipped_product_scaled_basis_lhs(
    %a: !cute.layout<"(4,3):(1@0,1@1)">,
    %b: !cute.layout<"(2,5):(1,2)">)
    -> !cute.layout<"((4,3),(2,5)):((1@0,1@1),(3@1,6@1))"> {
  %r = cute.zipped_product(%a, %b)
       : (!cute.layout<"(4,3):(1@0,1@1)">, !cute.layout<"(2,5):(1,2)">)
        -> !cute.layout<"((4,3),(2,5)):((1@0,1@1),(3@1,6@1))">
  return %r : !cute.layout<"((4,3),(2,5)):((1@0,1@1),(3@1,6@1))">
}

func.func @h_tiled_product_scaled_basis_lhs(
    %a: !cute.layout<"(4,3):(1@0,1@1)">,
    %b: !cute.layout<"(2,5):(1,2)">)
    -> !cute.layout<"((4,3),2,5):((1@0,1@1),3@1,6@1)"> {
  %r = cute.tiled_product(%a, %b)
       : (!cute.layout<"(4,3):(1@0,1@1)">, !cute.layout<"(2,5):(1,2)">)
        -> !cute.layout<"((4,3),2,5):((1@0,1@1),3@1,6@1)">
  return %r : !cute.layout<"((4,3),2,5):((1@0,1@1),3@1,6@1)">
}

func.func @h_flat_product_scaled_basis_lhs(
    %a: !cute.layout<"(4,3):(1@0,1@1)">,
    %b: !cute.layout<"(2,5):(1,2)">)
    -> !cute.layout<"(4,3,2,5):(1@0,1@1,3@1,6@1)"> {
  %r = cute.flat_product(%a, %b)
       : (!cute.layout<"(4,3):(1@0,1@1)">, !cute.layout<"(2,5):(1,2)">)
        -> !cute.layout<"(4,3,2,5):(1@0,1@1,3@1,6@1)">
  return %r : !cute.layout<"(4,3,2,5):(1@0,1@1,3@1,6@1)">
}

func.func @h_blocked_product_scaled_basis_lhs(
    %a: !cute.layout<"(4,3):(1@0,1@1)">,
    %b: !cute.layout<"(2,5):(1,2)">)
    -> !cute.layout<"((4,2),(3,5)):((1@0,3@1),(1@1,6@1))"> {
  %r = cute.blocked_product(%a, %b)
       : (!cute.layout<"(4,3):(1@0,1@1)">, !cute.layout<"(2,5):(1,2)">)
        -> !cute.layout<"((4,2),(3,5)):((1@0,3@1),(1@1,6@1))">
  return %r : !cute.layout<"((4,2),(3,5)):((1@0,3@1),(1@1,6@1))">
}

func.func @h_raked_product_scaled_basis_lhs(
    %a: !cute.layout<"(4,3):(1@0,1@1)">,
    %b: !cute.layout<"(2,5):(1,2)">)
    -> !cute.layout<"((2,4),(5,3)):((3@1,1@0),(6@1,1@1))"> {
  %r = cute.raked_product(%a, %b)
       : (!cute.layout<"(4,3):(1@0,1@1)">, !cute.layout<"(2,5):(1,2)">)
        -> !cute.layout<"((2,4),(5,3)):((3@1,1@0),(6@1,1@1))">
  return %r : !cute.layout<"((2,4),(5,3)):((3@1,1@0),(6@1,1@1))">
}

func.func @h_logical_divide(%a: !cute.layout<"(6,8):(8,1)">,
                             %b: !cute.shape<"(3,4)">)
    -> !cute.layout<"((3,2),(4,2)):((8,24),(1,4))"> {
  %r = cute.logical_divide(%a, %b)
       : (!cute.layout<"(6,8):(8,1)">, !cute.shape<"(3,4)">)
        -> !cute.layout<"((3,2),(4,2)):((8,24),(1,4))">
  return %r : !cute.layout<"((3,2),(4,2)):((8,24),(1,4))">
}

func.func @h_logical_divide_layout_tiler(
    %a: !cute.layout<"(6,8):(8,1)">,
    %b: !cute.layout<"(3,4):(1,3)">)
    -> !cute.layout<"((3,(2,2)),4):((8,(24,1)),2)"> {
  %r = cute.logical_divide(%a, %b)
       : (!cute.layout<"(6,8):(8,1)">, !cute.layout<"(3,4):(1,3)">)
        -> !cute.layout<"((3,(2,2)),4):((8,(24,1)),2)">
  return %r : !cute.layout<"((3,(2,2)),4):((8,(24,1)),2)">
}

func.func @h_logical_divide_tile_tiler(
    %a: !cute.layout<"(6,8):(8,1)">,
    %b: !cute.tile<"[(3):(1);(4):(1)]">)
    -> !cute.layout<"(((3),2),((4),2)):(((8),24),((1),4))"> {
  %r = cute.logical_divide(%a, %b)
       : (!cute.layout<"(6,8):(8,1)">, !cute.tile<"[(3):(1);(4):(1)]">)
        -> !cute.layout<"(((3),2),((4),2)):(((8),24),((1),4))">
  return %r : !cute.layout<"(((3),2),((4),2)):(((8),24),((1),4))">
}

func.func @h_logical_divide_composed_input(
    %a: !cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">,
    %b: !cute.shape<"(3,4)">)
    -> !cute.composed_layout<"S<3,4,3> o 0 o ((3,2),(4,2)):((8,24),(1,4))"> {
  %r = cute.logical_divide(%a, %b)
       : (!cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">,
          !cute.shape<"(3,4)">)
        -> !cute.composed_layout<"S<3,4,3> o 0 o ((3,2),(4,2)):((8,24),(1,4))">
  return %r : !cute.composed_layout<"S<3,4,3> o 0 o ((3,2),(4,2)):((8,24),(1,4))">
}

func.func @h_logical_divide_composed_input_layout_tiler(
    %a: !cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">,
    %b: !cute.layout<"(3,4):(1,3)">)
    -> !cute.composed_layout<"S<3,4,3> o 0 o ((3,(2,2)),4):((8,(24,1)),2)"> {
  %r = cute.logical_divide(%a, %b)
       : (!cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">,
          !cute.layout<"(3,4):(1,3)">)
        -> !cute.composed_layout<"S<3,4,3> o 0 o ((3,(2,2)),4):((8,(24,1)),2)">
  return %r : !cute.composed_layout<"S<3,4,3> o 0 o ((3,(2,2)),4):((8,(24,1)),2)">
}

func.func @h_logical_divide_composed_input_tile_tiler(
    %a: !cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">,
    %b: !cute.tile<"[(3):(1);(4):(1)]">)
    -> !cute.composed_layout<"S<3,4,3> o 0 o (((3),2),((4),2)):(((8),24),((1),4))"> {
  %r = cute.logical_divide(%a, %b)
       : (!cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">,
          !cute.tile<"[(3):(1);(4):(1)]">)
        -> !cute.composed_layout<"S<3,4,3> o 0 o (((3),2),((4),2)):(((8),24),((1),4))">
  return %r : !cute.composed_layout<"S<3,4,3> o 0 o (((3),2),((4),2)):(((8),24),((1),4))">
}

func.func @h_logical_divide_scaled_basis_shape(
    %a: !cute.layout<"(4,3):(1@0,1@1)">,
    %b: !cute.shape<"(2,3)">)
    -> !cute.layout<"((2,2),(3,1)):((1@0,2@0),(1@1,3@1))"> {
  %r = cute.logical_divide(%a, %b)
       : (!cute.layout<"(4,3):(1@0,1@1)">, !cute.shape<"(2,3)">)
        -> !cute.layout<"((2,2),(3,1)):((1@0,2@0),(1@1,3@1))">
  return %r : !cute.layout<"((2,2),(3,1)):((1@0,2@0),(1@1,3@1))">
}

func.func @h_logical_divide_scaled_basis_tile(
    %a: !cute.layout<"(4,3):(1@0,1@1)">,
    %b: !cute.tile<"[(2):(1);(3):(1)]">)
    -> !cute.layout<"(((2),2),((3),1)):(((1@0),2@0),((1@1),3@1))"> {
  %r = cute.logical_divide(%a, %b)
       : (!cute.layout<"(4,3):(1@0,1@1)">, !cute.tile<"[(2):(1);(3):(1)]">)
        -> !cute.layout<"(((2),2),((3),1)):(((1@0),2@0),((1@1),3@1))">
  return %r : !cute.layout<"(((2),2),((3),1)):(((1@0),2@0),((1@1),3@1))">
}

func.func @h_zipped_divide(%a: !cute.layout<"(6,8):(8,1)">,
                            %b: !cute.shape<"(3,4)">)
    -> !cute.layout<"((3,4),(2,2)):((8,1),(24,4))"> {
  %r = cute.zipped_divide(%a, %b)
       : (!cute.layout<"(6,8):(8,1)">, !cute.shape<"(3,4)">)
        -> !cute.layout<"((3,4),(2,2)):((8,1),(24,4))">
  return %r : !cute.layout<"((3,4),(2,2)):((8,1),(24,4))">
}

func.func @h_zipped_divide_layout_tiler(
    %a: !cute.layout<"(6,8):(8,1)">,
    %b: !cute.layout<"(3,4):(1,3)">)
    -> !cute.layout<"((3,(2,2)),4):((8,(24,1)),2)"> {
  %r = cute.zipped_divide(%a, %b)
       : (!cute.layout<"(6,8):(8,1)">, !cute.layout<"(3,4):(1,3)">) -> !cute.layout<"((3,(2,2)),4):((8,(24,1)),2)">
  return %r : !cute.layout<"((3,(2,2)),4):((8,(24,1)),2)">
}

func.func @h_zipped_divide_tile_tiler(
    %a: !cute.layout<"(6,8):(8,1)">,
    %b: !cute.tile<"[(3):(1);(4):(1)]">)
    -> !cute.layout<"(((3),(4)),(2,2)):(((8),(1)),(24,4))"> {
  %r = cute.zipped_divide(%a, %b)
       : (!cute.layout<"(6,8):(8,1)">, !cute.tile<"[(3):(1);(4):(1)]">) -> !cute.layout<"(((3),(4)),(2,2)):(((8),(1)),(24,4))">
  return %r : !cute.layout<"(((3),(4)),(2,2)):(((8),(1)),(24,4))">
}

func.func @h_zipped_divide_composed_input(
    %a: !cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">,
    %b: !cute.shape<"(3,4)">)
    -> !cute.composed_layout<"S<3,4,3> o 0 o ((3,4),(2,2)):((8,1),(24,4))"> {
  %r = cute.zipped_divide(%a, %b)
       : (!cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">, !cute.shape<"(3,4)">) -> !cute.composed_layout<"S<3,4,3> o 0 o ((3,4),(2,2)):((8,1),(24,4))">
  return %r : !cute.composed_layout<"S<3,4,3> o 0 o ((3,4),(2,2)):((8,1),(24,4))">
}

func.func @h_zipped_divide_composed_input_layout_tiler(
    %a: !cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">,
    %b: !cute.layout<"(3,4):(1,3)">)
    -> !cute.composed_layout<"S<3,4,3> o 0 o ((3,(2,2)),4):((8,(24,1)),2)"> {
  %r = cute.zipped_divide(%a, %b)
       : (!cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">, !cute.layout<"(3,4):(1,3)">) -> !cute.composed_layout<"S<3,4,3> o 0 o ((3,(2,2)),4):((8,(24,1)),2)">
  return %r : !cute.composed_layout<"S<3,4,3> o 0 o ((3,(2,2)),4):((8,(24,1)),2)">
}

func.func @h_zipped_divide_composed_input_tile_tiler(
    %a: !cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">,
    %b: !cute.tile<"[(3):(1);(4):(1)]">)
    -> !cute.composed_layout<"S<3,4,3> o 0 o (((3),(4)),(2,2)):(((8),(1)),(24,4))"> {
  %r = cute.zipped_divide(%a, %b)
       : (!cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">, !cute.tile<"[(3):(1);(4):(1)]">) -> !cute.composed_layout<"S<3,4,3> o 0 o (((3),(4)),(2,2)):(((8),(1)),(24,4))">
  return %r : !cute.composed_layout<"S<3,4,3> o 0 o (((3),(4)),(2,2)):(((8),(1)),(24,4))">
}

func.func @h_zipped_divide_scaled_basis_shape(
    %a: !cute.layout<"(4,3):(1@0,1@1)">,
    %b: !cute.shape<"(2,3)">)
    -> !cute.layout<"((2,3),(2,1)):((1@0,1@1),(2@0,3@1))"> {
  %r = cute.zipped_divide(%a, %b)
       : (!cute.layout<"(4,3):(1@0,1@1)">, !cute.shape<"(2,3)">) -> !cute.layout<"((2,3),(2,1)):((1@0,1@1),(2@0,3@1))">
  return %r : !cute.layout<"((2,3),(2,1)):((1@0,1@1),(2@0,3@1))">
}

func.func @h_zipped_divide_scaled_basis_tile(
    %a: !cute.layout<"(4,3):(1@0,1@1)">,
    %b: !cute.tile<"[(2):(1);(3):(1)]">)
    -> !cute.layout<"(((2),(3)),(2,1)):(((1@0),(1@1)),(2@0,3@1))"> {
  %r = cute.zipped_divide(%a, %b)
       : (!cute.layout<"(4,3):(1@0,1@1)">, !cute.tile<"[(2):(1);(3):(1)]">) -> !cute.layout<"(((2),(3)),(2,1)):(((1@0),(1@1)),(2@0,3@1))">
  return %r : !cute.layout<"(((2),(3)),(2,1)):(((1@0),(1@1)),(2@0,3@1))">
}

func.func @h_tiled_divide(%a: !cute.layout<"(6,8):(8,1)">,
                           %b: !cute.shape<"(3,4)">)
    -> !cute.layout<"((3,4),2,2):((8,1),24,4)"> {
  %r = cute.tiled_divide(%a, %b)
       : (!cute.layout<"(6,8):(8,1)">, !cute.shape<"(3,4)">)
        -> !cute.layout<"((3,4),2,2):((8,1),24,4)">
  return %r : !cute.layout<"((3,4),2,2):((8,1),24,4)">
}

func.func @h_tiled_divide_layout_tiler(
    %a: !cute.layout<"(6,8):(8,1)">,
    %b: !cute.layout<"(3,4):(1,3)">)
    -> !cute.layout<"((3,(2,2)),4):((8,(24,1)),2)"> {
  %r = cute.tiled_divide(%a, %b)
       : (!cute.layout<"(6,8):(8,1)">, !cute.layout<"(3,4):(1,3)">) -> !cute.layout<"((3,(2,2)),4):((8,(24,1)),2)">
  return %r : !cute.layout<"((3,(2,2)),4):((8,(24,1)),2)">
}

func.func @h_tiled_divide_tile_tiler(
    %a: !cute.layout<"(6,8):(8,1)">,
    %b: !cute.tile<"[(3):(1);(4):(1)]">)
    -> !cute.layout<"(((3),(4)),2,2):(((8),(1)),24,4)"> {
  %r = cute.tiled_divide(%a, %b)
       : (!cute.layout<"(6,8):(8,1)">, !cute.tile<"[(3):(1);(4):(1)]">) -> !cute.layout<"(((3),(4)),2,2):(((8),(1)),24,4)">
  return %r : !cute.layout<"(((3),(4)),2,2):(((8),(1)),24,4)">
}

func.func @h_tiled_divide_composed_input(
    %a: !cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">,
    %b: !cute.shape<"(3,4)">)
    -> !cute.composed_layout<"S<3,4,3> o 0 o ((3,4),2,2):((8,1),24,4)"> {
  %r = cute.tiled_divide(%a, %b)
       : (!cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">, !cute.shape<"(3,4)">) -> !cute.composed_layout<"S<3,4,3> o 0 o ((3,4),2,2):((8,1),24,4)">
  return %r : !cute.composed_layout<"S<3,4,3> o 0 o ((3,4),2,2):((8,1),24,4)">
}

func.func @h_tiled_divide_composed_input_layout_tiler(
    %a: !cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">,
    %b: !cute.layout<"(3,4):(1,3)">)
    -> !cute.composed_layout<"S<3,4,3> o 0 o ((3,(2,2)),4):((8,(24,1)),2)"> {
  %r = cute.tiled_divide(%a, %b)
       : (!cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">, !cute.layout<"(3,4):(1,3)">) -> !cute.composed_layout<"S<3,4,3> o 0 o ((3,(2,2)),4):((8,(24,1)),2)">
  return %r : !cute.composed_layout<"S<3,4,3> o 0 o ((3,(2,2)),4):((8,(24,1)),2)">
}

func.func @h_tiled_divide_composed_input_tile_tiler(
    %a: !cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">,
    %b: !cute.tile<"[(3):(1);(4):(1)]">)
    -> !cute.composed_layout<"S<3,4,3> o 0 o (((3),(4)),2,2):(((8),(1)),24,4)"> {
  %r = cute.tiled_divide(%a, %b)
       : (!cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">, !cute.tile<"[(3):(1);(4):(1)]">) -> !cute.composed_layout<"S<3,4,3> o 0 o (((3),(4)),2,2):(((8),(1)),24,4)">
  return %r : !cute.composed_layout<"S<3,4,3> o 0 o (((3),(4)),2,2):(((8),(1)),24,4)">
}

func.func @h_tiled_divide_scaled_basis_shape(
    %a: !cute.layout<"(4,3):(1@0,1@1)">,
    %b: !cute.shape<"(2,3)">)
    -> !cute.layout<"((2,3),2,1):((1@0,1@1),2@0,3@1)"> {
  %r = cute.tiled_divide(%a, %b)
       : (!cute.layout<"(4,3):(1@0,1@1)">, !cute.shape<"(2,3)">) -> !cute.layout<"((2,3),2,1):((1@0,1@1),2@0,3@1)">
  return %r : !cute.layout<"((2,3),2,1):((1@0,1@1),2@0,3@1)">
}

func.func @h_tiled_divide_scaled_basis_tile(
    %a: !cute.layout<"(4,3):(1@0,1@1)">,
    %b: !cute.tile<"[(2):(1);(3):(1)]">)
    -> !cute.layout<"(((2),(3)),2,1):(((1@0),(1@1)),2@0,3@1)"> {
  %r = cute.tiled_divide(%a, %b)
       : (!cute.layout<"(4,3):(1@0,1@1)">, !cute.tile<"[(2):(1);(3):(1)]">) -> !cute.layout<"(((2),(3)),2,1):(((1@0),(1@1)),2@0,3@1)">
  return %r : !cute.layout<"(((2),(3)),2,1):(((1@0),(1@1)),2@0,3@1)">
}

func.func @h_flat_divide(%a: !cute.layout<"(6,8):(8,1)">,
                          %b: !cute.shape<"(3,4)">)
    -> !cute.layout<"(3,4,2,2):(8,1,24,4)"> {
  %r = cute.flat_divide(%a, %b)
       : (!cute.layout<"(6,8):(8,1)">, !cute.shape<"(3,4)">)
        -> !cute.layout<"(3,4,2,2):(8,1,24,4)">
  return %r : !cute.layout<"(3,4,2,2):(8,1,24,4)">
}

func.func @h_flat_divide_layout_tiler(
    %a: !cute.layout<"(6,8):(8,1)">,
    %b: !cute.layout<"(3,4):(1,3)">)
    -> !cute.layout<"(3,(2,2),4):(8,(24,1),2)"> {
  %r = cute.flat_divide(%a, %b)
       : (!cute.layout<"(6,8):(8,1)">, !cute.layout<"(3,4):(1,3)">) -> !cute.layout<"(3,(2,2),4):(8,(24,1),2)">
  return %r : !cute.layout<"(3,(2,2),4):(8,(24,1),2)">
}

func.func @h_flat_divide_tile_tiler(
    %a: !cute.layout<"(6,8):(8,1)">,
    %b: !cute.tile<"[(3):(1);(4):(1)]">)
    -> !cute.layout<"((3),(4),2,2):((8),(1),24,4)"> {
  %r = cute.flat_divide(%a, %b)
       : (!cute.layout<"(6,8):(8,1)">, !cute.tile<"[(3):(1);(4):(1)]">) -> !cute.layout<"((3),(4),2,2):((8),(1),24,4)">
  return %r : !cute.layout<"((3),(4),2,2):((8),(1),24,4)">
}

func.func @h_flat_divide_composed_input(
    %a: !cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">,
    %b: !cute.shape<"(3,4)">)
    -> !cute.composed_layout<"S<3,4,3> o 0 o (3,4,2,2):(8,1,24,4)"> {
  %r = cute.flat_divide(%a, %b)
       : (!cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">, !cute.shape<"(3,4)">) -> !cute.composed_layout<"S<3,4,3> o 0 o (3,4,2,2):(8,1,24,4)">
  return %r : !cute.composed_layout<"S<3,4,3> o 0 o (3,4,2,2):(8,1,24,4)">
}

func.func @h_flat_divide_composed_input_layout_tiler(
    %a: !cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">,
    %b: !cute.layout<"(3,4):(1,3)">)
    -> !cute.composed_layout<"S<3,4,3> o 0 o (3,(2,2),4):(8,(24,1),2)"> {
  %r = cute.flat_divide(%a, %b)
       : (!cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">, !cute.layout<"(3,4):(1,3)">) -> !cute.composed_layout<"S<3,4,3> o 0 o (3,(2,2),4):(8,(24,1),2)">
  return %r : !cute.composed_layout<"S<3,4,3> o 0 o (3,(2,2),4):(8,(24,1),2)">
}

func.func @h_flat_divide_composed_input_tile_tiler(
    %a: !cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">,
    %b: !cute.tile<"[(3):(1);(4):(1)]">)
    -> !cute.composed_layout<"S<3,4,3> o 0 o ((3),(4),2,2):((8),(1),24,4)"> {
  %r = cute.flat_divide(%a, %b)
       : (!cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">, !cute.tile<"[(3):(1);(4):(1)]">) -> !cute.composed_layout<"S<3,4,3> o 0 o ((3),(4),2,2):((8),(1),24,4)">
  return %r : !cute.composed_layout<"S<3,4,3> o 0 o ((3),(4),2,2):((8),(1),24,4)">
}

func.func @h_flat_divide_scaled_basis_shape(
    %a: !cute.layout<"(4,3):(1@0,1@1)">,
    %b: !cute.shape<"(2,3)">)
    -> !cute.layout<"(2,3,2,1):(1@0,1@1,2@0,3@1)"> {
  %r = cute.flat_divide(%a, %b)
       : (!cute.layout<"(4,3):(1@0,1@1)">, !cute.shape<"(2,3)">) -> !cute.layout<"(2,3,2,1):(1@0,1@1,2@0,3@1)">
  return %r : !cute.layout<"(2,3,2,1):(1@0,1@1,2@0,3@1)">
}

func.func @h_flat_divide_scaled_basis_tile(
    %a: !cute.layout<"(4,3):(1@0,1@1)">,
    %b: !cute.tile<"[(2):(1);(3):(1)]">)
    -> !cute.layout<"((2),(3),2,1):((1@0),(1@1),2@0,3@1)"> {
  %r = cute.flat_divide(%a, %b)
       : (!cute.layout<"(4,3):(1@0,1@1)">, !cute.tile<"[(2):(1);(3):(1)]">) -> !cute.layout<"((2),(3),2,1):((1@0),(1@1),2@0,3@1)">
  return %r : !cute.layout<"((2),(3),2,1):((1@0),(1@1),2@0,3@1)">
}

func.func @h_tile_to_shape(%a: !cute.layout<"(3,2):(1,3)">,
                            %b: !cute.shape<"(6,8)">)
    -> !cute.layout<"((3,2),(2,4)):((1,6),(3,12))"> {
  %r = cute.tile_to_shape(%a, %b)
       : (!cute.layout<"(3,2):(1,3)">, !cute.shape<"(6,8)">)
        -> !cute.layout<"((3,2),(2,4)):((1,6),(3,12))">
  return %r : !cute.layout<"((3,2),(2,4)):((1,6),(3,12))">
}

func.func @h_tile_to_shape_order_natural(
    %a: !cute.layout<"(3,2):(1,3)">,
    %b: !cute.shape<"(6,8)">,
    %o: !cute.int_tuple<"(0,1)">)
    -> !cute.layout<"((3,2),(2,4)):((1,6),(3,12))"> {
  %r = cute.tile_to_shape(%a, %b, %o)
       : (!cute.layout<"(3,2):(1,3)">, !cute.shape<"(6,8)">,
          !cute.int_tuple<"(0,1)">)
        -> !cute.layout<"((3,2),(2,4)):((1,6),(3,12))">
  return %r : !cute.layout<"((3,2),(2,4)):((1,6),(3,12))">
}

func.func @h_tile_to_shape_order_swap(
    %a: !cute.layout<"(3,2):(1,3)">,
    %b: !cute.shape<"(6,8)">,
    %o: !cute.int_tuple<"(1,0)">)
    -> !cute.layout<"((3,2),(2,4)):((1,24),(3,6))"> {
  %r = cute.tile_to_shape(%a, %b, %o)
       : (!cute.layout<"(3,2):(1,3)">, !cute.shape<"(6,8)">,
          !cute.int_tuple<"(1,0)">)
        -> !cute.layout<"((3,2),(2,4)):((1,24),(3,6))">
  return %r : !cute.layout<"((3,2),(2,4)):((1,24),(3,6))">
}

//===----------------------------------------------------------------------===//
// Entry point.
//===----------------------------------------------------------------------===//

func.func @main() {
  %a = cute.static : !cute.layout<"(3,4):(4,1)">
  %b = cute.static : !cute.layout<"(2,5):(1,2)">

  // logical_product
  %r1 = cute.logical_product(%a, %b)
       : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(2,5):(1,2)">)
        -> !cute.layout<"((3,4),(2,5)):((4,1),(12,24))">
  cute.print(%r1) : !cute.layout<"((3,4),(2,5)):((4,1),(12,24))">
  %r1b = func.call @h_logical_product(%a, %b)
       : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(2,5):(1,2)">)
        -> !cute.layout<"((3,4),(2,5)):((4,1),(12,24))">
  cute.print(%r1b) : !cute.layout<"((3,4),(2,5)):((4,1),(12,24))">

  // zipped_product
  %r2 = cute.zipped_product(%a, %b)
       : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(2,5):(1,2)">)
        -> !cute.layout<"((3,4),(2,5)):((4,1),(12,24))">
  cute.print(%r2) : !cute.layout<"((3,4),(2,5)):((4,1),(12,24))">
  %r2b = func.call @h_zipped_product(%a, %b)
       : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(2,5):(1,2)">)
        -> !cute.layout<"((3,4),(2,5)):((4,1),(12,24))">
  cute.print(%r2b) : !cute.layout<"((3,4),(2,5)):((4,1),(12,24))">

  // tiled_product
  %r3 = cute.tiled_product(%a, %b)
       : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(2,5):(1,2)">)
        -> !cute.layout<"((3,4),2,5):((4,1),12,24)">
  cute.print(%r3) : !cute.layout<"((3,4),2,5):((4,1),12,24)">
  %r3b = func.call @h_tiled_product(%a, %b)
       : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(2,5):(1,2)">)
        -> !cute.layout<"((3,4),2,5):((4,1),12,24)">
  cute.print(%r3b) : !cute.layout<"((3,4),2,5):((4,1),12,24)">

  // flat_product
  %r4 = cute.flat_product(%a, %b)
       : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(2,5):(1,2)">)
        -> !cute.layout<"(3,4,2,5):(4,1,12,24)">
  cute.print(%r4) : !cute.layout<"(3,4,2,5):(4,1,12,24)">
  %r4b = func.call @h_flat_product(%a, %b)
       : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(2,5):(1,2)">)
        -> !cute.layout<"(3,4,2,5):(4,1,12,24)">
  cute.print(%r4b) : !cute.layout<"(3,4,2,5):(4,1,12,24)">

  // blocked_product
  %r5 = cute.blocked_product(%a, %b)
       : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(2,5):(1,2)">)
        -> !cute.layout<"((3,2),(4,5)):((4,12),(1,24))">
  cute.print(%r5) : !cute.layout<"((3,2),(4,5)):((4,12),(1,24))">
  %r5b = func.call @h_blocked_product(%a, %b)
       : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(2,5):(1,2)">)
        -> !cute.layout<"((3,2),(4,5)):((4,12),(1,24))">
  cute.print(%r5b) : !cute.layout<"((3,2),(4,5)):((4,12),(1,24))">

  // raked_product
  %r6 = cute.raked_product(%a, %b)
       : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(2,5):(1,2)">)
        -> !cute.layout<"((2,3),(5,4)):((12,4),(24,1))">
  cute.print(%r6) : !cute.layout<"((2,3),(5,4)):((12,4),(24,1))">
  %r6b = func.call @h_raked_product(%a, %b)
       : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(2,5):(1,2)">)
        -> !cute.layout<"((2,3),(5,4)):((12,4),(24,1))">
  cute.print(%r6b) : !cute.layout<"((2,3),(5,4)):((12,4),(24,1))">

  // Scaled-basis lhs across all 6 product ops — input has SB strides;
  // tiler is fully static (the cross-operand pre-check requires it).
  %psb = cute.static : !cute.layout<"(4,3):(1@0,1@1)">

  // logical_product (SB lhs)
  %r_psb1 = cute.logical_product(%psb, %b)
       : (!cute.layout<"(4,3):(1@0,1@1)">, !cute.layout<"(2,5):(1,2)">)
        -> !cute.layout<"((4,3),(2,5)):((1@0,1@1),(3@1,6@1))">
  cute.print(%r_psb1) : !cute.layout<"((4,3),(2,5)):((1@0,1@1),(3@1,6@1))">
  %r_psb1b = func.call @h_logical_product_scaled_basis_lhs(%psb, %b)
       : (!cute.layout<"(4,3):(1@0,1@1)">, !cute.layout<"(2,5):(1,2)">)
        -> !cute.layout<"((4,3),(2,5)):((1@0,1@1),(3@1,6@1))">
  cute.print(%r_psb1b) : !cute.layout<"((4,3),(2,5)):((1@0,1@1),(3@1,6@1))">

  // zipped_product (SB lhs) — same result shape as logical_product.
  %r_psb2 = cute.zipped_product(%psb, %b)
       : (!cute.layout<"(4,3):(1@0,1@1)">, !cute.layout<"(2,5):(1,2)">)
        -> !cute.layout<"((4,3),(2,5)):((1@0,1@1),(3@1,6@1))">
  cute.print(%r_psb2) : !cute.layout<"((4,3),(2,5)):((1@0,1@1),(3@1,6@1))">
  %r_psb2b = func.call @h_zipped_product_scaled_basis_lhs(%psb, %b)
       : (!cute.layout<"(4,3):(1@0,1@1)">, !cute.layout<"(2,5):(1,2)">)
        -> !cute.layout<"((4,3),(2,5)):((1@0,1@1),(3@1,6@1))">
  cute.print(%r_psb2b) : !cute.layout<"((4,3),(2,5)):((1@0,1@1),(3@1,6@1))">

  // tiled_product (SB lhs)
  %r_psb3 = cute.tiled_product(%psb, %b)
       : (!cute.layout<"(4,3):(1@0,1@1)">, !cute.layout<"(2,5):(1,2)">)
        -> !cute.layout<"((4,3),2,5):((1@0,1@1),3@1,6@1)">
  cute.print(%r_psb3) : !cute.layout<"((4,3),2,5):((1@0,1@1),3@1,6@1)">
  %r_psb3b = func.call @h_tiled_product_scaled_basis_lhs(%psb, %b)
       : (!cute.layout<"(4,3):(1@0,1@1)">, !cute.layout<"(2,5):(1,2)">)
        -> !cute.layout<"((4,3),2,5):((1@0,1@1),3@1,6@1)">
  cute.print(%r_psb3b) : !cute.layout<"((4,3),2,5):((1@0,1@1),3@1,6@1)">

  // flat_product (SB lhs)
  %r_psb4 = cute.flat_product(%psb, %b)
       : (!cute.layout<"(4,3):(1@0,1@1)">, !cute.layout<"(2,5):(1,2)">)
        -> !cute.layout<"(4,3,2,5):(1@0,1@1,3@1,6@1)">
  cute.print(%r_psb4) : !cute.layout<"(4,3,2,5):(1@0,1@1,3@1,6@1)">
  %r_psb4b = func.call @h_flat_product_scaled_basis_lhs(%psb, %b)
       : (!cute.layout<"(4,3):(1@0,1@1)">, !cute.layout<"(2,5):(1,2)">)
        -> !cute.layout<"(4,3,2,5):(1@0,1@1,3@1,6@1)">
  cute.print(%r_psb4b) : !cute.layout<"(4,3,2,5):(1@0,1@1,3@1,6@1)">

  // blocked_product (SB lhs)
  %r_psb5 = cute.blocked_product(%psb, %b)
       : (!cute.layout<"(4,3):(1@0,1@1)">, !cute.layout<"(2,5):(1,2)">)
        -> !cute.layout<"((4,2),(3,5)):((1@0,3@1),(1@1,6@1))">
  cute.print(%r_psb5) : !cute.layout<"((4,2),(3,5)):((1@0,3@1),(1@1,6@1))">
  %r_psb5b = func.call @h_blocked_product_scaled_basis_lhs(%psb, %b)
       : (!cute.layout<"(4,3):(1@0,1@1)">, !cute.layout<"(2,5):(1,2)">)
        -> !cute.layout<"((4,2),(3,5)):((1@0,3@1),(1@1,6@1))">
  cute.print(%r_psb5b) : !cute.layout<"((4,2),(3,5)):((1@0,3@1),(1@1,6@1))">

  // raked_product (SB lhs)
  %r_psb6 = cute.raked_product(%psb, %b)
       : (!cute.layout<"(4,3):(1@0,1@1)">, !cute.layout<"(2,5):(1,2)">)
        -> !cute.layout<"((2,4),(5,3)):((3@1,1@0),(6@1,1@1))">
  cute.print(%r_psb6) : !cute.layout<"((2,4),(5,3)):((3@1,1@0),(6@1,1@1))">
  %r_psb6b = func.call @h_raked_product_scaled_basis_lhs(%psb, %b)
       : (!cute.layout<"(4,3):(1@0,1@1)">, !cute.layout<"(2,5):(1,2)">)
        -> !cute.layout<"((2,4),(5,3)):((3@1,1@0),(6@1,1@1))">
  cute.print(%r_psb6b) : !cute.layout<"((2,4),(5,3)):((3@1,1@0),(6@1,1@1))">

  // Divides — fresh inputs.
  %da = cute.static : !cute.layout<"(6,8):(8,1)">
  %db = cute.static : !cute.shape<"(3,4)">

  // logical_divide
  %r7 = cute.logical_divide(%da, %db)
       : (!cute.layout<"(6,8):(8,1)">, !cute.shape<"(3,4)">)
        -> !cute.layout<"((3,2),(4,2)):((8,24),(1,4))">
  cute.print(%r7) : !cute.layout<"((3,2),(4,2)):((8,24),(1,4))">
  %r7b = func.call @h_logical_divide(%da, %db)
       : (!cute.layout<"(6,8):(8,1)">, !cute.shape<"(3,4)">)
        -> !cute.layout<"((3,2),(4,2)):((8,24),(1,4))">
  cute.print(%r7b) : !cute.layout<"((3,2),(4,2)):((8,24),(1,4))">

  // logical_divide with layout tiler.
  %dlt = cute.static : !cute.layout<"(3,4):(1,3)">
  %r7c = cute.logical_divide(%da, %dlt)
       : (!cute.layout<"(6,8):(8,1)">, !cute.layout<"(3,4):(1,3)">)
        -> !cute.layout<"((3,(2,2)),4):((8,(24,1)),2)">
  cute.print(%r7c) : !cute.layout<"((3,(2,2)),4):((8,(24,1)),2)">
  %r7cb = func.call @h_logical_divide_layout_tiler(%da, %dlt)
       : (!cute.layout<"(6,8):(8,1)">, !cute.layout<"(3,4):(1,3)">)
        -> !cute.layout<"((3,(2,2)),4):((8,(24,1)),2)">
  cute.print(%r7cb) : !cute.layout<"((3,(2,2)),4):((8,(24,1)),2)">

  // logical_divide with tile tiler.
  %dtt = cute.static : !cute.tile<"[(3):(1);(4):(1)]">
  %r7d = cute.logical_divide(%da, %dtt)
       : (!cute.layout<"(6,8):(8,1)">, !cute.tile<"[(3):(1);(4):(1)]">)
        -> !cute.layout<"(((3),2),((4),2)):(((8),24),((1),4))">
  cute.print(%r7d) : !cute.layout<"(((3),2),((4),2)):(((8),24),((1),4))">
  %r7db = func.call @h_logical_divide_tile_tiler(%da, %dtt)
       : (!cute.layout<"(6,8):(8,1)">, !cute.tile<"[(3):(1);(4):(1)]">)
        -> !cute.layout<"(((3),2),((4),2)):(((8),24),((1),4))">
  cute.print(%r7db) : !cute.layout<"(((3),2),((4),2)):(((8),24),((1),4))">

  // logical_divide with composed input — wrap preserved.
  %dca = cute.static : !cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">
  %r7e = cute.logical_divide(%dca, %db)
       : (!cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">,
          !cute.shape<"(3,4)">)
        -> !cute.composed_layout<"S<3,4,3> o 0 o ((3,2),(4,2)):((8,24),(1,4))">
  cute.print(%r7e) : !cute.composed_layout<"S<3,4,3> o 0 o ((3,2),(4,2)):((8,24),(1,4))">
  %r7eb = func.call @h_logical_divide_composed_input(%dca, %db)
       : (!cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">,
          !cute.shape<"(3,4)">)
        -> !cute.composed_layout<"S<3,4,3> o 0 o ((3,2),(4,2)):((8,24),(1,4))">
  cute.print(%r7eb) : !cute.composed_layout<"S<3,4,3> o 0 o ((3,2),(4,2)):((8,24),(1,4))">

  // logical_divide composed input × layout tiler — wrap + non-shape tiler.
  %r7f = cute.logical_divide(%dca, %dlt)
       : (!cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">,
          !cute.layout<"(3,4):(1,3)">)
        -> !cute.composed_layout<"S<3,4,3> o 0 o ((3,(2,2)),4):((8,(24,1)),2)">
  cute.print(%r7f) : !cute.composed_layout<"S<3,4,3> o 0 o ((3,(2,2)),4):((8,(24,1)),2)">
  %r7fb = func.call @h_logical_divide_composed_input_layout_tiler(%dca, %dlt)
       : (!cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">,
          !cute.layout<"(3,4):(1,3)">)
        -> !cute.composed_layout<"S<3,4,3> o 0 o ((3,(2,2)),4):((8,(24,1)),2)">
  cute.print(%r7fb) : !cute.composed_layout<"S<3,4,3> o 0 o ((3,(2,2)),4):((8,(24,1)),2)">

  // logical_divide composed input × tile tiler — wrap + tile tiler.
  %r7g = cute.logical_divide(%dca, %dtt)
       : (!cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">,
          !cute.tile<"[(3):(1);(4):(1)]">)
        -> !cute.composed_layout<"S<3,4,3> o 0 o (((3),2),((4),2)):(((8),24),((1),4))">
  cute.print(%r7g) : !cute.composed_layout<"S<3,4,3> o 0 o (((3),2),((4),2)):(((8),24),((1),4))">
  %r7gb = func.call @h_logical_divide_composed_input_tile_tiler(%dca, %dtt)
       : (!cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">,
          !cute.tile<"[(3):(1);(4):(1)]">)
        -> !cute.composed_layout<"S<3,4,3> o 0 o (((3),2),((4),2)):(((8),24),((1),4))">
  cute.print(%r7gb) : !cute.composed_layout<"S<3,4,3> o 0 o (((3),2),((4),2)):(((8),24),((1),4))">

  // logical_divide scaled-basis input × shape tiler — scaled-basis values
  // (1@N) are static and survive the `cute.static` fold.
  %dsb = cute.static : !cute.layout<"(4,3):(1@0,1@1)">
  %dsb_sh = cute.static : !cute.shape<"(2,3)">
  %r7h = cute.logical_divide(%dsb, %dsb_sh)
       : (!cute.layout<"(4,3):(1@0,1@1)">, !cute.shape<"(2,3)">)
        -> !cute.layout<"((2,2),(3,1)):((1@0,2@0),(1@1,3@1))">
  cute.print(%r7h) : !cute.layout<"((2,2),(3,1)):((1@0,2@0),(1@1,3@1))">
  %r7hb = func.call @h_logical_divide_scaled_basis_shape(%dsb, %dsb_sh)
       : (!cute.layout<"(4,3):(1@0,1@1)">, !cute.shape<"(2,3)">)
        -> !cute.layout<"((2,2),(3,1)):((1@0,2@0),(1@1,3@1))">
  cute.print(%r7hb) : !cute.layout<"((2,2),(3,1)):((1@0,2@0),(1@1,3@1))">

  // logical_divide scaled-basis input × tile tiler.
  %dsb_tt = cute.static : !cute.tile<"[(2):(1);(3):(1)]">
  %r7i = cute.logical_divide(%dsb, %dsb_tt)
       : (!cute.layout<"(4,3):(1@0,1@1)">, !cute.tile<"[(2):(1);(3):(1)]">)
        -> !cute.layout<"(((2),2),((3),1)):(((1@0),2@0),((1@1),3@1))">
  cute.print(%r7i) : !cute.layout<"(((2),2),((3),1)):(((1@0),2@0),((1@1),3@1))">
  %r7ib = func.call @h_logical_divide_scaled_basis_tile(%dsb, %dsb_tt)
       : (!cute.layout<"(4,3):(1@0,1@1)">, !cute.tile<"[(2):(1);(3):(1)]">)
        -> !cute.layout<"(((2),2),((3),1)):(((1@0),2@0),((1@1),3@1))">
  cute.print(%r7ib) : !cute.layout<"(((2),2),((3),1)):(((1@0),2@0),((1@1),3@1))">

  // zipped_divide
  %r8 = cute.zipped_divide(%da, %db)
       : (!cute.layout<"(6,8):(8,1)">, !cute.shape<"(3,4)">)
        -> !cute.layout<"((3,4),(2,2)):((8,1),(24,4))">
  cute.print(%r8) : !cute.layout<"((3,4),(2,2)):((8,1),(24,4))">
  %r8b = func.call @h_zipped_divide(%da, %db)
       : (!cute.layout<"(6,8):(8,1)">, !cute.shape<"(3,4)">)
        -> !cute.layout<"((3,4),(2,2)):((8,1),(24,4))">
  cute.print(%r8b) : !cute.layout<"((3,4),(2,2)):((8,1),(24,4))">

  %r_zb1 = cute.zipped_divide(%da, %dlt)
        : (!cute.layout<"(6,8):(8,1)">, !cute.layout<"(3,4):(1,3)">) -> !cute.layout<"((3,(2,2)),4):((8,(24,1)),2)">
  cute.print(%r_zb1) : !cute.layout<"((3,(2,2)),4):((8,(24,1)),2)">
  %r_zb1b = func.call @h_zipped_divide_layout_tiler(%da, %dlt)
        : (!cute.layout<"(6,8):(8,1)">, !cute.layout<"(3,4):(1,3)">) -> !cute.layout<"((3,(2,2)),4):((8,(24,1)),2)">
  cute.print(%r_zb1b) : !cute.layout<"((3,(2,2)),4):((8,(24,1)),2)">

  %r_zb2 = cute.zipped_divide(%da, %dtt)
        : (!cute.layout<"(6,8):(8,1)">, !cute.tile<"[(3):(1);(4):(1)]">) -> !cute.layout<"(((3),(4)),(2,2)):(((8),(1)),(24,4))">
  cute.print(%r_zb2) : !cute.layout<"(((3),(4)),(2,2)):(((8),(1)),(24,4))">
  %r_zb2b = func.call @h_zipped_divide_tile_tiler(%da, %dtt)
        : (!cute.layout<"(6,8):(8,1)">, !cute.tile<"[(3):(1);(4):(1)]">) -> !cute.layout<"(((3),(4)),(2,2)):(((8),(1)),(24,4))">
  cute.print(%r_zb2b) : !cute.layout<"(((3),(4)),(2,2)):(((8),(1)),(24,4))">

  %r_zb3 = cute.zipped_divide(%dca, %db)
        : (!cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">, !cute.shape<"(3,4)">) -> !cute.composed_layout<"S<3,4,3> o 0 o ((3,4),(2,2)):((8,1),(24,4))">
  cute.print(%r_zb3) : !cute.composed_layout<"S<3,4,3> o 0 o ((3,4),(2,2)):((8,1),(24,4))">
  %r_zb3b = func.call @h_zipped_divide_composed_input(%dca, %db)
        : (!cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">, !cute.shape<"(3,4)">) -> !cute.composed_layout<"S<3,4,3> o 0 o ((3,4),(2,2)):((8,1),(24,4))">
  cute.print(%r_zb3b) : !cute.composed_layout<"S<3,4,3> o 0 o ((3,4),(2,2)):((8,1),(24,4))">

  %r_zb4 = cute.zipped_divide(%dca, %dlt)
        : (!cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">, !cute.layout<"(3,4):(1,3)">) -> !cute.composed_layout<"S<3,4,3> o 0 o ((3,(2,2)),4):((8,(24,1)),2)">
  cute.print(%r_zb4) : !cute.composed_layout<"S<3,4,3> o 0 o ((3,(2,2)),4):((8,(24,1)),2)">
  %r_zb4b = func.call @h_zipped_divide_composed_input_layout_tiler(%dca, %dlt)
        : (!cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">, !cute.layout<"(3,4):(1,3)">) -> !cute.composed_layout<"S<3,4,3> o 0 o ((3,(2,2)),4):((8,(24,1)),2)">
  cute.print(%r_zb4b) : !cute.composed_layout<"S<3,4,3> o 0 o ((3,(2,2)),4):((8,(24,1)),2)">

  %r_zb5 = cute.zipped_divide(%dca, %dtt)
        : (!cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">, !cute.tile<"[(3):(1);(4):(1)]">) -> !cute.composed_layout<"S<3,4,3> o 0 o (((3),(4)),(2,2)):(((8),(1)),(24,4))">
  cute.print(%r_zb5) : !cute.composed_layout<"S<3,4,3> o 0 o (((3),(4)),(2,2)):(((8),(1)),(24,4))">
  %r_zb5b = func.call @h_zipped_divide_composed_input_tile_tiler(%dca, %dtt)
        : (!cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">, !cute.tile<"[(3):(1);(4):(1)]">) -> !cute.composed_layout<"S<3,4,3> o 0 o (((3),(4)),(2,2)):(((8),(1)),(24,4))">
  cute.print(%r_zb5b) : !cute.composed_layout<"S<3,4,3> o 0 o (((3),(4)),(2,2)):(((8),(1)),(24,4))">

  %r_zb6 = cute.zipped_divide(%dsb, %dsb_sh)
        : (!cute.layout<"(4,3):(1@0,1@1)">, !cute.shape<"(2,3)">) -> !cute.layout<"((2,3),(2,1)):((1@0,1@1),(2@0,3@1))">
  cute.print(%r_zb6) : !cute.layout<"((2,3),(2,1)):((1@0,1@1),(2@0,3@1))">
  %r_zb6b = func.call @h_zipped_divide_scaled_basis_shape(%dsb, %dsb_sh)
        : (!cute.layout<"(4,3):(1@0,1@1)">, !cute.shape<"(2,3)">) -> !cute.layout<"((2,3),(2,1)):((1@0,1@1),(2@0,3@1))">
  cute.print(%r_zb6b) : !cute.layout<"((2,3),(2,1)):((1@0,1@1),(2@0,3@1))">

  %r_zb7 = cute.zipped_divide(%dsb, %dsb_tt)
        : (!cute.layout<"(4,3):(1@0,1@1)">, !cute.tile<"[(2):(1);(3):(1)]">) -> !cute.layout<"(((2),(3)),(2,1)):(((1@0),(1@1)),(2@0,3@1))">
  cute.print(%r_zb7) : !cute.layout<"(((2),(3)),(2,1)):(((1@0),(1@1)),(2@0,3@1))">
  %r_zb7b = func.call @h_zipped_divide_scaled_basis_tile(%dsb, %dsb_tt)
        : (!cute.layout<"(4,3):(1@0,1@1)">, !cute.tile<"[(2):(1);(3):(1)]">) -> !cute.layout<"(((2),(3)),(2,1)):(((1@0),(1@1)),(2@0,3@1))">
  cute.print(%r_zb7b) : !cute.layout<"(((2),(3)),(2,1)):(((1@0),(1@1)),(2@0,3@1))">

  // tiled_divide
  %r9 = cute.tiled_divide(%da, %db)
       : (!cute.layout<"(6,8):(8,1)">, !cute.shape<"(3,4)">)
        -> !cute.layout<"((3,4),2,2):((8,1),24,4)">
  cute.print(%r9) : !cute.layout<"((3,4),2,2):((8,1),24,4)">
  %r9b = func.call @h_tiled_divide(%da, %db)
       : (!cute.layout<"(6,8):(8,1)">, !cute.shape<"(3,4)">)
        -> !cute.layout<"((3,4),2,2):((8,1),24,4)">
  cute.print(%r9b) : !cute.layout<"((3,4),2,2):((8,1),24,4)">

  %r_tc1 = cute.tiled_divide(%da, %dlt)
        : (!cute.layout<"(6,8):(8,1)">, !cute.layout<"(3,4):(1,3)">) -> !cute.layout<"((3,(2,2)),4):((8,(24,1)),2)">
  cute.print(%r_tc1) : !cute.layout<"((3,(2,2)),4):((8,(24,1)),2)">
  %r_tc1b = func.call @h_tiled_divide_layout_tiler(%da, %dlt)
        : (!cute.layout<"(6,8):(8,1)">, !cute.layout<"(3,4):(1,3)">) -> !cute.layout<"((3,(2,2)),4):((8,(24,1)),2)">
  cute.print(%r_tc1b) : !cute.layout<"((3,(2,2)),4):((8,(24,1)),2)">

  %r_tc2 = cute.tiled_divide(%da, %dtt)
        : (!cute.layout<"(6,8):(8,1)">, !cute.tile<"[(3):(1);(4):(1)]">) -> !cute.layout<"(((3),(4)),2,2):(((8),(1)),24,4)">
  cute.print(%r_tc2) : !cute.layout<"(((3),(4)),2,2):(((8),(1)),24,4)">
  %r_tc2b = func.call @h_tiled_divide_tile_tiler(%da, %dtt)
        : (!cute.layout<"(6,8):(8,1)">, !cute.tile<"[(3):(1);(4):(1)]">) -> !cute.layout<"(((3),(4)),2,2):(((8),(1)),24,4)">
  cute.print(%r_tc2b) : !cute.layout<"(((3),(4)),2,2):(((8),(1)),24,4)">

  %r_tc3 = cute.tiled_divide(%dca, %db)
        : (!cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">, !cute.shape<"(3,4)">) -> !cute.composed_layout<"S<3,4,3> o 0 o ((3,4),2,2):((8,1),24,4)">
  cute.print(%r_tc3) : !cute.composed_layout<"S<3,4,3> o 0 o ((3,4),2,2):((8,1),24,4)">
  %r_tc3b = func.call @h_tiled_divide_composed_input(%dca, %db)
        : (!cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">, !cute.shape<"(3,4)">) -> !cute.composed_layout<"S<3,4,3> o 0 o ((3,4),2,2):((8,1),24,4)">
  cute.print(%r_tc3b) : !cute.composed_layout<"S<3,4,3> o 0 o ((3,4),2,2):((8,1),24,4)">

  %r_tc4 = cute.tiled_divide(%dca, %dlt)
        : (!cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">, !cute.layout<"(3,4):(1,3)">) -> !cute.composed_layout<"S<3,4,3> o 0 o ((3,(2,2)),4):((8,(24,1)),2)">
  cute.print(%r_tc4) : !cute.composed_layout<"S<3,4,3> o 0 o ((3,(2,2)),4):((8,(24,1)),2)">
  %r_tc4b = func.call @h_tiled_divide_composed_input_layout_tiler(%dca, %dlt)
        : (!cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">, !cute.layout<"(3,4):(1,3)">) -> !cute.composed_layout<"S<3,4,3> o 0 o ((3,(2,2)),4):((8,(24,1)),2)">
  cute.print(%r_tc4b) : !cute.composed_layout<"S<3,4,3> o 0 o ((3,(2,2)),4):((8,(24,1)),2)">

  %r_tc5 = cute.tiled_divide(%dca, %dtt)
        : (!cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">, !cute.tile<"[(3):(1);(4):(1)]">) -> !cute.composed_layout<"S<3,4,3> o 0 o (((3),(4)),2,2):(((8),(1)),24,4)">
  cute.print(%r_tc5) : !cute.composed_layout<"S<3,4,3> o 0 o (((3),(4)),2,2):(((8),(1)),24,4)">
  %r_tc5b = func.call @h_tiled_divide_composed_input_tile_tiler(%dca, %dtt)
        : (!cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">, !cute.tile<"[(3):(1);(4):(1)]">) -> !cute.composed_layout<"S<3,4,3> o 0 o (((3),(4)),2,2):(((8),(1)),24,4)">
  cute.print(%r_tc5b) : !cute.composed_layout<"S<3,4,3> o 0 o (((3),(4)),2,2):(((8),(1)),24,4)">

  %r_tc6 = cute.tiled_divide(%dsb, %dsb_sh)
        : (!cute.layout<"(4,3):(1@0,1@1)">, !cute.shape<"(2,3)">) -> !cute.layout<"((2,3),2,1):((1@0,1@1),2@0,3@1)">
  cute.print(%r_tc6) : !cute.layout<"((2,3),2,1):((1@0,1@1),2@0,3@1)">
  %r_tc6b = func.call @h_tiled_divide_scaled_basis_shape(%dsb, %dsb_sh)
        : (!cute.layout<"(4,3):(1@0,1@1)">, !cute.shape<"(2,3)">) -> !cute.layout<"((2,3),2,1):((1@0,1@1),2@0,3@1)">
  cute.print(%r_tc6b) : !cute.layout<"((2,3),2,1):((1@0,1@1),2@0,3@1)">

  %r_tc7 = cute.tiled_divide(%dsb, %dsb_tt)
        : (!cute.layout<"(4,3):(1@0,1@1)">, !cute.tile<"[(2):(1);(3):(1)]">) -> !cute.layout<"(((2),(3)),2,1):(((1@0),(1@1)),2@0,3@1)">
  cute.print(%r_tc7) : !cute.layout<"(((2),(3)),2,1):(((1@0),(1@1)),2@0,3@1)">
  %r_tc7b = func.call @h_tiled_divide_scaled_basis_tile(%dsb, %dsb_tt)
        : (!cute.layout<"(4,3):(1@0,1@1)">, !cute.tile<"[(2):(1);(3):(1)]">) -> !cute.layout<"(((2),(3)),2,1):(((1@0),(1@1)),2@0,3@1)">
  cute.print(%r_tc7b) : !cute.layout<"(((2),(3)),2,1):(((1@0),(1@1)),2@0,3@1)">

  // flat_divide
  %r10 = cute.flat_divide(%da, %db)
       : (!cute.layout<"(6,8):(8,1)">, !cute.shape<"(3,4)">)
        -> !cute.layout<"(3,4,2,2):(8,1,24,4)">
  cute.print(%r10) : !cute.layout<"(3,4,2,2):(8,1,24,4)">
  %r10b = func.call @h_flat_divide(%da, %db)
       : (!cute.layout<"(6,8):(8,1)">, !cute.shape<"(3,4)">)
        -> !cute.layout<"(3,4,2,2):(8,1,24,4)">
  cute.print(%r10b) : !cute.layout<"(3,4,2,2):(8,1,24,4)">

  %r_fd1 = cute.flat_divide(%da, %dlt)
        : (!cute.layout<"(6,8):(8,1)">, !cute.layout<"(3,4):(1,3)">) -> !cute.layout<"(3,(2,2),4):(8,(24,1),2)">
  cute.print(%r_fd1) : !cute.layout<"(3,(2,2),4):(8,(24,1),2)">
  %r_fd1b = func.call @h_flat_divide_layout_tiler(%da, %dlt)
        : (!cute.layout<"(6,8):(8,1)">, !cute.layout<"(3,4):(1,3)">) -> !cute.layout<"(3,(2,2),4):(8,(24,1),2)">
  cute.print(%r_fd1b) : !cute.layout<"(3,(2,2),4):(8,(24,1),2)">

  %r_fd2 = cute.flat_divide(%da, %dtt)
        : (!cute.layout<"(6,8):(8,1)">, !cute.tile<"[(3):(1);(4):(1)]">) -> !cute.layout<"((3),(4),2,2):((8),(1),24,4)">
  cute.print(%r_fd2) : !cute.layout<"((3),(4),2,2):((8),(1),24,4)">
  %r_fd2b = func.call @h_flat_divide_tile_tiler(%da, %dtt)
        : (!cute.layout<"(6,8):(8,1)">, !cute.tile<"[(3):(1);(4):(1)]">) -> !cute.layout<"((3),(4),2,2):((8),(1),24,4)">
  cute.print(%r_fd2b) : !cute.layout<"((3),(4),2,2):((8),(1),24,4)">

  %r_fd3 = cute.flat_divide(%dca, %db)
        : (!cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">, !cute.shape<"(3,4)">) -> !cute.composed_layout<"S<3,4,3> o 0 o (3,4,2,2):(8,1,24,4)">
  cute.print(%r_fd3) : !cute.composed_layout<"S<3,4,3> o 0 o (3,4,2,2):(8,1,24,4)">
  %r_fd3b = func.call @h_flat_divide_composed_input(%dca, %db)
        : (!cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">, !cute.shape<"(3,4)">) -> !cute.composed_layout<"S<3,4,3> o 0 o (3,4,2,2):(8,1,24,4)">
  cute.print(%r_fd3b) : !cute.composed_layout<"S<3,4,3> o 0 o (3,4,2,2):(8,1,24,4)">

  %r_fd4 = cute.flat_divide(%dca, %dlt)
        : (!cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">, !cute.layout<"(3,4):(1,3)">) -> !cute.composed_layout<"S<3,4,3> o 0 o (3,(2,2),4):(8,(24,1),2)">
  cute.print(%r_fd4) : !cute.composed_layout<"S<3,4,3> o 0 o (3,(2,2),4):(8,(24,1),2)">
  %r_fd4b = func.call @h_flat_divide_composed_input_layout_tiler(%dca, %dlt)
        : (!cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">, !cute.layout<"(3,4):(1,3)">) -> !cute.composed_layout<"S<3,4,3> o 0 o (3,(2,2),4):(8,(24,1),2)">
  cute.print(%r_fd4b) : !cute.composed_layout<"S<3,4,3> o 0 o (3,(2,2),4):(8,(24,1),2)">

  %r_fd5 = cute.flat_divide(%dca, %dtt)
        : (!cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">, !cute.tile<"[(3):(1);(4):(1)]">) -> !cute.composed_layout<"S<3,4,3> o 0 o ((3),(4),2,2):((8),(1),24,4)">
  cute.print(%r_fd5) : !cute.composed_layout<"S<3,4,3> o 0 o ((3),(4),2,2):((8),(1),24,4)">
  %r_fd5b = func.call @h_flat_divide_composed_input_tile_tiler(%dca, %dtt)
        : (!cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">, !cute.tile<"[(3):(1);(4):(1)]">) -> !cute.composed_layout<"S<3,4,3> o 0 o ((3),(4),2,2):((8),(1),24,4)">
  cute.print(%r_fd5b) : !cute.composed_layout<"S<3,4,3> o 0 o ((3),(4),2,2):((8),(1),24,4)">

  %r_fd6 = cute.flat_divide(%dsb, %dsb_sh)
        : (!cute.layout<"(4,3):(1@0,1@1)">, !cute.shape<"(2,3)">) -> !cute.layout<"(2,3,2,1):(1@0,1@1,2@0,3@1)">
  cute.print(%r_fd6) : !cute.layout<"(2,3,2,1):(1@0,1@1,2@0,3@1)">
  %r_fd6b = func.call @h_flat_divide_scaled_basis_shape(%dsb, %dsb_sh)
        : (!cute.layout<"(4,3):(1@0,1@1)">, !cute.shape<"(2,3)">) -> !cute.layout<"(2,3,2,1):(1@0,1@1,2@0,3@1)">
  cute.print(%r_fd6b) : !cute.layout<"(2,3,2,1):(1@0,1@1,2@0,3@1)">

  %r_fd7 = cute.flat_divide(%dsb, %dsb_tt)
        : (!cute.layout<"(4,3):(1@0,1@1)">, !cute.tile<"[(2):(1);(3):(1)]">) -> !cute.layout<"((2),(3),2,1):((1@0),(1@1),2@0,3@1)">
  cute.print(%r_fd7) : !cute.layout<"((2),(3),2,1):((1@0),(1@1),2@0,3@1)">
  %r_fd7b = func.call @h_flat_divide_scaled_basis_tile(%dsb, %dsb_tt)
        : (!cute.layout<"(4,3):(1@0,1@1)">, !cute.tile<"[(2):(1);(3):(1)]">) -> !cute.layout<"((2),(3),2,1):((1@0),(1@1),2@0,3@1)">
  cute.print(%r_fd7b) : !cute.layout<"((2),(3),2,1):((1@0),(1@1),2@0,3@1)">

  // tile_to_shape
  %tta = cute.static : !cute.layout<"(3,2):(1,3)">
  %ttb = cute.static : !cute.shape<"(6,8)">
  %r12 = cute.tile_to_shape(%tta, %ttb)
       : (!cute.layout<"(3,2):(1,3)">, !cute.shape<"(6,8)">)
        -> !cute.layout<"((3,2),(2,4)):((1,6),(3,12))">
  cute.print(%r12) : !cute.layout<"((3,2),(2,4)):((1,6),(3,12))">
  %r12b = func.call @h_tile_to_shape(%tta, %ttb)
       : (!cute.layout<"(3,2):(1,3)">, !cute.shape<"(6,8)">)
        -> !cute.layout<"((3,2),(2,4)):((1,6),(3,12))">
  cute.print(%r12b) : !cute.layout<"((3,2),(2,4)):((1,6),(3,12))">

  // tile_to_shape with order = (0,1) — natural order; result strides
  // match the no-order case above.
  %tto_n = cute.static : !cute.int_tuple<"(0,1)">
  %r13 = cute.tile_to_shape(%tta, %ttb, %tto_n)
       : (!cute.layout<"(3,2):(1,3)">, !cute.shape<"(6,8)">,
          !cute.int_tuple<"(0,1)">)
        -> !cute.layout<"((3,2),(2,4)):((1,6),(3,12))">
  cute.print(%r13) : !cute.layout<"((3,2),(2,4)):((1,6),(3,12))">
  %r13b = func.call @h_tile_to_shape_order_natural(%tta, %ttb, %tto_n)
       : (!cute.layout<"(3,2):(1,3)">, !cute.shape<"(6,8)">,
          !cute.int_tuple<"(0,1)">)
        -> !cute.layout<"((3,2),(2,4)):((1,6),(3,12))">
  cute.print(%r13b) : !cute.layout<"((3,2),(2,4)):((1,6),(3,12))">

  // tile_to_shape with order = (1,0) — swapped order; same shape as the
  // natural case, but the per-axis replication strides differ.
  %tto_s = cute.static : !cute.int_tuple<"(1,0)">
  %r14 = cute.tile_to_shape(%tta, %ttb, %tto_s)
       : (!cute.layout<"(3,2):(1,3)">, !cute.shape<"(6,8)">,
          !cute.int_tuple<"(1,0)">)
        -> !cute.layout<"((3,2),(2,4)):((1,24),(3,6))">
  cute.print(%r14) : !cute.layout<"((3,2),(2,4)):((1,24),(3,6))">
  %r14b = func.call @h_tile_to_shape_order_swap(%tta, %ttb, %tto_s)
       : (!cute.layout<"(3,2):(1,3)">, !cute.shape<"(6,8)">,
          !cute.int_tuple<"(1,0)">)
        -> !cute.layout<"((3,2),(2,4)):((1,24),(3,6))">
  cute.print(%r14b) : !cute.layout<"((3,2),(2,4)):((1,24),(3,6))">

  return
}
