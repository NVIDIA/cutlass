

!memref_gmem_i32_ = !cute.memref<i32, gmem, "(?):(1)">
!memref_gmem_i8_ = !cute.memref<i8, gmem, "(?):(1)">
module attributes {gpu.container_module} {
  gpu.module @kernels {
    func.func public @kernel_cutlass_vote_kernel_tensorptri32gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_True_0(%arg0: !memref_gmem_i32_, %arg1: !memref_gmem_i8_, %arg2: !memref_gmem_i8_, %arg3: !memref_gmem_i8_) attributes {cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 32, 1, 1>} {
      %iter = cute.get_iter(%arg0) : !memref_gmem_i32_
      %iter_0 = cute.get_iter(%arg1) : !memref_gmem_i8_
      %iter_1 = cute.get_iter(%arg2) : !memref_gmem_i8_
      %iter_2 = cute.get_iter(%arg3) : !memref_gmem_i8_
      %iter_3 = cute.get_iter(%arg0) : !memref_gmem_i32_
      %iter_4 = cute.get_iter(%arg1) : !memref_gmem_i8_
      %iter_5 = cute.get_iter(%arg2) : !memref_gmem_i8_
      %iter_6 = cute.get_iter(%arg3) : !memref_gmem_i8_
      %lay = cute.get_layout(%arg0) : !memref_gmem_i32_
      %0 = cute.get_shape(%lay) : (!cute.layout<"(?):(1)">) -> !cute.shape<"(?)">
      %e0 = cute.get_leaves(%0) : !cute.shape<"(?)">
      %itup = cute.to_int_tuple(%e0) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %1 = cute.get_scalars(%itup) : !cute.int_tuple<"?">
      %2 = cute.get_stride(%lay) : (!cute.layout<"(?):(1)">) -> !cute.stride<"(1)">
      %e0_7 = cute.get_leaves(%2) : !cute.stride<"(1)">
      %lay_8 = cute.get_layout(%arg1) : !memref_gmem_i8_
      %3 = cute.get_shape(%lay_8) : (!cute.layout<"(?):(1)">) -> !cute.shape<"(?)">
      %e0_9 = cute.get_leaves(%3) : !cute.shape<"(?)">
      %itup_10 = cute.to_int_tuple(%e0_9) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %4 = cute.get_scalars(%itup_10) : !cute.int_tuple<"?">
      %5 = cute.get_stride(%lay_8) : (!cute.layout<"(?):(1)">) -> !cute.stride<"(1)">
      %e0_11 = cute.get_leaves(%5) : !cute.stride<"(1)">
      %lay_12 = cute.get_layout(%arg2) : !memref_gmem_i8_
      %6 = cute.get_shape(%lay_12) : (!cute.layout<"(?):(1)">) -> !cute.shape<"(?)">
      %e0_13 = cute.get_leaves(%6) : !cute.shape<"(?)">
      %itup_14 = cute.to_int_tuple(%e0_13) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %7 = cute.get_scalars(%itup_14) : !cute.int_tuple<"?">
      %8 = cute.get_stride(%lay_12) : (!cute.layout<"(?):(1)">) -> !cute.stride<"(1)">
      %e0_15 = cute.get_leaves(%8) : !cute.stride<"(1)">
      %lay_16 = cute.get_layout(%arg3) : !memref_gmem_i8_
      %9 = cute.get_shape(%lay_16) : (!cute.layout<"(?):(1)">) -> !cute.shape<"(?)">
      %e0_17 = cute.get_leaves(%9) : !cute.shape<"(?)">
      %itup_18 = cute.to_int_tuple(%e0_17) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %10 = cute.get_scalars(%itup_18) : !cute.int_tuple<"?">
      %11 = cute.get_stride(%lay_16) : (!cute.layout<"(?):(1)">) -> !cute.stride<"(1)">
      %e0_19 = cute.get_leaves(%11) : !cute.stride<"(1)">
      %12 = nvvm.read.ptx.sreg.tid.x : i32
      %13 = nvvm.read.ptx.sreg.tid.y : i32
      %14 = nvvm.read.ptx.sreg.tid.z : i32
      %c10_i32 = arith.constant 10 : i32
      %15 = arith.cmpi slt, %12, %c10_i32 : i32
      %c-1_i32 = arith.constant -1 : i32
      %16 = llvm.inline_asm has_side_effects asm_dialect = att "{\0A\09\0A            .reg .pred p;\0A\09\0A            setp.ne.b32 p, $1, 0;\0A\09\0A            vote.sync.ballot.b32 $0, p, $2;\0A\09\0A            }", "=r,r,i" %15, %c-1_i32 : (i1, i32) -> i32
      %17 = arith.cmpi slt, %12, %c10_i32 : i32
      %c-1_i32_20 = arith.constant -1 : i32
      %18 = llvm.inline_asm has_side_effects asm_dialect = att "{\0A\09\0A            .reg .pred ps;\0A\09\0A            .reg .pred pd;\0A\09\0A            setp.ne.b32 ps, $1, 0;\0A\09\0A            vote.sync.any.pred pd, ps, $2;\0A\09\0A            selp.b32 $0, 1, 0, pd;\0A\09\0A            }", "=r,r,i" %17, %c-1_i32_20 : (i1, i32) -> i1
      %19 = arith.cmpi slt, %12, %c10_i32 : i32
      %c-1_i32_21 = arith.constant -1 : i32
      %20 = llvm.inline_asm has_side_effects asm_dialect = att "{\0A\09\0A            .reg .pred ps;\0A\09\0A            .reg .pred pd;\0A\09\0A            setp.ne.b32 ps, $1, 0;\0A\09\0A            vote.sync.all.pred pd, ps, $2;\0A\09\0A            selp.b32 $0, 1, 0, pd;\0A\09\0A            }", "=r,r,i" %19, %c-1_i32_21 : (i1, i32) -> i1
      %21 = arith.cmpi slt, %12, %c10_i32 : i32
      %c-1_i32_22 = arith.constant -1 : i32
      %22 = llvm.inline_asm has_side_effects asm_dialect = att "{\0A\09\0A            .reg .pred ps;\0A\09\0A            .reg .pred pd;\0A\09\0A            setp.ne.b32 ps, $1, 0;\0A\09\0A            vote.sync.uni.pred pd, ps, $2;\0A\09\0A            selp.b32 $0, 1, 0, pd;\0A\09\0A            }", "=r,r,i" %21, %c-1_i32_22 : (i1, i32) -> i1
      %coord = cute.make_coord(%12) : (i32) -> !cute.coord<"?">
      cute.memref.store(%arg0, %coord, %16) : (!memref_gmem_i32_, !cute.coord<"?">, i32) -> ()
      %23 = arith.extui %18 : i1 to i8
      %coord_23 = cute.make_coord(%12) : (i32) -> !cute.coord<"?">
      cute.memref.store(%arg1, %coord_23, %23) : (!memref_gmem_i8_, !cute.coord<"?">, i8) -> ()
      %24 = arith.extui %20 : i1 to i8
      %coord_24 = cute.make_coord(%12) : (i32) -> !cute.coord<"?">
      cute.memref.store(%arg2, %coord_24, %24) : (!memref_gmem_i8_, !cute.coord<"?">, i8) -> ()
      %25 = arith.extui %22 : i1 to i8
      %coord_25 = cute.make_coord(%12) : (i32) -> !cute.coord<"?">
      cute.memref.store(%arg3, %coord_25, %25) : (!memref_gmem_i8_, !cute.coord<"?">, i8) -> ()
      return
    }
  }
  func.func @cutlass_vote_Tensorgmemo1_Tensorgmemo1_Tensorgmemo1_Tensorgmemo1_True(%arg0: !memref_gmem_i32_, %arg1: !memref_gmem_i8_, %arg2: !memref_gmem_i8_, %arg3: !memref_gmem_i8_) attributes {llvm.emit_c_interface} {
    %iter = cute.get_iter(%arg0) : !memref_gmem_i32_
    %iter_0 = cute.get_iter(%arg1) : !memref_gmem_i8_
    %iter_1 = cute.get_iter(%arg2) : !memref_gmem_i8_
    %iter_2 = cute.get_iter(%arg3) : !memref_gmem_i8_
    %iter_3 = cute.get_iter(%arg0) : !memref_gmem_i32_
    %iter_4 = cute.get_iter(%arg1) : !memref_gmem_i8_
    %iter_5 = cute.get_iter(%arg2) : !memref_gmem_i8_
    %iter_6 = cute.get_iter(%arg3) : !memref_gmem_i8_
    %lay = cute.get_layout(%arg0) : !memref_gmem_i32_
    %0 = cute.get_shape(%lay) : (!cute.layout<"(?):(1)">) -> !cute.shape<"(?)">
    %e0 = cute.get_leaves(%0) : !cute.shape<"(?)">
    %itup = cute.to_int_tuple(%e0) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %1 = cute.get_scalars(%itup) : !cute.int_tuple<"?">
    %2 = cute.get_stride(%lay) : (!cute.layout<"(?):(1)">) -> !cute.stride<"(1)">
    %e0_7 = cute.get_leaves(%2) : !cute.stride<"(1)">
    %lay_8 = cute.get_layout(%arg1) : !memref_gmem_i8_
    %3 = cute.get_shape(%lay_8) : (!cute.layout<"(?):(1)">) -> !cute.shape<"(?)">
    %e0_9 = cute.get_leaves(%3) : !cute.shape<"(?)">
    %itup_10 = cute.to_int_tuple(%e0_9) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %4 = cute.get_scalars(%itup_10) : !cute.int_tuple<"?">
    %5 = cute.get_stride(%lay_8) : (!cute.layout<"(?):(1)">) -> !cute.stride<"(1)">
    %e0_11 = cute.get_leaves(%5) : !cute.stride<"(1)">
    %lay_12 = cute.get_layout(%arg2) : !memref_gmem_i8_
    %6 = cute.get_shape(%lay_12) : (!cute.layout<"(?):(1)">) -> !cute.shape<"(?)">
    %e0_13 = cute.get_leaves(%6) : !cute.shape<"(?)">
    %itup_14 = cute.to_int_tuple(%e0_13) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %7 = cute.get_scalars(%itup_14) : !cute.int_tuple<"?">
    %8 = cute.get_stride(%lay_12) : (!cute.layout<"(?):(1)">) -> !cute.stride<"(1)">
    %e0_15 = cute.get_leaves(%8) : !cute.stride<"(1)">
    %lay_16 = cute.get_layout(%arg3) : !memref_gmem_i8_
    %9 = cute.get_shape(%lay_16) : (!cute.layout<"(?):(1)">) -> !cute.shape<"(?)">
    %e0_17 = cute.get_leaves(%9) : !cute.shape<"(?)">
    %itup_18 = cute.to_int_tuple(%e0_17) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %10 = cute.get_scalars(%itup_18) : !cute.int_tuple<"?">
    %11 = cute.get_stride(%lay_16) : (!cute.layout<"(?):(1)">) -> !cute.stride<"(1)">
    %e0_19 = cute.get_leaves(%11) : !cute.stride<"(1)">
    %int_tuple = cute.make_int_tuple() : () -> !cute.int_tuple<"32">
    %sz = cute.size(%int_tuple) <{mode = [0]}> : (!cute.int_tuple<"32">) -> !cute.int_tuple<"32">
    %e0_20 = cute.get_leaves(%sz) : !cute.int_tuple<"32">
    %lay_21 = cute.get_layout(%arg0) : !memref_gmem_i32_
    %12 = cute.get_shape(%lay_21) : (!cute.layout<"(?):(1)">) -> !cute.shape<"(?)">
    %e0_22 = cute.get_leaves(%12) : !cute.shape<"(?)">
    %itup_23 = cute.to_int_tuple(%e0_22) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %13 = cute.get_scalars(%itup_23) : !cute.int_tuple<"?">
    %14 = cute.get_stride(%lay_21) : (!cute.layout<"(?):(1)">) -> !cute.stride<"(1)">
    %e0_24 = cute.get_leaves(%14) : !cute.stride<"(1)">
    %lay_25 = cute.get_layout(%arg1) : !memref_gmem_i8_
    %15 = cute.get_shape(%lay_25) : (!cute.layout<"(?):(1)">) -> !cute.shape<"(?)">
    %e0_26 = cute.get_leaves(%15) : !cute.shape<"(?)">
    %itup_27 = cute.to_int_tuple(%e0_26) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %16 = cute.get_scalars(%itup_27) : !cute.int_tuple<"?">
    %17 = cute.get_stride(%lay_25) : (!cute.layout<"(?):(1)">) -> !cute.stride<"(1)">
    %e0_28 = cute.get_leaves(%17) : !cute.stride<"(1)">
    %lay_29 = cute.get_layout(%arg2) : !memref_gmem_i8_
    %18 = cute.get_shape(%lay_29) : (!cute.layout<"(?):(1)">) -> !cute.shape<"(?)">
    %e0_30 = cute.get_leaves(%18) : !cute.shape<"(?)">
    %itup_31 = cute.to_int_tuple(%e0_30) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %19 = cute.get_scalars(%itup_31) : !cute.int_tuple<"?">
    %20 = cute.get_stride(%lay_29) : (!cute.layout<"(?):(1)">) -> !cute.stride<"(1)">
    %e0_32 = cute.get_leaves(%20) : !cute.stride<"(1)">
    %lay_33 = cute.get_layout(%arg3) : !memref_gmem_i8_
    %21 = cute.get_shape(%lay_33) : (!cute.layout<"(?):(1)">) -> !cute.shape<"(?)">
    %e0_34 = cute.get_leaves(%21) : !cute.shape<"(?)">
    %itup_35 = cute.to_int_tuple(%e0_34) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %22 = cute.get_scalars(%itup_35) : !cute.int_tuple<"?">
    %23 = cute.get_stride(%lay_33) : (!cute.layout<"(?):(1)">) -> !cute.stride<"(1)">
    %e0_36 = cute.get_leaves(%23) : !cute.stride<"(1)">
    %c1 = arith.constant 1 : index
    %c32 = arith.constant 32 : index
    %c0_i32 = arith.constant 0 : i32
    gpu.launch_func  @kernels::@kernel_cutlass_vote_kernel_tensorptri32gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_True_0 blocks in (%c1, %c1, %c1) threads in (%c32, %c1, %c1)  dynamic_shared_memory_size %c0_i32 args(%arg0 : !memref_gmem_i32_, %arg1 : !memref_gmem_i8_, %arg2 : !memref_gmem_i8_, %arg3 : !memref_gmem_i8_) {use_pdl = false}
    return
  }
}



