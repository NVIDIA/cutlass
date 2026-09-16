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

// Tests `cute-expand-ops` lowering for `cute.to_int_tuple`.

// -----

// CHECK-LABEL: func.func @expand_shape_static
// CHECK-NOT:   cute.to_int_tuple
// CHECK:       cute.static : !cute.int_tuple<"(4,8)">
func.func @expand_shape_static(%s: !cute.shape<"(4,8)">)
    -> !cute.int_tuple<"(4,8)"> {
  %r = cute.to_int_tuple(%s) : !cute.shape<"(4,8)"> -> !cute.int_tuple<"(4,8)">
  return %r : !cute.int_tuple<"(4,8)">
}

// -----

// CHECK-LABEL: func.func @expand_shape_dynamic
// CHECK-NOT:   cute.to_int_tuple
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       %[[T:.+]] = cute.make_int_tuple
// CHECK-SAME:            -> !cute.int_tuple<"(?,4)">
func.func @expand_shape_dynamic(%s: !cute.shape<"(?,4)">)
    -> !cute.int_tuple<"(?,4)"> {
  %r = cute.to_int_tuple(%s) : !cute.shape<"(?,4)"> -> !cute.int_tuple<"(?,4)">
  return %r : !cute.int_tuple<"(?,4)">
}

// -----

// CHECK-LABEL: func.func @expand_stride_static
// CHECK-NOT:   cute.to_int_tuple
// CHECK:       cute.static : !cute.int_tuple<"(1,4)">
func.func @expand_stride_static(%d: !cute.stride<"(1,4)">)
    -> !cute.int_tuple<"(1,4)"> {
  %r = cute.to_int_tuple(%d) : !cute.stride<"(1,4)"> -> !cute.int_tuple<"(1,4)">
  return %r : !cute.int_tuple<"(1,4)">
}

// -----

// CHECK-LABEL: func.func @expand_stride_dynamic
// CHECK-NOT:   cute.to_int_tuple
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       %[[T:.+]] = cute.make_int_tuple
// CHECK-SAME:            -> !cute.int_tuple<"(1,?)">
func.func @expand_stride_dynamic(%d: !cute.stride<"(1,?)">)
    -> !cute.int_tuple<"(1,?)"> {
  %r = cute.to_int_tuple(%d) : !cute.stride<"(1,?)"> -> !cute.int_tuple<"(1,?)">
  return %r : !cute.int_tuple<"(1,?)">
}

// -----

// CHECK-LABEL: func.func @expand_coord_static
// CHECK-NOT:   cute.to_int_tuple
// CHECK:       cute.static : !cute.int_tuple<"(0,1)">
func.func @expand_coord_static(%c: !cute.coord<"(0,1)">)
    -> !cute.int_tuple<"(0,1)"> {
  %r = cute.to_int_tuple(%c) : !cute.coord<"(0,1)"> -> !cute.int_tuple<"(0,1)">
  return %r : !cute.int_tuple<"(0,1)">
}

// -----

// CHECK-LABEL: func.func @expand_coord_dynamic
// CHECK-NOT:   cute.to_int_tuple
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       %[[T:.+]] = cute.make_int_tuple
// CHECK-SAME:            -> !cute.int_tuple<"(?,3)">
func.func @expand_coord_dynamic(%c: !cute.coord<"(?,3)">)
    -> !cute.int_tuple<"(?,3)"> {
  %r = cute.to_int_tuple(%c) : !cute.coord<"(?,3)"> -> !cute.int_tuple<"(?,3)">
  return %r : !cute.int_tuple<"(?,3)">
}

// -----

// int_tuple → int_tuple is the identity case.
// CHECK-LABEL: func.func @expand_int_tuple_static
// CHECK-NOT:   cute.to_int_tuple
// CHECK:       cute.static : !cute.int_tuple<"(2,3)">
func.func @expand_int_tuple_static(%i: !cute.int_tuple<"(2,3)">)
    -> !cute.int_tuple<"(2,3)"> {
  %r = cute.to_int_tuple(%i)
         : !cute.int_tuple<"(2,3)"> -> !cute.int_tuple<"(2,3)">
  return %r : !cute.int_tuple<"(2,3)">
}

// -----

// CHECK-LABEL: func.func @expand_int_tuple_dynamic
// CHECK-NOT:   cute.to_int_tuple
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       %[[T:.+]] = cute.make_int_tuple
// CHECK-SAME:            -> !cute.int_tuple<"(?,3)">
func.func @expand_int_tuple_dynamic(%i: !cute.int_tuple<"(?,3)">)
    -> !cute.int_tuple<"(?,3)"> {
  %r = cute.to_int_tuple(%i)
         : !cute.int_tuple<"(?,3)"> -> !cute.int_tuple<"(?,3)">
  return %r : !cute.int_tuple<"(?,3)">
}
