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
      scf.if %52 {
        cute_nvgpu.prefetch_tma_desc(%arg1) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_100_2sm_multicast, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, internal_val_type = f16>) -> ()
        cute_nvgpu.prefetch_tma_desc(%arg3) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_100_2sm_multicast, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, internal_val_type = f16>) -> ()
      }
      %iter_7 = cute.recast_iter(%smem_ptr) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<i64, smem, align<1024>>
      scf.if %52 {
        %129 = builtin.unrealized_conversion_cast %iter_7 : !cute.ptr<i64, smem, align<1024>> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %129, %c1_i32 : !llvm.ptr<3>, i32
        %ptr_95 = cute.add_offset(%iter_7, %22) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"1">) -> !cute.ptr<i64, smem>
        %130 = builtin.unrealized_conversion_cast %ptr_95 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %130, %c1_i32 : !llvm.ptr<3>, i32
        %ptr_96 = cute.add_offset(%iter_7, %21) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"2">) -> !cute.ptr<i64, smem, align<16>>
        %131 = builtin.unrealized_conversion_cast %ptr_96 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %131, %c1_i32 : !llvm.ptr<3>, i32
        %ptr_97 = cute.add_offset(%iter_7, %20) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"3">) -> !cute.ptr<i64, smem>
        %132 = builtin.unrealized_conversion_cast %ptr_97 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %132, %c1_i32 : !llvm.ptr<3>, i32
        %ptr_98 = cute.add_offset(%iter_7, %19) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"4">) -> !cute.ptr<i64, smem, align<32>>
        %133 = builtin.unrealized_conversion_cast %ptr_98 : !cute.ptr<i64, smem, align<32>> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %133, %c1_i32 : !llvm.ptr<3>, i32
        %ptr_99 = cute.add_offset(%iter_7, %18) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"5">) -> !cute.ptr<i64, smem>
        %134 = builtin.unrealized_conversion_cast %ptr_99 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %134, %c1_i32 : !llvm.ptr<3>, i32
        %ptr_100 = cute.add_offset(%iter_7, %17) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"6">) -> !cute.ptr<i64, smem, align<16>>
        %135 = builtin.unrealized_conversion_cast %ptr_100 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %135, %c1_i32 : !llvm.ptr<3>, i32
      }
      %ptr_8 = cute.add_offset(%iter_7, %16) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"7">) -> !cute.ptr<i64, smem>
      scf.if %52 {
        %129 = builtin.unrealized_conversion_cast %ptr_8 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %129, %c1_i32 : !llvm.ptr<3>, i32
        %int_tuple_95 = cute.make_int_tuple() : () -> !cute.int_tuple<"8">
        %ptr_96 = cute.add_offset(%iter_7, %int_tuple_95) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"8">) -> !cute.ptr<i64, smem, align<64>>
        %dyn_97 = cute.derefine(%ptr_96) : !cute.ptr<i64, smem, align<64>> to !cute.ptr<i64, smem>
        %130 = builtin.unrealized_conversion_cast %dyn_97 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %130, %c1_i32 : !llvm.ptr<3>, i32
        %int_tuple_98 = cute.make_int_tuple() : () -> !cute.int_tuple<"9">
        %ptr_99 = cute.add_offset(%iter_7, %int_tuple_98) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"9">) -> !cute.ptr<i64, smem>
        %131 = builtin.unrealized_conversion_cast %ptr_99 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %131, %c1_i32 : !llvm.ptr<3>, i32
        %int_tuple_100 = cute.make_int_tuple() : () -> !cute.int_tuple<"10">
        %ptr_101 = cute.add_offset(%iter_7, %int_tuple_100) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"10">) -> !cute.ptr<i64, smem, align<16>>
        %dyn_102 = cute.derefine(%ptr_101) : !cute.ptr<i64, smem, align<16>> to !cute.ptr<i64, smem>
        %132 = builtin.unrealized_conversion_cast %dyn_102 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %132, %c1_i32 : !llvm.ptr<3>, i32
        %int_tuple_103 = cute.make_int_tuple() : () -> !cute.int_tuple<"11">
        %ptr_104 = cute.add_offset(%iter_7, %int_tuple_103) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"11">) -> !cute.ptr<i64, smem>
        %133 = builtin.unrealized_conversion_cast %ptr_104 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %133, %c1_i32 : !llvm.ptr<3>, i32
        %int_tuple_105 = cute.make_int_tuple() : () -> !cute.int_tuple<"12">
        %ptr_106 = cute.add_offset(%iter_7, %int_tuple_105) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"12">) -> !cute.ptr<i64, smem, align<32>>
        %dyn_107 = cute.derefine(%ptr_106) : !cute.ptr<i64, smem, align<32>> to !cute.ptr<i64, smem>
        %134 = builtin.unrealized_conversion_cast %dyn_107 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %134, %c1_i32 : !llvm.ptr<3>, i32
        %int_tuple_108 = cute.make_int_tuple() : () -> !cute.int_tuple<"13">
        %ptr_109 = cute.add_offset(%iter_7, %int_tuple_108) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"13">) -> !cute.ptr<i64, smem>
        %135 = builtin.unrealized_conversion_cast %ptr_109 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %135, %c1_i32 : !llvm.ptr<3>, i32
      }
      %53 = cute_nvgpu.arch.make_warp_uniform(%43) : i32
      %54 = cute.get_flat_coord(%53, %28) : (i32, !cute.layout<"((2),1,1,1):((1),0,0,0)">) -> !cute.coord<"(?,0,0,0)">
      %e0_9, %e1_10, %e2_11, %e3_12 = cute.get_leaves(%54) : !cute.coord<"(?,0,0,0)">
      %itup_13 = cute.to_int_tuple(%e0_9) : !cute.coord<"?"> to !cute.int_tuple<"?">
      %55 = cute.get_scalars(%itup_13) : !cute.int_tuple<"?">
      %coord = cute.make_coord(%itup_13) : (!cute.int_tuple<"?">) -> !cute.coord<"(?,0,_,0)">
      %idx = cute.crd2idx(%coord, %28) : (!cute.coord<"(?,0,_,0)">, !cute.layout<"((2),1,1,1):((1),0,0,0)">) -> !cute.int_tuple<"?">
      %e0_14 = cute.get_leaves(%idx) : !cute.int_tuple<"?">
      %56 = cute.get_scalars(%e0_14) : !cute.int_tuple<"?">
      %57 = arith.shli %c1_i32, %56 : i32
      %58 = arith.trunci %57 : i32 to i16
      %coord_15 = cute.make_coord(%itup_13) : (!cute.int_tuple<"?">) -> !cute.coord<"(?,_,0,0)">
      %idx_16 = cute.crd2idx(%coord_15, %28) : (!cute.coord<"(?,_,0,0)">, !cute.layout<"((2),1,1,1):((1),0,0,0)">) -> !cute.int_tuple<"?">
      %e0_17 = cute.get_leaves(%idx_16) : !cute.int_tuple<"?">
      %59 = cute.get_scalars(%e0_17) : !cute.int_tuple<"?">
      %60 = arith.shli %c1_i32, %59 : i32
      %61 = arith.trunci %60 : i32 to i16
      %62 = arith.xori %55, %c1_i32 : i32
      %coord_18 = cute.make_coord(%62) : (i32) -> !cute.coord<"(?,0,_,0)">
      %idx_19 = cute.crd2idx(%coord_18, %28) : (!cute.coord<"(?,0,_,0)">, !cute.layout<"((2),1,1,1):((1),0,0,0)">) -> !cute.int_tuple<"?">
      %e0_20 = cute.get_leaves(%idx_19) : !cute.int_tuple<"?">
      %63 = cute.get_scalars(%e0_20) : !cute.int_tuple<"?">
      %64 = arith.shli %c1_i32, %63 : i32
      %65 = arith.trunci %64 : i32 to i16
      %coord_21 = cute.make_coord(%62) : (i32) -> !cute.coord<"(?,_,0,0)">
      %idx_22 = cute.crd2idx(%coord_21, %28) : (!cute.coord<"(?,_,0,0)">, !cute.layout<"((2),1,1,1):((1),0,0,0)">) -> !cute.int_tuple<"?">
      %e0_23 = cute.get_leaves(%idx_22) : !cute.int_tuple<"?">
      %66 = cute.get_scalars(%e0_23) : !cute.int_tuple<"?">
      %67 = arith.shli %c1_i32, %66 : i32
      %68 = arith.trunci %67 : i32 to i16
      %69 = arith.ori %58, %61 : i16
      %70 = arith.ori %69, %65 : i16
      %71 = arith.ori %70, %68 : i16
      %72 = arith.cmpi eq, %45, %c0_i32 : i32
      nvvm.fence.mbarrier.init
      nvvm.cluster.arrive
      nvvm.cluster.wait
      %iter_24 = cute.recast_iter(%ptr_0) : !cute.ptr<i8, smem, align<16>> to !cute.ptr<i64, smem, align<16>>
      scf.if %52 {
        %129 = builtin.unrealized_conversion_cast %iter_24 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %129, %c1_i32 : !llvm.ptr<3>, i32
      }
      %ptr_25 = cute.add_offset(%iter_24, %22) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"1">) -> !cute.ptr<i64, smem>
      scf.if %52 {
        %129 = builtin.unrealized_conversion_cast %ptr_25 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %129, %c256_i32 : !llvm.ptr<3>, i32
      }
      %73 = arith.floordivsi %53, %c2_i32 : i32
      %74 = arith.muli %73, %c2_i32 : i32
      nvvm.fence.mbarrier.init
      nvvm.cluster.arrive
      nvvm.cluster.wait
      %coord_26 = cute.make_coord(%46, %42) : (i32, i32) -> !cute.coord<"(?,?,_)">
      %75:2 = cute.get_scalars(%coord_26) <{only_dynamic}> : !cute.coord<"(?,?,_)">
      %coord_27 = cute.make_coord(%75#0) : (i32) -> !cute.coord<"((_,_),(?,_))">
      %lay = cute.get_layout(%arg2) : !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">
      %76:2 = cute.get_scalars(%lay) <{only_dynamic}> : !cute.layout<"(?,?{div=8192}):(1@1,1@0)">
      %77 = arith.ceildivsi %76#0, %c256_i32 : i32
      %78 = arith.ceildivsi %76#1, %c64_i32 : i32
      %shape = cute.make_shape(%77, %78) : (i32, i32) -> !cute.shape<"((256,64),(?,?))">
      %lay_28 = cute.make_layout(%shape, %15) : !cute.layout<"((256,64),(?,?)):((1@1,1@0),(256@1,64@0))">
      %79:2 = cute.get_scalars(%lay_28) <{only_dynamic}> : !cute.layout<"((256,64),(?,?)):((1@1,1@0),(256@1,64@0))">
      %shape_29 = cute.make_shape(%79#1) : (i32) -> !cute.shape<"(256,64,?)">
      %lay_30 = cute.make_layout(%shape_29, %14) : !cute.layout<"(256,64,?):(1@1,1@0,64@0)">
      %idx_31 = cute.crd2idx(%coord_27, %lay_28) : (!cute.coord<"((_,_),(?,_))">, !cute.layout<"((256,64),(?,?)):((1@1,1@0),(256@1,64@0))">) -> !cute.int_tuple<"(0,?{div=256})">
      %tup = cute.add_offset(%13, %idx_31) : (!cute.int_tuple<"(0,0)">, !cute.int_tuple<"(0,?{div=256})">) -> !cute.int_tuple<"(0,?{div=256})">
      %coord_32 = cute.make_coord(%75#1) : (i32) -> !cute.coord<"((_,_),(?,_))">
      %lay_33 = cute.get_layout(%arg4) : !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">
      %80:2 = cute.get_scalars(%lay_33) <{only_dynamic}> : !cute.layout<"(?,?{div=8192}):(1@1,1@0)">
      %81 = arith.ceildivsi %80#0, %c256_i32 : i32
      %82 = arith.ceildivsi %80#1, %c64_i32 : i32
      %shape_34 = cute.make_shape(%81, %82) : (i32, i32) -> !cute.shape<"((256,64),(?,?))">
      %lay_35 = cute.make_layout(%shape_34, %15) : !cute.layout<"((256,64),(?,?)):((1@1,1@0),(256@1,64@0))">
      %83:2 = cute.get_scalars(%lay_35) <{only_dynamic}> : !cute.layout<"((256,64),(?,?)):((1@1,1@0),(256@1,64@0))">
      %shape_36 = cute.make_shape(%83#1) : (i32) -> !cute.shape<"(256,64,?)">
      %lay_37 = cute.make_layout(%shape_36, %14) : !cute.layout<"(256,64,?):(1@1,1@0,64@0)">
      %idx_38 = cute.crd2idx(%coord_32, %lay_35) : (!cute.coord<"((_,_),(?,_))">, !cute.layout<"((256,64),(?,?)):((1@1,1@0),(256@1,64@0))">) -> !cute.int_tuple<"(0,?{div=256})">
      %tup_39 = cute.add_offset(%13, %idx_38) : (!cute.int_tuple<"(0,0)">, !cute.int_tuple<"(0,?{div=256})">) -> !cute.int_tuple<"(0,?{div=256})">
      %coord_40 = cute.make_coord(%75#0, %75#1) : (i32, i32) -> !cute.coord<"((_,_),(?,?))">
      %lay_41 = cute.get_layout(%arg5) : !memref_gmem_f16_
      %84:3 = cute.get_scalars(%lay_41) <{only_dynamic}> : !cute.layout<"(?,?{div=8192}):(?{i64 div=8192},1)">
      %85 = arith.ceildivsi %84#0, %c256_i32 : i32
      %86 = arith.muli %84#2, %c256_i64 : i64
      %87 = arith.ceildivsi %84#1, %c256_i32 : i32
      %shape_42 = cute.make_shape(%85, %87) : (i32, i32) -> !cute.shape<"((256,256),(?,?))">
      %iv_43 = cute.assume(%84#2) : (i64) -> !cute.i64<divby 8192>
      %iv_44 = cute.assume(%86) : (i64) -> !cute.i64<divby 2097152>
      %stride = cute.make_stride(%iv_43, %iv_44) : (!cute.i64<divby 8192>, !cute.i64<divby 2097152>) -> !cute.stride<"((?{i64 div=8192},1),(?{i64 div=2097152},256))">
      %lay_45 = cute.make_layout(%shape_42, %stride) : !cute.layout<"((256,256),(?,?)):((?{i64 div=8192},1),(?{i64 div=2097152},256))">
      %88:4 = cute.get_scalars(%lay_45) <{only_dynamic}> : !cute.layout<"((256,256),(?,?)):((?{i64 div=8192},1),(?{i64 div=2097152},256))">
      %iv_46 = cute.assume(%88#2) : (i64) -> !cute.i64<divby 8192>
      %stride_47 = cute.make_stride(%iv_46) : (!cute.i64<divby 8192>) -> !cute.stride<"(?{i64 div=8192},1)">
      %lay_48 = cute.make_layout(%12, %stride_47) : !cute.layout<"(256,256):(?{i64 div=8192},1)">
      %idx_49 = cute.crd2idx(%coord_40, %lay_45) : (!cute.coord<"((_,_),(?,?))">, !cute.layout<"((256,256),(?,?)):((?{i64 div=8192},1),(?{i64 div=2097152},256))">) -> !cute.int_tuple<"?{i64 div=256}">
      %iter_50 = cute.get_iter(%arg5) : !memref_gmem_f16_
      %ptr_51 = cute.add_offset(%iter_50, %idx_49) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{i64 div=256}">) -> !cute.ptr<f16, gmem, align<32>>
      %coord_52 = cute.make_coord(%45) : (i32) -> !cute.coord<"?">
      %89 = cute.get_scalars(%lay_30) <{only_dynamic}> : !cute.layout<"(256,64,?):(1@1,1@0,64@0)">
      %90 = cute.get_scalars(%coord_52) <{only_dynamic}> : !cute.coord<"?">
      %91 = arith.remsi %90, %c2_i32 : i32
      %92 = arith.remsi %91, %c2_i32 : i32
      %93 = arith.muli %92, %c128_i32 : i32
      %iv_53 = cute.assume(%93) : (i32) -> !cute.i32<divby 128>
      %int_tuple = cute.make_int_tuple(%iv_53) : (!cute.i32<divby 128>) -> !cute.int_tuple<"(0,?{div=128})">
      %tup_54 = cute.add_offset(%tup, %int_tuple) : (!cute.int_tuple<"(0,?{div=256})">, !cute.int_tuple<"(0,?{div=128})">) -> !cute.int_tuple<"(0,?{div=128})">
      %shape_55 = cute.make_shape(%89) : (i32) -> !cute.shape<"((128,16),1,4,?)">
      %lay_56 = cute.make_layout(%shape_55, %11) : !cute.layout<"((128,16),1,4,?):((1@1,1@0),0,16@0,64@0)">
      %94 = cute.get_scalars(%lay_37) <{only_dynamic}> : !cute.layout<"(256,64,?):(1@1,1@0,64@0)">
      %tup_57 = cute.add_offset(%tup_39, %int_tuple) : (!cute.int_tuple<"(0,?{div=256})">, !cute.int_tuple<"(0,?{div=128})">) -> !cute.int_tuple<"(0,?{div=128})">
      %shape_58 = cute.make_shape(%94) : (i32) -> !cute.shape<"((128,16),1,4,?)">
      %lay_59 = cute.make_layout(%shape_58, %11) : !cute.layout<"((128,16),1,4,?):((1@1,1@0),0,16@0,64@0)">
      %95 = cute.get_scalars(%lay_48) <{only_dynamic}> : !cute.layout<"(256,256):(?{i64 div=8192},1)">
      %96 = arith.muli %95, %c128_i64 : i64
      %97 = arith.extsi %92 : i32 to i64
      %98 = arith.muli %97, %96 : i64
      %iv_60 = cute.assume(%98) : (i64) -> !cute.i64<divby 1048576>
      %int_tuple_61 = cute.make_int_tuple(%iv_60) : (!cute.i64<divby 1048576>) -> !cute.int_tuple<"?{i64 div=1048576}">
      %ptr_62 = cute.add_offset(%ptr_51, %int_tuple_61) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{i64 div=1048576}">) -> !cute.ptr<f16, gmem, align<32>>
      %iv_63 = cute.assume(%95) : (i64) -> !cute.i64<divby 8192>
      %stride_64 = cute.make_stride(%iv_63) : (!cute.i64<divby 8192>) -> !cute.stride<"((?{i64 div=8192},1),0,0)">
      %lay_65 = cute.make_layout(%10, %stride_64) : !cute.layout<"((128,256),1,1):((?{i64 div=8192},1),0,0)">
      %ummaSmemDesc = cute_nvgpu.make_umma_smem_desc(%iter_5 : !cute.ptr<f16, smem, align<128>, S<3,4,3>>) layout = <"((128,16),1,4,7):((64,1),0,16,8192)">, major = <k> -> !cute_nvgpu.smem_desc
      %ummaSmemDesc_66 = cute_nvgpu.make_umma_smem_desc(%iter_6 : !cute.ptr<f16, smem, align<128>, S<3,4,3>>) layout = <"((128,16),1,4,7):((64,1),0,16,8192)">, major = <k> -> !cute_nvgpu.smem_desc
      %99 = cute.get_scalars(%lay_56) <{only_dynamic}> : !cute.layout<"((128,16),1,4,?):((1@1,1@0),0,16@0,64@0)">
      %shape_67 = cute.make_shape(%99) : (i32) -> !cute.shape<"(((128,16),1,4),?)">
      %lay_68 = cute.make_layout(%shape_67, %9) : !cute.layout<"(((128,16),1,4),?):(((1@1,1@0),0,16@0),64@0)">
      %100 = cute.get_scalars(%lay_68) <{only_dynamic}> : !cute.layout<"(((128,16),1,4),?):(((1@1,1@0),0,16@0),64@0)">
      %shape_69 = cute.make_shape(%100) : (i32) -> !cute.shape<"(((64,128),1),?)">
      %lay_70 = cute.make_layout(%shape_69, %8) : !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">
      %101 = cute.get_scalars(%lay_59) <{only_dynamic}> : !cute.layout<"((128,16),1,4,?):((1@1,1@0),0,16@0,64@0)">
      %shape_71 = cute.make_shape(%101) : (i32) -> !cute.shape<"(((128,16),1,4),?)">
      %lay_72 = cute.make_layout(%shape_71, %9) : !cute.layout<"(((128,16),1,4),?):(((1@1,1@0),0,16@0),64@0)">
      %102 = cute.get_scalars(%lay_72) <{only_dynamic}> : !cute.layout<"(((128,16),1,4),?):(((1@1,1@0),0,16@0),64@0)">
      %shape_73 = cute.make_shape(%102) : (i32) -> !cute.shape<"(((64,128),1),?)">
      %lay_74 = cute.make_layout(%shape_73, %8) : !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">
      %coord_75 = cute.make_coord(%itup) : (!cute.int_tuple<"?">) -> !cute.coord<"(?,0,_,0)">
      %idx_76 = cute.crd2idx(%coord_75, %28) : (!cute.coord<"(?,0,_,0)">, !cute.layout<"((2),1,1,1):((1),0,0,0)">) -> !cute.int_tuple<"?">
      %e0_77 = cute.get_leaves(%idx_76) : !cute.int_tuple<"?">
      %103 = cute.get_scalars(%e0_77) : !cute.int_tuple<"?">
      %104 = arith.shli %c1_i32, %103 : i32
      %105 = arith.trunci %104 : i32 to i16
      %coord_78 = cute.make_coord(%itup) : (!cute.int_tuple<"?">) -> !cute.coord<"(?,_,0,0)">
      %idx_79 = cute.crd2idx(%coord_78, %28) : (!cute.coord<"(?,_,0,0)">, !cute.layout<"((2),1,1,1):((1),0,0,0)">) -> !cute.int_tuple<"?">
      %e0_80 = cute.get_leaves(%idx_79) : !cute.int_tuple<"?">
      %106 = cute.get_scalars(%e0_80) : !cute.int_tuple<"?">
      %107 = arith.shli %c1_i32, %106 : i32
      %108 = arith.trunci %107 : i32 to i16
      scf.if %52 {
        %129 = nvvm.elect.sync -> i1
        scf.if %129 {
          %130 = builtin.unrealized_conversion_cast %iter : !cute.ptr<i64, smem, align<128>> to !llvm.ptr<3>
          nvvm.mbarrier.init.shared %130, %c32_i32 : !llvm.ptr<3>, i32
        }
      }
      nvvm.fence.mbarrier.init
      scf.if %52 {
        cute_nvgpu.arch.sm100.alloc_tmem(%c512_i32, %iter_3) [cta_2] : i32, !cute.ptr<i32, smem, align<8>>
      }
      nvvm.barrier id = %c1_i32 number_of_threads = %c128_i32
      %tmem_ptr = cute_nvgpu.arch.sm100.retrieve_tmem_ptr(%iter_3) : !cute.ptr<i32, smem, align<8>> -> !cute.ptr<f32, tmem, align<16>>
      %109 = cute.get_scalars(%lay_65) <{only_dynamic}> : !cute.layout<"((128,256),1,1):((?{i64 div=8192},1),0,0)">
      %iv_81 = cute.assume(%109) : (i64) -> !cute.i64<divby 8192>
      %stride_82 = cute.make_stride(%iv_81) : (!cute.i64<divby 8192>) -> !cute.stride<"(((?{i64 div=8192},1)),((0,64),0,0))">
      %lay_83 = cute.make_layout(%7, %stride_82) : !cute.layout<"(((128,64)),((1,4),1,1)):(((?{i64 div=8192},1)),((0,64),0,0))">
      %coord_84 = cute.make_coord(%29) : (i32) -> !cute.coord<"?">
      %110 = cute.get_scalars(%coord_84) <{only_dynamic}> : !cute.coord<"?">
      %111 = arith.divsi %110, %c32_i32 : i32
      %112 = arith.muli %111, %c2097152_i32 : i32
      %iv_85 = cute.assume(%112) : (i32) -> !cute.i32<divby 2097152>
      %int_tuple_86 = cute.make_int_tuple(%iv_85) : (!cute.i32<divby 2097152>) -> !cute.int_tuple<"?{div=2097152}">
      %ptr_87 = cute.add_offset(%tmem_ptr, %int_tuple_86) : (!cute.ptr<f32, tmem, align<16>>, !cute.int_tuple<"?{div=2097152}">) -> !cute.ptr<f32, tmem, align<16>>
      %113 = cute.get_scalars(%lay_83) <{only_dynamic}> : !cute.layout<"(((128,64)),((1,4),1,1)):(((?{i64 div=8192},1)),((0,64),0,0))">
      %114 = arith.muli %113, %c32_i64 : i64
      %115 = arith.remsi %110, %c32_i32 : i32
      %116 = arith.extsi %115 : i32 to i64
      %117 = arith.muli %116, %113 : i64
      %118 = arith.extsi %111 : i32 to i64
      %119 = arith.muli %118, %114 : i64
      %120 = arith.addi %117, %119 : i64
      %iv_88 = cute.assume(%120) : (i64) -> !cute.i64<divby 8192>
      %int_tuple_89 = cute.make_int_tuple(%iv_88) : (!cute.i64<divby 8192>) -> !cute.int_tuple<"?{i64 div=8192}">
      %ptr_90 = cute.add_offset(%ptr_62, %int_tuple_89) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{i64 div=8192}">) -> !cute.ptr<f16, gmem, align<32>>
      %rmem = cute.memref.alloca() : !memref_rmem_f32_
      %rmem_91 = cute.memref.alloca() : !memref_rmem_f16_
      %sz = cute.size(%lay_30) <{mode = [2]}> : (!cute.layout<"(256,64,?):(1@1,1@0,64@0)">) -> !cute.int_tuple<"?">
      %e0_92 = cute.get_leaves(%sz) : !cute.int_tuple<"?">
      %121 = cute.get_scalars(%e0_92) : !cute.int_tuple<"?">
      %122:3 = scf.if %52 -> (i32, i32, i32) {
        %129 = arith.cmpi ne, %45, %c0_i32 : i32
        %130 = arith.extui %129 : i1 to i32
        scf.if %72 {
          %139 = builtin.unrealized_conversion_cast %ptr_25 : !cute.ptr<i64, smem> to !llvm.ptr<3>
          nvvm.mbarrier.try_wait.parity.shared %139, %c1_i32, %c10000000_i32 : !llvm.ptr<3>, i32, i32
        }
        %131 = cute_nvgpu.atom.make_exec_tma(%arg1) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_100_2sm_multicast, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>
        %132 = cute_nvgpu.atom.set_value(%131, %105 : i16) {field = #cute_nvgpu.atom_copy_field_tmaload<mcast_mask>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>
        %133 = cute_nvgpu.atom.make_exec_tma(%arg3) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_100_2sm_multicast, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>
        %134 = cute_nvgpu.atom.set_value(%133, %108 : i16) {field = #cute_nvgpu.atom_copy_field_tmaload<mcast_mask>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>
        %135 = arith.minsi %121, %c5_i32 : i32
        %136 = cute.get_scalars(%22) : !cute.int_tuple<"1">
        %137:3 = scf.for %arg6 = %c0_i32 to %135 step %c1_i32 iter_args(%arg7 = %c0_i32, %arg8 = %c1_i32, %arg9 = %c0_i32) -> (i32, i32, i32)  : i32 {
          %int_tuple_95 = cute.make_int_tuple(%arg7) : (i32) -> !cute.int_tuple<"?">
          %ptr_96 = cute.add_offset(%ptr_8, %int_tuple_95) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
          %139 = builtin.unrealized_conversion_cast %ptr_96 : !cute.ptr<i64, smem> to !llvm.ptr<3>
          nvvm.mbarrier.try_wait.parity.shared %139, %arg8, %c10000000_i32 : !llvm.ptr<3>, i32, i32
          scf.if %72 {
            %153 = nvvm.elect.sync -> i1
            scf.if %153 {
              %ptr_114 = cute.add_offset(%iter_7, %int_tuple_95) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
              %154 = builtin.unrealized_conversion_cast %ptr_114 : !cute.ptr<i64, smem> to !llvm.ptr<3>
              nvvm.mbarrier.txn %154, %c65536_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
            }
          }
          %140 = arith.addi %arg7, %c1_i32 : i32
          %141 = arith.addi %arg9, %c1_i32 : i32
          %142 = arith.cmpi eq, %140, %c7_i32 : i32
          %143 = arith.select %142, %c0_i32, %140 : i32
          %144 = scf.if %142 -> (i32) {
            %153 = arith.xori %arg8, %c1_i32 : i32
            scf.yield %153 : i32
          } else {
            scf.yield %arg8 : i32
          }
          %coord_97 = cute.make_coord(%arg9) : (i32) -> !cute.coord<"(_,?)">
          %idx_98 = cute.crd2idx(%coord_97, %lay_70) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
          %tup_99 = cute.add_offset(%tup_54, %idx_98) : (!cute.int_tuple<"(0,?{div=128})">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
          %e0_100, %e1_101 = cute.get_leaves(%tup_99) : !cute.int_tuple<"(?{div=64},?{div=128})">
          %coord_102 = cute.make_coord(%arg7) : (i32) -> !cute.coord<"(_,?)">
          %idx_103 = cute.crd2idx(%coord_102, %6) : (!cute.coord<"(_,?)">, !cute.layout<"((8192,1),7):((1,0),8192)">) -> !cute.int_tuple<"?{div=8192}">
          %ptr_104 = cute.add_offset(%iter_5, %idx_103) : (!cute.ptr<f16, smem, align<128>, S<3,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<f16, smem, align<128>, S<3,4,3>>
          %ptr_105 = cute.add_offset(%iter_7, %int_tuple_95) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
          %int_tuple_106 = cute.make_int_tuple(%e0_100, %e1_101) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=128}">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
          %145 = cute_nvgpu.atom.set_value(%132, %ptr_105 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>
          %146 = cute_nvgpu.atom.get_value(%145 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
          %147 = cute_nvgpu.atom.get_value(%145 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<mcast_mask>} : i16
          %TMADescAddr = cute_nvgpu.get_tma_desc_addr(%145 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) -> !cute.ptr<generic, align<64>>
          %148:2 = cute.get_scalars(%int_tuple_106) : !cute.int_tuple<"(?{div=64},?{div=128})">
          scf.for %arg10 = %c0_i32 to %136 step %c1_i32  : i32 {
            cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr : !cute.ptr<generic, align<64>>, %ptr_104 : !cute.ptr<f16, smem, align<128>, S<3,4,3>>, %146 : !cute.ptr<smem, align<8>>, [%148#0, %148#1] : i32, i32) mask = %147 mode = <tiled> num_cta = 2 : i32
          } {llvm.loop_annotation = #loop_annotation}
          %idx_107 = cute.crd2idx(%coord_97, %lay_74) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
          %tup_108 = cute.add_offset(%tup_57, %idx_107) : (!cute.int_tuple<"(0,?{div=128})">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
          %e0_109, %e1_110 = cute.get_leaves(%tup_108) : !cute.int_tuple<"(?{div=64},?{div=128})">
          %ptr_111 = cute.add_offset(%iter_6, %idx_103) : (!cute.ptr<f16, smem, align<128>, S<3,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<f16, smem, align<128>, S<3,4,3>>
          %int_tuple_112 = cute.make_int_tuple(%e0_109, %e1_110) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=128}">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
          %149 = cute_nvgpu.atom.set_value(%134, %ptr_105 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>
          %150 = cute_nvgpu.atom.get_value(%149 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
          %151 = cute_nvgpu.atom.get_value(%149 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<mcast_mask>} : i16
          %TMADescAddr_113 = cute_nvgpu.get_tma_desc_addr(%149 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) -> !cute.ptr<generic, align<64>>
          %152:2 = cute.get_scalars(%int_tuple_112) : !cute.int_tuple<"(?{div=64},?{div=128})">
          scf.for %arg10 = %c0_i32 to %136 step %c1_i32  : i32 {
            cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr_113 : !cute.ptr<generic, align<64>>, %ptr_111 : !cute.ptr<f16, smem, align<128>, S<3,4,3>>, %150 : !cute.ptr<smem, align<8>>, [%152#0, %152#1] : i32, i32) mask = %151 mode = <tiled> num_cta = 2 : i32
          } {llvm.loop_annotation = #loop_annotation}
          scf.yield %143, %144, %141 : i32, i32, i32
        }
        %138:7 = scf.for %arg6 = %c0_i32 to %121 step %c1_i32 iter_args(%arg7 = %137#2, %arg8 = %137#0, %arg9 = %137#1, %arg10 = %c0_i32, %arg11 = %c0_i32, %arg12 = %c0_i32, %arg13 = %0) -> (i32, i32, i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>)  : i32 {
          %139 = builtin.unrealized_conversion_cast %arg13 : !llvm.struct<(i1, i1, i1)> to !mma_f16_f16_f32_256x256x16_
          %140 = arith.addi %arg6, %135 : i32
          %141 = arith.cmpi ult, %140, %121 : i32
          %142:3 = scf.if %141 -> (i32, i32, i32) {
            %int_tuple_95 = cute.make_int_tuple(%arg8) : (i32) -> !cute.int_tuple<"?">
            %ptr_96 = cute.add_offset(%ptr_8, %int_tuple_95) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
            %144 = builtin.unrealized_conversion_cast %ptr_96 : !cute.ptr<i64, smem> to !llvm.ptr<3>
            nvvm.mbarrier.try_wait.parity.shared %144, %arg9, %c10000000_i32 : !llvm.ptr<3>, i32, i32
            scf.if %72 {
              %159 = nvvm.elect.sync -> i1
              scf.if %159 {
                %ptr_114 = cute.add_offset(%iter_7, %int_tuple_95) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
                %160 = builtin.unrealized_conversion_cast %ptr_114 : !cute.ptr<i64, smem> to !llvm.ptr<3>
                nvvm.mbarrier.txn %160, %c65536_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
              }
            }
            %145 = arith.addi %arg8, %c1_i32 : i32
            %146 = arith.addi %arg7, %c1_i32 : i32
            %147 = arith.cmpi eq, %145, %c7_i32 : i32
            %148 = arith.select %147, %c0_i32, %145 : i32
            %149 = scf.if %147 -> (i32) {
              %159 = arith.xori %arg9, %c1_i32 : i32
              scf.yield %159 : i32
            } else {
              scf.yield %arg9 : i32
            }
            %coord_97 = cute.make_coord(%arg7) : (i32) -> !cute.coord<"(_,?)">
            %idx_98 = cute.crd2idx(%coord_97, %lay_70) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
            %tup_99 = cute.add_offset(%tup_54, %idx_98) : (!cute.int_tuple<"(0,?{div=128})">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
            %e0_100, %e1_101 = cute.get_leaves(%tup_99) : !cute.int_tuple<"(?{div=64},?{div=128})">
            %coord_102 = cute.make_coord(%arg8) : (i32) -> !cute.coord<"(_,?)">
            %idx_103 = cute.crd2idx(%coord_102, %6) : (!cute.coord<"(_,?)">, !cute.layout<"((8192,1),7):((1,0),8192)">) -> !cute.int_tuple<"?{div=8192}">
            %ptr_104 = cute.add_offset(%iter_5, %idx_103) : (!cute.ptr<f16, smem, align<128>, S<3,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<f16, smem, align<128>, S<3,4,3>>
            %ptr_105 = cute.add_offset(%iter_7, %int_tuple_95) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
            %int_tuple_106 = cute.make_int_tuple(%e0_100, %e1_101) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=128}">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
            %150 = cute_nvgpu.atom.set_value(%132, %ptr_105 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>
            %151 = cute.get_scalars(%22) : !cute.int_tuple<"1">
            %152 = cute_nvgpu.atom.get_value(%150 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
            %153 = cute_nvgpu.atom.get_value(%150 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<mcast_mask>} : i16
            %TMADescAddr = cute_nvgpu.get_tma_desc_addr(%150 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) -> !cute.ptr<generic, align<64>>
            %154:2 = cute.get_scalars(%int_tuple_106) : !cute.int_tuple<"(?{div=64},?{div=128})">
            scf.for %arg14 = %c0_i32 to %151 step %c1_i32  : i32 {
              cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr : !cute.ptr<generic, align<64>>, %ptr_104 : !cute.ptr<f16, smem, align<128>, S<3,4,3>>, %152 : !cute.ptr<smem, align<8>>, [%154#0, %154#1] : i32, i32) mask = %153 mode = <tiled> num_cta = 2 : i32
            } {llvm.loop_annotation = #loop_annotation}
            %idx_107 = cute.crd2idx(%coord_97, %lay_74) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
            %tup_108 = cute.add_offset(%tup_57, %idx_107) : (!cute.int_tuple<"(0,?{div=128})">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
            %e0_109, %e1_110 = cute.get_leaves(%tup_108) : !cute.int_tuple<"(?{div=64},?{div=128})">
            %ptr_111 = cute.add_offset(%iter_6, %idx_103) : (!cute.ptr<f16, smem, align<128>, S<3,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<f16, smem, align<128>, S<3,4,3>>
            %int_tuple_112 = cute.make_int_tuple(%e0_109, %e1_110) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=128}">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
            %155 = cute_nvgpu.atom.set_value(%134, %ptr_105 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>
            %156 = cute_nvgpu.atom.get_value(%155 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
            %157 = cute_nvgpu.atom.get_value(%155 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<mcast_mask>} : i16
            %TMADescAddr_113 = cute_nvgpu.get_tma_desc_addr(%155 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) -> !cute.ptr<generic, align<64>>
            %158:2 = cute.get_scalars(%int_tuple_112) : !cute.int_tuple<"(?{div=64},?{div=128})">
            scf.for %arg14 = %c0_i32 to %151 step %c1_i32  : i32 {
              cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr_113 : !cute.ptr<generic, align<64>>, %ptr_111 : !cute.ptr<f16, smem, align<128>, S<3,4,3>>, %156 : !cute.ptr<smem, align<8>>, [%158#0, %158#1] : i32, i32) mask = %157 mode = <tiled> num_cta = 2 : i32
            } {llvm.loop_annotation = #loop_annotation}
            scf.yield %148, %149, %146 : i32, i32, i32
          } else {
            scf.yield %arg8, %arg9, %arg7 : i32, i32, i32
          }
          %143:4 = scf.if %72 -> (i32, i32, i32, !llvm.struct<(i1, i1, i1)>) {
            %int_tuple_95 = cute.make_int_tuple(%arg11) : (i32) -> !cute.int_tuple<"?">
            %ptr_96 = cute.add_offset(%iter_7, %int_tuple_95) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
            %144 = builtin.unrealized_conversion_cast %ptr_96 : !cute.ptr<i64, smem> to !llvm.ptr<3>
            nvvm.mbarrier.try_wait.parity.shared %144, %arg12, %c10000000_i32 : !llvm.ptr<3>, i32, i32
            %145 = arith.addi %arg11, %c1_i32 : i32
            %146 = arith.addi %arg10, %c1_i32 : i32
            %147 = arith.cmpi eq, %145, %c7_i32 : i32
            %148 = arith.select %147, %c0_i32, %145 : i32
            %149 = scf.if %147 -> (i32) {
              %193 = arith.xori %arg12, %c1_i32 : i32
              scf.yield %193 : i32
            } else {
              scf.yield %arg12 : i32
            }
            %coord_97 = cute.make_coord(%arg11) : (i32) -> !cute.coord<"(_,_,0,?)">
            %idx_98 = cute.crd2idx(%coord_97, %5) : (!cute.coord<"(_,_,0,?)">, !cute.layout<"(1,1,4,7):(0,0,2,1024)">) -> !cute.int_tuple<"?{div=1024}">
            %tup_99 = cute.add_offset(%ummaSmemDesc, %idx_98) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=1024}">) -> !cute_nvgpu.smem_desc
            %tup_100 = cute.add_offset(%ummaSmemDesc_66, %idx_98) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=1024}">) -> !cute_nvgpu.smem_desc
            %150 = cute.get_scalars(%22) : !cute.int_tuple<"1">
            %151 = cute_nvgpu.atom.get_value(%139 : !mma_f16_f16_f32_256x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : i1
            %152 = cute_nvgpu.atom.get_value(%139 : !mma_f16_f16_f32_256x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : i1
            %153 = cute_nvgpu.atom.get_value(%139 : !mma_f16_f16_f32_256x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : i1
            %154 = arith.extui %151 : i1 to i32
            %155 = arith.extui %152 : i1 to i32
            %156 = arith.shli %154, %c13_i32 : i32
            %157 = arith.shli %155, %c14_i32 : i32
            %158 = arith.ori %156, %c272629776_i32 : i32
            %159 = arith.ori %158, %157 : i32
            scf.for %arg14 = %c0_i32 to %150 step %c1_i32  : i32 {
              scf.for %arg15 = %c0_i32 to %150 step %c1_i32  : i32 {
                scf.for %arg16 = %c0_i32 to %150 step %c1_i32  : i32 {
                  cute_nvgpu.arch.mma.SM100.umma(%tup_99, %tup_100, %tmem_ptr, %159, %153) {num_cta = 2 : i32, scale = 0 : i32, a_type = f16} : (!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, !cute.ptr<f32, tmem, align<16>>, i32, i1) -> ()
                } {llvm.loop_annotation = #loop_annotation}
              } {llvm.loop_annotation = #loop_annotation}
            } {llvm.loop_annotation = #loop_annotation}
            %160 = cute_nvgpu.atom.set_value(%139, %true : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_f16_f16_f32_256x256x16_
            %coord_101 = cute.make_coord(%arg11) : (i32) -> !cute.coord<"(_,_,1,?)">
            %idx_102 = cute.crd2idx(%coord_101, %5) : (!cute.coord<"(_,_,1,?)">, !cute.layout<"(1,1,4,7):(0,0,2,1024)">) -> !cute.int_tuple<"?{div=2}">
            %tup_103 = cute.add_offset(%ummaSmemDesc, %idx_102) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
            %tup_104 = cute.add_offset(%ummaSmemDesc_66, %idx_102) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
            %161 = cute_nvgpu.atom.get_value(%160 : !mma_f16_f16_f32_256x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : i1
            %162 = cute_nvgpu.atom.get_value(%160 : !mma_f16_f16_f32_256x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : i1
            %163 = cute_nvgpu.atom.get_value(%160 : !mma_f16_f16_f32_256x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : i1
            %164 = arith.extui %161 : i1 to i32
            %165 = arith.extui %162 : i1 to i32
            %166 = arith.shli %164, %c13_i32 : i32
            %167 = arith.shli %165, %c14_i32 : i32
            %168 = arith.ori %166, %c272629776_i32 : i32
            %169 = arith.ori %168, %167 : i32
            scf.for %arg14 = %c0_i32 to %150 step %c1_i32  : i32 {
              scf.for %arg15 = %c0_i32 to %150 step %c1_i32  : i32 {
                scf.for %arg16 = %c0_i32 to %150 step %c1_i32  : i32 {
                  cute_nvgpu.arch.mma.SM100.umma(%tup_103, %tup_104, %tmem_ptr, %169, %163) {num_cta = 2 : i32, scale = 0 : i32, a_type = f16} : (!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, !cute.ptr<f32, tmem, align<16>>, i32, i1) -> ()
                } {llvm.loop_annotation = #loop_annotation}
              } {llvm.loop_annotation = #loop_annotation}
            } {llvm.loop_annotation = #loop_annotation}
            %170 = cute_nvgpu.atom.set_value(%160, %true : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_f16_f16_f32_256x256x16_
            %coord_105 = cute.make_coord(%arg11) : (i32) -> !cute.coord<"(_,_,2,?)">
            %idx_106 = cute.crd2idx(%coord_105, %5) : (!cute.coord<"(_,_,2,?)">, !cute.layout<"(1,1,4,7):(0,0,2,1024)">) -> !cute.int_tuple<"?{div=4}">
            %tup_107 = cute.add_offset(%ummaSmemDesc, %idx_106) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=4}">) -> !cute_nvgpu.smem_desc
            %tup_108 = cute.add_offset(%ummaSmemDesc_66, %idx_106) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=4}">) -> !cute_nvgpu.smem_desc
            %171 = cute_nvgpu.atom.get_value(%170 : !mma_f16_f16_f32_256x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : i1
            %172 = cute_nvgpu.atom.get_value(%170 : !mma_f16_f16_f32_256x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : i1
            %173 = cute_nvgpu.atom.get_value(%170 : !mma_f16_f16_f32_256x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : i1
            %174 = arith.extui %171 : i1 to i32
            %175 = arith.extui %172 : i1 to i32
            %176 = arith.shli %174, %c13_i32 : i32
            %177 = arith.shli %175, %c14_i32 : i32
            %178 = arith.ori %176, %c272629776_i32 : i32
            %179 = arith.ori %178, %177 : i32
            scf.for %arg14 = %c0_i32 to %150 step %c1_i32  : i32 {
              scf.for %arg15 = %c0_i32 to %150 step %c1_i32  : i32 {
                scf.for %arg16 = %c0_i32 to %150 step %c1_i32  : i32 {
                  cute_nvgpu.arch.mma.SM100.umma(%tup_107, %tup_108, %tmem_ptr, %179, %173) {num_cta = 2 : i32, scale = 0 : i32, a_type = f16} : (!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, !cute.ptr<f32, tmem, align<16>>, i32, i1) -> ()
                } {llvm.loop_annotation = #loop_annotation}
              } {llvm.loop_annotation = #loop_annotation}
            } {llvm.loop_annotation = #loop_annotation}
            %180 = cute_nvgpu.atom.set_value(%170, %true : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_f16_f16_f32_256x256x16_
            %coord_109 = cute.make_coord(%arg11) : (i32) -> !cute.coord<"(_,_,3,?)">
            %idx_110 = cute.crd2idx(%coord_109, %5) : (!cute.coord<"(_,_,3,?)">, !cute.layout<"(1,1,4,7):(0,0,2,1024)">) -> !cute.int_tuple<"?{div=2}">
            %tup_111 = cute.add_offset(%ummaSmemDesc, %idx_110) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
            %tup_112 = cute.add_offset(%ummaSmemDesc_66, %idx_110) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
            %181 = cute_nvgpu.atom.get_value(%180 : !mma_f16_f16_f32_256x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : i1
            %182 = cute_nvgpu.atom.get_value(%180 : !mma_f16_f16_f32_256x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : i1
            %183 = cute_nvgpu.atom.get_value(%180 : !mma_f16_f16_f32_256x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : i1
            %184 = arith.extui %181 : i1 to i32
            %185 = arith.extui %182 : i1 to i32
            %186 = arith.shli %184, %c13_i32 : i32
            %187 = arith.shli %185, %c14_i32 : i32
            %188 = arith.ori %186, %c272629776_i32 : i32
            %189 = arith.ori %188, %187 : i32
            scf.for %arg14 = %c0_i32 to %150 step %c1_i32  : i32 {
              scf.for %arg15 = %c0_i32 to %150 step %c1_i32  : i32 {
                scf.for %arg16 = %c0_i32 to %150 step %c1_i32  : i32 {
                  cute_nvgpu.arch.mma.SM100.umma(%tup_111, %tup_112, %tmem_ptr, %189, %183) {num_cta = 2 : i32, scale = 0 : i32, a_type = f16} : (!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, !cute.ptr<f32, tmem, align<16>>, i32, i1) -> ()
                } {llvm.loop_annotation = #loop_annotation}
              } {llvm.loop_annotation = #loop_annotation}
            } {llvm.loop_annotation = #loop_annotation}
            %190 = cute_nvgpu.atom.set_value(%180, %true : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_f16_f16_f32_256x256x16_
            %191 = builtin.unrealized_conversion_cast %190 : !mma_f16_f16_f32_256x256x16_ to !llvm.struct<(i1, i1, i1)>
            %192 = nvvm.elect.sync -> i1
            scf.if %192 {
              %ptr_113 = cute.add_offset(%ptr_8, %int_tuple_95) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
              %193 = builtin.unrealized_conversion_cast %ptr_113 : !cute.ptr<i64, smem> to !llvm.ptr<3>
              nvvm.tcgen05.commit.arrive %193, multicast_mask = %71 {group = #nvvm.tcgen05_group<cta_2>} : !llvm.ptr<3>, i16
            }
            scf.yield %146, %148, %149, %191 : i32, i32, i32, !llvm.struct<(i1, i1, i1)>
          } else {
            scf.yield %arg10, %arg11, %arg12, %arg13 : i32, i32, i32, !llvm.struct<(i1, i1, i1)>
          }
          scf.yield %142#2, %142#0, %142#1, %143#0, %143#1, %143#2, %143#3 : i32, i32, i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>
        }
        scf.if %72 {
          %139 = nvvm.elect.sync -> i1
          scf.if %139 {
            %dyn_95 = cute.derefine(%iter_24) : !cute.ptr<i64, smem, align<16>> to !cute.ptr<i64, smem>
            %140 = builtin.unrealized_conversion_cast %dyn_95 : !cute.ptr<i64, smem> to !llvm.ptr<3>
            nvvm.tcgen05.commit.arrive %140, multicast_mask = %c3_i16 {group = #nvvm.tcgen05_group<cta_2>} : !llvm.ptr<3>, i16
          }
        }
        scf.yield %130, %138#1, %138#2 : i32, i32, i32
      } else {
        scf.yield %c1_i32, %c0_i32, %c1_i32 : i32, i32, i32
      }
      scf.if %52 {
        cute_nvgpu.arch.sm100.relinquish_tmem_alloc_permit [cta_2]
      }
      %dyn = cute.derefine(%iter_24) : !cute.ptr<i64, smem, align<16>> to !cute.ptr<i64, smem>
      %123 = builtin.unrealized_conversion_cast %dyn : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %123, %c0_i32, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %iter_93 = cute.get_iter(%rmem) : !memref_rmem_f32_
      %124 = cute.get_scalars(%22) : !cute.int_tuple<"1">
      %125 = builtin.unrealized_conversion_cast %iter_93 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
      %iter_94 = cute.get_iter(%rmem_91) : !memref_rmem_f16_
      %126 = cute.get_scalars(%1) : !cute.int_tuple<"8">
      scf.for %arg6 = %c0_i32 to %c4_i32 step %c1_i32  : i32 {
        %coord_95 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,_,?)">
        %idx_96 = cute.crd2idx(%coord_95, %4) : (!cute.coord<"(_,_,?)">, !cute.layout<"(((64,32),1),1,((1,4),1,1)):(((1,65536),0),0,((0,64),0,0))">) -> !cute.int_tuple<"?{div=64}">
        %ptr_97 = cute.add_offset(%ptr_87, %idx_96) : (!cute.ptr<f32, tmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<f32, tmem, align<16>>
        scf.for %arg7 = %c0_i32 to %124 step %c1_i32  : i32 {
          %131 = "cute_nvgpu.arch.copy.SM100.tmem_load"(%ptr_97) <{num_b = 32 : i32, num_dp = 32 : i32, num_rep = 64 : i32}> : (!cute.ptr<f32, tmem, align<16>>) -> vector<64xi32>
          llvm.store %131, %125 : vector<64xi32>, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %129 = cute.memref.load_vec %rmem, row_major : !memref_rmem_f32_
        %130 = arith.truncf %129 : vector<64xf32> to vector<64xf16>
        cute.memref.store_vec %130, %rmem_91, row_major : !memref_rmem_f16_
        %idx_98 = cute.crd2idx(%coord_95, %3) : (!cute.coord<"(_,_,?)">, !cute.layout<"((64,1),1,((1,4),1,1)):((1,0),0,((0,64),0,0))">) -> !cute.int_tuple<"?{div=64}">
        %ptr_99 = cute.add_offset(%ptr_90, %idx_98) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<f16, gmem, align<32>>
        scf.for %arg7 = %c0_i32 to %126 step %c1_i32  : i32 {
          %coord_100 = cute.make_coord(%arg7) : (i32) -> !cute.coord<"(_,?)">
          %idx_101 = cute.crd2idx(%coord_100, %2) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(8)):(1,(8))">) -> !cute.int_tuple<"?{div=8}">
          %ptr_102 = cute.add_offset(%iter_94, %idx_101) : (!cute.ptr<f16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
          %ptr_103 = cute.add_offset(%ptr_99, %idx_101) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, gmem, align<16>>
          %131 = builtin.unrealized_conversion_cast %ptr_102 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
          %132 = builtin.unrealized_conversion_cast %ptr_103 : !cute.ptr<f16, gmem, align<16>> to !llvm.ptr<1>
          %133 = llvm.load %131 {alignment = 16 : i64} : !llvm.ptr -> vector<8xf16>
          llvm.store %133, %132 {alignment = 16 : i64} : vector<8xf16>, !llvm.ptr<1>
        } {llvm.loop_annotation = #loop_annotation}
      }
      %127 = builtin.unrealized_conversion_cast %ptr_25 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      %128 = nvvm.mapa.shared.cluster %127, %74 : !llvm.ptr<3>, i32 -> <3>
      nvvm.mbarrier.txn %128, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>, space = #nvvm.mbar_space<cluster>} : !llvm.ptr<3>, i32
      scf.if %52 {
        %129 = arith.addi %122#1, %c1_i32 : i32
        %130 = arith.cmpi eq, %129, %c7_i32 : i32
        %131 = arith.select %130, %c0_i32, %129 : i32
        %132 = scf.if %130 -> (i32) {
          %154 = arith.xori %122#2, %c1_i32 : i32
          scf.yield %154 : i32
        } else {
          scf.yield %122#2 : i32
        }
        %133 = arith.addi %131, %c1_i32 : i32
        %134 = arith.cmpi eq, %133, %c7_i32 : i32
        %135 = arith.select %134, %c0_i32, %133 : i32
        %136 = scf.if %134 -> (i32) {
          %154 = arith.xori %132, %c1_i32 : i32
          scf.yield %154 : i32
        } else {
          scf.yield %132 : i32
        }
        %137 = arith.addi %135, %c1_i32 : i32
        %138 = arith.cmpi eq, %137, %c7_i32 : i32
        %139 = arith.select %138, %c0_i32, %137 : i32
        %140 = scf.if %138 -> (i32) {
          %154 = arith.xori %136, %c1_i32 : i32
          scf.yield %154 : i32
        } else {
          scf.yield %136 : i32
        }
        %141 = arith.addi %139, %c1_i32 : i32
        %142 = arith.cmpi eq, %141, %c7_i32 : i32
        %143 = arith.select %142, %c0_i32, %141 : i32
        %144 = scf.if %142 -> (i32) {
          %154 = arith.xori %140, %c1_i32 : i32
          scf.yield %154 : i32
        } else {
          scf.yield %140 : i32
        }
        %145 = arith.addi %143, %c1_i32 : i32
        %146 = arith.cmpi eq, %145, %c7_i32 : i32
        %147 = arith.select %146, %c0_i32, %145 : i32
        %148 = scf.if %146 -> (i32) {
          %154 = arith.xori %144, %c1_i32 : i32
          scf.yield %154 : i32
        } else {
          scf.yield %144 : i32
        }
        %149 = arith.addi %147, %c1_i32 : i32
        %150 = arith.cmpi eq, %149, %c7_i32 : i32
        %151 = arith.select %150, %c0_i32, %149 : i32
        %152 = scf.if %150 -> (i32) {
          %154 = arith.xori %148, %c1_i32 : i32
          scf.yield %154 : i32
        } else {
          scf.yield %148 : i32
        }
        %int_tuple_95 = cute.make_int_tuple(%151) : (i32) -> !cute.int_tuple<"?">
        %ptr_96 = cute.add_offset(%ptr_8, %int_tuple_95) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
        %153 = builtin.unrealized_conversion_cast %ptr_96 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        nvvm.mbarrier.try_wait.parity.shared %153, %152, %c10000000_i32 : !llvm.ptr<3>, i32, i32
        scf.if %72 {
          %154 = nvvm.elect.sync -> i1
          scf.if %154 {
            %ptr_97 = cute.add_offset(%iter_7, %int_tuple_95) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
            %155 = builtin.unrealized_conversion_cast %ptr_97 : !cute.ptr<i64, smem> to !llvm.ptr<3>
            nvvm.mbarrier.txn %155, %c65536_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
          }
        }
        scf.if %72 {
          %154 = arith.remsi %53, %c2_i32 : i32
          %155 = arith.cmpi eq, %154, %c0_i32 : i32
          scf.if %155 {
            nvvm.mbarrier.try_wait.parity.shared %127, %122#0, %c10000000_i32 : !llvm.ptr<3>, i32, i32
          }
        }
      }
      nvvm.barrier id = %c1_i32
      scf.if %52 {
        %129 = arith.xori %53, %c1_i32 : i32
        %130 = builtin.unrealized_conversion_cast %iter : !cute.ptr<i64, smem, align<128>> to !llvm.ptr<3>
        %131 = nvvm.mapa.shared.cluster %130, %129 : !llvm.ptr<3>, i32 -> <3>
        nvvm.mbarrier.txn %131, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>, space = #nvvm.mbar_space<cluster>} : !llvm.ptr<3>, i32
        nvvm.mbarrier.try_wait.parity.shared %130, %c0_i32, %c10000000_i32 : !llvm.ptr<3>, i32, i32
        cute_nvgpu.arch.sm100.dealloc_tmem(%tmem_ptr, %c512_i32) [cta_2] : !cute.ptr<f32, tmem, align<16>>, i32
      }
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
