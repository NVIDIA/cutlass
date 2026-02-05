!copy_ldgsts = !cute.tiled_copy<!cute_nvgpu.atom.simt_async_copy<bf16, cache = always, 128 b>, layout_copy_tv = <"((64,2),(8,8)):((16,1),(2,1024))">, tiler_mn = <"[2:1;4096:1]">>
!copy_simt = !cute.tiled_copy<!cute_nvgpu.atom.universal_copy<bf16, 128 b>, layout_copy_tv = <"((64,2),(8,8)):((16,1),(2,1024))">, tiler_mn = <"[2:1;4096:1]">>
!memref_gmem_bf16_ = !cute.memref<bf16, gmem, align<16>, "(?,4096):(4096,1)">
!memref_gmem_bf16_1 = !cute.memref<bf16, gmem, align<16>, "(4096):(1)">
!memref_gmem_bf16_2 = !cute.memref<bf16, gmem, align<16>, "(2,4096):(4096,1)">
!memref_gmem_bf16_3 = !cute.memref<bf16, gmem, align<16>, "((2),4096):((0),1)">
!memref_gmem_bf16_4 = !cute.memref<bf16, gmem, align<16>, "(2,4096):(0,1)">
!memref_gmem_bf16_5 = !cute.memref<bf16, gmem, align<16>, "((8,8),1,1):((1,512),0,0)">
!memref_gmem_bf16_6 = !cute.memref<bf16, gmem, align<16>, "((8,8),(1,1)):((1,512),(0,0))">
!memref_rmem_bf16_ = !cute.memref<bf16, rmem, align<32>, "((8,8),1,1):((1,8),0,0)">
!memref_rmem_bf16_1 = !cute.memref<bf16, rmem, align<32>, "((8,8),(1,1)):((1,8),(0,0))">
!memref_rmem_bf16_2 = !cute.memref<bf16, rmem, align<32>, "(8,8):(1,8)">
!memref_rmem_i8_ = !cute.memref<i8, rmem, align<32>, "(8,1,1):(1,0,1)">
!memref_rmem_i8_1 = !cute.memref<i8, rmem, align<32>, "(8,(1,1)):(1,(0,1))">
!memref_smem_bf16_ = !cute.memref<bf16, smem, align<1024>, "(2,4096):(4096,1)">
!memref_smem_bf16_1 = !cute.memref<bf16, smem, align<16>, "((8,8),1,1):((1,512),0,0)">
!memref_smem_bf16_2 = !cute.memref<bf16, smem, align<16>, "((8,8),(1,1)):((1,512),(0,0))">
!memref_smem_bf16_3 = !cute.memref<bf16, smem, align<16>, "(8,8):(1,512)">
!memref_smem_f32_ = !cute.memref<f32, smem, align<1024>, "(2,2):(1,2)">
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
      %lay_30 = cute.make_ordered_layout(%shape, %int_tuple) : (!cute.shape<"(2,4096)">, !cute.int_tuple<"(1,0)">) -> !cute.layout<"(2,4096):(4096,1)">
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
      %lay_37 = cute.make_layout(%shape_36) : !cute.layout<"(2,2):(1,2)">
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
      %tiled_view = cute.local_tile(%arg0, %tile, %coord_53) : (!memref_gmem_bf16_, !cute.tile<"[2:1;4096:1]">, !cute.coord<"(?,0)">) -> !memref_gmem_bf16_2
      %iter_54 = cute.get_iter(%tiled_view) : !memref_gmem_bf16_2
      %tile_55 = cute.make_tile() : () -> !cute.tile<"[2:1;4096:1]">
      %coord_56 = cute.make_coord(%14) : (i32) -> !cute.coord<"(?,0)">
      %tiled_view_57 = cute.local_tile(%arg2, %tile_55, %coord_56) : (!memref_gmem_bf16_, !cute.tile<"[2:1;4096:1]">, !cute.coord<"(?,0)">) -> !memref_gmem_bf16_2
      %iter_58 = cute.get_iter(%tiled_view_57) : !memref_gmem_bf16_2
      %tile_59 = cute.make_tile() : () -> !cute.tile<"[2:1;4096:1]">
      %coord_60 = cute.make_coord(%14) : (i32) -> !cute.coord<"(?,0)">
      %tiled_view_61 = cute.local_tile(%22, %tile_59, %coord_60) : (!cute.coord_tensor<"(0,0)", "(?,4096):(1@0,1@1)">, !cute.tile<"[2:1;4096:1]">, !cute.coord<"(?,0)">) -> !cute.coord_tensor<"(?{div=2},0)", "(2,4096):(1@0,1@1)">
      %iter_62 = cute.get_iter(%tiled_view_61) : !cute.coord_tensor<"(?{div=2},0)", "(2,4096):(1@0,1@1)">
      %e0_63, %e1_64 = cute.get_leaves(%iter_62) : !cute.int_tuple<"(?{div=2},0)">
      %23 = cute.get_scalars(%e0_63) : !cute.int_tuple<"?{div=2}">
      %lay_65 = cute.get_layout(%arg1) : !memref_gmem_bf16_1
      %shape_66 = cute.make_shape() : () -> !cute.shape<"(2)">
      %stride = cute.make_stride() : () -> !cute.stride<"(0)">
      %lay_67 = cute.make_layout(%shape_66, %stride) : !cute.layout<"(2):(0)">
      %24 = cute.get_shape(%lay_65) : (!cute.layout<"(4096):(1)">) -> !cute.shape<"(4096)">
      %e0_68 = cute.get_leaves(%24) : !cute.shape<"(4096)">
      %prepend = cute.prepend_to_rank<2> (%lay_65, %lay_67) : !cute.layout<"(4096):(1)">, !cute.layout<"(2):(0)">
      %view_69 = cute.make_view(%iter_3, %prepend) : !memref_gmem_bf16_3
      %iter_70 = cute.get_iter(%view_69) : !memref_gmem_bf16_3
      %tile_71 = cute.make_tile() : () -> !cute.tile<"[2:1;4096:1]">
      %coord_72 = cute.make_coord() : () -> !cute.coord<"(0,0)">
      %tiled_view_73 = cute.local_tile(%view_69, %tile_71, %coord_72) : (!memref_gmem_bf16_3, !cute.tile<"[2:1;4096:1]">, !cute.coord<"(0,0)">) -> !memref_gmem_bf16_4
      %iter_74 = cute.get_iter(%tiled_view_73) : !memref_gmem_bf16_4
      %atom = cute.make_atom() : () -> !cute_nvgpu.atom.simt_async_copy<bf16, cache = always, 128 b>
      %atom_75 = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<bf16, 128 b>
      %atom_76 = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<bf16, 128 b>
      %tile_77 = cute.make_tile() : () -> !cute.tile<"[2:1;4096:1]">
      %25 = cute.make_tiled_copy(%atom) : !copy_ldgsts
      %tile_78 = cute.make_tile() : () -> !cute.tile<"[2:1;4096:1]">
      %26 = cute.make_tiled_copy(%atom_75) : !copy_simt
      %tile_79 = cute.make_tile() : () -> !cute.tile<"[2:1;4096:1]">
      %27 = cute.make_tiled_copy(%atom_76) : !copy_simt
      %coord_80 = cute.make_coord(%11) : (i32) -> !cute.coord<"?">
      %src_partitioned = cute.tiled.copy.partition_S(%25, %tiled_view, %coord_80) : (!copy_ldgsts, !memref_gmem_bf16_2, !cute.coord<"?">) -> !memref_gmem_bf16_5
      %iter_81 = cute.get_iter(%src_partitioned) : !memref_gmem_bf16_5
      %coord_82 = cute.make_coord(%11) : (i32) -> !cute.coord<"?">
      %dst_partitioned = cute.tiled.copy.partition_D(%25, %view, %coord_82) : (!copy_ldgsts, !memref_smem_bf16_, !cute.coord<"?">) -> !memref_smem_bf16_1
      %iter_83 = cute.get_iter(%dst_partitioned) : !memref_smem_bf16_1
      %coord_84 = cute.make_coord(%11) : (i32) -> !cute.coord<"?">
      %dst_partitioned_85 = cute.tiled.copy.partition_D(%27, %tiled_view_57, %coord_84) : (!copy_simt, !memref_gmem_bf16_2, !cute.coord<"?">) -> !memref_gmem_bf16_5
      %iter_86 = cute.get_iter(%dst_partitioned_85) : !memref_gmem_bf16_5
      %coord_87 = cute.make_coord(%11) : (i32) -> !cute.coord<"?">
      %src_partitioned_88 = cute.tiled.copy.partition_S(%25, %tiled_view_61, %coord_87) : (!copy_ldgsts, !cute.coord_tensor<"(?{div=2},0)", "(2,4096):(1@0,1@1)">, !cute.coord<"?">) -> !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %iter_89 = cute.get_iter(%src_partitioned_88) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %e0_90, %e1_91 = cute.get_leaves(%iter_89) : !cute.int_tuple<"(?,?{div=8})">
      %28 = cute.get_scalars(%e0_90) : !cute.int_tuple<"?">
      %29 = cute.get_scalars(%e1_91) : !cute.int_tuple<"?{div=8}">
      %lay_92 = cute.get_layout(%src_partitioned) : !memref_gmem_bf16_5
      %30 = cute.make_layout_like(%lay_92) : !cute.layout<"((8,8),1,1):((1,512),0,0)"> to !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %rmem = cute.memref.alloca(%30) : !memref_rmem_bf16_
      %iter_93 = cute.get_iter(%rmem) : !memref_rmem_bf16_
      %iter_94 = cute.get_iter(%rmem) : !memref_rmem_bf16_
      %lay_95 = cute.get_layout(%dst_partitioned_85) : !memref_gmem_bf16_5
      %31 = cute.make_layout_like(%lay_95) : !cute.layout<"((8,8),1,1):((1,512),0,0)"> to !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %rmem_96 = cute.memref.alloca(%31) : !memref_rmem_bf16_
      %iter_97 = cute.get_iter(%rmem_96) : !memref_rmem_bf16_
      %iter_98 = cute.get_iter(%rmem_96) : !memref_rmem_bf16_
      %coord_99 = cute.make_coord(%11) : (i32) -> !cute.coord<"?">
      %src_partitioned_100 = cute.tiled.copy.partition_S(%26, %tiled_view_73, %coord_99) : (!copy_simt, !memref_gmem_bf16_4, !cute.coord<"?">) -> !memref_gmem_bf16_5
      %iter_101 = cute.get_iter(%src_partitioned_100) : !memref_gmem_bf16_5
      %lay_102 = cute.get_layout(%src_partitioned_100) : !memref_gmem_bf16_5
      %32 = cute.make_layout_like(%lay_102) : !cute.layout<"((8,8),1,1):((1,512),0,0)"> to !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %rmem_103 = cute.memref.alloca(%32) : !memref_rmem_bf16_
      %iter_104 = cute.get_iter(%rmem_103) : !memref_rmem_bf16_
      %iter_105 = cute.get_iter(%rmem_103) : !memref_rmem_bf16_
      %retiled = cute.tiled.copy.retile(%25, %rmem_103) : (!copy_ldgsts, !memref_rmem_bf16_) -> !memref_rmem_bf16_
      %iter_106 = cute.get_iter(%retiled) : !memref_rmem_bf16_
      %sz = cute.size(%src_partitioned_88) <{mode = [0, 1]}> : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"8">
      %e0_107 = cute.get_leaves(%sz) : !cute.int_tuple<"8">
      %sz_108 = cute.size(%src_partitioned_88) <{mode = [1]}> : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"1">
      %e0_109 = cute.get_leaves(%sz_108) : !cute.int_tuple<"1">
      %sz_110 = cute.size(%src_partitioned_88) <{mode = [2]}> : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"1">
      %e0_111 = cute.get_leaves(%sz_110) : !cute.int_tuple<"1">
      %sz_112 = cute.size(%src_partitioned_88) <{mode = [2]}> : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"1">
      %e0_113 = cute.get_leaves(%sz_112) : !cute.int_tuple<"1">
      %shape_114 = cute.make_shape() : () -> !cute.shape<"(8,1,1)">
      %stride_115 = cute.make_stride() : () -> !cute.stride<"(1,0,1)">
      %lay_116 = cute.make_layout(%shape_114, %stride_115) : !cute.layout<"(8,1,1):(1,0,1)">
      %rmem_117 = cute.memref.alloca(%lay_116) : !memref_rmem_i8_
      %iter_118 = cute.get_iter(%rmem_117) : !memref_rmem_i8_
      %iter_119 = cute.get_iter(%rmem_117) : !memref_rmem_i8_
      %lay_120 = cute.get_layout(%rmem_117) : !memref_rmem_i8_
      %33 = cute.get_shape(%lay_120) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %e0_121, %e1_122, %e2_123 = cute.get_leaves(%33) : !cute.shape<"(8,1,1)">
      %coord_124 = cute.make_coord() : () -> !cute.coord<"((0,0),0,0)">
      %slice = cute.slice(%src_partitioned_88, %coord_124) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">, !cute.coord<"((0,0),0,0)">
      %iter_125 = cute.get_iter(%slice) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_126, %e1_127 = cute.get_leaves(%iter_125) : !cute.int_tuple<"(?,?{div=8})">
      %34 = cute.get_scalars(%e0_126) : !cute.int_tuple<"?">
      %35 = cute.get_scalars(%e1_127) : !cute.int_tuple<"?{div=8}">
      %iter_128 = cute.get_iter(%slice) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_129, %e1_130 = cute.get_leaves(%iter_128) : !cute.int_tuple<"(?,?{div=8})">
      %36 = cute.get_scalars(%e0_129) : !cute.int_tuple<"?">
      %37 = cute.get_scalars(%e1_130) : !cute.int_tuple<"?{div=8}">
      %iter_131 = cute.get_iter(%slice) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_132, %e1_133 = cute.get_leaves(%iter_131) : !cute.int_tuple<"(?,?{div=8})">
      %38 = cute.get_scalars(%e0_132) : !cute.int_tuple<"?">
      %39 = cute.get_scalars(%e1_133) : !cute.int_tuple<"?{div=8}">
      %coord_134 = cute.make_coord(%e1_133) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_135 = cute.make_coord() : () -> !cute.coord<"4096">
      %40 = cute.elem_less(%coord_134, %coord_135) : !cute.coord<"?{div=8}">, !cute.coord<"4096">
      %41 = arith.extui %40 : i1 to i8
      %coord_136 = cute.make_coord() : () -> !cute.coord<"(0,0,0)">
      cute.memref.store(%rmem_117, %coord_136, %41) : (!memref_rmem_i8_, !cute.coord<"(0,0,0)">, i8) -> ()
      %coord_137 = cute.make_coord() : () -> !cute.coord<"((0,1),0,0)">
      %slice_138 = cute.slice(%src_partitioned_88, %coord_137) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">, !cute.coord<"((0,1),0,0)">
      %iter_139 = cute.get_iter(%slice_138) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_140, %e1_141 = cute.get_leaves(%iter_139) : !cute.int_tuple<"(?,?{div=8})">
      %42 = cute.get_scalars(%e0_140) : !cute.int_tuple<"?">
      %43 = cute.get_scalars(%e1_141) : !cute.int_tuple<"?{div=8}">
      %iter_142 = cute.get_iter(%slice_138) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_143, %e1_144 = cute.get_leaves(%iter_142) : !cute.int_tuple<"(?,?{div=8})">
      %44 = cute.get_scalars(%e0_143) : !cute.int_tuple<"?">
      %45 = cute.get_scalars(%e1_144) : !cute.int_tuple<"?{div=8}">
      %iter_145 = cute.get_iter(%slice_138) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_146, %e1_147 = cute.get_leaves(%iter_145) : !cute.int_tuple<"(?,?{div=8})">
      %46 = cute.get_scalars(%e0_146) : !cute.int_tuple<"?">
      %47 = cute.get_scalars(%e1_147) : !cute.int_tuple<"?{div=8}">
      %coord_148 = cute.make_coord(%e1_147) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_149 = cute.make_coord() : () -> !cute.coord<"4096">
      %48 = cute.elem_less(%coord_148, %coord_149) : !cute.coord<"?{div=8}">, !cute.coord<"4096">
      %49 = arith.extui %48 : i1 to i8
      %coord_150 = cute.make_coord() : () -> !cute.coord<"(1,0,0)">
      cute.memref.store(%rmem_117, %coord_150, %49) : (!memref_rmem_i8_, !cute.coord<"(1,0,0)">, i8) -> ()
      %coord_151 = cute.make_coord() : () -> !cute.coord<"((0,2),0,0)">
      %slice_152 = cute.slice(%src_partitioned_88, %coord_151) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">, !cute.coord<"((0,2),0,0)">
      %iter_153 = cute.get_iter(%slice_152) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_154, %e1_155 = cute.get_leaves(%iter_153) : !cute.int_tuple<"(?,?{div=8})">
      %50 = cute.get_scalars(%e0_154) : !cute.int_tuple<"?">
      %51 = cute.get_scalars(%e1_155) : !cute.int_tuple<"?{div=8}">
      %iter_156 = cute.get_iter(%slice_152) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_157, %e1_158 = cute.get_leaves(%iter_156) : !cute.int_tuple<"(?,?{div=8})">
      %52 = cute.get_scalars(%e0_157) : !cute.int_tuple<"?">
      %53 = cute.get_scalars(%e1_158) : !cute.int_tuple<"?{div=8}">
      %iter_159 = cute.get_iter(%slice_152) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_160, %e1_161 = cute.get_leaves(%iter_159) : !cute.int_tuple<"(?,?{div=8})">
      %54 = cute.get_scalars(%e0_160) : !cute.int_tuple<"?">
      %55 = cute.get_scalars(%e1_161) : !cute.int_tuple<"?{div=8}">
      %coord_162 = cute.make_coord(%e1_161) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_163 = cute.make_coord() : () -> !cute.coord<"4096">
      %56 = cute.elem_less(%coord_162, %coord_163) : !cute.coord<"?{div=8}">, !cute.coord<"4096">
      %57 = arith.extui %56 : i1 to i8
      %coord_164 = cute.make_coord() : () -> !cute.coord<"(2,0,0)">
      cute.memref.store(%rmem_117, %coord_164, %57) : (!memref_rmem_i8_, !cute.coord<"(2,0,0)">, i8) -> ()
      %coord_165 = cute.make_coord() : () -> !cute.coord<"((0,3),0,0)">
      %slice_166 = cute.slice(%src_partitioned_88, %coord_165) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">, !cute.coord<"((0,3),0,0)">
      %iter_167 = cute.get_iter(%slice_166) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_168, %e1_169 = cute.get_leaves(%iter_167) : !cute.int_tuple<"(?,?{div=8})">
      %58 = cute.get_scalars(%e0_168) : !cute.int_tuple<"?">
      %59 = cute.get_scalars(%e1_169) : !cute.int_tuple<"?{div=8}">
      %iter_170 = cute.get_iter(%slice_166) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_171, %e1_172 = cute.get_leaves(%iter_170) : !cute.int_tuple<"(?,?{div=8})">
      %60 = cute.get_scalars(%e0_171) : !cute.int_tuple<"?">
      %61 = cute.get_scalars(%e1_172) : !cute.int_tuple<"?{div=8}">
      %iter_173 = cute.get_iter(%slice_166) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_174, %e1_175 = cute.get_leaves(%iter_173) : !cute.int_tuple<"(?,?{div=8})">
      %62 = cute.get_scalars(%e0_174) : !cute.int_tuple<"?">
      %63 = cute.get_scalars(%e1_175) : !cute.int_tuple<"?{div=8}">
      %coord_176 = cute.make_coord(%e1_175) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_177 = cute.make_coord() : () -> !cute.coord<"4096">
      %64 = cute.elem_less(%coord_176, %coord_177) : !cute.coord<"?{div=8}">, !cute.coord<"4096">
      %65 = arith.extui %64 : i1 to i8
      %coord_178 = cute.make_coord() : () -> !cute.coord<"(3,0,0)">
      cute.memref.store(%rmem_117, %coord_178, %65) : (!memref_rmem_i8_, !cute.coord<"(3,0,0)">, i8) -> ()
      %coord_179 = cute.make_coord() : () -> !cute.coord<"((0,4),0,0)">
      %slice_180 = cute.slice(%src_partitioned_88, %coord_179) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">, !cute.coord<"((0,4),0,0)">
      %iter_181 = cute.get_iter(%slice_180) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_182, %e1_183 = cute.get_leaves(%iter_181) : !cute.int_tuple<"(?,?{div=8})">
      %66 = cute.get_scalars(%e0_182) : !cute.int_tuple<"?">
      %67 = cute.get_scalars(%e1_183) : !cute.int_tuple<"?{div=8}">
      %iter_184 = cute.get_iter(%slice_180) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_185, %e1_186 = cute.get_leaves(%iter_184) : !cute.int_tuple<"(?,?{div=8})">
      %68 = cute.get_scalars(%e0_185) : !cute.int_tuple<"?">
      %69 = cute.get_scalars(%e1_186) : !cute.int_tuple<"?{div=8}">
      %iter_187 = cute.get_iter(%slice_180) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_188, %e1_189 = cute.get_leaves(%iter_187) : !cute.int_tuple<"(?,?{div=8})">
      %70 = cute.get_scalars(%e0_188) : !cute.int_tuple<"?">
      %71 = cute.get_scalars(%e1_189) : !cute.int_tuple<"?{div=8}">
      %coord_190 = cute.make_coord(%e1_189) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_191 = cute.make_coord() : () -> !cute.coord<"4096">
      %72 = cute.elem_less(%coord_190, %coord_191) : !cute.coord<"?{div=8}">, !cute.coord<"4096">
      %73 = arith.extui %72 : i1 to i8
      %coord_192 = cute.make_coord() : () -> !cute.coord<"(4,0,0)">
      cute.memref.store(%rmem_117, %coord_192, %73) : (!memref_rmem_i8_, !cute.coord<"(4,0,0)">, i8) -> ()
      %coord_193 = cute.make_coord() : () -> !cute.coord<"((0,5),0,0)">
      %slice_194 = cute.slice(%src_partitioned_88, %coord_193) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">, !cute.coord<"((0,5),0,0)">
      %iter_195 = cute.get_iter(%slice_194) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_196, %e1_197 = cute.get_leaves(%iter_195) : !cute.int_tuple<"(?,?{div=8})">
      %74 = cute.get_scalars(%e0_196) : !cute.int_tuple<"?">
      %75 = cute.get_scalars(%e1_197) : !cute.int_tuple<"?{div=8}">
      %iter_198 = cute.get_iter(%slice_194) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_199, %e1_200 = cute.get_leaves(%iter_198) : !cute.int_tuple<"(?,?{div=8})">
      %76 = cute.get_scalars(%e0_199) : !cute.int_tuple<"?">
      %77 = cute.get_scalars(%e1_200) : !cute.int_tuple<"?{div=8}">
      %iter_201 = cute.get_iter(%slice_194) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_202, %e1_203 = cute.get_leaves(%iter_201) : !cute.int_tuple<"(?,?{div=8})">
      %78 = cute.get_scalars(%e0_202) : !cute.int_tuple<"?">
      %79 = cute.get_scalars(%e1_203) : !cute.int_tuple<"?{div=8}">
      %coord_204 = cute.make_coord(%e1_203) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_205 = cute.make_coord() : () -> !cute.coord<"4096">
      %80 = cute.elem_less(%coord_204, %coord_205) : !cute.coord<"?{div=8}">, !cute.coord<"4096">
      %81 = arith.extui %80 : i1 to i8
      %coord_206 = cute.make_coord() : () -> !cute.coord<"(5,0,0)">
      cute.memref.store(%rmem_117, %coord_206, %81) : (!memref_rmem_i8_, !cute.coord<"(5,0,0)">, i8) -> ()
      %coord_207 = cute.make_coord() : () -> !cute.coord<"((0,6),0,0)">
      %slice_208 = cute.slice(%src_partitioned_88, %coord_207) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">, !cute.coord<"((0,6),0,0)">
      %iter_209 = cute.get_iter(%slice_208) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_210, %e1_211 = cute.get_leaves(%iter_209) : !cute.int_tuple<"(?,?{div=8})">
      %82 = cute.get_scalars(%e0_210) : !cute.int_tuple<"?">
      %83 = cute.get_scalars(%e1_211) : !cute.int_tuple<"?{div=8}">
      %iter_212 = cute.get_iter(%slice_208) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_213, %e1_214 = cute.get_leaves(%iter_212) : !cute.int_tuple<"(?,?{div=8})">
      %84 = cute.get_scalars(%e0_213) : !cute.int_tuple<"?">
      %85 = cute.get_scalars(%e1_214) : !cute.int_tuple<"?{div=8}">
      %iter_215 = cute.get_iter(%slice_208) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_216, %e1_217 = cute.get_leaves(%iter_215) : !cute.int_tuple<"(?,?{div=8})">
      %86 = cute.get_scalars(%e0_216) : !cute.int_tuple<"?">
      %87 = cute.get_scalars(%e1_217) : !cute.int_tuple<"?{div=8}">
      %coord_218 = cute.make_coord(%e1_217) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_219 = cute.make_coord() : () -> !cute.coord<"4096">
      %88 = cute.elem_less(%coord_218, %coord_219) : !cute.coord<"?{div=8}">, !cute.coord<"4096">
      %89 = arith.extui %88 : i1 to i8
      %coord_220 = cute.make_coord() : () -> !cute.coord<"(6,0,0)">
      cute.memref.store(%rmem_117, %coord_220, %89) : (!memref_rmem_i8_, !cute.coord<"(6,0,0)">, i8) -> ()
      %coord_221 = cute.make_coord() : () -> !cute.coord<"((0,7),0,0)">
      %slice_222 = cute.slice(%src_partitioned_88, %coord_221) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">, !cute.coord<"((0,7),0,0)">
      %iter_223 = cute.get_iter(%slice_222) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_224, %e1_225 = cute.get_leaves(%iter_223) : !cute.int_tuple<"(?,?{div=8})">
      %90 = cute.get_scalars(%e0_224) : !cute.int_tuple<"?">
      %91 = cute.get_scalars(%e1_225) : !cute.int_tuple<"?{div=8}">
      %iter_226 = cute.get_iter(%slice_222) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_227, %e1_228 = cute.get_leaves(%iter_226) : !cute.int_tuple<"(?,?{div=8})">
      %92 = cute.get_scalars(%e0_227) : !cute.int_tuple<"?">
      %93 = cute.get_scalars(%e1_228) : !cute.int_tuple<"?{div=8}">
      %iter_229 = cute.get_iter(%slice_222) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_230, %e1_231 = cute.get_leaves(%iter_229) : !cute.int_tuple<"(?,?{div=8})">
      %94 = cute.get_scalars(%e0_230) : !cute.int_tuple<"?">
      %95 = cute.get_scalars(%e1_231) : !cute.int_tuple<"?{div=8}">
      %coord_232 = cute.make_coord(%e1_231) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_233 = cute.make_coord() : () -> !cute.coord<"4096">
      %96 = cute.elem_less(%coord_232, %coord_233) : !cute.coord<"?{div=8}">, !cute.coord<"4096">
      %97 = arith.extui %96 : i1 to i8
      %coord_234 = cute.make_coord() : () -> !cute.coord<"(7,0,0)">
      cute.memref.store(%rmem_117, %coord_234, %97) : (!memref_rmem_i8_, !cute.coord<"(7,0,0)">, i8) -> ()
      %coord_235 = cute.make_coord() : () -> !cute.coord<"((0,0),0,0)">
      %slice_236 = cute.slice(%src_partitioned_88, %coord_235) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">, !cute.coord<"((0,0),0,0)">
      %iter_237 = cute.get_iter(%slice_236) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_238, %e1_239 = cute.get_leaves(%iter_237) : !cute.int_tuple<"(?,?{div=8})">
      %98 = cute.get_scalars(%e0_238) : !cute.int_tuple<"?">
      %99 = cute.get_scalars(%e1_239) : !cute.int_tuple<"?{div=8}">
      %iter_240 = cute.get_iter(%slice_236) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_241, %e1_242 = cute.get_leaves(%iter_240) : !cute.int_tuple<"(?,?{div=8})">
      %100 = cute.get_scalars(%e0_241) : !cute.int_tuple<"?">
      %101 = cute.get_scalars(%e1_242) : !cute.int_tuple<"?{div=8}">
      %iter_243 = cute.get_iter(%slice_236) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_244, %e1_245 = cute.get_leaves(%iter_243) : !cute.int_tuple<"(?,?{div=8})">
      %102 = cute.get_scalars(%e0_244) : !cute.int_tuple<"?">
      %103 = cute.get_scalars(%e1_245) : !cute.int_tuple<"?{div=8}">
      %104 = arith.cmpi slt, %102, %18 : i32
      scf.if %104 {
        %lay_552 = cute.get_layout(%src_partitioned) : !memref_gmem_bf16_5
        %251 = cute.get_shape(%lay_552) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %e0_553, %e1_554, %e2_555, %e3_556 = cute.get_leaves(%251) : !cute.shape<"((8,8),1,1)">
        %lay_557 = cute.get_layout(%dst_partitioned) : !memref_smem_bf16_1
        %252 = cute.get_shape(%lay_557) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %e0_558, %e1_559, %e2_560, %e3_561 = cute.get_leaves(%252) : !cute.shape<"((8,8),1,1)">
        %lay_562 = cute.get_layout(%src_partitioned) : !memref_gmem_bf16_5
        %shape_563 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_564 = cute.make_layout(%shape_563) : !cute.layout<"1:0">
        %append_565 = cute.append_to_rank<2> (%lay_562, %lay_564) : !cute.layout<"((8,8),1,1):((1,512),0,0)">, !cute.layout<"1:0">
        %view_566 = cute.make_view(%iter_81, %append_565) : !memref_gmem_bf16_5
        %iter_567 = cute.get_iter(%view_566) : !memref_gmem_bf16_5
        %lay_568 = cute.get_layout(%view_566) : !memref_gmem_bf16_5
        %253 = cute.get_shape(%lay_568) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %e0_569, %e1_570, %e2_571, %e3_572 = cute.get_leaves(%253) : !cute.shape<"((8,8),1,1)">
        %grouped_573 = cute.group_modes(%view_566) <1, 3> : (!memref_gmem_bf16_5) -> !memref_gmem_bf16_6
        %iter_574 = cute.get_iter(%grouped_573) : !memref_gmem_bf16_6
        %iter_575 = cute.get_iter(%grouped_573) : !memref_gmem_bf16_6
        %lay_576 = cute.get_layout(%dst_partitioned) : !memref_smem_bf16_1
        %shape_577 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_578 = cute.make_layout(%shape_577) : !cute.layout<"1:0">
        %append_579 = cute.append_to_rank<2> (%lay_576, %lay_578) : !cute.layout<"((8,8),1,1):((1,512),0,0)">, !cute.layout<"1:0">
        %view_580 = cute.make_view(%iter_83, %append_579) : !memref_smem_bf16_1
        %iter_581 = cute.get_iter(%view_580) : !memref_smem_bf16_1
        %lay_582 = cute.get_layout(%view_580) : !memref_smem_bf16_1
        %254 = cute.get_shape(%lay_582) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %e0_583, %e1_584, %e2_585, %e3_586 = cute.get_leaves(%254) : !cute.shape<"((8,8),1,1)">
        %grouped_587 = cute.group_modes(%view_580) <1, 3> : (!memref_smem_bf16_1) -> !memref_smem_bf16_2
        %iter_588 = cute.get_iter(%grouped_587) : !memref_smem_bf16_2
        %iter_589 = cute.get_iter(%grouped_587) : !memref_smem_bf16_2
        %lay_590 = cute.get_layout(%rmem_117) : !memref_rmem_i8_
        %shape_591 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_592 = cute.make_layout(%shape_591) : !cute.layout<"1:0">
        %append_593 = cute.append_to_rank<2> (%lay_590, %lay_592) : !cute.layout<"(8,1,1):(1,0,1)">, !cute.layout<"1:0">
        %view_594 = cute.make_view(%iter_119, %append_593) : !memref_rmem_i8_
        %iter_595 = cute.get_iter(%view_594) : !memref_rmem_i8_
        %lay_596 = cute.get_layout(%view_594) : !memref_rmem_i8_
        %255 = cute.get_shape(%lay_596) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
        %e0_597, %e1_598, %e2_599 = cute.get_leaves(%255) : !cute.shape<"(8,1,1)">
        %grouped_600 = cute.group_modes(%view_594) <1, 3> : (!memref_rmem_i8_) -> !memref_rmem_i8_1
        %iter_601 = cute.get_iter(%grouped_600) : !memref_rmem_i8_1
        %iter_602 = cute.get_iter(%grouped_600) : !memref_rmem_i8_1
        %lay_603 = cute.get_layout(%grouped_573) : !memref_gmem_bf16_6
        %256 = cute.get_shape(%lay_603) : (!cute.layout<"((8,8),(1,1)):((1,512),(0,0))">) -> !cute.shape<"((8,8),(1,1))">
        %e0_604, %e1_605, %e2_606, %e3_607 = cute.get_leaves(%256) : !cute.shape<"((8,8),(1,1))">
        %lay_608 = cute.get_layout(%grouped_587) : !memref_smem_bf16_2
        %257 = cute.get_shape(%lay_608) : (!cute.layout<"((8,8),(1,1)):((1,512),(0,0))">) -> !cute.shape<"((8,8),(1,1))">
        %e0_609, %e1_610, %e2_611, %e3_612 = cute.get_leaves(%257) : !cute.shape<"((8,8),(1,1))">
        %sz_613 = cute.size(%grouped_573) <{mode = [1]}> : (!memref_gmem_bf16_6) -> !cute.int_tuple<"1">
        %e0_614 = cute.get_leaves(%sz_613) : !cute.int_tuple<"1">
        %sz_615 = cute.size(%grouped_587) <{mode = [1]}> : (!memref_smem_bf16_2) -> !cute.int_tuple<"1">
        %e0_616 = cute.get_leaves(%sz_615) : !cute.int_tuple<"1">
        cute.copy(%atom, %grouped_573, %grouped_587, %grouped_600) : (!cute_nvgpu.atom.simt_async_copy<bf16, cache = always, 128 b>, !memref_gmem_bf16_6, !memref_smem_bf16_2, !memref_rmem_i8_1)
      }
      nvvm.cp.async.commit.group
      %coord_246 = cute.make_coord(%11) : (i32) -> !cute.coord<"?">
      %src_partitioned_247 = cute.tiled.copy.partition_S(%26, %tiled_view_61, %coord_246) : (!copy_simt, !cute.coord_tensor<"(?{div=2},0)", "(2,4096):(1@0,1@1)">, !cute.coord<"?">) -> !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %iter_248 = cute.get_iter(%src_partitioned_247) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %e0_249, %e1_250 = cute.get_leaves(%iter_248) : !cute.int_tuple<"(?,?{div=8})">
      %105 = cute.get_scalars(%e0_249) : !cute.int_tuple<"?">
      %106 = cute.get_scalars(%e1_250) : !cute.int_tuple<"?{div=8}">
      %sz_251 = cute.size(%src_partitioned_247) <{mode = [0, 1]}> : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"8">
      %e0_252 = cute.get_leaves(%sz_251) : !cute.int_tuple<"8">
      %sz_253 = cute.size(%src_partitioned_247) <{mode = [1]}> : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"1">
      %e0_254 = cute.get_leaves(%sz_253) : !cute.int_tuple<"1">
      %sz_255 = cute.size(%src_partitioned_247) <{mode = [2]}> : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"1">
      %e0_256 = cute.get_leaves(%sz_255) : !cute.int_tuple<"1">
      %sz_257 = cute.size(%src_partitioned_247) <{mode = [2]}> : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"1">
      %e0_258 = cute.get_leaves(%sz_257) : !cute.int_tuple<"1">
      %shape_259 = cute.make_shape() : () -> !cute.shape<"(8,1,1)">
      %stride_260 = cute.make_stride() : () -> !cute.stride<"(1,0,1)">
      %lay_261 = cute.make_layout(%shape_259, %stride_260) : !cute.layout<"(8,1,1):(1,0,1)">
      %rmem_262 = cute.memref.alloca(%lay_261) : !memref_rmem_i8_
      %iter_263 = cute.get_iter(%rmem_262) : !memref_rmem_i8_
      %iter_264 = cute.get_iter(%rmem_262) : !memref_rmem_i8_
      %lay_265 = cute.get_layout(%rmem_262) : !memref_rmem_i8_
      %107 = cute.get_shape(%lay_265) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %e0_266, %e1_267, %e2_268 = cute.get_leaves(%107) : !cute.shape<"(8,1,1)">
      %coord_269 = cute.make_coord() : () -> !cute.coord<"((0,0),0,0)">
      %slice_270 = cute.slice(%src_partitioned_247, %coord_269) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">, !cute.coord<"((0,0),0,0)">
      %iter_271 = cute.get_iter(%slice_270) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_272, %e1_273 = cute.get_leaves(%iter_271) : !cute.int_tuple<"(?,?{div=8})">
      %108 = cute.get_scalars(%e0_272) : !cute.int_tuple<"?">
      %109 = cute.get_scalars(%e1_273) : !cute.int_tuple<"?{div=8}">
      %iter_274 = cute.get_iter(%slice_270) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_275, %e1_276 = cute.get_leaves(%iter_274) : !cute.int_tuple<"(?,?{div=8})">
      %110 = cute.get_scalars(%e0_275) : !cute.int_tuple<"?">
      %111 = cute.get_scalars(%e1_276) : !cute.int_tuple<"?{div=8}">
      %iter_277 = cute.get_iter(%slice_270) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_278, %e1_279 = cute.get_leaves(%iter_277) : !cute.int_tuple<"(?,?{div=8})">
      %112 = cute.get_scalars(%e0_278) : !cute.int_tuple<"?">
      %113 = cute.get_scalars(%e1_279) : !cute.int_tuple<"?{div=8}">
      %coord_280 = cute.make_coord(%e1_279) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_281 = cute.make_coord() : () -> !cute.coord<"4096">
      %114 = cute.elem_less(%coord_280, %coord_281) : !cute.coord<"?{div=8}">, !cute.coord<"4096">
      %115 = arith.extui %114 : i1 to i8
      %coord_282 = cute.make_coord() : () -> !cute.coord<"(0,0,0)">
      cute.memref.store(%rmem_262, %coord_282, %115) : (!memref_rmem_i8_, !cute.coord<"(0,0,0)">, i8) -> ()
      %coord_283 = cute.make_coord() : () -> !cute.coord<"((0,1),0,0)">
      %slice_284 = cute.slice(%src_partitioned_247, %coord_283) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">, !cute.coord<"((0,1),0,0)">
      %iter_285 = cute.get_iter(%slice_284) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_286, %e1_287 = cute.get_leaves(%iter_285) : !cute.int_tuple<"(?,?{div=8})">
      %116 = cute.get_scalars(%e0_286) : !cute.int_tuple<"?">
      %117 = cute.get_scalars(%e1_287) : !cute.int_tuple<"?{div=8}">
      %iter_288 = cute.get_iter(%slice_284) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_289, %e1_290 = cute.get_leaves(%iter_288) : !cute.int_tuple<"(?,?{div=8})">
      %118 = cute.get_scalars(%e0_289) : !cute.int_tuple<"?">
      %119 = cute.get_scalars(%e1_290) : !cute.int_tuple<"?{div=8}">
      %iter_291 = cute.get_iter(%slice_284) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_292, %e1_293 = cute.get_leaves(%iter_291) : !cute.int_tuple<"(?,?{div=8})">
      %120 = cute.get_scalars(%e0_292) : !cute.int_tuple<"?">
      %121 = cute.get_scalars(%e1_293) : !cute.int_tuple<"?{div=8}">
      %coord_294 = cute.make_coord(%e1_293) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_295 = cute.make_coord() : () -> !cute.coord<"4096">
      %122 = cute.elem_less(%coord_294, %coord_295) : !cute.coord<"?{div=8}">, !cute.coord<"4096">
      %123 = arith.extui %122 : i1 to i8
      %coord_296 = cute.make_coord() : () -> !cute.coord<"(1,0,0)">
      cute.memref.store(%rmem_262, %coord_296, %123) : (!memref_rmem_i8_, !cute.coord<"(1,0,0)">, i8) -> ()
      %coord_297 = cute.make_coord() : () -> !cute.coord<"((0,2),0,0)">
      %slice_298 = cute.slice(%src_partitioned_247, %coord_297) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">, !cute.coord<"((0,2),0,0)">
      %iter_299 = cute.get_iter(%slice_298) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_300, %e1_301 = cute.get_leaves(%iter_299) : !cute.int_tuple<"(?,?{div=8})">
      %124 = cute.get_scalars(%e0_300) : !cute.int_tuple<"?">
      %125 = cute.get_scalars(%e1_301) : !cute.int_tuple<"?{div=8}">
      %iter_302 = cute.get_iter(%slice_298) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_303, %e1_304 = cute.get_leaves(%iter_302) : !cute.int_tuple<"(?,?{div=8})">
      %126 = cute.get_scalars(%e0_303) : !cute.int_tuple<"?">
      %127 = cute.get_scalars(%e1_304) : !cute.int_tuple<"?{div=8}">
      %iter_305 = cute.get_iter(%slice_298) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_306, %e1_307 = cute.get_leaves(%iter_305) : !cute.int_tuple<"(?,?{div=8})">
      %128 = cute.get_scalars(%e0_306) : !cute.int_tuple<"?">
      %129 = cute.get_scalars(%e1_307) : !cute.int_tuple<"?{div=8}">
      %coord_308 = cute.make_coord(%e1_307) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_309 = cute.make_coord() : () -> !cute.coord<"4096">
      %130 = cute.elem_less(%coord_308, %coord_309) : !cute.coord<"?{div=8}">, !cute.coord<"4096">
      %131 = arith.extui %130 : i1 to i8
      %coord_310 = cute.make_coord() : () -> !cute.coord<"(2,0,0)">
      cute.memref.store(%rmem_262, %coord_310, %131) : (!memref_rmem_i8_, !cute.coord<"(2,0,0)">, i8) -> ()
      %coord_311 = cute.make_coord() : () -> !cute.coord<"((0,3),0,0)">
      %slice_312 = cute.slice(%src_partitioned_247, %coord_311) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">, !cute.coord<"((0,3),0,0)">
      %iter_313 = cute.get_iter(%slice_312) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_314, %e1_315 = cute.get_leaves(%iter_313) : !cute.int_tuple<"(?,?{div=8})">
      %132 = cute.get_scalars(%e0_314) : !cute.int_tuple<"?">
      %133 = cute.get_scalars(%e1_315) : !cute.int_tuple<"?{div=8}">
      %iter_316 = cute.get_iter(%slice_312) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_317, %e1_318 = cute.get_leaves(%iter_316) : !cute.int_tuple<"(?,?{div=8})">
      %134 = cute.get_scalars(%e0_317) : !cute.int_tuple<"?">
      %135 = cute.get_scalars(%e1_318) : !cute.int_tuple<"?{div=8}">
      %iter_319 = cute.get_iter(%slice_312) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_320, %e1_321 = cute.get_leaves(%iter_319) : !cute.int_tuple<"(?,?{div=8})">
      %136 = cute.get_scalars(%e0_320) : !cute.int_tuple<"?">
      %137 = cute.get_scalars(%e1_321) : !cute.int_tuple<"?{div=8}">
      %coord_322 = cute.make_coord(%e1_321) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_323 = cute.make_coord() : () -> !cute.coord<"4096">
      %138 = cute.elem_less(%coord_322, %coord_323) : !cute.coord<"?{div=8}">, !cute.coord<"4096">
      %139 = arith.extui %138 : i1 to i8
      %coord_324 = cute.make_coord() : () -> !cute.coord<"(3,0,0)">
      cute.memref.store(%rmem_262, %coord_324, %139) : (!memref_rmem_i8_, !cute.coord<"(3,0,0)">, i8) -> ()
      %coord_325 = cute.make_coord() : () -> !cute.coord<"((0,4),0,0)">
      %slice_326 = cute.slice(%src_partitioned_247, %coord_325) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">, !cute.coord<"((0,4),0,0)">
      %iter_327 = cute.get_iter(%slice_326) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_328, %e1_329 = cute.get_leaves(%iter_327) : !cute.int_tuple<"(?,?{div=8})">
      %140 = cute.get_scalars(%e0_328) : !cute.int_tuple<"?">
      %141 = cute.get_scalars(%e1_329) : !cute.int_tuple<"?{div=8}">
      %iter_330 = cute.get_iter(%slice_326) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_331, %e1_332 = cute.get_leaves(%iter_330) : !cute.int_tuple<"(?,?{div=8})">
      %142 = cute.get_scalars(%e0_331) : !cute.int_tuple<"?">
      %143 = cute.get_scalars(%e1_332) : !cute.int_tuple<"?{div=8}">
      %iter_333 = cute.get_iter(%slice_326) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_334, %e1_335 = cute.get_leaves(%iter_333) : !cute.int_tuple<"(?,?{div=8})">
      %144 = cute.get_scalars(%e0_334) : !cute.int_tuple<"?">
      %145 = cute.get_scalars(%e1_335) : !cute.int_tuple<"?{div=8}">
      %coord_336 = cute.make_coord(%e1_335) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_337 = cute.make_coord() : () -> !cute.coord<"4096">
      %146 = cute.elem_less(%coord_336, %coord_337) : !cute.coord<"?{div=8}">, !cute.coord<"4096">
      %147 = arith.extui %146 : i1 to i8
      %coord_338 = cute.make_coord() : () -> !cute.coord<"(4,0,0)">
      cute.memref.store(%rmem_262, %coord_338, %147) : (!memref_rmem_i8_, !cute.coord<"(4,0,0)">, i8) -> ()
      %coord_339 = cute.make_coord() : () -> !cute.coord<"((0,5),0,0)">
      %slice_340 = cute.slice(%src_partitioned_247, %coord_339) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">, !cute.coord<"((0,5),0,0)">
      %iter_341 = cute.get_iter(%slice_340) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_342, %e1_343 = cute.get_leaves(%iter_341) : !cute.int_tuple<"(?,?{div=8})">
      %148 = cute.get_scalars(%e0_342) : !cute.int_tuple<"?">
      %149 = cute.get_scalars(%e1_343) : !cute.int_tuple<"?{div=8}">
      %iter_344 = cute.get_iter(%slice_340) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_345, %e1_346 = cute.get_leaves(%iter_344) : !cute.int_tuple<"(?,?{div=8})">
      %150 = cute.get_scalars(%e0_345) : !cute.int_tuple<"?">
      %151 = cute.get_scalars(%e1_346) : !cute.int_tuple<"?{div=8}">
      %iter_347 = cute.get_iter(%slice_340) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_348, %e1_349 = cute.get_leaves(%iter_347) : !cute.int_tuple<"(?,?{div=8})">
      %152 = cute.get_scalars(%e0_348) : !cute.int_tuple<"?">
      %153 = cute.get_scalars(%e1_349) : !cute.int_tuple<"?{div=8}">
      %coord_350 = cute.make_coord(%e1_349) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_351 = cute.make_coord() : () -> !cute.coord<"4096">
      %154 = cute.elem_less(%coord_350, %coord_351) : !cute.coord<"?{div=8}">, !cute.coord<"4096">
      %155 = arith.extui %154 : i1 to i8
      %coord_352 = cute.make_coord() : () -> !cute.coord<"(5,0,0)">
      cute.memref.store(%rmem_262, %coord_352, %155) : (!memref_rmem_i8_, !cute.coord<"(5,0,0)">, i8) -> ()
      %coord_353 = cute.make_coord() : () -> !cute.coord<"((0,6),0,0)">
      %slice_354 = cute.slice(%src_partitioned_247, %coord_353) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">, !cute.coord<"((0,6),0,0)">
      %iter_355 = cute.get_iter(%slice_354) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_356, %e1_357 = cute.get_leaves(%iter_355) : !cute.int_tuple<"(?,?{div=8})">
      %156 = cute.get_scalars(%e0_356) : !cute.int_tuple<"?">
      %157 = cute.get_scalars(%e1_357) : !cute.int_tuple<"?{div=8}">
      %iter_358 = cute.get_iter(%slice_354) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_359, %e1_360 = cute.get_leaves(%iter_358) : !cute.int_tuple<"(?,?{div=8})">
      %158 = cute.get_scalars(%e0_359) : !cute.int_tuple<"?">
      %159 = cute.get_scalars(%e1_360) : !cute.int_tuple<"?{div=8}">
      %iter_361 = cute.get_iter(%slice_354) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_362, %e1_363 = cute.get_leaves(%iter_361) : !cute.int_tuple<"(?,?{div=8})">
      %160 = cute.get_scalars(%e0_362) : !cute.int_tuple<"?">
      %161 = cute.get_scalars(%e1_363) : !cute.int_tuple<"?{div=8}">
      %coord_364 = cute.make_coord(%e1_363) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_365 = cute.make_coord() : () -> !cute.coord<"4096">
      %162 = cute.elem_less(%coord_364, %coord_365) : !cute.coord<"?{div=8}">, !cute.coord<"4096">
      %163 = arith.extui %162 : i1 to i8
      %coord_366 = cute.make_coord() : () -> !cute.coord<"(6,0,0)">
      cute.memref.store(%rmem_262, %coord_366, %163) : (!memref_rmem_i8_, !cute.coord<"(6,0,0)">, i8) -> ()
      %coord_367 = cute.make_coord() : () -> !cute.coord<"((0,7),0,0)">
      %slice_368 = cute.slice(%src_partitioned_247, %coord_367) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">, !cute.coord<"((0,7),0,0)">
      %iter_369 = cute.get_iter(%slice_368) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_370, %e1_371 = cute.get_leaves(%iter_369) : !cute.int_tuple<"(?,?{div=8})">
      %164 = cute.get_scalars(%e0_370) : !cute.int_tuple<"?">
      %165 = cute.get_scalars(%e1_371) : !cute.int_tuple<"?{div=8}">
      %iter_372 = cute.get_iter(%slice_368) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_373, %e1_374 = cute.get_leaves(%iter_372) : !cute.int_tuple<"(?,?{div=8})">
      %166 = cute.get_scalars(%e0_373) : !cute.int_tuple<"?">
      %167 = cute.get_scalars(%e1_374) : !cute.int_tuple<"?{div=8}">
      %iter_375 = cute.get_iter(%slice_368) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_376, %e1_377 = cute.get_leaves(%iter_375) : !cute.int_tuple<"(?,?{div=8})">
      %168 = cute.get_scalars(%e0_376) : !cute.int_tuple<"?">
      %169 = cute.get_scalars(%e1_377) : !cute.int_tuple<"?{div=8}">
      %coord_378 = cute.make_coord(%e1_377) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_379 = cute.make_coord() : () -> !cute.coord<"4096">
      %170 = cute.elem_less(%coord_378, %coord_379) : !cute.coord<"?{div=8}">, !cute.coord<"4096">
      %171 = arith.extui %170 : i1 to i8
      %coord_380 = cute.make_coord() : () -> !cute.coord<"(7,0,0)">
      cute.memref.store(%rmem_262, %coord_380, %171) : (!memref_rmem_i8_, !cute.coord<"(7,0,0)">, i8) -> ()
      %lay_381 = cute.get_layout(%src_partitioned_100) : !memref_gmem_bf16_5
      %172 = cute.get_shape(%lay_381) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %e0_382, %e1_383, %e2_384, %e3_385 = cute.get_leaves(%172) : !cute.shape<"((8,8),1,1)">
      %lay_386 = cute.get_layout(%rmem_103) : !memref_rmem_bf16_
      %173 = cute.get_shape(%lay_386) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %e0_387, %e1_388, %e2_389, %e3_390 = cute.get_leaves(%173) : !cute.shape<"((8,8),1,1)">
      %lay_391 = cute.get_layout(%src_partitioned_100) : !memref_gmem_bf16_5
      %shape_392 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_393 = cute.make_layout(%shape_392) : !cute.layout<"1:0">
      %append = cute.append_to_rank<2> (%lay_391, %lay_393) : !cute.layout<"((8,8),1,1):((1,512),0,0)">, !cute.layout<"1:0">
      %view_394 = cute.make_view(%iter_101, %append) : !memref_gmem_bf16_5
      %iter_395 = cute.get_iter(%view_394) : !memref_gmem_bf16_5
      %lay_396 = cute.get_layout(%view_394) : !memref_gmem_bf16_5
      %174 = cute.get_shape(%lay_396) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %e0_397, %e1_398, %e2_399, %e3_400 = cute.get_leaves(%174) : !cute.shape<"((8,8),1,1)">
      %grouped = cute.group_modes(%view_394) <1, 3> : (!memref_gmem_bf16_5) -> !memref_gmem_bf16_6
      %iter_401 = cute.get_iter(%grouped) : !memref_gmem_bf16_6
      %iter_402 = cute.get_iter(%grouped) : !memref_gmem_bf16_6
      %lay_403 = cute.get_layout(%rmem_103) : !memref_rmem_bf16_
      %shape_404 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_405 = cute.make_layout(%shape_404) : !cute.layout<"1:0">
      %append_406 = cute.append_to_rank<2> (%lay_403, %lay_405) : !cute.layout<"((8,8),1,1):((1,8),0,0)">, !cute.layout<"1:0">
      %view_407 = cute.make_view(%iter_105, %append_406) : !memref_rmem_bf16_
      %iter_408 = cute.get_iter(%view_407) : !memref_rmem_bf16_
      %lay_409 = cute.get_layout(%view_407) : !memref_rmem_bf16_
      %175 = cute.get_shape(%lay_409) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %e0_410, %e1_411, %e2_412, %e3_413 = cute.get_leaves(%175) : !cute.shape<"((8,8),1,1)">
      %grouped_414 = cute.group_modes(%view_407) <1, 3> : (!memref_rmem_bf16_) -> !memref_rmem_bf16_1
      %iter_415 = cute.get_iter(%grouped_414) : !memref_rmem_bf16_1
      %iter_416 = cute.get_iter(%grouped_414) : !memref_rmem_bf16_1
      %lay_417 = cute.get_layout(%rmem_262) : !memref_rmem_i8_
      %shape_418 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_419 = cute.make_layout(%shape_418) : !cute.layout<"1:0">
      %append_420 = cute.append_to_rank<2> (%lay_417, %lay_419) : !cute.layout<"(8,1,1):(1,0,1)">, !cute.layout<"1:0">
      %view_421 = cute.make_view(%iter_264, %append_420) : !memref_rmem_i8_
      %iter_422 = cute.get_iter(%view_421) : !memref_rmem_i8_
      %lay_423 = cute.get_layout(%view_421) : !memref_rmem_i8_
      %176 = cute.get_shape(%lay_423) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %e0_424, %e1_425, %e2_426 = cute.get_leaves(%176) : !cute.shape<"(8,1,1)">
      %grouped_427 = cute.group_modes(%view_421) <1, 3> : (!memref_rmem_i8_) -> !memref_rmem_i8_1
      %iter_428 = cute.get_iter(%grouped_427) : !memref_rmem_i8_1
      %iter_429 = cute.get_iter(%grouped_427) : !memref_rmem_i8_1
      %lay_430 = cute.get_layout(%grouped) : !memref_gmem_bf16_6
      %177 = cute.get_shape(%lay_430) : (!cute.layout<"((8,8),(1,1)):((1,512),(0,0))">) -> !cute.shape<"((8,8),(1,1))">
      %e0_431, %e1_432, %e2_433, %e3_434 = cute.get_leaves(%177) : !cute.shape<"((8,8),(1,1))">
      %lay_435 = cute.get_layout(%grouped_414) : !memref_rmem_bf16_1
      %178 = cute.get_shape(%lay_435) : (!cute.layout<"((8,8),(1,1)):((1,8),(0,0))">) -> !cute.shape<"((8,8),(1,1))">
      %e0_436, %e1_437, %e2_438, %e3_439 = cute.get_leaves(%178) : !cute.shape<"((8,8),(1,1))">
      %sz_440 = cute.size(%grouped) <{mode = [1]}> : (!memref_gmem_bf16_6) -> !cute.int_tuple<"1">
      %e0_441 = cute.get_leaves(%sz_440) : !cute.int_tuple<"1">
      %sz_442 = cute.size(%grouped_414) <{mode = [1]}> : (!memref_rmem_bf16_1) -> !cute.int_tuple<"1">
      %e0_443 = cute.get_leaves(%sz_442) : !cute.int_tuple<"1">
      cute.copy(%atom_75, %grouped, %grouped_414, %grouped_427) : (!cute_nvgpu.atom.universal_copy<bf16, 128 b>, !memref_gmem_bf16_6, !memref_rmem_bf16_1, !memref_rmem_i8_1)
      nvvm.cp.async.wait.group 0
      %lay_444 = cute.get_layout(%dst_partitioned) : !memref_smem_bf16_1
      %179 = cute.get_shape(%lay_444) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %e0_445, %e1_446, %e2_447, %e3_448 = cute.get_leaves(%179) : !cute.shape<"((8,8),1,1)">
      %lay_449 = cute.get_layout(%rmem) : !memref_rmem_bf16_
      %180 = cute.get_shape(%lay_449) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %e0_450, %e1_451, %e2_452, %e3_453 = cute.get_leaves(%180) : !cute.shape<"((8,8),1,1)">
      %lay_454 = cute.get_layout(%dst_partitioned) : !memref_smem_bf16_1
      %lay_455 = cute.get_layout(%rmem) : !memref_rmem_bf16_
      %rinv = cute.right_inverse(%lay_455) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.layout<"64:1">
      %181 = cute.composition(%lay_454, %rinv) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">, !cute.layout<"64:1">) -> !cute.layout<"(8,8):(1,512)">
      %coalesce = cute.coalesce(%181) : (!cute.layout<"(8,8):(1,512)">) -> !cute.layout<"(8,8):(1,512)">
      %182 = cute.get_shape(%coalesce) : (!cute.layout<"(8,8):(1,512)">) -> !cute.shape<"(8,8)">
      %e0_456, %e1_457 = cute.get_leaves(%182) : !cute.shape<"(8,8)">
      %183 = cute.get_stride(%coalesce) : (!cute.layout<"(8,8):(1,512)">) -> !cute.stride<"(1,512)">
      %e0_458, %e1_459 = cute.get_leaves(%183) : !cute.stride<"(1,512)">
      %184 = cute.get_shape(%coalesce) : (!cute.layout<"(8,8):(1,512)">) -> !cute.shape<"(8,8)">
      %e0_460, %e1_461 = cute.get_leaves(%184) : !cute.shape<"(8,8)">
      %185 = cute.get_shape(%coalesce) : (!cute.layout<"(8,8):(1,512)">) -> !cute.shape<"(8,8)">
      %e0_462, %e1_463 = cute.get_leaves(%185) : !cute.shape<"(8,8)">
      %186 = cute.get(%coalesce) <{mode = [0]}> : !cute.layout<"(8,8):(1,512)"> -> !cute.layout<"8:1">
      %187 = cute.composition(%rinv, %186) : (!cute.layout<"64:1">, !cute.layout<"8:1">) -> !cute.layout<"8:1">
      %sz_464 = cute.size(%187) : (!cute.layout<"8:1">) -> !cute.int_tuple<"8">
      %e0_465 = cute.get_leaves(%sz_464) : !cute.int_tuple<"8">
      %lay_466 = cute.get_layout(%dst_partitioned) : !memref_smem_bf16_1
      %lay_467 = cute.get_layout(%rmem) : !memref_rmem_bf16_
      %div = cute.logical_divide(%dst_partitioned, %187) : !memref_smem_bf16_1, !cute.layout<"8:1">
      %iter_468 = cute.get_iter(%div) : !memref_smem_bf16_3
      %iter_469 = cute.get_iter(%div) : !memref_smem_bf16_3
      %div_470 = cute.logical_divide(%rmem, %187) : !memref_rmem_bf16_, !cute.layout<"8:1">
      %iter_471 = cute.get_iter(%div_470) : !memref_rmem_bf16_2
      %iter_472 = cute.get_iter(%div_470) : !memref_rmem_bf16_2
      %shape_473 = cute.make_shape() : () -> !cute.shape<"8">
      %lay_474 = cute.make_layout(%shape_473) : !cute.layout<"8:1">
      %div_475 = cute.logical_divide(%div, %lay_474) : !memref_smem_bf16_3, !cute.layout<"8:1">
      %iter_476 = cute.get_iter(%div_475) : !memref_smem_bf16_3
      %iter_477 = cute.get_iter(%div_475) : !memref_smem_bf16_3
      %shape_478 = cute.make_shape() : () -> !cute.shape<"8">
      %lay_479 = cute.make_layout(%shape_478) : !cute.layout<"8:1">
      %div_480 = cute.logical_divide(%div_470, %lay_479) : !memref_rmem_bf16_2, !cute.layout<"8:1">
      %iter_481 = cute.get_iter(%div_480) : !memref_rmem_bf16_2
      %iter_482 = cute.get_iter(%div_480) : !memref_rmem_bf16_2
      %atom_483 = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<bf16, 128 b>
      cute.copy(%atom_483, %div_475, %div_480) : (!cute_nvgpu.atom.universal_copy<bf16, 128 b>, !memref_smem_bf16_3, !memref_rmem_bf16_2)
      %188 = cute.memref.load_vec %rmem : !memref_rmem_bf16_
      %189 = arith.extf %188 : vector<64xbf16> to vector<64xf32>
      %190 = arith.mulf %189, %189 : vector<64xf32>
      %cst = arith.constant 0.000000e+00 : f32
      %191 = vector.reduction <add>, %190, %cst : vector<64xf32> into f32
      %c-1_i32 = arith.constant -1 : i32
      %c16_i32 = arith.constant 16 : i32
      %c31_i32 = arith.constant 31 : i32
      %192 = nvvm.shfl.sync  bfly %c-1_i32, %191, %c16_i32, %c31_i32 : f32 -> f32
      %193 = arith.addf %192, %191 : f32
      %c8_i32 = arith.constant 8 : i32
      %194 = nvvm.shfl.sync  bfly %c-1_i32, %193, %c8_i32, %c31_i32 : f32 -> f32
      %195 = arith.addf %193, %194 : f32
      %c4_i32 = arith.constant 4 : i32
      %196 = nvvm.shfl.sync  bfly %c-1_i32, %195, %c4_i32, %c31_i32 : f32 -> f32
      %197 = arith.addf %195, %196 : f32
      %c2_i32 = arith.constant 2 : i32
      %198 = nvvm.shfl.sync  bfly %c-1_i32, %197, %c2_i32, %c31_i32 : f32 -> f32
      %199 = arith.addf %197, %198 : f32
      %c1_i32 = arith.constant 1 : i32
      %200 = nvvm.shfl.sync  bfly %c-1_i32, %199, %c1_i32, %c31_i32 : f32 -> f32
      %201 = arith.addf %199, %200 : f32
      %202 = nvvm.read.ptx.sreg.laneid : i32
      %203 = nvvm.read.ptx.sreg.tid.x : i32
      %204 = nvvm.read.ptx.sreg.tid.y : i32
      %205 = nvvm.read.ptx.sreg.tid.z : i32
      %206 = nvvm.read.ptx.sreg.ntid.x : i32
      %207 = nvvm.read.ptx.sreg.ntid.y : i32
      %208 = arith.muli %204, %206 : i32
      %209 = arith.addi %203, %208 : i32
      %210 = arith.muli %205, %206 : i32
      %211 = arith.muli %210, %207 : i32
      %212 = arith.addi %209, %211 : i32
      %c32_i32 = arith.constant 32 : i32
      %213 = arith.floordivsi %212, %c32_i32 : i32
      %lay_484 = cute.get_layout(%view_47) : !memref_smem_f32_
      %214 = cute.get_shape(%lay_484) : (!cute.layout<"(2,2):(1,2)">) -> !cute.shape<"(2,2)">
      %e0_485, %e1_486 = cute.get_leaves(%214) : !cute.shape<"(2,2)">
      %int_tuple_487 = cute.make_int_tuple() : () -> !cute.int_tuple<"2">
      %sz_488 = cute.size(%int_tuple_487) : (!cute.int_tuple<"2">) -> !cute.int_tuple<"2">
      %e0_489 = cute.get_leaves(%sz_488) : !cute.int_tuple<"2">
      %c2_i32_490 = arith.constant 2 : i32
      %215 = arith.floordivsi %213, %c2_i32_490 : i32
      %216 = arith.remsi %213, %c2_i32_490 : i32
      %c0_i32 = arith.constant 0 : i32
      %217 = arith.cmpi eq, %202, %c0_i32 : i32
      %218 = scf.if %217 -> (!memref_smem_f32_) {
        %iter_552 = cute.get_iter(%view_47) : !memref_smem_f32_
        %coord_553 = cute.make_coord(%215, %216) : (i32, i32) -> !cute.coord<"(?,?)">
        cute.memref.store(%view_47, %coord_553, %201) : (!memref_smem_f32_, !cute.coord<"(?,?)">, f32) -> ()
        scf.yield %view_47 : !memref_smem_f32_
      } else {
        %iter_552 = cute.get_iter(%view_47) : !memref_smem_f32_
        scf.yield %view_47 : !memref_smem_f32_
      }
      %iter_491 = cute.get_iter(%218) : !memref_smem_f32_
      %iter_492 = cute.get_iter(%218) : !memref_smem_f32_
      %iter_493 = cute.get_iter(%218) : !memref_smem_f32_
      nvvm.barrier
      %219 = arith.cmpi slt, %202, %c2_i32_490 : i32
      %cst_494 = arith.constant 0.000000e+00 : f32
      %220 = scf.if %219 -> (f32) {
        %coord_552 = cute.make_coord(%215, %202) : (i32, i32) -> !cute.coord<"(?,?)">
        %251 = cute.memref.load(%218, %coord_552) : (!memref_smem_f32_, !cute.coord<"(?,?)">) -> f32
        scf.yield %251 : f32
      } else {
        scf.yield %cst_494 : f32
      }
      %c-1_i32_495 = arith.constant -1 : i32
      %c16_i32_496 = arith.constant 16 : i32
      %c31_i32_497 = arith.constant 31 : i32
      %221 = nvvm.shfl.sync  bfly %c-1_i32_495, %220, %c16_i32_496, %c31_i32_497 : f32 -> f32
      %222 = arith.addf %220, %221 : f32
      %c8_i32_498 = arith.constant 8 : i32
      %223 = nvvm.shfl.sync  bfly %c-1_i32_495, %222, %c8_i32_498, %c31_i32_497 : f32 -> f32
      %224 = arith.addf %222, %223 : f32
      %c4_i32_499 = arith.constant 4 : i32
      %225 = nvvm.shfl.sync  bfly %c-1_i32_495, %224, %c4_i32_499, %c31_i32_497 : f32 -> f32
      %226 = arith.addf %224, %225 : f32
      %c2_i32_500 = arith.constant 2 : i32
      %227 = nvvm.shfl.sync  bfly %c-1_i32_495, %226, %c2_i32_500, %c31_i32_497 : f32 -> f32
      %228 = arith.addf %226, %227 : f32
      %c1_i32_501 = arith.constant 1 : i32
      %229 = nvvm.shfl.sync  bfly %c-1_i32_495, %228, %c1_i32_501, %c31_i32_497 : f32 -> f32
      %230 = arith.addf %228, %229 : f32
      %cst_502 = arith.constant 4.096000e+03 : f32
      %231 = arith.divf %230, %cst_502 : f32
      %232 = arith.addf %231, %arg3 : f32
      %233 = math.rsqrt %232 fastmath<fast> : f32
      nvvm.barrier
      %lay_503 = cute.get_layout(%dst_partitioned) : !memref_smem_bf16_1
      %lay_504 = cute.get_layout(%rmem) : !memref_rmem_bf16_
      %rinv_505 = cute.right_inverse(%lay_504) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.layout<"64:1">
      %234 = cute.composition(%lay_503, %rinv_505) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">, !cute.layout<"64:1">) -> !cute.layout<"(8,8):(1,512)">
      %coalesce_506 = cute.coalesce(%234) : (!cute.layout<"(8,8):(1,512)">) -> !cute.layout<"(8,8):(1,512)">
      %235 = cute.get_shape(%coalesce_506) : (!cute.layout<"(8,8):(1,512)">) -> !cute.shape<"(8,8)">
      %e0_507, %e1_508 = cute.get_leaves(%235) : !cute.shape<"(8,8)">
      %236 = cute.get_stride(%coalesce_506) : (!cute.layout<"(8,8):(1,512)">) -> !cute.stride<"(1,512)">
      %e0_509, %e1_510 = cute.get_leaves(%236) : !cute.stride<"(1,512)">
      %237 = cute.get_shape(%coalesce_506) : (!cute.layout<"(8,8):(1,512)">) -> !cute.shape<"(8,8)">
      %e0_511, %e1_512 = cute.get_leaves(%237) : !cute.shape<"(8,8)">
      %238 = cute.get_shape(%coalesce_506) : (!cute.layout<"(8,8):(1,512)">) -> !cute.shape<"(8,8)">
      %e0_513, %e1_514 = cute.get_leaves(%238) : !cute.shape<"(8,8)">
      %239 = cute.get(%coalesce_506) <{mode = [0]}> : !cute.layout<"(8,8):(1,512)"> -> !cute.layout<"8:1">
      %240 = cute.composition(%rinv_505, %239) : (!cute.layout<"64:1">, !cute.layout<"8:1">) -> !cute.layout<"8:1">
      %sz_515 = cute.size(%240) : (!cute.layout<"8:1">) -> !cute.int_tuple<"8">
      %e0_516 = cute.get_leaves(%sz_515) : !cute.int_tuple<"8">
      %lay_517 = cute.get_layout(%dst_partitioned) : !memref_smem_bf16_1
      %lay_518 = cute.get_layout(%rmem) : !memref_rmem_bf16_
      %div_519 = cute.logical_divide(%dst_partitioned, %240) : !memref_smem_bf16_1, !cute.layout<"8:1">
      %iter_520 = cute.get_iter(%div_519) : !memref_smem_bf16_3
      %iter_521 = cute.get_iter(%div_519) : !memref_smem_bf16_3
      %div_522 = cute.logical_divide(%rmem, %240) : !memref_rmem_bf16_, !cute.layout<"8:1">
      %iter_523 = cute.get_iter(%div_522) : !memref_rmem_bf16_2
      %iter_524 = cute.get_iter(%div_522) : !memref_rmem_bf16_2
      %shape_525 = cute.make_shape() : () -> !cute.shape<"8">
      %lay_526 = cute.make_layout(%shape_525) : !cute.layout<"8:1">
      %div_527 = cute.logical_divide(%div_519, %lay_526) : !memref_smem_bf16_3, !cute.layout<"8:1">
      %iter_528 = cute.get_iter(%div_527) : !memref_smem_bf16_3
      %iter_529 = cute.get_iter(%div_527) : !memref_smem_bf16_3
      %shape_530 = cute.make_shape() : () -> !cute.shape<"8">
      %lay_531 = cute.make_layout(%shape_530) : !cute.layout<"8:1">
      %div_532 = cute.logical_divide(%div_522, %lay_531) : !memref_rmem_bf16_2, !cute.layout<"8:1">
      %iter_533 = cute.get_iter(%div_532) : !memref_rmem_bf16_2
      %iter_534 = cute.get_iter(%div_532) : !memref_rmem_bf16_2
      %atom_535 = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<bf16, 128 b>
      cute.copy(%atom_535, %div_527, %div_532) : (!cute_nvgpu.atom.universal_copy<bf16, 128 b>, !memref_smem_bf16_3, !memref_rmem_bf16_2)
      %241 = cute.memref.load_vec %rmem : !memref_rmem_bf16_
      %242 = arith.extf %241 : vector<64xbf16> to vector<64xf32>
      %243 = vector.broadcast %233 : f32 to vector<64xf32>
      %244 = arith.mulf %242, %243 : vector<64xf32>
      %lay_536 = cute.get_layout(%retiled) : !memref_rmem_bf16_
      %245 = cute.get_shape(%lay_536) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %e0_537, %e1_538, %e2_539, %e3_540 = cute.get_leaves(%245) : !cute.shape<"((8,8),1,1)">
      %246 = cute.memref.load_vec %retiled : !memref_rmem_bf16_
      %247 = arith.extf %246 : vector<64xbf16> to vector<64xf32>
      %248 = arith.mulf %244, %247 : vector<64xf32>
      %249 = arith.truncf %248 : vector<64xf32> to vector<64xbf16>
      %lay_541 = cute.get_layout(%rmem_96) : !memref_rmem_bf16_
      %250 = cute.get_shape(%lay_541) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %e0_542, %e1_543, %e2_544, %e3_545 = cute.get_leaves(%250) : !cute.shape<"((8,8),1,1)">
      %int_tuple_546 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,8),1,1)">
      %sz_547 = cute.size(%int_tuple_546) : (!cute.int_tuple<"((8,8),1,1)">) -> !cute.int_tuple<"64">
      %e0_548 = cute.get_leaves(%sz_547) : !cute.int_tuple<"64">
      %int_tuple_549 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,8),1,1)">
      %sz_550 = cute.size(%int_tuple_549) : (!cute.int_tuple<"((8,8),1,1)">) -> !cute.int_tuple<"64">
      %e0_551 = cute.get_leaves(%sz_550) : !cute.int_tuple<"64">
      cute.memref.store_vec %249, %rmem_96 : !memref_rmem_bf16_
      scf.if %104 {
        %lay_552 = cute.get_layout(%rmem_96) : !memref_rmem_bf16_
        %251 = cute.get_shape(%lay_552) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %e0_553, %e1_554, %e2_555, %e3_556 = cute.get_leaves(%251) : !cute.shape<"((8,8),1,1)">
        %lay_557 = cute.get_layout(%dst_partitioned_85) : !memref_gmem_bf16_5
        %252 = cute.get_shape(%lay_557) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %e0_558, %e1_559, %e2_560, %e3_561 = cute.get_leaves(%252) : !cute.shape<"((8,8),1,1)">
        %lay_562 = cute.get_layout(%rmem_96) : !memref_rmem_bf16_
        %shape_563 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_564 = cute.make_layout(%shape_563) : !cute.layout<"1:0">
        %append_565 = cute.append_to_rank<2> (%lay_562, %lay_564) : !cute.layout<"((8,8),1,1):((1,8),0,0)">, !cute.layout<"1:0">
        %view_566 = cute.make_view(%iter_98, %append_565) : !memref_rmem_bf16_
        %iter_567 = cute.get_iter(%view_566) : !memref_rmem_bf16_
        %lay_568 = cute.get_layout(%view_566) : !memref_rmem_bf16_
        %253 = cute.get_shape(%lay_568) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %e0_569, %e1_570, %e2_571, %e3_572 = cute.get_leaves(%253) : !cute.shape<"((8,8),1,1)">
        %grouped_573 = cute.group_modes(%view_566) <1, 3> : (!memref_rmem_bf16_) -> !memref_rmem_bf16_1
        %iter_574 = cute.get_iter(%grouped_573) : !memref_rmem_bf16_1
        %iter_575 = cute.get_iter(%grouped_573) : !memref_rmem_bf16_1
        %lay_576 = cute.get_layout(%dst_partitioned_85) : !memref_gmem_bf16_5
        %shape_577 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_578 = cute.make_layout(%shape_577) : !cute.layout<"1:0">
        %append_579 = cute.append_to_rank<2> (%lay_576, %lay_578) : !cute.layout<"((8,8),1,1):((1,512),0,0)">, !cute.layout<"1:0">
        %view_580 = cute.make_view(%iter_86, %append_579) : !memref_gmem_bf16_5
        %iter_581 = cute.get_iter(%view_580) : !memref_gmem_bf16_5
        %lay_582 = cute.get_layout(%view_580) : !memref_gmem_bf16_5
        %254 = cute.get_shape(%lay_582) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %e0_583, %e1_584, %e2_585, %e3_586 = cute.get_leaves(%254) : !cute.shape<"((8,8),1,1)">
        %grouped_587 = cute.group_modes(%view_580) <1, 3> : (!memref_gmem_bf16_5) -> !memref_gmem_bf16_6
        %iter_588 = cute.get_iter(%grouped_587) : !memref_gmem_bf16_6
        %iter_589 = cute.get_iter(%grouped_587) : !memref_gmem_bf16_6
        %lay_590 = cute.get_layout(%rmem_117) : !memref_rmem_i8_
        %shape_591 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_592 = cute.make_layout(%shape_591) : !cute.layout<"1:0">
        %append_593 = cute.append_to_rank<2> (%lay_590, %lay_592) : !cute.layout<"(8,1,1):(1,0,1)">, !cute.layout<"1:0">
        %view_594 = cute.make_view(%iter_119, %append_593) : !memref_rmem_i8_
        %iter_595 = cute.get_iter(%view_594) : !memref_rmem_i8_
        %lay_596 = cute.get_layout(%view_594) : !memref_rmem_i8_
        %255 = cute.get_shape(%lay_596) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
        %e0_597, %e1_598, %e2_599 = cute.get_leaves(%255) : !cute.shape<"(8,1,1)">
        %grouped_600 = cute.group_modes(%view_594) <1, 3> : (!memref_rmem_i8_) -> !memref_rmem_i8_1
        %iter_601 = cute.get_iter(%grouped_600) : !memref_rmem_i8_1
        %iter_602 = cute.get_iter(%grouped_600) : !memref_rmem_i8_1
        %lay_603 = cute.get_layout(%grouped_573) : !memref_rmem_bf16_1
        %256 = cute.get_shape(%lay_603) : (!cute.layout<"((8,8),(1,1)):((1,8),(0,0))">) -> !cute.shape<"((8,8),(1,1))">
        %e0_604, %e1_605, %e2_606, %e3_607 = cute.get_leaves(%256) : !cute.shape<"((8,8),(1,1))">
        %lay_608 = cute.get_layout(%grouped_587) : !memref_gmem_bf16_6
        %257 = cute.get_shape(%lay_608) : (!cute.layout<"((8,8),(1,1)):((1,512),(0,0))">) -> !cute.shape<"((8,8),(1,1))">
        %e0_609, %e1_610, %e2_611, %e3_612 = cute.get_leaves(%257) : !cute.shape<"((8,8),(1,1))">
        %sz_613 = cute.size(%grouped_573) <{mode = [1]}> : (!memref_rmem_bf16_1) -> !cute.int_tuple<"1">
        %e0_614 = cute.get_leaves(%sz_613) : !cute.int_tuple<"1">
        %sz_615 = cute.size(%grouped_587) <{mode = [1]}> : (!memref_gmem_bf16_6) -> !cute.int_tuple<"1">
        %e0_616 = cute.get_leaves(%sz_615) : !cute.int_tuple<"1">
        cute.copy(%atom_76, %grouped_573, %grouped_587, %grouped_600) : (!cute_nvgpu.atom.universal_copy<bf16, 128 b>, !memref_rmem_bf16_1, !memref_gmem_bf16_6, !memref_rmem_i8_1)
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
    %lay_7 = cute.make_layout(%shape_5, %stride_6) : !cute.layout<"(4096):(1)">
    %view_8 = cute.make_view(%arg1, %lay_7) : !memref_gmem_bf16_1
    %iter_9 = cute.get_iter(%view_8) : !memref_gmem_bf16_1
    %shape_10 = cute.make_shape() : () -> !cute.shape<"((64,2),(8,8))">
    %stride_11 = cute.make_stride() : () -> !cute.stride<"((16,1),(2,1024))">
    %lay_12 = cute.make_layout(%shape_10, %stride_11) : !cute.layout<"((64,2),(8,8)):((16,1),(2,1024))">
    %int_tuple = cute.make_int_tuple(%arg3) : (i32) -> !cute.int_tuple<"?">
    %tile = cute.make_tile() : () -> !cute.tile<"2:1">
    %shp = cute.ceil_div(%int_tuple, %tile) : !cute.int_tuple<"?">, !cute.tile<"2:1">
    %e0 = cute.get_leaves(%shp) : !cute.int_tuple<"?">
    %0 = cute.get_scalars(%e0) : !cute.int_tuple<"?">
    %lay_13 = cute.get_layout(%view) : !memref_gmem_bf16_
    %1 = cute.get_shape(%lay_13) : (!cute.layout<"(?,4096):(4096,1)">) -> !cute.shape<"(?,4096)">
    %e0_14, %e1 = cute.get_leaves(%1) : !cute.shape<"(?,4096)">
    %itup = cute.to_int_tuple(%e0_14) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %2 = cute.get_scalars(%itup) : !cute.int_tuple<"?">
    %3 = cute.get_stride(%lay_13) : (!cute.layout<"(?,4096):(4096,1)">) -> !cute.stride<"(4096,1)">
    %e0_15, %e1_16 = cute.get_leaves(%3) : !cute.stride<"(4096,1)">
    %lay_17 = cute.get_layout(%view_8) : !memref_gmem_bf16_1
    %4 = cute.get_shape(%lay_17) : (!cute.layout<"(4096):(1)">) -> !cute.shape<"(4096)">
    %e0_18 = cute.get_leaves(%4) : !cute.shape<"(4096)">
    %5 = cute.get_stride(%lay_17) : (!cute.layout<"(4096):(1)">) -> !cute.stride<"(1)">
    %e0_19 = cute.get_leaves(%5) : !cute.stride<"(1)">
    %lay_20 = cute.get_layout(%view_3) : !memref_gmem_bf16_
    %6 = cute.get_shape(%lay_20) : (!cute.layout<"(?,4096):(4096,1)">) -> !cute.shape<"(?,4096)">
    %e0_21, %e1_22 = cute.get_leaves(%6) : !cute.shape<"(?,4096)">
    %itup_23 = cute.to_int_tuple(%e0_21) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %7 = cute.get_scalars(%itup_23) : !cute.int_tuple<"?">
    %8 = cute.get_stride(%lay_20) : (!cute.layout<"(?,4096):(4096,1)">) -> !cute.stride<"(4096,1)">
    %e0_24, %e1_25 = cute.get_leaves(%8) : !cute.stride<"(4096,1)">
    %9 = cute.get_shape(%lay_12) : (!cute.layout<"((64,2),(8,8)):((16,1),(2,1024))">) -> !cute.shape<"((64,2),(8,8))">
    %e0_26, %e1_27, %e2, %e3 = cute.get_leaves(%9) : !cute.shape<"((64,2),(8,8))">
    %10 = cute.get_stride(%lay_12) : (!cute.layout<"((64,2),(8,8)):((16,1),(2,1024))">) -> !cute.stride<"((16,1),(2,1024))">
    %e0_28, %e1_29, %e2_30, %e3_31 = cute.get_leaves(%10) : !cute.stride<"((16,1),(2,1024))">
    %c16400_i32 = arith.constant 16400 : i32
    %11 = arith.extsi %c16400_i32 : i32 to i64
    %c128_i32 = arith.constant 128 : i32
    %c1_i32 = arith.constant 1 : i32
    %12 = cuda.launch_cfg.create<max_attrs = 2 : i32> (blockDim = (%c128_i32, %c1_i32, %c1_i32), dynamicSmemBytes = %11, gridDim = (%0, %c1_i32, %c1_i32), stream = %arg5) : i32, i32, i32, i64, i32, i32, i32, !cuda.stream -> !cuda.launch_cfg<max_attrs = 2>
    %13 = cuda.launch_ex @kernels::@kernel_cutlass_kernel___main__RMSNormKernel_object_at__tensorptrbf16gmemalign16o409640961_tensorptrbf16_gmem_align16_o_40961_tensorptrbf16gmemalign16o409640961__2_4096_0<%12> (%view, %view_8, %view_3, %arg4) : !cuda.launch_cfg<max_attrs = 2>, (!memref_gmem_bf16_, !memref_gmem_bf16_1, !memref_gmem_bf16_, f32) -> !cuda.result
    %14 = cuda.cast %13 : !cuda.result -> i32
    cuda.return_if_error %14 : i32
    %c0_i32 = arith.constant 0 : i32
    return %c0_i32 : i32
  }
}
