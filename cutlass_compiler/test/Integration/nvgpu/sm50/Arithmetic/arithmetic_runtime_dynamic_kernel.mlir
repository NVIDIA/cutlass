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

// REQUIRES: cutlass_compiler_device
// RUN: env CUTLASS_COMPILER_TEST_BASE=0 %cutlass-compiler-run-device %s | FileCheck %s
//
// Runtime-dynamic Arithmetic kernel; dyn leaves cross host→device via gpu.launch_func args.
// elem_less and equal produce i1, extended via arith.extui for gpu.printf.

// CHECK: (4,6)
// CHECK: (5,7,3)
// CHECK: ((5,7),9)
// CHECK: (7,11)
// CHECK: (7,10)
// CHECK: (9,6,3)
// CHECK: ((9,13),2)
// CHECK: (7,11)
// CHECK: (4,5)
// CHECK: (1,1,3)
// CHECK: ((4,2),(2,2))
// CHECK: (4,3)
// CHECK: (3,3,6)
// CHECK: (2,8)
// CHECK: 1
// CHECK: 0
// CHECK-COUNT-4: 1

module attributes {gpu.container_module} {
  llvm.func @getenv(!llvm.ptr) -> !llvm.ptr
  llvm.func @atoi(!llvm.ptr) -> i32

  llvm.mlir.global internal constant @cutlass_compiler_env_name("CUTLASS_COMPILER_TEST_BASE\00") {addr_space = 0 : i32}

  func.func private @read_base() -> i32 {
    %name_addr = llvm.mlir.addressof @cutlass_compiler_env_name : !llvm.ptr
    %name = llvm.getelementptr %name_addr[0, 0]
          : (!llvm.ptr) -> !llvm.ptr, !llvm.array<15 x i8>
    %env = llvm.call @getenv(%name) : (!llvm.ptr) -> !llvm.ptr
    %v = llvm.call @atoi(%env) : (!llvm.ptr) -> i32
    return %v : i32
  }

