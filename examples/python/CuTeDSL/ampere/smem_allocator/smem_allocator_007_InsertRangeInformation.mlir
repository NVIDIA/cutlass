!memref_gmem_f32_ = !cute.memref<f32, gmem, "(8,4):(4,1)">
!memref_gmem_f32_1 = !cute.memref<f32, gmem, "(8,2):(2,1)">
!memref_gmem_f32_2 = !cute.memref<f32, gmem, "(16,2):(2,1)">
!memref_smem_f32_ = !cute.memref<f32, smem, align<32>, "(16,2):(1,16)">
!memref_smem_f32_1 = !cute.memref<f32, smem, align<128>, "(8,4):(1,8)">
!memref_smem_f32_2 = !cute.memref<f32, smem, align<128>, "(8,2):(1,8)">
module attributes {gpu.container_module} {
  gpu.module @kernels {
    cuda.kernel @kernel_cutlass_kernel_05_tensorptrf32gmemo8441_10_tensorptrf32gmemo8221_20_tensorptrf32gmemo16221_0(%arg0: !memref_gmem_f32_, %arg1: !memref_gmem_f32_1, %arg2: !memref_gmem_f32_2) attributes {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 1, 1, 1>} {
      %smem_ptr = cute_nvgpu.arch.get_dyn_smem() : !cute.ptr<i8, smem, align<1024>>
      %0 = cute.static : !cute.int_tuple<"4">
      %ptr = cute.add_offset(%smem_ptr, %0) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"4">) -> !cute.ptr<i8, smem, align<4>>
      %1 = cute.ptrtoint(%ptr) : !cute.ptr<i8, smem, align<4>> to i32
      %c128_i32 = arith.constant 128 : i32
      %2 = arith.addi %1, %c128_i32 : i32
      %c1_i32 = arith.constant 1 : i32
      %3 = arith.subi %2, %c1_i32 : i32
      %c-128_i32 = arith.constant -128 : i32
      %4 = arith.andi %3, %c-128_i32 : i32
      %5 = arith.extsi %4 : i32 to i64
      %iv = cute.assume(%5) : (i64) -> !cute.i64<divby 128>
      %6 = cute.inttoptr(%iv) : !cute.i64<divby 128> to !cute.ptr<i8, smem, align<128>>
      %7 = cute.static : !cute.int_tuple<"512">
      %ptr_0 = cute.add_offset(%6, %7) : (!cute.ptr<i8, smem, align<128>>, !cute.int_tuple<"512">) -> !cute.ptr<i8, smem, align<128>>
      %8 = cute.static : !cute.int_tuple<"0">
      %ptr_1 = cute.add_offset(%6, %8) : (!cute.ptr<i8, smem, align<128>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, smem, align<128>>
      %9 = cute.static : !cute.int_tuple<"64">
      %ptr_2 = cute.add_offset(%ptr_0, %9) : (!cute.ptr<i8, smem, align<128>>, !cute.int_tuple<"64">) -> !cute.ptr<i8, smem, align<64>>
      %10 = cute.static : !cute.int_tuple<"112">
      %ptr_3 = cute.add_offset(%ptr_2, %10) : (!cute.ptr<i8, smem, align<64>>, !cute.int_tuple<"112">) -> !cute.ptr<i8, smem, align<16>>
      %11 = cute.static : !cute.layout<"(16,2):(1,16)">
      %12 = cute.ptrtoint(%ptr_3) : !cute.ptr<i8, smem, align<16>> to i32
      %c32_i32 = arith.constant 32 : i32
      %13 = arith.addi %12, %c32_i32 : i32
      %14 = arith.subi %13, %c1_i32 : i32
      %c-32_i32 = arith.constant -32 : i32
      %15 = arith.andi %14, %c-32_i32 : i32
      %16 = arith.extsi %15 : i32 to i64
      %iv_4 = cute.assume(%16) : (i64) -> !cute.i64<divby 32>
      %17 = cute.inttoptr(%iv_4) : !cute.i64<divby 32> to !cute.ptr<i8, smem, align<32>>
      %iter = cute.recast_iter(%17) : !cute.ptr<i8, smem, align<32>> to !cute.ptr<f32, smem, align<32>>
      %view = cute.make_view(%iter, %11) : !memref_smem_f32_
      %18 = cute.static : !cute.layout<"(8,4):(1,8)">
      %iter_5 = cute.recast_iter(%ptr_1) : !cute.ptr<i8, smem, align<128>> to !cute.ptr<f32, smem, align<128>>
      %view_6 = cute.make_view(%iter_5, %18) : !memref_smem_f32_1
      %cst = arith.constant 5.000000e-01 : f32
      %19 = vector.splat %cst : vector<32xf32>
      cute.memref.store_vec %19, %view_6 : !memref_smem_f32_1
      %iter_7 = cute.get_iter(%view_6) : !memref_smem_f32_1
      %20 = builtin.unrealized_conversion_cast %iter_7 : !cute.ptr<f32, smem, align<128>> to !llvm.ptr<3>
      %21 = llvm.ptrtoint %20 : !llvm.ptr<3> to i64
      %22 = cute.memref.load_vec %view_6 : !memref_smem_f32_1
      %23 = vector.extract %22[0] : f32 from vector<32xf32>
      %24 = vector.extract %22[1] : f32 from vector<32xf32>
      %25 = vector.extract %22[2] : f32 from vector<32xf32>
      %26 = vector.extract %22[3] : f32 from vector<32xf32>
      %27 = vector.extract %22[4] : f32 from vector<32xf32>
      %28 = vector.extract %22[5] : f32 from vector<32xf32>
      %29 = vector.extract %22[6] : f32 from vector<32xf32>
      %30 = vector.extract %22[7] : f32 from vector<32xf32>
      %31 = vector.extract %22[8] : f32 from vector<32xf32>
      %32 = vector.extract %22[9] : f32 from vector<32xf32>
      %33 = vector.extract %22[10] : f32 from vector<32xf32>
      %34 = vector.extract %22[11] : f32 from vector<32xf32>
      %35 = vector.extract %22[12] : f32 from vector<32xf32>
      %36 = vector.extract %22[13] : f32 from vector<32xf32>
      %37 = vector.extract %22[14] : f32 from vector<32xf32>
      %38 = vector.extract %22[15] : f32 from vector<32xf32>
      %39 = vector.extract %22[16] : f32 from vector<32xf32>
      %40 = vector.extract %22[17] : f32 from vector<32xf32>
      %41 = vector.extract %22[18] : f32 from vector<32xf32>
      %42 = vector.extract %22[19] : f32 from vector<32xf32>
      %43 = vector.extract %22[20] : f32 from vector<32xf32>
      %44 = vector.extract %22[21] : f32 from vector<32xf32>
      %45 = vector.extract %22[22] : f32 from vector<32xf32>
      %46 = vector.extract %22[23] : f32 from vector<32xf32>
      %47 = vector.extract %22[24] : f32 from vector<32xf32>
      %48 = vector.extract %22[25] : f32 from vector<32xf32>
      %49 = vector.extract %22[26] : f32 from vector<32xf32>
      %50 = vector.extract %22[27] : f32 from vector<32xf32>
      %51 = vector.extract %22[28] : f32 from vector<32xf32>
      %52 = vector.extract %22[29] : f32 from vector<32xf32>
      %53 = vector.extract %22[30] : f32 from vector<32xf32>
      gpu.printf "cute.struct.MemRange: raw_ptr(0x%016llx: f32, smem, align<128>) o (8,4):(1,8) = \0A  ( %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, [...] )\0A", %21, %23, %24, %25, %26, %27, %28, %29, %30, %31, %32, %33, %34, %35, %36, %37, %38, %39, %40, %41, %42, %43, %44, %45, %46, %47, %48, %49, %50, %51, %52, %53 : i64, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32
      %54 = cute.memref.load_vec %view_6 : !memref_smem_f32_1
      cute.memref.store_vec %54, %arg0 : !memref_gmem_f32_
      %55 = cute.static : !cute.layout<"(8,2):(1,8)">
      %iter_8 = cute.recast_iter(%ptr_0) : !cute.ptr<i8, smem, align<128>> to !cute.ptr<f32, smem, align<128>>
      %view_9 = cute.make_view(%iter_8, %55) : !memref_smem_f32_2
      %cst_10 = arith.constant 1.000000e+00 : f32
      %56 = vector.splat %cst_10 : vector<16xf32>
      cute.memref.store_vec %56, %view_9 : !memref_smem_f32_2
      %iter_11 = cute.get_iter(%view_9) : !memref_smem_f32_2
      %57 = builtin.unrealized_conversion_cast %iter_11 : !cute.ptr<f32, smem, align<128>> to !llvm.ptr<3>
      %58 = llvm.ptrtoint %57 : !llvm.ptr<3> to i64
      %59 = cute.memref.load_vec %view_9 : !memref_smem_f32_2
      %60 = vector.extract %59[0] : f32 from vector<16xf32>
      %61 = vector.extract %59[1] : f32 from vector<16xf32>
      %62 = vector.extract %59[2] : f32 from vector<16xf32>
      %63 = vector.extract %59[3] : f32 from vector<16xf32>
      %64 = vector.extract %59[4] : f32 from vector<16xf32>
      %65 = vector.extract %59[5] : f32 from vector<16xf32>
      %66 = vector.extract %59[6] : f32 from vector<16xf32>
      %67 = vector.extract %59[7] : f32 from vector<16xf32>
      %68 = vector.extract %59[8] : f32 from vector<16xf32>
      %69 = vector.extract %59[9] : f32 from vector<16xf32>
      %70 = vector.extract %59[10] : f32 from vector<16xf32>
      %71 = vector.extract %59[11] : f32 from vector<16xf32>
      %72 = vector.extract %59[12] : f32 from vector<16xf32>
      %73 = vector.extract %59[13] : f32 from vector<16xf32>
      %74 = vector.extract %59[14] : f32 from vector<16xf32>
      %75 = vector.extract %59[15] : f32 from vector<16xf32>
      gpu.printf "block of memory: raw_ptr(0x%016llx: f32, smem, align<128>) o (8,2):(1,8) = \0A  ( %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f )\0A", %58, %60, %61, %62, %63, %64, %65, %66, %67, %68, %69, %70, %71, %72, %73, %74, %75 : i64, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32
      %76 = cute.memref.load_vec %view_9 : !memref_smem_f32_2
      cute.memref.store_vec %76, %arg1 : !memref_gmem_f32_1
      %cst_12 = arith.constant 2.000000e+00 : f32
      %77 = vector.splat %cst_12 : vector<32xf32>
      cute.memref.store_vec %77, %view : !memref_smem_f32_
      %iter_13 = cute.get_iter(%view) : !memref_smem_f32_
      %78 = builtin.unrealized_conversion_cast %iter_13 : !cute.ptr<f32, smem, align<32>> to !llvm.ptr<3>
      %79 = llvm.ptrtoint %78 : !llvm.ptr<3> to i64
      %80 = cute.memref.load_vec %view : !memref_smem_f32_
      %81 = vector.extract %80[0] : f32 from vector<32xf32>
      %82 = vector.extract %80[1] : f32 from vector<32xf32>
      %83 = vector.extract %80[2] : f32 from vector<32xf32>
      %84 = vector.extract %80[3] : f32 from vector<32xf32>
      %85 = vector.extract %80[4] : f32 from vector<32xf32>
      %86 = vector.extract %80[5] : f32 from vector<32xf32>
      %87 = vector.extract %80[6] : f32 from vector<32xf32>
      %88 = vector.extract %80[7] : f32 from vector<32xf32>
      %89 = vector.extract %80[8] : f32 from vector<32xf32>
      %90 = vector.extract %80[9] : f32 from vector<32xf32>
      %91 = vector.extract %80[10] : f32 from vector<32xf32>
      %92 = vector.extract %80[11] : f32 from vector<32xf32>
      %93 = vector.extract %80[12] : f32 from vector<32xf32>
      %94 = vector.extract %80[13] : f32 from vector<32xf32>
      %95 = vector.extract %80[14] : f32 from vector<32xf32>
      %96 = vector.extract %80[15] : f32 from vector<32xf32>
      %97 = vector.extract %80[16] : f32 from vector<32xf32>
      %98 = vector.extract %80[17] : f32 from vector<32xf32>
      %99 = vector.extract %80[18] : f32 from vector<32xf32>
      %100 = vector.extract %80[19] : f32 from vector<32xf32>
      %101 = vector.extract %80[20] : f32 from vector<32xf32>
      %102 = vector.extract %80[21] : f32 from vector<32xf32>
      %103 = vector.extract %80[22] : f32 from vector<32xf32>
      %104 = vector.extract %80[23] : f32 from vector<32xf32>
      %105 = vector.extract %80[24] : f32 from vector<32xf32>
      %106 = vector.extract %80[25] : f32 from vector<32xf32>
      %107 = vector.extract %80[26] : f32 from vector<32xf32>
      %108 = vector.extract %80[27] : f32 from vector<32xf32>
      %109 = vector.extract %80[28] : f32 from vector<32xf32>
      %110 = vector.extract %80[29] : f32 from vector<32xf32>
      %111 = vector.extract %80[30] : f32 from vector<32xf32>
      gpu.printf "tensor in smem: raw_ptr(0x%016llx: f32, smem, align<32>) o (16,2):(1,16) = \0A  ( %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, [...] )\0A", %79, %81, %82, %83, %84, %85, %86, %87, %88, %89, %90, %91, %92, %93, %94, %95, %96, %97, %98, %99, %100, %101, %102, %103, %104, %105, %106, %107, %108, %109, %110, %111 : i64, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32
      %112 = cute.memref.load_vec %view : !memref_smem_f32_
      cute.memref.store_vec %112, %arg2 : !memref_gmem_f32_2
      return
    }
  }
  func.func @cutlass_host_05_Tensorgmemo8441_10_Tensorgmemo8221_20_Tensorgmemo16221(%arg0: !memref_gmem_f32_, %arg1: !memref_gmem_f32_1, %arg2: !memref_gmem_f32_2) -> i32 attributes {llvm.emit_c_interface} {
    %c960_i32 = arith.constant 960 : i32
    %c0_i64 = arith.constant 0 : i64
    %0 = cuda.cast %c0_i64 : i64 -> !cuda.stream
    %1 = arith.extsi %c960_i32 : i32 to i64
    %c1_i32 = arith.constant 1 : i32
    %2 = cuda.launch_cfg.create<max_attrs = 2 : i32> (blockDim = (%c1_i32, %c1_i32, %c1_i32), dynamicSmemBytes = %1, gridDim = (%c1_i32, %c1_i32, %c1_i32), stream = %0) : i32, i32, i32, i64, i32, i32, i32, !cuda.stream -> !cuda.launch_cfg<max_attrs = 2>
    %3 = cuda.launch_ex @kernels::@kernel_cutlass_kernel_05_tensorptrf32gmemo8441_10_tensorptrf32gmemo8221_20_tensorptrf32gmemo16221_0<%2> (%arg0, %arg1, %arg2) : !cuda.launch_cfg<max_attrs = 2>, (!memref_gmem_f32_, !memref_gmem_f32_1, !memref_gmem_f32_2) -> !cuda.result
    %4 = cuda.cast %3 : !cuda.result -> i32
    cuda.return_if_error %4 : i32
    %c0_i32 = arith.constant 0 : i32
    return %c0_i32 : i32
  }
}
