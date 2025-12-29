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
      %38 = arith.floordivsi %37, %c32_i32 : i32
      %39 = cute_nvgpu.arch.make_warp_uniform(%38) : i32
      %40 = nvvm.read.ptx.sreg.ctaid.x range <i32, 0, 2147483647> : i32
      %41 = nvvm.read.ptx.sreg.ctaid.y range <i32, 0, 65535> : i32
      %42 = nvvm.read.ptx.sreg.cluster.ctarank : i32
      %43 = cute.get_flat_coord(%42, %27) : (i32, !cute.layout<"((2),1,1,1):((1),0,0,0)">) -> !cute.coord<"(?,0,0,0)">
      %e0, %e1, %e2, %e3 = cute.get_leaves(%43) : !cute.coord<"(?,0,0,0)">
      %itup = cute.to_int_tuple(%e0) : !cute.coord<"?"> to !cute.int_tuple<"?">
      %44 = arith.remsi %40, %c2_i32 : i32
      %45 = arith.floordivsi %40, %c2_i32 : i32
      %smem_ptr = cute_nvgpu.arch.get_dyn_smem() : !cute.ptr<i8, smem, align<1024>>
      %ptr = cute.add_offset(%smem_ptr, %26) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"144">) -> !cute.ptr<i8, smem, align<16>>
      %ptr_0 = cute.add_offset(%smem_ptr, %25) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"112">) -> !cute.ptr<i8, smem, align<16>>
      %ptr_1 = cute.add_offset(%smem_ptr, %24) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"128">) -> !cute.ptr<i8, smem, align<128>>
      %iter = cute.recast_iter(%ptr_1) : !cute.ptr<i8, smem, align<128>> to !cute.ptr<i64, smem, align<128>>
      %ptr_2 = cute.add_offset(%smem_ptr, %23) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"136">) -> !cute.ptr<i8, smem, align<8>>
      %iter_3 = cute.recast_iter(%ptr_2) : !cute.ptr<i8, smem, align<8>> to !cute.ptr<i32, smem, align<8>>
      %46 = cute.ptrtoint(%ptr) : !cute.ptr<i8, smem, align<16>> to i32
      %47 = arith.addi %46, %c127_i32 : i32
      %48 = arith.andi %47, %c-128_i32 : i32
      %49 = arith.extsi %48 : i32 to i64
      %iv = cute.assume(%49) : (i64) -> !cute.i64<divby 128>
      %50 = cute.inttoptr(%iv) : !cute.i64<divby 128> to !cute.ptr<i8, smem, align<128>>
      %ptr_4 = cute.add_offset(%50, %22) : (!cute.ptr<i8, smem, align<128>>, !cute.int_tuple<"114688">) -> !cute.ptr<i8, smem, align<128>>
      %iter_5 = cute.recast_iter(%50) : !cute.ptr<i8, smem, align<128>> to !cute.ptr<f16, smem, align<128>, S<3,4,3>>
      %iter_6 = cute.recast_iter(%ptr_4) : !cute.ptr<i8, smem, align<128>> to !cute.ptr<f16, smem, align<128>, S<3,4,3>>
      %51 = arith.cmpi eq, %39, %c0_i32 : i32
      cf.cond_br %51, ^bb1, ^bb2
    ^bb1:  // pred: ^bb0
      cute_nvgpu.prefetch_tma_desc(%arg1) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_100_2sm_multicast, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, internal_val_type = f16>) -> ()
      cute_nvgpu.prefetch_tma_desc(%arg3) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_100_2sm_multicast, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, internal_val_type = f16>) -> ()
      cf.br ^bb2
    ^bb2:  // 2 preds: ^bb0, ^bb1
      %iter_7 = cute.recast_iter(%smem_ptr) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<i64, smem, align<1024>>
      cf.cond_br %51, ^bb3, ^bb4
    ^bb3:  // pred: ^bb2
      %52 = builtin.unrealized_conversion_cast %iter_7 : !cute.ptr<i64, smem, align<1024>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %52, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_8 = cute.add_offset(%iter_7, %21) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"1">) -> !cute.ptr<i64, smem>
      %53 = builtin.unrealized_conversion_cast %ptr_8 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %53, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_9 = cute.add_offset(%iter_7, %20) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"2">) -> !cute.ptr<i64, smem, align<16>>
      %54 = builtin.unrealized_conversion_cast %ptr_9 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %54, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_10 = cute.add_offset(%iter_7, %19) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"3">) -> !cute.ptr<i64, smem>
      %55 = builtin.unrealized_conversion_cast %ptr_10 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %55, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_11 = cute.add_offset(%iter_7, %18) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"4">) -> !cute.ptr<i64, smem, align<32>>
      %56 = builtin.unrealized_conversion_cast %ptr_11 : !cute.ptr<i64, smem, align<32>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %56, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_12 = cute.add_offset(%iter_7, %17) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"5">) -> !cute.ptr<i64, smem>
      %57 = builtin.unrealized_conversion_cast %ptr_12 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %57, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_13 = cute.add_offset(%iter_7, %16) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"6">) -> !cute.ptr<i64, smem, align<16>>
      %58 = builtin.unrealized_conversion_cast %ptr_13 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %58, %c1_i32 : !llvm.ptr<3>, i32
      cf.br ^bb4
    ^bb4:  // 2 preds: ^bb2, ^bb3
      %ptr_14 = cute.add_offset(%iter_7, %15) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"7">) -> !cute.ptr<i64, smem>
      cf.cond_br %51, ^bb5, ^bb6
    ^bb5:  // pred: ^bb4
      %59 = builtin.unrealized_conversion_cast %ptr_14 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %59, %c1_i32 : !llvm.ptr<3>, i32
      %int_tuple = cute.make_int_tuple() : () -> !cute.int_tuple<"8">
      %ptr_15 = cute.add_offset(%iter_7, %int_tuple) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"8">) -> !cute.ptr<i64, smem, align<64>>
      %dyn = cute.derefine(%ptr_15) : !cute.ptr<i64, smem, align<64>> to !cute.ptr<i64, smem>
      %60 = builtin.unrealized_conversion_cast %dyn : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %60, %c1_i32 : !llvm.ptr<3>, i32
      %int_tuple_16 = cute.make_int_tuple() : () -> !cute.int_tuple<"9">
      %ptr_17 = cute.add_offset(%iter_7, %int_tuple_16) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"9">) -> !cute.ptr<i64, smem>
      %61 = builtin.unrealized_conversion_cast %ptr_17 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %61, %c1_i32 : !llvm.ptr<3>, i32
      %int_tuple_18 = cute.make_int_tuple() : () -> !cute.int_tuple<"10">
      %ptr_19 = cute.add_offset(%iter_7, %int_tuple_18) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"10">) -> !cute.ptr<i64, smem, align<16>>
      %dyn_20 = cute.derefine(%ptr_19) : !cute.ptr<i64, smem, align<16>> to !cute.ptr<i64, smem>
      %62 = builtin.unrealized_conversion_cast %dyn_20 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %62, %c1_i32 : !llvm.ptr<3>, i32
      %int_tuple_21 = cute.make_int_tuple() : () -> !cute.int_tuple<"11">
      %ptr_22 = cute.add_offset(%iter_7, %int_tuple_21) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"11">) -> !cute.ptr<i64, smem>
      %63 = builtin.unrealized_conversion_cast %ptr_22 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %63, %c1_i32 : !llvm.ptr<3>, i32
      %int_tuple_23 = cute.make_int_tuple() : () -> !cute.int_tuple<"12">
      %ptr_24 = cute.add_offset(%iter_7, %int_tuple_23) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"12">) -> !cute.ptr<i64, smem, align<32>>
      %dyn_25 = cute.derefine(%ptr_24) : !cute.ptr<i64, smem, align<32>> to !cute.ptr<i64, smem>
      %64 = builtin.unrealized_conversion_cast %dyn_25 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %64, %c1_i32 : !llvm.ptr<3>, i32
      %int_tuple_26 = cute.make_int_tuple() : () -> !cute.int_tuple<"13">
      %ptr_27 = cute.add_offset(%iter_7, %int_tuple_26) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"13">) -> !cute.ptr<i64, smem>
      %65 = builtin.unrealized_conversion_cast %ptr_27 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %65, %c1_i32 : !llvm.ptr<3>, i32
      cf.br ^bb6
    ^bb6:  // 2 preds: ^bb4, ^bb5
      %66 = cute_nvgpu.arch.make_warp_uniform(%42) : i32
      %67 = cute.get_flat_coord(%66, %27) : (i32, !cute.layout<"((2),1,1,1):((1),0,0,0)">) -> !cute.coord<"(?,0,0,0)">
      %e0_28, %e1_29, %e2_30, %e3_31 = cute.get_leaves(%67) : !cute.coord<"(?,0,0,0)">
      %itup_32 = cute.to_int_tuple(%e0_28) : !cute.coord<"?"> to !cute.int_tuple<"?">
      %68 = cute.get_scalars(%itup_32) : !cute.int_tuple<"?">
      %coord = cute.make_coord(%itup_32) : (!cute.int_tuple<"?">) -> !cute.coord<"(?,0,_,0)">
      %idx = cute.crd2idx(%coord, %27) : (!cute.coord<"(?,0,_,0)">, !cute.layout<"((2),1,1,1):((1),0,0,0)">) -> !cute.int_tuple<"?">
      %e0_33 = cute.get_leaves(%idx) : !cute.int_tuple<"?">
      %69 = cute.get_scalars(%e0_33) : !cute.int_tuple<"?">
      %70 = arith.shli %c1_i32, %69 : i32
      %71 = arith.trunci %70 : i32 to i16
      %coord_34 = cute.make_coord(%itup_32) : (!cute.int_tuple<"?">) -> !cute.coord<"(?,_,0,0)">
      %idx_35 = cute.crd2idx(%coord_34, %27) : (!cute.coord<"(?,_,0,0)">, !cute.layout<"((2),1,1,1):((1),0,0,0)">) -> !cute.int_tuple<"?">
      %e0_36 = cute.get_leaves(%idx_35) : !cute.int_tuple<"?">
      %72 = cute.get_scalars(%e0_36) : !cute.int_tuple<"?">
      %73 = arith.shli %c1_i32, %72 : i32
      %74 = arith.trunci %73 : i32 to i16
      %75 = arith.xori %68, %c1_i32 : i32
      %coord_37 = cute.make_coord(%75) : (i32) -> !cute.coord<"(?,0,_,0)">
      %idx_38 = cute.crd2idx(%coord_37, %27) : (!cute.coord<"(?,0,_,0)">, !cute.layout<"((2),1,1,1):((1),0,0,0)">) -> !cute.int_tuple<"?">
      %e0_39 = cute.get_leaves(%idx_38) : !cute.int_tuple<"?">
      %76 = cute.get_scalars(%e0_39) : !cute.int_tuple<"?">
      %77 = arith.shli %c1_i32, %76 : i32
      %78 = arith.trunci %77 : i32 to i16
      %coord_40 = cute.make_coord(%75) : (i32) -> !cute.coord<"(?,_,0,0)">
      %idx_41 = cute.crd2idx(%coord_40, %27) : (!cute.coord<"(?,_,0,0)">, !cute.layout<"((2),1,1,1):((1),0,0,0)">) -> !cute.int_tuple<"?">
      %e0_42 = cute.get_leaves(%idx_41) : !cute.int_tuple<"?">
      %79 = cute.get_scalars(%e0_42) : !cute.int_tuple<"?">
      %80 = arith.shli %c1_i32, %79 : i32
      %81 = arith.trunci %80 : i32 to i16
      %82 = arith.ori %71, %74 : i16
      %83 = arith.ori %82, %78 : i16
      %84 = arith.ori %83, %81 : i16
      %85 = arith.cmpi eq, %44, %c0_i32 : i32
      nvvm.fence.mbarrier.init
      nvvm.cluster.arrive.relaxed
      nvvm.cluster.wait
      %iter_43 = cute.recast_iter(%ptr_0) : !cute.ptr<i8, smem, align<16>> to !cute.ptr<i64, smem, align<16>>
      cf.cond_br %51, ^bb7, ^bb8
    ^bb7:  // pred: ^bb6
      %86 = builtin.unrealized_conversion_cast %iter_43 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %86, %c1_i32 : !llvm.ptr<3>, i32
      cf.br ^bb8
    ^bb8:  // 2 preds: ^bb6, ^bb7
      %ptr_44 = cute.add_offset(%iter_43, %21) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"1">) -> !cute.ptr<i64, smem>
      cf.cond_br %51, ^bb9, ^bb10
    ^bb9:  // pred: ^bb8
      %87 = builtin.unrealized_conversion_cast %ptr_44 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %87, %c256_i32 : !llvm.ptr<3>, i32
      cf.br ^bb10
    ^bb10:  // 2 preds: ^bb8, ^bb9
      %88 = arith.floordivsi %66, %c2_i32 : i32
      %89 = arith.muli %88, %c2_i32 : i32
      nvvm.fence.mbarrier.init
      nvvm.cluster.arrive.relaxed
      nvvm.cluster.wait
      %coord_45 = cute.make_coord(%45, %41) : (i32, i32) -> !cute.coord<"(?,?,_)">
      %90:2 = cute.get_scalars(%coord_45) <{only_dynamic}> : !cute.coord<"(?,?,_)">
      %coord_46 = cute.make_coord(%90#0) : (i32) -> !cute.coord<"((_,_),(?,_))">
      %lay = cute.get_layout(%arg2) : !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">
      %91:2 = cute.get_scalars(%lay) <{only_dynamic}> : !cute.layout<"(?,?{div=8192}):(1@1,1@0)">
      %92 = arith.ceildivsi %91#0, %c256_i32 : i32
      %93 = arith.ceildivsi %91#1, %c64_i32 : i32
      %shape = cute.make_shape(%92, %93) : (i32, i32) -> !cute.shape<"((256,64),(?,?))">
      %lay_47 = cute.make_layout(%shape, %14) : !cute.layout<"((256,64),(?,?)):((1@1,1@0),(256@1,64@0))">
      %94:2 = cute.get_scalars(%lay_47) <{only_dynamic}> : !cute.layout<"((256,64),(?,?)):((1@1,1@0),(256@1,64@0))">
      %shape_48 = cute.make_shape(%94#1) : (i32) -> !cute.shape<"(256,64,?)">
      %lay_49 = cute.make_layout(%shape_48, %13) : !cute.layout<"(256,64,?):(1@1,1@0,64@0)">
      %idx_50 = cute.crd2idx(%coord_46, %lay_47) : (!cute.coord<"((_,_),(?,_))">, !cute.layout<"((256,64),(?,?)):((1@1,1@0),(256@1,64@0))">) -> !cute.int_tuple<"(0,?{div=256})">
      %tup = cute.add_offset(%12, %idx_50) : (!cute.int_tuple<"(0,0)">, !cute.int_tuple<"(0,?{div=256})">) -> !cute.int_tuple<"(0,?{div=256})">
      %coord_51 = cute.make_coord(%90#1) : (i32) -> !cute.coord<"((_,_),(?,_))">
      %lay_52 = cute.get_layout(%arg4) : !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">
      %95:2 = cute.get_scalars(%lay_52) <{only_dynamic}> : !cute.layout<"(?,?{div=8192}):(1@1,1@0)">
      %96 = arith.ceildivsi %95#0, %c256_i32 : i32
      %97 = arith.ceildivsi %95#1, %c64_i32 : i32
      %shape_53 = cute.make_shape(%96, %97) : (i32, i32) -> !cute.shape<"((256,64),(?,?))">
      %lay_54 = cute.make_layout(%shape_53, %14) : !cute.layout<"((256,64),(?,?)):((1@1,1@0),(256@1,64@0))">
      %98:2 = cute.get_scalars(%lay_54) <{only_dynamic}> : !cute.layout<"((256,64),(?,?)):((1@1,1@0),(256@1,64@0))">
      %shape_55 = cute.make_shape(%98#1) : (i32) -> !cute.shape<"(256,64,?)">
      %lay_56 = cute.make_layout(%shape_55, %13) : !cute.layout<"(256,64,?):(1@1,1@0,64@0)">
      %idx_57 = cute.crd2idx(%coord_51, %lay_54) : (!cute.coord<"((_,_),(?,_))">, !cute.layout<"((256,64),(?,?)):((1@1,1@0),(256@1,64@0))">) -> !cute.int_tuple<"(0,?{div=256})">
      %tup_58 = cute.add_offset(%12, %idx_57) : (!cute.int_tuple<"(0,0)">, !cute.int_tuple<"(0,?{div=256})">) -> !cute.int_tuple<"(0,?{div=256})">
      %coord_59 = cute.make_coord(%90#0, %90#1) : (i32, i32) -> !cute.coord<"((_,_),(?,?))">
      %lay_60 = cute.get_layout(%arg5) : !memref_gmem_f16_
      %99:3 = cute.get_scalars(%lay_60) <{only_dynamic}> : !cute.layout<"(?,?{div=8192}):(?{i64 div=8192},1)">
      %100 = arith.ceildivsi %99#0, %c256_i32 : i32
      %101 = arith.muli %99#2, %c256_i64 : i64
      %102 = arith.ceildivsi %99#1, %c256_i32 : i32
      %shape_61 = cute.make_shape(%100, %102) : (i32, i32) -> !cute.shape<"((256,256),(?,?))">
      %iv_62 = cute.assume(%99#2) : (i64) -> !cute.i64<divby 8192>
      %iv_63 = cute.assume(%101) : (i64) -> !cute.i64<divby 2097152>
      %stride = cute.make_stride(%iv_62, %iv_63) : (!cute.i64<divby 8192>, !cute.i64<divby 2097152>) -> !cute.stride<"((?{i64 div=8192},1),(?{i64 div=2097152},256))">
      %lay_64 = cute.make_layout(%shape_61, %stride) : !cute.layout<"((256,256),(?,?)):((?{i64 div=8192},1),(?{i64 div=2097152},256))">
      %103:4 = cute.get_scalars(%lay_64) <{only_dynamic}> : !cute.layout<"((256,256),(?,?)):((?{i64 div=8192},1),(?{i64 div=2097152},256))">
      %iv_65 = cute.assume(%103#2) : (i64) -> !cute.i64<divby 8192>
      %stride_66 = cute.make_stride(%iv_65) : (!cute.i64<divby 8192>) -> !cute.stride<"(?{i64 div=8192},1)">
      %lay_67 = cute.make_layout(%11, %stride_66) : !cute.layout<"(256,256):(?{i64 div=8192},1)">
      %idx_68 = cute.crd2idx(%coord_59, %lay_64) : (!cute.coord<"((_,_),(?,?))">, !cute.layout<"((256,256),(?,?)):((?{i64 div=8192},1),(?{i64 div=2097152},256))">) -> !cute.int_tuple<"?{i64 div=256}">
      %iter_69 = cute.get_iter(%arg5) : !memref_gmem_f16_
      %ptr_70 = cute.add_offset(%iter_69, %idx_68) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{i64 div=256}">) -> !cute.ptr<f16, gmem, align<32>>
      %coord_71 = cute.make_coord(%44) : (i32) -> !cute.coord<"?">
      %104 = cute.get_scalars(%lay_49) <{only_dynamic}> : !cute.layout<"(256,64,?):(1@1,1@0,64@0)">
      %105 = cute.get_scalars(%coord_71) <{only_dynamic}> : !cute.coord<"?">
      %106 = arith.remsi %105, %c2_i32 : i32
      %107 = arith.remsi %106, %c2_i32 : i32
      %108 = arith.muli %107, %c128_i32 : i32
      %iv_72 = cute.assume(%108) : (i32) -> !cute.i32<divby 128>
      %int_tuple_73 = cute.make_int_tuple(%iv_72) : (!cute.i32<divby 128>) -> !cute.int_tuple<"(0,?{div=128})">
      %tup_74 = cute.add_offset(%tup, %int_tuple_73) : (!cute.int_tuple<"(0,?{div=256})">, !cute.int_tuple<"(0,?{div=128})">) -> !cute.int_tuple<"(0,?{div=128})">
      %shape_75 = cute.make_shape(%104) : (i32) -> !cute.shape<"((128,16),1,4,?)">
      %lay_76 = cute.make_layout(%shape_75, %10) : !cute.layout<"((128,16),1,4,?):((1@1,1@0),0,16@0,64@0)">
      %109 = cute.get_scalars(%lay_56) <{only_dynamic}> : !cute.layout<"(256,64,?):(1@1,1@0,64@0)">
      %tup_77 = cute.add_offset(%tup_58, %int_tuple_73) : (!cute.int_tuple<"(0,?{div=256})">, !cute.int_tuple<"(0,?{div=128})">) -> !cute.int_tuple<"(0,?{div=128})">
      %shape_78 = cute.make_shape(%109) : (i32) -> !cute.shape<"((128,16),1,4,?)">
      %lay_79 = cute.make_layout(%shape_78, %10) : !cute.layout<"((128,16),1,4,?):((1@1,1@0),0,16@0,64@0)">
      %110 = cute.get_scalars(%lay_67) <{only_dynamic}> : !cute.layout<"(256,256):(?{i64 div=8192},1)">
      %111 = arith.muli %110, %c128_i64 : i64
      %112 = arith.extsi %107 : i32 to i64
      %113 = arith.muli %112, %111 : i64
      %iv_80 = cute.assume(%113) : (i64) -> !cute.i64<divby 1048576>
      %int_tuple_81 = cute.make_int_tuple(%iv_80) : (!cute.i64<divby 1048576>) -> !cute.int_tuple<"?{i64 div=1048576}">
      %ptr_82 = cute.add_offset(%ptr_70, %int_tuple_81) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{i64 div=1048576}">) -> !cute.ptr<f16, gmem, align<32>>
      %iv_83 = cute.assume(%110) : (i64) -> !cute.i64<divby 8192>
      %stride_84 = cute.make_stride(%iv_83) : (!cute.i64<divby 8192>) -> !cute.stride<"((?{i64 div=8192},1),0,0)">
      %lay_85 = cute.make_layout(%9, %stride_84) : !cute.layout<"((128,256),1,1):((?{i64 div=8192},1),0,0)">
      %ummaSmemDesc = cute_nvgpu.make_umma_smem_desc(%iter_5 : !cute.ptr<f16, smem, align<128>, S<3,4,3>>) layout = <"((128,16),1,4,7):((64,1),0,16,8192)">, major = <k> -> !cute_nvgpu.smem_desc
      %ummaSmemDesc_86 = cute_nvgpu.make_umma_smem_desc(%iter_6 : !cute.ptr<f16, smem, align<128>, S<3,4,3>>) layout = <"((128,16),1,4,7):((64,1),0,16,8192)">, major = <k> -> !cute_nvgpu.smem_desc
      %114 = cute.get_scalars(%lay_76) <{only_dynamic}> : !cute.layout<"((128,16),1,4,?):((1@1,1@0),0,16@0,64@0)">
      %shape_87 = cute.make_shape(%114) : (i32) -> !cute.shape<"(((128,16),1,4),?)">
      %lay_88 = cute.make_layout(%shape_87, %8) : !cute.layout<"(((128,16),1,4),?):(((1@1,1@0),0,16@0),64@0)">
      %115 = cute.get_scalars(%lay_88) <{only_dynamic}> : !cute.layout<"(((128,16),1,4),?):(((1@1,1@0),0,16@0),64@0)">
      %shape_89 = cute.make_shape(%115) : (i32) -> !cute.shape<"(((64,128),1),?)">
      %lay_90 = cute.make_layout(%shape_89, %7) : !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">
      %116 = cute.get_scalars(%lay_79) <{only_dynamic}> : !cute.layout<"((128,16),1,4,?):((1@1,1@0),0,16@0,64@0)">
      %shape_91 = cute.make_shape(%116) : (i32) -> !cute.shape<"(((128,16),1,4),?)">
      %lay_92 = cute.make_layout(%shape_91, %8) : !cute.layout<"(((128,16),1,4),?):(((1@1,1@0),0,16@0),64@0)">
      %117 = cute.get_scalars(%lay_92) <{only_dynamic}> : !cute.layout<"(((128,16),1,4),?):(((1@1,1@0),0,16@0),64@0)">
      %shape_93 = cute.make_shape(%117) : (i32) -> !cute.shape<"(((64,128),1),?)">
      %lay_94 = cute.make_layout(%shape_93, %7) : !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">
      %coord_95 = cute.make_coord(%itup) : (!cute.int_tuple<"?">) -> !cute.coord<"(?,0,_,0)">
      %idx_96 = cute.crd2idx(%coord_95, %27) : (!cute.coord<"(?,0,_,0)">, !cute.layout<"((2),1,1,1):((1),0,0,0)">) -> !cute.int_tuple<"?">
      %e0_97 = cute.get_leaves(%idx_96) : !cute.int_tuple<"?">
      %118 = cute.get_scalars(%e0_97) : !cute.int_tuple<"?">
      %119 = arith.shli %c1_i32, %118 : i32
      %120 = arith.trunci %119 : i32 to i16
      %coord_98 = cute.make_coord(%itup) : (!cute.int_tuple<"?">) -> !cute.coord<"(?,_,0,0)">
      %idx_99 = cute.crd2idx(%coord_98, %27) : (!cute.coord<"(?,_,0,0)">, !cute.layout<"((2),1,1,1):((1),0,0,0)">) -> !cute.int_tuple<"?">
      %e0_100 = cute.get_leaves(%idx_99) : !cute.int_tuple<"?">
      %121 = cute.get_scalars(%e0_100) : !cute.int_tuple<"?">
      %122 = arith.shli %c1_i32, %121 : i32
      %123 = arith.trunci %122 : i32 to i16
      cf.cond_br %51, ^bb11, ^bb14
    ^bb11:  // pred: ^bb10
      %124 = nvvm.elect.sync -> i1
      cf.cond_br %124, ^bb12, ^bb13
    ^bb12:  // pred: ^bb11
      %125 = builtin.unrealized_conversion_cast %iter : !cute.ptr<i64, smem, align<128>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %125, %c32_i32 : !llvm.ptr<3>, i32
      cf.br ^bb13
    ^bb13:  // 2 preds: ^bb11, ^bb12
      cf.br ^bb14
    ^bb14:  // 2 preds: ^bb10, ^bb13
      nvvm.fence.mbarrier.init
      cf.cond_br %51, ^bb15, ^bb16
    ^bb15:  // pred: ^bb14
      cute_nvgpu.arch.sm100.alloc_tmem(%c512_i32, %iter_3) [cta_2] : i32, !cute.ptr<i32, smem, align<8>>
      cf.br ^bb16
    ^bb16:  // 2 preds: ^bb14, ^bb15
      nvvm.barrier id = %c1_i32 number_of_threads = %c128_i32
      %tmem_ptr = cute_nvgpu.arch.sm100.retrieve_tmem_ptr(%iter_3) : !cute.ptr<i32, smem, align<8>> -> !cute.ptr<f32, tmem, align<16>>
      %126 = cute.get_scalars(%lay_85) <{only_dynamic}> : !cute.layout<"((128,256),1,1):((?{i64 div=8192},1),0,0)">
      %iv_101 = cute.assume(%126) : (i64) -> !cute.i64<divby 8192>
      %stride_102 = cute.make_stride(%iv_101) : (!cute.i64<divby 8192>) -> !cute.stride<"(((?{i64 div=8192},1)),((0,64),0,0))">
      %lay_103 = cute.make_layout(%6, %stride_102) : !cute.layout<"(((128,64)),((1,4),1,1)):(((?{i64 div=8192},1)),((0,64),0,0))">
      %coord_104 = cute.make_coord(%28) : (i32) -> !cute.coord<"?">
      %127 = cute.get_scalars(%coord_104) <{only_dynamic}> : !cute.coord<"?">
      %128 = arith.divsi %127, %c32_i32 : i32
      %129 = arith.muli %128, %c2097152_i32 : i32
      %iv_105 = cute.assume(%129) : (i32) -> !cute.i32<divby 2097152>
      %int_tuple_106 = cute.make_int_tuple(%iv_105) : (!cute.i32<divby 2097152>) -> !cute.int_tuple<"?{div=2097152}">
      %ptr_107 = cute.add_offset(%tmem_ptr, %int_tuple_106) : (!cute.ptr<f32, tmem, align<16>>, !cute.int_tuple<"?{div=2097152}">) -> !cute.ptr<f32, tmem, align<16>>
      %130 = cute.get_scalars(%lay_103) <{only_dynamic}> : !cute.layout<"(((128,64)),((1,4),1,1)):(((?{i64 div=8192},1)),((0,64),0,0))">
      %131 = arith.muli %130, %c32_i64 : i64
      %132 = arith.remsi %127, %c32_i32 : i32
      %133 = arith.extsi %132 : i32 to i64
      %134 = arith.muli %133, %130 : i64
      %135 = arith.extsi %128 : i32 to i64
      %136 = arith.muli %135, %131 : i64
      %137 = arith.addi %134, %136 : i64
      %iv_108 = cute.assume(%137) : (i64) -> !cute.i64<divby 8192>
      %int_tuple_109 = cute.make_int_tuple(%iv_108) : (!cute.i64<divby 8192>) -> !cute.int_tuple<"?{i64 div=8192}">
      %ptr_110 = cute.add_offset(%ptr_82, %int_tuple_109) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{i64 div=8192}">) -> !cute.ptr<f16, gmem, align<32>>
      %rmem = cute.memref.alloca() : !memref_rmem_f32_
      %rmem_111 = cute.memref.alloca() : !memref_rmem_f16_
      %sz = cute.size(%lay_49) <{mode = [2]}> : (!cute.layout<"(256,64,?):(1@1,1@0,64@0)">) -> !cute.int_tuple<"?">
      %e0_112 = cute.get_leaves(%sz) : !cute.int_tuple<"?">
      %138 = cute.get_scalars(%e0_112) : !cute.int_tuple<"?">
      cf.cond_br %51, ^bb17, ^bb108
    ^bb17:  // pred: ^bb16
      %139 = arith.cmpi ne, %44, %c0_i32 : i32
      %140 = arith.extui %139 : i1 to i32
      cf.cond_br %85, ^bb18, ^bb19
    ^bb18:  // pred: ^bb17
      %141 = builtin.unrealized_conversion_cast %ptr_44 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %141, %c1_i32, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      cf.br ^bb19
    ^bb19:  // 2 preds: ^bb17, ^bb18
      %142 = cute_nvgpu.atom.make_exec_tma(%arg1) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_100_2sm_multicast, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>
      %143 = cute_nvgpu.atom.set_value(%142, %120 : i16) {field = #cute_nvgpu.atom_copy_field_tmaload<mcast_mask>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>
      %144 = cute_nvgpu.atom.make_exec_tma(%arg3) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_100_2sm_multicast, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>
      %145 = cute_nvgpu.atom.set_value(%144, %123 : i16) {field = #cute_nvgpu.atom_copy_field_tmaload<mcast_mask>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>
      %146 = arith.minsi %138, %c5_i32 : i32
      %147 = cute.get_scalars(%21) : !cute.int_tuple<"1">
      cf.br ^bb20(%c0_i32, %c0_i32, %c1_i32, %c0_i32 : i32, i32, i32, i32)
    ^bb20(%148: i32, %149: i32, %150: i32, %151: i32):  // 2 preds: ^bb19, ^bb35
      %152 = arith.cmpi slt, %148, %146 : i32
      cf.cond_br %152, ^bb21, ^bb36
    ^bb21:  // pred: ^bb20
      %int_tuple_113 = cute.make_int_tuple(%149) : (i32) -> !cute.int_tuple<"?">
      %ptr_114 = cute.add_offset(%ptr_14, %int_tuple_113) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %153 = builtin.unrealized_conversion_cast %ptr_114 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %153, %150, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      cf.cond_br %85, ^bb22, ^bb25
    ^bb22:  // pred: ^bb21
      %154 = nvvm.elect.sync -> i1
      cf.cond_br %154, ^bb23, ^bb24
    ^bb23:  // pred: ^bb22
      %ptr_115 = cute.add_offset(%iter_7, %int_tuple_113) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %155 = builtin.unrealized_conversion_cast %ptr_115 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %155, %c65536_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
      cf.br ^bb24
    ^bb24:  // 2 preds: ^bb22, ^bb23
      cf.br ^bb25
    ^bb25:  // 2 preds: ^bb21, ^bb24
      %156 = arith.addi %149, %c1_i32 : i32
      %157 = arith.addi %151, %c1_i32 : i32
      %158 = arith.cmpi eq, %156, %c7_i32 : i32
      %159 = arith.select %158, %c0_i32, %156 : i32
      cf.cond_br %158, ^bb26, ^bb27
    ^bb26:  // pred: ^bb25
      %160 = arith.xori %150, %c1_i32 : i32
      cf.br ^bb28(%160 : i32)
    ^bb27:  // pred: ^bb25
      cf.br ^bb28(%150 : i32)
    ^bb28(%161: i32):  // 2 preds: ^bb26, ^bb27
      cf.br ^bb29
    ^bb29:  // pred: ^bb28
      %coord_116 = cute.make_coord(%151) : (i32) -> !cute.coord<"(_,?)">
      %idx_117 = cute.crd2idx(%coord_116, %lay_90) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
      %tup_118 = cute.add_offset(%tup_74, %idx_117) : (!cute.int_tuple<"(0,?{div=128})">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
      %e0_119, %e1_120 = cute.get_leaves(%tup_118) : !cute.int_tuple<"(?{div=64},?{div=128})">
      %coord_121 = cute.make_coord(%149) : (i32) -> !cute.coord<"(_,?)">
      %idx_122 = cute.crd2idx(%coord_121, %5) : (!cute.coord<"(_,?)">, !cute.layout<"((8192,1),7):((1,0),8192)">) -> !cute.int_tuple<"?{div=8192}">
      %ptr_123 = cute.add_offset(%iter_5, %idx_122) : (!cute.ptr<f16, smem, align<128>, S<3,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<f16, smem, align<128>, S<3,4,3>>
      %ptr_124 = cute.add_offset(%iter_7, %int_tuple_113) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %int_tuple_125 = cute.make_int_tuple(%e0_119, %e1_120) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=128}">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
      %162 = cute_nvgpu.atom.set_value(%143, %ptr_124 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>
      %163 = cute_nvgpu.atom.get_value(%162 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
      %164 = cute_nvgpu.atom.get_value(%162 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<mcast_mask>} : i16
      %165 = cute_nvgpu.atom.get_value(%162 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<cache_policy>} : i64
      %TMADescAddr = cute_nvgpu.get_tma_desc_addr(%162 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) -> !cute.ptr<generic, align<64>>
      %166:2 = cute.get_scalars(%int_tuple_125) : !cute.int_tuple<"(?{div=64},?{div=128})">
      cf.br ^bb30(%c0_i32 : i32)
    ^bb30(%167: i32):  // 2 preds: ^bb29, ^bb31
      %168 = arith.cmpi slt, %167, %147 : i32
      cf.cond_br %168, ^bb31, ^bb32 {llvm.loop_annotation = #loop_annotation}
    ^bb31:  // pred: ^bb30
      cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr : !cute.ptr<generic, align<64>>, %ptr_123 : !cute.ptr<f16, smem, align<128>, S<3,4,3>>, %163 : !cute.ptr<smem, align<8>>, [%166#0, %166#1] : i32, i32) mask = %164 cache_policy = %165 mode = <tiled> num_cta = 2 : i32
      %169 = arith.addi %167, %c1_i32 : i32
      cf.br ^bb30(%169 : i32)
    ^bb32:  // pred: ^bb30
      %idx_126 = cute.crd2idx(%coord_116, %lay_94) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
      %tup_127 = cute.add_offset(%tup_77, %idx_126) : (!cute.int_tuple<"(0,?{div=128})">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
      %e0_128, %e1_129 = cute.get_leaves(%tup_127) : !cute.int_tuple<"(?{div=64},?{div=128})">
      %ptr_130 = cute.add_offset(%iter_6, %idx_122) : (!cute.ptr<f16, smem, align<128>, S<3,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<f16, smem, align<128>, S<3,4,3>>
      %int_tuple_131 = cute.make_int_tuple(%e0_128, %e1_129) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=128}">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
      %170 = cute_nvgpu.atom.set_value(%145, %ptr_124 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>
      %171 = cute_nvgpu.atom.get_value(%170 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
      %172 = cute_nvgpu.atom.get_value(%170 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<mcast_mask>} : i16
      %173 = cute_nvgpu.atom.get_value(%170 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<cache_policy>} : i64
      %TMADescAddr_132 = cute_nvgpu.get_tma_desc_addr(%170 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) -> !cute.ptr<generic, align<64>>
      %174:2 = cute.get_scalars(%int_tuple_131) : !cute.int_tuple<"(?{div=64},?{div=128})">
      cf.br ^bb33(%c0_i32 : i32)
    ^bb33(%175: i32):  // 2 preds: ^bb32, ^bb34
      %176 = arith.cmpi slt, %175, %147 : i32
      cf.cond_br %176, ^bb34, ^bb35 {llvm.loop_annotation = #loop_annotation}
    ^bb34:  // pred: ^bb33
      cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr_132 : !cute.ptr<generic, align<64>>, %ptr_130 : !cute.ptr<f16, smem, align<128>, S<3,4,3>>, %171 : !cute.ptr<smem, align<8>>, [%174#0, %174#1] : i32, i32) mask = %172 cache_policy = %173 mode = <tiled> num_cta = 2 : i32
      %177 = arith.addi %175, %c1_i32 : i32
      cf.br ^bb33(%177 : i32)
    ^bb35:  // pred: ^bb33
      %178 = arith.addi %148, %c1_i32 : i32
      cf.br ^bb20(%178, %159, %161, %157 : i32, i32, i32, i32)
    ^bb36:  // pred: ^bb20
      cf.br ^bb37(%c0_i32, %151, %149, %150, %c0_i32, %c0_i32, %c0_i32, %0 : i32, i32, i32, i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>)
    ^bb37(%179: i32, %180: i32, %181: i32, %182: i32, %183: i32, %184: i32, %185: i32, %186: !llvm.struct<(i1, i1, i1)>):  // 2 preds: ^bb36, ^bb102
      %187 = arith.cmpi slt, %179, %138 : i32
      cf.cond_br %187, ^bb38, ^bb103
    ^bb38:  // pred: ^bb37
      %188 = builtin.unrealized_conversion_cast %186 : !llvm.struct<(i1, i1, i1)> to !mma_f16_f16_f32_256x256x16_
      %189 = arith.addi %179, %146 : i32
      %190 = arith.cmpi ult, %189, %138 : i32
      cf.cond_br %190, ^bb39, ^bb54
    ^bb39:  // pred: ^bb38
      %int_tuple_133 = cute.make_int_tuple(%181) : (i32) -> !cute.int_tuple<"?">
      %ptr_134 = cute.add_offset(%ptr_14, %int_tuple_133) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %191 = builtin.unrealized_conversion_cast %ptr_134 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %191, %182, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      cf.cond_br %85, ^bb40, ^bb43
    ^bb40:  // pred: ^bb39
      %192 = nvvm.elect.sync -> i1
      cf.cond_br %192, ^bb41, ^bb42
    ^bb41:  // pred: ^bb40
      %ptr_135 = cute.add_offset(%iter_7, %int_tuple_133) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %193 = builtin.unrealized_conversion_cast %ptr_135 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %193, %c65536_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
      cf.br ^bb42
    ^bb42:  // 2 preds: ^bb40, ^bb41
      cf.br ^bb43
    ^bb43:  // 2 preds: ^bb39, ^bb42
      %194 = arith.addi %181, %c1_i32 : i32
      %195 = arith.addi %180, %c1_i32 : i32
      %196 = arith.cmpi eq, %194, %c7_i32 : i32
      %197 = arith.select %196, %c0_i32, %194 : i32
      cf.cond_br %196, ^bb44, ^bb45
    ^bb44:  // pred: ^bb43
      %198 = arith.xori %182, %c1_i32 : i32
      cf.br ^bb46(%198 : i32)
    ^bb45:  // pred: ^bb43
      cf.br ^bb46(%182 : i32)
    ^bb46(%199: i32):  // 2 preds: ^bb44, ^bb45
      cf.br ^bb47
    ^bb47:  // pred: ^bb46
      %coord_136 = cute.make_coord(%180) : (i32) -> !cute.coord<"(_,?)">
      %idx_137 = cute.crd2idx(%coord_136, %lay_90) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
      %tup_138 = cute.add_offset(%tup_74, %idx_137) : (!cute.int_tuple<"(0,?{div=128})">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
      %e0_139, %e1_140 = cute.get_leaves(%tup_138) : !cute.int_tuple<"(?{div=64},?{div=128})">
      %coord_141 = cute.make_coord(%181) : (i32) -> !cute.coord<"(_,?)">
      %idx_142 = cute.crd2idx(%coord_141, %5) : (!cute.coord<"(_,?)">, !cute.layout<"((8192,1),7):((1,0),8192)">) -> !cute.int_tuple<"?{div=8192}">
      %ptr_143 = cute.add_offset(%iter_5, %idx_142) : (!cute.ptr<f16, smem, align<128>, S<3,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<f16, smem, align<128>, S<3,4,3>>
      %ptr_144 = cute.add_offset(%iter_7, %int_tuple_133) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %int_tuple_145 = cute.make_int_tuple(%e0_139, %e1_140) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=128}">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
      %200 = cute_nvgpu.atom.set_value(%143, %ptr_144 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>
      %201 = cute.get_scalars(%21) : !cute.int_tuple<"1">
      %202 = cute_nvgpu.atom.get_value(%200 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
      %203 = cute_nvgpu.atom.get_value(%200 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<mcast_mask>} : i16
      %204 = cute_nvgpu.atom.get_value(%200 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<cache_policy>} : i64
      %TMADescAddr_146 = cute_nvgpu.get_tma_desc_addr(%200 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) -> !cute.ptr<generic, align<64>>
      %205:2 = cute.get_scalars(%int_tuple_145) : !cute.int_tuple<"(?{div=64},?{div=128})">
      cf.br ^bb48(%c0_i32 : i32)
    ^bb48(%206: i32):  // 2 preds: ^bb47, ^bb49
      %207 = arith.cmpi slt, %206, %201 : i32
      cf.cond_br %207, ^bb49, ^bb50 {llvm.loop_annotation = #loop_annotation}
    ^bb49:  // pred: ^bb48
      cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr_146 : !cute.ptr<generic, align<64>>, %ptr_143 : !cute.ptr<f16, smem, align<128>, S<3,4,3>>, %202 : !cute.ptr<smem, align<8>>, [%205#0, %205#1] : i32, i32) mask = %203 cache_policy = %204 mode = <tiled> num_cta = 2 : i32
      %208 = arith.addi %206, %c1_i32 : i32
      cf.br ^bb48(%208 : i32)
    ^bb50:  // pred: ^bb48
      %idx_147 = cute.crd2idx(%coord_136, %lay_94) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
      %tup_148 = cute.add_offset(%tup_77, %idx_147) : (!cute.int_tuple<"(0,?{div=128})">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
      %e0_149, %e1_150 = cute.get_leaves(%tup_148) : !cute.int_tuple<"(?{div=64},?{div=128})">
      %ptr_151 = cute.add_offset(%iter_6, %idx_142) : (!cute.ptr<f16, smem, align<128>, S<3,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<f16, smem, align<128>, S<3,4,3>>
      %int_tuple_152 = cute.make_int_tuple(%e0_149, %e1_150) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=128}">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
      %209 = cute_nvgpu.atom.set_value(%145, %ptr_144 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>
      %210 = cute_nvgpu.atom.get_value(%209 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
      %211 = cute_nvgpu.atom.get_value(%209 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<mcast_mask>} : i16
      %212 = cute_nvgpu.atom.get_value(%209 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<cache_policy>} : i64
      %TMADescAddr_153 = cute_nvgpu.get_tma_desc_addr(%209 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) -> !cute.ptr<generic, align<64>>
      %213:2 = cute.get_scalars(%int_tuple_152) : !cute.int_tuple<"(?{div=64},?{div=128})">
      cf.br ^bb51(%c0_i32 : i32)
    ^bb51(%214: i32):  // 2 preds: ^bb50, ^bb52
      %215 = arith.cmpi slt, %214, %201 : i32
      cf.cond_br %215, ^bb52, ^bb53 {llvm.loop_annotation = #loop_annotation}
    ^bb52:  // pred: ^bb51
      cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr_153 : !cute.ptr<generic, align<64>>, %ptr_151 : !cute.ptr<f16, smem, align<128>, S<3,4,3>>, %210 : !cute.ptr<smem, align<8>>, [%213#0, %213#1] : i32, i32) mask = %211 cache_policy = %212 mode = <tiled> num_cta = 2 : i32
      %216 = arith.addi %214, %c1_i32 : i32
      cf.br ^bb51(%216 : i32)
    ^bb53:  // pred: ^bb51
      cf.br ^bb55(%197, %199, %195 : i32, i32, i32)
    ^bb54:  // pred: ^bb38
      cf.br ^bb55(%181, %182, %180 : i32, i32, i32)
    ^bb55(%217: i32, %218: i32, %219: i32):  // 2 preds: ^bb53, ^bb54
      cf.br ^bb56
    ^bb56:  // pred: ^bb55
      cf.cond_br %85, ^bb57, ^bb100
    ^bb57:  // pred: ^bb56
      %int_tuple_154 = cute.make_int_tuple(%184) : (i32) -> !cute.int_tuple<"?">
      %ptr_155 = cute.add_offset(%iter_7, %int_tuple_154) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %220 = builtin.unrealized_conversion_cast %ptr_155 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %220, %185, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %221 = arith.addi %184, %c1_i32 : i32
      %222 = arith.addi %183, %c1_i32 : i32
      %223 = arith.cmpi eq, %221, %c7_i32 : i32
      %224 = arith.select %223, %c0_i32, %221 : i32
      cf.cond_br %223, ^bb58, ^bb59
    ^bb58:  // pred: ^bb57
      %225 = arith.xori %185, %c1_i32 : i32
      cf.br ^bb60(%225 : i32)
    ^bb59:  // pred: ^bb57
      cf.br ^bb60(%185 : i32)
    ^bb60(%226: i32):  // 2 preds: ^bb58, ^bb59
      cf.br ^bb61
    ^bb61:  // pred: ^bb60
      %coord_156 = cute.make_coord(%184) : (i32) -> !cute.coord<"(_,_,0,?)">
      %idx_157 = cute.crd2idx(%coord_156, %4) : (!cute.coord<"(_,_,0,?)">, !cute.layout<"(1,1,4,7):(0,0,2,1024)">) -> !cute.int_tuple<"?{div=1024}">
      %tup_158 = cute.add_offset(%ummaSmemDesc, %idx_157) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=1024}">) -> !cute_nvgpu.smem_desc
      %tup_159 = cute.add_offset(%ummaSmemDesc_86, %idx_157) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=1024}">) -> !cute_nvgpu.smem_desc
      %227 = cute.get_scalars(%21) : !cute.int_tuple<"1">
      %228 = cute_nvgpu.atom.get_value(%188 : !mma_f16_f16_f32_256x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : i1
      %229 = cute_nvgpu.atom.get_value(%188 : !mma_f16_f16_f32_256x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : i1
      %230 = cute_nvgpu.atom.get_value(%188 : !mma_f16_f16_f32_256x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : i1
      %231 = arith.extui %228 : i1 to i32
      %232 = arith.extui %229 : i1 to i32
      %233 = arith.shli %231, %c13_i32 : i32
      %234 = arith.shli %232, %c14_i32 : i32
      %235 = arith.ori %233, %c272629776_i32 : i32
      %236 = arith.ori %235, %234 : i32
      cf.br ^bb62(%c0_i32 : i32)
    ^bb62(%237: i32):  // 2 preds: ^bb61, ^bb69
      %238 = arith.cmpi slt, %237, %227 : i32
      cf.cond_br %238, ^bb63, ^bb70 {llvm.loop_annotation = #loop_annotation}
    ^bb63:  // pred: ^bb62
      cf.br ^bb64(%c0_i32 : i32)
    ^bb64(%239: i32):  // 2 preds: ^bb63, ^bb68
      %240 = arith.cmpi slt, %239, %227 : i32
      cf.cond_br %240, ^bb65, ^bb69 {llvm.loop_annotation = #loop_annotation}
    ^bb65:  // pred: ^bb64
      cf.br ^bb66(%c0_i32 : i32)
    ^bb66(%241: i32):  // 2 preds: ^bb65, ^bb67
      %242 = arith.cmpi slt, %241, %227 : i32
      cf.cond_br %242, ^bb67, ^bb68 {llvm.loop_annotation = #loop_annotation}
    ^bb67:  // pred: ^bb66
      cute_nvgpu.arch.mma.SM100.umma(%tup_158, %tup_159, %tmem_ptr, %236, %230) {num_cta = 2 : i32, scale = 0 : i32, a_type = f16} : (!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, !cute.ptr<f32, tmem, align<16>>, i32, i1) -> ()
      %243 = arith.addi %241, %c1_i32 : i32
      cf.br ^bb66(%243 : i32)
    ^bb68:  // pred: ^bb66
      %244 = arith.addi %239, %c1_i32 : i32
      cf.br ^bb64(%244 : i32)
    ^bb69:  // pred: ^bb64
      %245 = arith.addi %237, %c1_i32 : i32
      cf.br ^bb62(%245 : i32)
    ^bb70:  // pred: ^bb62
      %246 = cute_nvgpu.atom.set_value(%188, %true : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_f16_f16_f32_256x256x16_
      %coord_160 = cute.make_coord(%184) : (i32) -> !cute.coord<"(_,_,1,?)">
      %idx_161 = cute.crd2idx(%coord_160, %4) : (!cute.coord<"(_,_,1,?)">, !cute.layout<"(1,1,4,7):(0,0,2,1024)">) -> !cute.int_tuple<"?{div=2}">
      %tup_162 = cute.add_offset(%ummaSmemDesc, %idx_161) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
      %tup_163 = cute.add_offset(%ummaSmemDesc_86, %idx_161) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
      %247 = cute_nvgpu.atom.get_value(%246 : !mma_f16_f16_f32_256x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : i1
      %248 = cute_nvgpu.atom.get_value(%246 : !mma_f16_f16_f32_256x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : i1
      %249 = cute_nvgpu.atom.get_value(%246 : !mma_f16_f16_f32_256x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : i1
      %250 = arith.extui %247 : i1 to i32
      %251 = arith.extui %248 : i1 to i32
      %252 = arith.shli %250, %c13_i32 : i32
      %253 = arith.shli %251, %c14_i32 : i32
      %254 = arith.ori %252, %c272629776_i32 : i32
      %255 = arith.ori %254, %253 : i32
      cf.br ^bb71(%c0_i32 : i32)
    ^bb71(%256: i32):  // 2 preds: ^bb70, ^bb78
      %257 = arith.cmpi slt, %256, %227 : i32
      cf.cond_br %257, ^bb72, ^bb79 {llvm.loop_annotation = #loop_annotation}
    ^bb72:  // pred: ^bb71
      cf.br ^bb73(%c0_i32 : i32)
    ^bb73(%258: i32):  // 2 preds: ^bb72, ^bb77
      %259 = arith.cmpi slt, %258, %227 : i32
      cf.cond_br %259, ^bb74, ^bb78 {llvm.loop_annotation = #loop_annotation}
    ^bb74:  // pred: ^bb73
      cf.br ^bb75(%c0_i32 : i32)
    ^bb75(%260: i32):  // 2 preds: ^bb74, ^bb76
      %261 = arith.cmpi slt, %260, %227 : i32
      cf.cond_br %261, ^bb76, ^bb77 {llvm.loop_annotation = #loop_annotation}
    ^bb76:  // pred: ^bb75
      cute_nvgpu.arch.mma.SM100.umma(%tup_162, %tup_163, %tmem_ptr, %255, %249) {num_cta = 2 : i32, scale = 0 : i32, a_type = f16} : (!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, !cute.ptr<f32, tmem, align<16>>, i32, i1) -> ()
      %262 = arith.addi %260, %c1_i32 : i32
      cf.br ^bb75(%262 : i32)
    ^bb77:  // pred: ^bb75
      %263 = arith.addi %258, %c1_i32 : i32
      cf.br ^bb73(%263 : i32)
    ^bb78:  // pred: ^bb73
      %264 = arith.addi %256, %c1_i32 : i32
      cf.br ^bb71(%264 : i32)
    ^bb79:  // pred: ^bb71
      %265 = cute_nvgpu.atom.set_value(%246, %true : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_f16_f16_f32_256x256x16_
      %coord_164 = cute.make_coord(%184) : (i32) -> !cute.coord<"(_,_,2,?)">
      %idx_165 = cute.crd2idx(%coord_164, %4) : (!cute.coord<"(_,_,2,?)">, !cute.layout<"(1,1,4,7):(0,0,2,1024)">) -> !cute.int_tuple<"?{div=4}">
      %tup_166 = cute.add_offset(%ummaSmemDesc, %idx_165) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=4}">) -> !cute_nvgpu.smem_desc
      %tup_167 = cute.add_offset(%ummaSmemDesc_86, %idx_165) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=4}">) -> !cute_nvgpu.smem_desc
      %266 = cute_nvgpu.atom.get_value(%265 : !mma_f16_f16_f32_256x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : i1
      %267 = cute_nvgpu.atom.get_value(%265 : !mma_f16_f16_f32_256x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : i1
      %268 = cute_nvgpu.atom.get_value(%265 : !mma_f16_f16_f32_256x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : i1
      %269 = arith.extui %266 : i1 to i32
      %270 = arith.extui %267 : i1 to i32
      %271 = arith.shli %269, %c13_i32 : i32
      %272 = arith.shli %270, %c14_i32 : i32
      %273 = arith.ori %271, %c272629776_i32 : i32
      %274 = arith.ori %273, %272 : i32
      cf.br ^bb80(%c0_i32 : i32)
    ^bb80(%275: i32):  // 2 preds: ^bb79, ^bb87
      %276 = arith.cmpi slt, %275, %227 : i32
      cf.cond_br %276, ^bb81, ^bb88 {llvm.loop_annotation = #loop_annotation}
    ^bb81:  // pred: ^bb80
      cf.br ^bb82(%c0_i32 : i32)
    ^bb82(%277: i32):  // 2 preds: ^bb81, ^bb86
      %278 = arith.cmpi slt, %277, %227 : i32
      cf.cond_br %278, ^bb83, ^bb87 {llvm.loop_annotation = #loop_annotation}
    ^bb83:  // pred: ^bb82
      cf.br ^bb84(%c0_i32 : i32)
    ^bb84(%279: i32):  // 2 preds: ^bb83, ^bb85
      %280 = arith.cmpi slt, %279, %227 : i32
      cf.cond_br %280, ^bb85, ^bb86 {llvm.loop_annotation = #loop_annotation}
    ^bb85:  // pred: ^bb84
      cute_nvgpu.arch.mma.SM100.umma(%tup_166, %tup_167, %tmem_ptr, %274, %268) {num_cta = 2 : i32, scale = 0 : i32, a_type = f16} : (!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, !cute.ptr<f32, tmem, align<16>>, i32, i1) -> ()
      %281 = arith.addi %279, %c1_i32 : i32
      cf.br ^bb84(%281 : i32)
    ^bb86:  // pred: ^bb84
      %282 = arith.addi %277, %c1_i32 : i32
      cf.br ^bb82(%282 : i32)
    ^bb87:  // pred: ^bb82
      %283 = arith.addi %275, %c1_i32 : i32
      cf.br ^bb80(%283 : i32)
    ^bb88:  // pred: ^bb80
      %284 = cute_nvgpu.atom.set_value(%265, %true : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_f16_f16_f32_256x256x16_
      %coord_168 = cute.make_coord(%184) : (i32) -> !cute.coord<"(_,_,3,?)">
      %idx_169 = cute.crd2idx(%coord_168, %4) : (!cute.coord<"(_,_,3,?)">, !cute.layout<"(1,1,4,7):(0,0,2,1024)">) -> !cute.int_tuple<"?{div=2}">
      %tup_170 = cute.add_offset(%ummaSmemDesc, %idx_169) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
      %tup_171 = cute.add_offset(%ummaSmemDesc_86, %idx_169) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
      %285 = cute_nvgpu.atom.get_value(%284 : !mma_f16_f16_f32_256x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : i1
      %286 = cute_nvgpu.atom.get_value(%284 : !mma_f16_f16_f32_256x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : i1
      %287 = cute_nvgpu.atom.get_value(%284 : !mma_f16_f16_f32_256x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : i1
      %288 = arith.extui %285 : i1 to i32
      %289 = arith.extui %286 : i1 to i32
      %290 = arith.shli %288, %c13_i32 : i32
      %291 = arith.shli %289, %c14_i32 : i32
      %292 = arith.ori %290, %c272629776_i32 : i32
      %293 = arith.ori %292, %291 : i32
      cf.br ^bb89(%c0_i32 : i32)
    ^bb89(%294: i32):  // 2 preds: ^bb88, ^bb96
      %295 = arith.cmpi slt, %294, %227 : i32
      cf.cond_br %295, ^bb90, ^bb97 {llvm.loop_annotation = #loop_annotation}
    ^bb90:  // pred: ^bb89
      cf.br ^bb91(%c0_i32 : i32)
    ^bb91(%296: i32):  // 2 preds: ^bb90, ^bb95
      %297 = arith.cmpi slt, %296, %227 : i32
      cf.cond_br %297, ^bb92, ^bb96 {llvm.loop_annotation = #loop_annotation}
    ^bb92:  // pred: ^bb91
      cf.br ^bb93(%c0_i32 : i32)
    ^bb93(%298: i32):  // 2 preds: ^bb92, ^bb94
      %299 = arith.cmpi slt, %298, %227 : i32
      cf.cond_br %299, ^bb94, ^bb95 {llvm.loop_annotation = #loop_annotation}
    ^bb94:  // pred: ^bb93
      cute_nvgpu.arch.mma.SM100.umma(%tup_170, %tup_171, %tmem_ptr, %293, %287) {num_cta = 2 : i32, scale = 0 : i32, a_type = f16} : (!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, !cute.ptr<f32, tmem, align<16>>, i32, i1) -> ()
      %300 = arith.addi %298, %c1_i32 : i32
      cf.br ^bb93(%300 : i32)
    ^bb95:  // pred: ^bb93
      %301 = arith.addi %296, %c1_i32 : i32
      cf.br ^bb91(%301 : i32)
    ^bb96:  // pred: ^bb91
      %302 = arith.addi %294, %c1_i32 : i32
      cf.br ^bb89(%302 : i32)
    ^bb97:  // pred: ^bb89
      %303 = cute_nvgpu.atom.set_value(%284, %true : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_f16_f16_f32_256x256x16_
      %304 = builtin.unrealized_conversion_cast %303 : !mma_f16_f16_f32_256x256x16_ to !llvm.struct<(i1, i1, i1)>
      %305 = nvvm.elect.sync -> i1
      cf.cond_br %305, ^bb98, ^bb99
    ^bb98:  // pred: ^bb97
      %ptr_172 = cute.add_offset(%ptr_14, %int_tuple_154) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %306 = builtin.unrealized_conversion_cast %ptr_172 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.tcgen05.commit.arrive %306, multicast_mask = %84 {group = #nvvm.tcgen05_group<cta_2>} : !llvm.ptr<3>, i16
      cf.br ^bb99
    ^bb99:  // 2 preds: ^bb97, ^bb98
      cf.br ^bb101(%222, %224, %226, %304 : i32, i32, i32, !llvm.struct<(i1, i1, i1)>)
    ^bb100:  // pred: ^bb56
      cf.br ^bb101(%183, %184, %185, %186 : i32, i32, i32, !llvm.struct<(i1, i1, i1)>)
    ^bb101(%307: i32, %308: i32, %309: i32, %310: !llvm.struct<(i1, i1, i1)>):  // 2 preds: ^bb99, ^bb100
      cf.br ^bb102
    ^bb102:  // pred: ^bb101
      %311 = arith.addi %179, %c1_i32 : i32
      cf.br ^bb37(%311, %219, %217, %218, %307, %308, %309, %310 : i32, i32, i32, i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>)
    ^bb103:  // pred: ^bb37
      cf.cond_br %85, ^bb104, ^bb107
    ^bb104:  // pred: ^bb103
      %312 = nvvm.elect.sync -> i1
      cf.cond_br %312, ^bb105, ^bb106
    ^bb105:  // pred: ^bb104
      %dyn_173 = cute.derefine(%iter_43) : !cute.ptr<i64, smem, align<16>> to !cute.ptr<i64, smem>
      %313 = builtin.unrealized_conversion_cast %dyn_173 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.tcgen05.commit.arrive %313, multicast_mask = %c3_i16 {group = #nvvm.tcgen05_group<cta_2>} : !llvm.ptr<3>, i16
      cf.br ^bb106
    ^bb106:  // 2 preds: ^bb104, ^bb105
      cf.br ^bb107
    ^bb107:  // 2 preds: ^bb103, ^bb106
      cf.br ^bb109(%140, %181, %182 : i32, i32, i32)
    ^bb108:  // pred: ^bb16
      cf.br ^bb109(%c1_i32, %c0_i32, %c1_i32 : i32, i32, i32)
    ^bb109(%314: i32, %315: i32, %316: i32):  // 2 preds: ^bb107, ^bb108
      cf.br ^bb110
    ^bb110:  // pred: ^bb109
      cf.cond_br %51, ^bb111, ^bb112
    ^bb111:  // pred: ^bb110
      cute_nvgpu.arch.sm100.relinquish_tmem_alloc_permit [cta_2]
      cf.br ^bb112
    ^bb112:  // 2 preds: ^bb110, ^bb111
      %dyn_174 = cute.derefine(%iter_43) : !cute.ptr<i64, smem, align<16>> to !cute.ptr<i64, smem>
      %317 = builtin.unrealized_conversion_cast %dyn_174 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %317, %c0_i32, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %iter_175 = cute.get_iter(%rmem) : !memref_rmem_f32_
      %318 = cute.get_scalars(%21) : !cute.int_tuple<"1">
      %319 = builtin.unrealized_conversion_cast %iter_175 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
      %iter_176 = cute.get_iter(%rmem_111) : !memref_rmem_f16_
      %320 = cute.get_scalars(%18) : !cute.int_tuple<"4">
      cf.br ^bb113(%c0_i32 : i32)
    ^bb113(%321: i32):  // 2 preds: ^bb112, ^bb120
      %322 = arith.cmpi slt, %321, %c4_i32 : i32
      cf.cond_br %322, ^bb114, ^bb121
    ^bb114:  // pred: ^bb113
      %coord_177 = cute.make_coord(%321) : (i32) -> !cute.coord<"(_,_,?)">
      %idx_178 = cute.crd2idx(%coord_177, %3) : (!cute.coord<"(_,_,?)">, !cute.layout<"(((64,32),1),1,((1,4),1,1)):(((1,65536),0),0,((0,64),0,0))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_179 = cute.add_offset(%ptr_107, %idx_178) : (!cute.ptr<f32, tmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<f32, tmem, align<16>>
      cf.br ^bb115(%c0_i32 : i32)
    ^bb115(%323: i32):  // 2 preds: ^bb114, ^bb116
      %324 = arith.cmpi slt, %323, %318 : i32
      cf.cond_br %324, ^bb116, ^bb117 {llvm.loop_annotation = #loop_annotation}
    ^bb116:  // pred: ^bb115
      %325 = "cute_nvgpu.arch.copy.SM100.tmem_load"(%ptr_179) <{num_b = 32 : i32, num_dp = 32 : i32, num_rep = 64 : i32}> : (!cute.ptr<f32, tmem, align<16>>) -> vector<64xi32>
      llvm.store %325, %319 : vector<64xi32>, !llvm.ptr
      %326 = arith.addi %323, %c1_i32 : i32
      cf.br ^bb115(%326 : i32)
    ^bb117:  // pred: ^bb115
      %327 = cute.memref.load_vec %rmem : !memref_rmem_f32_
      %328 = arith.truncf %327 : vector<64xf32> to vector<64xf16>
      cute.memref.store_vec %328, %rmem_111 : !memref_rmem_f16_
      %idx_180 = cute.crd2idx(%coord_177, %2) : (!cute.coord<"(_,_,?)">, !cute.layout<"((64,1),1,((1,4),1,1)):((1,0),0,((0,64),0,0))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_181 = cute.add_offset(%ptr_110, %idx_180) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<f16, gmem, align<32>>
      cf.br ^bb118(%c0_i32 : i32)
    ^bb118(%329: i32):  // 2 preds: ^bb117, ^bb119
      %330 = arith.cmpi slt, %329, %320 : i32
      cf.cond_br %330, ^bb119, ^bb120 {llvm.loop_annotation = #loop_annotation}
    ^bb119:  // pred: ^bb118
      %coord_182 = cute.make_coord(%329) : (i32) -> !cute.coord<"(_,?)">
      %idx_183 = cute.crd2idx(%coord_182, %1) : (!cute.coord<"(_,?)">, !cute.layout<"(16,(4)):(1,(16))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_184 = cute.add_offset(%iter_176, %idx_183) : (!cute.ptr<f16, rmem, align<32>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<f16, rmem, align<32>>
      %ptr_185 = cute.add_offset(%ptr_181, %idx_183) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<f16, gmem, align<32>>
      %331 = builtin.unrealized_conversion_cast %ptr_184 : !cute.ptr<f16, rmem, align<32>> to !llvm.ptr
      %332 = builtin.unrealized_conversion_cast %ptr_185 : !cute.ptr<f16, gmem, align<32>> to !llvm.ptr<1>
      %333 = llvm.load %331 {alignment = 32 : i64} : !llvm.ptr -> vector<16xf16>
      llvm.store %333, %332 {alignment = 32 : i64} : vector<16xf16>, !llvm.ptr<1>
      %334 = arith.addi %329, %c1_i32 : i32
      cf.br ^bb118(%334 : i32)
    ^bb120:  // pred: ^bb118
      %335 = arith.addi %321, %c1_i32 : i32
      cf.br ^bb113(%335 : i32)
    ^bb121:  // pred: ^bb113
      %336 = builtin.unrealized_conversion_cast %ptr_44 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      %337 = nvvm.mapa.shared.cluster %336, %89 : !llvm.ptr<3>, i32 -> <3>
      nvvm.mbarrier.txn %337, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>, space = #nvvm.mbar_space<cluster>} : !llvm.ptr<3>, i32
      cf.cond_br %51, ^bb122, ^bb155
    ^bb122:  // pred: ^bb121
      %338 = arith.addi %315, %c1_i32 : i32
      %339 = arith.cmpi eq, %338, %c7_i32 : i32
      %340 = arith.select %339, %c0_i32, %338 : i32
      cf.cond_br %339, ^bb123, ^bb124
    ^bb123:  // pred: ^bb122
      %341 = arith.xori %316, %c1_i32 : i32
      cf.br ^bb125(%341 : i32)
    ^bb124:  // pred: ^bb122
      cf.br ^bb125(%316 : i32)
    ^bb125(%342: i32):  // 2 preds: ^bb123, ^bb124
      cf.br ^bb126
    ^bb126:  // pred: ^bb125
      %343 = arith.addi %340, %c1_i32 : i32
      %344 = arith.cmpi eq, %343, %c7_i32 : i32
      %345 = arith.select %344, %c0_i32, %343 : i32
      cf.cond_br %344, ^bb127, ^bb128
    ^bb127:  // pred: ^bb126
      %346 = arith.xori %342, %c1_i32 : i32
      cf.br ^bb129(%346 : i32)
    ^bb128:  // pred: ^bb126
      cf.br ^bb129(%342 : i32)
    ^bb129(%347: i32):  // 2 preds: ^bb127, ^bb128
      cf.br ^bb130
    ^bb130:  // pred: ^bb129
      %348 = arith.addi %345, %c1_i32 : i32
      %349 = arith.cmpi eq, %348, %c7_i32 : i32
      %350 = arith.select %349, %c0_i32, %348 : i32
      cf.cond_br %349, ^bb131, ^bb132
    ^bb131:  // pred: ^bb130
      %351 = arith.xori %347, %c1_i32 : i32
      cf.br ^bb133(%351 : i32)
    ^bb132:  // pred: ^bb130
      cf.br ^bb133(%347 : i32)
    ^bb133(%352: i32):  // 2 preds: ^bb131, ^bb132
      cf.br ^bb134
    ^bb134:  // pred: ^bb133
      %353 = arith.addi %350, %c1_i32 : i32
      %354 = arith.cmpi eq, %353, %c7_i32 : i32
      %355 = arith.select %354, %c0_i32, %353 : i32
      cf.cond_br %354, ^bb135, ^bb136
    ^bb135:  // pred: ^bb134
      %356 = arith.xori %352, %c1_i32 : i32
      cf.br ^bb137(%356 : i32)
    ^bb136:  // pred: ^bb134
      cf.br ^bb137(%352 : i32)
    ^bb137(%357: i32):  // 2 preds: ^bb135, ^bb136
      cf.br ^bb138
    ^bb138:  // pred: ^bb137
      %358 = arith.addi %355, %c1_i32 : i32
      %359 = arith.cmpi eq, %358, %c7_i32 : i32
      %360 = arith.select %359, %c0_i32, %358 : i32
      cf.cond_br %359, ^bb139, ^bb140
    ^bb139:  // pred: ^bb138
      %361 = arith.xori %357, %c1_i32 : i32
      cf.br ^bb141(%361 : i32)
    ^bb140:  // pred: ^bb138
      cf.br ^bb141(%357 : i32)
    ^bb141(%362: i32):  // 2 preds: ^bb139, ^bb140
      cf.br ^bb142
    ^bb142:  // pred: ^bb141
      %363 = arith.addi %360, %c1_i32 : i32
      %364 = arith.cmpi eq, %363, %c7_i32 : i32
      %365 = arith.select %364, %c0_i32, %363 : i32
      cf.cond_br %364, ^bb143, ^bb144
    ^bb143:  // pred: ^bb142
      %366 = arith.xori %362, %c1_i32 : i32
      cf.br ^bb145(%366 : i32)
    ^bb144:  // pred: ^bb142
      cf.br ^bb145(%362 : i32)
    ^bb145(%367: i32):  // 2 preds: ^bb143, ^bb144
      cf.br ^bb146
    ^bb146:  // pred: ^bb145
      %int_tuple_186 = cute.make_int_tuple(%365) : (i32) -> !cute.int_tuple<"?">
      %ptr_187 = cute.add_offset(%ptr_14, %int_tuple_186) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %368 = builtin.unrealized_conversion_cast %ptr_187 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %368, %367, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      cf.cond_br %85, ^bb147, ^bb150
    ^bb147:  // pred: ^bb146
      %369 = nvvm.elect.sync -> i1
      cf.cond_br %369, ^bb148, ^bb149
    ^bb148:  // pred: ^bb147
      %ptr_188 = cute.add_offset(%iter_7, %int_tuple_186) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %370 = builtin.unrealized_conversion_cast %ptr_188 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %370, %c65536_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
      cf.br ^bb149
    ^bb149:  // 2 preds: ^bb147, ^bb148
      cf.br ^bb150
    ^bb150:  // 2 preds: ^bb146, ^bb149
      cf.cond_br %85, ^bb151, ^bb154
    ^bb151:  // pred: ^bb150
      %371 = arith.remsi %66, %c2_i32 : i32
      %372 = arith.cmpi eq, %371, %c0_i32 : i32
      cf.cond_br %372, ^bb152, ^bb153
    ^bb152:  // pred: ^bb151
      nvvm.mbarrier.try_wait.parity.shared %336, %314, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      cf.br ^bb153
    ^bb153:  // 2 preds: ^bb151, ^bb152
      cf.br ^bb154
    ^bb154:  // 2 preds: ^bb150, ^bb153
      cf.br ^bb155
    ^bb155:  // 2 preds: ^bb121, ^bb154
      nvvm.barrier id = %c1_i32
      cf.cond_br %51, ^bb156, ^bb157
    ^bb156:  // pred: ^bb155
      %373 = arith.xori %66, %c1_i32 : i32
      %374 = builtin.unrealized_conversion_cast %iter : !cute.ptr<i64, smem, align<128>> to !llvm.ptr<3>
      %375 = nvvm.mapa.shared.cluster %374, %373 : !llvm.ptr<3>, i32 -> <3>
      nvvm.mbarrier.txn %375, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>, space = #nvvm.mbar_space<cluster>} : !llvm.ptr<3>, i32
      nvvm.mbarrier.try_wait.parity.shared %374, %c0_i32, %c10000000_i32 : !llvm.ptr<3>, i32, i32
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
    %149 = arith.ceildivsi %148#0, %c128_i32 : i32
    %150 = arith.ceildivsi %148#1, %c256_i32 : i32
    %int_tuple_8 = cute.make_int_tuple(%149, %150) : (i32, i32) -> !cute.int_tuple<"(?,?,1)">
    %e0_9, %e1_10, %e2 = cute.get_leaves(%int_tuple_8) : !cute.int_tuple<"(?,?,1)">
    %tup = cute.add_offset(%e0_9, %3) : (!cute.int_tuple<"?">, !cute.int_tuple<"2">) -> !cute.int_tuple<"?">
    %sub = cute.tuple_sub(%tup, %4) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
    %div = cute.tuple_div(%sub, %3) : (!cute.int_tuple<"?">, !cute.int_tuple<"2">) -> !cute.int_tuple<"?">
    %mul = cute.tuple_mul(%div, %3) : (!cute.int_tuple<"?">, !cute.int_tuple<"2">) -> !cute.int_tuple<"?{div=2}">
    %151 = cute.get_scalars(%mul) : !cute.int_tuple<"?{div=2}">
    %tup_11 = cute.add_offset(%e1_10, %4) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
    %sub_12 = cute.tuple_sub(%tup_11, %4) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
    %div_13 = cute.tuple_div(%sub_12, %4) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
    %mul_14 = cute.tuple_mul(%div_13, %4) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
    %152 = cute.get_scalars(%mul_14) : !cute.int_tuple<"?">
    %153 = cuda.cast %c0_i64 : i64 -> !cuda.stream
    %154 = cuda.launch_cfg.create<max_attrs = 2 : i32> (blockDim = (%c128_i32, %c1_i32, %c1_i32), dynamicSmemBytes = %c229632_i64, gridDim = (%151, %152, %c1_i32), stream = %153) : i32, i32, i32, i64, i32, i32, i32, !cuda.stream -> !cuda.launch_cfg<max_attrs = 2>
    cuda.launch_cfg.cluster_dim[%154] (%c2_i32, %c1_i32, %c1_i32) : !cuda.launch_cfg<max_attrs = 2>, i32, i32, i32
    %155 = cuda.launch_ex @kernels::@kernel_cutlass_kernel_TiledMMA_ThrLayoutVMNK21111000_PermutationMNK____MMAAtom_ThrID21_ShapeMNK25625616_TVLayoutA2128161281256_TVLayoutB2128161281256_TVLayoutC21282561281256_CopyAtom_ThrI_0<%154> (%10, %87, %view, %145, %view_5, %arg2) : !cuda.launch_cfg<max_attrs = 2>, (!mma_f16_f16_f32_256x256x16_, !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_100_2sm_multicast, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, internal_val_type = f16>, !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">, !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_100_2sm_multicast, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, internal_val_type = f16>, !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">, !memref_gmem_f16_) -> !cuda.result
    %156 = cuda.cast %155 : !cuda.result -> i32
    cuda.return_if_error %156 : i32
    return %c0_i32 : i32
  }
}
