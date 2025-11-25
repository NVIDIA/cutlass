module attributes {gpu.container_module} {
  gpu.module @kernels {
    llvm.func @kernel_cutlass_kernel_no_smem_0() attributes {gpu.kernel, nvvm.kernel, nvvm.reqntid = array<i32: 1, 1, 1>} {
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
  llvm.func @cutlass_launch_kernel2() attributes {llvm.emit_c_interface} {
    %0 = llvm.mlir.constant(0 : i32) : i32
    %1 = llvm.mlir.constant(1 : index) : i64
    %2 = builtin.unrealized_conversion_cast %1 : i64 to index
    gpu.launch_func  @kernels::@kernel_cutlass_kernel_no_smem_0 blocks in (%2, %2, %2) threads in (%2, %2, %2)  dynamic_shared_memory_size %0  {use_pdl = false}
    llvm.return
  }
  llvm.func @_mlir_ciface_cutlass_launch_kernel2() attributes {llvm.emit_c_interface} {
    llvm.call @cutlass_launch_kernel2() : () -> ()
    llvm.return
  }
}
