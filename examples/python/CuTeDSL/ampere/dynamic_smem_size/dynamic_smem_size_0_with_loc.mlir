

!memref_smem_f16_ = !cute.memref<f16, smem, align<64>, "(32,16):(1,32)">
module attributes {gpu.container_module} {
  gpu.module @kernels {
    func.func public @kernel_cutlass_kernel_0() attributes {cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 1, 1, 1>} {
      %smem_ptr = cute_nvgpu.arch.get_dyn_smem() : !cute.ptr<i8, smem, align<1024>>
      %int_tuple = cute.make_int_tuple() : () -> !cute.int_tuple<"264">
      %ptr = cute.add_offset(%smem_ptr, %int_tuple) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"264">) -> !cute.ptr<i8, smem, align<8>>
      %smem_size = cute_nvgpu.arch.get_dyn_smem_size() : i32
      %c264_i32 = arith.constant 264 : i32
      %0 = arith.cmpi sge, %smem_size, %c264_i32 : i32
      cf.assert %0, "Allocation failed: shared memory allocation exceeds available memory set in kernel launch. Allocated bytes: 264 bytes. Please reduce the allocation or set a larger smem size in kernel launch."
      %int_tuple_0 = cute.make_int_tuple() : () -> !cute.int_tuple<"0">
      %ptr_1 = cute.add_offset(%smem_ptr, %int_tuple_0) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, smem, align<1024>>
      %int_tuple_2 = cute.make_int_tuple() : () -> !cute.int_tuple<"256">
      %ptr_3 = cute.add_offset(%smem_ptr, %int_tuple_2) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"256">) -> !cute.ptr<i8, smem, align<256>>
      %iter = cute.recast_iter(%ptr_3) : !cute.ptr<i8, smem, align<256>> to !cute.ptr<i32, smem, align<256>>
      %int_tuple_4 = cute.make_int_tuple() : () -> !cute.int_tuple<"260">
      %ptr_5 = cute.add_offset(%smem_ptr, %int_tuple_4) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"260">) -> !cute.ptr<i8, smem, align<4>>
      %iter_6 = cute.recast_iter(%ptr_5) : !cute.ptr<i8, smem, align<4>> to !cute.ptr<i8, smem, align<4>>
      %1 = cute.ptrtoint(%ptr) : !cute.ptr<i8, smem, align<8>> to i32
      %c64_i32 = arith.constant 64 : i32
      %2 = arith.addi %1, %c64_i32 : i32
      %c1_i32 = arith.constant 1 : i32
      %3 = arith.subi %2, %c1_i32 : i32
      %c-64_i32 = arith.constant -64 : i32
      %4 = arith.andi %3, %c-64_i32 : i32
      %5 = arith.extsi %4 : i32 to i64
      %iv = cute.assume(%5) : (i64) -> !cute.i64<divby 64>
      %6 = cute.inttoptr(%iv) : !cute.i64<divby 64> to !cute.ptr<i8, smem, align<64>>
      %int_tuple_7 = cute.make_int_tuple() : () -> !cute.int_tuple<"512">
      %ptr_8 = cute.add_offset(%6, %int_tuple_7) : (!cute.ptr<i8, smem, align<64>>, !cute.int_tuple<"512">) -> !cute.ptr<i8, smem, align<64>>
      %smem_size_9 = cute_nvgpu.arch.get_dyn_smem_size() : i32
      %c832_i32 = arith.constant 832 : i32
      %7 = arith.cmpi sge, %smem_size_9, %c832_i32 : i32
      cf.assert %7, "Allocation failed: shared memory allocation exceeds available memory set in kernel launch. Allocated bytes: 832 bytes. Please reduce the allocation or set a larger smem size in kernel launch."
      %int_tuple_10 = cute.make_int_tuple() : () -> !cute.int_tuple<"512">
      %ptr_11 = cute.add_offset(%ptr_8, %int_tuple_10) : (!cute.ptr<i8, smem, align<64>>, !cute.int_tuple<"512">) -> !cute.ptr<i8, smem, align<64>>
      %smem_size_12 = cute_nvgpu.arch.get_dyn_smem_size() : i32
      %c1344_i32 = arith.constant 1344 : i32
      %8 = arith.cmpi sge, %smem_size_12, %c1344_i32 : i32
      cf.assert %8, "Allocation failed: shared memory allocation exceeds available memory set in kernel launch. Allocated bytes: 1344 bytes. Please reduce the allocation or set a larger smem size in kernel launch."
      %iter_13 = cute.recast_iter(%ptr_8) : !cute.ptr<i8, smem, align<64>> to !cute.ptr<i32, smem, align<64>>
      %shape = cute.make_shape() : () -> !cute.shape<"(32,16)">
      %lay = cute.make_layout(%shape) : !cute.layout<"(32,16):(1,32)">
      %coord = cute.make_coord() : () -> !cute.coord<"0">
      %idx = cute.crd2idx(%coord, %lay) : (!cute.coord<"0">, !cute.layout<"(32,16):(1,32)">) -> !cute.int_tuple<"0">
      %e0 = cute.get_leaves(%idx) : !cute.int_tuple<"0">
      %cosz = cute.cosize(%lay) : (!cute.layout<"(32,16):(1,32)">) -> !cute.int_tuple<"512">
      %e0_14 = cute.get_leaves(%cosz) : !cute.int_tuple<"512">
      %int_tuple_15 = cute.make_int_tuple() : () -> !cute.int_tuple<"1024">
      %ptr_16 = cute.add_offset(%ptr_11, %int_tuple_15) : (!cute.ptr<i8, smem, align<64>>, !cute.int_tuple<"1024">) -> !cute.ptr<i8, smem, align<64>>
      %smem_size_17 = cute_nvgpu.arch.get_dyn_smem_size() : i32
      %c2368_i32 = arith.constant 2368 : i32
      %9 = arith.cmpi sge, %smem_size_17, %c2368_i32 : i32
      cf.assert %9, "Allocation failed: shared memory allocation exceeds available memory set in kernel launch. Allocated bytes: 2368 bytes. Please reduce the allocation or set a larger smem size in kernel launch."
      %iter_18 = cute.recast_iter(%ptr_11) : !cute.ptr<i8, smem, align<64>> to !cute.ptr<f16, smem, align<64>>
      %view = cute.make_view(%iter_18, %lay) : !memref_smem_f16_
      %iter_19 = cute.get_iter(%view) : !memref_smem_f16_
      return
    }
  }
  func.func @cutlass_launch_kernel1() attributes {llvm.emit_c_interface} {
    %c1 = arith.constant 1 : index
    %c2368_i32 = arith.constant 2368 : i32
    gpu.launch_func  @kernels::@kernel_cutlass_kernel_0 blocks in (%c1, %c1, %c1) threads in (%c1, %c1, %c1)  dynamic_shared_memory_size %c2368_i32  {use_pdl = false}
    return
  }
}



module attributes {gpu.container_module} {
  gpu.module @kernels {
    func.func public @kernel_cutlass_kernel_no_smem_0() attributes {cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 1, 1, 1>} {
      %0 = nvvm.read.ptx.sreg.ctaid.x : i32
      %1 = nvvm.read.ptx.sreg.ctaid.y : i32
      %2 = nvvm.read.ptx.sreg.ctaid.z : i32
      %c0_i32 = arith.constant 0 : i32
      %3 = arith.cmpi eq, %0, %c0_i32 : i32
      scf.if %3 {
        cute.print("Hello world\0A", ) : 
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

