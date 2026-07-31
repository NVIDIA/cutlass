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

// Tests `cute-expand-ops` lowering for `cute.make_identity_layout`.

// -----

// CHECK-LABEL: func.func @expand_static
// CHECK-NOT:   cute.make_identity_layout
// CHECK:       %[[R:.+]] = cute.static : !cute.layout<"(4,2):(1@0,1@1)">
func.func @expand_static() -> !cute.layout<"(4,2):(1@0,1@1)"> {
  %s = cute.make_shape() : () -> !cute.shape<"(4,2)">
  %r = cute.make_identity_layout(%s)
         : !cute.shape<"(4,2)"> -> !cute.layout<"(4,2):(1@0,1@1)">
  return %r : !cute.layout<"(4,2):(1@0,1@1)">
}

// -----

// CHECK-LABEL: func.func @expand_dynamic
// CHECK-NOT:   cute.make_identity_layout
// CHECK:       cute.get_scalars<{only_dynamic}> (%{{.+}})
// CHECK:       %[[SHAPE:.+]] = cute.make_shape
// CHECK-SAME:                -> !cute.shape<"(2,(?,?),5)">
// CHECK:       %[[STRIDE:.+]] = cute.make_stride
// CHECK-SAME:                 -> !cute.stride<"(1@0,(1@0@1,1@1@1),1@2)">
// CHECK:       %[[LAYOUT:.+]] = cute.make_layout(%[[SHAPE]], %[[STRIDE]])
// CHECK-SAME:                 -> !cute.layout<"(2,(?,?),5):(1@0,(1@0@1,1@1@1),1@2)">
func.func @expand_dynamic(%shape: !cute.shape<"(2,(?,?),5)">)
    -> !cute.layout<"(2,(?,?),5):(1@0,(1@0@1,1@1@1),1@2)"> {
  %r = cute.make_identity_layout(%shape)
         : !cute.shape<"(2,(?,?),5)">
        -> !cute.layout<"(2,(?,?),5):(1@0,(1@0@1,1@1@1),1@2)">
  return %r : !cute.layout<"(2,(?,?),5):(1@0,(1@0@1,1@1@1),1@2)">
}

// -----

// All-dynamic shape — strides are still fully static basis vectors. Since
// identity strides have no dependence on the shape values, no arith ops
// are emitted; the dynamic shape leaves flow straight into `make_shape`.
// CHECK-LABEL: func.func @expand_all_dynamic_shape
// CHECK-NOT:   cute.make_identity_layout
// CHECK-NOT:   arith.muli
// CHECK:       cute.get_scalars<{only_dynamic}> (%{{.+}})
// CHECK:       %[[SHAPE:.+]] = cute.make_shape
// CHECK-SAME:                -> !cute.shape<"(?,?)">
// CHECK:       %[[STRIDE:.+]] = cute.make_stride() : () -> !cute.stride<"(1@0,1@1)">
// CHECK:       %[[LAYOUT:.+]] = cute.make_layout(%[[SHAPE]], %[[STRIDE]])
// CHECK-SAME:                 -> !cute.layout<"(?,?):(1@0,1@1)">
func.func @expand_all_dynamic_shape(%shape: !cute.shape<"(?,?)">)
    -> !cute.layout<"(?,?):(1@0,1@1)"> {
  %r = cute.make_identity_layout(%shape)
         : !cute.shape<"(?,?)"> -> !cute.layout<"(?,?):(1@0,1@1)">
  return %r : !cute.layout<"(?,?):(1@0,1@1)">
}
