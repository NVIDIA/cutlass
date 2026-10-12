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

// cute-fold-static: size/index ops with fully-static results fold to cute.static.

// -----

//===----------------------------------------------------------------------===//
// size / cosize
//===----------------------------------------------------------------------===//

// CHECK-LABEL: func.func @fold_size
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.int_tuple<"12">
// CHECK-NEXT:    return %[[R]]
func.func @fold_size() -> !cute.int_tuple<"12"> {
  %s = cute.make_shape() : () -> !cute.shape<"(4,3)">
  %r = cute.size(%s) : (!cute.shape<"(4,3)">) -> !cute.int_tuple<"12">
  return %r : !cute.int_tuple<"12">
}

// -----

// CHECK-LABEL: func.func @fold_cosize
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.int_tuple<"24">
// CHECK-NEXT:    return %[[R]]
func.func @fold_cosize() -> !cute.int_tuple<"24"> {
  %l_shape = cute.make_shape () : () -> !cute.shape<"(4,3,2)">
  %l_stride = cute.make_stride () : () -> !cute.stride<"(1,4,12)">
  %l = cute.make_layout (%l_shape, %l_stride) : (!cute.shape<"(4,3,2)">, !cute.stride<"(1,4,12)">) -> !cute.layout<"(4,3,2):(1,4,12)">
  %r = cute.cosize(%l) : (!cute.layout<"(4,3,2):(1,4,12)">) -> !cute.int_tuple<"24">
  return %r : !cute.int_tuple<"24">
}

// -----

//===----------------------------------------------------------------------===//
// tuple_product / tuple_product_each
//===----------------------------------------------------------------------===//

// CHECK-LABEL: func.func @fold_tuple_product
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.int_tuple<"40">
// CHECK-NEXT:    return %[[R]]
func.func @fold_tuple_product() -> !cute.int_tuple<"40"> {
  %t = cute.make_int_tuple() : () -> !cute.int_tuple<"(2,(5,4))">
  %r = cute.tuple_product(%t)
         : (!cute.int_tuple<"(2,(5,4))">) -> !cute.int_tuple<"40">
  return %r : !cute.int_tuple<"40">
}

// -----

// CHECK-LABEL: func.func @fold_tuple_product_each
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.int_tuple<"(2,12)">
// CHECK-NEXT:    return %[[R]]
func.func @fold_tuple_product_each() -> !cute.int_tuple<"(2,12)"> {
  %t = cute.make_int_tuple() : () -> !cute.int_tuple<"(2,(3,4))">
  %r = cute.tuple_product_each(%t)
         : (!cute.int_tuple<"(2,(3,4))">) -> !cute.int_tuple<"(2,12)">
  return %r : !cute.int_tuple<"(2,12)">
}

// -----

//===----------------------------------------------------------------------===//
// layout_eval / idx2crd
//===----------------------------------------------------------------------===//

// CHECK-LABEL: func.func @fold_layout_eval
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.int_tuple<"9">
// CHECK-NEXT:    return %[[R]]
func.func @fold_layout_eval() -> !cute.int_tuple<"9"> {
  %crd = cute.make_coord() : () -> !cute.coord<"(1,2)">
  %l_shape = cute.make_shape () : () -> !cute.shape<"(4,8)">
  %l_stride = cute.make_stride () : () -> !cute.stride<"(1,4)">
  %l = cute.make_layout (%l_shape, %l_stride) : (!cute.shape<"(4,8)">, !cute.stride<"(1,4)">) -> !cute.layout<"(4,8):(1,4)">
  %r = cute.layout_eval(%crd, %l)
         : (!cute.coord<"(1,2)">, !cute.layout<"(4,8):(1,4)">)
        -> !cute.int_tuple<"9">
  return %r : !cute.int_tuple<"9">
}

// -----

// CHECK-LABEL: func.func @fold_idx2crd
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.coord<"(1,2)">
// CHECK-NEXT:    return %[[R]]
func.func @fold_idx2crd() -> !cute.coord<"(1,2)"> {
  %idx = cute.make_int_tuple() : () -> !cute.int_tuple<"9">
  %s = cute.make_shape() : () -> !cute.shape<"(4,8)">
  %r = cute.idx2crd(%idx, %s)
         : (!cute.int_tuple<"9">, !cute.shape<"(4,8)">) -> !cute.coord<"(1,2)">
  return %r : !cute.coord<"(1,2)">
}

// -----

//===----------------------------------------------------------------------===//
// increment_coord
//===----------------------------------------------------------------------===//

// CHECK-LABEL: func.func @fold_increment_coord
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.coord<"(2,2)">
// CHECK-NEXT:    return %[[R]]
func.func @fold_increment_coord() -> !cute.coord<"(2,2)"> {
  %c = cute.make_coord() : () -> !cute.coord<"(1,2)">
  %s = cute.make_shape() : () -> !cute.shape<"(4,8)">
  %r = cute.increment_coord(%c, %s)
         : (!cute.coord<"(1,2)">, !cute.shape<"(4,8)">) -> !cute.coord<"(2,2)">
  return %r : !cute.coord<"(2,2)">
}

