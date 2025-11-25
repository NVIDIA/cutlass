module attributes {gpu.container_module} {
  gpu.module @kernels [#nvvm.target<O = 3, chip = "sm_90a">] {
    llvm.func @kernel_cutlass_vote_kernel_tensorptri32gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_False_0(%arg0: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, %arg1: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, %arg2: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, %arg3: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>) attributes {gpu.kernel, nvvm.kernel, nvvm.reqntid = array<i32: 32, 1, 1>} {
      %0 = llvm.mlir.constant(-1 : i32) : i32
      %1 = llvm.mlir.constant(10 : i32) : i32
      %2 = nvvm.read.ptx.sreg.tid.x range <i32, 0, 1024> : i32
      %3 = llvm.icmp "slt" %2, %1 : i32
      %4 = nvvm.vote.ballot.sync %0, %3 : i32
      %5 = llvm.inline_asm has_side_effects asm_dialect = att "{\0A\09\0A            .reg .pred ps;\0A\09\0A            .reg .pred pd;\0A\09\0A            setp.ne.b32 ps, $1, 0;\0A\09\0A            vote.sync.any.pred pd, ps, $2;\0A\09\0A            selp.b32 $0, 1, 0, pd;\0A\09\0A            }", "=r,r,i" %3, %0 : (i1, i32) -> i1
      %6 = llvm.inline_asm has_side_effects asm_dialect = att "{\0A\09\0A            .reg .pred ps;\0A\09\0A            .reg .pred pd;\0A\09\0A            setp.ne.b32 ps, $1, 0;\0A\09\0A            vote.sync.all.pred pd, ps, $2;\0A\09\0A            selp.b32 $0, 1, 0, pd;\0A\09\0A            }", "=r,r,i" %3, %0 : (i1, i32) -> i1
      %7 = llvm.inline_asm has_side_effects asm_dialect = att "{\0A\09\0A            .reg .pred ps;\0A\09\0A            .reg .pred pd;\0A\09\0A            setp.ne.b32 ps, $1, 0;\0A\09\0A            vote.sync.uni.pred pd, ps, $2;\0A\09\0A            selp.b32 $0, 1, 0, pd;\0A\09\0A            }", "=r,r,i" %3, %0 : (i1, i32) -> i1
      %8 = llvm.extractvalue %arg0[0] : !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)> 
      %9 = llvm.getelementptr %8[%2] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, i32
      %10 = llvm.ptrtoint %9 : !llvm.ptr<1> to i64
      %11 = llvm.inttoptr %10 : i64 to !llvm.ptr<1>
      llvm.store %4, %11 {alignment = 4 : i64} : i32, !llvm.ptr<1>
      %12 = llvm.zext %5 : i1 to i8
      %13 = llvm.extractvalue %arg1[0] : !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)> 
      %14 = llvm.getelementptr %13[%2] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, i8
      %15 = llvm.ptrtoint %14 : !llvm.ptr<1> to i64
      %16 = llvm.inttoptr %15 : i64 to !llvm.ptr<1>
      llvm.store %12, %16 {alignment = 1 : i64} : i8, !llvm.ptr<1>
      %17 = llvm.zext %6 : i1 to i8
      %18 = llvm.extractvalue %arg2[0] : !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)> 
      %19 = llvm.getelementptr %18[%2] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, i8
      %20 = llvm.ptrtoint %19 : !llvm.ptr<1> to i64
      %21 = llvm.inttoptr %20 : i64 to !llvm.ptr<1>
      llvm.store %17, %21 {alignment = 1 : i64} : i8, !llvm.ptr<1>
      %22 = llvm.zext %7 : i1 to i8
      %23 = llvm.extractvalue %arg3[0] : !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)> 
      %24 = llvm.getelementptr %23[%2] : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>, i8
      %25 = llvm.ptrtoint %24 : !llvm.ptr<1> to i64
      %26 = llvm.inttoptr %25 : i64 to !llvm.ptr<1>
      llvm.store %22, %26 {alignment = 1 : i64} : i8, !llvm.ptr<1>
      llvm.return
    }
  }
  llvm.func @cutlass_vote_Tensorgmemo1_Tensorgmemo1_Tensorgmemo1_Tensorgmemo1_False(%arg0: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, %arg1: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, %arg2: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, %arg3: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>) attributes {llvm.emit_c_interface} {
    %0 = llvm.mlir.constant(0 : i32) : i32
    %1 = llvm.mlir.constant(32 : index) : i64
    %2 = llvm.mlir.constant(1 : index) : i64
    llvm.inline_asm has_side_effects asm_dialect = att {use_pdl = false} "", ""  : () -> ()
    gpu.launch_func  @kernels::@kernel_cutlass_vote_kernel_tensorptri32gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_False_0 blocks in (%2, %2, %2) threads in (%1, %2, %2) : i64 dynamic_shared_memory_size %0 args(%arg0 : !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, %arg1 : !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, %arg2 : !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, %arg3 : !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>)
    llvm.return
  }
  llvm.func @_mlir_ciface_cutlass_vote_Tensorgmemo1_Tensorgmemo1_Tensorgmemo1_Tensorgmemo1_False(%arg0: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, %arg1: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, %arg2: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, %arg3: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>) attributes {llvm.emit_c_interface} {
    llvm.call @cutlass_vote_Tensorgmemo1_Tensorgmemo1_Tensorgmemo1_Tensorgmemo1_False(%arg0, %arg1, %arg2, %arg3) : (!llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>) -> ()
    llvm.return
  }
}
