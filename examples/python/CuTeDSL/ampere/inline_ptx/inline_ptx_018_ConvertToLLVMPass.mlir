module attributes {gpu.container_module} {
  gpu.module @kernels {
    llvm.func @kernel_cutlass_vote_kernel_tensorptri32gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_False_0(%arg0: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, %arg1: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, %arg2: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, %arg3: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>) attributes {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, gpu.kernel, nvvm.kernel, nvvm.reqntid = array<i32: 32, 1, 1>} {
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
  llvm.func @cutlass_vote_Tensorgmemo1_Tensorgmemo1_Tensorgmemo1_Tensorgmemo1_False(%arg0: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, %arg1: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, %arg2: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, %arg3: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>) -> i32 attributes {llvm.emit_c_interface} {
    %0 = llvm.mlir.constant(1 : i32) : i32
    %1 = llvm.mlir.constant(32 : i32) : i32
    %2 = llvm.mlir.constant(0 : i32) : i32
    %3 = llvm.mlir.constant(0 : i64) : i64
    %4 = llvm.inttoptr %3 : i64 to !llvm.ptr
    %5 = llvm.mlir.constant(1 : i32) : i32
    %6 = llvm.alloca %5 x !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)> : (i32) -> !llvm.ptr
    %7 = llvm.alloca %5 x !llvm.array<2 x struct<(i32, array<4 x i8>, array<64 x i8>)>> : (i32) -> !llvm.ptr
    %8 = llvm.getelementptr %6[0, 4] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %7, %8 : !llvm.ptr, !llvm.ptr
    %9 = llvm.getelementptr %6[0, 1, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %1, %9 : i32, !llvm.ptr
    %10 = llvm.getelementptr %6[0, 1, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %0, %10 : i32, !llvm.ptr
    %11 = llvm.getelementptr %6[0, 1, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %0, %11 : i32, !llvm.ptr
    %12 = llvm.getelementptr %6[0, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %3, %12 : i64, !llvm.ptr
    %13 = llvm.getelementptr %6[0, 0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %0, %13 : i32, !llvm.ptr
    %14 = llvm.getelementptr %6[0, 0, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %0, %14 : i32, !llvm.ptr
    %15 = llvm.getelementptr %6[0, 0, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %0, %15 : i32, !llvm.ptr
    %16 = llvm.getelementptr %6[0, 5] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    %17 = llvm.mlir.constant(0 : i32) : i32
    llvm.store %17, %16 : i32, !llvm.ptr
    %18 = llvm.getelementptr %6[0, 3] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %4, %18 : !llvm.ptr, !llvm.ptr
    %19 = llvm.alloca %5 x !llvm.array<1 x ptr> : (i32) -> !llvm.ptr
    %20 = llvm.getelementptr %19[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<1 x ptr>
    llvm.store %6, %20 : !llvm.ptr, !llvm.ptr
    %21 = builtin.unrealized_conversion_cast %19 : !llvm.ptr to !cuda.launch_cfg<max_attrs = 2>
    %22 = cuda.launch_ex @kernels::@kernel_cutlass_vote_kernel_tensorptri32gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_False_0<%21> (%arg0, %arg1, %arg2, %arg3) : !cuda.launch_cfg<max_attrs = 2>, (!llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>) -> !cuda.result
    %23 = builtin.unrealized_conversion_cast %22 : !cuda.result to i32
    cuda.return_if_error %23 : i32
    llvm.return %2 : i32
  }
  llvm.func @_mlir_ciface_cutlass_vote_Tensorgmemo1_Tensorgmemo1_Tensorgmemo1_Tensorgmemo1_False(%arg0: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, %arg1: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, %arg2: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, %arg3: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>) -> i32 attributes {llvm.emit_c_interface} {
    %0 = llvm.call @cutlass_vote_Tensorgmemo1_Tensorgmemo1_Tensorgmemo1_Tensorgmemo1_False(%arg0, %arg1, %arg2, %arg3) : (!llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>) -> i32
    llvm.return %0 : i32
  }
}
