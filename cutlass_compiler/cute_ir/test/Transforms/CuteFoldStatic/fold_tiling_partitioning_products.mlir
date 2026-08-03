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

// RUN: cute-opt -cute-fold-static --split-input-file %s | FileCheck %s

// cute-fold-static: tiling/partitioning ops with fully-static results fold to cute.static.

// -----

//===----------------------------------------------------------------------===//
// logical_product
//===----------------------------------------------------------------------===//

// CHECK-LABEL: func.func @fold_logical_product_layout
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.layout<"((3,4),(2,5)):((4,1),(12,24))">
// CHECK-NEXT:    return %[[R]]
func.func @fold_logical_product_layout()
    -> !cute.layout<"((3,4),(2,5)):((4,1),(12,24))"> {
  %a_shape = cute.make_shape () : () -> !cute.shape<"(3,4)">
  %a_stride = cute.make_stride () : () -> !cute.stride<"(4,1)">
  %a = cute.make_layout (%a_shape, %a_stride) : (!cute.shape<"(3,4)">, !cute.stride<"(4,1)">) -> !cute.layout<"(3,4):(4,1)">
  %b_shape = cute.make_shape () : () -> !cute.shape<"(2,5)">
  %b_stride = cute.make_stride () : () -> !cute.stride<"(1,2)">
  %b = cute.make_layout (%b_shape, %b_stride) : (!cute.shape<"(2,5)">, !cute.stride<"(1,2)">) -> !cute.layout<"(2,5):(1,2)">
  %r = cute.logical_product(%a, %b)
         : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(2,5):(1,2)">)
        -> !cute.layout<"((3,4),(2,5)):((4,1),(12,24))">
  return %r : !cute.layout<"((3,4),(2,5)):((4,1),(12,24))">
}

// -----

// CHECK-LABEL: func.func @fold_logical_product_composed_layout
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.composed_layout<"S<3,4,3> o 0 o ((3,4),(2,5)):((4,1),(12,24))">
// CHECK-NEXT:    return %[[R]]
func.func @fold_logical_product_composed_layout(
    %a: !cute.composed_layout<"S<3,4,3> o 0 o (3,4):(4,1)">)
    -> !cute.composed_layout<"S<3,4,3> o 0 o ((3,4),(2,5)):((4,1),(12,24))"> {
  %b_shape = cute.make_shape () : () -> !cute.shape<"(2,5)">
  %b_stride = cute.make_stride () : () -> !cute.stride<"(1,2)">
  %b = cute.make_layout (%b_shape, %b_stride) : (!cute.shape<"(2,5)">, !cute.stride<"(1,2)">) -> !cute.layout<"(2,5):(1,2)">
  %r = cute.logical_product(%a, %b)
         : (!cute.composed_layout<"S<3,4,3> o 0 o (3,4):(4,1)">,
            !cute.layout<"(2,5):(1,2)">)
        -> !cute.composed_layout<"S<3,4,3> o 0 o ((3,4),(2,5)):((4,1),(12,24))">
  return %r : !cute.composed_layout<"S<3,4,3> o 0 o ((3,4),(2,5)):((4,1),(12,24))">
}

// -----

//===----------------------------------------------------------------------===//
// zipped_product
//===----------------------------------------------------------------------===//

// CHECK-LABEL: func.func @fold_zipped_product_layout
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.layout<"((3,4),(2,5)):((4,1),(12,24))">
// CHECK-NEXT:    return %[[R]]
func.func @fold_zipped_product_layout()
    -> !cute.layout<"((3,4),(2,5)):((4,1),(12,24))"> {
  %a_shape = cute.make_shape () : () -> !cute.shape<"(3,4)">
  %a_stride = cute.make_stride () : () -> !cute.stride<"(4,1)">
  %a = cute.make_layout (%a_shape, %a_stride) : (!cute.shape<"(3,4)">, !cute.stride<"(4,1)">) -> !cute.layout<"(3,4):(4,1)">
  %b_shape = cute.make_shape () : () -> !cute.shape<"(2,5)">
  %b_stride = cute.make_stride () : () -> !cute.stride<"(1,2)">
  %b = cute.make_layout (%b_shape, %b_stride) : (!cute.shape<"(2,5)">, !cute.stride<"(1,2)">) -> !cute.layout<"(2,5):(1,2)">
  %r = cute.zipped_product(%a, %b)
         : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(2,5):(1,2)">)
        -> !cute.layout<"((3,4),(2,5)):((4,1),(12,24))">
  return %r : !cute.layout<"((3,4),(2,5)):((4,1),(12,24))">
}

