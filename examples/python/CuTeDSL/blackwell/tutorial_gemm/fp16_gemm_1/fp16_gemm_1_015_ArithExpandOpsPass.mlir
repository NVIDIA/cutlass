!memref_gmem_f16_ = !cute.memref<f16, gmem, align<32>, "(?,?{div=8192}):(?{i64 div=8192},1)">
!memref_rmem_f16_ = !cute.memref<f16, rmem, align<32>, "((64,1),1):((1,0),0)">
!memref_rmem_f32_ = !cute.memref<f32, rmem, align<32>, "((64,1),1):((1,0),0)">
!mma_f16_f16_f32_256x256x16_ = !cute.tiled_mma<!cute_nvgpu.sm100.mma<256x256x16, num_cta = 2, ab_major = (k, k), elem_type = (f16, f16, f32), frag_kind = ss, c_scale_exp = 0>, atom_layout_MNK = <"(1,1,1):(0,0,0)">>
#loop_unroll = #llvm.loop_unroll<disable = false, full = true>
#loop_annotation = #llvm.loop_annotation<unroll = #loop_unroll>
module attributes {gpu.container_module} {
  gpu.module @kernels {
    cuda.kernel @kernel_cutlass_kernel_TiledMMA_ThrLayoutVMNK21111000_PermutationMNK____MMAAtom_ThrID21_ShapeMNK25625616_TVLayoutA2128161281256_TVLayoutB2128161281256_TVLayoutC21282561281256_CopyAtom_ThrI_0(%arg0: !mma_f16_f16_f32_256x256x16_, %arg1: !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_100_2sm_multicast, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, internal_val_type = f16>, %arg2: !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">, %arg3: !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_100_2sm_multicast, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, internal_val_type = f16>, %arg4: !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">, %arg5: !memref_gmem_f16_) attributes {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} {
      %0 = builtin.unrealized_conversion_cast %arg0 : !mma_f16_f16_f32_256x256x16_ to !llvm.struct<(i1, i1, i1)>
      %c127_i32 = arith.constant 127 : i32
      %1 = cute.static : !cute.layout<"(16,(4)):(1,(16))">
      %2 = cute.static : !cute.layout<"((64,1),1,((1,4),1,1)):((1,0),0,((0,64),0,0))">
      %3 = cute.static : !cute.layout<"(((64,32),1),1,((1,4),1,1)):(((1,65536),0),0,((0,64),0,0))">
      %c4_i32 = arith.constant 4 : i32
      %c3_i16 = arith.constant 3 : i16
      %c14_i32 = arith.constant 14 : i32
      %c13_i32 = arith.constant 13 : i32
      %c272629776_i32 = arith.constant 272629776 : i32
      %4 = cute.static : !cute.layout<"(1,1,4,7):(0,0,2,1024)">
      %5 = cute.static : !cute.layout<"((8192,1),7):((1,0),8192)">
      %c65536_i32 = arith.constant 65536 : i32
      %c5_i32 = arith.constant 5 : i32
      %c7_i32 = arith.constant 7 : i32
      %c10000000_i32 = arith.constant 10000000 : i32
      %true = arith.constant true
      %c32_i64 = arith.constant 32 : i64
      %c2097152_i32 = arith.constant 2097152 : i32
      %6 = cute.static : !cute.shape<"(((128,64)),((1,4),1,1))">
      %c512_i32 = arith.constant 512 : i32
      %7 = cute.static : !cute.stride<"(((1@0,1@1),0),64@0)">
      %8 = cute.static : !cute.stride<"(((1@1,1@0),0,16@0),64@0)">
      %9 = cute.static : !cute.shape<"((128,256),1,1)">
      %c128_i64 = arith.constant 128 : i64
      %10 = cute.static : !cute.stride<"((1@1,1@0),0,16@0,64@0)">
      %11 = cute.static : !cute.shape<"(256,256)">
      %c256_i64 = arith.constant 256 : i64
      %12 = cute.static : !cute.int_tuple<"(0,0)">
      %13 = cute.static : !cute.stride<"(1@1,1@0,64@0)">
      %14 = cute.static : !cute.stride<"((1@1,1@0),(256@1,64@0))">
      %c64_i32 = arith.constant 64 : i32
      %c256_i32 = arith.constant 256 : i32
      %15 = cute.static : !cute.int_tuple<"7">
      %16 = cute.static : !cute.int_tuple<"6">
      %17 = cute.static : !cute.int_tuple<"5">
      %18 = cute.static : !cute.int_tuple<"4">
      %19 = cute.static : !cute.int_tuple<"3">
      %20 = cute.static : !cute.int_tuple<"2">
      %21 = cute.static : !cute.int_tuple<"1">
      %c0_i32 = arith.constant 0 : i32
      %22 = cute.static : !cute.int_tuple<"114688">
      %c-128_i32 = arith.constant -128 : i32
      %c1_i32 = arith.constant 1 : i32
      %c128_i32 = arith.constant 128 : i32
      %23 = cute.static : !cute.int_tuple<"136">
      %24 = cute.static : !cute.int_tuple<"128">
      %25 = cute.static : !cute.int_tuple<"112">
      %26 = cute.static : !cute.int_tuple<"144">
      %c2_i32 = arith.constant 2 : i32
      %c32_i32 = arith.constant 32 : i32
      %27 = cute.static : !cute.layout<"((2),1,1,1):((1),0,0,0)">
      %28 = nvvm.read.ptx.sreg.tid.x range <i32, 0, 1024> : i32
      %29 = nvvm.read.ptx.sreg.tid.y range <i32, 0, 1024> : i32
      %30 = nvvm.read.ptx.sreg.tid.z range <i32, 0, 64> : i32
      %31 = nvvm.read.ptx.sreg.ntid.x range <i32, 1, 1024> : i32
      %32 = nvvm.read.ptx.sreg.ntid.y range <i32, 1, 1024> : i32
      %33 = arith.muli %29, %31 : i32
      %34 = arith.addi %28, %33 : i32
      %35 = arith.muli %30, %31 : i32
      %36 = arith.muli %35, %32 : i32
      %37 = arith.addi %34, %36 : i32
      %38 = arith.divsi %37, %c32_i32 : i32
      %39 = arith.muli %38, %c32_i32 : i32
      %40 = arith.cmpi ne, %37, %39 : i32
      %c0_i32_0 = arith.constant 0 : i32
      %41 = arith.cmpi slt, %37, %c0_i32_0 : i32
      %42 = arith.cmpi slt, %c32_i32, %c0_i32_0 : i32
      %43 = arith.cmpi ne, %41, %42 : i1
      %44 = arith.andi %40, %43 : i1
      %c-1_i32 = arith.constant -1 : i32
      %45 = arith.addi %38, %c-1_i32 : i32
      %46 = arith.select %44, %45, %38 : i32
      %47 = cute_nvgpu.arch.make_warp_uniform(%46) : i32
      %48 = nvvm.read.ptx.sreg.ctaid.x range <i32, 0, 2147483647> : i32
      %49 = nvvm.read.ptx.sreg.ctaid.y range <i32, 0, 65535> : i32
      %50 = nvvm.read.ptx.sreg.cluster.ctarank : i32
      %51 = cute.get_flat_coord(%50, %27) : (i32, !cute.layout<"((2),1,1,1):((1),0,0,0)">) -> !cute.coord<"(?,0,0,0)">
      %e0, %e1, %e2, %e3 = cute.get_leaves(%51) : !cute.coord<"(?,0,0,0)">
      %itup = cute.to_int_tuple(%e0) : !cute.coord<"?"> to !cute.int_tuple<"?">
      %52 = arith.remsi %48, %c2_i32 : i32
      %53 = arith.divsi %48, %c2_i32 : i32
      %54 = arith.muli %53, %c2_i32 : i32
      %55 = arith.cmpi ne, %48, %54 : i32
      %c0_i32_1 = arith.constant 0 : i32
      %56 = arith.cmpi slt, %48, %c0_i32_1 : i32
      %57 = arith.cmpi slt, %c2_i32, %c0_i32_1 : i32
      %58 = arith.cmpi ne, %56, %57 : i1
      %59 = arith.andi %55, %58 : i1
      %c-1_i32_2 = arith.constant -1 : i32
      %60 = arith.addi %53, %c-1_i32_2 : i32
      %61 = arith.select %59, %60, %53 : i32
      %smem_ptr = cute_nvgpu.arch.get_dyn_smem() : !cute.ptr<i8, smem, align<1024>>
      %ptr = cute.add_offset(%smem_ptr, %26) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"144">) -> !cute.ptr<i8, smem, align<16>>
      %ptr_3 = cute.add_offset(%smem_ptr, %25) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"112">) -> !cute.ptr<i8, smem, align<16>>
      %ptr_4 = cute.add_offset(%smem_ptr, %24) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"128">) -> !cute.ptr<i8, smem, align<128>>
      %iter = cute.recast_iter(%ptr_4) : !cute.ptr<i8, smem, align<128>> to !cute.ptr<i64, smem, align<128>>
      %ptr_5 = cute.add_offset(%smem_ptr, %23) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"136">) -> !cute.ptr<i8, smem, align<8>>
      %iter_6 = cute.recast_iter(%ptr_5) : !cute.ptr<i8, smem, align<8>> to !cute.ptr<i32, smem, align<8>>
      %62 = cute.ptrtoint(%ptr) : !cute.ptr<i8, smem, align<16>> to i32
      %63 = arith.addi %62, %c127_i32 : i32
      %64 = arith.andi %63, %c-128_i32 : i32
      %65 = arith.extsi %64 : i32 to i64
      %iv = cute.assume(%65) : (i64) -> !cute.i64<divby 128>
      %66 = cute.inttoptr(%iv) : !cute.i64<divby 128> to !cute.ptr<i8, smem, align<128>>
      %ptr_7 = cute.add_offset(%66, %22) : (!cute.ptr<i8, smem, align<128>>, !cute.int_tuple<"114688">) -> !cute.ptr<i8, smem, align<128>>
      %iter_8 = cute.recast_iter(%66) : !cute.ptr<i8, smem, align<128>> to !cute.ptr<f16, smem, align<128>, S<3,4,3>>
      %iter_9 = cute.recast_iter(%ptr_7) : !cute.ptr<i8, smem, align<128>> to !cute.ptr<f16, smem, align<128>, S<3,4,3>>
      %67 = arith.cmpi eq, %47, %c0_i32 : i32
      cf.cond_br %67, ^bb1, ^bb2
    ^bb1:  // pred: ^bb0
      cute_nvgpu.prefetch_tma_desc(%arg1) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_100_2sm_multicast, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, internal_val_type = f16>) -> ()
      cute_nvgpu.prefetch_tma_desc(%arg3) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_100_2sm_multicast, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, internal_val_type = f16>) -> ()
      cf.br ^bb2
    ^bb2:  // 2 preds: ^bb0, ^bb1
      %iter_10 = cute.recast_iter(%smem_ptr) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<i64, smem, align<1024>>
      cf.cond_br %67, ^bb3, ^bb4
    ^bb3:  // pred: ^bb2
      %68 = builtin.unrealized_conversion_cast %iter_10 : !cute.ptr<i64, smem, align<1024>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %68, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_11 = cute.add_offset(%iter_10, %21) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"1">) -> !cute.ptr<i64, smem>
      %69 = builtin.unrealized_conversion_cast %ptr_11 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %69, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_12 = cute.add_offset(%iter_10, %20) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"2">) -> !cute.ptr<i64, smem, align<16>>
      %70 = builtin.unrealized_conversion_cast %ptr_12 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %70, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_13 = cute.add_offset(%iter_10, %19) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"3">) -> !cute.ptr<i64, smem>
      %71 = builtin.unrealized_conversion_cast %ptr_13 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %71, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_14 = cute.add_offset(%iter_10, %18) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"4">) -> !cute.ptr<i64, smem, align<32>>
      %72 = builtin.unrealized_conversion_cast %ptr_14 : !cute.ptr<i64, smem, align<32>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %72, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_15 = cute.add_offset(%iter_10, %17) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"5">) -> !cute.ptr<i64, smem>
      %73 = builtin.unrealized_conversion_cast %ptr_15 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %73, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_16 = cute.add_offset(%iter_10, %16) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"6">) -> !cute.ptr<i64, smem, align<16>>
      %74 = builtin.unrealized_conversion_cast %ptr_16 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %74, %c1_i32 : !llvm.ptr<3>, i32
      cf.br ^bb4
    ^bb4:  // 2 preds: ^bb2, ^bb3
      %ptr_17 = cute.add_offset(%iter_10, %15) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"7">) -> !cute.ptr<i64, smem>
      cf.cond_br %67, ^bb5, ^bb6
    ^bb5:  // pred: ^bb4
      %75 = builtin.unrealized_conversion_cast %ptr_17 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %75, %c1_i32 : !llvm.ptr<3>, i32
      %int_tuple = cute.make_int_tuple() : () -> !cute.int_tuple<"8">
      %ptr_18 = cute.add_offset(%iter_10, %int_tuple) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"8">) -> !cute.ptr<i64, smem, align<64>>
      %dyn = cute.derefine(%ptr_18) : !cute.ptr<i64, smem, align<64>> to !cute.ptr<i64, smem>
      %76 = builtin.unrealized_conversion_cast %dyn : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %76, %c1_i32 : !llvm.ptr<3>, i32
      %int_tuple_19 = cute.make_int_tuple() : () -> !cute.int_tuple<"9">
      %ptr_20 = cute.add_offset(%iter_10, %int_tuple_19) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"9">) -> !cute.ptr<i64, smem>
      %77 = builtin.unrealized_conversion_cast %ptr_20 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %77, %c1_i32 : !llvm.ptr<3>, i32
      %int_tuple_21 = cute.make_int_tuple() : () -> !cute.int_tuple<"10">
      %ptr_22 = cute.add_offset(%iter_10, %int_tuple_21) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"10">) -> !cute.ptr<i64, smem, align<16>>
      %dyn_23 = cute.derefine(%ptr_22) : !cute.ptr<i64, smem, align<16>> to !cute.ptr<i64, smem>
      %78 = builtin.unrealized_conversion_cast %dyn_23 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %78, %c1_i32 : !llvm.ptr<3>, i32
      %int_tuple_24 = cute.make_int_tuple() : () -> !cute.int_tuple<"11">
      %ptr_25 = cute.add_offset(%iter_10, %int_tuple_24) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"11">) -> !cute.ptr<i64, smem>
      %79 = builtin.unrealized_conversion_cast %ptr_25 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %79, %c1_i32 : !llvm.ptr<3>, i32
      %int_tuple_26 = cute.make_int_tuple() : () -> !cute.int_tuple<"12">
      %ptr_27 = cute.add_offset(%iter_10, %int_tuple_26) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"12">) -> !cute.ptr<i64, smem, align<32>>
      %dyn_28 = cute.derefine(%ptr_27) : !cute.ptr<i64, smem, align<32>> to !cute.ptr<i64, smem>
      %80 = builtin.unrealized_conversion_cast %dyn_28 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %80, %c1_i32 : !llvm.ptr<3>, i32
      %int_tuple_29 = cute.make_int_tuple() : () -> !cute.int_tuple<"13">
      %ptr_30 = cute.add_offset(%iter_10, %int_tuple_29) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"13">) -> !cute.ptr<i64, smem>
      %81 = builtin.unrealized_conversion_cast %ptr_30 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %81, %c1_i32 : !llvm.ptr<3>, i32
      cf.br ^bb6
    ^bb6:  // 2 preds: ^bb4, ^bb5
      %82 = cute_nvgpu.arch.make_warp_uniform(%50) : i32
      %83 = cute.get_flat_coord(%82, %27) : (i32, !cute.layout<"((2),1,1,1):((1),0,0,0)">) -> !cute.coord<"(?,0,0,0)">
      %e0_31, %e1_32, %e2_33, %e3_34 = cute.get_leaves(%83) : !cute.coord<"(?,0,0,0)">
      %itup_35 = cute.to_int_tuple(%e0_31) : !cute.coord<"?"> to !cute.int_tuple<"?">
      %84 = cute.get_scalars(%itup_35) : !cute.int_tuple<"?">
      %coord = cute.make_coord(%itup_35) : (!cute.int_tuple<"?">) -> !cute.coord<"(?,0,_,0)">
      %idx = cute.crd2idx(%coord, %27) : (!cute.coord<"(?,0,_,0)">, !cute.layout<"((2),1,1,1):((1),0,0,0)">) -> !cute.int_tuple<"?">
      %e0_36 = cute.get_leaves(%idx) : !cute.int_tuple<"?">
      %85 = cute.get_scalars(%e0_36) : !cute.int_tuple<"?">
      %86 = arith.shli %c1_i32, %85 : i32
      %87 = arith.trunci %86 : i32 to i16
      %coord_37 = cute.make_coord(%itup_35) : (!cute.int_tuple<"?">) -> !cute.coord<"(?,_,0,0)">
      %idx_38 = cute.crd2idx(%coord_37, %27) : (!cute.coord<"(?,_,0,0)">, !cute.layout<"((2),1,1,1):((1),0,0,0)">) -> !cute.int_tuple<"?">
      %e0_39 = cute.get_leaves(%idx_38) : !cute.int_tuple<"?">
      %88 = cute.get_scalars(%e0_39) : !cute.int_tuple<"?">
      %89 = arith.shli %c1_i32, %88 : i32
      %90 = arith.trunci %89 : i32 to i16
      %91 = arith.xori %84, %c1_i32 : i32
      %coord_40 = cute.make_coord(%91) : (i32) -> !cute.coord<"(?,0,_,0)">
      %idx_41 = cute.crd2idx(%coord_40, %27) : (!cute.coord<"(?,0,_,0)">, !cute.layout<"((2),1,1,1):((1),0,0,0)">) -> !cute.int_tuple<"?">
      %e0_42 = cute.get_leaves(%idx_41) : !cute.int_tuple<"?">
      %92 = cute.get_scalars(%e0_42) : !cute.int_tuple<"?">
      %93 = arith.shli %c1_i32, %92 : i32
      %94 = arith.trunci %93 : i32 to i16
      %coord_43 = cute.make_coord(%91) : (i32) -> !cute.coord<"(?,_,0,0)">
      %idx_44 = cute.crd2idx(%coord_43, %27) : (!cute.coord<"(?,_,0,0)">, !cute.layout<"((2),1,1,1):((1),0,0,0)">) -> !cute.int_tuple<"?">
      %e0_45 = cute.get_leaves(%idx_44) : !cute.int_tuple<"?">
      %95 = cute.get_scalars(%e0_45) : !cute.int_tuple<"?">
      %96 = arith.shli %c1_i32, %95 : i32
      %97 = arith.trunci %96 : i32 to i16
      %98 = arith.ori %87, %90 : i16
      %99 = arith.ori %98, %94 : i16
      %100 = arith.ori %99, %97 : i16
      %101 = arith.cmpi eq, %52, %c0_i32 : i32
      nvvm.fence.mbarrier.init
      nvvm.cluster.arrive.relaxed
      nvvm.cluster.wait
      %iter_46 = cute.recast_iter(%ptr_3) : !cute.ptr<i8, smem, align<16>> to !cute.ptr<i64, smem, align<16>>
      cf.cond_br %67, ^bb7, ^bb8
    ^bb7:  // pred: ^bb6
      %102 = builtin.unrealized_conversion_cast %iter_46 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %102, %c1_i32 : !llvm.ptr<3>, i32
      cf.br ^bb8
    ^bb8:  // 2 preds: ^bb6, ^bb7
      %ptr_47 = cute.add_offset(%iter_46, %21) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"1">) -> !cute.ptr<i64, smem>
      cf.cond_br %67, ^bb9, ^bb10
    ^bb9:  // pred: ^bb8
      %103 = builtin.unrealized_conversion_cast %ptr_47 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %103, %c256_i32 : !llvm.ptr<3>, i32
      cf.br ^bb10
    ^bb10:  // 2 preds: ^bb8, ^bb9
      %104 = arith.divsi %82, %c2_i32 : i32
      %105 = arith.muli %104, %c2_i32 : i32
      %106 = arith.cmpi ne, %82, %105 : i32
      %c0_i32_48 = arith.constant 0 : i32
      %107 = arith.cmpi slt, %82, %c0_i32_48 : i32
      %108 = arith.cmpi slt, %c2_i32, %c0_i32_48 : i32
      %109 = arith.cmpi ne, %107, %108 : i1
      %110 = arith.andi %106, %109 : i1
      %c-1_i32_49 = arith.constant -1 : i32
      %111 = arith.addi %104, %c-1_i32_49 : i32
      %112 = arith.select %110, %111, %104 : i32
      %113 = arith.muli %112, %c2_i32 : i32
      nvvm.fence.mbarrier.init
      nvvm.cluster.arrive.relaxed
      nvvm.cluster.wait
      %coord_50 = cute.make_coord(%61, %49) : (i32, i32) -> !cute.coord<"(?,?,_)">
      %114:2 = cute.get_scalars(%coord_50) <{only_dynamic}> : !cute.coord<"(?,?,_)">
      %coord_51 = cute.make_coord(%114#0) : (i32) -> !cute.coord<"((_,_),(?,_))">
      %lay = cute.get_layout(%arg2) : !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">
      %115:2 = cute.get_scalars(%lay) <{only_dynamic}> : !cute.layout<"(?,?{div=8192}):(1@1,1@0)">
      %c1_i32_52 = arith.constant 1 : i32
      %c0_i32_53 = arith.constant 0 : i32
      %c-1_i32_54 = arith.constant -1 : i32
      %116 = arith.cmpi sgt, %c256_i32, %c0_i32_53 : i32
      %117 = arith.select %116, %c-1_i32_54, %c1_i32_52 : i32
      %118 = arith.addi %117, %115#0 : i32
      %119 = arith.divsi %118, %c256_i32 : i32
      %120 = arith.addi %c1_i32_52, %119 : i32
      %121 = arith.subi %c0_i32_53, %115#0 : i32
      %122 = arith.divsi %121, %c256_i32 : i32
      %123 = arith.subi %c0_i32_53, %122 : i32
      %124 = arith.cmpi slt, %115#0, %c0_i32_53 : i32
      %125 = arith.cmpi sgt, %115#0, %c0_i32_53 : i32
      %126 = arith.cmpi slt, %c256_i32, %c0_i32_53 : i32
      %127 = arith.cmpi sgt, %c256_i32, %c0_i32_53 : i32
      %128 = arith.andi %124, %126 : i1
      %129 = arith.andi %125, %127 : i1
      %130 = arith.ori %128, %129 : i1
      %131 = arith.select %130, %120, %123 : i32
      %c1_i32_55 = arith.constant 1 : i32
      %c0_i32_56 = arith.constant 0 : i32
      %c-1_i32_57 = arith.constant -1 : i32
      %132 = arith.cmpi sgt, %c64_i32, %c0_i32_56 : i32
      %133 = arith.select %132, %c-1_i32_57, %c1_i32_55 : i32
      %134 = arith.addi %133, %115#1 : i32
      %135 = arith.divsi %134, %c64_i32 : i32
      %136 = arith.addi %c1_i32_55, %135 : i32
      %137 = arith.subi %c0_i32_56, %115#1 : i32
      %138 = arith.divsi %137, %c64_i32 : i32
      %139 = arith.subi %c0_i32_56, %138 : i32
      %140 = arith.cmpi slt, %115#1, %c0_i32_56 : i32
      %141 = arith.cmpi sgt, %115#1, %c0_i32_56 : i32
      %142 = arith.cmpi slt, %c64_i32, %c0_i32_56 : i32
      %143 = arith.cmpi sgt, %c64_i32, %c0_i32_56 : i32
      %144 = arith.andi %140, %142 : i1
      %145 = arith.andi %141, %143 : i1
      %146 = arith.ori %144, %145 : i1
      %147 = arith.select %146, %136, %139 : i32
      %shape = cute.make_shape(%131, %147) : (i32, i32) -> !cute.shape<"((256,64),(?,?))">
      %lay_58 = cute.make_layout(%shape, %14) : !cute.layout<"((256,64),(?,?)):((1@1,1@0),(256@1,64@0))">
      %148:2 = cute.get_scalars(%lay_58) <{only_dynamic}> : !cute.layout<"((256,64),(?,?)):((1@1,1@0),(256@1,64@0))">
      %shape_59 = cute.make_shape(%148#1) : (i32) -> !cute.shape<"(256,64,?)">
      %lay_60 = cute.make_layout(%shape_59, %13) : !cute.layout<"(256,64,?):(1@1,1@0,64@0)">
      %idx_61 = cute.crd2idx(%coord_51, %lay_58) : (!cute.coord<"((_,_),(?,_))">, !cute.layout<"((256,64),(?,?)):((1@1,1@0),(256@1,64@0))">) -> !cute.int_tuple<"(0,?{div=256})">
      %tup = cute.add_offset(%12, %idx_61) : (!cute.int_tuple<"(0,0)">, !cute.int_tuple<"(0,?{div=256})">) -> !cute.int_tuple<"(0,?{div=256})">
      %coord_62 = cute.make_coord(%114#1) : (i32) -> !cute.coord<"((_,_),(?,_))">
      %lay_63 = cute.get_layout(%arg4) : !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">
      %149:2 = cute.get_scalars(%lay_63) <{only_dynamic}> : !cute.layout<"(?,?{div=8192}):(1@1,1@0)">
      %c1_i32_64 = arith.constant 1 : i32
      %c0_i32_65 = arith.constant 0 : i32
      %c-1_i32_66 = arith.constant -1 : i32
      %150 = arith.cmpi sgt, %c256_i32, %c0_i32_65 : i32
      %151 = arith.select %150, %c-1_i32_66, %c1_i32_64 : i32
      %152 = arith.addi %151, %149#0 : i32
      %153 = arith.divsi %152, %c256_i32 : i32
      %154 = arith.addi %c1_i32_64, %153 : i32
      %155 = arith.subi %c0_i32_65, %149#0 : i32
      %156 = arith.divsi %155, %c256_i32 : i32
      %157 = arith.subi %c0_i32_65, %156 : i32
      %158 = arith.cmpi slt, %149#0, %c0_i32_65 : i32
      %159 = arith.cmpi sgt, %149#0, %c0_i32_65 : i32
      %160 = arith.cmpi slt, %c256_i32, %c0_i32_65 : i32
      %161 = arith.cmpi sgt, %c256_i32, %c0_i32_65 : i32
      %162 = arith.andi %158, %160 : i1
      %163 = arith.andi %159, %161 : i1
      %164 = arith.ori %162, %163 : i1
      %165 = arith.select %164, %154, %157 : i32
      %c1_i32_67 = arith.constant 1 : i32
      %c0_i32_68 = arith.constant 0 : i32
      %c-1_i32_69 = arith.constant -1 : i32
      %166 = arith.cmpi sgt, %c64_i32, %c0_i32_68 : i32
      %167 = arith.select %166, %c-1_i32_69, %c1_i32_67 : i32
      %168 = arith.addi %167, %149#1 : i32
      %169 = arith.divsi %168, %c64_i32 : i32
      %170 = arith.addi %c1_i32_67, %169 : i32
      %171 = arith.subi %c0_i32_68, %149#1 : i32
      %172 = arith.divsi %171, %c64_i32 : i32
      %173 = arith.subi %c0_i32_68, %172 : i32
      %174 = arith.cmpi slt, %149#1, %c0_i32_68 : i32
      %175 = arith.cmpi sgt, %149#1, %c0_i32_68 : i32
      %176 = arith.cmpi slt, %c64_i32, %c0_i32_68 : i32
      %177 = arith.cmpi sgt, %c64_i32, %c0_i32_68 : i32
      %178 = arith.andi %174, %176 : i1
      %179 = arith.andi %175, %177 : i1
      %180 = arith.ori %178, %179 : i1
      %181 = arith.select %180, %170, %173 : i32
      %shape_70 = cute.make_shape(%165, %181) : (i32, i32) -> !cute.shape<"((256,64),(?,?))">
      %lay_71 = cute.make_layout(%shape_70, %14) : !cute.layout<"((256,64),(?,?)):((1@1,1@0),(256@1,64@0))">
      %182:2 = cute.get_scalars(%lay_71) <{only_dynamic}> : !cute.layout<"((256,64),(?,?)):((1@1,1@0),(256@1,64@0))">
      %shape_72 = cute.make_shape(%182#1) : (i32) -> !cute.shape<"(256,64,?)">
      %lay_73 = cute.make_layout(%shape_72, %13) : !cute.layout<"(256,64,?):(1@1,1@0,64@0)">
      %idx_74 = cute.crd2idx(%coord_62, %lay_71) : (!cute.coord<"((_,_),(?,_))">, !cute.layout<"((256,64),(?,?)):((1@1,1@0),(256@1,64@0))">) -> !cute.int_tuple<"(0,?{div=256})">
      %tup_75 = cute.add_offset(%12, %idx_74) : (!cute.int_tuple<"(0,0)">, !cute.int_tuple<"(0,?{div=256})">) -> !cute.int_tuple<"(0,?{div=256})">
      %coord_76 = cute.make_coord(%114#0, %114#1) : (i32, i32) -> !cute.coord<"((_,_),(?,?))">
      %lay_77 = cute.get_layout(%arg5) : !memref_gmem_f16_
      %183:3 = cute.get_scalars(%lay_77) <{only_dynamic}> : !cute.layout<"(?,?{div=8192}):(?{i64 div=8192},1)">
      %c1_i32_78 = arith.constant 1 : i32
      %c0_i32_79 = arith.constant 0 : i32
      %c-1_i32_80 = arith.constant -1 : i32
      %184 = arith.cmpi sgt, %c256_i32, %c0_i32_79 : i32
      %185 = arith.select %184, %c-1_i32_80, %c1_i32_78 : i32
      %186 = arith.addi %185, %183#0 : i32
      %187 = arith.divsi %186, %c256_i32 : i32
      %188 = arith.addi %c1_i32_78, %187 : i32
      %189 = arith.subi %c0_i32_79, %183#0 : i32
      %190 = arith.divsi %189, %c256_i32 : i32
      %191 = arith.subi %c0_i32_79, %190 : i32
      %192 = arith.cmpi slt, %183#0, %c0_i32_79 : i32
      %193 = arith.cmpi sgt, %183#0, %c0_i32_79 : i32
      %194 = arith.cmpi slt, %c256_i32, %c0_i32_79 : i32
      %195 = arith.cmpi sgt, %c256_i32, %c0_i32_79 : i32
      %196 = arith.andi %192, %194 : i1
      %197 = arith.andi %193, %195 : i1
      %198 = arith.ori %196, %197 : i1
      %199 = arith.select %198, %188, %191 : i32
      %200 = arith.muli %183#2, %c256_i64 : i64
      %c1_i32_81 = arith.constant 1 : i32
      %c0_i32_82 = arith.constant 0 : i32
      %c-1_i32_83 = arith.constant -1 : i32
      %201 = arith.cmpi sgt, %c256_i32, %c0_i32_82 : i32
      %202 = arith.select %201, %c-1_i32_83, %c1_i32_81 : i32
      %203 = arith.addi %202, %183#1 : i32
      %204 = arith.divsi %203, %c256_i32 : i32
      %205 = arith.addi %c1_i32_81, %204 : i32
      %206 = arith.subi %c0_i32_82, %183#1 : i32
      %207 = arith.divsi %206, %c256_i32 : i32
      %208 = arith.subi %c0_i32_82, %207 : i32
      %209 = arith.cmpi slt, %183#1, %c0_i32_82 : i32
      %210 = arith.cmpi sgt, %183#1, %c0_i32_82 : i32
      %211 = arith.cmpi slt, %c256_i32, %c0_i32_82 : i32
      %212 = arith.cmpi sgt, %c256_i32, %c0_i32_82 : i32
      %213 = arith.andi %209, %211 : i1
      %214 = arith.andi %210, %212 : i1
      %215 = arith.ori %213, %214 : i1
      %216 = arith.select %215, %205, %208 : i32
      %shape_84 = cute.make_shape(%199, %216) : (i32, i32) -> !cute.shape<"((256,256),(?,?))">
      %iv_85 = cute.assume(%183#2) : (i64) -> !cute.i64<divby 8192>
      %iv_86 = cute.assume(%200) : (i64) -> !cute.i64<divby 2097152>
      %stride = cute.make_stride(%iv_85, %iv_86) : (!cute.i64<divby 8192>, !cute.i64<divby 2097152>) -> !cute.stride<"((?{i64 div=8192},1),(?{i64 div=2097152},256))">
      %lay_87 = cute.make_layout(%shape_84, %stride) : !cute.layout<"((256,256),(?,?)):((?{i64 div=8192},1),(?{i64 div=2097152},256))">
      %217:4 = cute.get_scalars(%lay_87) <{only_dynamic}> : !cute.layout<"((256,256),(?,?)):((?{i64 div=8192},1),(?{i64 div=2097152},256))">
      %iv_88 = cute.assume(%217#2) : (i64) -> !cute.i64<divby 8192>
      %stride_89 = cute.make_stride(%iv_88) : (!cute.i64<divby 8192>) -> !cute.stride<"(?{i64 div=8192},1)">
      %lay_90 = cute.make_layout(%11, %stride_89) : !cute.layout<"(256,256):(?{i64 div=8192},1)">
      %idx_91 = cute.crd2idx(%coord_76, %lay_87) : (!cute.coord<"((_,_),(?,?))">, !cute.layout<"((256,256),(?,?)):((?{i64 div=8192},1),(?{i64 div=2097152},256))">) -> !cute.int_tuple<"?{i64 div=256}">
      %iter_92 = cute.get_iter(%arg5) : !memref_gmem_f16_
      %ptr_93 = cute.add_offset(%iter_92, %idx_91) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{i64 div=256}">) -> !cute.ptr<f16, gmem, align<32>>
      %coord_94 = cute.make_coord(%52) : (i32) -> !cute.coord<"?">
      %218 = cute.get_scalars(%lay_60) <{only_dynamic}> : !cute.layout<"(256,64,?):(1@1,1@0,64@0)">
      %219 = cute.get_scalars(%coord_94) <{only_dynamic}> : !cute.coord<"?">
      %220 = arith.remsi %219, %c2_i32 : i32
      %221 = arith.remsi %220, %c2_i32 : i32
      %222 = arith.muli %221, %c128_i32 : i32
      %iv_95 = cute.assume(%222) : (i32) -> !cute.i32<divby 128>
      %int_tuple_96 = cute.make_int_tuple(%iv_95) : (!cute.i32<divby 128>) -> !cute.int_tuple<"(0,?{div=128})">
      %tup_97 = cute.add_offset(%tup, %int_tuple_96) : (!cute.int_tuple<"(0,?{div=256})">, !cute.int_tuple<"(0,?{div=128})">) -> !cute.int_tuple<"(0,?{div=128})">
      %shape_98 = cute.make_shape(%218) : (i32) -> !cute.shape<"((128,16),1,4,?)">
      %lay_99 = cute.make_layout(%shape_98, %10) : !cute.layout<"((128,16),1,4,?):((1@1,1@0),0,16@0,64@0)">
      %223 = cute.get_scalars(%lay_73) <{only_dynamic}> : !cute.layout<"(256,64,?):(1@1,1@0,64@0)">
      %tup_100 = cute.add_offset(%tup_75, %int_tuple_96) : (!cute.int_tuple<"(0,?{div=256})">, !cute.int_tuple<"(0,?{div=128})">) -> !cute.int_tuple<"(0,?{div=128})">
      %shape_101 = cute.make_shape(%223) : (i32) -> !cute.shape<"((128,16),1,4,?)">
      %lay_102 = cute.make_layout(%shape_101, %10) : !cute.layout<"((128,16),1,4,?):((1@1,1@0),0,16@0,64@0)">
      %224 = cute.get_scalars(%lay_90) <{only_dynamic}> : !cute.layout<"(256,256):(?{i64 div=8192},1)">
      %225 = arith.muli %224, %c128_i64 : i64
      %226 = arith.extsi %221 : i32 to i64
      %227 = arith.muli %226, %225 : i64
      %iv_103 = cute.assume(%227) : (i64) -> !cute.i64<divby 1048576>
      %int_tuple_104 = cute.make_int_tuple(%iv_103) : (!cute.i64<divby 1048576>) -> !cute.int_tuple<"?{i64 div=1048576}">
      %ptr_105 = cute.add_offset(%ptr_93, %int_tuple_104) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{i64 div=1048576}">) -> !cute.ptr<f16, gmem, align<32>>
      %iv_106 = cute.assume(%224) : (i64) -> !cute.i64<divby 8192>
      %stride_107 = cute.make_stride(%iv_106) : (!cute.i64<divby 8192>) -> !cute.stride<"((?{i64 div=8192},1),0,0)">
      %lay_108 = cute.make_layout(%9, %stride_107) : !cute.layout<"((128,256),1,1):((?{i64 div=8192},1),0,0)">
      %ummaSmemDesc = cute_nvgpu.make_umma_smem_desc(%iter_8 : !cute.ptr<f16, smem, align<128>, S<3,4,3>>) layout = <"((128,16),1,4,7):((64,1),0,16,8192)">, major = <k> -> !cute_nvgpu.smem_desc
      %ummaSmemDesc_109 = cute_nvgpu.make_umma_smem_desc(%iter_9 : !cute.ptr<f16, smem, align<128>, S<3,4,3>>) layout = <"((128,16),1,4,7):((64,1),0,16,8192)">, major = <k> -> !cute_nvgpu.smem_desc
      %228 = cute.get_scalars(%lay_99) <{only_dynamic}> : !cute.layout<"((128,16),1,4,?):((1@1,1@0),0,16@0,64@0)">
      %shape_110 = cute.make_shape(%228) : (i32) -> !cute.shape<"(((128,16),1,4),?)">
      %lay_111 = cute.make_layout(%shape_110, %8) : !cute.layout<"(((128,16),1,4),?):(((1@1,1@0),0,16@0),64@0)">
      %229 = cute.get_scalars(%lay_111) <{only_dynamic}> : !cute.layout<"(((128,16),1,4),?):(((1@1,1@0),0,16@0),64@0)">
      %shape_112 = cute.make_shape(%229) : (i32) -> !cute.shape<"(((64,128),1),?)">
      %lay_113 = cute.make_layout(%shape_112, %7) : !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">
      %230 = cute.get_scalars(%lay_102) <{only_dynamic}> : !cute.layout<"((128,16),1,4,?):((1@1,1@0),0,16@0,64@0)">
      %shape_114 = cute.make_shape(%230) : (i32) -> !cute.shape<"(((128,16),1,4),?)">
      %lay_115 = cute.make_layout(%shape_114, %8) : !cute.layout<"(((128,16),1,4),?):(((1@1,1@0),0,16@0),64@0)">
      %231 = cute.get_scalars(%lay_115) <{only_dynamic}> : !cute.layout<"(((128,16),1,4),?):(((1@1,1@0),0,16@0),64@0)">
      %shape_116 = cute.make_shape(%231) : (i32) -> !cute.shape<"(((64,128),1),?)">
      %lay_117 = cute.make_layout(%shape_116, %7) : !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">
      %coord_118 = cute.make_coord(%itup) : (!cute.int_tuple<"?">) -> !cute.coord<"(?,0,_,0)">
      %idx_119 = cute.crd2idx(%coord_118, %27) : (!cute.coord<"(?,0,_,0)">, !cute.layout<"((2),1,1,1):((1),0,0,0)">) -> !cute.int_tuple<"?">
      %e0_120 = cute.get_leaves(%idx_119) : !cute.int_tuple<"?">
      %232 = cute.get_scalars(%e0_120) : !cute.int_tuple<"?">
      %233 = arith.shli %c1_i32, %232 : i32
      %234 = arith.trunci %233 : i32 to i16
      %coord_121 = cute.make_coord(%itup) : (!cute.int_tuple<"?">) -> !cute.coord<"(?,_,0,0)">
      %idx_122 = cute.crd2idx(%coord_121, %27) : (!cute.coord<"(?,_,0,0)">, !cute.layout<"((2),1,1,1):((1),0,0,0)">) -> !cute.int_tuple<"?">
      %e0_123 = cute.get_leaves(%idx_122) : !cute.int_tuple<"?">
      %235 = cute.get_scalars(%e0_123) : !cute.int_tuple<"?">
      %236 = arith.shli %c1_i32, %235 : i32
      %237 = arith.trunci %236 : i32 to i16
      cf.cond_br %67, ^bb11, ^bb14
    ^bb11:  // pred: ^bb10
      %238 = nvvm.elect.sync -> i1
      cf.cond_br %238, ^bb12, ^bb13
    ^bb12:  // pred: ^bb11
      %239 = builtin.unrealized_conversion_cast %iter : !cute.ptr<i64, smem, align<128>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %239, %c32_i32 : !llvm.ptr<3>, i32
      cf.br ^bb13
    ^bb13:  // 2 preds: ^bb11, ^bb12
      cf.br ^bb14
    ^bb14:  // 2 preds: ^bb10, ^bb13
      nvvm.fence.mbarrier.init
      cf.cond_br %67, ^bb15, ^bb16
    ^bb15:  // pred: ^bb14
      cute_nvgpu.arch.sm100.alloc_tmem(%c512_i32, %iter_6) [cta_2] : i32, !cute.ptr<i32, smem, align<8>>
      cf.br ^bb16
    ^bb16:  // 2 preds: ^bb14, ^bb15
      nvvm.barrier id = %c1_i32 number_of_threads = %c128_i32
      %tmem_ptr = cute_nvgpu.arch.sm100.retrieve_tmem_ptr(%iter_6) : !cute.ptr<i32, smem, align<8>> -> !cute.ptr<f32, tmem, align<16>>
      %240 = cute.get_scalars(%lay_108) <{only_dynamic}> : !cute.layout<"((128,256),1,1):((?{i64 div=8192},1),0,0)">
      %iv_124 = cute.assume(%240) : (i64) -> !cute.i64<divby 8192>
      %stride_125 = cute.make_stride(%iv_124) : (!cute.i64<divby 8192>) -> !cute.stride<"(((?{i64 div=8192},1)),((0,64),0,0))">
      %lay_126 = cute.make_layout(%6, %stride_125) : !cute.layout<"(((128,64)),((1,4),1,1)):(((?{i64 div=8192},1)),((0,64),0,0))">
      %coord_127 = cute.make_coord(%28) : (i32) -> !cute.coord<"?">
      %241 = cute.get_scalars(%coord_127) <{only_dynamic}> : !cute.coord<"?">
      %242 = arith.divsi %241, %c32_i32 : i32
      %243 = arith.muli %242, %c2097152_i32 : i32
      %iv_128 = cute.assume(%243) : (i32) -> !cute.i32<divby 2097152>
      %int_tuple_129 = cute.make_int_tuple(%iv_128) : (!cute.i32<divby 2097152>) -> !cute.int_tuple<"?{div=2097152}">
      %ptr_130 = cute.add_offset(%tmem_ptr, %int_tuple_129) : (!cute.ptr<f32, tmem, align<16>>, !cute.int_tuple<"?{div=2097152}">) -> !cute.ptr<f32, tmem, align<16>>
      %244 = cute.get_scalars(%lay_126) <{only_dynamic}> : !cute.layout<"(((128,64)),((1,4),1,1)):(((?{i64 div=8192},1)),((0,64),0,0))">
      %245 = arith.muli %244, %c32_i64 : i64
      %246 = arith.remsi %241, %c32_i32 : i32
      %247 = arith.extsi %246 : i32 to i64
      %248 = arith.muli %247, %244 : i64
      %249 = arith.extsi %242 : i32 to i64
      %250 = arith.muli %249, %245 : i64
      %251 = arith.addi %248, %250 : i64
      %iv_131 = cute.assume(%251) : (i64) -> !cute.i64<divby 8192>
      %int_tuple_132 = cute.make_int_tuple(%iv_131) : (!cute.i64<divby 8192>) -> !cute.int_tuple<"?{i64 div=8192}">
      %ptr_133 = cute.add_offset(%ptr_105, %int_tuple_132) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{i64 div=8192}">) -> !cute.ptr<f16, gmem, align<32>>
      %rmem = cute.memref.alloca() : !memref_rmem_f32_
      %rmem_134 = cute.memref.alloca() : !memref_rmem_f16_
      %sz = cute.size(%lay_60) <{mode = [2]}> : (!cute.layout<"(256,64,?):(1@1,1@0,64@0)">) -> !cute.int_tuple<"?">
      %e0_135 = cute.get_leaves(%sz) : !cute.int_tuple<"?">
      %252 = cute.get_scalars(%e0_135) : !cute.int_tuple<"?">
      cf.cond_br %67, ^bb17, ^bb108
    ^bb17:  // pred: ^bb16
      %253 = arith.cmpi ne, %52, %c0_i32 : i32
      %254 = arith.extui %253 : i1 to i32
      cf.cond_br %101, ^bb18, ^bb19
    ^bb18:  // pred: ^bb17
      %255 = builtin.unrealized_conversion_cast %ptr_47 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %255, %c1_i32, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      cf.br ^bb19
    ^bb19:  // 2 preds: ^bb17, ^bb18
      %256 = cute_nvgpu.atom.make_exec_tma(%arg1) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_100_2sm_multicast, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>
      %257 = cute_nvgpu.atom.set_value(%256, %234 : i16) {field = #cute_nvgpu.atom_copy_field_tmaload<mcast_mask>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>
      %258 = cute_nvgpu.atom.make_exec_tma(%arg3) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_100_2sm_multicast, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>
      %259 = cute_nvgpu.atom.set_value(%258, %237 : i16) {field = #cute_nvgpu.atom_copy_field_tmaload<mcast_mask>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>
      %260 = arith.cmpi slt, %252, %c5_i32 : i32
      %261 = arith.select %260, %252, %c5_i32 : i32
      %262 = cute.get_scalars(%21) : !cute.int_tuple<"1">
      cf.br ^bb20(%c0_i32, %c0_i32, %c1_i32, %c0_i32 : i32, i32, i32, i32)
    ^bb20(%263: i32, %264: i32, %265: i32, %266: i32):  // 2 preds: ^bb19, ^bb35
      %267 = arith.cmpi slt, %263, %261 : i32
      cf.cond_br %267, ^bb21, ^bb36
    ^bb21:  // pred: ^bb20
      %int_tuple_136 = cute.make_int_tuple(%264) : (i32) -> !cute.int_tuple<"?">
      %ptr_137 = cute.add_offset(%ptr_17, %int_tuple_136) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %268 = builtin.unrealized_conversion_cast %ptr_137 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %268, %265, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      cf.cond_br %101, ^bb22, ^bb25
    ^bb22:  // pred: ^bb21
      %269 = nvvm.elect.sync -> i1
      cf.cond_br %269, ^bb23, ^bb24
    ^bb23:  // pred: ^bb22
      %ptr_138 = cute.add_offset(%iter_10, %int_tuple_136) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %270 = builtin.unrealized_conversion_cast %ptr_138 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %270, %c65536_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
      cf.br ^bb24
    ^bb24:  // 2 preds: ^bb22, ^bb23
      cf.br ^bb25
    ^bb25:  // 2 preds: ^bb21, ^bb24
      %271 = arith.addi %264, %c1_i32 : i32
      %272 = arith.addi %266, %c1_i32 : i32
      %273 = arith.cmpi eq, %271, %c7_i32 : i32
      %274 = arith.select %273, %c0_i32, %271 : i32
      cf.cond_br %273, ^bb26, ^bb27
    ^bb26:  // pred: ^bb25
      %275 = arith.xori %265, %c1_i32 : i32
      cf.br ^bb28(%275 : i32)
    ^bb27:  // pred: ^bb25
      cf.br ^bb28(%265 : i32)
    ^bb28(%276: i32):  // 2 preds: ^bb26, ^bb27
      cf.br ^bb29
    ^bb29:  // pred: ^bb28
      %coord_139 = cute.make_coord(%266) : (i32) -> !cute.coord<"(_,?)">
      %idx_140 = cute.crd2idx(%coord_139, %lay_113) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
      %tup_141 = cute.add_offset(%tup_97, %idx_140) : (!cute.int_tuple<"(0,?{div=128})">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
      %e0_142, %e1_143 = cute.get_leaves(%tup_141) : !cute.int_tuple<"(?{div=64},?{div=128})">
      %coord_144 = cute.make_coord(%264) : (i32) -> !cute.coord<"(_,?)">
      %idx_145 = cute.crd2idx(%coord_144, %5) : (!cute.coord<"(_,?)">, !cute.layout<"((8192,1),7):((1,0),8192)">) -> !cute.int_tuple<"?{div=8192}">
      %ptr_146 = cute.add_offset(%iter_8, %idx_145) : (!cute.ptr<f16, smem, align<128>, S<3,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<f16, smem, align<128>, S<3,4,3>>
      %ptr_147 = cute.add_offset(%iter_10, %int_tuple_136) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %int_tuple_148 = cute.make_int_tuple(%e0_142, %e1_143) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=128}">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
      %277 = cute_nvgpu.atom.set_value(%257, %ptr_147 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>
      %278 = cute_nvgpu.atom.get_value(%277 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
      %279 = cute_nvgpu.atom.get_value(%277 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<mcast_mask>} : i16
      %280 = cute_nvgpu.atom.get_value(%277 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<cache_policy>} : i64
      %TMADescAddr = cute_nvgpu.get_tma_desc_addr(%277 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) -> !cute.ptr<generic, align<64>>
      %281:2 = cute.get_scalars(%int_tuple_148) : !cute.int_tuple<"(?{div=64},?{div=128})">
      cf.br ^bb30(%c0_i32 : i32)
    ^bb30(%282: i32):  // 2 preds: ^bb29, ^bb31
      %283 = arith.cmpi slt, %282, %262 : i32
      cf.cond_br %283, ^bb31, ^bb32 {llvm.loop_annotation = #loop_annotation}
    ^bb31:  // pred: ^bb30
      cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr : !cute.ptr<generic, align<64>>, %ptr_146 : !cute.ptr<f16, smem, align<128>, S<3,4,3>>, %278 : !cute.ptr<smem, align<8>>, [%281#0, %281#1] : i32, i32) mask = %279 cache_policy = %280 mode = <tiled> num_cta = 2 : i32
      %284 = arith.addi %282, %c1_i32 : i32
      cf.br ^bb30(%284 : i32)
    ^bb32:  // pred: ^bb30
      %idx_149 = cute.crd2idx(%coord_139, %lay_117) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
      %tup_150 = cute.add_offset(%tup_100, %idx_149) : (!cute.int_tuple<"(0,?{div=128})">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
      %e0_151, %e1_152 = cute.get_leaves(%tup_150) : !cute.int_tuple<"(?{div=64},?{div=128})">
      %ptr_153 = cute.add_offset(%iter_9, %idx_145) : (!cute.ptr<f16, smem, align<128>, S<3,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<f16, smem, align<128>, S<3,4,3>>
      %int_tuple_154 = cute.make_int_tuple(%e0_151, %e1_152) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=128}">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
      %285 = cute_nvgpu.atom.set_value(%259, %ptr_147 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>
      %286 = cute_nvgpu.atom.get_value(%285 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
      %287 = cute_nvgpu.atom.get_value(%285 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<mcast_mask>} : i16
      %288 = cute_nvgpu.atom.get_value(%285 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<cache_policy>} : i64
      %TMADescAddr_155 = cute_nvgpu.get_tma_desc_addr(%285 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) -> !cute.ptr<generic, align<64>>
      %289:2 = cute.get_scalars(%int_tuple_154) : !cute.int_tuple<"(?{div=64},?{div=128})">
      cf.br ^bb33(%c0_i32 : i32)
    ^bb33(%290: i32):  // 2 preds: ^bb32, ^bb34
      %291 = arith.cmpi slt, %290, %262 : i32
      cf.cond_br %291, ^bb34, ^bb35 {llvm.loop_annotation = #loop_annotation}
    ^bb34:  // pred: ^bb33
      cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr_155 : !cute.ptr<generic, align<64>>, %ptr_153 : !cute.ptr<f16, smem, align<128>, S<3,4,3>>, %286 : !cute.ptr<smem, align<8>>, [%289#0, %289#1] : i32, i32) mask = %287 cache_policy = %288 mode = <tiled> num_cta = 2 : i32
      %292 = arith.addi %290, %c1_i32 : i32
      cf.br ^bb33(%292 : i32)
    ^bb35:  // pred: ^bb33
      %293 = arith.addi %263, %c1_i32 : i32
      cf.br ^bb20(%293, %274, %276, %272 : i32, i32, i32, i32)
    ^bb36:  // pred: ^bb20
      cf.br ^bb37(%c0_i32, %266, %264, %265, %c0_i32, %c0_i32, %c0_i32, %0 : i32, i32, i32, i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>)
    ^bb37(%294: i32, %295: i32, %296: i32, %297: i32, %298: i32, %299: i32, %300: i32, %301: !llvm.struct<(i1, i1, i1)>):  // 2 preds: ^bb36, ^bb102
      %302 = arith.cmpi slt, %294, %252 : i32
      cf.cond_br %302, ^bb38, ^bb103
    ^bb38:  // pred: ^bb37
      %303 = builtin.unrealized_conversion_cast %301 : !llvm.struct<(i1, i1, i1)> to !mma_f16_f16_f32_256x256x16_
      %304 = arith.addi %294, %261 : i32
      %305 = arith.cmpi ult, %304, %252 : i32
      cf.cond_br %305, ^bb39, ^bb54
    ^bb39:  // pred: ^bb38
      %int_tuple_156 = cute.make_int_tuple(%296) : (i32) -> !cute.int_tuple<"?">
      %ptr_157 = cute.add_offset(%ptr_17, %int_tuple_156) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %306 = builtin.unrealized_conversion_cast %ptr_157 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %306, %297, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      cf.cond_br %101, ^bb40, ^bb43
    ^bb40:  // pred: ^bb39
      %307 = nvvm.elect.sync -> i1
      cf.cond_br %307, ^bb41, ^bb42
    ^bb41:  // pred: ^bb40
      %ptr_158 = cute.add_offset(%iter_10, %int_tuple_156) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %308 = builtin.unrealized_conversion_cast %ptr_158 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %308, %c65536_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
      cf.br ^bb42
    ^bb42:  // 2 preds: ^bb40, ^bb41
      cf.br ^bb43
    ^bb43:  // 2 preds: ^bb39, ^bb42
      %309 = arith.addi %296, %c1_i32 : i32
      %310 = arith.addi %295, %c1_i32 : i32
      %311 = arith.cmpi eq, %309, %c7_i32 : i32
      %312 = arith.select %311, %c0_i32, %309 : i32
      cf.cond_br %311, ^bb44, ^bb45
    ^bb44:  // pred: ^bb43
      %313 = arith.xori %297, %c1_i32 : i32
      cf.br ^bb46(%313 : i32)
    ^bb45:  // pred: ^bb43
      cf.br ^bb46(%297 : i32)
    ^bb46(%314: i32):  // 2 preds: ^bb44, ^bb45
      cf.br ^bb47
    ^bb47:  // pred: ^bb46
      %coord_159 = cute.make_coord(%295) : (i32) -> !cute.coord<"(_,?)">
      %idx_160 = cute.crd2idx(%coord_159, %lay_113) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
      %tup_161 = cute.add_offset(%tup_97, %idx_160) : (!cute.int_tuple<"(0,?{div=128})">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
      %e0_162, %e1_163 = cute.get_leaves(%tup_161) : !cute.int_tuple<"(?{div=64},?{div=128})">
      %coord_164 = cute.make_coord(%296) : (i32) -> !cute.coord<"(_,?)">
      %idx_165 = cute.crd2idx(%coord_164, %5) : (!cute.coord<"(_,?)">, !cute.layout<"((8192,1),7):((1,0),8192)">) -> !cute.int_tuple<"?{div=8192}">
      %ptr_166 = cute.add_offset(%iter_8, %idx_165) : (!cute.ptr<f16, smem, align<128>, S<3,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<f16, smem, align<128>, S<3,4,3>>
      %ptr_167 = cute.add_offset(%iter_10, %int_tuple_156) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %int_tuple_168 = cute.make_int_tuple(%e0_162, %e1_163) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=128}">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
      %315 = cute_nvgpu.atom.set_value(%257, %ptr_167 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>
      %316 = cute.get_scalars(%21) : !cute.int_tuple<"1">
      %317 = cute_nvgpu.atom.get_value(%315 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
      %318 = cute_nvgpu.atom.get_value(%315 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<mcast_mask>} : i16
      %319 = cute_nvgpu.atom.get_value(%315 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<cache_policy>} : i64
      %TMADescAddr_169 = cute_nvgpu.get_tma_desc_addr(%315 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) -> !cute.ptr<generic, align<64>>
      %320:2 = cute.get_scalars(%int_tuple_168) : !cute.int_tuple<"(?{div=64},?{div=128})">
      cf.br ^bb48(%c0_i32 : i32)
    ^bb48(%321: i32):  // 2 preds: ^bb47, ^bb49
      %322 = arith.cmpi slt, %321, %316 : i32
      cf.cond_br %322, ^bb49, ^bb50 {llvm.loop_annotation = #loop_annotation}
    ^bb49:  // pred: ^bb48
      cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr_169 : !cute.ptr<generic, align<64>>, %ptr_166 : !cute.ptr<f16, smem, align<128>, S<3,4,3>>, %317 : !cute.ptr<smem, align<8>>, [%320#0, %320#1] : i32, i32) mask = %318 cache_policy = %319 mode = <tiled> num_cta = 2 : i32
      %323 = arith.addi %321, %c1_i32 : i32
      cf.br ^bb48(%323 : i32)
    ^bb50:  // pred: ^bb48
      %idx_170 = cute.crd2idx(%coord_159, %lay_117) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
      %tup_171 = cute.add_offset(%tup_100, %idx_170) : (!cute.int_tuple<"(0,?{div=128})">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
      %e0_172, %e1_173 = cute.get_leaves(%tup_171) : !cute.int_tuple<"(?{div=64},?{div=128})">
      %ptr_174 = cute.add_offset(%iter_9, %idx_165) : (!cute.ptr<f16, smem, align<128>, S<3,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<f16, smem, align<128>, S<3,4,3>>
      %int_tuple_175 = cute.make_int_tuple(%e0_172, %e1_173) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=128}">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
      %324 = cute_nvgpu.atom.set_value(%259, %ptr_167 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>
      %325 = cute_nvgpu.atom.get_value(%324 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
      %326 = cute_nvgpu.atom.get_value(%324 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<mcast_mask>} : i16
      %327 = cute_nvgpu.atom.get_value(%324 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<cache_policy>} : i64
      %TMADescAddr_176 = cute_nvgpu.get_tma_desc_addr(%324 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) -> !cute.ptr<generic, align<64>>
      %328:2 = cute.get_scalars(%int_tuple_175) : !cute.int_tuple<"(?{div=64},?{div=128})">
      cf.br ^bb51(%c0_i32 : i32)
    ^bb51(%329: i32):  // 2 preds: ^bb50, ^bb52
      %330 = arith.cmpi slt, %329, %316 : i32
      cf.cond_br %330, ^bb52, ^bb53 {llvm.loop_annotation = #loop_annotation}
    ^bb52:  // pred: ^bb51
      cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr_176 : !cute.ptr<generic, align<64>>, %ptr_174 : !cute.ptr<f16, smem, align<128>, S<3,4,3>>, %325 : !cute.ptr<smem, align<8>>, [%328#0, %328#1] : i32, i32) mask = %326 cache_policy = %327 mode = <tiled> num_cta = 2 : i32
      %331 = arith.addi %329, %c1_i32 : i32
      cf.br ^bb51(%331 : i32)
    ^bb53:  // pred: ^bb51
      cf.br ^bb55(%312, %314, %310 : i32, i32, i32)
    ^bb54:  // pred: ^bb38
      cf.br ^bb55(%296, %297, %295 : i32, i32, i32)
    ^bb55(%332: i32, %333: i32, %334: i32):  // 2 preds: ^bb53, ^bb54
      cf.br ^bb56
    ^bb56:  // pred: ^bb55
      cf.cond_br %101, ^bb57, ^bb100
    ^bb57:  // pred: ^bb56
      %int_tuple_177 = cute.make_int_tuple(%299) : (i32) -> !cute.int_tuple<"?">
      %ptr_178 = cute.add_offset(%iter_10, %int_tuple_177) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %335 = builtin.unrealized_conversion_cast %ptr_178 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %335, %300, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %336 = arith.addi %299, %c1_i32 : i32
      %337 = arith.addi %298, %c1_i32 : i32
      %338 = arith.cmpi eq, %336, %c7_i32 : i32
      %339 = arith.select %338, %c0_i32, %336 : i32
      cf.cond_br %338, ^bb58, ^bb59
    ^bb58:  // pred: ^bb57
      %340 = arith.xori %300, %c1_i32 : i32
      cf.br ^bb60(%340 : i32)
    ^bb59:  // pred: ^bb57
      cf.br ^bb60(%300 : i32)
    ^bb60(%341: i32):  // 2 preds: ^bb58, ^bb59
      cf.br ^bb61
    ^bb61:  // pred: ^bb60
      %coord_179 = cute.make_coord(%299) : (i32) -> !cute.coord<"(_,_,0,?)">
      %idx_180 = cute.crd2idx(%coord_179, %4) : (!cute.coord<"(_,_,0,?)">, !cute.layout<"(1,1,4,7):(0,0,2,1024)">) -> !cute.int_tuple<"?{div=1024}">
      %tup_181 = cute.add_offset(%ummaSmemDesc, %idx_180) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=1024}">) -> !cute_nvgpu.smem_desc
      %tup_182 = cute.add_offset(%ummaSmemDesc_109, %idx_180) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=1024}">) -> !cute_nvgpu.smem_desc
      %342 = cute.get_scalars(%21) : !cute.int_tuple<"1">
      %343 = cute_nvgpu.atom.get_value(%303 : !mma_f16_f16_f32_256x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : i1
      %344 = cute_nvgpu.atom.get_value(%303 : !mma_f16_f16_f32_256x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : i1
      %345 = cute_nvgpu.atom.get_value(%303 : !mma_f16_f16_f32_256x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : i1
      %346 = arith.extui %343 : i1 to i32
      %347 = arith.extui %344 : i1 to i32
      %348 = arith.shli %346, %c13_i32 : i32
      %349 = arith.shli %347, %c14_i32 : i32
      %350 = arith.ori %348, %c272629776_i32 : i32
      %351 = arith.ori %350, %349 : i32
      cf.br ^bb62(%c0_i32 : i32)
    ^bb62(%352: i32):  // 2 preds: ^bb61, ^bb69
      %353 = arith.cmpi slt, %352, %342 : i32
      cf.cond_br %353, ^bb63, ^bb70 {llvm.loop_annotation = #loop_annotation}
    ^bb63:  // pred: ^bb62
      cf.br ^bb64(%c0_i32 : i32)
    ^bb64(%354: i32):  // 2 preds: ^bb63, ^bb68
      %355 = arith.cmpi slt, %354, %342 : i32
      cf.cond_br %355, ^bb65, ^bb69 {llvm.loop_annotation = #loop_annotation}
    ^bb65:  // pred: ^bb64
      cf.br ^bb66(%c0_i32 : i32)
    ^bb66(%356: i32):  // 2 preds: ^bb65, ^bb67
      %357 = arith.cmpi slt, %356, %342 : i32
      cf.cond_br %357, ^bb67, ^bb68 {llvm.loop_annotation = #loop_annotation}
    ^bb67:  // pred: ^bb66
      cute_nvgpu.arch.mma.SM100.umma(%tup_181, %tup_182, %tmem_ptr, %351, %345) {num_cta = 2 : i32, scale = 0 : i32, a_type = f16} : (!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, !cute.ptr<f32, tmem, align<16>>, i32, i1) -> ()
      %358 = arith.addi %356, %c1_i32 : i32
      cf.br ^bb66(%358 : i32)
    ^bb68:  // pred: ^bb66
      %359 = arith.addi %354, %c1_i32 : i32
      cf.br ^bb64(%359 : i32)
    ^bb69:  // pred: ^bb64
      %360 = arith.addi %352, %c1_i32 : i32
      cf.br ^bb62(%360 : i32)
    ^bb70:  // pred: ^bb62
      %361 = cute_nvgpu.atom.set_value(%303, %true : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_f16_f16_f32_256x256x16_
      %coord_183 = cute.make_coord(%299) : (i32) -> !cute.coord<"(_,_,1,?)">
      %idx_184 = cute.crd2idx(%coord_183, %4) : (!cute.coord<"(_,_,1,?)">, !cute.layout<"(1,1,4,7):(0,0,2,1024)">) -> !cute.int_tuple<"?{div=2}">
      %tup_185 = cute.add_offset(%ummaSmemDesc, %idx_184) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
      %tup_186 = cute.add_offset(%ummaSmemDesc_109, %idx_184) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
      %362 = cute_nvgpu.atom.get_value(%361 : !mma_f16_f16_f32_256x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : i1
      %363 = cute_nvgpu.atom.get_value(%361 : !mma_f16_f16_f32_256x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : i1
      %364 = cute_nvgpu.atom.get_value(%361 : !mma_f16_f16_f32_256x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : i1
      %365 = arith.extui %362 : i1 to i32
      %366 = arith.extui %363 : i1 to i32
      %367 = arith.shli %365, %c13_i32 : i32
      %368 = arith.shli %366, %c14_i32 : i32
      %369 = arith.ori %367, %c272629776_i32 : i32
      %370 = arith.ori %369, %368 : i32
      cf.br ^bb71(%c0_i32 : i32)
    ^bb71(%371: i32):  // 2 preds: ^bb70, ^bb78
      %372 = arith.cmpi slt, %371, %342 : i32
      cf.cond_br %372, ^bb72, ^bb79 {llvm.loop_annotation = #loop_annotation}
    ^bb72:  // pred: ^bb71
      cf.br ^bb73(%c0_i32 : i32)
    ^bb73(%373: i32):  // 2 preds: ^bb72, ^bb77
      %374 = arith.cmpi slt, %373, %342 : i32
      cf.cond_br %374, ^bb74, ^bb78 {llvm.loop_annotation = #loop_annotation}
    ^bb74:  // pred: ^bb73
      cf.br ^bb75(%c0_i32 : i32)
    ^bb75(%375: i32):  // 2 preds: ^bb74, ^bb76
      %376 = arith.cmpi slt, %375, %342 : i32
      cf.cond_br %376, ^bb76, ^bb77 {llvm.loop_annotation = #loop_annotation}
    ^bb76:  // pred: ^bb75
      cute_nvgpu.arch.mma.SM100.umma(%tup_185, %tup_186, %tmem_ptr, %370, %364) {num_cta = 2 : i32, scale = 0 : i32, a_type = f16} : (!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, !cute.ptr<f32, tmem, align<16>>, i32, i1) -> ()
      %377 = arith.addi %375, %c1_i32 : i32
      cf.br ^bb75(%377 : i32)
    ^bb77:  // pred: ^bb75
      %378 = arith.addi %373, %c1_i32 : i32
      cf.br ^bb73(%378 : i32)
    ^bb78:  // pred: ^bb73
      %379 = arith.addi %371, %c1_i32 : i32
      cf.br ^bb71(%379 : i32)
    ^bb79:  // pred: ^bb71
      %380 = cute_nvgpu.atom.set_value(%361, %true : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_f16_f16_f32_256x256x16_
      %coord_187 = cute.make_coord(%299) : (i32) -> !cute.coord<"(_,_,2,?)">
      %idx_188 = cute.crd2idx(%coord_187, %4) : (!cute.coord<"(_,_,2,?)">, !cute.layout<"(1,1,4,7):(0,0,2,1024)">) -> !cute.int_tuple<"?{div=4}">
      %tup_189 = cute.add_offset(%ummaSmemDesc, %idx_188) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=4}">) -> !cute_nvgpu.smem_desc
      %tup_190 = cute.add_offset(%ummaSmemDesc_109, %idx_188) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=4}">) -> !cute_nvgpu.smem_desc
      %381 = cute_nvgpu.atom.get_value(%380 : !mma_f16_f16_f32_256x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : i1
      %382 = cute_nvgpu.atom.get_value(%380 : !mma_f16_f16_f32_256x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : i1
      %383 = cute_nvgpu.atom.get_value(%380 : !mma_f16_f16_f32_256x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : i1
      %384 = arith.extui %381 : i1 to i32
      %385 = arith.extui %382 : i1 to i32
      %386 = arith.shli %384, %c13_i32 : i32
      %387 = arith.shli %385, %c14_i32 : i32
      %388 = arith.ori %386, %c272629776_i32 : i32
      %389 = arith.ori %388, %387 : i32
      cf.br ^bb80(%c0_i32 : i32)
    ^bb80(%390: i32):  // 2 preds: ^bb79, ^bb87
      %391 = arith.cmpi slt, %390, %342 : i32
      cf.cond_br %391, ^bb81, ^bb88 {llvm.loop_annotation = #loop_annotation}
    ^bb81:  // pred: ^bb80
      cf.br ^bb82(%c0_i32 : i32)
    ^bb82(%392: i32):  // 2 preds: ^bb81, ^bb86
      %393 = arith.cmpi slt, %392, %342 : i32
      cf.cond_br %393, ^bb83, ^bb87 {llvm.loop_annotation = #loop_annotation}
    ^bb83:  // pred: ^bb82
      cf.br ^bb84(%c0_i32 : i32)
    ^bb84(%394: i32):  // 2 preds: ^bb83, ^bb85
      %395 = arith.cmpi slt, %394, %342 : i32
      cf.cond_br %395, ^bb85, ^bb86 {llvm.loop_annotation = #loop_annotation}
    ^bb85:  // pred: ^bb84
      cute_nvgpu.arch.mma.SM100.umma(%tup_189, %tup_190, %tmem_ptr, %389, %383) {num_cta = 2 : i32, scale = 0 : i32, a_type = f16} : (!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, !cute.ptr<f32, tmem, align<16>>, i32, i1) -> ()
      %396 = arith.addi %394, %c1_i32 : i32
      cf.br ^bb84(%396 : i32)
    ^bb86:  // pred: ^bb84
      %397 = arith.addi %392, %c1_i32 : i32
      cf.br ^bb82(%397 : i32)
    ^bb87:  // pred: ^bb82
      %398 = arith.addi %390, %c1_i32 : i32
      cf.br ^bb80(%398 : i32)
    ^bb88:  // pred: ^bb80
      %399 = cute_nvgpu.atom.set_value(%380, %true : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_f16_f16_f32_256x256x16_
      %coord_191 = cute.make_coord(%299) : (i32) -> !cute.coord<"(_,_,3,?)">
      %idx_192 = cute.crd2idx(%coord_191, %4) : (!cute.coord<"(_,_,3,?)">, !cute.layout<"(1,1,4,7):(0,0,2,1024)">) -> !cute.int_tuple<"?{div=2}">
      %tup_193 = cute.add_offset(%ummaSmemDesc, %idx_192) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
      %tup_194 = cute.add_offset(%ummaSmemDesc_109, %idx_192) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
      %400 = cute_nvgpu.atom.get_value(%399 : !mma_f16_f16_f32_256x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : i1
      %401 = cute_nvgpu.atom.get_value(%399 : !mma_f16_f16_f32_256x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : i1
      %402 = cute_nvgpu.atom.get_value(%399 : !mma_f16_f16_f32_256x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : i1
      %403 = arith.extui %400 : i1 to i32
      %404 = arith.extui %401 : i1 to i32
      %405 = arith.shli %403, %c13_i32 : i32
      %406 = arith.shli %404, %c14_i32 : i32
      %407 = arith.ori %405, %c272629776_i32 : i32
      %408 = arith.ori %407, %406 : i32
      cf.br ^bb89(%c0_i32 : i32)
    ^bb89(%409: i32):  // 2 preds: ^bb88, ^bb96
      %410 = arith.cmpi slt, %409, %342 : i32
      cf.cond_br %410, ^bb90, ^bb97 {llvm.loop_annotation = #loop_annotation}
    ^bb90:  // pred: ^bb89
      cf.br ^bb91(%c0_i32 : i32)
    ^bb91(%411: i32):  // 2 preds: ^bb90, ^bb95
      %412 = arith.cmpi slt, %411, %342 : i32
      cf.cond_br %412, ^bb92, ^bb96 {llvm.loop_annotation = #loop_annotation}
    ^bb92:  // pred: ^bb91
      cf.br ^bb93(%c0_i32 : i32)
    ^bb93(%413: i32):  // 2 preds: ^bb92, ^bb94
      %414 = arith.cmpi slt, %413, %342 : i32
      cf.cond_br %414, ^bb94, ^bb95 {llvm.loop_annotation = #loop_annotation}
    ^bb94:  // pred: ^bb93
      cute_nvgpu.arch.mma.SM100.umma(%tup_193, %tup_194, %tmem_ptr, %408, %402) {num_cta = 2 : i32, scale = 0 : i32, a_type = f16} : (!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, !cute.ptr<f32, tmem, align<16>>, i32, i1) -> ()
      %415 = arith.addi %413, %c1_i32 : i32
      cf.br ^bb93(%415 : i32)
    ^bb95:  // pred: ^bb93
      %416 = arith.addi %411, %c1_i32 : i32
      cf.br ^bb91(%416 : i32)
    ^bb96:  // pred: ^bb91
      %417 = arith.addi %409, %c1_i32 : i32
      cf.br ^bb89(%417 : i32)
    ^bb97:  // pred: ^bb89
      %418 = cute_nvgpu.atom.set_value(%399, %true : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_f16_f16_f32_256x256x16_
      %419 = builtin.unrealized_conversion_cast %418 : !mma_f16_f16_f32_256x256x16_ to !llvm.struct<(i1, i1, i1)>
      %420 = nvvm.elect.sync -> i1
      cf.cond_br %420, ^bb98, ^bb99
    ^bb98:  // pred: ^bb97
      %ptr_195 = cute.add_offset(%ptr_17, %int_tuple_177) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %421 = builtin.unrealized_conversion_cast %ptr_195 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.tcgen05.commit.arrive %421, multicast_mask = %100 {group = #nvvm.tcgen05_group<cta_2>} : !llvm.ptr<3>, i16
      cf.br ^bb99
    ^bb99:  // 2 preds: ^bb97, ^bb98
      cf.br ^bb101(%337, %339, %341, %419 : i32, i32, i32, !llvm.struct<(i1, i1, i1)>)
    ^bb100:  // pred: ^bb56
      cf.br ^bb101(%298, %299, %300, %301 : i32, i32, i32, !llvm.struct<(i1, i1, i1)>)
    ^bb101(%422: i32, %423: i32, %424: i32, %425: !llvm.struct<(i1, i1, i1)>):  // 2 preds: ^bb99, ^bb100
      cf.br ^bb102
    ^bb102:  // pred: ^bb101
      %426 = arith.addi %294, %c1_i32 : i32
      cf.br ^bb37(%426, %334, %332, %333, %422, %423, %424, %425 : i32, i32, i32, i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>)
    ^bb103:  // pred: ^bb37
      cf.cond_br %101, ^bb104, ^bb107
    ^bb104:  // pred: ^bb103
      %427 = nvvm.elect.sync -> i1
      cf.cond_br %427, ^bb105, ^bb106
    ^bb105:  // pred: ^bb104
      %dyn_196 = cute.derefine(%iter_46) : !cute.ptr<i64, smem, align<16>> to !cute.ptr<i64, smem>
      %428 = builtin.unrealized_conversion_cast %dyn_196 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.tcgen05.commit.arrive %428, multicast_mask = %c3_i16 {group = #nvvm.tcgen05_group<cta_2>} : !llvm.ptr<3>, i16
      cf.br ^bb106
    ^bb106:  // 2 preds: ^bb104, ^bb105
      cf.br ^bb107
    ^bb107:  // 2 preds: ^bb103, ^bb106
      cf.br ^bb109(%254, %296, %297 : i32, i32, i32)
    ^bb108:  // pred: ^bb16
      cf.br ^bb109(%c1_i32, %c0_i32, %c1_i32 : i32, i32, i32)
    ^bb109(%429: i32, %430: i32, %431: i32):  // 2 preds: ^bb107, ^bb108
      cf.br ^bb110
    ^bb110:  // pred: ^bb109
      cf.cond_br %67, ^bb111, ^bb112
    ^bb111:  // pred: ^bb110
      cute_nvgpu.arch.sm100.relinquish_tmem_alloc_permit [cta_2]
      cf.br ^bb112
    ^bb112:  // 2 preds: ^bb110, ^bb111
      %dyn_197 = cute.derefine(%iter_46) : !cute.ptr<i64, smem, align<16>> to !cute.ptr<i64, smem>
      %432 = builtin.unrealized_conversion_cast %dyn_197 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %432, %c0_i32, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %iter_198 = cute.get_iter(%rmem) : !memref_rmem_f32_
      %433 = cute.get_scalars(%21) : !cute.int_tuple<"1">
      %434 = builtin.unrealized_conversion_cast %iter_198 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
      %iter_199 = cute.get_iter(%rmem_134) : !memref_rmem_f16_
      %435 = cute.get_scalars(%18) : !cute.int_tuple<"4">
      cf.br ^bb113(%c0_i32 : i32)
    ^bb113(%436: i32):  // 2 preds: ^bb112, ^bb120
      %437 = arith.cmpi slt, %436, %c4_i32 : i32
      cf.cond_br %437, ^bb114, ^bb121
    ^bb114:  // pred: ^bb113
      %coord_200 = cute.make_coord(%436) : (i32) -> !cute.coord<"(_,_,?)">
      %idx_201 = cute.crd2idx(%coord_200, %3) : (!cute.coord<"(_,_,?)">, !cute.layout<"(((64,32),1),1,((1,4),1,1)):(((1,65536),0),0,((0,64),0,0))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_202 = cute.add_offset(%ptr_130, %idx_201) : (!cute.ptr<f32, tmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<f32, tmem, align<16>>
      cf.br ^bb115(%c0_i32 : i32)
    ^bb115(%438: i32):  // 2 preds: ^bb114, ^bb116
      %439 = arith.cmpi slt, %438, %433 : i32
      cf.cond_br %439, ^bb116, ^bb117 {llvm.loop_annotation = #loop_annotation}
    ^bb116:  // pred: ^bb115
      %440 = "cute_nvgpu.arch.copy.SM100.tmem_load"(%ptr_202) <{num_b = 32 : i32, num_dp = 32 : i32, num_rep = 64 : i32}> : (!cute.ptr<f32, tmem, align<16>>) -> vector<64xi32>
      llvm.store %440, %434 : vector<64xi32>, !llvm.ptr
      %441 = arith.addi %438, %c1_i32 : i32
      cf.br ^bb115(%441 : i32)
    ^bb117:  // pred: ^bb115
      %442 = cute.memref.load_vec %rmem : !memref_rmem_f32_
      %443 = arith.truncf %442 : vector<64xf32> to vector<64xf16>
      cute.memref.store_vec %443, %rmem_134 : !memref_rmem_f16_
      %idx_203 = cute.crd2idx(%coord_200, %2) : (!cute.coord<"(_,_,?)">, !cute.layout<"((64,1),1,((1,4),1,1)):((1,0),0,((0,64),0,0))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_204 = cute.add_offset(%ptr_133, %idx_203) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<f16, gmem, align<32>>
      cf.br ^bb118(%c0_i32 : i32)
    ^bb118(%444: i32):  // 2 preds: ^bb117, ^bb119
      %445 = arith.cmpi slt, %444, %435 : i32
      cf.cond_br %445, ^bb119, ^bb120 {llvm.loop_annotation = #loop_annotation}
    ^bb119:  // pred: ^bb118
      %coord_205 = cute.make_coord(%444) : (i32) -> !cute.coord<"(_,?)">
      %idx_206 = cute.crd2idx(%coord_205, %1) : (!cute.coord<"(_,?)">, !cute.layout<"(16,(4)):(1,(16))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_207 = cute.add_offset(%iter_199, %idx_206) : (!cute.ptr<f16, rmem, align<32>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<f16, rmem, align<32>>
      %ptr_208 = cute.add_offset(%ptr_204, %idx_206) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<f16, gmem, align<32>>
      %446 = builtin.unrealized_conversion_cast %ptr_207 : !cute.ptr<f16, rmem, align<32>> to !llvm.ptr
      %447 = builtin.unrealized_conversion_cast %ptr_208 : !cute.ptr<f16, gmem, align<32>> to !llvm.ptr<1>
      %448 = llvm.load %446 {alignment = 32 : i64} : !llvm.ptr -> vector<16xf16>
      llvm.store %448, %447 {alignment = 32 : i64} : vector<16xf16>, !llvm.ptr<1>
      %449 = arith.addi %444, %c1_i32 : i32
      cf.br ^bb118(%449 : i32)
    ^bb120:  // pred: ^bb118
      %450 = arith.addi %436, %c1_i32 : i32
      cf.br ^bb113(%450 : i32)
    ^bb121:  // pred: ^bb113
      %451 = builtin.unrealized_conversion_cast %ptr_47 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      %452 = nvvm.mapa.shared.cluster %451, %113 : !llvm.ptr<3>, i32 -> <3>
      nvvm.mbarrier.txn %452, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>, space = #nvvm.mbar_space<cluster>} : !llvm.ptr<3>, i32
      cf.cond_br %67, ^bb122, ^bb155
    ^bb122:  // pred: ^bb121
      %453 = arith.addi %430, %c1_i32 : i32
      %454 = arith.cmpi eq, %453, %c7_i32 : i32
      %455 = arith.select %454, %c0_i32, %453 : i32
      cf.cond_br %454, ^bb123, ^bb124
    ^bb123:  // pred: ^bb122
      %456 = arith.xori %431, %c1_i32 : i32
      cf.br ^bb125(%456 : i32)
    ^bb124:  // pred: ^bb122
      cf.br ^bb125(%431 : i32)
    ^bb125(%457: i32):  // 2 preds: ^bb123, ^bb124
      cf.br ^bb126
    ^bb126:  // pred: ^bb125
      %458 = arith.addi %455, %c1_i32 : i32
      %459 = arith.cmpi eq, %458, %c7_i32 : i32
      %460 = arith.select %459, %c0_i32, %458 : i32
      cf.cond_br %459, ^bb127, ^bb128
    ^bb127:  // pred: ^bb126
      %461 = arith.xori %457, %c1_i32 : i32
      cf.br ^bb129(%461 : i32)
    ^bb128:  // pred: ^bb126
      cf.br ^bb129(%457 : i32)
    ^bb129(%462: i32):  // 2 preds: ^bb127, ^bb128
      cf.br ^bb130
    ^bb130:  // pred: ^bb129
      %463 = arith.addi %460, %c1_i32 : i32
      %464 = arith.cmpi eq, %463, %c7_i32 : i32
      %465 = arith.select %464, %c0_i32, %463 : i32
      cf.cond_br %464, ^bb131, ^bb132
    ^bb131:  // pred: ^bb130
      %466 = arith.xori %462, %c1_i32 : i32
      cf.br ^bb133(%466 : i32)
    ^bb132:  // pred: ^bb130
      cf.br ^bb133(%462 : i32)
    ^bb133(%467: i32):  // 2 preds: ^bb131, ^bb132
      cf.br ^bb134
    ^bb134:  // pred: ^bb133
      %468 = arith.addi %465, %c1_i32 : i32
      %469 = arith.cmpi eq, %468, %c7_i32 : i32
      %470 = arith.select %469, %c0_i32, %468 : i32
      cf.cond_br %469, ^bb135, ^bb136
    ^bb135:  // pred: ^bb134
      %471 = arith.xori %467, %c1_i32 : i32
      cf.br ^bb137(%471 : i32)
    ^bb136:  // pred: ^bb134
      cf.br ^bb137(%467 : i32)
    ^bb137(%472: i32):  // 2 preds: ^bb135, ^bb136
      cf.br ^bb138
    ^bb138:  // pred: ^bb137
      %473 = arith.addi %470, %c1_i32 : i32
      %474 = arith.cmpi eq, %473, %c7_i32 : i32
      %475 = arith.select %474, %c0_i32, %473 : i32
      cf.cond_br %474, ^bb139, ^bb140
    ^bb139:  // pred: ^bb138
      %476 = arith.xori %472, %c1_i32 : i32
      cf.br ^bb141(%476 : i32)
    ^bb140:  // pred: ^bb138
      cf.br ^bb141(%472 : i32)
    ^bb141(%477: i32):  // 2 preds: ^bb139, ^bb140
      cf.br ^bb142
    ^bb142:  // pred: ^bb141
      %478 = arith.addi %475, %c1_i32 : i32
      %479 = arith.cmpi eq, %478, %c7_i32 : i32
      %480 = arith.select %479, %c0_i32, %478 : i32
      cf.cond_br %479, ^bb143, ^bb144
    ^bb143:  // pred: ^bb142
      %481 = arith.xori %477, %c1_i32 : i32
      cf.br ^bb145(%481 : i32)
    ^bb144:  // pred: ^bb142
      cf.br ^bb145(%477 : i32)
    ^bb145(%482: i32):  // 2 preds: ^bb143, ^bb144
      cf.br ^bb146
    ^bb146:  // pred: ^bb145
      %int_tuple_209 = cute.make_int_tuple(%480) : (i32) -> !cute.int_tuple<"?">
      %ptr_210 = cute.add_offset(%ptr_17, %int_tuple_209) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %483 = builtin.unrealized_conversion_cast %ptr_210 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %483, %482, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      cf.cond_br %101, ^bb147, ^bb150
    ^bb147:  // pred: ^bb146
      %484 = nvvm.elect.sync -> i1
      cf.cond_br %484, ^bb148, ^bb149
    ^bb148:  // pred: ^bb147
      %ptr_211 = cute.add_offset(%iter_10, %int_tuple_209) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %485 = builtin.unrealized_conversion_cast %ptr_211 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %485, %c65536_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
      cf.br ^bb149
    ^bb149:  // 2 preds: ^bb147, ^bb148
      cf.br ^bb150
    ^bb150:  // 2 preds: ^bb146, ^bb149
      cf.cond_br %101, ^bb151, ^bb154
    ^bb151:  // pred: ^bb150
      %486 = arith.remsi %82, %c2_i32 : i32
      %487 = arith.cmpi eq, %486, %c0_i32 : i32
      cf.cond_br %487, ^bb152, ^bb153
    ^bb152:  // pred: ^bb151
      nvvm.mbarrier.try_wait.parity.shared %451, %429, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      cf.br ^bb153
    ^bb153:  // 2 preds: ^bb151, ^bb152
      cf.br ^bb154
    ^bb154:  // 2 preds: ^bb150, ^bb153
      cf.br ^bb155
    ^bb155:  // 2 preds: ^bb121, ^bb154
      nvvm.barrier id = %c1_i32
      cf.cond_br %67, ^bb156, ^bb157
    ^bb156:  // pred: ^bb155
      %488 = arith.xori %82, %c1_i32 : i32
      %489 = builtin.unrealized_conversion_cast %iter : !cute.ptr<i64, smem, align<128>> to !llvm.ptr<3>
      %490 = nvvm.mapa.shared.cluster %489, %488 : !llvm.ptr<3>, i32 -> <3>
      nvvm.mbarrier.txn %490, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>, space = #nvvm.mbar_space<cluster>} : !llvm.ptr<3>, i32
      nvvm.mbarrier.try_wait.parity.shared %489, %c0_i32, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      cute_nvgpu.arch.sm100.dealloc_tmem(%tmem_ptr, %c512_i32) [cta_2] : !cute.ptr<f32, tmem, align<16>>, i32
      cf.br ^bb157
    ^bb157:  // 2 preds: ^bb155, ^bb156
      return
    }
  }
  func.func @cutlass_host_function_Tensorgmemodiv8192i64div81921_Tensorgmemodiv8192i64div81921_Tensorgmemodiv8192i64div81921(%arg0: !memref_gmem_f16_, %arg1: !memref_gmem_f16_, %arg2: !memref_gmem_f16_) -> i32 attributes {llvm.emit_c_interface} {
    %c229632_i64 = arith.constant 229632 : i64
    %0 = llvm.mlir.constant(127 : i64) : i64
    %1 = llvm.mlir.constant(4539628424389459968 : i64) : i64
    %2 = llvm.mlir.constant(287506 : i64) : i64
    %c0_i32 = arith.constant 0 : i32
    %c2_i32 = arith.constant 2 : i32
    %c1_i32 = arith.constant 1 : i32
    %3 = cute.static : !cute.int_tuple<"2">
    %4 = cute.static : !cute.int_tuple<"1">
    %c256_i32 = arith.constant 256 : i32
    %c128_i32 = arith.constant 128 : i32
    %5 = cute.static : !cute.int_tuple<"(0,0)">
    %6 = cute.static : !cute.stride<"(1@1,1@0)">
    %c44_i64 = arith.constant 44 : i64
    %c40_i64 = arith.constant 40 : i64
    %c15_i64 = arith.constant 15 : i64
    %c36_i64 = arith.constant 36 : i64
    %c32_i64 = arith.constant 32 : i64
    %c21_i64 = arith.constant 21 : i64
    %c131072_i64 = arith.constant 131072 : i64
    %c9007199254740991_i64 = arith.constant 9007199254740991 : i64
    %c4_i64 = arith.constant 4 : i64
    %c4294967295_i64 = arith.constant 4294967295 : i64
    %c16_i64 = arith.constant 16 : i64
    %c8_i64 = arith.constant 8 : i64
    %c2_i64 = arith.constant 2 : i64
    %c1_i64 = arith.constant 1 : i64
    %c0_i64 = arith.constant 0 : i64
    %c16_i32 = arith.constant 16 : i32
    %false = arith.constant false
    %atom = cute.make_atom() : () -> !cute_nvgpu.sm100.mma<256x256x16, num_cta = 2, ab_major = (k, k), elem_type = (f16, f16, f32), frag_kind = ss, c_scale_exp = 0>
    %7 = cute_nvgpu.atom.set_value(%atom, %false : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !cute_nvgpu.sm100.mma<256x256x16, num_cta = 2, ab_major = (k, k), elem_type = (f16, f16, f32), frag_kind = ss, c_scale_exp = 0>
    %8 = cute_nvgpu.atom.set_value(%7, %false : i1) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : !cute_nvgpu.sm100.mma<256x256x16, num_cta = 2, ab_major = (k, k), elem_type = (f16, f16, f32), frag_kind = ss, c_scale_exp = 0>
    %9 = cute_nvgpu.atom.set_value(%8, %false : i1) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : !cute_nvgpu.sm100.mma<256x256x16, num_cta = 2, ab_major = (k, k), elem_type = (f16, f16, f32), frag_kind = ss, c_scale_exp = 0>
    %10 = cute.make_tiled_mma(%9) : !mma_f16_f16_f32_256x256x16_
    %11 = llvm.alloca %c16_i32 x i64 {alignment = 64 : i64} : (i32) -> !llvm.ptr
    %iter = cute.get_iter(%arg0) : !memref_gmem_f16_
    %lay = cute.get_layout(%arg0) : !memref_gmem_f16_
    %12:3 = cute.get_scalars(%lay) <{only_dynamic}> : !cute.layout<"(?,?{div=8192}):(?{i64 div=8192},1)">
    %13 = arith.extui %12#1 : i32 to i64
    %14 = arith.extui %12#0 : i32 to i64
    %15 = llvm.mul %12#2, %c2_i64 : i64
    %16 = cute.ptrtoint(%iter) : !cute.ptr<f16, gmem, align<32>> to i64
    %17 = llvm.getelementptr %11[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %17 : i64, !llvm.ptr
    %18 = llvm.getelementptr %11[0, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %18 : i64, !llvm.ptr
    %19 = llvm.getelementptr %11[0, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %19 : i64, !llvm.ptr
    %20 = llvm.getelementptr %11[0, 3] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %20 : i64, !llvm.ptr
    %21 = llvm.getelementptr %11[0, 4] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %21 : i64, !llvm.ptr
    %22 = llvm.getelementptr %11[0, 5] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %22 : i64, !llvm.ptr
    %23 = llvm.getelementptr %11[0, 6] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %23 : i64, !llvm.ptr
    %24 = llvm.getelementptr %11[0, 7] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %24 : i64, !llvm.ptr
    %25 = llvm.getelementptr %11[0, 8] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %25 : i64, !llvm.ptr
    %26 = llvm.getelementptr %11[0, 9] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %26 : i64, !llvm.ptr
    %27 = llvm.getelementptr %11[0, 10] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %27 : i64, !llvm.ptr
    %28 = llvm.getelementptr %11[0, 11] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %28 : i64, !llvm.ptr
    %29 = llvm.getelementptr %11[0, 12] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %29 : i64, !llvm.ptr
    %30 = llvm.getelementptr %11[0, 13] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %30 : i64, !llvm.ptr
    %31 = llvm.getelementptr %11[0, 14] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %31 : i64, !llvm.ptr
    %32 = llvm.getelementptr %11[0, 15] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %32 : i64, !llvm.ptr
    %33 = llvm.udiv %16, %c16_i64 : i64
    %34 = llvm.and %33, %c9007199254740991_i64 : i64
    %35 = llvm.shl %34, %c4_i64 : i64
    llvm.store %35, %17 : i64, !llvm.ptr
    %36 = llvm.sub %14, %c1_i64 : i64
    %37 = llvm.sub %c1_i64, %c1_i64 : i64
    %38 = llvm.mul %36, %15 : i64
    %39 = llvm.mul %37, %c0_i64 : i64
    %40 = llvm.add %38, %39 : i64
    %41 = llvm.add %39, %39 : i64
    %42 = llvm.mul %13, %c16_i64 : i64
    %43 = llvm.udiv %42, %c8_i64 : i64
    %44 = llvm.add %43, %40 : i64
    %45 = llvm.add %44, %41 : i64
    %46 = llvm.icmp "uge" %45, %c131072_i64 : i64
    %47 = llvm.zext %46 : i1 to i64
    %48 = llvm.shl %47, %c21_i64 : i64
    %49 = llvm.udiv %15, %c16_i64 : i64
    %50 = llvm.shl %49, %c32_i64 : i64
    %51 = llvm.or %c0_i64, %48 : i64
    %52 = llvm.or %51, %50 : i64
    %53 = llvm.or %2, %52 : i64
    llvm.store %53, %18 : i64, !llvm.ptr
    %54 = llvm.udiv %c0_i64, %c16_i64 : i64
    %55 = llvm.and %54, %c4294967295_i64 : i64
    %56 = llvm.shl %55, %c0_i64 : i64
    %57 = llvm.shl %54, %c32_i64 : i64
    %58 = llvm.or %56, %57 : i64
    llvm.store %58, %19 : i64, !llvm.ptr
    %59 = llvm.lshr %15, %c36_i64 : i64
    %60 = llvm.and %59, %c15_i64 : i64
    %61 = llvm.shl %60, %c32_i64 : i64
    %62 = llvm.lshr %c0_i64, %c36_i64 : i64
    %63 = llvm.and %62, %c15_i64 : i64
    %64 = llvm.shl %63, %c36_i64 : i64
    %65 = llvm.shl %63, %c40_i64 : i64
    %66 = llvm.shl %62, %c44_i64 : i64
    %67 = llvm.or %61, %64 : i64
    %68 = llvm.or %65, %66 : i64
    %69 = llvm.or %67, %68 : i64
    %70 = llvm.or %56, %69 : i64
    llvm.store %70, %20 : i64, !llvm.ptr
    %71 = llvm.sub %13, %c1_i64 : i64
    %72 = llvm.and %71, %c4294967295_i64 : i64
    %73 = llvm.shl %72, %c0_i64 : i64
    %74 = llvm.shl %36, %c32_i64 : i64
    %75 = llvm.or %73, %74 : i64
    llvm.store %75, %21 : i64, !llvm.ptr
    %76 = llvm.and %37, %c4294967295_i64 : i64
    %77 = llvm.shl %76, %c0_i64 : i64
    %78 = llvm.shl %37, %c32_i64 : i64
    %79 = llvm.or %77, %78 : i64
    llvm.store %79, %22 : i64, !llvm.ptr
    %80 = llvm.or %76, %c0_i64 : i64
    %81 = llvm.or %80, %1 : i64
    llvm.store %81, %23 : i64, !llvm.ptr
    llvm.store %0, %24 : i64, !llvm.ptr
    %82 = builtin.unrealized_conversion_cast %11 : !llvm.ptr to !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>>
    %83 = cute.ptrtoint(%82) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>> to i64
    %84 = llvm.inttoptr %83 : i64 to !llvm.ptr
    %85 = llvm.load %84 {nontemporal} : !llvm.ptr -> !llvm.struct<(array<16 x i64>)>
    %86 = builtin.unrealized_conversion_cast %85 : !llvm.struct<(array<16 x i64>)> to !cute_nvgpu.tma_descriptor_tiled
    %atom_0 = cute.make_atom() : () -> !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_100_2sm_multicast, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, internal_val_type = f16>
    %87 = cute_nvgpu.atom.set_value(%atom_0, %86 : !cute_nvgpu.tma_descriptor_tiled) {field = #cute_nvgpu.atom_copy_field_non_exec_tma_load<tma_desc>} : !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_100_2sm_multicast, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, internal_val_type = f16>
    %88 = cute.get_shape(%lay) : (!cute.layout<"(?,?{div=8192}):(?{i64 div=8192},1)">) -> !cute.shape<"(?,?{div=8192})">
    %lay_1 = cute.make_layout(%88, %6) : !cute.layout<"(?,?{div=8192}):(1@1,1@0)">
    %view = cute.make_view(%5, %lay_1) : !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">
    %89 = llvm.alloca %c16_i32 x i64 {alignment = 64 : i64} : (i32) -> !llvm.ptr
    %iter_2 = cute.get_iter(%arg1) : !memref_gmem_f16_
    %lay_3 = cute.get_layout(%arg1) : !memref_gmem_f16_
    %90:3 = cute.get_scalars(%lay_3) <{only_dynamic}> : !cute.layout<"(?,?{div=8192}):(?{i64 div=8192},1)">
    %91 = arith.extui %90#1 : i32 to i64
    %92 = arith.extui %90#0 : i32 to i64
    %93 = llvm.mul %90#2, %c2_i64 : i64
    %94 = cute.ptrtoint(%iter_2) : !cute.ptr<f16, gmem, align<32>> to i64
    %95 = llvm.getelementptr %89[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %95 : i64, !llvm.ptr
    %96 = llvm.getelementptr %89[0, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %96 : i64, !llvm.ptr
    %97 = llvm.getelementptr %89[0, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %97 : i64, !llvm.ptr
    %98 = llvm.getelementptr %89[0, 3] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %98 : i64, !llvm.ptr
    %99 = llvm.getelementptr %89[0, 4] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %99 : i64, !llvm.ptr
    %100 = llvm.getelementptr %89[0, 5] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %100 : i64, !llvm.ptr
    %101 = llvm.getelementptr %89[0, 6] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %101 : i64, !llvm.ptr
    %102 = llvm.getelementptr %89[0, 7] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %102 : i64, !llvm.ptr
    %103 = llvm.getelementptr %89[0, 8] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %103 : i64, !llvm.ptr
    %104 = llvm.getelementptr %89[0, 9] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %104 : i64, !llvm.ptr
    %105 = llvm.getelementptr %89[0, 10] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %105 : i64, !llvm.ptr
    %106 = llvm.getelementptr %89[0, 11] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %106 : i64, !llvm.ptr
    %107 = llvm.getelementptr %89[0, 12] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %107 : i64, !llvm.ptr
    %108 = llvm.getelementptr %89[0, 13] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %108 : i64, !llvm.ptr
    %109 = llvm.getelementptr %89[0, 14] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %109 : i64, !llvm.ptr
    %110 = llvm.getelementptr %89[0, 15] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %110 : i64, !llvm.ptr
    %111 = llvm.udiv %94, %c16_i64 : i64
    %112 = llvm.and %111, %c9007199254740991_i64 : i64
    %113 = llvm.shl %112, %c4_i64 : i64
    llvm.store %113, %95 : i64, !llvm.ptr
    %114 = llvm.sub %92, %c1_i64 : i64
    %115 = llvm.mul %114, %93 : i64
    %116 = llvm.add %115, %39 : i64
    %117 = llvm.mul %91, %c16_i64 : i64
    %118 = llvm.udiv %117, %c8_i64 : i64
    %119 = llvm.add %118, %116 : i64
    %120 = llvm.add %119, %41 : i64
    %121 = llvm.icmp "uge" %120, %c131072_i64 : i64
    %122 = llvm.zext %121 : i1 to i64
    %123 = llvm.shl %122, %c21_i64 : i64
    %124 = llvm.udiv %93, %c16_i64 : i64
    %125 = llvm.shl %124, %c32_i64 : i64
    %126 = llvm.or %c0_i64, %123 : i64
    %127 = llvm.or %126, %125 : i64
    %128 = llvm.or %2, %127 : i64
    llvm.store %128, %96 : i64, !llvm.ptr
    llvm.store %58, %97 : i64, !llvm.ptr
    %129 = llvm.lshr %93, %c36_i64 : i64
    %130 = llvm.and %129, %c15_i64 : i64
    %131 = llvm.shl %130, %c32_i64 : i64
    %132 = llvm.or %131, %64 : i64
    %133 = llvm.or %132, %68 : i64
    %134 = llvm.or %56, %133 : i64
    llvm.store %134, %98 : i64, !llvm.ptr
    %135 = llvm.sub %91, %c1_i64 : i64
    %136 = llvm.and %135, %c4294967295_i64 : i64
    %137 = llvm.shl %136, %c0_i64 : i64
    %138 = llvm.shl %114, %c32_i64 : i64
    %139 = llvm.or %137, %138 : i64
    llvm.store %139, %99 : i64, !llvm.ptr
    llvm.store %79, %100 : i64, !llvm.ptr
    llvm.store %81, %101 : i64, !llvm.ptr
    llvm.store %0, %102 : i64, !llvm.ptr
    %140 = builtin.unrealized_conversion_cast %89 : !llvm.ptr to !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>>
    %141 = cute.ptrtoint(%140) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>> to i64
    %142 = llvm.inttoptr %141 : i64 to !llvm.ptr
    %143 = llvm.load %142 {nontemporal} : !llvm.ptr -> !llvm.struct<(array<16 x i64>)>
    %144 = builtin.unrealized_conversion_cast %143 : !llvm.struct<(array<16 x i64>)> to !cute_nvgpu.tma_descriptor_tiled
    %145 = cute_nvgpu.atom.set_value(%atom_0, %144 : !cute_nvgpu.tma_descriptor_tiled) {field = #cute_nvgpu.atom_copy_field_non_exec_tma_load<tma_desc>} : !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_100_2sm_multicast, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, internal_val_type = f16>
    %146 = cute.get_shape(%lay_3) : (!cute.layout<"(?,?{div=8192}):(?{i64 div=8192},1)">) -> !cute.shape<"(?,?{div=8192})">
    %lay_4 = cute.make_layout(%146, %6) : !cute.layout<"(?,?{div=8192}):(1@1,1@0)">
    %view_5 = cute.make_view(%5, %lay_4) : !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">
    %lay_6 = cute.get_layout(%arg2) : !memref_gmem_f16_
    %147 = cute.get_shape(%lay_6) : (!cute.layout<"(?,?{div=8192}):(?{i64 div=8192},1)">) -> !cute.shape<"(?,?{div=8192})">
    %e0, %e1 = cute.get_leaves(%147) : !cute.shape<"(?,?{div=8192})">
    %itup = cute.to_int_tuple(%e0) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %itup_7 = cute.to_int_tuple(%e1) : !cute.shape<"?{div=8192}"> to !cute.int_tuple<"?{div=8192}">
    %int_tuple = cute.make_int_tuple(%itup, %itup_7) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8192}">) -> !cute.int_tuple<"(?,?{div=8192},1)">
    %148:2 = cute.get_scalars(%int_tuple) <{only_dynamic}> : !cute.int_tuple<"(?,?{div=8192},1)">
    %c1_i32_8 = arith.constant 1 : i32
    %c0_i32_9 = arith.constant 0 : i32
    %c-1_i32 = arith.constant -1 : i32
    %149 = arith.cmpi sgt, %c128_i32, %c0_i32_9 : i32
    %150 = arith.select %149, %c-1_i32, %c1_i32_8 : i32
    %151 = arith.addi %150, %148#0 : i32
    %152 = arith.divsi %151, %c128_i32 : i32
    %153 = arith.addi %c1_i32_8, %152 : i32
    %154 = arith.subi %c0_i32_9, %148#0 : i32
    %155 = arith.divsi %154, %c128_i32 : i32
    %156 = arith.subi %c0_i32_9, %155 : i32
    %157 = arith.cmpi slt, %148#0, %c0_i32_9 : i32
    %158 = arith.cmpi sgt, %148#0, %c0_i32_9 : i32
    %159 = arith.cmpi slt, %c128_i32, %c0_i32_9 : i32
    %160 = arith.cmpi sgt, %c128_i32, %c0_i32_9 : i32
    %161 = arith.andi %157, %159 : i1
    %162 = arith.andi %158, %160 : i1
    %163 = arith.ori %161, %162 : i1
    %164 = arith.select %163, %153, %156 : i32
    %c1_i32_10 = arith.constant 1 : i32
    %c0_i32_11 = arith.constant 0 : i32
    %c-1_i32_12 = arith.constant -1 : i32
    %165 = arith.cmpi sgt, %c256_i32, %c0_i32_11 : i32
    %166 = arith.select %165, %c-1_i32_12, %c1_i32_10 : i32
    %167 = arith.addi %166, %148#1 : i32
    %168 = arith.divsi %167, %c256_i32 : i32
    %169 = arith.addi %c1_i32_10, %168 : i32
    %170 = arith.subi %c0_i32_11, %148#1 : i32
    %171 = arith.divsi %170, %c256_i32 : i32
    %172 = arith.subi %c0_i32_11, %171 : i32
    %173 = arith.cmpi slt, %148#1, %c0_i32_11 : i32
    %174 = arith.cmpi sgt, %148#1, %c0_i32_11 : i32
    %175 = arith.cmpi slt, %c256_i32, %c0_i32_11 : i32
    %176 = arith.cmpi sgt, %c256_i32, %c0_i32_11 : i32
    %177 = arith.andi %173, %175 : i1
    %178 = arith.andi %174, %176 : i1
    %179 = arith.ori %177, %178 : i1
    %180 = arith.select %179, %169, %172 : i32
    %int_tuple_13 = cute.make_int_tuple(%164, %180) : (i32, i32) -> !cute.int_tuple<"(?,?,1)">
    %e0_14, %e1_15, %e2 = cute.get_leaves(%int_tuple_13) : !cute.int_tuple<"(?,?,1)">
    %tup = cute.add_offset(%e0_14, %3) : (!cute.int_tuple<"?">, !cute.int_tuple<"2">) -> !cute.int_tuple<"?">
    %sub = cute.tuple_sub(%tup, %4) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
    %div = cute.tuple_div(%sub, %3) : (!cute.int_tuple<"?">, !cute.int_tuple<"2">) -> !cute.int_tuple<"?">
    %mul = cute.tuple_mul(%div, %3) : (!cute.int_tuple<"?">, !cute.int_tuple<"2">) -> !cute.int_tuple<"?{div=2}">
    %181 = cute.get_scalars(%mul) : !cute.int_tuple<"?{div=2}">
    %tup_16 = cute.add_offset(%e1_15, %4) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
    %sub_17 = cute.tuple_sub(%tup_16, %4) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
    %div_18 = cute.tuple_div(%sub_17, %4) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
    %mul_19 = cute.tuple_mul(%div_18, %4) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
    %182 = cute.get_scalars(%mul_19) : !cute.int_tuple<"?">
    %183 = cuda.cast %c0_i64 : i64 -> !cuda.stream
    %184 = cuda.launch_cfg.create<max_attrs = 2 : i32> (blockDim = (%c128_i32, %c1_i32, %c1_i32), dynamicSmemBytes = %c229632_i64, gridDim = (%181, %182, %c1_i32), stream = %183) : i32, i32, i32, i64, i32, i32, i32, !cuda.stream -> !cuda.launch_cfg<max_attrs = 2>
    cuda.launch_cfg.cluster_dim[%184] (%c2_i32, %c1_i32, %c1_i32) : !cuda.launch_cfg<max_attrs = 2>, i32, i32, i32
    %185 = cuda.launch_ex @kernels::@kernel_cutlass_kernel_TiledMMA_ThrLayoutVMNK21111000_PermutationMNK____MMAAtom_ThrID21_ShapeMNK25625616_TVLayoutA2128161281256_TVLayoutB2128161281256_TVLayoutC21282561281256_CopyAtom_ThrI_0<%184> (%10, %87, %view, %145, %view_5, %arg2) : !cuda.launch_cfg<max_attrs = 2>, (!mma_f16_f16_f32_256x256x16_, !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_100_2sm_multicast, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, internal_val_type = f16>, !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">, !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_100_2sm_multicast, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, internal_val_type = f16>, !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">, !memref_gmem_f16_) -> !cuda.result
    %186 = cuda.cast %185 : !cuda.result -> i32
    cuda.return_if_error %186 : i32
    return %c0_i32 : i32
  }
}
