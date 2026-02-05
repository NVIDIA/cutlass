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
      %iter_46 = cute.recast_iter(%ptr) : !cute.ptr<i8, smem, align<1024>> to !cute.ptr<f32, smem, align<1024>>
      %view_47 = cute.make_view(%iter_46, %lay_37) : !memref_smem_f32_
      %iter_48 = cute.get_iter(%view_47) : !memref_smem_f32_
      %shape_49 = cute.make_shape(%itup_25) : (!cute.int_tuple<"?">) -> !cute.shape<"(?,4096)">
      %int_tuple_50 = cute.make_int_tuple() : () -> !cute.int_tuple<"(0,0)">
      %stride = cute.make_stride() : () -> !cute.stride<"(1@0,1@1)">
      %lay_51 = cute.make_layout(%shape_49, %stride) : !cute.layout<"(?,4096):(1@0,1@1)">
      %view_52 = cute.make_view(%int_tuple_50, %lay_51) : !cute.coord_tensor<"(0,0)", "(?,4096):(1@0,1@1)">
      %iter_53 = cute.get_iter(%view_52) : !cute.coord_tensor<"(0,0)", "(?,4096):(1@0,1@1)">
      %e0_54, %e1_55 = cute.get_leaves(%iter_53) : !cute.int_tuple<"(0,0)">
      %tile = cute.make_tile() : () -> !cute.tile<"[2:1;4096:1]">
      %coord_56 = cute.make_coord(%14) : (i32) -> !cute.coord<"(?,0)">
      %22 = cute.get_scalars(%coord_56) <{only_dynamic}> : !cute.coord<"(?,0)">
      %coord_57 = cute.make_coord(%22) : (i32) -> !cute.coord<"((_,_),(?,0))">
      %lay_58 = cute.get_layout(%arg0) : !memref_gmem_bf16_
      %23 = cute.get_scalars(%lay_58) <{only_dynamic}> : !cute.layout<"(?,4096):(4096,1)">
      %c2_i32 = arith.constant 2 : i32
      %24 = arith.ceildivsi %23, %c2_i32 : i32
      %shape_59 = cute.make_shape(%24) : (i32) -> !cute.shape<"((2,4096),(?,1))">
      %stride_60 = cute.make_stride() : () -> !cute.stride<"((4096,1),(8192,0))">
      %lay_61 = cute.make_layout(%shape_59, %stride_60) : !cute.layout<"((2,4096),(?,1)):((4096,1),(8192,0))">
      %idx_62 = cute.crd2idx(%coord_57, %lay_61) : (!cute.coord<"((_,_),(?,0))">, !cute.layout<"((2,4096),(?,1)):((4096,1),(8192,0))">) -> !cute.int_tuple<"?{div=8192}">
      %iter_63 = cute.get_iter(%arg0) : !memref_gmem_bf16_
      %ptr_64 = cute.add_offset(%iter_63, %idx_62) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<bf16, gmem, align<16>>
      %view_65 = cute.make_view(%ptr_64) : !memref_gmem_bf16_2
      %iter_66 = cute.get_iter(%view_65) : !memref_gmem_bf16_2
      %tile_67 = cute.make_tile() : () -> !cute.tile<"[2:1;4096:1]">
      %coord_68 = cute.make_coord(%14) : (i32) -> !cute.coord<"(?,0)">
      %25 = cute.get_scalars(%coord_68) <{only_dynamic}> : !cute.coord<"(?,0)">
      %coord_69 = cute.make_coord(%25) : (i32) -> !cute.coord<"((_,_),(?,0))">
      %lay_70 = cute.get_layout(%arg2) : !memref_gmem_bf16_
      %26 = cute.get_scalars(%lay_70) <{only_dynamic}> : !cute.layout<"(?,4096):(4096,1)">
      %c2_i32_71 = arith.constant 2 : i32
      %27 = arith.ceildivsi %26, %c2_i32_71 : i32
      %shape_72 = cute.make_shape(%27) : (i32) -> !cute.shape<"((2,4096),(?,1))">
      %stride_73 = cute.make_stride() : () -> !cute.stride<"((4096,1),(8192,0))">
      %lay_74 = cute.make_layout(%shape_72, %stride_73) : !cute.layout<"((2,4096),(?,1)):((4096,1),(8192,0))">
      %idx_75 = cute.crd2idx(%coord_69, %lay_74) : (!cute.coord<"((_,_),(?,0))">, !cute.layout<"((2,4096),(?,1)):((4096,1),(8192,0))">) -> !cute.int_tuple<"?{div=8192}">
      %iter_76 = cute.get_iter(%arg2) : !memref_gmem_bf16_
      %ptr_77 = cute.add_offset(%iter_76, %idx_75) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=8192}">) -> !cute.ptr<bf16, gmem, align<16>>
      %view_78 = cute.make_view(%ptr_77) : !memref_gmem_bf16_2
      %iter_79 = cute.get_iter(%view_78) : !memref_gmem_bf16_2
      %tile_80 = cute.make_tile() : () -> !cute.tile<"[2:1;4096:1]">
      %coord_81 = cute.make_coord(%14) : (i32) -> !cute.coord<"(?,0)">
      %28 = cute.get_scalars(%coord_81) <{only_dynamic}> : !cute.coord<"(?,0)">
      %coord_82 = cute.make_coord(%28) : (i32) -> !cute.coord<"((_,_),(?,0))">
      %lay_83 = cute.get_layout(%view_52) : !cute.coord_tensor<"(0,0)", "(?,4096):(1@0,1@1)">
      %29 = cute.get_scalars(%lay_83) <{only_dynamic}> : !cute.layout<"(?,4096):(1@0,1@1)">
      %c2_i32_84 = arith.constant 2 : i32
      %30 = arith.ceildivsi %29, %c2_i32_84 : i32
      %shape_85 = cute.make_shape(%30) : (i32) -> !cute.shape<"((2,4096),(?,1))">
      %stride_86 = cute.make_stride() : () -> !cute.stride<"((1@0,1@1),(2@0,0))">
      %lay_87 = cute.make_layout(%shape_85, %stride_86) : !cute.layout<"((2,4096),(?,1)):((1@0,1@1),(2@0,0))">
      %idx_88 = cute.crd2idx(%coord_82, %lay_87) : (!cute.coord<"((_,_),(?,0))">, !cute.layout<"((2,4096),(?,1)):((1@0,1@1),(2@0,0))">) -> !cute.int_tuple<"(?{div=2},0)">
      %iter_89 = cute.get_iter(%view_52) : !cute.coord_tensor<"(0,0)", "(?,4096):(1@0,1@1)">
      %tup = cute.add_offset(%iter_89, %idx_88) : (!cute.int_tuple<"(0,0)">, !cute.int_tuple<"(?{div=2},0)">) -> !cute.int_tuple<"(?{div=2},0)">
      %view_90 = cute.make_view(%tup) : !cute.coord_tensor<"(?{div=2},0)", "(2,4096):(1@0,1@1)">
      %iter_91 = cute.get_iter(%view_90) : !cute.coord_tensor<"(?{div=2},0)", "(2,4096):(1@0,1@1)">
      %e0_92, %e1_93 = cute.get_leaves(%iter_91) : !cute.int_tuple<"(?{div=2},0)">
      %31 = cute.get_scalars(%e0_92) : !cute.int_tuple<"?{div=2}">
      %lay_94 = cute.get_layout(%arg1) : !memref_gmem_bf16_1
      %shape_95 = cute.make_shape() : () -> !cute.shape<"(2)">
      %stride_96 = cute.make_stride() : () -> !cute.stride<"(0)">
      %lay_97 = cute.make_layout() : !cute.layout<"(2):(0)">
      %32 = cute.get_shape(%lay_94) : (!cute.layout<"(4096):(1)">) -> !cute.shape<"(4096)">
      %e0_98 = cute.get_leaves(%32) : !cute.shape<"(4096)">
      %prepend = cute.prepend_to_rank<2> (%lay_94, %lay_97) : !cute.layout<"(4096):(1)">, !cute.layout<"(2):(0)">
      %view_99 = cute.make_view(%iter_3, %prepend) : !memref_gmem_bf16_3
      %iter_100 = cute.get_iter(%view_99) : !memref_gmem_bf16_3
      %tile_101 = cute.make_tile() : () -> !cute.tile<"[2:1;4096:1]">
      %coord_102 = cute.make_coord() : () -> !cute.coord<"(0,0)">
      %coord_103 = cute.make_coord() : () -> !cute.coord<"((_,_),(0,0))">
      %lay_104 = cute.get_layout(%view_99) : !memref_gmem_bf16_3
      %lay_105 = cute.make_layout() : !cute.layout<"((2,4096),(1,1)):((0,1),(0,0))">
      %idx_106 = cute.crd2idx(%coord_103, %lay_105) : (!cute.coord<"((_,_),(0,0))">, !cute.layout<"((2,4096),(1,1)):((0,1),(0,0))">) -> !cute.int_tuple<"0">
      %iter_107 = cute.get_iter(%view_99) : !memref_gmem_bf16_3
      %ptr_108 = cute.add_offset(%iter_107, %idx_106) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, gmem, align<16>>
      %view_109 = cute.make_view(%ptr_108) : !memref_gmem_bf16_4
      %iter_110 = cute.get_iter(%view_109) : !memref_gmem_bf16_4
      %atom = cute.make_atom() : () -> !cute_nvgpu.atom.simt_async_copy<bf16, cache = always, 128 b>
      %atom_111 = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<bf16, 128 b>
      %atom_112 = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<bf16, 128 b>
      %tile_113 = cute.make_tile() : () -> !cute.tile<"[2:1;4096:1]">
      %33 = cute.make_tiled_copy(%atom) : !copy_ldgsts
      %tile_114 = cute.make_tile() : () -> !cute.tile<"[2:1;4096:1]">
      %34 = cute.make_tiled_copy(%atom_111) : !copy_simt
      %tile_115 = cute.make_tile() : () -> !cute.tile<"[2:1;4096:1]">
      %35 = cute.make_tiled_copy(%atom_112) : !copy_simt
      %coord_116 = cute.make_coord(%11) : (i32) -> !cute.coord<"?">
      %iter_117 = cute.get_iter(%view_65) : !memref_gmem_bf16_2
      %36 = cute.get_scalars(%coord_116) <{only_dynamic}> : !cute.coord<"?">
      %c64_i32 = arith.constant 64 : i32
      %37 = arith.divsi %36, %c64_i32 : i32
      %c64_i32_118 = arith.constant 64 : i32
      %38 = arith.remsi %36, %c64_i32_118 : i32
      %c8_i32 = arith.constant 8 : i32
      %39 = arith.muli %38, %c8_i32 : i32
      %c4096_i32 = arith.constant 4096 : i32
      %40 = arith.muli %37, %c4096_i32 : i32
      %41 = arith.addi %39, %40 : i32
      %iv = cute.assume(%41) : (i32) -> !cute.i32<divby 8>
      %int_tuple_119 = cute.make_int_tuple(%iv) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %ptr_120 = cute.add_offset(%iter_117, %int_tuple_119) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %view_121 = cute.make_view(%ptr_120) : !memref_gmem_bf16_5
      %iter_122 = cute.get_iter(%view_121) : !memref_gmem_bf16_5
      %coord_123 = cute.make_coord(%11) : (i32) -> !cute.coord<"?">
      %iter_124 = cute.get_iter(%view) : !memref_smem_bf16_
      %42 = cute.get_scalars(%coord_123) <{only_dynamic}> : !cute.coord<"?">
      %c64_i32_125 = arith.constant 64 : i32
      %43 = arith.divsi %42, %c64_i32_125 : i32
      %c64_i32_126 = arith.constant 64 : i32
      %44 = arith.remsi %42, %c64_i32_126 : i32
      %c8_i32_127 = arith.constant 8 : i32
      %45 = arith.muli %44, %c8_i32_127 : i32
      %c4096_i32_128 = arith.constant 4096 : i32
      %46 = arith.muli %43, %c4096_i32_128 : i32
      %47 = arith.addi %45, %46 : i32
      %iv_129 = cute.assume(%47) : (i32) -> !cute.i32<divby 8>
      %int_tuple_130 = cute.make_int_tuple(%iv_129) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %ptr_131 = cute.add_offset(%iter_124, %int_tuple_130) : (!cute.ptr<bf16, smem, align<1024>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, smem, align<16>>
      %view_132 = cute.make_view(%ptr_131) : !memref_smem_bf16_1
      %iter_133 = cute.get_iter(%view_132) : !memref_smem_bf16_1
      %coord_134 = cute.make_coord(%11) : (i32) -> !cute.coord<"?">
      %iter_135 = cute.get_iter(%view_78) : !memref_gmem_bf16_2
      %48 = cute.get_scalars(%coord_134) <{only_dynamic}> : !cute.coord<"?">
      %c64_i32_136 = arith.constant 64 : i32
      %49 = arith.divsi %48, %c64_i32_136 : i32
      %c64_i32_137 = arith.constant 64 : i32
      %50 = arith.remsi %48, %c64_i32_137 : i32
      %c8_i32_138 = arith.constant 8 : i32
      %51 = arith.muli %50, %c8_i32_138 : i32
      %c4096_i32_139 = arith.constant 4096 : i32
      %52 = arith.muli %49, %c4096_i32_139 : i32
      %53 = arith.addi %51, %52 : i32
      %iv_140 = cute.assume(%53) : (i32) -> !cute.i32<divby 8>
      %int_tuple_141 = cute.make_int_tuple(%iv_140) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %ptr_142 = cute.add_offset(%iter_135, %int_tuple_141) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %view_143 = cute.make_view(%ptr_142) : !memref_gmem_bf16_5
      %iter_144 = cute.get_iter(%view_143) : !memref_gmem_bf16_5
      %coord_145 = cute.make_coord(%11) : (i32) -> !cute.coord<"?">
      %iter_146 = cute.get_iter(%view_90) : !cute.coord_tensor<"(?{div=2},0)", "(2,4096):(1@0,1@1)">
      %54 = cute.get_scalars(%coord_145) <{only_dynamic}> : !cute.coord<"?">
      %c64_i32_147 = arith.constant 64 : i32
      %55 = arith.divsi %54, %c64_i32_147 : i32
      %c64_i32_148 = arith.constant 64 : i32
      %56 = arith.remsi %54, %c64_i32_148 : i32
      %c8_i32_149 = arith.constant 8 : i32
      %57 = arith.muli %56, %c8_i32_149 : i32
      %iv_150 = cute.assume(%57) : (i32) -> !cute.i32<divby 8>
      %int_tuple_151 = cute.make_int_tuple(%55, %iv_150) : (i32, !cute.i32<divby 8>) -> !cute.int_tuple<"(?,?{div=8})">
      %tup_152 = cute.add_offset(%iter_146, %int_tuple_151) : (!cute.int_tuple<"(?{div=2},0)">, !cute.int_tuple<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %view_153 = cute.make_view(%tup_152) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %iter_154 = cute.get_iter(%view_153) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %e0_155, %e1_156 = cute.get_leaves(%iter_154) : !cute.int_tuple<"(?,?{div=8})">
      %58 = cute.get_scalars(%e0_155) : !cute.int_tuple<"?">
      %59 = cute.get_scalars(%e1_156) : !cute.int_tuple<"?{div=8}">
      %lay_157 = cute.get_layout(%view_121) : !memref_gmem_bf16_5
      %lay_158 = cute.make_layout() : !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %rmem = cute.memref.alloca(%lay_158) : !memref_rmem_bf16_
      %iter_159 = cute.get_iter(%rmem) : !memref_rmem_bf16_
      %iter_160 = cute.get_iter(%rmem) : !memref_rmem_bf16_
      %lay_161 = cute.get_layout(%view_143) : !memref_gmem_bf16_5
      %lay_162 = cute.make_layout() : !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %rmem_163 = cute.memref.alloca(%lay_162) : !memref_rmem_bf16_
      %iter_164 = cute.get_iter(%rmem_163) : !memref_rmem_bf16_
      %iter_165 = cute.get_iter(%rmem_163) : !memref_rmem_bf16_
      %coord_166 = cute.make_coord(%11) : (i32) -> !cute.coord<"?">
      %iter_167 = cute.get_iter(%view_109) : !memref_gmem_bf16_4
      %60 = cute.get_scalars(%coord_166) <{only_dynamic}> : !cute.coord<"?">
      %c64_i32_168 = arith.constant 64 : i32
      %61 = arith.divsi %60, %c64_i32_168 : i32
      %c64_i32_169 = arith.constant 64 : i32
      %62 = arith.remsi %60, %c64_i32_169 : i32
      %c8_i32_170 = arith.constant 8 : i32
      %63 = arith.muli %62, %c8_i32_170 : i32
      %iv_171 = cute.assume(%63) : (i32) -> !cute.i32<divby 8>
      %int_tuple_172 = cute.make_int_tuple(%iv_171) : (!cute.i32<divby 8>) -> !cute.int_tuple<"?{div=8}">
      %ptr_173 = cute.add_offset(%iter_167, %int_tuple_172) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, gmem, align<16>>
      %view_174 = cute.make_view(%ptr_173) : !memref_gmem_bf16_5
      %iter_175 = cute.get_iter(%view_174) : !memref_gmem_bf16_5
      %lay_176 = cute.get_layout(%view_174) : !memref_gmem_bf16_5
      %lay_177 = cute.make_layout() : !cute.layout<"((8,8),1,1):((1,8),0,0)">
      %rmem_178 = cute.memref.alloca(%lay_177) : !memref_rmem_bf16_
      %iter_179 = cute.get_iter(%rmem_178) : !memref_rmem_bf16_
      %iter_180 = cute.get_iter(%rmem_178) : !memref_rmem_bf16_
      %iter_181 = cute.get_iter(%rmem_178) : !memref_rmem_bf16_
      %view_182 = cute.make_view(%iter_181) : !memref_rmem_bf16_
      %iter_183 = cute.get_iter(%view_182) : !memref_rmem_bf16_
      %lay_184 = cute.get_layout(%view_153) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %sz = cute.size(%lay_184) <{mode = [0, 1]}> : (!cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"8">
      %e0_185 = cute.get_leaves(%sz) : !cute.int_tuple<"8">
      %lay_186 = cute.get_layout(%view_153) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %sz_187 = cute.size(%lay_186) <{mode = [1]}> : (!cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"1">
      %e0_188 = cute.get_leaves(%sz_187) : !cute.int_tuple<"1">
      %lay_189 = cute.get_layout(%view_153) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %sz_190 = cute.size(%lay_189) <{mode = [2]}> : (!cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"1">
      %e0_191 = cute.get_leaves(%sz_190) : !cute.int_tuple<"1">
      %lay_192 = cute.get_layout(%view_153) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %sz_193 = cute.size(%lay_192) <{mode = [2]}> : (!cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"1">
      %e0_194 = cute.get_leaves(%sz_193) : !cute.int_tuple<"1">
      %shape_195 = cute.make_shape() : () -> !cute.shape<"(8,1,1)">
      %stride_196 = cute.make_stride() : () -> !cute.stride<"(1,0,1)">
      %lay_197 = cute.make_layout() : !cute.layout<"(8,1,1):(1,0,1)">
      %rmem_198 = cute.memref.alloca(%lay_197) : !memref_rmem_i8_
      %iter_199 = cute.get_iter(%rmem_198) : !memref_rmem_i8_
      %iter_200 = cute.get_iter(%rmem_198) : !memref_rmem_i8_
      %lay_201 = cute.get_layout(%rmem_198) : !memref_rmem_i8_
      %64 = cute.get_shape(%lay_201) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %e0_202, %e1_203, %e2_204 = cute.get_leaves(%64) : !cute.shape<"(8,1,1)">
      %coord_205 = cute.make_coord() : () -> !cute.coord<"((0,0),0,0)">
      %lay_206 = cute.get_layout(%view_153) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %idx_207 = cute.crd2idx(%coord_205, %lay_206) : (!cute.coord<"((0,0),0,0)">, !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"(0,0)">
      %iter_208 = cute.get_iter(%view_153) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %tup_209 = cute.add_offset(%iter_208, %idx_207) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,0)">) -> !cute.int_tuple<"(?,?{div=8})">
      %view_210 = cute.make_view(%tup_209) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %iter_211 = cute.get_iter(%view_210) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_212, %e1_213 = cute.get_leaves(%iter_211) : !cute.int_tuple<"(?,?{div=8})">
      %65 = cute.get_scalars(%e0_212) : !cute.int_tuple<"?">
      %66 = cute.get_scalars(%e1_213) : !cute.int_tuple<"?{div=8}">
      %iter_214 = cute.get_iter(%view_210) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_215, %e1_216 = cute.get_leaves(%iter_214) : !cute.int_tuple<"(?,?{div=8})">
      %67 = cute.get_scalars(%e0_215) : !cute.int_tuple<"?">
      %68 = cute.get_scalars(%e1_216) : !cute.int_tuple<"?{div=8}">
      %iter_217 = cute.get_iter(%view_210) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_218, %e1_219 = cute.get_leaves(%iter_217) : !cute.int_tuple<"(?,?{div=8})">
      %69 = cute.get_scalars(%e0_218) : !cute.int_tuple<"?">
      %70 = cute.get_scalars(%e1_219) : !cute.int_tuple<"?{div=8}">
      %coord_220 = cute.make_coord(%e1_219) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_221 = cute.make_coord() : () -> !cute.coord<"4096">
      %71 = cute.get_scalars(%coord_220) : !cute.coord<"?{div=8}">
      %72 = cute.get_scalars(%coord_221) : !cute.coord<"4096">
      %true = arith.constant true
      %73 = arith.cmpi slt, %71, %72 : i32
      %74 = arith.andi %true, %73 : i1
      %75 = arith.extui %74 : i1 to i8
      %coord_222 = cute.make_coord() : () -> !cute.coord<"(0,0,0)">
      cute.memref.store(%rmem_198, %coord_222, %75) : (!memref_rmem_i8_, !cute.coord<"(0,0,0)">, i8) -> ()
      %coord_223 = cute.make_coord() : () -> !cute.coord<"((0,1),0,0)">
      %lay_224 = cute.get_layout(%view_153) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %idx_225 = cute.crd2idx(%coord_223, %lay_224) : (!cute.coord<"((0,1),0,0)">, !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"(0,512)">
      %iter_226 = cute.get_iter(%view_153) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %tup_227 = cute.add_offset(%iter_226, %idx_225) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,512)">) -> !cute.int_tuple<"(?,?{div=8})">
      %view_228 = cute.make_view(%tup_227) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %iter_229 = cute.get_iter(%view_228) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_230, %e1_231 = cute.get_leaves(%iter_229) : !cute.int_tuple<"(?,?{div=8})">
      %76 = cute.get_scalars(%e0_230) : !cute.int_tuple<"?">
      %77 = cute.get_scalars(%e1_231) : !cute.int_tuple<"?{div=8}">
      %iter_232 = cute.get_iter(%view_228) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_233, %e1_234 = cute.get_leaves(%iter_232) : !cute.int_tuple<"(?,?{div=8})">
      %78 = cute.get_scalars(%e0_233) : !cute.int_tuple<"?">
      %79 = cute.get_scalars(%e1_234) : !cute.int_tuple<"?{div=8}">
      %iter_235 = cute.get_iter(%view_228) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_236, %e1_237 = cute.get_leaves(%iter_235) : !cute.int_tuple<"(?,?{div=8})">
      %80 = cute.get_scalars(%e0_236) : !cute.int_tuple<"?">
      %81 = cute.get_scalars(%e1_237) : !cute.int_tuple<"?{div=8}">
      %coord_238 = cute.make_coord(%e1_237) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_239 = cute.make_coord() : () -> !cute.coord<"4096">
      %82 = cute.get_scalars(%coord_238) : !cute.coord<"?{div=8}">
      %83 = cute.get_scalars(%coord_239) : !cute.coord<"4096">
      %true_240 = arith.constant true
      %84 = arith.cmpi slt, %82, %83 : i32
      %85 = arith.andi %true_240, %84 : i1
      %86 = arith.extui %85 : i1 to i8
      %coord_241 = cute.make_coord() : () -> !cute.coord<"(1,0,0)">
      cute.memref.store(%rmem_198, %coord_241, %86) : (!memref_rmem_i8_, !cute.coord<"(1,0,0)">, i8) -> ()
      %coord_242 = cute.make_coord() : () -> !cute.coord<"((0,2),0,0)">
      %lay_243 = cute.get_layout(%view_153) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %idx_244 = cute.crd2idx(%coord_242, %lay_243) : (!cute.coord<"((0,2),0,0)">, !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"(0,1024)">
      %iter_245 = cute.get_iter(%view_153) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %tup_246 = cute.add_offset(%iter_245, %idx_244) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,1024)">) -> !cute.int_tuple<"(?,?{div=8})">
      %view_247 = cute.make_view(%tup_246) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %iter_248 = cute.get_iter(%view_247) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_249, %e1_250 = cute.get_leaves(%iter_248) : !cute.int_tuple<"(?,?{div=8})">
      %87 = cute.get_scalars(%e0_249) : !cute.int_tuple<"?">
      %88 = cute.get_scalars(%e1_250) : !cute.int_tuple<"?{div=8}">
      %iter_251 = cute.get_iter(%view_247) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_252, %e1_253 = cute.get_leaves(%iter_251) : !cute.int_tuple<"(?,?{div=8})">
      %89 = cute.get_scalars(%e0_252) : !cute.int_tuple<"?">
      %90 = cute.get_scalars(%e1_253) : !cute.int_tuple<"?{div=8}">
      %iter_254 = cute.get_iter(%view_247) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_255, %e1_256 = cute.get_leaves(%iter_254) : !cute.int_tuple<"(?,?{div=8})">
      %91 = cute.get_scalars(%e0_255) : !cute.int_tuple<"?">
      %92 = cute.get_scalars(%e1_256) : !cute.int_tuple<"?{div=8}">
      %coord_257 = cute.make_coord(%e1_256) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_258 = cute.make_coord() : () -> !cute.coord<"4096">
      %93 = cute.get_scalars(%coord_257) : !cute.coord<"?{div=8}">
      %94 = cute.get_scalars(%coord_258) : !cute.coord<"4096">
      %true_259 = arith.constant true
      %95 = arith.cmpi slt, %93, %94 : i32
      %96 = arith.andi %true_259, %95 : i1
      %97 = arith.extui %96 : i1 to i8
      %coord_260 = cute.make_coord() : () -> !cute.coord<"(2,0,0)">
      cute.memref.store(%rmem_198, %coord_260, %97) : (!memref_rmem_i8_, !cute.coord<"(2,0,0)">, i8) -> ()
      %coord_261 = cute.make_coord() : () -> !cute.coord<"((0,3),0,0)">
      %lay_262 = cute.get_layout(%view_153) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %idx_263 = cute.crd2idx(%coord_261, %lay_262) : (!cute.coord<"((0,3),0,0)">, !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"(0,1536)">
      %iter_264 = cute.get_iter(%view_153) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %tup_265 = cute.add_offset(%iter_264, %idx_263) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,1536)">) -> !cute.int_tuple<"(?,?{div=8})">
      %view_266 = cute.make_view(%tup_265) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %iter_267 = cute.get_iter(%view_266) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_268, %e1_269 = cute.get_leaves(%iter_267) : !cute.int_tuple<"(?,?{div=8})">
      %98 = cute.get_scalars(%e0_268) : !cute.int_tuple<"?">
      %99 = cute.get_scalars(%e1_269) : !cute.int_tuple<"?{div=8}">
      %iter_270 = cute.get_iter(%view_266) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_271, %e1_272 = cute.get_leaves(%iter_270) : !cute.int_tuple<"(?,?{div=8})">
      %100 = cute.get_scalars(%e0_271) : !cute.int_tuple<"?">
      %101 = cute.get_scalars(%e1_272) : !cute.int_tuple<"?{div=8}">
      %iter_273 = cute.get_iter(%view_266) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_274, %e1_275 = cute.get_leaves(%iter_273) : !cute.int_tuple<"(?,?{div=8})">
      %102 = cute.get_scalars(%e0_274) : !cute.int_tuple<"?">
      %103 = cute.get_scalars(%e1_275) : !cute.int_tuple<"?{div=8}">
      %coord_276 = cute.make_coord(%e1_275) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_277 = cute.make_coord() : () -> !cute.coord<"4096">
      %104 = cute.get_scalars(%coord_276) : !cute.coord<"?{div=8}">
      %105 = cute.get_scalars(%coord_277) : !cute.coord<"4096">
      %true_278 = arith.constant true
      %106 = arith.cmpi slt, %104, %105 : i32
      %107 = arith.andi %true_278, %106 : i1
      %108 = arith.extui %107 : i1 to i8
      %coord_279 = cute.make_coord() : () -> !cute.coord<"(3,0,0)">
      cute.memref.store(%rmem_198, %coord_279, %108) : (!memref_rmem_i8_, !cute.coord<"(3,0,0)">, i8) -> ()
      %coord_280 = cute.make_coord() : () -> !cute.coord<"((0,4),0,0)">
      %lay_281 = cute.get_layout(%view_153) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %idx_282 = cute.crd2idx(%coord_280, %lay_281) : (!cute.coord<"((0,4),0,0)">, !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"(0,2048)">
      %iter_283 = cute.get_iter(%view_153) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %tup_284 = cute.add_offset(%iter_283, %idx_282) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,2048)">) -> !cute.int_tuple<"(?,?{div=8})">
      %view_285 = cute.make_view(%tup_284) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %iter_286 = cute.get_iter(%view_285) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_287, %e1_288 = cute.get_leaves(%iter_286) : !cute.int_tuple<"(?,?{div=8})">
      %109 = cute.get_scalars(%e0_287) : !cute.int_tuple<"?">
      %110 = cute.get_scalars(%e1_288) : !cute.int_tuple<"?{div=8}">
      %iter_289 = cute.get_iter(%view_285) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_290, %e1_291 = cute.get_leaves(%iter_289) : !cute.int_tuple<"(?,?{div=8})">
      %111 = cute.get_scalars(%e0_290) : !cute.int_tuple<"?">
      %112 = cute.get_scalars(%e1_291) : !cute.int_tuple<"?{div=8}">
      %iter_292 = cute.get_iter(%view_285) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_293, %e1_294 = cute.get_leaves(%iter_292) : !cute.int_tuple<"(?,?{div=8})">
      %113 = cute.get_scalars(%e0_293) : !cute.int_tuple<"?">
      %114 = cute.get_scalars(%e1_294) : !cute.int_tuple<"?{div=8}">
      %coord_295 = cute.make_coord(%e1_294) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_296 = cute.make_coord() : () -> !cute.coord<"4096">
      %115 = cute.get_scalars(%coord_295) : !cute.coord<"?{div=8}">
      %116 = cute.get_scalars(%coord_296) : !cute.coord<"4096">
      %true_297 = arith.constant true
      %117 = arith.cmpi slt, %115, %116 : i32
      %118 = arith.andi %true_297, %117 : i1
      %119 = arith.extui %118 : i1 to i8
      %coord_298 = cute.make_coord() : () -> !cute.coord<"(4,0,0)">
      cute.memref.store(%rmem_198, %coord_298, %119) : (!memref_rmem_i8_, !cute.coord<"(4,0,0)">, i8) -> ()
      %coord_299 = cute.make_coord() : () -> !cute.coord<"((0,5),0,0)">
      %lay_300 = cute.get_layout(%view_153) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %idx_301 = cute.crd2idx(%coord_299, %lay_300) : (!cute.coord<"((0,5),0,0)">, !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"(0,2560)">
      %iter_302 = cute.get_iter(%view_153) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %tup_303 = cute.add_offset(%iter_302, %idx_301) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,2560)">) -> !cute.int_tuple<"(?,?{div=8})">
      %view_304 = cute.make_view(%tup_303) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %iter_305 = cute.get_iter(%view_304) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_306, %e1_307 = cute.get_leaves(%iter_305) : !cute.int_tuple<"(?,?{div=8})">
      %120 = cute.get_scalars(%e0_306) : !cute.int_tuple<"?">
      %121 = cute.get_scalars(%e1_307) : !cute.int_tuple<"?{div=8}">
      %iter_308 = cute.get_iter(%view_304) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_309, %e1_310 = cute.get_leaves(%iter_308) : !cute.int_tuple<"(?,?{div=8})">
      %122 = cute.get_scalars(%e0_309) : !cute.int_tuple<"?">
      %123 = cute.get_scalars(%e1_310) : !cute.int_tuple<"?{div=8}">
      %iter_311 = cute.get_iter(%view_304) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_312, %e1_313 = cute.get_leaves(%iter_311) : !cute.int_tuple<"(?,?{div=8})">
      %124 = cute.get_scalars(%e0_312) : !cute.int_tuple<"?">
      %125 = cute.get_scalars(%e1_313) : !cute.int_tuple<"?{div=8}">
      %coord_314 = cute.make_coord(%e1_313) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_315 = cute.make_coord() : () -> !cute.coord<"4096">
      %126 = cute.get_scalars(%coord_314) : !cute.coord<"?{div=8}">
      %127 = cute.get_scalars(%coord_315) : !cute.coord<"4096">
      %true_316 = arith.constant true
      %128 = arith.cmpi slt, %126, %127 : i32
      %129 = arith.andi %true_316, %128 : i1
      %130 = arith.extui %129 : i1 to i8
      %coord_317 = cute.make_coord() : () -> !cute.coord<"(5,0,0)">
      cute.memref.store(%rmem_198, %coord_317, %130) : (!memref_rmem_i8_, !cute.coord<"(5,0,0)">, i8) -> ()
      %coord_318 = cute.make_coord() : () -> !cute.coord<"((0,6),0,0)">
      %lay_319 = cute.get_layout(%view_153) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %idx_320 = cute.crd2idx(%coord_318, %lay_319) : (!cute.coord<"((0,6),0,0)">, !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"(0,3072)">
      %iter_321 = cute.get_iter(%view_153) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %tup_322 = cute.add_offset(%iter_321, %idx_320) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,3072)">) -> !cute.int_tuple<"(?,?{div=8})">
      %view_323 = cute.make_view(%tup_322) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %iter_324 = cute.get_iter(%view_323) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_325, %e1_326 = cute.get_leaves(%iter_324) : !cute.int_tuple<"(?,?{div=8})">
      %131 = cute.get_scalars(%e0_325) : !cute.int_tuple<"?">
      %132 = cute.get_scalars(%e1_326) : !cute.int_tuple<"?{div=8}">
      %iter_327 = cute.get_iter(%view_323) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_328, %e1_329 = cute.get_leaves(%iter_327) : !cute.int_tuple<"(?,?{div=8})">
      %133 = cute.get_scalars(%e0_328) : !cute.int_tuple<"?">
      %134 = cute.get_scalars(%e1_329) : !cute.int_tuple<"?{div=8}">
      %iter_330 = cute.get_iter(%view_323) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_331, %e1_332 = cute.get_leaves(%iter_330) : !cute.int_tuple<"(?,?{div=8})">
      %135 = cute.get_scalars(%e0_331) : !cute.int_tuple<"?">
      %136 = cute.get_scalars(%e1_332) : !cute.int_tuple<"?{div=8}">
      %coord_333 = cute.make_coord(%e1_332) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_334 = cute.make_coord() : () -> !cute.coord<"4096">
      %137 = cute.get_scalars(%coord_333) : !cute.coord<"?{div=8}">
      %138 = cute.get_scalars(%coord_334) : !cute.coord<"4096">
      %true_335 = arith.constant true
      %139 = arith.cmpi slt, %137, %138 : i32
      %140 = arith.andi %true_335, %139 : i1
      %141 = arith.extui %140 : i1 to i8
      %coord_336 = cute.make_coord() : () -> !cute.coord<"(6,0,0)">
      cute.memref.store(%rmem_198, %coord_336, %141) : (!memref_rmem_i8_, !cute.coord<"(6,0,0)">, i8) -> ()
      %coord_337 = cute.make_coord() : () -> !cute.coord<"((0,7),0,0)">
      %lay_338 = cute.get_layout(%view_153) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %idx_339 = cute.crd2idx(%coord_337, %lay_338) : (!cute.coord<"((0,7),0,0)">, !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"(0,3584)">
      %iter_340 = cute.get_iter(%view_153) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %tup_341 = cute.add_offset(%iter_340, %idx_339) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,3584)">) -> !cute.int_tuple<"(?,?{div=8})">
      %view_342 = cute.make_view(%tup_341) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %iter_343 = cute.get_iter(%view_342) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_344, %e1_345 = cute.get_leaves(%iter_343) : !cute.int_tuple<"(?,?{div=8})">
      %142 = cute.get_scalars(%e0_344) : !cute.int_tuple<"?">
      %143 = cute.get_scalars(%e1_345) : !cute.int_tuple<"?{div=8}">
      %iter_346 = cute.get_iter(%view_342) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_347, %e1_348 = cute.get_leaves(%iter_346) : !cute.int_tuple<"(?,?{div=8})">
      %144 = cute.get_scalars(%e0_347) : !cute.int_tuple<"?">
      %145 = cute.get_scalars(%e1_348) : !cute.int_tuple<"?{div=8}">
      %iter_349 = cute.get_iter(%view_342) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_350, %e1_351 = cute.get_leaves(%iter_349) : !cute.int_tuple<"(?,?{div=8})">
      %146 = cute.get_scalars(%e0_350) : !cute.int_tuple<"?">
      %147 = cute.get_scalars(%e1_351) : !cute.int_tuple<"?{div=8}">
      %coord_352 = cute.make_coord(%e1_351) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_353 = cute.make_coord() : () -> !cute.coord<"4096">
      %148 = cute.get_scalars(%coord_352) : !cute.coord<"?{div=8}">
      %149 = cute.get_scalars(%coord_353) : !cute.coord<"4096">
      %true_354 = arith.constant true
      %150 = arith.cmpi slt, %148, %149 : i32
      %151 = arith.andi %true_354, %150 : i1
      %152 = arith.extui %151 : i1 to i8
      %coord_355 = cute.make_coord() : () -> !cute.coord<"(7,0,0)">
      cute.memref.store(%rmem_198, %coord_355, %152) : (!memref_rmem_i8_, !cute.coord<"(7,0,0)">, i8) -> ()
      %coord_356 = cute.make_coord() : () -> !cute.coord<"((0,0),0,0)">
      %lay_357 = cute.get_layout(%view_153) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %idx_358 = cute.crd2idx(%coord_356, %lay_357) : (!cute.coord<"((0,0),0,0)">, !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"(0,0)">
      %iter_359 = cute.get_iter(%view_153) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %tup_360 = cute.add_offset(%iter_359, %idx_358) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,0)">) -> !cute.int_tuple<"(?,?{div=8})">
      %view_361 = cute.make_view(%tup_360) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %iter_362 = cute.get_iter(%view_361) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_363, %e1_364 = cute.get_leaves(%iter_362) : !cute.int_tuple<"(?,?{div=8})">
      %153 = cute.get_scalars(%e0_363) : !cute.int_tuple<"?">
      %154 = cute.get_scalars(%e1_364) : !cute.int_tuple<"?{div=8}">
      %iter_365 = cute.get_iter(%view_361) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_366, %e1_367 = cute.get_leaves(%iter_365) : !cute.int_tuple<"(?,?{div=8})">
      %155 = cute.get_scalars(%e0_366) : !cute.int_tuple<"?">
      %156 = cute.get_scalars(%e1_367) : !cute.int_tuple<"?{div=8}">
      %iter_368 = cute.get_iter(%view_361) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_369, %e1_370 = cute.get_leaves(%iter_368) : !cute.int_tuple<"(?,?{div=8})">
      %157 = cute.get_scalars(%e0_369) : !cute.int_tuple<"?">
      %158 = cute.get_scalars(%e1_370) : !cute.int_tuple<"?{div=8}">
      %159 = arith.cmpi slt, %157, %18 : i32
      scf.if %159 {
        %lay_788 = cute.get_layout(%view_121) : !memref_gmem_bf16_5
        %334 = cute.get_shape(%lay_788) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %e0_789, %e1_790, %e2_791, %e3_792 = cute.get_leaves(%334) : !cute.shape<"((8,8),1,1)">
        %lay_793 = cute.get_layout(%view_132) : !memref_smem_bf16_1
        %335 = cute.get_shape(%lay_793) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %e0_794, %e1_795, %e2_796, %e3_797 = cute.get_leaves(%335) : !cute.shape<"((8,8),1,1)">
        %lay_798 = cute.get_layout(%view_121) : !memref_gmem_bf16_5
        %shape_799 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_800 = cute.make_layout() : !cute.layout<"1:0">
        %append_801 = cute.append_to_rank<2> (%lay_798, %lay_800) : !cute.layout<"((8,8),1,1):((1,512),0,0)">, !cute.layout<"1:0">
        %view_802 = cute.make_view(%iter_122, %append_801) : !memref_gmem_bf16_5
        %iter_803 = cute.get_iter(%view_802) : !memref_gmem_bf16_5
        %lay_804 = cute.get_layout(%view_802) : !memref_gmem_bf16_5
        %336 = cute.get_shape(%lay_804) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %e0_805, %e1_806, %e2_807, %e3_808 = cute.get_leaves(%336) : !cute.shape<"((8,8),1,1)">
        %iter_809 = cute.get_iter(%view_802) : !memref_gmem_bf16_5
        %view_810 = cute.make_view(%iter_809) : !memref_gmem_bf16_6
        %iter_811 = cute.get_iter(%view_810) : !memref_gmem_bf16_6
        %iter_812 = cute.get_iter(%view_810) : !memref_gmem_bf16_6
        %lay_813 = cute.get_layout(%view_132) : !memref_smem_bf16_1
        %shape_814 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_815 = cute.make_layout() : !cute.layout<"1:0">
        %append_816 = cute.append_to_rank<2> (%lay_813, %lay_815) : !cute.layout<"((8,8),1,1):((1,512),0,0)">, !cute.layout<"1:0">
        %view_817 = cute.make_view(%iter_133, %append_816) : !memref_smem_bf16_1
        %iter_818 = cute.get_iter(%view_817) : !memref_smem_bf16_1
        %lay_819 = cute.get_layout(%view_817) : !memref_smem_bf16_1
        %337 = cute.get_shape(%lay_819) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %e0_820, %e1_821, %e2_822, %e3_823 = cute.get_leaves(%337) : !cute.shape<"((8,8),1,1)">
        %iter_824 = cute.get_iter(%view_817) : !memref_smem_bf16_1
        %view_825 = cute.make_view(%iter_824) : !memref_smem_bf16_2
        %iter_826 = cute.get_iter(%view_825) : !memref_smem_bf16_2
        %iter_827 = cute.get_iter(%view_825) : !memref_smem_bf16_2
        %lay_828 = cute.get_layout(%rmem_198) : !memref_rmem_i8_
        %shape_829 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_830 = cute.make_layout() : !cute.layout<"1:0">
        %append_831 = cute.append_to_rank<2> (%lay_828, %lay_830) : !cute.layout<"(8,1,1):(1,0,1)">, !cute.layout<"1:0">
        %view_832 = cute.make_view(%iter_200, %append_831) : !memref_rmem_i8_
        %iter_833 = cute.get_iter(%view_832) : !memref_rmem_i8_
        %lay_834 = cute.get_layout(%view_832) : !memref_rmem_i8_
        %338 = cute.get_shape(%lay_834) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
        %e0_835, %e1_836, %e2_837 = cute.get_leaves(%338) : !cute.shape<"(8,1,1)">
        %iter_838 = cute.get_iter(%view_832) : !memref_rmem_i8_
        %view_839 = cute.make_view(%iter_838) : !memref_rmem_i8_1
        %iter_840 = cute.get_iter(%view_839) : !memref_rmem_i8_1
        %iter_841 = cute.get_iter(%view_839) : !memref_rmem_i8_1
        %lay_842 = cute.get_layout(%view_810) : !memref_gmem_bf16_6
        %339 = cute.get_shape(%lay_842) : (!cute.layout<"((8,8),(1,1)):((1,512),(0,0))">) -> !cute.shape<"((8,8),(1,1))">
        %e0_843, %e1_844, %e2_845, %e3_846 = cute.get_leaves(%339) : !cute.shape<"((8,8),(1,1))">
        %lay_847 = cute.get_layout(%view_825) : !memref_smem_bf16_2
        %340 = cute.get_shape(%lay_847) : (!cute.layout<"((8,8),(1,1)):((1,512),(0,0))">) -> !cute.shape<"((8,8),(1,1))">
        %e0_848, %e1_849, %e2_850, %e3_851 = cute.get_leaves(%340) : !cute.shape<"((8,8),(1,1))">
        %lay_852 = cute.get_layout(%view_810) : !memref_gmem_bf16_6
        %sz_853 = cute.size(%lay_852) <{mode = [1]}> : (!cute.layout<"((8,8),(1,1)):((1,512),(0,0))">) -> !cute.int_tuple<"1">
        %e0_854 = cute.get_leaves(%sz_853) : !cute.int_tuple<"1">
        %lay_855 = cute.get_layout(%view_825) : !memref_smem_bf16_2
        %sz_856 = cute.size(%lay_855) <{mode = [1]}> : (!cute.layout<"((8,8),(1,1)):((1,512),(0,0))">) -> !cute.int_tuple<"1">
        %e0_857 = cute.get_leaves(%sz_856) : !cute.int_tuple<"1">
        %341 = cute.static : !cute.layout<"1:0">
        %iter_858 = cute.get_iter(%view_810) : !memref_gmem_bf16_6
        %iter_859 = cute.get_iter(%view_825) : !memref_smem_bf16_2
        %lay_860 = cute.get_layout(%view_810) : !memref_gmem_bf16_6
        %lay_861 = cute.get_layout(%view_825) : !memref_smem_bf16_2
        %append_862 = cute.append_to_rank<2> (%lay_860, %341) : !cute.layout<"((8,8),(1,1)):((1,512),(0,0))">, !cute.layout<"1:0">
        %append_863 = cute.append_to_rank<2> (%lay_861, %341) : !cute.layout<"((8,8),(1,1)):((1,512),(0,0))">, !cute.layout<"1:0">
        %lay_864 = cute.make_layout() : !cute.layout<"((8,8),((1,1))):((1,512),((0,0)))">
        %lay_865 = cute.make_layout() : !cute.layout<"((8,8),((1,1))):((1,512),((0,0)))">
        %iter_866 = cute.get_iter(%view_839) : !memref_rmem_i8_1
        %lay_867 = cute.get_layout(%view_839) : !memref_rmem_i8_1
        %append_868 = cute.append_to_rank<2> (%lay_867, %341) : !cute.layout<"(8,(1,1)):(1,(0,1))">, !cute.layout<"1:0">
        %lay_869 = cute.make_layout() : !cute.layout<"(8,((1,1))):(1,((0,1)))">
        %sz_870 = cute.size(%lay_864) <{mode = [1]}> : (!cute.layout<"((8,8),((1,1))):((1,512),((0,0)))">) -> !cute.int_tuple<"1">
        %342 = cute.get_scalars(%sz_870) : !cute.int_tuple<"1">
        %c0_i32_871 = arith.constant 0 : i32
        %c1_i32_872 = arith.constant 1 : i32
        scf.for %arg4 = %c0_i32_871 to %342 step %c1_i32_872  : i32 {
          %coord_873 = cute.make_coord(%arg4) : (i32) -> !cute.coord<"(_,?)">
          %343 = cute.get_scalars(%coord_873) <{only_dynamic}> : !cute.coord<"(_,?)">
          %lay_874 = cute.make_layout() : !cute.layout<"((8,8)):((1,512))">
          %idx_875 = cute.crd2idx(%coord_873, %lay_864) : (!cute.coord<"(_,?)">, !cute.layout<"((8,8),((1,1))):((1,512),((0,0)))">) -> !cute.int_tuple<"0">
          %ptr_876 = cute.add_offset(%iter_858, %idx_875) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, gmem, align<16>>
          %view_877 = cute.make_view(%ptr_876, %lay_874) : !memref_gmem_bf16_7
          %344 = cute.get_scalars(%coord_873) <{only_dynamic}> : !cute.coord<"(_,?)">
          %lay_878 = cute.make_layout() : !cute.layout<"((8,8)):((1,512))">
          %idx_879 = cute.crd2idx(%coord_873, %lay_865) : (!cute.coord<"(_,?)">, !cute.layout<"((8,8),((1,1))):((1,512),((0,0)))">) -> !cute.int_tuple<"0">
          %ptr_880 = cute.add_offset(%iter_859, %idx_879) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, smem, align<16>>
          %view_881 = cute.make_view(%ptr_880, %lay_878) : !memref_smem_bf16_3
          %345 = cute.get_scalars(%coord_873) <{only_dynamic}> : !cute.coord<"(_,?)">
          %lay_882 = cute.make_layout() : !cute.layout<"(8):(1)">
          %idx_883 = cute.crd2idx(%coord_873, %lay_869) : (!cute.coord<"(_,?)">, !cute.layout<"(8,((1,1))):(1,((0,1)))">) -> !cute.int_tuple<"?">
          %ptr_884 = cute.add_offset(%iter_866, %idx_883) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %view_885 = cute.make_view(%ptr_884, %lay_882) : !memref_rmem_i8_2
          %iter_886 = cute.get_iter(%view_877) : !memref_gmem_bf16_7
          %iter_887 = cute.get_iter(%view_881) : !memref_smem_bf16_3
          %iter_888 = cute.get_iter(%view_885) : !memref_rmem_i8_2
          %346 = builtin.unrealized_conversion_cast %iter_888 : !cute.ptr<i8, rmem> to !llvm.ptr
          %347 = llvm.load %346 : !llvm.ptr -> i8
          %348 = llvm.trunc %347 : i8 to i1
          %iter_889 = cute.recast_iter(%iter_886) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
          %iter_890 = cute.recast_iter(%iter_887) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_890 : !cute.ptr<i128, smem>, %iter_889 : !cute.ptr<i128, gmem>, %348 : i1) {cache_mode = <always>}
          %int_tuple_891 = cute.make_int_tuple() : () -> !cute.int_tuple<"512">
          %ptr_892 = cute.add_offset(%iter_886, %int_tuple_891) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"512">) -> !cute.ptr<bf16, gmem, align<16>>
          %int_tuple_893 = cute.make_int_tuple() : () -> !cute.int_tuple<"512">
          %ptr_894 = cute.add_offset(%iter_887, %int_tuple_893) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"512">) -> !cute.ptr<bf16, smem, align<16>>
          %int_tuple_895 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
          %ptr_896 = cute.add_offset(%iter_888, %int_tuple_895) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
          %349 = builtin.unrealized_conversion_cast %ptr_896 : !cute.ptr<i8, rmem> to !llvm.ptr
          %350 = llvm.load %349 : !llvm.ptr -> i8
          %351 = llvm.trunc %350 : i8 to i1
          %iter_897 = cute.recast_iter(%ptr_892) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
          %iter_898 = cute.recast_iter(%ptr_894) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_898 : !cute.ptr<i128, smem>, %iter_897 : !cute.ptr<i128, gmem>, %351 : i1) {cache_mode = <always>}
          %int_tuple_899 = cute.make_int_tuple() : () -> !cute.int_tuple<"1024">
          %ptr_900 = cute.add_offset(%iter_886, %int_tuple_899) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, gmem, align<16>>
          %int_tuple_901 = cute.make_int_tuple() : () -> !cute.int_tuple<"1024">
          %ptr_902 = cute.add_offset(%iter_887, %int_tuple_901) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, smem, align<16>>
          %int_tuple_903 = cute.make_int_tuple() : () -> !cute.int_tuple<"2">
          %ptr_904 = cute.add_offset(%iter_888, %int_tuple_903) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem>
          %352 = builtin.unrealized_conversion_cast %ptr_904 : !cute.ptr<i8, rmem> to !llvm.ptr
          %353 = llvm.load %352 : !llvm.ptr -> i8
          %354 = llvm.trunc %353 : i8 to i1
          %iter_905 = cute.recast_iter(%ptr_900) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
          %iter_906 = cute.recast_iter(%ptr_902) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_906 : !cute.ptr<i128, smem>, %iter_905 : !cute.ptr<i128, gmem>, %354 : i1) {cache_mode = <always>}
          %int_tuple_907 = cute.make_int_tuple() : () -> !cute.int_tuple<"1536">
          %ptr_908 = cute.add_offset(%iter_886, %int_tuple_907) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"1536">) -> !cute.ptr<bf16, gmem, align<16>>
          %int_tuple_909 = cute.make_int_tuple() : () -> !cute.int_tuple<"1536">
          %ptr_910 = cute.add_offset(%iter_887, %int_tuple_909) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"1536">) -> !cute.ptr<bf16, smem, align<16>>
          %int_tuple_911 = cute.make_int_tuple() : () -> !cute.int_tuple<"3">
          %ptr_912 = cute.add_offset(%iter_888, %int_tuple_911) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
          %355 = builtin.unrealized_conversion_cast %ptr_912 : !cute.ptr<i8, rmem> to !llvm.ptr
          %356 = llvm.load %355 : !llvm.ptr -> i8
          %357 = llvm.trunc %356 : i8 to i1
          %iter_913 = cute.recast_iter(%ptr_908) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
          %iter_914 = cute.recast_iter(%ptr_910) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_914 : !cute.ptr<i128, smem>, %iter_913 : !cute.ptr<i128, gmem>, %357 : i1) {cache_mode = <always>}
          %int_tuple_915 = cute.make_int_tuple() : () -> !cute.int_tuple<"2048">
          %ptr_916 = cute.add_offset(%iter_886, %int_tuple_915) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, gmem, align<16>>
          %int_tuple_917 = cute.make_int_tuple() : () -> !cute.int_tuple<"2048">
          %ptr_918 = cute.add_offset(%iter_887, %int_tuple_917) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, smem, align<16>>
          %int_tuple_919 = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
          %ptr_920 = cute.add_offset(%iter_888, %int_tuple_919) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem>
          %358 = builtin.unrealized_conversion_cast %ptr_920 : !cute.ptr<i8, rmem> to !llvm.ptr
          %359 = llvm.load %358 : !llvm.ptr -> i8
          %360 = llvm.trunc %359 : i8 to i1
          %iter_921 = cute.recast_iter(%ptr_916) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
          %iter_922 = cute.recast_iter(%ptr_918) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_922 : !cute.ptr<i128, smem>, %iter_921 : !cute.ptr<i128, gmem>, %360 : i1) {cache_mode = <always>}
          %int_tuple_923 = cute.make_int_tuple() : () -> !cute.int_tuple<"2560">
          %ptr_924 = cute.add_offset(%iter_886, %int_tuple_923) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"2560">) -> !cute.ptr<bf16, gmem, align<16>>
          %int_tuple_925 = cute.make_int_tuple() : () -> !cute.int_tuple<"2560">
          %ptr_926 = cute.add_offset(%iter_887, %int_tuple_925) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"2560">) -> !cute.ptr<bf16, smem, align<16>>
          %int_tuple_927 = cute.make_int_tuple() : () -> !cute.int_tuple<"5">
          %ptr_928 = cute.add_offset(%iter_888, %int_tuple_927) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
          %361 = builtin.unrealized_conversion_cast %ptr_928 : !cute.ptr<i8, rmem> to !llvm.ptr
          %362 = llvm.load %361 : !llvm.ptr -> i8
          %363 = llvm.trunc %362 : i8 to i1
          %iter_929 = cute.recast_iter(%ptr_924) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
          %iter_930 = cute.recast_iter(%ptr_926) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_930 : !cute.ptr<i128, smem>, %iter_929 : !cute.ptr<i128, gmem>, %363 : i1) {cache_mode = <always>}
          %int_tuple_931 = cute.make_int_tuple() : () -> !cute.int_tuple<"3072">
          %ptr_932 = cute.add_offset(%iter_886, %int_tuple_931) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, gmem, align<16>>
          %int_tuple_933 = cute.make_int_tuple() : () -> !cute.int_tuple<"3072">
          %ptr_934 = cute.add_offset(%iter_887, %int_tuple_933) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, smem, align<16>>
          %int_tuple_935 = cute.make_int_tuple() : () -> !cute.int_tuple<"6">
          %ptr_936 = cute.add_offset(%iter_888, %int_tuple_935) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem>
          %364 = builtin.unrealized_conversion_cast %ptr_936 : !cute.ptr<i8, rmem> to !llvm.ptr
          %365 = llvm.load %364 : !llvm.ptr -> i8
          %366 = llvm.trunc %365 : i8 to i1
          %iter_937 = cute.recast_iter(%ptr_932) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
          %iter_938 = cute.recast_iter(%ptr_934) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_938 : !cute.ptr<i128, smem>, %iter_937 : !cute.ptr<i128, gmem>, %366 : i1) {cache_mode = <always>}
          %int_tuple_939 = cute.make_int_tuple() : () -> !cute.int_tuple<"3584">
          %ptr_940 = cute.add_offset(%iter_886, %int_tuple_939) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"3584">) -> !cute.ptr<bf16, gmem, align<16>>
          %int_tuple_941 = cute.make_int_tuple() : () -> !cute.int_tuple<"3584">
          %ptr_942 = cute.add_offset(%iter_887, %int_tuple_941) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"3584">) -> !cute.ptr<bf16, smem, align<16>>
          %int_tuple_943 = cute.make_int_tuple() : () -> !cute.int_tuple<"7">
          %ptr_944 = cute.add_offset(%iter_888, %int_tuple_943) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
          %367 = builtin.unrealized_conversion_cast %ptr_944 : !cute.ptr<i8, rmem> to !llvm.ptr
          %368 = llvm.load %367 : !llvm.ptr -> i8
          %369 = llvm.trunc %368 : i8 to i1
          %iter_945 = cute.recast_iter(%ptr_940) : !cute.ptr<bf16, gmem, align<16>> to !cute.ptr<i128, gmem>
          %iter_946 = cute.recast_iter(%ptr_942) : !cute.ptr<bf16, smem, align<16>> to !cute.ptr<i128, smem>
          cute_nvgpu.arch.copy.SM80.cp_async(%iter_946 : !cute.ptr<i128, smem>, %iter_945 : !cute.ptr<i128, gmem>, %369 : i1) {cache_mode = <always>}
        } {llvm.loop_annotation = #loop_annotation}
      }
      nvvm.cp.async.commit.group
      %coord_371 = cute.make_coord(%11) : (i32) -> !cute.coord<"?">
      %iter_372 = cute.get_iter(%view_90) : !cute.coord_tensor<"(?{div=2},0)", "(2,4096):(1@0,1@1)">
      %160 = cute.get_scalars(%coord_371) <{only_dynamic}> : !cute.coord<"?">
      %c64_i32_373 = arith.constant 64 : i32
      %161 = arith.divsi %160, %c64_i32_373 : i32
      %c64_i32_374 = arith.constant 64 : i32
      %162 = arith.remsi %160, %c64_i32_374 : i32
      %c8_i32_375 = arith.constant 8 : i32
      %163 = arith.muli %162, %c8_i32_375 : i32
      %iv_376 = cute.assume(%163) : (i32) -> !cute.i32<divby 8>
      %int_tuple_377 = cute.make_int_tuple(%161, %iv_376) : (i32, !cute.i32<divby 8>) -> !cute.int_tuple<"(?,?{div=8})">
      %tup_378 = cute.add_offset(%iter_372, %int_tuple_377) : (!cute.int_tuple<"(?{div=2},0)">, !cute.int_tuple<"(?,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8})">
      %view_379 = cute.make_view(%tup_378) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %iter_380 = cute.get_iter(%view_379) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %e0_381, %e1_382 = cute.get_leaves(%iter_380) : !cute.int_tuple<"(?,?{div=8})">
      %164 = cute.get_scalars(%e0_381) : !cute.int_tuple<"?">
      %165 = cute.get_scalars(%e1_382) : !cute.int_tuple<"?{div=8}">
      %lay_383 = cute.get_layout(%view_379) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %sz_384 = cute.size(%lay_383) <{mode = [0, 1]}> : (!cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"8">
      %e0_385 = cute.get_leaves(%sz_384) : !cute.int_tuple<"8">
      %lay_386 = cute.get_layout(%view_379) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %sz_387 = cute.size(%lay_386) <{mode = [1]}> : (!cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"1">
      %e0_388 = cute.get_leaves(%sz_387) : !cute.int_tuple<"1">
      %lay_389 = cute.get_layout(%view_379) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %sz_390 = cute.size(%lay_389) <{mode = [2]}> : (!cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"1">
      %e0_391 = cute.get_leaves(%sz_390) : !cute.int_tuple<"1">
      %lay_392 = cute.get_layout(%view_379) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %sz_393 = cute.size(%lay_392) <{mode = [2]}> : (!cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"1">
      %e0_394 = cute.get_leaves(%sz_393) : !cute.int_tuple<"1">
      %shape_395 = cute.make_shape() : () -> !cute.shape<"(8,1,1)">
      %stride_396 = cute.make_stride() : () -> !cute.stride<"(1,0,1)">
      %lay_397 = cute.make_layout() : !cute.layout<"(8,1,1):(1,0,1)">
      %rmem_398 = cute.memref.alloca(%lay_397) : !memref_rmem_i8_
      %iter_399 = cute.get_iter(%rmem_398) : !memref_rmem_i8_
      %iter_400 = cute.get_iter(%rmem_398) : !memref_rmem_i8_
      %lay_401 = cute.get_layout(%rmem_398) : !memref_rmem_i8_
      %166 = cute.get_shape(%lay_401) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %e0_402, %e1_403, %e2_404 = cute.get_leaves(%166) : !cute.shape<"(8,1,1)">
      %coord_405 = cute.make_coord() : () -> !cute.coord<"((0,0),0,0)">
      %lay_406 = cute.get_layout(%view_379) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %idx_407 = cute.crd2idx(%coord_405, %lay_406) : (!cute.coord<"((0,0),0,0)">, !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"(0,0)">
      %iter_408 = cute.get_iter(%view_379) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %tup_409 = cute.add_offset(%iter_408, %idx_407) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,0)">) -> !cute.int_tuple<"(?,?{div=8})">
      %view_410 = cute.make_view(%tup_409) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %iter_411 = cute.get_iter(%view_410) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_412, %e1_413 = cute.get_leaves(%iter_411) : !cute.int_tuple<"(?,?{div=8})">
      %167 = cute.get_scalars(%e0_412) : !cute.int_tuple<"?">
      %168 = cute.get_scalars(%e1_413) : !cute.int_tuple<"?{div=8}">
      %iter_414 = cute.get_iter(%view_410) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_415, %e1_416 = cute.get_leaves(%iter_414) : !cute.int_tuple<"(?,?{div=8})">
      %169 = cute.get_scalars(%e0_415) : !cute.int_tuple<"?">
      %170 = cute.get_scalars(%e1_416) : !cute.int_tuple<"?{div=8}">
      %iter_417 = cute.get_iter(%view_410) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_418, %e1_419 = cute.get_leaves(%iter_417) : !cute.int_tuple<"(?,?{div=8})">
      %171 = cute.get_scalars(%e0_418) : !cute.int_tuple<"?">
      %172 = cute.get_scalars(%e1_419) : !cute.int_tuple<"?{div=8}">
      %coord_420 = cute.make_coord(%e1_419) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_421 = cute.make_coord() : () -> !cute.coord<"4096">
      %173 = cute.get_scalars(%coord_420) : !cute.coord<"?{div=8}">
      %174 = cute.get_scalars(%coord_421) : !cute.coord<"4096">
      %true_422 = arith.constant true
      %175 = arith.cmpi slt, %173, %174 : i32
      %176 = arith.andi %true_422, %175 : i1
      %177 = arith.extui %176 : i1 to i8
      %coord_423 = cute.make_coord() : () -> !cute.coord<"(0,0,0)">
      cute.memref.store(%rmem_398, %coord_423, %177) : (!memref_rmem_i8_, !cute.coord<"(0,0,0)">, i8) -> ()
      %coord_424 = cute.make_coord() : () -> !cute.coord<"((0,1),0,0)">
      %lay_425 = cute.get_layout(%view_379) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %idx_426 = cute.crd2idx(%coord_424, %lay_425) : (!cute.coord<"((0,1),0,0)">, !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"(0,512)">
      %iter_427 = cute.get_iter(%view_379) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %tup_428 = cute.add_offset(%iter_427, %idx_426) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,512)">) -> !cute.int_tuple<"(?,?{div=8})">
      %view_429 = cute.make_view(%tup_428) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %iter_430 = cute.get_iter(%view_429) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_431, %e1_432 = cute.get_leaves(%iter_430) : !cute.int_tuple<"(?,?{div=8})">
      %178 = cute.get_scalars(%e0_431) : !cute.int_tuple<"?">
      %179 = cute.get_scalars(%e1_432) : !cute.int_tuple<"?{div=8}">
      %iter_433 = cute.get_iter(%view_429) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_434, %e1_435 = cute.get_leaves(%iter_433) : !cute.int_tuple<"(?,?{div=8})">
      %180 = cute.get_scalars(%e0_434) : !cute.int_tuple<"?">
      %181 = cute.get_scalars(%e1_435) : !cute.int_tuple<"?{div=8}">
      %iter_436 = cute.get_iter(%view_429) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_437, %e1_438 = cute.get_leaves(%iter_436) : !cute.int_tuple<"(?,?{div=8})">
      %182 = cute.get_scalars(%e0_437) : !cute.int_tuple<"?">
      %183 = cute.get_scalars(%e1_438) : !cute.int_tuple<"?{div=8}">
      %coord_439 = cute.make_coord(%e1_438) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_440 = cute.make_coord() : () -> !cute.coord<"4096">
      %184 = cute.get_scalars(%coord_439) : !cute.coord<"?{div=8}">
      %185 = cute.get_scalars(%coord_440) : !cute.coord<"4096">
      %true_441 = arith.constant true
      %186 = arith.cmpi slt, %184, %185 : i32
      %187 = arith.andi %true_441, %186 : i1
      %188 = arith.extui %187 : i1 to i8
      %coord_442 = cute.make_coord() : () -> !cute.coord<"(1,0,0)">
      cute.memref.store(%rmem_398, %coord_442, %188) : (!memref_rmem_i8_, !cute.coord<"(1,0,0)">, i8) -> ()
      %coord_443 = cute.make_coord() : () -> !cute.coord<"((0,2),0,0)">
      %lay_444 = cute.get_layout(%view_379) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %idx_445 = cute.crd2idx(%coord_443, %lay_444) : (!cute.coord<"((0,2),0,0)">, !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"(0,1024)">
      %iter_446 = cute.get_iter(%view_379) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %tup_447 = cute.add_offset(%iter_446, %idx_445) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,1024)">) -> !cute.int_tuple<"(?,?{div=8})">
      %view_448 = cute.make_view(%tup_447) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %iter_449 = cute.get_iter(%view_448) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_450, %e1_451 = cute.get_leaves(%iter_449) : !cute.int_tuple<"(?,?{div=8})">
      %189 = cute.get_scalars(%e0_450) : !cute.int_tuple<"?">
      %190 = cute.get_scalars(%e1_451) : !cute.int_tuple<"?{div=8}">
      %iter_452 = cute.get_iter(%view_448) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_453, %e1_454 = cute.get_leaves(%iter_452) : !cute.int_tuple<"(?,?{div=8})">
      %191 = cute.get_scalars(%e0_453) : !cute.int_tuple<"?">
      %192 = cute.get_scalars(%e1_454) : !cute.int_tuple<"?{div=8}">
      %iter_455 = cute.get_iter(%view_448) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_456, %e1_457 = cute.get_leaves(%iter_455) : !cute.int_tuple<"(?,?{div=8})">
      %193 = cute.get_scalars(%e0_456) : !cute.int_tuple<"?">
      %194 = cute.get_scalars(%e1_457) : !cute.int_tuple<"?{div=8}">
      %coord_458 = cute.make_coord(%e1_457) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_459 = cute.make_coord() : () -> !cute.coord<"4096">
      %195 = cute.get_scalars(%coord_458) : !cute.coord<"?{div=8}">
      %196 = cute.get_scalars(%coord_459) : !cute.coord<"4096">
      %true_460 = arith.constant true
      %197 = arith.cmpi slt, %195, %196 : i32
      %198 = arith.andi %true_460, %197 : i1
      %199 = arith.extui %198 : i1 to i8
      %coord_461 = cute.make_coord() : () -> !cute.coord<"(2,0,0)">
      cute.memref.store(%rmem_398, %coord_461, %199) : (!memref_rmem_i8_, !cute.coord<"(2,0,0)">, i8) -> ()
      %coord_462 = cute.make_coord() : () -> !cute.coord<"((0,3),0,0)">
      %lay_463 = cute.get_layout(%view_379) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %idx_464 = cute.crd2idx(%coord_462, %lay_463) : (!cute.coord<"((0,3),0,0)">, !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"(0,1536)">
      %iter_465 = cute.get_iter(%view_379) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %tup_466 = cute.add_offset(%iter_465, %idx_464) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,1536)">) -> !cute.int_tuple<"(?,?{div=8})">
      %view_467 = cute.make_view(%tup_466) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %iter_468 = cute.get_iter(%view_467) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_469, %e1_470 = cute.get_leaves(%iter_468) : !cute.int_tuple<"(?,?{div=8})">
      %200 = cute.get_scalars(%e0_469) : !cute.int_tuple<"?">
      %201 = cute.get_scalars(%e1_470) : !cute.int_tuple<"?{div=8}">
      %iter_471 = cute.get_iter(%view_467) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_472, %e1_473 = cute.get_leaves(%iter_471) : !cute.int_tuple<"(?,?{div=8})">
      %202 = cute.get_scalars(%e0_472) : !cute.int_tuple<"?">
      %203 = cute.get_scalars(%e1_473) : !cute.int_tuple<"?{div=8}">
      %iter_474 = cute.get_iter(%view_467) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_475, %e1_476 = cute.get_leaves(%iter_474) : !cute.int_tuple<"(?,?{div=8})">
      %204 = cute.get_scalars(%e0_475) : !cute.int_tuple<"?">
      %205 = cute.get_scalars(%e1_476) : !cute.int_tuple<"?{div=8}">
      %coord_477 = cute.make_coord(%e1_476) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_478 = cute.make_coord() : () -> !cute.coord<"4096">
      %206 = cute.get_scalars(%coord_477) : !cute.coord<"?{div=8}">
      %207 = cute.get_scalars(%coord_478) : !cute.coord<"4096">
      %true_479 = arith.constant true
      %208 = arith.cmpi slt, %206, %207 : i32
      %209 = arith.andi %true_479, %208 : i1
      %210 = arith.extui %209 : i1 to i8
      %coord_480 = cute.make_coord() : () -> !cute.coord<"(3,0,0)">
      cute.memref.store(%rmem_398, %coord_480, %210) : (!memref_rmem_i8_, !cute.coord<"(3,0,0)">, i8) -> ()
      %coord_481 = cute.make_coord() : () -> !cute.coord<"((0,4),0,0)">
      %lay_482 = cute.get_layout(%view_379) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %idx_483 = cute.crd2idx(%coord_481, %lay_482) : (!cute.coord<"((0,4),0,0)">, !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"(0,2048)">
      %iter_484 = cute.get_iter(%view_379) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %tup_485 = cute.add_offset(%iter_484, %idx_483) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,2048)">) -> !cute.int_tuple<"(?,?{div=8})">
      %view_486 = cute.make_view(%tup_485) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %iter_487 = cute.get_iter(%view_486) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_488, %e1_489 = cute.get_leaves(%iter_487) : !cute.int_tuple<"(?,?{div=8})">
      %211 = cute.get_scalars(%e0_488) : !cute.int_tuple<"?">
      %212 = cute.get_scalars(%e1_489) : !cute.int_tuple<"?{div=8}">
      %iter_490 = cute.get_iter(%view_486) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_491, %e1_492 = cute.get_leaves(%iter_490) : !cute.int_tuple<"(?,?{div=8})">
      %213 = cute.get_scalars(%e0_491) : !cute.int_tuple<"?">
      %214 = cute.get_scalars(%e1_492) : !cute.int_tuple<"?{div=8}">
      %iter_493 = cute.get_iter(%view_486) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_494, %e1_495 = cute.get_leaves(%iter_493) : !cute.int_tuple<"(?,?{div=8})">
      %215 = cute.get_scalars(%e0_494) : !cute.int_tuple<"?">
      %216 = cute.get_scalars(%e1_495) : !cute.int_tuple<"?{div=8}">
      %coord_496 = cute.make_coord(%e1_495) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_497 = cute.make_coord() : () -> !cute.coord<"4096">
      %217 = cute.get_scalars(%coord_496) : !cute.coord<"?{div=8}">
      %218 = cute.get_scalars(%coord_497) : !cute.coord<"4096">
      %true_498 = arith.constant true
      %219 = arith.cmpi slt, %217, %218 : i32
      %220 = arith.andi %true_498, %219 : i1
      %221 = arith.extui %220 : i1 to i8
      %coord_499 = cute.make_coord() : () -> !cute.coord<"(4,0,0)">
      cute.memref.store(%rmem_398, %coord_499, %221) : (!memref_rmem_i8_, !cute.coord<"(4,0,0)">, i8) -> ()
      %coord_500 = cute.make_coord() : () -> !cute.coord<"((0,5),0,0)">
      %lay_501 = cute.get_layout(%view_379) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %idx_502 = cute.crd2idx(%coord_500, %lay_501) : (!cute.coord<"((0,5),0,0)">, !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"(0,2560)">
      %iter_503 = cute.get_iter(%view_379) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %tup_504 = cute.add_offset(%iter_503, %idx_502) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,2560)">) -> !cute.int_tuple<"(?,?{div=8})">
      %view_505 = cute.make_view(%tup_504) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %iter_506 = cute.get_iter(%view_505) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_507, %e1_508 = cute.get_leaves(%iter_506) : !cute.int_tuple<"(?,?{div=8})">
      %222 = cute.get_scalars(%e0_507) : !cute.int_tuple<"?">
      %223 = cute.get_scalars(%e1_508) : !cute.int_tuple<"?{div=8}">
      %iter_509 = cute.get_iter(%view_505) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_510, %e1_511 = cute.get_leaves(%iter_509) : !cute.int_tuple<"(?,?{div=8})">
      %224 = cute.get_scalars(%e0_510) : !cute.int_tuple<"?">
      %225 = cute.get_scalars(%e1_511) : !cute.int_tuple<"?{div=8}">
      %iter_512 = cute.get_iter(%view_505) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_513, %e1_514 = cute.get_leaves(%iter_512) : !cute.int_tuple<"(?,?{div=8})">
      %226 = cute.get_scalars(%e0_513) : !cute.int_tuple<"?">
      %227 = cute.get_scalars(%e1_514) : !cute.int_tuple<"?{div=8}">
      %coord_515 = cute.make_coord(%e1_514) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_516 = cute.make_coord() : () -> !cute.coord<"4096">
      %228 = cute.get_scalars(%coord_515) : !cute.coord<"?{div=8}">
      %229 = cute.get_scalars(%coord_516) : !cute.coord<"4096">
      %true_517 = arith.constant true
      %230 = arith.cmpi slt, %228, %229 : i32
      %231 = arith.andi %true_517, %230 : i1
      %232 = arith.extui %231 : i1 to i8
      %coord_518 = cute.make_coord() : () -> !cute.coord<"(5,0,0)">
      cute.memref.store(%rmem_398, %coord_518, %232) : (!memref_rmem_i8_, !cute.coord<"(5,0,0)">, i8) -> ()
      %coord_519 = cute.make_coord() : () -> !cute.coord<"((0,6),0,0)">
      %lay_520 = cute.get_layout(%view_379) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %idx_521 = cute.crd2idx(%coord_519, %lay_520) : (!cute.coord<"((0,6),0,0)">, !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"(0,3072)">
      %iter_522 = cute.get_iter(%view_379) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %tup_523 = cute.add_offset(%iter_522, %idx_521) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,3072)">) -> !cute.int_tuple<"(?,?{div=8})">
      %view_524 = cute.make_view(%tup_523) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %iter_525 = cute.get_iter(%view_524) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_526, %e1_527 = cute.get_leaves(%iter_525) : !cute.int_tuple<"(?,?{div=8})">
      %233 = cute.get_scalars(%e0_526) : !cute.int_tuple<"?">
      %234 = cute.get_scalars(%e1_527) : !cute.int_tuple<"?{div=8}">
      %iter_528 = cute.get_iter(%view_524) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_529, %e1_530 = cute.get_leaves(%iter_528) : !cute.int_tuple<"(?,?{div=8})">
      %235 = cute.get_scalars(%e0_529) : !cute.int_tuple<"?">
      %236 = cute.get_scalars(%e1_530) : !cute.int_tuple<"?{div=8}">
      %iter_531 = cute.get_iter(%view_524) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_532, %e1_533 = cute.get_leaves(%iter_531) : !cute.int_tuple<"(?,?{div=8})">
      %237 = cute.get_scalars(%e0_532) : !cute.int_tuple<"?">
      %238 = cute.get_scalars(%e1_533) : !cute.int_tuple<"?{div=8}">
      %coord_534 = cute.make_coord(%e1_533) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_535 = cute.make_coord() : () -> !cute.coord<"4096">
      %239 = cute.get_scalars(%coord_534) : !cute.coord<"?{div=8}">
      %240 = cute.get_scalars(%coord_535) : !cute.coord<"4096">
      %true_536 = arith.constant true
      %241 = arith.cmpi slt, %239, %240 : i32
      %242 = arith.andi %true_536, %241 : i1
      %243 = arith.extui %242 : i1 to i8
      %coord_537 = cute.make_coord() : () -> !cute.coord<"(6,0,0)">
      cute.memref.store(%rmem_398, %coord_537, %243) : (!memref_rmem_i8_, !cute.coord<"(6,0,0)">, i8) -> ()
      %coord_538 = cute.make_coord() : () -> !cute.coord<"((0,7),0,0)">
      %lay_539 = cute.get_layout(%view_379) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %idx_540 = cute.crd2idx(%coord_538, %lay_539) : (!cute.coord<"((0,7),0,0)">, !cute.layout<"((8,8),1,1):((1@1,512@1),0,0)">) -> !cute.int_tuple<"(0,3584)">
      %iter_541 = cute.get_iter(%view_379) : !cute.coord_tensor<"(?,?{div=8})", "((8,8),1,1):((1@1,512@1),0,0)">
      %tup_542 = cute.add_offset(%iter_541, %idx_540) : (!cute.int_tuple<"(?,?{div=8})">, !cute.int_tuple<"(0,3584)">) -> !cute.int_tuple<"(?,?{div=8})">
      %view_543 = cute.make_view(%tup_542) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %iter_544 = cute.get_iter(%view_543) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_545, %e1_546 = cute.get_leaves(%iter_544) : !cute.int_tuple<"(?,?{div=8})">
      %244 = cute.get_scalars(%e0_545) : !cute.int_tuple<"?">
      %245 = cute.get_scalars(%e1_546) : !cute.int_tuple<"?{div=8}">
      %iter_547 = cute.get_iter(%view_543) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_548, %e1_549 = cute.get_leaves(%iter_547) : !cute.int_tuple<"(?,?{div=8})">
      %246 = cute.get_scalars(%e0_548) : !cute.int_tuple<"?">
      %247 = cute.get_scalars(%e1_549) : !cute.int_tuple<"?{div=8}">
      %iter_550 = cute.get_iter(%view_543) : !cute.coord_tensor<"(?,?{div=8})", "():()">
      %e0_551, %e1_552 = cute.get_leaves(%iter_550) : !cute.int_tuple<"(?,?{div=8})">
      %248 = cute.get_scalars(%e0_551) : !cute.int_tuple<"?">
      %249 = cute.get_scalars(%e1_552) : !cute.int_tuple<"?{div=8}">
      %coord_553 = cute.make_coord(%e1_552) : (!cute.int_tuple<"?{div=8}">) -> !cute.coord<"?{div=8}">
      %coord_554 = cute.make_coord() : () -> !cute.coord<"4096">
      %250 = cute.get_scalars(%coord_553) : !cute.coord<"?{div=8}">
      %251 = cute.get_scalars(%coord_554) : !cute.coord<"4096">
      %true_555 = arith.constant true
      %252 = arith.cmpi slt, %250, %251 : i32
      %253 = arith.andi %true_555, %252 : i1
      %254 = arith.extui %253 : i1 to i8
      %coord_556 = cute.make_coord() : () -> !cute.coord<"(7,0,0)">
      cute.memref.store(%rmem_398, %coord_556, %254) : (!memref_rmem_i8_, !cute.coord<"(7,0,0)">, i8) -> ()
      %lay_557 = cute.get_layout(%view_174) : !memref_gmem_bf16_5
      %255 = cute.get_shape(%lay_557) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %e0_558, %e1_559, %e2_560, %e3_561 = cute.get_leaves(%255) : !cute.shape<"((8,8),1,1)">
      %lay_562 = cute.get_layout(%rmem_178) : !memref_rmem_bf16_
      %256 = cute.get_shape(%lay_562) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %e0_563, %e1_564, %e2_565, %e3_566 = cute.get_leaves(%256) : !cute.shape<"((8,8),1,1)">
      %lay_567 = cute.get_layout(%view_174) : !memref_gmem_bf16_5
      %shape_568 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_569 = cute.make_layout() : !cute.layout<"1:0">
      %append = cute.append_to_rank<2> (%lay_567, %lay_569) : !cute.layout<"((8,8),1,1):((1,512),0,0)">, !cute.layout<"1:0">
      %view_570 = cute.make_view(%iter_175, %append) : !memref_gmem_bf16_5
      %iter_571 = cute.get_iter(%view_570) : !memref_gmem_bf16_5
      %lay_572 = cute.get_layout(%view_570) : !memref_gmem_bf16_5
      %257 = cute.get_shape(%lay_572) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %e0_573, %e1_574, %e2_575, %e3_576 = cute.get_leaves(%257) : !cute.shape<"((8,8),1,1)">
      %iter_577 = cute.get_iter(%view_570) : !memref_gmem_bf16_5
      %view_578 = cute.make_view(%iter_577) : !memref_gmem_bf16_6
      %iter_579 = cute.get_iter(%view_578) : !memref_gmem_bf16_6
      %iter_580 = cute.get_iter(%view_578) : !memref_gmem_bf16_6
      %lay_581 = cute.get_layout(%rmem_178) : !memref_rmem_bf16_
      %shape_582 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_583 = cute.make_layout() : !cute.layout<"1:0">
      %append_584 = cute.append_to_rank<2> (%lay_581, %lay_583) : !cute.layout<"((8,8),1,1):((1,8),0,0)">, !cute.layout<"1:0">
      %view_585 = cute.make_view(%iter_180, %append_584) : !memref_rmem_bf16_
      %iter_586 = cute.get_iter(%view_585) : !memref_rmem_bf16_
      %lay_587 = cute.get_layout(%view_585) : !memref_rmem_bf16_
      %258 = cute.get_shape(%lay_587) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %e0_588, %e1_589, %e2_590, %e3_591 = cute.get_leaves(%258) : !cute.shape<"((8,8),1,1)">
      %iter_592 = cute.get_iter(%view_585) : !memref_rmem_bf16_
      %view_593 = cute.make_view(%iter_592) : !memref_rmem_bf16_1
      %iter_594 = cute.get_iter(%view_593) : !memref_rmem_bf16_1
      %iter_595 = cute.get_iter(%view_593) : !memref_rmem_bf16_1
      %lay_596 = cute.get_layout(%rmem_398) : !memref_rmem_i8_
      %shape_597 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_598 = cute.make_layout() : !cute.layout<"1:0">
      %append_599 = cute.append_to_rank<2> (%lay_596, %lay_598) : !cute.layout<"(8,1,1):(1,0,1)">, !cute.layout<"1:0">
      %view_600 = cute.make_view(%iter_400, %append_599) : !memref_rmem_i8_
      %iter_601 = cute.get_iter(%view_600) : !memref_rmem_i8_
      %lay_602 = cute.get_layout(%view_600) : !memref_rmem_i8_
      %259 = cute.get_shape(%lay_602) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
      %e0_603, %e1_604, %e2_605 = cute.get_leaves(%259) : !cute.shape<"(8,1,1)">
      %iter_606 = cute.get_iter(%view_600) : !memref_rmem_i8_
      %view_607 = cute.make_view(%iter_606) : !memref_rmem_i8_1
      %iter_608 = cute.get_iter(%view_607) : !memref_rmem_i8_1
      %iter_609 = cute.get_iter(%view_607) : !memref_rmem_i8_1
      %lay_610 = cute.get_layout(%view_578) : !memref_gmem_bf16_6
      %260 = cute.get_shape(%lay_610) : (!cute.layout<"((8,8),(1,1)):((1,512),(0,0))">) -> !cute.shape<"((8,8),(1,1))">
      %e0_611, %e1_612, %e2_613, %e3_614 = cute.get_leaves(%260) : !cute.shape<"((8,8),(1,1))">
      %lay_615 = cute.get_layout(%view_593) : !memref_rmem_bf16_1
      %261 = cute.get_shape(%lay_615) : (!cute.layout<"((8,8),(1,1)):((1,8),(0,0))">) -> !cute.shape<"((8,8),(1,1))">
      %e0_616, %e1_617, %e2_618, %e3_619 = cute.get_leaves(%261) : !cute.shape<"((8,8),(1,1))">
      %lay_620 = cute.get_layout(%view_578) : !memref_gmem_bf16_6
      %sz_621 = cute.size(%lay_620) <{mode = [1]}> : (!cute.layout<"((8,8),(1,1)):((1,512),(0,0))">) -> !cute.int_tuple<"1">
      %e0_622 = cute.get_leaves(%sz_621) : !cute.int_tuple<"1">
      %lay_623 = cute.get_layout(%view_593) : !memref_rmem_bf16_1
      %sz_624 = cute.size(%lay_623) <{mode = [1]}> : (!cute.layout<"((8,8),(1,1)):((1,8),(0,0))">) -> !cute.int_tuple<"1">
      %e0_625 = cute.get_leaves(%sz_624) : !cute.int_tuple<"1">
      %262 = cute.static : !cute.layout<"1:0">
      %iter_626 = cute.get_iter(%view_578) : !memref_gmem_bf16_6
      %iter_627 = cute.get_iter(%view_593) : !memref_rmem_bf16_1
      %lay_628 = cute.get_layout(%view_578) : !memref_gmem_bf16_6
      %lay_629 = cute.get_layout(%view_593) : !memref_rmem_bf16_1
      %append_630 = cute.append_to_rank<2> (%lay_628, %262) : !cute.layout<"((8,8),(1,1)):((1,512),(0,0))">, !cute.layout<"1:0">
      %append_631 = cute.append_to_rank<2> (%lay_629, %262) : !cute.layout<"((8,8),(1,1)):((1,8),(0,0))">, !cute.layout<"1:0">
      %lay_632 = cute.make_layout() : !cute.layout<"((8,8),((1,1))):((1,512),((0,0)))">
      %lay_633 = cute.make_layout() : !cute.layout<"((8,8),((1,1))):((1,8),((0,0)))">
      %iter_634 = cute.get_iter(%view_607) : !memref_rmem_i8_1
      %lay_635 = cute.get_layout(%view_607) : !memref_rmem_i8_1
      %append_636 = cute.append_to_rank<2> (%lay_635, %262) : !cute.layout<"(8,(1,1)):(1,(0,1))">, !cute.layout<"1:0">
      %lay_637 = cute.make_layout() : !cute.layout<"(8,((1,1))):(1,((0,1)))">
      %sz_638 = cute.size(%lay_632) <{mode = [1]}> : (!cute.layout<"((8,8),((1,1))):((1,512),((0,0)))">) -> !cute.int_tuple<"1">
      %263 = cute.get_scalars(%sz_638) : !cute.int_tuple<"1">
      %c0_i32 = arith.constant 0 : i32
      %c1_i32 = arith.constant 1 : i32
      scf.for %arg4 = %c0_i32 to %263 step %c1_i32  : i32 {
        %coord_788 = cute.make_coord(%arg4) : (i32) -> !cute.coord<"(_,?)">
        %334 = cute.get_scalars(%coord_788) <{only_dynamic}> : !cute.coord<"(_,?)">
        %lay_789 = cute.make_layout() : !cute.layout<"((8,8)):((1,512))">
        %idx_790 = cute.crd2idx(%coord_788, %lay_632) : (!cute.coord<"(_,?)">, !cute.layout<"((8,8),((1,1))):((1,512),((0,0)))">) -> !cute.int_tuple<"0">
        %ptr_791 = cute.add_offset(%iter_626, %idx_790) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, gmem, align<16>>
        %view_792 = cute.make_view(%ptr_791, %lay_789) : !memref_gmem_bf16_7
        %335 = cute.get_scalars(%coord_788) <{only_dynamic}> : !cute.coord<"(_,?)">
        %lay_793 = cute.make_layout() : !cute.layout<"((8,8)):((1,8))">
        %idx_794 = cute.crd2idx(%coord_788, %lay_633) : (!cute.coord<"(_,?)">, !cute.layout<"((8,8),((1,1))):((1,8),((0,0)))">) -> !cute.int_tuple<"0">
        %ptr_795 = cute.add_offset(%iter_627, %idx_794) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, rmem, align<32>>
        %view_796 = cute.make_view(%ptr_795, %lay_793) : !memref_rmem_bf16_2
        %336 = cute.get_scalars(%coord_788) <{only_dynamic}> : !cute.coord<"(_,?)">
        %lay_797 = cute.make_layout() : !cute.layout<"(8):(1)">
        %idx_798 = cute.crd2idx(%coord_788, %lay_637) : (!cute.coord<"(_,?)">, !cute.layout<"(8,((1,1))):(1,((0,1)))">) -> !cute.int_tuple<"?">
        %ptr_799 = cute.add_offset(%iter_634, %idx_798) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
        %view_800 = cute.make_view(%ptr_799, %lay_797) : !memref_rmem_i8_2
        %iter_801 = cute.get_iter(%view_792) : !memref_gmem_bf16_7
        %iter_802 = cute.get_iter(%view_796) : !memref_rmem_bf16_2
        %iter_803 = cute.get_iter(%view_800) : !memref_rmem_i8_2
        %337 = builtin.unrealized_conversion_cast %iter_803 : !cute.ptr<i8, rmem> to !llvm.ptr
        %338 = llvm.load %337 : !llvm.ptr -> i8
        %339 = llvm.mlir.constant(0 : i8) : i8
        %340 = llvm.icmp "ne" %338, %339 : i8
        scf.if %340 {
          %369 = builtin.unrealized_conversion_cast %iter_801 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
          %370 = builtin.unrealized_conversion_cast %iter_802 : !cute.ptr<bf16, rmem, align<32>> to !llvm.ptr
          %371 = llvm.load %369 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
          llvm.store %371, %370 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
        }
        %int_tuple_804 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
        %ptr_805 = cute.add_offset(%iter_803, %int_tuple_804) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
        %341 = builtin.unrealized_conversion_cast %ptr_805 : !cute.ptr<i8, rmem> to !llvm.ptr
        %342 = llvm.load %341 : !llvm.ptr -> i8
        %343 = llvm.mlir.constant(0 : i8) : i8
        %344 = llvm.icmp "ne" %342, %343 : i8
        scf.if %344 {
          %int_tuple_818 = cute.make_int_tuple() : () -> !cute.int_tuple<"512">
          %ptr_819 = cute.add_offset(%iter_801, %int_tuple_818) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"512">) -> !cute.ptr<bf16, gmem, align<16>>
          %int_tuple_820 = cute.make_int_tuple() : () -> !cute.int_tuple<"8">
          %ptr_821 = cute.add_offset(%iter_802, %int_tuple_820) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<bf16, rmem, align<16>>
          %369 = builtin.unrealized_conversion_cast %ptr_819 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
          %370 = builtin.unrealized_conversion_cast %ptr_821 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
          %371 = llvm.load %369 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
          llvm.store %371, %370 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
        }
        %int_tuple_806 = cute.make_int_tuple() : () -> !cute.int_tuple<"2">
        %ptr_807 = cute.add_offset(%iter_803, %int_tuple_806) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem>
        %345 = builtin.unrealized_conversion_cast %ptr_807 : !cute.ptr<i8, rmem> to !llvm.ptr
        %346 = llvm.load %345 : !llvm.ptr -> i8
        %347 = llvm.mlir.constant(0 : i8) : i8
        %348 = llvm.icmp "ne" %346, %347 : i8
        scf.if %348 {
          %int_tuple_818 = cute.make_int_tuple() : () -> !cute.int_tuple<"1024">
          %ptr_819 = cute.add_offset(%iter_801, %int_tuple_818) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, gmem, align<16>>
          %int_tuple_820 = cute.make_int_tuple() : () -> !cute.int_tuple<"16">
          %ptr_821 = cute.add_offset(%iter_802, %int_tuple_820) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"16">) -> !cute.ptr<bf16, rmem, align<32>>
          %369 = builtin.unrealized_conversion_cast %ptr_819 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
          %370 = builtin.unrealized_conversion_cast %ptr_821 : !cute.ptr<bf16, rmem, align<32>> to !llvm.ptr
          %371 = llvm.load %369 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
          llvm.store %371, %370 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
        }
        %int_tuple_808 = cute.make_int_tuple() : () -> !cute.int_tuple<"3">
        %ptr_809 = cute.add_offset(%iter_803, %int_tuple_808) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
        %349 = builtin.unrealized_conversion_cast %ptr_809 : !cute.ptr<i8, rmem> to !llvm.ptr
        %350 = llvm.load %349 : !llvm.ptr -> i8
        %351 = llvm.mlir.constant(0 : i8) : i8
        %352 = llvm.icmp "ne" %350, %351 : i8
        scf.if %352 {
          %int_tuple_818 = cute.make_int_tuple() : () -> !cute.int_tuple<"1536">
          %ptr_819 = cute.add_offset(%iter_801, %int_tuple_818) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"1536">) -> !cute.ptr<bf16, gmem, align<16>>
          %int_tuple_820 = cute.make_int_tuple() : () -> !cute.int_tuple<"24">
          %ptr_821 = cute.add_offset(%iter_802, %int_tuple_820) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"24">) -> !cute.ptr<bf16, rmem, align<16>>
          %369 = builtin.unrealized_conversion_cast %ptr_819 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
          %370 = builtin.unrealized_conversion_cast %ptr_821 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
          %371 = llvm.load %369 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
          llvm.store %371, %370 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
        }
        %int_tuple_810 = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
        %ptr_811 = cute.add_offset(%iter_803, %int_tuple_810) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem>
        %353 = builtin.unrealized_conversion_cast %ptr_811 : !cute.ptr<i8, rmem> to !llvm.ptr
        %354 = llvm.load %353 : !llvm.ptr -> i8
        %355 = llvm.mlir.constant(0 : i8) : i8
        %356 = llvm.icmp "ne" %354, %355 : i8
        scf.if %356 {
          %int_tuple_818 = cute.make_int_tuple() : () -> !cute.int_tuple<"2048">
          %ptr_819 = cute.add_offset(%iter_801, %int_tuple_818) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, gmem, align<16>>
          %int_tuple_820 = cute.make_int_tuple() : () -> !cute.int_tuple<"32">
          %ptr_821 = cute.add_offset(%iter_802, %int_tuple_820) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<32>>
          %369 = builtin.unrealized_conversion_cast %ptr_819 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
          %370 = builtin.unrealized_conversion_cast %ptr_821 : !cute.ptr<bf16, rmem, align<32>> to !llvm.ptr
          %371 = llvm.load %369 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
          llvm.store %371, %370 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
        }
        %int_tuple_812 = cute.make_int_tuple() : () -> !cute.int_tuple<"5">
        %ptr_813 = cute.add_offset(%iter_803, %int_tuple_812) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
        %357 = builtin.unrealized_conversion_cast %ptr_813 : !cute.ptr<i8, rmem> to !llvm.ptr
        %358 = llvm.load %357 : !llvm.ptr -> i8
        %359 = llvm.mlir.constant(0 : i8) : i8
        %360 = llvm.icmp "ne" %358, %359 : i8
        scf.if %360 {
          %int_tuple_818 = cute.make_int_tuple() : () -> !cute.int_tuple<"2560">
          %ptr_819 = cute.add_offset(%iter_801, %int_tuple_818) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"2560">) -> !cute.ptr<bf16, gmem, align<16>>
          %int_tuple_820 = cute.make_int_tuple() : () -> !cute.int_tuple<"40">
          %ptr_821 = cute.add_offset(%iter_802, %int_tuple_820) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"40">) -> !cute.ptr<bf16, rmem, align<16>>
          %369 = builtin.unrealized_conversion_cast %ptr_819 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
          %370 = builtin.unrealized_conversion_cast %ptr_821 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
          %371 = llvm.load %369 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
          llvm.store %371, %370 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
        }
        %int_tuple_814 = cute.make_int_tuple() : () -> !cute.int_tuple<"6">
        %ptr_815 = cute.add_offset(%iter_803, %int_tuple_814) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem>
        %361 = builtin.unrealized_conversion_cast %ptr_815 : !cute.ptr<i8, rmem> to !llvm.ptr
        %362 = llvm.load %361 : !llvm.ptr -> i8
        %363 = llvm.mlir.constant(0 : i8) : i8
        %364 = llvm.icmp "ne" %362, %363 : i8
        scf.if %364 {
          %int_tuple_818 = cute.make_int_tuple() : () -> !cute.int_tuple<"3072">
          %ptr_819 = cute.add_offset(%iter_801, %int_tuple_818) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, gmem, align<16>>
          %int_tuple_820 = cute.make_int_tuple() : () -> !cute.int_tuple<"48">
          %ptr_821 = cute.add_offset(%iter_802, %int_tuple_820) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"48">) -> !cute.ptr<bf16, rmem, align<32>>
          %369 = builtin.unrealized_conversion_cast %ptr_819 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
          %370 = builtin.unrealized_conversion_cast %ptr_821 : !cute.ptr<bf16, rmem, align<32>> to !llvm.ptr
          %371 = llvm.load %369 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
          llvm.store %371, %370 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
        }
        %int_tuple_816 = cute.make_int_tuple() : () -> !cute.int_tuple<"7">
        %ptr_817 = cute.add_offset(%iter_803, %int_tuple_816) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
        %365 = builtin.unrealized_conversion_cast %ptr_817 : !cute.ptr<i8, rmem> to !llvm.ptr
        %366 = llvm.load %365 : !llvm.ptr -> i8
        %367 = llvm.mlir.constant(0 : i8) : i8
        %368 = llvm.icmp "ne" %366, %367 : i8
        scf.if %368 {
          %int_tuple_818 = cute.make_int_tuple() : () -> !cute.int_tuple<"3584">
          %ptr_819 = cute.add_offset(%iter_801, %int_tuple_818) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"3584">) -> !cute.ptr<bf16, gmem, align<16>>
          %int_tuple_820 = cute.make_int_tuple() : () -> !cute.int_tuple<"56">
          %ptr_821 = cute.add_offset(%iter_802, %int_tuple_820) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"56">) -> !cute.ptr<bf16, rmem, align<16>>
          %369 = builtin.unrealized_conversion_cast %ptr_819 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
          %370 = builtin.unrealized_conversion_cast %ptr_821 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
          %371 = llvm.load %369 {alignment = 16 : i64} : !llvm.ptr<1> -> vector<8xbf16>
          llvm.store %371, %370 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
        }
      } {llvm.loop_annotation = #loop_annotation}
      nvvm.cp.async.wait.group 0
      %lay_639 = cute.get_layout(%view_132) : !memref_smem_bf16_1
      %264 = cute.get_shape(%lay_639) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %e0_640, %e1_641, %e2_642, %e3_643 = cute.get_leaves(%264) : !cute.shape<"((8,8),1,1)">
      %lay_644 = cute.get_layout(%rmem) : !memref_rmem_bf16_
      %265 = cute.get_shape(%lay_644) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %e0_645, %e1_646, %e2_647, %e3_648 = cute.get_leaves(%265) : !cute.shape<"((8,8),1,1)">
      %lay_649 = cute.get_layout(%view_132) : !memref_smem_bf16_1
      %lay_650 = cute.get_layout(%rmem) : !memref_rmem_bf16_
      %rinv = cute.right_inverse(%lay_650) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.layout<"64:1">
      %lay_651 = cute.make_layout() : !cute.layout<"(8,8):(1,512)">
      %coalesce = cute.coalesce(%lay_651) : (!cute.layout<"(8,8):(1,512)">) -> !cute.layout<"(8,8):(1,512)">
      %266 = cute.get_shape(%coalesce) : (!cute.layout<"(8,8):(1,512)">) -> !cute.shape<"(8,8)">
      %e0_652, %e1_653 = cute.get_leaves(%266) : !cute.shape<"(8,8)">
      %267 = cute.get_stride(%coalesce) : (!cute.layout<"(8,8):(1,512)">) -> !cute.stride<"(1,512)">
      %e0_654, %e1_655 = cute.get_leaves(%267) : !cute.stride<"(1,512)">
      %268 = cute.get_shape(%coalesce) : (!cute.layout<"(8,8):(1,512)">) -> !cute.shape<"(8,8)">
      %e0_656, %e1_657 = cute.get_leaves(%268) : !cute.shape<"(8,8)">
      %269 = cute.get_shape(%coalesce) : (!cute.layout<"(8,8):(1,512)">) -> !cute.shape<"(8,8)">
      %e0_658, %e1_659 = cute.get_leaves(%269) : !cute.shape<"(8,8)">
      %lay_660 = cute.make_layout() : !cute.layout<"8:1">
      %lay_661 = cute.make_layout() : !cute.layout<"8:1">
      %sz_662 = cute.size(%lay_661) : (!cute.layout<"8:1">) -> !cute.int_tuple<"8">
      %e0_663 = cute.get_leaves(%sz_662) : !cute.int_tuple<"8">
      %lay_664 = cute.get_layout(%view_132) : !memref_smem_bf16_1
      %lay_665 = cute.get_layout(%rmem) : !memref_rmem_bf16_
      %iter_666 = cute.get_iter(%view_132) : !memref_smem_bf16_1
      %view_667 = cute.make_view(%iter_666) : !memref_smem_bf16_4
      %iter_668 = cute.get_iter(%view_667) : !memref_smem_bf16_4
      %iter_669 = cute.get_iter(%view_667) : !memref_smem_bf16_4
      %iter_670 = cute.get_iter(%rmem) : !memref_rmem_bf16_
      %view_671 = cute.make_view(%iter_670) : !memref_rmem_bf16_3
      %iter_672 = cute.get_iter(%view_671) : !memref_rmem_bf16_3
      %iter_673 = cute.get_iter(%view_671) : !memref_rmem_bf16_3
      %shape_674 = cute.make_shape() : () -> !cute.shape<"8">
      %lay_675 = cute.make_layout() : !cute.layout<"8:1">
      %iter_676 = cute.get_iter(%view_667) : !memref_smem_bf16_4
      %view_677 = cute.make_view(%iter_676) : !memref_smem_bf16_4
      %iter_678 = cute.get_iter(%view_677) : !memref_smem_bf16_4
      %iter_679 = cute.get_iter(%view_677) : !memref_smem_bf16_4
      %shape_680 = cute.make_shape() : () -> !cute.shape<"8">
      %lay_681 = cute.make_layout() : !cute.layout<"8:1">
      %iter_682 = cute.get_iter(%view_671) : !memref_rmem_bf16_3
      %view_683 = cute.make_view(%iter_682) : !memref_rmem_bf16_3
      %iter_684 = cute.get_iter(%view_683) : !memref_rmem_bf16_3
      %iter_685 = cute.get_iter(%view_683) : !memref_rmem_bf16_3
      %atom_686 = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<bf16, 128 b>
      %270 = cute.static : !cute.layout<"1:0">
      %iter_687 = cute.get_iter(%view_677) : !memref_smem_bf16_4
      %iter_688 = cute.get_iter(%view_683) : !memref_rmem_bf16_3
      %lay_689 = cute.get_layout(%view_677) : !memref_smem_bf16_4
      %lay_690 = cute.get_layout(%view_683) : !memref_rmem_bf16_3
      %append_691 = cute.append_to_rank<2> (%lay_689, %270) : !cute.layout<"(8,8):(1,512)">, !cute.layout<"1:0">
      %append_692 = cute.append_to_rank<2> (%lay_690, %270) : !cute.layout<"(8,8):(1,8)">, !cute.layout<"1:0">
      %lay_693 = cute.make_layout() : !cute.layout<"(8,(8)):(1,(512))">
      %lay_694 = cute.make_layout() : !cute.layout<"(8,(8)):(1,(8))">
      %sz_695 = cute.size(%lay_693) <{mode = [1]}> : (!cute.layout<"(8,(8)):(1,(512))">) -> !cute.int_tuple<"8">
      %271 = cute.get_scalars(%sz_695) : !cute.int_tuple<"8">
      %c0_i32_696 = arith.constant 0 : i32
      %c1_i32_697 = arith.constant 1 : i32
      scf.for %arg4 = %c0_i32_696 to %271 step %c1_i32_697  : i32 {
        %coord_788 = cute.make_coord(%arg4) : (i32) -> !cute.coord<"(_,?)">
        %334 = cute.get_scalars(%coord_788) <{only_dynamic}> : !cute.coord<"(_,?)">
        %lay_789 = cute.make_layout() : !cute.layout<"(8):(1)">
        %idx_790 = cute.crd2idx(%coord_788, %lay_693) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(8)):(1,(512))">) -> !cute.int_tuple<"?{div=512}">
        %ptr_791 = cute.add_offset(%iter_687, %idx_790) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=512}">) -> !cute.ptr<bf16, smem, align<16>>
        %view_792 = cute.make_view(%ptr_791, %lay_789) : !memref_smem_bf16_5
        %335 = cute.get_scalars(%coord_788) <{only_dynamic}> : !cute.coord<"(_,?)">
        %lay_793 = cute.make_layout() : !cute.layout<"(8):(1)">
        %idx_794 = cute.crd2idx(%coord_788, %lay_694) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(8)):(1,(8))">) -> !cute.int_tuple<"?{div=8}">
        %ptr_795 = cute.add_offset(%iter_688, %idx_794) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
        %view_796 = cute.make_view(%ptr_795, %lay_793) : !memref_rmem_bf16_4
        %iter_797 = cute.get_iter(%view_792) : !memref_smem_bf16_5
        %iter_798 = cute.get_iter(%view_796) : !memref_rmem_bf16_4
        %336 = builtin.unrealized_conversion_cast %iter_797 : !cute.ptr<bf16, smem, align<16>> to !llvm.ptr<3>
        %337 = builtin.unrealized_conversion_cast %iter_798 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
        %338 = llvm.load %336 {alignment = 16 : i64} : !llvm.ptr<3> -> vector<8xbf16>
        llvm.store %338, %337 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
      } {llvm.loop_annotation = #loop_annotation}
      %272 = cute.memref.load_vec %rmem : !memref_rmem_bf16_
      %273 = arith.extf %272 : vector<64xbf16> to vector<64xf32>
      %274 = arith.mulf %273, %273 : vector<64xf32>
      %cst = arith.constant 0.000000e+00 : f32
      %275 = vector.reduction <add>, %274, %cst : vector<64xf32> into f32
      %c-1_i32 = arith.constant -1 : i32
      %c16_i32 = arith.constant 16 : i32
      %c31_i32 = arith.constant 31 : i32
      %276 = nvvm.shfl.sync  bfly %c-1_i32, %275, %c16_i32, %c31_i32 : f32 -> f32
      %277 = arith.addf %276, %275 : f32
      %c8_i32_698 = arith.constant 8 : i32
      %278 = nvvm.shfl.sync  bfly %c-1_i32, %277, %c8_i32_698, %c31_i32 : f32 -> f32
      %279 = arith.addf %277, %278 : f32
      %c4_i32 = arith.constant 4 : i32
      %280 = nvvm.shfl.sync  bfly %c-1_i32, %279, %c4_i32, %c31_i32 : f32 -> f32
      %281 = arith.addf %279, %280 : f32
      %c2_i32_699 = arith.constant 2 : i32
      %282 = nvvm.shfl.sync  bfly %c-1_i32, %281, %c2_i32_699, %c31_i32 : f32 -> f32
      %283 = arith.addf %281, %282 : f32
      %c1_i32_700 = arith.constant 1 : i32
      %284 = nvvm.shfl.sync  bfly %c-1_i32, %283, %c1_i32_700, %c31_i32 : f32 -> f32
      %285 = arith.addf %283, %284 : f32
      %286 = nvvm.read.ptx.sreg.laneid : i32
      %287 = nvvm.read.ptx.sreg.tid.x : i32
      %288 = nvvm.read.ptx.sreg.tid.y : i32
      %289 = nvvm.read.ptx.sreg.tid.z : i32
      %290 = nvvm.read.ptx.sreg.ntid.x : i32
      %291 = nvvm.read.ptx.sreg.ntid.y : i32
      %292 = arith.muli %288, %290 : i32
      %293 = arith.addi %287, %292 : i32
      %294 = arith.muli %289, %290 : i32
      %295 = arith.muli %294, %291 : i32
      %296 = arith.addi %293, %295 : i32
      %c32_i32 = arith.constant 32 : i32
      %297 = arith.floordivsi %296, %c32_i32 : i32
      %lay_701 = cute.get_layout(%view_47) : !memref_smem_f32_
      %298 = cute.get_shape(%lay_701) : (!cute.layout<"(2,2):(1,2)">) -> !cute.shape<"(2,2)">
      %e0_702, %e1_703 = cute.get_leaves(%298) : !cute.shape<"(2,2)">
      %int_tuple_704 = cute.make_int_tuple() : () -> !cute.int_tuple<"2">
      %sz_705 = cute.size(%int_tuple_704) : (!cute.int_tuple<"2">) -> !cute.int_tuple<"2">
      %e0_706 = cute.get_leaves(%sz_705) : !cute.int_tuple<"2">
      %c2_i32_707 = arith.constant 2 : i32
      %299 = arith.floordivsi %297, %c2_i32_707 : i32
      %300 = arith.remsi %297, %c2_i32_707 : i32
      %c0_i32_708 = arith.constant 0 : i32
      %301 = arith.cmpi eq, %286, %c0_i32_708 : i32
      %302 = scf.if %301 -> (!memref_smem_f32_) {
        %iter_788 = cute.get_iter(%view_47) : !memref_smem_f32_
        %coord_789 = cute.make_coord(%299, %300) : (i32, i32) -> !cute.coord<"(?,?)">
        cute.memref.store(%view_47, %coord_789, %285) : (!memref_smem_f32_, !cute.coord<"(?,?)">, f32) -> ()
        scf.yield %view_47 : !memref_smem_f32_
      } else {
        %iter_788 = cute.get_iter(%view_47) : !memref_smem_f32_
        scf.yield %view_47 : !memref_smem_f32_
      }
      %iter_709 = cute.get_iter(%302) : !memref_smem_f32_
      %iter_710 = cute.get_iter(%302) : !memref_smem_f32_
      %iter_711 = cute.get_iter(%302) : !memref_smem_f32_
      nvvm.barrier
      %303 = arith.cmpi slt, %286, %c2_i32_707 : i32
      %cst_712 = arith.constant 0.000000e+00 : f32
      %304 = scf.if %303 -> (f32) {
        %coord_788 = cute.make_coord(%299, %286) : (i32, i32) -> !cute.coord<"(?,?)">
        %334 = cute.memref.load(%302, %coord_788) : (!memref_smem_f32_, !cute.coord<"(?,?)">) -> f32
        scf.yield %334 : f32
      } else {
        scf.yield %cst_712 : f32
      }
      %c-1_i32_713 = arith.constant -1 : i32
      %c16_i32_714 = arith.constant 16 : i32
      %c31_i32_715 = arith.constant 31 : i32
      %305 = nvvm.shfl.sync  bfly %c-1_i32_713, %304, %c16_i32_714, %c31_i32_715 : f32 -> f32
      %306 = arith.addf %304, %305 : f32
      %c8_i32_716 = arith.constant 8 : i32
      %307 = nvvm.shfl.sync  bfly %c-1_i32_713, %306, %c8_i32_716, %c31_i32_715 : f32 -> f32
      %308 = arith.addf %306, %307 : f32
      %c4_i32_717 = arith.constant 4 : i32
      %309 = nvvm.shfl.sync  bfly %c-1_i32_713, %308, %c4_i32_717, %c31_i32_715 : f32 -> f32
      %310 = arith.addf %308, %309 : f32
      %c2_i32_718 = arith.constant 2 : i32
      %311 = nvvm.shfl.sync  bfly %c-1_i32_713, %310, %c2_i32_718, %c31_i32_715 : f32 -> f32
      %312 = arith.addf %310, %311 : f32
      %c1_i32_719 = arith.constant 1 : i32
      %313 = nvvm.shfl.sync  bfly %c-1_i32_713, %312, %c1_i32_719, %c31_i32_715 : f32 -> f32
      %314 = arith.addf %312, %313 : f32
      %cst_720 = arith.constant 4.096000e+03 : f32
      %315 = arith.divf %314, %cst_720 : f32
      %316 = arith.addf %315, %arg3 : f32
      %317 = math.rsqrt %316 fastmath<fast> : f32
      nvvm.barrier
      %lay_721 = cute.get_layout(%view_132) : !memref_smem_bf16_1
      %lay_722 = cute.get_layout(%rmem) : !memref_rmem_bf16_
      %rinv_723 = cute.right_inverse(%lay_722) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.layout<"64:1">
      %lay_724 = cute.make_layout() : !cute.layout<"(8,8):(1,512)">
      %coalesce_725 = cute.coalesce(%lay_724) : (!cute.layout<"(8,8):(1,512)">) -> !cute.layout<"(8,8):(1,512)">
      %318 = cute.get_shape(%coalesce_725) : (!cute.layout<"(8,8):(1,512)">) -> !cute.shape<"(8,8)">
      %e0_726, %e1_727 = cute.get_leaves(%318) : !cute.shape<"(8,8)">
      %319 = cute.get_stride(%coalesce_725) : (!cute.layout<"(8,8):(1,512)">) -> !cute.stride<"(1,512)">
      %e0_728, %e1_729 = cute.get_leaves(%319) : !cute.stride<"(1,512)">
      %320 = cute.get_shape(%coalesce_725) : (!cute.layout<"(8,8):(1,512)">) -> !cute.shape<"(8,8)">
      %e0_730, %e1_731 = cute.get_leaves(%320) : !cute.shape<"(8,8)">
      %321 = cute.get_shape(%coalesce_725) : (!cute.layout<"(8,8):(1,512)">) -> !cute.shape<"(8,8)">
      %e0_732, %e1_733 = cute.get_leaves(%321) : !cute.shape<"(8,8)">
      %lay_734 = cute.make_layout() : !cute.layout<"8:1">
      %lay_735 = cute.make_layout() : !cute.layout<"8:1">
      %sz_736 = cute.size(%lay_735) : (!cute.layout<"8:1">) -> !cute.int_tuple<"8">
      %e0_737 = cute.get_leaves(%sz_736) : !cute.int_tuple<"8">
      %lay_738 = cute.get_layout(%view_132) : !memref_smem_bf16_1
      %lay_739 = cute.get_layout(%rmem) : !memref_rmem_bf16_
      %iter_740 = cute.get_iter(%view_132) : !memref_smem_bf16_1
      %view_741 = cute.make_view(%iter_740) : !memref_smem_bf16_4
      %iter_742 = cute.get_iter(%view_741) : !memref_smem_bf16_4
      %iter_743 = cute.get_iter(%view_741) : !memref_smem_bf16_4
      %iter_744 = cute.get_iter(%rmem) : !memref_rmem_bf16_
      %view_745 = cute.make_view(%iter_744) : !memref_rmem_bf16_3
      %iter_746 = cute.get_iter(%view_745) : !memref_rmem_bf16_3
      %iter_747 = cute.get_iter(%view_745) : !memref_rmem_bf16_3
      %shape_748 = cute.make_shape() : () -> !cute.shape<"8">
      %lay_749 = cute.make_layout() : !cute.layout<"8:1">
      %iter_750 = cute.get_iter(%view_741) : !memref_smem_bf16_4
      %view_751 = cute.make_view(%iter_750) : !memref_smem_bf16_4
      %iter_752 = cute.get_iter(%view_751) : !memref_smem_bf16_4
      %iter_753 = cute.get_iter(%view_751) : !memref_smem_bf16_4
      %shape_754 = cute.make_shape() : () -> !cute.shape<"8">
      %lay_755 = cute.make_layout() : !cute.layout<"8:1">
      %iter_756 = cute.get_iter(%view_745) : !memref_rmem_bf16_3
      %view_757 = cute.make_view(%iter_756) : !memref_rmem_bf16_3
      %iter_758 = cute.get_iter(%view_757) : !memref_rmem_bf16_3
      %iter_759 = cute.get_iter(%view_757) : !memref_rmem_bf16_3
      %atom_760 = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<bf16, 128 b>
      %322 = cute.static : !cute.layout<"1:0">
      %iter_761 = cute.get_iter(%view_751) : !memref_smem_bf16_4
      %iter_762 = cute.get_iter(%view_757) : !memref_rmem_bf16_3
      %lay_763 = cute.get_layout(%view_751) : !memref_smem_bf16_4
      %lay_764 = cute.get_layout(%view_757) : !memref_rmem_bf16_3
      %append_765 = cute.append_to_rank<2> (%lay_763, %322) : !cute.layout<"(8,8):(1,512)">, !cute.layout<"1:0">
      %append_766 = cute.append_to_rank<2> (%lay_764, %322) : !cute.layout<"(8,8):(1,8)">, !cute.layout<"1:0">
      %lay_767 = cute.make_layout() : !cute.layout<"(8,(8)):(1,(512))">
      %lay_768 = cute.make_layout() : !cute.layout<"(8,(8)):(1,(8))">
      %sz_769 = cute.size(%lay_767) <{mode = [1]}> : (!cute.layout<"(8,(8)):(1,(512))">) -> !cute.int_tuple<"8">
      %323 = cute.get_scalars(%sz_769) : !cute.int_tuple<"8">
      %c0_i32_770 = arith.constant 0 : i32
      %c1_i32_771 = arith.constant 1 : i32
      scf.for %arg4 = %c0_i32_770 to %323 step %c1_i32_771  : i32 {
        %coord_788 = cute.make_coord(%arg4) : (i32) -> !cute.coord<"(_,?)">
        %334 = cute.get_scalars(%coord_788) <{only_dynamic}> : !cute.coord<"(_,?)">
        %lay_789 = cute.make_layout() : !cute.layout<"(8):(1)">
        %idx_790 = cute.crd2idx(%coord_788, %lay_767) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(8)):(1,(512))">) -> !cute.int_tuple<"?{div=512}">
        %ptr_791 = cute.add_offset(%iter_761, %idx_790) : (!cute.ptr<bf16, smem, align<16>>, !cute.int_tuple<"?{div=512}">) -> !cute.ptr<bf16, smem, align<16>>
        %view_792 = cute.make_view(%ptr_791, %lay_789) : !memref_smem_bf16_5
        %335 = cute.get_scalars(%coord_788) <{only_dynamic}> : !cute.coord<"(_,?)">
        %lay_793 = cute.make_layout() : !cute.layout<"(8):(1)">
        %idx_794 = cute.crd2idx(%coord_788, %lay_768) : (!cute.coord<"(_,?)">, !cute.layout<"(8,(8)):(1,(8))">) -> !cute.int_tuple<"?{div=8}">
        %ptr_795 = cute.add_offset(%iter_762, %idx_794) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<bf16, rmem, align<16>>
        %view_796 = cute.make_view(%ptr_795, %lay_793) : !memref_rmem_bf16_4
        %iter_797 = cute.get_iter(%view_792) : !memref_smem_bf16_5
        %iter_798 = cute.get_iter(%view_796) : !memref_rmem_bf16_4
        %336 = builtin.unrealized_conversion_cast %iter_797 : !cute.ptr<bf16, smem, align<16>> to !llvm.ptr<3>
        %337 = builtin.unrealized_conversion_cast %iter_798 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
        %338 = llvm.load %336 {alignment = 16 : i64} : !llvm.ptr<3> -> vector<8xbf16>
        llvm.store %338, %337 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr
      } {llvm.loop_annotation = #loop_annotation}
      %324 = cute.memref.load_vec %rmem : !memref_rmem_bf16_
      %325 = arith.extf %324 : vector<64xbf16> to vector<64xf32>
      %326 = vector.broadcast %317 : f32 to vector<64xf32>
      %327 = arith.mulf %325, %326 : vector<64xf32>
      %lay_772 = cute.get_layout(%view_182) : !memref_rmem_bf16_
      %328 = cute.get_shape(%lay_772) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %e0_773, %e1_774, %e2_775, %e3_776 = cute.get_leaves(%328) : !cute.shape<"((8,8),1,1)">
      %329 = cute.memref.load_vec %view_182 : !memref_rmem_bf16_
      %330 = arith.extf %329 : vector<64xbf16> to vector<64xf32>
      %331 = arith.mulf %327, %330 : vector<64xf32>
      %332 = arith.truncf %331 : vector<64xf32> to vector<64xbf16>
      %lay_777 = cute.get_layout(%rmem_163) : !memref_rmem_bf16_
      %333 = cute.get_shape(%lay_777) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
      %e0_778, %e1_779, %e2_780, %e3_781 = cute.get_leaves(%333) : !cute.shape<"((8,8),1,1)">
      %int_tuple_782 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,8),1,1)">
      %sz_783 = cute.size(%int_tuple_782) : (!cute.int_tuple<"((8,8),1,1)">) -> !cute.int_tuple<"64">
      %e0_784 = cute.get_leaves(%sz_783) : !cute.int_tuple<"64">
      %int_tuple_785 = cute.make_int_tuple() : () -> !cute.int_tuple<"((8,8),1,1)">
      %sz_786 = cute.size(%int_tuple_785) : (!cute.int_tuple<"((8,8),1,1)">) -> !cute.int_tuple<"64">
      %e0_787 = cute.get_leaves(%sz_786) : !cute.int_tuple<"64">
      cute.memref.store_vec %332, %rmem_163 : !memref_rmem_bf16_
      scf.if %159 {
        %lay_788 = cute.get_layout(%rmem_163) : !memref_rmem_bf16_
        %334 = cute.get_shape(%lay_788) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %e0_789, %e1_790, %e2_791, %e3_792 = cute.get_leaves(%334) : !cute.shape<"((8,8),1,1)">
        %lay_793 = cute.get_layout(%view_143) : !memref_gmem_bf16_5
        %335 = cute.get_shape(%lay_793) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %e0_794, %e1_795, %e2_796, %e3_797 = cute.get_leaves(%335) : !cute.shape<"((8,8),1,1)">
        %lay_798 = cute.get_layout(%rmem_163) : !memref_rmem_bf16_
        %shape_799 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_800 = cute.make_layout() : !cute.layout<"1:0">
        %append_801 = cute.append_to_rank<2> (%lay_798, %lay_800) : !cute.layout<"((8,8),1,1):((1,8),0,0)">, !cute.layout<"1:0">
        %view_802 = cute.make_view(%iter_165, %append_801) : !memref_rmem_bf16_
        %iter_803 = cute.get_iter(%view_802) : !memref_rmem_bf16_
        %lay_804 = cute.get_layout(%view_802) : !memref_rmem_bf16_
        %336 = cute.get_shape(%lay_804) : (!cute.layout<"((8,8),1,1):((1,8),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %e0_805, %e1_806, %e2_807, %e3_808 = cute.get_leaves(%336) : !cute.shape<"((8,8),1,1)">
        %iter_809 = cute.get_iter(%view_802) : !memref_rmem_bf16_
        %view_810 = cute.make_view(%iter_809) : !memref_rmem_bf16_1
        %iter_811 = cute.get_iter(%view_810) : !memref_rmem_bf16_1
        %iter_812 = cute.get_iter(%view_810) : !memref_rmem_bf16_1
        %lay_813 = cute.get_layout(%view_143) : !memref_gmem_bf16_5
        %shape_814 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_815 = cute.make_layout() : !cute.layout<"1:0">
        %append_816 = cute.append_to_rank<2> (%lay_813, %lay_815) : !cute.layout<"((8,8),1,1):((1,512),0,0)">, !cute.layout<"1:0">
        %view_817 = cute.make_view(%iter_144, %append_816) : !memref_gmem_bf16_5
        %iter_818 = cute.get_iter(%view_817) : !memref_gmem_bf16_5
        %lay_819 = cute.get_layout(%view_817) : !memref_gmem_bf16_5
        %337 = cute.get_shape(%lay_819) : (!cute.layout<"((8,8),1,1):((1,512),0,0)">) -> !cute.shape<"((8,8),1,1)">
        %e0_820, %e1_821, %e2_822, %e3_823 = cute.get_leaves(%337) : !cute.shape<"((8,8),1,1)">
        %iter_824 = cute.get_iter(%view_817) : !memref_gmem_bf16_5
        %view_825 = cute.make_view(%iter_824) : !memref_gmem_bf16_6
        %iter_826 = cute.get_iter(%view_825) : !memref_gmem_bf16_6
        %iter_827 = cute.get_iter(%view_825) : !memref_gmem_bf16_6
        %lay_828 = cute.get_layout(%rmem_198) : !memref_rmem_i8_
        %shape_829 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_830 = cute.make_layout() : !cute.layout<"1:0">
        %append_831 = cute.append_to_rank<2> (%lay_828, %lay_830) : !cute.layout<"(8,1,1):(1,0,1)">, !cute.layout<"1:0">
        %view_832 = cute.make_view(%iter_200, %append_831) : !memref_rmem_i8_
        %iter_833 = cute.get_iter(%view_832) : !memref_rmem_i8_
        %lay_834 = cute.get_layout(%view_832) : !memref_rmem_i8_
        %338 = cute.get_shape(%lay_834) : (!cute.layout<"(8,1,1):(1,0,1)">) -> !cute.shape<"(8,1,1)">
        %e0_835, %e1_836, %e2_837 = cute.get_leaves(%338) : !cute.shape<"(8,1,1)">
        %iter_838 = cute.get_iter(%view_832) : !memref_rmem_i8_
        %view_839 = cute.make_view(%iter_838) : !memref_rmem_i8_1
        %iter_840 = cute.get_iter(%view_839) : !memref_rmem_i8_1
        %iter_841 = cute.get_iter(%view_839) : !memref_rmem_i8_1
        %lay_842 = cute.get_layout(%view_810) : !memref_rmem_bf16_1
        %339 = cute.get_shape(%lay_842) : (!cute.layout<"((8,8),(1,1)):((1,8),(0,0))">) -> !cute.shape<"((8,8),(1,1))">
        %e0_843, %e1_844, %e2_845, %e3_846 = cute.get_leaves(%339) : !cute.shape<"((8,8),(1,1))">
        %lay_847 = cute.get_layout(%view_825) : !memref_gmem_bf16_6
        %340 = cute.get_shape(%lay_847) : (!cute.layout<"((8,8),(1,1)):((1,512),(0,0))">) -> !cute.shape<"((8,8),(1,1))">
        %e0_848, %e1_849, %e2_850, %e3_851 = cute.get_leaves(%340) : !cute.shape<"((8,8),(1,1))">
        %lay_852 = cute.get_layout(%view_810) : !memref_rmem_bf16_1
        %sz_853 = cute.size(%lay_852) <{mode = [1]}> : (!cute.layout<"((8,8),(1,1)):((1,8),(0,0))">) -> !cute.int_tuple<"1">
        %e0_854 = cute.get_leaves(%sz_853) : !cute.int_tuple<"1">
        %lay_855 = cute.get_layout(%view_825) : !memref_gmem_bf16_6
        %sz_856 = cute.size(%lay_855) <{mode = [1]}> : (!cute.layout<"((8,8),(1,1)):((1,512),(0,0))">) -> !cute.int_tuple<"1">
        %e0_857 = cute.get_leaves(%sz_856) : !cute.int_tuple<"1">
        %341 = cute.static : !cute.layout<"1:0">
        %iter_858 = cute.get_iter(%view_810) : !memref_rmem_bf16_1
        %iter_859 = cute.get_iter(%view_825) : !memref_gmem_bf16_6
        %lay_860 = cute.get_layout(%view_810) : !memref_rmem_bf16_1
        %lay_861 = cute.get_layout(%view_825) : !memref_gmem_bf16_6
        %append_862 = cute.append_to_rank<2> (%lay_860, %341) : !cute.layout<"((8,8),(1,1)):((1,8),(0,0))">, !cute.layout<"1:0">
        %append_863 = cute.append_to_rank<2> (%lay_861, %341) : !cute.layout<"((8,8),(1,1)):((1,512),(0,0))">, !cute.layout<"1:0">
        %lay_864 = cute.make_layout() : !cute.layout<"((8,8),((1,1))):((1,8),((0,0)))">
        %lay_865 = cute.make_layout() : !cute.layout<"((8,8),((1,1))):((1,512),((0,0)))">
        %iter_866 = cute.get_iter(%view_839) : !memref_rmem_i8_1
        %lay_867 = cute.get_layout(%view_839) : !memref_rmem_i8_1
        %append_868 = cute.append_to_rank<2> (%lay_867, %341) : !cute.layout<"(8,(1,1)):(1,(0,1))">, !cute.layout<"1:0">
        %lay_869 = cute.make_layout() : !cute.layout<"(8,((1,1))):(1,((0,1)))">
        %sz_870 = cute.size(%lay_864) <{mode = [1]}> : (!cute.layout<"((8,8),((1,1))):((1,8),((0,0)))">) -> !cute.int_tuple<"1">
        %342 = cute.get_scalars(%sz_870) : !cute.int_tuple<"1">
        %c0_i32_871 = arith.constant 0 : i32
        %c1_i32_872 = arith.constant 1 : i32
        scf.for %arg4 = %c0_i32_871 to %342 step %c1_i32_872  : i32 {
          %coord_873 = cute.make_coord(%arg4) : (i32) -> !cute.coord<"(_,?)">
          %343 = cute.get_scalars(%coord_873) <{only_dynamic}> : !cute.coord<"(_,?)">
          %lay_874 = cute.make_layout() : !cute.layout<"((8,8)):((1,8))">
          %idx_875 = cute.crd2idx(%coord_873, %lay_864) : (!cute.coord<"(_,?)">, !cute.layout<"((8,8),((1,1))):((1,8),((0,0)))">) -> !cute.int_tuple<"0">
          %ptr_876 = cute.add_offset(%iter_858, %idx_875) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, rmem, align<32>>
          %view_877 = cute.make_view(%ptr_876, %lay_874) : !memref_rmem_bf16_2
          %344 = cute.get_scalars(%coord_873) <{only_dynamic}> : !cute.coord<"(_,?)">
          %lay_878 = cute.make_layout() : !cute.layout<"((8,8)):((1,512))">
          %idx_879 = cute.crd2idx(%coord_873, %lay_865) : (!cute.coord<"(_,?)">, !cute.layout<"((8,8),((1,1))):((1,512),((0,0)))">) -> !cute.int_tuple<"0">
          %ptr_880 = cute.add_offset(%iter_859, %idx_879) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"0">) -> !cute.ptr<bf16, gmem, align<16>>
          %view_881 = cute.make_view(%ptr_880, %lay_878) : !memref_gmem_bf16_7
          %345 = cute.get_scalars(%coord_873) <{only_dynamic}> : !cute.coord<"(_,?)">
          %lay_882 = cute.make_layout() : !cute.layout<"(8):(1)">
          %idx_883 = cute.crd2idx(%coord_873, %lay_869) : (!cute.coord<"(_,?)">, !cute.layout<"(8,((1,1))):(1,((0,1)))">) -> !cute.int_tuple<"?">
          %ptr_884 = cute.add_offset(%iter_866, %idx_883) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"?">) -> !cute.ptr<i8, rmem>
          %view_885 = cute.make_view(%ptr_884, %lay_882) : !memref_rmem_i8_2
          %iter_886 = cute.get_iter(%view_877) : !memref_rmem_bf16_2
          %iter_887 = cute.get_iter(%view_881) : !memref_gmem_bf16_7
          %iter_888 = cute.get_iter(%view_885) : !memref_rmem_i8_2
          %346 = builtin.unrealized_conversion_cast %iter_888 : !cute.ptr<i8, rmem> to !llvm.ptr
          %347 = llvm.load %346 : !llvm.ptr -> i8
          %348 = llvm.mlir.constant(0 : i8) : i8
          %349 = llvm.icmp "ne" %347, %348 : i8
          scf.if %349 {
            %378 = builtin.unrealized_conversion_cast %iter_886 : !cute.ptr<bf16, rmem, align<32>> to !llvm.ptr
            %379 = builtin.unrealized_conversion_cast %iter_887 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
            %380 = llvm.load %378 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
            llvm.store %380, %379 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
          }
          %int_tuple_889 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
          %ptr_890 = cute.add_offset(%iter_888, %int_tuple_889) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
          %350 = builtin.unrealized_conversion_cast %ptr_890 : !cute.ptr<i8, rmem> to !llvm.ptr
          %351 = llvm.load %350 : !llvm.ptr -> i8
          %352 = llvm.mlir.constant(0 : i8) : i8
          %353 = llvm.icmp "ne" %351, %352 : i8
          scf.if %353 {
            %int_tuple_903 = cute.make_int_tuple() : () -> !cute.int_tuple<"8">
            %ptr_904 = cute.add_offset(%iter_886, %int_tuple_903) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<bf16, rmem, align<16>>
            %int_tuple_905 = cute.make_int_tuple() : () -> !cute.int_tuple<"512">
            %ptr_906 = cute.add_offset(%iter_887, %int_tuple_905) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"512">) -> !cute.ptr<bf16, gmem, align<16>>
            %378 = builtin.unrealized_conversion_cast %ptr_904 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
            %379 = builtin.unrealized_conversion_cast %ptr_906 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
            %380 = llvm.load %378 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
            llvm.store %380, %379 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
          }
          %int_tuple_891 = cute.make_int_tuple() : () -> !cute.int_tuple<"2">
          %ptr_892 = cute.add_offset(%iter_888, %int_tuple_891) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem>
          %354 = builtin.unrealized_conversion_cast %ptr_892 : !cute.ptr<i8, rmem> to !llvm.ptr
          %355 = llvm.load %354 : !llvm.ptr -> i8
          %356 = llvm.mlir.constant(0 : i8) : i8
          %357 = llvm.icmp "ne" %355, %356 : i8
          scf.if %357 {
            %int_tuple_903 = cute.make_int_tuple() : () -> !cute.int_tuple<"16">
            %ptr_904 = cute.add_offset(%iter_886, %int_tuple_903) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"16">) -> !cute.ptr<bf16, rmem, align<32>>
            %int_tuple_905 = cute.make_int_tuple() : () -> !cute.int_tuple<"1024">
            %ptr_906 = cute.add_offset(%iter_887, %int_tuple_905) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"1024">) -> !cute.ptr<bf16, gmem, align<16>>
            %378 = builtin.unrealized_conversion_cast %ptr_904 : !cute.ptr<bf16, rmem, align<32>> to !llvm.ptr
            %379 = builtin.unrealized_conversion_cast %ptr_906 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
            %380 = llvm.load %378 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
            llvm.store %380, %379 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
          }
          %int_tuple_893 = cute.make_int_tuple() : () -> !cute.int_tuple<"3">
          %ptr_894 = cute.add_offset(%iter_888, %int_tuple_893) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
          %358 = builtin.unrealized_conversion_cast %ptr_894 : !cute.ptr<i8, rmem> to !llvm.ptr
          %359 = llvm.load %358 : !llvm.ptr -> i8
          %360 = llvm.mlir.constant(0 : i8) : i8
          %361 = llvm.icmp "ne" %359, %360 : i8
          scf.if %361 {
            %int_tuple_903 = cute.make_int_tuple() : () -> !cute.int_tuple<"24">
            %ptr_904 = cute.add_offset(%iter_886, %int_tuple_903) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"24">) -> !cute.ptr<bf16, rmem, align<16>>
            %int_tuple_905 = cute.make_int_tuple() : () -> !cute.int_tuple<"1536">
            %ptr_906 = cute.add_offset(%iter_887, %int_tuple_905) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"1536">) -> !cute.ptr<bf16, gmem, align<16>>
            %378 = builtin.unrealized_conversion_cast %ptr_904 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
            %379 = builtin.unrealized_conversion_cast %ptr_906 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
            %380 = llvm.load %378 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
            llvm.store %380, %379 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
          }
          %int_tuple_895 = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
          %ptr_896 = cute.add_offset(%iter_888, %int_tuple_895) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem>
          %362 = builtin.unrealized_conversion_cast %ptr_896 : !cute.ptr<i8, rmem> to !llvm.ptr
          %363 = llvm.load %362 : !llvm.ptr -> i8
          %364 = llvm.mlir.constant(0 : i8) : i8
          %365 = llvm.icmp "ne" %363, %364 : i8
          scf.if %365 {
            %int_tuple_903 = cute.make_int_tuple() : () -> !cute.int_tuple<"32">
            %ptr_904 = cute.add_offset(%iter_886, %int_tuple_903) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"32">) -> !cute.ptr<bf16, rmem, align<32>>
            %int_tuple_905 = cute.make_int_tuple() : () -> !cute.int_tuple<"2048">
            %ptr_906 = cute.add_offset(%iter_887, %int_tuple_905) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"2048">) -> !cute.ptr<bf16, gmem, align<16>>
            %378 = builtin.unrealized_conversion_cast %ptr_904 : !cute.ptr<bf16, rmem, align<32>> to !llvm.ptr
            %379 = builtin.unrealized_conversion_cast %ptr_906 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
            %380 = llvm.load %378 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
            llvm.store %380, %379 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
          }
          %int_tuple_897 = cute.make_int_tuple() : () -> !cute.int_tuple<"5">
          %ptr_898 = cute.add_offset(%iter_888, %int_tuple_897) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
          %366 = builtin.unrealized_conversion_cast %ptr_898 : !cute.ptr<i8, rmem> to !llvm.ptr
          %367 = llvm.load %366 : !llvm.ptr -> i8
          %368 = llvm.mlir.constant(0 : i8) : i8
          %369 = llvm.icmp "ne" %367, %368 : i8
          scf.if %369 {
            %int_tuple_903 = cute.make_int_tuple() : () -> !cute.int_tuple<"40">
            %ptr_904 = cute.add_offset(%iter_886, %int_tuple_903) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"40">) -> !cute.ptr<bf16, rmem, align<16>>
            %int_tuple_905 = cute.make_int_tuple() : () -> !cute.int_tuple<"2560">
            %ptr_906 = cute.add_offset(%iter_887, %int_tuple_905) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"2560">) -> !cute.ptr<bf16, gmem, align<16>>
            %378 = builtin.unrealized_conversion_cast %ptr_904 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
            %379 = builtin.unrealized_conversion_cast %ptr_906 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
            %380 = llvm.load %378 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
            llvm.store %380, %379 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
          }
          %int_tuple_899 = cute.make_int_tuple() : () -> !cute.int_tuple<"6">
          %ptr_900 = cute.add_offset(%iter_888, %int_tuple_899) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem>
          %370 = builtin.unrealized_conversion_cast %ptr_900 : !cute.ptr<i8, rmem> to !llvm.ptr
          %371 = llvm.load %370 : !llvm.ptr -> i8
          %372 = llvm.mlir.constant(0 : i8) : i8
          %373 = llvm.icmp "ne" %371, %372 : i8
          scf.if %373 {
            %int_tuple_903 = cute.make_int_tuple() : () -> !cute.int_tuple<"48">
            %ptr_904 = cute.add_offset(%iter_886, %int_tuple_903) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"48">) -> !cute.ptr<bf16, rmem, align<32>>
            %int_tuple_905 = cute.make_int_tuple() : () -> !cute.int_tuple<"3072">
            %ptr_906 = cute.add_offset(%iter_887, %int_tuple_905) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"3072">) -> !cute.ptr<bf16, gmem, align<16>>
            %378 = builtin.unrealized_conversion_cast %ptr_904 : !cute.ptr<bf16, rmem, align<32>> to !llvm.ptr
            %379 = builtin.unrealized_conversion_cast %ptr_906 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
            %380 = llvm.load %378 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
            llvm.store %380, %379 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
          }
          %int_tuple_901 = cute.make_int_tuple() : () -> !cute.int_tuple<"7">
          %ptr_902 = cute.add_offset(%iter_888, %int_tuple_901) : (!cute.ptr<i8, rmem>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
          %374 = builtin.unrealized_conversion_cast %ptr_902 : !cute.ptr<i8, rmem> to !llvm.ptr
          %375 = llvm.load %374 : !llvm.ptr -> i8
          %376 = llvm.mlir.constant(0 : i8) : i8
          %377 = llvm.icmp "ne" %375, %376 : i8
          scf.if %377 {
            %int_tuple_903 = cute.make_int_tuple() : () -> !cute.int_tuple<"56">
            %ptr_904 = cute.add_offset(%iter_886, %int_tuple_903) : (!cute.ptr<bf16, rmem, align<32>>, !cute.int_tuple<"56">) -> !cute.ptr<bf16, rmem, align<16>>
            %int_tuple_905 = cute.make_int_tuple() : () -> !cute.int_tuple<"3584">
            %ptr_906 = cute.add_offset(%iter_887, %int_tuple_905) : (!cute.ptr<bf16, gmem, align<16>>, !cute.int_tuple<"3584">) -> !cute.ptr<bf16, gmem, align<16>>
            %378 = builtin.unrealized_conversion_cast %ptr_904 : !cute.ptr<bf16, rmem, align<16>> to !llvm.ptr
            %379 = builtin.unrealized_conversion_cast %ptr_906 : !cute.ptr<bf16, gmem, align<16>> to !llvm.ptr<1>
            %380 = llvm.load %378 {alignment = 16 : i64} : !llvm.ptr -> vector<8xbf16>
            llvm.store %380, %379 {alignment = 16 : i64} : vector<8xbf16>, !llvm.ptr<1>
          }
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
