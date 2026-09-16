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

// cute-fold-static: get and select ops with fully-static results fold to cute.static.

// -----

//===----------------------------------------------------------------------===//
// cute.get — one section per supported result type
//===----------------------------------------------------------------------===//

// CHECK-LABEL: func.func @fold_get_shape
// CHECK-SAME:  (%[[V:.+]]: !cute.shape<"(4,(2,3))">)
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.shape<"2">
// CHECK-NEXT:    return %[[R]]
func.func @fold_get_shape(%v: !cute.shape<"(4,(2,3))">) -> !cute.shape<"2"> {
  %r = cute.get<[1, 0]>(%v) : !cute.shape<"(4,(2,3))"> -> !cute.shape<"2">
  return %r : !cute.shape<"2">
}

// -----

// CHECK-LABEL: func.func @fold_get_int_tuple
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.int_tuple<"(4,5)">
// CHECK-NEXT:    return %[[R]]
func.func @fold_get_int_tuple(%v: !cute.int_tuple<"(3,(4,5))">)
    -> !cute.int_tuple<"(4,5)"> {
  %r = cute.get<[1]>(%v) : !cute.int_tuple<"(3,(4,5))"> -> !cute.int_tuple<"(4,5)">
  return %r : !cute.int_tuple<"(4,5)">
}

// -----

// CHECK-LABEL: func.func @fold_get_coord
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.coord<"3">
// CHECK-NEXT:    return %[[R]]
func.func @fold_get_coord(%v: !cute.coord<"(2,3)">) -> !cute.coord<"3"> {
  %r = cute.get<[1]>(%v) : !cute.coord<"(2,3)"> -> !cute.coord<"3">
  return %r : !cute.coord<"3">
}

// -----

// CHECK-LABEL: func.func @fold_get_stride
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.stride<"4">
// CHECK-NEXT:    return %[[R]]
func.func @fold_get_stride(%v: !cute.stride<"(1,(4,8))">) -> !cute.stride<"4"> {
  %r = cute.get<[1, 0]>(%v) : !cute.stride<"(1,(4,8))"> -> !cute.stride<"4">
  return %r : !cute.stride<"4">
}

// -----

// CHECK-LABEL: func.func @fold_get_tile
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.tile<"(4,8):(1,4)">
// CHECK-NEXT:    return %[[R]]
func.func @fold_get_tile(%v: !cute.tile<"[(4,8):(1,4);(2,3):(1,2)]">)
    -> !cute.tile<"(4,8):(1,4)"> {
  %r = cute.get<[0]>(%v)
         : !cute.tile<"[(4,8):(1,4);(2,3):(1,2)]"> -> !cute.tile<"(4,8):(1,4)">
  return %r : !cute.tile<"(4,8):(1,4)">
}

// -----

// CHECK-LABEL: func.func @fold_get_layout
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.layout<"4:1">
// CHECK-NEXT:    return %[[R]]
func.func @fold_get_layout(%v: !cute.layout<"(4,8):(1,4)">) -> !cute.layout<"4:1"> {
  %r = cute.get<[0]>(%v) : !cute.layout<"(4,8):(1,4)"> -> !cute.layout<"4:1">
  return %r : !cute.layout<"4:1">
}

// -----

// CHECK-LABEL: func.func @fold_get_composed_layout
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.composed_layout<"S<3,5,4> o 0 o 8:1">
// CHECK-NEXT:    return %[[R]]
func.func @fold_get_composed_layout(
    %v: !cute.composed_layout<"S<3,5,4> o 0 o (8,4):(1,8)">)
    -> !cute.composed_layout<"S<3,5,4> o 0 o 8:1"> {
  %r = cute.get<[0]>(%v)
         : !cute.composed_layout<"S<3,5,4> o 0 o (8,4):(1,8)">
        -> !cute.composed_layout<"S<3,5,4> o 0 o 8:1">
  return %r : !cute.composed_layout<"S<3,5,4> o 0 o 8:1">
}

// -----

