module attributes {gpu.container_module} {
  gpu.module @kernels attributes {compute_targets = [#cuda.compute_target<sass, conditional, [sm_90]>]} {
    llvm.func @kernel_cutlass_vote_kernel_tensorptri32gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_False_0(%arg0: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, %arg1: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, %arg2: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, %arg3: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>) attributes {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, gpu.kernel, nvvm.kernel, nvvm.reqntid = array<i32: 32, 1, 1>} {
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
  llvm.func @cutlass_vote_Tensorgmemo1_Tensorgmemo1_Tensorgmemo1_Tensorgmemo1_False(%arg0: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, %arg1: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, %arg2: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, %arg3: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>) -> i32 attributes {llvm.emit_c_interface} {
    %0 = llvm.mlir.constant(1 : i32) : i32
    %1 = llvm.mlir.constant(32 : i32) : i32
    %2 = llvm.mlir.constant(0 : i32) : i32
    %3 = llvm.mlir.constant(0 : i64) : i64
    %4 = llvm.inttoptr %3 : i64 to !llvm.ptr
    %5 = llvm.alloca %0 x !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)> : (i32) -> !llvm.ptr
    %6 = llvm.alloca %0 x !llvm.array<2 x struct<(i32, array<4 x i8>, array<64 x i8>)>> : (i32) -> !llvm.ptr
    %7 = llvm.getelementptr %5[0, 4] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %6, %7 : !llvm.ptr, !llvm.ptr
    %8 = llvm.getelementptr %5[0, 1, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %1, %8 : i32, !llvm.ptr
    %9 = llvm.getelementptr %5[0, 1, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %0, %9 : i32, !llvm.ptr
    %10 = llvm.getelementptr %5[0, 1, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %0, %10 : i32, !llvm.ptr
    %11 = llvm.getelementptr %5[0, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %3, %11 : i64, !llvm.ptr
    %12 = llvm.getelementptr %5[0, 0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %0, %12 : i32, !llvm.ptr
    %13 = llvm.getelementptr %5[0, 0, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %0, %13 : i32, !llvm.ptr
    %14 = llvm.getelementptr %5[0, 0, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %0, %14 : i32, !llvm.ptr
    %15 = llvm.getelementptr %5[0, 5] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %2, %15 : i32, !llvm.ptr
    %16 = llvm.getelementptr %5[0, 3] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %4, %16 : !llvm.ptr, !llvm.ptr
    %17 = llvm.alloca %0 x !llvm.array<1 x ptr> : (i32) -> !llvm.ptr
    %18 = llvm.getelementptr %17[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<1 x ptr>
    llvm.store %5, %18 : !llvm.ptr, !llvm.ptr
    %19 = builtin.unrealized_conversion_cast %17 : !llvm.ptr to !cuda.launch_cfg<max_attrs = 2>
    %20 = cuda.launch_ex @kernels::@kernel_cutlass_vote_kernel_tensorptri32gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_False_0<%19> (%arg0, %arg1, %arg2, %arg3) : !cuda.launch_cfg<max_attrs = 2>, (!llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>) -> !cuda.result
    %21 = builtin.unrealized_conversion_cast %20 : !cuda.result to i32
    cuda.return_if_error %21 : i32
    llvm.return %2 : i32
  }
  llvm.func @_mlir_ciface_cutlass_vote_Tensorgmemo1_Tensorgmemo1_Tensorgmemo1_Tensorgmemo1_False(%arg0: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, %arg1: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, %arg2: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, %arg3: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>) -> i32 attributes {llvm.emit_c_interface} {
    %0 = llvm.call @cutlass_vote_Tensorgmemo1_Tensorgmemo1_Tensorgmemo1_Tensorgmemo1_False(%arg0, %arg1, %arg2, %arg3) : (!llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>) -> i32
    llvm.return %0 : i32
  }
}
