!memref_gmem_f16_ = !cute.memref<f16, gmem, align<32>, "(?,?{div=8192}):(?{i64 div=8192},1)">
!memref_rmem_f16_ = !cute.memref<f16, rmem, align<32>, "((64,1),1):((1,0),0)">
!memref_rmem_f32_ = !cute.memref<f32, rmem, align<32>, "((64,1),1):((1,0),0)">
!mma_f16_f16_f32_256x256x16_ = !cute.tiled_mma<!cute_nvgpu.sm100.mma<256x256x16, num_cta = 2, ab_major = (k, k), elem_type = (f16, f16, f32), frag_kind = ss, c_scale_exp = 0>, atom_layout_MNK = <"(1,1,1):(0,0,0)">>
#loop_unroll = #llvm.loop_unroll<disable = false, full = true>
#loop_annotation = #llvm.loop_annotation<unroll = #loop_unroll>
module attributes {gpu.container_module} {
  gpu.module @kernels {
    func.func public @kernel_cutlass_kernel_TiledMMA_ThrLayoutVMNK21111000_PermutationMNK____MMAAtom_ThrID21_ShapeMNK25625616_TVLayoutA2128161281256_TVLayoutB2128161281256_TVLayoutC21282561281256_CopyAtom_ThrI_0(%arg0: !mma_f16_f16_f32_256x256x16_, %arg1: !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_100_2sm_multicast, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, internal_val_type = f16>, %arg2: !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">, %arg3: !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_100_2sm_multicast, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, internal_val_type = f16>, %arg4: !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">, %arg5: !memref_gmem_f16_) attributes {cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} {
      %0 = builtin.unrealized_conversion_cast %arg0 : !mma_f16_f16_f32_256x256x16_ to !llvm.struct<(i1, i1, i1)>
      %c127_i32 = arith.constant 127 : i32
      %1 = cute.static : !cute.int_tuple<"8">
      %2 = cute.static : !cute.layout<"(8,(8)):(1,(8))">
      %3 = cute.static : !cute.layout<"((64,1),1,((1,4),1,1)):((1,0),0,((0,64),0,0))">
      %4 = cute.static : !cute.layout<"(((64,32),1),1,((1,4),1,1)):(((1,65536),0),0,((0,64),0,0))">
      %c4_i32 = arith.constant 4 : i32
      %c3_i16 = arith.constant 3 : i16
      %c14_i32 = arith.constant 14 : i32
      %c13_i32 = arith.constant 13 : i32
      %c272629776_i32 = arith.constant 272629776 : i32
      %5 = cute.static : !cute.layout<"(1,1,4,7):(0,0,2,1024)">
      %6 = cute.static : !cute.layout<"((8192,1),7):((1,0),8192)">
      %c65536_i32 = arith.constant 65536 : i32
      %c5_i32 = arith.constant 5 : i32
      %c7_i32 = arith.constant 7 : i32
      %c10000000_i32 = arith.constant 10000000 : i32
      %true = arith.constant true
      %c32_i64 = arith.constant 32 : i64
      %c2097152_i32 = arith.constant 2097152 : i32
      %7 = cute.static : !cute.shape<"(((128,64)),((1,4),1,1))">
      %c512_i32 = arith.constant 512 : i32
      %8 = cute.static : !cute.stride<"(((1@0,1@1),0),64@0)">
      %9 = cute.static : !cute.stride<"(((1@1,1@0),0,16@0),64@0)">
      %10 = cute.static : !cute.shape<"((128,256),1,1)">
      %c128_i64 = arith.constant 128 : i64
      %11 = cute.static : !cute.stride<"((1@1,1@0),0,16@0,64@0)">
      %12 = cute.static : !cute.shape<"(256,256)">
      %c256_i64 = arith.constant 256 : i64
      %13 = cute.static : !cute.int_tuple<"(0,0)">
      %14 = cute.static : !cute.stride<"(1@1,1@0,64@0)">
      %15 = cute.static : !cute.stride<"((1@1,1@0),(256@1,64@0))">
      %c64_i32 = arith.constant 64 : i32
      %c256_i32 = arith.constant 256 : i32
      %16 = cute.static : !cute.int_tuple<"7">
      %17 = cute.static : !cute.int_tuple<"6">
      %18 = cute.static : !cute.int_tuple<"5">
      %19 = cute.static : !cute.int_tuple<"4">
      %20 = cute.static : !cute.int_tuple<"3">
      %21 = cute.static : !cute.int_tuple<"2">
      %22 = cute.static : !cute.int_tuple<"1">
      %c0_i32 = arith.constant 0 : i32
      %23 = cute.static : !cute.int_tuple<"114688">
      %c-128_i32 = arith.constant -128 : i32
      %c1_i32 = arith.constant 1 : i32
      %c128_i32 = arith.constant 128 : i32
      %24 = cute.static : !cute.int_tuple<"136">
      %25 = cute.static : !cute.int_tuple<"128">
      %26 = cute.static : !cute.int_tuple<"112">
      %27 = cute.static : !cute.int_tuple<"144">
      %c2_i32 = arith.constant 2 : i32
      %c32_i32 = arith.constant 32 : i32
      %28 = cute.static : !cute.layout<"((2),1,1,1):((1),0,0,0)">
      %29 = nvvm.read.ptx.sreg.tid.x range <i32, 0, 1024> : i32
      %30 = nvvm.read.ptx.sreg.tid.y range <i32, 0, 1024> : i32
      %31 = nvvm.read.ptx.sreg.tid.z range <i32, 0, 64> : i32
      %32 = nvvm.read.ptx.sreg.ntid.x range <i32, 1, 1024> : i32
      %33 = nvvm.read.ptx.sreg.ntid.y range <i32, 1, 1024> : i32
      %34 = arith.muli %30, %32 : i32
      %35 = arith.addi %29, %34 : i32
      %36 = arith.muli %31, %32 : i32
      %37 = arith.muli %36, %33 : i32
      %38 = arith.addi %35, %37 : i32
      %39 = arith.divsi %38, %c32_i32 : i32
      %40 = arith.muli %39, %c32_i32 : i32
      %41 = arith.cmpi ne, %38, %40 : i32
      %c0_i32_0 = arith.constant 0 : i32
      %42 = arith.cmpi slt, %38, %c0_i32_0 : i32
      %43 = arith.cmpi slt, %c32_i32, %c0_i32_0 : i32
      %44 = arith.cmpi ne, %42, %43 : i1
      %45 = arith.andi %41, %44 : i1
      %c-1_i32 = arith.constant -1 : i32
      %46 = arith.addi %39, %c-1_i32 : i32
      %47 = arith.select %45, %46, %39 : i32
      %48 = cute_nvgpu.arch.make_warp_uniform(%47) : i32
      %49 = nvvm.read.ptx.sreg.ctaid.x range <i32, 0, 2147483647> : i32
      %50 = nvvm.read.ptx.sreg.ctaid.y range <i32, 0, 65535> : i32
      %51 = nvvm.read.ptx.sreg.cluster.ctarank : i32
      %52 = cute.get_flat_coord(%51, %28) : (i32, !cute.layout<"((2),1,1,1):((1),0,0,0)">) -> !cute.coord<"(?,0,0,0)">
      %e0, %e1, %e2, %e3 = cute.get_leaves(%52) : !cute.coord<"(?,0,0,0)">
      %itup = cute.to_int_tuple(%e0) : !cute.coord<"?"> to !cute.int_tuple<"?">
      %53 = arith.remsi %49, %c2_i32 : i32
      %54 = arith.divsi %49, %c2_i32 : i32
      %55 = arith.muli %54, %c2_i32 : i32
      %56 = arith.cmpi ne, %49, %55 : i32
      %c0_i32_1 = arith.constant 0 : i32
      %57 = arith.cmpi slt, %49, %c0_i32_1 : i32
      %58 = arith.cmpi slt, %c2_i32, %c0_i32_1 : i32
      %59 = arith.cmpi ne, %57, %58 : i1
      %60 = arith.andi %56, %59 : i1
      %c-1_i32_2 = arith.constant -1 : i32
      %61 = arith.addi %54, %c-1_i32_2 : i32
      %62 = arith.select %60, %61, %54 : i32
      %smem_ptr = cute_nvgpu.arch.get_dyn_smem() : !cute.ptr<i8, smem, align<1024>>
      %ptr = cute.add_offset(%smem_ptr, %27) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"144">) -> !cute.ptr<i8, smem, align<16>>
      %ptr_3 = cute.add_offset(%smem_ptr, %26) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"112">) -> !cute.ptr<i8, smem, align<16>>
      %ptr_4 = cute.add_offset(%smem_ptr, %25) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"128">) -> !cute.ptr<i8, smem, align<128>>
      %iter = cute.recast_iter(%ptr_4) : !cute.ptr<i8, smem, align<128>> to !cute.ptr<i64, smem, align<128>>
      %ptr_5 = cute.add_offset(%smem_ptr, %24) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"136">) -> !cute.ptr<i8, smem, align<8>>
      %iter_6 = cute.recast_iter(%ptr_5) : !cute.ptr<i8, smem, align<8>> to !cute.ptr<i32, smem, align<8>>
      %63 = cute.ptrtoint(%ptr) : !cute.ptr<i8, smem, align<16>> to i32
      %64 = arith.addi %63, %c127_i32 : i32
      %65 = arith.andi %64, %c-128_i32 : i32
      %66 = arith.extsi %65 : i32 to i64
      %iv = cute.assume(%66) : (i64) -> !cute.i64<divby 128>
      %67 = cute.inttoptr(%iv) : !cute.i64<divby 128> to !cute.ptr<i8, smem, align<128>>
      %ptr_7 = cute.add_offset(%67, %23) : (!cute.ptr<i8, smem, align<128>>, !cute.int_tuple<"114688">) -> !cute.ptr<i8, smem, align<128>>
      %iter_8 = cute.recast_iter(%67) : !cute.ptr<i8, smem, align<128>> to !cute.ptr<f16, smem, align<128>, S<3,4,3>>
      %iter_9 = cute.recast_iter(%ptr_7) : !cute.ptr<i8, smem, align<128>> to !cute.ptr<f16, smem, align<128>, S<3,4,3>>
      %68 = arith.cmpi eq, %48, %c0_i32 : i32
      cf.cond_br %68, ^bb1, ^bb2
    ^bb1:  // pred: ^bb0
      cute_nvgpu.prefetch_tma_desc(%arg1) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_100_2sm_multicast, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, internal_val_type = f16>) -> ()
      cute_nvgpu.prefetch_tma_desc(%arg3) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_100_2sm_multicast, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, internal_val_type = f16>) -> ()
      cf.br ^bb2
    ^bb2:  // 2 preds: ^bb0, ^bb1
      %iter_10 = cute.recast_iter(%smem_ptr) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<i64, smem, align<1024>>
      cf.cond_br %68, ^bb3, ^bb4
    ^bb3:  // pred: ^bb2
      %69 = builtin.unrealized_conversion_cast %iter_10 : !cute.ptr<i64, smem, align<1024>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %69, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_11 = cute.add_offset(%iter_10, %22) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"1">) -> !cute.ptr<i64, smem>
      %70 = builtin.unrealized_conversion_cast %ptr_11 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %70, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_12 = cute.add_offset(%iter_10, %21) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"2">) -> !cute.ptr<i64, smem, align<16>>
      %71 = builtin.unrealized_conversion_cast %ptr_12 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %71, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_13 = cute.add_offset(%iter_10, %20) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"3">) -> !cute.ptr<i64, smem>
      %72 = builtin.unrealized_conversion_cast %ptr_13 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %72, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_14 = cute.add_offset(%iter_10, %19) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"4">) -> !cute.ptr<i64, smem, align<32>>
      %73 = builtin.unrealized_conversion_cast %ptr_14 : !cute.ptr<i64, smem, align<32>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %73, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_15 = cute.add_offset(%iter_10, %18) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"5">) -> !cute.ptr<i64, smem>
      %74 = builtin.unrealized_conversion_cast %ptr_15 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %74, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_16 = cute.add_offset(%iter_10, %17) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"6">) -> !cute.ptr<i64, smem, align<16>>
      %75 = builtin.unrealized_conversion_cast %ptr_16 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %75, %c1_i32 : !llvm.ptr<3>, i32
      cf.br ^bb4
    ^bb4:  // 2 preds: ^bb2, ^bb3
      %ptr_17 = cute.add_offset(%iter_10, %16) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"7">) -> !cute.ptr<i64, smem>
      cf.cond_br %68, ^bb5, ^bb6
    ^bb5:  // pred: ^bb4
      %76 = builtin.unrealized_conversion_cast %ptr_17 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %76, %c1_i32 : !llvm.ptr<3>, i32
      %int_tuple = cute.make_int_tuple() : () -> !cute.int_tuple<"8">
      %ptr_18 = cute.add_offset(%iter_10, %int_tuple) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"8">) -> !cute.ptr<i64, smem, align<64>>
      %dyn = cute.derefine(%ptr_18) : !cute.ptr<i64, smem, align<64>> to !cute.ptr<i64, smem>
      %77 = builtin.unrealized_conversion_cast %dyn : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %77, %c1_i32 : !llvm.ptr<3>, i32
      %int_tuple_19 = cute.make_int_tuple() : () -> !cute.int_tuple<"9">
      %ptr_20 = cute.add_offset(%iter_10, %int_tuple_19) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"9">) -> !cute.ptr<i64, smem>
      %78 = builtin.unrealized_conversion_cast %ptr_20 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %78, %c1_i32 : !llvm.ptr<3>, i32
      %int_tuple_21 = cute.make_int_tuple() : () -> !cute.int_tuple<"10">
      %ptr_22 = cute.add_offset(%iter_10, %int_tuple_21) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"10">) -> !cute.ptr<i64, smem, align<16>>
      %dyn_23 = cute.derefine(%ptr_22) : !cute.ptr<i64, smem, align<16>> to !cute.ptr<i64, smem>
      %79 = builtin.unrealized_conversion_cast %dyn_23 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %79, %c1_i32 : !llvm.ptr<3>, i32
      %int_tuple_24 = cute.make_int_tuple() : () -> !cute.int_tuple<"11">
      %ptr_25 = cute.add_offset(%iter_10, %int_tuple_24) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"11">) -> !cute.ptr<i64, smem>
      %80 = builtin.unrealized_conversion_cast %ptr_25 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %80, %c1_i32 : !llvm.ptr<3>, i32
      %int_tuple_26 = cute.make_int_tuple() : () -> !cute.int_tuple<"12">
      %ptr_27 = cute.add_offset(%iter_10, %int_tuple_26) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"12">) -> !cute.ptr<i64, smem, align<32>>
      %dyn_28 = cute.derefine(%ptr_27) : !cute.ptr<i64, smem, align<32>> to !cute.ptr<i64, smem>
      %81 = builtin.unrealized_conversion_cast %dyn_28 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %81, %c1_i32 : !llvm.ptr<3>, i32
      %int_tuple_29 = cute.make_int_tuple() : () -> !cute.int_tuple<"13">
      %ptr_30 = cute.add_offset(%iter_10, %int_tuple_29) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"13">) -> !cute.ptr<i64, smem>
      %82 = builtin.unrealized_conversion_cast %ptr_30 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %82, %c1_i32 : !llvm.ptr<3>, i32
      cf.br ^bb6
    ^bb6:  // 2 preds: ^bb4, ^bb5
      %83 = cute_nvgpu.arch.make_warp_uniform(%51) : i32
      %84 = cute.get_flat_coord(%83, %28) : (i32, !cute.layout<"((2),1,1,1):((1),0,0,0)">) -> !cute.coord<"(?,0,0,0)">
      %e0_31, %e1_32, %e2_33, %e3_34 = cute.get_leaves(%84) : !cute.coord<"(?,0,0,0)">
      %itup_35 = cute.to_int_tuple(%e0_31) : !cute.coord<"?"> to !cute.int_tuple<"?">
      %85 = cute.get_scalars(%itup_35) : !cute.int_tuple<"?">
      %coord = cute.make_coord(%itup_35) : (!cute.int_tuple<"?">) -> !cute.coord<"(?,0,_,0)">
      %idx = cute.crd2idx(%coord, %28) : (!cute.coord<"(?,0,_,0)">, !cute.layout<"((2),1,1,1):((1),0,0,0)">) -> !cute.int_tuple<"?">
      %e0_36 = cute.get_leaves(%idx) : !cute.int_tuple<"?">
      %86 = cute.get_scalars(%e0_36) : !cute.int_tuple<"?">
      %87 = arith.shli %c1_i32, %86 : i32
      %88 = arith.trunci %87 : i32 to i16
      %coord_37 = cute.make_coord(%itup_35) : (!cute.int_tuple<"?">) -> !cute.coord<"(?,_,0,0)">
      %idx_38 = cute.crd2idx(%coord_37, %28) : (!cute.coord<"(?,_,0,0)">, !cute.layout<"((2),1,1,1):((1),0,0,0)">) -> !cute.int_tuple<"?">
      %e0_39 = cute.get_leaves(%idx_38) : !cute.int_tuple<"?">
      %89 = cute.get_scalars(%e0_39) : !cute.int_tuple<"?">
      %90 = arith.shli %c1_i32, %89 : i32
      %91 = arith.trunci %90 : i32 to i16
      %92 = arith.xori %85, %c1_i32 : i32
      %coord_40 = cute.make_coord(%92) : (i32) -> !cute.coord<"(?,0,_,0)">
      %idx_41 = cute.crd2idx(%coord_40, %28) : (!cute.coord<"(?,0,_,0)">, !cute.layout<"((2),1,1,1):((1),0,0,0)">) -> !cute.int_tuple<"?">
      %e0_42 = cute.get_leaves(%idx_41) : !cute.int_tuple<"?">
      %93 = cute.get_scalars(%e0_42) : !cute.int_tuple<"?">
      %94 = arith.shli %c1_i32, %93 : i32
      %95 = arith.trunci %94 : i32 to i16
      %coord_43 = cute.make_coord(%92) : (i32) -> !cute.coord<"(?,_,0,0)">
      %idx_44 = cute.crd2idx(%coord_43, %28) : (!cute.coord<"(?,_,0,0)">, !cute.layout<"((2),1,1,1):((1),0,0,0)">) -> !cute.int_tuple<"?">
      %e0_45 = cute.get_leaves(%idx_44) : !cute.int_tuple<"?">
      %96 = cute.get_scalars(%e0_45) : !cute.int_tuple<"?">
      %97 = arith.shli %c1_i32, %96 : i32
      %98 = arith.trunci %97 : i32 to i16
      %99 = arith.ori %88, %91 : i16
      %100 = arith.ori %99, %95 : i16
      %101 = arith.ori %100, %98 : i16
      %102 = arith.cmpi eq, %53, %c0_i32 : i32
      nvvm.fence.mbarrier.init
      nvvm.cluster.arrive
      nvvm.cluster.wait
      %iter_46 = cute.recast_iter(%ptr_3) : !cute.ptr<i8, smem, align<16>> to !cute.ptr<i64, smem, align<16>>
      cf.cond_br %68, ^bb7, ^bb8
    ^bb7:  // pred: ^bb6
      %103 = builtin.unrealized_conversion_cast %iter_46 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %103, %c1_i32 : !llvm.ptr<3>, i32
      cf.br ^bb8
    ^bb8:  // 2 preds: ^bb6, ^bb7
      %ptr_47 = cute.add_offset(%iter_46, %22) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"1">) -> !cute.ptr<i64, smem>
      cf.cond_br %68, ^bb9, ^bb10
    ^bb9:  // pred: ^bb8
      %104 = builtin.unrealized_conversion_cast %ptr_47 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %104, %c256_i32 : !llvm.ptr<3>, i32
      cf.br ^bb10
    ^bb10:  // 2 preds: ^bb8, ^bb9
      %105 = arith.divsi %83, %c2_i32 : i32
      %106 = arith.muli %105, %c2_i32 : i32
      %107 = arith.cmpi ne, %83, %106 : i32
      %c0_i32_48 = arith.constant 0 : i32
      %108 = arith.cmpi slt, %83, %c0_i32_48 : i32
      %109 = arith.cmpi slt, %c2_i32, %c0_i32_48 : i32
      %110 = arith.cmpi ne, %108, %109 : i1
      %111 = arith.andi %107, %110 : i1
      %c-1_i32_49 = arith.constant -1 : i32
      %112 = arith.addi %105, %c-1_i32_49 : i32
      %113 = arith.select %111, %112, %105 : i32
      %114 = arith.muli %113, %c2_i32 : i32
      nvvm.fence.mbarrier.init
      nvvm.cluster.arrive
      nvvm.cluster.wait
      %coord_50 = cute.make_coord(%62, %50) : (i32, i32) -> !cute.coord<"(?,?,_)">
      %115:2 = cute.get_scalars(%coord_50) <{only_dynamic}> : !cute.coord<"(?,?,_)">
      %coord_51 = cute.make_coord(%115#0) : (i32) -> !cute.coord<"((_,_),(?,_))">
      %lay = cute.get_layout(%arg2) : !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">
      %116:2 = cute.get_scalars(%lay) <{only_dynamic}> : !cute.layout<"(?,?{div=8192}):(1@1,1@0)">
      %c1_i32_52 = arith.constant 1 : i32
      %c0_i32_53 = arith.constant 0 : i32
      %c-1_i32_54 = arith.constant -1 : i32
      %117 = arith.cmpi sgt, %c256_i32, %c0_i32_53 : i32
      %118 = arith.select %117, %c-1_i32_54, %c1_i32_52 : i32
      %119 = arith.addi %118, %116#0 : i32
      %120 = arith.divsi %119, %c256_i32 : i32
      %121 = arith.addi %c1_i32_52, %120 : i32
      %122 = arith.subi %c0_i32_53, %116#0 : i32
      %123 = arith.divsi %122, %c256_i32 : i32
      %124 = arith.subi %c0_i32_53, %123 : i32
      %125 = arith.cmpi slt, %116#0, %c0_i32_53 : i32
      %126 = arith.cmpi sgt, %116#0, %c0_i32_53 : i32
      %127 = arith.cmpi slt, %c256_i32, %c0_i32_53 : i32
      %128 = arith.cmpi sgt, %c256_i32, %c0_i32_53 : i32
      %129 = arith.andi %125, %127 : i1
      %130 = arith.andi %126, %128 : i1
      %131 = arith.ori %129, %130 : i1
      %132 = arith.select %131, %121, %124 : i32
      %c1_i32_55 = arith.constant 1 : i32
      %c0_i32_56 = arith.constant 0 : i32
      %c-1_i32_57 = arith.constant -1 : i32
      %133 = arith.cmpi sgt, %c64_i32, %c0_i32_56 : i32
      %134 = arith.select %133, %c-1_i32_57, %c1_i32_55 : i32
      %135 = arith.addi %134, %116#1 : i32
      %136 = arith.divsi %135, %c64_i32 : i32
      %137 = arith.addi %c1_i32_55, %136 : i32
      %138 = arith.subi %c0_i32_56, %116#1 : i32
      %139 = arith.divsi %138, %c64_i32 : i32
      %140 = arith.subi %c0_i32_56, %139 : i32
      %141 = arith.cmpi slt, %116#1, %c0_i32_56 : i32
      %142 = arith.cmpi sgt, %116#1, %c0_i32_56 : i32
      %143 = arith.cmpi slt, %c64_i32, %c0_i32_56 : i32
      %144 = arith.cmpi sgt, %c64_i32, %c0_i32_56 : i32
      %145 = arith.andi %141, %143 : i1
      %146 = arith.andi %142, %144 : i1
      %147 = arith.ori %145, %146 : i1
      %148 = arith.select %147, %137, %140 : i32
      %shape = cute.make_shape(%132, %148) : (i32, i32) -> !cute.shape<"((256,64),(?,?))">
      %lay_58 = cute.make_layout(%shape, %15) : !cute.layout<"((256,64),(?,?)):((1@1,1@0),(256@1,64@0))">
      %149:2 = cute.get_scalars(%lay_58) <{only_dynamic}> : !cute.layout<"((256,64),(?,?)):((1@1,1@0),(256@1,64@0))">
      %shape_59 = cute.make_shape(%149#1) : (i32) -> !cute.shape<"(256,64,?)">
      %lay_60 = cute.make_layout(%shape_59, %14) : !cute.layout<"(256,64,?):(1@1,1@0,64@0)">
      %idx_61 = cute.crd2idx(%coord_51, %lay_58) : (!cute.coord<"((_,_),(?,_))">, !cute.layout<"((256,64),(?,?)):((1@1,1@0),(256@1,64@0))">) -> !cute.int_tuple<"(0,?{div=256})">
      %tup = cute.add_offset(%13, %idx_61) : (!cute.int_tuple<"(0,0)">, !cute.int_tuple<"(0,?{div=256})">) -> !cute.int_tuple<"(0,?{div=256})">
      %coord_62 = cute.make_coord(%115#1) : (i32) -> !cute.coord<"((_,_),(?,_))">
      %lay_63 = cute.get_layout(%arg4) : !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">
      %150:2 = cute.get_scalars(%lay_63) <{only_dynamic}> : !cute.layout<"(?,?{div=8192}):(1@1,1@0)">
      %c1_i32_64 = arith.constant 1 : i32
      %c0_i32_65 = arith.constant 0 : i32
      %c-1_i32_66 = arith.constant -1 : i32
      %151 = arith.cmpi sgt, %c256_i32, %c0_i32_65 : i32
      %152 = arith.select %151, %c-1_i32_66, %c1_i32_64 : i32
      %153 = arith.addi %152, %150#0 : i32
      %154 = arith.divsi %153, %c256_i32 : i32
      %155 = arith.addi %c1_i32_64, %154 : i32
      %156 = arith.subi %c0_i32_65, %150#0 : i32
      %157 = arith.divsi %156, %c256_i32 : i32
      %158 = arith.subi %c0_i32_65, %157 : i32
      %159 = arith.cmpi slt, %150#0, %c0_i32_65 : i32
      %160 = arith.cmpi sgt, %150#0, %c0_i32_65 : i32
      %161 = arith.cmpi slt, %c256_i32, %c0_i32_65 : i32
      %162 = arith.cmpi sgt, %c256_i32, %c0_i32_65 : i32
      %163 = arith.andi %159, %161 : i1
      %164 = arith.andi %160, %162 : i1
      %165 = arith.ori %163, %164 : i1
      %166 = arith.select %165, %155, %158 : i32
      %c1_i32_67 = arith.constant 1 : i32
      %c0_i32_68 = arith.constant 0 : i32
      %c-1_i32_69 = arith.constant -1 : i32
      %167 = arith.cmpi sgt, %c64_i32, %c0_i32_68 : i32
      %168 = arith.select %167, %c-1_i32_69, %c1_i32_67 : i32
      %169 = arith.addi %168, %150#1 : i32
      %170 = arith.divsi %169, %c64_i32 : i32
      %171 = arith.addi %c1_i32_67, %170 : i32
      %172 = arith.subi %c0_i32_68, %150#1 : i32
      %173 = arith.divsi %172, %c64_i32 : i32
      %174 = arith.subi %c0_i32_68, %173 : i32
      %175 = arith.cmpi slt, %150#1, %c0_i32_68 : i32
      %176 = arith.cmpi sgt, %150#1, %c0_i32_68 : i32
      %177 = arith.cmpi slt, %c64_i32, %c0_i32_68 : i32
      %178 = arith.cmpi sgt, %c64_i32, %c0_i32_68 : i32
      %179 = arith.andi %175, %177 : i1
      %180 = arith.andi %176, %178 : i1
      %181 = arith.ori %179, %180 : i1
      %182 = arith.select %181, %171, %174 : i32
      %shape_70 = cute.make_shape(%166, %182) : (i32, i32) -> !cute.shape<"((256,64),(?,?))">
      %lay_71 = cute.make_layout(%shape_70, %15) : !cute.layout<"((256,64),(?,?)):((1@1,1@0),(256@1,64@0))">
      %183:2 = cute.get_scalars(%lay_71) <{only_dynamic}> : !cute.layout<"((256,64),(?,?)):((1@1,1@0),(256@1,64@0))">
      %shape_72 = cute.make_shape(%183#1) : (i32) -> !cute.shape<"(256,64,?)">
      %lay_73 = cute.make_layout(%shape_72, %14) : !cute.layout<"(256,64,?):(1@1,1@0,64@0)">
      %idx_74 = cute.crd2idx(%coord_62, %lay_71) : (!cute.coord<"((_,_),(?,_))">, !cute.layout<"((256,64),(?,?)):((1@1,1@0),(256@1,64@0))">) -> !cute.int_tuple<"(0,?{div=256})">
      %tup_75 = cute.add_offset(%13, %idx_74) : (!cute.int_tuple<"(0,0)">, !cute.int_tuple<"(0,?{div=256})">) -> !cute.int_tuple<"(0,?{div=256})">
      %coord_76 = cute.make_coord(%115#0, %115#1) : (i32, i32) -> !cute.coord<"((_,_),(?,?))">
      %lay_77 = cute.get_layout(%arg5) : !memref_gmem_f16_
      %184:3 = cute.get_scalars(%lay_77) <{only_dynamic}> : !cute.layout<"(?,?{div=8192}):(?{i64 div=8192},1)">
      %c1_i32_78 = arith.constant 1 : i32
      %c0_i32_79 = arith.constant 0 : i32
      %c-1_i32_80 = arith.constant -1 : i32
      %185 = arith.cmpi sgt, %c256_i32, %c0_i32_79 : i32
      %186 = arith.select %185, %c-1_i32_80, %c1_i32_78 : i32
      %187 = arith.addi %186, %184#0 : i32
      %188 = arith.divsi %187, %c256_i32 : i32
      %189 = arith.addi %c1_i32_78, %188 : i32
      %190 = arith.subi %c0_i32_79, %184#0 : i32
      %191 = arith.divsi %190, %c256_i32 : i32
      %192 = arith.subi %c0_i32_79, %191 : i32
      %193 = arith.cmpi slt, %184#0, %c0_i32_79 : i32
      %194 = arith.cmpi sgt, %184#0, %c0_i32_79 : i32
      %195 = arith.cmpi slt, %c256_i32, %c0_i32_79 : i32
      %196 = arith.cmpi sgt, %c256_i32, %c0_i32_79 : i32
      %197 = arith.andi %193, %195 : i1
      %198 = arith.andi %194, %196 : i1
      %199 = arith.ori %197, %198 : i1
      %200 = arith.select %199, %189, %192 : i32
      %201 = arith.muli %184#2, %c256_i64 : i64
      %c1_i32_81 = arith.constant 1 : i32
      %c0_i32_82 = arith.constant 0 : i32
      %c-1_i32_83 = arith.constant -1 : i32
      %202 = arith.cmpi sgt, %c256_i32, %c0_i32_82 : i32
      %203 = arith.select %202, %c-1_i32_83, %c1_i32_81 : i32
      %204 = arith.addi %203, %184#1 : i32
      %205 = arith.divsi %204, %c256_i32 : i32
      %206 = arith.addi %c1_i32_81, %205 : i32
      %207 = arith.subi %c0_i32_82, %184#1 : i32
      %208 = arith.divsi %207, %c256_i32 : i32
      %209 = arith.subi %c0_i32_82, %208 : i32
      %210 = arith.cmpi slt, %184#1, %c0_i32_82 : i32
      %211 = arith.cmpi sgt, %184#1, %c0_i32_82 : i32
      %212 = arith.cmpi slt, %c256_i32, %c0_i32_82 : i32
      %213 = arith.cmpi sgt, %c256_i32, %c0_i32_82 : i32
      %214 = arith.andi %210, %212 : i1
      %215 = arith.andi %211, %213 : i1
      %216 = arith.ori %214, %215 : i1
      %217 = arith.select %216, %206, %209 : i32
      %shape_84 = cute.make_shape(%200, %217) : (i32, i32) -> !cute.shape<"((256,256),(?,?))">
      %iv_85 = cute.assume(%184#2) : (i64) -> !cute.i64<divby 8192>
      %iv_86 = cute.assume(%201) : (i64) -> !cute.i64<divby 2097152>
      %stride = cute.make_stride(%iv_85, %iv_86) : (!cute.i64<divby 8192>, !cute.i64<divby 2097152>) -> !cute.stride<"((?{i64 div=8192},1),(?{i64 div=2097152},256))">
      %lay_87 = cute.make_layout(%shape_84, %stride) : !cute.layout<"((256,256),(?,?)):((?{i64 div=8192},1),(?{i64 div=2097152},256))">
      %218:4 = cute.get_scalars(%lay_87) <{only_dynamic}> : !cute.layout<"((256,256),(?,?)):((?{i64 div=8192},1),(?{i64 div=2097152},256))">
      %iv_88 = cute.assume(%218#2) : (i64) -> !cute.i64<divby 8192>
      %stride_89 = cute.make_stride(%iv_88) : (!cute.i64<divby 8192>) -> !cute.stride<"(?{i64 div=8192},1)">
      %lay_90 = cute.make_layout(%12, %stride_89) : !cute.layout<"(256,256):(?{i64 div=8192},1)">
      %idx_91 = cute.crd2idx(%coord_76, %lay_87) : (!cute.coord<"((_,_),(?,?))">, !cute.layout<"((256,256),(?,?)):((?{i64 div=8192},1),(?{i64 div=2097152},256))">) -> !cute.int_tuple<"?{i64 div=256}">
      %iter_92 = cute.get_iter(%arg5) : !memref_gmem_f16_
      %ptr_93 = cute.add_offset(%iter_92, %idx_91) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{i64 div=256}">) -> !cute.ptr<f16, gmem, align<32>>
      %coord_94 = cute.make_coord(%53) : (i32) -> !cute.coord<"?">
      %219 = cute.get_scalars(%lay_60) <{only_dynamic}> : !cute.layout<"(256,64,?):(1@1,1@0,64@0)">
      %220 = cute.get_scalars(%coord_94) <{only_dynamic}> : !cute.coord<"?">
      %221 = arith.remsi %220, %c2_i32 : i32
      %222 = arith.remsi %221, %c2_i32 : i32
      %223 = arith.muli %222, %c128_i32 : i32
      %iv_95 = cute.assume(%223) : (i32) -> !cute.i32<divby 128>
      %int_tuple_96 = cute.make_int_tuple(%iv_95) : (!cute.i32<divby 128>) -> !cute.int_tuple<"(0,?{div=128})">
      %tup_97 = cute.add_offset(%tup, %int_tuple_96) : (!cute.int_tuple<"(0,?{div=256})">, !cute.int_tuple<"(0,?{div=128})">) -> !cute.int_tuple<"(0,?{div=128})">
      %shape_98 = cute.make_shape(%219) : (i32) -> !cute.shape<"((128,16),1,4,?)">
      %lay_99 = cute.make_layout(%shape_98, %11) : !cute.layout<"((128,16),1,4,?):((1@1,1@0),0,16@0,64@0)">
      %224 = cute.get_scalars(%lay_73) <{only_dynamic}> : !cute.layout<"(256,64,?):(1@1,1@0,64@0)">
      %tup_100 = cute.add_offset(%tup_75, %int_tuple_96) : (!cute.int_tuple<"(0,?{div=256})">, !cute.int_tuple<"(0,?{div=128})">) -> !cute.int_tuple<"(0,?{div=128})">
      %shape_101 = cute.make_shape(%224) : (i32) -> !cute.shape<"((128,16),1,4,?)">
      %lay_102 = cute.make_layout(%shape_101, %11) : !cute.layout<"((128,16),1,4,?):((1@1,1@0),0,16@0,64@0)">
      %225 = cute.get_scalars(%lay_90) <{only_dynamic}> : !cute.layout<"(256,256):(?{i64 div=8192},1)">
      %226 = arith.muli %225, %c128_i64 : i64
      %227 = arith.extsi %222 : i32 to i64
      %228 = arith.muli %227, %226 : i64
      %iv_103 = cute.assume(%228) : (i64) -> !cute.i64<divby 1048576>
      %int_tuple_104 = cute.make_int_tuple(%iv_103) : (!cute.i64<divby 1048576>) -> !cute.int_tuple<"?{i64 div=1048576}">
      %ptr_105 = cute.add_offset(%ptr_93, %int_tuple_104) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{i64 div=1048576}">) -> !cute.ptr<f16, gmem, align<32>>
      %iv_106 = cute.assume(%225) : (i64) -> !cute.i64<divby 8192>
      %stride_107 = cute.make_stride(%iv_106) : (!cute.i64<divby 8192>) -> !cute.stride<"((?{i64 div=8192},1),0,0)">
      %lay_108 = cute.make_layout(%10, %stride_107) : !cute.layout<"((128,256),1,1):((?{i64 div=8192},1),0,0)">
      %ummaSmemDesc = cute_nvgpu.make_umma_smem_desc(%iter_8 : !cute.ptr<f16, smem, align<128>, S<3,4,3>>) layout = <"((128,16),1,4,7):((64,1),0,16,8192)">, major = <k> -> !cute_nvgpu.smem_desc
      %ummaSmemDesc_109 = cute_nvgpu.make_umma_smem_desc(%iter_9 : !cute.ptr<f16, smem, align<128>, S<3,4,3>>) layout = <"((128,16),1,4,7):((64,1),0,16,8192)">, major = <k> -> !cute_nvgpu.smem_desc
      %229 = cute.get_scalars(%lay_99) <{only_dynamic}> : !cute.layout<"((128,16),1,4,?):((1@1,1@0),0,16@0,64@0)">
      %shape_110 = cute.make_shape(%229) : (i32) -> !cute.shape<"(((128,16),1,4),?)">
      %lay_111 = cute.make_layout(%shape_110, %9) : !cute.layout<"(((128,16),1,4),?):(((1@1,1@0),0,16@0),64@0)">
      %230 = cute.get_scalars(%lay_111) <{only_dynamic}> : !cute.layout<"(((128,16),1,4),?):(((1@1,1@0),0,16@0),64@0)">
      %shape_112 = cute.make_shape(%230) : (i32) -> !cute.shape<"(((64,128),1),?)">
      %lay_113 = cute.make_layout(%shape_112, %8) : !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">
      %231 = cute.get_scalars(%lay_102) <{only_dynamic}> : !cute.layout<"((128,16),1,4,?):((1@1,1@0),0,16@0,64@0)">
      %shape_114 = cute.make_shape(%231) : (i32) -> !cute.shape<"(((128,16),1,4),?)">
      %lay_115 = cute.make_layout(%shape_114, %9) : !cute.layout<"(((128,16),1,4),?):(((1@1,1@0),0,16@0),64@0)">
      %232 = cute.get_scalars(%lay_115) <{only_dynamic}> : !cute.layout<"(((128,16),1,4),?):(((1@1,1@0),0,16@0),64@0)">
      %shape_116 = cute.make_shape(%232) : (i32) -> !cute.shape<"(((64,128),1),?)">
      %lay_117 = cute.make_layout(%shape_116, %8) : !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">
      %coord_118 = cute.make_coord(%itup) : (!cute.int_tuple<"?">) -> !cute.coord<"(?,0,_,0)">
      %idx_119 = cute.crd2idx(%coord_118, %28) : (!cute.coord<"(?,0,_,0)">, !cute.layout<"((2),1,1,1):((1),0,0,0)">) -> !cute.int_tuple<"?">
      %e0_120 = cute.get_leaves(%idx_119) : !cute.int_tuple<"?">
      %233 = cute.get_scalars(%e0_120) : !cute.int_tuple<"?">
      %234 = arith.shli %c1_i32, %233 : i32
      %235 = arith.trunci %234 : i32 to i16
      %coord_121 = cute.make_coord(%itup) : (!cute.int_tuple<"?">) -> !cute.coord<"(?,_,0,0)">
      %idx_122 = cute.crd2idx(%coord_121, %28) : (!cute.coord<"(?,_,0,0)">, !cute.layout<"((2),1,1,1):((1),0,0,0)">) -> !cute.int_tuple<"?">
      %e0_123 = cute.get_leaves(%idx_122) : !cute.int_tuple<"?">
      %236 = cute.get_scalars(%e0_123) : !cute.int_tuple<"?">
      %237 = arith.shli %c1_i32, %236 : i32
      %238 = arith.trunci %237 : i32 to i16
      cf.cond_br %68, ^bb11, ^bb14
    ^bb11:  // pred: ^bb10
      %239 = nvvm.elect.sync -> i1
      cf.cond_br %239, ^bb12, ^bb13
    ^bb12:  // pred: ^bb11
      %240 = builtin.unrealized_conversion_cast %iter : !cute.ptr<i64, smem, align<128>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %240, %c32_i32 : !llvm.ptr<3>, i32
      cf.br ^bb13
    ^bb13:  // 2 preds: ^bb11, ^bb12
      cf.br ^bb14
    ^bb14:  // 2 preds: ^bb10, ^bb13
      nvvm.fence.mbarrier.init
      cf.cond_br %68, ^bb15, ^bb16
    ^bb15:  // pred: ^bb14
      cute_nvgpu.arch.sm100.alloc_tmem(%c512_i32, %iter_6) [cta_2] : i32, !cute.ptr<i32, smem, align<8>>
      cf.br ^bb16
    ^bb16:  // 2 preds: ^bb14, ^bb15
      nvvm.barrier id = %c1_i32 number_of_threads = %c128_i32
      %tmem_ptr = cute_nvgpu.arch.sm100.retrieve_tmem_ptr(%iter_6) : !cute.ptr<i32, smem, align<8>> -> !cute.ptr<f32, tmem, align<16>>
      %241 = cute.get_scalars(%lay_108) <{only_dynamic}> : !cute.layout<"((128,256),1,1):((?{i64 div=8192},1),0,0)">
      %iv_124 = cute.assume(%241) : (i64) -> !cute.i64<divby 8192>
      %stride_125 = cute.make_stride(%iv_124) : (!cute.i64<divby 8192>) -> !cute.stride<"(((?{i64 div=8192},1)),((0,64),0,0))">
      %lay_126 = cute.make_layout(%7, %stride_125) : !cute.layout<"(((128,64)),((1,4),1,1)):(((?{i64 div=8192},1)),((0,64),0,0))">
      %coord_127 = cute.make_coord(%29) : (i32) -> !cute.coord<"?">
      %242 = cute.get_scalars(%coord_127) <{only_dynamic}> : !cute.coord<"?">
      %243 = arith.divsi %242, %c32_i32 : i32
      %244 = arith.muli %243, %c2097152_i32 : i32
      %iv_128 = cute.assume(%244) : (i32) -> !cute.i32<divby 2097152>
      %int_tuple_129 = cute.make_int_tuple(%iv_128) : (!cute.i32<divby 2097152>) -> !cute.int_tuple<"?{div=2097152}">
      %ptr_130 = cute.add_offset(%tmem_ptr, %int_tuple_129) : (!cute.ptr<f32, tmem, align<16>>, !cute.int_tuple<"?{div=2097152}">) -> !cute.ptr<f32, tmem, align<16>>
      %245 = cute.get_scalars(%lay_126) <{only_dynamic}> : !cute.layout<"(((128,64)),((1,4),1,1)):(((?{i64 div=8192},1)),((0,64),0,0))">
      %246 = arith.muli %245, %c32_i64 : i64
      %247 = arith.remsi %242, %c32_i32 : i32
      %248 = arith.extsi %247 : i32 to i64
      %249 = arith.muli %248, %245 : i64
      %250 = arith.extsi %243 : i32 to i64
      %251 = arith.muli %250, %246 : i64
      %252 = arith.addi %249, %251 : i64
      %iv_131 = cute.assume(%252) : (i64) -> !cute.i64<divby 8192>
      %int_tuple_132 = cute.make_int_tuple(%iv_131) : (!cute.i64<divby 8192>) -> !cute.int_tuple<"?{i64 div=8192}">
      %ptr_133 = cute.add_offset(%ptr_105, %int_tuple_132) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{i64 div=8192}">) -> !cute.ptr<f16, gmem, align<32>>
      %rmem = cute.memref.alloca() : !memref_rmem_f32_
      %rmem_134 = cute.memref.alloca() : !memref_rmem_f16_
      %sz = cute.size(%lay_60) <{mode = [2]}> : (!cute.layout<"(256,64,?):(1@1,1@0,64@0)">) -> !cute.int_tuple<"?">
      %e0_135 = cute.get_leaves(%sz) : !cute.int_tuple<"?">
      %253 = cute.get_scalars(%e0_135) : !cute.int_tuple<"?">
      cf.cond_br %68, ^bb17, ^bb108
    ^bb17:  // pred: ^bb16
      %254 = arith.cmpi ne, %53, %c0_i32 : i32
      %255 = arith.extui %254 : i1 to i32
      cf.cond_br %102, ^bb18, ^bb19
    ^bb18:  // pred: ^bb17
      %256 = builtin.unrealized_conversion_cast %ptr_47 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %256, %c1_i32, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      cf.br ^bb19
    ^bb19:  // 2 preds: ^bb17, ^bb18
      %257 = cute_nvgpu.atom.make_exec_tma(%arg1) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_100_2sm_multicast, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>
      %258 = cute_nvgpu.atom.set_value(%257, %235 : i16) {field = #cute_nvgpu.atom_copy_field_tmaload<mcast_mask>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>
      %259 = cute_nvgpu.atom.make_exec_tma(%arg3) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_100_2sm_multicast, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>
      %260 = cute_nvgpu.atom.set_value(%259, %238 : i16) {field = #cute_nvgpu.atom_copy_field_tmaload<mcast_mask>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>
      %261 = arith.cmpi slt, %253, %c5_i32 : i32
      %262 = arith.select %261, %253, %c5_i32 : i32
      %263 = cute.get_scalars(%22) : !cute.int_tuple<"1">
      cf.br ^bb20(%c0_i32, %c0_i32, %c1_i32, %c0_i32 : i32, i32, i32, i32)
    ^bb20(%264: i32, %265: i32, %266: i32, %267: i32):  // 2 preds: ^bb19, ^bb35
      %268 = arith.cmpi slt, %264, %262 : i32
      cf.cond_br %268, ^bb21, ^bb36
    ^bb21:  // pred: ^bb20
      %int_tuple_136 = cute.make_int_tuple(%265) : (i32) -> !cute.int_tuple<"?">
      %ptr_137 = cute.add_offset(%ptr_17, %int_tuple_136) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %269 = builtin.unrealized_conversion_cast %ptr_137 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %269, %266, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      cf.cond_br %102, ^bb22, ^bb25
    ^bb22:  // pred: ^bb21
      %270 = nvvm.elect.sync -> i1
      cf.cond_br %270, ^bb23, ^bb24
    ^bb23:  // pred: ^bb22
      %ptr_138 = cute.add_offset(%iter_10, %int_tuple_136) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %271 = builtin.unrealized_conversion_cast %ptr_138 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %271, %c65536_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
      cf.br ^bb24
    ^bb24:  // 2 preds: ^bb22, ^bb23
      cf.br ^bb25
    ^bb25:  // 2 preds: ^bb21, ^bb24
      %272 = arith.addi %265, %c1_i32 : i32
      %273 = arith.addi %267, %c1_i32 : i32
      %274 = arith.cmpi eq, %272, %c7_i32 : i32
      %275 = arith.select %274, %c0_i32, %272 : i32
      cf.cond_br %274, ^bb26, ^bb27
    ^bb26:  // pred: ^bb25
      %276 = arith.xori %266, %c1_i32 : i32
      cf.br ^bb28(%276 : i32)
    ^bb27:  // pred: ^bb25
      cf.br ^bb28(%266 : i32)
    ^bb28(%277: i32):  // 2 preds: ^bb26, ^bb27
      cf.br ^bb29
    ^bb29:  // pred: ^bb28
      %coord_139 = cute.make_coord(%267) : (i32) -> !cute.coord<"(_,?)">
      %idx_140 = cute.crd2idx(%coord_139, %lay_113) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
      %tup_141 = cute.add_offset(%tup_97, %idx_140) : (!cute.int_tuple<"(0,?{div=128})">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
      %e0_142, %e1_143 = cute.get_leaves(%tup_141) : !cute.int_tuple<"(?{div=64},?{div=128})">
      %coord_144 = cute.make_coord(%265) : (i32) -> !cute.coord<"(_,?)">
      %idx_145 = cute.crd2idx(%coord_144, %6) : (!cute.coord<"(_,?)">, !cute.layout<"((8192,1),7):((1,0),8192)">) -> !cute.int_tuple<"?{div=8192}">
      %ptr_146 = cute.add_offset(%iter_8, %idx_145) : (!cute.ptr<f16, smem, align<128>, S<3,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<f16, smem, align<128>, S<3,4,3>>
      %ptr_147 = cute.add_offset(%iter_10, %int_tuple_136) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %int_tuple_148 = cute.make_int_tuple(%e0_142, %e1_143) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=128}">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
      %278 = cute_nvgpu.atom.set_value(%258, %ptr_147 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>
      %279 = cute_nvgpu.atom.get_value(%278 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
      %280 = cute_nvgpu.atom.get_value(%278 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<mcast_mask>} : i16
      %TMADescAddr = cute_nvgpu.get_tma_desc_addr(%278 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) -> !cute.ptr<generic, align<64>>
      %281:2 = cute.get_scalars(%int_tuple_148) : !cute.int_tuple<"(?{div=64},?{div=128})">
      cf.br ^bb30(%c0_i32 : i32)
    ^bb30(%282: i32):  // 2 preds: ^bb29, ^bb31
      %283 = arith.cmpi slt, %282, %263 : i32
      cf.cond_br %283, ^bb31, ^bb32 {llvm.loop_annotation = #loop_annotation}
    ^bb31:  // pred: ^bb30
      cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr : !cute.ptr<generic, align<64>>, %ptr_146 : !cute.ptr<f16, smem, align<128>, S<3,4,3>>, %279 : !cute.ptr<smem, align<8>>, [%281#0, %281#1] : i32, i32) mask = %280 mode = <tiled> num_cta = 2 : i32
      %284 = arith.addi %282, %c1_i32 : i32
      cf.br ^bb30(%284 : i32)
    ^bb32:  // pred: ^bb30
      %idx_149 = cute.crd2idx(%coord_139, %lay_117) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
      %tup_150 = cute.add_offset(%tup_100, %idx_149) : (!cute.int_tuple<"(0,?{div=128})">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
      %e0_151, %e1_152 = cute.get_leaves(%tup_150) : !cute.int_tuple<"(?{div=64},?{div=128})">
      %ptr_153 = cute.add_offset(%iter_9, %idx_145) : (!cute.ptr<f16, smem, align<128>, S<3,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<f16, smem, align<128>, S<3,4,3>>
      %int_tuple_154 = cute.make_int_tuple(%e0_151, %e1_152) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=128}">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
      %285 = cute_nvgpu.atom.set_value(%260, %ptr_147 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>
      %286 = cute_nvgpu.atom.get_value(%285 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
      %287 = cute_nvgpu.atom.get_value(%285 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<mcast_mask>} : i16
      %TMADescAddr_155 = cute_nvgpu.get_tma_desc_addr(%285 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) -> !cute.ptr<generic, align<64>>
      %288:2 = cute.get_scalars(%int_tuple_154) : !cute.int_tuple<"(?{div=64},?{div=128})">
      cf.br ^bb33(%c0_i32 : i32)
    ^bb33(%289: i32):  // 2 preds: ^bb32, ^bb34
      %290 = arith.cmpi slt, %289, %263 : i32
      cf.cond_br %290, ^bb34, ^bb35 {llvm.loop_annotation = #loop_annotation}
    ^bb34:  // pred: ^bb33
      cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr_155 : !cute.ptr<generic, align<64>>, %ptr_153 : !cute.ptr<f16, smem, align<128>, S<3,4,3>>, %286 : !cute.ptr<smem, align<8>>, [%288#0, %288#1] : i32, i32) mask = %287 mode = <tiled> num_cta = 2 : i32
      %291 = arith.addi %289, %c1_i32 : i32
      cf.br ^bb33(%291 : i32)
    ^bb35:  // pred: ^bb33
      %292 = arith.addi %264, %c1_i32 : i32
      cf.br ^bb20(%292, %275, %277, %273 : i32, i32, i32, i32)
    ^bb36:  // pred: ^bb20
      cf.br ^bb37(%c0_i32, %267, %265, %266, %c0_i32, %c0_i32, %c0_i32, %0 : i32, i32, i32, i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>)
    ^bb37(%293: i32, %294: i32, %295: i32, %296: i32, %297: i32, %298: i32, %299: i32, %300: !llvm.struct<(i1, i1, i1)>):  // 2 preds: ^bb36, ^bb102
      %301 = arith.cmpi slt, %293, %253 : i32
      cf.cond_br %301, ^bb38, ^bb103
    ^bb38:  // pred: ^bb37
      %302 = builtin.unrealized_conversion_cast %300 : !llvm.struct<(i1, i1, i1)> to !mma_f16_f16_f32_256x256x16_
      %303 = arith.addi %293, %262 : i32
      %304 = arith.cmpi ult, %303, %253 : i32
      cf.cond_br %304, ^bb39, ^bb54
    ^bb39:  // pred: ^bb38
      %int_tuple_156 = cute.make_int_tuple(%295) : (i32) -> !cute.int_tuple<"?">
      %ptr_157 = cute.add_offset(%ptr_17, %int_tuple_156) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %305 = builtin.unrealized_conversion_cast %ptr_157 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %305, %296, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      cf.cond_br %102, ^bb40, ^bb43
    ^bb40:  // pred: ^bb39
      %306 = nvvm.elect.sync -> i1
      cf.cond_br %306, ^bb41, ^bb42
    ^bb41:  // pred: ^bb40
      %ptr_158 = cute.add_offset(%iter_10, %int_tuple_156) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %307 = builtin.unrealized_conversion_cast %ptr_158 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %307, %c65536_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
      cf.br ^bb42
    ^bb42:  // 2 preds: ^bb40, ^bb41
      cf.br ^bb43
    ^bb43:  // 2 preds: ^bb39, ^bb42
      %308 = arith.addi %295, %c1_i32 : i32
      %309 = arith.addi %294, %c1_i32 : i32
      %310 = arith.cmpi eq, %308, %c7_i32 : i32
      %311 = arith.select %310, %c0_i32, %308 : i32
      cf.cond_br %310, ^bb44, ^bb45
    ^bb44:  // pred: ^bb43
      %312 = arith.xori %296, %c1_i32 : i32
      cf.br ^bb46(%312 : i32)
    ^bb45:  // pred: ^bb43
      cf.br ^bb46(%296 : i32)
    ^bb46(%313: i32):  // 2 preds: ^bb44, ^bb45
      cf.br ^bb47
    ^bb47:  // pred: ^bb46
      %coord_159 = cute.make_coord(%294) : (i32) -> !cute.coord<"(_,?)">
      %idx_160 = cute.crd2idx(%coord_159, %lay_113) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
      %tup_161 = cute.add_offset(%tup_97, %idx_160) : (!cute.int_tuple<"(0,?{div=128})">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
      %e0_162, %e1_163 = cute.get_leaves(%tup_161) : !cute.int_tuple<"(?{div=64},?{div=128})">
      %coord_164 = cute.make_coord(%295) : (i32) -> !cute.coord<"(_,?)">
      %idx_165 = cute.crd2idx(%coord_164, %6) : (!cute.coord<"(_,?)">, !cute.layout<"((8192,1),7):((1,0),8192)">) -> !cute.int_tuple<"?{div=8192}">
      %ptr_166 = cute.add_offset(%iter_8, %idx_165) : (!cute.ptr<f16, smem, align<128>, S<3,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<f16, smem, align<128>, S<3,4,3>>
      %ptr_167 = cute.add_offset(%iter_10, %int_tuple_156) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %int_tuple_168 = cute.make_int_tuple(%e0_162, %e1_163) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=128}">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
      %314 = cute_nvgpu.atom.set_value(%258, %ptr_167 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>
      %315 = cute.get_scalars(%22) : !cute.int_tuple<"1">
      %316 = cute_nvgpu.atom.get_value(%314 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
      %317 = cute_nvgpu.atom.get_value(%314 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<mcast_mask>} : i16
      %TMADescAddr_169 = cute_nvgpu.get_tma_desc_addr(%314 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) -> !cute.ptr<generic, align<64>>
      %318:2 = cute.get_scalars(%int_tuple_168) : !cute.int_tuple<"(?{div=64},?{div=128})">
      cf.br ^bb48(%c0_i32 : i32)
    ^bb48(%319: i32):  // 2 preds: ^bb47, ^bb49
      %320 = arith.cmpi slt, %319, %315 : i32
      cf.cond_br %320, ^bb49, ^bb50 {llvm.loop_annotation = #loop_annotation}
    ^bb49:  // pred: ^bb48
      cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr_169 : !cute.ptr<generic, align<64>>, %ptr_166 : !cute.ptr<f16, smem, align<128>, S<3,4,3>>, %316 : !cute.ptr<smem, align<8>>, [%318#0, %318#1] : i32, i32) mask = %317 mode = <tiled> num_cta = 2 : i32
      %321 = arith.addi %319, %c1_i32 : i32
      cf.br ^bb48(%321 : i32)
    ^bb50:  // pred: ^bb48
      %idx_170 = cute.crd2idx(%coord_159, %lay_117) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
      %tup_171 = cute.add_offset(%tup_100, %idx_170) : (!cute.int_tuple<"(0,?{div=128})">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
      %e0_172, %e1_173 = cute.get_leaves(%tup_171) : !cute.int_tuple<"(?{div=64},?{div=128})">
      %ptr_174 = cute.add_offset(%iter_9, %idx_165) : (!cute.ptr<f16, smem, align<128>, S<3,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<f16, smem, align<128>, S<3,4,3>>
      %int_tuple_175 = cute.make_int_tuple(%e0_172, %e1_173) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=128}">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
      %322 = cute_nvgpu.atom.set_value(%260, %ptr_167 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>
      %323 = cute_nvgpu.atom.get_value(%322 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
      %324 = cute_nvgpu.atom.get_value(%322 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<mcast_mask>} : i16
      %TMADescAddr_176 = cute_nvgpu.get_tma_desc_addr(%322 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) -> !cute.ptr<generic, align<64>>
      %325:2 = cute.get_scalars(%int_tuple_175) : !cute.int_tuple<"(?{div=64},?{div=128})">
      cf.br ^bb51(%c0_i32 : i32)
    ^bb51(%326: i32):  // 2 preds: ^bb50, ^bb52
      %327 = arith.cmpi slt, %326, %315 : i32
      cf.cond_br %327, ^bb52, ^bb53 {llvm.loop_annotation = #loop_annotation}
    ^bb52:  // pred: ^bb51
      cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr_176 : !cute.ptr<generic, align<64>>, %ptr_174 : !cute.ptr<f16, smem, align<128>, S<3,4,3>>, %323 : !cute.ptr<smem, align<8>>, [%325#0, %325#1] : i32, i32) mask = %324 mode = <tiled> num_cta = 2 : i32
      %328 = arith.addi %326, %c1_i32 : i32
      cf.br ^bb51(%328 : i32)
    ^bb53:  // pred: ^bb51
      cf.br ^bb55(%311, %313, %309 : i32, i32, i32)
    ^bb54:  // pred: ^bb38
      cf.br ^bb55(%295, %296, %294 : i32, i32, i32)
    ^bb55(%329: i32, %330: i32, %331: i32):  // 2 preds: ^bb53, ^bb54
      cf.br ^bb56
    ^bb56:  // pred: ^bb55
      cf.cond_br %102, ^bb57, ^bb100
    ^bb57:  // pred: ^bb56
      %int_tuple_177 = cute.make_int_tuple(%298) : (i32) -> !cute.int_tuple<"?">
      %ptr_178 = cute.add_offset(%iter_10, %int_tuple_177) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %332 = builtin.unrealized_conversion_cast %ptr_178 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %332, %299, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %333 = arith.addi %298, %c1_i32 : i32
      %334 = arith.addi %297, %c1_i32 : i32
      %335 = arith.cmpi eq, %333, %c7_i32 : i32
      %336 = arith.select %335, %c0_i32, %333 : i32
      cf.cond_br %335, ^bb58, ^bb59
    ^bb58:  // pred: ^bb57
      %337 = arith.xori %299, %c1_i32 : i32
      cf.br ^bb60(%337 : i32)
    ^bb59:  // pred: ^bb57
      cf.br ^bb60(%299 : i32)
    ^bb60(%338: i32):  // 2 preds: ^bb58, ^bb59
      cf.br ^bb61
    ^bb61:  // pred: ^bb60
      %coord_179 = cute.make_coord(%298) : (i32) -> !cute.coord<"(_,_,0,?)">
      %idx_180 = cute.crd2idx(%coord_179, %5) : (!cute.coord<"(_,_,0,?)">, !cute.layout<"(1,1,4,7):(0,0,2,1024)">) -> !cute.int_tuple<"?{div=1024}">
      %tup_181 = cute.add_offset(%ummaSmemDesc, %idx_180) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=1024}">) -> !cute_nvgpu.smem_desc
      %tup_182 = cute.add_offset(%ummaSmemDesc_109, %idx_180) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=1024}">) -> !cute_nvgpu.smem_desc
      %339 = cute.get_scalars(%22) : !cute.int_tuple<"1">
      %340 = cute_nvgpu.atom.get_value(%302 : !mma_f16_f16_f32_256x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : i1
      %341 = cute_nvgpu.atom.get_value(%302 : !mma_f16_f16_f32_256x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : i1
      %342 = cute_nvgpu.atom.get_value(%302 : !mma_f16_f16_f32_256x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : i1
      %343 = arith.extui %340 : i1 to i32
      %344 = arith.extui %341 : i1 to i32
      %345 = arith.shli %343, %c13_i32 : i32
      %346 = arith.shli %344, %c14_i32 : i32
      %347 = arith.ori %345, %c272629776_i32 : i32
      %348 = arith.ori %347, %346 : i32
      cf.br ^bb62(%c0_i32 : i32)
    ^bb62(%349: i32):  // 2 preds: ^bb61, ^bb69
      %350 = arith.cmpi slt, %349, %339 : i32
      cf.cond_br %350, ^bb63, ^bb70 {llvm.loop_annotation = #loop_annotation}
    ^bb63:  // pred: ^bb62
      cf.br ^bb64(%c0_i32 : i32)
    ^bb64(%351: i32):  // 2 preds: ^bb63, ^bb68
      %352 = arith.cmpi slt, %351, %339 : i32
      cf.cond_br %352, ^bb65, ^bb69 {llvm.loop_annotation = #loop_annotation}
    ^bb65:  // pred: ^bb64
      cf.br ^bb66(%c0_i32 : i32)
    ^bb66(%353: i32):  // 2 preds: ^bb65, ^bb67
      %354 = arith.cmpi slt, %353, %339 : i32
      cf.cond_br %354, ^bb67, ^bb68 {llvm.loop_annotation = #loop_annotation}
    ^bb67:  // pred: ^bb66
      cute_nvgpu.arch.mma.SM100.umma(%tup_181, %tup_182, %tmem_ptr, %348, %342) {num_cta = 2 : i32, scale = 0 : i32, a_type = f16} : (!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, !cute.ptr<f32, tmem, align<16>>, i32, i1) -> ()
      %355 = arith.addi %353, %c1_i32 : i32
      cf.br ^bb66(%355 : i32)
    ^bb68:  // pred: ^bb66
      %356 = arith.addi %351, %c1_i32 : i32
      cf.br ^bb64(%356 : i32)
    ^bb69:  // pred: ^bb64
      %357 = arith.addi %349, %c1_i32 : i32
      cf.br ^bb62(%357 : i32)
    ^bb70:  // pred: ^bb62
      %358 = cute_nvgpu.atom.set_value(%302, %true : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_f16_f16_f32_256x256x16_
      %coord_183 = cute.make_coord(%298) : (i32) -> !cute.coord<"(_,_,1,?)">
      %idx_184 = cute.crd2idx(%coord_183, %5) : (!cute.coord<"(_,_,1,?)">, !cute.layout<"(1,1,4,7):(0,0,2,1024)">) -> !cute.int_tuple<"?{div=2}">
      %tup_185 = cute.add_offset(%ummaSmemDesc, %idx_184) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
      %tup_186 = cute.add_offset(%ummaSmemDesc_109, %idx_184) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
      %359 = cute_nvgpu.atom.get_value(%358 : !mma_f16_f16_f32_256x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : i1
      %360 = cute_nvgpu.atom.get_value(%358 : !mma_f16_f16_f32_256x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : i1
      %361 = cute_nvgpu.atom.get_value(%358 : !mma_f16_f16_f32_256x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : i1
      %362 = arith.extui %359 : i1 to i32
      %363 = arith.extui %360 : i1 to i32
      %364 = arith.shli %362, %c13_i32 : i32
      %365 = arith.shli %363, %c14_i32 : i32
      %366 = arith.ori %364, %c272629776_i32 : i32
      %367 = arith.ori %366, %365 : i32
      cf.br ^bb71(%c0_i32 : i32)
    ^bb71(%368: i32):  // 2 preds: ^bb70, ^bb78
      %369 = arith.cmpi slt, %368, %339 : i32
      cf.cond_br %369, ^bb72, ^bb79 {llvm.loop_annotation = #loop_annotation}
    ^bb72:  // pred: ^bb71
      cf.br ^bb73(%c0_i32 : i32)
    ^bb73(%370: i32):  // 2 preds: ^bb72, ^bb77
      %371 = arith.cmpi slt, %370, %339 : i32
      cf.cond_br %371, ^bb74, ^bb78 {llvm.loop_annotation = #loop_annotation}
    ^bb74:  // pred: ^bb73
      cf.br ^bb75(%c0_i32 : i32)
    ^bb75(%372: i32):  // 2 preds: ^bb74, ^bb76
      %373 = arith.cmpi slt, %372, %339 : i32
      cf.cond_br %373, ^bb76, ^bb77 {llvm.loop_annotation = #loop_annotation}
    ^bb76:  // pred: ^bb75
      cute_nvgpu.arch.mma.SM100.umma(%tup_185, %tup_186, %tmem_ptr, %367, %361) {num_cta = 2 : i32, scale = 0 : i32, a_type = f16} : (!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, !cute.ptr<f32, tmem, align<16>>, i32, i1) -> ()
      %374 = arith.addi %372, %c1_i32 : i32
      cf.br ^bb75(%374 : i32)
    ^bb77:  // pred: ^bb75
      %375 = arith.addi %370, %c1_i32 : i32
      cf.br ^bb73(%375 : i32)
    ^bb78:  // pred: ^bb73
      %376 = arith.addi %368, %c1_i32 : i32
      cf.br ^bb71(%376 : i32)
    ^bb79:  // pred: ^bb71
      %377 = cute_nvgpu.atom.set_value(%358, %true : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_f16_f16_f32_256x256x16_
      %coord_187 = cute.make_coord(%298) : (i32) -> !cute.coord<"(_,_,2,?)">
      %idx_188 = cute.crd2idx(%coord_187, %5) : (!cute.coord<"(_,_,2,?)">, !cute.layout<"(1,1,4,7):(0,0,2,1024)">) -> !cute.int_tuple<"?{div=4}">
      %tup_189 = cute.add_offset(%ummaSmemDesc, %idx_188) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=4}">) -> !cute_nvgpu.smem_desc
      %tup_190 = cute.add_offset(%ummaSmemDesc_109, %idx_188) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=4}">) -> !cute_nvgpu.smem_desc
      %378 = cute_nvgpu.atom.get_value(%377 : !mma_f16_f16_f32_256x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : i1
      %379 = cute_nvgpu.atom.get_value(%377 : !mma_f16_f16_f32_256x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : i1
      %380 = cute_nvgpu.atom.get_value(%377 : !mma_f16_f16_f32_256x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : i1
      %381 = arith.extui %378 : i1 to i32
      %382 = arith.extui %379 : i1 to i32
      %383 = arith.shli %381, %c13_i32 : i32
      %384 = arith.shli %382, %c14_i32 : i32
      %385 = arith.ori %383, %c272629776_i32 : i32
      %386 = arith.ori %385, %384 : i32
      cf.br ^bb80(%c0_i32 : i32)
    ^bb80(%387: i32):  // 2 preds: ^bb79, ^bb87
      %388 = arith.cmpi slt, %387, %339 : i32
      cf.cond_br %388, ^bb81, ^bb88 {llvm.loop_annotation = #loop_annotation}
    ^bb81:  // pred: ^bb80
      cf.br ^bb82(%c0_i32 : i32)
    ^bb82(%389: i32):  // 2 preds: ^bb81, ^bb86
      %390 = arith.cmpi slt, %389, %339 : i32
      cf.cond_br %390, ^bb83, ^bb87 {llvm.loop_annotation = #loop_annotation}
    ^bb83:  // pred: ^bb82
      cf.br ^bb84(%c0_i32 : i32)
    ^bb84(%391: i32):  // 2 preds: ^bb83, ^bb85
      %392 = arith.cmpi slt, %391, %339 : i32
      cf.cond_br %392, ^bb85, ^bb86 {llvm.loop_annotation = #loop_annotation}
    ^bb85:  // pred: ^bb84
      cute_nvgpu.arch.mma.SM100.umma(%tup_189, %tup_190, %tmem_ptr, %386, %380) {num_cta = 2 : i32, scale = 0 : i32, a_type = f16} : (!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, !cute.ptr<f32, tmem, align<16>>, i32, i1) -> ()
      %393 = arith.addi %391, %c1_i32 : i32
      cf.br ^bb84(%393 : i32)
    ^bb86:  // pred: ^bb84
      %394 = arith.addi %389, %c1_i32 : i32
      cf.br ^bb82(%394 : i32)
    ^bb87:  // pred: ^bb82
      %395 = arith.addi %387, %c1_i32 : i32
      cf.br ^bb80(%395 : i32)
    ^bb88:  // pred: ^bb80
      %396 = cute_nvgpu.atom.set_value(%377, %true : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_f16_f16_f32_256x256x16_
      %coord_191 = cute.make_coord(%298) : (i32) -> !cute.coord<"(_,_,3,?)">
      %idx_192 = cute.crd2idx(%coord_191, %5) : (!cute.coord<"(_,_,3,?)">, !cute.layout<"(1,1,4,7):(0,0,2,1024)">) -> !cute.int_tuple<"?{div=2}">
      %tup_193 = cute.add_offset(%ummaSmemDesc, %idx_192) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
      %tup_194 = cute.add_offset(%ummaSmemDesc_109, %idx_192) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
      %397 = cute_nvgpu.atom.get_value(%396 : !mma_f16_f16_f32_256x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : i1
      %398 = cute_nvgpu.atom.get_value(%396 : !mma_f16_f16_f32_256x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : i1
      %399 = cute_nvgpu.atom.get_value(%396 : !mma_f16_f16_f32_256x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : i1
      %400 = arith.extui %397 : i1 to i32
      %401 = arith.extui %398 : i1 to i32
      %402 = arith.shli %400, %c13_i32 : i32
      %403 = arith.shli %401, %c14_i32 : i32
      %404 = arith.ori %402, %c272629776_i32 : i32
      %405 = arith.ori %404, %403 : i32
      cf.br ^bb89(%c0_i32 : i32)
    ^bb89(%406: i32):  // 2 preds: ^bb88, ^bb96
      %407 = arith.cmpi slt, %406, %339 : i32
      cf.cond_br %407, ^bb90, ^bb97 {llvm.loop_annotation = #loop_annotation}
    ^bb90:  // pred: ^bb89
      cf.br ^bb91(%c0_i32 : i32)
    ^bb91(%408: i32):  // 2 preds: ^bb90, ^bb95
      %409 = arith.cmpi slt, %408, %339 : i32
      cf.cond_br %409, ^bb92, ^bb96 {llvm.loop_annotation = #loop_annotation}
    ^bb92:  // pred: ^bb91
      cf.br ^bb93(%c0_i32 : i32)
    ^bb93(%410: i32):  // 2 preds: ^bb92, ^bb94
      %411 = arith.cmpi slt, %410, %339 : i32
      cf.cond_br %411, ^bb94, ^bb95 {llvm.loop_annotation = #loop_annotation}
    ^bb94:  // pred: ^bb93
      cute_nvgpu.arch.mma.SM100.umma(%tup_193, %tup_194, %tmem_ptr, %405, %399) {num_cta = 2 : i32, scale = 0 : i32, a_type = f16} : (!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, !cute.ptr<f32, tmem, align<16>>, i32, i1) -> ()
      %412 = arith.addi %410, %c1_i32 : i32
      cf.br ^bb93(%412 : i32)
    ^bb95:  // pred: ^bb93
      %413 = arith.addi %408, %c1_i32 : i32
      cf.br ^bb91(%413 : i32)
    ^bb96:  // pred: ^bb91
      %414 = arith.addi %406, %c1_i32 : i32
      cf.br ^bb89(%414 : i32)
    ^bb97:  // pred: ^bb89
      %415 = cute_nvgpu.atom.set_value(%396, %true : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_f16_f16_f32_256x256x16_
      %416 = builtin.unrealized_conversion_cast %415 : !mma_f16_f16_f32_256x256x16_ to !llvm.struct<(i1, i1, i1)>
      %417 = nvvm.elect.sync -> i1
      cf.cond_br %417, ^bb98, ^bb99
    ^bb98:  // pred: ^bb97
      %ptr_195 = cute.add_offset(%ptr_17, %int_tuple_177) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %418 = builtin.unrealized_conversion_cast %ptr_195 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.tcgen05.commit.arrive %418, multicast_mask = %101 {group = #nvvm.tcgen05_group<cta_2>} : !llvm.ptr<3>, i16
      cf.br ^bb99
    ^bb99:  // 2 preds: ^bb97, ^bb98
      cf.br ^bb101(%334, %336, %338, %416 : i32, i32, i32, !llvm.struct<(i1, i1, i1)>)
    ^bb100:  // pred: ^bb56
      cf.br ^bb101(%297, %298, %299, %300 : i32, i32, i32, !llvm.struct<(i1, i1, i1)>)
    ^bb101(%419: i32, %420: i32, %421: i32, %422: !llvm.struct<(i1, i1, i1)>):  // 2 preds: ^bb99, ^bb100
      cf.br ^bb102
    ^bb102:  // pred: ^bb101
      %423 = arith.addi %293, %c1_i32 : i32
      cf.br ^bb37(%423, %331, %329, %330, %419, %420, %421, %422 : i32, i32, i32, i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>)
    ^bb103:  // pred: ^bb37
      cf.cond_br %102, ^bb104, ^bb107
    ^bb104:  // pred: ^bb103
      %424 = nvvm.elect.sync -> i1
      cf.cond_br %424, ^bb105, ^bb106
    ^bb105:  // pred: ^bb104
      %dyn_196 = cute.derefine(%iter_46) : !cute.ptr<i64, smem, align<16>> to !cute.ptr<i64, smem>
      %425 = builtin.unrealized_conversion_cast %dyn_196 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.tcgen05.commit.arrive %425, multicast_mask = %c3_i16 {group = #nvvm.tcgen05_group<cta_2>} : !llvm.ptr<3>, i16
      cf.br ^bb106
    ^bb106:  // 2 preds: ^bb104, ^bb105
      cf.br ^bb107
    ^bb107:  // 2 preds: ^bb103, ^bb106
      cf.br ^bb109(%255, %295, %296 : i32, i32, i32)
    ^bb108:  // pred: ^bb16
      cf.br ^bb109(%c1_i32, %c0_i32, %c1_i32 : i32, i32, i32)
    ^bb109(%426: i32, %427: i32, %428: i32):  // 2 preds: ^bb107, ^bb108
      cf.br ^bb110
    ^bb110:  // pred: ^bb109
      cf.cond_br %68, ^bb111, ^bb112
    ^bb111:  // pred: ^bb110
      cute_nvgpu.arch.sm100.relinquish_tmem_alloc_permit [cta_2]
      cf.br ^bb112
    ^bb112:  // 2 preds: ^bb110, ^bb111
      %dyn_197 = cute.derefine(%iter_46) : !cute.ptr<i64, smem, align<16>> to !cute.ptr<i64, smem>
      %429 = builtin.unrealized_conversion_cast %dyn_197 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %429, %c0_i32, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %iter_198 = cute.get_iter(%rmem) : !memref_rmem_f32_
      %430 = cute.get_scalars(%22) : !cute.int_tuple<"1">
      %431 = builtin.unrealized_conversion_cast %iter_198 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
      %iter_199 = cute.get_iter(%rmem_134) : !memref_rmem_f16_
      %432 = cute.get_scalars(%1) : !cute.int_tuple<"8">
      cf.br ^bb113(%c0_i32 : i32)
    ^bb113(%433: i32):  // 2 preds: ^bb112, ^bb120
      %434 = arith.cmpi slt, %433, %c4_i32 : i32
      cf.cond_br %434, ^bb114, ^bb121
    ^bb114:  // pred: ^bb113
      %coord_200 = cute.make_coord(%433) : (i32) -> !cute.coord<"(_,_,?)">
      %idx_201 = cute.crd2idx(%coord_200, %4) : (!cute.coord<"(_,_,?)">, !cute.layout<"(((64,32),1),1,((1,4),1,1)):(((1,65536),0),0,((0,64),0,0))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_202 = cute.add_offset(%ptr_130, %idx_201) : (!cute.ptr<f32, tmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<f32, tmem, align<16>>
      cf.br ^bb115(%c0_i32 : i32)
    ^bb115(%435: i32):  // 2 preds: ^bb114, ^bb116
      %436 = arith.cmpi slt, %435, %430 : i32
      cf.cond_br %436, ^bb116, ^bb117 {llvm.loop_annotation = #loop_annotation}
    ^bb116:  // pred: ^bb115
      %437 = "cute_nvgpu.arch.copy.SM100.tmem_load"(%ptr_202) <{num_b = 32 : i32, num_dp = 32 : i32, num_rep = 64 : i32}> : (!cute.ptr<f32, tmem, align<16>>) -> vector<64xi32>
      llvm.store %437, %431 : vector<64xi32>, !llvm.ptr
      %438 = arith.addi %435, %c1_i32 : i32
      cf.br ^bb115(%438 : i32)
    ^bb117:  // pred: ^bb115
      %439 = cute.memref.load_vec %rmem, row_major : !memref_rmem_f32_
      %440 = arith.truncf %439 : vector<64xf32> to vector<64xf16>
      cute.memref.store_vec %440, %rmem_134, row_major : !memref_rmem_f16_
      %idx_203 = cute.crd2idx(%coord_200, %3) : (!cute.coord<"(_,_,?)">, !cute.layout<"((64,1),1,((1,4),1,1)):((1,0),0,((0,64),0,0))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_204 = cute.add_offset(%ptr_133, %idx_203) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<f16, gmem, align<32>>
      cf.br ^bb118(%c0_i32 : i32)
    ^bb118(%441: i32):  // 2 preds: ^bb117, ^bb119
      %442 = arith.cmpi slt, %441, %432 : i32
      cf.cond_br %442, ^bb119, ^bb120 {llvm.loop_annotation = #loop_annotation}
    ^bb119:  // pred: ^bb118
      %coord_205 = cute.make_coord(%441) : (i32) -> !cute.coord<"(_,?)">
      %idx_206 = cute.crd2idx(%coord_205, %2) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(8)):(1,(8))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_207 = cute.add_offset(%iter_199, %idx_206) : (!cute.ptr<f16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
      %ptr_208 = cute.add_offset(%ptr_204, %idx_206) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, gmem, align<16>>
      %443 = builtin.unrealized_conversion_cast %ptr_207 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
      %444 = builtin.unrealized_conversion_cast %ptr_208 : !cute.ptr<f16, gmem, align<16>> to !llvm.ptr<1>
      %445 = llvm.load %443 {alignment = 16 : i64} : !llvm.ptr -> vector<8xf16>
      llvm.store %445, %444 {alignment = 16 : i64} : vector<8xf16>, !llvm.ptr<1>
      %446 = arith.addi %441, %c1_i32 : i32
      cf.br ^bb118(%446 : i32)
    ^bb120:  // pred: ^bb118
      %447 = arith.addi %433, %c1_i32 : i32
      cf.br ^bb113(%447 : i32)
    ^bb121:  // pred: ^bb113
      %448 = builtin.unrealized_conversion_cast %ptr_47 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      %449 = nvvm.mapa.shared.cluster %448, %114 : !llvm.ptr<3>, i32 -> <3>
      nvvm.mbarrier.txn %449, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>, space = #nvvm.mbar_space<cluster>} : !llvm.ptr<3>, i32
      cf.cond_br %68, ^bb122, ^bb155
    ^bb122:  // pred: ^bb121
      %450 = arith.addi %427, %c1_i32 : i32
      %451 = arith.cmpi eq, %450, %c7_i32 : i32
      %452 = arith.select %451, %c0_i32, %450 : i32
      cf.cond_br %451, ^bb123, ^bb124
    ^bb123:  // pred: ^bb122
      %453 = arith.xori %428, %c1_i32 : i32
      cf.br ^bb125(%453 : i32)
    ^bb124:  // pred: ^bb122
      cf.br ^bb125(%428 : i32)
    ^bb125(%454: i32):  // 2 preds: ^bb123, ^bb124
      cf.br ^bb126
    ^bb126:  // pred: ^bb125
      %455 = arith.addi %452, %c1_i32 : i32
      %456 = arith.cmpi eq, %455, %c7_i32 : i32
      %457 = arith.select %456, %c0_i32, %455 : i32
      cf.cond_br %456, ^bb127, ^bb128
    ^bb127:  // pred: ^bb126
      %458 = arith.xori %454, %c1_i32 : i32
      cf.br ^bb129(%458 : i32)
    ^bb128:  // pred: ^bb126
      cf.br ^bb129(%454 : i32)
    ^bb129(%459: i32):  // 2 preds: ^bb127, ^bb128
      cf.br ^bb130
    ^bb130:  // pred: ^bb129
      %460 = arith.addi %457, %c1_i32 : i32
      %461 = arith.cmpi eq, %460, %c7_i32 : i32
      %462 = arith.select %461, %c0_i32, %460 : i32
      cf.cond_br %461, ^bb131, ^bb132
    ^bb131:  // pred: ^bb130
      %463 = arith.xori %459, %c1_i32 : i32
      cf.br ^bb133(%463 : i32)
    ^bb132:  // pred: ^bb130
      cf.br ^bb133(%459 : i32)
    ^bb133(%464: i32):  // 2 preds: ^bb131, ^bb132
      cf.br ^bb134
    ^bb134:  // pred: ^bb133
      %465 = arith.addi %462, %c1_i32 : i32
      %466 = arith.cmpi eq, %465, %c7_i32 : i32
      %467 = arith.select %466, %c0_i32, %465 : i32
      cf.cond_br %466, ^bb135, ^bb136
    ^bb135:  // pred: ^bb134
      %468 = arith.xori %464, %c1_i32 : i32
      cf.br ^bb137(%468 : i32)
    ^bb136:  // pred: ^bb134
      cf.br ^bb137(%464 : i32)
    ^bb137(%469: i32):  // 2 preds: ^bb135, ^bb136
      cf.br ^bb138
    ^bb138:  // pred: ^bb137
      %470 = arith.addi %467, %c1_i32 : i32
      %471 = arith.cmpi eq, %470, %c7_i32 : i32
      %472 = arith.select %471, %c0_i32, %470 : i32
      cf.cond_br %471, ^bb139, ^bb140
    ^bb139:  // pred: ^bb138
      %473 = arith.xori %469, %c1_i32 : i32
      cf.br ^bb141(%473 : i32)
    ^bb140:  // pred: ^bb138
      cf.br ^bb141(%469 : i32)
    ^bb141(%474: i32):  // 2 preds: ^bb139, ^bb140
      cf.br ^bb142
    ^bb142:  // pred: ^bb141
      %475 = arith.addi %472, %c1_i32 : i32
      %476 = arith.cmpi eq, %475, %c7_i32 : i32
      %477 = arith.select %476, %c0_i32, %475 : i32
      cf.cond_br %476, ^bb143, ^bb144
    ^bb143:  // pred: ^bb142
      %478 = arith.xori %474, %c1_i32 : i32
      cf.br ^bb145(%478 : i32)
    ^bb144:  // pred: ^bb142
      cf.br ^bb145(%474 : i32)
    ^bb145(%479: i32):  // 2 preds: ^bb143, ^bb144
      cf.br ^bb146
    ^bb146:  // pred: ^bb145
      %int_tuple_209 = cute.make_int_tuple(%477) : (i32) -> !cute.int_tuple<"?">
      %ptr_210 = cute.add_offset(%ptr_17, %int_tuple_209) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %480 = builtin.unrealized_conversion_cast %ptr_210 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %480, %479, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      cf.cond_br %102, ^bb147, ^bb150
    ^bb147:  // pred: ^bb146
      %481 = nvvm.elect.sync -> i1
      cf.cond_br %481, ^bb148, ^bb149
    ^bb148:  // pred: ^bb147
      %ptr_211 = cute.add_offset(%iter_10, %int_tuple_209) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %482 = builtin.unrealized_conversion_cast %ptr_211 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %482, %c65536_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
      cf.br ^bb149
    ^bb149:  // 2 preds: ^bb147, ^bb148
      cf.br ^bb150
    ^bb150:  // 2 preds: ^bb146, ^bb149
      cf.cond_br %102, ^bb151, ^bb154
    ^bb151:  // pred: ^bb150
      %483 = arith.remsi %83, %c2_i32 : i32
      %484 = arith.cmpi eq, %483, %c0_i32 : i32
      cf.cond_br %484, ^bb152, ^bb153
    ^bb152:  // pred: ^bb151
      nvvm.mbarrier.try_wait.parity.shared %448, %426, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      cf.br ^bb153
    ^bb153:  // 2 preds: ^bb151, ^bb152
      cf.br ^bb154
    ^bb154:  // 2 preds: ^bb150, ^bb153
      cf.br ^bb155
    ^bb155:  // 2 preds: ^bb121, ^bb154
      nvvm.barrier id = %c1_i32
      cf.cond_br %68, ^bb156, ^bb157
    ^bb156:  // pred: ^bb155
      %485 = arith.xori %83, %c1_i32 : i32
      %486 = builtin.unrealized_conversion_cast %iter : !cute.ptr<i64, smem, align<128>> to !llvm.ptr<3>
      %487 = nvvm.mapa.shared.cluster %486, %485 : !llvm.ptr<3>, i32 -> <3>
      nvvm.mbarrier.txn %487, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>, space = #nvvm.mbar_space<cluster>} : !llvm.ptr<3>, i32
      nvvm.mbarrier.try_wait.parity.shared %486, %c0_i32, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      cute_nvgpu.arch.sm100.dealloc_tmem(%tmem_ptr, %c512_i32) [cta_2] : !cute.ptr<f32, tmem, align<16>>, i32
      cf.br ^bb157
    ^bb157:  // 2 preds: ^bb155, ^bb156
      return
    }
  }
  func.func @cutlass_host_function_Tensorgmemodiv8192i64div81921_Tensorgmemodiv8192i64div81921_Tensorgmemodiv8192i64div81921(%arg0: !memref_gmem_f16_, %arg1: !memref_gmem_f16_, %arg2: !memref_gmem_f16_) attributes {llvm.emit_c_interface} {
    %0 = llvm.mlir.constant(127 : i64) : i64
    %1 = llvm.mlir.constant(4539628424389459968 : i64) : i64
    %2 = llvm.mlir.constant(287506 : i64) : i64
    %c229632_i32 = arith.constant 229632 : i32
    %c2 = arith.constant 2 : index
    %c128 = arith.constant 128 : index
    %c1 = arith.constant 1 : index
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
    %c1_i32 = arith.constant 1 : i32
    %c0_i32 = arith.constant 0 : i32
    %c-1_i32 = arith.constant -1 : i32
    %149 = arith.cmpi sgt, %c128_i32, %c0_i32 : i32
    %150 = arith.select %149, %c-1_i32, %c1_i32 : i32
    %151 = arith.addi %150, %148#0 : i32
    %152 = arith.divsi %151, %c128_i32 : i32
    %153 = arith.addi %c1_i32, %152 : i32
    %154 = arith.subi %c0_i32, %148#0 : i32
    %155 = arith.divsi %154, %c128_i32 : i32
    %156 = arith.subi %c0_i32, %155 : i32
    %157 = arith.cmpi slt, %148#0, %c0_i32 : i32
    %158 = arith.cmpi sgt, %148#0, %c0_i32 : i32
    %159 = arith.cmpi slt, %c128_i32, %c0_i32 : i32
    %160 = arith.cmpi sgt, %c128_i32, %c0_i32 : i32
    %161 = arith.andi %157, %159 : i1
    %162 = arith.andi %158, %160 : i1
    %163 = arith.ori %161, %162 : i1
    %164 = arith.select %163, %153, %156 : i32
    %c1_i32_8 = arith.constant 1 : i32
    %c0_i32_9 = arith.constant 0 : i32
    %c-1_i32_10 = arith.constant -1 : i32
    %165 = arith.cmpi sgt, %c256_i32, %c0_i32_9 : i32
    %166 = arith.select %165, %c-1_i32_10, %c1_i32_8 : i32
    %167 = arith.addi %166, %148#1 : i32
    %168 = arith.divsi %167, %c256_i32 : i32
    %169 = arith.addi %c1_i32_8, %168 : i32
    %170 = arith.subi %c0_i32_9, %148#1 : i32
    %171 = arith.divsi %170, %c256_i32 : i32
    %172 = arith.subi %c0_i32_9, %171 : i32
    %173 = arith.cmpi slt, %148#1, %c0_i32_9 : i32
    %174 = arith.cmpi sgt, %148#1, %c0_i32_9 : i32
    %175 = arith.cmpi slt, %c256_i32, %c0_i32_9 : i32
    %176 = arith.cmpi sgt, %c256_i32, %c0_i32_9 : i32
    %177 = arith.andi %173, %175 : i1
    %178 = arith.andi %174, %176 : i1
    %179 = arith.ori %177, %178 : i1
    %180 = arith.select %179, %169, %172 : i32
    %int_tuple_11 = cute.make_int_tuple(%164, %180) : (i32, i32) -> !cute.int_tuple<"(?,?,1)">
    %e0_12, %e1_13, %e2 = cute.get_leaves(%int_tuple_11) : !cute.int_tuple<"(?,?,1)">
    %tup = cute.add_offset(%e0_12, %3) : (!cute.int_tuple<"?">, !cute.int_tuple<"2">) -> !cute.int_tuple<"?">
    %sub = cute.tuple_sub(%tup, %4) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
    %div = cute.tuple_div(%sub, %3) : (!cute.int_tuple<"?">, !cute.int_tuple<"2">) -> !cute.int_tuple<"?">
    %mul = cute.tuple_mul(%div, %3) : (!cute.int_tuple<"?">, !cute.int_tuple<"2">) -> !cute.int_tuple<"?{div=2}">
    %181 = cute.get_scalars(%mul) : !cute.int_tuple<"?{div=2}">
    %tup_14 = cute.add_offset(%e1_13, %4) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
    %sub_15 = cute.tuple_sub(%tup_14, %4) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
    %div_16 = cute.tuple_div(%sub_15, %4) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
    %mul_17 = cute.tuple_mul(%div_16, %4) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
    %182 = cute.get_scalars(%mul_17) : !cute.int_tuple<"?">
    %183 = arith.index_cast %181 : i32 to index
    %184 = arith.index_cast %182 : i32 to index
    gpu.launch_func  @kernels::@kernel_cutlass_kernel_TiledMMA_ThrLayoutVMNK21111000_PermutationMNK____MMAAtom_ThrID21_ShapeMNK25625616_TVLayoutA2128161281256_TVLayoutB2128161281256_TVLayoutC21282561281256_CopyAtom_ThrI_0 clusters in (%c2, %c1, %c1) blocks in (%183, %184, %c1) threads in (%c128, %c1, %c1)  dynamic_shared_memory_size %c229632_i32 args(%10 : !mma_f16_f16_f32_256x256x16_, %87 : !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_100_2sm_multicast, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, internal_val_type = f16>, %view : !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">, %145 : !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_100_2sm_multicast, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, internal_val_type = f16>, %view_5 : !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">, %arg2 : !memref_gmem_f16_) {use_pdl = false}
    return
  }
}
