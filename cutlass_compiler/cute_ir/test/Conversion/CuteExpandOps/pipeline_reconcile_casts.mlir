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

// RUN: cute-opt -cute-expand-ops --split-input-file %s \
// RUN:   | cute-opt -reconcile-unrealized-casts --split-input-file \
// RUN:   | FileCheck %s --check-prefix=AFTER-RECONCILE

// `cute-expand-ops` is a *partial* dialect conversion with an identity
// `TypeConverter`. The framework's source/target materializers would
// wrap rewritten SSA values in same-type `unrealized_conversion_cast`s
// were it not for the `nullify_dynamics` step in the cute attribute
// builders (see `CuteAttrs.td`), which collapses parser-built and
// programmatically-built attrs of identical textual form to the same
// MLIR instance — so the framework sees source == target and emits
// no cast.
//
// Two `cute-opt` invocations are kept in the RUN line for safety: if a
// future expand pattern ever produces a layout whose attr internal
// state differs from the parser-built form (escaping the nullify
// canonicalization), the framework will reintroduce casts, and a
// separate `cute-opt` invocation is needed to legalize them — the
// `ConversionPatternRewriter`'s materializer-cast bookkeeping doesn't
// carry over across a re-parse. This mirrors how downstream pipelines
// (host module + a separate finalization pass) compose these passes.

// -----

// AdvancedConstructors — make_layout_like dynamic.
// AFTER-RECONCILE-LABEL: func.func @make_layout_like_dynamic
// AFTER-RECONCILE-NOT:     unrealized_conversion_cast
// AFTER-RECONCILE:         return
//
func.func @make_layout_like_dynamic(%a: !cute.layout<"(?,4):(?,1)">)
    -> !cute.layout<"(?,4):(4,1)"> {
  %r = cute.make_layout_like(%a)
         : !cute.layout<"(?,4):(?,1)"> -> !cute.layout<"(?,4):(4,1)">
  return %r : !cute.layout<"(?,4):(4,1)">
}

// -----

// Accessors — get_stride dynamic.
// AFTER-RECONCILE-LABEL: func.func @get_stride_dynamic
// AFTER-RECONCILE-NOT:     unrealized_conversion_cast
// AFTER-RECONCILE:         return
//
func.func @get_stride_dynamic(%a: !cute.layout<"(2,3):(1,?)">)
    -> !cute.stride<"(1,?)"> {
  %r = cute.get_stride(%a)
         : !cute.layout<"(2,3):(1,?)"> -> !cute.stride<"(1,?)">
  return %r : !cute.stride<"(1,?)">
}

// -----

// LayoutAlgebra — coalesce dynamic.
// AFTER-RECONCILE-LABEL: func.func @coalesce_dynamic
// AFTER-RECONCILE-NOT:     unrealized_conversion_cast
// AFTER-RECONCILE:         return
//
func.func @coalesce_dynamic(%a: !cute.layout<"(?):(?)">)
    -> !cute.layout<"?:?"> {
  %r = cute.coalesce(%a)
         : (!cute.layout<"(?):(?)">) -> !cute.layout<"?:?">
  return %r : !cute.layout<"?:?">
}

// -----

// SizeIndex — size dynamic.
// AFTER-RECONCILE-LABEL: func.func @size_dynamic
// AFTER-RECONCILE-NOT:     unrealized_conversion_cast
// AFTER-RECONCILE:         return
//
func.func @size_dynamic(%a: !cute.layout<"(2,?,4):(1,?,?)">)
    -> !cute.int_tuple<"?"> {
  %r = cute.size(%a)
         : (!cute.layout<"(2,?,4):(1,?,?)">) -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}

// -----

// Arithmetic — tuple_add dynamic. Routes through `cute.make_shape` and a
// same-type cast back to the op's `int_tuple` result (kind-preserving
// `cg::arith_tuple_sum` returns a shape).
// AFTER-RECONCILE-LABEL: func.func @tuple_add_dynamic
// AFTER-RECONCILE-NOT:     unrealized_conversion_cast
// AFTER-RECONCILE:         return
//
func.func @tuple_add_dynamic(%a: !cute.shape<"(?,?)">,
                              %b: !cute.shape<"(1,2)">)
    -> !cute.shape<"(?,?)"> {
  %r = cute.tuple_add(%a, %b)
         : (!cute.shape<"(?,?)">, !cute.shape<"(1,2)">) -> !cute.shape<"(?,?)">
  return %r : !cute.shape<"(?,?)">
}

