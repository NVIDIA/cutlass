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
    func.func public @kernel_cutlass_kernel___main__SM100PersistentDenseGemmAlphaBetaKernel_object_at__TiledMMA_ThrLayoutVMNK11110000_PermutationMNK____MMAAtom_ThrID10_ShapeMNK1281288_TVLayoutA112881281128_TVL_0(%arg0: !mma_tf32_tf32_f32_128x128x8_, %arg1: !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, tf32, copy_bits = 131072, tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">, internal_val_type = tf32>, %arg2: !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">, %arg3: !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, tf32, copy_bits = 131072, tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">, internal_val_type = tf32>, %arg4: !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">, %arg5: !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f32, copy_bits = 65536, tma_gbasis = <"(16,128,1):(1@1,1@0,1@2)">, internal_val_type = f32>, %arg6: !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">, %arg7: !cute_nvgpu.atom.non_exec_tiled_tma_store<f32, copy_bits = 65536, tma_gbasis = <"(16,128,1):(1@1,1@0,1@2)">, internal_val_type = f32>, %arg8: !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">, %arg9: i32, %arg10: i32, %arg11: i32, %arg12: f32, %arg13: f32) attributes {cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 224, 1, 1>} {
      %0 = builtin.unrealized_conversion_cast %arg0 : !mma_tf32_tf32_f32_128x128x8_ to !llvm.struct<(i1, i1, i1)>
      %c8192_i32 = arith.constant 8192 : i32
      %1 = cute.static : !cute.layout<"(((16,128),1),(1,8)):(((1@0,1@1),0),(0,16@0))">
      %2 = cute.static : !cute.layout<"((2048,1),(1,2)):((1,0),(0,2048))">
      %3 = cute.static : !cute.int_tuple<"12">
      %4 = cute.static : !cute.int_tuple<"8">
      %5 = cute.static : !cute.layout<"((1,16),1,1,(1,2)):((0,1),0,0,(0,2048))">
      %6 = cute.static : !cute.layout<"(((16,32),1),1,1,(1,8)):(((1,65536),0),0,0,(0,16))">
      %c8_i32 = arith.constant 8 : i32
      %7 = cute.static : !cute.layout<"(((16,32),1),1,1,1,8,2):(((1,65536),0),0,0,0,16,128)">
      %8 = cute.static : !cute.stride<"(((1@0,1@1),0),0,16@0,128@1,128@0,1@2)">
      %9 = cute.static : !cute.stride<"((1@1,1@0),0,16@0,128@1,128@0,1@2)">
      %10 = cute.static : !cute.stride<"(1@1,1@0,0,16@0,128@1,128@0,1@2)">
      %c512_i32 = arith.constant 512 : i32
      %c16_i32 = arith.constant 16 : i32
      %c2097152_i32 = arith.constant 2097152 : i32
      %c256_i32 = arith.constant 256 : i32
      %c2_i32 = arith.constant 2 : i32
      %c14_i32 = arith.constant 14 : i32
      %c13_i32 = arith.constant 13 : i32
      %c136317200_i32 = arith.constant 136317200 : i32
      %11 = cute.static : !cute.layout<"(1,1,4,6):(0,0,2,1024)">
      %12 = cute.static : !cute.layout<"((128,128),1,1,2):((65536,1),0,0,128)">
      %c160_i32 = arith.constant 160 : i32
      %c3_i32 = arith.constant 3 : i32
      %c6_i32 = arith.constant 6 : i32
      %13 = cute.static : !cute.layout<"((4096,1),6):((1,0),4096)">
      %c32768_i32 = arith.constant 32768 : i32
      %c10000000_i32 = arith.constant 10000000 : i32
      %14 = cute.static : !cute.stride<"(((1@0,1@1),0),32@0)">
      %c224_i32 = arith.constant 224 : i32
      %15 = cute.static : !cute.stride<"(((1@0,1@1),0),128@1,32@0,1@2)">
      %16 = cute.static : !cute.stride<"(((1@1,1@0),0,8@0),128@1,32@0,1@2)">
      %17 = cute.static : !cute.stride<"((1@1,1@0),0,0,128@1,128@0,1@2)">
      %18 = cute.static : !cute.stride<"((1@1,1@0),0,8@0,128@1,32@0,1@2)">
      %19 = cute.static : !cute.stride<"(1@1,1@0,128@1,128@0,1@2)">
      %20 = cute.static : !cute.stride<"((1@1,1@0),(128@1,128@0,1@2))">
      %21 = cute.static : !cute.int_tuple<"(0,0,0)">
      %22 = cute.static : !cute.stride<"(1@1,1@0,128@1,32@0,1@2)">
      %23 = cute.static : !cute.stride<"((1@1,1@0),(128@1,32@0,1@2))">
      %c128_i32 = arith.constant 128 : i32
      %true = arith.constant true
      %false = arith.constant false
      %c4_i32 = arith.constant 4 : i32
      %24 = cute.static : !cute.int_tuple<"6">
      %25 = cute.static : !cute.int_tuple<"5">
      %26 = cute.static : !cute.int_tuple<"4">
      %27 = cute.static : !cute.int_tuple<"3">
      %28 = cute.static : !cute.int_tuple<"2">
      %29 = cute.static : !cute.int_tuple<"1">
      %30 = cute.static : !cute.int_tuple<"132096">
      %31 = cute.static : !cute.int_tuple<"33792">
      %32 = cute.static : !cute.int_tuple<"17408">
      %33 = cute.static : !cute.int_tuple<"1024">
      %34 = cute.static : !cute.int_tuple<"168">
      %35 = cute.static : !cute.int_tuple<"128">
      %36 = cute.static : !cute.int_tuple<"96">
      %c0_i32 = arith.constant 0 : i32
      %c1_i32 = arith.constant 1 : i32
      %c5_i32 = arith.constant 5 : i32
      %c32_i32 = arith.constant 32 : i32
      %int_tuple = cute.make_int_tuple(%arg9, %arg10, %arg11) : (i32, i32, i32) -> !cute.int_tuple<"(?,?,?)">
      %37:3 = cute.get_scalars(%int_tuple) <{only_dynamic}> : !cute.int_tuple<"(?,?,?)">
      %int_tuple_0 = cute.make_int_tuple(%37#0, %37#1, %37#2) : (i32, i32, i32) -> !cute.int_tuple<"(?,?,?)">
      %e0, %e1, %e2 = cute.get_leaves(%int_tuple_0) : !cute.int_tuple<"(?,?,?)">
      %shape = cute.make_shape(%e0, %e1, %e2) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.shape<"(?,?,?)">
      %lay = cute.make_layout(%shape) : !cute.layout<"(?,?,?):(1,?,?)">
      %38 = nvvm.read.ptx.sreg.tid.x range <i32, 0, 1024> : i32
      %39 = nvvm.read.ptx.sreg.tid.y range <i32, 0, 1024> : i32
      %40 = nvvm.read.ptx.sreg.tid.z range <i32, 0, 64> : i32
      %41 = nvvm.read.ptx.sreg.ntid.x range <i32, 1, 1024> : i32
      %42 = nvvm.read.ptx.sreg.ntid.y range <i32, 1, 1024> : i32
      %43 = arith.muli %39, %41 : i32
      %44 = arith.addi %38, %43 : i32
      %45 = arith.muli %40, %41 : i32
      %46 = arith.muli %45, %42 : i32
      %47 = arith.addi %44, %46 : i32
      %48 = arith.floordivsi %47, %c32_i32 : i32
      %49 = cute_nvgpu.arch.make_warp_uniform(%48) : i32
      %50 = arith.cmpi eq, %49, %c5_i32 : i32
      scf.if %50 {
        cute_nvgpu.prefetch_tma_desc(%arg1) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, tf32, copy_bits = 131072, tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">, internal_val_type = tf32>) -> ()
        cute_nvgpu.prefetch_tma_desc(%arg3) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, tf32, copy_bits = 131072, tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">, internal_val_type = tf32>) -> ()
        cute_nvgpu.prefetch_tma_desc(%arg5) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f32, copy_bits = 65536, tma_gbasis = <"(16,128,1):(1@1,1@0,1@2)">, internal_val_type = f32>) -> ()
        cute_nvgpu.prefetch_tma_desc(%arg7) : (!cute_nvgpu.atom.non_exec_tiled_tma_store<f32, copy_bits = 65536, tma_gbasis = <"(16,128,1):(1@1,1@0,1@2)">, internal_val_type = f32>) -> ()
      }
      %smem_ptr = cute_nvgpu.arch.get_dyn_smem() : !cute.ptr<i8, smem, align<1024>>
      %ptr = cute.add_offset(%smem_ptr, %36) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"96">) -> !cute.ptr<i8, smem, align<32>>
      %ptr_1 = cute.add_offset(%smem_ptr, %35) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"128">) -> !cute.ptr<i8, smem, align<128>>
      %ptr_2 = cute.add_offset(%smem_ptr, %34) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"168">) -> !cute.ptr<i8, smem, align<8>>
      %iter = cute.recast_iter(%ptr_2) : !cute.ptr<i8, smem, align<8>> to !cute.ptr<i32, smem, align<8>>
      %ptr_3 = cute.add_offset(%smem_ptr, %33) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"1024">) -> !cute.ptr<i8, smem, align<1024>>
      %ptr_4 = cute.add_offset(%smem_ptr, %32) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"17408">) -> !cute.ptr<i8, smem, align<1024>>
      %ptr_5 = cute.add_offset(%smem_ptr, %31) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"33792">) -> !cute.ptr<i8, smem, align<1024>>
      %ptr_6 = cute.add_offset(%smem_ptr, %30) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"132096">) -> !cute.ptr<i8, smem, align<1024>>
      %iter_7 = cute.recast_iter(%smem_ptr) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<i64, smem, align<1024>>
      %51 = arith.cmpi eq, %49, %c0_i32 : i32
      scf.if %51 {
        %85 = builtin.unrealized_conversion_cast %iter_7 : !cute.ptr<i64, smem, align<1024>> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %85, %c1_i32 : !llvm.ptr<3>, i32
        %ptr_55 = cute.add_offset(%iter_7, %29) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"1">) -> !cute.ptr<i64, smem>
        %86 = builtin.unrealized_conversion_cast %ptr_55 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %86, %c1_i32 : !llvm.ptr<3>, i32
        %ptr_56 = cute.add_offset(%iter_7, %28) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"2">) -> !cute.ptr<i64, smem, align<16>>
        %87 = builtin.unrealized_conversion_cast %ptr_56 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %87, %c1_i32 : !llvm.ptr<3>, i32
        %ptr_57 = cute.add_offset(%iter_7, %27) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"3">) -> !cute.ptr<i64, smem>
        %88 = builtin.unrealized_conversion_cast %ptr_57 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %88, %c1_i32 : !llvm.ptr<3>, i32
        %ptr_58 = cute.add_offset(%iter_7, %26) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"4">) -> !cute.ptr<i64, smem, align<32>>
        %89 = builtin.unrealized_conversion_cast %ptr_58 : !cute.ptr<i64, smem, align<32>> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %89, %c1_i32 : !llvm.ptr<3>, i32
        %ptr_59 = cute.add_offset(%iter_7, %25) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"5">) -> !cute.ptr<i64, smem>
        %90 = builtin.unrealized_conversion_cast %ptr_59 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %90, %c1_i32 : !llvm.ptr<3>, i32
      }
      %ptr_8 = cute.add_offset(%iter_7, %24) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"6">) -> !cute.ptr<i64, smem, align<16>>
      scf.if %51 {
        %85 = builtin.unrealized_conversion_cast %ptr_8 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %85, %c1_i32 : !llvm.ptr<3>, i32
        %int_tuple_55 = cute.make_int_tuple() : () -> !cute.int_tuple<"7">
        %ptr_56 = cute.add_offset(%iter_7, %int_tuple_55) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"7">) -> !cute.ptr<i64, smem>
        %86 = builtin.unrealized_conversion_cast %ptr_56 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %86, %c1_i32 : !llvm.ptr<3>, i32
        %int_tuple_57 = cute.make_int_tuple() : () -> !cute.int_tuple<"8">
        %ptr_58 = cute.add_offset(%iter_7, %int_tuple_57) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"8">) -> !cute.ptr<i64, smem, align<64>>
        %dyn = cute.derefine(%ptr_58) : !cute.ptr<i64, smem, align<64>> to !cute.ptr<i64, smem, align<16>>
        %87 = builtin.unrealized_conversion_cast %dyn : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %87, %c1_i32 : !llvm.ptr<3>, i32
        %int_tuple_59 = cute.make_int_tuple() : () -> !cute.int_tuple<"9">
        %ptr_60 = cute.add_offset(%iter_7, %int_tuple_59) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"9">) -> !cute.ptr<i64, smem>
        %88 = builtin.unrealized_conversion_cast %ptr_60 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %88, %c1_i32 : !llvm.ptr<3>, i32
        %int_tuple_61 = cute.make_int_tuple() : () -> !cute.int_tuple<"10">
        %ptr_62 = cute.add_offset(%iter_7, %int_tuple_61) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"10">) -> !cute.ptr<i64, smem, align<16>>
        %89 = builtin.unrealized_conversion_cast %ptr_62 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %89, %c1_i32 : !llvm.ptr<3>, i32
        %int_tuple_63 = cute.make_int_tuple() : () -> !cute.int_tuple<"11">
        %ptr_64 = cute.add_offset(%iter_7, %int_tuple_63) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"11">) -> !cute.ptr<i64, smem>
        %90 = builtin.unrealized_conversion_cast %ptr_64 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %90, %c1_i32 : !llvm.ptr<3>, i32
      }
      nvvm.fence.mbarrier.init
      nvvm.barrier
      %iter_9 = cute.recast_iter(%ptr) : !cute.ptr<i8, smem, align<32>> to !cute.ptr<i64, smem, align<32>>
      scf.if %51 {
        %85 = builtin.unrealized_conversion_cast %iter_9 : !cute.ptr<i64, smem, align<32>> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %85, %c1_i32 : !llvm.ptr<3>, i32
        %ptr_55 = cute.add_offset(%iter_9, %29) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i64, smem>
        %86 = builtin.unrealized_conversion_cast %ptr_55 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %86, %c1_i32 : !llvm.ptr<3>, i32
      }
      %ptr_10 = cute.add_offset(%iter_9, %28) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i64, smem, align<16>>
      scf.if %51 {
        %85 = builtin.unrealized_conversion_cast %ptr_10 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %85, %c4_i32 : !llvm.ptr<3>, i32
        %int_tuple_55 = cute.make_int_tuple() : () -> !cute.int_tuple<"3">
        %ptr_56 = cute.add_offset(%iter_9, %int_tuple_55) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i64, smem>
        %86 = builtin.unrealized_conversion_cast %ptr_56 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %86, %c4_i32 : !llvm.ptr<3>, i32
      }
      nvvm.fence.mbarrier.init
      nvvm.barrier
      %iter_11 = cute.recast_iter(%ptr_1) : !cute.ptr<i8, smem, align<128>> to !cute.ptr<i64, smem, align<128>>
      scf.if %51 {
        %85 = builtin.unrealized_conversion_cast %iter_11 : !cute.ptr<i64, smem, align<128>> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %85, %c1_i32 : !llvm.ptr<3>, i32
        %ptr_55 = cute.add_offset(%iter_11, %29) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"1">) -> !cute.ptr<i64, smem>
        %86 = builtin.unrealized_conversion_cast %ptr_55 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %86, %c1_i32 : !llvm.ptr<3>, i32
      }
      %ptr_12 = cute.add_offset(%iter_11, %28) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"2">) -> !cute.ptr<i64, smem, align<16>>
      scf.if %51 {
        %85 = builtin.unrealized_conversion_cast %ptr_12 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %85, %c4_i32 : !llvm.ptr<3>, i32
        %int_tuple_55 = cute.make_int_tuple() : () -> !cute.int_tuple<"3">
        %ptr_56 = cute.add_offset(%iter_11, %int_tuple_55) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"3">) -> !cute.ptr<i64, smem>
        %86 = builtin.unrealized_conversion_cast %ptr_56 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %86, %c4_i32 : !llvm.ptr<3>, i32
      }
      %52 = arith.remsi %38, %c32_i32 : i32
      %53 = arith.cmpi slt, %52, %c1_i32 : i32
      %54 = arith.extui %53 : i1 to i32
      %55 = arith.select %53, %c1_i32, %54 : i32
      %56 = arith.cmpi ne, %55, %c0_i32 : i32
      nvvm.fence.mbarrier.init
      nvvm.barrier
      %iter_13 = cute.recast_iter(%ptr_4) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<f32, smem, align<1024>, S<2,4,3>>
      %iter_14 = cute.recast_iter(%ptr_3) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<f32, smem, align<1024>, S<2,4,3>>
      %iter_15 = cute.recast_iter(%ptr_5) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<tf32, smem, align<1024>, S<3,4,3>>
      %iter_16 = cute.recast_iter(%ptr_6) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<tf32, smem, align<1024>, S<3,4,3>>
      %lay_17 = cute.get_layout(%arg2) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">
      %57:3 = cute.get_scalars(%lay_17) <{only_dynamic}> : !cute.layout<"(?,?,?):(1@1,1@0,1@2)">
      %58 = arith.ceildivsi %57#0, %c128_i32 : i32
      %59 = arith.ceildivsi %57#1, %c32_i32 : i32
      %shape_18 = cute.make_shape(%58, %59, %57#2) : (i32, i32, i32) -> !cute.shape<"((128,32),(?,?,?))">
      %lay_19 = cute.make_layout(%shape_18, %23) : !cute.layout<"((128,32),(?,?,?)):((1@1,1@0),(128@1,32@0,1@2))">
      %60:3 = cute.get_scalars(%lay_19) <{only_dynamic}> : !cute.layout<"((128,32),(?,?,?)):((1@1,1@0),(128@1,32@0,1@2))">
      %shape_20 = cute.make_shape(%60#0, %60#1, %60#2) : (i32, i32, i32) -> !cute.shape<"(128,32,?,?,?)">
      %lay_21 = cute.make_layout(%shape_20, %22) : !cute.layout<"(128,32,?,?,?):(1@1,1@0,128@1,32@0,1@2)">
      %lay_22 = cute.get_layout(%arg4) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">
      %61:3 = cute.get_scalars(%lay_22) <{only_dynamic}> : !cute.layout<"(?,?,?):(1@1,1@0,1@2)">
      %62 = arith.ceildivsi %61#0, %c128_i32 : i32
      %63 = arith.ceildivsi %61#1, %c32_i32 : i32
      %shape_23 = cute.make_shape(%62, %63, %61#2) : (i32, i32, i32) -> !cute.shape<"((128,32),(?,?,?))">
      %lay_24 = cute.make_layout(%shape_23, %23) : !cute.layout<"((128,32),(?,?,?)):((1@1,1@0),(128@1,32@0,1@2))">
      %64:3 = cute.get_scalars(%lay_24) <{only_dynamic}> : !cute.layout<"((128,32),(?,?,?)):((1@1,1@0),(128@1,32@0,1@2))">
      %shape_25 = cute.make_shape(%64#0, %64#1, %64#2) : (i32, i32, i32) -> !cute.shape<"(128,32,?,?,?)">
      %lay_26 = cute.make_layout(%shape_25, %22) : !cute.layout<"(128,32,?,?,?):(1@1,1@0,128@1,32@0,1@2)">
      %lay_27 = cute.get_layout(%arg6) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">
      %65:3 = cute.get_scalars(%lay_27) <{only_dynamic}> : !cute.layout<"(?,?,?):(1@1,1@0,1@2)">
      %66 = arith.ceildivsi %65#0, %c128_i32 : i32
      %67 = arith.ceildivsi %65#1, %c128_i32 : i32
      %shape_28 = cute.make_shape(%66, %67, %65#2) : (i32, i32, i32) -> !cute.shape<"((128,128),(?,?,?))">
      %lay_29 = cute.make_layout(%shape_28, %20) : !cute.layout<"((128,128),(?,?,?)):((1@1,1@0),(128@1,128@0,1@2))">
      %68:3 = cute.get_scalars(%lay_29) <{only_dynamic}> : !cute.layout<"((128,128),(?,?,?)):((1@1,1@0),(128@1,128@0,1@2))">
      %shape_30 = cute.make_shape(%68#0, %68#1, %68#2) : (i32, i32, i32) -> !cute.shape<"(128,128,?,?,?)">
      %lay_31 = cute.make_layout(%shape_30, %19) : !cute.layout<"(128,128,?,?,?):(1@1,1@0,128@1,128@0,1@2)">
      %lay_32 = cute.get_layout(%arg8) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">
      %69:3 = cute.get_scalars(%lay_32) <{only_dynamic}> : !cute.layout<"(?,?,?):(1@1,1@0,1@2)">
      %70 = arith.ceildivsi %69#0, %c128_i32 : i32
      %71 = arith.ceildivsi %69#1, %c128_i32 : i32
      %shape_33 = cute.make_shape(%70, %71, %69#2) : (i32, i32, i32) -> !cute.shape<"((128,128),(?,?,?))">
      %lay_34 = cute.make_layout(%shape_33, %20) : !cute.layout<"((128,128),(?,?,?)):((1@1,1@0),(128@1,128@0,1@2))">
      %72:3 = cute.get_scalars(%lay_34) <{only_dynamic}> : !cute.layout<"((128,128),(?,?,?)):((1@1,1@0),(128@1,128@0,1@2))">
      %shape_35 = cute.make_shape(%72#0, %72#1, %72#2) : (i32, i32, i32) -> !cute.shape<"(128,128,?,?,?)">
      %lay_36 = cute.make_layout(%shape_35, %19) : !cute.layout<"(128,128,?,?,?):(1@1,1@0,128@1,128@0,1@2)">
      %sz = cute.size(%lay_21) <{mode = [3]}> : (!cute.layout<"(128,32,?,?,?):(1@1,1@0,128@1,32@0,1@2)">) -> !cute.int_tuple<"?">
      %e0_37 = cute.get_leaves(%sz) : !cute.int_tuple<"?">
      %73 = cute.get_scalars(%e0_37) : !cute.int_tuple<"?">
      %74:3 = cute.get_scalars(%lay_21) <{only_dynamic}> : !cute.layout<"(128,32,?,?,?):(1@1,1@0,128@1,32@0,1@2)">
      %shape_38 = cute.make_shape(%74#0, %74#1, %74#2) : (i32, i32, i32) -> !cute.shape<"((128,8),1,4,?,?,?)">
      %lay_39 = cute.make_layout(%shape_38, %18) : !cute.layout<"((128,8),1,4,?,?,?):((1@1,1@0),0,8@0,128@1,32@0,1@2)">
      %75:3 = cute.get_scalars(%lay_26) <{only_dynamic}> : !cute.layout<"(128,32,?,?,?):(1@1,1@0,128@1,32@0,1@2)">
      %shape_40 = cute.make_shape(%75#0, %75#1, %75#2) : (i32, i32, i32) -> !cute.shape<"((128,8),1,4,?,?,?)">
      %lay_41 = cute.make_layout(%shape_40, %18) : !cute.layout<"((128,8),1,4,?,?,?):((1@1,1@0),0,8@0,128@1,32@0,1@2)">
      %76:3 = cute.get_scalars(%lay_31) <{only_dynamic}> : !cute.layout<"(128,128,?,?,?):(1@1,1@0,128@1,128@0,1@2)">
      %shape_42 = cute.make_shape(%76#0, %76#1, %76#2) : (i32, i32, i32) -> !cute.shape<"((128,128),1,1,?,?,?)">
      %lay_43 = cute.make_layout(%shape_42, %17) : !cute.layout<"((128,128),1,1,?,?,?):((1@1,1@0),0,0,128@1,128@0,1@2)">
      %77:3 = cute.get_scalars(%lay_36) <{only_dynamic}> : !cute.layout<"(128,128,?,?,?):(1@1,1@0,128@1,128@0,1@2)">
      %shape_44 = cute.make_shape(%77#0, %77#1, %77#2) : (i32, i32, i32) -> !cute.shape<"((128,128),1,1,?,?,?)">
      %lay_45 = cute.make_layout(%shape_44, %17) : !cute.layout<"((128,128),1,1,?,?,?):((1@1,1@0),0,0,128@1,128@0,1@2)">
      %78:3 = cute.get_scalars(%lay_39) <{only_dynamic}> : !cute.layout<"((128,8),1,4,?,?,?):((1@1,1@0),0,8@0,128@1,32@0,1@2)">
      %shape_46 = cute.make_shape(%78#0, %78#1, %78#2) : (i32, i32, i32) -> !cute.shape<"(((128,8),1,4),?,?,?)">
      %lay_47 = cute.make_layout(%shape_46, %16) : !cute.layout<"(((128,8),1,4),?,?,?):(((1@1,1@0),0,8@0),128@1,32@0,1@2)">
      %79:3 = cute.get_scalars(%lay_47) <{only_dynamic}> : !cute.layout<"(((128,8),1,4),?,?,?):(((1@1,1@0),0,8@0),128@1,32@0,1@2)">
      %shape_48 = cute.make_shape(%79#0, %79#1, %79#2) : (i32, i32, i32) -> !cute.shape<"(((32,128),1),?,?,?)">
      %lay_49 = cute.make_layout(%shape_48, %15) : !cute.layout<"(((32,128),1),?,?,?):(((1@0,1@1),0),128@1,32@0,1@2)">
      %80:3 = cute.get_scalars(%lay_41) <{only_dynamic}> : !cute.layout<"((128,8),1,4,?,?,?):((1@1,1@0),0,8@0,128@1,32@0,1@2)">
      %shape_50 = cute.make_shape(%80#0, %80#1, %80#2) : (i32, i32, i32) -> !cute.shape<"(((128,8),1,4),?,?,?)">
      %lay_51 = cute.make_layout(%shape_50, %16) : !cute.layout<"(((128,8),1,4),?,?,?):(((1@1,1@0),0,8@0),128@1,32@0,1@2)">
      %81:3 = cute.get_scalars(%lay_51) <{only_dynamic}> : !cute.layout<"(((128,8),1,4),?,?,?):(((1@1,1@0),0,8@0),128@1,32@0,1@2)">
      %shape_52 = cute.make_shape(%81#0, %81#1, %81#2) : (i32, i32, i32) -> !cute.shape<"(((32,128),1),?,?,?)">
      %lay_53 = cute.make_layout(%shape_52, %15) : !cute.layout<"(((32,128),1),?,?,?):(((1@0,1@1),0),128@1,32@0,1@2)">
      %ummaSmemDesc = cute_nvgpu.make_umma_smem_desc(%iter_15 : !cute.ptr<tf32, smem, align<1024>, S<3,4,3>>) layout = <"((128,8),1,4,6):((32,1),0,8,4096)">, major = <k> -> !cute_nvgpu.smem_desc
      %ummaSmemDesc_54 = cute_nvgpu.make_umma_smem_desc(%iter_16 : !cute.ptr<tf32, smem, align<1024>, S<3,4,3>>) layout = <"((128,8),1,4,6):((32,1),0,8,4096)">, major = <k> -> !cute_nvgpu.smem_desc
      nvvm.barrier id = %c1_i32 number_of_threads = %c224_i32
      scf.if %50 {
        %85 = nvvm.read.ptx.sreg.ctaid.z range <i32, 0, 65535> : i32
        %86 = nvvm.read.ptx.sreg.nctaid.x range <i32, 1, 2147483647> : i32
        %87 = nvvm.read.ptx.sreg.nctaid.y range <i32, 1, 65535> : i32
        %88 = nvvm.read.ptx.sreg.nctaid.z range <i32, 1, 65535> : i32
        %int_tuple_55 = cute.make_int_tuple(%86, %87, %88) : (i32, i32, i32) -> !cute.int_tuple<"(?,?,?)">
        %sz_56 = cute.size(%int_tuple_55) : (!cute.int_tuple<"(?,?,?)">) -> !cute.int_tuple<"?">
        %e0_57 = cute.get_leaves(%sz_56) : !cute.int_tuple<"?">
        %div = cute.tuple_div(%e0_57, %29) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
        %89 = cute.get_scalars(%div) : !cute.int_tuple<"?">
        %sz_58 = cute.size(%lay) : (!cute.layout<"(?,?,?):(1,?,?)">) -> !cute.int_tuple<"?">
        %e0_59 = cute.get_leaves(%sz_58) : !cute.int_tuple<"?">
        %90 = cute.get_scalars(%e0_59) : !cute.int_tuple<"?">
        %91 = arith.cmpi sgt, %90, %85 : i32
        %92 = cute.get_hier_coord(%85, %lay) : (i32, !cute.layout<"(?,?,?):(1,?,?)">) -> !cute.coord<"(?,?,?)">
        %e0_60, %e1_61, %e2_62 = cute.get_leaves(%92) : !cute.coord<"(?,?,?)">
        %itup = cute.to_int_tuple(%e0_60) : !cute.coord<"?"> to !cute.int_tuple<"?">
        %itup_63 = cute.to_int_tuple(%e1_61) : !cute.coord<"?"> to !cute.int_tuple<"?">
        %itup_64 = cute.to_int_tuple(%e2_62) : !cute.coord<"?"> to !cute.int_tuple<"?">
        %mul = cute.tuple_mul(%itup, %29) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
        %93 = cute.get_scalars(%mul) : !cute.int_tuple<"?">
        %mul_65 = cute.tuple_mul(%itup_63, %29) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
        %94 = cute.get_scalars(%mul_65) : !cute.int_tuple<"?">
        %mul_66 = cute.tuple_mul(%itup_64, %29) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
        %95 = cute.get_scalars(%mul_66) : !cute.int_tuple<"?">
        %96:3 = cute.get_scalars(%lay_49) <{only_dynamic}> : !cute.layout<"(((32,128),1),?,?,?):(((1@0,1@1),0),128@1,32@0,1@2)">
        %shape_67 = cute.make_shape(%96#1) : (i32) -> !cute.shape<"(((32,128),1),?)">
        %lay_68 = cute.make_layout(%shape_67, %14) : !cute.layout<"(((32,128),1),?):(((1@0,1@1),0),32@0)">
        %97:3 = cute.get_scalars(%lay_53) <{only_dynamic}> : !cute.layout<"(((32,128),1),?,?,?):(((1@0,1@1),0),128@1,32@0,1@2)">
        %shape_69 = cute.make_shape(%97#1) : (i32) -> !cute.shape<"(((32,128),1),?)">
        %lay_70 = cute.make_layout(%shape_69, %14) : !cute.layout<"(((32,128),1),?):(((1@0,1@1),0),32@0)">
        %98 = arith.cmpi sgt, %73, %c0_i32 : i32
        %99 = cute_nvgpu.atom.make_exec_tma(%arg1) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, tf32, copy_bits = 131072, tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">, internal_val_type = tf32>) -> !cute_nvgpu.atom.tma_load<tf32, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">>
        %100 = cute.get_scalars(%29) : !cute.int_tuple<"1">
        %101 = cute_nvgpu.atom.make_exec_tma(%arg3) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, tf32, copy_bits = 131072, tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">, internal_val_type = tf32>) -> !cute_nvgpu.atom.tma_load<tf32, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">>
        %102:7 = scf.while (%arg14 = %93, %arg15 = %94, %arg16 = %95, %arg17 = %91, %arg18 = %c0_i32, %arg19 = %c1_i32, %arg20 = %85, %arg21 = %c0_i32) : (i32, i32, i32, i1, i32, i32, i32, i32) -> (i32, i32, i32, i32, i32, i32, i32) {
          scf.condition(%arg17) %arg14, %arg15, %arg16, %arg18, %arg19, %arg20, %arg21 : i32, i32, i32, i32, i32, i32, i32
        } do {
        ^bb0(%arg14: i32, %arg15: i32, %arg16: i32, %arg17: i32, %arg18: i32, %arg19: i32, %arg20: i32):
          %coord = cute.make_coord(%arg14, %arg16) : (i32, i32) -> !cute.coord<"(_,?,_,?)">
          %idx = cute.crd2idx(%coord, %lay_49) : (!cute.coord<"(_,?,_,?)">, !cute.layout<"(((32,128),1),?,?,?):(((1@0,1@1),0),128@1,32@0,1@2)">) -> !cute.int_tuple<"(0,?{div=128},?)">
          %tup = cute.add_offset(%21, %idx) : (!cute.int_tuple<"(0,0,0)">, !cute.int_tuple<"(0,?{div=128},?)">) -> !cute.int_tuple<"(0,?{div=128},?)">
          %coord_73 = cute.make_coord(%arg15, %arg16) : (i32, i32) -> !cute.coord<"(_,?,_,?)">
          %idx_74 = cute.crd2idx(%coord_73, %lay_53) : (!cute.coord<"(_,?,_,?)">, !cute.layout<"(((32,128),1),?,?,?):(((1@0,1@1),0),128@1,32@0,1@2)">) -> !cute.int_tuple<"(0,?{div=128},?)">
          %tup_75 = cute.add_offset(%21, %idx_74) : (!cute.int_tuple<"(0,0,0)">, !cute.int_tuple<"(0,?{div=128},?)">) -> !cute.int_tuple<"(0,?{div=128},?)">
          %125 = scf.if %98 -> (i1) {
            %int_tuple_85 = cute.make_int_tuple(%arg17) : (i32) -> !cute.int_tuple<"?">
            %ptr_86 = cute.add_offset(%ptr_8, %int_tuple_85) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
            %134 = builtin.unrealized_conversion_cast %ptr_86 : !cute.ptr<i64, smem> to !llvm.ptr<3>
            %135 = nvvm.mbarrier.wait.parity %134, %arg18 {kind = #nvvm.mbar_wait<try>} : !llvm.ptr<3>, i32 -> i1
            scf.yield %135 : i1
          } else {
            scf.yield %true : i1
          }
          %126:4 = scf.for %arg21 = %c0_i32 to %73 step %c1_i32 iter_args(%arg22 = %125, %arg23 = %c0_i32, %arg24 = %arg17, %arg25 = %arg18) -> (i1, i32, i32, i32)  : i32 {
            %134 = arith.extui %arg22 : i1 to i32
            %135 = arith.cmpi eq, %134, %c0_i32 : i32
            scf.if %135 {
              %int_tuple_105 = cute.make_int_tuple(%arg24) : (i32) -> !cute.int_tuple<"?">
              %ptr_106 = cute.add_offset(%ptr_8, %int_tuple_105) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
              %150 = builtin.unrealized_conversion_cast %ptr_106 : !cute.ptr<i64, smem> to !llvm.ptr<3>
              nvvm.mbarrier.try_wait.parity.shared %150, %arg25, %c10000000_i32 : !llvm.ptr<3>, i32, i32
            }
            %136 = nvvm.elect.sync -> i1
            scf.if %136 {
              %int_tuple_105 = cute.make_int_tuple(%arg24) : (i32) -> !cute.int_tuple<"?">
              %ptr_106 = cute.add_offset(%iter_7, %int_tuple_105) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
              %150 = builtin.unrealized_conversion_cast %ptr_106 : !cute.ptr<i64, smem> to !llvm.ptr<3>
              nvvm.mbarrier.txn %150, %c32768_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
            }
            %coord_85 = cute.make_coord(%arg23) : (i32) -> !cute.coord<"(_,?)">
            %idx_86 = cute.crd2idx(%coord_85, %lay_68) : (!cute.coord<"(_,?)">, !cute.layout<"(((32,128),1),?):(((1@0,1@1),0),32@0)">) -> !cute.int_tuple<"(?{div=32},0)">
            %tup_87 = cute.add_offset(%tup, %idx_86) : (!cute.int_tuple<"(0,?{div=128},?)">, !cute.int_tuple<"(?{div=32},0)">) -> !cute.int_tuple<"(?{div=32},?{div=128},?)">
            %e0_88, %e1_89, %e2_90 = cute.get_leaves(%tup_87) : !cute.int_tuple<"(?{div=32},?{div=128},?)">
            %coord_91 = cute.make_coord(%arg24) : (i32) -> !cute.coord<"(_,?)">
            %idx_92 = cute.crd2idx(%coord_91, %13) : (!cute.coord<"(_,?)">, !cute.layout<"((4096,1),6):((1,0),4096)">) -> !cute.int_tuple<"?{div=4096}">
            %ptr_93 = cute.add_offset(%iter_15, %idx_92) : (!cute.ptr<tf32, smem, align<1024>, S<3,4,3>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<tf32, smem, align<1024>, S<3,4,3>>
            %int_tuple_94 = cute.make_int_tuple(%arg24) : (i32) -> !cute.int_tuple<"?">
            %ptr_95 = cute.add_offset(%iter_7, %int_tuple_94) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
            %int_tuple_96 = cute.make_int_tuple(%e0_88, %e1_89, %e2_90) : (!cute.int_tuple<"?{div=32}">, !cute.int_tuple<"?{div=128}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=32},?{div=128},?)">
            %137 = cute_nvgpu.atom.set_value(%99, %ptr_95 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<tf32, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">>
            %138 = cute_nvgpu.atom.get_value(%137 : !cute_nvgpu.atom.tma_load<tf32, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
            %TMADescAddr = cute_nvgpu.get_tma_desc_addr(%137 : !cute_nvgpu.atom.tma_load<tf32, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">>) -> !cute.ptr<generic, align<64>>
            %139:3 = cute.get_scalars(%int_tuple_96) : !cute.int_tuple<"(?{div=32},?{div=128},?)">
            scf.for %arg26 = %c0_i32 to %100 step %c1_i32  : i32 {
              cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr : !cute.ptr<generic, align<64>>, %ptr_93 : !cute.ptr<tf32, smem, align<1024>, S<3,4,3>>, %138 : !cute.ptr<smem, align<8>>, [%139#0, %139#1, %139#2] : i32, i32, i32) mode = <tiled> num_cta = 1 : i32
            } {llvm.loop_annotation = #loop_annotation}
            %idx_97 = cute.crd2idx(%coord_85, %lay_70) : (!cute.coord<"(_,?)">, !cute.layout<"(((32,128),1),?):(((1@0,1@1),0),32@0)">) -> !cute.int_tuple<"(?{div=32},0)">
            %tup_98 = cute.add_offset(%tup_75, %idx_97) : (!cute.int_tuple<"(0,?{div=128},?)">, !cute.int_tuple<"(?{div=32},0)">) -> !cute.int_tuple<"(?{div=32},?{div=128},?)">
            %e0_99, %e1_100, %e2_101 = cute.get_leaves(%tup_98) : !cute.int_tuple<"(?{div=32},?{div=128},?)">
            %ptr_102 = cute.add_offset(%iter_16, %idx_92) : (!cute.ptr<tf32, smem, align<1024>, S<3,4,3>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<tf32, smem, align<1024>, S<3,4,3>>
            %int_tuple_103 = cute.make_int_tuple(%e0_99, %e1_100, %e2_101) : (!cute.int_tuple<"?{div=32}">, !cute.int_tuple<"?{div=128}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=32},?{div=128},?)">
            %140 = cute_nvgpu.atom.set_value(%101, %ptr_95 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<tf32, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">>
            %141 = cute_nvgpu.atom.get_value(%140 : !cute_nvgpu.atom.tma_load<tf32, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
            %TMADescAddr_104 = cute_nvgpu.get_tma_desc_addr(%140 : !cute_nvgpu.atom.tma_load<tf32, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">>) -> !cute.ptr<generic, align<64>>
            %142:3 = cute.get_scalars(%int_tuple_103) : !cute.int_tuple<"(?{div=32},?{div=128},?)">
            scf.for %arg26 = %c0_i32 to %100 step %c1_i32  : i32 {
              cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr_104 : !cute.ptr<generic, align<64>>, %ptr_102 : !cute.ptr<tf32, smem, align<1024>, S<3,4,3>>, %141 : !cute.ptr<smem, align<8>>, [%142#0, %142#1, %142#2] : i32, i32, i32) mode = <tiled> num_cta = 1 : i32
            } {llvm.loop_annotation = #loop_annotation}
            %143 = arith.addi %arg24, %c1_i32 : i32
            %144 = arith.addi %arg23, %c1_i32 : i32
            %145 = arith.cmpi eq, %143, %c6_i32 : i32
            %146 = arith.select %145, %c0_i32, %143 : i32
            %147 = scf.if %145 -> (i32) {
              %150 = arith.xori %arg25, %c1_i32 : i32
              scf.yield %150 : i32
            } else {
              scf.yield %arg25 : i32
            }
            %148 = arith.cmpi sgt, %73, %144 : i32
            %149 = scf.if %148 -> (i1) {
              %int_tuple_105 = cute.make_int_tuple(%146) : (i32) -> !cute.int_tuple<"?">
              %ptr_106 = cute.add_offset(%ptr_8, %int_tuple_105) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
              %150 = builtin.unrealized_conversion_cast %ptr_106 : !cute.ptr<i64, smem> to !llvm.ptr<3>
              %151 = nvvm.mbarrier.wait.parity %150, %147 {kind = #nvvm.mbar_wait<try>} : !llvm.ptr<3>, i32 -> i1
              scf.yield %151 : i1
            } else {
              scf.yield %true : i1
            }
            scf.yield %149, %144, %146, %147 : i1, i32, i32, i32
          } {loop_annotation = #loop_annotation1}
          %127 = arith.addi %arg19, %89 : i32
          %128 = arith.addi %arg20, %c1_i32 : i32
          %129 = arith.cmpi sgt, %90, %127 : i32
          %130 = cute.get_hier_coord(%127, %lay) : (i32, !cute.layout<"(?,?,?):(1,?,?)">) -> !cute.coord<"(?,?,?)">
          %e0_76, %e1_77, %e2_78 = cute.get_leaves(%130) : !cute.coord<"(?,?,?)">
          %itup_79 = cute.to_int_tuple(%e0_76) : !cute.coord<"?"> to !cute.int_tuple<"?">
          %itup_80 = cute.to_int_tuple(%e1_77) : !cute.coord<"?"> to !cute.int_tuple<"?">
          %itup_81 = cute.to_int_tuple(%e2_78) : !cute.coord<"?"> to !cute.int_tuple<"?">
          %mul_82 = cute.tuple_mul(%itup_79, %29) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
          %131 = cute.get_scalars(%mul_82) : !cute.int_tuple<"?">
          %mul_83 = cute.tuple_mul(%itup_80, %29) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
          %132 = cute.get_scalars(%mul_83) : !cute.int_tuple<"?">
          %mul_84 = cute.tuple_mul(%itup_81, %29) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
          %133 = cute.get_scalars(%mul_84) : !cute.int_tuple<"?">
          scf.yield %131, %132, %133, %129, %126#2, %126#3, %127, %128 : i32, i32, i32, i1, i32, i32, i32, i32
        }
        %103 = arith.addi %102#3, %c1_i32 : i32
        %104 = arith.cmpi eq, %103, %c6_i32 : i32
        %105 = arith.select %104, %c0_i32, %103 : i32
        %106 = scf.if %104 -> (i32) {
          %125 = arith.xori %102#4, %c1_i32 : i32
          scf.yield %125 : i32
        } else {
          scf.yield %102#4 : i32
        }
        %107 = arith.addi %105, %c1_i32 : i32
        %108 = arith.cmpi eq, %107, %c6_i32 : i32
        %109 = arith.select %108, %c0_i32, %107 : i32
        %110 = scf.if %108 -> (i32) {
          %125 = arith.xori %106, %c1_i32 : i32
          scf.yield %125 : i32
        } else {
          scf.yield %106 : i32
        }
        %111 = arith.addi %109, %c1_i32 : i32
        %112 = arith.cmpi eq, %111, %c6_i32 : i32
        %113 = arith.select %112, %c0_i32, %111 : i32
        %114 = scf.if %112 -> (i32) {
          %125 = arith.xori %110, %c1_i32 : i32
          scf.yield %125 : i32
        } else {
          scf.yield %110 : i32
        }
        %115 = arith.addi %113, %c1_i32 : i32
        %116 = arith.cmpi eq, %115, %c6_i32 : i32
        %117 = arith.select %116, %c0_i32, %115 : i32
        %118 = scf.if %116 -> (i32) {
          %125 = arith.xori %114, %c1_i32 : i32
          scf.yield %125 : i32
        } else {
          scf.yield %114 : i32
        }
        %119 = arith.addi %117, %c1_i32 : i32
        %120 = arith.cmpi eq, %119, %c6_i32 : i32
        %121 = arith.select %120, %c0_i32, %119 : i32
        %122 = scf.if %120 -> (i32) {
          %125 = arith.xori %118, %c1_i32 : i32
          scf.yield %125 : i32
        } else {
          scf.yield %118 : i32
        }
        %int_tuple_71 = cute.make_int_tuple(%121) : (i32) -> !cute.int_tuple<"?">
        %ptr_72 = cute.add_offset(%ptr_8, %int_tuple_71) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
        %123 = builtin.unrealized_conversion_cast %ptr_72 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        nvvm.mbarrier.try_wait.parity.shared %123, %122, %c10000000_i32 : !llvm.ptr<3>, i32, i32
        %124 = nvvm.elect.sync -> i1
        scf.if %124 {
          %ptr_73 = cute.add_offset(%iter_7, %int_tuple_71) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
          %125 = builtin.unrealized_conversion_cast %ptr_73 : !cute.ptr<i64, smem> to !llvm.ptr<3>
          nvvm.mbarrier.txn %125, %c32768_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
        }
      }
      %82 = arith.cmpi eq, %49, %c4_i32 : i32
      scf.if %82 {
        nvvm.barrier id = %c3_i32 number_of_threads = %c160_i32
        %tmem_ptr = cute_nvgpu.arch.sm100.retrieve_tmem_ptr(%iter) : !cute.ptr<i32, smem, align<8>> -> !cute.ptr<f32, tmem, align<16>>
        %85 = nvvm.read.ptx.sreg.ctaid.z range <i32, 0, 65535> : i32
        %86 = nvvm.read.ptx.sreg.nctaid.x range <i32, 1, 2147483647> : i32
        %87 = nvvm.read.ptx.sreg.nctaid.y range <i32, 1, 65535> : i32
        %88 = nvvm.read.ptx.sreg.nctaid.z range <i32, 1, 65535> : i32
        %int_tuple_55 = cute.make_int_tuple(%86, %87, %88) : (i32, i32, i32) -> !cute.int_tuple<"(?,?,?)">
        %sz_56 = cute.size(%int_tuple_55) : (!cute.int_tuple<"(?,?,?)">) -> !cute.int_tuple<"?">
        %e0_57 = cute.get_leaves(%sz_56) : !cute.int_tuple<"?">
        %div = cute.tuple_div(%e0_57, %29) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
        %89 = cute.get_scalars(%div) : !cute.int_tuple<"?">
        %sz_58 = cute.size(%lay) : (!cute.layout<"(?,?,?):(1,?,?)">) -> !cute.int_tuple<"?">
        %e0_59 = cute.get_leaves(%sz_58) : !cute.int_tuple<"?">
        %90 = cute.get_scalars(%e0_59) : !cute.int_tuple<"?">
        %91 = arith.cmpi sgt, %90, %85 : i32
        %92 = arith.cmpi sgt, %73, %c0_i32 : i32
        %93 = arith.extui %92 : i1 to i32
        %94 = arith.select %92, %c1_i32, %93 : i32
        %95 = arith.cmpi ne, %94, %c0_i32 : i32
        %96 = cute.get_scalars(%29) : !cute.int_tuple<"1">
        %97:8 = scf.while (%arg14 = %91, %arg15 = %c0_i32, %arg16 = %c0_i32, %arg17 = %0, %arg18 = %c0_i32, %arg19 = %c0_i32, %arg20 = %c1_i32, %arg21 = %85, %arg22 = %c0_i32) : (i1, i32, i32, !llvm.struct<(i1, i1, i1)>, i32, i32, i32, i32, i32) -> (i32, i32, !llvm.struct<(i1, i1, i1)>, i32, i32, i32, i32, i32) {
          scf.condition(%arg14) %arg15, %arg16, %arg17, %arg18, %arg19, %arg20, %arg21, %arg22 : i32, i32, !llvm.struct<(i1, i1, i1)>, i32, i32, i32, i32, i32
        } do {
        ^bb0(%arg14: i32, %arg15: i32, %arg16: !llvm.struct<(i1, i1, i1)>, %arg17: i32, %arg18: i32, %arg19: i32, %arg20: i32, %arg21: i32):
          %102 = builtin.unrealized_conversion_cast %arg16 : !llvm.struct<(i1, i1, i1)> to !mma_tf32_tf32_f32_128x128x8_
          %coord = cute.make_coord(%arg18) : (i32) -> !cute.coord<"(_,_,_,?)">
          %idx = cute.crd2idx(%coord, %12) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((128,128),1,1,2):((65536,1),0,0,128)">) -> !cute.int_tuple<"?{div=128}">
          %ptr_60 = cute.add_offset(%tmem_ptr, %idx) : (!cute.ptr<f32, tmem, align<16>>, !cute.int_tuple<"?{div=128}">) -> !cute.ptr<f32, tmem, align<16>>
          %103 = scf.if %95 -> (i1) {
            %int_tuple_63 = cute.make_int_tuple(%arg14) : (i32) -> !cute.int_tuple<"?">
            %ptr_64 = cute.add_offset(%iter_7, %int_tuple_63) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
            %117 = builtin.unrealized_conversion_cast %ptr_64 : !cute.ptr<i64, smem> to !llvm.ptr<3>
            %118 = nvvm.mbarrier.wait.parity %117, %arg15 {kind = #nvvm.mbar_wait<try>} : !llvm.ptr<3>, i32 -> i1
            scf.yield %118 : i1
          } else {
            scf.yield %true : i1
          }
          %int_tuple_61 = cute.make_int_tuple(%arg18) : (i32) -> !cute.int_tuple<"?">
          %ptr_62 = cute.add_offset(%ptr_10, %int_tuple_61) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
          %104 = builtin.unrealized_conversion_cast %ptr_62 : !cute.ptr<i64, smem> to !llvm.ptr<3>
          nvvm.mbarrier.try_wait.parity.shared %104, %arg19, %c10000000_i32 : !llvm.ptr<3>, i32, i32
          %105 = cute_nvgpu.atom.set_value(%102, %false : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_tf32_tf32_f32_128x128x8_
          %106 = builtin.unrealized_conversion_cast %105 : !mma_tf32_tf32_f32_128x128x8_ to !llvm.struct<(i1, i1, i1)>
          %107:5 = scf.for %arg22 = %c0_i32 to %73 step %c1_i32 iter_args(%arg23 = %103, %arg24 = %106, %arg25 = %c0_i32, %arg26 = %arg14, %arg27 = %arg15) -> (i1, !llvm.struct<(i1, i1, i1)>, i32, i32, i32)  : i32 {
            %117 = arith.extui %arg23 : i1 to i32
            %118 = arith.cmpi eq, %117, %c0_i32 : i32
            scf.if %118 {
              %int_tuple_63 = cute.make_int_tuple(%arg26) : (i32) -> !cute.int_tuple<"?">
              %ptr_64 = cute.add_offset(%iter_7, %int_tuple_63) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
              %128 = builtin.unrealized_conversion_cast %ptr_64 : !cute.ptr<i64, smem> to !llvm.ptr<3>
              nvvm.mbarrier.try_wait.parity.shared %128, %arg27, %c10000000_i32 : !llvm.ptr<3>, i32, i32
            }
            %119 = scf.for %arg28 = %c0_i32 to %c4_i32 step %c1_i32 iter_args(%arg29 = %arg24) -> (!llvm.struct<(i1, i1, i1)>)  : i32 {
              %128 = builtin.unrealized_conversion_cast %arg29 : !llvm.struct<(i1, i1, i1)> to !mma_tf32_tf32_f32_128x128x8_
              %coord_63 = cute.make_coord(%arg28, %arg26) : (i32, i32) -> !cute.coord<"(_,_,?,?)">
              %idx_64 = cute.crd2idx(%coord_63, %11) : (!cute.coord<"(_,_,?,?)">, !cute.layout<"(1,1,4,6):(0,0,2,1024)">) -> !cute.int_tuple<"?{div=2}">
              %tup = cute.add_offset(%ummaSmemDesc, %idx_64) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
              %tup_65 = cute.add_offset(%ummaSmemDesc_54, %idx_64) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
              %129 = cute_nvgpu.atom.get_value(%128 : !mma_tf32_tf32_f32_128x128x8_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : i1
              %130 = cute_nvgpu.atom.get_value(%128 : !mma_tf32_tf32_f32_128x128x8_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : i1
              %131 = cute_nvgpu.atom.get_value(%128 : !mma_tf32_tf32_f32_128x128x8_) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : i1
              %132 = arith.extui %129 : i1 to i32
              %133 = arith.extui %130 : i1 to i32
              %134 = arith.shli %132, %c13_i32 : i32
              %135 = arith.shli %133, %c14_i32 : i32
              %136 = arith.ori %134, %c136317200_i32 : i32
              %137 = arith.ori %136, %135 : i32
              scf.for %arg30 = %c0_i32 to %96 step %c1_i32  : i32 {
                scf.for %arg31 = %c0_i32 to %96 step %c1_i32  : i32 {
                  scf.for %arg32 = %c0_i32 to %96 step %c1_i32  : i32 {
                    cute_nvgpu.arch.mma.SM100.umma(%tup, %tup_65, %ptr_60, %137, %131) {num_cta = 1 : i32, scale = 0 : i32, a_type = tf32} : (!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, !cute.ptr<f32, tmem, align<16>>, i32, i1) -> ()
                  } {llvm.loop_annotation = #loop_annotation}
                } {llvm.loop_annotation = #loop_annotation}
              } {llvm.loop_annotation = #loop_annotation}
              %138 = cute_nvgpu.atom.set_value(%128, %true : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_tf32_tf32_f32_128x128x8_
              %139 = builtin.unrealized_conversion_cast %138 : !mma_tf32_tf32_f32_128x128x8_ to !llvm.struct<(i1, i1, i1)>
              scf.yield %139 : !llvm.struct<(i1, i1, i1)>
            } {loop_annotation = #loop_annotation2}
            %120 = nvvm.elect.sync -> i1
            scf.if %120 {
              %int_tuple_63 = cute.make_int_tuple(%arg26) : (i32) -> !cute.int_tuple<"?">
              %ptr_64 = cute.add_offset(%ptr_8, %int_tuple_63) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
              %128 = builtin.unrealized_conversion_cast %ptr_64 : !cute.ptr<i64, smem> to !llvm.ptr<3>
              nvvm.tcgen05.commit.arrive %128 : !llvm.ptr<3>
            }
            %121 = arith.addi %arg26, %c1_i32 : i32
            %122 = arith.addi %arg25, %c1_i32 : i32
            %123 = arith.cmpi eq, %121, %c6_i32 : i32
            %124 = arith.select %123, %c0_i32, %121 : i32
            %125 = scf.if %123 -> (i32) {
              %128 = arith.xori %arg27, %c1_i32 : i32
              scf.yield %128 : i32
            } else {
              scf.yield %arg27 : i32
            }
            %126 = arith.cmpi sgt, %73, %122 : i32
            %127 = scf.if %126 -> (i1) {
              %int_tuple_63 = cute.make_int_tuple(%124) : (i32) -> !cute.int_tuple<"?">
              %ptr_64 = cute.add_offset(%iter_7, %int_tuple_63) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
              %128 = builtin.unrealized_conversion_cast %ptr_64 : !cute.ptr<i64, smem> to !llvm.ptr<3>
              %129 = nvvm.mbarrier.wait.parity %128, %125 {kind = #nvvm.mbar_wait<try>} : !llvm.ptr<3>, i32 -> i1
              scf.yield %129 : i1
            } else {
              scf.yield %true : i1
            }
            scf.yield %127, %119, %122, %124, %125 : i1, !llvm.struct<(i1, i1, i1)>, i32, i32, i32
          }
          %108 = nvvm.elect.sync -> i1
          scf.if %108 {
            %ptr_63 = cute.add_offset(%iter_9, %int_tuple_61) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
            %117 = builtin.unrealized_conversion_cast %ptr_63 : !cute.ptr<i64, smem> to !llvm.ptr<3>
            nvvm.tcgen05.commit.arrive %117 : !llvm.ptr<3>
          }
          %109 = arith.addi %arg18, %c1_i32 : i32
          %110 = arith.addi %arg17, %c1_i32 : i32
          %111 = arith.cmpi eq, %109, %c2_i32 : i32
          %112 = arith.select %111, %c0_i32, %109 : i32
          %113 = scf.if %111 -> (i32) {
            %117 = arith.xori %arg19, %c1_i32 : i32
            scf.yield %117 : i32
          } else {
            scf.yield %arg19 : i32
          }
          %114 = arith.addi %arg20, %89 : i32
          %115 = arith.addi %arg21, %c1_i32 : i32
          %116 = arith.cmpi sgt, %90, %114 : i32
          scf.yield %116, %107#3, %107#4, %107#1, %110, %112, %113, %114, %115 : i1, i32, i32, !llvm.struct<(i1, i1, i1)>, i32, i32, i32, i32, i32
        }
        %98 = nvvm.read.ptx.sreg.cluster.ctarank : i32
        %99 = cute_nvgpu.arch.make_warp_uniform(%98) : i32
        %100 = arith.remsi %99, %c2_i32 : i32
        %101 = arith.cmpi eq, %100, %c0_i32 : i32
        scf.if %101 {
          %102 = arith.addi %97#4, %c1_i32 : i32
          %103 = arith.cmpi eq, %102, %c2_i32 : i32
          %104 = arith.select %103, %c0_i32, %102 : i32
          %105 = scf.if %103 -> (i32) {
            %107 = arith.xori %97#5, %c1_i32 : i32
            scf.yield %107 : i32
          } else {
            scf.yield %97#5 : i32
          }
          %int_tuple_60 = cute.make_int_tuple(%104) : (i32) -> !cute.int_tuple<"?">
          %ptr_61 = cute.add_offset(%ptr_10, %int_tuple_60) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
          %106 = builtin.unrealized_conversion_cast %ptr_61 : !cute.ptr<i64, smem> to !llvm.ptr<3>
          nvvm.mbarrier.try_wait.parity.shared %106, %105, %c10000000_i32 : !llvm.ptr<3>, i32, i32
        }
      }
      %83 = arith.cmpi slt, %49, %c4_i32 : i32
      scf.if %83 {
        scf.if %51 {
          cute_nvgpu.arch.sm100.alloc_tmem(%c256_i32, %iter) [ cta_1] : i32, !cute.ptr<i32, smem, align<8>>
        }
        nvvm.barrier id = %c3_i32 number_of_threads = %c160_i32
        %tmem_ptr = cute_nvgpu.arch.sm100.retrieve_tmem_ptr(%iter) : !cute.ptr<i32, smem, align<8>> -> !cute.ptr<f32, tmem, align<16>>
        %coord = cute.make_coord(%38) : (i32) -> !cute.coord<"?">
        %85 = cute.get_scalars(%coord) <{only_dynamic}> : !cute.coord<"?">
        %86 = arith.divsi %85, %c32_i32 : i32
        %87 = arith.muli %86, %c2097152_i32 : i32
        %iv = cute.assume(%87) : (i32) -> !cute.i32<divby 2097152>
        %int_tuple_55 = cute.make_int_tuple(%iv) : (!cute.i32<divby 2097152>) -> !cute.int_tuple<"?{div=2097152}">
        %ptr_56 = cute.add_offset(%tmem_ptr, %int_tuple_55) : (!cute.ptr<f32, tmem, align<16>>, !cute.int_tuple<"?{div=2097152}">) -> !cute.ptr<f32, tmem, align<16>>
        %rmem = cute.memref.alloca() : !memref_rmem_f32_
        %iter_57 = cute.get_iter(%rmem) : !memref_rmem_f32_
        %rmem_58 = cute.memref.alloca() : !memref_rmem_f32_
        %atom = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<f32>
        %88 = cute.make_tiled_copy(%atom) : !copy_simt
        %89 = arith.remsi %85, %c32_i32 : i32
        %90 = arith.muli %89, %c16_i32 : i32
        %91 = arith.muli %86, %c512_i32 : i32
        %92 = arith.addi %90, %91 : i32
        %iv_59 = cute.assume(%92) : (i32) -> !cute.i32<divby 16>
        %int_tuple_60 = cute.make_int_tuple(%iv_59) : (!cute.i32<divby 16>) -> !cute.int_tuple<"?{div=16}">
        %ptr_61 = cute.add_offset(%iter_13, %int_tuple_60) : (!cute.ptr<f32, smem, align<1024>, S<2,4,3>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<f32, smem, align<64>, S<2,4,3>>
        %iter_62 = cute.get_iter(%rmem_58) : !memref_rmem_f32_
        %rmem_63 = cute.memref.alloca() : !memref_rmem_f32_
        %93 = cute.make_tiled_copy(%atom) : !copy_simt
        %ptr_64 = cute.add_offset(%iter_14, %int_tuple_60) : (!cute.ptr<f32, smem, align<1024>, S<2,4,3>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<f32, smem, align<64>, S<2,4,3>>
        %iter_65 = cute.get_iter(%rmem_63) : !memref_rmem_f32_
        %view = cute.make_view(%iter_65) : !memref_rmem_f32_1
        %94:3 = cute.get_scalars(%lay_45) <{only_dynamic}> : !cute.layout<"((128,128),1,1,?,?,?):((1@1,1@0),0,0,128@1,128@0,1@2)">
        %shape_66 = cute.make_shape(%94#0, %94#1, %94#2) : (i32, i32, i32) -> !cute.shape<"(128,128,?,?,?)">
        %lay_67 = cute.make_layout(%shape_66, %19) : !cute.layout<"(128,128,?,?,?):(1@1,1@0,128@1,128@0,1@2)">
        %95:3 = cute.get_scalars(%lay_67) <{only_dynamic}> : !cute.layout<"(128,128,?,?,?):(1@1,1@0,128@1,128@0,1@2)">
        %shape_68 = cute.make_shape(%95#0, %95#1, %95#2) : (i32, i32, i32) -> !cute.shape<"(128,16,1,8,?,?,?)">
        %lay_69 = cute.make_layout(%shape_68, %10) : !cute.layout<"(128,16,1,8,?,?,?):(1@1,1@0,0,16@0,128@1,128@0,1@2)">
        %96:3 = cute.get_scalars(%lay_69) <{only_dynamic}> : !cute.layout<"(128,16,1,8,?,?,?):(1@1,1@0,0,16@0,128@1,128@0,1@2)">
        %shape_70 = cute.make_shape(%96#0, %96#1, %96#2) : (i32, i32, i32) -> !cute.shape<"((128,16),1,8,?,?,?)">
        %lay_71 = cute.make_layout(%shape_70, %9) : !cute.layout<"((128,16),1,8,?,?,?):((1@1,1@0),0,16@0,128@1,128@0,1@2)">
        %97:3 = cute.get_scalars(%lay_71) <{only_dynamic}> : !cute.layout<"((128,16),1,8,?,?,?):((1@1,1@0),0,16@0,128@1,128@0,1@2)">
        %shape_72 = cute.make_shape(%97#0, %97#1, %97#2) : (i32, i32, i32) -> !cute.shape<"(((16,128),1),1,8,?,?,?)">
        %lay_73 = cute.make_layout(%shape_72, %8) : !cute.layout<"(((16,128),1),1,8,?,?,?):(((1@0,1@1),0),0,16@0,128@1,128@0,1@2)">
        %98 = nvvm.read.ptx.sreg.ctaid.z range <i32, 0, 65535> : i32
        %99 = nvvm.read.ptx.sreg.nctaid.x range <i32, 1, 2147483647> : i32
        %100 = nvvm.read.ptx.sreg.nctaid.y range <i32, 1, 65535> : i32
        %101 = nvvm.read.ptx.sreg.nctaid.z range <i32, 1, 65535> : i32
        %int_tuple_74 = cute.make_int_tuple(%99, %100, %101) : (i32, i32, i32) -> !cute.int_tuple<"(?,?,?)">
        %sz_75 = cute.size(%int_tuple_74) : (!cute.int_tuple<"(?,?,?)">) -> !cute.int_tuple<"?">
        %e0_76 = cute.get_leaves(%sz_75) : !cute.int_tuple<"?">
        %div = cute.tuple_div(%e0_76, %29) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
        %102 = cute.get_scalars(%div) : !cute.int_tuple<"?">
        %sz_77 = cute.size(%lay) : (!cute.layout<"(?,?,?):(1,?,?)">) -> !cute.int_tuple<"?">
        %e0_78 = cute.get_leaves(%sz_77) : !cute.int_tuple<"?">
        %103 = cute.get_scalars(%e0_78) : !cute.int_tuple<"?">
        %104 = arith.cmpi sgt, %103, %98 : i32
        %105 = cute.get_hier_coord(%98, %lay) : (i32, !cute.layout<"(?,?,?):(1,?,?)">) -> !cute.coord<"(?,?,?)">
        %e0_79, %e1_80, %e2_81 = cute.get_leaves(%105) : !cute.coord<"(?,?,?)">
        %itup = cute.to_int_tuple(%e0_79) : !cute.coord<"?"> to !cute.int_tuple<"?">
        %itup_82 = cute.to_int_tuple(%e1_80) : !cute.coord<"?"> to !cute.int_tuple<"?">
        %itup_83 = cute.to_int_tuple(%e2_81) : !cute.coord<"?"> to !cute.int_tuple<"?">
        %mul = cute.tuple_mul(%itup, %29) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
        %106 = cute.get_scalars(%mul) : !cute.int_tuple<"?">
        %mul_84 = cute.tuple_mul(%itup_82, %29) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
        %107 = cute.get_scalars(%mul_84) : !cute.int_tuple<"?">
        %mul_85 = cute.tuple_mul(%itup_83, %29) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
        %108 = cute.get_scalars(%mul_85) : !cute.int_tuple<"?">
        %109 = cute.get_scalars(%29) : !cute.int_tuple<"1">
        %110 = builtin.unrealized_conversion_cast %iter_57 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
        %swizzled = cute.apply_swizzle(%ptr_61) : !cute.ptr<f32, smem, align<64>, S<2,4,3>>
        %111 = builtin.unrealized_conversion_cast %iter_62 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
        %ptr_86 = cute.add_offset(%iter_62, %26) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
        %ptr_87 = cute.add_offset(%ptr_61, %26) : (!cute.ptr<f32, smem, align<64>, S<2,4,3>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, smem, align<16>, S<2,4,3>>
        %swizzled_88 = cute.apply_swizzle(%ptr_87) : !cute.ptr<f32, smem, align<16>, S<2,4,3>>
        %112 = builtin.unrealized_conversion_cast %ptr_86 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
        %ptr_89 = cute.add_offset(%iter_62, %4) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<f32, rmem, align<32>>
        %ptr_90 = cute.add_offset(%ptr_61, %4) : (!cute.ptr<f32, smem, align<64>, S<2,4,3>>, !cute.int_tuple<"8">) -> !cute.ptr<f32, smem, align<32>, S<2,4,3>>
        %swizzled_91 = cute.apply_swizzle(%ptr_90) : !cute.ptr<f32, smem, align<32>, S<2,4,3>>
        %113 = builtin.unrealized_conversion_cast %ptr_89 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
        %ptr_92 = cute.add_offset(%iter_62, %3) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<f32, rmem, align<16>>
        %ptr_93 = cute.add_offset(%ptr_61, %3) : (!cute.ptr<f32, smem, align<64>, S<2,4,3>>, !cute.int_tuple<"12">) -> !cute.ptr<f32, smem, align<16>, S<2,4,3>>
        %swizzled_94 = cute.apply_swizzle(%ptr_93) : !cute.ptr<f32, smem, align<16>, S<2,4,3>>
        %114 = builtin.unrealized_conversion_cast %ptr_92 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
        %view_95 = cute.make_view(%iter_57) : !memref_rmem_f32_1
        %view_96 = cute.make_view(%iter_62) : !memref_rmem_f32_1
        %115 = vector.broadcast %arg12 : f32 to vector<16xf32>
        %116 = vector.broadcast %arg13 : f32 to vector<16xf32>
        %swizzled_97 = cute.apply_swizzle(%ptr_64) : !cute.ptr<f32, smem, align<64>, S<2,4,3>>
        %117 = builtin.unrealized_conversion_cast %iter_65 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
        %ptr_98 = cute.add_offset(%iter_65, %26) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
        %ptr_99 = cute.add_offset(%ptr_64, %26) : (!cute.ptr<f32, smem, align<64>, S<2,4,3>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, smem, align<16>, S<2,4,3>>
        %swizzled_100 = cute.apply_swizzle(%ptr_99) : !cute.ptr<f32, smem, align<16>, S<2,4,3>>
        %118 = builtin.unrealized_conversion_cast %ptr_98 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
        %ptr_101 = cute.add_offset(%iter_65, %4) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<f32, rmem, align<32>>
        %ptr_102 = cute.add_offset(%ptr_64, %4) : (!cute.ptr<f32, smem, align<64>, S<2,4,3>>, !cute.int_tuple<"8">) -> !cute.ptr<f32, smem, align<32>, S<2,4,3>>
        %swizzled_103 = cute.apply_swizzle(%ptr_102) : !cute.ptr<f32, smem, align<32>, S<2,4,3>>
        %119 = builtin.unrealized_conversion_cast %ptr_101 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
        %ptr_104 = cute.add_offset(%iter_65, %3) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<f32, rmem, align<16>>
        %ptr_105 = cute.add_offset(%ptr_64, %3) : (!cute.ptr<f32, smem, align<64>, S<2,4,3>>, !cute.int_tuple<"12">) -> !cute.ptr<f32, smem, align<16>, S<2,4,3>>
        %swizzled_106 = cute.apply_swizzle(%ptr_105) : !cute.ptr<f32, smem, align<16>, S<2,4,3>>
        %120 = builtin.unrealized_conversion_cast %ptr_104 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
        %121:11 = scf.while (%arg14 = %106, %arg15 = %107, %arg16 = %108, %arg17 = %104, %arg18 = %c0_i32, %arg19 = %c0_i32, %arg20 = %c0_i32, %arg21 = %c0_i32, %arg22 = %c0_i32, %arg23 = %c0_i32, %arg24 = %98, %arg25 = %c0_i32) : (i32, i32, i32, i1, i32, i32, i32, i32, i32, i32, i32, i32) -> (i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) {
          scf.condition(%arg17) %arg14, %arg15, %arg16, %arg18, %arg19, %arg20, %arg21, %arg22, %arg23, %arg24, %arg25 : i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32
        } do {
        ^bb0(%arg14: i32, %arg15: i32, %arg16: i32, %arg17: i32, %arg18: i32, %arg19: i32, %arg20: i32, %arg21: i32, %arg22: i32, %arg23: i32, %arg24: i32):
          %coord_107 = cute.make_coord(%arg14, %arg15, %arg16) : (i32, i32, i32) -> !cute.coord<"(_,_,_,?,?,?)">
          %idx = cute.crd2idx(%coord_107, %lay_73) : (!cute.coord<"(_,_,_,?,?,?)">, !cute.layout<"(((16,128),1),1,8,?,?,?):(((1@0,1@1),0),0,16@0,128@1,128@0,1@2)">) -> !cute.int_tuple<"(?{div=128},?{div=128},?)">
          %tup = cute.add_offset(%21, %idx) : (!cute.int_tuple<"(0,0,0)">, !cute.int_tuple<"(?{div=128},?{div=128},?)">) -> !cute.int_tuple<"(?{div=128},?{div=128},?)">
          %coord_108 = cute.make_coord(%arg21) : (i32) -> !cute.coord<"(_,_,_,_,_,?)">
          %idx_109 = cute.crd2idx(%coord_108, %7) : (!cute.coord<"(_,_,_,_,_,?)">, !cute.layout<"(((16,32),1),1,1,1,8,2):(((1,65536),0),0,0,0,16,128)">) -> !cute.int_tuple<"?{div=128}">
          %ptr_110 = cute.add_offset(%ptr_56, %idx_109) : (!cute.ptr<f32, tmem, align<16>>, !cute.int_tuple<"?{div=128}">) -> !cute.ptr<f32, tmem, align<16>>
          %int_tuple_111 = cute.make_int_tuple(%arg21) : (i32) -> !cute.int_tuple<"?">
          %ptr_112 = cute.add_offset(%iter_9, %int_tuple_111) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
          %122 = builtin.unrealized_conversion_cast %ptr_112 : !cute.ptr<i64, smem> to !llvm.ptr<3>
          nvvm.mbarrier.try_wait.parity.shared %122, %arg22, %c10000000_i32 : !llvm.ptr<3>, i32, i32
          %123 = arith.muli %arg24, %c8_i32 : i32
          %124:3 = scf.for %arg25 = %c0_i32 to %c8_i32 step %c1_i32 iter_args(%arg26 = %arg17, %arg27 = %arg18, %arg28 = %arg19) -> (i32, i32, i32)  : i32 {
            %coord_122 = cute.make_coord(%arg25) : (i32) -> !cute.coord<"(_,_,_,?)">
            %idx_123 = cute.crd2idx(%coord_122, %6) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"(((16,32),1),1,1,(1,8)):(((1,65536),0),0,0,(0,16))">) -> !cute.int_tuple<"?{div=16}">
            %ptr_124 = cute.add_offset(%ptr_110, %idx_123) : (!cute.ptr<f32, tmem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<f32, tmem, align<16>>
            scf.for %arg29 = %c0_i32 to %109 step %c1_i32  : i32 {
              %159 = "cute_nvgpu.arch.copy.SM100.tmem_load"(%ptr_124) <{num_b = 32 : i32, num_dp = 32 : i32, num_rep = 16 : i32}> : (!cute.ptr<f32, tmem, align<16>>) -> vector<16xi32>
              llvm.store %159, %110 : vector<16xi32>, !llvm.ptr
            } {llvm.loop_annotation = #loop_annotation}
            %int_tuple_125 = cute.make_int_tuple(%arg27) : (i32) -> !cute.int_tuple<"?">
            %ptr_126 = cute.add_offset(%iter_11, %int_tuple_125) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
            %138 = builtin.unrealized_conversion_cast %ptr_126 : !cute.ptr<i64, smem> to !llvm.ptr<3>
            nvvm.mbarrier.try_wait.parity.shared %138, %arg28, %c10000000_i32 : !llvm.ptr<3>, i32, i32
            %coord_127 = cute.make_coord(%arg27) : (i32) -> !cute.coord<"(_,_,_,?)">
            %idx_128 = cute.crd2idx(%coord_127, %5) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((1,16),1,1,(1,2)):((0,1),0,0,(0,2048))">) -> !cute.int_tuple<"?{div=2048}">
            %ptr_129 = cute.add_offset(%swizzled, %idx_128) : (!cute.ptr<f32, smem, align<64>, S<2,4,3>>, !cute.int_tuple<"?{div=2048}">) -> !cute.ptr<f32, smem, align<64>, S<2,4,3>>
            %139 = builtin.unrealized_conversion_cast %ptr_129 : !cute.ptr<f32, smem, align<64>, S<2,4,3>> to !llvm.ptr<3>
            %ptr_130 = cute.add_offset(%swizzled_88, %idx_128) : (!cute.ptr<f32, smem, align<16>, S<2,4,3>>, !cute.int_tuple<"?{div=2048}">) -> !cute.ptr<f32, smem, align<16>, S<2,4,3>>
            %140 = builtin.unrealized_conversion_cast %ptr_130 : !cute.ptr<f32, smem, align<16>, S<2,4,3>> to !llvm.ptr<3>
            %ptr_131 = cute.add_offset(%swizzled_91, %idx_128) : (!cute.ptr<f32, smem, align<32>, S<2,4,3>>, !cute.int_tuple<"?{div=2048}">) -> !cute.ptr<f32, smem, align<32>, S<2,4,3>>
            %141 = builtin.unrealized_conversion_cast %ptr_131 : !cute.ptr<f32, smem, align<32>, S<2,4,3>> to !llvm.ptr<3>
            %ptr_132 = cute.add_offset(%swizzled_94, %idx_128) : (!cute.ptr<f32, smem, align<16>, S<2,4,3>>, !cute.int_tuple<"?{div=2048}">) -> !cute.ptr<f32, smem, align<16>, S<2,4,3>>
            %142 = builtin.unrealized_conversion_cast %ptr_132 : !cute.ptr<f32, smem, align<16>, S<2,4,3>> to !llvm.ptr<3>
            scf.for %arg29 = %c0_i32 to %109 step %c1_i32  : i32 {
              %159 = llvm.load %139 {alignment = 16 : i64} : !llvm.ptr<3> -> vector<4xf32>
              llvm.store %159, %111 {alignment = 16 : i64} : vector<4xf32>, !llvm.ptr
              %160 = llvm.load %140 {alignment = 16 : i64} : !llvm.ptr<3> -> vector<4xf32>
              llvm.store %160, %112 {alignment = 16 : i64} : vector<4xf32>, !llvm.ptr
              %161 = llvm.load %141 {alignment = 16 : i64} : !llvm.ptr<3> -> vector<4xf32>
              llvm.store %161, %113 {alignment = 16 : i64} : vector<4xf32>, !llvm.ptr
              %162 = llvm.load %142 {alignment = 16 : i64} : !llvm.ptr<3> -> vector<4xf32>
              llvm.store %162, %114 {alignment = 16 : i64} : vector<4xf32>, !llvm.ptr
            } {llvm.loop_annotation = #loop_annotation}
            nvvm.fence.proxy {kind = #nvvm.proxy_kind<async.shared>, space = #nvvm.shared_space<cta>}
            scf.if %56 {
              %ptr_139 = cute.add_offset(%ptr_12, %int_tuple_125) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
              %159 = builtin.unrealized_conversion_cast %ptr_139 : !cute.ptr<i64, smem> to !llvm.ptr<3>
              nvvm.mbarrier.txn %159, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>} : !llvm.ptr<3>, i32
            }
            %143 = arith.addi %arg27, %c1_i32 : i32
            %144 = arith.addi %arg26, %c1_i32 : i32
            %145 = arith.cmpi eq, %143, %c2_i32 : i32
            %146 = arith.select %145, %c0_i32, %143 : i32
            %147 = scf.if %145 -> (i32) {
              %159 = arith.xori %arg28, %c1_i32 : i32
              scf.yield %159 : i32
            } else {
              scf.yield %arg28 : i32
            }
            %148 = cute.memref.load_vec %view_95, row_major : !memref_rmem_f32_1
            %149 = cute.memref.load_vec %view_96, row_major : !memref_rmem_f32_1
            %150 = arith.mulf %115, %148 : vector<16xf32>
            %151 = arith.mulf %116, %149 : vector<16xf32>
            %152 = arith.addf %150, %151 : vector<16xf32>
            cute.memref.store_vec %152, %view, row_major : !memref_rmem_f32_1
            %153 = arith.addi %123, %arg25 : i32
            %154 = arith.remsi %153, %c2_i32 : i32
            %coord_133 = cute.make_coord(%154) : (i32) -> !cute.coord<"(_,_,_,?)">
            %idx_134 = cute.crd2idx(%coord_133, %5) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((1,16),1,1,(1,2)):((0,1),0,0,(0,2048))">) -> !cute.int_tuple<"?{div=2048}">
            %ptr_135 = cute.add_offset(%swizzled_97, %idx_134) : (!cute.ptr<f32, smem, align<64>, S<2,4,3>>, !cute.int_tuple<"?{div=2048}">) -> !cute.ptr<f32, smem, align<64>, S<2,4,3>>
            %155 = builtin.unrealized_conversion_cast %ptr_135 : !cute.ptr<f32, smem, align<64>, S<2,4,3>> to !llvm.ptr<3>
            %ptr_136 = cute.add_offset(%swizzled_100, %idx_134) : (!cute.ptr<f32, smem, align<16>, S<2,4,3>>, !cute.int_tuple<"?{div=2048}">) -> !cute.ptr<f32, smem, align<16>, S<2,4,3>>
            %156 = builtin.unrealized_conversion_cast %ptr_136 : !cute.ptr<f32, smem, align<16>, S<2,4,3>> to !llvm.ptr<3>
            %ptr_137 = cute.add_offset(%swizzled_103, %idx_134) : (!cute.ptr<f32, smem, align<32>, S<2,4,3>>, !cute.int_tuple<"?{div=2048}">) -> !cute.ptr<f32, smem, align<32>, S<2,4,3>>
            %157 = builtin.unrealized_conversion_cast %ptr_137 : !cute.ptr<f32, smem, align<32>, S<2,4,3>> to !llvm.ptr<3>
            %ptr_138 = cute.add_offset(%swizzled_106, %idx_134) : (!cute.ptr<f32, smem, align<16>, S<2,4,3>>, !cute.int_tuple<"?{div=2048}">) -> !cute.ptr<f32, smem, align<16>, S<2,4,3>>
            %158 = builtin.unrealized_conversion_cast %ptr_138 : !cute.ptr<f32, smem, align<16>, S<2,4,3>> to !llvm.ptr<3>
            scf.for %arg29 = %c0_i32 to %109 step %c1_i32  : i32 {
              %159 = llvm.load %117 {alignment = 16 : i64} : !llvm.ptr -> vector<4xf32>
              llvm.store %159, %155 {alignment = 16 : i64} : vector<4xf32>, !llvm.ptr<3>
              %160 = llvm.load %118 {alignment = 16 : i64} : !llvm.ptr -> vector<4xf32>
              llvm.store %160, %156 {alignment = 16 : i64} : vector<4xf32>, !llvm.ptr<3>
              %161 = llvm.load %119 {alignment = 16 : i64} : !llvm.ptr -> vector<4xf32>
              llvm.store %161, %157 {alignment = 16 : i64} : vector<4xf32>, !llvm.ptr<3>
              %162 = llvm.load %120 {alignment = 16 : i64} : !llvm.ptr -> vector<4xf32>
              llvm.store %162, %158 {alignment = 16 : i64} : vector<4xf32>, !llvm.ptr<3>
            } {llvm.loop_annotation = #loop_annotation}
            nvvm.fence.proxy {kind = #nvvm.proxy_kind<async.shared>, space = #nvvm.shared_space<cta>}
            nvvm.barrier id = %c2_i32 number_of_threads = %c128_i32
            scf.if %51 {
              %coord_139 = cute.make_coord(%154) : (i32) -> !cute.coord<"(_,?)">
              %idx_140 = cute.crd2idx(%coord_139, %2) : (!cute.coord<"(_,?)">, !cute.layout<"((2048,1),(1,2)):((1,0),(0,2048))">) -> !cute.int_tuple<"?{div=2048}">
              %ptr_141 = cute.add_offset(%iter_14, %idx_140) : (!cute.ptr<f32, smem, align<1024>, S<2,4,3>>, !cute.int_tuple<"?{div=2048}">) -> !cute.ptr<f32, smem, align<1024>, S<2,4,3>>
              %coord_142 = cute.make_coord(%arg25) : (i32) -> !cute.coord<"(_,?)">
              %idx_143 = cute.crd2idx(%coord_142, %1) : (!cute.coord<"(_,?)">, !cute.layout<"(((16,128),1),(1,8)):(((1@0,1@1),0),(0,16@0))">) -> !cute.int_tuple<"(?{div=16},0)">
              %tup_144 = cute.add_offset(%tup, %idx_143) : (!cute.int_tuple<"(?{div=128},?{div=128},?)">, !cute.int_tuple<"(?{div=16},0)">) -> !cute.int_tuple<"(?{div=16},?{div=128},?)">
              %e0_145, %e1_146, %e2_147 = cute.get_leaves(%tup_144) : !cute.int_tuple<"(?{div=16},?{div=128},?)">
              %int_tuple_148 = cute.make_int_tuple(%e0_145, %e1_146, %e2_147) : (!cute.int_tuple<"?{div=16}">, !cute.int_tuple<"?{div=128}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=16},?{div=128},?)">
              %159 = cute_nvgpu.atom.make_exec_tma(%arg7) : (!cute_nvgpu.atom.non_exec_tiled_tma_store<f32, copy_bits = 65536, tma_gbasis = <"(16,128,1):(1@1,1@0,1@2)">, internal_val_type = f32>) -> !cute_nvgpu.atom.tma_store<f32, copy_bits = 65536, mode = tiled, g_stride = <"()"> tma_gbasis = <"(16,128,1):(1@1,1@0,1@2)">>
              %TMADescAddr = cute_nvgpu.get_tma_desc_addr(%159 : !cute_nvgpu.atom.tma_store<f32, copy_bits = 65536, mode = tiled, g_stride = <"()"> tma_gbasis = <"(16,128,1):(1@1,1@0,1@2)">>) -> !cute.ptr<generic, align<64>>
              %160:3 = cute.get_scalars(%int_tuple_148) : !cute.int_tuple<"(?{div=16},?{div=128},?)">
              scf.for %arg29 = %c0_i32 to %109 step %c1_i32  : i32 {
                cute_nvgpu.arch.copy.SM100.tma_store(%TMADescAddr : !cute.ptr<generic, align<64>>, %ptr_141 : !cute.ptr<f32, smem, align<1024>, S<2,4,3>>, [%160#0, %160#1, %160#2] : i32, i32, i32) mode = <tiled>
              } {llvm.loop_annotation = #loop_annotation}
              nvvm.cp.async.bulk.commit.group
              nvvm.cp.async.bulk.wait_group 1 {read}
            }
            nvvm.barrier id = %c2_i32 number_of_threads = %c128_i32
            scf.yield %144, %146, %147 : i32, i32, i32
          }
          %125 = nvvm.elect.sync -> i1
          scf.if %125 {
            %ptr_122 = cute.add_offset(%ptr_10, %int_tuple_111) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
            %138 = builtin.unrealized_conversion_cast %ptr_122 : !cute.ptr<i64, smem> to !llvm.ptr<3>
            nvvm.mbarrier.txn %138, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>} : !llvm.ptr<3>, i32
          }
          %126 = arith.addi %arg21, %c1_i32 : i32
          %127 = arith.addi %arg20, %c1_i32 : i32
          %128 = arith.cmpi eq, %126, %c2_i32 : i32
          %129 = arith.select %128, %c0_i32, %126 : i32
          %130 = scf.if %128 -> (i32) {
            %138 = arith.xori %arg22, %c1_i32 : i32
            scf.yield %138 : i32
          } else {
            scf.yield %arg22 : i32
          }
          %131 = arith.addi %arg23, %102 : i32
          %132 = arith.addi %arg24, %c1_i32 : i32
          %133 = arith.cmpi sgt, %103, %131 : i32
          %134 = cute.get_hier_coord(%131, %lay) : (i32, !cute.layout<"(?,?,?):(1,?,?)">) -> !cute.coord<"(?,?,?)">
          %e0_113, %e1_114, %e2_115 = cute.get_leaves(%134) : !cute.coord<"(?,?,?)">
          %itup_116 = cute.to_int_tuple(%e0_113) : !cute.coord<"?"> to !cute.int_tuple<"?">
          %itup_117 = cute.to_int_tuple(%e1_114) : !cute.coord<"?"> to !cute.int_tuple<"?">
          %itup_118 = cute.to_int_tuple(%e2_115) : !cute.coord<"?"> to !cute.int_tuple<"?">
          %mul_119 = cute.tuple_mul(%itup_116, %29) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
          %135 = cute.get_scalars(%mul_119) : !cute.int_tuple<"?">
          %mul_120 = cute.tuple_mul(%itup_117, %29) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
          %136 = cute.get_scalars(%mul_120) : !cute.int_tuple<"?">
          %mul_121 = cute.tuple_mul(%itup_118, %29) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
          %137 = cute.get_scalars(%mul_121) : !cute.int_tuple<"?">
          scf.yield %135, %136, %137, %133, %124#0, %124#1, %124#2, %127, %129, %130, %131, %132 : i32, i32, i32, i1, i32, i32, i32, i32, i32, i32, i32, i32
        }
        scf.if %51 {
          cute_nvgpu.arch.sm100.relinquish_tmem_alloc_permit [ cta_1]
        }
        nvvm.barrier id = %c2_i32 number_of_threads = %c128_i32
        scf.if %51 {
          cute_nvgpu.arch.sm100.dealloc_tmem(%tmem_ptr, %c256_i32) [ cta_1] : !cute.ptr<f32, tmem, align<16>>, i32
        }
        nvvm.cp.async.bulk.wait_group 0 {read}
      }
      %84 = arith.cmpi eq, %49, %c6_i32 : i32
      scf.if %84 {
        %85:3 = cute.get_scalars(%lay_43) <{only_dynamic}> : !cute.layout<"((128,128),1,1,?,?,?):((1@1,1@0),0,0,128@1,128@0,1@2)">
        %shape_55 = cute.make_shape(%85#0, %85#1, %85#2) : (i32, i32, i32) -> !cute.shape<"(128,128,?,?,?)">
        %lay_56 = cute.make_layout(%shape_55, %19) : !cute.layout<"(128,128,?,?,?):(1@1,1@0,128@1,128@0,1@2)">
        %86:3 = cute.get_scalars(%lay_56) <{only_dynamic}> : !cute.layout<"(128,128,?,?,?):(1@1,1@0,128@1,128@0,1@2)">
        %shape_57 = cute.make_shape(%86#0, %86#1, %86#2) : (i32, i32, i32) -> !cute.shape<"(128,16,1,8,?,?,?)">
        %lay_58 = cute.make_layout(%shape_57, %10) : !cute.layout<"(128,16,1,8,?,?,?):(1@1,1@0,0,16@0,128@1,128@0,1@2)">
        %87:3 = cute.get_scalars(%lay_58) <{only_dynamic}> : !cute.layout<"(128,16,1,8,?,?,?):(1@1,1@0,0,16@0,128@1,128@0,1@2)">
        %shape_59 = cute.make_shape(%87#0, %87#1, %87#2) : (i32, i32, i32) -> !cute.shape<"((128,16),1,8,?,?,?)">
        %lay_60 = cute.make_layout(%shape_59, %9) : !cute.layout<"((128,16),1,8,?,?,?):((1@1,1@0),0,16@0,128@1,128@0,1@2)">
        %88:3 = cute.get_scalars(%lay_60) <{only_dynamic}> : !cute.layout<"((128,16),1,8,?,?,?):((1@1,1@0),0,16@0,128@1,128@0,1@2)">
        %shape_61 = cute.make_shape(%88#0, %88#1, %88#2) : (i32, i32, i32) -> !cute.shape<"(((16,128),1),1,8,?,?,?)">
        %lay_62 = cute.make_layout(%shape_61, %8) : !cute.layout<"(((16,128),1),1,8,?,?,?):(((1@0,1@1),0),0,16@0,128@1,128@0,1@2)">
        %89 = nvvm.read.ptx.sreg.ctaid.z range <i32, 0, 65535> : i32
        %90 = nvvm.read.ptx.sreg.nctaid.x range <i32, 1, 2147483647> : i32
        %91 = nvvm.read.ptx.sreg.nctaid.y range <i32, 1, 65535> : i32
        %92 = nvvm.read.ptx.sreg.nctaid.z range <i32, 1, 65535> : i32
        %int_tuple_63 = cute.make_int_tuple(%90, %91, %92) : (i32, i32, i32) -> !cute.int_tuple<"(?,?,?)">
        %sz_64 = cute.size(%int_tuple_63) : (!cute.int_tuple<"(?,?,?)">) -> !cute.int_tuple<"?">
        %e0_65 = cute.get_leaves(%sz_64) : !cute.int_tuple<"?">
        %div = cute.tuple_div(%e0_65, %29) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
        %93 = cute.get_scalars(%div) : !cute.int_tuple<"?">
        %sz_66 = cute.size(%lay) : (!cute.layout<"(?,?,?):(1,?,?)">) -> !cute.int_tuple<"?">
        %e0_67 = cute.get_leaves(%sz_66) : !cute.int_tuple<"?">
        %94 = cute.get_scalars(%e0_67) : !cute.int_tuple<"?">
        %95 = arith.cmpi sgt, %94, %89 : i32
        %96 = cute.get_hier_coord(%89, %lay) : (i32, !cute.layout<"(?,?,?):(1,?,?)">) -> !cute.coord<"(?,?,?)">
        %e0_68, %e1_69, %e2_70 = cute.get_leaves(%96) : !cute.coord<"(?,?,?)">
        %itup = cute.to_int_tuple(%e0_68) : !cute.coord<"?"> to !cute.int_tuple<"?">
        %itup_71 = cute.to_int_tuple(%e1_69) : !cute.coord<"?"> to !cute.int_tuple<"?">
        %itup_72 = cute.to_int_tuple(%e2_70) : !cute.coord<"?"> to !cute.int_tuple<"?">
        %mul = cute.tuple_mul(%itup, %29) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
        %97 = cute.get_scalars(%mul) : !cute.int_tuple<"?">
        %mul_73 = cute.tuple_mul(%itup_71, %29) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
        %98 = cute.get_scalars(%mul_73) : !cute.int_tuple<"?">
        %mul_74 = cute.tuple_mul(%itup_72, %29) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
        %99 = cute.get_scalars(%mul_74) : !cute.int_tuple<"?">
        %100 = cute_nvgpu.atom.make_exec_tma(%arg5) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f32, copy_bits = 65536, tma_gbasis = <"(16,128,1):(1@1,1@0,1@2)">, internal_val_type = f32>) -> !cute_nvgpu.atom.tma_load<f32, copy_bits = 65536, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(16,128,1):(1@1,1@0,1@2)">>
        %101 = cute.get_scalars(%29) : !cute.int_tuple<"1">
        %102:8 = scf.while (%arg14 = %97, %arg15 = %98, %arg16 = %99, %arg17 = %95, %arg18 = %c0_i32, %arg19 = %c0_i32, %arg20 = %c1_i32, %arg21 = %89, %arg22 = %c0_i32) : (i32, i32, i32, i1, i32, i32, i32, i32, i32) -> (i32, i32, i32, i32, i32, i32, i32, i32) {
          scf.condition(%arg17) %arg14, %arg15, %arg16, %arg18, %arg19, %arg20, %arg21, %arg22 : i32, i32, i32, i32, i32, i32, i32, i32
        } do {
        ^bb0(%arg14: i32, %arg15: i32, %arg16: i32, %arg17: i32, %arg18: i32, %arg19: i32, %arg20: i32, %arg21: i32):
          %coord = cute.make_coord(%arg14, %arg15, %arg16) : (i32, i32, i32) -> !cute.coord<"(_,_,_,?,?,?)">
          %idx = cute.crd2idx(%coord, %lay_62) : (!cute.coord<"(_,_,_,?,?,?)">, !cute.layout<"(((16,128),1),1,8,?,?,?):(((1@0,1@1),0),0,16@0,128@1,128@0,1@2)">) -> !cute.int_tuple<"(?{div=128},?{div=128},?)">
          %tup = cute.add_offset(%21, %idx) : (!cute.int_tuple<"(0,0,0)">, !cute.int_tuple<"(?{div=128},?{div=128},?)">) -> !cute.int_tuple<"(?{div=128},?{div=128},?)">
          %109:3 = scf.for %arg22 = %c0_i32 to %c8_i32 step %c1_i32 iter_args(%arg23 = %arg17, %arg24 = %arg18, %arg25 = %arg19) -> (i32, i32, i32)  : i32 {
            %int_tuple_86 = cute.make_int_tuple(%arg24) : (i32) -> !cute.int_tuple<"?">
            %ptr_87 = cute.add_offset(%ptr_12, %int_tuple_86) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
            %117 = builtin.unrealized_conversion_cast %ptr_87 : !cute.ptr<i64, smem> to !llvm.ptr<3>
            nvvm.mbarrier.try_wait.parity.shared %117, %arg25, %c10000000_i32 : !llvm.ptr<3>, i32, i32
            %118 = nvvm.elect.sync -> i1
            scf.if %118 {
              %ptr_99 = cute.add_offset(%iter_11, %int_tuple_86) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
              %127 = builtin.unrealized_conversion_cast %ptr_99 : !cute.ptr<i64, smem> to !llvm.ptr<3>
              nvvm.mbarrier.txn %127, %c8192_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
            }
            %coord_88 = cute.make_coord(%arg22) : (i32) -> !cute.coord<"(_,?)">
            %idx_89 = cute.crd2idx(%coord_88, %1) : (!cute.coord<"(_,?)">, !cute.layout<"(((16,128),1),(1,8)):(((1@0,1@1),0),(0,16@0))">) -> !cute.int_tuple<"(?{div=16},0)">
            %tup_90 = cute.add_offset(%tup, %idx_89) : (!cute.int_tuple<"(?{div=128},?{div=128},?)">, !cute.int_tuple<"(?{div=16},0)">) -> !cute.int_tuple<"(?{div=16},?{div=128},?)">
            %e0_91, %e1_92, %e2_93 = cute.get_leaves(%tup_90) : !cute.int_tuple<"(?{div=16},?{div=128},?)">
            %coord_94 = cute.make_coord(%arg24) : (i32) -> !cute.coord<"(_,?)">
            %idx_95 = cute.crd2idx(%coord_94, %2) : (!cute.coord<"(_,?)">, !cute.layout<"((2048,1),(1,2)):((1,0),(0,2048))">) -> !cute.int_tuple<"?{div=2048}">
            %ptr_96 = cute.add_offset(%iter_13, %idx_95) : (!cute.ptr<f32, smem, align<1024>, S<2,4,3>>, !cute.int_tuple<"?{div=2048}">) -> !cute.ptr<f32, smem, align<1024>, S<2,4,3>>
            %ptr_97 = cute.add_offset(%iter_11, %int_tuple_86) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
            %int_tuple_98 = cute.make_int_tuple(%e0_91, %e1_92, %e2_93) : (!cute.int_tuple<"?{div=16}">, !cute.int_tuple<"?{div=128}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=16},?{div=128},?)">
            %119 = cute_nvgpu.atom.set_value(%100, %ptr_97 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<f32, copy_bits = 65536, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(16,128,1):(1@1,1@0,1@2)">>
            %120 = cute_nvgpu.atom.get_value(%119 : !cute_nvgpu.atom.tma_load<f32, copy_bits = 65536, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(16,128,1):(1@1,1@0,1@2)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
            %TMADescAddr = cute_nvgpu.get_tma_desc_addr(%119 : !cute_nvgpu.atom.tma_load<f32, copy_bits = 65536, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(16,128,1):(1@1,1@0,1@2)">>) -> !cute.ptr<generic, align<64>>
            %121:3 = cute.get_scalars(%int_tuple_98) : !cute.int_tuple<"(?{div=16},?{div=128},?)">
            scf.for %arg26 = %c0_i32 to %101 step %c1_i32  : i32 {
              cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr : !cute.ptr<generic, align<64>>, %ptr_96 : !cute.ptr<f32, smem, align<1024>, S<2,4,3>>, %120 : !cute.ptr<smem, align<8>>, [%121#0, %121#1, %121#2] : i32, i32, i32) mode = <tiled> num_cta = 1 : i32
            } {llvm.loop_annotation = #loop_annotation}
            %122 = arith.addi %arg24, %c1_i32 : i32
            %123 = arith.addi %arg23, %c1_i32 : i32
            %124 = arith.cmpi eq, %122, %c2_i32 : i32
            %125 = arith.select %124, %c0_i32, %122 : i32
            %126 = scf.if %124 -> (i32) {
              %127 = arith.xori %arg25, %c1_i32 : i32
              scf.yield %127 : i32
            } else {
              scf.yield %arg25 : i32
            }
            scf.yield %123, %125, %126 : i32, i32, i32
          }
          %110 = arith.addi %arg20, %93 : i32
          %111 = arith.addi %arg21, %c1_i32 : i32
          %112 = arith.cmpi sgt, %94, %110 : i32
          %113 = cute.get_hier_coord(%110, %lay) : (i32, !cute.layout<"(?,?,?):(1,?,?)">) -> !cute.coord<"(?,?,?)">
          %e0_77, %e1_78, %e2_79 = cute.get_leaves(%113) : !cute.coord<"(?,?,?)">
          %itup_80 = cute.to_int_tuple(%e0_77) : !cute.coord<"?"> to !cute.int_tuple<"?">
          %itup_81 = cute.to_int_tuple(%e1_78) : !cute.coord<"?"> to !cute.int_tuple<"?">
          %itup_82 = cute.to_int_tuple(%e2_79) : !cute.coord<"?"> to !cute.int_tuple<"?">
          %mul_83 = cute.tuple_mul(%itup_80, %29) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
          %114 = cute.get_scalars(%mul_83) : !cute.int_tuple<"?">
          %mul_84 = cute.tuple_mul(%itup_81, %29) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
          %115 = cute.get_scalars(%mul_84) : !cute.int_tuple<"?">
          %mul_85 = cute.tuple_mul(%itup_82, %29) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
          %116 = cute.get_scalars(%mul_85) : !cute.int_tuple<"?">
          scf.yield %114, %115, %116, %112, %109#0, %109#1, %109#2, %110, %111 : i32, i32, i32, i1, i32, i32, i32, i32, i32
        }
        %103 = arith.addi %102#4, %c1_i32 : i32
        %104 = arith.cmpi eq, %103, %c2_i32 : i32
        %105 = arith.select %104, %c0_i32, %103 : i32
        %106 = scf.if %104 -> (i32) {
          %109 = arith.xori %102#5, %c1_i32 : i32
          scf.yield %109 : i32
        } else {
          scf.yield %102#5 : i32
        }
        %int_tuple_75 = cute.make_int_tuple(%105) : (i32) -> !cute.int_tuple<"?">
        %ptr_76 = cute.add_offset(%ptr_12, %int_tuple_75) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
        %107 = builtin.unrealized_conversion_cast %ptr_76 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        nvvm.mbarrier.try_wait.parity.shared %107, %106, %c10000000_i32 : !llvm.ptr<3>, i32, i32
        %108 = nvvm.elect.sync -> i1
        scf.if %108 {
          %ptr_77 = cute.add_offset(%iter_11, %int_tuple_75) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
          %109 = builtin.unrealized_conversion_cast %ptr_77 : !cute.ptr<i64, smem> to !llvm.ptr<3>
          nvvm.mbarrier.txn %109, %c8192_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
        }
      }
      return
    }
  }
  func.func @cutlass___call_____main__SM100PersistentDenseGemmAlphaBetaKernel_object_at__Tensorgmemoi641i64_Tensorgmemoi641i64_Tensorgmemoi641i64_Tensorgmemoi641i64_10_00_1_CUstream0x0_function(%arg0: !memref_gmem_tf32_, %arg1: !memref_gmem_tf32_, %arg2: !memref_gmem_f32_, %arg3: !memref_gmem_f32_, %arg4: f32, %arg5: f32, %arg6: !gpu.async.token) attributes {llvm.emit_c_interface} {
    %0 = llvm.mlir.constant(1080863910568919040 : i64) : i64
    %1 = llvm.mlir.constant(279458 : i64) : i64
    %2 = llvm.mlir.constant(127 : i64) : i64
    %3 = llvm.mlir.constant(2233785415175766016 : i64) : i64
    %4 = llvm.mlir.constant(353186 : i64) : i64
    %c230400_i32 = arith.constant 230400 : i32
    %c224 = arith.constant 224 : index
    %c1 = arith.constant 1 : index
    %c1_i32 = arith.constant 1 : i32
    %5 = cute.static : !cute.int_tuple<"1">
    %c128_i64 = arith.constant 128 : i64
    %c128_i32 = arith.constant 128 : i32
    %6 = cute.static : !cute.int_tuple<"(0,0,0)">
    %7 = cute.static : !cute.stride<"(1@1,1@0,1@2)">
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
    %8 = cute.static : !cute.layout<"((128,128),1,1,2):((65536,1),0,0,128)">
    %9 = cute.recast_layout<32, 32> (%8) : !cute.layout<"((128,128),1,1,2):((65536,1),0,0,128)"> to !cute.layout<"((128,128),1,1,2):((65536,1),0,0,128)">
    %atom = cute.make_atom() : () -> !cute_nvgpu.sm100.mma<128x128x8, num_cta = 1, ab_major = (k, k), elem_type = (tf32, tf32, f32), frag_kind = ss, c_scale_exp = 0>
    %10 = cute_nvgpu.atom.set_value(%atom, %false : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !cute_nvgpu.sm100.mma<128x128x8, num_cta = 1, ab_major = (k, k), elem_type = (tf32, tf32, f32), frag_kind = ss, c_scale_exp = 0>
    %11 = cute_nvgpu.atom.set_value(%10, %false : i1) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : !cute_nvgpu.sm100.mma<128x128x8, num_cta = 1, ab_major = (k, k), elem_type = (tf32, tf32, f32), frag_kind = ss, c_scale_exp = 0>
    %12 = cute_nvgpu.atom.set_value(%11, %false : i1) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : !cute_nvgpu.sm100.mma<128x128x8, num_cta = 1, ab_major = (k, k), elem_type = (tf32, tf32, f32), frag_kind = ss, c_scale_exp = 0>
    %13 = cute.make_tiled_mma(%12) : !mma_tf32_tf32_f32_128x128x8_
    %14 = llvm.alloca %c16_i32 x i64 {alignment = 64 : i64} : (i32) -> !llvm.ptr
    %iter = cute.get_iter(%arg0) : !memref_gmem_tf32_
    %lay = cute.get_layout(%arg0) : !memref_gmem_tf32_
    %15:5 = cute.get_scalars(%lay) <{only_dynamic}> : !cute.layout<"(?,?,?):(?{i64},1,?{i64})">
    %16 = arith.extui %15#1 : i32 to i64
    %17 = arith.extui %15#0 : i32 to i64
    %18 = llvm.mul %15#3, %c4_i64 : i64
    %19 = arith.extui %15#2 : i32 to i64
    %20 = llvm.mul %15#4, %c4_i64 : i64
    %21 = cute.ptrtoint(%iter) : !cute.ptr<tf32, gmem, align<16>> to i64
    %22 = llvm.getelementptr %14[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %22 : i64, !llvm.ptr
    %23 = llvm.getelementptr %14[0, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %23 : i64, !llvm.ptr
    %24 = llvm.getelementptr %14[0, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %24 : i64, !llvm.ptr
    %25 = llvm.getelementptr %14[0, 3] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %25 : i64, !llvm.ptr
    %26 = llvm.getelementptr %14[0, 4] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %26 : i64, !llvm.ptr
    %27 = llvm.getelementptr %14[0, 5] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %27 : i64, !llvm.ptr
    %28 = llvm.getelementptr %14[0, 6] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %28 : i64, !llvm.ptr
    %29 = llvm.getelementptr %14[0, 7] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %29 : i64, !llvm.ptr
    %30 = llvm.getelementptr %14[0, 8] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %30 : i64, !llvm.ptr
    %31 = llvm.getelementptr %14[0, 9] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %31 : i64, !llvm.ptr
    %32 = llvm.getelementptr %14[0, 10] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %32 : i64, !llvm.ptr
    %33 = llvm.getelementptr %14[0, 11] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %33 : i64, !llvm.ptr
    %34 = llvm.getelementptr %14[0, 12] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %34 : i64, !llvm.ptr
    %35 = llvm.getelementptr %14[0, 13] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %35 : i64, !llvm.ptr
    %36 = llvm.getelementptr %14[0, 14] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %36 : i64, !llvm.ptr
    %37 = llvm.getelementptr %14[0, 15] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %37 : i64, !llvm.ptr
    %38 = llvm.udiv %21, %c16_i64 : i64
    %39 = llvm.and %38, %c9007199254740991_i64 : i64
    %40 = llvm.shl %39, %c4_i64 : i64
    llvm.store %40, %22 : i64, !llvm.ptr
    %41 = llvm.sub %17, %c1_i64 : i64
    %42 = llvm.sub %19, %c1_i64 : i64
    %43 = llvm.sub %c1_i64, %c1_i64 : i64
    %44 = llvm.mul %41, %18 : i64
    %45 = llvm.mul %42, %20 : i64
    %46 = llvm.mul %43, %c0_i64 : i64
    %47 = llvm.add %44, %45 : i64
    %48 = llvm.add %46, %46 : i64
    %49 = llvm.mul %16, %c32_i64 : i64
    %50 = llvm.udiv %49, %c8_i64 : i64
    %51 = llvm.add %50, %47 : i64
    %52 = llvm.add %51, %48 : i64
    %53 = llvm.icmp "uge" %52, %c131072_i64 : i64
    %54 = llvm.zext %53 : i1 to i64
    %55 = llvm.shl %54, %c21_i64 : i64
    %56 = llvm.udiv %18, %c16_i64 : i64
    %57 = llvm.shl %56, %c32_i64 : i64
    %58 = llvm.or %c0_i64, %55 : i64
    %59 = llvm.or %58, %57 : i64
    %60 = llvm.or %4, %59 : i64
    llvm.store %60, %23 : i64, !llvm.ptr
    %61 = llvm.udiv %20, %c16_i64 : i64
    %62 = llvm.and %61, %c4294967295_i64 : i64
    %63 = llvm.shl %62, %c0_i64 : i64
    %64 = llvm.udiv %c0_i64, %c16_i64 : i64
    %65 = llvm.shl %64, %c32_i64 : i64
    %66 = llvm.or %63, %65 : i64
    llvm.store %66, %24 : i64, !llvm.ptr
    %67 = llvm.and %64, %c4294967295_i64 : i64
    %68 = llvm.shl %67, %c0_i64 : i64
    %69 = llvm.lshr %18, %c36_i64 : i64
    %70 = llvm.and %69, %c15_i64 : i64
    %71 = llvm.shl %70, %c32_i64 : i64
    %72 = llvm.lshr %20, %c36_i64 : i64
    %73 = llvm.and %72, %c15_i64 : i64
    %74 = llvm.shl %73, %c36_i64 : i64
    %75 = llvm.lshr %c0_i64, %c36_i64 : i64
    %76 = llvm.and %75, %c15_i64 : i64
    %77 = llvm.shl %76, %c40_i64 : i64
    %78 = llvm.shl %75, %c44_i64 : i64
    %79 = llvm.or %71, %74 : i64
    %80 = llvm.or %77, %78 : i64
    %81 = llvm.or %79, %80 : i64
    %82 = llvm.or %68, %81 : i64
    llvm.store %82, %25 : i64, !llvm.ptr
    %83 = llvm.sub %16, %c1_i64 : i64
    %84 = llvm.and %83, %c4294967295_i64 : i64
    %85 = llvm.shl %84, %c0_i64 : i64
    %86 = llvm.shl %41, %c32_i64 : i64
    %87 = llvm.or %85, %86 : i64
    llvm.store %87, %26 : i64, !llvm.ptr
    %88 = llvm.and %42, %c4294967295_i64 : i64
    %89 = llvm.shl %88, %c0_i64 : i64
    %90 = llvm.shl %43, %c32_i64 : i64
    %91 = llvm.or %89, %90 : i64
    llvm.store %91, %27 : i64, !llvm.ptr
    %92 = llvm.and %43, %c4294967295_i64 : i64
    %93 = llvm.or %92, %c0_i64 : i64
    %94 = llvm.or %93, %3 : i64
    llvm.store %94, %28 : i64, !llvm.ptr
    llvm.store %2, %29 : i64, !llvm.ptr
    %95 = builtin.unrealized_conversion_cast %14 : !llvm.ptr to !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>>
    %96 = cute.ptrtoint(%95) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>> to i64
    %97 = llvm.inttoptr %96 : i64 to !llvm.ptr
    %98 = llvm.load %97 {nontemporal} : !llvm.ptr -> !llvm.struct<(array<16 x i64>)>
    %99 = builtin.unrealized_conversion_cast %98 : !llvm.struct<(array<16 x i64>)> to !cute_nvgpu.tma_descriptor_tiled
    %atom_0 = cute.make_atom() : () -> !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, tf32, copy_bits = 131072, tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">, internal_val_type = tf32>
    %100 = cute_nvgpu.atom.set_value(%atom_0, %99 : !cute_nvgpu.tma_descriptor_tiled) {field = #cute_nvgpu.atom_copy_field_non_exec_tma_load<tma_desc>} : !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, tf32, copy_bits = 131072, tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">, internal_val_type = tf32>
    %101 = cute.get_shape(%lay) : (!cute.layout<"(?,?,?):(?{i64},1,?{i64})">) -> !cute.shape<"(?,?,?)">
    %lay_1 = cute.make_layout(%101, %7) : !cute.layout<"(?,?,?):(1@1,1@0,1@2)">
    %view = cute.make_view(%6, %lay_1) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">
    %102 = llvm.alloca %c16_i32 x i64 {alignment = 64 : i64} : (i32) -> !llvm.ptr
    %iter_2 = cute.get_iter(%arg1) : !memref_gmem_tf32_
    %lay_3 = cute.get_layout(%arg1) : !memref_gmem_tf32_
    %103:5 = cute.get_scalars(%lay_3) <{only_dynamic}> : !cute.layout<"(?,?,?):(?{i64},1,?{i64})">
    %104 = arith.extui %103#1 : i32 to i64
    %105 = arith.extui %103#0 : i32 to i64
    %106 = llvm.mul %103#3, %c4_i64 : i64
    %107 = arith.extui %103#2 : i32 to i64
    %108 = llvm.mul %103#4, %c4_i64 : i64
    %109 = cute.ptrtoint(%iter_2) : !cute.ptr<tf32, gmem, align<16>> to i64
    %110 = llvm.getelementptr %102[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %110 : i64, !llvm.ptr
    %111 = llvm.getelementptr %102[0, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %111 : i64, !llvm.ptr
    %112 = llvm.getelementptr %102[0, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %112 : i64, !llvm.ptr
    %113 = llvm.getelementptr %102[0, 3] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %113 : i64, !llvm.ptr
    %114 = llvm.getelementptr %102[0, 4] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %114 : i64, !llvm.ptr
    %115 = llvm.getelementptr %102[0, 5] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %115 : i64, !llvm.ptr
    %116 = llvm.getelementptr %102[0, 6] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %116 : i64, !llvm.ptr
    %117 = llvm.getelementptr %102[0, 7] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %117 : i64, !llvm.ptr
    %118 = llvm.getelementptr %102[0, 8] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %118 : i64, !llvm.ptr
    %119 = llvm.getelementptr %102[0, 9] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %119 : i64, !llvm.ptr
    %120 = llvm.getelementptr %102[0, 10] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %120 : i64, !llvm.ptr
    %121 = llvm.getelementptr %102[0, 11] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %121 : i64, !llvm.ptr
    %122 = llvm.getelementptr %102[0, 12] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %122 : i64, !llvm.ptr
    %123 = llvm.getelementptr %102[0, 13] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %123 : i64, !llvm.ptr
    %124 = llvm.getelementptr %102[0, 14] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %124 : i64, !llvm.ptr
    %125 = llvm.getelementptr %102[0, 15] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %125 : i64, !llvm.ptr
    %126 = llvm.udiv %109, %c16_i64 : i64
    %127 = llvm.and %126, %c9007199254740991_i64 : i64
    %128 = llvm.shl %127, %c4_i64 : i64
    llvm.store %128, %110 : i64, !llvm.ptr
    %129 = llvm.sub %105, %c1_i64 : i64
    %130 = llvm.sub %107, %c1_i64 : i64
    %131 = llvm.mul %129, %106 : i64
    %132 = llvm.mul %130, %108 : i64
    %133 = llvm.add %131, %132 : i64
    %134 = llvm.mul %104, %c32_i64 : i64
    %135 = llvm.udiv %134, %c8_i64 : i64
    %136 = llvm.add %135, %133 : i64
    %137 = llvm.add %136, %48 : i64
    %138 = llvm.icmp "uge" %137, %c131072_i64 : i64
    %139 = llvm.zext %138 : i1 to i64
    %140 = llvm.shl %139, %c21_i64 : i64
    %141 = llvm.udiv %106, %c16_i64 : i64
    %142 = llvm.shl %141, %c32_i64 : i64
    %143 = llvm.or %c0_i64, %140 : i64
    %144 = llvm.or %143, %142 : i64
    %145 = llvm.or %4, %144 : i64
    llvm.store %145, %111 : i64, !llvm.ptr
    %146 = llvm.udiv %108, %c16_i64 : i64
    %147 = llvm.and %146, %c4294967295_i64 : i64
    %148 = llvm.shl %147, %c0_i64 : i64
    %149 = llvm.or %148, %65 : i64
    llvm.store %149, %112 : i64, !llvm.ptr
    %150 = llvm.lshr %106, %c36_i64 : i64
    %151 = llvm.and %150, %c15_i64 : i64
    %152 = llvm.shl %151, %c32_i64 : i64
    %153 = llvm.lshr %108, %c36_i64 : i64
    %154 = llvm.and %153, %c15_i64 : i64
    %155 = llvm.shl %154, %c36_i64 : i64
    %156 = llvm.or %152, %155 : i64
    %157 = llvm.or %156, %80 : i64
    %158 = llvm.or %68, %157 : i64
    llvm.store %158, %113 : i64, !llvm.ptr
    %159 = llvm.sub %104, %c1_i64 : i64
    %160 = llvm.and %159, %c4294967295_i64 : i64
    %161 = llvm.shl %160, %c0_i64 : i64
    %162 = llvm.shl %129, %c32_i64 : i64
    %163 = llvm.or %161, %162 : i64
    llvm.store %163, %114 : i64, !llvm.ptr
    %164 = llvm.and %130, %c4294967295_i64 : i64
    %165 = llvm.shl %164, %c0_i64 : i64
    %166 = llvm.or %165, %90 : i64
    llvm.store %166, %115 : i64, !llvm.ptr
    llvm.store %94, %116 : i64, !llvm.ptr
    llvm.store %2, %117 : i64, !llvm.ptr
    %167 = builtin.unrealized_conversion_cast %102 : !llvm.ptr to !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>>
    %168 = cute.ptrtoint(%167) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>> to i64
    %169 = llvm.inttoptr %168 : i64 to !llvm.ptr
    %170 = llvm.load %169 {nontemporal} : !llvm.ptr -> !llvm.struct<(array<16 x i64>)>
    %171 = builtin.unrealized_conversion_cast %170 : !llvm.struct<(array<16 x i64>)> to !cute_nvgpu.tma_descriptor_tiled
    %172 = cute_nvgpu.atom.set_value(%atom_0, %171 : !cute_nvgpu.tma_descriptor_tiled) {field = #cute_nvgpu.atom_copy_field_non_exec_tma_load<tma_desc>} : !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, tf32, copy_bits = 131072, tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">, internal_val_type = tf32>
    %173 = cute.get_shape(%lay_3) : (!cute.layout<"(?,?,?):(?{i64},1,?{i64})">) -> !cute.shape<"(?,?,?)">
    %lay_4 = cute.make_layout(%173, %7) : !cute.layout<"(?,?,?):(1@1,1@0,1@2)">
    %view_5 = cute.make_view(%6, %lay_4) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">
    %174 = llvm.alloca %c16_i32 x i64 {alignment = 64 : i64} : (i32) -> !llvm.ptr
    %iter_6 = cute.get_iter(%arg3) : !memref_gmem_f32_
    %lay_7 = cute.get_layout(%arg3) : !memref_gmem_f32_
    %175:5 = cute.get_scalars(%lay_7) <{only_dynamic}> : !cute.layout<"(?,?,?):(?{i64},1,?{i64})">
    %176 = arith.extui %175#1 : i32 to i64
    %177 = arith.extui %175#0 : i32 to i64
    %178 = llvm.mul %175#3, %c4_i64 : i64
    %179 = arith.extui %175#2 : i32 to i64
    %180 = llvm.mul %175#4, %c4_i64 : i64
    %181 = cute.ptrtoint(%iter_6) : !cute.ptr<f32, gmem, align<16>> to i64
    %182 = llvm.getelementptr %174[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %182 : i64, !llvm.ptr
    %183 = llvm.getelementptr %174[0, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %183 : i64, !llvm.ptr
    %184 = llvm.getelementptr %174[0, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %184 : i64, !llvm.ptr
    %185 = llvm.getelementptr %174[0, 3] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %185 : i64, !llvm.ptr
    %186 = llvm.getelementptr %174[0, 4] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %186 : i64, !llvm.ptr
    %187 = llvm.getelementptr %174[0, 5] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %187 : i64, !llvm.ptr
    %188 = llvm.getelementptr %174[0, 6] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %188 : i64, !llvm.ptr
    %189 = llvm.getelementptr %174[0, 7] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %189 : i64, !llvm.ptr
    %190 = llvm.getelementptr %174[0, 8] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %190 : i64, !llvm.ptr
    %191 = llvm.getelementptr %174[0, 9] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %191 : i64, !llvm.ptr
    %192 = llvm.getelementptr %174[0, 10] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %192 : i64, !llvm.ptr
    %193 = llvm.getelementptr %174[0, 11] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %193 : i64, !llvm.ptr
    %194 = llvm.getelementptr %174[0, 12] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %194 : i64, !llvm.ptr
    %195 = llvm.getelementptr %174[0, 13] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %195 : i64, !llvm.ptr
    %196 = llvm.getelementptr %174[0, 14] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %196 : i64, !llvm.ptr
    %197 = llvm.getelementptr %174[0, 15] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %197 : i64, !llvm.ptr
    %198 = llvm.udiv %181, %c16_i64 : i64
    %199 = llvm.and %198, %c9007199254740991_i64 : i64
    %200 = llvm.shl %199, %c4_i64 : i64
    llvm.store %200, %182 : i64, !llvm.ptr
    %201 = llvm.sub %177, %c1_i64 : i64
    %202 = llvm.sub %179, %c1_i64 : i64
    %203 = llvm.mul %201, %178 : i64
    %204 = llvm.mul %202, %180 : i64
    %205 = llvm.add %203, %204 : i64
    %206 = llvm.mul %176, %c32_i64 : i64
    %207 = llvm.udiv %206, %c8_i64 : i64
    %208 = llvm.add %207, %205 : i64
    %209 = llvm.add %208, %48 : i64
    %210 = llvm.icmp "uge" %209, %c131072_i64 : i64
    %211 = llvm.zext %210 : i1 to i64
    %212 = llvm.shl %211, %c21_i64 : i64
    %213 = llvm.udiv %178, %c16_i64 : i64
    %214 = llvm.shl %213, %c32_i64 : i64
    %215 = llvm.or %c0_i64, %212 : i64
    %216 = llvm.or %215, %214 : i64
    %217 = llvm.or %1, %216 : i64
    llvm.store %217, %183 : i64, !llvm.ptr
    %218 = llvm.udiv %180, %c16_i64 : i64
    %219 = llvm.and %218, %c4294967295_i64 : i64
    %220 = llvm.shl %219, %c0_i64 : i64
    %221 = llvm.or %220, %65 : i64
    llvm.store %221, %184 : i64, !llvm.ptr
    %222 = llvm.lshr %178, %c36_i64 : i64
    %223 = llvm.and %222, %c15_i64 : i64
    %224 = llvm.shl %223, %c32_i64 : i64
    %225 = llvm.lshr %180, %c36_i64 : i64
    %226 = llvm.and %225, %c15_i64 : i64
    %227 = llvm.shl %226, %c36_i64 : i64
    %228 = llvm.or %224, %227 : i64
    %229 = llvm.or %228, %80 : i64
    %230 = llvm.or %68, %229 : i64
    llvm.store %230, %185 : i64, !llvm.ptr
    %231 = llvm.sub %176, %c1_i64 : i64
    %232 = llvm.and %231, %c4294967295_i64 : i64
    %233 = llvm.shl %232, %c0_i64 : i64
    %234 = llvm.shl %201, %c32_i64 : i64
    %235 = llvm.or %233, %234 : i64
    llvm.store %235, %186 : i64, !llvm.ptr
    %236 = llvm.and %202, %c4294967295_i64 : i64
    %237 = llvm.shl %236, %c0_i64 : i64
    %238 = llvm.or %237, %90 : i64
    llvm.store %238, %187 : i64, !llvm.ptr
    %239 = llvm.or %93, %0 : i64
    llvm.store %239, %188 : i64, !llvm.ptr
    llvm.store %2, %189 : i64, !llvm.ptr
    %240 = builtin.unrealized_conversion_cast %174 : !llvm.ptr to !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>>
    %241 = cute.ptrtoint(%240) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>> to i64
    %242 = llvm.inttoptr %241 : i64 to !llvm.ptr
    %243 = llvm.load %242 {nontemporal} : !llvm.ptr -> !llvm.struct<(array<16 x i64>)>
    %244 = builtin.unrealized_conversion_cast %243 : !llvm.struct<(array<16 x i64>)> to !cute_nvgpu.tma_descriptor_tiled
    %atom_8 = cute.make_atom() : () -> !cute_nvgpu.atom.non_exec_tiled_tma_store<f32, copy_bits = 65536, tma_gbasis = <"(16,128,1):(1@1,1@0,1@2)">, internal_val_type = f32>
    %245 = cute_nvgpu.atom.set_value(%atom_8, %244 : !cute_nvgpu.tma_descriptor_tiled) {field = #cute_nvgpu.atom_copy_field_non_exec_tma_store<tma_desc>} : !cute_nvgpu.atom.non_exec_tiled_tma_store<f32, copy_bits = 65536, tma_gbasis = <"(16,128,1):(1@1,1@0,1@2)">, internal_val_type = f32>
    %246 = cute.get_shape(%lay_7) : (!cute.layout<"(?,?,?):(?{i64},1,?{i64})">) -> !cute.shape<"(?,?,?)">
    %lay_9 = cute.make_layout(%246, %7) : !cute.layout<"(?,?,?):(1@1,1@0,1@2)">
    %view_10 = cute.make_view(%6, %lay_9) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">
    %247 = llvm.alloca %c16_i32 x i64 {alignment = 64 : i64} : (i32) -> !llvm.ptr
    %iter_11 = cute.get_iter(%arg2) : !memref_gmem_f32_
    %lay_12 = cute.get_layout(%arg2) : !memref_gmem_f32_
    %248:5 = cute.get_scalars(%lay_12) <{only_dynamic}> : !cute.layout<"(?,?,?):(?{i64},1,?{i64})">
    %249 = arith.extui %248#1 : i32 to i64
    %250 = arith.extui %248#0 : i32 to i64
    %251 = llvm.mul %248#3, %c4_i64 : i64
    %252 = arith.extui %248#2 : i32 to i64
    %253 = llvm.mul %248#4, %c4_i64 : i64
    %254 = cute.ptrtoint(%iter_11) : !cute.ptr<f32, gmem, align<16>> to i64
    %255 = llvm.getelementptr %247[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %255 : i64, !llvm.ptr
    %256 = llvm.getelementptr %247[0, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %256 : i64, !llvm.ptr
    %257 = llvm.getelementptr %247[0, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %257 : i64, !llvm.ptr
    %258 = llvm.getelementptr %247[0, 3] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %258 : i64, !llvm.ptr
    %259 = llvm.getelementptr %247[0, 4] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %259 : i64, !llvm.ptr
    %260 = llvm.getelementptr %247[0, 5] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %260 : i64, !llvm.ptr
    %261 = llvm.getelementptr %247[0, 6] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %261 : i64, !llvm.ptr
    %262 = llvm.getelementptr %247[0, 7] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %262 : i64, !llvm.ptr
    %263 = llvm.getelementptr %247[0, 8] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %263 : i64, !llvm.ptr
    %264 = llvm.getelementptr %247[0, 9] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %264 : i64, !llvm.ptr
    %265 = llvm.getelementptr %247[0, 10] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %265 : i64, !llvm.ptr
    %266 = llvm.getelementptr %247[0, 11] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %266 : i64, !llvm.ptr
    %267 = llvm.getelementptr %247[0, 12] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %267 : i64, !llvm.ptr
    %268 = llvm.getelementptr %247[0, 13] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %268 : i64, !llvm.ptr
    %269 = llvm.getelementptr %247[0, 14] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %269 : i64, !llvm.ptr
    %270 = llvm.getelementptr %247[0, 15] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %270 : i64, !llvm.ptr
    %271 = llvm.udiv %254, %c16_i64 : i64
    %272 = llvm.and %271, %c9007199254740991_i64 : i64
    %273 = llvm.shl %272, %c4_i64 : i64
    llvm.store %273, %255 : i64, !llvm.ptr
    %274 = llvm.sub %250, %c1_i64 : i64
    %275 = llvm.sub %252, %c1_i64 : i64
    %276 = llvm.mul %274, %251 : i64
    %277 = llvm.mul %275, %253 : i64
    %278 = llvm.add %276, %277 : i64
    %279 = llvm.mul %249, %c32_i64 : i64
    %280 = llvm.udiv %279, %c8_i64 : i64
    %281 = llvm.add %280, %278 : i64
    %282 = llvm.add %281, %48 : i64
    %283 = llvm.icmp "uge" %282, %c131072_i64 : i64
    %284 = llvm.zext %283 : i1 to i64
    %285 = llvm.shl %284, %c21_i64 : i64
    %286 = llvm.udiv %251, %c16_i64 : i64
    %287 = llvm.shl %286, %c32_i64 : i64
    %288 = llvm.or %c0_i64, %285 : i64
    %289 = llvm.or %288, %287 : i64
    %290 = llvm.or %1, %289 : i64
    llvm.store %290, %256 : i64, !llvm.ptr
    %291 = llvm.udiv %253, %c16_i64 : i64
    %292 = llvm.and %291, %c4294967295_i64 : i64
    %293 = llvm.shl %292, %c0_i64 : i64
    %294 = llvm.or %293, %65 : i64
    llvm.store %294, %257 : i64, !llvm.ptr
    %295 = llvm.lshr %251, %c36_i64 : i64
    %296 = llvm.and %295, %c15_i64 : i64
    %297 = llvm.shl %296, %c32_i64 : i64
    %298 = llvm.lshr %253, %c36_i64 : i64
    %299 = llvm.and %298, %c15_i64 : i64
    %300 = llvm.shl %299, %c36_i64 : i64
    %301 = llvm.or %297, %300 : i64
    %302 = llvm.or %301, %80 : i64
    %303 = llvm.or %68, %302 : i64
    llvm.store %303, %258 : i64, !llvm.ptr
    %304 = llvm.sub %249, %c1_i64 : i64
    %305 = llvm.and %304, %c4294967295_i64 : i64
    %306 = llvm.shl %305, %c0_i64 : i64
    %307 = llvm.shl %274, %c32_i64 : i64
    %308 = llvm.or %306, %307 : i64
    llvm.store %308, %259 : i64, !llvm.ptr
    %309 = llvm.and %275, %c4294967295_i64 : i64
    %310 = llvm.shl %309, %c0_i64 : i64
    %311 = llvm.or %310, %90 : i64
    llvm.store %311, %260 : i64, !llvm.ptr
    llvm.store %239, %261 : i64, !llvm.ptr
    llvm.store %2, %262 : i64, !llvm.ptr
    %312 = builtin.unrealized_conversion_cast %247 : !llvm.ptr to !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>>
    %313 = cute.ptrtoint(%312) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>> to i64
    %314 = llvm.inttoptr %313 : i64 to !llvm.ptr
    %315 = llvm.load %314 {nontemporal} : !llvm.ptr -> !llvm.struct<(array<16 x i64>)>
    %316 = builtin.unrealized_conversion_cast %315 : !llvm.struct<(array<16 x i64>)> to !cute_nvgpu.tma_descriptor_tiled
    %atom_13 = cute.make_atom() : () -> !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f32, copy_bits = 65536, tma_gbasis = <"(16,128,1):(1@1,1@0,1@2)">, internal_val_type = f32>
    %317 = cute_nvgpu.atom.set_value(%atom_13, %316 : !cute_nvgpu.tma_descriptor_tiled) {field = #cute_nvgpu.atom_copy_field_non_exec_tma_load<tma_desc>} : !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f32, copy_bits = 65536, tma_gbasis = <"(16,128,1):(1@1,1@0,1@2)">, internal_val_type = f32>
    %318 = cute.get_shape(%lay_12) : (!cute.layout<"(?,?,?):(?{i64},1,?{i64})">) -> !cute.shape<"(?,?,?)">
    %lay_14 = cute.make_layout(%318, %7) : !cute.layout<"(?,?,?):(1@1,1@0,1@2)">
    %view_15 = cute.make_view(%6, %lay_14) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">
    %319 = arith.ceildivsi %175#0, %c128_i32 : i32
    %320 = arith.muli %175#3, %c128_i64 : i64
    %321 = arith.ceildivsi %175#1, %c128_i32 : i32
    %shape = cute.make_shape(%319, %321, %175#2) : (i32, i32, i32) -> !cute.shape<"((128,128),(?,?,?))">
    %iv = cute.assume(%320) : (i64) -> !cute.i64<divby 128>
    %stride = cute.make_stride(%175#3, %iv, %175#4) : (i64, !cute.i64<divby 128>, i64) -> !cute.stride<"((?{i64},1),(?{i64 div=128},128,?{i64}))">
    %lay_16 = cute.make_layout(%shape, %stride) : !cute.layout<"((128,128),(?,?,?)):((?{i64},1),(?{i64 div=128},128,?{i64}))">
    %322:6 = cute.get_scalars(%lay_16) <{only_dynamic}> : !cute.layout<"((128,128),(?,?,?)):((?{i64},1),(?{i64 div=128},128,?{i64}))">
    %shape_17 = cute.make_shape(%322#0, %322#1, %322#2) : (i32, i32, i32) -> !cute.shape<"(?,?,?)">
    %iv_18 = cute.assume(%322#4) : (i64) -> !cute.i64<divby 128>
    %stride_19 = cute.make_stride(%iv_18, %322#5) : (!cute.i64<divby 128>, i64) -> !cute.stride<"(?{i64 div=128},128,?{i64})">
    %lay_20 = cute.make_layout(%shape_17, %stride_19) : !cute.layout<"(?,?,?):(?{i64 div=128},128,?{i64})">
    %323 = cute.get_shape(%lay_20) : (!cute.layout<"(?,?,?):(?{i64 div=128},128,?{i64})">) -> !cute.shape<"(?,?,?)">
    %e0, %e1, %e2 = cute.get_leaves(%323) : !cute.shape<"(?,?,?)">
    %itup = cute.to_int_tuple(%e0) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %324 = cute.get_scalars(%itup) : !cute.int_tuple<"?">
    %itup_21 = cute.to_int_tuple(%e1) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %325 = cute.get_scalars(%itup_21) : !cute.int_tuple<"?">
    %itup_22 = cute.to_int_tuple(%e2) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %326 = cute.get_scalars(%itup_22) : !cute.int_tuple<"?">
    %int_tuple = cute.make_int_tuple(%itup, %itup_21, %itup_22) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?,?,?)">
    %327:3 = cute.get_scalars(%int_tuple) <{only_dynamic}> : !cute.int_tuple<"(?,?,?)">
    %int_tuple_23 = cute.make_int_tuple(%327#0, %327#1, %327#2) : (i32, i32, i32) -> !cute.int_tuple<"(?,?,?)">
    %e0_24, %e1_25, %e2_26 = cute.get_leaves(%int_tuple_23) : !cute.int_tuple<"(?,?,?)">
    %shape_27 = cute.make_shape(%e0_24, %e1_25, %e2_26) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.shape<"(?,?,?)">
    %lay_28 = cute.make_layout(%shape_27) : !cute.layout<"(?,?,?):(1,?,?)">
    %328 = cute.get_shape(%lay_28) : (!cute.layout<"(?,?,?):(1,?,?)">) -> !cute.shape<"(?,?,?)">
    %e0_29, %e1_30, %e2_31 = cute.get_leaves(%328) : !cute.shape<"(?,?,?)">
    %itup_32 = cute.to_int_tuple(%e0_29) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %itup_33 = cute.to_int_tuple(%e1_30) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %int_tuple_34 = cute.make_int_tuple(%itup_32) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
    %sz = cute.size(%int_tuple_34) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
    %e0_35 = cute.get_leaves(%sz) : !cute.int_tuple<"?">
    %mul = cute.tuple_mul(%e0_35, %5) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
    %int_tuple_36 = cute.make_int_tuple(%itup_33) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
    %sz_37 = cute.size(%int_tuple_36) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
    %e0_38 = cute.get_leaves(%sz_37) : !cute.int_tuple<"?">
    %mul_39 = cute.tuple_mul(%e0_38, %5) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
    %itup_40 = cute.to_int_tuple(%e2_31) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %int_tuple_41 = cute.make_int_tuple(%mul, %mul_39, %itup_40) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?,?,?)">
    %sz_42 = cute.size(%int_tuple_41) : (!cute.int_tuple<"(?,?,?)">) -> !cute.int_tuple<"?">
    %e0_43 = cute.get_leaves(%sz_42) : !cute.int_tuple<"?">
    %329 = cute.get_scalars(%e0_43) : !cute.int_tuple<"?">
    %330 = arith.minsi %329, %c1_i32 : i32
    %331 = arith.index_cast %330 : i32 to index
    %332 = gpu.launch_func async [%arg6] @kernels::@kernel_cutlass_kernel___main__SM100PersistentDenseGemmAlphaBetaKernel_object_at__TiledMMA_ThrLayoutVMNK11110000_PermutationMNK____MMAAtom_ThrID10_ShapeMNK1281288_TVLayoutA112881281128_TVL_0 clusters in (%c1, %c1, %c1) blocks in (%c1, %c1, %331) threads in (%c224, %c1, %c1)  dynamic_shared_memory_size %c230400_i32 args(%13 : !mma_tf32_tf32_f32_128x128x8_, %100 : !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, tf32, copy_bits = 131072, tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">, internal_val_type = tf32>, %view : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">, %172 : !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, tf32, copy_bits = 131072, tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">, internal_val_type = tf32>, %view_5 : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">, %317 : !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f32, copy_bits = 65536, tma_gbasis = <"(16,128,1):(1@1,1@0,1@2)">, internal_val_type = f32>, %view_15 : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">, %245 : !cute_nvgpu.atom.non_exec_tiled_tma_store<f32, copy_bits = 65536, tma_gbasis = <"(16,128,1):(1@1,1@0,1@2)">, internal_val_type = f32>, %view_10 : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">, %324 : i32, %325 : i32, %326 : i32, %arg4 : f32, %arg5 : f32) {use_pdl = false}
    return
  }
}
