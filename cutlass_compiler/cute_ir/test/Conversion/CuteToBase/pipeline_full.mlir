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

// End-to-end pipeline: `cute-fold-static` → `cute-expand-ops` →
// `cute-to-base` → `reconcile-unrealized-casts`. Each test asserts that
// no `cute.*` op survives.

//===----------------------------------------------------------------------===//
// Surviving ops: constructors + static + assume + get_scalars + print
//===----------------------------------------------------------------------===//

// Static layout assembled via make_shape + make_layout, then printed.
// CHECK-LABEL: func.func @static_make_layout_print
// CHECK-NOT:     cute.
// CHECK:         llvm.call @printf
// CHECK:         return
func.func @static_make_layout_print() {
  %s = cute.make_shape () : () -> !cute.shape<"(2,3)">
  %l_stride = cute.make_stride () : () -> !cute.stride<"(1,2)">
  %l = cute.make_layout (%s, %l_stride) : (!cute.shape<"(2,3)">, !cute.stride<"(1,2)">) -> !cute.layout<"(2,3):(1,2)">
  cute.print(%l) : !cute.layout<"(2,3):(1,2)">
  return
}

// -----

// Dynamic shape round-trip: make_shape → print.
// CHECK-LABEL: func.func @dyn_shape_print
// CHECK-SAME:    (%[[A:.+]]: i32, %[[B:.+]]: i32)
// CHECK-NOT:     cute.
// CHECK:         llvm.call @printf
// CHECK:         return
func.func @dyn_shape_print(%a: i32, %b: i32) {
  %s = cute.make_shape (%a, %b) : (i32, i32) -> !cute.shape<"(?,?)">
  cute.print(%s) : !cute.shape<"(?,?)">
  return
}

// -----

// make_int_tuple (dynamic) + print.
// CHECK-LABEL: func.func @dyn_int_tuple_print
// CHECK-SAME:    (%[[A:.+]]: i32)
// CHECK-NOT:     cute.
// CHECK:         llvm.call @printf
// CHECK:         return
func.func @dyn_int_tuple_print(%a: i32) {
  %t = cute.make_int_tuple (%a) : (i32) -> !cute.int_tuple<"(?,4)">
  cute.print(%t) : !cute.int_tuple<"(?,4)">
  return
}

// -----

// make_stride (dynamic) + print.
// CHECK-LABEL: func.func @dyn_stride_print
// CHECK-SAME:    (%[[A:.+]]: i32)
// CHECK-NOT:     cute.
// CHECK:         llvm.call @printf
// CHECK:         return
func.func @dyn_stride_print(%a: i32) {
  %st = cute.make_stride (%a) : (i32) -> !cute.stride<"(?,1)">
  cute.print(%st) : !cute.stride<"(?,1)">
  return
}

// -----

// make_coord (dynamic + underscore) + print.
// CHECK-LABEL: func.func @dyn_coord_print
// CHECK-SAME:    (%[[A:.+]]: i32)
// CHECK-NOT:     cute.
// CHECK:         llvm.call @printf
// CHECK:         return
func.func @dyn_coord_print(%a: i32) {
  %c = cute.make_coord (%a) : (i32) -> !cute.coord<"(?,_)">
  cute.print(%c) : !cute.coord<"(?,_)">
  return
}

// -----

// make_tile (static) + print.
// CHECK-LABEL: func.func @static_tile_print
// CHECK-NOT:     cute.
// CHECK:         llvm.call @printf
// CHECK:         return
func.func @static_tile_print() {
  %t = cute.make_tile () : () -> !cute.tile<"[(2,3):(1,2)]">
  cute.print(%t) : !cute.tile<"[(2,3):(1,2)]">
  return
}

// -----

// make_composed_layout (dynamic offset) + print.
// CHECK-LABEL: func.func @dyn_composed_layout_print
// CHECK-SAME:    (%[[OFF:.+]]: i32)
// CHECK-NOT:     cute.
// CHECK:         llvm.call @printf
// CHECK:         return
func.func @dyn_composed_layout_print(%off: i32) {
  %a = cute.static : !cute.layout<"(4,5):(1,4)">
  %o = cute.make_int_tuple (%off) : (i32) -> !cute.int_tuple<"?">
  %b = cute.static : !cute.layout<"(2,3):(1,2)">
  %cl = cute.make_composed_layout (%a, %o, %b)
        : (!cute.layout<"(4,5):(1,4)">, !cute.int_tuple<"?">, !cute.layout<"(2,3):(1,2)">)
       -> !cute.composed_layout<"(4,5):(1,4) o ? o (2,3):(1,2)">
  cute.print(%cl) : !cute.composed_layout<"(4,5):(1,4) o ? o (2,3):(1,2)">
  return
}

