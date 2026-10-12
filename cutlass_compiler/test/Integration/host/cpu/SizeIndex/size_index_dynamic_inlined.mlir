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
// Dynamic SizeIndex, ops inlined in @main; static leaves fold through -base-prepare.
//
// RUN: cutlass-compiler -cute-fold-static -cute-expand-ops -cute-to-base \
// RUN:     -base-prepare %s | FileCheck --check-prefix=POST-PREP %s
//
// After -base-prepare only arith.constant may remain:
// POST-PREP-NOT: arith.{{[^c]}}
// POST-PREP-NOT: arith.c{{[^o]}}

// CHECK: 77
// CHECK: 12
// CHECK: 7
// CHECK: 208
// crd2idx: dyn coord (2,3) on dyn shape (?,8) x=4 → 2 + 3*4 = 14.
// CHECK: 14
// CHECK: (3,2)
// CHECK: (2,2)
// increment_coord wrap (dyn coord (3,2) + static shape (4,8)): runtime
// carry rolls mode 0 over → (0,3).
// CHECK: (0,3)
// increment_coord hierarchical (dyn coord (1,(2,0)) + static shape
// (4,(3,8))): nested carry walks all three modes → (2,(2,0)).
// CHECK: (2,(2,0))
// CHECK: (5,8,1,1)
// CHECK: (1,1,6,8)
// append_to_rank / prepend_to_rank on dyn layout (make_layout codegen end-to-end).
// CHECK: (5,8,1,1):(1,7,0,0)
// CHECK: (1,1,5,8):(0,0,1,7)
// append_to_rank / prepend_to_rank on dyn composed (make_composed_layout codegen).
// CHECK: S<3,4,3> o 0 o (5,3,1,1):(7,1,0,0)
// CHECK: S<3,4,3> o 0 o (1,1,5,3):(0,0,7,1)
// CHECK: 15
// CHECK: (3,10)

