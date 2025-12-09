!copy_simt = !cute.tiled_copy<!cute_nvgpu.atom.universal_copy<f32>, layout_copy_tv = <"((32,4),(16,1)):((4,1),(128,0))">, tiler_mn = <"[(4,32):(32,1);16:1]">>
!memref_gmem_f32_ = !cute.memref<f32, gmem, align<16>, "(?,?,?):(?{i64},1,?{i64})">
!memref_gmem_tf32_ = !cute.memref<tf32, gmem, align<16>, "(?,?,?):(?{i64},1,?{i64})">
!memref_rmem_f32_ = !cute.memref<f32, rmem, align<32>, "((16,1),1,1):((1,0),0,0)">
!memref_rmem_f32_1 = !cute.memref<f32, rmem, align<32>, "((1,16),1,1):((0,1),0,0)">
!mma_tf32_tf32_f32_128x128x8_ = !cute.tiled_mma<!cute_nvgpu.sm100.mma<128x128x8, num_cta = 1, ab_major = (k, k), elem_type = (tf32, tf32, f32), frag_kind = ss, c_scale_exp = 0>, atom_layout_MNK = <"(1,1,1):(0,0,0)">>
#loop_unroll = #llvm.loop_unroll<disable = false, full = true>
#loop_unroll1 = #llvm.loop_unroll<disable = true, count = 1 : i32>
#loop_unroll2 = #llvm.loop_unroll<full = true>
#loop_annotation = #llvm.loop_annotation<unroll = #loop_unroll>
#loop_annotation1 = #llvm.loop_annotation<unroll = #loop_unroll1>
#loop_annotation2 = #llvm.loop_annotation<unroll = #loop_unroll2>
module attributes {gpu.container_module} {
  gpu.module @kernels {
    cuda.kernel @kernel_cutlass_kernel___main__SM100PersistentDenseGemmAlphaBetaKernel_object_at__TiledMMA_ThrLayoutVMNK11110000_PermutationMNK____MMAAtom_ThrID10_ShapeMNK1281288_TVLayoutA112881281128_TVL_0(%arg0: !mma_tf32_tf32_f32_128x128x8_, %arg1: !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, tf32, copy_bits = 131072, tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">, internal_val_type = tf32>, %arg2: !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">, %arg3: !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, tf32, copy_bits = 131072, tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">, internal_val_type = tf32>, %arg4: !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">, %arg5: !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f32, copy_bits = 65536, tma_gbasis = <"(16,128,1):(1@1,1@0,1@2)">, internal_val_type = f32>, %arg6: !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">, %arg7: !cute_nvgpu.atom.non_exec_tiled_tma_store<f32, copy_bits = 65536, tma_gbasis = <"(16,128,1):(1@1,1@0,1@2)">, internal_val_type = f32>, %arg8: !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">, %arg9: i32, %arg10: i32, %arg11: i32, %arg12: !cute.fast_divmod_divisor<32>, %arg13: !cute.fast_divmod_divisor<32>, %arg14: !cute.fast_divmod_divisor<32>, %arg15: f32, %arg16: f32) attributes {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 224, 1, 1>} {
      %c8192_i32 = arith.constant 8192 : i32
      %0 = cute.static : !cute.layout<"(((16,128),1),(1,8)):(((1@0,1@1),0),(0,16@0))">
      %1 = cute.static : !cute.layout<"((2048,1),(1,2)):((1,0),(0,2048))">
      %2 = cute.static : !cute.int_tuple<"12">
      %3 = cute.static : !cute.int_tuple<"8">
      %4 = cute.static : !cute.layout<"((1,16),1,1,(1,2)):((0,1),0,0,(0,2048))">
      %5 = cute.static : !cute.layout<"(((16,32),1),1,1,(1,8)):(((1,65536),0),0,0,(0,16))">
      %c8_i32 = arith.constant 8 : i32
      %6 = cute.static : !cute.layout<"(((16,32),1),1,1,1,8,2):(((1,65536),0),0,0,0,16,128)">
      %7 = cute.static : !cute.stride<"(((1@0,1@1),0),0,16@0,128@1,128@0,1@2)">
      %8 = cute.static : !cute.stride<"((1@1,1@0),0,16@0,128@1,128@0,1@2)">
      %9 = cute.static : !cute.stride<"(1@1,1@0,0,16@0,128@1,128@0,1@2)">
      %c512_i32 = arith.constant 512 : i32
      %c16_i32 = arith.constant 16 : i32
      %c2097152_i32 = arith.constant 2097152 : i32
      %c256_i32 = arith.constant 256 : i32
      %c2_i32 = arith.constant 2 : i32
      %c14_i32 = arith.constant 14 : i32
      %c13_i32 = arith.constant 13 : i32
      %c136317200_i32 = arith.constant 136317200 : i32
      %10 = cute.static : !cute.layout<"(1,1,4,6):(0,0,2,1024)">
      %11 = cute.static : !cute.layout<"((128,128),1,1,2):((65536,1),0,0,128)">
      %c160_i32 = arith.constant 160 : i32
      %c3_i32 = arith.constant 3 : i32
      %c6_i32 = arith.constant 6 : i32
      %12 = cute.static : !cute.layout<"((4096,1),6):((1,0),4096)">
      %c32768_i32 = arith.constant 32768 : i32
      %c10000000_i32 = arith.constant 10000000 : i32
      %13 = cute.static : !cute.stride<"(((1@0,1@1),0),32@0)">
      %c224_i32 = arith.constant 224 : i32
      %14 = cute.static : !cute.stride<"(((1@0,1@1),0),128@1,32@0,1@2)">
      %15 = cute.static : !cute.stride<"(((1@1,1@0),0,8@0),128@1,32@0,1@2)">
      %16 = cute.static : !cute.stride<"((1@1,1@0),0,0,128@1,128@0,1@2)">
      %17 = cute.static : !cute.stride<"((1@1,1@0),0,8@0,128@1,32@0,1@2)">
      %18 = cute.static : !cute.stride<"(1@1,1@0,128@1,128@0,1@2)">
      %19 = cute.static : !cute.stride<"((1@1,1@0),(128@1,128@0,1@2))">
      %20 = cute.static : !cute.int_tuple<"(0,0,0)">
      %21 = cute.static : !cute.stride<"(1@1,1@0,128@1,32@0,1@2)">
      %22 = cute.static : !cute.stride<"((1@1,1@0),(128@1,32@0,1@2))">
      %c128_i32 = arith.constant 128 : i32
      %true = arith.constant true
      %false = arith.constant false
      %c4_i32 = arith.constant 4 : i32
      %23 = cute.static : !cute.int_tuple<"6">
      %24 = cute.static : !cute.int_tuple<"5">
      %25 = cute.static : !cute.int_tuple<"4">
      %26 = cute.static : !cute.int_tuple<"3">
      %27 = cute.static : !cute.int_tuple<"2">
      %28 = cute.static : !cute.int_tuple<"1">
      %29 = cute.static : !cute.int_tuple<"132096">
      %30 = cute.static : !cute.int_tuple<"33792">
      %31 = cute.static : !cute.int_tuple<"17408">
      %32 = cute.static : !cute.int_tuple<"1024">
      %33 = cute.static : !cute.int_tuple<"168">
      %34 = cute.static : !cute.int_tuple<"128">
      %35 = cute.static : !cute.int_tuple<"96">
      %c0_i32 = arith.constant 0 : i32
      %c1_i32 = arith.constant 1 : i32
      %c5_i32 = arith.constant 5 : i32
      %c32_i32 = arith.constant 32 : i32
      %int_tuple = cute.make_int_tuple(%arg9, %arg10, %arg11) : (i32, i32, i32) -> !cute.int_tuple<"(?,?,?)">
      %36:3 = cute.get_scalars(%int_tuple) <{only_dynamic}> : !cute.int_tuple<"(?,?,?)">
      %int_tuple_0 = cute.make_int_tuple(%36#0, %36#1, %36#2) : (i32, i32, i32) -> !cute.int_tuple<"(?,?,?)">
      %e0, %e1, %e2 = cute.get_leaves(%int_tuple_0) : !cute.int_tuple<"(?,?,?)">
      %shape = cute.make_shape(%e0, %e1, %e2) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.shape<"(?,?,?)">
      %lay = cute.make_layout(%shape) : !cute.layout<"(?,?,?):(1,?,?)">
      %37 = nvvm.read.ptx.sreg.tid.x range <i32, 0, 1024> : i32
      %38 = nvvm.read.ptx.sreg.tid.y range <i32, 0, 1024> : i32
      %39 = nvvm.read.ptx.sreg.tid.z range <i32, 0, 64> : i32
      %40 = nvvm.read.ptx.sreg.ntid.x range <i32, 1, 1024> : i32
      %41 = nvvm.read.ptx.sreg.ntid.y range <i32, 1, 1024> : i32
      %42 = arith.muli %38, %40 : i32
      %43 = arith.addi %37, %42 : i32
      %44 = arith.muli %39, %40 : i32
      %45 = arith.muli %44, %41 : i32
      %46 = arith.addi %43, %45 : i32
      %47 = arith.floordivsi %46, %c32_i32 : i32
      %48 = cute_nvgpu.arch.make_warp_uniform(%47) : i32
      %49 = arith.cmpi eq, %48, %c5_i32 : i32
      scf.if %49 {
        cute_nvgpu.prefetch_tma_desc(%arg1) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, tf32, copy_bits = 131072, tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">, internal_val_type = tf32>) -> ()
        cute_nvgpu.prefetch_tma_desc(%arg3) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, tf32, copy_bits = 131072, tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">, internal_val_type = tf32>) -> ()
        cute_nvgpu.prefetch_tma_desc(%arg5) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f32, copy_bits = 65536, tma_gbasis = <"(16,128,1):(1@1,1@0,1@2)">, internal_val_type = f32>) -> ()
        cute_nvgpu.prefetch_tma_desc(%arg7) : (!cute_nvgpu.atom.non_exec_tiled_tma_store<f32, copy_bits = 65536, tma_gbasis = <"(16,128,1):(1@1,1@0,1@2)">, internal_val_type = f32>) -> ()
      }
      %smem_ptr = cute_nvgpu.arch.get_dyn_smem() : !cute.ptr<i8, smem, align<1024>>
      %ptr = cute.add_offset(%smem_ptr, %35) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"96">) -> !cute.ptr<i8, smem, align<32>>
      %ptr_1 = cute.add_offset(%smem_ptr, %34) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"128">) -> !cute.ptr<i8, smem, align<128>>
      %ptr_2 = cute.add_offset(%smem_ptr, %33) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"168">) -> !cute.ptr<i8, smem, align<8>>
      %iter = cute.recast_iter(%ptr_2) : !cute.ptr<i8, smem, align<8>> to !cute.ptr<i32, smem, align<8>>
      %ptr_3 = cute.add_offset(%smem_ptr, %32) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"1024">) -> !cute.ptr<i8, smem, align<1024>>
      %ptr_4 = cute.add_offset(%smem_ptr, %31) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"17408">) -> !cute.ptr<i8, smem, align<1024>>
      %ptr_5 = cute.add_offset(%smem_ptr, %30) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"33792">) -> !cute.ptr<i8, smem, align<1024>>
      %ptr_6 = cute.add_offset(%smem_ptr, %29) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"132096">) -> !cute.ptr<i8, smem, align<1024>>
      %iter_7 = cute.recast_iter(%smem_ptr) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<i64, smem, align<1024>>
      %50 = arith.cmpi eq, %48, %c0_i32 : i32
      scf.if %50 {
        %84 = builtin.unrealized_conversion_cast %iter_7 : !cute.ptr<i64, smem, align<1024>> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %84, %c1_i32 : !llvm.ptr<3>, i32
        %ptr_55 = cute.add_offset(%iter_7, %28) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"1">) -> !cute.ptr<i64, smem>
        %85 = builtin.unrealized_conversion_cast %ptr_55 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %85, %c1_i32 : !llvm.ptr<3>, i32
        %ptr_56 = cute.add_offset(%iter_7, %27) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"2">) -> !cute.ptr<i64, smem, align<16>>
        %86 = builtin.unrealized_conversion_cast %ptr_56 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %86, %c1_i32 : !llvm.ptr<3>, i32
        %ptr_57 = cute.add_offset(%iter_7, %26) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"3">) -> !cute.ptr<i64, smem>
        %87 = builtin.unrealized_conversion_cast %ptr_57 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %87, %c1_i32 : !llvm.ptr<3>, i32
        %ptr_58 = cute.add_offset(%iter_7, %25) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"4">) -> !cute.ptr<i64, smem, align<32>>
        %88 = builtin.unrealized_conversion_cast %ptr_58 : !cute.ptr<i64, smem, align<32>> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %88, %c1_i32 : !llvm.ptr<3>, i32
        %ptr_59 = cute.add_offset(%iter_7, %24) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"5">) -> !cute.ptr<i64, smem>
        %89 = builtin.unrealized_conversion_cast %ptr_59 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %89, %c1_i32 : !llvm.ptr<3>, i32
      }
      %ptr_8 = cute.add_offset(%iter_7, %23) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"6">) -> !cute.ptr<i64, smem, align<16>>
      scf.if %50 {
        %84 = builtin.unrealized_conversion_cast %ptr_8 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %84, %c1_i32 : !llvm.ptr<3>, i32
        %int_tuple_55 = cute.make_int_tuple() : () -> !cute.int_tuple<"7">
        %ptr_56 = cute.add_offset(%iter_7, %int_tuple_55) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"7">) -> !cute.ptr<i64, smem>
        %85 = builtin.unrealized_conversion_cast %ptr_56 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %85, %c1_i32 : !llvm.ptr<3>, i32
        %int_tuple_57 = cute.make_int_tuple() : () -> !cute.int_tuple<"8">
        %ptr_58 = cute.add_offset(%iter_7, %int_tuple_57) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"8">) -> !cute.ptr<i64, smem, align<64>>
        %dyn = cute.derefine(%ptr_58) : !cute.ptr<i64, smem, align<64>> to !cute.ptr<i64, smem, align<16>>
        %86 = builtin.unrealized_conversion_cast %dyn : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %86, %c1_i32 : !llvm.ptr<3>, i32
        %int_tuple_59 = cute.make_int_tuple() : () -> !cute.int_tuple<"9">
        %ptr_60 = cute.add_offset(%iter_7, %int_tuple_59) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"9">) -> !cute.ptr<i64, smem>
        %87 = builtin.unrealized_conversion_cast %ptr_60 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %87, %c1_i32 : !llvm.ptr<3>, i32
        %int_tuple_61 = cute.make_int_tuple() : () -> !cute.int_tuple<"10">
        %ptr_62 = cute.add_offset(%iter_7, %int_tuple_61) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"10">) -> !cute.ptr<i64, smem, align<16>>
        %88 = builtin.unrealized_conversion_cast %ptr_62 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %88, %c1_i32 : !llvm.ptr<3>, i32
        %int_tuple_63 = cute.make_int_tuple() : () -> !cute.int_tuple<"11">
        %ptr_64 = cute.add_offset(%iter_7, %int_tuple_63) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"11">) -> !cute.ptr<i64, smem>
        %89 = builtin.unrealized_conversion_cast %ptr_64 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %89, %c1_i32 : !llvm.ptr<3>, i32
      }
      nvvm.fence.mbarrier.init
      nvvm.barrier
      %iter_9 = cute.recast_iter(%ptr) : !cute.ptr<i8, smem, align<32>> to !cute.ptr<i64, smem, align<32>>
      scf.if %50 {
        %84 = builtin.unrealized_conversion_cast %iter_9 : !cute.ptr<i64, smem, align<32>> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %84, %c1_i32 : !llvm.ptr<3>, i32
        %ptr_55 = cute.add_offset(%iter_9, %28) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i64, smem>
        %85 = builtin.unrealized_conversion_cast %ptr_55 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %85, %c1_i32 : !llvm.ptr<3>, i32
      }
      %ptr_10 = cute.add_offset(%iter_9, %27) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i64, smem, align<16>>
      scf.if %50 {
        %84 = builtin.unrealized_conversion_cast %ptr_10 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %84, %c4_i32 : !llvm.ptr<3>, i32
        %int_tuple_55 = cute.make_int_tuple() : () -> !cute.int_tuple<"3">
        %ptr_56 = cute.add_offset(%iter_9, %int_tuple_55) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i64, smem>
        %85 = builtin.unrealized_conversion_cast %ptr_56 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %85, %c4_i32 : !llvm.ptr<3>, i32
      }
      nvvm.fence.mbarrier.init
      nvvm.barrier
      %iter_11 = cute.recast_iter(%ptr_1) : !cute.ptr<i8, smem, align<128>> to !cute.ptr<i64, smem, align<128>>
      scf.if %50 {
        %84 = builtin.unrealized_conversion_cast %iter_11 : !cute.ptr<i64, smem, align<128>> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %84, %c1_i32 : !llvm.ptr<3>, i32
        %ptr_55 = cute.add_offset(%iter_11, %28) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"1">) -> !cute.ptr<i64, smem>
        %85 = builtin.unrealized_conversion_cast %ptr_55 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %85, %c1_i32 : !llvm.ptr<3>, i32
      }
      %ptr_12 = cute.add_offset(%iter_11, %27) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"2">) -> !cute.ptr<i64, smem, align<16>>
      scf.if %50 {
        %84 = builtin.unrealized_conversion_cast %ptr_12 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %84, %c4_i32 : !llvm.ptr<3>, i32
        %int_tuple_55 = cute.make_int_tuple() : () -> !cute.int_tuple<"3">
        %ptr_56 = cute.add_offset(%iter_11, %int_tuple_55) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"3">) -> !cute.ptr<i64, smem>
        %85 = builtin.unrealized_conversion_cast %ptr_56 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %85, %c4_i32 : !llvm.ptr<3>, i32
      }
      %51 = arith.remsi %37, %c32_i32 : i32
      %52 = arith.cmpi slt, %51, %c1_i32 : i32
      %53 = arith.extui %52 : i1 to i32
      %54 = arith.select %52, %c1_i32, %53 : i32
      %55 = arith.cmpi ne, %54, %c0_i32 : i32
      nvvm.fence.mbarrier.init
      nvvm.barrier
      %iter_13 = cute.recast_iter(%ptr_4) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<f32, smem, align<1024>, S<2,4,3>>
      %iter_14 = cute.recast_iter(%ptr_3) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<f32, smem, align<1024>, S<2,4,3>>
      %iter_15 = cute.recast_iter(%ptr_5) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<tf32, smem, align<1024>, S<3,4,3>>
      %iter_16 = cute.recast_iter(%ptr_6) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<tf32, smem, align<1024>, S<3,4,3>>
      %lay_17 = cute.get_layout(%arg2) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">
      %56:3 = cute.get_scalars(%lay_17) <{only_dynamic}> : !cute.layout<"(?,?,?):(1@1,1@0,1@2)">
      %57 = arith.ceildivsi %56#0, %c128_i32 : i32
      %58 = arith.ceildivsi %56#1, %c32_i32 : i32
      %shape_18 = cute.make_shape(%57, %58, %56#2) : (i32, i32, i32) -> !cute.shape<"((128,32),(?,?,?))">
      %lay_19 = cute.make_layout(%shape_18, %22) : !cute.layout<"((128,32),(?,?,?)):((1@1,1@0),(128@1,32@0,1@2))">
      %59:3 = cute.get_scalars(%lay_19) <{only_dynamic}> : !cute.layout<"((128,32),(?,?,?)):((1@1,1@0),(128@1,32@0,1@2))">
      %shape_20 = cute.make_shape(%59#0, %59#1, %59#2) : (i32, i32, i32) -> !cute.shape<"(128,32,?,?,?)">
      %lay_21 = cute.make_layout(%shape_20, %21) : !cute.layout<"(128,32,?,?,?):(1@1,1@0,128@1,32@0,1@2)">
      %lay_22 = cute.get_layout(%arg4) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">
      %60:3 = cute.get_scalars(%lay_22) <{only_dynamic}> : !cute.layout<"(?,?,?):(1@1,1@0,1@2)">
      %61 = arith.ceildivsi %60#0, %c128_i32 : i32
      %62 = arith.ceildivsi %60#1, %c32_i32 : i32
      %shape_23 = cute.make_shape(%61, %62, %60#2) : (i32, i32, i32) -> !cute.shape<"((128,32),(?,?,?))">
      %lay_24 = cute.make_layout(%shape_23, %22) : !cute.layout<"((128,32),(?,?,?)):((1@1,1@0),(128@1,32@0,1@2))">
      %63:3 = cute.get_scalars(%lay_24) <{only_dynamic}> : !cute.layout<"((128,32),(?,?,?)):((1@1,1@0),(128@1,32@0,1@2))">
      %shape_25 = cute.make_shape(%63#0, %63#1, %63#2) : (i32, i32, i32) -> !cute.shape<"(128,32,?,?,?)">
      %lay_26 = cute.make_layout(%shape_25, %21) : !cute.layout<"(128,32,?,?,?):(1@1,1@0,128@1,32@0,1@2)">
      %lay_27 = cute.get_layout(%arg6) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">
      %64:3 = cute.get_scalars(%lay_27) <{only_dynamic}> : !cute.layout<"(?,?,?):(1@1,1@0,1@2)">
      %65 = arith.ceildivsi %64#0, %c128_i32 : i32
      %66 = arith.ceildivsi %64#1, %c128_i32 : i32
      %shape_28 = cute.make_shape(%65, %66, %64#2) : (i32, i32, i32) -> !cute.shape<"((128,128),(?,?,?))">
      %lay_29 = cute.make_layout(%shape_28, %19) : !cute.layout<"((128,128),(?,?,?)):((1@1,1@0),(128@1,128@0,1@2))">
      %67:3 = cute.get_scalars(%lay_29) <{only_dynamic}> : !cute.layout<"((128,128),(?,?,?)):((1@1,1@0),(128@1,128@0,1@2))">
      %shape_30 = cute.make_shape(%67#0, %67#1, %67#2) : (i32, i32, i32) -> !cute.shape<"(128,128,?,?,?)">
      %lay_31 = cute.make_layout(%shape_30, %18) : !cute.layout<"(128,128,?,?,?):(1@1,1@0,128@1,128@0,1@2)">
      %lay_32 = cute.get_layout(%arg8) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">
      %68:3 = cute.get_scalars(%lay_32) <{only_dynamic}> : !cute.layout<"(?,?,?):(1@1,1@0,1@2)">
      %69 = arith.ceildivsi %68#0, %c128_i32 : i32
      %70 = arith.ceildivsi %68#1, %c128_i32 : i32
      %shape_33 = cute.make_shape(%69, %70, %68#2) : (i32, i32, i32) -> !cute.shape<"((128,128),(?,?,?))">
      %lay_34 = cute.make_layout(%shape_33, %19) : !cute.layout<"((128,128),(?,?,?)):((1@1,1@0),(128@1,128@0,1@2))">
      %71:3 = cute.get_scalars(%lay_34) <{only_dynamic}> : !cute.layout<"((128,128),(?,?,?)):((1@1,1@0),(128@1,128@0,1@2))">
      %shape_35 = cute.make_shape(%71#0, %71#1, %71#2) : (i32, i32, i32) -> !cute.shape<"(128,128,?,?,?)">
      %lay_36 = cute.make_layout(%shape_35, %18) : !cute.layout<"(128,128,?,?,?):(1@1,1@0,128@1,128@0,1@2)">
      %sz = cute.size(%lay_21) <{mode = [3]}> : (!cute.layout<"(128,32,?,?,?):(1@1,1@0,128@1,32@0,1@2)">) -> !cute.int_tuple<"?">
      %e0_37 = cute.get_leaves(%sz) : !cute.int_tuple<"?">
      %72 = cute.get_scalars(%e0_37) : !cute.int_tuple<"?">
      %73:3 = cute.get_scalars(%lay_21) <{only_dynamic}> : !cute.layout<"(128,32,?,?,?):(1@1,1@0,128@1,32@0,1@2)">
      %shape_38 = cute.make_shape(%73#0, %73#1, %73#2) : (i32, i32, i32) -> !cute.shape<"((128,8),1,4,?,?,?)">
      %lay_39 = cute.make_layout(%shape_38, %17) : !cute.layout<"((128,8),1,4,?,?,?):((1@1,1@0),0,8@0,128@1,32@0,1@2)">
      %74:3 = cute.get_scalars(%lay_26) <{only_dynamic}> : !cute.layout<"(128,32,?,?,?):(1@1,1@0,128@1,32@0,1@2)">
      %shape_40 = cute.make_shape(%74#0, %74#1, %74#2) : (i32, i32, i32) -> !cute.shape<"((128,8),1,4,?,?,?)">
      %lay_41 = cute.make_layout(%shape_40, %17) : !cute.layout<"((128,8),1,4,?,?,?):((1@1,1@0),0,8@0,128@1,32@0,1@2)">
      %75:3 = cute.get_scalars(%lay_31) <{only_dynamic}> : !cute.layout<"(128,128,?,?,?):(1@1,1@0,128@1,128@0,1@2)">
      %shape_42 = cute.make_shape(%75#0, %75#1, %75#2) : (i32, i32, i32) -> !cute.shape<"((128,128),1,1,?,?,?)">
      %lay_43 = cute.make_layout(%shape_42, %16) : !cute.layout<"((128,128),1,1,?,?,?):((1@1,1@0),0,0,128@1,128@0,1@2)">
      %76:3 = cute.get_scalars(%lay_36) <{only_dynamic}> : !cute.layout<"(128,128,?,?,?):(1@1,1@0,128@1,128@0,1@2)">
      %shape_44 = cute.make_shape(%76#0, %76#1, %76#2) : (i32, i32, i32) -> !cute.shape<"((128,128),1,1,?,?,?)">
      %lay_45 = cute.make_layout(%shape_44, %16) : !cute.layout<"((128,128),1,1,?,?,?):((1@1,1@0),0,0,128@1,128@0,1@2)">
      %77:3 = cute.get_scalars(%lay_39) <{only_dynamic}> : !cute.layout<"((128,8),1,4,?,?,?):((1@1,1@0),0,8@0,128@1,32@0,1@2)">
      %shape_46 = cute.make_shape(%77#0, %77#1, %77#2) : (i32, i32, i32) -> !cute.shape<"(((128,8),1,4),?,?,?)">
      %lay_47 = cute.make_layout(%shape_46, %15) : !cute.layout<"(((128,8),1,4),?,?,?):(((1@1,1@0),0,8@0),128@1,32@0,1@2)">
      %78:3 = cute.get_scalars(%lay_47) <{only_dynamic}> : !cute.layout<"(((128,8),1,4),?,?,?):(((1@1,1@0),0,8@0),128@1,32@0,1@2)">
      %shape_48 = cute.make_shape(%78#0, %78#1, %78#2) : (i32, i32, i32) -> !cute.shape<"(((32,128),1),?,?,?)">
      %lay_49 = cute.make_layout(%shape_48, %14) : !cute.layout<"(((32,128),1),?,?,?):(((1@0,1@1),0),128@1,32@0,1@2)">
      %79:3 = cute.get_scalars(%lay_41) <{only_dynamic}> : !cute.layout<"((128,8),1,4,?,?,?):((1@1,1@0),0,8@0,128@1,32@0,1@2)">
      %shape_50 = cute.make_shape(%79#0, %79#1, %79#2) : (i32, i32, i32) -> !cute.shape<"(((128,8),1,4),?,?,?)">
      %lay_51 = cute.make_layout(%shape_50, %15) : !cute.layout<"(((128,8),1,4),?,?,?):(((1@1,1@0),0,8@0),128@1,32@0,1@2)">
      %80:3 = cute.get_scalars(%lay_51) <{only_dynamic}> : !cute.layout<"(((128,8),1,4),?,?,?):(((1@1,1@0),0,8@0),128@1,32@0,1@2)">
      %shape_52 = cute.make_shape(%80#0, %80#1, %80#2) : (i32, i32, i32) -> !cute.shape<"(((32,128),1),?,?,?)">
      %lay_53 = cute.make_layout(%shape_52, %14) : !cute.layout<"(((32,128),1),?,?,?):(((1@0,1@1),0),128@1,32@0,1@2)">
      %ummaSmemDesc = cute_nvgpu.make_umma_smem_desc(%iter_15 : !cute.ptr<tf32, smem, align<1024>, S<3,4,3>>) layout = <"((128,8),1,4,6):((32,1),0,8,4096)">, major = <k> -> !cute_nvgpu.smem_desc
      %ummaSmemDesc_54 = cute_nvgpu.make_umma_smem_desc(%iter_16 : !cute.ptr<tf32, smem, align<1024>, S<3,4,3>>) layout = <"((128,8),1,4,6):((32,1),0,8,4096)">, major = <k> -> !cute_nvgpu.smem_desc
      nvvm.barrier id = %c1_i32 number_of_threads = %c224_i32
      scf.if %49 {
        %84 = nvvm.read.ptx.sreg.ctaid.z range <i32, 0, 65535> : i32
        %85 = nvvm.read.ptx.sreg.nctaid.x range <i32, 1, 2147483647> : i32
        %86 = nvvm.read.ptx.sreg.nctaid.y range <i32, 1, 65535> : i32
        %87 = nvvm.read.ptx.sreg.nctaid.z range <i32, 1, 65535> : i32
        %int_tuple_55 = cute.make_int_tuple(%85, %86, %87) : (i32, i32, i32) -> !cute.int_tuple<"(?,?,?)">
        %sz_56 = cute.size(%int_tuple_55) : (!cute.int_tuple<"(?,?,?)">) -> !cute.int_tuple<"?">
        %e0_57 = cute.get_leaves(%sz_56) : !cute.int_tuple<"?">
        %div = cute.tuple_div(%e0_57, %28) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
        %88 = cute.get_scalars(%div) : !cute.int_tuple<"?">
        %sz_58 = cute.size(%lay) : (!cute.layout<"(?,?,?):(1,?,?)">) -> !cute.int_tuple<"?">
        %e0_59 = cute.get_leaves(%sz_58) : !cute.int_tuple<"?">
        %89 = cute.get_scalars(%e0_59) : !cute.int_tuple<"?">
        %90 = arith.cmpi sgt, %89, %84 : i32
        %91 = cute.fast_divmod.get_divisor(%arg12) : !cute.fast_divmod_divisor<32>
        %multiplier, %shift1, %shift2 = cute.fast_divmod.get_aux(%arg12) : !cute.fast_divmod_divisor<32> -> (i32, i8)
        %92 = arith.extui %shift1 : i8 to i32
        %93 = arith.extui %shift2 : i8 to i32
        %94 = nvvm.mul  hi %84, %multiplier : i32 -> i32
        %95 = arith.subi %84, %94 : i32
        %96 = arith.shrui %95, %92 : i32
        %97 = arith.addi %94, %96 : i32
        %98 = arith.shrui %97, %93 : i32
        %99 = arith.muli %98, %91 : i32
        %100 = arith.subi %84, %99 : i32
        %101 = cute.fast_divmod.get_divisor(%arg13) : !cute.fast_divmod_divisor<32>
        %multiplier_60, %shift1_61, %shift2_62 = cute.fast_divmod.get_aux(%arg13) : !cute.fast_divmod_divisor<32> -> (i32, i8)
        %102 = arith.extui %shift1_61 : i8 to i32
        %103 = arith.extui %shift2_62 : i8 to i32
        %104 = nvvm.mul  hi %100, %multiplier_60 : i32 -> i32
        %105 = arith.subi %100, %104 : i32
        %106 = arith.shrui %105, %102 : i32
        %107 = arith.addi %104, %106 : i32
        %108 = arith.shrui %107, %103 : i32
        %109 = arith.muli %108, %101 : i32
        %110 = arith.subi %100, %109 : i32
        %111 = cute.fast_divmod.get_divisor(%arg14) : !cute.fast_divmod_divisor<32>
        %multiplier_63, %shift1_64, %shift2_65 = cute.fast_divmod.get_aux(%arg14) : !cute.fast_divmod_divisor<32> -> (i32, i8)
        %112 = arith.extui %shift1_64 : i8 to i32
        %113 = arith.extui %shift2_65 : i8 to i32
        %114 = nvvm.mul  hi %108, %multiplier_63 : i32 -> i32
        %115 = arith.subi %108, %114 : i32
        %116 = arith.shrui %115, %112 : i32
        %117 = arith.addi %114, %116 : i32
        %118 = arith.shrui %117, %113 : i32
        %119 = arith.muli %118, %111 : i32
        %120 = arith.subi %108, %119 : i32
        %int_tuple_66 = cute.make_int_tuple(%110) : (i32) -> !cute.int_tuple<"?">
        %mul = cute.tuple_mul(%int_tuple_66, %28) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
        %121 = cute.get_scalars(%mul) : !cute.int_tuple<"?">
        %int_tuple_67 = cute.make_int_tuple(%120) : (i32) -> !cute.int_tuple<"?">
        %mul_68 = cute.tuple_mul(%int_tuple_67, %28) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
        %122 = cute.get_scalars(%mul_68) : !cute.int_tuple<"?">
        %int_tuple_69 = cute.make_int_tuple(%118) : (i32) -> !cute.int_tuple<"?">
        %mul_70 = cute.tuple_mul(%int_tuple_69, %28) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
        %123 = cute.get_scalars(%mul_70) : !cute.int_tuple<"?">
        %124:7 = scf.while (%arg17 = %121, %arg18 = %122, %arg19 = %123, %arg20 = %90, %arg21 = %c0_i32, %arg22 = %c1_i32, %arg23 = %84, %arg24 = %c0_i32) : (i32, i32, i32, i1, i32, i32, i32, i32) -> (i32, i32, i32, i32, i32, i32, i32) {
          scf.condition(%arg20) %arg17, %arg18, %arg19, %arg21, %arg22, %arg23, %arg24 : i32, i32, i32, i32, i32, i32, i32
        } do {
        ^bb0(%arg17: i32, %arg18: i32, %arg19: i32, %arg20: i32, %arg21: i32, %arg22: i32, %arg23: i32):
          %coord = cute.make_coord(%arg17, %arg19) : (i32, i32) -> !cute.coord<"(_,?,_,?)">
          %147:3 = cute.get_scalars(%lay_49) <{only_dynamic}> : !cute.layout<"(((32,128),1),?,?,?):(((1@0,1@1),0),128@1,32@0,1@2)">
          %shape_73 = cute.make_shape(%147#1) : (i32) -> !cute.shape<"(((32,128),1),?)">
          %lay_74 = cute.make_layout(%shape_73, %13) : !cute.layout<"(((32,128),1),?):(((1@0,1@1),0),32@0)">
          %idx = cute.crd2idx(%coord, %lay_49) : (!cute.coord<"(_,?,_,?)">, !cute.layout<"(((32,128),1),?,?,?):(((1@0,1@1),0),128@1,32@0,1@2)">) -> !cute.int_tuple<"(0,?{div=128},?)">
          %tup = cute.add_offset(%20, %idx) : (!cute.int_tuple<"(0,0,0)">, !cute.int_tuple<"(0,?{div=128},?)">) -> !cute.int_tuple<"(0,?{div=128},?)">
          %coord_75 = cute.make_coord(%arg18, %arg19) : (i32, i32) -> !cute.coord<"(_,?,_,?)">
          %148:3 = cute.get_scalars(%lay_53) <{only_dynamic}> : !cute.layout<"(((32,128),1),?,?,?):(((1@0,1@1),0),128@1,32@0,1@2)">
          %shape_76 = cute.make_shape(%148#1) : (i32) -> !cute.shape<"(((32,128),1),?)">
          %lay_77 = cute.make_layout(%shape_76, %13) : !cute.layout<"(((32,128),1),?):(((1@0,1@1),0),32@0)">
          %idx_78 = cute.crd2idx(%coord_75, %lay_53) : (!cute.coord<"(_,?,_,?)">, !cute.layout<"(((32,128),1),?,?,?):(((1@0,1@1),0),128@1,32@0,1@2)">) -> !cute.int_tuple<"(0,?{div=128},?)">
          %tup_79 = cute.add_offset(%20, %idx_78) : (!cute.int_tuple<"(0,0,0)">, !cute.int_tuple<"(0,?{div=128},?)">) -> !cute.int_tuple<"(0,?{div=128},?)">
          %149 = arith.cmpi sgt, %72, %c0_i32 : i32
          %150 = scf.if %149 -> (i1) {
            %int_tuple_86 = cute.make_int_tuple(%arg20) : (i32) -> !cute.int_tuple<"?">
            %ptr_87 = cute.add_offset(%ptr_8, %int_tuple_86) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
            %179 = builtin.unrealized_conversion_cast %ptr_87 : !cute.ptr<i64, smem> to !llvm.ptr<3>
            %180 = nvvm.mbarrier.wait.parity %179, %arg21 {kind = #nvvm.mbar_wait<try>} : !llvm.ptr<3>, i32 -> i1
            scf.yield %180 : i1
          } else {
            scf.yield %true : i1
          }
          %151:4 = scf.for %arg24 = %c0_i32 to %72 step %c1_i32 iter_args(%arg25 = %150, %arg26 = %c0_i32, %arg27 = %arg20, %arg28 = %arg21) -> (i1, i32, i32, i32)  : i32 {
            %179 = arith.extui %arg25 : i1 to i32
            %180 = arith.cmpi eq, %179, %c0_i32 : i32
            scf.if %180 {
              %int_tuple_105 = cute.make_int_tuple(%arg27) : (i32) -> !cute.int_tuple<"?">
              %ptr_106 = cute.add_offset(%ptr_8, %int_tuple_105) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
              %194 = builtin.unrealized_conversion_cast %ptr_106 : !cute.ptr<i64, smem> to !llvm.ptr<3>
              nvvm.mbarrier.try_wait.parity.shared %194, %arg28, %c10000000_i32 : !llvm.ptr<3>, i32, i32
            }
            %181 = nvvm.elect.sync -> i1
            scf.if %181 {
              %int_tuple_105 = cute.make_int_tuple(%arg27) : (i32) -> !cute.int_tuple<"?">
              %ptr_106 = cute.add_offset(%iter_7, %int_tuple_105) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
              %194 = builtin.unrealized_conversion_cast %ptr_106 : !cute.ptr<i64, smem> to !llvm.ptr<3>
              nvvm.mbarrier.txn %194, %c32768_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
            }
            %coord_86 = cute.make_coord(%arg26) : (i32) -> !cute.coord<"(_,?)">
            %idx_87 = cute.crd2idx(%coord_86, %lay_74) : (!cute.coord<"(_,?)">, !cute.layout<"(((32,128),1),?):(((1@0,1@1),0),32@0)">) -> !cute.int_tuple<"(?{div=32},0)">
            %tup_88 = cute.add_offset(%tup, %idx_87) : (!cute.int_tuple<"(0,?{div=128},?)">, !cute.int_tuple<"(?{div=32},0)">) -> !cute.int_tuple<"(?{div=32},?{div=128},?)">
            %e0_89, %e1_90, %e2_91 = cute.get_leaves(%tup_88) : !cute.int_tuple<"(?{div=32},?{div=128},?)">
            %coord_92 = cute.make_coord(%arg27) : (i32) -> !cute.coord<"(_,?)">
            %idx_93 = cute.crd2idx(%coord_92, %12) : (!cute.coord<"(_,?)">, !cute.layout<"((4096,1),6):((1,0),4096)">) -> !cute.int_tuple<"?{div=4096}">
            %ptr_94 = cute.add_offset(%iter_15, %idx_93) : (!cute.ptr<tf32, smem, align<1024>, S<3,4,3>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<tf32, smem, align<1024>, S<3,4,3>>
            %int_tuple_95 = cute.make_int_tuple(%arg27) : (i32) -> !cute.int_tuple<"?">
            %ptr_96 = cute.add_offset(%iter_7, %int_tuple_95) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
            %int_tuple_97 = cute.make_int_tuple(%e0_89, %e1_90, %e2_91) : (!cute.int_tuple<"?{div=32}">, !cute.int_tuple<"?{div=128}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=32},?{div=128},?)">
            %182 = cute_nvgpu.atom.make_exec_tma(%arg1) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, tf32, copy_bits = 131072, tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">, internal_val_type = tf32>) -> !cute_nvgpu.atom.tma_load<tf32, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">>
            %183 = cute_nvgpu.atom.set_value(%182, %ptr_96 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<tf32, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">>
            %184 = cute.get_scalars(%28) : !cute.int_tuple<"1">
            scf.for %arg29 = %c0_i32 to %184 step %c1_i32  : i32 {
              %194 = cute_nvgpu.atom.get_value(%183 : !cute_nvgpu.atom.tma_load<tf32, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
              %195 = cute_nvgpu.atom.get_value(%183 : !cute_nvgpu.atom.tma_load<tf32, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<cache_policy>} : i64
              %TMADescAddr = cute_nvgpu.get_tma_desc_addr(%183 : !cute_nvgpu.atom.tma_load<tf32, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">>) -> !cute.ptr<generic, align<64>>
              %196:3 = cute.get_scalars(%int_tuple_97) : !cute.int_tuple<"(?{div=32},?{div=128},?)">
              cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr : !cute.ptr<generic, align<64>>, %ptr_94 : !cute.ptr<tf32, smem, align<1024>, S<3,4,3>>, %194 : !cute.ptr<smem, align<8>>, [%196#0, %196#1, %196#2] : i32, i32, i32) cache_policy = %195 mode = <tiled> num_cta = 1 : i32
            } {llvm.loop_annotation = #loop_annotation}
            %idx_98 = cute.crd2idx(%coord_86, %lay_77) : (!cute.coord<"(_,?)">, !cute.layout<"(((32,128),1),?):(((1@0,1@1),0),32@0)">) -> !cute.int_tuple<"(?{div=32},0)">
            %tup_99 = cute.add_offset(%tup_79, %idx_98) : (!cute.int_tuple<"(0,?{div=128},?)">, !cute.int_tuple<"(?{div=32},0)">) -> !cute.int_tuple<"(?{div=32},?{div=128},?)">
            %e0_100, %e1_101, %e2_102 = cute.get_leaves(%tup_99) : !cute.int_tuple<"(?{div=32},?{div=128},?)">
            %ptr_103 = cute.add_offset(%iter_16, %idx_93) : (!cute.ptr<tf32, smem, align<1024>, S<3,4,3>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<tf32, smem, align<1024>, S<3,4,3>>
            %int_tuple_104 = cute.make_int_tuple(%e0_100, %e1_101, %e2_102) : (!cute.int_tuple<"?{div=32}">, !cute.int_tuple<"?{div=128}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=32},?{div=128},?)">
            %185 = cute_nvgpu.atom.make_exec_tma(%arg3) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, tf32, copy_bits = 131072, tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">, internal_val_type = tf32>) -> !cute_nvgpu.atom.tma_load<tf32, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">>
            %186 = cute_nvgpu.atom.set_value(%185, %ptr_96 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<tf32, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">>
            scf.for %arg29 = %c0_i32 to %184 step %c1_i32  : i32 {
              %194 = cute_nvgpu.atom.get_value(%186 : !cute_nvgpu.atom.tma_load<tf32, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
              %195 = cute_nvgpu.atom.get_value(%186 : !cute_nvgpu.atom.tma_load<tf32, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<cache_policy>} : i64
              %TMADescAddr = cute_nvgpu.get_tma_desc_addr(%186 : !cute_nvgpu.atom.tma_load<tf32, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">>) -> !cute.ptr<generic, align<64>>
              %196:3 = cute.get_scalars(%int_tuple_104) : !cute.int_tuple<"(?{div=32},?{div=128},?)">
              cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr : !cute.ptr<generic, align<64>>, %ptr_103 : !cute.ptr<tf32, smem, align<1024>, S<3,4,3>>, %194 : !cute.ptr<smem, align<8>>, [%196#0, %196#1, %196#2] : i32, i32, i32) cache_policy = %195 mode = <tiled> num_cta = 1 : i32
            } {llvm.loop_annotation = #loop_annotation}
            %187 = arith.addi %arg27, %c1_i32 : i32
            %188 = arith.addi %arg26, %c1_i32 : i32
            %189 = arith.cmpi eq, %187, %c6_i32 : i32
            %190 = arith.select %189, %c0_i32, %187 : i32
            %191 = scf.if %189 -> (i32) {
              %194 = arith.xori %arg28, %c1_i32 : i32
              scf.yield %194 : i32
            } else {
              scf.yield %arg28 : i32
            }
            %192 = arith.cmpi sgt, %72, %188 : i32
            %193 = scf.if %192 -> (i1) {
              %int_tuple_105 = cute.make_int_tuple(%190) : (i32) -> !cute.int_tuple<"?">
              %ptr_106 = cute.add_offset(%ptr_8, %int_tuple_105) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
              %194 = builtin.unrealized_conversion_cast %ptr_106 : !cute.ptr<i64, smem> to !llvm.ptr<3>
              %195 = nvvm.mbarrier.wait.parity %194, %191 {kind = #nvvm.mbar_wait<try>} : !llvm.ptr<3>, i32 -> i1
              scf.yield %195 : i1
            } else {
              scf.yield %true : i1
            }
            scf.yield %193, %188, %190, %191 : i1, i32, i32, i32
          } {loop_annotation = #loop_annotation1}
          %152 = arith.addi %arg22, %88 : i32
          %153 = arith.addi %arg23, %c1_i32 : i32
          %154 = arith.cmpi sgt, %89, %152 : i32
          %155 = nvvm.mul  hi %152, %multiplier : i32 -> i32
          %156 = arith.subi %152, %155 : i32
          %157 = arith.shrui %156, %92 : i32
          %158 = arith.addi %155, %157 : i32
          %159 = arith.shrui %158, %93 : i32
          %160 = arith.muli %159, %91 : i32
          %161 = arith.subi %152, %160 : i32
          %162 = nvvm.mul  hi %161, %multiplier_60 : i32 -> i32
          %163 = arith.subi %161, %162 : i32
          %164 = arith.shrui %163, %102 : i32
          %165 = arith.addi %162, %164 : i32
          %166 = arith.shrui %165, %103 : i32
          %167 = arith.muli %166, %101 : i32
          %168 = arith.subi %161, %167 : i32
          %169 = nvvm.mul  hi %166, %multiplier_63 : i32 -> i32
          %170 = arith.subi %166, %169 : i32
          %171 = arith.shrui %170, %112 : i32
          %172 = arith.addi %169, %171 : i32
          %173 = arith.shrui %172, %113 : i32
          %174 = arith.muli %173, %111 : i32
          %175 = arith.subi %166, %174 : i32
          %int_tuple_80 = cute.make_int_tuple(%168) : (i32) -> !cute.int_tuple<"?">
          %mul_81 = cute.tuple_mul(%int_tuple_80, %28) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
          %176 = cute.get_scalars(%mul_81) : !cute.int_tuple<"?">
          %int_tuple_82 = cute.make_int_tuple(%175) : (i32) -> !cute.int_tuple<"?">
          %mul_83 = cute.tuple_mul(%int_tuple_82, %28) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
          %177 = cute.get_scalars(%mul_83) : !cute.int_tuple<"?">
          %int_tuple_84 = cute.make_int_tuple(%173) : (i32) -> !cute.int_tuple<"?">
          %mul_85 = cute.tuple_mul(%int_tuple_84, %28) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
          %178 = cute.get_scalars(%mul_85) : !cute.int_tuple<"?">
          scf.yield %176, %177, %178, %154, %151#2, %151#3, %152, %153 : i32, i32, i32, i1, i32, i32, i32, i32
        }
        %125 = arith.addi %124#3, %c1_i32 : i32
        %126 = arith.cmpi eq, %125, %c6_i32 : i32
        %127 = arith.select %126, %c0_i32, %125 : i32
        %128 = scf.if %126 -> (i32) {
          %147 = arith.xori %124#4, %c1_i32 : i32
          scf.yield %147 : i32
        } else {
          scf.yield %124#4 : i32
        }
        %129 = arith.addi %127, %c1_i32 : i32
        %130 = arith.cmpi eq, %129, %c6_i32 : i32
        %131 = arith.select %130, %c0_i32, %129 : i32
        %132 = scf.if %130 -> (i32) {
          %147 = arith.xori %128, %c1_i32 : i32
          scf.yield %147 : i32
        } else {
          scf.yield %128 : i32
        }
        %133 = arith.addi %131, %c1_i32 : i32
        %134 = arith.cmpi eq, %133, %c6_i32 : i32
        %135 = arith.select %134, %c0_i32, %133 : i32
        %136 = scf.if %134 -> (i32) {
          %147 = arith.xori %132, %c1_i32 : i32
          scf.yield %147 : i32
        } else {
          scf.yield %132 : i32
        }
        %137 = arith.addi %135, %c1_i32 : i32
        %138 = arith.cmpi eq, %137, %c6_i32 : i32
        %139 = arith.select %138, %c0_i32, %137 : i32
        %140 = scf.if %138 -> (i32) {
          %147 = arith.xori %136, %c1_i32 : i32
          scf.yield %147 : i32
        } else {
          scf.yield %136 : i32
        }
        %141 = arith.addi %139, %c1_i32 : i32
        %142 = arith.cmpi eq, %141, %c6_i32 : i32
        %143 = arith.select %142, %c0_i32, %141 : i32
        %144 = scf.if %142 -> (i32) {
          %147 = arith.xori %140, %c1_i32 : i32
          scf.yield %147 : i32
        } else {
          scf.yield %140 : i32
        }
        %int_tuple_71 = cute.make_int_tuple(%143) : (i32) -> !cute.int_tuple<"?">
        %ptr_72 = cute.add_offset(%ptr_8, %int_tuple_71) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
        %145 = builtin.unrealized_conversion_cast %ptr_72 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        nvvm.mbarrier.try_wait.parity.shared %145, %144, %c10000000_i32 : !llvm.ptr<3>, i32, i32
        %146 = nvvm.elect.sync -> i1
        scf.if %146 {
          %ptr_73 = cute.add_offset(%iter_7, %int_tuple_71) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
          %147 = builtin.unrealized_conversion_cast %ptr_73 : !cute.ptr<i64, smem> to !llvm.ptr<3>
          nvvm.mbarrier.txn %147, %c32768_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
        }
      }
      %81 = arith.cmpi eq, %48, %c4_i32 : i32
      scf.if %81 {
        nvvm.barrier id = %c3_i32 number_of_threads = %c160_i32
        %tmem_ptr = cute_nvgpu.arch.sm100.retrieve_tmem_ptr(%iter) : !cute.ptr<i32, smem, align<8>> -> !cute.ptr<f32, tmem, align<16>>
        %84 = nvvm.read.ptx.sreg.ctaid.z range <i32, 0, 65535> : i32
        %85 = nvvm.read.ptx.sreg.nctaid.x range <i32, 1, 2147483647> : i32
        %86 = nvvm.read.ptx.sreg.nctaid.y range <i32, 1, 65535> : i32
        %87 = nvvm.read.ptx.sreg.nctaid.z range <i32, 1, 65535> : i32
        %int_tuple_55 = cute.make_int_tuple(%85, %86, %87) : (i32, i32, i32) -> !cute.int_tuple<"(?,?,?)">
        %sz_56 = cute.size(%int_tuple_55) : (!cute.int_tuple<"(?,?,?)">) -> !cute.int_tuple<"?">
        %e0_57 = cute.get_leaves(%sz_56) : !cute.int_tuple<"?">
        %div = cute.tuple_div(%e0_57, %28) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
        %88 = cute.get_scalars(%div) : !cute.int_tuple<"?">
        %sz_58 = cute.size(%lay) : (!cute.layout<"(?,?,?):(1,?,?)">) -> !cute.int_tuple<"?">
        %e0_59 = cute.get_leaves(%sz_58) : !cute.int_tuple<"?">
        %89 = cute.get_scalars(%e0_59) : !cute.int_tuple<"?">
        %90 = arith.cmpi sgt, %89, %84 : i32
        %91 = cute.fast_divmod.get_divisor(%arg12) : !cute.fast_divmod_divisor<32>
        %multiplier, %shift1, %shift2 = cute.fast_divmod.get_aux(%arg12) : !cute.fast_divmod_divisor<32> -> (i32, i8)
        %92 = arith.extui %shift1 : i8 to i32
        %93 = arith.extui %shift2 : i8 to i32
        %94 = nvvm.mul  hi %84, %multiplier : i32 -> i32
        %95 = arith.subi %84, %94 : i32
        %96 = arith.shrui %95, %92 : i32
        %97 = arith.addi %94, %96 : i32
        %98 = arith.shrui %97, %93 : i32
        %99 = arith.muli %98, %91 : i32
        %100 = arith.subi %84, %99 : i32
        %multiplier_60, %shift1_61, %shift2_62 = cute.fast_divmod.get_aux(%arg13) : !cute.fast_divmod_divisor<32> -> (i32, i8)
        %101 = arith.extui %shift1_61 : i8 to i32
        %102 = arith.extui %shift2_62 : i8 to i32
        %103 = nvvm.mul  hi %100, %multiplier_60 : i32 -> i32
        %104 = arith.subi %100, %103 : i32
        %105 = arith.shrui %104, %101 : i32
        %106 = arith.addi %103, %105 : i32
        %107 = arith.shrui %106, %102 : i32
        %multiplier_63, %shift1_64, %shift2_65 = cute.fast_divmod.get_aux(%arg14) : !cute.fast_divmod_divisor<32> -> (i32, i8)
        %108 = nvvm.mul  hi %107, %multiplier_63 : i32 -> i32
        %109:8 = scf.while (%arg17 = %90, %arg18 = %c0_i32, %arg19 = %c0_i32, %arg20 = %arg0, %arg21 = %c0_i32, %arg22 = %c0_i32, %arg23 = %c1_i32, %arg24 = %84, %arg25 = %c0_i32) : (i1, i32, i32, !mma_tf32_tf32_f32_128x128x8_, i32, i32, i32, i32, i32) -> (i32, i32, !mma_tf32_tf32_f32_128x128x8_, i32, i32, i32, i32, i32) {
          scf.condition(%arg17) %arg18, %arg19, %arg20, %arg21, %arg22, %arg23, %arg24, %arg25 : i32, i32, !mma_tf32_tf32_f32_128x128x8_, i32, i32, i32, i32, i32
        } do {
        ^bb0(%arg17: i32, %arg18: i32, %arg19: !mma_tf32_tf32_f32_128x128x8_, %arg20: i32, %arg21: i32, %arg22: i32, %arg23: i32, %arg24: i32):
          %coord = cute.make_coord(%arg21) : (i32) -> !cute.coord<"(_,_,_,?)">
          %idx = cute.crd2idx(%coord, %11) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((128,128),1,1,2):((65536,1),0,0,128)">) -> !cute.int_tuple<"?{div=128}">
          %ptr_66 = cute.add_offset(%tmem_ptr, %idx) : (!cute.ptr<f32, tmem, align<16>>, !cute.int_tuple<"?{div=128}">) -> !cute.ptr<f32, tmem, align<16>>
          %114 = arith.cmpi sgt, %72, %c0_i32 : i32
          %115 = arith.extui %114 : i1 to i32
          %116 = arith.select %114, %c1_i32, %115 : i32
          %117 = arith.cmpi ne, %116, %c0_i32 : i32
          %118 = scf.if %117 -> (i1) {
            %int_tuple_69 = cute.make_int_tuple(%arg17) : (i32) -> !cute.int_tuple<"?">
            %ptr_70 = cute.add_offset(%iter_7, %int_tuple_69) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
            %144 = builtin.unrealized_conversion_cast %ptr_70 : !cute.ptr<i64, smem> to !llvm.ptr<3>
            %145 = nvvm.mbarrier.wait.parity %144, %arg18 {kind = #nvvm.mbar_wait<try>} : !llvm.ptr<3>, i32 -> i1
            scf.yield %145 : i1
          } else {
            scf.yield %true : i1
          }
          %int_tuple_67 = cute.make_int_tuple(%arg21) : (i32) -> !cute.int_tuple<"?">
          %ptr_68 = cute.add_offset(%ptr_10, %int_tuple_67) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
          %119 = builtin.unrealized_conversion_cast %ptr_68 : !cute.ptr<i64, smem> to !llvm.ptr<3>
          nvvm.mbarrier.try_wait.parity.shared %119, %arg22, %c10000000_i32 : !llvm.ptr<3>, i32, i32
          %120 = cute_nvgpu.atom.set_value(%arg19, %false : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_tf32_tf32_f32_128x128x8_
          %121:5 = scf.for %arg25 = %c0_i32 to %72 step %c1_i32 iter_args(%arg26 = %118, %arg27 = %120, %arg28 = %c0_i32, %arg29 = %arg17, %arg30 = %arg18) -> (i1, !mma_tf32_tf32_f32_128x128x8_, i32, i32, i32)  : i32 {
            %144 = arith.extui %arg26 : i1 to i32
            %145 = arith.cmpi eq, %144, %c0_i32 : i32
            scf.if %145 {
              %int_tuple_69 = cute.make_int_tuple(%arg29) : (i32) -> !cute.int_tuple<"?">
              %ptr_70 = cute.add_offset(%iter_7, %int_tuple_69) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
              %155 = builtin.unrealized_conversion_cast %ptr_70 : !cute.ptr<i64, smem> to !llvm.ptr<3>
              nvvm.mbarrier.try_wait.parity.shared %155, %arg30, %c10000000_i32 : !llvm.ptr<3>, i32, i32
            }
            %146 = scf.for %arg31 = %c0_i32 to %c4_i32 step %c1_i32 iter_args(%arg32 = %arg27) -> (!mma_tf32_tf32_f32_128x128x8_)  : i32 {
              %coord_69 = cute.make_coord(%arg31, %arg29) : (i32, i32) -> !cute.coord<"(_,_,?,?)">
              %idx_70 = cute.crd2idx(%coord_69, %10) : (!cute.coord<"(_,_,?,?)">, !cute.layout<"(1,1,4,6):(0,0,2,1024)">) -> !cute.int_tuple<"?{div=2}">
              %tup = cute.add_offset(%ummaSmemDesc, %idx_70) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
              %tup_71 = cute.add_offset(%ummaSmemDesc_54, %idx_70) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
              %155 = cute.get_scalars(%28) : !cute.int_tuple<"1">
              scf.for %arg33 = %c0_i32 to %155 step %c1_i32  : i32 {
                scf.for %arg34 = %c0_i32 to %155 step %c1_i32  : i32 {
                  scf.for %arg35 = %c0_i32 to %155 step %c1_i32  : i32 {
                    %157 = cute_nvgpu.atom.get_value(%arg32 : !mma_tf32_tf32_f32_128x128x8_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : i1
                    %158 = cute_nvgpu.atom.get_value(%arg32 : !mma_tf32_tf32_f32_128x128x8_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : i1
                    %159 = cute_nvgpu.atom.get_value(%arg32 : !mma_tf32_tf32_f32_128x128x8_) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : i1
                    %160 = arith.extui %157 : i1 to i32
                    %161 = arith.extui %158 : i1 to i32
                    %162 = arith.shli %160, %c13_i32 : i32
                    %163 = arith.shli %161, %c14_i32 : i32
                    %164 = arith.ori %162, %c136317200_i32 : i32
                    %165 = arith.ori %164, %163 : i32
                    cute_nvgpu.arch.mma.SM100.umma(%tup, %tup_71, %ptr_66, %165, %159) {num_cta = 1 : i32, scale = 0 : i32, a_type = tf32} : (!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, !cute.ptr<f32, tmem, align<16>>, i32, i1) -> ()
                  } {llvm.loop_annotation = #loop_annotation}
                } {llvm.loop_annotation = #loop_annotation}
              } {llvm.loop_annotation = #loop_annotation}
              %156 = cute_nvgpu.atom.set_value(%arg32, %true : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_tf32_tf32_f32_128x128x8_
              scf.yield %156 : !mma_tf32_tf32_f32_128x128x8_
            } {loop_annotation = #loop_annotation2}
            %147 = nvvm.elect.sync -> i1
            scf.if %147 {
              %int_tuple_69 = cute.make_int_tuple(%arg29) : (i32) -> !cute.int_tuple<"?">
              %ptr_70 = cute.add_offset(%ptr_8, %int_tuple_69) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
              %155 = builtin.unrealized_conversion_cast %ptr_70 : !cute.ptr<i64, smem> to !llvm.ptr<3>
              nvvm.tcgen05.commit.arrive %155 : !llvm.ptr<3>
            }
            %148 = arith.addi %arg29, %c1_i32 : i32
            %149 = arith.addi %arg28, %c1_i32 : i32
            %150 = arith.cmpi eq, %148, %c6_i32 : i32
            %151 = arith.select %150, %c0_i32, %148 : i32
            %152 = scf.if %150 -> (i32) {
              %155 = arith.xori %arg30, %c1_i32 : i32
              scf.yield %155 : i32
            } else {
              scf.yield %arg30 : i32
            }
            %153 = arith.cmpi sgt, %72, %149 : i32
            %154 = scf.if %153 -> (i1) {
              %int_tuple_69 = cute.make_int_tuple(%151) : (i32) -> !cute.int_tuple<"?">
              %ptr_70 = cute.add_offset(%iter_7, %int_tuple_69) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
              %155 = builtin.unrealized_conversion_cast %ptr_70 : !cute.ptr<i64, smem> to !llvm.ptr<3>
              %156 = nvvm.mbarrier.wait.parity %155, %152 {kind = #nvvm.mbar_wait<try>} : !llvm.ptr<3>, i32 -> i1
              scf.yield %156 : i1
            } else {
              scf.yield %true : i1
            }
            scf.yield %154, %146, %149, %151, %152 : i1, !mma_tf32_tf32_f32_128x128x8_, i32, i32, i32
          }
          %122 = nvvm.elect.sync -> i1
          scf.if %122 {
            %ptr_69 = cute.add_offset(%iter_9, %int_tuple_67) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
            %144 = builtin.unrealized_conversion_cast %ptr_69 : !cute.ptr<i64, smem> to !llvm.ptr<3>
            nvvm.tcgen05.commit.arrive %144 : !llvm.ptr<3>
          }
          %123 = arith.addi %arg21, %c1_i32 : i32
          %124 = arith.addi %arg20, %c1_i32 : i32
          %125 = arith.cmpi eq, %123, %c2_i32 : i32
          %126 = arith.select %125, %c0_i32, %123 : i32
          %127 = scf.if %125 -> (i32) {
            %144 = arith.xori %arg22, %c1_i32 : i32
            scf.yield %144 : i32
          } else {
            scf.yield %arg22 : i32
          }
          %128 = arith.addi %arg23, %88 : i32
          %129 = arith.addi %arg24, %c1_i32 : i32
          %130 = arith.cmpi sgt, %89, %128 : i32
          %131 = nvvm.mul  hi %128, %multiplier : i32 -> i32
          %132 = arith.subi %128, %131 : i32
          %133 = arith.shrui %132, %92 : i32
          %134 = arith.addi %131, %133 : i32
          %135 = arith.shrui %134, %93 : i32
          %136 = arith.muli %135, %91 : i32
          %137 = arith.subi %128, %136 : i32
          %138 = nvvm.mul  hi %137, %multiplier_60 : i32 -> i32
          %139 = arith.subi %137, %138 : i32
          %140 = arith.shrui %139, %101 : i32
          %141 = arith.addi %138, %140 : i32
          %142 = arith.shrui %141, %102 : i32
          %143 = nvvm.mul  hi %142, %multiplier_63 : i32 -> i32
          scf.yield %130, %121#3, %121#4, %121#1, %124, %126, %127, %128, %129 : i1, i32, i32, !mma_tf32_tf32_f32_128x128x8_, i32, i32, i32, i32, i32
        }
        %110 = nvvm.read.ptx.sreg.cluster.ctarank : i32
        %111 = cute_nvgpu.arch.make_warp_uniform(%110) : i32
        %112 = arith.remsi %111, %c2_i32 : i32
        %113 = arith.cmpi eq, %112, %c0_i32 : i32
        scf.if %113 {
          %114 = arith.addi %109#4, %c1_i32 : i32
          %115 = arith.cmpi eq, %114, %c2_i32 : i32
          %116 = arith.select %115, %c0_i32, %114 : i32
          %117 = scf.if %115 -> (i32) {
            %119 = arith.xori %109#5, %c1_i32 : i32
            scf.yield %119 : i32
          } else {
            scf.yield %109#5 : i32
          }
          %int_tuple_66 = cute.make_int_tuple(%116) : (i32) -> !cute.int_tuple<"?">
          %ptr_67 = cute.add_offset(%ptr_10, %int_tuple_66) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
          %118 = builtin.unrealized_conversion_cast %ptr_67 : !cute.ptr<i64, smem> to !llvm.ptr<3>
          nvvm.mbarrier.try_wait.parity.shared %118, %117, %c10000000_i32 : !llvm.ptr<3>, i32, i32
        }
      }
      %82 = arith.cmpi slt, %48, %c4_i32 : i32
      scf.if %82 {
        scf.if %50 {
          cute_nvgpu.arch.sm100.alloc_tmem(%c256_i32, %iter) [ cta_1] : i32, !cute.ptr<i32, smem, align<8>>
        }
        nvvm.barrier id = %c3_i32 number_of_threads = %c160_i32
        %tmem_ptr = cute_nvgpu.arch.sm100.retrieve_tmem_ptr(%iter) : !cute.ptr<i32, smem, align<8>> -> !cute.ptr<f32, tmem, align<16>>
        %coord = cute.make_coord(%37) : (i32) -> !cute.coord<"?">
        %84 = cute.get_scalars(%coord) <{only_dynamic}> : !cute.coord<"?">
        %85 = arith.divsi %84, %c32_i32 : i32
        %86 = arith.muli %85, %c2097152_i32 : i32
        %iv = cute.assume(%86) : (i32) -> !cute.i32<divby 2097152>
        %int_tuple_55 = cute.make_int_tuple(%iv) : (!cute.i32<divby 2097152>) -> !cute.int_tuple<"?{div=2097152}">
        %ptr_56 = cute.add_offset(%tmem_ptr, %int_tuple_55) : (!cute.ptr<f32, tmem, align<16>>, !cute.int_tuple<"?{div=2097152}">) -> !cute.ptr<f32, tmem, align<16>>
        %rmem = cute.memref.alloca() : !memref_rmem_f32_
        %iter_57 = cute.get_iter(%rmem) : !memref_rmem_f32_
        %rmem_58 = cute.memref.alloca() : !memref_rmem_f32_
        %atom = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<f32>
        %87 = cute.make_tiled_copy(%atom) : !copy_simt
        %88 = arith.remsi %84, %c32_i32 : i32
        %89 = arith.muli %88, %c16_i32 : i32
        %90 = arith.muli %85, %c512_i32 : i32
        %91 = arith.addi %89, %90 : i32
        %iv_59 = cute.assume(%91) : (i32) -> !cute.i32<divby 16>
        %int_tuple_60 = cute.make_int_tuple(%iv_59) : (!cute.i32<divby 16>) -> !cute.int_tuple<"?{div=16}">
        %ptr_61 = cute.add_offset(%iter_13, %int_tuple_60) : (!cute.ptr<f32, smem, align<1024>, S<2,4,3>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<f32, smem, align<64>, S<2,4,3>>
        %iter_62 = cute.get_iter(%rmem_58) : !memref_rmem_f32_
        %rmem_63 = cute.memref.alloca() : !memref_rmem_f32_
        %92 = cute.make_tiled_copy(%atom) : !copy_simt
        %ptr_64 = cute.add_offset(%iter_14, %int_tuple_60) : (!cute.ptr<f32, smem, align<1024>, S<2,4,3>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<f32, smem, align<64>, S<2,4,3>>
        %iter_65 = cute.get_iter(%rmem_63) : !memref_rmem_f32_
        %view = cute.make_view(%iter_65) : !memref_rmem_f32_1
        %93:3 = cute.get_scalars(%lay_45) <{only_dynamic}> : !cute.layout<"((128,128),1,1,?,?,?):((1@1,1@0),0,0,128@1,128@0,1@2)">
        %shape_66 = cute.make_shape(%93#0, %93#1, %93#2) : (i32, i32, i32) -> !cute.shape<"(128,128,?,?,?)">
        %lay_67 = cute.make_layout(%shape_66, %18) : !cute.layout<"(128,128,?,?,?):(1@1,1@0,128@1,128@0,1@2)">
        %94:3 = cute.get_scalars(%lay_67) <{only_dynamic}> : !cute.layout<"(128,128,?,?,?):(1@1,1@0,128@1,128@0,1@2)">
        %shape_68 = cute.make_shape(%94#0, %94#1, %94#2) : (i32, i32, i32) -> !cute.shape<"(128,16,1,8,?,?,?)">
        %lay_69 = cute.make_layout(%shape_68, %9) : !cute.layout<"(128,16,1,8,?,?,?):(1@1,1@0,0,16@0,128@1,128@0,1@2)">
        %95:3 = cute.get_scalars(%lay_69) <{only_dynamic}> : !cute.layout<"(128,16,1,8,?,?,?):(1@1,1@0,0,16@0,128@1,128@0,1@2)">
        %shape_70 = cute.make_shape(%95#0, %95#1, %95#2) : (i32, i32, i32) -> !cute.shape<"((128,16),1,8,?,?,?)">
        %lay_71 = cute.make_layout(%shape_70, %8) : !cute.layout<"((128,16),1,8,?,?,?):((1@1,1@0),0,16@0,128@1,128@0,1@2)">
        %96:3 = cute.get_scalars(%lay_71) <{only_dynamic}> : !cute.layout<"((128,16),1,8,?,?,?):((1@1,1@0),0,16@0,128@1,128@0,1@2)">
        %shape_72 = cute.make_shape(%96#0, %96#1, %96#2) : (i32, i32, i32) -> !cute.shape<"(((16,128),1),1,8,?,?,?)">
        %lay_73 = cute.make_layout(%shape_72, %7) : !cute.layout<"(((16,128),1),1,8,?,?,?):(((1@0,1@1),0),0,16@0,128@1,128@0,1@2)">
        %97 = nvvm.read.ptx.sreg.ctaid.z range <i32, 0, 65535> : i32
        %98 = nvvm.read.ptx.sreg.nctaid.x range <i32, 1, 2147483647> : i32
        %99 = nvvm.read.ptx.sreg.nctaid.y range <i32, 1, 65535> : i32
        %100 = nvvm.read.ptx.sreg.nctaid.z range <i32, 1, 65535> : i32
        %int_tuple_74 = cute.make_int_tuple(%98, %99, %100) : (i32, i32, i32) -> !cute.int_tuple<"(?,?,?)">
        %sz_75 = cute.size(%int_tuple_74) : (!cute.int_tuple<"(?,?,?)">) -> !cute.int_tuple<"?">
        %e0_76 = cute.get_leaves(%sz_75) : !cute.int_tuple<"?">
        %div = cute.tuple_div(%e0_76, %28) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
        %101 = cute.get_scalars(%div) : !cute.int_tuple<"?">
        %sz_77 = cute.size(%lay) : (!cute.layout<"(?,?,?):(1,?,?)">) -> !cute.int_tuple<"?">
        %e0_78 = cute.get_leaves(%sz_77) : !cute.int_tuple<"?">
        %102 = cute.get_scalars(%e0_78) : !cute.int_tuple<"?">
        %103 = arith.cmpi sgt, %102, %97 : i32
        %104 = cute.fast_divmod.get_divisor(%arg12) : !cute.fast_divmod_divisor<32>
        %multiplier, %shift1, %shift2 = cute.fast_divmod.get_aux(%arg12) : !cute.fast_divmod_divisor<32> -> (i32, i8)
        %105 = arith.extui %shift1 : i8 to i32
        %106 = arith.extui %shift2 : i8 to i32
        %107 = nvvm.mul  hi %97, %multiplier : i32 -> i32
        %108 = arith.subi %97, %107 : i32
        %109 = arith.shrui %108, %105 : i32
        %110 = arith.addi %107, %109 : i32
        %111 = arith.shrui %110, %106 : i32
        %112 = arith.muli %111, %104 : i32
        %113 = arith.subi %97, %112 : i32
        %114 = cute.fast_divmod.get_divisor(%arg13) : !cute.fast_divmod_divisor<32>
        %multiplier_79, %shift1_80, %shift2_81 = cute.fast_divmod.get_aux(%arg13) : !cute.fast_divmod_divisor<32> -> (i32, i8)
        %115 = arith.extui %shift1_80 : i8 to i32
        %116 = arith.extui %shift2_81 : i8 to i32
        %117 = nvvm.mul  hi %113, %multiplier_79 : i32 -> i32
        %118 = arith.subi %113, %117 : i32
        %119 = arith.shrui %118, %115 : i32
        %120 = arith.addi %117, %119 : i32
        %121 = arith.shrui %120, %116 : i32
        %122 = arith.muli %121, %114 : i32
        %123 = arith.subi %113, %122 : i32
        %124 = cute.fast_divmod.get_divisor(%arg14) : !cute.fast_divmod_divisor<32>
        %multiplier_82, %shift1_83, %shift2_84 = cute.fast_divmod.get_aux(%arg14) : !cute.fast_divmod_divisor<32> -> (i32, i8)
        %125 = arith.extui %shift1_83 : i8 to i32
        %126 = arith.extui %shift2_84 : i8 to i32
        %127 = nvvm.mul  hi %121, %multiplier_82 : i32 -> i32
        %128 = arith.subi %121, %127 : i32
        %129 = arith.shrui %128, %125 : i32
        %130 = arith.addi %127, %129 : i32
        %131 = arith.shrui %130, %126 : i32
        %132 = arith.muli %131, %124 : i32
        %133 = arith.subi %121, %132 : i32
        %int_tuple_85 = cute.make_int_tuple(%123) : (i32) -> !cute.int_tuple<"?">
        %mul = cute.tuple_mul(%int_tuple_85, %28) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
        %134 = cute.get_scalars(%mul) : !cute.int_tuple<"?">
        %int_tuple_86 = cute.make_int_tuple(%133) : (i32) -> !cute.int_tuple<"?">
        %mul_87 = cute.tuple_mul(%int_tuple_86, %28) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
        %135 = cute.get_scalars(%mul_87) : !cute.int_tuple<"?">
        %int_tuple_88 = cute.make_int_tuple(%131) : (i32) -> !cute.int_tuple<"?">
        %mul_89 = cute.tuple_mul(%int_tuple_88, %28) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
        %136 = cute.get_scalars(%mul_89) : !cute.int_tuple<"?">
        %137:11 = scf.while (%arg17 = %134, %arg18 = %135, %arg19 = %136, %arg20 = %103, %arg21 = %c0_i32, %arg22 = %c0_i32, %arg23 = %c0_i32, %arg24 = %c0_i32, %arg25 = %c0_i32, %arg26 = %c0_i32, %arg27 = %97, %arg28 = %c0_i32) : (i32, i32, i32, i1, i32, i32, i32, i32, i32, i32, i32, i32) -> (i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) {
          scf.condition(%arg20) %arg17, %arg18, %arg19, %arg21, %arg22, %arg23, %arg24, %arg25, %arg26, %arg27, %arg28 : i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32
        } do {
        ^bb0(%arg17: i32, %arg18: i32, %arg19: i32, %arg20: i32, %arg21: i32, %arg22: i32, %arg23: i32, %arg24: i32, %arg25: i32, %arg26: i32, %arg27: i32):
          %coord_90 = cute.make_coord(%arg17, %arg18, %arg19) : (i32, i32, i32) -> !cute.coord<"(_,_,_,?,?,?)">
          %idx = cute.crd2idx(%coord_90, %lay_73) : (!cute.coord<"(_,_,_,?,?,?)">, !cute.layout<"(((16,128),1),1,8,?,?,?):(((1@0,1@1),0),0,16@0,128@1,128@0,1@2)">) -> !cute.int_tuple<"(?{div=128},?{div=128},?)">
          %tup = cute.add_offset(%20, %idx) : (!cute.int_tuple<"(0,0,0)">, !cute.int_tuple<"(?{div=128},?{div=128},?)">) -> !cute.int_tuple<"(?{div=128},?{div=128},?)">
          %coord_91 = cute.make_coord(%arg24) : (i32) -> !cute.coord<"(_,_,_,_,_,?)">
          %idx_92 = cute.crd2idx(%coord_91, %6) : (!cute.coord<"(_,_,_,_,_,?)">, !cute.layout<"(((16,32),1),1,1,1,8,2):(((1,65536),0),0,0,0,16,128)">) -> !cute.int_tuple<"?{div=128}">
          %ptr_93 = cute.add_offset(%ptr_56, %idx_92) : (!cute.ptr<f32, tmem, align<16>>, !cute.int_tuple<"?{div=128}">) -> !cute.ptr<f32, tmem, align<16>>
          %int_tuple_94 = cute.make_int_tuple(%arg24) : (i32) -> !cute.int_tuple<"?">
          %ptr_95 = cute.add_offset(%iter_9, %int_tuple_94) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
          %138 = builtin.unrealized_conversion_cast %ptr_95 : !cute.ptr<i64, smem> to !llvm.ptr<3>
          nvvm.mbarrier.try_wait.parity.shared %138, %arg25, %c10000000_i32 : !llvm.ptr<3>, i32, i32
          %139 = arith.muli %arg27, %c8_i32 : i32
          %140:3 = scf.for %arg28 = %c0_i32 to %c8_i32 step %c1_i32 iter_args(%arg29 = %arg20, %arg30 = %arg21, %arg31 = %arg22) -> (i32, i32, i32)  : i32 {
            %coord_102 = cute.make_coord(%arg28) : (i32) -> !cute.coord<"(_,_,_,?)">
            %idx_103 = cute.crd2idx(%coord_102, %5) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"(((16,32),1),1,1,(1,8)):(((1,65536),0),0,0,(0,16))">) -> !cute.int_tuple<"?{div=16}">
            %ptr_104 = cute.add_offset(%ptr_93, %idx_103) : (!cute.ptr<f32, tmem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<f32, tmem, align<16>>
            %174 = cute.get_scalars(%28) : !cute.int_tuple<"1">
            scf.for %arg32 = %c0_i32 to %174 step %c1_i32  : i32 {
              %190 = "cute_nvgpu.arch.copy.SM100.tmem_load"(%ptr_104) <{num_b = 32 : i32, num_dp = 32 : i32, num_rep = 16 : i32}> : (!cute.ptr<f32, tmem, align<16>>) -> vector<16xi32>
              %191 = builtin.unrealized_conversion_cast %iter_57 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
              llvm.store %190, %191 : vector<16xi32>, !llvm.ptr
            } {llvm.loop_annotation = #loop_annotation}
            %int_tuple_105 = cute.make_int_tuple(%arg30) : (i32) -> !cute.int_tuple<"?">
            %ptr_106 = cute.add_offset(%iter_11, %int_tuple_105) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
            %175 = builtin.unrealized_conversion_cast %ptr_106 : !cute.ptr<i64, smem> to !llvm.ptr<3>
            nvvm.mbarrier.try_wait.parity.shared %175, %arg31, %c10000000_i32 : !llvm.ptr<3>, i32, i32
            %coord_107 = cute.make_coord(%arg30) : (i32) -> !cute.coord<"(_,_,_,?)">
            %idx_108 = cute.crd2idx(%coord_107, %4) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((1,16),1,1,(1,2)):((0,1),0,0,(0,2048))">) -> !cute.int_tuple<"?{div=2048}">
            scf.for %arg32 = %c0_i32 to %174 step %c1_i32  : i32 {
              %swizzled = cute.apply_swizzle(%ptr_61) : !cute.ptr<f32, smem, align<64>, S<2,4,3>>
              %ptr_113 = cute.add_offset(%swizzled, %idx_108) : (!cute.ptr<f32, smem, align<64>, S<2,4,3>>, !cute.int_tuple<"?{div=2048}">) -> !cute.ptr<f32, smem, align<64>, S<2,4,3>>
              %190 = builtin.unrealized_conversion_cast %ptr_113 : !cute.ptr<f32, smem, align<64>, S<2,4,3>> to !llvm.ptr<3>
              %191 = builtin.unrealized_conversion_cast %iter_62 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
              %192 = llvm.load %190 {alignment = 16 : i64} : !llvm.ptr<3> -> vector<4xf32>
              llvm.store %192, %191 {alignment = 16 : i64} : vector<4xf32>, !llvm.ptr
              %ptr_114 = cute.add_offset(%iter_62, %25) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
              %ptr_115 = cute.add_offset(%ptr_61, %25) : (!cute.ptr<f32, smem, align<64>, S<2,4,3>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, smem, align<16>, S<2,4,3>>
              %swizzled_116 = cute.apply_swizzle(%ptr_115) : !cute.ptr<f32, smem, align<16>, S<2,4,3>>
              %ptr_117 = cute.add_offset(%swizzled_116, %idx_108) : (!cute.ptr<f32, smem, align<16>, S<2,4,3>>, !cute.int_tuple<"?{div=2048}">) -> !cute.ptr<f32, smem, align<16>, S<2,4,3>>
              %193 = builtin.unrealized_conversion_cast %ptr_117 : !cute.ptr<f32, smem, align<16>, S<2,4,3>> to !llvm.ptr<3>
              %194 = builtin.unrealized_conversion_cast %ptr_114 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              %195 = llvm.load %193 {alignment = 16 : i64} : !llvm.ptr<3> -> vector<4xf32>
              llvm.store %195, %194 {alignment = 16 : i64} : vector<4xf32>, !llvm.ptr
              %ptr_118 = cute.add_offset(%iter_62, %3) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<f32, rmem, align<32>>
              %ptr_119 = cute.add_offset(%ptr_61, %3) : (!cute.ptr<f32, smem, align<64>, S<2,4,3>>, !cute.int_tuple<"8">) -> !cute.ptr<f32, smem, align<32>, S<2,4,3>>
              %swizzled_120 = cute.apply_swizzle(%ptr_119) : !cute.ptr<f32, smem, align<32>, S<2,4,3>>
              %ptr_121 = cute.add_offset(%swizzled_120, %idx_108) : (!cute.ptr<f32, smem, align<32>, S<2,4,3>>, !cute.int_tuple<"?{div=2048}">) -> !cute.ptr<f32, smem, align<32>, S<2,4,3>>
              %196 = builtin.unrealized_conversion_cast %ptr_121 : !cute.ptr<f32, smem, align<32>, S<2,4,3>> to !llvm.ptr<3>
              %197 = builtin.unrealized_conversion_cast %ptr_118 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
              %198 = llvm.load %196 {alignment = 16 : i64} : !llvm.ptr<3> -> vector<4xf32>
              llvm.store %198, %197 {alignment = 16 : i64} : vector<4xf32>, !llvm.ptr
              %ptr_122 = cute.add_offset(%iter_62, %2) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<f32, rmem, align<16>>
              %ptr_123 = cute.add_offset(%ptr_61, %2) : (!cute.ptr<f32, smem, align<64>, S<2,4,3>>, !cute.int_tuple<"12">) -> !cute.ptr<f32, smem, align<16>, S<2,4,3>>
              %swizzled_124 = cute.apply_swizzle(%ptr_123) : !cute.ptr<f32, smem, align<16>, S<2,4,3>>
              %ptr_125 = cute.add_offset(%swizzled_124, %idx_108) : (!cute.ptr<f32, smem, align<16>, S<2,4,3>>, !cute.int_tuple<"?{div=2048}">) -> !cute.ptr<f32, smem, align<16>, S<2,4,3>>
              %199 = builtin.unrealized_conversion_cast %ptr_125 : !cute.ptr<f32, smem, align<16>, S<2,4,3>> to !llvm.ptr<3>
              %200 = builtin.unrealized_conversion_cast %ptr_122 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              %201 = llvm.load %199 {alignment = 16 : i64} : !llvm.ptr<3> -> vector<4xf32>
              llvm.store %201, %200 {alignment = 16 : i64} : vector<4xf32>, !llvm.ptr
            } {llvm.loop_annotation = #loop_annotation}
            nvvm.fence.proxy {kind = #nvvm.proxy_kind<async.shared>, space = #nvvm.shared_space<cta>}
            scf.if %55 {
              %ptr_113 = cute.add_offset(%ptr_12, %int_tuple_105) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
              %190 = builtin.unrealized_conversion_cast %ptr_113 : !cute.ptr<i64, smem> to !llvm.ptr<3>
              nvvm.mbarrier.txn %190, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>} : !llvm.ptr<3>, i32
            }
            %176 = arith.addi %arg30, %c1_i32 : i32
            %177 = arith.addi %arg29, %c1_i32 : i32
            %178 = arith.cmpi eq, %176, %c2_i32 : i32
            %179 = arith.select %178, %c0_i32, %176 : i32
            %180 = scf.if %178 -> (i32) {
              %190 = arith.xori %arg31, %c1_i32 : i32
              scf.yield %190 : i32
            } else {
              scf.yield %arg31 : i32
            }
            %view_109 = cute.make_view(%iter_57) : !memref_rmem_f32_1
            %181 = cute.memref.load_vec %view_109 : !memref_rmem_f32_1
            %view_110 = cute.make_view(%iter_62) : !memref_rmem_f32_1
            %182 = cute.memref.load_vec %view_110 : !memref_rmem_f32_1
            %183 = vector.broadcast %arg15 : f32 to vector<16xf32>
            %184 = arith.mulf %183, %181 : vector<16xf32>
            %185 = vector.broadcast %arg16 : f32 to vector<16xf32>
            %186 = arith.mulf %185, %182 : vector<16xf32>
            %187 = arith.addf %184, %186 : vector<16xf32>
            cute.memref.store_vec %187, %view : !memref_rmem_f32_1
            %188 = arith.addi %139, %arg28 : i32
            %189 = arith.remsi %188, %c2_i32 : i32
            %coord_111 = cute.make_coord(%189) : (i32) -> !cute.coord<"(_,_,_,?)">
            %idx_112 = cute.crd2idx(%coord_111, %4) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((1,16),1,1,(1,2)):((0,1),0,0,(0,2048))">) -> !cute.int_tuple<"?{div=2048}">
            scf.for %arg32 = %c0_i32 to %174 step %c1_i32  : i32 {
              %swizzled = cute.apply_swizzle(%ptr_64) : !cute.ptr<f32, smem, align<64>, S<2,4,3>>
              %ptr_113 = cute.add_offset(%swizzled, %idx_112) : (!cute.ptr<f32, smem, align<64>, S<2,4,3>>, !cute.int_tuple<"?{div=2048}">) -> !cute.ptr<f32, smem, align<64>, S<2,4,3>>
              %190 = builtin.unrealized_conversion_cast %iter_65 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
              %191 = builtin.unrealized_conversion_cast %ptr_113 : !cute.ptr<f32, smem, align<64>, S<2,4,3>> to !llvm.ptr<3>
              %192 = llvm.load %190 {alignment = 16 : i64} : !llvm.ptr -> vector<4xf32>
              llvm.store %192, %191 {alignment = 16 : i64} : vector<4xf32>, !llvm.ptr<3>
              %ptr_114 = cute.add_offset(%iter_65, %25) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
              %ptr_115 = cute.add_offset(%ptr_64, %25) : (!cute.ptr<f32, smem, align<64>, S<2,4,3>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, smem, align<16>, S<2,4,3>>
              %swizzled_116 = cute.apply_swizzle(%ptr_115) : !cute.ptr<f32, smem, align<16>, S<2,4,3>>
              %ptr_117 = cute.add_offset(%swizzled_116, %idx_112) : (!cute.ptr<f32, smem, align<16>, S<2,4,3>>, !cute.int_tuple<"?{div=2048}">) -> !cute.ptr<f32, smem, align<16>, S<2,4,3>>
              %193 = builtin.unrealized_conversion_cast %ptr_114 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              %194 = builtin.unrealized_conversion_cast %ptr_117 : !cute.ptr<f32, smem, align<16>, S<2,4,3>> to !llvm.ptr<3>
              %195 = llvm.load %193 {alignment = 16 : i64} : !llvm.ptr -> vector<4xf32>
              llvm.store %195, %194 {alignment = 16 : i64} : vector<4xf32>, !llvm.ptr<3>
              %ptr_118 = cute.add_offset(%iter_65, %3) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<f32, rmem, align<32>>
              %ptr_119 = cute.add_offset(%ptr_64, %3) : (!cute.ptr<f32, smem, align<64>, S<2,4,3>>, !cute.int_tuple<"8">) -> !cute.ptr<f32, smem, align<32>, S<2,4,3>>
              %swizzled_120 = cute.apply_swizzle(%ptr_119) : !cute.ptr<f32, smem, align<32>, S<2,4,3>>
              %ptr_121 = cute.add_offset(%swizzled_120, %idx_112) : (!cute.ptr<f32, smem, align<32>, S<2,4,3>>, !cute.int_tuple<"?{div=2048}">) -> !cute.ptr<f32, smem, align<32>, S<2,4,3>>
              %196 = builtin.unrealized_conversion_cast %ptr_118 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
              %197 = builtin.unrealized_conversion_cast %ptr_121 : !cute.ptr<f32, smem, align<32>, S<2,4,3>> to !llvm.ptr<3>
              %198 = llvm.load %196 {alignment = 16 : i64} : !llvm.ptr -> vector<4xf32>
              llvm.store %198, %197 {alignment = 16 : i64} : vector<4xf32>, !llvm.ptr<3>
              %ptr_122 = cute.add_offset(%iter_65, %2) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<f32, rmem, align<16>>
              %ptr_123 = cute.add_offset(%ptr_64, %2) : (!cute.ptr<f32, smem, align<64>, S<2,4,3>>, !cute.int_tuple<"12">) -> !cute.ptr<f32, smem, align<16>, S<2,4,3>>
              %swizzled_124 = cute.apply_swizzle(%ptr_123) : !cute.ptr<f32, smem, align<16>, S<2,4,3>>
              %ptr_125 = cute.add_offset(%swizzled_124, %idx_112) : (!cute.ptr<f32, smem, align<16>, S<2,4,3>>, !cute.int_tuple<"?{div=2048}">) -> !cute.ptr<f32, smem, align<16>, S<2,4,3>>
              %199 = builtin.unrealized_conversion_cast %ptr_122 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              %200 = builtin.unrealized_conversion_cast %ptr_125 : !cute.ptr<f32, smem, align<16>, S<2,4,3>> to !llvm.ptr<3>
              %201 = llvm.load %199 {alignment = 16 : i64} : !llvm.ptr -> vector<4xf32>
              llvm.store %201, %200 {alignment = 16 : i64} : vector<4xf32>, !llvm.ptr<3>
            } {llvm.loop_annotation = #loop_annotation}
            nvvm.fence.proxy {kind = #nvvm.proxy_kind<async.shared>, space = #nvvm.shared_space<cta>}
            nvvm.barrier id = %c2_i32 number_of_threads = %c128_i32
            scf.if %50 {
              %coord_113 = cute.make_coord(%189) : (i32) -> !cute.coord<"(_,?)">
              %idx_114 = cute.crd2idx(%coord_113, %1) : (!cute.coord<"(_,?)">, !cute.layout<"((2048,1),(1,2)):((1,0),(0,2048))">) -> !cute.int_tuple<"?{div=2048}">
              %ptr_115 = cute.add_offset(%iter_14, %idx_114) : (!cute.ptr<f32, smem, align<1024>, S<2,4,3>>, !cute.int_tuple<"?{div=2048}">) -> !cute.ptr<f32, smem, align<1024>, S<2,4,3>>
              %coord_116 = cute.make_coord(%arg28) : (i32) -> !cute.coord<"(_,?)">
              %idx_117 = cute.crd2idx(%coord_116, %0) : (!cute.coord<"(_,?)">, !cute.layout<"(((16,128),1),(1,8)):(((1@0,1@1),0),(0,16@0))">) -> !cute.int_tuple<"(?{div=16},0)">
              %tup_118 = cute.add_offset(%tup, %idx_117) : (!cute.int_tuple<"(?{div=128},?{div=128},?)">, !cute.int_tuple<"(?{div=16},0)">) -> !cute.int_tuple<"(?{div=16},?{div=128},?)">
              %e0_119, %e1_120, %e2_121 = cute.get_leaves(%tup_118) : !cute.int_tuple<"(?{div=16},?{div=128},?)">
              %int_tuple_122 = cute.make_int_tuple(%e0_119, %e1_120, %e2_121) : (!cute.int_tuple<"?{div=16}">, !cute.int_tuple<"?{div=128}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=16},?{div=128},?)">
              %190 = cute_nvgpu.atom.make_exec_tma(%arg7) : (!cute_nvgpu.atom.non_exec_tiled_tma_store<f32, copy_bits = 65536, tma_gbasis = <"(16,128,1):(1@1,1@0,1@2)">, internal_val_type = f32>) -> !cute_nvgpu.atom.tma_store<f32, copy_bits = 65536, mode = tiled, g_stride = <"()"> tma_gbasis = <"(16,128,1):(1@1,1@0,1@2)">>
              scf.for %arg32 = %c0_i32 to %174 step %c1_i32  : i32 {
                %TMADescAddr = cute_nvgpu.get_tma_desc_addr(%190 : !cute_nvgpu.atom.tma_store<f32, copy_bits = 65536, mode = tiled, g_stride = <"()"> tma_gbasis = <"(16,128,1):(1@1,1@0,1@2)">>) -> !cute.ptr<generic, align<64>>
                %191 = cute_nvgpu.atom.get_value(%190 : !cute_nvgpu.atom.tma_store<f32, copy_bits = 65536, mode = tiled, g_stride = <"()"> tma_gbasis = <"(16,128,1):(1@1,1@0,1@2)">>) {field = #cute_nvgpu.atom_copy_field_tmastore<cache_policy>} : i64
                %192:3 = cute.get_scalars(%int_tuple_122) : !cute.int_tuple<"(?{div=16},?{div=128},?)">
                cute_nvgpu.arch.copy.SM100.tma_store(%TMADescAddr : !cute.ptr<generic, align<64>>, %ptr_115 : !cute.ptr<f32, smem, align<1024>, S<2,4,3>>, [%192#0, %192#1, %192#2] : i32, i32, i32) cache_policy = %191 mode = <tiled>
              } {llvm.loop_annotation = #loop_annotation}
              nvvm.cp.async.bulk.commit.group
              nvvm.cp.async.bulk.wait_group 1 {read}
            }
            nvvm.barrier id = %c2_i32 number_of_threads = %c128_i32
            scf.yield %177, %179, %180 : i32, i32, i32
          }
          %141 = nvvm.elect.sync -> i1
          scf.if %141 {
            %ptr_102 = cute.add_offset(%ptr_10, %int_tuple_94) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
            %174 = builtin.unrealized_conversion_cast %ptr_102 : !cute.ptr<i64, smem> to !llvm.ptr<3>
            nvvm.mbarrier.txn %174, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>} : !llvm.ptr<3>, i32
          }
          %142 = arith.addi %arg24, %c1_i32 : i32
          %143 = arith.addi %arg23, %c1_i32 : i32
          %144 = arith.cmpi eq, %142, %c2_i32 : i32
          %145 = arith.select %144, %c0_i32, %142 : i32
          %146 = scf.if %144 -> (i32) {
            %174 = arith.xori %arg25, %c1_i32 : i32
            scf.yield %174 : i32
          } else {
            scf.yield %arg25 : i32
          }
          %147 = arith.addi %arg26, %101 : i32
          %148 = arith.addi %arg27, %c1_i32 : i32
          %149 = arith.cmpi sgt, %102, %147 : i32
          %150 = nvvm.mul  hi %147, %multiplier : i32 -> i32
          %151 = arith.subi %147, %150 : i32
          %152 = arith.shrui %151, %105 : i32
          %153 = arith.addi %150, %152 : i32
          %154 = arith.shrui %153, %106 : i32
          %155 = arith.muli %154, %104 : i32
          %156 = arith.subi %147, %155 : i32
          %157 = nvvm.mul  hi %156, %multiplier_79 : i32 -> i32
          %158 = arith.subi %156, %157 : i32
          %159 = arith.shrui %158, %115 : i32
          %160 = arith.addi %157, %159 : i32
          %161 = arith.shrui %160, %116 : i32
          %162 = arith.muli %161, %114 : i32
          %163 = arith.subi %156, %162 : i32
          %164 = nvvm.mul  hi %161, %multiplier_82 : i32 -> i32
          %165 = arith.subi %161, %164 : i32
          %166 = arith.shrui %165, %125 : i32
          %167 = arith.addi %164, %166 : i32
          %168 = arith.shrui %167, %126 : i32
          %169 = arith.muli %168, %124 : i32
          %170 = arith.subi %161, %169 : i32
          %int_tuple_96 = cute.make_int_tuple(%163) : (i32) -> !cute.int_tuple<"?">
          %mul_97 = cute.tuple_mul(%int_tuple_96, %28) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
          %171 = cute.get_scalars(%mul_97) : !cute.int_tuple<"?">
          %int_tuple_98 = cute.make_int_tuple(%170) : (i32) -> !cute.int_tuple<"?">
          %mul_99 = cute.tuple_mul(%int_tuple_98, %28) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
          %172 = cute.get_scalars(%mul_99) : !cute.int_tuple<"?">
          %int_tuple_100 = cute.make_int_tuple(%168) : (i32) -> !cute.int_tuple<"?">
          %mul_101 = cute.tuple_mul(%int_tuple_100, %28) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
          %173 = cute.get_scalars(%mul_101) : !cute.int_tuple<"?">
          scf.yield %171, %172, %173, %149, %140#0, %140#1, %140#2, %143, %145, %146, %147, %148 : i32, i32, i32, i1, i32, i32, i32, i32, i32, i32, i32, i32
        }
        scf.if %50 {
          cute_nvgpu.arch.sm100.relinquish_tmem_alloc_permit [ cta_1]
        }
        nvvm.barrier id = %c2_i32 number_of_threads = %c128_i32
        scf.if %50 {
          cute_nvgpu.arch.sm100.dealloc_tmem(%tmem_ptr, %c256_i32) [ cta_1] : !cute.ptr<f32, tmem, align<16>>, i32
        }
        nvvm.cp.async.bulk.wait_group 0 {read}
      }
      %83 = arith.cmpi eq, %48, %c6_i32 : i32
      scf.if %83 {
        %84:3 = cute.get_scalars(%lay_43) <{only_dynamic}> : !cute.layout<"((128,128),1,1,?,?,?):((1@1,1@0),0,0,128@1,128@0,1@2)">
        %shape_55 = cute.make_shape(%84#0, %84#1, %84#2) : (i32, i32, i32) -> !cute.shape<"(128,128,?,?,?)">
        %lay_56 = cute.make_layout(%shape_55, %18) : !cute.layout<"(128,128,?,?,?):(1@1,1@0,128@1,128@0,1@2)">
        %85:3 = cute.get_scalars(%lay_56) <{only_dynamic}> : !cute.layout<"(128,128,?,?,?):(1@1,1@0,128@1,128@0,1@2)">
        %shape_57 = cute.make_shape(%85#0, %85#1, %85#2) : (i32, i32, i32) -> !cute.shape<"(128,16,1,8,?,?,?)">
        %lay_58 = cute.make_layout(%shape_57, %9) : !cute.layout<"(128,16,1,8,?,?,?):(1@1,1@0,0,16@0,128@1,128@0,1@2)">
        %86:3 = cute.get_scalars(%lay_58) <{only_dynamic}> : !cute.layout<"(128,16,1,8,?,?,?):(1@1,1@0,0,16@0,128@1,128@0,1@2)">
        %shape_59 = cute.make_shape(%86#0, %86#1, %86#2) : (i32, i32, i32) -> !cute.shape<"((128,16),1,8,?,?,?)">
        %lay_60 = cute.make_layout(%shape_59, %8) : !cute.layout<"((128,16),1,8,?,?,?):((1@1,1@0),0,16@0,128@1,128@0,1@2)">
        %87:3 = cute.get_scalars(%lay_60) <{only_dynamic}> : !cute.layout<"((128,16),1,8,?,?,?):((1@1,1@0),0,16@0,128@1,128@0,1@2)">
        %shape_61 = cute.make_shape(%87#0, %87#1, %87#2) : (i32, i32, i32) -> !cute.shape<"(((16,128),1),1,8,?,?,?)">
        %lay_62 = cute.make_layout(%shape_61, %7) : !cute.layout<"(((16,128),1),1,8,?,?,?):(((1@0,1@1),0),0,16@0,128@1,128@0,1@2)">
        %88 = nvvm.read.ptx.sreg.ctaid.z range <i32, 0, 65535> : i32
        %89 = nvvm.read.ptx.sreg.nctaid.x range <i32, 1, 2147483647> : i32
        %90 = nvvm.read.ptx.sreg.nctaid.y range <i32, 1, 65535> : i32
        %91 = nvvm.read.ptx.sreg.nctaid.z range <i32, 1, 65535> : i32
        %int_tuple_63 = cute.make_int_tuple(%89, %90, %91) : (i32, i32, i32) -> !cute.int_tuple<"(?,?,?)">
        %sz_64 = cute.size(%int_tuple_63) : (!cute.int_tuple<"(?,?,?)">) -> !cute.int_tuple<"?">
        %e0_65 = cute.get_leaves(%sz_64) : !cute.int_tuple<"?">
        %div = cute.tuple_div(%e0_65, %28) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
        %92 = cute.get_scalars(%div) : !cute.int_tuple<"?">
        %sz_66 = cute.size(%lay) : (!cute.layout<"(?,?,?):(1,?,?)">) -> !cute.int_tuple<"?">
        %e0_67 = cute.get_leaves(%sz_66) : !cute.int_tuple<"?">
        %93 = cute.get_scalars(%e0_67) : !cute.int_tuple<"?">
        %94 = arith.cmpi sgt, %93, %88 : i32
        %95 = cute.fast_divmod.get_divisor(%arg12) : !cute.fast_divmod_divisor<32>
        %multiplier, %shift1, %shift2 = cute.fast_divmod.get_aux(%arg12) : !cute.fast_divmod_divisor<32> -> (i32, i8)
        %96 = arith.extui %shift1 : i8 to i32
        %97 = arith.extui %shift2 : i8 to i32
        %98 = nvvm.mul  hi %88, %multiplier : i32 -> i32
        %99 = arith.subi %88, %98 : i32
        %100 = arith.shrui %99, %96 : i32
        %101 = arith.addi %98, %100 : i32
        %102 = arith.shrui %101, %97 : i32
        %103 = arith.muli %102, %95 : i32
        %104 = arith.subi %88, %103 : i32
        %105 = cute.fast_divmod.get_divisor(%arg13) : !cute.fast_divmod_divisor<32>
        %multiplier_68, %shift1_69, %shift2_70 = cute.fast_divmod.get_aux(%arg13) : !cute.fast_divmod_divisor<32> -> (i32, i8)
        %106 = arith.extui %shift1_69 : i8 to i32
        %107 = arith.extui %shift2_70 : i8 to i32
        %108 = nvvm.mul  hi %104, %multiplier_68 : i32 -> i32
        %109 = arith.subi %104, %108 : i32
        %110 = arith.shrui %109, %106 : i32
        %111 = arith.addi %108, %110 : i32
        %112 = arith.shrui %111, %107 : i32
        %113 = arith.muli %112, %105 : i32
        %114 = arith.subi %104, %113 : i32
        %115 = cute.fast_divmod.get_divisor(%arg14) : !cute.fast_divmod_divisor<32>
        %multiplier_71, %shift1_72, %shift2_73 = cute.fast_divmod.get_aux(%arg14) : !cute.fast_divmod_divisor<32> -> (i32, i8)
        %116 = arith.extui %shift1_72 : i8 to i32
        %117 = arith.extui %shift2_73 : i8 to i32
        %118 = nvvm.mul  hi %112, %multiplier_71 : i32 -> i32
        %119 = arith.subi %112, %118 : i32
        %120 = arith.shrui %119, %116 : i32
        %121 = arith.addi %118, %120 : i32
        %122 = arith.shrui %121, %117 : i32
        %123 = arith.muli %122, %115 : i32
        %124 = arith.subi %112, %123 : i32
        %int_tuple_74 = cute.make_int_tuple(%114) : (i32) -> !cute.int_tuple<"?">
        %mul = cute.tuple_mul(%int_tuple_74, %28) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
        %125 = cute.get_scalars(%mul) : !cute.int_tuple<"?">
        %int_tuple_75 = cute.make_int_tuple(%124) : (i32) -> !cute.int_tuple<"?">
        %mul_76 = cute.tuple_mul(%int_tuple_75, %28) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
        %126 = cute.get_scalars(%mul_76) : !cute.int_tuple<"?">
        %int_tuple_77 = cute.make_int_tuple(%122) : (i32) -> !cute.int_tuple<"?">
        %mul_78 = cute.tuple_mul(%int_tuple_77, %28) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
        %127 = cute.get_scalars(%mul_78) : !cute.int_tuple<"?">
        %128:8 = scf.while (%arg17 = %125, %arg18 = %126, %arg19 = %127, %arg20 = %94, %arg21 = %c0_i32, %arg22 = %c0_i32, %arg23 = %c1_i32, %arg24 = %88, %arg25 = %c0_i32) : (i32, i32, i32, i1, i32, i32, i32, i32, i32) -> (i32, i32, i32, i32, i32, i32, i32, i32) {
          scf.condition(%arg20) %arg17, %arg18, %arg19, %arg21, %arg22, %arg23, %arg24, %arg25 : i32, i32, i32, i32, i32, i32, i32, i32
        } do {
        ^bb0(%arg17: i32, %arg18: i32, %arg19: i32, %arg20: i32, %arg21: i32, %arg22: i32, %arg23: i32, %arg24: i32):
          %coord = cute.make_coord(%arg17, %arg18, %arg19) : (i32, i32, i32) -> !cute.coord<"(_,_,_,?,?,?)">
          %idx = cute.crd2idx(%coord, %lay_62) : (!cute.coord<"(_,_,_,?,?,?)">, !cute.layout<"(((16,128),1),1,8,?,?,?):(((1@0,1@1),0),0,16@0,128@1,128@0,1@2)">) -> !cute.int_tuple<"(?{div=128},?{div=128},?)">
          %tup = cute.add_offset(%20, %idx) : (!cute.int_tuple<"(0,0,0)">, !cute.int_tuple<"(?{div=128},?{div=128},?)">) -> !cute.int_tuple<"(?{div=128},?{div=128},?)">
          %135:3 = scf.for %arg25 = %c0_i32 to %c8_i32 step %c1_i32 iter_args(%arg26 = %arg20, %arg27 = %arg21, %arg28 = %arg22) -> (i32, i32, i32)  : i32 {
            %int_tuple_87 = cute.make_int_tuple(%arg27) : (i32) -> !cute.int_tuple<"?">
            %ptr_88 = cute.add_offset(%ptr_12, %int_tuple_87) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
            %163 = builtin.unrealized_conversion_cast %ptr_88 : !cute.ptr<i64, smem> to !llvm.ptr<3>
            nvvm.mbarrier.try_wait.parity.shared %163, %arg28, %c10000000_i32 : !llvm.ptr<3>, i32, i32
            %164 = nvvm.elect.sync -> i1
            scf.if %164 {
              %ptr_100 = cute.add_offset(%iter_11, %int_tuple_87) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
              %173 = builtin.unrealized_conversion_cast %ptr_100 : !cute.ptr<i64, smem> to !llvm.ptr<3>
              nvvm.mbarrier.txn %173, %c8192_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
            }
            %coord_89 = cute.make_coord(%arg25) : (i32) -> !cute.coord<"(_,?)">
            %idx_90 = cute.crd2idx(%coord_89, %0) : (!cute.coord<"(_,?)">, !cute.layout<"(((16,128),1),(1,8)):(((1@0,1@1),0),(0,16@0))">) -> !cute.int_tuple<"(?{div=16},0)">
            %tup_91 = cute.add_offset(%tup, %idx_90) : (!cute.int_tuple<"(?{div=128},?{div=128},?)">, !cute.int_tuple<"(?{div=16},0)">) -> !cute.int_tuple<"(?{div=16},?{div=128},?)">
            %e0_92, %e1_93, %e2_94 = cute.get_leaves(%tup_91) : !cute.int_tuple<"(?{div=16},?{div=128},?)">
            %coord_95 = cute.make_coord(%arg27) : (i32) -> !cute.coord<"(_,?)">
            %idx_96 = cute.crd2idx(%coord_95, %1) : (!cute.coord<"(_,?)">, !cute.layout<"((2048,1),(1,2)):((1,0),(0,2048))">) -> !cute.int_tuple<"?{div=2048}">
            %ptr_97 = cute.add_offset(%iter_13, %idx_96) : (!cute.ptr<f32, smem, align<1024>, S<2,4,3>>, !cute.int_tuple<"?{div=2048}">) -> !cute.ptr<f32, smem, align<1024>, S<2,4,3>>
            %ptr_98 = cute.add_offset(%iter_11, %int_tuple_87) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
            %int_tuple_99 = cute.make_int_tuple(%e0_92, %e1_93, %e2_94) : (!cute.int_tuple<"?{div=16}">, !cute.int_tuple<"?{div=128}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=16},?{div=128},?)">
            %165 = cute_nvgpu.atom.make_exec_tma(%arg5) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f32, copy_bits = 65536, tma_gbasis = <"(16,128,1):(1@1,1@0,1@2)">, internal_val_type = f32>) -> !cute_nvgpu.atom.tma_load<f32, copy_bits = 65536, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(16,128,1):(1@1,1@0,1@2)">>
            %166 = cute_nvgpu.atom.set_value(%165, %ptr_98 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<f32, copy_bits = 65536, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(16,128,1):(1@1,1@0,1@2)">>
            %167 = cute.get_scalars(%28) : !cute.int_tuple<"1">
            scf.for %arg29 = %c0_i32 to %167 step %c1_i32  : i32 {
              %173 = cute_nvgpu.atom.get_value(%166 : !cute_nvgpu.atom.tma_load<f32, copy_bits = 65536, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(16,128,1):(1@1,1@0,1@2)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
              %174 = cute_nvgpu.atom.get_value(%166 : !cute_nvgpu.atom.tma_load<f32, copy_bits = 65536, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(16,128,1):(1@1,1@0,1@2)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<cache_policy>} : i64
              %TMADescAddr = cute_nvgpu.get_tma_desc_addr(%166 : !cute_nvgpu.atom.tma_load<f32, copy_bits = 65536, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(16,128,1):(1@1,1@0,1@2)">>) -> !cute.ptr<generic, align<64>>
              %175:3 = cute.get_scalars(%int_tuple_99) : !cute.int_tuple<"(?{div=16},?{div=128},?)">
              cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr : !cute.ptr<generic, align<64>>, %ptr_97 : !cute.ptr<f32, smem, align<1024>, S<2,4,3>>, %173 : !cute.ptr<smem, align<8>>, [%175#0, %175#1, %175#2] : i32, i32, i32) cache_policy = %174 mode = <tiled> num_cta = 1 : i32
            } {llvm.loop_annotation = #loop_annotation}
            %168 = arith.addi %arg27, %c1_i32 : i32
            %169 = arith.addi %arg26, %c1_i32 : i32
            %170 = arith.cmpi eq, %168, %c2_i32 : i32
            %171 = arith.select %170, %c0_i32, %168 : i32
            %172 = scf.if %170 -> (i32) {
              %173 = arith.xori %arg28, %c1_i32 : i32
              scf.yield %173 : i32
            } else {
              scf.yield %arg28 : i32
            }
            scf.yield %169, %171, %172 : i32, i32, i32
          }
          %136 = arith.addi %arg23, %92 : i32
          %137 = arith.addi %arg24, %c1_i32 : i32
          %138 = arith.cmpi sgt, %93, %136 : i32
          %139 = nvvm.mul  hi %136, %multiplier : i32 -> i32
          %140 = arith.subi %136, %139 : i32
          %141 = arith.shrui %140, %96 : i32
          %142 = arith.addi %139, %141 : i32
          %143 = arith.shrui %142, %97 : i32
          %144 = arith.muli %143, %95 : i32
          %145 = arith.subi %136, %144 : i32
          %146 = nvvm.mul  hi %145, %multiplier_68 : i32 -> i32
          %147 = arith.subi %145, %146 : i32
          %148 = arith.shrui %147, %106 : i32
          %149 = arith.addi %146, %148 : i32
          %150 = arith.shrui %149, %107 : i32
          %151 = arith.muli %150, %105 : i32
          %152 = arith.subi %145, %151 : i32
          %153 = nvvm.mul  hi %150, %multiplier_71 : i32 -> i32
          %154 = arith.subi %150, %153 : i32
          %155 = arith.shrui %154, %116 : i32
          %156 = arith.addi %153, %155 : i32
          %157 = arith.shrui %156, %117 : i32
          %158 = arith.muli %157, %115 : i32
          %159 = arith.subi %150, %158 : i32
          %int_tuple_81 = cute.make_int_tuple(%152) : (i32) -> !cute.int_tuple<"?">
          %mul_82 = cute.tuple_mul(%int_tuple_81, %28) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
          %160 = cute.get_scalars(%mul_82) : !cute.int_tuple<"?">
          %int_tuple_83 = cute.make_int_tuple(%159) : (i32) -> !cute.int_tuple<"?">
          %mul_84 = cute.tuple_mul(%int_tuple_83, %28) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
          %161 = cute.get_scalars(%mul_84) : !cute.int_tuple<"?">
          %int_tuple_85 = cute.make_int_tuple(%157) : (i32) -> !cute.int_tuple<"?">
          %mul_86 = cute.tuple_mul(%int_tuple_85, %28) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
          %162 = cute.get_scalars(%mul_86) : !cute.int_tuple<"?">
          scf.yield %160, %161, %162, %138, %135#0, %135#1, %135#2, %136, %137 : i32, i32, i32, i1, i32, i32, i32, i32, i32
        }
        %129 = arith.addi %128#4, %c1_i32 : i32
        %130 = arith.cmpi eq, %129, %c2_i32 : i32
        %131 = arith.select %130, %c0_i32, %129 : i32
        %132 = scf.if %130 -> (i32) {
          %135 = arith.xori %128#5, %c1_i32 : i32
          scf.yield %135 : i32
        } else {
          scf.yield %128#5 : i32
        }
        %int_tuple_79 = cute.make_int_tuple(%131) : (i32) -> !cute.int_tuple<"?">
        %ptr_80 = cute.add_offset(%ptr_12, %int_tuple_79) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
        %133 = builtin.unrealized_conversion_cast %ptr_80 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        nvvm.mbarrier.try_wait.parity.shared %133, %132, %c10000000_i32 : !llvm.ptr<3>, i32, i32
        %134 = nvvm.elect.sync -> i1
        scf.if %134 {
          %ptr_81 = cute.add_offset(%iter_11, %int_tuple_79) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
          %135 = builtin.unrealized_conversion_cast %ptr_81 : !cute.ptr<i64, smem> to !llvm.ptr<3>
          nvvm.mbarrier.txn %135, %c8192_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
        }
      }
      return
    }
  }
  func.func @cutlass___call_____main__SM100PersistentDenseGemmAlphaBetaKernel_object_at__Tensorgmemoi641i64_Tensorgmemoi641i64_Tensorgmemoi641i64_Tensorgmemoi641i64_10_00_1_CUstream0x0_function(%arg0: !memref_gmem_tf32_, %arg1: !memref_gmem_tf32_, %arg2: !memref_gmem_f32_, %arg3: !memref_gmem_f32_, %arg4: f32, %arg5: f32, %arg6: !cuda.stream) -> i32 attributes {llvm.emit_c_interface} {
    %c230400_i64 = arith.constant 230400 : i64
    %c4294967296_i64 = arith.constant 4294967296 : i64
    %c-2147483648_i32 = arith.constant -2147483648 : i32
    %0 = llvm.mlir.constant(1080863910568919040 : i64) : i64
    %1 = llvm.mlir.constant(279458 : i64) : i64
    %2 = llvm.mlir.constant(127 : i64) : i64
    %3 = llvm.mlir.constant(2233785415175766016 : i64) : i64
    %4 = llvm.mlir.constant(353186 : i64) : i64
    %c0_i32 = arith.constant 0 : i32
    %c224_i32 = arith.constant 224 : i32
    %c1_i32 = arith.constant 1 : i32
    %5 = cute.static : !cute.int_tuple<"1">
    %6 = llvm.mlir.constant(1 : i64) : i64
    %7 = llvm.mlir.constant(1 : i8) : i8
    %8 = llvm.mlir.constant(2 : i32) : i32
    %9 = llvm.mlir.constant(32 : i8) : i8
    %10 = llvm.mlir.constant(0 : i8) : i8
    %11 = llvm.mlir.constant(1 : i32) : i32
    %c128_i64 = arith.constant 128 : i64
    %c128_i32 = arith.constant 128 : i32
    %12 = cute.static : !cute.int_tuple<"(0,0,0)">
    %13 = cute.static : !cute.stride<"(1@1,1@0,1@2)">
    %c44_i64 = arith.constant 44 : i64
    %c40_i64 = arith.constant 40 : i64
    %c15_i64 = arith.constant 15 : i64
    %c36_i64 = arith.constant 36 : i64
    %c21_i64 = arith.constant 21 : i64
    %c131072_i64 = arith.constant 131072 : i64
    %c32_i64 = arith.constant 32 : i64
    %c9007199254740991_i64 = arith.constant 9007199254740991 : i64
    %c4294967295_i64 = arith.constant 4294967295 : i64
    %c16_i64 = arith.constant 16 : i64
    %c8_i64 = arith.constant 8 : i64
    %c4_i64 = arith.constant 4 : i64
    %c1_i64 = arith.constant 1 : i64
    %c0_i64 = arith.constant 0 : i64
    %c16_i32 = arith.constant 16 : i32
    %false = arith.constant false
    %14 = cute.static : !cute.layout<"((128,128),1,1,2):((65536,1),0,0,128)">
    %15 = cute.recast_layout<32, 32> (%14) : !cute.layout<"((128,128),1,1,2):((65536,1),0,0,128)"> to !cute.layout<"((128,128),1,1,2):((65536,1),0,0,128)">
    %atom = cute.make_atom() : () -> !cute_nvgpu.sm100.mma<128x128x8, num_cta = 1, ab_major = (k, k), elem_type = (tf32, tf32, f32), frag_kind = ss, c_scale_exp = 0>
    %16 = cute_nvgpu.atom.set_value(%atom, %false : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !cute_nvgpu.sm100.mma<128x128x8, num_cta = 1, ab_major = (k, k), elem_type = (tf32, tf32, f32), frag_kind = ss, c_scale_exp = 0>
    %17 = cute_nvgpu.atom.set_value(%16, %false : i1) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : !cute_nvgpu.sm100.mma<128x128x8, num_cta = 1, ab_major = (k, k), elem_type = (tf32, tf32, f32), frag_kind = ss, c_scale_exp = 0>
    %18 = cute_nvgpu.atom.set_value(%17, %false : i1) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : !cute_nvgpu.sm100.mma<128x128x8, num_cta = 1, ab_major = (k, k), elem_type = (tf32, tf32, f32), frag_kind = ss, c_scale_exp = 0>
    %19 = cute.make_tiled_mma(%18) : !mma_tf32_tf32_f32_128x128x8_
    %20 = llvm.alloca %c16_i32 x i64 {alignment = 64 : i64} : (i32) -> !llvm.ptr
    %iter = cute.get_iter(%arg0) : !memref_gmem_tf32_
    %lay = cute.get_layout(%arg0) : !memref_gmem_tf32_
    %21:5 = cute.get_scalars(%lay) <{only_dynamic}> : !cute.layout<"(?,?,?):(?{i64},1,?{i64})">
    %22 = arith.extui %21#1 : i32 to i64
    %23 = arith.extui %21#0 : i32 to i64
    %24 = llvm.mul %21#3, %c4_i64 : i64
    %25 = arith.extui %21#2 : i32 to i64
    %26 = llvm.mul %21#4, %c4_i64 : i64
    %27 = cute.ptrtoint(%iter) : !cute.ptr<tf32, gmem, align<16>> to i64
    %28 = llvm.getelementptr %20[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %28 : i64, !llvm.ptr
    %29 = llvm.getelementptr %20[0, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %29 : i64, !llvm.ptr
    %30 = llvm.getelementptr %20[0, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %30 : i64, !llvm.ptr
    %31 = llvm.getelementptr %20[0, 3] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %31 : i64, !llvm.ptr
    %32 = llvm.getelementptr %20[0, 4] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %32 : i64, !llvm.ptr
    %33 = llvm.getelementptr %20[0, 5] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %33 : i64, !llvm.ptr
    %34 = llvm.getelementptr %20[0, 6] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %34 : i64, !llvm.ptr
    %35 = llvm.getelementptr %20[0, 7] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %35 : i64, !llvm.ptr
    %36 = llvm.getelementptr %20[0, 8] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %36 : i64, !llvm.ptr
    %37 = llvm.getelementptr %20[0, 9] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %37 : i64, !llvm.ptr
    %38 = llvm.getelementptr %20[0, 10] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %38 : i64, !llvm.ptr
    %39 = llvm.getelementptr %20[0, 11] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %39 : i64, !llvm.ptr
    %40 = llvm.getelementptr %20[0, 12] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %40 : i64, !llvm.ptr
    %41 = llvm.getelementptr %20[0, 13] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %41 : i64, !llvm.ptr
    %42 = llvm.getelementptr %20[0, 14] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %42 : i64, !llvm.ptr
    %43 = llvm.getelementptr %20[0, 15] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %43 : i64, !llvm.ptr
    %44 = llvm.udiv %27, %c16_i64 : i64
    %45 = llvm.and %44, %c9007199254740991_i64 : i64
    %46 = llvm.shl %45, %c4_i64 : i64
    llvm.store %46, %28 : i64, !llvm.ptr
    %47 = llvm.sub %23, %c1_i64 : i64
    %48 = llvm.sub %25, %c1_i64 : i64
    %49 = llvm.sub %c1_i64, %c1_i64 : i64
    %50 = llvm.mul %47, %24 : i64
    %51 = llvm.mul %48, %26 : i64
    %52 = llvm.mul %49, %c0_i64 : i64
    %53 = llvm.add %50, %51 : i64
    %54 = llvm.add %52, %52 : i64
    %55 = llvm.mul %22, %c32_i64 : i64
    %56 = llvm.udiv %55, %c8_i64 : i64
    %57 = llvm.add %56, %53 : i64
    %58 = llvm.add %57, %54 : i64
    %59 = llvm.icmp "uge" %58, %c131072_i64 : i64
    %60 = llvm.zext %59 : i1 to i64
    %61 = llvm.shl %60, %c21_i64 : i64
    %62 = llvm.udiv %24, %c16_i64 : i64
    %63 = llvm.shl %62, %c32_i64 : i64
    %64 = llvm.or %c0_i64, %61 : i64
    %65 = llvm.or %64, %63 : i64
    %66 = llvm.or %4, %65 : i64
    llvm.store %66, %29 : i64, !llvm.ptr
    %67 = llvm.udiv %26, %c16_i64 : i64
    %68 = llvm.and %67, %c4294967295_i64 : i64
    %69 = llvm.shl %68, %c0_i64 : i64
    %70 = llvm.udiv %c0_i64, %c16_i64 : i64
    %71 = llvm.shl %70, %c32_i64 : i64
    %72 = llvm.or %69, %71 : i64
    llvm.store %72, %30 : i64, !llvm.ptr
    %73 = llvm.and %70, %c4294967295_i64 : i64
    %74 = llvm.shl %73, %c0_i64 : i64
    %75 = llvm.lshr %24, %c36_i64 : i64
    %76 = llvm.and %75, %c15_i64 : i64
    %77 = llvm.shl %76, %c32_i64 : i64
    %78 = llvm.lshr %26, %c36_i64 : i64
    %79 = llvm.and %78, %c15_i64 : i64
    %80 = llvm.shl %79, %c36_i64 : i64
    %81 = llvm.lshr %c0_i64, %c36_i64 : i64
    %82 = llvm.and %81, %c15_i64 : i64
    %83 = llvm.shl %82, %c40_i64 : i64
    %84 = llvm.shl %81, %c44_i64 : i64
    %85 = llvm.or %77, %80 : i64
    %86 = llvm.or %83, %84 : i64
    %87 = llvm.or %85, %86 : i64
    %88 = llvm.or %74, %87 : i64
    llvm.store %88, %31 : i64, !llvm.ptr
    %89 = llvm.sub %22, %c1_i64 : i64
    %90 = llvm.and %89, %c4294967295_i64 : i64
    %91 = llvm.shl %90, %c0_i64 : i64
    %92 = llvm.shl %47, %c32_i64 : i64
    %93 = llvm.or %91, %92 : i64
    llvm.store %93, %32 : i64, !llvm.ptr
    %94 = llvm.and %48, %c4294967295_i64 : i64
    %95 = llvm.shl %94, %c0_i64 : i64
    %96 = llvm.shl %49, %c32_i64 : i64
    %97 = llvm.or %95, %96 : i64
    llvm.store %97, %33 : i64, !llvm.ptr
    %98 = llvm.and %49, %c4294967295_i64 : i64
    %99 = llvm.or %98, %c0_i64 : i64
    %100 = llvm.or %99, %3 : i64
    llvm.store %100, %34 : i64, !llvm.ptr
    llvm.store %2, %35 : i64, !llvm.ptr
    %101 = builtin.unrealized_conversion_cast %20 : !llvm.ptr to !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>>
    %102 = cute.ptrtoint(%101) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>> to i64
    %103 = llvm.inttoptr %102 : i64 to !llvm.ptr
    %104 = llvm.load %103 {nontemporal} : !llvm.ptr -> !llvm.struct<(array<16 x i64>)>
    %105 = builtin.unrealized_conversion_cast %104 : !llvm.struct<(array<16 x i64>)> to !cute_nvgpu.tma_descriptor_tiled
    %atom_0 = cute.make_atom() : () -> !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, tf32, copy_bits = 131072, tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">, internal_val_type = tf32>
    %106 = cute_nvgpu.atom.set_value(%atom_0, %105 : !cute_nvgpu.tma_descriptor_tiled) {field = #cute_nvgpu.atom_copy_field_non_exec_tma_load<tma_desc>} : !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, tf32, copy_bits = 131072, tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">, internal_val_type = tf32>
    %107 = cute.get_shape(%lay) : (!cute.layout<"(?,?,?):(?{i64},1,?{i64})">) -> !cute.shape<"(?,?,?)">
    %lay_1 = cute.make_layout(%107, %13) : !cute.layout<"(?,?,?):(1@1,1@0,1@2)">
    %view = cute.make_view(%12, %lay_1) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">
    %108 = llvm.alloca %c16_i32 x i64 {alignment = 64 : i64} : (i32) -> !llvm.ptr
    %iter_2 = cute.get_iter(%arg1) : !memref_gmem_tf32_
    %lay_3 = cute.get_layout(%arg1) : !memref_gmem_tf32_
    %109:5 = cute.get_scalars(%lay_3) <{only_dynamic}> : !cute.layout<"(?,?,?):(?{i64},1,?{i64})">
    %110 = arith.extui %109#1 : i32 to i64
    %111 = arith.extui %109#0 : i32 to i64
    %112 = llvm.mul %109#3, %c4_i64 : i64
    %113 = arith.extui %109#2 : i32 to i64
    %114 = llvm.mul %109#4, %c4_i64 : i64
    %115 = cute.ptrtoint(%iter_2) : !cute.ptr<tf32, gmem, align<16>> to i64
    %116 = llvm.getelementptr %108[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %116 : i64, !llvm.ptr
    %117 = llvm.getelementptr %108[0, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %117 : i64, !llvm.ptr
    %118 = llvm.getelementptr %108[0, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %118 : i64, !llvm.ptr
    %119 = llvm.getelementptr %108[0, 3] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %119 : i64, !llvm.ptr
    %120 = llvm.getelementptr %108[0, 4] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %120 : i64, !llvm.ptr
    %121 = llvm.getelementptr %108[0, 5] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %121 : i64, !llvm.ptr
    %122 = llvm.getelementptr %108[0, 6] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %122 : i64, !llvm.ptr
    %123 = llvm.getelementptr %108[0, 7] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %123 : i64, !llvm.ptr
    %124 = llvm.getelementptr %108[0, 8] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %124 : i64, !llvm.ptr
    %125 = llvm.getelementptr %108[0, 9] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %125 : i64, !llvm.ptr
    %126 = llvm.getelementptr %108[0, 10] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %126 : i64, !llvm.ptr
    %127 = llvm.getelementptr %108[0, 11] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %127 : i64, !llvm.ptr
    %128 = llvm.getelementptr %108[0, 12] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %128 : i64, !llvm.ptr
    %129 = llvm.getelementptr %108[0, 13] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %129 : i64, !llvm.ptr
    %130 = llvm.getelementptr %108[0, 14] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %130 : i64, !llvm.ptr
    %131 = llvm.getelementptr %108[0, 15] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %131 : i64, !llvm.ptr
    %132 = llvm.udiv %115, %c16_i64 : i64
    %133 = llvm.and %132, %c9007199254740991_i64 : i64
    %134 = llvm.shl %133, %c4_i64 : i64
    llvm.store %134, %116 : i64, !llvm.ptr
    %135 = llvm.sub %111, %c1_i64 : i64
    %136 = llvm.sub %113, %c1_i64 : i64
    %137 = llvm.mul %135, %112 : i64
    %138 = llvm.mul %136, %114 : i64
    %139 = llvm.add %137, %138 : i64
    %140 = llvm.mul %110, %c32_i64 : i64
    %141 = llvm.udiv %140, %c8_i64 : i64
    %142 = llvm.add %141, %139 : i64
    %143 = llvm.add %142, %54 : i64
    %144 = llvm.icmp "uge" %143, %c131072_i64 : i64
    %145 = llvm.zext %144 : i1 to i64
    %146 = llvm.shl %145, %c21_i64 : i64
    %147 = llvm.udiv %112, %c16_i64 : i64
    %148 = llvm.shl %147, %c32_i64 : i64
    %149 = llvm.or %c0_i64, %146 : i64
    %150 = llvm.or %149, %148 : i64
    %151 = llvm.or %4, %150 : i64
    llvm.store %151, %117 : i64, !llvm.ptr
    %152 = llvm.udiv %114, %c16_i64 : i64
    %153 = llvm.and %152, %c4294967295_i64 : i64
    %154 = llvm.shl %153, %c0_i64 : i64
    %155 = llvm.or %154, %71 : i64
    llvm.store %155, %118 : i64, !llvm.ptr
    %156 = llvm.lshr %112, %c36_i64 : i64
    %157 = llvm.and %156, %c15_i64 : i64
    %158 = llvm.shl %157, %c32_i64 : i64
    %159 = llvm.lshr %114, %c36_i64 : i64
    %160 = llvm.and %159, %c15_i64 : i64
    %161 = llvm.shl %160, %c36_i64 : i64
    %162 = llvm.or %158, %161 : i64
    %163 = llvm.or %162, %86 : i64
    %164 = llvm.or %74, %163 : i64
    llvm.store %164, %119 : i64, !llvm.ptr
    %165 = llvm.sub %110, %c1_i64 : i64
    %166 = llvm.and %165, %c4294967295_i64 : i64
    %167 = llvm.shl %166, %c0_i64 : i64
    %168 = llvm.shl %135, %c32_i64 : i64
    %169 = llvm.or %167, %168 : i64
    llvm.store %169, %120 : i64, !llvm.ptr
    %170 = llvm.and %136, %c4294967295_i64 : i64
    %171 = llvm.shl %170, %c0_i64 : i64
    %172 = llvm.or %171, %96 : i64
    llvm.store %172, %121 : i64, !llvm.ptr
    llvm.store %100, %122 : i64, !llvm.ptr
    llvm.store %2, %123 : i64, !llvm.ptr
    %173 = builtin.unrealized_conversion_cast %108 : !llvm.ptr to !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>>
    %174 = cute.ptrtoint(%173) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>> to i64
    %175 = llvm.inttoptr %174 : i64 to !llvm.ptr
    %176 = llvm.load %175 {nontemporal} : !llvm.ptr -> !llvm.struct<(array<16 x i64>)>
    %177 = builtin.unrealized_conversion_cast %176 : !llvm.struct<(array<16 x i64>)> to !cute_nvgpu.tma_descriptor_tiled
    %178 = cute_nvgpu.atom.set_value(%atom_0, %177 : !cute_nvgpu.tma_descriptor_tiled) {field = #cute_nvgpu.atom_copy_field_non_exec_tma_load<tma_desc>} : !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, tf32, copy_bits = 131072, tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">, internal_val_type = tf32>
    %179 = cute.get_shape(%lay_3) : (!cute.layout<"(?,?,?):(?{i64},1,?{i64})">) -> !cute.shape<"(?,?,?)">
    %lay_4 = cute.make_layout(%179, %13) : !cute.layout<"(?,?,?):(1@1,1@0,1@2)">
    %view_5 = cute.make_view(%12, %lay_4) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">
    %180 = llvm.alloca %c16_i32 x i64 {alignment = 64 : i64} : (i32) -> !llvm.ptr
    %iter_6 = cute.get_iter(%arg3) : !memref_gmem_f32_
    %lay_7 = cute.get_layout(%arg3) : !memref_gmem_f32_
    %181:5 = cute.get_scalars(%lay_7) <{only_dynamic}> : !cute.layout<"(?,?,?):(?{i64},1,?{i64})">
    %182 = arith.extui %181#1 : i32 to i64
    %183 = arith.extui %181#0 : i32 to i64
    %184 = llvm.mul %181#3, %c4_i64 : i64
    %185 = arith.extui %181#2 : i32 to i64
    %186 = llvm.mul %181#4, %c4_i64 : i64
    %187 = cute.ptrtoint(%iter_6) : !cute.ptr<f32, gmem, align<16>> to i64
    %188 = llvm.getelementptr %180[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %188 : i64, !llvm.ptr
    %189 = llvm.getelementptr %180[0, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %189 : i64, !llvm.ptr
    %190 = llvm.getelementptr %180[0, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %190 : i64, !llvm.ptr
    %191 = llvm.getelementptr %180[0, 3] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %191 : i64, !llvm.ptr
    %192 = llvm.getelementptr %180[0, 4] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %192 : i64, !llvm.ptr
    %193 = llvm.getelementptr %180[0, 5] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %193 : i64, !llvm.ptr
    %194 = llvm.getelementptr %180[0, 6] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %194 : i64, !llvm.ptr
    %195 = llvm.getelementptr %180[0, 7] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %195 : i64, !llvm.ptr
    %196 = llvm.getelementptr %180[0, 8] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %196 : i64, !llvm.ptr
    %197 = llvm.getelementptr %180[0, 9] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %197 : i64, !llvm.ptr
    %198 = llvm.getelementptr %180[0, 10] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %198 : i64, !llvm.ptr
    %199 = llvm.getelementptr %180[0, 11] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %199 : i64, !llvm.ptr
    %200 = llvm.getelementptr %180[0, 12] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %200 : i64, !llvm.ptr
    %201 = llvm.getelementptr %180[0, 13] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %201 : i64, !llvm.ptr
    %202 = llvm.getelementptr %180[0, 14] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %202 : i64, !llvm.ptr
    %203 = llvm.getelementptr %180[0, 15] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %203 : i64, !llvm.ptr
    %204 = llvm.udiv %187, %c16_i64 : i64
    %205 = llvm.and %204, %c9007199254740991_i64 : i64
    %206 = llvm.shl %205, %c4_i64 : i64
    llvm.store %206, %188 : i64, !llvm.ptr
    %207 = llvm.sub %183, %c1_i64 : i64
    %208 = llvm.sub %185, %c1_i64 : i64
    %209 = llvm.mul %207, %184 : i64
    %210 = llvm.mul %208, %186 : i64
    %211 = llvm.add %209, %210 : i64
    %212 = llvm.mul %182, %c32_i64 : i64
    %213 = llvm.udiv %212, %c8_i64 : i64
    %214 = llvm.add %213, %211 : i64
    %215 = llvm.add %214, %54 : i64
    %216 = llvm.icmp "uge" %215, %c131072_i64 : i64
    %217 = llvm.zext %216 : i1 to i64
    %218 = llvm.shl %217, %c21_i64 : i64
    %219 = llvm.udiv %184, %c16_i64 : i64
    %220 = llvm.shl %219, %c32_i64 : i64
    %221 = llvm.or %c0_i64, %218 : i64
    %222 = llvm.or %221, %220 : i64
    %223 = llvm.or %1, %222 : i64
    llvm.store %223, %189 : i64, !llvm.ptr
    %224 = llvm.udiv %186, %c16_i64 : i64
    %225 = llvm.and %224, %c4294967295_i64 : i64
    %226 = llvm.shl %225, %c0_i64 : i64
    %227 = llvm.or %226, %71 : i64
    llvm.store %227, %190 : i64, !llvm.ptr
    %228 = llvm.lshr %184, %c36_i64 : i64
    %229 = llvm.and %228, %c15_i64 : i64
    %230 = llvm.shl %229, %c32_i64 : i64
    %231 = llvm.lshr %186, %c36_i64 : i64
    %232 = llvm.and %231, %c15_i64 : i64
    %233 = llvm.shl %232, %c36_i64 : i64
    %234 = llvm.or %230, %233 : i64
    %235 = llvm.or %234, %86 : i64
    %236 = llvm.or %74, %235 : i64
    llvm.store %236, %191 : i64, !llvm.ptr
    %237 = llvm.sub %182, %c1_i64 : i64
    %238 = llvm.and %237, %c4294967295_i64 : i64
    %239 = llvm.shl %238, %c0_i64 : i64
    %240 = llvm.shl %207, %c32_i64 : i64
    %241 = llvm.or %239, %240 : i64
    llvm.store %241, %192 : i64, !llvm.ptr
    %242 = llvm.and %208, %c4294967295_i64 : i64
    %243 = llvm.shl %242, %c0_i64 : i64
    %244 = llvm.or %243, %96 : i64
    llvm.store %244, %193 : i64, !llvm.ptr
    %245 = llvm.or %99, %0 : i64
    llvm.store %245, %194 : i64, !llvm.ptr
    llvm.store %2, %195 : i64, !llvm.ptr
    %246 = builtin.unrealized_conversion_cast %180 : !llvm.ptr to !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>>
    %247 = cute.ptrtoint(%246) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>> to i64
    %248 = llvm.inttoptr %247 : i64 to !llvm.ptr
    %249 = llvm.load %248 {nontemporal} : !llvm.ptr -> !llvm.struct<(array<16 x i64>)>
    %250 = builtin.unrealized_conversion_cast %249 : !llvm.struct<(array<16 x i64>)> to !cute_nvgpu.tma_descriptor_tiled
    %atom_8 = cute.make_atom() : () -> !cute_nvgpu.atom.non_exec_tiled_tma_store<f32, copy_bits = 65536, tma_gbasis = <"(16,128,1):(1@1,1@0,1@2)">, internal_val_type = f32>
    %251 = cute_nvgpu.atom.set_value(%atom_8, %250 : !cute_nvgpu.tma_descriptor_tiled) {field = #cute_nvgpu.atom_copy_field_non_exec_tma_store<tma_desc>} : !cute_nvgpu.atom.non_exec_tiled_tma_store<f32, copy_bits = 65536, tma_gbasis = <"(16,128,1):(1@1,1@0,1@2)">, internal_val_type = f32>
    %252 = cute.get_shape(%lay_7) : (!cute.layout<"(?,?,?):(?{i64},1,?{i64})">) -> !cute.shape<"(?,?,?)">
    %lay_9 = cute.make_layout(%252, %13) : !cute.layout<"(?,?,?):(1@1,1@0,1@2)">
    %view_10 = cute.make_view(%12, %lay_9) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">
    %253 = llvm.alloca %c16_i32 x i64 {alignment = 64 : i64} : (i32) -> !llvm.ptr
    %iter_11 = cute.get_iter(%arg2) : !memref_gmem_f32_
    %lay_12 = cute.get_layout(%arg2) : !memref_gmem_f32_
    %254:5 = cute.get_scalars(%lay_12) <{only_dynamic}> : !cute.layout<"(?,?,?):(?{i64},1,?{i64})">
    %255 = arith.extui %254#1 : i32 to i64
    %256 = arith.extui %254#0 : i32 to i64
    %257 = llvm.mul %254#3, %c4_i64 : i64
    %258 = arith.extui %254#2 : i32 to i64
    %259 = llvm.mul %254#4, %c4_i64 : i64
    %260 = cute.ptrtoint(%iter_11) : !cute.ptr<f32, gmem, align<16>> to i64
    %261 = llvm.getelementptr %253[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %261 : i64, !llvm.ptr
    %262 = llvm.getelementptr %253[0, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %262 : i64, !llvm.ptr
    %263 = llvm.getelementptr %253[0, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %263 : i64, !llvm.ptr
    %264 = llvm.getelementptr %253[0, 3] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %264 : i64, !llvm.ptr
    %265 = llvm.getelementptr %253[0, 4] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %265 : i64, !llvm.ptr
    %266 = llvm.getelementptr %253[0, 5] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %266 : i64, !llvm.ptr
    %267 = llvm.getelementptr %253[0, 6] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %267 : i64, !llvm.ptr
    %268 = llvm.getelementptr %253[0, 7] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %268 : i64, !llvm.ptr
    %269 = llvm.getelementptr %253[0, 8] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %269 : i64, !llvm.ptr
    %270 = llvm.getelementptr %253[0, 9] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %270 : i64, !llvm.ptr
    %271 = llvm.getelementptr %253[0, 10] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %271 : i64, !llvm.ptr
    %272 = llvm.getelementptr %253[0, 11] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %272 : i64, !llvm.ptr
    %273 = llvm.getelementptr %253[0, 12] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %273 : i64, !llvm.ptr
    %274 = llvm.getelementptr %253[0, 13] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %274 : i64, !llvm.ptr
    %275 = llvm.getelementptr %253[0, 14] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %275 : i64, !llvm.ptr
    %276 = llvm.getelementptr %253[0, 15] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %276 : i64, !llvm.ptr
    %277 = llvm.udiv %260, %c16_i64 : i64
    %278 = llvm.and %277, %c9007199254740991_i64 : i64
    %279 = llvm.shl %278, %c4_i64 : i64
    llvm.store %279, %261 : i64, !llvm.ptr
    %280 = llvm.sub %256, %c1_i64 : i64
    %281 = llvm.sub %258, %c1_i64 : i64
    %282 = llvm.mul %280, %257 : i64
    %283 = llvm.mul %281, %259 : i64
    %284 = llvm.add %282, %283 : i64
    %285 = llvm.mul %255, %c32_i64 : i64
    %286 = llvm.udiv %285, %c8_i64 : i64
    %287 = llvm.add %286, %284 : i64
    %288 = llvm.add %287, %54 : i64
    %289 = llvm.icmp "uge" %288, %c131072_i64 : i64
    %290 = llvm.zext %289 : i1 to i64
    %291 = llvm.shl %290, %c21_i64 : i64
    %292 = llvm.udiv %257, %c16_i64 : i64
    %293 = llvm.shl %292, %c32_i64 : i64
    %294 = llvm.or %c0_i64, %291 : i64
    %295 = llvm.or %294, %293 : i64
    %296 = llvm.or %1, %295 : i64
    llvm.store %296, %262 : i64, !llvm.ptr
    %297 = llvm.udiv %259, %c16_i64 : i64
    %298 = llvm.and %297, %c4294967295_i64 : i64
    %299 = llvm.shl %298, %c0_i64 : i64
    %300 = llvm.or %299, %71 : i64
    llvm.store %300, %263 : i64, !llvm.ptr
    %301 = llvm.lshr %257, %c36_i64 : i64
    %302 = llvm.and %301, %c15_i64 : i64
    %303 = llvm.shl %302, %c32_i64 : i64
    %304 = llvm.lshr %259, %c36_i64 : i64
    %305 = llvm.and %304, %c15_i64 : i64
    %306 = llvm.shl %305, %c36_i64 : i64
    %307 = llvm.or %303, %306 : i64
    %308 = llvm.or %307, %86 : i64
    %309 = llvm.or %74, %308 : i64
    llvm.store %309, %264 : i64, !llvm.ptr
    %310 = llvm.sub %255, %c1_i64 : i64
    %311 = llvm.and %310, %c4294967295_i64 : i64
    %312 = llvm.shl %311, %c0_i64 : i64
    %313 = llvm.shl %280, %c32_i64 : i64
    %314 = llvm.or %312, %313 : i64
    llvm.store %314, %265 : i64, !llvm.ptr
    %315 = llvm.and %281, %c4294967295_i64 : i64
    %316 = llvm.shl %315, %c0_i64 : i64
    %317 = llvm.or %316, %96 : i64
    llvm.store %317, %266 : i64, !llvm.ptr
    llvm.store %245, %267 : i64, !llvm.ptr
    llvm.store %2, %268 : i64, !llvm.ptr
    %318 = builtin.unrealized_conversion_cast %253 : !llvm.ptr to !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>>
    %319 = cute.ptrtoint(%318) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>> to i64
    %320 = llvm.inttoptr %319 : i64 to !llvm.ptr
    %321 = llvm.load %320 {nontemporal} : !llvm.ptr -> !llvm.struct<(array<16 x i64>)>
    %322 = builtin.unrealized_conversion_cast %321 : !llvm.struct<(array<16 x i64>)> to !cute_nvgpu.tma_descriptor_tiled
    %atom_13 = cute.make_atom() : () -> !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f32, copy_bits = 65536, tma_gbasis = <"(16,128,1):(1@1,1@0,1@2)">, internal_val_type = f32>
    %323 = cute_nvgpu.atom.set_value(%atom_13, %322 : !cute_nvgpu.tma_descriptor_tiled) {field = #cute_nvgpu.atom_copy_field_non_exec_tma_load<tma_desc>} : !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f32, copy_bits = 65536, tma_gbasis = <"(16,128,1):(1@1,1@0,1@2)">, internal_val_type = f32>
    %324 = cute.get_shape(%lay_12) : (!cute.layout<"(?,?,?):(?{i64},1,?{i64})">) -> !cute.shape<"(?,?,?)">
    %lay_14 = cute.make_layout(%324, %13) : !cute.layout<"(?,?,?):(1@1,1@0,1@2)">
    %view_15 = cute.make_view(%12, %lay_14) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">
    %325 = arith.ceildivsi %181#0, %c128_i32 : i32
    %326 = arith.muli %181#3, %c128_i64 : i64
    %327 = arith.ceildivsi %181#1, %c128_i32 : i32
    %shape = cute.make_shape(%325, %327, %181#2) : (i32, i32, i32) -> !cute.shape<"((128,128),(?,?,?))">
    %iv = cute.assume(%326) : (i64) -> !cute.i64<divby 128>
    %stride = cute.make_stride(%181#3, %iv, %181#4) : (i64, !cute.i64<divby 128>, i64) -> !cute.stride<"((?{i64},1),(?{i64 div=128},128,?{i64}))">
    %lay_16 = cute.make_layout(%shape, %stride) : !cute.layout<"((128,128),(?,?,?)):((?{i64},1),(?{i64 div=128},128,?{i64}))">
    %328:6 = cute.get_scalars(%lay_16) <{only_dynamic}> : !cute.layout<"((128,128),(?,?,?)):((?{i64},1),(?{i64 div=128},128,?{i64}))">
    %shape_17 = cute.make_shape(%328#0, %328#1, %328#2) : (i32, i32, i32) -> !cute.shape<"(?,?,?)">
    %iv_18 = cute.assume(%328#4) : (i64) -> !cute.i64<divby 128>
    %stride_19 = cute.make_stride(%iv_18, %328#5) : (!cute.i64<divby 128>, i64) -> !cute.stride<"(?{i64 div=128},128,?{i64})">
    %lay_20 = cute.make_layout(%shape_17, %stride_19) : !cute.layout<"(?,?,?):(?{i64 div=128},128,?{i64})">
    %329 = cute.get_shape(%lay_20) : (!cute.layout<"(?,?,?):(?{i64 div=128},128,?{i64})">) -> !cute.shape<"(?,?,?)">
    %e0, %e1, %e2 = cute.get_leaves(%329) : !cute.shape<"(?,?,?)">
    %itup = cute.to_int_tuple(%e0) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %330 = cute.get_scalars(%itup) : !cute.int_tuple<"?">
    %itup_21 = cute.to_int_tuple(%e1) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %331 = cute.get_scalars(%itup_21) : !cute.int_tuple<"?">
    %itup_22 = cute.to_int_tuple(%e2) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %332 = cute.get_scalars(%itup_22) : !cute.int_tuple<"?">
    %int_tuple = cute.make_int_tuple(%itup, %itup_21, %itup_22) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?,?,?)">
    %333:3 = cute.get_scalars(%int_tuple) <{only_dynamic}> : !cute.int_tuple<"(?,?,?)">
    %int_tuple_23 = cute.make_int_tuple(%333#0, %333#1, %333#2) : (i32, i32, i32) -> !cute.int_tuple<"(?,?,?)">
    %e0_24, %e1_25, %e2_26 = cute.get_leaves(%int_tuple_23) : !cute.int_tuple<"(?,?,?)">
    %shape_27 = cute.make_shape(%e0_24, %e1_25, %e2_26) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.shape<"(?,?,?)">
    %lay_28 = cute.make_layout(%shape_27) : !cute.layout<"(?,?,?):(1,?,?)">
    %sz = cute.size(%lay_28) : (!cute.layout<"(?,?,?):(1,?,?)">) -> !cute.int_tuple<"?">
    %e0_29 = cute.get_leaves(%sz) : !cute.int_tuple<"?">
    %334 = cute.get_scalars(%e0_29) : !cute.int_tuple<"?">
    %335 = cute.get_shape(%lay_28) : (!cute.layout<"(?,?,?):(1,?,?)">) -> !cute.shape<"(?,?,?)">
    %e0_30, %e1_31, %e2_32 = cute.get_leaves(%335) : !cute.shape<"(?,?,?)">
    %itup_33 = cute.to_int_tuple(%e0_30) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %336 = cute.get_scalars(%itup_33) : !cute.int_tuple<"?">
    %itup_34 = cute.to_int_tuple(%e1_31) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %337 = cute.get_scalars(%itup_34) : !cute.int_tuple<"?">
    %338 = arith.cmpi eq, %334, %11 : i32
    %339 = scf.if %338 -> (i8) {
      scf.yield %10 : i8
    } else {
      %388 = arith.cmpi uge, %334, %c-2147483648_i32 : i32
      %389 = scf.if %388 -> (i8) {
        scf.yield %9 : i8
      } else {
        %390:2 = scf.while (%arg7 = %8, %arg8 = %7) : (i32, i8) -> (i32, i8) {
          %391 = arith.cmpi ult, %arg7, %334 : i32
          scf.condition(%391) %arg7, %arg8 : i32, i8
        } do {
        ^bb0(%arg7: i32, %arg8: i8):
          %391 = arith.muli %arg7, %8 : i32
          %392 = arith.addi %arg8, %7 : i8
          scf.yield %391, %392 : i32, i8
        }
        scf.yield %390#1 : i8
      }
      scf.yield %389 : i8
    }
    %340 = arith.extui %339 : i8 to i64
    %341 = arith.extui %334 : i32 to i64
    %342 = arith.shli %6, %340 : i64
    %343 = arith.subi %342, %341 : i64
    %344 = arith.muli %343, %c4294967296_i64 : i64
    %345 = arith.divui %344, %341 : i64
    %346 = arith.addi %345, %6 : i64
    %347 = arith.trunci %346 : i64 to i32
    %348 = arith.minui %339, %7 : i8
    %349 = arith.cmpi ult, %339, %7 : i8
    %350 = arith.subi %339, %7 : i8
    %351 = arith.select %349, %10, %350 : i8
    %352 = cute.fast_divmod.make_divisor(%334, %347, %348, %351) : i32 -> !cute.fast_divmod_divisor<32>
    %353 = arith.cmpi eq, %336, %11 : i32
    %354 = scf.if %353 -> (i8) {
      scf.yield %10 : i8
    } else {
      %388 = arith.cmpi uge, %336, %c-2147483648_i32 : i32
      %389 = scf.if %388 -> (i8) {
        scf.yield %9 : i8
      } else {
        %390:2 = scf.while (%arg7 = %8, %arg8 = %7) : (i32, i8) -> (i32, i8) {
          %391 = arith.cmpi ult, %arg7, %336 : i32
          scf.condition(%391) %arg7, %arg8 : i32, i8
        } do {
        ^bb0(%arg7: i32, %arg8: i8):
          %391 = arith.muli %arg7, %8 : i32
          %392 = arith.addi %arg8, %7 : i8
          scf.yield %391, %392 : i32, i8
        }
        scf.yield %390#1 : i8
      }
      scf.yield %389 : i8
    }
    %355 = arith.extui %354 : i8 to i64
    %356 = arith.extui %336 : i32 to i64
    %357 = arith.shli %6, %355 : i64
    %358 = arith.subi %357, %356 : i64
    %359 = arith.muli %358, %c4294967296_i64 : i64
    %360 = arith.divui %359, %356 : i64
    %361 = arith.addi %360, %6 : i64
    %362 = arith.trunci %361 : i64 to i32
    %363 = arith.minui %354, %7 : i8
    %364 = arith.cmpi ult, %354, %7 : i8
    %365 = arith.subi %354, %7 : i8
    %366 = arith.select %364, %10, %365 : i8
    %367 = cute.fast_divmod.make_divisor(%336, %362, %363, %366) : i32 -> !cute.fast_divmod_divisor<32>
    %368 = arith.cmpi eq, %337, %11 : i32
    %369 = scf.if %368 -> (i8) {
      scf.yield %10 : i8
    } else {
      %388 = arith.cmpi uge, %337, %c-2147483648_i32 : i32
      %389 = scf.if %388 -> (i8) {
        scf.yield %9 : i8
      } else {
        %390:2 = scf.while (%arg7 = %8, %arg8 = %7) : (i32, i8) -> (i32, i8) {
          %391 = arith.cmpi ult, %arg7, %337 : i32
          scf.condition(%391) %arg7, %arg8 : i32, i8
        } do {
        ^bb0(%arg7: i32, %arg8: i8):
          %391 = arith.muli %arg7, %8 : i32
          %392 = arith.addi %arg8, %7 : i8
          scf.yield %391, %392 : i32, i8
        }
        scf.yield %390#1 : i8
      }
      scf.yield %389 : i8
    }
    %370 = arith.extui %369 : i8 to i64
    %371 = arith.extui %337 : i32 to i64
    %372 = arith.shli %6, %370 : i64
    %373 = arith.subi %372, %371 : i64
    %374 = arith.muli %373, %c4294967296_i64 : i64
    %375 = arith.divui %374, %371 : i64
    %376 = arith.addi %375, %6 : i64
    %377 = arith.trunci %376 : i64 to i32
    %378 = arith.minui %369, %7 : i8
    %379 = arith.cmpi ult, %369, %7 : i8
    %380 = arith.subi %369, %7 : i8
    %381 = arith.select %379, %10, %380 : i8
    %382 = cute.fast_divmod.make_divisor(%337, %377, %378, %381) : i32 -> !cute.fast_divmod_divisor<32>
    %int_tuple_35 = cute.make_int_tuple(%itup_33) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
    %sz_36 = cute.size(%int_tuple_35) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
    %e0_37 = cute.get_leaves(%sz_36) : !cute.int_tuple<"?">
    %mul = cute.tuple_mul(%e0_37, %5) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
    %int_tuple_38 = cute.make_int_tuple(%itup_34) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
    %sz_39 = cute.size(%int_tuple_38) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
    %e0_40 = cute.get_leaves(%sz_39) : !cute.int_tuple<"?">
    %mul_41 = cute.tuple_mul(%e0_40, %5) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
    %itup_42 = cute.to_int_tuple(%e2_32) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %int_tuple_43 = cute.make_int_tuple(%mul, %mul_41, %itup_42) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?,?,?)">
    %sz_44 = cute.size(%int_tuple_43) : (!cute.int_tuple<"(?,?,?)">) -> !cute.int_tuple<"?">
    %e0_45 = cute.get_leaves(%sz_44) : !cute.int_tuple<"?">
    %383 = cute.get_scalars(%e0_45) : !cute.int_tuple<"?">
    %384 = arith.minsi %383, %c1_i32 : i32
    %385 = cuda.launch_cfg.create<max_attrs = 2 : i32> (blockDim = (%c224_i32, %c1_i32, %c1_i32), dynamicSmemBytes = %c230400_i64, gridDim = (%c1_i32, %c1_i32, %384), stream = %arg6) : i32, i32, i32, i64, i32, i32, i32, !cuda.stream -> !cuda.launch_cfg<max_attrs = 2>
    cuda.launch_cfg.cluster_dim[%385] (%c1_i32, %c1_i32, %c1_i32) : !cuda.launch_cfg<max_attrs = 2>, i32, i32, i32
    %386 = cuda.launch_ex @kernels::@kernel_cutlass_kernel___main__SM100PersistentDenseGemmAlphaBetaKernel_object_at__TiledMMA_ThrLayoutVMNK11110000_PermutationMNK____MMAAtom_ThrID10_ShapeMNK1281288_TVLayoutA112881281128_TVL_0<%385> (%19, %106, %view, %178, %view_5, %323, %view_15, %251, %view_10, %330, %331, %332, %352, %367, %382, %arg4, %arg5) : !cuda.launch_cfg<max_attrs = 2>, (!mma_tf32_tf32_f32_128x128x8_, !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, tf32, copy_bits = 131072, tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">, internal_val_type = tf32>, !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">, !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, tf32, copy_bits = 131072, tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">, internal_val_type = tf32>, !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">, !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f32, copy_bits = 65536, tma_gbasis = <"(16,128,1):(1@1,1@0,1@2)">, internal_val_type = f32>, !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">, !cute_nvgpu.atom.non_exec_tiled_tma_store<f32, copy_bits = 65536, tma_gbasis = <"(16,128,1):(1@1,1@0,1@2)">, internal_val_type = f32>, !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">, i32, i32, i32, !cute.fast_divmod_divisor<32>, !cute.fast_divmod_divisor<32>, !cute.fast_divmod_divisor<32>, f32, f32) -> !cuda.result
    %387 = cuda.cast %386 : !cuda.result -> i32
    cuda.return_if_error %387 : i32
    return %c0_i32 : i32
  }
}
