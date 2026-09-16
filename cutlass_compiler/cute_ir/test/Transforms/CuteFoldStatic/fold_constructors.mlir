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

// cute-fold-static: constructor ops with fully-static result types fold to cute.static.

// -----

// CHECK-LABEL: func.func @fold_make_int_tuple
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.int_tuple<"(2,4)">
// CHECK-NEXT:    return %[[R]] : !cute.int_tuple<"(2,4)">
func.func @fold_make_int_tuple() -> !cute.int_tuple<"(2,4)"> {
  %t = cute.make_int_tuple() : () -> !cute.int_tuple<"(2,4)">
  return %t : !cute.int_tuple<"(2,4)">
}

// -----

// CHECK-LABEL: func.func @fold_make_shape
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.shape<"(2,4)">
// CHECK-NEXT:    return %[[R]] : !cute.shape<"(2,4)">
func.func @fold_make_shape() -> !cute.shape<"(2,4)"> {
  %s = cute.make_shape() : () -> !cute.shape<"(2,4)">
  return %s : !cute.shape<"(2,4)">
}

// -----

// CHECK-LABEL: func.func @fold_make_stride
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.stride<"(1,4)">
// CHECK-NEXT:    return %[[R]] : !cute.stride<"(1,4)">
func.func @fold_make_stride() -> !cute.stride<"(1,4)"> {
  %d = cute.make_stride() : () -> !cute.stride<"(1,4)">
  return %d : !cute.stride<"(1,4)">
}

// -----

// CHECK-LABEL: func.func @fold_make_coord
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.coord<"(1,2)">
// CHECK-NEXT:    return %[[R]] : !cute.coord<"(1,2)">
func.func @fold_make_coord() -> !cute.coord<"(1,2)"> {
  %c = cute.make_coord() : () -> !cute.coord<"(1,2)">
  return %c : !cute.coord<"(1,2)">
}

// -----

// CHECK-LABEL: func.func @fold_make_layout
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.layout<"(2,4):(1,2)">
// CHECK-NEXT:    return %[[R]] : !cute.layout<"(2,4):(1,2)">
func.func @fold_make_layout() -> !cute.layout<"(2,4):(1,2)"> {
  %s = cute.make_shape () : () -> !cute.shape<"(2,4)">
  %d = cute.make_stride () : () -> !cute.stride<"(1,2)">
  %l = cute.make_layout(%s, %d)
        : (!cute.shape<"(2,4)">, !cute.stride<"(1,2)">) -> !cute.layout<"(2,4):(1,2)">
  return %l : !cute.layout<"(2,4):(1,2)">
}

// -----

// CHECK-LABEL: func.func @fold_make_tile
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.tile<"[(2,3):(1,2)]">
// CHECK-NEXT:    return %[[R]] : !cute.tile<"[(2,3):(1,2)]">
func.func @fold_make_tile() -> !cute.tile<"[(2,3):(1,2)]"> {
  %t = cute.make_tile() : () -> !cute.tile<"[(2,3):(1,2)]">
  return %t : !cute.tile<"[(2,3):(1,2)]">
}

// -----

// make_composed_layout — layout A.
// CHECK-LABEL: func.func @fold_make_composed_layout_layout_a
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">
// CHECK-NEXT:    return %[[R]] : !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">
func.func @fold_make_composed_layout_layout_a()
    -> !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)"> {
  %as = cute.make_shape () : () -> !cute.shape<"(4,5)">
  %ad = cute.make_stride () : () -> !cute.stride<"(1,4)">
  %a = cute.make_layout(%as, %ad)
        : (!cute.shape<"(4,5)">, !cute.stride<"(1,4)">) -> !cute.layout<"(4,5):(1,4)">
  %off = cute.make_int_tuple() : () -> !cute.int_tuple<"2">
  %bs = cute.make_shape () : () -> !cute.shape<"(2,3)">
  %bd = cute.make_stride () : () -> !cute.stride<"(1,2)">
  %b = cute.make_layout(%bs, %bd)
        : (!cute.shape<"(2,3)">, !cute.stride<"(1,2)">) -> !cute.layout<"(2,3):(1,2)">
  %cl = cute.make_composed_layout(%a, %off, %b)
          : (!cute.layout<"(4,5):(1,4)">, !cute.int_tuple<"2">,
             !cute.layout<"(2,3):(1,2)">)
         -> !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">
  return %cl : !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">
}

