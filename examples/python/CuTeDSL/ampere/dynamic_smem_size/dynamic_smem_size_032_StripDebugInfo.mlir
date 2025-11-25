gpu.module @kernels [#nvvm.target<O = 3, chip = "sm_90a">] {
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
