!memref_gmem_f16_ = !cute.memref<f16, gmem, align<32>, "(?,?{div=8192}):(?{i64 div=8192},1)">
!memref_rmem_f16_ = !cute.memref<f16, rmem, align<32>, "((64,1),1):((1,0),0)">
!memref_rmem_f32_ = !cute.memref<f32, rmem, align<32>, "((64,1),1):((1,0),0)">
!mma_f16_f16_f32_128x256x16_ = !cute.tiled_mma<!cute_nvgpu.sm100.mma<128x256x16, num_cta = 1, ab_major = (k, k), elem_type = (f16, f16, f32), frag_kind = ss, c_scale_exp = 0>, atom_layout_MNK = <"(1,1,1):(0,0,0)">>
#loop_unroll = #llvm.loop_unroll<disable = false, full = true>
#loop_annotation = #llvm.loop_annotation<unroll = #loop_unroll>
module attributes {gpu.container_module} {
  gpu.module @kernels {
    cuda.kernel @kernel_cutlass_kernel_TiledMMA_ThrLayoutVMNK11110000_PermutationMNK____MMAAtom_ThrID10_ShapeMNK12825616_TVLayoutA1128161281128_TVLayoutB1256162561256_TVLayoutC11282561281128_CopyAtom_ThrI_0(%arg0: !mma_f16_f16_f32_128x256x16_, %arg1: !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, internal_val_type = f16>, %arg2: !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">, %arg3: !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 262144, tma_gbasis = <"(64,256):(1@1,1@0)">, internal_val_type = f16>, %arg4: !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">, %arg5: !memref_gmem_f16_) attributes {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} {
      %c127_i32 = arith.constant 127 : i32
      %0 = cute.static : !cute.layout<"(16,(4)):(1,(16))">
      %1 = cute.static : !cute.layout<"((64,1),1,((1,4),1,1)):((1,0),0,((0,64),0,0))">
      %2 = cute.static : !cute.layout<"(((64,32),1),1,((1,4),1,1)):(((1,65536),0),0,((0,64),0,0))">
      %c14_i32 = arith.constant 14 : i32
      %c13_i32 = arith.constant 13 : i32
      %c138412048_i32 = arith.constant 138412048 : i32
      %3 = cute.static : !cute.layout<"(1,1,4,4):(0,0,2,2048)">
      %4 = cute.static : !cute.layout<"(1,1,4,4):(0,0,2,1024)">
      %5 = cute.static : !cute.layout<"((16384,1),4):((1,0),16384)">
      %6 = cute.static : !cute.layout<"((8192,1),4):((1,0),8192)">
      %c49152_i32 = arith.constant 49152 : i32
      %c2_i32 = arith.constant 2 : i32
      %c4_i32 = arith.constant 4 : i32
      %c10000000_i32 = arith.constant 10000000 : i32
      %true = arith.constant true
      %c32_i64 = arith.constant 32 : i64
      %c2097152_i32 = arith.constant 2097152 : i32
      %7 = cute.static : !cute.shape<"(((128,64)),((1,4),1,1))">
      %8 = cute.static : !cute.stride<"(((1@0,1@1),0),64@0)">
      %9 = cute.static : !cute.stride<"(((1@1,1@0),0,16@0),64@0)">
      %10 = cute.static : !cute.shape<"((128,256),1,1)">
      %11 = cute.static : !cute.stride<"((1@1,1@0),0,16@0,64@0)">
      %12 = cute.static : !cute.shape<"(128,256)">
      %c128_i64 = arith.constant 128 : i64
      %13 = cute.static : !cute.stride<"((1@1,1@0),(256@1,64@0))">
      %c256_i32 = arith.constant 256 : i32
      %14 = cute.static : !cute.int_tuple<"(0,0)">
      %15 = cute.static : !cute.stride<"(1@1,1@0,64@0)">
      %16 = cute.static : !cute.stride<"((1@1,1@0),(128@1,64@0))">
      %c64_i32 = arith.constant 64 : i32
      %17 = cute.static : !cute.int_tuple<"4">
      %18 = cute.static : !cute.int_tuple<"3">
      %19 = cute.static : !cute.int_tuple<"2">
      %20 = cute.static : !cute.int_tuple<"1">
      %c512_i32 = arith.constant 512 : i32
      %c0_i32 = arith.constant 0 : i32
      %21 = cute.static : !cute.int_tuple<"65536">
      %c-128_i32 = arith.constant -128 : i32
      %c1_i32 = arith.constant 1 : i32
      %c128_i32 = arith.constant 128 : i32
      %22 = cute.static : !cute.int_tuple<"80">
      %23 = cute.static : !cute.int_tuple<"64">
      %24 = cute.static : !cute.int_tuple<"88">
      %c32_i32 = arith.constant 32 : i32
      %25 = nvvm.read.ptx.sreg.tid.x range <i32, 0, 1024> : i32
      %26 = nvvm.read.ptx.sreg.tid.x range <i32, 0, 1024> : i32
      %27 = nvvm.read.ptx.sreg.tid.y range <i32, 0, 1024> : i32
      %28 = nvvm.read.ptx.sreg.tid.z range <i32, 0, 64> : i32
      %29 = nvvm.read.ptx.sreg.ntid.x range <i32, 1, 1024> : i32
      %30 = nvvm.read.ptx.sreg.ntid.y range <i32, 1, 1024> : i32
      %31 = arith.muli %27, %29 : i32
      %32 = arith.addi %26, %31 : i32
      %33 = arith.muli %28, %29 : i32
      %34 = arith.muli %33, %30 : i32
      %35 = arith.addi %32, %34 : i32
      %36 = arith.floordivsi %35, %c32_i32 : i32
      %37 = cute_nvgpu.arch.make_warp_uniform(%36) : i32
      %38 = nvvm.read.ptx.sreg.ctaid.x range <i32, 0, 2147483647> : i32
      %39 = nvvm.read.ptx.sreg.ctaid.y range <i32, 0, 65535> : i32
      %smem_ptr = cute_nvgpu.arch.get_dyn_smem() : !cute.ptr<i8, smem, align<1024>>
      %ptr = cute.add_offset(%smem_ptr, %24) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"88">) -> !cute.ptr<i8, smem, align<8>>
      %ptr_0 = cute.add_offset(%smem_ptr, %23) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"64">) -> !cute.ptr<i8, smem, align<64>>
      %ptr_1 = cute.add_offset(%smem_ptr, %22) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"80">) -> !cute.ptr<i8, smem, align<16>>
      %iter = cute.recast_iter(%ptr_1) : !cute.ptr<i8, smem, align<16>> to !cute.ptr<i32, smem, align<16>>
      %40 = cute.ptrtoint(%ptr) : !cute.ptr<i8, smem, align<8>> to i32
      %41 = arith.addi %40, %c127_i32 : i32
      %42 = arith.andi %41, %c-128_i32 : i32
      %43 = arith.extsi %42 : i32 to i64
      %iv = cute.assume(%43) : (i64) -> !cute.i64<divby 128>
      %44 = cute.inttoptr(%iv) : !cute.i64<divby 128> to !cute.ptr<i8, smem, align<128>>
      %ptr_2 = cute.add_offset(%44, %21) : (!cute.ptr<i8, smem, align<128>>, !cute.int_tuple<"65536">) -> !cute.ptr<i8, smem, align<128>>
      %iter_3 = cute.recast_iter(%44) : !cute.ptr<i8, smem, align<128>> to !cute.ptr<f16, smem, align<128>, S<3,4,3>>
      %iter_4 = cute.recast_iter(%ptr_2) : !cute.ptr<i8, smem, align<128>> to !cute.ptr<f16, smem, align<128>, S<3,4,3>>
      %45 = nvvm.read.ptx.sreg.tid.x range <i32, 0, 1024> : i32
      %46 = nvvm.read.ptx.sreg.tid.y range <i32, 0, 1024> : i32
      %47 = nvvm.read.ptx.sreg.tid.z range <i32, 0, 64> : i32
      %48 = nvvm.read.ptx.sreg.ntid.x range <i32, 1, 1024> : i32
      %49 = nvvm.read.ptx.sreg.ntid.y range <i32, 1, 1024> : i32
      %50 = arith.muli %46, %48 : i32
      %51 = arith.addi %45, %50 : i32
      %52 = arith.muli %47, %48 : i32
      %53 = arith.muli %52, %49 : i32
      %54 = arith.addi %51, %53 : i32
      %55 = arith.floordivsi %54, %c32_i32 : i32
      %56 = cute_nvgpu.arch.make_warp_uniform(%55) : i32
      %57 = arith.cmpi eq, %56, %c0_i32 : i32
      scf.if %57 {
        cute_nvgpu.arch.sm100.alloc_tmem(%c512_i32, %iter) [ cta_1] : i32, !cute.ptr<i32, smem, align<16>>
      }
      %58 = arith.cmpi eq, %37, %c0_i32 : i32
      scf.if %58 {
        cute_nvgpu.prefetch_tma_desc(%arg1) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, internal_val_type = f16>) -> ()
        cute_nvgpu.prefetch_tma_desc(%arg3) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 262144, tma_gbasis = <"(64,256):(1@1,1@0)">, internal_val_type = f16>) -> ()
      }
      %iter_5 = cute.recast_iter(%smem_ptr) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<i64, smem, align<1024>>
      %59 = nvvm.read.ptx.sreg.tid.x range <i32, 0, 1024> : i32
      %60 = nvvm.read.ptx.sreg.tid.y range <i32, 0, 1024> : i32
      %61 = nvvm.read.ptx.sreg.tid.z range <i32, 0, 64> : i32
      %62 = nvvm.read.ptx.sreg.ntid.x range <i32, 1, 1024> : i32
      %63 = nvvm.read.ptx.sreg.ntid.y range <i32, 1, 1024> : i32
      %64 = arith.muli %60, %62 : i32
      %65 = arith.addi %59, %64 : i32
      %66 = arith.muli %61, %62 : i32
      %67 = arith.muli %66, %63 : i32
      %68 = arith.addi %65, %67 : i32
      %69 = arith.floordivsi %68, %c32_i32 : i32
      %70 = cute_nvgpu.arch.make_warp_uniform(%69) : i32
      %71 = arith.cmpi eq, %70, %c0_i32 : i32
      scf.if %71 {
        %178 = builtin.unrealized_conversion_cast %iter_5 : !cute.ptr<i64, smem, align<1024>> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %178, %c1_i32 : !llvm.ptr<3>, i32
        %ptr_62 = cute.add_offset(%iter_5, %20) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"1">) -> !cute.ptr<i64, smem>
        %179 = builtin.unrealized_conversion_cast %ptr_62 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %179, %c1_i32 : !llvm.ptr<3>, i32
        %ptr_63 = cute.add_offset(%iter_5, %19) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"2">) -> !cute.ptr<i64, smem, align<16>>
        %180 = builtin.unrealized_conversion_cast %ptr_63 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %180, %c1_i32 : !llvm.ptr<3>, i32
        %ptr_64 = cute.add_offset(%iter_5, %18) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"3">) -> !cute.ptr<i64, smem>
        %181 = builtin.unrealized_conversion_cast %ptr_64 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %181, %c1_i32 : !llvm.ptr<3>, i32
      }
      %ptr_6 = cute.add_offset(%iter_5, %17) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"4">) -> !cute.ptr<i64, smem, align<32>>
      %72 = nvvm.read.ptx.sreg.tid.x range <i32, 0, 1024> : i32
      %73 = nvvm.read.ptx.sreg.tid.y range <i32, 0, 1024> : i32
      %74 = nvvm.read.ptx.sreg.tid.z range <i32, 0, 64> : i32
      %75 = nvvm.read.ptx.sreg.ntid.x range <i32, 1, 1024> : i32
      %76 = nvvm.read.ptx.sreg.ntid.y range <i32, 1, 1024> : i32
      %77 = arith.muli %73, %75 : i32
      %78 = arith.addi %72, %77 : i32
      %79 = arith.muli %74, %75 : i32
      %80 = arith.muli %79, %76 : i32
      %81 = arith.addi %78, %80 : i32
      %82 = arith.floordivsi %81, %c32_i32 : i32
      %83 = cute_nvgpu.arch.make_warp_uniform(%82) : i32
      %84 = arith.cmpi eq, %83, %c0_i32 : i32
      scf.if %84 {
        %178 = builtin.unrealized_conversion_cast %ptr_6 : !cute.ptr<i64, smem, align<32>> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %178, %c1_i32 : !llvm.ptr<3>, i32
        %int_tuple_62 = cute.make_int_tuple() : () -> !cute.int_tuple<"5">
        %ptr_63 = cute.add_offset(%iter_5, %int_tuple_62) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"5">) -> !cute.ptr<i64, smem>
        %179 = builtin.unrealized_conversion_cast %ptr_63 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %179, %c1_i32 : !llvm.ptr<3>, i32
        %int_tuple_64 = cute.make_int_tuple() : () -> !cute.int_tuple<"6">
        %ptr_65 = cute.add_offset(%iter_5, %int_tuple_64) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"6">) -> !cute.ptr<i64, smem, align<16>>
        %180 = builtin.unrealized_conversion_cast %ptr_65 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %180, %c1_i32 : !llvm.ptr<3>, i32
        %int_tuple_66 = cute.make_int_tuple() : () -> !cute.int_tuple<"7">
        %ptr_67 = cute.add_offset(%iter_5, %int_tuple_66) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"7">) -> !cute.ptr<i64, smem>
        %181 = builtin.unrealized_conversion_cast %ptr_67 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %181, %c1_i32 : !llvm.ptr<3>, i32
      }
      nvvm.fence.mbarrier.init
      nvvm.barrier
      %iter_7 = cute.recast_iter(%ptr_0) : !cute.ptr<i8, smem, align<64>> to !cute.ptr<i64, smem, align<64>>
      %85 = nvvm.read.ptx.sreg.tid.x range <i32, 0, 1024> : i32
      %86 = nvvm.read.ptx.sreg.tid.y range <i32, 0, 1024> : i32
      %87 = nvvm.read.ptx.sreg.tid.z range <i32, 0, 64> : i32
      %88 = nvvm.read.ptx.sreg.ntid.x range <i32, 1, 1024> : i32
      %89 = nvvm.read.ptx.sreg.ntid.y range <i32, 1, 1024> : i32
      %90 = arith.muli %86, %88 : i32
      %91 = arith.addi %85, %90 : i32
      %92 = arith.muli %87, %88 : i32
      %93 = arith.muli %92, %89 : i32
      %94 = arith.addi %91, %93 : i32
      %95 = arith.floordivsi %94, %c32_i32 : i32
      %96 = cute_nvgpu.arch.make_warp_uniform(%95) : i32
      %97 = arith.cmpi eq, %96, %c0_i32 : i32
      scf.if %97 {
        %178 = builtin.unrealized_conversion_cast %iter_7 : !cute.ptr<i64, smem, align<64>> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %178, %c1_i32 : !llvm.ptr<3>, i32
      }
      %ptr_8 = cute.add_offset(%iter_7, %20) : (!cute.ptr<i64, smem, align<64>>, !cute.int_tuple<"1">) -> !cute.ptr<i64, smem>
      %98 = nvvm.read.ptx.sreg.tid.x range <i32, 0, 1024> : i32
      %99 = nvvm.read.ptx.sreg.tid.y range <i32, 0, 1024> : i32
      %100 = nvvm.read.ptx.sreg.tid.z range <i32, 0, 64> : i32
      %101 = nvvm.read.ptx.sreg.ntid.x range <i32, 1, 1024> : i32
      %102 = nvvm.read.ptx.sreg.ntid.y range <i32, 1, 1024> : i32
      %103 = arith.muli %99, %101 : i32
      %104 = arith.addi %98, %103 : i32
      %105 = arith.muli %100, %101 : i32
      %106 = arith.muli %105, %102 : i32
      %107 = arith.addi %104, %106 : i32
      %108 = arith.floordivsi %107, %c32_i32 : i32
      %109 = cute_nvgpu.arch.make_warp_uniform(%108) : i32
      %110 = arith.cmpi eq, %109, %c0_i32 : i32
      scf.if %110 {
        %178 = builtin.unrealized_conversion_cast %ptr_8 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %178, %c128_i32 : !llvm.ptr<3>, i32
      }
      nvvm.fence.mbarrier.init
      nvvm.barrier
      %coord = cute.make_coord(%38, %39) : (i32, i32) -> !cute.coord<"(?,?,_)">
      %111:2 = cute.get_scalars(%coord) <{only_dynamic}> : !cute.coord<"(?,?,_)">
      %coord_9 = cute.make_coord(%111#0) : (i32) -> !cute.coord<"((_,_),(?,_))">
      %lay = cute.get_layout(%arg2) : !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">
      %112:2 = cute.get_scalars(%lay) <{only_dynamic}> : !cute.layout<"(?,?{div=8192}):(1@1,1@0)">
      %113 = arith.ceildivsi %112#0, %c128_i32 : i32
      %114 = arith.ceildivsi %112#1, %c64_i32 : i32
      %shape = cute.make_shape(%113, %114) : (i32, i32) -> !cute.shape<"((128,64),(?,?))">
      %lay_10 = cute.make_layout(%shape, %16) : !cute.layout<"((128,64),(?,?)):((1@1,1@0),(128@1,64@0))">
      %115:2 = cute.get_scalars(%lay_10) <{only_dynamic}> : !cute.layout<"((128,64),(?,?)):((1@1,1@0),(128@1,64@0))">
      %shape_11 = cute.make_shape(%115#1) : (i32) -> !cute.shape<"(128,64,?)">
      %lay_12 = cute.make_layout(%shape_11, %15) : !cute.layout<"(128,64,?):(1@1,1@0,64@0)">
      %idx = cute.crd2idx(%coord_9, %lay_10) : (!cute.coord<"((_,_),(?,_))">, !cute.layout<"((128,64),(?,?)):((1@1,1@0),(128@1,64@0))">) -> !cute.int_tuple<"(0,?{div=128})">
      %tup = cute.add_offset(%14, %idx) : (!cute.int_tuple<"(0,0)">, !cute.int_tuple<"(0,?{div=128})">) -> !cute.int_tuple<"(0,?{div=128})">
      %coord_13 = cute.make_coord(%38, %39) : (i32, i32) -> !cute.coord<"(?,?,_)">
      %116:2 = cute.get_scalars(%coord_13) <{only_dynamic}> : !cute.coord<"(?,?,_)">
      %coord_14 = cute.make_coord(%116#1) : (i32) -> !cute.coord<"((_,_),(?,_))">
      %lay_15 = cute.get_layout(%arg4) : !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">
      %117:2 = cute.get_scalars(%lay_15) <{only_dynamic}> : !cute.layout<"(?,?{div=8192}):(1@1,1@0)">
      %118 = arith.ceildivsi %117#0, %c256_i32 : i32
      %119 = arith.ceildivsi %117#1, %c64_i32 : i32
      %shape_16 = cute.make_shape(%118, %119) : (i32, i32) -> !cute.shape<"((256,64),(?,?))">
      %lay_17 = cute.make_layout(%shape_16, %13) : !cute.layout<"((256,64),(?,?)):((1@1,1@0),(256@1,64@0))">
      %120:2 = cute.get_scalars(%lay_17) <{only_dynamic}> : !cute.layout<"((256,64),(?,?)):((1@1,1@0),(256@1,64@0))">
      %shape_18 = cute.make_shape(%120#1) : (i32) -> !cute.shape<"(256,64,?)">
      %lay_19 = cute.make_layout(%shape_18, %15) : !cute.layout<"(256,64,?):(1@1,1@0,64@0)">
      %idx_20 = cute.crd2idx(%coord_14, %lay_17) : (!cute.coord<"((_,_),(?,_))">, !cute.layout<"((256,64),(?,?)):((1@1,1@0),(256@1,64@0))">) -> !cute.int_tuple<"(0,?{div=256})">
      %tup_21 = cute.add_offset(%14, %idx_20) : (!cute.int_tuple<"(0,0)">, !cute.int_tuple<"(0,?{div=256})">) -> !cute.int_tuple<"(0,?{div=256})">
      %coord_22 = cute.make_coord(%38, %39) : (i32, i32) -> !cute.coord<"(?,?,_)">
      %121:2 = cute.get_scalars(%coord_22) <{only_dynamic}> : !cute.coord<"(?,?,_)">
      %coord_23 = cute.make_coord(%121#0, %121#1) : (i32, i32) -> !cute.coord<"((_,_),(?,?))">
      %lay_24 = cute.get_layout(%arg5) : !memref_gmem_f16_
      %122:3 = cute.get_scalars(%lay_24) <{only_dynamic}> : !cute.layout<"(?,?{div=8192}):(?{i64 div=8192},1)">
      %123 = arith.ceildivsi %122#0, %c128_i32 : i32
      %124 = arith.muli %122#2, %c128_i64 : i64
      %125 = arith.ceildivsi %122#1, %c256_i32 : i32
      %shape_25 = cute.make_shape(%123, %125) : (i32, i32) -> !cute.shape<"((128,256),(?,?))">
      %iv_26 = cute.assume(%122#2) : (i64) -> !cute.i64<divby 8192>
      %iv_27 = cute.assume(%124) : (i64) -> !cute.i64<divby 1048576>
      %stride = cute.make_stride(%iv_26, %iv_27) : (!cute.i64<divby 8192>, !cute.i64<divby 1048576>) -> !cute.stride<"((?{i64 div=8192},1),(?{i64 div=1048576},256))">
      %lay_28 = cute.make_layout(%shape_25, %stride) : !cute.layout<"((128,256),(?,?)):((?{i64 div=8192},1),(?{i64 div=1048576},256))">
      %126:4 = cute.get_scalars(%lay_28) <{only_dynamic}> : !cute.layout<"((128,256),(?,?)):((?{i64 div=8192},1),(?{i64 div=1048576},256))">
      %iv_29 = cute.assume(%126#2) : (i64) -> !cute.i64<divby 8192>
      %stride_30 = cute.make_stride(%iv_29) : (!cute.i64<divby 8192>) -> !cute.stride<"(?{i64 div=8192},1)">
      %lay_31 = cute.make_layout(%12, %stride_30) : !cute.layout<"(128,256):(?{i64 div=8192},1)">
      %idx_32 = cute.crd2idx(%coord_23, %lay_28) : (!cute.coord<"((_,_),(?,?))">, !cute.layout<"((128,256),(?,?)):((?{i64 div=8192},1),(?{i64 div=1048576},256))">) -> !cute.int_tuple<"?{i64 div=256}">
      %iter_33 = cute.get_iter(%arg5) : !memref_gmem_f16_
      %ptr_34 = cute.add_offset(%iter_33, %idx_32) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{i64 div=256}">) -> !cute.ptr<f16, gmem, align<32>>
      %127 = cute.get_scalars(%lay_12) <{only_dynamic}> : !cute.layout<"(128,64,?):(1@1,1@0,64@0)">
      %shape_35 = cute.make_shape(%127) : (i32) -> !cute.shape<"((128,16),1,4,?)">
      %lay_36 = cute.make_layout(%shape_35, %11) : !cute.layout<"((128,16),1,4,?):((1@1,1@0),0,16@0,64@0)">
      %128 = cute.get_scalars(%lay_19) <{only_dynamic}> : !cute.layout<"(256,64,?):(1@1,1@0,64@0)">
      %shape_37 = cute.make_shape(%128) : (i32) -> !cute.shape<"((256,16),1,4,?)">
      %lay_38 = cute.make_layout(%shape_37, %11) : !cute.layout<"((256,16),1,4,?):((1@1,1@0),0,16@0,64@0)">
      %129 = cute.get_scalars(%lay_31) <{only_dynamic}> : !cute.layout<"(128,256):(?{i64 div=8192},1)">
      %iv_39 = cute.assume(%129) : (i64) -> !cute.i64<divby 8192>
      %stride_40 = cute.make_stride(%iv_39) : (!cute.i64<divby 8192>) -> !cute.stride<"((?{i64 div=8192},1),0,0)">
      %lay_41 = cute.make_layout(%10, %stride_40) : !cute.layout<"((128,256),1,1):((?{i64 div=8192},1),0,0)">
      %ummaSmemDesc = cute_nvgpu.make_umma_smem_desc(%iter_3 : !cute.ptr<f16, smem, align<128>, S<3,4,3>>) layout = <"((128,16),1,4,4):((64,1),0,16,8192)">, major = <k> -> !cute_nvgpu.smem_desc
      %ummaSmemDesc_42 = cute_nvgpu.make_umma_smem_desc(%iter_4 : !cute.ptr<f16, smem, align<128>, S<3,4,3>>) layout = <"((256,16),1,4,4):((64,1),0,16,16384)">, major = <k> -> !cute_nvgpu.smem_desc
      %130 = cute.get_scalars(%lay_36) <{only_dynamic}> : !cute.layout<"((128,16),1,4,?):((1@1,1@0),0,16@0,64@0)">
      %shape_43 = cute.make_shape(%130) : (i32) -> !cute.shape<"(((128,16),1,4),?)">
      %lay_44 = cute.make_layout(%shape_43, %9) : !cute.layout<"(((128,16),1,4),?):(((1@1,1@0),0,16@0),64@0)">
      %131 = cute.get_scalars(%lay_44) <{only_dynamic}> : !cute.layout<"(((128,16),1,4),?):(((1@1,1@0),0,16@0),64@0)">
      %shape_45 = cute.make_shape(%131) : (i32) -> !cute.shape<"(((64,128),1),?)">
      %lay_46 = cute.make_layout(%shape_45, %8) : !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">
      %132 = cute.get_scalars(%lay_38) <{only_dynamic}> : !cute.layout<"((256,16),1,4,?):((1@1,1@0),0,16@0,64@0)">
      %shape_47 = cute.make_shape(%132) : (i32) -> !cute.shape<"(((256,16),1,4),?)">
      %lay_48 = cute.make_layout(%shape_47, %9) : !cute.layout<"(((256,16),1,4),?):(((1@1,1@0),0,16@0),64@0)">
      %133 = cute.get_scalars(%lay_48) <{only_dynamic}> : !cute.layout<"(((256,16),1,4),?):(((1@1,1@0),0,16@0),64@0)">
      %shape_49 = cute.make_shape(%133) : (i32) -> !cute.shape<"(((64,256),1),?)">
      %lay_50 = cute.make_layout(%shape_49, %8) : !cute.layout<"(((64,256),1),?):(((1@0,1@1),0),64@0)">
      nvvm.barrier id = %c1_i32 number_of_threads = %c128_i32
      %tmem_ptr = cute_nvgpu.arch.sm100.retrieve_tmem_ptr(%iter) : !cute.ptr<i32, smem, align<16>> -> !cute.ptr<f32, tmem, align<16>>
      %134 = cute.get_scalars(%lay_41) <{only_dynamic}> : !cute.layout<"((128,256),1,1):((?{i64 div=8192},1),0,0)">
      %iv_51 = cute.assume(%134) : (i64) -> !cute.i64<divby 8192>
      %stride_52 = cute.make_stride(%iv_51) : (!cute.i64<divby 8192>) -> !cute.stride<"(((?{i64 div=8192},1)),((0,64),0,0))">
      %lay_53 = cute.make_layout(%7, %stride_52) : !cute.layout<"(((128,64)),((1,4),1,1)):(((?{i64 div=8192},1)),((0,64),0,0))">
      %coord_54 = cute.make_coord(%25) : (i32) -> !cute.coord<"?">
      %135 = cute.get_scalars(%coord_54) <{only_dynamic}> : !cute.coord<"?">
      %136 = arith.divsi %135, %c32_i32 : i32
      %137 = arith.muli %136, %c2097152_i32 : i32
      %iv_55 = cute.assume(%137) : (i32) -> !cute.i32<divby 2097152>
      %int_tuple = cute.make_int_tuple(%iv_55) : (!cute.i32<divby 2097152>) -> !cute.int_tuple<"?{div=2097152}">
      %ptr_56 = cute.add_offset(%tmem_ptr, %int_tuple) : (!cute.ptr<f32, tmem, align<16>>, !cute.int_tuple<"?{div=2097152}">) -> !cute.ptr<f32, tmem, align<16>>
      %coord_57 = cute.make_coord(%25) : (i32) -> !cute.coord<"?">
      %138 = cute.get_scalars(%lay_53) <{only_dynamic}> : !cute.layout<"(((128,64)),((1,4),1,1)):(((?{i64 div=8192},1)),((0,64),0,0))">
      %139 = cute.get_scalars(%coord_57) <{only_dynamic}> : !cute.coord<"?">
      %140 = arith.muli %138, %c32_i64 : i64
      %141 = arith.divsi %139, %c32_i32 : i32
      %142 = arith.remsi %139, %c32_i32 : i32
      %143 = arith.extsi %142 : i32 to i64
      %144 = arith.muli %143, %138 : i64
      %145 = arith.extsi %141 : i32 to i64
      %146 = arith.muli %145, %140 : i64
      %147 = arith.addi %144, %146 : i64
      %iv_58 = cute.assume(%147) : (i64) -> !cute.i64<divby 8192>
      %int_tuple_59 = cute.make_int_tuple(%iv_58) : (!cute.i64<divby 8192>) -> !cute.int_tuple<"?{i64 div=8192}">
      %ptr_60 = cute.add_offset(%ptr_34, %int_tuple_59) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{i64 div=8192}">) -> !cute.ptr<f16, gmem, align<32>>
      %rmem = cute.memref.alloca() : !memref_rmem_f32_
      %rmem_61 = cute.memref.alloca() : !memref_rmem_f16_
      %sz = cute.size(%lay_12) <{mode = [2]}> : (!cute.layout<"(128,64,?):(1@1,1@0,64@0)">) -> !cute.int_tuple<"?">
      %e0 = cute.get_leaves(%sz) : !cute.int_tuple<"?">
      %148 = cute.get_scalars(%e0) : !cute.int_tuple<"?">
      %149 = arith.cmpi eq, %37, %c0_i32 : i32
      scf.if %149 {
        %178 = builtin.unrealized_conversion_cast %ptr_8 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        nvvm.mbarrier.try_wait.parity.shared %178, %c1_i32, %c10000000_i32 : !llvm.ptr<3>, i32, i32
        %179 = cute_nvgpu.atom.make_exec_tma(%arg1) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128):(1@1,1@0)">>
        %180 = cute_nvgpu.atom.make_exec_tma(%arg3) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 262144, tma_gbasis = <"(64,256):(1@1,1@0)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_load<f16, copy_bits = 262144, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,256):(1@1,1@0)">>
        %181 = arith.minsi %148, %c2_i32 : i32
        %182:3 = scf.for %arg6 = %c0_i32 to %181 step %c1_i32 iter_args(%arg7 = %c0_i32, %arg8 = %c1_i32, %arg9 = %c0_i32) -> (i32, i32, i32)  : i32 {
          %int_tuple_62 = cute.make_int_tuple(%arg7) : (i32) -> !cute.int_tuple<"?">
          %ptr_63 = cute.add_offset(%ptr_6, %int_tuple_62) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
          %185 = builtin.unrealized_conversion_cast %ptr_63 : !cute.ptr<i64, smem> to !llvm.ptr<3>
          nvvm.mbarrier.try_wait.parity.shared %185, %arg8, %c10000000_i32 : !llvm.ptr<3>, i32, i32
          %186 = nvvm.elect.sync -> i1
          scf.if %186 {
            %int_tuple_81 = cute.make_int_tuple(%arg7) : (i32) -> !cute.int_tuple<"?">
            %ptr_82 = cute.add_offset(%iter_5, %int_tuple_81) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
            %196 = builtin.unrealized_conversion_cast %ptr_82 : !cute.ptr<i64, smem> to !llvm.ptr<3>
            nvvm.mbarrier.txn %196, %c49152_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
          }
          %187 = arith.addi %arg7, %c1_i32 : i32
          %188 = arith.addi %arg9, %c1_i32 : i32
          %189 = arith.cmpi eq, %187, %c4_i32 : i32
          %190 = arith.select %189, %c0_i32, %187 : i32
          %191 = scf.if %189 -> (i32) {
            %196 = arith.xori %arg8, %c1_i32 : i32
            scf.yield %196 : i32
          } else {
            scf.yield %arg8 : i32
          }
          %coord_64 = cute.make_coord(%arg9) : (i32) -> !cute.coord<"(_,?)">
          %idx_65 = cute.crd2idx(%coord_64, %lay_46) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
          %tup_66 = cute.add_offset(%tup, %idx_65) : (!cute.int_tuple<"(0,?{div=128})">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
          %e0_67, %e1 = cute.get_leaves(%tup_66) : !cute.int_tuple<"(?{div=64},?{div=128})">
          %coord_68 = cute.make_coord(%arg7) : (i32) -> !cute.coord<"(_,?)">
          %idx_69 = cute.crd2idx(%coord_68, %6) : (!cute.coord<"(_,?)">, !cute.layout<"((8192,1),4):((1,0),8192)">) -> !cute.int_tuple<"?{div=8192}">
          %ptr_70 = cute.add_offset(%iter_3, %idx_69) : (!cute.ptr<f16, smem, align<128>, S<3,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<f16, smem, align<128>, S<3,4,3>>
          %int_tuple_71 = cute.make_int_tuple(%arg7) : (i32) -> !cute.int_tuple<"?">
          %ptr_72 = cute.add_offset(%iter_5, %int_tuple_71) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
          %int_tuple_73 = cute.make_int_tuple(%e0_67, %e1) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=128}">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
          %192 = cute_nvgpu.atom.set_value(%179, %ptr_72 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128):(1@1,1@0)">>
          %193 = cute.get_scalars(%20) : !cute.int_tuple<"1">
          scf.for %arg10 = %c0_i32 to %193 step %c1_i32  : i32 {
            %196 = cute_nvgpu.atom.get_value(%192 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
            %197 = cute_nvgpu.atom.get_value(%192 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<cache_policy>} : i64
            %TMADescAddr = cute_nvgpu.get_tma_desc_addr(%192 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128):(1@1,1@0)">>) -> !cute.ptr<generic, align<64>>
            %198:2 = cute.get_scalars(%int_tuple_73) : !cute.int_tuple<"(?{div=64},?{div=128})">
            cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr : !cute.ptr<generic, align<64>>, %ptr_70 : !cute.ptr<f16, smem, align<128>, S<3,4,3>>, %196 : !cute.ptr<smem, align<8>>, [%198#0, %198#1] : i32, i32) cache_policy = %197 mode = <tiled> num_cta = 1 : i32
          } {llvm.loop_annotation = #loop_annotation}
          %idx_74 = cute.crd2idx(%coord_64, %lay_50) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,256),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
          %tup_75 = cute.add_offset(%tup_21, %idx_74) : (!cute.int_tuple<"(0,?{div=256})">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.int_tuple<"(?{div=64},?{div=256})">
          %e0_76, %e1_77 = cute.get_leaves(%tup_75) : !cute.int_tuple<"(?{div=64},?{div=256})">
          %idx_78 = cute.crd2idx(%coord_68, %5) : (!cute.coord<"(_,?)">, !cute.layout<"((16384,1),4):((1,0),16384)">) -> !cute.int_tuple<"?{div=16384}">
          %ptr_79 = cute.add_offset(%iter_4, %idx_78) : (!cute.ptr<f16, smem, align<128>, S<3,4,3>>, !cute.int_tuple<"?{div=16384}">) -> !cute.ptr<f16, smem, align<128>, S<3,4,3>>
          %int_tuple_80 = cute.make_int_tuple(%e0_76, %e1_77) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=256}">) -> !cute.int_tuple<"(?{div=64},?{div=256})">
          %194 = cute_nvgpu.atom.set_value(%180, %ptr_72 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 262144, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,256):(1@1,1@0)">>
          %195 = cute.get_scalars(%20) : !cute.int_tuple<"1">
          scf.for %arg10 = %c0_i32 to %195 step %c1_i32  : i32 {
            %196 = cute_nvgpu.atom.get_value(%194 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 262144, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,256):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
            %197 = cute_nvgpu.atom.get_value(%194 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 262144, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,256):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<cache_policy>} : i64
            %TMADescAddr = cute_nvgpu.get_tma_desc_addr(%194 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 262144, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,256):(1@1,1@0)">>) -> !cute.ptr<generic, align<64>>
            %198:2 = cute.get_scalars(%int_tuple_80) : !cute.int_tuple<"(?{div=64},?{div=256})">
            cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr : !cute.ptr<generic, align<64>>, %ptr_79 : !cute.ptr<f16, smem, align<128>, S<3,4,3>>, %196 : !cute.ptr<smem, align<8>>, [%198#0, %198#1] : i32, i32) cache_policy = %197 mode = <tiled> num_cta = 1 : i32
          } {llvm.loop_annotation = #loop_annotation}
          scf.yield %190, %191, %188 : i32, i32, i32
        }
        %183:7 = scf.for %arg6 = %c0_i32 to %148 step %c1_i32 iter_args(%arg7 = %182#2, %arg8 = %182#0, %arg9 = %182#1, %arg10 = %c0_i32, %arg11 = %c0_i32, %arg12 = %c0_i32, %arg13 = %arg0) -> (i32, i32, i32, i32, i32, i32, !mma_f16_f16_f32_128x256x16_)  : i32 {
          %185 = arith.addi %arg6, %181 : i32
          %186 = arith.cmpi ult, %185, %148 : i32
          %187:3 = scf.if %186 -> (i32, i32, i32) {
            %int_tuple_84 = cute.make_int_tuple(%arg8) : (i32) -> !cute.int_tuple<"?">
            %ptr_85 = cute.add_offset(%ptr_6, %int_tuple_84) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
            %211 = builtin.unrealized_conversion_cast %ptr_85 : !cute.ptr<i64, smem> to !llvm.ptr<3>
            nvvm.mbarrier.try_wait.parity.shared %211, %arg9, %c10000000_i32 : !llvm.ptr<3>, i32, i32
            %212 = nvvm.elect.sync -> i1
            scf.if %212 {
              %int_tuple_103 = cute.make_int_tuple(%arg8) : (i32) -> !cute.int_tuple<"?">
              %ptr_104 = cute.add_offset(%iter_5, %int_tuple_103) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
              %222 = builtin.unrealized_conversion_cast %ptr_104 : !cute.ptr<i64, smem> to !llvm.ptr<3>
              nvvm.mbarrier.txn %222, %c49152_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
            }
            %213 = arith.addi %arg8, %c1_i32 : i32
            %214 = arith.addi %arg7, %c1_i32 : i32
            %215 = arith.cmpi eq, %213, %c4_i32 : i32
            %216 = arith.select %215, %c0_i32, %213 : i32
            %217 = scf.if %215 -> (i32) {
              %222 = arith.xori %arg9, %c1_i32 : i32
              scf.yield %222 : i32
            } else {
              scf.yield %arg9 : i32
            }
            %coord_86 = cute.make_coord(%arg7) : (i32) -> !cute.coord<"(_,?)">
            %idx_87 = cute.crd2idx(%coord_86, %lay_46) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
            %tup_88 = cute.add_offset(%tup, %idx_87) : (!cute.int_tuple<"(0,?{div=128})">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
            %e0_89, %e1 = cute.get_leaves(%tup_88) : !cute.int_tuple<"(?{div=64},?{div=128})">
            %coord_90 = cute.make_coord(%arg8) : (i32) -> !cute.coord<"(_,?)">
            %idx_91 = cute.crd2idx(%coord_90, %6) : (!cute.coord<"(_,?)">, !cute.layout<"((8192,1),4):((1,0),8192)">) -> !cute.int_tuple<"?{div=8192}">
            %ptr_92 = cute.add_offset(%iter_3, %idx_91) : (!cute.ptr<f16, smem, align<128>, S<3,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<f16, smem, align<128>, S<3,4,3>>
            %int_tuple_93 = cute.make_int_tuple(%arg8) : (i32) -> !cute.int_tuple<"?">
            %ptr_94 = cute.add_offset(%iter_5, %int_tuple_93) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
            %int_tuple_95 = cute.make_int_tuple(%e0_89, %e1) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=128}">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
            %218 = cute_nvgpu.atom.set_value(%179, %ptr_94 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128):(1@1,1@0)">>
            %219 = cute.get_scalars(%20) : !cute.int_tuple<"1">
            scf.for %arg14 = %c0_i32 to %219 step %c1_i32  : i32 {
              %222 = cute_nvgpu.atom.get_value(%218 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
              %223 = cute_nvgpu.atom.get_value(%218 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<cache_policy>} : i64
              %TMADescAddr = cute_nvgpu.get_tma_desc_addr(%218 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128):(1@1,1@0)">>) -> !cute.ptr<generic, align<64>>
              %224:2 = cute.get_scalars(%int_tuple_95) : !cute.int_tuple<"(?{div=64},?{div=128})">
              cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr : !cute.ptr<generic, align<64>>, %ptr_92 : !cute.ptr<f16, smem, align<128>, S<3,4,3>>, %222 : !cute.ptr<smem, align<8>>, [%224#0, %224#1] : i32, i32) cache_policy = %223 mode = <tiled> num_cta = 1 : i32
            } {llvm.loop_annotation = #loop_annotation}
            %idx_96 = cute.crd2idx(%coord_86, %lay_50) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,256),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
            %tup_97 = cute.add_offset(%tup_21, %idx_96) : (!cute.int_tuple<"(0,?{div=256})">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.int_tuple<"(?{div=64},?{div=256})">
            %e0_98, %e1_99 = cute.get_leaves(%tup_97) : !cute.int_tuple<"(?{div=64},?{div=256})">
            %idx_100 = cute.crd2idx(%coord_90, %5) : (!cute.coord<"(_,?)">, !cute.layout<"((16384,1),4):((1,0),16384)">) -> !cute.int_tuple<"?{div=16384}">
            %ptr_101 = cute.add_offset(%iter_4, %idx_100) : (!cute.ptr<f16, smem, align<128>, S<3,4,3>>, !cute.int_tuple<"?{div=16384}">) -> !cute.ptr<f16, smem, align<128>, S<3,4,3>>
            %int_tuple_102 = cute.make_int_tuple(%e0_98, %e1_99) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=256}">) -> !cute.int_tuple<"(?{div=64},?{div=256})">
            %220 = cute_nvgpu.atom.set_value(%180, %ptr_94 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 262144, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,256):(1@1,1@0)">>
            %221 = cute.get_scalars(%20) : !cute.int_tuple<"1">
            scf.for %arg14 = %c0_i32 to %221 step %c1_i32  : i32 {
              %222 = cute_nvgpu.atom.get_value(%220 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 262144, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,256):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
              %223 = cute_nvgpu.atom.get_value(%220 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 262144, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,256):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<cache_policy>} : i64
              %TMADescAddr = cute_nvgpu.get_tma_desc_addr(%220 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 262144, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,256):(1@1,1@0)">>) -> !cute.ptr<generic, align<64>>
              %224:2 = cute.get_scalars(%int_tuple_102) : !cute.int_tuple<"(?{div=64},?{div=256})">
              cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr : !cute.ptr<generic, align<64>>, %ptr_101 : !cute.ptr<f16, smem, align<128>, S<3,4,3>>, %222 : !cute.ptr<smem, align<8>>, [%224#0, %224#1] : i32, i32) cache_policy = %223 mode = <tiled> num_cta = 1 : i32
            } {llvm.loop_annotation = #loop_annotation}
            scf.yield %216, %217, %214 : i32, i32, i32
          } else {
            scf.yield %arg8, %arg9, %arg7 : i32, i32, i32
          }
          %int_tuple_62 = cute.make_int_tuple(%arg11) : (i32) -> !cute.int_tuple<"?">
          %ptr_63 = cute.add_offset(%iter_5, %int_tuple_62) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
          %188 = builtin.unrealized_conversion_cast %ptr_63 : !cute.ptr<i64, smem> to !llvm.ptr<3>
          nvvm.mbarrier.try_wait.parity.shared %188, %arg12, %c10000000_i32 : !llvm.ptr<3>, i32, i32
          %189 = arith.addi %arg11, %c1_i32 : i32
          %190 = arith.addi %arg10, %c1_i32 : i32
          %191 = arith.cmpi eq, %189, %c4_i32 : i32
          %192 = arith.select %191, %c0_i32, %189 : i32
          %193 = scf.if %191 -> (i32) {
            %211 = arith.xori %arg12, %c1_i32 : i32
            scf.yield %211 : i32
          } else {
            scf.yield %arg12 : i32
          }
          %coord_64 = cute.make_coord(%arg11) : (i32) -> !cute.coord<"(_,_,0,?)">
          %idx_65 = cute.crd2idx(%coord_64, %4) : (!cute.coord<"(_,_,0,?)">, !cute.layout<"(1,1,4,4):(0,0,2,1024)">) -> !cute.int_tuple<"?{div=1024}">
          %tup_66 = cute.add_offset(%ummaSmemDesc, %idx_65) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=1024}">) -> !cute_nvgpu.smem_desc
          %idx_67 = cute.crd2idx(%coord_64, %3) : (!cute.coord<"(_,_,0,?)">, !cute.layout<"(1,1,4,4):(0,0,2,2048)">) -> !cute.int_tuple<"?{div=2048}">
          %tup_68 = cute.add_offset(%ummaSmemDesc_42, %idx_67) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2048}">) -> !cute_nvgpu.smem_desc
          %194 = cute.get_scalars(%20) : !cute.int_tuple<"1">
          %195 = cute.get_scalars(%20) : !cute.int_tuple<"1">
          %196 = cute.get_scalars(%20) : !cute.int_tuple<"1">
          scf.for %arg14 = %c0_i32 to %194 step %c1_i32  : i32 {
            scf.for %arg15 = %c0_i32 to %195 step %c1_i32  : i32 {
              scf.for %arg16 = %c0_i32 to %196 step %c1_i32  : i32 {
                %211 = cute_nvgpu.atom.get_value(%arg13 : !mma_f16_f16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : i1
                %212 = cute_nvgpu.atom.get_value(%arg13 : !mma_f16_f16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : i1
                %213 = cute_nvgpu.atom.get_value(%arg13 : !mma_f16_f16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : i1
                %214 = arith.extui %211 : i1 to i32
                %215 = arith.extui %212 : i1 to i32
                %216 = arith.shli %214, %c13_i32 : i32
                %217 = arith.shli %215, %c14_i32 : i32
                %218 = arith.ori %216, %c138412048_i32 : i32
                %219 = arith.ori %218, %217 : i32
                cute_nvgpu.arch.mma.SM100.umma(%tup_66, %tup_68, %tmem_ptr, %219, %213) {num_cta = 1 : i32, scale = 0 : i32, a_type = f16} : (!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, !cute.ptr<f32, tmem, align<16>>, i32, i1) -> ()
              } {llvm.loop_annotation = #loop_annotation}
            } {llvm.loop_annotation = #loop_annotation}
          } {llvm.loop_annotation = #loop_annotation}
          %197 = cute_nvgpu.atom.set_value(%arg13, %true : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_f16_f16_f32_128x256x16_
          %coord_69 = cute.make_coord(%arg11) : (i32) -> !cute.coord<"(_,_,1,?)">
          %idx_70 = cute.crd2idx(%coord_69, %4) : (!cute.coord<"(_,_,1,?)">, !cute.layout<"(1,1,4,4):(0,0,2,1024)">) -> !cute.int_tuple<"?{div=2}">
          %tup_71 = cute.add_offset(%ummaSmemDesc, %idx_70) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
          %idx_72 = cute.crd2idx(%coord_69, %3) : (!cute.coord<"(_,_,1,?)">, !cute.layout<"(1,1,4,4):(0,0,2,2048)">) -> !cute.int_tuple<"?{div=2}">
          %tup_73 = cute.add_offset(%ummaSmemDesc_42, %idx_72) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
          %198 = cute.get_scalars(%20) : !cute.int_tuple<"1">
          %199 = cute.get_scalars(%20) : !cute.int_tuple<"1">
          %200 = cute.get_scalars(%20) : !cute.int_tuple<"1">
          scf.for %arg14 = %c0_i32 to %198 step %c1_i32  : i32 {
            scf.for %arg15 = %c0_i32 to %199 step %c1_i32  : i32 {
              scf.for %arg16 = %c0_i32 to %200 step %c1_i32  : i32 {
                %211 = cute_nvgpu.atom.get_value(%197 : !mma_f16_f16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : i1
                %212 = cute_nvgpu.atom.get_value(%197 : !mma_f16_f16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : i1
                %213 = cute_nvgpu.atom.get_value(%197 : !mma_f16_f16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : i1
                %214 = arith.extui %211 : i1 to i32
                %215 = arith.extui %212 : i1 to i32
                %216 = arith.shli %214, %c13_i32 : i32
                %217 = arith.shli %215, %c14_i32 : i32
                %218 = arith.ori %216, %c138412048_i32 : i32
                %219 = arith.ori %218, %217 : i32
                cute_nvgpu.arch.mma.SM100.umma(%tup_71, %tup_73, %tmem_ptr, %219, %213) {num_cta = 1 : i32, scale = 0 : i32, a_type = f16} : (!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, !cute.ptr<f32, tmem, align<16>>, i32, i1) -> ()
              } {llvm.loop_annotation = #loop_annotation}
            } {llvm.loop_annotation = #loop_annotation}
          } {llvm.loop_annotation = #loop_annotation}
          %201 = cute_nvgpu.atom.set_value(%197, %true : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_f16_f16_f32_128x256x16_
          %coord_74 = cute.make_coord(%arg11) : (i32) -> !cute.coord<"(_,_,2,?)">
          %idx_75 = cute.crd2idx(%coord_74, %4) : (!cute.coord<"(_,_,2,?)">, !cute.layout<"(1,1,4,4):(0,0,2,1024)">) -> !cute.int_tuple<"?{div=4}">
          %tup_76 = cute.add_offset(%ummaSmemDesc, %idx_75) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=4}">) -> !cute_nvgpu.smem_desc
          %idx_77 = cute.crd2idx(%coord_74, %3) : (!cute.coord<"(_,_,2,?)">, !cute.layout<"(1,1,4,4):(0,0,2,2048)">) -> !cute.int_tuple<"?{div=4}">
          %tup_78 = cute.add_offset(%ummaSmemDesc_42, %idx_77) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=4}">) -> !cute_nvgpu.smem_desc
          %202 = cute.get_scalars(%20) : !cute.int_tuple<"1">
          %203 = cute.get_scalars(%20) : !cute.int_tuple<"1">
          %204 = cute.get_scalars(%20) : !cute.int_tuple<"1">
          scf.for %arg14 = %c0_i32 to %202 step %c1_i32  : i32 {
            scf.for %arg15 = %c0_i32 to %203 step %c1_i32  : i32 {
              scf.for %arg16 = %c0_i32 to %204 step %c1_i32  : i32 {
                %211 = cute_nvgpu.atom.get_value(%201 : !mma_f16_f16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : i1
                %212 = cute_nvgpu.atom.get_value(%201 : !mma_f16_f16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : i1
                %213 = cute_nvgpu.atom.get_value(%201 : !mma_f16_f16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : i1
                %214 = arith.extui %211 : i1 to i32
                %215 = arith.extui %212 : i1 to i32
                %216 = arith.shli %214, %c13_i32 : i32
                %217 = arith.shli %215, %c14_i32 : i32
                %218 = arith.ori %216, %c138412048_i32 : i32
                %219 = arith.ori %218, %217 : i32
                cute_nvgpu.arch.mma.SM100.umma(%tup_76, %tup_78, %tmem_ptr, %219, %213) {num_cta = 1 : i32, scale = 0 : i32, a_type = f16} : (!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, !cute.ptr<f32, tmem, align<16>>, i32, i1) -> ()
              } {llvm.loop_annotation = #loop_annotation}
            } {llvm.loop_annotation = #loop_annotation}
          } {llvm.loop_annotation = #loop_annotation}
          %205 = cute_nvgpu.atom.set_value(%201, %true : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_f16_f16_f32_128x256x16_
          %coord_79 = cute.make_coord(%arg11) : (i32) -> !cute.coord<"(_,_,3,?)">
          %idx_80 = cute.crd2idx(%coord_79, %4) : (!cute.coord<"(_,_,3,?)">, !cute.layout<"(1,1,4,4):(0,0,2,1024)">) -> !cute.int_tuple<"?{div=2}">
          %tup_81 = cute.add_offset(%ummaSmemDesc, %idx_80) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
          %idx_82 = cute.crd2idx(%coord_79, %3) : (!cute.coord<"(_,_,3,?)">, !cute.layout<"(1,1,4,4):(0,0,2,2048)">) -> !cute.int_tuple<"?{div=2}">
          %tup_83 = cute.add_offset(%ummaSmemDesc_42, %idx_82) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
          %206 = cute.get_scalars(%20) : !cute.int_tuple<"1">
          %207 = cute.get_scalars(%20) : !cute.int_tuple<"1">
          %208 = cute.get_scalars(%20) : !cute.int_tuple<"1">
          scf.for %arg14 = %c0_i32 to %206 step %c1_i32  : i32 {
            scf.for %arg15 = %c0_i32 to %207 step %c1_i32  : i32 {
              scf.for %arg16 = %c0_i32 to %208 step %c1_i32  : i32 {
                %211 = cute_nvgpu.atom.get_value(%205 : !mma_f16_f16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : i1
                %212 = cute_nvgpu.atom.get_value(%205 : !mma_f16_f16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : i1
                %213 = cute_nvgpu.atom.get_value(%205 : !mma_f16_f16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : i1
                %214 = arith.extui %211 : i1 to i32
                %215 = arith.extui %212 : i1 to i32
                %216 = arith.shli %214, %c13_i32 : i32
                %217 = arith.shli %215, %c14_i32 : i32
                %218 = arith.ori %216, %c138412048_i32 : i32
                %219 = arith.ori %218, %217 : i32
                cute_nvgpu.arch.mma.SM100.umma(%tup_81, %tup_83, %tmem_ptr, %219, %213) {num_cta = 1 : i32, scale = 0 : i32, a_type = f16} : (!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, !cute.ptr<f32, tmem, align<16>>, i32, i1) -> ()
              } {llvm.loop_annotation = #loop_annotation}
            } {llvm.loop_annotation = #loop_annotation}
          } {llvm.loop_annotation = #loop_annotation}
          %209 = cute_nvgpu.atom.set_value(%205, %true : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_f16_f16_f32_128x256x16_
          %210 = nvvm.elect.sync -> i1
          scf.if %210 {
            %int_tuple_84 = cute.make_int_tuple(%arg11) : (i32) -> !cute.int_tuple<"?">
            %ptr_85 = cute.add_offset(%ptr_6, %int_tuple_84) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
            %211 = builtin.unrealized_conversion_cast %ptr_85 : !cute.ptr<i64, smem> to !llvm.ptr<3>
            nvvm.tcgen05.commit.arrive %211 : !llvm.ptr<3>
          }
          scf.yield %187#2, %187#0, %187#1, %190, %192, %193, %209 : i32, i32, i32, i32, i32, i32, !mma_f16_f16_f32_128x256x16_
        }
        %184 = nvvm.elect.sync -> i1
        scf.if %184 {
          %dyn_62 = cute.derefine(%iter_7) : !cute.ptr<i64, smem, align<64>> to !cute.ptr<i64, smem>
          %185 = builtin.unrealized_conversion_cast %dyn_62 : !cute.ptr<i64, smem> to !llvm.ptr<3>
          nvvm.tcgen05.commit.arrive %185 : !llvm.ptr<3>
        }
      }
      %150 = nvvm.read.ptx.sreg.tid.x range <i32, 0, 1024> : i32
      %151 = nvvm.read.ptx.sreg.tid.y range <i32, 0, 1024> : i32
      %152 = nvvm.read.ptx.sreg.tid.z range <i32, 0, 64> : i32
      %153 = nvvm.read.ptx.sreg.ntid.x range <i32, 1, 1024> : i32
      %154 = nvvm.read.ptx.sreg.ntid.y range <i32, 1, 1024> : i32
      %155 = arith.muli %151, %153 : i32
      %156 = arith.addi %150, %155 : i32
      %157 = arith.muli %152, %153 : i32
      %158 = arith.muli %157, %154 : i32
      %159 = arith.addi %156, %158 : i32
      %160 = arith.floordivsi %159, %c32_i32 : i32
      %161 = cute_nvgpu.arch.make_warp_uniform(%160) : i32
      %162 = arith.cmpi eq, %161, %c0_i32 : i32
      scf.if %162 {
        cute_nvgpu.arch.sm100.relinquish_tmem_alloc_permit [ cta_1]
      }
      %dyn = cute.derefine(%iter_7) : !cute.ptr<i64, smem, align<64>> to !cute.ptr<i64, smem>
      %163 = builtin.unrealized_conversion_cast %dyn : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %163, %c0_i32, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      scf.for %arg6 = %c0_i32 to %c4_i32 step %c1_i32  : i32 {
        %iter_62 = cute.get_iter(%rmem) : !memref_rmem_f32_
        %coord_63 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,_,?)">
        %idx_64 = cute.crd2idx(%coord_63, %2) : (!cute.coord<"(_,_,?)">, !cute.layout<"(((64,32),1),1,((1,4),1,1)):(((1,65536),0),0,((0,64),0,0))">) -> !cute.int_tuple<"?{div=64}">
        %ptr_65 = cute.add_offset(%ptr_56, %idx_64) : (!cute.ptr<f32, tmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<f32, tmem, align<16>>
        %178 = cute.get_scalars(%20) : !cute.int_tuple<"1">
        scf.for %arg7 = %c0_i32 to %178 step %c1_i32  : i32 {
          %182 = "cute_nvgpu.arch.copy.SM100.tmem_load"(%ptr_65) <{num_b = 32 : i32, num_dp = 32 : i32, num_rep = 64 : i32}> : (!cute.ptr<f32, tmem, align<16>>) -> vector<64xi32>
          %183 = builtin.unrealized_conversion_cast %iter_62 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
          llvm.store %182, %183 : vector<64xi32>, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %179 = cute.memref.load_vec %rmem : !memref_rmem_f32_
        %180 = arith.truncf %179 : vector<64xf32> to vector<64xf16>
        cute.memref.store_vec %180, %rmem_61 : !memref_rmem_f16_
        %coord_66 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,_,?)">
        %idx_67 = cute.crd2idx(%coord_66, %1) : (!cute.coord<"(_,_,?)">, !cute.layout<"((64,1),1,((1,4),1,1)):((1,0),0,((0,64),0,0))">) -> !cute.int_tuple<"?{div=64}">
        %ptr_68 = cute.add_offset(%ptr_60, %idx_67) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<f16, gmem, align<32>>
        %iter_69 = cute.get_iter(%rmem_61) : !memref_rmem_f16_
        %181 = cute.get_scalars(%17) : !cute.int_tuple<"4">
        scf.for %arg7 = %c0_i32 to %181 step %c1_i32  : i32 {
          %coord_70 = cute.make_coord(%arg7) : (i32) -> !cute.coord<"(_,?)">
          %idx_71 = cute.crd2idx(%coord_70, %0) : (!cute.coord<"(_,?)">, !cute.layout<"(16,(4)):(1,(16))">) -> !cute.int_tuple<"?{div=16}">
          %ptr_72 = cute.add_offset(%iter_69, %idx_71) : (!cute.ptr<f16, rmem, align<32>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<f16, rmem, align<32>>
          %idx_73 = cute.crd2idx(%coord_70, %0) : (!cute.coord<"(_,?)">, !cute.layout<"(16,(4)):(1,(16))">) -> !cute.int_tuple<"?{div=16}">
          %ptr_74 = cute.add_offset(%ptr_68, %idx_73) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<f16, gmem, align<32>>
          %182 = builtin.unrealized_conversion_cast %ptr_72 : !cute.ptr<f16, rmem, align<32>> to !llvm.ptr
          %183 = builtin.unrealized_conversion_cast %ptr_74 : !cute.ptr<f16, gmem, align<32>> to !llvm.ptr<1>
          %184 = llvm.load %182 {alignment = 32 : i64} : !llvm.ptr -> vector<16xf16>
          llvm.store %184, %183 {alignment = 32 : i64} : vector<16xf16>, !llvm.ptr<1>
        } {llvm.loop_annotation = #loop_annotation}
      }
      %164 = builtin.unrealized_conversion_cast %ptr_8 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %164, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>} : !llvm.ptr<3>, i32
      nvvm.barrier id = %c1_i32
      %165 = nvvm.read.ptx.sreg.tid.x range <i32, 0, 1024> : i32
      %166 = nvvm.read.ptx.sreg.tid.y range <i32, 0, 1024> : i32
      %167 = nvvm.read.ptx.sreg.tid.z range <i32, 0, 64> : i32
      %168 = nvvm.read.ptx.sreg.ntid.x range <i32, 1, 1024> : i32
      %169 = nvvm.read.ptx.sreg.ntid.y range <i32, 1, 1024> : i32
      %170 = arith.muli %166, %168 : i32
      %171 = arith.addi %165, %170 : i32
      %172 = arith.muli %167, %168 : i32
      %173 = arith.muli %172, %169 : i32
      %174 = arith.addi %171, %173 : i32
      %175 = arith.floordivsi %174, %c32_i32 : i32
      %176 = cute_nvgpu.arch.make_warp_uniform(%175) : i32
      %177 = arith.cmpi eq, %176, %c0_i32 : i32
      scf.if %177 {
        cute_nvgpu.arch.sm100.dealloc_tmem(%tmem_ptr, %c512_i32) [ cta_1] : !cute.ptr<f32, tmem, align<16>>, i32
      }
      return
    }
  }
  func.func @cutlass_host_function_Tensorgmemodiv8192i64div81921_Tensorgmemodiv8192i64div81921_Tensorgmemodiv8192i64div81921(%arg0: !memref_gmem_f16_, %arg1: !memref_gmem_f16_, %arg2: !memref_gmem_f16_) -> i32 attributes {llvm.emit_c_interface} {
    %c196736_i64 = arith.constant 196736 : i64
    %0 = llvm.mlir.constant(255 : i64) : i64
    %1 = llvm.mlir.constant(127 : i64) : i64
    %2 = llvm.mlir.constant(4539628424389459968 : i64) : i64
    %3 = llvm.mlir.constant(287506 : i64) : i64
    %c0_i32 = arith.constant 0 : i32
    %c1_i32 = arith.constant 1 : i32
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
    %35 = llvm.getelementptr %10[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %34, %35 : i64, !llvm.ptr
    %36 = llvm.sub %13, %c1_i64 : i64
    %37 = llvm.sub %c1_i64, %c1_i64 : i64
    %38 = llvm.sub %c1_i64, %c1_i64 : i64
    %39 = llvm.sub %c1_i64, %c1_i64 : i64
    %40 = llvm.mul %36, %14 : i64
    %41 = llvm.mul %37, %c0_i64 : i64
    %42 = llvm.mul %38, %c0_i64 : i64
    %43 = llvm.mul %39, %c0_i64 : i64
    %44 = llvm.add %40, %41 : i64
    %45 = llvm.add %42, %43 : i64
    %46 = llvm.mul %12, %c16_i64 : i64
    %47 = llvm.udiv %46, %c8_i64 : i64
    %48 = llvm.add %47, %44 : i64
    %49 = llvm.add %48, %45 : i64
    %50 = llvm.icmp "uge" %49, %c131072_i64 : i64
    %51 = llvm.zext %50 : i1 to i64
    %52 = llvm.shl %51, %c21_i64 : i64
    %53 = llvm.udiv %14, %c16_i64 : i64
    %54 = llvm.shl %53, %c32_i64 : i64
    %55 = llvm.or %c0_i64, %52 : i64
    %56 = llvm.or %55, %54 : i64
    %57 = llvm.or %3, %56 : i64
    %58 = llvm.getelementptr %10[0, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %57, %58 : i64, !llvm.ptr
    %59 = llvm.udiv %c0_i64, %c16_i64 : i64
    %60 = llvm.and %59, %c4294967295_i64 : i64
    %61 = llvm.shl %60, %c0_i64 : i64
    %62 = llvm.udiv %c0_i64, %c16_i64 : i64
    %63 = llvm.shl %62, %c32_i64 : i64
    %64 = llvm.or %61, %63 : i64
    %65 = llvm.getelementptr %10[0, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %64, %65 : i64, !llvm.ptr
    %66 = llvm.udiv %c0_i64, %c16_i64 : i64
    %67 = llvm.and %66, %c4294967295_i64 : i64
    %68 = llvm.shl %67, %c0_i64 : i64
    %69 = llvm.lshr %14, %c36_i64 : i64
    %70 = llvm.and %69, %c15_i64 : i64
    %71 = llvm.shl %70, %c32_i64 : i64
    %72 = llvm.lshr %c0_i64, %c36_i64 : i64
    %73 = llvm.and %72, %c15_i64 : i64
    %74 = llvm.shl %73, %c36_i64 : i64
    %75 = llvm.lshr %c0_i64, %c36_i64 : i64
    %76 = llvm.and %75, %c15_i64 : i64
    %77 = llvm.shl %76, %c40_i64 : i64
    %78 = llvm.lshr %c0_i64, %c36_i64 : i64
    %79 = llvm.shl %78, %c44_i64 : i64
    %80 = llvm.or %71, %74 : i64
    %81 = llvm.or %77, %79 : i64
    %82 = llvm.or %80, %81 : i64
    %83 = llvm.or %68, %82 : i64
    %84 = llvm.getelementptr %10[0, 3] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %83, %84 : i64, !llvm.ptr
    %85 = llvm.sub %12, %c1_i64 : i64
    %86 = llvm.and %85, %c4294967295_i64 : i64
    %87 = llvm.shl %86, %c0_i64 : i64
    %88 = llvm.sub %13, %c1_i64 : i64
    %89 = llvm.shl %88, %c32_i64 : i64
    %90 = llvm.or %87, %89 : i64
    %91 = llvm.getelementptr %10[0, 4] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %90, %91 : i64, !llvm.ptr
    %92 = llvm.sub %c1_i64, %c1_i64 : i64
    %93 = llvm.and %92, %c4294967295_i64 : i64
    %94 = llvm.shl %93, %c0_i64 : i64
    %95 = llvm.sub %c1_i64, %c1_i64 : i64
    %96 = llvm.shl %95, %c32_i64 : i64
    %97 = llvm.or %94, %96 : i64
    %98 = llvm.getelementptr %10[0, 5] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %97, %98 : i64, !llvm.ptr
    %99 = llvm.sub %c1_i64, %c1_i64 : i64
    %100 = llvm.and %99, %c4294967295_i64 : i64
    %101 = llvm.or %100, %c0_i64 : i64
    %102 = llvm.or %101, %2 : i64
    %103 = llvm.getelementptr %10[0, 6] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %102, %103 : i64, !llvm.ptr
    %104 = llvm.getelementptr %10[0, 7] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %1, %104 : i64, !llvm.ptr
    %105 = builtin.unrealized_conversion_cast %10 : !llvm.ptr to !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>>
    %106 = cute.ptrtoint(%105) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>> to i64
    %107 = llvm.inttoptr %106 : i64 to !llvm.ptr
    %108 = llvm.load %107 {nontemporal} : !llvm.ptr -> !llvm.struct<(array<16 x i64>)>
    %109 = builtin.unrealized_conversion_cast %108 : !llvm.struct<(array<16 x i64>)> to !cute_nvgpu.tma_descriptor_tiled
    %atom_0 = cute.make_atom() : () -> !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, internal_val_type = f16>
    %110 = cute_nvgpu.atom.set_value(%atom_0, %109 : !cute_nvgpu.tma_descriptor_tiled) {field = #cute_nvgpu.atom_copy_field_non_exec_tma_load<tma_desc>} : !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, internal_val_type = f16>
    %lay_1 = cute.get_layout(%arg0) : !memref_gmem_f16_
    %111 = cute.get_shape(%lay_1) : (!cute.layout<"(?,?{div=8192}):(?{i64 div=8192},1)">) -> !cute.shape<"(?,?{div=8192})">
    %lay_2 = cute.make_layout(%111, %5) : !cute.layout<"(?,?{div=8192}):(1@1,1@0)">
    %view = cute.make_view(%4, %lay_2) : !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">
    %112 = llvm.alloca %c16_i32 x i64 {alignment = 64 : i64} : (i32) -> !llvm.ptr
    %iter_3 = cute.get_iter(%arg1) : !memref_gmem_f16_
    %lay_4 = cute.get_layout(%arg1) : !memref_gmem_f16_
    %113:3 = cute.get_scalars(%lay_4) <{only_dynamic}> : !cute.layout<"(?,?{div=8192}):(?{i64 div=8192},1)">
    %114 = arith.extui %113#1 : i32 to i64
    %115 = arith.extui %113#0 : i32 to i64
    %116 = llvm.mul %113#2, %c2_i64 : i64
    %117 = cute.ptrtoint(%iter_3) : !cute.ptr<f16, gmem, align<32>> to i64
    %118 = llvm.getelementptr %112[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %118 : i64, !llvm.ptr
    %119 = llvm.getelementptr %112[0, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %119 : i64, !llvm.ptr
    %120 = llvm.getelementptr %112[0, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %120 : i64, !llvm.ptr
    %121 = llvm.getelementptr %112[0, 3] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %121 : i64, !llvm.ptr
    %122 = llvm.getelementptr %112[0, 4] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %122 : i64, !llvm.ptr
    %123 = llvm.getelementptr %112[0, 5] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %123 : i64, !llvm.ptr
    %124 = llvm.getelementptr %112[0, 6] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %124 : i64, !llvm.ptr
    %125 = llvm.getelementptr %112[0, 7] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %125 : i64, !llvm.ptr
    %126 = llvm.getelementptr %112[0, 8] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %126 : i64, !llvm.ptr
    %127 = llvm.getelementptr %112[0, 9] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %127 : i64, !llvm.ptr
    %128 = llvm.getelementptr %112[0, 10] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %128 : i64, !llvm.ptr
    %129 = llvm.getelementptr %112[0, 11] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %129 : i64, !llvm.ptr
    %130 = llvm.getelementptr %112[0, 12] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %130 : i64, !llvm.ptr
    %131 = llvm.getelementptr %112[0, 13] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %131 : i64, !llvm.ptr
    %132 = llvm.getelementptr %112[0, 14] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %132 : i64, !llvm.ptr
    %133 = llvm.getelementptr %112[0, 15] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %c0_i64, %133 : i64, !llvm.ptr
    %134 = llvm.udiv %117, %c16_i64 : i64
    %135 = llvm.and %134, %c9007199254740991_i64 : i64
    %136 = llvm.shl %135, %c4_i64 : i64
    %137 = llvm.getelementptr %112[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %136, %137 : i64, !llvm.ptr
    %138 = llvm.sub %115, %c1_i64 : i64
    %139 = llvm.sub %c1_i64, %c1_i64 : i64
    %140 = llvm.sub %c1_i64, %c1_i64 : i64
    %141 = llvm.sub %c1_i64, %c1_i64 : i64
    %142 = llvm.mul %138, %116 : i64
    %143 = llvm.mul %139, %c0_i64 : i64
    %144 = llvm.mul %140, %c0_i64 : i64
    %145 = llvm.mul %141, %c0_i64 : i64
    %146 = llvm.add %142, %143 : i64
    %147 = llvm.add %144, %145 : i64
    %148 = llvm.mul %114, %c16_i64 : i64
    %149 = llvm.udiv %148, %c8_i64 : i64
    %150 = llvm.add %149, %146 : i64
    %151 = llvm.add %150, %147 : i64
    %152 = llvm.icmp "uge" %151, %c131072_i64 : i64
    %153 = llvm.zext %152 : i1 to i64
    %154 = llvm.shl %153, %c21_i64 : i64
    %155 = llvm.udiv %116, %c16_i64 : i64
    %156 = llvm.shl %155, %c32_i64 : i64
    %157 = llvm.or %c0_i64, %154 : i64
    %158 = llvm.or %157, %156 : i64
    %159 = llvm.or %3, %158 : i64
    %160 = llvm.getelementptr %112[0, 1] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %159, %160 : i64, !llvm.ptr
    %161 = llvm.udiv %c0_i64, %c16_i64 : i64
    %162 = llvm.and %161, %c4294967295_i64 : i64
    %163 = llvm.shl %162, %c0_i64 : i64
    %164 = llvm.udiv %c0_i64, %c16_i64 : i64
    %165 = llvm.shl %164, %c32_i64 : i64
    %166 = llvm.or %163, %165 : i64
    %167 = llvm.getelementptr %112[0, 2] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %166, %167 : i64, !llvm.ptr
    %168 = llvm.udiv %c0_i64, %c16_i64 : i64
    %169 = llvm.and %168, %c4294967295_i64 : i64
    %170 = llvm.shl %169, %c0_i64 : i64
    %171 = llvm.lshr %116, %c36_i64 : i64
    %172 = llvm.and %171, %c15_i64 : i64
    %173 = llvm.shl %172, %c32_i64 : i64
    %174 = llvm.lshr %c0_i64, %c36_i64 : i64
    %175 = llvm.and %174, %c15_i64 : i64
    %176 = llvm.shl %175, %c36_i64 : i64
    %177 = llvm.lshr %c0_i64, %c36_i64 : i64
    %178 = llvm.and %177, %c15_i64 : i64
    %179 = llvm.shl %178, %c40_i64 : i64
    %180 = llvm.lshr %c0_i64, %c36_i64 : i64
    %181 = llvm.shl %180, %c44_i64 : i64
    %182 = llvm.or %173, %176 : i64
    %183 = llvm.or %179, %181 : i64
    %184 = llvm.or %182, %183 : i64
    %185 = llvm.or %170, %184 : i64
    %186 = llvm.getelementptr %112[0, 3] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %185, %186 : i64, !llvm.ptr
    %187 = llvm.sub %114, %c1_i64 : i64
    %188 = llvm.and %187, %c4294967295_i64 : i64
    %189 = llvm.shl %188, %c0_i64 : i64
    %190 = llvm.sub %115, %c1_i64 : i64
    %191 = llvm.shl %190, %c32_i64 : i64
    %192 = llvm.or %189, %191 : i64
    %193 = llvm.getelementptr %112[0, 4] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %192, %193 : i64, !llvm.ptr
    %194 = llvm.sub %c1_i64, %c1_i64 : i64
    %195 = llvm.and %194, %c4294967295_i64 : i64
    %196 = llvm.shl %195, %c0_i64 : i64
    %197 = llvm.sub %c1_i64, %c1_i64 : i64
    %198 = llvm.shl %197, %c32_i64 : i64
    %199 = llvm.or %196, %198 : i64
    %200 = llvm.getelementptr %112[0, 5] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %199, %200 : i64, !llvm.ptr
    %201 = llvm.sub %c1_i64, %c1_i64 : i64
    %202 = llvm.and %201, %c4294967295_i64 : i64
    %203 = llvm.or %202, %c0_i64 : i64
    %204 = llvm.or %203, %2 : i64
    %205 = llvm.getelementptr %112[0, 6] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %204, %205 : i64, !llvm.ptr
    %206 = llvm.getelementptr %112[0, 7] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<16 x i64>
    llvm.store %0, %206 : i64, !llvm.ptr
    %207 = builtin.unrealized_conversion_cast %112 : !llvm.ptr to !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>>
    %208 = cute.ptrtoint(%207) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<64>> to i64
    %209 = llvm.inttoptr %208 : i64 to !llvm.ptr
    %210 = llvm.load %209 {nontemporal} : !llvm.ptr -> !llvm.struct<(array<16 x i64>)>
    %211 = builtin.unrealized_conversion_cast %210 : !llvm.struct<(array<16 x i64>)> to !cute_nvgpu.tma_descriptor_tiled
    %atom_5 = cute.make_atom() : () -> !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 262144, tma_gbasis = <"(64,256):(1@1,1@0)">, internal_val_type = f16>
    %212 = cute_nvgpu.atom.set_value(%atom_5, %211 : !cute_nvgpu.tma_descriptor_tiled) {field = #cute_nvgpu.atom_copy_field_non_exec_tma_load<tma_desc>} : !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 262144, tma_gbasis = <"(64,256):(1@1,1@0)">, internal_val_type = f16>
    %lay_6 = cute.get_layout(%arg1) : !memref_gmem_f16_
    %213 = cute.get_shape(%lay_6) : (!cute.layout<"(?,?{div=8192}):(?{i64 div=8192},1)">) -> !cute.shape<"(?,?{div=8192})">
    %lay_7 = cute.make_layout(%213, %5) : !cute.layout<"(?,?{div=8192}):(1@1,1@0)">
    %view_8 = cute.make_view(%4, %lay_7) : !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">
    %lay_9 = cute.get_layout(%arg2) : !memref_gmem_f16_
    %214 = cute.get_shape(%lay_9) : (!cute.layout<"(?,?{div=8192}):(?{i64 div=8192},1)">) -> !cute.shape<"(?,?{div=8192})">
    %e0, %e1 = cute.get_leaves(%214) : !cute.shape<"(?,?{div=8192})">
    %itup = cute.to_int_tuple(%e0) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %itup_10 = cute.to_int_tuple(%e1) : !cute.shape<"?{div=8192}"> to !cute.int_tuple<"?{div=8192}">
    %int_tuple = cute.make_int_tuple(%itup, %itup_10) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8192}">) -> !cute.int_tuple<"(?,?{div=8192},1)">
    %215:2 = cute.get_scalars(%int_tuple) <{only_dynamic}> : !cute.int_tuple<"(?,?{div=8192},1)">
    %216 = arith.ceildivsi %215#0, %c128_i32 : i32
    %217 = arith.ceildivsi %215#1, %c256_i32 : i32
    %int_tuple_11 = cute.make_int_tuple(%216, %217) : (i32, i32) -> !cute.int_tuple<"(?,?,1)">
    %e0_12, %e1_13, %e2 = cute.get_leaves(%int_tuple_11) : !cute.int_tuple<"(?,?,1)">
    %218 = cute.get_scalars(%e0_12) : !cute.int_tuple<"?">
    %219 = cute.get_scalars(%e1_13) : !cute.int_tuple<"?">
    %220 = cuda.cast %c0_i64 : i64 -> !cuda.stream
    %221 = cuda.launch_cfg.create<max_attrs = 2 : i32> (blockDim = (%c128_i32, %c1_i32, %c1_i32), dynamicSmemBytes = %c196736_i64, gridDim = (%218, %219, %c1_i32), stream = %220) : i32, i32, i32, i64, i32, i32, i32, !cuda.stream -> !cuda.launch_cfg<max_attrs = 2>
    %222 = cuda.launch_ex @kernels::@kernel_cutlass_kernel_TiledMMA_ThrLayoutVMNK11110000_PermutationMNK____MMAAtom_ThrID10_ShapeMNK12825616_TVLayoutA1128161281128_TVLayoutB1256162561256_TVLayoutC11282561281128_CopyAtom_ThrI_0<%221> (%9, %110, %view, %212, %view_8, %arg2) : !cuda.launch_cfg<max_attrs = 2>, (!mma_f16_f16_f32_128x256x16_, !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, internal_val_type = f16>, !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">, !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 262144, tma_gbasis = <"(64,256):(1@1,1@0)">, internal_val_type = f16>, !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">, !memref_gmem_f16_) -> !cuda.result
    %223 = cuda.cast %222 : !cuda.result -> i32
    cuda.return_if_error %223 : i32
    return %c0_i32 : i32
  }
}