// -----

// TilingPartitioningProducts — logical_divide dynamic with shape tiler.
// AFTER-RECONCILE-LABEL: func.func @logical_divide_dynamic
// AFTER-RECONCILE-NOT:     unrealized_conversion_cast
// AFTER-RECONCILE:         return
//
func.func @logical_divide_dynamic(%a: !cute.layout<"(?,8):(8,1)">,
                                    %b: !cute.shape<"(3,4)">)
    -> !cute.layout<"((3,?),(4,2)):((8,24),(1,4))"> {
  %r = cute.logical_divide(%a, %b)
         : (!cute.layout<"(?,8):(8,1)">, !cute.shape<"(3,4)">)
        -> !cute.layout<"((3,?),(4,2)):((8,24),(1,4))">
  return %r : !cute.layout<"((3,?),(4,2)):((8,24),(1,4))">
}

// -----

// ComposedLayout result — verifies the `allowDecay=false` rebuild path
// also reconciles cleanly.
// AFTER-RECONCILE-LABEL: func.func @composed_layout_dynamic
// AFTER-RECONCILE-NOT:     unrealized_conversion_cast
// AFTER-RECONCILE:         return
//
func.func @composed_layout_dynamic(
    %a: !cute.composed_layout<"S<3,5,4> o 0 o (?,?):(?,?)">)
    -> !cute.int_tuple<"?"> {
  %r = cute.cosize(%a)
         : (!cute.composed_layout<"S<3,5,4> o 0 o (?,?):(?,?)">)
        -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}

// -----

// Multi-op chain — a dynamic value flowing through two ops should also
// reconcile cleanly. The cast emitted between `cute.size` and `cute.equal`
// is removed.
// AFTER-RECONCILE-LABEL: func.func @op_chain
// AFTER-RECONCILE-NOT:     unrealized_conversion_cast
// AFTER-RECONCILE:         return
//
func.func @op_chain(%a: !cute.layout<"(?,4):(1,?)">,
                     %b: !cute.int_tuple<"4">) -> i1 {
  %sz = cute.size(%a) : (!cute.layout<"(?,4):(1,?)">) -> !cute.int_tuple<"?">
  %r = cute.equal(%sz, %b)
         : (!cute.int_tuple<"?">, !cute.int_tuple<"4">) -> i1
  return %r : i1
}

// -----

// AdvancedConstructors — make_identity_layout dynamic. Result has
// basis-stride leaves (`1@0`, `1@1`); reconcile should still clean up.
// AFTER-RECONCILE-LABEL: func.func @make_identity_layout_dynamic
// AFTER-RECONCILE-NOT:     unrealized_conversion_cast
// AFTER-RECONCILE:         return
//
func.func @make_identity_layout_dynamic(%s: !cute.shape<"(?,4)">)
    -> !cute.layout<"(?,4):(1@0,1@1)"> {
  %r = cute.make_identity_layout(%s)
         : !cute.shape<"(?,4)"> -> !cute.layout<"(?,4):(1@0,1@1)">
  return %r : !cute.layout<"(?,4):(1@0,1@1)">
}

// -----

// Accessors — get_shape dynamic.
// AFTER-RECONCILE-LABEL: func.func @get_shape_dynamic
// AFTER-RECONCILE-NOT:     unrealized_conversion_cast
// AFTER-RECONCILE:         return
//
func.func @get_shape_dynamic(%a: !cute.layout<"(?,4):(1,?)">)
    -> !cute.shape<"(?,4)"> {
  %r = cute.get_shape(%a)
         : !cute.layout<"(?,4):(1,?)"> -> !cute.shape<"(?,4)">
  return %r : !cute.shape<"(?,4)">
}

// -----

// Accessors — to_int_tuple dynamic. The op is kind-changing (shape →
// int_tuple); the cast emitted here covers the kind transition.
// AFTER-RECONCILE-LABEL: func.func @to_int_tuple_dynamic
// AFTER-RECONCILE-NOT:     unrealized_conversion_cast
// AFTER-RECONCILE:         return
//
func.func @to_int_tuple_dynamic(%s: !cute.shape<"(?,4)">)
    -> !cute.int_tuple<"(?,4)"> {
  %r = cute.to_int_tuple(%s)
         : !cute.shape<"(?,4)"> -> !cute.int_tuple<"(?,4)">
  return %r : !cute.int_tuple<"(?,4)">
}

