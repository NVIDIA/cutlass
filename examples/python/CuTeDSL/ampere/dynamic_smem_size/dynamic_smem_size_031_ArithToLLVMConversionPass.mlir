module attributes {gpu.container_module} {
  gpu.module @kernels attributes {compute_targets = [#cuda.compute_target<sass, conditional, [sm_90]>]} {
    llvm.func @kernel_cutlass_kernel_no_smem_0() attributes {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, gpu.kernel, nvvm.kernel, nvvm.reqntid = array<i32: 1, 1, 1>} {
      %0 = llvm.mlir.constant(0 : i32) : i32
      %1 = nvvm.read.ptx.sreg.ctaid.x range <i32, 0, 2147483647> : i32
      %2 = llvm.icmp "eq" %1, %0 : i32
      llvm.cond_br %2, ^bb1, ^bb2
    ^bb1:  // pred: ^bb0
      gpu.printf "Hello world\0A"
      llvm.br ^bb2
    ^bb2:  // 2 preds: ^bb0, ^bb1
      llvm.return
    }
  }
  llvm.func @cutlass_launch_kernel2() -> i32 attributes {llvm.emit_c_interface} {
    %0 = llvm.mlir.constant(1 : i32) : i32
    %1 = llvm.mlir.constant(0 : i32) : i32
    %2 = llvm.mlir.constant(0 : i64) : i64
    %3 = llvm.inttoptr %2 : i64 to !llvm.ptr
    %4 = llvm.alloca %0 x !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)> : (i32) -> !llvm.ptr
    %5 = llvm.alloca %0 x !llvm.array<2 x struct<(i32, array<4 x i8>, array<64 x i8>)>> : (i32) -> !llvm.ptr
    %6 = llvm.getelementptr %4[0, 4] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %5, %6 : !llvm.ptr, !llvm.ptr
    %7 = llvm.getelementptr %4[0, 1, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %0, %7 : i32, !llvm.ptr
    %8 = llvm.getelementptr %4[0, 1, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %0, %8 : i32, !llvm.ptr
    %9 = llvm.getelementptr %4[0, 1, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %0, %9 : i32, !llvm.ptr
    %10 = llvm.getelementptr %4[0, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %2, %10 : i64, !llvm.ptr
    %11 = llvm.getelementptr %4[0, 0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %0, %11 : i32, !llvm.ptr
    %12 = llvm.getelementptr %4[0, 0, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %0, %12 : i32, !llvm.ptr
    %13 = llvm.getelementptr %4[0, 0, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %0, %13 : i32, !llvm.ptr
    %14 = llvm.getelementptr %4[0, 5] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %1, %14 : i32, !llvm.ptr
    %15 = llvm.getelementptr %4[0, 3] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>
    llvm.store %3, %15 : !llvm.ptr, !llvm.ptr
    %16 = llvm.alloca %0 x !llvm.array<1 x ptr> : (i32) -> !llvm.ptr
    %17 = builtin.unrealized_conversion_cast %16 : !llvm.ptr to !cuda.launch_cfg<max_attrs = 2>
    %18 = llvm.getelementptr %16[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<1 x ptr>
    llvm.store %4, %18 : !llvm.ptr, !llvm.ptr
    %19 = cuda.launch_ex @kernels::@kernel_cutlass_kernel_no_smem_0<%17> () : !cuda.launch_cfg<max_attrs = 2>, () -> !cuda.result
    %20 = builtin.unrealized_conversion_cast %19 : !cuda.result to i32
    cuda.return_if_error %20 : i32
    llvm.return %1 : i32
  }
  llvm.func @_mlir_ciface_cutlass_launch_kernel2() -> i32 attributes {llvm.emit_c_interface} {
    %0 = llvm.call @cutlass_launch_kernel2() : () -> i32
    llvm.return %0 : i32
  }
}
