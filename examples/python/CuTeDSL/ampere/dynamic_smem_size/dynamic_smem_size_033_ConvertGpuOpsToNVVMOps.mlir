gpu.module @kernels attributes {compute_targets = [#cuda.compute_target<sass, conditional, [sm_90]>]} {
  llvm.mlir.global internal constant @printfFormat_0("Hello world\0A\00") {addr_space = 0 : i32}
  llvm.func @vprintf(!llvm.ptr, !llvm.ptr) -> i32
  llvm.func @kernel_cutlass_kernel_no_smem_0() attributes {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, gpu.kernel, nvvm.kernel, nvvm.reqntid = array<i32: 1, 1, 1>} {
    %0 = llvm.mlir.constant(0 : i32) : i32
    %1 = nvvm.read.ptx.sreg.ctaid.x range <i32, 0, 2147483647> : i32
    %2 = llvm.icmp "eq" %1, %0 : i32
    llvm.cond_br %2, ^bb1, ^bb2
  ^bb1:  // pred: ^bb0
    %3 = llvm.mlir.addressof @printfFormat_0 : !llvm.ptr
    %4 = llvm.getelementptr %3[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<13 x i8>
    %5 = llvm.mlir.constant(1 : index) : i64
    %6 = llvm.alloca %5 x !llvm.struct<()> : (i64) -> !llvm.ptr
    %7 = llvm.call @vprintf(%4, %6) : (!llvm.ptr, !llvm.ptr) -> i32
    llvm.br ^bb2
  ^bb2:  // 2 preds: ^bb0, ^bb1
    llvm.return
  }
}
