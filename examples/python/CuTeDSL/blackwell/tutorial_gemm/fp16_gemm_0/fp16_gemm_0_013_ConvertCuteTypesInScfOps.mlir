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
      %37 = arith.floordivsi %36, %c32_i32 : i32
      %38 = cute_nvgpu.arch.make_warp_uniform(%37) : i32
      %39 = nvvm.read.ptx.sreg.ctaid.x range <i32, 0, 2147483647> : i32
      %40 = nvvm.read.ptx.sreg.ctaid.y range <i32, 0, 65535> : i32
      %smem_ptr = cute_nvgpu.arch.get_dyn_smem() : !cute.ptr<i8, smem, align<1024>>
      %ptr = cute.add_offset(%smem_ptr, %26) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"88">) -> !cute.ptr<i8, smem, align<8>>
      %ptr_0 = cute.add_offset(%smem_ptr, %25) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"64">) -> !cute.ptr<i8, smem, align<64>>
      %ptr_1 = cute.add_offset(%smem_ptr, %24) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"80">) -> !cute.ptr<i8, smem, align<16>>
      %iter = cute.recast_iter(%ptr_1) : !cute.ptr<i8, smem, align<16>> to !cute.ptr<i32, smem, align<16>>
      %41 = cute.ptrtoint(%ptr) : !cute.ptr<i8, smem, align<8>> to i32
      %42 = arith.addi %41, %c127_i32 : i32
      %43 = arith.andi %42, %c-128_i32 : i32
      %44 = arith.extsi %43 : i32 to i64
      %iv = cute.assume(%44) : (i64) -> !cute.i64<divby 128>
      %45 = cute.inttoptr(%iv) : !cute.i64<divby 128> to !cute.ptr<i8, smem, align<128>>
      %ptr_2 = cute.add_offset(%45, %23) : (!cute.ptr<i8, smem, align<128>>, !cute.int_tuple<"65536">) -> !cute.ptr<i8, smem, align<128>>
      %iter_3 = cute.recast_iter(%45) : !cute.ptr<i8, smem, align<128>> to !cute.ptr<f16, smem, align<128>, S<3,4,3>>
      %iter_4 = cute.recast_iter(%ptr_2) : !cute.ptr<i8, smem, align<128>> to !cute.ptr<f16, smem, align<128>, S<3,4,3>>
      %46 = arith.cmpi eq, %38, %c0_i32 : i32
      scf.if %46 {
        cute_nvgpu.arch.sm100.alloc_tmem(%c512_i32, %iter) [ cta_1] : i32, !cute.ptr<i32, smem, align<16>>
      }
      scf.if %46 {
        cute_nvgpu.prefetch_tma_desc(%arg1) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, internal_val_type = f16>) -> ()
        cute_nvgpu.prefetch_tma_desc(%arg3) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 262144, tma_gbasis = <"(64,256):(1@1,1@0)">, internal_val_type = f16>) -> ()
      }
      %iter_5 = cute.recast_iter(%smem_ptr) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<i64, smem, align<1024>>
      scf.if %46 {
        %86 = builtin.unrealized_conversion_cast %iter_5 : !cute.ptr<i64, smem, align<1024>> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %86, %c1_i32 : !llvm.ptr<3>, i32
        %ptr_61 = cute.add_offset(%iter_5, %22) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"1">) -> !cute.ptr<i64, smem>
        %87 = builtin.unrealized_conversion_cast %ptr_61 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %87, %c1_i32 : !llvm.ptr<3>, i32
        %ptr_62 = cute.add_offset(%iter_5, %21) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"2">) -> !cute.ptr<i64, smem, align<16>>
        %88 = builtin.unrealized_conversion_cast %ptr_62 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %88, %c1_i32 : !llvm.ptr<3>, i32
        %ptr_63 = cute.add_offset(%iter_5, %20) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"3">) -> !cute.ptr<i64, smem>
        %89 = builtin.unrealized_conversion_cast %ptr_63 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %89, %c1_i32 : !llvm.ptr<3>, i32
      }
      %ptr_6 = cute.add_offset(%iter_5, %19) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"4">) -> !cute.ptr<i64, smem, align<32>>
      scf.if %46 {
        %86 = builtin.unrealized_conversion_cast %ptr_6 : !cute.ptr<i64, smem, align<32>> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %86, %c1_i32 : !llvm.ptr<3>, i32
        %int_tuple_61 = cute.make_int_tuple() : () -> !cute.int_tuple<"5">
        %ptr_62 = cute.add_offset(%iter_5, %int_tuple_61) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"5">) -> !cute.ptr<i64, smem>
        %87 = builtin.unrealized_conversion_cast %ptr_62 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %87, %c1_i32 : !llvm.ptr<3>, i32
        %int_tuple_63 = cute.make_int_tuple() : () -> !cute.int_tuple<"6">
        %ptr_64 = cute.add_offset(%iter_5, %int_tuple_63) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"6">) -> !cute.ptr<i64, smem, align<16>>
        %88 = builtin.unrealized_conversion_cast %ptr_64 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %88, %c1_i32 : !llvm.ptr<3>, i32
        %int_tuple_65 = cute.make_int_tuple() : () -> !cute.int_tuple<"7">
        %ptr_66 = cute.add_offset(%iter_5, %int_tuple_65) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"7">) -> !cute.ptr<i64, smem>
        %89 = builtin.unrealized_conversion_cast %ptr_66 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %89, %c1_i32 : !llvm.ptr<3>, i32
      }
      nvvm.fence.mbarrier.init
      nvvm.barrier
      %iter_7 = cute.recast_iter(%ptr_0) : !cute.ptr<i8, smem, align<64>> to !cute.ptr<i64, smem, align<64>>
      scf.if %46 {
        %86 = builtin.unrealized_conversion_cast %iter_7 : !cute.ptr<i64, smem, align<64>> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %86, %c1_i32 : !llvm.ptr<3>, i32
      }
      %ptr_8 = cute.add_offset(%iter_7, %22) : (!cute.ptr<i64, smem, align<64>>, !cute.int_tuple<"1">) -> !cute.ptr<i64, smem>
      scf.if %46 {
        %86 = builtin.unrealized_conversion_cast %ptr_8 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %86, %c128_i32 : !llvm.ptr<3>, i32
      }
      nvvm.fence.mbarrier.init
      nvvm.barrier
      %coord = cute.make_coord(%39, %40) : (i32, i32) -> !cute.coord<"(?,?,_)">
      %47:2 = cute.get_scalars(%coord) <{only_dynamic}> : !cute.coord<"(?,?,_)">
      %coord_9 = cute.make_coord(%47#0) : (i32) -> !cute.coord<"((_,_),(?,_))">
      %lay = cute.get_layout(%arg2) : !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">
      %48:2 = cute.get_scalars(%lay) <{only_dynamic}> : !cute.layout<"(?,?{div=8192}):(1@1,1@0)">
      %49 = arith.ceildivsi %48#0, %c128_i32 : i32
      %50 = arith.ceildivsi %48#1, %c64_i32 : i32
      %shape = cute.make_shape(%49, %50) : (i32, i32) -> !cute.shape<"((128,64),(?,?))">
      %lay_10 = cute.make_layout(%shape, %18) : !cute.layout<"((128,64),(?,?)):((1@1,1@0),(128@1,64@0))">
      %51:2 = cute.get_scalars(%lay_10) <{only_dynamic}> : !cute.layout<"((128,64),(?,?)):((1@1,1@0),(128@1,64@0))">
      %shape_11 = cute.make_shape(%51#1) : (i32) -> !cute.shape<"(128,64,?)">
      %lay_12 = cute.make_layout(%shape_11, %17) : !cute.layout<"(128,64,?):(1@1,1@0,64@0)">
      %idx = cute.crd2idx(%coord_9, %lay_10) : (!cute.coord<"((_,_),(?,_))">, !cute.layout<"((128,64),(?,?)):((1@1,1@0),(128@1,64@0))">) -> !cute.int_tuple<"(0,?{div=128})">
      %tup = cute.add_offset(%16, %idx) : (!cute.int_tuple<"(0,0)">, !cute.int_tuple<"(0,?{div=128})">) -> !cute.int_tuple<"(0,?{div=128})">
      %coord_13 = cute.make_coord(%47#1) : (i32) -> !cute.coord<"((_,_),(?,_))">
      %lay_14 = cute.get_layout(%arg4) : !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">
      %52:2 = cute.get_scalars(%lay_14) <{only_dynamic}> : !cute.layout<"(?,?{div=8192}):(1@1,1@0)">
      %53 = arith.ceildivsi %52#0, %c256_i32 : i32
      %54 = arith.ceildivsi %52#1, %c64_i32 : i32
      %shape_15 = cute.make_shape(%53, %54) : (i32, i32) -> !cute.shape<"((256,64),(?,?))">
      %lay_16 = cute.make_layout(%shape_15, %15) : !cute.layout<"((256,64),(?,?)):((1@1,1@0),(256@1,64@0))">
      %55:2 = cute.get_scalars(%lay_16) <{only_dynamic}> : !cute.layout<"((256,64),(?,?)):((1@1,1@0),(256@1,64@0))">
      %shape_17 = cute.make_shape(%55#1) : (i32) -> !cute.shape<"(256,64,?)">
      %lay_18 = cute.make_layout(%shape_17, %17) : !cute.layout<"(256,64,?):(1@1,1@0,64@0)">
      %idx_19 = cute.crd2idx(%coord_13, %lay_16) : (!cute.coord<"((_,_),(?,_))">, !cute.layout<"((256,64),(?,?)):((1@1,1@0),(256@1,64@0))">) -> !cute.int_tuple<"(0,?{div=256})">
      %tup_20 = cute.add_offset(%16, %idx_19) : (!cute.int_tuple<"(0,0)">, !cute.int_tuple<"(0,?{div=256})">) -> !cute.int_tuple<"(0,?{div=256})">
      %coord_21 = cute.make_coord(%47#0, %47#1) : (i32, i32) -> !cute.coord<"((_,_),(?,?))">
      %lay_22 = cute.get_layout(%arg5) : !memref_gmem_f16_
      %56:3 = cute.get_scalars(%lay_22) <{only_dynamic}> : !cute.layout<"(?,?{div=8192}):(?{i64 div=8192},1)">
      %57 = arith.ceildivsi %56#0, %c128_i32 : i32
      %58 = arith.muli %56#2, %c128_i64 : i64
      %59 = arith.ceildivsi %56#1, %c256_i32 : i32
      %shape_23 = cute.make_shape(%57, %59) : (i32, i32) -> !cute.shape<"((128,256),(?,?))">
      %iv_24 = cute.assume(%56#2) : (i64) -> !cute.i64<divby 8192>
      %iv_25 = cute.assume(%58) : (i64) -> !cute.i64<divby 1048576>
      %stride = cute.make_stride(%iv_24, %iv_25) : (!cute.i64<divby 8192>, !cute.i64<divby 1048576>) -> !cute.stride<"((?{i64 div=8192},1),(?{i64 div=1048576},256))">
      %lay_26 = cute.make_layout(%shape_23, %stride) : !cute.layout<"((128,256),(?,?)):((?{i64 div=8192},1),(?{i64 div=1048576},256))">
      %60:4 = cute.get_scalars(%lay_26) <{only_dynamic}> : !cute.layout<"((128,256),(?,?)):((?{i64 div=8192},1),(?{i64 div=1048576},256))">
      %iv_27 = cute.assume(%60#2) : (i64) -> !cute.i64<divby 8192>
      %stride_28 = cute.make_stride(%iv_27) : (!cute.i64<divby 8192>) -> !cute.stride<"(?{i64 div=8192},1)">
      %lay_29 = cute.make_layout(%14, %stride_28) : !cute.layout<"(128,256):(?{i64 div=8192},1)">
      %idx_30 = cute.crd2idx(%coord_21, %lay_26) : (!cute.coord<"((_,_),(?,?))">, !cute.layout<"((128,256),(?,?)):((?{i64 div=8192},1),(?{i64 div=1048576},256))">) -> !cute.int_tuple<"?{i64 div=256}">
      %iter_31 = cute.get_iter(%arg5) : !memref_gmem_f16_
      %ptr_32 = cute.add_offset(%iter_31, %idx_30) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{i64 div=256}">) -> !cute.ptr<f16, gmem, align<32>>
      %61 = cute.get_scalars(%lay_12) <{only_dynamic}> : !cute.layout<"(128,64,?):(1@1,1@0,64@0)">
      %shape_33 = cute.make_shape(%61) : (i32) -> !cute.shape<"((128,16),1,4,?)">
      %lay_34 = cute.make_layout(%shape_33, %13) : !cute.layout<"((128,16),1,4,?):((1@1,1@0),0,16@0,64@0)">
      %62 = cute.get_scalars(%lay_18) <{only_dynamic}> : !cute.layout<"(256,64,?):(1@1,1@0,64@0)">
      %shape_35 = cute.make_shape(%62) : (i32) -> !cute.shape<"((256,16),1,4,?)">
      %lay_36 = cute.make_layout(%shape_35, %13) : !cute.layout<"((256,16),1,4,?):((1@1,1@0),0,16@0,64@0)">
      %63 = cute.get_scalars(%lay_29) <{only_dynamic}> : !cute.layout<"(128,256):(?{i64 div=8192},1)">
      %iv_37 = cute.assume(%63) : (i64) -> !cute.i64<divby 8192>
      %stride_38 = cute.make_stride(%iv_37) : (!cute.i64<divby 8192>) -> !cute.stride<"((?{i64 div=8192},1),0,0)">
      %lay_39 = cute.make_layout(%12, %stride_38) : !cute.layout<"((128,256),1,1):((?{i64 div=8192},1),0,0)">
      %ummaSmemDesc = cute_nvgpu.make_umma_smem_desc(%iter_3 : !cute.ptr<f16, smem, align<128>, S<3,4,3>>) layout = <"((128,16),1,4,4):((64,1),0,16,8192)">, major = <k> -> !cute_nvgpu.smem_desc
      %ummaSmemDesc_40 = cute_nvgpu.make_umma_smem_desc(%iter_4 : !cute.ptr<f16, smem, align<128>, S<3,4,3>>) layout = <"((256,16),1,4,4):((64,1),0,16,16384)">, major = <k> -> !cute_nvgpu.smem_desc
      %64 = cute.get_scalars(%lay_34) <{only_dynamic}> : !cute.layout<"((128,16),1,4,?):((1@1,1@0),0,16@0,64@0)">
      %shape_41 = cute.make_shape(%64) : (i32) -> !cute.shape<"(((128,16),1,4),?)">
      %lay_42 = cute.make_layout(%shape_41, %11) : !cute.layout<"(((128,16),1,4),?):(((1@1,1@0),0,16@0),64@0)">
      %65 = cute.get_scalars(%lay_42) <{only_dynamic}> : !cute.layout<"(((128,16),1,4),?):(((1@1,1@0),0,16@0),64@0)">
      %shape_43 = cute.make_shape(%65) : (i32) -> !cute.shape<"(((64,128),1),?)">
      %lay_44 = cute.make_layout(%shape_43, %10) : !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">
      %66 = cute.get_scalars(%lay_36) <{only_dynamic}> : !cute.layout<"((256,16),1,4,?):((1@1,1@0),0,16@0,64@0)">
      %shape_45 = cute.make_shape(%66) : (i32) -> !cute.shape<"(((256,16),1,4),?)">
      %lay_46 = cute.make_layout(%shape_45, %11) : !cute.layout<"(((256,16),1,4),?):(((1@1,1@0),0,16@0),64@0)">
      %67 = cute.get_scalars(%lay_46) <{only_dynamic}> : !cute.layout<"(((256,16),1,4),?):(((1@1,1@0),0,16@0),64@0)">
      %shape_47 = cute.make_shape(%67) : (i32) -> !cute.shape<"(((64,256),1),?)">
      %lay_48 = cute.make_layout(%shape_47, %10) : !cute.layout<"(((64,256),1),?):(((1@0,1@1),0),64@0)">
      nvvm.barrier id = %c1_i32 number_of_threads = %c128_i32
      %tmem_ptr = cute_nvgpu.arch.sm100.retrieve_tmem_ptr(%iter) : !cute.ptr<i32, smem, align<16>> -> !cute.ptr<f32, tmem, align<16>>
      %68 = cute.get_scalars(%lay_39) <{only_dynamic}> : !cute.layout<"((128,256),1,1):((?{i64 div=8192},1),0,0)">
      %iv_49 = cute.assume(%68) : (i64) -> !cute.i64<divby 8192>
      %stride_50 = cute.make_stride(%iv_49) : (!cute.i64<divby 8192>) -> !cute.stride<"(((?{i64 div=8192},1)),((0,64),0,0))">
      %lay_51 = cute.make_layout(%9, %stride_50) : !cute.layout<"(((128,64)),((1,4),1,1)):(((?{i64 div=8192},1)),((0,64),0,0))">
      %coord_52 = cute.make_coord(%27) : (i32) -> !cute.coord<"?">
      %69 = cute.get_scalars(%coord_52) <{only_dynamic}> : !cute.coord<"?">
      %70 = arith.divsi %69, %c32_i32 : i32
      %71 = arith.muli %70, %c2097152_i32 : i32
      %iv_53 = cute.assume(%71) : (i32) -> !cute.i32<divby 2097152>
      %int_tuple = cute.make_int_tuple(%iv_53) : (!cute.i32<divby 2097152>) -> !cute.int_tuple<"?{div=2097152}">
      %ptr_54 = cute.add_offset(%tmem_ptr, %int_tuple) : (!cute.ptr<f32, tmem, align<16>>, !cute.int_tuple<"?{div=2097152}">) -> !cute.ptr<f32, tmem, align<16>>
      %72 = cute.get_scalars(%lay_51) <{only_dynamic}> : !cute.layout<"(((128,64)),((1,4),1,1)):(((?{i64 div=8192},1)),((0,64),0,0))">
      %73 = arith.muli %72, %c32_i64 : i64
      %74 = arith.remsi %69, %c32_i32 : i32
      %75 = arith.extsi %74 : i32 to i64
      %76 = arith.muli %75, %72 : i64
      %77 = arith.extsi %70 : i32 to i64
      %78 = arith.muli %77, %73 : i64
      %79 = arith.addi %76, %78 : i64
      %iv_55 = cute.assume(%79) : (i64) -> !cute.i64<divby 8192>
      %int_tuple_56 = cute.make_int_tuple(%iv_55) : (!cute.i64<divby 8192>) -> !cute.int_tuple<"?{i64 div=8192}">
      %ptr_57 = cute.add_offset(%ptr_32, %int_tuple_56) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{i64 div=8192}">) -> !cute.ptr<f16, gmem, align<32>>
      %rmem = cute.memref.alloca() : !memref_rmem_f32_
      %rmem_58 = cute.memref.alloca() : !memref_rmem_f16_
      %sz = cute.size(%lay_12) <{mode = [2]}> : (!cute.layout<"(128,64,?):(1@1,1@0,64@0)">) -> !cute.int_tuple<"?">
      %e0 = cute.get_leaves(%sz) : !cute.int_tuple<"?">
      %80 = cute.get_scalars(%e0) : !cute.int_tuple<"?">
      scf.if %46 {
        %86 = builtin.unrealized_conversion_cast %ptr_8 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        nvvm.mbarrier.try_wait.parity.shared %86, %c1_i32, %c10000000_i32 : !llvm.ptr<3>, i32, i32
        %87 = cute_nvgpu.atom.make_exec_tma(%arg1) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128):(1@1,1@0)">>
        %88 = cute_nvgpu.atom.make_exec_tma(%arg3) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 262144, tma_gbasis = <"(64,256):(1@1,1@0)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_load<f16, copy_bits = 262144, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,256):(1@1,1@0)">>
        %89 = arith.minsi %80, %c2_i32 : i32
        %90 = cute.get_scalars(%22) : !cute.int_tuple<"1">
        %91:3 = scf.for %arg6 = %c0_i32 to %89 step %c1_i32 iter_args(%arg7 = %c0_i32, %arg8 = %c1_i32, %arg9 = %c0_i32) -> (i32, i32, i32)  : i32 {
          %int_tuple_61 = cute.make_int_tuple(%arg7) : (i32) -> !cute.int_tuple<"?">
          %ptr_62 = cute.add_offset(%ptr_6, %int_tuple_61) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
          %95 = builtin.unrealized_conversion_cast %ptr_62 : !cute.ptr<i64, smem> to !llvm.ptr<3>
          nvvm.mbarrier.try_wait.parity.shared %95, %arg8, %c10000000_i32 : !llvm.ptr<3>, i32, i32
          %96 = nvvm.elect.sync -> i1
          scf.if %96 {
            %ptr_80 = cute.add_offset(%iter_5, %int_tuple_61) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
            %108 = builtin.unrealized_conversion_cast %ptr_80 : !cute.ptr<i64, smem> to !llvm.ptr<3>
            nvvm.mbarrier.txn %108, %c49152_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
          }
          %97 = arith.addi %arg7, %c1_i32 : i32
          %98 = arith.addi %arg9, %c1_i32 : i32
          %99 = arith.cmpi eq, %97, %c4_i32 : i32
          %100 = arith.select %99, %c0_i32, %97 : i32
          %101 = scf.if %99 -> (i32) {
            %108 = arith.xori %arg8, %c1_i32 : i32
            scf.yield %108 : i32
          } else {
            scf.yield %arg8 : i32
          }
          %coord_63 = cute.make_coord(%arg9) : (i32) -> !cute.coord<"(_,?)">
          %idx_64 = cute.crd2idx(%coord_63, %lay_44) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
          %tup_65 = cute.add_offset(%tup, %idx_64) : (!cute.int_tuple<"(0,?{div=128})">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
          %e0_66, %e1 = cute.get_leaves(%tup_65) : !cute.int_tuple<"(?{div=64},?{div=128})">
          %coord_67 = cute.make_coord(%arg7) : (i32) -> !cute.coord<"(_,?)">
          %idx_68 = cute.crd2idx(%coord_67, %8) : (!cute.coord<"(_,?)">, !cute.layout<"((8192,1),4):((1,0),8192)">) -> !cute.int_tuple<"?{div=8192}">
          %ptr_69 = cute.add_offset(%iter_3, %idx_68) : (!cute.ptr<f16, smem, align<128>, S<3,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<f16, smem, align<128>, S<3,4,3>>
          %ptr_70 = cute.add_offset(%iter_5, %int_tuple_61) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
          %int_tuple_71 = cute.make_int_tuple(%e0_66, %e1) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=128}">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
          %102 = cute_nvgpu.atom.set_value(%87, %ptr_70 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128):(1@1,1@0)">>
          %103 = cute_nvgpu.atom.get_value(%102 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
          %TMADescAddr = cute_nvgpu.get_tma_desc_addr(%102 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128):(1@1,1@0)">>) -> !cute.ptr<generic, align<64>>
          %104:2 = cute.get_scalars(%int_tuple_71) : !cute.int_tuple<"(?{div=64},?{div=128})">
          scf.for %arg10 = %c0_i32 to %90 step %c1_i32  : i32 {
            cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr : !cute.ptr<generic, align<64>>, %ptr_69 : !cute.ptr<f16, smem, align<128>, S<3,4,3>>, %103 : !cute.ptr<smem, align<8>>, [%104#0, %104#1] : i32, i32) mode = <tiled> num_cta = 1 : i32
          } {llvm.loop_annotation = #loop_annotation}
          %idx_72 = cute.crd2idx(%coord_63, %lay_48) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,256),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
          %tup_73 = cute.add_offset(%tup_20, %idx_72) : (!cute.int_tuple<"(0,?{div=256})">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.int_tuple<"(?{div=64},?{div=256})">
          %e0_74, %e1_75 = cute.get_leaves(%tup_73) : !cute.int_tuple<"(?{div=64},?{div=256})">
          %idx_76 = cute.crd2idx(%coord_67, %7) : (!cute.coord<"(_,?)">, !cute.layout<"((16384,1),4):((1,0),16384)">) -> !cute.int_tuple<"?{div=16384}">
          %ptr_77 = cute.add_offset(%iter_4, %idx_76) : (!cute.ptr<f16, smem, align<128>, S<3,4,3>>, !cute.int_tuple<"?{div=16384}">) -> !cute.ptr<f16, smem, align<128>, S<3,4,3>>
          %int_tuple_78 = cute.make_int_tuple(%e0_74, %e1_75) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=256}">) -> !cute.int_tuple<"(?{div=64},?{div=256})">
          %105 = cute_nvgpu.atom.set_value(%88, %ptr_70 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 262144, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,256):(1@1,1@0)">>
          %106 = cute_nvgpu.atom.get_value(%105 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 262144, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,256):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
          %TMADescAddr_79 = cute_nvgpu.get_tma_desc_addr(%105 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 262144, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,256):(1@1,1@0)">>) -> !cute.ptr<generic, align<64>>
          %107:2 = cute.get_scalars(%int_tuple_78) : !cute.int_tuple<"(?{div=64},?{div=256})">
          scf.for %arg10 = %c0_i32 to %90 step %c1_i32  : i32 {
            cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr_79 : !cute.ptr<generic, align<64>>, %ptr_77 : !cute.ptr<f16, smem, align<128>, S<3,4,3>>, %106 : !cute.ptr<smem, align<8>>, [%107#0, %107#1] : i32, i32) mode = <tiled> num_cta = 1 : i32
          } {llvm.loop_annotation = #loop_annotation}
          scf.yield %100, %101, %98 : i32, i32, i32
        }
        %92 = cute.get_scalars(%22) : !cute.int_tuple<"1">
        %93:7 = scf.for %arg6 = %c0_i32 to %80 step %c1_i32 iter_args(%arg7 = %91#2, %arg8 = %91#0, %arg9 = %91#1, %arg10 = %c0_i32, %arg11 = %c0_i32, %arg12 = %c0_i32, %arg13 = %0) -> (i32, i32, i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>)  : i32 {
          %95 = builtin.unrealized_conversion_cast %arg13 : !llvm.struct<(i1, i1, i1)> to !mma_f16_f16_f32_128x256x16_
          %96 = arith.addi %arg6, %89 : i32
          %97 = arith.cmpi ult, %96, %80 : i32
          %98:3 = scf.if %97 -> (i32, i32, i32) {
            %int_tuple_83 = cute.make_int_tuple(%arg8) : (i32) -> !cute.int_tuple<"?">
            %ptr_84 = cute.add_offset(%ptr_6, %int_tuple_83) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
            %147 = builtin.unrealized_conversion_cast %ptr_84 : !cute.ptr<i64, smem> to !llvm.ptr<3>
            nvvm.mbarrier.try_wait.parity.shared %147, %arg9, %c10000000_i32 : !llvm.ptr<3>, i32, i32
            %148 = nvvm.elect.sync -> i1
            scf.if %148 {
              %ptr_102 = cute.add_offset(%iter_5, %int_tuple_83) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
              %161 = builtin.unrealized_conversion_cast %ptr_102 : !cute.ptr<i64, smem> to !llvm.ptr<3>
              nvvm.mbarrier.txn %161, %c49152_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
            }
            %149 = arith.addi %arg8, %c1_i32 : i32
            %150 = arith.addi %arg7, %c1_i32 : i32
            %151 = arith.cmpi eq, %149, %c4_i32 : i32
            %152 = arith.select %151, %c0_i32, %149 : i32
            %153 = scf.if %151 -> (i32) {
              %161 = arith.xori %arg9, %c1_i32 : i32
              scf.yield %161 : i32
            } else {
              scf.yield %arg9 : i32
            }
            %coord_85 = cute.make_coord(%arg7) : (i32) -> !cute.coord<"(_,?)">
            %idx_86 = cute.crd2idx(%coord_85, %lay_44) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
            %tup_87 = cute.add_offset(%tup, %idx_86) : (!cute.int_tuple<"(0,?{div=128})">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
            %e0_88, %e1 = cute.get_leaves(%tup_87) : !cute.int_tuple<"(?{div=64},?{div=128})">
            %coord_89 = cute.make_coord(%arg8) : (i32) -> !cute.coord<"(_,?)">
            %idx_90 = cute.crd2idx(%coord_89, %8) : (!cute.coord<"(_,?)">, !cute.layout<"((8192,1),4):((1,0),8192)">) -> !cute.int_tuple<"?{div=8192}">
            %ptr_91 = cute.add_offset(%iter_3, %idx_90) : (!cute.ptr<f16, smem, align<128>, S<3,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<f16, smem, align<128>, S<3,4,3>>
            %ptr_92 = cute.add_offset(%iter_5, %int_tuple_83) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
            %int_tuple_93 = cute.make_int_tuple(%e0_88, %e1) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=128}">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
            %154 = cute_nvgpu.atom.set_value(%87, %ptr_92 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128):(1@1,1@0)">>
            %155 = cute.get_scalars(%22) : !cute.int_tuple<"1">
            %156 = cute_nvgpu.atom.get_value(%154 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
            %TMADescAddr = cute_nvgpu.get_tma_desc_addr(%154 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128):(1@1,1@0)">>) -> !cute.ptr<generic, align<64>>
            %157:2 = cute.get_scalars(%int_tuple_93) : !cute.int_tuple<"(?{div=64},?{div=128})">
            scf.for %arg14 = %c0_i32 to %155 step %c1_i32  : i32 {
              cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr : !cute.ptr<generic, align<64>>, %ptr_91 : !cute.ptr<f16, smem, align<128>, S<3,4,3>>, %156 : !cute.ptr<smem, align<8>>, [%157#0, %157#1] : i32, i32) mode = <tiled> num_cta = 1 : i32
            } {llvm.loop_annotation = #loop_annotation}
            %idx_94 = cute.crd2idx(%coord_85, %lay_48) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,256),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
            %tup_95 = cute.add_offset(%tup_20, %idx_94) : (!cute.int_tuple<"(0,?{div=256})">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.int_tuple<"(?{div=64},?{div=256})">
            %e0_96, %e1_97 = cute.get_leaves(%tup_95) : !cute.int_tuple<"(?{div=64},?{div=256})">
            %idx_98 = cute.crd2idx(%coord_89, %7) : (!cute.coord<"(_,?)">, !cute.layout<"((16384,1),4):((1,0),16384)">) -> !cute.int_tuple<"?{div=16384}">
            %ptr_99 = cute.add_offset(%iter_4, %idx_98) : (!cute.ptr<f16, smem, align<128>, S<3,4,3>>, !cute.int_tuple<"?{div=16384}">) -> !cute.ptr<f16, smem, align<128>, S<3,4,3>>
            %int_tuple_100 = cute.make_int_tuple(%e0_96, %e1_97) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=256}">) -> !cute.int_tuple<"(?{div=64},?{div=256})">
            %158 = cute_nvgpu.atom.set_value(%88, %ptr_92 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 262144, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,256):(1@1,1@0)">>
            %159 = cute_nvgpu.atom.get_value(%158 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 262144, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,256):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
            %TMADescAddr_101 = cute_nvgpu.get_tma_desc_addr(%158 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 262144, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,256):(1@1,1@0)">>) -> !cute.ptr<generic, align<64>>
            %160:2 = cute.get_scalars(%int_tuple_100) : !cute.int_tuple<"(?{div=64},?{div=256})">
            scf.for %arg14 = %c0_i32 to %155 step %c1_i32  : i32 {
              cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr_101 : !cute.ptr<generic, align<64>>, %ptr_99 : !cute.ptr<f16, smem, align<128>, S<3,4,3>>, %159 : !cute.ptr<smem, align<8>>, [%160#0, %160#1] : i32, i32) mode = <tiled> num_cta = 1 : i32
            } {llvm.loop_annotation = #loop_annotation}
            scf.yield %152, %153, %150 : i32, i32, i32
          } else {
            scf.yield %arg8, %arg9, %arg7 : i32, i32, i32
          }
          %int_tuple_61 = cute.make_int_tuple(%arg11) : (i32) -> !cute.int_tuple<"?">
          %ptr_62 = cute.add_offset(%iter_5, %int_tuple_61) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
          %99 = builtin.unrealized_conversion_cast %ptr_62 : !cute.ptr<i64, smem> to !llvm.ptr<3>
          nvvm.mbarrier.try_wait.parity.shared %99, %arg12, %c10000000_i32 : !llvm.ptr<3>, i32, i32
          %100 = arith.addi %arg11, %c1_i32 : i32
          %101 = arith.addi %arg10, %c1_i32 : i32
          %102 = arith.cmpi eq, %100, %c4_i32 : i32
          %103 = arith.select %102, %c0_i32, %100 : i32
          %104 = scf.if %102 -> (i32) {
            %147 = arith.xori %arg12, %c1_i32 : i32
            scf.yield %147 : i32
          } else {
            scf.yield %arg12 : i32
          }
          %coord_63 = cute.make_coord(%arg11) : (i32) -> !cute.coord<"(_,_,0,?)">
          %idx_64 = cute.crd2idx(%coord_63, %6) : (!cute.coord<"(_,_,0,?)">, !cute.layout<"(1,1,4,4):(0,0,2,1024)">) -> !cute.int_tuple<"?{div=1024}">
          %tup_65 = cute.add_offset(%ummaSmemDesc, %idx_64) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=1024}">) -> !cute_nvgpu.smem_desc
          %idx_66 = cute.crd2idx(%coord_63, %5) : (!cute.coord<"(_,_,0,?)">, !cute.layout<"(1,1,4,4):(0,0,2,2048)">) -> !cute.int_tuple<"?{div=2048}">
          %tup_67 = cute.add_offset(%ummaSmemDesc_40, %idx_66) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2048}">) -> !cute_nvgpu.smem_desc
          %105 = cute_nvgpu.atom.get_value(%95 : !mma_f16_f16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : i1
          %106 = cute_nvgpu.atom.get_value(%95 : !mma_f16_f16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : i1
          %107 = cute_nvgpu.atom.get_value(%95 : !mma_f16_f16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : i1
          %108 = arith.extui %105 : i1 to i32
          %109 = arith.extui %106 : i1 to i32
          %110 = arith.shli %108, %c13_i32 : i32
          %111 = arith.shli %109, %c14_i32 : i32
          %112 = arith.ori %110, %c138412048_i32 : i32
          %113 = arith.ori %112, %111 : i32
          scf.for %arg14 = %c0_i32 to %92 step %c1_i32  : i32 {
            scf.for %arg15 = %c0_i32 to %92 step %c1_i32  : i32 {
              scf.for %arg16 = %c0_i32 to %92 step %c1_i32  : i32 {
                cute_nvgpu.arch.mma.SM100.umma(%tup_65, %tup_67, %tmem_ptr, %113, %107) {num_cta = 1 : i32, scale = 0 : i32, a_type = f16} : (!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, !cute.ptr<f32, tmem, align<16>>, i32, i1) -> ()
              } {llvm.loop_annotation = #loop_annotation}
            } {llvm.loop_annotation = #loop_annotation}
          } {llvm.loop_annotation = #loop_annotation}
          %114 = cute_nvgpu.atom.set_value(%95, %true : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_f16_f16_f32_128x256x16_
          %coord_68 = cute.make_coord(%arg11) : (i32) -> !cute.coord<"(_,_,1,?)">
          %idx_69 = cute.crd2idx(%coord_68, %6) : (!cute.coord<"(_,_,1,?)">, !cute.layout<"(1,1,4,4):(0,0,2,1024)">) -> !cute.int_tuple<"?{div=2}">
          %tup_70 = cute.add_offset(%ummaSmemDesc, %idx_69) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
          %idx_71 = cute.crd2idx(%coord_68, %5) : (!cute.coord<"(_,_,1,?)">, !cute.layout<"(1,1,4,4):(0,0,2,2048)">) -> !cute.int_tuple<"?{div=2}">
          %tup_72 = cute.add_offset(%ummaSmemDesc_40, %idx_71) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
          %115 = cute_nvgpu.atom.get_value(%114 : !mma_f16_f16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : i1
          %116 = cute_nvgpu.atom.get_value(%114 : !mma_f16_f16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : i1
          %117 = cute_nvgpu.atom.get_value(%114 : !mma_f16_f16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : i1
          %118 = arith.extui %115 : i1 to i32
          %119 = arith.extui %116 : i1 to i32
          %120 = arith.shli %118, %c13_i32 : i32
          %121 = arith.shli %119, %c14_i32 : i32
          %122 = arith.ori %120, %c138412048_i32 : i32
          %123 = arith.ori %122, %121 : i32
          scf.for %arg14 = %c0_i32 to %92 step %c1_i32  : i32 {
            scf.for %arg15 = %c0_i32 to %92 step %c1_i32  : i32 {
              scf.for %arg16 = %c0_i32 to %92 step %c1_i32  : i32 {
                cute_nvgpu.arch.mma.SM100.umma(%tup_70, %tup_72, %tmem_ptr, %123, %117) {num_cta = 1 : i32, scale = 0 : i32, a_type = f16} : (!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, !cute.ptr<f32, tmem, align<16>>, i32, i1) -> ()
              } {llvm.loop_annotation = #loop_annotation}
            } {llvm.loop_annotation = #loop_annotation}
          } {llvm.loop_annotation = #loop_annotation}
          %124 = cute_nvgpu.atom.set_value(%114, %true : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_f16_f16_f32_128x256x16_
          %coord_73 = cute.make_coord(%arg11) : (i32) -> !cute.coord<"(_,_,2,?)">
          %idx_74 = cute.crd2idx(%coord_73, %6) : (!cute.coord<"(_,_,2,?)">, !cute.layout<"(1,1,4,4):(0,0,2,1024)">) -> !cute.int_tuple<"?{div=4}">
          %tup_75 = cute.add_offset(%ummaSmemDesc, %idx_74) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=4}">) -> !cute_nvgpu.smem_desc
          %idx_76 = cute.crd2idx(%coord_73, %5) : (!cute.coord<"(_,_,2,?)">, !cute.layout<"(1,1,4,4):(0,0,2,2048)">) -> !cute.int_tuple<"?{div=4}">
          %tup_77 = cute.add_offset(%ummaSmemDesc_40, %idx_76) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=4}">) -> !cute_nvgpu.smem_desc
          %125 = cute_nvgpu.atom.get_value(%124 : !mma_f16_f16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : i1
          %126 = cute_nvgpu.atom.get_value(%124 : !mma_f16_f16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : i1
          %127 = cute_nvgpu.atom.get_value(%124 : !mma_f16_f16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : i1
          %128 = arith.extui %125 : i1 to i32
          %129 = arith.extui %126 : i1 to i32
          %130 = arith.shli %128, %c13_i32 : i32
          %131 = arith.shli %129, %c14_i32 : i32
          %132 = arith.ori %130, %c138412048_i32 : i32
          %133 = arith.ori %132, %131 : i32
          scf.for %arg14 = %c0_i32 to %92 step %c1_i32  : i32 {
            scf.for %arg15 = %c0_i32 to %92 step %c1_i32  : i32 {
              scf.for %arg16 = %c0_i32 to %92 step %c1_i32  : i32 {
                cute_nvgpu.arch.mma.SM100.umma(%tup_75, %tup_77, %tmem_ptr, %133, %127) {num_cta = 1 : i32, scale = 0 : i32, a_type = f16} : (!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, !cute.ptr<f32, tmem, align<16>>, i32, i1) -> ()
              } {llvm.loop_annotation = #loop_annotation}
            } {llvm.loop_annotation = #loop_annotation}
          } {llvm.loop_annotation = #loop_annotation}
          %134 = cute_nvgpu.atom.set_value(%124, %true : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_f16_f16_f32_128x256x16_
          %coord_78 = cute.make_coord(%arg11) : (i32) -> !cute.coord<"(_,_,3,?)">
          %idx_79 = cute.crd2idx(%coord_78, %6) : (!cute.coord<"(_,_,3,?)">, !cute.layout<"(1,1,4,4):(0,0,2,1024)">) -> !cute.int_tuple<"?{div=2}">
          %tup_80 = cute.add_offset(%ummaSmemDesc, %idx_79) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
          %idx_81 = cute.crd2idx(%coord_78, %5) : (!cute.coord<"(_,_,3,?)">, !cute.layout<"(1,1,4,4):(0,0,2,2048)">) -> !cute.int_tuple<"?{div=2}">
          %tup_82 = cute.add_offset(%ummaSmemDesc_40, %idx_81) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
          %135 = cute_nvgpu.atom.get_value(%134 : !mma_f16_f16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : i1
          %136 = cute_nvgpu.atom.get_value(%134 : !mma_f16_f16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : i1
          %137 = cute_nvgpu.atom.get_value(%134 : !mma_f16_f16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : i1
          %138 = arith.extui %135 : i1 to i32
          %139 = arith.extui %136 : i1 to i32
          %140 = arith.shli %138, %c13_i32 : i32
          %141 = arith.shli %139, %c14_i32 : i32
          %142 = arith.ori %140, %c138412048_i32 : i32
          %143 = arith.ori %142, %141 : i32
          scf.for %arg14 = %c0_i32 to %92 step %c1_i32  : i32 {
            scf.for %arg15 = %c0_i32 to %92 step %c1_i32  : i32 {
              scf.for %arg16 = %c0_i32 to %92 step %c1_i32  : i32 {
                cute_nvgpu.arch.mma.SM100.umma(%tup_80, %tup_82, %tmem_ptr, %143, %137) {num_cta = 1 : i32, scale = 0 : i32, a_type = f16} : (!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, !cute.ptr<f32, tmem, align<16>>, i32, i1) -> ()
              } {llvm.loop_annotation = #loop_annotation}
            } {llvm.loop_annotation = #loop_annotation}
          } {llvm.loop_annotation = #loop_annotation}
          %144 = cute_nvgpu.atom.set_value(%134, %true : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_f16_f16_f32_128x256x16_
          %145 = builtin.unrealized_conversion_cast %144 : !mma_f16_f16_f32_128x256x16_ to !llvm.struct<(i1, i1, i1)>
          %146 = nvvm.elect.sync -> i1
          scf.if %146 {
            %ptr_83 = cute.add_offset(%ptr_6, %int_tuple_61) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
            %147 = builtin.unrealized_conversion_cast %ptr_83 : !cute.ptr<i64, smem> to !llvm.ptr<3>
            nvvm.tcgen05.commit.arrive %147 : !llvm.ptr<3>
          }
          scf.yield %98#2, %98#0, %98#1, %101, %103, %104, %145 : i32, i32, i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>
        }
        %94 = nvvm.elect.sync -> i1
        scf.if %94 {
          %dyn_61 = cute.derefine(%iter_7) : !cute.ptr<i64, smem, align<64>> to !cute.ptr<i64, smem>
          %95 = builtin.unrealized_conversion_cast %dyn_61 : !cute.ptr<i64, smem> to !llvm.ptr<3>
          nvvm.tcgen05.commit.arrive %95 : !llvm.ptr<3>
        }
      }
      scf.if %46 {
        cute_nvgpu.arch.sm100.relinquish_tmem_alloc_permit [ cta_1]
      }
      %dyn = cute.derefine(%iter_7) : !cute.ptr<i64, smem, align<64>> to !cute.ptr<i64, smem>
      %81 = builtin.unrealized_conversion_cast %dyn : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %81, %c0_i32, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %iter_59 = cute.get_iter(%rmem) : !memref_rmem_f32_
      %82 = cute.get_scalars(%22) : !cute.int_tuple<"1">
      %83 = builtin.unrealized_conversion_cast %iter_59 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
      %iter_60 = cute.get_iter(%rmem_58) : !memref_rmem_f16_
      %84 = cute.get_scalars(%1) : !cute.int_tuple<"8">
      scf.for %arg6 = %c0_i32 to %c4_i32 step %c1_i32  : i32 {
        %coord_61 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,_,?)">
        %idx_62 = cute.crd2idx(%coord_61, %4) : (!cute.coord<"(_,_,?)">, !cute.layout<"(((64,32),1),1,((1,4),1,1)):(((1,65536),0),0,((0,64),0,0))">) -> !cute.int_tuple<"?{div=64}">
        %ptr_63 = cute.add_offset(%ptr_54, %idx_62) : (!cute.ptr<f32, tmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<f32, tmem, align<16>>
        scf.for %arg7 = %c0_i32 to %82 step %c1_i32  : i32 {
          %88 = "cute_nvgpu.arch.copy.SM100.tmem_load"(%ptr_63) <{num_b = 32 : i32, num_dp = 32 : i32, num_rep = 64 : i32}> : (!cute.ptr<f32, tmem, align<16>>) -> vector<64xi32>
          llvm.store %88, %83 : vector<64xi32>, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %86 = cute.memref.load_vec %rmem, row_major : !memref_rmem_f32_
        %87 = arith.truncf %86 : vector<64xf32> to vector<64xf16>
        cute.memref.store_vec %87, %rmem_58, row_major : !memref_rmem_f16_
        %idx_64 = cute.crd2idx(%coord_61, %3) : (!cute.coord<"(_,_,?)">, !cute.layout<"((64,1),1,((1,4),1,1)):((1,0),0,((0,64),0,0))">) -> !cute.int_tuple<"?{div=64}">
        %ptr_65 = cute.add_offset(%ptr_57, %idx_64) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<f16, gmem, align<32>>
        scf.for %arg7 = %c0_i32 to %84 step %c1_i32  : i32 {
          %coord_66 = cute.make_coord(%arg7) : (i32) -> !cute.coord<"(_,?)">
          %idx_67 = cute.crd2idx(%coord_66, %2) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(8)):(1,(8))">) -> !cute.int_tuple<"?{div=8}">
          %ptr_68 = cute.add_offset(%iter_60, %idx_67) : (!cute.ptr<f16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, rmem, align<16>>
          %ptr_69 = cute.add_offset(%ptr_65, %idx_67) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f16, gmem, align<16>>
          %88 = builtin.unrealized_conversion_cast %ptr_68 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
          %89 = builtin.unrealized_conversion_cast %ptr_69 : !cute.ptr<f16, gmem, align<16>> to !llvm.ptr<1>
          %90 = llvm.load %88 {alignment = 16 : i64} : !llvm.ptr -> vector<8xf16>
          llvm.store %90, %89 {alignment = 16 : i64} : vector<8xf16>, !llvm.ptr<1>
        } {llvm.loop_annotation = #loop_annotation}
      }
      %85 = builtin.unrealized_conversion_cast %ptr_8 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %85, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>} : !llvm.ptr<3>, i32
      nvvm.barrier id = %c1_i32
      scf.if %46 {
        cute_nvgpu.arch.sm100.dealloc_tmem(%tmem_ptr, %c512_i32) [ cta_1] : !cute.ptr<f32, tmem, align<16>>, i32
      }
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
    %148 = arith.ceildivsi %147#0, %c128_i32 : i32
    %149 = arith.ceildivsi %147#1, %c256_i32 : i32
    %int_tuple_9 = cute.make_int_tuple(%148, %149) : (i32, i32) -> !cute.int_tuple<"(?,?,1)">
    %e0_10, %e1_11, %e2 = cute.get_leaves(%int_tuple_9) : !cute.int_tuple<"(?,?,1)">
    %150 = cute.get_scalars(%e0_10) : !cute.int_tuple<"?">
    %151 = cute.get_scalars(%e1_11) : !cute.int_tuple<"?">
    %152 = arith.index_cast %150 : i32 to index
    %153 = arith.index_cast %151 : i32 to index
    gpu.launch_func  @kernels::@kernel_cutlass_kernel_TiledMMA_ThrLayoutVMNK11110000_PermutationMNK____MMAAtom_ThrID10_ShapeMNK12825616_TVLayoutA1128161281128_TVLayoutB1256162561256_TVLayoutC11282561281128_CopyAtom_ThrI_0 blocks in (%152, %153, %c1) threads in (%c128, %c1, %c1)  dynamic_shared_memory_size %c196736_i32 args(%9 : !mma_f16_f16_f32_128x256x16_, %86 : !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, internal_val_type = f16>, %view : !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">, %144 : !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 262144, tma_gbasis = <"(64,256):(1@1,1@0)">, internal_val_type = f16>, %view_6 : !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">, %arg2 : !memref_gmem_f16_) {use_pdl = false}
    return
  }
}