// -----

// make_int_tuple of a scalar dynamic, followed by print — confirms
// the full pipeline lowers the constructor + printf in tandem.
// CHECK-LABEL: func.func @make_int_tuple_print
// CHECK-SAME:    (%[[N:.+]]: i32)
// CHECK-NOT:     cute.
// CHECK:         llvm.call @printf
// CHECK:         return
func.func @make_int_tuple_print(%n: i32) {
  %t = cute.make_int_tuple (%n)
       : (i32) -> !cute.int_tuple<"?">
  cute.print(%t) : !cute.int_tuple<"?">
  return
}

// -----

// cute.get_scalars exercised directly (not as a transient).
// CHECK-LABEL: func.func @get_scalars_only_dyn
// CHECK-NOT:     cute.
// CHECK-COUNT-2: llvm.extractvalue
// CHECK:         return
func.func @get_scalars_only_dyn(%l: !cute.layout<"(?,4):(1,?)">) -> (i32, i32) {
  %a, %b = cute.get_scalars<{only_dynamic}> (%l) : !cute.layout<"(?,4):(1,?)">
  return %a, %b : i32, i32
}

//===----------------------------------------------------------------------===//
// Algebra ops — one representative per category; the pipeline must
// produce zero cute ops.
//===----------------------------------------------------------------------===//

// AdvancedConstructors — make_layout_like over a dynamic source.
// CHECK-LABEL: func.func @advanced_make_layout_like
// CHECK-NOT:     cute.
// CHECK:         return
func.func @advanced_make_layout_like(%a: !cute.layout<"(?,4):(?,1)">)
    -> !cute.layout<"(?,4):(4,1)"> {
  %r = cute.make_layout_like(%a)
         : !cute.layout<"(?,4):(?,1)"> -> !cute.layout<"(?,4):(4,1)">
  return %r : !cute.layout<"(?,4):(4,1)">
}

// -----

// Accessors — cute.get on a static shape.
// CHECK-LABEL: func.func @accessor_get
// CHECK-NOT:     cute.
// CHECK:         return
func.func @accessor_get(%a: !cute.shape<"(4,(2,3))">) -> !cute.shape<"(2,3)"> {
  %r = cute.get<[1]>(%a) : !cute.shape<"(4,(2,3))"> -> !cute.shape<"(2,3)">
  return %r : !cute.shape<"(2,3)">
}

// -----

// LayoutAlgebra — composition of two static layouts.
// CHECK-LABEL: func.func @layout_algebra_composition
// CHECK-NOT:     cute.
// CHECK:         return
func.func @layout_algebra_composition(%a: !cute.layout<"(4,8):(1,4)">,
                                        %b: !cute.layout<"(2,4):(1,2)">)
    -> !cute.layout<"(2,4):(1,2)"> {
  %r = cute.composition(%a, %b)
         : (!cute.layout<"(4,8):(1,4)">, !cute.layout<"(2,4):(1,2)">)
        -> !cute.layout<"(2,4):(1,2)">
  return %r : !cute.layout<"(2,4):(1,2)">
}

// -----

// LayoutAlgebra — dynamic right_inverse keeps the runtime extent through the
// complete expansion and base-lowering pipeline.
// CHECK-LABEL: func.func @layout_algebra_right_inverse_dynamic_shape
// CHECK-SAME:    (%[[SRC:.+]]: !llvm.struct<(i32, struct<()>)>) -> i32
// CHECK-NOT:     cute.
// CHECK:         %[[N:.+]] = llvm.extractvalue %[[SRC]][0]
// CHECK:         %[[WITH_N:.+]] = llvm.insertvalue %[[N]], %{{.+}}[0]
// CHECK:         %[[OUT:.+]] = llvm.insertvalue %{{.+}}, %[[WITH_N]][1]
// CHECK:         %[[RESULT_N:.+]] = llvm.extractvalue %[[OUT]][0]
// CHECK:         return %[[RESULT_N]] : i32
func.func @layout_algebra_right_inverse_dynamic_shape(
    %src: !cute.layout<"(16,?):(1,16)">) -> i32 {
  %r = cute.right_inverse(%src)
         : (!cute.layout<"(16,?):(1,16)">) -> !cute.layout<"(16,?):(1,16)">
  %n = cute.get_scalars<{only_dynamic}> (%r)
         : !cute.layout<"(16,?):(1,16)">
  return %n : i32
}

// -----