// -----

// make_composed_layout — swizzle A.
// CHECK-LABEL: func.func @fold_make_composed_layout_swizzle_a
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.composed_layout<"S<3,5,4> o 0 o (8,4):(1,8)">
// CHECK-NEXT:    return %[[R]] : !cute.composed_layout<"S<3,5,4> o 0 o (8,4):(1,8)">
func.func @fold_make_composed_layout_swizzle_a(%sw: !cute.swizzle<"S<3,5,4>">)
    -> !cute.composed_layout<"S<3,5,4> o 0 o (8,4):(1,8)"> {
  %off = cute.make_int_tuple() : () -> !cute.int_tuple<"0">
  %bs = cute.make_shape () : () -> !cute.shape<"(8,4)">
  %bd = cute.make_stride () : () -> !cute.stride<"(1,8)">
  %b = cute.make_layout(%bs, %bd)
        : (!cute.shape<"(8,4)">, !cute.stride<"(1,8)">) -> !cute.layout<"(8,4):(1,8)">
  %cl = cute.make_composed_layout(%sw, %off, %b)
          : (!cute.swizzle<"S<3,5,4>">, !cute.int_tuple<"0">,
             !cute.layout<"(8,4):(1,8)">)
         -> !cute.composed_layout<"S<3,5,4> o 0 o (8,4):(1,8)">
  return %cl : !cute.composed_layout<"S<3,5,4> o 0 o (8,4):(1,8)">
}

// -----

// CHECK-LABEL: func.func @fold_make_layout_like
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"(4,2):(4,1)">)
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.layout<"(4,2):(2,1)">
// CHECK-NEXT:    return %[[R]] : !cute.layout<"(4,2):(2,1)">
func.func @fold_make_layout_like(%src: !cute.layout<"(4,2):(4,1)">)
    -> !cute.layout<"(4,2):(2,1)"> {
  %l = cute.make_layout_like(%src)
         : !cute.layout<"(4,2):(4,1)"> -> !cute.layout<"(4,2):(2,1)">
  return %l : !cute.layout<"(4,2):(2,1)">
}

// -----

// CHECK-LABEL: func.func @fold_make_ordered_layout
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.layout<"(4,2):(1,4)">
// CHECK-NEXT:    return %[[R]] : !cute.layout<"(4,2):(1,4)">
func.func @fold_make_ordered_layout() -> !cute.layout<"(4,2):(1,4)"> {
  %s = cute.make_shape() : () -> !cute.shape<"(4,2)">
  %o = cute.make_int_tuple() : () -> !cute.int_tuple<"(0,1)">
  %l = cute.make_ordered_layout(%s, %o)
         : (!cute.shape<"(4,2)">, !cute.int_tuple<"(0,1)">)
        -> !cute.layout<"(4,2):(1,4)">
  return %l : !cute.layout<"(4,2):(1,4)">
}

// -----

// CHECK-LABEL: func.func @fold_make_identity_layout
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.layout<"(4,2):(1@0,1@1)">
// CHECK-NEXT:    return %[[R]] : !cute.layout<"(4,2):(1@0,1@1)">
func.func @fold_make_identity_layout() -> !cute.layout<"(4,2):(1@0,1@1)"> {
  %s = cute.make_shape() : () -> !cute.shape<"(4,2)">
  %l = cute.make_identity_layout(%s)
         : !cute.shape<"(4,2)"> -> !cute.layout<"(4,2):(1@0,1@1)">
  return %l : !cute.layout<"(4,2):(1@0,1@1)">
}