// -----

// CHECK-LABEL: func.func @fold_zipped_product_composed_layout
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.composed_layout<"S<3,4,3> o 0 o ((3,4),(2,5)):((4,1),(12,24))">
// CHECK-NEXT:    return %[[R]]
func.func @fold_zipped_product_composed_layout(
    %a: !cute.composed_layout<"S<3,4,3> o 0 o (3,4):(4,1)">)
    -> !cute.composed_layout<"S<3,4,3> o 0 o ((3,4),(2,5)):((4,1),(12,24))"> {
  %b_shape = cute.make_shape () : () -> !cute.shape<"(2,5)">
  %b_stride = cute.make_stride () : () -> !cute.stride<"(1,2)">
  %b = cute.make_layout (%b_shape, %b_stride) : (!cute.shape<"(2,5)">, !cute.stride<"(1,2)">) -> !cute.layout<"(2,5):(1,2)">
  %r = cute.zipped_product(%a, %b)
         : (!cute.composed_layout<"S<3,4,3> o 0 o (3,4):(4,1)">,
            !cute.layout<"(2,5):(1,2)">)
        -> !cute.composed_layout<"S<3,4,3> o 0 o ((3,4),(2,5)):((4,1),(12,24))">
  return %r : !cute.composed_layout<"S<3,4,3> o 0 o ((3,4),(2,5)):((4,1),(12,24))">
}

// -----

//===----------------------------------------------------------------------===//
// tiled_product
//===----------------------------------------------------------------------===//

// CHECK-LABEL: func.func @fold_tiled_product_layout
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.layout<"((3,4),2,5):((4,1),12,24)">
// CHECK-NEXT:    return %[[R]]
func.func @fold_tiled_product_layout() -> !cute.layout<"((3,4),2,5):((4,1),12,24)"> {
  %a_shape = cute.make_shape () : () -> !cute.shape<"(3,4)">
  %a_stride = cute.make_stride () : () -> !cute.stride<"(4,1)">
  %a = cute.make_layout (%a_shape, %a_stride) : (!cute.shape<"(3,4)">, !cute.stride<"(4,1)">) -> !cute.layout<"(3,4):(4,1)">
  %b_shape = cute.make_shape () : () -> !cute.shape<"(2,5)">
  %b_stride = cute.make_stride () : () -> !cute.stride<"(1,2)">
  %b = cute.make_layout (%b_shape, %b_stride) : (!cute.shape<"(2,5)">, !cute.stride<"(1,2)">) -> !cute.layout<"(2,5):(1,2)">
  %r = cute.tiled_product(%a, %b)
         : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(2,5):(1,2)">)
        -> !cute.layout<"((3,4),2,5):((4,1),12,24)">
  return %r : !cute.layout<"((3,4),2,5):((4,1),12,24)">
}

// -----

