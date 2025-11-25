!copy_simt = !cute.tiled_copy<!cute_nvgpu.atom.universal_copy<f16>, layout_copy_tv = <"((32,4),(32,1)):((4,1),(128,0))">, tiler_mn = <"[(4,32):(32,1);32:1]">>
!memref_gmem_f16_ = !cute.memref<f16, gmem, align<16>, "(?,?,1):(?,?,0)">
!memref_gmem_f16_1 = !cute.memref<f16, gmem, align<16>, "(?,?,?):(?,?,?)">
!memref_gmem_f16_2 = !cute.memref<f16, gmem, align<16>, "(?,?,?):(?{i64},1,?{i64})">
!memref_gmem_i32_ = !cute.memref<i32, gmem, align<16>, "(2,4):(4,1)">
!memref_gmem_i32_1 = !cute.memref<i32, gmem, align<16>, "(2,3,2):(6,2,1)">
!memref_gmem_i64_ = !cute.memref<i64, gmem, align<16>, "(2,3):(3,1)">
!memref_gmem_i64_1 = !cute.memref<i64, gmem, "(1,3,16):(1,16,1)">
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
    func.func public @kernel_cutlass_kernel___main__GroupedGemmKernel_object_at__TiledMMA_ThrLayoutVMNK11110000_PermutationMNK____MMAAtom_ThrID10_ShapeMNK12812816_TVLayoutA1128161281128_TVLayoutB1128161281128__0(%arg0: !mma_f16_f16_f32_128x128x16_, %arg1: !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>, %arg2: !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">, %arg3: !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>, %arg4: !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">, %arg5: !cute_nvgpu.atom.non_exec_tiled_tma_store<f16, copy_bits = 65536, tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>, %arg6: !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">, %arg7: i32, %arg8: !memref_gmem_i32_, %arg9: !memref_gmem_i32_1, %arg10: !memref_gmem_i64_, %arg11: !memref_gmem_i64_1) attributes {cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 192, 1, 1>} {
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
      %c3_i32 = arith.constant 3 : i32
      %13 = cute.static : !cute.layout<"((8192,1),6):((1,0),8192)">
      %c32768_i32 = arith.constant 32768 : i32
      %c10000000_i32 = arith.constant 10000000 : i32
      %14 = cute.static : !cute.stride<"(((1@0,1@1),0),64@0)">
      %true = arith.constant true
      %c160_i32 = arith.constant 160 : i32
      %15 = cute.static : !cute.layout<"(2,3,2):(6,2,1)">
      %16 = cute.static : !cute.coord<"2">
      %c31_i32 = arith.constant 31 : i32
      %c16_i32 = arith.constant 16 : i32
      %c8_i32 = arith.constant 8 : i32
      %17 = cute.static : !cute.coord<"1">
      %18 = cute.static : !cute.layout<"(2,4):(4,1)">
      %c-1_i32 = arith.constant -1 : i32
      %19 = cute.static : !cute.coord<"0">
      %20 = cute.static : !cute.layout<"(1,3,16):(1,16,1)">
      %c192_i32 = arith.constant 192 : i32
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
      %false = arith.constant false
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
      %c1_i32 = arith.constant 1 : i32
      %c5_i32 = arith.constant 5 : i32
      %c32_i32 = arith.constant 32 : i32
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
      nvvm.barrier id = %c1_i32 number_of_threads = %c192_i32
      %90 = nvvm.read.ptx.sreg.nctaid.x range <i32, 1, 2147483647> : i32
      %91 = nvvm.read.ptx.sreg.nctaid.y range <i32, 1, 65535> : i32
      %92 = nvvm.read.ptx.sreg.nctaid.z range <i32, 1, 65535> : i32
      %93 = arith.muli %56, %91 : i32
      %94 = arith.muli %93, %90 : i32
      %95 = arith.muli %55, %90 : i32
      %96 = arith.addi %94, %95 : i32
      %97 = arith.addi %96, %54 : i32
      %coord = cute.make_coord(%97) : (i32) -> !cute.coord<"(?,0,_)">
      %idx = cute.crd2idx(%coord, %20) : (!cute.coord<"(?,0,_)">, !cute.layout<"(1,3,16):(1,16,1)">) -> !cute.int_tuple<"?">
      %iter_55 = cute.get_iter(%arg11) : !memref_gmem_i64_1
      %ptr_56 = cute.add_offset(%iter_55, %idx) : (!cute.ptr<i64, gmem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, gmem>
      %98 = cute.ptrtoint(%ptr_56) : !cute.ptr<i64, gmem> to i64
      %iv = cute.assume(%98) : (i64) -> !cute.i64<divby 128>
      %99 = cute.inttoptr(%iv) : !cute.i64<divby 128> to !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, gmem, align<128>>
      %coord_57 = cute.make_coord(%97) : (i32) -> !cute.coord<"(?,1,_)">
      %idx_58 = cute.crd2idx(%coord_57, %20) : (!cute.coord<"(?,1,_)">, !cute.layout<"(1,3,16):(1,16,1)">) -> !cute.int_tuple<"?">
      %ptr_59 = cute.add_offset(%iter_55, %idx_58) : (!cute.ptr<i64, gmem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, gmem>
      %100 = cute.ptrtoint(%ptr_59) : !cute.ptr<i64, gmem> to i64
      %iv_60 = cute.assume(%100) : (i64) -> !cute.i64<divby 128>
      %101 = cute.inttoptr(%iv_60) : !cute.i64<divby 128> to !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, gmem, align<128>>
      %coord_61 = cute.make_coord(%97) : (i32) -> !cute.coord<"(?,2,_)">
      %idx_62 = cute.crd2idx(%coord_61, %20) : (!cute.coord<"(?,2,_)">, !cute.layout<"(1,3,16):(1,16,1)">) -> !cute.int_tuple<"?">
      %ptr_63 = cute.add_offset(%iter_55, %idx_62) : (!cute.ptr<i64, gmem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, gmem>
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
      %107 = cute.get_hier_coord(%56, %lay) : (i32, !cute.layout<"(1,1,?):(0,0,1)">) -> !cute.coord<"(0,0,?)">
      %e0_69, %e1_70, %e2_71 = cute.get_leaves(%107) : !cute.coord<"(0,0,?)">
      %itup = cute.to_int_tuple(%e2_71) : !cute.coord<"?"> to !cute.int_tuple<"?">
      %mul = cute.tuple_mul(%itup, %39) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %108 = cute.get_scalars(%mul) : !cute.int_tuple<"?">
      %109 = nvvm.read.ptx.sreg.laneid range <i32, 0, 32> : i32
      %110 = arith.cmpi sge, %109, %c1_i32 : i32
      %111 = arith.cmpi sge, %109, %c2_i32 : i32
      %112 = arith.cmpi sge, %109, %c4_i32 : i32
      %113 = arith.cmpi sge, %109, %c8_i32 : i32
      %114 = arith.cmpi sge, %109, %c16_i32 : i32
      %iter_72 = cute.get_iter(%arg8) : !memref_gmem_i32_
      %115 = cute.get_scalars(%39) : !cute.int_tuple<"1">
      %116:3 = cute.get_scalars(%lay_49) <{only_dynamic}> : !cute.layout<"(((64,128),1),?,?,?):(((1@0,1@1),0),128@1,64@0,1@2)">
      %shape_73 = cute.make_shape(%116#1) : (i32) -> !cute.shape<"(((64,128),1),?)">
      %lay_74 = cute.make_layout(%shape_73, %14) : !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">
      %117:3 = cute.get_scalars(%lay_53) <{only_dynamic}> : !cute.layout<"(((64,128),1),?,?,?):(((1@0,1@1),0),128@1,64@0,1@2)">
      %shape_75 = cute.make_shape(%117#1) : (i32) -> !cute.shape<"(((64,128),1),?)">
      %lay_76 = cute.make_layout(%shape_75, %14) : !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">
      %118 = cute.ptrtoint(%99) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, gmem, align<128>> to i64
      %iv_77 = cute.assume(%118) : (i64) -> !cute.i64<divby 128>
      %119 = cute.inttoptr(%iv_77) : !cute.i64<divby 128> to !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<128>>
      %120 = cute_nvgpu.atom.make_exec_tma(%arg1) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>
      %121 = cute.ptrtoint(%101) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, gmem, align<128>> to i64
      %iv_78 = cute.assume(%121) : (i64) -> !cute.i64<divby 128>
      %122 = cute.inttoptr(%iv_78) : !cute.i64<divby 128> to !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<128>>
      %123 = cute_nvgpu.atom.make_exec_tma(%arg3) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>
      cf.br ^bb18(%false, %c0_i32, %108, %106, %c-1_i32, %c0_i32, %c0_i32, %56, %c0_i32 : i1, i32, i32, i1, i32, i32, i32, i32, i32)
    ^bb18(%124: i1, %125: i32, %126: i32, %127: i1, %128: i32, %129: i32, %130: i32, %131: i32, %132: i32):  // 2 preds: ^bb17, ^bb95
      cf.cond_br %127, ^bb19(%124, %125, %126, %128, %129, %130, %131, %132 : i1, i32, i32, i32, i32, i32, i32, i32), ^bb96
    ^bb19(%133: i1, %134: i32, %135: i32, %136: i32, %137: i32, %138: i32, %139: i32, %140: i32):  // pred: ^bb18
      %141 = arith.cmpi sge, %135, %138 : i32
      cf.br ^bb20(%141, %137, %138, %138 : i1, i32, i32, i32)
    ^bb20(%142: i1, %143: i32, %144: i32, %145: i32):  // 2 preds: ^bb19, ^bb52
      cf.cond_br %142, ^bb21(%143, %144, %145 : i32, i32, i32), ^bb53
    ^bb21(%146: i32, %147: i32, %148: i32):  // pred: ^bb20
      %149 = arith.addi %146, %109 : i32
      %150 = arith.cmpi slt, %149, %c2_i32 : i32
      cf.cond_br %150, ^bb22, ^bb26
    ^bb22:  // pred: ^bb21
      %rmem = cute.memref.alloca() : !memref_rmem_i32_
      %coord_79 = cute.make_coord(%149) : (i32) -> !cute.coord<"(?,_)">
      %idx_80 = cute.crd2idx(%coord_79, %18) : (!cute.coord<"(?,_)">, !cute.layout<"(2,4):(4,1)">) -> !cute.int_tuple<"?{div=4}">
      %iter_81 = cute.get_iter(%arg8) : !memref_gmem_i32_
      %ptr_82 = cute.add_offset(%iter_81, %idx_80) : (!cute.ptr<i32, gmem, align<16>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<i32, gmem, align<16>>
      %iter_83 = cute.get_iter(%rmem) : !memref_rmem_i32_
      %151 = cute.get_scalars(%39) : !cute.int_tuple<"1">
      %152 = builtin.unrealized_conversion_cast %ptr_82 : !cute.ptr<i32, gmem, align<16>> to !llvm.ptr<1>
      %153 = builtin.unrealized_conversion_cast %iter_83 : !cute.ptr<i32, rmem, align<32>> to !llvm.ptr
      cf.br ^bb23(%c0_i32 : i32)
    ^bb23(%154: i32):  // 2 preds: ^bb22, ^bb24
      %155 = arith.cmpi slt, %154, %151 : i32
      cf.cond_br %155, ^bb24, ^bb25 {llvm.loop_annotation = #loop_annotation}
    ^bb24:  // pred: ^bb23
      %156 = llvm.load %152 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<4xi32>
      llvm.store %156, %153 {alignment = 16 : i64} : vector<4xi32>, !llvm.ptr
      %157 = arith.addi %154, %c1_i32 : i32
      cf.br ^bb23(%157 : i32)
    ^bb25:  // pred: ^bb23
      %158 = cute.memref.load(%rmem, %19) : (!memref_rmem_i32_, !cute.coord<"0">) -> i32
      %159 = arith.addi %158, %c127_i32 : i32
      %160 = arith.floordivsi %159, %c128_i32 : i32
      %161 = cute.memref.load(%rmem, %17) : (!memref_rmem_i32_, !cute.coord<"1">) -> i32
      %162 = arith.addi %161, %c127_i32 : i32
      %163 = arith.floordivsi %162, %c128_i32 : i32
      %164 = arith.muli %160, %163 : i32
      cf.br ^bb27(%164 : i32)
    ^bb26:  // pred: ^bb21
      cf.br ^bb27(%c0_i32 : i32)
    ^bb27(%165: i32):  // 2 preds: ^bb25, ^bb26
      cf.br ^bb28
    ^bb28:  // pred: ^bb27
      %166 = nvvm.shfl.sync  up %c-1_i32, %165, %c1_i32, %c0_i32 : i32 -> i32
      cf.cond_br %110, ^bb29, ^bb30
    ^bb29:  // pred: ^bb28
      %167 = arith.addi %165, %166 : i32
      cf.br ^bb31(%167 : i32)
    ^bb30:  // pred: ^bb28
      cf.br ^bb31(%165 : i32)
    ^bb31(%168: i32):  // 2 preds: ^bb29, ^bb30
      cf.br ^bb32
    ^bb32:  // pred: ^bb31
      %169 = nvvm.shfl.sync  up %c-1_i32, %168, %c2_i32, %c0_i32 : i32 -> i32
      cf.cond_br %111, ^bb33, ^bb34
    ^bb33:  // pred: ^bb32
      %170 = arith.addi %168, %169 : i32
      cf.br ^bb35(%170 : i32)
    ^bb34:  // pred: ^bb32
      cf.br ^bb35(%168 : i32)
    ^bb35(%171: i32):  // 2 preds: ^bb33, ^bb34
      cf.br ^bb36
    ^bb36:  // pred: ^bb35
      %172 = nvvm.shfl.sync  up %c-1_i32, %171, %c4_i32, %c0_i32 : i32 -> i32
      cf.cond_br %112, ^bb37, ^bb38
    ^bb37:  // pred: ^bb36
      %173 = arith.addi %171, %172 : i32
      cf.br ^bb39(%173 : i32)
    ^bb38:  // pred: ^bb36
      cf.br ^bb39(%171 : i32)
    ^bb39(%174: i32):  // 2 preds: ^bb37, ^bb38
      cf.br ^bb40
    ^bb40:  // pred: ^bb39
      %175 = nvvm.shfl.sync  up %c-1_i32, %174, %c8_i32, %c0_i32 : i32 -> i32
      cf.cond_br %113, ^bb41, ^bb42
    ^bb41:  // pred: ^bb40
      %176 = arith.addi %174, %175 : i32
      cf.br ^bb43(%176 : i32)
    ^bb42:  // pred: ^bb40
      cf.br ^bb43(%174 : i32)
    ^bb43(%177: i32):  // 2 preds: ^bb41, ^bb42
      cf.br ^bb44
    ^bb44:  // pred: ^bb43
      %178 = nvvm.shfl.sync  up %c-1_i32, %177, %c16_i32, %c0_i32 : i32 -> i32
      cf.cond_br %114, ^bb45, ^bb46
    ^bb45:  // pred: ^bb44
      %179 = arith.addi %177, %178 : i32
      cf.br ^bb47(%179 : i32)
    ^bb46:  // pred: ^bb44
      cf.br ^bb47(%177 : i32)
    ^bb47(%180: i32):  // 2 preds: ^bb45, ^bb46
      cf.br ^bb48
    ^bb48:  // pred: ^bb47
      %181 = arith.addi %180, %148 : i32
      %182 = arith.cmpi sge, %135, %181 : i32
      %183 = nvvm.vote.ballot.sync %c-1_i32, %182 : i32
      %184 = llvm.intr.ctpop(%183) : (i32) -> i32
      %185 = arith.cmpi eq, %184, %c32_i32 : i32
      %186 = arith.addi %184, %146 : i32
      %187 = arith.cmpi eq, %184, %c0_i32 : i32
      %188 = arith.cmpi eq, %187, %false : i1
      cf.cond_br %188, ^bb49, ^bb50
    ^bb49:  // pred: ^bb48
      %189 = arith.subi %184, %c1_i32 : i32
      %190 = nvvm.shfl.sync  idx %c-1_i32, %181, %189, %c31_i32 : i32 -> i32
      cf.br ^bb51(%190 : i32)
    ^bb50:  // pred: ^bb48
      cf.br ^bb51(%148 : i32)
    ^bb51(%191: i32):  // 2 preds: ^bb49, ^bb50
      cf.br ^bb52
    ^bb52:  // pred: ^bb51
      %192 = arith.select %185, %c31_i32, %184 : i32
      %193 = nvvm.shfl.sync  idx %c-1_i32, %181, %192, %c31_i32 : i32 -> i32
      cf.br ^bb20(%185, %186, %191, %193 : i1, i32, i32, i32)
    ^bb53:  // pred: ^bb20
      %rmem_84 = cute.memref.alloca() : !memref_rmem_i32_
      %coord_85 = cute.make_coord(%143) : (i32) -> !cute.coord<"(?,_)">
      %idx_86 = cute.crd2idx(%coord_85, %18) : (!cute.coord<"(?,_)">, !cute.layout<"(2,4):(4,1)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_87 = cute.add_offset(%iter_72, %idx_86) : (!cute.ptr<i32, gmem, align<16>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<i32, gmem, align<16>>
      %iter_88 = cute.get_iter(%rmem_84) : !memref_rmem_i32_
      %194 = builtin.unrealized_conversion_cast %ptr_87 : !cute.ptr<i32, gmem, align<16>> to !llvm.ptr<1>
      %195 = builtin.unrealized_conversion_cast %iter_88 : !cute.ptr<i32, rmem, align<32>> to !llvm.ptr
      cf.br ^bb54(%c0_i32 : i32)
    ^bb54(%196: i32):  // 2 preds: ^bb53, ^bb55
      %197 = arith.cmpi slt, %196, %115 : i32
      cf.cond_br %197, ^bb55, ^bb56 {llvm.loop_annotation = #loop_annotation}
    ^bb55:  // pred: ^bb54
      %198 = llvm.load %194 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<4xi32>
      llvm.store %198, %195 {alignment = 16 : i64} : vector<4xi32>, !llvm.ptr
      %199 = arith.addi %196, %c1_i32 : i32
      cf.br ^bb54(%199 : i32)
    ^bb56:  // pred: ^bb54
      %200 = arith.subi %135, %144 : i32
      %201 = cute.memref.load(%rmem_84, %19) : (!memref_rmem_i32_, !cute.coord<"0">) -> i32
      %202 = cute.memref.load(%rmem_84, %17) : (!memref_rmem_i32_, !cute.coord<"1">) -> i32
      %203 = cute.memref.load(%rmem_84, %16) : (!memref_rmem_i32_, !cute.coord<"2">) -> i32
      %int_tuple_89 = cute.make_int_tuple(%201, %202, %203) : (i32, i32, i32) -> !cute.int_tuple<"(?,?,?)">
      %204:3 = cute.get_scalars(%int_tuple_89) <{only_dynamic}> : !cute.int_tuple<"(?,?,?)">
      %205 = arith.ceildivsi %204#0, %c128_i32 : i32
      %206 = arith.ceildivsi %204#1, %c128_i32 : i32
      %207 = arith.ceildivsi %204#2, %c64_i32 : i32
      %int_tuple_90 = cute.make_int_tuple(%205, %206, %207) : (i32, i32, i32) -> !cute.int_tuple<"(?,?,?)">
      %e0_91, %e1_92, %e2_93 = cute.get_leaves(%int_tuple_90) : !cute.int_tuple<"(?,?,?)">
      %208 = cute.get_scalars(%e2_93) : !cute.int_tuple<"?">
      %shape_94 = cute.make_shape(%e0_91, %e1_92) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.shape<"(?,?)">
      %lay_95 = cute.make_layout(%shape_94) : !cute.layout<"(?,?):(1,?)">
      %209 = cute.get_hier_coord(%200, %lay_95) : (i32, !cute.layout<"(?,?):(1,?)">) -> !cute.coord<"(?,?)">
      %e0_96, %e1_97 = cute.get_leaves(%209) : !cute.coord<"(?,?)">
      %itup_98 = cute.to_int_tuple(%e0_96) : !cute.coord<"?"> to !cute.int_tuple<"?">
      %itup_99 = cute.to_int_tuple(%e1_97) : !cute.coord<"?"> to !cute.int_tuple<"?">
      %mul_100 = cute.tuple_mul(%itup_98, %39) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %mul_101 = cute.tuple_mul(%itup_99, %39) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %210 = arith.cmpi ne, %143, %136 : i32
      cf.cond_br %210, ^bb57, ^bb70
    ^bb57:  // pred: ^bb56
      %coord_102 = cute.make_coord(%143) : (i32) -> !cute.coord<"(?,0)">
      %211 = cute.memref.load(%arg10, %coord_102) : (!memref_gmem_i64_, !cute.coord<"(?,0)">) -> i64
      %iv_103 = cute.assume(%211) : (i64) -> !cute.i64<divby 16>
      %212 = cute.inttoptr(%iv_103) : !cute.i64<divby 16> to !cute.ptr<f16, gmem, align<16>>
      %coord_104 = cute.make_coord(%143) : (i32) -> !cute.coord<"(?,0,_)">
      %idx_105 = cute.crd2idx(%coord_104, %15) : (!cute.coord<"(?,0,_)">, !cute.layout<"(2,3,2):(6,2,1)">) -> !cute.int_tuple<"?{div=6}">
      %iter_106 = cute.get_iter(%arg9) : !memref_gmem_i32_1
      %ptr_107 = cute.add_offset(%iter_106, %idx_105) : (!cute.ptr<i32, gmem, align<16>>, !cute.int_tuple<"?{div=6}">) -> !cute.ptr<i32, gmem, align<8>>
      %rmem_108 = cute.memref.alloca() : !memref_rmem_i32_1
      %iter_109 = cute.get_iter(%rmem_108) : !memref_rmem_i32_1
      %213 = builtin.unrealized_conversion_cast %ptr_107 : !cute.ptr<i32, gmem, align<8>> to !llvm.ptr<1>
      %214 = builtin.unrealized_conversion_cast %iter_109 : !cute.ptr<i32, rmem, align<32>> to !llvm.ptr
      cf.br ^bb58(%c0_i32 : i32)
    ^bb58(%215: i32):  // 2 preds: ^bb57, ^bb59
      %216 = arith.cmpi slt, %215, %115 : i32
      cf.cond_br %216, ^bb59, ^bb60 {llvm.loop_annotation = #loop_annotation}
    ^bb59:  // pred: ^bb58
      %217 = llvm.load %213 {alignment = 8 : i64} : !llvm.ptr<1> -> vector<2xi32>
      llvm.store %217, %214 {alignment = 8 : i64} : vector<2xi32>, !llvm.ptr
      %218 = arith.addi %215, %c1_i32 : i32
      cf.br ^bb58(%218 : i32)
    ^bb60:  // pred: ^bb58
      %219 = cute.memref.load(%rmem_108, %19) : (!memref_rmem_i32_1, !cute.coord<"0">) -> i32
      %220 = cute.memref.load(%rmem_108, %17) : (!memref_rmem_i32_1, !cute.coord<"1">) -> i32
      %shape_110 = cute.make_shape(%201, %203) : (i32, i32) -> !cute.shape<"(?,?,1)">
      %stride = cute.make_stride(%219, %220) : (i32, i32) -> !cute.stride<"(?,?,0)">
      %lay_111 = cute.make_layout(%shape_110, %stride) : !cute.layout<"(?,?,1):(?,?,0)">
      %view = cute.make_view(%212, %lay_111) : !memref_gmem_f16_
      %dyn_112 = cute.derefine(%view) : !memref_gmem_f16_ to !memref_gmem_f16_1
      %coord_113 = cute.make_coord(%143) : (i32) -> !cute.coord<"(?,1)">
      %221 = cute.memref.load(%arg10, %coord_113) : (!memref_gmem_i64_, !cute.coord<"(?,1)">) -> i64
      %iv_114 = cute.assume(%221) : (i64) -> !cute.i64<divby 16>
      %222 = cute.inttoptr(%iv_114) : !cute.i64<divby 16> to !cute.ptr<f16, gmem, align<16>>
      %coord_115 = cute.make_coord(%143) : (i32) -> !cute.coord<"(?,1,_)">
      %idx_116 = cute.crd2idx(%coord_115, %15) : (!cute.coord<"(?,1,_)">, !cute.layout<"(2,3,2):(6,2,1)">) -> !cute.int_tuple<"?{div=2}">
      %ptr_117 = cute.add_offset(%iter_106, %idx_116) : (!cute.ptr<i32, gmem, align<16>>, !cute.int_tuple<"?{div=2}">) -> !cute.ptr<i32, gmem, align<8>>
      %rmem_118 = cute.memref.alloca() : !memref_rmem_i32_1
      %iter_119 = cute.get_iter(%rmem_118) : !memref_rmem_i32_1
      %223 = builtin.unrealized_conversion_cast %ptr_117 : !cute.ptr<i32, gmem, align<8>> to !llvm.ptr<1>
      %224 = builtin.unrealized_conversion_cast %iter_119 : !cute.ptr<i32, rmem, align<32>> to !llvm.ptr
      cf.br ^bb61(%c0_i32 : i32)
    ^bb61(%225: i32):  // 2 preds: ^bb60, ^bb62
      %226 = arith.cmpi slt, %225, %115 : i32
      cf.cond_br %226, ^bb62, ^bb63 {llvm.loop_annotation = #loop_annotation}
    ^bb62:  // pred: ^bb61
      %227 = llvm.load %223 {alignment = 8 : i64} : !llvm.ptr<1> -> vector<2xi32>
      llvm.store %227, %224 {alignment = 8 : i64} : vector<2xi32>, !llvm.ptr
      %228 = arith.addi %225, %c1_i32 : i32
      cf.br ^bb61(%228 : i32)
    ^bb63:  // pred: ^bb61
      %229 = cute.memref.load(%rmem_118, %19) : (!memref_rmem_i32_1, !cute.coord<"0">) -> i32
      %230 = cute.memref.load(%rmem_118, %17) : (!memref_rmem_i32_1, !cute.coord<"1">) -> i32
      %shape_120 = cute.make_shape(%202, %203) : (i32, i32) -> !cute.shape<"(?,?,1)">
      %stride_121 = cute.make_stride(%229, %230) : (i32, i32) -> !cute.stride<"(?,?,0)">
      %lay_122 = cute.make_layout(%shape_120, %stride_121) : !cute.layout<"(?,?,1):(?,?,0)">
      %view_123 = cute.make_view(%222, %lay_122) : !memref_gmem_f16_
      %dyn_124 = cute.derefine(%view_123) : !memref_gmem_f16_ to !memref_gmem_f16_1
      %231 = arith.cmpi eq, %133, %false : i1
      %232 = arith.select %231, %true, %133 : i1
      cf.cond_br %231, ^bb64, ^bb65
    ^bb64:  // pred: ^bb63
      nvvm.barrier id = %c4_i32 number_of_threads = %c160_i32
      cf.br ^bb65
    ^bb65:  // 2 preds: ^bb63, ^bb64
      cf.cond_br %53, ^bb66, ^bb69
    ^bb66:  // pred: ^bb65
      cute_nvgpu.update_tma_desc(%arg1, %dyn_112, %iter_8) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>, !memref_gmem_f16_1, !cute.ptr<i64, smem, align<1024>>) -> ()
      cute_nvgpu.update_tma_desc(%arg3, %dyn_124, %ptr_9) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>, !memref_gmem_f16_1, !cute.ptr<i64, smem, align<128>>) -> ()
      %233 = nvvm.elect.sync -> i1
      cf.cond_br %233, ^bb67, ^bb68
    ^bb67:  // pred: ^bb66
      nvvm.cp.async.bulk.commit.group
      nvvm.cp.async.bulk.wait_group 0 {read}
      cf.br ^bb68
    ^bb68:  // 2 preds: ^bb66, ^bb67
      nvvm.bar.warp.sync %c-1_i32 : i32
      %234 = cute.ptrtoint(%99) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, gmem, align<128>> to i64
      %235 = cute.ptrtoint(%iter_8) : !cute.ptr<i64, smem, align<1024>> to i32
      llvm.inline_asm has_side_effects asm_dialect = att "tensormap.cp_fenceproxy.global.shared::cta.tensormap::generic.release.gpu.sync.aligned [$0], [$1], 128;", "l,r" %234, %235 : (i64, i32) -> ()
      %236 = cute.ptrtoint(%101) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, gmem, align<128>> to i64
      %237 = cute.ptrtoint(%ptr_9) : !cute.ptr<i64, smem, align<128>> to i32
      llvm.inline_asm has_side_effects asm_dialect = att "tensormap.cp_fenceproxy.global.shared::cta.tensormap::generic.release.gpu.sync.aligned [$0], [$1], 128;", "l,r" %236, %237 : (i64, i32) -> ()
      cf.br ^bb69
    ^bb69:  // 2 preds: ^bb65, ^bb68
      cf.br ^bb71(%232 : i1)
    ^bb70:  // pred: ^bb56
      cf.br ^bb71(%133 : i1)
    ^bb71(%238: i1):  // 2 preds: ^bb69, ^bb70
      cf.br ^bb72
    ^bb72:  // pred: ^bb71
      %div_125 = cute.tuple_div(%mul_100, %39) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_126 = cute.make_coord(%div_125) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,?,_,0)">
      %idx_127 = cute.crd2idx(%coord_126, %lay_49) : (!cute.coord<"(_,?,_,0)">, !cute.layout<"(((64,128),1),?,?,?):(((1@0,1@1),0),128@1,64@0,1@2)">) -> !cute.int_tuple<"(0,?{div=128},0)">
      %tup = cute.add_offset(%27, %idx_127) : (!cute.int_tuple<"(0,0,0)">, !cute.int_tuple<"(0,?{div=128},0)">) -> !cute.int_tuple<"(0,?{div=128},0)">
      %coord_128 = cute.make_coord(%mul_101) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,?,_,0)">
      %idx_129 = cute.crd2idx(%coord_128, %lay_53) : (!cute.coord<"(_,?,_,0)">, !cute.layout<"(((64,128),1),?,?,?):(((1@0,1@1),0),128@1,64@0,1@2)">) -> !cute.int_tuple<"(0,?{div=128},0)">
      %tup_130 = cute.add_offset(%27, %idx_129) : (!cute.int_tuple<"(0,0,0)">, !cute.int_tuple<"(0,?{div=128},0)">) -> !cute.int_tuple<"(0,?{div=128},0)">
      %int_tuple_131 = cute.make_int_tuple(%134) : (i32) -> !cute.int_tuple<"?">
      %tup_132 = cute.add_offset(%int_tuple_131, %e2_93) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.int_tuple<"?">
      %239 = cute.get_scalars(%tup_132) : !cute.int_tuple<"?">
      %240 = arith.remsi %134, %c6_i32 : i32
      %241 = arith.floordivsi %134, %c6_i32 : i32
      %242 = arith.remsi %241, %c2_i32 : i32
      %243 = arith.xori %242, %c1_i32 : i32
      %244 = arith.cmpi sgt, %208, %c0_i32 : i32
      %int_tuple_133 = cute.make_int_tuple(%240) : (i32) -> !cute.int_tuple<"?">
      %ptr_134 = cute.add_offset(%iter_13, %int_tuple_133) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      cf.cond_br %244, ^bb73, ^bb74
    ^bb73:  // pred: ^bb72
      %245 = builtin.unrealized_conversion_cast %ptr_134 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      %246 = nvvm.mbarrier.wait.parity %245, %243 {kind = #nvvm.mbar_wait<try>} : !llvm.ptr<3>, i32 -> i1
      cf.br ^bb75(%246 : i1)
    ^bb74:  // pred: ^bb72
      cf.br ^bb75(%true : i1)
    ^bb75(%247: i1):  // 2 preds: ^bb73, ^bb74
      cf.br ^bb76
    ^bb76:  // pred: ^bb75
      cf.cond_br %210, ^bb77, ^bb78
    ^bb77:  // pred: ^bb76
      %248 = cute.ptrtoint(%99) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, gmem, align<128>> to i64
      llvm.inline_asm has_side_effects asm_dialect = att "fence.proxy.tensormap::generic.acquire.gpu [$0], 128;", "l" %248 : (i64) -> ()
      %249 = cute.ptrtoint(%101) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, gmem, align<128>> to i64
      llvm.inline_asm has_side_effects asm_dialect = att "fence.proxy.tensormap::generic.acquire.gpu [$0], 128;", "l" %249 : (i64) -> ()
      cf.br ^bb78
    ^bb78:  // 2 preds: ^bb76, ^bb77
      cf.br ^bb79(%c0_i32, %247, %c0_i32, %240, %243 : i32, i1, i32, i32, i32)
    ^bb79(%250: i32, %251: i1, %252: i32, %253: i32, %254: i32):  // 2 preds: ^bb78, ^bb94
      %255 = arith.cmpi slt, %250, %208 : i32
      cf.cond_br %255, ^bb80, ^bb95 {loop_annotation = #loop_annotation1}
    ^bb80:  // pred: ^bb79
      %256 = arith.addi %252, %c1_i32 : i32
      %257 = arith.addi %134, %256 : i32
      %258 = arith.remsi %257, %c6_i32 : i32
      %259 = arith.cmpi eq, %258, %c0_i32 : i32
      %260 = arith.xori %254, %c1_i32 : i32
      %261 = arith.select %259, %260, %254 : i32
      %int_tuple_135 = cute.make_int_tuple(%253) : (i32) -> !cute.int_tuple<"?">
      %ptr_136 = cute.add_offset(%iter_12, %int_tuple_135) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %262 = arith.extui %251 : i1 to i32
      %263 = arith.cmpi eq, %262, %c0_i32 : i32
      cf.cond_br %263, ^bb81, ^bb82
    ^bb81:  // pred: ^bb80
      %ptr_137 = cute.add_offset(%iter_13, %int_tuple_135) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %264 = builtin.unrealized_conversion_cast %ptr_137 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %264, %254, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      cf.br ^bb82
    ^bb82:  // 2 preds: ^bb80, ^bb81
      %265 = nvvm.elect.sync -> i1
      cf.cond_br %265, ^bb83, ^bb84
    ^bb83:  // pred: ^bb82
      %266 = builtin.unrealized_conversion_cast %ptr_136 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %266, %c32768_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
      cf.br ^bb84
    ^bb84:  // 2 preds: ^bb82, ^bb83
      %coord_138 = cute.make_coord(%252) : (i32) -> !cute.coord<"(_,?)">
      %idx_139 = cute.crd2idx(%coord_138, %lay_74) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
      %tup_140 = cute.add_offset(%tup, %idx_139) : (!cute.int_tuple<"(0,?{div=128},0)">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.int_tuple<"(?{div=64},?{div=128},0)">
      %e0_141, %e1_142, %e2_143 = cute.get_leaves(%tup_140) : !cute.int_tuple<"(?{div=64},?{div=128},0)">
      %coord_144 = cute.make_coord(%253) : (i32) -> !cute.coord<"(_,?)">
      %idx_145 = cute.crd2idx(%coord_144, %13) : (!cute.coord<"(_,?)">, !cute.layout<"((8192,1),6):((1,0),8192)">) -> !cute.int_tuple<"?{div=8192}">
      %ptr_146 = cute.add_offset(%iter_23, %idx_145) : (!cute.ptr<f16, smem, align<1024>, S<3,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<f16, smem, align<1024>, S<3,4,3>>
      %int_tuple_147 = cute.make_int_tuple(%e0_141, %e1_142) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=128}">) -> !cute.int_tuple<"(?{div=64},?{div=128},0)">
      %267 = cute_nvgpu.atom.set_value(%120, %ptr_136 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>
      %268 = cute_nvgpu.atom.set_value(%267, %119 : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<128>>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_descriptor_ptr>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>
      %269 = cute_nvgpu.atom.get_value(%268 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
      %TMADescAddr = cute_nvgpu.get_tma_desc_addr(%268 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>) -> !cute.ptr<generic, align<64>>
      %270:3 = cute.get_scalars(%int_tuple_147) : !cute.int_tuple<"(?{div=64},?{div=128},0)">
      cf.br ^bb85(%c0_i32 : i32)
    ^bb85(%271: i32):  // 2 preds: ^bb84, ^bb86
      %272 = arith.cmpi slt, %271, %115 : i32
      cf.cond_br %272, ^bb86, ^bb87 {llvm.loop_annotation = #loop_annotation}
    ^bb86:  // pred: ^bb85
      cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr : !cute.ptr<generic, align<64>>, %ptr_146 : !cute.ptr<f16, smem, align<1024>, S<3,4,3>>, %269 : !cute.ptr<smem, align<8>>, [%270#0, %270#1, %270#2] : i32, i32, i32) mode = <tiled> num_cta = 1 : i32
      %273 = arith.addi %271, %c1_i32 : i32
      cf.br ^bb85(%273 : i32)
    ^bb87:  // pred: ^bb85
      %idx_148 = cute.crd2idx(%coord_138, %lay_76) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
      %tup_149 = cute.add_offset(%tup_130, %idx_148) : (!cute.int_tuple<"(0,?{div=128},0)">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.int_tuple<"(?{div=64},?{div=128},0)">
      %e0_150, %e1_151, %e2_152 = cute.get_leaves(%tup_149) : !cute.int_tuple<"(?{div=64},?{div=128},0)">
      %ptr_153 = cute.add_offset(%iter_24, %idx_145) : (!cute.ptr<f16, smem, align<1024>, S<3,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<f16, smem, align<1024>, S<3,4,3>>
      %int_tuple_154 = cute.make_int_tuple(%e0_150, %e1_151) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=128}">) -> !cute.int_tuple<"(?{div=64},?{div=128},0)">
      %274 = cute_nvgpu.atom.set_value(%123, %ptr_136 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>
      %275 = cute_nvgpu.atom.set_value(%274, %122 : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<128>>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_descriptor_ptr>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>
      %276 = cute_nvgpu.atom.get_value(%275 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
      %TMADescAddr_155 = cute_nvgpu.get_tma_desc_addr(%275 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>) -> !cute.ptr<generic, align<64>>
      %277:3 = cute.get_scalars(%int_tuple_154) : !cute.int_tuple<"(?{div=64},?{div=128},0)">
      cf.br ^bb88(%c0_i32 : i32)
    ^bb88(%278: i32):  // 2 preds: ^bb87, ^bb89
      %279 = arith.cmpi slt, %278, %115 : i32
      cf.cond_br %279, ^bb89, ^bb90 {llvm.loop_annotation = #loop_annotation}
    ^bb89:  // pred: ^bb88
      cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr_155 : !cute.ptr<generic, align<64>>, %ptr_153 : !cute.ptr<f16, smem, align<1024>, S<3,4,3>>, %276 : !cute.ptr<smem, align<8>>, [%277#0, %277#1, %277#2] : i32, i32, i32) mode = <tiled> num_cta = 1 : i32
      %280 = arith.addi %278, %c1_i32 : i32
      cf.br ^bb88(%280 : i32)
    ^bb90:  // pred: ^bb88
      %281 = arith.cmpi sgt, %208, %256 : i32
      %int_tuple_156 = cute.make_int_tuple(%258) : (i32) -> !cute.int_tuple<"?">
      %ptr_157 = cute.add_offset(%iter_13, %int_tuple_156) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      cf.cond_br %281, ^bb91, ^bb92
    ^bb91:  // pred: ^bb90
      %282 = builtin.unrealized_conversion_cast %ptr_157 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      %283 = nvvm.mbarrier.wait.parity %282, %261 {kind = #nvvm.mbar_wait<try>} : !llvm.ptr<3>, i32 -> i1
      cf.br ^bb93(%283 : i1)
    ^bb92:  // pred: ^bb90
      cf.br ^bb93(%true : i1)
    ^bb93(%284: i1):  // 2 preds: ^bb91, ^bb92
      cf.br ^bb94
    ^bb94:  // pred: ^bb93
      %285 = arith.addi %250, %c1_i32 : i32
      cf.br ^bb79(%285, %284, %256, %258, %261 : i32, i1, i32, i32, i32)
    ^bb95:  // pred: ^bb79
      %286 = arith.addi %139, %104 : i32
      %287 = arith.addi %140, %c1_i32 : i32
      %288 = arith.cmpi sgt, %105, %286 : i32
      %289 = cute.get_hier_coord(%286, %lay) : (i32, !cute.layout<"(1,1,?):(0,0,1)">) -> !cute.coord<"(0,0,?)">
      %e0_158, %e1_159, %e2_160 = cute.get_leaves(%289) : !cute.coord<"(0,0,?)">
      %itup_161 = cute.to_int_tuple(%e2_160) : !cute.coord<"?"> to !cute.int_tuple<"?">
      %mul_162 = cute.tuple_mul(%itup_161, %39) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %290 = cute.get_scalars(%mul_162) : !cute.int_tuple<"?">
      cf.br ^bb18(%238, %239, %290, %288, %143, %143, %144, %286, %287 : i1, i32, i32, i1, i32, i32, i32, i32, i32)
    ^bb96:  // pred: ^bb18
      cf.br ^bb97
    ^bb97:  // 2 preds: ^bb16, ^bb96
      cf.cond_br %64, ^bb98, ^bb168
    ^bb98:  // pred: ^bb97
      nvvm.barrier id = %c3_i32 number_of_threads = %c160_i32
      %tmem_ptr = cute_nvgpu.arch.sm100.retrieve_tmem_ptr(%iter) : !cute.ptr<i32, smem, align<8>> -> !cute.ptr<f32, tmem, align<16>>
      %int_tuple_163 = cute.make_int_tuple(%90, %91, %92) : (i32, i32, i32) -> !cute.int_tuple<"(?,?,?)">
      %sz_164 = cute.size(%int_tuple_163) : (!cute.int_tuple<"(?,?,?)">) -> !cute.int_tuple<"?">
      %e0_165 = cute.get_leaves(%sz_164) : !cute.int_tuple<"?">
      %div_166 = cute.tuple_div(%e0_165, %39) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %291 = cute.get_scalars(%div_166) : !cute.int_tuple<"?">
      %sz_167 = cute.size(%lay) : (!cute.layout<"(1,1,?):(0,0,1)">) -> !cute.int_tuple<"?">
      %e0_168 = cute.get_leaves(%sz_167) : !cute.int_tuple<"?">
      %292 = cute.get_scalars(%e0_168) : !cute.int_tuple<"?">
      %293 = arith.cmpi sgt, %292, %56 : i32
      %294 = cute.get_hier_coord(%56, %lay) : (i32, !cute.layout<"(1,1,?):(0,0,1)">) -> !cute.coord<"(0,0,?)">
      %e0_169, %e1_170, %e2_171 = cute.get_leaves(%294) : !cute.coord<"(0,0,?)">
      %itup_172 = cute.to_int_tuple(%e2_171) : !cute.coord<"?"> to !cute.int_tuple<"?">
      %mul_173 = cute.tuple_mul(%itup_172, %39) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %295 = cute.get_scalars(%mul_173) : !cute.int_tuple<"?">
      %296 = nvvm.read.ptx.sreg.laneid range <i32, 0, 32> : i32
      %297 = arith.cmpi sge, %296, %c1_i32 : i32
      %298 = arith.cmpi sge, %296, %c2_i32 : i32
      %299 = arith.cmpi sge, %296, %c4_i32 : i32
      %300 = arith.cmpi sge, %296, %c8_i32 : i32
      %301 = arith.cmpi sge, %296, %c16_i32 : i32
      %iter_174 = cute.get_iter(%arg8) : !memref_gmem_i32_
      %302 = cute.get_scalars(%39) : !cute.int_tuple<"1">
      cf.br ^bb99(%c0_i32, %295, %293, %c0_i32, %c0_i32, %0, %56, %c0_i32 : i32, i32, i1, i32, i32, !llvm.struct<(i1, i1, i1)>, i32, i32)
    ^bb99(%303: i32, %304: i32, %305: i1, %306: i32, %307: i32, %308: !llvm.struct<(i1, i1, i1)>, %309: i32, %310: i32):  // 2 preds: ^bb98, ^bb166
      cf.cond_br %305, ^bb100(%303, %304, %306, %307, %308, %309, %310 : i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>, i32, i32), ^bb167
    ^bb100(%311: i32, %312: i32, %313: i32, %314: i32, %315: !llvm.struct<(i1, i1, i1)>, %316: i32, %317: i32):  // pred: ^bb99
      %318 = builtin.unrealized_conversion_cast %315 : !llvm.struct<(i1, i1, i1)> to !mma_f16_f16_f32_128x128x16_
      %319 = arith.cmpi sge, %312, %314 : i32
      cf.br ^bb101(%319, %313, %314, %314 : i1, i32, i32, i32)
    ^bb101(%320: i1, %321: i32, %322: i32, %323: i32):  // 2 preds: ^bb100, ^bb133
      cf.cond_br %320, ^bb102(%321, %322, %323 : i32, i32, i32), ^bb134
    ^bb102(%324: i32, %325: i32, %326: i32):  // pred: ^bb101
      %327 = arith.addi %324, %296 : i32
      %328 = arith.cmpi slt, %327, %c2_i32 : i32
      cf.cond_br %328, ^bb103, ^bb107
    ^bb103:  // pred: ^bb102
      %rmem_175 = cute.memref.alloca() : !memref_rmem_i32_
      %coord_176 = cute.make_coord(%327) : (i32) -> !cute.coord<"(?,_)">
      %idx_177 = cute.crd2idx(%coord_176, %18) : (!cute.coord<"(?,_)">, !cute.layout<"(2,4):(4,1)">) -> !cute.int_tuple<"?{div=4}">
      %iter_178 = cute.get_iter(%arg8) : !memref_gmem_i32_
      %ptr_179 = cute.add_offset(%iter_178, %idx_177) : (!cute.ptr<i32, gmem, align<16>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<i32, gmem, align<16>>
      %iter_180 = cute.get_iter(%rmem_175) : !memref_rmem_i32_
      %329 = cute.get_scalars(%39) : !cute.int_tuple<"1">
      %330 = builtin.unrealized_conversion_cast %ptr_179 : !cute.ptr<i32, gmem, align<16>> to !llvm.ptr<1>
      %331 = builtin.unrealized_conversion_cast %iter_180 : !cute.ptr<i32, rmem, align<32>> to !llvm.ptr
      cf.br ^bb104(%c0_i32 : i32)
    ^bb104(%332: i32):  // 2 preds: ^bb103, ^bb105
      %333 = arith.cmpi slt, %332, %329 : i32
      cf.cond_br %333, ^bb105, ^bb106 {llvm.loop_annotation = #loop_annotation}
    ^bb105:  // pred: ^bb104
      %334 = llvm.load %330 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<4xi32>
      llvm.store %334, %331 {alignment = 16 : i64} : vector<4xi32>, !llvm.ptr
      %335 = arith.addi %332, %c1_i32 : i32
      cf.br ^bb104(%335 : i32)
    ^bb106:  // pred: ^bb104
      %336 = cute.memref.load(%rmem_175, %19) : (!memref_rmem_i32_, !cute.coord<"0">) -> i32
      %337 = arith.addi %336, %c127_i32 : i32
      %338 = arith.floordivsi %337, %c128_i32 : i32
      %339 = cute.memref.load(%rmem_175, %17) : (!memref_rmem_i32_, !cute.coord<"1">) -> i32
      %340 = arith.addi %339, %c127_i32 : i32
      %341 = arith.floordivsi %340, %c128_i32 : i32
      %342 = arith.muli %338, %341 : i32
      cf.br ^bb108(%342 : i32)
    ^bb107:  // pred: ^bb102
      cf.br ^bb108(%c0_i32 : i32)
    ^bb108(%343: i32):  // 2 preds: ^bb106, ^bb107
      cf.br ^bb109
    ^bb109:  // pred: ^bb108
      %344 = nvvm.shfl.sync  up %c-1_i32, %343, %c1_i32, %c0_i32 : i32 -> i32
      cf.cond_br %297, ^bb110, ^bb111
    ^bb110:  // pred: ^bb109
      %345 = arith.addi %343, %344 : i32
      cf.br ^bb112(%345 : i32)
    ^bb111:  // pred: ^bb109
      cf.br ^bb112(%343 : i32)
    ^bb112(%346: i32):  // 2 preds: ^bb110, ^bb111
      cf.br ^bb113
    ^bb113:  // pred: ^bb112
      %347 = nvvm.shfl.sync  up %c-1_i32, %346, %c2_i32, %c0_i32 : i32 -> i32
      cf.cond_br %298, ^bb114, ^bb115
    ^bb114:  // pred: ^bb113
      %348 = arith.addi %346, %347 : i32
      cf.br ^bb116(%348 : i32)
    ^bb115:  // pred: ^bb113
      cf.br ^bb116(%346 : i32)
    ^bb116(%349: i32):  // 2 preds: ^bb114, ^bb115
      cf.br ^bb117
    ^bb117:  // pred: ^bb116
      %350 = nvvm.shfl.sync  up %c-1_i32, %349, %c4_i32, %c0_i32 : i32 -> i32
      cf.cond_br %299, ^bb118, ^bb119
    ^bb118:  // pred: ^bb117
      %351 = arith.addi %349, %350 : i32
      cf.br ^bb120(%351 : i32)
    ^bb119:  // pred: ^bb117
      cf.br ^bb120(%349 : i32)
    ^bb120(%352: i32):  // 2 preds: ^bb118, ^bb119
      cf.br ^bb121
    ^bb121:  // pred: ^bb120
      %353 = nvvm.shfl.sync  up %c-1_i32, %352, %c8_i32, %c0_i32 : i32 -> i32
      cf.cond_br %300, ^bb122, ^bb123
    ^bb122:  // pred: ^bb121
      %354 = arith.addi %352, %353 : i32
      cf.br ^bb124(%354 : i32)
    ^bb123:  // pred: ^bb121
      cf.br ^bb124(%352 : i32)
    ^bb124(%355: i32):  // 2 preds: ^bb122, ^bb123
      cf.br ^bb125
    ^bb125:  // pred: ^bb124
      %356 = nvvm.shfl.sync  up %c-1_i32, %355, %c16_i32, %c0_i32 : i32 -> i32
      cf.cond_br %301, ^bb126, ^bb127
    ^bb126:  // pred: ^bb125
      %357 = arith.addi %355, %356 : i32
      cf.br ^bb128(%357 : i32)
    ^bb127:  // pred: ^bb125
      cf.br ^bb128(%355 : i32)
    ^bb128(%358: i32):  // 2 preds: ^bb126, ^bb127
      cf.br ^bb129
    ^bb129:  // pred: ^bb128
      %359 = arith.addi %358, %326 : i32
      %360 = arith.cmpi sge, %312, %359 : i32
      %361 = nvvm.vote.ballot.sync %c-1_i32, %360 : i32
      %362 = llvm.intr.ctpop(%361) : (i32) -> i32
      %363 = arith.cmpi eq, %362, %c32_i32 : i32
      %364 = arith.addi %362, %324 : i32
      %365 = arith.cmpi eq, %362, %c0_i32 : i32
      %366 = arith.cmpi eq, %365, %false : i1
      cf.cond_br %366, ^bb130, ^bb131
    ^bb130:  // pred: ^bb129
      %367 = arith.subi %362, %c1_i32 : i32
      %368 = nvvm.shfl.sync  idx %c-1_i32, %359, %367, %c31_i32 : i32 -> i32
      cf.br ^bb132(%368 : i32)
    ^bb131:  // pred: ^bb129
      cf.br ^bb132(%326 : i32)
    ^bb132(%369: i32):  // 2 preds: ^bb130, ^bb131
      cf.br ^bb133
    ^bb133:  // pred: ^bb132
      %370 = arith.select %363, %c31_i32, %362 : i32
      %371 = nvvm.shfl.sync  idx %c-1_i32, %359, %370, %c31_i32 : i32 -> i32
      cf.br ^bb101(%363, %364, %369, %371 : i1, i32, i32, i32)
    ^bb134:  // pred: ^bb101
      %rmem_181 = cute.memref.alloca() : !memref_rmem_i32_
      %coord_182 = cute.make_coord(%321) : (i32) -> !cute.coord<"(?,_)">
      %idx_183 = cute.crd2idx(%coord_182, %18) : (!cute.coord<"(?,_)">, !cute.layout<"(2,4):(4,1)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_184 = cute.add_offset(%iter_174, %idx_183) : (!cute.ptr<i32, gmem, align<16>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<i32, gmem, align<16>>
      %iter_185 = cute.get_iter(%rmem_181) : !memref_rmem_i32_
      %372 = builtin.unrealized_conversion_cast %ptr_184 : !cute.ptr<i32, gmem, align<16>> to !llvm.ptr<1>
      %373 = builtin.unrealized_conversion_cast %iter_185 : !cute.ptr<i32, rmem, align<32>> to !llvm.ptr
      cf.br ^bb135(%c0_i32 : i32)
    ^bb135(%374: i32):  // 2 preds: ^bb134, ^bb136
      %375 = arith.cmpi slt, %374, %302 : i32
      cf.cond_br %375, ^bb136, ^bb137 {llvm.loop_annotation = #loop_annotation}
    ^bb136:  // pred: ^bb135
      %376 = llvm.load %372 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<4xi32>
      llvm.store %376, %373 {alignment = 16 : i64} : vector<4xi32>, !llvm.ptr
      %377 = arith.addi %374, %c1_i32 : i32
      cf.br ^bb135(%377 : i32)
    ^bb137:  // pred: ^bb135
      %378 = cute.memref.load(%rmem_181, %16) : (!memref_rmem_i32_, !cute.coord<"2">) -> i32
      %379 = arith.addi %378, %c63_i32 : i32
      %380 = arith.floordivsi %379, %c64_i32 : i32
      %381 = arith.remsi %317, %c2_i32 : i32
      %coord_186 = cute.make_coord(%381) : (i32) -> !cute.coord<"(_,_,_,?)">
      %idx_187 = cute.crd2idx(%coord_186, %12) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((128,128),1,1,2):((65536,1),0,0,128)">) -> !cute.int_tuple<"?{div=128}">
      %ptr_188 = cute.add_offset(%tmem_ptr, %idx_187) : (!cute.ptr<f32, tmem, align<16>>, !cute.int_tuple<"?{div=128}">) -> !cute.ptr<f32, tmem, align<16>>
      %382 = arith.addi %311, %380 : i32
      %383 = arith.remsi %311, %c6_i32 : i32
      %384 = arith.cmpi sgt, %380, %c0_i32 : i32
      %385 = arith.extui %384 : i1 to i32
      %386 = arith.select %384, %c1_i32, %385 : i32
      %387 = arith.cmpi ne, %386, %c0_i32 : i32
      %388 = arith.floordivsi %311, %c6_i32 : i32
      %389 = arith.remsi %388, %c2_i32 : i32
      %int_tuple_189 = cute.make_int_tuple(%383) : (i32) -> !cute.int_tuple<"?">
      %ptr_190 = cute.add_offset(%iter_12, %int_tuple_189) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      cf.cond_br %387, ^bb138, ^bb139
    ^bb138:  // pred: ^bb137
      %390 = builtin.unrealized_conversion_cast %ptr_190 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      %391 = nvvm.mbarrier.wait.parity %390, %389 {kind = #nvvm.mbar_wait<try>} : !llvm.ptr<3>, i32 -> i1
      cf.br ^bb140(%391 : i1)
    ^bb139:  // pred: ^bb137
      cf.br ^bb140(%true : i1)
    ^bb140(%392: i1):  // 2 preds: ^bb138, ^bb139
      cf.br ^bb141
    ^bb141:  // pred: ^bb140
      %393 = arith.floordivsi %317, %c2_i32 : i32
      %394 = arith.remsi %393, %c2_i32 : i32
      %395 = arith.xori %394, %c1_i32 : i32
      %int_tuple_191 = cute.make_int_tuple(%381) : (i32) -> !cute.int_tuple<"?">
      %ptr_192 = cute.add_offset(%iter_15, %int_tuple_191) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %396 = builtin.unrealized_conversion_cast %ptr_192 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %396, %395, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %397 = cute_nvgpu.atom.set_value(%318, %false : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_f16_f16_f32_128x128x16_
      %398 = builtin.unrealized_conversion_cast %397 : !mma_f16_f16_f32_128x128x16_ to !llvm.struct<(i1, i1, i1)>
      %399 = arith.addi %311, %c1_i32 : i32
      %400 = arith.remsi %399, %c6_i32 : i32
      cf.br ^bb142(%c0_i32, %392, %383, %389, %398, %400 : i32, i1, i32, i32, !llvm.struct<(i1, i1, i1)>, i32)
    ^bb142(%401: i32, %402: i1, %403: i32, %404: i32, %405: !llvm.struct<(i1, i1, i1)>, %406: i32):  // 2 preds: ^bb141, ^bb163
      %407 = arith.cmpi slt, %401, %380 : i32
      cf.cond_br %407, ^bb143, ^bb164
    ^bb143:  // pred: ^bb142
      %408 = arith.addi %401, %c1_i32 : i32
      %409 = arith.cmpi eq, %406, %c0_i32 : i32
      %410 = arith.xori %404, %c1_i32 : i32
      %411 = arith.select %409, %410, %404 : i32
      %412 = arith.extui %402 : i1 to i32
      %413 = arith.cmpi eq, %412, %c0_i32 : i32
      cf.cond_br %413, ^bb144, ^bb145
    ^bb144:  // pred: ^bb143
      %int_tuple_193 = cute.make_int_tuple(%403) : (i32) -> !cute.int_tuple<"?">
      %ptr_194 = cute.add_offset(%iter_12, %int_tuple_193) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %414 = builtin.unrealized_conversion_cast %ptr_194 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %414, %404, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      cf.br ^bb145
    ^bb145:  // 2 preds: ^bb143, ^bb144
      cf.br ^bb146(%c0_i32, %405 : i32, !llvm.struct<(i1, i1, i1)>)
    ^bb146(%415: i32, %416: !llvm.struct<(i1, i1, i1)>):  // 2 preds: ^bb145, ^bb156
      %417 = arith.cmpi slt, %415, %c4_i32 : i32
      cf.cond_br %417, ^bb147, ^bb157 {loop_annotation = #loop_annotation2}
    ^bb147:  // pred: ^bb146
      %418 = builtin.unrealized_conversion_cast %416 : !llvm.struct<(i1, i1, i1)> to !mma_f16_f16_f32_128x128x16_
      %coord_195 = cute.make_coord(%415, %403) : (i32, i32) -> !cute.coord<"(_,_,?,?)">
      %idx_196 = cute.crd2idx(%coord_195, %11) : (!cute.coord<"(_,_,?,?)">, !cute.layout<"(1,1,4,6):(0,0,2,1024)">) -> !cute.int_tuple<"?{div=2}">
      %tup_197 = cute.add_offset(%ummaSmemDesc, %idx_196) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
      %tup_198 = cute.add_offset(%ummaSmemDesc_54, %idx_196) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
      %419 = cute_nvgpu.atom.get_value(%418 : !mma_f16_f16_f32_128x128x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : i1
      %420 = cute_nvgpu.atom.get_value(%418 : !mma_f16_f16_f32_128x128x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : i1
      %421 = cute_nvgpu.atom.get_value(%418 : !mma_f16_f16_f32_128x128x16_) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : i1
      %422 = arith.extui %419 : i1 to i32
      %423 = arith.extui %420 : i1 to i32
      %424 = arith.shli %422, %c13_i32 : i32
      %425 = arith.shli %423, %c14_i32 : i32
      %426 = arith.ori %424, %c136314896_i32 : i32
      %427 = arith.ori %426, %425 : i32
      cf.br ^bb148(%c0_i32 : i32)
    ^bb148(%428: i32):  // 2 preds: ^bb147, ^bb155
      %429 = arith.cmpi slt, %428, %302 : i32
      cf.cond_br %429, ^bb149, ^bb156 {llvm.loop_annotation = #loop_annotation}
    ^bb149:  // pred: ^bb148
      cf.br ^bb150(%c0_i32 : i32)
    ^bb150(%430: i32):  // 2 preds: ^bb149, ^bb154
      %431 = arith.cmpi slt, %430, %302 : i32
      cf.cond_br %431, ^bb151, ^bb155 {llvm.loop_annotation = #loop_annotation}
    ^bb151:  // pred: ^bb150
      cf.br ^bb152(%c0_i32 : i32)
    ^bb152(%432: i32):  // 2 preds: ^bb151, ^bb153
      %433 = arith.cmpi slt, %432, %302 : i32
      cf.cond_br %433, ^bb153, ^bb154 {llvm.loop_annotation = #loop_annotation}
    ^bb153:  // pred: ^bb152
      cute_nvgpu.arch.mma.SM100.umma(%tup_197, %tup_198, %ptr_188, %427, %421) {num_cta = 1 : i32, scale = 0 : i32, a_type = f16} : (!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, !cute.ptr<f32, tmem, align<16>>, i32, i1) -> ()
      %434 = arith.addi %432, %c1_i32 : i32
      cf.br ^bb152(%434 : i32)
    ^bb154:  // pred: ^bb152
      %435 = arith.addi %430, %c1_i32 : i32
      cf.br ^bb150(%435 : i32)
    ^bb155:  // pred: ^bb150
      %436 = arith.addi %428, %c1_i32 : i32
      cf.br ^bb148(%436 : i32)
    ^bb156:  // pred: ^bb148
      %437 = cute_nvgpu.atom.set_value(%418, %true : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_f16_f16_f32_128x128x16_
      %438 = builtin.unrealized_conversion_cast %437 : !mma_f16_f16_f32_128x128x16_ to !llvm.struct<(i1, i1, i1)>
      %439 = arith.addi %415, %c1_i32 : i32
      cf.br ^bb146(%439, %438 : i32, !llvm.struct<(i1, i1, i1)>)
    ^bb157:  // pred: ^bb146
      %440 = nvvm.elect.sync -> i1
      cf.cond_br %440, ^bb158, ^bb159
    ^bb158:  // pred: ^bb157
      %int_tuple_199 = cute.make_int_tuple(%403) : (i32) -> !cute.int_tuple<"?">
      %ptr_200 = cute.add_offset(%iter_13, %int_tuple_199) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %441 = builtin.unrealized_conversion_cast %ptr_200 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.tcgen05.commit.arrive %441 : !llvm.ptr<3>
      cf.br ^bb159
    ^bb159:  // 2 preds: ^bb157, ^bb158
      %442 = arith.cmpi slt, %408, %380 : i32
      %443 = arith.extui %442 : i1 to i32
      %444 = arith.select %442, %c1_i32, %443 : i32
      %445 = arith.cmpi ne, %444, %c0_i32 : i32
      %int_tuple_201 = cute.make_int_tuple(%406) : (i32) -> !cute.int_tuple<"?">
      %ptr_202 = cute.add_offset(%iter_12, %int_tuple_201) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      cf.cond_br %445, ^bb160, ^bb161
    ^bb160:  // pred: ^bb159
      %446 = builtin.unrealized_conversion_cast %ptr_202 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      %447 = nvvm.mbarrier.wait.parity %446, %411 {kind = #nvvm.mbar_wait<try>} : !llvm.ptr<3>, i32 -> i1
      cf.br ^bb162(%447 : i1)
    ^bb161:  // pred: ^bb159
      cf.br ^bb162(%true : i1)
    ^bb162(%448: i1):  // 2 preds: ^bb160, ^bb161
      cf.br ^bb163
    ^bb163:  // pred: ^bb162
      %449 = arith.addi %406, %c1_i32 : i32
      %450 = arith.cmpi eq, %449, %c6_i32 : i32
      %451 = arith.select %450, %c0_i32, %449 : i32
      %452 = arith.addi %401, %c1_i32 : i32
      cf.br ^bb142(%452, %448, %406, %411, %416, %451 : i32, i1, i32, i32, !llvm.struct<(i1, i1, i1)>, i32)
    ^bb164:  // pred: ^bb142
      %453 = nvvm.elect.sync -> i1
      cf.cond_br %453, ^bb165, ^bb166
    ^bb165:  // pred: ^bb164
      %ptr_203 = cute.add_offset(%iter_14, %int_tuple_191) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %454 = builtin.unrealized_conversion_cast %ptr_203 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.tcgen05.commit.arrive %454 : !llvm.ptr<3>
      cf.br ^bb166
    ^bb166:  // 2 preds: ^bb164, ^bb165
      %455 = arith.addi %316, %291 : i32
      %456 = arith.addi %317, %c1_i32 : i32
      %457 = arith.cmpi sgt, %292, %455 : i32
      %458 = cute.get_hier_coord(%455, %lay) : (i32, !cute.layout<"(1,1,?):(0,0,1)">) -> !cute.coord<"(0,0,?)">
      %e0_204, %e1_205, %e2_206 = cute.get_leaves(%458) : !cute.coord<"(0,0,?)">
      %itup_207 = cute.to_int_tuple(%e2_206) : !cute.coord<"?"> to !cute.int_tuple<"?">
      %mul_208 = cute.tuple_mul(%itup_207, %39) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %459 = cute.get_scalars(%mul_208) : !cute.int_tuple<"?">
      cf.br ^bb99(%382, %459, %457, %321, %322, %405, %455, %456 : i32, i32, i1, i32, i32, !llvm.struct<(i1, i1, i1)>, i32, i32)
    ^bb167:  // pred: ^bb99
      cf.br ^bb168
    ^bb168:  // 2 preds: ^bb97, ^bb167
      %460 = arith.cmpi slt, %52, %c4_i32 : i32
      cf.cond_br %460, ^bb169, ^bb259
    ^bb169:  // pred: ^bb168
      cf.cond_br %57, ^bb170, ^bb173
    ^bb170:  // pred: ^bb169
      %461 = nvvm.elect.sync -> i1
      cf.cond_br %461, ^bb171, ^bb172
    ^bb171:  // pred: ^bb170
      cute_nvgpu.copy_tma_desc(%arg1, %iter_8) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>, !cute.ptr<i64, smem, align<1024>>) -> ()
      cf.br ^bb172
    ^bb172:  // 2 preds: ^bb170, ^bb171
      cf.br ^bb173
    ^bb173:  // 2 preds: ^bb169, ^bb172
      nvvm.bar.warp.sync %c-1_i32 : i32
      cf.cond_br %57, ^bb174, ^bb177
    ^bb174:  // pred: ^bb173
      %462 = nvvm.elect.sync -> i1
      cf.cond_br %462, ^bb175, ^bb176
    ^bb175:  // pred: ^bb174
      cute_nvgpu.copy_tma_desc(%arg3, %ptr_9) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>, !cute.ptr<i64, smem, align<128>>) -> ()
      cf.br ^bb176
    ^bb176:  // 2 preds: ^bb174, ^bb175
      cf.br ^bb177
    ^bb177:  // 2 preds: ^bb173, ^bb176
      nvvm.bar.warp.sync %c-1_i32 : i32
      nvvm.barrier id = %c4_i32 number_of_threads = %c160_i32
      cf.cond_br %57, ^bb178, ^bb181
    ^bb178:  // pred: ^bb177
      %463 = nvvm.elect.sync -> i1
      cf.cond_br %463, ^bb179, ^bb180
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
      nvvm.barrier id = %c3_i32 number_of_threads = %c160_i32
      %tmem_ptr_209 = cute_nvgpu.arch.sm100.retrieve_tmem_ptr(%iter) : !cute.ptr<i32, smem, align<8>> -> !cute.ptr<f32, tmem, align<16>>
      %coord_210 = cute.make_coord(%41) : (i32) -> !cute.coord<"?">
      %464 = cute.get_scalars(%coord_210) <{only_dynamic}> : !cute.coord<"?">
      %465 = arith.divsi %464, %c32_i32 : i32
      %466 = arith.muli %465, %c2097152_i32 : i32
      %iv_211 = cute.assume(%466) : (i32) -> !cute.i32<divby 2097152>
      %int_tuple_212 = cute.make_int_tuple(%iv_211) : (!cute.i32<divby 2097152>) -> !cute.int_tuple<"?{div=2097152}">
      %ptr_213 = cute.add_offset(%tmem_ptr_209, %int_tuple_212) : (!cute.ptr<f32, tmem, align<16>>, !cute.int_tuple<"?{div=2097152}">) -> !cute.ptr<f32, tmem, align<16>>
      %rmem_214 = cute.memref.alloca() : !memref_rmem_f32_
      %iter_215 = cute.get_iter(%rmem_214) : !memref_rmem_f32_
      %rmem_216 = cute.memref.alloca() : !memref_rmem_f16_
      %atom = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<f16>
      %467 = cute.make_tiled_copy(%atom) : !copy_simt
      %468 = arith.remsi %464, %c32_i32 : i32
      %469 = arith.muli %468, %c32_i32 : i32
      %470 = arith.muli %465, %c1024_i32 : i32
      %471 = arith.addi %469, %470 : i32
      %iv_217 = cute.assume(%471) : (i32) -> !cute.i32<divby 32>
      %int_tuple_218 = cute.make_int_tuple(%iv_217) : (!cute.i32<divby 32>) -> !cute.int_tuple<"?{div=32}">
      %ptr_219 = cute.add_offset(%iter_22, %int_tuple_218) : (!cute.ptr<f16, smem, align<1024>, S<2,4,3>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f16, smem, align<64>, S<2,4,3>>
      %iter_220 = cute.get_iter(%rmem_216) : !memref_rmem_f16_
      %view_221 = cute.make_view(%iter_220) : !memref_rmem_f16_1
      %472:3 = cute.get_scalars(%lay_45) <{only_dynamic}> : !cute.layout<"((128,128),1,1,?,?,?):((1@1,1@0),0,0,128@1,128@0,1@2)">
      %shape_222 = cute.make_shape(%472#0, %472#1, %472#2) : (i32, i32, i32) -> !cute.shape<"(128,128,?,?,?)">
      %lay_223 = cute.make_layout(%shape_222, %25) : !cute.layout<"(128,128,?,?,?):(1@1,1@0,128@1,128@0,1@2)">
      %473:3 = cute.get_scalars(%lay_223) <{only_dynamic}> : !cute.layout<"(128,128,?,?,?):(1@1,1@0,128@1,128@0,1@2)">
      %shape_224 = cute.make_shape(%473#0, %473#1, %473#2) : (i32, i32, i32) -> !cute.shape<"(128,32,1,4,?,?,?)">
      %lay_225 = cute.make_layout(%shape_224, %10) : !cute.layout<"(128,32,1,4,?,?,?):(1@1,1@0,0,32@0,128@1,128@0,1@2)">
      %474:3 = cute.get_scalars(%lay_225) <{only_dynamic}> : !cute.layout<"(128,32,1,4,?,?,?):(1@1,1@0,0,32@0,128@1,128@0,1@2)">
      %shape_226 = cute.make_shape(%474#0, %474#1, %474#2) : (i32, i32, i32) -> !cute.shape<"((128,32),1,4,?,?,?)">
      %lay_227 = cute.make_layout(%shape_226, %9) : !cute.layout<"((128,32),1,4,?,?,?):((1@1,1@0),0,32@0,128@1,128@0,1@2)">
      %475:3 = cute.get_scalars(%lay_227) <{only_dynamic}> : !cute.layout<"((128,32),1,4,?,?,?):((1@1,1@0),0,32@0,128@1,128@0,1@2)">
      %shape_228 = cute.make_shape(%475#0, %475#1, %475#2) : (i32, i32, i32) -> !cute.shape<"(((32,128),1),1,4,?,?,?)">
      %lay_229 = cute.make_layout(%shape_228, %8) : !cute.layout<"(((32,128),1),1,4,?,?,?):(((1@0,1@1),0),0,32@0,128@1,128@0,1@2)">
      %int_tuple_230 = cute.make_int_tuple(%90, %91, %92) : (i32, i32, i32) -> !cute.int_tuple<"(?,?,?)">
      %sz_231 = cute.size(%int_tuple_230) : (!cute.int_tuple<"(?,?,?)">) -> !cute.int_tuple<"?">
      %e0_232 = cute.get_leaves(%sz_231) : !cute.int_tuple<"?">
      %div_233 = cute.tuple_div(%e0_232, %39) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %476 = cute.get_scalars(%div_233) : !cute.int_tuple<"?">
      %sz_234 = cute.size(%lay) : (!cute.layout<"(1,1,?):(0,0,1)">) -> !cute.int_tuple<"?">
      %e0_235 = cute.get_leaves(%sz_234) : !cute.int_tuple<"?">
      %477 = cute.get_scalars(%e0_235) : !cute.int_tuple<"?">
      %478 = arith.cmpi sgt, %477, %56 : i32
      %479 = cute.get_hier_coord(%56, %lay) : (i32, !cute.layout<"(1,1,?):(0,0,1)">) -> !cute.coord<"(0,0,?)">
      %e0_236, %e1_237, %e2_238 = cute.get_leaves(%479) : !cute.coord<"(0,0,?)">
      %itup_239 = cute.to_int_tuple(%e2_238) : !cute.coord<"?"> to !cute.int_tuple<"?">
      %mul_240 = cute.tuple_mul(%itup_239, %39) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %480 = cute.get_scalars(%mul_240) : !cute.int_tuple<"?">
      %481 = nvvm.read.ptx.sreg.laneid range <i32, 0, 32> : i32
      %482 = arith.cmpi sge, %481, %c1_i32 : i32
      %483 = arith.cmpi sge, %481, %c2_i32 : i32
      %484 = arith.cmpi sge, %481, %c4_i32 : i32
      %485 = arith.cmpi sge, %481, %c8_i32 : i32
      %486 = arith.cmpi sge, %481, %c16_i32 : i32
      %iter_241 = cute.get_iter(%arg8) : !memref_gmem_i32_
      %487 = cute.get_scalars(%39) : !cute.int_tuple<"1">
      %488 = builtin.unrealized_conversion_cast %iter_215 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
      %view_242 = cute.make_view(%iter_215) : !memref_rmem_f32_1
      %swizzled = cute.apply_swizzle(%ptr_219) : !cute.ptr<f16, smem, align<64>, S<2,4,3>>
      %489 = builtin.unrealized_conversion_cast %iter_220 : !cute.ptr<f16, rmem, align<32>> to !llvm.ptr
      %ptr_243 = cute.add_offset(%iter_220, %4) : (!cute.ptr<f16, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<f16, rmem, align<16>>
      %ptr_244 = cute.add_offset(%ptr_219, %4) : (!cute.ptr<f16, smem, align<64>, S<2,4,3>>, !cute.int_tuple<"8">) -> !cute.ptr<f16, smem, align<16>, S<2,4,3>>
      %swizzled_245 = cute.apply_swizzle(%ptr_244) : !cute.ptr<f16, smem, align<16>, S<2,4,3>>
      %490 = builtin.unrealized_conversion_cast %ptr_243 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
      %ptr_246 = cute.add_offset(%iter_220, %30) : (!cute.ptr<f16, rmem, align<32>>, !cute.int_tuple<"16">) -> !cute.ptr<f16, rmem, align<32>>
      %ptr_247 = cute.add_offset(%ptr_219, %30) : (!cute.ptr<f16, smem, align<64>, S<2,4,3>>, !cute.int_tuple<"16">) -> !cute.ptr<f16, smem, align<32>, S<2,4,3>>
      %swizzled_248 = cute.apply_swizzle(%ptr_247) : !cute.ptr<f16, smem, align<32>, S<2,4,3>>
      %491 = builtin.unrealized_conversion_cast %ptr_246 : !cute.ptr<f16, rmem, align<32>> to !llvm.ptr
      %ptr_249 = cute.add_offset(%iter_220, %3) : (!cute.ptr<f16, rmem, align<32>>, !cute.int_tuple<"24">) -> !cute.ptr<f16, rmem, align<16>>
      %ptr_250 = cute.add_offset(%ptr_219, %3) : (!cute.ptr<f16, smem, align<64>, S<2,4,3>>, !cute.int_tuple<"24">) -> !cute.ptr<f16, smem, align<16>, S<2,4,3>>
      %swizzled_251 = cute.apply_swizzle(%ptr_250) : !cute.ptr<f16, smem, align<16>, S<2,4,3>>
      %492 = builtin.unrealized_conversion_cast %ptr_249 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
      cf.br ^bb184(%c0_i32, %480, %478, %c-1_i32, %c0_i32, %c0_i32, %56, %c0_i32 : i32, i32, i1, i32, i32, i32, i32, i32)
    ^bb184(%493: i32, %494: i32, %495: i1, %496: i32, %497: i32, %498: i32, %499: i32, %500: i32):  // 2 preds: ^bb183, ^bb251
      cf.cond_br %495, ^bb185(%493, %494, %496, %497, %498, %499, %500 : i32, i32, i32, i32, i32, i32, i32), ^bb252
    ^bb185(%501: i32, %502: i32, %503: i32, %504: i32, %505: i32, %506: i32, %507: i32):  // pred: ^bb184
      %508 = arith.cmpi sge, %502, %505 : i32
      cf.br ^bb186(%508, %504, %505, %505 : i1, i32, i32, i32)
    ^bb186(%509: i1, %510: i32, %511: i32, %512: i32):  // 2 preds: ^bb185, ^bb218
      cf.cond_br %509, ^bb187(%510, %511, %512 : i32, i32, i32), ^bb219
    ^bb187(%513: i32, %514: i32, %515: i32):  // pred: ^bb186
      %516 = arith.addi %513, %481 : i32
      %517 = arith.cmpi slt, %516, %c2_i32 : i32
      cf.cond_br %517, ^bb188, ^bb192
    ^bb188:  // pred: ^bb187
      %rmem_252 = cute.memref.alloca() : !memref_rmem_i32_
      %coord_253 = cute.make_coord(%516) : (i32) -> !cute.coord<"(?,_)">
      %idx_254 = cute.crd2idx(%coord_253, %18) : (!cute.coord<"(?,_)">, !cute.layout<"(2,4):(4,1)">) -> !cute.int_tuple<"?{div=4}">
      %iter_255 = cute.get_iter(%arg8) : !memref_gmem_i32_
      %ptr_256 = cute.add_offset(%iter_255, %idx_254) : (!cute.ptr<i32, gmem, align<16>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<i32, gmem, align<16>>
      %iter_257 = cute.get_iter(%rmem_252) : !memref_rmem_i32_
      %518 = cute.get_scalars(%39) : !cute.int_tuple<"1">
      %519 = builtin.unrealized_conversion_cast %ptr_256 : !cute.ptr<i32, gmem, align<16>> to !llvm.ptr<1>
      %520 = builtin.unrealized_conversion_cast %iter_257 : !cute.ptr<i32, rmem, align<32>> to !llvm.ptr
      cf.br ^bb189(%c0_i32 : i32)
    ^bb189(%521: i32):  // 2 preds: ^bb188, ^bb190
      %522 = arith.cmpi slt, %521, %518 : i32
      cf.cond_br %522, ^bb190, ^bb191 {llvm.loop_annotation = #loop_annotation}
    ^bb190:  // pred: ^bb189
      %523 = llvm.load %519 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<4xi32>
      llvm.store %523, %520 {alignment = 16 : i64} : vector<4xi32>, !llvm.ptr
      %524 = arith.addi %521, %c1_i32 : i32
      cf.br ^bb189(%524 : i32)
    ^bb191:  // pred: ^bb189
      %525 = cute.memref.load(%rmem_252, %19) : (!memref_rmem_i32_, !cute.coord<"0">) -> i32
      %526 = arith.addi %525, %c127_i32 : i32
      %527 = arith.floordivsi %526, %c128_i32 : i32
      %528 = cute.memref.load(%rmem_252, %17) : (!memref_rmem_i32_, !cute.coord<"1">) -> i32
      %529 = arith.addi %528, %c127_i32 : i32
      %530 = arith.floordivsi %529, %c128_i32 : i32
      %531 = arith.muli %527, %530 : i32
      cf.br ^bb193(%531 : i32)
    ^bb192:  // pred: ^bb187
      cf.br ^bb193(%c0_i32 : i32)
    ^bb193(%532: i32):  // 2 preds: ^bb191, ^bb192
      cf.br ^bb194
    ^bb194:  // pred: ^bb193
      %533 = nvvm.shfl.sync  up %c-1_i32, %532, %c1_i32, %c0_i32 : i32 -> i32
      cf.cond_br %482, ^bb195, ^bb196
    ^bb195:  // pred: ^bb194
      %534 = arith.addi %532, %533 : i32
      cf.br ^bb197(%534 : i32)
    ^bb196:  // pred: ^bb194
      cf.br ^bb197(%532 : i32)
    ^bb197(%535: i32):  // 2 preds: ^bb195, ^bb196
      cf.br ^bb198
    ^bb198:  // pred: ^bb197
      %536 = nvvm.shfl.sync  up %c-1_i32, %535, %c2_i32, %c0_i32 : i32 -> i32
      cf.cond_br %483, ^bb199, ^bb200
    ^bb199:  // pred: ^bb198
      %537 = arith.addi %535, %536 : i32
      cf.br ^bb201(%537 : i32)
    ^bb200:  // pred: ^bb198
      cf.br ^bb201(%535 : i32)
    ^bb201(%538: i32):  // 2 preds: ^bb199, ^bb200
      cf.br ^bb202
    ^bb202:  // pred: ^bb201
      %539 = nvvm.shfl.sync  up %c-1_i32, %538, %c4_i32, %c0_i32 : i32 -> i32
      cf.cond_br %484, ^bb203, ^bb204
    ^bb203:  // pred: ^bb202
      %540 = arith.addi %538, %539 : i32
      cf.br ^bb205(%540 : i32)
    ^bb204:  // pred: ^bb202
      cf.br ^bb205(%538 : i32)
    ^bb205(%541: i32):  // 2 preds: ^bb203, ^bb204
      cf.br ^bb206
    ^bb206:  // pred: ^bb205
      %542 = nvvm.shfl.sync  up %c-1_i32, %541, %c8_i32, %c0_i32 : i32 -> i32
      cf.cond_br %485, ^bb207, ^bb208
    ^bb207:  // pred: ^bb206
      %543 = arith.addi %541, %542 : i32
      cf.br ^bb209(%543 : i32)
    ^bb208:  // pred: ^bb206
      cf.br ^bb209(%541 : i32)
    ^bb209(%544: i32):  // 2 preds: ^bb207, ^bb208
      cf.br ^bb210
    ^bb210:  // pred: ^bb209
      %545 = nvvm.shfl.sync  up %c-1_i32, %544, %c16_i32, %c0_i32 : i32 -> i32
      cf.cond_br %486, ^bb211, ^bb212
    ^bb211:  // pred: ^bb210
      %546 = arith.addi %544, %545 : i32
      cf.br ^bb213(%546 : i32)
    ^bb212:  // pred: ^bb210
      cf.br ^bb213(%544 : i32)
    ^bb213(%547: i32):  // 2 preds: ^bb211, ^bb212
      cf.br ^bb214
    ^bb214:  // pred: ^bb213
      %548 = arith.addi %547, %515 : i32
      %549 = arith.cmpi sge, %502, %548 : i32
      %550 = nvvm.vote.ballot.sync %c-1_i32, %549 : i32
      %551 = llvm.intr.ctpop(%550) : (i32) -> i32
      %552 = arith.cmpi eq, %551, %c32_i32 : i32
      %553 = arith.addi %551, %513 : i32
      %554 = arith.cmpi eq, %551, %c0_i32 : i32
      %555 = arith.cmpi eq, %554, %false : i1
      cf.cond_br %555, ^bb215, ^bb216
    ^bb215:  // pred: ^bb214
      %556 = arith.subi %551, %c1_i32 : i32
      %557 = nvvm.shfl.sync  idx %c-1_i32, %548, %556, %c31_i32 : i32 -> i32
      cf.br ^bb217(%557 : i32)
    ^bb216:  // pred: ^bb214
      cf.br ^bb217(%515 : i32)
    ^bb217(%558: i32):  // 2 preds: ^bb215, ^bb216
      cf.br ^bb218
    ^bb218:  // pred: ^bb217
      %559 = arith.select %552, %c31_i32, %551 : i32
      %560 = nvvm.shfl.sync  idx %c-1_i32, %548, %559, %c31_i32 : i32 -> i32
      cf.br ^bb186(%552, %553, %558, %560 : i1, i32, i32, i32)
    ^bb219:  // pred: ^bb186
      %rmem_258 = cute.memref.alloca() : !memref_rmem_i32_
      %coord_259 = cute.make_coord(%510) : (i32) -> !cute.coord<"(?,_)">
      %idx_260 = cute.crd2idx(%coord_259, %18) : (!cute.coord<"(?,_)">, !cute.layout<"(2,4):(4,1)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_261 = cute.add_offset(%iter_241, %idx_260) : (!cute.ptr<i32, gmem, align<16>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<i32, gmem, align<16>>
      %iter_262 = cute.get_iter(%rmem_258) : !memref_rmem_i32_
      %561 = builtin.unrealized_conversion_cast %ptr_261 : !cute.ptr<i32, gmem, align<16>> to !llvm.ptr<1>
      %562 = builtin.unrealized_conversion_cast %iter_262 : !cute.ptr<i32, rmem, align<32>> to !llvm.ptr
      cf.br ^bb220(%c0_i32 : i32)
    ^bb220(%563: i32):  // 2 preds: ^bb219, ^bb221
      %564 = arith.cmpi slt, %563, %487 : i32
      cf.cond_br %564, ^bb221, ^bb222 {llvm.loop_annotation = #loop_annotation}
    ^bb221:  // pred: ^bb220
      %565 = llvm.load %561 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<4xi32>
      llvm.store %565, %562 {alignment = 16 : i64} : vector<4xi32>, !llvm.ptr
      %566 = arith.addi %563, %c1_i32 : i32
      cf.br ^bb220(%566 : i32)
    ^bb222:  // pred: ^bb220
      %567 = arith.subi %502, %511 : i32
      %568 = cute.memref.load(%rmem_258, %19) : (!memref_rmem_i32_, !cute.coord<"0">) -> i32
      %569 = cute.memref.load(%rmem_258, %17) : (!memref_rmem_i32_, !cute.coord<"1">) -> i32
      %570 = cute.memref.load(%rmem_258, %16) : (!memref_rmem_i32_, !cute.coord<"2">) -> i32
      %int_tuple_263 = cute.make_int_tuple(%568, %569, %570) : (i32, i32, i32) -> !cute.int_tuple<"(?,?,?)">
      %571:3 = cute.get_scalars(%int_tuple_263) <{only_dynamic}> : !cute.int_tuple<"(?,?,?)">
      %572 = arith.ceildivsi %571#0, %c128_i32 : i32
      %573 = arith.ceildivsi %571#1, %c128_i32 : i32
      %574 = arith.ceildivsi %571#2, %c64_i32 : i32
      %int_tuple_264 = cute.make_int_tuple(%572, %573, %574) : (i32, i32, i32) -> !cute.int_tuple<"(?,?,?)">
      %e0_265, %e1_266, %e2_267 = cute.get_leaves(%int_tuple_264) : !cute.int_tuple<"(?,?,?)">
      %shape_268 = cute.make_shape(%e0_265, %e1_266) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.shape<"(?,?)">
      %lay_269 = cute.make_layout(%shape_268) : !cute.layout<"(?,?):(1,?)">
      %575 = cute.get_hier_coord(%567, %lay_269) : (i32, !cute.layout<"(?,?):(1,?)">) -> !cute.coord<"(?,?)">
      %e0_270, %e1_271 = cute.get_leaves(%575) : !cute.coord<"(?,?)">
      %itup_272 = cute.to_int_tuple(%e0_270) : !cute.coord<"?"> to !cute.int_tuple<"?">
      %itup_273 = cute.to_int_tuple(%e1_271) : !cute.coord<"?"> to !cute.int_tuple<"?">
      %mul_274 = cute.tuple_mul(%itup_272, %39) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %mul_275 = cute.tuple_mul(%itup_273, %39) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %576 = arith.cmpi ne, %510, %503 : i32
      cf.cond_br %576, ^bb223, ^bb231
    ^bb223:  // pred: ^bb222
      %coord_276 = cute.make_coord(%510) : (i32) -> !cute.coord<"(?,2)">
      %577 = cute.memref.load(%arg10, %coord_276) : (!memref_gmem_i64_, !cute.coord<"(?,2)">) -> i64
      %iv_277 = cute.assume(%577) : (i64) -> !cute.i64<divby 16>
      %578 = cute.inttoptr(%iv_277) : !cute.i64<divby 16> to !cute.ptr<f16, gmem, align<16>>
      %coord_278 = cute.make_coord(%510) : (i32) -> !cute.coord<"(?,2,_)">
      %idx_279 = cute.crd2idx(%coord_278, %15) : (!cute.coord<"(?,2,_)">, !cute.layout<"(2,3,2):(6,2,1)">) -> !cute.int_tuple<"?{div=2}">
      %iter_280 = cute.get_iter(%arg9) : !memref_gmem_i32_1
      %ptr_281 = cute.add_offset(%iter_280, %idx_279) : (!cute.ptr<i32, gmem, align<16>>, !cute.int_tuple<"?{div=2}">) -> !cute.ptr<i32, gmem, align<8>>
      %rmem_282 = cute.memref.alloca() : !memref_rmem_i32_1
      %iter_283 = cute.get_iter(%rmem_282) : !memref_rmem_i32_1
      %579 = builtin.unrealized_conversion_cast %ptr_281 : !cute.ptr<i32, gmem, align<8>> to !llvm.ptr<1>
      %580 = builtin.unrealized_conversion_cast %iter_283 : !cute.ptr<i32, rmem, align<32>> to !llvm.ptr
      cf.br ^bb224(%c0_i32 : i32)
    ^bb224(%581: i32):  // 2 preds: ^bb223, ^bb225
      %582 = arith.cmpi slt, %581, %487 : i32
      cf.cond_br %582, ^bb225, ^bb226 {llvm.loop_annotation = #loop_annotation}
    ^bb225:  // pred: ^bb224
      %583 = llvm.load %579 {alignment = 8 : i64} : !llvm.ptr<1> -> vector<2xi32>
      llvm.store %583, %580 {alignment = 8 : i64} : vector<2xi32>, !llvm.ptr
      %584 = arith.addi %581, %c1_i32 : i32
      cf.br ^bb224(%584 : i32)
    ^bb226:  // pred: ^bb224
      %585 = cute.memref.load(%rmem_282, %19) : (!memref_rmem_i32_1, !cute.coord<"0">) -> i32
      %586 = cute.memref.load(%rmem_282, %17) : (!memref_rmem_i32_1, !cute.coord<"1">) -> i32
      %shape_284 = cute.make_shape(%568, %569) : (i32, i32) -> !cute.shape<"(?,?,1)">
      %stride_285 = cute.make_stride(%585, %586) : (i32, i32) -> !cute.stride<"(?,?,0)">
      %lay_286 = cute.make_layout(%shape_284, %stride_285) : !cute.layout<"(?,?,1):(?,?,0)">
      %view_287 = cute.make_view(%578, %lay_286) : !memref_gmem_f16_
      %dyn_288 = cute.derefine(%view_287) : !memref_gmem_f16_ to !memref_gmem_f16_1
      cf.cond_br %57, ^bb227, ^bb230
    ^bb227:  // pred: ^bb226
      cute_nvgpu.update_tma_desc(%arg5, %dyn_288, %dyn) : (!cute_nvgpu.atom.non_exec_tiled_tma_store<f16, copy_bits = 65536, tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>, !memref_gmem_f16_1, !cute.ptr<i64, smem, align<128>>) -> ()
      %587 = nvvm.elect.sync -> i1
      cf.cond_br %587, ^bb228, ^bb229
    ^bb228:  // pred: ^bb227
      nvvm.cp.async.bulk.commit.group
      nvvm.cp.async.bulk.wait_group 0 {read}
      cf.br ^bb229
    ^bb229:  // 2 preds: ^bb227, ^bb228
      nvvm.bar.warp.sync %c-1_i32 : i32
      %588 = cute.ptrtoint(%103) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, gmem, align<128>> to i64
      %589 = cute.ptrtoint(%dyn) : !cute.ptr<i64, smem, align<128>> to i32
      llvm.inline_asm has_side_effects asm_dialect = att "tensormap.cp_fenceproxy.global.shared::cta.tensormap::generic.release.gpu.sync.aligned [$0], [$1], 128;", "l,r" %588, %589 : (i64, i32) -> ()
      cf.br ^bb230
    ^bb230:  // 2 preds: ^bb226, ^bb229
      cf.br ^bb231
    ^bb231:  // 2 preds: ^bb222, ^bb230
      %div_289 = cute.tuple_div(%mul_274, %39) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %int_tuple_290 = cute.make_int_tuple(%501) : (i32) -> !cute.int_tuple<"?">
      %tup_291 = cute.add_offset(%int_tuple_290, %e2_267) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.int_tuple<"?">
      %590 = cute.get_scalars(%tup_291) : !cute.int_tuple<"?">
      %coord_292 = cute.make_coord(%div_289, %mul_275) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(_,_,_,?,?,0)">
      %idx_293 = cute.crd2idx(%coord_292, %lay_229) : (!cute.coord<"(_,_,_,?,?,0)">, !cute.layout<"(((32,128),1),1,4,?,?,?):(((1@0,1@1),0),0,32@0,128@1,128@0,1@2)">) -> !cute.int_tuple<"(?{div=128},?{div=128},0)">
      %tup_294 = cute.add_offset(%27, %idx_293) : (!cute.int_tuple<"(0,0,0)">, !cute.int_tuple<"(?{div=128},?{div=128},0)">) -> !cute.int_tuple<"(?{div=128},?{div=128},0)">
      %591 = arith.remsi %507, %c2_i32 : i32
      %coord_295 = cute.make_coord(%591) : (i32) -> !cute.coord<"(_,_,_,_,_,?)">
      %idx_296 = cute.crd2idx(%coord_295, %7) : (!cute.coord<"(_,_,_,_,_,?)">, !cute.layout<"(((32,32),1),1,1,1,4,2):(((1,65536),0),0,0,0,32,128)">) -> !cute.int_tuple<"?{div=128}">
      %ptr_297 = cute.add_offset(%ptr_213, %idx_296) : (!cute.ptr<f32, tmem, align<16>>, !cute.int_tuple<"?{div=128}">) -> !cute.ptr<f32, tmem, align<16>>
      %592 = arith.floordivsi %507, %c2_i32 : i32
      %593 = arith.remsi %592, %c2_i32 : i32
      %int_tuple_298 = cute.make_int_tuple(%591) : (i32) -> !cute.int_tuple<"?">
      %ptr_299 = cute.add_offset(%iter_14, %int_tuple_298) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %594 = builtin.unrealized_conversion_cast %ptr_299 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %594, %593, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      cf.cond_br %576, ^bb232, ^bb235
    ^bb232:  // pred: ^bb231
      cf.cond_br %57, ^bb233, ^bb234
    ^bb233:  // pred: ^bb232
      %595 = cute.ptrtoint(%103) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, gmem, align<128>> to i64
      llvm.inline_asm has_side_effects asm_dialect = att "fence.proxy.tensormap::generic.acquire.gpu [$0], 128;", "l" %595 : (i64) -> ()
      cf.br ^bb234
    ^bb234:  // 2 preds: ^bb232, ^bb233
      cf.br ^bb235
    ^bb235:  // 2 preds: ^bb231, ^bb234
      %596 = arith.muli %507, %c4_i32 : i32
      %597 = arith.remsi %596, %c4_i32 : i32
      cf.br ^bb236(%c0_i32, %597 : i32, i32)
    ^bb236(%598: i32, %599: i32):  // 2 preds: ^bb235, ^bb248
      %600 = arith.cmpi slt, %598, %c4_i32 : i32
      cf.cond_br %600, ^bb237, ^bb249
    ^bb237:  // pred: ^bb236
      %coord_300 = cute.make_coord(%598) : (i32) -> !cute.coord<"(_,_,_,?)">
      %idx_301 = cute.crd2idx(%coord_300, %6) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"(((32,32),1),1,1,(1,4)):(((1,65536),0),0,0,(0,32))">) -> !cute.int_tuple<"?{div=32}">
      %ptr_302 = cute.add_offset(%ptr_297, %idx_301) : (!cute.ptr<f32, tmem, align<16>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f32, tmem, align<16>>
      cf.br ^bb238(%c0_i32 : i32)
    ^bb238(%601: i32):  // 2 preds: ^bb237, ^bb239
      %602 = arith.cmpi slt, %601, %487 : i32
      cf.cond_br %602, ^bb239, ^bb240 {llvm.loop_annotation = #loop_annotation}
    ^bb239:  // pred: ^bb238
      %603 = "cute_nvgpu.arch.copy.SM100.tmem_load"(%ptr_302) <{num_b = 32 : i32, num_dp = 32 : i32, num_rep = 32 : i32}> : (!cute.ptr<f32, tmem, align<16>>) -> vector<32xi32>
      llvm.store %603, %488 : vector<32xi32>, !llvm.ptr
      %604 = arith.addi %601, %c1_i32 : i32
      cf.br ^bb238(%604 : i32)
    ^bb240:  // pred: ^bb238
      %605 = cute.memref.load_vec %view_242, row_major : !memref_rmem_f32_1
      %606 = arith.truncf %605 : vector<32xf32> to vector<32xf16>
      cute.memref.store_vec %606, %view_221, row_major : !memref_rmem_f16_1
      %coord_303 = cute.make_coord(%599) : (i32) -> !cute.coord<"(_,_,_,?)">
      %idx_304 = cute.crd2idx(%coord_303, %5) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((1,32),1,1,(1,4)):((0,1),0,0,(0,4096))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_305 = cute.add_offset(%swizzled, %idx_304) : (!cute.ptr<f16, smem, align<64>, S<2,4,3>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, smem, align<64>, S<2,4,3>>
      %607 = builtin.unrealized_conversion_cast %ptr_305 : !cute.ptr<f16, smem, align<64>, S<2,4,3>> to !llvm.ptr<3>
      %ptr_306 = cute.add_offset(%swizzled_245, %idx_304) : (!cute.ptr<f16, smem, align<16>, S<2,4,3>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, smem, align<16>, S<2,4,3>>
      %608 = builtin.unrealized_conversion_cast %ptr_306 : !cute.ptr<f16, smem, align<16>, S<2,4,3>> to !llvm.ptr<3>
      %ptr_307 = cute.add_offset(%swizzled_248, %idx_304) : (!cute.ptr<f16, smem, align<32>, S<2,4,3>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, smem, align<32>, S<2,4,3>>
      %609 = builtin.unrealized_conversion_cast %ptr_307 : !cute.ptr<f16, smem, align<32>, S<2,4,3>> to !llvm.ptr<3>
      %ptr_308 = cute.add_offset(%swizzled_251, %idx_304) : (!cute.ptr<f16, smem, align<16>, S<2,4,3>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, smem, align<16>, S<2,4,3>>
      %610 = builtin.unrealized_conversion_cast %ptr_308 : !cute.ptr<f16, smem, align<16>, S<2,4,3>> to !llvm.ptr<3>
      cf.br ^bb241(%c0_i32 : i32)
    ^bb241(%611: i32):  // 2 preds: ^bb240, ^bb242
      %612 = arith.cmpi slt, %611, %487 : i32
      cf.cond_br %612, ^bb242, ^bb243 {llvm.loop_annotation = #loop_annotation}
    ^bb242:  // pred: ^bb241
      %613 = llvm.load %489 {alignment = 16 : i64} : !llvm.ptr -> vector<8xf16>
      llvm.store %613, %607 {alignment = 16 : i64} : vector<8xf16>, !llvm.ptr<3>
      %614 = llvm.load %490 {alignment = 16 : i64} : !llvm.ptr -> vector<8xf16>
      llvm.store %614, %608 {alignment = 16 : i64} : vector<8xf16>, !llvm.ptr<3>
      %615 = llvm.load %491 {alignment = 16 : i64} : !llvm.ptr -> vector<8xf16>
      llvm.store %615, %609 {alignment = 16 : i64} : vector<8xf16>, !llvm.ptr<3>
      %616 = llvm.load %492 {alignment = 16 : i64} : !llvm.ptr -> vector<8xf16>
      llvm.store %616, %610 {alignment = 16 : i64} : vector<8xf16>, !llvm.ptr<3>
      %617 = arith.addi %611, %c1_i32 : i32
      cf.br ^bb241(%617 : i32)
    ^bb243:  // pred: ^bb241
      nvvm.fence.proxy {kind = #nvvm.proxy_kind<async.shared>, space = #nvvm.shared_space<cta>}
      nvvm.barrier id = %c2_i32 number_of_threads = %c128_i32
      cf.cond_br %57, ^bb244, ^bb248
    ^bb244:  // pred: ^bb243
      %coord_309 = cute.make_coord(%599) : (i32) -> !cute.coord<"(_,?)">
      %idx_310 = cute.crd2idx(%coord_309, %2) : (!cute.coord<"(_,?)">, !cute.layout<"((4096,1),(1,4)):((1,0),(0,4096))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_311 = cute.add_offset(%iter_22, %idx_310) : (!cute.ptr<f16, smem, align<1024>, S<2,4,3>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, smem, align<1024>, S<2,4,3>>
      %coord_312 = cute.make_coord(%598) : (i32) -> !cute.coord<"(_,?)">
      %idx_313 = cute.crd2idx(%coord_312, %1) : (!cute.coord<"(_,?)">, !cute.layout<"(((32,128),1),(1,4)):(((1@0,1@1),0),(0,32@0))">) -> !cute.int_tuple<"(?{div=32},0)">
      %tup_314 = cute.add_offset(%tup_294, %idx_313) : (!cute.int_tuple<"(?{div=128},?{div=128},0)">, !cute.int_tuple<"(?{div=32},0)">) -> !cute.int_tuple<"(?{div=32},?{div=128},0)">
      %e0_315, %e1_316, %e2_317 = cute.get_leaves(%tup_314) : !cute.int_tuple<"(?{div=32},?{div=128},0)">
      %618 = cute.ptrtoint(%103) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, gmem, align<128>> to i64
      %iv_318 = cute.assume(%618) : (i64) -> !cute.i64<divby 128>
      %619 = cute.inttoptr(%iv_318) : !cute.i64<divby 128> to !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<128>>
      %int_tuple_319 = cute.make_int_tuple(%e0_315, %e1_316) : (!cute.int_tuple<"?{div=32}">, !cute.int_tuple<"?{div=128}">) -> !cute.int_tuple<"(?{div=32},?{div=128},0)">
      %620 = cute_nvgpu.atom.make_exec_tma(%arg5) : (!cute_nvgpu.atom.non_exec_tiled_tma_store<f16, copy_bits = 65536, tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_store<f16, copy_bits = 65536, mode = tiled, g_stride = <"()"> tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">>
      %621 = cute_nvgpu.atom.set_value(%620, %619 : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<128>>) {field = #cute_nvgpu.atom_copy_field_tmastore<tma_descriptor_ptr>} : !cute_nvgpu.atom.tma_store<f16, copy_bits = 65536, mode = tiled, g_stride = <"()"> tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">>
      %TMADescAddr_320 = cute_nvgpu.get_tma_desc_addr(%621 : !cute_nvgpu.atom.tma_store<f16, copy_bits = 65536, mode = tiled, g_stride = <"()"> tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">>) -> !cute.ptr<generic, align<64>>
      %622:3 = cute.get_scalars(%int_tuple_319) : !cute.int_tuple<"(?{div=32},?{div=128},0)">
      cf.br ^bb245(%c0_i32 : i32)
    ^bb245(%623: i32):  // 2 preds: ^bb244, ^bb246
      %624 = arith.cmpi slt, %623, %487 : i32
      cf.cond_br %624, ^bb246, ^bb247 {llvm.loop_annotation = #loop_annotation}
    ^bb246:  // pred: ^bb245
      cute_nvgpu.arch.copy.SM100.tma_store(%TMADescAddr_320 : !cute.ptr<generic, align<64>>, %ptr_311 : !cute.ptr<f16, smem, align<1024>, S<2,4,3>>, [%622#0, %622#1, %622#2] : i32, i32, i32) mode = <tiled>
      %625 = arith.addi %623, %c1_i32 : i32
      cf.br ^bb245(%625 : i32)
    ^bb247:  // pred: ^bb245
      nvvm.cp.async.bulk.commit.group
      nvvm.cp.async.bulk.wait_group 3 {read}
      cf.br ^bb248
    ^bb248:  // 2 preds: ^bb243, ^bb247
      nvvm.barrier id = %c2_i32 number_of_threads = %c128_i32
      %626 = arith.addi %599, %c1_i32 : i32
      %627 = arith.cmpi eq, %626, %c4_i32 : i32
      %628 = arith.select %627, %c0_i32, %626 : i32
      %629 = arith.addi %598, %c1_i32 : i32
      cf.br ^bb236(%629, %628 : i32, i32)
    ^bb249:  // pred: ^bb236
      %630 = nvvm.elect.sync -> i1
      cf.cond_br %630, ^bb250, ^bb251
    ^bb250:  // pred: ^bb249
      %ptr_321 = cute.add_offset(%iter_15, %int_tuple_298) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %631 = builtin.unrealized_conversion_cast %ptr_321 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %631, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>} : !llvm.ptr<3>, i32
      cf.br ^bb251
    ^bb251:  // 2 preds: ^bb249, ^bb250
      %632 = arith.addi %506, %476 : i32
      %633 = arith.addi %507, %c1_i32 : i32
      %634 = arith.cmpi sgt, %477, %632 : i32
      %635 = cute.get_hier_coord(%632, %lay) : (i32, !cute.layout<"(1,1,?):(0,0,1)">) -> !cute.coord<"(0,0,?)">
      %e0_322, %e1_323, %e2_324 = cute.get_leaves(%635) : !cute.coord<"(0,0,?)">
      %itup_325 = cute.to_int_tuple(%e2_324) : !cute.coord<"?"> to !cute.int_tuple<"?">
      %mul_326 = cute.tuple_mul(%itup_325, %39) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %636 = cute.get_scalars(%mul_326) : !cute.int_tuple<"?">
      cf.br ^bb184(%590, %636, %634, %510, %510, %511, %632, %633 : i32, i32, i1, i32, i32, i32, i32, i32)
    ^bb252:  // pred: ^bb184
      cf.cond_br %57, ^bb253, ^bb254
    ^bb253:  // pred: ^bb252
      cute_nvgpu.arch.sm100.relinquish_tmem_alloc_permit [ cta_1]
      cf.br ^bb254
    ^bb254:  // 2 preds: ^bb252, ^bb253
      nvvm.barrier id = %c2_i32 number_of_threads = %c128_i32
      cf.cond_br %57, ^bb255, ^bb256
    ^bb255:  // pred: ^bb254
      cute_nvgpu.arch.sm100.dealloc_tmem(%tmem_ptr_209, %c256_i32) [ cta_1] : !cute.ptr<f32, tmem, align<16>>, i32
      cf.br ^bb256
    ^bb256:  // 2 preds: ^bb254, ^bb255
      cf.cond_br %57, ^bb257, ^bb258
    ^bb257:  // pred: ^bb256
      %637 = arith.subi %493, %c1_i32 : i32
      %638 = arith.remsi %637, %c6_i32 : i32
      %int_tuple_327 = cute.make_int_tuple(%638) : (i32) -> !cute.int_tuple<"?">
      %ptr_328 = cute.add_offset(%iter_13, %int_tuple_327) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %639 = arith.floordivsi %637, %c6_i32 : i32
      %640 = arith.remsi %639, %c2_i32 : i32
      %641 = builtin.unrealized_conversion_cast %ptr_328 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %641, %640, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      cf.br ^bb258
    ^bb258:  // 2 preds: ^bb256, ^bb257
      cf.br ^bb259
    ^bb259:  // 2 preds: ^bb168, ^bb258
      return
    }
  }
  func.func @cutlass___call_____main__GroupedGemmKernel_object_at__Tensorgmemoi641i64_Tensorgmemoi641i64_Tensorgmemoi641i64_2_Tensorgmemo2441_Tensorgmemo232621_Tensorgmemo2331_2_Tensorgmemo1316(%arg0: !memref_gmem_f16_2, %arg1: !memref_gmem_f16_2, %arg2: !memref_gmem_f16_2, %arg3: !memref_gmem_i32_, %arg4: !memref_gmem_i32_1, %arg5: !memref_gmem_i64_, %arg6: !memref_gmem_i64_1, %arg7: !gpu.async.token) attributes {llvm.emit_c_interface} {
    %0 = llvm.mlir.constant(2233785415175766016 : i64) : i64
    %1 = llvm.mlir.constant(279330 : i64) : i64
    %2 = llvm.mlir.constant(127 : i64) : i64
    %3 = llvm.mlir.constant(4539628424389459968 : i64) : i64
    %4 = llvm.mlir.constant(287522 : i64) : i64
    %c230400_i32 = arith.constant 230400 : i32
    %c192 = arith.constant 192 : index
    %c1 = arith.constant 1 : index
    %c1_i32 = arith.constant 1 : i32
    %c2_i32 = arith.constant 2 : i32
    %5 = cute.static : !cute.int_tuple<"(0,0,0)">
    %6 = cute.static : !cute.stride<"(1@1,1@0,1@2)">
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
    %7 = cute.static : !cute.layout<"((128,128),1,1,2):((65536,1),0,0,128)">
    %8 = cute.recast_layout<32, 32> (%7) : !cute.layout<"((128,128),1,1,2):((65536,1),0,0,128)"> to !cute.layout<"((128,128),1,1,2):((65536,1),0,0,128)">
    %atom = cute.make_atom() : () -> !cute_nvgpu.sm100.mma<128x128x16, num_cta = 1, ab_major = (k, k), elem_type = (f16, f16, f32), frag_kind = ss, c_scale_exp = 0>
    %9 = cute_nvgpu.atom.set_value(%atom, %false : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !cute_nvgpu.sm100.mma<128x128x16, num_cta = 1, ab_major = (k, k), elem_type = (f16, f16, f32), frag_kind = ss, c_scale_exp = 0>
    %10 = cute_nvgpu.atom.set_value(%9, %false : i1) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : !cute_nvgpu.sm100.mma<128x128x16, num_cta = 1, ab_major = (k, k), elem_type = (f16, f16, f32), frag_kind = ss, c_scale_exp = 0>
    %11 = cute_nvgpu.atom.set_value(%10, %false : i1) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : !cute_nvgpu.sm100.mma<128x128x16, num_cta = 1, ab_major = (k, k), elem_type = (f16, f16, f32), frag_kind = ss, c_scale_exp = 0>
    %12 = cute.make_tiled_mma(%11) : !mma_f16_f16_f32_128x128x16_
    %13 = llvm.alloca %c16_i32 x i64 {alignment = 64 : i64} : (i32) -> !llvm.ptr
    %iter = cute.get_iter(%arg0) : !memref_gmem_f16_2
    %lay = cute.get_layout(%arg0) : !memref_gmem_f16_2
    %14:5 = cute.get_scalars(%lay) <{only_dynamic}> : !cute.layout<"(?,?,?):(?{i64},1,?{i64})">
    %15 = arith.extui %14#1 : i32 to i64
    %16 = arith.extui %14#0 : i32 to i64
    %17 = llvm.mul %14#3, %c2_i64 : i64
    %18 = arith.extui %14#2 : i32 to i64
    %19 = llvm.mul %14#4, %c2_i64 : i64
    %20 = cute.ptrtoint(%iter) : !cute.ptr<f16, gmem, align<16>> to i64
    %21 = llvm.getelementptr %13[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %21 : i64, !llvm.ptr
    %22 = llvm.getelementptr %13[0, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %22 : i64, !llvm.ptr
    %23 = llvm.getelementptr %13[0, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %23 : i64, !llvm.ptr
    %24 = llvm.getelementptr %13[0, 3] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %24 : i64, !llvm.ptr
    %25 = llvm.getelementptr %13[0, 4] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %25 : i64, !llvm.ptr
    %26 = llvm.getelementptr %13[0, 5] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %26 : i64, !llvm.ptr
    %27 = llvm.getelementptr %13[0, 6] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %27 : i64, !llvm.ptr
    %28 = llvm.getelementptr %13[0, 7] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %28 : i64, !llvm.ptr
    %29 = llvm.getelementptr %13[0, 8] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %29 : i64, !llvm.ptr
    %30 = llvm.getelementptr %13[0, 9] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %30 : i64, !llvm.ptr
    %31 = llvm.getelementptr %13[0, 10] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %31 : i64, !llvm.ptr
    %32 = llvm.getelementptr %13[0, 11] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %32 : i64, !llvm.ptr
    %33 = llvm.getelementptr %13[0, 12] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %33 : i64, !llvm.ptr
    %34 = llvm.getelementptr %13[0, 13] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %34 : i64, !llvm.ptr
    %35 = llvm.getelementptr %13[0, 14] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %35 : i64, !llvm.ptr
    %36 = llvm.getelementptr %13[0, 15] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %36 : i64, !llvm.ptr
    %37 = llvm.udiv %20, %c16_i64 : i64
    %38 = llvm.and %37, %c9007199254740991_i64 : i64
    %39 = llvm.shl %38, %c4_i64 : i64
    llvm.store %39, %21 : i64, !llvm.ptr
    %40 = llvm.sub %16, %c1_i64 : i64
    %41 = llvm.sub %18, %c1_i64 : i64
    %42 = llvm.sub %c1_i64, %c1_i64 : i64
    %43 = llvm.mul %40, %17 : i64
    %44 = llvm.mul %41, %19 : i64
    %45 = llvm.mul %42, %c0_i64 : i64
    %46 = llvm.add %43, %44 : i64
    %47 = llvm.add %45, %45 : i64
    %48 = llvm.mul %15, %c16_i64 : i64
    %49 = llvm.udiv %48, %c8_i64 : i64
    %50 = llvm.add %49, %46 : i64
    %51 = llvm.add %50, %47 : i64
    %52 = llvm.icmp "uge" %51, %c131072_i64 : i64
    %53 = llvm.zext %52 : i1 to i64
    %54 = llvm.shl %53, %c21_i64 : i64
    %55 = llvm.udiv %17, %c16_i64 : i64
    %56 = llvm.shl %55, %c32_i64 : i64
    %57 = llvm.or %c0_i64, %54 : i64
    %58 = llvm.or %57, %56 : i64
    %59 = llvm.or %4, %58 : i64
    llvm.store %59, %22 : i64, !llvm.ptr
    %60 = llvm.udiv %19, %c16_i64 : i64
    %61 = llvm.and %60, %c4294967295_i64 : i64
    %62 = llvm.shl %61, %c0_i64 : i64
    %63 = llvm.udiv %c0_i64, %c16_i64 : i64
    %64 = llvm.shl %63, %c32_i64 : i64
    %65 = llvm.or %62, %64 : i64
    llvm.store %65, %23 : i64, !llvm.ptr
    %66 = llvm.and %63, %c4294967295_i64 : i64
    %67 = llvm.shl %66, %c0_i64 : i64
    %68 = llvm.lshr %17, %c36_i64 : i64
    %69 = llvm.and %68, %c15_i64 : i64
    %70 = llvm.shl %69, %c32_i64 : i64
    %71 = llvm.lshr %19, %c36_i64 : i64
    %72 = llvm.and %71, %c15_i64 : i64
    %73 = llvm.shl %72, %c36_i64 : i64
    %74 = llvm.lshr %c0_i64, %c36_i64 : i64
    %75 = llvm.and %74, %c15_i64 : i64
    %76 = llvm.shl %75, %c40_i64 : i64
    %77 = llvm.shl %74, %c44_i64 : i64
    %78 = llvm.or %70, %73 : i64
    %79 = llvm.or %76, %77 : i64
    %80 = llvm.or %78, %79 : i64
    %81 = llvm.or %67, %80 : i64
    llvm.store %81, %24 : i64, !llvm.ptr
    %82 = llvm.sub %15, %c1_i64 : i64
    %83 = llvm.and %82, %c4294967295_i64 : i64
    %84 = llvm.shl %83, %c0_i64 : i64
    %85 = llvm.shl %40, %c32_i64 : i64
    %86 = llvm.or %84, %85 : i64
    llvm.store %86, %25 : i64, !llvm.ptr
    %87 = llvm.and %41, %c4294967295_i64 : i64
    %88 = llvm.shl %87, %c0_i64 : i64
    %89 = llvm.shl %42, %c32_i64 : i64
    %90 = llvm.or %88, %89 : i64
    llvm.store %90, %26 : i64, !llvm.ptr
    %91 = llvm.and %42, %c4294967295_i64 : i64
    %92 = llvm.or %91, %c0_i64 : i64
    %93 = llvm.or %92, %3 : i64
    llvm.store %93, %27 : i64, !llvm.ptr
    llvm.store %2, %28 : i64, !llvm.ptr
    %94 = builtin.unrealized_conversion_cast %13 : !llvm.ptr to !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>>
    %95 = cute.ptrtoint(%94) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>> to i64
    %96 = llvm.inttoptr %95 : i64 to !llvm.ptr
    %97 = llvm.load %96 {nontemporal} : !llvm.ptr -> !llvm.struct<(array<16 x i64>)>
    %98 = builtin.unrealized_conversion_cast %97 : !llvm.struct<(array<16 x i64>)> to !cute_nvgpu.tma_descriptor_tiled
    %atom_0 = cute.make_atom() : () -> !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>
    %99 = cute_nvgpu.atom.set_value(%atom_0, %98 : !cute_nvgpu.tma_descriptor_tiled) {field = #cute_nvgpu.atom_copy_field_non_exec_tma_load<tma_desc>} : !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>
    %100 = cute.get_shape(%lay) : (!cute.layout<"(?,?,?):(?{i64},1,?{i64})">) -> !cute.shape<"(?,?,?)">
    %lay_1 = cute.make_layout(%100, %6) : !cute.layout<"(?,?,?):(1@1,1@0,1@2)">
    %view = cute.make_view(%5, %lay_1) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">
    %101 = llvm.alloca %c16_i32 x i64 {alignment = 64 : i64} : (i32) -> !llvm.ptr
    %iter_2 = cute.get_iter(%arg1) : !memref_gmem_f16_2
    %lay_3 = cute.get_layout(%arg1) : !memref_gmem_f16_2
    %102:5 = cute.get_scalars(%lay_3) <{only_dynamic}> : !cute.layout<"(?,?,?):(?{i64},1,?{i64})">
    %103 = arith.extui %102#1 : i32 to i64
    %104 = arith.extui %102#0 : i32 to i64
    %105 = llvm.mul %102#3, %c2_i64 : i64
    %106 = arith.extui %102#2 : i32 to i64
    %107 = llvm.mul %102#4, %c2_i64 : i64
    %108 = cute.ptrtoint(%iter_2) : !cute.ptr<f16, gmem, align<16>> to i64
    %109 = llvm.getelementptr %101[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %109 : i64, !llvm.ptr
    %110 = llvm.getelementptr %101[0, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %110 : i64, !llvm.ptr
    %111 = llvm.getelementptr %101[0, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %111 : i64, !llvm.ptr
    %112 = llvm.getelementptr %101[0, 3] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %112 : i64, !llvm.ptr
    %113 = llvm.getelementptr %101[0, 4] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %113 : i64, !llvm.ptr
    %114 = llvm.getelementptr %101[0, 5] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %114 : i64, !llvm.ptr
    %115 = llvm.getelementptr %101[0, 6] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %115 : i64, !llvm.ptr
    %116 = llvm.getelementptr %101[0, 7] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %116 : i64, !llvm.ptr
    %117 = llvm.getelementptr %101[0, 8] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %117 : i64, !llvm.ptr
    %118 = llvm.getelementptr %101[0, 9] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %118 : i64, !llvm.ptr
    %119 = llvm.getelementptr %101[0, 10] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %119 : i64, !llvm.ptr
    %120 = llvm.getelementptr %101[0, 11] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %120 : i64, !llvm.ptr
    %121 = llvm.getelementptr %101[0, 12] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %121 : i64, !llvm.ptr
    %122 = llvm.getelementptr %101[0, 13] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %122 : i64, !llvm.ptr
    %123 = llvm.getelementptr %101[0, 14] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %123 : i64, !llvm.ptr
    %124 = llvm.getelementptr %101[0, 15] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %124 : i64, !llvm.ptr
    %125 = llvm.udiv %108, %c16_i64 : i64
    %126 = llvm.and %125, %c9007199254740991_i64 : i64
    %127 = llvm.shl %126, %c4_i64 : i64
    llvm.store %127, %109 : i64, !llvm.ptr
    %128 = llvm.sub %104, %c1_i64 : i64
    %129 = llvm.sub %106, %c1_i64 : i64
    %130 = llvm.mul %128, %105 : i64
    %131 = llvm.mul %129, %107 : i64
    %132 = llvm.add %130, %131 : i64
    %133 = llvm.mul %103, %c16_i64 : i64
    %134 = llvm.udiv %133, %c8_i64 : i64
    %135 = llvm.add %134, %132 : i64
    %136 = llvm.add %135, %47 : i64
    %137 = llvm.icmp "uge" %136, %c131072_i64 : i64
    %138 = llvm.zext %137 : i1 to i64
    %139 = llvm.shl %138, %c21_i64 : i64
    %140 = llvm.udiv %105, %c16_i64 : i64
    %141 = llvm.shl %140, %c32_i64 : i64
    %142 = llvm.or %c0_i64, %139 : i64
    %143 = llvm.or %142, %141 : i64
    %144 = llvm.or %4, %143 : i64
    llvm.store %144, %110 : i64, !llvm.ptr
    %145 = llvm.udiv %107, %c16_i64 : i64
    %146 = llvm.and %145, %c4294967295_i64 : i64
    %147 = llvm.shl %146, %c0_i64 : i64
    %148 = llvm.or %147, %64 : i64
    llvm.store %148, %111 : i64, !llvm.ptr
    %149 = llvm.lshr %105, %c36_i64 : i64
    %150 = llvm.and %149, %c15_i64 : i64
    %151 = llvm.shl %150, %c32_i64 : i64
    %152 = llvm.lshr %107, %c36_i64 : i64
    %153 = llvm.and %152, %c15_i64 : i64
    %154 = llvm.shl %153, %c36_i64 : i64
    %155 = llvm.or %151, %154 : i64
    %156 = llvm.or %155, %79 : i64
    %157 = llvm.or %67, %156 : i64
    llvm.store %157, %112 : i64, !llvm.ptr
    %158 = llvm.sub %103, %c1_i64 : i64
    %159 = llvm.and %158, %c4294967295_i64 : i64
    %160 = llvm.shl %159, %c0_i64 : i64
    %161 = llvm.shl %128, %c32_i64 : i64
    %162 = llvm.or %160, %161 : i64
    llvm.store %162, %113 : i64, !llvm.ptr
    %163 = llvm.and %129, %c4294967295_i64 : i64
    %164 = llvm.shl %163, %c0_i64 : i64
    %165 = llvm.or %164, %89 : i64
    llvm.store %165, %114 : i64, !llvm.ptr
    llvm.store %93, %115 : i64, !llvm.ptr
    llvm.store %2, %116 : i64, !llvm.ptr
    %166 = builtin.unrealized_conversion_cast %101 : !llvm.ptr to !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>>
    %167 = cute.ptrtoint(%166) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>> to i64
    %168 = llvm.inttoptr %167 : i64 to !llvm.ptr
    %169 = llvm.load %168 {nontemporal} : !llvm.ptr -> !llvm.struct<(array<16 x i64>)>
    %170 = builtin.unrealized_conversion_cast %169 : !llvm.struct<(array<16 x i64>)> to !cute_nvgpu.tma_descriptor_tiled
    %171 = cute_nvgpu.atom.set_value(%atom_0, %170 : !cute_nvgpu.tma_descriptor_tiled) {field = #cute_nvgpu.atom_copy_field_non_exec_tma_load<tma_desc>} : !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>
    %172 = cute.get_shape(%lay_3) : (!cute.layout<"(?,?,?):(?{i64},1,?{i64})">) -> !cute.shape<"(?,?,?)">
    %lay_4 = cute.make_layout(%172, %6) : !cute.layout<"(?,?,?):(1@1,1@0,1@2)">
    %view_5 = cute.make_view(%5, %lay_4) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">
    %173 = llvm.alloca %c16_i32 x i64 {alignment = 64 : i64} : (i32) -> !llvm.ptr
    %iter_6 = cute.get_iter(%arg2) : !memref_gmem_f16_2
    %lay_7 = cute.get_layout(%arg2) : !memref_gmem_f16_2
    %174:5 = cute.get_scalars(%lay_7) <{only_dynamic}> : !cute.layout<"(?,?,?):(?{i64},1,?{i64})">
    %175 = arith.extui %174#1 : i32 to i64
    %176 = arith.extui %174#0 : i32 to i64
    %177 = llvm.mul %174#3, %c2_i64 : i64
    %178 = arith.extui %174#2 : i32 to i64
    %179 = llvm.mul %174#4, %c2_i64 : i64
    %180 = cute.ptrtoint(%iter_6) : !cute.ptr<f16, gmem, align<16>> to i64
    %181 = llvm.getelementptr %173[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %181 : i64, !llvm.ptr
    %182 = llvm.getelementptr %173[0, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %182 : i64, !llvm.ptr
    %183 = llvm.getelementptr %173[0, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %183 : i64, !llvm.ptr
    %184 = llvm.getelementptr %173[0, 3] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %184 : i64, !llvm.ptr
    %185 = llvm.getelementptr %173[0, 4] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %185 : i64, !llvm.ptr
    %186 = llvm.getelementptr %173[0, 5] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %186 : i64, !llvm.ptr
    %187 = llvm.getelementptr %173[0, 6] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %187 : i64, !llvm.ptr
    %188 = llvm.getelementptr %173[0, 7] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %188 : i64, !llvm.ptr
    %189 = llvm.getelementptr %173[0, 8] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %189 : i64, !llvm.ptr
    %190 = llvm.getelementptr %173[0, 9] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %190 : i64, !llvm.ptr
    %191 = llvm.getelementptr %173[0, 10] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %191 : i64, !llvm.ptr
    %192 = llvm.getelementptr %173[0, 11] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %192 : i64, !llvm.ptr
    %193 = llvm.getelementptr %173[0, 12] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %193 : i64, !llvm.ptr
    %194 = llvm.getelementptr %173[0, 13] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %194 : i64, !llvm.ptr
    %195 = llvm.getelementptr %173[0, 14] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %195 : i64, !llvm.ptr
    %196 = llvm.getelementptr %173[0, 15] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %196 : i64, !llvm.ptr
    %197 = llvm.udiv %180, %c16_i64 : i64
    %198 = llvm.and %197, %c9007199254740991_i64 : i64
    %199 = llvm.shl %198, %c4_i64 : i64
    llvm.store %199, %181 : i64, !llvm.ptr
    %200 = llvm.sub %176, %c1_i64 : i64
    %201 = llvm.sub %178, %c1_i64 : i64
    %202 = llvm.mul %200, %177 : i64
    %203 = llvm.mul %201, %179 : i64
    %204 = llvm.add %202, %203 : i64
    %205 = llvm.mul %175, %c16_i64 : i64
    %206 = llvm.udiv %205, %c8_i64 : i64
    %207 = llvm.add %206, %204 : i64
    %208 = llvm.add %207, %47 : i64
    %209 = llvm.icmp "uge" %208, %c131072_i64 : i64
    %210 = llvm.zext %209 : i1 to i64
    %211 = llvm.shl %210, %c21_i64 : i64
    %212 = llvm.udiv %177, %c16_i64 : i64
    %213 = llvm.shl %212, %c32_i64 : i64
    %214 = llvm.or %c0_i64, %211 : i64
    %215 = llvm.or %214, %213 : i64
    %216 = llvm.or %1, %215 : i64
    llvm.store %216, %182 : i64, !llvm.ptr
    %217 = llvm.udiv %179, %c16_i64 : i64
    %218 = llvm.and %217, %c4294967295_i64 : i64
    %219 = llvm.shl %218, %c0_i64 : i64
    %220 = llvm.or %219, %64 : i64
    llvm.store %220, %183 : i64, !llvm.ptr
    %221 = llvm.lshr %177, %c36_i64 : i64
    %222 = llvm.and %221, %c15_i64 : i64
    %223 = llvm.shl %222, %c32_i64 : i64
    %224 = llvm.lshr %179, %c36_i64 : i64
    %225 = llvm.and %224, %c15_i64 : i64
    %226 = llvm.shl %225, %c36_i64 : i64
    %227 = llvm.or %223, %226 : i64
    %228 = llvm.or %227, %79 : i64
    %229 = llvm.or %67, %228 : i64
    llvm.store %229, %184 : i64, !llvm.ptr
    %230 = llvm.sub %175, %c1_i64 : i64
    %231 = llvm.and %230, %c4294967295_i64 : i64
    %232 = llvm.shl %231, %c0_i64 : i64
    %233 = llvm.shl %200, %c32_i64 : i64
    %234 = llvm.or %232, %233 : i64
    llvm.store %234, %185 : i64, !llvm.ptr
    %235 = llvm.and %201, %c4294967295_i64 : i64
    %236 = llvm.shl %235, %c0_i64 : i64
    %237 = llvm.or %236, %89 : i64
    llvm.store %237, %186 : i64, !llvm.ptr
    %238 = llvm.or %92, %0 : i64
    llvm.store %238, %187 : i64, !llvm.ptr
    llvm.store %2, %188 : i64, !llvm.ptr
    %239 = builtin.unrealized_conversion_cast %173 : !llvm.ptr to !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>>
    %240 = cute.ptrtoint(%239) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>> to i64
    %241 = llvm.inttoptr %240 : i64 to !llvm.ptr
    %242 = llvm.load %241 {nontemporal} : !llvm.ptr -> !llvm.struct<(array<16 x i64>)>
    %243 = builtin.unrealized_conversion_cast %242 : !llvm.struct<(array<16 x i64>)> to !cute_nvgpu.tma_descriptor_tiled
    %atom_8 = cute.make_atom() : () -> !cute_nvgpu.atom.non_exec_tiled_tma_store<f16, copy_bits = 65536, tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>
    %244 = cute_nvgpu.atom.set_value(%atom_8, %243 : !cute_nvgpu.tma_descriptor_tiled) {field = #cute_nvgpu.atom_copy_field_non_exec_tma_store<tma_desc>} : !cute_nvgpu.atom.non_exec_tiled_tma_store<f16, copy_bits = 65536, tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>
    %245 = cute.get_shape(%lay_7) : (!cute.layout<"(?,?,?):(?{i64},1,?{i64})">) -> !cute.shape<"(?,?,?)">
    %lay_9 = cute.make_layout(%245, %6) : !cute.layout<"(?,?,?):(1@1,1@0,1@2)">
    %view_10 = cute.make_view(%5, %lay_9) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">
    %int_tuple = cute.make_int_tuple() : () -> !cute.int_tuple<"(1,1,2)">
    %dyn = cute.derefine(%int_tuple) : !cute.int_tuple<"(1,1,2)"> to !cute.int_tuple<"(1,1,?)">
    %246 = cute.get_scalars(%dyn) <{only_dynamic}> : !cute.int_tuple<"(1,1,?)">
    %int_tuple_11 = cute.make_int_tuple(%246) : (i32) -> !cute.int_tuple<"(1,1,?)">
    %e0, %e1, %e2 = cute.get_leaves(%int_tuple_11) : !cute.int_tuple<"(1,1,?)">
    %shape = cute.make_shape(%e2) : (!cute.int_tuple<"?">) -> !cute.shape<"(1,1,?)">
    %lay_12 = cute.make_layout(%shape) : !cute.layout<"(1,1,?):(0,0,1)">
    %247 = cute.get_shape(%lay_12) : (!cute.layout<"(1,1,?):(0,0,1)">) -> !cute.shape<"(1,1,?)">
    %e0_13, %e1_14, %e2_15 = cute.get_leaves(%247) : !cute.shape<"(1,1,?)">
    %itup = cute.to_int_tuple(%e2_15) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %int_tuple_16 = cute.make_int_tuple(%itup) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"(1,1,?)">
    %sz = cute.size(%int_tuple_16) : (!cute.int_tuple<"(1,1,?)">) -> !cute.int_tuple<"?">
    %e0_17 = cute.get_leaves(%sz) : !cute.int_tuple<"?">
    %248 = cute.get_scalars(%e0_17) : !cute.int_tuple<"?">
    %249 = arith.minsi %248, %c1_i32 : i32
    %250 = arith.index_cast %249 : i32 to index
    %251 = gpu.launch_func async [%arg7] @kernels::@kernel_cutlass_kernel___main__GroupedGemmKernel_object_at__TiledMMA_ThrLayoutVMNK11110000_PermutationMNK____MMAAtom_ThrID10_ShapeMNK12812816_TVLayoutA1128161281128_TVLayoutB1128161281128__0 clusters in (%c1, %c1, %c1) blocks in (%c1, %c1, %250) threads in (%c192, %c1, %c1)  dynamic_shared_memory_size %c230400_i32 args(%12 : !mma_f16_f16_f32_128x128x16_, %99 : !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>, %view : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">, %171 : !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>, %view_5 : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">, %244 : !cute_nvgpu.atom.non_exec_tiled_tma_store<f16, copy_bits = 65536, tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>, %view_10 : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">, %c2_i32 : i32, %arg3 : !memref_gmem_i32_, %arg4 : !memref_gmem_i32_1, %arg5 : !memref_gmem_i64_, %arg6 : !memref_gmem_i64_1) {use_pdl = false}
    return
  }
}
