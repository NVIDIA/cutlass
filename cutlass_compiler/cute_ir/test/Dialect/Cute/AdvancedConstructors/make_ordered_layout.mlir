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

// Tests parse/print round-trip for cute.make_ordered_layout.

// -----

// Flat shape with col-major order.
// CHECK-LABEL: func.func @flat_col_major
// CHECK-SAME: (%[[S:.+]]: !cute.shape<"(4,2)">, %[[O:.+]]: !cute.int_tuple<"(0,1)">)
func.func @flat_col_major(%s: !cute.shape<"(4,2)">, %o: !cute.int_tuple<"(0,1)">) -> !cute.layout<"(4,2):(1,4)"> {
  // CHECK: %[[L:.+]] = cute.make_ordered_layout(%[[S]], %[[O]])
  // CHECK-SAME: (!cute.shape<"(4,2)">, !cute.int_tuple<"(0,1)">) -> !cute.layout<"(4,2):(1,4)">
  %l = cute.make_ordered_layout(%s, %o)
         : (!cute.shape<"(4,2)">, !cute.int_tuple<"(0,1)">) -> !cute.layout<"(4,2):(1,4)">
  return %l : !cute.layout<"(4,2):(1,4)">
}

// -----

// Flat shape with row-major order.
// CHECK-LABEL: func.func @flat_row_major
// CHECK-SAME: (%[[S:.+]]: !cute.shape<"(4,2)">, %[[O:.+]]: !cute.int_tuple<"(1,0)">)
func.func @flat_row_major(%s: !cute.shape<"(4,2)">, %o: !cute.int_tuple<"(1,0)">) -> !cute.layout<"(4,2):(2,1)"> {
  // CHECK: cute.make_ordered_layout(%[[S]], %[[O]])
  // CHECK-SAME: (!cute.shape<"(4,2)">, !cute.int_tuple<"(1,0)">) -> !cute.layout<"(4,2):(2,1)">
  %l = cute.make_ordered_layout(%s, %o)
         : (!cute.shape<"(4,2)">, !cute.int_tuple<"(1,0)">) -> !cute.layout<"(4,2):(2,1)">
  return %l : !cute.layout<"(4,2):(2,1)">
}

// -----

// Nested shape with nested order — hierarchical mode ordering.
// CHECK-LABEL: func.func @nested_order
// CHECK-SAME: (%[[S:.+]]: !cute.shape<"(2,(2,2),2)">, %[[O:.+]]: !cute.int_tuple<"(0,(2,3),1)">)
func.func @nested_order(%s: !cute.shape<"(2,(2,2),2)">, %o: !cute.int_tuple<"(0,(2,3),1)">) -> !cute.layout<"(2,(2,2),2):(1,(4,8),2)"> {
  // CHECK: cute.make_ordered_layout(%[[S]], %[[O]])
  // CHECK-SAME: -> !cute.layout<"(2,(2,2),2):(1,(4,8),2)">
  %l = cute.make_ordered_layout(%s, %o)
         : (!cute.shape<"(2,(2,2),2)">, !cute.int_tuple<"(0,(2,3),1)">) -> !cute.layout<"(2,(2,2),2):(1,(4,8),2)">
  return %l : !cute.layout<"(2,(2,2),2):(1,(4,8),2)">
}

// -----

// Nested shape with nested order — hierarchical mode ordering.
// CHECK-LABEL: func.func @nested_order_with_non_hier_order
// CHECK-SAME: (%[[S:.+]]: !cute.shape<"(2,(2,2),2)">, %[[O:.+]]: !cute.int_tuple<"(0,2,1)">)
func.func @nested_order_with_non_hier_order(%s: !cute.shape<"(2,(2,2),2)">, %o: !cute.int_tuple<"(0,2,1)">) -> !cute.layout<"(2,(2,2),2):(1,(4,8),2)"> {
  // CHECK: cute.make_ordered_layout(%[[S]], %[[O]])
  // CHECK-SAME: -> !cute.layout<"(2,(2,2),2):(1,(4,8),2)">
  %l = cute.make_ordered_layout(%s, %o)
         : (!cute.shape<"(2,(2,2),2)">, !cute.int_tuple<"(0,2,1)">) -> !cute.layout<"(2,(2,2),2):(1,(4,8),2)">
  return %l : !cute.layout<"(2,(2,2),2):(1,(4,8),2)">
}

