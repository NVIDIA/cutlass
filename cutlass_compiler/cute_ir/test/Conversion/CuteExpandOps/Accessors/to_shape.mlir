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

// Tests `cute-expand-ops` lowering for `cute.to_shape`.

// -----

// CHECK-LABEL: func.func @expand_static
// CHECK-NOT:   cute.to_shape
// CHECK:       cute.static : !cute.shape<"(4,8)">
func.func @expand_static(%i: !cute.int_tuple<"(4,8)">) -> !cute.shape<"(4,8)"> {
  %r = cute.to_shape(%i) : !cute.int_tuple<"(4,8)"> -> !cute.shape<"(4,8)">
  return %r : !cute.shape<"(4,8)">
}

// -----

// CHECK-LABEL: func.func @expand_dynamic
// CHECK-NOT:   cute.to_shape
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       %[[R:.+]] = cute.make_shape
// CHECK-SAME:            -> !cute.shape<"(?,4)">
func.func @expand_dynamic(%i: !cute.int_tuple<"(?,4)">) -> !cute.shape<"(?,4)"> {
  %r = cute.to_shape(%i) : !cute.int_tuple<"(?,4)"> -> !cute.shape<"(?,4)">
  return %r : !cute.shape<"(?,4)">
}
