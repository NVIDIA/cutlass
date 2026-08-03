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

// RUN: %cutlass-compiler-run-host %s | FileCheck %s
//
// All-static AdvancedConstructors; cute-fold-static evaluates every op, no arith.* survives.
// RUN: cutlass-compiler -cute-fold-static -cute-expand-ops -cute-to-base \
// RUN:     -base-prepare %s | FileCheck --check-prefix=POST-PREP %s
//
// POST-PREP-NOT: arith.

// Each op runs via direct inline and helper-call paths.

// CHECK-COUNT-2: (4,2):(2,1)
// CHECK-COUNT-2: (4,2):(1@0,1@1)
// CHECK-COUNT-2: (4,2):(1,4)
// CHECK-COUNT-2: (8,2):(1,8)
// CHECK-COUNT-2: (2,(3,4)):(1@0,(1@0@1,1@1@1))

//===----------------------------------------------------------------------===//
// Per-op helpers.
//===----------------------------------------------------------------------===//

func.func @h_make_layout_like(%src: !cute.layout<"(4,2):(4,1)">)
    -> !cute.layout<"(4,2):(2,1)"> {
  %r = cute.make_layout_like(%src)
       : !cute.layout<"(4,2):(4,1)"> -> !cute.layout<"(4,2):(2,1)">
  return %r : !cute.layout<"(4,2):(2,1)">
}

func.func @h_make_identity_layout(%s: !cute.shape<"(4,2)">)
    -> !cute.layout<"(4,2):(1@0,1@1)"> {
  %r = cute.make_identity_layout(%s)
       : !cute.shape<"(4,2)"> -> !cute.layout<"(4,2):(1@0,1@1)">
  return %r : !cute.layout<"(4,2):(1@0,1@1)">
}

func.func @h_make_ordered_layout(%s: !cute.shape<"(4,2)">,
                                 %o: !cute.int_tuple<"(0,1)">)
    -> !cute.layout<"(4,2):(1,4)"> {
  %r = cute.make_ordered_layout(%s, %o)
       : (!cute.shape<"(4,2)">, !cute.int_tuple<"(0,1)">) -> !cute.layout<"(4,2):(1,4)">
  return %r : !cute.layout<"(4,2):(1,4)">
}

// Composed-source helpers — exercise the ComposedLayoutType branch.

func.func @h_make_layout_like_composed(
    %src: !cute.composed_layout<"S<3,4,3> o 6 o (8,2):(2,16)">)
    -> !cute.layout<"(8,2):(1,8)"> {
  %r = cute.make_layout_like(%src)
       : !cute.composed_layout<"S<3,4,3> o 6 o (8,2):(2,16)"> -> !cute.layout<"(8,2):(1,8)">
  return %r : !cute.layout<"(8,2):(1,8)">
}

func.func @h_make_identity_layout_nested(%s: !cute.shape<"(2,(3,4))">)
    -> !cute.layout<"(2,(3,4)):(1@0,(1@0@1,1@1@1))"> {
  %r = cute.make_identity_layout(%s)
       : !cute.shape<"(2,(3,4))"> -> !cute.layout<"(2,(3,4)):(1@0,(1@0@1,1@1@1))">
  return %r : !cute.layout<"(2,(3,4)):(1@0,(1@0@1,1@1@1))">
}

//===----------------------------------------------------------------------===//
// Entry point.
//===----------------------------------------------------------------------===//

func.func @main() {
  // make_layout_like — canonicalize a layout's stride to packed form.
  // Input row-major (4,2):(4,1) → output (4,2):(2,1).
  %src1 = cute.static : !cute.layout<"(4,2):(4,1)">
  %r1 = cute.make_layout_like(%src1)
       : !cute.layout<"(4,2):(4,1)"> -> !cute.layout<"(4,2):(2,1)">
  cute.print(%r1) : !cute.layout<"(4,2):(2,1)">
  %r1b = func.call @h_make_layout_like(%src1)
       : (!cute.layout<"(4,2):(4,1)">) -> !cute.layout<"(4,2):(2,1)">
  cute.print(%r1b) : !cute.layout<"(4,2):(2,1)">

  // make_identity_layout — produce the identity layout for a shape.
  %s2 = cute.static : !cute.shape<"(4,2)">
  %r2 = cute.make_identity_layout(%s2)
       : !cute.shape<"(4,2)"> -> !cute.layout<"(4,2):(1@0,1@1)">
  cute.print(%r2) : !cute.layout<"(4,2):(1@0,1@1)">
  %r2b = func.call @h_make_identity_layout(%s2)
       : (!cute.shape<"(4,2)">) -> !cute.layout<"(4,2):(1@0,1@1)">
  cute.print(%r2b) : !cute.layout<"(4,2):(1@0,1@1)">

  // make_ordered_layout — strides ordered by the given int_tuple
  // ordering. (0,1) selects col-major: (4,2):(1,4).
  %s3 = cute.static : !cute.shape<"(4,2)">
  %ord = cute.static : !cute.int_tuple<"(0,1)">
  %r3 = cute.make_ordered_layout(%s3, %ord)
       : (!cute.shape<"(4,2)">, !cute.int_tuple<"(0,1)">) -> !cute.layout<"(4,2):(1,4)">
  cute.print(%r3) : !cute.layout<"(4,2):(1,4)">
  %r3b = func.call @h_make_ordered_layout(%s3, %ord)
       : (!cute.shape<"(4,2)">, !cute.int_tuple<"(0,1)">) -> !cute.layout<"(4,2):(1,4)">
  cute.print(%r3b) : !cute.layout<"(4,2):(1,4)">

  // make_layout_like with a composed-layout source — exercises the
  // ComposedLayoutType branch (algorithm runs on outer B).
  // B = (8,2):(2,16) → compact-reordered result (8,2):(1,8).
  %src5 = cute.static : !cute.composed_layout<"S<3,4,3> o 6 o (8,2):(2,16)">
  %r5 = cute.make_layout_like(%src5)
       : !cute.composed_layout<"S<3,4,3> o 6 o (8,2):(2,16)"> -> !cute.layout<"(8,2):(1,8)">
  cute.print(%r5) : !cute.layout<"(8,2):(1,8)">
  %r5b = func.call @h_make_layout_like_composed(%src5)
       : (!cute.composed_layout<"S<3,4,3> o 6 o (8,2):(2,16)">) -> !cute.layout<"(8,2):(1,8)">
  cute.print(%r5b) : !cute.layout<"(8,2):(1,8)">

  // make_identity_layout with a nested shape — depth-2 basis chains
  // `1@0@1 / 1@1@1` are emitted for the inner mode (3,4).
  %s7 = cute.static : !cute.shape<"(2,(3,4))">
  %r7 = cute.make_identity_layout(%s7)
       : !cute.shape<"(2,(3,4))"> -> !cute.layout<"(2,(3,4)):(1@0,(1@0@1,1@1@1))">
  cute.print(%r7) : !cute.layout<"(2,(3,4)):(1@0,(1@0@1,1@1@1))">
  %r7b = func.call @h_make_identity_layout_nested(%s7)
       : (!cute.shape<"(2,(3,4))">) -> !cute.layout<"(2,(3,4)):(1@0,(1@0@1,1@1@1))">
  cute.print(%r7b) : !cute.layout<"(2,(3,4)):(1@0,(1@0@1,1@1@1))">

  return
}