func.func @main() {
  // size: (?,7) with x=11 → 77
  %x11 = arith.constant 11 : i32
  %s1 = cute.make_shape (%x11) : (i32) -> !cute.shape<"(?,7)">
  %r1 = cute.size(%s1) : (!cute.shape<"(?,7)">) -> !cute.int_tuple<"?">
  cute.print(%r1) : !cute.int_tuple<"?">

  // cosize: (?,3):(1,?) with x=4 → 12
  %x4 = arith.constant 4 : i32
  %s2 = cute.make_shape (%x4) : (i32) -> !cute.shape<"(?,3)">
  %l2_stride = cute.make_stride (%x4) : (i32) -> !cute.stride<"(1,?)">
  %l2 = cute.make_layout (%s2, %l2_stride) : (!cute.shape<"(?,3)">, !cute.stride<"(1,?)">) -> !cute.layout<"(?,3):(1,?)">
  %r2 = cute.cosize(%l2) : (!cute.layout<"(?,3):(1,?)">) -> !cute.int_tuple<"?">
  cute.print(%r2) : !cute.int_tuple<"?">

  // layout_eval: dyn coord (3,1) + dyn layout (?,8):(1,?) x=4 → 3+1*4 = 7
  %x3 = arith.constant 3 : i32
  %x1 = arith.constant 1 : i32
  %crd3 = cute.make_coord (%x3, %x1) : (i32, i32) -> !cute.coord<"(?,?)">
  %sh3 = cute.make_shape (%x4) : (i32) -> !cute.shape<"(?,8)">
  %ll3_stride = cute.make_stride (%x4) : (i32) -> !cute.stride<"(1,?)">
  %ll3 = cute.make_layout (%sh3, %ll3_stride) : (!cute.shape<"(?,8)">, !cute.stride<"(1,?)">) -> !cute.layout<"(?,8):(1,?)">
  %r3 = cute.layout_eval(%crd3, %ll3)
       : (!cute.coord<"(?,?)">, !cute.layout<"(?,8):(1,?)">) -> !cute.int_tuple<"?">
  cute.print(%r3) : !cute.int_tuple<"?">

  // layout_eval over composed_layout: dyn coord 6 on `S<1,4,3> o 0 o (32):(32)` →
  // 6*32 = 192; swizzle(192) = 192 ^ ((192 & 128) >> 3) = 208. Exercises the
  // 3-step decomposition under a dynamic coordinate.
  %x6c = arith.constant 6 : i32
  %crd3c = cute.make_coord (%x6c) : (i32) -> !cute.coord<"?">
  %cl3 = cute.static : !cute.composed_layout<"S<1,4,3> o 0 o (32):(32)">
  %r3c = cute.layout_eval(%crd3c, %cl3)
       : (!cute.coord<"?">,
          !cute.composed_layout<"S<1,4,3> o 0 o (32):(32)">)
      -> !cute.int_tuple<"?">
  cute.print(%r3c) : !cute.int_tuple<"?">

  // crd2idx: dyn coord (2,3) + dyn shape (?,8) x=4 → 2 + 3*4 = 14.
  %x2p = arith.constant 2 : i32
  %x3p = arith.constant 3 : i32
  %crd3p = cute.make_coord (%x2p, %x3p) : (i32, i32) -> !cute.coord<"(?,?)">
  %sh3p = cute.make_shape (%x4) : (i32) -> !cute.shape<"(?,8)">
  %r3p = cute.crd2idx(%crd3p, %sh3p)
       : (!cute.coord<"(?,?)">, !cute.shape<"(?,8)">) -> !cute.int_tuple<"?">
  cute.print(%r3p) : !cute.int_tuple<"?">

  // idx2crd: dyn idx 11 + static shape (4,8) → coord (3,2) (col-major, mode 0 = stride 1)
  %x_idx = arith.constant 11 : i32
  %idx4 = cute.make_int_tuple (%x_idx) : (i32) -> !cute.int_tuple<"?">
  %s4 = cute.static : !cute.shape<"(4,8)">
  %r4 = cute.idx2crd(%idx4, %s4)
       : (!cute.int_tuple<"?">, !cute.shape<"(4,8)">) -> !cute.coord<"(?,?)">
  cute.print(%r4) : !cute.coord<"(?,?)">

  // increment_coord: dyn coord (1,2) + static shape (4,8) → (2,2)
  %x2 = arith.constant 2 : i32
  %crd5 = cute.make_coord (%x1, %x2) : (i32, i32) -> !cute.coord<"(?,?)">
  %s5 = cute.static : !cute.shape<"(4,8)">
  %r5 = cute.increment_coord(%crd5, %s5)
       : (!cute.coord<"(?,?)">, !cute.shape<"(4,8)">) -> !cute.coord<"(?,?)">
  cute.print(%r5) : !cute.coord<"(?,?)">

  // increment_coord wrap: dyn coord (3,2) + static shape (4,8) →
  // runtime print (0,3). Exercises the runtime carry path where mode 0
  // exceeds its extent and rolls over. Reuses %x3 from above (value 3).
  %crd5w = cute.make_coord (%x3, %x2) : (i32, i32) -> !cute.coord<"(?,?)">
  %r5w = cute.increment_coord(%crd5w, %s5)
       : (!cute.coord<"(?,?)">, !cute.shape<"(4,8)">) -> !cute.coord<"(?,?)">
  cute.print(%r5w) : !cute.coord<"(?,?)">

  // increment_coord hierarchical: dyn coord (1,(2,0)) + static shape
  // (4,(3,8)) → runtime print (2,(2,0)). Exercises the nested carry
  // chain (rank-3 flat result with `(?,(?,?))` profile).
  %x0c = arith.constant 0 : i32
  %crd5h = cute.make_coord (%x1, %x2, %x0c)
       : (i32, i32, i32) -> !cute.coord<"(?,(?,?))">
  %s5h = cute.static : !cute.shape<"(4,(3,8))">
  %r5h = cute.increment_coord(%crd5h, %s5h)
       : (!cute.coord<"(?,(?,?))">, !cute.shape<"(4,(3,8))">) -> !cute.coord<"(?,(?,?))">
  cute.print(%r5h) : !cute.coord<"(?,(?,?))">

  // append_to_rank<4>: dyn (?,8) value 5 + static 1 → (5,8,1,1)
  %x5 = arith.constant 5 : i32
  %s6 = cute.make_shape (%x5) : (i32) -> !cute.shape<"(?,8)">
  %e6 = cute.static : !cute.shape<"1">
  %r6 = cute.append_to_rank<4>(%s6, %e6) : !cute.shape<"(?,8)">, !cute.shape<"1">
  cute.print(%r6) : !cute.shape<"(?,8,1,1)">

  // prepend_to_rank<4>: dyn (?,8) value 6 + static 1 → (1,1,6,8)
  %x6 = arith.constant 6 : i32
  %s7 = cute.make_shape (%x6) : (i32) -> !cute.shape<"(?,8)">
  %r7 = cute.prepend_to_rank<4>(%s7, %e6) : !cute.shape<"(?,8)">, !cute.shape<"1">
  cute.print(%r7) : !cute.shape<"(1,1,?,8)">

  // append_to_rank on a dyn layout: input is (?,8):(1,?), pad with 1:0 to
  // rank 4. The dyn extent (= 5) and dyn stride (= 7 below) survive →
  // result (5,8,1,1):(1,7,0,0). Exercises the make_layout rebuild end-to-end.
  %x7 = arith.constant 7 : i32
  %sl = cute.make_shape (%x5) : (i32) -> !cute.shape<"(?,8)">
  %tl = cute.make_stride (%x7) : (i32) -> !cute.stride<"(1,?)">
  %l_in = cute.make_layout (%sl, %tl)
        : (!cute.shape<"(?,8)">, !cute.stride<"(1,?)">) -> !cute.layout<"(?,8):(1,?)">
  %l_e = cute.static : !cute.layout<"1:0">
  %rl = cute.append_to_rank<4>(%l_in, %l_e)
        : !cute.layout<"(?,8):(1,?)">, !cute.layout<"1:0">
  cute.print(%rl) : !cute.layout<"(?,8,1,1):(1,?,0,0)">

  // prepend_to_rank on the same dyn layout: result (1,1,5,8):(0,0,1,7).
  %rlp = cute.prepend_to_rank<4>(%l_in, %l_e)
         : !cute.layout<"(?,8):(1,?)">, !cute.layout<"1:0">
  cute.print(%rlp) : !cute.layout<"(1,1,?,8):(0,0,1,?)">

  // append_to_rank on a dyn composed layout: swizzle + dyn B with both
  // dyn extent (= 5) and dyn stride (= 7) in B. Pad with 1:0 to rank 4.
  // Result swizzle preserved, B = (5,3,1,1):(7,1,0,0). Exercises
  // make_composed_layout codegen end-to-end.
  %co_sw = cute.static : !cute.swizzle<"S<3,4,3>">
  %co_off = cute.static : !cute.int_tuple<"0">
  %co_sh = cute.make_shape (%x5) : (i32) -> !cute.shape<"(?,3)">
  %co_st = cute.make_stride (%x7) : (i32) -> !cute.stride<"(?,1)">
  %co_b = cute.make_layout (%co_sh, %co_st)
        : (!cute.shape<"(?,3)">, !cute.stride<"(?,1)">) -> !cute.layout<"(?,3):(?,1)">
  %co_in = cute.make_composed_layout(%co_sw, %co_off, %co_b)
        : (!cute.swizzle<"S<3,4,3>">, !cute.int_tuple<"0">,
           !cute.layout<"(?,3):(?,1)">)
       -> !cute.composed_layout<"S<3,4,3> o 0 o (?,3):(?,1)">
  %r_co = cute.append_to_rank<4>(%co_in, %l_e)
        : !cute.composed_layout<"S<3,4,3> o 0 o (?,3):(?,1)">,
          !cute.layout<"1:0">
  cute.print(%r_co) : !cute.composed_layout<"S<3,4,3> o 0 o (?,3,1,1):(?,1,0,0)">

  // prepend_to_rank on the same dyn composed: B = (1,1,5,3):(0,0,7,1).
  %r_cop = cute.prepend_to_rank<4>(%co_in, %l_e)
         : !cute.composed_layout<"S<3,4,3> o 0 o (?,3):(?,1)">,
           !cute.layout<"1:0">
  cute.print(%r_cop) : !cute.composed_layout<"S<3,4,3> o 0 o (1,1,?,3):(0,0,?,1)">

  // tuple_product: dyn (?,?) values (3,5) → 15
  %t8 = cute.make_int_tuple (%x3, %x5) : (i32, i32) -> !cute.int_tuple<"(?,?)">
  %r8 = cute.tuple_product(%t8)
       : (!cute.int_tuple<"(?,?)">) -> !cute.int_tuple<"?">
  cute.print(%r8) : !cute.int_tuple<"?">

  // tuple_product_each: dyn (?,(?,?)) values (3,(2,5)) → (3,10)
  %t9 = cute.make_int_tuple (%x3, %x2, %x5) : (i32, i32, i32) -> !cute.int_tuple<"(?,(?,?))">
  %r9 = cute.tuple_product_each(%t9)
       : (!cute.int_tuple<"(?,(?,?))">) -> !cute.int_tuple<"(?,?)">
  cute.print(%r9) : !cute.int_tuple<"(?,?)">

  return
}
