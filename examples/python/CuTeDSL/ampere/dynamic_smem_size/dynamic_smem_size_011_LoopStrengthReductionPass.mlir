module attributes {gpu.container_module} {
  gpu.module @kernels {
    func.func public @kernel_cutlass_kernel_no_smem_0() attributes {cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 1, 1, 1>} {
      %c0_i32 = arith.constant 0 : i32
      %0 = nvvm.read.ptx.sreg.ctaid.x range <i32, 0, 2147483647> : i32
      %1 = arith.cmpi eq, %0, %c0_i32 : i32
      scf.if %1 {
        gpu.printf "Hello world\0A"
      }
      return
    }
  }
  func.func @cutlass_launch_kernel2() attributes {llvm.emit_c_interface} {
    %c1 = arith.constant 1 : index
    %c0_i32 = arith.constant 0 : i32
    gpu.launch_func  @kernels::@kernel_cutlass_kernel_no_smem_0 blocks in (%c1, %c1, %c1) threads in (%c1, %c1, %c1)  dynamic_shared_memory_size %c0_i32  {use_pdl = false}
    return
  }
}
