!memref_gmem_f16_ = !cute.memref<f16, gmem, align<32>, "(?,?{div=8192}):(?{i64 div=8192},1)">
!memref_rmem_f16_ = !cute.memref<f16, rmem, align<32>, "((64,1),1):((1,0),0)">
!memref_rmem_f32_ = !cute.memref<f32, rmem, align<32>, "((64,1),1):((1,0),0)">
!mma_f16_f16_f32_128x256x16_ = !cute.tiled_mma<!cute_nvgpu.sm100.mma<128x256x16, num_cta = 1, ab_major = (k, k), elem_type = (f16, f16, f32), frag_kind = ss, c_scale_exp = 0>, atom_layout_MNK = <"(1,1,1):(0,0,0)">>
#loop_unroll = #llvm.loop_unroll<disable = false, full = true>
#loop_annotation = #llvm.loop_annotation<unroll = #loop_unroll>
module attributes {gpu.container_module} {
  gpu.module @kernels {
    cuda.kernel @kernel_cutlass_kernel_TiledMMA_ThrLayoutVMNK11110000_PermutationMNK____MMAAtom_ThrID10_ShapeMNK12825616_TVLayoutA1128161281128_TVLayoutB1256162561256_TVLayoutC11282561281128_CopyAtom_ThrI_0(%arg0: !mma_f16_f16_f32_128x256x16_, %arg1: !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, internal_val_type = f16>, %arg2: !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">, %arg3: !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 262144, tma_gbasis = <"(64,256):(1@1,1@0)">, internal_val_type = f16>, %arg4: !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">, %arg5: !memref_gmem_f16_) attributes {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} {
      %0 = builtin.unrealized_conversion_cast %arg0 : !mma_f16_f16_f32_128x256x16_ to !llvm.struct<(i1, i1, i1)>
      %c127_i32 = arith.constant 127 : i32
      %1 = cute.static : !cute.layout<"(16,(4)):(1,(16))">
      %2 = cute.static : !cute.layout<"((64,1),1,((1,4),1,1)):((1,0),0,((0,64),0,0))">
      %3 = cute.static : !cute.layout<"(((64,32),1),1,((1,4),1,1)):(((1,65536),0),0,((0,64),0,0))">
      %c14_i32 = arith.constant 14 : i32
      %c13_i32 = arith.constant 13 : i32
      %c138412048_i32 = arith.constant 138412048 : i32
      %4 = cute.static : !cute.layout<"(1,1,4,4):(0,0,2,2048)">
      %5 = cute.static : !cute.layout<"(1,1,4,4):(0,0,2,1024)">
      %6 = cute.static : !cute.layout<"((16384,1),4):((1,0),16384)">
      %7 = cute.static : !cute.layout<"((8192,1),4):((1,0),8192)">
      %c49152_i32 = arith.constant 49152 : i32
      %c2_i32 = arith.constant 2 : i32
      %c4_i32 = arith.constant 4 : i32
      %c10000000_i32 = arith.constant 10000000 : i32
      %true = arith.constant true
      %c32_i64 = arith.constant 32 : i64
      %c2097152_i32 = arith.constant 2097152 : i32
      %8 = cute.static : !cute.shape<"(((128,64)),((1,4),1,1))">
      %9 = cute.static : !cute.stride<"(((1@0,1@1),0),64@0)">
      %10 = cute.static : !cute.stride<"(((1@1,1@0),0,16@0),64@0)">
      %11 = cute.static : !cute.shape<"((128,256),1,1)">
      %12 = cute.static : !cute.stride<"((1@1,1@0),0,16@0,64@0)">
      %13 = cute.static : !cute.shape<"(128,256)">
      %c128_i64 = arith.constant 128 : i64
      %14 = cute.static : !cute.stride<"((1@1,1@0),(256@1,64@0))">
      %c256_i32 = arith.constant 256 : i32
      %15 = cute.static : !cute.int_tuple<"(0,0)">
      %16 = cute.static : !cute.stride<"(1@1,1@0,64@0)">
      %17 = cute.static : !cute.stride<"((1@1,1@0),(128@1,64@0))">
      %c64_i32 = arith.constant 64 : i32
      %18 = cute.static : !cute.int_tuple<"4">
      %19 = cute.static : !cute.int_tuple<"3">
      %20 = cute.static : !cute.int_tuple<"2">
      %21 = cute.static : !cute.int_tuple<"1">
      %c512_i32 = arith.constant 512 : i32
      %c0_i32 = arith.constant 0 : i32
      %22 = cute.static : !cute.int_tuple<"65536">
      %c-128_i32 = arith.constant -128 : i32
      %c1_i32 = arith.constant 1 : i32
      %c128_i32 = arith.constant 128 : i32
      %23 = cute.static : !cute.int_tuple<"80">
      %24 = cute.static : !cute.int_tuple<"64">
      %25 = cute.static : !cute.int_tuple<"88">
      %c32_i32 = arith.constant 32 : i32
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
      %ptr = cute.add_offset(%smem_ptr, %25) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"88">) -> !cute.ptr<i8, smem, align<8>>
      %ptr_0 = cute.add_offset(%smem_ptr, %24) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"64">) -> !cute.ptr<i8, smem, align<64>>
      %ptr_1 = cute.add_offset(%smem_ptr, %23) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"80">) -> !cute.ptr<i8, smem, align<16>>
      %iter = cute.recast_iter(%ptr_1) : !cute.ptr<i8, smem, align<16>> to !cute.ptr<i32, smem, align<16>>
      %40 = cute.ptrtoint(%ptr) : !cute.ptr<i8, smem, align<8>> to i32
      %41 = arith.addi %40, %c127_i32 : i32
      %42 = arith.andi %41, %c-128_i32 : i32
      %43 = arith.extsi %42 : i32 to i64
      %iv = cute.assume(%43) : (i64) -> !cute.i64<divby 128>
      %44 = cute.inttoptr(%iv) : !cute.i64<divby 128> to !cute.ptr<i8, smem, align<128>>
      %ptr_2 = cute.add_offset(%44, %22) : (!cute.ptr<i8, smem, align<128>>, !cute.int_tuple<"65536">) -> !cute.ptr<i8, smem, align<128>>
      %iter_3 = cute.recast_iter(%44) : !cute.ptr<i8, smem, align<128>> to !cute.ptr<f16, smem, align<128>, S<3,4,3>>
      %iter_4 = cute.recast_iter(%ptr_2) : !cute.ptr<i8, smem, align<128>> to !cute.ptr<f16, smem, align<128>, S<3,4,3>>
      %45 = arith.cmpi eq, %37, %c0_i32 : i32
      cf.cond_br %45, ^bb1, ^bb2
    ^bb1:  // pred: ^bb0
      cute_nvgpu.arch.sm100.alloc_tmem(%c512_i32, %iter) [ cta_1] : i32, !cute.ptr<i32, smem, align<16>>
      cf.br ^bb2
    ^bb2:  // 2 preds: ^bb0, ^bb1
      cf.cond_br %45, ^bb3, ^bb4
    ^bb3:  // pred: ^bb2
      cute_nvgpu.prefetch_tma_desc(%arg1) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, internal_val_type = f16>) -> ()
      cute_nvgpu.prefetch_tma_desc(%arg3) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 262144, tma_gbasis = <"(64,256):(1@1,1@0)">, internal_val_type = f16>) -> ()
      cf.br ^bb4
    ^bb4:  // 2 preds: ^bb2, ^bb3
      %iter_5 = cute.recast_iter(%smem_ptr) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<i64, smem, align<1024>>
      cf.cond_br %45, ^bb5, ^bb6
    ^bb5:  // pred: ^bb4
      %46 = builtin.unrealized_conversion_cast %iter_5 : !cute.ptr<i64, smem, align<1024>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %46, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_6 = cute.add_offset(%iter_5, %21) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"1">) -> !cute.ptr<i64, smem>
      %47 = builtin.unrealized_conversion_cast %ptr_6 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %47, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_7 = cute.add_offset(%iter_5, %20) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"2">) -> !cute.ptr<i64, smem, align<16>>
      %48 = builtin.unrealized_conversion_cast %ptr_7 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %48, %c1_i32 : !llvm.ptr<3>, i32
      %ptr_8 = cute.add_offset(%iter_5, %19) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"3">) -> !cute.ptr<i64, smem>
      %49 = builtin.unrealized_conversion_cast %ptr_8 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %49, %c1_i32 : !llvm.ptr<3>, i32
      cf.br ^bb6
    ^bb6:  // 2 preds: ^bb4, ^bb5
      %ptr_9 = cute.add_offset(%iter_5, %18) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"4">) -> !cute.ptr<i64, smem, align<32>>
      cf.cond_br %45, ^bb7, ^bb8
    ^bb7:  // pred: ^bb6
      %50 = builtin.unrealized_conversion_cast %ptr_9 : !cute.ptr<i64, smem, align<32>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %50, %c1_i32 : !llvm.ptr<3>, i32
      %int_tuple = cute.make_int_tuple() : () -> !cute.int_tuple<"5">
      %ptr_10 = cute.add_offset(%iter_5, %int_tuple) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"5">) -> !cute.ptr<i64, smem>
      %51 = builtin.unrealized_conversion_cast %ptr_10 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %51, %c1_i32 : !llvm.ptr<3>, i32
      %int_tuple_11 = cute.make_int_tuple() : () -> !cute.int_tuple<"6">
      %ptr_12 = cute.add_offset(%iter_5, %int_tuple_11) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"6">) -> !cute.ptr<i64, smem, align<16>>
      %52 = builtin.unrealized_conversion_cast %ptr_12 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %52, %c1_i32 : !llvm.ptr<3>, i32
      %int_tuple_13 = cute.make_int_tuple() : () -> !cute.int_tuple<"7">
      %ptr_14 = cute.add_offset(%iter_5, %int_tuple_13) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"7">) -> !cute.ptr<i64, smem>
      %53 = builtin.unrealized_conversion_cast %ptr_14 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %53, %c1_i32 : !llvm.ptr<3>, i32
      cf.br ^bb8
    ^bb8:  // 2 preds: ^bb6, ^bb7
      nvvm.fence.mbarrier.init
      nvvm.barrier
      %iter_15 = cute.recast_iter(%ptr_0) : !cute.ptr<i8, smem, align<64>> to !cute.ptr<i64, smem, align<64>>
      cf.cond_br %45, ^bb9, ^bb10
    ^bb9:  // pred: ^bb8
      %54 = builtin.unrealized_conversion_cast %iter_15 : !cute.ptr<i64, smem, align<64>> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %54, %c1_i32 : !llvm.ptr<3>, i32
      cf.br ^bb10
    ^bb10:  // 2 preds: ^bb8, ^bb9
      %ptr_16 = cute.add_offset(%iter_15, %21) : (!cute.ptr<i64, smem, align<64>>, !cute.int_tuple<"1">) -> !cute.ptr<i64, smem>
      cf.cond_br %45, ^bb11, ^bb12
    ^bb11:  // pred: ^bb10
      %55 = builtin.unrealized_conversion_cast %ptr_16 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.init.shared %55, %c128_i32 : !llvm.ptr<3>, i32
      cf.br ^bb12
    ^bb12:  // 2 preds: ^bb10, ^bb11
      nvvm.fence.mbarrier.init
      nvvm.barrier
      %coord = cute.make_coord(%38, %39) : (i32, i32) -> !cute.coord<"(?,?,_)">
      %56:2 = cute.get_scalars(%coord) <{only_dynamic}> : !cute.coord<"(?,?,_)">
      %coord_17 = cute.make_coord(%56#0) : (i32) -> !cute.coord<"((_,_),(?,_))">
      %lay = cute.get_layout(%arg2) : !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">
      %57:2 = cute.get_scalars(%lay) <{only_dynamic}> : !cute.layout<"(?,?{div=8192}):(1@1,1@0)">
      %58 = arith.ceildivsi %57#0, %c128_i32 : i32
      %59 = arith.ceildivsi %57#1, %c64_i32 : i32
      %shape = cute.make_shape(%58, %59) : (i32, i32) -> !cute.shape<"((128,64),(?,?))">
      %lay_18 = cute.make_layout(%shape, %17) : !cute.layout<"((128,64),(?,?)):((1@1,1@0),(128@1,64@0))">
      %60:2 = cute.get_scalars(%lay_18) <{only_dynamic}> : !cute.layout<"((128,64),(?,?)):((1@1,1@0),(128@1,64@0))">
      %shape_19 = cute.make_shape(%60#1) : (i32) -> !cute.shape<"(128,64,?)">
      %lay_20 = cute.make_layout(%shape_19, %16) : !cute.layout<"(128,64,?):(1@1,1@0,64@0)">
      %idx = cute.crd2idx(%coord_17, %lay_18) : (!cute.coord<"((_,_),(?,_))">, !cute.layout<"((128,64),(?,?)):((1@1,1@0),(128@1,64@0))">) -> !cute.int_tuple<"(0,?{div=128})">
      %tup = cute.add_offset(%15, %idx) : (!cute.int_tuple<"(0,0)">, !cute.int_tuple<"(0,?{div=128})">) -> !cute.int_tuple<"(0,?{div=128})">
      %coord_21 = cute.make_coord(%56#1) : (i32) -> !cute.coord<"((_,_),(?,_))">
      %lay_22 = cute.get_layout(%arg4) : !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">
      %61:2 = cute.get_scalars(%lay_22) <{only_dynamic}> : !cute.layout<"(?,?{div=8192}):(1@1,1@0)">
      %62 = arith.ceildivsi %61#0, %c256_i32 : i32
      %63 = arith.ceildivsi %61#1, %c64_i32 : i32
      %shape_23 = cute.make_shape(%62, %63) : (i32, i32) -> !cute.shape<"((256,64),(?,?))">
      %lay_24 = cute.make_layout(%shape_23, %14) : !cute.layout<"((256,64),(?,?)):((1@1,1@0),(256@1,64@0))">
      %64:2 = cute.get_scalars(%lay_24) <{only_dynamic}> : !cute.layout<"((256,64),(?,?)):((1@1,1@0),(256@1,64@0))">
      %shape_25 = cute.make_shape(%64#1) : (i32) -> !cute.shape<"(256,64,?)">
      %lay_26 = cute.make_layout(%shape_25, %16) : !cute.layout<"(256,64,?):(1@1,1@0,64@0)">
      %idx_27 = cute.crd2idx(%coord_21, %lay_24) : (!cute.coord<"((_,_),(?,_))">, !cute.layout<"((256,64),(?,?)):((1@1,1@0),(256@1,64@0))">) -> !cute.int_tuple<"(0,?{div=256})">
      %tup_28 = cute.add_offset(%15, %idx_27) : (!cute.int_tuple<"(0,0)">, !cute.int_tuple<"(0,?{div=256})">) -> !cute.int_tuple<"(0,?{div=256})">
      %coord_29 = cute.make_coord(%56#0, %56#1) : (i32, i32) -> !cute.coord<"((_,_),(?,?))">
      %lay_30 = cute.get_layout(%arg5) : !memref_gmem_f16_
      %65:3 = cute.get_scalars(%lay_30) <{only_dynamic}> : !cute.layout<"(?,?{div=8192}):(?{i64 div=8192},1)">
      %66 = arith.ceildivsi %65#0, %c128_i32 : i32
      %67 = arith.muli %65#2, %c128_i64 : i64
      %68 = arith.ceildivsi %65#1, %c256_i32 : i32
      %shape_31 = cute.make_shape(%66, %68) : (i32, i32) -> !cute.shape<"((128,256),(?,?))">
      %iv_32 = cute.assume(%65#2) : (i64) -> !cute.i64<divby 8192>
      %iv_33 = cute.assume(%67) : (i64) -> !cute.i64<divby 1048576>
      %stride = cute.make_stride(%iv_32, %iv_33) : (!cute.i64<divby 8192>, !cute.i64<divby 1048576>) -> !cute.stride<"((?{i64 div=8192},1),(?{i64 div=1048576},256))">
      %lay_34 = cute.make_layout(%shape_31, %stride) : !cute.layout<"((128,256),(?,?)):((?{i64 div=8192},1),(?{i64 div=1048576},256))">
      %69:4 = cute.get_scalars(%lay_34) <{only_dynamic}> : !cute.layout<"((128,256),(?,?)):((?{i64 div=8192},1),(?{i64 div=1048576},256))">
      %iv_35 = cute.assume(%69#2) : (i64) -> !cute.i64<divby 8192>
      %stride_36 = cute.make_stride(%iv_35) : (!cute.i64<divby 8192>) -> !cute.stride<"(?{i64 div=8192},1)">
      %lay_37 = cute.make_layout(%13, %stride_36) : !cute.layout<"(128,256):(?{i64 div=8192},1)">
      %idx_38 = cute.crd2idx(%coord_29, %lay_34) : (!cute.coord<"((_,_),(?,?))">, !cute.layout<"((128,256),(?,?)):((?{i64 div=8192},1),(?{i64 div=1048576},256))">) -> !cute.int_tuple<"?{i64 div=256}">
      %iter_39 = cute.get_iter(%arg5) : !memref_gmem_f16_
      %ptr_40 = cute.add_offset(%iter_39, %idx_38) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{i64 div=256}">) -> !cute.ptr<f16, gmem, align<32>>
      %70 = cute.get_scalars(%lay_20) <{only_dynamic}> : !cute.layout<"(128,64,?):(1@1,1@0,64@0)">
      %shape_41 = cute.make_shape(%70) : (i32) -> !cute.shape<"((128,16),1,4,?)">
      %lay_42 = cute.make_layout(%shape_41, %12) : !cute.layout<"((128,16),1,4,?):((1@1,1@0),0,16@0,64@0)">
      %71 = cute.get_scalars(%lay_26) <{only_dynamic}> : !cute.layout<"(256,64,?):(1@1,1@0,64@0)">
      %shape_43 = cute.make_shape(%71) : (i32) -> !cute.shape<"((256,16),1,4,?)">
      %lay_44 = cute.make_layout(%shape_43, %12) : !cute.layout<"((256,16),1,4,?):((1@1,1@0),0,16@0,64@0)">
      %72 = cute.get_scalars(%lay_37) <{only_dynamic}> : !cute.layout<"(128,256):(?{i64 div=8192},1)">
      %iv_45 = cute.assume(%72) : (i64) -> !cute.i64<divby 8192>
      %stride_46 = cute.make_stride(%iv_45) : (!cute.i64<divby 8192>) -> !cute.stride<"((?{i64 div=8192},1),0,0)">
      %lay_47 = cute.make_layout(%11, %stride_46) : !cute.layout<"((128,256),1,1):((?{i64 div=8192},1),0,0)">
      %ummaSmemDesc = cute_nvgpu.make_umma_smem_desc(%iter_3 : !cute.ptr<f16, smem, align<128>, S<3,4,3>>) layout = <"((128,16),1,4,4):((64,1),0,16,8192)">, major = <k> -> !cute_nvgpu.smem_desc
      %ummaSmemDesc_48 = cute_nvgpu.make_umma_smem_desc(%iter_4 : !cute.ptr<f16, smem, align<128>, S<3,4,3>>) layout = <"((256,16),1,4,4):((64,1),0,16,16384)">, major = <k> -> !cute_nvgpu.smem_desc
      %73 = cute.get_scalars(%lay_42) <{only_dynamic}> : !cute.layout<"((128,16),1,4,?):((1@1,1@0),0,16@0,64@0)">
      %shape_49 = cute.make_shape(%73) : (i32) -> !cute.shape<"(((128,16),1,4),?)">
      %lay_50 = cute.make_layout(%shape_49, %10) : !cute.layout<"(((128,16),1,4),?):(((1@1,1@0),0,16@0),64@0)">
      %74 = cute.get_scalars(%lay_50) <{only_dynamic}> : !cute.layout<"(((128,16),1,4),?):(((1@1,1@0),0,16@0),64@0)">
      %shape_51 = cute.make_shape(%74) : (i32) -> !cute.shape<"(((64,128),1),?)">
      %lay_52 = cute.make_layout(%shape_51, %9) : !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">
      %75 = cute.get_scalars(%lay_44) <{only_dynamic}> : !cute.layout<"((256,16),1,4,?):((1@1,1@0),0,16@0,64@0)">
      %shape_53 = cute.make_shape(%75) : (i32) -> !cute.shape<"(((256,16),1,4),?)">
      %lay_54 = cute.make_layout(%shape_53, %10) : !cute.layout<"(((256,16),1,4),?):(((1@1,1@0),0,16@0),64@0)">
      %76 = cute.get_scalars(%lay_54) <{only_dynamic}> : !cute.layout<"(((256,16),1,4),?):(((1@1,1@0),0,16@0),64@0)">
      %shape_55 = cute.make_shape(%76) : (i32) -> !cute.shape<"(((64,256),1),?)">
      %lay_56 = cute.make_layout(%shape_55, %9) : !cute.layout<"(((64,256),1),?):(((1@0,1@1),0),64@0)">
      nvvm.barrier id = %c1_i32 number_of_threads = %c128_i32
      %tmem_ptr = cute_nvgpu.arch.sm100.retrieve_tmem_ptr(%iter) : !cute.ptr<i32, smem, align<16>> -> !cute.ptr<f32, tmem, align<16>>
      %77 = cute.get_scalars(%lay_47) <{only_dynamic}> : !cute.layout<"((128,256),1,1):((?{i64 div=8192},1),0,0)">
      %iv_57 = cute.assume(%77) : (i64) -> !cute.i64<divby 8192>
      %stride_58 = cute.make_stride(%iv_57) : (!cute.i64<divby 8192>) -> !cute.stride<"(((?{i64 div=8192},1)),((0,64),0,0))">
      %lay_59 = cute.make_layout(%8, %stride_58) : !cute.layout<"(((128,64)),((1,4),1,1)):(((?{i64 div=8192},1)),((0,64),0,0))">
      %coord_60 = cute.make_coord(%26) : (i32) -> !cute.coord<"?">
      %78 = cute.get_scalars(%coord_60) <{only_dynamic}> : !cute.coord<"?">
      %79 = arith.divsi %78, %c32_i32 : i32
      %80 = arith.muli %79, %c2097152_i32 : i32
      %iv_61 = cute.assume(%80) : (i32) -> !cute.i32<divby 2097152>
      %int_tuple_62 = cute.make_int_tuple(%iv_61) : (!cute.i32<divby 2097152>) -> !cute.int_tuple<"?{div=2097152}">
      %ptr_63 = cute.add_offset(%tmem_ptr, %int_tuple_62) : (!cute.ptr<f32, tmem, align<16>>, !cute.int_tuple<"?{div=2097152}">) -> !cute.ptr<f32, tmem, align<16>>
      %81 = cute.get_scalars(%lay_59) <{only_dynamic}> : !cute.layout<"(((128,64)),((1,4),1,1)):(((?{i64 div=8192},1)),((0,64),0,0))">
      %82 = arith.muli %81, %c32_i64 : i64
      %83 = arith.remsi %78, %c32_i32 : i32
      %84 = arith.extsi %83 : i32 to i64
      %85 = arith.muli %84, %81 : i64
      %86 = arith.extsi %79 : i32 to i64
      %87 = arith.muli %86, %82 : i64
      %88 = arith.addi %85, %87 : i64
      %iv_64 = cute.assume(%88) : (i64) -> !cute.i64<divby 8192>
      %int_tuple_65 = cute.make_int_tuple(%iv_64) : (!cute.i64<divby 8192>) -> !cute.int_tuple<"?{i64 div=8192}">
      %ptr_66 = cute.add_offset(%ptr_40, %int_tuple_65) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{i64 div=8192}">) -> !cute.ptr<f16, gmem, align<32>>
      %rmem = cute.memref.alloca() : !memref_rmem_f32_
      %rmem_67 = cute.memref.alloca() : !memref_rmem_f16_
      %sz = cute.size(%lay_20) <{mode = [2]}> : (!cute.layout<"(128,64,?):(1@1,1@0,64@0)">) -> !cute.int_tuple<"?">
      %e0 = cute.get_leaves(%sz) : !cute.int_tuple<"?">
      %89 = cute.get_scalars(%e0) : !cute.int_tuple<"?">
      cf.cond_br %45, ^bb13, ^bb92
    ^bb13:  // pred: ^bb12
      %90 = builtin.unrealized_conversion_cast %ptr_16 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %90, %c1_i32, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %91 = cute_nvgpu.atom.make_exec_tma(%arg1) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128):(1@1,1@0)">>
      %92 = cute_nvgpu.atom.make_exec_tma(%arg3) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 262144, tma_gbasis = <"(64,256):(1@1,1@0)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_load<f16, copy_bits = 262144, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,256):(1@1,1@0)">>
      %93 = arith.minsi %89, %c2_i32 : i32
      %94 = cute.get_scalars(%21) : !cute.int_tuple<"1">
      cf.br ^bb14(%c0_i32, %c0_i32, %c1_i32, %c0_i32 : i32, i32, i32, i32)
    ^bb14(%95: i32, %96: i32, %97: i32, %98: i32):  // 2 preds: ^bb13, ^bb27
      %99 = arith.cmpi slt, %95, %93 : i32
      cf.cond_br %99, ^bb15, ^bb28
    ^bb15:  // pred: ^bb14
      %int_tuple_68 = cute.make_int_tuple(%96) : (i32) -> !cute.int_tuple<"?">
      %ptr_69 = cute.add_offset(%ptr_9, %int_tuple_68) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %100 = builtin.unrealized_conversion_cast %ptr_69 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %100, %97, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %101 = nvvm.elect.sync -> i1
      cf.cond_br %101, ^bb16, ^bb17
    ^bb16:  // pred: ^bb15
      %ptr_70 = cute.add_offset(%iter_5, %int_tuple_68) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %102 = builtin.unrealized_conversion_cast %ptr_70 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %102, %c49152_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
      cf.br ^bb17
    ^bb17:  // 2 preds: ^bb15, ^bb16
      %103 = arith.addi %96, %c1_i32 : i32
      %104 = arith.addi %98, %c1_i32 : i32
      %105 = arith.cmpi eq, %103, %c4_i32 : i32
      %106 = arith.select %105, %c0_i32, %103 : i32
      cf.cond_br %105, ^bb18, ^bb19
    ^bb18:  // pred: ^bb17
      %107 = arith.xori %97, %c1_i32 : i32
      cf.br ^bb20(%107 : i32)
    ^bb19:  // pred: ^bb17
      cf.br ^bb20(%97 : i32)
    ^bb20(%108: i32):  // 2 preds: ^bb18, ^bb19
      cf.br ^bb21
    ^bb21:  // pred: ^bb20
      %coord_71 = cute.make_coord(%98) : (i32) -> !cute.coord<"(_,?)">
      %idx_72 = cute.crd2idx(%coord_71, %lay_52) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
      %tup_73 = cute.add_offset(%tup, %idx_72) : (!cute.int_tuple<"(0,?{div=128})">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
      %e0_74, %e1 = cute.get_leaves(%tup_73) : !cute.int_tuple<"(?{div=64},?{div=128})">
      %coord_75 = cute.make_coord(%96) : (i32) -> !cute.coord<"(_,?)">
      %idx_76 = cute.crd2idx(%coord_75, %7) : (!cute.coord<"(_,?)">, !cute.layout<"((8192,1),4):((1,0),8192)">) -> !cute.int_tuple<"?{div=8192}">
      %ptr_77 = cute.add_offset(%iter_3, %idx_76) : (!cute.ptr<f16, smem, align<128>, S<3,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<f16, smem, align<128>, S<3,4,3>>
      %ptr_78 = cute.add_offset(%iter_5, %int_tuple_68) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %int_tuple_79 = cute.make_int_tuple(%e0_74, %e1) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=128}">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
      %109 = cute_nvgpu.atom.set_value(%91, %ptr_78 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128):(1@1,1@0)">>
      %110 = cute_nvgpu.atom.get_value(%109 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
      %111 = cute_nvgpu.atom.get_value(%109 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<cache_policy>} : i64
      %TMADescAddr = cute_nvgpu.get_tma_desc_addr(%109 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128):(1@1,1@0)">>) -> !cute.ptr<generic, align<64>>
      %112:2 = cute.get_scalars(%int_tuple_79) : !cute.int_tuple<"(?{div=64},?{div=128})">
      cf.br ^bb22(%c0_i32 : i32)
    ^bb22(%113: i32):  // 2 preds: ^bb21, ^bb23
      %114 = arith.cmpi slt, %113, %94 : i32
      cf.cond_br %114, ^bb23, ^bb24 {llvm.loop_annotation = #loop_annotation}
    ^bb23:  // pred: ^bb22
      cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr : !cute.ptr<generic, align<64>>, %ptr_77 : !cute.ptr<f16, smem, align<128>, S<3,4,3>>, %110 : !cute.ptr<smem, align<8>>, [%112#0, %112#1] : i32, i32) cache_policy = %111 mode = <tiled> num_cta = 1 : i32
      %115 = arith.addi %113, %c1_i32 : i32
      cf.br ^bb22(%115 : i32)
    ^bb24:  // pred: ^bb22
      %idx_80 = cute.crd2idx(%coord_71, %lay_56) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,256),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
      %tup_81 = cute.add_offset(%tup_28, %idx_80) : (!cute.int_tuple<"(0,?{div=256})">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.int_tuple<"(?{div=64},?{div=256})">
      %e0_82, %e1_83 = cute.get_leaves(%tup_81) : !cute.int_tuple<"(?{div=64},?{div=256})">
      %idx_84 = cute.crd2idx(%coord_75, %6) : (!cute.coord<"(_,?)">, !cute.layout<"((16384,1),4):((1,0),16384)">) -> !cute.int_tuple<"?{div=16384}">
      %ptr_85 = cute.add_offset(%iter_4, %idx_84) : (!cute.ptr<f16, smem, align<128>, S<3,4,3>>, !cute.int_tuple<"?{div=16384}">) -> !cute.ptr<f16, smem, align<128>, S<3,4,3>>
      %int_tuple_86 = cute.make_int_tuple(%e0_82, %e1_83) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=256}">) -> !cute.int_tuple<"(?{div=64},?{div=256})">
      %116 = cute_nvgpu.atom.set_value(%92, %ptr_78 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 262144, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,256):(1@1,1@0)">>
      %117 = cute_nvgpu.atom.get_value(%116 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 262144, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,256):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
      %118 = cute_nvgpu.atom.get_value(%116 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 262144, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,256):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<cache_policy>} : i64
      %TMADescAddr_87 = cute_nvgpu.get_tma_desc_addr(%116 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 262144, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,256):(1@1,1@0)">>) -> !cute.ptr<generic, align<64>>
      %119:2 = cute.get_scalars(%int_tuple_86) : !cute.int_tuple<"(?{div=64},?{div=256})">
      cf.br ^bb25(%c0_i32 : i32)
    ^bb25(%120: i32):  // 2 preds: ^bb24, ^bb26
      %121 = arith.cmpi slt, %120, %94 : i32
      cf.cond_br %121, ^bb26, ^bb27 {llvm.loop_annotation = #loop_annotation}
    ^bb26:  // pred: ^bb25
      cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr_87 : !cute.ptr<generic, align<64>>, %ptr_85 : !cute.ptr<f16, smem, align<128>, S<3,4,3>>, %117 : !cute.ptr<smem, align<8>>, [%119#0, %119#1] : i32, i32) cache_policy = %118 mode = <tiled> num_cta = 1 : i32
      %122 = arith.addi %120, %c1_i32 : i32
      cf.br ^bb25(%122 : i32)
    ^bb27:  // pred: ^bb25
      %123 = arith.addi %95, %c1_i32 : i32
      cf.br ^bb14(%123, %106, %108, %104 : i32, i32, i32, i32)
    ^bb28:  // pred: ^bb14
      %124 = cute.get_scalars(%21) : !cute.int_tuple<"1">
      cf.br ^bb29(%c0_i32, %98, %96, %97, %c0_i32, %c0_i32, %c0_i32, %0 : i32, i32, i32, i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>)
    ^bb29(%125: i32, %126: i32, %127: i32, %128: i32, %129: i32, %130: i32, %131: i32, %132: !llvm.struct<(i1, i1, i1)>):  // 2 preds: ^bb28, ^bb88
      %133 = arith.cmpi slt, %125, %89 : i32
      cf.cond_br %133, ^bb30, ^bb89
    ^bb30:  // pred: ^bb29
      %134 = builtin.unrealized_conversion_cast %132 : !llvm.struct<(i1, i1, i1)> to !mma_f16_f16_f32_128x256x16_
      %135 = arith.addi %125, %93 : i32
      %136 = arith.cmpi ult, %135, %89 : i32
      cf.cond_br %136, ^bb31, ^bb44
    ^bb31:  // pred: ^bb30
      %int_tuple_88 = cute.make_int_tuple(%127) : (i32) -> !cute.int_tuple<"?">
      %ptr_89 = cute.add_offset(%ptr_9, %int_tuple_88) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %137 = builtin.unrealized_conversion_cast %ptr_89 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %137, %128, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %138 = nvvm.elect.sync -> i1
      cf.cond_br %138, ^bb32, ^bb33
    ^bb32:  // pred: ^bb31
      %ptr_90 = cute.add_offset(%iter_5, %int_tuple_88) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %139 = builtin.unrealized_conversion_cast %ptr_90 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %139, %c49152_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
      cf.br ^bb33
    ^bb33:  // 2 preds: ^bb31, ^bb32
      %140 = arith.addi %127, %c1_i32 : i32
      %141 = arith.addi %126, %c1_i32 : i32
      %142 = arith.cmpi eq, %140, %c4_i32 : i32
      %143 = arith.select %142, %c0_i32, %140 : i32
      cf.cond_br %142, ^bb34, ^bb35
    ^bb34:  // pred: ^bb33
      %144 = arith.xori %128, %c1_i32 : i32
      cf.br ^bb36(%144 : i32)
    ^bb35:  // pred: ^bb33
      cf.br ^bb36(%128 : i32)
    ^bb36(%145: i32):  // 2 preds: ^bb34, ^bb35
      cf.br ^bb37
    ^bb37:  // pred: ^bb36
      %coord_91 = cute.make_coord(%126) : (i32) -> !cute.coord<"(_,?)">
      %idx_92 = cute.crd2idx(%coord_91, %lay_52) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
      %tup_93 = cute.add_offset(%tup, %idx_92) : (!cute.int_tuple<"(0,?{div=128})">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
      %e0_94, %e1_95 = cute.get_leaves(%tup_93) : !cute.int_tuple<"(?{div=64},?{div=128})">
      %coord_96 = cute.make_coord(%127) : (i32) -> !cute.coord<"(_,?)">
      %idx_97 = cute.crd2idx(%coord_96, %7) : (!cute.coord<"(_,?)">, !cute.layout<"((8192,1),4):((1,0),8192)">) -> !cute.int_tuple<"?{div=8192}">
      %ptr_98 = cute.add_offset(%iter_3, %idx_97) : (!cute.ptr<f16, smem, align<128>, S<3,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<f16, smem, align<128>, S<3,4,3>>
      %ptr_99 = cute.add_offset(%iter_5, %int_tuple_88) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %int_tuple_100 = cute.make_int_tuple(%e0_94, %e1_95) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=128}">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
      %146 = cute_nvgpu.atom.set_value(%91, %ptr_99 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128):(1@1,1@0)">>
      %147 = cute.get_scalars(%21) : !cute.int_tuple<"1">
      %148 = cute_nvgpu.atom.get_value(%146 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
      %149 = cute_nvgpu.atom.get_value(%146 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<cache_policy>} : i64
      %TMADescAddr_101 = cute_nvgpu.get_tma_desc_addr(%146 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128):(1@1,1@0)">>) -> !cute.ptr<generic, align<64>>
      %150:2 = cute.get_scalars(%int_tuple_100) : !cute.int_tuple<"(?{div=64},?{div=128})">
      cf.br ^bb38(%c0_i32 : i32)
    ^bb38(%151: i32):  // 2 preds: ^bb37, ^bb39
      %152 = arith.cmpi slt, %151, %147 : i32
      cf.cond_br %152, ^bb39, ^bb40 {llvm.loop_annotation = #loop_annotation}
    ^bb39:  // pred: ^bb38
      cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr_101 : !cute.ptr<generic, align<64>>, %ptr_98 : !cute.ptr<f16, smem, align<128>, S<3,4,3>>, %148 : !cute.ptr<smem, align<8>>, [%150#0, %150#1] : i32, i32) cache_policy = %149 mode = <tiled> num_cta = 1 : i32
      %153 = arith.addi %151, %c1_i32 : i32
      cf.br ^bb38(%153 : i32)
    ^bb40:  // pred: ^bb38
      %idx_102 = cute.crd2idx(%coord_91, %lay_56) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,256),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
      %tup_103 = cute.add_offset(%tup_28, %idx_102) : (!cute.int_tuple<"(0,?{div=256})">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.int_tuple<"(?{div=64},?{div=256})">
      %e0_104, %e1_105 = cute.get_leaves(%tup_103) : !cute.int_tuple<"(?{div=64},?{div=256})">
      %idx_106 = cute.crd2idx(%coord_96, %6) : (!cute.coord<"(_,?)">, !cute.layout<"((16384,1),4):((1,0),16384)">) -> !cute.int_tuple<"?{div=16384}">
      %ptr_107 = cute.add_offset(%iter_4, %idx_106) : (!cute.ptr<f16, smem, align<128>, S<3,4,3>>, !cute.int_tuple<"?{div=16384}">) -> !cute.ptr<f16, smem, align<128>, S<3,4,3>>
      %int_tuple_108 = cute.make_int_tuple(%e0_104, %e1_105) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=256}">) -> !cute.int_tuple<"(?{div=64},?{div=256})">
      %154 = cute_nvgpu.atom.set_value(%92, %ptr_99 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 262144, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,256):(1@1,1@0)">>
      %155 = cute_nvgpu.atom.get_value(%154 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 262144, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,256):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
      %156 = cute_nvgpu.atom.get_value(%154 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 262144, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,256):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<cache_policy>} : i64
      %TMADescAddr_109 = cute_nvgpu.get_tma_desc_addr(%154 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 262144, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,256):(1@1,1@0)">>) -> !cute.ptr<generic, align<64>>
      %157:2 = cute.get_scalars(%int_tuple_108) : !cute.int_tuple<"(?{div=64},?{div=256})">
      cf.br ^bb41(%c0_i32 : i32)
    ^bb41(%158: i32):  // 2 preds: ^bb40, ^bb42
      %159 = arith.cmpi slt, %158, %147 : i32
      cf.cond_br %159, ^bb42, ^bb43 {llvm.loop_annotation = #loop_annotation}
    ^bb42:  // pred: ^bb41
      cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr_109 : !cute.ptr<generic, align<64>>, %ptr_107 : !cute.ptr<f16, smem, align<128>, S<3,4,3>>, %155 : !cute.ptr<smem, align<8>>, [%157#0, %157#1] : i32, i32) cache_policy = %156 mode = <tiled> num_cta = 1 : i32
      %160 = arith.addi %158, %c1_i32 : i32
      cf.br ^bb41(%160 : i32)
    ^bb43:  // pred: ^bb41
      cf.br ^bb45(%143, %145, %141 : i32, i32, i32)
    ^bb44:  // pred: ^bb30
      cf.br ^bb45(%127, %128, %126 : i32, i32, i32)
    ^bb45(%161: i32, %162: i32, %163: i32):  // 2 preds: ^bb43, ^bb44
      cf.br ^bb46
    ^bb46:  // pred: ^bb45
      %int_tuple_110 = cute.make_int_tuple(%130) : (i32) -> !cute.int_tuple<"?">
      %ptr_111 = cute.add_offset(%iter_5, %int_tuple_110) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %164 = builtin.unrealized_conversion_cast %ptr_111 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %164, %131, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %165 = arith.addi %130, %c1_i32 : i32
      %166 = arith.addi %129, %c1_i32 : i32
      %167 = arith.cmpi eq, %165, %c4_i32 : i32
      %168 = arith.select %167, %c0_i32, %165 : i32
      cf.cond_br %167, ^bb47, ^bb48
    ^bb47:  // pred: ^bb46
      %169 = arith.xori %131, %c1_i32 : i32
      cf.br ^bb49(%169 : i32)
    ^bb48:  // pred: ^bb46
      cf.br ^bb49(%131 : i32)
    ^bb49(%170: i32):  // 2 preds: ^bb47, ^bb48
      cf.br ^bb50
    ^bb50:  // pred: ^bb49
      %coord_112 = cute.make_coord(%130) : (i32) -> !cute.coord<"(_,_,0,?)">
      %idx_113 = cute.crd2idx(%coord_112, %5) : (!cute.coord<"(_,_,0,?)">, !cute.layout<"(1,1,4,4):(0,0,2,1024)">) -> !cute.int_tuple<"?{div=1024}">
      %tup_114 = cute.add_offset(%ummaSmemDesc, %idx_113) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=1024}">) -> !cute_nvgpu.smem_desc
      %idx_115 = cute.crd2idx(%coord_112, %4) : (!cute.coord<"(_,_,0,?)">, !cute.layout<"(1,1,4,4):(0,0,2,2048)">) -> !cute.int_tuple<"?{div=2048}">
      %tup_116 = cute.add_offset(%ummaSmemDesc_48, %idx_115) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2048}">) -> !cute_nvgpu.smem_desc
      %171 = cute_nvgpu.atom.get_value(%134 : !mma_f16_f16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : i1
      %172 = cute_nvgpu.atom.get_value(%134 : !mma_f16_f16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : i1
      %173 = cute_nvgpu.atom.get_value(%134 : !mma_f16_f16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : i1
      %174 = arith.extui %171 : i1 to i32
      %175 = arith.extui %172 : i1 to i32
      %176 = arith.shli %174, %c13_i32 : i32
      %177 = arith.shli %175, %c14_i32 : i32
      %178 = arith.ori %176, %c138412048_i32 : i32
      %179 = arith.ori %178, %177 : i32
      cf.br ^bb51(%c0_i32 : i32)
    ^bb51(%180: i32):  // 2 preds: ^bb50, ^bb58
      %181 = arith.cmpi slt, %180, %124 : i32
      cf.cond_br %181, ^bb52, ^bb59 {llvm.loop_annotation = #loop_annotation}
    ^bb52:  // pred: ^bb51
      cf.br ^bb53(%c0_i32 : i32)
    ^bb53(%182: i32):  // 2 preds: ^bb52, ^bb57
      %183 = arith.cmpi slt, %182, %124 : i32
      cf.cond_br %183, ^bb54, ^bb58 {llvm.loop_annotation = #loop_annotation}
    ^bb54:  // pred: ^bb53
      cf.br ^bb55(%c0_i32 : i32)
    ^bb55(%184: i32):  // 2 preds: ^bb54, ^bb56
      %185 = arith.cmpi slt, %184, %124 : i32
      cf.cond_br %185, ^bb56, ^bb57 {llvm.loop_annotation = #loop_annotation}
    ^bb56:  // pred: ^bb55
      cute_nvgpu.arch.mma.SM100.umma(%tup_114, %tup_116, %tmem_ptr, %179, %173) {num_cta = 1 : i32, scale = 0 : i32, a_type = f16} : (!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, !cute.ptr<f32, tmem, align<16>>, i32, i1) -> ()
      %186 = arith.addi %184, %c1_i32 : i32
      cf.br ^bb55(%186 : i32)
    ^bb57:  // pred: ^bb55
      %187 = arith.addi %182, %c1_i32 : i32
      cf.br ^bb53(%187 : i32)
    ^bb58:  // pred: ^bb53
      %188 = arith.addi %180, %c1_i32 : i32
      cf.br ^bb51(%188 : i32)
    ^bb59:  // pred: ^bb51
      %189 = cute_nvgpu.atom.set_value(%134, %true : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_f16_f16_f32_128x256x16_
      %coord_117 = cute.make_coord(%130) : (i32) -> !cute.coord<"(_,_,1,?)">
      %idx_118 = cute.crd2idx(%coord_117, %5) : (!cute.coord<"(_,_,1,?)">, !cute.layout<"(1,1,4,4):(0,0,2,1024)">) -> !cute.int_tuple<"?{div=2}">
      %tup_119 = cute.add_offset(%ummaSmemDesc, %idx_118) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
      %idx_120 = cute.crd2idx(%coord_117, %4) : (!cute.coord<"(_,_,1,?)">, !cute.layout<"(1,1,4,4):(0,0,2,2048)">) -> !cute.int_tuple<"?{div=2}">
      %tup_121 = cute.add_offset(%ummaSmemDesc_48, %idx_120) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
      %190 = cute_nvgpu.atom.get_value(%189 : !mma_f16_f16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : i1
      %191 = cute_nvgpu.atom.get_value(%189 : !mma_f16_f16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : i1
      %192 = cute_nvgpu.atom.get_value(%189 : !mma_f16_f16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : i1
      %193 = arith.extui %190 : i1 to i32
      %194 = arith.extui %191 : i1 to i32
      %195 = arith.shli %193, %c13_i32 : i32
      %196 = arith.shli %194, %c14_i32 : i32
      %197 = arith.ori %195, %c138412048_i32 : i32
      %198 = arith.ori %197, %196 : i32
      cf.br ^bb60(%c0_i32 : i32)
    ^bb60(%199: i32):  // 2 preds: ^bb59, ^bb67
      %200 = arith.cmpi slt, %199, %124 : i32
      cf.cond_br %200, ^bb61, ^bb68 {llvm.loop_annotation = #loop_annotation}
    ^bb61:  // pred: ^bb60
      cf.br ^bb62(%c0_i32 : i32)
    ^bb62(%201: i32):  // 2 preds: ^bb61, ^bb66
      %202 = arith.cmpi slt, %201, %124 : i32
      cf.cond_br %202, ^bb63, ^bb67 {llvm.loop_annotation = #loop_annotation}
    ^bb63:  // pred: ^bb62
      cf.br ^bb64(%c0_i32 : i32)
    ^bb64(%203: i32):  // 2 preds: ^bb63, ^bb65
      %204 = arith.cmpi slt, %203, %124 : i32
      cf.cond_br %204, ^bb65, ^bb66 {llvm.loop_annotation = #loop_annotation}
    ^bb65:  // pred: ^bb64
      cute_nvgpu.arch.mma.SM100.umma(%tup_119, %tup_121, %tmem_ptr, %198, %192) {num_cta = 1 : i32, scale = 0 : i32, a_type = f16} : (!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, !cute.ptr<f32, tmem, align<16>>, i32, i1) -> ()
      %205 = arith.addi %203, %c1_i32 : i32
      cf.br ^bb64(%205 : i32)
    ^bb66:  // pred: ^bb64
      %206 = arith.addi %201, %c1_i32 : i32
      cf.br ^bb62(%206 : i32)
    ^bb67:  // pred: ^bb62
      %207 = arith.addi %199, %c1_i32 : i32
      cf.br ^bb60(%207 : i32)
    ^bb68:  // pred: ^bb60
      %208 = cute_nvgpu.atom.set_value(%189, %true : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_f16_f16_f32_128x256x16_
      %coord_122 = cute.make_coord(%130) : (i32) -> !cute.coord<"(_,_,2,?)">
      %idx_123 = cute.crd2idx(%coord_122, %5) : (!cute.coord<"(_,_,2,?)">, !cute.layout<"(1,1,4,4):(0,0,2,1024)">) -> !cute.int_tuple<"?{div=4}">
      %tup_124 = cute.add_offset(%ummaSmemDesc, %idx_123) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=4}">) -> !cute_nvgpu.smem_desc
      %idx_125 = cute.crd2idx(%coord_122, %4) : (!cute.coord<"(_,_,2,?)">, !cute.layout<"(1,1,4,4):(0,0,2,2048)">) -> !cute.int_tuple<"?{div=4}">
      %tup_126 = cute.add_offset(%ummaSmemDesc_48, %idx_125) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=4}">) -> !cute_nvgpu.smem_desc
      %209 = cute_nvgpu.atom.get_value(%208 : !mma_f16_f16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : i1
      %210 = cute_nvgpu.atom.get_value(%208 : !mma_f16_f16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : i1
      %211 = cute_nvgpu.atom.get_value(%208 : !mma_f16_f16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : i1
      %212 = arith.extui %209 : i1 to i32
      %213 = arith.extui %210 : i1 to i32
      %214 = arith.shli %212, %c13_i32 : i32
      %215 = arith.shli %213, %c14_i32 : i32
      %216 = arith.ori %214, %c138412048_i32 : i32
      %217 = arith.ori %216, %215 : i32
      cf.br ^bb69(%c0_i32 : i32)
    ^bb69(%218: i32):  // 2 preds: ^bb68, ^bb76
      %219 = arith.cmpi slt, %218, %124 : i32
      cf.cond_br %219, ^bb70, ^bb77 {llvm.loop_annotation = #loop_annotation}
    ^bb70:  // pred: ^bb69
      cf.br ^bb71(%c0_i32 : i32)
    ^bb71(%220: i32):  // 2 preds: ^bb70, ^bb75
      %221 = arith.cmpi slt, %220, %124 : i32
      cf.cond_br %221, ^bb72, ^bb76 {llvm.loop_annotation = #loop_annotation}
    ^bb72:  // pred: ^bb71
      cf.br ^bb73(%c0_i32 : i32)
    ^bb73(%222: i32):  // 2 preds: ^bb72, ^bb74
      %223 = arith.cmpi slt, %222, %124 : i32
      cf.cond_br %223, ^bb74, ^bb75 {llvm.loop_annotation = #loop_annotation}
    ^bb74:  // pred: ^bb73
      cute_nvgpu.arch.mma.SM100.umma(%tup_124, %tup_126, %tmem_ptr, %217, %211) {num_cta = 1 : i32, scale = 0 : i32, a_type = f16} : (!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, !cute.ptr<f32, tmem, align<16>>, i32, i1) -> ()
      %224 = arith.addi %222, %c1_i32 : i32
      cf.br ^bb73(%224 : i32)
    ^bb75:  // pred: ^bb73
      %225 = arith.addi %220, %c1_i32 : i32
      cf.br ^bb71(%225 : i32)
    ^bb76:  // pred: ^bb71
      %226 = arith.addi %218, %c1_i32 : i32
      cf.br ^bb69(%226 : i32)
    ^bb77:  // pred: ^bb69
      %227 = cute_nvgpu.atom.set_value(%208, %true : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_f16_f16_f32_128x256x16_
      %coord_127 = cute.make_coord(%130) : (i32) -> !cute.coord<"(_,_,3,?)">
      %idx_128 = cute.crd2idx(%coord_127, %5) : (!cute.coord<"(_,_,3,?)">, !cute.layout<"(1,1,4,4):(0,0,2,1024)">) -> !cute.int_tuple<"?{div=2}">
      %tup_129 = cute.add_offset(%ummaSmemDesc, %idx_128) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
      %idx_130 = cute.crd2idx(%coord_127, %4) : (!cute.coord<"(_,_,3,?)">, !cute.layout<"(1,1,4,4):(0,0,2,2048)">) -> !cute.int_tuple<"?{div=2}">
      %tup_131 = cute.add_offset(%ummaSmemDesc_48, %idx_130) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
      %228 = cute_nvgpu.atom.get_value(%227 : !mma_f16_f16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : i1
      %229 = cute_nvgpu.atom.get_value(%227 : !mma_f16_f16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : i1
      %230 = cute_nvgpu.atom.get_value(%227 : !mma_f16_f16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : i1
      %231 = arith.extui %228 : i1 to i32
      %232 = arith.extui %229 : i1 to i32
      %233 = arith.shli %231, %c13_i32 : i32
      %234 = arith.shli %232, %c14_i32 : i32
      %235 = arith.ori %233, %c138412048_i32 : i32
      %236 = arith.ori %235, %234 : i32
      cf.br ^bb78(%c0_i32 : i32)
    ^bb78(%237: i32):  // 2 preds: ^bb77, ^bb85
      %238 = arith.cmpi slt, %237, %124 : i32
      cf.cond_br %238, ^bb79, ^bb86 {llvm.loop_annotation = #loop_annotation}
    ^bb79:  // pred: ^bb78
      cf.br ^bb80(%c0_i32 : i32)
    ^bb80(%239: i32):  // 2 preds: ^bb79, ^bb84
      %240 = arith.cmpi slt, %239, %124 : i32
      cf.cond_br %240, ^bb81, ^bb85 {llvm.loop_annotation = #loop_annotation}
    ^bb81:  // pred: ^bb80
      cf.br ^bb82(%c0_i32 : i32)
    ^bb82(%241: i32):  // 2 preds: ^bb81, ^bb83
      %242 = arith.cmpi slt, %241, %124 : i32
      cf.cond_br %242, ^bb83, ^bb84 {llvm.loop_annotation = #loop_annotation}
    ^bb83:  // pred: ^bb82
      cute_nvgpu.arch.mma.SM100.umma(%tup_129, %tup_131, %tmem_ptr, %236, %230) {num_cta = 1 : i32, scale = 0 : i32, a_type = f16} : (!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, !cute.ptr<f32, tmem, align<16>>, i32, i1) -> ()
      %243 = arith.addi %241, %c1_i32 : i32
      cf.br ^bb82(%243 : i32)
    ^bb84:  // pred: ^bb82
      %244 = arith.addi %239, %c1_i32 : i32
      cf.br ^bb80(%244 : i32)
    ^bb85:  // pred: ^bb80
      %245 = arith.addi %237, %c1_i32 : i32
      cf.br ^bb78(%245 : i32)
    ^bb86:  // pred: ^bb78
      %246 = cute_nvgpu.atom.set_value(%227, %true : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_f16_f16_f32_128x256x16_
      %247 = builtin.unrealized_conversion_cast %246 : !mma_f16_f16_f32_128x256x16_ to !llvm.struct<(i1, i1, i1)>
      %248 = nvvm.elect.sync -> i1
      cf.cond_br %248, ^bb87, ^bb88
    ^bb87:  // pred: ^bb86
      %ptr_132 = cute.add_offset(%ptr_9, %int_tuple_110) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
      %249 = builtin.unrealized_conversion_cast %ptr_132 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.tcgen05.commit.arrive %249 : !llvm.ptr<3>
      cf.br ^bb88
    ^bb88:  // 2 preds: ^bb86, ^bb87
      %250 = arith.addi %125, %c1_i32 : i32
      cf.br ^bb29(%250, %163, %161, %162, %166, %168, %170, %247 : i32, i32, i32, i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>)
    ^bb89:  // pred: ^bb29
      %251 = nvvm.elect.sync -> i1
      cf.cond_br %251, ^bb90, ^bb91
    ^bb90:  // pred: ^bb89
      %dyn = cute.derefine(%iter_15) : !cute.ptr<i64, smem, align<64>> to !cute.ptr<i64, smem>
      %252 = builtin.unrealized_conversion_cast %dyn : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.tcgen05.commit.arrive %252 : !llvm.ptr<3>
      cf.br ^bb91
    ^bb91:  // 2 preds: ^bb89, ^bb90
      cf.br ^bb92
    ^bb92:  // 2 preds: ^bb12, ^bb91
      cf.cond_br %45, ^bb93, ^bb94
    ^bb93:  // pred: ^bb92
      cute_nvgpu.arch.sm100.relinquish_tmem_alloc_permit [ cta_1]
      cf.br ^bb94
    ^bb94:  // 2 preds: ^bb92, ^bb93
      %dyn_133 = cute.derefine(%iter_15) : !cute.ptr<i64, smem, align<64>> to !cute.ptr<i64, smem>
      %253 = builtin.unrealized_conversion_cast %dyn_133 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %253, %c0_i32, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %iter_134 = cute.get_iter(%rmem) : !memref_rmem_f32_
      %254 = cute.get_scalars(%21) : !cute.int_tuple<"1">
      %255 = builtin.unrealized_conversion_cast %iter_134 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
      %iter_135 = cute.get_iter(%rmem_67) : !memref_rmem_f16_
      %256 = cute.get_scalars(%18) : !cute.int_tuple<"4">
      cf.br ^bb95(%c0_i32 : i32)
    ^bb95(%257: i32):  // 2 preds: ^bb94, ^bb102
      %258 = arith.cmpi slt, %257, %c4_i32 : i32
      cf.cond_br %258, ^bb96, ^bb103
    ^bb96:  // pred: ^bb95
      %coord_136 = cute.make_coord(%257) : (i32) -> !cute.coord<"(_,_,?)">
      %idx_137 = cute.crd2idx(%coord_136, %3) : (!cute.coord<"(_,_,?)">, !cute.layout<"(((64,32),1),1,((1,4),1,1)):(((1,65536),0),0,((0,64),0,0))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_138 = cute.add_offset(%ptr_63, %idx_137) : (!cute.ptr<f32, tmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<f32, tmem, align<16>>
      cf.br ^bb97(%c0_i32 : i32)
    ^bb97(%259: i32):  // 2 preds: ^bb96, ^bb98
      %260 = arith.cmpi slt, %259, %254 : i32
      cf.cond_br %260, ^bb98, ^bb99 {llvm.loop_annotation = #loop_annotation}
    ^bb98:  // pred: ^bb97
      %261 = "cute_nvgpu.arch.copy.SM100.tmem_load"(%ptr_138) <{num_b = 32 : i32, num_dp = 32 : i32, num_rep = 64 : i32}> : (!cute.ptr<f32, tmem, align<16>>) -> vector<64xi32>
      llvm.store %261, %255 : vector<64xi32>, !llvm.ptr
      %262 = arith.addi %259, %c1_i32 : i32
      cf.br ^bb97(%262 : i32)
    ^bb99:  // pred: ^bb97
      %263 = cute.memref.load_vec %rmem : !memref_rmem_f32_
      %264 = arith.truncf %263 : vector<64xf32> to vector<64xf16>
      cute.memref.store_vec %264, %rmem_67 : !memref_rmem_f16_
      %idx_139 = cute.crd2idx(%coord_136, %2) : (!cute.coord<"(_,_,?)">, !cute.layout<"((64,1),1,((1,4),1,1)):((1,0),0,((0,64),0,0))">) -> !cute.int_tuple<"?{div=64}">
      %ptr_140 = cute.add_offset(%ptr_66, %idx_139) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<f16, gmem, align<32>>
      cf.br ^bb100(%c0_i32 : i32)
    ^bb100(%265: i32):  // 2 preds: ^bb99, ^bb101
      %266 = arith.cmpi slt, %265, %256 : i32
      cf.cond_br %266, ^bb101, ^bb102 {llvm.loop_annotation = #loop_annotation}
    ^bb101:  // pred: ^bb100
      %coord_141 = cute.make_coord(%265) : (i32) -> !cute.coord<"(_,?)">
      %idx_142 = cute.crd2idx(%coord_141, %1) : (!cute.coord<"(_,?)">, !cute.layout<"(16,(4)):(1,(16))">) -> !cute.int_tuple<"?{div=16}">
      %ptr_143 = cute.add_offset(%iter_135, %idx_142) : (!cute.ptr<f16, rmem, align<32>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<f16, rmem, align<32>>
      %ptr_144 = cute.add_offset(%ptr_140, %idx_142) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<f16, gmem, align<32>>
      %267 = builtin.unrealized_conversion_cast %ptr_143 : !cute.ptr<f16, rmem, align<32>> to !llvm.ptr
      %268 = builtin.unrealized_conversion_cast %ptr_144 : !cute.ptr<f16, gmem, align<32>> to !llvm.ptr<1>
      %269 = llvm.load %267 {alignment = 32 : i64} : !llvm.ptr -> vector<16xf16>
      llvm.store %269, %268 {alignment = 32 : i64} : vector<16xf16>, !llvm.ptr<1>
      %270 = arith.addi %265, %c1_i32 : i32
      cf.br ^bb100(%270 : i32)
    ^bb102:  // pred: ^bb100
      %271 = arith.addi %257, %c1_i32 : i32
      cf.br ^bb95(%271 : i32)
    ^bb103:  // pred: ^bb95
      %272 = builtin.unrealized_conversion_cast %ptr_16 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %272, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>} : !llvm.ptr<3>, i32
      nvvm.barrier id = %c1_i32
      cf.cond_br %45, ^bb104, ^bb105
    ^bb104:  // pred: ^bb103
      cute_nvgpu.arch.sm100.dealloc_tmem(%tmem_ptr, %c512_i32) [ cta_1] : !cute.ptr<f32, tmem, align<16>>, i32
      cf.br ^bb105
    ^bb105:  // 2 preds: ^bb103, ^bb104
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
    %152 = cuda.cast %c0_i64 : i64 -> !cuda.stream
    %153 = cuda.launch_cfg.create<max_attrs = 2 : i32> (blockDim = (%c128_i32, %c1_i32, %c1_i32), dynamicSmemBytes = %c196736_i64, gridDim = (%150, %151, %c1_i32), stream = %152) : i32, i32, i32, i64, i32, i32, i32, !cuda.stream -> !cuda.launch_cfg<max_attrs = 2>
    %154 = cuda.launch_ex @kernels::@kernel_cutlass_kernel_TiledMMA_ThrLayoutVMNK11110000_PermutationMNK____MMAAtom_ThrID10_ShapeMNK12825616_TVLayoutA1128161281128_TVLayoutB1256162561256_TVLayoutC11282561281128_CopyAtom_ThrI_0<%153> (%9, %86, %view, %144, %view_6, %arg2) : !cuda.launch_cfg<max_attrs = 2>, (!mma_f16_f16_f32_128x256x16_, !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, internal_val_type = f16>, !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">, !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 262144, tma_gbasis = <"(64,256):(1@1,1@0)">, internal_val_type = f16>, !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">, !memref_gmem_f16_) -> !cuda.result
    %155 = cuda.cast %154 : !cuda.result -> i32
    cuda.return_if_error %155 : i32
    return %c0_i32 : i32
  }
}