// -----

//===----------------------------------------------------------------------===//
// append_to_rank — every TupleOrLayout variant
//===----------------------------------------------------------------------===//

// CHECK-LABEL: func.func @fold_append_to_rank_int_tuple
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.int_tuple<"(5,1,1)">
// CHECK-NEXT:    return %[[R]]
func.func @fold_append_to_rank_int_tuple() -> !cute.int_tuple<"(5,1,1)"> {
  %in = cute.make_int_tuple() : () -> !cute.int_tuple<"5">
  %e = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
  %r = cute.append_to_rank<3>(%in, %e)
         : !cute.int_tuple<"5">, !cute.int_tuple<"1">
  return %r : !cute.int_tuple<"(5,1,1)">
}

// -----

// CHECK-LABEL: func.func @fold_append_to_rank_coord
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.coord<"(2,3,0,0)">
// CHECK-NEXT:    return %[[R]]
func.func @fold_append_to_rank_coord() -> !cute.coord<"(2,3,0,0)"> {
  %in = cute.make_coord() : () -> !cute.coord<"(2,3)">
  %e = cute.make_coord() : () -> !cute.coord<"0">
  %r = cute.append_to_rank<4>(%in, %e) : !cute.coord<"(2,3)">, !cute.coord<"0">
  return %r : !cute.coord<"(2,3,0,0)">
}

// -----

// CHECK-LABEL: func.func @fold_append_to_rank_stride
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.stride<"(4,2,0,0)">
// CHECK-NEXT:    return %[[R]]
func.func @fold_append_to_rank_stride() -> !cute.stride<"(4,2,0,0)"> {
  %in = cute.make_stride() : () -> !cute.stride<"(4,2)">
  %e = cute.make_stride() : () -> !cute.stride<"0">
  %r = cute.append_to_rank<4>(%in, %e) : !cute.stride<"(4,2)">, !cute.stride<"0">
  return %r : !cute.stride<"(4,2,0,0)">
}

// -----

// CHECK-LABEL: func.func @fold_append_to_rank_shape
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.shape<"(4,8,1,1)">
// CHECK-NEXT:    return %[[R]]
func.func @fold_append_to_rank_shape() -> !cute.shape<"(4,8,1,1)"> {
  %in = cute.make_shape() : () -> !cute.shape<"(4,8)">
  %e = cute.make_shape() : () -> !cute.shape<"1">
  %r = cute.append_to_rank<4>(%in, %e) : !cute.shape<"(4,8)">, !cute.shape<"1">
  return %r : !cute.shape<"(4,8,1,1)">
}

// -----

// CHECK-LABEL: func.func @fold_append_to_rank_layout
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.layout<"(4,1,1):(1,0,0)">
// CHECK-NEXT:    return %[[R]]
func.func @fold_append_to_rank_layout() -> !cute.layout<"(4,1,1):(1,0,0)"> {
  %in_shape = cute.make_shape () : () -> !cute.shape<"4">
  %in_stride = cute.make_stride () : () -> !cute.stride<"1">
  %in = cute.make_layout (%in_shape, %in_stride) : (!cute.shape<"4">, !cute.stride<"1">) -> !cute.layout<"4:1">
  %e_shape = cute.make_shape () : () -> !cute.shape<"1">
  %e_stride = cute.make_stride () : () -> !cute.stride<"0">
  %e = cute.make_layout (%e_shape, %e_stride) : (!cute.shape<"1">, !cute.stride<"0">) -> !cute.layout<"1:0">
  %r = cute.append_to_rank<3>(%in, %e) : !cute.layout<"4:1">, !cute.layout<"1:0">
  return %r : !cute.layout<"(4,1,1):(1,0,0)">
}

// -----

// CHECK-LABEL: func.func @fold_append_to_rank_composed_layout
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.composed_layout<"(4,5):(1,4) o 2 o (4,8,1):(1,4,0)">
// CHECK-NEXT:    return %[[R]]
func.func @fold_append_to_rank_composed_layout(
    %in: !cute.composed_layout<"(4,5):(1,4) o 2 o (4,8):(1,4)">,
    %e: !cute.layout<"1:0">)
    -> !cute.composed_layout<"(4,5):(1,4) o 2 o (4,8,1):(1,4,0)"> {
  %r = cute.append_to_rank<3>(%in, %e)
         : !cute.composed_layout<"(4,5):(1,4) o 2 o (4,8):(1,4)">,
           !cute.layout<"1:0">
  return %r : !cute.composed_layout<"(4,5):(1,4) o 2 o (4,8,1):(1,4,0)">
}

