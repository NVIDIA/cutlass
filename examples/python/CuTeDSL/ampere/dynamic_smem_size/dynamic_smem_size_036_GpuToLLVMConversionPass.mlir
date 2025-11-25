module attributes {gpu.container_module} {
  gpu.module @kernels [#nvvm.target<O = 3, chip = "sm_90a">] {
    llvm.mlir.global internal constant @printfFormat_0("Hello world\0A\00") {addr_space = 0 : i32}
    llvm.func @vprintf(!llvm.ptr, !llvm.ptr) -> i32
    llvm.func @kernel_cutlass_kernel_no_smem_0() attributes {gpu.kernel, nvvm.kernel, nvvm.reqntid = array<i32: 1, 1, 1>} {
      %0 = llvm.mlir.constant(1 : index) : i64
      %1 = llvm.mlir.addressof @printfFormat_0 : !llvm.ptr
      %2 = llvm.mlir.constant(0 : i32) : i32
      %3 = nvvm.read.ptx.sreg.ctaid.x range <i32, 0, 2147483647> : i32
      %4 = llvm.icmp "eq" %3, %2 : i32
      llvm.cond_br %4, ^bb1, ^bb2
    ^bb1:  // pred: ^bb0
      %5 = llvm.getelementptr %1[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<13 x i8>
      %6 = llvm.alloca %0 x !llvm.struct<()> : (i64) -> !llvm.ptr
      %7 = llvm.call @vprintf(%5, %6) : (!llvm.ptr, !llvm.ptr) -> i32
      llvm.br ^bb2
    ^bb2:  // 2 preds: ^bb0, ^bb1
      llvm.return
    }
  }
  llvm.func @cutlass_launch_kernel2() attributes {llvm.emit_c_interface} {
    %0 = llvm.mlir.constant(0 : i32) : i32
    %1 = llvm.mlir.constant(1 : index) : i64
    llvm.inline_asm has_side_effects asm_dialect = att {use_pdl = false} "", ""  : () -> ()
    gpu.launch_func  @kernels::@kernel_cutlass_kernel_no_smem_0 blocks in (%1, %1, %1) threads in (%1, %1, %1) : i64 dynamic_shared_memory_size %0 
    llvm.return
  }
  llvm.func @_mlir_ciface_cutlass_launch_kernel2() attributes {llvm.emit_c_interface} {
    llvm.call @cutlass_launch_kernel2() : () -> ()
    llvm.return
  }
}
