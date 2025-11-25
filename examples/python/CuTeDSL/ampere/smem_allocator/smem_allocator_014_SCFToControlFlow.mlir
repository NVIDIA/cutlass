!memref_gmem_f32_ = !cute.memref<f32, gmem, "(8,4):(4,1)">
!memref_gmem_f32_1 = !cute.memref<f32, gmem, "(8,2):(2,1)">
!memref_gmem_f32_2 = !cute.memref<f32, gmem, "(16,2):(2,1)">
!memref_smem_f32_ = !cute.memref<f32, smem, align<32>, "(16,2):(1,16)">
!memref_smem_f32_1 = !cute.memref<f32, smem, align<128>, "(8,4):(1,8)">
!memref_smem_f32_2 = !cute.memref<f32, smem, align<128>, "(8,2):(1,8)">
module attributes {gpu.container_module} {
  gpu.module @kernels {
    func.func public @kernel_cutlass_kernel_05_tensorptrf32gmemo8441_10_tensorptrf32gmemo8221_20_tensorptrf32gmemo16221_0(%arg0: !memref_gmem_f32_, %arg1: !memref_gmem_f32_1, %arg2: !memref_gmem_f32_2) attributes {cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 1, 1, 1>} {
      %cst = arith.constant dense<2.000000e+00> : vector<32xf32>
      %cst_0 = arith.constant dense<1.000000e+00> : vector<16xf32>
      %cst_1 = arith.constant dense<5.000000e-01> : vector<32xf32>
      %c31_i32 = arith.constant 31 : i32
      %c127_i32 = arith.constant 127 : i32
      %0 = cute.static : !cute.layout<"(8,2):(1,8)">
      %1 = cute.static : !cute.layout<"(8,4):(1,8)">
      %c-32_i32 = arith.constant -32 : i32
      %2 = cute.static : !cute.layout<"(16,2):(1,16)">
      %3 = cute.static : !cute.int_tuple<"512">
      %c-128_i32 = arith.constant -128 : i32
      %4 = cute.static : !cute.int_tuple<"4">
      %smem_ptr = cute_nvgpu.arch.get_dyn_smem() : !cute.ptr<i8, smem, align<1024>>
      %ptr = cute.add_offset(%smem_ptr, %4) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"4">) -> !cute.ptr<i8, smem, align<4>>
      %5 = cute.ptrtoint(%ptr) : !cute.ptr<i8, smem, align<4>> to i32
      %6 = arith.addi %5, %c127_i32 : i32
      %7 = arith.andi %6, %c-128_i32 : i32
      %8 = arith.extsi %7 : i32 to i64
      %iv = cute.assume(%8) : (i64) -> !cute.i64<divby 128>
      %9 = cute.inttoptr(%iv) : !cute.i64<divby 128> to !cute.ptr<i8, smem, align<128>>
      %ptr_2 = cute.add_offset(%9, %3) : (!cute.ptr<i8, smem, align<128>>, !cute.int_tuple<"512">) -> !cute.ptr<i8, smem, align<128>>
      %int_tuple = cute.make_int_tuple() : () -> !cute.int_tuple<"688">
      %ptr_3 = cute.add_offset(%9, %int_tuple) : (!cute.ptr<i8, smem, align<128>>, !cute.int_tuple<"688">) -> !cute.ptr<i8, smem, align<16>>
      %10 = cute.ptrtoint(%ptr_3) : !cute.ptr<i8, smem, align<16>> to i32
      %11 = arith.addi %10, %c31_i32 : i32
      %12 = arith.andi %11, %c-32_i32 : i32
      %13 = arith.extsi %12 : i32 to i64
      %iv_4 = cute.assume(%13) : (i64) -> !cute.i64<divby 32>
      %14 = cute.inttoptr(%iv_4) : !cute.i64<divby 32> to !cute.ptr<i8, smem, align<32>>
      %iter = cute.recast_iter(%14) : !cute.ptr<i8, smem, align<32>> to !cute.ptr<f32, smem, align<32>>
      %view = cute.make_view(%iter, %2) : !memref_smem_f32_
      %iter_5 = cute.recast_iter(%9) : !cute.ptr<i8, smem, align<128>> to !cute.ptr<f32, smem, align<128>>
      %view_6 = cute.make_view(%iter_5, %1) : !memref_smem_f32_1
      cute.memref.store_vec %cst_1, %view_6, row_major : !memref_smem_f32_1
      %15 = builtin.unrealized_conversion_cast %iter_5 : !cute.ptr<f32, smem, align<128>> to !llvm.ptr<3>
      %16 = llvm.ptrtoint %15 : !llvm.ptr<3> to i64
      %17 = cute.memref.load_vec %view_6 : !memref_smem_f32_1
      %18 = vector.extract %17[0] : f32 from vector<32xf32>
      %19 = vector.extract %17[1] : f32 from vector<32xf32>
      %20 = vector.extract %17[2] : f32 from vector<32xf32>
      %21 = vector.extract %17[3] : f32 from vector<32xf32>
      %22 = vector.extract %17[4] : f32 from vector<32xf32>
      %23 = vector.extract %17[5] : f32 from vector<32xf32>
      %24 = vector.extract %17[6] : f32 from vector<32xf32>
      %25 = vector.extract %17[7] : f32 from vector<32xf32>
      %26 = vector.extract %17[8] : f32 from vector<32xf32>
      %27 = vector.extract %17[9] : f32 from vector<32xf32>
      %28 = vector.extract %17[10] : f32 from vector<32xf32>
      %29 = vector.extract %17[11] : f32 from vector<32xf32>
      %30 = vector.extract %17[12] : f32 from vector<32xf32>
      %31 = vector.extract %17[13] : f32 from vector<32xf32>
      %32 = vector.extract %17[14] : f32 from vector<32xf32>
      %33 = vector.extract %17[15] : f32 from vector<32xf32>
      %34 = vector.extract %17[16] : f32 from vector<32xf32>
      %35 = vector.extract %17[17] : f32 from vector<32xf32>
      %36 = vector.extract %17[18] : f32 from vector<32xf32>
      %37 = vector.extract %17[19] : f32 from vector<32xf32>
      %38 = vector.extract %17[20] : f32 from vector<32xf32>
      %39 = vector.extract %17[21] : f32 from vector<32xf32>
      %40 = vector.extract %17[22] : f32 from vector<32xf32>
      %41 = vector.extract %17[23] : f32 from vector<32xf32>
      %42 = vector.extract %17[24] : f32 from vector<32xf32>
      %43 = vector.extract %17[25] : f32 from vector<32xf32>
      %44 = vector.extract %17[26] : f32 from vector<32xf32>
      %45 = vector.extract %17[27] : f32 from vector<32xf32>
      %46 = vector.extract %17[28] : f32 from vector<32xf32>
      %47 = vector.extract %17[29] : f32 from vector<32xf32>
      %48 = vector.extract %17[30] : f32 from vector<32xf32>
      gpu.printf "cute.struct.MemRange: raw_ptr(0x%016llx: f32, smem, align<128>) o (8,4):(1,8) = \0A  ( %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, [...] )\0A", %16, %18, %19, %20, %21, %22, %23, %24, %25, %26, %27, %28, %29, %30, %31, %32, %33, %34, %35, %36, %37, %38, %39, %40, %41, %42, %43, %44, %45, %46, %47, %48 : i64, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32
      %49 = cute.memref.load_vec %view_6, row_major : !memref_smem_f32_1
      cute.memref.store_vec %49, %arg0, row_major : !memref_gmem_f32_
      %iter_7 = cute.recast_iter(%ptr_2) : !cute.ptr<i8, smem, align<128>> to !cute.ptr<f32, smem, align<128>>
      %view_8 = cute.make_view(%iter_7, %0) : !memref_smem_f32_2
      cute.memref.store_vec %cst_0, %view_8, row_major : !memref_smem_f32_2
      %50 = builtin.unrealized_conversion_cast %iter_7 : !cute.ptr<f32, smem, align<128>> to !llvm.ptr<3>
      %51 = llvm.ptrtoint %50 : !llvm.ptr<3> to i64
      %52 = cute.memref.load_vec %view_8 : !memref_smem_f32_2
      %53 = vector.extract %52[0] : f32 from vector<16xf32>
      %54 = vector.extract %52[1] : f32 from vector<16xf32>
      %55 = vector.extract %52[2] : f32 from vector<16xf32>
      %56 = vector.extract %52[3] : f32 from vector<16xf32>
      %57 = vector.extract %52[4] : f32 from vector<16xf32>
      %58 = vector.extract %52[5] : f32 from vector<16xf32>
      %59 = vector.extract %52[6] : f32 from vector<16xf32>
      %60 = vector.extract %52[7] : f32 from vector<16xf32>
      %61 = vector.extract %52[8] : f32 from vector<16xf32>
      %62 = vector.extract %52[9] : f32 from vector<16xf32>
      %63 = vector.extract %52[10] : f32 from vector<16xf32>
      %64 = vector.extract %52[11] : f32 from vector<16xf32>
      %65 = vector.extract %52[12] : f32 from vector<16xf32>
      %66 = vector.extract %52[13] : f32 from vector<16xf32>
      %67 = vector.extract %52[14] : f32 from vector<16xf32>
      %68 = vector.extract %52[15] : f32 from vector<16xf32>
      gpu.printf "block of memory: raw_ptr(0x%016llx: f32, smem, align<128>) o (8,2):(1,8) = \0A  ( %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f )\0A", %51, %53, %54, %55, %56, %57, %58, %59, %60, %61, %62, %63, %64, %65, %66, %67, %68 : i64, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32
      %69 = cute.memref.load_vec %view_8, row_major : !memref_smem_f32_2
      cute.memref.store_vec %69, %arg1, row_major : !memref_gmem_f32_1
      cute.memref.store_vec %cst, %view, row_major : !memref_smem_f32_
      %70 = builtin.unrealized_conversion_cast %iter : !cute.ptr<f32, smem, align<32>> to !llvm.ptr<3>
      %71 = llvm.ptrtoint %70 : !llvm.ptr<3> to i64
      %72 = cute.memref.load_vec %view : !memref_smem_f32_
      %73 = vector.extract %72[0] : f32 from vector<32xf32>
      %74 = vector.extract %72[1] : f32 from vector<32xf32>
      %75 = vector.extract %72[2] : f32 from vector<32xf32>
      %76 = vector.extract %72[3] : f32 from vector<32xf32>
      %77 = vector.extract %72[4] : f32 from vector<32xf32>
      %78 = vector.extract %72[5] : f32 from vector<32xf32>
      %79 = vector.extract %72[6] : f32 from vector<32xf32>
      %80 = vector.extract %72[7] : f32 from vector<32xf32>
      %81 = vector.extract %72[8] : f32 from vector<32xf32>
      %82 = vector.extract %72[9] : f32 from vector<32xf32>
      %83 = vector.extract %72[10] : f32 from vector<32xf32>
      %84 = vector.extract %72[11] : f32 from vector<32xf32>
      %85 = vector.extract %72[12] : f32 from vector<32xf32>
      %86 = vector.extract %72[13] : f32 from vector<32xf32>
      %87 = vector.extract %72[14] : f32 from vector<32xf32>
      %88 = vector.extract %72[15] : f32 from vector<32xf32>
      %89 = vector.extract %72[16] : f32 from vector<32xf32>
      %90 = vector.extract %72[17] : f32 from vector<32xf32>
      %91 = vector.extract %72[18] : f32 from vector<32xf32>
      %92 = vector.extract %72[19] : f32 from vector<32xf32>
      %93 = vector.extract %72[20] : f32 from vector<32xf32>
      %94 = vector.extract %72[21] : f32 from vector<32xf32>
      %95 = vector.extract %72[22] : f32 from vector<32xf32>
      %96 = vector.extract %72[23] : f32 from vector<32xf32>
      %97 = vector.extract %72[24] : f32 from vector<32xf32>
      %98 = vector.extract %72[25] : f32 from vector<32xf32>
      %99 = vector.extract %72[26] : f32 from vector<32xf32>
      %100 = vector.extract %72[27] : f32 from vector<32xf32>
      %101 = vector.extract %72[28] : f32 from vector<32xf32>
      %102 = vector.extract %72[29] : f32 from vector<32xf32>
      %103 = vector.extract %72[30] : f32 from vector<32xf32>
      gpu.printf "tensor in smem: raw_ptr(0x%016llx: f32, smem, align<32>) o (16,2):(1,16) = \0A  ( %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, [...] )\0A", %71, %73, %74, %75, %76, %77, %78, %79, %80, %81, %82, %83, %84, %85, %86, %87, %88, %89, %90, %91, %92, %93, %94, %95, %96, %97, %98, %99, %100, %101, %102, %103 : i64, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32
      %104 = cute.memref.load_vec %view, row_major : !memref_smem_f32_
      cute.memref.store_vec %104, %arg2, row_major : !memref_gmem_f32_2
      return
    }
  }
  func.func @cutlass_host_05_Tensorgmemo8441_10_Tensorgmemo8221_20_Tensorgmemo16221(%arg0: !memref_gmem_f32_, %arg1: !memref_gmem_f32_1, %arg2: !memref_gmem_f32_2) attributes {llvm.emit_c_interface} {
    %c1 = arith.constant 1 : index
    %c960_i32 = arith.constant 960 : i32
    gpu.launch_func  @kernels::@kernel_cutlass_kernel_05_tensorptrf32gmemo8441_10_tensorptrf32gmemo8221_20_tensorptrf32gmemo16221_0 blocks in (%c1, %c1, %c1) threads in (%c1, %c1, %c1)  dynamic_shared_memory_size %c960_i32 args(%arg0 : !memref_gmem_f32_, %arg1 : !memref_gmem_f32_1, %arg2 : !memref_gmem_f32_2) {use_pdl = false}
    return
  }
}
