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

// RUN: cute-opt -cute-expand-ops --split-input-file %s | FileCheck %s

// Tests `cute-expand-ops` lowering for `cute.tuple_sub`.

// -----

// CHECK-LABEL: func.func @expand_static_int_tuple
// CHECK-NOT:   cute.tuple_sub
// CHECK:       cute.static : !cute.int_tuple<"(4,6)">
func.func @expand_static_int_tuple(%a: !cute.int_tuple<"(5,8)">,
                                    %b: !cute.int_tuple<"(1,2)">)
    -> !cute.int_tuple<"(4,6)"> {
  %r = cute.tuple_sub(%a, %b)
         : (!cute.int_tuple<"(5,8)">, !cute.int_tuple<"(1,2)">)
        -> !cute.int_tuple<"(4,6)">
  return %r : !cute.int_tuple<"(4,6)">
}

// -----

// CHECK-LABEL: func.func @expand_static_shape
// CHECK-NOT:   cute.tuple_sub
// CHECK:       cute.static : !cute.shape<"(4,6)">
func.func @expand_static_shape(%a: !cute.shape<"(5,8)">,
                                %b: !cute.shape<"(1,2)">)
    -> !cute.shape<"(4,6)"> {
  %r = cute.tuple_sub(%a, %b)
         : (!cute.shape<"(5,8)">, !cute.shape<"(1,2)">)
        -> !cute.shape<"(4,6)">
  return %r : !cute.shape<"(4,6)">
}

// -----

// CHECK-LABEL: func.func @expand_int_tuple_dynamic
// CHECK-NOT:   cute.tuple_sub
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK-COUNT-2: arith.subi {{.+}} : i32
// CHECK-NOT:   arith.subi
// CHECK:       cute.make_int_tuple
// CHECK-SAME:  -> !cute.int_tuple<"(?,?)">
func.func @expand_int_tuple_dynamic(%a: !cute.int_tuple<"(?,?)">,
                                     %b: !cute.int_tuple<"(1,2)">)
    -> !cute.int_tuple<"(?,?)"> {
  %r = cute.tuple_sub(%a, %b)
         : (!cute.int_tuple<"(?,?)">, !cute.int_tuple<"(1,2)">)
        -> !cute.int_tuple<"(?,?)">
  return %r : !cute.int_tuple<"(?,?)">
}

// -----

// CHECK-LABEL: func.func @expand_shape_dynamic
// CHECK-NOT:   cute.tuple_sub
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_shape
// CHECK-SAME:  -> !cute.shape<"(?,?)">
func.func @expand_shape_dynamic(%a: !cute.shape<"(?,?)">,
                                 %b: !cute.shape<"(1,2)">)
    -> !cute.shape<"(?,?)"> {
  %r = cute.tuple_sub(%a, %b)
         : (!cute.shape<"(?,?)">, !cute.shape<"(1,2)">)
        -> !cute.shape<"(?,?)">
  return %r : !cute.shape<"(?,?)">
}

// -----

// Nested dynamic int_tuple.
// CHECK-LABEL: func.func @expand_nested_dyn
// CHECK-NOT:     cute.tuple_sub
// CHECK:         cute.get_scalars<{only_dynamic}>
// CHECK:         cute.get_scalars<{only_dynamic}>
// CHECK-COUNT-2: arith.subi %{{.+}}, %{{.+}} overflow<nsw> : i32
// CHECK:         cute.make_int_tuple
func.func @expand_nested_dyn(
    %lhs: !cute.int_tuple<"((2,?),?)">,
    %rhs: !cute.int_tuple<"((1,?),?)">)
    -> !cute.int_tuple<"((1,?),?)"> {
  %r = cute.tuple_sub(%lhs, %rhs)
         : (!cute.int_tuple<"((2,?),?)">,
            !cute.int_tuple<"((1,?),?)">)
        -> !cute.int_tuple<"((1,?),?)">
  return %r : !cute.int_tuple<"((1,?),?)">
}
