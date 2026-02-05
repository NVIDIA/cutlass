!copy_ldgsts = !cute.tiled_copy<!cute_nvgpu.atom.simt_async_copy<bf16, cache = always, 128 b>, layout_copy_tv = <"((64,2),(8,8)):((16,1),(2,1024))">, tiler_mn = <"[2:1;4096:1]">>
!copy_simt = !cute.tiled_copy<!cute_nvgpu.atom.universal_copy<bf16, 128 b>, layout_copy_tv = <"((64,2),(8,8)):((16,1),(2,1024))">, tiler_mn = <"[2:1;4096:1]">>
!memref_gmem_bf16_ = !cute.memref<bf16, gmem, align<16>, "(?,4096):(4096,1)">
!memref_gmem_bf16_1 = !cute.memref<bf16, gmem, align<16>, "(4096):(1)">
!memref_gmem_bf16_2 = !cute.memref<bf16, gmem, align<16>, "(2,4096):(4096,1)">
!memref_gmem_bf16_3 = !cute.memref<bf16, gmem, align<16>, "((2),4096):((0),1)">
!memref_gmem_bf16_4 = !cute.memref<bf16, gmem, align<16>, "(2,4096):(0,1)">
!memref_gmem_bf16_5 = !cute.memref<bf16, gmem, align<16>, "((8,8),1,1):((1,512),0,0)">
!memref_gmem_bf16_6 = !cute.memref<bf16, gmem, align<16>, "((8,8),(1,1)):((1,512),(0,0))">
!memref_gmem_bf16_7 = !cute.memref<bf16, gmem, align<16>, "((8,8)):((1,512))">
!memref_rmem_bf16_ = !cute.memref<bf16, rmem, align<32>, "((8,8),1,1):((1,8),0,0)">
!memref_rmem_bf16_1 = !cute.memref<bf16, rmem, align<32>, "((8,8),(1,1)):((1,8),(0,0))">
!memref_rmem_bf16_2 = !cute.memref<bf16, rmem, align<32>, "((8,8)):((1,8))">
!memref_rmem_bf16_3 = !cute.memref<bf16, rmem, align<32>, "(8,8):(1,8)">
!memref_rmem_bf16_4 = !cute.memref<bf16, rmem, align<16>, "(8):(1)">
!memref_rmem_i8_ = !cute.memref<i8, rmem, align<32>, "(8,1,1):(1,0,1)">
!memref_rmem_i8_1 = !cute.memref<i8, rmem, align<32>, "(8,(1,1)):(1,(0,1))">
!memref_rmem_i8_2 = !cute.memref<i8, rmem, "(8):(1)">
!memref_smem_bf16_ = !cute.memref<bf16, smem, align<1024>, "(2,4096):(4096,1)">
!memref_smem_bf16_1 = !cute.memref<bf16, smem, align<16>, "((8,8),1,1):((1,512),0,0)">
!memref_smem_bf16_2 = !cute.memref<bf16, smem, align<16>, "((8,8),(1,1)):((1,512),(0,0))">
!memref_smem_bf16_3 = !cute.memref<bf16, smem, align<16>, "((8,8)):((1,512))">
!memref_smem_bf16_4 = !cute.memref<bf16, smem, align<16>, "(8,8):(1,512)">
!memref_smem_bf16_5 = !cute.memref<bf16, smem, align<16>, "(8):(1)">
!memref_smem_f32_ = !cute.memref<f32, smem, align<1024>, "(2,2):(1,2)">
#loop_unroll = #llvm.loop_unroll<disable = false, full = true>
#loop_annotation = #llvm.loop_annotation<unroll = #loop_unroll>
module attributes {gpu.container_module} {
  gpu.module @kernels {
    cuda.kernel @kernel_cutlass_kernel___main__RMSNormKernel_object_at__tensorptrbf16gmemalign16o409640961_tensorptrbf16_gmem_align16_o_40961_tensorptrbf16gmemalign16o409640961__2_4096_0(%arg0: !memref_gmem_bf16_, %arg1: !memref_gmem_bf16_1, %arg2: !memref_gmem_bf16_, %arg3: f32) attributes {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} {
      %0 = cute.static : !cute.layout<"((64,2),(8,8)):((16,1),(2,1024))">
      %iter = cute.get_iter(%arg0) : !memref_gmem_bf16_
      %iter_0 = cute.get_iter(%arg1) : !memref_gmem_bf16_1
      %iter_1 = cute.get_iter(%arg2) : !memref_gmem_bf16_
      %iter_2 = cute.get_iter(%arg0) : !memref_gmem_bf16_
      %iter_3 = cute.get_iter(%arg1) : !memref_gmem_bf16_1
      %iter_4 = cute.get_iter(%arg2) : !memref_gmem_bf16_
      %lay = cute.get_layout(%arg0) : !memref_gmem_bf16_
      %1 = cute.get_shape(%lay) : (!cute.layout<"(?,4096):(4096,1)">) -> !cute.shape<"(?,4096)">
      %e0, %e1 = cute.get_leaves(%1) : !cute.shape<"(?,4096)">
      %itup = cute.to_int_tuple(%e0) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %2 = cute.get_scalars(%itup) : !cute.int_tuple<"?">
      %3 = cute.get_stride(%lay) : (!cute.layout<"(?,4096):(4096,1)">) -> !cute.stride<"(4096,1)">
      %e0_5, %e1_6 = cute.get_leaves(%3) : !cute.stride<"(4096,1)">
      %lay_7 = cute.get_layout(%arg1) : !memref_gmem_bf16_1
      %4 = cute.get_shape(%lay_7) : (!cute.layout<"(4096):(1)">) -> !cute.shape<"(4096)">
      %e0_8 = cute.get_leaves(%4) : !cute.shape<"(4096)">
      %5 = cute.get_stride(%lay_7) : (!cute.layout<"(4096):(1)">) -> !cute.stride<"(1)">
      %e0_9 = cute.get_leaves(%5) : !cute.stride<"(1)">
      %lay_10 = cute.get_layout(%arg2) : !memref_gmem_bf16_
      %6 = cute.get_shape(%lay_10) : (!cute.layout<"(?,4096):(4096,1)">) -> !cute.shape<"(?,4096)">
      %e0_11, %e1_12 = cute.get_leaves(%6) : !cute.shape<"(?,4096)">
      %itup_13 = cute.to_int_tuple(%e0_11) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %7 = cute.get_scalars(%itup_13) : !cute.int_tuple<"?">
      %8 = cute.get_stride(%lay_10) : (!cute.layout<"(?,4096):(4096,1)">) -> !cute.stride<"(4096,1)">
      %e0_14, %e1_15 = cute.get_leaves(%8) : !cute.stride<"(4096,1)">
      %9 = cute.get_shape(%0) : (!cute.layout<"((64,2),(8,8)):((16,1),(2,1024))">) -> !cute.shape<"((64,2),(8,8))">
      %e0_16, %e1_17, %e2, %e3 = cute.get_leaves(%9) : !cute.shape<"((64,2),(8,8))">
      %10 = cute.get_stride(%0) : (!cute.layout<"((64,2),(8,8)):((16,1),(2,1024))">) -> !cute.stride<"((16,1),(2,1024))">
      %e0_18, %e1_19, %e2_20, %e3_21 = cute.get_leaves(%10) : !cute.stride<"((16,1),(2,1024))">
      %11 = nvvm.read.ptx.sreg.tid.x : i32
      %12 = nvvm.read.ptx.sreg.tid.y : i32
      %13 = nvvm.read.ptx.sreg.tid.z : i32
      %14 = nvvm.read.ptx.sreg.ctaid.x : i32
      %15 = nvvm.read.ptx.sreg.ctaid.y : i32
      %16 = nvvm.read.ptx.sreg.ctaid.z : i32
      %lay_22 = cute.get_layout(%arg0) : !memref_gmem_bf16_
      %17 = cute.get_shape(%lay_22) : (!cute.layout<"(?,4096):(4096,1)">) -> !cute.shape<"(?,4096)">
      %e0_23, %e1_24 = cute.get_leaves(%17) : !cute.shape<"(?,4096)">
      %itup_25 = cute.to_int_tuple(%e0_23) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %18 = cute.get_scalars(%itup_25) : !cute.int_tuple<"?">
      %19 = cute.get_shape(%0) : (!cute.layout<"((64,2),(8,8)):((16,1),(2,1024))">) -> !cute.shape<"((64,2),(8,8))">
      %e0_26, %e1_27, %e2_28, %e3_29 = cute.get_leaves(%19) : !cute.shape<"((64,2),(8,8))">
      %smem_ptr = cute_nvgpu.arch.get_dyn_smem() : !cute.ptr<i8, smem, align<1024>>
      %shape = cute.make_shape() : () -> !cute.shape<"(2,4096)">
      %int_tuple = cute.make_int_tuple() : () -> !cute.int_tuple<"(1,0)">
      %lay_30 = cute.make_layout() : !cute.layout<"(2,4096):(4096,1)">
      %coord = cute.make_coord() : () -> !cute.coord<"0">
      %idx = cute.crd2idx(%coord, %lay_30) : (!cute.coord<"0">, !cute.layout<"(2,4096):(4096,1)">) -> !cute.int_tuple<"0">
      %e0_31 = cute.get_leaves(%idx) : !cute.int_tuple<"0">
      %cosz = cute.cosize(%lay_30) : (!cute.layout<"(2,4096):(4096,1)">) -> !cute.int_tuple<"8192">
      %e0_32 = cute.get_leaves(%cosz) : !cute.int_tuple<"8192">
      %int_tuple_33 = cute.make_int_tuple() : () -> !cute.int_tuple<"16384">
      %ptr = cute.add_offset(%smem_ptr, %int_tuple_33) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"16384">) -> !cute.ptr<i8, smem, align<1024>>
      %smem_size = cute_nvgpu.arch.get_dyn_smem_size() : i32
      %c16384_i32 = arith.constant 16384 : i32
      %20 = arith.cmpi sge, %smem_size, %c16384_i32 : i32
      cf.assert %20, "Allocation failed: shared memory allocation exceeds available memory set in kernel launch. Allocated bytes: 16384 bytes. Please reduce the allocation or set a larger smem size in kernel launch."
      %iter_34 = cute.recast_iter(%smem_ptr) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<bf16, smem, align<1024>>
      %view = cute.make_view(%iter_34, %lay_30) : !memref_smem_bf16_
      %iter_35 = cute.get_iter(%view) : !memref_smem_bf16_
      %shape_36 = cute.make_shape() : () -> !cute.shape<"(2,2)">
      %lay_37 = cute.make_layout() : !cute.layout<"(2,2):(1,2)">
      %coord_38 = cute.make_coord() : () -> !cute.coord<"0">
      %idx_39 = cute.crd2idx(%coord_38, %lay_37) : (!cute.coord<"0">, !cute.layout<"(2,2):(1,2)">) -> !cute.int_tuple<"0">
      %e0_40 = cute.get_leaves(%idx_39) : !cute.int_tuple<"0">
      %cosz_41 = cute.cosize(%lay_37) : (!cute.layout<"(2,2):(1,2)">) -> !cute.int_tuple<"4">
      %e0_42 = cute.get_leaves(%cosz_41) : !cute.int_tuple<"4">
      %int_tuple_43 = cute.make_int_tuple() : () -> !cute.int_tuple<"16">
      %ptr_44 = cute.add_offset(%ptr, %int_tuple_43) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"16">) -> !cute.ptr<i8, smem, align<16>>
      %smem_size_45 = cute_nvgpu.arch.get_dyn_smem_size() : i32
      %c16400_i32 = arith.constant 16400 : i32
      %21 = arith.cmpi sge, %smem_size_45, %c16400_i32 : i32
      cf.assert %21, "Allocation failed: shared memory allocation exceeds available memory set in kernel launch. Allocated bytes: 16400 bytes. Please reduce the allocation or set a larger smem size in kernel launch."
      %iter_46 = cute.recast_iter(%ptr) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<f32, smem, align<1024>>
      %view_47 = cute.make_view(%iter_46, %lay_37) : !memref_smem_f32_
      %iter_48 = cute.get_iter(%view_47) : !memref_smem_f32_
      %shape_49 = cute.make_shape(%itup_25) : (!cute.int_tuple<"?">) -> !cute.shape<"(?,4096)">
      %22 = cute.make_identity_tensor(%shape_49) : !cute.coord_tensor<"(0,0)", "(?,4096):(1@0,1@1)">
      %iter_50 = cute.get_iter(%22) : !cute.coord_tensor<"(0,0)", "(?,4096):(1@0,1@1)">
      %e0_51, %e1_52 = cute.get_leaves(%iter_50) : !cute.int_tuple<"(0,0)">
      %tile = cute.make_tile() : () -> !cute.tile<"[2:1;4096:1]">
      %coord_53 = cute.make_coord(%14) : (i32) -> !cute.coord<"(?,0)">
      %23 = cute.get_scalars(%coord_53) <{only_dynamic}> : !cute.coord<"(?,0)">
      %coord_54 = cute.make_coord(%23) : (i32) -> !cute.coord<"((_,_),(?,0))">
      %lay_55 = cute.get_layout(%arg0) : !memref_gmem_bf16_
      %24 = cute.get_scalars(%lay_55) <{only_dynamic}> : !cute.layout<"(?,4096):(4096,1)">
      %c2_i32 = arith.constant 2 : i32
      %25 = arith.ceildivsi %24, %c2_i32 : i32
      %shape_56 = cute.make_shape(%25) : (i32) -> !cute.shape<"((2,4096),(?,1))">
      %stride = cute.make_stride() : () -> !cute.stride<"((4096,1),(8192,0))">
      %lay_57 = cute.make_layout(%shape_56, %stride) : !cute.layout<"((2,4096),(?,1)):((4096,1),(8192,0))">
      %idx_58 = cute.crd2idx(%coord_54, %lay_57) : (!cute.coord<"((_,_),(?,0))">, !cute.layout<"((2,4096),(?,1)):((4096,1),(8192,0))">) -> !cute.int_tuple<"?{div=8192}">
      %iter_59 = cute.get_iter(%arg0) : !memref_gmem_bf16_
      %ptr_60 = cute.add_offset(%iter_59, %idx_58) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<bf16, gmem, align<16>>
      %view_61 = cute.make_view(%ptr_60) : !memref_gmem_bf16_2
      %iter_62 = cute.get_iter(%view_61) : !memref_gmem_bf16_2
      %tile_63 = cute.make_tile() : () -> !cute.tile<"[2:1;4096:1]">
      %coord_64 = cute.make_coord(%14) : (i32) -> !cute.coord<"(?,0)">
      %26 = cute.get_scalars(%coord_64) <{only_dynamic}> : !cute.coord<"(?,0)">
      %coord_65 = cute.make_coord(%26) : (i32) -> !cute.coord<"((_,_),(?,0))">
      %lay_66 = cute.get_layout(%arg2) : !memref_gmem_bf16_
      %27 = cute.get_scalars(%lay_66) <{only_dynamic}> : !cute.layout<"(?,4096):(4096,1)">
      %c2_i32_67 = arith.constant 2 : i32
      %28 = arith.ceildivsi %27, %c2_i32_67 : i32
      %shape_68 = cute.make_shape(%28) : (i32) -> !cute.shape<"((2,4096),(?,1))">
      %stride_69 = cute.make_stride() : () -> !cute.stride<"((4096,1),(8192,0))">
      %lay_70 = cute.make_layout(%shape_68, %stride_69) : !cute.layout<"((2,4096),(?,1)):((4096,1),(8192,0))">
      %idx_71 = cute.crd2idx(%coord_65, %lay_70) : (!cute.coord<"((_,_),(?,0))">, !cute.layout<"((2,4096),(?,1)):((4096,1),(8192,0))">) -> !cute.int_tuple<"?{div=8192}">
      %iter_72 = cute.get_iter(%arg2) : !memref_gmem_bf16_
      %ptr_73 = cute.add_offset(%iter_72, %idx_71) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<bf16, gmem, align<16>>
      %view_74 = cute.make_view(%ptr_73) : !memref_gmem_bf16_2
      %iter_75 = cute.get_iter(%view_74) : !memref_gmem_bf16_2
      %tile_76 = cute.make_tile() : () -> !cute.tile<"[2:1;4096:1]">
      %coord_77 = cute.make_coord(%14) : (i32) -> !cute.coord<"(?,0)">
      %29 = cute.get_scalars(%coord_77) <{only_dynamic}> : !cute.coord<"(?,0)">
      %coord_78 = cute.make_coord(%29) : (i32) -> !cute.coord<"((_,_),(?,0))">
      %lay_79 = cute.get_layout(%22) : !cute.coord_tensor<"(0,0)", "(?,4096):(1@0,1@1)">
      %30 = cute.get_scalars(%lay_79) <{only_dynamic}> : !cute.layout<"(?,4096):(1@0,1@1)">
      %c2_i32_80 = arith.constant 2 : i32
      %31 = arith.ceildivsi %30, %c2_i32_80 : i32
      %shape_81 = cute.make_shape(%31) : (i32) -> !cute.shape<"((2,4096),(?,1))">
      %stride_82 = cute.make_stride() : () -> !cute.stride<"((1@0,1@1),(2@0,0))">
      %lay_83 = cute.make_layout(%shape_81, %stride_82) : !cute.layout<"((2,4096),(?,1)):((1@0,1@1),(2@0,0))">
      %idx_84 = cute.crd2idx(%coord_78, %lay_83) : (!cute.coord<"((_,_),(?,0))">, !cute.layout<"((2,4096),(?,1)):((1@0,1@1),(2@0,0))">) -> !cute.int_tuple<"(?{div=2},0)">
      %iter_85 = cute.get_iter(%22) : !cute.coord_tensor<"(0,0)", "(?,4096):(1@0,1@1)">
      %tup = cute.add_offset(%iter_85, %idx_84) : (!cute.int_tuple<"(0,0)">, !cute.int_tuple<"(?{div=2},0)">) -> !cute.int_tuple<"(?{div=2},0)">
      %view_86 = cute.make_view(%tup) : !cute.coord_tensor<"(?{div=2},0)", "(2,4096):(1@0,1@1)">
      %iter_87 = cute.get_iter(%view_86) : !cute.coord_tensor<"(?{div=2},0)", "(2,4096):(1@0,1@1)">
      %e0_88, %e1_89 = cute.get_leaves(%iter_87) : !cute.int_tuple<"(?{div=2},0)">
      %32 = cute.get_scalars(%e0_88) : !cute.int_tuple<"?{div=2}">
      %lay_90 = cute.get_layout(%arg1) : !memref_gmem_bf16_1
      %shape_91 = cute.make_shape() : () -> !cute.shape<"(2)">
      %stride_92 = cute.make_stride() : () -> !cute.stride<"(0)">
      %lay_93 = cute.make_layout() : !cute.layout<"(2):(0)">
      %33 = cute.get_shape(%lay_90) : (!cute.layout<"(4096):(1)">) -> !cute.shape<"(4096)">
      %e0_94 = cute.get_leaves(%33) : !cute.shape<"(4096)">
      %prepend = cute.prepend_to_rank<2> (%lay_90, %lay_93) : !cute.layout<"(4096):(1)">, !cute.layout<"(2):(0)">
      %view_95 = cute.make_view(%iter_3, %prepend) : !memref_gmem_bf16_3
      %iter_96 = cute.get_iter(%view_95) : !memref_gmem_bf16_3
      %tile_97 = cute.make_tile() : () -> !cute.tile<"[2:1;4096:1]">
      %coord_98 = cute.make_coord() : () -> !cute.coord<"(0,0)">
      %coord_99 = cute.make_coord() : () -> !cute.coord<"((_,_),(0,0))">
      %lay_100 = cute.get_layout(%view_95) : !memref_gmem_bf16_3
      %lay_101 = cute.make_layout() : !cute.layout<"((2,4096),(1,1)):((0,1),(0,0))">
      %idx_102 = cute.crd2idx(%coord_99, %lay_101) : (!cute.coord<"((_,_),(0,0))">, !cute.layout<"((2,4096),(1,1)):((0,1),(0,0))">) -> !cute.int_tuple<"0">
      %iter_103 = cute.get_iter(%view_95) : !memref_gmem_bf16_3
      %ptr_104 = cute.add_offset(%iter_103, %idx_102) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, gmem, align<16>>
      %view_105 = cute.make_view(%ptr_104) : !memref_gmem_bf16_4
      %iter_106 = cute.get_iter(%view_105) : !memref_gmem_bf16_4
      %atom = cute.make_atom() : () -> !cute_nvgpu.atom.simt_async_copy<bf16, cache = always, 128 b>
      %atom_107 = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<bf16, 128 b>
      %atom_108 = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<bf16, 128 b>
      %tile_109 = cute.make_tile() : () -> !cute.tile<"[2:1;4096:1]">
      %34 = cute.make_tiled_copy(%atom) : !copy_ldgsts
      %tile_110 = cute.make_tile() : () -> !cute.tile<"[2:1;4096:1]">
      %35 = cute.make_tiled_copy(%atom_107) : !copy_simt
      %tile_111 = cute.make_tile() : () -> !cute.tile<"[2:1;4096:1]">
      %36 = cute.make_tiled_copy(%atom_108) : !copy_simt
      %coord_112 = cute.make_coord(%11) : (i32) -> !cute.coord<"?">
      %src_partitioned = cute.tiled.copy.partition_S(%34, %view_61, %coord_112) : (!copy_ldgsts, !memref_gmem_bf16_2, !cute.coord<"?">) -> !memref_gmem_bf16_5
      %iter_113 = cute.get_iter(%src_partitioned) : !memref_gmem_bf16_5
      %coord_114 = cute.make_coord(%11) : (i32) -> !cute.coord<"?">
      %dst_partitioned = cute.tiled.copy.partition_D(%34, %view, %coord_114) : (!copy_ldgsts, !memref_smem_bf16_, !cute.coord<"?">) -> !memref_smem_bf16_1
      %iter_115 = cute.get_iter(%dst_partitioned) : !memref_smem_bf16_1
      %coord_116 = cute.make_coord(%11) : (i32) -> !cute.coord<"?">
      %dst_partitioned_117 = cute.tiled.copy.partition_D(%36, %view_74, %coord_116) : (!copy_simt, !memref_gmem_bf16_2, !cute.coord<"?">) -> !memref_gmem_bf16_5
      %iter_118 = cute.get_iter(%dst_partitioned_117) : !memref_gmem_bf16_5
      %coord_119 = cute.make_coord(%11) : (i32) -> !cute.coord<"?">
      %src_partitioned_120 = cute.tiled.copy.partition_S(%34, %view_86, %coord_119) : (!copy_ldgsts, !cute.coord_tensor<"(?{div=2},0)", "(2,4096):(1@0,1@1)">, !cute.coord<"?">) -> !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %iter_121 = cute.get_iter(%src_partitioned_120) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %e0_122, %e1_123 = cute.get_leaves(%iter_121) : !cute.int_tuple<"(?,?{div=8})">
      %37 = cute.get_scalars(%e0_122) : !cute.int_tuple<"?">
      %38 = cute.get_scalars(%e1_123) : !cute.int_tuple<"?{div=8}">
      %lay_124 = cute.get_layout(%src_partitioned) : !memref_gmem_bf16_5
      %39 = cute.make_layout_like(%lay_124) : !cute.layout<"((8,8),1,1):((1,512),0,0)"> to !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %rmem = cute.memref.alloca(%39) : !memref_rmem_bf16_
      %iter_125 = cute.get_iter(%rmem) : !memref_rmem_bf16_
      %iter_126 = cute.get_iter(%rmem) : !memref_rmem_bf16_
      %lay_127 = cute.get_layout(%dst_partitioned_117) : !memref_gmem_bf16_5
      %40 = cute.make_layout_like(%lay_127) : !cute.layout<"((8,8),1,1):((1,512),0,0)"> to !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %rmem_128 = cute.memref.alloca(%40) : !memref_rmem_bf16_
      %iter_129 = cute.get_iter(%rmem_128) : !memref_rmem_bf16_
      %iter_130 = cute.get_iter(%rmem_128) : !memref_rmem_bf16_
      %coord_131 = cute.make_coord(%11) : (i32) -> !cute.coord<"?">
      %src_partitioned_132 = cute.tiled.copy.partition_S(%35, %view_105, %coord_131) : (!copy_simt, !memref_gmem_bf16_4, !cute.coord<"?">) -> !memref_gmem_bf16_5
      %iter_133 = cute.get_iter(%src_partitioned_132) : !memref_gmem_bf16_5
      %lay_134 = cute.get_layout(%src_partitioned_132) : !memref_gmem_bf16_5
      %41 = cute.make_layout_like(%lay_134) : !cute.layout<"((8,8),1,1):((1,512),0,0)"> to !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %rmem_135 = cute.memref.alloca(%41) : !memref_rmem_bf16_
      %iter_136 = cute.get_iter(%rmem_135) : !memref_rmem_bf16_
      %iter_137 = cute.get_iter(%rmem_135) : !memref_rmem_bf16_
      %retiled = cute.tiled.copy.retile(%34, %rmem_135) : (!copy_ldgsts, !memref_rmem_bf16_) -> !memref_rmem_bf16_
      %iter_138 = cute.get_iter(%retiled) : !memref_rmem_bf16_
      %lay_139 = cute.get_layout(%src_partitioned_120) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %sz = cute.size(%lay_139) <{mode = [0, 1]}> : (!cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"8">
      %e0_140 = cute.get_leaves(%sz) : !cute.int_tuple<"8">
      %lay_141 = cute.get_layout(%src_partitioned_120) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %sz_142 = cute.size(%lay_141) <{mode = [1]}> : (!cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"1">
      %e0_143 = cute.get_leaves(%sz_142) : !cute.int_tuple<"1">
      %lay_144 = cute.get_layout(%src_partitioned_120) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %sz_145 = cute.size(%lay_144) <{mode = [2]}> : (!cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"1">
      %e0_146 = cute.get_leaves(%sz_145) : !cute.int_tuple<"1">
      %lay_147 = cute.get_layout(%src_partitioned_120) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %sz_148 = cute.size(%lay_147) <{mode = [2]}> : (!cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"1">
      %e0_149 = cute.get_leaves(%sz_148) : !cute.int_tuple<"1">
      %shape_150 = cute.make_shape() : () -> !cute.shape<"(8,1,1)">
      %stride_151 = cute.make_stride() : () -> !cute.stride<"(1,0,1)">
      %lay_152 = cute.make_layout() : !cute.layout<"(8,1,1):(1,0,1)">
      %rmem_153 = cute.memref.alloca(%lay_152) : !memref_rmem_i8_
      %iter_154 = cute.get_iter(%rmem_153) : !memref_rmem_i8_
      %iter_155 = cute.get_iter(%rmem_153) : !memref_rmem_i8_
      %lay_156 = cute.get_layout(%rmem_153) : !memref_rmem_i8_
      %42 = cute.get_shape(%lay_156) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %e0_157, %e1_158, %e2_159 = cute.get_leaves(%42) : !cute.shape<"(8,1,1)">
      %coord_160 = cute.make_coord() : () -> !cute.coord<"((0,0),0,0)">
      %lay_161 = cute.get_layout(%src_partitioned_120) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %idx_162 = cute.crd2idx(%coord_160, %lay_161) : (!cute.coord<"((0,0),0,0)">, !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"(0,0)">
      %iter_163 = cute.get_iter(%src_partitioned_120) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %tup_164 = cute.add_offset(%iter_163, %idx_162) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,0)">) -> !cute.int_tuple<"(?,?{div=8})">
      %view_165 = cute.make_view(%tup_164) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %iter_166 = cute.get_iter(%view_165) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_167, %e1_168 = cute.get_leaves(%iter_166) : !cute.int_tuple<"(?,?{div=8})">
      %43 = cute.get_scalars(%e0_167) : !cute.int_tuple<"?">
      %44 = cute.get_scalars(%e1_168) : !cute.int_tuple<"?{div=8}">
      %iter_169 = cute.get_iter(%view_165) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_170, %e1_171 = cute.get_leaves(%iter_169) : !cute.int_tuple<"(?,?{div=8})">
      %45 = cute.get_scalars(%e0_170) : !cute.int_tuple<"?">
      %46 = cute.get_scalars(%e1_171) : !cute.int_tuple<"?{div=8}">
      %iter_172 = cute.get_iter(%view_165) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_173, %e1_174 = cute.get_leaves(%iter_172) : !cute.int_tuple<"(?,?{div=8})">
      %47 = cute.get_scalars(%e0_173) : !cute.int_tuple<"?">
      %48 = cute.get_scalars(%e1_174) : !cute.int_tuple<"?{div=8}">
      %coord_175 = cute.make_coord(%e1_174) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_176 = cute.make_coord() : () -> !cute.coord<"4096">
      %49 = cute.elem_less(%coord_175, %coord_176) : !cute.coord<"?{div=8}">, !cute.coord<"4096">
      %50 = arith.extui %49 : i1 to i8
      %coord_177 = cute.make_coord() : () -> !cute.coord<"(0,0,0)">
      cute.memref.store(%rmem_153, %coord_177, %50) : (!memref_rmem_i8_, !cute.coord<"(0,0,0)">, i8) -> ()
      %coord_178 = cute.make_coord() : () -> !cute.coord<"((0,1),0,0)">
      %lay_179 = cute.get_layout(%src_partitioned_120) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %idx_180 = cute.crd2idx(%coord_178, %lay_179) : (!cute.coord<"((0,1),0,0)">, !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"(0,512)">
      %iter_181 = cute.get_iter(%src_partitioned_120) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %tup_182 = cute.add_offset(%iter_181, %idx_180) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,512)">) -> !cute.int_tuple<"(?,?{div=8})">
      %view_183 = cute.make_view(%tup_182) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %iter_184 = cute.get_iter(%view_183) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_185, %e1_186 = cute.get_leaves(%iter_184) : !cute.int_tuple<"(?,?{div=8})">
      %51 = cute.get_scalars(%e0_185) : !cute.int_tuple<"?">
      %52 = cute.get_scalars(%e1_186) : !cute.int_tuple<"?{div=8}">
      %iter_187 = cute.get_iter(%view_183) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_188, %e1_189 = cute.get_leaves(%iter_187) : !cute.int_tuple<"(?,?{div=8})">
      %53 = cute.get_scalars(%e0_188) : !cute.int_tuple<"?">
      %54 = cute.get_scalars(%e1_189) : !cute.int_tuple<"?{div=8}">
      %iter_190 = cute.get_iter(%view_183) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_191, %e1_192 = cute.get_leaves(%iter_190) : !cute.int_tuple<"(?,?{div=8})">
      %55 = cute.get_scalars(%e0_191) : !cute.int_tuple<"?">
      %56 = cute.get_scalars(%e1_192) : !cute.int_tuple<"?{div=8}">
      %coord_193 = cute.make_coord(%e1_192) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_194 = cute.make_coord() : () -> !cute.coord<"4096">
      %57 = cute.elem_less(%coord_193, %coord_194) : !cute.coord<"?{div=8}">, !cute.coord<"4096">
      %58 = arith.extui %57 : i1 to i8
      %coord_195 = cute.make_coord() : () -> !cute.coord<"(1,0,0)">
      cute.memref.store(%rmem_153, %coord_195, %58) : (!memref_rmem_i8_, !cute.coord<"(1,0,0)">, i8) -> ()
      %coord_196 = cute.make_coord() : () -> !cute.coord<"((0,2),0,0)">
      %lay_197 = cute.get_layout(%src_partitioned_120) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %idx_198 = cute.crd2idx(%coord_196, %lay_197) : (!cute.coord<"((0,2),0,0)">, !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"(0,1024)">
      %iter_199 = cute.get_iter(%src_partitioned_120) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %tup_200 = cute.add_offset(%iter_199, %idx_198) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,1024)">) -> !cute.int_tuple<"(?,?{div=8})">
      %view_201 = cute.make_view(%tup_200) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %iter_202 = cute.get_iter(%view_201) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_203, %e1_204 = cute.get_leaves(%iter_202) : !cute.int_tuple<"(?,?{div=8})">
      %59 = cute.get_scalars(%e0_203) : !cute.int_tuple<"?">
      %60 = cute.get_scalars(%e1_204) : !cute.int_tuple<"?{div=8}">
      %iter_205 = cute.get_iter(%view_201) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_206, %e1_207 = cute.get_leaves(%iter_205) : !cute.int_tuple<"(?,?{div=8})">
      %61 = cute.get_scalars(%e0_206) : !cute.int_tuple<"?">
      %62 = cute.get_scalars(%e1_207) : !cute.int_tuple<"?{div=8}">
      %iter_208 = cute.get_iter(%view_201) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_209, %e1_210 = cute.get_leaves(%iter_208) : !cute.int_tuple<"(?,?{div=8})">
      %63 = cute.get_scalars(%e0_209) : !cute.int_tuple<"?">
      %64 = cute.get_scalars(%e1_210) : !cute.int_tuple<"?{div=8}">
      %coord_211 = cute.make_coord(%e1_210) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_212 = cute.make_coord() : () -> !cute.coord<"4096">
      %65 = cute.elem_less(%coord_211, %coord_212) : !cute.coord<"?{div=8}">, !cute.coord<"4096">
      %66 = arith.extui %65 : i1 to i8
      %coord_213 = cute.make_coord() : () -> !cute.coord<"(2,0,0)">
      cute.memref.store(%rmem_153, %coord_213, %66) : (!memref_rmem_i8_, !cute.coord<"(2,0,0)">, i8) -> ()
      %coord_214 = cute.make_coord() : () -> !cute.coord<"((0,3),0,0)">
      %lay_215 = cute.get_layout(%src_partitioned_120) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %idx_216 = cute.crd2idx(%coord_214, %lay_215) : (!cute.coord<"((0,3),0,0)">, !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"(0,1536)">
      %iter_217 = cute.get_iter(%src_partitioned_120) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %tup_218 = cute.add_offset(%iter_217, %idx_216) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,1536)">) -> !cute.int_tuple<"(?,?{div=8})">
      %view_219 = cute.make_view(%tup_218) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %iter_220 = cute.get_iter(%view_219) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_221, %e1_222 = cute.get_leaves(%iter_220) : !cute.int_tuple<"(?,?{div=8})">
      %67 = cute.get_scalars(%e0_221) : !cute.int_tuple<"?">
      %68 = cute.get_scalars(%e1_222) : !cute.int_tuple<"?{div=8}">
      %iter_223 = cute.get_iter(%view_219) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_224, %e1_225 = cute.get_leaves(%iter_223) : !cute.int_tuple<"(?,?{div=8})">
      %69 = cute.get_scalars(%e0_224) : !cute.int_tuple<"?">
      %70 = cute.get_scalars(%e1_225) : !cute.int_tuple<"?{div=8}">
      %iter_226 = cute.get_iter(%view_219) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_227, %e1_228 = cute.get_leaves(%iter_226) : !cute.int_tuple<"(?,?{div=8})">
      %71 = cute.get_scalars(%e0_227) : !cute.int_tuple<"?">
      %72 = cute.get_scalars(%e1_228) : !cute.int_tuple<"?{div=8}">
      %coord_229 = cute.make_coord(%e1_228) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_230 = cute.make_coord() : () -> !cute.coord<"4096">
      %73 = cute.elem_less(%coord_229, %coord_230) : !cute.coord<"?{div=8}">, !cute.coord<"4096">
      %74 = arith.extui %73 : i1 to i8
      %coord_231 = cute.make_coord() : () -> !cute.coord<"(3,0,0)">
      cute.memref.store(%rmem_153, %coord_231, %74) : (!memref_rmem_i8_, !cute.coord<"(3,0,0)">, i8) -> ()
      %coord_232 = cute.make_coord() : () -> !cute.coord<"((0,4),0,0)">
      %lay_233 = cute.get_layout(%src_partitioned_120) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %idx_234 = cute.crd2idx(%coord_232, %lay_233) : (!cute.coord<"((0,4),0,0)">, !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"(0,2048)">
      %iter_235 = cute.get_iter(%src_partitioned_120) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %tup_236 = cute.add_offset(%iter_235, %idx_234) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,2048)">) -> !cute.int_tuple<"(?,?{div=8})">
      %view_237 = cute.make_view(%tup_236) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %iter_238 = cute.get_iter(%view_237) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_239, %e1_240 = cute.get_leaves(%iter_238) : !cute.int_tuple<"(?,?{div=8})">
      %75 = cute.get_scalars(%e0_239) : !cute.int_tuple<"?">
      %76 = cute.get_scalars(%e1_240) : !cute.int_tuple<"?{div=8}">
      %iter_241 = cute.get_iter(%view_237) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_242, %e1_243 = cute.get_leaves(%iter_241) : !cute.int_tuple<"(?,?{div=8})">
      %77 = cute.get_scalars(%e0_242) : !cute.int_tuple<"?">
      %78 = cute.get_scalars(%e1_243) : !cute.int_tuple<"?{div=8}">
      %iter_244 = cute.get_iter(%view_237) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_245, %e1_246 = cute.get_leaves(%iter_244) : !cute.int_tuple<"(?,?{div=8})">
      %79 = cute.get_scalars(%e0_245) : !cute.int_tuple<"?">
      %80 = cute.get_scalars(%e1_246) : !cute.int_tuple<"?{div=8}">
      %coord_247 = cute.make_coord(%e1_246) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_248 = cute.make_coord() : () -> !cute.coord<"4096">
      %81 = cute.elem_less(%coord_247, %coord_248) : !cute.coord<"?{div=8}">, !cute.coord<"4096">
      %82 = arith.extui %81 : i1 to i8
      %coord_249 = cute.make_coord() : () -> !cute.coord<"(4,0,0)">
      cute.memref.store(%rmem_153, %coord_249, %82) : (!memref_rmem_i8_, !cute.coord<"(4,0,0)">, i8) -> ()
      %coord_250 = cute.make_coord() : () -> !cute.coord<"((0,5),0,0)">
      %lay_251 = cute.get_layout(%src_partitioned_120) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %idx_252 = cute.crd2idx(%coord_250, %lay_251) : (!cute.coord<"((0,5),0,0)">, !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"(0,2560)">
      %iter_253 = cute.get_iter(%src_partitioned_120) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %tup_254 = cute.add_offset(%iter_253, %idx_252) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,2560)">) -> !cute.int_tuple<"(?,?{div=8})">
      %view_255 = cute.make_view(%tup_254) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %iter_256 = cute.get_iter(%view_255) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_257, %e1_258 = cute.get_leaves(%iter_256) : !cute.int_tuple<"(?,?{div=8})">
      %83 = cute.get_scalars(%e0_257) : !cute.int_tuple<"?">
      %84 = cute.get_scalars(%e1_258) : !cute.int_tuple<"?{div=8}">
      %iter_259 = cute.get_iter(%view_255) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_260, %e1_261 = cute.get_leaves(%iter_259) : !cute.int_tuple<"(?,?{div=8})">
      %85 = cute.get_scalars(%e0_260) : !cute.int_tuple<"?">
      %86 = cute.get_scalars(%e1_261) : !cute.int_tuple<"?{div=8}">
      %iter_262 = cute.get_iter(%view_255) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_263, %e1_264 = cute.get_leaves(%iter_262) : !cute.int_tuple<"(?,?{div=8})">
      %87 = cute.get_scalars(%e0_263) : !cute.int_tuple<"?">
      %88 = cute.get_scalars(%e1_264) : !cute.int_tuple<"?{div=8}">
      %coord_265 = cute.make_coord(%e1_264) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_266 = cute.make_coord() : () -> !cute.coord<"4096">
      %89 = cute.elem_less(%coord_265, %coord_266) : !cute.coord<"?{div=8}">, !cute.coord<"4096">
      %90 = arith.extui %89 : i1 to i8
      %coord_267 = cute.make_coord() : () -> !cute.coord<"(5,0,0)">
      cute.memref.store(%rmem_153, %coord_267, %90) : (!memref_rmem_i8_, !cute.coord<"(5,0,0)">, i8) -> ()
      %coord_268 = cute.make_coord() : () -> !cute.coord<"((0,6),0,0)">
      %lay_269 = cute.get_layout(%src_partitioned_120) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %idx_270 = cute.crd2idx(%coord_268, %lay_269) : (!cute.coord<"((0,6),0,0)">, !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"(0,3072)">
      %iter_271 = cute.get_iter(%src_partitioned_120) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %tup_272 = cute.add_offset(%iter_271, %idx_270) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,3072)">) -> !cute.int_tuple<"(?,?{div=8})">
      %view_273 = cute.make_view(%tup_272) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %iter_274 = cute.get_iter(%view_273) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_275, %e1_276 = cute.get_leaves(%iter_274) : !cute.int_tuple<"(?,?{div=8})">
      %91 = cute.get_scalars(%e0_275) : !cute.int_tuple<"?">
      %92 = cute.get_scalars(%e1_276) : !cute.int_tuple<"?{div=8}">
      %iter_277 = cute.get_iter(%view_273) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_278, %e1_279 = cute.get_leaves(%iter_277) : !cute.int_tuple<"(?,?{div=8})">
      %93 = cute.get_scalars(%e0_278) : !cute.int_tuple<"?">
      %94 = cute.get_scalars(%e1_279) : !cute.int_tuple<"?{div=8}">
      %iter_280 = cute.get_iter(%view_273) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_281, %e1_282 = cute.get_leaves(%iter_280) : !cute.int_tuple<"(?,?{div=8})">
      %95 = cute.get_scalars(%e0_281) : !cute.int_tuple<"?">
      %96 = cute.get_scalars(%e1_282) : !cute.int_tuple<"?{div=8}">
      %coord_283 = cute.make_coord(%e1_282) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_284 = cute.make_coord() : () -> !cute.coord<"4096">
      %97 = cute.elem_less(%coord_283, %coord_284) : !cute.coord<"?{div=8}">, !cute.coord<"4096">
      %98 = arith.extui %97 : i1 to i8
      %coord_285 = cute.make_coord() : () -> !cute.coord<"(6,0,0)">
      cute.memref.store(%rmem_153, %coord_285, %98) : (!memref_rmem_i8_, !cute.coord<"(6,0,0)">, i8) -> ()
      %coord_286 = cute.make_coord() : () -> !cute.coord<"((0,7),0,0)">
      %lay_287 = cute.get_layout(%src_partitioned_120) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %idx_288 = cute.crd2idx(%coord_286, %lay_287) : (!cute.coord<"((0,7),0,0)">, !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"(0,3584)">
      %iter_289 = cute.get_iter(%src_partitioned_120) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %tup_290 = cute.add_offset(%iter_289, %idx_288) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,3584)">) -> !cute.int_tuple<"(?,?{div=8})">
      %view_291 = cute.make_view(%tup_290) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %iter_292 = cute.get_iter(%view_291) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_293, %e1_294 = cute.get_leaves(%iter_292) : !cute.int_tuple<"(?,?{div=8})">
      %99 = cute.get_scalars(%e0_293) : !cute.int_tuple<"?">
      %100 = cute.get_scalars(%e1_294) : !cute.int_tuple<"?{div=8}">
      %iter_295 = cute.get_iter(%view_291) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_296, %e1_297 = cute.get_leaves(%iter_295) : !cute.int_tuple<"(?,?{div=8})">
      %101 = cute.get_scalars(%e0_296) : !cute.int_tuple<"?">
      %102 = cute.get_scalars(%e1_297) : !cute.int_tuple<"?{div=8}">
      %iter_298 = cute.get_iter(%view_291) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_299, %e1_300 = cute.get_leaves(%iter_298) : !cute.int_tuple<"(?,?{div=8})">
      %103 = cute.get_scalars(%e0_299) : !cute.int_tuple<"?">
      %104 = cute.get_scalars(%e1_300) : !cute.int_tuple<"?{div=8}">
      %coord_301 = cute.make_coord(%e1_300) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_302 = cute.make_coord() : () -> !cute.coord<"4096">
      %105 = cute.elem_less(%coord_301, %coord_302) : !cute.coord<"?{div=8}">, !cute.coord<"4096">
      %106 = arith.extui %105 : i1 to i8
      %coord_303 = cute.make_coord() : () -> !cute.coord<"(7,0,0)">
      cute.memref.store(%rmem_153, %coord_303, %106) : (!memref_rmem_i8_, !cute.coord<"(7,0,0)">, i8) -> ()
      %coord_304 = cute.make_coord() : () -> !cute.coord<"((0,0),0,0)">
      %lay_305 = cute.get_layout(%src_partitioned_120) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %idx_306 = cute.crd2idx(%coord_304, %lay_305) : (!cute.coord<"((0,0),0,0)">, !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"(0,0)">
      %iter_307 = cute.get_iter(%src_partitioned_120) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %tup_308 = cute.add_offset(%iter_307, %idx_306) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,0)">) -> !cute.int_tuple<"(?,?{div=8})">
      %view_309 = cute.make_view(%tup_308) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %iter_310 = cute.get_iter(%view_309) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_311, %e1_312 = cute.get_leaves(%iter_310) : !cute.int_tuple<"(?,?{div=8})">
      %107 = cute.get_scalars(%e0_311) : !cute.int_tuple<"?">
      %108 = cute.get_scalars(%e1_312) : !cute.int_tuple<"?{div=8}">
      %iter_313 = cute.get_iter(%view_309) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_314, %e1_315 = cute.get_leaves(%iter_313) : !cute.int_tuple<"(?,?{div=8})">
      %109 = cute.get_scalars(%e0_314) : !cute.int_tuple<"?">
      %110 = cute.get_scalars(%e1_315) : !cute.int_tuple<"?{div=8}">
      %iter_316 = cute.get_iter(%view_309) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_317, %e1_318 = cute.get_leaves(%iter_316) : !cute.int_tuple<"(?,?{div=8})">
      %111 = cute.get_scalars(%e0_317) : !cute.int_tuple<"?">
      %112 = cute.get_scalars(%e1_318) : !cute.int_tuple<"?{div=8}">
      %113 = arith.cmpi slt, %111, %18 : i32
      scf.if %113 {
        %lay_718 = cute.get_layout(%src_partitioned) : !memref_gmem_bf16_5
        %262 = cute.get_shape(%lay_718) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %e0_719, %e1_720, %e2_721, %e3_722 = cute.get_leaves(%262) : !cute.shape<"((8,8),1,1)">
        %lay_723 = cute.get_layout(%dst_partitioned) : !memref_smem_bf16_1
        %263 = cute.get_shape(%lay_723) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %e0_724, %e1_725, %e2_726, %e3_727 = cute.get_leaves(%263) : !cute.shape<"((8,8),1,1)">
        %lay_728 = cute.get_layout(%src_partitioned) : !memref_gmem_bf16_5
        %shape_729 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_730 = cute.make_layout() : !cute.layout<"1:0">
        %append_731 = cute.append_to_rank<2> (%lay_728, %lay_730) : !cute.layout<"((8,8),1,1):((1,512),0,0)">, !cute.layout<"1:0">
        %view_732 = cute.make_view(%iter_113, %append_731) : !memref_gmem_bf16_5
        %iter_733 = cute.get_iter(%view_732) : !memref_gmem_bf16_5
        %lay_734 = cute.get_layout(%view_732) : !memref_gmem_bf16_5
        %264 = cute.get_shape(%lay_734) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %e0_735, %e1_736, %e2_737, %e3_738 = cute.get_leaves(%264) : !cute.shape<"((8,8),1,1)">
        %iter_739 = cute.get_iter(%view_732) : !memref_gmem_bf16_5
        %view_740 = cute.make_view(%iter_739) : !memref_gmem_bf16_6
        %iter_741 = cute.get_iter(%view_740) : !memref_gmem_bf16_6
        %iter_742 = cute.get_iter(%view_740) : !memref_gmem_bf16_6
        %lay_743 = cute.get_layout(%dst_partitioned) : !memref_smem_bf16_1
        %shape_744 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_745 = cute.make_layout() : !cute.layout<"1:0">
        %append_746 = cute.append_to_rank<2> (%lay_743, %lay_745) : !cute.layout<"((8,8),1,1):((1,512),0,0)">, !cute.layout<"1:0">
        %view_747 = cute.make_view(%iter_115, %append_746) : !memref_smem_bf16_1
        %iter_748 = cute.get_iter(%view_747) : !memref_smem_bf16_1
        %lay_749 = cute.get_layout(%view_747) : !memref_smem_bf16_1
        %265 = cute.get_shape(%lay_749) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %e0_750, %e1_751, %e2_752, %e3_753 = cute.get_leaves(%265) : !cute.shape<"((8,8),1,1)">
        %iter_754 = cute.get_iter(%view_747) : !memref_smem_bf16_1
        %view_755 = cute.make_view(%iter_754) : !memref_smem_bf16_2
        %iter_756 = cute.get_iter(%view_755) : !memref_smem_bf16_2
        %iter_757 = cute.get_iter(%view_755) : !memref_smem_bf16_2
        %lay_758 = cute.get_layout(%rmem_153) : !memref_rmem_i8_
        %shape_759 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_760 = cute.make_layout() : !cute.layout<"1:0">
        %append_761 = cute.append_to_rank<2> (%lay_758, %lay_760) : !cute.layout<"(8,1,1):(1,0,1)">, !cute.layout<"1:0">
        %view_762 = cute.make_view(%iter_155, %append_761) : !memref_rmem_i8_
        %iter_763 = cute.get_iter(%view_762) : !memref_rmem_i8_
        %lay_764 = cute.get_layout(%view_762) : !memref_rmem_i8_
        %266 = cute.get_shape(%lay_764) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
        %e0_765, %e1_766, %e2_767 = cute.get_leaves(%266) : !cute.shape<"(8,1,1)">
        %iter_768 = cute.get_iter(%view_762) : !memref_rmem_i8_
        %view_769 = cute.make_view(%iter_768) : !memref_rmem_i8_1
        %iter_770 = cute.get_iter(%view_769) : !memref_rmem_i8_1
        %iter_771 = cute.get_iter(%view_769) : !memref_rmem_i8_1
        %lay_772 = cute.get_layout(%view_740) : !memref_gmem_bf16_6
        %267 = cute.get_shape(%lay_772) : (!cute.layout<"((8,8),(1,1)):((1,512),(0,0))">) -> !cute.shape<"((8,8),(1,1))">
        %e0_773, %e1_774, %e2_775, %e3_776 = cute.get_leaves(%267) : !cute.shape<"((8,8),(1,1))">
        %lay_777 = cute.get_layout(%view_755) : !memref_smem_bf16_2
        %268 = cute.get_shape(%lay_777) : (!cute.layout<"((8,8),(1,1)):((1,512),(0,0))">) -> !cute.shape<"((8,8),(1,1))">
        %e0_778, %e1_779, %e2_780, %e3_781 = cute.get_leaves(%268) : !cute.shape<"((8,8),(1,1))">
        %lay_782 = cute.get_layout(%view_740) : !memref_gmem_bf16_6
        %sz_783 = cute.size(%lay_782) <{mode = [1]}> : (!cute.layout<"((8,8),(1,1)):((1,512),(0,0))">) -> !cute.int_tuple<"1">
        %e0_784 = cute.get_leaves(%sz_783) : !cute.int_tuple<"1">
        %lay_785 = cute.get_layout(%view_755) : !memref_smem_bf16_2
        %sz_786 = cute.size(%lay_785) <{mode = [1]}> : (!cute.layout<"((8,8),(1,1)):((1,512),(0,0))">) -> !cute.int_tuple<"1">
        %e0_787 = cute.get_leaves(%sz_786) : !cute.int_tuple<"1">
        %269 = cute.static : !cute.layout<"1:0">
        %iter_788 = cute.get_iter(%view_740) : !memref_gmem_bf16_6
        %iter_789 = cute.get_iter(%view_755) : !memref_smem_bf16_2
        %lay_790 = cute.get_layout(%view_740) : !memref_gmem_bf16_6
        %lay_791 = cute.get_layout(%view_755) : !memref_smem_bf16_2
        %append_792 = cute.append_to_rank<2> (%lay_790, %269) : !cute.layout<"((8,8),(1,1)):((1,512),(0,0))">, !cute.layout<"1:0">
        %append_793 = cute.append_to_rank<2> (%lay_791, %269) : !cute.layout<"((8,8),(1,1)):((1,512),(0,0))">, !cute.layout<"1:0">
        %lay_794 = cute.make_layout() : !cute.layout<"((8,8),((1,1))):((1,512),((0,0)))">
        %lay_795 = cute.make_layout() : !cute.layout<"((8,8),((1,1))):((1,512),((0,0)))">
        %iter_796 = cute.get_iter(%view_769) : !memref_rmem_i8_1
        %lay_797 = cute.get_layout(%view_769) : !memref_rmem_i8_1
        %append_798 = cute.append_to_rank<2> (%lay_797, %269) : !cute.layout<"(8,(1,1)):(1,(0,1))">, !cute.layout<"1:0">
        %lay_799 = cute.make_layout() : !cute.layout<"(8,((1,1))):(1,((0,1)))">
        %sz_800 = cute.size(%lay_794) <{mode = [1]}> : (!cute.layout<"((8,8),((1,1))):((1,512),((0,0)))">) -> !cute.int_tuple<"1">
        %270 = cute.get_scalars(%sz_800) : !cute.int_tuple<"1">
        %c0_i32_801 = arith.constant 0 : i32
        %c1_i32_802 = arith.constant 1 : i32
        scf.for %arg4 = %c0_i32_801 to %270 step %c1_i32_802  : i32 {
          %coord_803 = cute.make_coord(%arg4) : (i32) -> !cute.coord<"(_,?)">
          %slice = cute.slice(%lay_794, %coord_803) : !cute.layout<"((8,8),((1,1))):((1,512),((0,0)))">, !cute.coord<"(_,?)">
          %idx_804 = cute.crd2idx(%coord_803, %lay_794) : (!cute.coord<"(_,?)">, !cute.layout<"((8,8),((1,1))):((1,512),((0,0)))">) -> !cute.int_tuple<"0">
          %ptr_805 = cute.add_offset(%iter_788, %idx_804) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, gmem, align<16>>
          %view_806 = cute.make_view(%ptr_805, %slice) : !memref_gmem_bf16_7
          %slice_807 = cute.slice(%lay_795, %coord_803) : !cute.layout<"((8,8),((1,1))):((1,512),((0,0)))">, !cute.coord<"(_,?)">
          %idx_808 = cute.crd2idx(%coord_803, %lay_795) : (!cute.coord<"(_,?)">, !cute.layout<"((8,8),((1,1))):((1,512),((0,0)))">) -> !cute.int_tuple<"0">
          %ptr_809 = cute.add_offset(%iter_789, %idx_808) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, smem, align<16>>
          %view_810 = cute.make_view(%ptr_809, %slice_807) : !memref_smem_bf16_3
          %slice_811 = cute.slice(%lay_799, %coord_803) : !cute.layout<"(8,((1,1))):(1,((0,1)))">, !cute.coord<"(_,?)">
          %idx_812 = cute.crd2idx(%coord_803, %lay_799) : (!cute.coord<"(_,?)">, !cute.layout<"(8,((1,1))):(1,((0,1)))">) -> !cute.int_tuple<"?">
          %ptr_813 = cute.add_offset(%iter_796, %idx_812) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %view_814 = cute.make_view(%ptr_813, %slice_811) : !memref_rmem_i8_2
          cute.copy_atom_call(%atom, %view_806, %view_810, %view_814) : (!cute_nvgpu.atom.simt_async_copy<bf16, cache = always, 128 b>, !memref_gmem_bf16_7, !memref_smem_bf16_3, !memref_rmem_i8_2) -> ()
        } {llvm.loop_annotation = #loop_annotation}
      }
      nvvm.cp.async.commit.group
      %coord_319 = cute.make_coord(%11) : (i32) -> !cute.coord<"?">
      %src_partitioned_320 = cute.tiled.copy.partition_S(%35, %view_86, %coord_319) : (!copy_simt, !cute.coord_tensor<"(?{div=2},0)", "(2,4096):(1@0,1@1)">, !cute.coord<"?">) -> !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %iter_321 = cute.get_iter(%src_partitioned_320) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %e0_322, %e1_323 = cute.get_leaves(%iter_321) : !cute.int_tuple<"(?,?{div=8})">
      %114 = cute.get_scalars(%e0_322) : !cute.int_tuple<"?">
      %115 = cute.get_scalars(%e1_323) : !cute.int_tuple<"?{div=8}">
      %lay_324 = cute.get_layout(%src_partitioned_320) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %sz_325 = cute.size(%lay_324) <{mode = [0, 1]}> : (!cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"8">
      %e0_326 = cute.get_leaves(%sz_325) : !cute.int_tuple<"8">
      %lay_327 = cute.get_layout(%src_partitioned_320) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %sz_328 = cute.size(%lay_327) <{mode = [1]}> : (!cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"1">
      %e0_329 = cute.get_leaves(%sz_328) : !cute.int_tuple<"1">
      %lay_330 = cute.get_layout(%src_partitioned_320) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %sz_331 = cute.size(%lay_330) <{mode = [2]}> : (!cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"1">
      %e0_332 = cute.get_leaves(%sz_331) : !cute.int_tuple<"1">
      %lay_333 = cute.get_layout(%src_partitioned_320) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %sz_334 = cute.size(%lay_333) <{mode = [2]}> : (!cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"1">
      %e0_335 = cute.get_leaves(%sz_334) : !cute.int_tuple<"1">
      %shape_336 = cute.make_shape() : () -> !cute.shape<"(8,1,1)">
      %stride_337 = cute.make_stride() : () -> !cute.stride<"(1,0,1)">
      %lay_338 = cute.make_layout() : !cute.layout<"(8,1,1):(1,0,1)">
      %rmem_339 = cute.memref.alloca(%lay_338) : !memref_rmem_i8_
      %iter_340 = cute.get_iter(%rmem_339) : !memref_rmem_i8_
      %iter_341 = cute.get_iter(%rmem_339) : !memref_rmem_i8_
      %lay_342 = cute.get_layout(%rmem_339) : !memref_rmem_i8_
      %116 = cute.get_shape(%lay_342) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %e0_343, %e1_344, %e2_345 = cute.get_leaves(%116) : !cute.shape<"(8,1,1)">
      %coord_346 = cute.make_coord() : () -> !cute.coord<"((0,0),0,0)">
      %lay_347 = cute.get_layout(%src_partitioned_320) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %idx_348 = cute.crd2idx(%coord_346, %lay_347) : (!cute.coord<"((0,0),0,0)">, !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"(0,0)">
      %iter_349 = cute.get_iter(%src_partitioned_320) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %tup_350 = cute.add_offset(%iter_349, %idx_348) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,0)">) -> !cute.int_tuple<"(?,?{div=8})">
      %view_351 = cute.make_view(%tup_350) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %iter_352 = cute.get_iter(%view_351) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_353, %e1_354 = cute.get_leaves(%iter_352) : !cute.int_tuple<"(?,?{div=8})">
      %117 = cute.get_scalars(%e0_353) : !cute.int_tuple<"?">
      %118 = cute.get_scalars(%e1_354) : !cute.int_tuple<"?{div=8}">
      %iter_355 = cute.get_iter(%view_351) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_356, %e1_357 = cute.get_leaves(%iter_355) : !cute.int_tuple<"(?,?{div=8})">
      %119 = cute.get_scalars(%e0_356) : !cute.int_tuple<"?">
      %120 = cute.get_scalars(%e1_357) : !cute.int_tuple<"?{div=8}">
      %iter_358 = cute.get_iter(%view_351) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_359, %e1_360 = cute.get_leaves(%iter_358) : !cute.int_tuple<"(?,?{div=8})">
      %121 = cute.get_scalars(%e0_359) : !cute.int_tuple<"?">
      %122 = cute.get_scalars(%e1_360) : !cute.int_tuple<"?{div=8}">
      %coord_361 = cute.make_coord(%e1_360) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_362 = cute.make_coord() : () -> !cute.coord<"4096">
      %123 = cute.elem_less(%coord_361, %coord_362) : !cute.coord<"?{div=8}">, !cute.coord<"4096">
      %124 = arith.extui %123 : i1 to i8
      %coord_363 = cute.make_coord() : () -> !cute.coord<"(0,0,0)">
      cute.memref.store(%rmem_339, %coord_363, %124) : (!memref_rmem_i8_, !cute.coord<"(0,0,0)">, i8) -> ()
      %coord_364 = cute.make_coord() : () -> !cute.coord<"((0,1),0,0)">
      %lay_365 = cute.get_layout(%src_partitioned_320) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %idx_366 = cute.crd2idx(%coord_364, %lay_365) : (!cute.coord<"((0,1),0,0)">, !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"(0,512)">
      %iter_367 = cute.get_iter(%src_partitioned_320) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %tup_368 = cute.add_offset(%iter_367, %idx_366) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,512)">) -> !cute.int_tuple<"(?,?{div=8})">
      %view_369 = cute.make_view(%tup_368) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %iter_370 = cute.get_iter(%view_369) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_371, %e1_372 = cute.get_leaves(%iter_370) : !cute.int_tuple<"(?,?{div=8})">
      %125 = cute.get_scalars(%e0_371) : !cute.int_tuple<"?">
      %126 = cute.get_scalars(%e1_372) : !cute.int_tuple<"?{div=8}">
      %iter_373 = cute.get_iter(%view_369) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_374, %e1_375 = cute.get_leaves(%iter_373) : !cute.int_tuple<"(?,?{div=8})">
      %127 = cute.get_scalars(%e0_374) : !cute.int_tuple<"?">
      %128 = cute.get_scalars(%e1_375) : !cute.int_tuple<"?{div=8}">
      %iter_376 = cute.get_iter(%view_369) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_377, %e1_378 = cute.get_leaves(%iter_376) : !cute.int_tuple<"(?,?{div=8})">
      %129 = cute.get_scalars(%e0_377) : !cute.int_tuple<"?">
      %130 = cute.get_scalars(%e1_378) : !cute.int_tuple<"?{div=8}">
      %coord_379 = cute.make_coord(%e1_378) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_380 = cute.make_coord() : () -> !cute.coord<"4096">
      %131 = cute.elem_less(%coord_379, %coord_380) : !cute.coord<"?{div=8}">, !cute.coord<"4096">
      %132 = arith.extui %131 : i1 to i8
      %coord_381 = cute.make_coord() : () -> !cute.coord<"(1,0,0)">
      cute.memref.store(%rmem_339, %coord_381, %132) : (!memref_rmem_i8_, !cute.coord<"(1,0,0)">, i8) -> ()
      %coord_382 = cute.make_coord() : () -> !cute.coord<"((0,2),0,0)">
      %lay_383 = cute.get_layout(%src_partitioned_320) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %idx_384 = cute.crd2idx(%coord_382, %lay_383) : (!cute.coord<"((0,2),0,0)">, !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"(0,1024)">
      %iter_385 = cute.get_iter(%src_partitioned_320) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %tup_386 = cute.add_offset(%iter_385, %idx_384) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,1024)">) -> !cute.int_tuple<"(?,?{div=8})">
      %view_387 = cute.make_view(%tup_386) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %iter_388 = cute.get_iter(%view_387) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_389, %e1_390 = cute.get_leaves(%iter_388) : !cute.int_tuple<"(?,?{div=8})">
      %133 = cute.get_scalars(%e0_389) : !cute.int_tuple<"?">
      %134 = cute.get_scalars(%e1_390) : !cute.int_tuple<"?{div=8}">
      %iter_391 = cute.get_iter(%view_387) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_392, %e1_393 = cute.get_leaves(%iter_391) : !cute.int_tuple<"(?,?{div=8})">
      %135 = cute.get_scalars(%e0_392) : !cute.int_tuple<"?">
      %136 = cute.get_scalars(%e1_393) : !cute.int_tuple<"?{div=8}">
      %iter_394 = cute.get_iter(%view_387) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_395, %e1_396 = cute.get_leaves(%iter_394) : !cute.int_tuple<"(?,?{div=8})">
      %137 = cute.get_scalars(%e0_395) : !cute.int_tuple<"?">
      %138 = cute.get_scalars(%e1_396) : !cute.int_tuple<"?{div=8}">
      %coord_397 = cute.make_coord(%e1_396) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_398 = cute.make_coord() : () -> !cute.coord<"4096">
      %139 = cute.elem_less(%coord_397, %coord_398) : !cute.coord<"?{div=8}">, !cute.coord<"4096">
      %140 = arith.extui %139 : i1 to i8
      %coord_399 = cute.make_coord() : () -> !cute.coord<"(2,0,0)">
      cute.memref.store(%rmem_339, %coord_399, %140) : (!memref_rmem_i8_, !cute.coord<"(2,0,0)">, i8) -> ()
      %coord_400 = cute.make_coord() : () -> !cute.coord<"((0,3),0,0)">
      %lay_401 = cute.get_layout(%src_partitioned_320) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %idx_402 = cute.crd2idx(%coord_400, %lay_401) : (!cute.coord<"((0,3),0,0)">, !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"(0,1536)">
      %iter_403 = cute.get_iter(%src_partitioned_320) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %tup_404 = cute.add_offset(%iter_403, %idx_402) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,1536)">) -> !cute.int_tuple<"(?,?{div=8})">
      %view_405 = cute.make_view(%tup_404) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %iter_406 = cute.get_iter(%view_405) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_407, %e1_408 = cute.get_leaves(%iter_406) : !cute.int_tuple<"(?,?{div=8})">
      %141 = cute.get_scalars(%e0_407) : !cute.int_tuple<"?">
      %142 = cute.get_scalars(%e1_408) : !cute.int_tuple<"?{div=8}">
      %iter_409 = cute.get_iter(%view_405) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_410, %e1_411 = cute.get_leaves(%iter_409) : !cute.int_tuple<"(?,?{div=8})">
      %143 = cute.get_scalars(%e0_410) : !cute.int_tuple<"?">
      %144 = cute.get_scalars(%e1_411) : !cute.int_tuple<"?{div=8}">
      %iter_412 = cute.get_iter(%view_405) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_413, %e1_414 = cute.get_leaves(%iter_412) : !cute.int_tuple<"(?,?{div=8})">
      %145 = cute.get_scalars(%e0_413) : !cute.int_tuple<"?">
      %146 = cute.get_scalars(%e1_414) : !cute.int_tuple<"?{div=8}">
      %coord_415 = cute.make_coord(%e1_414) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_416 = cute.make_coord() : () -> !cute.coord<"4096">
      %147 = cute.elem_less(%coord_415, %coord_416) : !cute.coord<"?{div=8}">, !cute.coord<"4096">
      %148 = arith.extui %147 : i1 to i8
      %coord_417 = cute.make_coord() : () -> !cute.coord<"(3,0,0)">
      cute.memref.store(%rmem_339, %coord_417, %148) : (!memref_rmem_i8_, !cute.coord<"(3,0,0)">, i8) -> ()
      %coord_418 = cute.make_coord() : () -> !cute.coord<"((0,4),0,0)">
      %lay_419 = cute.get_layout(%src_partitioned_320) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %idx_420 = cute.crd2idx(%coord_418, %lay_419) : (!cute.coord<"((0,4),0,0)">, !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"(0,2048)">
      %iter_421 = cute.get_iter(%src_partitioned_320) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %tup_422 = cute.add_offset(%iter_421, %idx_420) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,2048)">) -> !cute.int_tuple<"(?,?{div=8})">
      %view_423 = cute.make_view(%tup_422) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %iter_424 = cute.get_iter(%view_423) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_425, %e1_426 = cute.get_leaves(%iter_424) : !cute.int_tuple<"(?,?{div=8})">
      %149 = cute.get_scalars(%e0_425) : !cute.int_tuple<"?">
      %150 = cute.get_scalars(%e1_426) : !cute.int_tuple<"?{div=8}">
      %iter_427 = cute.get_iter(%view_423) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_428, %e1_429 = cute.get_leaves(%iter_427) : !cute.int_tuple<"(?,?{div=8})">
      %151 = cute.get_scalars(%e0_428) : !cute.int_tuple<"?">
      %152 = cute.get_scalars(%e1_429) : !cute.int_tuple<"?{div=8}">
      %iter_430 = cute.get_iter(%view_423) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_431, %e1_432 = cute.get_leaves(%iter_430) : !cute.int_tuple<"(?,?{div=8})">
      %153 = cute.get_scalars(%e0_431) : !cute.int_tuple<"?">
      %154 = cute.get_scalars(%e1_432) : !cute.int_tuple<"?{div=8}">
      %coord_433 = cute.make_coord(%e1_432) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_434 = cute.make_coord() : () -> !cute.coord<"4096">
      %155 = cute.elem_less(%coord_433, %coord_434) : !cute.coord<"?{div=8}">, !cute.coord<"4096">
      %156 = arith.extui %155 : i1 to i8
      %coord_435 = cute.make_coord() : () -> !cute.coord<"(4,0,0)">
      cute.memref.store(%rmem_339, %coord_435, %156) : (!memref_rmem_i8_, !cute.coord<"(4,0,0)">, i8) -> ()
      %coord_436 = cute.make_coord() : () -> !cute.coord<"((0,5),0,0)">
      %lay_437 = cute.get_layout(%src_partitioned_320) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %idx_438 = cute.crd2idx(%coord_436, %lay_437) : (!cute.coord<"((0,5),0,0)">, !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"(0,2560)">
      %iter_439 = cute.get_iter(%src_partitioned_320) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %tup_440 = cute.add_offset(%iter_439, %idx_438) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,2560)">) -> !cute.int_tuple<"(?,?{div=8})">
      %view_441 = cute.make_view(%tup_440) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %iter_442 = cute.get_iter(%view_441) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_443, %e1_444 = cute.get_leaves(%iter_442) : !cute.int_tuple<"(?,?{div=8})">
      %157 = cute.get_scalars(%e0_443) : !cute.int_tuple<"?">
      %158 = cute.get_scalars(%e1_444) : !cute.int_tuple<"?{div=8}">
      %iter_445 = cute.get_iter(%view_441) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_446, %e1_447 = cute.get_leaves(%iter_445) : !cute.int_tuple<"(?,?{div=8})">
      %159 = cute.get_scalars(%e0_446) : !cute.int_tuple<"?">
      %160 = cute.get_scalars(%e1_447) : !cute.int_tuple<"?{div=8}">
      %iter_448 = cute.get_iter(%view_441) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_449, %e1_450 = cute.get_leaves(%iter_448) : !cute.int_tuple<"(?,?{div=8})">
      %161 = cute.get_scalars(%e0_449) : !cute.int_tuple<"?">
      %162 = cute.get_scalars(%e1_450) : !cute.int_tuple<"?{div=8}">
      %coord_451 = cute.make_coord(%e1_450) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_452 = cute.make_coord() : () -> !cute.coord<"4096">
      %163 = cute.elem_less(%coord_451, %coord_452) : !cute.coord<"?{div=8}">, !cute.coord<"4096">
      %164 = arith.extui %163 : i1 to i8
      %coord_453 = cute.make_coord() : () -> !cute.coord<"(5,0,0)">
      cute.memref.store(%rmem_339, %coord_453, %164) : (!memref_rmem_i8_, !cute.coord<"(5,0,0)">, i8) -> ()
      %coord_454 = cute.make_coord() : () -> !cute.coord<"((0,6),0,0)">
      %lay_455 = cute.get_layout(%src_partitioned_320) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %idx_456 = cute.crd2idx(%coord_454, %lay_455) : (!cute.coord<"((0,6),0,0)">, !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"(0,3072)">
      %iter_457 = cute.get_iter(%src_partitioned_320) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %tup_458 = cute.add_offset(%iter_457, %idx_456) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,3072)">) -> !cute.int_tuple<"(?,?{div=8})">
      %view_459 = cute.make_view(%tup_458) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %iter_460 = cute.get_iter(%view_459) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_461, %e1_462 = cute.get_leaves(%iter_460) : !cute.int_tuple<"(?,?{div=8})">
      %165 = cute.get_scalars(%e0_461) : !cute.int_tuple<"?">
      %166 = cute.get_scalars(%e1_462) : !cute.int_tuple<"?{div=8}">
      %iter_463 = cute.get_iter(%view_459) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_464, %e1_465 = cute.get_leaves(%iter_463) : !cute.int_tuple<"(?,?{div=8})">
      %167 = cute.get_scalars(%e0_464) : !cute.int_tuple<"?">
      %168 = cute.get_scalars(%e1_465) : !cute.int_tuple<"?{div=8}">
      %iter_466 = cute.get_iter(%view_459) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_467, %e1_468 = cute.get_leaves(%iter_466) : !cute.int_tuple<"(?,?{div=8})">
      %169 = cute.get_scalars(%e0_467) : !cute.int_tuple<"?">
      %170 = cute.get_scalars(%e1_468) : !cute.int_tuple<"?{div=8}">
      %coord_469 = cute.make_coord(%e1_468) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_470 = cute.make_coord() : () -> !cute.coord<"4096">
      %171 = cute.elem_less(%coord_469, %coord_470) : !cute.coord<"?{div=8}">, !cute.coord<"4096">
      %172 = arith.extui %171 : i1 to i8
      %coord_471 = cute.make_coord() : () -> !cute.coord<"(6,0,0)">
      cute.memref.store(%rmem_339, %coord_471, %172) : (!memref_rmem_i8_, !cute.coord<"(6,0,0)">, i8) -> ()
      %coord_472 = cute.make_coord() : () -> !cute.coord<"((0,7),0,0)">
      %lay_473 = cute.get_layout(%src_partitioned_320) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %idx_474 = cute.crd2idx(%coord_472, %lay_473) : (!cute.coord<"((0,7),0,0)">, !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"(0,3584)">
      %iter_475 = cute.get_iter(%src_partitioned_320) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %tup_476 = cute.add_offset(%iter_475, %idx_474) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,3584)">) -> !cute.int_tuple<"(?,?{div=8})">
      %view_477 = cute.make_view(%tup_476) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %iter_478 = cute.get_iter(%view_477) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_479, %e1_480 = cute.get_leaves(%iter_478) : !cute.int_tuple<"(?,?{div=8})">
      %173 = cute.get_scalars(%e0_479) : !cute.int_tuple<"?">
      %174 = cute.get_scalars(%e1_480) : !cute.int_tuple<"?{div=8}">
      %iter_481 = cute.get_iter(%view_477) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_482, %e1_483 = cute.get_leaves(%iter_481) : !cute.int_tuple<"(?,?{div=8})">
      %175 = cute.get_scalars(%e0_482) : !cute.int_tuple<"?">
      %176 = cute.get_scalars(%e1_483) : !cute.int_tuple<"?{div=8}">
      %iter_484 = cute.get_iter(%view_477) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_485, %e1_486 = cute.get_leaves(%iter_484) : !cute.int_tuple<"(?,?{div=8})">
      %177 = cute.get_scalars(%e0_485) : !cute.int_tuple<"?">
      %178 = cute.get_scalars(%e1_486) : !cute.int_tuple<"?{div=8}">
      %coord_487 = cute.make_coord(%e1_486) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_488 = cute.make_coord() : () -> !cute.coord<"4096">
      %179 = cute.elem_less(%coord_487, %coord_488) : !cute.coord<"?{div=8}">, !cute.coord<"4096">
      %180 = arith.extui %179 : i1 to i8
      %coord_489 = cute.make_coord() : () -> !cute.coord<"(7,0,0)">
      cute.memref.store(%rmem_339, %coord_489, %180) : (!memref_rmem_i8_, !cute.coord<"(7,0,0)">, i8) -> ()
      %lay_490 = cute.get_layout(%src_partitioned_132) : !memref_gmem_bf16_5
      %181 = cute.get_shape(%lay_490) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %e0_491, %e1_492, %e2_493, %e3_494 = cute.get_leaves(%181) : !cute.shape<"((8,8),1,1)">
      %lay_495 = cute.get_layout(%rmem_135) : !memref_rmem_bf16_
      %182 = cute.get_shape(%lay_495) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %e0_496, %e1_497, %e2_498, %e3_499 = cute.get_leaves(%182) : !cute.shape<"((8,8),1,1)">
      %lay_500 = cute.get_layout(%src_partitioned_132) : !memref_gmem_bf16_5
      %shape_501 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_502 = cute.make_layout() : !cute.layout<"1:0">
      %append = cute.append_to_rank<2> (%lay_500, %lay_502) : !cute.layout<"((8,8),1,1):((1,512),0,0)">, !cute.layout<"1:0">
      %view_503 = cute.make_view(%iter_133, %append) : !memref_gmem_bf16_5
      %iter_504 = cute.get_iter(%view_503) : !memref_gmem_bf16_5
      %lay_505 = cute.get_layout(%view_503) : !memref_gmem_bf16_5
      %183 = cute.get_shape(%lay_505) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %e0_506, %e1_507, %e2_508, %e3_509 = cute.get_leaves(%183) : !cute.shape<"((8,8),1,1)">
      %iter_510 = cute.get_iter(%view_503) : !memref_gmem_bf16_5
      %view_511 = cute.make_view(%iter_510) : !memref_gmem_bf16_6
      %iter_512 = cute.get_iter(%view_511) : !memref_gmem_bf16_6
      %iter_513 = cute.get_iter(%view_511) : !memref_gmem_bf16_6
      %lay_514 = cute.get_layout(%rmem_135) : !memref_rmem_bf16_
      %shape_515 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_516 = cute.make_layout() : !cute.layout<"1:0">
      %append_517 = cute.append_to_rank<2> (%lay_514, %lay_516) : !cute.layout<"((8,8),1,1):((1,8),0,0)">, !cute.layout<"1:0">
      %view_518 = cute.make_view(%iter_137, %append_517) : !memref_rmem_bf16_
      %iter_519 = cute.get_iter(%view_518) : !memref_rmem_bf16_
      %lay_520 = cute.get_layout(%view_518) : !memref_rmem_bf16_
      %184 = cute.get_shape(%lay_520) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %e0_521, %e1_522, %e2_523, %e3_524 = cute.get_leaves(%184) : !cute.shape<"((8,8),1,1)">
      %iter_525 = cute.get_iter(%view_518) : !memref_rmem_bf16_
      %view_526 = cute.make_view(%iter_525) : !memref_rmem_bf16_1
      %iter_527 = cute.get_iter(%view_526) : !memref_rmem_bf16_1
      %iter_528 = cute.get_iter(%view_526) : !memref_rmem_bf16_1
      %lay_529 = cute.get_layout(%rmem_339) : !memref_rmem_i8_
      %shape_530 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_531 = cute.make_layout() : !cute.layout<"1:0">
      %append_532 = cute.append_to_rank<2> (%lay_529, %lay_531) : !cute.layout<"(8,1,1):(1,0,1)">, !cute.layout<"1:0">
      %view_533 = cute.make_view(%iter_341, %append_532) : !memref_rmem_i8_
      %iter_534 = cute.get_iter(%view_533) : !memref_rmem_i8_
      %lay_535 = cute.get_layout(%view_533) : !memref_rmem_i8_
      %185 = cute.get_shape(%lay_535) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %e0_536, %e1_537, %e2_538 = cute.get_leaves(%185) : !cute.shape<"(8,1,1)">
      %iter_539 = cute.get_iter(%view_533) : !memref_rmem_i8_
      %view_540 = cute.make_view(%iter_539) : !memref_rmem_i8_1
      %iter_541 = cute.get_iter(%view_540) : !memref_rmem_i8_1
      %iter_542 = cute.get_iter(%view_540) : !memref_rmem_i8_1
      %lay_543 = cute.get_layout(%view_511) : !memref_gmem_bf16_6
      %186 = cute.get_shape(%lay_543) : (!cute.layout<"((8,8),(1,1)):((1,512),(0,0))">) -> !cute.shape<"((8,8),(1,1))">
      %e0_544, %e1_545, %e2_546, %e3_547 = cute.get_leaves(%186) : !cute.shape<"((8,8),(1,1))">
      %lay_548 = cute.get_layout(%view_526) : !memref_rmem_bf16_1
      %187 = cute.get_shape(%lay_548) : (!cute.layout<"((8,8),(1,1)):((1,8),(0,0))">) -> !cute.shape<"((8,8),(1,1))">
      %e0_549, %e1_550, %e2_551, %e3_552 = cute.get_leaves(%187) : !cute.shape<"((8,8),(1,1))">
      %lay_553 = cute.get_layout(%view_511) : !memref_gmem_bf16_6
      %sz_554 = cute.size(%lay_553) <{mode = [1]}> : (!cute.layout<"((8,8),(1,1)):((1,512),(0,0))">) -> !cute.int_tuple<"1">
      %e0_555 = cute.get_leaves(%sz_554) : !cute.int_tuple<"1">
      %lay_556 = cute.get_layout(%view_526) : !memref_rmem_bf16_1
      %sz_557 = cute.size(%lay_556) <{mode = [1]}> : (!cute.layout<"((8,8),(1,1)):((1,8),(0,0))">) -> !cute.int_tuple<"1">
      %e0_558 = cute.get_leaves(%sz_557) : !cute.int_tuple<"1">
      %188 = cute.static : !cute.layout<"1:0">
      %iter_559 = cute.get_iter(%view_511) : !memref_gmem_bf16_6
      %iter_560 = cute.get_iter(%view_526) : !memref_rmem_bf16_1
      %lay_561 = cute.get_layout(%view_511) : !memref_gmem_bf16_6
      %lay_562 = cute.get_layout(%view_526) : !memref_rmem_bf16_1
      %append_563 = cute.append_to_rank<2> (%lay_561, %188) : !cute.layout<"((8,8),(1,1)):((1,512),(0,0))">, !cute.layout<"1:0">
      %append_564 = cute.append_to_rank<2> (%lay_562, %188) : !cute.layout<"((8,8),(1,1)):((1,8),(0,0))">, !cute.layout<"1:0">
      %lay_565 = cute.make_layout() : !cute.layout<"((8,8),((1,1))):((1,512),((0,0)))">
      %lay_566 = cute.make_layout() : !cute.layout<"((8,8),((1,1))):((1,8),((0,0)))">
      %iter_567 = cute.get_iter(%view_540) : !memref_rmem_i8_1
      %lay_568 = cute.get_layout(%view_540) : !memref_rmem_i8_1
      %append_569 = cute.append_to_rank<2> (%lay_568, %188) : !cute.layout<"(8,(1,1)):(1,(0,1))">, !cute.layout<"1:0">
      %lay_570 = cute.make_layout() : !cute.layout<"(8,((1,1))):(1,((0,1)))">
      %sz_571 = cute.size(%lay_565) <{mode = [1]}> : (!cute.layout<"((8,8),((1,1))):((1,512),((0,0)))">) -> !cute.int_tuple<"1">
      %189 = cute.get_scalars(%sz_571) : !cute.int_tuple<"1">
      %c0_i32 = arith.constant 0 : i32
      %c1_i32 = arith.constant 1 : i32
      scf.for %arg4 = %c0_i32 to %189 step %c1_i32  : i32 {
        %coord_718 = cute.make_coord(%arg4) : (i32) -> !cute.coord<"(_,?)">
        %slice = cute.slice(%lay_565, %coord_718) : !cute.layout<"((8,8),((1,1))):((1,512),((0,0)))">, !cute.coord<"(_,?)">
        %idx_719 = cute.crd2idx(%coord_718, %lay_565) : (!cute.coord<"(_,?)">, !cute.layout<"((8,8),((1,1))):((1,512),((0,0)))">) -> !cute.int_tuple<"0">
        %ptr_720 = cute.add_offset(%iter_559, %idx_719) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, gmem, align<16>>
        %view_721 = cute.make_view(%ptr_720, %slice) : !memref_gmem_bf16_7
        %slice_722 = cute.slice(%lay_566, %coord_718) : !cute.layout<"((8,8),((1,1))):((1,8),((0,0)))">, !cute.coord<"(_,?)">
        %idx_723 = cute.crd2idx(%coord_718, %lay_566) : (!cute.coord<"(_,?)">, !cute.layout<"((8,8),((1,1))):((1,8),((0,0)))">) -> !cute.int_tuple<"0">
        %ptr_724 = cute.add_offset(%iter_560, %idx_723) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, rmem, align<32>>
        %view_725 = cute.make_view(%ptr_724, %slice_722) : !memref_rmem_bf16_2
        %slice_726 = cute.slice(%lay_570, %coord_718) : !cute.layout<"(8,((1,1))):(1,((0,1)))">, !cute.coord<"(_,?)">
        %idx_727 = cute.crd2idx(%coord_718, %lay_570) : (!cute.coord<"(_,?)">, !cute.layout<"(8,((1,1))):(1,((0,1)))">) -> !cute.int_tuple<"?">
        %ptr_728 = cute.add_offset(%iter_567, %idx_727) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
        %view_729 = cute.make_view(%ptr_728, %slice_726) : !memref_rmem_i8_2
        cute.copy_atom_call(%atom_107, %view_721, %view_725, %view_729) : (!cute_nvgpu.atom.universal_copy<bf16, 128 b>, !memref_gmem_bf16_7, !memref_rmem_bf16_2, !memref_rmem_i8_2) -> ()
      } {llvm.loop_annotation = #loop_annotation}
      nvvm.cp.async.wait.group 0
      %lay_572 = cute.get_layout(%dst_partitioned) : !memref_smem_bf16_1
      %190 = cute.get_shape(%lay_572) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %e0_573, %e1_574, %e2_575, %e3_576 = cute.get_leaves(%190) : !cute.shape<"((8,8),1,1)">
      %lay_577 = cute.get_layout(%rmem) : !memref_rmem_bf16_
      %191 = cute.get_shape(%lay_577) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %e0_578, %e1_579, %e2_580, %e3_581 = cute.get_leaves(%191) : !cute.shape<"((8,8),1,1)">
      %lay_582 = cute.get_layout(%dst_partitioned) : !memref_smem_bf16_1
      %lay_583 = cute.get_layout(%rmem) : !memref_rmem_bf16_
      %rinv = cute.right_inverse(%lay_583) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.layout<"64:1">
      %lay_584 = cute.make_layout() : !cute.layout<"(8,8):(1,512)">
      %coalesce = cute.coalesce(%lay_584) : (!cute.layout<"(8,8):(1,512)">) -> !cute.layout<"(8,8):(1,512)">
      %192 = cute.get_shape(%coalesce) : (!cute.layout<"(8,8):(1,512)">) -> !cute.shape<"(8,8)">
      %e0_585, %e1_586 = cute.get_leaves(%192) : !cute.shape<"(8,8)">
      %193 = cute.get_stride(%coalesce) : (!cute.layout<"(8,8):(1,512)">) -> !cute.stride<"(1,512)">
      %e0_587, %e1_588 = cute.get_leaves(%193) : !cute.stride<"(1,512)">
      %194 = cute.get_shape(%coalesce) : (!cute.layout<"(8,8):(1,512)">) -> !cute.shape<"(8,8)">
      %e0_589, %e1_590 = cute.get_leaves(%194) : !cute.shape<"(8,8)">
      %195 = cute.get_shape(%coalesce) : (!cute.layout<"(8,8):(1,512)">) -> !cute.shape<"(8,8)">
      %e0_591, %e1_592 = cute.get_leaves(%195) : !cute.shape<"(8,8)">
      %196 = cute.get(%coalesce) <{mode = [0]}> : !cute.layout<"(8,8):(1,512)"> -> !cute.layout<"8:1">
      %lay_593 = cute.make_layout() : !cute.layout<"8:1">
      %sz_594 = cute.size(%lay_593) : (!cute.layout<"8:1">) -> !cute.int_tuple<"8">
      %e0_595 = cute.get_leaves(%sz_594) : !cute.int_tuple<"8">
      %lay_596 = cute.get_layout(%dst_partitioned) : !memref_smem_bf16_1
      %lay_597 = cute.get_layout(%rmem) : !memref_rmem_bf16_
      %iter_598 = cute.get_iter(%dst_partitioned) : !memref_smem_bf16_1
      %view_599 = cute.make_view(%iter_598) : !memref_smem_bf16_4
      %iter_600 = cute.get_iter(%view_599) : !memref_smem_bf16_4
      %iter_601 = cute.get_iter(%view_599) : !memref_smem_bf16_4
      %iter_602 = cute.get_iter(%rmem) : !memref_rmem_bf16_
      %view_603 = cute.make_view(%iter_602) : !memref_rmem_bf16_3
      %iter_604 = cute.get_iter(%view_603) : !memref_rmem_bf16_3
      %iter_605 = cute.get_iter(%view_603) : !memref_rmem_bf16_3
      %shape_606 = cute.make_shape() : () -> !cute.shape<"8">
      %lay_607 = cute.make_layout() : !cute.layout<"8:1">
      %iter_608 = cute.get_iter(%view_599) : !memref_smem_bf16_4
      %view_609 = cute.make_view(%iter_608) : !memref_smem_bf16_4
      %iter_610 = cute.get_iter(%view_609) : !memref_smem_bf16_4
      %iter_611 = cute.get_iter(%view_609) : !memref_smem_bf16_4
      %shape_612 = cute.make_shape() : () -> !cute.shape<"8">
      %lay_613 = cute.make_layout() : !cute.layout<"8:1">
      %iter_614 = cute.get_iter(%view_603) : !memref_rmem_bf16_3
      %view_615 = cute.make_view(%iter_614) : !memref_rmem_bf16_3
      %iter_616 = cute.get_iter(%view_615) : !memref_rmem_bf16_3
      %iter_617 = cute.get_iter(%view_615) : !memref_rmem_bf16_3
      %atom_618 = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<bf16, 128 b>
      %197 = cute.static : !cute.layout<"1:0">
      %iter_619 = cute.get_iter(%view_609) : !memref_smem_bf16_4
      %iter_620 = cute.get_iter(%view_615) : !memref_rmem_bf16_3
      %lay_621 = cute.get_layout(%view_609) : !memref_smem_bf16_4
      %lay_622 = cute.get_layout(%view_615) : !memref_rmem_bf16_3
      %append_623 = cute.append_to_rank<2> (%lay_621, %197) : !cute.layout<"(8,8):(1,512)">, !cute.layout<"1:0">
      %append_624 = cute.append_to_rank<2> (%lay_622, %197) : !cute.layout<"(8,8):(1,8)">, !cute.layout<"1:0">
      %lay_625 = cute.make_layout() : !cute.layout<"(8,(8)):(1,(512))">
      %lay_626 = cute.make_layout() : !cute.layout<"(8,(8)):(1,(8))">
      %sz_627 = cute.size(%lay_625) <{mode = [1]}> : (!cute.layout<"(8,(8)):(1,(512))">) -> !cute.int_tuple<"8">
      %198 = cute.get_scalars(%sz_627) : !cute.int_tuple<"8">
      %c0_i32_628 = arith.constant 0 : i32
      %c1_i32_629 = arith.constant 1 : i32
      scf.for %arg4 = %c0_i32_628 to %198 step %c1_i32_629  : i32 {
        %coord_718 = cute.make_coord(%arg4) : (i32) -> !cute.coord<"(_,?)">
        %slice = cute.slice(%lay_625, %coord_718) : !cute.layout<"(8,(8)):(1,(512))">, !cute.coord<"(_,?)">
        %idx_719 = cute.crd2idx(%coord_718, %lay_625) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(8)):(1,(512))">) -> !cute.int_tuple<"?{div=512}">
        %ptr_720 = cute.add_offset(%iter_619, %idx_719) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=512}">) -> !cute.ptr<bf16, smem, align<16>>
        %view_721 = cute.make_view(%ptr_720, %slice) : !memref_smem_bf16_5
        %slice_722 = cute.slice(%lay_626, %coord_718) : !cute.layout<"(8,(8)):(1,(8))">, !cute.coord<"(_,?)">
        %idx_723 = cute.crd2idx(%coord_718, %lay_626) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(8)):(1,(8))">) -> !cute.int_tuple<"?{div=8}">
        %ptr_724 = cute.add_offset(%iter_620, %idx_723) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
        %view_725 = cute.make_view(%ptr_724, %slice_722) : !memref_rmem_bf16_4
        cute.copy_atom_call(%atom_618, %view_721, %view_725) : (!cute_nvgpu.atom.universal_copy<bf16, 128 b>, !memref_smem_bf16_5, !memref_rmem_bf16_4) -> ()
      } {llvm.loop_annotation = #loop_annotation}
      %199 = cute.memref.load_vec %rmem : !memref_rmem_bf16_
      %200 = arith.extf %199 : vector<64xbf16> to vector<64xf32>
      %201 = arith.mulf %200, %200 : vector<64xf32>
      %cst = arith.constant 0.000000e+00 : f32
      %202 = vector.reduction <add>, %201, %cst : vector<64xf32> into f32
      %c-1_i32 = arith.constant -1 : i32
      %c16_i32 = arith.constant 16 : i32
      %c31_i32 = arith.constant 31 : i32
      %203 = nvvm.shfl.sync  bfly %c-1_i32, %202, %c16_i32, %c31_i32 : f32 -> f32
      %204 = arith.addf %203, %202 : f32
      %c8_i32 = arith.constant 8 : i32
      %205 = nvvm.shfl.sync  bfly %c-1_i32, %204, %c8_i32, %c31_i32 : f32 -> f32
      %206 = arith.addf %204, %205 : f32
      %c4_i32 = arith.constant 4 : i32
      %207 = nvvm.shfl.sync  bfly %c-1_i32, %206, %c4_i32, %c31_i32 : f32 -> f32
      %208 = arith.addf %206, %207 : f32
      %c2_i32_630 = arith.constant 2 : i32
      %209 = nvvm.shfl.sync  bfly %c-1_i32, %208, %c2_i32_630, %c31_i32 : f32 -> f32
      %210 = arith.addf %208, %209 : f32
      %c1_i32_631 = arith.constant 1 : i32
      %211 = nvvm.shfl.sync  bfly %c-1_i32, %210, %c1_i32_631, %c31_i32 : f32 -> f32
      %212 = arith.addf %210, %211 : f32
      %213 = nvvm.read.ptx.sreg.laneid : i32
      %214 = nvvm.read.ptx.sreg.tid.x : i32
      %215 = nvvm.read.ptx.sreg.tid.y : i32
      %216 = nvvm.read.ptx.sreg.tid.z : i32
      %217 = nvvm.read.ptx.sreg.ntid.x : i32
      %218 = nvvm.read.ptx.sreg.ntid.y : i32
      %219 = arith.muli %215, %217 : i32
      %220 = arith.addi %214, %219 : i32
      %221 = arith.muli %216, %217 : i32
      %222 = arith.muli %221, %218 : i32
      %223 = arith.addi %220, %222 : i32
      %c32_i32 = arith.constant 32 : i32
      %224 = arith.floordivsi %223, %c32_i32 : i32
      %lay_632 = cute.get_layout(%view_47) : !memref_smem_f32_
      %225 = cute.get_shape(%lay_632) : (!cute.layout<"(2,2):(1,2)">) -> !cute.shape<"(2,2)">
      %e0_633, %e1_634 = cute.get_leaves(%225) : !cute.shape<"(2,2)">
      %int_tuple_635 = cute.make_int_tuple() : () -> !cute.int_tuple<"2">
      %sz_636 = cute.size(%int_tuple_635) : (!cute.int_tuple<"2">) -> !cute.int_tuple<"2">
      %e0_637 = cute.get_leaves(%sz_636) : !cute.int_tuple<"2">
      %c2_i32_638 = arith.constant 2 : i32
      %226 = arith.floordivsi %224, %c2_i32_638 : i32
      %227 = arith.remsi %224, %c2_i32_638 : i32
      %c0_i32_639 = arith.constant 0 : i32
      %228 = arith.cmpi eq, %213, %c0_i32_639 : i32
      %229 = scf.if %228 -> (!memref_smem_f32_) {
        %iter_718 = cute.get_iter(%view_47) : !memref_smem_f32_
        %coord_719 = cute.make_coord(%226, %227) : (i32, i32) -> !cute.coord<"(?,?)">
        cute.memref.store(%view_47, %coord_719, %212) : (!memref_smem_f32_, !cute.coord<"(?,?)">, f32) -> ()
        scf.yield %view_47 : !memref_smem_f32_
      } else {
        %iter_718 = cute.get_iter(%view_47) : !memref_smem_f32_
        scf.yield %view_47 : !memref_smem_f32_
      }
      %iter_640 = cute.get_iter(%229) : !memref_smem_f32_
      %iter_641 = cute.get_iter(%229) : !memref_smem_f32_
      %iter_642 = cute.get_iter(%229) : !memref_smem_f32_
      nvvm.barrier
      %230 = arith.cmpi slt, %213, %c2_i32_638 : i32
      %cst_643 = arith.constant 0.000000e+00 : f32
      %231 = scf.if %230 -> (f32) {
        %coord_718 = cute.make_coord(%226, %213) : (i32, i32) -> !cute.coord<"(?,?)">
        %262 = cute.memref.load(%229, %coord_718) : (!memref_smem_f32_, !cute.coord<"(?,?)">) -> f32
        scf.yield %262 : f32
      } else {
        scf.yield %cst_643 : f32
      }
      %c-1_i32_644 = arith.constant -1 : i32
      %c16_i32_645 = arith.constant 16 : i32
      %c31_i32_646 = arith.constant 31 : i32
      %232 = nvvm.shfl.sync  bfly %c-1_i32_644, %231, %c16_i32_645, %c31_i32_646 : f32 -> f32
      %233 = arith.addf %231, %232 : f32
      %c8_i32_647 = arith.constant 8 : i32
      %234 = nvvm.shfl.sync  bfly %c-1_i32_644, %233, %c8_i32_647, %c31_i32_646 : f32 -> f32
      %235 = arith.addf %233, %234 : f32
      %c4_i32_648 = arith.constant 4 : i32
      %236 = nvvm.shfl.sync  bfly %c-1_i32_644, %235, %c4_i32_648, %c31_i32_646 : f32 -> f32
      %237 = arith.addf %235, %236 : f32
      %c2_i32_649 = arith.constant 2 : i32
      %238 = nvvm.shfl.sync  bfly %c-1_i32_644, %237, %c2_i32_649, %c31_i32_646 : f32 -> f32
      %239 = arith.addf %237, %238 : f32
      %c1_i32_650 = arith.constant 1 : i32
      %240 = nvvm.shfl.sync  bfly %c-1_i32_644, %239, %c1_i32_650, %c31_i32_646 : f32 -> f32
      %241 = arith.addf %239, %240 : f32
      %cst_651 = arith.constant 4.096000e+03 : f32
      %242 = arith.divf %241, %cst_651 : f32
      %243 = arith.addf %242, %arg3 : f32
      %244 = math.rsqrt %243 fastmath<fast> : f32
      nvvm.barrier
      %lay_652 = cute.get_layout(%dst_partitioned) : !memref_smem_bf16_1
      %lay_653 = cute.get_layout(%rmem) : !memref_rmem_bf16_
      %rinv_654 = cute.right_inverse(%lay_653) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.layout<"64:1">
      %lay_655 = cute.make_layout() : !cute.layout<"(8,8):(1,512)">
      %coalesce_656 = cute.coalesce(%lay_655) : (!cute.layout<"(8,8):(1,512)">) -> !cute.layout<"(8,8):(1,512)">
      %245 = cute.get_shape(%coalesce_656) : (!cute.layout<"(8,8):(1,512)">) -> !cute.shape<"(8,8)">
      %e0_657, %e1_658 = cute.get_leaves(%245) : !cute.shape<"(8,8)">
      %246 = cute.get_stride(%coalesce_656) : (!cute.layout<"(8,8):(1,512)">) -> !cute.stride<"(1,512)">
      %e0_659, %e1_660 = cute.get_leaves(%246) : !cute.stride<"(1,512)">
      %247 = cute.get_shape(%coalesce_656) : (!cute.layout<"(8,8):(1,512)">) -> !cute.shape<"(8,8)">
      %e0_661, %e1_662 = cute.get_leaves(%247) : !cute.shape<"(8,8)">
      %248 = cute.get_shape(%coalesce_656) : (!cute.layout<"(8,8):(1,512)">) -> !cute.shape<"(8,8)">
      %e0_663, %e1_664 = cute.get_leaves(%248) : !cute.shape<"(8,8)">
      %249 = cute.get(%coalesce_656) <{mode = [0]}> : !cute.layout<"(8,8):(1,512)"> -> !cute.layout<"8:1">
      %lay_665 = cute.make_layout() : !cute.layout<"8:1">
      %sz_666 = cute.size(%lay_665) : (!cute.layout<"8:1">) -> !cute.int_tuple<"8">
      %e0_667 = cute.get_leaves(%sz_666) : !cute.int_tuple<"8">
      %lay_668 = cute.get_layout(%dst_partitioned) : !memref_smem_bf16_1
      %lay_669 = cute.get_layout(%rmem) : !memref_rmem_bf16_
      %iter_670 = cute.get_iter(%dst_partitioned) : !memref_smem_bf16_1
      %view_671 = cute.make_view(%iter_670) : !memref_smem_bf16_4
      %iter_672 = cute.get_iter(%view_671) : !memref_smem_bf16_4
      %iter_673 = cute.get_iter(%view_671) : !memref_smem_bf16_4
      %iter_674 = cute.get_iter(%rmem) : !memref_rmem_bf16_
      %view_675 = cute.make_view(%iter_674) : !memref_rmem_bf16_3
      %iter_676 = cute.get_iter(%view_675) : !memref_rmem_bf16_3
      %iter_677 = cute.get_iter(%view_675) : !memref_rmem_bf16_3
      %shape_678 = cute.make_shape() : () -> !cute.shape<"8">
      %lay_679 = cute.make_layout() : !cute.layout<"8:1">
      %iter_680 = cute.get_iter(%view_671) : !memref_smem_bf16_4
      %view_681 = cute.make_view(%iter_680) : !memref_smem_bf16_4
      %iter_682 = cute.get_iter(%view_681) : !memref_smem_bf16_4
      %iter_683 = cute.get_iter(%view_681) : !memref_smem_bf16_4
      %shape_684 = cute.make_shape() : () -> !cute.shape<"8">
      %lay_685 = cute.make_layout() : !cute.layout<"8:1">
      %iter_686 = cute.get_iter(%view_675) : !memref_rmem_bf16_3
      %view_687 = cute.make_view(%iter_686) : !memref_rmem_bf16_3
      %iter_688 = cute.get_iter(%view_687) : !memref_rmem_bf16_3
      %iter_689 = cute.get_iter(%view_687) : !memref_rmem_bf16_3
      %atom_690 = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<bf16, 128 b>
      %250 = cute.static : !cute.layout<"1:0">
      %iter_691 = cute.get_iter(%view_681) : !memref_smem_bf16_4
      %iter_692 = cute.get_iter(%view_687) : !memref_rmem_bf16_3
      %lay_693 = cute.get_layout(%view_681) : !memref_smem_bf16_4
      %lay_694 = cute.get_layout(%view_687) : !memref_rmem_bf16_3
      %append_695 = cute.append_to_rank<2> (%lay_693, %250) : !cute.layout<"(8,8):(1,512)">, !cute.layout<"1:0">
      %append_696 = cute.append_to_rank<2> (%lay_694, %250) : !cute.layout<"(8,8):(1,8)">, !cute.layout<"1:0">
      %lay_697 = cute.make_layout() : !cute.layout<"(8,(8)):(1,(512))">
      %lay_698 = cute.make_layout() : !cute.layout<"(8,(8)):(1,(8))">
      %sz_699 = cute.size(%lay_697) <{mode = [1]}> : (!cute.layout<"(8,(8)):(1,(512))">) -> !cute.int_tuple<"8">
      %251 = cute.get_scalars(%sz_699) : !cute.int_tuple<"8">
      %c0_i32_700 = arith.constant 0 : i32
      %c1_i32_701 = arith.constant 1 : i32
      scf.for %arg4 = %c0_i32_700 to %251 step %c1_i32_701  : i32 {
        %coord_718 = cute.make_coord(%arg4) : (i32) -> !cute.coord<"(_,?)">
        %slice = cute.slice(%lay_697, %coord_718) : !cute.layout<"(8,(8)):(1,(512))">, !cute.coord<"(_,?)">
        %idx_719 = cute.crd2idx(%coord_718, %lay_697) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(8)):(1,(512))">) -> !cute.int_tuple<"?{div=512}">
        %ptr_720 = cute.add_offset(%iter_691, %idx_719) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=512}">) -> !cute.ptr<bf16, smem, align<16>>
        %view_721 = cute.make_view(%ptr_720, %slice) : !memref_smem_bf16_5
        %slice_722 = cute.slice(%lay_698, %coord_718) : !cute.layout<"(8,(8)):(1,(8))">, !cute.coord<"(_,?)">
        %idx_723 = cute.crd2idx(%coord_718, %lay_698) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(8)):(1,(8))">) -> !cute.int_tuple<"?{div=8}">
        %ptr_724 = cute.add_offset(%iter_692, %idx_723) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
        %view_725 = cute.make_view(%ptr_724, %slice_722) : !memref_rmem_bf16_4
        cute.copy_atom_call(%atom_690, %view_721, %view_725) : (!cute_nvgpu.atom.universal_copy<bf16, 128 b>, !memref_smem_bf16_5, !memref_rmem_bf16_4) -> ()
      } {llvm.loop_annotation = #loop_annotation}
      %252 = cute.memref.load_vec %rmem : !memref_rmem_bf16_
      %253 = arith.extf %252 : vector<64xbf16> to vector<64xf32>
      %254 = vector.broadcast %244 : f32 to vector<64xf32>
      %255 = arith.mulf %253, %254 : vector<64xf32>
      %lay_702 = cute.get_layout(%retiled) : !memref_rmem_bf16_
      %256 = cute.get_shape(%lay_702) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %e0_703, %e1_704, %e2_705, %e3_706 = cute.get_leaves(%256) : !cute.shape<"((8,8),1,1)">
      %257 = cute.memref.load_vec %retiled : !memref_rmem_bf16_
      %258 = arith.extf %257 : vector<64xbf16> to vector<64xf32>
      %259 = arith.mulf %255, %258 : vector<64xf32>
      %260 = arith.truncf %259 : vector<64xf32> to vector<64xbf16>
      %lay_707 = cute.get_layout(%rmem_128) : !memref_rmem_bf16_
      %261 = cute.get_shape(%lay_707) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %e0_708, %e1_709, %e2_710, %e3_711 = cute.get_leaves(%261) : !cute.shape<"((8,8),1,1)">
      %int_tuple_712 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,8),1,1)">
      %sz_713 = cute.size(%int_tuple_712) : (!cute.int_tuple<"((8,8),1,1)">) -> !cute.int_tuple<"64">
      %e0_714 = cute.get_leaves(%sz_713) : !cute.int_tuple<"64">
      %int_tuple_715 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,8),1,1)">
      %sz_716 = cute.size(%int_tuple_715) : (!cute.int_tuple<"((8,8),1,1)">) -> !cute.int_tuple<"64">
      %e0_717 = cute.get_leaves(%sz_716) : !cute.int_tuple<"64">
      cute.memref.store_vec %260, %rmem_128 : !memref_rmem_bf16_
      scf.if %113 {
        %lay_718 = cute.get_layout(%rmem_128) : !memref_rmem_bf16_
        %262 = cute.get_shape(%lay_718) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %e0_719, %e1_720, %e2_721, %e3_722 = cute.get_leaves(%262) : !cute.shape<"((8,8),1,1)">
        %lay_723 = cute.get_layout(%dst_partitioned_117) : !memref_gmem_bf16_5
        %263 = cute.get_shape(%lay_723) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %e0_724, %e1_725, %e2_726, %e3_727 = cute.get_leaves(%263) : !cute.shape<"((8,8),1,1)">
        %lay_728 = cute.get_layout(%rmem_128) : !memref_rmem_bf16_
        %shape_729 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_730 = cute.make_layout() : !cute.layout<"1:0">
        %append_731 = cute.append_to_rank<2> (%lay_728, %lay_730) : !cute.layout<"((8,8),1,1):((1,8),0,0)">, !cute.layout<"1:0">
        %view_732 = cute.make_view(%iter_130, %append_731) : !memref_rmem_bf16_
        %iter_733 = cute.get_iter(%view_732) : !memref_rmem_bf16_
        %lay_734 = cute.get_layout(%view_732) : !memref_rmem_bf16_
        %264 = cute.get_shape(%lay_734) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %e0_735, %e1_736, %e2_737, %e3_738 = cute.get_leaves(%264) : !cute.shape<"((8,8),1,1)">
        %iter_739 = cute.get_iter(%view_732) : !memref_rmem_bf16_
        %view_740 = cute.make_view(%iter_739) : !memref_rmem_bf16_1
        %iter_741 = cute.get_iter(%view_740) : !memref_rmem_bf16_1
        %iter_742 = cute.get_iter(%view_740) : !memref_rmem_bf16_1
        %lay_743 = cute.get_layout(%dst_partitioned_117) : !memref_gmem_bf16_5
        %shape_744 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_745 = cute.make_layout() : !cute.layout<"1:0">
        %append_746 = cute.append_to_rank<2> (%lay_743, %lay_745) : !cute.layout<"((8,8),1,1):((1,512),0,0)">, !cute.layout<"1:0">
        %view_747 = cute.make_view(%iter_118, %append_746) : !memref_gmem_bf16_5
        %iter_748 = cute.get_iter(%view_747) : !memref_gmem_bf16_5
        %lay_749 = cute.get_layout(%view_747) : !memref_gmem_bf16_5
        %265 = cute.get_shape(%lay_749) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %e0_750, %e1_751, %e2_752, %e3_753 = cute.get_leaves(%265) : !cute.shape<"((8,8),1,1)">
        %iter_754 = cute.get_iter(%view_747) : !memref_gmem_bf16_5
        %view_755 = cute.make_view(%iter_754) : !memref_gmem_bf16_6
        %iter_756 = cute.get_iter(%view_755) : !memref_gmem_bf16_6
        %iter_757 = cute.get_iter(%view_755) : !memref_gmem_bf16_6
        %lay_758 = cute.get_layout(%rmem_153) : !memref_rmem_i8_
        %shape_759 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_760 = cute.make_layout() : !cute.layout<"1:0">
        %append_761 = cute.append_to_rank<2> (%lay_758, %lay_760) : !cute.layout<"(8,1,1):(1,0,1)">, !cute.layout<"1:0">
        %view_762 = cute.make_view(%iter_155, %append_761) : !memref_rmem_i8_
        %iter_763 = cute.get_iter(%view_762) : !memref_rmem_i8_
        %lay_764 = cute.get_layout(%view_762) : !memref_rmem_i8_
        %266 = cute.get_shape(%lay_764) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
        %e0_765, %e1_766, %e2_767 = cute.get_leaves(%266) : !cute.shape<"(8,1,1)">
        %iter_768 = cute.get_iter(%view_762) : !memref_rmem_i8_
        %view_769 = cute.make_view(%iter_768) : !memref_rmem_i8_1
        %iter_770 = cute.get_iter(%view_769) : !memref_rmem_i8_1
        %iter_771 = cute.get_iter(%view_769) : !memref_rmem_i8_1
        %lay_772 = cute.get_layout(%view_740) : !memref_rmem_bf16_1
        %267 = cute.get_shape(%lay_772) : (!cute.layout<"((8,8),(1,1)):((1,8),(0,0))">) -> !cute.shape<"((8,8),(1,1))">
        %e0_773, %e1_774, %e2_775, %e3_776 = cute.get_leaves(%267) : !cute.shape<"((8,8),(1,1))">
        %lay_777 = cute.get_layout(%view_755) : !memref_gmem_bf16_6
        %268 = cute.get_shape(%lay_777) : (!cute.layout<"((8,8),(1,1)):((1,512),(0,0))">) -> !cute.shape<"((8,8),(1,1))">
        %e0_778, %e1_779, %e2_780, %e3_781 = cute.get_leaves(%268) : !cute.shape<"((8,8),(1,1))">
        %lay_782 = cute.get_layout(%view_740) : !memref_rmem_bf16_1
        %sz_783 = cute.size(%lay_782) <{mode = [1]}> : (!cute.layout<"((8,8),(1,1)):((1,8),(0,0))">) -> !cute.int_tuple<"1">
        %e0_784 = cute.get_leaves(%sz_783) : !cute.int_tuple<"1">
        %lay_785 = cute.get_layout(%view_755) : !memref_gmem_bf16_6
        %sz_786 = cute.size(%lay_785) <{mode = [1]}> : (!cute.layout<"((8,8),(1,1)):((1,512),(0,0))">) -> !cute.int_tuple<"1">
        %e0_787 = cute.get_leaves(%sz_786) : !cute.int_tuple<"1">
        %269 = cute.static : !cute.layout<"1:0">
        %iter_788 = cute.get_iter(%view_740) : !memref_rmem_bf16_1
        %iter_789 = cute.get_iter(%view_755) : !memref_gmem_bf16_6
        %lay_790 = cute.get_layout(%view_740) : !memref_rmem_bf16_1
        %lay_791 = cute.get_layout(%view_755) : !memref_gmem_bf16_6
        %append_792 = cute.append_to_rank<2> (%lay_790, %269) : !cute.layout<"((8,8),(1,1)):((1,8),(0,0))">, !cute.layout<"1:0">
        %append_793 = cute.append_to_rank<2> (%lay_791, %269) : !cute.layout<"((8,8),(1,1)):((1,512),(0,0))">, !cute.layout<"1:0">
        %lay_794 = cute.make_layout() : !cute.layout<"((8,8),((1,1))):((1,8),((0,0)))">
        %lay_795 = cute.make_layout() : !cute.layout<"((8,8),((1,1))):((1,512),((0,0)))">
        %iter_796 = cute.get_iter(%view_769) : !memref_rmem_i8_1
        %lay_797 = cute.get_layout(%view_769) : !memref_rmem_i8_1
        %append_798 = cute.append_to_rank<2> (%lay_797, %269) : !cute.layout<"(8,(1,1)):(1,(0,1))">, !cute.layout<"1:0">
        %lay_799 = cute.make_layout() : !cute.layout<"(8,((1,1))):(1,((0,1)))">
        %sz_800 = cute.size(%lay_794) <{mode = [1]}> : (!cute.layout<"((8,8),((1,1))):((1,8),((0,0)))">) -> !cute.int_tuple<"1">
        %270 = cute.get_scalars(%sz_800) : !cute.int_tuple<"1">
        %c0_i32_801 = arith.constant 0 : i32
        %c1_i32_802 = arith.constant 1 : i32
        scf.for %arg4 = %c0_i32_801 to %270 step %c1_i32_802  : i32 {
          %coord_803 = cute.make_coord(%arg4) : (i32) -> !cute.coord<"(_,?)">
          %slice = cute.slice(%lay_794, %coord_803) : !cute.layout<"((8,8),((1,1))):((1,8),((0,0)))">, !cute.coord<"(_,?)">
          %idx_804 = cute.crd2idx(%coord_803, %lay_794) : (!cute.coord<"(_,?)">, !cute.layout<"((8,8),((1,1))):((1,8),((0,0)))">) -> !cute.int_tuple<"0">
          %ptr_805 = cute.add_offset(%iter_788, %idx_804) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, rmem, align<32>>
          %view_806 = cute.make_view(%ptr_805, %slice) : !memref_rmem_bf16_2
          %slice_807 = cute.slice(%lay_795, %coord_803) : !cute.layout<"((8,8),((1,1))):((1,512),((0,0)))">, !cute.coord<"(_,?)">
          %idx_808 = cute.crd2idx(%coord_803, %lay_795) : (!cute.coord<"(_,?)">, !cute.layout<"((8,8),((1,1))):((1,512),((0,0)))">) -> !cute.int_tuple<"0">
          %ptr_809 = cute.add_offset(%iter_789, %idx_808) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, gmem, align<16>>
          %view_810 = cute.make_view(%ptr_809, %slice_807) : !memref_gmem_bf16_7
          %slice_811 = cute.slice(%lay_799, %coord_803) : !cute.layout<"(8,((1,1))):(1,((0,1)))">, !cute.coord<"(_,?)">
          %idx_812 = cute.crd2idx(%coord_803, %lay_799) : (!cute.coord<"(_,?)">, !cute.layout<"(8,((1,1))):(1,((0,1)))">) -> !cute.int_tuple<"?">
          %ptr_813 = cute.add_offset(%iter_796, %idx_812) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %view_814 = cute.make_view(%ptr_813, %slice_811) : !memref_rmem_i8_2
          cute.copy_atom_call(%atom_108, %view_806, %view_810, %view_814) : (!cute_nvgpu.atom.universal_copy<bf16, 128 b>, !memref_rmem_bf16_2, !memref_gmem_bf16_7, !memref_rmem_i8_2) -> ()
        } {llvm.loop_annotation = #loop_annotation}
      }
      return
    }
  }
  func.func @cutlass___call_____main__RMSNormKernel_object_at__Ptrgmem_Ptrgmem_Ptrgmem___CUstream0x0(%arg0: !cute.ptr<bf16, gmem, align<16>>, %arg1: !cute.ptr<bf16, gmem, align<16>>, %arg2: !cute.ptr<bf16, gmem, align<16>>, %arg3: i32, %arg4: f32, %arg5: !cuda.stream) -> i32 attributes {llvm.emit_c_interface} {
    %shape = cute.make_shape(%arg3) : (i32) -> !cute.shape<"(?,4096)">
    %stride = cute.make_stride() : () -> !cute.stride<"(4096,1)">
    %lay = cute.make_layout(%shape, %stride) : !cute.layout<"(?,4096):(4096,1)">
    %view = cute.make_view(%arg0, %lay) : !memref_gmem_bf16_
    %iter = cute.get_iter(%view) : !memref_gmem_bf16_
    %shape_0 = cute.make_shape(%arg3) : (i32) -> !cute.shape<"(?,4096)">
    %stride_1 = cute.make_stride() : () -> !cute.stride<"(4096,1)">
    %lay_2 = cute.make_layout(%shape_0, %stride_1) : !cute.layout<"(?,4096):(4096,1)">
    %view_3 = cute.make_view(%arg2, %lay_2) : !memref_gmem_bf16_
    %iter_4 = cute.get_iter(%view_3) : !memref_gmem_bf16_
    %shape_5 = cute.make_shape() : () -> !cute.shape<"(4096)">
    %stride_6 = cute.make_stride() : () -> !cute.stride<"(1)">
    %lay_7 = cute.make_layout() : !cute.layout<"(4096):(1)">
    %view_8 = cute.make_view(%arg1, %lay_7) : !memref_gmem_bf16_1
    %iter_9 = cute.get_iter(%view_8) : !memref_gmem_bf16_1
    %shape_10 = cute.make_shape() : () -> !cute.shape<"((64,2),(8,8))">
    %stride_11 = cute.make_stride() : () -> !cute.stride<"((16,1),(2,1024))">
    %lay_12 = cute.make_layout() : !cute.layout<"((64,2),(8,8)):((16,1),(2,1024))">
    %int_tuple = cute.make_int_tuple(%arg3) : (i32) -> !cute.int_tuple<"?">
    %tile = cute.make_tile() : () -> !cute.tile<"2:1">
    %0 = cute.get_scalars(%int_tuple) <{only_dynamic}> : !cute.int_tuple<"?">
    %c2_i32 = arith.constant 2 : i32
    %1 = arith.ceildivsi %0, %c2_i32 : i32
    %int_tuple_13 = cute.make_int_tuple(%1) : (i32) -> !cute.int_tuple<"?">
    %e0 = cute.get_leaves(%int_tuple_13) : !cute.int_tuple<"?">
    %2 = cute.get_scalars(%e0) : !cute.int_tuple<"?">
    %lay_14 = cute.get_layout(%view) : !memref_gmem_bf16_
    %3 = cute.get_shape(%lay_14) : (!cute.layout<"(?,4096):(4096,1)">) -> !cute.shape<"(?,4096)">
    %e0_15, %e1 = cute.get_leaves(%3) : !cute.shape<"(?,4096)">
    %itup = cute.to_int_tuple(%e0_15) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %4 = cute.get_scalars(%itup) : !cute.int_tuple<"?">
    %5 = cute.get_stride(%lay_14) : (!cute.layout<"(?,4096):(4096,1)">) -> !cute.stride<"(4096,1)">
    %e0_16, %e1_17 = cute.get_leaves(%5) : !cute.stride<"(4096,1)">
    %lay_18 = cute.get_layout(%view_8) : !memref_gmem_bf16_1
    %6 = cute.get_shape(%lay_18) : (!cute.layout<"(4096):(1)">) -> !cute.shape<"(4096)">
    %e0_19 = cute.get_leaves(%6) : !cute.shape<"(4096)">
    %7 = cute.get_stride(%lay_18) : (!cute.layout<"(4096):(1)">) -> !cute.stride<"(1)">
    %e0_20 = cute.get_leaves(%7) : !cute.stride<"(1)">
    %lay_21 = cute.get_layout(%view_3) : !memref_gmem_bf16_
    %8 = cute.get_shape(%lay_21) : (!cute.layout<"(?,4096):(4096,1)">) -> !cute.shape<"(?,4096)">
    %e0_22, %e1_23 = cute.get_leaves(%8) : !cute.shape<"(?,4096)">
    %itup_24 = cute.to_int_tuple(%e0_22) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %9 = cute.get_scalars(%itup_24) : !cute.int_tuple<"?">
    %10 = cute.get_stride(%lay_21) : (!cute.layout<"(?,4096):(4096,1)">) -> !cute.stride<"(4096,1)">
    %e0_25, %e1_26 = cute.get_leaves(%10) : !cute.stride<"(4096,1)">
    %11 = cute.get_shape(%lay_12) : (!cute.layout<"((64,2),(8,8)):((16,1),(2,1024))">) -> !cute.shape<"((64,2),(8,8))">
    %e0_27, %e1_28, %e2, %e3 = cute.get_leaves(%11) : !cute.shape<"((64,2),(8,8))">
    %12 = cute.get_stride(%lay_12) : (!cute.layout<"((64,2),(8,8)):((16,1),(2,1024))">) -> !cute.stride<"((16,1),(2,1024))">
    %e0_29, %e1_30, %e2_31, %e3_32 = cute.get_leaves(%12) : !cute.stride<"((16,1),(2,1024))">
    %c16400_i32 = arith.constant 16400 : i32
    %13 = arith.extsi %c16400_i32 : i32 to i64
    %c128_i32 = arith.constant 128 : i32
    %c1_i32 = arith.constant 1 : i32
    %14 = cuda.launch_cfg.create<max_attrs = 2 : i32> (blockDim = (%c128_i32, %c1_i32, %c1_i32), dynamicSmemBytes = %13, gridDim = (%2, %c1_i32, %c1_i32), stream = %arg5) : i32, i32, i32, i64, i32, i32, i32, !cuda.stream -> !cuda.launch_cfg<max_attrs = 2>
    %15 = cuda.launch_ex @kernels::@kernel_cutlass_kernel___main__RMSNormKernel_object_at__tensorptrbf16gmemalign16o409640961_tensorptrbf16_gmem_align16_o_40961_tensorptrbf16gmemalign16o409640961__2_4096_0<%14> (%view, %view_8, %view_3, %arg4) : !cuda.launch_cfg<max_attrs = 2>, (!memref_gmem_bf16_, !memref_gmem_bf16_1, !memref_gmem_bf16_, f32) -> !cuda.result
    %16 = cuda.cast %15 : !cuda.result -> i32
    cuda.return_if_error %16 : i32
    %c0_i32 = arith.constant 0 : i32
    return %c0_i32 : i32
  }
}
