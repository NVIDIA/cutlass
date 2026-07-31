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

// RUN: cute-opt -cute-fold-static -cute-expand-ops -cute-to-base \
// RUN:   --split-input-file %s \
// RUN:   | cute-opt -reconcile-unrealized-casts --split-input-file \
// RUN:   | FileCheck %s

// 200-op stress test: 50 arith/math ops feeding dynamic operands of
// 150 cute ops (constructors + layout-algebra from every category)
// in a single function. Verifies the full pipeline scales without
// leaving any cute op behind, and that arith/math values flow through
// the type converter and into expand-ops decompositions correctly.
//
// 50 blocks of (1 arith/math + 3 cute) cycle through 10 templates:
//   T0  Arithmetic    make_int_tuple + tuple_add(self)   + print
//   T1  Arithmetic    make_int_tuple + tuple_add(self)   + print
//   T2  Arithmetic    make_int_tuple + tuple_sub(self)   + print
//   T3  SizeIndex     make_int_tuple + tuple_product     + print
//   T4  SizeIndex     make_shape     + tuple_product_each+ print
//   T5  LayoutAlgebra make_layout    + coalesce
//   T6  Accessors     make_layout    + get_shape
//   T7  SizeIndex     make_layout    + size
//   T8  Arithmetic    make_shape     + tuple_add(self)   + print
//   T9  Arithmetic    make_int_tuple + tuple_add(self)

// CHECK-LABEL: func.func @stress_200
// CHECK-NOT:     cute.
// CHECK:         return