//===----------------------------------------------------------------------===//
// cute.select — one section per supported result type
//===----------------------------------------------------------------------===//

// CHECK-LABEL: func.func @fold_select_shape
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.shape<"(4,2)">
// CHECK-NEXT:    return %[[R]]
func.func @fold_select_shape(%v: !cute.shape<"(4,8,2)">) -> !cute.shape<"(4,2)"> {
  %r = cute.select<[0, 2]>(%v) : !cute.shape<"(4,8,2)"> -> !cute.shape<"(4,2)">
  return %r : !cute.shape<"(4,2)">
}

// -----

// CHECK-LABEL: func.func @fold_select_int_tuple
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.int_tuple<"(1,3)">
// CHECK-NEXT:    return %[[R]]
func.func @fold_select_int_tuple(%v: !cute.int_tuple<"(1,2,3)">)
    -> !cute.int_tuple<"(1,3)"> {
  %r = cute.select<[0, 2]>(%v)
         : !cute.int_tuple<"(1,2,3)"> -> !cute.int_tuple<"(1,3)">
  return %r : !cute.int_tuple<"(1,3)">
}

// -----

// CHECK-LABEL: func.func @fold_select_coord
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.coord<"(1,3)">
// CHECK-NEXT:    return %[[R]]
func.func @fold_select_coord(%v: !cute.coord<"(1,2,3)">) -> !cute.coord<"(1,3)"> {
  %r = cute.select<[0, 2]>(%v) : !cute.coord<"(1,2,3)"> -> !cute.coord<"(1,3)">
  return %r : !cute.coord<"(1,3)">
}

// -----

// CHECK-LABEL: func.func @fold_select_stride
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.stride<"(1,8)">
// CHECK-NEXT:    return %[[R]]
func.func @fold_select_stride(%v: !cute.stride<"(1,4,8)">)
    -> !cute.stride<"(1,8)"> {
  %r = cute.select<[0, 2]>(%v) : !cute.stride<"(1,4,8)"> -> !cute.stride<"(1,8)">
  return %r : !cute.stride<"(1,8)">
}

// -----

// CHECK-LABEL: func.func @fold_select_tile
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.tile<"[(2,3):(1,2);(4,8):(1,4)]">
// CHECK-NEXT:    return %[[R]]
func.func @fold_select_tile(%v: !cute.tile<"[(4,8):(1,4);(2,3):(1,2)]">)
    -> !cute.tile<"[(2,3):(1,2);(4,8):(1,4)]"> {
  %r = cute.select<[1, 0]>(%v)
         : !cute.tile<"[(4,8):(1,4);(2,3):(1,2)]">
        -> !cute.tile<"[(2,3):(1,2);(4,8):(1,4)]">
  return %r : !cute.tile<"[(2,3):(1,2);(4,8):(1,4)]">
}

// -----

// CHECK-LABEL: func.func @fold_select_layout
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.layout<"(8,4):(8,1)">
// CHECK-NEXT:    return %[[R]]
func.func @fold_select_layout(%v: !cute.layout<"(4,2,8):(1,4,8)">)
    -> !cute.layout<"(8,4):(8,1)"> {
  %r = cute.select<[2, 0]>(%v)
         : !cute.layout<"(4,2,8):(1,4,8)"> -> !cute.layout<"(8,4):(8,1)">
  return %r : !cute.layout<"(8,4):(8,1)">
}

// -----

// CHECK-LABEL: func.func @fold_select_composed_layout
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.composed_layout<"S<3,5,4> o 0 o (8,4):(8,1)">
// CHECK-NEXT:    return %[[R]]
func.func @fold_select_composed_layout(
    %v: !cute.composed_layout<"S<3,5,4> o 0 o (4,2,8):(1,4,8)">)
    -> !cute.composed_layout<"S<3,5,4> o 0 o (8,4):(8,1)"> {
  %r = cute.select<[2, 0]>(%v)
         : !cute.composed_layout<"S<3,5,4> o 0 o (4,2,8):(1,4,8)">
        -> !cute.composed_layout<"S<3,5,4> o 0 o (8,4):(8,1)">
  return %r : !cute.composed_layout<"S<3,5,4> o 0 o (8,4):(8,1)">
}

