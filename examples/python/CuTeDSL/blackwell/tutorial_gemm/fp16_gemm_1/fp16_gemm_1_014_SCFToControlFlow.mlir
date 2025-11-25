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
      %39 = arith.floordivsi %38, %c32_i32 : i32
      %40 = cute_nvgpu.arch.make_warp_uniform(%39) : i32
      %41 = nvvm.read.ptx.sreg.ctaid.x range <i32, 0, 2147483647> : i32
      %42 = nvvm.read.ptx.sreg.ctaid.y range <i32, 0, 65535> : i32
      %43 = nvvm.read.ptx.sreg.cluster.ctarank : i32
      %44 = cute.get_flat_coord(%43, %28) : (i32, !cute.layout<"((2),1,1,1):((1),0,0,0)">) -> !cute.coord<"(?,0,0,0)">
      %e0, %e1, %e2, %e3 = cute.get_leaves(%44) : !cute.coord<"(?,0,0,0)">
      %itup = cute.to_int_tuple(%e0) : !cute.coord<"?"> to !cute.int_tuple<"?">
      %45 = arith.remsi %41, %c2_i32 : i32
      %46 = arith.floordivsi %41, %c2_i32 : i32
      %smem_ptr = cute_nvgpu.arch.get_dyn_smem() : !cute.ptr<i8, smem, align<1024>>
      %ptr = cute.add_offset(%smem_ptr, %27) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"144">) -> !cute.ptr<i8, smem, align<16>>
      %ptr_0 = cute.add_offset(%smem_ptr, %26) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"112">) -> !cute.ptr<i8, smem, align<16>>
      %ptr_1 = cute.add_offset(%smem_ptr, %25) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"128">) -> !cute.ptr<i8, smem, align<128>>
      %iter = cute.recast_iter(%ptr_1) : !cute.ptr<i8, smem, align<128>> to !cute.ptr<i64, smem, align<128>>
      %ptr_2 = cute.add_offset(%smem_ptr, %24) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"136">) -> !cute.ptr<i8, smem, align<8>>
      %iter_3 = cute.recast_iter(%ptr_2) : !cute.ptr<i8, smem, align<8>> to !cute.ptr<i32, smem, align<8>>
      %47 = cute.ptrtoint(%ptr) : !cute.ptr<i8, smem, align<16>> to i32
      %48 = arith.addi %47, %c127_i32 : i32
      %49 = arith.andi %48, %c-128_i32 : i32
      %50 = arith.extsi %49 : i32 to i64
      %iv = cute.assume(%50) : (i64) -> !cute.i64<divby 128>
      %51 = cute.inttoptr(%iv) : !cute.i64<divby 128> to !cute.ptr<i8, smem, align<128>>
      %ptr_4 = cute.add_offset(%51, %23) : (!cute.ptr<i8, smem, align<128>>, !cute.int_tuple<"114688">) -> !cute.ptr<i8, smem, align<128>>
      %iter_5 = cute.recast_iter(%51) : !cute.ptr<i8, smem, align<128>> to !cute.ptr<f16, smem, align<128>, S<3,4,3>>
      %iter_6 = cute.recast_iter(%ptr_4) : !cute.ptr<i8, smem, align<128>> to !cute.ptr<f16, smem, align<128>, S<3,4,3>>
      %52 = arith.cmpi eq, %40, %c0_i32 : i32
      cf.cond_br %52, ^bb1, ^bb2
    ^bb1:  // pred: ^bb0
      cute_nvgpu.prefetch_tma_desc(%arg1) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_100_2sm_multicast, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, internal_val_type = f16>) -> ()
      cute_nvgpu.prefetch_tma_desc(%arg3) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_100_2sm_multicast, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, internal_val_type = f16>) -> ()
      cf.br ^bb2
    ^bb2:  // 2 preds: ^bb0, ^bb1
      %iter_7 = cute.recast_iter(%smem_ptr) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<i64, smem, align<1024>>
      cf.cond_br %52, ^bb3, ^bb4
    ^bb3:  // pred: ^bb2
      %53 = builtin.unrealized_conversion_cast %iter_7 : !cute.ptr<i64, smem, align<1024>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %53, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_8 = cute.add_offset(%iter_7, %22) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"1">) -> !cute.ptr<i64, smem>
      %54 = builtin.unrealized_conversion_cast %ptr_8 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %54, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_9 = cute.add_offset(%iter_7, %21) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"2">) -> !cute.ptr<i64, smem, align<16>>
      %55 = builtin.unrealized_conversion_cast %ptr_9 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %55, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_10 = cute.add_offset(%iter_7, %20) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"3">) -> !cute.ptr<i64, smem>
      %56 = builtin.unrealized_conversion_cast %ptr_10 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %56, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_11 = cute.add_offset(%iter_7, %19) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"4">) -> !cute.ptr<i64, smem, align<32>>
      %57 = builtin.unrealized_conversion_cast %ptr_11 : !cute.ptr<i64, smem, align<32>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %57, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_12 = cute.add_offset(%iter_7, %18) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"5">) -> !cute.ptr<i64, smem>
      %58 = builtin.unrealized_conversion_cast %ptr_12 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %58, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_13 = cute.add_offset(%iter_7, %17) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"6">) -> !cute.ptr<i64, smem, align<16>>
      %59 = builtin.unrealized_conversion_cast %ptr_13 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %59, %c1_i32 : !llvm.ptr<3>, i32
      cf.br ^bb4
    ^bb4:  // 2 preds: ^bb2, ^bb3
      %ptr_14 = cute.add_offset(%iter_7, %16) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"7">) -> !cute.ptr<i64, smem>
      cf.cond_br %52, ^bb5, ^bb6
    ^bb5:  // pred: ^bb4
      %60 = builtin.unrealized_conversion_cast %ptr_14 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %60, %c1_i32 : !llvm.ptr<3>, i32
      %int_tuple = cute.make_int_tuple() : () -> !cute.int_tuple<"8">
      %ptr_15 = cute.add_offset(%iter_7, %int_tuple) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"8">) -> !cute.ptr<i64, smem, align<64>>
      %dyn = cute.derefine(%ptr_15) : !cute.ptr<i64, smem, align<64>> to !cute.ptr<i64, smem>
      %61 = builtin.unrealized_conversion_cast %dyn : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %61, %c1_i32 : !llvm.ptr<3>, i32
      %int_tuple_16 = cute.make_int_tuple() : () -> !cute.int_tuple<"9">
      %ptr_17 = cute.add_offset(%iter_7, %int_tuple_16) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"9">) -> !cute.ptr<i64, smem>
      %62 = builtin.unrealized_conversion_cast %ptr_17 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %62, %c1_i32 : !llvm.ptr<3>, i32
      %int_tuple_18 = cute.make_int_tuple() : () -> !cute.int_tuple<"10">
      %ptr_19 = cute.add_offset(%iter_7, %int_tuple_18) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"10">) -> !cute.ptr<i64, smem, align<16>>
      %dyn_20 = cute.derefine(%ptr_19) : !cute.ptr<i64, smem, align<16>> to !cute.ptr<i64, smem>
      %63 = builtin.unrealized_conversion_cast %dyn_20 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %63, %c1_i32 : !llvm.ptr<3>, i32
      %int_tuple_21 = cute.make_int_tuple() : () -> !cute.int_tuple<"11">
      %ptr_22 = cute.add_offset(%iter_7, %int_tuple_21) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"11">) -> !cute.ptr<i64, smem>
      %64 = builtin.unrealized_conversion_cast %ptr_22 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %64, %c1_i32 : !llvm.ptr<3>, i32
      %int_tuple_23 = cute.make_int_tuple() : () -> !cute.int_tuple<"12">
      %ptr_24 = cute.add_offset(%iter_7, %int_tuple_23) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"12">) -> !cute.ptr<i64, smem, align<32>>
      %dyn_25 = cute.derefine(%ptr_24) : !cute.ptr<i64, smem, align<32>> to !cute.ptr<i64, smem>
      %65 = builtin.unrealized_conversion_cast %dyn_25 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %65, %c1_i32 : !llvm.ptr<3>, i32
      %int_tuple_26 = cute.make_int_tuple() : () -> !cute.int_tuple<"13">
      %ptr_27 = cute.add_offset(%iter_7, %int_tuple_26) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"13">) -> !cute.ptr<i64, smem>
      %66 = builtin.unrealized_conversion_cast %ptr_27 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %66, %c1_i32 : !llvm.ptr<3>, i32
      cf.br ^bb6
    ^bb6:  // 2 preds: ^bb4, ^bb5
      %67 = cute_nvgpu.arch.make_warp_uniform(%43) : i32
      %68 = cute.get_flat_coord(%67, %28) : (i32, !cute.layout<"((2),1,1,1):((1),0,0,0)">) -> !cute.coord<"(?,0,0,0)">
      %e0_28, %e1_29, %e2_30, %e3_31 = cute.get_leaves(%68) : !cute.coord<"(?,0,0,0)">
      %itup_32 = cute.to_int_tuple(%e0_28) : !cute.coord<"?"> to !cute.int_tuple<"?">
      %69 = cute.get_scalars(%itup_32) : !cute.int_tuple<"?">
      %coord = cute.make_coord(%itup_32) : (!cute.int_tuple<"?">) -> !cute.coord<"(?,0,_,0)">
      %idx = cute.crd2idx(%coord, %28) : (!cute.coord<"(?,0,_,0)">, !cute.layout<"((2),1,1,1):((1),0,0,0)">) -> !cute.int_tuple<"?">
      %e0_33 = cute.get_leaves(%idx) : !cute.int_tuple<"?">
      %70 = cute.get_scalars(%e0_33) : !cute.int_tuple<"?">
      %71 = arith.shli %c1_i32, %70 : i32
      %72 = arith.trunci %71 : i32 to i16
      %coord_34 = cute.make_coord(%itup_32) : (!cute.int_tuple<"?">) -> !cute.coord<"(?,_,0,0)">
      %idx_35 = cute.crd2idx(%coord_34, %28) : (!cute.coord<"(?,_,0,0)">, !cute.layout<"((2),1,1,1):((1),0,0,0)">) -> !cute.int_tuple<"?">
      %e0_36 = cute.get_leaves(%idx_35) : !cute.int_tuple<"?">
      %73 = cute.get_scalars(%e0_36) : !cute.int_tuple<"?">
      %74 = arith.shli %c1_i32, %73 : i32
      %75 = arith.trunci %74 : i32 to i16
      %76 = arith.xori %69, %c1_i32 : i32
      %coord_37 = cute.make_coord(%76) : (i32) -> !cute.coord<"(?,0,_,0)">
      %idx_38 = cute.crd2idx(%coord_37, %28) : (!cute.coord<"(?,0,_,0)">, !cute.layout<"((2),1,1,1):((1),0,0,0)">) -> !cute.int_tuple<"?">
      %e0_39 = cute.get_leaves(%idx_38) : !cute.int_tuple<"?">
      %77 = cute.get_scalars(%e0_39) : !cute.int_tuple<"?">
      %78 = arith.shli %c1_i32, %77 : i32
      %79 = arith.trunci %78 : i32 to i16
      %coord_40 = cute.make_coord(%76) : (i32) -> !cute.coord<"(?,_,0,0)">
      %idx_41 = cute.crd2idx(%coord_40, %28) : (!cute.coord<"(?,_,0,0)">, !cute.layout<"((2),1,1,1):((1),0,0,0)">) -> !cute.int_tuple<"?">
      %e0_42 = cute.get_leaves(%idx_41) : !cute.int_tuple<"?">
      %80 = cute.get_scalars(%e0_42) : !cute.int_tuple<"?">
      %81 = arith.shli %c1_i32, %80 : i32
      %82 = arith.trunci %81 : i32 to i16
      %83 = arith.ori %72, %75 : i16
      %84 = arith.ori %83, %79 : i16
      %85 = arith.ori %84, %82 : i16
      %86 = arith.cmpi eq, %45, %c0_i32 : i32
      nvvm.fence.mbarrier.init
      nvvm.cluster.arrive
      nvvm.cluster.wait
      %iter_43 = cute.recast_iter(%ptr_0) : !cute.ptr<i8, smem, align<16>> to !cute.ptr<i64, smem, align<16>>
      cf.cond_br %52, ^bb7, ^bb8
    ^bb7:  // pred: ^bb6
      %87 = builtin.unrealized_conversion_cast %iter_43 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %87, %c1_i32 : !llvm.ptr<3>, i32
      cf.br ^bb8
    ^bb8:  // 2 preds: ^bb6, ^bb7
      %ptr_44 = cute.add_offset(%iter_43, %22) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"1">) -> !cute.ptr<i64, smem>
      cf.cond_br %52, ^bb9, ^bb10
    ^bb9:  // pred: ^bb8
      %88 = builtin.unrealized_conversion_cast %ptr_44 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %88, %c256_i32 : !llvm.ptr<3>, i32
      cf.br ^bb10
    ^bb10:  // 2 preds: ^bb8, ^bb9
      %89 = arith.floordivsi %67, %c2_i32 : i32
      %90 = arith.muli %89, %c2_i32 : i32
      nvvm.fence.mbarrier.init
      nvvm.cluster.arrive
      nvvm.cluster.wait
      %coord_45 = cute.make_coord(%46, %42) : (i32, i32) -> !cute.coord<"(?,?,_)">
      %91:2 = cute.get_scalars(%coord_45) <{only_dynamic}> : !cute.coord<"(?,?,_)">
      %coord_46 = cute.make_coord(%91#0) : (i32) -> !cute.coord<"((_,_),(?,_))">
      %lay = cute.get_layout(%arg2) : !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">
      %92:2 = cute.get_scalars(%lay) <{only_dynamic}> : !cute.layout<"(?,?{div=8192}):(1@1,1@0)">
      %93 = arith.ceildivsi %92#0, %c256_i32 : i32
      %94 = arith.ceildivsi %92#1, %c64_i32 : i32
      %shape = cute.make_shape(%93, %94) : (i32, i32) -> !cute.shape<"((256,64),(?,?))">
      %lay_47 = cute.make_layout(%shape, %15) : !cute.layout<"((256,64),(?,?)):((1@1,1@0),(256@1,64@0))">
      %95:2 = cute.get_scalars(%lay_47) <{only_dynamic}> : !cute.layout<"((256,64),(?,?)):((1@1,1@0),(256@1,64@0))">
      %shape_48 = cute.make_shape(%95#1) : (i32) -> !cute.shape<"(256,64,?)">
      %lay_49 = cute.make_layout(%shape_48, %14) : !cute.layout<"(256,64,?):(1@1,1@0,64@0)">
      %idx_50 = cute.crd2idx(%coord_46, %lay_47) : (!cute.coord<"((_,_),(?,_))">, !cute.layout<"((256,64),(?,?)):((1@1,1@0),(256@1,64@0))">) -> !cute.int_tuple<"(0,?{div=256})">
      %tup = cute.add_offset(%13, %idx_50) : (!cute.int_tuple<"(0,0)">, !cute.int_tuple<"(0,?{div=256})">) -> !cute.int_tuple<"(0,?{div=256})">
      %coord_51 = cute.make_coord(%91#1) : (i32) -> !cute.coord<"((_,_),(?,_))">
      %lay_52 = cute.get_layout(%arg4) : !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">
      %96:2 = cute.get_scalars(%lay_52) <{only_dynamic}> : !cute.layout<"(?,?{div=8192}):(1@1,1@0)">
      %97 = arith.ceildivsi %96#0, %c256_i32 : i32
      %98 = arith.ceildivsi %96#1, %c64_i32 : i32
      %shape_53 = cute.make_shape(%97, %98) : (i32, i32) -> !cute.shape<"((256,64),(?,?))">
      %lay_54 = cute.make_layout(%shape_53, %15) : !cute.layout<"((256,64),(?,?)):((1@1,1@0),(256@1,64@0))">
      %99:2 = cute.get_scalars(%lay_54) <{only_dynamic}> : !cute.layout<"((256,64),(?,?)):((1@1,1@0),(256@1,64@0))">
      %shape_55 = cute.make_shape(%99#1) : (i32) -> !cute.shape<"(256,64,?)">
      %lay_56 = cute.make_layout(%shape_55, %14) : !cute.layout<"(256,64,?):(1@1,1@0,64@0)">
      %idx_57 = cute.crd2idx(%coord_51, %lay_54) : (!cute.coord<"((_,_),(?,_))">, !cute.layout<"((256,64),(?,?)):((1@1,1@0),(256@1,64@0))">) -> !cute.int_tuple<"(0,?{div=256})">
      %tup_58 = cute.add_offset(%13, %idx_57) : (!cute.int_tuple<"(0,0)">, !cute.int_tuple<"(0,?{div=256})">) -> !cute.int_tuple<"(0,?{div=256})">
      %coord_59 = cute.make_coord(%91#0, %91#1) : (i32, i32) -> !cute.coord<"((_,_),(?,?))">
      %lay_60 = cute.get_layout(%arg5) : !memref_gmem_f16_
      %100:3 = cute.get_scalars(%lay_60) <{only_dynamic}> : !cute.layout<"(?,?{div=8192}):(?{i64 div=8192},1)">
      %101 = arith.ceildivsi %100#0, %c256_i32 : i32
      %102 = arith.muli %100#2, %c256_i64 : i64
      %103 = arith.ceildivsi %100#1, %c256_i32 : i32
      %shape_61 = cute.make_shape(%101, %103) : (i32, i32) -> !cute.shape<"((256,256),(?,?))">
      %iv_62 = cute.assume(%100#2) : (i64) -> !cute.i64<divby 8192>
      %iv_63 = cute.assume(%102) : (i64) -> !cute.i64<divby 2097152>
      %stride = cute.make_stride(%iv_62, %iv_63) : (!cute.i64<divby 8192>, !cute.i64<divby 2097152>) -> !cute.stride<"((?{i64 div=8192},1),(?{i64 div=2097152},256))">
      %lay_64 = cute.make_layout(%shape_61, %stride) : !cute.layout<"((256,256),(?,?)):((?{i64 div=8192},1),(?{i64 div=2097152},256))">
      %104:4 = cute.get_scalars(%lay_64) <{only_dynamic}> : !cute.layout<"((256,256),(?,?)):((?{i64 div=8192},1),(?{i64 div=2097152},256))">
      %iv_65 = cute.assume(%104#2) : (i64) -> !cute.i64<divby 8192>
      %stride_66 = cute.make_stride(%iv_65) : (!cute.i64<divby 8192>) -> !cute.stride<"(?{i64 div=8192},1)">
      %lay_67 = cute.make_layout(%12, %stride_66) : !cute.layout<"(256,256):(?{i64 div=8192},1)">
      %idx_68 = cute.crd2idx(%coord_59, %lay_64) : (!cute.coord<"((_,_),(?,?))">, !cute.layout<"((256,256),(?,?)):((?{i64 div=8192},1),(?{i64 div=2097152},256))">) -> !cute.int_tuple<"?{i64 div=256}">
      %iter_69 = cute.get_iter(%arg5) : !memref_gmem_f16_
      %ptr_70 = cute.add_offset(%iter_69, %idx_68) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{i64 div=256}">) -> !cute.ptr<f16, gmem, align<32>>
      %coord_71 = cute.make_coord(%45) : (i32) -> !cute.coord<"?">
      %105 = cute.get_scalars(%lay_49) <{only_dynamic}> : !cute.layout<"(256,64,?):(1@1,1@0,64@0)">
      %106 = cute.get_scalars(%coord_71) <{only_dynamic}> : !cute.coord<"?">
      %107 = arith.remsi %106, %c2_i32 : i32
      %108 = arith.remsi %107, %c2_i32 : i32
      %109 = arith.muli %108, %c128_i32 : i32
      %iv_72 = cute.assume(%109) : (i32) -> !cute.i32<divby 128>
      %int_tuple_73 = cute.make_int_tuple(%iv_72) : (!cute.i32<divby 128>) -> !cute.int_tuple<"(0,?{div=128})">
      %tup_74 = cute.add_offset(%tup, %int_tuple_73) : (!cute.int_tuple<"(0,?{div=256})">, !cute.int_tuple<"(0,?{div=128})">) -> !cute.int_tuple<"(0,?{div=128})">
      %shape_75 = cute.make_shape(%105) : (i32) -> !cute.shape<"((128,16),1,4,?)">
      %lay_76 = cute.make_layout(%shape_75, %11) : !cute.layout<"((128,16),1,4,?):((1@1,1@0),0,16@0,64@0)">
      %110 = cute.get_scalars(%lay_56) <{only_dynamic}> : !cute.layout<"(256,64,?):(1@1,1@0,64@0)">
      %tup_77 = cute.add_offset(%tup_58, %int_tuple_73) : (!cute.int_tuple<"(0,?{div=256})">, !cute.int_tuple<"(0,?{div=128})">) -> !cute.int_tuple<"(0,?{div=128})">
      %shape_78 = cute.make_shape(%110) : (i32) -> !cute.shape<"((128,16),1,4,?)">
      %lay_79 = cute.make_layout(%shape_78, %11) : !cute.layout<"((128,16),1,4,?):((1@1,1@0),0,16@0,64@0)">
      %111 = cute.get_scalars(%lay_67) <{only_dynamic}> : !cute.layout<"(256,256):(?{i64 div=8192},1)">
      %112 = arith.muli %111, %c128_i64 : i64
      %113 = arith.extsi %108 : i32 to i64
      %114 = arith.muli %113, %112 : i64
      %iv_80 = cute.assume(%114) : (i64) -> !cute.i64<divby 1048576>
      %int_tuple_81 = cute.make_int_tuple(%iv_80) : (!cute.i64<divby 1048576>) -> !cute.int_tuple<"?{i64 div=1048576}">
      %ptr_82 = cute.add_offset(%ptr_70, %int_tuple_81) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{i64 div=1048576}">) -> !cute.ptr<f16, gmem, align<32>>
      %iv_83 = cute.assume(%111) : (i64) -> !cute.i64<divby 8192>
      %stride_84 = cute.make_stride(%iv_83) : (!cute.i64<divby 8192>) -> !cute.stride<"((?{i64 div=8192},1),0,0)">
      %lay_85 = cute.make_layout(%10, %stride_84) : !cute.layout<"((128,256),1,1):((?{i64 div=8192},1),0,0)">
      %ummaSmemDesc = cute_nvgpu.make_umma_smem_desc(%iter_5 : !cute.ptr<f16, smem, align<128>, S<3,4,3>>) layout = <"((128,16),1,4,7):((64,1),0,16,8192)">, major = <k> -> !cute_nvgpu.smem_desc
      %ummaSmemDesc_86 = cute_nvgpu.make_umma_smem_desc(%iter_6 : !cute.ptr<f16, smem, align<128>, S<3,4,3>>) layout = <"((128,16),1,4,7):((64,1),0,16,8192)">, major = <k> -> !cute_nvgpu.smem_desc
      %115 = cute.get_scalars(%lay_76) <{only_dynamic}> : !cute.layout<"((128,16),1,4,?):((1@1,1@0),0,16@0,64@0)">
      %shape_87 = cute.make_shape(%115) : (i32) -> !cute.shape<"(((128,16),1,4),?)">
      %lay_88 = cute.make_layout(%shape_87, %9) : !cute.layout<"(((128,16),1,4),?):(((1@1,1@0),0,16@0),64@0)">
      %116 = cute.get_scalars(%lay_88) <{only_dynamic}> : !cute.layout<"(((128,16),1,4),?):(((1@1,1@0),0,16@0),64@0)">
      %shape_89 = cute.make_shape(%116) : (i32) -> !cute.shape<"(((64,128),1),?)">
      %lay_90 = cute.make_layout(%shape_89, %8) : !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">
      %117 = cute.get_scalars(%lay_79) <{only_dynamic}> : !cute.layout<"((128,16),1,4,?):((1@1,1@0),0,16@0,64@0)">
      %shape_91 = cute.make_shape(%117) : (i32) -> !cute.shape<"(((128,16),1,4),?)">
      %lay_92 = cute.make_layout(%shape_91, %9) : !cute.layout<"(((128,16),1,4),?):(((1@1,1@0),0,16@0),64@0)">
      %118 = cute.get_scalars(%lay_92) <{only_dynamic}> : !cute.layout<"(((128,16),1,4),?):(((1@1,1@0),0,16@0),64@0)">
      %shape_93 = cute.make_shape(%118) : (i32) -> !cute.shape<"(((64,128),1),?)">
      %lay_94 = cute.make_layout(%shape_93, %8) : !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">
      %coord_95 = cute.make_coord(%itup) : (!cute.int_tuple<"?">) -> !cute.coord<"(?,0,_,0)">
      %idx_96 = cute.crd2idx(%coord_95, %28) : (!cute.coord<"(?,0,_,0)">, !cute.layout<"((2),1,1,1):((1),0,0,0)">) -> !cute.int_tuple<"?">
      %e0_97 = cute.get_leaves(%idx_96) : !cute.int_tuple<"?">
      %119 = cute.get_scalars(%e0_97) : !cute.int_tuple<"?">
      %120 = arith.shli %c1_i32, %119 : i32
      %121 = arith.trunci %120 : i32 to i16
      %coord_98 = cute.make_coord(%itup) : (!cute.int_tuple<"?">) -> !cute.coord<"(?,_,0,0)">
      %idx_99 = cute.crd2idx(%coord_98, %28) : (!cute.coord<"(?,_,0,0)">, !cute.layout<"((2),1,1,1):((1),0,0,0)">) -> !cute.int_tuple<"?">
      %e0_100 = cute.get_leaves(%idx_99) : !cute.int_tuple<"?">
      %122 = cute.get_scalars(%e0_100) : !cute.int_tuple<"?">
      %123 = arith.shli %c1_i32, %122 : i32
      %124 = arith.trunci %123 : i32 to i16
      cf.cond_br %52, ^bb11, ^bb14
    ^bb11:  // pred: ^bb10
      %125 = nvvm.elect.sync -> i1
      cf.cond_br %125, ^bb12, ^bb13
    ^bb12:  // pred: ^bb11
      %126 = builtin.unrealized_conversion_cast %iter : !cute.ptr<i64, smem, align<128>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %126, %c32_i32 : !llvm.ptr<3>, i32
      cf.br ^bb13
    ^bb13:  // 2 preds: ^bb11, ^bb12
      cf.br ^bb14
    ^bb14:  // 2 preds: ^bb10, ^bb13
      nvvm.fence.mbarrier.init
      cf.cond_br %52, ^bb15, ^bb16
    ^bb15:  // pred: ^bb14
      cute_nvgpu.arch.sm100.alloc_tmem(%c512_i32, %iter_3) [cta_2] : i32, !cute.ptr<i32, smem, align<8>>
      cf.br ^bb16
    ^bb16:  // 2 preds: ^bb14, ^bb15
      nvvm.barrier id = %c1_i32 number_of_threads = %c128_i32
      %tmem_ptr = cute_nvgpu.arch.sm100.retrieve_tmem_ptr(%iter_3) : !cute.ptr<i32, smem, align<8>> -> !cute.ptr<f32, tmem, align<16>>
      %127 = cute.get_scalars(%lay_85) <{only_dynamic}> : !cute.layout<"((128,256),1,1):((?{i64 div=8192},1),0,0)">
      %iv_101 = cute.assume(%127) : (i64) -> !cute.i64<divby 8192>
      %stride_102 = cute.make_stride(%iv_101) : (!cute.i64<divby 8192>) -> !cute.stride<"(((?{i64 div=8192},1)),((0,64),0,0))">
      %lay_103 = cute.make_layout(%7, %stride_102) : !cute.layout<"(((128,64)),((1,4),1,1)):(((?{i64 div=8192},1)),((0,64),0,0))">
      %coord_104 = cute.make_coord(%29) : (i32) -> !cute.coord<"?">
      %128 = cute.get_scalars(%coord_104) <{only_dynamic}> : !cute.coord<"?">
      %129 = arith.divsi %128, %c32_i32 : i32
      %130 = arith.muli %129, %c2097152_i32 : i32
      %iv_105 = cute.assume(%130) : (i32) -> !cute.i32<divby 2097152>
      %int_tuple_106 = cute.make_int_tuple(%iv_105) : (!cute.i32<divby 2097152>) -> !cute.int_tuple<"?{div=2097152}">
      %ptr_107 = cute.add_offset(%tmem_ptr, %int_tuple_106) : (!cute.ptr<f32, tmem, align<16>>, !cute.int_tuple<"?{div=2097152}">) -> !cute.ptr<f32, tmem, align<16>>
      %131 = cute.get_scalars(%lay_103) <{only_dynamic}> : !cute.layout<"(((128,64)),((1,4),1,1)):(((?{i64 div=8192},1)),((0,64),0,0))">
      %132 = arith.muli %131, %c32_i64 : i64
      %133 = arith.remsi %128, %c32_i32 : i32
      %134 = arith.extsi %133 : i32 to i64
      %135 = arith.muli %134, %131 : i64
      %136 = arith.extsi %129 : i32 to i64
      %137 = arith.muli %136, %132 : i64
      %138 = arith.addi %135, %137 : i64
      %iv_108 = cute.assume(%138) : (i64) -> !cute.i64<divby 8192>
      %int_tuple_109 = cute.make_int_tuple(%iv_108) : (!cute.i64<divby 8192>) -> !cute.int_tuple<"?{i64 div=8192}">
      %ptr_110 = cute.add_offset(%ptr_82, %int_tuple_109) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{i64 div=8192}">) -> !cute.ptr<f16, gmem, align<32>>
      %rmem = cute.memref.alloca() : !memref_rmem_f32_
      %rmem_111 = cute.memref.alloca() : !memref_rmem_f16_
      %sz = cute.size(%lay_49) <{mode = [2]}> : (!cute.layout<"(256,64,?):(1@1,1@0,64@0)">) -> !cute.int_tuple<"?">
      %e0_112 = cute.get_leaves(%sz) : !cute.int_tuple<"?">
      %139 = cute.get_scalars(%e0_112) : !cute.int_tuple<"?">
      cf.cond_br %52, ^bb17, ^bb108
    ^bb17:  // pred: ^bb16
      %140 = arith.cmpi ne, %45, %c0_i32 : i32
      %141 = arith.extui %140 : i1 to i32
      cf.cond_br %86, ^bb18, ^bb19
    ^bb18:  // pred: ^bb17
      %142 = builtin.unrealized_conversion_cast %ptr_44 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %142, %c1_i32, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      cf.br ^bb19
    ^bb19:  // 2 preds: ^bb17, ^bb18
      %143 = cute_nvgpu.atom.make_exec_tma(%arg1) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_100_2sm_multicast, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>
      %144 = cute_nvgpu.atom.set_value(%143, %121 : i16) {field = #cute_nvgpu.atom_copy_field_tmaload<mcast_mask>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>
      %145 = cute_nvgpu.atom.make_exec_tma(%arg3) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_100_2sm_multicast, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>
      %146 = cute_nvgpu.atom.set_value(%145, %124 : i16) {field = #cute_nvgpu.atom_copy_field_tmaload<mcast_mask>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>
      %147 = arith.minsi %139, %c5_i32 : i32
      %148 = cute.get_scalars(%22) : !cute.int_tuple<"1">
      cf.br ^bb20(%c0_i32, %c0_i32, %c1_i32, %c0_i32 : i32, i32, i32, i32)
    ^bb20(%149: i32, %150: i32, %151: i32, %152: i32):  // 2 preds: ^bb19, ^bb35
      %153 = arith.cmpi slt, %149, %147 : i32
      cf.cond_br %153, ^bb21, ^bb36
    ^bb21:  // pred: ^bb20
      %int_tuple_113 = cute.make_int_tuple(%150) : (i32) -> !cute.int_tuple<"?">
      %ptr_114 = cute.add_offset(%ptr_14, %int_tuple_113) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %154 = builtin.unrealized_conversion_cast %ptr_114 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %154, %151, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      cf.cond_br %86, ^bb22, ^bb25
    ^bb22:  // pred: ^bb21
      %155 = nvvm.elect.sync -> i1
      cf.cond_br %155, ^bb23, ^bb24
    ^bb23:  // pred: ^bb22
      %ptr_115 = cute.add_offset(%iter_7, %int_tuple_113) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %156 = builtin.unrealized_conversion_cast %ptr_115 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %156, %c65536_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
      cf.br ^bb24
    ^bb24:  // 2 preds: ^bb22, ^bb23
      cf.br ^bb25
    ^bb25:  // 2 preds: ^bb21, ^bb24
      %157 = arith.addi %150, %c1_i32 : i32
      %158 = arith.addi %152, %c1_i32 : i32
      %159 = arith.cmpi eq, %157, %c7_i32 : i32
      %160 = arith.select %159, %c0_i32, %157 : i32
      cf.cond_br %159, ^bb26, ^bb27
    ^bb26:  // pred: ^bb25
      %161 = arith.xori %151, %c1_i32 : i32
      cf.br ^bb28(%161 : i32)
    ^bb27:  // pred: ^bb25
      cf.br ^bb28(%151 : i32)
    ^bb28(%162: i32):  // 2 preds: ^bb26, ^bb27
      cf.br ^bb29
    ^bb29:  // pred: ^bb28
      %coord_116 = cute.make_coord(%152) : (i32) -> !cute.coord<"(_,?)">
      %idx_117 = cute.crd2idx(%coord_116, %lay_90) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
      %tup_118 = cute.add_offset(%tup_74, %idx_117) : (!cute.int_tuple<"(0,?{div=128})">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
      %e0_119, %e1_120 = cute.get_leaves(%tup_118) : !cute.int_tuple<"(?{div=64},?{div=128})">
      %coord_121 = cute.make_coord(%150) : (i32) -> !cute.coord<"(_,?)">
      %idx_122 = cute.crd2idx(%coord_121, %6) : (!cute.coord<"(_,?)">, !cute.layout<"((8192,1),7):((1,0),8192)">) -> !cute.int_tuple<"?{div=8192}">
      %ptr_123 = cute.add_offset(%iter_5, %idx_122) : (!cute.ptr<f16, smem, align<128>, S<3,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<f16, smem, align<128>, S<3,4,3>>
      %ptr_124 = cute.add_offset(%iter_7, %int_tuple_113) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %int_tuple_125 = cute.make_int_tuple(%e0_119, %e1_120) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=128}">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
      %163 = cute_nvgpu.atom.set_value(%144, %ptr_124 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>
      %164 = cute_nvgpu.atom.get_value(%163 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
      %165 = cute_nvgpu.atom.get_value(%163 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<mcast_mask>} : i16
      %TMADescAddr = cute_nvgpu.get_tma_desc_addr(%163 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) -> !cute.ptr<generic, align<64>>
      %166:2 = cute.get_scalars(%int_tuple_125) : !cute.int_tuple<"(?{div=64},?{div=128})">
      cf.br ^bb30(%c0_i32 : i32)
    ^bb30(%167: i32):  // 2 preds: ^bb29, ^bb31
      %168 = arith.cmpi slt, %167, %148 : i32
      cf.cond_br %168, ^bb31, ^bb32 {llvm.loop_annotation = #loop_annotation}
    ^bb31:  // pred: ^bb30
      cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr : !cute.ptr<generic, align<64>>, %ptr_123 : !cute.ptr<f16, smem, align<128>, S<3,4,3>>, %164 : !cute.ptr<smem, align<8>>, [%166#0, %166#1] : i32, i32) mask = %165 mode = <tiled> num_cta = 2 : i32
      %169 = arith.addi %167, %c1_i32 : i32
      cf.br ^bb30(%169 : i32)
    ^bb32:  // pred: ^bb30
      %idx_126 = cute.crd2idx(%coord_116, %lay_94) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
      %tup_127 = cute.add_offset(%tup_77, %idx_126) : (!cute.int_tuple<"(0,?{div=128})">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
      %e0_128, %e1_129 = cute.get_leaves(%tup_127) : !cute.int_tuple<"(?{div=64},?{div=128})">
      %ptr_130 = cute.add_offset(%iter_6, %idx_122) : (!cute.ptr<f16, smem, align<128>, S<3,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<f16, smem, align<128>, S<3,4,3>>
      %int_tuple_131 = cute.make_int_tuple(%e0_128, %e1_129) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=128}">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
      %170 = cute_nvgpu.atom.set_value(%146, %ptr_124 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>
      %171 = cute_nvgpu.atom.get_value(%170 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
      %172 = cute_nvgpu.atom.get_value(%170 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<mcast_mask>} : i16
      %TMADescAddr_132 = cute_nvgpu.get_tma_desc_addr(%170 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) -> !cute.ptr<generic, align<64>>
      %173:2 = cute.get_scalars(%int_tuple_131) : !cute.int_tuple<"(?{div=64},?{div=128})">
      cf.br ^bb33(%c0_i32 : i32)
    ^bb33(%174: i32):  // 2 preds: ^bb32, ^bb34
      %175 = arith.cmpi slt, %174, %148 : i32
      cf.cond_br %175, ^bb34, ^bb35 {llvm.loop_annotation = #loop_annotation}
    ^bb34:  // pred: ^bb33
      cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr_132 : !cute.ptr<generic, align<64>>, %ptr_130 : !cute.ptr<f16, smem, align<128>, S<3,4,3>>, %171 : !cute.ptr<smem, align<8>>, [%173#0, %173#1] : i32, i32) mask = %172 mode = <tiled> num_cta = 2 : i32
      %176 = arith.addi %174, %c1_i32 : i32
      cf.br ^bb33(%176 : i32)
    ^bb35:  // pred: ^bb33
      %177 = arith.addi %149, %c1_i32 : i32
      cf.br ^bb20(%177, %160, %162, %158 : i32, i32, i32, i32)
    ^bb36:  // pred: ^bb20
      cf.br ^bb37(%c0_i32, %152, %150, %151, %c0_i32, %c0_i32, %c0_i32, %0 : i32, i32, i32, i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>)
    ^bb37(%178: i32, %179: i32, %180: i32, %181: i32, %182: i32, %183: i32, %184: i32, %185: !llvm.struct<(i1, i1, i1)>):  // 2 preds: ^bb36, ^bb102
      %186 = arith.cmpi slt, %178, %139 : i32
      cf.cond_br %186, ^bb38, ^bb103
    ^bb38:  // pred: ^bb37
      %187 = builtin.unrealized_conversion_cast %185 : !llvm.struct<(i1, i1, i1)> to !mma_f16_f16_f32_256x256x16_
      %188 = arith.addi %178, %147 : i32
      %189 = arith.cmpi ult, %188, %139 : i32
      cf.cond_br %189, ^bb39, ^bb54
    ^bb39:  // pred: ^bb38
      %int_tuple_133 = cute.make_int_tuple(%180) : (i32) -> !cute.int_tuple<"?">
      %ptr_134 = cute.add_offset(%ptr_14, %int_tuple_133) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %190 = builtin.unrealized_conversion_cast %ptr_134 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %190, %181, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      cf.cond_br %86, ^bb40, ^bb43
    ^bb40:  // pred: ^bb39
      %191 = nvvm.elect.sync -> i1
      cf.cond_br %191, ^bb41, ^bb42
    ^bb41:  // pred: ^bb40
      %ptr_135 = cute.add_offset(%iter_7, %int_tuple_133) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %192 = builtin.unrealized_conversion_cast %ptr_135 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %192, %c65536_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
      cf.br ^bb42
    ^bb42:  // 2 preds: ^bb40, ^bb41
      cf.br ^bb43
    ^bb43:  // 2 preds: ^bb39, ^bb42
      %193 = arith.addi %180, %c1_i32 : i32
      %194 = arith.addi %179, %c1_i32 : i32
      %195 = arith.cmpi eq, %193, %c7_i32 : i32
      %196 = arith.select %195, %c0_i32, %193 : i32
      cf.cond_br %195, ^bb44, ^bb45
    ^bb44:  // pred: ^bb43
      %197 = arith.xori %181, %c1_i32 : i32
      cf.br ^bb46(%197 : i32)
    ^bb45:  // pred: ^bb43
      cf.br ^bb46(%181 : i32)
    ^bb46(%198: i32):  // 2 preds: ^bb44, ^bb45
      cf.br ^bb47
    ^bb47:  // pred: ^bb46
      %coord_136 = cute.make_coord(%179) : (i32) -> !cute.coord<"(_,?)">
      %idx_137 = cute.crd2idx(%coord_136, %lay_90) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
      %tup_138 = cute.add_offset(%tup_74, %idx_137) : (!cute.int_tuple<"(0,?{div=128})">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
      %e0_139, %e1_140 = cute.get_leaves(%tup_138) : !cute.int_tuple<"(?{div=64},?{div=128})">
      %coord_141 = cute.make_coord(%180) : (i32) -> !cute.coord<"(_,?)">
      %idx_142 = cute.crd2idx(%coord_141, %6) : (!cute.coord<"(_,?)">, !cute.layout<"((8192,1),7):((1,0),8192)">) -> !cute.int_tuple<"?{div=8192}">
      %ptr_143 = cute.add_offset(%iter_5, %idx_142) : (!cute.ptr<f16, smem, align<128>, S<3,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<f16, smem, align<128>, S<3,4,3>>
      %ptr_144 = cute.add_offset(%iter_7, %int_tuple_133) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %int_tuple_145 = cute.make_int_tuple(%e0_139, %e1_140) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=128}">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
      %199 = cute_nvgpu.atom.set_value(%144, %ptr_144 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>
      %200 = cute.get_scalars(%22) : !cute.int_tuple<"1">
      %201 = cute_nvgpu.atom.get_value(%199 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
      %202 = cute_nvgpu.atom.get_value(%199 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<mcast_mask>} : i16
      %TMADescAddr_146 = cute_nvgpu.get_tma_desc_addr(%199 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) -> !cute.ptr<generic, align<64>>
      %203:2 = cute.get_scalars(%int_tuple_145) : !cute.int_tuple<"(?{div=64},?{div=128})">
      cf.br ^bb48(%c0_i32 : i32)
    ^bb48(%204: i32):  // 2 preds: ^bb47, ^bb49
      %205 = arith.cmpi slt, %204, %200 : i32
      cf.cond_br %205, ^bb49, ^bb50 {llvm.loop_annotation = #loop_annotation}
    ^bb49:  // pred: ^bb48
      cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr_146 : !cute.ptr<generic, align<64>>, %ptr_143 : !cute.ptr<f16, smem, align<128>, S<3,4,3>>, %201 : !cute.ptr<smem, align<8>>, [%203#0, %203#1] : i32, i32) mask = %202 mode = <tiled> num_cta = 2 : i32
      %206 = arith.addi %204, %c1_i32 : i32
      cf.br ^bb48(%206 : i32)
    ^bb50:  // pred: ^bb48
      %idx_147 = cute.crd2idx(%coord_136, %lay_94) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
      %tup_148 = cute.add_offset(%tup_77, %idx_147) : (!cute.int_tuple<"(0,?{div=128})">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
      %e0_149, %e1_150 = cute.get_leaves(%tup_148) : !cute.int_tuple<"(?{div=64},?{div=128})">
      %ptr_151 = cute.add_offset(%iter_6, %idx_142) : (!cute.ptr<f16, smem, align<128>, S<3,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<f16, smem, align<128>, S<3,4,3>>
      %int_tuple_152 = cute.make_int_tuple(%e0_149, %e1_150) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=128}">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
      %207 = cute_nvgpu.atom.set_value(%146, %ptr_144 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>
      %208 = cute_nvgpu.atom.get_value(%207 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
      %209 = cute_nvgpu.atom.get_value(%207 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<mcast_mask>} : i16
      %TMADescAddr_153 = cute_nvgpu.get_tma_desc_addr(%207 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) -> !cute.ptr<generic, align<64>>
      %210:2 = cute.get_scalars(%int_tuple_152) : !cute.int_tuple<"(?{div=64},?{div=128})">
      cf.br ^bb51(%c0_i32 : i32)
    ^bb51(%211: i32):  // 2 preds: ^bb50, ^bb52
      %212 = arith.cmpi slt, %211, %200 : i32
      cf.cond_br %212, ^bb52, ^bb53 {llvm.loop_annotation = #loop_annotation}
    ^bb52:  // pred: ^bb51
      cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr_153 : !cute.ptr<generic, align<64>>, %ptr_151 : !cute.ptr<f16, smem, align<128>, S<3,4,3>>, %208 : !cute.ptr<smem, align<8>>, [%210#0, %210#1] : i32, i32) mask = %209 mode = <tiled> num_cta = 2 : i32
      %213 = arith.addi %211, %c1_i32 : i32
      cf.br ^bb51(%213 : i32)
    ^bb53:  // pred: ^bb51
      cf.br ^bb55(%196, %198, %194 : i32, i32, i32)
    ^bb54:  // pred: ^bb38
      cf.br ^bb55(%180, %181, %179 : i32, i32, i32)
    ^bb55(%214: i32, %215: i32, %216: i32):  // 2 preds: ^bb53, ^bb54
      cf.br ^bb56
    ^bb56:  // pred: ^bb55
      cf.cond_br %86, ^bb57, ^bb100
    ^bb57:  // pred: ^bb56
      %int_tuple_154 = cute.make_int_tuple(%183) : (i32) -> !cute.int_tuple<"?">
      %ptr_155 = cute.add_offset(%iter_7, %int_tuple_154) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %217 = builtin.unrealized_conversion_cast %ptr_155 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %217, %184, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %218 = arith.addi %183, %c1_i32 : i32
      %219 = arith.addi %182, %c1_i32 : i32
      %220 = arith.cmpi eq, %218, %c7_i32 : i32
      %221 = arith.select %220, %c0_i32, %218 : i32
      cf.cond_br %220, ^bb58, ^bb59
    ^bb58:  // pred: ^bb57
      %222 = arith.xori %184, %c1_i32 : i32
      cf.br ^bb60(%222 : i32)
    ^bb59:  // pred: ^bb57
      cf.br ^bb60(%184 : i32)
    ^bb60(%223: i32):  // 2 preds: ^bb58, ^bb59
      cf.br ^bb61
    ^bb61:  // pred: ^bb60
      %coord_156 = cute.make_coord(%183) : (i32) -> !cute.coord<"(_,_,0,?)">
      %idx_157 = cute.crd2idx(%coord_156, %5) : (!cute.coord<"(_,_,0,?)">, !cute.layout<"(1,1,4,7):(0,0,2,1024)">) -> !cute.int_tuple<"?{div=1024}">
      %tup_158 = cute.add_offset(%ummaSmemDesc, %idx_157) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=1024}">) -> !cute_nvgpu.smem_desc
      %tup_159 = cute.add_offset(%ummaSmemDesc_86, %idx_157) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=1024}">) -> !cute_nvgpu.smem_desc
      %224 = cute.get_scalars(%22) : !cute.int_tuple<"1">
      %225 = cute_nvgpu.atom.get_value(%187 : !mma_f16_f16_f32_256x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : i1
      %226 = cute_nvgpu.atom.get_value(%187 : !mma_f16_f16_f32_256x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : i1
      %227 = cute_nvgpu.atom.get_value(%187 : !mma_f16_f16_f32_256x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : i1
      %228 = arith.extui %225 : i1 to i32
      %229 = arith.extui %226 : i1 to i32
      %230 = arith.shli %228, %c13_i32 : i32
      %231 = arith.shli %229, %c14_i32 : i32
      %232 = arith.ori %230, %c272629776_i32 : i32
      %233 = arith.ori %232, %231 : i32
      cf.br ^bb62(%c0_i32 : i32)
    ^bb62(%234: i32):  // 2 preds: ^bb61, ^bb69
      %235 = arith.cmpi slt, %234, %224 : i32
      cf.cond_br %235, ^bb63, ^bb70 {llvm.loop_annotation = #loop_annotation}
    ^bb63:  // pred: ^bb62
      cf.br ^bb64(%c0_i32 : i32)
    ^bb64(%236: i32):  // 2 preds: ^bb63, ^bb68
      %237 = arith.cmpi slt, %236, %224 : i32
      cf.cond_br %237, ^bb65, ^bb69 {llvm.loop_annotation = #loop_annotation}
    ^bb65:  // pred: ^bb64
      cf.br ^bb66(%c0_i32 : i32)
    ^bb66(%238: i32):  // 2 preds: ^bb65, ^bb67
      %239 = arith.cmpi slt, %238, %224 : i32
      cf.cond_br %239, ^bb67, ^bb68 {llvm.loop_annotation = #loop_annotation}
    ^bb67:  // pred: ^bb66
      cute_nvgpu.arch.mma.SM100.umma(%tup_158, %tup_159, %tmem_ptr, %233, %227) {num_cta = 2 : i32, scale = 0 : i32, a_type = f16} : (!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, !cute.ptr<f32, tmem, align<16>>, i32, i1) -> ()
      %240 = arith.addi %238, %c1_i32 : i32
      cf.br ^bb66(%240 : i32)
    ^bb68:  // pred: ^bb66
      %241 = arith.addi %236, %c1_i32 : i32
      cf.br ^bb64(%241 : i32)
    ^bb69:  // pred: ^bb64
      %242 = arith.addi %234, %c1_i32 : i32
      cf.br ^bb62(%242 : i32)
    ^bb70:  // pred: ^bb62
      %243 = cute_nvgpu.atom.set_value(%187, %true : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_f16_f16_f32_256x256x16_
      %coord_160 = cute.make_coord(%183) : (i32) -> !cute.coord<"(_,_,1,?)">
      %idx_161 = cute.crd2idx(%coord_160, %5) : (!cute.coord<"(_,_,1,?)">, !cute.layout<"(1,1,4,7):(0,0,2,1024)">) -> !cute.int_tuple<"?{div=2}">
      %tup_162 = cute.add_offset(%ummaSmemDesc, %idx_161) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
      %tup_163 = cute.add_offset(%ummaSmemDesc_86, %idx_161) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
      %244 = cute_nvgpu.atom.get_value(%243 : !mma_f16_f16_f32_256x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : i1
      %245 = cute_nvgpu.atom.get_value(%243 : !mma_f16_f16_f32_256x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : i1
      %246 = cute_nvgpu.atom.get_value(%243 : !mma_f16_f16_f32_256x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : i1
      %247 = arith.extui %244 : i1 to i32
      %248 = arith.extui %245 : i1 to i32
      %249 = arith.shli %247, %c13_i32 : i32
      %250 = arith.shli %248, %c14_i32 : i32
      %251 = arith.ori %249, %c272629776_i32 : i32
      %252 = arith.ori %251, %250 : i32
      cf.br ^bb71(%c0_i32 : i32)
    ^bb71(%253: i32):  // 2 preds: ^bb70, ^bb78
      %254 = arith.cmpi slt, %253, %224 : i32
      cf.cond_br %254, ^bb72, ^bb79 {llvm.loop_annotation = #loop_annotation}
    ^bb72:  // pred: ^bb71
      cf.br ^bb73(%c0_i32 : i32)
    ^bb73(%255: i32):  // 2 preds: ^bb72, ^bb77
      %256 = arith.cmpi slt, %255, %224 : i32
      cf.cond_br %256, ^bb74, ^bb78 {llvm.loop_annotation = #loop_annotation}
    ^bb74:  // pred: ^bb73
      cf.br ^bb75(%c0_i32 : i32)
    ^bb75(%257: i32):  // 2 preds: ^bb74, ^bb76
      %258 = arith.cmpi slt, %257, %224 : i32
      cf.cond_br %258, ^bb76, ^bb77 {llvm.loop_annotation = #loop_annotation}
    ^bb76:  // pred: ^bb75
      cute_nvgpu.arch.mma.SM100.umma(%tup_162, %tup_163, %tmem_ptr, %252, %246) {num_cta = 2 : i32, scale = 0 : i32, a_type = f16} : (!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, !cute.ptr<f32, tmem, align<16>>, i32, i1) -> ()
      %259 = arith.addi %257, %c1_i32 : i32
      cf.br ^bb75(%259 : i32)
    ^bb77:  // pred: ^bb75
      %260 = arith.addi %255, %c1_i32 : i32
      cf.br ^bb73(%260 : i32)
    ^bb78:  // pred: ^bb73
      %261 = arith.addi %253, %c1_i32 : i32
      cf.br ^bb71(%261 : i32)
    ^bb79:  // pred: ^bb71
      %262 = cute_nvgpu.atom.set_value(%243, %true : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_f16_f16_f32_256x256x16_
      %coord_164 = cute.make_coord(%183) : (i32) -> !cute.coord<"(_,_,2,?)">
      %idx_165 = cute.crd2idx(%coord_164, %5) : (!cute.coord<"(_,_,2,?)">, !cute.layout<"(1,1,4,7):(0,0,2,1024)">) -> !cute.int_tuple<"?{div=4}">
      %tup_166 = cute.add_offset(%ummaSmemDesc, %idx_165) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=4}">) -> !cute_nvgpu.smem_desc
      %tup_167 = cute.add_offset(%ummaSmemDesc_86, %idx_165) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=4}">) -> !cute_nvgpu.smem_desc
      %263 = cute_nvgpu.atom.get_value(%262 : !mma_f16_f16_f32_256x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : i1
      %264 = cute_nvgpu.atom.get_value(%262 : !mma_f16_f16_f32_256x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : i1
      %265 = cute_nvgpu.atom.get_value(%262 : !mma_f16_f16_f32_256x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : i1
      %266 = arith.extui %263 : i1 to i32
      %267 = arith.extui %264 : i1 to i32
      %268 = arith.shli %266, %c13_i32 : i32
      %269 = arith.shli %267, %c14_i32 : i32
      %270 = arith.ori %268, %c272629776_i32 : i32
      %271 = arith.ori %270, %269 : i32
      cf.br ^bb80(%c0_i32 : i32)
    ^bb80(%272: i32):  // 2 preds: ^bb79, ^bb87
      %273 = arith.cmpi slt, %272, %224 : i32
      cf.cond_br %273, ^bb81, ^bb88 {llvm.loop_annotation = #loop_annotation}
    ^bb81:  // pred: ^bb80
      cf.br ^bb82(%c0_i32 : i32)
    ^bb82(%274: i32):  // 2 preds: ^bb81, ^bb86
      %275 = arith.cmpi slt, %274, %224 : i32
      cf.cond_br %275, ^bb83, ^bb87 {llvm.loop_annotation = #loop_annotation}
    ^bb83:  // pred: ^bb82
      cf.br ^bb84(%c0_i32 : i32)
    ^bb84(%276: i32):  // 2 preds: ^bb83, ^bb85
      %277 = arith.cmpi slt, %276, %224 : i32
      cf.cond_br %277, ^bb85, ^bb86 {llvm.loop_annotation = #loop_annotation}
    ^bb85:  // pred: ^bb84
      cute_nvgpu.arch.mma.SM100.umma(%tup_166, %tup_167, %tmem_ptr, %271, %265) {num_cta = 2 : i32, scale = 0 : i32, a_type = f16} : (!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, !cute.ptr<f32, tmem, align<16>>, i32, i1) -> ()
      %278 = arith.addi %276, %c1_i32 : i32
      cf.br ^bb84(%278 : i32)
    ^bb86:  // pred: ^bb84
      %279 = arith.addi %274, %c1_i32 : i32
      cf.br ^bb82(%279 : i32)
    ^bb87:  // pred: ^bb82
      %280 = arith.addi %272, %c1_i32 : i32
      cf.br ^bb80(%280 : i32)
    ^bb88:  // pred: ^bb80
      %281 = cute_nvgpu.atom.set_value(%262, %true : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_f16_f16_f32_256x256x16_
      %coord_168 = cute.make_coord(%183) : (i32) -> !cute.coord<"(_,_,3,?)">
      %idx_169 = cute.crd2idx(%coord_168, %5) : (!cute.coord<"(_,_,3,?)">, !cute.layout<"(1,1,4,7):(0,0,2,1024)">) -> !cute.int_tuple<"?{div=2}">
      %tup_170 = cute.add_offset(%ummaSmemDesc, %idx_169) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
      %tup_171 = cute.add_offset(%ummaSmemDesc_86, %idx_169) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
      %282 = cute_nvgpu.atom.get_value(%281 : !mma_f16_f16_f32_256x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : i1
      %283 = cute_nvgpu.atom.get_value(%281 : !mma_f16_f16_f32_256x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : i1
      %284 = cute_nvgpu.atom.get_value(%281 : !mma_f16_f16_f32_256x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : i1
      %285 = arith.extui %282 : i1 to i32
      %286 = arith.extui %283 : i1 to i32
      %287 = arith.shli %285, %c13_i32 : i32
      %288 = arith.shli %286, %c14_i32 : i32
      %289 = arith.ori %287, %c272629776_i32 : i32
      %290 = arith.ori %289, %288 : i32
      cf.br ^bb89(%c0_i32 : i32)
    ^bb89(%291: i32):  // 2 preds: ^bb88, ^bb96
      %292 = arith.cmpi slt, %291, %224 : i32
      cf.cond_br %292, ^bb90, ^bb97 {llvm.loop_annotation = #loop_annotation}
    ^bb90:  // pred: ^bb89
      cf.br ^bb91(%c0_i32 : i32)
    ^bb91(%293: i32):  // 2 preds: ^bb90, ^bb95
      %294 = arith.cmpi slt, %293, %224 : i32
      cf.cond_br %294, ^bb92, ^bb96 {llvm.loop_annotation = #loop_annotation}
    ^bb92:  // pred: ^bb91
      cf.br ^bb93(%c0_i32 : i32)
    ^bb93(%295: i32):  // 2 preds: ^bb92, ^bb94
      %296 = arith.cmpi slt, %295, %224 : i32
      cf.cond_br %296, ^bb94, ^bb95 {llvm.loop_annotation = #loop_annotation}
    ^bb94:  // pred: ^bb93
      cute_nvgpu.arch.mma.SM100.umma(%tup_170, %tup_171, %tmem_ptr, %290, %284) {num_cta = 2 : i32, scale = 0 : i32, a_type = f16} : (!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, !cute.ptr<f32, tmem, align<16>>, i32, i1) -> ()
      %297 = arith.addi %295, %c1_i32 : i32
      cf.br ^bb93(%297 : i32)
    ^bb95:  // pred: ^bb93
      %298 = arith.addi %293, %c1_i32 : i32
      cf.br ^bb91(%298 : i32)
    ^bb96:  // pred: ^bb91
      %299 = arith.addi %291, %c1_i32 : i32
      cf.br ^bb89(%299 : i32)
    ^bb97:  // pred: ^bb89
      %300 = cute_nvgpu.atom.set_value(%281, %true : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_f16_f16_f32_256x256x16_
      %301 = builtin.unrealized_conversion_cast %300 : !mma_f16_f16_f32_256x256x16_ to !llvm.struct<(i1, i1, i1)>
      %302 = nvvm.elect.sync -> i1
      cf.cond_br %302, ^bb98, ^bb99
    ^bb98:  // pred: ^bb97
      %ptr_172 = cute.add_offset(%ptr_14, %int_tuple_154) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %303 = builtin.unrealized_conversion_cast %ptr_172 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.tcgen05.commit.arrive %303, multicast_mask = %85 {group = #nvvm.tcgen05_group<cta_2>} : !llvm.ptr<3>, i16
      cf.br ^bb99
    ^bb99:  // 2 preds: ^bb97, ^bb98
      cf.br ^bb101(%219, %221, %223, %301 : i32, i32, i32, !llvm.struct<(i1, i1, i1)>)
    ^bb100:  // pred: ^bb56
      cf.br ^bb101(%182, %183, %184, %185 : i32, i32, i32, !llvm.struct<(i1, i1, i1)>)
    ^bb101(%304: i32, %305: i32, %306: i32, %307: !llvm.struct<(i1, i1, i1)>):  // 2 preds: ^bb99, ^bb100
      cf.br ^bb102
    ^bb102:  // pred: ^bb101
      %308 = arith.addi %178, %c1_i32 : i32
      cf.br ^bb37(%308, %216, %214, %215, %304, %305, %306, %307 : i32, i32, i32, i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>)
    ^bb103:  // pred: ^bb37
      cf.cond_br %86, ^bb104, ^bb107
    ^bb104:  // pred: ^bb103
      %309 = nvvm.elect.sync -> i1
      cf.cond_br %309, ^bb105, ^bb106
    ^bb105:  // pred: ^bb104
      %dyn_173 = cute.derefine(%iter_43) : !cute.ptr<i64, smem, align<16>> to !cute.ptr<i64, smem>
      %310 = builtin.unrealized_conversion_cast %dyn_173 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.tcgen05.commit.arrive %310, multicast_mask = %c3_i16 {group = #nvvm.tcgen05_group<cta_2>} : !llvm.ptr<3>, i16
      cf.br ^bb106
    ^bb106:  // 2 preds: ^bb104, ^bb105
      cf.br ^bb107
    ^bb107:  // 2 preds: ^bb103, ^bb106
      cf.br ^bb109(%141, %180, %181 : i32, i32, i32)
    ^bb108:  // pred: ^bb16
      cf.br ^bb109(%c1_i32, %c0_i32, %c1_i32 : i32, i32, i32)
    ^bb109(%311: i32, %312: i32, %313: i32):  // 2 preds: ^bb107, ^bb108
      cf.br ^bb110
    ^bb110:  // pred: ^bb109
      cf.cond_br %52, ^bb111, ^bb112
    ^bb111:  // pred: ^bb110
      cute_nvgpu.arch.sm100.relinquish_tmem_alloc_permit [cta_2]
      cf.br ^bb112
    ^bb112:  // 2 preds: ^bb110, ^bb111
      %dyn_174 = cute.derefine(%iter_43) : !cute.ptr<i64, smem, align<16>> to !cute.ptr<i64, smem>
      %314 = builtin.unrealized_conversion_cast %dyn_174 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %314, %c0_i32, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %iter_175 = cute.get_iter(%rmem) : !memref_rmem_f32_
      %315 = cute.get_scalars(%22) : !cute.int_tuple<"1">
      %316 = builtin.unrealized_conversion_cast %iter_175 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
      %iter_176 = cute.get_iter(%rmem_111) : !memref_rmem_f16_
      %317 = cute.get_scalars(%1) : !cute.int_tuple<"8">
      cf.br ^bb113(%c0_i32 : i32)
    ^bb113(%318: i32):  // 2 preds: ^bb112, ^bb120
      %319 = arith.cmpi slt, %318, %c4_i32 : i32
      cf.cond_br %319, ^bb114, ^bb121
    ^bb114:  // pred: ^bb113
      %coord_177 = cute.make_coord(%318) : (i32) -> !cute.coord<"(_,_,?)">
      %idx_178 = cute.crd2idx(%coord_177, %4) : (!cute.coord<"(_,_,?)">, !cute.layout<"(((64,32),1),1,((1,4),1,1)):(((1,65536),0),0,((0,64),0,0))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_179 = cute.add_offset(%ptr_107, %idx_178) : (!cute.ptr<f32, tmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<f32, tmem, align<16>>
      cf.br ^bb115(%c0_i32 : i32)
    ^bb115(%320: i32):  // 2 preds: ^bb114, ^bb116
      %321 = arith.cmpi slt, %320, %315 : i32
      cf.cond_br %321, ^bb116, ^bb117 {llvm.loop_annotation = #loop_annotation}
    ^bb116:  // pred: ^bb115
      %322 = "cute_nvgpu.arch.copy.SM100.tmem_load"(%ptr_179) <{num_b = 32 : i32, num_dp = 32 : i32, num_rep = 64 : i32}> : (!cute.ptr<f32, tmem, align<16>>) -> vector<64xi32>
      llvm.store %322, %316 : vector<64xi32>, !llvm.ptr
      %323 = arith.addi %320, %c1_i32 : i32
      cf.br ^bb115(%323 : i32)
    ^bb117:  // pred: ^bb115
      %324 = cute.memref.load_vec %rmem, row_major : !memref_rmem_f32_
      %325 = arith.truncf %324 : vector<64xf32> to vector<64xf16>
      cute.memref.store_vec %325, %rmem_111, row_major : !memref_rmem_f16_
      %idx_180 = cute.crd2idx(%coord_177, %3) : (!cute.coord<"(_,_,?)">, !cute.layout<"((64,1),1,((1,4),1,1)):((1,0),0,((0,64),0,0))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_181 = cute.add_offset(%ptr_110, %idx_180) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<f16, gmem, align<32>>
      cf.br ^bb118(%c0_i32 : i32)
    ^bb118(%326: i32):  // 2 preds: ^bb117, ^bb119
      %327 = arith.cmpi slt, %326, %317 : i32
      cf.cond_br %327, ^bb119, ^bb120 {llvm.loop_annotation = #loop_annotation}
    ^bb119:  // pred: ^bb118
      %coord_182 = cute.make_coord(%326) : (i32) -> !cute.coord<"(_,?)">
      %idx_183 = cute.crd2idx(%coord_182, %2) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(8)):(1,(8))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_184 = cute.add_offset(%iter_176, %idx_183) : (!cute.ptr<f16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
      %ptr_185 = cute.add_offset(%ptr_181, %idx_183) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, gmem, align<16>>
      %328 = builtin.unrealized_conversion_cast %ptr_184 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
      %329 = builtin.unrealized_conversion_cast %ptr_185 : !cute.ptr<f16, gmem, align<16>> to !llvm.ptr<1>
      %330 = llvm.load %328 {alignment = 16 : i64} : !llvm.ptr -> vector<8xf16>
      llvm.store %330, %329 {alignment = 16 : i64} : vector<8xf16>, !llvm.ptr<1>
      %331 = arith.addi %326, %c1_i32 : i32
      cf.br ^bb118(%331 : i32)
    ^bb120:  // pred: ^bb118
      %332 = arith.addi %318, %c1_i32 : i32
      cf.br ^bb113(%332 : i32)
    ^bb121:  // pred: ^bb113
      %333 = builtin.unrealized_conversion_cast %ptr_44 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      %334 = nvvm.mapa.shared.cluster %333, %90 : !llvm.ptr<3>, i32 -> <3>
      nvvm.mbarrier.txn %334, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>, space = #nvvm.mbar_space<cluster>} : !llvm.ptr<3>, i32
      cf.cond_br %52, ^bb122, ^bb155
    ^bb122:  // pred: ^bb121
      %335 = arith.addi %312, %c1_i32 : i32
      %336 = arith.cmpi eq, %335, %c7_i32 : i32
      %337 = arith.select %336, %c0_i32, %335 : i32
      cf.cond_br %336, ^bb123, ^bb124
    ^bb123:  // pred: ^bb122
      %338 = arith.xori %313, %c1_i32 : i32
      cf.br ^bb125(%338 : i32)
    ^bb124:  // pred: ^bb122
      cf.br ^bb125(%313 : i32)
    ^bb125(%339: i32):  // 2 preds: ^bb123, ^bb124
      cf.br ^bb126
    ^bb126:  // pred: ^bb125
      %340 = arith.addi %337, %c1_i32 : i32
      %341 = arith.cmpi eq, %340, %c7_i32 : i32
      %342 = arith.select %341, %c0_i32, %340 : i32
      cf.cond_br %341, ^bb127, ^bb128
    ^bb127:  // pred: ^bb126
      %343 = arith.xori %339, %c1_i32 : i32
      cf.br ^bb129(%343 : i32)
    ^bb128:  // pred: ^bb126
      cf.br ^bb129(%339 : i32)
    ^bb129(%344: i32):  // 2 preds: ^bb127, ^bb128
      cf.br ^bb130
    ^bb130:  // pred: ^bb129
      %345 = arith.addi %342, %c1_i32 : i32
      %346 = arith.cmpi eq, %345, %c7_i32 : i32
      %347 = arith.select %346, %c0_i32, %345 : i32
      cf.cond_br %346, ^bb131, ^bb132
    ^bb131:  // pred: ^bb130
      %348 = arith.xori %344, %c1_i32 : i32
      cf.br ^bb133(%348 : i32)
    ^bb132:  // pred: ^bb130
      cf.br ^bb133(%344 : i32)
    ^bb133(%349: i32):  // 2 preds: ^bb131, ^bb132
      cf.br ^bb134
    ^bb134:  // pred: ^bb133
      %350 = arith.addi %347, %c1_i32 : i32
      %351 = arith.cmpi eq, %350, %c7_i32 : i32
      %352 = arith.select %351, %c0_i32, %350 : i32
      cf.cond_br %351, ^bb135, ^bb136
    ^bb135:  // pred: ^bb134
      %353 = arith.xori %349, %c1_i32 : i32
      cf.br ^bb137(%353 : i32)
    ^bb136:  // pred: ^bb134
      cf.br ^bb137(%349 : i32)
    ^bb137(%354: i32):  // 2 preds: ^bb135, ^bb136
      cf.br ^bb138
    ^bb138:  // pred: ^bb137
      %355 = arith.addi %352, %c1_i32 : i32
      %356 = arith.cmpi eq, %355, %c7_i32 : i32
      %357 = arith.select %356, %c0_i32, %355 : i32
      cf.cond_br %356, ^bb139, ^bb140
    ^bb139:  // pred: ^bb138
      %358 = arith.xori %354, %c1_i32 : i32
      cf.br ^bb141(%358 : i32)
    ^bb140:  // pred: ^bb138
      cf.br ^bb141(%354 : i32)
    ^bb141(%359: i32):  // 2 preds: ^bb139, ^bb140
      cf.br ^bb142
    ^bb142:  // pred: ^bb141
      %360 = arith.addi %357, %c1_i32 : i32
      %361 = arith.cmpi eq, %360, %c7_i32 : i32
      %362 = arith.select %361, %c0_i32, %360 : i32
      cf.cond_br %361, ^bb143, ^bb144
    ^bb143:  // pred: ^bb142
      %363 = arith.xori %359, %c1_i32 : i32
      cf.br ^bb145(%363 : i32)
    ^bb144:  // pred: ^bb142
      cf.br ^bb145(%359 : i32)
    ^bb145(%364: i32):  // 2 preds: ^bb143, ^bb144
      cf.br ^bb146
    ^bb146:  // pred: ^bb145
      %int_tuple_186 = cute.make_int_tuple(%362) : (i32) -> !cute.int_tuple<"?">
      %ptr_187 = cute.add_offset(%ptr_14, %int_tuple_186) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %365 = builtin.unrealized_conversion_cast %ptr_187 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %365, %364, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      cf.cond_br %86, ^bb147, ^bb150
    ^bb147:  // pred: ^bb146
      %366 = nvvm.elect.sync -> i1
      cf.cond_br %366, ^bb148, ^bb149
    ^bb148:  // pred: ^bb147
      %ptr_188 = cute.add_offset(%iter_7, %int_tuple_186) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %367 = builtin.unrealized_conversion_cast %ptr_188 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %367, %c65536_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
      cf.br ^bb149
    ^bb149:  // 2 preds: ^bb147, ^bb148
      cf.br ^bb150
    ^bb150:  // 2 preds: ^bb146, ^bb149
      cf.cond_br %86, ^bb151, ^bb154
    ^bb151:  // pred: ^bb150
      %368 = arith.remsi %67, %c2_i32 : i32
      %369 = arith.cmpi eq, %368, %c0_i32 : i32
      cf.cond_br %369, ^bb152, ^bb153
    ^bb152:  // pred: ^bb151
      nvvm.mbarrier.try_wait.parity.shared %333, %311, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      cf.br ^bb153
    ^bb153:  // 2 preds: ^bb151, ^bb152
      cf.br ^bb154
    ^bb154:  // 2 preds: ^bb150, ^bb153
      cf.br ^bb155
    ^bb155:  // 2 preds: ^bb121, ^bb154
      nvvm.barrier id = %c1_i32
      cf.cond_br %52, ^bb156, ^bb157
    ^bb156:  // pred: ^bb155
      %370 = arith.xori %67, %c1_i32 : i32
      %371 = builtin.unrealized_conversion_cast %iter : !cute.ptr<i64, smem, align<128>> to !llvm.ptr<3>
      %372 = nvvm.mapa.shared.cluster %371, %370 : !llvm.ptr<3>, i32 -> <3>
      nvvm.mbarrier.txn %372, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>, space = #nvvm.mbar_space<cluster>} : !llvm.ptr<3>, i32
      nvvm.mbarrier.try_wait.parity.shared %371, %c0_i32, %c10000000_i32 : !llvm.ptr<3>, i32, i32
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
    %153 = arith.index_cast %151 : i32 to index
    %154 = arith.index_cast %152 : i32 to index
    gpu.launch_func  @kernels::@kernel_cutlass_kernel_TiledMMA_ThrLayoutVMNK21111000_PermutationMNK____MMAAtom_ThrID21_ShapeMNK25625616_TVLayoutA2128161281256_TVLayoutB2128161281256_TVLayoutC21282561281256_CopyAtom_ThrI_0 clusters in (%c2, %c1, %c1) blocks in (%153, %154, %c1) threads in (%c128, %c1, %c1)  dynamic_shared_memory_size %c229632_i32 args(%10 : !mma_f16_f16_f32_256x256x16_, %87 : !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_100_2sm_multicast, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, internal_val_type = f16>, %view : !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">, %145 : !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_100_2sm_multicast, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, internal_val_type = f16>, %view_5 : !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">, %arg2 : !memref_gmem_f16_) {use_pdl = false}
    return
  }
}