!memref_gmem_i32_ = !cute.memref<i32, gmem, "(?):(1)">
!memref_gmem_i8_ = !cute.memref<i8, gmem, "(?):(1)">
module attributes {gpu.container_module} {
  gpu.module @kernels {
    func.func public @kernel_cutlass_vote_kernel_tensorptri32gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_False_0(%arg0: !memref_gmem_i32_, %arg1: !memref_gmem_i8_, %arg2: !memref_gmem_i8_, %arg3: !memref_gmem_i8_) attributes {cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 32, 1, 1>} {
      %iter = cute.get_iter(%arg0) : !memref_gmem_i32_
      %iter_0 = cute.get_iter(%arg1) : !memref_gmem_i8_
      %iter_1 = cute.get_iter(%arg2) : !memref_gmem_i8_
      %iter_2 = cute.get_iter(%arg3) : !memref_gmem_i8_
      %iter_3 = cute.get_iter(%arg0) : !memref_gmem_i32_
      %iter_4 = cute.get_iter(%arg1) : !memref_gmem_i8_
      %iter_5 = cute.get_iter(%arg2) : !memref_gmem_i8_
      %iter_6 = cute.get_iter(%arg3) : !memref_gmem_i8_
      %lay = cute.get_layout(%arg0) : !memref_gmem_i32_
      %0 = cute.get_shape(%lay) : (!cute.layout<"(?):(1)">) -> !cute.shape<"(?)">
      %e0 = cute.get_leaves(%0) : !cute.shape<"(?)">
      %itup = cute.to_int_tuple(%e0) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %1 = cute.get_scalars(%itup) : !cute.int_tuple<"?">
      %2 = cute.get_stride(%lay) : (!cute.layout<"(?):(1)">) -> !cute.stride<"(1)">
      %e0_7 = cute.get_leaves(%2) : !cute.stride<"(1)">
      %lay_8 = cute.get_layout(%arg1) : !memref_gmem_i8_
      %3 = cute.get_shape(%lay_8) : (!cute.layout<"(?):(1)">) -> !cute.shape<"(?)">
      %e0_9 = cute.get_leaves(%3) : !cute.shape<"(?)">
      %itup_10 = cute.to_int_tuple(%e0_9) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %4 = cute.get_scalars(%itup_10) : !cute.int_tuple<"?">
      %5 = cute.get_stride(%lay_8) : (!cute.layout<"(?):(1)">) -> !cute.stride<"(1)">
      %e0_11 = cute.get_leaves(%5) : !cute.stride<"(1)">
      %lay_12 = cute.get_layout(%arg2) : !memref_gmem_i8_
      %6 = cute.get_shape(%lay_12) : (!cute.layout<"(?):(1)">) -> !cute.shape<"(?)">
      %e0_13 = cute.get_leaves(%6) : !cute.shape<"(?)">
      %itup_14 = cute.to_int_tuple(%e0_13) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %7 = cute.get_scalars(%itup_14) : !cute.int_tuple<"?">
      %8 = cute.get_stride(%lay_12) : (!cute.layout<"(?):(1)">) -> !cute.stride<"(1)">
      %e0_15 = cute.get_leaves(%8) : !cute.stride<"(1)">
      %lay_16 = cute.get_layout(%arg3) : !memref_gmem_i8_
      %9 = cute.get_shape(%lay_16) : (!cute.layout<"(?):(1)">) -> !cute.shape<"(?)">
      %e0_17 = cute.get_leaves(%9) : !cute.shape<"(?)">
      %itup_18 = cute.to_int_tuple(%e0_17) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %10 = cute.get_scalars(%itup_18) : !cute.int_tuple<"?">
      %11 = cute.get_stride(%lay_16) : (!cute.layout<"(?):(1)">) -> !cute.stride<"(1)">
      %e0_19 = cute.get_leaves(%11) : !cute.stride<"(1)">
      %12 = nvvm.read.ptx.sreg.tid.x : i32
      %13 = nvvm.read.ptx.sreg.tid.y : i32
      %14 = nvvm.read.ptx.sreg.tid.z : i32
      %c10_i32 = arith.constant 10 : i32
      %15 = arith.cmpi slt, %12, %c10_i32 : i32
      %c-1_i32 = arith.constant -1 : i32
      %16 = nvvm.vote.ballot.sync %c-1_i32, %15 : i32
      %17 = arith.cmpi slt, %12, %c10_i32 : i32
      %c-1_i32_20 = arith.constant -1 : i32
      %18 = llvm.inline_asm has_side_effects asm_dialect = att "{\0A\09\0A            .reg .pred ps;\0A\09\0A            .reg .pred pd;\0A\09\0A            setp.ne.b32 ps, $1, 0;\0A\09\0A            vote.sync.any.pred pd, ps, $2;\0A\09\0A            selp.b32 $0, 1, 0, pd;\0A\09\0A            }", "=r,r,i" %17, %c-1_i32_20 : (i1, i32) -> i1
      %19 = arith.cmpi slt, %12, %c10_i32 : i32
      %c-1_i32_21 = arith.constant -1 : i32
      %20 = llvm.inline_asm has_side_effects asm_dialect = att "{\0A\09\0A            .reg .pred ps;\0A\09\0A            .reg .pred pd;\0A\09\0A            setp.ne.b32 ps, $1, 0;\0A\09\0A            vote.sync.all.pred pd, ps, $2;\0A\09\0A            selp.b32 $0, 1, 0, pd;\0A\09\0A            }", "=r,r,i" %19, %c-1_i32_21 : (i1, i32) -> i1
      %21 = arith.cmpi slt, %12, %c10_i32 : i32
      %c-1_i32_22 = arith.constant -1 : i32
      %22 = llvm.inline_asm has_side_effects asm_dialect = att "{\0A\09\0A            .reg .pred ps;\0A\09\0A            .reg .pred pd;\0A\09\0A            setp.ne.b32 ps, $1, 0;\0A\09\0A            vote.sync.uni.pred pd, ps, $2;\0A\09\0A            selp.b32 $0, 1, 0, pd;\0A\09\0A            }", "=r,r,i" %21, %c-1_i32_22 : (i1, i32) -> i1
      %coord = cute.make_coord(%12) : (i32) -> !cute.coord<"?">
      cute.memref.store(%arg0, %coord, %16) : (!memref_gmem_i32_, !cute.coord<"?">, i32) -> ()
      %23 = arith.extui %18 : i1 to i8
      %coord_23 = cute.make_coord(%12) : (i32) -> !cute.coord<"?">
      cute.memref.store(%arg1, %coord_23, %23) : (!memref_gmem_i8_, !cute.coord<"?">, i8) -> ()
      %24 = arith.extui %20 : i1 to i8
      %coord_24 = cute.make_coord(%12) : (i32) -> !cute.coord<"?">
      cute.memref.store(%arg2, %coord_24, %24) : (!memref_gmem_i8_, !cute.coord<"?">, i8) -> ()
      %25 = arith.extui %22 : i1 to i8
      %coord_25 = cute.make_coord(%12) : (i32) -> !cute.coord<"?">
      cute.memref.store(%arg3, %coord_25, %25) : (!memref_gmem_i8_, !cute.coord<"?">, i8) -> ()
      return
    }
  }
  func.func @cutlass_vote_Tensorgmemo1_Tensorgmemo1_Tensorgmemo1_Tensorgmemo1_False(%arg0: !memref_gmem_i32_, %arg1: !memref_gmem_i8_, %arg2: !memref_gmem_i8_, %arg3: !memref_gmem_i8_) attributes {llvm.emit_c_interface} {
    %iter = cute.get_iter(%arg0) : !memref_gmem_i32_
    %iter_0 = cute.get_iter(%arg1) : !memref_gmem_i8_
    %iter_1 = cute.get_iter(%arg2) : !memref_gmem_i8_
    %iter_2 = cute.get_iter(%arg3) : !memref_gmem_i8_
    %iter_3 = cute.get_iter(%arg0) : !memref_gmem_i32_
    %iter_4 = cute.get_iter(%arg1) : !memref_gmem_i8_
    %iter_5 = cute.get_iter(%arg2) : !memref_gmem_i8_
    %iter_6 = cute.get_iter(%arg3) : !memref_gmem_i8_
    %lay = cute.get_layout(%arg0) : !memref_gmem_i32_
    %0 = cute.get_shape(%lay) : (!cute.layout<"(?):(1)">) -> !cute.shape<"(?)">
    %e0 = cute.get_leaves(%0) : !cute.shape<"(?)">
    %itup = cute.to_int_tuple(%e0) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %1 = cute.get_scalars(%itup) : !cute.int_tuple<"?">
    %2 = cute.get_stride(%lay) : (!cute.layout<"(?):(1)">) -> !cute.stride<"(1)">
    %e0_7 = cute.get_leaves(%2) : !cute.stride<"(1)">
    %lay_8 = cute.get_layout(%arg1) : !memref_gmem_i8_
    %3 = cute.get_shape(%lay_8) : (!cute.layout<"(?):(1)">) -> !cute.shape<"(?)">
    %e0_9 = cute.get_leaves(%3) : !cute.shape<"(?)">
    %itup_10 = cute.to_int_tuple(%e0_9) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %4 = cute.get_scalars(%itup_10) : !cute.int_tuple<"?">
    %5 = cute.get_stride(%lay_8) : (!cute.layout<"(?):(1)">) -> !cute.stride<"(1)">
    %e0_11 = cute.get_leaves(%5) : !cute.stride<"(1)">
    %lay_12 = cute.get_layout(%arg2) : !memref_gmem_i8_
    %6 = cute.get_shape(%lay_12) : (!cute.layout<"(?):(1)">) -> !cute.shape<"(?)">
    %e0_13 = cute.get_leaves(%6) : !cute.shape<"(?)">
    %itup_14 = cute.to_int_tuple(%e0_13) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %7 = cute.get_scalars(%itup_14) : !cute.int_tuple<"?">
    %8 = cute.get_stride(%lay_12) : (!cute.layout<"(?):(1)">) -> !cute.stride<"(1)">
    %e0_15 = cute.get_leaves(%8) : !cute.stride<"(1)">
    %lay_16 = cute.get_layout(%arg3) : !memref_gmem_i8_
    %9 = cute.get_shape(%lay_16) : (!cute.layout<"(?):(1)">) -> !cute.shape<"(?)">
    %e0_17 = cute.get_leaves(%9) : !cute.shape<"(?)">
    %itup_18 = cute.to_int_tuple(%e0_17) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %10 = cute.get_scalars(%itup_18) : !cute.int_tuple<"?">
    %11 = cute.get_stride(%lay_16) : (!cute.layout<"(?):(1)">) -> !cute.stride<"(1)">
    %e0_19 = cute.get_leaves(%11) : !cute.stride<"(1)">
    %int_tuple = cute.make_int_tuple() : () -> !cute.int_tuple<"32">
    %sz = cute.size(%int_tuple) <{mode = [0]}> : (!cute.int_tuple<"32">) -> !cute.int_tuple<"32">
    %e0_20 = cute.get_leaves(%sz) : !cute.int_tuple<"32">
    %lay_21 = cute.get_layout(%arg0) : !memref_gmem_i32_
    %12 = cute.get_shape(%lay_21) : (!cute.layout<"(?):(1)">) -> !cute.shape<"(?)">
    %e0_22 = cute.get_leaves(%12) : !cute.shape<"(?)">
    %itup_23 = cute.to_int_tuple(%e0_22) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %13 = cute.get_scalars(%itup_23) : !cute.int_tuple<"?">
    %14 = cute.get_stride(%lay_21) : (!cute.layout<"(?):(1)">) -> !cute.stride<"(1)">
    %e0_24 = cute.get_leaves(%14) : !cute.stride<"(1)">
    %lay_25 = cute.get_layout(%arg1) : !memref_gmem_i8_
    %15 = cute.get_shape(%lay_25) : (!cute.layout<"(?):(1)">) -> !cute.shape<"(?)">
    %e0_26 = cute.get_leaves(%15) : !cute.shape<"(?)">
    %itup_27 = cute.to_int_tuple(%e0_26) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %16 = cute.get_scalars(%itup_27) : !cute.int_tuple<"?">
    %17 = cute.get_stride(%lay_25) : (!cute.layout<"(?):(1)">) -> !cute.stride<"(1)">
    %e0_28 = cute.get_leaves(%17) : !cute.stride<"(1)">
    %lay_29 = cute.get_layout(%arg2) : !memref_gmem_i8_
    %18 = cute.get_shape(%lay_29) : (!cute.layout<"(?):(1)">) -> !cute.shape<"(?)">
    %e0_30 = cute.get_leaves(%18) : !cute.shape<"(?)">
    %itup_31 = cute.to_int_tuple(%e0_30) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %19 = cute.get_scalars(%itup_31) : !cute.int_tuple<"?">
    %20 = cute.get_stride(%lay_29) : (!cute.layout<"(?):(1)">) -> !cute.stride<"(1)">
    %e0_32 = cute.get_leaves(%20) : !cute.stride<"(1)">
    %lay_33 = cute.get_layout(%arg3) : !memref_gmem_i8_
    %21 = cute.get_shape(%lay_33) : (!cute.layout<"(?):(1)">) -> !cute.shape<"(?)">
    %e0_34 = cute.get_leaves(%21) : !cute.shape<"(?)">
    %itup_35 = cute.to_int_tuple(%e0_34) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %22 = cute.get_scalars(%itup_35) : !cute.int_tuple<"?">
    %23 = cute.get_stride(%lay_33) : (!cute.layout<"(?):(1)">) -> !cute.stride<"(1)">
    %e0_36 = cute.get_leaves(%23) : !cute.stride<"(1)">
    %c1 = arith.constant 1 : index
    %c32 = arith.constant 32 : index
    %c0_i32 = arith.constant 0 : i32
    gpu.launch_func  @kernels::@kernel_cutlass_vote_kernel_tensorptri32gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_False_0 blocks in (%c1, %c1, %c1) threads in (%c32, %c1, %c1)  dynamic_shared_memory_size %c0_i32 args(%arg0 : !memref_gmem_i32_, %arg1 : !memref_gmem_i8_, %arg2 : !memref_gmem_i8_, %arg3 : !memref_gmem_i8_) {use_pdl = false}
    return
  }
}

