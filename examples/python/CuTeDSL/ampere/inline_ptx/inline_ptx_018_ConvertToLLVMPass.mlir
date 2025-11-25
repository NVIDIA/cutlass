!memref_gmem_i32_ = !cute.memref<i32, gmem, "(?):(1)">
!memref_gmem_i8_ = !cute.memref<i8, gmem, "(?):(1)">
module attributes {gpu.container_module} {
  gpu.module @kernels {
    llvm.func @kernel_cutlass_vote_kernel_tensorptri32gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_False_0(%arg0: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, %arg1: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, %arg2: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, %arg3: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>) attributes {gpu.kernel, nvvm.kernel, nvvm.reqntid = array<i32: 32, 1, 1>} {
      %0 = llvm.mlir.constant(-1 : i32) : i32
      %1 = llvm.mlir.constant(10 : i32) : i32
      %2 = nvvm.read.ptx.sreg.tid.x range <i32, 0, 1024> : i32
      %3 = llvm.icmp "slt" %2, %1 : i32
      %4 = nvvm.vote.ballot.sync %0, %3 : i32
      %5 = llvm.inline_asm has_side_effects asm_dialect = att "{\0A\09\0A            .reg .pred ps;\0A\09\0A            .reg .pred pd;\0A\09\0A            setp.ne.b32 ps, $1, 0;\0A\09\0A            vote.sync.any.pred pd, ps, $2;\0A\09\0A            selp.b32 $0, 1, 0, pd;\0A\09\0A            }", "=r,r,i" %3, %0 : (i1, i32) -> i1
      %6 = llvm.inline_asm has_side_effects asm_dialect = att "{\0A\09\0A            .reg .pred ps;\0A\09\0A            .reg .pred pd;\0A\09\0A            setp.ne.b32 ps, $1, 0;\0A\09\0A            vote.sync.all.pred pd, ps, $2;\0A\09\0A            selp.b32 $0, 1, 0, pd;\0A\09\0A            }", "=r,r,i" %3, %0 : (i1, i32) -> i1
      %7 = llvm.inline_asm has_side_effects asm_dialect = att "{\0A\09\0A            .reg .pred ps;\0A\09\0A            .reg .pred pd;\0A\09\0A            setp.ne.b32 ps, $1, 0;\0A\09\0A            vote.sync.uni.pred pd, ps, $2;\0A\09\0A            selp.b32 $0, 1, 0, pd;\0A\09\0A            }", "=r,r,i" %3, %0 : (i1, i32) -> i1
      %8 = llvm.extractvalue %arg0[1] : !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)> 
      %9 = llvm.extractvalue %8[0] : !llvm.struct<(i32, struct<()>)> 
      %10 = llvm.extractvalue %8[1] : !llvm.struct<(i32, struct<()>)> 
      %11 = llvm.extractvalue %arg0[0] : !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)> 
      %12 = llvm.getelementptr %11[%2] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, i32
      %13 = llvm.ptrtoint %12 : !llvm.ptr<1> to i64
      %14 = llvm.inttoptr %13 : i64 to !llvm.ptr<1>
      llvm.store %4, %14 {alignment = 4 : i64} : i32, !llvm.ptr<1>
      %15 = llvm.zext %5 : i1 to i8
      %16 = llvm.extractvalue %arg1[1] : !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)> 
      %17 = llvm.extractvalue %16[0] : !llvm.struct<(i32, struct<()>)> 
      %18 = llvm.extractvalue %16[1] : !llvm.struct<(i32, struct<()>)> 
      %19 = llvm.extractvalue %arg1[0] : !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)> 
      %20 = llvm.getelementptr %19[%2] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, i8
      %21 = llvm.ptrtoint %20 : !llvm.ptr<1> to i64
      %22 = llvm.inttoptr %21 : i64 to !llvm.ptr<1>
      llvm.store %15, %22 {alignment = 1 : i64} : i8, !llvm.ptr<1>
      %23 = llvm.zext %6 : i1 to i8
      %24 = llvm.extractvalue %arg2[1] : !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)> 
      %25 = llvm.extractvalue %24[0] : !llvm.struct<(i32, struct<()>)> 
      %26 = llvm.extractvalue %24[1] : !llvm.struct<(i32, struct<()>)> 
      %27 = llvm.extractvalue %arg2[0] : !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)> 
      %28 = llvm.getelementptr %27[%2] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, i8
      %29 = llvm.ptrtoint %28 : !llvm.ptr<1> to i64
      %30 = llvm.inttoptr %29 : i64 to !llvm.ptr<1>
      llvm.store %23, %30 {alignment = 1 : i64} : i8, !llvm.ptr<1>
      %31 = llvm.zext %7 : i1 to i8
      %32 = llvm.extractvalue %arg3[1] : !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)> 
      %33 = llvm.extractvalue %32[0] : !llvm.struct<(i32, struct<()>)> 
      %34 = llvm.extractvalue %32[1] : !llvm.struct<(i32, struct<()>)> 
      %35 = llvm.extractvalue %arg3[0] : !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)> 
      %36 = llvm.getelementptr %35[%2] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, i8
      %37 = llvm.ptrtoint %36 : !llvm.ptr<1> to i64
      %38 = llvm.inttoptr %37 : i64 to !llvm.ptr<1>
      llvm.store %31, %38 {alignment = 1 : i64} : i8, !llvm.ptr<1>
      llvm.return
    }
  }
  llvm.func @cutlass_vote_Tensorgmemo1_Tensorgmemo1_Tensorgmemo1_Tensorgmemo1_False(%arg0: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, %arg1: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, %arg2: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, %arg3: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>) attributes {llvm.emit_c_interface} {
    %0 = builtin.unrealized_conversion_cast %arg3 : !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)> to !memref_gmem_i8_
    %1 = builtin.unrealized_conversion_cast %arg2 : !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)> to !memref_gmem_i8_
    %2 = builtin.unrealized_conversion_cast %arg1 : !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)> to !memref_gmem_i8_
    %3 = builtin.unrealized_conversion_cast %arg0 : !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)> to !memref_gmem_i32_
    %4 = llvm.mlir.constant(1 : index) : i64
    %5 = builtin.unrealized_conversion_cast %4 : i64 to index
    %6 = llvm.mlir.constant(32 : index) : i64
    %7 = builtin.unrealized_conversion_cast %6 : i64 to index
    %8 = llvm.mlir.constant(0 : i32) : i32
    gpu.launch_func  @kernels::@kernel_cutlass_vote_kernel_tensorptri32gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_False_0 blocks in (%5, %5, %5) threads in (%7, %5, %5)  dynamic_shared_memory_size %8 args(%3 : !memref_gmem_i32_, %2 : !memref_gmem_i8_, %1 : !memref_gmem_i8_, %0 : !memref_gmem_i8_) {use_pdl = false}
    llvm.return
  }
  llvm.func @_mlir_ciface_cutlass_vote_Tensorgmemo1_Tensorgmemo1_Tensorgmemo1_Tensorgmemo1_False(%arg0: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, %arg1: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, %arg2: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, %arg3: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>) attributes {llvm.emit_c_interface} {
    llvm.call @cutlass_vote_Tensorgmemo1_Tensorgmemo1_Tensorgmemo1_Tensorgmemo1_False(%arg0, %arg1, %arg2, %arg3) : (!llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>) -> ()
    llvm.return
  }
}