// CHECK-LABEL: func.func @fold_tiled_product_composed_layout
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.composed_layout<"S<3,4,3> o 0 o ((3,4),2,5):((4,1),12,24)">
// CHECK-NEXT:    return %[[R]]
func.func @fold_tiled_product_composed_layout(
    %a: !cute.composed_layout<"S<3,4,3> o 0 o (3,4):(4,1)">)
    -> !cute.composed_layout<"S<3,4,3> o 0 o ((3,4),2,5):((4,1),12,24)"> {
  %b_shape = cute.make_shape () : () -> !cute.shape<"(2,5)">
  %b_stride = cute.make_stride () : () -> !cute.stride<"(1,2)">
  %b = cute.make_layout (%b_shape, %b_stride) : (!cute.shape<"(2,5)">, !cute.stride<"(1,2)">) -> !cute.layout<"(2,5):(1,2)">
  %r = cute.tiled_product(%a, %b)
         : (!cute.composed_layout<"S<3,4,3> o 0 o (3,4):(4,1)">,
            !cute.layout<"(2,5):(1,2)">)
        -> !cute.composed_layout<"S<3,4,3> o 0 o ((3,4),2,5):((4,1),12,24)">
  return %r : !cute.composed_layout<"S<3,4,3> o 0 o ((3,4),2,5):((4,1),12,24)">
}

// -----

//===----------------------------------------------------------------------===//
// flat_product
//===----------------------------------------------------------------------===//

// CHECK-LABEL: func.func @fold_flat_product_layout
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.layout<"(3,4,2,5):(4,1,12,24)">
// CHECK-NEXT:    return %[[R]]
func.func @fold_flat_product_layout() -> !cute.layout<"(3,4,2,5):(4,1,12,24)"> {
  %a_shape = cute.make_shape () : () -> !cute.shape<"(3,4)">
  %a_stride = cute.make_stride () : () -> !cute.stride<"(4,1)">
  %a = cute.make_layout (%a_shape, %a_stride) : (!cute.shape<"(3,4)">, !cute.stride<"(4,1)">) -> !cute.layout<"(3,4):(4,1)">
  %b_shape = cute.make_shape () : () -> !cute.shape<"(2,5)">
  %b_stride = cute.make_stride () : () -> !cute.stride<"(1,2)">
  %b = cute.make_layout (%b_shape, %b_stride) : (!cute.shape<"(2,5)">, !cute.stride<"(1,2)">) -> !cute.layout<"(2,5):(1,2)">
  %r = cute.flat_product(%a, %b)
         : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(2,5):(1,2)">)
        -> !cute.layout<"(3,4,2,5):(4,1,12,24)">
  return %r : !cute.layout<"(3,4,2,5):(4,1,12,24)">
}

// -----

// CHECK-LABEL: func.func @fold_flat_product_composed_layout
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.composed_layout<"S<3,4,3> o 0 o (3,4,2,5):(4,1,12,24)">
// CHECK-NEXT:    return %[[R]]
func.func @fold_flat_product_composed_layout(
    %a: !cute.composed_layout<"S<3,4,3> o 0 o (3,4):(4,1)">)
    -> !cute.composed_layout<"S<3,4,3> o 0 o (3,4,2,5):(4,1,12,24)"> {
  %b_shape = cute.make_shape () : () -> !cute.shape<"(2,5)">
  %b_stride = cute.make_stride () : () -> !cute.stride<"(1,2)">
  %b = cute.make_layout (%b_shape, %b_stride) : (!cute.shape<"(2,5)">, !cute.stride<"(1,2)">) -> !cute.layout<"(2,5):(1,2)">
  %r = cute.flat_product(%a, %b)
         : (!cute.composed_layout<"S<3,4,3> o 0 o (3,4):(4,1)">,
            !cute.layout<"(2,5):(1,2)">)
        -> !cute.composed_layout<"S<3,4,3> o 0 o (3,4,2,5):(4,1,12,24)">
  return %r : !cute.composed_layout<"S<3,4,3> o 0 o (3,4,2,5):(4,1,12,24)">
}

// -----

//===----------------------------------------------------------------------===//
// raked_product
//===----------------------------------------------------------------------===//

