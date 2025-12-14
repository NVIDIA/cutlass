!copy_simt = !cute.tiled_copy<!cute_nvgpu.atom.universal_copy<f16>, layout_copy_tv = <"((32,4),(32,1)):((4,1),(128,0))">, tiler_mn = <"[(4,32):(32,1);32:1]">>
!memref_gmem_f16_ = !cute.memref<f16, gmem, align<16>, "(?,?,1):(?,?,0)">
!memref_gmem_f16_1 = !cute.memref<f16, gmem, align<16>, "(?,?,?):(?,?,?)">
!memref_gmem_f16_2 = !cute.memref<f16, gmem, align<16>, "(?,?,?):(?{i64},1,?{i64})">
!memref_gmem_i32_ = !cute.memref<i32, gmem, align<16>, "(2,4):(4,1)">
!memref_gmem_i32_1 = !cute.memref<i32, gmem, align<16>, "(2,3,2):(6,2,1)">
!memref_gmem_i64_ = !cute.memref<i64, gmem, align<16>, "(2,3):(3,1)">
!memref_gmem_i64_1 = !cute.memref<i64, gmem, "(1,3,16):(48,16,1)">
!memref_rmem_f16_ = !cute.memref<f16, rmem, align<32>, "((32,1),1,1):((1,0),0,0)">
!memref_rmem_f16_1 = !cute.memref<f16, rmem, align<32>, "((1,32),1,1):((0,1),0,0)">
!memref_rmem_f32_ = !cute.memref<f32, rmem, align<32>, "((32,1),1,1):((1,0),0,0)">
!memref_rmem_f32_1 = !cute.memref<f32, rmem, align<32>, "((1,32),1,1):((0,1),0,0)">
!memref_rmem_i32_ = !cute.memref<i32, rmem, align<32>, "4:1">
!memref_rmem_i32_1 = !cute.memref<i32, rmem, align<32>, "2:1">
!mma_f16_f16_f32_128x128x16_ = !cute.tiled_mma<!cute_nvgpu.sm100.mma<128x128x16, num_cta = 1, ab_major = (k, k), elem_type = (f16, f16, f32), frag_kind = ss, c_scale_exp = 0>, atom_layout_MNK = <"(1,1,1):(0,0,0)">>
#loop_unroll = #llvm.loop_unroll<disable = false, full = true>
#loop_unroll1 = #llvm.loop_unroll<disable = true, count = 1 : i32>
#loop_unroll2 = #llvm.loop_unroll<full = true>
#loop_annotation = #llvm.loop_annotation<unroll = #loop_unroll>
#loop_annotation1 = #llvm.loop_annotation<unroll = #loop_unroll1>
#loop_annotation2 = #llvm.loop_annotation<unroll = #loop_unroll2>
module attributes {gpu.container_module} {
  gpu.module @kernels {
    cuda.kernel @kernel_cutlass_kernel___main__GroupedGemmKernel_object_at__TiledMMA_ThrLayoutVMNK11110000_PermutationMNK____MMAAtom_ThrID10_ShapeMNK12812816_TVLayoutA1128161281128_TVLayoutB1128161281128__0(%arg0: !mma_f16_f16_f32_128x128x16_, %arg1: !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>, %arg2: !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">, %arg3: !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>, %arg4: !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">, %arg5: !cute_nvgpu.atom.non_exec_tiled_tma_store<f16, copy_bits = 65536, tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>, %arg6: !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">, %arg7: i32, %arg8: !cute.fast_divmod_divisor<32>, %arg9: !cute.fast_divmod_divisor<32>, %arg10: !cute.fast_divmod_divisor<32>, %arg11: !memref_gmem_i32_, %arg12: !memref_gmem_i32_1, %arg13: !memref_gmem_i64_, %arg14: !memref_gmem_i64_1) attributes {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 192, 1, 1>} {
      %0 = builtin.unrealized_conversion_cast %arg0 : !mma_f16_f16_f32_128x128x16_ to !llvm.struct<(i1, i1, i1)>
      %c63_i32 = arith.constant 63 : i32
      %c127_i32 = arith.constant 127 : i32
      %1 = cute.static : !cute.layout<"(((32,128),1),(1,4)):(((1@0,1@1),0),(0,32@0))">
      %2 = cute.static : !cute.layout<"((4096,1),(1,4)):((1,0),(0,4096))">
      %3 = cute.static : !cute.int_tuple<"24">
      %4 = cute.static : !cute.int_tuple<"8">
      %5 = cute.static : !cute.layout<"((1,32),1,1,(1,4)):((0,1),0,0,(0,4096))">
      %6 = cute.static : !cute.layout<"(((32,32),1),1,1,(1,4)):(((1,65536),0),0,0,(0,32))">
      %7 = cute.static : !cute.layout<"(((32,32),1),1,1,1,4,2):(((1,65536),0),0,0,0,32,128)">
      %8 = cute.static : !cute.stride<"(((1@0,1@1),0),0,32@0,128@1,128@0,1@2)">
      %9 = cute.static : !cute.stride<"((1@1,1@0),0,32@0,128@1,128@0,1@2)">
      %10 = cute.static : !cute.stride<"(1@1,1@0,0,32@0,128@1,128@0,1@2)">
      %c1024_i32 = arith.constant 1024 : i32
      %c2097152_i32 = arith.constant 2097152 : i32
      %c256_i32 = arith.constant 256 : i32
      %c14_i32 = arith.constant 14 : i32
      %c13_i32 = arith.constant 13 : i32
      %c136314896_i32 = arith.constant 136314896 : i32
      %11 = cute.static : !cute.layout<"(1,1,4,6):(0,0,2,1024)">
      %12 = cute.static : !cute.layout<"((128,128),1,1,2):((65536,1),0,0,128)">
      %13 = cute.static : !cute.layout<"((8192,1),6):((1,0),8192)">
      %c32768_i32 = arith.constant 32768 : i32
      %c10000000_i32 = arith.constant 10000000 : i32
      %14 = cute.static : !cute.stride<"(((1@0,1@1),0),64@0)">
      %true = arith.constant true
      %c160_i32 = arith.constant 160 : i32
      %c3_i32 = arith.constant 3 : i32
      %15 = cute.static : !cute.layout<"(2,3,2):(6,2,1)">
      %16 = cute.static : !cute.coord<"2">
      %c31_i32 = arith.constant 31 : i32
      %c16_i32 = arith.constant 16 : i32
      %c8_i32 = arith.constant 8 : i32
      %17 = cute.static : !cute.coord<"1">
      %18 = cute.static : !cute.coord<"0">
      %19 = cute.static : !cute.layout<"(2,4):(4,1)">
      %c-1_i32 = arith.constant -1 : i32
      %false = arith.constant false
      %20 = cute.static : !cute.layout<"(1,3,16):(48,16,1)">
      %21 = cute.static : !cute.stride<"(((1@0,1@1),0),128@1,64@0,1@2)">
      %22 = cute.static : !cute.stride<"(((1@1,1@0),0,16@0),128@1,64@0,1@2)">
      %23 = cute.static : !cute.stride<"((1@1,1@0),0,0,128@1,128@0,1@2)">
      %24 = cute.static : !cute.stride<"((1@1,1@0),0,16@0,128@1,64@0,1@2)">
      %25 = cute.static : !cute.stride<"(1@1,1@0,128@1,128@0,1@2)">
      %26 = cute.static : !cute.stride<"((1@1,1@0),(128@1,128@0,1@2))">
      %27 = cute.static : !cute.int_tuple<"(0,0,0)">
      %28 = cute.static : !cute.stride<"(1@1,1@0,128@1,64@0,1@2)">
      %29 = cute.static : !cute.stride<"((1@1,1@0),(128@1,64@0,1@2))">
      %c64_i32 = arith.constant 64 : i32
      %c128_i32 = arith.constant 128 : i32
      %c2_i32 = arith.constant 2 : i32
      %c4_i32 = arith.constant 4 : i32
      %c6_i32 = arith.constant 6 : i32
      %30 = cute.static : !cute.int_tuple<"16">
      %31 = cute.static : !cute.int_tuple<"132096">
      %32 = cute.static : !cute.int_tuple<"33792">
      %33 = cute.static : !cute.int_tuple<"1024">
      %34 = cute.static : !cute.int_tuple<"520">
      %35 = cute.static : !cute.int_tuple<"496">
      %36 = cute.static : !cute.int_tuple<"480">
      %37 = cute.static : !cute.int_tuple<"432">
      %38 = cute.static : !cute.int_tuple<"384">
      %c0_i32 = arith.constant 0 : i32
      %c5_i32 = arith.constant 5 : i32
      %c32_i32 = arith.constant 32 : i32
      %c1_i32 = arith.constant 1 : i32
      %39 = cute.static : !cute.int_tuple<"1">
      %int_tuple = cute.make_int_tuple(%arg7) : (i32) -> !cute.int_tuple<"(1,1,?)">
      %40 = cute.get_scalars(%int_tuple) <{only_dynamic}> : !cute.int_tuple<"(1,1,?)">
      %int_tuple_0 = cute.make_int_tuple(%40) : (i32) -> !cute.int_tuple<"(1,1,?)">
      %e0, %e1, %e2 = cute.get_leaves(%int_tuple_0) : !cute.int_tuple<"(1,1,?)">
      %shape = cute.make_shape(%e2) : (!cute.int_tuple<"?">) -> !cute.shape<"(1,1,?)">
      %lay = cute.make_layout(%shape) : !cute.layout<"(1,1,?):(0,0,1)">
      %41 = nvvm.read.ptx.sreg.tid.x range <i32, 0, 1024> : i32
      %42 = nvvm.read.ptx.sreg.tid.y range <i32, 0, 1024> : i32
      %43 = nvvm.read.ptx.sreg.tid.z range <i32, 0, 64> : i32
      %44 = nvvm.read.ptx.sreg.ntid.x range <i32, 1, 1024> : i32
      %45 = nvvm.read.ptx.sreg.ntid.y range <i32, 1, 1024> : i32
      %46 = arith.muli %42, %44 : i32
      %47 = arith.addi %41, %46 : i32
      %48 = arith.muli %43, %44 : i32
      %49 = arith.muli %48, %45 : i32
      %50 = arith.addi %47, %49 : i32
      %51 = arith.floordivsi %50, %c32_i32 : i32
      %52 = cute_nvgpu.arch.make_warp_uniform(%51) : i32
      %53 = arith.cmpi eq, %52, %c5_i32 : i32
      cf.cond_br %53, ^bb1, ^bb2
    ^bb1:  // pred: ^bb0
      cute_nvgpu.prefetch_tma_desc(%arg1) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>) -> ()
      cute_nvgpu.prefetch_tma_desc(%arg3) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>) -> ()
      cute_nvgpu.prefetch_tma_desc(%arg5) : (!cute_nvgpu.atom.non_exec_tiled_tma_store<f16, copy_bits = 65536, tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>) -> ()
      cf.br ^bb2
    ^bb2:  // 2 preds: ^bb0, ^bb1
      %54 = nvvm.read.ptx.sreg.ctaid.x range <i32, 0, 2147483647> : i32
      %55 = nvvm.read.ptx.sreg.ctaid.y range <i32, 0, 65535> : i32
      %56 = nvvm.read.ptx.sreg.ctaid.z range <i32, 0, 65535> : i32
      %smem_ptr = cute_nvgpu.arch.get_dyn_smem() : !cute.ptr<i8, smem, align<1024>>
      %ptr = cute.add_offset(%smem_ptr, %38) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"384">) -> !cute.ptr<i8, smem, align<128>>
      %ptr_1 = cute.add_offset(%smem_ptr, %37) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"432">) -> !cute.ptr<i8, smem, align<16>>
      %ptr_2 = cute.add_offset(%smem_ptr, %36) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"480">) -> !cute.ptr<i8, smem, align<32>>
      %ptr_3 = cute.add_offset(%smem_ptr, %35) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"496">) -> !cute.ptr<i8, smem, align<16>>
      %ptr_4 = cute.add_offset(%smem_ptr, %34) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"520">) -> !cute.ptr<i8, smem, align<8>>
      %iter = cute.recast_iter(%ptr_4) : !cute.ptr<i8, smem, align<8>> to !cute.ptr<i32, smem, align<8>>
      %ptr_5 = cute.add_offset(%smem_ptr, %33) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"1024">) -> !cute.ptr<i8, smem, align<1024>>
      %ptr_6 = cute.add_offset(%smem_ptr, %32) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"33792">) -> !cute.ptr<i8, smem, align<1024>>
      %ptr_7 = cute.add_offset(%smem_ptr, %31) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"132096">) -> !cute.ptr<i8, smem, align<1024>>
      %iter_8 = cute.recast_iter(%smem_ptr) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<i64, smem, align<1024>>
      %ptr_9 = cute.add_offset(%iter_8, %30) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"16">) -> !cute.ptr<i64, smem, align<128>>
      %int_tuple_10 = cute.make_int_tuple() : () -> !cute.int_tuple<"32">
      %ptr_11 = cute.add_offset(%iter_8, %int_tuple_10) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"32">) -> !cute.ptr<i64, smem, align<256>>
      %dyn = cute.derefine(%ptr_11) : !cute.ptr<i64, smem, align<256>> to !cute.ptr<i64, smem, align<128>>
      %iter_12 = cute.recast_iter(%ptr) : !cute.ptr<i8, smem, align<128>> to !cute.ptr<i64, smem, align<128>>
      %iter_13 = cute.recast_iter(%ptr_1) : !cute.ptr<i8, smem, align<16>> to !cute.ptr<i64, smem, align<16>>
      %iter_14 = cute.recast_iter(%ptr_2) : !cute.ptr<i8, smem, align<32>> to !cute.ptr<i64, smem, align<32>>
      %iter_15 = cute.recast_iter(%ptr_3) : !cute.ptr<i8, smem, align<16>> to !cute.ptr<i64, smem, align<16>>
      %57 = arith.cmpi eq, %52, %c0_i32 : i32
      cf.cond_br %57, ^bb3, ^bb9
    ^bb3:  // pred: ^bb2
      cf.br ^bb4(%c0_i32 : i32)
    ^bb4(%58: i32):  // 2 preds: ^bb3, ^bb7
      %59 = arith.cmpi slt, %58, %c6_i32 : i32
      cf.cond_br %59, ^bb5, ^bb8
    ^bb5:  // pred: ^bb4
      %60 = nvvm.elect.sync -> i1
      cf.cond_br %60, ^bb6, ^bb7
    ^bb6:  // pred: ^bb5
      %int_tuple_16 = cute.make_int_tuple(%58) : (i32) -> !cute.int_tuple<"?">
      %ptr_17 = cute.add_offset(%iter_12, %int_tuple_16) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %61 = builtin.unrealized_conversion_cast %ptr_17 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %61, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_18 = cute.add_offset(%iter_13, %int_tuple_16) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %62 = builtin.unrealized_conversion_cast %ptr_18 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %62, %c1_i32 : !llvm.ptr<3>, i32
      cf.br ^bb7
    ^bb7:  // 2 preds: ^bb5, ^bb6
      %63 = arith.addi %58, %c1_i32 : i32
      cf.br ^bb4(%63 : i32)
    ^bb8:  // pred: ^bb4
      cf.br ^bb9
    ^bb9:  // 2 preds: ^bb2, ^bb8
      %64 = arith.cmpi eq, %52, %c4_i32 : i32
      cf.cond_br %64, ^bb10, ^bb16
    ^bb10:  // pred: ^bb9
      cf.br ^bb11(%c0_i32 : i32)
    ^bb11(%65: i32):  // 2 preds: ^bb10, ^bb14
      %66 = arith.cmpi slt, %65, %c2_i32 : i32
      cf.cond_br %66, ^bb12, ^bb15
    ^bb12:  // pred: ^bb11
      %67 = nvvm.elect.sync -> i1
      cf.cond_br %67, ^bb13, ^bb14
    ^bb13:  // pred: ^bb12
      %int_tuple_19 = cute.make_int_tuple(%65) : (i32) -> !cute.int_tuple<"?">
      %ptr_20 = cute.add_offset(%iter_14, %int_tuple_19) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %68 = builtin.unrealized_conversion_cast %ptr_20 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %68, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_21 = cute.add_offset(%iter_15, %int_tuple_19) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %69 = builtin.unrealized_conversion_cast %ptr_21 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %69, %c4_i32 : !llvm.ptr<3>, i32
      cf.br ^bb14
    ^bb14:  // 2 preds: ^bb12, ^bb13
      %70 = arith.addi %65, %c1_i32 : i32
      cf.br ^bb11(%70 : i32)
    ^bb15:  // pred: ^bb11
      cf.br ^bb16
    ^bb16:  // 2 preds: ^bb9, ^bb15
      nvvm.fence.mbarrier.init
      %iter_22 = cute.recast_iter(%ptr_5) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<f16, smem, align<1024>, S<2,4,3>>
      %iter_23 = cute.recast_iter(%ptr_6) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<f16, smem, align<1024>, S<3,4,3>>
      %iter_24 = cute.recast_iter(%ptr_7) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<f16, smem, align<1024>, S<3,4,3>>
      %lay_25 = cute.get_layout(%arg2) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">
      %71:3 = cute.get_scalars(%lay_25) <{only_dynamic}> : !cute.layout<"(?,?,?):(1@1,1@0,1@2)">
      %72 = arith.ceildivsi %71#0, %c128_i32 : i32
      %73 = arith.ceildivsi %71#1, %c64_i32 : i32
      %shape_26 = cute.make_shape(%72, %73, %71#2) : (i32, i32, i32) -> !cute.shape<"((128,64),(?,?,?))">
      %lay_27 = cute.make_layout(%shape_26, %29) : !cute.layout<"((128,64),(?,?,?)):((1@1,1@0),(128@1,64@0,1@2))">
      %74:3 = cute.get_scalars(%lay_27) <{only_dynamic}> : !cute.layout<"((128,64),(?,?,?)):((1@1,1@0),(128@1,64@0,1@2))">
      %shape_28 = cute.make_shape(%74#0, %74#1, %74#2) : (i32, i32, i32) -> !cute.shape<"(128,64,?,?,?)">
      %lay_29 = cute.make_layout(%shape_28, %28) : !cute.layout<"(128,64,?,?,?):(1@1,1@0,128@1,64@0,1@2)">
      %lay_30 = cute.get_layout(%arg4) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">
      %75:3 = cute.get_scalars(%lay_30) <{only_dynamic}> : !cute.layout<"(?,?,?):(1@1,1@0,1@2)">
      %76 = arith.ceildivsi %75#0, %c128_i32 : i32
      %77 = arith.ceildivsi %75#1, %c64_i32 : i32
      %shape_31 = cute.make_shape(%76, %77, %75#2) : (i32, i32, i32) -> !cute.shape<"((128,64),(?,?,?))">
      %lay_32 = cute.make_layout(%shape_31, %29) : !cute.layout<"((128,64),(?,?,?)):((1@1,1@0),(128@1,64@0,1@2))">
      %78:3 = cute.get_scalars(%lay_32) <{only_dynamic}> : !cute.layout<"((128,64),(?,?,?)):((1@1,1@0),(128@1,64@0,1@2))">
      %shape_33 = cute.make_shape(%78#0, %78#1, %78#2) : (i32, i32, i32) -> !cute.shape<"(128,64,?,?,?)">
      %lay_34 = cute.make_layout(%shape_33, %28) : !cute.layout<"(128,64,?,?,?):(1@1,1@0,128@1,64@0,1@2)">
      %lay_35 = cute.get_layout(%arg6) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">
      %79:3 = cute.get_scalars(%lay_35) <{only_dynamic}> : !cute.layout<"(?,?,?):(1@1,1@0,1@2)">
      %80 = arith.ceildivsi %79#0, %c128_i32 : i32
      %81 = arith.ceildivsi %79#1, %c128_i32 : i32
      %shape_36 = cute.make_shape(%80, %81, %79#2) : (i32, i32, i32) -> !cute.shape<"((128,128),(?,?,?))">
      %lay_37 = cute.make_layout(%shape_36, %26) : !cute.layout<"((128,128),(?,?,?)):((1@1,1@0),(128@1,128@0,1@2))">
      %82:3 = cute.get_scalars(%lay_37) <{only_dynamic}> : !cute.layout<"((128,128),(?,?,?)):((1@1,1@0),(128@1,128@0,1@2))">
      %shape_38 = cute.make_shape(%82#0, %82#1, %82#2) : (i32, i32, i32) -> !cute.shape<"(128,128,?,?,?)">
      %lay_39 = cute.make_layout(%shape_38, %25) : !cute.layout<"(128,128,?,?,?):(1@1,1@0,128@1,128@0,1@2)">
      %83:3 = cute.get_scalars(%lay_29) <{only_dynamic}> : !cute.layout<"(128,64,?,?,?):(1@1,1@0,128@1,64@0,1@2)">
      %shape_40 = cute.make_shape(%83#0, %83#1, %83#2) : (i32, i32, i32) -> !cute.shape<"((128,16),1,4,?,?,?)">
      %lay_41 = cute.make_layout(%shape_40, %24) : !cute.layout<"((128,16),1,4,?,?,?):((1@1,1@0),0,16@0,128@1,64@0,1@2)">
      %84:3 = cute.get_scalars(%lay_34) <{only_dynamic}> : !cute.layout<"(128,64,?,?,?):(1@1,1@0,128@1,64@0,1@2)">
      %shape_42 = cute.make_shape(%84#0, %84#1, %84#2) : (i32, i32, i32) -> !cute.shape<"((128,16),1,4,?,?,?)">
      %lay_43 = cute.make_layout(%shape_42, %24) : !cute.layout<"((128,16),1,4,?,?,?):((1@1,1@0),0,16@0,128@1,64@0,1@2)">
      %85:3 = cute.get_scalars(%lay_39) <{only_dynamic}> : !cute.layout<"(128,128,?,?,?):(1@1,1@0,128@1,128@0,1@2)">
      %shape_44 = cute.make_shape(%85#0, %85#1, %85#2) : (i32, i32, i32) -> !cute.shape<"((128,128),1,1,?,?,?)">
      %lay_45 = cute.make_layout(%shape_44, %23) : !cute.layout<"((128,128),1,1,?,?,?):((1@1,1@0),0,0,128@1,128@0,1@2)">
      %86:3 = cute.get_scalars(%lay_41) <{only_dynamic}> : !cute.layout<"((128,16),1,4,?,?,?):((1@1,1@0),0,16@0,128@1,64@0,1@2)">
      %shape_46 = cute.make_shape(%86#0, %86#1, %86#2) : (i32, i32, i32) -> !cute.shape<"(((128,16),1,4),?,?,?)">
      %lay_47 = cute.make_layout(%shape_46, %22) : !cute.layout<"(((128,16),1,4),?,?,?):(((1@1,1@0),0,16@0),128@1,64@0,1@2)">
      %87:3 = cute.get_scalars(%lay_47) <{only_dynamic}> : !cute.layout<"(((128,16),1,4),?,?,?):(((1@1,1@0),0,16@0),128@1,64@0,1@2)">
      %shape_48 = cute.make_shape(%87#0, %87#1, %87#2) : (i32, i32, i32) -> !cute.shape<"(((64,128),1),?,?,?)">
      %lay_49 = cute.make_layout(%shape_48, %21) : !cute.layout<"(((64,128),1),?,?,?):(((1@0,1@1),0),128@1,64@0,1@2)">
      %88:3 = cute.get_scalars(%lay_43) <{only_dynamic}> : !cute.layout<"((128,16),1,4,?,?,?):((1@1,1@0),0,16@0,128@1,64@0,1@2)">
      %shape_50 = cute.make_shape(%88#0, %88#1, %88#2) : (i32, i32, i32) -> !cute.shape<"(((128,16),1,4),?,?,?)">
      %lay_51 = cute.make_layout(%shape_50, %22) : !cute.layout<"(((128,16),1,4),?,?,?):(((1@1,1@0),0,16@0),128@1,64@0,1@2)">
      %89:3 = cute.get_scalars(%lay_51) <{only_dynamic}> : !cute.layout<"(((128,16),1,4),?,?,?):(((1@1,1@0),0,16@0),128@1,64@0,1@2)">
      %shape_52 = cute.make_shape(%89#0, %89#1, %89#2) : (i32, i32, i32) -> !cute.shape<"(((64,128),1),?,?,?)">
      %lay_53 = cute.make_layout(%shape_52, %21) : !cute.layout<"(((64,128),1),?,?,?):(((1@0,1@1),0),128@1,64@0,1@2)">
      %ummaSmemDesc = cute_nvgpu.make_umma_smem_desc(%iter_23 : !cute.ptr<f16, smem, align<1024>, S<3,4,3>>) layout = <"((128,16),1,4,6):((64,1),0,16,8192)">, major = <k> -> !cute_nvgpu.smem_desc
      %ummaSmemDesc_54 = cute_nvgpu.make_umma_smem_desc(%iter_24 : !cute.ptr<f16, smem, align<1024>, S<3,4,3>>) layout = <"((128,16),1,4,6):((64,1),0,16,8192)">, major = <k> -> !cute_nvgpu.smem_desc
      nvvm.barrier
      %90 = nvvm.read.ptx.sreg.nctaid.x range <i32, 1, 2147483647> : i32
      %91 = nvvm.read.ptx.sreg.nctaid.y range <i32, 1, 65535> : i32
      %92 = nvvm.read.ptx.sreg.nctaid.z range <i32, 1, 65535> : i32
      %93 = arith.muli %56, %91 : i32
      %94 = arith.muli %93, %90 : i32
      %95 = arith.muli %55, %90 : i32
      %96 = arith.addi %94, %95 : i32
      %97 = arith.addi %96, %54 : i32
      %coord = cute.make_coord(%97) : (i32) -> !cute.coord<"(?,0,_)">
      %idx = cute.crd2idx(%coord, %20) : (!cute.coord<"(?,0,_)">, !cute.layout<"(1,3,16):(48,16,1)">) -> !cute.int_tuple<"?{div=48}">
      %iter_55 = cute.get_iter(%arg14) : !memref_gmem_i64_1
      %ptr_56 = cute.add_offset(%iter_55, %idx) : (!cute.ptr<i64, gmem>, !cute.int_tuple<"?{div=48}">) -> !cute.ptr<i64, gmem>
      %98 = cute.ptrtoint(%ptr_56) : !cute.ptr<i64, gmem> to i64
      %iv = cute.assume(%98) : (i64) -> !cute.i64<divby 128>
      %99 = cute.inttoptr(%iv) : !cute.i64<divby 128> to !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, gmem, align<128>>
      %coord_57 = cute.make_coord(%97) : (i32) -> !cute.coord<"(?,1,_)">
      %idx_58 = cute.crd2idx(%coord_57, %20) : (!cute.coord<"(?,1,_)">, !cute.layout<"(1,3,16):(48,16,1)">) -> !cute.int_tuple<"?{div=16}">
      %ptr_59 = cute.add_offset(%iter_55, %idx_58) : (!cute.ptr<i64, gmem>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<i64, gmem>
      %100 = cute.ptrtoint(%ptr_59) : !cute.ptr<i64, gmem> to i64
      %iv_60 = cute.assume(%100) : (i64) -> !cute.i64<divby 128>
      %101 = cute.inttoptr(%iv_60) : !cute.i64<divby 128> to !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, gmem, align<128>>
      %coord_61 = cute.make_coord(%97) : (i32) -> !cute.coord<"(?,2,_)">
      %idx_62 = cute.crd2idx(%coord_61, %20) : (!cute.coord<"(?,2,_)">, !cute.layout<"(1,3,16):(48,16,1)">) -> !cute.int_tuple<"?{div=16}">
      %ptr_63 = cute.add_offset(%iter_55, %idx_62) : (!cute.ptr<i64, gmem>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<i64, gmem>
      %102 = cute.ptrtoint(%ptr_63) : !cute.ptr<i64, gmem> to i64
      %iv_64 = cute.assume(%102) : (i64) -> !cute.i64<divby 128>
      %103 = cute.inttoptr(%iv_64) : !cute.i64<divby 128> to !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, gmem, align<128>>
      cf.cond_br %53, ^bb17, ^bb97
    ^bb17:  // pred: ^bb16
      %int_tuple_65 = cute.make_int_tuple(%90, %91, %92) : (i32, i32, i32) -> !cute.int_tuple<"(?,?,?)">
      %sz = cute.size(%int_tuple_65) : (!cute.int_tuple<"(?,?,?)">) -> !cute.int_tuple<"?">
      %e0_66 = cute.get_leaves(%sz) : !cute.int_tuple<"?">
      %div = cute.tuple_div(%e0_66, %39) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %104 = cute.get_scalars(%div) : !cute.int_tuple<"?">
      %sz_67 = cute.size(%lay) : (!cute.layout<"(1,1,?):(0,0,1)">) -> !cute.int_tuple<"?">
      %e0_68 = cute.get_leaves(%sz_67) : !cute.int_tuple<"?">
      %105 = cute.get_scalars(%e0_68) : !cute.int_tuple<"?">
      %106 = arith.cmpi sgt, %105, %56 : i32
      %107 = cute.fast_divmod.get_divisor(%arg8) : !cute.fast_divmod_divisor<32>
      %multiplier, %shift1, %shift2 = cute.fast_divmod.get_aux(%arg8) : !cute.fast_divmod_divisor<32> -> (i32, i8)
      %108 = arith.extui %shift1 : i8 to i32
      %109 = arith.extui %shift2 : i8 to i32
      %110 = nvvm.mul  hi %56, %multiplier : i32 -> i32
      %111 = arith.subi %56, %110 : i32
      %112 = arith.shrui %111, %108 : i32
      %113 = arith.addi %110, %112 : i32
      %114 = arith.shrui %113, %109 : i32
      %115 = arith.muli %114, %107 : i32
      %116 = arith.subi %56, %115 : i32
      %117 = cute.fast_divmod.get_divisor(%arg9) : !cute.fast_divmod_divisor<32>
      %multiplier_69, %shift1_70, %shift2_71 = cute.fast_divmod.get_aux(%arg9) : !cute.fast_divmod_divisor<32> -> (i32, i8)
      %118 = arith.extui %shift1_70 : i8 to i32
      %119 = arith.extui %shift2_71 : i8 to i32
      %120 = nvvm.mul  hi %116, %multiplier_69 : i32 -> i32
      %121 = arith.subi %116, %120 : i32
      %122 = arith.shrui %121, %118 : i32
      %123 = arith.addi %120, %122 : i32
      %124 = arith.shrui %123, %119 : i32
      %125 = arith.muli %124, %117 : i32
      %126 = arith.subi %116, %125 : i32
      %127 = cute.fast_divmod.get_divisor(%arg10) : !cute.fast_divmod_divisor<32>
      %multiplier_72, %shift1_73, %shift2_74 = cute.fast_divmod.get_aux(%arg10) : !cute.fast_divmod_divisor<32> -> (i32, i8)
      %128 = arith.extui %shift1_73 : i8 to i32
      %129 = arith.extui %shift2_74 : i8 to i32
      %130 = nvvm.mul  hi %124, %multiplier_72 : i32 -> i32
      %131 = arith.subi %124, %130 : i32
      %132 = arith.shrui %131, %128 : i32
      %133 = arith.addi %130, %132 : i32
      %134 = arith.shrui %133, %129 : i32
      %135 = arith.muli %134, %127 : i32
      %136 = arith.subi %124, %135 : i32
      %int_tuple_75 = cute.make_int_tuple(%126) : (i32) -> !cute.int_tuple<"?">
      %mul = cute.tuple_mul(%int_tuple_75, %39) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %137 = cute.get_scalars(%mul) : !cute.int_tuple<"?">
      %int_tuple_76 = cute.make_int_tuple(%136) : (i32) -> !cute.int_tuple<"?">
      %mul_77 = cute.tuple_mul(%int_tuple_76, %39) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %138 = cute.get_scalars(%mul_77) : !cute.int_tuple<"?">
      %int_tuple_78 = cute.make_int_tuple(%134) : (i32) -> !cute.int_tuple<"?">
      %mul_79 = cute.tuple_mul(%int_tuple_78, %39) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %139 = cute.get_scalars(%mul_79) : !cute.int_tuple<"?">
      %140 = nvvm.read.ptx.sreg.laneid range <i32, 0, 32> : i32
      %141 = arith.cmpi sge, %140, %c1_i32 : i32
      %142 = arith.cmpi sge, %140, %c2_i32 : i32
      %143 = arith.cmpi sge, %140, %c4_i32 : i32
      %144 = arith.cmpi sge, %140, %c8_i32 : i32
      %145 = arith.cmpi sge, %140, %c16_i32 : i32
      %iter_80 = cute.get_iter(%arg11) : !memref_gmem_i32_
      %146 = cute.get_scalars(%39) : !cute.int_tuple<"1">
      %147:3 = cute.get_scalars(%lay_49) <{only_dynamic}> : !cute.layout<"(((64,128),1),?,?,?):(((1@0,1@1),0),128@1,64@0,1@2)">
      %shape_81 = cute.make_shape(%147#1) : (i32) -> !cute.shape<"(((64,128),1),?)">
      %lay_82 = cute.make_layout(%shape_81, %14) : !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">
      %148:3 = cute.get_scalars(%lay_53) <{only_dynamic}> : !cute.layout<"(((64,128),1),?,?,?):(((1@0,1@1),0),128@1,64@0,1@2)">
      %shape_83 = cute.make_shape(%148#1) : (i32) -> !cute.shape<"(((64,128),1),?)">
      %lay_84 = cute.make_layout(%shape_83, %14) : !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">
      %149 = cute.ptrtoint(%99) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, gmem, align<128>> to i64
      %iv_85 = cute.assume(%149) : (i64) -> !cute.i64<divby 128>
      %150 = cute.inttoptr(%iv_85) : !cute.i64<divby 128> to !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<128>>
      %151 = cute_nvgpu.atom.make_exec_tma(%arg1) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>
      %152 = cute.ptrtoint(%101) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, gmem, align<128>> to i64
      %iv_86 = cute.assume(%152) : (i64) -> !cute.i64<divby 128>
      %153 = cute.inttoptr(%iv_86) : !cute.i64<divby 128> to !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<128>>
      %154 = cute_nvgpu.atom.make_exec_tma(%arg3) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>
      cf.br ^bb18(%false, %c0_i32, %137, %138, %139, %106, %c-1_i32, %c0_i32, %c0_i32, %56, %c0_i32 : i1, i32, i32, i32, i32, i1, i32, i32, i32, i32, i32)
    ^bb18(%155: i1, %156: i32, %157: i32, %158: i32, %159: i32, %160: i1, %161: i32, %162: i32, %163: i32, %164: i32, %165: i32):  // 2 preds: ^bb17, ^bb95
      cf.cond_br %160, ^bb19(%155, %156, %157, %158, %159, %161, %162, %163, %164, %165 : i1, i32, i32, i32, i32, i32, i32, i32, i32, i32), ^bb96
    ^bb19(%166: i1, %167: i32, %168: i32, %169: i32, %170: i32, %171: i32, %172: i32, %173: i32, %174: i32, %175: i32):  // pred: ^bb18
      %176 = arith.cmpi sge, %170, %173 : i32
      cf.br ^bb20(%176, %172, %173, %173 : i1, i32, i32, i32)
    ^bb20(%177: i1, %178: i32, %179: i32, %180: i32):  // 2 preds: ^bb19, ^bb52
      cf.cond_br %177, ^bb21(%178, %179, %180 : i32, i32, i32), ^bb53
    ^bb21(%181: i32, %182: i32, %183: i32):  // pred: ^bb20
      %184 = arith.addi %181, %140 : i32
      %185 = arith.cmpi slt, %184, %c2_i32 : i32
      cf.cond_br %185, ^bb22, ^bb26
    ^bb22:  // pred: ^bb21
      %rmem = cute.memref.alloca() : !memref_rmem_i32_
      %coord_87 = cute.make_coord(%184) : (i32) -> !cute.coord<"(?,_)">
      %idx_88 = cute.crd2idx(%coord_87, %19) : (!cute.coord<"(?,_)">, !cute.layout<"(2,4):(4,1)">) -> !cute.int_tuple<"?{div=4}">
      %iter_89 = cute.get_iter(%arg11) : !memref_gmem_i32_
      %ptr_90 = cute.add_offset(%iter_89, %idx_88) : (!cute.ptr<i32, gmem, align<16>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<i32, gmem, align<16>>
      %iter_91 = cute.get_iter(%rmem) : !memref_rmem_i32_
      %186 = cute.get_scalars(%39) : !cute.int_tuple<"1">
      %187 = builtin.unrealized_conversion_cast %ptr_90 : !cute.ptr<i32, gmem, align<16>> to !llvm.ptr<1>
      %188 = builtin.unrealized_conversion_cast %iter_91 : !cute.ptr<i32, rmem, align<32>> to !llvm.ptr
      cf.br ^bb23(%c0_i32 : i32)
    ^bb23(%189: i32):  // 2 preds: ^bb22, ^bb24
      %190 = arith.cmpi slt, %189, %186 : i32
      cf.cond_br %190, ^bb24, ^bb25 {llvm.loop_annotation = #loop_annotation}
    ^bb24:  // pred: ^bb23
      %191 = llvm.load %187 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<4xi32>
      llvm.store %191, %188 {alignment = 16 : i64} : vector<4xi32>, !llvm.ptr
      %192 = arith.addi %189, %c1_i32 : i32
      cf.br ^bb23(%192 : i32)
    ^bb25:  // pred: ^bb23
      %193 = cute.memref.load(%rmem, %18) : (!memref_rmem_i32_, !cute.coord<"0">) -> i32
      %194 = arith.addi %193, %c127_i32 : i32
      %195 = arith.floordivsi %194, %c128_i32 : i32
      %196 = cute.memref.load(%rmem, %17) : (!memref_rmem_i32_, !cute.coord<"1">) -> i32
      %197 = arith.addi %196, %c127_i32 : i32
      %198 = arith.floordivsi %197, %c128_i32 : i32
      %199 = arith.muli %195, %198 : i32
      cf.br ^bb27(%199 : i32)
    ^bb26:  // pred: ^bb21
      cf.br ^bb27(%c0_i32 : i32)
    ^bb27(%200: i32):  // 2 preds: ^bb25, ^bb26
      cf.br ^bb28
    ^bb28:  // pred: ^bb27
      %201 = nvvm.shfl.sync  up %c-1_i32, %200, %c1_i32, %c0_i32 : i32 -> i32
      cf.cond_br %141, ^bb29, ^bb30
    ^bb29:  // pred: ^bb28
      %202 = arith.addi %200, %201 : i32
      cf.br ^bb31(%202 : i32)
    ^bb30:  // pred: ^bb28
      cf.br ^bb31(%200 : i32)
    ^bb31(%203: i32):  // 2 preds: ^bb29, ^bb30
      cf.br ^bb32
    ^bb32:  // pred: ^bb31
      %204 = nvvm.shfl.sync  up %c-1_i32, %203, %c2_i32, %c0_i32 : i32 -> i32
      cf.cond_br %142, ^bb33, ^bb34
    ^bb33:  // pred: ^bb32
      %205 = arith.addi %203, %204 : i32
      cf.br ^bb35(%205 : i32)
    ^bb34:  // pred: ^bb32
      cf.br ^bb35(%203 : i32)
    ^bb35(%206: i32):  // 2 preds: ^bb33, ^bb34
      cf.br ^bb36
    ^bb36:  // pred: ^bb35
      %207 = nvvm.shfl.sync  up %c-1_i32, %206, %c4_i32, %c0_i32 : i32 -> i32
      cf.cond_br %143, ^bb37, ^bb38
    ^bb37:  // pred: ^bb36
      %208 = arith.addi %206, %207 : i32
      cf.br ^bb39(%208 : i32)
    ^bb38:  // pred: ^bb36
      cf.br ^bb39(%206 : i32)
    ^bb39(%209: i32):  // 2 preds: ^bb37, ^bb38
      cf.br ^bb40
    ^bb40:  // pred: ^bb39
      %210 = nvvm.shfl.sync  up %c-1_i32, %209, %c8_i32, %c0_i32 : i32 -> i32
      cf.cond_br %144, ^bb41, ^bb42
    ^bb41:  // pred: ^bb40
      %211 = arith.addi %209, %210 : i32
      cf.br ^bb43(%211 : i32)
    ^bb42:  // pred: ^bb40
      cf.br ^bb43(%209 : i32)
    ^bb43(%212: i32):  // 2 preds: ^bb41, ^bb42
      cf.br ^bb44
    ^bb44:  // pred: ^bb43
      %213 = nvvm.shfl.sync  up %c-1_i32, %212, %c16_i32, %c0_i32 : i32 -> i32
      cf.cond_br %145, ^bb45, ^bb46
    ^bb45:  // pred: ^bb44
      %214 = arith.addi %212, %213 : i32
      cf.br ^bb47(%214 : i32)
    ^bb46:  // pred: ^bb44
      cf.br ^bb47(%212 : i32)
    ^bb47(%215: i32):  // 2 preds: ^bb45, ^bb46
      cf.br ^bb48
    ^bb48:  // pred: ^bb47
      %216 = arith.addi %215, %183 : i32
      %217 = arith.cmpi sge, %170, %216 : i32
      %218 = nvvm.vote.ballot.sync %c-1_i32, %217 : i32
      %219 = llvm.intr.ctpop(%218) : (i32) -> i32
      %220 = arith.cmpi eq, %219, %c32_i32 : i32
      %221 = arith.addi %219, %181 : i32
      %222 = arith.cmpi eq, %219, %c0_i32 : i32
      %223 = arith.cmpi eq, %222, %false : i1
      cf.cond_br %223, ^bb49, ^bb50
    ^bb49:  // pred: ^bb48
      %224 = arith.subi %219, %c1_i32 : i32
      %225 = nvvm.shfl.sync  idx %c-1_i32, %216, %224, %c31_i32 : i32 -> i32
      cf.br ^bb51(%225 : i32)
    ^bb50:  // pred: ^bb48
      cf.br ^bb51(%183 : i32)
    ^bb51(%226: i32):  // 2 preds: ^bb49, ^bb50
      cf.br ^bb52
    ^bb52:  // pred: ^bb51
      %227 = arith.select %220, %c31_i32, %219 : i32
      %228 = nvvm.shfl.sync  idx %c-1_i32, %216, %227, %c31_i32 : i32 -> i32
      cf.br ^bb20(%220, %221, %226, %228 : i1, i32, i32, i32)
    ^bb53:  // pred: ^bb20
      %rmem_92 = cute.memref.alloca() : !memref_rmem_i32_
      %coord_93 = cute.make_coord(%178) : (i32) -> !cute.coord<"(?,_)">
      %idx_94 = cute.crd2idx(%coord_93, %19) : (!cute.coord<"(?,_)">, !cute.layout<"(2,4):(4,1)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_95 = cute.add_offset(%iter_80, %idx_94) : (!cute.ptr<i32, gmem, align<16>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<i32, gmem, align<16>>
      %iter_96 = cute.get_iter(%rmem_92) : !memref_rmem_i32_
      %229 = builtin.unrealized_conversion_cast %ptr_95 : !cute.ptr<i32, gmem, align<16>> to !llvm.ptr<1>
      %230 = builtin.unrealized_conversion_cast %iter_96 : !cute.ptr<i32, rmem, align<32>> to !llvm.ptr
      cf.br ^bb54(%c0_i32 : i32)
    ^bb54(%231: i32):  // 2 preds: ^bb53, ^bb55
      %232 = arith.cmpi slt, %231, %146 : i32
      cf.cond_br %232, ^bb55, ^bb56 {llvm.loop_annotation = #loop_annotation}
    ^bb55:  // pred: ^bb54
      %233 = llvm.load %229 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<4xi32>
      llvm.store %233, %230 {alignment = 16 : i64} : vector<4xi32>, !llvm.ptr
      %234 = arith.addi %231, %c1_i32 : i32
      cf.br ^bb54(%234 : i32)
    ^bb56:  // pred: ^bb54
      %235 = arith.subi %170, %179 : i32
      %236 = cute.memref.load(%rmem_92, %18) : (!memref_rmem_i32_, !cute.coord<"0">) -> i32
      %237 = cute.memref.load(%rmem_92, %17) : (!memref_rmem_i32_, !cute.coord<"1">) -> i32
      %238 = cute.memref.load(%rmem_92, %16) : (!memref_rmem_i32_, !cute.coord<"2">) -> i32
      %int_tuple_97 = cute.make_int_tuple(%236, %237, %238) : (i32, i32, i32) -> !cute.int_tuple<"(?,?,?)">
      %239:3 = cute.get_scalars(%int_tuple_97) <{only_dynamic}> : !cute.int_tuple<"(?,?,?)">
      %240 = arith.ceildivsi %239#0, %c128_i32 : i32
      %241 = arith.ceildivsi %239#1, %c128_i32 : i32
      %242 = arith.ceildivsi %239#2, %c64_i32 : i32
      %int_tuple_98 = cute.make_int_tuple(%240, %241, %242) : (i32, i32, i32) -> !cute.int_tuple<"(?,?,?)">
      %e0_99, %e1_100, %e2_101 = cute.get_leaves(%int_tuple_98) : !cute.int_tuple<"(?,?,?)">
      %243 = cute.get_scalars(%e2_101) : !cute.int_tuple<"?">
      %shape_102 = cute.make_shape(%e0_99, %e1_100) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.shape<"(?,?)">
      %lay_103 = cute.make_layout(%shape_102) : !cute.layout<"(?,?):(1,?)">
      %244 = cute.get_hier_coord(%235, %lay_103) : (i32, !cute.layout<"(?,?):(1,?)">) -> !cute.coord<"(?,?)">
      %e0_104, %e1_105 = cute.get_leaves(%244) : !cute.coord<"(?,?)">
      %itup = cute.to_int_tuple(%e0_104) : !cute.coord<"?"> to !cute.int_tuple<"?">
      %itup_106 = cute.to_int_tuple(%e1_105) : !cute.coord<"?"> to !cute.int_tuple<"?">
      %mul_107 = cute.tuple_mul(%itup, %39) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %int_tuple_108 = cute.make_int_tuple(%168) : (i32) -> !cute.int_tuple<"?">
      %tup = cute.add_offset(%mul_107, %int_tuple_108) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.int_tuple<"?">
      %mul_109 = cute.tuple_mul(%itup_106, %39) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %int_tuple_110 = cute.make_int_tuple(%169) : (i32) -> !cute.int_tuple<"?">
      %tup_111 = cute.add_offset(%mul_109, %int_tuple_110) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.int_tuple<"?">
      %245 = arith.cmpi ne, %178, %171 : i32
      cf.cond_br %245, ^bb57, ^bb70
    ^bb57:  // pred: ^bb56
      %coord_112 = cute.make_coord(%178) : (i32) -> !cute.coord<"(?,0)">
      %246 = cute.memref.load(%arg13, %coord_112) : (!memref_gmem_i64_, !cute.coord<"(?,0)">) -> i64
      %iv_113 = cute.assume(%246) : (i64) -> !cute.i64<divby 16>
      %247 = cute.inttoptr(%iv_113) : !cute.i64<divby 16> to !cute.ptr<f16, gmem, align<16>>
      %coord_114 = cute.make_coord(%178) : (i32) -> !cute.coord<"(?,0,_)">
      %idx_115 = cute.crd2idx(%coord_114, %15) : (!cute.coord<"(?,0,_)">, !cute.layout<"(2,3,2):(6,2,1)">) -> !cute.int_tuple<"?{div=6}">
      %iter_116 = cute.get_iter(%arg12) : !memref_gmem_i32_1
      %ptr_117 = cute.add_offset(%iter_116, %idx_115) : (!cute.ptr<i32, gmem, align<16>>, !cute.int_tuple<"?{div=6}">) -> !cute.ptr<i32, gmem, align<8>>
      %rmem_118 = cute.memref.alloca() : !memref_rmem_i32_1
      %iter_119 = cute.get_iter(%rmem_118) : !memref_rmem_i32_1
      %248 = builtin.unrealized_conversion_cast %ptr_117 : !cute.ptr<i32, gmem, align<8>> to !llvm.ptr<1>
      %249 = builtin.unrealized_conversion_cast %iter_119 : !cute.ptr<i32, rmem, align<32>> to !llvm.ptr
      cf.br ^bb58(%c0_i32 : i32)
    ^bb58(%250: i32):  // 2 preds: ^bb57, ^bb59
      %251 = arith.cmpi slt, %250, %146 : i32
      cf.cond_br %251, ^bb59, ^bb60 {llvm.loop_annotation = #loop_annotation}
    ^bb59:  // pred: ^bb58
      %252 = llvm.load %248 {alignment = 8 : i64} : !llvm.ptr<1> -> vector<2xi32>
      llvm.store %252, %249 {alignment = 8 : i64} : vector<2xi32>, !llvm.ptr
      %253 = arith.addi %250, %c1_i32 : i32
      cf.br ^bb58(%253 : i32)
    ^bb60:  // pred: ^bb58
      %254 = cute.memref.load(%rmem_118, %18) : (!memref_rmem_i32_1, !cute.coord<"0">) -> i32
      %255 = cute.memref.load(%rmem_118, %17) : (!memref_rmem_i32_1, !cute.coord<"1">) -> i32
      %shape_120 = cute.make_shape(%236, %238) : (i32, i32) -> !cute.shape<"(?,?,1)">
      %stride = cute.make_stride(%254, %255) : (i32, i32) -> !cute.stride<"(?,?,0)">
      %lay_121 = cute.make_layout(%shape_120, %stride) : !cute.layout<"(?,?,1):(?,?,0)">
      %view = cute.make_view(%247, %lay_121) : !memref_gmem_f16_
      %dyn_122 = cute.derefine(%view) : !memref_gmem_f16_ to !memref_gmem_f16_1
      %coord_123 = cute.make_coord(%178) : (i32) -> !cute.coord<"(?,1)">
      %256 = cute.memref.load(%arg13, %coord_123) : (!memref_gmem_i64_, !cute.coord<"(?,1)">) -> i64
      %iv_124 = cute.assume(%256) : (i64) -> !cute.i64<divby 16>
      %257 = cute.inttoptr(%iv_124) : !cute.i64<divby 16> to !cute.ptr<f16, gmem, align<16>>
      %coord_125 = cute.make_coord(%178) : (i32) -> !cute.coord<"(?,1,_)">
      %idx_126 = cute.crd2idx(%coord_125, %15) : (!cute.coord<"(?,1,_)">, !cute.layout<"(2,3,2):(6,2,1)">) -> !cute.int_tuple<"?{div=2}">
      %ptr_127 = cute.add_offset(%iter_116, %idx_126) : (!cute.ptr<i32, gmem, align<16>>, !cute.int_tuple<"?{div=2}">) -> !cute.ptr<i32, gmem, align<8>>
      %rmem_128 = cute.memref.alloca() : !memref_rmem_i32_1
      %iter_129 = cute.get_iter(%rmem_128) : !memref_rmem_i32_1
      %258 = builtin.unrealized_conversion_cast %ptr_127 : !cute.ptr<i32, gmem, align<8>> to !llvm.ptr<1>
      %259 = builtin.unrealized_conversion_cast %iter_129 : !cute.ptr<i32, rmem, align<32>> to !llvm.ptr
      cf.br ^bb61(%c0_i32 : i32)
    ^bb61(%260: i32):  // 2 preds: ^bb60, ^bb62
      %261 = arith.cmpi slt, %260, %146 : i32
      cf.cond_br %261, ^bb62, ^bb63 {llvm.loop_annotation = #loop_annotation}
    ^bb62:  // pred: ^bb61
      %262 = llvm.load %258 {alignment = 8 : i64} : !llvm.ptr<1> -> vector<2xi32>
      llvm.store %262, %259 {alignment = 8 : i64} : vector<2xi32>, !llvm.ptr
      %263 = arith.addi %260, %c1_i32 : i32
      cf.br ^bb61(%263 : i32)
    ^bb63:  // pred: ^bb61
      %264 = cute.memref.load(%rmem_128, %18) : (!memref_rmem_i32_1, !cute.coord<"0">) -> i32
      %265 = cute.memref.load(%rmem_128, %17) : (!memref_rmem_i32_1, !cute.coord<"1">) -> i32
      %shape_130 = cute.make_shape(%237, %238) : (i32, i32) -> !cute.shape<"(?,?,1)">
      %stride_131 = cute.make_stride(%264, %265) : (i32, i32) -> !cute.stride<"(?,?,0)">
      %lay_132 = cute.make_layout(%shape_130, %stride_131) : !cute.layout<"(?,?,1):(?,?,0)">
      %view_133 = cute.make_view(%257, %lay_132) : !memref_gmem_f16_
      %dyn_134 = cute.derefine(%view_133) : !memref_gmem_f16_ to !memref_gmem_f16_1
      %266 = arith.cmpi eq, %166, %false : i1
      %267 = arith.select %266, %true, %166 : i1
      cf.cond_br %266, ^bb64, ^bb65
    ^bb64:  // pred: ^bb63
      nvvm.barrier id = %c3_i32 number_of_threads = %c160_i32
      cf.br ^bb65
    ^bb65:  // 2 preds: ^bb63, ^bb64
      cf.cond_br %53, ^bb66, ^bb69
    ^bb66:  // pred: ^bb65
      cute_nvgpu.update_tma_desc(%arg1, %dyn_122, %iter_8) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>, !memref_gmem_f16_1, !cute.ptr<i64, smem, align<1024>>) -> ()
      cute_nvgpu.update_tma_desc(%arg3, %dyn_134, %ptr_9) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>, !memref_gmem_f16_1, !cute.ptr<i64, smem, align<128>>) -> ()
      %268 = nvvm.elect.sync -> i1
      cf.cond_br %268, ^bb67, ^bb68
    ^bb67:  // pred: ^bb66
      nvvm.cp.async.bulk.commit.group
      nvvm.cp.async.bulk.wait_group 0 {read}
      cf.br ^bb68
    ^bb68:  // 2 preds: ^bb66, ^bb67
      nvvm.bar.warp.sync %c-1_i32 : i32
      %269 = cute.ptrtoint(%99) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, gmem, align<128>> to i64
      %270 = cute.ptrtoint(%iter_8) : !cute.ptr<i64, smem, align<1024>> to i32
      llvm.inline_asm has_side_effects asm_dialect = att "tensormap.cp_fenceproxy.global.shared::cta.tensormap::generic.release.gpu.sync.aligned [$0], [$1], 128;", "l,r" %269, %270 : (i64, i32) -> ()
      %271 = cute.ptrtoint(%101) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, gmem, align<128>> to i64
      %272 = cute.ptrtoint(%ptr_9) : !cute.ptr<i64, smem, align<128>> to i32
      llvm.inline_asm has_side_effects asm_dialect = att "tensormap.cp_fenceproxy.global.shared::cta.tensormap::generic.release.gpu.sync.aligned [$0], [$1], 128;", "l,r" %271, %272 : (i64, i32) -> ()
      cf.br ^bb69
    ^bb69:  // 2 preds: ^bb65, ^bb68
      cf.br ^bb71(%267 : i1)
    ^bb70:  // pred: ^bb56
      cf.br ^bb71(%166 : i1)
    ^bb71(%273: i1):  // 2 preds: ^bb69, ^bb70
      cf.br ^bb72
    ^bb72:  // pred: ^bb71
      %div_135 = cute.tuple_div(%tup, %39) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_136 = cute.make_coord(%div_135) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,?,_,0)">
      %idx_137 = cute.crd2idx(%coord_136, %lay_49) : (!cute.coord<"(_,?,_,0)">, !cute.layout<"(((64,128),1),?,?,?):(((1@0,1@1),0),128@1,64@0,1@2)">) -> !cute.int_tuple<"(0,?{div=128},0)">
      %tup_138 = cute.add_offset(%27, %idx_137) : (!cute.int_tuple<"(0,0,0)">, !cute.int_tuple<"(0,?{div=128},0)">) -> !cute.int_tuple<"(0,?{div=128},0)">
      %coord_139 = cute.make_coord(%tup_111) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,?,_,0)">
      %idx_140 = cute.crd2idx(%coord_139, %lay_53) : (!cute.coord<"(_,?,_,0)">, !cute.layout<"(((64,128),1),?,?,?):(((1@0,1@1),0),128@1,64@0,1@2)">) -> !cute.int_tuple<"(0,?{div=128},0)">
      %tup_141 = cute.add_offset(%27, %idx_140) : (!cute.int_tuple<"(0,0,0)">, !cute.int_tuple<"(0,?{div=128},0)">) -> !cute.int_tuple<"(0,?{div=128},0)">
      %int_tuple_142 = cute.make_int_tuple(%167) : (i32) -> !cute.int_tuple<"?">
      %tup_143 = cute.add_offset(%int_tuple_142, %e2_101) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.int_tuple<"?">
      %274 = cute.get_scalars(%tup_143) : !cute.int_tuple<"?">
      %275 = arith.remsi %167, %c6_i32 : i32
      %276 = arith.floordivsi %167, %c6_i32 : i32
      %277 = arith.remsi %276, %c2_i32 : i32
      %278 = arith.xori %277, %c1_i32 : i32
      %279 = arith.cmpi sgt, %243, %c0_i32 : i32
      %int_tuple_144 = cute.make_int_tuple(%275) : (i32) -> !cute.int_tuple<"?">
      %ptr_145 = cute.add_offset(%iter_13, %int_tuple_144) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      cf.cond_br %279, ^bb73, ^bb74
    ^bb73:  // pred: ^bb72
      %280 = builtin.unrealized_conversion_cast %ptr_145 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      %281 = nvvm.mbarrier.wait.parity %280, %278 {kind = #nvvm.mbar_wait<try>} : !llvm.ptr<3>, i32 -> i1
      cf.br ^bb75(%281 : i1)
    ^bb74:  // pred: ^bb72
      cf.br ^bb75(%true : i1)
    ^bb75(%282: i1):  // 2 preds: ^bb73, ^bb74
      cf.br ^bb76
    ^bb76:  // pred: ^bb75
      cf.cond_br %245, ^bb77, ^bb78
    ^bb77:  // pred: ^bb76
      %283 = cute.ptrtoint(%99) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, gmem, align<128>> to i64
      llvm.inline_asm has_side_effects asm_dialect = att "fence.proxy.tensormap::generic.acquire.gpu [$0], 128;", "l" %283 : (i64) -> ()
      %284 = cute.ptrtoint(%101) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, gmem, align<128>> to i64
      llvm.inline_asm has_side_effects asm_dialect = att "fence.proxy.tensormap::generic.acquire.gpu [$0], 128;", "l" %284 : (i64) -> ()
      cf.br ^bb78
    ^bb78:  // 2 preds: ^bb76, ^bb77
      cf.br ^bb79(%c0_i32, %282, %c0_i32, %275, %278 : i32, i1, i32, i32, i32)
    ^bb79(%285: i32, %286: i1, %287: i32, %288: i32, %289: i32):  // 2 preds: ^bb78, ^bb94
      %290 = arith.cmpi slt, %285, %243 : i32
      cf.cond_br %290, ^bb80, ^bb95 {loop_annotation = #loop_annotation1}
    ^bb80:  // pred: ^bb79
      %291 = arith.addi %287, %c1_i32 : i32
      %292 = arith.addi %167, %291 : i32
      %293 = arith.remsi %292, %c6_i32 : i32
      %294 = arith.cmpi eq, %293, %c0_i32 : i32
      %295 = arith.xori %289, %c1_i32 : i32
      %296 = arith.select %294, %295, %289 : i32
      %int_tuple_146 = cute.make_int_tuple(%288) : (i32) -> !cute.int_tuple<"?">
      %ptr_147 = cute.add_offset(%iter_12, %int_tuple_146) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %297 = arith.extui %286 : i1 to i32
      %298 = arith.cmpi eq, %297, %c0_i32 : i32
      cf.cond_br %298, ^bb81, ^bb82
    ^bb81:  // pred: ^bb80
      %ptr_148 = cute.add_offset(%iter_13, %int_tuple_146) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %299 = builtin.unrealized_conversion_cast %ptr_148 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %299, %289, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      cf.br ^bb82
    ^bb82:  // 2 preds: ^bb80, ^bb81
      %300 = nvvm.elect.sync -> i1
      cf.cond_br %300, ^bb83, ^bb84
    ^bb83:  // pred: ^bb82
      %301 = builtin.unrealized_conversion_cast %ptr_147 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %301, %c32768_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
      cf.br ^bb84
    ^bb84:  // 2 preds: ^bb82, ^bb83
      %coord_149 = cute.make_coord(%287) : (i32) -> !cute.coord<"(_,?)">
      %idx_150 = cute.crd2idx(%coord_149, %lay_82) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
      %tup_151 = cute.add_offset(%tup_138, %idx_150) : (!cute.int_tuple<"(0,?{div=128},0)">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.int_tuple<"(?{div=64},?{div=128},0)">
      %e0_152, %e1_153, %e2_154 = cute.get_leaves(%tup_151) : !cute.int_tuple<"(?{div=64},?{div=128},0)">
      %coord_155 = cute.make_coord(%288) : (i32) -> !cute.coord<"(_,?)">
      %idx_156 = cute.crd2idx(%coord_155, %13) : (!cute.coord<"(_,?)">, !cute.layout<"((8192,1),6):((1,0),8192)">) -> !cute.int_tuple<"?{div=8192}">
      %ptr_157 = cute.add_offset(%iter_23, %idx_156) : (!cute.ptr<f16, smem, align<1024>, S<3,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<f16, smem, align<1024>, S<3,4,3>>
      %int_tuple_158 = cute.make_int_tuple(%e0_152, %e1_153) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=128}">) -> !cute.int_tuple<"(?{div=64},?{div=128},0)">
      %302 = cute_nvgpu.atom.set_value(%151, %ptr_147 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>
      %303 = cute_nvgpu.atom.set_value(%302, %150 : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<128>>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_descriptor_ptr>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>
      %304 = cute_nvgpu.atom.get_value(%303 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
      %305 = cute_nvgpu.atom.get_value(%303 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<cache_policy>} : i64
      %TMADescAddr = cute_nvgpu.get_tma_desc_addr(%303 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>) -> !cute.ptr<generic, align<64>>
      %306:3 = cute.get_scalars(%int_tuple_158) : !cute.int_tuple<"(?{div=64},?{div=128},0)">
      cf.br ^bb85(%c0_i32 : i32)
    ^bb85(%307: i32):  // 2 preds: ^bb84, ^bb86
      %308 = arith.cmpi slt, %307, %146 : i32
      cf.cond_br %308, ^bb86, ^bb87 {llvm.loop_annotation = #loop_annotation}
    ^bb86:  // pred: ^bb85
      cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr : !cute.ptr<generic, align<64>>, %ptr_157 : !cute.ptr<f16, smem, align<1024>, S<3,4,3>>, %304 : !cute.ptr<smem, align<8>>, [%306#0, %306#1, %306#2] : i32, i32, i32) cache_policy = %305 mode = <tiled> num_cta = 1 : i32
      %309 = arith.addi %307, %c1_i32 : i32
      cf.br ^bb85(%309 : i32)
    ^bb87:  // pred: ^bb85
      %idx_159 = cute.crd2idx(%coord_149, %lay_84) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
      %tup_160 = cute.add_offset(%tup_141, %idx_159) : (!cute.int_tuple<"(0,?{div=128},0)">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.int_tuple<"(?{div=64},?{div=128},0)">
      %e0_161, %e1_162, %e2_163 = cute.get_leaves(%tup_160) : !cute.int_tuple<"(?{div=64},?{div=128},0)">
      %ptr_164 = cute.add_offset(%iter_24, %idx_156) : (!cute.ptr<f16, smem, align<1024>, S<3,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<f16, smem, align<1024>, S<3,4,3>>
      %int_tuple_165 = cute.make_int_tuple(%e0_161, %e1_162) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=128}">) -> !cute.int_tuple<"(?{div=64},?{div=128},0)">
      %310 = cute_nvgpu.atom.set_value(%154, %ptr_147 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>
      %311 = cute_nvgpu.atom.set_value(%310, %153 : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<128>>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_descriptor_ptr>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>
      %312 = cute_nvgpu.atom.get_value(%311 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
      %313 = cute_nvgpu.atom.get_value(%311 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<cache_policy>} : i64
      %TMADescAddr_166 = cute_nvgpu.get_tma_desc_addr(%311 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>) -> !cute.ptr<generic, align<64>>
      %314:3 = cute.get_scalars(%int_tuple_165) : !cute.int_tuple<"(?{div=64},?{div=128},0)">
      cf.br ^bb88(%c0_i32 : i32)
    ^bb88(%315: i32):  // 2 preds: ^bb87, ^bb89
      %316 = arith.cmpi slt, %315, %146 : i32
      cf.cond_br %316, ^bb89, ^bb90 {llvm.loop_annotation = #loop_annotation}
    ^bb89:  // pred: ^bb88
      cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr_166 : !cute.ptr<generic, align<64>>, %ptr_164 : !cute.ptr<f16, smem, align<1024>, S<3,4,3>>, %312 : !cute.ptr<smem, align<8>>, [%314#0, %314#1, %314#2] : i32, i32, i32) cache_policy = %313 mode = <tiled> num_cta = 1 : i32
      %317 = arith.addi %315, %c1_i32 : i32
      cf.br ^bb88(%317 : i32)
    ^bb90:  // pred: ^bb88
      %318 = arith.cmpi sgt, %243, %291 : i32
      %int_tuple_167 = cute.make_int_tuple(%293) : (i32) -> !cute.int_tuple<"?">
      %ptr_168 = cute.add_offset(%iter_13, %int_tuple_167) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      cf.cond_br %318, ^bb91, ^bb92
    ^bb91:  // pred: ^bb90
      %319 = builtin.unrealized_conversion_cast %ptr_168 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      %320 = nvvm.mbarrier.wait.parity %319, %296 {kind = #nvvm.mbar_wait<try>} : !llvm.ptr<3>, i32 -> i1
      cf.br ^bb93(%320 : i1)
    ^bb92:  // pred: ^bb90
      cf.br ^bb93(%true : i1)
    ^bb93(%321: i1):  // 2 preds: ^bb91, ^bb92
      cf.br ^bb94
    ^bb94:  // pred: ^bb93
      %322 = arith.addi %285, %c1_i32 : i32
      cf.br ^bb79(%322, %321, %291, %293, %296 : i32, i1, i32, i32, i32)
    ^bb95:  // pred: ^bb79
      %323 = arith.addi %174, %104 : i32
      %324 = arith.addi %175, %c1_i32 : i32
      %325 = arith.cmpi sgt, %105, %323 : i32
      %326 = nvvm.mul  hi %323, %multiplier : i32 -> i32
      %327 = arith.subi %323, %326 : i32
      %328 = arith.shrui %327, %108 : i32
      %329 = arith.addi %326, %328 : i32
      %330 = arith.shrui %329, %109 : i32
      %331 = arith.muli %330, %107 : i32
      %332 = arith.subi %323, %331 : i32
      %333 = nvvm.mul  hi %332, %multiplier_69 : i32 -> i32
      %334 = arith.subi %332, %333 : i32
      %335 = arith.shrui %334, %118 : i32
      %336 = arith.addi %333, %335 : i32
      %337 = arith.shrui %336, %119 : i32
      %338 = arith.muli %337, %117 : i32
      %339 = arith.subi %332, %338 : i32
      %340 = nvvm.mul  hi %337, %multiplier_72 : i32 -> i32
      %341 = arith.subi %337, %340 : i32
      %342 = arith.shrui %341, %128 : i32
      %343 = arith.addi %340, %342 : i32
      %344 = arith.shrui %343, %129 : i32
      %345 = arith.muli %344, %127 : i32
      %346 = arith.subi %337, %345 : i32
      %int_tuple_169 = cute.make_int_tuple(%339) : (i32) -> !cute.int_tuple<"?">
      %mul_170 = cute.tuple_mul(%int_tuple_169, %39) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %347 = cute.get_scalars(%mul_170) : !cute.int_tuple<"?">
      %int_tuple_171 = cute.make_int_tuple(%346) : (i32) -> !cute.int_tuple<"?">
      %mul_172 = cute.tuple_mul(%int_tuple_171, %39) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %348 = cute.get_scalars(%mul_172) : !cute.int_tuple<"?">
      %int_tuple_173 = cute.make_int_tuple(%344) : (i32) -> !cute.int_tuple<"?">
      %mul_174 = cute.tuple_mul(%int_tuple_173, %39) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %349 = cute.get_scalars(%mul_174) : !cute.int_tuple<"?">
      cf.br ^bb18(%273, %274, %347, %348, %349, %325, %178, %178, %179, %323, %324 : i1, i32, i32, i32, i32, i1, i32, i32, i32, i32, i32)
    ^bb96:  // pred: ^bb18
      cf.br ^bb97
    ^bb97:  // 2 preds: ^bb16, ^bb96
      cf.cond_br %64, ^bb98, ^bb168
    ^bb98:  // pred: ^bb97
      nvvm.barrier id = %c2_i32 number_of_threads = %c160_i32
      %tmem_ptr = cute_nvgpu.arch.sm100.retrieve_tmem_ptr(%iter) : !cute.ptr<i32, smem, align<8>> -> !cute.ptr<f32, tmem, align<16>>
      %int_tuple_175 = cute.make_int_tuple(%90, %91, %92) : (i32, i32, i32) -> !cute.int_tuple<"(?,?,?)">
      %sz_176 = cute.size(%int_tuple_175) : (!cute.int_tuple<"(?,?,?)">) -> !cute.int_tuple<"?">
      %e0_177 = cute.get_leaves(%sz_176) : !cute.int_tuple<"?">
      %div_178 = cute.tuple_div(%e0_177, %39) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %350 = cute.get_scalars(%div_178) : !cute.int_tuple<"?">
      %sz_179 = cute.size(%lay) : (!cute.layout<"(1,1,?):(0,0,1)">) -> !cute.int_tuple<"?">
      %e0_180 = cute.get_leaves(%sz_179) : !cute.int_tuple<"?">
      %351 = cute.get_scalars(%e0_180) : !cute.int_tuple<"?">
      %352 = arith.cmpi sgt, %351, %56 : i32
      %353 = cute.fast_divmod.get_divisor(%arg8) : !cute.fast_divmod_divisor<32>
      %multiplier_181, %shift1_182, %shift2_183 = cute.fast_divmod.get_aux(%arg8) : !cute.fast_divmod_divisor<32> -> (i32, i8)
      %354 = arith.extui %shift1_182 : i8 to i32
      %355 = arith.extui %shift2_183 : i8 to i32
      %356 = nvvm.mul  hi %56, %multiplier_181 : i32 -> i32
      %357 = arith.subi %56, %356 : i32
      %358 = arith.shrui %357, %354 : i32
      %359 = arith.addi %356, %358 : i32
      %360 = arith.shrui %359, %355 : i32
      %361 = arith.muli %360, %353 : i32
      %362 = arith.subi %56, %361 : i32
      %multiplier_184, %shift1_185, %shift2_186 = cute.fast_divmod.get_aux(%arg9) : !cute.fast_divmod_divisor<32> -> (i32, i8)
      %363 = arith.extui %shift1_185 : i8 to i32
      %364 = arith.extui %shift2_186 : i8 to i32
      %365 = nvvm.mul  hi %362, %multiplier_184 : i32 -> i32
      %366 = arith.subi %362, %365 : i32
      %367 = arith.shrui %366, %363 : i32
      %368 = arith.addi %365, %367 : i32
      %369 = arith.shrui %368, %364 : i32
      %multiplier_187, %shift1_188, %shift2_189 = cute.fast_divmod.get_aux(%arg10) : !cute.fast_divmod_divisor<32> -> (i32, i8)
      %370 = arith.extui %shift1_188 : i8 to i32
      %371 = arith.extui %shift2_189 : i8 to i32
      %372 = nvvm.mul  hi %369, %multiplier_187 : i32 -> i32
      %373 = arith.subi %369, %372 : i32
      %374 = arith.shrui %373, %370 : i32
      %375 = arith.addi %372, %374 : i32
      %376 = arith.shrui %375, %371 : i32
      %int_tuple_190 = cute.make_int_tuple(%376) : (i32) -> !cute.int_tuple<"?">
      %mul_191 = cute.tuple_mul(%int_tuple_190, %39) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %377 = cute.get_scalars(%mul_191) : !cute.int_tuple<"?">
      %378 = nvvm.read.ptx.sreg.laneid range <i32, 0, 32> : i32
      %379 = arith.cmpi sge, %378, %c1_i32 : i32
      %380 = arith.cmpi sge, %378, %c2_i32 : i32
      %381 = arith.cmpi sge, %378, %c4_i32 : i32
      %382 = arith.cmpi sge, %378, %c8_i32 : i32
      %383 = arith.cmpi sge, %378, %c16_i32 : i32
      %iter_192 = cute.get_iter(%arg11) : !memref_gmem_i32_
      %384 = cute.get_scalars(%39) : !cute.int_tuple<"1">
      cf.br ^bb99(%c0_i32, %377, %352, %c0_i32, %c0_i32, %0, %56, %c0_i32 : i32, i32, i1, i32, i32, !llvm.struct<(i1, i1, i1)>, i32, i32)
    ^bb99(%385: i32, %386: i32, %387: i1, %388: i32, %389: i32, %390: !llvm.struct<(i1, i1, i1)>, %391: i32, %392: i32):  // 2 preds: ^bb98, ^bb166
      cf.cond_br %387, ^bb100(%385, %386, %388, %389, %390, %391, %392 : i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>, i32, i32), ^bb167
    ^bb100(%393: i32, %394: i32, %395: i32, %396: i32, %397: !llvm.struct<(i1, i1, i1)>, %398: i32, %399: i32):  // pred: ^bb99
      %400 = builtin.unrealized_conversion_cast %397 : !llvm.struct<(i1, i1, i1)> to !mma_f16_f16_f32_128x128x16_
      %401 = arith.cmpi sge, %394, %396 : i32
      cf.br ^bb101(%401, %395, %396, %396 : i1, i32, i32, i32)
    ^bb101(%402: i1, %403: i32, %404: i32, %405: i32):  // 2 preds: ^bb100, ^bb133
      cf.cond_br %402, ^bb102(%403, %404, %405 : i32, i32, i32), ^bb134
    ^bb102(%406: i32, %407: i32, %408: i32):  // pred: ^bb101
      %409 = arith.addi %406, %378 : i32
      %410 = arith.cmpi slt, %409, %c2_i32 : i32
      cf.cond_br %410, ^bb103, ^bb107
    ^bb103:  // pred: ^bb102
      %rmem_193 = cute.memref.alloca() : !memref_rmem_i32_
      %coord_194 = cute.make_coord(%409) : (i32) -> !cute.coord<"(?,_)">
      %idx_195 = cute.crd2idx(%coord_194, %19) : (!cute.coord<"(?,_)">, !cute.layout<"(2,4):(4,1)">) -> !cute.int_tuple<"?{div=4}">
      %iter_196 = cute.get_iter(%arg11) : !memref_gmem_i32_
      %ptr_197 = cute.add_offset(%iter_196, %idx_195) : (!cute.ptr<i32, gmem, align<16>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<i32, gmem, align<16>>
      %iter_198 = cute.get_iter(%rmem_193) : !memref_rmem_i32_
      %411 = cute.get_scalars(%39) : !cute.int_tuple<"1">
      %412 = builtin.unrealized_conversion_cast %ptr_197 : !cute.ptr<i32, gmem, align<16>> to !llvm.ptr<1>
      %413 = builtin.unrealized_conversion_cast %iter_198 : !cute.ptr<i32, rmem, align<32>> to !llvm.ptr
      cf.br ^bb104(%c0_i32 : i32)
    ^bb104(%414: i32):  // 2 preds: ^bb103, ^bb105
      %415 = arith.cmpi slt, %414, %411 : i32
      cf.cond_br %415, ^bb105, ^bb106 {llvm.loop_annotation = #loop_annotation}
    ^bb105:  // pred: ^bb104
      %416 = llvm.load %412 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<4xi32>
      llvm.store %416, %413 {alignment = 16 : i64} : vector<4xi32>, !llvm.ptr
      %417 = arith.addi %414, %c1_i32 : i32
      cf.br ^bb104(%417 : i32)
    ^bb106:  // pred: ^bb104
      %418 = cute.memref.load(%rmem_193, %18) : (!memref_rmem_i32_, !cute.coord<"0">) -> i32
      %419 = arith.addi %418, %c127_i32 : i32
      %420 = arith.floordivsi %419, %c128_i32 : i32
      %421 = cute.memref.load(%rmem_193, %17) : (!memref_rmem_i32_, !cute.coord<"1">) -> i32
      %422 = arith.addi %421, %c127_i32 : i32
      %423 = arith.floordivsi %422, %c128_i32 : i32
      %424 = arith.muli %420, %423 : i32
      cf.br ^bb108(%424 : i32)
    ^bb107:  // pred: ^bb102
      cf.br ^bb108(%c0_i32 : i32)
    ^bb108(%425: i32):  // 2 preds: ^bb106, ^bb107
      cf.br ^bb109
    ^bb109:  // pred: ^bb108
      %426 = nvvm.shfl.sync  up %c-1_i32, %425, %c1_i32, %c0_i32 : i32 -> i32
      cf.cond_br %379, ^bb110, ^bb111
    ^bb110:  // pred: ^bb109
      %427 = arith.addi %425, %426 : i32
      cf.br ^bb112(%427 : i32)
    ^bb111:  // pred: ^bb109
      cf.br ^bb112(%425 : i32)
    ^bb112(%428: i32):  // 2 preds: ^bb110, ^bb111
      cf.br ^bb113
    ^bb113:  // pred: ^bb112
      %429 = nvvm.shfl.sync  up %c-1_i32, %428, %c2_i32, %c0_i32 : i32 -> i32
      cf.cond_br %380, ^bb114, ^bb115
    ^bb114:  // pred: ^bb113
      %430 = arith.addi %428, %429 : i32
      cf.br ^bb116(%430 : i32)
    ^bb115:  // pred: ^bb113
      cf.br ^bb116(%428 : i32)
    ^bb116(%431: i32):  // 2 preds: ^bb114, ^bb115
      cf.br ^bb117
    ^bb117:  // pred: ^bb116
      %432 = nvvm.shfl.sync  up %c-1_i32, %431, %c4_i32, %c0_i32 : i32 -> i32
      cf.cond_br %381, ^bb118, ^bb119
    ^bb118:  // pred: ^bb117
      %433 = arith.addi %431, %432 : i32
      cf.br ^bb120(%433 : i32)
    ^bb119:  // pred: ^bb117
      cf.br ^bb120(%431 : i32)
    ^bb120(%434: i32):  // 2 preds: ^bb118, ^bb119
      cf.br ^bb121
    ^bb121:  // pred: ^bb120
      %435 = nvvm.shfl.sync  up %c-1_i32, %434, %c8_i32, %c0_i32 : i32 -> i32
      cf.cond_br %382, ^bb122, ^bb123
    ^bb122:  // pred: ^bb121
      %436 = arith.addi %434, %435 : i32
      cf.br ^bb124(%436 : i32)
    ^bb123:  // pred: ^bb121
      cf.br ^bb124(%434 : i32)
    ^bb124(%437: i32):  // 2 preds: ^bb122, ^bb123
      cf.br ^bb125
    ^bb125:  // pred: ^bb124
      %438 = nvvm.shfl.sync  up %c-1_i32, %437, %c16_i32, %c0_i32 : i32 -> i32
      cf.cond_br %383, ^bb126, ^bb127
    ^bb126:  // pred: ^bb125
      %439 = arith.addi %437, %438 : i32
      cf.br ^bb128(%439 : i32)
    ^bb127:  // pred: ^bb125
      cf.br ^bb128(%437 : i32)
    ^bb128(%440: i32):  // 2 preds: ^bb126, ^bb127
      cf.br ^bb129
    ^bb129:  // pred: ^bb128
      %441 = arith.addi %440, %408 : i32
      %442 = arith.cmpi sge, %394, %441 : i32
      %443 = nvvm.vote.ballot.sync %c-1_i32, %442 : i32
      %444 = llvm.intr.ctpop(%443) : (i32) -> i32
      %445 = arith.cmpi eq, %444, %c32_i32 : i32
      %446 = arith.addi %444, %406 : i32
      %447 = arith.cmpi eq, %444, %c0_i32 : i32
      %448 = arith.cmpi eq, %447, %false : i1
      cf.cond_br %448, ^bb130, ^bb131
    ^bb130:  // pred: ^bb129
      %449 = arith.subi %444, %c1_i32 : i32
      %450 = nvvm.shfl.sync  idx %c-1_i32, %441, %449, %c31_i32 : i32 -> i32
      cf.br ^bb132(%450 : i32)
    ^bb131:  // pred: ^bb129
      cf.br ^bb132(%408 : i32)
    ^bb132(%451: i32):  // 2 preds: ^bb130, ^bb131
      cf.br ^bb133
    ^bb133:  // pred: ^bb132
      %452 = arith.select %445, %c31_i32, %444 : i32
      %453 = nvvm.shfl.sync  idx %c-1_i32, %441, %452, %c31_i32 : i32 -> i32
      cf.br ^bb101(%445, %446, %451, %453 : i1, i32, i32, i32)
    ^bb134:  // pred: ^bb101
      %rmem_199 = cute.memref.alloca() : !memref_rmem_i32_
      %coord_200 = cute.make_coord(%403) : (i32) -> !cute.coord<"(?,_)">
      %idx_201 = cute.crd2idx(%coord_200, %19) : (!cute.coord<"(?,_)">, !cute.layout<"(2,4):(4,1)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_202 = cute.add_offset(%iter_192, %idx_201) : (!cute.ptr<i32, gmem, align<16>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<i32, gmem, align<16>>
      %iter_203 = cute.get_iter(%rmem_199) : !memref_rmem_i32_
      %454 = builtin.unrealized_conversion_cast %ptr_202 : !cute.ptr<i32, gmem, align<16>> to !llvm.ptr<1>
      %455 = builtin.unrealized_conversion_cast %iter_203 : !cute.ptr<i32, rmem, align<32>> to !llvm.ptr
      cf.br ^bb135(%c0_i32 : i32)
    ^bb135(%456: i32):  // 2 preds: ^bb134, ^bb136
      %457 = arith.cmpi slt, %456, %384 : i32
      cf.cond_br %457, ^bb136, ^bb137 {llvm.loop_annotation = #loop_annotation}
    ^bb136:  // pred: ^bb135
      %458 = llvm.load %454 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<4xi32>
      llvm.store %458, %455 {alignment = 16 : i64} : vector<4xi32>, !llvm.ptr
      %459 = arith.addi %456, %c1_i32 : i32
      cf.br ^bb135(%459 : i32)
    ^bb137:  // pred: ^bb135
      %460 = cute.memref.load(%rmem_199, %16) : (!memref_rmem_i32_, !cute.coord<"2">) -> i32
      %461 = arith.addi %460, %c63_i32 : i32
      %462 = arith.floordivsi %461, %c64_i32 : i32
      %463 = arith.remsi %399, %c2_i32 : i32
      %coord_204 = cute.make_coord(%463) : (i32) -> !cute.coord<"(_,_,_,?)">
      %idx_205 = cute.crd2idx(%coord_204, %12) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((128,128),1,1,2):((65536,1),0,0,128)">) -> !cute.int_tuple<"?{div=128}">
      %ptr_206 = cute.add_offset(%tmem_ptr, %idx_205) : (!cute.ptr<f32, tmem, align<16>>, !cute.int_tuple<"?{div=128}">) -> !cute.ptr<f32, tmem, align<16>>
      %464 = arith.addi %393, %462 : i32
      %465 = arith.remsi %393, %c6_i32 : i32
      %466 = arith.cmpi sgt, %462, %c0_i32 : i32
      %467 = arith.extui %466 : i1 to i32
      %468 = arith.select %466, %c1_i32, %467 : i32
      %469 = arith.cmpi ne, %468, %c0_i32 : i32
      %470 = arith.floordivsi %393, %c6_i32 : i32
      %471 = arith.remsi %470, %c2_i32 : i32
      %int_tuple_207 = cute.make_int_tuple(%465) : (i32) -> !cute.int_tuple<"?">
      %ptr_208 = cute.add_offset(%iter_12, %int_tuple_207) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      cf.cond_br %469, ^bb138, ^bb139
    ^bb138:  // pred: ^bb137
      %472 = builtin.unrealized_conversion_cast %ptr_208 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      %473 = nvvm.mbarrier.wait.parity %472, %471 {kind = #nvvm.mbar_wait<try>} : !llvm.ptr<3>, i32 -> i1
      cf.br ^bb140(%473 : i1)
    ^bb139:  // pred: ^bb137
      cf.br ^bb140(%true : i1)
    ^bb140(%474: i1):  // 2 preds: ^bb138, ^bb139
      cf.br ^bb141
    ^bb141:  // pred: ^bb140
      %475 = arith.floordivsi %399, %c2_i32 : i32
      %476 = arith.remsi %475, %c2_i32 : i32
      %477 = arith.xori %476, %c1_i32 : i32
      %int_tuple_209 = cute.make_int_tuple(%463) : (i32) -> !cute.int_tuple<"?">
      %ptr_210 = cute.add_offset(%iter_15, %int_tuple_209) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %478 = builtin.unrealized_conversion_cast %ptr_210 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %478, %477, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %479 = cute_nvgpu.atom.set_value(%400, %false : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_f16_f16_f32_128x128x16_
      %480 = builtin.unrealized_conversion_cast %479 : !mma_f16_f16_f32_128x128x16_ to !llvm.struct<(i1, i1, i1)>
      %481 = arith.addi %393, %c1_i32 : i32
      %482 = arith.remsi %481, %c6_i32 : i32
      cf.br ^bb142(%c0_i32, %474, %465, %471, %480, %482 : i32, i1, i32, i32, !llvm.struct<(i1, i1, i1)>, i32)
    ^bb142(%483: i32, %484: i1, %485: i32, %486: i32, %487: !llvm.struct<(i1, i1, i1)>, %488: i32):  // 2 preds: ^bb141, ^bb163
      %489 = arith.cmpi slt, %483, %462 : i32
      cf.cond_br %489, ^bb143, ^bb164
    ^bb143:  // pred: ^bb142
      %490 = arith.addi %483, %c1_i32 : i32
      %491 = arith.cmpi eq, %488, %c0_i32 : i32
      %492 = arith.xori %486, %c1_i32 : i32
      %493 = arith.select %491, %492, %486 : i32
      %494 = arith.extui %484 : i1 to i32
      %495 = arith.cmpi eq, %494, %c0_i32 : i32
      cf.cond_br %495, ^bb144, ^bb145
    ^bb144:  // pred: ^bb143
      %int_tuple_211 = cute.make_int_tuple(%485) : (i32) -> !cute.int_tuple<"?">
      %ptr_212 = cute.add_offset(%iter_12, %int_tuple_211) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %496 = builtin.unrealized_conversion_cast %ptr_212 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %496, %486, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      cf.br ^bb145
    ^bb145:  // 2 preds: ^bb143, ^bb144
      cf.br ^bb146(%c0_i32, %487 : i32, !llvm.struct<(i1, i1, i1)>)
    ^bb146(%497: i32, %498: !llvm.struct<(i1, i1, i1)>):  // 2 preds: ^bb145, ^bb156
      %499 = arith.cmpi slt, %497, %c4_i32 : i32
      cf.cond_br %499, ^bb147, ^bb157 {loop_annotation = #loop_annotation2}
    ^bb147:  // pred: ^bb146
      %500 = builtin.unrealized_conversion_cast %498 : !llvm.struct<(i1, i1, i1)> to !mma_f16_f16_f32_128x128x16_
      %coord_213 = cute.make_coord(%497, %485) : (i32, i32) -> !cute.coord<"(_,_,?,?)">
      %idx_214 = cute.crd2idx(%coord_213, %11) : (!cute.coord<"(_,_,?,?)">, !cute.layout<"(1,1,4,6):(0,0,2,1024)">) -> !cute.int_tuple<"?{div=2}">
      %tup_215 = cute.add_offset(%ummaSmemDesc, %idx_214) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
      %tup_216 = cute.add_offset(%ummaSmemDesc_54, %idx_214) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
      %501 = cute_nvgpu.atom.get_value(%500 : !mma_f16_f16_f32_128x128x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : i1
      %502 = cute_nvgpu.atom.get_value(%500 : !mma_f16_f16_f32_128x128x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : i1
      %503 = cute_nvgpu.atom.get_value(%500 : !mma_f16_f16_f32_128x128x16_) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : i1
      %504 = arith.extui %501 : i1 to i32
      %505 = arith.extui %502 : i1 to i32
      %506 = arith.shli %504, %c13_i32 : i32
      %507 = arith.shli %505, %c14_i32 : i32
      %508 = arith.ori %506, %c136314896_i32 : i32
      %509 = arith.ori %508, %507 : i32
      cf.br ^bb148(%c0_i32 : i32)
    ^bb148(%510: i32):  // 2 preds: ^bb147, ^bb155
      %511 = arith.cmpi slt, %510, %384 : i32
      cf.cond_br %511, ^bb149, ^bb156 {llvm.loop_annotation = #loop_annotation}
    ^bb149:  // pred: ^bb148
      cf.br ^bb150(%c0_i32 : i32)
    ^bb150(%512: i32):  // 2 preds: ^bb149, ^bb154
      %513 = arith.cmpi slt, %512, %384 : i32
      cf.cond_br %513, ^bb151, ^bb155 {llvm.loop_annotation = #loop_annotation}
    ^bb151:  // pred: ^bb150
      cf.br ^bb152(%c0_i32 : i32)
    ^bb152(%514: i32):  // 2 preds: ^bb151, ^bb153
      %515 = arith.cmpi slt, %514, %384 : i32
      cf.cond_br %515, ^bb153, ^bb154 {llvm.loop_annotation = #loop_annotation}
    ^bb153:  // pred: ^bb152
      cute_nvgpu.arch.mma.SM100.umma(%tup_215, %tup_216, %ptr_206, %509, %503) {num_cta = 1 : i32, scale = 0 : i32, a_type = f16} : (!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, !cute.ptr<f32, tmem, align<16>>, i32, i1) -> ()
      %516 = arith.addi %514, %c1_i32 : i32
      cf.br ^bb152(%516 : i32)
    ^bb154:  // pred: ^bb152
      %517 = arith.addi %512, %c1_i32 : i32
      cf.br ^bb150(%517 : i32)
    ^bb155:  // pred: ^bb150
      %518 = arith.addi %510, %c1_i32 : i32
      cf.br ^bb148(%518 : i32)
    ^bb156:  // pred: ^bb148
      %519 = cute_nvgpu.atom.set_value(%500, %true : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_f16_f16_f32_128x128x16_
      %520 = builtin.unrealized_conversion_cast %519 : !mma_f16_f16_f32_128x128x16_ to !llvm.struct<(i1, i1, i1)>
      %521 = arith.addi %497, %c1_i32 : i32
      cf.br ^bb146(%521, %520 : i32, !llvm.struct<(i1, i1, i1)>)
    ^bb157:  // pred: ^bb146
      %522 = nvvm.elect.sync -> i1
      cf.cond_br %522, ^bb158, ^bb159
    ^bb158:  // pred: ^bb157
      %int_tuple_217 = cute.make_int_tuple(%485) : (i32) -> !cute.int_tuple<"?">
      %ptr_218 = cute.add_offset(%iter_13, %int_tuple_217) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %523 = builtin.unrealized_conversion_cast %ptr_218 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.tcgen05.commit.arrive %523 : !llvm.ptr<3>
      cf.br ^bb159
    ^bb159:  // 2 preds: ^bb157, ^bb158
      %524 = arith.cmpi slt, %490, %462 : i32
      %525 = arith.extui %524 : i1 to i32
      %526 = arith.select %524, %c1_i32, %525 : i32
      %527 = arith.cmpi ne, %526, %c0_i32 : i32
      %int_tuple_219 = cute.make_int_tuple(%488) : (i32) -> !cute.int_tuple<"?">
      %ptr_220 = cute.add_offset(%iter_12, %int_tuple_219) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      cf.cond_br %527, ^bb160, ^bb161
    ^bb160:  // pred: ^bb159
      %528 = builtin.unrealized_conversion_cast %ptr_220 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      %529 = nvvm.mbarrier.wait.parity %528, %493 {kind = #nvvm.mbar_wait<try>} : !llvm.ptr<3>, i32 -> i1
      cf.br ^bb162(%529 : i1)
    ^bb161:  // pred: ^bb159
      cf.br ^bb162(%true : i1)
    ^bb162(%530: i1):  // 2 preds: ^bb160, ^bb161
      cf.br ^bb163
    ^bb163:  // pred: ^bb162
      %531 = arith.addi %488, %c1_i32 : i32
      %532 = arith.cmpi eq, %531, %c6_i32 : i32
      %533 = arith.select %532, %c0_i32, %531 : i32
      %534 = arith.addi %483, %c1_i32 : i32
      cf.br ^bb142(%534, %530, %488, %493, %498, %533 : i32, i1, i32, i32, !llvm.struct<(i1, i1, i1)>, i32)
    ^bb164:  // pred: ^bb142
      %535 = nvvm.elect.sync -> i1
      cf.cond_br %535, ^bb165, ^bb166
    ^bb165:  // pred: ^bb164
      %ptr_221 = cute.add_offset(%iter_14, %int_tuple_209) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %536 = builtin.unrealized_conversion_cast %ptr_221 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.tcgen05.commit.arrive %536 : !llvm.ptr<3>
      cf.br ^bb166
    ^bb166:  // 2 preds: ^bb164, ^bb165
      %537 = arith.addi %398, %350 : i32
      %538 = arith.addi %399, %c1_i32 : i32
      %539 = arith.cmpi sgt, %351, %537 : i32
      %540 = nvvm.mul  hi %537, %multiplier_181 : i32 -> i32
      %541 = arith.subi %537, %540 : i32
      %542 = arith.shrui %541, %354 : i32
      %543 = arith.addi %540, %542 : i32
      %544 = arith.shrui %543, %355 : i32
      %545 = arith.muli %544, %353 : i32
      %546 = arith.subi %537, %545 : i32
      %547 = nvvm.mul  hi %546, %multiplier_184 : i32 -> i32
      %548 = arith.subi %546, %547 : i32
      %549 = arith.shrui %548, %363 : i32
      %550 = arith.addi %547, %549 : i32
      %551 = arith.shrui %550, %364 : i32
      %552 = nvvm.mul  hi %551, %multiplier_187 : i32 -> i32
      %553 = arith.subi %551, %552 : i32
      %554 = arith.shrui %553, %370 : i32
      %555 = arith.addi %552, %554 : i32
      %556 = arith.shrui %555, %371 : i32
      %int_tuple_222 = cute.make_int_tuple(%556) : (i32) -> !cute.int_tuple<"?">
      %mul_223 = cute.tuple_mul(%int_tuple_222, %39) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %557 = cute.get_scalars(%mul_223) : !cute.int_tuple<"?">
      cf.br ^bb99(%464, %557, %539, %403, %404, %487, %537, %538 : i32, i32, i1, i32, i32, !llvm.struct<(i1, i1, i1)>, i32, i32)
    ^bb167:  // pred: ^bb99
      cf.br ^bb168
    ^bb168:  // 2 preds: ^bb97, ^bb167
      %558 = arith.cmpi slt, %52, %c4_i32 : i32
      cf.cond_br %558, ^bb169, ^bb259
    ^bb169:  // pred: ^bb168
      cf.cond_br %57, ^bb170, ^bb173
    ^bb170:  // pred: ^bb169
      %559 = nvvm.elect.sync -> i1
      cf.cond_br %559, ^bb171, ^bb172
    ^bb171:  // pred: ^bb170
      cute_nvgpu.copy_tma_desc(%arg1, %iter_8) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>, !cute.ptr<i64, smem, align<1024>>) -> ()
      cf.br ^bb172
    ^bb172:  // 2 preds: ^bb170, ^bb171
      cf.br ^bb173
    ^bb173:  // 2 preds: ^bb169, ^bb172
      nvvm.bar.warp.sync %c-1_i32 : i32
      cf.cond_br %57, ^bb174, ^bb177
    ^bb174:  // pred: ^bb173
      %560 = nvvm.elect.sync -> i1
      cf.cond_br %560, ^bb175, ^bb176
    ^bb175:  // pred: ^bb174
      cute_nvgpu.copy_tma_desc(%arg3, %ptr_9) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>, !cute.ptr<i64, smem, align<128>>) -> ()
      cf.br ^bb176
    ^bb176:  // 2 preds: ^bb174, ^bb175
      cf.br ^bb177
    ^bb177:  // 2 preds: ^bb173, ^bb176
      nvvm.bar.warp.sync %c-1_i32 : i32
      nvvm.barrier id = %c3_i32 number_of_threads = %c160_i32
      cf.cond_br %57, ^bb178, ^bb181
    ^bb178:  // pred: ^bb177
      %561 = nvvm.elect.sync -> i1
      cf.cond_br %561, ^bb179, ^bb180
    ^bb179:  // pred: ^bb178
      cute_nvgpu.copy_tma_desc(%arg5, %dyn) : (!cute_nvgpu.atom.non_exec_tiled_tma_store<f16, copy_bits = 65536, tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>, !cute.ptr<i64, smem, align<128>>) -> ()
      cf.br ^bb180
    ^bb180:  // 2 preds: ^bb178, ^bb179
      cf.br ^bb181
    ^bb181:  // 2 preds: ^bb177, ^bb180
      nvvm.bar.warp.sync %c-1_i32 : i32
      cf.cond_br %57, ^bb182, ^bb183
    ^bb182:  // pred: ^bb181
      cute_nvgpu.arch.sm100.alloc_tmem(%c256_i32, %iter) [ cta_1] : i32, !cute.ptr<i32, smem, align<8>>
      cf.br ^bb183
    ^bb183:  // 2 preds: ^bb181, ^bb182
      nvvm.barrier id = %c2_i32 number_of_threads = %c160_i32
      %tmem_ptr_224 = cute_nvgpu.arch.sm100.retrieve_tmem_ptr(%iter) : !cute.ptr<i32, smem, align<8>> -> !cute.ptr<f32, tmem, align<16>>
      %coord_225 = cute.make_coord(%41) : (i32) -> !cute.coord<"?">
      %562 = cute.get_scalars(%coord_225) <{only_dynamic}> : !cute.coord<"?">
      %563 = arith.divsi %562, %c32_i32 : i32
      %564 = arith.muli %563, %c2097152_i32 : i32
      %iv_226 = cute.assume(%564) : (i32) -> !cute.i32<divby 2097152>
      %int_tuple_227 = cute.make_int_tuple(%iv_226) : (!cute.i32<divby 2097152>) -> !cute.int_tuple<"?{div=2097152}">
      %ptr_228 = cute.add_offset(%tmem_ptr_224, %int_tuple_227) : (!cute.ptr<f32, tmem, align<16>>, !cute.int_tuple<"?{div=2097152}">) -> !cute.ptr<f32, tmem, align<16>>
      %rmem_229 = cute.memref.alloca() : !memref_rmem_f32_
      %iter_230 = cute.get_iter(%rmem_229) : !memref_rmem_f32_
      %rmem_231 = cute.memref.alloca() : !memref_rmem_f16_
      %atom = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<f16>
      %565 = cute.make_tiled_copy(%atom) : !copy_simt
      %566 = arith.remsi %562, %c32_i32 : i32
      %567 = arith.muli %566, %c32_i32 : i32
      %568 = arith.muli %563, %c1024_i32 : i32
      %569 = arith.addi %567, %568 : i32
      %iv_232 = cute.assume(%569) : (i32) -> !cute.i32<divby 32>
      %int_tuple_233 = cute.make_int_tuple(%iv_232) : (!cute.i32<divby 32>) -> !cute.int_tuple<"?{div=32}">
      %ptr_234 = cute.add_offset(%iter_22, %int_tuple_233) : (!cute.ptr<f16, smem, align<1024>, S<2,4,3>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f16, smem, align<64>, S<2,4,3>>
      %iter_235 = cute.get_iter(%rmem_231) : !memref_rmem_f16_
      %view_236 = cute.make_view(%iter_235) : !memref_rmem_f16_1
      %570:3 = cute.get_scalars(%lay_45) <{only_dynamic}> : !cute.layout<"((128,128),1,1,?,?,?):((1@1,1@0),0,0,128@1,128@0,1@2)">
      %shape_237 = cute.make_shape(%570#0, %570#1, %570#2) : (i32, i32, i32) -> !cute.shape<"(128,128,?,?,?)">
      %lay_238 = cute.make_layout(%shape_237, %25) : !cute.layout<"(128,128,?,?,?):(1@1,1@0,128@1,128@0,1@2)">
      %571:3 = cute.get_scalars(%lay_238) <{only_dynamic}> : !cute.layout<"(128,128,?,?,?):(1@1,1@0,128@1,128@0,1@2)">
      %shape_239 = cute.make_shape(%571#0, %571#1, %571#2) : (i32, i32, i32) -> !cute.shape<"(128,32,1,4,?,?,?)">
      %lay_240 = cute.make_layout(%shape_239, %10) : !cute.layout<"(128,32,1,4,?,?,?):(1@1,1@0,0,32@0,128@1,128@0,1@2)">
      %572:3 = cute.get_scalars(%lay_240) <{only_dynamic}> : !cute.layout<"(128,32,1,4,?,?,?):(1@1,1@0,0,32@0,128@1,128@0,1@2)">
      %shape_241 = cute.make_shape(%572#0, %572#1, %572#2) : (i32, i32, i32) -> !cute.shape<"((128,32),1,4,?,?,?)">
      %lay_242 = cute.make_layout(%shape_241, %9) : !cute.layout<"((128,32),1,4,?,?,?):((1@1,1@0),0,32@0,128@1,128@0,1@2)">
      %573:3 = cute.get_scalars(%lay_242) <{only_dynamic}> : !cute.layout<"((128,32),1,4,?,?,?):((1@1,1@0),0,32@0,128@1,128@0,1@2)">
      %shape_243 = cute.make_shape(%573#0, %573#1, %573#2) : (i32, i32, i32) -> !cute.shape<"(((32,128),1),1,4,?,?,?)">
      %lay_244 = cute.make_layout(%shape_243, %8) : !cute.layout<"(((32,128),1),1,4,?,?,?):(((1@0,1@1),0),0,32@0,128@1,128@0,1@2)">
      %int_tuple_245 = cute.make_int_tuple(%90, %91, %92) : (i32, i32, i32) -> !cute.int_tuple<"(?,?,?)">
      %sz_246 = cute.size(%int_tuple_245) : (!cute.int_tuple<"(?,?,?)">) -> !cute.int_tuple<"?">
      %e0_247 = cute.get_leaves(%sz_246) : !cute.int_tuple<"?">
      %div_248 = cute.tuple_div(%e0_247, %39) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %574 = cute.get_scalars(%div_248) : !cute.int_tuple<"?">
      %sz_249 = cute.size(%lay) : (!cute.layout<"(1,1,?):(0,0,1)">) -> !cute.int_tuple<"?">
      %e0_250 = cute.get_leaves(%sz_249) : !cute.int_tuple<"?">
      %575 = cute.get_scalars(%e0_250) : !cute.int_tuple<"?">
      %576 = arith.cmpi sgt, %575, %56 : i32
      %577 = cute.fast_divmod.get_divisor(%arg8) : !cute.fast_divmod_divisor<32>
      %multiplier_251, %shift1_252, %shift2_253 = cute.fast_divmod.get_aux(%arg8) : !cute.fast_divmod_divisor<32> -> (i32, i8)
      %578 = arith.extui %shift1_252 : i8 to i32
      %579 = arith.extui %shift2_253 : i8 to i32
      %580 = nvvm.mul  hi %56, %multiplier_251 : i32 -> i32
      %581 = arith.subi %56, %580 : i32
      %582 = arith.shrui %581, %578 : i32
      %583 = arith.addi %580, %582 : i32
      %584 = arith.shrui %583, %579 : i32
      %585 = arith.muli %584, %577 : i32
      %586 = arith.subi %56, %585 : i32
      %587 = cute.fast_divmod.get_divisor(%arg9) : !cute.fast_divmod_divisor<32>
      %multiplier_254, %shift1_255, %shift2_256 = cute.fast_divmod.get_aux(%arg9) : !cute.fast_divmod_divisor<32> -> (i32, i8)
      %588 = arith.extui %shift1_255 : i8 to i32
      %589 = arith.extui %shift2_256 : i8 to i32
      %590 = nvvm.mul  hi %586, %multiplier_254 : i32 -> i32
      %591 = arith.subi %586, %590 : i32
      %592 = arith.shrui %591, %588 : i32
      %593 = arith.addi %590, %592 : i32
      %594 = arith.shrui %593, %589 : i32
      %595 = arith.muli %594, %587 : i32
      %596 = arith.subi %586, %595 : i32
      %597 = cute.fast_divmod.get_divisor(%arg10) : !cute.fast_divmod_divisor<32>
      %multiplier_257, %shift1_258, %shift2_259 = cute.fast_divmod.get_aux(%arg10) : !cute.fast_divmod_divisor<32> -> (i32, i8)
      %598 = arith.extui %shift1_258 : i8 to i32
      %599 = arith.extui %shift2_259 : i8 to i32
      %600 = nvvm.mul  hi %594, %multiplier_257 : i32 -> i32
      %601 = arith.subi %594, %600 : i32
      %602 = arith.shrui %601, %598 : i32
      %603 = arith.addi %600, %602 : i32
      %604 = arith.shrui %603, %599 : i32
      %605 = arith.muli %604, %597 : i32
      %606 = arith.subi %594, %605 : i32
      %int_tuple_260 = cute.make_int_tuple(%596) : (i32) -> !cute.int_tuple<"?">
      %mul_261 = cute.tuple_mul(%int_tuple_260, %39) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %607 = cute.get_scalars(%mul_261) : !cute.int_tuple<"?">
      %int_tuple_262 = cute.make_int_tuple(%606) : (i32) -> !cute.int_tuple<"?">
      %mul_263 = cute.tuple_mul(%int_tuple_262, %39) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %608 = cute.get_scalars(%mul_263) : !cute.int_tuple<"?">
      %int_tuple_264 = cute.make_int_tuple(%604) : (i32) -> !cute.int_tuple<"?">
      %mul_265 = cute.tuple_mul(%int_tuple_264, %39) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %609 = cute.get_scalars(%mul_265) : !cute.int_tuple<"?">
      %610 = nvvm.read.ptx.sreg.laneid range <i32, 0, 32> : i32
      %611 = arith.cmpi sge, %610, %c1_i32 : i32
      %612 = arith.cmpi sge, %610, %c2_i32 : i32
      %613 = arith.cmpi sge, %610, %c4_i32 : i32
      %614 = arith.cmpi sge, %610, %c8_i32 : i32
      %615 = arith.cmpi sge, %610, %c16_i32 : i32
      %iter_266 = cute.get_iter(%arg11) : !memref_gmem_i32_
      %616 = cute.get_scalars(%39) : !cute.int_tuple<"1">
      %617 = builtin.unrealized_conversion_cast %iter_230 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
      %view_267 = cute.make_view(%iter_230) : !memref_rmem_f32_1
      %swizzled = cute.apply_swizzle(%ptr_234) : !cute.ptr<f16, smem, align<64>, S<2,4,3>>
      %618 = builtin.unrealized_conversion_cast %iter_235 : !cute.ptr<f16, rmem, align<32>> to !llvm.ptr
      %ptr_268 = cute.add_offset(%iter_235, %4) : (!cute.ptr<f16, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<f16, rmem, align<16>>
      %ptr_269 = cute.add_offset(%ptr_234, %4) : (!cute.ptr<f16, smem, align<64>, S<2,4,3>>, !cute.int_tuple<"8">) -> !cute.ptr<f16, smem, align<16>, S<2,4,3>>
      %swizzled_270 = cute.apply_swizzle(%ptr_269) : !cute.ptr<f16, smem, align<16>, S<2,4,3>>
      %619 = builtin.unrealized_conversion_cast %ptr_268 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
      %ptr_271 = cute.add_offset(%iter_235, %30) : (!cute.ptr<f16, rmem, align<32>>, !cute.int_tuple<"16">) -> !cute.ptr<f16, rmem, align<32>>
      %ptr_272 = cute.add_offset(%ptr_234, %30) : (!cute.ptr<f16, smem, align<64>, S<2,4,3>>, !cute.int_tuple<"16">) -> !cute.ptr<f16, smem, align<32>, S<2,4,3>>
      %swizzled_273 = cute.apply_swizzle(%ptr_272) : !cute.ptr<f16, smem, align<32>, S<2,4,3>>
      %620 = builtin.unrealized_conversion_cast %ptr_271 : !cute.ptr<f16, rmem, align<32>> to !llvm.ptr
      %ptr_274 = cute.add_offset(%iter_235, %3) : (!cute.ptr<f16, rmem, align<32>>, !cute.int_tuple<"24">) -> !cute.ptr<f16, rmem, align<16>>
      %ptr_275 = cute.add_offset(%ptr_234, %3) : (!cute.ptr<f16, smem, align<64>, S<2,4,3>>, !cute.int_tuple<"24">) -> !cute.ptr<f16, smem, align<16>, S<2,4,3>>
      %swizzled_276 = cute.apply_swizzle(%ptr_275) : !cute.ptr<f16, smem, align<16>, S<2,4,3>>
      %621 = builtin.unrealized_conversion_cast %ptr_274 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
      cf.br ^bb184(%c0_i32, %607, %608, %609, %576, %c-1_i32, %c0_i32, %c0_i32, %56, %c0_i32 : i32, i32, i32, i32, i1, i32, i32, i32, i32, i32)
    ^bb184(%622: i32, %623: i32, %624: i32, %625: i32, %626: i1, %627: i32, %628: i32, %629: i32, %630: i32, %631: i32):  // 2 preds: ^bb183, ^bb251
      cf.cond_br %626, ^bb185(%622, %623, %624, %625, %627, %628, %629, %630, %631 : i32, i32, i32, i32, i32, i32, i32, i32, i32), ^bb252
    ^bb185(%632: i32, %633: i32, %634: i32, %635: i32, %636: i32, %637: i32, %638: i32, %639: i32, %640: i32):  // pred: ^bb184
      %641 = arith.cmpi sge, %635, %638 : i32
      cf.br ^bb186(%641, %637, %638, %638 : i1, i32, i32, i32)
    ^bb186(%642: i1, %643: i32, %644: i32, %645: i32):  // 2 preds: ^bb185, ^bb218
      cf.cond_br %642, ^bb187(%643, %644, %645 : i32, i32, i32), ^bb219
    ^bb187(%646: i32, %647: i32, %648: i32):  // pred: ^bb186
      %649 = arith.addi %646, %610 : i32
      %650 = arith.cmpi slt, %649, %c2_i32 : i32
      cf.cond_br %650, ^bb188, ^bb192
    ^bb188:  // pred: ^bb187
      %rmem_277 = cute.memref.alloca() : !memref_rmem_i32_
      %coord_278 = cute.make_coord(%649) : (i32) -> !cute.coord<"(?,_)">
      %idx_279 = cute.crd2idx(%coord_278, %19) : (!cute.coord<"(?,_)">, !cute.layout<"(2,4):(4,1)">) -> !cute.int_tuple<"?{div=4}">
      %iter_280 = cute.get_iter(%arg11) : !memref_gmem_i32_
      %ptr_281 = cute.add_offset(%iter_280, %idx_279) : (!cute.ptr<i32, gmem, align<16>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<i32, gmem, align<16>>
      %iter_282 = cute.get_iter(%rmem_277) : !memref_rmem_i32_
      %651 = cute.get_scalars(%39) : !cute.int_tuple<"1">
      %652 = builtin.unrealized_conversion_cast %ptr_281 : !cute.ptr<i32, gmem, align<16>> to !llvm.ptr<1>
      %653 = builtin.unrealized_conversion_cast %iter_282 : !cute.ptr<i32, rmem, align<32>> to !llvm.ptr
      cf.br ^bb189(%c0_i32 : i32)
    ^bb189(%654: i32):  // 2 preds: ^bb188, ^bb190
      %655 = arith.cmpi slt, %654, %651 : i32
      cf.cond_br %655, ^bb190, ^bb191 {llvm.loop_annotation = #loop_annotation}
    ^bb190:  // pred: ^bb189
      %656 = llvm.load %652 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<4xi32>
      llvm.store %656, %653 {alignment = 16 : i64} : vector<4xi32>, !llvm.ptr
      %657 = arith.addi %654, %c1_i32 : i32
      cf.br ^bb189(%657 : i32)
    ^bb191:  // pred: ^bb189
      %658 = cute.memref.load(%rmem_277, %18) : (!memref_rmem_i32_, !cute.coord<"0">) -> i32
      %659 = arith.addi %658, %c127_i32 : i32
      %660 = arith.floordivsi %659, %c128_i32 : i32
      %661 = cute.memref.load(%rmem_277, %17) : (!memref_rmem_i32_, !cute.coord<"1">) -> i32
      %662 = arith.addi %661, %c127_i32 : i32
      %663 = arith.floordivsi %662, %c128_i32 : i32
      %664 = arith.muli %660, %663 : i32
      cf.br ^bb193(%664 : i32)
    ^bb192:  // pred: ^bb187
      cf.br ^bb193(%c0_i32 : i32)
    ^bb193(%665: i32):  // 2 preds: ^bb191, ^bb192
      cf.br ^bb194
    ^bb194:  // pred: ^bb193
      %666 = nvvm.shfl.sync  up %c-1_i32, %665, %c1_i32, %c0_i32 : i32 -> i32
      cf.cond_br %611, ^bb195, ^bb196
    ^bb195:  // pred: ^bb194
      %667 = arith.addi %665, %666 : i32
      cf.br ^bb197(%667 : i32)
    ^bb196:  // pred: ^bb194
      cf.br ^bb197(%665 : i32)
    ^bb197(%668: i32):  // 2 preds: ^bb195, ^bb196
      cf.br ^bb198
    ^bb198:  // pred: ^bb197
      %669 = nvvm.shfl.sync  up %c-1_i32, %668, %c2_i32, %c0_i32 : i32 -> i32
      cf.cond_br %612, ^bb199, ^bb200
    ^bb199:  // pred: ^bb198
      %670 = arith.addi %668, %669 : i32
      cf.br ^bb201(%670 : i32)
    ^bb200:  // pred: ^bb198
      cf.br ^bb201(%668 : i32)
    ^bb201(%671: i32):  // 2 preds: ^bb199, ^bb200
      cf.br ^bb202
    ^bb202:  // pred: ^bb201
      %672 = nvvm.shfl.sync  up %c-1_i32, %671, %c4_i32, %c0_i32 : i32 -> i32
      cf.cond_br %613, ^bb203, ^bb204
    ^bb203:  // pred: ^bb202
      %673 = arith.addi %671, %672 : i32
      cf.br ^bb205(%673 : i32)
    ^bb204:  // pred: ^bb202
      cf.br ^bb205(%671 : i32)
    ^bb205(%674: i32):  // 2 preds: ^bb203, ^bb204
      cf.br ^bb206
    ^bb206:  // pred: ^bb205
      %675 = nvvm.shfl.sync  up %c-1_i32, %674, %c8_i32, %c0_i32 : i32 -> i32
      cf.cond_br %614, ^bb207, ^bb208
    ^bb207:  // pred: ^bb206
      %676 = arith.addi %674, %675 : i32
      cf.br ^bb209(%676 : i32)
    ^bb208:  // pred: ^bb206
      cf.br ^bb209(%674 : i32)
    ^bb209(%677: i32):  // 2 preds: ^bb207, ^bb208
      cf.br ^bb210
    ^bb210:  // pred: ^bb209
      %678 = nvvm.shfl.sync  up %c-1_i32, %677, %c16_i32, %c0_i32 : i32 -> i32
      cf.cond_br %615, ^bb211, ^bb212
    ^bb211:  // pred: ^bb210
      %679 = arith.addi %677, %678 : i32
      cf.br ^bb213(%679 : i32)
    ^bb212:  // pred: ^bb210
      cf.br ^bb213(%677 : i32)
    ^bb213(%680: i32):  // 2 preds: ^bb211, ^bb212
      cf.br ^bb214
    ^bb214:  // pred: ^bb213
      %681 = arith.addi %680, %648 : i32
      %682 = arith.cmpi sge, %635, %681 : i32
      %683 = nvvm.vote.ballot.sync %c-1_i32, %682 : i32
      %684 = llvm.intr.ctpop(%683) : (i32) -> i32
      %685 = arith.cmpi eq, %684, %c32_i32 : i32
      %686 = arith.addi %684, %646 : i32
      %687 = arith.cmpi eq, %684, %c0_i32 : i32
      %688 = arith.cmpi eq, %687, %false : i1
      cf.cond_br %688, ^bb215, ^bb216
    ^bb215:  // pred: ^bb214
      %689 = arith.subi %684, %c1_i32 : i32
      %690 = nvvm.shfl.sync  idx %c-1_i32, %681, %689, %c31_i32 : i32 -> i32
      cf.br ^bb217(%690 : i32)
    ^bb216:  // pred: ^bb214
      cf.br ^bb217(%648 : i32)
    ^bb217(%691: i32):  // 2 preds: ^bb215, ^bb216
      cf.br ^bb218
    ^bb218:  // pred: ^bb217
      %692 = arith.select %685, %c31_i32, %684 : i32
      %693 = nvvm.shfl.sync  idx %c-1_i32, %681, %692, %c31_i32 : i32 -> i32
      cf.br ^bb186(%685, %686, %691, %693 : i1, i32, i32, i32)
    ^bb219:  // pred: ^bb186
      %rmem_283 = cute.memref.alloca() : !memref_rmem_i32_
      %coord_284 = cute.make_coord(%643) : (i32) -> !cute.coord<"(?,_)">
      %idx_285 = cute.crd2idx(%coord_284, %19) : (!cute.coord<"(?,_)">, !cute.layout<"(2,4):(4,1)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_286 = cute.add_offset(%iter_266, %idx_285) : (!cute.ptr<i32, gmem, align<16>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<i32, gmem, align<16>>
      %iter_287 = cute.get_iter(%rmem_283) : !memref_rmem_i32_
      %694 = builtin.unrealized_conversion_cast %ptr_286 : !cute.ptr<i32, gmem, align<16>> to !llvm.ptr<1>
      %695 = builtin.unrealized_conversion_cast %iter_287 : !cute.ptr<i32, rmem, align<32>> to !llvm.ptr
      cf.br ^bb220(%c0_i32 : i32)
    ^bb220(%696: i32):  // 2 preds: ^bb219, ^bb221
      %697 = arith.cmpi slt, %696, %616 : i32
      cf.cond_br %697, ^bb221, ^bb222 {llvm.loop_annotation = #loop_annotation}
    ^bb221:  // pred: ^bb220
      %698 = llvm.load %694 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<4xi32>
      llvm.store %698, %695 {alignment = 16 : i64} : vector<4xi32>, !llvm.ptr
      %699 = arith.addi %696, %c1_i32 : i32
      cf.br ^bb220(%699 : i32)
    ^bb222:  // pred: ^bb220
      %700 = arith.subi %635, %644 : i32
      %701 = cute.memref.load(%rmem_283, %18) : (!memref_rmem_i32_, !cute.coord<"0">) -> i32
      %702 = cute.memref.load(%rmem_283, %17) : (!memref_rmem_i32_, !cute.coord<"1">) -> i32
      %703 = cute.memref.load(%rmem_283, %16) : (!memref_rmem_i32_, !cute.coord<"2">) -> i32
      %int_tuple_288 = cute.make_int_tuple(%701, %702, %703) : (i32, i32, i32) -> !cute.int_tuple<"(?,?,?)">
      %704:3 = cute.get_scalars(%int_tuple_288) <{only_dynamic}> : !cute.int_tuple<"(?,?,?)">
      %705 = arith.ceildivsi %704#0, %c128_i32 : i32
      %706 = arith.ceildivsi %704#1, %c128_i32 : i32
      %707 = arith.ceildivsi %704#2, %c64_i32 : i32
      %int_tuple_289 = cute.make_int_tuple(%705, %706, %707) : (i32, i32, i32) -> !cute.int_tuple<"(?,?,?)">
      %e0_290, %e1_291, %e2_292 = cute.get_leaves(%int_tuple_289) : !cute.int_tuple<"(?,?,?)">
      %shape_293 = cute.make_shape(%e0_290, %e1_291) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.shape<"(?,?)">
      %lay_294 = cute.make_layout(%shape_293) : !cute.layout<"(?,?):(1,?)">
      %708 = cute.get_hier_coord(%700, %lay_294) : (i32, !cute.layout<"(?,?):(1,?)">) -> !cute.coord<"(?,?)">
      %e0_295, %e1_296 = cute.get_leaves(%708) : !cute.coord<"(?,?)">
      %itup_297 = cute.to_int_tuple(%e0_295) : !cute.coord<"?"> to !cute.int_tuple<"?">
      %itup_298 = cute.to_int_tuple(%e1_296) : !cute.coord<"?"> to !cute.int_tuple<"?">
      %mul_299 = cute.tuple_mul(%itup_297, %39) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %int_tuple_300 = cute.make_int_tuple(%633) : (i32) -> !cute.int_tuple<"?">
      %tup_301 = cute.add_offset(%mul_299, %int_tuple_300) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.int_tuple<"?">
      %mul_302 = cute.tuple_mul(%itup_298, %39) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %int_tuple_303 = cute.make_int_tuple(%634) : (i32) -> !cute.int_tuple<"?">
      %tup_304 = cute.add_offset(%mul_302, %int_tuple_303) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.int_tuple<"?">
      %709 = arith.cmpi ne, %643, %636 : i32
      cf.cond_br %709, ^bb223, ^bb231
    ^bb223:  // pred: ^bb222
      %coord_305 = cute.make_coord(%643) : (i32) -> !cute.coord<"(?,2)">
      %710 = cute.memref.load(%arg13, %coord_305) : (!memref_gmem_i64_, !cute.coord<"(?,2)">) -> i64
      %iv_306 = cute.assume(%710) : (i64) -> !cute.i64<divby 16>
      %711 = cute.inttoptr(%iv_306) : !cute.i64<divby 16> to !cute.ptr<f16, gmem, align<16>>
      %coord_307 = cute.make_coord(%643) : (i32) -> !cute.coord<"(?,2,_)">
      %idx_308 = cute.crd2idx(%coord_307, %15) : (!cute.coord<"(?,2,_)">, !cute.layout<"(2,3,2):(6,2,1)">) -> !cute.int_tuple<"?{div=2}">
      %iter_309 = cute.get_iter(%arg12) : !memref_gmem_i32_1
      %ptr_310 = cute.add_offset(%iter_309, %idx_308) : (!cute.ptr<i32, gmem, align<16>>, !cute.int_tuple<"?{div=2}">) -> !cute.ptr<i32, gmem, align<8>>
      %rmem_311 = cute.memref.alloca() : !memref_rmem_i32_1
      %iter_312 = cute.get_iter(%rmem_311) : !memref_rmem_i32_1
      %712 = builtin.unrealized_conversion_cast %ptr_310 : !cute.ptr<i32, gmem, align<8>> to !llvm.ptr<1>
      %713 = builtin.unrealized_conversion_cast %iter_312 : !cute.ptr<i32, rmem, align<32>> to !llvm.ptr
      cf.br ^bb224(%c0_i32 : i32)
    ^bb224(%714: i32):  // 2 preds: ^bb223, ^bb225
      %715 = arith.cmpi slt, %714, %616 : i32
      cf.cond_br %715, ^bb225, ^bb226 {llvm.loop_annotation = #loop_annotation}
    ^bb225:  // pred: ^bb224
      %716 = llvm.load %712 {alignment = 8 : i64} : !llvm.ptr<1> -> vector<2xi32>
      llvm.store %716, %713 {alignment = 8 : i64} : vector<2xi32>, !llvm.ptr
      %717 = arith.addi %714, %c1_i32 : i32
      cf.br ^bb224(%717 : i32)
    ^bb226:  // pred: ^bb224
      %718 = cute.memref.load(%rmem_311, %18) : (!memref_rmem_i32_1, !cute.coord<"0">) -> i32
      %719 = cute.memref.load(%rmem_311, %17) : (!memref_rmem_i32_1, !cute.coord<"1">) -> i32
      %shape_313 = cute.make_shape(%701, %702) : (i32, i32) -> !cute.shape<"(?,?,1)">
      %stride_314 = cute.make_stride(%718, %719) : (i32, i32) -> !cute.stride<"(?,?,0)">
      %lay_315 = cute.make_layout(%shape_313, %stride_314) : !cute.layout<"(?,?,1):(?,?,0)">
      %view_316 = cute.make_view(%711, %lay_315) : !memref_gmem_f16_
      %dyn_317 = cute.derefine(%view_316) : !memref_gmem_f16_ to !memref_gmem_f16_1
      cf.cond_br %57, ^bb227, ^bb230
    ^bb227:  // pred: ^bb226
      cute_nvgpu.update_tma_desc(%arg5, %dyn_317, %dyn) : (!cute_nvgpu.atom.non_exec_tiled_tma_store<f16, copy_bits = 65536, tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>, !memref_gmem_f16_1, !cute.ptr<i64, smem, align<128>>) -> ()
      %720 = nvvm.elect.sync -> i1
      cf.cond_br %720, ^bb228, ^bb229
    ^bb228:  // pred: ^bb227
      nvvm.cp.async.bulk.commit.group
      nvvm.cp.async.bulk.wait_group 0 {read}
      cf.br ^bb229
    ^bb229:  // 2 preds: ^bb227, ^bb228
      nvvm.bar.warp.sync %c-1_i32 : i32
      %721 = cute.ptrtoint(%103) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, gmem, align<128>> to i64
      %722 = cute.ptrtoint(%dyn) : !cute.ptr<i64, smem, align<128>> to i32
      llvm.inline_asm has_side_effects asm_dialect = att "tensormap.cp_fenceproxy.global.shared::cta.tensormap::generic.release.gpu.sync.aligned [$0], [$1], 128;", "l,r" %721, %722 : (i64, i32) -> ()
      cf.br ^bb230
    ^bb230:  // 2 preds: ^bb226, ^bb229
      cf.br ^bb231
    ^bb231:  // 2 preds: ^bb222, ^bb230
      %div_318 = cute.tuple_div(%tup_301, %39) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %int_tuple_319 = cute.make_int_tuple(%632) : (i32) -> !cute.int_tuple<"?">
      %tup_320 = cute.add_offset(%int_tuple_319, %e2_292) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.int_tuple<"?">
      %723 = cute.get_scalars(%tup_320) : !cute.int_tuple<"?">
      %coord_321 = cute.make_coord(%div_318, %tup_304) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(_,_,_,?,?,0)">
      %idx_322 = cute.crd2idx(%coord_321, %lay_244) : (!cute.coord<"(_,_,_,?,?,0)">, !cute.layout<"(((32,128),1),1,4,?,?,?):(((1@0,1@1),0),0,32@0,128@1,128@0,1@2)">) -> !cute.int_tuple<"(?{div=128},?{div=128},0)">
      %tup_323 = cute.add_offset(%27, %idx_322) : (!cute.int_tuple<"(0,0,0)">, !cute.int_tuple<"(?{div=128},?{div=128},0)">) -> !cute.int_tuple<"(?{div=128},?{div=128},0)">
      %724 = arith.remsi %640, %c2_i32 : i32
      %coord_324 = cute.make_coord(%724) : (i32) -> !cute.coord<"(_,_,_,_,_,?)">
      %idx_325 = cute.crd2idx(%coord_324, %7) : (!cute.coord<"(_,_,_,_,_,?)">, !cute.layout<"(((32,32),1),1,1,1,4,2):(((1,65536),0),0,0,0,32,128)">) -> !cute.int_tuple<"?{div=128}">
      %ptr_326 = cute.add_offset(%ptr_228, %idx_325) : (!cute.ptr<f32, tmem, align<16>>, !cute.int_tuple<"?{div=128}">) -> !cute.ptr<f32, tmem, align<16>>
      %725 = arith.floordivsi %640, %c2_i32 : i32
      %726 = arith.remsi %725, %c2_i32 : i32
      %int_tuple_327 = cute.make_int_tuple(%724) : (i32) -> !cute.int_tuple<"?">
      %ptr_328 = cute.add_offset(%iter_14, %int_tuple_327) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %727 = builtin.unrealized_conversion_cast %ptr_328 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %727, %726, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      cf.cond_br %709, ^bb232, ^bb235
    ^bb232:  // pred: ^bb231
      cf.cond_br %57, ^bb233, ^bb234
    ^bb233:  // pred: ^bb232
      %728 = cute.ptrtoint(%103) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, gmem, align<128>> to i64
      llvm.inline_asm has_side_effects asm_dialect = att "fence.proxy.tensormap::generic.acquire.gpu [$0], 128;", "l" %728 : (i64) -> ()
      cf.br ^bb234
    ^bb234:  // 2 preds: ^bb232, ^bb233
      cf.br ^bb235
    ^bb235:  // 2 preds: ^bb231, ^bb234
      %729 = arith.muli %640, %c4_i32 : i32
      %730 = arith.remsi %729, %c4_i32 : i32
      cf.br ^bb236(%c0_i32, %730 : i32, i32)
    ^bb236(%731: i32, %732: i32):  // 2 preds: ^bb235, ^bb248
      %733 = arith.cmpi slt, %731, %c4_i32 : i32
      cf.cond_br %733, ^bb237, ^bb249
    ^bb237:  // pred: ^bb236
      %coord_329 = cute.make_coord(%731) : (i32) -> !cute.coord<"(_,_,_,?)">
      %idx_330 = cute.crd2idx(%coord_329, %6) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"(((32,32),1),1,1,(1,4)):(((1,65536),0),0,0,(0,32))">) -> !cute.int_tuple<"?{div=32}">
      %ptr_331 = cute.add_offset(%ptr_326, %idx_330) : (!cute.ptr<f32, tmem, align<16>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f32, tmem, align<16>>
      cf.br ^bb238(%c0_i32 : i32)
    ^bb238(%734: i32):  // 2 preds: ^bb237, ^bb239
      %735 = arith.cmpi slt, %734, %616 : i32
      cf.cond_br %735, ^bb239, ^bb240 {llvm.loop_annotation = #loop_annotation}
    ^bb239:  // pred: ^bb238
      %736 = "cute_nvgpu.arch.copy.SM100.tmem_load"(%ptr_331) <{num_b = 32 : i32, num_dp = 32 : i32, num_rep = 32 : i32}> : (!cute.ptr<f32, tmem, align<16>>) -> vector<32xi32>
      llvm.store %736, %617 : vector<32xi32>, !llvm.ptr
      %737 = arith.addi %734, %c1_i32 : i32
      cf.br ^bb238(%737 : i32)
    ^bb240:  // pred: ^bb238
      %738 = cute.memref.load_vec %view_267 : !memref_rmem_f32_1
      %739 = arith.truncf %738 : vector<32xf32> to vector<32xf16>
      cute.memref.store_vec %739, %view_236 : !memref_rmem_f16_1
      %coord_332 = cute.make_coord(%732) : (i32) -> !cute.coord<"(_,_,_,?)">
      %idx_333 = cute.crd2idx(%coord_332, %5) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((1,32),1,1,(1,4)):((0,1),0,0,(0,4096))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_334 = cute.add_offset(%swizzled, %idx_333) : (!cute.ptr<f16, smem, align<64>, S<2,4,3>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, smem, align<64>, S<2,4,3>>
      %740 = builtin.unrealized_conversion_cast %ptr_334 : !cute.ptr<f16, smem, align<64>, S<2,4,3>> to !llvm.ptr<3>
      %ptr_335 = cute.add_offset(%swizzled_270, %idx_333) : (!cute.ptr<f16, smem, align<16>, S<2,4,3>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, smem, align<16>, S<2,4,3>>
      %741 = builtin.unrealized_conversion_cast %ptr_335 : !cute.ptr<f16, smem, align<16>, S<2,4,3>> to !llvm.ptr<3>
      %ptr_336 = cute.add_offset(%swizzled_273, %idx_333) : (!cute.ptr<f16, smem, align<32>, S<2,4,3>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, smem, align<32>, S<2,4,3>>
      %742 = builtin.unrealized_conversion_cast %ptr_336 : !cute.ptr<f16, smem, align<32>, S<2,4,3>> to !llvm.ptr<3>
      %ptr_337 = cute.add_offset(%swizzled_276, %idx_333) : (!cute.ptr<f16, smem, align<16>, S<2,4,3>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, smem, align<16>, S<2,4,3>>
      %743 = builtin.unrealized_conversion_cast %ptr_337 : !cute.ptr<f16, smem, align<16>, S<2,4,3>> to !llvm.ptr<3>
      cf.br ^bb241(%c0_i32 : i32)
    ^bb241(%744: i32):  // 2 preds: ^bb240, ^bb242
      %745 = arith.cmpi slt, %744, %616 : i32
      cf.cond_br %745, ^bb242, ^bb243 {llvm.loop_annotation = #loop_annotation}
    ^bb242:  // pred: ^bb241
      %746 = llvm.load %618 {alignment = 16 : i64} : !llvm.ptr -> vector<8xf16>
      llvm.store %746, %740 {alignment = 16 : i64} : vector<8xf16>, !llvm.ptr<3>
      %747 = llvm.load %619 {alignment = 16 : i64} : !llvm.ptr -> vector<8xf16>
      llvm.store %747, %741 {alignment = 16 : i64} : vector<8xf16>, !llvm.ptr<3>
      %748 = llvm.load %620 {alignment = 16 : i64} : !llvm.ptr -> vector<8xf16>
      llvm.store %748, %742 {alignment = 16 : i64} : vector<8xf16>, !llvm.ptr<3>
      %749 = llvm.load %621 {alignment = 16 : i64} : !llvm.ptr -> vector<8xf16>
      llvm.store %749, %743 {alignment = 16 : i64} : vector<8xf16>, !llvm.ptr<3>
      %750 = arith.addi %744, %c1_i32 : i32
      cf.br ^bb241(%750 : i32)
    ^bb243:  // pred: ^bb241
      nvvm.fence.proxy {kind = #nvvm.proxy_kind<async.shared>, space = #nvvm.shared_space<cta>}
      nvvm.barrier id = %c1_i32 number_of_threads = %c128_i32
      cf.cond_br %57, ^bb244, ^bb248
    ^bb244:  // pred: ^bb243
      %coord_338 = cute.make_coord(%732) : (i32) -> !cute.coord<"(_,?)">
      %idx_339 = cute.crd2idx(%coord_338, %2) : (!cute.coord<"(_,?)">, !cute.layout<"((4096,1),(1,4)):((1,0),(0,4096))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_340 = cute.add_offset(%iter_22, %idx_339) : (!cute.ptr<f16, smem, align<1024>, S<2,4,3>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, smem, align<1024>, S<2,4,3>>
      %coord_341 = cute.make_coord(%731) : (i32) -> !cute.coord<"(_,?)">
      %idx_342 = cute.crd2idx(%coord_341, %1) : (!cute.coord<"(_,?)">, !cute.layout<"(((32,128),1),(1,4)):(((1@0,1@1),0),(0,32@0))">) -> !cute.int_tuple<"(?{div=32},0)">
      %tup_343 = cute.add_offset(%tup_323, %idx_342) : (!cute.int_tuple<"(?{div=128},?{div=128},0)">, !cute.int_tuple<"(?{div=32},0)">) -> !cute.int_tuple<"(?{div=32},?{div=128},0)">
      %e0_344, %e1_345, %e2_346 = cute.get_leaves(%tup_343) : !cute.int_tuple<"(?{div=32},?{div=128},0)">
      %751 = cute.ptrtoint(%103) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, gmem, align<128>> to i64
      %iv_347 = cute.assume(%751) : (i64) -> !cute.i64<divby 128>
      %752 = cute.inttoptr(%iv_347) : !cute.i64<divby 128> to !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<128>>
      %int_tuple_348 = cute.make_int_tuple(%e0_344, %e1_345) : (!cute.int_tuple<"?{div=32}">, !cute.int_tuple<"?{div=128}">) -> !cute.int_tuple<"(?{div=32},?{div=128},0)">
      %753 = cute_nvgpu.atom.make_exec_tma(%arg5) : (!cute_nvgpu.atom.non_exec_tiled_tma_store<f16, copy_bits = 65536, tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_store<f16, copy_bits = 65536, mode = tiled, g_stride = <"()"> tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">>
      %754 = cute_nvgpu.atom.set_value(%753, %752 : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<128>>) {field = #cute_nvgpu.atom_copy_field_tmastore<tma_descriptor_ptr>} : !cute_nvgpu.atom.tma_store<f16, copy_bits = 65536, mode = tiled, g_stride = <"()"> tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">>
      %TMADescAddr_349 = cute_nvgpu.get_tma_desc_addr(%754 : !cute_nvgpu.atom.tma_store<f16, copy_bits = 65536, mode = tiled, g_stride = <"()"> tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">>) -> !cute.ptr<generic, align<64>>
      %755 = cute_nvgpu.atom.get_value(%754 : !cute_nvgpu.atom.tma_store<f16, copy_bits = 65536, mode = tiled, g_stride = <"()"> tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">>) {field = #cute_nvgpu.atom_copy_field_tmastore<cache_policy>} : i64
      %756:3 = cute.get_scalars(%int_tuple_348) : !cute.int_tuple<"(?{div=32},?{div=128},0)">
      cf.br ^bb245(%c0_i32 : i32)
    ^bb245(%757: i32):  // 2 preds: ^bb244, ^bb246
      %758 = arith.cmpi slt, %757, %616 : i32
      cf.cond_br %758, ^bb246, ^bb247 {llvm.loop_annotation = #loop_annotation}
    ^bb246:  // pred: ^bb245
      cute_nvgpu.arch.copy.SM100.tma_store(%TMADescAddr_349 : !cute.ptr<generic, align<64>>, %ptr_340 : !cute.ptr<f16, smem, align<1024>, S<2,4,3>>, [%756#0, %756#1, %756#2] : i32, i32, i32) cache_policy = %755 mode = <tiled>
      %759 = arith.addi %757, %c1_i32 : i32
      cf.br ^bb245(%759 : i32)
    ^bb247:  // pred: ^bb245
      nvvm.cp.async.bulk.commit.group
      nvvm.cp.async.bulk.wait_group 3 {read}
      cf.br ^bb248
    ^bb248:  // 2 preds: ^bb243, ^bb247
      nvvm.barrier id = %c1_i32 number_of_threads = %c128_i32
      %760 = arith.addi %732, %c1_i32 : i32
      %761 = arith.cmpi eq, %760, %c4_i32 : i32
      %762 = arith.select %761, %c0_i32, %760 : i32
      %763 = arith.addi %731, %c1_i32 : i32
      cf.br ^bb236(%763, %762 : i32, i32)
    ^bb249:  // pred: ^bb236
      %764 = nvvm.elect.sync -> i1
      cf.cond_br %764, ^bb250, ^bb251
    ^bb250:  // pred: ^bb249
      %ptr_350 = cute.add_offset(%iter_15, %int_tuple_327) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %765 = builtin.unrealized_conversion_cast %ptr_350 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %765, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>} : !llvm.ptr<3>, i32
      cf.br ^bb251
    ^bb251:  // 2 preds: ^bb249, ^bb250
      %766 = arith.addi %639, %574 : i32
      %767 = arith.addi %640, %c1_i32 : i32
      %768 = arith.cmpi sgt, %575, %766 : i32
      %769 = nvvm.mul  hi %766, %multiplier_251 : i32 -> i32
      %770 = arith.subi %766, %769 : i32
      %771 = arith.shrui %770, %578 : i32
      %772 = arith.addi %769, %771 : i32
      %773 = arith.shrui %772, %579 : i32
      %774 = arith.muli %773, %577 : i32
      %775 = arith.subi %766, %774 : i32
      %776 = nvvm.mul  hi %775, %multiplier_254 : i32 -> i32
      %777 = arith.subi %775, %776 : i32
      %778 = arith.shrui %777, %588 : i32
      %779 = arith.addi %776, %778 : i32
      %780 = arith.shrui %779, %589 : i32
      %781 = arith.muli %780, %587 : i32
      %782 = arith.subi %775, %781 : i32
      %783 = nvvm.mul  hi %780, %multiplier_257 : i32 -> i32
      %784 = arith.subi %780, %783 : i32
      %785 = arith.shrui %784, %598 : i32
      %786 = arith.addi %783, %785 : i32
      %787 = arith.shrui %786, %599 : i32
      %788 = arith.muli %787, %597 : i32
      %789 = arith.subi %780, %788 : i32
      %int_tuple_351 = cute.make_int_tuple(%782) : (i32) -> !cute.int_tuple<"?">
      %mul_352 = cute.tuple_mul(%int_tuple_351, %39) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %790 = cute.get_scalars(%mul_352) : !cute.int_tuple<"?">
      %int_tuple_353 = cute.make_int_tuple(%789) : (i32) -> !cute.int_tuple<"?">
      %mul_354 = cute.tuple_mul(%int_tuple_353, %39) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %791 = cute.get_scalars(%mul_354) : !cute.int_tuple<"?">
      %int_tuple_355 = cute.make_int_tuple(%787) : (i32) -> !cute.int_tuple<"?">
      %mul_356 = cute.tuple_mul(%int_tuple_355, %39) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %792 = cute.get_scalars(%mul_356) : !cute.int_tuple<"?">
      cf.br ^bb184(%723, %790, %791, %792, %768, %643, %643, %644, %766, %767 : i32, i32, i32, i32, i1, i32, i32, i32, i32, i32)
    ^bb252:  // pred: ^bb184
      cf.cond_br %57, ^bb253, ^bb254
    ^bb253:  // pred: ^bb252
      cute_nvgpu.arch.sm100.relinquish_tmem_alloc_permit [ cta_1]
      cf.br ^bb254
    ^bb254:  // 2 preds: ^bb252, ^bb253
      nvvm.barrier id = %c1_i32 number_of_threads = %c128_i32
      cf.cond_br %57, ^bb255, ^bb256
    ^bb255:  // pred: ^bb254
      cute_nvgpu.arch.sm100.dealloc_tmem(%tmem_ptr_224, %c256_i32) [ cta_1] : !cute.ptr<f32, tmem, align<16>>, i32
      cf.br ^bb256
    ^bb256:  // 2 preds: ^bb254, ^bb255
      cf.cond_br %57, ^bb257, ^bb258
    ^bb257:  // pred: ^bb256
      %793 = arith.subi %622, %c1_i32 : i32
      %794 = arith.remsi %793, %c6_i32 : i32
      %int_tuple_357 = cute.make_int_tuple(%794) : (i32) -> !cute.int_tuple<"?">
      %ptr_358 = cute.add_offset(%iter_13, %int_tuple_357) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %795 = arith.floordivsi %793, %c6_i32 : i32
      %796 = arith.remsi %795, %c2_i32 : i32
      %797 = builtin.unrealized_conversion_cast %ptr_358 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %797, %796, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      cf.br ^bb258
    ^bb258:  // 2 preds: ^bb256, ^bb257
      cf.br ^bb259
    ^bb259:  // 2 preds: ^bb168, ^bb258
      return
    }
  }
  func.func @cutlass___call_____main__GroupedGemmKernel_object_at__Tensorgmemoi641i64_Tensorgmemoi641i64_Tensorgmemoi641i64_2_Tensorgmemo2441_Tensorgmemo232621_Tensorgmemo2331_2_Tensorgmemo1316(%arg0: !memref_gmem_f16_2, %arg1: !memref_gmem_f16_2, %arg2: !memref_gmem_f16_2, %arg3: !memref_gmem_i32_, %arg4: !memref_gmem_i32_1, %arg5: !memref_gmem_i64_, %arg6: !memref_gmem_i64_1, %arg7: !cuda.stream) -> i32 attributes {llvm.emit_c_interface} {
    %c230400_i64 = arith.constant 230400 : i64
    %c0_i8 = arith.constant 0 : i8
    %c4294967296_i64 = arith.constant 4294967296 : i64
    %c-2147483648_i32 = arith.constant -2147483648 : i32
    %0 = llvm.mlir.constant(2233785415175766016 : i64) : i64
    %1 = llvm.mlir.constant(279330 : i64) : i64
    %2 = llvm.mlir.constant(127 : i64) : i64
    %3 = llvm.mlir.constant(4539628424389459968 : i64) : i64
    %4 = llvm.mlir.constant(287522 : i64) : i64
    %c0_i32 = arith.constant 0 : i32
    %c192_i32 = arith.constant 192 : i32
    %c1_i32 = arith.constant 1 : i32
    %5 = llvm.mlir.constant(1 : i64) : i64
    %6 = llvm.mlir.constant(1 : i8) : i8
    %7 = llvm.mlir.constant(2 : i32) : i32
    %8 = llvm.mlir.constant(32 : i8) : i8
    %9 = llvm.mlir.constant(0 : i8) : i8
    %10 = llvm.mlir.constant(1 : i32) : i32
    %c2_i32 = arith.constant 2 : i32
    %11 = cute.static : !cute.int_tuple<"(0,0,0)">
    %12 = cute.static : !cute.stride<"(1@1,1@0,1@2)">
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
    %false = arith.constant false
    %13 = cute.static : !cute.layout<"((128,128),1,1,2):((65536,1),0,0,128)">
    %14 = cute.recast_layout<32, 32> (%13) : !cute.layout<"((128,128),1,1,2):((65536,1),0,0,128)"> to !cute.layout<"((128,128),1,1,2):((65536,1),0,0,128)">
    %atom = cute.make_atom() : () -> !cute_nvgpu.sm100.mma<128x128x16, num_cta = 1, ab_major = (k, k), elem_type = (f16, f16, f32), frag_kind = ss, c_scale_exp = 0>
    %15 = cute_nvgpu.atom.set_value(%atom, %false : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !cute_nvgpu.sm100.mma<128x128x16, num_cta = 1, ab_major = (k, k), elem_type = (f16, f16, f32), frag_kind = ss, c_scale_exp = 0>
    %16 = cute_nvgpu.atom.set_value(%15, %false : i1) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : !cute_nvgpu.sm100.mma<128x128x16, num_cta = 1, ab_major = (k, k), elem_type = (f16, f16, f32), frag_kind = ss, c_scale_exp = 0>
    %17 = cute_nvgpu.atom.set_value(%16, %false : i1) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : !cute_nvgpu.sm100.mma<128x128x16, num_cta = 1, ab_major = (k, k), elem_type = (f16, f16, f32), frag_kind = ss, c_scale_exp = 0>
    %18 = cute.make_tiled_mma(%17) : !mma_f16_f16_f32_128x128x16_
    %19 = llvm.alloca %c16_i32 x i64 {alignment = 64 : i64} : (i32) -> !llvm.ptr
    %iter = cute.get_iter(%arg0) : !memref_gmem_f16_2
    %lay = cute.get_layout(%arg0) : !memref_gmem_f16_2
    %20:5 = cute.get_scalars(%lay) <{only_dynamic}> : !cute.layout<"(?,?,?):(?{i64},1,?{i64})">
    %21 = arith.extui %20#1 : i32 to i64
    %22 = arith.extui %20#0 : i32 to i64
    %23 = llvm.mul %20#3, %c2_i64 : i64
    %24 = arith.extui %20#2 : i32 to i64
    %25 = llvm.mul %20#4, %c2_i64 : i64
    %26 = cute.ptrtoint(%iter) : !cute.ptr<f16, gmem, align<16>> to i64
    %27 = llvm.getelementptr %19[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %27 : i64, !llvm.ptr
    %28 = llvm.getelementptr %19[0, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %28 : i64, !llvm.ptr
    %29 = llvm.getelementptr %19[0, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %29 : i64, !llvm.ptr
    %30 = llvm.getelementptr %19[0, 3] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %30 : i64, !llvm.ptr
    %31 = llvm.getelementptr %19[0, 4] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %31 : i64, !llvm.ptr
    %32 = llvm.getelementptr %19[0, 5] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %32 : i64, !llvm.ptr
    %33 = llvm.getelementptr %19[0, 6] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %33 : i64, !llvm.ptr
    %34 = llvm.getelementptr %19[0, 7] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %34 : i64, !llvm.ptr
    %35 = llvm.getelementptr %19[0, 8] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %35 : i64, !llvm.ptr
    %36 = llvm.getelementptr %19[0, 9] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %36 : i64, !llvm.ptr
    %37 = llvm.getelementptr %19[0, 10] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %37 : i64, !llvm.ptr
    %38 = llvm.getelementptr %19[0, 11] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %38 : i64, !llvm.ptr
    %39 = llvm.getelementptr %19[0, 12] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %39 : i64, !llvm.ptr
    %40 = llvm.getelementptr %19[0, 13] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %40 : i64, !llvm.ptr
    %41 = llvm.getelementptr %19[0, 14] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %41 : i64, !llvm.ptr
    %42 = llvm.getelementptr %19[0, 15] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %42 : i64, !llvm.ptr
    %43 = llvm.udiv %26, %c16_i64 : i64
    %44 = llvm.and %43, %c9007199254740991_i64 : i64
    %45 = llvm.shl %44, %c4_i64 : i64
    llvm.store %45, %27 : i64, !llvm.ptr
    %46 = llvm.sub %22, %c1_i64 : i64
    %47 = llvm.sub %24, %c1_i64 : i64
    %48 = llvm.sub %c1_i64, %c1_i64 : i64
    %49 = llvm.mul %46, %23 : i64
    %50 = llvm.mul %47, %25 : i64
    %51 = llvm.mul %48, %c0_i64 : i64
    %52 = llvm.add %49, %50 : i64
    %53 = llvm.add %51, %51 : i64
    %54 = llvm.mul %21, %c16_i64 : i64
    %55 = llvm.udiv %54, %c8_i64 : i64
    %56 = llvm.add %55, %52 : i64
    %57 = llvm.add %56, %53 : i64
    %58 = llvm.icmp "uge" %57, %c131072_i64 : i64
    %59 = llvm.zext %58 : i1 to i64
    %60 = llvm.shl %59, %c21_i64 : i64
    %61 = llvm.udiv %23, %c16_i64 : i64
    %62 = llvm.shl %61, %c32_i64 : i64
    %63 = llvm.or %c0_i64, %60 : i64
    %64 = llvm.or %63, %62 : i64
    %65 = llvm.or %4, %64 : i64
    llvm.store %65, %28 : i64, !llvm.ptr
    %66 = llvm.udiv %25, %c16_i64 : i64
    %67 = llvm.and %66, %c4294967295_i64 : i64
    %68 = llvm.shl %67, %c0_i64 : i64
    %69 = llvm.udiv %c0_i64, %c16_i64 : i64
    %70 = llvm.shl %69, %c32_i64 : i64
    %71 = llvm.or %68, %70 : i64
    llvm.store %71, %29 : i64, !llvm.ptr
    %72 = llvm.and %69, %c4294967295_i64 : i64
    %73 = llvm.shl %72, %c0_i64 : i64
    %74 = llvm.lshr %23, %c36_i64 : i64
    %75 = llvm.and %74, %c15_i64 : i64
    %76 = llvm.shl %75, %c32_i64 : i64
    %77 = llvm.lshr %25, %c36_i64 : i64
    %78 = llvm.and %77, %c15_i64 : i64
    %79 = llvm.shl %78, %c36_i64 : i64
    %80 = llvm.lshr %c0_i64, %c36_i64 : i64
    %81 = llvm.and %80, %c15_i64 : i64
    %82 = llvm.shl %81, %c40_i64 : i64
    %83 = llvm.shl %80, %c44_i64 : i64
    %84 = llvm.or %76, %79 : i64
    %85 = llvm.or %82, %83 : i64
    %86 = llvm.or %84, %85 : i64
    %87 = llvm.or %73, %86 : i64
    llvm.store %87, %30 : i64, !llvm.ptr
    %88 = llvm.sub %21, %c1_i64 : i64
    %89 = llvm.and %88, %c4294967295_i64 : i64
    %90 = llvm.shl %89, %c0_i64 : i64
    %91 = llvm.shl %46, %c32_i64 : i64
    %92 = llvm.or %90, %91 : i64
    llvm.store %92, %31 : i64, !llvm.ptr
    %93 = llvm.and %47, %c4294967295_i64 : i64
    %94 = llvm.shl %93, %c0_i64 : i64
    %95 = llvm.shl %48, %c32_i64 : i64
    %96 = llvm.or %94, %95 : i64
    llvm.store %96, %32 : i64, !llvm.ptr
    %97 = llvm.and %48, %c4294967295_i64 : i64
    %98 = llvm.or %97, %c0_i64 : i64
    %99 = llvm.or %98, %3 : i64
    llvm.store %99, %33 : i64, !llvm.ptr
    llvm.store %2, %34 : i64, !llvm.ptr
    %100 = builtin.unrealized_conversion_cast %19 : !llvm.ptr to !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>>
    %101 = cute.ptrtoint(%100) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>> to i64
    %102 = llvm.inttoptr %101 : i64 to !llvm.ptr
    %103 = llvm.load %102 {nontemporal} : !llvm.ptr -> !llvm.struct<(array<16 x i64>)>
    %104 = builtin.unrealized_conversion_cast %103 : !llvm.struct<(array<16 x i64>)> to !cute_nvgpu.tma_descriptor_tiled
    %atom_0 = cute.make_atom() : () -> !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>
    %105 = cute_nvgpu.atom.set_value(%atom_0, %104 : !cute_nvgpu.tma_descriptor_tiled) {field = #cute_nvgpu.atom_copy_field_non_exec_tma_load<tma_desc>} : !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>
    %106 = cute.get_shape(%lay) : (!cute.layout<"(?,?,?):(?{i64},1,?{i64})">) -> !cute.shape<"(?,?,?)">
    %lay_1 = cute.make_layout(%106, %12) : !cute.layout<"(?,?,?):(1@1,1@0,1@2)">
    %view = cute.make_view(%11, %lay_1) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">
    %107 = llvm.alloca %c16_i32 x i64 {alignment = 64 : i64} : (i32) -> !llvm.ptr
    %iter_2 = cute.get_iter(%arg1) : !memref_gmem_f16_2
    %lay_3 = cute.get_layout(%arg1) : !memref_gmem_f16_2
    %108:5 = cute.get_scalars(%lay_3) <{only_dynamic}> : !cute.layout<"(?,?,?):(?{i64},1,?{i64})">
    %109 = arith.extui %108#1 : i32 to i64
    %110 = arith.extui %108#0 : i32 to i64
    %111 = llvm.mul %108#3, %c2_i64 : i64
    %112 = arith.extui %108#2 : i32 to i64
    %113 = llvm.mul %108#4, %c2_i64 : i64
    %114 = cute.ptrtoint(%iter_2) : !cute.ptr<f16, gmem, align<16>> to i64
    %115 = llvm.getelementptr %107[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %115 : i64, !llvm.ptr
    %116 = llvm.getelementptr %107[0, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %116 : i64, !llvm.ptr
    %117 = llvm.getelementptr %107[0, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %117 : i64, !llvm.ptr
    %118 = llvm.getelementptr %107[0, 3] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %118 : i64, !llvm.ptr
    %119 = llvm.getelementptr %107[0, 4] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %119 : i64, !llvm.ptr
    %120 = llvm.getelementptr %107[0, 5] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %120 : i64, !llvm.ptr
    %121 = llvm.getelementptr %107[0, 6] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %121 : i64, !llvm.ptr
    %122 = llvm.getelementptr %107[0, 7] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %122 : i64, !llvm.ptr
    %123 = llvm.getelementptr %107[0, 8] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %123 : i64, !llvm.ptr
    %124 = llvm.getelementptr %107[0, 9] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %124 : i64, !llvm.ptr
    %125 = llvm.getelementptr %107[0, 10] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %125 : i64, !llvm.ptr
    %126 = llvm.getelementptr %107[0, 11] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %126 : i64, !llvm.ptr
    %127 = llvm.getelementptr %107[0, 12] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %127 : i64, !llvm.ptr
    %128 = llvm.getelementptr %107[0, 13] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %128 : i64, !llvm.ptr
    %129 = llvm.getelementptr %107[0, 14] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %129 : i64, !llvm.ptr
    %130 = llvm.getelementptr %107[0, 15] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %130 : i64, !llvm.ptr
    %131 = llvm.udiv %114, %c16_i64 : i64
    %132 = llvm.and %131, %c9007199254740991_i64 : i64
    %133 = llvm.shl %132, %c4_i64 : i64
    llvm.store %133, %115 : i64, !llvm.ptr
    %134 = llvm.sub %110, %c1_i64 : i64
    %135 = llvm.sub %112, %c1_i64 : i64
    %136 = llvm.mul %134, %111 : i64
    %137 = llvm.mul %135, %113 : i64
    %138 = llvm.add %136, %137 : i64
    %139 = llvm.mul %109, %c16_i64 : i64
    %140 = llvm.udiv %139, %c8_i64 : i64
    %141 = llvm.add %140, %138 : i64
    %142 = llvm.add %141, %53 : i64
    %143 = llvm.icmp "uge" %142, %c131072_i64 : i64
    %144 = llvm.zext %143 : i1 to i64
    %145 = llvm.shl %144, %c21_i64 : i64
    %146 = llvm.udiv %111, %c16_i64 : i64
    %147 = llvm.shl %146, %c32_i64 : i64
    %148 = llvm.or %c0_i64, %145 : i64
    %149 = llvm.or %148, %147 : i64
    %150 = llvm.or %4, %149 : i64
    llvm.store %150, %116 : i64, !llvm.ptr
    %151 = llvm.udiv %113, %c16_i64 : i64
    %152 = llvm.and %151, %c4294967295_i64 : i64
    %153 = llvm.shl %152, %c0_i64 : i64
    %154 = llvm.or %153, %70 : i64
    llvm.store %154, %117 : i64, !llvm.ptr
    %155 = llvm.lshr %111, %c36_i64 : i64
    %156 = llvm.and %155, %c15_i64 : i64
    %157 = llvm.shl %156, %c32_i64 : i64
    %158 = llvm.lshr %113, %c36_i64 : i64
    %159 = llvm.and %158, %c15_i64 : i64
    %160 = llvm.shl %159, %c36_i64 : i64
    %161 = llvm.or %157, %160 : i64
    %162 = llvm.or %161, %85 : i64
    %163 = llvm.or %73, %162 : i64
    llvm.store %163, %118 : i64, !llvm.ptr
    %164 = llvm.sub %109, %c1_i64 : i64
    %165 = llvm.and %164, %c4294967295_i64 : i64
    %166 = llvm.shl %165, %c0_i64 : i64
    %167 = llvm.shl %134, %c32_i64 : i64
    %168 = llvm.or %166, %167 : i64
    llvm.store %168, %119 : i64, !llvm.ptr
    %169 = llvm.and %135, %c4294967295_i64 : i64
    %170 = llvm.shl %169, %c0_i64 : i64
    %171 = llvm.or %170, %95 : i64
    llvm.store %171, %120 : i64, !llvm.ptr
    llvm.store %99, %121 : i64, !llvm.ptr
    llvm.store %2, %122 : i64, !llvm.ptr
    %172 = builtin.unrealized_conversion_cast %107 : !llvm.ptr to !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>>
    %173 = cute.ptrtoint(%172) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>> to i64
    %174 = llvm.inttoptr %173 : i64 to !llvm.ptr
    %175 = llvm.load %174 {nontemporal} : !llvm.ptr -> !llvm.struct<(array<16 x i64>)>
    %176 = builtin.unrealized_conversion_cast %175 : !llvm.struct<(array<16 x i64>)> to !cute_nvgpu.tma_descriptor_tiled
    %177 = cute_nvgpu.atom.set_value(%atom_0, %176 : !cute_nvgpu.tma_descriptor_tiled) {field = #cute_nvgpu.atom_copy_field_non_exec_tma_load<tma_desc>} : !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>
    %178 = cute.get_shape(%lay_3) : (!cute.layout<"(?,?,?):(?{i64},1,?{i64})">) -> !cute.shape<"(?,?,?)">
    %lay_4 = cute.make_layout(%178, %12) : !cute.layout<"(?,?,?):(1@1,1@0,1@2)">
    %view_5 = cute.make_view(%11, %lay_4) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">
    %179 = llvm.alloca %c16_i32 x i64 {alignment = 64 : i64} : (i32) -> !llvm.ptr
    %iter_6 = cute.get_iter(%arg2) : !memref_gmem_f16_2
    %lay_7 = cute.get_layout(%arg2) : !memref_gmem_f16_2
    %180:5 = cute.get_scalars(%lay_7) <{only_dynamic}> : !cute.layout<"(?,?,?):(?{i64},1,?{i64})">
    %181 = arith.extui %180#1 : i32 to i64
    %182 = arith.extui %180#0 : i32 to i64
    %183 = llvm.mul %180#3, %c2_i64 : i64
    %184 = arith.extui %180#2 : i32 to i64
    %185 = llvm.mul %180#4, %c2_i64 : i64
    %186 = cute.ptrtoint(%iter_6) : !cute.ptr<f16, gmem, align<16>> to i64
    %187 = llvm.getelementptr %179[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %187 : i64, !llvm.ptr
    %188 = llvm.getelementptr %179[0, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %188 : i64, !llvm.ptr
    %189 = llvm.getelementptr %179[0, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %189 : i64, !llvm.ptr
    %190 = llvm.getelementptr %179[0, 3] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %190 : i64, !llvm.ptr
    %191 = llvm.getelementptr %179[0, 4] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %191 : i64, !llvm.ptr
    %192 = llvm.getelementptr %179[0, 5] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %192 : i64, !llvm.ptr
    %193 = llvm.getelementptr %179[0, 6] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %193 : i64, !llvm.ptr
    %194 = llvm.getelementptr %179[0, 7] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %194 : i64, !llvm.ptr
    %195 = llvm.getelementptr %179[0, 8] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %195 : i64, !llvm.ptr
    %196 = llvm.getelementptr %179[0, 9] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %196 : i64, !llvm.ptr
    %197 = llvm.getelementptr %179[0, 10] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %197 : i64, !llvm.ptr
    %198 = llvm.getelementptr %179[0, 11] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %198 : i64, !llvm.ptr
    %199 = llvm.getelementptr %179[0, 12] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %199 : i64, !llvm.ptr
    %200 = llvm.getelementptr %179[0, 13] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %200 : i64, !llvm.ptr
    %201 = llvm.getelementptr %179[0, 14] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %201 : i64, !llvm.ptr
    %202 = llvm.getelementptr %179[0, 15] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %202 : i64, !llvm.ptr
    %203 = llvm.udiv %186, %c16_i64 : i64
    %204 = llvm.and %203, %c9007199254740991_i64 : i64
    %205 = llvm.shl %204, %c4_i64 : i64
    llvm.store %205, %187 : i64, !llvm.ptr
    %206 = llvm.sub %182, %c1_i64 : i64
    %207 = llvm.sub %184, %c1_i64 : i64
    %208 = llvm.mul %206, %183 : i64
    %209 = llvm.mul %207, %185 : i64
    %210 = llvm.add %208, %209 : i64
    %211 = llvm.mul %181, %c16_i64 : i64
    %212 = llvm.udiv %211, %c8_i64 : i64
    %213 = llvm.add %212, %210 : i64
    %214 = llvm.add %213, %53 : i64
    %215 = llvm.icmp "uge" %214, %c131072_i64 : i64
    %216 = llvm.zext %215 : i1 to i64
    %217 = llvm.shl %216, %c21_i64 : i64
    %218 = llvm.udiv %183, %c16_i64 : i64
    %219 = llvm.shl %218, %c32_i64 : i64
    %220 = llvm.or %c0_i64, %217 : i64
    %221 = llvm.or %220, %219 : i64
    %222 = llvm.or %1, %221 : i64
    llvm.store %222, %188 : i64, !llvm.ptr
    %223 = llvm.udiv %185, %c16_i64 : i64
    %224 = llvm.and %223, %c4294967295_i64 : i64
    %225 = llvm.shl %224, %c0_i64 : i64
    %226 = llvm.or %225, %70 : i64
    llvm.store %226, %189 : i64, !llvm.ptr
    %227 = llvm.lshr %183, %c36_i64 : i64
    %228 = llvm.and %227, %c15_i64 : i64
    %229 = llvm.shl %228, %c32_i64 : i64
    %230 = llvm.lshr %185, %c36_i64 : i64
    %231 = llvm.and %230, %c15_i64 : i64
    %232 = llvm.shl %231, %c36_i64 : i64
    %233 = llvm.or %229, %232 : i64
    %234 = llvm.or %233, %85 : i64
    %235 = llvm.or %73, %234 : i64
    llvm.store %235, %190 : i64, !llvm.ptr
    %236 = llvm.sub %181, %c1_i64 : i64
    %237 = llvm.and %236, %c4294967295_i64 : i64
    %238 = llvm.shl %237, %c0_i64 : i64
    %239 = llvm.shl %206, %c32_i64 : i64
    %240 = llvm.or %238, %239 : i64
    llvm.store %240, %191 : i64, !llvm.ptr
    %241 = llvm.and %207, %c4294967295_i64 : i64
    %242 = llvm.shl %241, %c0_i64 : i64
    %243 = llvm.or %242, %95 : i64
    llvm.store %243, %192 : i64, !llvm.ptr
    %244 = llvm.or %98, %0 : i64
    llvm.store %244, %193 : i64, !llvm.ptr
    llvm.store %2, %194 : i64, !llvm.ptr
    %245 = builtin.unrealized_conversion_cast %179 : !llvm.ptr to !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>>
    %246 = cute.ptrtoint(%245) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>> to i64
    %247 = llvm.inttoptr %246 : i64 to !llvm.ptr
    %248 = llvm.load %247 {nontemporal} : !llvm.ptr -> !llvm.struct<(array<16 x i64>)>
    %249 = builtin.unrealized_conversion_cast %248 : !llvm.struct<(array<16 x i64>)> to !cute_nvgpu.tma_descriptor_tiled
    %atom_8 = cute.make_atom() : () -> !cute_nvgpu.atom.non_exec_tiled_tma_store<f16, copy_bits = 65536, tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>
    %250 = cute_nvgpu.atom.set_value(%atom_8, %249 : !cute_nvgpu.tma_descriptor_tiled) {field = #cute_nvgpu.atom_copy_field_non_exec_tma_store<tma_desc>} : !cute_nvgpu.atom.non_exec_tiled_tma_store<f16, copy_bits = 65536, tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>
    %251 = cute.get_shape(%lay_7) : (!cute.layout<"(?,?,?):(?{i64},1,?{i64})">) -> !cute.shape<"(?,?,?)">
    %lay_9 = cute.make_layout(%251, %12) : !cute.layout<"(?,?,?):(1@1,1@0,1@2)">
    %view_10 = cute.make_view(%11, %lay_9) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">
    %int_tuple = cute.make_int_tuple() : () -> !cute.int_tuple<"(1,1,2)">
    %dyn = cute.derefine(%int_tuple) : !cute.int_tuple<"(1,1,2)"> to !cute.int_tuple<"(1,1,?)">
    %252 = cute.get_scalars(%dyn) <{only_dynamic}> : !cute.int_tuple<"(1,1,?)">
    %int_tuple_11 = cute.make_int_tuple(%252) : (i32) -> !cute.int_tuple<"(1,1,?)">
    %e0, %e1, %e2 = cute.get_leaves(%int_tuple_11) : !cute.int_tuple<"(1,1,?)">
    %shape = cute.make_shape(%e2) : (!cute.int_tuple<"?">) -> !cute.shape<"(1,1,?)">
    %lay_12 = cute.make_layout(%shape) : !cute.layout<"(1,1,?):(0,0,1)">
    %sz = cute.size(%lay_12) : (!cute.layout<"(1,1,?):(0,0,1)">) -> !cute.int_tuple<"?">
    %e0_13 = cute.get_leaves(%sz) : !cute.int_tuple<"?">
    %253 = cute.get_scalars(%e0_13) : !cute.int_tuple<"?">
    %254 = arith.cmpi eq, %253, %10 : i32
    cf.cond_br %254, ^bb1, ^bb2
  ^bb1:  // pred: ^bb0
    cf.br ^bb10(%9 : i8)
  ^bb2:  // pred: ^bb0
    %255 = arith.cmpi uge, %253, %c-2147483648_i32 : i32
    cf.cond_br %255, ^bb3, ^bb4
  ^bb3:  // pred: ^bb2
    cf.br ^bb8(%8 : i8)
  ^bb4:  // pred: ^bb2
    cf.br ^bb5(%7, %6 : i32, i8)
  ^bb5(%256: i32, %257: i8):  // 2 preds: ^bb4, ^bb6
    %258 = arith.cmpi ult, %256, %253 : i32
    cf.cond_br %258, ^bb6(%256, %257 : i32, i8), ^bb7
  ^bb6(%259: i32, %260: i8):  // pred: ^bb5
    %261 = arith.muli %259, %7 : i32
    %262 = arith.addi %260, %6 : i8
    cf.br ^bb5(%261, %262 : i32, i8)
  ^bb7:  // pred: ^bb5
    cf.br ^bb8(%257 : i8)
  ^bb8(%263: i8):  // 2 preds: ^bb3, ^bb7
    cf.br ^bb9
  ^bb9:  // pred: ^bb8
    cf.br ^bb10(%263 : i8)
  ^bb10(%264: i8):  // 2 preds: ^bb1, ^bb9
    cf.br ^bb11
  ^bb11:  // pred: ^bb10
    %265 = arith.extui %264 : i8 to i64
    %266 = arith.extui %253 : i32 to i64
    %267 = arith.shli %5, %265 : i64
    %268 = arith.subi %267, %266 : i64
    %269 = arith.muli %268, %c4294967296_i64 : i64
    %270 = arith.divui %269, %266 : i64
    %271 = arith.addi %270, %5 : i64
    %272 = arith.trunci %271 : i64 to i32
    %273 = arith.minui %264, %6 : i8
    %274 = arith.cmpi ult, %264, %6 : i8
    %275 = arith.subi %264, %6 : i8
    %276 = arith.select %274, %9, %275 : i8
    %277 = cute.fast_divmod.make_divisor(%253, %272, %273, %276) : i32 -> !cute.fast_divmod_divisor<32>
    %278 = cute.fast_divmod.make_divisor(%c1_i32, %c1_i32, %c0_i8, %9) : i32 -> !cute.fast_divmod_divisor<32>
    %279 = cute.get_shape(%lay_12) : (!cute.layout<"(1,1,?):(0,0,1)">) -> !cute.shape<"(1,1,?)">
    %e0_14, %e1_15, %e2_16 = cute.get_leaves(%279) : !cute.shape<"(1,1,?)">
    %itup = cute.to_int_tuple(%e2_16) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %int_tuple_17 = cute.make_int_tuple(%itup) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"(1,1,?)">
    %sz_18 = cute.size(%int_tuple_17) : (!cute.int_tuple<"(1,1,?)">) -> !cute.int_tuple<"?">
    %e0_19 = cute.get_leaves(%sz_18) : !cute.int_tuple<"?">
    %280 = cute.get_scalars(%e0_19) : !cute.int_tuple<"?">
    %281 = arith.minsi %280, %c1_i32 : i32
    %282 = cuda.launch_cfg.create<max_attrs = 2 : i32> (blockDim = (%c192_i32, %c1_i32, %c1_i32), dynamicSmemBytes = %c230400_i64, gridDim = (%c1_i32, %c1_i32, %281), stream = %arg7) : i32, i32, i32, i64, i32, i32, i32, !cuda.stream -> !cuda.launch_cfg<max_attrs = 2>
    cuda.launch_cfg.cluster_dim[%282] (%c1_i32, %c1_i32, %c1_i32) : !cuda.launch_cfg<max_attrs = 2>, i32, i32, i32
    %283 = cuda.launch_ex @kernels::@kernel_cutlass_kernel___main__GroupedGemmKernel_object_at__TiledMMA_ThrLayoutVMNK11110000_PermutationMNK____MMAAtom_ThrID10_ShapeMNK12812816_TVLayoutA1128161281128_TVLayoutB1128161281128__0<%282> (%18, %105, %view, %177, %view_5, %250, %view_10, %c2_i32, %277, %278, %278, %arg3, %arg4, %arg5, %arg6) : !cuda.launch_cfg<max_attrs = 2>, (!mma_f16_f16_f32_128x128x16_, !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>, !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">, !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>, !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">, !cute_nvgpu.atom.non_exec_tiled_tma_store<f16, copy_bits = 65536, tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>, !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">, i32, !cute.fast_divmod_divisor<32>, !cute.fast_divmod_divisor<32>, !cute.fast_divmod_divisor<32>, !memref_gmem_i32_, !memref_gmem_i32_1, !memref_gmem_i64_, !memref_gmem_i64_1) -> !cuda.result
    %284 = cuda.cast %283 : !cuda.result -> i32
    cuda.return_if_error %284 : i32
    return %c0_i32 : i32
  }
}