func.func @stress_200(%a: i32, %b: i32, %c: i32, %d: i32) {
  %x_0 = math.absi %a : i32
  %t_0 = cute.make_int_tuple (%x_0) : (i32) -> !cute.int_tuple<"(?,4)">
  %r_0 = cute.tuple_add(%t_0, %t_0) : (!cute.int_tuple<"(?,4)">, !cute.int_tuple<"(?,4)">) -> !cute.int_tuple<"(?,8)">
  cute.print(%r_0) : !cute.int_tuple<"(?,8)">
  %x_1 = arith.subi %c, %d : i32
  %t_1 = cute.make_int_tuple (%x_1) : (i32) -> !cute.int_tuple<"(?,4)">
  %r_1 = cute.tuple_add(%t_1, %t_1) : (!cute.int_tuple<"(?,4)">, !cute.int_tuple<"(?,4)">) -> !cute.int_tuple<"(?,8)">
  cute.print(%r_1) : !cute.int_tuple<"(?,8)">
  %x_2 = arith.muli %x_1, %x_0 : i32
  %t_2 = cute.make_int_tuple (%x_2) : (i32) -> !cute.int_tuple<"(?,4)">
  %r_2 = cute.tuple_sub(%t_2, %t_2) : (!cute.int_tuple<"(?,4)">, !cute.int_tuple<"(?,4)">) -> !cute.int_tuple<"(?,0)">
  cute.print(%r_2) : !cute.int_tuple<"(?,0)">
  %x_3 = arith.divsi %x_2, %x_1 : i32
  %t_3 = cute.make_int_tuple (%x_3) : (i32) -> !cute.int_tuple<"(?,4)">
  %r_3 = cute.tuple_product(%t_3) : (!cute.int_tuple<"(?,4)">) -> !cute.int_tuple<"?">
  cute.print(%r_3) : !cute.int_tuple<"?">
  %x_4 = arith.shli %x_3, %x_2 : i32
  %t_4 = cute.make_shape (%x_4) : (i32) -> !cute.shape<"(?,(3,4))">
  %r_4 = cute.tuple_product_each(%t_4) : (!cute.shape<"(?,(3,4))">) -> !cute.shape<"(?,12)">
  cute.print(%r_4) : !cute.shape<"(?,12)">
  %x_5 = math.cttz %x_4 : i32
  %s_5 = cute.make_shape (%x_5) : (i32) -> !cute.shape<"(1,?)">
  %l_5_stride = cute.make_stride () : () -> !cute.stride<"(0,1)">
  %l_5 = cute.make_layout (%s_5, %l_5_stride) : (!cute.shape<"(1,?)">, !cute.stride<"(0,1)">) -> !cute.layout<"(1,?):(0,1)">
  %r_5 = cute.coalesce(%l_5) : (!cute.layout<"(1,?):(0,1)">) -> !cute.layout<"?:1">
  %x_6 = arith.maxsi %x_5, %x_4 : i32
  %s_6 = cute.make_shape (%x_6) : (i32) -> !cute.shape<"(?,4)">
  %xs_7 = arith.constant 5: i32
  %l_6_stride = cute.make_stride (%xs_7) : (i32) -> !cute.stride<"(1,?)">
  %l_6 = cute.make_layout (%s_6, %l_6_stride) : (!cute.shape<"(?,4)">, !cute.stride<"(1,?)">) -> !cute.layout<"(?,4):(1,?)">
  %r_6 = cute.get_shape(%l_6) : !cute.layout<"(?,4):(1,?)"> -> !cute.shape<"(?,4)">
  %x_7 = arith.minsi %x_6, %x_5 : i32
  %s_7 = cute.make_shape (%x_7) : (i32) -> !cute.shape<"(?,4)">
  %l_7_stride = cute.make_stride (%xs_7) : (i32) -> !cute.stride<"(1,?)">
  %l_7 = cute.make_layout (%s_7, %l_7_stride) : (!cute.shape<"(?,4)">, !cute.stride<"(1,?)">) -> !cute.layout<"(?,4):(1,?)">
  %r_7 = cute.size(%l_7) : (!cute.layout<"(?,4):(1,?)">) -> !cute.int_tuple<"?">
  %x_8 = arith.andi %x_7, %x_6 : i32
  %s_8 = cute.make_shape (%x_8) : (i32) -> !cute.shape<"(?,4)">
  %r_8 = cute.tuple_add(%s_8, %s_8) : (!cute.shape<"(?,4)">, !cute.shape<"(?,4)">) -> !cute.shape<"(?,8)">
  cute.print(%r_8) : !cute.shape<"(?,8)">
  %x_9 = arith.ori %x_8, %x_7 : i32
  %t_9 = cute.make_int_tuple (%x_9) : (i32) -> !cute.int_tuple<"?">
  %r_9 = cute.tuple_add(%t_9, %t_9) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.int_tuple<"?">
  %x_10 = math.ctlz %x_9 : i32
  %t_10 = cute.make_int_tuple (%x_10) : (i32) -> !cute.int_tuple<"(?,4)">
  %r_10 = cute.tuple_add(%t_10, %t_10) : (!cute.int_tuple<"(?,4)">, !cute.int_tuple<"(?,4)">) -> !cute.int_tuple<"(?,8)">
  cute.print(%r_10) : !cute.int_tuple<"(?,8)">
  %x_11 = arith.subi %x_10, %x_9 : i32
  %t_11 = cute.make_int_tuple (%x_11) : (i32) -> !cute.int_tuple<"(?,4)">
  %r_11 = cute.tuple_add(%t_11, %t_11) : (!cute.int_tuple<"(?,4)">, !cute.int_tuple<"(?,4)">) -> !cute.int_tuple<"(?,8)">
  cute.print(%r_11) : !cute.int_tuple<"(?,8)">
  %x_12 = arith.muli %x_11, %x_10 : i32
  %t_12 = cute.make_int_tuple (%x_12) : (i32) -> !cute.int_tuple<"(?,4)">
  %r_12 = cute.tuple_sub(%t_12, %t_12) : (!cute.int_tuple<"(?,4)">, !cute.int_tuple<"(?,4)">) -> !cute.int_tuple<"(?,0)">
  cute.print(%r_12) : !cute.int_tuple<"(?,0)">
  %x_13 = arith.divsi %x_12, %x_11 : i32
  %t_13 = cute.make_int_tuple (%x_13) : (i32) -> !cute.int_tuple<"(?,4)">
  %r_13 = cute.tuple_product(%t_13) : (!cute.int_tuple<"(?,4)">) -> !cute.int_tuple<"?">
  cute.print(%r_13) : !cute.int_tuple<"?">
  %x_14 = arith.shli %x_13, %x_12 : i32
  %t_14 = cute.make_shape (%x_14) : (i32) -> !cute.shape<"(?,(3,4))">
  %r_14 = cute.tuple_product_each(%t_14) : (!cute.shape<"(?,(3,4))">) -> !cute.shape<"(?,12)">
  cute.print(%r_14) : !cute.shape<"(?,12)">
  %x_15 = math.ctpop %x_14 : i32
  %s_15 = cute.make_shape (%x_15) : (i32) -> !cute.shape<"(1,?)">
  %l_15_stride = cute.make_stride () : () -> !cute.stride<"(0,1)">
  %l_15 = cute.make_layout (%s_15, %l_15_stride) : (!cute.shape<"(1,?)">, !cute.stride<"(0,1)">) -> !cute.layout<"(1,?):(0,1)">
  %r_15 = cute.coalesce(%l_15) : (!cute.layout<"(1,?):(0,1)">) -> !cute.layout<"?:1">
  %x_16 = arith.maxsi %x_15, %x_14 : i32
  %s_16 = cute.make_shape (%x_16) : (i32) -> !cute.shape<"(?,4)">
  %xs_16 = arith.constant 5: i32
  %l_16_stride = cute.make_stride (%xs_16) : (i32) -> !cute.stride<"(1,?)">
  %l_16 = cute.make_layout (%s_16, %l_16_stride) : (!cute.shape<"(?,4)">, !cute.stride<"(1,?)">) -> !cute.layout<"(?,4):(1,?)">
  %r_16 = cute.get_shape(%l_16) : !cute.layout<"(?,4):(1,?)"> -> !cute.shape<"(?,4)">
  %x_17 = arith.minsi %x_16, %x_15 : i32
  %s_17 = cute.make_shape (%x_17) : (i32) -> !cute.shape<"(?,4)">
  %l_17_stride = cute.make_stride (%xs_16) : (i32) -> !cute.stride<"(1,?)">
  %l_17 = cute.make_layout (%s_17, %l_17_stride) : (!cute.shape<"(?,4)">, !cute.stride<"(1,?)">) -> !cute.layout<"(?,4):(1,?)">
  %r_17 = cute.size(%l_17) : (!cute.layout<"(?,4):(1,?)">) -> !cute.int_tuple<"?">
  %x_18 = arith.andi %x_17, %x_16 : i32
  %s_18 = cute.make_shape (%x_18) : (i32) -> !cute.shape<"(?,4)">
  %r_18 = cute.tuple_add(%s_18, %s_18) : (!cute.shape<"(?,4)">, !cute.shape<"(?,4)">) -> !cute.shape<"(?,8)">
  cute.print(%r_18) : !cute.shape<"(?,8)">
  %x_19 = arith.ori %x_18, %x_17 : i32
  %t_19 = cute.make_int_tuple (%x_19) : (i32) -> !cute.int_tuple<"?">
  %r_19 = cute.tuple_add(%t_19, %t_19) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.int_tuple<"?">
  %x_20 = math.absi %x_19 : i32
  %t_20 = cute.make_int_tuple (%x_20) : (i32) -> !cute.int_tuple<"(?,4)">
  %r_20 = cute.tuple_add(%t_20, %t_20) : (!cute.int_tuple<"(?,4)">, !cute.int_tuple<"(?,4)">) -> !cute.int_tuple<"(?,8)">
  cute.print(%r_20) : !cute.int_tuple<"(?,8)">
  %x_21 = arith.subi %x_20, %x_19 : i32
  %t_21 = cute.make_int_tuple (%x_21) : (i32) -> !cute.int_tuple<"(?,4)">
  %r_21 = cute.tuple_add(%t_21, %t_21) : (!cute.int_tuple<"(?,4)">, !cute.int_tuple<"(?,4)">) -> !cute.int_tuple<"(?,8)">
  cute.print(%r_21) : !cute.int_tuple<"(?,8)">
  %x_22 = arith.muli %x_21, %x_20 : i32
  %t_22 = cute.make_int_tuple (%x_22) : (i32) -> !cute.int_tuple<"(?,4)">
  %r_22 = cute.tuple_sub(%t_22, %t_22) : (!cute.int_tuple<"(?,4)">, !cute.int_tuple<"(?,4)">) -> !cute.int_tuple<"(?,0)">
  cute.print(%r_22) : !cute.int_tuple<"(?,0)">
  %x_23 = arith.divsi %x_22, %x_21 : i32
  %t_23 = cute.make_int_tuple (%x_23) : (i32) -> !cute.int_tuple<"(?,4)">
  %r_23 = cute.tuple_product(%t_23) : (!cute.int_tuple<"(?,4)">) -> !cute.int_tuple<"?">
  cute.print(%r_23) : !cute.int_tuple<"?">
  %x_24 = arith.shli %x_23, %x_22 : i32
  %t_24 = cute.make_shape (%x_24) : (i32) -> !cute.shape<"(?,(3,4))">
  %r_24 = cute.tuple_product_each(%t_24) : (!cute.shape<"(?,(3,4))">) -> !cute.shape<"(?,12)">
  cute.print(%r_24) : !cute.shape<"(?,12)">
  %x_25 = math.cttz %x_24 : i32
  %s_25 = cute.make_shape (%x_25) : (i32) -> !cute.shape<"(1,?)">
  %l_25_stride = cute.make_stride () : () -> !cute.stride<"(0,1)">
  %l_25 = cute.make_layout (%s_25, %l_25_stride) : (!cute.shape<"(1,?)">, !cute.stride<"(0,1)">) -> !cute.layout<"(1,?):(0,1)">
  %r_25 = cute.coalesce(%l_25) : (!cute.layout<"(1,?):(0,1)">) -> !cute.layout<"?:1">
  %x_26 = arith.maxsi %x_25, %x_24 : i32
  %s_26 = cute.make_shape (%x_26) : (i32) -> !cute.shape<"(?,4)">
  %xs_26 = arith.constant 5: i32
  %l_26_stride = cute.make_stride (%xs_26) : (i32) -> !cute.stride<"(1,?)">
  %l_26 = cute.make_layout (%s_26, %l_26_stride) : (!cute.shape<"(?,4)">, !cute.stride<"(1,?)">) -> !cute.layout<"(?,4):(1,?)">
  %r_26 = cute.get_shape(%l_26) : !cute.layout<"(?,4):(1,?)"> -> !cute.shape<"(?,4)">
  %x_27 = arith.minsi %x_26, %x_25 : i32
  %s_27 = cute.make_shape (%x_27) : (i32) -> !cute.shape<"(?,4)">
  %l_27_stride = cute.make_stride (%xs_26) : (i32) -> !cute.stride<"(1,?)">
  %l_27 = cute.make_layout (%s_27, %l_27_stride) : (!cute.shape<"(?,4)">, !cute.stride<"(1,?)">) -> !cute.layout<"(?,4):(1,?)">
  %r_27 = cute.size(%l_27) : (!cute.layout<"(?,4):(1,?)">) -> !cute.int_tuple<"?">
  %x_28 = arith.andi %x_27, %x_26 : i32
  %s_28 = cute.make_shape (%x_28) : (i32) -> !cute.shape<"(?,4)">
  %r_28 = cute.tuple_add(%s_28, %s_28) : (!cute.shape<"(?,4)">, !cute.shape<"(?,4)">) -> !cute.shape<"(?,8)">
  cute.print(%r_28) : !cute.shape<"(?,8)">
  %x_29 = arith.ori %x_28, %x_27 : i32
  %t_29 = cute.make_int_tuple (%x_29) : (i32) -> !cute.int_tuple<"?">
  %r_29 = cute.tuple_add(%t_29, %t_29) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.int_tuple<"?">
  %x_30 = math.ctlz %x_29 : i32
  %t_30 = cute.make_int_tuple (%x_30) : (i32) -> !cute.int_tuple<"(?,4)">
  %r_30 = cute.tuple_add(%t_30, %t_30) : (!cute.int_tuple<"(?,4)">, !cute.int_tuple<"(?,4)">) -> !cute.int_tuple<"(?,8)">
  cute.print(%r_30) : !cute.int_tuple<"(?,8)">
  %x_31 = arith.subi %x_30, %x_29 : i32
  %t_31 = cute.make_int_tuple (%x_31) : (i32) -> !cute.int_tuple<"(?,4)">
  %r_31 = cute.tuple_add(%t_31, %t_31) : (!cute.int_tuple<"(?,4)">, !cute.int_tuple<"(?,4)">) -> !cute.int_tuple<"(?,8)">
  cute.print(%r_31) : !cute.int_tuple<"(?,8)">
  %x_32 = arith.muli %x_31, %x_30 : i32
  %t_32 = cute.make_int_tuple (%x_32) : (i32) -> !cute.int_tuple<"(?,4)">
  %r_32 = cute.tuple_sub(%t_32, %t_32) : (!cute.int_tuple<"(?,4)">, !cute.int_tuple<"(?,4)">) -> !cute.int_tuple<"(?,0)">
  cute.print(%r_32) : !cute.int_tuple<"(?,0)">
  %x_33 = arith.divsi %x_32, %x_31 : i32
  %t_33 = cute.make_int_tuple (%x_33) : (i32) -> !cute.int_tuple<"(?,4)">
  %r_33 = cute.tuple_product(%t_33) : (!cute.int_tuple<"(?,4)">) -> !cute.int_tuple<"?">
  cute.print(%r_33) : !cute.int_tuple<"?">
  %x_34 = arith.shli %x_33, %x_32 : i32
  %t_34 = cute.make_shape (%x_34) : (i32) -> !cute.shape<"(?,(3,4))">
  %r_34 = cute.tuple_product_each(%t_34) : (!cute.shape<"(?,(3,4))">) -> !cute.shape<"(?,12)">
  cute.print(%r_34) : !cute.shape<"(?,12)">
  %x_35 = math.ctpop %x_34 : i32
  %s_35 = cute.make_shape (%x_35) : (i32) -> !cute.shape<"(1,?)">
  %l_35_stride = cute.make_stride () : () -> !cute.stride<"(0,1)">
  %l_35 = cute.make_layout (%s_35, %l_35_stride) : (!cute.shape<"(1,?)">, !cute.stride<"(0,1)">) -> !cute.layout<"(1,?):(0,1)">
  %r_35 = cute.coalesce(%l_35) : (!cute.layout<"(1,?):(0,1)">) -> !cute.layout<"?:1">
  %x_36 = arith.maxsi %x_35, %x_34 : i32
  %s_36 = cute.make_shape (%x_36) : (i32) -> !cute.shape<"(?,4)">
  %xs_36 = arith.constant 5: i32
  %l_36_stride = cute.make_stride (%xs_36) : (i32) -> !cute.stride<"(1,?)">
  %l_36 = cute.make_layout (%s_36, %l_36_stride) : (!cute.shape<"(?,4)">, !cute.stride<"(1,?)">) -> !cute.layout<"(?,4):(1,?)">
  %r_36 = cute.get_shape(%l_36) : !cute.layout<"(?,4):(1,?)"> -> !cute.shape<"(?,4)">
  %x_37 = arith.minsi %x_36, %x_35 : i32
  %s_37 = cute.make_shape (%x_37) : (i32) -> !cute.shape<"(?,4)">
  %l_37_stride = cute.make_stride (%xs_36) : (i32) -> !cute.stride<"(1,?)">
  %l_37 = cute.make_layout (%s_37, %l_37_stride) : (!cute.shape<"(?,4)">, !cute.stride<"(1,?)">) -> !cute.layout<"(?,4):(1,?)">
  %r_37 = cute.size(%l_37) : (!cute.layout<"(?,4):(1,?)">) -> !cute.int_tuple<"?">
  %x_38 = arith.andi %x_37, %x_36 : i32
  %s_38 = cute.make_shape (%x_38) : (i32) -> !cute.shape<"(?,4)">
  %r_38 = cute.tuple_add(%s_38, %s_38) : (!cute.shape<"(?,4)">, !cute.shape<"(?,4)">) -> !cute.shape<"(?,8)">
  cute.print(%r_38) : !cute.shape<"(?,8)">
  %x_39 = arith.ori %x_38, %x_37 : i32
  %t_39 = cute.make_int_tuple (%x_39) : (i32) -> !cute.int_tuple<"?">
  %r_39 = cute.tuple_add(%t_39, %t_39) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.int_tuple<"?">
  %x_40 = math.absi %x_39 : i32
  %t_40 = cute.make_int_tuple (%x_40) : (i32) -> !cute.int_tuple<"(?,4)">
  %r_40 = cute.tuple_add(%t_40, %t_40) : (!cute.int_tuple<"(?,4)">, !cute.int_tuple<"(?,4)">) -> !cute.int_tuple<"(?,8)">
  cute.print(%r_40) : !cute.int_tuple<"(?,8)">
  %x_41 = arith.subi %x_40, %x_39 : i32
  %t_41 = cute.make_int_tuple (%x_41) : (i32) -> !cute.int_tuple<"(?,4)">
  %r_41 = cute.tuple_add(%t_41, %t_41) : (!cute.int_tuple<"(?,4)">, !cute.int_tuple<"(?,4)">) -> !cute.int_tuple<"(?,8)">
  cute.print(%r_41) : !cute.int_tuple<"(?,8)">
  %x_42 = arith.muli %x_41, %x_40 : i32
  %t_42 = cute.make_int_tuple (%x_42) : (i32) -> !cute.int_tuple<"(?,4)">
  %r_42 = cute.tuple_sub(%t_42, %t_42) : (!cute.int_tuple<"(?,4)">, !cute.int_tuple<"(?,4)">) -> !cute.int_tuple<"(?,0)">
  cute.print(%r_42) : !cute.int_tuple<"(?,0)">
  %x_43 = arith.divsi %x_42, %x_41 : i32
  %t_43 = cute.make_int_tuple (%x_43) : (i32) -> !cute.int_tuple<"(?,4)">
  %r_43 = cute.tuple_product(%t_43) : (!cute.int_tuple<"(?,4)">) -> !cute.int_tuple<"?">
  cute.print(%r_43) : !cute.int_tuple<"?">
  %x_44 = arith.shli %x_43, %x_42 : i32
  %t_44 = cute.make_shape (%x_44) : (i32) -> !cute.shape<"(?,(3,4))">
  %r_44 = cute.tuple_product_each(%t_44) : (!cute.shape<"(?,(3,4))">) -> !cute.shape<"(?,12)">
  cute.print(%r_44) : !cute.shape<"(?,12)">
  %x_45 = math.cttz %x_44 : i32
  %s_45 = cute.make_shape (%x_45) : (i32) -> !cute.shape<"(1,?)">
  %l_45_stride = cute.make_stride () : () -> !cute.stride<"(0,1)">
  %l_45 = cute.make_layout (%s_45, %l_45_stride) : (!cute.shape<"(1,?)">, !cute.stride<"(0,1)">) -> !cute.layout<"(1,?):(0,1)">
  %r_45 = cute.coalesce(%l_45) : (!cute.layout<"(1,?):(0,1)">) -> !cute.layout<"?:1">
  %x_46 = arith.maxsi %x_45, %x_44 : i32
  %s_46 = cute.make_shape (%x_46) : (i32) -> !cute.shape<"(?,4)">
  %xs_46 = arith.constant 5: i32
  %l_46_stride = cute.make_stride (%xs_46) : (i32) -> !cute.stride<"(1,?)">
  %l_46 = cute.make_layout (%s_46, %l_46_stride) : (!cute.shape<"(?,4)">, !cute.stride<"(1,?)">) -> !cute.layout<"(?,4):(1,?)">
  %r_46 = cute.get_shape(%l_46) : !cute.layout<"(?,4):(1,?)"> -> !cute.shape<"(?,4)">
  %x_47 = arith.minsi %x_46, %x_45 : i32
  %s_47 = cute.make_shape (%x_47) : (i32) -> !cute.shape<"(?,4)">
  %l_47_stride = cute.make_stride (%xs_46) : (i32) -> !cute.stride<"(1,?)">
  %l_47 = cute.make_layout (%s_47, %l_47_stride) : (!cute.shape<"(?,4)">, !cute.stride<"(1,?)">) -> !cute.layout<"(?,4):(1,?)">
  %r_47 = cute.size(%l_47) : (!cute.layout<"(?,4):(1,?)">) -> !cute.int_tuple<"?">
  %x_48 = arith.andi %x_47, %x_46 : i32
  %s_48 = cute.make_shape (%x_48) : (i32) -> !cute.shape<"(?,4)">
  %r_48 = cute.tuple_add(%s_48, %s_48) : (!cute.shape<"(?,4)">, !cute.shape<"(?,4)">) -> !cute.shape<"(?,8)">
  cute.print(%r_48) : !cute.shape<"(?,8)">
  %x_49 = arith.ori %x_48, %x_47 : i32
  %t_49 = cute.make_int_tuple (%x_49) : (i32) -> !cute.int_tuple<"?">
  %r_49 = cute.tuple_add(%t_49, %t_49) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.int_tuple<"?">
  return
}