// -----

// Dynamic shape — result has a dynamic stride alongside the
// static-extent siblings.
// CHECK-LABEL: func.func @dynamic_shape
// CHECK-SAME: (%[[S:.+]]: !cute.shape<"(4,3,?,2)">, %[[O:.+]]: !cute.int_tuple<"(2,1,3,4)">)
func.func @dynamic_shape(%s: !cute.shape<"(4,3,?,2)">, %o: !cute.int_tuple<"(2,1,3,4)">) -> !cute.layout<"(4,3,?,2):(3,1,12,?)"> {
  // CHECK: cute.make_ordered_layout(%[[S]], %[[O]])
  // CHECK-SAME: -> !cute.layout<"(4,3,?,2):(3,1,12,?)">
  %l = cute.make_ordered_layout(%s, %o)
         : (!cute.shape<"(4,3,?,2)">, !cute.int_tuple<"(2,1,3,4)">) -> !cute.layout<"(4,3,?,2):(3,1,12,?)">
  return %l : !cute.layout<"(4,3,?,2):(3,1,12,?)">
}

// -----

// Non-canonical (non-zero-indexed) order values — relative ordering is what matters.
// CHECK-LABEL: func.func @noncanonical_order
// CHECK-SAME: (%[[S:.+]]: !cute.shape<"(2,(2,2),2)">, %[[O:.+]]: !cute.int_tuple<"(2,1,3)">)
func.func @noncanonical_order(%s: !cute.shape<"(2,(2,2),2)">, %o: !cute.int_tuple<"(2,1,3)">) -> !cute.layout<"(2,(2,2),2):(4,(1,2),8)"> {
  // CHECK: cute.make_ordered_layout(%[[S]], %[[O]])
  // CHECK-SAME: -> !cute.layout<"(2,(2,2),2):(4,(1,2),8)">
  %l = cute.make_ordered_layout(%s, %o)
         : (!cute.shape<"(2,(2,2),2)">, !cute.int_tuple<"(2,1,3)">) -> !cute.layout<"(2,(2,2),2):(4,(1,2),8)">
  return %l : !cute.layout<"(2,(2,2),2):(4,(1,2),8)">
}

// -----

// Rank-1 shape with rank-1 order.
// CHECK-LABEL: func.func @rank1_shape
// CHECK-SAME: (%[[S:.+]]: !cute.shape<"4">, %[[O:.+]]: !cute.int_tuple<"0">)
func.func @rank1_shape(%s: !cute.shape<"4">, %o: !cute.int_tuple<"0">) -> !cute.layout<"4:1"> {
  // CHECK: cute.make_ordered_layout(%[[S]], %[[O]])
  // CHECK-SAME: (!cute.shape<"4">, !cute.int_tuple<"0">) -> !cute.layout<"4:1">
  %l = cute.make_ordered_layout(%s, %o)
         : (!cute.shape<"4">, !cute.int_tuple<"0">) -> !cute.layout<"4:1">
  return %l : !cute.layout<"4:1">
}

// -----

// All-dynamic shape with static order: stride 1 lives in the mode whose
// order value is smallest; the other mode gets the prefix-product stride.
// CHECK-LABEL: func.func @all_dynamic_shape
// CHECK-SAME: (%[[S:.+]]: !cute.shape<"(?,?)">, %[[O:.+]]: !cute.int_tuple<"(0,1)">)
func.func @all_dynamic_shape(%s: !cute.shape<"(?,?)">, %o: !cute.int_tuple<"(0,1)">) -> !cute.layout<"(?,?):(1,?)"> {
  // CHECK: cute.make_ordered_layout(%[[S]], %[[O]])
  // CHECK-SAME: (!cute.shape<"(?,?)">, !cute.int_tuple<"(0,1)">) -> !cute.layout<"(?,?):(1,?)">
  %l = cute.make_ordered_layout(%s, %o)
         : (!cute.shape<"(?,?)">, !cute.int_tuple<"(0,1)">) -> !cute.layout<"(?,?):(1,?)">
  return %l : !cute.layout<"(?,?):(1,?)">
}

