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
      %c63_i32 = arith.constant 63 : i32
      %c127_i32 = arith.constant 127 : i32
      %0 = cute.static : !cute.layout<"(((32,128),1),(1,4)):(((1@0,1@1),0),(0,32@0))">
      %1 = cute.static : !cute.layout<"((4096,1),(1,4)):((1,0),(0,4096))">
      %2 = cute.static : !cute.int_tuple<"24">
      %3 = cute.static : !cute.int_tuple<"8">
      %4 = cute.static : !cute.layout<"((1,32),1,1,(1,4)):((0,1),0,0,(0,4096))">
      %5 = cute.static : !cute.layout<"(((32,32),1),1,1,(1,4)):(((1,65536),0),0,0,(0,32))">
      %6 = cute.static : !cute.layout<"(((32,32),1),1,1,1,4,2):(((1,65536),0),0,0,0,32,128)">
      %7 = cute.static : !cute.stride<"(((1@0,1@1),0),0,32@0,128@1,128@0,1@2)">
      %8 = cute.static : !cute.stride<"((1@1,1@0),0,32@0,128@1,128@0,1@2)">
      %9 = cute.static : !cute.stride<"(1@1,1@0,0,32@0,128@1,128@0,1@2)">
      %c1024_i32 = arith.constant 1024 : i32
      %c2097152_i32 = arith.constant 2097152 : i32
      %c256_i32 = arith.constant 256 : i32
      %c14_i32 = arith.constant 14 : i32
      %c13_i32 = arith.constant 13 : i32
      %c136314896_i32 = arith.constant 136314896 : i32
      %10 = cute.static : !cute.layout<"(1,1,4,6):(0,0,2,1024)">
      %11 = cute.static : !cute.layout<"((128,128),1,1,2):((65536,1),0,0,128)">
      %c3_i32 = arith.constant 3 : i32
      %12 = cute.static : !cute.layout<"((8192,1),6):((1,0),8192)">
      %c32768_i32 = arith.constant 32768 : i32
      %c10000000_i32 = arith.constant 10000000 : i32
      %13 = cute.static : !cute.stride<"(((1@0,1@1),0),64@0)">
      %true = arith.constant true
      %c160_i32 = arith.constant 160 : i32
      %14 = cute.static : !cute.layout<"(2,3,2):(6,2,1)">
      %15 = cute.static : !cute.coord<"2">
      %c31_i32 = arith.constant 31 : i32
      %c16_i32 = arith.constant 16 : i32
      %c8_i32 = arith.constant 8 : i32
      %16 = cute.static : !cute.coord<"1">
      %17 = cute.static : !cute.coord<"0">
      %18 = cute.static : !cute.layout<"(2,4):(4,1)">
      %c-1_i32 = arith.constant -1 : i32
      %19 = cute.static : !cute.layout<"(1,3,16):(48,16,1)">
      %c192_i32 = arith.constant 192 : i32
      %20 = cute.static : !cute.stride<"(((1@0,1@1),0),128@1,64@0,1@2)">
      %21 = cute.static : !cute.stride<"(((1@1,1@0),0,16@0),128@1,64@0,1@2)">
      %22 = cute.static : !cute.stride<"((1@1,1@0),0,0,128@1,128@0,1@2)">
      %23 = cute.static : !cute.stride<"((1@1,1@0),0,16@0,128@1,64@0,1@2)">
      %24 = cute.static : !cute.stride<"(1@1,1@0,128@1,128@0,1@2)">
      %25 = cute.static : !cute.stride<"((1@1,1@0),(128@1,128@0,1@2))">
      %26 = cute.static : !cute.int_tuple<"(0,0,0)">
      %27 = cute.static : !cute.stride<"(1@1,1@0,128@1,64@0,1@2)">
      %28 = cute.static : !cute.stride<"((1@1,1@0),(128@1,64@0,1@2))">
      %c64_i32 = arith.constant 64 : i32
      %c128_i32 = arith.constant 128 : i32
      %false = arith.constant false
      %c2_i32 = arith.constant 2 : i32
      %c4_i32 = arith.constant 4 : i32
      %c6_i32 = arith.constant 6 : i32
      %29 = cute.static : !cute.int_tuple<"16">
      %30 = cute.static : !cute.int_tuple<"132096">
      %31 = cute.static : !cute.int_tuple<"33792">
      %32 = cute.static : !cute.int_tuple<"1024">
      %33 = cute.static : !cute.int_tuple<"520">
      %34 = cute.static : !cute.int_tuple<"496">
      %35 = cute.static : !cute.int_tuple<"480">
      %36 = cute.static : !cute.int_tuple<"432">
      %37 = cute.static : !cute.int_tuple<"384">
      %c0_i32 = arith.constant 0 : i32
      %c5_i32 = arith.constant 5 : i32
      %c32_i32 = arith.constant 32 : i32
      %c1_i32 = arith.constant 1 : i32
      %38 = cute.static : !cute.int_tuple<"1">
      %int_tuple = cute.make_int_tuple(%arg7) : (i32) -> !cute.int_tuple<"(1,1,?)">
      %39 = cute.get_scalars(%int_tuple) <{only_dynamic}> : !cute.int_tuple<"(1,1,?)">
      %int_tuple_0 = cute.make_int_tuple(%39) : (i32) -> !cute.int_tuple<"(1,1,?)">
      %e0, %e1, %e2 = cute.get_leaves(%int_tuple_0) : !cute.int_tuple<"(1,1,?)">
      %shape = cute.make_shape(%e2) : (!cute.int_tuple<"?">) -> !cute.shape<"(1,1,?)">
      %lay = cute.make_layout(%shape) : !cute.layout<"(1,1,?):(0,0,1)">
      %40 = nvvm.read.ptx.sreg.tid.x range <i32, 0, 1024> : i32
      %41 = nvvm.read.ptx.sreg.tid.y range <i32, 0, 1024> : i32
      %42 = nvvm.read.ptx.sreg.tid.z range <i32, 0, 64> : i32
      %43 = nvvm.read.ptx.sreg.ntid.x range <i32, 1, 1024> : i32
      %44 = nvvm.read.ptx.sreg.ntid.y range <i32, 1, 1024> : i32
      %45 = arith.muli %41, %43 : i32
      %46 = arith.addi %40, %45 : i32
      %47 = arith.muli %42, %43 : i32
      %48 = arith.muli %47, %44 : i32
      %49 = arith.addi %46, %48 : i32
      %50 = arith.floordivsi %49, %c32_i32 : i32
      %51 = cute_nvgpu.arch.make_warp_uniform(%50) : i32
      %52 = arith.cmpi eq, %51, %c5_i32 : i32
      scf.if %52 {
        cute_nvgpu.prefetch_tma_desc(%arg1) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>) -> ()
        cute_nvgpu.prefetch_tma_desc(%arg3) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>) -> ()
        cute_nvgpu.prefetch_tma_desc(%arg5) : (!cute_nvgpu.atom.non_exec_tiled_tma_store<f16, copy_bits = 65536, tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>) -> ()
      }
      %53 = nvvm.read.ptx.sreg.ctaid.x range <i32, 0, 2147483647> : i32
      %54 = nvvm.read.ptx.sreg.ctaid.y range <i32, 0, 65535> : i32
      %55 = nvvm.read.ptx.sreg.ctaid.z range <i32, 0, 65535> : i32
      %smem_ptr = cute_nvgpu.arch.get_dyn_smem() : !cute.ptr<i8, smem, align<1024>>
      %ptr = cute.add_offset(%smem_ptr, %37) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"384">) -> !cute.ptr<i8, smem, align<128>>
      %ptr_1 = cute.add_offset(%smem_ptr, %36) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"432">) -> !cute.ptr<i8, smem, align<16>>
      %ptr_2 = cute.add_offset(%smem_ptr, %35) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"480">) -> !cute.ptr<i8, smem, align<32>>
      %ptr_3 = cute.add_offset(%smem_ptr, %34) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"496">) -> !cute.ptr<i8, smem, align<16>>
      %ptr_4 = cute.add_offset(%smem_ptr, %33) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"520">) -> !cute.ptr<i8, smem, align<8>>
      %iter = cute.recast_iter(%ptr_4) : !cute.ptr<i8, smem, align<8>> to !cute.ptr<i32, smem, align<8>>
      %ptr_5 = cute.add_offset(%smem_ptr, %32) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"1024">) -> !cute.ptr<i8, smem, align<1024>>
      %ptr_6 = cute.add_offset(%smem_ptr, %31) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"33792">) -> !cute.ptr<i8, smem, align<1024>>
      %ptr_7 = cute.add_offset(%smem_ptr, %30) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"132096">) -> !cute.ptr<i8, smem, align<1024>>
      %iter_8 = cute.recast_iter(%smem_ptr) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<i64, smem, align<1024>>
      %ptr_9 = cute.add_offset(%iter_8, %29) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"16">) -> !cute.ptr<i64, smem, align<128>>
      %int_tuple_10 = cute.make_int_tuple() : () -> !cute.int_tuple<"32">
      %ptr_11 = cute.add_offset(%iter_8, %int_tuple_10) : (!cute.ptr<i64, smem, align<1024>>, !cute.int_tuple<"32">) -> !cute.ptr<i64, smem, align<256>>
      %dyn = cute.derefine(%ptr_11) : !cute.ptr<i64, smem, align<256>> to !cute.ptr<i64, smem, align<128>>
      %iter_12 = cute.recast_iter(%ptr) : !cute.ptr<i8, smem, align<128>> to !cute.ptr<i64, smem, align<128>>
      %iter_13 = cute.recast_iter(%ptr_1) : !cute.ptr<i8, smem, align<16>> to !cute.ptr<i64, smem, align<16>>
      %iter_14 = cute.recast_iter(%ptr_2) : !cute.ptr<i8, smem, align<32>> to !cute.ptr<i64, smem, align<32>>
      %iter_15 = cute.recast_iter(%ptr_3) : !cute.ptr<i8, smem, align<16>> to !cute.ptr<i64, smem, align<16>>
      %56 = arith.cmpi eq, %51, %c0_i32 : i32
      scf.if %56 {
        scf.for %arg15 = %c0_i32 to %c6_i32 step %c1_i32  : i32 {
          %92 = nvvm.elect.sync -> i1
          scf.if %92 {
            %int_tuple_59 = cute.make_int_tuple(%arg15) : (i32) -> !cute.int_tuple<"?">
            %ptr_60 = cute.add_offset(%iter_12, %int_tuple_59) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
            %93 = builtin.unrealized_conversion_cast %ptr_60 : !cute.ptr<i64, smem> to !llvm.ptr<3>
            nvvm.mbarrier.init.shared %93, %c1_i32 : !llvm.ptr<3>, i32
            %ptr_61 = cute.add_offset(%iter_13, %int_tuple_59) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
            %94 = builtin.unrealized_conversion_cast %ptr_61 : !cute.ptr<i64, smem> to !llvm.ptr<3>
            nvvm.mbarrier.init.shared %94, %c1_i32 : !llvm.ptr<3>, i32
          }
        }
      }
      %57 = arith.cmpi eq, %51, %c4_i32 : i32
      scf.if %57 {
        scf.for %arg15 = %c0_i32 to %c2_i32 step %c1_i32  : i32 {
          %92 = nvvm.elect.sync -> i1
          scf.if %92 {
            %int_tuple_59 = cute.make_int_tuple(%arg15) : (i32) -> !cute.int_tuple<"?">
            %ptr_60 = cute.add_offset(%iter_14, %int_tuple_59) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
            %93 = builtin.unrealized_conversion_cast %ptr_60 : !cute.ptr<i64, smem> to !llvm.ptr<3>
            nvvm.mbarrier.init.shared %93, %c1_i32 : !llvm.ptr<3>, i32
            %ptr_61 = cute.add_offset(%iter_15, %int_tuple_59) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
            %94 = builtin.unrealized_conversion_cast %ptr_61 : !cute.ptr<i64, smem> to !llvm.ptr<3>
            nvvm.mbarrier.init.shared %94, %c4_i32 : !llvm.ptr<3>, i32
          }
        }
      }
      nvvm.fence.mbarrier.init
      %iter_16 = cute.recast_iter(%ptr_5) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<f16, smem, align<1024>, S<2,4,3>>
      %iter_17 = cute.recast_iter(%ptr_6) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<f16, smem, align<1024>, S<3,4,3>>
      %iter_18 = cute.recast_iter(%ptr_7) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<f16, smem, align<1024>, S<3,4,3>>
      %lay_19 = cute.get_layout(%arg2) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">
      %58:3 = cute.get_scalars(%lay_19) <{only_dynamic}> : !cute.layout<"(?,?,?):(1@1,1@0,1@2)">
      %59 = arith.ceildivsi %58#0, %c128_i32 : i32
      %60 = arith.ceildivsi %58#1, %c64_i32 : i32
      %shape_20 = cute.make_shape(%59, %60, %58#2) : (i32, i32, i32) -> !cute.shape<"((128,64),(?,?,?))">
      %lay_21 = cute.make_layout(%shape_20, %28) : !cute.layout<"((128,64),(?,?,?)):((1@1,1@0),(128@1,64@0,1@2))">
      %61:3 = cute.get_scalars(%lay_21) <{only_dynamic}> : !cute.layout<"((128,64),(?,?,?)):((1@1,1@0),(128@1,64@0,1@2))">
      %shape_22 = cute.make_shape(%61#0, %61#1, %61#2) : (i32, i32, i32) -> !cute.shape<"(128,64,?,?,?)">
      %lay_23 = cute.make_layout(%shape_22, %27) : !cute.layout<"(128,64,?,?,?):(1@1,1@0,128@1,64@0,1@2)">
      %lay_24 = cute.get_layout(%arg4) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">
      %62:3 = cute.get_scalars(%lay_24) <{only_dynamic}> : !cute.layout<"(?,?,?):(1@1,1@0,1@2)">
      %63 = arith.ceildivsi %62#0, %c128_i32 : i32
      %64 = arith.ceildivsi %62#1, %c64_i32 : i32
      %shape_25 = cute.make_shape(%63, %64, %62#2) : (i32, i32, i32) -> !cute.shape<"((128,64),(?,?,?))">
      %lay_26 = cute.make_layout(%shape_25, %28) : !cute.layout<"((128,64),(?,?,?)):((1@1,1@0),(128@1,64@0,1@2))">
      %65:3 = cute.get_scalars(%lay_26) <{only_dynamic}> : !cute.layout<"((128,64),(?,?,?)):((1@1,1@0),(128@1,64@0,1@2))">
      %shape_27 = cute.make_shape(%65#0, %65#1, %65#2) : (i32, i32, i32) -> !cute.shape<"(128,64,?,?,?)">
      %lay_28 = cute.make_layout(%shape_27, %27) : !cute.layout<"(128,64,?,?,?):(1@1,1@0,128@1,64@0,1@2)">
      %lay_29 = cute.get_layout(%arg6) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">
      %66:3 = cute.get_scalars(%lay_29) <{only_dynamic}> : !cute.layout<"(?,?,?):(1@1,1@0,1@2)">
      %67 = arith.ceildivsi %66#0, %c128_i32 : i32
      %68 = arith.ceildivsi %66#1, %c128_i32 : i32
      %shape_30 = cute.make_shape(%67, %68, %66#2) : (i32, i32, i32) -> !cute.shape<"((128,128),(?,?,?))">
      %lay_31 = cute.make_layout(%shape_30, %25) : !cute.layout<"((128,128),(?,?,?)):((1@1,1@0),(128@1,128@0,1@2))">
      %69:3 = cute.get_scalars(%lay_31) <{only_dynamic}> : !cute.layout<"((128,128),(?,?,?)):((1@1,1@0),(128@1,128@0,1@2))">
      %shape_32 = cute.make_shape(%69#0, %69#1, %69#2) : (i32, i32, i32) -> !cute.shape<"(128,128,?,?,?)">
      %lay_33 = cute.make_layout(%shape_32, %24) : !cute.layout<"(128,128,?,?,?):(1@1,1@0,128@1,128@0,1@2)">
      %70:3 = cute.get_scalars(%lay_23) <{only_dynamic}> : !cute.layout<"(128,64,?,?,?):(1@1,1@0,128@1,64@0,1@2)">
      %shape_34 = cute.make_shape(%70#0, %70#1, %70#2) : (i32, i32, i32) -> !cute.shape<"((128,16),1,4,?,?,?)">
      %lay_35 = cute.make_layout(%shape_34, %23) : !cute.layout<"((128,16),1,4,?,?,?):((1@1,1@0),0,16@0,128@1,64@0,1@2)">
      %71:3 = cute.get_scalars(%lay_28) <{only_dynamic}> : !cute.layout<"(128,64,?,?,?):(1@1,1@0,128@1,64@0,1@2)">
      %shape_36 = cute.make_shape(%71#0, %71#1, %71#2) : (i32, i32, i32) -> !cute.shape<"((128,16),1,4,?,?,?)">
      %lay_37 = cute.make_layout(%shape_36, %23) : !cute.layout<"((128,16),1,4,?,?,?):((1@1,1@0),0,16@0,128@1,64@0,1@2)">
      %72:3 = cute.get_scalars(%lay_33) <{only_dynamic}> : !cute.layout<"(128,128,?,?,?):(1@1,1@0,128@1,128@0,1@2)">
      %shape_38 = cute.make_shape(%72#0, %72#1, %72#2) : (i32, i32, i32) -> !cute.shape<"((128,128),1,1,?,?,?)">
      %lay_39 = cute.make_layout(%shape_38, %22) : !cute.layout<"((128,128),1,1,?,?,?):((1@1,1@0),0,0,128@1,128@0,1@2)">
      %73:3 = cute.get_scalars(%lay_35) <{only_dynamic}> : !cute.layout<"((128,16),1,4,?,?,?):((1@1,1@0),0,16@0,128@1,64@0,1@2)">
      %shape_40 = cute.make_shape(%73#0, %73#1, %73#2) : (i32, i32, i32) -> !cute.shape<"(((128,16),1,4),?,?,?)">
      %lay_41 = cute.make_layout(%shape_40, %21) : !cute.layout<"(((128,16),1,4),?,?,?):(((1@1,1@0),0,16@0),128@1,64@0,1@2)">
      %74:3 = cute.get_scalars(%lay_41) <{only_dynamic}> : !cute.layout<"(((128,16),1,4),?,?,?):(((1@1,1@0),0,16@0),128@1,64@0,1@2)">
      %shape_42 = cute.make_shape(%74#0, %74#1, %74#2) : (i32, i32, i32) -> !cute.shape<"(((64,128),1),?,?,?)">
      %lay_43 = cute.make_layout(%shape_42, %20) : !cute.layout<"(((64,128),1),?,?,?):(((1@0,1@1),0),128@1,64@0,1@2)">
      %75:3 = cute.get_scalars(%lay_37) <{only_dynamic}> : !cute.layout<"((128,16),1,4,?,?,?):((1@1,1@0),0,16@0,128@1,64@0,1@2)">
      %shape_44 = cute.make_shape(%75#0, %75#1, %75#2) : (i32, i32, i32) -> !cute.shape<"(((128,16),1,4),?,?,?)">
      %lay_45 = cute.make_layout(%shape_44, %21) : !cute.layout<"(((128,16),1,4),?,?,?):(((1@1,1@0),0,16@0),128@1,64@0,1@2)">
      %76:3 = cute.get_scalars(%lay_45) <{only_dynamic}> : !cute.layout<"(((128,16),1,4),?,?,?):(((1@1,1@0),0,16@0),128@1,64@0,1@2)">
      %shape_46 = cute.make_shape(%76#0, %76#1, %76#2) : (i32, i32, i32) -> !cute.shape<"(((64,128),1),?,?,?)">
      %lay_47 = cute.make_layout(%shape_46, %20) : !cute.layout<"(((64,128),1),?,?,?):(((1@0,1@1),0),128@1,64@0,1@2)">
      %ummaSmemDesc = cute_nvgpu.make_umma_smem_desc(%iter_17 : !cute.ptr<f16, smem, align<1024>, S<3,4,3>>) layout = <"((128,16),1,4,6):((64,1),0,16,8192)">, major = <k> -> !cute_nvgpu.smem_desc
      %ummaSmemDesc_48 = cute_nvgpu.make_umma_smem_desc(%iter_18 : !cute.ptr<f16, smem, align<1024>, S<3,4,3>>) layout = <"((128,16),1,4,6):((64,1),0,16,8192)">, major = <k> -> !cute_nvgpu.smem_desc
      nvvm.barrier id = %c1_i32 number_of_threads = %c192_i32
      %77 = nvvm.read.ptx.sreg.nctaid.x range <i32, 1, 2147483647> : i32
      %78 = nvvm.read.ptx.sreg.nctaid.y range <i32, 1, 65535> : i32
      %79 = nvvm.read.ptx.sreg.nctaid.z range <i32, 1, 65535> : i32
      %80 = arith.muli %55, %78 : i32
      %81 = arith.muli %80, %77 : i32
      %82 = arith.muli %54, %77 : i32
      %83 = arith.addi %81, %82 : i32
      %84 = arith.addi %83, %53 : i32
      %coord = cute.make_coord(%84) : (i32) -> !cute.coord<"(?,0,_)">
      %idx = cute.crd2idx(%coord, %19) : (!cute.coord<"(?,0,_)">, !cute.layout<"(1,3,16):(48,16,1)">) -> !cute.int_tuple<"?{div=48}">
      %iter_49 = cute.get_iter(%arg14) : !memref_gmem_i64_1
      %ptr_50 = cute.add_offset(%iter_49, %idx) : (!cute.ptr<i64, gmem>, !cute.int_tuple<"?{div=48}">) -> !cute.ptr<i64, gmem>
      %85 = cute.ptrtoint(%ptr_50) : !cute.ptr<i64, gmem> to i64
      %iv = cute.assume(%85) : (i64) -> !cute.i64<divby 128>
      %86 = cute.inttoptr(%iv) : !cute.i64<divby 128> to !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, gmem, align<128>>
      %coord_51 = cute.make_coord(%84) : (i32) -> !cute.coord<"(?,1,_)">
      %idx_52 = cute.crd2idx(%coord_51, %19) : (!cute.coord<"(?,1,_)">, !cute.layout<"(1,3,16):(48,16,1)">) -> !cute.int_tuple<"?{div=16}">
      %ptr_53 = cute.add_offset(%iter_49, %idx_52) : (!cute.ptr<i64, gmem>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<i64, gmem>
      %87 = cute.ptrtoint(%ptr_53) : !cute.ptr<i64, gmem> to i64
      %iv_54 = cute.assume(%87) : (i64) -> !cute.i64<divby 128>
      %88 = cute.inttoptr(%iv_54) : !cute.i64<divby 128> to !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, gmem, align<128>>
      %coord_55 = cute.make_coord(%84) : (i32) -> !cute.coord<"(?,2,_)">
      %idx_56 = cute.crd2idx(%coord_55, %19) : (!cute.coord<"(?,2,_)">, !cute.layout<"(1,3,16):(48,16,1)">) -> !cute.int_tuple<"?{div=16}">
      %ptr_57 = cute.add_offset(%iter_49, %idx_56) : (!cute.ptr<i64, gmem>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<i64, gmem>
      %89 = cute.ptrtoint(%ptr_57) : !cute.ptr<i64, gmem> to i64
      %iv_58 = cute.assume(%89) : (i64) -> !cute.i64<divby 128>
      %90 = cute.inttoptr(%iv_58) : !cute.i64<divby 128> to !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, gmem, align<128>>
      scf.if %52 {
        %int_tuple_59 = cute.make_int_tuple(%77, %78, %79) : (i32, i32, i32) -> !cute.int_tuple<"(?,?,?)">
        %sz = cute.size(%int_tuple_59) : (!cute.int_tuple<"(?,?,?)">) -> !cute.int_tuple<"?">
        %e0_60 = cute.get_leaves(%sz) : !cute.int_tuple<"?">
        %div = cute.tuple_div(%e0_60, %38) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
        %92 = cute.get_scalars(%div) : !cute.int_tuple<"?">
        %sz_61 = cute.size(%lay) : (!cute.layout<"(1,1,?):(0,0,1)">) -> !cute.int_tuple<"?">
        %e0_62 = cute.get_leaves(%sz_61) : !cute.int_tuple<"?">
        %93 = cute.get_scalars(%e0_62) : !cute.int_tuple<"?">
        %94 = arith.cmpi sgt, %93, %55 : i32
        %95 = cute.fast_divmod.get_divisor(%arg8) : !cute.fast_divmod_divisor<32>
        %multiplier, %shift1, %shift2 = cute.fast_divmod.get_aux(%arg8) : !cute.fast_divmod_divisor<32> -> (i32, i8)
        %96 = arith.extui %shift1 : i8 to i32
        %97 = arith.extui %shift2 : i8 to i32
        %98 = nvvm.mul  hi %55, %multiplier : i32 -> i32
        %99 = arith.subi %55, %98 : i32
        %100 = arith.shrui %99, %96 : i32
        %101 = arith.addi %98, %100 : i32
        %102 = arith.shrui %101, %97 : i32
        %103 = arith.muli %102, %95 : i32
        %104 = arith.subi %55, %103 : i32
        %105 = cute.fast_divmod.get_divisor(%arg9) : !cute.fast_divmod_divisor<32>
        %multiplier_63, %shift1_64, %shift2_65 = cute.fast_divmod.get_aux(%arg9) : !cute.fast_divmod_divisor<32> -> (i32, i8)
        %106 = arith.extui %shift1_64 : i8 to i32
        %107 = arith.extui %shift2_65 : i8 to i32
        %108 = nvvm.mul  hi %104, %multiplier_63 : i32 -> i32
        %109 = arith.subi %104, %108 : i32
        %110 = arith.shrui %109, %106 : i32
        %111 = arith.addi %108, %110 : i32
        %112 = arith.shrui %111, %107 : i32
        %113 = arith.muli %112, %105 : i32
        %114 = arith.subi %104, %113 : i32
        %115 = cute.fast_divmod.get_divisor(%arg10) : !cute.fast_divmod_divisor<32>
        %multiplier_66, %shift1_67, %shift2_68 = cute.fast_divmod.get_aux(%arg10) : !cute.fast_divmod_divisor<32> -> (i32, i8)
        %116 = arith.extui %shift1_67 : i8 to i32
        %117 = arith.extui %shift2_68 : i8 to i32
        %118 = nvvm.mul  hi %112, %multiplier_66 : i32 -> i32
        %119 = arith.subi %112, %118 : i32
        %120 = arith.shrui %119, %116 : i32
        %121 = arith.addi %118, %120 : i32
        %122 = arith.shrui %121, %117 : i32
        %123 = arith.muli %122, %115 : i32
        %124 = arith.subi %112, %123 : i32
        %int_tuple_69 = cute.make_int_tuple(%114) : (i32) -> !cute.int_tuple<"?">
        %mul = cute.tuple_mul(%int_tuple_69, %38) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
        %125 = cute.get_scalars(%mul) : !cute.int_tuple<"?">
        %int_tuple_70 = cute.make_int_tuple(%124) : (i32) -> !cute.int_tuple<"?">
        %mul_71 = cute.tuple_mul(%int_tuple_70, %38) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
        %126 = cute.get_scalars(%mul_71) : !cute.int_tuple<"?">
        %int_tuple_72 = cute.make_int_tuple(%122) : (i32) -> !cute.int_tuple<"?">
        %mul_73 = cute.tuple_mul(%int_tuple_72, %38) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
        %127 = cute.get_scalars(%mul_73) : !cute.int_tuple<"?">
        %128:10 = scf.while (%arg15 = %false, %arg16 = %c0_i32, %arg17 = %125, %arg18 = %126, %arg19 = %127, %arg20 = %94, %arg21 = %c-1_i32, %arg22 = %c0_i32, %arg23 = %c0_i32, %arg24 = %55, %arg25 = %c0_i32) : (i1, i32, i32, i32, i32, i1, i32, i32, i32, i32, i32) -> (i1, i32, i32, i32, i32, i32, i32, i32, i32, i32) {
          scf.condition(%arg20) %arg15, %arg16, %arg17, %arg18, %arg19, %arg21, %arg22, %arg23, %arg24, %arg25 : i1, i32, i32, i32, i32, i32, i32, i32, i32, i32
        } do {
        ^bb0(%arg15: i1, %arg16: i32, %arg17: i32, %arg18: i32, %arg19: i32, %arg20: i32, %arg21: i32, %arg22: i32, %arg23: i32, %arg24: i32):
          %129 = nvvm.read.ptx.sreg.laneid range <i32, 0, 32> : i32
          %130 = arith.cmpi sge, %arg19, %arg22 : i32
          %131:3 = scf.while (%arg25 = %130, %arg26 = %arg21, %arg27 = %arg22, %arg28 = %arg22) : (i1, i32, i32, i32) -> (i32, i32, i32) {
            scf.condition(%arg25) %arg26, %arg27, %arg28 : i32, i32, i32
          } do {
          ^bb0(%arg25: i32, %arg26: i32, %arg27: i32):
            %182 = arith.addi %arg25, %129 : i32
            %183 = arith.cmpi slt, %182, %c2_i32 : i32
            %184 = scf.if %183 -> (i32) {
              %rmem_115 = cute.memref.alloca() : !memref_rmem_i32_
              %coord_116 = cute.make_coord(%182) : (i32) -> !cute.coord<"(?,_)">
              %idx_117 = cute.crd2idx(%coord_116, %18) : (!cute.coord<"(?,_)">, !cute.layout<"(2,4):(4,1)">) -> !cute.int_tuple<"?{div=4}">
              %iter_118 = cute.get_iter(%arg11) : !memref_gmem_i32_
              %ptr_119 = cute.add_offset(%iter_118, %idx_117) : (!cute.ptr<i32, gmem, align<16>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<i32, gmem, align<16>>
              %iter_120 = cute.get_iter(%rmem_115) : !memref_rmem_i32_
              %211 = cute.get_scalars(%38) : !cute.int_tuple<"1">
              scf.for %arg28 = %c0_i32 to %211 step %c1_i32  : i32 {
                %219 = builtin.unrealized_conversion_cast %ptr_119 : !cute.ptr<i32, gmem, align<16>> to !llvm.ptr<1>
                %220 = builtin.unrealized_conversion_cast %iter_120 : !cute.ptr<i32, rmem, align<32>> to !llvm.ptr
                %221 = llvm.load %219 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<4xi32>
                llvm.store %221, %220 {alignment = 16 : i64} : vector<4xi32>, !llvm.ptr
              } {llvm.loop_annotation = #loop_annotation}
              %212 = cute.memref.load(%rmem_115, %17) : (!memref_rmem_i32_, !cute.coord<"0">) -> i32
              %213 = arith.addi %212, %c127_i32 : i32
              %214 = arith.floordivsi %213, %c128_i32 : i32
              %215 = cute.memref.load(%rmem_115, %16) : (!memref_rmem_i32_, !cute.coord<"1">) -> i32
              %216 = arith.addi %215, %c127_i32 : i32
              %217 = arith.floordivsi %216, %c128_i32 : i32
              %218 = arith.muli %214, %217 : i32
              scf.yield %218 : i32
            } else {
              scf.yield %c0_i32 : i32
            }
            %185 = nvvm.shfl.sync  up %c-1_i32, %184, %c1_i32, %c0_i32 : i32 -> i32
            %186 = arith.cmpi sge, %129, %c1_i32 : i32
            %187 = scf.if %186 -> (i32) {
              %211 = arith.addi %184, %185 : i32
              scf.yield %211 : i32
            } else {
              scf.yield %184 : i32
            }
            %188 = nvvm.shfl.sync  up %c-1_i32, %187, %c2_i32, %c0_i32 : i32 -> i32
            %189 = arith.cmpi sge, %129, %c2_i32 : i32
            %190 = scf.if %189 -> (i32) {
              %211 = arith.addi %187, %188 : i32
              scf.yield %211 : i32
            } else {
              scf.yield %187 : i32
            }
            %191 = nvvm.shfl.sync  up %c-1_i32, %190, %c4_i32, %c0_i32 : i32 -> i32
            %192 = arith.cmpi sge, %129, %c4_i32 : i32
            %193 = scf.if %192 -> (i32) {
              %211 = arith.addi %190, %191 : i32
              scf.yield %211 : i32
            } else {
              scf.yield %190 : i32
            }
            %194 = nvvm.shfl.sync  up %c-1_i32, %193, %c8_i32, %c0_i32 : i32 -> i32
            %195 = arith.cmpi sge, %129, %c8_i32 : i32
            %196 = scf.if %195 -> (i32) {
              %211 = arith.addi %193, %194 : i32
              scf.yield %211 : i32
            } else {
              scf.yield %193 : i32
            }
            %197 = nvvm.shfl.sync  up %c-1_i32, %196, %c16_i32, %c0_i32 : i32 -> i32
            %198 = arith.cmpi sge, %129, %c16_i32 : i32
            %199 = scf.if %198 -> (i32) {
              %211 = arith.addi %196, %197 : i32
              scf.yield %211 : i32
            } else {
              scf.yield %196 : i32
            }
            %200 = arith.addi %199, %arg27 : i32
            %201 = arith.cmpi sge, %arg19, %200 : i32
            %202 = nvvm.vote.ballot.sync %c-1_i32, %201 : i32
            %203 = llvm.intr.ctpop(%202) : (i32) -> i32
            %204 = arith.cmpi eq, %203, %c32_i32 : i32
            %205 = arith.addi %203, %arg25 : i32
            %206 = arith.cmpi eq, %203, %c0_i32 : i32
            %207 = arith.cmpi eq, %206, %false : i1
            %208 = scf.if %207 -> (i32) {
              %211 = arith.subi %203, %c1_i32 : i32
              %212 = nvvm.shfl.sync  idx %c-1_i32, %200, %211, %c31_i32 : i32 -> i32
              scf.yield %212 : i32
            } else {
              scf.yield %arg27 : i32
            }
            %209 = arith.select %204, %c31_i32, %203 : i32
            %210 = nvvm.shfl.sync  idx %c-1_i32, %200, %209, %c31_i32 : i32 -> i32
            scf.yield %204, %205, %208, %210 : i1, i32, i32, i32
          }
          %rmem = cute.memref.alloca() : !memref_rmem_i32_
          %coord_74 = cute.make_coord(%131#0) : (i32) -> !cute.coord<"(?,_)">
          %idx_75 = cute.crd2idx(%coord_74, %18) : (!cute.coord<"(?,_)">, !cute.layout<"(2,4):(4,1)">) -> !cute.int_tuple<"?{div=4}">
          %iter_76 = cute.get_iter(%arg11) : !memref_gmem_i32_
          %ptr_77 = cute.add_offset(%iter_76, %idx_75) : (!cute.ptr<i32, gmem, align<16>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<i32, gmem, align<16>>
          %iter_78 = cute.get_iter(%rmem) : !memref_rmem_i32_
          %132 = cute.get_scalars(%38) : !cute.int_tuple<"1">
          scf.for %arg25 = %c0_i32 to %132 step %c1_i32  : i32 {
            %182 = builtin.unrealized_conversion_cast %ptr_77 : !cute.ptr<i32, gmem, align<16>> to !llvm.ptr<1>
            %183 = builtin.unrealized_conversion_cast %iter_78 : !cute.ptr<i32, rmem, align<32>> to !llvm.ptr
            %184 = llvm.load %182 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<4xi32>
            llvm.store %184, %183 {alignment = 16 : i64} : vector<4xi32>, !llvm.ptr
          } {llvm.loop_annotation = #loop_annotation}
          %133 = arith.subi %arg19, %131#1 : i32
          %134 = cute.memref.load(%rmem, %17) : (!memref_rmem_i32_, !cute.coord<"0">) -> i32
          %135 = cute.memref.load(%rmem, %16) : (!memref_rmem_i32_, !cute.coord<"1">) -> i32
          %136 = cute.memref.load(%rmem, %15) : (!memref_rmem_i32_, !cute.coord<"2">) -> i32
          %int_tuple_79 = cute.make_int_tuple(%134, %135, %136) : (i32, i32, i32) -> !cute.int_tuple<"(?,?,?)">
          %137:3 = cute.get_scalars(%int_tuple_79) <{only_dynamic}> : !cute.int_tuple<"(?,?,?)">
          %138 = arith.ceildivsi %137#0, %c128_i32 : i32
          %139 = arith.ceildivsi %137#1, %c128_i32 : i32
          %140 = arith.ceildivsi %137#2, %c64_i32 : i32
          %int_tuple_80 = cute.make_int_tuple(%138, %139, %140) : (i32, i32, i32) -> !cute.int_tuple<"(?,?,?)">
          %e0_81, %e1_82, %e2_83 = cute.get_leaves(%int_tuple_80) : !cute.int_tuple<"(?,?,?)">
          %141 = cute.get_scalars(%e2_83) : !cute.int_tuple<"?">
          %shape_84 = cute.make_shape(%e0_81, %e1_82) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.shape<"(?,?)">
          %lay_85 = cute.make_layout(%shape_84) : !cute.layout<"(?,?):(1,?)">
          %142 = cute.get_hier_coord(%133, %lay_85) : (i32, !cute.layout<"(?,?):(1,?)">) -> !cute.coord<"(?,?)">
          %e0_86, %e1_87 = cute.get_leaves(%142) : !cute.coord<"(?,?)">
          %itup = cute.to_int_tuple(%e0_86) : !cute.coord<"?"> to !cute.int_tuple<"?">
          %itup_88 = cute.to_int_tuple(%e1_87) : !cute.coord<"?"> to !cute.int_tuple<"?">
          %mul_89 = cute.tuple_mul(%itup, %38) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
          %int_tuple_90 = cute.make_int_tuple(%arg17) : (i32) -> !cute.int_tuple<"?">
          %tup = cute.add_offset(%mul_89, %int_tuple_90) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.int_tuple<"?">
          %mul_91 = cute.tuple_mul(%itup_88, %38) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
          %int_tuple_92 = cute.make_int_tuple(%arg18) : (i32) -> !cute.int_tuple<"?">
          %tup_93 = cute.add_offset(%mul_91, %int_tuple_92) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.int_tuple<"?">
          %143 = arith.cmpi ne, %131#0, %arg20 : i32
          %144 = scf.if %143 -> (i1) {
            %coord_115 = cute.make_coord(%131#0) : (i32) -> !cute.coord<"(?,0)">
            %182 = cute.memref.load(%arg13, %coord_115) : (!memref_gmem_i64_, !cute.coord<"(?,0)">) -> i64
            %iv_116 = cute.assume(%182) : (i64) -> !cute.i64<divby 16>
            %183 = cute.inttoptr(%iv_116) : !cute.i64<divby 16> to !cute.ptr<f16, gmem, align<16>>
            %coord_117 = cute.make_coord(%131#0) : (i32) -> !cute.coord<"(?,0,_)">
            %idx_118 = cute.crd2idx(%coord_117, %14) : (!cute.coord<"(?,0,_)">, !cute.layout<"(2,3,2):(6,2,1)">) -> !cute.int_tuple<"?{div=6}">
            %iter_119 = cute.get_iter(%arg12) : !memref_gmem_i32_1
            %ptr_120 = cute.add_offset(%iter_119, %idx_118) : (!cute.ptr<i32, gmem, align<16>>, !cute.int_tuple<"?{div=6}">) -> !cute.ptr<i32, gmem, align<8>>
            %rmem_121 = cute.memref.alloca() : !memref_rmem_i32_1
            %iter_122 = cute.get_iter(%rmem_121) : !memref_rmem_i32_1
            scf.for %arg25 = %c0_i32 to %132 step %c1_i32  : i32 {
              %192 = builtin.unrealized_conversion_cast %ptr_120 : !cute.ptr<i32, gmem, align<8>> to !llvm.ptr<1>
              %193 = builtin.unrealized_conversion_cast %iter_122 : !cute.ptr<i32, rmem, align<32>> to !llvm.ptr
              %194 = llvm.load %192 {alignment = 8 : i64} : !llvm.ptr<1> -> vector<2xi32>
              llvm.store %194, %193 {alignment = 8 : i64} : vector<2xi32>, !llvm.ptr
            } {llvm.loop_annotation = #loop_annotation}
            %184 = cute.memref.load(%rmem_121, %17) : (!memref_rmem_i32_1, !cute.coord<"0">) -> i32
            %185 = cute.memref.load(%rmem_121, %16) : (!memref_rmem_i32_1, !cute.coord<"1">) -> i32
            %shape_123 = cute.make_shape(%134, %136) : (i32, i32) -> !cute.shape<"(?,?,1)">
            %stride = cute.make_stride(%184, %185) : (i32, i32) -> !cute.stride<"(?,?,0)">
            %lay_124 = cute.make_layout(%shape_123, %stride) : !cute.layout<"(?,?,1):(?,?,0)">
            %view = cute.make_view(%183, %lay_124) : !memref_gmem_f16_
            %dyn_125 = cute.derefine(%view) : !memref_gmem_f16_ to !memref_gmem_f16_1
            %coord_126 = cute.make_coord(%131#0) : (i32) -> !cute.coord<"(?,1)">
            %186 = cute.memref.load(%arg13, %coord_126) : (!memref_gmem_i64_, !cute.coord<"(?,1)">) -> i64
            %iv_127 = cute.assume(%186) : (i64) -> !cute.i64<divby 16>
            %187 = cute.inttoptr(%iv_127) : !cute.i64<divby 16> to !cute.ptr<f16, gmem, align<16>>
            %coord_128 = cute.make_coord(%131#0) : (i32) -> !cute.coord<"(?,1,_)">
            %idx_129 = cute.crd2idx(%coord_128, %14) : (!cute.coord<"(?,1,_)">, !cute.layout<"(2,3,2):(6,2,1)">) -> !cute.int_tuple<"?{div=2}">
            %ptr_130 = cute.add_offset(%iter_119, %idx_129) : (!cute.ptr<i32, gmem, align<16>>, !cute.int_tuple<"?{div=2}">) -> !cute.ptr<i32, gmem, align<8>>
            %rmem_131 = cute.memref.alloca() : !memref_rmem_i32_1
            %iter_132 = cute.get_iter(%rmem_131) : !memref_rmem_i32_1
            scf.for %arg25 = %c0_i32 to %132 step %c1_i32  : i32 {
              %192 = builtin.unrealized_conversion_cast %ptr_130 : !cute.ptr<i32, gmem, align<8>> to !llvm.ptr<1>
              %193 = builtin.unrealized_conversion_cast %iter_132 : !cute.ptr<i32, rmem, align<32>> to !llvm.ptr
              %194 = llvm.load %192 {alignment = 8 : i64} : !llvm.ptr<1> -> vector<2xi32>
              llvm.store %194, %193 {alignment = 8 : i64} : vector<2xi32>, !llvm.ptr
            } {llvm.loop_annotation = #loop_annotation}
            %188 = cute.memref.load(%rmem_131, %17) : (!memref_rmem_i32_1, !cute.coord<"0">) -> i32
            %189 = cute.memref.load(%rmem_131, %16) : (!memref_rmem_i32_1, !cute.coord<"1">) -> i32
            %shape_133 = cute.make_shape(%135, %136) : (i32, i32) -> !cute.shape<"(?,?,1)">
            %stride_134 = cute.make_stride(%188, %189) : (i32, i32) -> !cute.stride<"(?,?,0)">
            %lay_135 = cute.make_layout(%shape_133, %stride_134) : !cute.layout<"(?,?,1):(?,?,0)">
            %view_136 = cute.make_view(%187, %lay_135) : !memref_gmem_f16_
            %dyn_137 = cute.derefine(%view_136) : !memref_gmem_f16_ to !memref_gmem_f16_1
            %190 = arith.cmpi eq, %arg15, %false : i1
            %191 = arith.select %190, %true, %arg15 : i1
            scf.if %190 {
              nvvm.barrier id = %c4_i32 number_of_threads = %c160_i32
            }
            scf.if %52 {
              cute_nvgpu.update_tma_desc(%arg1, %dyn_125, %iter_8) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>, !memref_gmem_f16_1, !cute.ptr<i64, smem, align<1024>>) -> ()
              cute_nvgpu.update_tma_desc(%arg3, %dyn_137, %ptr_9) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>, !memref_gmem_f16_1, !cute.ptr<i64, smem, align<128>>) -> ()
              %192 = nvvm.elect.sync -> i1
              scf.if %192 {
                nvvm.cp.async.bulk.commit.group
                nvvm.cp.async.bulk.wait_group 0 {read}
              }
              nvvm.bar.warp.sync %c-1_i32 : i32
              %193 = cute.ptrtoint(%86) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, gmem, align<128>> to i64
              %194 = cute.ptrtoint(%iter_8) : !cute.ptr<i64, smem, align<1024>> to i32
              llvm.inline_asm has_side_effects asm_dialect = att "tensormap.cp_fenceproxy.global.shared::cta.tensormap::generic.release.gpu.sync.aligned [$0], [$1], 128;", "l,r" %193, %194 : (i64, i32) -> ()
              %195 = cute.ptrtoint(%88) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, gmem, align<128>> to i64
              %196 = cute.ptrtoint(%ptr_9) : !cute.ptr<i64, smem, align<128>> to i32
              llvm.inline_asm has_side_effects asm_dialect = att "tensormap.cp_fenceproxy.global.shared::cta.tensormap::generic.release.gpu.sync.aligned [$0], [$1], 128;", "l,r" %195, %196 : (i64, i32) -> ()
            }
            scf.yield %191 : i1
          } else {
            scf.yield %arg15 : i1
          }
          %div_94 = cute.tuple_div(%tup, %38) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
          %coord_95 = cute.make_coord(%div_94) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,?,_,0)">
          %145:3 = cute.get_scalars(%lay_43) <{only_dynamic}> : !cute.layout<"(((64,128),1),?,?,?):(((1@0,1@1),0),128@1,64@0,1@2)">
          %shape_96 = cute.make_shape(%145#1) : (i32) -> !cute.shape<"(((64,128),1),?)">
          %lay_97 = cute.make_layout(%shape_96, %13) : !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">
          %idx_98 = cute.crd2idx(%coord_95, %lay_43) : (!cute.coord<"(_,?,_,0)">, !cute.layout<"(((64,128),1),?,?,?):(((1@0,1@1),0),128@1,64@0,1@2)">) -> !cute.int_tuple<"(0,?{div=128},0)">
          %tup_99 = cute.add_offset(%26, %idx_98) : (!cute.int_tuple<"(0,0,0)">, !cute.int_tuple<"(0,?{div=128},0)">) -> !cute.int_tuple<"(0,?{div=128},0)">
          %coord_100 = cute.make_coord(%tup_93) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,?,_,0)">
          %146:3 = cute.get_scalars(%lay_47) <{only_dynamic}> : !cute.layout<"(((64,128),1),?,?,?):(((1@0,1@1),0),128@1,64@0,1@2)">
          %shape_101 = cute.make_shape(%146#1) : (i32) -> !cute.shape<"(((64,128),1),?)">
          %lay_102 = cute.make_layout(%shape_101, %13) : !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">
          %idx_103 = cute.crd2idx(%coord_100, %lay_47) : (!cute.coord<"(_,?,_,0)">, !cute.layout<"(((64,128),1),?,?,?):(((1@0,1@1),0),128@1,64@0,1@2)">) -> !cute.int_tuple<"(0,?{div=128},0)">
          %tup_104 = cute.add_offset(%26, %idx_103) : (!cute.int_tuple<"(0,0,0)">, !cute.int_tuple<"(0,?{div=128},0)">) -> !cute.int_tuple<"(0,?{div=128},0)">
          %int_tuple_105 = cute.make_int_tuple(%arg16) : (i32) -> !cute.int_tuple<"?">
          %tup_106 = cute.add_offset(%int_tuple_105, %e2_83) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.int_tuple<"?">
          %147 = cute.get_scalars(%tup_106) : !cute.int_tuple<"?">
          %148 = arith.remsi %arg16, %c6_i32 : i32
          %149 = arith.floordivsi %arg16, %c6_i32 : i32
          %150 = arith.remsi %149, %c2_i32 : i32
          %151 = arith.xori %150, %c1_i32 : i32
          %152 = arith.cmpi sgt, %141, %c0_i32 : i32
          %int_tuple_107 = cute.make_int_tuple(%148) : (i32) -> !cute.int_tuple<"?">
          %ptr_108 = cute.add_offset(%iter_13, %int_tuple_107) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
          %153 = scf.if %152 -> (i1) {
            %182 = builtin.unrealized_conversion_cast %ptr_108 : !cute.ptr<i64, smem> to !llvm.ptr<3>
            %183 = nvvm.mbarrier.wait.parity %182, %151 {kind = #nvvm.mbar_wait<try>} : !llvm.ptr<3>, i32 -> i1
            scf.yield %183 : i1
          } else {
            scf.yield %true : i1
          }
          scf.if %143 {
            %182 = cute.ptrtoint(%86) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, gmem, align<128>> to i64
            llvm.inline_asm has_side_effects asm_dialect = att "fence.proxy.tensormap::generic.acquire.gpu [$0], 128;", "l" %182 : (i64) -> ()
            %183 = cute.ptrtoint(%88) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, gmem, align<128>> to i64
            llvm.inline_asm has_side_effects asm_dialect = att "fence.proxy.tensormap::generic.acquire.gpu [$0], 128;", "l" %183 : (i64) -> ()
          }
          %154:4 = scf.for %arg25 = %c0_i32 to %141 step %c1_i32 iter_args(%arg26 = %153, %arg27 = %c0_i32, %arg28 = %148, %arg29 = %151) -> (i1, i32, i32, i32)  : i32 {
            %182 = arith.addi %arg27, %c1_i32 : i32
            %183 = arith.addi %arg16, %182 : i32
            %184 = arith.remsi %183, %c6_i32 : i32
            %185 = arith.cmpi eq, %184, %c0_i32 : i32
            %186 = arith.xori %arg29, %c1_i32 : i32
            %187 = arith.select %185, %186, %arg29 : i32
            %int_tuple_115 = cute.make_int_tuple(%arg28) : (i32) -> !cute.int_tuple<"?">
            %ptr_116 = cute.add_offset(%iter_12, %int_tuple_115) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
            %188 = arith.extui %arg26 : i1 to i32
            %189 = arith.cmpi eq, %188, %c0_i32 : i32
            scf.if %189 {
              %ptr_138 = cute.add_offset(%iter_13, %int_tuple_115) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
              %203 = builtin.unrealized_conversion_cast %ptr_138 : !cute.ptr<i64, smem> to !llvm.ptr<3>
              nvvm.mbarrier.try_wait.parity.shared %203, %arg29, %c10000000_i32 : !llvm.ptr<3>, i32, i32
            }
            %190 = nvvm.elect.sync -> i1
            scf.if %190 {
              %203 = builtin.unrealized_conversion_cast %ptr_116 : !cute.ptr<i64, smem> to !llvm.ptr<3>
              nvvm.mbarrier.txn %203, %c32768_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
            }
            %coord_117 = cute.make_coord(%arg27) : (i32) -> !cute.coord<"(_,?)">
            %idx_118 = cute.crd2idx(%coord_117, %lay_97) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
            %tup_119 = cute.add_offset(%tup_99, %idx_118) : (!cute.int_tuple<"(0,?{div=128},0)">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.int_tuple<"(?{div=64},?{div=128},0)">
            %e0_120, %e1_121, %e2_122 = cute.get_leaves(%tup_119) : !cute.int_tuple<"(?{div=64},?{div=128},0)">
            %coord_123 = cute.make_coord(%arg28) : (i32) -> !cute.coord<"(_,?)">
            %idx_124 = cute.crd2idx(%coord_123, %12) : (!cute.coord<"(_,?)">, !cute.layout<"((8192,1),6):((1,0),8192)">) -> !cute.int_tuple<"?{div=8192}">
            %ptr_125 = cute.add_offset(%iter_17, %idx_124) : (!cute.ptr<f16, smem, align<1024>, S<3,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<f16, smem, align<1024>, S<3,4,3>>
            %191 = cute.ptrtoint(%86) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, gmem, align<128>> to i64
            %iv_126 = cute.assume(%191) : (i64) -> !cute.i64<divby 128>
            %192 = cute.inttoptr(%iv_126) : !cute.i64<divby 128> to !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<128>>
            %int_tuple_127 = cute.make_int_tuple(%e0_120, %e1_121) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=128}">) -> !cute.int_tuple<"(?{div=64},?{div=128},0)">
            %193 = cute_nvgpu.atom.make_exec_tma(%arg1) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>
            %194 = cute_nvgpu.atom.set_value(%193, %ptr_116 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>
            %195 = cute_nvgpu.atom.set_value(%194, %192 : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<128>>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_descriptor_ptr>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>
            scf.for %arg30 = %c0_i32 to %132 step %c1_i32  : i32 {
              %203 = cute_nvgpu.atom.get_value(%195 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
              %204 = cute_nvgpu.atom.get_value(%195 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<cache_policy>} : i64
              %TMADescAddr = cute_nvgpu.get_tma_desc_addr(%195 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>) -> !cute.ptr<generic, align<64>>
              %205:3 = cute.get_scalars(%int_tuple_127) : !cute.int_tuple<"(?{div=64},?{div=128},0)">
              cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr : !cute.ptr<generic, align<64>>, %ptr_125 : !cute.ptr<f16, smem, align<1024>, S<3,4,3>>, %203 : !cute.ptr<smem, align<8>>, [%205#0, %205#1, %205#2] : i32, i32, i32) cache_policy = %204 mode = <tiled> num_cta = 1 : i32
            } {llvm.loop_annotation = #loop_annotation}
            %idx_128 = cute.crd2idx(%coord_117, %lay_102) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
            %tup_129 = cute.add_offset(%tup_104, %idx_128) : (!cute.int_tuple<"(0,?{div=128},0)">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.int_tuple<"(?{div=64},?{div=128},0)">
            %e0_130, %e1_131, %e2_132 = cute.get_leaves(%tup_129) : !cute.int_tuple<"(?{div=64},?{div=128},0)">
            %ptr_133 = cute.add_offset(%iter_18, %idx_124) : (!cute.ptr<f16, smem, align<1024>, S<3,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<f16, smem, align<1024>, S<3,4,3>>
            %196 = cute.ptrtoint(%88) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, gmem, align<128>> to i64
            %iv_134 = cute.assume(%196) : (i64) -> !cute.i64<divby 128>
            %197 = cute.inttoptr(%iv_134) : !cute.i64<divby 128> to !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<128>>
            %int_tuple_135 = cute.make_int_tuple(%e0_130, %e1_131) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=128}">) -> !cute.int_tuple<"(?{div=64},?{div=128},0)">
            %198 = cute_nvgpu.atom.make_exec_tma(%arg3) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>
            %199 = cute_nvgpu.atom.set_value(%198, %ptr_116 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>
            %200 = cute_nvgpu.atom.set_value(%199, %197 : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<128>>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_descriptor_ptr>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>
            scf.for %arg30 = %c0_i32 to %132 step %c1_i32  : i32 {
              %203 = cute_nvgpu.atom.get_value(%200 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
              %204 = cute_nvgpu.atom.get_value(%200 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<cache_policy>} : i64
              %TMADescAddr = cute_nvgpu.get_tma_desc_addr(%200 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>) -> !cute.ptr<generic, align<64>>
              %205:3 = cute.get_scalars(%int_tuple_135) : !cute.int_tuple<"(?{div=64},?{div=128},0)">
              cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr : !cute.ptr<generic, align<64>>, %ptr_133 : !cute.ptr<f16, smem, align<1024>, S<3,4,3>>, %203 : !cute.ptr<smem, align<8>>, [%205#0, %205#1, %205#2] : i32, i32, i32) cache_policy = %204 mode = <tiled> num_cta = 1 : i32
            } {llvm.loop_annotation = #loop_annotation}
            %201 = arith.cmpi sgt, %141, %182 : i32
            %int_tuple_136 = cute.make_int_tuple(%184) : (i32) -> !cute.int_tuple<"?">
            %ptr_137 = cute.add_offset(%iter_13, %int_tuple_136) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
            %202 = scf.if %201 -> (i1) {
              %203 = builtin.unrealized_conversion_cast %ptr_137 : !cute.ptr<i64, smem> to !llvm.ptr<3>
              %204 = nvvm.mbarrier.wait.parity %203, %187 {kind = #nvvm.mbar_wait<try>} : !llvm.ptr<3>, i32 -> i1
              scf.yield %204 : i1
            } else {
              scf.yield %true : i1
            }
            scf.yield %202, %182, %184, %187 : i1, i32, i32, i32
          } {loop_annotation = #loop_annotation1}
          %155 = arith.addi %arg23, %92 : i32
          %156 = arith.addi %arg24, %c1_i32 : i32
          %157 = arith.cmpi sgt, %93, %155 : i32
          %158 = nvvm.mul  hi %155, %multiplier : i32 -> i32
          %159 = arith.subi %155, %158 : i32
          %160 = arith.shrui %159, %96 : i32
          %161 = arith.addi %158, %160 : i32
          %162 = arith.shrui %161, %97 : i32
          %163 = arith.muli %162, %95 : i32
          %164 = arith.subi %155, %163 : i32
          %165 = nvvm.mul  hi %164, %multiplier_63 : i32 -> i32
          %166 = arith.subi %164, %165 : i32
          %167 = arith.shrui %166, %106 : i32
          %168 = arith.addi %165, %167 : i32
          %169 = arith.shrui %168, %107 : i32
          %170 = arith.muli %169, %105 : i32
          %171 = arith.subi %164, %170 : i32
          %172 = nvvm.mul  hi %169, %multiplier_66 : i32 -> i32
          %173 = arith.subi %169, %172 : i32
          %174 = arith.shrui %173, %116 : i32
          %175 = arith.addi %172, %174 : i32
          %176 = arith.shrui %175, %117 : i32
          %177 = arith.muli %176, %115 : i32
          %178 = arith.subi %169, %177 : i32
          %int_tuple_109 = cute.make_int_tuple(%171) : (i32) -> !cute.int_tuple<"?">
          %mul_110 = cute.tuple_mul(%int_tuple_109, %38) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
          %179 = cute.get_scalars(%mul_110) : !cute.int_tuple<"?">
          %int_tuple_111 = cute.make_int_tuple(%178) : (i32) -> !cute.int_tuple<"?">
          %mul_112 = cute.tuple_mul(%int_tuple_111, %38) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
          %180 = cute.get_scalars(%mul_112) : !cute.int_tuple<"?">
          %int_tuple_113 = cute.make_int_tuple(%176) : (i32) -> !cute.int_tuple<"?">
          %mul_114 = cute.tuple_mul(%int_tuple_113, %38) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
          %181 = cute.get_scalars(%mul_114) : !cute.int_tuple<"?">
          scf.yield %144, %147, %179, %180, %181, %157, %131#0, %131#0, %131#1, %155, %156 : i1, i32, i32, i32, i32, i1, i32, i32, i32, i32, i32
        }
      }
      scf.if %57 {
        nvvm.barrier id = %c3_i32 number_of_threads = %c160_i32
        %tmem_ptr = cute_nvgpu.arch.sm100.retrieve_tmem_ptr(%iter) : !cute.ptr<i32, smem, align<8>> -> !cute.ptr<f32, tmem, align<16>>
        %int_tuple_59 = cute.make_int_tuple(%77, %78, %79) : (i32, i32, i32) -> !cute.int_tuple<"(?,?,?)">
        %sz = cute.size(%int_tuple_59) : (!cute.int_tuple<"(?,?,?)">) -> !cute.int_tuple<"?">
        %e0_60 = cute.get_leaves(%sz) : !cute.int_tuple<"?">
        %div = cute.tuple_div(%e0_60, %38) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
        %92 = cute.get_scalars(%div) : !cute.int_tuple<"?">
        %sz_61 = cute.size(%lay) : (!cute.layout<"(1,1,?):(0,0,1)">) -> !cute.int_tuple<"?">
        %e0_62 = cute.get_leaves(%sz_61) : !cute.int_tuple<"?">
        %93 = cute.get_scalars(%e0_62) : !cute.int_tuple<"?">
        %94 = arith.cmpi sgt, %93, %55 : i32
        %95 = cute.fast_divmod.get_divisor(%arg8) : !cute.fast_divmod_divisor<32>
        %multiplier, %shift1, %shift2 = cute.fast_divmod.get_aux(%arg8) : !cute.fast_divmod_divisor<32> -> (i32, i8)
        %96 = arith.extui %shift1 : i8 to i32
        %97 = arith.extui %shift2 : i8 to i32
        %98 = nvvm.mul  hi %55, %multiplier : i32 -> i32
        %99 = arith.subi %55, %98 : i32
        %100 = arith.shrui %99, %96 : i32
        %101 = arith.addi %98, %100 : i32
        %102 = arith.shrui %101, %97 : i32
        %103 = arith.muli %102, %95 : i32
        %104 = arith.subi %55, %103 : i32
        %multiplier_63, %shift1_64, %shift2_65 = cute.fast_divmod.get_aux(%arg9) : !cute.fast_divmod_divisor<32> -> (i32, i8)
        %105 = arith.extui %shift1_64 : i8 to i32
        %106 = arith.extui %shift2_65 : i8 to i32
        %107 = nvvm.mul  hi %104, %multiplier_63 : i32 -> i32
        %108 = arith.subi %104, %107 : i32
        %109 = arith.shrui %108, %105 : i32
        %110 = arith.addi %107, %109 : i32
        %111 = arith.shrui %110, %106 : i32
        %multiplier_66, %shift1_67, %shift2_68 = cute.fast_divmod.get_aux(%arg10) : !cute.fast_divmod_divisor<32> -> (i32, i8)
        %112 = arith.extui %shift1_67 : i8 to i32
        %113 = arith.extui %shift2_68 : i8 to i32
        %114 = nvvm.mul  hi %111, %multiplier_66 : i32 -> i32
        %115 = arith.subi %111, %114 : i32
        %116 = arith.shrui %115, %112 : i32
        %117 = arith.addi %114, %116 : i32
        %118 = arith.shrui %117, %113 : i32
        %int_tuple_69 = cute.make_int_tuple(%118) : (i32) -> !cute.int_tuple<"?">
        %mul = cute.tuple_mul(%int_tuple_69, %38) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
        %119 = cute.get_scalars(%mul) : !cute.int_tuple<"?">
        %120:7 = scf.while (%arg15 = %c0_i32, %arg16 = %119, %arg17 = %94, %arg18 = %c0_i32, %arg19 = %c0_i32, %arg20 = %arg0, %arg21 = %55, %arg22 = %c0_i32) : (i32, i32, i1, i32, i32, !mma_f16_f16_f32_128x128x16_, i32, i32) -> (i32, i32, i32, i32, !mma_f16_f16_f32_128x128x16_, i32, i32) {
          scf.condition(%arg17) %arg15, %arg16, %arg18, %arg19, %arg20, %arg21, %arg22 : i32, i32, i32, i32, !mma_f16_f16_f32_128x128x16_, i32, i32
        } do {
        ^bb0(%arg15: i32, %arg16: i32, %arg17: i32, %arg18: i32, %arg19: !mma_f16_f16_f32_128x128x16_, %arg20: i32, %arg21: i32):
          %121 = nvvm.read.ptx.sreg.laneid range <i32, 0, 32> : i32
          %122 = arith.cmpi sge, %arg16, %arg18 : i32
          %123:3 = scf.while (%arg22 = %122, %arg23 = %arg17, %arg24 = %arg18, %arg25 = %arg18) : (i1, i32, i32, i32) -> (i32, i32, i32) {
            scf.condition(%arg22) %arg23, %arg24, %arg25 : i32, i32, i32
          } do {
          ^bb0(%arg22: i32, %arg23: i32, %arg24: i32):
            %166 = arith.addi %arg22, %121 : i32
            %167 = arith.cmpi slt, %166, %c2_i32 : i32
            %168 = scf.if %167 -> (i32) {
              %rmem_84 = cute.memref.alloca() : !memref_rmem_i32_
              %coord_85 = cute.make_coord(%166) : (i32) -> !cute.coord<"(?,_)">
              %idx_86 = cute.crd2idx(%coord_85, %18) : (!cute.coord<"(?,_)">, !cute.layout<"(2,4):(4,1)">) -> !cute.int_tuple<"?{div=4}">
              %iter_87 = cute.get_iter(%arg11) : !memref_gmem_i32_
              %ptr_88 = cute.add_offset(%iter_87, %idx_86) : (!cute.ptr<i32, gmem, align<16>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<i32, gmem, align<16>>
              %iter_89 = cute.get_iter(%rmem_84) : !memref_rmem_i32_
              %195 = cute.get_scalars(%38) : !cute.int_tuple<"1">
              scf.for %arg25 = %c0_i32 to %195 step %c1_i32  : i32 {
                %203 = builtin.unrealized_conversion_cast %ptr_88 : !cute.ptr<i32, gmem, align<16>> to !llvm.ptr<1>
                %204 = builtin.unrealized_conversion_cast %iter_89 : !cute.ptr<i32, rmem, align<32>> to !llvm.ptr
                %205 = llvm.load %203 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<4xi32>
                llvm.store %205, %204 {alignment = 16 : i64} : vector<4xi32>, !llvm.ptr
              } {llvm.loop_annotation = #loop_annotation}
              %196 = cute.memref.load(%rmem_84, %17) : (!memref_rmem_i32_, !cute.coord<"0">) -> i32
              %197 = arith.addi %196, %c127_i32 : i32
              %198 = arith.floordivsi %197, %c128_i32 : i32
              %199 = cute.memref.load(%rmem_84, %16) : (!memref_rmem_i32_, !cute.coord<"1">) -> i32
              %200 = arith.addi %199, %c127_i32 : i32
              %201 = arith.floordivsi %200, %c128_i32 : i32
              %202 = arith.muli %198, %201 : i32
              scf.yield %202 : i32
            } else {
              scf.yield %c0_i32 : i32
            }
            %169 = nvvm.shfl.sync  up %c-1_i32, %168, %c1_i32, %c0_i32 : i32 -> i32
            %170 = arith.cmpi sge, %121, %c1_i32 : i32
            %171 = scf.if %170 -> (i32) {
              %195 = arith.addi %168, %169 : i32
              scf.yield %195 : i32
            } else {
              scf.yield %168 : i32
            }
            %172 = nvvm.shfl.sync  up %c-1_i32, %171, %c2_i32, %c0_i32 : i32 -> i32
            %173 = arith.cmpi sge, %121, %c2_i32 : i32
            %174 = scf.if %173 -> (i32) {
              %195 = arith.addi %171, %172 : i32
              scf.yield %195 : i32
            } else {
              scf.yield %171 : i32
            }
            %175 = nvvm.shfl.sync  up %c-1_i32, %174, %c4_i32, %c0_i32 : i32 -> i32
            %176 = arith.cmpi sge, %121, %c4_i32 : i32
            %177 = scf.if %176 -> (i32) {
              %195 = arith.addi %174, %175 : i32
              scf.yield %195 : i32
            } else {
              scf.yield %174 : i32
            }
            %178 = nvvm.shfl.sync  up %c-1_i32, %177, %c8_i32, %c0_i32 : i32 -> i32
            %179 = arith.cmpi sge, %121, %c8_i32 : i32
            %180 = scf.if %179 -> (i32) {
              %195 = arith.addi %177, %178 : i32
              scf.yield %195 : i32
            } else {
              scf.yield %177 : i32
            }
            %181 = nvvm.shfl.sync  up %c-1_i32, %180, %c16_i32, %c0_i32 : i32 -> i32
            %182 = arith.cmpi sge, %121, %c16_i32 : i32
            %183 = scf.if %182 -> (i32) {
              %195 = arith.addi %180, %181 : i32
              scf.yield %195 : i32
            } else {
              scf.yield %180 : i32
            }
            %184 = arith.addi %183, %arg24 : i32
            %185 = arith.cmpi sge, %arg16, %184 : i32
            %186 = nvvm.vote.ballot.sync %c-1_i32, %185 : i32
            %187 = llvm.intr.ctpop(%186) : (i32) -> i32
            %188 = arith.cmpi eq, %187, %c32_i32 : i32
            %189 = arith.addi %187, %arg22 : i32
            %190 = arith.cmpi eq, %187, %c0_i32 : i32
            %191 = arith.cmpi eq, %190, %false : i1
            %192 = scf.if %191 -> (i32) {
              %195 = arith.subi %187, %c1_i32 : i32
              %196 = nvvm.shfl.sync  idx %c-1_i32, %184, %195, %c31_i32 : i32 -> i32
              scf.yield %196 : i32
            } else {
              scf.yield %arg24 : i32
            }
            %193 = arith.select %188, %c31_i32, %187 : i32
            %194 = nvvm.shfl.sync  idx %c-1_i32, %184, %193, %c31_i32 : i32 -> i32
            scf.yield %188, %189, %192, %194 : i1, i32, i32, i32
          }
          %rmem = cute.memref.alloca() : !memref_rmem_i32_
          %coord_70 = cute.make_coord(%123#0) : (i32) -> !cute.coord<"(?,_)">
          %idx_71 = cute.crd2idx(%coord_70, %18) : (!cute.coord<"(?,_)">, !cute.layout<"(2,4):(4,1)">) -> !cute.int_tuple<"?{div=4}">
          %iter_72 = cute.get_iter(%arg11) : !memref_gmem_i32_
          %ptr_73 = cute.add_offset(%iter_72, %idx_71) : (!cute.ptr<i32, gmem, align<16>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<i32, gmem, align<16>>
          %iter_74 = cute.get_iter(%rmem) : !memref_rmem_i32_
          %124 = cute.get_scalars(%38) : !cute.int_tuple<"1">
          scf.for %arg22 = %c0_i32 to %124 step %c1_i32  : i32 {
            %166 = builtin.unrealized_conversion_cast %ptr_73 : !cute.ptr<i32, gmem, align<16>> to !llvm.ptr<1>
            %167 = builtin.unrealized_conversion_cast %iter_74 : !cute.ptr<i32, rmem, align<32>> to !llvm.ptr
            %168 = llvm.load %166 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<4xi32>
            llvm.store %168, %167 {alignment = 16 : i64} : vector<4xi32>, !llvm.ptr
          } {llvm.loop_annotation = #loop_annotation}
          %125 = cute.memref.load(%rmem, %15) : (!memref_rmem_i32_, !cute.coord<"2">) -> i32
          %126 = arith.addi %125, %c63_i32 : i32
          %127 = arith.floordivsi %126, %c64_i32 : i32
          %128 = arith.remsi %arg21, %c2_i32 : i32
          %coord_75 = cute.make_coord(%128) : (i32) -> !cute.coord<"(_,_,_,?)">
          %idx_76 = cute.crd2idx(%coord_75, %11) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((128,128),1,1,2):((65536,1),0,0,128)">) -> !cute.int_tuple<"?{div=128}">
          %ptr_77 = cute.add_offset(%tmem_ptr, %idx_76) : (!cute.ptr<f32, tmem, align<16>>, !cute.int_tuple<"?{div=128}">) -> !cute.ptr<f32, tmem, align<16>>
          %129 = arith.addi %arg15, %127 : i32
          %130 = arith.remsi %arg15, %c6_i32 : i32
          %131 = arith.cmpi sgt, %127, %c0_i32 : i32
          %132 = arith.extui %131 : i1 to i32
          %133 = arith.select %131, %c1_i32, %132 : i32
          %134 = arith.cmpi ne, %133, %c0_i32 : i32
          %135 = arith.floordivsi %arg15, %c6_i32 : i32
          %136 = arith.remsi %135, %c2_i32 : i32
          %int_tuple_78 = cute.make_int_tuple(%130) : (i32) -> !cute.int_tuple<"?">
          %ptr_79 = cute.add_offset(%iter_12, %int_tuple_78) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
          %137 = scf.if %134 -> (i1) {
            %166 = builtin.unrealized_conversion_cast %ptr_79 : !cute.ptr<i64, smem> to !llvm.ptr<3>
            %167 = nvvm.mbarrier.wait.parity %166, %136 {kind = #nvvm.mbar_wait<try>} : !llvm.ptr<3>, i32 -> i1
            scf.yield %167 : i1
          } else {
            scf.yield %true : i1
          }
          %138 = arith.floordivsi %arg21, %c2_i32 : i32
          %139 = arith.remsi %138, %c2_i32 : i32
          %140 = arith.xori %139, %c1_i32 : i32
          %int_tuple_80 = cute.make_int_tuple(%128) : (i32) -> !cute.int_tuple<"?">
          %ptr_81 = cute.add_offset(%iter_15, %int_tuple_80) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
          %141 = builtin.unrealized_conversion_cast %ptr_81 : !cute.ptr<i64, smem> to !llvm.ptr<3>
          nvvm.mbarrier.try_wait.parity.shared %141, %140, %c10000000_i32 : !llvm.ptr<3>, i32, i32
          %142 = cute_nvgpu.atom.set_value(%arg19, %false : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_f16_f16_f32_128x128x16_
          %143:4 = scf.for %arg22 = %c0_i32 to %127 step %c1_i32 iter_args(%arg23 = %137, %arg24 = %130, %arg25 = %136, %arg26 = %142) -> (i1, i32, i32, !mma_f16_f16_f32_128x128x16_)  : i32 {
            %166 = arith.addi %arg22, %c1_i32 : i32
            %167 = arith.addi %arg15, %166 : i32
            %168 = arith.remsi %167, %c6_i32 : i32
            %169 = arith.cmpi eq, %168, %c0_i32 : i32
            %170 = arith.xori %arg25, %c1_i32 : i32
            %171 = arith.select %169, %170, %arg25 : i32
            %172 = arith.extui %arg23 : i1 to i32
            %173 = arith.cmpi eq, %172, %c0_i32 : i32
            scf.if %173 {
              %int_tuple_86 = cute.make_int_tuple(%arg24) : (i32) -> !cute.int_tuple<"?">
              %ptr_87 = cute.add_offset(%iter_12, %int_tuple_86) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
              %181 = builtin.unrealized_conversion_cast %ptr_87 : !cute.ptr<i64, smem> to !llvm.ptr<3>
              nvvm.mbarrier.try_wait.parity.shared %181, %arg25, %c10000000_i32 : !llvm.ptr<3>, i32, i32
            }
            %174 = scf.for %arg27 = %c0_i32 to %c4_i32 step %c1_i32 iter_args(%arg28 = %arg26) -> (!mma_f16_f16_f32_128x128x16_)  : i32 {
              %coord_86 = cute.make_coord(%arg27, %arg24) : (i32, i32) -> !cute.coord<"(_,_,?,?)">
              %idx_87 = cute.crd2idx(%coord_86, %10) : (!cute.coord<"(_,_,?,?)">, !cute.layout<"(1,1,4,6):(0,0,2,1024)">) -> !cute.int_tuple<"?{div=2}">
              %tup = cute.add_offset(%ummaSmemDesc, %idx_87) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
              %tup_88 = cute.add_offset(%ummaSmemDesc_48, %idx_87) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
              scf.for %arg29 = %c0_i32 to %124 step %c1_i32  : i32 {
                scf.for %arg30 = %c0_i32 to %124 step %c1_i32  : i32 {
                  scf.for %arg31 = %c0_i32 to %124 step %c1_i32  : i32 {
                    %182 = cute_nvgpu.atom.get_value(%arg28 : !mma_f16_f16_f32_128x128x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : i1
                    %183 = cute_nvgpu.atom.get_value(%arg28 : !mma_f16_f16_f32_128x128x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : i1
                    %184 = cute_nvgpu.atom.get_value(%arg28 : !mma_f16_f16_f32_128x128x16_) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : i1
                    %185 = arith.extui %182 : i1 to i32
                    %186 = arith.extui %183 : i1 to i32
                    %187 = arith.shli %185, %c13_i32 : i32
                    %188 = arith.shli %186, %c14_i32 : i32
                    %189 = arith.ori %187, %c136314896_i32 : i32
                    %190 = arith.ori %189, %188 : i32
                    cute_nvgpu.arch.mma.SM100.umma(%tup, %tup_88, %ptr_77, %190, %184) {num_cta = 1 : i32, scale = 0 : i32, a_type = f16} : (!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, !cute.ptr<f32, tmem, align<16>>, i32, i1) -> ()
                  } {llvm.loop_annotation = #loop_annotation}
                } {llvm.loop_annotation = #loop_annotation}
              } {llvm.loop_annotation = #loop_annotation}
              %181 = cute_nvgpu.atom.set_value(%arg28, %true : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_f16_f16_f32_128x128x16_
              scf.yield %181 : !mma_f16_f16_f32_128x128x16_
            } {loop_annotation = #loop_annotation2}
            %175 = nvvm.elect.sync -> i1
            scf.if %175 {
              %int_tuple_86 = cute.make_int_tuple(%arg24) : (i32) -> !cute.int_tuple<"?">
              %ptr_87 = cute.add_offset(%iter_13, %int_tuple_86) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
              %181 = builtin.unrealized_conversion_cast %ptr_87 : !cute.ptr<i64, smem> to !llvm.ptr<3>
              nvvm.tcgen05.commit.arrive %181 : !llvm.ptr<3>
            }
            %176 = arith.cmpi slt, %166, %127 : i32
            %177 = arith.extui %176 : i1 to i32
            %178 = arith.select %176, %c1_i32, %177 : i32
            %179 = arith.cmpi ne, %178, %c0_i32 : i32
            %int_tuple_84 = cute.make_int_tuple(%168) : (i32) -> !cute.int_tuple<"?">
            %ptr_85 = cute.add_offset(%iter_12, %int_tuple_84) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
            %180 = scf.if %179 -> (i1) {
              %181 = builtin.unrealized_conversion_cast %ptr_85 : !cute.ptr<i64, smem> to !llvm.ptr<3>
              %182 = nvvm.mbarrier.wait.parity %181, %171 {kind = #nvvm.mbar_wait<try>} : !llvm.ptr<3>, i32 -> i1
              scf.yield %182 : i1
            } else {
              scf.yield %true : i1
            }
            scf.yield %180, %168, %171, %174 : i1, i32, i32, !mma_f16_f16_f32_128x128x16_
          }
          %144 = nvvm.elect.sync -> i1
          scf.if %144 {
            %ptr_84 = cute.add_offset(%iter_14, %int_tuple_80) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
            %166 = builtin.unrealized_conversion_cast %ptr_84 : !cute.ptr<i64, smem> to !llvm.ptr<3>
            nvvm.tcgen05.commit.arrive %166 : !llvm.ptr<3>
          }
          %145 = arith.addi %arg20, %92 : i32
          %146 = arith.addi %arg21, %c1_i32 : i32
          %147 = arith.cmpi sgt, %93, %145 : i32
          %148 = nvvm.mul  hi %145, %multiplier : i32 -> i32
          %149 = arith.subi %145, %148 : i32
          %150 = arith.shrui %149, %96 : i32
          %151 = arith.addi %148, %150 : i32
          %152 = arith.shrui %151, %97 : i32
          %153 = arith.muli %152, %95 : i32
          %154 = arith.subi %145, %153 : i32
          %155 = nvvm.mul  hi %154, %multiplier_63 : i32 -> i32
          %156 = arith.subi %154, %155 : i32
          %157 = arith.shrui %156, %105 : i32
          %158 = arith.addi %155, %157 : i32
          %159 = arith.shrui %158, %106 : i32
          %160 = nvvm.mul  hi %159, %multiplier_66 : i32 -> i32
          %161 = arith.subi %159, %160 : i32
          %162 = arith.shrui %161, %112 : i32
          %163 = arith.addi %160, %162 : i32
          %164 = arith.shrui %163, %113 : i32
          %int_tuple_82 = cute.make_int_tuple(%164) : (i32) -> !cute.int_tuple<"?">
          %mul_83 = cute.tuple_mul(%int_tuple_82, %38) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
          %165 = cute.get_scalars(%mul_83) : !cute.int_tuple<"?">
          scf.yield %129, %165, %147, %123#0, %123#1, %143#3, %145, %146 : i32, i32, i1, i32, i32, !mma_f16_f16_f32_128x128x16_, i32, i32
        }
      }
      %91 = arith.cmpi slt, %51, %c4_i32 : i32
      scf.if %91 {
        scf.if %56 {
          %141 = nvvm.elect.sync -> i1
          scf.if %141 {
            cute_nvgpu.copy_tma_desc(%arg1, %iter_8) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>, !cute.ptr<i64, smem, align<1024>>) -> ()
          }
        }
        nvvm.bar.warp.sync %c-1_i32 : i32
        scf.if %56 {
          %141 = nvvm.elect.sync -> i1
          scf.if %141 {
            cute_nvgpu.copy_tma_desc(%arg3, %ptr_9) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>, !cute.ptr<i64, smem, align<128>>) -> ()
          }
        }
        nvvm.bar.warp.sync %c-1_i32 : i32
        nvvm.barrier id = %c4_i32 number_of_threads = %c160_i32
        scf.if %56 {
          %141 = nvvm.elect.sync -> i1
          scf.if %141 {
            cute_nvgpu.copy_tma_desc(%arg5, %dyn) : (!cute_nvgpu.atom.non_exec_tiled_tma_store<f16, copy_bits = 65536, tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>, !cute.ptr<i64, smem, align<128>>) -> ()
          }
        }
        nvvm.bar.warp.sync %c-1_i32 : i32
        scf.if %56 {
          cute_nvgpu.arch.sm100.alloc_tmem(%c256_i32, %iter) [ cta_1] : i32, !cute.ptr<i32, smem, align<8>>
        }
        nvvm.barrier id = %c3_i32 number_of_threads = %c160_i32
        %tmem_ptr = cute_nvgpu.arch.sm100.retrieve_tmem_ptr(%iter) : !cute.ptr<i32, smem, align<8>> -> !cute.ptr<f32, tmem, align<16>>
        %coord_59 = cute.make_coord(%40) : (i32) -> !cute.coord<"?">
        %92 = cute.get_scalars(%coord_59) <{only_dynamic}> : !cute.coord<"?">
        %93 = arith.divsi %92, %c32_i32 : i32
        %94 = arith.muli %93, %c2097152_i32 : i32
        %iv_60 = cute.assume(%94) : (i32) -> !cute.i32<divby 2097152>
        %int_tuple_61 = cute.make_int_tuple(%iv_60) : (!cute.i32<divby 2097152>) -> !cute.int_tuple<"?{div=2097152}">
        %ptr_62 = cute.add_offset(%tmem_ptr, %int_tuple_61) : (!cute.ptr<f32, tmem, align<16>>, !cute.int_tuple<"?{div=2097152}">) -> !cute.ptr<f32, tmem, align<16>>
        %rmem = cute.memref.alloca() : !memref_rmem_f32_
        %iter_63 = cute.get_iter(%rmem) : !memref_rmem_f32_
        %rmem_64 = cute.memref.alloca() : !memref_rmem_f16_
        %atom = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<f16>
        %95 = cute.make_tiled_copy(%atom) : !copy_simt
        %96 = arith.remsi %92, %c32_i32 : i32
        %97 = arith.muli %96, %c32_i32 : i32
        %98 = arith.muli %93, %c1024_i32 : i32
        %99 = arith.addi %97, %98 : i32
        %iv_65 = cute.assume(%99) : (i32) -> !cute.i32<divby 32>
        %int_tuple_66 = cute.make_int_tuple(%iv_65) : (!cute.i32<divby 32>) -> !cute.int_tuple<"?{div=32}">
        %ptr_67 = cute.add_offset(%iter_16, %int_tuple_66) : (!cute.ptr<f16, smem, align<1024>, S<2,4,3>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f16, smem, align<64>, S<2,4,3>>
        %iter_68 = cute.get_iter(%rmem_64) : !memref_rmem_f16_
        %view = cute.make_view(%iter_68) : !memref_rmem_f16_1
        %100:3 = cute.get_scalars(%lay_39) <{only_dynamic}> : !cute.layout<"((128,128),1,1,?,?,?):((1@1,1@0),0,0,128@1,128@0,1@2)">
        %shape_69 = cute.make_shape(%100#0, %100#1, %100#2) : (i32, i32, i32) -> !cute.shape<"(128,128,?,?,?)">
        %lay_70 = cute.make_layout(%shape_69, %24) : !cute.layout<"(128,128,?,?,?):(1@1,1@0,128@1,128@0,1@2)">
        %101:3 = cute.get_scalars(%lay_70) <{only_dynamic}> : !cute.layout<"(128,128,?,?,?):(1@1,1@0,128@1,128@0,1@2)">
        %shape_71 = cute.make_shape(%101#0, %101#1, %101#2) : (i32, i32, i32) -> !cute.shape<"(128,32,1,4,?,?,?)">
        %lay_72 = cute.make_layout(%shape_71, %9) : !cute.layout<"(128,32,1,4,?,?,?):(1@1,1@0,0,32@0,128@1,128@0,1@2)">
        %102:3 = cute.get_scalars(%lay_72) <{only_dynamic}> : !cute.layout<"(128,32,1,4,?,?,?):(1@1,1@0,0,32@0,128@1,128@0,1@2)">
        %shape_73 = cute.make_shape(%102#0, %102#1, %102#2) : (i32, i32, i32) -> !cute.shape<"((128,32),1,4,?,?,?)">
        %lay_74 = cute.make_layout(%shape_73, %8) : !cute.layout<"((128,32),1,4,?,?,?):((1@1,1@0),0,32@0,128@1,128@0,1@2)">
        %103:3 = cute.get_scalars(%lay_74) <{only_dynamic}> : !cute.layout<"((128,32),1,4,?,?,?):((1@1,1@0),0,32@0,128@1,128@0,1@2)">
        %shape_75 = cute.make_shape(%103#0, %103#1, %103#2) : (i32, i32, i32) -> !cute.shape<"(((32,128),1),1,4,?,?,?)">
        %lay_76 = cute.make_layout(%shape_75, %7) : !cute.layout<"(((32,128),1),1,4,?,?,?):(((1@0,1@1),0),0,32@0,128@1,128@0,1@2)">
        %int_tuple_77 = cute.make_int_tuple(%77, %78, %79) : (i32, i32, i32) -> !cute.int_tuple<"(?,?,?)">
        %sz = cute.size(%int_tuple_77) : (!cute.int_tuple<"(?,?,?)">) -> !cute.int_tuple<"?">
        %e0_78 = cute.get_leaves(%sz) : !cute.int_tuple<"?">
        %div = cute.tuple_div(%e0_78, %38) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
        %104 = cute.get_scalars(%div) : !cute.int_tuple<"?">
        %sz_79 = cute.size(%lay) : (!cute.layout<"(1,1,?):(0,0,1)">) -> !cute.int_tuple<"?">
        %e0_80 = cute.get_leaves(%sz_79) : !cute.int_tuple<"?">
        %105 = cute.get_scalars(%e0_80) : !cute.int_tuple<"?">
        %106 = arith.cmpi sgt, %105, %55 : i32
        %107 = cute.fast_divmod.get_divisor(%arg8) : !cute.fast_divmod_divisor<32>
        %multiplier, %shift1, %shift2 = cute.fast_divmod.get_aux(%arg8) : !cute.fast_divmod_divisor<32> -> (i32, i8)
        %108 = arith.extui %shift1 : i8 to i32
        %109 = arith.extui %shift2 : i8 to i32
        %110 = nvvm.mul  hi %55, %multiplier : i32 -> i32
        %111 = arith.subi %55, %110 : i32
        %112 = arith.shrui %111, %108 : i32
        %113 = arith.addi %110, %112 : i32
        %114 = arith.shrui %113, %109 : i32
        %115 = arith.muli %114, %107 : i32
        %116 = arith.subi %55, %115 : i32
        %117 = cute.fast_divmod.get_divisor(%arg9) : !cute.fast_divmod_divisor<32>
        %multiplier_81, %shift1_82, %shift2_83 = cute.fast_divmod.get_aux(%arg9) : !cute.fast_divmod_divisor<32> -> (i32, i8)
        %118 = arith.extui %shift1_82 : i8 to i32
        %119 = arith.extui %shift2_83 : i8 to i32
        %120 = nvvm.mul  hi %116, %multiplier_81 : i32 -> i32
        %121 = arith.subi %116, %120 : i32
        %122 = arith.shrui %121, %118 : i32
        %123 = arith.addi %120, %122 : i32
        %124 = arith.shrui %123, %119 : i32
        %125 = arith.muli %124, %117 : i32
        %126 = arith.subi %116, %125 : i32
        %127 = cute.fast_divmod.get_divisor(%arg10) : !cute.fast_divmod_divisor<32>
        %multiplier_84, %shift1_85, %shift2_86 = cute.fast_divmod.get_aux(%arg10) : !cute.fast_divmod_divisor<32> -> (i32, i8)
        %128 = arith.extui %shift1_85 : i8 to i32
        %129 = arith.extui %shift2_86 : i8 to i32
        %130 = nvvm.mul  hi %124, %multiplier_84 : i32 -> i32
        %131 = arith.subi %124, %130 : i32
        %132 = arith.shrui %131, %128 : i32
        %133 = arith.addi %130, %132 : i32
        %134 = arith.shrui %133, %129 : i32
        %135 = arith.muli %134, %127 : i32
        %136 = arith.subi %124, %135 : i32
        %int_tuple_87 = cute.make_int_tuple(%126) : (i32) -> !cute.int_tuple<"?">
        %mul = cute.tuple_mul(%int_tuple_87, %38) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
        %137 = cute.get_scalars(%mul) : !cute.int_tuple<"?">
        %int_tuple_88 = cute.make_int_tuple(%136) : (i32) -> !cute.int_tuple<"?">
        %mul_89 = cute.tuple_mul(%int_tuple_88, %38) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
        %138 = cute.get_scalars(%mul_89) : !cute.int_tuple<"?">
        %int_tuple_90 = cute.make_int_tuple(%134) : (i32) -> !cute.int_tuple<"?">
        %mul_91 = cute.tuple_mul(%int_tuple_90, %38) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
        %139 = cute.get_scalars(%mul_91) : !cute.int_tuple<"?">
        %140:9 = scf.while (%arg15 = %c0_i32, %arg16 = %137, %arg17 = %138, %arg18 = %139, %arg19 = %106, %arg20 = %c-1_i32, %arg21 = %c0_i32, %arg22 = %c0_i32, %arg23 = %55, %arg24 = %c0_i32) : (i32, i32, i32, i32, i1, i32, i32, i32, i32, i32) -> (i32, i32, i32, i32, i32, i32, i32, i32, i32) {
          scf.condition(%arg19) %arg15, %arg16, %arg17, %arg18, %arg20, %arg21, %arg22, %arg23, %arg24 : i32, i32, i32, i32, i32, i32, i32, i32, i32
        } do {
        ^bb0(%arg15: i32, %arg16: i32, %arg17: i32, %arg18: i32, %arg19: i32, %arg20: i32, %arg21: i32, %arg22: i32, %arg23: i32):
          %141 = nvvm.read.ptx.sreg.laneid range <i32, 0, 32> : i32
          %142 = arith.cmpi sge, %arg18, %arg21 : i32
          %143:3 = scf.while (%arg24 = %142, %arg25 = %arg20, %arg26 = %arg21, %arg27 = %arg21) : (i1, i32, i32, i32) -> (i32, i32, i32) {
            scf.condition(%arg24) %arg25, %arg26, %arg27 : i32, i32, i32
          } do {
          ^bb0(%arg24: i32, %arg25: i32, %arg26: i32):
            %189 = arith.addi %arg24, %141 : i32
            %190 = arith.cmpi slt, %189, %c2_i32 : i32
            %191 = scf.if %190 -> (i32) {
              %rmem_130 = cute.memref.alloca() : !memref_rmem_i32_
              %coord_131 = cute.make_coord(%189) : (i32) -> !cute.coord<"(?,_)">
              %idx_132 = cute.crd2idx(%coord_131, %18) : (!cute.coord<"(?,_)">, !cute.layout<"(2,4):(4,1)">) -> !cute.int_tuple<"?{div=4}">
              %iter_133 = cute.get_iter(%arg11) : !memref_gmem_i32_
              %ptr_134 = cute.add_offset(%iter_133, %idx_132) : (!cute.ptr<i32, gmem, align<16>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<i32, gmem, align<16>>
              %iter_135 = cute.get_iter(%rmem_130) : !memref_rmem_i32_
              %218 = cute.get_scalars(%38) : !cute.int_tuple<"1">
              scf.for %arg27 = %c0_i32 to %218 step %c1_i32  : i32 {
                %226 = builtin.unrealized_conversion_cast %ptr_134 : !cute.ptr<i32, gmem, align<16>> to !llvm.ptr<1>
                %227 = builtin.unrealized_conversion_cast %iter_135 : !cute.ptr<i32, rmem, align<32>> to !llvm.ptr
                %228 = llvm.load %226 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<4xi32>
                llvm.store %228, %227 {alignment = 16 : i64} : vector<4xi32>, !llvm.ptr
              } {llvm.loop_annotation = #loop_annotation}
              %219 = cute.memref.load(%rmem_130, %17) : (!memref_rmem_i32_, !cute.coord<"0">) -> i32
              %220 = arith.addi %219, %c127_i32 : i32
              %221 = arith.floordivsi %220, %c128_i32 : i32
              %222 = cute.memref.load(%rmem_130, %16) : (!memref_rmem_i32_, !cute.coord<"1">) -> i32
              %223 = arith.addi %222, %c127_i32 : i32
              %224 = arith.floordivsi %223, %c128_i32 : i32
              %225 = arith.muli %221, %224 : i32
              scf.yield %225 : i32
            } else {
              scf.yield %c0_i32 : i32
            }
            %192 = nvvm.shfl.sync  up %c-1_i32, %191, %c1_i32, %c0_i32 : i32 -> i32
            %193 = arith.cmpi sge, %141, %c1_i32 : i32
            %194 = scf.if %193 -> (i32) {
              %218 = arith.addi %191, %192 : i32
              scf.yield %218 : i32
            } else {
              scf.yield %191 : i32
            }
            %195 = nvvm.shfl.sync  up %c-1_i32, %194, %c2_i32, %c0_i32 : i32 -> i32
            %196 = arith.cmpi sge, %141, %c2_i32 : i32
            %197 = scf.if %196 -> (i32) {
              %218 = arith.addi %194, %195 : i32
              scf.yield %218 : i32
            } else {
              scf.yield %194 : i32
            }
            %198 = nvvm.shfl.sync  up %c-1_i32, %197, %c4_i32, %c0_i32 : i32 -> i32
            %199 = arith.cmpi sge, %141, %c4_i32 : i32
            %200 = scf.if %199 -> (i32) {
              %218 = arith.addi %197, %198 : i32
              scf.yield %218 : i32
            } else {
              scf.yield %197 : i32
            }
            %201 = nvvm.shfl.sync  up %c-1_i32, %200, %c8_i32, %c0_i32 : i32 -> i32
            %202 = arith.cmpi sge, %141, %c8_i32 : i32
            %203 = scf.if %202 -> (i32) {
              %218 = arith.addi %200, %201 : i32
              scf.yield %218 : i32
            } else {
              scf.yield %200 : i32
            }
            %204 = nvvm.shfl.sync  up %c-1_i32, %203, %c16_i32, %c0_i32 : i32 -> i32
            %205 = arith.cmpi sge, %141, %c16_i32 : i32
            %206 = scf.if %205 -> (i32) {
              %218 = arith.addi %203, %204 : i32
              scf.yield %218 : i32
            } else {
              scf.yield %203 : i32
            }
            %207 = arith.addi %206, %arg26 : i32
            %208 = arith.cmpi sge, %arg18, %207 : i32
            %209 = nvvm.vote.ballot.sync %c-1_i32, %208 : i32
            %210 = llvm.intr.ctpop(%209) : (i32) -> i32
            %211 = arith.cmpi eq, %210, %c32_i32 : i32
            %212 = arith.addi %210, %arg24 : i32
            %213 = arith.cmpi eq, %210, %c0_i32 : i32
            %214 = arith.cmpi eq, %213, %false : i1
            %215 = scf.if %214 -> (i32) {
              %218 = arith.subi %210, %c1_i32 : i32
              %219 = nvvm.shfl.sync  idx %c-1_i32, %207, %218, %c31_i32 : i32 -> i32
              scf.yield %219 : i32
            } else {
              scf.yield %arg26 : i32
            }
            %216 = arith.select %211, %c31_i32, %210 : i32
            %217 = nvvm.shfl.sync  idx %c-1_i32, %207, %216, %c31_i32 : i32 -> i32
            scf.yield %211, %212, %215, %217 : i1, i32, i32, i32
          }
          %rmem_92 = cute.memref.alloca() : !memref_rmem_i32_
          %coord_93 = cute.make_coord(%143#0) : (i32) -> !cute.coord<"(?,_)">
          %idx_94 = cute.crd2idx(%coord_93, %18) : (!cute.coord<"(?,_)">, !cute.layout<"(2,4):(4,1)">) -> !cute.int_tuple<"?{div=4}">
          %iter_95 = cute.get_iter(%arg11) : !memref_gmem_i32_
          %ptr_96 = cute.add_offset(%iter_95, %idx_94) : (!cute.ptr<i32, gmem, align<16>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<i32, gmem, align<16>>
          %iter_97 = cute.get_iter(%rmem_92) : !memref_rmem_i32_
          %144 = cute.get_scalars(%38) : !cute.int_tuple<"1">
          scf.for %arg24 = %c0_i32 to %144 step %c1_i32  : i32 {
            %189 = builtin.unrealized_conversion_cast %ptr_96 : !cute.ptr<i32, gmem, align<16>> to !llvm.ptr<1>
            %190 = builtin.unrealized_conversion_cast %iter_97 : !cute.ptr<i32, rmem, align<32>> to !llvm.ptr
            %191 = llvm.load %189 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<4xi32>
            llvm.store %191, %190 {alignment = 16 : i64} : vector<4xi32>, !llvm.ptr
          } {llvm.loop_annotation = #loop_annotation}
          %145 = arith.subi %arg18, %143#1 : i32
          %146 = cute.memref.load(%rmem_92, %17) : (!memref_rmem_i32_, !cute.coord<"0">) -> i32
          %147 = cute.memref.load(%rmem_92, %16) : (!memref_rmem_i32_, !cute.coord<"1">) -> i32
          %148 = cute.memref.load(%rmem_92, %15) : (!memref_rmem_i32_, !cute.coord<"2">) -> i32
          %int_tuple_98 = cute.make_int_tuple(%146, %147, %148) : (i32, i32, i32) -> !cute.int_tuple<"(?,?,?)">
          %149:3 = cute.get_scalars(%int_tuple_98) <{only_dynamic}> : !cute.int_tuple<"(?,?,?)">
          %150 = arith.ceildivsi %149#0, %c128_i32 : i32
          %151 = arith.ceildivsi %149#1, %c128_i32 : i32
          %152 = arith.ceildivsi %149#2, %c64_i32 : i32
          %int_tuple_99 = cute.make_int_tuple(%150, %151, %152) : (i32, i32, i32) -> !cute.int_tuple<"(?,?,?)">
          %e0_100, %e1_101, %e2_102 = cute.get_leaves(%int_tuple_99) : !cute.int_tuple<"(?,?,?)">
          %shape_103 = cute.make_shape(%e0_100, %e1_101) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.shape<"(?,?)">
          %lay_104 = cute.make_layout(%shape_103) : !cute.layout<"(?,?):(1,?)">
          %153 = cute.get_hier_coord(%145, %lay_104) : (i32, !cute.layout<"(?,?):(1,?)">) -> !cute.coord<"(?,?)">
          %e0_105, %e1_106 = cute.get_leaves(%153) : !cute.coord<"(?,?)">
          %itup = cute.to_int_tuple(%e0_105) : !cute.coord<"?"> to !cute.int_tuple<"?">
          %itup_107 = cute.to_int_tuple(%e1_106) : !cute.coord<"?"> to !cute.int_tuple<"?">
          %mul_108 = cute.tuple_mul(%itup, %38) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
          %int_tuple_109 = cute.make_int_tuple(%arg16) : (i32) -> !cute.int_tuple<"?">
          %tup = cute.add_offset(%mul_108, %int_tuple_109) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.int_tuple<"?">
          %mul_110 = cute.tuple_mul(%itup_107, %38) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
          %int_tuple_111 = cute.make_int_tuple(%arg17) : (i32) -> !cute.int_tuple<"?">
          %tup_112 = cute.add_offset(%mul_110, %int_tuple_111) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.int_tuple<"?">
          %154 = arith.cmpi ne, %143#0, %arg19 : i32
          scf.if %154 {
            %coord_130 = cute.make_coord(%143#0) : (i32) -> !cute.coord<"(?,2)">
            %189 = cute.memref.load(%arg13, %coord_130) : (!memref_gmem_i64_, !cute.coord<"(?,2)">) -> i64
            %iv_131 = cute.assume(%189) : (i64) -> !cute.i64<divby 16>
            %190 = cute.inttoptr(%iv_131) : !cute.i64<divby 16> to !cute.ptr<f16, gmem, align<16>>
            %coord_132 = cute.make_coord(%143#0) : (i32) -> !cute.coord<"(?,2,_)">
            %idx_133 = cute.crd2idx(%coord_132, %14) : (!cute.coord<"(?,2,_)">, !cute.layout<"(2,3,2):(6,2,1)">) -> !cute.int_tuple<"?{div=2}">
            %iter_134 = cute.get_iter(%arg12) : !memref_gmem_i32_1
            %ptr_135 = cute.add_offset(%iter_134, %idx_133) : (!cute.ptr<i32, gmem, align<16>>, !cute.int_tuple<"?{div=2}">) -> !cute.ptr<i32, gmem, align<8>>
            %rmem_136 = cute.memref.alloca() : !memref_rmem_i32_1
            %iter_137 = cute.get_iter(%rmem_136) : !memref_rmem_i32_1
            scf.for %arg24 = %c0_i32 to %144 step %c1_i32  : i32 {
              %193 = builtin.unrealized_conversion_cast %ptr_135 : !cute.ptr<i32, gmem, align<8>> to !llvm.ptr<1>
              %194 = builtin.unrealized_conversion_cast %iter_137 : !cute.ptr<i32, rmem, align<32>> to !llvm.ptr
              %195 = llvm.load %193 {alignment = 8 : i64} : !llvm.ptr<1> -> vector<2xi32>
              llvm.store %195, %194 {alignment = 8 : i64} : vector<2xi32>, !llvm.ptr
            } {llvm.loop_annotation = #loop_annotation}
            %191 = cute.memref.load(%rmem_136, %17) : (!memref_rmem_i32_1, !cute.coord<"0">) -> i32
            %192 = cute.memref.load(%rmem_136, %16) : (!memref_rmem_i32_1, !cute.coord<"1">) -> i32
            %shape_138 = cute.make_shape(%146, %147) : (i32, i32) -> !cute.shape<"(?,?,1)">
            %stride = cute.make_stride(%191, %192) : (i32, i32) -> !cute.stride<"(?,?,0)">
            %lay_139 = cute.make_layout(%shape_138, %stride) : !cute.layout<"(?,?,1):(?,?,0)">
            %view_140 = cute.make_view(%190, %lay_139) : !memref_gmem_f16_
            %dyn_141 = cute.derefine(%view_140) : !memref_gmem_f16_ to !memref_gmem_f16_1
            scf.if %56 {
              cute_nvgpu.update_tma_desc(%arg5, %dyn_141, %dyn) : (!cute_nvgpu.atom.non_exec_tiled_tma_store<f16, copy_bits = 65536, tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>, !memref_gmem_f16_1, !cute.ptr<i64, smem, align<128>>) -> ()
              %193 = nvvm.elect.sync -> i1
              scf.if %193 {
                nvvm.cp.async.bulk.commit.group
                nvvm.cp.async.bulk.wait_group 0 {read}
              }
              nvvm.bar.warp.sync %c-1_i32 : i32
              %194 = cute.ptrtoint(%90) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, gmem, align<128>> to i64
              %195 = cute.ptrtoint(%dyn) : !cute.ptr<i64, smem, align<128>> to i32
              llvm.inline_asm has_side_effects asm_dialect = att "tensormap.cp_fenceproxy.global.shared::cta.tensormap::generic.release.gpu.sync.aligned [$0], [$1], 128;", "l,r" %194, %195 : (i64, i32) -> ()
            }
          }
          %div_113 = cute.tuple_div(%tup, %38) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
          %int_tuple_114 = cute.make_int_tuple(%arg15) : (i32) -> !cute.int_tuple<"?">
          %tup_115 = cute.add_offset(%int_tuple_114, %e2_102) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.int_tuple<"?">
          %155 = cute.get_scalars(%tup_115) : !cute.int_tuple<"?">
          %coord_116 = cute.make_coord(%div_113, %tup_112) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(_,_,_,?,?,0)">
          %idx_117 = cute.crd2idx(%coord_116, %lay_76) : (!cute.coord<"(_,_,_,?,?,0)">, !cute.layout<"(((32,128),1),1,4,?,?,?):(((1@0,1@1),0),0,32@0,128@1,128@0,1@2)">) -> !cute.int_tuple<"(?{div=128},?{div=128},0)">
          %tup_118 = cute.add_offset(%26, %idx_117) : (!cute.int_tuple<"(0,0,0)">, !cute.int_tuple<"(?{div=128},?{div=128},0)">) -> !cute.int_tuple<"(?{div=128},?{div=128},0)">
          %156 = arith.remsi %arg23, %c2_i32 : i32
          %coord_119 = cute.make_coord(%156) : (i32) -> !cute.coord<"(_,_,_,_,_,?)">
          %idx_120 = cute.crd2idx(%coord_119, %6) : (!cute.coord<"(_,_,_,_,_,?)">, !cute.layout<"(((32,32),1),1,1,1,4,2):(((1,65536),0),0,0,0,32,128)">) -> !cute.int_tuple<"?{div=128}">
          %ptr_121 = cute.add_offset(%ptr_62, %idx_120) : (!cute.ptr<f32, tmem, align<16>>, !cute.int_tuple<"?{div=128}">) -> !cute.ptr<f32, tmem, align<16>>
          %157 = arith.floordivsi %arg23, %c2_i32 : i32
          %158 = arith.remsi %157, %c2_i32 : i32
          %int_tuple_122 = cute.make_int_tuple(%156) : (i32) -> !cute.int_tuple<"?">
          %ptr_123 = cute.add_offset(%iter_14, %int_tuple_122) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
          %159 = builtin.unrealized_conversion_cast %ptr_123 : !cute.ptr<i64, smem> to !llvm.ptr<3>
          nvvm.mbarrier.try_wait.parity.shared %159, %158, %c10000000_i32 : !llvm.ptr<3>, i32, i32
          scf.if %154 {
            scf.if %56 {
              %189 = cute.ptrtoint(%90) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, gmem, align<128>> to i64
              llvm.inline_asm has_side_effects asm_dialect = att "fence.proxy.tensormap::generic.acquire.gpu [$0], 128;", "l" %189 : (i64) -> ()
            }
          }
          %160 = arith.muli %arg23, %c4_i32 : i32
          scf.for %arg24 = %c0_i32 to %c4_i32 step %c1_i32  : i32 {
            %coord_130 = cute.make_coord(%arg24) : (i32) -> !cute.coord<"(_,_,_,?)">
            %idx_131 = cute.crd2idx(%coord_130, %5) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"(((32,32),1),1,1,(1,4)):(((1,65536),0),0,0,(0,32))">) -> !cute.int_tuple<"?{div=32}">
            %ptr_132 = cute.add_offset(%ptr_121, %idx_131) : (!cute.ptr<f32, tmem, align<16>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f32, tmem, align<16>>
            scf.for %arg25 = %c0_i32 to %144 step %c1_i32  : i32 {
              %193 = "cute_nvgpu.arch.copy.SM100.tmem_load"(%ptr_132) <{num_b = 32 : i32, num_dp = 32 : i32, num_rep = 32 : i32}> : (!cute.ptr<f32, tmem, align<16>>) -> vector<32xi32>
              %194 = builtin.unrealized_conversion_cast %iter_63 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
              llvm.store %193, %194 : vector<32xi32>, !llvm.ptr
            } {llvm.loop_annotation = #loop_annotation}
            %view_133 = cute.make_view(%iter_63) : !memref_rmem_f32_1
            %189 = cute.memref.load_vec %view_133 : !memref_rmem_f32_1
            %190 = arith.truncf %189 : vector<32xf32> to vector<32xf16>
            cute.memref.store_vec %190, %view : !memref_rmem_f16_1
            %191 = arith.addi %160, %arg24 : i32
            %192 = arith.remsi %191, %c4_i32 : i32
            %coord_134 = cute.make_coord(%192) : (i32) -> !cute.coord<"(_,_,_,?)">
            %idx_135 = cute.crd2idx(%coord_134, %4) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((1,32),1,1,(1,4)):((0,1),0,0,(0,4096))">) -> !cute.int_tuple<"?{div=4096}">
            scf.for %arg25 = %c0_i32 to %144 step %c1_i32  : i32 {
              %swizzled = cute.apply_swizzle(%ptr_67) : !cute.ptr<f16, smem, align<64>, S<2,4,3>>
              %ptr_136 = cute.add_offset(%swizzled, %idx_135) : (!cute.ptr<f16, smem, align<64>, S<2,4,3>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, smem, align<64>, S<2,4,3>>
              %193 = builtin.unrealized_conversion_cast %iter_68 : !cute.ptr<f16, rmem, align<32>> to !llvm.ptr
              %194 = builtin.unrealized_conversion_cast %ptr_136 : !cute.ptr<f16, smem, align<64>, S<2,4,3>> to !llvm.ptr<3>
              %195 = llvm.load %193 {alignment = 16 : i64} : !llvm.ptr -> vector<8xf16>
              llvm.store %195, %194 {alignment = 16 : i64} : vector<8xf16>, !llvm.ptr<3>
              %ptr_137 = cute.add_offset(%iter_68, %3) : (!cute.ptr<f16, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<f16, rmem, align<16>>
              %ptr_138 = cute.add_offset(%ptr_67, %3) : (!cute.ptr<f16, smem, align<64>, S<2,4,3>>, !cute.int_tuple<"8">) -> !cute.ptr<f16, smem, align<16>, S<2,4,3>>
              %swizzled_139 = cute.apply_swizzle(%ptr_138) : !cute.ptr<f16, smem, align<16>, S<2,4,3>>
              %ptr_140 = cute.add_offset(%swizzled_139, %idx_135) : (!cute.ptr<f16, smem, align<16>, S<2,4,3>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, smem, align<16>, S<2,4,3>>
              %196 = builtin.unrealized_conversion_cast %ptr_137 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
              %197 = builtin.unrealized_conversion_cast %ptr_140 : !cute.ptr<f16, smem, align<16>, S<2,4,3>> to !llvm.ptr<3>
              %198 = llvm.load %196 {alignment = 16 : i64} : !llvm.ptr -> vector<8xf16>
              llvm.store %198, %197 {alignment = 16 : i64} : vector<8xf16>, !llvm.ptr<3>
              %ptr_141 = cute.add_offset(%iter_68, %29) : (!cute.ptr<f16, rmem, align<32>>, !cute.int_tuple<"16">) -> !cute.ptr<f16, rmem, align<32>>
              %ptr_142 = cute.add_offset(%ptr_67, %29) : (!cute.ptr<f16, smem, align<64>, S<2,4,3>>, !cute.int_tuple<"16">) -> !cute.ptr<f16, smem, align<32>, S<2,4,3>>
              %swizzled_143 = cute.apply_swizzle(%ptr_142) : !cute.ptr<f16, smem, align<32>, S<2,4,3>>
              %ptr_144 = cute.add_offset(%swizzled_143, %idx_135) : (!cute.ptr<f16, smem, align<32>, S<2,4,3>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, smem, align<32>, S<2,4,3>>
              %199 = builtin.unrealized_conversion_cast %ptr_141 : !cute.ptr<f16, rmem, align<32>> to !llvm.ptr
              %200 = builtin.unrealized_conversion_cast %ptr_144 : !cute.ptr<f16, smem, align<32>, S<2,4,3>> to !llvm.ptr<3>
              %201 = llvm.load %199 {alignment = 16 : i64} : !llvm.ptr -> vector<8xf16>
              llvm.store %201, %200 {alignment = 16 : i64} : vector<8xf16>, !llvm.ptr<3>
              %ptr_145 = cute.add_offset(%iter_68, %2) : (!cute.ptr<f16, rmem, align<32>>, !cute.int_tuple<"24">) -> !cute.ptr<f16, rmem, align<16>>
              %ptr_146 = cute.add_offset(%ptr_67, %2) : (!cute.ptr<f16, smem, align<64>, S<2,4,3>>, !cute.int_tuple<"24">) -> !cute.ptr<f16, smem, align<16>, S<2,4,3>>
              %swizzled_147 = cute.apply_swizzle(%ptr_146) : !cute.ptr<f16, smem, align<16>, S<2,4,3>>
              %ptr_148 = cute.add_offset(%swizzled_147, %idx_135) : (!cute.ptr<f16, smem, align<16>, S<2,4,3>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, smem, align<16>, S<2,4,3>>
              %202 = builtin.unrealized_conversion_cast %ptr_145 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
              %203 = builtin.unrealized_conversion_cast %ptr_148 : !cute.ptr<f16, smem, align<16>, S<2,4,3>> to !llvm.ptr<3>
              %204 = llvm.load %202 {alignment = 16 : i64} : !llvm.ptr -> vector<8xf16>
              llvm.store %204, %203 {alignment = 16 : i64} : vector<8xf16>, !llvm.ptr<3>
            } {llvm.loop_annotation = #loop_annotation}
            nvvm.fence.proxy {kind = #nvvm.proxy_kind<async.shared>, space = #nvvm.shared_space<cta>}
            nvvm.barrier id = %c2_i32 number_of_threads = %c128_i32
            scf.if %56 {
              %coord_136 = cute.make_coord(%192) : (i32) -> !cute.coord<"(_,?)">
              %idx_137 = cute.crd2idx(%coord_136, %1) : (!cute.coord<"(_,?)">, !cute.layout<"((4096,1),(1,4)):((1,0),(0,4096))">) -> !cute.int_tuple<"?{div=4096}">
              %ptr_138 = cute.add_offset(%iter_16, %idx_137) : (!cute.ptr<f16, smem, align<1024>, S<2,4,3>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, smem, align<1024>, S<2,4,3>>
              %coord_139 = cute.make_coord(%arg24) : (i32) -> !cute.coord<"(_,?)">
              %idx_140 = cute.crd2idx(%coord_139, %0) : (!cute.coord<"(_,?)">, !cute.layout<"(((32,128),1),(1,4)):(((1@0,1@1),0),(0,32@0))">) -> !cute.int_tuple<"(?{div=32},0)">
              %tup_141 = cute.add_offset(%tup_118, %idx_140) : (!cute.int_tuple<"(?{div=128},?{div=128},0)">, !cute.int_tuple<"(?{div=32},0)">) -> !cute.int_tuple<"(?{div=32},?{div=128},0)">
              %e0_142, %e1_143, %e2_144 = cute.get_leaves(%tup_141) : !cute.int_tuple<"(?{div=32},?{div=128},0)">
              %193 = cute.ptrtoint(%90) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, gmem, align<128>> to i64
              %iv_145 = cute.assume(%193) : (i64) -> !cute.i64<divby 128>
              %194 = cute.inttoptr(%iv_145) : !cute.i64<divby 128> to !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<128>>
              %int_tuple_146 = cute.make_int_tuple(%e0_142, %e1_143) : (!cute.int_tuple<"?{div=32}">, !cute.int_tuple<"?{div=128}">) -> !cute.int_tuple<"(?{div=32},?{div=128},0)">
              %195 = cute_nvgpu.atom.make_exec_tma(%arg5) : (!cute_nvgpu.atom.non_exec_tiled_tma_store<f16, copy_bits = 65536, tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_store<f16, copy_bits = 65536, mode = tiled, g_stride = <"()"> tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">>
              %196 = cute_nvgpu.atom.set_value(%195, %194 : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<128>>) {field = #cute_nvgpu.atom_copy_field_tmastore<tma_descriptor_ptr>} : !cute_nvgpu.atom.tma_store<f16, copy_bits = 65536, mode = tiled, g_stride = <"()"> tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">>
              scf.for %arg25 = %c0_i32 to %144 step %c1_i32  : i32 {
                %TMADescAddr = cute_nvgpu.get_tma_desc_addr(%196 : !cute_nvgpu.atom.tma_store<f16, copy_bits = 65536, mode = tiled, g_stride = <"()"> tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">>) -> !cute.ptr<generic, align<64>>
                %197 = cute_nvgpu.atom.get_value(%196 : !cute_nvgpu.atom.tma_store<f16, copy_bits = 65536, mode = tiled, g_stride = <"()"> tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">>) {field = #cute_nvgpu.atom_copy_field_tmastore<cache_policy>} : i64
                %198:3 = cute.get_scalars(%int_tuple_146) : !cute.int_tuple<"(?{div=32},?{div=128},0)">
                cute_nvgpu.arch.copy.SM100.tma_store(%TMADescAddr : !cute.ptr<generic, align<64>>, %ptr_138 : !cute.ptr<f16, smem, align<1024>, S<2,4,3>>, [%198#0, %198#1, %198#2] : i32, i32, i32) cache_policy = %197 mode = <tiled>
              } {llvm.loop_annotation = #loop_annotation}
              nvvm.cp.async.bulk.commit.group
              nvvm.cp.async.bulk.wait_group 3 {read}
            }
            nvvm.barrier id = %c2_i32 number_of_threads = %c128_i32
          }
          %161 = nvvm.elect.sync -> i1
          scf.if %161 {
            %ptr_130 = cute.add_offset(%iter_15, %int_tuple_122) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
            %189 = builtin.unrealized_conversion_cast %ptr_130 : !cute.ptr<i64, smem> to !llvm.ptr<3>
            nvvm.mbarrier.txn %189, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>} : !llvm.ptr<3>, i32
          }
          %162 = arith.addi %arg22, %104 : i32
          %163 = arith.addi %arg23, %c1_i32 : i32
          %164 = arith.cmpi sgt, %105, %162 : i32
          %165 = nvvm.mul  hi %162, %multiplier : i32 -> i32
          %166 = arith.subi %162, %165 : i32
          %167 = arith.shrui %166, %108 : i32
          %168 = arith.addi %165, %167 : i32
          %169 = arith.shrui %168, %109 : i32
          %170 = arith.muli %169, %107 : i32
          %171 = arith.subi %162, %170 : i32
          %172 = nvvm.mul  hi %171, %multiplier_81 : i32 -> i32
          %173 = arith.subi %171, %172 : i32
          %174 = arith.shrui %173, %118 : i32
          %175 = arith.addi %172, %174 : i32
          %176 = arith.shrui %175, %119 : i32
          %177 = arith.muli %176, %117 : i32
          %178 = arith.subi %171, %177 : i32
          %179 = nvvm.mul  hi %176, %multiplier_84 : i32 -> i32
          %180 = arith.subi %176, %179 : i32
          %181 = arith.shrui %180, %128 : i32
          %182 = arith.addi %179, %181 : i32
          %183 = arith.shrui %182, %129 : i32
          %184 = arith.muli %183, %127 : i32
          %185 = arith.subi %176, %184 : i32
          %int_tuple_124 = cute.make_int_tuple(%178) : (i32) -> !cute.int_tuple<"?">
          %mul_125 = cute.tuple_mul(%int_tuple_124, %38) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
          %186 = cute.get_scalars(%mul_125) : !cute.int_tuple<"?">
          %int_tuple_126 = cute.make_int_tuple(%185) : (i32) -> !cute.int_tuple<"?">
          %mul_127 = cute.tuple_mul(%int_tuple_126, %38) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
          %187 = cute.get_scalars(%mul_127) : !cute.int_tuple<"?">
          %int_tuple_128 = cute.make_int_tuple(%183) : (i32) -> !cute.int_tuple<"?">
          %mul_129 = cute.tuple_mul(%int_tuple_128, %38) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
          %188 = cute.get_scalars(%mul_129) : !cute.int_tuple<"?">
          scf.yield %155, %186, %187, %188, %164, %143#0, %143#0, %143#1, %162, %163 : i32, i32, i32, i32, i1, i32, i32, i32, i32, i32
        }
        scf.if %56 {
          cute_nvgpu.arch.sm100.relinquish_tmem_alloc_permit [ cta_1]
        }
        nvvm.barrier id = %c2_i32 number_of_threads = %c128_i32
        scf.if %56 {
          cute_nvgpu.arch.sm100.dealloc_tmem(%tmem_ptr, %c256_i32) [ cta_1] : !cute.ptr<f32, tmem, align<16>>, i32
        }
        scf.if %56 {
          %141 = arith.subi %140#0, %c1_i32 : i32
          %142 = arith.remsi %141, %c6_i32 : i32
          %int_tuple_92 = cute.make_int_tuple(%142) : (i32) -> !cute.int_tuple<"?">
          %ptr_93 = cute.add_offset(%iter_13, %int_tuple_92) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
          %143 = arith.floordivsi %141, %c6_i32 : i32
          %144 = arith.remsi %143, %c2_i32 : i32
          %145 = builtin.unrealized_conversion_cast %ptr_93 : !cute.ptr<i64, smem> to !llvm.ptr<3>
          nvvm.mbarrier.try_wait.parity.shared %145, %144, %c10000000_i32 : !llvm.ptr<3>, i32, i32
        }
      }
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
    %255 = scf.if %254 -> (i8) {
      scf.yield %9 : i8
    } else {
      %276 = arith.cmpi uge, %253, %c-2147483648_i32 : i32
      %277 = scf.if %276 -> (i8) {
        scf.yield %8 : i8
      } else {
        %278:2 = scf.while (%arg8 = %7, %arg9 = %6) : (i32, i8) -> (i32, i8) {
          %279 = arith.cmpi ult, %arg8, %253 : i32
          scf.condition(%279) %arg8, %arg9 : i32, i8
        } do {
        ^bb0(%arg8: i32, %arg9: i8):
          %279 = arith.muli %arg8, %7 : i32
          %280 = arith.addi %arg9, %6 : i8
          scf.yield %279, %280 : i32, i8
        }
        scf.yield %278#1 : i8
      }
      scf.yield %277 : i8
    }
    %256 = arith.extui %255 : i8 to i64
    %257 = arith.extui %253 : i32 to i64
    %258 = arith.shli %5, %256 : i64
    %259 = arith.subi %258, %257 : i64
    %260 = arith.muli %259, %c4294967296_i64 : i64
    %261 = arith.divui %260, %257 : i64
    %262 = arith.addi %261, %5 : i64
    %263 = arith.trunci %262 : i64 to i32
    %264 = arith.minui %255, %6 : i8
    %265 = arith.cmpi ult, %255, %6 : i8
    %266 = arith.subi %255, %6 : i8
    %267 = arith.select %265, %9, %266 : i8
    %268 = cute.fast_divmod.make_divisor(%253, %263, %264, %267) : i32 -> !cute.fast_divmod_divisor<32>
    %269 = cute.fast_divmod.make_divisor(%c1_i32, %c1_i32, %c0_i8, %9) : i32 -> !cute.fast_divmod_divisor<32>
    %270 = cute.get_shape(%lay_12) : (!cute.layout<"(1,1,?):(0,0,1)">) -> !cute.shape<"(1,1,?)">
    %e0_14, %e1_15, %e2_16 = cute.get_leaves(%270) : !cute.shape<"(1,1,?)">
    %itup = cute.to_int_tuple(%e2_16) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %int_tuple_17 = cute.make_int_tuple(%itup) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"(1,1,?)">
    %sz_18 = cute.size(%int_tuple_17) : (!cute.int_tuple<"(1,1,?)">) -> !cute.int_tuple<"?">
    %e0_19 = cute.get_leaves(%sz_18) : !cute.int_tuple<"?">
    %271 = cute.get_scalars(%e0_19) : !cute.int_tuple<"?">
    %272 = arith.minsi %271, %c1_i32 : i32
    %273 = cuda.launch_cfg.create<max_attrs = 2 : i32> (blockDim = (%c192_i32, %c1_i32, %c1_i32), dynamicSmemBytes = %c230400_i64, gridDim = (%c1_i32, %c1_i32, %272), stream = %arg7) : i32, i32, i32, i64, i32, i32, i32, !cuda.stream -> !cuda.launch_cfg<max_attrs = 2>
    cuda.launch_cfg.cluster_dim[%273] (%c1_i32, %c1_i32, %c1_i32) : !cuda.launch_cfg<max_attrs = 2>, i32, i32, i32
    %274 = cuda.launch_ex @kernels::@kernel_cutlass_kernel___main__GroupedGemmKernel_object_at__TiledMMA_ThrLayoutVMNK11110000_PermutationMNK____MMAAtom_ThrID10_ShapeMNK12812816_TVLayoutA1128161281128_TVLayoutB1128161281128__0<%273> (%18, %105, %view, %177, %view_5, %250, %view_10, %c2_i32, %268, %269, %269, %arg3, %arg4, %arg5, %arg6) : !cuda.launch_cfg<max_attrs = 2>, (!mma_f16_f16_f32_128x128x16_, !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>, !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">, !cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>, !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">, !cute_nvgpu.atom.non_exec_tiled_tma_store<f16, copy_bits = 65536, tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>, !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@1,1@0,1@2)">, i32, !cute.fast_divmod_divisor<32>, !cute.fast_divmod_divisor<32>, !cute.fast_divmod_divisor<32>, !memref_gmem_i32_, !memref_gmem_i32_1, !memref_gmem_i64_, !memref_gmem_i64_1) -> !cuda.result
    %275 = cuda.cast %274 : !cuda.result -> i32
    cuda.return_if_error %275 : i32
    return %c0_i32 : i32
  }
}