// LayoutAlgebra — a runtime shape extent becomes the inverse's runtime stride
// after a static zero-stride mode is skipped.
// CHECK-LABEL: func.func @layout_algebra_right_inverse_zero_stride
// CHECK-SAME:    (%[[SRC:.+]]: !llvm.struct<(i32, struct<()>)>) -> i32
// CHECK-NOT:     cute.
// CHECK:         %[[N:.+]] = llvm.extractvalue %[[SRC]][0]
// CHECK:         %[[BASE:.+]] = llvm.insertvalue %{{.+}}, %{{.+}}[0]
// CHECK:         %[[WITH_N:.+]] = llvm.insertvalue %[[N]], %[[BASE]][1]
// CHECK:         %[[RESULT_N:.+]] = llvm.extractvalue %[[WITH_N]][1]
// CHECK:         return %[[RESULT_N]] : i32
func.func @layout_algebra_right_inverse_zero_stride(
    %src: !cute.layout<"(?,4):(0,1)">) -> i32 {
  %r = cute.right_inverse(%src)
         : (!cute.layout<"(?,4):(0,1)">) -> !cute.layout<"4:?">
  %n = cute.get_scalars<{only_dynamic}> (%r) : !cute.layout<"4:?">
  return %n : i32
}

// -----

// Arithmetic — tuple_sub on dynamic operands, then print.
// CHECK-LABEL: func.func @arith_tuple_sub_print
// CHECK-NOT:     cute.
// CHECK:         arith.subi
// CHECK:         llvm.call @printf
// CHECK:         return
func.func @arith_tuple_sub_print(%a: !cute.int_tuple<"(?,?)">) {
  %b = cute.static : !cute.int_tuple<"(1,2)">
  %r = cute.tuple_sub(%a, %b)
         : (!cute.int_tuple<"(?,?)">, !cute.int_tuple<"(1,2)">)
        -> !cute.int_tuple<"(?,?)">
  cute.print(%r) : !cute.int_tuple<"(?,?)">
  return
}

// -----

// SizeIndex — cute.size on a static layout.
// CHECK-LABEL: func.func @sizeindex_size
// CHECK-NOT:     cute.
// CHECK:         return
func.func @sizeindex_size(%a: !cute.layout<"(2,3,4):(1,2,6)">)
    -> !cute.int_tuple<"24"> {
  %r = cute.size(%a)
         : (!cute.layout<"(2,3,4):(1,2,6)">) -> !cute.int_tuple<"24">
  return %r : !cute.int_tuple<"24">
}

// -----

// SizeIndex — cute.layout_eval over a static composed_layout with a dynamic
// coord (swizzle inner).
// CHECK-LABEL: func.func @sizeindex_layout_eval_composed_dynamic
// CHECK-NOT:     cute.
// CHECK:         return
func.func @sizeindex_layout_eval_composed_dynamic(
    %c: !cute.coord<"?">,
    %l: !cute.composed_layout<"S<1,4,3> o 0 o (32):(32)">)
    -> !cute.int_tuple<"?"> {
  %r = cute.layout_eval(%c, %l)
         : (!cute.coord<"?">,
            !cute.composed_layout<"S<1,4,3> o 0 o (32):(32)">)
        -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}

// -----

// TilingPartitioningProducts — logical_divide with a dynamic source.
// CHECK-LABEL: func.func @tiling_logical_divide
// CHECK-NOT:     cute.
// CHECK:         return
func.func @tiling_logical_divide(%a: !cute.layout<"(?,8):(8,1)">,
                                   %b: !cute.shape<"(3,4)">)
    -> !cute.layout<"((3,?),(4,2)):((8,24),(1,4))"> {
  %r = cute.logical_divide(%a, %b)
         : (!cute.layout<"(?,8):(8,1)">, !cute.shape<"(3,4)">)
        -> !cute.layout<"((3,?),(4,2)):((8,24),(1,4))">
  return %r : !cute.layout<"((3,?),(4,2)):((8,24),(1,4))">
}

//===----------------------------------------------------------------------===//
// GPU pipeline
//===----------------------------------------------------------------------===//

// Print inside a `gpu.func` lowers to `gpu.printf`.
// CHECK-LABEL: gpu.module @kernels
// CHECK-LABEL: gpu.func @kernel_print
// CHECK-NOT:     cute.
// CHECK:         gpu.printf
// CHECK-NOT:     llvm.call @printf
// CHECK:         gpu.return
gpu.module @kernels {
  gpu.func @kernel_print(%a: i32) kernel {
    %s = cute.make_shape (%a) : (i32) -> !cute.shape<"(?,4)">
    cute.print(%s) : !cute.shape<"(?,4)">
    gpu.return
  }
}
