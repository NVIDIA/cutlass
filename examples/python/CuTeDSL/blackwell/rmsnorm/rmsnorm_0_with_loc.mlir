

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
    cuda.kernel @kernel_cutlass_kernel___main__RMSNormKernel_object_at__tensorptrbf16gmemalign16o409640961_tensorptrbf16_gmem_align16_o_40961_tensorptrbf16gmemalign16o409640961__2_4096_0(%arg0: !memref_gmem_bf16_, %arg1: !memref_gmem_bf16_1, %arg2: !memref_gmem_bf16_, %arg3: f32, %arg4: !cute.layout<"((64,2),(8,8)):((16,1),(2,1024))">) attributes {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} {
      %iter = cute.get_iter(%arg0) : !memref_gmem_bf16_
      %iter_0 = cute.get_iter(%arg1) : !memref_gmem_bf16_1
      %iter_1 = cute.get_iter(%arg2) : !memref_gmem_bf16_
      %iter_2 = cute.get_iter(%arg0) : !memref_gmem_bf16_
      %iter_3 = cute.get_iter(%arg1) : !memref_gmem_bf16_1
      %iter_4 = cute.get_iter(%arg2) : !memref_gmem_bf16_
      %lay = cute.get_layout(%arg0) : !memref_gmem_bf16_
      %lay_5 = cute.get_layout(%arg1) : !memref_gmem_bf16_1
      %lay_6 = cute.get_layout(%arg2) : !memref_gmem_bf16_
      %lay_7 = cute.get_layout(%arg0) : !memref_gmem_bf16_
      %lay_8 = cute.get_layout(%arg1) : !memref_gmem_bf16_1
      %lay_9 = cute.get_layout(%arg2) : !memref_gmem_bf16_
      %0 = nvvm.read.ptx.sreg.tid.x : i32
      %1 = nvvm.read.ptx.sreg.tid.y : i32
      %2 = nvvm.read.ptx.sreg.tid.z : i32
      %3 = nvvm.read.ptx.sreg.ctaid.x : i32
      %4 = nvvm.read.ptx.sreg.ctaid.y : i32
      %5 = nvvm.read.ptx.sreg.ctaid.z : i32
      %lay_10 = cute.get_layout(%arg0) : !memref_gmem_bf16_
      %6 = cute.get_shape(%lay_10) : (!cute.layout<"(?,4096):(4096,1)">) -> !cute.shape<"(?,4096)">
      %e0, %e1 = cute.get_leaves(%6) : !cute.shape<"(?,4096)">
      %itup = cute.to_int_tuple(%e0) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %7 = cute.get_scalars(%itup) : !cute.int_tuple<"?">
      %8 = cute.get_shape(%arg4) : (!cute.layout<"((64,2),(8,8)):((16,1),(2,1024))">) -> !cute.shape<"((64,2),(8,8))">
      %e0_11, %e1_12, %e2, %e3 = cute.get_leaves(%8) : !cute.shape<"((64,2),(8,8))">
      %smem_ptr = cute_nvgpu.arch.get_dyn_smem() : !cute.ptr<i8, smem, align<1024>>
      %shape = cute.make_shape() : () -> !cute.shape<"(2,4096)">
      %int_tuple = cute.make_int_tuple() : () -> !cute.int_tuple<"(1,0)">
      %lay_13 = cute.make_ordered_layout(%shape, %int_tuple) : (!cute.shape<"(2,4096)">, !cute.int_tuple<"(1,0)">) -> !cute.layout<"(2,4096):(4096,1)">
      %coord = cute.make_coord() : () -> !cute.coord<"0">
      %idx = cute.crd2idx(%coord, %lay_13) : (!cute.coord<"0">, !cute.layout<"(2,4096):(4096,1)">) -> !cute.int_tuple<"0">
      %e0_14 = cute.get_leaves(%idx) : !cute.int_tuple<"0">
      %cosz = cute.cosize(%lay_13) : (!cute.layout<"(2,4096):(4096,1)">) -> !cute.int_tuple<"8192">
      %e0_15 = cute.get_leaves(%cosz) : !cute.int_tuple<"8192">
      %int_tuple_16 = cute.make_int_tuple() : () -> !cute.int_tuple<"16384">
      %ptr = cute.add_offset(%smem_ptr, %int_tuple_16) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"16384">) -> !cute.ptr<i8, smem, align<1024>>
      %smem_size = cute_nvgpu.arch.get_dyn_smem_size() : i32
      %c16384_i32 = arith.constant 16384 : i32
      %9 = arith.cmpi sge, %smem_size, %c16384_i32 : i32
      cf.assert %9, "Allocation failed: shared memory allocation exceeds available memory set in kernel launch. Allocated bytes: 16384 bytes. Please reduce the allocation or set a larger smem size in kernel launch."
      %iter_17 = cute.recast_iter(%smem_ptr) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<bf16, smem, align<1024>>
      %view = cute.make_view(%iter_17, %lay_13) : !memref_smem_bf16_
      %iter_18 = cute.get_iter(%view) : !memref_smem_bf16_
      %shape_19 = cute.make_shape() : () -> !cute.shape<"(2,2)">
      %lay_20 = cute.make_layout(%shape_19) : !cute.layout<"(2,2):(1,2)">
      %coord_21 = cute.make_coord() : () -> !cute.coord<"0">
      %idx_22 = cute.crd2idx(%coord_21, %lay_20) : (!cute.coord<"0">, !cute.layout<"(2,2):(1,2)">) -> !cute.int_tuple<"0">
      %e0_23 = cute.get_leaves(%idx_22) : !cute.int_tuple<"0">
      %cosz_24 = cute.cosize(%lay_20) : (!cute.layout<"(2,2):(1,2)">) -> !cute.int_tuple<"4">
      %e0_25 = cute.get_leaves(%cosz_24) : !cute.int_tuple<"4">
      %int_tuple_26 = cute.make_int_tuple() : () -> !cute.int_tuple<"16">
      %ptr_27 = cute.add_offset(%ptr, %int_tuple_26) : (!cute.ptr<i8, smem, align<1024>>, !cute.int_tuple<"16">) -> !cute.ptr<i8, smem, align<16>>
      %smem_size_28 = cute_nvgpu.arch.get_dyn_smem_size() : i32
      %c16400_i32 = arith.constant 16400 : i32
      %10 = arith.cmpi sge, %smem_size_28, %c16400_i32 : i32
      cf.assert %10, "Allocation failed: shared memory allocation exceeds available memory set in kernel launch. Allocated bytes: 16400 bytes. Please reduce the allocation or set a larger smem size in kernel launch."
      %iter_29 = cute.recast_iter(%ptr) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<f32, smem, align<1024>>
      %view_30 = cute.make_view(%iter_29, %lay_20) : !memref_smem_f32_
      %iter_31 = cute.get_iter(%view_30) : !memref_smem_f32_
      %lay_32 = cute.get_layout(%arg0) : !memref_gmem_bf16_
      %11 = cute.get_shape(%lay_32) : (!cute.layout<"(?,4096):(4096,1)">) -> !cute.shape<"(?,4096)">
      %e0_33, %e1_34 = cute.get_leaves(%11) : !cute.shape<"(?,4096)">
      %itup_35 = cute.to_int_tuple(%e0_33) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %12 = cute.get_scalars(%itup_35) : !cute.int_tuple<"?">
      %shape_36 = cute.make_shape(%itup_35) : (!cute.int_tuple<"?">) -> !cute.shape<"(?,4096)">
      %13 = cute.make_identity_tensor(%shape_36) : !cute.coord_tensor<"(0,0)", "(?,4096):(1@0,1@1)">
      %iter_37 = cute.get_iter(%13) : !cute.coord_tensor<"(0,0)", "(?,4096):(1@0,1@1)">
      %tup = cute.deref_arith_tuple_iter(%iter_37) : !cute.arith_tuple_iter<"(0,0)">
      %e0_38, %e1_39 = cute.get_leaves(%tup) : !cute.int_tuple<"(0,0)">
      %tile = cute.make_tile() : () -> !cute.tile<"[2:1;4096:1]">
      %coord_40 = cute.make_coord(%3) : (i32) -> !cute.coord<"(?,0)">
      %tiled_view = cute.local_tile(%arg0, %tile, %coord_40) : (!memref_gmem_bf16_, !cute.tile<"[2:1;4096:1]">, !cute.coord<"(?,0)">) -> !memref_gmem_bf16_2
      %iter_41 = cute.get_iter(%tiled_view) : !memref_gmem_bf16_2
      %tile_42 = cute.make_tile() : () -> !cute.tile<"[2:1;4096:1]">
      %coord_43 = cute.make_coord(%3) : (i32) -> !cute.coord<"(?,0)">
      %tiled_view_44 = cute.local_tile(%arg2, %tile_42, %coord_43) : (!memref_gmem_bf16_, !cute.tile<"[2:1;4096:1]">, !cute.coord<"(?,0)">) -> !memref_gmem_bf16_2
      %iter_45 = cute.get_iter(%tiled_view_44) : !memref_gmem_bf16_2
      %tile_46 = cute.make_tile() : () -> !cute.tile<"[2:1;4096:1]">
      %coord_47 = cute.make_coord(%3) : (i32) -> !cute.coord<"(?,0)">
      %tiled_view_48 = cute.local_tile(%13, %tile_46, %coord_47) : (!cute.coord_tensor<"(0,0)", "(?,4096):(1@0,1@1)">, !cute.tile<"[2:1;4096:1]">, !cute.coord<"(?,0)">) -> !cute.coord_tensor<"(?{div=2},0)", "(2,4096):(1@0,1@1)">
      %iter_49 = cute.get_iter(%tiled_view_48) : !cute.coord_tensor<"(?{div=2},0)", "(2,4096):(1@0,1@1)">
      %tup_50 = cute.deref_arith_tuple_iter(%iter_49) : !cute.arith_tuple_iter<"(?{div=2},0)">
      %e0_51, %e1_52 = cute.get_leaves(%tup_50) : !cute.int_tuple<"(?{div=2},0)">
      %14 = cute.get_scalars(%e0_51) : !cute.int_tuple<"?{div=2}">
      %lay_53 = cute.get_layout(%arg1) : !memref_gmem_bf16_1
      %shape_54 = cute.make_shape() : () -> !cute.shape<"(2)">
      %stride = cute.make_stride() : () -> !cute.stride<"(0)">
      %lay_55 = cute.make_layout(%shape_54, %stride) : !cute.layout<"(2):(0)">
      %15 = cute.get_shape(%lay_53) : (!cute.layout<"(4096):(1)">) -> !cute.shape<"(4096)">
      %e0_56 = cute.get_leaves(%15) : !cute.shape<"(4096)">
      %prepend = cute.prepend_to_rank<2> (%lay_53, %lay_55) : !cute.layout<"(4096):(1)">, !cute.layout<"(2):(0)">
      %view_57 = cute.make_view(%iter_3, %prepend) : !memref_gmem_bf16_3
      %iter_58 = cute.get_iter(%view_57) : !memref_gmem_bf16_3
      %tile_59 = cute.make_tile() : () -> !cute.tile<"[2:1;4096:1]">
      %coord_60 = cute.make_coord() : () -> !cute.coord<"(0,0)">
      %tiled_view_61 = cute.local_tile(%view_57, %tile_59, %coord_60) : (!memref_gmem_bf16_3, !cute.tile<"[2:1;4096:1]">, !cute.coord<"(0,0)">) -> !memref_gmem_bf16_4
      %iter_62 = cute.get_iter(%tiled_view_61) : !memref_gmem_bf16_4
      %atom = cute.make_atom() : () -> !cute_nvgpu.atom.simt_async_copy<bf16, cache = always, 128 b>
      %atom_63 = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<bf16, 128 b>
      %atom_64 = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<bf16, 128 b>
      %tile_65 = cute.make_tile() : () -> !cute.tile<"[2:1;4096:1]">
      %16 = cute.make_tiled_copy(%atom) : !copy_ldgsts
      %tile_66 = cute.make_tile() : () -> !cute.tile<"[2:1;4096:1]">
      %17 = cute.make_tiled_copy(%atom_63) : !copy_simt
      %tile_67 = cute.make_tile() : () -> !cute.tile<"[2:1;4096:1]">
      %18 = cute.make_tiled_copy(%atom_64) : !copy_simt
      %coord_68 = cute.make_coord(%0) : (i32) -> !cute.coord<"?">
      %src_partitioned = cute.tiled.copy.partition_S(%16, %tiled_view, %coord_68) : (!copy_ldgsts, !memref_gmem_bf16_2, !cute.coord<"?">) -> !memref_gmem_bf16_5
      %iter_69 = cute.get_iter(%src_partitioned) : !memref_gmem_bf16_5
      %coord_70 = cute.make_coord(%0) : (i32) -> !cute.coord<"?">
      %dst_partitioned = cute.tiled.copy.partition_D(%16, %view, %coord_70) : (!copy_ldgsts, !memref_smem_bf16_, !cute.coord<"?">) -> !memref_smem_bf16_1
      %iter_71 = cute.get_iter(%dst_partitioned) : !memref_smem_bf16_1
      %coord_72 = cute.make_coord(%0) : (i32) -> !cute.coord<"?">
      %dst_partitioned_73 = cute.tiled.copy.partition_D(%18, %tiled_view_44, %coord_72) : (!copy_simt, !memref_gmem_bf16_2, !cute.coord<"?">) -> !memref_gmem_bf16_5
      %iter_74 = cute.get_iter(%dst_partitioned_73) : !memref_gmem_bf16_5
      %coord_75 = cute.make_coord(%0) : (i32) -> !cute.coord<"?">
      %src_partitioned_76 = cute.tiled.copy.partition_S(%16, %tiled_view_48, %coord_75) : (!copy_ldgsts, !cute.coord_tensor<"(?{div=2},0)", "(2,4096):(1@0,1@1)">, !cute.coord<"?">) -> !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %iter_77 = cute.get_iter(%src_partitioned_76) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %tup_78 = cute.deref_arith_tuple_iter(%iter_77) : !cute.arith_tuple_iter<"(?,?{div=8})">
      %e0_79, %e1_80 = cute.get_leaves(%tup_78) : !cute.int_tuple<"(?,?{div=8})">
      %19 = cute.get_scalars(%e0_79) : !cute.int_tuple<"?">
      %20 = cute.get_scalars(%e1_80) : !cute.int_tuple<"?{div=8}">
      %lay_81 = cute.get_layout(%src_partitioned) : !memref_gmem_bf16_5
      %21 = cute.make_layout_like(%lay_81) : !cute.layout<"((8,8),1,1):((1,512),0,0)"> to !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %rmem = cute.memref.alloca(%21) : !memref_rmem_bf16_
      %iter_82 = cute.get_iter(%rmem) : !memref_rmem_bf16_
      %iter_83 = cute.get_iter(%rmem) : !memref_rmem_bf16_
      %lay_84 = cute.get_layout(%dst_partitioned_73) : !memref_gmem_bf16_5
      %22 = cute.make_layout_like(%lay_84) : !cute.layout<"((8,8),1,1):((1,512),0,0)"> to !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %rmem_85 = cute.memref.alloca(%22) : !memref_rmem_bf16_
      %iter_86 = cute.get_iter(%rmem_85) : !memref_rmem_bf16_
      %iter_87 = cute.get_iter(%rmem_85) : !memref_rmem_bf16_
      %coord_88 = cute.make_coord(%0) : (i32) -> !cute.coord<"?">
      %src_partitioned_89 = cute.tiled.copy.partition_S(%17, %tiled_view_61, %coord_88) : (!copy_simt, !memref_gmem_bf16_4, !cute.coord<"?">) -> !memref_gmem_bf16_5
      %iter_90 = cute.get_iter(%src_partitioned_89) : !memref_gmem_bf16_5
      %lay_91 = cute.get_layout(%src_partitioned_89) : !memref_gmem_bf16_5
      %23 = cute.make_layout_like(%lay_91) : !cute.layout<"((8,8),1,1):((1,512),0,0)"> to !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %rmem_92 = cute.memref.alloca(%23) : !memref_rmem_bf16_
      %iter_93 = cute.get_iter(%rmem_92) : !memref_rmem_bf16_
      %iter_94 = cute.get_iter(%rmem_92) : !memref_rmem_bf16_
      %retiled = cute.tiled.copy.retile(%16, %rmem_92) : (!copy_ldgsts, !memref_rmem_bf16_) -> !memref_rmem_bf16_
      %iter_95 = cute.get_iter(%retiled) : !memref_rmem_bf16_
      %sz = cute.size(%src_partitioned_76) <{mode = [0, 1]}> : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"8">
      %e0_96 = cute.get_leaves(%sz) : !cute.int_tuple<"8">
      %sz_97 = cute.size(%src_partitioned_76) <{mode = [1]}> : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"1">
      %e0_98 = cute.get_leaves(%sz_97) : !cute.int_tuple<"1">
      %sz_99 = cute.size(%src_partitioned_76) <{mode = [2]}> : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"1">
      %e0_100 = cute.get_leaves(%sz_99) : !cute.int_tuple<"1">
      %sz_101 = cute.size(%src_partitioned_76) <{mode = [2]}> : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"1">
      %e0_102 = cute.get_leaves(%sz_101) : !cute.int_tuple<"1">
      %shape_103 = cute.make_shape() : () -> !cute.shape<"(8,1,1)">
      %stride_104 = cute.make_stride() : () -> !cute.stride<"(1,0,1)">
      %lay_105 = cute.make_layout(%shape_103, %stride_104) : !cute.layout<"(8,1,1):(1,0,1)">
      %rmem_106 = cute.memref.alloca(%lay_105) : !memref_rmem_i8_
      %iter_107 = cute.get_iter(%rmem_106) : !memref_rmem_i8_
      %iter_108 = cute.get_iter(%rmem_106) : !memref_rmem_i8_
      %lay_109 = cute.get_layout(%rmem_106) : !memref_rmem_i8_
      %24 = cute.get_shape(%lay_109) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %e0_110, %e1_111, %e2_112 = cute.get_leaves(%24) : !cute.shape<"(8,1,1)">
      %lay_113 = cute.get_layout(%rmem_106) : !memref_rmem_i8_
      %25 = cute.get_shape(%lay_113) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %e0_114, %e1_115, %e2_116 = cute.get_leaves(%25) : !cute.shape<"(8,1,1)">
      %coord_117 = cute.make_coord() : () -> !cute.coord<"((0,0),0,0)">
      %slice = cute.slice(%src_partitioned_76, %coord_117) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">, !cute.coord<"((0,0),0,0)">
      %iter_118 = cute.get_iter(%slice) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %tup_119 = cute.deref_arith_tuple_iter(%iter_118) : !cute.arith_tuple_iter<"(?,?{div=8})">
      %e0_120, %e1_121 = cute.get_leaves(%tup_119) : !cute.int_tuple<"(?,?{div=8})">
      %26 = cute.get_scalars(%e0_120) : !cute.int_tuple<"?">
      %27 = cute.get_scalars(%e1_121) : !cute.int_tuple<"?{div=8}">
      %iter_122 = cute.get_iter(%slice) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %tup_123 = cute.deref_arith_tuple_iter(%iter_122) : !cute.arith_tuple_iter<"(?,?{div=8})">
      %e0_124, %e1_125 = cute.get_leaves(%tup_123) : !cute.int_tuple<"(?,?{div=8})">
      %28 = cute.get_scalars(%e0_124) : !cute.int_tuple<"?">
      %29 = cute.get_scalars(%e1_125) : !cute.int_tuple<"?{div=8}">
      %iter_126 = cute.get_iter(%slice) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %tup_127 = cute.deref_arith_tuple_iter(%iter_126) : !cute.arith_tuple_iter<"(?,?{div=8})">
      %e0_128, %e1_129 = cute.get_leaves(%tup_127) : !cute.int_tuple<"(?,?{div=8})">
      %30 = cute.get_scalars(%e0_128) : !cute.int_tuple<"?">
      %31 = cute.get_scalars(%e1_129) : !cute.int_tuple<"?{div=8}">
      %coord_130 = cute.make_coord(%e1_129) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_131 = cute.make_coord() : () -> !cute.coord<"4096">
      %32 = cute.elem_less(%coord_130, %coord_131) : !cute.coord<"?{div=8}">, !cute.coord<"4096">
      %33 = arith.extui %32 : i1 to i8
      %coord_132 = cute.make_coord() : () -> !cute.coord<"(0,0,0)">
      cute.memref.store(%rmem_106, %coord_132, %33) : (!memref_rmem_i8_, !cute.coord<"(0,0,0)">, i8) -> ()
      %lay_133 = cute.get_layout(%rmem_106) : !memref_rmem_i8_
      %34 = cute.get_shape(%lay_133) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %e0_134, %e1_135, %e2_136 = cute.get_leaves(%34) : !cute.shape<"(8,1,1)">
      %coord_137 = cute.make_coord() : () -> !cute.coord<"((0,1),0,0)">
      %slice_138 = cute.slice(%src_partitioned_76, %coord_137) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">, !cute.coord<"((0,1),0,0)">
      %iter_139 = cute.get_iter(%slice_138) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %tup_140 = cute.deref_arith_tuple_iter(%iter_139) : !cute.arith_tuple_iter<"(?,?{div=8})">
      %e0_141, %e1_142 = cute.get_leaves(%tup_140) : !cute.int_tuple<"(?,?{div=8})">
      %35 = cute.get_scalars(%e0_141) : !cute.int_tuple<"?">
      %36 = cute.get_scalars(%e1_142) : !cute.int_tuple<"?{div=8}">
      %iter_143 = cute.get_iter(%slice_138) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %tup_144 = cute.deref_arith_tuple_iter(%iter_143) : !cute.arith_tuple_iter<"(?,?{div=8})">
      %e0_145, %e1_146 = cute.get_leaves(%tup_144) : !cute.int_tuple<"(?,?{div=8})">
      %37 = cute.get_scalars(%e0_145) : !cute.int_tuple<"?">
      %38 = cute.get_scalars(%e1_146) : !cute.int_tuple<"?{div=8}">
      %iter_147 = cute.get_iter(%slice_138) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %tup_148 = cute.deref_arith_tuple_iter(%iter_147) : !cute.arith_tuple_iter<"(?,?{div=8})">
      %e0_149, %e1_150 = cute.get_leaves(%tup_148) : !cute.int_tuple<"(?,?{div=8})">
      %39 = cute.get_scalars(%e0_149) : !cute.int_tuple<"?">
      %40 = cute.get_scalars(%e1_150) : !cute.int_tuple<"?{div=8}">
      %coord_151 = cute.make_coord(%e1_150) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_152 = cute.make_coord() : () -> !cute.coord<"4096">
      %41 = cute.elem_less(%coord_151, %coord_152) : !cute.coord<"?{div=8}">, !cute.coord<"4096">
      %42 = arith.extui %41 : i1 to i8
      %coord_153 = cute.make_coord() : () -> !cute.coord<"(1,0,0)">
      cute.memref.store(%rmem_106, %coord_153, %42) : (!memref_rmem_i8_, !cute.coord<"(1,0,0)">, i8) -> ()
      %lay_154 = cute.get_layout(%rmem_106) : !memref_rmem_i8_
      %43 = cute.get_shape(%lay_154) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %e0_155, %e1_156, %e2_157 = cute.get_leaves(%43) : !cute.shape<"(8,1,1)">
      %coord_158 = cute.make_coord() : () -> !cute.coord<"((0,2),0,0)">
      %slice_159 = cute.slice(%src_partitioned_76, %coord_158) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">, !cute.coord<"((0,2),0,0)">
      %iter_160 = cute.get_iter(%slice_159) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %tup_161 = cute.deref_arith_tuple_iter(%iter_160) : !cute.arith_tuple_iter<"(?,?{div=8})">
      %e0_162, %e1_163 = cute.get_leaves(%tup_161) : !cute.int_tuple<"(?,?{div=8})">
      %44 = cute.get_scalars(%e0_162) : !cute.int_tuple<"?">
      %45 = cute.get_scalars(%e1_163) : !cute.int_tuple<"?{div=8}">
      %iter_164 = cute.get_iter(%slice_159) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %tup_165 = cute.deref_arith_tuple_iter(%iter_164) : !cute.arith_tuple_iter<"(?,?{div=8})">
      %e0_166, %e1_167 = cute.get_leaves(%tup_165) : !cute.int_tuple<"(?,?{div=8})">
      %46 = cute.get_scalars(%e0_166) : !cute.int_tuple<"?">
      %47 = cute.get_scalars(%e1_167) : !cute.int_tuple<"?{div=8}">
      %iter_168 = cute.get_iter(%slice_159) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %tup_169 = cute.deref_arith_tuple_iter(%iter_168) : !cute.arith_tuple_iter<"(?,?{div=8})">
      %e0_170, %e1_171 = cute.get_leaves(%tup_169) : !cute.int_tuple<"(?,?{div=8})">
      %48 = cute.get_scalars(%e0_170) : !cute.int_tuple<"?">
      %49 = cute.get_scalars(%e1_171) : !cute.int_tuple<"?{div=8}">
      %coord_172 = cute.make_coord(%e1_171) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_173 = cute.make_coord() : () -> !cute.coord<"4096">
      %50 = cute.elem_less(%coord_172, %coord_173) : !cute.coord<"?{div=8}">, !cute.coord<"4096">
      %51 = arith.extui %50 : i1 to i8
      %coord_174 = cute.make_coord() : () -> !cute.coord<"(2,0,0)">
      cute.memref.store(%rmem_106, %coord_174, %51) : (!memref_rmem_i8_, !cute.coord<"(2,0,0)">, i8) -> ()
      %lay_175 = cute.get_layout(%rmem_106) : !memref_rmem_i8_
      %52 = cute.get_shape(%lay_175) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %e0_176, %e1_177, %e2_178 = cute.get_leaves(%52) : !cute.shape<"(8,1,1)">
      %coord_179 = cute.make_coord() : () -> !cute.coord<"((0,3),0,0)">
      %slice_180 = cute.slice(%src_partitioned_76, %coord_179) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">, !cute.coord<"((0,3),0,0)">
      %iter_181 = cute.get_iter(%slice_180) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %tup_182 = cute.deref_arith_tuple_iter(%iter_181) : !cute.arith_tuple_iter<"(?,?{div=8})">
      %e0_183, %e1_184 = cute.get_leaves(%tup_182) : !cute.int_tuple<"(?,?{div=8})">
      %53 = cute.get_scalars(%e0_183) : !cute.int_tuple<"?">
      %54 = cute.get_scalars(%e1_184) : !cute.int_tuple<"?{div=8}">
      %iter_185 = cute.get_iter(%slice_180) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %tup_186 = cute.deref_arith_tuple_iter(%iter_185) : !cute.arith_tuple_iter<"(?,?{div=8})">
      %e0_187, %e1_188 = cute.get_leaves(%tup_186) : !cute.int_tuple<"(?,?{div=8})">
      %55 = cute.get_scalars(%e0_187) : !cute.int_tuple<"?">
      %56 = cute.get_scalars(%e1_188) : !cute.int_tuple<"?{div=8}">
      %iter_189 = cute.get_iter(%slice_180) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %tup_190 = cute.deref_arith_tuple_iter(%iter_189) : !cute.arith_tuple_iter<"(?,?{div=8})">
      %e0_191, %e1_192 = cute.get_leaves(%tup_190) : !cute.int_tuple<"(?,?{div=8})">
      %57 = cute.get_scalars(%e0_191) : !cute.int_tuple<"?">
      %58 = cute.get_scalars(%e1_192) : !cute.int_tuple<"?{div=8}">
      %coord_193 = cute.make_coord(%e1_192) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_194 = cute.make_coord() : () -> !cute.coord<"4096">
      %59 = cute.elem_less(%coord_193, %coord_194) : !cute.coord<"?{div=8}">, !cute.coord<"4096">
      %60 = arith.extui %59 : i1 to i8
      %coord_195 = cute.make_coord() : () -> !cute.coord<"(3,0,0)">
      cute.memref.store(%rmem_106, %coord_195, %60) : (!memref_rmem_i8_, !cute.coord<"(3,0,0)">, i8) -> ()
      %lay_196 = cute.get_layout(%rmem_106) : !memref_rmem_i8_
      %61 = cute.get_shape(%lay_196) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %e0_197, %e1_198, %e2_199 = cute.get_leaves(%61) : !cute.shape<"(8,1,1)">
      %coord_200 = cute.make_coord() : () -> !cute.coord<"((0,4),0,0)">
      %slice_201 = cute.slice(%src_partitioned_76, %coord_200) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">, !cute.coord<"((0,4),0,0)">
      %iter_202 = cute.get_iter(%slice_201) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %tup_203 = cute.deref_arith_tuple_iter(%iter_202) : !cute.arith_tuple_iter<"(?,?{div=8})">
      %e0_204, %e1_205 = cute.get_leaves(%tup_203) : !cute.int_tuple<"(?,?{div=8})">
      %62 = cute.get_scalars(%e0_204) : !cute.int_tuple<"?">
      %63 = cute.get_scalars(%e1_205) : !cute.int_tuple<"?{div=8}">
      %iter_206 = cute.get_iter(%slice_201) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %tup_207 = cute.deref_arith_tuple_iter(%iter_206) : !cute.arith_tuple_iter<"(?,?{div=8})">
      %e0_208, %e1_209 = cute.get_leaves(%tup_207) : !cute.int_tuple<"(?,?{div=8})">
      %64 = cute.get_scalars(%e0_208) : !cute.int_tuple<"?">
      %65 = cute.get_scalars(%e1_209) : !cute.int_tuple<"?{div=8}">
      %iter_210 = cute.get_iter(%slice_201) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %tup_211 = cute.deref_arith_tuple_iter(%iter_210) : !cute.arith_tuple_iter<"(?,?{div=8})">
      %e0_212, %e1_213 = cute.get_leaves(%tup_211) : !cute.int_tuple<"(?,?{div=8})">
      %66 = cute.get_scalars(%e0_212) : !cute.int_tuple<"?">
      %67 = cute.get_scalars(%e1_213) : !cute.int_tuple<"?{div=8}">
      %coord_214 = cute.make_coord(%e1_213) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_215 = cute.make_coord() : () -> !cute.coord<"4096">
      %68 = cute.elem_less(%coord_214, %coord_215) : !cute.coord<"?{div=8}">, !cute.coord<"4096">
      %69 = arith.extui %68 : i1 to i8
      %coord_216 = cute.make_coord() : () -> !cute.coord<"(4,0,0)">
      cute.memref.store(%rmem_106, %coord_216, %69) : (!memref_rmem_i8_, !cute.coord<"(4,0,0)">, i8) -> ()
      %lay_217 = cute.get_layout(%rmem_106) : !memref_rmem_i8_
      %70 = cute.get_shape(%lay_217) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %e0_218, %e1_219, %e2_220 = cute.get_leaves(%70) : !cute.shape<"(8,1,1)">
      %coord_221 = cute.make_coord() : () -> !cute.coord<"((0,5),0,0)">
      %slice_222 = cute.slice(%src_partitioned_76, %coord_221) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">, !cute.coord<"((0,5),0,0)">
      %iter_223 = cute.get_iter(%slice_222) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %tup_224 = cute.deref_arith_tuple_iter(%iter_223) : !cute.arith_tuple_iter<"(?,?{div=8})">
      %e0_225, %e1_226 = cute.get_leaves(%tup_224) : !cute.int_tuple<"(?,?{div=8})">
      %71 = cute.get_scalars(%e0_225) : !cute.int_tuple<"?">
      %72 = cute.get_scalars(%e1_226) : !cute.int_tuple<"?{div=8}">
      %iter_227 = cute.get_iter(%slice_222) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %tup_228 = cute.deref_arith_tuple_iter(%iter_227) : !cute.arith_tuple_iter<"(?,?{div=8})">
      %e0_229, %e1_230 = cute.get_leaves(%tup_228) : !cute.int_tuple<"(?,?{div=8})">
      %73 = cute.get_scalars(%e0_229) : !cute.int_tuple<"?">
      %74 = cute.get_scalars(%e1_230) : !cute.int_tuple<"?{div=8}">
      %iter_231 = cute.get_iter(%slice_222) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %tup_232 = cute.deref_arith_tuple_iter(%iter_231) : !cute.arith_tuple_iter<"(?,?{div=8})">
      %e0_233, %e1_234 = cute.get_leaves(%tup_232) : !cute.int_tuple<"(?,?{div=8})">
      %75 = cute.get_scalars(%e0_233) : !cute.int_tuple<"?">
      %76 = cute.get_scalars(%e1_234) : !cute.int_tuple<"?{div=8}">
      %coord_235 = cute.make_coord(%e1_234) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_236 = cute.make_coord() : () -> !cute.coord<"4096">
      %77 = cute.elem_less(%coord_235, %coord_236) : !cute.coord<"?{div=8}">, !cute.coord<"4096">
      %78 = arith.extui %77 : i1 to i8
      %coord_237 = cute.make_coord() : () -> !cute.coord<"(5,0,0)">
      cute.memref.store(%rmem_106, %coord_237, %78) : (!memref_rmem_i8_, !cute.coord<"(5,0,0)">, i8) -> ()
      %lay_238 = cute.get_layout(%rmem_106) : !memref_rmem_i8_
      %79 = cute.get_shape(%lay_238) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %e0_239, %e1_240, %e2_241 = cute.get_leaves(%79) : !cute.shape<"(8,1,1)">
      %coord_242 = cute.make_coord() : () -> !cute.coord<"((0,6),0,0)">
      %slice_243 = cute.slice(%src_partitioned_76, %coord_242) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">, !cute.coord<"((0,6),0,0)">
      %iter_244 = cute.get_iter(%slice_243) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %tup_245 = cute.deref_arith_tuple_iter(%iter_244) : !cute.arith_tuple_iter<"(?,?{div=8})">
      %e0_246, %e1_247 = cute.get_leaves(%tup_245) : !cute.int_tuple<"(?,?{div=8})">
      %80 = cute.get_scalars(%e0_246) : !cute.int_tuple<"?">
      %81 = cute.get_scalars(%e1_247) : !cute.int_tuple<"?{div=8}">
      %iter_248 = cute.get_iter(%slice_243) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %tup_249 = cute.deref_arith_tuple_iter(%iter_248) : !cute.arith_tuple_iter<"(?,?{div=8})">
      %e0_250, %e1_251 = cute.get_leaves(%tup_249) : !cute.int_tuple<"(?,?{div=8})">
      %82 = cute.get_scalars(%e0_250) : !cute.int_tuple<"?">
      %83 = cute.get_scalars(%e1_251) : !cute.int_tuple<"?{div=8}">
      %iter_252 = cute.get_iter(%slice_243) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %tup_253 = cute.deref_arith_tuple_iter(%iter_252) : !cute.arith_tuple_iter<"(?,?{div=8})">
      %e0_254, %e1_255 = cute.get_leaves(%tup_253) : !cute.int_tuple<"(?,?{div=8})">
      %84 = cute.get_scalars(%e0_254) : !cute.int_tuple<"?">
      %85 = cute.get_scalars(%e1_255) : !cute.int_tuple<"?{div=8}">
      %coord_256 = cute.make_coord(%e1_255) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_257 = cute.make_coord() : () -> !cute.coord<"4096">
      %86 = cute.elem_less(%coord_256, %coord_257) : !cute.coord<"?{div=8}">, !cute.coord<"4096">
      %87 = arith.extui %86 : i1 to i8
      %coord_258 = cute.make_coord() : () -> !cute.coord<"(6,0,0)">
      cute.memref.store(%rmem_106, %coord_258, %87) : (!memref_rmem_i8_, !cute.coord<"(6,0,0)">, i8) -> ()
      %lay_259 = cute.get_layout(%rmem_106) : !memref_rmem_i8_
      %88 = cute.get_shape(%lay_259) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %e0_260, %e1_261, %e2_262 = cute.get_leaves(%88) : !cute.shape<"(8,1,1)">
      %coord_263 = cute.make_coord() : () -> !cute.coord<"((0,7),0,0)">
      %slice_264 = cute.slice(%src_partitioned_76, %coord_263) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">, !cute.coord<"((0,7),0,0)">
      %iter_265 = cute.get_iter(%slice_264) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %tup_266 = cute.deref_arith_tuple_iter(%iter_265) : !cute.arith_tuple_iter<"(?,?{div=8})">
      %e0_267, %e1_268 = cute.get_leaves(%tup_266) : !cute.int_tuple<"(?,?{div=8})">
      %89 = cute.get_scalars(%e0_267) : !cute.int_tuple<"?">
      %90 = cute.get_scalars(%e1_268) : !cute.int_tuple<"?{div=8}">
      %iter_269 = cute.get_iter(%slice_264) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %tup_270 = cute.deref_arith_tuple_iter(%iter_269) : !cute.arith_tuple_iter<"(?,?{div=8})">
      %e0_271, %e1_272 = cute.get_leaves(%tup_270) : !cute.int_tuple<"(?,?{div=8})">
      %91 = cute.get_scalars(%e0_271) : !cute.int_tuple<"?">
      %92 = cute.get_scalars(%e1_272) : !cute.int_tuple<"?{div=8}">
      %iter_273 = cute.get_iter(%slice_264) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %tup_274 = cute.deref_arith_tuple_iter(%iter_273) : !cute.arith_tuple_iter<"(?,?{div=8})">
      %e0_275, %e1_276 = cute.get_leaves(%tup_274) : !cute.int_tuple<"(?,?{div=8})">
      %93 = cute.get_scalars(%e0_275) : !cute.int_tuple<"?">
      %94 = cute.get_scalars(%e1_276) : !cute.int_tuple<"?{div=8}">
      %coord_277 = cute.make_coord(%e1_276) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_278 = cute.make_coord() : () -> !cute.coord<"4096">
      %95 = cute.elem_less(%coord_277, %coord_278) : !cute.coord<"?{div=8}">, !cute.coord<"4096">
      %96 = arith.extui %95 : i1 to i8
      %coord_279 = cute.make_coord() : () -> !cute.coord<"(7,0,0)">
      cute.memref.store(%rmem_106, %coord_279, %96) : (!memref_rmem_i8_, !cute.coord<"(7,0,0)">, i8) -> ()
      %coord_280 = cute.make_coord() : () -> !cute.coord<"((0,0),0,0)">
      %slice_281 = cute.slice(%src_partitioned_76, %coord_280) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">, !cute.coord<"((0,0),0,0)">
      %iter_282 = cute.get_iter(%slice_281) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %tup_283 = cute.deref_arith_tuple_iter(%iter_282) : !cute.arith_tuple_iter<"(?,?{div=8})">
      %e0_284, %e1_285 = cute.get_leaves(%tup_283) : !cute.int_tuple<"(?,?{div=8})">
      %97 = cute.get_scalars(%e0_284) : !cute.int_tuple<"?">
      %98 = cute.get_scalars(%e1_285) : !cute.int_tuple<"?{div=8}">
      %iter_286 = cute.get_iter(%slice_281) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %tup_287 = cute.deref_arith_tuple_iter(%iter_286) : !cute.arith_tuple_iter<"(?,?{div=8})">
      %e0_288, %e1_289 = cute.get_leaves(%tup_287) : !cute.int_tuple<"(?,?{div=8})">
      %99 = cute.get_scalars(%e0_288) : !cute.int_tuple<"?">
      %100 = cute.get_scalars(%e1_289) : !cute.int_tuple<"?{div=8}">
      %iter_290 = cute.get_iter(%slice_281) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %tup_291 = cute.deref_arith_tuple_iter(%iter_290) : !cute.arith_tuple_iter<"(?,?{div=8})">
      %e0_292, %e1_293 = cute.get_leaves(%tup_291) : !cute.int_tuple<"(?,?{div=8})">
      %101 = cute.get_scalars(%e0_292) : !cute.int_tuple<"?">
      %102 = cute.get_scalars(%e1_293) : !cute.int_tuple<"?{div=8}">
      %103 = arith.cmpi slt, %101, %7 : i32
      scf.if %103 {
        %lay_713 = cute.get_layout(%src_partitioned) : !memref_gmem_bf16_5
        %269 = cute.get_shape(%lay_713) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %e0_714, %e1_715, %e2_716, %e3_717 = cute.get_leaves(%269) : !cute.shape<"((8,8),1,1)">
        %lay_718 = cute.get_layout(%dst_partitioned) : !memref_smem_bf16_1
        %270 = cute.get_shape(%lay_718) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %e0_719, %e1_720, %e2_721, %e3_722 = cute.get_leaves(%270) : !cute.shape<"((8,8),1,1)">
        %lay_723 = cute.get_layout(%src_partitioned) : !memref_gmem_bf16_5
        %shape_724 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_725 = cute.make_layout(%shape_724) : !cute.layout<"1:0">
        %append_726 = cute.append_to_rank<2> (%lay_723, %lay_725) : !cute.layout<"((8,8),1,1):((1,512),0,0)">, !cute.layout<"1:0">
        %view_727 = cute.make_view(%iter_69, %append_726) : !memref_gmem_bf16_5
        %iter_728 = cute.get_iter(%view_727) : !memref_gmem_bf16_5
        %lay_729 = cute.get_layout(%view_727) : !memref_gmem_bf16_5
        %271 = cute.get_shape(%lay_729) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %e0_730, %e1_731, %e2_732, %e3_733 = cute.get_leaves(%271) : !cute.shape<"((8,8),1,1)">
        %lay_734 = cute.get_layout(%view_727) : !memref_gmem_bf16_5
        %272 = cute.get_shape(%lay_734) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %e0_735, %e1_736, %e2_737, %e3_738 = cute.get_leaves(%272) : !cute.shape<"((8,8),1,1)">
        %grouped_739 = cute.group_modes(%view_727) <1, 3> : (!memref_gmem_bf16_5) -> !memref_gmem_bf16_6
        %iter_740 = cute.get_iter(%grouped_739) : !memref_gmem_bf16_6
        %iter_741 = cute.get_iter(%grouped_739) : !memref_gmem_bf16_6
        %lay_742 = cute.get_layout(%dst_partitioned) : !memref_smem_bf16_1
        %shape_743 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_744 = cute.make_layout(%shape_743) : !cute.layout<"1:0">
        %append_745 = cute.append_to_rank<2> (%lay_742, %lay_744) : !cute.layout<"((8,8),1,1):((1,512),0,0)">, !cute.layout<"1:0">
        %view_746 = cute.make_view(%iter_71, %append_745) : !memref_smem_bf16_1
        %iter_747 = cute.get_iter(%view_746) : !memref_smem_bf16_1
        %lay_748 = cute.get_layout(%view_746) : !memref_smem_bf16_1
        %273 = cute.get_shape(%lay_748) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %e0_749, %e1_750, %e2_751, %e3_752 = cute.get_leaves(%273) : !cute.shape<"((8,8),1,1)">
        %lay_753 = cute.get_layout(%view_746) : !memref_smem_bf16_1
        %274 = cute.get_shape(%lay_753) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %e0_754, %e1_755, %e2_756, %e3_757 = cute.get_leaves(%274) : !cute.shape<"((8,8),1,1)">
        %grouped_758 = cute.group_modes(%view_746) <1, 3> : (!memref_smem_bf16_1) -> !memref_smem_bf16_2
        %iter_759 = cute.get_iter(%grouped_758) : !memref_smem_bf16_2
        %iter_760 = cute.get_iter(%grouped_758) : !memref_smem_bf16_2
        %lay_761 = cute.get_layout(%rmem_106) : !memref_rmem_i8_
        %shape_762 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_763 = cute.make_layout(%shape_762) : !cute.layout<"1:0">
        %append_764 = cute.append_to_rank<2> (%lay_761, %lay_763) : !cute.layout<"(8,1,1):(1,0,1)">, !cute.layout<"1:0">
        %view_765 = cute.make_view(%iter_108, %append_764) : !memref_rmem_i8_
        %iter_766 = cute.get_iter(%view_765) : !memref_rmem_i8_
        %lay_767 = cute.get_layout(%view_765) : !memref_rmem_i8_
        %275 = cute.get_shape(%lay_767) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
        %e0_768, %e1_769, %e2_770 = cute.get_leaves(%275) : !cute.shape<"(8,1,1)">
        %lay_771 = cute.get_layout(%view_765) : !memref_rmem_i8_
        %276 = cute.get_shape(%lay_771) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
        %e0_772, %e1_773, %e2_774 = cute.get_leaves(%276) : !cute.shape<"(8,1,1)">
        %grouped_775 = cute.group_modes(%view_765) <1, 3> : (!memref_rmem_i8_) -> !memref_rmem_i8_1
        %iter_776 = cute.get_iter(%grouped_775) : !memref_rmem_i8_1
        %iter_777 = cute.get_iter(%grouped_775) : !memref_rmem_i8_1
        %lay_778 = cute.get_layout(%grouped_739) : !memref_gmem_bf16_6
        %277 = cute.get_shape(%lay_778) : (!cute.layout<"((8,8),(1,1)):((1,512),(0,0))">) -> !cute.shape<"((8,8),(1,1))">
        %e0_779, %e1_780, %e2_781, %e3_782 = cute.get_leaves(%277) : !cute.shape<"((8,8),(1,1))">
        %lay_783 = cute.get_layout(%grouped_758) : !memref_smem_bf16_2
        %278 = cute.get_shape(%lay_783) : (!cute.layout<"((8,8),(1,1)):((1,512),(0,0))">) -> !cute.shape<"((8,8),(1,1))">
        %e0_784, %e1_785, %e2_786, %e3_787 = cute.get_leaves(%278) : !cute.shape<"((8,8),(1,1))">
        %sz_788 = cute.size(%grouped_739) <{mode = [1]}> : (!memref_gmem_bf16_6) -> !cute.int_tuple<"1">
        %e0_789 = cute.get_leaves(%sz_788) : !cute.int_tuple<"1">
        %sz_790 = cute.size(%grouped_758) <{mode = [1]}> : (!memref_smem_bf16_2) -> !cute.int_tuple<"1">
        %e0_791 = cute.get_leaves(%sz_790) : !cute.int_tuple<"1">
        cute.copy(%atom, %grouped_739, %grouped_758, %grouped_775) : (!cute_nvgpu.atom.simt_async_copy<bf16, cache = always, 128 b>, !memref_gmem_bf16_6, !memref_smem_bf16_2, !memref_rmem_i8_1)
      }
      nvvm.cp.async.commit.group
      %coord_294 = cute.make_coord(%0) : (i32) -> !cute.coord<"?">
      %src_partitioned_295 = cute.tiled.copy.partition_S(%17, %tiled_view_48, %coord_294) : (!copy_simt, !cute.coord_tensor<"(?{div=2},0)", "(2,4096):(1@0,1@1)">, !cute.coord<"?">) -> !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %iter_296 = cute.get_iter(%src_partitioned_295) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %tup_297 = cute.deref_arith_tuple_iter(%iter_296) : !cute.arith_tuple_iter<"(?,?{div=8})">
      %e0_298, %e1_299 = cute.get_leaves(%tup_297) : !cute.int_tuple<"(?,?{div=8})">
      %104 = cute.get_scalars(%e0_298) : !cute.int_tuple<"?">
      %105 = cute.get_scalars(%e1_299) : !cute.int_tuple<"?{div=8}">
      %sz_300 = cute.size(%src_partitioned_295) <{mode = [0, 1]}> : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"8">
      %e0_301 = cute.get_leaves(%sz_300) : !cute.int_tuple<"8">
      %sz_302 = cute.size(%src_partitioned_295) <{mode = [1]}> : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"1">
      %e0_303 = cute.get_leaves(%sz_302) : !cute.int_tuple<"1">
      %sz_304 = cute.size(%src_partitioned_295) <{mode = [2]}> : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"1">
      %e0_305 = cute.get_leaves(%sz_304) : !cute.int_tuple<"1">
      %sz_306 = cute.size(%src_partitioned_295) <{mode = [2]}> : (!cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"1">
      %e0_307 = cute.get_leaves(%sz_306) : !cute.int_tuple<"1">
      %shape_308 = cute.make_shape() : () -> !cute.shape<"(8,1,1)">
      %stride_309 = cute.make_stride() : () -> !cute.stride<"(1,0,1)">
      %lay_310 = cute.make_layout(%shape_308, %stride_309) : !cute.layout<"(8,1,1):(1,0,1)">
      %rmem_311 = cute.memref.alloca(%lay_310) : !memref_rmem_i8_
      %iter_312 = cute.get_iter(%rmem_311) : !memref_rmem_i8_
      %iter_313 = cute.get_iter(%rmem_311) : !memref_rmem_i8_
      %lay_314 = cute.get_layout(%rmem_311) : !memref_rmem_i8_
      %106 = cute.get_shape(%lay_314) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %e0_315, %e1_316, %e2_317 = cute.get_leaves(%106) : !cute.shape<"(8,1,1)">
      %lay_318 = cute.get_layout(%rmem_311) : !memref_rmem_i8_
      %107 = cute.get_shape(%lay_318) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %e0_319, %e1_320, %e2_321 = cute.get_leaves(%107) : !cute.shape<"(8,1,1)">
      %coord_322 = cute.make_coord() : () -> !cute.coord<"((0,0),0,0)">
      %slice_323 = cute.slice(%src_partitioned_295, %coord_322) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">, !cute.coord<"((0,0),0,0)">
      %iter_324 = cute.get_iter(%slice_323) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %tup_325 = cute.deref_arith_tuple_iter(%iter_324) : !cute.arith_tuple_iter<"(?,?{div=8})">
      %e0_326, %e1_327 = cute.get_leaves(%tup_325) : !cute.int_tuple<"(?,?{div=8})">
      %108 = cute.get_scalars(%e0_326) : !cute.int_tuple<"?">
      %109 = cute.get_scalars(%e1_327) : !cute.int_tuple<"?{div=8}">
      %iter_328 = cute.get_iter(%slice_323) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %tup_329 = cute.deref_arith_tuple_iter(%iter_328) : !cute.arith_tuple_iter<"(?,?{div=8})">
      %e0_330, %e1_331 = cute.get_leaves(%tup_329) : !cute.int_tuple<"(?,?{div=8})">
      %110 = cute.get_scalars(%e0_330) : !cute.int_tuple<"?">
      %111 = cute.get_scalars(%e1_331) : !cute.int_tuple<"?{div=8}">
      %iter_332 = cute.get_iter(%slice_323) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %tup_333 = cute.deref_arith_tuple_iter(%iter_332) : !cute.arith_tuple_iter<"(?,?{div=8})">
      %e0_334, %e1_335 = cute.get_leaves(%tup_333) : !cute.int_tuple<"(?,?{div=8})">
      %112 = cute.get_scalars(%e0_334) : !cute.int_tuple<"?">
      %113 = cute.get_scalars(%e1_335) : !cute.int_tuple<"?{div=8}">
      %coord_336 = cute.make_coord(%e1_335) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_337 = cute.make_coord() : () -> !cute.coord<"4096">
      %114 = cute.elem_less(%coord_336, %coord_337) : !cute.coord<"?{div=8}">, !cute.coord<"4096">
      %115 = arith.extui %114 : i1 to i8
      %coord_338 = cute.make_coord() : () -> !cute.coord<"(0,0,0)">
      cute.memref.store(%rmem_311, %coord_338, %115) : (!memref_rmem_i8_, !cute.coord<"(0,0,0)">, i8) -> ()
      %lay_339 = cute.get_layout(%rmem_311) : !memref_rmem_i8_
      %116 = cute.get_shape(%lay_339) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %e0_340, %e1_341, %e2_342 = cute.get_leaves(%116) : !cute.shape<"(8,1,1)">
      %coord_343 = cute.make_coord() : () -> !cute.coord<"((0,1),0,0)">
      %slice_344 = cute.slice(%src_partitioned_295, %coord_343) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">, !cute.coord<"((0,1),0,0)">
      %iter_345 = cute.get_iter(%slice_344) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %tup_346 = cute.deref_arith_tuple_iter(%iter_345) : !cute.arith_tuple_iter<"(?,?{div=8})">
      %e0_347, %e1_348 = cute.get_leaves(%tup_346) : !cute.int_tuple<"(?,?{div=8})">
      %117 = cute.get_scalars(%e0_347) : !cute.int_tuple<"?">
      %118 = cute.get_scalars(%e1_348) : !cute.int_tuple<"?{div=8}">
      %iter_349 = cute.get_iter(%slice_344) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %tup_350 = cute.deref_arith_tuple_iter(%iter_349) : !cute.arith_tuple_iter<"(?,?{div=8})">
      %e0_351, %e1_352 = cute.get_leaves(%tup_350) : !cute.int_tuple<"(?,?{div=8})">
      %119 = cute.get_scalars(%e0_351) : !cute.int_tuple<"?">
      %120 = cute.get_scalars(%e1_352) : !cute.int_tuple<"?{div=8}">
      %iter_353 = cute.get_iter(%slice_344) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %tup_354 = cute.deref_arith_tuple_iter(%iter_353) : !cute.arith_tuple_iter<"(?,?{div=8})">
      %e0_355, %e1_356 = cute.get_leaves(%tup_354) : !cute.int_tuple<"(?,?{div=8})">
      %121 = cute.get_scalars(%e0_355) : !cute.int_tuple<"?">
      %122 = cute.get_scalars(%e1_356) : !cute.int_tuple<"?{div=8}">
      %coord_357 = cute.make_coord(%e1_356) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_358 = cute.make_coord() : () -> !cute.coord<"4096">
      %123 = cute.elem_less(%coord_357, %coord_358) : !cute.coord<"?{div=8}">, !cute.coord<"4096">
      %124 = arith.extui %123 : i1 to i8
      %coord_359 = cute.make_coord() : () -> !cute.coord<"(1,0,0)">
      cute.memref.store(%rmem_311, %coord_359, %124) : (!memref_rmem_i8_, !cute.coord<"(1,0,0)">, i8) -> ()
      %lay_360 = cute.get_layout(%rmem_311) : !memref_rmem_i8_
      %125 = cute.get_shape(%lay_360) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %e0_361, %e1_362, %e2_363 = cute.get_leaves(%125) : !cute.shape<"(8,1,1)">
      %coord_364 = cute.make_coord() : () -> !cute.coord<"((0,2),0,0)">
      %slice_365 = cute.slice(%src_partitioned_295, %coord_364) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">, !cute.coord<"((0,2),0,0)">
      %iter_366 = cute.get_iter(%slice_365) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %tup_367 = cute.deref_arith_tuple_iter(%iter_366) : !cute.arith_tuple_iter<"(?,?{div=8})">
      %e0_368, %e1_369 = cute.get_leaves(%tup_367) : !cute.int_tuple<"(?,?{div=8})">
      %126 = cute.get_scalars(%e0_368) : !cute.int_tuple<"?">
      %127 = cute.get_scalars(%e1_369) : !cute.int_tuple<"?{div=8}">
      %iter_370 = cute.get_iter(%slice_365) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %tup_371 = cute.deref_arith_tuple_iter(%iter_370) : !cute.arith_tuple_iter<"(?,?{div=8})">
      %e0_372, %e1_373 = cute.get_leaves(%tup_371) : !cute.int_tuple<"(?,?{div=8})">
      %128 = cute.get_scalars(%e0_372) : !cute.int_tuple<"?">
      %129 = cute.get_scalars(%e1_373) : !cute.int_tuple<"?{div=8}">
      %iter_374 = cute.get_iter(%slice_365) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %tup_375 = cute.deref_arith_tuple_iter(%iter_374) : !cute.arith_tuple_iter<"(?,?{div=8})">
      %e0_376, %e1_377 = cute.get_leaves(%tup_375) : !cute.int_tuple<"(?,?{div=8})">
      %130 = cute.get_scalars(%e0_376) : !cute.int_tuple<"?">
      %131 = cute.get_scalars(%e1_377) : !cute.int_tuple<"?{div=8}">
      %coord_378 = cute.make_coord(%e1_377) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_379 = cute.make_coord() : () -> !cute.coord<"4096">
      %132 = cute.elem_less(%coord_378, %coord_379) : !cute.coord<"?{div=8}">, !cute.coord<"4096">
      %133 = arith.extui %132 : i1 to i8
      %coord_380 = cute.make_coord() : () -> !cute.coord<"(2,0,0)">
      cute.memref.store(%rmem_311, %coord_380, %133) : (!memref_rmem_i8_, !cute.coord<"(2,0,0)">, i8) -> ()
      %lay_381 = cute.get_layout(%rmem_311) : !memref_rmem_i8_
      %134 = cute.get_shape(%lay_381) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %e0_382, %e1_383, %e2_384 = cute.get_leaves(%134) : !cute.shape<"(8,1,1)">
      %coord_385 = cute.make_coord() : () -> !cute.coord<"((0,3),0,0)">
      %slice_386 = cute.slice(%src_partitioned_295, %coord_385) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">, !cute.coord<"((0,3),0,0)">
      %iter_387 = cute.get_iter(%slice_386) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %tup_388 = cute.deref_arith_tuple_iter(%iter_387) : !cute.arith_tuple_iter<"(?,?{div=8})">
      %e0_389, %e1_390 = cute.get_leaves(%tup_388) : !cute.int_tuple<"(?,?{div=8})">
      %135 = cute.get_scalars(%e0_389) : !cute.int_tuple<"?">
      %136 = cute.get_scalars(%e1_390) : !cute.int_tuple<"?{div=8}">
      %iter_391 = cute.get_iter(%slice_386) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %tup_392 = cute.deref_arith_tuple_iter(%iter_391) : !cute.arith_tuple_iter<"(?,?{div=8})">
      %e0_393, %e1_394 = cute.get_leaves(%tup_392) : !cute.int_tuple<"(?,?{div=8})">
      %137 = cute.get_scalars(%e0_393) : !cute.int_tuple<"?">
      %138 = cute.get_scalars(%e1_394) : !cute.int_tuple<"?{div=8}">
      %iter_395 = cute.get_iter(%slice_386) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %tup_396 = cute.deref_arith_tuple_iter(%iter_395) : !cute.arith_tuple_iter<"(?,?{div=8})">
      %e0_397, %e1_398 = cute.get_leaves(%tup_396) : !cute.int_tuple<"(?,?{div=8})">
      %139 = cute.get_scalars(%e0_397) : !cute.int_tuple<"?">
      %140 = cute.get_scalars(%e1_398) : !cute.int_tuple<"?{div=8}">
      %coord_399 = cute.make_coord(%e1_398) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_400 = cute.make_coord() : () -> !cute.coord<"4096">
      %141 = cute.elem_less(%coord_399, %coord_400) : !cute.coord<"?{div=8}">, !cute.coord<"4096">
      %142 = arith.extui %141 : i1 to i8
      %coord_401 = cute.make_coord() : () -> !cute.coord<"(3,0,0)">
      cute.memref.store(%rmem_311, %coord_401, %142) : (!memref_rmem_i8_, !cute.coord<"(3,0,0)">, i8) -> ()
      %lay_402 = cute.get_layout(%rmem_311) : !memref_rmem_i8_
      %143 = cute.get_shape(%lay_402) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %e0_403, %e1_404, %e2_405 = cute.get_leaves(%143) : !cute.shape<"(8,1,1)">
      %coord_406 = cute.make_coord() : () -> !cute.coord<"((0,4),0,0)">
      %slice_407 = cute.slice(%src_partitioned_295, %coord_406) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">, !cute.coord<"((0,4),0,0)">
      %iter_408 = cute.get_iter(%slice_407) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %tup_409 = cute.deref_arith_tuple_iter(%iter_408) : !cute.arith_tuple_iter<"(?,?{div=8})">
      %e0_410, %e1_411 = cute.get_leaves(%tup_409) : !cute.int_tuple<"(?,?{div=8})">
      %144 = cute.get_scalars(%e0_410) : !cute.int_tuple<"?">
      %145 = cute.get_scalars(%e1_411) : !cute.int_tuple<"?{div=8}">
      %iter_412 = cute.get_iter(%slice_407) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %tup_413 = cute.deref_arith_tuple_iter(%iter_412) : !cute.arith_tuple_iter<"(?,?{div=8})">
      %e0_414, %e1_415 = cute.get_leaves(%tup_413) : !cute.int_tuple<"(?,?{div=8})">
      %146 = cute.get_scalars(%e0_414) : !cute.int_tuple<"?">
      %147 = cute.get_scalars(%e1_415) : !cute.int_tuple<"?{div=8}">
      %iter_416 = cute.get_iter(%slice_407) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %tup_417 = cute.deref_arith_tuple_iter(%iter_416) : !cute.arith_tuple_iter<"(?,?{div=8})">
      %e0_418, %e1_419 = cute.get_leaves(%tup_417) : !cute.int_tuple<"(?,?{div=8})">
      %148 = cute.get_scalars(%e0_418) : !cute.int_tuple<"?">
      %149 = cute.get_scalars(%e1_419) : !cute.int_tuple<"?{div=8}">
      %coord_420 = cute.make_coord(%e1_419) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_421 = cute.make_coord() : () -> !cute.coord<"4096">
      %150 = cute.elem_less(%coord_420, %coord_421) : !cute.coord<"?{div=8}">, !cute.coord<"4096">
      %151 = arith.extui %150 : i1 to i8
      %coord_422 = cute.make_coord() : () -> !cute.coord<"(4,0,0)">
      cute.memref.store(%rmem_311, %coord_422, %151) : (!memref_rmem_i8_, !cute.coord<"(4,0,0)">, i8) -> ()
      %lay_423 = cute.get_layout(%rmem_311) : !memref_rmem_i8_
      %152 = cute.get_shape(%lay_423) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %e0_424, %e1_425, %e2_426 = cute.get_leaves(%152) : !cute.shape<"(8,1,1)">
      %coord_427 = cute.make_coord() : () -> !cute.coord<"((0,5),0,0)">
      %slice_428 = cute.slice(%src_partitioned_295, %coord_427) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">, !cute.coord<"((0,5),0,0)">
      %iter_429 = cute.get_iter(%slice_428) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %tup_430 = cute.deref_arith_tuple_iter(%iter_429) : !cute.arith_tuple_iter<"(?,?{div=8})">
      %e0_431, %e1_432 = cute.get_leaves(%tup_430) : !cute.int_tuple<"(?,?{div=8})">
      %153 = cute.get_scalars(%e0_431) : !cute.int_tuple<"?">
      %154 = cute.get_scalars(%e1_432) : !cute.int_tuple<"?{div=8}">
      %iter_433 = cute.get_iter(%slice_428) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %tup_434 = cute.deref_arith_tuple_iter(%iter_433) : !cute.arith_tuple_iter<"(?,?{div=8})">
      %e0_435, %e1_436 = cute.get_leaves(%tup_434) : !cute.int_tuple<"(?,?{div=8})">
      %155 = cute.get_scalars(%e0_435) : !cute.int_tuple<"?">
      %156 = cute.get_scalars(%e1_436) : !cute.int_tuple<"?{div=8}">
      %iter_437 = cute.get_iter(%slice_428) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %tup_438 = cute.deref_arith_tuple_iter(%iter_437) : !cute.arith_tuple_iter<"(?,?{div=8})">
      %e0_439, %e1_440 = cute.get_leaves(%tup_438) : !cute.int_tuple<"(?,?{div=8})">
      %157 = cute.get_scalars(%e0_439) : !cute.int_tuple<"?">
      %158 = cute.get_scalars(%e1_440) : !cute.int_tuple<"?{div=8}">
      %coord_441 = cute.make_coord(%e1_440) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_442 = cute.make_coord() : () -> !cute.coord<"4096">
      %159 = cute.elem_less(%coord_441, %coord_442) : !cute.coord<"?{div=8}">, !cute.coord<"4096">
      %160 = arith.extui %159 : i1 to i8
      %coord_443 = cute.make_coord() : () -> !cute.coord<"(5,0,0)">
      cute.memref.store(%rmem_311, %coord_443, %160) : (!memref_rmem_i8_, !cute.coord<"(5,0,0)">, i8) -> ()
      %lay_444 = cute.get_layout(%rmem_311) : !memref_rmem_i8_
      %161 = cute.get_shape(%lay_444) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %e0_445, %e1_446, %e2_447 = cute.get_leaves(%161) : !cute.shape<"(8,1,1)">
      %coord_448 = cute.make_coord() : () -> !cute.coord<"((0,6),0,0)">
      %slice_449 = cute.slice(%src_partitioned_295, %coord_448) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">, !cute.coord<"((0,6),0,0)">
      %iter_450 = cute.get_iter(%slice_449) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %tup_451 = cute.deref_arith_tuple_iter(%iter_450) : !cute.arith_tuple_iter<"(?,?{div=8})">
      %e0_452, %e1_453 = cute.get_leaves(%tup_451) : !cute.int_tuple<"(?,?{div=8})">
      %162 = cute.get_scalars(%e0_452) : !cute.int_tuple<"?">
      %163 = cute.get_scalars(%e1_453) : !cute.int_tuple<"?{div=8}">
      %iter_454 = cute.get_iter(%slice_449) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %tup_455 = cute.deref_arith_tuple_iter(%iter_454) : !cute.arith_tuple_iter<"(?,?{div=8})">
      %e0_456, %e1_457 = cute.get_leaves(%tup_455) : !cute.int_tuple<"(?,?{div=8})">
      %164 = cute.get_scalars(%e0_456) : !cute.int_tuple<"?">
      %165 = cute.get_scalars(%e1_457) : !cute.int_tuple<"?{div=8}">
      %iter_458 = cute.get_iter(%slice_449) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %tup_459 = cute.deref_arith_tuple_iter(%iter_458) : !cute.arith_tuple_iter<"(?,?{div=8})">
      %e0_460, %e1_461 = cute.get_leaves(%tup_459) : !cute.int_tuple<"(?,?{div=8})">
      %166 = cute.get_scalars(%e0_460) : !cute.int_tuple<"?">
      %167 = cute.get_scalars(%e1_461) : !cute.int_tuple<"?{div=8}">
      %coord_462 = cute.make_coord(%e1_461) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_463 = cute.make_coord() : () -> !cute.coord<"4096">
      %168 = cute.elem_less(%coord_462, %coord_463) : !cute.coord<"?{div=8}">, !cute.coord<"4096">
      %169 = arith.extui %168 : i1 to i8
      %coord_464 = cute.make_coord() : () -> !cute.coord<"(6,0,0)">
      cute.memref.store(%rmem_311, %coord_464, %169) : (!memref_rmem_i8_, !cute.coord<"(6,0,0)">, i8) -> ()
      %lay_465 = cute.get_layout(%rmem_311) : !memref_rmem_i8_
      %170 = cute.get_shape(%lay_465) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %e0_466, %e1_467, %e2_468 = cute.get_leaves(%170) : !cute.shape<"(8,1,1)">
      %coord_469 = cute.make_coord() : () -> !cute.coord<"((0,7),0,0)">
      %slice_470 = cute.slice(%src_partitioned_295, %coord_469) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">, !cute.coord<"((0,7),0,0)">
      %iter_471 = cute.get_iter(%slice_470) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %tup_472 = cute.deref_arith_tuple_iter(%iter_471) : !cute.arith_tuple_iter<"(?,?{div=8})">
      %e0_473, %e1_474 = cute.get_leaves(%tup_472) : !cute.int_tuple<"(?,?{div=8})">
      %171 = cute.get_scalars(%e0_473) : !cute.int_tuple<"?">
      %172 = cute.get_scalars(%e1_474) : !cute.int_tuple<"?{div=8}">
      %iter_475 = cute.get_iter(%slice_470) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %tup_476 = cute.deref_arith_tuple_iter(%iter_475) : !cute.arith_tuple_iter<"(?,?{div=8})">
      %e0_477, %e1_478 = cute.get_leaves(%tup_476) : !cute.int_tuple<"(?,?{div=8})">
      %173 = cute.get_scalars(%e0_477) : !cute.int_tuple<"?">
      %174 = cute.get_scalars(%e1_478) : !cute.int_tuple<"?{div=8}">
      %iter_479 = cute.get_iter(%slice_470) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %tup_480 = cute.deref_arith_tuple_iter(%iter_479) : !cute.arith_tuple_iter<"(?,?{div=8})">
      %e0_481, %e1_482 = cute.get_leaves(%tup_480) : !cute.int_tuple<"(?,?{div=8})">
      %175 = cute.get_scalars(%e0_481) : !cute.int_tuple<"?">
      %176 = cute.get_scalars(%e1_482) : !cute.int_tuple<"?{div=8}">
      %coord_483 = cute.make_coord(%e1_482) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_484 = cute.make_coord() : () -> !cute.coord<"4096">
      %177 = cute.elem_less(%coord_483, %coord_484) : !cute.coord<"?{div=8}">, !cute.coord<"4096">
      %178 = arith.extui %177 : i1 to i8
      %coord_485 = cute.make_coord() : () -> !cute.coord<"(7,0,0)">
      cute.memref.store(%rmem_311, %coord_485, %178) : (!memref_rmem_i8_, !cute.coord<"(7,0,0)">, i8) -> ()
      %lay_486 = cute.get_layout(%src_partitioned_89) : !memref_gmem_bf16_5
      %179 = cute.get_shape(%lay_486) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %e0_487, %e1_488, %e2_489, %e3_490 = cute.get_leaves(%179) : !cute.shape<"((8,8),1,1)">
      %lay_491 = cute.get_layout(%rmem_92) : !memref_rmem_bf16_
      %180 = cute.get_shape(%lay_491) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %e0_492, %e1_493, %e2_494, %e3_495 = cute.get_leaves(%180) : !cute.shape<"((8,8),1,1)">
      %lay_496 = cute.get_layout(%src_partitioned_89) : !memref_gmem_bf16_5
      %shape_497 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_498 = cute.make_layout(%shape_497) : !cute.layout<"1:0">
      %append = cute.append_to_rank<2> (%lay_496, %lay_498) : !cute.layout<"((8,8),1,1):((1,512),0,0)">, !cute.layout<"1:0">
      %view_499 = cute.make_view(%iter_90, %append) : !memref_gmem_bf16_5
      %iter_500 = cute.get_iter(%view_499) : !memref_gmem_bf16_5
      %lay_501 = cute.get_layout(%view_499) : !memref_gmem_bf16_5
      %181 = cute.get_shape(%lay_501) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %e0_502, %e1_503, %e2_504, %e3_505 = cute.get_leaves(%181) : !cute.shape<"((8,8),1,1)">
      %lay_506 = cute.get_layout(%view_499) : !memref_gmem_bf16_5
      %182 = cute.get_shape(%lay_506) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %e0_507, %e1_508, %e2_509, %e3_510 = cute.get_leaves(%182) : !cute.shape<"((8,8),1,1)">
      %grouped = cute.group_modes(%view_499) <1, 3> : (!memref_gmem_bf16_5) -> !memref_gmem_bf16_6
      %iter_511 = cute.get_iter(%grouped) : !memref_gmem_bf16_6
      %iter_512 = cute.get_iter(%grouped) : !memref_gmem_bf16_6
      %lay_513 = cute.get_layout(%rmem_92) : !memref_rmem_bf16_
      %shape_514 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_515 = cute.make_layout(%shape_514) : !cute.layout<"1:0">
      %append_516 = cute.append_to_rank<2> (%lay_513, %lay_515) : !cute.layout<"((8,8),1,1):((1,8),0,0)">, !cute.layout<"1:0">
      %view_517 = cute.make_view(%iter_94, %append_516) : !memref_rmem_bf16_
      %iter_518 = cute.get_iter(%view_517) : !memref_rmem_bf16_
      %lay_519 = cute.get_layout(%view_517) : !memref_rmem_bf16_
      %183 = cute.get_shape(%lay_519) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %e0_520, %e1_521, %e2_522, %e3_523 = cute.get_leaves(%183) : !cute.shape<"((8,8),1,1)">
      %lay_524 = cute.get_layout(%view_517) : !memref_rmem_bf16_
      %184 = cute.get_shape(%lay_524) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %e0_525, %e1_526, %e2_527, %e3_528 = cute.get_leaves(%184) : !cute.shape<"((8,8),1,1)">
      %grouped_529 = cute.group_modes(%view_517) <1, 3> : (!memref_rmem_bf16_) -> !memref_rmem_bf16_1
      %iter_530 = cute.get_iter(%grouped_529) : !memref_rmem_bf16_1
      %iter_531 = cute.get_iter(%grouped_529) : !memref_rmem_bf16_1
      %lay_532 = cute.get_layout(%rmem_311) : !memref_rmem_i8_
      %shape_533 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_534 = cute.make_layout(%shape_533) : !cute.layout<"1:0">
      %append_535 = cute.append_to_rank<2> (%lay_532, %lay_534) : !cute.layout<"(8,1,1):(1,0,1)">, !cute.layout<"1:0">
      %view_536 = cute.make_view(%iter_313, %append_535) : !memref_rmem_i8_
      %iter_537 = cute.get_iter(%view_536) : !memref_rmem_i8_
      %lay_538 = cute.get_layout(%view_536) : !memref_rmem_i8_
      %185 = cute.get_shape(%lay_538) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %e0_539, %e1_540, %e2_541 = cute.get_leaves(%185) : !cute.shape<"(8,1,1)">
      %lay_542 = cute.get_layout(%view_536) : !memref_rmem_i8_
      %186 = cute.get_shape(%lay_542) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %e0_543, %e1_544, %e2_545 = cute.get_leaves(%186) : !cute.shape<"(8,1,1)">
      %grouped_546 = cute.group_modes(%view_536) <1, 3> : (!memref_rmem_i8_) -> !memref_rmem_i8_1
      %iter_547 = cute.get_iter(%grouped_546) : !memref_rmem_i8_1
      %iter_548 = cute.get_iter(%grouped_546) : !memref_rmem_i8_1
      %lay_549 = cute.get_layout(%grouped) : !memref_gmem_bf16_6
      %187 = cute.get_shape(%lay_549) : (!cute.layout<"((8,8),(1,1)):((1,512),(0,0))">) -> !cute.shape<"((8,8),(1,1))">
      %e0_550, %e1_551, %e2_552, %e3_553 = cute.get_leaves(%187) : !cute.shape<"((8,8),(1,1))">
      %lay_554 = cute.get_layout(%grouped_529) : !memref_rmem_bf16_1
      %188 = cute.get_shape(%lay_554) : (!cute.layout<"((8,8),(1,1)):((1,8),(0,0))">) -> !cute.shape<"((8,8),(1,1))">
      %e0_555, %e1_556, %e2_557, %e3_558 = cute.get_leaves(%188) : !cute.shape<"((8,8),(1,1))">
      %sz_559 = cute.size(%grouped) <{mode = [1]}> : (!memref_gmem_bf16_6) -> !cute.int_tuple<"1">
      %e0_560 = cute.get_leaves(%sz_559) : !cute.int_tuple<"1">
      %sz_561 = cute.size(%grouped_529) <{mode = [1]}> : (!memref_rmem_bf16_1) -> !cute.int_tuple<"1">
      %e0_562 = cute.get_leaves(%sz_561) : !cute.int_tuple<"1">
      cute.copy(%atom_63, %grouped, %grouped_529, %grouped_546) : (!cute_nvgpu.atom.universal_copy<bf16, 128 b>, !memref_gmem_bf16_6, !memref_rmem_bf16_1, !memref_rmem_i8_1)
      nvvm.cp.async.wait.group 0
      %lay_563 = cute.get_layout(%dst_partitioned) : !memref_smem_bf16_1
      %189 = cute.get_shape(%lay_563) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %e0_564, %e1_565, %e2_566, %e3_567 = cute.get_leaves(%189) : !cute.shape<"((8,8),1,1)">
      %lay_568 = cute.get_layout(%rmem) : !memref_rmem_bf16_
      %190 = cute.get_shape(%lay_568) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %e0_569, %e1_570, %e2_571, %e3_572 = cute.get_leaves(%190) : !cute.shape<"((8,8),1,1)">
      %lay_573 = cute.get_layout(%dst_partitioned) : !memref_smem_bf16_1
      %lay_574 = cute.get_layout(%rmem) : !memref_rmem_bf16_
      %rinv = cute.right_inverse(%lay_574) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.layout<"64:1">
      %191 = cute.composition(%lay_573, %rinv) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">, !cute.layout<"64:1">) -> !cute.layout<"(8,8):(1,512)">
      %coalesce = cute.coalesce(%191) : (!cute.layout<"(8,8):(1,512)">) -> !cute.layout<"(8,8):(1,512)">
      %192 = cute.get_shape(%coalesce) : (!cute.layout<"(8,8):(1,512)">) -> !cute.shape<"(8,8)">
      %e0_575, %e1_576 = cute.get_leaves(%192) : !cute.shape<"(8,8)">
      %193 = cute.get_stride(%coalesce) : (!cute.layout<"(8,8):(1,512)">) -> !cute.stride<"(1,512)">
      %e0_577, %e1_578 = cute.get_leaves(%193) : !cute.stride<"(1,512)">
      %194 = cute.get_shape(%coalesce) : (!cute.layout<"(8,8):(1,512)">) -> !cute.shape<"(8,8)">
      %e0_579, %e1_580 = cute.get_leaves(%194) : !cute.shape<"(8,8)">
      %195 = cute.get_shape(%coalesce) : (!cute.layout<"(8,8):(1,512)">) -> !cute.shape<"(8,8)">
      %e0_581, %e1_582 = cute.get_leaves(%195) : !cute.shape<"(8,8)">
      %196 = cute.get(%coalesce) <{mode = [0]}> : !cute.layout<"(8,8):(1,512)"> -> !cute.layout<"8:1">
      %197 = cute.composition(%rinv, %196) : (!cute.layout<"64:1">, !cute.layout<"8:1">) -> !cute.layout<"8:1">
      %sz_583 = cute.size(%197) : (!cute.layout<"8:1">) -> !cute.int_tuple<"8">
      %e0_584 = cute.get_leaves(%sz_583) : !cute.int_tuple<"8">
      %lay_585 = cute.get_layout(%dst_partitioned) : !memref_smem_bf16_1
      %lay_586 = cute.get_layout(%rmem) : !memref_rmem_bf16_
      %div = cute.logical_divide(%dst_partitioned, %197) : !memref_smem_bf16_1, !cute.layout<"8:1">
      %iter_587 = cute.get_iter(%div) : !memref_smem_bf16_3
      %iter_588 = cute.get_iter(%div) : !memref_smem_bf16_3
      %div_589 = cute.logical_divide(%rmem, %197) : !memref_rmem_bf16_, !cute.layout<"8:1">
      %iter_590 = cute.get_iter(%div_589) : !memref_rmem_bf16_2
      %iter_591 = cute.get_iter(%div_589) : !memref_rmem_bf16_2
      %shape_592 = cute.make_shape() : () -> !cute.shape<"8">
      %lay_593 = cute.make_layout(%shape_592) : !cute.layout<"8:1">
      %div_594 = cute.logical_divide(%div, %lay_593) : !memref_smem_bf16_3, !cute.layout<"8:1">
      %iter_595 = cute.get_iter(%div_594) : !memref_smem_bf16_3
      %iter_596 = cute.get_iter(%div_594) : !memref_smem_bf16_3
      %shape_597 = cute.make_shape() : () -> !cute.shape<"8">
      %lay_598 = cute.make_layout(%shape_597) : !cute.layout<"8:1">
      %div_599 = cute.logical_divide(%div_589, %lay_598) : !memref_rmem_bf16_2, !cute.layout<"8:1">
      %iter_600 = cute.get_iter(%div_599) : !memref_rmem_bf16_2
      %iter_601 = cute.get_iter(%div_599) : !memref_rmem_bf16_2
      %atom_602 = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<bf16, 128 b>
      cute.copy(%atom_602, %div_594, %div_599) : (!cute_nvgpu.atom.universal_copy<bf16, 128 b>, !memref_smem_bf16_3, !memref_rmem_bf16_2)
      %lay_603 = cute.get_layout(%rmem) : !memref_rmem_bf16_
      %198 = cute.get_shape(%lay_603) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %e0_604, %e1_605, %e2_606, %e3_607 = cute.get_leaves(%198) : !cute.shape<"((8,8),1,1)">
      %199 = cute.memref.load_vec %rmem : !memref_rmem_bf16_
      %lay_608 = cute.get_layout(%rmem) : !memref_rmem_bf16_
      %200 = cute.get_shape(%lay_608) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %e0_609, %e1_610, %e2_611, %e3_612 = cute.get_leaves(%200) : !cute.shape<"((8,8),1,1)">
      %201 = arith.extf %199 : vector<64xbf16> to vector<64xf32>
      %202 = arith.mulf %201, %201 : vector<64xf32>
      %cst = arith.constant 0.000000e+00 : f32
      %203 = vector.reduction <add>, %202, %cst : vector<64xf32> into f32
      %c-1_i32 = arith.constant -1 : i32
      %c16_i32 = arith.constant 16 : i32
      %c31_i32 = arith.constant 31 : i32
      %204 = nvvm.shfl.sync  bfly %c-1_i32, %203, %c16_i32, %c31_i32 : f32 -> f32
      %205 = arith.addf %204, %203 : f32
      %c8_i32 = arith.constant 8 : i32
      %206 = nvvm.shfl.sync  bfly %c-1_i32, %205, %c8_i32, %c31_i32 : f32 -> f32
      %207 = arith.addf %205, %206 : f32
      %c4_i32 = arith.constant 4 : i32
      %208 = nvvm.shfl.sync  bfly %c-1_i32, %207, %c4_i32, %c31_i32 : f32 -> f32
      %209 = arith.addf %207, %208 : f32
      %c2_i32 = arith.constant 2 : i32
      %210 = nvvm.shfl.sync  bfly %c-1_i32, %209, %c2_i32, %c31_i32 : f32 -> f32
      %211 = arith.addf %209, %210 : f32
      %c1_i32 = arith.constant 1 : i32
      %212 = nvvm.shfl.sync  bfly %c-1_i32, %211, %c1_i32, %c31_i32 : f32 -> f32
      %213 = arith.addf %211, %212 : f32
      %214 = nvvm.read.ptx.sreg.laneid : i32
      %215 = nvvm.read.ptx.sreg.tid.x : i32
      %216 = nvvm.read.ptx.sreg.tid.y : i32
      %217 = nvvm.read.ptx.sreg.tid.z : i32
      %218 = nvvm.read.ptx.sreg.ntid.x : i32
      %219 = nvvm.read.ptx.sreg.ntid.y : i32
      %220 = arith.muli %216, %218 : i32
      %221 = arith.addi %215, %220 : i32
      %222 = arith.muli %217, %218 : i32
      %223 = arith.muli %222, %219 : i32
      %224 = arith.addi %221, %223 : i32
      %c32_i32 = arith.constant 32 : i32
      %225 = arith.floordivsi %224, %c32_i32 : i32
      %lay_613 = cute.get_layout(%view_30) : !memref_smem_f32_
      %226 = cute.get_shape(%lay_613) : (!cute.layout<"(2,2):(1,2)">) -> !cute.shape<"(2,2)">
      %e0_614, %e1_615 = cute.get_leaves(%226) : !cute.shape<"(2,2)">
      %int_tuple_616 = cute.make_int_tuple() : () -> !cute.int_tuple<"2">
      %sz_617 = cute.size(%int_tuple_616) : (!cute.int_tuple<"2">) -> !cute.int_tuple<"2">
      %e0_618 = cute.get_leaves(%sz_617) : !cute.int_tuple<"2">
      %c2_i32_619 = arith.constant 2 : i32
      %227 = arith.floordivsi %225, %c2_i32_619 : i32
      %228 = arith.remsi %225, %c2_i32_619 : i32
      %c0_i32 = arith.constant 0 : i32
      %229 = arith.cmpi eq, %214, %c0_i32 : i32
      %230 = scf.if %229 -> (!memref_smem_f32_) {
        %iter_713 = cute.get_iter(%view_30) : !memref_smem_f32_
        %coord_714 = cute.make_coord(%227, %228) : (i32, i32) -> !cute.coord<"(?,?)">
        cute.memref.store(%view_30, %coord_714, %213) : (!memref_smem_f32_, !cute.coord<"(?,?)">, f32) -> ()
        scf.yield %view_30 : !memref_smem_f32_
      } else {
        %iter_713 = cute.get_iter(%view_30) : !memref_smem_f32_
        scf.yield %view_30 : !memref_smem_f32_
      }
      %iter_620 = cute.get_iter(%230) : !memref_smem_f32_
      %iter_621 = cute.get_iter(%230) : !memref_smem_f32_
      %iter_622 = cute.get_iter(%230) : !memref_smem_f32_
      %c0_i32_623 = arith.constant 0 : i32
      llvm.inline_asm has_side_effects asm_dialect = att "bar.sync $0;", "r" %c0_i32_623 : (i32) -> ()
      %231 = arith.cmpi slt, %214, %c2_i32_619 : i32
      %cst_624 = arith.constant 0.000000e+00 : f32
      %232 = scf.if %231 -> (f32) {
        %coord_713 = cute.make_coord(%227, %214) : (i32, i32) -> !cute.coord<"(?,?)">
        %269 = cute.memref.load(%230, %coord_713) : (!memref_smem_f32_, !cute.coord<"(?,?)">) -> f32
        scf.yield %269 : f32
      } else {
        scf.yield %cst_624 : f32
      }
      %c-1_i32_625 = arith.constant -1 : i32
      %c16_i32_626 = arith.constant 16 : i32
      %c31_i32_627 = arith.constant 31 : i32
      %233 = nvvm.shfl.sync  bfly %c-1_i32_625, %232, %c16_i32_626, %c31_i32_627 : f32 -> f32
      %234 = arith.addf %232, %233 : f32
      %c8_i32_628 = arith.constant 8 : i32
      %235 = nvvm.shfl.sync  bfly %c-1_i32_625, %234, %c8_i32_628, %c31_i32_627 : f32 -> f32
      %236 = arith.addf %234, %235 : f32
      %c4_i32_629 = arith.constant 4 : i32
      %237 = nvvm.shfl.sync  bfly %c-1_i32_625, %236, %c4_i32_629, %c31_i32_627 : f32 -> f32
      %238 = arith.addf %236, %237 : f32
      %c2_i32_630 = arith.constant 2 : i32
      %239 = nvvm.shfl.sync  bfly %c-1_i32_625, %238, %c2_i32_630, %c31_i32_627 : f32 -> f32
      %240 = arith.addf %238, %239 : f32
      %c1_i32_631 = arith.constant 1 : i32
      %241 = nvvm.shfl.sync  bfly %c-1_i32_625, %240, %c1_i32_631, %c31_i32_627 : f32 -> f32
      %242 = arith.addf %240, %241 : f32
      %cst_632 = arith.constant 4.096000e+03 : f32
      %243 = arith.divf %242, %cst_632 : f32
      %244 = arith.addf %243, %arg3 : f32
      %245 = math.rsqrt %244 fastmath<fast> : f32
      %c0_i32_633 = arith.constant 0 : i32
      llvm.inline_asm has_side_effects asm_dialect = att "bar.sync $0;", "r" %c0_i32_633 : (i32) -> ()
      %lay_634 = cute.get_layout(%dst_partitioned) : !memref_smem_bf16_1
      %246 = cute.get_shape(%lay_634) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %e0_635, %e1_636, %e2_637, %e3_638 = cute.get_leaves(%246) : !cute.shape<"((8,8),1,1)">
      %lay_639 = cute.get_layout(%rmem) : !memref_rmem_bf16_
      %247 = cute.get_shape(%lay_639) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %e0_640, %e1_641, %e2_642, %e3_643 = cute.get_leaves(%247) : !cute.shape<"((8,8),1,1)">
      %lay_644 = cute.get_layout(%dst_partitioned) : !memref_smem_bf16_1
      %lay_645 = cute.get_layout(%rmem) : !memref_rmem_bf16_
      %rinv_646 = cute.right_inverse(%lay_645) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.layout<"64:1">
      %248 = cute.composition(%lay_644, %rinv_646) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">, !cute.layout<"64:1">) -> !cute.layout<"(8,8):(1,512)">
      %coalesce_647 = cute.coalesce(%248) : (!cute.layout<"(8,8):(1,512)">) -> !cute.layout<"(8,8):(1,512)">
      %249 = cute.get_shape(%coalesce_647) : (!cute.layout<"(8,8):(1,512)">) -> !cute.shape<"(8,8)">
      %e0_648, %e1_649 = cute.get_leaves(%249) : !cute.shape<"(8,8)">
      %250 = cute.get_stride(%coalesce_647) : (!cute.layout<"(8,8):(1,512)">) -> !cute.stride<"(1,512)">
      %e0_650, %e1_651 = cute.get_leaves(%250) : !cute.stride<"(1,512)">
      %251 = cute.get_shape(%coalesce_647) : (!cute.layout<"(8,8):(1,512)">) -> !cute.shape<"(8,8)">
      %e0_652, %e1_653 = cute.get_leaves(%251) : !cute.shape<"(8,8)">
      %252 = cute.get_shape(%coalesce_647) : (!cute.layout<"(8,8):(1,512)">) -> !cute.shape<"(8,8)">
      %e0_654, %e1_655 = cute.get_leaves(%252) : !cute.shape<"(8,8)">
      %253 = cute.get(%coalesce_647) <{mode = [0]}> : !cute.layout<"(8,8):(1,512)"> -> !cute.layout<"8:1">
      %254 = cute.composition(%rinv_646, %253) : (!cute.layout<"64:1">, !cute.layout<"8:1">) -> !cute.layout<"8:1">
      %sz_656 = cute.size(%254) : (!cute.layout<"8:1">) -> !cute.int_tuple<"8">
      %e0_657 = cute.get_leaves(%sz_656) : !cute.int_tuple<"8">
      %lay_658 = cute.get_layout(%dst_partitioned) : !memref_smem_bf16_1
      %lay_659 = cute.get_layout(%rmem) : !memref_rmem_bf16_
      %div_660 = cute.logical_divide(%dst_partitioned, %254) : !memref_smem_bf16_1, !cute.layout<"8:1">
      %iter_661 = cute.get_iter(%div_660) : !memref_smem_bf16_3
      %iter_662 = cute.get_iter(%div_660) : !memref_smem_bf16_3
      %div_663 = cute.logical_divide(%rmem, %254) : !memref_rmem_bf16_, !cute.layout<"8:1">
      %iter_664 = cute.get_iter(%div_663) : !memref_rmem_bf16_2
      %iter_665 = cute.get_iter(%div_663) : !memref_rmem_bf16_2
      %shape_666 = cute.make_shape() : () -> !cute.shape<"8">
      %lay_667 = cute.make_layout(%shape_666) : !cute.layout<"8:1">
      %div_668 = cute.logical_divide(%div_660, %lay_667) : !memref_smem_bf16_3, !cute.layout<"8:1">
      %iter_669 = cute.get_iter(%div_668) : !memref_smem_bf16_3
      %iter_670 = cute.get_iter(%div_668) : !memref_smem_bf16_3
      %shape_671 = cute.make_shape() : () -> !cute.shape<"8">
      %lay_672 = cute.make_layout(%shape_671) : !cute.layout<"8:1">
      %div_673 = cute.logical_divide(%div_663, %lay_672) : !memref_rmem_bf16_2, !cute.layout<"8:1">
      %iter_674 = cute.get_iter(%div_673) : !memref_rmem_bf16_2
      %iter_675 = cute.get_iter(%div_673) : !memref_rmem_bf16_2
      %atom_676 = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<bf16, 128 b>
      cute.copy(%atom_676, %div_668, %div_673) : (!cute_nvgpu.atom.universal_copy<bf16, 128 b>, !memref_smem_bf16_3, !memref_rmem_bf16_2)
      %lay_677 = cute.get_layout(%rmem) : !memref_rmem_bf16_
      %255 = cute.get_shape(%lay_677) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %e0_678, %e1_679, %e2_680, %e3_681 = cute.get_leaves(%255) : !cute.shape<"((8,8),1,1)">
      %256 = cute.memref.load_vec %rmem : !memref_rmem_bf16_
      %lay_682 = cute.get_layout(%rmem) : !memref_rmem_bf16_
      %257 = cute.get_shape(%lay_682) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %e0_683, %e1_684, %e2_685, %e3_686 = cute.get_leaves(%257) : !cute.shape<"((8,8),1,1)">
      %258 = arith.extf %256 : vector<64xbf16> to vector<64xf32>
      %259 = vector.broadcast %245 : f32 to vector<64xf32>
      %260 = arith.mulf %258, %259 : vector<64xf32>
      %lay_687 = cute.get_layout(%retiled) : !memref_rmem_bf16_
      %261 = cute.get_shape(%lay_687) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %e0_688, %e1_689, %e2_690, %e3_691 = cute.get_leaves(%261) : !cute.shape<"((8,8),1,1)">
      %262 = cute.memref.load_vec %retiled : !memref_rmem_bf16_
      %lay_692 = cute.get_layout(%retiled) : !memref_rmem_bf16_
      %263 = cute.get_shape(%lay_692) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %e0_693, %e1_694, %e2_695, %e3_696 = cute.get_leaves(%263) : !cute.shape<"((8,8),1,1)">
      %264 = arith.extf %262 : vector<64xbf16> to vector<64xf32>
      %265 = arith.mulf %260, %264 : vector<64xf32>
      %266 = arith.truncf %265 : vector<64xf32> to vector<64xbf16>
      %lay_697 = cute.get_layout(%rmem_85) : !memref_rmem_bf16_
      %267 = cute.get_shape(%lay_697) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %e0_698, %e1_699, %e2_700, %e3_701 = cute.get_leaves(%267) : !cute.shape<"((8,8),1,1)">
      %lay_702 = cute.get_layout(%rmem_85) : !memref_rmem_bf16_
      %268 = cute.get_shape(%lay_702) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %e0_703, %e1_704, %e2_705, %e3_706 = cute.get_leaves(%268) : !cute.shape<"((8,8),1,1)">
      %int_tuple_707 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,8),1,1)">
      %sz_708 = cute.size(%int_tuple_707) : (!cute.int_tuple<"((8,8),1,1)">) -> !cute.int_tuple<"64">
      %e0_709 = cute.get_leaves(%sz_708) : !cute.int_tuple<"64">
      %int_tuple_710 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,8),1,1)">
      %sz_711 = cute.size(%int_tuple_710) : (!cute.int_tuple<"((8,8),1,1)">) -> !cute.int_tuple<"64">
      %e0_712 = cute.get_leaves(%sz_711) : !cute.int_tuple<"64">
      cute.memref.store_vec %266, %rmem_85 : !memref_rmem_bf16_
      scf.if %103 {
        %lay_713 = cute.get_layout(%rmem_85) : !memref_rmem_bf16_
        %269 = cute.get_shape(%lay_713) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %e0_714, %e1_715, %e2_716, %e3_717 = cute.get_leaves(%269) : !cute.shape<"((8,8),1,1)">
        %lay_718 = cute.get_layout(%dst_partitioned_73) : !memref_gmem_bf16_5
        %270 = cute.get_shape(%lay_718) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %e0_719, %e1_720, %e2_721, %e3_722 = cute.get_leaves(%270) : !cute.shape<"((8,8),1,1)">
        %lay_723 = cute.get_layout(%rmem_85) : !memref_rmem_bf16_
        %shape_724 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_725 = cute.make_layout(%shape_724) : !cute.layout<"1:0">
        %append_726 = cute.append_to_rank<2> (%lay_723, %lay_725) : !cute.layout<"((8,8),1,1):((1,8),0,0)">, !cute.layout<"1:0">
        %view_727 = cute.make_view(%iter_87, %append_726) : !memref_rmem_bf16_
        %iter_728 = cute.get_iter(%view_727) : !memref_rmem_bf16_
        %lay_729 = cute.get_layout(%view_727) : !memref_rmem_bf16_
        %271 = cute.get_shape(%lay_729) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %e0_730, %e1_731, %e2_732, %e3_733 = cute.get_leaves(%271) : !cute.shape<"((8,8),1,1)">
        %lay_734 = cute.get_layout(%view_727) : !memref_rmem_bf16_
        %272 = cute.get_shape(%lay_734) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %e0_735, %e1_736, %e2_737, %e3_738 = cute.get_leaves(%272) : !cute.shape<"((8,8),1,1)">
        %grouped_739 = cute.group_modes(%view_727) <1, 3> : (!memref_rmem_bf16_) -> !memref_rmem_bf16_1
        %iter_740 = cute.get_iter(%grouped_739) : !memref_rmem_bf16_1
        %iter_741 = cute.get_iter(%grouped_739) : !memref_rmem_bf16_1
        %lay_742 = cute.get_layout(%dst_partitioned_73) : !memref_gmem_bf16_5
        %shape_743 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_744 = cute.make_layout(%shape_743) : !cute.layout<"1:0">
        %append_745 = cute.append_to_rank<2> (%lay_742, %lay_744) : !cute.layout<"((8,8),1,1):((1,512),0,0)">, !cute.layout<"1:0">
        %view_746 = cute.make_view(%iter_74, %append_745) : !memref_gmem_bf16_5
        %iter_747 = cute.get_iter(%view_746) : !memref_gmem_bf16_5
        %lay_748 = cute.get_layout(%view_746) : !memref_gmem_bf16_5
        %273 = cute.get_shape(%lay_748) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %e0_749, %e1_750, %e2_751, %e3_752 = cute.get_leaves(%273) : !cute.shape<"((8,8),1,1)">
        %lay_753 = cute.get_layout(%view_746) : !memref_gmem_bf16_5
        %274 = cute.get_shape(%lay_753) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %e0_754, %e1_755, %e2_756, %e3_757 = cute.get_leaves(%274) : !cute.shape<"((8,8),1,1)">
        %grouped_758 = cute.group_modes(%view_746) <1, 3> : (!memref_gmem_bf16_5) -> !memref_gmem_bf16_6
        %iter_759 = cute.get_iter(%grouped_758) : !memref_gmem_bf16_6
        %iter_760 = cute.get_iter(%grouped_758) : !memref_gmem_bf16_6
        %lay_761 = cute.get_layout(%rmem_106) : !memref_rmem_i8_
        %shape_762 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_763 = cute.make_layout(%shape_762) : !cute.layout<"1:0">
        %append_764 = cute.append_to_rank<2> (%lay_761, %lay_763) : !cute.layout<"(8,1,1):(1,0,1)">, !cute.layout<"1:0">
        %view_765 = cute.make_view(%iter_108, %append_764) : !memref_rmem_i8_
        %iter_766 = cute.get_iter(%view_765) : !memref_rmem_i8_
        %lay_767 = cute.get_layout(%view_765) : !memref_rmem_i8_
        %275 = cute.get_shape(%lay_767) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
        %e0_768, %e1_769, %e2_770 = cute.get_leaves(%275) : !cute.shape<"(8,1,1)">
        %lay_771 = cute.get_layout(%view_765) : !memref_rmem_i8_
        %276 = cute.get_shape(%lay_771) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
        %e0_772, %e1_773, %e2_774 = cute.get_leaves(%276) : !cute.shape<"(8,1,1)">
        %grouped_775 = cute.group_modes(%view_765) <1, 3> : (!memref_rmem_i8_) -> !memref_rmem_i8_1
        %iter_776 = cute.get_iter(%grouped_775) : !memref_rmem_i8_1
        %iter_777 = cute.get_iter(%grouped_775) : !memref_rmem_i8_1
        %lay_778 = cute.get_layout(%grouped_739) : !memref_rmem_bf16_1
        %277 = cute.get_shape(%lay_778) : (!cute.layout<"((8,8),(1,1)):((1,8),(0,0))">) -> !cute.shape<"((8,8),(1,1))">
        %e0_779, %e1_780, %e2_781, %e3_782 = cute.get_leaves(%277) : !cute.shape<"((8,8),(1,1))">
        %lay_783 = cute.get_layout(%grouped_758) : !memref_gmem_bf16_6
        %278 = cute.get_shape(%lay_783) : (!cute.layout<"((8,8),(1,1)):((1,512),(0,0))">) -> !cute.shape<"((8,8),(1,1))">
        %e0_784, %e1_785, %e2_786, %e3_787 = cute.get_leaves(%278) : !cute.shape<"((8,8),(1,1))">
        %sz_788 = cute.size(%grouped_739) <{mode = [1]}> : (!memref_rmem_bf16_1) -> !cute.int_tuple<"1">
        %e0_789 = cute.get_leaves(%sz_788) : !cute.int_tuple<"1">
        %sz_790 = cute.size(%grouped_758) <{mode = [1]}> : (!memref_gmem_bf16_6) -> !cute.int_tuple<"1">
        %e0_791 = cute.get_leaves(%sz_790) : !cute.int_tuple<"1">
        cute.copy(%atom_64, %grouped_739, %grouped_758, %grouped_775) : (!cute_nvgpu.atom.universal_copy<bf16, 128 b>, !memref_rmem_bf16_1, !memref_gmem_bf16_6, !memref_rmem_i8_1)
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
    %lay_14 = cute.get_layout(%view_8) : !memref_gmem_bf16_1
    %lay_15 = cute.get_layout(%view_3) : !memref_gmem_bf16_
    %c16400_i32 = arith.constant 16400 : i32
    %1 = arith.extsi %c16400_i32 : i32 to i64
    %c128_i32 = arith.constant 128 : i32
    %c1_i32 = arith.constant 1 : i32
    %2 = cuda.launch_cfg.create<max_attrs = 3 : i32> (blockDim = (%c128_i32, %c1_i32, %c1_i32), dynamicSmemBytes = %1, gridDim = (%0, %c1_i32, %c1_i32), stream = %arg5) : i32, i32, i32, i64, i32, i32, i32, !cuda.stream -> !cuda.launch_cfg<max_attrs = 3>
    %c0_i32 = arith.constant 0 : i32
    cuda.launch_cfg.programmatic_stream_serialization_allowed[%2] %c0_i32 : !cuda.launch_cfg<max_attrs = 3>, i32
    %c0_i32_16 = arith.constant 0 : i32
    cuda.launch_cfg.cooperative[%2] %c0_i32_16 : !cuda.launch_cfg<max_attrs = 3>, i32
    %3 = cuda.launch_ex @kernels::@kernel_cutlass_kernel___main__RMSNormKernel_object_at__tensorptrbf16gmemalign16o409640961_tensorptrbf16_gmem_align16_o_40961_tensorptrbf16gmemalign16o409640961__2_4096_0<%2> (%view, %view_8, %view_3, %arg4, %lay_12) {assume_kernel_attr = #cuda.assume_kernel_attr<true>} : !cuda.launch_cfg<max_attrs = 3>, (!memref_gmem_bf16_, !memref_gmem_bf16_1, !memref_gmem_bf16_, f32, !cute.layout<"((64,2),(8,8)):((16,1),(2,1024))">) -> !cuda.result
    %4 = cuda.cast %3 : !cuda.result -> i32
    cuda.return_if_error %4 : i32
    %c0_i32_17 = arith.constant 0 : i32
    return %c0_i32_17 : i32
  }
}

