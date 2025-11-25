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
      %51 = arith.divsi %50, %c32_i32 : i32
      %52 = arith.muli %51, %c32_i32 : i32
      %53 = arith.cmpi ne, %50, %52 : i32
      %c0_i32_1 = arith.constant 0 : i32
      %54 = arith.cmpi slt, %50, %c0_i32_1 : i32
      %55 = arith.cmpi slt, %c32_i32, %c0_i32_1 : i32
      %56 = arith.cmpi ne, %54, %55 : i1
      %57 = arith.andi %53, %56 : i1
      %c-1_i32_2 = arith.constant -1 : i32
      %58 = arith.addi %51, %c-1_i32_2 : i32
      %59 = arith.select %57, %58, %51 : i32
      %60 = cute_nvgpu.arch.make_warp_uniform(%59) : i32
      %61 = arith.cmpi eq, %60, %c5_i32 : i32
      cf.cond_br %61, ^bb1, ^bb2
    ^bb1:  // pred: ^bb0
      cute_nvgpu.prefetch_tma_desc(%arg1) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>) -> ()
      cute_nvgpu.prefetch_tma_desc(%arg3) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>) -> ()
      cute_nvgpu.prefetch_tma_desc(%arg5) : (!cute_nvgpu.atom.non_exec_tiled_tma_store<f16, copy_bits = 65536, tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>) -> ()
      cf.br ^bb2
    ^bb2:  // 2 preds: ^bb0, ^bb1
      %62 = nvvm.read.ptx.sreg.ctaid.x range <i32, 0, 2147483647> : i32
      %63 = nvvm.read.ptx.sreg.ctaid.y range <i32, 0, 65535> : i32
      %64 = nvvm.read.ptx.sreg.ctaid.z range <i32, 0, 65535> : i32
      %smem_ptr = cute_nvgpu.arch.get_dyn_smem() : !cute.ptr<i8, smem, align<1024>>
      %ptr = cute.add_offset(%smem_ptr, %38) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"384">) -> !cute.ptr<i8, smem, align<128>>
      %ptr_3 = cute.add_offset(%smem_ptr, %37) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"432">) -> !cute.ptr<i8, smem, align<16>>
      %ptr_4 = cute.add_offset(%smem_ptr, %36) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"480">) -> !cute.ptr<i8, smem, align<32>>
      %ptr_5 = cute.add_offset(%smem_ptr, %35) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"496">) -> !cute.ptr<i8, smem, align<16>>
      %ptr_6 = cute.add_offset(%smem_ptr, %34) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"520">) -> !cute.ptr<i8, smem, align<8>>
      %iter = cute.recast_iter(%ptr_6) : !cute.ptr<i8, smem, align<8>> to !cute.ptr<i32, smem, align<8>>
      %ptr_7 = cute.add_offset(%smem_ptr, %33) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"1024">) -> !cute.ptr<i8, smem, align<1024>>
      %ptr_8 = cute.add_offset(%smem_ptr, %32) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"33792">) -> !cute.ptr<i8, smem, align<1024>>
      %ptr_9 = cute.add_offset(%smem_ptr, %31) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"132096">) -> !cute.ptr<i8, smem, align<1024>>
      %iter_10 = cute.recast_iter(%smem_ptr) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<i64, smem, align<1024>>
      %ptr_11 = cute.add_offset(%iter_10, %30) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"16">) -> !cute.ptr<i64, smem, align<128>>
      %int_tuple_12 = cute.make_int_tuple() : () -> !cute.int_tuple<"32">
      %ptr_13 = cute.add_offset(%iter_10, %int_tuple_12) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"32">) -> !cute.ptr<i64, smem, align<256>>
      %dyn = cute.derefine(%ptr_13) : !cute.ptr<i64, smem, align<256>> to !cute.ptr<i64, smem, align<128>>
      %iter_14 = cute.recast_iter(%ptr) : !cute.ptr<i8, smem, align<128>> to !cute.ptr<i64, smem, align<128>>
      %iter_15 = cute.recast_iter(%ptr_3) : !cute.ptr<i8, smem, align<16>> to !cute.ptr<i64, smem, align<16>>
      %iter_16 = cute.recast_iter(%ptr_4) : !cute.ptr<i8, smem, align<32>> to !cute.ptr<i64, smem, align<32>>
      %iter_17 = cute.recast_iter(%ptr_5) : !cute.ptr<i8, smem, align<16>> to !cute.ptr<i64, smem, align<16>>
      %65 = arith.cmpi eq, %60, %c0_i32 : i32
      cf.cond_br %65, ^bb3, ^bb9
    ^bb3:  // pred: ^bb2
      cf.br ^bb4(%c0_i32 : i32)
    ^bb4(%66: i32):  // 2 preds: ^bb3, ^bb7
      %67 = arith.cmpi slt, %66, %c6_i32 : i32
      cf.cond_br %67, ^bb5, ^bb8
    ^bb5:  // pred: ^bb4
      %68 = nvvm.elect.sync -> i1
      cf.cond_br %68, ^bb6, ^bb7
    ^bb6:  // pred: ^bb5
      %int_tuple_18 = cute.make_int_tuple(%66) : (i32) -> !cute.int_tuple<"?">
      %ptr_19 = cute.add_offset(%iter_14, %int_tuple_18) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %69 = builtin.unrealized_conversion_cast %ptr_19 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %69, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_20 = cute.add_offset(%iter_15, %int_tuple_18) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %70 = builtin.unrealized_conversion_cast %ptr_20 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %70, %c1_i32 : !llvm.ptr<3>, i32
      cf.br ^bb7
    ^bb7:  // 2 preds: ^bb5, ^bb6
      %71 = arith.addi %66, %c1_i32 : i32
      cf.br ^bb4(%71 : i32)
    ^bb8:  // pred: ^bb4
      cf.br ^bb9
    ^bb9:  // 2 preds: ^bb2, ^bb8
      %72 = arith.cmpi eq, %60, %c4_i32 : i32
      cf.cond_br %72, ^bb10, ^bb16
    ^bb10:  // pred: ^bb9
      cf.br ^bb11(%c0_i32 : i32)
    ^bb11(%73: i32):  // 2 preds: ^bb10, ^bb14
      %74 = arith.cmpi slt, %73, %c2_i32 : i32
      cf.cond_br %74, ^bb12, ^bb15
    ^bb12:  // pred: ^bb11
      %75 = nvvm.elect.sync -> i1
      cf.cond_br %75, ^bb13, ^bb14
    ^bb13:  // pred: ^bb12
      %int_tuple_21 = cute.make_int_tuple(%73) : (i32) -> !cute.int_tuple<"?">
      %ptr_22 = cute.add_offset(%iter_16, %int_tuple_21) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %76 = builtin.unrealized_conversion_cast %ptr_22 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %76, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_23 = cute.add_offset(%iter_17, %int_tuple_21) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %77 = builtin.unrealized_conversion_cast %ptr_23 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %77, %c4_i32 : !llvm.ptr<3>, i32
      cf.br ^bb14
    ^bb14:  // 2 preds: ^bb12, ^bb13
      %78 = arith.addi %73, %c1_i32 : i32
      cf.br ^bb11(%78 : i32)
    ^bb15:  // pred: ^bb11
      cf.br ^bb16
    ^bb16:  // 2 preds: ^bb9, ^bb15
      nvvm.fence.mbarrier.init
      %iter_24 = cute.recast_iter(%ptr_7) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<f16, smem, align<1024>, S<2,4,3>>
      %iter_25 = cute.recast_iter(%ptr_8) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<f16, smem, align<1024>, S<3,4,3>>
      %iter_26 = cute.recast_iter(%ptr_9) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<f16, smem, align<1024>, S<3,4,3>>
      %lay_27 = cute.get_layout(%arg2) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">
      %79:3 = cute.get_scalars(%lay_27) <{only_dynamic}> : !cute.layout<"(?,?,?):(1@1,1@0,1@2)">
      %c1_i32_28 = arith.constant 1 : i32
      %c0_i32_29 = arith.constant 0 : i32
      %c-1_i32_30 = arith.constant -1 : i32
      %80 = arith.cmpi sgt, %c128_i32, %c0_i32_29 : i32
      %81 = arith.select %80, %c-1_i32_30, %c1_i32_28 : i32
      %82 = arith.addi %81, %79#0 : i32
      %83 = arith.divsi %82, %c128_i32 : i32
      %84 = arith.addi %c1_i32_28, %83 : i32
      %85 = arith.subi %c0_i32_29, %79#0 : i32
      %86 = arith.divsi %85, %c128_i32 : i32
      %87 = arith.subi %c0_i32_29, %86 : i32
      %88 = arith.cmpi slt, %79#0, %c0_i32_29 : i32
      %89 = arith.cmpi sgt, %79#0, %c0_i32_29 : i32
      %90 = arith.cmpi slt, %c128_i32, %c0_i32_29 : i32
      %91 = arith.cmpi sgt, %c128_i32, %c0_i32_29 : i32
      %92 = arith.andi %88, %90 : i1
      %93 = arith.andi %89, %91 : i1
      %94 = arith.ori %92, %93 : i1
      %95 = arith.select %94, %84, %87 : i32
      %c1_i32_31 = arith.constant 1 : i32
      %c0_i32_32 = arith.constant 0 : i32
      %c-1_i32_33 = arith.constant -1 : i32
      %96 = arith.cmpi sgt, %c64_i32, %c0_i32_32 : i32
      %97 = arith.select %96, %c-1_i32_33, %c1_i32_31 : i32
      %98 = arith.addi %97, %79#1 : i32
      %99 = arith.divsi %98, %c64_i32 : i32
      %100 = arith.addi %c1_i32_31, %99 : i32
      %101 = arith.subi %c0_i32_32, %79#1 : i32
      %102 = arith.divsi %101, %c64_i32 : i32
      %103 = arith.subi %c0_i32_32, %102 : i32
      %104 = arith.cmpi slt, %79#1, %c0_i32_32 : i32
      %105 = arith.cmpi sgt, %79#1, %c0_i32_32 : i32
      %106 = arith.cmpi slt, %c64_i32, %c0_i32_32 : i32
      %107 = arith.cmpi sgt, %c64_i32, %c0_i32_32 : i32
      %108 = arith.andi %104, %106 : i1
      %109 = arith.andi %105, %107 : i1
      %110 = arith.ori %108, %109 : i1
      %111 = arith.select %110, %100, %103 : i32
      %shape_34 = cute.make_shape(%95, %111, %79#2) : (i32, i32, i32) -> !cute.shape<"((128,64),(?,?,?))">
      %lay_35 = cute.make_layout(%shape_34, %29) : !cute.layout<"((128,64),(?,?,?)):((1@1,1@0),(128@1,64@0,1@2))">
      %112:3 = cute.get_scalars(%lay_35) <{only_dynamic}> : !cute.layout<"((128,64),(?,?,?)):((1@1,1@0),(128@1,64@0,1@2))">
      %shape_36 = cute.make_shape(%112#0, %112#1, %112#2) : (i32, i32, i32) -> !cute.shape<"(128,64,?,?,?)">
      %lay_37 = cute.make_layout(%shape_36, %28) : !cute.layout<"(128,64,?,?,?):(1@1,1@0,128@1,64@0,1@2)">
      %lay_38 = cute.get_layout(%arg4) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">
      %113:3 = cute.get_scalars(%lay_38) <{only_dynamic}> : !cute.layout<"(?,?,?):(1@1,1@0,1@2)">
      %c1_i32_39 = arith.constant 1 : i32
      %c0_i32_40 = arith.constant 0 : i32
      %c-1_i32_41 = arith.constant -1 : i32
      %114 = arith.cmpi sgt, %c128_i32, %c0_i32_40 : i32
      %115 = arith.select %114, %c-1_i32_41, %c1_i32_39 : i32
      %116 = arith.addi %115, %113#0 : i32
      %117 = arith.divsi %116, %c128_i32 : i32
      %118 = arith.addi %c1_i32_39, %117 : i32
      %119 = arith.subi %c0_i32_40, %113#0 : i32
      %120 = arith.divsi %119, %c128_i32 : i32
      %121 = arith.subi %c0_i32_40, %120 : i32
      %122 = arith.cmpi slt, %113#0, %c0_i32_40 : i32
      %123 = arith.cmpi sgt, %113#0, %c0_i32_40 : i32
      %124 = arith.cmpi slt, %c128_i32, %c0_i32_40 : i32
      %125 = arith.cmpi sgt, %c128_i32, %c0_i32_40 : i32
      %126 = arith.andi %122, %124 : i1
      %127 = arith.andi %123, %125 : i1
      %128 = arith.ori %126, %127 : i1
      %129 = arith.select %128, %118, %121 : i32
      %c1_i32_42 = arith.constant 1 : i32
      %c0_i32_43 = arith.constant 0 : i32
      %c-1_i32_44 = arith.constant -1 : i32
      %130 = arith.cmpi sgt, %c64_i32, %c0_i32_43 : i32
      %131 = arith.select %130, %c-1_i32_44, %c1_i32_42 : i32
      %132 = arith.addi %131, %113#1 : i32
      %133 = arith.divsi %132, %c64_i32 : i32
      %134 = arith.addi %c1_i32_42, %133 : i32
      %135 = arith.subi %c0_i32_43, %113#1 : i32
      %136 = arith.divsi %135, %c64_i32 : i32
      %137 = arith.subi %c0_i32_43, %136 : i32
      %138 = arith.cmpi slt, %113#1, %c0_i32_43 : i32
      %139 = arith.cmpi sgt, %113#1, %c0_i32_43 : i32
      %140 = arith.cmpi slt, %c64_i32, %c0_i32_43 : i32
      %141 = arith.cmpi sgt, %c64_i32, %c0_i32_43 : i32
      %142 = arith.andi %138, %140 : i1
      %143 = arith.andi %139, %141 : i1
      %144 = arith.ori %142, %143 : i1
      %145 = arith.select %144, %134, %137 : i32
      %shape_45 = cute.make_shape(%129, %145, %113#2) : (i32, i32, i32) -> !cute.shape<"((128,64),(?,?,?))">
      %lay_46 = cute.make_layout(%shape_45, %29) : !cute.layout<"((128,64),(?,?,?)):((1@1,1@0),(128@1,64@0,1@2))">
      %146:3 = cute.get_scalars(%lay_46) <{only_dynamic}> : !cute.layout<"((128,64),(?,?,?)):((1@1,1@0),(128@1,64@0,1@2))">
      %shape_47 = cute.make_shape(%146#0, %146#1, %146#2) : (i32, i32, i32) -> !cute.shape<"(128,64,?,?,?)">
      %lay_48 = cute.make_layout(%shape_47, %28) : !cute.layout<"(128,64,?,?,?):(1@1,1@0,128@1,64@0,1@2)">
      %lay_49 = cute.get_layout(%arg6) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">
      %147:3 = cute.get_scalars(%lay_49) <{only_dynamic}> : !cute.layout<"(?,?,?):(1@1,1@0,1@2)">
      %c1_i32_50 = arith.constant 1 : i32
      %c0_i32_51 = arith.constant 0 : i32
      %c-1_i32_52 = arith.constant -1 : i32
      %148 = arith.cmpi sgt, %c128_i32, %c0_i32_51 : i32
      %149 = arith.select %148, %c-1_i32_52, %c1_i32_50 : i32
      %150 = arith.addi %149, %147#0 : i32
      %151 = arith.divsi %150, %c128_i32 : i32
      %152 = arith.addi %c1_i32_50, %151 : i32
      %153 = arith.subi %c0_i32_51, %147#0 : i32
      %154 = arith.divsi %153, %c128_i32 : i32
      %155 = arith.subi %c0_i32_51, %154 : i32
      %156 = arith.cmpi slt, %147#0, %c0_i32_51 : i32
      %157 = arith.cmpi sgt, %147#0, %c0_i32_51 : i32
      %158 = arith.cmpi slt, %c128_i32, %c0_i32_51 : i32
      %159 = arith.cmpi sgt, %c128_i32, %c0_i32_51 : i32
      %160 = arith.andi %156, %158 : i1
      %161 = arith.andi %157, %159 : i1
      %162 = arith.ori %160, %161 : i1
      %163 = arith.select %162, %152, %155 : i32
      %c1_i32_53 = arith.constant 1 : i32
      %c0_i32_54 = arith.constant 0 : i32
      %c-1_i32_55 = arith.constant -1 : i32
      %164 = arith.cmpi sgt, %c128_i32, %c0_i32_54 : i32
      %165 = arith.select %164, %c-1_i32_55, %c1_i32_53 : i32
      %166 = arith.addi %165, %147#1 : i32
      %167 = arith.divsi %166, %c128_i32 : i32
      %168 = arith.addi %c1_i32_53, %167 : i32
      %169 = arith.subi %c0_i32_54, %147#1 : i32
      %170 = arith.divsi %169, %c128_i32 : i32
      %171 = arith.subi %c0_i32_54, %170 : i32
      %172 = arith.cmpi slt, %147#1, %c0_i32_54 : i32
      %173 = arith.cmpi sgt, %147#1, %c0_i32_54 : i32
      %174 = arith.cmpi slt, %c128_i32, %c0_i32_54 : i32
      %175 = arith.cmpi sgt, %c128_i32, %c0_i32_54 : i32
      %176 = arith.andi %172, %174 : i1
      %177 = arith.andi %173, %175 : i1
      %178 = arith.ori %176, %177 : i1
      %179 = arith.select %178, %168, %171 : i32
      %shape_56 = cute.make_shape(%163, %179, %147#2) : (i32, i32, i32) -> !cute.shape<"((128,128),(?,?,?))">
      %lay_57 = cute.make_layout(%shape_56, %26) : !cute.layout<"((128,128),(?,?,?)):((1@1,1@0),(128@1,128@0,1@2))">
      %180:3 = cute.get_scalars(%lay_57) <{only_dynamic}> : !cute.layout<"((128,128),(?,?,?)):((1@1,1@0),(128@1,128@0,1@2))">
      %shape_58 = cute.make_shape(%180#0, %180#1, %180#2) : (i32, i32, i32) -> !cute.shape<"(128,128,?,?,?)">
      %lay_59 = cute.make_layout(%shape_58, %25) : !cute.layout<"(128,128,?,?,?):(1@1,1@0,128@1,128@0,1@2)">
      %181:3 = cute.get_scalars(%lay_37) <{only_dynamic}> : !cute.layout<"(128,64,?,?,?):(1@1,1@0,128@1,64@0,1@2)">
      %shape_60 = cute.make_shape(%181#0, %181#1, %181#2) : (i32, i32, i32) -> !cute.shape<"((128,16),1,4,?,?,?)">
      %lay_61 = cute.make_layout(%shape_60, %24) : !cute.layout<"((128,16),1,4,?,?,?):((1@1,1@0),0,16@0,128@1,64@0,1@2)">
      %182:3 = cute.get_scalars(%lay_48) <{only_dynamic}> : !cute.layout<"(128,64,?,?,?):(1@1,1@0,128@1,64@0,1@2)">
      %shape_62 = cute.make_shape(%182#0, %182#1, %182#2) : (i32, i32, i32) -> !cute.shape<"((128,16),1,4,?,?,?)">
      %lay_63 = cute.make_layout(%shape_62, %24) : !cute.layout<"((128,16),1,4,?,?,?):((1@1,1@0),0,16@0,128@1,64@0,1@2)">
      %183:3 = cute.get_scalars(%lay_59) <{only_dynamic}> : !cute.layout<"(128,128,?,?,?):(1@1,1@0,128@1,128@0,1@2)">
      %shape_64 = cute.make_shape(%183#0, %183#1, %183#2) : (i32, i32, i32) -> !cute.shape<"((128,128),1,1,?,?,?)">
      %lay_65 = cute.make_layout(%shape_64, %23) : !cute.layout<"((128,128),1,1,?,?,?):((1@1,1@0),0,0,128@1,128@0,1@2)">
      %184:3 = cute.get_scalars(%lay_61) <{only_dynamic}> : !cute.layout<"((128,16),1,4,?,?,?):((1@1,1@0),0,16@0,128@1,64@0,1@2)">
      %shape_66 = cute.make_shape(%184#0, %184#1, %184#2) : (i32, i32, i32) -> !cute.shape<"(((128,16),1,4),?,?,?)">
      %lay_67 = cute.make_layout(%shape_66, %22) : !cute.layout<"(((128,16),1,4),?,?,?):(((1@1,1@0),0,16@0),128@1,64@0,1@2)">
      %185:3 = cute.get_scalars(%lay_67) <{only_dynamic}> : !cute.layout<"(((128,16),1,4),?,?,?):(((1@1,1@0),0,16@0),128@1,64@0,1@2)">
      %shape_68 = cute.make_shape(%185#0, %185#1, %185#2) : (i32, i32, i32) -> !cute.shape<"(((64,128),1),?,?,?)">
      %lay_69 = cute.make_layout(%shape_68, %21) : !cute.layout<"(((64,128),1),?,?,?):(((1@0,1@1),0),128@1,64@0,1@2)">
      %186:3 = cute.get_scalars(%lay_63) <{only_dynamic}> : !cute.layout<"((128,16),1,4,?,?,?):((1@1,1@0),0,16@0,128@1,64@0,1@2)">
      %shape_70 = cute.make_shape(%186#0, %186#1, %186#2) : (i32, i32, i32) -> !cute.shape<"(((128,16),1,4),?,?,?)">
      %lay_71 = cute.make_layout(%shape_70, %22) : !cute.layout<"(((128,16),1,4),?,?,?):(((1@1,1@0),0,16@0),128@1,64@0,1@2)">
      %187:3 = cute.get_scalars(%lay_71) <{only_dynamic}> : !cute.layout<"(((128,16),1,4),?,?,?):(((1@1,1@0),0,16@0),128@1,64@0,1@2)">
      %shape_72 = cute.make_shape(%187#0, %187#1, %187#2) : (i32, i32, i32) -> !cute.shape<"(((64,128),1),?,?,?)">
      %lay_73 = cute.make_layout(%shape_72, %21) : !cute.layout<"(((64,128),1),?,?,?):(((1@0,1@1),0),128@1,64@0,1@2)">
      %ummaSmemDesc = cute_nvgpu.make_umma_smem_desc(%iter_25 : !cute.ptr<f16, smem, align<1024>, S<3,4,3>>) layout = <"((128,16),1,4,6):((64,1),0,16,8192)">, major = <k> -> !cute_nvgpu.smem_desc
      %ummaSmemDesc_74 = cute_nvgpu.make_umma_smem_desc(%iter_26 : !cute.ptr<f16, smem, align<1024>, S<3,4,3>>) layout = <"((128,16),1,4,6):((64,1),0,16,8192)">, major = <k> -> !cute_nvgpu.smem_desc
      nvvm.barrier id = %c1_i32 number_of_threads = %c192_i32
      %188 = nvvm.read.ptx.sreg.nctaid.x range <i32, 1, 2147483647> : i32
      %189 = nvvm.read.ptx.sreg.nctaid.y range <i32, 1, 65535> : i32
      %190 = nvvm.read.ptx.sreg.nctaid.z range <i32, 1, 65535> : i32
      %191 = arith.muli %64, %189 : i32
      %192 = arith.muli %191, %188 : i32
      %193 = arith.muli %63, %188 : i32
      %194 = arith.addi %192, %193 : i32
      %195 = arith.addi %194, %62 : i32
      %coord = cute.make_coord(%195) : (i32) -> !cute.coord<"(?,0,_)">
      %idx = cute.crd2idx(%coord, %20) : (!cute.coord<"(?,0,_)">, !cute.layout<"(1,3,16):(1,16,1)">) -> !cute.int_tuple<"?">
      %iter_75 = cute.get_iter(%arg11) : !memref_gmem_i64_1
      %ptr_76 = cute.add_offset(%iter_75, %idx) : (!cute.ptr<i64, gmem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, gmem>
      %196 = cute.ptrtoint(%ptr_76) : !cute.ptr<i64, gmem> to i64
      %iv = cute.assume(%196) : (i64) -> !cute.i64<divby 128>
      %197 = cute.inttoptr(%iv) : !cute.i64<divby 128> to !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, gmem, align<128>>
      %coord_77 = cute.make_coord(%195) : (i32) -> !cute.coord<"(?,1,_)">
      %idx_78 = cute.crd2idx(%coord_77, %20) : (!cute.coord<"(?,1,_)">, !cute.layout<"(1,3,16):(1,16,1)">) -> !cute.int_tuple<"?">
      %ptr_79 = cute.add_offset(%iter_75, %idx_78) : (!cute.ptr<i64, gmem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, gmem>
      %198 = cute.ptrtoint(%ptr_79) : !cute.ptr<i64, gmem> to i64
      %iv_80 = cute.assume(%198) : (i64) -> !cute.i64<divby 128>
      %199 = cute.inttoptr(%iv_80) : !cute.i64<divby 128> to !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, gmem, align<128>>
      %coord_81 = cute.make_coord(%195) : (i32) -> !cute.coord<"(?,2,_)">
      %idx_82 = cute.crd2idx(%coord_81, %20) : (!cute.coord<"(?,2,_)">, !cute.layout<"(1,3,16):(1,16,1)">) -> !cute.int_tuple<"?">
      %ptr_83 = cute.add_offset(%iter_75, %idx_82) : (!cute.ptr<i64, gmem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, gmem>
      %200 = cute.ptrtoint(%ptr_83) : !cute.ptr<i64, gmem> to i64
      %iv_84 = cute.assume(%200) : (i64) -> !cute.i64<divby 128>
      %201 = cute.inttoptr(%iv_84) : !cute.i64<divby 128> to !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, gmem, align<128>>
      cf.cond_br %61, ^bb17, ^bb97
    ^bb17:  // pred: ^bb16
      %int_tuple_85 = cute.make_int_tuple(%188, %189, %190) : (i32, i32, i32) -> !cute.int_tuple<"(?,?,?)">
      %sz = cute.size(%int_tuple_85) : (!cute.int_tuple<"(?,?,?)">) -> !cute.int_tuple<"?">
      %e0_86 = cute.get_leaves(%sz) : !cute.int_tuple<"?">
      %div = cute.tuple_div(%e0_86, %39) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %202 = cute.get_scalars(%div) : !cute.int_tuple<"?">
      %sz_87 = cute.size(%lay) : (!cute.layout<"(1,1,?):(0,0,1)">) -> !cute.int_tuple<"?">
      %e0_88 = cute.get_leaves(%sz_87) : !cute.int_tuple<"?">
      %203 = cute.get_scalars(%e0_88) : !cute.int_tuple<"?">
      %204 = arith.cmpi sgt, %203, %64 : i32
      %205 = cute.get_hier_coord(%64, %lay) : (i32, !cute.layout<"(1,1,?):(0,0,1)">) -> !cute.coord<"(0,0,?)">
      %e0_89, %e1_90, %e2_91 = cute.get_leaves(%205) : !cute.coord<"(0,0,?)">
      %itup = cute.to_int_tuple(%e2_91) : !cute.coord<"?"> to !cute.int_tuple<"?">
      %mul = cute.tuple_mul(%itup, %39) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %206 = cute.get_scalars(%mul) : !cute.int_tuple<"?">
      %207 = nvvm.read.ptx.sreg.laneid range <i32, 0, 32> : i32
      %208 = arith.cmpi sge, %207, %c1_i32 : i32
      %209 = arith.cmpi sge, %207, %c2_i32 : i32
      %210 = arith.cmpi sge, %207, %c4_i32 : i32
      %211 = arith.cmpi sge, %207, %c8_i32 : i32
      %212 = arith.cmpi sge, %207, %c16_i32 : i32
      %iter_92 = cute.get_iter(%arg8) : !memref_gmem_i32_
      %213 = cute.get_scalars(%39) : !cute.int_tuple<"1">
      %214:3 = cute.get_scalars(%lay_69) <{only_dynamic}> : !cute.layout<"(((64,128),1),?,?,?):(((1@0,1@1),0),128@1,64@0,1@2)">
      %shape_93 = cute.make_shape(%214#1) : (i32) -> !cute.shape<"(((64,128),1),?)">
      %lay_94 = cute.make_layout(%shape_93, %14) : !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">
      %215:3 = cute.get_scalars(%lay_73) <{only_dynamic}> : !cute.layout<"(((64,128),1),?,?,?):(((1@0,1@1),0),128@1,64@0,1@2)">
      %shape_95 = cute.make_shape(%215#1) : (i32) -> !cute.shape<"(((64,128),1),?)">
      %lay_96 = cute.make_layout(%shape_95, %14) : !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">
      %216 = cute.ptrtoint(%197) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, gmem, align<128>> to i64
      %iv_97 = cute.assume(%216) : (i64) -> !cute.i64<divby 128>
      %217 = cute.inttoptr(%iv_97) : !cute.i64<divby 128> to !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<128>>
      %218 = cute_nvgpu.atom.make_exec_tma(%arg1) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>
      %219 = cute.ptrtoint(%199) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, gmem, align<128>> to i64
      %iv_98 = cute.assume(%219) : (i64) -> !cute.i64<divby 128>
      %220 = cute.inttoptr(%iv_98) : !cute.i64<divby 128> to !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<128>>
      %221 = cute_nvgpu.atom.make_exec_tma(%arg3) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>
      cf.br ^bb18(%false, %c0_i32, %206, %204, %c-1_i32, %c0_i32, %c0_i32, %64, %c0_i32 : i1, i32, i32, i1, i32, i32, i32, i32, i32)
    ^bb18(%222: i1, %223: i32, %224: i32, %225: i1, %226: i32, %227: i32, %228: i32, %229: i32, %230: i32):  // 2 preds: ^bb17, ^bb95
      cf.cond_br %225, ^bb19(%222, %223, %224, %226, %227, %228, %229, %230 : i1, i32, i32, i32, i32, i32, i32, i32), ^bb96
    ^bb19(%231: i1, %232: i32, %233: i32, %234: i32, %235: i32, %236: i32, %237: i32, %238: i32):  // pred: ^bb18
      %239 = arith.cmpi sge, %233, %236 : i32
      cf.br ^bb20(%239, %235, %236, %236 : i1, i32, i32, i32)
    ^bb20(%240: i1, %241: i32, %242: i32, %243: i32):  // 2 preds: ^bb19, ^bb52
      cf.cond_br %240, ^bb21(%241, %242, %243 : i32, i32, i32), ^bb53
    ^bb21(%244: i32, %245: i32, %246: i32):  // pred: ^bb20
      %247 = arith.addi %244, %207 : i32
      %248 = arith.cmpi slt, %247, %c2_i32 : i32
      cf.cond_br %248, ^bb22, ^bb26
    ^bb22:  // pred: ^bb21
      %rmem = cute.memref.alloca() : !memref_rmem_i32_
      %coord_99 = cute.make_coord(%247) : (i32) -> !cute.coord<"(?,_)">
      %idx_100 = cute.crd2idx(%coord_99, %18) : (!cute.coord<"(?,_)">, !cute.layout<"(2,4):(4,1)">) -> !cute.int_tuple<"?{div=4}">
      %iter_101 = cute.get_iter(%arg8) : !memref_gmem_i32_
      %ptr_102 = cute.add_offset(%iter_101, %idx_100) : (!cute.ptr<i32, gmem, align<16>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<i32, gmem, align<16>>
      %iter_103 = cute.get_iter(%rmem) : !memref_rmem_i32_
      %249 = cute.get_scalars(%39) : !cute.int_tuple<"1">
      %250 = builtin.unrealized_conversion_cast %ptr_102 : !cute.ptr<i32, gmem, align<16>> to !llvm.ptr<1>
      %251 = builtin.unrealized_conversion_cast %iter_103 : !cute.ptr<i32, rmem, align<32>> to !llvm.ptr
      cf.br ^bb23(%c0_i32 : i32)
    ^bb23(%252: i32):  // 2 preds: ^bb22, ^bb24
      %253 = arith.cmpi slt, %252, %249 : i32
      cf.cond_br %253, ^bb24, ^bb25 {llvm.loop_annotation = #loop_annotation}
    ^bb24:  // pred: ^bb23
      %254 = llvm.load %250 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<4xi32>
      llvm.store %254, %251 {alignment = 16 : i64} : vector<4xi32>, !llvm.ptr
      %255 = arith.addi %252, %c1_i32 : i32
      cf.br ^bb23(%255 : i32)
    ^bb25:  // pred: ^bb23
      %256 = cute.memref.load(%rmem, %19) : (!memref_rmem_i32_, !cute.coord<"0">) -> i32
      %257 = arith.addi %256, %c127_i32 : i32
      %258 = arith.divsi %257, %c128_i32 : i32
      %259 = arith.muli %258, %c128_i32 : i32
      %260 = arith.cmpi ne, %257, %259 : i32
      %c0_i32_104 = arith.constant 0 : i32
      %261 = arith.cmpi slt, %257, %c0_i32_104 : i32
      %262 = arith.cmpi slt, %c128_i32, %c0_i32_104 : i32
      %263 = arith.cmpi ne, %261, %262 : i1
      %264 = arith.andi %260, %263 : i1
      %c-1_i32_105 = arith.constant -1 : i32
      %265 = arith.addi %258, %c-1_i32_105 : i32
      %266 = arith.select %264, %265, %258 : i32
      %267 = cute.memref.load(%rmem, %17) : (!memref_rmem_i32_, !cute.coord<"1">) -> i32
      %268 = arith.addi %267, %c127_i32 : i32
      %269 = arith.divsi %268, %c128_i32 : i32
      %270 = arith.muli %269, %c128_i32 : i32
      %271 = arith.cmpi ne, %268, %270 : i32
      %c0_i32_106 = arith.constant 0 : i32
      %272 = arith.cmpi slt, %268, %c0_i32_106 : i32
      %273 = arith.cmpi slt, %c128_i32, %c0_i32_106 : i32
      %274 = arith.cmpi ne, %272, %273 : i1
      %275 = arith.andi %271, %274 : i1
      %c-1_i32_107 = arith.constant -1 : i32
      %276 = arith.addi %269, %c-1_i32_107 : i32
      %277 = arith.select %275, %276, %269 : i32
      %278 = arith.muli %266, %277 : i32
      cf.br ^bb27(%278 : i32)
    ^bb26:  // pred: ^bb21
      cf.br ^bb27(%c0_i32 : i32)
    ^bb27(%279: i32):  // 2 preds: ^bb25, ^bb26
      cf.br ^bb28
    ^bb28:  // pred: ^bb27
      %280 = nvvm.shfl.sync  up %c-1_i32, %279, %c1_i32, %c0_i32 : i32 -> i32
      cf.cond_br %208, ^bb29, ^bb30
    ^bb29:  // pred: ^bb28
      %281 = arith.addi %279, %280 : i32
      cf.br ^bb31(%281 : i32)
    ^bb30:  // pred: ^bb28
      cf.br ^bb31(%279 : i32)
    ^bb31(%282: i32):  // 2 preds: ^bb29, ^bb30
      cf.br ^bb32
    ^bb32:  // pred: ^bb31
      %283 = nvvm.shfl.sync  up %c-1_i32, %282, %c2_i32, %c0_i32 : i32 -> i32
      cf.cond_br %209, ^bb33, ^bb34
    ^bb33:  // pred: ^bb32
      %284 = arith.addi %282, %283 : i32
      cf.br ^bb35(%284 : i32)
    ^bb34:  // pred: ^bb32
      cf.br ^bb35(%282 : i32)
    ^bb35(%285: i32):  // 2 preds: ^bb33, ^bb34
      cf.br ^bb36
    ^bb36:  // pred: ^bb35
      %286 = nvvm.shfl.sync  up %c-1_i32, %285, %c4_i32, %c0_i32 : i32 -> i32
      cf.cond_br %210, ^bb37, ^bb38
    ^bb37:  // pred: ^bb36
      %287 = arith.addi %285, %286 : i32
      cf.br ^bb39(%287 : i32)
    ^bb38:  // pred: ^bb36
      cf.br ^bb39(%285 : i32)
    ^bb39(%288: i32):  // 2 preds: ^bb37, ^bb38
      cf.br ^bb40
    ^bb40:  // pred: ^bb39
      %289 = nvvm.shfl.sync  up %c-1_i32, %288, %c8_i32, %c0_i32 : i32 -> i32
      cf.cond_br %211, ^bb41, ^bb42
    ^bb41:  // pred: ^bb40
      %290 = arith.addi %288, %289 : i32
      cf.br ^bb43(%290 : i32)
    ^bb42:  // pred: ^bb40
      cf.br ^bb43(%288 : i32)
    ^bb43(%291: i32):  // 2 preds: ^bb41, ^bb42
      cf.br ^bb44
    ^bb44:  // pred: ^bb43
      %292 = nvvm.shfl.sync  up %c-1_i32, %291, %c16_i32, %c0_i32 : i32 -> i32
      cf.cond_br %212, ^bb45, ^bb46
    ^bb45:  // pred: ^bb44
      %293 = arith.addi %291, %292 : i32
      cf.br ^bb47(%293 : i32)
    ^bb46:  // pred: ^bb44
      cf.br ^bb47(%291 : i32)
    ^bb47(%294: i32):  // 2 preds: ^bb45, ^bb46
      cf.br ^bb48
    ^bb48:  // pred: ^bb47
      %295 = arith.addi %294, %246 : i32
      %296 = arith.cmpi sge, %233, %295 : i32
      %297 = nvvm.vote.ballot.sync %c-1_i32, %296 : i32
      %298 = llvm.intr.ctpop(%297) : (i32) -> i32
      %299 = arith.cmpi eq, %298, %c32_i32 : i32
      %300 = arith.addi %298, %244 : i32
      %301 = arith.cmpi eq, %298, %c0_i32 : i32
      %302 = arith.cmpi eq, %301, %false : i1
      cf.cond_br %302, ^bb49, ^bb50
    ^bb49:  // pred: ^bb48
      %303 = arith.subi %298, %c1_i32 : i32
      %304 = nvvm.shfl.sync  idx %c-1_i32, %295, %303, %c31_i32 : i32 -> i32
      cf.br ^bb51(%304 : i32)
    ^bb50:  // pred: ^bb48
      cf.br ^bb51(%246 : i32)
    ^bb51(%305: i32):  // 2 preds: ^bb49, ^bb50
      cf.br ^bb52
    ^bb52:  // pred: ^bb51
      %306 = arith.select %299, %c31_i32, %298 : i32
      %307 = nvvm.shfl.sync  idx %c-1_i32, %295, %306, %c31_i32 : i32 -> i32
      cf.br ^bb20(%299, %300, %305, %307 : i1, i32, i32, i32)
    ^bb53:  // pred: ^bb20
      %rmem_108 = cute.memref.alloca() : !memref_rmem_i32_
      %coord_109 = cute.make_coord(%241) : (i32) -> !cute.coord<"(?,_)">
      %idx_110 = cute.crd2idx(%coord_109, %18) : (!cute.coord<"(?,_)">, !cute.layout<"(2,4):(4,1)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_111 = cute.add_offset(%iter_92, %idx_110) : (!cute.ptr<i32, gmem, align<16>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<i32, gmem, align<16>>
      %iter_112 = cute.get_iter(%rmem_108) : !memref_rmem_i32_
      %308 = builtin.unrealized_conversion_cast %ptr_111 : !cute.ptr<i32, gmem, align<16>> to !llvm.ptr<1>
      %309 = builtin.unrealized_conversion_cast %iter_112 : !cute.ptr<i32, rmem, align<32>> to !llvm.ptr
      cf.br ^bb54(%c0_i32 : i32)
    ^bb54(%310: i32):  // 2 preds: ^bb53, ^bb55
      %311 = arith.cmpi slt, %310, %213 : i32
      cf.cond_br %311, ^bb55, ^bb56 {llvm.loop_annotation = #loop_annotation}
    ^bb55:  // pred: ^bb54
      %312 = llvm.load %308 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<4xi32>
      llvm.store %312, %309 {alignment = 16 : i64} : vector<4xi32>, !llvm.ptr
      %313 = arith.addi %310, %c1_i32 : i32
      cf.br ^bb54(%313 : i32)
    ^bb56:  // pred: ^bb54
      %314 = arith.subi %233, %242 : i32
      %315 = cute.memref.load(%rmem_108, %19) : (!memref_rmem_i32_, !cute.coord<"0">) -> i32
      %316 = cute.memref.load(%rmem_108, %17) : (!memref_rmem_i32_, !cute.coord<"1">) -> i32
      %317 = cute.memref.load(%rmem_108, %16) : (!memref_rmem_i32_, !cute.coord<"2">) -> i32
      %int_tuple_113 = cute.make_int_tuple(%315, %316, %317) : (i32, i32, i32) -> !cute.int_tuple<"(?,?,?)">
      %318:3 = cute.get_scalars(%int_tuple_113) <{only_dynamic}> : !cute.int_tuple<"(?,?,?)">
      %c1_i32_114 = arith.constant 1 : i32
      %c0_i32_115 = arith.constant 0 : i32
      %c-1_i32_116 = arith.constant -1 : i32
      %319 = arith.cmpi sgt, %c128_i32, %c0_i32_115 : i32
      %320 = arith.select %319, %c-1_i32_116, %c1_i32_114 : i32
      %321 = arith.addi %320, %318#0 : i32
      %322 = arith.divsi %321, %c128_i32 : i32
      %323 = arith.addi %c1_i32_114, %322 : i32
      %324 = arith.subi %c0_i32_115, %318#0 : i32
      %325 = arith.divsi %324, %c128_i32 : i32
      %326 = arith.subi %c0_i32_115, %325 : i32
      %327 = arith.cmpi slt, %318#0, %c0_i32_115 : i32
      %328 = arith.cmpi sgt, %318#0, %c0_i32_115 : i32
      %329 = arith.cmpi slt, %c128_i32, %c0_i32_115 : i32
      %330 = arith.cmpi sgt, %c128_i32, %c0_i32_115 : i32
      %331 = arith.andi %327, %329 : i1
      %332 = arith.andi %328, %330 : i1
      %333 = arith.ori %331, %332 : i1
      %334 = arith.select %333, %323, %326 : i32
      %c1_i32_117 = arith.constant 1 : i32
      %c0_i32_118 = arith.constant 0 : i32
      %c-1_i32_119 = arith.constant -1 : i32
      %335 = arith.cmpi sgt, %c128_i32, %c0_i32_118 : i32
      %336 = arith.select %335, %c-1_i32_119, %c1_i32_117 : i32
      %337 = arith.addi %336, %318#1 : i32
      %338 = arith.divsi %337, %c128_i32 : i32
      %339 = arith.addi %c1_i32_117, %338 : i32
      %340 = arith.subi %c0_i32_118, %318#1 : i32
      %341 = arith.divsi %340, %c128_i32 : i32
      %342 = arith.subi %c0_i32_118, %341 : i32
      %343 = arith.cmpi slt, %318#1, %c0_i32_118 : i32
      %344 = arith.cmpi sgt, %318#1, %c0_i32_118 : i32
      %345 = arith.cmpi slt, %c128_i32, %c0_i32_118 : i32
      %346 = arith.cmpi sgt, %c128_i32, %c0_i32_118 : i32
      %347 = arith.andi %343, %345 : i1
      %348 = arith.andi %344, %346 : i1
      %349 = arith.ori %347, %348 : i1
      %350 = arith.select %349, %339, %342 : i32
      %c1_i32_120 = arith.constant 1 : i32
      %c0_i32_121 = arith.constant 0 : i32
      %c-1_i32_122 = arith.constant -1 : i32
      %351 = arith.cmpi sgt, %c64_i32, %c0_i32_121 : i32
      %352 = arith.select %351, %c-1_i32_122, %c1_i32_120 : i32
      %353 = arith.addi %352, %318#2 : i32
      %354 = arith.divsi %353, %c64_i32 : i32
      %355 = arith.addi %c1_i32_120, %354 : i32
      %356 = arith.subi %c0_i32_121, %318#2 : i32
      %357 = arith.divsi %356, %c64_i32 : i32
      %358 = arith.subi %c0_i32_121, %357 : i32
      %359 = arith.cmpi slt, %318#2, %c0_i32_121 : i32
      %360 = arith.cmpi sgt, %318#2, %c0_i32_121 : i32
      %361 = arith.cmpi slt, %c64_i32, %c0_i32_121 : i32
      %362 = arith.cmpi sgt, %c64_i32, %c0_i32_121 : i32
      %363 = arith.andi %359, %361 : i1
      %364 = arith.andi %360, %362 : i1
      %365 = arith.ori %363, %364 : i1
      %366 = arith.select %365, %355, %358 : i32
      %int_tuple_123 = cute.make_int_tuple(%334, %350, %366) : (i32, i32, i32) -> !cute.int_tuple<"(?,?,?)">
      %e0_124, %e1_125, %e2_126 = cute.get_leaves(%int_tuple_123) : !cute.int_tuple<"(?,?,?)">
      %367 = cute.get_scalars(%e2_126) : !cute.int_tuple<"?">
      %shape_127 = cute.make_shape(%e0_124, %e1_125) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.shape<"(?,?)">
      %lay_128 = cute.make_layout(%shape_127) : !cute.layout<"(?,?):(1,?)">
      %368 = cute.get_hier_coord(%314, %lay_128) : (i32, !cute.layout<"(?,?):(1,?)">) -> !cute.coord<"(?,?)">
      %e0_129, %e1_130 = cute.get_leaves(%368) : !cute.coord<"(?,?)">
      %itup_131 = cute.to_int_tuple(%e0_129) : !cute.coord<"?"> to !cute.int_tuple<"?">
      %itup_132 = cute.to_int_tuple(%e1_130) : !cute.coord<"?"> to !cute.int_tuple<"?">
      %mul_133 = cute.tuple_mul(%itup_131, %39) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %mul_134 = cute.tuple_mul(%itup_132, %39) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %369 = arith.cmpi ne, %241, %234 : i32
      cf.cond_br %369, ^bb57, ^bb70
    ^bb57:  // pred: ^bb56
      %coord_135 = cute.make_coord(%241) : (i32) -> !cute.coord<"(?,0)">
      %370 = cute.memref.load(%arg10, %coord_135) : (!memref_gmem_i64_, !cute.coord<"(?,0)">) -> i64
      %iv_136 = cute.assume(%370) : (i64) -> !cute.i64<divby 16>
      %371 = cute.inttoptr(%iv_136) : !cute.i64<divby 16> to !cute.ptr<f16, gmem, align<16>>
      %coord_137 = cute.make_coord(%241) : (i32) -> !cute.coord<"(?,0,_)">
      %idx_138 = cute.crd2idx(%coord_137, %15) : (!cute.coord<"(?,0,_)">, !cute.layout<"(2,3,2):(6,2,1)">) -> !cute.int_tuple<"?{div=6}">
      %iter_139 = cute.get_iter(%arg9) : !memref_gmem_i32_1
      %ptr_140 = cute.add_offset(%iter_139, %idx_138) : (!cute.ptr<i32, gmem, align<16>>, !cute.int_tuple<"?{div=6}">) -> !cute.ptr<i32, gmem, align<8>>
      %rmem_141 = cute.memref.alloca() : !memref_rmem_i32_1
      %iter_142 = cute.get_iter(%rmem_141) : !memref_rmem_i32_1
      %372 = builtin.unrealized_conversion_cast %ptr_140 : !cute.ptr<i32, gmem, align<8>> to !llvm.ptr<1>
      %373 = builtin.unrealized_conversion_cast %iter_142 : !cute.ptr<i32, rmem, align<32>> to !llvm.ptr
      cf.br ^bb58(%c0_i32 : i32)
    ^bb58(%374: i32):  // 2 preds: ^bb57, ^bb59
      %375 = arith.cmpi slt, %374, %213 : i32
      cf.cond_br %375, ^bb59, ^bb60 {llvm.loop_annotation = #loop_annotation}
    ^bb59:  // pred: ^bb58
      %376 = llvm.load %372 {alignment = 8 : i64} : !llvm.ptr<1> -> vector<2xi32>
      llvm.store %376, %373 {alignment = 8 : i64} : vector<2xi32>, !llvm.ptr
      %377 = arith.addi %374, %c1_i32 : i32
      cf.br ^bb58(%377 : i32)
    ^bb60:  // pred: ^bb58
      %378 = cute.memref.load(%rmem_141, %19) : (!memref_rmem_i32_1, !cute.coord<"0">) -> i32
      %379 = cute.memref.load(%rmem_141, %17) : (!memref_rmem_i32_1, !cute.coord<"1">) -> i32
      %shape_143 = cute.make_shape(%315, %317) : (i32, i32) -> !cute.shape<"(?,?,1)">
      %stride = cute.make_stride(%378, %379) : (i32, i32) -> !cute.stride<"(?,?,0)">
      %lay_144 = cute.make_layout(%shape_143, %stride) : !cute.layout<"(?,?,1):(?,?,0)">
      %view = cute.make_view(%371, %lay_144) : !memref_gmem_f16_
      %dyn_145 = cute.derefine(%view) : !memref_gmem_f16_ to !memref_gmem_f16_1
      %coord_146 = cute.make_coord(%241) : (i32) -> !cute.coord<"(?,1)">
      %380 = cute.memref.load(%arg10, %coord_146) : (!memref_gmem_i64_, !cute.coord<"(?,1)">) -> i64
      %iv_147 = cute.assume(%380) : (i64) -> !cute.i64<divby 16>
      %381 = cute.inttoptr(%iv_147) : !cute.i64<divby 16> to !cute.ptr<f16, gmem, align<16>>
      %coord_148 = cute.make_coord(%241) : (i32) -> !cute.coord<"(?,1,_)">
      %idx_149 = cute.crd2idx(%coord_148, %15) : (!cute.coord<"(?,1,_)">, !cute.layout<"(2,3,2):(6,2,1)">) -> !cute.int_tuple<"?{div=2}">
      %ptr_150 = cute.add_offset(%iter_139, %idx_149) : (!cute.ptr<i32, gmem, align<16>>, !cute.int_tuple<"?{div=2}">) -> !cute.ptr<i32, gmem, align<8>>
      %rmem_151 = cute.memref.alloca() : !memref_rmem_i32_1
      %iter_152 = cute.get_iter(%rmem_151) : !memref_rmem_i32_1
      %382 = builtin.unrealized_conversion_cast %ptr_150 : !cute.ptr<i32, gmem, align<8>> to !llvm.ptr<1>
      %383 = builtin.unrealized_conversion_cast %iter_152 : !cute.ptr<i32, rmem, align<32>> to !llvm.ptr
      cf.br ^bb61(%c0_i32 : i32)
    ^bb61(%384: i32):  // 2 preds: ^bb60, ^bb62
      %385 = arith.cmpi slt, %384, %213 : i32
      cf.cond_br %385, ^bb62, ^bb63 {llvm.loop_annotation = #loop_annotation}
    ^bb62:  // pred: ^bb61
      %386 = llvm.load %382 {alignment = 8 : i64} : !llvm.ptr<1> -> vector<2xi32>
      llvm.store %386, %383 {alignment = 8 : i64} : vector<2xi32>, !llvm.ptr
      %387 = arith.addi %384, %c1_i32 : i32
      cf.br ^bb61(%387 : i32)
    ^bb63:  // pred: ^bb61
      %388 = cute.memref.load(%rmem_151, %19) : (!memref_rmem_i32_1, !cute.coord<"0">) -> i32
      %389 = cute.memref.load(%rmem_151, %17) : (!memref_rmem_i32_1, !cute.coord<"1">) -> i32
      %shape_153 = cute.make_shape(%316, %317) : (i32, i32) -> !cute.shape<"(?,?,1)">
      %stride_154 = cute.make_stride(%388, %389) : (i32, i32) -> !cute.stride<"(?,?,0)">
      %lay_155 = cute.make_layout(%shape_153, %stride_154) : !cute.layout<"(?,?,1):(?,?,0)">
      %view_156 = cute.make_view(%381, %lay_155) : !memref_gmem_f16_
      %dyn_157 = cute.derefine(%view_156) : !memref_gmem_f16_ to !memref_gmem_f16_1
      %390 = arith.cmpi eq, %231, %false : i1
      %391 = arith.select %390, %true, %231 : i1
      cf.cond_br %390, ^bb64, ^bb65
    ^bb64:  // pred: ^bb63
      nvvm.barrier id = %c4_i32 number_of_threads = %c160_i32
      cf.br ^bb65
    ^bb65:  // 2 preds: ^bb63, ^bb64
      cf.cond_br %61, ^bb66, ^bb69
    ^bb66:  // pred: ^bb65
      cute_nvgpu.update_tma_desc(%arg1, %dyn_145, %iter_10) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>, !memref_gmem_f16_1, !cute.ptr<i64, smem, align<1024>>) -> ()
      cute_nvgpu.update_tma_desc(%arg3, %dyn_157, %ptr_11) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>, !memref_gmem_f16_1, !cute.ptr<i64, smem, align<128>>) -> ()
      %392 = nvvm.elect.sync -> i1
      cf.cond_br %392, ^bb67, ^bb68
    ^bb67:  // pred: ^bb66
      nvvm.cp.async.bulk.commit.group
      nvvm.cp.async.bulk.wait_group 0 {read}
      cf.br ^bb68
    ^bb68:  // 2 preds: ^bb66, ^bb67
      nvvm.bar.warp.sync %c-1_i32 : i32
      %393 = cute.ptrtoint(%197) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, gmem, align<128>> to i64
      %394 = cute.ptrtoint(%iter_10) : !cute.ptr<i64, smem, align<1024>> to i32
      llvm.inline_asm has_side_effects asm_dialect = att "tensormap.cp_fenceproxy.global.shared::cta.tensormap::generic.release.gpu.sync.aligned [$0], [$1], 128;", "l,r" %393, %394 : (i64, i32) -> ()
      %395 = cute.ptrtoint(%199) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, gmem, align<128>> to i64
      %396 = cute.ptrtoint(%ptr_11) : !cute.ptr<i64, smem, align<128>> to i32
      llvm.inline_asm has_side_effects asm_dialect = att "tensormap.cp_fenceproxy.global.shared::cta.tensormap::generic.release.gpu.sync.aligned [$0], [$1], 128;", "l,r" %395, %396 : (i64, i32) -> ()
      cf.br ^bb69
    ^bb69:  // 2 preds: ^bb65, ^bb68
      cf.br ^bb71(%391 : i1)
    ^bb70:  // pred: ^bb56
      cf.br ^bb71(%231 : i1)
    ^bb71(%397: i1):  // 2 preds: ^bb69, ^bb70
      cf.br ^bb72
    ^bb72:  // pred: ^bb71
      %div_158 = cute.tuple_div(%mul_133, %39) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %coord_159 = cute.make_coord(%div_158) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,?,_,0)">
      %idx_160 = cute.crd2idx(%coord_159, %lay_69) : (!cute.coord<"(_,?,_,0)">, !cute.layout<"(((64,128),1),?,?,?):(((1@0,1@1),0),128@1,64@0,1@2)">) -> !cute.int_tuple<"(0,?{div=128},0)">
      %tup = cute.add_offset(%27, %idx_160) : (!cute.int_tuple<"(0,0,0)">, !cute.int_tuple<"(0,?{div=128},0)">) -> !cute.int_tuple<"(0,?{div=128},0)">
      %coord_161 = cute.make_coord(%mul_134) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,?,_,0)">
      %idx_162 = cute.crd2idx(%coord_161, %lay_73) : (!cute.coord<"(_,?,_,0)">, !cute.layout<"(((64,128),1),?,?,?):(((1@0,1@1),0),128@1,64@0,1@2)">) -> !cute.int_tuple<"(0,?{div=128},0)">
      %tup_163 = cute.add_offset(%27, %idx_162) : (!cute.int_tuple<"(0,0,0)">, !cute.int_tuple<"(0,?{div=128},0)">) -> !cute.int_tuple<"(0,?{div=128},0)">
      %int_tuple_164 = cute.make_int_tuple(%232) : (i32) -> !cute.int_tuple<"?">
      %tup_165 = cute.add_offset(%int_tuple_164, %e2_126) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.int_tuple<"?">
      %398 = cute.get_scalars(%tup_165) : !cute.int_tuple<"?">
      %399 = arith.remsi %232, %c6_i32 : i32
      %400 = arith.divsi %232, %c6_i32 : i32
      %401 = arith.muli %400, %c6_i32 : i32
      %402 = arith.cmpi ne, %232, %401 : i32
      %c0_i32_166 = arith.constant 0 : i32
      %403 = arith.cmpi slt, %232, %c0_i32_166 : i32
      %404 = arith.cmpi slt, %c6_i32, %c0_i32_166 : i32
      %405 = arith.cmpi ne, %403, %404 : i1
      %406 = arith.andi %402, %405 : i1
      %c-1_i32_167 = arith.constant -1 : i32
      %407 = arith.addi %400, %c-1_i32_167 : i32
      %408 = arith.select %406, %407, %400 : i32
      %409 = arith.remsi %408, %c2_i32 : i32
      %410 = arith.xori %409, %c1_i32 : i32
      %411 = arith.cmpi sgt, %367, %c0_i32 : i32
      %int_tuple_168 = cute.make_int_tuple(%399) : (i32) -> !cute.int_tuple<"?">
      %ptr_169 = cute.add_offset(%iter_15, %int_tuple_168) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      cf.cond_br %411, ^bb73, ^bb74
    ^bb73:  // pred: ^bb72
      %412 = builtin.unrealized_conversion_cast %ptr_169 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      %413 = nvvm.mbarrier.wait.parity %412, %410 {kind = #nvvm.mbar_wait<try>} : !llvm.ptr<3>, i32 -> i1
      cf.br ^bb75(%413 : i1)
    ^bb74:  // pred: ^bb72
      cf.br ^bb75(%true : i1)
    ^bb75(%414: i1):  // 2 preds: ^bb73, ^bb74
      cf.br ^bb76
    ^bb76:  // pred: ^bb75
      cf.cond_br %369, ^bb77, ^bb78
    ^bb77:  // pred: ^bb76
      %415 = cute.ptrtoint(%197) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, gmem, align<128>> to i64
      llvm.inline_asm has_side_effects asm_dialect = att "fence.proxy.tensormap::generic.acquire.gpu [$0], 128;", "l" %415 : (i64) -> ()
      %416 = cute.ptrtoint(%199) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, gmem, align<128>> to i64
      llvm.inline_asm has_side_effects asm_dialect = att "fence.proxy.tensormap::generic.acquire.gpu [$0], 128;", "l" %416 : (i64) -> ()
      cf.br ^bb78
    ^bb78:  // 2 preds: ^bb76, ^bb77
      cf.br ^bb79(%c0_i32, %414, %c0_i32, %399, %410 : i32, i1, i32, i32, i32)
    ^bb79(%417: i32, %418: i1, %419: i32, %420: i32, %421: i32):  // 2 preds: ^bb78, ^bb94
      %422 = arith.cmpi slt, %417, %367 : i32
      cf.cond_br %422, ^bb80, ^bb95 {loop_annotation = #loop_annotation1}
    ^bb80:  // pred: ^bb79
      %423 = arith.addi %419, %c1_i32 : i32
      %424 = arith.addi %232, %423 : i32
      %425 = arith.remsi %424, %c6_i32 : i32
      %426 = arith.cmpi eq, %425, %c0_i32 : i32
      %427 = arith.xori %421, %c1_i32 : i32
      %428 = arith.select %426, %427, %421 : i32
      %int_tuple_170 = cute.make_int_tuple(%420) : (i32) -> !cute.int_tuple<"?">
      %ptr_171 = cute.add_offset(%iter_14, %int_tuple_170) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %429 = arith.extui %418 : i1 to i32
      %430 = arith.cmpi eq, %429, %c0_i32 : i32
      cf.cond_br %430, ^bb81, ^bb82
    ^bb81:  // pred: ^bb80
      %ptr_172 = cute.add_offset(%iter_15, %int_tuple_170) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %431 = builtin.unrealized_conversion_cast %ptr_172 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %431, %421, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      cf.br ^bb82
    ^bb82:  // 2 preds: ^bb80, ^bb81
      %432 = nvvm.elect.sync -> i1
      cf.cond_br %432, ^bb83, ^bb84
    ^bb83:  // pred: ^bb82
      %433 = builtin.unrealized_conversion_cast %ptr_171 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %433, %c32768_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
      cf.br ^bb84
    ^bb84:  // 2 preds: ^bb82, ^bb83
      %coord_173 = cute.make_coord(%419) : (i32) -> !cute.coord<"(_,?)">
      %idx_174 = cute.crd2idx(%coord_173, %lay_94) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
      %tup_175 = cute.add_offset(%tup, %idx_174) : (!cute.int_tuple<"(0,?{div=128},0)">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.int_tuple<"(?{div=64},?{div=128},0)">
      %e0_176, %e1_177, %e2_178 = cute.get_leaves(%tup_175) : !cute.int_tuple<"(?{div=64},?{div=128},0)">
      %coord_179 = cute.make_coord(%420) : (i32) -> !cute.coord<"(_,?)">
      %idx_180 = cute.crd2idx(%coord_179, %13) : (!cute.coord<"(_,?)">, !cute.layout<"((8192,1),6):((1,0),8192)">) -> !cute.int_tuple<"?{div=8192}">
      %ptr_181 = cute.add_offset(%iter_25, %idx_180) : (!cute.ptr<f16, smem, align<1024>, S<3,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<f16, smem, align<1024>, S<3,4,3>>
      %int_tuple_182 = cute.make_int_tuple(%e0_176, %e1_177) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=128}">) -> !cute.int_tuple<"(?{div=64},?{div=128},0)">
      %434 = cute_nvgpu.atom.set_value(%218, %ptr_171 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>
      %435 = cute_nvgpu.atom.set_value(%434, %217 : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<128>>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_descriptor_ptr>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>
      %436 = cute_nvgpu.atom.get_value(%435 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
      %TMADescAddr = cute_nvgpu.get_tma_desc_addr(%435 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>) -> !cute.ptr<generic, align<64>>
      %437:3 = cute.get_scalars(%int_tuple_182) : !cute.int_tuple<"(?{div=64},?{div=128},0)">
      cf.br ^bb85(%c0_i32 : i32)
    ^bb85(%438: i32):  // 2 preds: ^bb84, ^bb86
      %439 = arith.cmpi slt, %438, %213 : i32
      cf.cond_br %439, ^bb86, ^bb87 {llvm.loop_annotation = #loop_annotation}
    ^bb86:  // pred: ^bb85
      cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr : !cute.ptr<generic, align<64>>, %ptr_181 : !cute.ptr<f16, smem, align<1024>, S<3,4,3>>, %436 : !cute.ptr<smem, align<8>>, [%437#0, %437#1, %437#2] : i32, i32, i32) mode = <tiled> num_cta = 1 : i32
      %440 = arith.addi %438, %c1_i32 : i32
      cf.br ^bb85(%440 : i32)
    ^bb87:  // pred: ^bb85
      %idx_183 = cute.crd2idx(%coord_173, %lay_96) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
      %tup_184 = cute.add_offset(%tup_163, %idx_183) : (!cute.int_tuple<"(0,?{div=128},0)">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.int_tuple<"(?{div=64},?{div=128},0)">
      %e0_185, %e1_186, %e2_187 = cute.get_leaves(%tup_184) : !cute.int_tuple<"(?{div=64},?{div=128},0)">
      %ptr_188 = cute.add_offset(%iter_26, %idx_180) : (!cute.ptr<f16, smem, align<1024>, S<3,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<f16, smem, align<1024>, S<3,4,3>>
      %int_tuple_189 = cute.make_int_tuple(%e0_185, %e1_186) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=128}">) -> !cute.int_tuple<"(?{div=64},?{div=128},0)">
      %441 = cute_nvgpu.atom.set_value(%221, %ptr_171 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>
      %442 = cute_nvgpu.atom.set_value(%441, %220 : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<128>>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_descriptor_ptr>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>
      %443 = cute_nvgpu.atom.get_value(%442 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
      %TMADescAddr_190 = cute_nvgpu.get_tma_desc_addr(%442 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>) -> !cute.ptr<generic, align<64>>
      %444:3 = cute.get_scalars(%int_tuple_189) : !cute.int_tuple<"(?{div=64},?{div=128},0)">
      cf.br ^bb88(%c0_i32 : i32)
    ^bb88(%445: i32):  // 2 preds: ^bb87, ^bb89
      %446 = arith.cmpi slt, %445, %213 : i32
      cf.cond_br %446, ^bb89, ^bb90 {llvm.loop_annotation = #loop_annotation}
    ^bb89:  // pred: ^bb88
      cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr_190 : !cute.ptr<generic, align<64>>, %ptr_188 : !cute.ptr<f16, smem, align<1024>, S<3,4,3>>, %443 : !cute.ptr<smem, align<8>>, [%444#0, %444#1, %444#2] : i32, i32, i32) mode = <tiled> num_cta = 1 : i32
      %447 = arith.addi %445, %c1_i32 : i32
      cf.br ^bb88(%447 : i32)
    ^bb90:  // pred: ^bb88
      %448 = arith.cmpi sgt, %367, %423 : i32
      %int_tuple_191 = cute.make_int_tuple(%425) : (i32) -> !cute.int_tuple<"?">
      %ptr_192 = cute.add_offset(%iter_15, %int_tuple_191) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      cf.cond_br %448, ^bb91, ^bb92
    ^bb91:  // pred: ^bb90
      %449 = builtin.unrealized_conversion_cast %ptr_192 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      %450 = nvvm.mbarrier.wait.parity %449, %428 {kind = #nvvm.mbar_wait<try>} : !llvm.ptr<3>, i32 -> i1
      cf.br ^bb93(%450 : i1)
    ^bb92:  // pred: ^bb90
      cf.br ^bb93(%true : i1)
    ^bb93(%451: i1):  // 2 preds: ^bb91, ^bb92
      cf.br ^bb94
    ^bb94:  // pred: ^bb93
      %452 = arith.addi %417, %c1_i32 : i32
      cf.br ^bb79(%452, %451, %423, %425, %428 : i32, i1, i32, i32, i32)
    ^bb95:  // pred: ^bb79
      %453 = arith.addi %237, %202 : i32
      %454 = arith.addi %238, %c1_i32 : i32
      %455 = arith.cmpi sgt, %203, %453 : i32
      %456 = cute.get_hier_coord(%453, %lay) : (i32, !cute.layout<"(1,1,?):(0,0,1)">) -> !cute.coord<"(0,0,?)">
      %e0_193, %e1_194, %e2_195 = cute.get_leaves(%456) : !cute.coord<"(0,0,?)">
      %itup_196 = cute.to_int_tuple(%e2_195) : !cute.coord<"?"> to !cute.int_tuple<"?">
      %mul_197 = cute.tuple_mul(%itup_196, %39) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %457 = cute.get_scalars(%mul_197) : !cute.int_tuple<"?">
      cf.br ^bb18(%397, %398, %457, %455, %241, %241, %242, %453, %454 : i1, i32, i32, i1, i32, i32, i32, i32, i32)
    ^bb96:  // pred: ^bb18
      cf.br ^bb97
    ^bb97:  // 2 preds: ^bb16, ^bb96
      cf.cond_br %72, ^bb98, ^bb168
    ^bb98:  // pred: ^bb97
      nvvm.barrier id = %c3_i32 number_of_threads = %c160_i32
      %tmem_ptr = cute_nvgpu.arch.sm100.retrieve_tmem_ptr(%iter) : !cute.ptr<i32, smem, align<8>> -> !cute.ptr<f32, tmem, align<16>>
      %int_tuple_198 = cute.make_int_tuple(%188, %189, %190) : (i32, i32, i32) -> !cute.int_tuple<"(?,?,?)">
      %sz_199 = cute.size(%int_tuple_198) : (!cute.int_tuple<"(?,?,?)">) -> !cute.int_tuple<"?">
      %e0_200 = cute.get_leaves(%sz_199) : !cute.int_tuple<"?">
      %div_201 = cute.tuple_div(%e0_200, %39) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %458 = cute.get_scalars(%div_201) : !cute.int_tuple<"?">
      %sz_202 = cute.size(%lay) : (!cute.layout<"(1,1,?):(0,0,1)">) -> !cute.int_tuple<"?">
      %e0_203 = cute.get_leaves(%sz_202) : !cute.int_tuple<"?">
      %459 = cute.get_scalars(%e0_203) : !cute.int_tuple<"?">
      %460 = arith.cmpi sgt, %459, %64 : i32
      %461 = cute.get_hier_coord(%64, %lay) : (i32, !cute.layout<"(1,1,?):(0,0,1)">) -> !cute.coord<"(0,0,?)">
      %e0_204, %e1_205, %e2_206 = cute.get_leaves(%461) : !cute.coord<"(0,0,?)">
      %itup_207 = cute.to_int_tuple(%e2_206) : !cute.coord<"?"> to !cute.int_tuple<"?">
      %mul_208 = cute.tuple_mul(%itup_207, %39) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %462 = cute.get_scalars(%mul_208) : !cute.int_tuple<"?">
      %463 = nvvm.read.ptx.sreg.laneid range <i32, 0, 32> : i32
      %464 = arith.cmpi sge, %463, %c1_i32 : i32
      %465 = arith.cmpi sge, %463, %c2_i32 : i32
      %466 = arith.cmpi sge, %463, %c4_i32 : i32
      %467 = arith.cmpi sge, %463, %c8_i32 : i32
      %468 = arith.cmpi sge, %463, %c16_i32 : i32
      %iter_209 = cute.get_iter(%arg8) : !memref_gmem_i32_
      %469 = cute.get_scalars(%39) : !cute.int_tuple<"1">
      cf.br ^bb99(%c0_i32, %462, %460, %c0_i32, %c0_i32, %0, %64, %c0_i32 : i32, i32, i1, i32, i32, !llvm.struct<(i1, i1, i1)>, i32, i32)
    ^bb99(%470: i32, %471: i32, %472: i1, %473: i32, %474: i32, %475: !llvm.struct<(i1, i1, i1)>, %476: i32, %477: i32):  // 2 preds: ^bb98, ^bb166
      cf.cond_br %472, ^bb100(%470, %471, %473, %474, %475, %476, %477 : i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>, i32, i32), ^bb167
    ^bb100(%478: i32, %479: i32, %480: i32, %481: i32, %482: !llvm.struct<(i1, i1, i1)>, %483: i32, %484: i32):  // pred: ^bb99
      %485 = builtin.unrealized_conversion_cast %482 : !llvm.struct<(i1, i1, i1)> to !mma_f16_f16_f32_128x128x16_
      %486 = arith.cmpi sge, %479, %481 : i32
      cf.br ^bb101(%486, %480, %481, %481 : i1, i32, i32, i32)
    ^bb101(%487: i1, %488: i32, %489: i32, %490: i32):  // 2 preds: ^bb100, ^bb133
      cf.cond_br %487, ^bb102(%488, %489, %490 : i32, i32, i32), ^bb134
    ^bb102(%491: i32, %492: i32, %493: i32):  // pred: ^bb101
      %494 = arith.addi %491, %463 : i32
      %495 = arith.cmpi slt, %494, %c2_i32 : i32
      cf.cond_br %495, ^bb103, ^bb107
    ^bb103:  // pred: ^bb102
      %rmem_210 = cute.memref.alloca() : !memref_rmem_i32_
      %coord_211 = cute.make_coord(%494) : (i32) -> !cute.coord<"(?,_)">
      %idx_212 = cute.crd2idx(%coord_211, %18) : (!cute.coord<"(?,_)">, !cute.layout<"(2,4):(4,1)">) -> !cute.int_tuple<"?{div=4}">
      %iter_213 = cute.get_iter(%arg8) : !memref_gmem_i32_
      %ptr_214 = cute.add_offset(%iter_213, %idx_212) : (!cute.ptr<i32, gmem, align<16>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<i32, gmem, align<16>>
      %iter_215 = cute.get_iter(%rmem_210) : !memref_rmem_i32_
      %496 = cute.get_scalars(%39) : !cute.int_tuple<"1">
      %497 = builtin.unrealized_conversion_cast %ptr_214 : !cute.ptr<i32, gmem, align<16>> to !llvm.ptr<1>
      %498 = builtin.unrealized_conversion_cast %iter_215 : !cute.ptr<i32, rmem, align<32>> to !llvm.ptr
      cf.br ^bb104(%c0_i32 : i32)
    ^bb104(%499: i32):  // 2 preds: ^bb103, ^bb105
      %500 = arith.cmpi slt, %499, %496 : i32
      cf.cond_br %500, ^bb105, ^bb106 {llvm.loop_annotation = #loop_annotation}
    ^bb105:  // pred: ^bb104
      %501 = llvm.load %497 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<4xi32>
      llvm.store %501, %498 {alignment = 16 : i64} : vector<4xi32>, !llvm.ptr
      %502 = arith.addi %499, %c1_i32 : i32
      cf.br ^bb104(%502 : i32)
    ^bb106:  // pred: ^bb104
      %503 = cute.memref.load(%rmem_210, %19) : (!memref_rmem_i32_, !cute.coord<"0">) -> i32
      %504 = arith.addi %503, %c127_i32 : i32
      %505 = arith.divsi %504, %c128_i32 : i32
      %506 = arith.muli %505, %c128_i32 : i32
      %507 = arith.cmpi ne, %504, %506 : i32
      %c0_i32_216 = arith.constant 0 : i32
      %508 = arith.cmpi slt, %504, %c0_i32_216 : i32
      %509 = arith.cmpi slt, %c128_i32, %c0_i32_216 : i32
      %510 = arith.cmpi ne, %508, %509 : i1
      %511 = arith.andi %507, %510 : i1
      %c-1_i32_217 = arith.constant -1 : i32
      %512 = arith.addi %505, %c-1_i32_217 : i32
      %513 = arith.select %511, %512, %505 : i32
      %514 = cute.memref.load(%rmem_210, %17) : (!memref_rmem_i32_, !cute.coord<"1">) -> i32
      %515 = arith.addi %514, %c127_i32 : i32
      %516 = arith.divsi %515, %c128_i32 : i32
      %517 = arith.muli %516, %c128_i32 : i32
      %518 = arith.cmpi ne, %515, %517 : i32
      %c0_i32_218 = arith.constant 0 : i32
      %519 = arith.cmpi slt, %515, %c0_i32_218 : i32
      %520 = arith.cmpi slt, %c128_i32, %c0_i32_218 : i32
      %521 = arith.cmpi ne, %519, %520 : i1
      %522 = arith.andi %518, %521 : i1
      %c-1_i32_219 = arith.constant -1 : i32
      %523 = arith.addi %516, %c-1_i32_219 : i32
      %524 = arith.select %522, %523, %516 : i32
      %525 = arith.muli %513, %524 : i32
      cf.br ^bb108(%525 : i32)
    ^bb107:  // pred: ^bb102
      cf.br ^bb108(%c0_i32 : i32)
    ^bb108(%526: i32):  // 2 preds: ^bb106, ^bb107
      cf.br ^bb109
    ^bb109:  // pred: ^bb108
      %527 = nvvm.shfl.sync  up %c-1_i32, %526, %c1_i32, %c0_i32 : i32 -> i32
      cf.cond_br %464, ^bb110, ^bb111
    ^bb110:  // pred: ^bb109
      %528 = arith.addi %526, %527 : i32
      cf.br ^bb112(%528 : i32)
    ^bb111:  // pred: ^bb109
      cf.br ^bb112(%526 : i32)
    ^bb112(%529: i32):  // 2 preds: ^bb110, ^bb111
      cf.br ^bb113
    ^bb113:  // pred: ^bb112
      %530 = nvvm.shfl.sync  up %c-1_i32, %529, %c2_i32, %c0_i32 : i32 -> i32
      cf.cond_br %465, ^bb114, ^bb115
    ^bb114:  // pred: ^bb113
      %531 = arith.addi %529, %530 : i32
      cf.br ^bb116(%531 : i32)
    ^bb115:  // pred: ^bb113
      cf.br ^bb116(%529 : i32)
    ^bb116(%532: i32):  // 2 preds: ^bb114, ^bb115
      cf.br ^bb117
    ^bb117:  // pred: ^bb116
      %533 = nvvm.shfl.sync  up %c-1_i32, %532, %c4_i32, %c0_i32 : i32 -> i32
      cf.cond_br %466, ^bb118, ^bb119
    ^bb118:  // pred: ^bb117
      %534 = arith.addi %532, %533 : i32
      cf.br ^bb120(%534 : i32)
    ^bb119:  // pred: ^bb117
      cf.br ^bb120(%532 : i32)
    ^bb120(%535: i32):  // 2 preds: ^bb118, ^bb119
      cf.br ^bb121
    ^bb121:  // pred: ^bb120
      %536 = nvvm.shfl.sync  up %c-1_i32, %535, %c8_i32, %c0_i32 : i32 -> i32
      cf.cond_br %467, ^bb122, ^bb123
    ^bb122:  // pred: ^bb121
      %537 = arith.addi %535, %536 : i32
      cf.br ^bb124(%537 : i32)
    ^bb123:  // pred: ^bb121
      cf.br ^bb124(%535 : i32)
    ^bb124(%538: i32):  // 2 preds: ^bb122, ^bb123
      cf.br ^bb125
    ^bb125:  // pred: ^bb124
      %539 = nvvm.shfl.sync  up %c-1_i32, %538, %c16_i32, %c0_i32 : i32 -> i32
      cf.cond_br %468, ^bb126, ^bb127
    ^bb126:  // pred: ^bb125
      %540 = arith.addi %538, %539 : i32
      cf.br ^bb128(%540 : i32)
    ^bb127:  // pred: ^bb125
      cf.br ^bb128(%538 : i32)
    ^bb128(%541: i32):  // 2 preds: ^bb126, ^bb127
      cf.br ^bb129
    ^bb129:  // pred: ^bb128
      %542 = arith.addi %541, %493 : i32
      %543 = arith.cmpi sge, %479, %542 : i32
      %544 = nvvm.vote.ballot.sync %c-1_i32, %543 : i32
      %545 = llvm.intr.ctpop(%544) : (i32) -> i32
      %546 = arith.cmpi eq, %545, %c32_i32 : i32
      %547 = arith.addi %545, %491 : i32
      %548 = arith.cmpi eq, %545, %c0_i32 : i32
      %549 = arith.cmpi eq, %548, %false : i1
      cf.cond_br %549, ^bb130, ^bb131
    ^bb130:  // pred: ^bb129
      %550 = arith.subi %545, %c1_i32 : i32
      %551 = nvvm.shfl.sync  idx %c-1_i32, %542, %550, %c31_i32 : i32 -> i32
      cf.br ^bb132(%551 : i32)
    ^bb131:  // pred: ^bb129
      cf.br ^bb132(%493 : i32)
    ^bb132(%552: i32):  // 2 preds: ^bb130, ^bb131
      cf.br ^bb133
    ^bb133:  // pred: ^bb132
      %553 = arith.select %546, %c31_i32, %545 : i32
      %554 = nvvm.shfl.sync  idx %c-1_i32, %542, %553, %c31_i32 : i32 -> i32
      cf.br ^bb101(%546, %547, %552, %554 : i1, i32, i32, i32)
    ^bb134:  // pred: ^bb101
      %rmem_220 = cute.memref.alloca() : !memref_rmem_i32_
      %coord_221 = cute.make_coord(%488) : (i32) -> !cute.coord<"(?,_)">
      %idx_222 = cute.crd2idx(%coord_221, %18) : (!cute.coord<"(?,_)">, !cute.layout<"(2,4):(4,1)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_223 = cute.add_offset(%iter_209, %idx_222) : (!cute.ptr<i32, gmem, align<16>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<i32, gmem, align<16>>
      %iter_224 = cute.get_iter(%rmem_220) : !memref_rmem_i32_
      %555 = builtin.unrealized_conversion_cast %ptr_223 : !cute.ptr<i32, gmem, align<16>> to !llvm.ptr<1>
      %556 = builtin.unrealized_conversion_cast %iter_224 : !cute.ptr<i32, rmem, align<32>> to !llvm.ptr
      cf.br ^bb135(%c0_i32 : i32)
    ^bb135(%557: i32):  // 2 preds: ^bb134, ^bb136
      %558 = arith.cmpi slt, %557, %469 : i32
      cf.cond_br %558, ^bb136, ^bb137 {llvm.loop_annotation = #loop_annotation}
    ^bb136:  // pred: ^bb135
      %559 = llvm.load %555 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<4xi32>
      llvm.store %559, %556 {alignment = 16 : i64} : vector<4xi32>, !llvm.ptr
      %560 = arith.addi %557, %c1_i32 : i32
      cf.br ^bb135(%560 : i32)
    ^bb137:  // pred: ^bb135
      %561 = cute.memref.load(%rmem_220, %16) : (!memref_rmem_i32_, !cute.coord<"2">) -> i32
      %562 = arith.addi %561, %c63_i32 : i32
      %563 = arith.divsi %562, %c64_i32 : i32
      %564 = arith.muli %563, %c64_i32 : i32
      %565 = arith.cmpi ne, %562, %564 : i32
      %c0_i32_225 = arith.constant 0 : i32
      %566 = arith.cmpi slt, %562, %c0_i32_225 : i32
      %567 = arith.cmpi slt, %c64_i32, %c0_i32_225 : i32
      %568 = arith.cmpi ne, %566, %567 : i1
      %569 = arith.andi %565, %568 : i1
      %c-1_i32_226 = arith.constant -1 : i32
      %570 = arith.addi %563, %c-1_i32_226 : i32
      %571 = arith.select %569, %570, %563 : i32
      %572 = arith.remsi %484, %c2_i32 : i32
      %coord_227 = cute.make_coord(%572) : (i32) -> !cute.coord<"(_,_,_,?)">
      %idx_228 = cute.crd2idx(%coord_227, %12) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((128,128),1,1,2):((65536,1),0,0,128)">) -> !cute.int_tuple<"?{div=128}">
      %ptr_229 = cute.add_offset(%tmem_ptr, %idx_228) : (!cute.ptr<f32, tmem, align<16>>, !cute.int_tuple<"?{div=128}">) -> !cute.ptr<f32, tmem, align<16>>
      %573 = arith.addi %478, %571 : i32
      %574 = arith.remsi %478, %c6_i32 : i32
      %575 = arith.cmpi sgt, %571, %c0_i32 : i32
      %576 = arith.extui %575 : i1 to i32
      %577 = arith.select %575, %c1_i32, %576 : i32
      %578 = arith.cmpi ne, %577, %c0_i32 : i32
      %579 = arith.divsi %478, %c6_i32 : i32
      %580 = arith.muli %579, %c6_i32 : i32
      %581 = arith.cmpi ne, %478, %580 : i32
      %c0_i32_230 = arith.constant 0 : i32
      %582 = arith.cmpi slt, %478, %c0_i32_230 : i32
      %583 = arith.cmpi slt, %c6_i32, %c0_i32_230 : i32
      %584 = arith.cmpi ne, %582, %583 : i1
      %585 = arith.andi %581, %584 : i1
      %c-1_i32_231 = arith.constant -1 : i32
      %586 = arith.addi %579, %c-1_i32_231 : i32
      %587 = arith.select %585, %586, %579 : i32
      %588 = arith.remsi %587, %c2_i32 : i32
      %int_tuple_232 = cute.make_int_tuple(%574) : (i32) -> !cute.int_tuple<"?">
      %ptr_233 = cute.add_offset(%iter_14, %int_tuple_232) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      cf.cond_br %578, ^bb138, ^bb139
    ^bb138:  // pred: ^bb137
      %589 = builtin.unrealized_conversion_cast %ptr_233 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      %590 = nvvm.mbarrier.wait.parity %589, %588 {kind = #nvvm.mbar_wait<try>} : !llvm.ptr<3>, i32 -> i1
      cf.br ^bb140(%590 : i1)
    ^bb139:  // pred: ^bb137
      cf.br ^bb140(%true : i1)
    ^bb140(%591: i1):  // 2 preds: ^bb138, ^bb139
      cf.br ^bb141
    ^bb141:  // pred: ^bb140
      %592 = arith.divsi %484, %c2_i32 : i32
      %593 = arith.muli %592, %c2_i32 : i32
      %594 = arith.cmpi ne, %484, %593 : i32
      %c0_i32_234 = arith.constant 0 : i32
      %595 = arith.cmpi slt, %484, %c0_i32_234 : i32
      %596 = arith.cmpi slt, %c2_i32, %c0_i32_234 : i32
      %597 = arith.cmpi ne, %595, %596 : i1
      %598 = arith.andi %594, %597 : i1
      %c-1_i32_235 = arith.constant -1 : i32
      %599 = arith.addi %592, %c-1_i32_235 : i32
      %600 = arith.select %598, %599, %592 : i32
      %601 = arith.remsi %600, %c2_i32 : i32
      %602 = arith.xori %601, %c1_i32 : i32
      %int_tuple_236 = cute.make_int_tuple(%572) : (i32) -> !cute.int_tuple<"?">
      %ptr_237 = cute.add_offset(%iter_17, %int_tuple_236) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %603 = builtin.unrealized_conversion_cast %ptr_237 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %603, %602, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %604 = cute_nvgpu.atom.set_value(%485, %false : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_f16_f16_f32_128x128x16_
      %605 = builtin.unrealized_conversion_cast %604 : !mma_f16_f16_f32_128x128x16_ to !llvm.struct<(i1, i1, i1)>
      %606 = arith.addi %478, %c1_i32 : i32
      %607 = arith.remsi %606, %c6_i32 : i32
      cf.br ^bb142(%c0_i32, %591, %574, %588, %605, %607 : i32, i1, i32, i32, !llvm.struct<(i1, i1, i1)>, i32)
    ^bb142(%608: i32, %609: i1, %610: i32, %611: i32, %612: !llvm.struct<(i1, i1, i1)>, %613: i32):  // 2 preds: ^bb141, ^bb163
      %614 = arith.cmpi slt, %608, %571 : i32
      cf.cond_br %614, ^bb143, ^bb164
    ^bb143:  // pred: ^bb142
      %615 = arith.addi %608, %c1_i32 : i32
      %616 = arith.cmpi eq, %613, %c0_i32 : i32
      %617 = arith.xori %611, %c1_i32 : i32
      %618 = arith.select %616, %617, %611 : i32
      %619 = arith.extui %609 : i1 to i32
      %620 = arith.cmpi eq, %619, %c0_i32 : i32
      cf.cond_br %620, ^bb144, ^bb145
    ^bb144:  // pred: ^bb143
      %int_tuple_238 = cute.make_int_tuple(%610) : (i32) -> !cute.int_tuple<"?">
      %ptr_239 = cute.add_offset(%iter_14, %int_tuple_238) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %621 = builtin.unrealized_conversion_cast %ptr_239 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %621, %611, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      cf.br ^bb145
    ^bb145:  // 2 preds: ^bb143, ^bb144
      cf.br ^bb146(%c0_i32, %612 : i32, !llvm.struct<(i1, i1, i1)>)
    ^bb146(%622: i32, %623: !llvm.struct<(i1, i1, i1)>):  // 2 preds: ^bb145, ^bb156
      %624 = arith.cmpi slt, %622, %c4_i32 : i32
      cf.cond_br %624, ^bb147, ^bb157 {loop_annotation = #loop_annotation2}
    ^bb147:  // pred: ^bb146
      %625 = builtin.unrealized_conversion_cast %623 : !llvm.struct<(i1, i1, i1)> to !mma_f16_f16_f32_128x128x16_
      %coord_240 = cute.make_coord(%622, %610) : (i32, i32) -> !cute.coord<"(_,_,?,?)">
      %idx_241 = cute.crd2idx(%coord_240, %11) : (!cute.coord<"(_,_,?,?)">, !cute.layout<"(1,1,4,6):(0,0,2,1024)">) -> !cute.int_tuple<"?{div=2}">
      %tup_242 = cute.add_offset(%ummaSmemDesc, %idx_241) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
      %tup_243 = cute.add_offset(%ummaSmemDesc_74, %idx_241) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
      %626 = cute_nvgpu.atom.get_value(%625 : !mma_f16_f16_f32_128x128x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : i1
      %627 = cute_nvgpu.atom.get_value(%625 : !mma_f16_f16_f32_128x128x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : i1
      %628 = cute_nvgpu.atom.get_value(%625 : !mma_f16_f16_f32_128x128x16_) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : i1
      %629 = arith.extui %626 : i1 to i32
      %630 = arith.extui %627 : i1 to i32
      %631 = arith.shli %629, %c13_i32 : i32
      %632 = arith.shli %630, %c14_i32 : i32
      %633 = arith.ori %631, %c136314896_i32 : i32
      %634 = arith.ori %633, %632 : i32
      cf.br ^bb148(%c0_i32 : i32)
    ^bb148(%635: i32):  // 2 preds: ^bb147, ^bb155
      %636 = arith.cmpi slt, %635, %469 : i32
      cf.cond_br %636, ^bb149, ^bb156 {llvm.loop_annotation = #loop_annotation}
    ^bb149:  // pred: ^bb148
      cf.br ^bb150(%c0_i32 : i32)
    ^bb150(%637: i32):  // 2 preds: ^bb149, ^bb154
      %638 = arith.cmpi slt, %637, %469 : i32
      cf.cond_br %638, ^bb151, ^bb155 {llvm.loop_annotation = #loop_annotation}
    ^bb151:  // pred: ^bb150
      cf.br ^bb152(%c0_i32 : i32)
    ^bb152(%639: i32):  // 2 preds: ^bb151, ^bb153
      %640 = arith.cmpi slt, %639, %469 : i32
      cf.cond_br %640, ^bb153, ^bb154 {llvm.loop_annotation = #loop_annotation}
    ^bb153:  // pred: ^bb152
      cute_nvgpu.arch.mma.SM100.umma(%tup_242, %tup_243, %ptr_229, %634, %628) {num_cta = 1 : i32, scale = 0 : i32, a_type = f16} : (!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, !cute.ptr<f32, tmem, align<16>>, i32, i1) -> ()
      %641 = arith.addi %639, %c1_i32 : i32
      cf.br ^bb152(%641 : i32)
    ^bb154:  // pred: ^bb152
      %642 = arith.addi %637, %c1_i32 : i32
      cf.br ^bb150(%642 : i32)
    ^bb155:  // pred: ^bb150
      %643 = arith.addi %635, %c1_i32 : i32
      cf.br ^bb148(%643 : i32)
    ^bb156:  // pred: ^bb148
      %644 = cute_nvgpu.atom.set_value(%625, %true : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_f16_f16_f32_128x128x16_
      %645 = builtin.unrealized_conversion_cast %644 : !mma_f16_f16_f32_128x128x16_ to !llvm.struct<(i1, i1, i1)>
      %646 = arith.addi %622, %c1_i32 : i32
      cf.br ^bb146(%646, %645 : i32, !llvm.struct<(i1, i1, i1)>)
    ^bb157:  // pred: ^bb146
      %647 = nvvm.elect.sync -> i1
      cf.cond_br %647, ^bb158, ^bb159
    ^bb158:  // pred: ^bb157
      %int_tuple_244 = cute.make_int_tuple(%610) : (i32) -> !cute.int_tuple<"?">
      %ptr_245 = cute.add_offset(%iter_15, %int_tuple_244) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %648 = builtin.unrealized_conversion_cast %ptr_245 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.tcgen05.commit.arrive %648 : !llvm.ptr<3>
      cf.br ^bb159
    ^bb159:  // 2 preds: ^bb157, ^bb158
      %649 = arith.cmpi slt, %615, %571 : i32
      %650 = arith.extui %649 : i1 to i32
      %651 = arith.select %649, %c1_i32, %650 : i32
      %652 = arith.cmpi ne, %651, %c0_i32 : i32
      %int_tuple_246 = cute.make_int_tuple(%613) : (i32) -> !cute.int_tuple<"?">
      %ptr_247 = cute.add_offset(%iter_14, %int_tuple_246) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      cf.cond_br %652, ^bb160, ^bb161
    ^bb160:  // pred: ^bb159
      %653 = builtin.unrealized_conversion_cast %ptr_247 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      %654 = nvvm.mbarrier.wait.parity %653, %618 {kind = #nvvm.mbar_wait<try>} : !llvm.ptr<3>, i32 -> i1
      cf.br ^bb162(%654 : i1)
    ^bb161:  // pred: ^bb159
      cf.br ^bb162(%true : i1)
    ^bb162(%655: i1):  // 2 preds: ^bb160, ^bb161
      cf.br ^bb163
    ^bb163:  // pred: ^bb162
      %656 = arith.addi %613, %c1_i32 : i32
      %657 = arith.cmpi eq, %656, %c6_i32 : i32
      %658 = arith.select %657, %c0_i32, %656 : i32
      %659 = arith.addi %608, %c1_i32 : i32
      cf.br ^bb142(%659, %655, %613, %618, %623, %658 : i32, i1, i32, i32, !llvm.struct<(i1, i1, i1)>, i32)
    ^bb164:  // pred: ^bb142
      %660 = nvvm.elect.sync -> i1
      cf.cond_br %660, ^bb165, ^bb166
    ^bb165:  // pred: ^bb164
      %ptr_248 = cute.add_offset(%iter_16, %int_tuple_236) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %661 = builtin.unrealized_conversion_cast %ptr_248 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.tcgen05.commit.arrive %661 : !llvm.ptr<3>
      cf.br ^bb166
    ^bb166:  // 2 preds: ^bb164, ^bb165
      %662 = arith.addi %483, %458 : i32
      %663 = arith.addi %484, %c1_i32 : i32
      %664 = arith.cmpi sgt, %459, %662 : i32
      %665 = cute.get_hier_coord(%662, %lay) : (i32, !cute.layout<"(1,1,?):(0,0,1)">) -> !cute.coord<"(0,0,?)">
      %e0_249, %e1_250, %e2_251 = cute.get_leaves(%665) : !cute.coord<"(0,0,?)">
      %itup_252 = cute.to_int_tuple(%e2_251) : !cute.coord<"?"> to !cute.int_tuple<"?">
      %mul_253 = cute.tuple_mul(%itup_252, %39) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %666 = cute.get_scalars(%mul_253) : !cute.int_tuple<"?">
      cf.br ^bb99(%573, %666, %664, %488, %489, %612, %662, %663 : i32, i32, i1, i32, i32, !llvm.struct<(i1, i1, i1)>, i32, i32)
    ^bb167:  // pred: ^bb99
      cf.br ^bb168
    ^bb168:  // 2 preds: ^bb97, ^bb167
      %667 = arith.cmpi slt, %60, %c4_i32 : i32
      cf.cond_br %667, ^bb169, ^bb259
    ^bb169:  // pred: ^bb168
      cf.cond_br %65, ^bb170, ^bb173
    ^bb170:  // pred: ^bb169
      %668 = nvvm.elect.sync -> i1
      cf.cond_br %668, ^bb171, ^bb172
    ^bb171:  // pred: ^bb170
      cute_nvgpu.copy_tma_desc(%arg1, %iter_10) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>, !cute.ptr<i64, smem, align<1024>>) -> ()
      cf.br ^bb172
    ^bb172:  // 2 preds: ^bb170, ^bb171
      cf.br ^bb173
    ^bb173:  // 2 preds: ^bb169, ^bb172
      nvvm.bar.warp.sync %c-1_i32 : i32
      cf.cond_br %65, ^bb174, ^bb177
    ^bb174:  // pred: ^bb173
      %669 = nvvm.elect.sync -> i1
      cf.cond_br %669, ^bb175, ^bb176
    ^bb175:  // pred: ^bb174
      cute_nvgpu.copy_tma_desc(%arg3, %ptr_11) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>, !cute.ptr<i64, smem, align<128>>) -> ()
      cf.br ^bb176
    ^bb176:  // 2 preds: ^bb174, ^bb175
      cf.br ^bb177
    ^bb177:  // 2 preds: ^bb173, ^bb176
      nvvm.bar.warp.sync %c-1_i32 : i32
      nvvm.barrier id = %c4_i32 number_of_threads = %c160_i32
      cf.cond_br %65, ^bb178, ^bb181
    ^bb178:  // pred: ^bb177
      %670 = nvvm.elect.sync -> i1
      cf.cond_br %670, ^bb179, ^bb180
    ^bb179:  // pred: ^bb178
      cute_nvgpu.copy_tma_desc(%arg5, %dyn) : (!cute_nvgpu.atom.non_exec_tiled_tma_store<f16, copy_bits = 65536, tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>, !cute.ptr<i64, smem, align<128>>) -> ()
      cf.br ^bb180
    ^bb180:  // 2 preds: ^bb178, ^bb179
      cf.br ^bb181
    ^bb181:  // 2 preds: ^bb177, ^bb180
      nvvm.bar.warp.sync %c-1_i32 : i32
      cf.cond_br %65, ^bb182, ^bb183
    ^bb182:  // pred: ^bb181
      cute_nvgpu.arch.sm100.alloc_tmem(%c256_i32, %iter) [ cta_1] : i32, !cute.ptr<i32, smem, align<8>>
      cf.br ^bb183
    ^bb183:  // 2 preds: ^bb181, ^bb182
      nvvm.barrier id = %c3_i32 number_of_threads = %c160_i32
      %tmem_ptr_254 = cute_nvgpu.arch.sm100.retrieve_tmem_ptr(%iter) : !cute.ptr<i32, smem, align<8>> -> !cute.ptr<f32, tmem, align<16>>
      %coord_255 = cute.make_coord(%41) : (i32) -> !cute.coord<"?">
      %671 = cute.get_scalars(%coord_255) <{only_dynamic}> : !cute.coord<"?">
      %672 = arith.divsi %671, %c32_i32 : i32
      %673 = arith.muli %672, %c2097152_i32 : i32
      %iv_256 = cute.assume(%673) : (i32) -> !cute.i32<divby 2097152>
      %int_tuple_257 = cute.make_int_tuple(%iv_256) : (!cute.i32<divby 2097152>) -> !cute.int_tuple<"?{div=2097152}">
      %ptr_258 = cute.add_offset(%tmem_ptr_254, %int_tuple_257) : (!cute.ptr<f32, tmem, align<16>>, !cute.int_tuple<"?{div=2097152}">) -> !cute.ptr<f32, tmem, align<16>>
      %rmem_259 = cute.memref.alloca() : !memref_rmem_f32_
      %iter_260 = cute.get_iter(%rmem_259) : !memref_rmem_f32_
      %rmem_261 = cute.memref.alloca() : !memref_rmem_f16_
      %atom = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<f16>
      %674 = cute.make_tiled_copy(%atom) : !copy_simt
      %675 = arith.remsi %671, %c32_i32 : i32
      %676 = arith.muli %675, %c32_i32 : i32
      %677 = arith.muli %672, %c1024_i32 : i32
      %678 = arith.addi %676, %677 : i32
      %iv_262 = cute.assume(%678) : (i32) -> !cute.i32<divby 32>
      %int_tuple_263 = cute.make_int_tuple(%iv_262) : (!cute.i32<divby 32>) -> !cute.int_tuple<"?{div=32}">
      %ptr_264 = cute.add_offset(%iter_24, %int_tuple_263) : (!cute.ptr<f16, smem, align<1024>, S<2,4,3>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f16, smem, align<64>, S<2,4,3>>
      %iter_265 = cute.get_iter(%rmem_261) : !memref_rmem_f16_
      %view_266 = cute.make_view(%iter_265) : !memref_rmem_f16_1
      %679:3 = cute.get_scalars(%lay_65) <{only_dynamic}> : !cute.layout<"((128,128),1,1,?,?,?):((1@1,1@0),0,0,128@1,128@0,1@2)">
      %shape_267 = cute.make_shape(%679#0, %679#1, %679#2) : (i32, i32, i32) -> !cute.shape<"(128,128,?,?,?)">
      %lay_268 = cute.make_layout(%shape_267, %25) : !cute.layout<"(128,128,?,?,?):(1@1,1@0,128@1,128@0,1@2)">
      %680:3 = cute.get_scalars(%lay_268) <{only_dynamic}> : !cute.layout<"(128,128,?,?,?):(1@1,1@0,128@1,128@0,1@2)">
      %shape_269 = cute.make_shape(%680#0, %680#1, %680#2) : (i32, i32, i32) -> !cute.shape<"(128,32,1,4,?,?,?)">
      %lay_270 = cute.make_layout(%shape_269, %10) : !cute.layout<"(128,32,1,4,?,?,?):(1@1,1@0,0,32@0,128@1,128@0,1@2)">
      %681:3 = cute.get_scalars(%lay_270) <{only_dynamic}> : !cute.layout<"(128,32,1,4,?,?,?):(1@1,1@0,0,32@0,128@1,128@0,1@2)">
      %shape_271 = cute.make_shape(%681#0, %681#1, %681#2) : (i32, i32, i32) -> !cute.shape<"((128,32),1,4,?,?,?)">
      %lay_272 = cute.make_layout(%shape_271, %9) : !cute.layout<"((128,32),1,4,?,?,?):((1@1,1@0),0,32@0,128@1,128@0,1@2)">
      %682:3 = cute.get_scalars(%lay_272) <{only_dynamic}> : !cute.layout<"((128,32),1,4,?,?,?):((1@1,1@0),0,32@0,128@1,128@0,1@2)">
      %shape_273 = cute.make_shape(%682#0, %682#1, %682#2) : (i32, i32, i32) -> !cute.shape<"(((32,128),1),1,4,?,?,?)">
      %lay_274 = cute.make_layout(%shape_273, %8) : !cute.layout<"(((32,128),1),1,4,?,?,?):(((1@0,1@1),0),0,32@0,128@1,128@0,1@2)">
      %int_tuple_275 = cute.make_int_tuple(%188, %189, %190) : (i32, i32, i32) -> !cute.int_tuple<"(?,?,?)">
      %sz_276 = cute.size(%int_tuple_275) : (!cute.int_tuple<"(?,?,?)">) -> !cute.int_tuple<"?">
      %e0_277 = cute.get_leaves(%sz_276) : !cute.int_tuple<"?">
      %div_278 = cute.tuple_div(%e0_277, %39) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %683 = cute.get_scalars(%div_278) : !cute.int_tuple<"?">
      %sz_279 = cute.size(%lay) : (!cute.layout<"(1,1,?):(0,0,1)">) -> !cute.int_tuple<"?">
      %e0_280 = cute.get_leaves(%sz_279) : !cute.int_tuple<"?">
      %684 = cute.get_scalars(%e0_280) : !cute.int_tuple<"?">
      %685 = arith.cmpi sgt, %684, %64 : i32
      %686 = cute.get_hier_coord(%64, %lay) : (i32, !cute.layout<"(1,1,?):(0,0,1)">) -> !cute.coord<"(0,0,?)">
      %e0_281, %e1_282, %e2_283 = cute.get_leaves(%686) : !cute.coord<"(0,0,?)">
      %itup_284 = cute.to_int_tuple(%e2_283) : !cute.coord<"?"> to !cute.int_tuple<"?">
      %mul_285 = cute.tuple_mul(%itup_284, %39) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %687 = cute.get_scalars(%mul_285) : !cute.int_tuple<"?">
      %688 = nvvm.read.ptx.sreg.laneid range <i32, 0, 32> : i32
      %689 = arith.cmpi sge, %688, %c1_i32 : i32
      %690 = arith.cmpi sge, %688, %c2_i32 : i32
      %691 = arith.cmpi sge, %688, %c4_i32 : i32
      %692 = arith.cmpi sge, %688, %c8_i32 : i32
      %693 = arith.cmpi sge, %688, %c16_i32 : i32
      %iter_286 = cute.get_iter(%arg8) : !memref_gmem_i32_
      %694 = cute.get_scalars(%39) : !cute.int_tuple<"1">
      %695 = builtin.unrealized_conversion_cast %iter_260 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
      %view_287 = cute.make_view(%iter_260) : !memref_rmem_f32_1
      %swizzled = cute.apply_swizzle(%ptr_264) : !cute.ptr<f16, smem, align<64>, S<2,4,3>>
      %696 = builtin.unrealized_conversion_cast %iter_265 : !cute.ptr<f16, rmem, align<32>> to !llvm.ptr
      %ptr_288 = cute.add_offset(%iter_265, %4) : (!cute.ptr<f16, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<f16, rmem, align<16>>
      %ptr_289 = cute.add_offset(%ptr_264, %4) : (!cute.ptr<f16, smem, align<64>, S<2,4,3>>, !cute.int_tuple<"8">) -> !cute.ptr<f16, smem, align<16>, S<2,4,3>>
      %swizzled_290 = cute.apply_swizzle(%ptr_289) : !cute.ptr<f16, smem, align<16>, S<2,4,3>>
      %697 = builtin.unrealized_conversion_cast %ptr_288 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
      %ptr_291 = cute.add_offset(%iter_265, %30) : (!cute.ptr<f16, rmem, align<32>>, !cute.int_tuple<"16">) -> !cute.ptr<f16, rmem, align<32>>
      %ptr_292 = cute.add_offset(%ptr_264, %30) : (!cute.ptr<f16, smem, align<64>, S<2,4,3>>, !cute.int_tuple<"16">) -> !cute.ptr<f16, smem, align<32>, S<2,4,3>>
      %swizzled_293 = cute.apply_swizzle(%ptr_292) : !cute.ptr<f16, smem, align<32>, S<2,4,3>>
      %698 = builtin.unrealized_conversion_cast %ptr_291 : !cute.ptr<f16, rmem, align<32>> to !llvm.ptr
      %ptr_294 = cute.add_offset(%iter_265, %3) : (!cute.ptr<f16, rmem, align<32>>, !cute.int_tuple<"24">) -> !cute.ptr<f16, rmem, align<16>>
      %ptr_295 = cute.add_offset(%ptr_264, %3) : (!cute.ptr<f16, smem, align<64>, S<2,4,3>>, !cute.int_tuple<"24">) -> !cute.ptr<f16, smem, align<16>, S<2,4,3>>
      %swizzled_296 = cute.apply_swizzle(%ptr_295) : !cute.ptr<f16, smem, align<16>, S<2,4,3>>
      %699 = builtin.unrealized_conversion_cast %ptr_294 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
      cf.br ^bb184(%c0_i32, %687, %685, %c-1_i32, %c0_i32, %c0_i32, %64, %c0_i32 : i32, i32, i1, i32, i32, i32, i32, i32)
    ^bb184(%700: i32, %701: i32, %702: i1, %703: i32, %704: i32, %705: i32, %706: i32, %707: i32):  // 2 preds: ^bb183, ^bb251
      cf.cond_br %702, ^bb185(%700, %701, %703, %704, %705, %706, %707 : i32, i32, i32, i32, i32, i32, i32), ^bb252
    ^bb185(%708: i32, %709: i32, %710: i32, %711: i32, %712: i32, %713: i32, %714: i32):  // pred: ^bb184
      %715 = arith.cmpi sge, %709, %712 : i32
      cf.br ^bb186(%715, %711, %712, %712 : i1, i32, i32, i32)
    ^bb186(%716: i1, %717: i32, %718: i32, %719: i32):  // 2 preds: ^bb185, ^bb218
      cf.cond_br %716, ^bb187(%717, %718, %719 : i32, i32, i32), ^bb219
    ^bb187(%720: i32, %721: i32, %722: i32):  // pred: ^bb186
      %723 = arith.addi %720, %688 : i32
      %724 = arith.cmpi slt, %723, %c2_i32 : i32
      cf.cond_br %724, ^bb188, ^bb192
    ^bb188:  // pred: ^bb187
      %rmem_297 = cute.memref.alloca() : !memref_rmem_i32_
      %coord_298 = cute.make_coord(%723) : (i32) -> !cute.coord<"(?,_)">
      %idx_299 = cute.crd2idx(%coord_298, %18) : (!cute.coord<"(?,_)">, !cute.layout<"(2,4):(4,1)">) -> !cute.int_tuple<"?{div=4}">
      %iter_300 = cute.get_iter(%arg8) : !memref_gmem_i32_
      %ptr_301 = cute.add_offset(%iter_300, %idx_299) : (!cute.ptr<i32, gmem, align<16>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<i32, gmem, align<16>>
      %iter_302 = cute.get_iter(%rmem_297) : !memref_rmem_i32_
      %725 = cute.get_scalars(%39) : !cute.int_tuple<"1">
      %726 = builtin.unrealized_conversion_cast %ptr_301 : !cute.ptr<i32, gmem, align<16>> to !llvm.ptr<1>
      %727 = builtin.unrealized_conversion_cast %iter_302 : !cute.ptr<i32, rmem, align<32>> to !llvm.ptr
      cf.br ^bb189(%c0_i32 : i32)
    ^bb189(%728: i32):  // 2 preds: ^bb188, ^bb190
      %729 = arith.cmpi slt, %728, %725 : i32
      cf.cond_br %729, ^bb190, ^bb191 {llvm.loop_annotation = #loop_annotation}
    ^bb190:  // pred: ^bb189
      %730 = llvm.load %726 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<4xi32>
      llvm.store %730, %727 {alignment = 16 : i64} : vector<4xi32>, !llvm.ptr
      %731 = arith.addi %728, %c1_i32 : i32
      cf.br ^bb189(%731 : i32)
    ^bb191:  // pred: ^bb189
      %732 = cute.memref.load(%rmem_297, %19) : (!memref_rmem_i32_, !cute.coord<"0">) -> i32
      %733 = arith.addi %732, %c127_i32 : i32
      %734 = arith.divsi %733, %c128_i32 : i32
      %735 = arith.muli %734, %c128_i32 : i32
      %736 = arith.cmpi ne, %733, %735 : i32
      %c0_i32_303 = arith.constant 0 : i32
      %737 = arith.cmpi slt, %733, %c0_i32_303 : i32
      %738 = arith.cmpi slt, %c128_i32, %c0_i32_303 : i32
      %739 = arith.cmpi ne, %737, %738 : i1
      %740 = arith.andi %736, %739 : i1
      %c-1_i32_304 = arith.constant -1 : i32
      %741 = arith.addi %734, %c-1_i32_304 : i32
      %742 = arith.select %740, %741, %734 : i32
      %743 = cute.memref.load(%rmem_297, %17) : (!memref_rmem_i32_, !cute.coord<"1">) -> i32
      %744 = arith.addi %743, %c127_i32 : i32
      %745 = arith.divsi %744, %c128_i32 : i32
      %746 = arith.muli %745, %c128_i32 : i32
      %747 = arith.cmpi ne, %744, %746 : i32
      %c0_i32_305 = arith.constant 0 : i32
      %748 = arith.cmpi slt, %744, %c0_i32_305 : i32
      %749 = arith.cmpi slt, %c128_i32, %c0_i32_305 : i32
      %750 = arith.cmpi ne, %748, %749 : i1
      %751 = arith.andi %747, %750 : i1
      %c-1_i32_306 = arith.constant -1 : i32
      %752 = arith.addi %745, %c-1_i32_306 : i32
      %753 = arith.select %751, %752, %745 : i32
      %754 = arith.muli %742, %753 : i32
      cf.br ^bb193(%754 : i32)
    ^bb192:  // pred: ^bb187
      cf.br ^bb193(%c0_i32 : i32)
    ^bb193(%755: i32):  // 2 preds: ^bb191, ^bb192
      cf.br ^bb194
    ^bb194:  // pred: ^bb193
      %756 = nvvm.shfl.sync  up %c-1_i32, %755, %c1_i32, %c0_i32 : i32 -> i32
      cf.cond_br %689, ^bb195, ^bb196
    ^bb195:  // pred: ^bb194
      %757 = arith.addi %755, %756 : i32
      cf.br ^bb197(%757 : i32)
    ^bb196:  // pred: ^bb194
      cf.br ^bb197(%755 : i32)
    ^bb197(%758: i32):  // 2 preds: ^bb195, ^bb196
      cf.br ^bb198
    ^bb198:  // pred: ^bb197
      %759 = nvvm.shfl.sync  up %c-1_i32, %758, %c2_i32, %c0_i32 : i32 -> i32
      cf.cond_br %690, ^bb199, ^bb200
    ^bb199:  // pred: ^bb198
      %760 = arith.addi %758, %759 : i32
      cf.br ^bb201(%760 : i32)
    ^bb200:  // pred: ^bb198
      cf.br ^bb201(%758 : i32)
    ^bb201(%761: i32):  // 2 preds: ^bb199, ^bb200
      cf.br ^bb202
    ^bb202:  // pred: ^bb201
      %762 = nvvm.shfl.sync  up %c-1_i32, %761, %c4_i32, %c0_i32 : i32 -> i32
      cf.cond_br %691, ^bb203, ^bb204
    ^bb203:  // pred: ^bb202
      %763 = arith.addi %761, %762 : i32
      cf.br ^bb205(%763 : i32)
    ^bb204:  // pred: ^bb202
      cf.br ^bb205(%761 : i32)
    ^bb205(%764: i32):  // 2 preds: ^bb203, ^bb204
      cf.br ^bb206
    ^bb206:  // pred: ^bb205
      %765 = nvvm.shfl.sync  up %c-1_i32, %764, %c8_i32, %c0_i32 : i32 -> i32
      cf.cond_br %692, ^bb207, ^bb208
    ^bb207:  // pred: ^bb206
      %766 = arith.addi %764, %765 : i32
      cf.br ^bb209(%766 : i32)
    ^bb208:  // pred: ^bb206
      cf.br ^bb209(%764 : i32)
    ^bb209(%767: i32):  // 2 preds: ^bb207, ^bb208
      cf.br ^bb210
    ^bb210:  // pred: ^bb209
      %768 = nvvm.shfl.sync  up %c-1_i32, %767, %c16_i32, %c0_i32 : i32 -> i32
      cf.cond_br %693, ^bb211, ^bb212
    ^bb211:  // pred: ^bb210
      %769 = arith.addi %767, %768 : i32
      cf.br ^bb213(%769 : i32)
    ^bb212:  // pred: ^bb210
      cf.br ^bb213(%767 : i32)
    ^bb213(%770: i32):  // 2 preds: ^bb211, ^bb212
      cf.br ^bb214
    ^bb214:  // pred: ^bb213
      %771 = arith.addi %770, %722 : i32
      %772 = arith.cmpi sge, %709, %771 : i32
      %773 = nvvm.vote.ballot.sync %c-1_i32, %772 : i32
      %774 = llvm.intr.ctpop(%773) : (i32) -> i32
      %775 = arith.cmpi eq, %774, %c32_i32 : i32
      %776 = arith.addi %774, %720 : i32
      %777 = arith.cmpi eq, %774, %c0_i32 : i32
      %778 = arith.cmpi eq, %777, %false : i1
      cf.cond_br %778, ^bb215, ^bb216
    ^bb215:  // pred: ^bb214
      %779 = arith.subi %774, %c1_i32 : i32
      %780 = nvvm.shfl.sync  idx %c-1_i32, %771, %779, %c31_i32 : i32 -> i32
      cf.br ^bb217(%780 : i32)
    ^bb216:  // pred: ^bb214
      cf.br ^bb217(%722 : i32)
    ^bb217(%781: i32):  // 2 preds: ^bb215, ^bb216
      cf.br ^bb218
    ^bb218:  // pred: ^bb217
      %782 = arith.select %775, %c31_i32, %774 : i32
      %783 = nvvm.shfl.sync  idx %c-1_i32, %771, %782, %c31_i32 : i32 -> i32
      cf.br ^bb186(%775, %776, %781, %783 : i1, i32, i32, i32)
    ^bb219:  // pred: ^bb186
      %rmem_307 = cute.memref.alloca() : !memref_rmem_i32_
      %coord_308 = cute.make_coord(%717) : (i32) -> !cute.coord<"(?,_)">
      %idx_309 = cute.crd2idx(%coord_308, %18) : (!cute.coord<"(?,_)">, !cute.layout<"(2,4):(4,1)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_310 = cute.add_offset(%iter_286, %idx_309) : (!cute.ptr<i32, gmem, align<16>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<i32, gmem, align<16>>
      %iter_311 = cute.get_iter(%rmem_307) : !memref_rmem_i32_
      %784 = builtin.unrealized_conversion_cast %ptr_310 : !cute.ptr<i32, gmem, align<16>> to !llvm.ptr<1>
      %785 = builtin.unrealized_conversion_cast %iter_311 : !cute.ptr<i32, rmem, align<32>> to !llvm.ptr
      cf.br ^bb220(%c0_i32 : i32)
    ^bb220(%786: i32):  // 2 preds: ^bb219, ^bb221
      %787 = arith.cmpi slt, %786, %694 : i32
      cf.cond_br %787, ^bb221, ^bb222 {llvm.loop_annotation = #loop_annotation}
    ^bb221:  // pred: ^bb220
      %788 = llvm.load %784 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<4xi32>
      llvm.store %788, %785 {alignment = 16 : i64} : vector<4xi32>, !llvm.ptr
      %789 = arith.addi %786, %c1_i32 : i32
      cf.br ^bb220(%789 : i32)
    ^bb222:  // pred: ^bb220
      %790 = arith.subi %709, %718 : i32
      %791 = cute.memref.load(%rmem_307, %19) : (!memref_rmem_i32_, !cute.coord<"0">) -> i32
      %792 = cute.memref.load(%rmem_307, %17) : (!memref_rmem_i32_, !cute.coord<"1">) -> i32
      %793 = cute.memref.load(%rmem_307, %16) : (!memref_rmem_i32_, !cute.coord<"2">) -> i32
      %int_tuple_312 = cute.make_int_tuple(%791, %792, %793) : (i32, i32, i32) -> !cute.int_tuple<"(?,?,?)">
      %794:3 = cute.get_scalars(%int_tuple_312) <{only_dynamic}> : !cute.int_tuple<"(?,?,?)">
      %c1_i32_313 = arith.constant 1 : i32
      %c0_i32_314 = arith.constant 0 : i32
      %c-1_i32_315 = arith.constant -1 : i32
      %795 = arith.cmpi sgt, %c128_i32, %c0_i32_314 : i32
      %796 = arith.select %795, %c-1_i32_315, %c1_i32_313 : i32
      %797 = arith.addi %796, %794#0 : i32
      %798 = arith.divsi %797, %c128_i32 : i32
      %799 = arith.addi %c1_i32_313, %798 : i32
      %800 = arith.subi %c0_i32_314, %794#0 : i32
      %801 = arith.divsi %800, %c128_i32 : i32
      %802 = arith.subi %c0_i32_314, %801 : i32
      %803 = arith.cmpi slt, %794#0, %c0_i32_314 : i32
      %804 = arith.cmpi sgt, %794#0, %c0_i32_314 : i32
      %805 = arith.cmpi slt, %c128_i32, %c0_i32_314 : i32
      %806 = arith.cmpi sgt, %c128_i32, %c0_i32_314 : i32
      %807 = arith.andi %803, %805 : i1
      %808 = arith.andi %804, %806 : i1
      %809 = arith.ori %807, %808 : i1
      %810 = arith.select %809, %799, %802 : i32
      %c1_i32_316 = arith.constant 1 : i32
      %c0_i32_317 = arith.constant 0 : i32
      %c-1_i32_318 = arith.constant -1 : i32
      %811 = arith.cmpi sgt, %c128_i32, %c0_i32_317 : i32
      %812 = arith.select %811, %c-1_i32_318, %c1_i32_316 : i32
      %813 = arith.addi %812, %794#1 : i32
      %814 = arith.divsi %813, %c128_i32 : i32
      %815 = arith.addi %c1_i32_316, %814 : i32
      %816 = arith.subi %c0_i32_317, %794#1 : i32
      %817 = arith.divsi %816, %c128_i32 : i32
      %818 = arith.subi %c0_i32_317, %817 : i32
      %819 = arith.cmpi slt, %794#1, %c0_i32_317 : i32
      %820 = arith.cmpi sgt, %794#1, %c0_i32_317 : i32
      %821 = arith.cmpi slt, %c128_i32, %c0_i32_317 : i32
      %822 = arith.cmpi sgt, %c128_i32, %c0_i32_317 : i32
      %823 = arith.andi %819, %821 : i1
      %824 = arith.andi %820, %822 : i1
      %825 = arith.ori %823, %824 : i1
      %826 = arith.select %825, %815, %818 : i32
      %c1_i32_319 = arith.constant 1 : i32
      %c0_i32_320 = arith.constant 0 : i32
      %c-1_i32_321 = arith.constant -1 : i32
      %827 = arith.cmpi sgt, %c64_i32, %c0_i32_320 : i32
      %828 = arith.select %827, %c-1_i32_321, %c1_i32_319 : i32
      %829 = arith.addi %828, %794#2 : i32
      %830 = arith.divsi %829, %c64_i32 : i32
      %831 = arith.addi %c1_i32_319, %830 : i32
      %832 = arith.subi %c0_i32_320, %794#2 : i32
      %833 = arith.divsi %832, %c64_i32 : i32
      %834 = arith.subi %c0_i32_320, %833 : i32
      %835 = arith.cmpi slt, %794#2, %c0_i32_320 : i32
      %836 = arith.cmpi sgt, %794#2, %c0_i32_320 : i32
      %837 = arith.cmpi slt, %c64_i32, %c0_i32_320 : i32
      %838 = arith.cmpi sgt, %c64_i32, %c0_i32_320 : i32
      %839 = arith.andi %835, %837 : i1
      %840 = arith.andi %836, %838 : i1
      %841 = arith.ori %839, %840 : i1
      %842 = arith.select %841, %831, %834 : i32
      %int_tuple_322 = cute.make_int_tuple(%810, %826, %842) : (i32, i32, i32) -> !cute.int_tuple<"(?,?,?)">
      %e0_323, %e1_324, %e2_325 = cute.get_leaves(%int_tuple_322) : !cute.int_tuple<"(?,?,?)">
      %shape_326 = cute.make_shape(%e0_323, %e1_324) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.shape<"(?,?)">
      %lay_327 = cute.make_layout(%shape_326) : !cute.layout<"(?,?):(1,?)">
      %843 = cute.get_hier_coord(%790, %lay_327) : (i32, !cute.layout<"(?,?):(1,?)">) -> !cute.coord<"(?,?)">
      %e0_328, %e1_329 = cute.get_leaves(%843) : !cute.coord<"(?,?)">
      %itup_330 = cute.to_int_tuple(%e0_328) : !cute.coord<"?"> to !cute.int_tuple<"?">
      %itup_331 = cute.to_int_tuple(%e1_329) : !cute.coord<"?"> to !cute.int_tuple<"?">
      %mul_332 = cute.tuple_mul(%itup_330, %39) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %mul_333 = cute.tuple_mul(%itup_331, %39) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %844 = arith.cmpi ne, %717, %710 : i32
      cf.cond_br %844, ^bb223, ^bb231
    ^bb223:  // pred: ^bb222
      %coord_334 = cute.make_coord(%717) : (i32) -> !cute.coord<"(?,2)">
      %845 = cute.memref.load(%arg10, %coord_334) : (!memref_gmem_i64_, !cute.coord<"(?,2)">) -> i64
      %iv_335 = cute.assume(%845) : (i64) -> !cute.i64<divby 16>
      %846 = cute.inttoptr(%iv_335) : !cute.i64<divby 16> to !cute.ptr<f16, gmem, align<16>>
      %coord_336 = cute.make_coord(%717) : (i32) -> !cute.coord<"(?,2,_)">
      %idx_337 = cute.crd2idx(%coord_336, %15) : (!cute.coord<"(?,2,_)">, !cute.layout<"(2,3,2):(6,2,1)">) -> !cute.int_tuple<"?{div=2}">
      %iter_338 = cute.get_iter(%arg9) : !memref_gmem_i32_1
      %ptr_339 = cute.add_offset(%iter_338, %idx_337) : (!cute.ptr<i32, gmem, align<16>>, !cute.int_tuple<"?{div=2}">) -> !cute.ptr<i32, gmem, align<8>>
      %rmem_340 = cute.memref.alloca() : !memref_rmem_i32_1
      %iter_341 = cute.get_iter(%rmem_340) : !memref_rmem_i32_1
      %847 = builtin.unrealized_conversion_cast %ptr_339 : !cute.ptr<i32, gmem, align<8>> to !llvm.ptr<1>
      %848 = builtin.unrealized_conversion_cast %iter_341 : !cute.ptr<i32, rmem, align<32>> to !llvm.ptr
      cf.br ^bb224(%c0_i32 : i32)
    ^bb224(%849: i32):  // 2 preds: ^bb223, ^bb225
      %850 = arith.cmpi slt, %849, %694 : i32
      cf.cond_br %850, ^bb225, ^bb226 {llvm.loop_annotation = #loop_annotation}
    ^bb225:  // pred: ^bb224
      %851 = llvm.load %847 {alignment = 8 : i64} : !llvm.ptr<1> -> vector<2xi32>
      llvm.store %851, %848 {alignment = 8 : i64} : vector<2xi32>, !llvm.ptr
      %852 = arith.addi %849, %c1_i32 : i32
      cf.br ^bb224(%852 : i32)
    ^bb226:  // pred: ^bb224
      %853 = cute.memref.load(%rmem_340, %19) : (!memref_rmem_i32_1, !cute.coord<"0">) -> i32
      %854 = cute.memref.load(%rmem_340, %17) : (!memref_rmem_i32_1, !cute.coord<"1">) -> i32
      %shape_342 = cute.make_shape(%791, %792) : (i32, i32) -> !cute.shape<"(?,?,1)">
      %stride_343 = cute.make_stride(%853, %854) : (i32, i32) -> !cute.stride<"(?,?,0)">
      %lay_344 = cute.make_layout(%shape_342, %stride_343) : !cute.layout<"(?,?,1):(?,?,0)">
      %view_345 = cute.make_view(%846, %lay_344) : !memref_gmem_f16_
      %dyn_346 = cute.derefine(%view_345) : !memref_gmem_f16_ to !memref_gmem_f16_1
      cf.cond_br %65, ^bb227, ^bb230
    ^bb227:  // pred: ^bb226
      cute_nvgpu.update_tma_desc(%arg5, %dyn_346, %dyn) : (!cute_nvgpu.atom.non_exec_tiled_tma_store<f16, copy_bits = 65536, tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>, !memref_gmem_f16_1, !cute.ptr<i64, smem, align<128>>) -> ()
      %855 = nvvm.elect.sync -> i1
      cf.cond_br %855, ^bb228, ^bb229
    ^bb228:  // pred: ^bb227
      nvvm.cp.async.bulk.commit.group
      nvvm.cp.async.bulk.wait_group 0 {read}
      cf.br ^bb229
    ^bb229:  // 2 preds: ^bb227, ^bb228
      nvvm.bar.warp.sync %c-1_i32 : i32
      %856 = cute.ptrtoint(%201) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, gmem, align<128>> to i64
      %857 = cute.ptrtoint(%dyn) : !cute.ptr<i64, smem, align<128>> to i32
      llvm.inline_asm has_side_effects asm_dialect = att "tensormap.cp_fenceproxy.global.shared::cta.tensormap::generic.release.gpu.sync.aligned [$0], [$1], 128;", "l,r" %856, %857 : (i64, i32) -> ()
      cf.br ^bb230
    ^bb230:  // 2 preds: ^bb226, ^bb229
      cf.br ^bb231
    ^bb231:  // 2 preds: ^bb222, ^bb230
      %div_347 = cute.tuple_div(%mul_332, %39) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %int_tuple_348 = cute.make_int_tuple(%708) : (i32) -> !cute.int_tuple<"?">
      %tup_349 = cute.add_offset(%int_tuple_348, %e2_325) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.int_tuple<"?">
      %858 = cute.get_scalars(%tup_349) : !cute.int_tuple<"?">
      %coord_350 = cute.make_coord(%div_347, %mul_333) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(_,_,_,?,?,0)">
      %idx_351 = cute.crd2idx(%coord_350, %lay_274) : (!cute.coord<"(_,_,_,?,?,0)">, !cute.layout<"(((32,128),1),1,4,?,?,?):(((1@0,1@1),0),0,32@0,128@1,128@0,1@2)">) -> !cute.int_tuple<"(?{div=128},?{div=128},0)">
      %tup_352 = cute.add_offset(%27, %idx_351) : (!cute.int_tuple<"(0,0,0)">, !cute.int_tuple<"(?{div=128},?{div=128},0)">) -> !cute.int_tuple<"(?{div=128},?{div=128},0)">
      %859 = arith.remsi %714, %c2_i32 : i32
      %coord_353 = cute.make_coord(%859) : (i32) -> !cute.coord<"(_,_,_,_,_,?)">
      %idx_354 = cute.crd2idx(%coord_353, %7) : (!cute.coord<"(_,_,_,_,_,?)">, !cute.layout<"(((32,32),1),1,1,1,4,2):(((1,65536),0),0,0,0,32,128)">) -> !cute.int_tuple<"?{div=128}">
      %ptr_355 = cute.add_offset(%ptr_258, %idx_354) : (!cute.ptr<f32, tmem, align<16>>, !cute.int_tuple<"?{div=128}">) -> !cute.ptr<f32, tmem, align<16>>
      %860 = arith.divsi %714, %c2_i32 : i32
      %861 = arith.muli %860, %c2_i32 : i32
      %862 = arith.cmpi ne, %714, %861 : i32
      %c0_i32_356 = arith.constant 0 : i32
      %863 = arith.cmpi slt, %714, %c0_i32_356 : i32
      %864 = arith.cmpi slt, %c2_i32, %c0_i32_356 : i32
      %865 = arith.cmpi ne, %863, %864 : i1
      %866 = arith.andi %862, %865 : i1
      %c-1_i32_357 = arith.constant -1 : i32
      %867 = arith.addi %860, %c-1_i32_357 : i32
      %868 = arith.select %866, %867, %860 : i32
      %869 = arith.remsi %868, %c2_i32 : i32
      %int_tuple_358 = cute.make_int_tuple(%859) : (i32) -> !cute.int_tuple<"?">
      %ptr_359 = cute.add_offset(%iter_16, %int_tuple_358) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %870 = builtin.unrealized_conversion_cast %ptr_359 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %870, %869, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      cf.cond_br %844, ^bb232, ^bb235
    ^bb232:  // pred: ^bb231
      cf.cond_br %65, ^bb233, ^bb234
    ^bb233:  // pred: ^bb232
      %871 = cute.ptrtoint(%201) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, gmem, align<128>> to i64
      llvm.inline_asm has_side_effects asm_dialect = att "fence.proxy.tensormap::generic.acquire.gpu [$0], 128;", "l" %871 : (i64) -> ()
      cf.br ^bb234
    ^bb234:  // 2 preds: ^bb232, ^bb233
      cf.br ^bb235
    ^bb235:  // 2 preds: ^bb231, ^bb234
      %872 = arith.muli %714, %c4_i32 : i32
      %873 = arith.remsi %872, %c4_i32 : i32
      cf.br ^bb236(%c0_i32, %873 : i32, i32)
    ^bb236(%874: i32, %875: i32):  // 2 preds: ^bb235, ^bb248
      %876 = arith.cmpi slt, %874, %c4_i32 : i32
      cf.cond_br %876, ^bb237, ^bb249
    ^bb237:  // pred: ^bb236
      %coord_360 = cute.make_coord(%874) : (i32) -> !cute.coord<"(_,_,_,?)">
      %idx_361 = cute.crd2idx(%coord_360, %6) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"(((32,32),1),1,1,(1,4)):(((1,65536),0),0,0,(0,32))">) -> !cute.int_tuple<"?{div=32}">
      %ptr_362 = cute.add_offset(%ptr_355, %idx_361) : (!cute.ptr<f32, tmem, align<16>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f32, tmem, align<16>>
      cf.br ^bb238(%c0_i32 : i32)
    ^bb238(%877: i32):  // 2 preds: ^bb237, ^bb239
      %878 = arith.cmpi slt, %877, %694 : i32
      cf.cond_br %878, ^bb239, ^bb240 {llvm.loop_annotation = #loop_annotation}
    ^bb239:  // pred: ^bb238
      %879 = "cute_nvgpu.arch.copy.SM100.tmem_load"(%ptr_362) <{num_b = 32 : i32, num_dp = 32 : i32, num_rep = 32 : i32}> : (!cute.ptr<f32, tmem, align<16>>) -> vector<32xi32>
      llvm.store %879, %695 : vector<32xi32>, !llvm.ptr
      %880 = arith.addi %877, %c1_i32 : i32
      cf.br ^bb238(%880 : i32)
    ^bb240:  // pred: ^bb238
      %881 = cute.memref.load_vec %view_287, row_major : !memref_rmem_f32_1
      %882 = arith.truncf %881 : vector<32xf32> to vector<32xf16>
      cute.memref.store_vec %882, %view_266, row_major : !memref_rmem_f16_1
      %coord_363 = cute.make_coord(%875) : (i32) -> !cute.coord<"(_,_,_,?)">
      %idx_364 = cute.crd2idx(%coord_363, %5) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((1,32),1,1,(1,4)):((0,1),0,0,(0,4096))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_365 = cute.add_offset(%swizzled, %idx_364) : (!cute.ptr<f16, smem, align<64>, S<2,4,3>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, smem, align<64>, S<2,4,3>>
      %883 = builtin.unrealized_conversion_cast %ptr_365 : !cute.ptr<f16, smem, align<64>, S<2,4,3>> to !llvm.ptr<3>
      %ptr_366 = cute.add_offset(%swizzled_290, %idx_364) : (!cute.ptr<f16, smem, align<16>, S<2,4,3>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, smem, align<16>, S<2,4,3>>
      %884 = builtin.unrealized_conversion_cast %ptr_366 : !cute.ptr<f16, smem, align<16>, S<2,4,3>> to !llvm.ptr<3>
      %ptr_367 = cute.add_offset(%swizzled_293, %idx_364) : (!cute.ptr<f16, smem, align<32>, S<2,4,3>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, smem, align<32>, S<2,4,3>>
      %885 = builtin.unrealized_conversion_cast %ptr_367 : !cute.ptr<f16, smem, align<32>, S<2,4,3>> to !llvm.ptr<3>
      %ptr_368 = cute.add_offset(%swizzled_296, %idx_364) : (!cute.ptr<f16, smem, align<16>, S<2,4,3>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, smem, align<16>, S<2,4,3>>
      %886 = builtin.unrealized_conversion_cast %ptr_368 : !cute.ptr<f16, smem, align<16>, S<2,4,3>> to !llvm.ptr<3>
      cf.br ^bb241(%c0_i32 : i32)
    ^bb241(%887: i32):  // 2 preds: ^bb240, ^bb242
      %888 = arith.cmpi slt, %887, %694 : i32
      cf.cond_br %888, ^bb242, ^bb243 {llvm.loop_annotation = #loop_annotation}
    ^bb242:  // pred: ^bb241
      %889 = llvm.load %696 {alignment = 16 : i64} : !llvm.ptr -> vector<8xf16>
      llvm.store %889, %883 {alignment = 16 : i64} : vector<8xf16>, !llvm.ptr<3>
      %890 = llvm.load %697 {alignment = 16 : i64} : !llvm.ptr -> vector<8xf16>
      llvm.store %890, %884 {alignment = 16 : i64} : vector<8xf16>, !llvm.ptr<3>
      %891 = llvm.load %698 {alignment = 16 : i64} : !llvm.ptr -> vector<8xf16>
      llvm.store %891, %885 {alignment = 16 : i64} : vector<8xf16>, !llvm.ptr<3>
      %892 = llvm.load %699 {alignment = 16 : i64} : !llvm.ptr -> vector<8xf16>
      llvm.store %892, %886 {alignment = 16 : i64} : vector<8xf16>, !llvm.ptr<3>
      %893 = arith.addi %887, %c1_i32 : i32
      cf.br ^bb241(%893 : i32)
    ^bb243:  // pred: ^bb241
      nvvm.fence.proxy {kind = #nvvm.proxy_kind<async.shared>, space = #nvvm.shared_space<cta>}
      nvvm.barrier id = %c2_i32 number_of_threads = %c128_i32
      cf.cond_br %65, ^bb244, ^bb248
    ^bb244:  // pred: ^bb243
      %coord_369 = cute.make_coord(%875) : (i32) -> !cute.coord<"(_,?)">
      %idx_370 = cute.crd2idx(%coord_369, %2) : (!cute.coord<"(_,?)">, !cute.layout<"((4096,1),(1,4)):((1,0),(0,4096))">) -> !cute.int_tuple<"?{div=4096}">
      %ptr_371 = cute.add_offset(%iter_24, %idx_370) : (!cute.ptr<f16, smem, align<1024>, S<2,4,3>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, smem, align<1024>, S<2,4,3>>
      %coord_372 = cute.make_coord(%874) : (i32) -> !cute.coord<"(_,?)">
      %idx_373 = cute.crd2idx(%coord_372, %1) : (!cute.coord<"(_,?)">, !cute.layout<"(((32,128),1),(1,4)):(((1@0,1@1),0),(0,32@0))">) -> !cute.int_tuple<"(?{div=32},0)">
      %tup_374 = cute.add_offset(%tup_352, %idx_373) : (!cute.int_tuple<"(?{div=128},?{div=128},0)">, !cute.int_tuple<"(?{div=32},0)">) -> !cute.int_tuple<"(?{div=32},?{div=128},0)">
      %e0_375, %e1_376, %e2_377 = cute.get_leaves(%tup_374) : !cute.int_tuple<"(?{div=32},?{div=128},0)">
      %894 = cute.ptrtoint(%201) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, gmem, align<128>> to i64
      %iv_378 = cute.assume(%894) : (i64) -> !cute.i64<divby 128>
      %895 = cute.inttoptr(%iv_378) : !cute.i64<divby 128> to !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<128>>
      %int_tuple_379 = cute.make_int_tuple(%e0_375, %e1_376) : (!cute.int_tuple<"?{div=32}">, !cute.int_tuple<"?{div=128}">) -> !cute.int_tuple<"(?{div=32},?{div=128},0)">
      %896 = cute_nvgpu.atom.make_exec_tma(%arg5) : (!cute_nvgpu.atom.non_exec_tiled_tma_store<f16, copy_bits = 65536, tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_store<f16, copy_bits = 65536, mode = tiled, g_stride = <"()"> tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">>
      %897 = cute_nvgpu.atom.set_value(%896, %895 : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<128>>) {field = #cute_nvgpu.atom_copy_field_tmastore<tma_descriptor_ptr>} : !cute_nvgpu.atom.tma_store<f16, copy_bits = 65536, mode = tiled, g_stride = <"()"> tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">>
      %TMADescAddr_380 = cute_nvgpu.get_tma_desc_addr(%897 : !cute_nvgpu.atom.tma_store<f16, copy_bits = 65536, mode = tiled, g_stride = <"()"> tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">>) -> !cute.ptr<generic, align<64>>
      %898:3 = cute.get_scalars(%int_tuple_379) : !cute.int_tuple<"(?{div=32},?{div=128},0)">
      cf.br ^bb245(%c0_i32 : i32)
    ^bb245(%899: i32):  // 2 preds: ^bb244, ^bb246
      %900 = arith.cmpi slt, %899, %694 : i32
      cf.cond_br %900, ^bb246, ^bb247 {llvm.loop_annotation = #loop_annotation}
    ^bb246:  // pred: ^bb245
      cute_nvgpu.arch.copy.SM100.tma_store(%TMADescAddr_380 : !cute.ptr<generic, align<64>>, %ptr_371 : !cute.ptr<f16, smem, align<1024>, S<2,4,3>>, [%898#0, %898#1, %898#2] : i32, i32, i32) mode = <tiled>
      %901 = arith.addi %899, %c1_i32 : i32
      cf.br ^bb245(%901 : i32)
    ^bb247:  // pred: ^bb245
      nvvm.cp.async.bulk.commit.group
      nvvm.cp.async.bulk.wait_group 3 {read}
      cf.br ^bb248
    ^bb248:  // 2 preds: ^bb243, ^bb247
      nvvm.barrier id = %c2_i32 number_of_threads = %c128_i32
      %902 = arith.addi %875, %c1_i32 : i32
      %903 = arith.cmpi eq, %902, %c4_i32 : i32
      %904 = arith.select %903, %c0_i32, %902 : i32
      %905 = arith.addi %874, %c1_i32 : i32
      cf.br ^bb236(%905, %904 : i32, i32)
    ^bb249:  // pred: ^bb236
      %906 = nvvm.elect.sync -> i1
      cf.cond_br %906, ^bb250, ^bb251
    ^bb250:  // pred: ^bb249
      %ptr_381 = cute.add_offset(%iter_17, %int_tuple_358) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %907 = builtin.unrealized_conversion_cast %ptr_381 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %907, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>} : !llvm.ptr<3>, i32
      cf.br ^bb251
    ^bb251:  // 2 preds: ^bb249, ^bb250
      %908 = arith.addi %713, %683 : i32
      %909 = arith.addi %714, %c1_i32 : i32
      %910 = arith.cmpi sgt, %684, %908 : i32
      %911 = cute.get_hier_coord(%908, %lay) : (i32, !cute.layout<"(1,1,?):(0,0,1)">) -> !cute.coord<"(0,0,?)">
      %e0_382, %e1_383, %e2_384 = cute.get_leaves(%911) : !cute.coord<"(0,0,?)">
      %itup_385 = cute.to_int_tuple(%e2_384) : !cute.coord<"?"> to !cute.int_tuple<"?">
      %mul_386 = cute.tuple_mul(%itup_385, %39) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
      %912 = cute.get_scalars(%mul_386) : !cute.int_tuple<"?">
      cf.br ^bb184(%858, %912, %910, %717, %717, %718, %908, %909 : i32, i32, i1, i32, i32, i32, i32, i32)
    ^bb252:  // pred: ^bb184
      cf.cond_br %65, ^bb253, ^bb254
    ^bb253:  // pred: ^bb252
      cute_nvgpu.arch.sm100.relinquish_tmem_alloc_permit [ cta_1]
      cf.br ^bb254
    ^bb254:  // 2 preds: ^bb252, ^bb253
      nvvm.barrier id = %c2_i32 number_of_threads = %c128_i32
      cf.cond_br %65, ^bb255, ^bb256
    ^bb255:  // pred: ^bb254
      cute_nvgpu.arch.sm100.dealloc_tmem(%tmem_ptr_254, %c256_i32) [ cta_1] : !cute.ptr<f32, tmem, align<16>>, i32
      cf.br ^bb256
    ^bb256:  // 2 preds: ^bb254, ^bb255
      cf.cond_br %65, ^bb257, ^bb258
    ^bb257:  // pred: ^bb256
      %913 = arith.subi %700, %c1_i32 : i32
      %914 = arith.remsi %913, %c6_i32 : i32
      %int_tuple_387 = cute.make_int_tuple(%914) : (i32) -> !cute.int_tuple<"?">
      %ptr_388 = cute.add_offset(%iter_15, %int_tuple_387) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %915 = arith.divsi %913, %c6_i32 : i32
      %916 = arith.muli %915, %c6_i32 : i32
      %917 = arith.cmpi ne, %913, %916 : i32
      %c0_i32_389 = arith.constant 0 : i32
      %918 = arith.cmpi slt, %913, %c0_i32_389 : i32
      %919 = arith.cmpi slt, %c6_i32, %c0_i32_389 : i32
      %920 = arith.cmpi ne, %918, %919 : i1
      %921 = arith.andi %917, %920 : i1
      %c-1_i32_390 = arith.constant -1 : i32
      %922 = arith.addi %915, %c-1_i32_390 : i32
      %923 = arith.select %921, %922, %915 : i32
      %924 = arith.remsi %923, %c2_i32 : i32
      %925 = builtin.unrealized_conversion_cast %ptr_388 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %925, %924, %c10000000_i32 : !llvm.ptr<3>, i32, i32
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
    %249 = arith.cmpi slt, %248, %c1_i32 : i32
    %250 = arith.select %249, %248, %c1_i32 : i32
    %251 = arith.index_cast %250 : i32 to index
    %252 = gpu.launch_func async [%arg7] @kernels::@kernel_cutlass_kernel___main__GroupedGemmKernel_object_at__TiledMMA_ThrLayoutVMNK11110000_PermutationMNK____MMAAtom_ThrID10_ShapeMNK12812816_TVLayoutA1128161281128_TVLayoutB1128161281128__0 clusters in (%c1, %c1, %c1) blocks in (%c1, %c1, %251) threads in (%c192, %c1, %c1)  dynamic_shared_memory_size %c230400_i32 args(%12 : !mma_f16_f16_f32_128x128x16_, %99 : !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>, %view : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">, %171 : !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>, %view_5 : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">, %244 : !cute_nvgpu.atom.non_exec_tiled_tma_store<f16, copy_bits = 65536, tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>, %view_10 : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">, %c2_i32 : i32, %arg3 : !memref_gmem_i32_, %arg4 : !memref_gmem_i32_1, %arg5 : !memref_gmem_i64_, %arg6 : !memref_gmem_i64_1) {use_pdl = false}
    return
  }
}
