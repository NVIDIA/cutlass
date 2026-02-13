!copy_ldsm_4_ = !cute.tiled_copy<!cute_nvgpu.atom.ldsm<val_type = f16, mode = <"(8,8)">, sz_pattern = u16, num_matrices = 4, t>, layout_copy_tv = <"((4,8,2,2),((2,2,2),(1,1))):((64,1,16,0),((32,8,256),(0,0)))">, tiler_mn = <"[32:1;16:1]">>
!copy_ldsm_4_1 = !cute.tiled_copy<!cute_nvgpu.atom.ldsm<val_type = f16, mode = <"(8,8)">, sz_pattern = u16, num_matrices = 4, t>, layout_copy_tv = <"((4,8,2,2),((2,2),(2,1))):((64,1,0,8),((32,256),(16,0)))">, tiler_mn = <"[32:1;16:1]">>
!copy_stsm_4_ = !cute.tiled_copy<!cute_nvgpu.atom.stsm<f16, mode = <"(8,8)">, num_matrices = 4, t>, layout_copy_tv = <"((4,8,2,2),(2,2,2)):((32,1,8,128),(256,16,512))">, tiler_mn = <"[(8,2,2):(1,16,8);(8,2,2):(2,1,16)]">>
!copy_stsm_4_1 = !cute.tiled_copy<!cute_nvgpu.atom.stsm<f16, mode = <"(8,8)">, num_matrices = 4, t>, layout_copy_tv = <"((4,16,2),((2,2,2),1)):((32,1,128),((256,16,512),0))">, tiler_mn = <"[(8,2,2):(1,16,8);(8,2,2):(2,1,16)]">>
!memref_gmem_f16_ = !cute.memref<f16, gmem, align<16>, "(?,?,?):(1,?{i64},?{i64})">
!memref_rmem_f16_ = !cute.memref<f16, rmem, align<16>, "((2,2,2),2,4):((1,2,4),8,16)">
!memref_rmem_f16_1 = !cute.memref<f16, rmem, align<8>, "((2,2),4,4):((1,2),4,16)">
!memref_rmem_f16_2 = !cute.memref<f16, rmem, align<32>, "(((2,2,2),1),2,1):(((1,2,4),0),8,0)">
!memref_rmem_f32_ = !cute.memref<f32, rmem, align<32>, "((2,2),2,4):((1,2),4,8)">
!memref_rmem_f32_1 = !cute.memref<f32, rmem, align<32>, "(((4,2),1),2,2):(((1,8),0),4,16)">
!memref_rmem_f32_2 = !cute.memref<f32, rmem, align<32>, "(((2,2,2),1),2,1):(((1,2,4),0),8,0)">
!memref_smem_f16_ = !cute.memref<f16, smem, align<16>, S<3,4,3>, "((8,1),2,4):((1,0),32,1024)">
#loop_unroll = #llvm.loop_unroll<disable = false, full = true>
#loop_unroll1 = #llvm.loop_unroll<disable = true, count = 1 : i32>
#loop_annotation = #llvm.loop_annotation<unroll = #loop_unroll>
#loop_annotation1 = #llvm.loop_annotation<unroll = #loop_unroll1>
module attributes {gpu.container_module} {
  gpu.module @kernels {
    cuda.kernel @kernel_cutlass_kernel___main__Sm120GemmKernel_object_at__CopyAtom_ThrID10_TVLayoutSrc1409601_TVLayoutDst1409601_Valuetypef16_tensor000o101112_CopyAtom_ThrID10_TVLayoutSrc1409601_TVLayoutD_0(%arg0: !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 65536, tma_gbasis = <"(64,64,1):(1@0,1@1,1@2)">, internal_val_type = f16>, %arg1: !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">, %arg2: !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 65536, tma_gbasis = <"(64,64,1):(1@0,1@1,1@2)">, internal_val_type = f16>, %arg3: !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">, %arg4: !cute_nvgpu.atom.non_exec_tiled_tma_store<f16, copy_bits = 32768, tma_gbasis = <"(64,32,1):(1@0,1@1,1@2)">, internal_val_type = f16>, %arg5: !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">, %arg6: i32, %arg7: i32, %arg8: i32, %arg9: !cute.fast_divmod_divisor<32>, %arg10: !cute.fast_divmod_divisor<32>, %arg11: !cute.fast_divmod_divisor<32>) attributes {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 160, 1, 1>} {
      %cst = arith.constant dense<0.000000e+00> : vector<32xf32>
      %0 = cute.static : !cute.layout<"((4096,1),(1,4)):((1,0),(0,4096))">
      %c16384_i32 = arith.constant 16384 : i32
      %1 = cute.static : !cute.stride<"(((1@0,1@1),0),64@1)">
      %2 = cute.static : !cute.int_tuple<"(0,32)">
      %3 = cute.static : !cute.coord<"31">
      %4 = cute.static : !cute.coord<"30">
      %5 = cute.static : !cute.coord<"29">
      %6 = cute.static : !cute.coord<"28">
      %7 = cute.static : !cute.coord<"27">
      %8 = cute.static : !cute.coord<"26">
      %9 = cute.static : !cute.coord<"25">
      %10 = cute.static : !cute.coord<"24">
      %11 = cute.static : !cute.coord<"23">
      %12 = cute.static : !cute.coord<"22">
      %13 = cute.static : !cute.coord<"21">
      %14 = cute.static : !cute.coord<"20">
      %15 = cute.static : !cute.coord<"19">
      %16 = cute.static : !cute.coord<"18">
      %17 = cute.static : !cute.coord<"17">
      %18 = cute.static : !cute.coord<"16">
      %19 = cute.static : !cute.layout<"((8,1),((2,1))):((1,0),((32,0)))">
      %20 = cute.static : !cute.layout<"(((2,2,2),1),((2,1))):(((1,2,4),0),((8,0)))">
      %21 = cute.static : !cute.coord<"15">
      %22 = cute.static : !cute.coord<"14">
      %23 = cute.static : !cute.coord<"13">
      %24 = cute.static : !cute.coord<"12">
      %25 = cute.static : !cute.coord<"11">
      %26 = cute.static : !cute.coord<"10">
      %27 = cute.static : !cute.coord<"9">
      %28 = cute.static : !cute.coord<"8">
      %29 = cute.static : !cute.coord<"7">
      %30 = cute.static : !cute.coord<"6">
      %31 = cute.static : !cute.coord<"5">
      %32 = cute.static : !cute.coord<"4">
      %33 = cute.static : !cute.coord<"3">
      %34 = cute.static : !cute.coord<"2">
      %35 = cute.static : !cute.coord<"1">
      %36 = cute.static : !cute.coord<"0">
      %c1024_i32 = arith.constant 1024 : i32
      %c128_i32 = arith.constant 128 : i32
      %37 = cute.static : !cute.int_tuple<"48">
      %38 = cute.static : !cute.int_tuple<"3072">
      %39 = cute.static : !cute.int_tuple<"32">
      %40 = cute.static : !cute.int_tuple<"2048">
      %41 = cute.static : !cute.layout<"((2,2),4,1):((1,2),4,0)">
      %42 = cute.static : !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">
      %43 = cute.static : !cute.int_tuple<"16">
      %44 = cute.static : !cute.int_tuple<"6">
      %45 = llvm.mlir.constant(3 : i32) : i32
      %46 = llvm.mlir.constant(0 : i32) : i32
      %47 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((8)))">
      %48 = cute.static : !cute.layout<"((8,1),((2))):((1,0),((32)))">
      %49 = cute.static : !cute.layout<"((8,1),2,4,(1,4)):((1,0),32,1024,(0,4096))">
      %c10000000_i32 = arith.constant 10000000 : i32
      %c16_i32 = arith.constant 16 : i32
      %c512_i32 = arith.constant 512 : i32
      %c2_i32 = arith.constant 2 : i32
      %c8_i32 = arith.constant 8 : i32
      %50 = cute.static : !cute.layout<"((2,2),2,4):((1,2),4,8)">
      %51 = cute.static : !cute.stride<"(((1@0,1@1),0),64@0,64@1,1@2)">
      %52 = cute.static : !cute.stride<"((1@0,1@1),64@0,64@1,1@2)">
      %53 = cute.static : !cute.int_tuple<"(0,0,0)">
      %54 = cute.static : !cute.stride<"(1@0,1@1,64@0,64@1,1@2)">
      %55 = cute.static : !cute.stride<"((1@0,1@1),(64@0,64@1,1@2))">
      %c64_i32 = arith.constant 64 : i32
      %true = arith.constant true
      %c4_i32 = arith.constant 4 : i32
      %56 = cute.static : !cute.int_tuple<"4">
      %57 = cute.static : !cute.int_tuple<"3">
      %58 = cute.static : !cute.int_tuple<"2">
      %59 = cute.static : !cute.int_tuple<"1">
      %c1_i32 = arith.constant 1 : i32
      %60 = cute.static : !cute.int_tuple<"66560">
      %61 = cute.static : !cute.int_tuple<"33792">
      %62 = cute.static : !cute.int_tuple<"1024">
      %c0_i32 = arith.constant 0 : i32
      %c32_i32 = arith.constant 32 : i32
      %63 = llvm.mlir.constant(2 : i32) : i32
      %64 = llvm.mlir.constant(1 : i32) : i32
      %int_tuple = cute.make_int_tuple(%arg6, %arg7, %arg8) : (i32, i32, i32) -> !cute.int_tuple<"(?,?,?)">
      %65:3 = cute.get_scalars(%int_tuple) <{only_dynamic}> : !cute.int_tuple<"(?,?,?)">
      %int_tuple_0 = cute.make_int_tuple(%65#0, %65#1, %65#2) : (i32, i32, i32) -> !cute.int_tuple<"(?,?,?)">
      %e0, %e1, %e2 = cute.get_leaves(%int_tuple_0) : !cute.int_tuple<"(?,?,?)">
      %shape = cute.make_shape(%e0, %e1, %e2) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.shape<"(?,?,?)">
      %lay = cute.make_layout(%shape) : !cute.layout<"(?,?,?):(1,?,?)">
      %66 = nvvm.read.ptx.sreg.tid.x range <i32, 0, 1024> : i32
      %67 = nvvm.read.ptx.sreg.tid.y range <i32, 0, 1024> : i32
      %68 = nvvm.read.ptx.sreg.tid.z range <i32, 0, 64> : i32
      %69 = nvvm.read.ptx.sreg.ntid.x range <i32, 1, 1024> : i32
      %70 = nvvm.read.ptx.sreg.ntid.y range <i32, 1, 1024> : i32
      %71 = arith.muli %67, %69 : i32
      %72 = arith.addi %66, %71 : i32
      %73 = arith.muli %68, %69 : i32
      %74 = arith.muli %73, %70 : i32
      %75 = arith.addi %72, %74 : i32
      %76 = arith.divsi %75, %c32_i32 : i32
      %77 = arith.muli %76, %c32_i32 : i32
      %78 = arith.cmpi ne, %75, %77 : i32
      %c0_i32_1 = arith.constant 0 : i32
      %79 = arith.cmpi slt, %75, %c0_i32_1 : i32
      %80 = arith.cmpi slt, %c32_i32, %c0_i32_1 : i32
      %81 = arith.cmpi ne, %79, %80 : i1
      %82 = arith.andi %78, %81 : i1
      %c-1_i32 = arith.constant -1 : i32
      %83 = arith.addi %76, %c-1_i32 : i32
      %84 = arith.select %82, %83, %76 : i32
      %85 = cute_nvgpu.arch.make_warp_uniform(%84) : i32
      %86 = arith.cmpi eq, %85, %c0_i32 : i32
      cf.cond_br %86, ^bb1, ^bb2
    ^bb1:  // pred: ^bb0
      cute_nvgpu.prefetch_tma_desc(%arg0) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 65536, tma_gbasis = <"(64,64,1):(1@0,1@1,1@2)">, internal_val_type = f16>) -> ()
      cute_nvgpu.prefetch_tma_desc(%arg2) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 65536, tma_gbasis = <"(64,64,1):(1@0,1@1,1@2)">, internal_val_type = f16>) -> ()
      cute_nvgpu.prefetch_tma_desc(%arg4) : (!cute_nvgpu.atom.non_exec_tiled_tma_store<f16, copy_bits = 32768, tma_gbasis = <"(64,32,1):(1@0,1@1,1@2)">, internal_val_type = f16>) -> ()
      cf.br ^bb2
    ^bb2:  // 2 preds: ^bb0, ^bb1
      %smem_ptr = cute_nvgpu.arch.get_dyn_smem() : !cute.ptr<i8, smem, align<1024>>
      %ptr = cute.add_offset(%smem_ptr, %62) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"1024">) -> !cute.ptr<i8, smem, align<1024>>
      %ptr_2 = cute.add_offset(%smem_ptr, %61) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"33792">) -> !cute.ptr<i8, smem, align<1024>>
      %ptr_3 = cute.add_offset(%smem_ptr, %60) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"66560">) -> !cute.ptr<i8, smem, align<1024>>
      %iter = cute.recast_iter(%smem_ptr) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<i64, smem, align<1024>>
      cf.cond_br %86, ^bb3, ^bb4
    ^bb3:  // pred: ^bb2
      %87 = builtin.unrealized_conversion_cast %iter : !cute.ptr<i64, smem, align<1024>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %87, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_4 = cute.add_offset(%iter, %59) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"1">) -> !cute.ptr<i64, smem>
      %88 = builtin.unrealized_conversion_cast %ptr_4 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %88, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_5 = cute.add_offset(%iter, %58) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"2">) -> !cute.ptr<i64, smem, align<16>>
      %89 = builtin.unrealized_conversion_cast %ptr_5 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %89, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_6 = cute.add_offset(%iter, %57) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"3">) -> !cute.ptr<i64, smem>
      %90 = builtin.unrealized_conversion_cast %ptr_6 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %90, %c1_i32 : !llvm.ptr<3>, i32
      cf.br ^bb4
    ^bb4:  // 2 preds: ^bb2, ^bb3
      %ptr_7 = cute.add_offset(%iter, %56) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"4">) -> !cute.ptr<i64, smem, align<32>>
      cf.cond_br %86, ^bb5, ^bb6
    ^bb5:  // pred: ^bb4
      %91 = builtin.unrealized_conversion_cast %ptr_7 : !cute.ptr<i64, smem, align<32>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %91, %c4_i32 : !llvm.ptr<3>, i32
      %int_tuple_8 = cute.make_int_tuple() : () -> !cute.int_tuple<"5">
      %ptr_9 = cute.add_offset(%iter, %int_tuple_8) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"5">) -> !cute.ptr<i64, smem>
      %92 = builtin.unrealized_conversion_cast %ptr_9 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %92, %c4_i32 : !llvm.ptr<3>, i32
      %int_tuple_10 = cute.make_int_tuple() : () -> !cute.int_tuple<"6">
      %ptr_11 = cute.add_offset(%iter, %int_tuple_10) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"6">) -> !cute.ptr<i64, smem, align<16>>
      %93 = builtin.unrealized_conversion_cast %ptr_11 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %93, %c4_i32 : !llvm.ptr<3>, i32
      %int_tuple_12 = cute.make_int_tuple() : () -> !cute.int_tuple<"7">
      %ptr_13 = cute.add_offset(%iter, %int_tuple_12) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"7">) -> !cute.ptr<i64, smem>
      %94 = builtin.unrealized_conversion_cast %ptr_13 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %94, %c4_i32 : !llvm.ptr<3>, i32
      cf.br ^bb6
    ^bb6:  // 2 preds: ^bb4, ^bb5
      %95 = arith.remsi %66, %c32_i32 : i32
      %96 = arith.cmpi slt, %95, %c1_i32 : i32
      %97 = arith.extui %96 : i1 to i32
      %98 = arith.select %96, %c1_i32, %97 : i32
      %99 = arith.cmpi ne, %98, %c0_i32 : i32
      nvvm.fence.mbarrier.init
      nvvm.barrier
      %iter_14 = cute.recast_iter(%ptr) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<f16, smem, align<1024>, S<3,4,3>>
      %iter_15 = cute.recast_iter(%ptr_2) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<f16, smem, align<1024>, S<3,4,3>>
      %iter_16 = cute.recast_iter(%ptr_3) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<f16, smem, align<1024>, S<3,4,3>>
      %lay_17 = cute.get_layout(%arg1) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">
      %100:3 = cute.get_scalars(%lay_17) <{only_dynamic}> : !cute.layout<"(?,?,?):(1@0,1@1,1@2)">
      %c1_i32_18 = arith.constant 1 : i32
      %c0_i32_19 = arith.constant 0 : i32
      %c-1_i32_20 = arith.constant -1 : i32
      %101 = arith.cmpi sgt, %c64_i32, %c0_i32_19 : i32
      %102 = arith.select %101, %c-1_i32_20, %c1_i32_18 : i32
      %103 = arith.addi %102, %100#0 : i32
      %104 = arith.divsi %103, %c64_i32 : i32
      %105 = arith.addi %c1_i32_18, %104 : i32
      %106 = arith.subi %c0_i32_19, %100#0 : i32
      %107 = arith.divsi %106, %c64_i32 : i32
      %108 = arith.subi %c0_i32_19, %107 : i32
      %109 = arith.cmpi slt, %100#0, %c0_i32_19 : i32
      %110 = arith.cmpi sgt, %100#0, %c0_i32_19 : i32
      %111 = arith.cmpi slt, %c64_i32, %c0_i32_19 : i32
      %112 = arith.cmpi sgt, %c64_i32, %c0_i32_19 : i32
      %113 = arith.andi %109, %111 : i1
      %114 = arith.andi %110, %112 : i1
      %115 = arith.ori %113, %114 : i1
      %116 = arith.select %115, %105, %108 : i32
      %c1_i32_21 = arith.constant 1 : i32
      %c0_i32_22 = arith.constant 0 : i32
      %c-1_i32_23 = arith.constant -1 : i32
      %117 = arith.cmpi sgt, %c64_i32, %c0_i32_22 : i32
      %118 = arith.select %117, %c-1_i32_23, %c1_i32_21 : i32
      %119 = arith.addi %118, %100#1 : i32
      %120 = arith.divsi %119, %c64_i32 : i32
      %121 = arith.addi %c1_i32_21, %120 : i32
      %122 = arith.subi %c0_i32_22, %100#1 : i32
      %123 = arith.divsi %122, %c64_i32 : i32
      %124 = arith.subi %c0_i32_22, %123 : i32
      %125 = arith.cmpi slt, %100#1, %c0_i32_22 : i32
      %126 = arith.cmpi sgt, %100#1, %c0_i32_22 : i32
      %127 = arith.cmpi slt, %c64_i32, %c0_i32_22 : i32
      %128 = arith.cmpi sgt, %c64_i32, %c0_i32_22 : i32
      %129 = arith.andi %125, %127 : i1
      %130 = arith.andi %126, %128 : i1
      %131 = arith.ori %129, %130 : i1
      %132 = arith.select %131, %121, %124 : i32
      %shape_24 = cute.make_shape(%116, %132, %100#2) : (i32, i32, i32) -> !cute.shape<"((64,64),(?,?,?))">
      %lay_25 = cute.make_layout(%shape_24, %55) : !cute.layout<"((64,64),(?,?,?)):((1@0,1@1),(64@0,64@1,1@2))">
      %133:3 = cute.get_scalars(%lay_25) <{only_dynamic}> : !cute.layout<"((64,64),(?,?,?)):((1@0,1@1),(64@0,64@1,1@2))">
      %shape_26 = cute.make_shape(%133#0, %133#1, %133#2) : (i32, i32, i32) -> !cute.shape<"(64,64,?,?,?)">
      %lay_27 = cute.make_layout(%shape_26, %54) : !cute.layout<"(64,64,?,?,?):(1@0,1@1,64@0,64@1,1@2)">
      %lay_28 = cute.get_layout(%arg3) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">
      %134:3 = cute.get_scalars(%lay_28) <{only_dynamic}> : !cute.layout<"(?,?,?):(1@0,1@1,1@2)">
      %c1_i32_29 = arith.constant 1 : i32
      %c0_i32_30 = arith.constant 0 : i32
      %c-1_i32_31 = arith.constant -1 : i32
      %135 = arith.cmpi sgt, %c64_i32, %c0_i32_30 : i32
      %136 = arith.select %135, %c-1_i32_31, %c1_i32_29 : i32
      %137 = arith.addi %136, %134#0 : i32
      %138 = arith.divsi %137, %c64_i32 : i32
      %139 = arith.addi %c1_i32_29, %138 : i32
      %140 = arith.subi %c0_i32_30, %134#0 : i32
      %141 = arith.divsi %140, %c64_i32 : i32
      %142 = arith.subi %c0_i32_30, %141 : i32
      %143 = arith.cmpi slt, %134#0, %c0_i32_30 : i32
      %144 = arith.cmpi sgt, %134#0, %c0_i32_30 : i32
      %145 = arith.cmpi slt, %c64_i32, %c0_i32_30 : i32
      %146 = arith.cmpi sgt, %c64_i32, %c0_i32_30 : i32
      %147 = arith.andi %143, %145 : i1
      %148 = arith.andi %144, %146 : i1
      %149 = arith.ori %147, %148 : i1
      %150 = arith.select %149, %139, %142 : i32
      %c1_i32_32 = arith.constant 1 : i32
      %c0_i32_33 = arith.constant 0 : i32
      %c-1_i32_34 = arith.constant -1 : i32
      %151 = arith.cmpi sgt, %c64_i32, %c0_i32_33 : i32
      %152 = arith.select %151, %c-1_i32_34, %c1_i32_32 : i32
      %153 = arith.addi %152, %134#1 : i32
      %154 = arith.divsi %153, %c64_i32 : i32
      %155 = arith.addi %c1_i32_32, %154 : i32
      %156 = arith.subi %c0_i32_33, %134#1 : i32
      %157 = arith.divsi %156, %c64_i32 : i32
      %158 = arith.subi %c0_i32_33, %157 : i32
      %159 = arith.cmpi slt, %134#1, %c0_i32_33 : i32
      %160 = arith.cmpi sgt, %134#1, %c0_i32_33 : i32
      %161 = arith.cmpi slt, %c64_i32, %c0_i32_33 : i32
      %162 = arith.cmpi sgt, %c64_i32, %c0_i32_33 : i32
      %163 = arith.andi %159, %161 : i1
      %164 = arith.andi %160, %162 : i1
      %165 = arith.ori %163, %164 : i1
      %166 = arith.select %165, %155, %158 : i32
      %shape_35 = cute.make_shape(%150, %166, %134#2) : (i32, i32, i32) -> !cute.shape<"((64,64),(?,?,?))">
      %lay_36 = cute.make_layout(%shape_35, %55) : !cute.layout<"((64,64),(?,?,?)):((1@0,1@1),(64@0,64@1,1@2))">
      %167:3 = cute.get_scalars(%lay_36) <{only_dynamic}> : !cute.layout<"((64,64),(?,?,?)):((1@0,1@1),(64@0,64@1,1@2))">
      %shape_37 = cute.make_shape(%167#0, %167#1, %167#2) : (i32, i32, i32) -> !cute.shape<"(64,64,?,?,?)">
      %lay_38 = cute.make_layout(%shape_37, %54) : !cute.layout<"(64,64,?,?,?):(1@0,1@1,64@0,64@1,1@2)">
      %lay_39 = cute.get_layout(%arg5) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">
      %168:3 = cute.get_scalars(%lay_39) <{only_dynamic}> : !cute.layout<"(?,?,?):(1@0,1@1,1@2)">
      %c1_i32_40 = arith.constant 1 : i32
      %c0_i32_41 = arith.constant 0 : i32
      %c-1_i32_42 = arith.constant -1 : i32
      %169 = arith.cmpi sgt, %c64_i32, %c0_i32_41 : i32
      %170 = arith.select %169, %c-1_i32_42, %c1_i32_40 : i32
      %171 = arith.addi %170, %168#0 : i32
      %172 = arith.divsi %171, %c64_i32 : i32
      %173 = arith.addi %c1_i32_40, %172 : i32
      %174 = arith.subi %c0_i32_41, %168#0 : i32
      %175 = arith.divsi %174, %c64_i32 : i32
      %176 = arith.subi %c0_i32_41, %175 : i32
      %177 = arith.cmpi slt, %168#0, %c0_i32_41 : i32
      %178 = arith.cmpi sgt, %168#0, %c0_i32_41 : i32
      %179 = arith.cmpi slt, %c64_i32, %c0_i32_41 : i32
      %180 = arith.cmpi sgt, %c64_i32, %c0_i32_41 : i32
      %181 = arith.andi %177, %179 : i1
      %182 = arith.andi %178, %180 : i1
      %183 = arith.ori %181, %182 : i1
      %184 = arith.select %183, %173, %176 : i32
      %c1_i32_43 = arith.constant 1 : i32
      %c0_i32_44 = arith.constant 0 : i32
      %c-1_i32_45 = arith.constant -1 : i32
      %185 = arith.cmpi sgt, %c64_i32, %c0_i32_44 : i32
      %186 = arith.select %185, %c-1_i32_45, %c1_i32_43 : i32
      %187 = arith.addi %186, %168#1 : i32
      %188 = arith.divsi %187, %c64_i32 : i32
      %189 = arith.addi %c1_i32_43, %188 : i32
      %190 = arith.subi %c0_i32_44, %168#1 : i32
      %191 = arith.divsi %190, %c64_i32 : i32
      %192 = arith.subi %c0_i32_44, %191 : i32
      %193 = arith.cmpi slt, %168#1, %c0_i32_44 : i32
      %194 = arith.cmpi sgt, %168#1, %c0_i32_44 : i32
      %195 = arith.cmpi slt, %c64_i32, %c0_i32_44 : i32
      %196 = arith.cmpi sgt, %c64_i32, %c0_i32_44 : i32
      %197 = arith.andi %193, %195 : i1
      %198 = arith.andi %194, %196 : i1
      %199 = arith.ori %197, %198 : i1
      %200 = arith.select %199, %189, %192 : i32
      %shape_46 = cute.make_shape(%184, %200, %168#2) : (i32, i32, i32) -> !cute.shape<"((64,64),(?,?,?))">
      %lay_47 = cute.make_layout(%shape_46, %55) : !cute.layout<"((64,64),(?,?,?)):((1@0,1@1),(64@0,64@1,1@2))">
      %201:3 = cute.get_scalars(%lay_47) <{only_dynamic}> : !cute.layout<"((64,64),(?,?,?)):((1@0,1@1),(64@0,64@1,1@2))">
      %shape_48 = cute.make_shape(%201#0, %201#1, %201#2) : (i32, i32, i32) -> !cute.shape<"(64,64,?,?,?)">
      %lay_49 = cute.make_layout(%shape_48, %54) : !cute.layout<"(64,64,?,?,?):(1@0,1@1,64@0,64@1,1@2)">
      %202:3 = cute.get_scalars(%lay_27) <{only_dynamic}> : !cute.layout<"(64,64,?,?,?):(1@0,1@1,64@0,64@1,1@2)">
      %shape_50 = cute.make_shape(%202#0, %202#1, %202#2) : (i32, i32, i32) -> !cute.shape<"((64,64),?,?,?)">
      %lay_51 = cute.make_layout(%shape_50, %52) : !cute.layout<"((64,64),?,?,?):((1@0,1@1),64@0,64@1,1@2)">
      %203:3 = cute.get_scalars(%lay_51) <{only_dynamic}> : !cute.layout<"((64,64),?,?,?):((1@0,1@1),64@0,64@1,1@2)">
      %shape_52 = cute.make_shape(%203#0, %203#1, %203#2) : (i32, i32, i32) -> !cute.shape<"(((64,64),1),?,?,?)">
      %lay_53 = cute.make_layout(%shape_52, %51) : !cute.layout<"(((64,64),1),?,?,?):(((1@0,1@1),0),64@0,64@1,1@2)">
      %204:3 = cute.get_scalars(%lay_38) <{only_dynamic}> : !cute.layout<"(64,64,?,?,?):(1@0,1@1,64@0,64@1,1@2)">
      %shape_54 = cute.make_shape(%204#0, %204#1, %204#2) : (i32, i32, i32) -> !cute.shape<"((64,64),?,?,?)">
      %lay_55 = cute.make_layout(%shape_54, %52) : !cute.layout<"((64,64),?,?,?):((1@0,1@1),64@0,64@1,1@2)">
      %205:3 = cute.get_scalars(%lay_55) <{only_dynamic}> : !cute.layout<"((64,64),?,?,?):((1@0,1@1),64@0,64@1,1@2)">
      %shape_56 = cute.make_shape(%205#0, %205#1, %205#2) : (i32, i32, i32) -> !cute.shape<"(((64,64),1),?,?,?)">
      %lay_57 = cute.make_layout(%shape_56, %51) : !cute.layout<"(((64,64),1),?,?,?):(((1@0,1@1),0),64@0,64@1,1@2)">
      %rmem = cute.memref.alloca() : !memref_rmem_f16_
      %rmem_58 = cute.memref.alloca() : !memref_rmem_f16_1
      %rmem_59 = cute.memref.alloca() : !memref_rmem_f32_
      nvvm.barrier id = %c1_i32
      %sz = cute.size(%lay_27) <{mode = [3]}> : (!cute.layout<"(64,64,?,?,?):(1@0,1@1,64@0,64@1,1@2)">) -> !cute.int_tuple<"?">
      %e0_60 = cute.get_leaves(%sz) : !cute.int_tuple<"?">
      %206 = cute.get_scalars(%e0_60) : !cute.int_tuple<"?">
      %207 = nvvm.read.ptx.sreg.ctaid.z range <i32, 0, 65535> : i32
      %208 = nvvm.read.ptx.sreg.nctaid.x range <i32, 1, 2147483647> : i32
      %209 = nvvm.read.ptx.sreg.nctaid.y range <i32, 1, 65535> : i32
      %210 = nvvm.read.ptx.sreg.nctaid.z range <i32, 1, 65535> : i32
      %int_tuple_61 = cute.make_int_tuple(%208, %209, %210) : (i32, i32, i32) -> !cute.int_tuple<"(?,?,?)">
      %sz_62 = cute.size(%int_tuple_61) : (!cute.int_tuple<"(?,?,?)">) -> !cute.int_tuple<"?">
      %e0_63 = cute.get_leaves(%sz_62) : !cute.int_tuple<"?">
      %div = cute.tuple_div(%e0_63, %59) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %211 = cute.get_scalars(%div) : !cute.int_tuple<"?">
      %sz_64 = cute.size(%lay) : (!cute.layout<"(?,?,?):(1,?,?)">) -> !cute.int_tuple<"?">
      %e0_65 = cute.get_leaves(%sz_64) : !cute.int_tuple<"?">
      %212 = cute.get_scalars(%e0_65) : !cute.int_tuple<"?">
      %213 = arith.cmpi sgt, %212, %207 : i32
      %214 = cute.fast_divmod.get_divisor(%arg9) : !cute.fast_divmod_divisor<32>
      %multiplier, %shift1, %shift2 = cute.fast_divmod.get_aux(%arg9) : !cute.fast_divmod_divisor<32> -> (i32, i8)
      %215 = arith.extui %shift1 : i8 to i32
      %216 = arith.extui %shift2 : i8 to i32
      %217 = nvvm.mul  hi %207, %multiplier : i32 -> i32
      %218 = arith.subi %207, %217 : i32
      %219 = arith.shrui %218, %215 : i32
      %220 = arith.addi %217, %219 : i32
      %221 = arith.shrui %220, %216 : i32
      %222 = arith.muli %221, %214 : i32
      %223 = arith.subi %207, %222 : i32
      %224 = cute.fast_divmod.get_divisor(%arg10) : !cute.fast_divmod_divisor<32>
      %multiplier_66, %shift1_67, %shift2_68 = cute.fast_divmod.get_aux(%arg10) : !cute.fast_divmod_divisor<32> -> (i32, i8)
      %225 = arith.extui %shift1_67 : i8 to i32
      %226 = arith.extui %shift2_68 : i8 to i32
      %227 = nvvm.mul  hi %223, %multiplier_66 : i32 -> i32
      %228 = arith.subi %223, %227 : i32
      %229 = arith.shrui %228, %225 : i32
      %230 = arith.addi %227, %229 : i32
      %231 = arith.shrui %230, %226 : i32
      %232 = arith.muli %231, %224 : i32
      %233 = arith.subi %223, %232 : i32
      %234 = cute.fast_divmod.get_divisor(%arg11) : !cute.fast_divmod_divisor<32>
      %multiplier_69, %shift1_70, %shift2_71 = cute.fast_divmod.get_aux(%arg11) : !cute.fast_divmod_divisor<32> -> (i32, i8)
      %235 = arith.extui %shift1_70 : i8 to i32
      %236 = arith.extui %shift2_71 : i8 to i32
      %237 = nvvm.mul  hi %231, %multiplier_69 : i32 -> i32
      %238 = arith.subi %231, %237 : i32
      %239 = arith.shrui %238, %235 : i32
      %240 = arith.addi %237, %239 : i32
      %241 = arith.shrui %240, %236 : i32
      %242 = arith.muli %241, %234 : i32
      %243 = arith.subi %231, %242 : i32
      %int_tuple_72 = cute.make_int_tuple(%233) : (i32) -> !cute.int_tuple<"?">
      %mul = cute.tuple_mul(%int_tuple_72, %59) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %244 = cute.get_scalars(%mul) : !cute.int_tuple<"?">
      %int_tuple_73 = cute.make_int_tuple(%243) : (i32) -> !cute.int_tuple<"?">
      %mul_74 = cute.tuple_mul(%int_tuple_73, %59) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %245 = cute.get_scalars(%mul_74) : !cute.int_tuple<"?">
      %int_tuple_75 = cute.make_int_tuple(%241) : (i32) -> !cute.int_tuple<"?">
      %mul_76 = cute.tuple_mul(%int_tuple_75, %59) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %246 = cute.get_scalars(%mul_76) : !cute.int_tuple<"?">
      %247 = arith.cmpi slt, %85, %c4_i32 : i32
      cf.cond_br %247, ^bb7, ^bb170
    ^bb7:  // pred: ^bb6
      nvvm.setmaxregister  increase 232
      %atom = cute.make_atom() : () -> !cute_nvgpu.atom.ldsm<val_type = f16, mode = <"(8,8)">, sz_pattern = u16, num_matrices = 4, t>
      %248 = cute.make_tiled_copy(%atom) : !copy_ldsm_4_
      %249 = cute.make_tiled_copy(%atom) : !copy_ldsm_4_1
      %coord = cute.make_coord(%66) : (i32) -> !cute.coord<"?">
      %250 = cute.get_scalars(%coord) <{only_dynamic}> : !cute.coord<"?">
      %251 = arith.divsi %250, %c8_i32 : i32
      %252 = arith.remsi %250, %c8_i32 : i32
      %253 = arith.muli %252, %c64_i32 : i32
      %254 = arith.divsi %251, %c2_i32 : i32
      %255 = arith.remsi %251, %c2_i32 : i32
      %256 = arith.muli %255, %c8_i32 : i32
      %257 = arith.addi %253, %256 : i32
      %258 = arith.divsi %254, %c2_i32 : i32
      %259 = arith.remsi %254, %c2_i32 : i32
      %260 = arith.muli %259, %c512_i32 : i32
      %261 = arith.addi %257, %260 : i32
      %262 = arith.remsi %258, %c2_i32 : i32
      %263 = arith.muli %262, %c16_i32 : i32
      %264 = arith.addi %261, %263 : i32
      %iv = cute.assume(%264) : (i32) -> !cute.i32<divby 8>
      %int_tuple_77 = cute.make_int_tuple(%iv) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %ptr_78 = cute.add_offset(%iter_14, %int_tuple_77) : (!cute.ptr<f16, smem, align<1024>, S<3,4,3>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %iter_79 = cute.get_iter(%rmem) : !memref_rmem_f16_
      %265 = arith.divsi %250, %c16_i32 : i32
      %266 = arith.remsi %250, %c16_i32 : i32
      %267 = arith.muli %266, %c64_i32 : i32
      %268 = arith.divsi %265, %c2_i32 : i32
      %269 = arith.remsi %265, %c2_i32 : i32
      %270 = arith.muli %269, %c16_i32 : i32
      %271 = arith.addi %267, %270 : i32
      %272 = arith.divsi %268, %c2_i32 : i32
      %273 = arith.muli %272, %c8_i32 : i32
      %274 = arith.addi %271, %273 : i32
      %iv_80 = cute.assume(%274) : (i32) -> !cute.i32<divby 8>
      %int_tuple_81 = cute.make_int_tuple(%iv_80) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %ptr_82 = cute.add_offset(%iter_15, %int_tuple_81) : (!cute.ptr<f16, smem, align<1024>, S<3,4,3>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %iter_83 = cute.get_iter(%rmem_58) : !memref_rmem_f16_1
      %275 = arith.cmpi sgt, %206, %c0_i32 : i32
      %276 = cute.get_scalars(%58) : !cute.int_tuple<"2">
      %sub = cute.tuple_sub(%e0_60, %59) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %277 = cute.get_scalars(%sub) : !cute.int_tuple<"?">
      %ptr_84 = cute.add_offset(%iter_79, %43) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"16">) -> !cute.ptr<f16, rmem, align<16>>
      %ptr_85 = cute.add_offset(%iter_83, %43) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"16">) -> !cute.ptr<f16, rmem, align<8>>
      %iter_86 = cute.get_iter(%rmem_59) : !memref_rmem_f32_
      %278 = cute.get_scalars(%59) : !cute.int_tuple<"1">
      %279 = cute.get_scalars(%56) : !cute.int_tuple<"4">
      %ptr_87 = cute.add_offset(%iter_79, %39) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"32">) -> !cute.ptr<f16, rmem, align<16>>
      %ptr_88 = cute.add_offset(%iter_83, %39) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"32">) -> !cute.ptr<f16, rmem, align<8>>
      %ptr_89 = cute.add_offset(%iter_79, %37) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"48">) -> !cute.ptr<f16, rmem, align<16>>
      %ptr_90 = cute.add_offset(%iter_83, %37) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"48">) -> !cute.ptr<f16, rmem, align<8>>
      %ptr_91 = cute.add_offset(%iter_79, %43) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"16">) -> !cute.ptr<f16, rmem, align<16>>
      %ptr_92 = cute.add_offset(%iter_83, %43) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"16">) -> !cute.ptr<f16, rmem, align<8>>
      %iter_93 = cute.get_iter(%rmem_59) : !memref_rmem_f32_
      %280 = cute.get_scalars(%59) : !cute.int_tuple<"1">
      %281 = cute.get_scalars(%56) : !cute.int_tuple<"4">
      %ptr_94 = cute.add_offset(%iter_79, %39) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"32">) -> !cute.ptr<f16, rmem, align<16>>
      %ptr_95 = cute.add_offset(%iter_83, %39) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"32">) -> !cute.ptr<f16, rmem, align<8>>
      %ptr_96 = cute.add_offset(%iter_79, %37) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"48">) -> !cute.ptr<f16, rmem, align<16>>
      %ptr_97 = cute.add_offset(%iter_83, %37) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"48">) -> !cute.ptr<f16, rmem, align<8>>
      %atom_98 = cute.make_atom() : () -> !cute_nvgpu.atom.stsm<f16, mode = <"(8,8)">, num_matrices = 4, t>
      %282 = arith.divsi %250, %c2_i32 : i32
      %283 = arith.remsi %250, %c2_i32 : i32
      %284 = arith.muli %283, %c64_i32 : i32
      %285 = arith.divsi %282, %c4_i32 : i32
      %286 = arith.remsi %282, %c4_i32 : i32
      %287 = arith.muli %286, %c128_i32 : i32
      %288 = arith.addi %284, %287 : i32
      %289 = arith.divsi %285, %c2_i32 : i32
      %290 = arith.remsi %285, %c2_i32 : i32
      %291 = arith.muli %290, %c8_i32 : i32
      %292 = arith.addi %288, %291 : i32
      %293 = arith.divsi %289, %c2_i32 : i32
      %294 = arith.remsi %289, %c2_i32 : i32
      %295 = arith.muli %294, %c1024_i32 : i32
      %296 = arith.addi %292, %295 : i32
      %297 = arith.divsi %293, %c2_i32 : i32
      %298 = arith.remsi %293, %c2_i32 : i32
      %299 = arith.muli %298, %c16_i32 : i32
      %300 = arith.addi %296, %299 : i32
      %301 = arith.muli %297, %c512_i32 : i32
      %302 = arith.addi %300, %301 : i32
      %iv_99 = cute.assume(%302) : (i32) -> !cute.i32<divby 8>
      %int_tuple_100 = cute.make_int_tuple(%iv_99) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %ptr_101 = cute.add_offset(%iter_16, %int_tuple_100) : (!cute.ptr<f16, smem, align<1024>, S<3,4,3>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %view = cute.make_view(%iter_93) : !memref_rmem_f32_1
      %ptr_102 = cute.add_offset(%ptr_101, %40) : (!cute.ptr<f16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"2048">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      cf.br ^bb8(%244, %245, %246, %213, %c0_i32, %c0_i32, %207, %c0_i32 : i32, i32, i32, i1, i32, i32, i32, i32)
    ^bb8(%303: i32, %304: i32, %305: i32, %306: i1, %307: i32, %308: i32, %309: i32, %310: i32):  // 2 preds: ^bb7, ^bb168
      cf.cond_br %306, ^bb9(%303, %304, %305, %307, %308, %309, %310 : i32, i32, i32, i32, i32, i32, i32), ^bb169
    ^bb9(%311: i32, %312: i32, %313: i32, %314: i32, %315: i32, %316: i32, %317: i32):  // pred: ^bb8
      %coord_103 = cute.make_coord(%311, %312, %313) : (i32, i32, i32) -> !cute.coord<"(_,_,?,?,?)">
      %idx = cute.crd2idx(%coord_103, %lay_49) : (!cute.coord<"(_,_,?,?,?)">, !cute.layout<"(64,64,?,?,?):(1@0,1@1,64@0,64@1,1@2)">) -> !cute.int_tuple<"(?{div=64},?{div=64},?)">
      %tup = cute.add_offset(%53, %idx) : (!cute.int_tuple<"(0,0,0)">, !cute.int_tuple<"(?{div=64},?{div=64},?)">) -> !cute.int_tuple<"(?{div=64},?{div=64},?)">
      cute.memref.store_vec %cst, %rmem_59 : !memref_rmem_f32_
      cf.cond_br %275, ^bb10, ^bb11
    ^bb10:  // pred: ^bb9
      %int_tuple_104 = cute.make_int_tuple(%314) : (i32) -> !cute.int_tuple<"?">
      %ptr_105 = cute.add_offset(%iter, %int_tuple_104) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %318 = builtin.unrealized_conversion_cast %ptr_105 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      %319 = nvvm.mbarrier.wait.parity %318, %315 {kind = #nvvm.mbar_wait<try>} : !llvm.ptr<3>, i32 -> i1
      cf.br ^bb12(%319 : i1)
    ^bb11:  // pred: ^bb9
      cf.br ^bb12(%true : i1)
    ^bb12(%320: i1):  // 2 preds: ^bb10, ^bb11
      cf.br ^bb13
    ^bb13:  // pred: ^bb12
      %321 = arith.extui %320 : i1 to i32
      %322 = arith.cmpi eq, %321, %c0_i32 : i32
      cf.cond_br %322, ^bb14, ^bb15
    ^bb14:  // pred: ^bb13
      %int_tuple_106 = cute.make_int_tuple(%314) : (i32) -> !cute.int_tuple<"?">
      %ptr_107 = cute.add_offset(%iter, %int_tuple_106) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %323 = builtin.unrealized_conversion_cast %ptr_107 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %323, %315, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      cf.br ^bb15
    ^bb15:  // 2 preds: ^bb13, ^bb14
      %coord_108 = cute.make_coord(%314) : (i32) -> !cute.coord<"(_,_,_,?)">
      %idx_109 = cute.crd2idx(%coord_108, %49) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((8,1),2,4,(1,4)):((1,0),32,1024,(0,4096))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_110 = cute.add_offset(%ptr_78, %idx_109) : (!cute.ptr<f16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %view_111 = cute.make_view(%ptr_110) : !memref_smem_f16_
      %324 = builtin.unrealized_conversion_cast %view_111 : !memref_smem_f16_ to !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)>
      %ptr_112 = cute.add_offset(%ptr_82, %idx_109) : (!cute.ptr<f16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %view_113 = cute.make_view(%ptr_112) : !memref_smem_f16_
      %325 = builtin.unrealized_conversion_cast %view_113 : !memref_smem_f16_ to !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)>
      cf.br ^bb16(%c0_i32 : i32)
    ^bb16(%326: i32):  // 2 preds: ^bb15, ^bb17
      %327 = arith.cmpi slt, %326, %276 : i32
      cf.cond_br %327, ^bb17, ^bb18 {llvm.loop_annotation = #loop_annotation}
    ^bb17:  // pred: ^bb16
      %coord_114 = cute.make_coord(%326) : (i32) -> !cute.coord<"(_,?)">
      %idx_115 = cute.crd2idx(%coord_114, %48) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((32)))">) -> !cute.int_tuple<"?{div=32}">
      %ptr_116 = cute.add_offset(%ptr_78, %idx_115) : (!cute.ptr<f16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %idx_117 = cute.crd2idx(%coord_114, %47) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_118 = cute.add_offset(%iter_79, %idx_117) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
      %swizzled = cute.apply_swizzle(%ptr_116) : !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %ptr_119 = cute.add_offset(%swizzled, %idx_109) : (!cute.ptr<f16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %328 = cute_nvgpu.arch.copy.ldsm %ptr_119{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <f16, smem, align<16>, S<3,4,3>> -> vector<4xi32>
      %329 = vector.extractelement %328[%46 : i32] : vector<4xi32>
      %330 = builtin.unrealized_conversion_cast %ptr_118 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
      llvm.store %329, %330 : i32, !llvm.ptr
      %331 = vector.extractelement %328[%64 : i32] : vector<4xi32>
      %ptr_120 = cute.add_offset(%ptr_118, %58) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<f16, rmem, align<4>>
      %332 = builtin.unrealized_conversion_cast %ptr_120 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %331, %332 : i32, !llvm.ptr
      %333 = vector.extractelement %328[%63 : i32] : vector<4xi32>
      %ptr_121 = cute.add_offset(%ptr_118, %56) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<f16, rmem, align<8>>
      %334 = builtin.unrealized_conversion_cast %ptr_121 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
      llvm.store %333, %334 : i32, !llvm.ptr
      %335 = vector.extractelement %328[%45 : i32] : vector<4xi32>
      %ptr_122 = cute.add_offset(%ptr_118, %44) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<f16, rmem, align<4>>
      %336 = builtin.unrealized_conversion_cast %ptr_122 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %335, %336 : i32, !llvm.ptr
      %337 = arith.addi %326, %c1_i32 : i32
      cf.br ^bb16(%337 : i32)
    ^bb18:  // pred: ^bb16
      cf.br ^bb19(%c0_i32 : i32)
    ^bb19(%338: i32):  // 2 preds: ^bb18, ^bb20
      %339 = arith.cmpi slt, %338, %276 : i32
      cf.cond_br %339, ^bb20, ^bb21 {llvm.loop_annotation = #loop_annotation}
    ^bb20:  // pred: ^bb19
      %coord_123 = cute.make_coord(%338) : (i32) -> !cute.coord<"(_,?)">
      %idx_124 = cute.crd2idx(%coord_123, %48) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((32)))">) -> !cute.int_tuple<"?{div=32}">
      %ptr_125 = cute.add_offset(%ptr_82, %idx_124) : (!cute.ptr<f16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %idx_126 = cute.crd2idx(%coord_123, %47) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_127 = cute.add_offset(%iter_83, %idx_126) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<8>>
      %swizzled_128 = cute.apply_swizzle(%ptr_125) : !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %ptr_129 = cute.add_offset(%swizzled_128, %idx_109) : (!cute.ptr<f16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %340 = cute_nvgpu.arch.copy.ldsm %ptr_129{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <f16, smem, align<16>, S<3,4,3>> -> vector<4xi32>
      %341 = vector.extractelement %340[%46 : i32] : vector<4xi32>
      %342 = builtin.unrealized_conversion_cast %ptr_127 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
      llvm.store %341, %342 : i32, !llvm.ptr
      %343 = vector.extractelement %340[%64 : i32] : vector<4xi32>
      %ptr_130 = cute.add_offset(%ptr_127, %58) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<f16, rmem, align<4>>
      %344 = builtin.unrealized_conversion_cast %ptr_130 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %343, %344 : i32, !llvm.ptr
      %345 = vector.extractelement %340[%63 : i32] : vector<4xi32>
      %ptr_131 = cute.add_offset(%ptr_127, %56) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<f16, rmem, align<8>>
      %346 = builtin.unrealized_conversion_cast %ptr_131 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
      llvm.store %345, %346 : i32, !llvm.ptr
      %347 = vector.extractelement %340[%45 : i32] : vector<4xi32>
      %ptr_132 = cute.add_offset(%ptr_127, %44) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<f16, rmem, align<4>>
      %348 = builtin.unrealized_conversion_cast %ptr_132 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %347, %348 : i32, !llvm.ptr
      %349 = arith.addi %338, %c1_i32 : i32
      cf.br ^bb19(%349 : i32)
    ^bb21:  // pred: ^bb19
      cf.br ^bb22(%c0_i32, %324, %325, %c0_i32, %314, %315 : i32, !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)>, !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)>, i32, i32, i32)
    ^bb22(%350: i32, %351: !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)>, %352: !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)>, %353: i32, %354: i32, %355: i32):  // 2 preds: ^bb21, ^bb91
      %356 = arith.cmpi slt, %350, %277 : i32
      cf.cond_br %356, ^bb23, ^bb92 {loop_annotation = #loop_annotation1}
    ^bb23:  // pred: ^bb22
      %357 = builtin.unrealized_conversion_cast %352 : !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)> to !memref_smem_f16_
      %358 = builtin.unrealized_conversion_cast %351 : !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)> to !memref_smem_f16_
      %iter_133 = cute.get_iter(%358) : !memref_smem_f16_
      %ptr_134 = cute.add_offset(%iter_133, %62) : (!cute.ptr<f16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"1024">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      cf.br ^bb24(%c0_i32 : i32)
    ^bb24(%359: i32):  // 2 preds: ^bb23, ^bb25
      %360 = arith.cmpi slt, %359, %276 : i32
      cf.cond_br %360, ^bb25, ^bb26 {llvm.loop_annotation = #loop_annotation}
    ^bb25:  // pred: ^bb24
      %coord_135 = cute.make_coord(%359) : (i32) -> !cute.coord<"(_,?)">
      %idx_136 = cute.crd2idx(%coord_135, %48) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((32)))">) -> !cute.int_tuple<"?{div=32}">
      %ptr_137 = cute.add_offset(%ptr_134, %idx_136) : (!cute.ptr<f16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %idx_138 = cute.crd2idx(%coord_135, %47) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_139 = cute.add_offset(%ptr_84, %idx_138) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
      %swizzled_140 = cute.apply_swizzle(%ptr_137) : !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %361 = cute_nvgpu.arch.copy.ldsm %swizzled_140{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <f16, smem, align<16>, S<3,4,3>> -> vector<4xi32>
      %362 = vector.extractelement %361[%46 : i32] : vector<4xi32>
      %363 = builtin.unrealized_conversion_cast %ptr_139 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
      llvm.store %362, %363 : i32, !llvm.ptr
      %364 = vector.extractelement %361[%64 : i32] : vector<4xi32>
      %ptr_141 = cute.add_offset(%ptr_139, %58) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<f16, rmem, align<4>>
      %365 = builtin.unrealized_conversion_cast %ptr_141 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %364, %365 : i32, !llvm.ptr
      %366 = vector.extractelement %361[%63 : i32] : vector<4xi32>
      %ptr_142 = cute.add_offset(%ptr_139, %56) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<f16, rmem, align<8>>
      %367 = builtin.unrealized_conversion_cast %ptr_142 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
      llvm.store %366, %367 : i32, !llvm.ptr
      %368 = vector.extractelement %361[%45 : i32] : vector<4xi32>
      %ptr_143 = cute.add_offset(%ptr_139, %44) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<f16, rmem, align<4>>
      %369 = builtin.unrealized_conversion_cast %ptr_143 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %368, %369 : i32, !llvm.ptr
      %370 = arith.addi %359, %c1_i32 : i32
      cf.br ^bb24(%370 : i32)
    ^bb26:  // pred: ^bb24
      %iter_144 = cute.get_iter(%357) : !memref_smem_f16_
      %ptr_145 = cute.add_offset(%iter_144, %62) : (!cute.ptr<f16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"1024">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      cf.br ^bb27(%c0_i32 : i32)
    ^bb27(%371: i32):  // 2 preds: ^bb26, ^bb28
      %372 = arith.cmpi slt, %371, %276 : i32
      cf.cond_br %372, ^bb28, ^bb29 {llvm.loop_annotation = #loop_annotation}
    ^bb28:  // pred: ^bb27
      %coord_146 = cute.make_coord(%371) : (i32) -> !cute.coord<"(_,?)">
      %idx_147 = cute.crd2idx(%coord_146, %48) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((32)))">) -> !cute.int_tuple<"?{div=32}">
      %ptr_148 = cute.add_offset(%ptr_145, %idx_147) : (!cute.ptr<f16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %idx_149 = cute.crd2idx(%coord_146, %47) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_150 = cute.add_offset(%ptr_85, %idx_149) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<8>>
      %swizzled_151 = cute.apply_swizzle(%ptr_148) : !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %373 = cute_nvgpu.arch.copy.ldsm %swizzled_151{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <f16, smem, align<16>, S<3,4,3>> -> vector<4xi32>
      %374 = vector.extractelement %373[%46 : i32] : vector<4xi32>
      %375 = builtin.unrealized_conversion_cast %ptr_150 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
      llvm.store %374, %375 : i32, !llvm.ptr
      %376 = vector.extractelement %373[%64 : i32] : vector<4xi32>
      %ptr_152 = cute.add_offset(%ptr_150, %58) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<f16, rmem, align<4>>
      %377 = builtin.unrealized_conversion_cast %ptr_152 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %376, %377 : i32, !llvm.ptr
      %378 = vector.extractelement %373[%63 : i32] : vector<4xi32>
      %ptr_153 = cute.add_offset(%ptr_150, %56) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<f16, rmem, align<8>>
      %379 = builtin.unrealized_conversion_cast %ptr_153 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
      llvm.store %378, %379 : i32, !llvm.ptr
      %380 = vector.extractelement %373[%45 : i32] : vector<4xi32>
      %ptr_154 = cute.add_offset(%ptr_150, %44) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<f16, rmem, align<4>>
      %381 = builtin.unrealized_conversion_cast %ptr_154 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %380, %381 : i32, !llvm.ptr
      %382 = arith.addi %371, %c1_i32 : i32
      cf.br ^bb27(%382 : i32)
    ^bb29:  // pred: ^bb27
      cf.br ^bb30(%c0_i32 : i32)
    ^bb30(%383: i32):  // 2 preds: ^bb29, ^bb37
      %384 = arith.cmpi slt, %383, %278 : i32
      cf.cond_br %384, ^bb31, ^bb38 {llvm.loop_annotation = #loop_annotation}
    ^bb31:  // pred: ^bb30
      cf.br ^bb32(%c0_i32 : i32)
    ^bb32(%385: i32):  // 2 preds: ^bb31, ^bb36
      %386 = arith.cmpi slt, %385, %276 : i32
      cf.cond_br %386, ^bb33, ^bb37 {llvm.loop_annotation = #loop_annotation}
    ^bb33:  // pred: ^bb32
      %coord_155 = cute.make_coord(%385, %383) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_156 = cute.crd2idx(%coord_155, %42) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">) -> !cute.int_tuple<"?{div=8}">
      %ptr_157 = cute.add_offset(%iter_79, %idx_156) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
      %387 = builtin.unrealized_conversion_cast %ptr_157 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
      %388 = llvm.getelementptr %387[1] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
      %389 = llvm.getelementptr %387[2] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
      %390 = llvm.getelementptr %387[3] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
      cf.br ^bb34(%c0_i32 : i32)
    ^bb34(%391: i32):  // 2 preds: ^bb33, ^bb35
      %392 = arith.cmpi slt, %391, %279 : i32
      cf.cond_br %392, ^bb35, ^bb36 {llvm.loop_annotation = #loop_annotation}
    ^bb35:  // pred: ^bb34
      %coord_158 = cute.make_coord(%391, %383) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_159 = cute.make_coord(%385, %391) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_160 = cute.crd2idx(%coord_158, %41) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),4,1):((1,2),4,0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_161 = cute.add_offset(%iter_83, %idx_160) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f16, rmem, align<8>>
      %idx_162 = cute.crd2idx(%coord_159, %50) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,4):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_163 = cute.add_offset(%iter_86, %idx_162) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %393 = llvm.load %387 : !llvm.ptr -> vector<2xf16>
      %394 = llvm.load %388 : !llvm.ptr -> vector<2xf16>
      %395 = llvm.load %389 : !llvm.ptr -> vector<2xf16>
      %396 = llvm.load %390 : !llvm.ptr -> vector<2xf16>
      %397 = builtin.unrealized_conversion_cast %ptr_161 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
      %398 = llvm.load %397 : !llvm.ptr -> vector<2xf16>
      %399 = llvm.getelementptr %397[1] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
      %400 = llvm.load %399 : !llvm.ptr -> vector<2xf16>
      %401 = builtin.unrealized_conversion_cast %ptr_163 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %402 = llvm.load %401 : !llvm.ptr -> f32
      %403 = llvm.getelementptr %401[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %404 = llvm.load %403 : !llvm.ptr -> f32
      %405 = llvm.getelementptr %401[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %406 = llvm.load %405 : !llvm.ptr -> f32
      %407 = llvm.getelementptr %401[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %408 = llvm.load %407 : !llvm.ptr -> f32
      %409:4 = cute_nvgpu.arch.mma.SM80 A[%393, %394, %395, %396]  B[%398, %400]  C[%402, %404, %406, %408] < {a_type = f16, b_type = f16, shape_MNK = #cute.shape<"(16,8,16)">}> : (vector<2xf16>, vector<2xf16>, f32) -> (f32, f32, f32, f32)
      llvm.store %409#0, %401 : f32, !llvm.ptr
      llvm.store %409#1, %403 : f32, !llvm.ptr
      llvm.store %409#2, %405 : f32, !llvm.ptr
      llvm.store %409#3, %407 : f32, !llvm.ptr
      %410 = arith.addi %391, %c1_i32 : i32
      cf.br ^bb34(%410 : i32)
    ^bb36:  // pred: ^bb34
      %411 = arith.addi %385, %c1_i32 : i32
      cf.br ^bb32(%411 : i32)
    ^bb37:  // pred: ^bb32
      %412 = arith.addi %383, %c1_i32 : i32
      cf.br ^bb30(%412 : i32)
    ^bb38:  // pred: ^bb30
      %ptr_164 = cute.add_offset(%iter_133, %40) : (!cute.ptr<f16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"2048">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      cf.br ^bb39(%c0_i32 : i32)
    ^bb39(%413: i32):  // 2 preds: ^bb38, ^bb40
      %414 = arith.cmpi slt, %413, %276 : i32
      cf.cond_br %414, ^bb40, ^bb41 {llvm.loop_annotation = #loop_annotation}
    ^bb40:  // pred: ^bb39
      %coord_165 = cute.make_coord(%413) : (i32) -> !cute.coord<"(_,?)">
      %idx_166 = cute.crd2idx(%coord_165, %48) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((32)))">) -> !cute.int_tuple<"?{div=32}">
      %ptr_167 = cute.add_offset(%ptr_164, %idx_166) : (!cute.ptr<f16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %idx_168 = cute.crd2idx(%coord_165, %47) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_169 = cute.add_offset(%ptr_87, %idx_168) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
      %swizzled_170 = cute.apply_swizzle(%ptr_167) : !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %415 = cute_nvgpu.arch.copy.ldsm %swizzled_170{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <f16, smem, align<16>, S<3,4,3>> -> vector<4xi32>
      %416 = vector.extractelement %415[%46 : i32] : vector<4xi32>
      %417 = builtin.unrealized_conversion_cast %ptr_169 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
      llvm.store %416, %417 : i32, !llvm.ptr
      %418 = vector.extractelement %415[%64 : i32] : vector<4xi32>
      %ptr_171 = cute.add_offset(%ptr_169, %58) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<f16, rmem, align<4>>
      %419 = builtin.unrealized_conversion_cast %ptr_171 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %418, %419 : i32, !llvm.ptr
      %420 = vector.extractelement %415[%63 : i32] : vector<4xi32>
      %ptr_172 = cute.add_offset(%ptr_169, %56) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<f16, rmem, align<8>>
      %421 = builtin.unrealized_conversion_cast %ptr_172 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
      llvm.store %420, %421 : i32, !llvm.ptr
      %422 = vector.extractelement %415[%45 : i32] : vector<4xi32>
      %ptr_173 = cute.add_offset(%ptr_169, %44) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<f16, rmem, align<4>>
      %423 = builtin.unrealized_conversion_cast %ptr_173 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %422, %423 : i32, !llvm.ptr
      %424 = arith.addi %413, %c1_i32 : i32
      cf.br ^bb39(%424 : i32)
    ^bb41:  // pred: ^bb39
      %ptr_174 = cute.add_offset(%iter_144, %40) : (!cute.ptr<f16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"2048">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      cf.br ^bb42(%c0_i32 : i32)
    ^bb42(%425: i32):  // 2 preds: ^bb41, ^bb43
      %426 = arith.cmpi slt, %425, %276 : i32
      cf.cond_br %426, ^bb43, ^bb44 {llvm.loop_annotation = #loop_annotation}
    ^bb43:  // pred: ^bb42
      %coord_175 = cute.make_coord(%425) : (i32) -> !cute.coord<"(_,?)">
      %idx_176 = cute.crd2idx(%coord_175, %48) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((32)))">) -> !cute.int_tuple<"?{div=32}">
      %ptr_177 = cute.add_offset(%ptr_174, %idx_176) : (!cute.ptr<f16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %idx_178 = cute.crd2idx(%coord_175, %47) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_179 = cute.add_offset(%ptr_88, %idx_178) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<8>>
      %swizzled_180 = cute.apply_swizzle(%ptr_177) : !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %427 = cute_nvgpu.arch.copy.ldsm %swizzled_180{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <f16, smem, align<16>, S<3,4,3>> -> vector<4xi32>
      %428 = vector.extractelement %427[%46 : i32] : vector<4xi32>
      %429 = builtin.unrealized_conversion_cast %ptr_179 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
      llvm.store %428, %429 : i32, !llvm.ptr
      %430 = vector.extractelement %427[%64 : i32] : vector<4xi32>
      %ptr_181 = cute.add_offset(%ptr_179, %58) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<f16, rmem, align<4>>
      %431 = builtin.unrealized_conversion_cast %ptr_181 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %430, %431 : i32, !llvm.ptr
      %432 = vector.extractelement %427[%63 : i32] : vector<4xi32>
      %ptr_182 = cute.add_offset(%ptr_179, %56) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<f16, rmem, align<8>>
      %433 = builtin.unrealized_conversion_cast %ptr_182 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
      llvm.store %432, %433 : i32, !llvm.ptr
      %434 = vector.extractelement %427[%45 : i32] : vector<4xi32>
      %ptr_183 = cute.add_offset(%ptr_179, %44) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<f16, rmem, align<4>>
      %435 = builtin.unrealized_conversion_cast %ptr_183 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %434, %435 : i32, !llvm.ptr
      %436 = arith.addi %425, %c1_i32 : i32
      cf.br ^bb42(%436 : i32)
    ^bb44:  // pred: ^bb42
      cf.br ^bb45(%c0_i32 : i32)
    ^bb45(%437: i32):  // 2 preds: ^bb44, ^bb52
      %438 = arith.cmpi slt, %437, %278 : i32
      cf.cond_br %438, ^bb46, ^bb53 {llvm.loop_annotation = #loop_annotation}
    ^bb46:  // pred: ^bb45
      cf.br ^bb47(%c0_i32 : i32)
    ^bb47(%439: i32):  // 2 preds: ^bb46, ^bb51
      %440 = arith.cmpi slt, %439, %276 : i32
      cf.cond_br %440, ^bb48, ^bb52 {llvm.loop_annotation = #loop_annotation}
    ^bb48:  // pred: ^bb47
      %coord_184 = cute.make_coord(%439, %437) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_185 = cute.crd2idx(%coord_184, %42) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">) -> !cute.int_tuple<"?{div=8}">
      %ptr_186 = cute.add_offset(%ptr_84, %idx_185) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
      %441 = builtin.unrealized_conversion_cast %ptr_186 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
      %442 = llvm.getelementptr %441[1] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
      %443 = llvm.getelementptr %441[2] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
      %444 = llvm.getelementptr %441[3] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
      cf.br ^bb49(%c0_i32 : i32)
    ^bb49(%445: i32):  // 2 preds: ^bb48, ^bb50
      %446 = arith.cmpi slt, %445, %279 : i32
      cf.cond_br %446, ^bb50, ^bb51 {llvm.loop_annotation = #loop_annotation}
    ^bb50:  // pred: ^bb49
      %coord_187 = cute.make_coord(%445, %437) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_188 = cute.make_coord(%439, %445) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_189 = cute.crd2idx(%coord_187, %41) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),4,1):((1,2),4,0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_190 = cute.add_offset(%ptr_85, %idx_189) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f16, rmem, align<8>>
      %idx_191 = cute.crd2idx(%coord_188, %50) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,4):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_192 = cute.add_offset(%iter_86, %idx_191) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %447 = llvm.load %441 : !llvm.ptr -> vector<2xf16>
      %448 = llvm.load %442 : !llvm.ptr -> vector<2xf16>
      %449 = llvm.load %443 : !llvm.ptr -> vector<2xf16>
      %450 = llvm.load %444 : !llvm.ptr -> vector<2xf16>
      %451 = builtin.unrealized_conversion_cast %ptr_190 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
      %452 = llvm.load %451 : !llvm.ptr -> vector<2xf16>
      %453 = llvm.getelementptr %451[1] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
      %454 = llvm.load %453 : !llvm.ptr -> vector<2xf16>
      %455 = builtin.unrealized_conversion_cast %ptr_192 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %456 = llvm.load %455 : !llvm.ptr -> f32
      %457 = llvm.getelementptr %455[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %458 = llvm.load %457 : !llvm.ptr -> f32
      %459 = llvm.getelementptr %455[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %460 = llvm.load %459 : !llvm.ptr -> f32
      %461 = llvm.getelementptr %455[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %462 = llvm.load %461 : !llvm.ptr -> f32
      %463:4 = cute_nvgpu.arch.mma.SM80 A[%447, %448, %449, %450]  B[%452, %454]  C[%456, %458, %460, %462] < {a_type = f16, b_type = f16, shape_MNK = #cute.shape<"(16,8,16)">}> : (vector<2xf16>, vector<2xf16>, f32) -> (f32, f32, f32, f32)
      llvm.store %463#0, %455 : f32, !llvm.ptr
      llvm.store %463#1, %457 : f32, !llvm.ptr
      llvm.store %463#2, %459 : f32, !llvm.ptr
      llvm.store %463#3, %461 : f32, !llvm.ptr
      %464 = arith.addi %445, %c1_i32 : i32
      cf.br ^bb49(%464 : i32)
    ^bb51:  // pred: ^bb49
      %465 = arith.addi %439, %c1_i32 : i32
      cf.br ^bb47(%465 : i32)
    ^bb52:  // pred: ^bb47
      %466 = arith.addi %437, %c1_i32 : i32
      cf.br ^bb45(%466 : i32)
    ^bb53:  // pred: ^bb45
      %ptr_193 = cute.add_offset(%iter_133, %38) : (!cute.ptr<f16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"3072">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      cf.br ^bb54(%c0_i32 : i32)
    ^bb54(%467: i32):  // 2 preds: ^bb53, ^bb55
      %468 = arith.cmpi slt, %467, %276 : i32
      cf.cond_br %468, ^bb55, ^bb56 {llvm.loop_annotation = #loop_annotation}
    ^bb55:  // pred: ^bb54
      %coord_194 = cute.make_coord(%467) : (i32) -> !cute.coord<"(_,?)">
      %idx_195 = cute.crd2idx(%coord_194, %48) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((32)))">) -> !cute.int_tuple<"?{div=32}">
      %ptr_196 = cute.add_offset(%ptr_193, %idx_195) : (!cute.ptr<f16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %idx_197 = cute.crd2idx(%coord_194, %47) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_198 = cute.add_offset(%ptr_89, %idx_197) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
      %swizzled_199 = cute.apply_swizzle(%ptr_196) : !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %469 = cute_nvgpu.arch.copy.ldsm %swizzled_199{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <f16, smem, align<16>, S<3,4,3>> -> vector<4xi32>
      %470 = vector.extractelement %469[%46 : i32] : vector<4xi32>
      %471 = builtin.unrealized_conversion_cast %ptr_198 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
      llvm.store %470, %471 : i32, !llvm.ptr
      %472 = vector.extractelement %469[%64 : i32] : vector<4xi32>
      %ptr_200 = cute.add_offset(%ptr_198, %58) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<f16, rmem, align<4>>
      %473 = builtin.unrealized_conversion_cast %ptr_200 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %472, %473 : i32, !llvm.ptr
      %474 = vector.extractelement %469[%63 : i32] : vector<4xi32>
      %ptr_201 = cute.add_offset(%ptr_198, %56) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<f16, rmem, align<8>>
      %475 = builtin.unrealized_conversion_cast %ptr_201 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
      llvm.store %474, %475 : i32, !llvm.ptr
      %476 = vector.extractelement %469[%45 : i32] : vector<4xi32>
      %ptr_202 = cute.add_offset(%ptr_198, %44) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<f16, rmem, align<4>>
      %477 = builtin.unrealized_conversion_cast %ptr_202 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %476, %477 : i32, !llvm.ptr
      %478 = arith.addi %467, %c1_i32 : i32
      cf.br ^bb54(%478 : i32)
    ^bb56:  // pred: ^bb54
      %ptr_203 = cute.add_offset(%iter_144, %38) : (!cute.ptr<f16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"3072">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      cf.br ^bb57(%c0_i32 : i32)
    ^bb57(%479: i32):  // 2 preds: ^bb56, ^bb58
      %480 = arith.cmpi slt, %479, %276 : i32
      cf.cond_br %480, ^bb58, ^bb59 {llvm.loop_annotation = #loop_annotation}
    ^bb58:  // pred: ^bb57
      %coord_204 = cute.make_coord(%479) : (i32) -> !cute.coord<"(_,?)">
      %idx_205 = cute.crd2idx(%coord_204, %48) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((32)))">) -> !cute.int_tuple<"?{div=32}">
      %ptr_206 = cute.add_offset(%ptr_203, %idx_205) : (!cute.ptr<f16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %idx_207 = cute.crd2idx(%coord_204, %47) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_208 = cute.add_offset(%ptr_90, %idx_207) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<8>>
      %swizzled_209 = cute.apply_swizzle(%ptr_206) : !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %481 = cute_nvgpu.arch.copy.ldsm %swizzled_209{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <f16, smem, align<16>, S<3,4,3>> -> vector<4xi32>
      %482 = vector.extractelement %481[%46 : i32] : vector<4xi32>
      %483 = builtin.unrealized_conversion_cast %ptr_208 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
      llvm.store %482, %483 : i32, !llvm.ptr
      %484 = vector.extractelement %481[%64 : i32] : vector<4xi32>
      %ptr_210 = cute.add_offset(%ptr_208, %58) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<f16, rmem, align<4>>
      %485 = builtin.unrealized_conversion_cast %ptr_210 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %484, %485 : i32, !llvm.ptr
      %486 = vector.extractelement %481[%63 : i32] : vector<4xi32>
      %ptr_211 = cute.add_offset(%ptr_208, %56) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<f16, rmem, align<8>>
      %487 = builtin.unrealized_conversion_cast %ptr_211 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
      llvm.store %486, %487 : i32, !llvm.ptr
      %488 = vector.extractelement %481[%45 : i32] : vector<4xi32>
      %ptr_212 = cute.add_offset(%ptr_208, %44) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<f16, rmem, align<4>>
      %489 = builtin.unrealized_conversion_cast %ptr_212 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %488, %489 : i32, !llvm.ptr
      %490 = arith.addi %479, %c1_i32 : i32
      cf.br ^bb57(%490 : i32)
    ^bb59:  // pred: ^bb57
      cf.br ^bb60(%c0_i32 : i32)
    ^bb60(%491: i32):  // 2 preds: ^bb59, ^bb67
      %492 = arith.cmpi slt, %491, %278 : i32
      cf.cond_br %492, ^bb61, ^bb68 {llvm.loop_annotation = #loop_annotation}
    ^bb61:  // pred: ^bb60
      cf.br ^bb62(%c0_i32 : i32)
    ^bb62(%493: i32):  // 2 preds: ^bb61, ^bb66
      %494 = arith.cmpi slt, %493, %276 : i32
      cf.cond_br %494, ^bb63, ^bb67 {llvm.loop_annotation = #loop_annotation}
    ^bb63:  // pred: ^bb62
      %coord_213 = cute.make_coord(%493, %491) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_214 = cute.crd2idx(%coord_213, %42) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">) -> !cute.int_tuple<"?{div=8}">
      %ptr_215 = cute.add_offset(%ptr_87, %idx_214) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
      %495 = builtin.unrealized_conversion_cast %ptr_215 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
      %496 = llvm.getelementptr %495[1] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
      %497 = llvm.getelementptr %495[2] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
      %498 = llvm.getelementptr %495[3] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
      cf.br ^bb64(%c0_i32 : i32)
    ^bb64(%499: i32):  // 2 preds: ^bb63, ^bb65
      %500 = arith.cmpi slt, %499, %279 : i32
      cf.cond_br %500, ^bb65, ^bb66 {llvm.loop_annotation = #loop_annotation}
    ^bb65:  // pred: ^bb64
      %coord_216 = cute.make_coord(%499, %491) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_217 = cute.make_coord(%493, %499) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_218 = cute.crd2idx(%coord_216, %41) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),4,1):((1,2),4,0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_219 = cute.add_offset(%ptr_88, %idx_218) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f16, rmem, align<8>>
      %idx_220 = cute.crd2idx(%coord_217, %50) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,4):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_221 = cute.add_offset(%iter_86, %idx_220) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %501 = llvm.load %495 : !llvm.ptr -> vector<2xf16>
      %502 = llvm.load %496 : !llvm.ptr -> vector<2xf16>
      %503 = llvm.load %497 : !llvm.ptr -> vector<2xf16>
      %504 = llvm.load %498 : !llvm.ptr -> vector<2xf16>
      %505 = builtin.unrealized_conversion_cast %ptr_219 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
      %506 = llvm.load %505 : !llvm.ptr -> vector<2xf16>
      %507 = llvm.getelementptr %505[1] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
      %508 = llvm.load %507 : !llvm.ptr -> vector<2xf16>
      %509 = builtin.unrealized_conversion_cast %ptr_221 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %510 = llvm.load %509 : !llvm.ptr -> f32
      %511 = llvm.getelementptr %509[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %512 = llvm.load %511 : !llvm.ptr -> f32
      %513 = llvm.getelementptr %509[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %514 = llvm.load %513 : !llvm.ptr -> f32
      %515 = llvm.getelementptr %509[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %516 = llvm.load %515 : !llvm.ptr -> f32
      %517:4 = cute_nvgpu.arch.mma.SM80 A[%501, %502, %503, %504]  B[%506, %508]  C[%510, %512, %514, %516] < {a_type = f16, b_type = f16, shape_MNK = #cute.shape<"(16,8,16)">}> : (vector<2xf16>, vector<2xf16>, f32) -> (f32, f32, f32, f32)
      llvm.store %517#0, %509 : f32, !llvm.ptr
      llvm.store %517#1, %511 : f32, !llvm.ptr
      llvm.store %517#2, %513 : f32, !llvm.ptr
      llvm.store %517#3, %515 : f32, !llvm.ptr
      %518 = arith.addi %499, %c1_i32 : i32
      cf.br ^bb64(%518 : i32)
    ^bb66:  // pred: ^bb64
      %519 = arith.addi %493, %c1_i32 : i32
      cf.br ^bb62(%519 : i32)
    ^bb67:  // pred: ^bb62
      %520 = arith.addi %491, %c1_i32 : i32
      cf.br ^bb60(%520 : i32)
    ^bb68:  // pred: ^bb60
      cf.cond_br %99, ^bb69, ^bb70
    ^bb69:  // pred: ^bb68
      %int_tuple_222 = cute.make_int_tuple(%354) : (i32) -> !cute.int_tuple<"?">
      %ptr_223 = cute.add_offset(%ptr_7, %int_tuple_222) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %521 = builtin.unrealized_conversion_cast %ptr_223 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %521, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>} : !llvm.ptr<3>, i32
      cf.br ^bb70
    ^bb70:  // 2 preds: ^bb68, ^bb69
      %522 = arith.addi %354, %c1_i32 : i32
      %523 = arith.addi %353, %c1_i32 : i32
      %524 = arith.cmpi eq, %522, %c4_i32 : i32
      %525 = arith.select %524, %c0_i32, %522 : i32
      cf.cond_br %524, ^bb71, ^bb72
    ^bb71:  // pred: ^bb70
      %526 = arith.xori %355, %c1_i32 : i32
      cf.br ^bb73(%526 : i32)
    ^bb72:  // pred: ^bb70
      cf.br ^bb73(%355 : i32)
    ^bb73(%527: i32):  // 2 preds: ^bb71, ^bb72
      cf.br ^bb74
    ^bb74:  // pred: ^bb73
      %int_tuple_224 = cute.make_int_tuple(%525) : (i32) -> !cute.int_tuple<"?">
      %ptr_225 = cute.add_offset(%iter, %int_tuple_224) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %528 = builtin.unrealized_conversion_cast %ptr_225 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      %529 = nvvm.mbarrier.wait.parity %528, %527 {kind = #nvvm.mbar_wait<try>} : !llvm.ptr<3>, i32 -> i1
      %coord_226 = cute.make_coord(%525) : (i32) -> !cute.coord<"(_,_,_,?)">
      %idx_227 = cute.crd2idx(%coord_226, %49) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((8,1),2,4,(1,4)):((1,0),32,1024,(0,4096))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_228 = cute.add_offset(%ptr_78, %idx_227) : (!cute.ptr<f16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %view_229 = cute.make_view(%ptr_228) : !memref_smem_f16_
      %530 = builtin.unrealized_conversion_cast %view_229 : !memref_smem_f16_ to !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)>
      %ptr_230 = cute.add_offset(%ptr_82, %idx_227) : (!cute.ptr<f16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %view_231 = cute.make_view(%ptr_230) : !memref_smem_f16_
      %531 = builtin.unrealized_conversion_cast %view_231 : !memref_smem_f16_ to !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)>
      %532 = arith.extui %529 : i1 to i32
      %533 = arith.cmpi eq, %532, %c0_i32 : i32
      cf.cond_br %533, ^bb75, ^bb76
    ^bb75:  // pred: ^bb74
      nvvm.mbarrier.try_wait.parity.shared %528, %527, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      cf.br ^bb76
    ^bb76:  // 2 preds: ^bb74, ^bb75
      cf.br ^bb77(%c0_i32 : i32)
    ^bb77(%534: i32):  // 2 preds: ^bb76, ^bb78
      %535 = arith.cmpi slt, %534, %276 : i32
      cf.cond_br %535, ^bb78, ^bb79 {llvm.loop_annotation = #loop_annotation}
    ^bb78:  // pred: ^bb77
      %coord_232 = cute.make_coord(%534) : (i32) -> !cute.coord<"(_,?)">
      %idx_233 = cute.crd2idx(%coord_232, %48) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((32)))">) -> !cute.int_tuple<"?{div=32}">
      %ptr_234 = cute.add_offset(%ptr_78, %idx_233) : (!cute.ptr<f16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %idx_235 = cute.crd2idx(%coord_232, %47) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_236 = cute.add_offset(%iter_79, %idx_235) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
      %swizzled_237 = cute.apply_swizzle(%ptr_234) : !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %ptr_238 = cute.add_offset(%swizzled_237, %idx_227) : (!cute.ptr<f16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %536 = cute_nvgpu.arch.copy.ldsm %ptr_238{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <f16, smem, align<16>, S<3,4,3>> -> vector<4xi32>
      %537 = vector.extractelement %536[%46 : i32] : vector<4xi32>
      %538 = builtin.unrealized_conversion_cast %ptr_236 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
      llvm.store %537, %538 : i32, !llvm.ptr
      %539 = vector.extractelement %536[%64 : i32] : vector<4xi32>
      %ptr_239 = cute.add_offset(%ptr_236, %58) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<f16, rmem, align<4>>
      %540 = builtin.unrealized_conversion_cast %ptr_239 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %539, %540 : i32, !llvm.ptr
      %541 = vector.extractelement %536[%63 : i32] : vector<4xi32>
      %ptr_240 = cute.add_offset(%ptr_236, %56) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<f16, rmem, align<8>>
      %542 = builtin.unrealized_conversion_cast %ptr_240 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
      llvm.store %541, %542 : i32, !llvm.ptr
      %543 = vector.extractelement %536[%45 : i32] : vector<4xi32>
      %ptr_241 = cute.add_offset(%ptr_236, %44) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<f16, rmem, align<4>>
      %544 = builtin.unrealized_conversion_cast %ptr_241 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %543, %544 : i32, !llvm.ptr
      %545 = arith.addi %534, %c1_i32 : i32
      cf.br ^bb77(%545 : i32)
    ^bb79:  // pred: ^bb77
      cf.br ^bb80(%c0_i32 : i32)
    ^bb80(%546: i32):  // 2 preds: ^bb79, ^bb81
      %547 = arith.cmpi slt, %546, %276 : i32
      cf.cond_br %547, ^bb81, ^bb82 {llvm.loop_annotation = #loop_annotation}
    ^bb81:  // pred: ^bb80
      %coord_242 = cute.make_coord(%546) : (i32) -> !cute.coord<"(_,?)">
      %idx_243 = cute.crd2idx(%coord_242, %48) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((32)))">) -> !cute.int_tuple<"?{div=32}">
      %ptr_244 = cute.add_offset(%ptr_82, %idx_243) : (!cute.ptr<f16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %idx_245 = cute.crd2idx(%coord_242, %47) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_246 = cute.add_offset(%iter_83, %idx_245) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<8>>
      %swizzled_247 = cute.apply_swizzle(%ptr_244) : !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %ptr_248 = cute.add_offset(%swizzled_247, %idx_227) : (!cute.ptr<f16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %548 = cute_nvgpu.arch.copy.ldsm %ptr_248{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <f16, smem, align<16>, S<3,4,3>> -> vector<4xi32>
      %549 = vector.extractelement %548[%46 : i32] : vector<4xi32>
      %550 = builtin.unrealized_conversion_cast %ptr_246 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
      llvm.store %549, %550 : i32, !llvm.ptr
      %551 = vector.extractelement %548[%64 : i32] : vector<4xi32>
      %ptr_249 = cute.add_offset(%ptr_246, %58) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<f16, rmem, align<4>>
      %552 = builtin.unrealized_conversion_cast %ptr_249 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %551, %552 : i32, !llvm.ptr
      %553 = vector.extractelement %548[%63 : i32] : vector<4xi32>
      %ptr_250 = cute.add_offset(%ptr_246, %56) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<f16, rmem, align<8>>
      %554 = builtin.unrealized_conversion_cast %ptr_250 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
      llvm.store %553, %554 : i32, !llvm.ptr
      %555 = vector.extractelement %548[%45 : i32] : vector<4xi32>
      %ptr_251 = cute.add_offset(%ptr_246, %44) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<f16, rmem, align<4>>
      %556 = builtin.unrealized_conversion_cast %ptr_251 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %555, %556 : i32, !llvm.ptr
      %557 = arith.addi %546, %c1_i32 : i32
      cf.br ^bb80(%557 : i32)
    ^bb82:  // pred: ^bb80
      cf.br ^bb83(%c0_i32 : i32)
    ^bb83(%558: i32):  // 2 preds: ^bb82, ^bb90
      %559 = arith.cmpi slt, %558, %278 : i32
      cf.cond_br %559, ^bb84, ^bb91 {llvm.loop_annotation = #loop_annotation}
    ^bb84:  // pred: ^bb83
      cf.br ^bb85(%c0_i32 : i32)
    ^bb85(%560: i32):  // 2 preds: ^bb84, ^bb89
      %561 = arith.cmpi slt, %560, %276 : i32
      cf.cond_br %561, ^bb86, ^bb90 {llvm.loop_annotation = #loop_annotation}
    ^bb86:  // pred: ^bb85
      %coord_252 = cute.make_coord(%560, %558) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_253 = cute.crd2idx(%coord_252, %42) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">) -> !cute.int_tuple<"?{div=8}">
      %ptr_254 = cute.add_offset(%ptr_89, %idx_253) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
      %562 = builtin.unrealized_conversion_cast %ptr_254 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
      %563 = llvm.getelementptr %562[1] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
      %564 = llvm.getelementptr %562[2] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
      %565 = llvm.getelementptr %562[3] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
      cf.br ^bb87(%c0_i32 : i32)
    ^bb87(%566: i32):  // 2 preds: ^bb86, ^bb88
      %567 = arith.cmpi slt, %566, %279 : i32
      cf.cond_br %567, ^bb88, ^bb89 {llvm.loop_annotation = #loop_annotation}
    ^bb88:  // pred: ^bb87
      %coord_255 = cute.make_coord(%566, %558) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_256 = cute.make_coord(%560, %566) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_257 = cute.crd2idx(%coord_255, %41) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),4,1):((1,2),4,0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_258 = cute.add_offset(%ptr_90, %idx_257) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f16, rmem, align<8>>
      %idx_259 = cute.crd2idx(%coord_256, %50) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,4):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_260 = cute.add_offset(%iter_86, %idx_259) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %568 = llvm.load %562 : !llvm.ptr -> vector<2xf16>
      %569 = llvm.load %563 : !llvm.ptr -> vector<2xf16>
      %570 = llvm.load %564 : !llvm.ptr -> vector<2xf16>
      %571 = llvm.load %565 : !llvm.ptr -> vector<2xf16>
      %572 = builtin.unrealized_conversion_cast %ptr_258 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
      %573 = llvm.load %572 : !llvm.ptr -> vector<2xf16>
      %574 = llvm.getelementptr %572[1] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
      %575 = llvm.load %574 : !llvm.ptr -> vector<2xf16>
      %576 = builtin.unrealized_conversion_cast %ptr_260 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %577 = llvm.load %576 : !llvm.ptr -> f32
      %578 = llvm.getelementptr %576[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %579 = llvm.load %578 : !llvm.ptr -> f32
      %580 = llvm.getelementptr %576[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %581 = llvm.load %580 : !llvm.ptr -> f32
      %582 = llvm.getelementptr %576[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %583 = llvm.load %582 : !llvm.ptr -> f32
      %584:4 = cute_nvgpu.arch.mma.SM80 A[%568, %569, %570, %571]  B[%573, %575]  C[%577, %579, %581, %583] < {a_type = f16, b_type = f16, shape_MNK = #cute.shape<"(16,8,16)">}> : (vector<2xf16>, vector<2xf16>, f32) -> (f32, f32, f32, f32)
      llvm.store %584#0, %576 : f32, !llvm.ptr
      llvm.store %584#1, %578 : f32, !llvm.ptr
      llvm.store %584#2, %580 : f32, !llvm.ptr
      llvm.store %584#3, %582 : f32, !llvm.ptr
      %585 = arith.addi %566, %c1_i32 : i32
      cf.br ^bb87(%585 : i32)
    ^bb89:  // pred: ^bb87
      %586 = arith.addi %560, %c1_i32 : i32
      cf.br ^bb85(%586 : i32)
    ^bb90:  // pred: ^bb85
      %587 = arith.addi %558, %c1_i32 : i32
      cf.br ^bb83(%587 : i32)
    ^bb91:  // pred: ^bb83
      %588 = arith.addi %350, %c1_i32 : i32
      cf.br ^bb22(%588, %530, %531, %523, %525, %527 : i32, !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)>, !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)>, i32, i32, i32)
    ^bb92:  // pred: ^bb22
      %589 = builtin.unrealized_conversion_cast %352 : !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)> to !memref_smem_f16_
      %590 = builtin.unrealized_conversion_cast %351 : !llvm.struct<(ptr<3>, struct<(struct<()>, struct<()>)>)> to !memref_smem_f16_
      %iter_261 = cute.get_iter(%590) : !memref_smem_f16_
      %ptr_262 = cute.add_offset(%iter_261, %62) : (!cute.ptr<f16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"1024">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      cf.br ^bb93(%c0_i32 : i32)
    ^bb93(%591: i32):  // 2 preds: ^bb92, ^bb94
      %592 = arith.cmpi slt, %591, %276 : i32
      cf.cond_br %592, ^bb94, ^bb95 {llvm.loop_annotation = #loop_annotation}
    ^bb94:  // pred: ^bb93
      %coord_263 = cute.make_coord(%591) : (i32) -> !cute.coord<"(_,?)">
      %idx_264 = cute.crd2idx(%coord_263, %48) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((32)))">) -> !cute.int_tuple<"?{div=32}">
      %ptr_265 = cute.add_offset(%ptr_262, %idx_264) : (!cute.ptr<f16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %idx_266 = cute.crd2idx(%coord_263, %47) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_267 = cute.add_offset(%ptr_91, %idx_266) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
      %swizzled_268 = cute.apply_swizzle(%ptr_265) : !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %593 = cute_nvgpu.arch.copy.ldsm %swizzled_268{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <f16, smem, align<16>, S<3,4,3>> -> vector<4xi32>
      %594 = vector.extractelement %593[%46 : i32] : vector<4xi32>
      %595 = builtin.unrealized_conversion_cast %ptr_267 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
      llvm.store %594, %595 : i32, !llvm.ptr
      %596 = vector.extractelement %593[%64 : i32] : vector<4xi32>
      %ptr_269 = cute.add_offset(%ptr_267, %58) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<f16, rmem, align<4>>
      %597 = builtin.unrealized_conversion_cast %ptr_269 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %596, %597 : i32, !llvm.ptr
      %598 = vector.extractelement %593[%63 : i32] : vector<4xi32>
      %ptr_270 = cute.add_offset(%ptr_267, %56) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<f16, rmem, align<8>>
      %599 = builtin.unrealized_conversion_cast %ptr_270 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
      llvm.store %598, %599 : i32, !llvm.ptr
      %600 = vector.extractelement %593[%45 : i32] : vector<4xi32>
      %ptr_271 = cute.add_offset(%ptr_267, %44) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<f16, rmem, align<4>>
      %601 = builtin.unrealized_conversion_cast %ptr_271 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %600, %601 : i32, !llvm.ptr
      %602 = arith.addi %591, %c1_i32 : i32
      cf.br ^bb93(%602 : i32)
    ^bb95:  // pred: ^bb93
      %iter_272 = cute.get_iter(%589) : !memref_smem_f16_
      %ptr_273 = cute.add_offset(%iter_272, %62) : (!cute.ptr<f16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"1024">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      cf.br ^bb96(%c0_i32 : i32)
    ^bb96(%603: i32):  // 2 preds: ^bb95, ^bb97
      %604 = arith.cmpi slt, %603, %276 : i32
      cf.cond_br %604, ^bb97, ^bb98 {llvm.loop_annotation = #loop_annotation}
    ^bb97:  // pred: ^bb96
      %coord_274 = cute.make_coord(%603) : (i32) -> !cute.coord<"(_,?)">
      %idx_275 = cute.crd2idx(%coord_274, %48) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((32)))">) -> !cute.int_tuple<"?{div=32}">
      %ptr_276 = cute.add_offset(%ptr_273, %idx_275) : (!cute.ptr<f16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %idx_277 = cute.crd2idx(%coord_274, %47) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_278 = cute.add_offset(%ptr_92, %idx_277) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<8>>
      %swizzled_279 = cute.apply_swizzle(%ptr_276) : !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %605 = cute_nvgpu.arch.copy.ldsm %swizzled_279{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <f16, smem, align<16>, S<3,4,3>> -> vector<4xi32>
      %606 = vector.extractelement %605[%46 : i32] : vector<4xi32>
      %607 = builtin.unrealized_conversion_cast %ptr_278 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
      llvm.store %606, %607 : i32, !llvm.ptr
      %608 = vector.extractelement %605[%64 : i32] : vector<4xi32>
      %ptr_280 = cute.add_offset(%ptr_278, %58) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<f16, rmem, align<4>>
      %609 = builtin.unrealized_conversion_cast %ptr_280 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %608, %609 : i32, !llvm.ptr
      %610 = vector.extractelement %605[%63 : i32] : vector<4xi32>
      %ptr_281 = cute.add_offset(%ptr_278, %56) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<f16, rmem, align<8>>
      %611 = builtin.unrealized_conversion_cast %ptr_281 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
      llvm.store %610, %611 : i32, !llvm.ptr
      %612 = vector.extractelement %605[%45 : i32] : vector<4xi32>
      %ptr_282 = cute.add_offset(%ptr_278, %44) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<f16, rmem, align<4>>
      %613 = builtin.unrealized_conversion_cast %ptr_282 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %612, %613 : i32, !llvm.ptr
      %614 = arith.addi %603, %c1_i32 : i32
      cf.br ^bb96(%614 : i32)
    ^bb98:  // pred: ^bb96
      cf.br ^bb99(%c0_i32 : i32)
    ^bb99(%615: i32):  // 2 preds: ^bb98, ^bb106
      %616 = arith.cmpi slt, %615, %280 : i32
      cf.cond_br %616, ^bb100, ^bb107 {llvm.loop_annotation = #loop_annotation}
    ^bb100:  // pred: ^bb99
      cf.br ^bb101(%c0_i32 : i32)
    ^bb101(%617: i32):  // 2 preds: ^bb100, ^bb105
      %618 = arith.cmpi slt, %617, %276 : i32
      cf.cond_br %618, ^bb102, ^bb106 {llvm.loop_annotation = #loop_annotation}
    ^bb102:  // pred: ^bb101
      %coord_283 = cute.make_coord(%617, %615) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_284 = cute.crd2idx(%coord_283, %42) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">) -> !cute.int_tuple<"?{div=8}">
      %ptr_285 = cute.add_offset(%iter_79, %idx_284) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
      %619 = builtin.unrealized_conversion_cast %ptr_285 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
      %620 = llvm.getelementptr %619[1] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
      %621 = llvm.getelementptr %619[2] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
      %622 = llvm.getelementptr %619[3] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
      cf.br ^bb103(%c0_i32 : i32)
    ^bb103(%623: i32):  // 2 preds: ^bb102, ^bb104
      %624 = arith.cmpi slt, %623, %281 : i32
      cf.cond_br %624, ^bb104, ^bb105 {llvm.loop_annotation = #loop_annotation}
    ^bb104:  // pred: ^bb103
      %coord_286 = cute.make_coord(%623, %615) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_287 = cute.make_coord(%617, %623) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_288 = cute.crd2idx(%coord_286, %41) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),4,1):((1,2),4,0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_289 = cute.add_offset(%iter_83, %idx_288) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f16, rmem, align<8>>
      %idx_290 = cute.crd2idx(%coord_287, %50) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,4):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_291 = cute.add_offset(%iter_93, %idx_290) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %625 = llvm.load %619 : !llvm.ptr -> vector<2xf16>
      %626 = llvm.load %620 : !llvm.ptr -> vector<2xf16>
      %627 = llvm.load %621 : !llvm.ptr -> vector<2xf16>
      %628 = llvm.load %622 : !llvm.ptr -> vector<2xf16>
      %629 = builtin.unrealized_conversion_cast %ptr_289 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
      %630 = llvm.load %629 : !llvm.ptr -> vector<2xf16>
      %631 = llvm.getelementptr %629[1] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
      %632 = llvm.load %631 : !llvm.ptr -> vector<2xf16>
      %633 = builtin.unrealized_conversion_cast %ptr_291 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %634 = llvm.load %633 : !llvm.ptr -> f32
      %635 = llvm.getelementptr %633[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %636 = llvm.load %635 : !llvm.ptr -> f32
      %637 = llvm.getelementptr %633[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %638 = llvm.load %637 : !llvm.ptr -> f32
      %639 = llvm.getelementptr %633[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %640 = llvm.load %639 : !llvm.ptr -> f32
      %641:4 = cute_nvgpu.arch.mma.SM80 A[%625, %626, %627, %628]  B[%630, %632]  C[%634, %636, %638, %640] < {a_type = f16, b_type = f16, shape_MNK = #cute.shape<"(16,8,16)">}> : (vector<2xf16>, vector<2xf16>, f32) -> (f32, f32, f32, f32)
      llvm.store %641#0, %633 : f32, !llvm.ptr
      llvm.store %641#1, %635 : f32, !llvm.ptr
      llvm.store %641#2, %637 : f32, !llvm.ptr
      llvm.store %641#3, %639 : f32, !llvm.ptr
      %642 = arith.addi %623, %c1_i32 : i32
      cf.br ^bb103(%642 : i32)
    ^bb105:  // pred: ^bb103
      %643 = arith.addi %617, %c1_i32 : i32
      cf.br ^bb101(%643 : i32)
    ^bb106:  // pred: ^bb101
      %644 = arith.addi %615, %c1_i32 : i32
      cf.br ^bb99(%644 : i32)
    ^bb107:  // pred: ^bb99
      %ptr_292 = cute.add_offset(%iter_261, %40) : (!cute.ptr<f16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"2048">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      cf.br ^bb108(%c0_i32 : i32)
    ^bb108(%645: i32):  // 2 preds: ^bb107, ^bb109
      %646 = arith.cmpi slt, %645, %276 : i32
      cf.cond_br %646, ^bb109, ^bb110 {llvm.loop_annotation = #loop_annotation}
    ^bb109:  // pred: ^bb108
      %coord_293 = cute.make_coord(%645) : (i32) -> !cute.coord<"(_,?)">
      %idx_294 = cute.crd2idx(%coord_293, %48) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((32)))">) -> !cute.int_tuple<"?{div=32}">
      %ptr_295 = cute.add_offset(%ptr_292, %idx_294) : (!cute.ptr<f16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %idx_296 = cute.crd2idx(%coord_293, %47) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_297 = cute.add_offset(%ptr_94, %idx_296) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
      %swizzled_298 = cute.apply_swizzle(%ptr_295) : !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %647 = cute_nvgpu.arch.copy.ldsm %swizzled_298{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <f16, smem, align<16>, S<3,4,3>> -> vector<4xi32>
      %648 = vector.extractelement %647[%46 : i32] : vector<4xi32>
      %649 = builtin.unrealized_conversion_cast %ptr_297 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
      llvm.store %648, %649 : i32, !llvm.ptr
      %650 = vector.extractelement %647[%64 : i32] : vector<4xi32>
      %ptr_299 = cute.add_offset(%ptr_297, %58) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<f16, rmem, align<4>>
      %651 = builtin.unrealized_conversion_cast %ptr_299 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %650, %651 : i32, !llvm.ptr
      %652 = vector.extractelement %647[%63 : i32] : vector<4xi32>
      %ptr_300 = cute.add_offset(%ptr_297, %56) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<f16, rmem, align<8>>
      %653 = builtin.unrealized_conversion_cast %ptr_300 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
      llvm.store %652, %653 : i32, !llvm.ptr
      %654 = vector.extractelement %647[%45 : i32] : vector<4xi32>
      %ptr_301 = cute.add_offset(%ptr_297, %44) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<f16, rmem, align<4>>
      %655 = builtin.unrealized_conversion_cast %ptr_301 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %654, %655 : i32, !llvm.ptr
      %656 = arith.addi %645, %c1_i32 : i32
      cf.br ^bb108(%656 : i32)
    ^bb110:  // pred: ^bb108
      %ptr_302 = cute.add_offset(%iter_272, %40) : (!cute.ptr<f16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"2048">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      cf.br ^bb111(%c0_i32 : i32)
    ^bb111(%657: i32):  // 2 preds: ^bb110, ^bb112
      %658 = arith.cmpi slt, %657, %276 : i32
      cf.cond_br %658, ^bb112, ^bb113 {llvm.loop_annotation = #loop_annotation}
    ^bb112:  // pred: ^bb111
      %coord_303 = cute.make_coord(%657) : (i32) -> !cute.coord<"(_,?)">
      %idx_304 = cute.crd2idx(%coord_303, %48) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((32)))">) -> !cute.int_tuple<"?{div=32}">
      %ptr_305 = cute.add_offset(%ptr_302, %idx_304) : (!cute.ptr<f16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %idx_306 = cute.crd2idx(%coord_303, %47) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_307 = cute.add_offset(%ptr_95, %idx_306) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<8>>
      %swizzled_308 = cute.apply_swizzle(%ptr_305) : !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %659 = cute_nvgpu.arch.copy.ldsm %swizzled_308{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <f16, smem, align<16>, S<3,4,3>> -> vector<4xi32>
      %660 = vector.extractelement %659[%46 : i32] : vector<4xi32>
      %661 = builtin.unrealized_conversion_cast %ptr_307 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
      llvm.store %660, %661 : i32, !llvm.ptr
      %662 = vector.extractelement %659[%64 : i32] : vector<4xi32>
      %ptr_309 = cute.add_offset(%ptr_307, %58) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<f16, rmem, align<4>>
      %663 = builtin.unrealized_conversion_cast %ptr_309 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %662, %663 : i32, !llvm.ptr
      %664 = vector.extractelement %659[%63 : i32] : vector<4xi32>
      %ptr_310 = cute.add_offset(%ptr_307, %56) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<f16, rmem, align<8>>
      %665 = builtin.unrealized_conversion_cast %ptr_310 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
      llvm.store %664, %665 : i32, !llvm.ptr
      %666 = vector.extractelement %659[%45 : i32] : vector<4xi32>
      %ptr_311 = cute.add_offset(%ptr_307, %44) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<f16, rmem, align<4>>
      %667 = builtin.unrealized_conversion_cast %ptr_311 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %666, %667 : i32, !llvm.ptr
      %668 = arith.addi %657, %c1_i32 : i32
      cf.br ^bb111(%668 : i32)
    ^bb113:  // pred: ^bb111
      cf.br ^bb114(%c0_i32 : i32)
    ^bb114(%669: i32):  // 2 preds: ^bb113, ^bb121
      %670 = arith.cmpi slt, %669, %280 : i32
      cf.cond_br %670, ^bb115, ^bb122 {llvm.loop_annotation = #loop_annotation}
    ^bb115:  // pred: ^bb114
      cf.br ^bb116(%c0_i32 : i32)
    ^bb116(%671: i32):  // 2 preds: ^bb115, ^bb120
      %672 = arith.cmpi slt, %671, %276 : i32
      cf.cond_br %672, ^bb117, ^bb121 {llvm.loop_annotation = #loop_annotation}
    ^bb117:  // pred: ^bb116
      %coord_312 = cute.make_coord(%671, %669) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_313 = cute.crd2idx(%coord_312, %42) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">) -> !cute.int_tuple<"?{div=8}">
      %ptr_314 = cute.add_offset(%ptr_91, %idx_313) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
      %673 = builtin.unrealized_conversion_cast %ptr_314 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
      %674 = llvm.getelementptr %673[1] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
      %675 = llvm.getelementptr %673[2] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
      %676 = llvm.getelementptr %673[3] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
      cf.br ^bb118(%c0_i32 : i32)
    ^bb118(%677: i32):  // 2 preds: ^bb117, ^bb119
      %678 = arith.cmpi slt, %677, %281 : i32
      cf.cond_br %678, ^bb119, ^bb120 {llvm.loop_annotation = #loop_annotation}
    ^bb119:  // pred: ^bb118
      %coord_315 = cute.make_coord(%677, %669) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_316 = cute.make_coord(%671, %677) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_317 = cute.crd2idx(%coord_315, %41) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),4,1):((1,2),4,0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_318 = cute.add_offset(%ptr_92, %idx_317) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f16, rmem, align<8>>
      %idx_319 = cute.crd2idx(%coord_316, %50) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,4):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_320 = cute.add_offset(%iter_93, %idx_319) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %679 = llvm.load %673 : !llvm.ptr -> vector<2xf16>
      %680 = llvm.load %674 : !llvm.ptr -> vector<2xf16>
      %681 = llvm.load %675 : !llvm.ptr -> vector<2xf16>
      %682 = llvm.load %676 : !llvm.ptr -> vector<2xf16>
      %683 = builtin.unrealized_conversion_cast %ptr_318 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
      %684 = llvm.load %683 : !llvm.ptr -> vector<2xf16>
      %685 = llvm.getelementptr %683[1] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
      %686 = llvm.load %685 : !llvm.ptr -> vector<2xf16>
      %687 = builtin.unrealized_conversion_cast %ptr_320 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %688 = llvm.load %687 : !llvm.ptr -> f32
      %689 = llvm.getelementptr %687[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %690 = llvm.load %689 : !llvm.ptr -> f32
      %691 = llvm.getelementptr %687[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %692 = llvm.load %691 : !llvm.ptr -> f32
      %693 = llvm.getelementptr %687[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %694 = llvm.load %693 : !llvm.ptr -> f32
      %695:4 = cute_nvgpu.arch.mma.SM80 A[%679, %680, %681, %682]  B[%684, %686]  C[%688, %690, %692, %694] < {a_type = f16, b_type = f16, shape_MNK = #cute.shape<"(16,8,16)">}> : (vector<2xf16>, vector<2xf16>, f32) -> (f32, f32, f32, f32)
      llvm.store %695#0, %687 : f32, !llvm.ptr
      llvm.store %695#1, %689 : f32, !llvm.ptr
      llvm.store %695#2, %691 : f32, !llvm.ptr
      llvm.store %695#3, %693 : f32, !llvm.ptr
      %696 = arith.addi %677, %c1_i32 : i32
      cf.br ^bb118(%696 : i32)
    ^bb120:  // pred: ^bb118
      %697 = arith.addi %671, %c1_i32 : i32
      cf.br ^bb116(%697 : i32)
    ^bb121:  // pred: ^bb116
      %698 = arith.addi %669, %c1_i32 : i32
      cf.br ^bb114(%698 : i32)
    ^bb122:  // pred: ^bb114
      %ptr_321 = cute.add_offset(%iter_261, %38) : (!cute.ptr<f16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"3072">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      cf.br ^bb123(%c0_i32 : i32)
    ^bb123(%699: i32):  // 2 preds: ^bb122, ^bb124
      %700 = arith.cmpi slt, %699, %276 : i32
      cf.cond_br %700, ^bb124, ^bb125 {llvm.loop_annotation = #loop_annotation}
    ^bb124:  // pred: ^bb123
      %coord_322 = cute.make_coord(%699) : (i32) -> !cute.coord<"(_,?)">
      %idx_323 = cute.crd2idx(%coord_322, %48) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((32)))">) -> !cute.int_tuple<"?{div=32}">
      %ptr_324 = cute.add_offset(%ptr_321, %idx_323) : (!cute.ptr<f16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %idx_325 = cute.crd2idx(%coord_322, %47) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_326 = cute.add_offset(%ptr_96, %idx_325) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
      %swizzled_327 = cute.apply_swizzle(%ptr_324) : !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %701 = cute_nvgpu.arch.copy.ldsm %swizzled_327{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <f16, smem, align<16>, S<3,4,3>> -> vector<4xi32>
      %702 = vector.extractelement %701[%46 : i32] : vector<4xi32>
      %703 = builtin.unrealized_conversion_cast %ptr_326 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
      llvm.store %702, %703 : i32, !llvm.ptr
      %704 = vector.extractelement %701[%64 : i32] : vector<4xi32>
      %ptr_328 = cute.add_offset(%ptr_326, %58) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"2">) -> !cute.ptr<f16, rmem, align<4>>
      %705 = builtin.unrealized_conversion_cast %ptr_328 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %704, %705 : i32, !llvm.ptr
      %706 = vector.extractelement %701[%63 : i32] : vector<4xi32>
      %ptr_329 = cute.add_offset(%ptr_326, %56) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"4">) -> !cute.ptr<f16, rmem, align<8>>
      %707 = builtin.unrealized_conversion_cast %ptr_329 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
      llvm.store %706, %707 : i32, !llvm.ptr
      %708 = vector.extractelement %701[%45 : i32] : vector<4xi32>
      %ptr_330 = cute.add_offset(%ptr_326, %44) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"6">) -> !cute.ptr<f16, rmem, align<4>>
      %709 = builtin.unrealized_conversion_cast %ptr_330 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %708, %709 : i32, !llvm.ptr
      %710 = arith.addi %699, %c1_i32 : i32
      cf.br ^bb123(%710 : i32)
    ^bb125:  // pred: ^bb123
      %ptr_331 = cute.add_offset(%iter_272, %38) : (!cute.ptr<f16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"3072">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      cf.br ^bb126(%c0_i32 : i32)
    ^bb126(%711: i32):  // 2 preds: ^bb125, ^bb127
      %712 = arith.cmpi slt, %711, %276 : i32
      cf.cond_br %712, ^bb127, ^bb128 {llvm.loop_annotation = #loop_annotation}
    ^bb127:  // pred: ^bb126
      %coord_332 = cute.make_coord(%711) : (i32) -> !cute.coord<"(_,?)">
      %idx_333 = cute.crd2idx(%coord_332, %48) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((32)))">) -> !cute.int_tuple<"?{div=32}">
      %ptr_334 = cute.add_offset(%ptr_331, %idx_333) : (!cute.ptr<f16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %idx_335 = cute.crd2idx(%coord_332, %47) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2))):((1,0),((8)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_336 = cute.add_offset(%ptr_97, %idx_335) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<8>>
      %swizzled_337 = cute.apply_swizzle(%ptr_334) : !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %713 = cute_nvgpu.arch.copy.ldsm %swizzled_337{matrix_shape = <"(8,8)">, sz_pattern = <u16>, num_matrices = 4 : i32, transpose} : <f16, smem, align<16>, S<3,4,3>> -> vector<4xi32>
      %714 = vector.extractelement %713[%46 : i32] : vector<4xi32>
      %715 = builtin.unrealized_conversion_cast %ptr_336 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
      llvm.store %714, %715 : i32, !llvm.ptr
      %716 = vector.extractelement %713[%64 : i32] : vector<4xi32>
      %ptr_338 = cute.add_offset(%ptr_336, %58) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"2">) -> !cute.ptr<f16, rmem, align<4>>
      %717 = builtin.unrealized_conversion_cast %ptr_338 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %716, %717 : i32, !llvm.ptr
      %718 = vector.extractelement %713[%63 : i32] : vector<4xi32>
      %ptr_339 = cute.add_offset(%ptr_336, %56) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"4">) -> !cute.ptr<f16, rmem, align<8>>
      %719 = builtin.unrealized_conversion_cast %ptr_339 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
      llvm.store %718, %719 : i32, !llvm.ptr
      %720 = vector.extractelement %713[%45 : i32] : vector<4xi32>
      %ptr_340 = cute.add_offset(%ptr_336, %44) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"6">) -> !cute.ptr<f16, rmem, align<4>>
      %721 = builtin.unrealized_conversion_cast %ptr_340 : !cute.ptr<f16, rmem, align<4>> to !llvm.ptr
      llvm.store %720, %721 : i32, !llvm.ptr
      %722 = arith.addi %711, %c1_i32 : i32
      cf.br ^bb126(%722 : i32)
    ^bb128:  // pred: ^bb126
      cf.br ^bb129(%c0_i32 : i32)
    ^bb129(%723: i32):  // 2 preds: ^bb128, ^bb136
      %724 = arith.cmpi slt, %723, %280 : i32
      cf.cond_br %724, ^bb130, ^bb137 {llvm.loop_annotation = #loop_annotation}
    ^bb130:  // pred: ^bb129
      cf.br ^bb131(%c0_i32 : i32)
    ^bb131(%725: i32):  // 2 preds: ^bb130, ^bb135
      %726 = arith.cmpi slt, %725, %276 : i32
      cf.cond_br %726, ^bb132, ^bb136 {llvm.loop_annotation = #loop_annotation}
    ^bb132:  // pred: ^bb131
      %coord_341 = cute.make_coord(%725, %723) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_342 = cute.crd2idx(%coord_341, %42) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">) -> !cute.int_tuple<"?{div=8}">
      %ptr_343 = cute.add_offset(%ptr_94, %idx_342) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
      %727 = builtin.unrealized_conversion_cast %ptr_343 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
      %728 = llvm.getelementptr %727[1] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
      %729 = llvm.getelementptr %727[2] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
      %730 = llvm.getelementptr %727[3] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
      cf.br ^bb133(%c0_i32 : i32)
    ^bb133(%731: i32):  // 2 preds: ^bb132, ^bb134
      %732 = arith.cmpi slt, %731, %281 : i32
      cf.cond_br %732, ^bb134, ^bb135 {llvm.loop_annotation = #loop_annotation}
    ^bb134:  // pred: ^bb133
      %coord_344 = cute.make_coord(%731, %723) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_345 = cute.make_coord(%725, %731) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_346 = cute.crd2idx(%coord_344, %41) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),4,1):((1,2),4,0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_347 = cute.add_offset(%ptr_95, %idx_346) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f16, rmem, align<8>>
      %idx_348 = cute.crd2idx(%coord_345, %50) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,4):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_349 = cute.add_offset(%iter_93, %idx_348) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %733 = llvm.load %727 : !llvm.ptr -> vector<2xf16>
      %734 = llvm.load %728 : !llvm.ptr -> vector<2xf16>
      %735 = llvm.load %729 : !llvm.ptr -> vector<2xf16>
      %736 = llvm.load %730 : !llvm.ptr -> vector<2xf16>
      %737 = builtin.unrealized_conversion_cast %ptr_347 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
      %738 = llvm.load %737 : !llvm.ptr -> vector<2xf16>
      %739 = llvm.getelementptr %737[1] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
      %740 = llvm.load %739 : !llvm.ptr -> vector<2xf16>
      %741 = builtin.unrealized_conversion_cast %ptr_349 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %742 = llvm.load %741 : !llvm.ptr -> f32
      %743 = llvm.getelementptr %741[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %744 = llvm.load %743 : !llvm.ptr -> f32
      %745 = llvm.getelementptr %741[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %746 = llvm.load %745 : !llvm.ptr -> f32
      %747 = llvm.getelementptr %741[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %748 = llvm.load %747 : !llvm.ptr -> f32
      %749:4 = cute_nvgpu.arch.mma.SM80 A[%733, %734, %735, %736]  B[%738, %740]  C[%742, %744, %746, %748] < {a_type = f16, b_type = f16, shape_MNK = #cute.shape<"(16,8,16)">}> : (vector<2xf16>, vector<2xf16>, f32) -> (f32, f32, f32, f32)
      llvm.store %749#0, %741 : f32, !llvm.ptr
      llvm.store %749#1, %743 : f32, !llvm.ptr
      llvm.store %749#2, %745 : f32, !llvm.ptr
      llvm.store %749#3, %747 : f32, !llvm.ptr
      %750 = arith.addi %731, %c1_i32 : i32
      cf.br ^bb133(%750 : i32)
    ^bb135:  // pred: ^bb133
      %751 = arith.addi %725, %c1_i32 : i32
      cf.br ^bb131(%751 : i32)
    ^bb136:  // pred: ^bb131
      %752 = arith.addi %723, %c1_i32 : i32
      cf.br ^bb129(%752 : i32)
    ^bb137:  // pred: ^bb129
      cf.cond_br %99, ^bb138, ^bb139
    ^bb138:  // pred: ^bb137
      %int_tuple_350 = cute.make_int_tuple(%354) : (i32) -> !cute.int_tuple<"?">
      %ptr_351 = cute.add_offset(%ptr_7, %int_tuple_350) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %753 = builtin.unrealized_conversion_cast %ptr_351 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %753, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>} : !llvm.ptr<3>, i32
      cf.br ^bb139
    ^bb139:  // 2 preds: ^bb137, ^bb138
      %754 = arith.addi %354, %c1_i32 : i32
      %755 = arith.cmpi eq, %754, %c4_i32 : i32
      %756 = arith.select %755, %c0_i32, %754 : i32
      cf.cond_br %755, ^bb140, ^bb141
    ^bb140:  // pred: ^bb139
      %757 = arith.xori %355, %c1_i32 : i32
      cf.br ^bb142(%757 : i32)
    ^bb141:  // pred: ^bb139
      cf.br ^bb142(%355 : i32)
    ^bb142(%758: i32):  // 2 preds: ^bb140, ^bb141
      cf.br ^bb143
    ^bb143:  // pred: ^bb142
      cf.br ^bb144(%c0_i32 : i32)
    ^bb144(%759: i32):  // 2 preds: ^bb143, ^bb151
      %760 = arith.cmpi slt, %759, %280 : i32
      cf.cond_br %760, ^bb145, ^bb152 {llvm.loop_annotation = #loop_annotation}
    ^bb145:  // pred: ^bb144
      cf.br ^bb146(%c0_i32 : i32)
    ^bb146(%761: i32):  // 2 preds: ^bb145, ^bb150
      %762 = arith.cmpi slt, %761, %276 : i32
      cf.cond_br %762, ^bb147, ^bb151 {llvm.loop_annotation = #loop_annotation}
    ^bb147:  // pred: ^bb146
      %coord_352 = cute.make_coord(%761, %759) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_353 = cute.crd2idx(%coord_352, %42) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2,2),2,1):((1,2,4),8,0)">) -> !cute.int_tuple<"?{div=8}">
      %ptr_354 = cute.add_offset(%ptr_96, %idx_353) : (!cute.ptr<f16, rmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
      %763 = builtin.unrealized_conversion_cast %ptr_354 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
      %764 = llvm.getelementptr %763[1] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
      %765 = llvm.getelementptr %763[2] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
      %766 = llvm.getelementptr %763[3] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
      cf.br ^bb148(%c0_i32 : i32)
    ^bb148(%767: i32):  // 2 preds: ^bb147, ^bb149
      %768 = arith.cmpi slt, %767, %281 : i32
      cf.cond_br %768, ^bb149, ^bb150 {llvm.loop_annotation = #loop_annotation}
    ^bb149:  // pred: ^bb148
      %coord_355 = cute.make_coord(%767, %759) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %coord_356 = cute.make_coord(%761, %767) : (i32, i32) -> !cute.coord<"(_,?,?)">
      %idx_357 = cute.crd2idx(%coord_355, %41) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),4,1):((1,2),4,0)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_358 = cute.add_offset(%ptr_97, %idx_357) : (!cute.ptr<f16, rmem, align<8>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f16, rmem, align<8>>
      %idx_359 = cute.crd2idx(%coord_356, %50) : (!cute.coord<"(_,?,?)">, !cute.layout<"((2,2),2,4):((1,2),4,8)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_360 = cute.add_offset(%iter_93, %idx_359) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, rmem, align<16>>
      %769 = llvm.load %763 : !llvm.ptr -> vector<2xf16>
      %770 = llvm.load %764 : !llvm.ptr -> vector<2xf16>
      %771 = llvm.load %765 : !llvm.ptr -> vector<2xf16>
      %772 = llvm.load %766 : !llvm.ptr -> vector<2xf16>
      %773 = builtin.unrealized_conversion_cast %ptr_358 : !cute.ptr<f16, rmem, align<8>> to !llvm.ptr
      %774 = llvm.load %773 : !llvm.ptr -> vector<2xf16>
      %775 = llvm.getelementptr %773[1] : (!llvm.ptr) -> !llvm.ptr, vector<2xf16>
      %776 = llvm.load %775 : !llvm.ptr -> vector<2xf16>
      %777 = builtin.unrealized_conversion_cast %ptr_360 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %778 = llvm.load %777 : !llvm.ptr -> f32
      %779 = llvm.getelementptr %777[1] : (!llvm.ptr) -> !llvm.ptr, f32
      %780 = llvm.load %779 : !llvm.ptr -> f32
      %781 = llvm.getelementptr %777[2] : (!llvm.ptr) -> !llvm.ptr, f32
      %782 = llvm.load %781 : !llvm.ptr -> f32
      %783 = llvm.getelementptr %777[3] : (!llvm.ptr) -> !llvm.ptr, f32
      %784 = llvm.load %783 : !llvm.ptr -> f32
      %785:4 = cute_nvgpu.arch.mma.SM80 A[%769, %770, %771, %772]  B[%774, %776]  C[%778, %780, %782, %784] < {a_type = f16, b_type = f16, shape_MNK = #cute.shape<"(16,8,16)">}> : (vector<2xf16>, vector<2xf16>, f32) -> (f32, f32, f32, f32)
      llvm.store %785#0, %777 : f32, !llvm.ptr
      llvm.store %785#1, %779 : f32, !llvm.ptr
      llvm.store %785#2, %781 : f32, !llvm.ptr
      llvm.store %785#3, %783 : f32, !llvm.ptr
      %786 = arith.addi %767, %c1_i32 : i32
      cf.br ^bb148(%786 : i32)
    ^bb150:  // pred: ^bb148
      %787 = arith.addi %761, %c1_i32 : i32
      cf.br ^bb146(%787 : i32)
    ^bb151:  // pred: ^bb146
      %788 = arith.addi %759, %c1_i32 : i32
      cf.br ^bb144(%788 : i32)
    ^bb152:  // pred: ^bb144
      %789 = cute.make_tiled_copy(%atom_98) : !copy_stsm_4_
      %790 = cute.make_tiled_copy(%atom_98) : !copy_stsm_4_1
      %rmem_361 = cute.memref.alloca() : !memref_rmem_f32_2
      %791 = cute.memref.load(%view, %36) : (!memref_rmem_f32_1, !cute.coord<"0">) -> f32
      cute.memref.store(%rmem_361, %36, %791) : (!memref_rmem_f32_2, !cute.coord<"0">, f32) -> ()
      %792 = cute.memref.load(%view, %35) : (!memref_rmem_f32_1, !cute.coord<"1">) -> f32
      cute.memref.store(%rmem_361, %35, %792) : (!memref_rmem_f32_2, !cute.coord<"1">, f32) -> ()
      %793 = cute.memref.load(%view, %34) : (!memref_rmem_f32_1, !cute.coord<"2">) -> f32
      cute.memref.store(%rmem_361, %34, %793) : (!memref_rmem_f32_2, !cute.coord<"2">, f32) -> ()
      %794 = cute.memref.load(%view, %33) : (!memref_rmem_f32_1, !cute.coord<"3">) -> f32
      cute.memref.store(%rmem_361, %33, %794) : (!memref_rmem_f32_2, !cute.coord<"3">, f32) -> ()
      %795 = cute.memref.load(%view, %32) : (!memref_rmem_f32_1, !cute.coord<"4">) -> f32
      cute.memref.store(%rmem_361, %32, %795) : (!memref_rmem_f32_2, !cute.coord<"4">, f32) -> ()
      %796 = cute.memref.load(%view, %31) : (!memref_rmem_f32_1, !cute.coord<"5">) -> f32
      cute.memref.store(%rmem_361, %31, %796) : (!memref_rmem_f32_2, !cute.coord<"5">, f32) -> ()
      %797 = cute.memref.load(%view, %30) : (!memref_rmem_f32_1, !cute.coord<"6">) -> f32
      cute.memref.store(%rmem_361, %30, %797) : (!memref_rmem_f32_2, !cute.coord<"6">, f32) -> ()
      %798 = cute.memref.load(%view, %29) : (!memref_rmem_f32_1, !cute.coord<"7">) -> f32
      cute.memref.store(%rmem_361, %29, %798) : (!memref_rmem_f32_2, !cute.coord<"7">, f32) -> ()
      %799 = cute.memref.load(%view, %28) : (!memref_rmem_f32_1, !cute.coord<"8">) -> f32
      cute.memref.store(%rmem_361, %28, %799) : (!memref_rmem_f32_2, !cute.coord<"8">, f32) -> ()
      %800 = cute.memref.load(%view, %27) : (!memref_rmem_f32_1, !cute.coord<"9">) -> f32
      cute.memref.store(%rmem_361, %27, %800) : (!memref_rmem_f32_2, !cute.coord<"9">, f32) -> ()
      %801 = cute.memref.load(%view, %26) : (!memref_rmem_f32_1, !cute.coord<"10">) -> f32
      cute.memref.store(%rmem_361, %26, %801) : (!memref_rmem_f32_2, !cute.coord<"10">, f32) -> ()
      %802 = cute.memref.load(%view, %25) : (!memref_rmem_f32_1, !cute.coord<"11">) -> f32
      cute.memref.store(%rmem_361, %25, %802) : (!memref_rmem_f32_2, !cute.coord<"11">, f32) -> ()
      %803 = cute.memref.load(%view, %24) : (!memref_rmem_f32_1, !cute.coord<"12">) -> f32
      cute.memref.store(%rmem_361, %24, %803) : (!memref_rmem_f32_2, !cute.coord<"12">, f32) -> ()
      %804 = cute.memref.load(%view, %23) : (!memref_rmem_f32_1, !cute.coord<"13">) -> f32
      cute.memref.store(%rmem_361, %23, %804) : (!memref_rmem_f32_2, !cute.coord<"13">, f32) -> ()
      %805 = cute.memref.load(%view, %22) : (!memref_rmem_f32_1, !cute.coord<"14">) -> f32
      cute.memref.store(%rmem_361, %22, %805) : (!memref_rmem_f32_2, !cute.coord<"14">, f32) -> ()
      %806 = cute.memref.load(%view, %21) : (!memref_rmem_f32_1, !cute.coord<"15">) -> f32
      cute.memref.store(%rmem_361, %21, %806) : (!memref_rmem_f32_2, !cute.coord<"15">, f32) -> ()
      %rmem_362 = cute.memref.alloca() : !memref_rmem_f16_2
      %iter_363 = cute.get_iter(%rmem_362) : !memref_rmem_f16_2
      %807 = cute.memref.load_vec %rmem_361 : !memref_rmem_f32_2
      %808 = arith.truncf %807 : vector<16xf32> to vector<16xf16>
      cute.memref.store_vec %808, %rmem_362 : !memref_rmem_f16_2
      cf.br ^bb153(%c0_i32 : i32)
    ^bb153(%809: i32):  // 2 preds: ^bb152, ^bb154
      %810 = arith.cmpi slt, %809, %276 : i32
      cf.cond_br %810, ^bb154, ^bb155 {llvm.loop_annotation = #loop_annotation}
    ^bb154:  // pred: ^bb153
      %coord_364 = cute.make_coord(%809) : (i32) -> !cute.coord<"(_,?)">
      %idx_365 = cute.crd2idx(%coord_364, %20) : (!cute.coord<"(_,?)">, !cute.layout<"(((2,2,2),1),((2,1))):(((1,2,4),0),((8,0)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_366 = cute.add_offset(%iter_363, %idx_365) : (!cute.ptr<f16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
      %idx_367 = cute.crd2idx(%coord_364, %19) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2,1))):((1,0),((32,0)))">) -> !cute.int_tuple<"?{div=32}">
      %ptr_368 = cute.add_offset(%ptr_101, %idx_367) : (!cute.ptr<f16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %811 = builtin.unrealized_conversion_cast %ptr_366 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
      %812 = llvm.load %811 : !llvm.ptr -> vector<4xi32>
      %swizzled_369 = cute.apply_swizzle(%ptr_368) : !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      cute_nvgpu.arch.copy.stsm(%swizzled_369, %812) {matrix_shape = <"(8,8)">, num_matrices = 4 : i32, transpose} : <f16, smem, align<16>, S<3,4,3>>, vector<4xi32>
      %813 = arith.addi %809, %c1_i32 : i32
      cf.br ^bb153(%813 : i32)
    ^bb155:  // pred: ^bb153
      nvvm.fence.proxy {kind = #nvvm.proxy_kind<async.shared>, space = #nvvm.shared_space<cta>}
      nvvm.barrier id = %c2_i32 number_of_threads = %c128_i32
      cf.cond_br %86, ^bb156, ^bb160
    ^bb156:  // pred: ^bb155
      %e0_370, %e1_371, %e2_372 = cute.get_leaves(%tup) : !cute.int_tuple<"(?{div=64},?{div=64},?)">
      %int_tuple_373 = cute.make_int_tuple(%e0_370, %e1_371, %e2_372) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=64},?{div=64},?)">
      %814 = cute_nvgpu.atom.make_exec_tma(%arg4) : (!cute_nvgpu.atom.non_exec_tiled_tma_store<f16, copy_bits = 32768, tma_gbasis = <"(64,32,1):(1@0,1@1,1@2)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_store<f16, copy_bits = 32768, mode = tiled, g_stride = <"()"> tma_gbasis = <"(64,32,1):(1@0,1@1,1@2)">>
      %TMADescAddr = cute_nvgpu.get_tma_desc_addr(%814 : !cute_nvgpu.atom.tma_store<f16, copy_bits = 32768, mode = tiled, g_stride = <"()"> tma_gbasis = <"(64,32,1):(1@0,1@1,1@2)">>) -> !cute.ptr<generic, align<64>>
      %815 = cute_nvgpu.atom.get_value(%814 : !cute_nvgpu.atom.tma_store<f16, copy_bits = 32768, mode = tiled, g_stride = <"()"> tma_gbasis = <"(64,32,1):(1@0,1@1,1@2)">>) {field = #cute_nvgpu.atom_copy_field_tmastore<cache_policy>} : i64
      %816:3 = cute.get_scalars(%int_tuple_373) : !cute.int_tuple<"(?{div=64},?{div=64},?)">
      cf.br ^bb157(%c0_i32 : i32)
    ^bb157(%817: i32):  // 2 preds: ^bb156, ^bb158
      %818 = arith.cmpi slt, %817, %280 : i32
      cf.cond_br %818, ^bb158, ^bb159 {llvm.loop_annotation = #loop_annotation}
    ^bb158:  // pred: ^bb157
      cute_nvgpu.arch.copy.SM100.tma_store(%TMADescAddr : !cute.ptr<generic, align<64>>, %iter_16 : !cute.ptr<f16, smem, align<1024>, S<3,4,3>>, [%816#0, %816#1, %816#2] : i32, i32, i32) cache_policy = %815 mode = <tiled>
      %819 = arith.addi %817, %c1_i32 : i32
      cf.br ^bb157(%819 : i32)
    ^bb159:  // pred: ^bb157
      nvvm.cp.async.bulk.commit.group
      nvvm.cp.async.bulk.wait_group 7 {read}
      cf.br ^bb160
    ^bb160:  // 2 preds: ^bb155, ^bb159
      %820 = cute.memref.load(%view, %18) : (!memref_rmem_f32_1, !cute.coord<"16">) -> f32
      cute.memref.store(%rmem_361, %36, %820) : (!memref_rmem_f32_2, !cute.coord<"0">, f32) -> ()
      %821 = cute.memref.load(%view, %17) : (!memref_rmem_f32_1, !cute.coord<"17">) -> f32
      cute.memref.store(%rmem_361, %35, %821) : (!memref_rmem_f32_2, !cute.coord<"1">, f32) -> ()
      %822 = cute.memref.load(%view, %16) : (!memref_rmem_f32_1, !cute.coord<"18">) -> f32
      cute.memref.store(%rmem_361, %34, %822) : (!memref_rmem_f32_2, !cute.coord<"2">, f32) -> ()
      %823 = cute.memref.load(%view, %15) : (!memref_rmem_f32_1, !cute.coord<"19">) -> f32
      cute.memref.store(%rmem_361, %33, %823) : (!memref_rmem_f32_2, !cute.coord<"3">, f32) -> ()
      %824 = cute.memref.load(%view, %14) : (!memref_rmem_f32_1, !cute.coord<"20">) -> f32
      cute.memref.store(%rmem_361, %32, %824) : (!memref_rmem_f32_2, !cute.coord<"4">, f32) -> ()
      %825 = cute.memref.load(%view, %13) : (!memref_rmem_f32_1, !cute.coord<"21">) -> f32
      cute.memref.store(%rmem_361, %31, %825) : (!memref_rmem_f32_2, !cute.coord<"5">, f32) -> ()
      %826 = cute.memref.load(%view, %12) : (!memref_rmem_f32_1, !cute.coord<"22">) -> f32
      cute.memref.store(%rmem_361, %30, %826) : (!memref_rmem_f32_2, !cute.coord<"6">, f32) -> ()
      %827 = cute.memref.load(%view, %11) : (!memref_rmem_f32_1, !cute.coord<"23">) -> f32
      cute.memref.store(%rmem_361, %29, %827) : (!memref_rmem_f32_2, !cute.coord<"7">, f32) -> ()
      %828 = cute.memref.load(%view, %10) : (!memref_rmem_f32_1, !cute.coord<"24">) -> f32
      cute.memref.store(%rmem_361, %28, %828) : (!memref_rmem_f32_2, !cute.coord<"8">, f32) -> ()
      %829 = cute.memref.load(%view, %9) : (!memref_rmem_f32_1, !cute.coord<"25">) -> f32
      cute.memref.store(%rmem_361, %27, %829) : (!memref_rmem_f32_2, !cute.coord<"9">, f32) -> ()
      %830 = cute.memref.load(%view, %8) : (!memref_rmem_f32_1, !cute.coord<"26">) -> f32
      cute.memref.store(%rmem_361, %26, %830) : (!memref_rmem_f32_2, !cute.coord<"10">, f32) -> ()
      %831 = cute.memref.load(%view, %7) : (!memref_rmem_f32_1, !cute.coord<"27">) -> f32
      cute.memref.store(%rmem_361, %25, %831) : (!memref_rmem_f32_2, !cute.coord<"11">, f32) -> ()
      %832 = cute.memref.load(%view, %6) : (!memref_rmem_f32_1, !cute.coord<"28">) -> f32
      cute.memref.store(%rmem_361, %24, %832) : (!memref_rmem_f32_2, !cute.coord<"12">, f32) -> ()
      %833 = cute.memref.load(%view, %5) : (!memref_rmem_f32_1, !cute.coord<"29">) -> f32
      cute.memref.store(%rmem_361, %23, %833) : (!memref_rmem_f32_2, !cute.coord<"13">, f32) -> ()
      %834 = cute.memref.load(%view, %4) : (!memref_rmem_f32_1, !cute.coord<"30">) -> f32
      cute.memref.store(%rmem_361, %22, %834) : (!memref_rmem_f32_2, !cute.coord<"14">, f32) -> ()
      %835 = cute.memref.load(%view, %3) : (!memref_rmem_f32_1, !cute.coord<"31">) -> f32
      cute.memref.store(%rmem_361, %21, %835) : (!memref_rmem_f32_2, !cute.coord<"15">, f32) -> ()
      %rmem_374 = cute.memref.alloca() : !memref_rmem_f16_2
      %iter_375 = cute.get_iter(%rmem_374) : !memref_rmem_f16_2
      %836 = cute.memref.load_vec %rmem_361 : !memref_rmem_f32_2
      %837 = arith.truncf %836 : vector<16xf32> to vector<16xf16>
      cute.memref.store_vec %837, %rmem_374 : !memref_rmem_f16_2
      cf.br ^bb161(%c0_i32 : i32)
    ^bb161(%838: i32):  // 2 preds: ^bb160, ^bb162
      %839 = arith.cmpi slt, %838, %276 : i32
      cf.cond_br %839, ^bb162, ^bb163 {llvm.loop_annotation = #loop_annotation}
    ^bb162:  // pred: ^bb161
      %coord_376 = cute.make_coord(%838) : (i32) -> !cute.coord<"(_,?)">
      %idx_377 = cute.crd2idx(%coord_376, %20) : (!cute.coord<"(_,?)">, !cute.layout<"(((2,2,2),1),((2,1))):(((1,2,4),0),((8,0)))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_378 = cute.add_offset(%iter_375, %idx_377) : (!cute.ptr<f16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
      %idx_379 = cute.crd2idx(%coord_376, %19) : (!cute.coord<"(_,?)">, !cute.layout<"((8,1),((2,1))):((1,0),((32,0)))">) -> !cute.int_tuple<"?{div=32}">
      %ptr_380 = cute.add_offset(%ptr_102, %idx_379) : (!cute.ptr<f16, smem, align<16>, S<3,4,3>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      %840 = builtin.unrealized_conversion_cast %ptr_378 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
      %841 = llvm.load %840 : !llvm.ptr -> vector<4xi32>
      %swizzled_381 = cute.apply_swizzle(%ptr_380) : !cute.ptr<f16, smem, align<16>, S<3,4,3>>
      cute_nvgpu.arch.copy.stsm(%swizzled_381, %841) {matrix_shape = <"(8,8)">, num_matrices = 4 : i32, transpose} : <f16, smem, align<16>, S<3,4,3>>, vector<4xi32>
      %842 = arith.addi %838, %c1_i32 : i32
      cf.br ^bb161(%842 : i32)
    ^bb163:  // pred: ^bb161
      nvvm.fence.proxy {kind = #nvvm.proxy_kind<async.shared>, space = #nvvm.shared_space<cta>}
      nvvm.barrier id = %c2_i32 number_of_threads = %c128_i32
      cf.cond_br %86, ^bb164, ^bb168
    ^bb164:  // pred: ^bb163
      %ptr_382 = cute.add_offset(%iter_16, %40) : (!cute.ptr<f16, smem, align<1024>, S<3,4,3>>, !cute.int_tuple<"2048">) -> !cute.ptr<f16, smem, align<1024>, S<3,4,3>>
      %tup_383 = cute.add_offset(%tup, %2) : (!cute.int_tuple<"(?{div=64},?{div=64},?)">, !cute.int_tuple<"(0,32)">) -> !cute.int_tuple<"(?{div=64},?{div=32},?)">
      %e0_384, %e1_385, %e2_386 = cute.get_leaves(%tup_383) : !cute.int_tuple<"(?{div=64},?{div=32},?)">
      %int_tuple_387 = cute.make_int_tuple(%e0_384, %e1_385, %e2_386) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=32}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=64},?{div=32},?)">
      %843 = cute_nvgpu.atom.make_exec_tma(%arg4) : (!cute_nvgpu.atom.non_exec_tiled_tma_store<f16, copy_bits = 32768, tma_gbasis = <"(64,32,1):(1@0,1@1,1@2)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_store<f16, copy_bits = 32768, mode = tiled, g_stride = <"()"> tma_gbasis = <"(64,32,1):(1@0,1@1,1@2)">>
      %TMADescAddr_388 = cute_nvgpu.get_tma_desc_addr(%843 : !cute_nvgpu.atom.tma_store<f16, copy_bits = 32768, mode = tiled, g_stride = <"()"> tma_gbasis = <"(64,32,1):(1@0,1@1,1@2)">>) -> !cute.ptr<generic, align<64>>
      %844 = cute_nvgpu.atom.get_value(%843 : !cute_nvgpu.atom.tma_store<f16, copy_bits = 32768, mode = tiled, g_stride = <"()"> tma_gbasis = <"(64,32,1):(1@0,1@1,1@2)">>) {field = #cute_nvgpu.atom_copy_field_tmastore<cache_policy>} : i64
      %845:3 = cute.get_scalars(%int_tuple_387) : !cute.int_tuple<"(?{div=64},?{div=32},?)">
      cf.br ^bb165(%c0_i32 : i32)
    ^bb165(%846: i32):  // 2 preds: ^bb164, ^bb166
      %847 = arith.cmpi slt, %846, %280 : i32
      cf.cond_br %847, ^bb166, ^bb167 {llvm.loop_annotation = #loop_annotation}
    ^bb166:  // pred: ^bb165
      cute_nvgpu.arch.copy.SM100.tma_store(%TMADescAddr_388 : !cute.ptr<generic, align<64>>, %ptr_382 : !cute.ptr<f16, smem, align<1024>, S<3,4,3>>, [%845#0, %845#1, %845#2] : i32, i32, i32) cache_policy = %844 mode = <tiled>
      %848 = arith.addi %846, %c1_i32 : i32
      cf.br ^bb165(%848 : i32)
    ^bb167:  // pred: ^bb165
      nvvm.cp.async.bulk.commit.group
      nvvm.cp.async.bulk.wait_group 7 {read}
      cf.br ^bb168
    ^bb168:  // 2 preds: ^bb163, ^bb167
      %849 = arith.addi %316, %211 : i32
      %850 = arith.addi %317, %c1_i32 : i32
      %851 = arith.cmpi sgt, %212, %849 : i32
      %852 = nvvm.mul  hi %849, %multiplier : i32 -> i32
      %853 = arith.subi %849, %852 : i32
      %854 = arith.shrui %853, %215 : i32
      %855 = arith.addi %852, %854 : i32
      %856 = arith.shrui %855, %216 : i32
      %857 = arith.muli %856, %214 : i32
      %858 = arith.subi %849, %857 : i32
      %859 = nvvm.mul  hi %858, %multiplier_66 : i32 -> i32
      %860 = arith.subi %858, %859 : i32
      %861 = arith.shrui %860, %225 : i32
      %862 = arith.addi %859, %861 : i32
      %863 = arith.shrui %862, %226 : i32
      %864 = arith.muli %863, %224 : i32
      %865 = arith.subi %858, %864 : i32
      %866 = nvvm.mul  hi %863, %multiplier_69 : i32 -> i32
      %867 = arith.subi %863, %866 : i32
      %868 = arith.shrui %867, %235 : i32
      %869 = arith.addi %866, %868 : i32
      %870 = arith.shrui %869, %236 : i32
      %871 = arith.muli %870, %234 : i32
      %872 = arith.subi %863, %871 : i32
      %int_tuple_389 = cute.make_int_tuple(%865) : (i32) -> !cute.int_tuple<"?">
      %mul_390 = cute.tuple_mul(%int_tuple_389, %59) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %873 = cute.get_scalars(%mul_390) : !cute.int_tuple<"?">
      %int_tuple_391 = cute.make_int_tuple(%872) : (i32) -> !cute.int_tuple<"?">
      %mul_392 = cute.tuple_mul(%int_tuple_391, %59) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %874 = cute.get_scalars(%mul_392) : !cute.int_tuple<"?">
      %int_tuple_393 = cute.make_int_tuple(%870) : (i32) -> !cute.int_tuple<"?">
      %mul_394 = cute.tuple_mul(%int_tuple_393, %59) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %875 = cute.get_scalars(%mul_394) : !cute.int_tuple<"?">
      nvvm.cp.async.bulk.wait_group 0 {read}
      cf.br ^bb8(%873, %874, %875, %851, %756, %758, %849, %850 : i32, i32, i32, i1, i32, i32, i32, i32)
    ^bb169:  // pred: ^bb8
      cf.br ^bb205
    ^bb170:  // pred: ^bb6
      %876 = arith.cmpi eq, %85, %c4_i32 : i32
      cf.cond_br %876, ^bb171, ^bb204
    ^bb171:  // pred: ^bb170
      nvvm.setmaxregister  decrease 40
      %877:3 = cute.get_scalars(%lay_53) <{only_dynamic}> : !cute.layout<"(((64,64),1),?,?,?):(((1@0,1@1),0),64@0,64@1,1@2)">
      %shape_395 = cute.make_shape(%877#1) : (i32) -> !cute.shape<"(((64,64),1),?)">
      %lay_396 = cute.make_layout(%shape_395, %1) : !cute.layout<"(((64,64),1),?):(((1@0,1@1),0),64@1)">
      %878:3 = cute.get_scalars(%lay_57) <{only_dynamic}> : !cute.layout<"(((64,64),1),?,?,?):(((1@0,1@1),0),64@0,64@1,1@2)">
      %shape_397 = cute.make_shape(%878#1) : (i32) -> !cute.shape<"(((64,64),1),?)">
      %lay_398 = cute.make_layout(%shape_397, %1) : !cute.layout<"(((64,64),1),?):(((1@0,1@1),0),64@1)">
      %879 = cute_nvgpu.atom.make_exec_tma(%arg0) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 65536, tma_gbasis = <"(64,64,1):(1@0,1@1,1@2)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_load<f16, copy_bits = 65536, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,64,1):(1@0,1@1,1@2)">>
      %880 = cute.get_scalars(%59) : !cute.int_tuple<"1">
      %881 = cute_nvgpu.atom.make_exec_tma(%arg2) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 65536, tma_gbasis = <"(64,64,1):(1@0,1@1,1@2)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_load<f16, copy_bits = 65536, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,64,1):(1@0,1@1,1@2)">>
      cf.br ^bb172(%244, %245, %246, %213, %c0_i32, %c1_i32, %207, %c0_i32 : i32, i32, i32, i1, i32, i32, i32, i32)
    ^bb172(%882: i32, %883: i32, %884: i32, %885: i1, %886: i32, %887: i32, %888: i32, %889: i32):  // 2 preds: ^bb171, ^bb188
      cf.cond_br %885, ^bb173(%882, %883, %884, %886, %887, %888, %889 : i32, i32, i32, i32, i32, i32, i32), ^bb189
    ^bb173(%890: i32, %891: i32, %892: i32, %893: i32, %894: i32, %895: i32, %896: i32):  // pred: ^bb172
      %coord_399 = cute.make_coord(%890, %892) : (i32, i32) -> !cute.coord<"(_,?,_,?)">
      %idx_400 = cute.crd2idx(%coord_399, %lay_53) : (!cute.coord<"(_,?,_,?)">, !cute.layout<"(((64,64),1),?,?,?):(((1@0,1@1),0),64@0,64@1,1@2)">) -> !cute.int_tuple<"(?{div=64},0,?)">
      %tup_401 = cute.add_offset(%53, %idx_400) : (!cute.int_tuple<"(0,0,0)">, !cute.int_tuple<"(?{div=64},0,?)">) -> !cute.int_tuple<"(?{div=64},0,?)">
      %coord_402 = cute.make_coord(%891, %892) : (i32, i32) -> !cute.coord<"(_,?,_,?)">
      %idx_403 = cute.crd2idx(%coord_402, %lay_57) : (!cute.coord<"(_,?,_,?)">, !cute.layout<"(((64,64),1),?,?,?):(((1@0,1@1),0),64@0,64@1,1@2)">) -> !cute.int_tuple<"(?{div=64},0,?)">
      %tup_404 = cute.add_offset(%53, %idx_403) : (!cute.int_tuple<"(0,0,0)">, !cute.int_tuple<"(?{div=64},0,?)">) -> !cute.int_tuple<"(?{div=64},0,?)">
      cf.br ^bb174(%c0_i32, %c0_i32, %893, %894 : i32, i32, i32, i32)
    ^bb174(%897: i32, %898: i32, %899: i32, %900: i32):  // 2 preds: ^bb173, ^bb187
      %901 = arith.cmpi slt, %897, %206 : i32
      cf.cond_br %901, ^bb175, ^bb188 {loop_annotation = #loop_annotation1}
    ^bb175:  // pred: ^bb174
      %int_tuple_405 = cute.make_int_tuple(%899) : (i32) -> !cute.int_tuple<"?">
      %ptr_406 = cute.add_offset(%ptr_7, %int_tuple_405) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %902 = builtin.unrealized_conversion_cast %ptr_406 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %902, %900, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %903 = nvvm.elect.sync -> i1
      cf.cond_br %903, ^bb176, ^bb177
    ^bb176:  // pred: ^bb175
      %ptr_407 = cute.add_offset(%iter, %int_tuple_405) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %904 = builtin.unrealized_conversion_cast %ptr_407 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %904, %c16384_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
      cf.br ^bb177
    ^bb177:  // 2 preds: ^bb175, ^bb176
      %coord_408 = cute.make_coord(%898) : (i32) -> !cute.coord<"(_,?)">
      %idx_409 = cute.crd2idx(%coord_408, %lay_396) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,64),1),?):(((1@0,1@1),0),64@1)">) -> !cute.int_tuple<"(0,?{div=64})">
      %tup_410 = cute.add_offset(%tup_401, %idx_409) : (!cute.int_tuple<"(?{div=64},0,?)">, !cute.int_tuple<"(0,?{div=64})">) -> !cute.int_tuple<"(?{div=64},?{div=64},?)">
      %e0_411, %e1_412, %e2_413 = cute.get_leaves(%tup_410) : !cute.int_tuple<"(?{div=64},?{div=64},?)">
      %coord_414 = cute.make_coord(%899) : (i32) -> !cute.coord<"(_,?)">
      %idx_415 = cute.crd2idx(%coord_414, %0) : (!cute.coord<"(_,?)">, !cute.layout<"((4096,1),(1,4)):((1,0),(0,4096))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_416 = cute.add_offset(%iter_14, %idx_415) : (!cute.ptr<f16, smem, align<1024>, S<3,4,3>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, smem, align<1024>, S<3,4,3>>
      %idx_417 = cute.crd2idx(%coord_408, %lay_398) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,64),1),?):(((1@0,1@1),0),64@1)">) -> !cute.int_tuple<"(0,?{div=64})">
      %tup_418 = cute.add_offset(%tup_404, %idx_417) : (!cute.int_tuple<"(?{div=64},0,?)">, !cute.int_tuple<"(0,?{div=64})">) -> !cute.int_tuple<"(?{div=64},?{div=64},?)">
      %e0_419, %e1_420, %e2_421 = cute.get_leaves(%tup_418) : !cute.int_tuple<"(?{div=64},?{div=64},?)">
      %ptr_422 = cute.add_offset(%iter_15, %idx_415) : (!cute.ptr<f16, smem, align<1024>, S<3,4,3>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, smem, align<1024>, S<3,4,3>>
      %ptr_423 = cute.add_offset(%iter, %int_tuple_405) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %int_tuple_424 = cute.make_int_tuple(%e0_411, %e1_412, %e2_413) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=64},?{div=64},?)">
      %905 = cute_nvgpu.atom.set_value(%879, %ptr_423 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 65536, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,64,1):(1@0,1@1,1@2)">>
      %906 = cute_nvgpu.atom.get_value(%905 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 65536, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,64,1):(1@0,1@1,1@2)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
      %907 = cute_nvgpu.atom.get_value(%905 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 65536, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,64,1):(1@0,1@1,1@2)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<cache_policy>} : i64
      %TMADescAddr_425 = cute_nvgpu.get_tma_desc_addr(%905 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 65536, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,64,1):(1@0,1@1,1@2)">>) -> !cute.ptr<generic, align<64>>
      %908:3 = cute.get_scalars(%int_tuple_424) : !cute.int_tuple<"(?{div=64},?{div=64},?)">
      cf.br ^bb178(%c0_i32 : i32)
    ^bb178(%909: i32):  // 2 preds: ^bb177, ^bb179
      %910 = arith.cmpi slt, %909, %880 : i32
      cf.cond_br %910, ^bb179, ^bb180 {llvm.loop_annotation = #loop_annotation}
    ^bb179:  // pred: ^bb178
      cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr_425 : !cute.ptr<generic, align<64>>, %ptr_416 : !cute.ptr<f16, smem, align<1024>, S<3,4,3>>, %906 : !cute.ptr<smem, align<8>>, [%908#0, %908#1, %908#2] : i32, i32, i32) cache_policy = %907 mode = <tiled> num_cta = 1 : i32
      %911 = arith.addi %909, %c1_i32 : i32
      cf.br ^bb178(%911 : i32)
    ^bb180:  // pred: ^bb178
      %int_tuple_426 = cute.make_int_tuple(%e0_419, %e1_420, %e2_421) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=64},?{div=64},?)">
      %912 = cute_nvgpu.atom.set_value(%881, %ptr_423 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 65536, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,64,1):(1@0,1@1,1@2)">>
      %913 = cute_nvgpu.atom.get_value(%912 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 65536, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,64,1):(1@0,1@1,1@2)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
      %914 = cute_nvgpu.atom.get_value(%912 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 65536, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,64,1):(1@0,1@1,1@2)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<cache_policy>} : i64
      %TMADescAddr_427 = cute_nvgpu.get_tma_desc_addr(%912 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 65536, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,64,1):(1@0,1@1,1@2)">>) -> !cute.ptr<generic, align<64>>
      %915:3 = cute.get_scalars(%int_tuple_426) : !cute.int_tuple<"(?{div=64},?{div=64},?)">
      cf.br ^bb181(%c0_i32 : i32)
    ^bb181(%916: i32):  // 2 preds: ^bb180, ^bb182
      %917 = arith.cmpi slt, %916, %880 : i32
      cf.cond_br %917, ^bb182, ^bb183 {llvm.loop_annotation = #loop_annotation}
    ^bb182:  // pred: ^bb181
      cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr_427 : !cute.ptr<generic, align<64>>, %ptr_422 : !cute.ptr<f16, smem, align<1024>, S<3,4,3>>, %913 : !cute.ptr<smem, align<8>>, [%915#0, %915#1, %915#2] : i32, i32, i32) cache_policy = %914 mode = <tiled> num_cta = 1 : i32
      %918 = arith.addi %916, %c1_i32 : i32
      cf.br ^bb181(%918 : i32)
    ^bb183:  // pred: ^bb181
      %919 = arith.addi %899, %c1_i32 : i32
      %920 = arith.addi %898, %c1_i32 : i32
      %921 = arith.cmpi eq, %919, %c4_i32 : i32
      %922 = arith.select %921, %c0_i32, %919 : i32
      cf.cond_br %921, ^bb184, ^bb185
    ^bb184:  // pred: ^bb183
      %923 = arith.xori %900, %c1_i32 : i32
      cf.br ^bb186(%923 : i32)
    ^bb185:  // pred: ^bb183
      cf.br ^bb186(%900 : i32)
    ^bb186(%924: i32):  // 2 preds: ^bb184, ^bb185
      cf.br ^bb187
    ^bb187:  // pred: ^bb186
      %925 = arith.addi %897, %c1_i32 : i32
      cf.br ^bb174(%925, %920, %922, %924 : i32, i32, i32, i32)
    ^bb188:  // pred: ^bb174
      %926 = arith.addi %895, %211 : i32
      %927 = arith.addi %896, %c1_i32 : i32
      %928 = arith.cmpi sgt, %212, %926 : i32
      %929 = nvvm.mul  hi %926, %multiplier : i32 -> i32
      %930 = arith.subi %926, %929 : i32
      %931 = arith.shrui %930, %215 : i32
      %932 = arith.addi %929, %931 : i32
      %933 = arith.shrui %932, %216 : i32
      %934 = arith.muli %933, %214 : i32
      %935 = arith.subi %926, %934 : i32
      %936 = nvvm.mul  hi %935, %multiplier_66 : i32 -> i32
      %937 = arith.subi %935, %936 : i32
      %938 = arith.shrui %937, %225 : i32
      %939 = arith.addi %936, %938 : i32
      %940 = arith.shrui %939, %226 : i32
      %941 = arith.muli %940, %224 : i32
      %942 = arith.subi %935, %941 : i32
      %943 = nvvm.mul  hi %940, %multiplier_69 : i32 -> i32
      %944 = arith.subi %940, %943 : i32
      %945 = arith.shrui %944, %235 : i32
      %946 = arith.addi %943, %945 : i32
      %947 = arith.shrui %946, %236 : i32
      %948 = arith.muli %947, %234 : i32
      %949 = arith.subi %940, %948 : i32
      %int_tuple_428 = cute.make_int_tuple(%942) : (i32) -> !cute.int_tuple<"?">
      %mul_429 = cute.tuple_mul(%int_tuple_428, %59) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %950 = cute.get_scalars(%mul_429) : !cute.int_tuple<"?">
      %int_tuple_430 = cute.make_int_tuple(%949) : (i32) -> !cute.int_tuple<"?">
      %mul_431 = cute.tuple_mul(%int_tuple_430, %59) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %951 = cute.get_scalars(%mul_431) : !cute.int_tuple<"?">
      %int_tuple_432 = cute.make_int_tuple(%947) : (i32) -> !cute.int_tuple<"?">
      %mul_433 = cute.tuple_mul(%int_tuple_432, %59) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %952 = cute.get_scalars(%mul_433) : !cute.int_tuple<"?">
      cf.br ^bb172(%950, %951, %952, %928, %899, %900, %926, %927 : i32, i32, i32, i1, i32, i32, i32, i32)
    ^bb189:  // pred: ^bb172
      %953 = arith.addi %886, %c1_i32 : i32
      %954 = arith.cmpi eq, %953, %c4_i32 : i32
      %955 = arith.select %954, %c0_i32, %953 : i32
      cf.cond_br %954, ^bb190, ^bb191
    ^bb190:  // pred: ^bb189
      %956 = arith.xori %887, %c1_i32 : i32
      cf.br ^bb192(%956 : i32)
    ^bb191:  // pred: ^bb189
      cf.br ^bb192(%887 : i32)
    ^bb192(%957: i32):  // 2 preds: ^bb190, ^bb191
      cf.br ^bb193
    ^bb193:  // pred: ^bb192
      %958 = arith.addi %955, %c1_i32 : i32
      %959 = arith.cmpi eq, %958, %c4_i32 : i32
      %960 = arith.select %959, %c0_i32, %958 : i32
      cf.cond_br %959, ^bb194, ^bb195
    ^bb194:  // pred: ^bb193
      %961 = arith.xori %957, %c1_i32 : i32
      cf.br ^bb196(%961 : i32)
    ^bb195:  // pred: ^bb193
      cf.br ^bb196(%957 : i32)
    ^bb196(%962: i32):  // 2 preds: ^bb194, ^bb195
      cf.br ^bb197
    ^bb197:  // pred: ^bb196
      %963 = arith.addi %960, %c1_i32 : i32
      %964 = arith.cmpi eq, %963, %c4_i32 : i32
      %965 = arith.select %964, %c0_i32, %963 : i32
      cf.cond_br %964, ^bb198, ^bb199
    ^bb198:  // pred: ^bb197
      %966 = arith.xori %962, %c1_i32 : i32
      cf.br ^bb200(%966 : i32)
    ^bb199:  // pred: ^bb197
      cf.br ^bb200(%962 : i32)
    ^bb200(%967: i32):  // 2 preds: ^bb198, ^bb199
      cf.br ^bb201
    ^bb201:  // pred: ^bb200
      %int_tuple_434 = cute.make_int_tuple(%965) : (i32) -> !cute.int_tuple<"?">
      %ptr_435 = cute.add_offset(%ptr_7, %int_tuple_434) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %968 = builtin.unrealized_conversion_cast %ptr_435 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %968, %967, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %969 = nvvm.elect.sync -> i1
      cf.cond_br %969, ^bb202, ^bb203
    ^bb202:  // pred: ^bb201
      %ptr_436 = cute.add_offset(%iter, %int_tuple_434) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %970 = builtin.unrealized_conversion_cast %ptr_436 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %970, %c16384_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
      cf.br ^bb203
    ^bb203:  // 2 preds: ^bb201, ^bb202
      cf.br ^bb204
    ^bb204:  // 2 preds: ^bb170, ^bb203
      cf.br ^bb205
    ^bb205:  // 2 preds: ^bb169, ^bb204
      return
    }
  }
  func.func @cutlass___call_____main__Sm120GemmKernel_object_at__Tensorgmemo1i64i64_Tensorgmemo1i64i64_Tensorgmemo1i64i64_1_CUstream0x0(%arg0: !memref_gmem_f16_, %arg1: !memref_gmem_f16_, %arg2: !memref_gmem_f16_, %arg3: !cuda.stream) -> i32 attributes {llvm.emit_c_interface} {
    %c99328_i64 = arith.constant 99328 : i64
    %c4294967296_i64 = arith.constant 4294967296 : i64
    %c-2147483648_i32 = arith.constant -2147483648 : i32
    %0 = llvm.mlir.constant(31 : i64) : i64
    %1 = llvm.mlir.constant(63 : i64) : i64
    %2 = llvm.mlir.constant(4539628424389459968 : i64) : i64
    %3 = llvm.mlir.constant(287522 : i64) : i64
    %c0_i32 = arith.constant 0 : i32
    %c160_i32 = arith.constant 160 : i32
    %c1_i32 = arith.constant 1 : i32
    %4 = cute.static : !cute.int_tuple<"1">
    %5 = llvm.mlir.constant(1 : i64) : i64
    %6 = llvm.mlir.constant(1 : i8) : i8
    %7 = llvm.mlir.constant(2 : i32) : i32
    %8 = llvm.mlir.constant(32 : i8) : i8
    %9 = llvm.mlir.constant(0 : i8) : i8
    %10 = llvm.mlir.constant(1 : i32) : i32
    %c64_i64 = arith.constant 64 : i64
    %c64_i32 = arith.constant 64 : i32
    %11 = cute.static : !cute.int_tuple<"(0,0,0)">
    %12 = cute.static : !cute.stride<"(1@0,1@1,1@2)">
    %c44_i64 = arith.constant 44 : i64
    %c40_i64 = arith.constant 40 : i64
    %c15_i64 = arith.constant 15 : i64
    %c36_i64 = arith.constant 36 : i64
    %c21_i64 = arith.constant 21 : i64
    %c131072_i64 = arith.constant 131072 : i64
    %c32_i64 = arith.constant 32 : i64
    %c9007199254740991_i64 = arith.constant 9007199254740991 : i64
    %c4_i64 = arith.constant 4 : i64
    %c4294967295_i64 = arith.constant 4294967295 : i64
    %c16_i64 = arith.constant 16 : i64
    %c8_i64 = arith.constant 8 : i64
    %c2_i64 = arith.constant 2 : i64
    %c1_i64 = arith.constant 1 : i64
    %c0_i64 = arith.constant 0 : i64
    %c16_i32 = arith.constant 16 : i32
    %13 = llvm.alloca %c16_i32 x i64 {alignment = 64 : i64} : (i32) -> !llvm.ptr
    %iter = cute.get_iter(%arg0) : !memref_gmem_f16_
    %lay = cute.get_layout(%arg0) : !memref_gmem_f16_
    %14:5 = cute.get_scalars(%lay) <{only_dynamic}> : !cute.layout<"(?,?,?):(1,?{i64},?{i64})">
    %15 = arith.extui %14#0 : i32 to i64
    %16 = arith.extui %14#1 : i32 to i64
    %17 = llvm.mul %14#3, %c2_i64 : i64
    %18 = arith.extui %14#2 : i32 to i64
    %19 = llvm.mul %14#4, %c2_i64 : i64
    %20 = cute.ptrtoint(%iter) : !cute.ptr<f16, gmem, align<16>> to i64
    %21 = llvm.getelementptr %13[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %21 : i64, !llvm.ptr
    %22 = llvm.getelementptr %13[0, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %22 : i64, !llvm.ptr
    %23 = llvm.getelementptr %13[0, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %23 : i64, !llvm.ptr
    %24 = llvm.getelementptr %13[0, 3] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %24 : i64, !llvm.ptr
    %25 = llvm.getelementptr %13[0, 4] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %25 : i64, !llvm.ptr
    %26 = llvm.getelementptr %13[0, 5] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %26 : i64, !llvm.ptr
    %27 = llvm.getelementptr %13[0, 6] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %27 : i64, !llvm.ptr
    %28 = llvm.getelementptr %13[0, 7] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %28 : i64, !llvm.ptr
    %29 = llvm.getelementptr %13[0, 8] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %29 : i64, !llvm.ptr
    %30 = llvm.getelementptr %13[0, 9] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %30 : i64, !llvm.ptr
    %31 = llvm.getelementptr %13[0, 10] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %31 : i64, !llvm.ptr
    %32 = llvm.getelementptr %13[0, 11] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %32 : i64, !llvm.ptr
    %33 = llvm.getelementptr %13[0, 12] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %33 : i64, !llvm.ptr
    %34 = llvm.getelementptr %13[0, 13] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %34 : i64, !llvm.ptr
    %35 = llvm.getelementptr %13[0, 14] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %35 : i64, !llvm.ptr
    %36 = llvm.getelementptr %13[0, 15] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %36 : i64, !llvm.ptr
    %37 = llvm.udiv %20, %c16_i64 : i64
    %38 = llvm.and %37, %c9007199254740991_i64 : i64
    %39 = llvm.shl %38, %c4_i64 : i64
    llvm.store %39, %21 : i64, !llvm.ptr
    %40 = llvm.sub %16, %c1_i64 : i64
    %41 = llvm.sub %18, %c1_i64 : i64
    %42 = llvm.sub %c1_i64, %c1_i64 : i64
    %43 = llvm.mul %40, %17 : i64
    %44 = llvm.mul %41, %19 : i64
    %45 = llvm.mul %42, %c0_i64 : i64
    %46 = llvm.add %43, %44 : i64
    %47 = llvm.add %45, %45 : i64
    %48 = llvm.mul %15, %c16_i64 : i64
    %49 = llvm.udiv %48, %c8_i64 : i64
    %50 = llvm.add %49, %46 : i64
    %51 = llvm.add %50, %47 : i64
    %52 = llvm.icmp "uge" %51, %c131072_i64 : i64
    %53 = llvm.zext %52 : i1 to i64
    %54 = llvm.shl %53, %c21_i64 : i64
    %55 = llvm.udiv %17, %c16_i64 : i64
    %56 = llvm.shl %55, %c32_i64 : i64
    %57 = llvm.or %c0_i64, %54 : i64
    %58 = llvm.or %57, %56 : i64
    %59 = llvm.or %3, %58 : i64
    llvm.store %59, %22 : i64, !llvm.ptr
    %60 = llvm.udiv %19, %c16_i64 : i64
    %61 = llvm.and %60, %c4294967295_i64 : i64
    %62 = llvm.shl %61, %c0_i64 : i64
    %63 = llvm.udiv %c0_i64, %c16_i64 : i64
    %64 = llvm.shl %63, %c32_i64 : i64
    %65 = llvm.or %62, %64 : i64
    llvm.store %65, %23 : i64, !llvm.ptr
    %66 = llvm.and %63, %c4294967295_i64 : i64
    %67 = llvm.shl %66, %c0_i64 : i64
    %68 = llvm.lshr %17, %c36_i64 : i64
    %69 = llvm.and %68, %c15_i64 : i64
    %70 = llvm.shl %69, %c32_i64 : i64
    %71 = llvm.lshr %19, %c36_i64 : i64
    %72 = llvm.and %71, %c15_i64 : i64
    %73 = llvm.shl %72, %c36_i64 : i64
    %74 = llvm.lshr %c0_i64, %c36_i64 : i64
    %75 = llvm.and %74, %c15_i64 : i64
    %76 = llvm.shl %75, %c40_i64 : i64
    %77 = llvm.shl %74, %c44_i64 : i64
    %78 = llvm.or %70, %73 : i64
    %79 = llvm.or %76, %77 : i64
    %80 = llvm.or %78, %79 : i64
    %81 = llvm.or %67, %80 : i64
    llvm.store %81, %24 : i64, !llvm.ptr
    %82 = llvm.sub %15, %c1_i64 : i64
    %83 = llvm.and %82, %c4294967295_i64 : i64
    %84 = llvm.shl %83, %c0_i64 : i64
    %85 = llvm.shl %40, %c32_i64 : i64
    %86 = llvm.or %84, %85 : i64
    llvm.store %86, %25 : i64, !llvm.ptr
    %87 = llvm.and %41, %c4294967295_i64 : i64
    %88 = llvm.shl %87, %c0_i64 : i64
    %89 = llvm.shl %42, %c32_i64 : i64
    %90 = llvm.or %88, %89 : i64
    llvm.store %90, %26 : i64, !llvm.ptr
    %91 = llvm.and %42, %c4294967295_i64 : i64
    %92 = llvm.or %91, %c0_i64 : i64
    %93 = llvm.or %92, %2 : i64
    llvm.store %93, %27 : i64, !llvm.ptr
    llvm.store %1, %28 : i64, !llvm.ptr
    %94 = builtin.unrealized_conversion_cast %13 : !llvm.ptr to !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>>
    %95 = cute.ptrtoint(%94) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>> to i64
    %96 = llvm.inttoptr %95 : i64 to !llvm.ptr
    %97 = llvm.load %96 {nontemporal} : !llvm.ptr -> !llvm.struct<(array<16 x i64>)>
    %98 = builtin.unrealized_conversion_cast %97 : !llvm.struct<(array<16 x i64>)> to !cute_nvgpu.tma_descriptor_tiled
    %atom = cute.make_atom() : () -> !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 65536, tma_gbasis = <"(64,64,1):(1@0,1@1,1@2)">, internal_val_type = f16>
    %99 = cute_nvgpu.atom.set_value(%atom, %98 : !cute_nvgpu.tma_descriptor_tiled) {field = #cute_nvgpu.atom_copy_field_non_exec_tma_load<tma_desc>} : !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 65536, tma_gbasis = <"(64,64,1):(1@0,1@1,1@2)">, internal_val_type = f16>
    %100 = cute.get_shape(%lay) : (!cute.layout<"(?,?,?):(1,?{i64},?{i64})">) -> !cute.shape<"(?,?,?)">
    %lay_0 = cute.make_layout(%100, %12) : !cute.layout<"(?,?,?):(1@0,1@1,1@2)">
    %view = cute.make_view(%11, %lay_0) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">
    %101 = llvm.alloca %c16_i32 x i64 {alignment = 64 : i64} : (i32) -> !llvm.ptr
    %iter_1 = cute.get_iter(%arg1) : !memref_gmem_f16_
    %lay_2 = cute.get_layout(%arg1) : !memref_gmem_f16_
    %102:5 = cute.get_scalars(%lay_2) <{only_dynamic}> : !cute.layout<"(?,?,?):(1,?{i64},?{i64})">
    %103 = arith.extui %102#0 : i32 to i64
    %104 = arith.extui %102#1 : i32 to i64
    %105 = llvm.mul %102#3, %c2_i64 : i64
    %106 = arith.extui %102#2 : i32 to i64
    %107 = llvm.mul %102#4, %c2_i64 : i64
    %108 = cute.ptrtoint(%iter_1) : !cute.ptr<f16, gmem, align<16>> to i64
    %109 = llvm.getelementptr %101[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %109 : i64, !llvm.ptr
    %110 = llvm.getelementptr %101[0, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %110 : i64, !llvm.ptr
    %111 = llvm.getelementptr %101[0, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %111 : i64, !llvm.ptr
    %112 = llvm.getelementptr %101[0, 3] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %112 : i64, !llvm.ptr
    %113 = llvm.getelementptr %101[0, 4] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %113 : i64, !llvm.ptr
    %114 = llvm.getelementptr %101[0, 5] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %114 : i64, !llvm.ptr
    %115 = llvm.getelementptr %101[0, 6] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %115 : i64, !llvm.ptr
    %116 = llvm.getelementptr %101[0, 7] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %116 : i64, !llvm.ptr
    %117 = llvm.getelementptr %101[0, 8] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %117 : i64, !llvm.ptr
    %118 = llvm.getelementptr %101[0, 9] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %118 : i64, !llvm.ptr
    %119 = llvm.getelementptr %101[0, 10] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %119 : i64, !llvm.ptr
    %120 = llvm.getelementptr %101[0, 11] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %120 : i64, !llvm.ptr
    %121 = llvm.getelementptr %101[0, 12] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %121 : i64, !llvm.ptr
    %122 = llvm.getelementptr %101[0, 13] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %122 : i64, !llvm.ptr
    %123 = llvm.getelementptr %101[0, 14] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %123 : i64, !llvm.ptr
    %124 = llvm.getelementptr %101[0, 15] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %124 : i64, !llvm.ptr
    %125 = llvm.udiv %108, %c16_i64 : i64
    %126 = llvm.and %125, %c9007199254740991_i64 : i64
    %127 = llvm.shl %126, %c4_i64 : i64
    llvm.store %127, %109 : i64, !llvm.ptr
    %128 = llvm.sub %104, %c1_i64 : i64
    %129 = llvm.sub %106, %c1_i64 : i64
    %130 = llvm.mul %128, %105 : i64
    %131 = llvm.mul %129, %107 : i64
    %132 = llvm.add %130, %131 : i64
    %133 = llvm.mul %103, %c16_i64 : i64
    %134 = llvm.udiv %133, %c8_i64 : i64
    %135 = llvm.add %134, %132 : i64
    %136 = llvm.add %135, %47 : i64
    %137 = llvm.icmp "uge" %136, %c131072_i64 : i64
    %138 = llvm.zext %137 : i1 to i64
    %139 = llvm.shl %138, %c21_i64 : i64
    %140 = llvm.udiv %105, %c16_i64 : i64
    %141 = llvm.shl %140, %c32_i64 : i64
    %142 = llvm.or %c0_i64, %139 : i64
    %143 = llvm.or %142, %141 : i64
    %144 = llvm.or %3, %143 : i64
    llvm.store %144, %110 : i64, !llvm.ptr
    %145 = llvm.udiv %107, %c16_i64 : i64
    %146 = llvm.and %145, %c4294967295_i64 : i64
    %147 = llvm.shl %146, %c0_i64 : i64
    %148 = llvm.or %147, %64 : i64
    llvm.store %148, %111 : i64, !llvm.ptr
    %149 = llvm.lshr %105, %c36_i64 : i64
    %150 = llvm.and %149, %c15_i64 : i64
    %151 = llvm.shl %150, %c32_i64 : i64
    %152 = llvm.lshr %107, %c36_i64 : i64
    %153 = llvm.and %152, %c15_i64 : i64
    %154 = llvm.shl %153, %c36_i64 : i64
    %155 = llvm.or %151, %154 : i64
    %156 = llvm.or %155, %79 : i64
    %157 = llvm.or %67, %156 : i64
    llvm.store %157, %112 : i64, !llvm.ptr
    %158 = llvm.sub %103, %c1_i64 : i64
    %159 = llvm.and %158, %c4294967295_i64 : i64
    %160 = llvm.shl %159, %c0_i64 : i64
    %161 = llvm.shl %128, %c32_i64 : i64
    %162 = llvm.or %160, %161 : i64
    llvm.store %162, %113 : i64, !llvm.ptr
    %163 = llvm.and %129, %c4294967295_i64 : i64
    %164 = llvm.shl %163, %c0_i64 : i64
    %165 = llvm.or %164, %89 : i64
    llvm.store %165, %114 : i64, !llvm.ptr
    llvm.store %93, %115 : i64, !llvm.ptr
    llvm.store %1, %116 : i64, !llvm.ptr
    %166 = builtin.unrealized_conversion_cast %101 : !llvm.ptr to !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>>
    %167 = cute.ptrtoint(%166) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>> to i64
    %168 = llvm.inttoptr %167 : i64 to !llvm.ptr
    %169 = llvm.load %168 {nontemporal} : !llvm.ptr -> !llvm.struct<(array<16 x i64>)>
    %170 = builtin.unrealized_conversion_cast %169 : !llvm.struct<(array<16 x i64>)> to !cute_nvgpu.tma_descriptor_tiled
    %171 = cute_nvgpu.atom.set_value(%atom, %170 : !cute_nvgpu.tma_descriptor_tiled) {field = #cute_nvgpu.atom_copy_field_non_exec_tma_load<tma_desc>} : !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 65536, tma_gbasis = <"(64,64,1):(1@0,1@1,1@2)">, internal_val_type = f16>
    %172 = cute.get_shape(%lay_2) : (!cute.layout<"(?,?,?):(1,?{i64},?{i64})">) -> !cute.shape<"(?,?,?)">
    %lay_3 = cute.make_layout(%172, %12) : !cute.layout<"(?,?,?):(1@0,1@1,1@2)">
    %view_4 = cute.make_view(%11, %lay_3) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">
    %173 = llvm.alloca %c16_i32 x i64 {alignment = 64 : i64} : (i32) -> !llvm.ptr
    %iter_5 = cute.get_iter(%arg2) : !memref_gmem_f16_
    %lay_6 = cute.get_layout(%arg2) : !memref_gmem_f16_
    %174:5 = cute.get_scalars(%lay_6) <{only_dynamic}> : !cute.layout<"(?,?,?):(1,?{i64},?{i64})">
    %175 = arith.extui %174#0 : i32 to i64
    %176 = arith.extui %174#1 : i32 to i64
    %177 = llvm.mul %174#3, %c2_i64 : i64
    %178 = arith.extui %174#2 : i32 to i64
    %179 = llvm.mul %174#4, %c2_i64 : i64
    %180 = cute.ptrtoint(%iter_5) : !cute.ptr<f16, gmem, align<16>> to i64
    %181 = llvm.getelementptr %173[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %181 : i64, !llvm.ptr
    %182 = llvm.getelementptr %173[0, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %182 : i64, !llvm.ptr
    %183 = llvm.getelementptr %173[0, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %183 : i64, !llvm.ptr
    %184 = llvm.getelementptr %173[0, 3] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %184 : i64, !llvm.ptr
    %185 = llvm.getelementptr %173[0, 4] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %185 : i64, !llvm.ptr
    %186 = llvm.getelementptr %173[0, 5] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %186 : i64, !llvm.ptr
    %187 = llvm.getelementptr %173[0, 6] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %187 : i64, !llvm.ptr
    %188 = llvm.getelementptr %173[0, 7] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %188 : i64, !llvm.ptr
    %189 = llvm.getelementptr %173[0, 8] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %189 : i64, !llvm.ptr
    %190 = llvm.getelementptr %173[0, 9] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %190 : i64, !llvm.ptr
    %191 = llvm.getelementptr %173[0, 10] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %191 : i64, !llvm.ptr
    %192 = llvm.getelementptr %173[0, 11] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %192 : i64, !llvm.ptr
    %193 = llvm.getelementptr %173[0, 12] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %193 : i64, !llvm.ptr
    %194 = llvm.getelementptr %173[0, 13] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %194 : i64, !llvm.ptr
    %195 = llvm.getelementptr %173[0, 14] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %195 : i64, !llvm.ptr
    %196 = llvm.getelementptr %173[0, 15] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %196 : i64, !llvm.ptr
    %197 = llvm.udiv %180, %c16_i64 : i64
    %198 = llvm.and %197, %c9007199254740991_i64 : i64
    %199 = llvm.shl %198, %c4_i64 : i64
    llvm.store %199, %181 : i64, !llvm.ptr
    %200 = llvm.sub %176, %c1_i64 : i64
    %201 = llvm.sub %178, %c1_i64 : i64
    %202 = llvm.mul %200, %177 : i64
    %203 = llvm.mul %201, %179 : i64
    %204 = llvm.add %202, %203 : i64
    %205 = llvm.mul %175, %c16_i64 : i64
    %206 = llvm.udiv %205, %c8_i64 : i64
    %207 = llvm.add %206, %204 : i64
    %208 = llvm.add %207, %47 : i64
    %209 = llvm.icmp "uge" %208, %c131072_i64 : i64
    %210 = llvm.zext %209 : i1 to i64
    %211 = llvm.shl %210, %c21_i64 : i64
    %212 = llvm.udiv %177, %c16_i64 : i64
    %213 = llvm.shl %212, %c32_i64 : i64
    %214 = llvm.or %c0_i64, %211 : i64
    %215 = llvm.or %214, %213 : i64
    %216 = llvm.or %3, %215 : i64
    llvm.store %216, %182 : i64, !llvm.ptr
    %217 = llvm.udiv %179, %c16_i64 : i64
    %218 = llvm.and %217, %c4294967295_i64 : i64
    %219 = llvm.shl %218, %c0_i64 : i64
    %220 = llvm.or %219, %64 : i64
    llvm.store %220, %183 : i64, !llvm.ptr
    %221 = llvm.lshr %177, %c36_i64 : i64
    %222 = llvm.and %221, %c15_i64 : i64
    %223 = llvm.shl %222, %c32_i64 : i64
    %224 = llvm.lshr %179, %c36_i64 : i64
    %225 = llvm.and %224, %c15_i64 : i64
    %226 = llvm.shl %225, %c36_i64 : i64
    %227 = llvm.or %223, %226 : i64
    %228 = llvm.or %227, %79 : i64
    %229 = llvm.or %67, %228 : i64
    llvm.store %229, %184 : i64, !llvm.ptr
    %230 = llvm.sub %175, %c1_i64 : i64
    %231 = llvm.and %230, %c4294967295_i64 : i64
    %232 = llvm.shl %231, %c0_i64 : i64
    %233 = llvm.shl %200, %c32_i64 : i64
    %234 = llvm.or %232, %233 : i64
    llvm.store %234, %185 : i64, !llvm.ptr
    %235 = llvm.and %201, %c4294967295_i64 : i64
    %236 = llvm.shl %235, %c0_i64 : i64
    %237 = llvm.or %236, %89 : i64
    llvm.store %237, %186 : i64, !llvm.ptr
    llvm.store %93, %187 : i64, !llvm.ptr
    llvm.store %0, %188 : i64, !llvm.ptr
    %238 = builtin.unrealized_conversion_cast %173 : !llvm.ptr to !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>>
    %239 = cute.ptrtoint(%238) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>> to i64
    %240 = llvm.inttoptr %239 : i64 to !llvm.ptr
    %241 = llvm.load %240 {nontemporal} : !llvm.ptr -> !llvm.struct<(array<16 x i64>)>
    %242 = builtin.unrealized_conversion_cast %241 : !llvm.struct<(array<16 x i64>)> to !cute_nvgpu.tma_descriptor_tiled
    %atom_7 = cute.make_atom() : () -> !cute_nvgpu.atom.non_exec_tiled_tma_store<f16, copy_bits = 32768, tma_gbasis = <"(64,32,1):(1@0,1@1,1@2)">, internal_val_type = f16>
    %243 = cute_nvgpu.atom.set_value(%atom_7, %242 : !cute_nvgpu.tma_descriptor_tiled) {field = #cute_nvgpu.atom_copy_field_non_exec_tma_store<tma_desc>} : !cute_nvgpu.atom.non_exec_tiled_tma_store<f16, copy_bits = 32768, tma_gbasis = <"(64,32,1):(1@0,1@1,1@2)">, internal_val_type = f16>
    %244 = cute.get_shape(%lay_6) : (!cute.layout<"(?,?,?):(1,?{i64},?{i64})">) -> !cute.shape<"(?,?,?)">
    %lay_8 = cute.make_layout(%244, %12) : !cute.layout<"(?,?,?):(1@0,1@1,1@2)">
    %view_9 = cute.make_view(%11, %lay_8) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">
    %c1_i32_10 = arith.constant 1 : i32
    %c0_i32_11 = arith.constant 0 : i32
    %c-1_i32 = arith.constant -1 : i32
    %245 = arith.cmpi sgt, %c64_i32, %c0_i32_11 : i32
    %246 = arith.select %245, %c-1_i32, %c1_i32_10 : i32
    %247 = arith.addi %246, %174#0 : i32
    %248 = arith.divsi %247, %c64_i32 : i32
    %249 = arith.addi %c1_i32_10, %248 : i32
    %250 = arith.subi %c0_i32_11, %174#0 : i32
    %251 = arith.divsi %250, %c64_i32 : i32
    %252 = arith.subi %c0_i32_11, %251 : i32
    %253 = arith.cmpi slt, %174#0, %c0_i32_11 : i32
    %254 = arith.cmpi sgt, %174#0, %c0_i32_11 : i32
    %255 = arith.cmpi slt, %c64_i32, %c0_i32_11 : i32
    %256 = arith.cmpi sgt, %c64_i32, %c0_i32_11 : i32
    %257 = arith.andi %253, %255 : i1
    %258 = arith.andi %254, %256 : i1
    %259 = arith.ori %257, %258 : i1
    %260 = arith.select %259, %249, %252 : i32
    %c1_i32_12 = arith.constant 1 : i32
    %c0_i32_13 = arith.constant 0 : i32
    %c-1_i32_14 = arith.constant -1 : i32
    %261 = arith.cmpi sgt, %c64_i32, %c0_i32_13 : i32
    %262 = arith.select %261, %c-1_i32_14, %c1_i32_12 : i32
    %263 = arith.addi %262, %174#1 : i32
    %264 = arith.divsi %263, %c64_i32 : i32
    %265 = arith.addi %c1_i32_12, %264 : i32
    %266 = arith.subi %c0_i32_13, %174#1 : i32
    %267 = arith.divsi %266, %c64_i32 : i32
    %268 = arith.subi %c0_i32_13, %267 : i32
    %269 = arith.cmpi slt, %174#1, %c0_i32_13 : i32
    %270 = arith.cmpi sgt, %174#1, %c0_i32_13 : i32
    %271 = arith.cmpi slt, %c64_i32, %c0_i32_13 : i32
    %272 = arith.cmpi sgt, %c64_i32, %c0_i32_13 : i32
    %273 = arith.andi %269, %271 : i1
    %274 = arith.andi %270, %272 : i1
    %275 = arith.ori %273, %274 : i1
    %276 = arith.select %275, %265, %268 : i32
    %277 = arith.muli %174#3, %c64_i64 : i64
    %shape = cute.make_shape(%260, %276, %174#2) : (i32, i32, i32) -> !cute.shape<"((64,64),(?,?,?))">
    %iv = cute.assume(%277) : (i64) -> !cute.i64<divby 64>
    %stride = cute.make_stride(%174#3, %iv, %174#4) : (i64, !cute.i64<divby 64>, i64) -> !cute.stride<"((1,?{i64}),(64,?{i64 div=64},?{i64}))">
    %lay_15 = cute.make_layout(%shape, %stride) : !cute.layout<"((64,64),(?,?,?)):((1,?{i64}),(64,?{i64 div=64},?{i64}))">
    %278:6 = cute.get_scalars(%lay_15) <{only_dynamic}> : !cute.layout<"((64,64),(?,?,?)):((1,?{i64}),(64,?{i64 div=64},?{i64}))">
    %shape_16 = cute.make_shape(%278#0, %278#1, %278#2) : (i32, i32, i32) -> !cute.shape<"(?,?,?)">
    %iv_17 = cute.assume(%278#4) : (i64) -> !cute.i64<divby 64>
    %stride_18 = cute.make_stride(%iv_17, %278#5) : (!cute.i64<divby 64>, i64) -> !cute.stride<"(64,?{i64 div=64},?{i64})">
    %lay_19 = cute.make_layout(%shape_16, %stride_18) : !cute.layout<"(?,?,?):(64,?{i64 div=64},?{i64})">
    %279 = cute.get_shape(%lay_19) : (!cute.layout<"(?,?,?):(64,?{i64 div=64},?{i64})">) -> !cute.shape<"(?,?,?)">
    %e0, %e1, %e2 = cute.get_leaves(%279) : !cute.shape<"(?,?,?)">
    %itup = cute.to_int_tuple(%e0) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %280 = cute.get_scalars(%itup) : !cute.int_tuple<"?">
    %itup_20 = cute.to_int_tuple(%e1) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %281 = cute.get_scalars(%itup_20) : !cute.int_tuple<"?">
    %itup_21 = cute.to_int_tuple(%e2) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %282 = cute.get_scalars(%itup_21) : !cute.int_tuple<"?">
    %int_tuple = cute.make_int_tuple(%itup, %itup_20, %itup_21) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?,?,?)">
    %283:3 = cute.get_scalars(%int_tuple) <{only_dynamic}> : !cute.int_tuple<"(?,?,?)">
    %int_tuple_22 = cute.make_int_tuple(%283#0, %283#1, %283#2) : (i32, i32, i32) -> !cute.int_tuple<"(?,?,?)">
    %e0_23, %e1_24, %e2_25 = cute.get_leaves(%int_tuple_22) : !cute.int_tuple<"(?,?,?)">
    %shape_26 = cute.make_shape(%e0_23, %e1_24, %e2_25) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.shape<"(?,?,?)">
    %lay_27 = cute.make_layout(%shape_26) : !cute.layout<"(?,?,?):(1,?,?)">
    %sz = cute.size(%lay_27) : (!cute.layout<"(?,?,?):(1,?,?)">) -> !cute.int_tuple<"?">
    %e0_28 = cute.get_leaves(%sz) : !cute.int_tuple<"?">
    %284 = cute.get_scalars(%e0_28) : !cute.int_tuple<"?">
    %285 = cute.get_shape(%lay_27) : (!cute.layout<"(?,?,?):(1,?,?)">) -> !cute.shape<"(?,?,?)">
    %e0_29, %e1_30, %e2_31 = cute.get_leaves(%285) : !cute.shape<"(?,?,?)">
    %itup_32 = cute.to_int_tuple(%e0_29) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %286 = cute.get_scalars(%itup_32) : !cute.int_tuple<"?">
    %itup_33 = cute.to_int_tuple(%e1_30) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %287 = cute.get_scalars(%itup_33) : !cute.int_tuple<"?">
    %288 = arith.cmpi eq, %284, %10 : i32
    cf.cond_br %288, ^bb1, ^bb2
  ^bb1:  // pred: ^bb0
    cf.br ^bb10(%9 : i8)
  ^bb2:  // pred: ^bb0
    %289 = arith.cmpi uge, %284, %c-2147483648_i32 : i32
    cf.cond_br %289, ^bb3, ^bb4
  ^bb3:  // pred: ^bb2
    cf.br ^bb8(%8 : i8)
  ^bb4:  // pred: ^bb2
    cf.br ^bb5(%7, %6 : i32, i8)
  ^bb5(%290: i32, %291: i8):  // 2 preds: ^bb4, ^bb6
    %292 = arith.cmpi ult, %290, %284 : i32
    cf.cond_br %292, ^bb6(%290, %291 : i32, i8), ^bb7
  ^bb6(%293: i32, %294: i8):  // pred: ^bb5
    %295 = arith.muli %293, %7 : i32
    %296 = arith.addi %294, %6 : i8
    cf.br ^bb5(%295, %296 : i32, i8)
  ^bb7:  // pred: ^bb5
    cf.br ^bb8(%291 : i8)
  ^bb8(%297: i8):  // 2 preds: ^bb3, ^bb7
    cf.br ^bb9
  ^bb9:  // pred: ^bb8
    cf.br ^bb10(%297 : i8)
  ^bb10(%298: i8):  // 2 preds: ^bb1, ^bb9
    cf.br ^bb11
  ^bb11:  // pred: ^bb10
    %299 = arith.extui %298 : i8 to i64
    %300 = arith.extui %284 : i32 to i64
    %301 = arith.shli %5, %299 : i64
    %302 = arith.subi %301, %300 : i64
    %303 = arith.muli %302, %c4294967296_i64 : i64
    %304 = arith.divui %303, %300 : i64
    %305 = arith.addi %304, %5 : i64
    %306 = arith.trunci %305 : i64 to i32
    %307 = arith.cmpi ult, %298, %6 : i8
    %308 = arith.select %307, %298, %6 : i8
    %309 = arith.cmpi ult, %298, %6 : i8
    %310 = arith.subi %298, %6 : i8
    %311 = arith.select %309, %9, %310 : i8
    %312 = cute.fast_divmod.make_divisor(%284, %306, %308, %311) : i32 -> !cute.fast_divmod_divisor<32>
    %313 = arith.cmpi eq, %286, %10 : i32
    cf.cond_br %313, ^bb12, ^bb13
  ^bb12:  // pred: ^bb11
    cf.br ^bb21(%9 : i8)
  ^bb13:  // pred: ^bb11
    %314 = arith.cmpi uge, %286, %c-2147483648_i32 : i32
    cf.cond_br %314, ^bb14, ^bb15
  ^bb14:  // pred: ^bb13
    cf.br ^bb19(%8 : i8)
  ^bb15:  // pred: ^bb13
    cf.br ^bb16(%7, %6 : i32, i8)
  ^bb16(%315: i32, %316: i8):  // 2 preds: ^bb15, ^bb17
    %317 = arith.cmpi ult, %315, %286 : i32
    cf.cond_br %317, ^bb17(%315, %316 : i32, i8), ^bb18
  ^bb17(%318: i32, %319: i8):  // pred: ^bb16
    %320 = arith.muli %318, %7 : i32
    %321 = arith.addi %319, %6 : i8
    cf.br ^bb16(%320, %321 : i32, i8)
  ^bb18:  // pred: ^bb16
    cf.br ^bb19(%316 : i8)
  ^bb19(%322: i8):  // 2 preds: ^bb14, ^bb18
    cf.br ^bb20
  ^bb20:  // pred: ^bb19
    cf.br ^bb21(%322 : i8)
  ^bb21(%323: i8):  // 2 preds: ^bb12, ^bb20
    cf.br ^bb22
  ^bb22:  // pred: ^bb21
    %324 = arith.extui %323 : i8 to i64
    %325 = arith.extui %286 : i32 to i64
    %326 = arith.shli %5, %324 : i64
    %327 = arith.subi %326, %325 : i64
    %328 = arith.muli %327, %c4294967296_i64 : i64
    %329 = arith.divui %328, %325 : i64
    %330 = arith.addi %329, %5 : i64
    %331 = arith.trunci %330 : i64 to i32
    %332 = arith.cmpi ult, %323, %6 : i8
    %333 = arith.select %332, %323, %6 : i8
    %334 = arith.cmpi ult, %323, %6 : i8
    %335 = arith.subi %323, %6 : i8
    %336 = arith.select %334, %9, %335 : i8
    %337 = cute.fast_divmod.make_divisor(%286, %331, %333, %336) : i32 -> !cute.fast_divmod_divisor<32>
    %338 = arith.cmpi eq, %287, %10 : i32
    cf.cond_br %338, ^bb23, ^bb24
  ^bb23:  // pred: ^bb22
    cf.br ^bb32(%9 : i8)
  ^bb24:  // pred: ^bb22
    %339 = arith.cmpi uge, %287, %c-2147483648_i32 : i32
    cf.cond_br %339, ^bb25, ^bb26
  ^bb25:  // pred: ^bb24
    cf.br ^bb30(%8 : i8)
  ^bb26:  // pred: ^bb24
    cf.br ^bb27(%7, %6 : i32, i8)
  ^bb27(%340: i32, %341: i8):  // 2 preds: ^bb26, ^bb28
    %342 = arith.cmpi ult, %340, %287 : i32
    cf.cond_br %342, ^bb28(%340, %341 : i32, i8), ^bb29
  ^bb28(%343: i32, %344: i8):  // pred: ^bb27
    %345 = arith.muli %343, %7 : i32
    %346 = arith.addi %344, %6 : i8
    cf.br ^bb27(%345, %346 : i32, i8)
  ^bb29:  // pred: ^bb27
    cf.br ^bb30(%341 : i8)
  ^bb30(%347: i8):  // 2 preds: ^bb25, ^bb29
    cf.br ^bb31
  ^bb31:  // pred: ^bb30
    cf.br ^bb32(%347 : i8)
  ^bb32(%348: i8):  // 2 preds: ^bb23, ^bb31
    cf.br ^bb33
  ^bb33:  // pred: ^bb32
    %349 = arith.extui %348 : i8 to i64
    %350 = arith.extui %287 : i32 to i64
    %351 = arith.shli %5, %349 : i64
    %352 = arith.subi %351, %350 : i64
    %353 = arith.muli %352, %c4294967296_i64 : i64
    %354 = arith.divui %353, %350 : i64
    %355 = arith.addi %354, %5 : i64
    %356 = arith.trunci %355 : i64 to i32
    %357 = arith.cmpi ult, %348, %6 : i8
    %358 = arith.select %357, %348, %6 : i8
    %359 = arith.cmpi ult, %348, %6 : i8
    %360 = arith.subi %348, %6 : i8
    %361 = arith.select %359, %9, %360 : i8
    %362 = cute.fast_divmod.make_divisor(%287, %356, %358, %361) : i32 -> !cute.fast_divmod_divisor<32>
    %int_tuple_34 = cute.make_int_tuple(%itup_32) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
    %sz_35 = cute.size(%int_tuple_34) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
    %e0_36 = cute.get_leaves(%sz_35) : !cute.int_tuple<"?">
    %mul = cute.tuple_mul(%e0_36, %4) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
    %int_tuple_37 = cute.make_int_tuple(%itup_33) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
    %sz_38 = cute.size(%int_tuple_37) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
    %e0_39 = cute.get_leaves(%sz_38) : !cute.int_tuple<"?">
    %mul_40 = cute.tuple_mul(%e0_39, %4) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
    %itup_41 = cute.to_int_tuple(%e2_31) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %int_tuple_42 = cute.make_int_tuple(%mul, %mul_40, %itup_41) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?,?,?)">
    %sz_43 = cute.size(%int_tuple_42) : (!cute.int_tuple<"(?,?,?)">) -> !cute.int_tuple<"?">
    %e0_44 = cute.get_leaves(%sz_43) : !cute.int_tuple<"?">
    %363 = cute.get_scalars(%e0_44) : !cute.int_tuple<"?">
    %364 = arith.cmpi slt, %363, %c1_i32 : i32
    %365 = arith.select %364, %363, %c1_i32 : i32
    %366 = cuda.launch_cfg.create<max_attrs = 2 : i32> (blockDim = (%c160_i32, %c1_i32, %c1_i32), dynamicSmemBytes = %c99328_i64, gridDim = (%c1_i32, %c1_i32, %365), stream = %arg3) : i32, i32, i32, i64, i32, i32, i32, !cuda.stream -> !cuda.launch_cfg<max_attrs = 2>
    cuda.launch_cfg.cluster_dim[%366] (%c1_i32, %c1_i32, %c1_i32) : !cuda.launch_cfg<max_attrs = 2>, i32, i32, i32
    %367 = cuda.launch_ex @kernels::@kernel_cutlass_kernel___main__Sm120GemmKernel_object_at__CopyAtom_ThrID10_TVLayoutSrc1409601_TVLayoutDst1409601_Valuetypef16_tensor000o101112_CopyAtom_ThrID10_TVLayoutSrc1409601_TVLayoutD_0<%366> (%99, %view, %171, %view_4, %243, %view_9, %280, %281, %282, %312, %337, %362) : !cuda.launch_cfg<max_attrs = 2>, (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 65536, tma_gbasis = <"(64,64,1):(1@0,1@1,1@2)">, internal_val_type = f16>, !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">, !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 65536, tma_gbasis = <"(64,64,1):(1@0,1@1,1@2)">, internal_val_type = f16>, !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">, !cute_nvgpu.atom.non_exec_tiled_tma_store<f16, copy_bits = 32768, tma_gbasis = <"(64,32,1):(1@0,1@1,1@2)">, internal_val_type = f16>, !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">, i32, i32, i32, !cute.fast_divmod_divisor<32>, !cute.fast_divmod_divisor<32>, !cute.fast_divmod_divisor<32>) -> !cuda.result
    %368 = cuda.cast %367 : !cuda.result -> i32
    cuda.return_if_error %368 : i32
    return %c0_i32 : i32
  }
}