// -----

//===----------------------------------------------------------------------===//
// Dynamic input with static-result mode — folds.
//===----------------------------------------------------------------------===//

// get picks static mode from a partially-dynamic shape.
// CHECK-LABEL: func.func @fold_get_dynamic_input_shape
// CHECK-SAME:  (%[[V:.+]]: !cute.shape<"(4,?,2)">)
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.shape<"4">
// CHECK-NEXT:    return %[[R]]
func.func @fold_get_dynamic_input_shape(%v: !cute.shape<"(4,?,2)">)
    -> !cute.shape<"4"> {
  %r = cute.get<[0]>(%v) : !cute.shape<"(4,?,2)"> -> !cute.shape<"4">
  return %r : !cute.shape<"4">
}

// -----

// get picks static mode from a partially-dynamic layout.
// CHECK-LABEL: func.func @fold_get_dynamic_input_layout
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.layout<"4:1">
// CHECK-NEXT:    return %[[R]]
func.func @fold_get_dynamic_input_layout(%v: !cute.layout<"(?,4):(?,1)">)
    -> !cute.layout<"4:1"> {
  %r = cute.get<[1]>(%v) : !cute.layout<"(?,4):(?,1)"> -> !cute.layout<"4:1">
  return %r : !cute.layout<"4:1">
}

// -----

// get picks static mode from a partially-dynamic int_tuple.
// CHECK-LABEL: func.func @fold_get_dynamic_input_int_tuple
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.int_tuple<"(4,5)">
// CHECK-NEXT:    return %[[R]]
func.func @fold_get_dynamic_input_int_tuple(%v: !cute.int_tuple<"(?,(4,5))">)
    -> !cute.int_tuple<"(4,5)"> {
  %r = cute.get<[1]>(%v) : !cute.int_tuple<"(?,(4,5))"> -> !cute.int_tuple<"(4,5)">
  return %r : !cute.int_tuple<"(4,5)">
}

// -----

// select<[0, 2]> picks the two static modes from `(4,?,2)`.
// CHECK-LABEL: func.func @fold_select_dynamic_input_shape
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.shape<"(4,2)">
// CHECK-NEXT:    return %[[R]]
func.func @fold_select_dynamic_input_shape(%v: !cute.shape<"(4,?,2)">)
    -> !cute.shape<"(4,2)"> {
  %r = cute.select<[0, 2]>(%v) : !cute.shape<"(4,?,2)"> -> !cute.shape<"(4,2)">
  return %r : !cute.shape<"(4,2)">
}

// -----

// select<[2, 0]> on a layout whose mode 1 is dynamic.
// CHECK-LABEL: func.func @fold_select_dynamic_input_layout
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.layout<"(2,4):(8,1)">
// CHECK-NEXT:    return %[[R]]
func.func @fold_select_dynamic_input_layout(%v: !cute.layout<"(4,?,2):(1,?,8)">)
    -> !cute.layout<"(2,4):(8,1)"> {
  %r = cute.select<[2, 0]>(%v)
         : !cute.layout<"(4,?,2):(1,?,8)"> -> !cute.layout<"(2,4):(8,1)">
  return %r : !cute.layout<"(2,4):(8,1)">
}

// -----

// select<[0, 2]> on a coord whose mode 1 is dynamic.
// CHECK-LABEL: func.func @fold_select_dynamic_input_coord
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.coord<"(1,3)">
// CHECK-NEXT:    return %[[R]]
func.func @fold_select_dynamic_input_coord(%v: !cute.coord<"(1,?,3)">)
    -> !cute.coord<"(1,3)"> {
  %r = cute.select<[0, 2]>(%v) : !cute.coord<"(1,?,3)"> -> !cute.coord<"(1,3)">
  return %r : !cute.coord<"(1,3)">
}
