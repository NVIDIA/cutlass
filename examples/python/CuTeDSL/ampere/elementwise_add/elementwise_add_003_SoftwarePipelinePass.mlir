!copy_simt = !cute.tiled_copy<!cute_nvgpu.atom.universal_copy<f32>, layout_copy_tv = <"((32,4),(4,4)):((64,4),(16,1))">, tiler_mn = <"[16:1;128:1]">>
!memref_gmem_f32_ = !cute.memref<f32, gmem, "((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
!memref_gmem_f32_1 = !cute.memref<f32, gmem, "(16,128):(?{i64},1)">
!memref_gmem_f32_2 = !cute.memref<f32, gmem, "((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
!memref_gmem_f32_3 = !cute.memref<f32, gmem, "((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
!memref_gmem_f32_4 = !cute.memref<f32, gmem, "(?,?):(?{i64},1)">
!memref_rmem_f32_ = !cute.memref<f32, rmem, align<32>, "((1,(4,4)),1,1):((0,(1,4)),0,0)">
!memref_rmem_f32_1 = !cute.memref<f32, rmem, align<32>, "((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
!memref_rmem_i8_ = !cute.memref<i8, rmem, align<32>, "((1,(4,4)),1,1):((0,(1,4)),0,0)">
!memref_rmem_i8_1 = !cute.memref<i8, rmem, align<32>, "((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
module attributes {gpu.container_module} {
  gpu.module @kernels {
    cuda.kernel @kernel_cutlass_elementwise_add_kernel_tensorptrf32gmemo161281i64div16128_tensorptrf32gmemo161281i64div16128_tensorptrf32gmemo161281i64div16128_tensor00o1612810111601281___0(%arg0: !memref_gmem_f32_, %arg1: !memref_gmem_f32_, %arg2: !memref_gmem_f32_, %arg3: !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">, %arg4: i32, %arg5: i32) attributes {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} {
      %0 = cute.static : !cute.layout<"(4,32):(32,1)">
      %1 = cute.static : !cute.layout<"(4,4):(4,1)">
      %iter = cute.get_iter(%arg0) : !memref_gmem_f32_
      %iter_0 = cute.get_iter(%arg1) : !memref_gmem_f32_
      %iter_1 = cute.get_iter(%arg2) : !memref_gmem_f32_
      %iter_2 = cute.get_iter(%arg3) : !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
      %e0, %e1 = cute.get_leaves(%iter_2) : !cute.int_tuple<"(0,0)">
      %iter_3 = cute.get_iter(%arg0) : !memref_gmem_f32_
      %iter_4 = cute.get_iter(%arg1) : !memref_gmem_f32_
      %iter_5 = cute.get_iter(%arg2) : !memref_gmem_f32_
      %iter_6 = cute.get_iter(%arg3) : !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
      %e0_7, %e1_8 = cute.get_leaves(%iter_6) : !cute.int_tuple<"(0,0)">
      %lay = cute.get_layout(%arg0) : !memref_gmem_f32_
      %2 = cute.get_shape(%lay) : (!cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.shape<"((16,128),(?,?))">
      %e0_9, %e1_10, %e2, %e3 = cute.get_leaves(%2) : !cute.shape<"((16,128),(?,?))">
      %itup = cute.to_int_tuple(%e2) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %3 = cute.get_scalars(%itup) : !cute.int_tuple<"?">
      %itup_11 = cute.to_int_tuple(%e3) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %4 = cute.get_scalars(%itup_11) : !cute.int_tuple<"?">
      %5 = cute.get_stride(%lay) : (!cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.stride<"((?{i64},1),(?{i64 div=16},128))">
      %e0_12, %e1_13, %e2_14, %e3_15 = cute.get_leaves(%5) : !cute.stride<"((?{i64},1),(?{i64 div=16},128))">
      %itup_16 = cute.to_int_tuple(%e0_12) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
      %6 = cute.get_scalars(%itup_16) : !cute.int_tuple<"?{i64}">
      %itup_17 = cute.to_int_tuple(%e2_14) : !cute.stride<"?{i64 div=16}"> to !cute.int_tuple<"?{i64 div=16}">
      %7 = cute.get_scalars(%itup_17) : !cute.int_tuple<"?{i64 div=16}">
      %lay_18 = cute.get_layout(%arg1) : !memref_gmem_f32_
      %8 = cute.get_shape(%lay_18) : (!cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.shape<"((16,128),(?,?))">
      %e0_19, %e1_20, %e2_21, %e3_22 = cute.get_leaves(%8) : !cute.shape<"((16,128),(?,?))">
      %itup_23 = cute.to_int_tuple(%e2_21) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %9 = cute.get_scalars(%itup_23) : !cute.int_tuple<"?">
      %itup_24 = cute.to_int_tuple(%e3_22) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %10 = cute.get_scalars(%itup_24) : !cute.int_tuple<"?">
      %11 = cute.get_stride(%lay_18) : (!cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.stride<"((?{i64},1),(?{i64 div=16},128))">
      %e0_25, %e1_26, %e2_27, %e3_28 = cute.get_leaves(%11) : !cute.stride<"((?{i64},1),(?{i64 div=16},128))">
      %itup_29 = cute.to_int_tuple(%e0_25) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
      %12 = cute.get_scalars(%itup_29) : !cute.int_tuple<"?{i64}">
      %itup_30 = cute.to_int_tuple(%e2_27) : !cute.stride<"?{i64 div=16}"> to !cute.int_tuple<"?{i64 div=16}">
      %13 = cute.get_scalars(%itup_30) : !cute.int_tuple<"?{i64 div=16}">
      %lay_31 = cute.get_layout(%arg2) : !memref_gmem_f32_
      %14 = cute.get_shape(%lay_31) : (!cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.shape<"((16,128),(?,?))">
      %e0_32, %e1_33, %e2_34, %e3_35 = cute.get_leaves(%14) : !cute.shape<"((16,128),(?,?))">
      %itup_36 = cute.to_int_tuple(%e2_34) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %15 = cute.get_scalars(%itup_36) : !cute.int_tuple<"?">
      %itup_37 = cute.to_int_tuple(%e3_35) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %16 = cute.get_scalars(%itup_37) : !cute.int_tuple<"?">
      %17 = cute.get_stride(%lay_31) : (!cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.stride<"((?{i64},1),(?{i64 div=16},128))">
      %e0_38, %e1_39, %e2_40, %e3_41 = cute.get_leaves(%17) : !cute.stride<"((?{i64},1),(?{i64 div=16},128))">
      %itup_42 = cute.to_int_tuple(%e0_38) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
      %18 = cute.get_scalars(%itup_42) : !cute.int_tuple<"?{i64}">
      %itup_43 = cute.to_int_tuple(%e2_40) : !cute.stride<"?{i64 div=16}"> to !cute.int_tuple<"?{i64 div=16}">
      %19 = cute.get_scalars(%itup_43) : !cute.int_tuple<"?{i64 div=16}">
      %lay_44 = cute.get_layout(%arg3) : !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
      %20 = cute.get_shape(%lay_44) : (!cute.layout<"((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">) -> !cute.shape<"((16,128),(?,?))">
      %e0_45, %e1_46, %e2_47, %e3_48 = cute.get_leaves(%20) : !cute.shape<"((16,128),(?,?))">
      %itup_49 = cute.to_int_tuple(%e2_47) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %21 = cute.get_scalars(%itup_49) : !cute.int_tuple<"?">
      %itup_50 = cute.to_int_tuple(%e3_48) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %22 = cute.get_scalars(%itup_50) : !cute.int_tuple<"?">
      %23 = cute.get_stride(%lay_44) : (!cute.layout<"((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">) -> !cute.stride<"((1@0,1@1),(16@0,128@1))">
      %e0_51, %e1_52, %e2_53, %e3_54 = cute.get_leaves(%23) : !cute.stride<"((1@0,1@1),(16@0,128@1))">
      %24 = cute.get_shape(%0) : (!cute.layout<"(4,32):(32,1)">) -> !cute.shape<"(4,32)">
      %e0_55, %e1_56 = cute.get_leaves(%24) : !cute.shape<"(4,32)">
      %25 = cute.get_stride(%0) : (!cute.layout<"(4,32):(32,1)">) -> !cute.stride<"(32,1)">
      %e0_57, %e1_58 = cute.get_leaves(%25) : !cute.stride<"(32,1)">
      %26 = cute.get_shape(%1) : (!cute.layout<"(4,4):(4,1)">) -> !cute.shape<"(4,4)">
      %e0_59, %e1_60 = cute.get_leaves(%26) : !cute.shape<"(4,4)">
      %27 = cute.get_stride(%1) : (!cute.layout<"(4,4):(4,1)">) -> !cute.stride<"(4,1)">
      %e0_61, %e1_62 = cute.get_leaves(%27) : !cute.stride<"(4,1)">
      %28 = nvvm.read.ptx.sreg.tid.x : i32
      %29 = nvvm.read.ptx.sreg.tid.y : i32
      %30 = nvvm.read.ptx.sreg.tid.z : i32
      %31 = nvvm.read.ptx.sreg.ctaid.x : i32
      %32 = nvvm.read.ptx.sreg.ctaid.y : i32
      %33 = nvvm.read.ptx.sreg.ctaid.z : i32
      %coord = cute.make_coord(%31) : (i32) -> !cute.coord<"((_,_),?)">
      %slice = cute.slice(%arg0, %coord) : !memref_gmem_f32_, !cute.coord<"((_,_),?)">
      %iter_63 = cute.get_iter(%slice) : !memref_gmem_f32_1
      %iter_64 = cute.get_iter(%slice) : !memref_gmem_f32_1
      %coord_65 = cute.make_coord(%31) : (i32) -> !cute.coord<"((_,_),?)">
      %slice_66 = cute.slice(%arg1, %coord_65) : !memref_gmem_f32_, !cute.coord<"((_,_),?)">
      %iter_67 = cute.get_iter(%slice_66) : !memref_gmem_f32_1
      %iter_68 = cute.get_iter(%slice_66) : !memref_gmem_f32_1
      %coord_69 = cute.make_coord(%31) : (i32) -> !cute.coord<"((_,_),?)">
      %slice_70 = cute.slice(%arg2, %coord_69) : !memref_gmem_f32_, !cute.coord<"((_,_),?)">
      %iter_71 = cute.get_iter(%slice_70) : !memref_gmem_f32_1
      %iter_72 = cute.get_iter(%slice_70) : !memref_gmem_f32_1
      %coord_73 = cute.make_coord(%31) : (i32) -> !cute.coord<"((_,_),?)">
      %slice_74 = cute.slice(%arg3, %coord_73) : !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">, !cute.coord<"((_,_),?)">
      %iter_75 = cute.get_iter(%slice_74) : !cute.coord_tensor<"(?{div=16},?{div=128})", "(16,128):(1@0,1@1)">
      %e0_76, %e1_77 = cute.get_leaves(%iter_75) : !cute.int_tuple<"(?{div=16},?{div=128})">
      %34 = cute.get_scalars(%e0_76) : !cute.int_tuple<"?{div=16}">
      %35 = cute.get_scalars(%e1_77) : !cute.int_tuple<"?{div=128}">
      %iter_78 = cute.get_iter(%slice_74) : !cute.coord_tensor<"(?{div=16},?{div=128})", "(16,128):(1@0,1@1)">
      %e0_79, %e1_80 = cute.get_leaves(%iter_78) : !cute.int_tuple<"(?{div=16},?{div=128})">
      %36 = cute.get_scalars(%e0_79) : !cute.int_tuple<"?{div=16}">
      %37 = cute.get_scalars(%e1_80) : !cute.int_tuple<"?{div=128}">
      %atom = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<f32>
      %atom_81 = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<f32>
      %prod = cute.raked_product(%0, %1) : (!cute.layout<"(4,32):(32,1)">, !cute.layout<"(4,4):(4,1)">) -> !cute.layout<"((4,4),(4,32)):((512,32),(128,1))">
      %sz = cute.size(%0) : (!cute.layout<"(4,32):(32,1)">) -> !cute.int_tuple<"128">
      %e0_82 = cute.get_leaves(%sz) : !cute.int_tuple<"128">
      %sz_83 = cute.size(%1) : (!cute.layout<"(4,4):(4,1)">) -> !cute.int_tuple<"16">
      %e0_84 = cute.get_leaves(%sz_83) : !cute.int_tuple<"16">
      %shape = cute.make_shape() : () -> !cute.shape<"(128,16)">
      %lay_85 = cute.make_layout(%shape) : !cute.layout<"(128,16):(1,128)">
      %rinv = cute.right_inverse(%prod) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.layout<"(32,16,4):(64,4,1)">
      %38 = cute.composition(%rinv, %lay_85) : (!cute.layout<"(32,16,4):(64,4,1)">, !cute.layout<"(128,16):(1,128)">) -> !cute.layout<"((32,4),(4,4)):((64,4),(16,1))">
      %39 = cute.get_shape(%prod) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.shape<"((4,4),(4,32))">
      %e0_86, %e1_87, %e2_88, %e3_89 = cute.get_leaves(%39) : !cute.shape<"((4,4),(4,32))">
      %int_tuple = cute.make_int_tuple() : () -> !cute.int_tuple<"((4,4),(4,32))">
      %res = cute.tuple.product_each(%int_tuple) : (!cute.int_tuple<"((4,4),(4,32))">) -> !cute.int_tuple<"(16,128)">
      %e0_90, %e1_91 = cute.get_leaves(%res) : !cute.int_tuple<"(16,128)">
      %int_tuple_92 = cute.make_int_tuple() : () -> !cute.int_tuple<"(16,128)">
      %res_93 = cute.tuple.product_each(%int_tuple_92) : (!cute.int_tuple<"(16,128)">) -> !cute.int_tuple<"(16,128)">
      %e0_94, %e1_95 = cute.get_leaves(%res_93) : !cute.int_tuple<"(16,128)">
      %tile = cute.make_tile() : () -> !cute.tile<"[16:1;128:1]">
      %40 = cute.make_tiled_copy(%atom) : !copy_simt
      %prod_96 = cute.raked_product(%0, %1) : (!cute.layout<"(4,32):(32,1)">, !cute.layout<"(4,4):(4,1)">) -> !cute.layout<"((4,4),(4,32)):((512,32),(128,1))">
      %sz_97 = cute.size(%0) : (!cute.layout<"(4,32):(32,1)">) -> !cute.int_tuple<"128">
      %e0_98 = cute.get_leaves(%sz_97) : !cute.int_tuple<"128">
      %sz_99 = cute.size(%1) : (!cute.layout<"(4,4):(4,1)">) -> !cute.int_tuple<"16">
      %e0_100 = cute.get_leaves(%sz_99) : !cute.int_tuple<"16">
      %shape_101 = cute.make_shape() : () -> !cute.shape<"(128,16)">
      %lay_102 = cute.make_layout(%shape_101) : !cute.layout<"(128,16):(1,128)">
      %rinv_103 = cute.right_inverse(%prod_96) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.layout<"(32,16,4):(64,4,1)">
      %41 = cute.composition(%rinv_103, %lay_102) : (!cute.layout<"(32,16,4):(64,4,1)">, !cute.layout<"(128,16):(1,128)">) -> !cute.layout<"((32,4),(4,4)):((64,4),(16,1))">
      %42 = cute.get_shape(%prod_96) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.shape<"((4,4),(4,32))">
      %e0_104, %e1_105, %e2_106, %e3_107 = cute.get_leaves(%42) : !cute.shape<"((4,4),(4,32))">
      %int_tuple_108 = cute.make_int_tuple() : () -> !cute.int_tuple<"((4,4),(4,32))">
      %res_109 = cute.tuple.product_each(%int_tuple_108) : (!cute.int_tuple<"((4,4),(4,32))">) -> !cute.int_tuple<"(16,128)">
      %e0_110, %e1_111 = cute.get_leaves(%res_109) : !cute.int_tuple<"(16,128)">
      %int_tuple_112 = cute.make_int_tuple() : () -> !cute.int_tuple<"(16,128)">
      %res_113 = cute.tuple.product_each(%int_tuple_112) : (!cute.int_tuple<"(16,128)">) -> !cute.int_tuple<"(16,128)">
      %e0_114, %e1_115 = cute.get_leaves(%res_113) : !cute.int_tuple<"(16,128)">
      %tile_116 = cute.make_tile() : () -> !cute.tile<"[16:1;128:1]">
      %43 = cute.make_tiled_copy(%atom) : !copy_simt
      %prod_117 = cute.raked_product(%0, %1) : (!cute.layout<"(4,32):(32,1)">, !cute.layout<"(4,4):(4,1)">) -> !cute.layout<"((4,4),(4,32)):((512,32),(128,1))">
      %sz_118 = cute.size(%0) : (!cute.layout<"(4,32):(32,1)">) -> !cute.int_tuple<"128">
      %e0_119 = cute.get_leaves(%sz_118) : !cute.int_tuple<"128">
      %sz_120 = cute.size(%1) : (!cute.layout<"(4,4):(4,1)">) -> !cute.int_tuple<"16">
      %e0_121 = cute.get_leaves(%sz_120) : !cute.int_tuple<"16">
      %shape_122 = cute.make_shape() : () -> !cute.shape<"(128,16)">
      %lay_123 = cute.make_layout(%shape_122) : !cute.layout<"(128,16):(1,128)">
      %rinv_124 = cute.right_inverse(%prod_117) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.layout<"(32,16,4):(64,4,1)">
      %44 = cute.composition(%rinv_124, %lay_123) : (!cute.layout<"(32,16,4):(64,4,1)">, !cute.layout<"(128,16):(1,128)">) -> !cute.layout<"((32,4),(4,4)):((64,4),(16,1))">
      %45 = cute.get_shape(%prod_117) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.shape<"((4,4),(4,32))">
      %e0_125, %e1_126, %e2_127, %e3_128 = cute.get_leaves(%45) : !cute.shape<"((4,4),(4,32))">
      %int_tuple_129 = cute.make_int_tuple() : () -> !cute.int_tuple<"((4,4),(4,32))">
      %res_130 = cute.tuple.product_each(%int_tuple_129) : (!cute.int_tuple<"((4,4),(4,32))">) -> !cute.int_tuple<"(16,128)">
      %e0_131, %e1_132 = cute.get_leaves(%res_130) : !cute.int_tuple<"(16,128)">
      %int_tuple_133 = cute.make_int_tuple() : () -> !cute.int_tuple<"(16,128)">
      %res_134 = cute.tuple.product_each(%int_tuple_133) : (!cute.int_tuple<"(16,128)">) -> !cute.int_tuple<"(16,128)">
      %e0_135, %e1_136 = cute.get_leaves(%res_134) : !cute.int_tuple<"(16,128)">
      %tile_137 = cute.make_tile() : () -> !cute.tile<"[16:1;128:1]">
      %46 = cute.make_tiled_copy(%atom_81) : !copy_simt
      %coord_138 = cute.make_coord(%28) : (i32) -> !cute.coord<"?">
      %src_partitioned = cute.tiled.copy.partition_S(%40, %slice, %coord_138) : (!copy_simt, !memref_gmem_f32_1, !cute.coord<"?">) -> !memref_gmem_f32_2
      %iter_139 = cute.get_iter(%src_partitioned) : !memref_gmem_f32_2
      %coord_140 = cute.make_coord(%28) : (i32) -> !cute.coord<"?">
      %src_partitioned_141 = cute.tiled.copy.partition_S(%43, %slice_66, %coord_140) : (!copy_simt, !memref_gmem_f32_1, !cute.coord<"?">) -> !memref_gmem_f32_2
      %iter_142 = cute.get_iter(%src_partitioned_141) : !memref_gmem_f32_2
      %coord_143 = cute.make_coord(%28) : (i32) -> !cute.coord<"?">
      %src_partitioned_144 = cute.tiled.copy.partition_S(%46, %slice_70, %coord_143) : (!copy_simt, !memref_gmem_f32_1, !cute.coord<"?">) -> !memref_gmem_f32_2
      %iter_145 = cute.get_iter(%src_partitioned_144) : !memref_gmem_f32_2
      %lay_146 = cute.get_layout(%src_partitioned) : !memref_gmem_f32_2
      %47 = cute.make_layout_like(%lay_146) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)"> to !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %rmem = cute.memref.alloca(%47) : !memref_rmem_f32_
      %iter_147 = cute.get_iter(%rmem) : !memref_rmem_f32_
      %iter_148 = cute.get_iter(%rmem) : !memref_rmem_f32_
      %lay_149 = cute.get_layout(%src_partitioned_141) : !memref_gmem_f32_2
      %48 = cute.make_layout_like(%lay_149) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)"> to !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %rmem_150 = cute.memref.alloca(%48) : !memref_rmem_f32_
      %iter_151 = cute.get_iter(%rmem_150) : !memref_rmem_f32_
      %iter_152 = cute.get_iter(%rmem_150) : !memref_rmem_f32_
      %lay_153 = cute.get_layout(%src_partitioned_144) : !memref_gmem_f32_2
      %49 = cute.make_layout_like(%lay_153) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)"> to !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %rmem_154 = cute.memref.alloca(%49) : !memref_rmem_f32_
      %iter_155 = cute.get_iter(%rmem_154) : !memref_rmem_f32_
      %iter_156 = cute.get_iter(%rmem_154) : !memref_rmem_f32_
      %coord_157 = cute.make_coord(%28) : (i32) -> !cute.coord<"?">
      %src_partitioned_158 = cute.tiled.copy.partition_S(%46, %slice_74, %coord_157) : (!copy_simt, !cute.coord_tensor<"(?{div=16},?{div=128})", "(16,128):(1@0,1@1)">, !cute.coord<"?">) -> !cute.coord_tensor<"(?{div=4},?{div=4})", "((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">
      %iter_159 = cute.get_iter(%src_partitioned_158) : !cute.coord_tensor<"(?{div=4},?{div=4})", "((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">
      %e0_160, %e1_161 = cute.get_leaves(%iter_159) : !cute.int_tuple<"(?{div=4},?{div=4})">
      %50 = cute.get_scalars(%e0_160) : !cute.int_tuple<"?{div=4}">
      %51 = cute.get_scalars(%e1_161) : !cute.int_tuple<"?{div=4}">
      %lay_162 = cute.get_layout(%src_partitioned_158) : !cute.coord_tensor<"(?{div=4},?{div=4})", "((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">
      %52 = cute.get_shape(%lay_162) : (!cute.layout<"((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_163, %e1_164, %e2_165, %e3_166, %e4 = cute.get_leaves(%52) : !cute.shape<"((1,(4,4)),1,1)">
      %shape_167 = cute.make_shape() : () -> !cute.shape<"((1,(4,4)),1,1)">
      %lay_168 = cute.make_layout(%shape_167) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %rmem_169 = cute.memref.alloca(%lay_168) : !memref_rmem_i8_
      %iter_170 = cute.get_iter(%rmem_169) : !memref_rmem_i8_
      %iter_171 = cute.get_iter(%rmem_169) : !memref_rmem_i8_
      %sz_172 = cute.size(%rmem_169) : (!memref_rmem_i8_) -> !cute.int_tuple<"16">
      %e0_173 = cute.get_leaves(%sz_172) : !cute.int_tuple<"16">
      %lay_174 = cute.get_layout(%rmem_169) : !memref_rmem_i8_
      %53 = cute.get_shape(%lay_174) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_175, %e1_176, %e2_177, %e3_178, %e4_179 = cute.get_leaves(%53) : !cute.shape<"((1,(4,4)),1,1)">
      %54 = cute.get_stride(%lay_174) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.stride<"((0,(1,4)),0,0)">
      %e0_180, %e1_181, %e2_182, %e3_183, %e4_184 = cute.get_leaves(%54) : !cute.stride<"((0,(1,4)),0,0)">
      %c0_i32 = arith.constant 0 : i32
      %c16_i32 = arith.constant 16 : i32
      %c1_i32 = arith.constant 1 : i32
      %55 = scf.for %arg6 = %c0_i32 to %c16_i32 step %c1_i32 iter_args(%arg7 = %rmem_169) -> (!memref_rmem_i8_)  : i32 {
        %iter_421 = cute.get_iter(%arg7) : !memref_rmem_i8_
        %lay_422 = cute.get_layout(%arg7) : !memref_rmem_i8_
        %82 = cute.get_shape(%lay_422) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
        %e0_423, %e1_424, %e2_425, %e3_426, %e4_427 = cute.get_leaves(%82) : !cute.shape<"((1,(4,4)),1,1)">
        %83 = cute.get_stride(%lay_422) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.stride<"((0,(1,4)),0,0)">
        %e0_428, %e1_429, %e2_430, %e3_431, %e4_432 = cute.get_leaves(%83) : !cute.stride<"((0,(1,4)),0,0)">
        %iter_433 = cute.get_iter(%arg7) : !memref_rmem_i8_
        %coord_434 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"?">
        %slice_435 = cute.slice(%src_partitioned_158, %coord_434) : !cute.coord_tensor<"(?{div=4},?{div=4})", "((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">, !cute.coord<"?">
        %iter_436 = cute.get_iter(%slice_435) : !cute.coord_tensor<"(?,?)", "():()">
        %e0_437, %e1_438 = cute.get_leaves(%iter_436) : !cute.int_tuple<"(?,?)">
        %84 = cute.get_scalars(%e0_437) : !cute.int_tuple<"?">
        %85 = cute.get_scalars(%e1_438) : !cute.int_tuple<"?">
        %iter_439 = cute.get_iter(%slice_435) : !cute.coord_tensor<"(?,?)", "():()">
        %e0_440, %e1_441 = cute.get_leaves(%iter_439) : !cute.int_tuple<"(?,?)">
        %86 = cute.get_scalars(%e0_440) : !cute.int_tuple<"?">
        %87 = cute.get_scalars(%e1_441) : !cute.int_tuple<"?">
        %iter_442 = cute.get_iter(%slice_435) : !cute.coord_tensor<"(?,?)", "():()">
        %e0_443, %e1_444 = cute.get_leaves(%iter_442) : !cute.int_tuple<"(?,?)">
        %88 = cute.get_scalars(%e0_443) : !cute.int_tuple<"?">
        %89 = cute.get_scalars(%e1_444) : !cute.int_tuple<"?">
        %coord_445 = cute.make_coord(%e0_443, %e1_444) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
        %coord_446 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
        %90 = cute.elem_less(%coord_445, %coord_446) : !cute.coord<"(?,?)">, !cute.coord<"(?,?)">
        %91 = arith.extui %90 : i1 to i8
        %coord_447 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"?">
        cute.memref.store(%arg7, %coord_447, %91) : (!memref_rmem_i8_, !cute.coord<"?">, i8) -> ()
        %lay_448 = cute.get_layout(%arg7) : !memref_rmem_i8_
        %92 = cute.get_shape(%lay_448) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
        %e0_449, %e1_450, %e2_451, %e3_452, %e4_453 = cute.get_leaves(%92) : !cute.shape<"((1,(4,4)),1,1)">
        %93 = cute.get_stride(%lay_448) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.stride<"((0,(1,4)),0,0)">
        %e0_454, %e1_455, %e2_456, %e3_457, %e4_458 = cute.get_leaves(%93) : !cute.stride<"((0,(1,4)),0,0)">
        scf.yield %arg7 : !memref_rmem_i8_
      }
      %iter_185 = cute.get_iter(%55) : !memref_rmem_i8_
      %lay_186 = cute.get_layout(%55) : !memref_rmem_i8_
      %56 = cute.get_shape(%lay_186) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_187, %e1_188, %e2_189, %e3_190, %e4_191 = cute.get_leaves(%56) : !cute.shape<"((1,(4,4)),1,1)">
      %57 = cute.get_stride(%lay_186) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.stride<"((0,(1,4)),0,0)">
      %e0_192, %e1_193, %e2_194, %e3_195, %e4_196 = cute.get_leaves(%57) : !cute.stride<"((0,(1,4)),0,0)">
      %iter_197 = cute.get_iter(%55) : !memref_rmem_i8_
      %iter_198 = cute.get_iter(%55) : !memref_rmem_i8_
      %lay_199 = cute.get_layout(%src_partitioned) : !memref_gmem_f32_2
      %58 = cute.get_shape(%lay_199) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_200, %e1_201, %e2_202, %e3_203, %e4_204 = cute.get_leaves(%58) : !cute.shape<"((1,(4,4)),1,1)">
      %lay_205 = cute.get_layout(%rmem) : !memref_rmem_f32_
      %59 = cute.get_shape(%lay_205) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_206, %e1_207, %e2_208, %e3_209, %e4_210 = cute.get_leaves(%59) : !cute.shape<"((1,(4,4)),1,1)">
      %lay_211 = cute.get_layout(%src_partitioned) : !memref_gmem_f32_2
      %shape_212 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_213 = cute.make_layout(%shape_212) : !cute.layout<"1:0">
      %append = cute.append_to_rank<2> (%lay_211, %lay_213) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">
      %view = cute.make_view(%iter_139, %append) : !memref_gmem_f32_2
      %iter_214 = cute.get_iter(%view) : !memref_gmem_f32_2
      %lay_215 = cute.get_layout(%view) : !memref_gmem_f32_2
      %60 = cute.get_shape(%lay_215) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_216, %e1_217, %e2_218, %e3_219, %e4_220 = cute.get_leaves(%60) : !cute.shape<"((1,(4,4)),1,1)">
      %grouped = cute.group_modes(%view) <1, 3> : (!memref_gmem_f32_2) -> !memref_gmem_f32_3
      %iter_221 = cute.get_iter(%grouped) : !memref_gmem_f32_3
      %iter_222 = cute.get_iter(%grouped) : !memref_gmem_f32_3
      %lay_223 = cute.get_layout(%rmem) : !memref_rmem_f32_
      %shape_224 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_225 = cute.make_layout(%shape_224) : !cute.layout<"1:0">
      %append_226 = cute.append_to_rank<2> (%lay_223, %lay_225) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
      %view_227 = cute.make_view(%iter_148, %append_226) : !memref_rmem_f32_
      %iter_228 = cute.get_iter(%view_227) : !memref_rmem_f32_
      %lay_229 = cute.get_layout(%view_227) : !memref_rmem_f32_
      %61 = cute.get_shape(%lay_229) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_230, %e1_231, %e2_232, %e3_233, %e4_234 = cute.get_leaves(%61) : !cute.shape<"((1,(4,4)),1,1)">
      %grouped_235 = cute.group_modes(%view_227) <1, 3> : (!memref_rmem_f32_) -> !memref_rmem_f32_1
      %iter_236 = cute.get_iter(%grouped_235) : !memref_rmem_f32_1
      %iter_237 = cute.get_iter(%grouped_235) : !memref_rmem_f32_1
      %lay_238 = cute.get_layout(%55) : !memref_rmem_i8_
      %shape_239 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_240 = cute.make_layout(%shape_239) : !cute.layout<"1:0">
      %append_241 = cute.append_to_rank<2> (%lay_238, %lay_240) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
      %view_242 = cute.make_view(%iter_198, %append_241) : !memref_rmem_i8_
      %iter_243 = cute.get_iter(%view_242) : !memref_rmem_i8_
      %lay_244 = cute.get_layout(%view_242) : !memref_rmem_i8_
      %62 = cute.get_shape(%lay_244) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_245, %e1_246, %e2_247, %e3_248, %e4_249 = cute.get_leaves(%62) : !cute.shape<"((1,(4,4)),1,1)">
      %grouped_250 = cute.group_modes(%view_242) <1, 3> : (!memref_rmem_i8_) -> !memref_rmem_i8_1
      %iter_251 = cute.get_iter(%grouped_250) : !memref_rmem_i8_1
      %iter_252 = cute.get_iter(%grouped_250) : !memref_rmem_i8_1
      %lay_253 = cute.get_layout(%grouped) : !memref_gmem_f32_3
      %63 = cute.get_shape(%lay_253) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
      %e0_254, %e1_255, %e2_256, %e3_257, %e4_258 = cute.get_leaves(%63) : !cute.shape<"((1,(4,4)),(1,1))">
      %lay_259 = cute.get_layout(%grouped_235) : !memref_rmem_f32_1
      %64 = cute.get_shape(%lay_259) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
      %e0_260, %e1_261, %e2_262, %e3_263, %e4_264 = cute.get_leaves(%64) : !cute.shape<"((1,(4,4)),(1,1))">
      %sz_265 = cute.size(%grouped) <{mode = [1]}> : (!memref_gmem_f32_3) -> !cute.int_tuple<"1">
      %e0_266 = cute.get_leaves(%sz_265) : !cute.int_tuple<"1">
      %sz_267 = cute.size(%grouped_235) <{mode = [1]}> : (!memref_rmem_f32_1) -> !cute.int_tuple<"1">
      %e0_268 = cute.get_leaves(%sz_267) : !cute.int_tuple<"1">
      cute.copy(%atom, %grouped, %grouped_235, %grouped_250) : (!cute_nvgpu.atom.universal_copy<f32>, !memref_gmem_f32_3, !memref_rmem_f32_1, !memref_rmem_i8_1)
      %lay_269 = cute.get_layout(%src_partitioned_141) : !memref_gmem_f32_2
      %65 = cute.get_shape(%lay_269) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_270, %e1_271, %e2_272, %e3_273, %e4_274 = cute.get_leaves(%65) : !cute.shape<"((1,(4,4)),1,1)">
      %lay_275 = cute.get_layout(%rmem_150) : !memref_rmem_f32_
      %66 = cute.get_shape(%lay_275) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_276, %e1_277, %e2_278, %e3_279, %e4_280 = cute.get_leaves(%66) : !cute.shape<"((1,(4,4)),1,1)">
      %lay_281 = cute.get_layout(%src_partitioned_141) : !memref_gmem_f32_2
      %shape_282 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_283 = cute.make_layout(%shape_282) : !cute.layout<"1:0">
      %append_284 = cute.append_to_rank<2> (%lay_281, %lay_283) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">
      %view_285 = cute.make_view(%iter_142, %append_284) : !memref_gmem_f32_2
      %iter_286 = cute.get_iter(%view_285) : !memref_gmem_f32_2
      %lay_287 = cute.get_layout(%view_285) : !memref_gmem_f32_2
      %67 = cute.get_shape(%lay_287) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_288, %e1_289, %e2_290, %e3_291, %e4_292 = cute.get_leaves(%67) : !cute.shape<"((1,(4,4)),1,1)">
      %grouped_293 = cute.group_modes(%view_285) <1, 3> : (!memref_gmem_f32_2) -> !memref_gmem_f32_3
      %iter_294 = cute.get_iter(%grouped_293) : !memref_gmem_f32_3
      %iter_295 = cute.get_iter(%grouped_293) : !memref_gmem_f32_3
      %lay_296 = cute.get_layout(%rmem_150) : !memref_rmem_f32_
      %shape_297 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_298 = cute.make_layout(%shape_297) : !cute.layout<"1:0">
      %append_299 = cute.append_to_rank<2> (%lay_296, %lay_298) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
      %view_300 = cute.make_view(%iter_152, %append_299) : !memref_rmem_f32_
      %iter_301 = cute.get_iter(%view_300) : !memref_rmem_f32_
      %lay_302 = cute.get_layout(%view_300) : !memref_rmem_f32_
      %68 = cute.get_shape(%lay_302) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_303, %e1_304, %e2_305, %e3_306, %e4_307 = cute.get_leaves(%68) : !cute.shape<"((1,(4,4)),1,1)">
      %grouped_308 = cute.group_modes(%view_300) <1, 3> : (!memref_rmem_f32_) -> !memref_rmem_f32_1
      %iter_309 = cute.get_iter(%grouped_308) : !memref_rmem_f32_1
      %iter_310 = cute.get_iter(%grouped_308) : !memref_rmem_f32_1
      %lay_311 = cute.get_layout(%55) : !memref_rmem_i8_
      %shape_312 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_313 = cute.make_layout(%shape_312) : !cute.layout<"1:0">
      %append_314 = cute.append_to_rank<2> (%lay_311, %lay_313) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
      %view_315 = cute.make_view(%iter_198, %append_314) : !memref_rmem_i8_
      %iter_316 = cute.get_iter(%view_315) : !memref_rmem_i8_
      %lay_317 = cute.get_layout(%view_315) : !memref_rmem_i8_
      %69 = cute.get_shape(%lay_317) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_318, %e1_319, %e2_320, %e3_321, %e4_322 = cute.get_leaves(%69) : !cute.shape<"((1,(4,4)),1,1)">
      %grouped_323 = cute.group_modes(%view_315) <1, 3> : (!memref_rmem_i8_) -> !memref_rmem_i8_1
      %iter_324 = cute.get_iter(%grouped_323) : !memref_rmem_i8_1
      %iter_325 = cute.get_iter(%grouped_323) : !memref_rmem_i8_1
      %lay_326 = cute.get_layout(%grouped_293) : !memref_gmem_f32_3
      %70 = cute.get_shape(%lay_326) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
      %e0_327, %e1_328, %e2_329, %e3_330, %e4_331 = cute.get_leaves(%70) : !cute.shape<"((1,(4,4)),(1,1))">
      %lay_332 = cute.get_layout(%grouped_308) : !memref_rmem_f32_1
      %71 = cute.get_shape(%lay_332) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
      %e0_333, %e1_334, %e2_335, %e3_336, %e4_337 = cute.get_leaves(%71) : !cute.shape<"((1,(4,4)),(1,1))">
      %sz_338 = cute.size(%grouped_293) <{mode = [1]}> : (!memref_gmem_f32_3) -> !cute.int_tuple<"1">
      %e0_339 = cute.get_leaves(%sz_338) : !cute.int_tuple<"1">
      %sz_340 = cute.size(%grouped_308) <{mode = [1]}> : (!memref_rmem_f32_1) -> !cute.int_tuple<"1">
      %e0_341 = cute.get_leaves(%sz_340) : !cute.int_tuple<"1">
      cute.copy(%atom, %grouped_293, %grouped_308, %grouped_323) : (!cute_nvgpu.atom.universal_copy<f32>, !memref_gmem_f32_3, !memref_rmem_f32_1, !memref_rmem_i8_1)
      %72 = cute.memref.load_vec %rmem : !memref_rmem_f32_
      %73 = cute.memref.load_vec %rmem_150 : !memref_rmem_f32_
      %74 = arith.addf %72, %73 : vector<16xf32>
      %lay_342 = cute.get_layout(%rmem_154) : !memref_rmem_f32_
      %75 = cute.get_shape(%lay_342) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_343, %e1_344, %e2_345, %e3_346, %e4_347 = cute.get_leaves(%75) : !cute.shape<"((1,(4,4)),1,1)">
      %int_tuple_348 = cute.make_int_tuple() : () -> !cute.int_tuple<"((1,(4,4)),1,1)">
      %sz_349 = cute.size(%int_tuple_348) : (!cute.int_tuple<"((1,(4,4)),1,1)">) -> !cute.int_tuple<"16">
      %e0_350 = cute.get_leaves(%sz_349) : !cute.int_tuple<"16">
      %int_tuple_351 = cute.make_int_tuple() : () -> !cute.int_tuple<"((1,(4,4)),1,1)">
      %sz_352 = cute.size(%int_tuple_351) : (!cute.int_tuple<"((1,(4,4)),1,1)">) -> !cute.int_tuple<"16">
      %e0_353 = cute.get_leaves(%sz_352) : !cute.int_tuple<"16">
      cute.memref.store_vec %74, %rmem_154 : !memref_rmem_f32_
      %lay_354 = cute.get_layout(%src_partitioned_144) : !memref_gmem_f32_2
      %76 = cute.get_shape(%lay_354) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_355, %e1_356, %e2_357, %e3_358, %e4_359 = cute.get_leaves(%76) : !cute.shape<"((1,(4,4)),1,1)">
      %lay_360 = cute.get_layout(%rmem_154) : !memref_rmem_f32_
      %shape_361 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_362 = cute.make_layout(%shape_361) : !cute.layout<"1:0">
      %append_363 = cute.append_to_rank<2> (%lay_360, %lay_362) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
      %view_364 = cute.make_view(%iter_156, %append_363) : !memref_rmem_f32_
      %iter_365 = cute.get_iter(%view_364) : !memref_rmem_f32_
      %lay_366 = cute.get_layout(%view_364) : !memref_rmem_f32_
      %77 = cute.get_shape(%lay_366) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_367, %e1_368, %e2_369, %e3_370, %e4_371 = cute.get_leaves(%77) : !cute.shape<"((1,(4,4)),1,1)">
      %grouped_372 = cute.group_modes(%view_364) <1, 3> : (!memref_rmem_f32_) -> !memref_rmem_f32_1
      %iter_373 = cute.get_iter(%grouped_372) : !memref_rmem_f32_1
      %iter_374 = cute.get_iter(%grouped_372) : !memref_rmem_f32_1
      %lay_375 = cute.get_layout(%src_partitioned_144) : !memref_gmem_f32_2
      %shape_376 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_377 = cute.make_layout(%shape_376) : !cute.layout<"1:0">
      %append_378 = cute.append_to_rank<2> (%lay_375, %lay_377) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">
      %view_379 = cute.make_view(%iter_145, %append_378) : !memref_gmem_f32_2
      %iter_380 = cute.get_iter(%view_379) : !memref_gmem_f32_2
      %lay_381 = cute.get_layout(%view_379) : !memref_gmem_f32_2
      %78 = cute.get_shape(%lay_381) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_382, %e1_383, %e2_384, %e3_385, %e4_386 = cute.get_leaves(%78) : !cute.shape<"((1,(4,4)),1,1)">
      %grouped_387 = cute.group_modes(%view_379) <1, 3> : (!memref_gmem_f32_2) -> !memref_gmem_f32_3
      %iter_388 = cute.get_iter(%grouped_387) : !memref_gmem_f32_3
      %iter_389 = cute.get_iter(%grouped_387) : !memref_gmem_f32_3
      %lay_390 = cute.get_layout(%55) : !memref_rmem_i8_
      %shape_391 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_392 = cute.make_layout(%shape_391) : !cute.layout<"1:0">
      %append_393 = cute.append_to_rank<2> (%lay_390, %lay_392) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
      %view_394 = cute.make_view(%iter_198, %append_393) : !memref_rmem_i8_
      %iter_395 = cute.get_iter(%view_394) : !memref_rmem_i8_
      %lay_396 = cute.get_layout(%view_394) : !memref_rmem_i8_
      %79 = cute.get_shape(%lay_396) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_397, %e1_398, %e2_399, %e3_400, %e4_401 = cute.get_leaves(%79) : !cute.shape<"((1,(4,4)),1,1)">
      %grouped_402 = cute.group_modes(%view_394) <1, 3> : (!memref_rmem_i8_) -> !memref_rmem_i8_1
      %iter_403 = cute.get_iter(%grouped_402) : !memref_rmem_i8_1
      %iter_404 = cute.get_iter(%grouped_402) : !memref_rmem_i8_1
      %lay_405 = cute.get_layout(%grouped_372) : !memref_rmem_f32_1
      %80 = cute.get_shape(%lay_405) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
      %e0_406, %e1_407, %e2_408, %e3_409, %e4_410 = cute.get_leaves(%80) : !cute.shape<"((1,(4,4)),(1,1))">
      %lay_411 = cute.get_layout(%grouped_387) : !memref_gmem_f32_3
      %81 = cute.get_shape(%lay_411) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
      %e0_412, %e1_413, %e2_414, %e3_415, %e4_416 = cute.get_leaves(%81) : !cute.shape<"((1,(4,4)),(1,1))">
      %sz_417 = cute.size(%grouped_372) <{mode = [1]}> : (!memref_rmem_f32_1) -> !cute.int_tuple<"1">
      %e0_418 = cute.get_leaves(%sz_417) : !cute.int_tuple<"1">
      %sz_419 = cute.size(%grouped_387) <{mode = [1]}> : (!memref_gmem_f32_3) -> !cute.int_tuple<"1">
      %e0_420 = cute.get_leaves(%sz_419) : !cute.int_tuple<"1">
      cute.copy(%atom_81, %grouped_372, %grouped_387, %grouped_402) : (!cute_nvgpu.atom.universal_copy<f32>, !memref_rmem_f32_1, !memref_gmem_f32_3, !memref_rmem_i8_1)
      return
    }
  }
  func.func @cutlass_elementwise_add_tensor02841_02912_01912_08313_09196_09403_10126_01202_16746_01064_01796_23174_06047_09508_18613_09638_07238_13885_01225_14714_08045_25177_11321_05292_11895_(%arg0: !memref_gmem_f32_4, %arg1: !memref_gmem_f32_4, %arg2: !memref_gmem_f32_4) -> i32 attributes {llvm.emit_c_interface} {
    %iter = cute.get_iter(%arg0) : !memref_gmem_f32_4
    %iter_0 = cute.get_iter(%arg1) : !memref_gmem_f32_4
    %iter_1 = cute.get_iter(%arg2) : !memref_gmem_f32_4
    %iter_2 = cute.get_iter(%arg0) : !memref_gmem_f32_4
    %iter_3 = cute.get_iter(%arg1) : !memref_gmem_f32_4
    %iter_4 = cute.get_iter(%arg2) : !memref_gmem_f32_4
    %lay = cute.get_layout(%arg0) : !memref_gmem_f32_4
    %0 = cute.get_shape(%lay) : (!cute.layout<"(?,?):(?{i64},1)">) -> !cute.shape<"(?,?)">
    %e0, %e1 = cute.get_leaves(%0) : !cute.shape<"(?,?)">
    %itup = cute.to_int_tuple(%e0) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %1 = cute.get_scalars(%itup) : !cute.int_tuple<"?">
    %itup_5 = cute.to_int_tuple(%e1) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %2 = cute.get_scalars(%itup_5) : !cute.int_tuple<"?">
    %3 = cute.get_stride(%lay) : (!cute.layout<"(?,?):(?{i64},1)">) -> !cute.stride<"(?{i64},1)">
    %e0_6, %e1_7 = cute.get_leaves(%3) : !cute.stride<"(?{i64},1)">
    %itup_8 = cute.to_int_tuple(%e0_6) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
    %4 = cute.get_scalars(%itup_8) : !cute.int_tuple<"?{i64}">
    %lay_9 = cute.get_layout(%arg1) : !memref_gmem_f32_4
    %5 = cute.get_shape(%lay_9) : (!cute.layout<"(?,?):(?{i64},1)">) -> !cute.shape<"(?,?)">
    %e0_10, %e1_11 = cute.get_leaves(%5) : !cute.shape<"(?,?)">
    %itup_12 = cute.to_int_tuple(%e0_10) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %6 = cute.get_scalars(%itup_12) : !cute.int_tuple<"?">
    %itup_13 = cute.to_int_tuple(%e1_11) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %7 = cute.get_scalars(%itup_13) : !cute.int_tuple<"?">
    %8 = cute.get_stride(%lay_9) : (!cute.layout<"(?,?):(?{i64},1)">) -> !cute.stride<"(?{i64},1)">
    %e0_14, %e1_15 = cute.get_leaves(%8) : !cute.stride<"(?{i64},1)">
    %itup_16 = cute.to_int_tuple(%e0_14) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
    %9 = cute.get_scalars(%itup_16) : !cute.int_tuple<"?{i64}">
    %lay_17 = cute.get_layout(%arg2) : !memref_gmem_f32_4
    %10 = cute.get_shape(%lay_17) : (!cute.layout<"(?,?):(?{i64},1)">) -> !cute.shape<"(?,?)">
    %e0_18, %e1_19 = cute.get_leaves(%10) : !cute.shape<"(?,?)">
    %itup_20 = cute.to_int_tuple(%e0_18) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %11 = cute.get_scalars(%itup_20) : !cute.int_tuple<"?">
    %itup_21 = cute.to_int_tuple(%e1_19) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %12 = cute.get_scalars(%itup_21) : !cute.int_tuple<"?">
    %13 = cute.get_stride(%lay_17) : (!cute.layout<"(?,?):(?{i64},1)">) -> !cute.stride<"(?{i64},1)">
    %e0_22, %e1_23 = cute.get_leaves(%13) : !cute.stride<"(?{i64},1)">
    %itup_24 = cute.to_int_tuple(%e0_22) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
    %14 = cute.get_scalars(%itup_24) : !cute.int_tuple<"?{i64}">
    %shape = cute.make_shape() : () -> !cute.shape<"(4,32)">
    %int_tuple = cute.make_int_tuple() : () -> !cute.int_tuple<"(1,0)">
    %lay_25 = cute.make_ordered_layout(%shape, %int_tuple) : (!cute.shape<"(4,32)">, !cute.int_tuple<"(1,0)">) -> !cute.layout<"(4,32):(32,1)">
    %shape_26 = cute.make_shape() : () -> !cute.shape<"(4,4)">
    %int_tuple_27 = cute.make_int_tuple() : () -> !cute.int_tuple<"(1,0)">
    %lay_28 = cute.make_ordered_layout(%shape_26, %int_tuple_27) : (!cute.shape<"(4,4)">, !cute.int_tuple<"(1,0)">) -> !cute.layout<"(4,4):(4,1)">
    %prod = cute.raked_product(%lay_25, %lay_28) : (!cute.layout<"(4,32):(32,1)">, !cute.layout<"(4,4):(4,1)">) -> !cute.layout<"((4,4),(4,32)):((512,32),(128,1))">
    %sz = cute.size(%lay_25) : (!cute.layout<"(4,32):(32,1)">) -> !cute.int_tuple<"128">
    %e0_29 = cute.get_leaves(%sz) : !cute.int_tuple<"128">
    %sz_30 = cute.size(%lay_28) : (!cute.layout<"(4,4):(4,1)">) -> !cute.int_tuple<"16">
    %e0_31 = cute.get_leaves(%sz_30) : !cute.int_tuple<"16">
    %shape_32 = cute.make_shape() : () -> !cute.shape<"(128,16)">
    %lay_33 = cute.make_layout(%shape_32) : !cute.layout<"(128,16):(1,128)">
    %rinv = cute.right_inverse(%prod) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.layout<"(32,16,4):(64,4,1)">
    %15 = cute.composition(%rinv, %lay_33) : (!cute.layout<"(32,16,4):(64,4,1)">, !cute.layout<"(128,16):(1,128)">) -> !cute.layout<"((32,4),(4,4)):((64,4),(16,1))">
    %16 = cute.get_shape(%prod) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.shape<"((4,4),(4,32))">
    %e0_34, %e1_35, %e2, %e3 = cute.get_leaves(%16) : !cute.shape<"((4,4),(4,32))">
    %int_tuple_36 = cute.make_int_tuple() : () -> !cute.int_tuple<"((4,4),(4,32))">
    %res = cute.tuple.product_each(%int_tuple_36) : (!cute.int_tuple<"((4,4),(4,32))">) -> !cute.int_tuple<"(16,128)">
    %e0_37, %e1_38 = cute.get_leaves(%res) : !cute.int_tuple<"(16,128)">
    %17 = cute.get_shape(%15) : (!cute.layout<"((32,4),(4,4)):((64,4),(16,1))">) -> !cute.shape<"((32,4),(4,4))">
    %e0_39, %e1_40, %e2_41, %e3_42 = cute.get_leaves(%17) : !cute.shape<"((32,4),(4,4))">
    %18 = cute.get_stride(%15) : (!cute.layout<"((32,4),(4,4)):((64,4),(16,1))">) -> !cute.stride<"((64,4),(16,1))">
    %e0_43, %e1_44, %e2_45, %e3_46 = cute.get_leaves(%18) : !cute.stride<"((64,4),(16,1))">
    %tile = cute.make_tile() : () -> !cute.tile<"[16:1;128:1]">
    %div = cute.zipped_divide(%arg0, %tile) : !memref_gmem_f32_4, !cute.tile<"[16:1;128:1]">
    %iter_47 = cute.get_iter(%div) : !memref_gmem_f32_
    %iter_48 = cute.get_iter(%div) : !memref_gmem_f32_
    %tile_49 = cute.make_tile() : () -> !cute.tile<"[16:1;128:1]">
    %div_50 = cute.zipped_divide(%arg1, %tile_49) : !memref_gmem_f32_4, !cute.tile<"[16:1;128:1]">
    %iter_51 = cute.get_iter(%div_50) : !memref_gmem_f32_
    %iter_52 = cute.get_iter(%div_50) : !memref_gmem_f32_
    %tile_53 = cute.make_tile() : () -> !cute.tile<"[16:1;128:1]">
    %div_54 = cute.zipped_divide(%arg2, %tile_53) : !memref_gmem_f32_4, !cute.tile<"[16:1;128:1]">
    %iter_55 = cute.get_iter(%div_54) : !memref_gmem_f32_
    %iter_56 = cute.get_iter(%div_54) : !memref_gmem_f32_
    %lay_57 = cute.get_layout(%arg2) : !memref_gmem_f32_4
    %19 = cute.get_shape(%lay_57) : (!cute.layout<"(?,?):(?{i64},1)">) -> !cute.shape<"(?,?)">
    %e0_58, %e1_59 = cute.get_leaves(%19) : !cute.shape<"(?,?)">
    %itup_60 = cute.to_int_tuple(%e0_58) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %20 = cute.get_scalars(%itup_60) : !cute.int_tuple<"?">
    %itup_61 = cute.to_int_tuple(%e1_59) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %21 = cute.get_scalars(%itup_61) : !cute.int_tuple<"?">
    %shape_62 = cute.make_shape(%itup_60, %itup_61) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.shape<"(?,?)">
    %22 = cute.make_identity_tensor(%shape_62) : !cute.coord_tensor<"(0,0)", "(?,?):(1@0,1@1)">
    %iter_63 = cute.get_iter(%22) : !cute.coord_tensor<"(0,0)", "(?,?):(1@0,1@1)">
    %e0_64, %e1_65 = cute.get_leaves(%iter_63) : !cute.int_tuple<"(0,0)">
    %tile_66 = cute.make_tile() : () -> !cute.tile<"[16:1;128:1]">
    %div_67 = cute.zipped_divide(%22, %tile_66) : !cute.coord_tensor<"(0,0)", "(?,?):(1@0,1@1)">, !cute.tile<"[16:1;128:1]">
    %iter_68 = cute.get_iter(%div_67) : !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
    %e0_69, %e1_70 = cute.get_leaves(%iter_68) : !cute.int_tuple<"(0,0)">
    %iter_71 = cute.get_iter(%div_67) : !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
    %e0_72, %e1_73 = cute.get_leaves(%iter_71) : !cute.int_tuple<"(0,0)">
    %sz_74 = cute.size(%div_54) <{mode = [1]}> : (!memref_gmem_f32_) -> !cute.int_tuple<"?">
    %e0_75 = cute.get_leaves(%sz_74) : !cute.int_tuple<"?">
    %23 = cute.get_scalars(%e0_75) : !cute.int_tuple<"?">
    %sz_76 = cute.size(%15) <{mode = [0]}> : (!cute.layout<"((32,4),(4,4)):((64,4),(16,1))">) -> !cute.int_tuple<"128">
    %e0_77 = cute.get_leaves(%sz_76) : !cute.int_tuple<"128">
    %lay_78 = cute.get_layout(%div) : !memref_gmem_f32_
    %24 = cute.get_shape(%lay_78) : (!cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.shape<"((16,128),(?,?))">
    %e0_79, %e1_80, %e2_81, %e3_82 = cute.get_leaves(%24) : !cute.shape<"((16,128),(?,?))">
    %itup_83 = cute.to_int_tuple(%e2_81) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %25 = cute.get_scalars(%itup_83) : !cute.int_tuple<"?">
    %itup_84 = cute.to_int_tuple(%e3_82) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %26 = cute.get_scalars(%itup_84) : !cute.int_tuple<"?">
    %27 = cute.get_stride(%lay_78) : (!cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.stride<"((?{i64},1),(?{i64 div=16},128))">
    %e0_85, %e1_86, %e2_87, %e3_88 = cute.get_leaves(%27) : !cute.stride<"((?{i64},1),(?{i64 div=16},128))">
    %itup_89 = cute.to_int_tuple(%e0_85) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
    %28 = cute.get_scalars(%itup_89) : !cute.int_tuple<"?{i64}">
    %itup_90 = cute.to_int_tuple(%e2_87) : !cute.stride<"?{i64 div=16}"> to !cute.int_tuple<"?{i64 div=16}">
    %29 = cute.get_scalars(%itup_90) : !cute.int_tuple<"?{i64 div=16}">
    %lay_91 = cute.get_layout(%div_50) : !memref_gmem_f32_
    %30 = cute.get_shape(%lay_91) : (!cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.shape<"((16,128),(?,?))">
    %e0_92, %e1_93, %e2_94, %e3_95 = cute.get_leaves(%30) : !cute.shape<"((16,128),(?,?))">
    %itup_96 = cute.to_int_tuple(%e2_94) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %31 = cute.get_scalars(%itup_96) : !cute.int_tuple<"?">
    %itup_97 = cute.to_int_tuple(%e3_95) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %32 = cute.get_scalars(%itup_97) : !cute.int_tuple<"?">
    %33 = cute.get_stride(%lay_91) : (!cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.stride<"((?{i64},1),(?{i64 div=16},128))">
    %e0_98, %e1_99, %e2_100, %e3_101 = cute.get_leaves(%33) : !cute.stride<"((?{i64},1),(?{i64 div=16},128))">
    %itup_102 = cute.to_int_tuple(%e0_98) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
    %34 = cute.get_scalars(%itup_102) : !cute.int_tuple<"?{i64}">
    %itup_103 = cute.to_int_tuple(%e2_100) : !cute.stride<"?{i64 div=16}"> to !cute.int_tuple<"?{i64 div=16}">
    %35 = cute.get_scalars(%itup_103) : !cute.int_tuple<"?{i64 div=16}">
    %lay_104 = cute.get_layout(%div_54) : !memref_gmem_f32_
    %36 = cute.get_shape(%lay_104) : (!cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.shape<"((16,128),(?,?))">
    %e0_105, %e1_106, %e2_107, %e3_108 = cute.get_leaves(%36) : !cute.shape<"((16,128),(?,?))">
    %itup_109 = cute.to_int_tuple(%e2_107) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %37 = cute.get_scalars(%itup_109) : !cute.int_tuple<"?">
    %itup_110 = cute.to_int_tuple(%e3_108) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %38 = cute.get_scalars(%itup_110) : !cute.int_tuple<"?">
    %39 = cute.get_stride(%lay_104) : (!cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.stride<"((?{i64},1),(?{i64 div=16},128))">
    %e0_111, %e1_112, %e2_113, %e3_114 = cute.get_leaves(%39) : !cute.stride<"((?{i64},1),(?{i64 div=16},128))">
    %itup_115 = cute.to_int_tuple(%e0_111) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
    %40 = cute.get_scalars(%itup_115) : !cute.int_tuple<"?{i64}">
    %itup_116 = cute.to_int_tuple(%e2_113) : !cute.stride<"?{i64 div=16}"> to !cute.int_tuple<"?{i64 div=16}">
    %41 = cute.get_scalars(%itup_116) : !cute.int_tuple<"?{i64 div=16}">
    %lay_117 = cute.get_layout(%div_67) : !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
    %42 = cute.get_shape(%lay_117) : (!cute.layout<"((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">) -> !cute.shape<"((16,128),(?,?))">
    %e0_118, %e1_119, %e2_120, %e3_121 = cute.get_leaves(%42) : !cute.shape<"((16,128),(?,?))">
    %itup_122 = cute.to_int_tuple(%e2_120) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %43 = cute.get_scalars(%itup_122) : !cute.int_tuple<"?">
    %itup_123 = cute.to_int_tuple(%e3_121) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %44 = cute.get_scalars(%itup_123) : !cute.int_tuple<"?">
    %45 = cute.get_stride(%lay_117) : (!cute.layout<"((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">) -> !cute.stride<"((1@0,1@1),(16@0,128@1))">
    %e0_124, %e1_125, %e2_126, %e3_127 = cute.get_leaves(%45) : !cute.stride<"((1@0,1@1),(16@0,128@1))">
    %46 = cute.get_shape(%lay_25) : (!cute.layout<"(4,32):(32,1)">) -> !cute.shape<"(4,32)">
    %e0_128, %e1_129 = cute.get_leaves(%46) : !cute.shape<"(4,32)">
    %47 = cute.get_stride(%lay_25) : (!cute.layout<"(4,32):(32,1)">) -> !cute.stride<"(32,1)">
    %e0_130, %e1_131 = cute.get_leaves(%47) : !cute.stride<"(32,1)">
    %48 = cute.get_shape(%lay_28) : (!cute.layout<"(4,4):(4,1)">) -> !cute.shape<"(4,4)">
    %e0_132, %e1_133 = cute.get_leaves(%48) : !cute.shape<"(4,4)">
    %49 = cute.get_stride(%lay_28) : (!cute.layout<"(4,4):(4,1)">) -> !cute.stride<"(4,1)">
    %e0_134, %e1_135 = cute.get_leaves(%49) : !cute.stride<"(4,1)">
    %c0_i32 = arith.constant 0 : i32
    %c0_i64 = arith.constant 0 : i64
    %50 = cuda.cast %c0_i64 : i64 -> !cuda.stream
    %51 = arith.extsi %c0_i32 : i32 to i64
    %c128_i32 = arith.constant 128 : i32
    %c1_i32 = arith.constant 1 : i32
    %52 = cuda.launch_cfg.create<max_attrs = 2 : i32> (blockDim = (%c128_i32, %c1_i32, %c1_i32), dynamicSmemBytes = %51, gridDim = (%23, %c1_i32, %c1_i32), stream = %50) : i32, i32, i32, i64, i32, i32, i32, !cuda.stream -> !cuda.launch_cfg<max_attrs = 2>
    %53 = cuda.launch_ex @kernels::@kernel_cutlass_elementwise_add_kernel_tensorptrf32gmemo161281i64div16128_tensorptrf32gmemo161281i64div16128_tensorptrf32gmemo161281i64div16128_tensor00o1612810111601281___0<%52> (%div, %div_50, %div_54, %div_67, %20, %21) : !cuda.launch_cfg<max_attrs = 2>, (!memref_gmem_f32_, !memref_gmem_f32_, !memref_gmem_f32_, !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">, i32, i32) -> !cuda.result
    %54 = cuda.cast %53 : !cuda.result -> i32
    cuda.return_if_error %54 : i32
    %c0_i32_136 = arith.constant 0 : i32
    return %c0_i32_136 : i32
  }
}