// -----

// Accessors — composed_get_offset dynamic. The result kind (`int_tuple`)
// differs from the input kind (`composed_layout`).
// AFTER-RECONCILE-LABEL: func.func @composed_get_offset_dynamic
// AFTER-RECONCILE-NOT:     unrealized_conversion_cast
// AFTER-RECONCILE:         return
//
func.func @composed_get_offset_dynamic(
    %c: !cute.composed_layout<"(4,5):(1,4) o ? o (2,3):(1,2)">)
    -> !cute.int_tuple<"?"> {
  %r = cute.composed_get_offset(%c)
         : !cute.composed_layout<"(4,5):(1,4) o ? o (2,3):(1,2)">
        -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}

// -----

// SizeIndex — layout_eval over a composed_layout. Result kind (`int_tuple`)
// differs from operand #1 kind (`composed_layout`); the explicit 3-step
// expansion threads dynamics through both inner and outer layouts.
// AFTER-RECONCILE-LABEL: func.func @layout_eval_composed_dynamic
// AFTER-RECONCILE-NOT:     unrealized_conversion_cast
// AFTER-RECONCILE:         return
//
func.func @layout_eval_composed_dynamic(
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

// LayoutAlgebra — composition dynamic. Threads stride values through
// `(?,?):(?,?) ∘ 4:1`.
// AFTER-RECONCILE-LABEL: func.func @composition_dynamic
// AFTER-RECONCILE-NOT:     unrealized_conversion_cast
// AFTER-RECONCILE:         return
//
func.func @composition_dynamic(%a: !cute.layout<"?:?">,
                                 %b: !cute.layout<"4:1">)
    -> !cute.layout<"4:?"> {
  %r = cute.composition(%a, %b)
         : (!cute.layout<"?:?">, !cute.layout<"4:1">) -> !cute.layout<"4:?">
  return %r : !cute.layout<"4:?">
}

// -----

// LayoutAlgebra — recast_layout composed_layout dynamic. Exercises the
// swizzle-bit rescaling path with an `allowDecay=false` rebuild.
// AFTER-RECONCILE-LABEL: func.func @recast_layout_composed_dynamic
// AFTER-RECONCILE-NOT:     unrealized_conversion_cast
// AFTER-RECONCILE:         return
//
func.func @recast_layout_composed_dynamic(
    %a: !cute.composed_layout<"S<3,5,4> o 0 o (32,?):(1,?)">)
    -> !cute.composed_layout<"S<3,3,4> o 0 o (8,?):(1,?)"> {
  %r = cute.recast_layout<32, 8>(%a)
         : !cute.composed_layout<"S<3,5,4> o 0 o (32,?):(1,?)">
        -> !cute.composed_layout<"S<3,3,4> o 0 o (8,?):(1,?)">
  return %r : !cute.composed_layout<"S<3,3,4> o 0 o (8,?):(1,?)">
}

// -----

// LayoutAlgebra — slice dynamic.
// AFTER-RECONCILE-LABEL: func.func @slice_dynamic
// AFTER-RECONCILE-NOT:     unrealized_conversion_cast
// AFTER-RECONCILE:         return
//
func.func @slice_dynamic(%a: !cute.layout<"(2,?,4):(1,?,?)">,
                          %c: !cute.coord<"(0,_,_)">)
    -> !cute.layout<"(?,4):(?,?)"> {
  %r = cute.slice(%a, %c)
         : !cute.layout<"(2,?,4):(1,?,?)">, !cute.coord<"(0,_,_)">
  return %r : !cute.layout<"(?,4):(?,?)">
}

// -----

// SizeIndex — cosize dynamic. Uses `math.absi` on stride leaves.
// AFTER-RECONCILE-LABEL: func.func @cosize_dynamic
// AFTER-RECONCILE-NOT:     unrealized_conversion_cast
// AFTER-RECONCILE:         return
//
func.func @cosize_dynamic(%a: !cute.layout<"(?,?,?):(?,?,?)">)
    -> !cute.int_tuple<"?"> {
  %r = cute.cosize(%a)
         : (!cute.layout<"(?,?,?):(?,?,?)">) -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}

// -----

// SizeIndex — append_to_rank dynamic with composed_layout (allowDecay=false
// path).
// AFTER-RECONCILE-LABEL: func.func @append_to_rank_composed_dynamic
// AFTER-RECONCILE-NOT:     unrealized_conversion_cast
// AFTER-RECONCILE:         return
//
func.func @append_to_rank_composed_dynamic(
    %in: !cute.composed_layout<"(4,5):(1,4) o 0 o (?,3):(?,4)">,
    %e: !cute.layout<"1:0">)
    -> !cute.composed_layout<"(4,5):(1,4) o 0 o (?,3,1):(?,4,0)"> {
  %r = cute.append_to_rank<3>(%in, %e)
         : !cute.composed_layout<"(4,5):(1,4) o 0 o (?,3):(?,4)">,
           !cute.layout<"1:0">
  return %r : !cute.composed_layout<"(4,5):(1,4) o 0 o (?,3,1):(?,4,0)">
}

// -----

// Arithmetic — ceil_div dynamic with shape tiler crossing kinds (input
// is int_tuple, tiler is shape, result is int_tuple).
// AFTER-RECONCILE-LABEL: func.func @ceil_div_cross_kind_dynamic
// AFTER-RECONCILE-NOT:     unrealized_conversion_cast
// AFTER-RECONCILE:         return
//
func.func @ceil_div_cross_kind_dynamic(%a: !cute.int_tuple<"(?,?)">,
                                         %b: !cute.shape<"(2,3)">)
    -> !cute.int_tuple<"(?,?)"> {
  %r = cute.ceil_div(%a, %b)
         : (!cute.int_tuple<"(?,?)">, !cute.shape<"(2,3)">)
        -> !cute.int_tuple<"(?,?)">
  return %r : !cute.int_tuple<"(?,?)">
}

// -----

// TilingPartitioningProducts — tiled_product on a static
// composed_layout. (The 6 product ops reject any non-static input —
// see TilingPartitioningProducts/logical_product_errors.mlir for the
// rejection. Folds to `cute.static` at lowering time.)
// AFTER-RECONCILE-LABEL: func.func @tiled_product_composed_static
// AFTER-RECONCILE-NOT:     unrealized_conversion_cast
// AFTER-RECONCILE:         return
//
func.func @tiled_product_composed_static(
    %a: !cute.composed_layout<"S<3,4,3> o 0 o (5,4):(4,1)">,
    %b: !cute.layout<"(2,5):(1,2)">)
    -> !cute.composed_layout<"S<3,4,3> o 0 o ((5,4),2,5):((4,1),20,40)"> {
  %r = cute.tiled_product(%a, %b)
         : (!cute.composed_layout<"S<3,4,3> o 0 o (5,4):(4,1)">,
            !cute.layout<"(2,5):(1,2)">)
        -> !cute.composed_layout<"S<3,4,3> o 0 o ((5,4),2,5):((4,1),20,40)">
  return %r : !cute.composed_layout<"S<3,4,3> o 0 o ((5,4),2,5):((4,1),20,40)">
}

// -----

// Long-chain test — four ops fed into each other. Each boundary emits a
// cast post-expand-ops; reconcile must clean every one even when they
// stack across multiple producers.
// AFTER-RECONCILE-LABEL: func.func @long_chain
// AFTER-RECONCILE-NOT:     unrealized_conversion_cast
// AFTER-RECONCILE:         return
//
func.func @long_chain(%a: !cute.layout<"(?,8):(1,?)">,
                       %b: !cute.shape<"(3,4)">) -> !cute.int_tuple<"?"> {
  %d = cute.logical_divide(%a, %b)
         : (!cute.layout<"(?,8):(1,?)">, !cute.shape<"(3,4)">)
        -> !cute.layout<"((3,?),(4,2)):((1,3),(?,?))">
  %co = cute.coalesce(%d)
         : (!cute.layout<"((3,?),(4,2)):((1,3),(?,?))">)
        -> !cute.layout<"(3,?,4,2):(1,3,?,?)">
  %sz = cute.size(%co)
         : (!cute.layout<"(3,?,4,2):(1,3,?,?)">) -> !cute.int_tuple<"?">
  %e = cute.tuple_add(%sz, %sz)
         : (!cute.int_tuple<"?">, !cute.int_tuple<"?">)
        -> !cute.int_tuple<"?">
  return %e : !cute.int_tuple<"?">
}
