

module attributes {gpu.container_module} {
  gpu.module @kernels {
    func.func public @kernel_cutlass__empty_kernel_cutlassutilshardware_infoHardwareInfo_object_at__0() attributes {cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 1, 1, 1>} {
      return
    }
  }
  func.func @cutlass__host_function_cutlassutilshardware_infoHardwareInfo_object_at_() attributes {llvm.emit_c_interface} {
    %c1 = arith.constant 1 : index
    %c0_i32 = arith.constant 0 : i32
    gpu.launch_func  @kernels::@kernel_cutlass__empty_kernel_cutlassutilshardware_infoHardwareInfo_object_at__0 blocks in (%c1, %c1, %c1) threads in (%c1, %c1, %c1)  dynamic_shared_memory_size %c0_i32  {use_pdl = false}
    return
  }
}