  gpu.module @kernel {
    gpu.func @print_all(%base: i32) kernel {
      %tx = gpu.thread_id x
      %c0_idx = arith.constant 0 : index
      %is_zero = arith.cmpi eq, %tx, %c0_idx : index
      scf.if %is_zero {
        // tuple_add: (3,4) + (1,2) → (4,6)
        %o3 = arith.constant 3 : i32
        %o4 = arith.constant 4 : i32
        %o1 = arith.constant 1 : i32
        %o2 = arith.constant 2 : i32
        %x3 = arith.addi %base, %o3 : i32
        %x4 = arith.addi %base, %o4 : i32
        %x1 = arith.addi %base, %o1 : i32
        %x2 = arith.addi %base, %o2 : i32
        %t1a = cute.make_int_tuple (%x3, %x4) : (i32, i32) -> !cute.int_tuple<"(?,?)">
        %t1b = cute.make_int_tuple (%x1, %x2) : (i32, i32) -> !cute.int_tuple<"(?,?)">
        %r1 = cute.tuple_add(%t1a, %t1b)
            : (!cute.int_tuple<"(?,?)">, !cute.int_tuple<"(?,?)">)
           -> !cute.int_tuple<"(?,?)">
        cute.print(%r1) : !cute.int_tuple<"(?,?)">

        // tuple_add rank-mismatch: (1,2,3) + (4,5) → (5,7,3).
        %oadd5 = arith.constant 5 : i32
        %xadd5 = arith.addi %base, %oadd5 : i32
        %t1am = cute.make_int_tuple (%x1, %x2, %x3)
            : (i32, i32, i32) -> !cute.int_tuple<"(?,?,?)">
        %t1bm = cute.make_int_tuple (%x4, %xadd5)
            : (i32, i32) -> !cute.int_tuple<"(?,?)">
        %r1m = cute.tuple_add(%t1am, %t1bm)
            : (!cute.int_tuple<"(?,?,?)">, !cute.int_tuple<"(?,?)">)
           -> !cute.int_tuple<"(?,?,?)">
        cute.print(%r1m) : !cute.int_tuple<"(?,?,?)">

        // tuple_add nested: ((1,2),3) + ((4,5),6) → ((5,7),9).
        %oadd6 = arith.constant 6 : i32
        %xadd6 = arith.addi %base, %oadd6 : i32
        %t1an = cute.make_int_tuple (%x1, %x2, %x3)
            : (i32, i32, i32) -> !cute.int_tuple<"((?,?),?)">
        %t1bn = cute.make_int_tuple (%x4, %xadd5, %xadd6)
            : (i32, i32, i32) -> !cute.int_tuple<"((?,?),?)">
        %r1n = cute.tuple_add(%t1an, %t1bn)
            : (!cute.int_tuple<"((?,?),?)">, !cute.int_tuple<"((?,?),?)">)
           -> !cute.int_tuple<"((?,?),?)">
        cute.print(%r1n) : !cute.int_tuple<"((?,?),?)">

        // tuple_add zero identity with dyn lhs: (7,11) + 0 → (7,11).
        %oz7 = arith.constant 7 : i32
        %oz11 = arith.constant 11 : i32
        %xz7 = arith.addi %base, %oz7 : i32
        %xz11 = arith.addi %base, %oz11 : i32
        %t1az = cute.make_int_tuple (%xz7, %xz11)
            : (i32, i32) -> !cute.int_tuple<"(?,?)">
        %t1bz = cute.static : !cute.int_tuple<"0">
        %r1z = cute.tuple_add(%t1az, %t1bz)
            : (!cute.int_tuple<"(?,?)">, !cute.int_tuple<"0">)
           -> !cute.int_tuple<"(?,?)">
        cute.print(%r1z) : !cute.int_tuple<"(?,?)">

        // tuple_sub: (10,15) - (3,5) → (7,10)
        %o10 = arith.constant 10 : i32
        %o15 = arith.constant 15 : i32
        %o5 = arith.constant 5 : i32
        %x10 = arith.addi %base, %o10 : i32
        %x15 = arith.addi %base, %o15 : i32
        %xs3 = arith.addi %base, %o3 : i32
        %x5 = arith.addi %base, %o5 : i32
        %t2a = cute.make_int_tuple (%x10, %x15) : (i32, i32) -> !cute.int_tuple<"(?,?)">
        %t2b = cute.make_int_tuple (%xs3, %x5) : (i32, i32) -> !cute.int_tuple<"(?,?)">
        %r2 = cute.tuple_sub(%t2a, %t2b)
            : (!cute.int_tuple<"(?,?)">, !cute.int_tuple<"(?,?)">)
           -> !cute.int_tuple<"(?,?)">
        cute.print(%r2) : !cute.int_tuple<"(?,?)">

        // tuple_sub rank-mismatch: (10,8,3) - (1,2) → (9,6,3).
        %osub8 = arith.constant 8 : i32
        %xsub8 = arith.addi %base, %osub8 : i32
        %t2am = cute.make_int_tuple (%x10, %xsub8, %x3)
            : (i32, i32, i32) -> !cute.int_tuple<"(?,?,?)">
        %t2bm = cute.make_int_tuple (%x1, %x2) : (i32, i32) -> !cute.int_tuple<"(?,?)">
        %r2m = cute.tuple_sub(%t2am, %t2bm)
            : (!cute.int_tuple<"(?,?,?)">, !cute.int_tuple<"(?,?)">)
           -> !cute.int_tuple<"(?,?,?)">
        cute.print(%r2m) : !cute.int_tuple<"(?,?,?)">

        // tuple_sub nested: ((10,15),5) - ((1,2),3) → ((9,13),2).
        %t2an = cute.make_int_tuple (%x10, %x15, %x5)
            : (i32, i32, i32) -> !cute.int_tuple<"((?,?),?)">
        %t2bn = cute.make_int_tuple (%x1, %x2, %x3)
            : (i32, i32, i32) -> !cute.int_tuple<"((?,?),?)">
        %r2n = cute.tuple_sub(%t2an, %t2bn)
            : (!cute.int_tuple<"((?,?),?)">, !cute.int_tuple<"((?,?),?)">)
           -> !cute.int_tuple<"((?,?),?)">
        cute.print(%r2n) : !cute.int_tuple<"((?,?),?)">

        // tuple_sub zero identity with dyn lhs: (7,11) - 0 → (7,11).
        %osub7 = arith.constant 7 : i32
        %osub11 = arith.constant 11 : i32
        %xsub7 = arith.addi %base, %osub7 : i32
        %xsub11 = arith.addi %base, %osub11 : i32
        %t2az = cute.make_int_tuple (%xsub7, %xsub11) : (i32, i32) -> !cute.int_tuple<"(?,?)">
        %t2bz = cute.static : !cute.int_tuple<"0">
        %r2z = cute.tuple_sub(%t2az, %t2bz)
            : (!cute.int_tuple<"(?,?)">, !cute.int_tuple<"0">)
           -> !cute.int_tuple<"(?,?)">
        cute.print(%r2z) : !cute.int_tuple<"(?,?)">

        %o20 = arith.constant 20 : i32

        // shape_div: (12,20) / (3,4) → (4,5)
        %o12 = arith.constant 12 : i32
        %xs12 = arith.addi %base, %o12 : i32
        %xs20 = arith.addi %base, %o20 : i32
        %xss3 = arith.addi %base, %o3 : i32
        %xs4 = arith.addi %base, %o4 : i32
        %t6a = cute.make_shape (%xs12, %xs20) : (i32, i32) -> !cute.shape<"(?,?)">
        %t6b = cute.make_shape (%xss3, %xs4) : (i32, i32) -> !cute.shape<"(?,?)">
        %r6 = cute.shape_div(%t6a, %t6b)
            : (!cute.shape<"(?,?)">, !cute.shape<"(?,?)">) -> !cute.shape<"(?,?)">
        cute.print(%r6) : !cute.shape<"(?,?)">

        // shape_div tuple/scalar sequential: (4,5,6)/40 → (1,1,3).
        %osd40 = arith.constant 40 : i32
        %osd6 = arith.constant 6 : i32
        %xsd4 = arith.addi %base, %o4 : i32
        %xsd5 = arith.addi %base, %o5 : i32
        %xsd6 = arith.addi %base, %osd6 : i32
        %xsd40 = arith.addi %base, %osd40 : i32
        %t6aq = cute.make_shape (%xsd4, %xsd5, %xsd6)
            : (i32, i32, i32) -> !cute.shape<"(?,?,?)">
        %t6bq = cute.make_shape (%xsd40) : (i32) -> !cute.shape<"?">
        %r6q = cute.shape_div(%t6aq, %t6bq)
            : (!cute.shape<"(?,?,?)">, !cute.shape<"?">)
           -> !cute.shape<"(?,?,?)">
        cute.print(%r6q) : !cute.shape<"(?,?,?)">

        // shape_div nested: ((8,10),(6,4))/((2,5),(3,2)) → ((4,2),(2,2)).
        %osd8 = arith.constant 8 : i32
        %xsd8 = arith.addi %base, %osd8 : i32
        %xsd10 = arith.addi %base, %o10 : i32
        %xsd2 = arith.addi %base, %o2 : i32
        %xsd3 = arith.addi %base, %o3 : i32
        %t6an = cute.make_shape (%xsd8, %xsd10, %xsd6, %xsd4)
            : (i32, i32, i32, i32) -> !cute.shape<"((?,?),(?,?))">
        %t6bn = cute.make_shape (%xsd2, %xsd5, %xsd3, %xsd2)
            : (i32, i32, i32, i32) -> !cute.shape<"((?,?),(?,?))">
        %r6n = cute.shape_div(%t6an, %t6bn)
            : (!cute.shape<"((?,?),(?,?))">, !cute.shape<"((?,?),(?,?))">)
           -> !cute.shape<"((?,?),(?,?))">
        cute.print(%r6n) : !cute.shape<"((?,?),(?,?))">

        // ceil_div: ceildiv((10,11), (3,4)) → (4,3)
        %o11 = arith.constant 11 : i32
        %xc10 = arith.addi %base, %o10 : i32
        %xc11 = arith.addi %base, %o11 : i32
        %xc3 = arith.addi %base, %o3 : i32
        %xc4 = arith.addi %base, %o4 : i32
        %t7a = cute.make_int_tuple (%xc10, %xc11) : (i32, i32) -> !cute.int_tuple<"(?,?)">
        %t7b = cute.make_int_tuple (%xc3, %xc4) : (i32, i32) -> !cute.int_tuple<"(?,?)">
        %r7 = cute.ceil_div(%t7a, %t7b)
            : (!cute.int_tuple<"(?,?)">, !cute.int_tuple<"(?,?)">)
           -> !cute.int_tuple<"(?,?)">
        cute.print(%r7) : !cute.int_tuple<"(?,?)">

        // ceil_div input-longer: (8,10,6)/(3,4) → (3,3,6).
        %ocd8 = arith.constant 8 : i32
        %ocd6 = arith.constant 6 : i32
        %xcd8 = arith.addi %base, %ocd8 : i32
        %xcd6 = arith.addi %base, %ocd6 : i32
        %t7am = cute.make_int_tuple (%xcd8, %xc10, %xcd6)
            : (i32, i32, i32) -> !cute.int_tuple<"(?,?,?)">
        %t7bm = cute.make_int_tuple (%xc3, %xc4)
            : (i32, i32) -> !cute.int_tuple<"(?,?)">
        %r7m = cute.ceil_div(%t7am, %t7bm)
            : (!cute.int_tuple<"(?,?,?)">, !cute.int_tuple<"(?,?)">)
           -> !cute.int_tuple<"(?,?,?)">
        cute.print(%r7m) : !cute.int_tuple<"(?,?,?)">

        // ceil_div sequential: (4,8)/2 → (2,8).
        %xcd4 = arith.addi %base, %o4 : i32
        %xcd2 = arith.addi %base, %o2 : i32
        %t7aq = cute.make_int_tuple (%xcd4, %xcd8)
            : (i32, i32) -> !cute.int_tuple<"(?,?)">
        %t7bq = cute.make_int_tuple (%xcd2) : (i32) -> !cute.int_tuple<"?">
        %r7q = cute.ceil_div(%t7aq, %t7bq)
            : (!cute.int_tuple<"(?,?)">, !cute.int_tuple<"?">)
           -> !cute.int_tuple<"(?,?)">
        cute.print(%r7q) : !cute.int_tuple<"(?,?)">

        // elem_less: (3,4) < (5,6) → 1
        %o6 = arith.constant 6 : i32
        %xlt3 = arith.addi %base, %o3 : i32
        %xlt4 = arith.addi %base, %o4 : i32
        %xlt5 = arith.addi %base, %o5 : i32
        %xlt6 = arith.addi %base, %o6 : i32
        %t8a = cute.make_int_tuple (%xlt3, %xlt4) : (i32, i32) -> !cute.int_tuple<"(?,?)">
        %t8b = cute.make_int_tuple (%xlt5, %xlt6) : (i32, i32) -> !cute.int_tuple<"(?,?)">
        %r8 = cute.elem_less(%t8a, %t8b)
            : (!cute.int_tuple<"(?,?)">, !cute.int_tuple<"(?,?)">) -> i1
        %r8_i32 = arith.extui %r8 : i1 to i32
        gpu.printf "%d\n", %r8_i32 : i32

        // equal: (3,4) == (3,5) → 0
        %xeq3 = arith.addi %base, %o3 : i32
        %xeq4 = arith.addi %base, %o4 : i32
        %xeq5 = arith.addi %base, %o5 : i32
        %t9a = cute.make_int_tuple (%xeq3, %xeq4) : (i32, i32) -> !cute.int_tuple<"(?,?)">
        %t9b = cute.make_int_tuple (%xeq3, %xeq5) : (i32, i32) -> !cute.int_tuple<"(?,?)">
        %r9 = cute.equal(%t9a, %t9b)
            : (!cute.int_tuple<"(?,?)">, !cute.int_tuple<"(?,?)">) -> i1
        %r9_i32 = arith.extui %r9 : i1 to i32
        gpu.printf "%d\n", %r9_i32 : i32

        // elem_less nested dyn: ((1,2),3) < ((4,5),6) at every leaf → 1.
        %t10a = cute.make_int_tuple (%xlt3, %xeq4, %xlt5)
              : (i32, i32, i32) -> !cute.int_tuple<"((?,?),?)">
        %t10b = cute.make_int_tuple (%xlt5, %xlt6, %xlt6)
              : (i32, i32, i32) -> !cute.int_tuple<"((?,?),?)">
        %r10 = cute.elem_less(%t10a, %t10b)
            : (!cute.int_tuple<"((?,?),?)">, !cute.int_tuple<"((?,?),?)">) -> i1
        %r10_i32 = arith.extui %r10 : i1 to i32
        gpu.printf "%d\n", %r10_i32 : i32

        // equal nested dyn: identical dyn `((?,?),?)` leaves on both sides → 1.
        %t11a = cute.make_int_tuple (%xlt3, %xeq4, %xlt5)
              : (i32, i32, i32) -> !cute.int_tuple<"((?,?),?)">
        %t11b = cute.make_int_tuple (%xlt3, %xeq4, %xlt5)
              : (i32, i32, i32) -> !cute.int_tuple<"((?,?),?)">
        %r11 = cute.equal(%t11a, %t11b)
            : (!cute.int_tuple<"((?,?),?)">, !cute.int_tuple<"((?,?),?)">) -> i1
        %r11_i32 = arith.extui %r11 : i1 to i32
        gpu.printf "%d\n", %r11_i32 : i32

        // equal layout dyn: identical dyn `(?,4):(1,?)` on both sides → 1.
        // The static `1` stride leaf surfaces as `arith.constant 1 : i32 →
        // arith.extsi to i64` (inserted by `GetScalarsOpConversion` to
        // honor the op's i64-typed leaf declaration), then a real
        // `arith.cmpi : i64`.
        %sh12a = cute.make_shape (%xlt3) : (i32) -> !cute.shape<"(?,4)">
        %st12a = cute.make_stride (%xlt4) : (i32) -> !cute.stride<"(1,?)">
        %l12a = cute.make_layout (%sh12a, %st12a)
              : (!cute.shape<"(?,4)">, !cute.stride<"(1,?)">)
             -> !cute.layout<"(?,4):(1,?)">
        %sh12b = cute.make_shape (%xlt3) : (i32) -> !cute.shape<"(?,4)">
        %st12b = cute.make_stride (%xlt4) : (i32) -> !cute.stride<"(1,?)">
        %l12b = cute.make_layout (%sh12b, %st12b)
              : (!cute.shape<"(?,4)">, !cute.stride<"(1,?)">)
             -> !cute.layout<"(?,4):(1,?)">
        %r12 = cute.equal(%l12a, %l12b)
            : (!cute.layout<"(?,4):(1,?)">, !cute.layout<"(?,4):(1,?)">) -> i1
        %r12_i32 = arith.extui %r12 : i1 to i32
        gpu.printf "%d\n", %r12_i32 : i32

        // equal stride dyn: identical dyn `(1,?)` on both sides → 1.
        %s13a = cute.make_stride (%xlt4) : (i32) -> !cute.stride<"(1,?)">
        %s13b = cute.make_stride (%xlt4) : (i32) -> !cute.stride<"(1,?)">
        %r13 = cute.equal(%s13a, %s13b)
            : (!cute.stride<"(1,?)">, !cute.stride<"(1,?)">) -> i1
        %r13_i32 = arith.extui %r13 : i1 to i32
        gpu.printf "%d\n", %r13_i32 : i32
      }
      gpu.return
    }
  }

  func.func @main() {
    %base = func.call @read_base() : () -> i32
    %c1 = arith.constant 1 : index
    %c4 = arith.constant 4 : index
    gpu.launch_func @kernel::@print_all blocks in (%c1, %c1, %c1) threads in (%c4, %c1, %c1) args(%base : i32)
    return
  }
}
