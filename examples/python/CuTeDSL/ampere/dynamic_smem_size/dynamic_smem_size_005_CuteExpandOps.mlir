module attributes {gpu.container_module} {
  gpu.module @kernels {
    cuda.kernel @kernel_cutlass_kernel_no_smem_0() attributes {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 1, 1, 1>} {
      %0 = nvvm.read.ptx.sreg.ctaid.x : i32
      %1 = nvvm.read.ptx.sreg.ctaid.y : i32
      %2 = nvvm.read.ptx.sreg.ctaid.z : i32
      %c0_i32 = arith.constant 0 : i32
      %3 = arith.cmpi eq, %0, %c0_i32 : i32
      scf.if %3 {
        gpu.printf "Hello world\0A"
      }
      return
    }
  }
  func.func @cutlass_launch_kernel2() -> i32 attributes {llvm.emit_c_interface} {
    %c0_i32 = arith.constant 0 : i32
    %c0_i64 = arith.constant 0 : i64
    %0 = cuda.cast %c0_i64 : i64 -> !cuda.stream
    %1 = arith.extsi %c0_i32 : i32 to i64
    %c1_i32 = arith.constant 1 : i32
    %2 = cuda.launch_cfg.create<max_attrs = 2 : i32> (blockDim = (%c1_i32, %c1_i32, %c1_i32), dynamicSmemBytes = %1, gridDim = (%c1_i32, %c1_i32, %c1_i32), stream = %0) : i32, i32, i32, i64, i32, i32, i32, !cuda.stream -> !cuda.launch_cfg<max_attrs = 2>
    %3 = cuda.launch_ex @kernels::@kernel_cutlass_kernel_no_smem_0<%2> () : !cuda.launch_cfg<max_attrs = 2>, () -> !cuda.result
    %4 = cuda.cast %3 : !cuda.result -> i32
    cuda.return_if_error %4 : i32
    %c0_i32_0 = arith.constant 0 : i32
    return %c0_i32_0 : i32
  }
}