// -----

// Rank-3 shape with one dyn leaf, reversed order `(3,2,1)`. Stride 1
// goes to the mode with the smallest order value.
// CHECK-LABEL: func.func @rank3_dyn_reversed_order
// CHECK-SAME: (%[[S:.+]]: !cute.shape<"(4,3,?)">, %[[O:.+]]: !cute.int_tuple<"(3,2,1)">)
func.func @rank3_dyn_reversed_order(%s: !cute.shape<"(4,3,?)">,
                                    %o: !cute.int_tuple<"(3,2,1)">)
    -> !cute.layout<"(4,3,?):(?,?,1)"> {
  // CHECK: cute.make_ordered_layout(%[[S]], %[[O]])
  // CHECK-SAME: (!cute.shape<"(4,3,?)">, !cute.int_tuple<"(3,2,1)">) -> !cute.layout<"(4,3,?):(?,?,1)">
  %l = cute.make_ordered_layout(%s, %o)
       : (!cute.shape<"(4,3,?)">, !cute.int_tuple<"(3,2,1)">)
      -> !cute.layout<"(4,3,?):(?,?,1)">
  return %l : !cute.layout<"(4,3,?):(?,?,1)">
}

// -----

// Rank-3 shape with one dyn leaf, alternate order `(3,1,2)`.
// CHECK-LABEL: func.func @rank3_dyn_alternate_order
// CHECK-SAME: (%[[S:.+]]: !cute.shape<"(4,3,?)">, %[[O:.+]]: !cute.int_tuple<"(3,1,2)">)
func.func @rank3_dyn_alternate_order(%s: !cute.shape<"(4,3,?)">,
                                     %o: !cute.int_tuple<"(3,1,2)">)
    -> !cute.layout<"(4,3,?):(?,1,3)"> {
  // CHECK: cute.make_ordered_layout(%[[S]], %[[O]])
  // CHECK-SAME: (!cute.shape<"(4,3,?)">, !cute.int_tuple<"(3,1,2)">) -> !cute.layout<"(4,3,?):(?,1,3)">
  %l = cute.make_ordered_layout(%s, %o)
       : (!cute.shape<"(4,3,?)">, !cute.int_tuple<"(3,1,2)">)
      -> !cute.layout<"(4,3,?):(?,1,3)">
  return %l : !cute.layout<"(4,3,?):(?,1,3)">
}

// -----

// Rank-4 fully-static shape with permutation order `(0,2,3,1)`. Stride
// 1 → mode 0.
// CHECK-LABEL: func.func @rank4_static_permutation
// CHECK-SAME: (%[[S:.+]]: !cute.shape<"(2,2,2,2)">, %[[O:.+]]: !cute.int_tuple<"(0,2,3,1)">)
func.func @rank4_static_permutation(%s: !cute.shape<"(2,2,2,2)">,
                                    %o: !cute.int_tuple<"(0,2,3,1)">)
    -> !cute.layout<"(2,2,2,2):(1,4,8,2)"> {
  // CHECK: cute.make_ordered_layout(%[[S]], %[[O]])
  // CHECK-SAME: (!cute.shape<"(2,2,2,2)">, !cute.int_tuple<"(0,2,3,1)">) -> !cute.layout<"(2,2,2,2):(1,4,8,2)">
  %l = cute.make_ordered_layout(%s, %o)
       : (!cute.shape<"(2,2,2,2)">, !cute.int_tuple<"(0,2,3,1)">)
      -> !cute.layout<"(2,2,2,2):(1,4,8,2)">
  return %l : !cute.layout<"(2,2,2,2):(1,4,8,2)">
}
