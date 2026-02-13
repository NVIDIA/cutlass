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
      %26 = nvvm.read.ptx.sreg.tid.y range <i32, 0, 1024> : i32
      %27 = nvvm.read.ptx.sreg.tid.z range <i32, 0, 64> : i32
      %28 = nvvm.read.ptx.sreg.ntid.x range <i32, 1, 1024> : i32
      %29 = nvvm.read.ptx.sreg.ntid.y range <i32, 1, 1024> : i32
      %30 = arith.muli %26, %28 : i32
      %31 = arith.addi %25, %30 : i32
      %32 = arith.muli %27, %28 : i32
      %33 = arith.muli %32, %29 : i32
      %34 = arith.addi %31, %33 : i32
      %35 = arith.floordivsi %34, %c32_i32 : i32
      %36 = cute_nvgpu.arch.make_warp_uniform(%35) : i32
      %37 = nvvm.read.ptx.sreg.ctaid.x range <i32, 0, 2147483647> : i32
      %38 = nvvm.read.ptx.sreg.ctaid.y range <i32, 0, 65535> : i32
      %smem_ptr = cute_nvgpu.arch.get_dyn_smem() : !cute.ptr<i8, smem, align<1024>>
      %ptr = cute.add_offset(%smem_ptr, %24) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"88">) -> !cute.ptr<i8, smem, align<8>>
      %ptr_0 = cute.add_offset(%smem_ptr, %23) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"64">) -> !cute.ptr<i8, smem, align<64>>
      %ptr_1 = cute.add_offset(%smem_ptr, %22) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"80">) -> !cute.ptr<i8, smem, align<16>>
      %iter = cute.recast_iter(%ptr_1) : !cute.ptr<i8, smem, align<16>> to !cute.ptr<i32, smem, align<16>>
      %39 = cute.ptrtoint(%ptr) : !cute.ptr<i8, smem, align<8>> to i32
      %40 = arith.addi %39, %c127_i32 : i32
      %41 = arith.andi %40, %c-128_i32 : i32
      %42 = arith.extsi %41 : i32 to i64
      %iv = cute.assume(%42) : (i64) -> !cute.i64<divby 128>
      %43 = cute.inttoptr(%iv) : !cute.i64<divby 128> to !cute.ptr<i8, smem, align<128>>
      %ptr_2 = cute.add_offset(%43, %21) : (!cute.ptr<i8, smem, align<128>>, !cute.int_tuple<"65536">) -> !cute.ptr<i8, smem, align<128>>
      %iter_3 = cute.recast_iter(%43) : !cute.ptr<i8, smem, align<128>> to !cute.ptr<f16, smem, align<128>, S<3,4,3>>
      %iter_4 = cute.recast_iter(%ptr_2) : !cute.ptr<i8, smem, align<128>> to !cute.ptr<f16, smem, align<128>, S<3,4,3>>
      %44 = arith.cmpi eq, %36, %c0_i32 : i32
      scf.if %44 {
        cute_nvgpu.arch.sm100.alloc_tmem(%c512_i32, %iter) [ cta_1] : i32, !cute.ptr<i32, smem, align<16>>
      }
      scf.if %44 {
        cute_nvgpu.prefetch_tma_desc(%arg1) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, internal_val_type = f16>) -> ()
        cute_nvgpu.prefetch_tma_desc(%arg3) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 262144, tma_gbasis = <"(64,256):(1@1,1@0)">, internal_val_type = f16>) -> ()
      }
      %iter_5 = cute.recast_iter(%smem_ptr) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<i64, smem, align<1024>>
      scf.if %44 {
        %84 = builtin.unrealized_conversion_cast %iter_5 : !cute.ptr<i64, smem, align<1024>> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %84, %c1_i32 : !llvm.ptr<3>, i32
        %ptr_61 = cute.add_offset(%iter_5, %20) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"1">) -> !cute.ptr<i64, smem>
        %85 = builtin.unrealized_conversion_cast %ptr_61 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %85, %c1_i32 : !llvm.ptr<3>, i32
        %ptr_62 = cute.add_offset(%iter_5, %19) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"2">) -> !cute.ptr<i64, smem, align<16>>
        %86 = builtin.unrealized_conversion_cast %ptr_62 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %86, %c1_i32 : !llvm.ptr<3>, i32
        %ptr_63 = cute.add_offset(%iter_5, %18) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"3">) -> !cute.ptr<i64, smem>
        %87 = builtin.unrealized_conversion_cast %ptr_63 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %87, %c1_i32 : !llvm.ptr<3>, i32
      }
      %ptr_6 = cute.add_offset(%iter_5, %17) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"4">) -> !cute.ptr<i64, smem, align<32>>
      scf.if %44 {
        %84 = builtin.unrealized_conversion_cast %ptr_6 : !cute.ptr<i64, smem, align<32>> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %84, %c1_i32 : !llvm.ptr<3>, i32
        %int_tuple_61 = cute.make_int_tuple() : () -> !cute.int_tuple<"5">
        %ptr_62 = cute.add_offset(%iter_5, %int_tuple_61) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"5">) -> !cute.ptr<i64, smem>
        %85 = builtin.unrealized_conversion_cast %ptr_62 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %85, %c1_i32 : !llvm.ptr<3>, i32
        %int_tuple_63 = cute.make_int_tuple() : () -> !cute.int_tuple<"6">
        %ptr_64 = cute.add_offset(%iter_5, %int_tuple_63) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"6">) -> !cute.ptr<i64, smem, align<16>>
        %86 = builtin.unrealized_conversion_cast %ptr_64 : !cute.ptr<i64, smem, align<16>> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %86, %c1_i32 : !llvm.ptr<3>, i32
        %int_tuple_65 = cute.make_int_tuple() : () -> !cute.int_tuple<"7">
        %ptr_66 = cute.add_offset(%iter_5, %int_tuple_65) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"7">) -> !cute.ptr<i64, smem>
        %87 = builtin.unrealized_conversion_cast %ptr_66 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %87, %c1_i32 : !llvm.ptr<3>, i32
      }
      nvvm.fence.mbarrier.init
      nvvm.barrier
      %iter_7 = cute.recast_iter(%ptr_0) : !cute.ptr<i8, smem, align<64>> to !cute.ptr<i64, smem, align<64>>
      scf.if %44 {
        %84 = builtin.unrealized_conversion_cast %iter_7 : !cute.ptr<i64, smem, align<64>> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %84, %c1_i32 : !llvm.ptr<3>, i32
      }
      %ptr_8 = cute.add_offset(%iter_7, %20) : (!cute.ptr<i64, smem, align<64>>, !cute.int_tuple<"1">) -> !cute.ptr<i64, smem>
      scf.if %44 {
        %84 = builtin.unrealized_conversion_cast %ptr_8 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        nvvm.mbarrier.init.shared %84, %c128_i32 : !llvm.ptr<3>, i32
      }
      nvvm.fence.mbarrier.init
      nvvm.barrier
      %coord = cute.make_coord(%37, %38) : (i32, i32) -> !cute.coord<"(?,?,_)">
      %45:2 = cute.get_scalars(%coord) <{only_dynamic}> : !cute.coord<"(?,?,_)">
      %coord_9 = cute.make_coord(%45#0) : (i32) -> !cute.coord<"((_,_),(?,_))">
      %lay = cute.get_layout(%arg2) : !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">
      %46:2 = cute.get_scalars(%lay) <{only_dynamic}> : !cute.layout<"(?,?{div=8192}):(1@1,1@0)">
      %47 = arith.ceildivsi %46#0, %c128_i32 : i32
      %48 = arith.ceildivsi %46#1, %c64_i32 : i32
      %shape = cute.make_shape(%47, %48) : (i32, i32) -> !cute.shape<"((128,64),(?,?))">
      %lay_10 = cute.make_layout(%shape, %16) : !cute.layout<"((128,64),(?,?)):((1@1,1@0),(128@1,64@0))">
      %49:2 = cute.get_scalars(%lay_10) <{only_dynamic}> : !cute.layout<"((128,64),(?,?)):((1@1,1@0),(128@1,64@0))">
      %shape_11 = cute.make_shape(%49#1) : (i32) -> !cute.shape<"(128,64,?)">
      %lay_12 = cute.make_layout(%shape_11, %15) : !cute.layout<"(128,64,?):(1@1,1@0,64@0)">
      %idx = cute.crd2idx(%coord_9, %lay_10) : (!cute.coord<"((_,_),(?,_))">, !cute.layout<"((128,64),(?,?)):((1@1,1@0),(128@1,64@0))">) -> !cute.int_tuple<"(0,?{div=128})">
      %tup = cute.add_offset(%14, %idx) : (!cute.int_tuple<"(0,0)">, !cute.int_tuple<"(0,?{div=128})">) -> !cute.int_tuple<"(0,?{div=128})">
      %coord_13 = cute.make_coord(%45#1) : (i32) -> !cute.coord<"((_,_),(?,_))">
      %lay_14 = cute.get_layout(%arg4) : !cute.coord_tensor<"(0,0)", "(?,?{div=8192}):(1@1,1@0)">
      %50:2 = cute.get_scalars(%lay_14) <{only_dynamic}> : !cute.layout<"(?,?{div=8192}):(1@1,1@0)">
      %51 = arith.ceildivsi %50#0, %c256_i32 : i32
      %52 = arith.ceildivsi %50#1, %c64_i32 : i32
      %shape_15 = cute.make_shape(%51, %52) : (i32, i32) -> !cute.shape<"((256,64),(?,?))">
      %lay_16 = cute.make_layout(%shape_15, %13) : !cute.layout<"((256,64),(?,?)):((1@1,1@0),(256@1,64@0))">
      %53:2 = cute.get_scalars(%lay_16) <{only_dynamic}> : !cute.layout<"((256,64),(?,?)):((1@1,1@0),(256@1,64@0))">
      %shape_17 = cute.make_shape(%53#1) : (i32) -> !cute.shape<"(256,64,?)">
      %lay_18 = cute.make_layout(%shape_17, %15) : !cute.layout<"(256,64,?):(1@1,1@0,64@0)">
      %idx_19 = cute.crd2idx(%coord_13, %lay_16) : (!cute.coord<"((_,_),(?,_))">, !cute.layout<"((256,64),(?,?)):((1@1,1@0),(256@1,64@0))">) -> !cute.int_tuple<"(0,?{div=256})">
      %tup_20 = cute.add_offset(%14, %idx_19) : (!cute.int_tuple<"(0,0)">, !cute.int_tuple<"(0,?{div=256})">) -> !cute.int_tuple<"(0,?{div=256})">
      %coord_21 = cute.make_coord(%45#0, %45#1) : (i32, i32) -> !cute.coord<"((_,_),(?,?))">
      %lay_22 = cute.get_layout(%arg5) : !memref_gmem_f16_
      %54:3 = cute.get_scalars(%lay_22) <{only_dynamic}> : !cute.layout<"(?,?{div=8192}):(?{i64 div=8192},1)">
      %55 = arith.ceildivsi %54#0, %c128_i32 : i32
      %56 = arith.muli %54#2, %c128_i64 : i64
      %57 = arith.ceildivsi %54#1, %c256_i32 : i32
      %shape_23 = cute.make_shape(%55, %57) : (i32, i32) -> !cute.shape<"((128,256),(?,?))">
      %iv_24 = cute.assume(%54#2) : (i64) -> !cute.i64<divby 8192>
      %iv_25 = cute.assume(%56) : (i64) -> !cute.i64<divby 1048576>
      %stride = cute.make_stride(%iv_24, %iv_25) : (!cute.i64<divby 8192>, !cute.i64<divby 1048576>) -> !cute.stride<"((?{i64 div=8192},1),(?{i64 div=1048576},256))">
      %lay_26 = cute.make_layout(%shape_23, %stride) : !cute.layout<"((128,256),(?,?)):((?{i64 div=8192},1),(?{i64 div=1048576},256))">
      %58:4 = cute.get_scalars(%lay_26) <{only_dynamic}> : !cute.layout<"((128,256),(?,?)):((?{i64 div=8192},1),(?{i64 div=1048576},256))">
      %iv_27 = cute.assume(%58#2) : (i64) -> !cute.i64<divby 8192>
      %stride_28 = cute.make_stride(%iv_27) : (!cute.i64<divby 8192>) -> !cute.stride<"(?{i64 div=8192},1)">
      %lay_29 = cute.make_layout(%12, %stride_28) : !cute.layout<"(128,256):(?{i64 div=8192},1)">
      %idx_30 = cute.crd2idx(%coord_21, %lay_26) : (!cute.coord<"((_,_),(?,?))">, !cute.layout<"((128,256),(?,?)):((?{i64 div=8192},1),(?{i64 div=1048576},256))">) -> !cute.int_tuple<"?{i64 div=256}">
      %iter_31 = cute.get_iter(%arg5) : !memref_gmem_f16_
      %ptr_32 = cute.add_offset(%iter_31, %idx_30) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{i64 div=256}">) -> !cute.ptr<f16, gmem, align<32>>
      %59 = cute.get_scalars(%lay_12) <{only_dynamic}> : !cute.layout<"(128,64,?):(1@1,1@0,64@0)">
      %shape_33 = cute.make_shape(%59) : (i32) -> !cute.shape<"((128,16),1,4,?)">
      %lay_34 = cute.make_layout(%shape_33, %11) : !cute.layout<"((128,16),1,4,?):((1@1,1@0),0,16@0,64@0)">
      %60 = cute.get_scalars(%lay_18) <{only_dynamic}> : !cute.layout<"(256,64,?):(1@1,1@0,64@0)">
      %shape_35 = cute.make_shape(%60) : (i32) -> !cute.shape<"((256,16),1,4,?)">
      %lay_36 = cute.make_layout(%shape_35, %11) : !cute.layout<"((256,16),1,4,?):((1@1,1@0),0,16@0,64@0)">
      %61 = cute.get_scalars(%lay_29) <{only_dynamic}> : !cute.layout<"(128,256):(?{i64 div=8192},1)">
      %iv_37 = cute.assume(%61) : (i64) -> !cute.i64<divby 8192>
      %stride_38 = cute.make_stride(%iv_37) : (!cute.i64<divby 8192>) -> !cute.stride<"((?{i64 div=8192},1),0,0)">
      %lay_39 = cute.make_layout(%10, %stride_38) : !cute.layout<"((128,256),1,1):((?{i64 div=8192},1),0,0)">
      %ummaSmemDesc = cute_nvgpu.make_umma_smem_desc(%iter_3 : !cute.ptr<f16, smem, align<128>, S<3,4,3>>) layout = <"((128,16),1,4,4):((64,1),0,16,8192)">, major = <k> -> !cute_nvgpu.smem_desc
      %ummaSmemDesc_40 = cute_nvgpu.make_umma_smem_desc(%iter_4 : !cute.ptr<f16, smem, align<128>, S<3,4,3>>) layout = <"((256,16),1,4,4):((64,1),0,16,16384)">, major = <k> -> !cute_nvgpu.smem_desc
      %62 = cute.get_scalars(%lay_34) <{only_dynamic}> : !cute.layout<"((128,16),1,4,?):((1@1,1@0),0,16@0,64@0)">
      %shape_41 = cute.make_shape(%62) : (i32) -> !cute.shape<"(((128,16),1,4),?)">
      %lay_42 = cute.make_layout(%shape_41, %9) : !cute.layout<"(((128,16),1,4),?):(((1@1,1@0),0,16@0),64@0)">
      %63 = cute.get_scalars(%lay_42) <{only_dynamic}> : !cute.layout<"(((128,16),1,4),?):(((1@1,1@0),0,16@0),64@0)">
      %shape_43 = cute.make_shape(%63) : (i32) -> !cute.shape<"(((64,128),1),?)">
      %lay_44 = cute.make_layout(%shape_43, %8) : !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">
      %64 = cute.get_scalars(%lay_36) <{only_dynamic}> : !cute.layout<"((256,16),1,4,?):((1@1,1@0),0,16@0,64@0)">
      %shape_45 = cute.make_shape(%64) : (i32) -> !cute.shape<"(((256,16),1,4),?)">
      %lay_46 = cute.make_layout(%shape_45, %9) : !cute.layout<"(((256,16),1,4),?):(((1@1,1@0),0,16@0),64@0)">
      %65 = cute.get_scalars(%lay_46) <{only_dynamic}> : !cute.layout<"(((256,16),1,4),?):(((1@1,1@0),0,16@0),64@0)">
      %shape_47 = cute.make_shape(%65) : (i32) -> !cute.shape<"(((64,256),1),?)">
      %lay_48 = cute.make_layout(%shape_47, %8) : !cute.layout<"(((64,256),1),?):(((1@0,1@1),0),64@0)">
      nvvm.barrier id = %c1_i32 number_of_threads = %c128_i32
      %tmem_ptr = cute_nvgpu.arch.sm100.retrieve_tmem_ptr(%iter) : !cute.ptr<i32, smem, align<16>> -> !cute.ptr<f32, tmem, align<16>>
      %66 = cute.get_scalars(%lay_39) <{only_dynamic}> : !cute.layout<"((128,256),1,1):((?{i64 div=8192},1),0,0)">
      %iv_49 = cute.assume(%66) : (i64) -> !cute.i64<divby 8192>
      %stride_50 = cute.make_stride(%iv_49) : (!cute.i64<divby 8192>) -> !cute.stride<"(((?{i64 div=8192},1)),((0,64),0,0))">
      %lay_51 = cute.make_layout(%7, %stride_50) : !cute.layout<"(((128,64)),((1,4),1,1)):(((?{i64 div=8192},1)),((0,64),0,0))">
      %coord_52 = cute.make_coord(%25) : (i32) -> !cute.coord<"?">
      %67 = cute.get_scalars(%coord_52) <{only_dynamic}> : !cute.coord<"?">
      %68 = arith.divsi %67, %c32_i32 : i32
      %69 = arith.muli %68, %c2097152_i32 : i32
      %iv_53 = cute.assume(%69) : (i32) -> !cute.i32<divby 2097152>
      %int_tuple = cute.make_int_tuple(%iv_53) : (!cute.i32<divby 2097152>) -> !cute.int_tuple<"?{div=2097152}">
      %ptr_54 = cute.add_offset(%tmem_ptr, %int_tuple) : (!cute.ptr<f32, tmem, align<16>>, !cute.int_tuple<"?{div=2097152}">) -> !cute.ptr<f32, tmem, align<16>>
      %70 = cute.get_scalars(%lay_51) <{only_dynamic}> : !cute.layout<"(((128,64)),((1,4),1,1)):(((?{i64 div=8192},1)),((0,64),0,0))">
      %71 = arith.muli %70, %c32_i64 : i64
      %72 = arith.remsi %67, %c32_i32 : i32
      %73 = arith.extsi %72 : i32 to i64
      %74 = arith.muli %73, %70 : i64
      %75 = arith.extsi %68 : i32 to i64
      %76 = arith.muli %75, %71 : i64
      %77 = arith.addi %74, %76 : i64
      %iv_55 = cute.assume(%77) : (i64) -> !cute.i64<divby 8192>
      %int_tuple_56 = cute.make_int_tuple(%iv_55) : (!cute.i64<divby 8192>) -> !cute.int_tuple<"?{i64 div=8192}">
      %ptr_57 = cute.add_offset(%ptr_32, %int_tuple_56) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{i64 div=8192}">) -> !cute.ptr<f16, gmem, align<32>>
      %rmem = cute.memref.alloca() : !memref_rmem_f32_
      %rmem_58 = cute.memref.alloca() : !memref_rmem_f16_
      %sz = cute.size(%lay_12) <{mode = [2]}> : (!cute.layout<"(128,64,?):(1@1,1@0,64@0)">) -> !cute.int_tuple<"?">
      %e0 = cute.get_leaves(%sz) : !cute.int_tuple<"?">
      %78 = cute.get_scalars(%e0) : !cute.int_tuple<"?">
      scf.if %44 {
        %84 = builtin.unrealized_conversion_cast %ptr_8 : !cute.ptr<i64, smem> to !llvm.ptr<3>
        nvvm.mbarrier.try_wait.parity.shared %84, %c1_i32, %c10000000_i32 : !llvm.ptr<3>, i32, i32
        %85 = cute_nvgpu.atom.make_exec_tma(%arg1) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128):(1@1,1@0)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128):(1@1,1@0)">>
        %86 = cute_nvgpu.atom.make_exec_tma(%arg3) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 262144, tma_gbasis = <"(64,256):(1@1,1@0)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_load<f16, copy_bits = 262144, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,256):(1@1,1@0)">>
        %87 = arith.minsi %78, %c2_i32 : i32
        %88 = cute.get_scalars(%20) : !cute.int_tuple<"1">
        %89:3 = scf.for %arg6 = %c0_i32 to %87 step %c1_i32 iter_args(%arg7 = %c0_i32, %arg8 = %c1_i32, %arg9 = %c0_i32) -> (i32, i32, i32)  : i32 {
          %int_tuple_61 = cute.make_int_tuple(%arg7) : (i32) -> !cute.int_tuple<"?">
          %ptr_62 = cute.add_offset(%ptr_6, %int_tuple_61) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
          %93 = builtin.unrealized_conversion_cast %ptr_62 : !cute.ptr<i64, smem> to !llvm.ptr<3>
          nvvm.mbarrier.try_wait.parity.shared %93, %arg8, %c10000000_i32 : !llvm.ptr<3>, i32, i32
          %94 = nvvm.elect.sync -> i1
          scf.if %94 {
            %ptr_80 = cute.add_offset(%iter_5, %int_tuple_61) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
            %108 = builtin.unrealized_conversion_cast %ptr_80 : !cute.ptr<i64, smem> to !llvm.ptr<3>
            nvvm.mbarrier.txn %108, %c49152_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
          }
          %95 = arith.addi %arg7, %c1_i32 : i32
          %96 = arith.addi %arg9, %c1_i32 : i32
          %97 = arith.cmpi eq, %95, %c4_i32 : i32
          %98 = arith.select %97, %c0_i32, %95 : i32
          %99 = scf.if %97 -> (i32) {
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
          %idx_68 = cute.crd2idx(%coord_67, %6) : (!cute.coord<"(_,?)">, !cute.layout<"((8192,1),4):((1,0),8192)">) -> !cute.int_tuple<"?{div=8192}">
          %ptr_69 = cute.add_offset(%iter_3, %idx_68) : (!cute.ptr<f16, smem, align<128>, S<3,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<f16, smem, align<128>, S<3,4,3>>
          %ptr_70 = cute.add_offset(%iter_5, %int_tuple_61) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
          %int_tuple_71 = cute.make_int_tuple(%e0_66, %e1) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=128}">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
          %100 = cute_nvgpu.atom.set_value(%85, %ptr_70 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128):(1@1,1@0)">>
          %101 = cute_nvgpu.atom.get_value(%100 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
          %102 = cute_nvgpu.atom.get_value(%100 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<cache_policy>} : i64
          %TMADescAddr = cute_nvgpu.get_tma_desc_addr(%100 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128):(1@1,1@0)">>) -> !cute.ptr<generic, align<64>>
          %103:2 = cute.get_scalars(%int_tuple_71) : !cute.int_tuple<"(?{div=64},?{div=128})">
          scf.for %arg10 = %c0_i32 to %88 step %c1_i32  : i32 {
            cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr : !cute.ptr<generic, align<64>>, %ptr_69 : !cute.ptr<f16, smem, align<128>, S<3,4,3>>, %101 : !cute.ptr<smem, align<8>>, [%103#0, %103#1] : i32, i32) cache_policy = %102 mode = <tiled> num_cta = 1 : i32
          } {llvm.loop_annotation = #loop_annotation}
          %idx_72 = cute.crd2idx(%coord_63, %lay_48) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,256),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
          %tup_73 = cute.add_offset(%tup_20, %idx_72) : (!cute.int_tuple<"(0,?{div=256})">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.int_tuple<"(?{div=64},?{div=256})">
          %e0_74, %e1_75 = cute.get_leaves(%tup_73) : !cute.int_tuple<"(?{div=64},?{div=256})">
          %idx_76 = cute.crd2idx(%coord_67, %5) : (!cute.coord<"(_,?)">, !cute.layout<"((16384,1),4):((1,0),16384)">) -> !cute.int_tuple<"?{div=16384}">
          %ptr_77 = cute.add_offset(%iter_4, %idx_76) : (!cute.ptr<f16, smem, align<128>, S<3,4,3>>, !cute.int_tuple<"?{div=16384}">) -> !cute.ptr<f16, smem, align<128>, S<3,4,3>>
          %int_tuple_78 = cute.make_int_tuple(%e0_74, %e1_75) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=256}">) -> !cute.int_tuple<"(?{div=64},?{div=256})">
          %104 = cute_nvgpu.atom.set_value(%86, %ptr_70 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 262144, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,256):(1@1,1@0)">>
          %105 = cute_nvgpu.atom.get_value(%104 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 262144, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,256):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
          %106 = cute_nvgpu.atom.get_value(%104 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 262144, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,256):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<cache_policy>} : i64
          %TMADescAddr_79 = cute_nvgpu.get_tma_desc_addr(%104 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 262144, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,256):(1@1,1@0)">>) -> !cute.ptr<generic, align<64>>
          %107:2 = cute.get_scalars(%int_tuple_78) : !cute.int_tuple<"(?{div=64},?{div=256})">
          scf.for %arg10 = %c0_i32 to %88 step %c1_i32  : i32 {
            cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr_79 : !cute.ptr<generic, align<64>>, %ptr_77 : !cute.ptr<f16, smem, align<128>, S<3,4,3>>, %105 : !cute.ptr<smem, align<8>>, [%107#0, %107#1] : i32, i32) cache_policy = %106 mode = <tiled> num_cta = 1 : i32
          } {llvm.loop_annotation = #loop_annotation}
          scf.yield %98, %99, %96 : i32, i32, i32
        }
        %90 = cute.get_scalars(%20) : !cute.int_tuple<"1">
        %91:7 = scf.for %arg6 = %c0_i32 to %78 step %c1_i32 iter_args(%arg7 = %89#2, %arg8 = %89#0, %arg9 = %89#1, %arg10 = %c0_i32, %arg11 = %c0_i32, %arg12 = %c0_i32, %arg13 = %arg0) -> (i32, i32, i32, i32, i32, i32, !mma_f16_f16_f32_128x256x16_)  : i32 {
          %93 = arith.addi %arg6, %87 : i32
          %94 = arith.cmpi ult, %93, %78 : i32
          %95:3 = scf.if %94 -> (i32, i32, i32) {
            %int_tuple_83 = cute.make_int_tuple(%arg8) : (i32) -> !cute.int_tuple<"?">
            %ptr_84 = cute.add_offset(%ptr_6, %int_tuple_83) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
            %143 = builtin.unrealized_conversion_cast %ptr_84 : !cute.ptr<i64, smem> to !llvm.ptr<3>
            nvvm.mbarrier.try_wait.parity.shared %143, %arg9, %c10000000_i32 : !llvm.ptr<3>, i32, i32
            %144 = nvvm.elect.sync -> i1
            scf.if %144 {
              %ptr_102 = cute.add_offset(%iter_5, %int_tuple_83) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
              %159 = builtin.unrealized_conversion_cast %ptr_102 : !cute.ptr<i64, smem> to !llvm.ptr<3>
              nvvm.mbarrier.txn %159, %c49152_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
            }
            %145 = arith.addi %arg8, %c1_i32 : i32
            %146 = arith.addi %arg7, %c1_i32 : i32
            %147 = arith.cmpi eq, %145, %c4_i32 : i32
            %148 = arith.select %147, %c0_i32, %145 : i32
            %149 = scf.if %147 -> (i32) {
              %159 = arith.xori %arg9, %c1_i32 : i32
              scf.yield %159 : i32
            } else {
              scf.yield %arg9 : i32
            }
            %coord_85 = cute.make_coord(%arg7) : (i32) -> !cute.coord<"(_,?)">
            %idx_86 = cute.crd2idx(%coord_85, %lay_44) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
            %tup_87 = cute.add_offset(%tup, %idx_86) : (!cute.int_tuple<"(0,?{div=128})">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
            %e0_88, %e1 = cute.get_leaves(%tup_87) : !cute.int_tuple<"(?{div=64},?{div=128})">
            %coord_89 = cute.make_coord(%arg8) : (i32) -> !cute.coord<"(_,?)">
            %idx_90 = cute.crd2idx(%coord_89, %6) : (!cute.coord<"(_,?)">, !cute.layout<"((8192,1),4):((1,0),8192)">) -> !cute.int_tuple<"?{div=8192}">
            %ptr_91 = cute.add_offset(%iter_3, %idx_90) : (!cute.ptr<f16, smem, align<128>, S<3,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<f16, smem, align<128>, S<3,4,3>>
            %ptr_92 = cute.add_offset(%iter_5, %int_tuple_83) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
            %int_tuple_93 = cute.make_int_tuple(%e0_88, %e1) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=128}">) -> !cute.int_tuple<"(?{div=64},?{div=128})">
            %150 = cute_nvgpu.atom.set_value(%85, %ptr_92 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128):(1@1,1@0)">>
            %151 = cute.get_scalars(%20) : !cute.int_tuple<"1">
            %152 = cute_nvgpu.atom.get_value(%150 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
            %153 = cute_nvgpu.atom.get_value(%150 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<cache_policy>} : i64
            %TMADescAddr = cute_nvgpu.get_tma_desc_addr(%150 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128):(1@1,1@0)">>) -> !cute.ptr<generic, align<64>>
            %154:2 = cute.get_scalars(%int_tuple_93) : !cute.int_tuple<"(?{div=64},?{div=128})">
            scf.for %arg14 = %c0_i32 to %151 step %c1_i32  : i32 {
              cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr : !cute.ptr<generic, align<64>>, %ptr_91 : !cute.ptr<f16, smem, align<128>, S<3,4,3>>, %152 : !cute.ptr<smem, align<8>>, [%154#0, %154#1] : i32, i32) cache_policy = %153 mode = <tiled> num_cta = 1 : i32
            } {llvm.loop_annotation = #loop_annotation}
            %idx_94 = cute.crd2idx(%coord_85, %lay_48) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,256),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
            %tup_95 = cute.add_offset(%tup_20, %idx_94) : (!cute.int_tuple<"(0,?{div=256})">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.int_tuple<"(?{div=64},?{div=256})">
            %e0_96, %e1_97 = cute.get_leaves(%tup_95) : !cute.int_tuple<"(?{div=64},?{div=256})">
            %idx_98 = cute.crd2idx(%coord_89, %5) : (!cute.coord<"(_,?)">, !cute.layout<"((16384,1),4):((1,0),16384)">) -> !cute.int_tuple<"?{div=16384}">
            %ptr_99 = cute.add_offset(%iter_4, %idx_98) : (!cute.ptr<f16, smem, align<128>, S<3,4,3>>, !cute.int_tuple<"?{div=16384}">) -> !cute.ptr<f16, smem, align<128>, S<3,4,3>>
            %int_tuple_100 = cute.make_int_tuple(%e0_96, %e1_97) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=256}">) -> !cute.int_tuple<"(?{div=64},?{div=256})">
            %155 = cute_nvgpu.atom.set_value(%86, %ptr_92 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 262144, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,256):(1@1,1@0)">>
            %156 = cute_nvgpu.atom.get_value(%155 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 262144, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,256):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
            %157 = cute_nvgpu.atom.get_value(%155 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 262144, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,256):(1@1,1@0)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<cache_policy>} : i64
            %TMADescAddr_101 = cute_nvgpu.get_tma_desc_addr(%155 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 262144, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,256):(1@1,1@0)">>) -> !cute.ptr<generic, align<64>>
            %158:2 = cute.get_scalars(%int_tuple_100) : !cute.int_tuple<"(?{div=64},?{div=256})">
            scf.for %arg14 = %c0_i32 to %151 step %c1_i32  : i32 {
              cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr_101 : !cute.ptr<generic, align<64>>, %ptr_99 : !cute.ptr<f16, smem, align<128>, S<3,4,3>>, %156 : !cute.ptr<smem, align<8>>, [%158#0, %158#1] : i32, i32) cache_policy = %157 mode = <tiled> num_cta = 1 : i32
            } {llvm.loop_annotation = #loop_annotation}
            scf.yield %148, %149, %146 : i32, i32, i32
          } else {
            scf.yield %arg8, %arg9, %arg7 : i32, i32, i32
          }
          %int_tuple_61 = cute.make_int_tuple(%arg11) : (i32) -> !cute.int_tuple<"?">
          %ptr_62 = cute.add_offset(%iter_5, %int_tuple_61) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
          %96 = builtin.unrealized_conversion_cast %ptr_62 : !cute.ptr<i64, smem> to !llvm.ptr<3>
          nvvm.mbarrier.try_wait.parity.shared %96, %arg12, %c10000000_i32 : !llvm.ptr<3>, i32, i32
          %97 = arith.addi %arg11, %c1_i32 : i32
          %98 = arith.addi %arg10, %c1_i32 : i32
          %99 = arith.cmpi eq, %97, %c4_i32 : i32
          %100 = arith.select %99, %c0_i32, %97 : i32
          %101 = scf.if %99 -> (i32) {
            %143 = arith.xori %arg12, %c1_i32 : i32
            scf.yield %143 : i32
          } else {
            scf.yield %arg12 : i32
          }
          %coord_63 = cute.make_coord(%arg11) : (i32) -> !cute.coord<"(_,_,0,?)">
          %idx_64 = cute.crd2idx(%coord_63, %4) : (!cute.coord<"(_,_,0,?)">, !cute.layout<"(1,1,4,4):(0,0,2,1024)">) -> !cute.int_tuple<"?{div=1024}">
          %tup_65 = cute.add_offset(%ummaSmemDesc, %idx_64) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=1024}">) -> !cute_nvgpu.smem_desc
          %idx_66 = cute.crd2idx(%coord_63, %3) : (!cute.coord<"(_,_,0,?)">, !cute.layout<"(1,1,4,4):(0,0,2,2048)">) -> !cute.int_tuple<"?{div=2048}">
          %tup_67 = cute.add_offset(%ummaSmemDesc_40, %idx_66) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2048}">) -> !cute_nvgpu.smem_desc
          %102 = cute_nvgpu.atom.get_value(%arg13 : !mma_f16_f16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : i1
          %103 = cute_nvgpu.atom.get_value(%arg13 : !mma_f16_f16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : i1
          %104 = cute_nvgpu.atom.get_value(%arg13 : !mma_f16_f16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : i1
          %105 = arith.extui %102 : i1 to i32
          %106 = arith.extui %103 : i1 to i32
          %107 = arith.shli %105, %c13_i32 : i32
          %108 = arith.shli %106, %c14_i32 : i32
          %109 = arith.ori %107, %c138412048_i32 : i32
          %110 = arith.ori %109, %108 : i32
          scf.for %arg14 = %c0_i32 to %90 step %c1_i32  : i32 {
            scf.for %arg15 = %c0_i32 to %90 step %c1_i32  : i32 {
              scf.for %arg16 = %c0_i32 to %90 step %c1_i32  : i32 {
                cute_nvgpu.arch.mma.SM100.umma(%tup_65, %tup_67, %tmem_ptr, %110, %104) {num_cta = 1 : i32, scale = 0 : i32, a_type = f16} : (!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, !cute.ptr<f32, tmem, align<16>>, i32, i1) -> ()
              } {llvm.loop_annotation = #loop_annotation}
            } {llvm.loop_annotation = #loop_annotation}
          } {llvm.loop_annotation = #loop_annotation}
          %111 = cute_nvgpu.atom.set_value(%arg13, %true : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_f16_f16_f32_128x256x16_
          %coord_68 = cute.make_coord(%arg11) : (i32) -> !cute.coord<"(_,_,1,?)">
          %idx_69 = cute.crd2idx(%coord_68, %4) : (!cute.coord<"(_,_,1,?)">, !cute.layout<"(1,1,4,4):(0,0,2,1024)">) -> !cute.int_tuple<"?{div=2}">
          %tup_70 = cute.add_offset(%ummaSmemDesc, %idx_69) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
          %idx_71 = cute.crd2idx(%coord_68, %3) : (!cute.coord<"(_,_,1,?)">, !cute.layout<"(1,1,4,4):(0,0,2,2048)">) -> !cute.int_tuple<"?{div=2}">
          %tup_72 = cute.add_offset(%ummaSmemDesc_40, %idx_71) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
          %112 = cute_nvgpu.atom.get_value(%111 : !mma_f16_f16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : i1
          %113 = cute_nvgpu.atom.get_value(%111 : !mma_f16_f16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : i1
          %114 = cute_nvgpu.atom.get_value(%111 : !mma_f16_f16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : i1
          %115 = arith.extui %112 : i1 to i32
          %116 = arith.extui %113 : i1 to i32
          %117 = arith.shli %115, %c13_i32 : i32
          %118 = arith.shli %116, %c14_i32 : i32
          %119 = arith.ori %117, %c138412048_i32 : i32
          %120 = arith.ori %119, %118 : i32
          scf.for %arg14 = %c0_i32 to %90 step %c1_i32  : i32 {
            scf.for %arg15 = %c0_i32 to %90 step %c1_i32  : i32 {
              scf.for %arg16 = %c0_i32 to %90 step %c1_i32  : i32 {
                cute_nvgpu.arch.mma.SM100.umma(%tup_70, %tup_72, %tmem_ptr, %120, %114) {num_cta = 1 : i32, scale = 0 : i32, a_type = f16} : (!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, !cute.ptr<f32, tmem, align<16>>, i32, i1) -> ()
              } {llvm.loop_annotation = #loop_annotation}
            } {llvm.loop_annotation = #loop_annotation}
          } {llvm.loop_annotation = #loop_annotation}
          %121 = cute_nvgpu.atom.set_value(%111, %true : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_f16_f16_f32_128x256x16_
          %coord_73 = cute.make_coord(%arg11) : (i32) -> !cute.coord<"(_,_,2,?)">
          %idx_74 = cute.crd2idx(%coord_73, %4) : (!cute.coord<"(_,_,2,?)">, !cute.layout<"(1,1,4,4):(0,0,2,1024)">) -> !cute.int_tuple<"?{div=4}">
          %tup_75 = cute.add_offset(%ummaSmemDesc, %idx_74) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=4}">) -> !cute_nvgpu.smem_desc
          %idx_76 = cute.crd2idx(%coord_73, %3) : (!cute.coord<"(_,_,2,?)">, !cute.layout<"(1,1,4,4):(0,0,2,2048)">) -> !cute.int_tuple<"?{div=4}">
          %tup_77 = cute.add_offset(%ummaSmemDesc_40, %idx_76) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=4}">) -> !cute_nvgpu.smem_desc
          %122 = cute_nvgpu.atom.get_value(%121 : !mma_f16_f16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : i1
          %123 = cute_nvgpu.atom.get_value(%121 : !mma_f16_f16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : i1
          %124 = cute_nvgpu.atom.get_value(%121 : !mma_f16_f16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : i1
          %125 = arith.extui %122 : i1 to i32
          %126 = arith.extui %123 : i1 to i32
          %127 = arith.shli %125, %c13_i32 : i32
          %128 = arith.shli %126, %c14_i32 : i32
          %129 = arith.ori %127, %c138412048_i32 : i32
          %130 = arith.ori %129, %128 : i32
          scf.for %arg14 = %c0_i32 to %90 step %c1_i32  : i32 {
            scf.for %arg15 = %c0_i32 to %90 step %c1_i32  : i32 {
              scf.for %arg16 = %c0_i32 to %90 step %c1_i32  : i32 {
                cute_nvgpu.arch.mma.SM100.umma(%tup_75, %tup_77, %tmem_ptr, %130, %124) {num_cta = 1 : i32, scale = 0 : i32, a_type = f16} : (!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, !cute.ptr<f32, tmem, align<16>>, i32, i1) -> ()
              } {llvm.loop_annotation = #loop_annotation}
            } {llvm.loop_annotation = #loop_annotation}
          } {llvm.loop_annotation = #loop_annotation}
          %131 = cute_nvgpu.atom.set_value(%121, %true : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_f16_f16_f32_128x256x16_
          %coord_78 = cute.make_coord(%arg11) : (i32) -> !cute.coord<"(_,_,3,?)">
          %idx_79 = cute.crd2idx(%coord_78, %4) : (!cute.coord<"(_,_,3,?)">, !cute.layout<"(1,1,4,4):(0,0,2,1024)">) -> !cute.int_tuple<"?{div=2}">
          %tup_80 = cute.add_offset(%ummaSmemDesc, %idx_79) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
          %idx_81 = cute.crd2idx(%coord_78, %3) : (!cute.coord<"(_,_,3,?)">, !cute.layout<"(1,1,4,4):(0,0,2,2048)">) -> !cute.int_tuple<"?{div=2}">
          %tup_82 = cute.add_offset(%ummaSmemDesc_40, %idx_81) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
          %132 = cute_nvgpu.atom.get_value(%131 : !mma_f16_f16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : i1
          %133 = cute_nvgpu.atom.get_value(%131 : !mma_f16_f16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : i1
          %134 = cute_nvgpu.atom.get_value(%131 : !mma_f16_f16_f32_128x256x16_) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : i1
          %135 = arith.extui %132 : i1 to i32
          %136 = arith.extui %133 : i1 to i32
          %137 = arith.shli %135, %c13_i32 : i32
          %138 = arith.shli %136, %c14_i32 : i32
          %139 = arith.ori %137, %c138412048_i32 : i32
          %140 = arith.ori %139, %138 : i32
          scf.for %arg14 = %c0_i32 to %90 step %c1_i32  : i32 {
            scf.for %arg15 = %c0_i32 to %90 step %c1_i32  : i32 {
              scf.for %arg16 = %c0_i32 to %90 step %c1_i32  : i32 {
                cute_nvgpu.arch.mma.SM100.umma(%tup_80, %tup_82, %tmem_ptr, %140, %134) {num_cta = 1 : i32, scale = 0 : i32, a_type = f16} : (!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, !cute.ptr<f32, tmem, align<16>>, i32, i1) -> ()
              } {llvm.loop_annotation = #loop_annotation}
            } {llvm.loop_annotation = #loop_annotation}
          } {llvm.loop_annotation = #loop_annotation}
          %141 = cute_nvgpu.atom.set_value(%131, %true : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_f16_f16_f32_128x256x16_
          %142 = nvvm.elect.sync -> i1
          scf.if %142 {
            %ptr_83 = cute.add_offset(%ptr_6, %int_tuple_61) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
            %143 = builtin.unrealized_conversion_cast %ptr_83 : !cute.ptr<i64, smem> to !llvm.ptr<3>
            nvvm.tcgen05.commit.arrive %143 : !llvm.ptr<3>
          }
          scf.yield %95#2, %95#0, %95#1, %98, %100, %101, %141 : i32, i32, i32, i32, i32, i32, !mma_f16_f16_f32_128x256x16_
        }
        %92 = nvvm.elect.sync -> i1
        scf.if %92 {
          %dyn_61 = cute.derefine(%iter_7) : !cute.ptr<i64, smem, align<64>> to !cute.ptr<i64, smem>
          %93 = builtin.unrealized_conversion_cast %dyn_61 : !cute.ptr<i64, smem> to !llvm.ptr<3>
          nvvm.tcgen05.commit.arrive %93 : !llvm.ptr<3>
        }
      }
      scf.if %44 {
        cute_nvgpu.arch.sm100.relinquish_tmem_alloc_permit [ cta_1]
      }
      %dyn = cute.derefine(%iter_7) : !cute.ptr<i64, smem, align<64>> to !cute.ptr<i64, smem>
      %79 = builtin.unrealized_conversion_cast %dyn : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.try_wait.parity.shared %79, %c0_i32, %c10000000_i32 : !llvm.ptr<3>, i32, i32
      %iter_59 = cute.get_iter(%rmem) : !memref_rmem_f32_
      %80 = cute.get_scalars(%20) : !cute.int_tuple<"1">
      %81 = builtin.unrealized_conversion_cast %iter_59 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
      %iter_60 = cute.get_iter(%rmem_58) : !memref_rmem_f16_
      %82 = cute.get_scalars(%17) : !cute.int_tuple<"4">
      scf.for %arg6 = %c0_i32 to %c4_i32 step %c1_i32  : i32 {
        %coord_61 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,_,?)">
        %idx_62 = cute.crd2idx(%coord_61, %2) : (!cute.coord<"(_,_,?)">, !cute.layout<"(((64,32),1),1,((1,4),1,1)):(((1,65536),0),0,((0,64),0,0))">) -> !cute.int_tuple<"?{div=64}">
        %ptr_63 = cute.add_offset(%ptr_54, %idx_62) : (!cute.ptr<f32, tmem, align<16>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<f32, tmem, align<16>>
        scf.for %arg7 = %c0_i32 to %80 step %c1_i32  : i32 {
          %86 = "cute_nvgpu.arch.copy.SM100.tmem_load"(%ptr_63) <{num_b = 32 : i32, num_dp = 32 : i32, num_rep = 64 : i32}> : (!cute.ptr<f32, tmem, align<16>>) -> vector<64xi32>
          llvm.store %86, %81 : vector<64xi32>, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %84 = cute.memref.load_vec %rmem : !memref_rmem_f32_
        %85 = arith.truncf %84 : vector<64xf32> to vector<64xf16>
        cute.memref.store_vec %85, %rmem_58 : !memref_rmem_f16_
        %idx_64 = cute.crd2idx(%coord_61, %1) : (!cute.coord<"(_,_,?)">, !cute.layout<"((64,1),1,((1,4),1,1)):((1,0),0,((0,64),0,0))">) -> !cute.int_tuple<"?{div=64}">
        %ptr_65 = cute.add_offset(%ptr_57, %idx_64) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{div=64}">) -> !cute.ptr<f16, gmem, align<32>>
        scf.for %arg7 = %c0_i32 to %82 step %c1_i32  : i32 {
          %coord_66 = cute.make_coord(%arg7) : (i32) -> !cute.coord<"(_,?)">
          %idx_67 = cute.crd2idx(%coord_66, %0) : (!cute.coord<"(_,?)">, !cute.layout<"(16,(4)):(1,(16))">) -> !cute.int_tuple<"?{div=16}">
          %ptr_68 = cute.add_offset(%iter_60, %idx_67) : (!cute.ptr<f16, rmem, align<32>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<f16, rmem, align<32>>
          %ptr_69 = cute.add_offset(%ptr_65, %idx_67) : (!cute.ptr<f16, gmem, align<32>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<f16, gmem, align<32>>
          %86 = builtin.unrealized_conversion_cast %ptr_68 : !cute.ptr<f16, rmem, align<32>> to !llvm.ptr
          %87 = builtin.unrealized_conversion_cast %ptr_69 : !cute.ptr<f16, gmem, align<32>> to !llvm.ptr<1>
          %88 = llvm.load %86 {alignment = 32 : i64} : !llvm.ptr -> vector<16xf16>
          llvm.store %88, %87 {alignment = 32 : i64} : vector<16xf16>, !llvm.ptr<1>
        } {llvm.loop_annotation = #loop_annotation}
      }
      %83 = builtin.unrealized_conversion_cast %ptr_8 : !cute.ptr<i64, smem> to !llvm.ptr<3>
      nvvm.mbarrier.txn %83, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>} : !llvm.ptr<3>, i32
      nvvm.barrier id = %c1_i32
      scf.if %44 {
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
