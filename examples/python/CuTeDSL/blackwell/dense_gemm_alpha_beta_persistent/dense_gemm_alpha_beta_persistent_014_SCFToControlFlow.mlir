!copy_simt = !cute.tiled_copy<!cute_nvgpu.atom.universal_copy<f32>, layout_copy_tv = <"((32,4),(16,1)):((4,1),(128,0))">, tiler_mn = <"[(4,32):(32,1);16:1]">>
!memref_gmem_f32_ = !cute.memref<f32, gmem, align<16>, "(?,?,?):(?{i64},1,?{i64})">
!memref_gmem_tf32_ = !cute.memref<tf32, gmem, align<16>, "(?,?,?):(?{i64},1,?{i64})">
!memref_rmem_f32_ = !cute.memref<f32, rmem, align<32>, "((16,1),1,1):((1,0),0,0)">
!memref_rmem_f32_1 = !cute.memref<f32, rmem, align<32>, "((1,16),1,1):((0,1),0,0)">
!mma_tf32_tf32_f32_128x128x8_ = !cute.tiled_mma<!cute_nvgpu.sm100.mma<128x128x8, num_cta = 1, ab_major = (k, k), elem_type = (tf32, tf32, f32), frag_kind = ss, c_scale_exp = 0>, atom_layout_MNK = <"(1,1,1):(0,0,0)">>
#loop_unroll = #llvm.loop_unroll<disable = true, count = 1 : i32>
#loop_unroll1 = #llvm.loop_unroll<disable = false, full = true>
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
      cf.cond_br %50, ^bb1, ^bb2
    ^bb1:  // pred: ^bb0
      cute_nvgpu.prefetch_tma_desc(%arg1) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, tf32, copy_bits = 131072, tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">, internal_val_type = tf32>) -> ()
      cute_nvgpu.prefetch_tma_desc(%arg3) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, tf32, copy_bits = 131072, tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">, internal_val_type = tf32>) -> ()
      cute_nvgpu.prefetch_tma_desc(%arg5) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f32, copy_bits = 65536, tma_gbasis = <"(16,128,1):(1@1,1@0,1@2)">, internal_val_type = f32>) -> ()
      cute_nvgpu.prefetch_tma_desc(%arg7) : (!cute_nvgpu.atom.non_exec_tiled_tma_store<f32, copy_bits = 65536, tma_gbasis = <"(16,128,1):(1@1,1@0,1@2)">, internal_val_type = f32>) -> ()
      cf.br ^bb2
    ^bb2:  // 2 preds: ^bb0, ^bb1
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
      cf.cond_br %51, ^bb3, ^bb4
    ^bb3:  // pred: ^bb2
      %52 = builtin.unrealized_conversion_cast %iter_7 : !cute.ptr<i64, smem, align<1024>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %52, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_8 = cute.add_offset(%iter_7, %29) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"1">) -> !cute.ptr<i64, smem>
      %53 = builtin.unrealized_conversion_cast %ptr_8 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %53, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_9 = cute.add_offset(%iter_7, %28) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"2">) -> !cute.ptr<i64, smem, align<16>>
      %54 = builtin.unrealized_conversion_cast %ptr_9 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %54, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_10 = cute.add_offset(%iter_7, %27) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"3">) -> !cute.ptr<i64, smem>
      %55 = builtin.unrealized_conversion_cast %ptr_10 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %55, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_11 = cute.add_offset(%iter_7, %26) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"4">) -> !cute.ptr<i64, smem, align<32>>
      %56 = builtin.unrealized_conversion_cast %ptr_11 : !cute.ptr<i64, smem, align<32>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %56, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_12 = cute.add_offset(%iter_7, %25) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"5">) -> !cute.ptr<i64, smem>
      %57 = builtin.unrealized_conversion_cast %ptr_12 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %57, %c1_i32 : !llvm.ptr<3>, i32
      cf.br ^bb4
    ^bb4:  // 2 preds: ^bb2, ^bb3
      %ptr_13 = cute.add_offset(%iter_7, %24) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"6">) -> !cute.ptr<i64, smem, align<16>>
      cf.cond_br %51, ^bb5, ^bb6
    ^bb5:  // pred: ^bb4
      %58 = builtin.unrealized_conversion_cast %ptr_13 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %58, %c1_i32 : !llvm.ptr<3>, i32
      %int_tuple_14 = cute.make_int_tuple() : () -> !cute.int_tuple<"7">
      %ptr_15 = cute.add_offset(%iter_7, %int_tuple_14) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"7">) -> !cute.ptr<i64, smem>
      %59 = builtin.unrealized_conversion_cast %ptr_15 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %59, %c1_i32 : !llvm.ptr<3>, i32
      %int_tuple_16 = cute.make_int_tuple() : () -> !cute.int_tuple<"8">
      %ptr_17 = cute.add_offset(%iter_7, %int_tuple_16) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"8">) -> !cute.ptr<i64, smem, align<64>>
      %dyn = cute.derefine(%ptr_17) : !cute.ptr<i64, smem, align<64>> to !cute.ptr<i64, smem, align<16>>
      %60 = builtin.unrealized_conversion_cast %dyn : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %60, %c1_i32 : !llvm.ptr<3>, i32
      %int_tuple_18 = cute.make_int_tuple() : () -> !cute.int_tuple<"9">
      %ptr_19 = cute.add_offset(%iter_7, %int_tuple_18) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"9">) -> !cute.ptr<i64, smem>
      %61 = builtin.unrealized_conversion_cast %ptr_19 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %61, %c1_i32 : !llvm.ptr<3>, i32
      %int_tuple_20 = cute.make_int_tuple() : () -> !cute.int_tuple<"10">
      %ptr_21 = cute.add_offset(%iter_7, %int_tuple_20) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"10">) -> !cute.ptr<i64, smem, align<16>>
      %62 = builtin.unrealized_conversion_cast %ptr_21 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %62, %c1_i32 : !llvm.ptr<3>, i32
      %int_tuple_22 = cute.make_int_tuple() : () -> !cute.int_tuple<"11">
      %ptr_23 = cute.add_offset(%iter_7, %int_tuple_22) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"11">) -> !cute.ptr<i64, smem>
      %63 = builtin.unrealized_conversion_cast %ptr_23 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %63, %c1_i32 : !llvm.ptr<3>, i32
      cf.br ^bb6
    ^bb6:  // 2 preds: ^bb4, ^bb5
      nvvm.fence.mbarrier.init
      nvvm.barrier
      %iter_24 = cute.recast_iter(%ptr) : !cute.ptr<i8, smem, align<32>> to !cute.ptr<i64, smem, align<32>>
      cf.cond_br %51, ^bb7, ^bb8
    ^bb7:  // pred: ^bb6
      %64 = builtin.unrealized_conversion_cast %iter_24 : !cute.ptr<i64, smem, align<32>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %64, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_25 = cute.add_offset(%iter_24, %29) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i64, smem>
      %65 = builtin.unrealized_conversion_cast %ptr_25 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %65, %c1_i32 : !llvm.ptr<3>, i32
      cf.br ^bb8
    ^bb8:  // 2 preds: ^bb6, ^bb7
      %ptr_26 = cute.add_offset(%iter_24, %28) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i64, smem, align<16>>
      cf.cond_br %51, ^bb9, ^bb10
    ^bb9:  // pred: ^bb8
      %66 = builtin.unrealized_conversion_cast %ptr_26 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %66, %c4_i32 : !llvm.ptr<3>, i32
      %int_tuple_27 = cute.make_int_tuple() : () -> !cute.int_tuple<"3">
      %ptr_28 = cute.add_offset(%iter_24, %int_tuple_27) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i64, smem>
      %67 = builtin.unrealized_conversion_cast %ptr_28 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %67, %c4_i32 : !llvm.ptr<3>, i32
      cf.br ^bb10
    ^bb10:  // 2 preds: ^bb8, ^bb9
      nvvm.fence.mbarrier.init
      nvvm.barrier
      %iter_29 = cute.recast_iter(%ptr_1) : !cute.ptr<i8, smem, align<128>> to !cute.ptr<i64, smem, align<128>>
      cf.cond_br %51, ^bb11, ^bb12
    ^bb11:  // pred: ^bb10
      %68 = builtin.unrealized_conversion_cast %iter_29 : !cute.ptr<i64, smem, align<128>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %68, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_30 = cute.add_offset(%iter_29, %29) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"1">) -> !cute.ptr<i64, smem>
      %69 = builtin.unrealized_conversion_cast %ptr_30 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %69, %c1_i32 : !llvm.ptr<3>, i32
      cf.br ^bb12
    ^bb12:  // 2 preds: ^bb10, ^bb11
      %ptr_31 = cute.add_offset(%iter_29, %28) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"2">) -> !cute.ptr<i64, smem, align<16>>
      cf.cond_br %51, ^bb13, ^bb14
    ^bb13:  // pred: ^bb12
      %70 = builtin.unrealized_conversion_cast %ptr_31 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %70, %c4_i32 : !llvm.ptr<3>, i32
      %int_tuple_32 = cute.make_int_tuple() : () -> !cute.int_tuple<"3">
      %ptr_33 = cute.add_offset(%iter_29, %int_tuple_32) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"3">) -> !cute.ptr<i64, smem>
      %71 = builtin.unrealized_conversion_cast %ptr_33 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %71, %c4_i32 : !llvm.ptr<3>, i32
      cf.br ^bb14
    ^bb14:  // 2 preds: ^bb12, ^bb13
      %72 = arith.remsi %38, %c32_i32 : i32
      %73 = arith.cmpi slt, %72, %c1_i32 : i32
      %74 = arith.extui %73 : i1 to i32
      %75 = arith.select %73, %c1_i32, %74 : i32
      %76 = arith.cmpi ne, %75, %c0_i32 : i32
      nvvm.fence.mbarrier.init
      nvvm.barrier
      %iter_34 = cute.recast_iter(%ptr_4) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<f32, smem, align<1024>, S<2,4,3>>
      %iter_35 = cute.recast_iter(%ptr_3) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<f32, smem, align<1024>, S<2,4,3>>
      %iter_36 = cute.recast_iter(%ptr_5) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<tf32, smem, align<1024>, S<3,4,3>>
      %iter_37 = cute.recast_iter(%ptr_6) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<tf32, smem, align<1024>, S<3,4,3>>
      %lay_38 = cute.get_layout(%arg2) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">
      %77:3 = cute.get_scalars(%lay_38) <{only_dynamic}> : !cute.layout<"(?,?,?):(1@1,1@0,1@2)">
      %78 = arith.ceildivsi %77#0, %c128_i32 : i32
      %79 = arith.ceildivsi %77#1, %c32_i32 : i32
      %shape_39 = cute.make_shape(%78, %79, %77#2) : (i32, i32, i32) -> !cute.shape<"((128,32),(?,?,?))">
      %lay_40 = cute.make_layout(%shape_39, %23) : !cute.layout<"((128,32),(?,?,?)):((1@1,1@0),(128@1,32@0,1@2))">
      %80:3 = cute.get_scalars(%lay_40) <{only_dynamic}> : !cute.layout<"((128,32),(?,?,?)):((1@1,1@0),(128@1,32@0,1@2))">
      %shape_41 = cute.make_shape(%80#0, %80#1, %80#2) : (i32, i32, i32) -> !cute.shape<"(128,32,?,?,?)">
      %lay_42 = cute.make_layout(%shape_41, %22) : !cute.layout<"(128,32,?,?,?):(1@1,1@0,128@1,32@0,1@2)">
      %lay_43 = cute.get_layout(%arg4) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">
      %81:3 = cute.get_scalars(%lay_43) <{only_dynamic}> : !cute.layout<"(?,?,?):(1@1,1@0,1@2)">
      %82 = arith.ceildivsi %81#0, %c128_i32 : i32
      %83 = arith.ceildivsi %81#1, %c32_i32 : i32
      %shape_44 = cute.make_shape(%82, %83, %81#2) : (i32, i32, i32) -> !cute.shape<"((128,32),(?,?,?))">
      %lay_45 = cute.make_layout(%shape_44, %23) : !cute.layout<"((128,32),(?,?,?)):((1@1,1@0),(128@1,32@0,1@2))">
      %84:3 = cute.get_scalars(%lay_45) <{only_dynamic}> : !cute.layout<"((128,32),(?,?,?)):((1@1,1@0),(128@1,32@0,1@2))">
      %shape_46 = cute.make_shape(%84#0, %84#1, %84#2) : (i32, i32, i32) -> !cute.shape<"(128,32,?,?,?)">
      %lay_47 = cute.make_layout(%shape_46, %22) : !cute.layout<"(128,32,?,?,?):(1@1,1@0,128@1,32@0,1@2)">
      %lay_48 = cute.get_layout(%arg6) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">
      %85:3 = cute.get_scalars(%lay_48) <{only_dynamic}> : !cute.layout<"(?,?,?):(1@1,1@0,1@2)">
      %86 = arith.ceildivsi %85#0, %c128_i32 : i32
      %87 = arith.ceildivsi %85#1, %c128_i32 : i32
      %shape_49 = cute.make_shape(%86, %87, %85#2) : (i32, i32, i32) -> !cute.shape<"((128,128),(?,?,?))">
      %lay_50 = cute.make_layout(%shape_49, %20) : !cute.layout<"((128,128),(?,?,?)):((1@1,1@0),(128@1,128@0,1@2))">
      %88:3 = cute.get_scalars(%lay_50) <{only_dynamic}> : !cute.layout<"((128,128),(?,?,?)):((1@1,1@0),(128@1,128@0,1@2))">
      %shape_51 = cute.make_shape(%88#0, %88#1, %88#2) : (i32, i32, i32) -> !cute.shape<"(128,128,?,?,?)">
      %lay_52 = cute.make_layout(%shape_51, %19) : !cute.layout<"(128,128,?,?,?):(1@1,1@0,128@1,128@0,1@2)">
      %lay_53 = cute.get_layout(%arg8) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">
      %89:3 = cute.get_scalars(%lay_53) <{only_dynamic}> : !cute.layout<"(?,?,?):(1@1,1@0,1@2)">
      %90 = arith.ceildivsi %89#0, %c128_i32 : i32
      %91 = arith.ceildivsi %89#1, %c128_i32 : i32
      %shape_54 = cute.make_shape(%90, %91, %89#2) : (i32, i32, i32) -> !cute.shape<"((128,128),(?,?,?))">
      %lay_55 = cute.make_layout(%shape_54, %20) : !cute.layout<"((128,128),(?,?,?)):((1@1,1@0),(128@1,128@0,1@2))">
      %92:3 = cute.get_scalars(%lay_55) <{only_dynamic}> : !cute.layout<"((128,128),(?,?,?)):((1@1,1@0),(128@1,128@0,1@2))">
      %shape_56 = cute.make_shape(%92#0, %92#1, %92#2) : (i32, i32, i32) -> !cute.shape<"(128,128,?,?,?)">
      %lay_57 = cute.make_layout(%shape_56, %19) : !cute.layout<"(128,128,?,?,?):(1@1,1@0,128@1,128@0,1@2)">
      %sz = cute.size(%lay_42) <{mode = [3]}> : (!cute.layout<"(128,32,?,?,?):(1@1,1@0,128@1,32@0,1@2)">) -> !cute.int_tuple<"?">
      %e0_58 = cute.get_leaves(%sz) : !cute.int_tuple<"?">
      %93 = cute.get_scalars(%e0_58) : !cute.int_tuple<"?">
      %94:3 = cute.get_scalars(%lay_42) <{only_dynamic}> : !cute.layout<"(128,32,?,?,?):(1@1,1@0,128@1,32@0,1@2)">
      %shape_59 = cute.make_shape(%94#0, %94#1, %94#2) : (i32, i32, i32) -> !cute.shape<"((128,8),1,4,?,?,?)">
      %lay_60 = cute.make_layout(%shape_59, %18) : !cute.layout<"((128,8),1,4,?,?,?):((1@1,1@0),0,8@0,128@1,32@0,1@2)">
      %95:3 = cute.get_scalars(%lay_47) <{only_dynamic}> : !cute.layout<"(128,32,?,?,?):(1@1,1@0,128@1,32@0,1@2)">
      %shape_61 = cute.make_shape(%95#0, %95#1, %95#2) : (i32, i32, i32) -> !cute.shape<"((128,8),1,4,?,?,?)">
      %lay_62 = cute.make_layout(%shape_61, %18) : !cute.layout<"((128,8),1,4,?,?,?):((1@1,1@0),0,8@0,128@1,32@0,1@2)">
      %96:3 = cute.get_scalars(%lay_52) <{only_dynamic}> : !cute.layout<"(128,128,?,?,?):(1@1,1@0,128@1,128@0,1@2)">
      %shape_63 = cute.make_shape(%96#0, %96#1, %96#2) : (i32, i32, i32) -> !cute.shape<"((128,128),1,1,?,?,?)">
      %lay_64 = cute.make_layout(%shape_63, %17) : !cute.layout<"((128,128),1,1,?,?,?):((1@1,1@0),0,0,128@1,128@0,1@2)">
      %97:3 = cute.get_scalars(%lay_57) <{only_dynamic}> : !cute.layout<"(128,128,?,?,?):(1@1,1@0,128@1,128@0,1@2)">
      %shape_65 = cute.make_shape(%97#0, %97#1, %97#2) : (i32, i32, i32) -> !cute.shape<"((128,128),1,1,?,?,?)">
      %lay_66 = cute.make_layout(%shape_65, %17) : !cute.layout<"((128,128),1,1,?,?,?):((1@1,1@0),0,0,128@1,128@0,1@2)">
      %98:3 = cute.get_scalars(%lay_60) <{only_dynamic}> : !cute.layout<"((128,8),1,4,?,?,?):((1@1,1@0),0,8@0,128@1,32@0,1@2)">
      %shape_67 = cute.make_shape(%98#0, %98#1, %98#2) : (i32, i32, i32) -> !cute.shape<"(((128,8),1,4),?,?,?)">
      %lay_68 = cute.make_layout(%shape_67, %16) : !cute.layout<"(((128,8),1,4),?,?,?):(((1@1,1@0),0,8@0),128@1,32@0,1@2)">
      %99:3 = cute.get_scalars(%lay_68) <{only_dynamic}> : !cute.layout<"(((128,8),1,4),?,?,?):(((1@1,1@0),0,8@0),128@1,32@0,1@2)">
      %shape_69 = cute.make_shape(%99#0, %99#1, %99#2) : (i32, i32, i32) -> !cute.shape<"(((32,128),1),?,?,?)">
      %lay_70 = cute.make_layout(%shape_69, %15) : !cute.layout<"(((32,128),1),?,?,?):(((1@0,1@1),0),128@1,32@0,1@2)">
      %100:3 = cute.get_scalars(%lay_62) <{only_dynamic}> : !cute.layout<"((128,8),1,4,?,?,?):((1@1,1@0),0,8@0,128@1,32@0,1@2)">
      %shape_71 = cute.make_shape(%100#0, %100#1, %100#2) : (i32, i32, i32) -> !cute.shape<"(((128,8),1,4),?,?,?)">
      %lay_72 = cute.make_layout(%shape_71, %16) : !cute.layout<"(((128,8),1,4),?,?,?):(((1@1,1@0),0,8@0),128@1,32@0,1@2)">
      %101:3 = cute.get_scalars(%lay_72) <{only_dynamic}> : !cute.layout<"(((128,8),1,4),?,?,?):(((1@1,1@0),0,8@0),128@1,32@0,1@2)">
      %shape_73 = cute.make_shape(%101#0, %101#1, %101#2) : (i32, i32, i32) -> !cute.shape<"(((32,128),1),?,?,?)">
      %lay_74 = cute.make_layout(%shape_73, %15) : !cute.layout<"(((32,128),1),?,?,?):(((1@0,1@1),0),128@1,32@0,1@2)">
      %ummaSmemDesc = cute_nvgpu.make_umma_smem_desc(%iter_36 : !cute.ptr<tf32, smem, align<1024>, S<3,4,3>>) layout = <"((128,8),1,4,6):((32,1),0,8,4096)">, major = <k> -> !cute_nvgpu.smem_desc
      %ummaSmemDesc_75 = cute_nvgpu.make_umma_smem_desc(%iter_37 : !cute.ptr<tf32, smem, align<1024>, S<3,4,3>>) layout = <"((128,8),1,4,6):((32,1),0,8,4096)">, major = <k> -> !cute_nvgpu.smem_desc
      nvvm.barrier id = %c1_i32 number_of_threads = %c224_i32
      cf.cond_br %50, ^bb15, ^bb66
    ^bb15:  // pred: ^bb14
      %102 = nvvm.read.ptx.sreg.ctaid.z range <i32, 0, 65535> : i32
      %103 = nvvm.read.ptx.sreg.nctaid.x range <i32, 1, 2147483647> : i32
      %104 = nvvm.read.ptx.sreg.nctaid.y range <i32, 1, 65535> : i32
      %105 = nvvm.read.ptx.sreg.nctaid.z range <i32, 1, 65535> : i32
      %int_tuple_76 = cute.make_int_tuple(%103, %104, %105) : (i32, i32, i32) -> !cute.int_tuple<"(?,?,?)">
      %sz_77 = cute.size(%int_tuple_76) : (!cute.int_tuple<"(?,?,?)">) -> !cute.int_tuple<"?">
      %e0_78 = cute.get_leaves(%sz_77) : !cute.int_tuple<"?">
      %div = cute.tuple_div(%e0_78, %29) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %106 = cute.get_scalars(%div) : !cute.int_tuple<"?">
      %sz_79 = cute.size(%lay) : (!cute.layout<"(?,?,?):(1,?,?)">) -> !cute.int_tuple<"?">
      %e0_80 = cute.get_leaves(%sz_79) : !cute.int_tuple<"?">
      %107 = cute.get_scalars(%e0_80) : !cute.int_tuple<"?">
      %108 = arith.cmpi sgt, %107, %102 : i32
      %109 = cute.get_hier_coord(%102, %lay) : (i32, !cute.layout<"(?,?,?):(1,?,?)">) -> !cute.coord<"(?,?,?)">
      %e0_81, %e1_82, %e2_83 = cute.get_leaves(%109) : !cute.coord<"(?,?,?)">
      %itup = cute.to_int_tuple(%e0_81) : !cute.coord<"?"> to !cute.int_tuple<"?">
      %itup_84 = cute.to_int_tuple(%e1_82) : !cute.coord<"?"> to !cute.int_tuple<"?">
      %itup_85 = cute.to_int_tuple(%e2_83) : !cute.coord<"?"> to !cute.int_tuple<"?">
      %mul = cute.tuple_mul(%itup, %29) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %110 = cute.get_scalars(%mul) : !cute.int_tuple<"?">
      %mul_86 = cute.tuple_mul(%itup_84, %29) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %111 = cute.get_scalars(%mul_86) : !cute.int_tuple<"?">
      %mul_87 = cute.tuple_mul(%itup_85, %29) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %112 = cute.get_scalars(%mul_87) : !cute.int_tuple<"?">
      %113:3 = cute.get_scalars(%lay_70) <{only_dynamic}> : !cute.layout<"(((32,128),1),?,?,?):(((1@0,1@1),0),128@1,32@0,1@2)">
      %shape_88 = cute.make_shape(%113#1) : (i32) -> !cute.shape<"(((32,128),1),?)">
      %lay_89 = cute.make_layout(%shape_88, %14) : !cute.layout<"(((32,128),1),?):(((1@0,1@1),0),32@0)">
      %114:3 = cute.get_scalars(%lay_74) <{only_dynamic}> : !cute.layout<"(((32,128),1),?,?,?):(((1@0,1@1),0),128@1,32@0,1@2)">
      %shape_90 = cute.make_shape(%114#1) : (i32) -> !cute.shape<"(((32,128),1),?)">
      %lay_91 = cute.make_layout(%shape_90, %14) : !cute.layout<"(((32,128),1),?):(((1@0,1@1),0),32@0)">
      %115 = arith.cmpi sgt, %93, %c0_i32 : i32
      %116 = cute_nvgpu.atom.make_exec_tma(%arg1) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, tf32, copy_bits = 131072, tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">, internal_val_type = tf32>) -> !cute_nvgpu.atom.tma_load<tf32, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">>
      %117 = cute.get_scalars(%29) : !cute.int_tuple<"1">
      %118 = cute_nvgpu.atom.make_exec_tma(%arg3) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, tf32, copy_bits = 131072, tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">, internal_val_type = tf32>) -> !cute_nvgpu.atom.tma_load<tf32, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">>
      cf.br ^bb16(%110, %111, %112, %108, %c0_i32, %c1_i32, %102, %c0_i32 : i32, i32, i32, i1, i32, i32, i32, i32)
    ^bb16(%119: i32, %120: i32, %121: i32, %122: i1, %123: i32, %124: i32, %125: i32, %126: i32):  // 2 preds: ^bb15, ^bb42
      cf.cond_br %122, ^bb17(%119, %120, %121, %123, %124, %125, %126 : i32, i32, i32, i32, i32, i32, i32), ^bb43
    ^bb17(%127: i32, %128: i32, %129: i32, %130: i32, %131: i32, %132: i32, %133: i32):  // pred: ^bb16
      %coord = cute.make_coord(%127, %129) : (i32, i32) -> !cute.coord<"(_,?,_,?)">
      %idx = cute.crd2idx(%coord, %lay_70) : (!cute.coord<"(_,?,_,?)">, !cute.layout<"(((32,128),1),?,?,?):(((1@0,1@1),0),128@1,32@0,1@2)">) -> !cute.int_tuple<"(0,?{div=128},?)">
      %tup = cute.add_offset(%21, %idx) : (!cute.int_tuple<"(0,0,0)">, !cute.int_tuple<"(0,?{div=128},?)">) -> !cute.int_tuple<"(0,?{div=128},?)">
      %coord_92 = cute.make_coord(%128, %129) : (i32, i32) -> !cute.coord<"(_,?,_,?)">
      %idx_93 = cute.crd2idx(%coord_92, %lay_74) : (!cute.coord<"(_,?,_,?)">, !cute.layout<"(((32,128),1),?,?,?):(((1@0,1@1),0),128@1,32@0,1@2)">) -> !cute.int_tuple<"(0,?{div=128},?)">
      %tup_94 = cute.add_offset(%21, %idx_93) : (!cute.int_tuple<"(0,0,0)">, !cute.int_tuple<"(0,?{div=128},?)">) -> !cute.int_tuple<"(0,?{div=128},?)">
      cf.cond_br %115, ^bb18, ^bb19
    ^bb18:  // pred: ^bb17
      %int_tuple_95 = cute.make_int_tuple(%130) : (i32) -> !cute.int_tuple<"?">
      %ptr_96 = cute.add_offset(%ptr_13, %int_tuple_95) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %134 = builtin.unrealized_conversion_cast %ptr_96 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      %135 = nvvm.mbarrier.wait.parity %134, %131 {kind = #nvvm.mbar_wait<try>} : !llvm.ptr<3>, i32 -> i1
      cf.br ^bb20(%135 : i1)
    ^bb19:  // pred: ^bb17
      cf.br ^bb20(%true : i1)
    ^bb20(%136: i1):  // 2 preds: ^bb18, ^bb19
      cf.br ^bb21
    ^bb21:  // pred: ^bb20
      cf.br ^bb22(%c0_i32, %136, %c0_i32, %130, %131 : i32, i1, i32, i32, i32)
    ^bb22(%137: i32, %138: i1, %139: i32, %140: i32, %141: i32):  // 2 preds: ^bb21, ^bb41
      %142 = arith.cmpi slt, %137, %93 : i32
      cf.cond_br %142, ^bb23, ^bb42 {loop_annotation = #loop_annotation}
    ^bb23:  // pred: ^bb22
      %143 = arith.extui %138 : i1 to i32
      %144 = arith.cmpi eq, %143, %c0_i32 : i32
      cf.cond_br %144, ^bb24, ^bb25
    ^bb24:  // pred: ^bb23
      %int_tuple_97 = cute.make_int_tuple(%140) : (i32) -> !cute.int_tuple<"?">
      %ptr_98 = cute.add_offset(%ptr_13, %int_tuple_97) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %145 = builtin.unrealized_conversion_cast %ptr_98 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %145, %141, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      cf.br ^bb25
    ^bb25:  // 2 preds: ^bb23, ^bb24
      %146 = nvvm.elect.sync -> i1
      cf.cond_br %146, ^bb26, ^bb27
    ^bb26:  // pred: ^bb25
      %int_tuple_99 = cute.make_int_tuple(%140) : (i32) -> !cute.int_tuple<"?">
      %ptr_100 = cute.add_offset(%iter_7, %int_tuple_99) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %147 = builtin.unrealized_conversion_cast %ptr_100 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %147, %c32768_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
      cf.br ^bb27
    ^bb27:  // 2 preds: ^bb25, ^bb26
      %coord_101 = cute.make_coord(%139) : (i32) -> !cute.coord<"(_,?)">
      %idx_102 = cute.crd2idx(%coord_101, %lay_89) : (!cute.coord<"(_,?)">, !cute.layout<"(((32,128),1),?):(((1@0,1@1),0),32@0)">) -> !cute.int_tuple<"(?{div=32},0)">
      %tup_103 = cute.add_offset(%tup, %idx_102) : (!cute.int_tuple<"(0,?{div=128},?)">, !cute.int_tuple<"(?{div=32},0)">) -> !cute.int_tuple<"(?{div=32},?{div=128},?)">
      %e0_104, %e1_105, %e2_106 = cute.get_leaves(%tup_103) : !cute.int_tuple<"(?{div=32},?{div=128},?)">
      %coord_107 = cute.make_coord(%140) : (i32) -> !cute.coord<"(_,?)">
      %idx_108 = cute.crd2idx(%coord_107, %13) : (!cute.coord<"(_,?)">, !cute.layout<"((4096,1),6):((1,0),4096)">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_109 = cute.add_offset(%iter_36, %idx_108) : (!cute.ptr<tf32, smem, align<1024>, S<3,4,3>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<tf32, smem, align<1024>, S<3,4,3>>
      %int_tuple_110 = cute.make_int_tuple(%140) : (i32) -> !cute.int_tuple<"?">
      %ptr_111 = cute.add_offset(%iter_7, %int_tuple_110) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %int_tuple_112 = cute.make_int_tuple(%e0_104, %e1_105, %e2_106) : (!cute.int_tuple<"?{div=32}">, !cute.int_tuple<"?{div=128}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=32},?{div=128},?)">
      %148 = cute_nvgpu.atom.set_value(%116, %ptr_111 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<tf32, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">>
      %149 = cute_nvgpu.atom.get_value(%148 : !cute_nvgpu.atom.tma_load<tf32, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
      %TMADescAddr = cute_nvgpu.get_tma_desc_addr(%148 : !cute_nvgpu.atom.tma_load<tf32, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">>) -> !cute.ptr<generic, align<64>>
      %150:3 = cute.get_scalars(%int_tuple_112) : !cute.int_tuple<"(?{div=32},?{div=128},?)">
      cf.br ^bb28(%c0_i32 : i32)
    ^bb28(%151: i32):  // 2 preds: ^bb27, ^bb29
      %152 = arith.cmpi slt, %151, %117 : i32
      cf.cond_br %152, ^bb29, ^bb30 {llvm.loop_annotation = #loop_annotation1}
    ^bb29:  // pred: ^bb28
      cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr : !cute.ptr<generic, align<64>>, %ptr_109 : !cute.ptr<tf32, smem, align<1024>, S<3,4,3>>, %149 : !cute.ptr<smem, align<8>>, [%150#0, %150#1, %150#2] : i32, i32, i32) mode = <tiled> num_cta = 1 : i32
      %153 = arith.addi %151, %c1_i32 : i32
      cf.br ^bb28(%153 : i32)
    ^bb30:  // pred: ^bb28
      %idx_113 = cute.crd2idx(%coord_101, %lay_91) : (!cute.coord<"(_,?)">, !cute.layout<"(((32,128),1),?):(((1@0,1@1),0),32@0)">) -> !cute.int_tuple<"(?{div=32},0)">
      %tup_114 = cute.add_offset(%tup_94, %idx_113) : (!cute.int_tuple<"(0,?{div=128},?)">, !cute.int_tuple<"(?{div=32},0)">) -> !cute.int_tuple<"(?{div=32},?{div=128},?)">
      %e0_115, %e1_116, %e2_117 = cute.get_leaves(%tup_114) : !cute.int_tuple<"(?{div=32},?{div=128},?)">
      %ptr_118 = cute.add_offset(%iter_37, %idx_108) : (!cute.ptr<tf32, smem, align<1024>, S<3,4,3>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<tf32, smem, align<1024>, S<3,4,3>>
      %int_tuple_119 = cute.make_int_tuple(%e0_115, %e1_116, %e2_117) : (!cute.int_tuple<"?{div=32}">, !cute.int_tuple<"?{div=128}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=32},?{div=128},?)">
      %154 = cute_nvgpu.atom.set_value(%118, %ptr_111 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<tf32, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">>
      %155 = cute_nvgpu.atom.get_value(%154 : !cute_nvgpu.atom.tma_load<tf32, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
      %TMADescAddr_120 = cute_nvgpu.get_tma_desc_addr(%154 : !cute_nvgpu.atom.tma_load<tf32, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">>) -> !cute.ptr<generic, align<64>>
      %156:3 = cute.get_scalars(%int_tuple_119) : !cute.int_tuple<"(?{div=32},?{div=128},?)">
      cf.br ^bb31(%c0_i32 : i32)
    ^bb31(%157: i32):  // 2 preds: ^bb30, ^bb32
      %158 = arith.cmpi slt, %157, %117 : i32
      cf.cond_br %158, ^bb32, ^bb33 {llvm.loop_annotation = #loop_annotation1}
    ^bb32:  // pred: ^bb31
      cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr_120 : !cute.ptr<generic, align<64>>, %ptr_118 : !cute.ptr<tf32, smem, align<1024>, S<3,4,3>>, %155 : !cute.ptr<smem, align<8>>, [%156#0, %156#1, %156#2] : i32, i32, i32) mode = <tiled> num_cta = 1 : i32
      %159 = arith.addi %157, %c1_i32 : i32
      cf.br ^bb31(%159 : i32)
    ^bb33:  // pred: ^bb31
      %160 = arith.addi %140, %c1_i32 : i32
      %161 = arith.addi %139, %c1_i32 : i32
      %162 = arith.cmpi eq, %160, %c6_i32 : i32
      %163 = arith.select %162, %c0_i32, %160 : i32
      cf.cond_br %162, ^bb34, ^bb35
    ^bb34:  // pred: ^bb33
      %164 = arith.xori %141, %c1_i32 : i32
      cf.br ^bb36(%164 : i32)
    ^bb35:  // pred: ^bb33
      cf.br ^bb36(%141 : i32)
    ^bb36(%165: i32):  // 2 preds: ^bb34, ^bb35
      cf.br ^bb37
    ^bb37:  // pred: ^bb36
      %166 = arith.cmpi sgt, %93, %161 : i32
      cf.cond_br %166, ^bb38, ^bb39
    ^bb38:  // pred: ^bb37
      %int_tuple_121 = cute.make_int_tuple(%163) : (i32) -> !cute.int_tuple<"?">
      %ptr_122 = cute.add_offset(%ptr_13, %int_tuple_121) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %167 = builtin.unrealized_conversion_cast %ptr_122 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      %168 = nvvm.mbarrier.wait.parity %167, %165 {kind = #nvvm.mbar_wait<try>} : !llvm.ptr<3>, i32 -> i1
      cf.br ^bb40(%168 : i1)
    ^bb39:  // pred: ^bb37
      cf.br ^bb40(%true : i1)
    ^bb40(%169: i1):  // 2 preds: ^bb38, ^bb39
      cf.br ^bb41
    ^bb41:  // pred: ^bb40
      %170 = arith.addi %137, %c1_i32 : i32
      cf.br ^bb22(%170, %169, %161, %163, %165 : i32, i1, i32, i32, i32)
    ^bb42:  // pred: ^bb22
      %171 = arith.addi %132, %106 : i32
      %172 = arith.addi %133, %c1_i32 : i32
      %173 = arith.cmpi sgt, %107, %171 : i32
      %174 = cute.get_hier_coord(%171, %lay) : (i32, !cute.layout<"(?,?,?):(1,?,?)">) -> !cute.coord<"(?,?,?)">
      %e0_123, %e1_124, %e2_125 = cute.get_leaves(%174) : !cute.coord<"(?,?,?)">
      %itup_126 = cute.to_int_tuple(%e0_123) : !cute.coord<"?"> to !cute.int_tuple<"?">
      %itup_127 = cute.to_int_tuple(%e1_124) : !cute.coord<"?"> to !cute.int_tuple<"?">
      %itup_128 = cute.to_int_tuple(%e2_125) : !cute.coord<"?"> to !cute.int_tuple<"?">
      %mul_129 = cute.tuple_mul(%itup_126, %29) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %175 = cute.get_scalars(%mul_129) : !cute.int_tuple<"?">
      %mul_130 = cute.tuple_mul(%itup_127, %29) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %176 = cute.get_scalars(%mul_130) : !cute.int_tuple<"?">
      %mul_131 = cute.tuple_mul(%itup_128, %29) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %177 = cute.get_scalars(%mul_131) : !cute.int_tuple<"?">
      cf.br ^bb16(%175, %176, %177, %173, %140, %141, %171, %172 : i32, i32, i32, i1, i32, i32, i32, i32)
    ^bb43:  // pred: ^bb16
      %178 = arith.addi %123, %c1_i32 : i32
      %179 = arith.cmpi eq, %178, %c6_i32 : i32
      %180 = arith.select %179, %c0_i32, %178 : i32
      cf.cond_br %179, ^bb44, ^bb45
    ^bb44:  // pred: ^bb43
      %181 = arith.xori %124, %c1_i32 : i32
      cf.br ^bb46(%181 : i32)
    ^bb45:  // pred: ^bb43
      cf.br ^bb46(%124 : i32)
    ^bb46(%182: i32):  // 2 preds: ^bb44, ^bb45
      cf.br ^bb47
    ^bb47:  // pred: ^bb46
      %183 = arith.addi %180, %c1_i32 : i32
      %184 = arith.cmpi eq, %183, %c6_i32 : i32
      %185 = arith.select %184, %c0_i32, %183 : i32
      cf.cond_br %184, ^bb48, ^bb49
    ^bb48:  // pred: ^bb47
      %186 = arith.xori %182, %c1_i32 : i32
      cf.br ^bb50(%186 : i32)
    ^bb49:  // pred: ^bb47
      cf.br ^bb50(%182 : i32)
    ^bb50(%187: i32):  // 2 preds: ^bb48, ^bb49
      cf.br ^bb51
    ^bb51:  // pred: ^bb50
      %188 = arith.addi %185, %c1_i32 : i32
      %189 = arith.cmpi eq, %188, %c6_i32 : i32
      %190 = arith.select %189, %c0_i32, %188 : i32
      cf.cond_br %189, ^bb52, ^bb53
    ^bb52:  // pred: ^bb51
      %191 = arith.xori %187, %c1_i32 : i32
      cf.br ^bb54(%191 : i32)
    ^bb53:  // pred: ^bb51
      cf.br ^bb54(%187 : i32)
    ^bb54(%192: i32):  // 2 preds: ^bb52, ^bb53
      cf.br ^bb55
    ^bb55:  // pred: ^bb54
      %193 = arith.addi %190, %c1_i32 : i32
      %194 = arith.cmpi eq, %193, %c6_i32 : i32
      %195 = arith.select %194, %c0_i32, %193 : i32
      cf.cond_br %194, ^bb56, ^bb57
    ^bb56:  // pred: ^bb55
      %196 = arith.xori %192, %c1_i32 : i32
      cf.br ^bb58(%196 : i32)
    ^bb57:  // pred: ^bb55
      cf.br ^bb58(%192 : i32)
    ^bb58(%197: i32):  // 2 preds: ^bb56, ^bb57
      cf.br ^bb59
    ^bb59:  // pred: ^bb58
      %198 = arith.addi %195, %c1_i32 : i32
      %199 = arith.cmpi eq, %198, %c6_i32 : i32
      %200 = arith.select %199, %c0_i32, %198 : i32
      cf.cond_br %199, ^bb60, ^bb61
    ^bb60:  // pred: ^bb59
      %201 = arith.xori %197, %c1_i32 : i32
      cf.br ^bb62(%201 : i32)
    ^bb61:  // pred: ^bb59
      cf.br ^bb62(%197 : i32)
    ^bb62(%202: i32):  // 2 preds: ^bb60, ^bb61
      cf.br ^bb63
    ^bb63:  // pred: ^bb62
      %int_tuple_132 = cute.make_int_tuple(%200) : (i32) -> !cute.int_tuple<"?">
      %ptr_133 = cute.add_offset(%ptr_13, %int_tuple_132) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %203 = builtin.unrealized_conversion_cast %ptr_133 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %203, %202, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %204 = nvvm.elect.sync -> i1
      cf.cond_br %204, ^bb64, ^bb65
    ^bb64:  // pred: ^bb63
      %ptr_134 = cute.add_offset(%iter_7, %int_tuple_132) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %205 = builtin.unrealized_conversion_cast %ptr_134 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %205, %c32768_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
      cf.br ^bb65
    ^bb65:  // 2 preds: ^bb63, ^bb64
      cf.br ^bb66
    ^bb66:  // 2 preds: ^bb14, ^bb65
      %206 = arith.cmpi eq, %49, %c4_i32 : i32
      cf.cond_br %206, ^bb67, ^bb114
    ^bb67:  // pred: ^bb66
      nvvm.barrier id = %c3_i32 number_of_threads = %c160_i32
      %tmem_ptr = cute_nvgpu.arch.sm100.retrieve_tmem_ptr(%iter) : !cute.ptr<i32, smem, align<8>> -> !cute.ptr<f32, tmem, align<16>>
      %207 = nvvm.read.ptx.sreg.ctaid.z range <i32, 0, 65535> : i32
      %208 = nvvm.read.ptx.sreg.nctaid.x range <i32, 1, 2147483647> : i32
      %209 = nvvm.read.ptx.sreg.nctaid.y range <i32, 1, 65535> : i32
      %210 = nvvm.read.ptx.sreg.nctaid.z range <i32, 1, 65535> : i32
      %int_tuple_135 = cute.make_int_tuple(%208, %209, %210) : (i32, i32, i32) -> !cute.int_tuple<"(?,?,?)">
      %sz_136 = cute.size(%int_tuple_135) : (!cute.int_tuple<"(?,?,?)">) -> !cute.int_tuple<"?">
      %e0_137 = cute.get_leaves(%sz_136) : !cute.int_tuple<"?">
      %div_138 = cute.tuple_div(%e0_137, %29) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %211 = cute.get_scalars(%div_138) : !cute.int_tuple<"?">
      %sz_139 = cute.size(%lay) : (!cute.layout<"(?,?,?):(1,?,?)">) -> !cute.int_tuple<"?">
      %e0_140 = cute.get_leaves(%sz_139) : !cute.int_tuple<"?">
      %212 = cute.get_scalars(%e0_140) : !cute.int_tuple<"?">
      %213 = arith.cmpi sgt, %212, %207 : i32
      %214 = arith.cmpi sgt, %93, %c0_i32 : i32
      %215 = arith.extui %214 : i1 to i32
      %216 = arith.select %214, %c1_i32, %215 : i32
      %217 = arith.cmpi ne, %216, %c0_i32 : i32
      %218 = cute.get_scalars(%29) : !cute.int_tuple<"1">
      cf.br ^bb68(%213, %c0_i32, %c0_i32, %0, %c0_i32, %c0_i32, %c1_i32, %207, %c0_i32 : i1, i32, i32, !llvm.struct<(i1, i1, i1)>, i32, i32, i32, i32, i32)
    ^bb68(%219: i1, %220: i32, %221: i32, %222: !llvm.struct<(i1, i1, i1)>, %223: i32, %224: i32, %225: i32, %226: i32, %227: i32):  // 2 preds: ^bb67, ^bb106
      cf.cond_br %219, ^bb69(%220, %221, %222, %223, %224, %225, %226, %227 : i32, i32, !llvm.struct<(i1, i1, i1)>, i32, i32, i32, i32, i32), ^bb107
    ^bb69(%228: i32, %229: i32, %230: !llvm.struct<(i1, i1, i1)>, %231: i32, %232: i32, %233: i32, %234: i32, %235: i32):  // pred: ^bb68
      %236 = builtin.unrealized_conversion_cast %230 : !llvm.struct<(i1, i1, i1)> to !mma_tf32_tf32_f32_128x128x8_
      %coord_141 = cute.make_coord(%232) : (i32) -> !cute.coord<"(_,_,_,?)">
      %idx_142 = cute.crd2idx(%coord_141, %12) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((128,128),1,1,2):((65536,1),0,0,128)">) -> !cute.int_tuple<"?{div=128}">
      %ptr_143 = cute.add_offset(%tmem_ptr, %idx_142) : (!cute.ptr<f32, tmem, align<16>>, !cute.int_tuple<"?{div=128}">) -> !cute.ptr<f32, tmem, align<16>>
      cf.cond_br %217, ^bb70, ^bb71
    ^bb70:  // pred: ^bb69
      %int_tuple_144 = cute.make_int_tuple(%228) : (i32) -> !cute.int_tuple<"?">
      %ptr_145 = cute.add_offset(%iter_7, %int_tuple_144) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %237 = builtin.unrealized_conversion_cast %ptr_145 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      %238 = nvvm.mbarrier.wait.parity %237, %229 {kind = #nvvm.mbar_wait<try>} : !llvm.ptr<3>, i32 -> i1
      cf.br ^bb72(%238 : i1)
    ^bb71:  // pred: ^bb69
      cf.br ^bb72(%true : i1)
    ^bb72(%239: i1):  // 2 preds: ^bb70, ^bb71
      cf.br ^bb73
    ^bb73:  // pred: ^bb72
      %int_tuple_146 = cute.make_int_tuple(%232) : (i32) -> !cute.int_tuple<"?">
      %ptr_147 = cute.add_offset(%ptr_26, %int_tuple_146) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %240 = builtin.unrealized_conversion_cast %ptr_147 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %240, %233, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %241 = cute_nvgpu.atom.set_value(%236, %false : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_tf32_tf32_f32_128x128x8_
      %242 = builtin.unrealized_conversion_cast %241 : !mma_tf32_tf32_f32_128x128x8_ to !llvm.struct<(i1, i1, i1)>
      cf.br ^bb74(%c0_i32, %239, %242, %c0_i32, %228, %229 : i32, i1, !llvm.struct<(i1, i1, i1)>, i32, i32, i32)
    ^bb74(%243: i32, %244: i1, %245: !llvm.struct<(i1, i1, i1)>, %246: i32, %247: i32, %248: i32):  // 2 preds: ^bb73, ^bb99
      %249 = arith.cmpi slt, %243, %93 : i32
      cf.cond_br %249, ^bb75, ^bb100
    ^bb75:  // pred: ^bb74
      %250 = arith.extui %244 : i1 to i32
      %251 = arith.cmpi eq, %250, %c0_i32 : i32
      cf.cond_br %251, ^bb76, ^bb77
    ^bb76:  // pred: ^bb75
      %int_tuple_148 = cute.make_int_tuple(%247) : (i32) -> !cute.int_tuple<"?">
      %ptr_149 = cute.add_offset(%iter_7, %int_tuple_148) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %252 = builtin.unrealized_conversion_cast %ptr_149 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %252, %248, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      cf.br ^bb77
    ^bb77:  // 2 preds: ^bb75, ^bb76
      cf.br ^bb78(%c0_i32, %245 : i32, !llvm.struct<(i1, i1, i1)>)
    ^bb78(%253: i32, %254: !llvm.struct<(i1, i1, i1)>):  // 2 preds: ^bb77, ^bb88
      %255 = arith.cmpi slt, %253, %c4_i32 : i32
      cf.cond_br %255, ^bb79, ^bb89 {loop_annotation = #loop_annotation2}
    ^bb79:  // pred: ^bb78
      %256 = builtin.unrealized_conversion_cast %254 : !llvm.struct<(i1, i1, i1)> to !mma_tf32_tf32_f32_128x128x8_
      %coord_150 = cute.make_coord(%253, %247) : (i32, i32) -> !cute.coord<"(_,_,?,?)">
      %idx_151 = cute.crd2idx(%coord_150, %11) : (!cute.coord<"(_,_,?,?)">, !cute.layout<"(1,1,4,6):(0,0,2,1024)">) -> !cute.int_tuple<"?{div=2}">
      %tup_152 = cute.add_offset(%ummaSmemDesc, %idx_151) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
      %tup_153 = cute.add_offset(%ummaSmemDesc_75, %idx_151) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
      %257 = cute_nvgpu.atom.get_value(%256 : !mma_tf32_tf32_f32_128x128x8_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : i1
      %258 = cute_nvgpu.atom.get_value(%256 : !mma_tf32_tf32_f32_128x128x8_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : i1
      %259 = cute_nvgpu.atom.get_value(%256 : !mma_tf32_tf32_f32_128x128x8_) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : i1
      %260 = arith.extui %257 : i1 to i32
      %261 = arith.extui %258 : i1 to i32
      %262 = arith.shli %260, %c13_i32 : i32
      %263 = arith.shli %261, %c14_i32 : i32
      %264 = arith.ori %262, %c136317200_i32 : i32
      %265 = arith.ori %264, %263 : i32
      cf.br ^bb80(%c0_i32 : i32)
    ^bb80(%266: i32):  // 2 preds: ^bb79, ^bb87
      %267 = arith.cmpi slt, %266, %218 : i32
      cf.cond_br %267, ^bb81, ^bb88 {llvm.loop_annotation = #loop_annotation1}
    ^bb81:  // pred: ^bb80
      cf.br ^bb82(%c0_i32 : i32)
    ^bb82(%268: i32):  // 2 preds: ^bb81, ^bb86
      %269 = arith.cmpi slt, %268, %218 : i32
      cf.cond_br %269, ^bb83, ^bb87 {llvm.loop_annotation = #loop_annotation1}
    ^bb83:  // pred: ^bb82
      cf.br ^bb84(%c0_i32 : i32)
    ^bb84(%270: i32):  // 2 preds: ^bb83, ^bb85
      %271 = arith.cmpi slt, %270, %218 : i32
      cf.cond_br %271, ^bb85, ^bb86 {llvm.loop_annotation = #loop_annotation1}
    ^bb85:  // pred: ^bb84
      cute_nvgpu.arch.mma.SM100.umma(%tup_152, %tup_153, %ptr_143, %265, %259) {num_cta = 1 : i32, scale = 0 : i32, a_type = tf32} : (!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, !cute.ptr<f32, tmem, align<16>>, i32, i1) -> ()
      %272 = arith.addi %270, %c1_i32 : i32
      cf.br ^bb84(%272 : i32)
    ^bb86:  // pred: ^bb84
      %273 = arith.addi %268, %c1_i32 : i32
      cf.br ^bb82(%273 : i32)
    ^bb87:  // pred: ^bb82
      %274 = arith.addi %266, %c1_i32 : i32
      cf.br ^bb80(%274 : i32)
    ^bb88:  // pred: ^bb80
      %275 = cute_nvgpu.atom.set_value(%256, %true : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_tf32_tf32_f32_128x128x8_
      %276 = builtin.unrealized_conversion_cast %275 : !mma_tf32_tf32_f32_128x128x8_ to !llvm.struct<(i1, i1, i1)>
      %277 = arith.addi %253, %c1_i32 : i32
      cf.br ^bb78(%277, %276 : i32, !llvm.struct<(i1, i1, i1)>)
    ^bb89:  // pred: ^bb78
      %278 = nvvm.elect.sync -> i1
      cf.cond_br %278, ^bb90, ^bb91
    ^bb90:  // pred: ^bb89
      %int_tuple_154 = cute.make_int_tuple(%247) : (i32) -> !cute.int_tuple<"?">
      %ptr_155 = cute.add_offset(%ptr_13, %int_tuple_154) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %279 = builtin.unrealized_conversion_cast %ptr_155 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.tcgen05.commit.arrive %279 : !llvm.ptr<3>
      cf.br ^bb91
    ^bb91:  // 2 preds: ^bb89, ^bb90
      %280 = arith.addi %247, %c1_i32 : i32
      %281 = arith.addi %246, %c1_i32 : i32
      %282 = arith.cmpi eq, %280, %c6_i32 : i32
      %283 = arith.select %282, %c0_i32, %280 : i32
      cf.cond_br %282, ^bb92, ^bb93
    ^bb92:  // pred: ^bb91
      %284 = arith.xori %248, %c1_i32 : i32
      cf.br ^bb94(%284 : i32)
    ^bb93:  // pred: ^bb91
      cf.br ^bb94(%248 : i32)
    ^bb94(%285: i32):  // 2 preds: ^bb92, ^bb93
      cf.br ^bb95
    ^bb95:  // pred: ^bb94
      %286 = arith.cmpi sgt, %93, %281 : i32
      cf.cond_br %286, ^bb96, ^bb97
    ^bb96:  // pred: ^bb95
      %int_tuple_156 = cute.make_int_tuple(%283) : (i32) -> !cute.int_tuple<"?">
      %ptr_157 = cute.add_offset(%iter_7, %int_tuple_156) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %287 = builtin.unrealized_conversion_cast %ptr_157 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      %288 = nvvm.mbarrier.wait.parity %287, %285 {kind = #nvvm.mbar_wait<try>} : !llvm.ptr<3>, i32 -> i1
      cf.br ^bb98(%288 : i1)
    ^bb97:  // pred: ^bb95
      cf.br ^bb98(%true : i1)
    ^bb98(%289: i1):  // 2 preds: ^bb96, ^bb97
      cf.br ^bb99
    ^bb99:  // pred: ^bb98
      %290 = arith.addi %243, %c1_i32 : i32
      cf.br ^bb74(%290, %289, %254, %281, %283, %285 : i32, i1, !llvm.struct<(i1, i1, i1)>, i32, i32, i32)
    ^bb100:  // pred: ^bb74
      %291 = nvvm.elect.sync -> i1
      cf.cond_br %291, ^bb101, ^bb102
    ^bb101:  // pred: ^bb100
      %ptr_158 = cute.add_offset(%iter_24, %int_tuple_146) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %292 = builtin.unrealized_conversion_cast %ptr_158 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.tcgen05.commit.arrive %292 : !llvm.ptr<3>
      cf.br ^bb102
    ^bb102:  // 2 preds: ^bb100, ^bb101
      %293 = arith.addi %232, %c1_i32 : i32
      %294 = arith.addi %231, %c1_i32 : i32
      %295 = arith.cmpi eq, %293, %c2_i32 : i32
      %296 = arith.select %295, %c0_i32, %293 : i32
      cf.cond_br %295, ^bb103, ^bb104
    ^bb103:  // pred: ^bb102
      %297 = arith.xori %233, %c1_i32 : i32
      cf.br ^bb105(%297 : i32)
    ^bb104:  // pred: ^bb102
      cf.br ^bb105(%233 : i32)
    ^bb105(%298: i32):  // 2 preds: ^bb103, ^bb104
      cf.br ^bb106
    ^bb106:  // pred: ^bb105
      %299 = arith.addi %234, %211 : i32
      %300 = arith.addi %235, %c1_i32 : i32
      %301 = arith.cmpi sgt, %212, %299 : i32
      cf.br ^bb68(%301, %247, %248, %245, %294, %296, %298, %299, %300 : i1, i32, i32, !llvm.struct<(i1, i1, i1)>, i32, i32, i32, i32, i32)
    ^bb107:  // pred: ^bb68
      %302 = nvvm.read.ptx.sreg.cluster.ctarank : i32
      %303 = cute_nvgpu.arch.make_warp_uniform(%302) : i32
      %304 = arith.remsi %303, %c2_i32 : i32
      %305 = arith.cmpi eq, %304, %c0_i32 : i32
      cf.cond_br %305, ^bb108, ^bb113
    ^bb108:  // pred: ^bb107
      %306 = arith.addi %224, %c1_i32 : i32
      %307 = arith.cmpi eq, %306, %c2_i32 : i32
      %308 = arith.select %307, %c0_i32, %306 : i32
      cf.cond_br %307, ^bb109, ^bb110
    ^bb109:  // pred: ^bb108
      %309 = arith.xori %225, %c1_i32 : i32
      cf.br ^bb111(%309 : i32)
    ^bb110:  // pred: ^bb108
      cf.br ^bb111(%225 : i32)
    ^bb111(%310: i32):  // 2 preds: ^bb109, ^bb110
      cf.br ^bb112
    ^bb112:  // pred: ^bb111
      %int_tuple_159 = cute.make_int_tuple(%308) : (i32) -> !cute.int_tuple<"?">
      %ptr_160 = cute.add_offset(%ptr_26, %int_tuple_159) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %311 = builtin.unrealized_conversion_cast %ptr_160 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %311, %310, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      cf.br ^bb113
    ^bb113:  // 2 preds: ^bb107, ^bb112
      cf.br ^bb114
    ^bb114:  // 2 preds: ^bb66, ^bb113
      %312 = arith.cmpi slt, %49, %c4_i32 : i32
      cf.cond_br %312, ^bb115, ^bb154
    ^bb115:  // pred: ^bb114
      cf.cond_br %51, ^bb116, ^bb117
    ^bb116:  // pred: ^bb115
      cute_nvgpu.arch.sm100.alloc_tmem(%c256_i32, %iter) [ cta_1] : i32, !cute.ptr<i32, smem, align<8>>
      cf.br ^bb117
    ^bb117:  // 2 preds: ^bb115, ^bb116
      nvvm.barrier id = %c3_i32 number_of_threads = %c160_i32
      %tmem_ptr_161 = cute_nvgpu.arch.sm100.retrieve_tmem_ptr(%iter) : !cute.ptr<i32, smem, align<8>> -> !cute.ptr<f32, tmem, align<16>>
      %coord_162 = cute.make_coord(%38) : (i32) -> !cute.coord<"?">
      %313 = cute.get_scalars(%coord_162) <{only_dynamic}> : !cute.coord<"?">
      %314 = arith.divsi %313, %c32_i32 : i32
      %315 = arith.muli %314, %c2097152_i32 : i32
      %iv = cute.assume(%315) : (i32) -> !cute.i32<divby 2097152>
      %int_tuple_163 = cute.make_int_tuple(%iv) : (!cute.i32<divby 2097152>) -> !cute.int_tuple<"?{div=2097152}">
      %ptr_164 = cute.add_offset(%tmem_ptr_161, %int_tuple_163) : (!cute.ptr<f32, tmem, align<16>>, !cute.int_tuple<"?{div=2097152}">) -> !cute.ptr<f32, tmem, align<16>>
      %rmem = cute.memref.alloca() : !memref_rmem_f32_
      %iter_165 = cute.get_iter(%rmem) : !memref_rmem_f32_
      %rmem_166 = cute.memref.alloca() : !memref_rmem_f32_
      %atom = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<f32>
      %316 = cute.make_tiled_copy(%atom) : !copy_simt
      %317 = arith.remsi %313, %c32_i32 : i32
      %318 = arith.muli %317, %c16_i32 : i32
      %319 = arith.muli %314, %c512_i32 : i32
      %320 = arith.addi %318, %319 : i32
      %iv_167 = cute.assume(%320) : (i32) -> !cute.i32<divby 16>
      %int_tuple_168 = cute.make_int_tuple(%iv_167) : (!cute.i32<divby 16>) -> !cute.int_tuple<"?{div=16}">
      %ptr_169 = cute.add_offset(%iter_34, %int_tuple_168) : (!cute.ptr<f32, smem, align<1024>, S<2,4,3>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<f32, smem, align<64>, S<2,4,3>>
      %iter_170 = cute.get_iter(%rmem_166) : !memref_rmem_f32_
      %rmem_171 = cute.memref.alloca() : !memref_rmem_f32_
      %321 = cute.make_tiled_copy(%atom) : !copy_simt
      %ptr_172 = cute.add_offset(%iter_35, %int_tuple_168) : (!cute.ptr<f32, smem, align<1024>, S<2,4,3>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<f32, smem, align<64>, S<2,4,3>>
      %iter_173 = cute.get_iter(%rmem_171) : !memref_rmem_f32_
      %view = cute.make_view(%iter_173) : !memref_rmem_f32_1
      %322:3 = cute.get_scalars(%lay_66) <{only_dynamic}> : !cute.layout<"((128,128),1,1,?,?,?):((1@1,1@0),0,0,128@1,128@0,1@2)">
      %shape_174 = cute.make_shape(%322#0, %322#1, %322#2) : (i32, i32, i32) -> !cute.shape<"(128,128,?,?,?)">
      %lay_175 = cute.make_layout(%shape_174, %19) : !cute.layout<"(128,128,?,?,?):(1@1,1@0,128@1,128@0,1@2)">
      %323:3 = cute.get_scalars(%lay_175) <{only_dynamic}> : !cute.layout<"(128,128,?,?,?):(1@1,1@0,128@1,128@0,1@2)">
      %shape_176 = cute.make_shape(%323#0, %323#1, %323#2) : (i32, i32, i32) -> !cute.shape<"(128,16,1,8,?,?,?)">
      %lay_177 = cute.make_layout(%shape_176, %10) : !cute.layout<"(128,16,1,8,?,?,?):(1@1,1@0,0,16@0,128@1,128@0,1@2)">
      %324:3 = cute.get_scalars(%lay_177) <{only_dynamic}> : !cute.layout<"(128,16,1,8,?,?,?):(1@1,1@0,0,16@0,128@1,128@0,1@2)">
      %shape_178 = cute.make_shape(%324#0, %324#1, %324#2) : (i32, i32, i32) -> !cute.shape<"((128,16),1,8,?,?,?)">
      %lay_179 = cute.make_layout(%shape_178, %9) : !cute.layout<"((128,16),1,8,?,?,?):((1@1,1@0),0,16@0,128@1,128@0,1@2)">
      %325:3 = cute.get_scalars(%lay_179) <{only_dynamic}> : !cute.layout<"((128,16),1,8,?,?,?):((1@1,1@0),0,16@0,128@1,128@0,1@2)">
      %shape_180 = cute.make_shape(%325#0, %325#1, %325#2) : (i32, i32, i32) -> !cute.shape<"(((16,128),1),1,8,?,?,?)">
      %lay_181 = cute.make_layout(%shape_180, %8) : !cute.layout<"(((16,128),1),1,8,?,?,?):(((1@0,1@1),0),0,16@0,128@1,128@0,1@2)">
      %326 = nvvm.read.ptx.sreg.ctaid.z range <i32, 0, 65535> : i32
      %327 = nvvm.read.ptx.sreg.nctaid.x range <i32, 1, 2147483647> : i32
      %328 = nvvm.read.ptx.sreg.nctaid.y range <i32, 1, 65535> : i32
      %329 = nvvm.read.ptx.sreg.nctaid.z range <i32, 1, 65535> : i32
      %int_tuple_182 = cute.make_int_tuple(%327, %328, %329) : (i32, i32, i32) -> !cute.int_tuple<"(?,?,?)">
      %sz_183 = cute.size(%int_tuple_182) : (!cute.int_tuple<"(?,?,?)">) -> !cute.int_tuple<"?">
      %e0_184 = cute.get_leaves(%sz_183) : !cute.int_tuple<"?">
      %div_185 = cute.tuple_div(%e0_184, %29) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %330 = cute.get_scalars(%div_185) : !cute.int_tuple<"?">
      %sz_186 = cute.size(%lay) : (!cute.layout<"(?,?,?):(1,?,?)">) -> !cute.int_tuple<"?">
      %e0_187 = cute.get_leaves(%sz_186) : !cute.int_tuple<"?">
      %331 = cute.get_scalars(%e0_187) : !cute.int_tuple<"?">
      %332 = arith.cmpi sgt, %331, %326 : i32
      %333 = cute.get_hier_coord(%326, %lay) : (i32, !cute.layout<"(?,?,?):(1,?,?)">) -> !cute.coord<"(?,?,?)">
      %e0_188, %e1_189, %e2_190 = cute.get_leaves(%333) : !cute.coord<"(?,?,?)">
      %itup_191 = cute.to_int_tuple(%e0_188) : !cute.coord<"?"> to !cute.int_tuple<"?">
      %itup_192 = cute.to_int_tuple(%e1_189) : !cute.coord<"?"> to !cute.int_tuple<"?">
      %itup_193 = cute.to_int_tuple(%e2_190) : !cute.coord<"?"> to !cute.int_tuple<"?">
      %mul_194 = cute.tuple_mul(%itup_191, %29) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %334 = cute.get_scalars(%mul_194) : !cute.int_tuple<"?">
      %mul_195 = cute.tuple_mul(%itup_192, %29) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %335 = cute.get_scalars(%mul_195) : !cute.int_tuple<"?">
      %mul_196 = cute.tuple_mul(%itup_193, %29) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %336 = cute.get_scalars(%mul_196) : !cute.int_tuple<"?">
      %337 = cute.get_scalars(%29) : !cute.int_tuple<"1">
      %338 = builtin.unrealized_conversion_cast %iter_165 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
      %swizzled = cute.apply_swizzle(%ptr_169) : !cute.ptr<f32, smem, align<64>, S<2,4,3>>
      %339 = builtin.unrealized_conversion_cast %iter_170 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
      %ptr_197 = cute.add_offset(%iter_170, %26) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
      %ptr_198 = cute.add_offset(%ptr_169, %26) : (!cute.ptr<f32, smem, align<64>, S<2,4,3>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, smem, align<16>, S<2,4,3>>
      %swizzled_199 = cute.apply_swizzle(%ptr_198) : !cute.ptr<f32, smem, align<16>, S<2,4,3>>
      %340 = builtin.unrealized_conversion_cast %ptr_197 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %ptr_200 = cute.add_offset(%iter_170, %4) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<f32, rmem, align<32>>
      %ptr_201 = cute.add_offset(%ptr_169, %4) : (!cute.ptr<f32, smem, align<64>, S<2,4,3>>, !cute.int_tuple<"8">) -> !cute.ptr<f32, smem, align<32>, S<2,4,3>>
      %swizzled_202 = cute.apply_swizzle(%ptr_201) : !cute.ptr<f32, smem, align<32>, S<2,4,3>>
      %341 = builtin.unrealized_conversion_cast %ptr_200 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
      %ptr_203 = cute.add_offset(%iter_170, %3) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<f32, rmem, align<16>>
      %ptr_204 = cute.add_offset(%ptr_169, %3) : (!cute.ptr<f32, smem, align<64>, S<2,4,3>>, !cute.int_tuple<"12">) -> !cute.ptr<f32, smem, align<16>, S<2,4,3>>
      %swizzled_205 = cute.apply_swizzle(%ptr_204) : !cute.ptr<f32, smem, align<16>, S<2,4,3>>
      %342 = builtin.unrealized_conversion_cast %ptr_203 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %view_206 = cute.make_view(%iter_165) : !memref_rmem_f32_1
      %view_207 = cute.make_view(%iter_170) : !memref_rmem_f32_1
      %343 = vector.broadcast %arg12 : f32 to vector<16xf32>
      %344 = vector.broadcast %arg13 : f32 to vector<16xf32>
      %swizzled_208 = cute.apply_swizzle(%ptr_172) : !cute.ptr<f32, smem, align<64>, S<2,4,3>>
      %345 = builtin.unrealized_conversion_cast %iter_173 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
      %ptr_209 = cute.add_offset(%iter_173, %26) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
      %ptr_210 = cute.add_offset(%ptr_172, %26) : (!cute.ptr<f32, smem, align<64>, S<2,4,3>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, smem, align<16>, S<2,4,3>>
      %swizzled_211 = cute.apply_swizzle(%ptr_210) : !cute.ptr<f32, smem, align<16>, S<2,4,3>>
      %346 = builtin.unrealized_conversion_cast %ptr_209 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %ptr_212 = cute.add_offset(%iter_173, %4) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<f32, rmem, align<32>>
      %ptr_213 = cute.add_offset(%ptr_172, %4) : (!cute.ptr<f32, smem, align<64>, S<2,4,3>>, !cute.int_tuple<"8">) -> !cute.ptr<f32, smem, align<32>, S<2,4,3>>
      %swizzled_214 = cute.apply_swizzle(%ptr_213) : !cute.ptr<f32, smem, align<32>, S<2,4,3>>
      %347 = builtin.unrealized_conversion_cast %ptr_212 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
      %ptr_215 = cute.add_offset(%iter_173, %3) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<f32, rmem, align<16>>
      %ptr_216 = cute.add_offset(%ptr_172, %3) : (!cute.ptr<f32, smem, align<64>, S<2,4,3>>, !cute.int_tuple<"12">) -> !cute.ptr<f32, smem, align<16>, S<2,4,3>>
      %swizzled_217 = cute.apply_swizzle(%ptr_216) : !cute.ptr<f32, smem, align<16>, S<2,4,3>>
      %348 = builtin.unrealized_conversion_cast %ptr_215 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      cf.br ^bb118(%334, %335, %336, %332, %c0_i32, %c0_i32, %c0_i32, %c0_i32, %c0_i32, %c0_i32, %326, %c0_i32 : i32, i32, i32, i1, i32, i32, i32, i32, i32, i32, i32, i32)
    ^bb118(%349: i32, %350: i32, %351: i32, %352: i1, %353: i32, %354: i32, %355: i32, %356: i32, %357: i32, %358: i32, %359: i32, %360: i32):  // 2 preds: ^bb117, ^bb148
      cf.cond_br %352, ^bb119(%349, %350, %351, %353, %354, %355, %356, %357, %358, %359, %360 : i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32), ^bb149
    ^bb119(%361: i32, %362: i32, %363: i32, %364: i32, %365: i32, %366: i32, %367: i32, %368: i32, %369: i32, %370: i32, %371: i32):  // pred: ^bb118
      %coord_218 = cute.make_coord(%361, %362, %363) : (i32, i32, i32) -> !cute.coord<"(_,_,_,?,?,?)">
      %idx_219 = cute.crd2idx(%coord_218, %lay_181) : (!cute.coord<"(_,_,_,?,?,?)">, !cute.layout<"(((16,128),1),1,8,?,?,?):(((1@0,1@1),0),0,16@0,128@1,128@0,1@2)">) -> !cute.int_tuple<"(?{div=128},?{div=128},?)">
      %tup_220 = cute.add_offset(%21, %idx_219) : (!cute.int_tuple<"(0,0,0)">, !cute.int_tuple<"(?{div=128},?{div=128},?)">) -> !cute.int_tuple<"(?{div=128},?{div=128},?)">
      %coord_221 = cute.make_coord(%368) : (i32) -> !cute.coord<"(_,_,_,_,_,?)">
      %idx_222 = cute.crd2idx(%coord_221, %7) : (!cute.coord<"(_,_,_,_,_,?)">, !cute.layout<"(((16,32),1),1,1,1,8,2):(((1,65536),0),0,0,0,16,128)">) -> !cute.int_tuple<"?{div=128}">
      %ptr_223 = cute.add_offset(%ptr_164, %idx_222) : (!cute.ptr<f32, tmem, align<16>>, !cute.int_tuple<"?{div=128}">) -> !cute.ptr<f32, tmem, align<16>>
      %int_tuple_224 = cute.make_int_tuple(%368) : (i32) -> !cute.int_tuple<"?">
      %ptr_225 = cute.add_offset(%iter_24, %int_tuple_224) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %372 = builtin.unrealized_conversion_cast %ptr_225 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %372, %369, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %373 = arith.muli %371, %c8_i32 : i32
      cf.br ^bb120(%c0_i32, %364, %365, %366 : i32, i32, i32, i32)
    ^bb120(%374: i32, %375: i32, %376: i32, %377: i32):  // 2 preds: ^bb119, ^bb141
      %378 = arith.cmpi slt, %374, %c8_i32 : i32
      cf.cond_br %378, ^bb121, ^bb142
    ^bb121:  // pred: ^bb120
      %coord_226 = cute.make_coord(%374) : (i32) -> !cute.coord<"(_,_,_,?)">
      %idx_227 = cute.crd2idx(%coord_226, %6) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"(((16,32),1),1,1,(1,8)):(((1,65536),0),0,0,(0,16))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_228 = cute.add_offset(%ptr_223, %idx_227) : (!cute.ptr<f32, tmem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<f32, tmem, align<16>>
      cf.br ^bb122(%c0_i32 : i32)
    ^bb122(%379: i32):  // 2 preds: ^bb121, ^bb123
      %380 = arith.cmpi slt, %379, %337 : i32
      cf.cond_br %380, ^bb123, ^bb124 {llvm.loop_annotation = #loop_annotation1}
    ^bb123:  // pred: ^bb122
      %381 = "cute_nvgpu.arch.copy.SM100.tmem_load"(%ptr_228) <{num_b = 32 : i32, num_dp = 32 : i32, num_rep = 16 : i32}> : (!cute.ptr<f32, tmem, align<16>>) -> vector<16xi32>
      llvm.store %381, %338 : vector<16xi32>, !llvm.ptr
      %382 = arith.addi %379, %c1_i32 : i32
      cf.br ^bb122(%382 : i32)
    ^bb124:  // pred: ^bb122
      %int_tuple_229 = cute.make_int_tuple(%376) : (i32) -> !cute.int_tuple<"?">
      %ptr_230 = cute.add_offset(%iter_29, %int_tuple_229) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %383 = builtin.unrealized_conversion_cast %ptr_230 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %383, %377, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %coord_231 = cute.make_coord(%376) : (i32) -> !cute.coord<"(_,_,_,?)">
      %idx_232 = cute.crd2idx(%coord_231, %5) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((1,16),1,1,(1,2)):((0,1),0,0,(0,2048))">) -> !cute.int_tuple<"?{div=2048}">
      %ptr_233 = cute.add_offset(%swizzled, %idx_232) : (!cute.ptr<f32, smem, align<64>, S<2,4,3>>, !cute.int_tuple<"?{div=2048}">) -> !cute.ptr<f32, smem, align<64>, S<2,4,3>>
      %384 = builtin.unrealized_conversion_cast %ptr_233 : !cute.ptr<f32, smem, align<64>, S<2,4,3>> to !llvm.ptr<3>
      %ptr_234 = cute.add_offset(%swizzled_199, %idx_232) : (!cute.ptr<f32, smem, align<16>, S<2,4,3>>, !cute.int_tuple<"?{div=2048}">) -> !cute.ptr<f32, smem, align<16>, S<2,4,3>>
      %385 = builtin.unrealized_conversion_cast %ptr_234 : !cute.ptr<f32, smem, align<16>, S<2,4,3>> to !llvm.ptr<3>
      %ptr_235 = cute.add_offset(%swizzled_202, %idx_232) : (!cute.ptr<f32, smem, align<32>, S<2,4,3>>, !cute.int_tuple<"?{div=2048}">) -> !cute.ptr<f32, smem, align<32>, S<2,4,3>>
      %386 = builtin.unrealized_conversion_cast %ptr_235 : !cute.ptr<f32, smem, align<32>, S<2,4,3>> to !llvm.ptr<3>
      %ptr_236 = cute.add_offset(%swizzled_205, %idx_232) : (!cute.ptr<f32, smem, align<16>, S<2,4,3>>, !cute.int_tuple<"?{div=2048}">) -> !cute.ptr<f32, smem, align<16>, S<2,4,3>>
      %387 = builtin.unrealized_conversion_cast %ptr_236 : !cute.ptr<f32, smem, align<16>, S<2,4,3>> to !llvm.ptr<3>
      cf.br ^bb125(%c0_i32 : i32)
    ^bb125(%388: i32):  // 2 preds: ^bb124, ^bb126
      %389 = arith.cmpi slt, %388, %337 : i32
      cf.cond_br %389, ^bb126, ^bb127 {llvm.loop_annotation = #loop_annotation1}
    ^bb126:  // pred: ^bb125
      %390 = llvm.load %384 {alignment = 16 : i64} : !llvm.ptr<3> -> vector<4xf32>
      llvm.store %390, %339 {alignment = 16 : i64} : vector<4xf32>, !llvm.ptr
      %391 = llvm.load %385 {alignment = 16 : i64} : !llvm.ptr<3> -> vector<4xf32>
      llvm.store %391, %340 {alignment = 16 : i64} : vector<4xf32>, !llvm.ptr
      %392 = llvm.load %386 {alignment = 16 : i64} : !llvm.ptr<3> -> vector<4xf32>
      llvm.store %392, %341 {alignment = 16 : i64} : vector<4xf32>, !llvm.ptr
      %393 = llvm.load %387 {alignment = 16 : i64} : !llvm.ptr<3> -> vector<4xf32>
      llvm.store %393, %342 {alignment = 16 : i64} : vector<4xf32>, !llvm.ptr
      %394 = arith.addi %388, %c1_i32 : i32
      cf.br ^bb125(%394 : i32)
    ^bb127:  // pred: ^bb125
      nvvm.fence.proxy {kind = #nvvm.proxy_kind<async.shared>, space = #nvvm.shared_space<cta>}
      cf.cond_br %76, ^bb128, ^bb129
    ^bb128:  // pred: ^bb127
      %ptr_237 = cute.add_offset(%ptr_31, %int_tuple_229) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %395 = builtin.unrealized_conversion_cast %ptr_237 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %395, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>} : !llvm.ptr<3>, i32
      cf.br ^bb129
    ^bb129:  // 2 preds: ^bb127, ^bb128
      %396 = arith.addi %376, %c1_i32 : i32
      %397 = arith.addi %375, %c1_i32 : i32
      %398 = arith.cmpi eq, %396, %c2_i32 : i32
      %399 = arith.select %398, %c0_i32, %396 : i32
      cf.cond_br %398, ^bb130, ^bb131
    ^bb130:  // pred: ^bb129
      %400 = arith.xori %377, %c1_i32 : i32
      cf.br ^bb132(%400 : i32)
    ^bb131:  // pred: ^bb129
      cf.br ^bb132(%377 : i32)
    ^bb132(%401: i32):  // 2 preds: ^bb130, ^bb131
      cf.br ^bb133
    ^bb133:  // pred: ^bb132
      %402 = cute.memref.load_vec %view_206, row_major : !memref_rmem_f32_1
      %403 = cute.memref.load_vec %view_207, row_major : !memref_rmem_f32_1
      %404 = arith.mulf %343, %402 : vector<16xf32>
      %405 = arith.mulf %344, %403 : vector<16xf32>
      %406 = arith.addf %404, %405 : vector<16xf32>
      cute.memref.store_vec %406, %view, row_major : !memref_rmem_f32_1
      %407 = arith.addi %373, %374 : i32
      %408 = arith.remsi %407, %c2_i32 : i32
      %coord_238 = cute.make_coord(%408) : (i32) -> !cute.coord<"(_,_,_,?)">
      %idx_239 = cute.crd2idx(%coord_238, %5) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((1,16),1,1,(1,2)):((0,1),0,0,(0,2048))">) -> !cute.int_tuple<"?{div=2048}">
      %ptr_240 = cute.add_offset(%swizzled_208, %idx_239) : (!cute.ptr<f32, smem, align<64>, S<2,4,3>>, !cute.int_tuple<"?{div=2048}">) -> !cute.ptr<f32, smem, align<64>, S<2,4,3>>
      %409 = builtin.unrealized_conversion_cast %ptr_240 : !cute.ptr<f32, smem, align<64>, S<2,4,3>> to !llvm.ptr<3>
      %ptr_241 = cute.add_offset(%swizzled_211, %idx_239) : (!cute.ptr<f32, smem, align<16>, S<2,4,3>>, !cute.int_tuple<"?{div=2048}">) -> !cute.ptr<f32, smem, align<16>, S<2,4,3>>
      %410 = builtin.unrealized_conversion_cast %ptr_241 : !cute.ptr<f32, smem, align<16>, S<2,4,3>> to !llvm.ptr<3>
      %ptr_242 = cute.add_offset(%swizzled_214, %idx_239) : (!cute.ptr<f32, smem, align<32>, S<2,4,3>>, !cute.int_tuple<"?{div=2048}">) -> !cute.ptr<f32, smem, align<32>, S<2,4,3>>
      %411 = builtin.unrealized_conversion_cast %ptr_242 : !cute.ptr<f32, smem, align<32>, S<2,4,3>> to !llvm.ptr<3>
      %ptr_243 = cute.add_offset(%swizzled_217, %idx_239) : (!cute.ptr<f32, smem, align<16>, S<2,4,3>>, !cute.int_tuple<"?{div=2048}">) -> !cute.ptr<f32, smem, align<16>, S<2,4,3>>
      %412 = builtin.unrealized_conversion_cast %ptr_243 : !cute.ptr<f32, smem, align<16>, S<2,4,3>> to !llvm.ptr<3>
      cf.br ^bb134(%c0_i32 : i32)
    ^bb134(%413: i32):  // 2 preds: ^bb133, ^bb135
      %414 = arith.cmpi slt, %413, %337 : i32
      cf.cond_br %414, ^bb135, ^bb136 {llvm.loop_annotation = #loop_annotation1}
    ^bb135:  // pred: ^bb134
      %415 = llvm.load %345 {alignment = 16 : i64} : !llvm.ptr -> vector<4xf32>
      llvm.store %415, %409 {alignment = 16 : i64} : vector<4xf32>, !llvm.ptr<3>
      %416 = llvm.load %346 {alignment = 16 : i64} : !llvm.ptr -> vector<4xf32>
      llvm.store %416, %410 {alignment = 16 : i64} : vector<4xf32>, !llvm.ptr<3>
      %417 = llvm.load %347 {alignment = 16 : i64} : !llvm.ptr -> vector<4xf32>
      llvm.store %417, %411 {alignment = 16 : i64} : vector<4xf32>, !llvm.ptr<3>
      %418 = llvm.load %348 {alignment = 16 : i64} : !llvm.ptr -> vector<4xf32>
      llvm.store %418, %412 {alignment = 16 : i64} : vector<4xf32>, !llvm.ptr<3>
      %419 = arith.addi %413, %c1_i32 : i32
      cf.br ^bb134(%419 : i32)
    ^bb136:  // pred: ^bb134
      nvvm.fence.proxy {kind = #nvvm.proxy_kind<async.shared>, space = #nvvm.shared_space<cta>}
      nvvm.barrier id = %c2_i32 number_of_threads = %c128_i32
      cf.cond_br %51, ^bb137, ^bb141
    ^bb137:  // pred: ^bb136
      %coord_244 = cute.make_coord(%408) : (i32) -> !cute.coord<"(_,?)">
      %idx_245 = cute.crd2idx(%coord_244, %2) : (!cute.coord<"(_,?)">, !cute.layout<"((2048,1),(1,2)):((1,0),(0,2048))">) -> !cute.int_tuple<"?{div=2048}">
      %ptr_246 = cute.add_offset(%iter_35, %idx_245) : (!cute.ptr<f32, smem, align<1024>, S<2,4,3>>, !cute.int_tuple<"?{div=2048}">) -> !cute.ptr<f32, smem, align<1024>, S<2,4,3>>
      %coord_247 = cute.make_coord(%374) : (i32) -> !cute.coord<"(_,?)">
      %idx_248 = cute.crd2idx(%coord_247, %1) : (!cute.coord<"(_,?)">, !cute.layout<"(((16,128),1),(1,8)):(((1@0,1@1),0),(0,16@0))">) -> !cute.int_tuple<"(?{div=16},0)">
      %tup_249 = cute.add_offset(%tup_220, %idx_248) : (!cute.int_tuple<"(?{div=128},?{div=128},?)">, !cute.int_tuple<"(?{div=16},0)">) -> !cute.int_tuple<"(?{div=16},?{div=128},?)">
      %e0_250, %e1_251, %e2_252 = cute.get_leaves(%tup_249) : !cute.int_tuple<"(?{div=16},?{div=128},?)">
      %int_tuple_253 = cute.make_int_tuple(%e0_250, %e1_251, %e2_252) : (!cute.int_tuple<"?{div=16}">, !cute.int_tuple<"?{div=128}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=16},?{div=128},?)">
      %420 = cute_nvgpu.atom.make_exec_tma(%arg7) : (!cute_nvgpu.atom.non_exec_tiled_tma_store<f32, copy_bits = 65536, tma_gbasis = <"(16,128,1):(1@1,1@0,1@2)">, internal_val_type = f32>) -> !cute_nvgpu.atom.tma_store<f32, copy_bits = 65536, mode = tiled, g_stride = <"()"> tma_gbasis = <"(16,128,1):(1@1,1@0,1@2)">>
      %TMADescAddr_254 = cute_nvgpu.get_tma_desc_addr(%420 : !cute_nvgpu.atom.tma_store<f32, copy_bits = 65536, mode = tiled, g_stride = <"()"> tma_gbasis = <"(16,128,1):(1@1,1@0,1@2)">>) -> !cute.ptr<generic, align<64>>
      %421:3 = cute.get_scalars(%int_tuple_253) : !cute.int_tuple<"(?{div=16},?{div=128},?)">
      cf.br ^bb138(%c0_i32 : i32)
    ^bb138(%422: i32):  // 2 preds: ^bb137, ^bb139
      %423 = arith.cmpi slt, %422, %337 : i32
      cf.cond_br %423, ^bb139, ^bb140 {llvm.loop_annotation = #loop_annotation1}
    ^bb139:  // pred: ^bb138
      cute_nvgpu.arch.copy.SM100.tma_store(%TMADescAddr_254 : !cute.ptr<generic, align<64>>, %ptr_246 : !cute.ptr<f32, smem, align<1024>, S<2,4,3>>, [%421#0, %421#1, %421#2] : i32, i32, i32) mode = <tiled>
      %424 = arith.addi %422, %c1_i32 : i32
      cf.br ^bb138(%424 : i32)
    ^bb140:  // pred: ^bb138
      nvvm.cp.async.bulk.commit.group
      nvvm.cp.async.bulk.wait_group 1 {read}
      cf.br ^bb141
    ^bb141:  // 2 preds: ^bb136, ^bb140
      nvvm.barrier id = %c2_i32 number_of_threads = %c128_i32
      %425 = arith.addi %374, %c1_i32 : i32
      cf.br ^bb120(%425, %397, %399, %401 : i32, i32, i32, i32)
    ^bb142:  // pred: ^bb120
      %426 = nvvm.elect.sync -> i1
      cf.cond_br %426, ^bb143, ^bb144
    ^bb143:  // pred: ^bb142
      %ptr_255 = cute.add_offset(%ptr_26, %int_tuple_224) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %427 = builtin.unrealized_conversion_cast %ptr_255 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %427, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>} : !llvm.ptr<3>, i32
      cf.br ^bb144
    ^bb144:  // 2 preds: ^bb142, ^bb143
      %428 = arith.addi %368, %c1_i32 : i32
      %429 = arith.addi %367, %c1_i32 : i32
      %430 = arith.cmpi eq, %428, %c2_i32 : i32
      %431 = arith.select %430, %c0_i32, %428 : i32
      cf.cond_br %430, ^bb145, ^bb146
    ^bb145:  // pred: ^bb144
      %432 = arith.xori %369, %c1_i32 : i32
      cf.br ^bb147(%432 : i32)
    ^bb146:  // pred: ^bb144
      cf.br ^bb147(%369 : i32)
    ^bb147(%433: i32):  // 2 preds: ^bb145, ^bb146
      cf.br ^bb148
    ^bb148:  // pred: ^bb147
      %434 = arith.addi %370, %330 : i32
      %435 = arith.addi %371, %c1_i32 : i32
      %436 = arith.cmpi sgt, %331, %434 : i32
      %437 = cute.get_hier_coord(%434, %lay) : (i32, !cute.layout<"(?,?,?):(1,?,?)">) -> !cute.coord<"(?,?,?)">
      %e0_256, %e1_257, %e2_258 = cute.get_leaves(%437) : !cute.coord<"(?,?,?)">
      %itup_259 = cute.to_int_tuple(%e0_256) : !cute.coord<"?"> to !cute.int_tuple<"?">
      %itup_260 = cute.to_int_tuple(%e1_257) : !cute.coord<"?"> to !cute.int_tuple<"?">
      %itup_261 = cute.to_int_tuple(%e2_258) : !cute.coord<"?"> to !cute.int_tuple<"?">
      %mul_262 = cute.tuple_mul(%itup_259, %29) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %438 = cute.get_scalars(%mul_262) : !cute.int_tuple<"?">
      %mul_263 = cute.tuple_mul(%itup_260, %29) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %439 = cute.get_scalars(%mul_263) : !cute.int_tuple<"?">
      %mul_264 = cute.tuple_mul(%itup_261, %29) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %440 = cute.get_scalars(%mul_264) : !cute.int_tuple<"?">
      cf.br ^bb118(%438, %439, %440, %436, %375, %376, %377, %429, %431, %433, %434, %435 : i32, i32, i32, i1, i32, i32, i32, i32, i32, i32, i32, i32)
    ^bb149:  // pred: ^bb118
      cf.cond_br %51, ^bb150, ^bb151
    ^bb150:  // pred: ^bb149
      cute_nvgpu.arch.sm100.relinquish_tmem_alloc_permit [ cta_1]
      cf.br ^bb151
    ^bb151:  // 2 preds: ^bb149, ^bb150
      nvvm.barrier id = %c2_i32 number_of_threads = %c128_i32
      cf.cond_br %51, ^bb152, ^bb153
    ^bb152:  // pred: ^bb151
      cute_nvgpu.arch.sm100.dealloc_tmem(%tmem_ptr_161, %c256_i32) [ cta_1] : !cute.ptr<f32, tmem, align<16>>, i32
      cf.br ^bb153
    ^bb153:  // 2 preds: ^bb151, ^bb152
      nvvm.cp.async.bulk.wait_group 0 {read}
      cf.br ^bb154
    ^bb154:  // 2 preds: ^bb114, ^bb153
      %441 = arith.cmpi eq, %49, %c6_i32 : i32
      cf.cond_br %441, ^bb155, ^bb177
    ^bb155:  // pred: ^bb154
      %442:3 = cute.get_scalars(%lay_64) <{only_dynamic}> : !cute.layout<"((128,128),1,1,?,?,?):((1@1,1@0),0,0,128@1,128@0,1@2)">
      %shape_265 = cute.make_shape(%442#0, %442#1, %442#2) : (i32, i32, i32) -> !cute.shape<"(128,128,?,?,?)">
      %lay_266 = cute.make_layout(%shape_265, %19) : !cute.layout<"(128,128,?,?,?):(1@1,1@0,128@1,128@0,1@2)">
      %443:3 = cute.get_scalars(%lay_266) <{only_dynamic}> : !cute.layout<"(128,128,?,?,?):(1@1,1@0,128@1,128@0,1@2)">
      %shape_267 = cute.make_shape(%443#0, %443#1, %443#2) : (i32, i32, i32) -> !cute.shape<"(128,16,1,8,?,?,?)">
      %lay_268 = cute.make_layout(%shape_267, %10) : !cute.layout<"(128,16,1,8,?,?,?):(1@1,1@0,0,16@0,128@1,128@0,1@2)">
      %444:3 = cute.get_scalars(%lay_268) <{only_dynamic}> : !cute.layout<"(128,16,1,8,?,?,?):(1@1,1@0,0,16@0,128@1,128@0,1@2)">
      %shape_269 = cute.make_shape(%444#0, %444#1, %444#2) : (i32, i32, i32) -> !cute.shape<"((128,16),1,8,?,?,?)">
      %lay_270 = cute.make_layout(%shape_269, %9) : !cute.layout<"((128,16),1,8,?,?,?):((1@1,1@0),0,16@0,128@1,128@0,1@2)">
      %445:3 = cute.get_scalars(%lay_270) <{only_dynamic}> : !cute.layout<"((128,16),1,8,?,?,?):((1@1,1@0),0,16@0,128@1,128@0,1@2)">
      %shape_271 = cute.make_shape(%445#0, %445#1, %445#2) : (i32, i32, i32) -> !cute.shape<"(((16,128),1),1,8,?,?,?)">
      %lay_272 = cute.make_layout(%shape_271, %8) : !cute.layout<"(((16,128),1),1,8,?,?,?):(((1@0,1@1),0),0,16@0,128@1,128@0,1@2)">
      %446 = nvvm.read.ptx.sreg.ctaid.z range <i32, 0, 65535> : i32
      %447 = nvvm.read.ptx.sreg.nctaid.x range <i32, 1, 2147483647> : i32
      %448 = nvvm.read.ptx.sreg.nctaid.y range <i32, 1, 65535> : i32
      %449 = nvvm.read.ptx.sreg.nctaid.z range <i32, 1, 65535> : i32
      %int_tuple_273 = cute.make_int_tuple(%447, %448, %449) : (i32, i32, i32) -> !cute.int_tuple<"(?,?,?)">
      %sz_274 = cute.size(%int_tuple_273) : (!cute.int_tuple<"(?,?,?)">) -> !cute.int_tuple<"?">
      %e0_275 = cute.get_leaves(%sz_274) : !cute.int_tuple<"?">
      %div_276 = cute.tuple_div(%e0_275, %29) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %450 = cute.get_scalars(%div_276) : !cute.int_tuple<"?">
      %sz_277 = cute.size(%lay) : (!cute.layout<"(?,?,?):(1,?,?)">) -> !cute.int_tuple<"?">
      %e0_278 = cute.get_leaves(%sz_277) : !cute.int_tuple<"?">
      %451 = cute.get_scalars(%e0_278) : !cute.int_tuple<"?">
      %452 = arith.cmpi sgt, %451, %446 : i32
      %453 = cute.get_hier_coord(%446, %lay) : (i32, !cute.layout<"(?,?,?):(1,?,?)">) -> !cute.coord<"(?,?,?)">
      %e0_279, %e1_280, %e2_281 = cute.get_leaves(%453) : !cute.coord<"(?,?,?)">
      %itup_282 = cute.to_int_tuple(%e0_279) : !cute.coord<"?"> to !cute.int_tuple<"?">
      %itup_283 = cute.to_int_tuple(%e1_280) : !cute.coord<"?"> to !cute.int_tuple<"?">
      %itup_284 = cute.to_int_tuple(%e2_281) : !cute.coord<"?"> to !cute.int_tuple<"?">
      %mul_285 = cute.tuple_mul(%itup_282, %29) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %454 = cute.get_scalars(%mul_285) : !cute.int_tuple<"?">
      %mul_286 = cute.tuple_mul(%itup_283, %29) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %455 = cute.get_scalars(%mul_286) : !cute.int_tuple<"?">
      %mul_287 = cute.tuple_mul(%itup_284, %29) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %456 = cute.get_scalars(%mul_287) : !cute.int_tuple<"?">
      %457 = cute_nvgpu.atom.make_exec_tma(%arg5) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f32, copy_bits = 65536, tma_gbasis = <"(16,128,1):(1@1,1@0,1@2)">, internal_val_type = f32>) -> !cute_nvgpu.atom.tma_load<f32, copy_bits = 65536, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(16,128,1):(1@1,1@0,1@2)">>
      %458 = cute.get_scalars(%29) : !cute.int_tuple<"1">
      cf.br ^bb156(%454, %455, %456, %452, %c0_i32, %c0_i32, %c1_i32, %446, %c0_i32 : i32, i32, i32, i1, i32, i32, i32, i32, i32)
    ^bb156(%459: i32, %460: i32, %461: i32, %462: i1, %463: i32, %464: i32, %465: i32, %466: i32, %467: i32):  // 2 preds: ^bb155, ^bb169
      cf.cond_br %462, ^bb157(%459, %460, %461, %463, %464, %465, %466, %467 : i32, i32, i32, i32, i32, i32, i32, i32), ^bb170
    ^bb157(%468: i32, %469: i32, %470: i32, %471: i32, %472: i32, %473: i32, %474: i32, %475: i32):  // pred: ^bb156
      %coord_288 = cute.make_coord(%468, %469, %470) : (i32, i32, i32) -> !cute.coord<"(_,_,_,?,?,?)">
      %idx_289 = cute.crd2idx(%coord_288, %lay_272) : (!cute.coord<"(_,_,_,?,?,?)">, !cute.layout<"(((16,128),1),1,8,?,?,?):(((1@0,1@1),0),0,16@0,128@1,128@0,1@2)">) -> !cute.int_tuple<"(?{div=128},?{div=128},?)">
      %tup_290 = cute.add_offset(%21, %idx_289) : (!cute.int_tuple<"(0,0,0)">, !cute.int_tuple<"(?{div=128},?{div=128},?)">) -> !cute.int_tuple<"(?{div=128},?{div=128},?)">
      cf.br ^bb158(%c0_i32, %471, %472, %473 : i32, i32, i32, i32)
    ^bb158(%476: i32, %477: i32, %478: i32, %479: i32):  // 2 preds: ^bb157, ^bb168
      %480 = arith.cmpi slt, %476, %c8_i32 : i32
      cf.cond_br %480, ^bb159, ^bb169
    ^bb159:  // pred: ^bb158
      %int_tuple_291 = cute.make_int_tuple(%478) : (i32) -> !cute.int_tuple<"?">
      %ptr_292 = cute.add_offset(%ptr_31, %int_tuple_291) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %481 = builtin.unrealized_conversion_cast %ptr_292 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %481, %479, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %482 = nvvm.elect.sync -> i1
      cf.cond_br %482, ^bb160, ^bb161
    ^bb160:  // pred: ^bb159
      %ptr_293 = cute.add_offset(%iter_29, %int_tuple_291) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %483 = builtin.unrealized_conversion_cast %ptr_293 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %483, %c8192_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
      cf.br ^bb161
    ^bb161:  // 2 preds: ^bb159, ^bb160
      %coord_294 = cute.make_coord(%476) : (i32) -> !cute.coord<"(_,?)">
      %idx_295 = cute.crd2idx(%coord_294, %1) : (!cute.coord<"(_,?)">, !cute.layout<"(((16,128),1),(1,8)):(((1@0,1@1),0),(0,16@0))">) -> !cute.int_tuple<"(?{div=16},0)">
      %tup_296 = cute.add_offset(%tup_290, %idx_295) : (!cute.int_tuple<"(?{div=128},?{div=128},?)">, !cute.int_tuple<"(?{div=16},0)">) -> !cute.int_tuple<"(?{div=16},?{div=128},?)">
      %e0_297, %e1_298, %e2_299 = cute.get_leaves(%tup_296) : !cute.int_tuple<"(?{div=16},?{div=128},?)">
      %coord_300 = cute.make_coord(%478) : (i32) -> !cute.coord<"(_,?)">
      %idx_301 = cute.crd2idx(%coord_300, %2) : (!cute.coord<"(_,?)">, !cute.layout<"((2048,1),(1,2)):((1,0),(0,2048))">) -> !cute.int_tuple<"?{div=2048}">
      %ptr_302 = cute.add_offset(%iter_34, %idx_301) : (!cute.ptr<f32, smem, align<1024>, S<2,4,3>>, !cute.int_tuple<"?{div=2048}">) -> !cute.ptr<f32, smem, align<1024>, S<2,4,3>>
      %ptr_303 = cute.add_offset(%iter_29, %int_tuple_291) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %int_tuple_304 = cute.make_int_tuple(%e0_297, %e1_298, %e2_299) : (!cute.int_tuple<"?{div=16}">, !cute.int_tuple<"?{div=128}">, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?{div=16},?{div=128},?)">
      %484 = cute_nvgpu.atom.set_value(%457, %ptr_303 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<f32, copy_bits = 65536, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(16,128,1):(1@1,1@0,1@2)">>
      %485 = cute_nvgpu.atom.get_value(%484 : !cute_nvgpu.atom.tma_load<f32, copy_bits = 65536, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(16,128,1):(1@1,1@0,1@2)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
      %TMADescAddr_305 = cute_nvgpu.get_tma_desc_addr(%484 : !cute_nvgpu.atom.tma_load<f32, copy_bits = 65536, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(16,128,1):(1@1,1@0,1@2)">>) -> !cute.ptr<generic, align<64>>
      %486:3 = cute.get_scalars(%int_tuple_304) : !cute.int_tuple<"(?{div=16},?{div=128},?)">
      cf.br ^bb162(%c0_i32 : i32)
    ^bb162(%487: i32):  // 2 preds: ^bb161, ^bb163
      %488 = arith.cmpi slt, %487, %458 : i32
      cf.cond_br %488, ^bb163, ^bb164 {llvm.loop_annotation = #loop_annotation1}
    ^bb163:  // pred: ^bb162
      cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr_305 : !cute.ptr<generic, align<64>>, %ptr_302 : !cute.ptr<f32, smem, align<1024>, S<2,4,3>>, %485 : !cute.ptr<smem, align<8>>, [%486#0, %486#1, %486#2] : i32, i32, i32) mode = <tiled> num_cta = 1 : i32
      %489 = arith.addi %487, %c1_i32 : i32
      cf.br ^bb162(%489 : i32)
    ^bb164:  // pred: ^bb162
      %490 = arith.addi %478, %c1_i32 : i32
      %491 = arith.addi %477, %c1_i32 : i32
      %492 = arith.cmpi eq, %490, %c2_i32 : i32
      %493 = arith.select %492, %c0_i32, %490 : i32
      cf.cond_br %492, ^bb165, ^bb166
    ^bb165:  // pred: ^bb164
      %494 = arith.xori %479, %c1_i32 : i32
      cf.br ^bb167(%494 : i32)
    ^bb166:  // pred: ^bb164
      cf.br ^bb167(%479 : i32)
    ^bb167(%495: i32):  // 2 preds: ^bb165, ^bb166
      cf.br ^bb168
    ^bb168:  // pred: ^bb167
      %496 = arith.addi %476, %c1_i32 : i32
      cf.br ^bb158(%496, %491, %493, %495 : i32, i32, i32, i32)
    ^bb169:  // pred: ^bb158
      %497 = arith.addi %474, %450 : i32
      %498 = arith.addi %475, %c1_i32 : i32
      %499 = arith.cmpi sgt, %451, %497 : i32
      %500 = cute.get_hier_coord(%497, %lay) : (i32, !cute.layout<"(?,?,?):(1,?,?)">) -> !cute.coord<"(?,?,?)">
      %e0_306, %e1_307, %e2_308 = cute.get_leaves(%500) : !cute.coord<"(?,?,?)">
      %itup_309 = cute.to_int_tuple(%e0_306) : !cute.coord<"?"> to !cute.int_tuple<"?">
      %itup_310 = cute.to_int_tuple(%e1_307) : !cute.coord<"?"> to !cute.int_tuple<"?">
      %itup_311 = cute.to_int_tuple(%e2_308) : !cute.coord<"?"> to !cute.int_tuple<"?">
      %mul_312 = cute.tuple_mul(%itup_309, %29) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %501 = cute.get_scalars(%mul_312) : !cute.int_tuple<"?">
      %mul_313 = cute.tuple_mul(%itup_310, %29) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %502 = cute.get_scalars(%mul_313) : !cute.int_tuple<"?">
      %mul_314 = cute.tuple_mul(%itup_311, %29) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %503 = cute.get_scalars(%mul_314) : !cute.int_tuple<"?">
      cf.br ^bb156(%501, %502, %503, %499, %477, %478, %479, %497, %498 : i32, i32, i32, i1, i32, i32, i32, i32, i32)
    ^bb170:  // pred: ^bb156
      %504 = arith.addi %464, %c1_i32 : i32
      %505 = arith.cmpi eq, %504, %c2_i32 : i32
      %506 = arith.select %505, %c0_i32, %504 : i32
      cf.cond_br %505, ^bb171, ^bb172
    ^bb171:  // pred: ^bb170
      %507 = arith.xori %465, %c1_i32 : i32
      cf.br ^bb173(%507 : i32)
    ^bb172:  // pred: ^bb170
      cf.br ^bb173(%465 : i32)
    ^bb173(%508: i32):  // 2 preds: ^bb171, ^bb172
      cf.br ^bb174
    ^bb174:  // pred: ^bb173
      %int_tuple_315 = cute.make_int_tuple(%506) : (i32) -> !cute.int_tuple<"?">
      %ptr_316 = cute.add_offset(%ptr_31, %int_tuple_315) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %509 = builtin.unrealized_conversion_cast %ptr_316 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %509, %508, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %510 = nvvm.elect.sync -> i1
      cf.cond_br %510, ^bb175, ^bb176
    ^bb175:  // pred: ^bb174
      %ptr_317 = cute.add_offset(%iter_29, %int_tuple_315) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %511 = builtin.unrealized_conversion_cast %ptr_317 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %511, %c8192_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
      cf.br ^bb176
    ^bb176:  // 2 preds: ^bb174, ^bb175
      cf.br ^bb177
    ^bb177:  // 2 preds: ^bb154, ^bb176
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
