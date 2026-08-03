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

// Tests `cute-expand-ops` lowering for `cute.shape_div`.

// -----

// (scalar, scalar) static.
// CHECK-LABEL: func.func @expand_scalar_scalar
// CHECK-NOT:   cute.shape_div
// CHECK:       cute.static : !cute.shape<"3">
func.func @expand_scalar_scalar(%a: !cute.shape<"12">, %b: !cute.shape<"4">)
    -> !cute.shape<"3"> {
  %r = cute.shape_div(%a, %b)
         : (!cute.shape<"12">, !cute.shape<"4">) -> !cute.shape<"3">
  return %r : !cute.shape<"3">
}

// -----

// (tuple, tuple) static — element-wise.
// CHECK-LABEL: func.func @expand_tuple_tuple_static
// CHECK-NOT:   cute.shape_div
// CHECK:       cute.static : !cute.shape<"(4,2)">
func.func @expand_tuple_tuple_static(%a: !cute.shape<"(8,10)">,
                                      %b: !cute.shape<"(2,5)">)
    -> !cute.shape<"(4,2)"> {
  %r = cute.shape_div(%a, %b)
         : (!cute.shape<"(8,10)">, !cute.shape<"(2,5)">)
        -> !cute.shape<"(4,2)">
  return %r : !cute.shape<"(4,2)">
}

// -----

// (tuple, scalar) static.
// CHECK-LABEL: func.func @expand_tuple_scalar
// CHECK-NOT:   cute.shape_div
// CHECK:       cute.static : !cute.shape<"(1,1,3)">
func.func @expand_tuple_scalar(%a: !cute.shape<"(4,5,6)">,
                                %b: !cute.shape<"40">)
    -> !cute.shape<"(1,1,3)"> {
  %r = cute.shape_div(%a, %b)
         : (!cute.shape<"(4,5,6)">, !cute.shape<"40">)
        -> !cute.shape<"(1,1,3)">
  return %r : !cute.shape<"(1,1,3)">
}

// -----

// (scalar, tuple) static.
// CHECK-LABEL: func.func @expand_scalar_tuple
// CHECK-NOT:   cute.shape_div
// CHECK:       cute.static : !cute.shape<"4">
func.func @expand_scalar_tuple(%a: !cute.shape<"24">,
                                %b: !cute.shape<"(2,3)">)
    -> !cute.shape<"4"> {
  %r = cute.shape_div(%a, %b)
         : (!cute.shape<"24">, !cute.shape<"(2,3)">)
        -> !cute.shape<"4">
  return %r : !cute.shape<"4">
}

// -----

// (tuple, tuple) dynamic.
// CHECK-LABEL: func.func @expand_tuple_tuple_dynamic
// CHECK-NOT:   cute.shape_div
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       arith.divsi
// CHECK:       cute.make_shape
// CHECK-SAME:  -> !cute.shape<"(?,?)">
func.func @expand_tuple_tuple_dynamic(%a: !cute.shape<"(?,?)">,
                                       %b: !cute.shape<"(2,3)">)
    -> !cute.shape<"(?,?)"> {
  %r = cute.shape_div(%a, %b)
         : (!cute.shape<"(?,?)">, !cute.shape<"(2,3)">)
        -> !cute.shape<"(?,?)">
  return %r : !cute.shape<"(?,?)">
}