// CHECK-LABEL: func.func @fold_raked_product_layout
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.layout<"((2,3),(5,4)):((12,4),(24,1))">
// CHECK-NEXT:    return %[[R]]
func.func @fold_raked_product_layout()
    -> !cute.layout<"((2,3),(5,4)):((12,4),(24,1))"> {
  %a_shape = cute.make_shape () : () -> !cute.shape<"(3,4)">
  %a_stride = cute.make_stride () : () -> !cute.stride<"(4,1)">
  %a = cute.make_layout (%a_shape, %a_stride) : (!cute.shape<"(3,4)">, !cute.stride<"(4,1)">) -> !cute.layout<"(3,4):(4,1)">
  %b_shape = cute.make_shape () : () -> !cute.shape<"(2,5)">
  %b_stride = cute.make_stride () : () -> !cute.stride<"(1,2)">
  %b = cute.make_layout (%b_shape, %b_stride) : (!cute.shape<"(2,5)">, !cute.stride<"(1,2)">) -> !cute.layout<"(2,5):(1,2)">
  %r = cute.raked_product(%a, %b)
         : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(2,5):(1,2)">)
        -> !cute.layout<"((2,3),(5,4)):((12,4),(24,1))">
  return %r : !cute.layout<"((2,3),(5,4)):((12,4),(24,1))">
}

// -----

// CHECK-LABEL: func.func @fold_raked_product_composed_layout
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.composed_layout<"S<3,4,3> o 0 o ((2,3),(5,4)):((12,4),(24,1))">
// CHECK-NEXT:    return %[[R]]
func.func @fold_raked_product_composed_layout(
    %a: !cute.composed_layout<"S<3,4,3> o 0 o (3,4):(4,1)">)
    -> !cute.composed_layout<"S<3,4,3> o 0 o ((2,3),(5,4)):((12,4),(24,1))"> {
  %b_shape = cute.make_shape () : () -> !cute.shape<"(2,5)">
  %b_stride = cute.make_stride () : () -> !cute.stride<"(1,2)">
  %b = cute.make_layout (%b_shape, %b_stride) : (!cute.shape<"(2,5)">, !cute.stride<"(1,2)">) -> !cute.layout<"(2,5):(1,2)">
  %r = cute.raked_product(%a, %b)
         : (!cute.composed_layout<"S<3,4,3> o 0 o (3,4):(4,1)">,
            !cute.layout<"(2,5):(1,2)">)
        -> !cute.composed_layout<"S<3,4,3> o 0 o ((2,3),(5,4)):((12,4),(24,1))">
  return %r : !cute.composed_layout<"S<3,4,3> o 0 o ((2,3),(5,4)):((12,4),(24,1))">
}

// -----

//===----------------------------------------------------------------------===//
// blocked_product
//===----------------------------------------------------------------------===//

// CHECK-LABEL: func.func @fold_blocked_product_layout
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.layout<"((3,2),(4,5)):((4,12),(1,24))">
// CHECK-NEXT:    return %[[R]]
func.func @fold_blocked_product_layout()
    -> !cute.layout<"((3,2),(4,5)):((4,12),(1,24))"> {
  %a_shape = cute.make_shape () : () -> !cute.shape<"(3,4)">
  %a_stride = cute.make_stride () : () -> !cute.stride<"(4,1)">
  %a = cute.make_layout (%a_shape, %a_stride) : (!cute.shape<"(3,4)">, !cute.stride<"(4,1)">) -> !cute.layout<"(3,4):(4,1)">
  %b_shape = cute.make_shape () : () -> !cute.shape<"(2,5)">
  %b_stride = cute.make_stride () : () -> !cute.stride<"(1,2)">
  %b = cute.make_layout (%b_shape, %b_stride) : (!cute.shape<"(2,5)">, !cute.stride<"(1,2)">) -> !cute.layout<"(2,5):(1,2)">
  %r = cute.blocked_product(%a, %b)
         : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(2,5):(1,2)">)
        -> !cute.layout<"((3,2),(4,5)):((4,12),(1,24))">
  return %r : !cute.layout<"((3,2),(4,5)):((4,12),(1,24))">
}

// -----

