!memref_gmem_f16_ = !cute.memref<f16, gmem, align<32>, "(?,?{div=8192}):(?{i64 div=8192},1)">
!memref_rmem_f16_ = !cute.memref<f16, rmem, align<32>, "((64,1),1):((1,0),0)">
!memref_rmem_f32_ = !cute.memref<f32, rmem, align<32>, "((64,1),1):((1,0),0)">
!mma_f16_f16_f32_256x256x16_ = !cute.tiled_mma<!cute_nvgpu.sm100.mma<256x256x16, num_cta = 2, ab_major = (k, k), elem_type = (f16, f16, f32), frag_kind = ss, c_scale_exp = 0>, atom_layout_MNK = <"(1,1,1):(0,0,0)">>
#loop_unroll = #llvm.loop_unroll<disable = false, full = true>
#loop_annotation = #llvm.loop_annotation<unroll = #loop_unroll>
module attributes {gpu.container_module} {
  gpu.module @kernels {
    cuda.kernel @kernel_cutlass_kernel_TiledMMA_ThrLayoutVMNK21111000_PermutationMNK____MMAAtom_ThrID21_ShapeMNK25625616_TVLayoutA2128161281256_TVLayoutB2128161281256_TVLayoutC21282561281256_CopyAtom_ThrI_0(%arg0: !mma_f16_f16_f32_256x256x16_, %arg1: !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_100_2sm_multicast, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, internal_val_type = f16>, %arg2: !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">, %arg3: !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_100_2sm_multicast, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, internal_val_type = f16>, %arg4: !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">, %arg5: !memref_gmem_f16_) attributes {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} {
      %c127_i32 = arith.constant 127 : i32
      %0 = cute.static : !cute.layout<"(16,(4)):(1,(16))">
      %1 = cute.static : !cute.layout<"((64,1),1,((1,4),1,1)):((1,0),0,((0,64),0,0))">
      %2 = cute.static : !cute.layout<"(((64,32),1),1,((1,4),1,1)):(((1,65536),0),0,((0,64),0,0))">
      %c4_i32 = arith.constant 4 : i32
      %c3_i16 = arith.constant 3 : i16
      %c14_i32 = arith.constant 14 : i32
      %c13_i32 = arith.constant 13 : i32
      %c272629776_i32 = arith.constant 272629776 : i32
      %3 = cute.static : !cute.layout<"(1,1,4,7):(0,0,2,1024)">
      %4 = cute.static : !cute.layout<"((8192,1),7):((1,0),8192)">
      %c65536_i32 = arith.constant 65536 : i32
      %c5_i32 = arith.constant 5 : i32
      %c7_i32 = arith.constant 7 : i32
      %c10000000_i32 = arith.constant 10000000 : i32
      %true = arith.constant true
      %c32_i64 = arith.constant 32 : i64
      %c2097152_i32 = arith.constant 2097152 : i32
      %5 = cute.static : !cute.shape<"(((128,64)),((1,4),1,1))">
      %c512_i32 = arith.constant 512 : i32
      %6 = cute.static : !cute.stride<"(((1@0,1@1),0),64@0)">
      %7 = cute.static : !cute.stride<"(((1@1,1@0),0,16@0),64@0)">
      %8 = cute.static : !cute.shape<"((128,256),1,1)">
      %c128_i64 = arith.constant 128 : i64
      %9 = cute.static : !cute.stride<"((1@1,1@0),0,16@0,64@0)">
      %10 = cute.static : !cute.shape<"(256,256)">
      %c256_i64 = arith.constant 256 : i64
      %11 = cute.static : !cute.int_tuple<"(0,0)">
      %12 = cute.static : !cute.stride<"(1@1,1@0,64@0)">
      %13 = cute.static : !cute.stride<"((1@1,1@0),(256@1,64@0))">
      %c64_i32 = arith.constant 64 : i32
      %c256_i32 = arith.constant 256 : i32
      %14 = cute.static : !cute.int_tuple<"7">
      %15 = cute.static : !cute.int_tuple<"6">
      %16 = cute.static : !cute.int_tuple<"5">
      %17 = cute.static : !cute.int_tuple<"4">
      %18 = cute.static : !cute.int_tuple<"3">
      %19 = cute.static : !cute.int_tuple<"2">
      %20 = cute.static : !cute.int_tuple<"1">
      %c0_i32 = arith.constant 0 : i32
      %21 = cute.static : !cute.int_tuple<"114688">
      %c-128_i32 = arith.constant -128 : i32
      %c1_i32 = arith.constant 1 : i32
      %c128_i32 = arith.constant 128 : i32
      %22 = cute.static : !cute.int_tuple<"136">
      %23 = cute.static : !cute.int_tuple<"128">
      %24 = cute.static : !cute.int_tuple<"112">
      %25 = cute.static : !cute.int_tuple<"144">
      %c2_i32 = arith.constant 2 : i32
      %c32_i32 = arith.constant 32 : i32
      %26 = cute.static : !cute.layout<"((2),1,1,1):((1),0,0,0)">
      %27 = nvvm.read.ptx.sreg.tid.x range <i32, 0, 1024> : i32
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
      %43 = cute.get_flat_coord(%42, %26) : (i32, !cute.layout<"((2),1,1,1):((1),0,0,0)">) -> !cute.coord<"(?,0,0,0)">
      %e0, %e1, %e2, %e3 = cute.get_leaves(%43) : !cute.coord<"(?,0,0,0)">
      %itup = cute.to_int_tuple(%e0) : !cute.coord<"?"> to !cute.int_tuple<"?">
      %44 = arith.remsi %40, %c2_i32 : i32
      %45 = arith.floordivsi %40, %c2_i32 : i32
      %smem_ptr = cute_nvgpu.arch.get_dyn_smem() : !cute.ptr<i8, smem, align<1024>>
      %ptr = cute.add_offset(%smem_ptr, %25) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"144">) -> !cute.ptr<i8, smem, align<16>>
      %ptr_0 = cute.add_offset(%smem_ptr, %24) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"112">) -> !cute.ptr<i8, smem, align<16>>
      %ptr_1 = cute.add_offset(%smem_ptr, %23) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"128">) -> !cute.ptr<i8, smem, align<128>>
      %iter = cute.recast_iter(%ptr_1) : !cute.ptr<i8, smem, align<128>> to !cute.ptr<i64, smem, align<128>>
      %ptr_2 = cute.add_offset(%smem_ptr, %22) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"136">) -> !cute.ptr<i8, smem, align<8>>
      %iter_3 = cute.recast_iter(%ptr_2) : !cute.ptr<i8, smem, align<8>> to !cute.ptr<i32, smem, align<8>>
      %46 = cute.ptrtoint(%ptr) : !cute.ptr<i8, smem, align<16>> to i32
      %47 = arith.addi %46, %c127_i32 : i32
      %48 = arith.andi %47, %c-128_i32 : i32
      %49 = arith.extsi %48 : i32 to i64
      %iv = cute.assume(%49) : (i64) -> !cute.i64<divby 128>
      %50 = cute.inttoptr(%iv) : !cute.i64<divby 128> to !cute.ptr<i8, smem, align<128>>
      %ptr_4 = cute.add_offset(%50, %21) : (!cute.ptr<i8, smem, align<128>>, !cute.int_tuple<"114688">) -> !cute.ptr<i8, smem, align<128>>
      %iter_5 = cute.recast_iter(%50) : !cute.ptr<i8, smem, align<128>> to !cute.ptr<f16, smem, align<128>, S<3,4,3>>
      %iter_6 = cute.recast_iter(%ptr_4) : !cute.ptr<i8, smem, align<128>> to !cute.ptr<f16, smem, align<128>, S<3,4,3>>
      %51 = arith.cmpi eq, %39, %c0_i32 : i32
      scf.if %51 {
        cute_nvgpu.prefetch_tma_desc(%arg1) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_100_2sm_multicast, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, internal_val_type = f16>) -> ()
        cute_nvgpu.prefetch_tma_desc(%arg3) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_100_2sm_multicast, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, internal_val_type = f16>) -> ()
      }
      %iter_7 = cute.recast_iter(%smem_ptr) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<i64, smem, align<1024>>
      %52 = nvvm.read.ptx.sreg.tid.x range <i32, 0, 1024> : i32
      %53 = nvvm.read.ptx.sreg.tid.y range <i32, 0, 1024> : i32
      %54 = nvvm.read.ptx.sreg.tid.z range <i32, 0, 64> : i32
      %55 = nvvm.read.ptx.sreg.ntid.x range <i32, 1, 1024> : i32
      %56 = nvvm.read.ptx.sreg.ntid.y range <i32, 1, 1024> : i32
      %57 = arith.muli %53, %55 : i32
      %58 = arith.addi %52, %57 : i32
      %59 = arith.muli %54, %55 : i32
      %60 = arith.muli %59, %56 : i32
      %61 = arith.addi %58, %60 : i32
      %62 = arith.floordivsi %61, %c32_i32 : i32
      %63 = cute_nvgpu.arch.make_warp_uniform(%62) : i32
      %64 = arith.cmpi eq, %63, %c0_i32 : i32
      scf.if %64 {
        %248 = builtin.unrealized_conversion_cast %iter_7 : !cute.ptr<i64, smem, align<1024>> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %248, %c1_i32 : !llvm.ptr<3>, i32
        %ptr_100 = cute.add_offset(%iter_7, %20) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"1">) -> !cute.ptr<i64, smem>
        %249 = builtin.unrealized_conversion_cast %ptr_100 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %249, %c1_i32 : !llvm.ptr<3>, i32
        %ptr_101 = cute.add_offset(%iter_7, %19) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"2">) -> !cute.ptr<i64, smem, align<16>>
        %250 = builtin.unrealized_conversion_cast %ptr_101 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %250, %c1_i32 : !llvm.ptr<3>, i32
        %ptr_102 = cute.add_offset(%iter_7, %18) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"3">) -> !cute.ptr<i64, smem>
        %251 = builtin.unrealized_conversion_cast %ptr_102 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %251, %c1_i32 : !llvm.ptr<3>, i32
        %ptr_103 = cute.add_offset(%iter_7, %17) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"4">) -> !cute.ptr<i64, smem, align<32>>
        %252 = builtin.unrealized_conversion_cast %ptr_103 : !cute.ptr<i64, smem, align<32>> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %252, %c1_i32 : !llvm.ptr<3>, i32
        %ptr_104 = cute.add_offset(%iter_7, %16) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"5">) -> !cute.ptr<i64, smem>
        %253 = builtin.unrealized_conversion_cast %ptr_104 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %253, %c1_i32 : !llvm.ptr<3>, i32
        %ptr_105 = cute.add_offset(%iter_7, %15) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"6">) -> !cute.ptr<i64, smem, align<16>>
        %254 = builtin.unrealized_conversion_cast %ptr_105 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %254, %c1_i32 : !llvm.ptr<3>, i32
      }
      %ptr_8 = cute.add_offset(%iter_7, %14) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"7">) -> !cute.ptr<i64, smem>
      %65 = nvvm.read.ptx.sreg.tid.x range <i32, 0, 1024> : i32
      %66 = nvvm.read.ptx.sreg.tid.y range <i32, 0, 1024> : i32
      %67 = nvvm.read.ptx.sreg.tid.z range <i32, 0, 64> : i32
      %68 = nvvm.read.ptx.sreg.ntid.x range <i32, 1, 1024> : i32
      %69 = nvvm.read.ptx.sreg.ntid.y range <i32, 1, 1024> : i32
      %70 = arith.muli %66, %68 : i32
      %71 = arith.addi %65, %70 : i32
      %72 = arith.muli %67, %68 : i32
      %73 = arith.muli %72, %69 : i32
      %74 = arith.addi %71, %73 : i32
      %75 = arith.floordivsi %74, %c32_i32 : i32
      %76 = cute_nvgpu.arch.make_warp_uniform(%75) : i32
      %77 = arith.cmpi eq, %76, %c0_i32 : i32
      scf.if %77 {
        %248 = builtin.unrealized_conversion_cast %ptr_8 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %248, %c1_i32 : !llvm.ptr<3>, i32
        %int_tuple_100 = cute.make_int_tuple() : () -> !cute.int_tuple<"8">
        %ptr_101 = cute.add_offset(%iter_7, %int_tuple_100) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"8">) -> !cute.ptr<i64, smem, align<64>>
        %dyn_102 = cute.derefine(%ptr_101) : !cute.ptr<i64, smem, align<64>> to !cute.ptr<i64, smem>
        %249 = builtin.unrealized_conversion_cast %dyn_102 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %249, %c1_i32 : !llvm.ptr<3>, i32
        %int_tuple_103 = cute.make_int_tuple() : () -> !cute.int_tuple<"9">
        %ptr_104 = cute.add_offset(%iter_7, %int_tuple_103) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"9">) -> !cute.ptr<i64, smem>
        %250 = builtin.unrealized_conversion_cast %ptr_104 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %250, %c1_i32 : !llvm.ptr<3>, i32
        %int_tuple_105 = cute.make_int_tuple() : () -> !cute.int_tuple<"10">
        %ptr_106 = cute.add_offset(%iter_7, %int_tuple_105) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"10">) -> !cute.ptr<i64, smem, align<16>>
        %dyn_107 = cute.derefine(%ptr_106) : !cute.ptr<i64, smem, align<16>> to !cute.ptr<i64, smem>
        %251 = builtin.unrealized_conversion_cast %dyn_107 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %251, %c1_i32 : !llvm.ptr<3>, i32
        %int_tuple_108 = cute.make_int_tuple() : () -> !cute.int_tuple<"11">
        %ptr_109 = cute.add_offset(%iter_7, %int_tuple_108) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"11">) -> !cute.ptr<i64, smem>
        %252 = builtin.unrealized_conversion_cast %ptr_109 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %252, %c1_i32 : !llvm.ptr<3>, i32
        %int_tuple_110 = cute.make_int_tuple() : () -> !cute.int_tuple<"12">
        %ptr_111 = cute.add_offset(%iter_7, %int_tuple_110) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"12">) -> !cute.ptr<i64, smem, align<32>>
        %dyn_112 = cute.derefine(%ptr_111) : !cute.ptr<i64, smem, align<32>> to !cute.ptr<i64, smem>
        %253 = builtin.unrealized_conversion_cast %dyn_112 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %253, %c1_i32 : !llvm.ptr<3>, i32
        %int_tuple_113 = cute.make_int_tuple() : () -> !cute.int_tuple<"13">
        %ptr_114 = cute.add_offset(%iter_7, %int_tuple_113) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"13">) -> !cute.ptr<i64, smem>
        %254 = builtin.unrealized_conversion_cast %ptr_114 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %254, %c1_i32 : !llvm.ptr<3>, i32
      }
      %78 = nvvm.read.ptx.sreg.cluster.ctarank : i32
      %79 = cute_nvgpu.arch.make_warp_uniform(%78) : i32
      %80 = cute.get_flat_coord(%79, %26) : (i32, !cute.layout<"((2),1,1,1):((1),0,0,0)">) -> !cute.coord<"(?,0,0,0)">
      %e0_9, %e1_10, %e2_11, %e3_12 = cute.get_leaves(%80) : !cute.coord<"(?,0,0,0)">
      %itup_13 = cute.to_int_tuple(%e0_9) : !cute.coord<"?"> to !cute.int_tuple<"?">
      %81 = cute.get_scalars(%itup_13) : !cute.int_tuple<"?">
      %coord = cute.make_coord(%itup_13) : (!cute.int_tuple<"?">) -> !cute.coord<"(?,0,_,0)">
      %idx = cute.crd2idx(%coord, %26) : (!cute.coord<"(?,0,_,0)">, !cute.layout<"((2),1,1,1):((1),0,0,0)">) -> !cute.int_tuple<"?">
      %e0_14 = cute.get_leaves(%idx) : !cute.int_tuple<"?">
      %82 = cute.get_scalars(%e0_14) : !cute.int_tuple<"?">
      %83 = arith.shli %c1_i32, %82 : i32
      %84 = arith.trunci %83 : i32 to i16
      %coord_15 = cute.make_coord(%itup_13) : (!cute.int_tuple<"?">) -> !cute.coord<"(?,_,0,0)">
      %idx_16 = cute.crd2idx(%coord_15, %26) : (!cute.coord<"(?,_,0,0)">, !cute.layout<"((2),1,1,1):((1),0,0,0)">) -> !cute.int_tuple<"?">
      %e0_17 = cute.get_leaves(%idx_16) : !cute.int_tuple<"?">
      %85 = cute.get_scalars(%e0_17) : !cute.int_tuple<"?">
      %86 = arith.shli %c1_i32, %85 : i32
      %87 = arith.trunci %86 : i32 to i16
      %88 = arith.xori %81, %c1_i32 : i32
      %coord_18 = cute.make_coord(%88) : (i32) -> !cute.coord<"(?,0,_,0)">
      %idx_19 = cute.crd2idx(%coord_18, %26) : (!cute.coord<"(?,0,_,0)">, !cute.layout<"((2),1,1,1):((1),0,0,0)">) -> !cute.int_tuple<"?">
      %e0_20 = cute.get_leaves(%idx_19) : !cute.int_tuple<"?">
      %89 = cute.get_scalars(%e0_20) : !cute.int_tuple<"?">
      %90 = arith.shli %c1_i32, %89 : i32
      %91 = arith.trunci %90 : i32 to i16
      %coord_21 = cute.make_coord(%88) : (i32) -> !cute.coord<"(?,_,0,0)">
      %idx_22 = cute.crd2idx(%coord_21, %26) : (!cute.coord<"(?,_,0,0)">, !cute.layout<"((2),1,1,1):((1),0,0,0)">) -> !cute.int_tuple<"?">
      %e0_23 = cute.get_leaves(%idx_22) : !cute.int_tuple<"?">
      %92 = cute.get_scalars(%e0_23) : !cute.int_tuple<"?">
      %93 = arith.shli %c1_i32, %92 : i32
      %94 = arith.trunci %93 : i32 to i16
      %95 = arith.ori %84, %87 : i16
      %96 = arith.ori %95, %91 : i16
      %97 = arith.ori %96, %94 : i16
      %98 = nvvm.read.ptx.sreg.ctaid.x range <i32, 0, 2147483647> : i32
      %99 = arith.remsi %98, %c2_i32 : i32
      %100 = arith.cmpi eq, %99, %c0_i32 : i32
      nvvm.fence.mbarrier.init
      nvvm.cluster.arrive.relaxed
      nvvm.cluster.wait
      %iter_24 = cute.recast_iter(%ptr_0) : !cute.ptr<i8, smem, align<16>> to !cute.ptr<i64, smem, align<16>>
      %101 = nvvm.read.ptx.sreg.tid.x range <i32, 0, 1024> : i32
      %102 = nvvm.read.ptx.sreg.tid.y range <i32, 0, 1024> : i32
      %103 = nvvm.read.ptx.sreg.tid.z range <i32, 0, 64> : i32
      %104 = nvvm.read.ptx.sreg.ntid.x range <i32, 1, 1024> : i32
      %105 = nvvm.read.ptx.sreg.ntid.y range <i32, 1, 1024> : i32
      %106 = arith.muli %102, %104 : i32
      %107 = arith.addi %101, %106 : i32
      %108 = arith.muli %103, %104 : i32
      %109 = arith.muli %108, %105 : i32
      %110 = arith.addi %107, %109 : i32
      %111 = arith.floordivsi %110, %c32_i32 : i32
      %112 = cute_nvgpu.arch.make_warp_uniform(%111) : i32
      %113 = arith.cmpi eq, %112, %c0_i32 : i32
      scf.if %113 {
        %248 = builtin.unrealized_conversion_cast %iter_24 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %248, %c1_i32 : !llvm.ptr<3>, i32
      }
      %ptr_25 = cute.add_offset(%iter_24, %20) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"1">) -> !cute.ptr<i64, smem>
      %114 = nvvm.read.ptx.sreg.tid.x range <i32, 0, 1024> : i32
      %115 = nvvm.read.ptx.sreg.tid.y range <i32, 0, 1024> : i32
      %116 = nvvm.read.ptx.sreg.tid.z range <i32, 0, 64> : i32
      %117 = nvvm.read.ptx.sreg.ntid.x range <i32, 1, 1024> : i32
      %118 = nvvm.read.ptx.sreg.ntid.y range <i32, 1, 1024> : i32
      %119 = arith.muli %115, %117 : i32
      %120 = arith.addi %114, %119 : i32
      %121 = arith.muli %116, %117 : i32
      %122 = arith.muli %121, %118 : i32
      %123 = arith.addi %120, %122 : i32
      %124 = arith.floordivsi %123, %c32_i32 : i32
      %125 = cute_nvgpu.arch.make_warp_uniform(%124) : i32
      %126 = arith.cmpi eq, %125, %c0_i32 : i32
      scf.if %126 {
        %248 = builtin.unrealized_conversion_cast %ptr_25 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %248, %c256_i32 : !llvm.ptr<3>, i32
      }
      %127 = nvvm.read.ptx.sreg.cluster.ctarank : i32
      %128 = cute_nvgpu.arch.make_warp_uniform(%127) : i32
      %129 = arith.floordivsi %128, %c2_i32 : i32
      %130 = arith.muli %129, %c2_i32 : i32
      nvvm.fence.mbarrier.init
      nvvm.cluster.arrive.relaxed
      nvvm.cluster.wait
      %coord_26 = cute.make_coord(%45, %41) : (i32, i32) -> !cute.coord<"(?,?,_)">
      %131:2 = cute.get_scalars(%coord_26) <{only_dynamic}> : !cute.coord<"(?,?,_)">
      %coord_27 = cute.make_coord(%131#0) : (i32) -> !cute.coord<"((_,_),(?,_))">
      %lay = cute.get_layout(%arg2) : !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">
      %132:2 = cute.get_scalars(%lay) <{only_dynamic}> : !cute.layout<"(?,?{div=8192}):(1@1,1@0)">
      %133 = arith.ceildivsi %132#0, %c256_i32 : i32
      %134 = arith.ceildivsi %132#1, %c64_i32 : i32
      %shape = cute.make_shape(%133, %134) : (i32, i32) -> !cute.shape<"((256,64),(?,?))">
      %lay_28 = cute.make_layout(%shape, %13) : !cute.layout<"((256,64),(?,?)):((1@1,1@0),(256@1,64@0))">
      %135:2 = cute.get_scalars(%lay_28) <{only_dynamic}> : !cute.layout<"((256,64),(?,?)):((1@1,1@0),(256@1,64@0))">
      %shape_29 = cute.make_shape(%135#1) : (i32) -> !cute.shape<"(256,64,?)">
      %lay_30 = cute.make_layout(%shape_29, %12) : !cute.layout<"(256,64,?):(1@1,1@0,64@0)">
      %idx_31 = cute.crd2idx(%coord_27, %lay_28) : (!cute.coord<"((_,_),(?,_))">, !cute.layout<"((256,64),(?,?)):((1@1,1@0),(256@1,64@0))">) -> !cute.int_tuple<"(0,?{div=256})">
      %tup = cute.add_offset(%11, %idx_31) : (!cute.int_tuple<"(0,0)">, !cute.int_tuple<"(0,?{div=256})">) -> !cute.int_tuple<"(0,?{div=256})">
      %coord_32 = cute.make_coord(%45, %41) : (i32, i32) -> !cute.coord<"(?,?,_)">
      %136:2 = cute.get_scalars(%coord_32) <{only_dynamic}> : !cute.coord<"(?,?,_)">
      %coord_33 = cute.make_coord(%136#1) : (i32) -> !cute.coord<"((_,_),(?,_))">
      %lay_34 = cute.get_layout(%arg4) : !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">
      %137:2 = cute.get_scalars(%lay_34) <{only_dynamic}> : !cute.layout<"(?,?{div=8192}):(1@1,1@0)">
      %138 = arith.ceildivsi %137#0, %c256_i32 : i32
      %139 = arith.ceildivsi %137#1, %c64_i32 : i32
      %shape_35 = cute.make_shape(%138, %139) : (i32, i32) -> !cute.shape<"((256,64),(?,?))">
      %lay_36 = cute.make_layout(%shape_35, %13) : !cute.layout<"((256,64),(?,?)):((1@1,1@0),(256@1,64@0))">
      %140:2 = cute.get_scalars(%lay_36) <{only_dynamic}> : !cute.layout<"((256,64),(?,?)):((1@1,1@0),(256@1,64@0))">
      %shape_37 = cute.make_shape(%140#1) : (i32) -> !cute.shape<"(256,64,?)">
      %lay_38 = cute.make_layout(%shape_37, %12) : !cute.layout<"(256,64,?):(1@1,1@0,64@0)">
      %idx_39 = cute.crd2idx(%coord_33, %lay_36) : (!cute.coord<"((_,_),(?,_))">, !cute.layout<"((256,64),(?,?)):((1@1,1@0),(256@1,64@0))">) -> !cute.int_tuple<"(0,?{div=256})">
      %tup_40 = cute.add_offset(%11, %idx_39) : (!cute.int_tuple<"(0,0)">, !cute.int_tuple<"(0,?{div=256})">) -> !cute.int_tuple<"(0,?{div=256})">
      %coord_41 = cute.make_coord(%45, %41) : (i32, i32) -> !cute.coord<"(?,?,_)">
      %141:2 = cute.get_scalars(%coord_41) <{only_dynamic}> : !cute.coord<"(?,?,_)">
      %coord_42 = cute.make_coord(%141#0, %141#1) : (i32, i32) -> !cute.coord<"((_,_),(?,?))">
      %lay_43 = cute.get_layout(%arg5) : !memref_gmem_f16_
      %142:3 = cute.get_scalars(%lay_43) <{only_dynamic}> : !cute.layout<"(?,?{div=8192}):(?{i64 div=8192},1)">
      %143 = arith.ceildivsi %142#0, %c256_i32 : i32
      %144 = arith.muli %142#2, %c256_i64 : i64
      %145 = arith.ceildivsi %142#1, %c256_i32 : i32
      %shape_44 = cute.make_shape(%143, %145) : (i32, i32) -> !cute.shape<"((256,256),(?,?))">
      %iv_45 = cute.assume(%142#2) : (i64) -> !cute.i64<divby 8192>
      %iv_46 = cute.assume(%144) : (i64) -> !cute.i64<divby 2097152>
      %stride = cute.make_stride(%iv_45, %iv_46) : (!cute.i64<divby 8192>, !cute.i64<divby 2097152>) -> !cute.stride<"((?{i64 div=8192},1),(?{i64 div=2097152},256))">
      %lay_47 = cute.make_layout(%shape_44, %stride) : !cute.layout<"((256,256),(?,?)):((?{i64 div=8192},1),(?{i64 div=2097152},256))">
      %146:4 = cute.get_scalars(%lay_47) <{only_dynamic}> : !cute.layout<"((256,256),(?,?)):((?{i64 div=8192},1),(?{i64 div=2097152},256))">
      %iv_48 = cute.assume(%146#2) : (i64) -> !cute.i64<divby 8192>
      %stride_49 = cute.make_stride(%iv_48) : (!cute.i64<divby 8192>) -> !cute.stride<"(?{i64 div=8192},1)">
      %lay_50 = cute.make_layout(%10, %stride_49) : !cute.layout<"(256,256):(?{i64 div=8192},1)">
      %idx_51 = cute.crd2idx(%coord_42, %lay_47) : (!cute.coord<"((_,_),(?,?))">, !cute.layout<"((256,256),(?,?)):((?{i64 div=8192},1),(?{i64 div=2097152},256))">) -> !cute.int_tuple<"?{i64 div=256}">
      %iter_52 = cute.get_iter(%arg5) : !memref_gmem_f16_
      %ptr_53 = cute.add_offset(%iter_52, %idx_51) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{i64 div=256}">) -> !cute.ptr<f16, gmem, align<32>>
      %coord_54 = cute.make_coord(%44) : (i32) -> !cute.coord<"?">
      %147 = cute.get_scalars(%lay_30) <{only_dynamic}> : !cute.layout<"(256,64,?):(1@1,1@0,64@0)">
      %148 = cute.get_scalars(%coord_54) <{only_dynamic}> : !cute.coord<"?">
      %149 = arith.remsi %148, %c2_i32 : i32
      %150 = arith.remsi %149, %c2_i32 : i32
      %151 = arith.muli %150, %c128_i32 : i32
      %iv_55 = cute.assume(%151) : (i32) -> !cute.i32<divby 128>
      %int_tuple = cute.make_int_tuple(%iv_55) : (!cute.i32<divby 128>) -> !cute.int_tuple<"(0,?{div=128})">
      %tup_56 = cute.add_offset(%tup, %int_tuple) : (!cute.int_tuple<"(0,?{div=256})">, !cute.int_tuple<"(0,?{div=128})">) -> !cute.int_tuple<"(0,?{div=128})">
      %shape_57 = cute.make_shape(%147) : (i32) -> !cute.shape<"((128,16),1,4,?)">
      %lay_58 = cute.make_layout(%shape_57, %9) : !cute.layout<"((128,16),1,4,?):((1@1,1@0),0,16@0,64@0)">
      %coord_59 = cute.make_coord(%44) : (i32) -> !cute.coord<"?">
      %152 = cute.get_scalars(%lay_38) <{only_dynamic}> : !cute.layout<"(256,64,?):(1@1,1@0,64@0)">
      %153 = cute.get_scalars(%coord_59) <{only_dynamic}> : !cute.coord<"?">
      %154 = arith.remsi %153, %c2_i32 : i32
      %155 = arith.remsi %154, %c2_i32 : i32
      %156 = arith.muli %155, %c128_i32 : i32
      %iv_60 = cute.assume(%156) : (i32) -> !cute.i32<divby 128>
      %int_tuple_61 = cute.make_int_tuple(%iv_60) : (!cute.i32<divby 128>) -> !cute.int_tuple<"(0,?{div=128})">
      %tup_62 = cute.add_offset(%tup_40, %int_tuple_61) : (!cute.int_tuple<"(0,?{div=256})">, !cute.int_tuple<"(0,?{div=128})">) -> !cute.int_tuple<"(0,?{div=128})">
      %shape_63 = cute.make_shape(%152) : (i32) -> !cute.shape<"((128,16),1,4,?)">
      %lay_64 = cute.make_layout(%shape_63, %9) : !cute.layout<"((128,16),1,4,?):((1@1,1@0),0,16@0,64@0)">
      %coord_65 = cute.make_coord(%44) : (i32) -> !cute.coord<"?">
      %157 = cute.get_scalars(%lay_50) <{only_dynamic}> : !cute.layout<"(256,256):(?{i64 div=8192},1)">
      %158 = cute.get_scalars(%coord_65) <{only_dynamic}> : !cute.coord<"?">
      %159 = arith.muli %157, %c128_i64 : i64
      %160 = arith.remsi %158, %c2_i32 : i32
      %161 = arith.remsi %160, %c2_i32 : i32
      %162 = arith.extsi %161 : i32 to i64
      %163 = arith.muli %162, %159 : i64
      %iv_66 = cute.assume(%163) : (i64) -> !cute.i64<divby 1048576>
      %int_tuple_67 = cute.make_int_tuple(%iv_66) : (!cute.i64<divby 1048576>) -> !cute.int_tuple<"?{i64 div=1048576}">
      %ptr_68 = cute.add_offset(%ptr_53, %int_tuple_67) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{i64 div=1048576}">) -> !cute.ptr<f16, gmem, align<32>>
      %iv_69 = cute.assume(%157) : (i64) -> !cute.i64<divby 8192>
      %stride_70 = cute.make_stride(%iv_69) : (!cute.i64<divby 8192>) -> !cute.stride<"((?{i64 div=8192},1),0,0)">
      %lay_71 = cute.make_layout(%8, %stride_70) : !cute.layout<"((128,256),1,1):((?{i64 div=8192},1),0,0)">
      %ummaSmemDesc = cute_nvgpu.make_umma_smem_desc(%iter_5 : !cute.ptr<f16, smem, align<128>, S<3,4,3>>) layout = <"((128,16),1,4,7):((64,1),0,16,8192)">, major = <k> -> !cute_nvgpu.smem_desc
      %ummaSmemDesc_72 = cute_nvgpu.make_umma_smem_desc(%iter_6 : !cute.ptr<f16, smem, align<128>, S<3,4,3>>) layout = <"((128,16),1,4,7):((64,1),0,16,8192)">, major = <k> -> !cute_nvgpu.smem_desc
      %164 = cute.get_scalars(%lay_58) <{only_dynamic}> : !cute.layout<"((128,16),1,4,?):((1@1,1@0),0,16@0,64@0)">
      %shape_73 = cute.make_shape(%164) : (i32) -> !cute.shape<"(((128,16),1,4),?)">
      %lay_74 = cute.make_layout(%shape_73, %7) : !cute.layout<"(((128,16),1,4),?):(((1@1,1@0),0,16@0),64@0)">
      %165 = cute.get_scalars(%lay_74) <{only_dynamic}> : !cute.layout<"(((128,16),1,4),?):(((1@1,1@0),0,16@0),64@0)">
      %shape_75 = cute.make_shape(%165) : (i32) -> !cute.shape<"(((64,128),1),?)">
      %lay_76 = cute.make_layout(%shape_75, %6) : !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">
      %166 = cute.get_scalars(%lay_64) <{only_dynamic}> : !cute.layout<"((128,16),1,4,?):((1@1,1@0),0,16@0,64@0)">
      %shape_77 = cute.make_shape(%166) : (i32) -> !cute.shape<"(((128,16),1,4),?)">
      %lay_78 = cute.make_layout(%shape_77, %7) : !cute.layout<"(((128,16),1,4),?):(((1@1,1@0),0,16@0),64@0)">
      %167 = cute.get_scalars(%lay_78) <{only_dynamic}> : !cute.layout<"(((128,16),1,4),?):(((1@1,1@0),0,16@0),64@0)">
      %shape_79 = cute.make_shape(%167) : (i32) -> !cute.shape<"(((64,128),1),?)">
      %lay_80 = cute.make_layout(%shape_79, %6) : !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">
      %coord_81 = cute.make_coord(%itup) : (!cute.int_tuple<"?">) -> !cute.coord<"(?,0,_,0)">
      %idx_82 = cute.crd2idx(%coord_81, %26) : (!cute.coord<"(?,0,_,0)">, !cute.layout<"((2),1,1,1):((1),0,0,0)">) -> !cute.int_tuple<"?">
      %e0_83 = cute.get_leaves(%idx_82) : !cute.int_tuple<"?">
      %168 = cute.get_scalars(%e0_83) : !cute.int_tuple<"?">
      %169 = arith.shli %c1_i32, %168 : i32
      %170 = arith.trunci %169 : i32 to i16
      %coord_84 = cute.make_coord(%itup) : (!cute.int_tuple<"?">) -> !cute.coord<"(?,_,0,0)">
      %idx_85 = cute.crd2idx(%coord_84, %26) : (!cute.coord<"(?,_,0,0)">, !cute.layout<"((2),1,1,1):((1),0,0,0)">) -> !cute.int_tuple<"?">
      %e0_86 = cute.get_leaves(%idx_85) : !cute.int_tuple<"?">
      %171 = cute.get_scalars(%e0_86) : !cute.int_tuple<"?">
      %172 = arith.shli %c1_i32, %171 : i32
      %173 = arith.trunci %172 : i32 to i16
      %174 = nvvm.read.ptx.sreg.tid.x range <i32, 0, 1024> : i32
      %175 = nvvm.read.ptx.sreg.tid.y range <i32, 0, 1024> : i32
      %176 = nvvm.read.ptx.sreg.tid.z range <i32, 0, 64> : i32
      %177 = nvvm.read.ptx.sreg.ntid.x range <i32, 1, 1024> : i32
      %178 = nvvm.read.ptx.sreg.ntid.y range <i32, 1, 1024> : i32
      %179 = arith.muli %175, %177 : i32
      %180 = arith.addi %174, %179 : i32
      %181 = arith.muli %176, %177 : i32
      %182 = arith.muli %181, %178 : i32
      %183 = arith.addi %180, %182 : i32
      %184 = arith.floordivsi %183, %c32_i32 : i32
      %185 = cute_nvgpu.arch.make_warp_uniform(%184) : i32
      %186 = arith.cmpi eq, %185, %c0_i32 : i32
      scf.if %186 {
        %248 = nvvm.elect.sync -> i1
        scf.if %248 {
          %249 = builtin.unrealized_conversion_cast %iter : !cute.ptr<i64, smem, align<128>> to !llvm.ptr<3>
          nvvm.mbarrier.init.shared %249, %c32_i32 : !llvm.ptr<3>, i32
        }
      }
      nvvm.fence.mbarrier.init
      %187 = nvvm.read.ptx.sreg.tid.x range <i32, 0, 1024> : i32
      %188 = nvvm.read.ptx.sreg.tid.y range <i32, 0, 1024> : i32
      %189 = nvvm.read.ptx.sreg.tid.z range <i32, 0, 64> : i32
      %190 = nvvm.read.ptx.sreg.ntid.x range <i32, 1, 1024> : i32
      %191 = nvvm.read.ptx.sreg.ntid.y range <i32, 1, 1024> : i32
      %192 = arith.muli %188, %190 : i32
      %193 = arith.addi %187, %192 : i32
      %194 = arith.muli %189, %190 : i32
      %195 = arith.muli %194, %191 : i32
      %196 = arith.addi %193, %195 : i32
      %197 = arith.floordivsi %196, %c32_i32 : i32
      %198 = cute_nvgpu.arch.make_warp_uniform(%197) : i32
      %199 = arith.cmpi eq, %198, %c0_i32 : i32
      scf.if %199 {
        cute_nvgpu.arch.sm100.alloc_tmem(%c512_i32, %iter_3) [cta_2] : i32, !cute.ptr<i32, smem, align<8>>
      }
      nvvm.barrier id = %c1_i32 number_of_threads = %c128_i32
      %tmem_ptr = cute_nvgpu.arch.sm100.retrieve_tmem_ptr(%iter_3) : !cute.ptr<i32, smem, align<8>> -> !cute.ptr<f32, tmem, align<16>>
      %200 = cute.get_scalars(%lay_71) <{only_dynamic}> : !cute.layout<"((128,256),1,1):((?{i64 div=8192},1),0,0)">
      %iv_87 = cute.assume(%200) : (i64) -> !cute.i64<divby 8192>
      %stride_88 = cute.make_stride(%iv_87) : (!cute.i64<divby 8192>) -> !cute.stride<"(((?{i64 div=8192},1)),((0,64),0,0))">
      %lay_89 = cute.make_layout(%5, %stride_88) : !cute.layout<"(((128,64)),((1,4),1,1)):(((?{i64 div=8192},1)),((0,64),0,0))">
      %coord_90 = cute.make_coord(%27) : (i32) -> !cute.coord<"?">
      %201 = cute.get_scalars(%coord_90) <{only_dynamic}> : !cute.coord<"?">
      %202 = arith.divsi %201, %c32_i32 : i32
      %203 = arith.muli %202, %c2097152_i32 : i32
      %iv_91 = cute.assume(%203) : (i32) -> !cute.i32<divby 2097152>
      %int_tuple_92 = cute.make_int_tuple(%iv_91) : (!cute.i32<divby 2097152>) -> !cute.int_tuple<"?{div=2097152}">
      %ptr_93 = cute.add_offset(%tmem_ptr, %int_tuple_92) : (!cute.ptr<f32, tmem, align<16>>, !cute.int_tuple<"?{div=2097152}">) -> !cute.ptr<f32, tmem, align<16>>
      %coord_94 = cute.make_coord(%27) : (i32) -> !cute.coord<"?">
      %204 = cute.get_scalars(%lay_89) <{only_dynamic}> : !cute.layout<"(((128,64)),((1,4),1,1)):(((?{i64 div=8192},1)),((0,64),0,0))">
      %205 = cute.get_scalars(%coord_94) <{only_dynamic}> : !cute.coord<"?">
      %206 = arith.muli %204, %c32_i64 : i64
      %207 = arith.divsi %205, %c32_i32 : i32
      %208 = arith.remsi %205, %c32_i32 : i32
      %209 = arith.extsi %208 : i32 to i64
      %210 = arith.muli %209, %204 : i64
      %211 = arith.extsi %207 : i32 to i64
      %212 = arith.muli %211, %206 : i64
      %213 = arith.addi %210, %212 : i64
      %iv_95 = cute.assume(%213) : (i64) -> !cute.i64<divby 8192>
      %int_tuple_96 = cute.make_int_tuple(%iv_95) : (!cute.i64<divby 8192>) -> !cute.int_tuple<"?{i64 div=8192}">
      %ptr_97 = cute.add_offset(%ptr_68, %int_tuple_96) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{i64 div=8192}">) -> !cute.ptr<f16, gmem, align<32>>
      %rmem = cute.memref.alloca() : !memref_rmem_f32_
      %rmem_98 = cute.memref.alloca() : !memref_rmem_f16_
      %214 = arith.cmpi eq, %44, %c0_i32 : i32
      %sz = cute.size(%lay_30) <{mode = [2]}> : (!cute.layout<"(256,64,?):(1@1,1@0,64@0)">) -> !cute.int_tuple<"?">
      %e0_99 = cute.get_leaves(%sz) : !cute.int_tuple<"?">
      %215 = cute.get_scalars(%e0_99) : !cute.int_tuple<"?">
      %216 = arith.cmpi eq, %39, %c0_i32 : i32
      %217:3 = scf.if %216 -> (i32, i32, i32) {
        %248 = arith.cmpi ne, %44, %c0_i32 : i32
        %249 = arith.extui %248 : i1 to i32
        scf.if %214 {
          %257 = builtin.unrealized_conversion_cast %ptr_25 : !cute.ptr<i64, smem> to !llvm.ptr<3>
          nvvm.mbarrier.try_wait.parity.shared %257, %c1_i32, %c10000000_i32 : !llvm.ptr<3>, i32, i32
        }
        %250 = cute_nvgpu.atom.make_exec_tma(%arg1) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_100_2sm_multicast, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>
        %251 = cute_nvgpu.atom.set_value(%250, %170 : i16) {field = #cute_nvgpu.atom_copy_field_tmaload<mcast_mask>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>
        %252 = cute_nvgpu.atom.make_exec_tma(%arg3) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_100_2sm_multicast, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>
        %253 = cute_nvgpu.atom.set_value(%252, %173 : i16) {field = #cute_nvgpu.atom_copy_field_tmaload<mcast_mask>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>
        %254 = arith.minsi %215, %c5_i32 : i32
        %255:3 = scf.for %arg6 = %c0_i32 to %254 step %c1_i32 iter_args(%arg7 = %c0_i32, %arg8 = %c1_i32, %arg9 = %c0_i32) -> (i32, i32, i32)  : i32 {
          %int_tuple_100 = cute.make_int_tuple(%arg7) : (i32) -> !cute.int_tuple<"?">
          %ptr_101 = cute.add_offset(%ptr_8, %int_tuple_100) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
          %257 = builtin.unrealized_conversion_cast %ptr_101 : !cute.ptr<i64, smem> to !llvm.ptr<3>
          nvvm.mbarrier.try_wait.parity.shared %257, %arg8, %c10000000_i32 : !llvm.ptr<3>, i32, i32
          scf.if %100 {
            %267 = nvvm.elect.sync -> i1
            scf.if %267 {
              %int_tuple_120 = cute.make_int_tuple(%arg7) : (i32) -> !cute.int_tuple<"?">
              %ptr_121 = cute.add_offset(%iter_7, %int_tuple_120) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
              %268 = builtin.unrealized_conversion_cast %ptr_121 : !cute.ptr<i64, smem> to !llvm.ptr<3>
              nvvm.mbarrier.txn %268, %c65536_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
            }
          }
          %258 = arith.addi %arg7, %c1_i32 : i32
          %259 = arith.addi %arg9, %c1_i32 : i32
          %260 = arith.cmpi eq, %258, %c7_i32 : i32
          %261 = arith.select %260, %c0_i32, %258 : i32
          %262 = scf.if %260 -> (i32) {
            %267 = arith.xori %arg8, %c1_i32 : i32
            scf.yield %267 : i32
          } else {
            scf.yield %arg8 : i32
          }
          %coord_102 = cute.make_coord(%arg9) : (i32) -> !cute.coord<"(_,?)">
          %idx_103 = cute.crd2idx(%coord_102, %lay_76) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
          %tup_104 = cute.add_offset(%tup_56, %idx_103) : (!cute.int_tuple<"(0,?{div=128})">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
          %e0_105, %e1_106 = cute.get_leaves(%tup_104) : !cute.int_tuple<"(?{div=64},?{div=128})">
          %coord_107 = cute.make_coord(%arg7) : (i32) -> !cute.coord<"(_,?)">
          %idx_108 = cute.crd2idx(%coord_107, %4) : (!cute.coord<"(_,?)">, !cute.layout<"((8192,1),7):((1,0),8192)">) -> !cute.int_tuple<"?{div=8192}">
          %ptr_109 = cute.add_offset(%iter_5, %idx_108) : (!cute.ptr<f16, smem, align<128>, S<3,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<f16, smem, align<128>, S<3,4,3>>
          %int_tuple_110 = cute.make_int_tuple(%arg7) : (i32) -> !cute.int_tuple<"?">
          %ptr_111 = cute.add_offset(%iter_7, %int_tuple_110) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
          %int_tuple_112 = cute.make_int_tuple(%e0_105, %e1_106) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=128}">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
          %263 = cute_nvgpu.atom.set_value(%251, %ptr_111 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>
          %264 = cute.get_scalars(%20) : !cute.int_tuple<"1">
          scf.for %arg10 = %c0_i32 to %264 step %c1_i32  : i32 {
            %267 = cute_nvgpu.atom.get_value(%263 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
            %268 = cute_nvgpu.atom.get_value(%263 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<mcast_mask>} : i16
            %269 = cute_nvgpu.atom.get_value(%263 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<cache_policy>} : i64
            %TMADescAddr = cute_nvgpu.get_tma_desc_addr(%263 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) -> !cute.ptr<generic, align<64>>
            %270:2 = cute.get_scalars(%int_tuple_112) : !cute.int_tuple<"(?{div=64},?{div=128})">
            cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr : !cute.ptr<generic, align<64>>, %ptr_109 : !cute.ptr<f16, smem, align<128>, S<3,4,3>>, %267 : !cute.ptr<smem, align<8>>, [%270#0, %270#1] : i32, i32) mask = %268 cache_policy = %269 mode = <tiled> num_cta = 2 : i32
          } {llvm.loop_annotation = #loop_annotation}
          %idx_113 = cute.crd2idx(%coord_102, %lay_80) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
          %tup_114 = cute.add_offset(%tup_62, %idx_113) : (!cute.int_tuple<"(0,?{div=128})">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
          %e0_115, %e1_116 = cute.get_leaves(%tup_114) : !cute.int_tuple<"(?{div=64},?{div=128})">
          %idx_117 = cute.crd2idx(%coord_107, %4) : (!cute.coord<"(_,?)">, !cute.layout<"((8192,1),7):((1,0),8192)">) -> !cute.int_tuple<"?{div=8192}">
          %ptr_118 = cute.add_offset(%iter_6, %idx_117) : (!cute.ptr<f16, smem, align<128>, S<3,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<f16, smem, align<128>, S<3,4,3>>
          %int_tuple_119 = cute.make_int_tuple(%e0_115, %e1_116) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=128}">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
          %265 = cute_nvgpu.atom.set_value(%253, %ptr_111 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>
          %266 = cute.get_scalars(%20) : !cute.int_tuple<"1">
          scf.for %arg10 = %c0_i32 to %266 step %c1_i32  : i32 {
            %267 = cute_nvgpu.atom.get_value(%265 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
            %268 = cute_nvgpu.atom.get_value(%265 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<mcast_mask>} : i16
            %269 = cute_nvgpu.atom.get_value(%265 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<cache_policy>} : i64
            %TMADescAddr = cute_nvgpu.get_tma_desc_addr(%265 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) -> !cute.ptr<generic, align<64>>
            %270:2 = cute.get_scalars(%int_tuple_119) : !cute.int_tuple<"(?{div=64},?{div=128})">
            cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr : !cute.ptr<generic, align<64>>, %ptr_118 : !cute.ptr<f16, smem, align<128>, S<3,4,3>>, %267 : !cute.ptr<smem, align<8>>, [%270#0, %270#1] : i32, i32) mask = %268 cache_policy = %269 mode = <tiled> num_cta = 2 : i32
          } {llvm.loop_annotation = #loop_annotation}
          scf.yield %261, %262, %259 : i32, i32, i32
        }
        %256:7 = scf.for %arg6 = %c0_i32 to %215 step %c1_i32 iter_args(%arg7 = %255#2, %arg8 = %255#0, %arg9 = %255#1, %arg10 = %c0_i32, %arg11 = %c0_i32, %arg12 = %c0_i32, %arg13 = %arg0) -> (i32, i32, i32, i32, i32, i32, !mma_f16_f16_f32_256x256x16_)  : i32 {
          %257 = arith.addi %arg6, %254 : i32
          %258 = arith.cmpi ult, %257, %215 : i32
          %259:3 = scf.if %258 -> (i32, i32, i32) {
            %int_tuple_100 = cute.make_int_tuple(%arg8) : (i32) -> !cute.int_tuple<"?">
            %ptr_101 = cute.add_offset(%ptr_8, %int_tuple_100) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
            %261 = builtin.unrealized_conversion_cast %ptr_101 : !cute.ptr<i64, smem> to !llvm.ptr<3>
            nvvm.mbarrier.try_wait.parity.shared %261, %arg9, %c10000000_i32 : !llvm.ptr<3>, i32, i32
            scf.if %100 {
              %271 = nvvm.elect.sync -> i1
              scf.if %271 {
                %int_tuple_120 = cute.make_int_tuple(%arg8) : (i32) -> !cute.int_tuple<"?">
                %ptr_121 = cute.add_offset(%iter_7, %int_tuple_120) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
                %272 = builtin.unrealized_conversion_cast %ptr_121 : !cute.ptr<i64, smem> to !llvm.ptr<3>
                nvvm.mbarrier.txn %272, %c65536_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
              }
            }
            %262 = arith.addi %arg8, %c1_i32 : i32
            %263 = arith.addi %arg7, %c1_i32 : i32
            %264 = arith.cmpi eq, %262, %c7_i32 : i32
            %265 = arith.select %264, %c0_i32, %262 : i32
            %266 = scf.if %264 -> (i32) {
              %271 = arith.xori %arg9, %c1_i32 : i32
              scf.yield %271 : i32
            } else {
              scf.yield %arg9 : i32
            }
            %coord_102 = cute.make_coord(%arg7) : (i32) -> !cute.coord<"(_,?)">
            %idx_103 = cute.crd2idx(%coord_102, %lay_76) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
            %tup_104 = cute.add_offset(%tup_56, %idx_103) : (!cute.int_tuple<"(0,?{div=128})">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
            %e0_105, %e1_106 = cute.get_leaves(%tup_104) : !cute.int_tuple<"(?{div=64},?{div=128})">
            %coord_107 = cute.make_coord(%arg8) : (i32) -> !cute.coord<"(_,?)">
            %idx_108 = cute.crd2idx(%coord_107, %4) : (!cute.coord<"(_,?)">, !cute.layout<"((8192,1),7):((1,0),8192)">) -> !cute.int_tuple<"?{div=8192}">
            %ptr_109 = cute.add_offset(%iter_5, %idx_108) : (!cute.ptr<f16, smem, align<128>, S<3,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<f16, smem, align<128>, S<3,4,3>>
            %int_tuple_110 = cute.make_int_tuple(%arg8) : (i32) -> !cute.int_tuple<"?">
            %ptr_111 = cute.add_offset(%iter_7, %int_tuple_110) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
            %int_tuple_112 = cute.make_int_tuple(%e0_105, %e1_106) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=128}">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
            %267 = cute_nvgpu.atom.set_value(%251, %ptr_111 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>
            %268 = cute.get_scalars(%20) : !cute.int_tuple<"1">
            scf.for %arg14 = %c0_i32 to %268 step %c1_i32  : i32 {
              %271 = cute_nvgpu.atom.get_value(%267 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
              %272 = cute_nvgpu.atom.get_value(%267 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<mcast_mask>} : i16
              %273 = cute_nvgpu.atom.get_value(%267 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<cache_policy>} : i64
              %TMADescAddr = cute_nvgpu.get_tma_desc_addr(%267 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) -> !cute.ptr<generic, align<64>>
              %274:2 = cute.get_scalars(%int_tuple_112) : !cute.int_tuple<"(?{div=64},?{div=128})">
              cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr : !cute.ptr<generic, align<64>>, %ptr_109 : !cute.ptr<f16, smem, align<128>, S<3,4,3>>, %271 : !cute.ptr<smem, align<8>>, [%274#0, %274#1] : i32, i32) mask = %272 cache_policy = %273 mode = <tiled> num_cta = 2 : i32
            } {llvm.loop_annotation = #loop_annotation}
            %idx_113 = cute.crd2idx(%coord_102, %lay_80) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
            %tup_114 = cute.add_offset(%tup_62, %idx_113) : (!cute.int_tuple<"(0,?{div=128})">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
            %e0_115, %e1_116 = cute.get_leaves(%tup_114) : !cute.int_tuple<"(?{div=64},?{div=128})">
            %idx_117 = cute.crd2idx(%coord_107, %4) : (!cute.coord<"(_,?)">, !cute.layout<"((8192,1),7):((1,0),8192)">) -> !cute.int_tuple<"?{div=8192}">
            %ptr_118 = cute.add_offset(%iter_6, %idx_117) : (!cute.ptr<f16, smem, align<128>, S<3,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<f16, smem, align<128>, S<3,4,3>>
            %int_tuple_119 = cute.make_int_tuple(%e0_115, %e1_116) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=128}">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
            %269 = cute_nvgpu.atom.set_value(%253, %ptr_111 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>
            %270 = cute.get_scalars(%20) : !cute.int_tuple<"1">
            scf.for %arg14 = %c0_i32 to %270 step %c1_i32  : i32 {
              %271 = cute_nvgpu.atom.get_value(%269 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
              %272 = cute_nvgpu.atom.get_value(%269 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<mcast_mask>} : i16
              %273 = cute_nvgpu.atom.get_value(%269 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<cache_policy>} : i64
              %TMADescAddr = cute_nvgpu.get_tma_desc_addr(%269 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 2, g_stride = <"()"> mcast = true tma_gbasis = <"(64,128):(1@1,1@0)">>) -> !cute.ptr<generic, align<64>>
              %274:2 = cute.get_scalars(%int_tuple_119) : !cute.int_tuple<"(?{div=64},?{div=128})">
              cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr : !cute.ptr<generic, align<64>>, %ptr_118 : !cute.ptr<f16, smem, align<128>, S<3,4,3>>, %271 : !cute.ptr<smem, align<8>>, [%274#0, %274#1] : i32, i32) mask = %272 cache_policy = %273 mode = <tiled> num_cta = 2 : i32
            } {llvm.loop_annotation = #loop_annotation}
            scf.yield %265, %266, %263 : i32, i32, i32
          } else {
            scf.yield %arg8, %arg9, %arg7 : i32, i32, i32
          }
          %260:4 = scf.if %214 -> (i32, i32, i32, !mma_f16_f16_f32_256x256x16_) {
            %int_tuple_100 = cute.make_int_tuple(%arg11) : (i32) -> !cute.int_tuple<"?">
            %ptr_101 = cute.add_offset(%iter_7, %int_tuple_100) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
            %261 = builtin.unrealized_conversion_cast %ptr_101 : !cute.ptr<i64, smem> to !llvm.ptr<3>
            nvvm.mbarrier.try_wait.parity.shared %261, %arg12, %c10000000_i32 : !llvm.ptr<3>, i32, i32
            %262 = arith.addi %arg11, %c1_i32 : i32
            %263 = arith.addi %arg10, %c1_i32 : i32
            %264 = arith.cmpi eq, %262, %c7_i32 : i32
            %265 = arith.select %264, %c0_i32, %262 : i32
            %266 = scf.if %264 -> (i32) {
              %284 = arith.xori %arg12, %c1_i32 : i32
              scf.yield %284 : i32
            } else {
              scf.yield %arg12 : i32
            }
            %coord_102 = cute.make_coord(%arg11) : (i32) -> !cute.coord<"(_,_,0,?)">
            %idx_103 = cute.crd2idx(%coord_102, %3) : (!cute.coord<"(_,_,0,?)">, !cute.layout<"(1,1,4,7):(0,0,2,1024)">) -> !cute.int_tuple<"?{div=1024}">
            %tup_104 = cute.add_offset(%ummaSmemDesc, %idx_103) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=1024}">) -> !cute_nvgpu.smem_desc
            %idx_105 = cute.crd2idx(%coord_102, %3) : (!cute.coord<"(_,_,0,?)">, !cute.layout<"(1,1,4,7):(0,0,2,1024)">) -> !cute.int_tuple<"?{div=1024}">
            %tup_106 = cute.add_offset(%ummaSmemDesc_72, %idx_105) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=1024}">) -> !cute_nvgpu.smem_desc
            %267 = cute.get_scalars(%20) : !cute.int_tuple<"1">
            %268 = cute.get_scalars(%20) : !cute.int_tuple<"1">
            %269 = cute.get_scalars(%20) : !cute.int_tuple<"1">
            scf.for %arg14 = %c0_i32 to %267 step %c1_i32  : i32 {
              scf.for %arg15 = %c0_i32 to %268 step %c1_i32  : i32 {
                scf.for %arg16 = %c0_i32 to %269 step %c1_i32  : i32 {
                  %284 = cute_nvgpu.atom.get_value(%arg13 : !mma_f16_f16_f32_256x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : i1
                  %285 = cute_nvgpu.atom.get_value(%arg13 : !mma_f16_f16_f32_256x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : i1
                  %286 = cute_nvgpu.atom.get_value(%arg13 : !mma_f16_f16_f32_256x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : i1
                  %287 = arith.extui %284 : i1 to i32
                  %288 = arith.extui %285 : i1 to i32
                  %289 = arith.shli %287, %c13_i32 : i32
                  %290 = arith.shli %288, %c14_i32 : i32
                  %291 = arith.ori %289, %c272629776_i32 : i32
                  %292 = arith.ori %291, %290 : i32
                  cute_nvgpu.arch.mma.SM100.umma(%tup_104, %tup_106, %tmem_ptr, %292, %286) {num_cta = 2 : i32, scale = 0 : i32, a_type = f16} : (!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, !cute.ptr<f32, tmem, align<16>>, i32, i1) -> ()
                } {llvm.loop_annotation = #loop_annotation}
              } {llvm.loop_annotation = #loop_annotation}
            } {llvm.loop_annotation = #loop_annotation}
            %270 = cute_nvgpu.atom.set_value(%arg13, %true : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_f16_f16_f32_256x256x16_
            %coord_107 = cute.make_coord(%arg11) : (i32) -> !cute.coord<"(_,_,1,?)">
            %idx_108 = cute.crd2idx(%coord_107, %3) : (!cute.coord<"(_,_,1,?)">, !cute.layout<"(1,1,4,7):(0,0,2,1024)">) -> !cute.int_tuple<"?{div=2}">
            %tup_109 = cute.add_offset(%ummaSmemDesc, %idx_108) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
            %idx_110 = cute.crd2idx(%coord_107, %3) : (!cute.coord<"(_,_,1,?)">, !cute.layout<"(1,1,4,7):(0,0,2,1024)">) -> !cute.int_tuple<"?{div=2}">
            %tup_111 = cute.add_offset(%ummaSmemDesc_72, %idx_110) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
            %271 = cute.get_scalars(%20) : !cute.int_tuple<"1">
            %272 = cute.get_scalars(%20) : !cute.int_tuple<"1">
            %273 = cute.get_scalars(%20) : !cute.int_tuple<"1">
            scf.for %arg14 = %c0_i32 to %271 step %c1_i32  : i32 {
              scf.for %arg15 = %c0_i32 to %272 step %c1_i32  : i32 {
                scf.for %arg16 = %c0_i32 to %273 step %c1_i32  : i32 {
                  %284 = cute_nvgpu.atom.get_value(%270 : !mma_f16_f16_f32_256x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : i1
                  %285 = cute_nvgpu.atom.get_value(%270 : !mma_f16_f16_f32_256x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : i1
                  %286 = cute_nvgpu.atom.get_value(%270 : !mma_f16_f16_f32_256x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : i1
                  %287 = arith.extui %284 : i1 to i32
                  %288 = arith.extui %285 : i1 to i32
                  %289 = arith.shli %287, %c13_i32 : i32
                  %290 = arith.shli %288, %c14_i32 : i32
                  %291 = arith.ori %289, %c272629776_i32 : i32
                  %292 = arith.ori %291, %290 : i32
                  cute_nvgpu.arch.mma.SM100.umma(%tup_109, %tup_111, %tmem_ptr, %292, %286) {num_cta = 2 : i32, scale = 0 : i32, a_type = f16} : (!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, !cute.ptr<f32, tmem, align<16>>, i32, i1) -> ()
                } {llvm.loop_annotation = #loop_annotation}
              } {llvm.loop_annotation = #loop_annotation}
            } {llvm.loop_annotation = #loop_annotation}
            %274 = cute_nvgpu.atom.set_value(%270, %true : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_f16_f16_f32_256x256x16_
            %coord_112 = cute.make_coord(%arg11) : (i32) -> !cute.coord<"(_,_,2,?)">
            %idx_113 = cute.crd2idx(%coord_112, %3) : (!cute.coord<"(_,_,2,?)">, !cute.layout<"(1,1,4,7):(0,0,2,1024)">) -> !cute.int_tuple<"?{div=4}">
            %tup_114 = cute.add_offset(%ummaSmemDesc, %idx_113) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=4}">) -> !cute_nvgpu.smem_desc
            %idx_115 = cute.crd2idx(%coord_112, %3) : (!cute.coord<"(_,_,2,?)">, !cute.layout<"(1,1,4,7):(0,0,2,1024)">) -> !cute.int_tuple<"?{div=4}">
            %tup_116 = cute.add_offset(%ummaSmemDesc_72, %idx_115) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=4}">) -> !cute_nvgpu.smem_desc
            %275 = cute.get_scalars(%20) : !cute.int_tuple<"1">
            %276 = cute.get_scalars(%20) : !cute.int_tuple<"1">
            %277 = cute.get_scalars(%20) : !cute.int_tuple<"1">
            scf.for %arg14 = %c0_i32 to %275 step %c1_i32  : i32 {
              scf.for %arg15 = %c0_i32 to %276 step %c1_i32  : i32 {
                scf.for %arg16 = %c0_i32 to %277 step %c1_i32  : i32 {
                  %284 = cute_nvgpu.atom.get_value(%274 : !mma_f16_f16_f32_256x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : i1
                  %285 = cute_nvgpu.atom.get_value(%274 : !mma_f16_f16_f32_256x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : i1
                  %286 = cute_nvgpu.atom.get_value(%274 : !mma_f16_f16_f32_256x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : i1
                  %287 = arith.extui %284 : i1 to i32
                  %288 = arith.extui %285 : i1 to i32
                  %289 = arith.shli %287, %c13_i32 : i32
                  %290 = arith.shli %288, %c14_i32 : i32
                  %291 = arith.ori %289, %c272629776_i32 : i32
                  %292 = arith.ori %291, %290 : i32
                  cute_nvgpu.arch.mma.SM100.umma(%tup_114, %tup_116, %tmem_ptr, %292, %286) {num_cta = 2 : i32, scale = 0 : i32, a_type = f16} : (!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, !cute.ptr<f32, tmem, align<16>>, i32, i1) -> ()
                } {llvm.loop_annotation = #loop_annotation}
              } {llvm.loop_annotation = #loop_annotation}
            } {llvm.loop_annotation = #loop_annotation}
            %278 = cute_nvgpu.atom.set_value(%274, %true : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_f16_f16_f32_256x256x16_
            %coord_117 = cute.make_coord(%arg11) : (i32) -> !cute.coord<"(_,_,3,?)">
            %idx_118 = cute.crd2idx(%coord_117, %3) : (!cute.coord<"(_,_,3,?)">, !cute.layout<"(1,1,4,7):(0,0,2,1024)">) -> !cute.int_tuple<"?{div=2}">
            %tup_119 = cute.add_offset(%ummaSmemDesc, %idx_118) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
            %idx_120 = cute.crd2idx(%coord_117, %3) : (!cute.coord<"(_,_,3,?)">, !cute.layout<"(1,1,4,7):(0,0,2,1024)">) -> !cute.int_tuple<"?{div=2}">
            %tup_121 = cute.add_offset(%ummaSmemDesc_72, %idx_120) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
            %279 = cute.get_scalars(%20) : !cute.int_tuple<"1">
            %280 = cute.get_scalars(%20) : !cute.int_tuple<"1">
            %281 = cute.get_scalars(%20) : !cute.int_tuple<"1">
            scf.for %arg14 = %c0_i32 to %279 step %c1_i32  : i32 {
              scf.for %arg15 = %c0_i32 to %280 step %c1_i32  : i32 {
                scf.for %arg16 = %c0_i32 to %281 step %c1_i32  : i32 {
                  %284 = cute_nvgpu.atom.get_value(%278 : !mma_f16_f16_f32_256x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : i1
                  %285 = cute_nvgpu.atom.get_value(%278 : !mma_f16_f16_f32_256x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : i1
                  %286 = cute_nvgpu.atom.get_value(%278 : !mma_f16_f16_f32_256x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : i1
                  %287 = arith.extui %284 : i1 to i32
                  %288 = arith.extui %285 : i1 to i32
                  %289 = arith.shli %287, %c13_i32 : i32
                  %290 = arith.shli %288, %c14_i32 : i32
                  %291 = arith.ori %289, %c272629776_i32 : i32
                  %292 = arith.ori %291, %290 : i32
                  cute_nvgpu.arch.mma.SM100.umma(%tup_119, %tup_121, %tmem_ptr, %292, %286) {num_cta = 2 : i32, scale = 0 : i32, a_type = f16} : (!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, !cute.ptr<f32, tmem, align<16>>, i32, i1) -> ()
                } {llvm.loop_annotation = #loop_annotation}
              } {llvm.loop_annotation = #loop_annotation}
            } {llvm.loop_annotation = #loop_annotation}
            %282 = cute_nvgpu.atom.set_value(%278, %true : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_f16_f16_f32_256x256x16_
            %283 = nvvm.elect.sync -> i1
            scf.if %283 {
              %int_tuple_122 = cute.make_int_tuple(%arg11) : (i32) -> !cute.int_tuple<"?">
              %ptr_123 = cute.add_offset(%ptr_8, %int_tuple_122) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
              %284 = builtin.unrealized_conversion_cast %ptr_123 : !cute.ptr<i64, smem> to !llvm.ptr<3>
              nvvm.tcgen05.commit.arrive %284, multicast_mask = %97 {group = #nvvm.tcgen05_group<cta_2>} : !llvm.ptr<3>, i16
            }
            scf.yield %263, %265, %266, %282 : i32, i32, i32, !mma_f16_f16_f32_256x256x16_
          } else {
            scf.yield %arg10, %arg11, %arg12, %arg13 : i32, i32, i32, !mma_f16_f16_f32_256x256x16_
          }
          scf.yield %259#2, %259#0, %259#1, %260#0, %260#1, %260#2, %260#3 : i32, i32, i32, i32, i32, i32, !mma_f16_f16_f32_256x256x16_
        }
        scf.if %214 {
          %257 = nvvm.elect.sync -> i1
          scf.if %257 {
            %dyn_100 = cute.derefine(%iter_24) : !cute.ptr<i64, smem, align<16>> to !cute.ptr<i64, smem>
            %258 = builtin.unrealized_conversion_cast %dyn_100 : !cute.ptr<i64, smem> to !llvm.ptr<3>
            nvvm.tcgen05.commit.arrive %258, multicast_mask = %c3_i16 {group = #nvvm.tcgen05_group<cta_2>} : !llvm.ptr<3>, i16
          }
        }
        scf.yield %249, %256#1, %256#2 : i32, i32, i32
      } else {
        scf.yield %c1_i32, %c0_i32, %c1_i32 : i32, i32, i32
      }
      %218 = nvvm.read.ptx.sreg.tid.x range <i32, 0, 1024> : i32
      %219 = nvvm.read.ptx.sreg.tid.y range <i32, 0, 1024> : i32
      %220 = nvvm.read.ptx.sreg.tid.z range <i32, 0, 64> : i32
      %221 = nvvm.read.ptx.sreg.ntid.x range <i32, 1, 1024> : i32
      %222 = nvvm.read.ptx.sreg.ntid.y range <i32, 1, 1024> : i32
      %223 = arith.muli %219, %221 : i32
      %224 = arith.addi %218, %223 : i32
      %225 = arith.muli %220, %221 : i32
      %226 = arith.muli %225, %222 : i32
      %227 = arith.addi %224, %226 : i32
      %228 = arith.floordivsi %227, %c32_i32 : i32
      %229 = cute_nvgpu.arch.make_warp_uniform(%228) : i32
      %230 = arith.cmpi eq, %229, %c0_i32 : i32
      scf.if %230 {
        cute_nvgpu.arch.sm100.relinquish_tmem_alloc_permit [cta_2]
      }
      %dyn = cute.derefine(%iter_24) : !cute.ptr<i64, smem, align<16>> to !cute.ptr<i64, smem>
      %231 = builtin.unrealized_conversion_cast %dyn : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %231, %c0_i32, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      scf.for %arg6 = %c0_i32 to %c4_i32 step %c1_i32  : i32 {
        %iter_100 = cute.get_iter(%rmem) : !memref_rmem_f32_
        %coord_101 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,_,?)">
        %idx_102 = cute.crd2idx(%coord_101, %2) : (!cute.coord<"(_,_,?)">, !cute.layout<"(((64,32),1),1,((1,4),1,1)):(((1,65536),0),0,((0,64),0,0))">) -> !cute.int_tuple<"?{div=64}">
        %ptr_103 = cute.add_offset(%ptr_93, %idx_102) : (!cute.ptr<f32, tmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<f32, tmem, align<16>>
        %248 = cute.get_scalars(%20) : !cute.int_tuple<"1">
        scf.for %arg7 = %c0_i32 to %248 step %c1_i32  : i32 {
          %252 = "cute_nvgpu.arch.copy.SM100.tmem_load"(%ptr_103) <{num_b = 32 : i32, num_dp = 32 : i32, num_rep = 64 : i32}> : (!cute.ptr<f32, tmem, align<16>>) -> vector<64xi32>
          %253 = builtin.unrealized_conversion_cast %iter_100 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
          llvm.store %252, %253 : vector<64xi32>, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %249 = cute.memref.load_vec %rmem : !memref_rmem_f32_
        %250 = arith.truncf %249 : vector<64xf32> to vector<64xf16>
        cute.memref.store_vec %250, %rmem_98 : !memref_rmem_f16_
        %coord_104 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,_,?)">
        %idx_105 = cute.crd2idx(%coord_104, %1) : (!cute.coord<"(_,_,?)">, !cute.layout<"((64,1),1,((1,4),1,1)):((1,0),0,((0,64),0,0))">) -> !cute.int_tuple<"?{div=64}">
        %ptr_106 = cute.add_offset(%ptr_97, %idx_105) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<f16, gmem, align<32>>
        %iter_107 = cute.get_iter(%rmem_98) : !memref_rmem_f16_
        %251 = cute.get_scalars(%17) : !cute.int_tuple<"4">
        scf.for %arg7 = %c0_i32 to %251 step %c1_i32  : i32 {
          %coord_108 = cute.make_coord(%arg7) : (i32) -> !cute.coord<"(_,?)">
          %idx_109 = cute.crd2idx(%coord_108, %0) : (!cute.coord<"(_,?)">, !cute.layout<"(16,(4)):(1,(16))">) -> !cute.int_tuple<"?{div=16}">
          %ptr_110 = cute.add_offset(%iter_107, %idx_109) : (!cute.ptr<f16, rmem, align<32>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<f16, rmem, align<32>>
          %idx_111 = cute.crd2idx(%coord_108, %0) : (!cute.coord<"(_,?)">, !cute.layout<"(16,(4)):(1,(16))">) -> !cute.int_tuple<"?{div=16}">
          %ptr_112 = cute.add_offset(%ptr_106, %idx_111) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<f16, gmem, align<32>>
          %252 = builtin.unrealized_conversion_cast %ptr_110 : !cute.ptr<f16, rmem, align<32>> to !llvm.ptr
          %253 = builtin.unrealized_conversion_cast %ptr_112 : !cute.ptr<f16, gmem, align<32>> to !llvm.ptr<1>
          %254 = llvm.load %252 {alignment = 32 : i64} : !llvm.ptr -> vector<16xf16>
          llvm.store %254, %253 {alignment = 32 : i64} : vector<16xf16>, !llvm.ptr<1>
        } {llvm.loop_annotation = #loop_annotation}
      }
      %232 = builtin.unrealized_conversion_cast %ptr_25 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      %233 = nvvm.mapa.shared.cluster %232, %130 : !llvm.ptr<3>, i32 -> <3>
      nvvm.mbarrier.txn %233, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>, space = #nvvm.mbar_space<cluster>} : !llvm.ptr<3>, i32
      %234 = arith.cmpi eq, %39, %c0_i32 : i32
      scf.if %234 {
        %248 = arith.addi %217#1, %c1_i32 : i32
        %249 = arith.cmpi eq, %248, %c7_i32 : i32
        %250 = arith.select %249, %c0_i32, %248 : i32
        %251 = scf.if %249 -> (i32) {
          %273 = arith.xori %217#2, %c1_i32 : i32
          scf.yield %273 : i32
        } else {
          scf.yield %217#2 : i32
        }
        %252 = arith.addi %250, %c1_i32 : i32
        %253 = arith.cmpi eq, %252, %c7_i32 : i32
        %254 = arith.select %253, %c0_i32, %252 : i32
        %255 = scf.if %253 -> (i32) {
          %273 = arith.xori %251, %c1_i32 : i32
          scf.yield %273 : i32
        } else {
          scf.yield %251 : i32
        }
        %256 = arith.addi %254, %c1_i32 : i32
        %257 = arith.cmpi eq, %256, %c7_i32 : i32
        %258 = arith.select %257, %c0_i32, %256 : i32
        %259 = scf.if %257 -> (i32) {
          %273 = arith.xori %255, %c1_i32 : i32
          scf.yield %273 : i32
        } else {
          scf.yield %255 : i32
        }
        %260 = arith.addi %258, %c1_i32 : i32
        %261 = arith.cmpi eq, %260, %c7_i32 : i32
        %262 = arith.select %261, %c0_i32, %260 : i32
        %263 = scf.if %261 -> (i32) {
          %273 = arith.xori %259, %c1_i32 : i32
          scf.yield %273 : i32
        } else {
          scf.yield %259 : i32
        }
        %264 = arith.addi %262, %c1_i32 : i32
        %265 = arith.cmpi eq, %264, %c7_i32 : i32
        %266 = arith.select %265, %c0_i32, %264 : i32
        %267 = scf.if %265 -> (i32) {
          %273 = arith.xori %263, %c1_i32 : i32
          scf.yield %273 : i32
        } else {
          scf.yield %263 : i32
        }
        %268 = arith.addi %266, %c1_i32 : i32
        %269 = arith.cmpi eq, %268, %c7_i32 : i32
        %270 = arith.select %269, %c0_i32, %268 : i32
        %271 = scf.if %269 -> (i32) {
          %273 = arith.xori %267, %c1_i32 : i32
          scf.yield %273 : i32
        } else {
          scf.yield %267 : i32
        }
        %int_tuple_100 = cute.make_int_tuple(%270) : (i32) -> !cute.int_tuple<"?">
        %ptr_101 = cute.add_offset(%ptr_8, %int_tuple_100) : (!cute.ptr<i64, smem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
        %272 = builtin.unrealized_conversion_cast %ptr_101 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        nvvm.mbarrier.try_wait.parity.shared %272, %271, %c10000000_i32 : !llvm.ptr<3>, i32, i32
        scf.if %100 {
          %273 = nvvm.elect.sync -> i1
          scf.if %273 {
            %int_tuple_102 = cute.make_int_tuple(%270) : (i32) -> !cute.int_tuple<"?">
            %ptr_103 = cute.add_offset(%iter_7, %int_tuple_102) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
            %274 = builtin.unrealized_conversion_cast %ptr_103 : !cute.ptr<i64, smem> to !llvm.ptr<3>
            nvvm.mbarrier.txn %274, %c65536_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
          }
        }
        scf.if %214 {
          %273 = nvvm.read.ptx.sreg.cluster.ctarank : i32
          %274 = cute_nvgpu.arch.make_warp_uniform(%273) : i32
          %275 = arith.remsi %274, %c2_i32 : i32
          %276 = arith.cmpi eq, %275, %c0_i32 : i32
          scf.if %276 {
            %277 = builtin.unrealized_conversion_cast %ptr_25 : !cute.ptr<i64, smem> to !llvm.ptr<3>
            nvvm.mbarrier.try_wait.parity.shared %277, %217#0, %c10000000_i32 : !llvm.ptr<3>, i32, i32
          }
        }
      }
      nvvm.barrier id = %c1_i32
      %235 = nvvm.read.ptx.sreg.tid.x range <i32, 0, 1024> : i32
      %236 = nvvm.read.ptx.sreg.tid.y range <i32, 0, 1024> : i32
      %237 = nvvm.read.ptx.sreg.tid.z range <i32, 0, 64> : i32
      %238 = nvvm.read.ptx.sreg.ntid.x range <i32, 1, 1024> : i32
      %239 = nvvm.read.ptx.sreg.ntid.y range <i32, 1, 1024> : i32
      %240 = arith.muli %236, %238 : i32
      %241 = arith.addi %235, %240 : i32
      %242 = arith.muli %237, %238 : i32
      %243 = arith.muli %242, %239 : i32
      %244 = arith.addi %241, %243 : i32
      %245 = arith.floordivsi %244, %c32_i32 : i32
      %246 = cute_nvgpu.arch.make_warp_uniform(%245) : i32
      %247 = arith.cmpi eq, %246, %c0_i32 : i32
      scf.if %247 {
        %248 = nvvm.read.ptx.sreg.cluster.ctarank : i32
        %249 = cute_nvgpu.arch.make_warp_uniform(%248) : i32
        %250 = arith.xori %249, %c1_i32 : i32
        %251 = builtin.unrealized_conversion_cast %iter : !cute.ptr<i64, smem, align<128>> to !llvm.ptr<3>
        %252 = nvvm.mapa.shared.cluster %251, %250 : !llvm.ptr<3>, i32 -> <3>
        nvvm.mbarrier.txn %252, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>, space = #nvvm.mbar_space<cluster>} : !llvm.ptr<3>, i32
        %253 = builtin.unrealized_conversion_cast %iter : !cute.ptr<i64, smem, align<128>> to !llvm.ptr<3>
        nvvm.mbarrier.try_wait.parity.shared %253, %c0_i32, %c10000000_i32 : !llvm.ptr<3>, i32, i32
        cute_nvgpu.arch.sm100.dealloc_tmem(%tmem_ptr, %c512_i32) [cta_2] : !cute.ptr<f32, tmem, align<16>>, i32
      }
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
    %36 = llvm.getelementptr %11[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %35, %36 : i64, !llvm.ptr
    %37 = llvm.sub %14, %c1_i64 : i64
    %38 = llvm.sub %c1_i64, %c1_i64 : i64
    %39 = llvm.sub %c1_i64, %c1_i64 : i64
    %40 = llvm.sub %c1_i64, %c1_i64 : i64
    %41 = llvm.mul %37, %15 : i64
    %42 = llvm.mul %38, %c0_i64 : i64
    %43 = llvm.mul %39, %c0_i64 : i64
    %44 = llvm.mul %40, %c0_i64 : i64
    %45 = llvm.add %41, %42 : i64
    %46 = llvm.add %43, %44 : i64
    %47 = llvm.mul %13, %c16_i64 : i64
    %48 = llvm.udiv %47, %c8_i64 : i64
    %49 = llvm.add %48, %45 : i64
    %50 = llvm.add %49, %46 : i64
    %51 = llvm.icmp "uge" %50, %c131072_i64 : i64
    %52 = llvm.zext %51 : i1 to i64
    %53 = llvm.shl %52, %c21_i64 : i64
    %54 = llvm.udiv %15, %c16_i64 : i64
    %55 = llvm.shl %54, %c32_i64 : i64
    %56 = llvm.or %c0_i64, %53 : i64
    %57 = llvm.or %56, %55 : i64
    %58 = llvm.or %2, %57 : i64
    %59 = llvm.getelementptr %11[0, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %58, %59 : i64, !llvm.ptr
    %60 = llvm.udiv %c0_i64, %c16_i64 : i64
    %61 = llvm.and %60, %c4294967295_i64 : i64
    %62 = llvm.shl %61, %c0_i64 : i64
    %63 = llvm.udiv %c0_i64, %c16_i64 : i64
    %64 = llvm.shl %63, %c32_i64 : i64
    %65 = llvm.or %62, %64 : i64
    %66 = llvm.getelementptr %11[0, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %65, %66 : i64, !llvm.ptr
    %67 = llvm.udiv %c0_i64, %c16_i64 : i64
    %68 = llvm.and %67, %c4294967295_i64 : i64
    %69 = llvm.shl %68, %c0_i64 : i64
    %70 = llvm.lshr %15, %c36_i64 : i64
    %71 = llvm.and %70, %c15_i64 : i64
    %72 = llvm.shl %71, %c32_i64 : i64
    %73 = llvm.lshr %c0_i64, %c36_i64 : i64
    %74 = llvm.and %73, %c15_i64 : i64
    %75 = llvm.shl %74, %c36_i64 : i64
    %76 = llvm.lshr %c0_i64, %c36_i64 : i64
    %77 = llvm.and %76, %c15_i64 : i64
    %78 = llvm.shl %77, %c40_i64 : i64
    %79 = llvm.lshr %c0_i64, %c36_i64 : i64
    %80 = llvm.shl %79, %c44_i64 : i64
    %81 = llvm.or %72, %75 : i64
    %82 = llvm.or %78, %80 : i64
    %83 = llvm.or %81, %82 : i64
    %84 = llvm.or %69, %83 : i64
    %85 = llvm.getelementptr %11[0, 3] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %84, %85 : i64, !llvm.ptr
    %86 = llvm.sub %13, %c1_i64 : i64
    %87 = llvm.and %86, %c4294967295_i64 : i64
    %88 = llvm.shl %87, %c0_i64 : i64
    %89 = llvm.sub %14, %c1_i64 : i64
    %90 = llvm.shl %89, %c32_i64 : i64
    %91 = llvm.or %88, %90 : i64
    %92 = llvm.getelementptr %11[0, 4] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %91, %92 : i64, !llvm.ptr
    %93 = llvm.sub %c1_i64, %c1_i64 : i64
    %94 = llvm.and %93, %c4294967295_i64 : i64
    %95 = llvm.shl %94, %c0_i64 : i64
    %96 = llvm.sub %c1_i64, %c1_i64 : i64
    %97 = llvm.shl %96, %c32_i64 : i64
    %98 = llvm.or %95, %97 : i64
    %99 = llvm.getelementptr %11[0, 5] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %98, %99 : i64, !llvm.ptr
    %100 = llvm.sub %c1_i64, %c1_i64 : i64
    %101 = llvm.and %100, %c4294967295_i64 : i64
    %102 = llvm.or %101, %c0_i64 : i64
    %103 = llvm.or %102, %1 : i64
    %104 = llvm.getelementptr %11[0, 6] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %103, %104 : i64, !llvm.ptr
    %105 = llvm.getelementptr %11[0, 7] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %0, %105 : i64, !llvm.ptr
    %106 = builtin.unrealized_conversion_cast %11 : !llvm.ptr to !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>>
    %107 = cute.ptrtoint(%106) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>> to i64
    %108 = llvm.inttoptr %107 : i64 to !llvm.ptr
    %109 = llvm.load %108 {nontemporal} : !llvm.ptr -> !llvm.struct<(array<16 x i64>)>
    %110 = builtin.unrealized_conversion_cast %109 : !llvm.struct<(array<16 x i64>)> to !cute_nvgpu.tma_descriptor_tiled
    %atom_0 = cute.make_atom() : () -> !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_100_2sm_multicast, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, internal_val_type = f16>
    %111 = cute_nvgpu.atom.set_value(%atom_0, %110 : !cute_nvgpu.tma_descriptor_tiled) {field = #cute_nvgpu.atom_copy_field_non_exec_tma_load<tma_desc>} : !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_100_2sm_multicast, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, internal_val_type = f16>
    %lay_1 = cute.get_layout(%arg0) : !memref_gmem_f16_
    %112 = cute.get_shape(%lay_1) : (!cute.layout<"(?,?{div=8192}):(?{i64 div=8192},1)">) -> !cute.shape<"(?,?{div=8192})">
    %lay_2 = cute.make_layout(%112, %6) : !cute.layout<"(?,?{div=8192}):(1@1,1@0)">
    %view = cute.make_view(%5, %lay_2) : !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">
    %113 = llvm.alloca %c16_i32 x i64 {alignment = 64 : i64} : (i32) -> !llvm.ptr
    %iter_3 = cute.get_iter(%arg1) : !memref_gmem_f16_
    %lay_4 = cute.get_layout(%arg1) : !memref_gmem_f16_
    %114:3 = cute.get_scalars(%lay_4) <{only_dynamic}> : !cute.layout<"(?,?{div=8192}):(?{i64 div=8192},1)">
    %115 = arith.extui %114#1 : i32 to i64
    %116 = arith.extui %114#0 : i32 to i64
    %117 = llvm.mul %114#2, %c2_i64 : i64
    %118 = cute.ptrtoint(%iter_3) : !cute.ptr<f16, gmem, align<32>> to i64
    %119 = llvm.getelementptr %113[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %119 : i64, !llvm.ptr
    %120 = llvm.getelementptr %113[0, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %120 : i64, !llvm.ptr
    %121 = llvm.getelementptr %113[0, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %121 : i64, !llvm.ptr
    %122 = llvm.getelementptr %113[0, 3] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %122 : i64, !llvm.ptr
    %123 = llvm.getelementptr %113[0, 4] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %123 : i64, !llvm.ptr
    %124 = llvm.getelementptr %113[0, 5] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %124 : i64, !llvm.ptr
    %125 = llvm.getelementptr %113[0, 6] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %125 : i64, !llvm.ptr
    %126 = llvm.getelementptr %113[0, 7] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %126 : i64, !llvm.ptr
    %127 = llvm.getelementptr %113[0, 8] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %127 : i64, !llvm.ptr
    %128 = llvm.getelementptr %113[0, 9] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %128 : i64, !llvm.ptr
    %129 = llvm.getelementptr %113[0, 10] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %129 : i64, !llvm.ptr
    %130 = llvm.getelementptr %113[0, 11] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %130 : i64, !llvm.ptr
    %131 = llvm.getelementptr %113[0, 12] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %131 : i64, !llvm.ptr
    %132 = llvm.getelementptr %113[0, 13] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %132 : i64, !llvm.ptr
    %133 = llvm.getelementptr %113[0, 14] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %133 : i64, !llvm.ptr
    %134 = llvm.getelementptr %113[0, 15] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %134 : i64, !llvm.ptr
    %135 = llvm.udiv %118, %c16_i64 : i64
    %136 = llvm.and %135, %c9007199254740991_i64 : i64
    %137 = llvm.shl %136, %c4_i64 : i64
    %138 = llvm.getelementptr %113[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %137, %138 : i64, !llvm.ptr
    %139 = llvm.sub %116, %c1_i64 : i64
    %140 = llvm.sub %c1_i64, %c1_i64 : i64
    %141 = llvm.sub %c1_i64, %c1_i64 : i64
    %142 = llvm.sub %c1_i64, %c1_i64 : i64
    %143 = llvm.mul %139, %117 : i64
    %144 = llvm.mul %140, %c0_i64 : i64
    %145 = llvm.mul %141, %c0_i64 : i64
    %146 = llvm.mul %142, %c0_i64 : i64
    %147 = llvm.add %143, %144 : i64
    %148 = llvm.add %145, %146 : i64
    %149 = llvm.mul %115, %c16_i64 : i64
    %150 = llvm.udiv %149, %c8_i64 : i64
    %151 = llvm.add %150, %147 : i64
    %152 = llvm.add %151, %148 : i64
    %153 = llvm.icmp "uge" %152, %c131072_i64 : i64
    %154 = llvm.zext %153 : i1 to i64
    %155 = llvm.shl %154, %c21_i64 : i64
    %156 = llvm.udiv %117, %c16_i64 : i64
    %157 = llvm.shl %156, %c32_i64 : i64
    %158 = llvm.or %c0_i64, %155 : i64
    %159 = llvm.or %158, %157 : i64
    %160 = llvm.or %2, %159 : i64
    %161 = llvm.getelementptr %113[0, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %160, %161 : i64, !llvm.ptr
    %162 = llvm.udiv %c0_i64, %c16_i64 : i64
    %163 = llvm.and %162, %c4294967295_i64 : i64
    %164 = llvm.shl %163, %c0_i64 : i64
    %165 = llvm.udiv %c0_i64, %c16_i64 : i64
    %166 = llvm.shl %165, %c32_i64 : i64
    %167 = llvm.or %164, %166 : i64
    %168 = llvm.getelementptr %113[0, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %167, %168 : i64, !llvm.ptr
    %169 = llvm.udiv %c0_i64, %c16_i64 : i64
    %170 = llvm.and %169, %c4294967295_i64 : i64
    %171 = llvm.shl %170, %c0_i64 : i64
    %172 = llvm.lshr %117, %c36_i64 : i64
    %173 = llvm.and %172, %c15_i64 : i64
    %174 = llvm.shl %173, %c32_i64 : i64
    %175 = llvm.lshr %c0_i64, %c36_i64 : i64
    %176 = llvm.and %175, %c15_i64 : i64
    %177 = llvm.shl %176, %c36_i64 : i64
    %178 = llvm.lshr %c0_i64, %c36_i64 : i64
    %179 = llvm.and %178, %c15_i64 : i64
    %180 = llvm.shl %179, %c40_i64 : i64
    %181 = llvm.lshr %c0_i64, %c36_i64 : i64
    %182 = llvm.shl %181, %c44_i64 : i64
    %183 = llvm.or %174, %177 : i64
    %184 = llvm.or %180, %182 : i64
    %185 = llvm.or %183, %184 : i64
    %186 = llvm.or %171, %185 : i64
    %187 = llvm.getelementptr %113[0, 3] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %186, %187 : i64, !llvm.ptr
    %188 = llvm.sub %115, %c1_i64 : i64
    %189 = llvm.and %188, %c4294967295_i64 : i64
    %190 = llvm.shl %189, %c0_i64 : i64
    %191 = llvm.sub %116, %c1_i64 : i64
    %192 = llvm.shl %191, %c32_i64 : i64
    %193 = llvm.or %190, %192 : i64
    %194 = llvm.getelementptr %113[0, 4] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %193, %194 : i64, !llvm.ptr
    %195 = llvm.sub %c1_i64, %c1_i64 : i64
    %196 = llvm.and %195, %c4294967295_i64 : i64
    %197 = llvm.shl %196, %c0_i64 : i64
    %198 = llvm.sub %c1_i64, %c1_i64 : i64
    %199 = llvm.shl %198, %c32_i64 : i64
    %200 = llvm.or %197, %199 : i64
    %201 = llvm.getelementptr %113[0, 5] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %200, %201 : i64, !llvm.ptr
    %202 = llvm.sub %c1_i64, %c1_i64 : i64
    %203 = llvm.and %202, %c4294967295_i64 : i64
    %204 = llvm.or %203, %c0_i64 : i64
    %205 = llvm.or %204, %1 : i64
    %206 = llvm.getelementptr %113[0, 6] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %205, %206 : i64, !llvm.ptr
    %207 = llvm.getelementptr %113[0, 7] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %0, %207 : i64, !llvm.ptr
    %208 = builtin.unrealized_conversion_cast %113 : !llvm.ptr to !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>>
    %209 = cute.ptrtoint(%208) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>> to i64
    %210 = llvm.inttoptr %209 : i64 to !llvm.ptr
    %211 = llvm.load %210 {nontemporal} : !llvm.ptr -> !llvm.struct<(array<16 x i64>)>
    %212 = builtin.unrealized_conversion_cast %211 : !llvm.struct<(array<16 x i64>)> to !cute_nvgpu.tma_descriptor_tiled
    %atom_5 = cute.make_atom() : () -> !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_100_2sm_multicast, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, internal_val_type = f16>
    %213 = cute_nvgpu.atom.set_value(%atom_5, %212 : !cute_nvgpu.tma_descriptor_tiled) {field = #cute_nvgpu.atom_copy_field_non_exec_tma_load<tma_desc>} : !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_100_2sm_multicast, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, internal_val_type = f16>
    %lay_6 = cute.get_layout(%arg1) : !memref_gmem_f16_
    %214 = cute.get_shape(%lay_6) : (!cute.layout<"(?,?{div=8192}):(?{i64 div=8192},1)">) -> !cute.shape<"(?,?{div=8192})">
    %lay_7 = cute.make_layout(%214, %6) : !cute.layout<"(?,?{div=8192}):(1@1,1@0)">
    %view_8 = cute.make_view(%5, %lay_7) : !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">
    %lay_9 = cute.get_layout(%arg2) : !memref_gmem_f16_
    %215 = cute.get_shape(%lay_9) : (!cute.layout<"(?,?{div=8192}):(?{i64 div=8192},1)">) -> !cute.shape<"(?,?{div=8192})">
    %e0, %e1 = cute.get_leaves(%215) : !cute.shape<"(?,?{div=8192})">
    %itup = cute.to_int_tuple(%e0) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %itup_10 = cute.to_int_tuple(%e1) : !cute.shape<"?{div=8192}"> to !cute.int_tuple<"?{div=8192}">
    %int_tuple = cute.make_int_tuple(%itup, %itup_10) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8192}">) -> !cute.int_tuple<"(?,?{div=8192},1)">
    %216:2 = cute.get_scalars(%int_tuple) <{only_dynamic}> : !cute.int_tuple<"(?,?{div=8192},1)">
    %217 = arith.ceildivsi %216#0, %c128_i32 : i32
    %218 = arith.ceildivsi %216#1, %c256_i32 : i32
    %int_tuple_11 = cute.make_int_tuple(%217, %218) : (i32, i32) -> !cute.int_tuple<"(?,?,1)">
    %e0_12, %e1_13, %e2 = cute.get_leaves(%int_tuple_11) : !cute.int_tuple<"(?,?,1)">
    %tup = cute.add_offset(%e0_12, %3) : (!cute.int_tuple<"?">, !cute.int_tuple<"2">) -> !cute.int_tuple<"?">
    %sub = cute.tuple_sub(%tup, %4) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
    %div = cute.tuple_div(%sub, %3) : (!cute.int_tuple<"?">, !cute.int_tuple<"2">) -> !cute.int_tuple<"?">
    %mul = cute.tuple_mul(%div, %3) : (!cute.int_tuple<"?">, !cute.int_tuple<"2">) -> !cute.int_tuple<"?{div=2}">
    %219 = cute.get_scalars(%mul) : !cute.int_tuple<"?{div=2}">
    %tup_14 = cute.add_offset(%e1_13, %4) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
    %sub_15 = cute.tuple_sub(%tup_14, %4) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
    %div_16 = cute.tuple_div(%sub_15, %4) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
    %mul_17 = cute.tuple_mul(%div_16, %4) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
    %220 = cute.get_scalars(%mul_17) : !cute.int_tuple<"?">
    %221 = cuda.cast %c0_i64 : i64 -> !cuda.stream
    %222 = cuda.launch_cfg.create<max_attrs = 2 : i32> (blockDim = (%c128_i32, %c1_i32, %c1_i32), dynamicSmemBytes = %c229632_i64, gridDim = (%219, %220, %c1_i32), stream = %221) : i32, i32, i32, i64, i32, i32, i32, !cuda.stream -> !cuda.launch_cfg<max_attrs = 2>
    cuda.launch_cfg.cluster_dim[%222] (%c2_i32, %c1_i32, %c1_i32) : !cuda.launch_cfg<max_attrs = 2>, i32, i32, i32
    %223 = cuda.launch_ex @kernels::@kernel_cutlass_kernel_TiledMMA_ThrLayoutVMNK21111000_PermutationMNK____MMAAtom_ThrID21_ShapeMNK25625616_TVLayoutA2128161281256_TVLayoutB2128161281256_TVLayoutC21282561281256_CopyAtom_ThrI_0<%222> (%10, %111, %view, %213, %view_8, %arg2) : !cuda.launch_cfg<max_attrs = 2>, (!mma_f16_f16_f32_256x256x16_, !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_100_2sm_multicast, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, internal_val_type = f16>, !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">, !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_100_2sm_multicast, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, internal_val_type = f16>, !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">, !memref_gmem_f16_) -> !cuda.result
    %224 = cuda.cast %223 : !cuda.result -> i32
    cuda.return_if_error %224 : i32
    return %c0_i32 : i32
  }
}