// -----

//===----------------------------------------------------------------------===//
// prepend_to_rank — every TupleOrLayout variant
//===----------------------------------------------------------------------===//

// CHECK-LABEL: func.func @fold_prepend_to_rank_int_tuple
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.int_tuple<"(1,1,5)">
// CHECK-NEXT:    return %[[R]]
func.func @fold_prepend_to_rank_int_tuple() -> !cute.int_tuple<"(1,1,5)"> {
  %in = cute.make_int_tuple() : () -> !cute.int_tuple<"5">
  %e = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
  %r = cute.prepend_to_rank<3>(%in, %e)
         : !cute.int_tuple<"5">, !cute.int_tuple<"1">
  return %r : !cute.int_tuple<"(1,1,5)">
}

// -----

// CHECK-LABEL: func.func @fold_prepend_to_rank_coord
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.coord<"(0,0,2,3)">
// CHECK-NEXT:    return %[[R]]
func.func @fold_prepend_to_rank_coord() -> !cute.coord<"(0,0,2,3)"> {
  %in = cute.make_coord() : () -> !cute.coord<"(2,3)">
  %e = cute.make_coord() : () -> !cute.coord<"0">
  %r = cute.prepend_to_rank<4>(%in, %e) : !cute.coord<"(2,3)">, !cute.coord<"0">
  return %r : !cute.coord<"(0,0,2,3)">
}

// -----

// CHECK-LABEL: func.func @fold_prepend_to_rank_stride
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.stride<"(0,0,4,2)">
// CHECK-NEXT:    return %[[R]]
func.func @fold_prepend_to_rank_stride() -> !cute.stride<"(0,0,4,2)"> {
  %in = cute.make_stride() : () -> !cute.stride<"(4,2)">
  %e = cute.make_stride() : () -> !cute.stride<"0">
  %r = cute.prepend_to_rank<4>(%in, %e) : !cute.stride<"(4,2)">, !cute.stride<"0">
  return %r : !cute.stride<"(0,0,4,2)">
}

// -----

// CHECK-LABEL: func.func @fold_prepend_to_rank_shape
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.shape<"(1,1,4,8)">
// CHECK-NEXT:    return %[[R]]
func.func @fold_prepend_to_rank_shape() -> !cute.shape<"(1,1,4,8)"> {
  %in = cute.make_shape() : () -> !cute.shape<"(4,8)">
  %e = cute.make_shape() : () -> !cute.shape<"1">
  %r = cute.prepend_to_rank<4>(%in, %e) : !cute.shape<"(4,8)">, !cute.shape<"1">
  return %r : !cute.shape<"(1,1,4,8)">
}

// -----

// CHECK-LABEL: func.func @fold_prepend_to_rank_layout
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.layout<"(1,1,4,8):(0,0,1,4)">
// CHECK-NEXT:    return %[[R]]
func.func @fold_prepend_to_rank_layout()
    -> !cute.layout<"(1,1,4,8):(0,0,1,4)"> {
  %in_shape = cute.make_shape () : () -> !cute.shape<"(4,8)">
  %in_stride = cute.make_stride () : () -> !cute.stride<"(1,4)">
  %in = cute.make_layout (%in_shape, %in_stride) : (!cute.shape<"(4,8)">, !cute.stride<"(1,4)">) -> !cute.layout<"(4,8):(1,4)">
  %e_shape = cute.make_shape () : () -> !cute.shape<"1">
  %e_stride = cute.make_stride () : () -> !cute.stride<"0">
  %e = cute.make_layout (%e_shape, %e_stride) : (!cute.shape<"1">, !cute.stride<"0">) -> !cute.layout<"1:0">
  %r = cute.prepend_to_rank<4>(%in, %e)
         : !cute.layout<"(4,8):(1,4)">, !cute.layout<"1:0">
  return %r : !cute.layout<"(1,1,4,8):(0,0,1,4)">
}

// -----

// CHECK-LABEL: func.func @fold_prepend_to_rank_composed_layout
// CHECK-NEXT:    %[[R:.+]] = cute.static : !cute.composed_layout<"(4,5):(1,4) o 2 o (1,4,8):(0,1,4)">
// CHECK-NEXT:    return %[[R]]
func.func @fold_prepend_to_rank_composed_layout(
    %in: !cute.composed_layout<"(4,5):(1,4) o 2 o (4,8):(1,4)">,
    %e: !cute.layout<"1:0">)
    -> !cute.composed_layout<"(4,5):(1,4) o 2 o (1,4,8):(0,1,4)"> {
  %r = cute.prepend_to_rank<3>(%in, %e)
         : !cute.composed_layout<"(4,5):(1,4) o 2 o (4,8):(1,4)">,
           !cute.layout<"1:0">
  return %r : !cute.composed_layout<"(4,5):(1,4) o 2 o (1,4,8):(0,1,4)">
}