// CHECK-LABEL: func.func @fold_blocked_product_composed_layout
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.composed_layout<"S<3,4,3> o 0 o ((3,2),(4,5)):((4,12),(1,24))">
// CHECK-NEXT:    return %[[R]]
func.func @fold_blocked_product_composed_layout(
    %a: !cute.composed_layout<"S<3,4,3> o 0 o (3,4):(4,1)">)
    -> !cute.composed_layout<"S<3,4,3> o 0 o ((3,2),(4,5)):((4,12),(1,24))"> {
  %b_shape = cute.make_shape () : () -> !cute.shape<"(2,5)">
  %b_stride = cute.make_stride () : () -> !cute.stride<"(1,2)">
  %b = cute.make_layout (%b_shape, %b_stride) : (!cute.shape<"(2,5)">, !cute.stride<"(1,2)">) -> !cute.layout<"(2,5):(1,2)">
  %r = cute.blocked_product(%a, %b)
         : (!cute.composed_layout<"S<3,4,3> o 0 o (3,4):(4,1)">,
            !cute.layout<"(2,5):(1,2)">)
        -> !cute.composed_layout<"S<3,4,3> o 0 o ((3,2),(4,5)):((4,12),(1,24))">
  return %r : !cute.composed_layout<"S<3,4,3> o 0 o ((3,2),(4,5)):((4,12),(1,24))">
}

// -----

//===----------------------------------------------------------------------===//
// logical_divide
//===----------------------------------------------------------------------===//

// CHECK-LABEL: func.func @fold_logical_divide_layout
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.layout<"((3,2),(4,2)):((8,24),(1,4))">
// CHECK-NEXT:    return %[[R]]
func.func @fold_logical_divide_layout()
    -> !cute.layout<"((3,2),(4,2)):((8,24),(1,4))"> {
  %a_shape = cute.make_shape () : () -> !cute.shape<"(6,8)">
  %a_stride = cute.make_stride () : () -> !cute.stride<"(8,1)">
  %a = cute.make_layout (%a_shape, %a_stride) : (!cute.shape<"(6,8)">, !cute.stride<"(8,1)">) -> !cute.layout<"(6,8):(8,1)">
  %b = cute.make_shape() : () -> !cute.shape<"(3,4)">
  %r = cute.logical_divide(%a, %b)
         : (!cute.layout<"(6,8):(8,1)">, !cute.shape<"(3,4)">)
        -> !cute.layout<"((3,2),(4,2)):((8,24),(1,4))">
  return %r : !cute.layout<"((3,2),(4,2)):((8,24),(1,4))">
}

// -----

