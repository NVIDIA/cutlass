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
      %17 = cute.static : !cute.layout<"(2,4):(4,1)">
      %c-1_i32 = arith.constant -1 : i32
      %18 = cute.static : !cute.coord<"0">
      %19 = cute.static : !cute.layout<"(1,3,16):(1,16,1)">
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
      %c1_i32 = arith.constant 1 : i32
      %c5_i32 = arith.constant 5 : i32
      %c32_i32 = arith.constant 32 : i32
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
        scf.for %arg12 = %c0_i32 to %c6_i32 step %c1_i32  : i32 {
          %92 = nvvm.elect.sync -> i1
          scf.if %92 {
            %int_tuple_59 = cute.make_int_tuple(%arg12) : (i32) -> !cute.int_tuple<"?">
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
        scf.for %arg12 = %c0_i32 to %c2_i32 step %c1_i32  : i32 {
          %92 = nvvm.elect.sync -> i1
          scf.if %92 {
            %int_tuple_59 = cute.make_int_tuple(%arg12) : (i32) -> !cute.int_tuple<"?">
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
      %idx = cute.crd2idx(%coord, %19) : (!cute.coord<"(?,0,_)">, !cute.layout<"(1,3,16):(1,16,1)">) -> !cute.int_tuple<"?">
      %iter_49 = cute.get_iter(%arg11) : !memref_gmem_i64_1
      %ptr_50 = cute.add_offset(%iter_49, %idx) : (!cute.ptr<i64, gmem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, gmem>
      %85 = cute.ptrtoint(%ptr_50) : !cute.ptr<i64, gmem> to i64
      %iv = cute.assume(%85) : (i64) -> !cute.i64<divby 128>
      %86 = cute.inttoptr(%iv) : !cute.i64<divby 128> to !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, gmem, align<128>>
      %coord_51 = cute.make_coord(%84) : (i32) -> !cute.coord<"(?,1,_)">
      %idx_52 = cute.crd2idx(%coord_51, %19) : (!cute.coord<"(?,1,_)">, !cute.layout<"(1,3,16):(1,16,1)">) -> !cute.int_tuple<"?">
      %ptr_53 = cute.add_offset(%iter_49, %idx_52) : (!cute.ptr<i64, gmem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, gmem>
      %87 = cute.ptrtoint(%ptr_53) : !cute.ptr<i64, gmem> to i64
      %iv_54 = cute.assume(%87) : (i64) -> !cute.i64<divby 128>
      %88 = cute.inttoptr(%iv_54) : !cute.i64<divby 128> to !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, gmem, align<128>>
      %coord_55 = cute.make_coord(%84) : (i32) -> !cute.coord<"(?,2,_)">
      %idx_56 = cute.crd2idx(%coord_55, %19) : (!cute.coord<"(?,2,_)">, !cute.layout<"(1,3,16):(1,16,1)">) -> !cute.int_tuple<"?">
      %ptr_57 = cute.add_offset(%iter_49, %idx_56) : (!cute.ptr<i64, gmem>, !cute.int_tuple<"?">) -> !cute.ptr<i64, gmem>
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
        %95 = cute.get_hier_coord(%55, %lay) : (i32, !cute.layout<"(1,1,?):(0,0,1)">) -> !cute.coord<"(0,0,?)">
        %e0_63, %e1_64, %e2_65 = cute.get_leaves(%95) : !cute.coord<"(0,0,?)">
        %itup = cute.to_int_tuple(%e2_65) : !cute.coord<"?"> to !cute.int_tuple<"?">
        %mul = cute.tuple_mul(%itup, %38) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
        %96 = cute.get_scalars(%mul) : !cute.int_tuple<"?">
        %97:8 = scf.while (%arg12 = %false, %arg13 = %c0_i32, %arg14 = %96, %arg15 = %94, %arg16 = %c-1_i32, %arg17 = %c0_i32, %arg18 = %c0_i32, %arg19 = %55, %arg20 = %c0_i32) : (i1, i32, i32, i1, i32, i32, i32, i32, i32) -> (i1, i32, i32, i32, i32, i32, i32, i32) {
          scf.condition(%arg15) %arg12, %arg13, %arg14, %arg16, %arg17, %arg18, %arg19, %arg20 : i1, i32, i32, i32, i32, i32, i32, i32
        } do {
        ^bb0(%arg12: i1, %arg13: i32, %arg14: i32, %arg15: i32, %arg16: i32, %arg17: i32, %arg18: i32, %arg19: i32):
          %98 = nvvm.read.ptx.sreg.laneid range <i32, 0, 32> : i32
          %99 = arith.cmpi sge, %arg14, %arg17 : i32
          %100:3 = scf.while (%arg20 = %99, %arg21 = %arg16, %arg22 = %arg17, %arg23 = %arg17) : (i1, i32, i32, i32) -> (i32, i32, i32) {
            scf.condition(%arg20) %arg21, %arg22, %arg23 : i32, i32, i32
          } do {
          ^bb0(%arg20: i32, %arg21: i32, %arg22: i32):
            %129 = arith.addi %arg20, %98 : i32
            %130 = arith.cmpi slt, %129, %c2_i32 : i32
            %131 = scf.if %130 -> (i32) {
              %rmem_103 = cute.memref.alloca() : !memref_rmem_i32_
              %coord_104 = cute.make_coord(%129) : (i32) -> !cute.coord<"(?,_)">
              %idx_105 = cute.crd2idx(%coord_104, %17) : (!cute.coord<"(?,_)">, !cute.layout<"(2,4):(4,1)">) -> !cute.int_tuple<"?{div=4}">
              %iter_106 = cute.get_iter(%arg8) : !memref_gmem_i32_
              %ptr_107 = cute.add_offset(%iter_106, %idx_105) : (!cute.ptr<i32, gmem, align<16>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<i32, gmem, align<16>>
              %iter_108 = cute.get_iter(%rmem_103) : !memref_rmem_i32_
              %158 = cute.get_scalars(%38) : !cute.int_tuple<"1">
              scf.for %arg23 = %c0_i32 to %158 step %c1_i32  : i32 {
                %166 = builtin.unrealized_conversion_cast %ptr_107 : !cute.ptr<i32, gmem, align<16>> to !llvm.ptr<1>
                %167 = builtin.unrealized_conversion_cast %iter_108 : !cute.ptr<i32, rmem, align<32>> to !llvm.ptr
                %168 = llvm.load %166 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<4xi32>
                llvm.store %168, %167 {alignment = 16 : i64} : vector<4xi32>, !llvm.ptr
              } {llvm.loop_annotation = #loop_annotation}
              %159 = cute.memref.load(%rmem_103, %18) : (!memref_rmem_i32_, !cute.coord<"0">) -> i32
              %160 = arith.addi %159, %c127_i32 : i32
              %161 = arith.floordivsi %160, %c128_i32 : i32
              %162 = cute.memref.load(%rmem_103, %16) : (!memref_rmem_i32_, !cute.coord<"1">) -> i32
              %163 = arith.addi %162, %c127_i32 : i32
              %164 = arith.floordivsi %163, %c128_i32 : i32
              %165 = arith.muli %161, %164 : i32
              scf.yield %165 : i32
            } else {
              scf.yield %c0_i32 : i32
            }
            %132 = nvvm.shfl.sync  up %c-1_i32, %131, %c1_i32, %c0_i32 : i32 -> i32
            %133 = arith.cmpi sge, %98, %c1_i32 : i32
            %134 = scf.if %133 -> (i32) {
              %158 = arith.addi %131, %132 : i32
              scf.yield %158 : i32
            } else {
              scf.yield %131 : i32
            }
            %135 = nvvm.shfl.sync  up %c-1_i32, %134, %c2_i32, %c0_i32 : i32 -> i32
            %136 = arith.cmpi sge, %98, %c2_i32 : i32
            %137 = scf.if %136 -> (i32) {
              %158 = arith.addi %134, %135 : i32
              scf.yield %158 : i32
            } else {
              scf.yield %134 : i32
            }
            %138 = nvvm.shfl.sync  up %c-1_i32, %137, %c4_i32, %c0_i32 : i32 -> i32
            %139 = arith.cmpi sge, %98, %c4_i32 : i32
            %140 = scf.if %139 -> (i32) {
              %158 = arith.addi %137, %138 : i32
              scf.yield %158 : i32
            } else {
              scf.yield %137 : i32
            }
            %141 = nvvm.shfl.sync  up %c-1_i32, %140, %c8_i32, %c0_i32 : i32 -> i32
            %142 = arith.cmpi sge, %98, %c8_i32 : i32
            %143 = scf.if %142 -> (i32) {
              %158 = arith.addi %140, %141 : i32
              scf.yield %158 : i32
            } else {
              scf.yield %140 : i32
            }
            %144 = nvvm.shfl.sync  up %c-1_i32, %143, %c16_i32, %c0_i32 : i32 -> i32
            %145 = arith.cmpi sge, %98, %c16_i32 : i32
            %146 = scf.if %145 -> (i32) {
              %158 = arith.addi %143, %144 : i32
              scf.yield %158 : i32
            } else {
              scf.yield %143 : i32
            }
            %147 = arith.addi %146, %arg22 : i32
            %148 = arith.cmpi sge, %arg14, %147 : i32
            %149 = nvvm.vote.ballot.sync %c-1_i32, %148 : i32
            %150 = llvm.intr.ctpop(%149) : (i32) -> i32
            %151 = arith.cmpi eq, %150, %c32_i32 : i32
            %152 = arith.addi %150, %arg20 : i32
            %153 = arith.cmpi eq, %150, %c0_i32 : i32
            %154 = arith.cmpi eq, %153, %false : i1
            %155 = scf.if %154 -> (i32) {
              %158 = arith.subi %150, %c1_i32 : i32
              %159 = nvvm.shfl.sync  idx %c-1_i32, %147, %158, %c31_i32 : i32 -> i32
              scf.yield %159 : i32
            } else {
              scf.yield %arg22 : i32
            }
            %156 = arith.select %151, %c31_i32, %150 : i32
            %157 = nvvm.shfl.sync  idx %c-1_i32, %147, %156, %c31_i32 : i32 -> i32
            scf.yield %151, %152, %155, %157 : i1, i32, i32, i32
          }
          %rmem = cute.memref.alloca() : !memref_rmem_i32_
          %coord_66 = cute.make_coord(%100#0) : (i32) -> !cute.coord<"(?,_)">
          %idx_67 = cute.crd2idx(%coord_66, %17) : (!cute.coord<"(?,_)">, !cute.layout<"(2,4):(4,1)">) -> !cute.int_tuple<"?{div=4}">
          %iter_68 = cute.get_iter(%arg8) : !memref_gmem_i32_
          %ptr_69 = cute.add_offset(%iter_68, %idx_67) : (!cute.ptr<i32, gmem, align<16>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<i32, gmem, align<16>>
          %iter_70 = cute.get_iter(%rmem) : !memref_rmem_i32_
          %101 = cute.get_scalars(%38) : !cute.int_tuple<"1">
          scf.for %arg20 = %c0_i32 to %101 step %c1_i32  : i32 {
            %129 = builtin.unrealized_conversion_cast %ptr_69 : !cute.ptr<i32, gmem, align<16>> to !llvm.ptr<1>
            %130 = builtin.unrealized_conversion_cast %iter_70 : !cute.ptr<i32, rmem, align<32>> to !llvm.ptr
            %131 = llvm.load %129 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<4xi32>
            llvm.store %131, %130 {alignment = 16 : i64} : vector<4xi32>, !llvm.ptr
          } {llvm.loop_annotation = #loop_annotation}
          %102 = arith.subi %arg14, %100#1 : i32
          %103 = cute.memref.load(%rmem, %18) : (!memref_rmem_i32_, !cute.coord<"0">) -> i32
          %104 = cute.memref.load(%rmem, %16) : (!memref_rmem_i32_, !cute.coord<"1">) -> i32
          %105 = cute.memref.load(%rmem, %15) : (!memref_rmem_i32_, !cute.coord<"2">) -> i32
          %int_tuple_71 = cute.make_int_tuple(%103, %104, %105) : (i32, i32, i32) -> !cute.int_tuple<"(?,?,?)">
          %106:3 = cute.get_scalars(%int_tuple_71) <{only_dynamic}> : !cute.int_tuple<"(?,?,?)">
          %107 = arith.ceildivsi %106#0, %c128_i32 : i32
          %108 = arith.ceildivsi %106#1, %c128_i32 : i32
          %109 = arith.ceildivsi %106#2, %c64_i32 : i32
          %int_tuple_72 = cute.make_int_tuple(%107, %108, %109) : (i32, i32, i32) -> !cute.int_tuple<"(?,?,?)">
          %e0_73, %e1_74, %e2_75 = cute.get_leaves(%int_tuple_72) : !cute.int_tuple<"(?,?,?)">
          %110 = cute.get_scalars(%e2_75) : !cute.int_tuple<"?">
          %shape_76 = cute.make_shape(%e0_73, %e1_74) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.shape<"(?,?)">
          %lay_77 = cute.make_layout(%shape_76) : !cute.layout<"(?,?):(1,?)">
          %111 = cute.get_hier_coord(%102, %lay_77) : (i32, !cute.layout<"(?,?):(1,?)">) -> !cute.coord<"(?,?)">
          %e0_78, %e1_79 = cute.get_leaves(%111) : !cute.coord<"(?,?)">
          %itup_80 = cute.to_int_tuple(%e0_78) : !cute.coord<"?"> to !cute.int_tuple<"?">
          %itup_81 = cute.to_int_tuple(%e1_79) : !cute.coord<"?"> to !cute.int_tuple<"?">
          %mul_82 = cute.tuple_mul(%itup_80, %38) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
          %mul_83 = cute.tuple_mul(%itup_81, %38) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
          %112 = arith.cmpi ne, %100#0, %arg15 : i32
          %113 = scf.if %112 -> (i1) {
            %coord_103 = cute.make_coord(%100#0) : (i32) -> !cute.coord<"(?,0)">
            %129 = cute.memref.load(%arg10, %coord_103) : (!memref_gmem_i64_, !cute.coord<"(?,0)">) -> i64
            %iv_104 = cute.assume(%129) : (i64) -> !cute.i64<divby 16>
            %130 = cute.inttoptr(%iv_104) : !cute.i64<divby 16> to !cute.ptr<f16, gmem, align<16>>
            %coord_105 = cute.make_coord(%100#0) : (i32) -> !cute.coord<"(?,0,_)">
            %idx_106 = cute.crd2idx(%coord_105, %14) : (!cute.coord<"(?,0,_)">, !cute.layout<"(2,3,2):(6,2,1)">) -> !cute.int_tuple<"?{div=6}">
            %iter_107 = cute.get_iter(%arg9) : !memref_gmem_i32_1
            %ptr_108 = cute.add_offset(%iter_107, %idx_106) : (!cute.ptr<i32, gmem, align<16>>, !cute.int_tuple<"?{div=6}">) -> !cute.ptr<i32, gmem, align<8>>
            %rmem_109 = cute.memref.alloca() : !memref_rmem_i32_1
            %iter_110 = cute.get_iter(%rmem_109) : !memref_rmem_i32_1
            scf.for %arg20 = %c0_i32 to %101 step %c1_i32  : i32 {
              %139 = builtin.unrealized_conversion_cast %ptr_108 : !cute.ptr<i32, gmem, align<8>> to !llvm.ptr<1>
              %140 = builtin.unrealized_conversion_cast %iter_110 : !cute.ptr<i32, rmem, align<32>> to !llvm.ptr
              %141 = llvm.load %139 {alignment = 8 : i64} : !llvm.ptr<1> -> vector<2xi32>
              llvm.store %141, %140 {alignment = 8 : i64} : vector<2xi32>, !llvm.ptr
            } {llvm.loop_annotation = #loop_annotation}
            %131 = cute.memref.load(%rmem_109, %18) : (!memref_rmem_i32_1, !cute.coord<"0">) -> i32
            %132 = cute.memref.load(%rmem_109, %16) : (!memref_rmem_i32_1, !cute.coord<"1">) -> i32
            %shape_111 = cute.make_shape(%103, %105) : (i32, i32) -> !cute.shape<"(?,?,1)">
            %stride = cute.make_stride(%131, %132) : (i32, i32) -> !cute.stride<"(?,?,0)">
            %lay_112 = cute.make_layout(%shape_111, %stride) : !cute.layout<"(?,?,1):(?,?,0)">
            %view = cute.make_view(%130, %lay_112) : !memref_gmem_f16_
            %dyn_113 = cute.derefine(%view) : !memref_gmem_f16_ to !memref_gmem_f16_1
            %coord_114 = cute.make_coord(%100#0) : (i32) -> !cute.coord<"(?,1)">
            %133 = cute.memref.load(%arg10, %coord_114) : (!memref_gmem_i64_, !cute.coord<"(?,1)">) -> i64
            %iv_115 = cute.assume(%133) : (i64) -> !cute.i64<divby 16>
            %134 = cute.inttoptr(%iv_115) : !cute.i64<divby 16> to !cute.ptr<f16, gmem, align<16>>
            %coord_116 = cute.make_coord(%100#0) : (i32) -> !cute.coord<"(?,1,_)">
            %idx_117 = cute.crd2idx(%coord_116, %14) : (!cute.coord<"(?,1,_)">, !cute.layout<"(2,3,2):(6,2,1)">) -> !cute.int_tuple<"?{div=2}">
            %ptr_118 = cute.add_offset(%iter_107, %idx_117) : (!cute.ptr<i32, gmem, align<16>>, !cute.int_tuple<"?{div=2}">) -> !cute.ptr<i32, gmem, align<8>>
            %rmem_119 = cute.memref.alloca() : !memref_rmem_i32_1
            %iter_120 = cute.get_iter(%rmem_119) : !memref_rmem_i32_1
            scf.for %arg20 = %c0_i32 to %101 step %c1_i32  : i32 {
              %139 = builtin.unrealized_conversion_cast %ptr_118 : !cute.ptr<i32, gmem, align<8>> to !llvm.ptr<1>
              %140 = builtin.unrealized_conversion_cast %iter_120 : !cute.ptr<i32, rmem, align<32>> to !llvm.ptr
              %141 = llvm.load %139 {alignment = 8 : i64} : !llvm.ptr<1> -> vector<2xi32>
              llvm.store %141, %140 {alignment = 8 : i64} : vector<2xi32>, !llvm.ptr
            } {llvm.loop_annotation = #loop_annotation}
            %135 = cute.memref.load(%rmem_119, %18) : (!memref_rmem_i32_1, !cute.coord<"0">) -> i32
            %136 = cute.memref.load(%rmem_119, %16) : (!memref_rmem_i32_1, !cute.coord<"1">) -> i32
            %shape_121 = cute.make_shape(%104, %105) : (i32, i32) -> !cute.shape<"(?,?,1)">
            %stride_122 = cute.make_stride(%135, %136) : (i32, i32) -> !cute.stride<"(?,?,0)">
            %lay_123 = cute.make_layout(%shape_121, %stride_122) : !cute.layout<"(?,?,1):(?,?,0)">
            %view_124 = cute.make_view(%134, %lay_123) : !memref_gmem_f16_
            %dyn_125 = cute.derefine(%view_124) : !memref_gmem_f16_ to !memref_gmem_f16_1
            %137 = arith.cmpi eq, %arg12, %false : i1
            %138 = arith.select %137, %true, %arg12 : i1
            scf.if %137 {
              nvvm.barrier id = %c4_i32 number_of_threads = %c160_i32
            }
            scf.if %52 {
              cute_nvgpu.update_tma_desc(%arg1, %dyn_113, %iter_8) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>, !memref_gmem_f16_1, !cute.ptr<i64, smem, align<1024>>) -> ()
              cute_nvgpu.update_tma_desc(%arg3, %dyn_125, %ptr_9) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>, !memref_gmem_f16_1, !cute.ptr<i64, smem, align<128>>) -> ()
              %139 = nvvm.elect.sync -> i1
              scf.if %139 {
                nvvm.cp.async.bulk.commit.group
                nvvm.cp.async.bulk.wait_group 0 {read}
              }
              nvvm.bar.warp.sync %c-1_i32 : i32
              %140 = cute.ptrtoint(%86) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, gmem, align<128>> to i64
              %141 = cute.ptrtoint(%iter_8) : !cute.ptr<i64, smem, align<1024>> to i32
              llvm.inline_asm has_side_effects asm_dialect = att "tensormap.cp_fenceproxy.global.shared::cta.tensormap::generic.release.gpu.sync.aligned [$0], [$1], 128;", "l,r" %140, %141 : (i64, i32) -> ()
              %142 = cute.ptrtoint(%88) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, gmem, align<128>> to i64
              %143 = cute.ptrtoint(%ptr_9) : !cute.ptr<i64, smem, align<128>> to i32
              llvm.inline_asm has_side_effects asm_dialect = att "tensormap.cp_fenceproxy.global.shared::cta.tensormap::generic.release.gpu.sync.aligned [$0], [$1], 128;", "l,r" %142, %143 : (i64, i32) -> ()
            }
            scf.yield %138 : i1
          } else {
            scf.yield %arg12 : i1
          }
          %div_84 = cute.tuple_div(%mul_82, %38) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
          %coord_85 = cute.make_coord(%div_84) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,?,_,0)">
          %114:3 = cute.get_scalars(%lay_43) <{only_dynamic}> : !cute.layout<"(((64,128),1),?,?,?):(((1@0,1@1),0),128@1,64@0,1@2)">
          %shape_86 = cute.make_shape(%114#1) : (i32) -> !cute.shape<"(((64,128),1),?)">
          %lay_87 = cute.make_layout(%shape_86, %13) : !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">
          %idx_88 = cute.crd2idx(%coord_85, %lay_43) : (!cute.coord<"(_,?,_,0)">, !cute.layout<"(((64,128),1),?,?,?):(((1@0,1@1),0),128@1,64@0,1@2)">) -> !cute.int_tuple<"(0,?{div=128},0)">
          %tup = cute.add_offset(%26, %idx_88) : (!cute.int_tuple<"(0,0,0)">, !cute.int_tuple<"(0,?{div=128},0)">) -> !cute.int_tuple<"(0,?{div=128},0)">
          %coord_89 = cute.make_coord(%mul_83) : (!cute.int_tuple<"?">) -> !cute.coord<"(_,?,_,0)">
          %115:3 = cute.get_scalars(%lay_47) <{only_dynamic}> : !cute.layout<"(((64,128),1),?,?,?):(((1@0,1@1),0),128@1,64@0,1@2)">
          %shape_90 = cute.make_shape(%115#1) : (i32) -> !cute.shape<"(((64,128),1),?)">
          %lay_91 = cute.make_layout(%shape_90, %13) : !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">
          %idx_92 = cute.crd2idx(%coord_89, %lay_47) : (!cute.coord<"(_,?,_,0)">, !cute.layout<"(((64,128),1),?,?,?):(((1@0,1@1),0),128@1,64@0,1@2)">) -> !cute.int_tuple<"(0,?{div=128},0)">
          %tup_93 = cute.add_offset(%26, %idx_92) : (!cute.int_tuple<"(0,0,0)">, !cute.int_tuple<"(0,?{div=128},0)">) -> !cute.int_tuple<"(0,?{div=128},0)">
          %int_tuple_94 = cute.make_int_tuple(%arg13) : (i32) -> !cute.int_tuple<"?">
          %tup_95 = cute.add_offset(%int_tuple_94, %e2_75) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.int_tuple<"?">
          %116 = cute.get_scalars(%tup_95) : !cute.int_tuple<"?">
          %117 = arith.remsi %arg13, %c6_i32 : i32
          %118 = arith.floordivsi %arg13, %c6_i32 : i32
          %119 = arith.remsi %118, %c2_i32 : i32
          %120 = arith.xori %119, %c1_i32 : i32
          %121 = arith.cmpi sgt, %110, %c0_i32 : i32
          %int_tuple_96 = cute.make_int_tuple(%117) : (i32) -> !cute.int_tuple<"?">
          %ptr_97 = cute.add_offset(%iter_13, %int_tuple_96) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
          %122 = scf.if %121 -> (i1) {
            %129 = builtin.unrealized_conversion_cast %ptr_97 : !cute.ptr<i64, smem> to !llvm.ptr<3>
            %130 = nvvm.mbarrier.wait.parity %129, %120 {kind = #nvvm.mbar_wait<try>} : !llvm.ptr<3>, i32 -> i1
            scf.yield %130 : i1
          } else {
            scf.yield %true : i1
          }
          scf.if %112 {
            %129 = cute.ptrtoint(%86) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, gmem, align<128>> to i64
            llvm.inline_asm has_side_effects asm_dialect = att "fence.proxy.tensormap::generic.acquire.gpu [$0], 128;", "l" %129 : (i64) -> ()
            %130 = cute.ptrtoint(%88) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, gmem, align<128>> to i64
            llvm.inline_asm has_side_effects asm_dialect = att "fence.proxy.tensormap::generic.acquire.gpu [$0], 128;", "l" %130 : (i64) -> ()
          }
          %123:4 = scf.for %arg20 = %c0_i32 to %110 step %c1_i32 iter_args(%arg21 = %122, %arg22 = %c0_i32, %arg23 = %117, %arg24 = %120) -> (i1, i32, i32, i32)  : i32 {
            %129 = arith.addi %arg22, %c1_i32 : i32
            %130 = arith.addi %arg13, %129 : i32
            %131 = arith.remsi %130, %c6_i32 : i32
            %132 = arith.cmpi eq, %131, %c0_i32 : i32
            %133 = arith.xori %arg24, %c1_i32 : i32
            %134 = arith.select %132, %133, %arg24 : i32
            %int_tuple_103 = cute.make_int_tuple(%arg23) : (i32) -> !cute.int_tuple<"?">
            %ptr_104 = cute.add_offset(%iter_12, %int_tuple_103) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
            %135 = arith.extui %arg21 : i1 to i32
            %136 = arith.cmpi eq, %135, %c0_i32 : i32
            scf.if %136 {
              %ptr_126 = cute.add_offset(%iter_13, %int_tuple_103) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
              %150 = builtin.unrealized_conversion_cast %ptr_126 : !cute.ptr<i64, smem> to !llvm.ptr<3>
              nvvm.mbarrier.try_wait.parity.shared %150, %arg24, %c10000000_i32 : !llvm.ptr<3>, i32, i32
            }
            %137 = nvvm.elect.sync -> i1
            scf.if %137 {
              %150 = builtin.unrealized_conversion_cast %ptr_104 : !cute.ptr<i64, smem> to !llvm.ptr<3>
              nvvm.mbarrier.txn %150, %c32768_i32 {kind = #nvvm.mbar_txn_kind<arrive_expect_tx>} : !llvm.ptr<3>, i32
            }
            %coord_105 = cute.make_coord(%arg22) : (i32) -> !cute.coord<"(_,?)">
            %idx_106 = cute.crd2idx(%coord_105, %lay_87) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
            %tup_107 = cute.add_offset(%tup, %idx_106) : (!cute.int_tuple<"(0,?{div=128},0)">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.int_tuple<"(?{div=64},?{div=128},0)">
            %e0_108, %e1_109, %e2_110 = cute.get_leaves(%tup_107) : !cute.int_tuple<"(?{div=64},?{div=128},0)">
            %coord_111 = cute.make_coord(%arg23) : (i32) -> !cute.coord<"(_,?)">
            %idx_112 = cute.crd2idx(%coord_111, %12) : (!cute.coord<"(_,?)">, !cute.layout<"((8192,1),6):((1,0),8192)">) -> !cute.int_tuple<"?{div=8192}">
            %ptr_113 = cute.add_offset(%iter_17, %idx_112) : (!cute.ptr<f16, smem, align<1024>, S<3,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<f16, smem, align<1024>, S<3,4,3>>
            %138 = cute.ptrtoint(%86) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, gmem, align<128>> to i64
            %iv_114 = cute.assume(%138) : (i64) -> !cute.i64<divby 128>
            %139 = cute.inttoptr(%iv_114) : !cute.i64<divby 128> to !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<128>>
            %int_tuple_115 = cute.make_int_tuple(%e0_108, %e1_109) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=128}">) -> !cute.int_tuple<"(?{div=64},?{div=128},0)">
            %140 = cute_nvgpu.atom.make_exec_tma(%arg1) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>
            %141 = cute_nvgpu.atom.set_value(%140, %ptr_104 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>
            %142 = cute_nvgpu.atom.set_value(%141, %139 : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<128>>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_descriptor_ptr>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>
            scf.for %arg25 = %c0_i32 to %101 step %c1_i32  : i32 {
              %150 = cute_nvgpu.atom.get_value(%142 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
              %TMADescAddr = cute_nvgpu.get_tma_desc_addr(%142 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>) -> !cute.ptr<generic, align<64>>
              %151:3 = cute.get_scalars(%int_tuple_115) : !cute.int_tuple<"(?{div=64},?{div=128},0)">
              cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr : !cute.ptr<generic, align<64>>, %ptr_113 : !cute.ptr<f16, smem, align<1024>, S<3,4,3>>, %150 : !cute.ptr<smem, align<8>>, [%151#0, %151#1, %151#2] : i32, i32, i32) mode = <tiled> num_cta = 1 : i32
            } {llvm.loop_annotation = #loop_annotation}
            %idx_116 = cute.crd2idx(%coord_105, %lay_91) : (!cute.coord<"(_,?)">, !cute.layout<"(((64,128),1),?):(((1@0,1@1),0),64@0)">) -> !cute.int_tuple<"(?{div=64},0)">
            %tup_117 = cute.add_offset(%tup_93, %idx_116) : (!cute.int_tuple<"(0,?{div=128},0)">, !cute.int_tuple<"(?{div=64},0)">) -> !cute.int_tuple<"(?{div=64},?{div=128},0)">
            %e0_118, %e1_119, %e2_120 = cute.get_leaves(%tup_117) : !cute.int_tuple<"(?{div=64},?{div=128},0)">
            %ptr_121 = cute.add_offset(%iter_18, %idx_112) : (!cute.ptr<f16, smem, align<1024>, S<3,4,3>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<f16, smem, align<1024>, S<3,4,3>>
            %143 = cute.ptrtoint(%88) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, gmem, align<128>> to i64
            %iv_122 = cute.assume(%143) : (i64) -> !cute.i64<divby 128>
            %144 = cute.inttoptr(%iv_122) : !cute.i64<divby 128> to !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<128>>
            %int_tuple_123 = cute.make_int_tuple(%e0_118, %e1_119) : (!cute.int_tuple<"?{div=64}">, !cute.int_tuple<"?{div=128}">) -> !cute.int_tuple<"(?{div=64},?{div=128},0)">
            %145 = cute_nvgpu.atom.make_exec_tma(%arg3) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>
            %146 = cute_nvgpu.atom.set_value(%145, %ptr_104 : !cute.ptr<i64, smem>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>
            %147 = cute_nvgpu.atom.set_value(%146, %144 : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<128>>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_descriptor_ptr>} : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>
            scf.for %arg25 = %c0_i32 to %101 step %c1_i32  : i32 {
              %150 = cute_nvgpu.atom.get_value(%147 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>) {field = #cute_nvgpu.atom_copy_field_tmaload<tma_bar>} : !cute.ptr<smem, align<8>>
              %TMADescAddr = cute_nvgpu.get_tma_desc_addr(%147 : !cute_nvgpu.atom.tma_load<f16, copy_bits = 131072, mode = tiled, num_cta = 1, g_stride = <"()"> tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">>) -> !cute.ptr<generic, align<64>>
              %151:3 = cute.get_scalars(%int_tuple_123) : !cute.int_tuple<"(?{div=64},?{div=128},0)">
              cute_nvgpu.arch.copy.SM100.tma_load(%TMADescAddr : !cute.ptr<generic, align<64>>, %ptr_121 : !cute.ptr<f16, smem, align<1024>, S<3,4,3>>, %150 : !cute.ptr<smem, align<8>>, [%151#0, %151#1, %151#2] : i32, i32, i32) mode = <tiled> num_cta = 1 : i32
            } {llvm.loop_annotation = #loop_annotation}
            %148 = arith.cmpi sgt, %110, %129 : i32
            %int_tuple_124 = cute.make_int_tuple(%131) : (i32) -> !cute.int_tuple<"?">
            %ptr_125 = cute.add_offset(%iter_13, %int_tuple_124) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
            %149 = scf.if %148 -> (i1) {
              %150 = builtin.unrealized_conversion_cast %ptr_125 : !cute.ptr<i64, smem> to !llvm.ptr<3>
              %151 = nvvm.mbarrier.wait.parity %150, %134 {kind = #nvvm.mbar_wait<try>} : !llvm.ptr<3>, i32 -> i1
              scf.yield %151 : i1
            } else {
              scf.yield %true : i1
            }
            scf.yield %149, %129, %131, %134 : i1, i32, i32, i32
          } {loop_annotation = #loop_annotation1}
          %124 = arith.addi %arg18, %92 : i32
          %125 = arith.addi %arg19, %c1_i32 : i32
          %126 = arith.cmpi sgt, %93, %124 : i32
          %127 = cute.get_hier_coord(%124, %lay) : (i32, !cute.layout<"(1,1,?):(0,0,1)">) -> !cute.coord<"(0,0,?)">
          %e0_98, %e1_99, %e2_100 = cute.get_leaves(%127) : !cute.coord<"(0,0,?)">
          %itup_101 = cute.to_int_tuple(%e2_100) : !cute.coord<"?"> to !cute.int_tuple<"?">
          %mul_102 = cute.tuple_mul(%itup_101, %38) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
          %128 = cute.get_scalars(%mul_102) : !cute.int_tuple<"?">
          scf.yield %113, %116, %128, %126, %100#0, %100#0, %100#1, %124, %125 : i1, i32, i32, i1, i32, i32, i32, i32, i32
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
        %95 = cute.get_hier_coord(%55, %lay) : (i32, !cute.layout<"(1,1,?):(0,0,1)">) -> !cute.coord<"(0,0,?)">
        %e0_63, %e1_64, %e2_65 = cute.get_leaves(%95) : !cute.coord<"(0,0,?)">
        %itup = cute.to_int_tuple(%e2_65) : !cute.coord<"?"> to !cute.int_tuple<"?">
        %mul = cute.tuple_mul(%itup, %38) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
        %96 = cute.get_scalars(%mul) : !cute.int_tuple<"?">
        %97:7 = scf.while (%arg12 = %c0_i32, %arg13 = %96, %arg14 = %94, %arg15 = %c0_i32, %arg16 = %c0_i32, %arg17 = %arg0, %arg18 = %55, %arg19 = %c0_i32) : (i32, i32, i1, i32, i32, !mma_f16_f16_f32_128x128x16_, i32, i32) -> (i32, i32, i32, i32, !mma_f16_f16_f32_128x128x16_, i32, i32) {
          scf.condition(%arg14) %arg12, %arg13, %arg15, %arg16, %arg17, %arg18, %arg19 : i32, i32, i32, i32, !mma_f16_f16_f32_128x128x16_, i32, i32
        } do {
        ^bb0(%arg12: i32, %arg13: i32, %arg14: i32, %arg15: i32, %arg16: !mma_f16_f16_f32_128x128x16_, %arg17: i32, %arg18: i32):
          %98 = nvvm.read.ptx.sreg.laneid range <i32, 0, 32> : i32
          %99 = arith.cmpi sge, %arg13, %arg15 : i32
          %100:3 = scf.while (%arg19 = %99, %arg20 = %arg14, %arg21 = %arg15, %arg22 = %arg15) : (i1, i32, i32, i32) -> (i32, i32, i32) {
            scf.condition(%arg19) %arg20, %arg21, %arg22 : i32, i32, i32
          } do {
          ^bb0(%arg19: i32, %arg20: i32, %arg21: i32):
            %127 = arith.addi %arg19, %98 : i32
            %128 = arith.cmpi slt, %127, %c2_i32 : i32
            %129 = scf.if %128 -> (i32) {
              %rmem_83 = cute.memref.alloca() : !memref_rmem_i32_
              %coord_84 = cute.make_coord(%127) : (i32) -> !cute.coord<"(?,_)">
              %idx_85 = cute.crd2idx(%coord_84, %17) : (!cute.coord<"(?,_)">, !cute.layout<"(2,4):(4,1)">) -> !cute.int_tuple<"?{div=4}">
              %iter_86 = cute.get_iter(%arg8) : !memref_gmem_i32_
              %ptr_87 = cute.add_offset(%iter_86, %idx_85) : (!cute.ptr<i32, gmem, align<16>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<i32, gmem, align<16>>
              %iter_88 = cute.get_iter(%rmem_83) : !memref_rmem_i32_
              %156 = cute.get_scalars(%38) : !cute.int_tuple<"1">
              scf.for %arg22 = %c0_i32 to %156 step %c1_i32  : i32 {
                %164 = builtin.unrealized_conversion_cast %ptr_87 : !cute.ptr<i32, gmem, align<16>> to !llvm.ptr<1>
                %165 = builtin.unrealized_conversion_cast %iter_88 : !cute.ptr<i32, rmem, align<32>> to !llvm.ptr
                %166 = llvm.load %164 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<4xi32>
                llvm.store %166, %165 {alignment = 16 : i64} : vector<4xi32>, !llvm.ptr
              } {llvm.loop_annotation = #loop_annotation}
              %157 = cute.memref.load(%rmem_83, %18) : (!memref_rmem_i32_, !cute.coord<"0">) -> i32
              %158 = arith.addi %157, %c127_i32 : i32
              %159 = arith.floordivsi %158, %c128_i32 : i32
              %160 = cute.memref.load(%rmem_83, %16) : (!memref_rmem_i32_, !cute.coord<"1">) -> i32
              %161 = arith.addi %160, %c127_i32 : i32
              %162 = arith.floordivsi %161, %c128_i32 : i32
              %163 = arith.muli %159, %162 : i32
              scf.yield %163 : i32
            } else {
              scf.yield %c0_i32 : i32
            }
            %130 = nvvm.shfl.sync  up %c-1_i32, %129, %c1_i32, %c0_i32 : i32 -> i32
            %131 = arith.cmpi sge, %98, %c1_i32 : i32
            %132 = scf.if %131 -> (i32) {
              %156 = arith.addi %129, %130 : i32
              scf.yield %156 : i32
            } else {
              scf.yield %129 : i32
            }
            %133 = nvvm.shfl.sync  up %c-1_i32, %132, %c2_i32, %c0_i32 : i32 -> i32
            %134 = arith.cmpi sge, %98, %c2_i32 : i32
            %135 = scf.if %134 -> (i32) {
              %156 = arith.addi %132, %133 : i32
              scf.yield %156 : i32
            } else {
              scf.yield %132 : i32
            }
            %136 = nvvm.shfl.sync  up %c-1_i32, %135, %c4_i32, %c0_i32 : i32 -> i32
            %137 = arith.cmpi sge, %98, %c4_i32 : i32
            %138 = scf.if %137 -> (i32) {
              %156 = arith.addi %135, %136 : i32
              scf.yield %156 : i32
            } else {
              scf.yield %135 : i32
            }
            %139 = nvvm.shfl.sync  up %c-1_i32, %138, %c8_i32, %c0_i32 : i32 -> i32
            %140 = arith.cmpi sge, %98, %c8_i32 : i32
            %141 = scf.if %140 -> (i32) {
              %156 = arith.addi %138, %139 : i32
              scf.yield %156 : i32
            } else {
              scf.yield %138 : i32
            }
            %142 = nvvm.shfl.sync  up %c-1_i32, %141, %c16_i32, %c0_i32 : i32 -> i32
            %143 = arith.cmpi sge, %98, %c16_i32 : i32
            %144 = scf.if %143 -> (i32) {
              %156 = arith.addi %141, %142 : i32
              scf.yield %156 : i32
            } else {
              scf.yield %141 : i32
            }
            %145 = arith.addi %144, %arg21 : i32
            %146 = arith.cmpi sge, %arg13, %145 : i32
            %147 = nvvm.vote.ballot.sync %c-1_i32, %146 : i32
            %148 = llvm.intr.ctpop(%147) : (i32) -> i32
            %149 = arith.cmpi eq, %148, %c32_i32 : i32
            %150 = arith.addi %148, %arg19 : i32
            %151 = arith.cmpi eq, %148, %c0_i32 : i32
            %152 = arith.cmpi eq, %151, %false : i1
            %153 = scf.if %152 -> (i32) {
              %156 = arith.subi %148, %c1_i32 : i32
              %157 = nvvm.shfl.sync  idx %c-1_i32, %145, %156, %c31_i32 : i32 -> i32
              scf.yield %157 : i32
            } else {
              scf.yield %arg21 : i32
            }
            %154 = arith.select %149, %c31_i32, %148 : i32
            %155 = nvvm.shfl.sync  idx %c-1_i32, %145, %154, %c31_i32 : i32 -> i32
            scf.yield %149, %150, %153, %155 : i1, i32, i32, i32
          }
          %rmem = cute.memref.alloca() : !memref_rmem_i32_
          %coord_66 = cute.make_coord(%100#0) : (i32) -> !cute.coord<"(?,_)">
          %idx_67 = cute.crd2idx(%coord_66, %17) : (!cute.coord<"(?,_)">, !cute.layout<"(2,4):(4,1)">) -> !cute.int_tuple<"?{div=4}">
          %iter_68 = cute.get_iter(%arg8) : !memref_gmem_i32_
          %ptr_69 = cute.add_offset(%iter_68, %idx_67) : (!cute.ptr<i32, gmem, align<16>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<i32, gmem, align<16>>
          %iter_70 = cute.get_iter(%rmem) : !memref_rmem_i32_
          %101 = cute.get_scalars(%38) : !cute.int_tuple<"1">
          scf.for %arg19 = %c0_i32 to %101 step %c1_i32  : i32 {
            %127 = builtin.unrealized_conversion_cast %ptr_69 : !cute.ptr<i32, gmem, align<16>> to !llvm.ptr<1>
            %128 = builtin.unrealized_conversion_cast %iter_70 : !cute.ptr<i32, rmem, align<32>> to !llvm.ptr
            %129 = llvm.load %127 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<4xi32>
            llvm.store %129, %128 {alignment = 16 : i64} : vector<4xi32>, !llvm.ptr
          } {llvm.loop_annotation = #loop_annotation}
          %102 = cute.memref.load(%rmem, %15) : (!memref_rmem_i32_, !cute.coord<"2">) -> i32
          %103 = arith.addi %102, %c63_i32 : i32
          %104 = arith.floordivsi %103, %c64_i32 : i32
          %105 = arith.remsi %arg18, %c2_i32 : i32
          %coord_71 = cute.make_coord(%105) : (i32) -> !cute.coord<"(_,_,_,?)">
          %idx_72 = cute.crd2idx(%coord_71, %11) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((128,128),1,1,2):((65536,1),0,0,128)">) -> !cute.int_tuple<"?{div=128}">
          %ptr_73 = cute.add_offset(%tmem_ptr, %idx_72) : (!cute.ptr<f32, tmem, align<16>>, !cute.int_tuple<"?{div=128}">) -> !cute.ptr<f32, tmem, align<16>>
          %106 = arith.addi %arg12, %104 : i32
          %107 = arith.remsi %arg12, %c6_i32 : i32
          %108 = arith.cmpi sgt, %104, %c0_i32 : i32
          %109 = arith.extui %108 : i1 to i32
          %110 = arith.select %108, %c1_i32, %109 : i32
          %111 = arith.cmpi ne, %110, %c0_i32 : i32
          %112 = arith.floordivsi %arg12, %c6_i32 : i32
          %113 = arith.remsi %112, %c2_i32 : i32
          %int_tuple_74 = cute.make_int_tuple(%107) : (i32) -> !cute.int_tuple<"?">
          %ptr_75 = cute.add_offset(%iter_12, %int_tuple_74) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
          %114 = scf.if %111 -> (i1) {
            %127 = builtin.unrealized_conversion_cast %ptr_75 : !cute.ptr<i64, smem> to !llvm.ptr<3>
            %128 = nvvm.mbarrier.wait.parity %127, %113 {kind = #nvvm.mbar_wait<try>} : !llvm.ptr<3>, i32 -> i1
            scf.yield %128 : i1
          } else {
            scf.yield %true : i1
          }
          %115 = arith.floordivsi %arg18, %c2_i32 : i32
          %116 = arith.remsi %115, %c2_i32 : i32
          %117 = arith.xori %116, %c1_i32 : i32
          %int_tuple_76 = cute.make_int_tuple(%105) : (i32) -> !cute.int_tuple<"?">
          %ptr_77 = cute.add_offset(%iter_15, %int_tuple_76) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
          %118 = builtin.unrealized_conversion_cast %ptr_77 : !cute.ptr<i64, smem> to !llvm.ptr<3>
          nvvm.mbarrier.try_wait.parity.shared %118, %117, %c10000000_i32 : !llvm.ptr<3>, i32, i32
          %119 = cute_nvgpu.atom.set_value(%arg16, %false : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_f16_f16_f32_128x128x16_
          %120:4 = scf.for %arg19 = %c0_i32 to %104 step %c1_i32 iter_args(%arg20 = %114, %arg21 = %107, %arg22 = %113, %arg23 = %119) -> (i1, i32, i32, !mma_f16_f16_f32_128x128x16_)  : i32 {
            %127 = arith.addi %arg19, %c1_i32 : i32
            %128 = arith.addi %arg12, %127 : i32
            %129 = arith.remsi %128, %c6_i32 : i32
            %130 = arith.cmpi eq, %129, %c0_i32 : i32
            %131 = arith.xori %arg22, %c1_i32 : i32
            %132 = arith.select %130, %131, %arg22 : i32
            %133 = arith.extui %arg20 : i1 to i32
            %134 = arith.cmpi eq, %133, %c0_i32 : i32
            scf.if %134 {
              %int_tuple_85 = cute.make_int_tuple(%arg21) : (i32) -> !cute.int_tuple<"?">
              %ptr_86 = cute.add_offset(%iter_12, %int_tuple_85) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
              %142 = builtin.unrealized_conversion_cast %ptr_86 : !cute.ptr<i64, smem> to !llvm.ptr<3>
              nvvm.mbarrier.try_wait.parity.shared %142, %arg22, %c10000000_i32 : !llvm.ptr<3>, i32, i32
            }
            %135 = scf.for %arg24 = %c0_i32 to %c4_i32 step %c1_i32 iter_args(%arg25 = %arg23) -> (!mma_f16_f16_f32_128x128x16_)  : i32 {
              %coord_85 = cute.make_coord(%arg24, %arg21) : (i32, i32) -> !cute.coord<"(_,_,?,?)">
              %idx_86 = cute.crd2idx(%coord_85, %10) : (!cute.coord<"(_,_,?,?)">, !cute.layout<"(1,1,4,6):(0,0,2,1024)">) -> !cute.int_tuple<"?{div=2}">
              %tup = cute.add_offset(%ummaSmemDesc, %idx_86) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
              %tup_87 = cute.add_offset(%ummaSmemDesc_48, %idx_86) : (!cute_nvgpu.smem_desc, !cute.int_tuple<"?{div=2}">) -> !cute_nvgpu.smem_desc
              scf.for %arg26 = %c0_i32 to %101 step %c1_i32  : i32 {
                scf.for %arg27 = %c0_i32 to %101 step %c1_i32  : i32 {
                  scf.for %arg28 = %c0_i32 to %101 step %c1_i32  : i32 {
                    %143 = cute_nvgpu.atom.get_value(%arg25 : !mma_f16_f16_f32_128x128x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_a>} : i1
                    %144 = cute_nvgpu.atom.get_value(%arg25 : !mma_f16_f16_f32_128x128x16_) {field = #cute_nvgpu.atom_mma_field_sm100<neg_b>} : i1
                    %145 = cute_nvgpu.atom.get_value(%arg25 : !mma_f16_f16_f32_128x128x16_) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : i1
                    %146 = arith.extui %143 : i1 to i32
                    %147 = arith.extui %144 : i1 to i32
                    %148 = arith.shli %146, %c13_i32 : i32
                    %149 = arith.shli %147, %c14_i32 : i32
                    %150 = arith.ori %148, %c136314896_i32 : i32
                    %151 = arith.ori %150, %149 : i32
                    cute_nvgpu.arch.mma.SM100.umma(%tup, %tup_87, %ptr_73, %151, %145) {num_cta = 1 : i32, scale = 0 : i32, a_type = f16} : (!cute_nvgpu.smem_desc, !cute_nvgpu.smem_desc, !cute.ptr<f32, tmem, align<16>>, i32, i1) -> ()
                  } {llvm.loop_annotation = #loop_annotation}
                } {llvm.loop_annotation = #loop_annotation}
              } {llvm.loop_annotation = #loop_annotation}
              %142 = cute_nvgpu.atom.set_value(%arg25, %true : i1) {field = #cute_nvgpu.atom_mma_field_sm100<accum_c>} : !mma_f16_f16_f32_128x128x16_
              scf.yield %142 : !mma_f16_f16_f32_128x128x16_
            } {loop_annotation = #loop_annotation2}
            %136 = nvvm.elect.sync -> i1
            scf.if %136 {
              %int_tuple_85 = cute.make_int_tuple(%arg21) : (i32) -> !cute.int_tuple<"?">
              %ptr_86 = cute.add_offset(%iter_13, %int_tuple_85) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
              %142 = builtin.unrealized_conversion_cast %ptr_86 : !cute.ptr<i64, smem> to !llvm.ptr<3>
              nvvm.tcgen05.commit.arrive %142 : !llvm.ptr<3>
            }
            %137 = arith.cmpi slt, %127, %104 : i32
            %138 = arith.extui %137 : i1 to i32
            %139 = arith.select %137, %c1_i32, %138 : i32
            %140 = arith.cmpi ne, %139, %c0_i32 : i32
            %int_tuple_83 = cute.make_int_tuple(%129) : (i32) -> !cute.int_tuple<"?">
            %ptr_84 = cute.add_offset(%iter_12, %int_tuple_83) : (!cute.ptr<i64, smem, align<128>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
            %141 = scf.if %140 -> (i1) {
              %142 = builtin.unrealized_conversion_cast %ptr_84 : !cute.ptr<i64, smem> to !llvm.ptr<3>
              %143 = nvvm.mbarrier.wait.parity %142, %132 {kind = #nvvm.mbar_wait<try>} : !llvm.ptr<3>, i32 -> i1
              scf.yield %143 : i1
            } else {
              scf.yield %true : i1
            }
            scf.yield %141, %129, %132, %135 : i1, i32, i32, !mma_f16_f16_f32_128x128x16_
          }
          %121 = nvvm.elect.sync -> i1
          scf.if %121 {
            %ptr_83 = cute.add_offset(%iter_14, %int_tuple_76) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
            %127 = builtin.unrealized_conversion_cast %ptr_83 : !cute.ptr<i64, smem> to !llvm.ptr<3>
            nvvm.tcgen05.commit.arrive %127 : !llvm.ptr<3>
          }
          %122 = arith.addi %arg17, %92 : i32
          %123 = arith.addi %arg18, %c1_i32 : i32
          %124 = arith.cmpi sgt, %93, %122 : i32
          %125 = cute.get_hier_coord(%122, %lay) : (i32, !cute.layout<"(1,1,?):(0,0,1)">) -> !cute.coord<"(0,0,?)">
          %e0_78, %e1_79, %e2_80 = cute.get_leaves(%125) : !cute.coord<"(0,0,?)">
          %itup_81 = cute.to_int_tuple(%e2_80) : !cute.coord<"?"> to !cute.int_tuple<"?">
          %mul_82 = cute.tuple_mul(%itup_81, %38) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
          %126 = cute.get_scalars(%mul_82) : !cute.int_tuple<"?">
          scf.yield %106, %126, %124, %100#0, %100#1, %120#3, %122, %123 : i32, i32, i1, i32, i32, !mma_f16_f16_f32_128x128x16_, i32, i32
        }
      }
      %91 = arith.cmpi slt, %51, %c4_i32 : i32
      scf.if %91 {
        scf.if %56 {
          %110 = nvvm.elect.sync -> i1
          scf.if %110 {
            cute_nvgpu.copy_tma_desc(%arg1, %iter_8) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>, !cute.ptr<i64, smem, align<1024>>) -> ()
          }
        }
        nvvm.bar.warp.sync %c-1_i32 : i32
        scf.if %56 {
          %110 = nvvm.elect.sync -> i1
          scf.if %110 {
            cute_nvgpu.copy_tma_desc(%arg3, %ptr_9) : (!cute_nvgpu.atom.non_exec_tiled_tma_load<sm_90, f16, copy_bits = 131072, tma_gbasis = <"(64,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>, !cute.ptr<i64, smem, align<128>>) -> ()
          }
        }
        nvvm.bar.warp.sync %c-1_i32 : i32
        nvvm.barrier id = %c4_i32 number_of_threads = %c160_i32
        scf.if %56 {
          %110 = nvvm.elect.sync -> i1
          scf.if %110 {
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
        %107 = cute.get_hier_coord(%55, %lay) : (i32, !cute.layout<"(1,1,?):(0,0,1)">) -> !cute.coord<"(0,0,?)">
        %e0_81, %e1_82, %e2_83 = cute.get_leaves(%107) : !cute.coord<"(0,0,?)">
        %itup = cute.to_int_tuple(%e2_83) : !cute.coord<"?"> to !cute.int_tuple<"?">
        %mul = cute.tuple_mul(%itup, %38) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
        %108 = cute.get_scalars(%mul) : !cute.int_tuple<"?">
        %109:7 = scf.while (%arg12 = %c0_i32, %arg13 = %108, %arg14 = %106, %arg15 = %c-1_i32, %arg16 = %c0_i32, %arg17 = %c0_i32, %arg18 = %55, %arg19 = %c0_i32) : (i32, i32, i1, i32, i32, i32, i32, i32) -> (i32, i32, i32, i32, i32, i32, i32) {
          scf.condition(%arg14) %arg12, %arg13, %arg15, %arg16, %arg17, %arg18, %arg19 : i32, i32, i32, i32, i32, i32, i32
        } do {
        ^bb0(%arg12: i32, %arg13: i32, %arg14: i32, %arg15: i32, %arg16: i32, %arg17: i32, %arg18: i32):
          %110 = nvvm.read.ptx.sreg.laneid range <i32, 0, 32> : i32
          %111 = arith.cmpi sge, %arg13, %arg16 : i32
          %112:3 = scf.while (%arg19 = %111, %arg20 = %arg15, %arg21 = %arg16, %arg22 = %arg16) : (i1, i32, i32, i32) -> (i32, i32, i32) {
            scf.condition(%arg19) %arg20, %arg21, %arg22 : i32, i32, i32
          } do {
          ^bb0(%arg19: i32, %arg20: i32, %arg21: i32):
            %136 = arith.addi %arg19, %110 : i32
            %137 = arith.cmpi slt, %136, %c2_i32 : i32
            %138 = scf.if %137 -> (i32) {
              %rmem_118 = cute.memref.alloca() : !memref_rmem_i32_
              %coord_119 = cute.make_coord(%136) : (i32) -> !cute.coord<"(?,_)">
              %idx_120 = cute.crd2idx(%coord_119, %17) : (!cute.coord<"(?,_)">, !cute.layout<"(2,4):(4,1)">) -> !cute.int_tuple<"?{div=4}">
              %iter_121 = cute.get_iter(%arg8) : !memref_gmem_i32_
              %ptr_122 = cute.add_offset(%iter_121, %idx_120) : (!cute.ptr<i32, gmem, align<16>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<i32, gmem, align<16>>
              %iter_123 = cute.get_iter(%rmem_118) : !memref_rmem_i32_
              %165 = cute.get_scalars(%38) : !cute.int_tuple<"1">
              scf.for %arg22 = %c0_i32 to %165 step %c1_i32  : i32 {
                %173 = builtin.unrealized_conversion_cast %ptr_122 : !cute.ptr<i32, gmem, align<16>> to !llvm.ptr<1>
                %174 = builtin.unrealized_conversion_cast %iter_123 : !cute.ptr<i32, rmem, align<32>> to !llvm.ptr
                %175 = llvm.load %173 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<4xi32>
                llvm.store %175, %174 {alignment = 16 : i64} : vector<4xi32>, !llvm.ptr
              } {llvm.loop_annotation = #loop_annotation}
              %166 = cute.memref.load(%rmem_118, %18) : (!memref_rmem_i32_, !cute.coord<"0">) -> i32
              %167 = arith.addi %166, %c127_i32 : i32
              %168 = arith.floordivsi %167, %c128_i32 : i32
              %169 = cute.memref.load(%rmem_118, %16) : (!memref_rmem_i32_, !cute.coord<"1">) -> i32
              %170 = arith.addi %169, %c127_i32 : i32
              %171 = arith.floordivsi %170, %c128_i32 : i32
              %172 = arith.muli %168, %171 : i32
              scf.yield %172 : i32
            } else {
              scf.yield %c0_i32 : i32
            }
            %139 = nvvm.shfl.sync  up %c-1_i32, %138, %c1_i32, %c0_i32 : i32 -> i32
            %140 = arith.cmpi sge, %110, %c1_i32 : i32
            %141 = scf.if %140 -> (i32) {
              %165 = arith.addi %138, %139 : i32
              scf.yield %165 : i32
            } else {
              scf.yield %138 : i32
            }
            %142 = nvvm.shfl.sync  up %c-1_i32, %141, %c2_i32, %c0_i32 : i32 -> i32
            %143 = arith.cmpi sge, %110, %c2_i32 : i32
            %144 = scf.if %143 -> (i32) {
              %165 = arith.addi %141, %142 : i32
              scf.yield %165 : i32
            } else {
              scf.yield %141 : i32
            }
            %145 = nvvm.shfl.sync  up %c-1_i32, %144, %c4_i32, %c0_i32 : i32 -> i32
            %146 = arith.cmpi sge, %110, %c4_i32 : i32
            %147 = scf.if %146 -> (i32) {
              %165 = arith.addi %144, %145 : i32
              scf.yield %165 : i32
            } else {
              scf.yield %144 : i32
            }
            %148 = nvvm.shfl.sync  up %c-1_i32, %147, %c8_i32, %c0_i32 : i32 -> i32
            %149 = arith.cmpi sge, %110, %c8_i32 : i32
            %150 = scf.if %149 -> (i32) {
              %165 = arith.addi %147, %148 : i32
              scf.yield %165 : i32
            } else {
              scf.yield %147 : i32
            }
            %151 = nvvm.shfl.sync  up %c-1_i32, %150, %c16_i32, %c0_i32 : i32 -> i32
            %152 = arith.cmpi sge, %110, %c16_i32 : i32
            %153 = scf.if %152 -> (i32) {
              %165 = arith.addi %150, %151 : i32
              scf.yield %165 : i32
            } else {
              scf.yield %150 : i32
            }
            %154 = arith.addi %153, %arg21 : i32
            %155 = arith.cmpi sge, %arg13, %154 : i32
            %156 = nvvm.vote.ballot.sync %c-1_i32, %155 : i32
            %157 = llvm.intr.ctpop(%156) : (i32) -> i32
            %158 = arith.cmpi eq, %157, %c32_i32 : i32
            %159 = arith.addi %157, %arg19 : i32
            %160 = arith.cmpi eq, %157, %c0_i32 : i32
            %161 = arith.cmpi eq, %160, %false : i1
            %162 = scf.if %161 -> (i32) {
              %165 = arith.subi %157, %c1_i32 : i32
              %166 = nvvm.shfl.sync  idx %c-1_i32, %154, %165, %c31_i32 : i32 -> i32
              scf.yield %166 : i32
            } else {
              scf.yield %arg21 : i32
            }
            %163 = arith.select %158, %c31_i32, %157 : i32
            %164 = nvvm.shfl.sync  idx %c-1_i32, %154, %163, %c31_i32 : i32 -> i32
            scf.yield %158, %159, %162, %164 : i1, i32, i32, i32
          }
          %rmem_84 = cute.memref.alloca() : !memref_rmem_i32_
          %coord_85 = cute.make_coord(%112#0) : (i32) -> !cute.coord<"(?,_)">
          %idx_86 = cute.crd2idx(%coord_85, %17) : (!cute.coord<"(?,_)">, !cute.layout<"(2,4):(4,1)">) -> !cute.int_tuple<"?{div=4}">
          %iter_87 = cute.get_iter(%arg8) : !memref_gmem_i32_
          %ptr_88 = cute.add_offset(%iter_87, %idx_86) : (!cute.ptr<i32, gmem, align<16>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<i32, gmem, align<16>>
          %iter_89 = cute.get_iter(%rmem_84) : !memref_rmem_i32_
          %113 = cute.get_scalars(%38) : !cute.int_tuple<"1">
          scf.for %arg19 = %c0_i32 to %113 step %c1_i32  : i32 {
            %136 = builtin.unrealized_conversion_cast %ptr_88 : !cute.ptr<i32, gmem, align<16>> to !llvm.ptr<1>
            %137 = builtin.unrealized_conversion_cast %iter_89 : !cute.ptr<i32, rmem, align<32>> to !llvm.ptr
            %138 = llvm.load %136 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<4xi32>
            llvm.store %138, %137 {alignment = 16 : i64} : vector<4xi32>, !llvm.ptr
          } {llvm.loop_annotation = #loop_annotation}
          %114 = arith.subi %arg13, %112#1 : i32
          %115 = cute.memref.load(%rmem_84, %18) : (!memref_rmem_i32_, !cute.coord<"0">) -> i32
          %116 = cute.memref.load(%rmem_84, %16) : (!memref_rmem_i32_, !cute.coord<"1">) -> i32
          %117 = cute.memref.load(%rmem_84, %15) : (!memref_rmem_i32_, !cute.coord<"2">) -> i32
          %int_tuple_90 = cute.make_int_tuple(%115, %116, %117) : (i32, i32, i32) -> !cute.int_tuple<"(?,?,?)">
          %118:3 = cute.get_scalars(%int_tuple_90) <{only_dynamic}> : !cute.int_tuple<"(?,?,?)">
          %119 = arith.ceildivsi %118#0, %c128_i32 : i32
          %120 = arith.ceildivsi %118#1, %c128_i32 : i32
          %121 = arith.ceildivsi %118#2, %c64_i32 : i32
          %int_tuple_91 = cute.make_int_tuple(%119, %120, %121) : (i32, i32, i32) -> !cute.int_tuple<"(?,?,?)">
          %e0_92, %e1_93, %e2_94 = cute.get_leaves(%int_tuple_91) : !cute.int_tuple<"(?,?,?)">
          %shape_95 = cute.make_shape(%e0_92, %e1_93) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.shape<"(?,?)">
          %lay_96 = cute.make_layout(%shape_95) : !cute.layout<"(?,?):(1,?)">
          %122 = cute.get_hier_coord(%114, %lay_96) : (i32, !cute.layout<"(?,?):(1,?)">) -> !cute.coord<"(?,?)">
          %e0_97, %e1_98 = cute.get_leaves(%122) : !cute.coord<"(?,?)">
          %itup_99 = cute.to_int_tuple(%e0_97) : !cute.coord<"?"> to !cute.int_tuple<"?">
          %itup_100 = cute.to_int_tuple(%e1_98) : !cute.coord<"?"> to !cute.int_tuple<"?">
          %mul_101 = cute.tuple_mul(%itup_99, %38) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
          %mul_102 = cute.tuple_mul(%itup_100, %38) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
          %123 = arith.cmpi ne, %112#0, %arg14 : i32
          scf.if %123 {
            %coord_118 = cute.make_coord(%112#0) : (i32) -> !cute.coord<"(?,2)">
            %136 = cute.memref.load(%arg10, %coord_118) : (!memref_gmem_i64_, !cute.coord<"(?,2)">) -> i64
            %iv_119 = cute.assume(%136) : (i64) -> !cute.i64<divby 16>
            %137 = cute.inttoptr(%iv_119) : !cute.i64<divby 16> to !cute.ptr<f16, gmem, align<16>>
            %coord_120 = cute.make_coord(%112#0) : (i32) -> !cute.coord<"(?,2,_)">
            %idx_121 = cute.crd2idx(%coord_120, %14) : (!cute.coord<"(?,2,_)">, !cute.layout<"(2,3,2):(6,2,1)">) -> !cute.int_tuple<"?{div=2}">
            %iter_122 = cute.get_iter(%arg9) : !memref_gmem_i32_1
            %ptr_123 = cute.add_offset(%iter_122, %idx_121) : (!cute.ptr<i32, gmem, align<16>>, !cute.int_tuple<"?{div=2}">) -> !cute.ptr<i32, gmem, align<8>>
            %rmem_124 = cute.memref.alloca() : !memref_rmem_i32_1
            %iter_125 = cute.get_iter(%rmem_124) : !memref_rmem_i32_1
            scf.for %arg19 = %c0_i32 to %113 step %c1_i32  : i32 {
              %140 = builtin.unrealized_conversion_cast %ptr_123 : !cute.ptr<i32, gmem, align<8>> to !llvm.ptr<1>
              %141 = builtin.unrealized_conversion_cast %iter_125 : !cute.ptr<i32, rmem, align<32>> to !llvm.ptr
              %142 = llvm.load %140 {alignment = 8 : i64} : !llvm.ptr<1> -> vector<2xi32>
              llvm.store %142, %141 {alignment = 8 : i64} : vector<2xi32>, !llvm.ptr
            } {llvm.loop_annotation = #loop_annotation}
            %138 = cute.memref.load(%rmem_124, %18) : (!memref_rmem_i32_1, !cute.coord<"0">) -> i32
            %139 = cute.memref.load(%rmem_124, %16) : (!memref_rmem_i32_1, !cute.coord<"1">) -> i32
            %shape_126 = cute.make_shape(%115, %116) : (i32, i32) -> !cute.shape<"(?,?,1)">
            %stride = cute.make_stride(%138, %139) : (i32, i32) -> !cute.stride<"(?,?,0)">
            %lay_127 = cute.make_layout(%shape_126, %stride) : !cute.layout<"(?,?,1):(?,?,0)">
            %view_128 = cute.make_view(%137, %lay_127) : !memref_gmem_f16_
            %dyn_129 = cute.derefine(%view_128) : !memref_gmem_f16_ to !memref_gmem_f16_1
            scf.if %56 {
              cute_nvgpu.update_tma_desc(%arg5, %dyn_129, %dyn) : (!cute_nvgpu.atom.non_exec_tiled_tma_store<f16, copy_bits = 65536, tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>, !memref_gmem_f16_1, !cute.ptr<i64, smem, align<128>>) -> ()
              %140 = nvvm.elect.sync -> i1
              scf.if %140 {
                nvvm.cp.async.bulk.commit.group
                nvvm.cp.async.bulk.wait_group 0 {read}
              }
              nvvm.bar.warp.sync %c-1_i32 : i32
              %141 = cute.ptrtoint(%90) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, gmem, align<128>> to i64
              %142 = cute.ptrtoint(%dyn) : !cute.ptr<i64, smem, align<128>> to i32
              llvm.inline_asm has_side_effects asm_dialect = att "tensormap.cp_fenceproxy.global.shared::cta.tensormap::generic.release.gpu.sync.aligned [$0], [$1], 128;", "l,r" %141, %142 : (i64, i32) -> ()
            }
          }
          %div_103 = cute.tuple_div(%mul_101, %38) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
          %int_tuple_104 = cute.make_int_tuple(%arg12) : (i32) -> !cute.int_tuple<"?">
          %tup = cute.add_offset(%int_tuple_104, %e2_94) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.int_tuple<"?">
          %124 = cute.get_scalars(%tup) : !cute.int_tuple<"?">
          %coord_105 = cute.make_coord(%div_103, %mul_102) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(_,_,_,?,?,0)">
          %idx_106 = cute.crd2idx(%coord_105, %lay_76) : (!cute.coord<"(_,_,_,?,?,0)">, !cute.layout<"(((32,128),1),1,4,?,?,?):(((1@0,1@1),0),0,32@0,128@1,128@0,1@2)">) -> !cute.int_tuple<"(?{div=128},?{div=128},0)">
          %tup_107 = cute.add_offset(%26, %idx_106) : (!cute.int_tuple<"(0,0,0)">, !cute.int_tuple<"(?{div=128},?{div=128},0)">) -> !cute.int_tuple<"(?{div=128},?{div=128},0)">
          %125 = arith.remsi %arg18, %c2_i32 : i32
          %coord_108 = cute.make_coord(%125) : (i32) -> !cute.coord<"(_,_,_,_,_,?)">
          %idx_109 = cute.crd2idx(%coord_108, %6) : (!cute.coord<"(_,_,_,_,_,?)">, !cute.layout<"(((32,32),1),1,1,1,4,2):(((1,65536),0),0,0,0,32,128)">) -> !cute.int_tuple<"?{div=128}">
          %ptr_110 = cute.add_offset(%ptr_62, %idx_109) : (!cute.ptr<f32, tmem, align<16>>, !cute.int_tuple<"?{div=128}">) -> !cute.ptr<f32, tmem, align<16>>
          %126 = arith.floordivsi %arg18, %c2_i32 : i32
          %127 = arith.remsi %126, %c2_i32 : i32
          %int_tuple_111 = cute.make_int_tuple(%125) : (i32) -> !cute.int_tuple<"?">
          %ptr_112 = cute.add_offset(%iter_14, %int_tuple_111) : (!cute.ptr<i64, smem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
          %128 = builtin.unrealized_conversion_cast %ptr_112 : !cute.ptr<i64, smem> to !llvm.ptr<3>
          nvvm.mbarrier.try_wait.parity.shared %128, %127, %c10000000_i32 : !llvm.ptr<3>, i32, i32
          scf.if %123 {
            scf.if %56 {
              %136 = cute.ptrtoint(%90) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, gmem, align<128>> to i64
              llvm.inline_asm has_side_effects asm_dialect = att "fence.proxy.tensormap::generic.acquire.gpu [$0], 128;", "l" %136 : (i64) -> ()
            }
          }
          %129 = arith.muli %arg18, %c4_i32 : i32
          scf.for %arg19 = %c0_i32 to %c4_i32 step %c1_i32  : i32 {
            %coord_118 = cute.make_coord(%arg19) : (i32) -> !cute.coord<"(_,_,_,?)">
            %idx_119 = cute.crd2idx(%coord_118, %5) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"(((32,32),1),1,1,(1,4)):(((1,65536),0),0,0,(0,32))">) -> !cute.int_tuple<"?{div=32}">
            %ptr_120 = cute.add_offset(%ptr_110, %idx_119) : (!cute.ptr<f32, tmem, align<16>>, !cute.int_tuple<"?{div=32}">) -> !cute.ptr<f32, tmem, align<16>>
            scf.for %arg20 = %c0_i32 to %113 step %c1_i32  : i32 {
              %140 = "cute_nvgpu.arch.copy.SM100.tmem_load"(%ptr_120) <{num_b = 32 : i32, num_dp = 32 : i32, num_rep = 32 : i32}> : (!cute.ptr<f32, tmem, align<16>>) -> vector<32xi32>
              %141 = builtin.unrealized_conversion_cast %iter_63 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
              llvm.store %140, %141 : vector<32xi32>, !llvm.ptr
            } {llvm.loop_annotation = #loop_annotation}
            %view_121 = cute.make_view(%iter_63) : !memref_rmem_f32_1
            %136 = cute.memref.load_vec %view_121, row_major : !memref_rmem_f32_1
            %137 = arith.truncf %136 : vector<32xf32> to vector<32xf16>
            cute.memref.store_vec %137, %view, row_major : !memref_rmem_f16_1
            %138 = arith.addi %129, %arg19 : i32
            %139 = arith.remsi %138, %c4_i32 : i32
            %coord_122 = cute.make_coord(%139) : (i32) -> !cute.coord<"(_,_,_,?)">
            %idx_123 = cute.crd2idx(%coord_122, %4) : (!cute.coord<"(_,_,_,?)">, !cute.layout<"((1,32),1,1,(1,4)):((0,1),0,0,(0,4096))">) -> !cute.int_tuple<"?{div=4096}">
            scf.for %arg20 = %c0_i32 to %113 step %c1_i32  : i32 {
              %swizzled = cute.apply_swizzle(%ptr_67) : !cute.ptr<f16, smem, align<64>, S<2,4,3>>
              %ptr_124 = cute.add_offset(%swizzled, %idx_123) : (!cute.ptr<f16, smem, align<64>, S<2,4,3>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, smem, align<64>, S<2,4,3>>
              %140 = builtin.unrealized_conversion_cast %iter_68 : !cute.ptr<f16, rmem, align<32>> to !llvm.ptr
              %141 = builtin.unrealized_conversion_cast %ptr_124 : !cute.ptr<f16, smem, align<64>, S<2,4,3>> to !llvm.ptr<3>
              %142 = llvm.load %140 {alignment = 16 : i64} : !llvm.ptr -> vector<8xf16>
              llvm.store %142, %141 {alignment = 16 : i64} : vector<8xf16>, !llvm.ptr<3>
              %ptr_125 = cute.add_offset(%iter_68, %3) : (!cute.ptr<f16, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<f16, rmem, align<16>>
              %ptr_126 = cute.add_offset(%ptr_67, %3) : (!cute.ptr<f16, smem, align<64>, S<2,4,3>>, !cute.int_tuple<"8">) -> !cute.ptr<f16, smem, align<16>, S<2,4,3>>
              %swizzled_127 = cute.apply_swizzle(%ptr_126) : !cute.ptr<f16, smem, align<16>, S<2,4,3>>
              %ptr_128 = cute.add_offset(%swizzled_127, %idx_123) : (!cute.ptr<f16, smem, align<16>, S<2,4,3>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, smem, align<16>, S<2,4,3>>
              %143 = builtin.unrealized_conversion_cast %ptr_125 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
              %144 = builtin.unrealized_conversion_cast %ptr_128 : !cute.ptr<f16, smem, align<16>, S<2,4,3>> to !llvm.ptr<3>
              %145 = llvm.load %143 {alignment = 16 : i64} : !llvm.ptr -> vector<8xf16>
              llvm.store %145, %144 {alignment = 16 : i64} : vector<8xf16>, !llvm.ptr<3>
              %ptr_129 = cute.add_offset(%iter_68, %29) : (!cute.ptr<f16, rmem, align<32>>, !cute.int_tuple<"16">) -> !cute.ptr<f16, rmem, align<32>>
              %ptr_130 = cute.add_offset(%ptr_67, %29) : (!cute.ptr<f16, smem, align<64>, S<2,4,3>>, !cute.int_tuple<"16">) -> !cute.ptr<f16, smem, align<32>, S<2,4,3>>
              %swizzled_131 = cute.apply_swizzle(%ptr_130) : !cute.ptr<f16, smem, align<32>, S<2,4,3>>
              %ptr_132 = cute.add_offset(%swizzled_131, %idx_123) : (!cute.ptr<f16, smem, align<32>, S<2,4,3>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, smem, align<32>, S<2,4,3>>
              %146 = builtin.unrealized_conversion_cast %ptr_129 : !cute.ptr<f16, rmem, align<32>> to !llvm.ptr
              %147 = builtin.unrealized_conversion_cast %ptr_132 : !cute.ptr<f16, smem, align<32>, S<2,4,3>> to !llvm.ptr<3>
              %148 = llvm.load %146 {alignment = 16 : i64} : !llvm.ptr -> vector<8xf16>
              llvm.store %148, %147 {alignment = 16 : i64} : vector<8xf16>, !llvm.ptr<3>
              %ptr_133 = cute.add_offset(%iter_68, %2) : (!cute.ptr<f16, rmem, align<32>>, !cute.int_tuple<"24">) -> !cute.ptr<f16, rmem, align<16>>
              %ptr_134 = cute.add_offset(%ptr_67, %2) : (!cute.ptr<f16, smem, align<64>, S<2,4,3>>, !cute.int_tuple<"24">) -> !cute.ptr<f16, smem, align<16>, S<2,4,3>>
              %swizzled_135 = cute.apply_swizzle(%ptr_134) : !cute.ptr<f16, smem, align<16>, S<2,4,3>>
              %ptr_136 = cute.add_offset(%swizzled_135, %idx_123) : (!cute.ptr<f16, smem, align<16>, S<2,4,3>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, smem, align<16>, S<2,4,3>>
              %149 = builtin.unrealized_conversion_cast %ptr_133 : !cute.ptr<f16, rmem, align<16>> to !llvm.ptr
              %150 = builtin.unrealized_conversion_cast %ptr_136 : !cute.ptr<f16, smem, align<16>, S<2,4,3>> to !llvm.ptr<3>
              %151 = llvm.load %149 {alignment = 16 : i64} : !llvm.ptr -> vector<8xf16>
              llvm.store %151, %150 {alignment = 16 : i64} : vector<8xf16>, !llvm.ptr<3>
            } {llvm.loop_annotation = #loop_annotation}
            nvvm.fence.proxy {kind = #nvvm.proxy_kind<async.shared>, space = #nvvm.shared_space<cta>}
            nvvm.barrier id = %c2_i32 number_of_threads = %c128_i32
            scf.if %56 {
              %coord_124 = cute.make_coord(%139) : (i32) -> !cute.coord<"(_,?)">
              %idx_125 = cute.crd2idx(%coord_124, %1) : (!cute.coord<"(_,?)">, !cute.layout<"((4096,1),(1,4)):((1,0),(0,4096))">) -> !cute.int_tuple<"?{div=4096}">
              %ptr_126 = cute.add_offset(%iter_16, %idx_125) : (!cute.ptr<f16, smem, align<1024>, S<2,4,3>>, !cute.int_tuple<"?{div=4096}">) -> !cute.ptr<f16, smem, align<1024>, S<2,4,3>>
              %coord_127 = cute.make_coord(%arg19) : (i32) -> !cute.coord<"(_,?)">
              %idx_128 = cute.crd2idx(%coord_127, %0) : (!cute.coord<"(_,?)">, !cute.layout<"(((32,128),1),(1,4)):(((1@0,1@1),0),(0,32@0))">) -> !cute.int_tuple<"(?{div=32},0)">
              %tup_129 = cute.add_offset(%tup_107, %idx_128) : (!cute.int_tuple<"(?{div=128},?{div=128},0)">, !cute.int_tuple<"(?{div=32},0)">) -> !cute.int_tuple<"(?{div=32},?{div=128},0)">
              %e0_130, %e1_131, %e2_132 = cute.get_leaves(%tup_129) : !cute.int_tuple<"(?{div=32},?{div=128},0)">
              %140 = cute.ptrtoint(%90) : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, gmem, align<128>> to i64
              %iv_133 = cute.assume(%140) : (i64) -> !cute.i64<divby 128>
              %141 = cute.inttoptr(%iv_133) : !cute.i64<divby 128> to !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<128>>
              %int_tuple_134 = cute.make_int_tuple(%e0_130, %e1_131) : (!cute.int_tuple<"?{div=32}">, !cute.int_tuple<"?{div=128}">) -> !cute.int_tuple<"(?{div=32},?{div=128},0)">
              %142 = cute_nvgpu.atom.make_exec_tma(%arg5) : (!cute_nvgpu.atom.non_exec_tiled_tma_store<f16, copy_bits = 65536, tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">, internal_val_type = f16>) -> !cute_nvgpu.atom.tma_store<f16, copy_bits = 65536, mode = tiled, g_stride = <"()"> tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">>
              %143 = cute_nvgpu.atom.set_value(%142, %141 : !cute.ptr<!cute_nvgpu.tma_descriptor_tiled, generic, align<128>>) {field = #cute_nvgpu.atom_copy_field_tmastore<tma_descriptor_ptr>} : !cute_nvgpu.atom.tma_store<f16, copy_bits = 65536, mode = tiled, g_stride = <"()"> tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">>
              scf.for %arg20 = %c0_i32 to %113 step %c1_i32  : i32 {
                %TMADescAddr = cute_nvgpu.get_tma_desc_addr(%143 : !cute_nvgpu.atom.tma_store<f16, copy_bits = 65536, mode = tiled, g_stride = <"()"> tma_gbasis = <"(32,128,1):(1@1,1@0,1@2)">>) -> !cute.ptr<generic, align<64>>
                %144:3 = cute.get_scalars(%int_tuple_134) : !cute.int_tuple<"(?{div=32},?{div=128},0)">
                cute_nvgpu.arch.copy.SM100.tma_store(%TMADescAddr : !cute.ptr<generic, align<64>>, %ptr_126 : !cute.ptr<f16, smem, align<1024>, S<2,4,3>>, [%144#0, %144#1, %144#2] : i32, i32, i32) mode = <tiled>
              } {llvm.loop_annotation = #loop_annotation}
              nvvm.cp.async.bulk.commit.group
              nvvm.cp.async.bulk.wait_group 3 {read}
            }
            nvvm.barrier id = %c2_i32 number_of_threads = %c128_i32
          }
          %130 = nvvm.elect.sync -> i1
          scf.if %130 {
            %ptr_118 = cute.add_offset(%iter_15, %int_tuple_111) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
            %136 = builtin.unrealized_conversion_cast %ptr_118 : !cute.ptr<i64, smem> to !llvm.ptr<3>
            nvvm.mbarrier.txn %136, %c1_i32 {kind = #nvvm.mbar_txn_kind<arrive>} : !llvm.ptr<3>, i32
          }
          %131 = arith.addi %arg17, %104 : i32
          %132 = arith.addi %arg18, %c1_i32 : i32
          %133 = arith.cmpi sgt, %105, %131 : i32
          %134 = cute.get_hier_coord(%131, %lay) : (i32, !cute.layout<"(1,1,?):(0,0,1)">) -> !cute.coord<"(0,0,?)">
          %e0_113, %e1_114, %e2_115 = cute.get_leaves(%134) : !cute.coord<"(0,0,?)">
          %itup_116 = cute.to_int_tuple(%e2_115) : !cute.coord<"?"> to !cute.int_tuple<"?">
          %mul_117 = cute.tuple_mul(%itup_116, %38) : (!cute.int_tuple<"?">, !cute.int_tuple<"1">) -> !cute.int_tuple<"?">
          %135 = cute.get_scalars(%mul_117) : !cute.int_tuple<"?">
          scf.yield %124, %135, %133, %112#0, %112#0, %112#1, %131, %132 : i32, i32, i1, i32, i32, i32, i32, i32
        }
        scf.if %56 {
          cute_nvgpu.arch.sm100.relinquish_tmem_alloc_permit [ cta_1]
        }
        nvvm.barrier id = %c2_i32 number_of_threads = %c128_i32
        scf.if %56 {
          cute_nvgpu.arch.sm100.dealloc_tmem(%tmem_ptr, %c256_i32) [ cta_1] : !cute.ptr<f32, tmem, align<16>>, i32
        }
        scf.if %56 {
          %110 = arith.subi %109#0, %c1_i32 : i32
          %111 = arith.remsi %110, %c6_i32 : i32
          %int_tuple_84 = cute.make_int_tuple(%111) : (i32) -> !cute.int_tuple<"?">
          %ptr_85 = cute.add_offset(%iter_13, %int_tuple_84) : (!cute.ptr<i64, smem, align<16>>, !cute.int_tuple<"?">) -> !cute.ptr<i64, smem>
          %112 = arith.floordivsi %110, %c6_i32 : i32
          %113 = arith.remsi %112, %c2_i32 : i32
          %114 = builtin.unrealized_conversion_cast %ptr_85 : !cute.ptr<i64, smem> to !llvm.ptr<3>
          nvvm.mbarrier.try_wait.parity.shared %114, %113, %c10000000_i32 : !llvm.ptr<3>, i32, i32
        }
      }
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
