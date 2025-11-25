!memref_gmem_f16_ = !cute.memref<f16, gmem, align<32>, "(?,?{div=8192}):(?{i64 div=8192},1)">
!memref_rmem_f16_ = !cute.memref<f16, rmem, align<32>, "((64,1),1):((1,0),0)">
!memref_rmem_f32_ = !cute.memref<f32, rmem, align<32>, "((64,1),1):((1,0),0)">
!mma_f16_f16_f32_128x256x16_ = !cute.tiled_mma<!cute_nvgpu.sm100.mma<128x256x16, num_cta = 1, ab_major = (k, k), elem_type = (f16, f16, f32), frag_kind = ss, c_scale_exp = 0>, atom_layout_MNK = <"(1,1,1):(0,0,0)">>
#loop_unroll = #llvm.loop_unroll<disable = false, full = true>
#loop_annotation = #llvm.loop_annotation<unroll = #loop_unroll>
module attributes {gpu.container_module} {
  gpu.module @kernels {
    func.func public @kernel_cutlass_kernel_TiledMMA_ThrLayoutVMNK11110000_PermutationMNK____MMAAtom_ThrID10_ShapeMNK12825616_TVLayoutA1128161281128_TVLayoutB1256162561256_TVLayoutC11282561281128_CopyAtom_ThrI_0(%arg0: !mma_f16_f16_f32_128x256x16_, %arg1: !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, internal_val_type = f16>, %arg2: !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">, %arg3: !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 262144, tma_gbasis = <"(64,256):(1@1,1@0)">, internal_val_type = f16>, %arg4: !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">, %arg5: !memref_gmem_f16_) attributes {cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} {
      %0 = builtin.unrealized_conversion_cast %arg0 : !mma_f16_f16_f32_128x256x16_ to !llvm.struct<(i1, i1, i1)>
      %c127_i32 = arith.constant 127 : i32
      %1 = cute.static : !cute.int_tuple<"8">
      %2 = cute.static : !cute.layout<"(8,(8)):(1,(8))">
      %3 = cute.static : !cute.layout<"((64,1),1,((1,4),1,1)):((1,0),0,((0,64),0,0))">
      %4 = cute.static : !cute.layout<"(((64,32),1),1,((1,4),1,1)):(((1,65536),0),0,((0,64),0,0))">
      %c14_i32 = arith.constant 14 : i32
      %c13_i32 = arith.constant 13 : i32
      %c138412048_i32 = arith.constant 138412048 : i32
      %5 = cute.static : !cute.layout<"(1,1,4,4):(0,0,2,2048)">
      %6 = cute.static : !cute.layout<"(1,1,4,4):(0,0,2,1024)">
      %7 = cute.static : !cute.layout<"((16384,1),4):((1,0),16384)">
      %8 = cute.static : !cute.layout<"((8192,1),4):((1,0),8192)">
      %c49152_i32 = arith.constant 49152 : i32
      %c2_i32 = arith.constant 2 : i32
      %c4_i32 = arith.constant 4 : i32
      %c10000000_i32 = arith.constant 10000000 : i32
      %true = arith.constant true
      %c32_i64 = arith.constant 32 : i64
      %c2097152_i32 = arith.constant 2097152 : i32
      %9 = cute.static : !cute.shape<"(((128,64)),((1,4),1,1))">
      %10 = cute.static : !cute.stride<"(((1@0,1@1),0),64@0)">
      %11 = cute.static : !cute.stride<"(((1@1,1@0),0,16@0),64@0)">
      %12 = cute.static : !cute.shape<"((128,256),1,1)">
      %13 = cute.static : !cute.stride<"((1@1,1@0),0,16@0,64@0)">
      %14 = cute.static : !cute.shape<"(128,256)">
      %c128_i64 = arith.constant 128 : i64
      %15 = cute.static : !cute.stride<"((1@1,1@0),(256@1,64@0))">
      %c256_i32 = arith.constant 256 : i32
      %16 = cute.static : !cute.int_tuple<"(0,0)">
      %17 = cute.static : !cute.stride<"(1@1,1@0,64@0)">
      %18 = cute.static : !cute.stride<"((1@1,1@0),(128@1,64@0))">
      %c64_i32 = arith.constant 64 : i32
      %19 = cute.static : !cute.int_tuple<"4">
      %20 = cute.static : !cute.int_tuple<"3">
      %21 = cute.static : !cute.int_tuple<"2">
      %22 = cute.static : !cute.int_tuple<"1">
      %c512_i32 = arith.constant 512 : i32
      %c0_i32 = arith.constant 0 : i32
      %23 = cute.static : !cute.int_tuple<"65536">
      %c-128_i32 = arith.constant -128 : i32
      %c1_i32 = arith.constant 1 : i32
      %c128_i32 = arith.constant 128 : i32
      %24 = cute.static : !cute.int_tuple<"80">
      %25 = cute.static : !cute.int_tuple<"64">
      %26 = cute.static : !cute.int_tuple<"88">
      %c32_i32 = arith.constant 32 : i32
      %27 = nvvm.read.ptx.sreg.tid.x range <i32, 0, 1024> : i32
      %28 = nvvm.read.ptx.sreg.tid.y range <i32, 0, 1024> : i32
      %29 = nvvm.read.ptx.sreg.tid.z range <i32, 0, 64> : i32
      %30 = nvvm.read.ptx.sreg.ntid.x range <i32, 1, 1024> : i32
      %31 = nvvm.read.ptx.sreg.ntid.y range <i32, 1, 1024> : i32
      %32 = arith.muli %28, %30 : i32
      %33 = arith.addi %27, %32 : i32
      %34 = arith.muli %29, %30 : i32
      %35 = arith.muli %34, %31 : i32
      %36 = arith.addi %33, %35 : i32
      %37 = arith.divsi %36, %c32_i32 : i32
      %38 = arith.muli %37, %c32_i32 : i32
      %39 = arith.cmpi ne, %36, %38 : i32
      %c0_i32_0 = arith.constant 0 : i32
      %40 = arith.cmpi slt, %36, %c0_i32_0 : i32
      %41 = arith.cmpi slt, %c32_i32, %c0_i32_0 : i32
      %42 = arith.cmpi ne, %40, %41 : i1
      %43 = arith.andi %39, %42 : i1
      %c-1_i32 = arith.constant -1 : i32
      %44 = arith.addi %37, %c-1_i32 : i32
      %45 = arith.select %43, %44, %37 : i32
      %46 = cute_nvgpu.arch.make_warp_uniform(%45) : i32
      %47 = nvvm.read.ptx.sreg.ctaid.x range <i32, 0, 2147483647> : i32
      %48 = nvvm.read.ptx.sreg.ctaid.y range <i32, 0, 65535> : i32
      %smem_ptr = cute_nvgpu.arch.get_dyn_smem() : !cute.ptr<i8, smem, align<1024>>
      %ptr = cute.add_offset(%smem_ptr, %26) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"88">) -> !cute.ptr<i8, smem, align<8>>
      %ptr_1 = cute.add_offset(%smem_ptr, %25) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"64">) -> !cute.ptr<i8, smem, align<64>>
      %ptr_2 = cute.add_offset(%smem_ptr, %24) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"80">) -> !cute.ptr<i8, smem, align<16>>
      %iter = cute.recast_iter(%ptr_2) : !cute.ptr<i8, smem, align<16>> to !cute.ptr<i32, smem, align<16>>
      %49 = cute.ptrtoint(%ptr) : !cute.ptr<i8, smem, align<8>> to i32
      %50 = arith.addi %49, %c127_i32 : i32
      %51 = arith.andi %50, %c-128_i32 : i32
      %52 = arith.extsi %51 : i32 to i64
      %iv = cute.assume(%52) : (i64) -> !cute.i64<divby 128>
      %53 = cute.inttoptr(%iv) : !cute.i64<divby 128> to !cute.ptr<i8, smem, align<128>>
      %ptr_3 = cute.add_offset(%53, %23) : (!cute.ptr<i8, smem, align<128>>, !cute.int_tuple<"65536">) -> !cute.ptr<i8, smem, align<128>>
      %iter_4 = cute.recast_iter(%53) : !cute.ptr<i8, smem, align<128>> to !cute.ptr<f16, smem, align<128>, S<3,4,3>>
      %iter_5 = cute.recast_iter(%ptr_3) : !cute.ptr<i8, smem, align<128>> to !cute.ptr<f16, smem, align<128>, S<3,4,3>>
      %54 = arith.cmpi eq, %46, %c0_i32 : i32
      cf.cond_br %54, ^bb1, ^bb2
    ^bb1:  // pred: ^bb0
      cute_nvgpu.arch.sm100.alloc_tmem(%c512_i32, %iter) [ cta_1] : i32, !cute.ptr<i32, smem, align<16>>
      cf.br ^bb2
    ^bb2:  // 2 preds: ^bb0, ^bb1
      cf.cond_br %54, ^bb3, ^bb4
    ^bb3:  // pred: ^bb2
      cute_nvgpu.prefetch_tma_desc(%arg1) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, internal_val_type = f16>) -> ()
      cute_nvgpu.prefetch_tma_desc(%arg3) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 262144, tma_gbasis = <"(64,256):(1@1,1@0)">, internal_val_type = f16>) -> ()
      cf.br ^bb4
    ^bb4:  // 2 preds: ^bb2, ^bb3
      %iter_6 = cute.recast_iter(%smem_ptr) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<i64, smem, align<1024>>
      cf.cond_br %54, ^bb5, ^bb6
    ^bb5:  // pred: ^bb4
      %55 = builtin.unrealized_conversion_cast %iter_6 : !cute.ptr<i64, smem, align<1024>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %55, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_7 = cute.add_offset(%iter_6, %22) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"1">) -> !cute.ptr<i64, smem>
      %56 = builtin.unrealized_conversion_cast %ptr_7 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %56, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_8 = cute.add_offset(%iter_6, %21) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"2">) -> !cute.ptr<i64, smem, align<16>>
      %57 = builtin.unrealized_conversion_cast %ptr_8 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %57, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_9 = cute.add_offset(%iter_6, %20) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"3">) -> !cute.ptr<i64, smem>
      %58 = builtin.unrealized_conversion_cast %ptr_9 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %58, %c1_i32 : !llvm.ptr<3>, i32
      cf.br ^bb6
    ^bb6:  // 2 preds: ^bb4, ^bb5
      %ptr_10 = cute.add_offset(%iter_6, %19) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"4">) -> !cute.ptr<i64, smem, align<32>>
      cf.cond_br %54, ^bb7, ^bb8
    ^bb7:  // pred: ^bb6
      %59 = builtin.unrealized_conversion_cast %ptr_10 : !cute.ptr<i64, smem, align<32>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %59, %c1_i32 : !llvm.ptr<3>, i32
      %int_tuple = cute.make_int_tuple() : () -> !cute.int_tuple<"5">
      %ptr_11 = cute.add_offset(%iter_6, %int_tuple) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"5">) -> !cute.ptr<i64, smem>
      %60 = builtin.unrealized_conversion_cast %ptr_11 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %60, %c1_i32 : !llvm.ptr<3>, i32
      %int_tuple_12 = cute.make_int_tuple() : () -> !cute.int_tuple<"6">
      %ptr_13 = cute.add_offset(%iter_6, %int_tuple_12) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"6">) -> !cute.ptr<i64, smem, align<16>>
      %61 = builtin.unrealized_conversion_cast %ptr_13 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %61, %c1_i32 : !llvm.ptr<3>, i32
      %int_tuple_14 = cute.make_int_tuple() : () -> !cute.int_tuple<"7">
      %ptr_15 = cute.add_offset(%iter_6, %int_tuple_14) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"7">) -> !cute.ptr<i64, smem>
      %62 = builtin.unrealized_conversion_cast %ptr_15 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %62, %c1_i32 : !llvm.ptr<3>, i32
      cf.br ^bb8
    ^bb8:  // 2 preds: ^bb6, ^bb7
      nvvm.fence.mbarrier.init
      nvvm.barrier
      %iter_16 = cute.recast_iter(%ptr_1) : !cute.ptr<i8, smem, align<64>> to !cute.ptr<i64, smem, align<64>>
      cf.cond_br %54, ^bb9, ^bb10
    ^bb9:  // pred: ^bb8
      %63 = builtin.unrealized_conversion_cast %iter_16 : !cute.ptr<i64, smem, align<64>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %63, %c1_i32 : !llvm.ptr<3>, i32
      cf.br ^bb10
    ^bb10:  // 2 preds: ^bb8, ^bb9
      %ptr_17 = cute.add_offset(%iter_16, %22) : (!cute.ptr<i64, smem, align<64>>, !cute.int_tuple<"1">) -> !cute.ptr<i64, smem>
      cf.cond_br %54, ^bb11, ^bb12
    ^bb11:  // pred: ^bb10
      %64 = builtin.unrealized_conversion_cast %ptr_17 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %64, %c128_i32 : !llvm.ptr<3>, i32
      cf.br ^bb12
    ^bb12:  // 2 preds: ^bb10, ^bb11
      nvvm.fence.mbarrier.init
      nvvm.barrier
      %coord = cute.make_coord(%47, %48) : (i32, i32) -> !cute.coord<"(?,?,_)">
      %65:2 = cute.get_scalars(%coord) <{only_dynamic}> : !cute.coord<"(?,?,_)">
      %coord_18 = cute.make_coord(%65#0) : (i32) -> !cute.coord<"((_,_),(?,_))">
      %lay = cute.get_layout(%arg2) : !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">
      %66:2 = cute.get_scalars(%lay) <{only_dynamic}> : !cute.layout<"(?,?{div=8192}):(1@1,1@0)">
      %c1_i32_19 = arith.constant 1 : i32
      %c0_i32_20 = arith.constant 0 : i32
      %c-1_i32_21 = arith.constant -1 : i32
      %67 = arith.cmpi sgt, %c128_i32, %c0_i32_20 : i32
      %68 = arith.select %67, %c-1_i32_21, %c1_i32_19 : i32
      %69 = arith.addi %68, %66#0 : i32
      %70 = arith.divsi %69, %c128_i32 : i32
      %71 = arith.addi %c1_i32_19, %70 : i32
      %72 = arith.subi %c0_i32_20, %66#0 : i32
      %73 = arith.divsi %72, %c128_i32 : i32
      %74 = arith.subi %c0_i32_20, %73 : i32
      %75 = arith.cmpi slt, %66#0, %c0_i32_20 : i32
      %76 = arith.cmpi sgt, %66#0, %c0_i32_20 : i32
      %77 = arith.cmpi slt, %c128_i32, %c0_i32_20 : i32
      %78 = arith.cmpi sgt, %c128_i32, %c0_i32_20 : i32
      %79 = arith.andi %75, %77 : i1
      %80 = arith.andi %76, %78 : i1
      %81 = arith.ori %79, %80 : i1
      %82 = arith.select %81, %71, %74 : i32
      %c1_i32_22 = arith.constant 1 : i32
      %c0_i32_23 = arith.constant 0 : i32
      %c-1_i32_24 = arith.constant -1 : i32
      %83 = arith.cmpi sgt, %c64_i32, %c0_i32_23 : i32
      %84 = arith.select %83, %c-1_i32_24, %c1_i32_22 : i32
      %85 = arith.addi %84, %66#1 : i32
      %86 = arith.divsi %85, %c64_i32 : i32
      %87 = arith.addi %c1_i32_22, %86 : i32
      %88 = arith.subi %c0_i32_23, %66#1 : i32
      %89 = arith.divsi %88, %c64_i32 : i32
      %90 = arith.subi %c0_i32_23, %89 : i32
      %91 = arith.cmpi slt, %66#1, %c0_i32_23 : i32
      %92 = arith.cmpi sgt, %66#1, %c0_i32_23 : i32
      %93 = arith.cmpi slt, %c64_i32, %c0_i32_23 : i32
      %94 = arith.cmpi sgt, %c64_i32, %c0_i32_23 : i32
      %95 = arith.andi %91, %93 : i1
      %96 = arith.andi %92, %94 : i1
      %97 = arith.ori %95, %96 : i1
      %98 = arith.select %97, %87, %90 : i32
      %shape = cute.make_shape(%82, %98) : (i32, i32) -> !cute.shape<"((128,64),(?,?))">
      %lay_25 = cute.make_layout(%shape, %18) : !cute.layout<"((128,64),(?,?)):((1@1,1@0),(128@1,64@0))">
      %99:2 = cute.get_scalars(%lay_25) <{only_dynamic}> : !cute.layout<"((128,64),(?,?)):((1@1,1@0),(128@1,64@0))">
      %shape_26 = cute.make_shape(%99#1) : (i32) -> !cute.shape<"(128,64,?)">
      %lay_27 = cute.make_layout(%shape_26, %17) : !cute.layout<"(128,64,?):(1@1,1@0,64@0)">
      %idx = cute.crd2idx(%coord_18, %lay_25) : (!cute.coord<"((_,_),(?,_))">, !cute.layout<"((128,64),(?,?)):((1@1,1@0),(128@1,64@0))">) -> !cute.int_tuple<"(0,?{div=128})">
      %tup = cute.add_offset(%16, %idx) : (!cute.int_tuple<"(0,0)">, !cute.int_tuple<"(0,?{div=128})">) -> !cute.int_tuple<"(0,?{div=128})">
      %coord_28 = cute.make_coord(%65#1) : (i32) -> !cute.coord<"((_,_),(?,_))">
      %lay_29 = cute.get_layout(%arg4) : !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">
      %100:2 = cute.get_scalars(%lay_29) <{only_dynamic}> : !cute.layout<"(?,?{div=8192}):(1@1,1@0)">
      %c1_i32_30 = arith.constant 1 : i32
      %c0_i32_31 = arith.constant 0 : i32
      %c-1_i32_32 = arith.constant -1 : i32
      %101 = arith.cmpi sgt, %c256_i32, %c0_i32_31 : i32
      %102 = arith.select %101, %c-1_i32_32, %c1_i32_30 : i32
      %103 = arith.addi %102, %100#0 : i32
      %104 = arith.divsi %103, %c256_i32 : i32
      %105 = arith.addi %c1_i32_30, %104 : i32
      %106 = arith.subi %c0_i32_31, %100#0 : i32
      %107 = arith.divsi %106, %c256_i32 : i32
      %108 = arith.subi %c0_i32_31, %107 : i32
      %109 = arith.cmpi slt, %100#0, %c0_i32_31 : i32
      %110 = arith.cmpi sgt, %100#0, %c0_i32_31 : i32
      %111 = arith.cmpi slt, %c256_i32, %c0_i32_31 : i32
      %112 = arith.cmpi sgt, %c256_i32, %c0_i32_31 : i32
      %113 = arith.andi %109, %111 : i1
      %114 = arith.andi %110, %112 : i1
      %115 = arith.ori %113, %114 : i1
      %116 = arith.select %115, %105, %108 : i32
      %c1_i32_33 = arith.constant 1 : i32
      %c0_i32_34 = arith.constant 0 : i32
      %c-1_i32_35 = arith.constant -1 : i32
      %117 = arith.cmpi sgt, %c64_i32, %c0_i32_34 : i32
      %118 = arith.select %117, %c-1_i32_35, %c1_i32_33 : i32
      %119 = arith.addi %118, %100#1 : i32
      %120 = arith.divsi %119, %c64_i32 : i32
      %121 = arith.addi %c1_i32_33, %120 : i32
      %122 = arith.subi %c0_i32_34, %100#1 : i32
      %123 = arith.divsi %122, %c64_i32 : i32
      %124 = arith.subi %c0_i32_34, %123 : i32
      %125 = arith.cmpi slt, %100#1, %c0_i32_34 : i32
      %126 = arith.cmpi sgt, %100#1, %c0_i32_34 : i32
      %127 = arith.cmpi slt, %c64_i32, %c0_i32_34 : i32
      %128 = arith.cmpi sgt, %c64_i32, %c0_i32_34 : i32
      %129 = arith.andi %125, %127 : i1
      %130 = arith.andi %126, %128 : i1
      %131 = arith.ori %129, %130 : i1
      %132 = arith.select %131, %121, %124 : i32
      %shape_36 = cute.make_shape(%116, %132) : (i32, i32) -> !cute.shape<"((256,64),(?,?))">
      %lay_37 = cute.make_layout(%shape_36, %15) : !cute.layout<"((256,64),(?,?)):((1@1,1@0),(256@1,64@0))">
      %133:2 = cute.get_scalars(%lay_37) <{only_dynamic}> : !cute.layout<"((256,64),(?,?)):((1@1,1@0),(256@1,64@0))">
      %shape_38 = cute.make_shape(%133#1) : (i32) -> !cute.shape<"(256,64,?)">
      %lay_39 = cute.make_layout(%shape_38, %17) : !cute.layout<"(256,64,?):(1@1,1@0,64@0)">
      %idx_40 = cute.crd2idx(%coord_28, %lay_37) : (!cute.coord<"((_,_),(?,_))">, !cute.layout<"((256,64),(?,?)):((1@1,1@0),(256@1,64@0))">) -> !cute.int_tuple<"(0,?{div=256})">
      %tup_41 = cute.add_offset(%16, %idx_40) : (!cute.int_tuple<"(0,0)">, !cute.int_tuple<"(0,?{div=256})">) -> !cute.int_tuple<"(0,?{div=256})">
      %coord_42 = cute.make_coord(%65#0, %65#1) : (i32, i32) -> !cute.coord<"((_,_),(?,?))">
      %lay_43 = cute.get_layout(%arg5) : !memref_gmem_f16_
      %134:3 = cute.get_scalars(%lay_43) <{only_dynamic}> : !cute.layout<"(?,?{div=8192}):(?{i64 div=8192},1)">
      %c1_i32_44 = arith.constant 1 : i32
      %c0_i32_45 = arith.constant 0 : i32
      %c-1_i32_46 = arith.constant -1 : i32
      %135 = arith.cmpi sgt, %c128_i32, %c0_i32_45 : i32
      %136 = arith.select %135, %c-1_i32_46, %c1_i32_44 : i32
      %137 = arith.addi %136, %134#0 : i32
      %138 = arith.divsi %137, %c128_i32 : i32
      %139 = arith.addi %c1_i32_44, %138 : i32
      %140 = arith.subi %c0_i32_45, %134#0 : i32
      %141 = arith.divsi %140, %c128_i32 : i32
      %142 = arith.subi %c0_i32_45, %141 : i32
      %143 = arith.cmpi slt, %134#0, %c0_i32_45 : i32
      %144 = arith.cmpi sgt, %134#0, %c0_i32_45 : i32
      %145 = arith.cmpi slt, %c128_i32, %c0_i32_45 : i32
      %146 = arith.cmpi sgt, %c128_i32, %c0_i32_45 : i32
      %147 = arith.andi %143, %145 : i1
      %148 = arith.andi %144, %146 : i1
      %149 = arith.ori %147, %148 : i1
      %150 = arith.select %149, %139, %142 : i32
      %151 = arith.muli %134#2, %c128_i64 : i64
      %c1_i32_47 = arith.constant 1 : i32
      %c0_i32_48 = arith.constant 0 : i32
      %c-1_i32_49 = arith.constant -1 : i32
      %152 = arith.cmpi sgt, %c256_i32, %c0_i32_48 : i32
      %153 = arith.select %152, %c-1_i32_49, %c1_i32_47 : i32
      %154 = arith.addi %153, %134#1 : i32
      %155 = arith.divsi %154, %c256_i32 : i32
      %156 = arith.addi %c1_i32_47, %155 : i32
      %157 = arith.subi %c0_i32_48, %134#1 : i32
      %158 = arith.divsi %157, %c256_i32 : i32
      %159 = arith.subi %c0_i32_48, %158 : i32
      %160 = arith.cmpi slt, %134#1, %c0_i32_48 : i32
      %161 = arith.cmpi sgt, %134#1, %c0_i32_48 : i32
      %162 = arith.cmpi slt, %c256_i32, %c0_i32_48 : i32
      %163 = arith.cmpi sgt, %c256_i32, %c0_i32_48 : i32
      %164 = arith.andi %160, %162 : i1
      %165 = arith.andi %161, %163 : i1
      %166 = arith.ori %164, %165 : i1
      %167 = arith.select %166, %156, %159 : i32
      %shape_50 = cute.make_shape(%150, %167) : (i32, i32) -> !cute.shape<"((128,256),(?,?))">
      %iv_51 = cute.assume(%134#2) : (i64) -> !cute.i64<divby 8192>
      %iv_52 = cute.assume(%151) : (i64) -> !cute.i64<divby 1048576>
      %stride = cute.make_stride(%iv_51, %iv_52) : (!cute.i64<divby 8192>, !cute.i64<divby 1048576>) -> !cute.stride<"((?{i64 div=8192},1),(?{i64 div=1048576},256))">
      %lay_53 = cute.make_layout(%shape_50, %stride) : !cute.layout<"((128,256),(?,?)):((?{i64 div=8192},1),(?{i64 div=1048576},256))">
      %168:4 = cute.get_scalars(%lay_53) <{only_dynamic}> : !cute.layout<"((128,256),(?,?)):((?{i64 div=8192},1),(?{i64 div=1048576},256))">
      %iv_54 = cute.assume(%168#2) : (i64) -> !cute.i64<divby 8192>
      %stride_55 = cute.make_stride(%iv_54) : (!cute.i64<divby 8192>) -> !cute.stride<"(?{i64 div=8192},1)">
      %lay_56 = cute.make_layout(%14, %stride_55) : !cute.layout<"(128,256):(?{i64 div=8192},1)">
      %idx_57 = cute.crd2idx(%coord_42, %lay_53) : (!cute.coord<"((_,_),(?,?))">, !cute.layout<"((128,256),(?,?)):((?{i64 div=8192},1),(?{i64 div=1048576},256))">) -> !cute.int_tuple<"?{i64 div=256}">
      %iter_58 = cute.get_iter(%arg5) : !memref_gmem_f16_
      %ptr_59 = cute.add_offset(%iter_58, %idx_57) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{i64 div=256}">) -> !cute.ptr<f16, gmem, align<32>>
      %169 = cute.get_scalars(%lay_27) <{only_dynamic}> : !cute.layout<"(128,64,?):(1@1,1@0,64@0)">
      %shape_60 = cute.make_shape(%169) : (i32) -> !cute.shape<"((128,16),1,4,?)">
      %lay_61 = cute.make_layout(%shape_60, %13) : !cute.layout<"((128,16),1,4,?):((1@1,1@0),0,16@0,64@0)">
      %170 = cute.get_scalars(%lay_39) <{only_dynamic}> : !cute.layout<"(256,64,?):(1@1,1@0,64@0)">
      %shape_62 = cute.make_shape(%170) : (i32) -> !cute.shape<"((256,16),1,4,?)">
      %lay_63 = cute.make_layout(%shape_62, %13) : !cute.layout<"((256,16),1,4,?):((1@1,1@0),0,16@0,64@0)">
      %171 = cute.get_scalars(%lay_56) <{only_dynamic}> : !cute.layout<"(128,256):(?{i64 div=8192},1)">
      %iv_64 = cute.assume(%171) : (i64) -> !cute.i64<divby 8192>
      %stride_65 = cute.make_stride(%iv_64) : (!cute.i64<divby 8192>) -> !cute.stride<"((?{i64 div=8192},1),0,0)">
      %lay_66 = cute.make_layout(%12, %stride_65) : !cute.layout<"((128,256),1,1):((?{i64 div=8192},1),0,0)">
      %ummaSmemDesc = cute_nvgpu.make_umma_smem_desc(%iter_4 : !cute.ptr<f16, smem, align<128>, S<3,4,3>>) layout = <"((128,16),1,4,4):((64,1),0,16,8192)">, major = <k> -> !cute_nvgpu.smem_desc
      %ummaSmemDesc_67 = cute_nvgpu.make_umma_smem_desc(%iter_5 : !cute.ptr<f16, smem, align<128>, S<3,4,3>>) layout = <"((256,16),1,4,4):((64,1),0,16,16384)">, major = <k> -> !cute_nvgpu.smem_desc
      %172 = cute.get_scalars(%lay_61) <{only_dynamic}> : !cute.layout<"((128,16),1,4,?):((1@1,1@0),0,16@0,64@0)">
      %shape_68 = cute.make_shape(%172) : (i32) -> !cute.shape<"(((128,16),1,4),?)">
      %lay_69 = cute.make_layout(%shape_68, %11) : !cute.layout<"(((128,16),1,4),?):(((1@1,1@0),0,16@0),64@0)">
      %173 = cute.get_scalars(%lay_69) <{only_dynamic}> : !cute.layout<"(((128,16),1,4),?):(((1@1,1@0),0,16@0),64@0)">
      %shape_70 = cute.make_shape(%173) : (i32) -> !cute.shape<"(((64,128),1),?)">
      %lay_71 = cute.make_layout(%shape_70, %10) : !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">
      %174 = cute.get_scalars(%lay_63) <{only_dynamic}> : !cute.layout<"((256,16),1,4,?):((1@1,1@0),0,16@0,64@0)">
      %shape_72 = cute.make_shape(%174) : (i32) -> !cute.shape<"(((256,16),1,4),?)">
      %lay_73 = cute.make_layout(%shape_72, %11) : !cute.layout<"(((256,16),1,4),?):(((1@1,1@0),0,16@0),64@0)">
      %175 = cute.get_scalars(%lay_73) <{only_dynamic}> : !cute.layout<"(((256,16),1,4),?):(((1@1,1@0),0,16@0),64@0)">
      %shape_74 = cute.make_shape(%175) : (i32) -> !cute.shape<"(((64,256),1),?)">
      %lay_75 = cute.make_layout(%shape_74, %10) : !cute.layout<"(((64,256),1),?):(((1@0,1@1),0),64@0)">
      nvvm.barrier id = %c1_i32 number_of_threads = %c128_i32
      %tmem_ptr = cute_nvgpu.arch.sm100.retrieve_tmem_ptr(%iter) : !cute.ptr<i32, smem, align<16>> -> !cute.ptr<f32, tmem, align<16>>
      %176 = cute.get_scalars(%lay_66) <{only_dynamic}> : !cute.layout<"((128,256),1,1):((?{i64 div=8192},1),0,0)">
      %iv_76 = cute.assume(%176) : (i64) -> !cute.i64<divby 8192>
      %stride_77 = cute.make_stride(%iv_76) : (!cute.i64<divby 8192>) -> !cute.stride<"(((?{i64 div=8192},1)),((0,64),0,0))">
      %lay_78 = cute.make_layout(%9, %stride_77) : !cute.layout<"(((128,64)),((1,4),1,1)):(((?{i64 div=8192},1)),((0,64),0,0))">
      %coord_79 = cute.make_coord(%27) : (i32) -> !cute.coord<"?">
      %177 = cute.get_scalars(%coord_79) <{only_dynamic}> : !cute.coord<"?">
      %178 = arith.divsi %177, %c32_i32 : i32
      %179 = arith.muli %178, %c2097152_i32 : i32
      %iv_80 = cute.assume(%179) : (i32) -> !cute.i32<divby 2097152>
      %int_tuple_81 = cute.make_int_tuple(%iv_80) : (!cute.i32<divby 2097152>) -> !cute.int_tuple<"?{div=2097152}">
      %ptr_82 = cute.add_offset(%tmem_ptr, %int_tuple_81) : (!cute.ptr<f32, tmem, align<16>>, !cute.int_tuple<"?{div=2097152}">) -> !cute.ptr<f32, tmem, align<16>>
      %180 = cute.get_scalars(%lay_78) <{only_dynamic}> : !cute.layout<"(((128,64)),((1,4),1,1)):(((?{i64 div=8192},1)),((0,64),0,0))">
      %181 = arith.muli %180, %c32_i64 : i64
      %182 = arith.remsi %177, %c32_i32 : i32
      %183 = arith.extsi %182 : i32 to i64
      %184 = arith.muli %183, %180 : i64
      %185 = arith.extsi %178 : i32 to i64
      %186 = arith.muli %185, %181 : i64
      %187 = arith.addi %184, %186 : i64
      %iv_83 = cute.assume(%187) : (i64) -> !cute.i64<divby 8192>
      %int_tuple_84 = cute.make_int_tuple(%iv_83) : (!cute.i64<divby 8192>) -> !cute.int_tuple<"?{i64 div=8192}">
      %ptr_85 = cute.add_offset(%ptr_59, %int_tuple_84) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{i64 div=8192}">) -> !cute.ptr<f16, gmem, align<32>>
      %rmem = cute.memref.alloca() : !memref_rmem_f32_
      %rmem_86 = cute.memref.alloca() : !memref_rmem_f16_
      %sz = cute.size(%lay_27) <{mode = [2]}> : (!cute.layout<"(128,64,?):(1@1,1@0,64@0)">) -> !cute.int_tuple<"?">
      %e0 = cute.get_leaves(%sz) : !cute.int_tuple<"?">
      %188 = cute.get_scalars(%e0) : !cute.int_tuple<"?">
      cf.cond_br %54, ^bb13, ^bb92
    ^bb13:  // pred: ^bb12
      %189 = builtin.unrealized_conversion_cast %ptr_17 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %189, %c1_i32, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %190 = cute_nvgpu.atom.make_exec_tma(%arg1) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128):(1@1,1@0)">>
      %191 = cute_nvgpu.atom.make_exec_tma(%arg3) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 262144, tma_gbasis = <"(64,256):(1@1,1@0)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_load<f16, copy_bits = 262144, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,256):(1@1,1@0)">>
      %192 = arith.cmpi slt, %188, %c2_i32 : i32
      %193 = arith.select %192, %188, %c2_i32 : i32
      %194 = cute.get_scalars(%22) : !cute.int_tuple<"1">
      cf.br ^bb14(%c0_i32, %c0_i32, %c1_i32, %c0_i32 : i32, i32, i32, i32)
    ^bb14(%195: i32, %196: i32, %197: i32, %198: i32):  // 2 preds: ^bb13, ^bb27
      %199 = arith.cmpi slt, %195, %193 : i32
      cf.cond_br %199, ^bb15, ^bb28
    ^bb15:  // pred: ^bb14
      %int_tuple_87 = cute.make_int_tuple(%196) : (i32) -> !cute.int_tuple<"?">
      %ptr_88 = cute.add_offset(%ptr_10, %int_tuple_87) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %200 = builtin.unrealized_conversion_cast %ptr_88 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %200, %197, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %201 = nvvm.elect.sync -> i1
      cf.cond_br %201, ^bb16, ^bb17
    ^bb16:  // pred: ^bb15
      %ptr_89 = cute.add_offset(%iter_6, %int_tuple_87) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %202 = builtin.unrealized_conversion_cast %ptr_89 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %202, %c49152_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
      cf.br ^bb17
    ^bb17:  // 2 preds: ^bb15, ^bb16
      %203 = arith.addi %196, %c1_i32 : i32
      %204 = arith.addi %198, %c1_i32 : i32
      %205 = arith.cmpi eq, %203, %c4_i32 : i32
      %206 = arith.select %205, %c0_i32, %203 : i32
      cf.cond_br %205, ^bb18, ^bb19
    ^bb18:  // pred: ^bb17
      %207 = arith.xori %197, %c1_i32 : i32
      cf.br ^bb20(%207 : i32)
    ^bb19:  // pred: ^bb17
      cf.br ^bb20(%197 : i32)
    ^bb20(%208: i32):  // 2 preds: ^bb18, ^bb19
      cf.br ^bb21
    ^bb21:  // pred: ^bb20
      %coord_90 = cute.make_coord(%198) : (i32) -> !cute.coord<"(_,?)">
      %idx_91 = cute.crd2idx(%coord_90, %lay_71) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
      %tup_92 = cute.add_offset(%tup, %idx_91) : (!cute.int_tuple<"(0,?{div=128})">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
      %e0_93, %e1 = cute.get_leaves(%tup_92) : !cute.int_tuple<"(?{div=64},?{div=128})">
      %coord_94 = cute.make_coord(%196) : (i32) -> !cute.coord<"(_,?)">
      %idx_95 = cute.crd2idx(%coord_94, %8) : (!cute.coord<"(_,?)">, !cute.layout<"((8192,1),4):((1,0),8192)">) -> !cute.int_tuple<"?{div=8192}">
      %ptr_96 = cute.add_offset(%iter_4, %idx_95) : (!cute.ptr<f16, smem, align<128>, S<3,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<f16, smem, align<128>, S<3,4,3>>
      %ptr_97 = cute.add_offset(%iter_6, %int_tuple_87) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %int_tuple_98 = cute.make_int_tuple(%e0_93, %e1) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=128}">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
      %209 = cute_nvgpu.atom.set_value(%190, %ptr_97 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128):(1@1,1@0)">>
      %210 = cute_nvgpu.atom.get_value(%209 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
      %TMADescAddr = cute_nvgpu.get_tma_desc_addr(%209 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128):(1@1,1@0)">>) -> !cute.ptr<generic, align<64>>
      %211:2 = cute.get_scalars(%int_tuple_98) : !cute.int_tuple<"(?{div=64},?{div=128})">
      cf.br ^bb22(%c0_i32 : i32)
    ^bb22(%212: i32):  // 2 preds: ^bb21, ^bb23
      %213 = arith.cmpi slt, %212, %194 : i32
      cf.cond_br %213, ^bb23, ^bb24 {llvm.loop_annotation = #loop_annotation}
    ^bb23:  // pred: ^bb22
      cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr : !cute.ptr<generic, align<64>>, %ptr_96 : !cute.ptr<f16, smem, align<128>, S<3,4,3>>, %210 : !cute.ptr<smem, align<8>>, [%211#0, %211#1] : i32, i32) mode = <tiled> num_cta = 1 : i32
      %214 = arith.addi %212, %c1_i32 : i32
      cf.br ^bb22(%214 : i32)
    ^bb24:  // pred: ^bb22
      %idx_99 = cute.crd2idx(%coord_90, %lay_75) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,256),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
      %tup_100 = cute.add_offset(%tup_41, %idx_99) : (!cute.int_tuple<"(0,?{div=256})">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.int_tuple<"(?{div=64},?{div=256})">
      %e0_101, %e1_102 = cute.get_leaves(%tup_100) : !cute.int_tuple<"(?{div=64},?{div=256})">
      %idx_103 = cute.crd2idx(%coord_94, %7) : (!cute.coord<"(_,?)">, !cute.layout<"((16384,1),4):((1,0),16384)">) -> !cute.int_tuple<"?{div=16384}">
      %ptr_104 = cute.add_offset(%iter_5, %idx_103) : (!cute.ptr<f16, smem, align<128>, S<3,4,3>>, !cute.int_tuple<"?{div=16384}">) -> !cute.ptr<f16, smem, align<128>, S<3,4,3>>
      %int_tuple_105 = cute.make_int_tuple(%e0_101, %e1_102) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=256}">) -> !cute.int_tuple<"(?{div=64},?{div=256})">
      %215 = cute_nvgpu.atom.set_value(%191, %ptr_97 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 262144, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,256):(1@1,1@0)">>
      %216 = cute_nvgpu.atom.get_value(%215 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 262144, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,256):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
      %TMADescAddr_106 = cute_nvgpu.get_tma_desc_addr(%215 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 262144, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,256):(1@1,1@0)">>) -> !cute.ptr<generic, align<64>>
      %217:2 = cute.get_scalars(%int_tuple_105) : !cute.int_tuple<"(?{div=64},?{div=256})">
      cf.br ^bb25(%c0_i32 : i32)
    ^bb25(%218: i32):  // 2 preds: ^bb24, ^bb26
      %219 = arith.cmpi slt, %218, %194 : i32
      cf.cond_br %219, ^bb26, ^bb27 {llvm.loop_annotation = #loop_annotation}
    ^bb26:  // pred: ^bb25
      cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr_106 : !cute.ptr<generic, align<64>>, %ptr_104 : !cute.ptr<f16, smem, align<128>, S<3,4,3>>, %216 : !cute.ptr<smem, align<8>>, [%217#0, %217#1] : i32, i32) mode = <tiled> num_cta = 1 : i32
      %220 = arith.addi %218, %c1_i32 : i32
      cf.br ^bb25(%220 : i32)
    ^bb27:  // pred: ^bb25
      %221 = arith.addi %195, %c1_i32 : i32
      cf.br ^bb14(%221, %206, %208, %204 : i32, i32, i32, i32)
    ^bb28:  // pred: ^bb14
      %222 = cute.get_scalars(%22) : !cute.int_tuple<"1">
      cf.br ^bb29(%c0_i32, %198, %196, %197, %c0_i32, %c0_i32, %c0_i32, %0 : i32, i32, i32, i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>)
    ^bb29(%223: i32, %224: i32, %225: i32, %226: i32, %227: i32, %228: i32, %229: i32, %230: !llvm.struct<(i1, i1, i1)>):  // 2 preds: ^bb28, ^bb88
      %231 = arith.cmpi slt, %223, %188 : i32
      cf.cond_br %231, ^bb30, ^bb89
    ^bb30:  // pred: ^bb29
      %232 = builtin.unrealized_conversion_cast %230 : !llvm.struct<(i1, i1, i1)> to !mma_f16_f16_f32_128x256x16_
      %233 = arith.addi %223, %193 : i32
      %234 = arith.cmpi ult, %233, %188 : i32
      cf.cond_br %234, ^bb31, ^bb44
    ^bb31:  // pred: ^bb30
      %int_tuple_107 = cute.make_int_tuple(%225) : (i32) -> !cute.int_tuple<"?">
      %ptr_108 = cute.add_offset(%ptr_10, %int_tuple_107) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %235 = builtin.unrealized_conversion_cast %ptr_108 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %235, %226, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %236 = nvvm.elect.sync -> i1
      cf.cond_br %236, ^bb32, ^bb33
    ^bb32:  // pred: ^bb31
      %ptr_109 = cute.add_offset(%iter_6, %int_tuple_107) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %237 = builtin.unrealized_conversion_cast %ptr_109 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %237, %c49152_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
      cf.br ^bb33
    ^bb33:  // 2 preds: ^bb31, ^bb32
      %238 = arith.addi %225, %c1_i32 : i32
      %239 = arith.addi %224, %c1_i32 : i32
      %240 = arith.cmpi eq, %238, %c4_i32 : i32
      %241 = arith.select %240, %c0_i32, %238 : i32
      cf.cond_br %240, ^bb34, ^bb35
    ^bb34:  // pred: ^bb33
      %242 = arith.xori %226, %c1_i32 : i32
      cf.br ^bb36(%242 : i32)
    ^bb35:  // pred: ^bb33
      cf.br ^bb36(%226 : i32)
    ^bb36(%243: i32):  // 2 preds: ^bb34, ^bb35
      cf.br ^bb37
    ^bb37:  // pred: ^bb36
      %coord_110 = cute.make_coord(%224) : (i32) -> !cute.coord<"(_,?)">
      %idx_111 = cute.crd2idx(%coord_110, %lay_71) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
      %tup_112 = cute.add_offset(%tup, %idx_111) : (!cute.int_tuple<"(0,?{div=128})">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
      %e0_113, %e1_114 = cute.get_leaves(%tup_112) : !cute.int_tuple<"(?{div=64},?{div=128})">
      %coord_115 = cute.make_coord(%225) : (i32) -> !cute.coord<"(_,?)">
      %idx_116 = cute.crd2idx(%coord_115, %8) : (!cute.coord<"(_,?)">, !cute.layout<"((8192,1),4):((1,0),8192)">) -> !cute.int_tuple<"?{div=8192}">
      %ptr_117 = cute.add_offset(%iter_4, %idx_116) : (!cute.ptr<f16, smem, align<128>, S<3,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<f16, smem, align<128>, S<3,4,3>>
      %ptr_118 = cute.add_offset(%iter_6, %int_tuple_107) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %int_tuple_119 = cute.make_int_tuple(%e0_113, %e1_114) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=128}">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
      %244 = cute_nvgpu.atom.set_value(%190, %ptr_118 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128):(1@1,1@0)">>
      %245 = cute.get_scalars(%22) : !cute.int_tuple<"1">
      %246 = cute_nvgpu.atom.get_value(%244 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
      %TMADescAddr_120 = cute_nvgpu.get_tma_desc_addr(%244 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128):(1@1,1@0)">>) -> !cute.ptr<generic, align<64>>
      %247:2 = cute.get_scalars(%int_tuple_119) : !cute.int_tuple<"(?{div=64},?{div=128})">
      cf.br ^bb38(%c0_i32 : i32)
    ^bb38(%248: i32):  // 2 preds: ^bb37, ^bb39
      %249 = arith.cmpi slt, %248, %245 : i32
      cf.cond_br %249, ^bb39, ^bb40 {llvm.loop_annotation = #loop_annotation}
    ^bb39:  // pred: ^bb38
      cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr_120 : !cute.ptr<generic, align<64>>, %ptr_117 : !cute.ptr<f16, smem, align<128>, S<3,4,3>>, %246 : !cute.ptr<smem, align<8>>, [%247#0, %247#1] : i32, i32) mode = <tiled> num_cta = 1 : i32
      %250 = arith.addi %248, %c1_i32 : i32
      cf.br ^bb38(%250 : i32)
    ^bb40:  // pred: ^bb38
      %idx_121 = cute.crd2idx(%coord_110, %lay_75) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,256),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
      %tup_122 = cute.add_offset(%tup_41, %idx_121) : (!cute.int_tuple<"(0,?{div=256})">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.int_tuple<"(?{div=64},?{div=256})">
      %e0_123, %e1_124 = cute.get_leaves(%tup_122) : !cute.int_tuple<"(?{div=64},?{div=256})">
      %idx_125 = cute.crd2idx(%coord_115, %7) : (!cute.coord<"(_,?)">, !cute.layout<"((16384,1),4):((1,0),16384)">) -> !cute.int_tuple<"?{div=16384}">
      %ptr_126 = cute.add_offset(%iter_5, %idx_125) : (!cute.ptr<f16, smem, align<128>, S<3,4,3>>, !cute.int_tuple<"?{div=16384}">) -> !cute.ptr<f16, smem, align<128>, S<3,4,3>>
      %int_tuple_127 = cute.make_int_tuple(%e0_123, %e1_124) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=256}">) -> !cute.int_tuple<"(?{div=64},?{div=256})">
      %251 = cute_nvgpu.atom.set_value(%191, %ptr_118 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 262144, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,256):(1@1,1@0)">>
      %252 = cute_nvgpu.atom.get_value(%251 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 262144, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,256):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
      %TMADescAddr_128 = cute_nvgpu.get_tma_desc_addr(%251 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 262144, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,256):(1@1,1@0)">>) -> !cute.ptr<generic, align<64>>
      %253:2 = cute.get_scalars(%int_tuple_127) : !cute.int_tuple<"(?{div=64},?{div=256})">
      cf.br ^bb41(%c0_i32 : i32)
    ^bb41(%254: i32):  // 2 preds: ^bb40, ^bb42
      %255 = arith.cmpi slt, %254, %245 : i32
      cf.cond_br %255, ^bb42, ^bb43 {llvm.loop_annotation = #loop_annotation}
    ^bb42:  // pred: ^bb41
      cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr_128 : !cute.ptr<generic, align<64>>, %ptr_126 : !cute.ptr<f16, smem, align<128>, S<3,4,3>>, %252 : !cute.ptr<smem, align<8>>, [%253#0, %253#1] : i32, i32) mode = <tiled> num_cta = 1 : i32
      %256 = arith.addi %254, %c1_i32 : i32
      cf.br ^bb41(%256 : i32)
    ^bb43:  // pred: ^bb41
      cf.br ^bb45(%241, %243, %239 : i32, i32, i32)
    ^bb44:  // pred: ^bb30
      cf.br ^bb45(%225, %226, %224 : i32, i32, i32)
    ^bb45(%257: i32, %258: i32, %259: i32):  // 2 preds: ^bb43, ^bb44
      cf.br ^bb46
    ^bb46:  // pred: ^bb45
      %int_tuple_129 = cute.make_int_tuple(%228) : (i32) -> !cute.int_tuple<"?">
      %ptr_130 = cute.add_offset(%iter_6, %int_tuple_129) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %260 = builtin.unrealized_conversion_cast %ptr_130 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %260, %229, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %261 = arith.addi %228, %c1_i32 : i32
      %262 = arith.addi %227, %c1_i32 : i32
      %263 = arith.cmpi eq, %261, %c4_i32 : i32
      %264 = arith.select %263, %c0_i32, %261 : i32
      cf.cond_br %263, ^bb47, ^bb48
    ^bb47:  // pred: ^bb46
      %265 = arith.xori %229, %c1_i32 : i32
      cf.br ^bb49(%265 : i32)
    ^bb48:  // pred: ^bb46
      cf.br ^bb49(%229 : i32)
    ^bb49(%266: i32):  // 2 preds: ^bb47, ^bb48
      cf.br ^bb50
    ^bb50:  // pred: ^bb49
      %coord_131 = cute.make_coord(%228) : (i32) -> !cute.coord<"(_,_,0,?)">
      %idx_132 = cute.crd2idx(%coord_131, %6) : (!cute.coord<"(_,_,0,?)">, !cute.layout<"(1,1,4,4):(0,0,2,1024)">) -> !cute.int_tuple<"?{div=1024}">
      %tup_133 = cute.add_offset(%ummaSmemDesc, %idx_132) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=1024}">) -> !cute_nvgpu.smem_desc
      %idx_134 = cute.crd2idx(%coord_131, %5) : (!cute.coord<"(_,_,0,?)">, !cute.layout<"(1,1,4,4):(0,0,2,2048)">) -> !cute.int_tuple<"?{div=2048}">
      %tup_135 = cute.add_offset(%ummaSmemDesc_67, %idx_134) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2048}">) -> !cute_nvgpu.smem_desc
      %267 = cute_nvgpu.atom.get_value(%232 : !mma_f16_f16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : i1
      %268 = cute_nvgpu.atom.get_value(%232 : !mma_f16_f16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : i1
      %269 = cute_nvgpu.atom.get_value(%232 : !mma_f16_f16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : i1
      %270 = arith.extui %267 : i1 to i32
      %271 = arith.extui %268 : i1 to i32
      %272 = arith.shli %270, %c13_i32 : i32
      %273 = arith.shli %271, %c14_i32 : i32
      %274 = arith.ori %272, %c138412048_i32 : i32
      %275 = arith.ori %274, %273 : i32
      cf.br ^bb51(%c0_i32 : i32)
    ^bb51(%276: i32):  // 2 preds: ^bb50, ^bb58
      %277 = arith.cmpi slt, %276, %222 : i32
      cf.cond_br %277, ^bb52, ^bb59 {llvm.loop_annotation = #loop_annotation}
    ^bb52:  // pred: ^bb51
      cf.br ^bb53(%c0_i32 : i32)
    ^bb53(%278: i32):  // 2 preds: ^bb52, ^bb57
      %279 = arith.cmpi slt, %278, %222 : i32
      cf.cond_br %279, ^bb54, ^bb58 {llvm.loop_annotation = #loop_annotation}
    ^bb54:  // pred: ^bb53
      cf.br ^bb55(%c0_i32 : i32)
    ^bb55(%280: i32):  // 2 preds: ^bb54, ^bb56
      %281 = arith.cmpi slt, %280, %222 : i32
      cf.cond_br %281, ^bb56, ^bb57 {llvm.loop_annotation = #loop_annotation}
    ^bb56:  // pred: ^bb55
      cute_nvgpu.arch.mma.SM100.umma(%tup_133, %tup_135, %tmem_ptr, %275, %269) {num_cta = 1 : i32, scale = 0 : i32, a_type = f16} : (!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, !cute.ptr<f32, tmem, align<16>>, i32, i1) -> ()
      %282 = arith.addi %280, %c1_i32 : i32
      cf.br ^bb55(%282 : i32)
    ^bb57:  // pred: ^bb55
      %283 = arith.addi %278, %c1_i32 : i32
      cf.br ^bb53(%283 : i32)
    ^bb58:  // pred: ^bb53
      %284 = arith.addi %276, %c1_i32 : i32
      cf.br ^bb51(%284 : i32)
    ^bb59:  // pred: ^bb51
      %285 = cute_nvgpu.atom.set_value(%232, %true : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_f16_f16_f32_128x256x16_
      %coord_136 = cute.make_coord(%228) : (i32) -> !cute.coord<"(_,_,1,?)">
      %idx_137 = cute.crd2idx(%coord_136, %6) : (!cute.coord<"(_,_,1,?)">, !cute.layout<"(1,1,4,4):(0,0,2,1024)">) -> !cute.int_tuple<"?{div=2}">
      %tup_138 = cute.add_offset(%ummaSmemDesc, %idx_137) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
      %idx_139 = cute.crd2idx(%coord_136, %5) : (!cute.coord<"(_,_,1,?)">, !cute.layout<"(1,1,4,4):(0,0,2,2048)">) -> !cute.int_tuple<"?{div=2}">
      %tup_140 = cute.add_offset(%ummaSmemDesc_67, %idx_139) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
      %286 = cute_nvgpu.atom.get_value(%285 : !mma_f16_f16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : i1
      %287 = cute_nvgpu.atom.get_value(%285 : !mma_f16_f16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : i1
      %288 = cute_nvgpu.atom.get_value(%285 : !mma_f16_f16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : i1
      %289 = arith.extui %286 : i1 to i32
      %290 = arith.extui %287 : i1 to i32
      %291 = arith.shli %289, %c13_i32 : i32
      %292 = arith.shli %290, %c14_i32 : i32
      %293 = arith.ori %291, %c138412048_i32 : i32
      %294 = arith.ori %293, %292 : i32
      cf.br ^bb60(%c0_i32 : i32)
    ^bb60(%295: i32):  // 2 preds: ^bb59, ^bb67
      %296 = arith.cmpi slt, %295, %222 : i32
      cf.cond_br %296, ^bb61, ^bb68 {llvm.loop_annotation = #loop_annotation}
    ^bb61:  // pred: ^bb60
      cf.br ^bb62(%c0_i32 : i32)
    ^bb62(%297: i32):  // 2 preds: ^bb61, ^bb66
      %298 = arith.cmpi slt, %297, %222 : i32
      cf.cond_br %298, ^bb63, ^bb67 {llvm.loop_annotation = #loop_annotation}
    ^bb63:  // pred: ^bb62
      cf.br ^bb64(%c0_i32 : i32)
    ^bb64(%299: i32):  // 2 preds: ^bb63, ^bb65
      %300 = arith.cmpi slt, %299, %222 : i32
      cf.cond_br %300, ^bb65, ^bb66 {llvm.loop_annotation = #loop_annotation}
    ^bb65:  // pred: ^bb64
      cute_nvgpu.arch.mma.SM100.umma(%tup_138, %tup_140, %tmem_ptr, %294, %288) {num_cta = 1 : i32, scale = 0 : i32, a_type = f16} : (!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, !cute.ptr<f32, tmem, align<16>>, i32, i1) -> ()
      %301 = arith.addi %299, %c1_i32 : i32
      cf.br ^bb64(%301 : i32)
    ^bb66:  // pred: ^bb64
      %302 = arith.addi %297, %c1_i32 : i32
      cf.br ^bb62(%302 : i32)
    ^bb67:  // pred: ^bb62
      %303 = arith.addi %295, %c1_i32 : i32
      cf.br ^bb60(%303 : i32)
    ^bb68:  // pred: ^bb60
      %304 = cute_nvgpu.atom.set_value(%285, %true : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_f16_f16_f32_128x256x16_
      %coord_141 = cute.make_coord(%228) : (i32) -> !cute.coord<"(_,_,2,?)">
      %idx_142 = cute.crd2idx(%coord_141, %6) : (!cute.coord<"(_,_,2,?)">, !cute.layout<"(1,1,4,4):(0,0,2,1024)">) -> !cute.int_tuple<"?{div=4}">
      %tup_143 = cute.add_offset(%ummaSmemDesc, %idx_142) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=4}">) -> !cute_nvgpu.smem_desc
      %idx_144 = cute.crd2idx(%coord_141, %5) : (!cute.coord<"(_,_,2,?)">, !cute.layout<"(1,1,4,4):(0,0,2,2048)">) -> !cute.int_tuple<"?{div=4}">
      %tup_145 = cute.add_offset(%ummaSmemDesc_67, %idx_144) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=4}">) -> !cute_nvgpu.smem_desc
      %305 = cute_nvgpu.atom.get_value(%304 : !mma_f16_f16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : i1
      %306 = cute_nvgpu.atom.get_value(%304 : !mma_f16_f16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : i1
      %307 = cute_nvgpu.atom.get_value(%304 : !mma_f16_f16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : i1
      %308 = arith.extui %305 : i1 to i32
      %309 = arith.extui %306 : i1 to i32
      %310 = arith.shli %308, %c13_i32 : i32
      %311 = arith.shli %309, %c14_i32 : i32
      %312 = arith.ori %310, %c138412048_i32 : i32
      %313 = arith.ori %312, %311 : i32
      cf.br ^bb69(%c0_i32 : i32)
    ^bb69(%314: i32):  // 2 preds: ^bb68, ^bb76
      %315 = arith.cmpi slt, %314, %222 : i32
      cf.cond_br %315, ^bb70, ^bb77 {llvm.loop_annotation = #loop_annotation}
    ^bb70:  // pred: ^bb69
      cf.br ^bb71(%c0_i32 : i32)
    ^bb71(%316: i32):  // 2 preds: ^bb70, ^bb75
      %317 = arith.cmpi slt, %316, %222 : i32
      cf.cond_br %317, ^bb72, ^bb76 {llvm.loop_annotation = #loop_annotation}
    ^bb72:  // pred: ^bb71
      cf.br ^bb73(%c0_i32 : i32)
    ^bb73(%318: i32):  // 2 preds: ^bb72, ^bb74
      %319 = arith.cmpi slt, %318, %222 : i32
      cf.cond_br %319, ^bb74, ^bb75 {llvm.loop_annotation = #loop_annotation}
    ^bb74:  // pred: ^bb73
      cute_nvgpu.arch.mma.SM100.umma(%tup_143, %tup_145, %tmem_ptr, %313, %307) {num_cta = 1 : i32, scale = 0 : i32, a_type = f16} : (!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, !cute.ptr<f32, tmem, align<16>>, i32, i1) -> ()
      %320 = arith.addi %318, %c1_i32 : i32
      cf.br ^bb73(%320 : i32)
    ^bb75:  // pred: ^bb73
      %321 = arith.addi %316, %c1_i32 : i32
      cf.br ^bb71(%321 : i32)
    ^bb76:  // pred: ^bb71
      %322 = arith.addi %314, %c1_i32 : i32
      cf.br ^bb69(%322 : i32)
    ^bb77:  // pred: ^bb69
      %323 = cute_nvgpu.atom.set_value(%304, %true : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_f16_f16_f32_128x256x16_
      %coord_146 = cute.make_coord(%228) : (i32) -> !cute.coord<"(_,_,3,?)">
      %idx_147 = cute.crd2idx(%coord_146, %6) : (!cute.coord<"(_,_,3,?)">, !cute.layout<"(1,1,4,4):(0,0,2,1024)">) -> !cute.int_tuple<"?{div=2}">
      %tup_148 = cute.add_offset(%ummaSmemDesc, %idx_147) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
      %idx_149 = cute.crd2idx(%coord_146, %5) : (!cute.coord<"(_,_,3,?)">, !cute.layout<"(1,1,4,4):(0,0,2,2048)">) -> !cute.int_tuple<"?{div=2}">
      %tup_150 = cute.add_offset(%ummaSmemDesc_67, %idx_149) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
      %324 = cute_nvgpu.atom.get_value(%323 : !mma_f16_f16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : i1
      %325 = cute_nvgpu.atom.get_value(%323 : !mma_f16_f16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : i1
      %326 = cute_nvgpu.atom.get_value(%323 : !mma_f16_f16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : i1
      %327 = arith.extui %324 : i1 to i32
      %328 = arith.extui %325 : i1 to i32
      %329 = arith.shli %327, %c13_i32 : i32
      %330 = arith.shli %328, %c14_i32 : i32
      %331 = arith.ori %329, %c138412048_i32 : i32
      %332 = arith.ori %331, %330 : i32
      cf.br ^bb78(%c0_i32 : i32)
    ^bb78(%333: i32):  // 2 preds: ^bb77, ^bb85
      %334 = arith.cmpi slt, %333, %222 : i32
      cf.cond_br %334, ^bb79, ^bb86 {llvm.loop_annotation = #loop_annotation}
    ^bb79:  // pred: ^bb78
      cf.br ^bb80(%c0_i32 : i32)
    ^bb80(%335: i32):  // 2 preds: ^bb79, ^bb84
      %336 = arith.cmpi slt, %335, %222 : i32
      cf.cond_br %336, ^bb81, ^bb85 {llvm.loop_annotation = #loop_annotation}
    ^bb81:  // pred: ^bb80
      cf.br ^bb82(%c0_i32 : i32)
    ^bb82(%337: i32):  // 2 preds: ^bb81, ^bb83
      %338 = arith.cmpi slt, %337, %222 : i32
      cf.cond_br %338, ^bb83, ^bb84 {llvm.loop_annotation = #loop_annotation}
    ^bb83:  // pred: ^bb82
      cute_nvgpu.arch.mma.SM100.umma(%tup_148, %tup_150, %tmem_ptr, %332, %326) {num_cta = 1 : i32, scale = 0 : i32, a_type = f16} : (!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, !cute.ptr<f32, tmem, align<16>>, i32, i1) -> ()
      %339 = arith.addi %337, %c1_i32 : i32
      cf.br ^bb82(%339 : i32)
    ^bb84:  // pred: ^bb82
      %340 = arith.addi %335, %c1_i32 : i32
      cf.br ^bb80(%340 : i32)
    ^bb85:  // pred: ^bb80
      %341 = arith.addi %333, %c1_i32 : i32
      cf.br ^bb78(%341 : i32)
    ^bb86:  // pred: ^bb78
      %342 = cute_nvgpu.atom.set_value(%323, %true : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_f16_f16_f32_128x256x16_
      %343 = builtin.unrealized_conversion_cast %342 : !mma_f16_f16_f32_128x256x16_ to !llvm.struct<(i1, i1, i1)>
      %344 = nvvm.elect.sync -> i1
      cf.cond_br %344, ^bb87, ^bb88
    ^bb87:  // pred: ^bb86
      %ptr_151 = cute.add_offset(%ptr_10, %int_tuple_129) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %345 = builtin.unrealized_conversion_cast %ptr_151 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.tcgen05.commit.arrive %345 : !llvm.ptr<3>
      cf.br ^bb88
    ^bb88:  // 2 preds: ^bb86, ^bb87
      %346 = arith.addi %223, %c1_i32 : i32
      cf.br ^bb29(%346, %259, %257, %258, %262, %264, %266, %343 : i32, i32, i32, i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>)
    ^bb89:  // pred: ^bb29
      %347 = nvvm.elect.sync -> i1
      cf.cond_br %347, ^bb90, ^bb91
    ^bb90:  // pred: ^bb89
      %dyn = cute.derefine(%iter_16) : !cute.ptr<i64, smem, align<64>> to !cute.ptr<i64, smem>
      %348 = builtin.unrealized_conversion_cast %dyn : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.tcgen05.commit.arrive %348 : !llvm.ptr<3>
      cf.br ^bb91
    ^bb91:  // 2 preds: ^bb89, ^bb90
      cf.br ^bb92
    ^bb92:  // 2 preds: ^bb12, ^bb91
      cf.cond_br %54, ^bb93, ^bb94
    ^bb93:  // pred: ^bb92
      cute_nvgpu.arch.sm100.relinquish_tmem_alloc_permit [ cta_1]
      cf.br ^bb94
    ^bb94:  // 2 preds: ^bb92, ^bb93
      %dyn_152 = cute.derefine(%iter_16) : !cute.ptr<i64, smem, align<64>> to !cute.ptr<i64, smem>
      %349 = builtin.unrealized_conversion_cast %dyn_152 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %349, %c0_i32, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %iter_153 = cute.get_iter(%rmem) : !memref_rmem_f32_
      %350 = cute.get_scalars(%22) : !cute.int_tuple<"1">
      %351 = builtin.unrealized_conversion_cast %iter_153 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
      %iter_154 = cute.get_iter(%rmem_86) : !memref_rmem_f16_
      %352 = cute.get_scalars(%1) : !cute.int_tuple<"8">
      cf.br ^bb95(%c0_i32 : i32)
    ^bb95(%353: i32):  // 2 preds: ^bb94, ^bb102
      %354 = arith.cmpi slt, %353, %c4_i32 : i32
      cf.cond_br %354, ^bb96, ^bb103
    ^bb96:  // pred: ^bb95
      %coord_155 = cute.make_coord(%353) : (i32) -> !cute.coord<"(_,_,?)">
      %idx_156 = cute.crd2idx(%coord_155, %4) : (!cute.coord<"(_,_,?)">, !cute.layout<"(((64,32),1),1,((1,4),1,1)):(((1,65536),0),0,((0,64),0,0))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_157 = cute.add_offset(%ptr_82, %idx_156) : (!cute.ptr<f32, tmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<f32, tmem, align<16>>
      cf.br ^bb97(%c0_i32 : i32)
    ^bb97(%355: i32):  // 2 preds: ^bb96, ^bb98
      %356 = arith.cmpi slt, %355, %350 : i32
      cf.cond_br %356, ^bb98, ^bb99 {llvm.loop_annotation = #loop_annotation}
    ^bb98:  // pred: ^bb97
      %357 = "cute_nvgpu.arch.copy.SM100.tmem_load"(%ptr_157) <{num_b = 32 : i32, num_dp = 32 : i32, num_rep = 64 : i32}> : (!cute.ptr<f32, tmem, align<16>>) -> vector<64xi32>
      llvm.store %357, %351 : vector<64xi32>, !llvm.ptr
      %358 = arith.addi %355, %c1_i32 : i32
      cf.br ^bb97(%358 : i32)
    ^bb99:  // pred: ^bb97
      %359 = cute.memref.load_vec %rmem, row_major : !memref_rmem_f32_
      %360 = arith.truncf %359 : vector<64xf32> to vector<64xf16>
      cute.memref.store_vec %360, %rmem_86, row_major : !memref_rmem_f16_
      %idx_158 = cute.crd2idx(%coord_155, %3) : (!cute.coord<"(_,_,?)">, !cute.layout<"((64,1),1,((1,4),1,1)):((1,0),0,((0,64),0,0))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_159 = cute.add_offset(%ptr_85, %idx_158) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<f16, gmem, align<32>>
      cf.br ^bb100(%c0_i32 : i32)
    ^bb100(%361: i32):  // 2 preds: ^bb99, ^bb101
      %362 = arith.cmpi slt, %361, %352 : i32
      cf.cond_br %362, ^bb101, ^bb102 {llvm.loop_annotation = #loop_annotation}
    ^bb101:  // pred: ^bb100
      %coord_160 = cute.make_coord(%361) : (i32) -> !cute.coord<"(_,?)">
      %idx_161 = cute.crd2idx(%coord_160, %2) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(8)):(1,(8))">) -> !cute.int_tuple<"?{div=8}">
      %ptr_162 = cute.add_offset(%iter_154, %idx_161) : (!cute.ptr<f16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
      %ptr_163 = cute.add_offset(%ptr_159, %idx_161) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, gmem, align<16>>
      %363 = builtin.unrealized_conversion_cast %ptr_162 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
      %364 = builtin.unrealized_conversion_cast %ptr_163 : !cute.ptr<f16, gmem, align<16>> to !llvm.ptr<1>
      %365 = llvm.load %363 {alignment = 16 : i64} : !llvm.ptr -> vector<8xf16>
      llvm.store %365, %364 {alignment = 16 : i64} : vector<8xf16>, !llvm.ptr<1>
      %366 = arith.addi %361, %c1_i32 : i32
      cf.br ^bb100(%366 : i32)
    ^bb102:  // pred: ^bb100
      %367 = arith.addi %353, %c1_i32 : i32
      cf.br ^bb95(%367 : i32)
    ^bb103:  // pred: ^bb95
      %368 = builtin.unrealized_conversion_cast %ptr_17 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %368, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>} : !llvm.ptr<3>, i32
      nvvm.barrier id = %c1_i32
      cf.cond_br %54, ^bb104, ^bb105
    ^bb104:  // pred: ^bb103
      cute_nvgpu.arch.sm100.dealloc_tmem(%tmem_ptr, %c512_i32) [ cta_1] : !cute.ptr<f32, tmem, align<16>>, i32
      cf.br ^bb105
    ^bb105:  // 2 preds: ^bb103, ^bb104
      return
    }
  }
  func.func @cutlass_host_function_Tensorgmemodiv8192i64div81921_Tensorgmemodiv8192i64div81921_Tensorgmemodiv8192i64div81921(%arg0: !memref_gmem_f16_, %arg1: !memref_gmem_f16_, %arg2: !memref_gmem_f16_) attributes {llvm.emit_c_interface} {
    %0 = llvm.mlir.constant(255 : i64) : i64
    %1 = llvm.mlir.constant(127 : i64) : i64
    %2 = llvm.mlir.constant(4539628424389459968 : i64) : i64
    %3 = llvm.mlir.constant(287506 : i64) : i64
    %c196736_i32 = arith.constant 196736 : i32
    %c128 = arith.constant 128 : index
    %c1 = arith.constant 1 : index
    %c256_i32 = arith.constant 256 : i32
    %c128_i32 = arith.constant 128 : i32
    %4 = cute.static : !cute.int_tuple<"(0,0)">
    %5 = cute.static : !cute.stride<"(1@1,1@0)">
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
    %atom = cute.make_atom() : () -> !cute_nvgpu.sm100.mma<128x256x16, num_cta = 1, ab_major = (k, k), elem_type = (f16, f16, f32), frag_kind = ss, c_scale_exp = 0>
    %6 = cute_nvgpu.atom.set_value(%atom, %false : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !cute_nvgpu.sm100.mma<128x256x16, num_cta = 1, ab_major = (k, k), elem_type = (f16, f16, f32), frag_kind = ss, c_scale_exp = 0>
    %7 = cute_nvgpu.atom.set_value(%6, %false : i1) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : !cute_nvgpu.sm100.mma<128x256x16, num_cta = 1, ab_major = (k, k), elem_type = (f16, f16, f32), frag_kind = ss, c_scale_exp = 0>
    %8 = cute_nvgpu.atom.set_value(%7, %false : i1) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : !cute_nvgpu.sm100.mma<128x256x16, num_cta = 1, ab_major = (k, k), elem_type = (f16, f16, f32), frag_kind = ss, c_scale_exp = 0>
    %9 = cute.make_tiled_mma(%8) : !mma_f16_f16_f32_128x256x16_
    %10 = llvm.alloca %c16_i32 x i64 {alignment = 64 : i64} : (i32) -> !llvm.ptr
    %iter = cute.get_iter(%arg0) : !memref_gmem_f16_
    %lay = cute.get_layout(%arg0) : !memref_gmem_f16_
    %11:3 = cute.get_scalars(%lay) <{only_dynamic}> : !cute.layout<"(?,?{div=8192}):(?{i64 div=8192},1)">
    %12 = arith.extui %11#1 : i32 to i64
    %13 = arith.extui %11#0 : i32 to i64
    %14 = llvm.mul %11#2, %c2_i64 : i64
    %15 = cute.ptrtoint(%iter) : !cute.ptr<f16, gmem, align<32>> to i64
    %16 = llvm.getelementptr %10[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %16 : i64, !llvm.ptr
    %17 = llvm.getelementptr %10[0, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %17 : i64, !llvm.ptr
    %18 = llvm.getelementptr %10[0, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %18 : i64, !llvm.ptr
    %19 = llvm.getelementptr %10[0, 3] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %19 : i64, !llvm.ptr
    %20 = llvm.getelementptr %10[0, 4] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %20 : i64, !llvm.ptr
    %21 = llvm.getelementptr %10[0, 5] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %21 : i64, !llvm.ptr
    %22 = llvm.getelementptr %10[0, 6] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %22 : i64, !llvm.ptr
    %23 = llvm.getelementptr %10[0, 7] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %23 : i64, !llvm.ptr
    %24 = llvm.getelementptr %10[0, 8] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %24 : i64, !llvm.ptr
    %25 = llvm.getelementptr %10[0, 9] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %25 : i64, !llvm.ptr
    %26 = llvm.getelementptr %10[0, 10] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %26 : i64, !llvm.ptr
    %27 = llvm.getelementptr %10[0, 11] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %27 : i64, !llvm.ptr
    %28 = llvm.getelementptr %10[0, 12] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %28 : i64, !llvm.ptr
    %29 = llvm.getelementptr %10[0, 13] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %29 : i64, !llvm.ptr
    %30 = llvm.getelementptr %10[0, 14] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %30 : i64, !llvm.ptr
    %31 = llvm.getelementptr %10[0, 15] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %31 : i64, !llvm.ptr
    %32 = llvm.udiv %15, %c16_i64 : i64
    %33 = llvm.and %32, %c9007199254740991_i64 : i64
    %34 = llvm.shl %33, %c4_i64 : i64
    llvm.store %34, %16 : i64, !llvm.ptr
    %35 = llvm.sub %13, %c1_i64 : i64
    %36 = llvm.sub %c1_i64, %c1_i64 : i64
    %37 = llvm.mul %35, %14 : i64
    %38 = llvm.mul %36, %c0_i64 : i64
    %39 = llvm.add %37, %38 : i64
    %40 = llvm.add %38, %38 : i64
    %41 = llvm.mul %12, %c16_i64 : i64
    %42 = llvm.udiv %41, %c8_i64 : i64
    %43 = llvm.add %42, %39 : i64
    %44 = llvm.add %43, %40 : i64
    %45 = llvm.icmp "uge" %44, %c131072_i64 : i64
    %46 = llvm.zext %45 : i1 to i64
    %47 = llvm.shl %46, %c21_i64 : i64
    %48 = llvm.udiv %14, %c16_i64 : i64
    %49 = llvm.shl %48, %c32_i64 : i64
    %50 = llvm.or %c0_i64, %47 : i64
    %51 = llvm.or %50, %49 : i64
    %52 = llvm.or %3, %51 : i64
    llvm.store %52, %17 : i64, !llvm.ptr
    %53 = llvm.udiv %c0_i64, %c16_i64 : i64
    %54 = llvm.and %53, %c4294967295_i64 : i64
    %55 = llvm.shl %54, %c0_i64 : i64
    %56 = llvm.shl %53, %c32_i64 : i64
    %57 = llvm.or %55, %56 : i64
    llvm.store %57, %18 : i64, !llvm.ptr
    %58 = llvm.lshr %14, %c36_i64 : i64
    %59 = llvm.and %58, %c15_i64 : i64
    %60 = llvm.shl %59, %c32_i64 : i64
    %61 = llvm.lshr %c0_i64, %c36_i64 : i64
    %62 = llvm.and %61, %c15_i64 : i64
    %63 = llvm.shl %62, %c36_i64 : i64
    %64 = llvm.shl %62, %c40_i64 : i64
    %65 = llvm.shl %61, %c44_i64 : i64
    %66 = llvm.or %60, %63 : i64
    %67 = llvm.or %64, %65 : i64
    %68 = llvm.or %66, %67 : i64
    %69 = llvm.or %55, %68 : i64
    llvm.store %69, %19 : i64, !llvm.ptr
    %70 = llvm.sub %12, %c1_i64 : i64
    %71 = llvm.and %70, %c4294967295_i64 : i64
    %72 = llvm.shl %71, %c0_i64 : i64
    %73 = llvm.shl %35, %c32_i64 : i64
    %74 = llvm.or %72, %73 : i64
    llvm.store %74, %20 : i64, !llvm.ptr
    %75 = llvm.and %36, %c4294967295_i64 : i64
    %76 = llvm.shl %75, %c0_i64 : i64
    %77 = llvm.shl %36, %c32_i64 : i64
    %78 = llvm.or %76, %77 : i64
    llvm.store %78, %21 : i64, !llvm.ptr
    %79 = llvm.or %75, %c0_i64 : i64
    %80 = llvm.or %79, %2 : i64
    llvm.store %80, %22 : i64, !llvm.ptr
    llvm.store %1, %23 : i64, !llvm.ptr
    %81 = builtin.unrealized_conversion_cast %10 : !llvm.ptr to !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>>
    %82 = cute.ptrtoint(%81) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>> to i64
    %83 = llvm.inttoptr %82 : i64 to !llvm.ptr
    %84 = llvm.load %83 {nontemporal} : !llvm.ptr -> !llvm.struct<(array<16 x i64>)>
    %85 = builtin.unrealized_conversion_cast %84 : !llvm.struct<(array<16 x i64>)> to !cute_nvgpu.tma_descriptor_tiled
    %atom_0 = cute.make_atom() : () -> !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, internal_val_type = f16>
    %86 = cute_nvgpu.atom.set_value(%atom_0, %85 : !cute_nvgpu.tma_descriptor_tiled) {field = #cute_nvgpu.atom_copy_field_non_exec_tma_load<tma_desc>} : !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, internal_val_type = f16>
    %87 = cute.get_shape(%lay) : (!cute.layout<"(?,?{div=8192}):(?{i64 div=8192},1)">) -> !cute.shape<"(?,?{div=8192})">
    %lay_1 = cute.make_layout(%87, %5) : !cute.layout<"(?,?{div=8192}):(1@1,1@0)">
    %view = cute.make_view(%4, %lay_1) : !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">
    %88 = llvm.alloca %c16_i32 x i64 {alignment = 64 : i64} : (i32) -> !llvm.ptr
    %iter_2 = cute.get_iter(%arg1) : !memref_gmem_f16_
    %lay_3 = cute.get_layout(%arg1) : !memref_gmem_f16_
    %89:3 = cute.get_scalars(%lay_3) <{only_dynamic}> : !cute.layout<"(?,?{div=8192}):(?{i64 div=8192},1)">
    %90 = arith.extui %89#1 : i32 to i64
    %91 = arith.extui %89#0 : i32 to i64
    %92 = llvm.mul %89#2, %c2_i64 : i64
    %93 = cute.ptrtoint(%iter_2) : !cute.ptr<f16, gmem, align<32>> to i64
    %94 = llvm.getelementptr %88[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %94 : i64, !llvm.ptr
    %95 = llvm.getelementptr %88[0, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %95 : i64, !llvm.ptr
    %96 = llvm.getelementptr %88[0, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %96 : i64, !llvm.ptr
    %97 = llvm.getelementptr %88[0, 3] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %97 : i64, !llvm.ptr
    %98 = llvm.getelementptr %88[0, 4] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %98 : i64, !llvm.ptr
    %99 = llvm.getelementptr %88[0, 5] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %99 : i64, !llvm.ptr
    %100 = llvm.getelementptr %88[0, 6] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %100 : i64, !llvm.ptr
    %101 = llvm.getelementptr %88[0, 7] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %101 : i64, !llvm.ptr
    %102 = llvm.getelementptr %88[0, 8] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %102 : i64, !llvm.ptr
    %103 = llvm.getelementptr %88[0, 9] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %103 : i64, !llvm.ptr
    %104 = llvm.getelementptr %88[0, 10] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %104 : i64, !llvm.ptr
    %105 = llvm.getelementptr %88[0, 11] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %105 : i64, !llvm.ptr
    %106 = llvm.getelementptr %88[0, 12] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %106 : i64, !llvm.ptr
    %107 = llvm.getelementptr %88[0, 13] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %107 : i64, !llvm.ptr
    %108 = llvm.getelementptr %88[0, 14] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %108 : i64, !llvm.ptr
    %109 = llvm.getelementptr %88[0, 15] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %109 : i64, !llvm.ptr
    %110 = llvm.udiv %93, %c16_i64 : i64
    %111 = llvm.and %110, %c9007199254740991_i64 : i64
    %112 = llvm.shl %111, %c4_i64 : i64
    llvm.store %112, %94 : i64, !llvm.ptr
    %113 = llvm.sub %91, %c1_i64 : i64
    %114 = llvm.mul %113, %92 : i64
    %115 = llvm.add %114, %38 : i64
    %116 = llvm.mul %90, %c16_i64 : i64
    %117 = llvm.udiv %116, %c8_i64 : i64
    %118 = llvm.add %117, %115 : i64
    %119 = llvm.add %118, %40 : i64
    %120 = llvm.icmp "uge" %119, %c131072_i64 : i64
    %121 = llvm.zext %120 : i1 to i64
    %122 = llvm.shl %121, %c21_i64 : i64
    %123 = llvm.udiv %92, %c16_i64 : i64
    %124 = llvm.shl %123, %c32_i64 : i64
    %125 = llvm.or %c0_i64, %122 : i64
    %126 = llvm.or %125, %124 : i64
    %127 = llvm.or %3, %126 : i64
    llvm.store %127, %95 : i64, !llvm.ptr
    llvm.store %57, %96 : i64, !llvm.ptr
    %128 = llvm.lshr %92, %c36_i64 : i64
    %129 = llvm.and %128, %c15_i64 : i64
    %130 = llvm.shl %129, %c32_i64 : i64
    %131 = llvm.or %130, %63 : i64
    %132 = llvm.or %131, %67 : i64
    %133 = llvm.or %55, %132 : i64
    llvm.store %133, %97 : i64, !llvm.ptr
    %134 = llvm.sub %90, %c1_i64 : i64
    %135 = llvm.and %134, %c4294967295_i64 : i64
    %136 = llvm.shl %135, %c0_i64 : i64
    %137 = llvm.shl %113, %c32_i64 : i64
    %138 = llvm.or %136, %137 : i64
    llvm.store %138, %98 : i64, !llvm.ptr
    llvm.store %78, %99 : i64, !llvm.ptr
    llvm.store %80, %100 : i64, !llvm.ptr
    llvm.store %0, %101 : i64, !llvm.ptr
    %139 = builtin.unrealized_conversion_cast %88 : !llvm.ptr to !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>>
    %140 = cute.ptrtoint(%139) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>> to i64
    %141 = llvm.inttoptr %140 : i64 to !llvm.ptr
    %142 = llvm.load %141 {nontemporal} : !llvm.ptr -> !llvm.struct<(array<16 x i64>)>
    %143 = builtin.unrealized_conversion_cast %142 : !llvm.struct<(array<16 x i64>)> to !cute_nvgpu.tma_descriptor_tiled
    %atom_4 = cute.make_atom() : () -> !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 262144, tma_gbasis = <"(64,256):(1@1,1@0)">, internal_val_type = f16>
    %144 = cute_nvgpu.atom.set_value(%atom_4, %143 : !cute_nvgpu.tma_descriptor_tiled) {field = #cute_nvgpu.atom_copy_field_non_exec_tma_load<tma_desc>} : !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 262144, tma_gbasis = <"(64,256):(1@1,1@0)">, internal_val_type = f16>
    %145 = cute.get_shape(%lay_3) : (!cute.layout<"(?,?{div=8192}):(?{i64 div=8192},1)">) -> !cute.shape<"(?,?{div=8192})">
    %lay_5 = cute.make_layout(%145, %5) : !cute.layout<"(?,?{div=8192}):(1@1,1@0)">
    %view_6 = cute.make_view(%4, %lay_5) : !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">
    %lay_7 = cute.get_layout(%arg2) : !memref_gmem_f16_
    %146 = cute.get_shape(%lay_7) : (!cute.layout<"(?,?{div=8192}):(?{i64 div=8192},1)">) -> !cute.shape<"(?,?{div=8192})">
    %e0, %e1 = cute.get_leaves(%146) : !cute.shape<"(?,?{div=8192})">
    %itup = cute.to_int_tuple(%e0) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %itup_8 = cute.to_int_tuple(%e1) : !cute.shape<"?{div=8192}"> to !cute.int_tuple<"?{div=8192}">
    %int_tuple = cute.make_int_tuple(%itup, %itup_8) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8192}">) -> !cute.int_tuple<"(?,?{div=8192},1)">
    %147:2 = cute.get_scalars(%int_tuple) <{only_dynamic}> : !cute.int_tuple<"(?,?{div=8192},1)">
    %c1_i32 = arith.constant 1 : i32
    %c0_i32 = arith.constant 0 : i32
    %c-1_i32 = arith.constant -1 : i32
    %148 = arith.cmpi sgt, %c128_i32, %c0_i32 : i32
    %149 = arith.select %148, %c-1_i32, %c1_i32 : i32
    %150 = arith.addi %149, %147#0 : i32
    %151 = arith.divsi %150, %c128_i32 : i32
    %152 = arith.addi %c1_i32, %151 : i32
    %153 = arith.subi %c0_i32, %147#0 : i32
    %154 = arith.divsi %153, %c128_i32 : i32
    %155 = arith.subi %c0_i32, %154 : i32
    %156 = arith.cmpi slt, %147#0, %c0_i32 : i32
    %157 = arith.cmpi sgt, %147#0, %c0_i32 : i32
    %158 = arith.cmpi slt, %c128_i32, %c0_i32 : i32
    %159 = arith.cmpi sgt, %c128_i32, %c0_i32 : i32
    %160 = arith.andi %156, %158 : i1
    %161 = arith.andi %157, %159 : i1
    %162 = arith.ori %160, %161 : i1
    %163 = arith.select %162, %152, %155 : i32
    %c1_i32_9 = arith.constant 1 : i32
    %c0_i32_10 = arith.constant 0 : i32
    %c-1_i32_11 = arith.constant -1 : i32
    %164 = arith.cmpi sgt, %c256_i32, %c0_i32_10 : i32
    %165 = arith.select %164, %c-1_i32_11, %c1_i32_9 : i32
    %166 = arith.addi %165, %147#1 : i32
    %167 = arith.divsi %166, %c256_i32 : i32
    %168 = arith.addi %c1_i32_9, %167 : i32
    %169 = arith.subi %c0_i32_10, %147#1 : i32
    %170 = arith.divsi %169, %c256_i32 : i32
    %171 = arith.subi %c0_i32_10, %170 : i32
    %172 = arith.cmpi slt, %147#1, %c0_i32_10 : i32
    %173 = arith.cmpi sgt, %147#1, %c0_i32_10 : i32
    %174 = arith.cmpi slt, %c256_i32, %c0_i32_10 : i32
    %175 = arith.cmpi sgt, %c256_i32, %c0_i32_10 : i32
    %176 = arith.andi %172, %174 : i1
    %177 = arith.andi %173, %175 : i1
    %178 = arith.ori %176, %177 : i1
    %179 = arith.select %178, %168, %171 : i32
    %int_tuple_12 = cute.make_int_tuple(%163, %179) : (i32, i32) -> !cute.int_tuple<"(?,?,1)">
    %e0_13, %e1_14, %e2 = cute.get_leaves(%int_tuple_12) : !cute.int_tuple<"(?,?,1)">
    %180 = cute.get_scalars(%e0_13) : !cute.int_tuple<"?">
    %181 = cute.get_scalars(%e1_14) : !cute.int_tuple<"?">
    %182 = arith.index_cast %180 : i32 to index
    %183 = arith.index_cast %181 : i32 to index
    gpu.launch_func  @kernels::@kernel_cutlass_kernel_TiledMMA_ThrLayoutVMNK11110000_PermutationMNK____MMAAtom_ThrID10_ShapeMNK12825616_TVLayoutA1128161281128_TVLayoutB1256162561256_TVLayoutC11282561281128_CopyAtom_ThrI_0 blocks in (%182, %183, %c1) threads in (%c128, %c1, %c1)  dynamic_shared_memory_size %c196736_i32 args(%9 : !mma_f16_f16_f32_128x256x16_, %86 : !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, internal_val_type = f16>, %view : !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">, %144 : !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 262144, tma_gbasis = <"(64,256):(1@1,1@0)">, internal_val_type = f16>, %view_6 : !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">, %arg2 : !memref_gmem_f16_) {use_pdl = false}
    return
  }
}
