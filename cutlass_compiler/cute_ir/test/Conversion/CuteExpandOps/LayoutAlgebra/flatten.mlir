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

// Tests `cute-expand-ops` lowering for `cute.flatten`.

// -----

// Static layout: folds to cute.static.
// CHECK-LABEL: func.func @expand_static
// CHECK-NOT:   cute.flatten
// CHECK:       cute.static : !cute.layout<"(3,4,5):(8,1,4)">
func.func @expand_static(%src: !cute.layout<"(3,(4,5)):(8,(1,4))">)
    -> !cute.layout<"(3,4,5):(8,1,4)"> {
  %r = cute.flatten(%src)
         : (!cute.layout<"(3,(4,5)):(8,(1,4))">) -> !cute.layout<"(3,4,5):(8,1,4)">
  return %r : !cute.layout<"(3,4,5):(8,1,4)">
}

// -----

// Static composed layout: B flattened, result.
// CHECK-LABEL: func.func @expand_composed_static
// CHECK-NOT:   cute.flatten
// CHECK:       cute.static : !cute.composed_layout<"(4,5):(1,4) o 2 o (3,4,5):(8,1,4)">
func.func @expand_composed_static(
    %src: !cute.composed_layout<"(4,5):(1,4) o 2 o (3,(4,5)):(8,(1,4))">)
    -> !cute.composed_layout<"(4,5):(1,4) o 2 o (3,4,5):(8,1,4)"> {
  %r = cute.flatten(%src)
         : (!cute.composed_layout<"(4,5):(1,4) o 2 o (3,(4,5)):(8,(1,4))">)
        -> !cute.composed_layout<"(4,5):(1,4) o 2 o (3,4,5):(8,1,4)">
  return %r : !cute.composed_layout<"(4,5):(1,4) o 2 o (3,4,5):(8,1,4)">
}

// -----

// Dynamic flat input.
// CHECK-LABEL: func.func @expand_layout_keeps_dynamic
// CHECK-NOT:   cute.flatten
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_layout
// CHECK-SAME:  -> !cute.layout<"(?,3):(1,?)">
func.func @expand_layout_keeps_dynamic(%src: !cute.layout<"(?,3):(1,?)">)
    -> !cute.layout<"(?,3):(1,?)"> {
  %r = cute.flatten(%src)
         : (!cute.layout<"(?,3):(1,?)">) -> !cute.layout<"(?,3):(1,?)">
  return %r : !cute.layout<"(?,3):(1,?)">
}

// -----

// Dynamic nested input: flatten removes the nesting and the result keeps the
// dynamic leaves intact.
// CHECK-LABEL: func.func @expand_layout_nested_dynamic
// CHECK-NOT:   cute.flatten
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_layout
// CHECK-SAME:  -> !cute.layout<"(3,?,5):(?,1,?)">
func.func @expand_layout_nested_dynamic(
    %src: !cute.layout<"(3,(?,5)):(?,(1,?))">) -> !cute.layout<"(3,?,5):(?,1,?)"> {
  %r = cute.flatten(%src)
         : (!cute.layout<"(3,(?,5)):(?,(1,?))">) -> !cute.layout<"(3,?,5):(?,1,?)">
  return %r : !cute.layout<"(3,?,5):(?,1,?)">
}

// -----

// Composed layout with dynamic B.
// CHECK-LABEL: func.func @expand_composed_layout_keeps_dynamic
// CHECK-NOT:   cute.flatten
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_layout
// CHECK:       cute.make_composed_layout
// CHECK-SAME:  -> <"S<3,5,4> o 0 o (3,?,5):(?,1,?)">
func.func @expand_composed_layout_keeps_dynamic(
    %src: !cute.composed_layout<"S<3,5,4> o 0 o (3,(?,5)):(?,(1,?))">)
    -> !cute.composed_layout<"S<3,5,4> o 0 o (3,?,5):(?,1,?)"> {
  %r = cute.flatten(%src)
         : (!cute.composed_layout<"S<3,5,4> o 0 o (3,(?,5)):(?,(1,?))">)
        -> !cute.composed_layout<"S<3,5,4> o 0 o (3,?,5):(?,1,?)">
  return %r : !cute.composed_layout<"S<3,5,4> o 0 o (3,?,5):(?,1,?)">
}

// -----

// Tuple-kind input — static shape: folds to cute.static.
// CHECK-LABEL: func.func @expand_shape_static
// CHECK-NOT:   cute.flatten
// CHECK:       cute.static : !cute.shape<"(3,4,5)">
func.func @expand_shape_static(%src: !cute.shape<"(3,(4,5))">)
    -> !cute.shape<"(3,4,5)"> {
  %r = cute.flatten(%src) : (!cute.shape<"(3,(4,5))">) -> !cute.shape<"(3,4,5)">
  return %r : !cute.shape<"(3,4,5)">
}

// -----

// Dynamic shape.
// CHECK-LABEL: func.func @expand_shape_dynamic
// CHECK-NOT:   cute.flatten
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_shape
// CHECK-SAME:  -> !cute.shape<"(3,?,5)">
func.func @expand_shape_dynamic(%src: !cute.shape<"(3,(?,5))">)
    -> !cute.shape<"(3,?,5)"> {
  %r = cute.flatten(%src) : (!cute.shape<"(3,(?,5))">) -> !cute.shape<"(3,?,5)">
  return %r : !cute.shape<"(3,?,5)">
}