// CHECK-LABEL: func.func @fold_logical_divide_composed_layout
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.composed_layout<"S<3,4,3> o 0 o ((3,2),(4,2)):((8,24),(1,4))">
// CHECK-NEXT:    return %[[R]]
func.func @fold_logical_divide_composed_layout(
    %a: !cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">)
    -> !cute.composed_layout<"S<3,4,3> o 0 o ((3,2),(4,2)):((8,24),(1,4))"> {
  %b = cute.make_shape() : () -> !cute.shape<"(3,4)">
  %r = cute.logical_divide(%a, %b)
         : (!cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">,
            !cute.shape<"(3,4)">)
        -> !cute.composed_layout<"S<3,4,3> o 0 o ((3,2),(4,2)):((8,24),(1,4))">
  return %r : !cute.composed_layout<"S<3,4,3> o 0 o ((3,2),(4,2)):((8,24),(1,4))">
}

// -----

//===----------------------------------------------------------------------===//
// zipped_divide
//===----------------------------------------------------------------------===//

// CHECK-LABEL: func.func @fold_zipped_divide_layout
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.layout<"((3,4),(2,2)):((8,1),(24,4))">
// CHECK-NEXT:    return %[[R]]
func.func @fold_zipped_divide_layout()
    -> !cute.layout<"((3,4),(2,2)):((8,1),(24,4))"> {
  %a_shape = cute.make_shape () : () -> !cute.shape<"(6,8)">
  %a_stride = cute.make_stride () : () -> !cute.stride<"(8,1)">
  %a = cute.make_layout (%a_shape, %a_stride) : (!cute.shape<"(6,8)">, !cute.stride<"(8,1)">) -> !cute.layout<"(6,8):(8,1)">
  %b = cute.make_shape() : () -> !cute.shape<"(3,4)">
  %r = cute.zipped_divide(%a, %b)
         : (!cute.layout<"(6,8):(8,1)">, !cute.shape<"(3,4)">)
        -> !cute.layout<"((3,4),(2,2)):((8,1),(24,4))">
  return %r : !cute.layout<"((3,4),(2,2)):((8,1),(24,4))">
}

// -----

// CHECK-LABEL: func.func @fold_zipped_divide_composed_layout
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.composed_layout<"S<3,4,3> o 0 o ((3,4),(2,2)):((8,1),(24,4))">
// CHECK-NEXT:    return %[[R]]
func.func @fold_zipped_divide_composed_layout(
    %a: !cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">)
    -> !cute.composed_layout<"S<3,4,3> o 0 o ((3,4),(2,2)):((8,1),(24,4))"> {
  %b = cute.make_shape() : () -> !cute.shape<"(3,4)">
  %r = cute.zipped_divide(%a, %b)
         : (!cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">,
            !cute.shape<"(3,4)">)
        -> !cute.composed_layout<"S<3,4,3> o 0 o ((3,4),(2,2)):((8,1),(24,4))">
  return %r : !cute.composed_layout<"S<3,4,3> o 0 o ((3,4),(2,2)):((8,1),(24,4))">
}

// -----

//===----------------------------------------------------------------------===//
// tiled_divide
//===----------------------------------------------------------------------===//

// CHECK-LABEL: func.func @fold_tiled_divide_layout
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.layout<"((3,4),2,2):((8,1),24,4)">
// CHECK-NEXT:    return %[[R]]
func.func @fold_tiled_divide_layout() -> !cute.layout<"((3,4),2,2):((8,1),24,4)"> {
  %a_shape = cute.make_shape () : () -> !cute.shape<"(6,8)">
  %a_stride = cute.make_stride () : () -> !cute.stride<"(8,1)">
  %a = cute.make_layout (%a_shape, %a_stride) : (!cute.shape<"(6,8)">, !cute.stride<"(8,1)">) -> !cute.layout<"(6,8):(8,1)">
  %b = cute.make_shape() : () -> !cute.shape<"(3,4)">
  %r = cute.tiled_divide(%a, %b)
         : (!cute.layout<"(6,8):(8,1)">, !cute.shape<"(3,4)">)
        -> !cute.layout<"((3,4),2,2):((8,1),24,4)">
  return %r : !cute.layout<"((3,4),2,2):((8,1),24,4)">
}

// -----

// CHECK-LABEL: func.func @fold_tiled_divide_composed_layout
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.composed_layout<"S<3,4,3> o 0 o ((3,4),2,2):((8,1),24,4)">
// CHECK-NEXT:    return %[[R]]
func.func @fold_tiled_divide_composed_layout(
    %a: !cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">)
    -> !cute.composed_layout<"S<3,4,3> o 0 o ((3,4),2,2):((8,1),24,4)"> {
  %b = cute.make_shape() : () -> !cute.shape<"(3,4)">
  %r = cute.tiled_divide(%a, %b)
         : (!cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">,
            !cute.shape<"(3,4)">)
        -> !cute.composed_layout<"S<3,4,3> o 0 o ((3,4),2,2):((8,1),24,4)">
  return %r : !cute.composed_layout<"S<3,4,3> o 0 o ((3,4),2,2):((8,1),24,4)">
}

// -----

//===----------------------------------------------------------------------===//
// flat_divide
//===----------------------------------------------------------------------===//

// CHECK-LABEL: func.func @fold_flat_divide_layout
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.layout<"(3,4,2,2):(8,1,24,4)">
// CHECK-NEXT:    return %[[R]]
func.func @fold_flat_divide_layout() -> !cute.layout<"(3,4,2,2):(8,1,24,4)"> {
  %a_shape = cute.make_shape () : () -> !cute.shape<"(6,8)">
  %a_stride = cute.make_stride () : () -> !cute.stride<"(8,1)">
  %a = cute.make_layout (%a_shape, %a_stride) : (!cute.shape<"(6,8)">, !cute.stride<"(8,1)">) -> !cute.layout<"(6,8):(8,1)">
  %b = cute.make_shape() : () -> !cute.shape<"(3,4)">
  %r = cute.flat_divide(%a, %b)
         : (!cute.layout<"(6,8):(8,1)">, !cute.shape<"(3,4)">)
        -> !cute.layout<"(3,4,2,2):(8,1,24,4)">
  return %r : !cute.layout<"(3,4,2,2):(8,1,24,4)">
}

// -----

// CHECK-LABEL: func.func @fold_flat_divide_composed_layout
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.composed_layout<"S<3,4,3> o 0 o (3,4,2,2):(8,1,24,4)">
// CHECK-NEXT:    return %[[R]]
func.func @fold_flat_divide_composed_layout(
    %a: !cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">)
    -> !cute.composed_layout<"S<3,4,3> o 0 o (3,4,2,2):(8,1,24,4)"> {
  %b = cute.make_shape() : () -> !cute.shape<"(3,4)">
  %r = cute.flat_divide(%a, %b)
         : (!cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">,
            !cute.shape<"(3,4)">)
        -> !cute.composed_layout<"S<3,4,3> o 0 o (3,4,2,2):(8,1,24,4)">
  return %r : !cute.composed_layout<"S<3,4,3> o 0 o (3,4,2,2):(8,1,24,4)">
}

// -----

//===----------------------------------------------------------------------===//
// tile_to_shape
//===----------------------------------------------------------------------===//

// CHECK-LABEL: func.func @fold_tile_to_shape_layout
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.layout<"((3,2),(2,4)):((1,6),(3,12))">
// CHECK-NEXT:    return %[[R]]
func.func @fold_tile_to_shape_layout()
    -> !cute.layout<"((3,2),(2,4)):((1,6),(3,12))"> {
  %a_shape = cute.make_shape () : () -> !cute.shape<"(3,2)">
  %a_stride = cute.make_stride () : () -> !cute.stride<"(1,3)">
  %a = cute.make_layout (%a_shape, %a_stride) : (!cute.shape<"(3,2)">, !cute.stride<"(1,3)">) -> !cute.layout<"(3,2):(1,3)">
  %b = cute.make_shape() : () -> !cute.shape<"(6,8)">
  %r = cute.tile_to_shape(%a, %b)
         : (!cute.layout<"(3,2):(1,3)">, !cute.shape<"(6,8)">)
        -> !cute.layout<"((3,2),(2,4)):((1,6),(3,12))">
  return %r : !cute.layout<"((3,2),(2,4)):((1,6),(3,12))">
}

// -----

// CHECK-LABEL: func.func @fold_tile_to_shape_composed_layout
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.composed_layout<"S<3,4,3> o 0 o ((3,2),(2,4)):((1,6),(3,12))">
// CHECK-NEXT:    return %[[R]]
func.func @fold_tile_to_shape_composed_layout(
    %a: !cute.composed_layout<"S<3,4,3> o 0 o (3,2):(1,3)">)
    -> !cute.composed_layout<"S<3,4,3> o 0 o ((3,2),(2,4)):((1,6),(3,12))"> {
  %b = cute.make_shape() : () -> !cute.shape<"(6,8)">
  %r = cute.tile_to_shape(%a, %b)
         : (!cute.composed_layout<"S<3,4,3> o 0 o (3,2):(1,3)">,
            !cute.shape<"(6,8)">)
        -> !cute.composed_layout<"S<3,4,3> o 0 o ((3,2),(2,4)):((1,6),(3,12))">
  return %r : !cute.composed_layout<"S<3,4,3> o 0 o ((3,2),(2,4)):((1,6),(3,12))">
}
