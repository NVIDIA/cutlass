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
    cuda.kernel @kernel_cutlass_elementwise_add_kernel_tensorptrf32gmemo161281i64div16128_tensorptrf32gmemo161281i64div16128_tensorptrf32gmemo161281i64div16128_tensor00o1612810111601281___False_0(%arg0: !memref_gmem_f32_, %arg1: !memref_gmem_f32_, %arg2: !memref_gmem_f32_, %arg3: !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">, %arg4: i32, %arg5: i32) attributes {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} {
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
      %c0_i32 = arith.constant 0 : i32
      %c16_i32 = arith.constant 16 : i32
      %c1_i32 = arith.constant 1 : i32
      %53 = scf.for %arg6 = %c0_i32 to %c16_i32 step %c1_i32 iter_args(%arg7 = %rmem_169) -> (!memref_rmem_i8_)  : i32 {
        %iter_256 = cute.get_iter(%arg7) : !memref_rmem_i8_
        %iter_257 = cute.get_iter(%arg7) : !memref_rmem_i8_
        %coord_258 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"?">
        %slice_259 = cute.slice(%src_partitioned_158, %coord_258) : !cute.coord_tensor<"(?{div=4},?{div=4})", "((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">, !cute.coord<"?">
        %iter_260 = cute.get_iter(%slice_259) : !cute.coord_tensor<"(?,?)", "():()">
        %e0_261, %e1_262 = cute.get_leaves(%iter_260) : !cute.int_tuple<"(?,?)">
        %62 = cute.get_scalars(%e0_261) : !cute.int_tuple<"?">
        %63 = cute.get_scalars(%e1_262) : !cute.int_tuple<"?">
        %iter_263 = cute.get_iter(%slice_259) : !cute.coord_tensor<"(?,?)", "():()">
        %e0_264, %e1_265 = cute.get_leaves(%iter_263) : !cute.int_tuple<"(?,?)">
        %64 = cute.get_scalars(%e0_264) : !cute.int_tuple<"?">
        %65 = cute.get_scalars(%e1_265) : !cute.int_tuple<"?">
        %iter_266 = cute.get_iter(%slice_259) : !cute.coord_tensor<"(?,?)", "():()">
        %e0_267, %e1_268 = cute.get_leaves(%iter_266) : !cute.int_tuple<"(?,?)">
        %66 = cute.get_scalars(%e0_267) : !cute.int_tuple<"?">
        %67 = cute.get_scalars(%e1_268) : !cute.int_tuple<"?">
        %coord_269 = cute.make_coord(%e0_267, %e1_268) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
        %coord_270 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
        %68 = cute.elem_less(%coord_269, %coord_270) : !cute.coord<"(?,?)">, !cute.coord<"(?,?)">
        %69 = arith.extui %68 : i1 to i8
        %coord_271 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"?">
        cute.memref.store(%arg7, %coord_271, %69) : (!memref_rmem_i8_, !cute.coord<"?">, i8) -> ()
        scf.yield %arg7 : !memref_rmem_i8_
      }
      %iter_174 = cute.get_iter(%53) : !memref_rmem_i8_
      %iter_175 = cute.get_iter(%53) : !memref_rmem_i8_
      %iter_176 = cute.get_iter(%53) : !memref_rmem_i8_
      %false = arith.constant false
      scf.if %false {
        %c0_i32_256 = arith.constant 0 : i32
        %c10_i32_257 = arith.constant 10 : i32
        %c1_i32_258 = arith.constant 1 : i32
        scf.for %arg6 = %c0_i32_256 to %c10_i32_257 step %c1_i32_258  : i32 {
          %lay_259 = cute.get_layout(%src_partitioned) : !memref_gmem_f32_2
          %62 = cute.get_shape(%lay_259) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_260, %e1_261, %e2_262, %e3_263, %e4_264 = cute.get_leaves(%62) : !cute.shape<"((1,(4,4)),1,1)">
          %lay_265 = cute.get_layout(%rmem) : !memref_rmem_f32_
          %63 = cute.get_shape(%lay_265) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_266, %e1_267, %e2_268, %e3_269, %e4_270 = cute.get_leaves(%63) : !cute.shape<"((1,(4,4)),1,1)">
          %lay_271 = cute.get_layout(%src_partitioned) : !memref_gmem_f32_2
          %shape_272 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_273 = cute.make_layout(%shape_272) : !cute.layout<"1:0">
          %append_274 = cute.append_to_rank<2> (%lay_271, %lay_273) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">
          %view_275 = cute.make_view(%iter_139, %append_274) : !memref_gmem_f32_2
          %iter_276 = cute.get_iter(%view_275) : !memref_gmem_f32_2
          %lay_277 = cute.get_layout(%view_275) : !memref_gmem_f32_2
          %64 = cute.get_shape(%lay_277) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_278, %e1_279, %e2_280, %e3_281, %e4_282 = cute.get_leaves(%64) : !cute.shape<"((1,(4,4)),1,1)">
          %grouped_283 = cute.group_modes(%view_275) <1, 3> : (!memref_gmem_f32_2) -> !memref_gmem_f32_3
          %iter_284 = cute.get_iter(%grouped_283) : !memref_gmem_f32_3
          %iter_285 = cute.get_iter(%grouped_283) : !memref_gmem_f32_3
          %lay_286 = cute.get_layout(%rmem) : !memref_rmem_f32_
          %shape_287 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_288 = cute.make_layout(%shape_287) : !cute.layout<"1:0">
          %append_289 = cute.append_to_rank<2> (%lay_286, %lay_288) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
          %view_290 = cute.make_view(%iter_148, %append_289) : !memref_rmem_f32_
          %iter_291 = cute.get_iter(%view_290) : !memref_rmem_f32_
          %lay_292 = cute.get_layout(%view_290) : !memref_rmem_f32_
          %65 = cute.get_shape(%lay_292) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_293, %e1_294, %e2_295, %e3_296, %e4_297 = cute.get_leaves(%65) : !cute.shape<"((1,(4,4)),1,1)">
          %grouped_298 = cute.group_modes(%view_290) <1, 3> : (!memref_rmem_f32_) -> !memref_rmem_f32_1
          %iter_299 = cute.get_iter(%grouped_298) : !memref_rmem_f32_1
          %iter_300 = cute.get_iter(%grouped_298) : !memref_rmem_f32_1
          %lay_301 = cute.get_layout(%53) : !memref_rmem_i8_
          %shape_302 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_303 = cute.make_layout(%shape_302) : !cute.layout<"1:0">
          %append_304 = cute.append_to_rank<2> (%lay_301, %lay_303) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
          %view_305 = cute.make_view(%iter_176, %append_304) : !memref_rmem_i8_
          %iter_306 = cute.get_iter(%view_305) : !memref_rmem_i8_
          %lay_307 = cute.get_layout(%view_305) : !memref_rmem_i8_
          %66 = cute.get_shape(%lay_307) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_308, %e1_309, %e2_310, %e3_311, %e4_312 = cute.get_leaves(%66) : !cute.shape<"((1,(4,4)),1,1)">
          %grouped_313 = cute.group_modes(%view_305) <1, 3> : (!memref_rmem_i8_) -> !memref_rmem_i8_1
          %iter_314 = cute.get_iter(%grouped_313) : !memref_rmem_i8_1
          %iter_315 = cute.get_iter(%grouped_313) : !memref_rmem_i8_1
          %lay_316 = cute.get_layout(%grouped_283) : !memref_gmem_f32_3
          %67 = cute.get_shape(%lay_316) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
          %e0_317, %e1_318, %e2_319, %e3_320, %e4_321 = cute.get_leaves(%67) : !cute.shape<"((1,(4,4)),(1,1))">
          %lay_322 = cute.get_layout(%grouped_298) : !memref_rmem_f32_1
          %68 = cute.get_shape(%lay_322) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
          %e0_323, %e1_324, %e2_325, %e3_326, %e4_327 = cute.get_leaves(%68) : !cute.shape<"((1,(4,4)),(1,1))">
          %sz_328 = cute.size(%grouped_283) <{mode = [1]}> : (!memref_gmem_f32_3) -> !cute.int_tuple<"1">
          %e0_329 = cute.get_leaves(%sz_328) : !cute.int_tuple<"1">
          %sz_330 = cute.size(%grouped_298) <{mode = [1]}> : (!memref_rmem_f32_1) -> !cute.int_tuple<"1">
          %e0_331 = cute.get_leaves(%sz_330) : !cute.int_tuple<"1">
          cute.copy(%atom, %grouped_283, %grouped_298, %grouped_313) : (!cute_nvgpu.atom.universal_copy<f32>, !memref_gmem_f32_3, !memref_rmem_f32_1, !memref_rmem_i8_1)
          %lay_332 = cute.get_layout(%src_partitioned_141) : !memref_gmem_f32_2
          %69 = cute.get_shape(%lay_332) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_333, %e1_334, %e2_335, %e3_336, %e4_337 = cute.get_leaves(%69) : !cute.shape<"((1,(4,4)),1,1)">
          %lay_338 = cute.get_layout(%rmem_150) : !memref_rmem_f32_
          %70 = cute.get_shape(%lay_338) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_339, %e1_340, %e2_341, %e3_342, %e4_343 = cute.get_leaves(%70) : !cute.shape<"((1,(4,4)),1,1)">
          %lay_344 = cute.get_layout(%src_partitioned_141) : !memref_gmem_f32_2
          %shape_345 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_346 = cute.make_layout(%shape_345) : !cute.layout<"1:0">
          %append_347 = cute.append_to_rank<2> (%lay_344, %lay_346) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">
          %view_348 = cute.make_view(%iter_142, %append_347) : !memref_gmem_f32_2
          %iter_349 = cute.get_iter(%view_348) : !memref_gmem_f32_2
          %lay_350 = cute.get_layout(%view_348) : !memref_gmem_f32_2
          %71 = cute.get_shape(%lay_350) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_351, %e1_352, %e2_353, %e3_354, %e4_355 = cute.get_leaves(%71) : !cute.shape<"((1,(4,4)),1,1)">
          %grouped_356 = cute.group_modes(%view_348) <1, 3> : (!memref_gmem_f32_2) -> !memref_gmem_f32_3
          %iter_357 = cute.get_iter(%grouped_356) : !memref_gmem_f32_3
          %iter_358 = cute.get_iter(%grouped_356) : !memref_gmem_f32_3
          %lay_359 = cute.get_layout(%rmem_150) : !memref_rmem_f32_
          %shape_360 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_361 = cute.make_layout(%shape_360) : !cute.layout<"1:0">
          %append_362 = cute.append_to_rank<2> (%lay_359, %lay_361) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
          %view_363 = cute.make_view(%iter_152, %append_362) : !memref_rmem_f32_
          %iter_364 = cute.get_iter(%view_363) : !memref_rmem_f32_
          %lay_365 = cute.get_layout(%view_363) : !memref_rmem_f32_
          %72 = cute.get_shape(%lay_365) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_366, %e1_367, %e2_368, %e3_369, %e4_370 = cute.get_leaves(%72) : !cute.shape<"((1,(4,4)),1,1)">
          %grouped_371 = cute.group_modes(%view_363) <1, 3> : (!memref_rmem_f32_) -> !memref_rmem_f32_1
          %iter_372 = cute.get_iter(%grouped_371) : !memref_rmem_f32_1
          %iter_373 = cute.get_iter(%grouped_371) : !memref_rmem_f32_1
          %lay_374 = cute.get_layout(%53) : !memref_rmem_i8_
          %shape_375 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_376 = cute.make_layout(%shape_375) : !cute.layout<"1:0">
          %append_377 = cute.append_to_rank<2> (%lay_374, %lay_376) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
          %view_378 = cute.make_view(%iter_176, %append_377) : !memref_rmem_i8_
          %iter_379 = cute.get_iter(%view_378) : !memref_rmem_i8_
          %lay_380 = cute.get_layout(%view_378) : !memref_rmem_i8_
          %73 = cute.get_shape(%lay_380) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_381, %e1_382, %e2_383, %e3_384, %e4_385 = cute.get_leaves(%73) : !cute.shape<"((1,(4,4)),1,1)">
          %grouped_386 = cute.group_modes(%view_378) <1, 3> : (!memref_rmem_i8_) -> !memref_rmem_i8_1
          %iter_387 = cute.get_iter(%grouped_386) : !memref_rmem_i8_1
          %iter_388 = cute.get_iter(%grouped_386) : !memref_rmem_i8_1
          %lay_389 = cute.get_layout(%grouped_356) : !memref_gmem_f32_3
          %74 = cute.get_shape(%lay_389) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
          %e0_390, %e1_391, %e2_392, %e3_393, %e4_394 = cute.get_leaves(%74) : !cute.shape<"((1,(4,4)),(1,1))">
          %lay_395 = cute.get_layout(%grouped_371) : !memref_rmem_f32_1
          %75 = cute.get_shape(%lay_395) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
          %e0_396, %e1_397, %e2_398, %e3_399, %e4_400 = cute.get_leaves(%75) : !cute.shape<"((1,(4,4)),(1,1))">
          %sz_401 = cute.size(%grouped_356) <{mode = [1]}> : (!memref_gmem_f32_3) -> !cute.int_tuple<"1">
          %e0_402 = cute.get_leaves(%sz_401) : !cute.int_tuple<"1">
          %sz_403 = cute.size(%grouped_371) <{mode = [1]}> : (!memref_rmem_f32_1) -> !cute.int_tuple<"1">
          %e0_404 = cute.get_leaves(%sz_403) : !cute.int_tuple<"1">
          cute.copy(%atom, %grouped_356, %grouped_371, %grouped_386) : (!cute_nvgpu.atom.universal_copy<f32>, !memref_gmem_f32_3, !memref_rmem_f32_1, !memref_rmem_i8_1)
        }
        llvm.inline_asm has_side_effects asm_dialect = att "griddepcontrol.launch_dependents;", ""  : () -> ()
      } else {
        %c0_i32_256 = arith.constant 0 : i32
        %c10_i32_257 = arith.constant 10 : i32
        %c1_i32_258 = arith.constant 1 : i32
        scf.for %arg6 = %c0_i32_256 to %c10_i32_257 step %c1_i32_258  : i32 {
          %lay_259 = cute.get_layout(%src_partitioned_141) : !memref_gmem_f32_2
          %62 = cute.get_shape(%lay_259) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_260, %e1_261, %e2_262, %e3_263, %e4_264 = cute.get_leaves(%62) : !cute.shape<"((1,(4,4)),1,1)">
          %lay_265 = cute.get_layout(%rmem_150) : !memref_rmem_f32_
          %63 = cute.get_shape(%lay_265) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_266, %e1_267, %e2_268, %e3_269, %e4_270 = cute.get_leaves(%63) : !cute.shape<"((1,(4,4)),1,1)">
          %lay_271 = cute.get_layout(%src_partitioned_141) : !memref_gmem_f32_2
          %shape_272 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_273 = cute.make_layout(%shape_272) : !cute.layout<"1:0">
          %append_274 = cute.append_to_rank<2> (%lay_271, %lay_273) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">
          %view_275 = cute.make_view(%iter_142, %append_274) : !memref_gmem_f32_2
          %iter_276 = cute.get_iter(%view_275) : !memref_gmem_f32_2
          %lay_277 = cute.get_layout(%view_275) : !memref_gmem_f32_2
          %64 = cute.get_shape(%lay_277) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_278, %e1_279, %e2_280, %e3_281, %e4_282 = cute.get_leaves(%64) : !cute.shape<"((1,(4,4)),1,1)">
          %grouped_283 = cute.group_modes(%view_275) <1, 3> : (!memref_gmem_f32_2) -> !memref_gmem_f32_3
          %iter_284 = cute.get_iter(%grouped_283) : !memref_gmem_f32_3
          %iter_285 = cute.get_iter(%grouped_283) : !memref_gmem_f32_3
          %lay_286 = cute.get_layout(%rmem_150) : !memref_rmem_f32_
          %shape_287 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_288 = cute.make_layout(%shape_287) : !cute.layout<"1:0">
          %append_289 = cute.append_to_rank<2> (%lay_286, %lay_288) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
          %view_290 = cute.make_view(%iter_152, %append_289) : !memref_rmem_f32_
          %iter_291 = cute.get_iter(%view_290) : !memref_rmem_f32_
          %lay_292 = cute.get_layout(%view_290) : !memref_rmem_f32_
          %65 = cute.get_shape(%lay_292) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_293, %e1_294, %e2_295, %e3_296, %e4_297 = cute.get_leaves(%65) : !cute.shape<"((1,(4,4)),1,1)">
          %grouped_298 = cute.group_modes(%view_290) <1, 3> : (!memref_rmem_f32_) -> !memref_rmem_f32_1
          %iter_299 = cute.get_iter(%grouped_298) : !memref_rmem_f32_1
          %iter_300 = cute.get_iter(%grouped_298) : !memref_rmem_f32_1
          %lay_301 = cute.get_layout(%53) : !memref_rmem_i8_
          %shape_302 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_303 = cute.make_layout(%shape_302) : !cute.layout<"1:0">
          %append_304 = cute.append_to_rank<2> (%lay_301, %lay_303) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
          %view_305 = cute.make_view(%iter_176, %append_304) : !memref_rmem_i8_
          %iter_306 = cute.get_iter(%view_305) : !memref_rmem_i8_
          %lay_307 = cute.get_layout(%view_305) : !memref_rmem_i8_
          %66 = cute.get_shape(%lay_307) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_308, %e1_309, %e2_310, %e3_311, %e4_312 = cute.get_leaves(%66) : !cute.shape<"((1,(4,4)),1,1)">
          %grouped_313 = cute.group_modes(%view_305) <1, 3> : (!memref_rmem_i8_) -> !memref_rmem_i8_1
          %iter_314 = cute.get_iter(%grouped_313) : !memref_rmem_i8_1
          %iter_315 = cute.get_iter(%grouped_313) : !memref_rmem_i8_1
          %lay_316 = cute.get_layout(%grouped_283) : !memref_gmem_f32_3
          %67 = cute.get_shape(%lay_316) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
          %e0_317, %e1_318, %e2_319, %e3_320, %e4_321 = cute.get_leaves(%67) : !cute.shape<"((1,(4,4)),(1,1))">
          %lay_322 = cute.get_layout(%grouped_298) : !memref_rmem_f32_1
          %68 = cute.get_shape(%lay_322) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
          %e0_323, %e1_324, %e2_325, %e3_326, %e4_327 = cute.get_leaves(%68) : !cute.shape<"((1,(4,4)),(1,1))">
          %sz_328 = cute.size(%grouped_283) <{mode = [1]}> : (!memref_gmem_f32_3) -> !cute.int_tuple<"1">
          %e0_329 = cute.get_leaves(%sz_328) : !cute.int_tuple<"1">
          %sz_330 = cute.size(%grouped_298) <{mode = [1]}> : (!memref_rmem_f32_1) -> !cute.int_tuple<"1">
          %e0_331 = cute.get_leaves(%sz_330) : !cute.int_tuple<"1">
          cute.copy(%atom, %grouped_283, %grouped_298, %grouped_313) : (!cute_nvgpu.atom.universal_copy<f32>, !memref_gmem_f32_3, !memref_rmem_f32_1, !memref_rmem_i8_1)
        }
        llvm.inline_asm has_side_effects asm_dialect = att "griddepcontrol.wait;", ""  : () -> ()
        scf.for %arg6 = %c0_i32_256 to %c10_i32_257 step %c1_i32_258  : i32 {
          %lay_259 = cute.get_layout(%src_partitioned) : !memref_gmem_f32_2
          %62 = cute.get_shape(%lay_259) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_260, %e1_261, %e2_262, %e3_263, %e4_264 = cute.get_leaves(%62) : !cute.shape<"((1,(4,4)),1,1)">
          %lay_265 = cute.get_layout(%rmem) : !memref_rmem_f32_
          %63 = cute.get_shape(%lay_265) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_266, %e1_267, %e2_268, %e3_269, %e4_270 = cute.get_leaves(%63) : !cute.shape<"((1,(4,4)),1,1)">
          %lay_271 = cute.get_layout(%src_partitioned) : !memref_gmem_f32_2
          %shape_272 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_273 = cute.make_layout(%shape_272) : !cute.layout<"1:0">
          %append_274 = cute.append_to_rank<2> (%lay_271, %lay_273) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">
          %view_275 = cute.make_view(%iter_139, %append_274) : !memref_gmem_f32_2
          %iter_276 = cute.get_iter(%view_275) : !memref_gmem_f32_2
          %lay_277 = cute.get_layout(%view_275) : !memref_gmem_f32_2
          %64 = cute.get_shape(%lay_277) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_278, %e1_279, %e2_280, %e3_281, %e4_282 = cute.get_leaves(%64) : !cute.shape<"((1,(4,4)),1,1)">
          %grouped_283 = cute.group_modes(%view_275) <1, 3> : (!memref_gmem_f32_2) -> !memref_gmem_f32_3
          %iter_284 = cute.get_iter(%grouped_283) : !memref_gmem_f32_3
          %iter_285 = cute.get_iter(%grouped_283) : !memref_gmem_f32_3
          %lay_286 = cute.get_layout(%rmem) : !memref_rmem_f32_
          %shape_287 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_288 = cute.make_layout(%shape_287) : !cute.layout<"1:0">
          %append_289 = cute.append_to_rank<2> (%lay_286, %lay_288) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
          %view_290 = cute.make_view(%iter_148, %append_289) : !memref_rmem_f32_
          %iter_291 = cute.get_iter(%view_290) : !memref_rmem_f32_
          %lay_292 = cute.get_layout(%view_290) : !memref_rmem_f32_
          %65 = cute.get_shape(%lay_292) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_293, %e1_294, %e2_295, %e3_296, %e4_297 = cute.get_leaves(%65) : !cute.shape<"((1,(4,4)),1,1)">
          %grouped_298 = cute.group_modes(%view_290) <1, 3> : (!memref_rmem_f32_) -> !memref_rmem_f32_1
          %iter_299 = cute.get_iter(%grouped_298) : !memref_rmem_f32_1
          %iter_300 = cute.get_iter(%grouped_298) : !memref_rmem_f32_1
          %lay_301 = cute.get_layout(%53) : !memref_rmem_i8_
          %shape_302 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_303 = cute.make_layout(%shape_302) : !cute.layout<"1:0">
          %append_304 = cute.append_to_rank<2> (%lay_301, %lay_303) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
          %view_305 = cute.make_view(%iter_176, %append_304) : !memref_rmem_i8_
          %iter_306 = cute.get_iter(%view_305) : !memref_rmem_i8_
          %lay_307 = cute.get_layout(%view_305) : !memref_rmem_i8_
          %66 = cute.get_shape(%lay_307) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_308, %e1_309, %e2_310, %e3_311, %e4_312 = cute.get_leaves(%66) : !cute.shape<"((1,(4,4)),1,1)">
          %grouped_313 = cute.group_modes(%view_305) <1, 3> : (!memref_rmem_i8_) -> !memref_rmem_i8_1
          %iter_314 = cute.get_iter(%grouped_313) : !memref_rmem_i8_1
          %iter_315 = cute.get_iter(%grouped_313) : !memref_rmem_i8_1
          %lay_316 = cute.get_layout(%grouped_283) : !memref_gmem_f32_3
          %67 = cute.get_shape(%lay_316) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
          %e0_317, %e1_318, %e2_319, %e3_320, %e4_321 = cute.get_leaves(%67) : !cute.shape<"((1,(4,4)),(1,1))">
          %lay_322 = cute.get_layout(%grouped_298) : !memref_rmem_f32_1
          %68 = cute.get_shape(%lay_322) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
          %e0_323, %e1_324, %e2_325, %e3_326, %e4_327 = cute.get_leaves(%68) : !cute.shape<"((1,(4,4)),(1,1))">
          %sz_328 = cute.size(%grouped_283) <{mode = [1]}> : (!memref_gmem_f32_3) -> !cute.int_tuple<"1">
          %e0_329 = cute.get_leaves(%sz_328) : !cute.int_tuple<"1">
          %sz_330 = cute.size(%grouped_298) <{mode = [1]}> : (!memref_rmem_f32_1) -> !cute.int_tuple<"1">
          %e0_331 = cute.get_leaves(%sz_330) : !cute.int_tuple<"1">
          cute.copy(%atom, %grouped_283, %grouped_298, %grouped_313) : (!cute_nvgpu.atom.universal_copy<f32>, !memref_gmem_f32_3, !memref_rmem_f32_1, !memref_rmem_i8_1)
        }
      }
      %c10_i32 = arith.constant 10 : i32
      %54:3 = scf.for %arg6 = %c0_i32 to %c10_i32 step %c1_i32 iter_args(%arg7 = %rmem, %arg8 = %rmem_150, %arg9 = %rmem_154) -> (!memref_rmem_f32_, !memref_rmem_f32_, !memref_rmem_f32_)  : i32 {
        %iter_256 = cute.get_iter(%arg7) : !memref_rmem_f32_
        %iter_257 = cute.get_iter(%arg8) : !memref_rmem_f32_
        %iter_258 = cute.get_iter(%arg9) : !memref_rmem_f32_
        %iter_259 = cute.get_iter(%arg7) : !memref_rmem_f32_
        %iter_260 = cute.get_iter(%arg8) : !memref_rmem_f32_
        %iter_261 = cute.get_iter(%arg9) : !memref_rmem_f32_
        %lay_262 = cute.get_layout(%arg7) : !memref_rmem_f32_
        %62 = cute.get_shape(%lay_262) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
        %e0_263, %e1_264, %e2_265, %e3_266, %e4_267 = cute.get_leaves(%62) : !cute.shape<"((1,(4,4)),1,1)">
        %63 = cute.memref.load_vec %arg7 : !memref_rmem_f32_
        %lay_268 = cute.get_layout(%arg8) : !memref_rmem_f32_
        %64 = cute.get_shape(%lay_268) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
        %e0_269, %e1_270, %e2_271, %e3_272, %e4_273 = cute.get_leaves(%64) : !cute.shape<"((1,(4,4)),1,1)">
        %65 = cute.memref.load_vec %arg8 : !memref_rmem_f32_
        %66 = arith.addf %63, %65 : vector<16xf32>
        %lay_274 = cute.get_layout(%arg9) : !memref_rmem_f32_
        %67 = cute.get_shape(%lay_274) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
        %e0_275, %e1_276, %e2_277, %e3_278, %e4_279 = cute.get_leaves(%67) : !cute.shape<"((1,(4,4)),1,1)">
        %int_tuple_280 = cute.make_int_tuple() : () -> !cute.int_tuple<"((1,(4,4)),1,1)">
        %sz_281 = cute.size(%int_tuple_280) : (!cute.int_tuple<"((1,(4,4)),1,1)">) -> !cute.int_tuple<"16">
        %e0_282 = cute.get_leaves(%sz_281) : !cute.int_tuple<"16">
        %int_tuple_283 = cute.make_int_tuple() : () -> !cute.int_tuple<"((1,(4,4)),1,1)">
        %sz_284 = cute.size(%int_tuple_283) : (!cute.int_tuple<"((1,(4,4)),1,1)">) -> !cute.int_tuple<"16">
        %e0_285 = cute.get_leaves(%sz_284) : !cute.int_tuple<"16">
        cute.memref.store_vec %66, %arg9 : !memref_rmem_f32_
        scf.yield %arg7, %arg8, %arg9 : !memref_rmem_f32_, !memref_rmem_f32_, !memref_rmem_f32_
      }
      %iter_177 = cute.get_iter(%54#0) : !memref_rmem_f32_
      %iter_178 = cute.get_iter(%54#1) : !memref_rmem_f32_
      %iter_179 = cute.get_iter(%54#2) : !memref_rmem_f32_
      %iter_180 = cute.get_iter(%54#0) : !memref_rmem_f32_
      %iter_181 = cute.get_iter(%54#0) : !memref_rmem_f32_
      %iter_182 = cute.get_iter(%54#1) : !memref_rmem_f32_
      %iter_183 = cute.get_iter(%54#1) : !memref_rmem_f32_
      %iter_184 = cute.get_iter(%54#2) : !memref_rmem_f32_
      %iter_185 = cute.get_iter(%54#2) : !memref_rmem_f32_
      %lay_186 = cute.get_layout(%54#2) : !memref_rmem_f32_
      %55 = cute.get_shape(%lay_186) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_187, %e1_188, %e2_189, %e3_190, %e4_191 = cute.get_leaves(%55) : !cute.shape<"((1,(4,4)),1,1)">
      %lay_192 = cute.get_layout(%src_partitioned_144) : !memref_gmem_f32_2
      %56 = cute.get_shape(%lay_192) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_193, %e1_194, %e2_195, %e3_196, %e4_197 = cute.get_leaves(%56) : !cute.shape<"((1,(4,4)),1,1)">
      %lay_198 = cute.get_layout(%54#2) : !memref_rmem_f32_
      %shape_199 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_200 = cute.make_layout(%shape_199) : !cute.layout<"1:0">
      %append = cute.append_to_rank<2> (%lay_198, %lay_200) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
      %view = cute.make_view(%iter_185, %append) : !memref_rmem_f32_
      %iter_201 = cute.get_iter(%view) : !memref_rmem_f32_
      %lay_202 = cute.get_layout(%view) : !memref_rmem_f32_
      %57 = cute.get_shape(%lay_202) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_203, %e1_204, %e2_205, %e3_206, %e4_207 = cute.get_leaves(%57) : !cute.shape<"((1,(4,4)),1,1)">
      %grouped = cute.group_modes(%view) <1, 3> : (!memref_rmem_f32_) -> !memref_rmem_f32_1
      %iter_208 = cute.get_iter(%grouped) : !memref_rmem_f32_1
      %iter_209 = cute.get_iter(%grouped) : !memref_rmem_f32_1
      %lay_210 = cute.get_layout(%src_partitioned_144) : !memref_gmem_f32_2
      %shape_211 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_212 = cute.make_layout(%shape_211) : !cute.layout<"1:0">
      %append_213 = cute.append_to_rank<2> (%lay_210, %lay_212) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">
      %view_214 = cute.make_view(%iter_145, %append_213) : !memref_gmem_f32_2
      %iter_215 = cute.get_iter(%view_214) : !memref_gmem_f32_2
      %lay_216 = cute.get_layout(%view_214) : !memref_gmem_f32_2
      %58 = cute.get_shape(%lay_216) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_217, %e1_218, %e2_219, %e3_220, %e4_221 = cute.get_leaves(%58) : !cute.shape<"((1,(4,4)),1,1)">
      %grouped_222 = cute.group_modes(%view_214) <1, 3> : (!memref_gmem_f32_2) -> !memref_gmem_f32_3
      %iter_223 = cute.get_iter(%grouped_222) : !memref_gmem_f32_3
      %iter_224 = cute.get_iter(%grouped_222) : !memref_gmem_f32_3
      %lay_225 = cute.get_layout(%53) : !memref_rmem_i8_
      %shape_226 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_227 = cute.make_layout(%shape_226) : !cute.layout<"1:0">
      %append_228 = cute.append_to_rank<2> (%lay_225, %lay_227) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
      %view_229 = cute.make_view(%iter_176, %append_228) : !memref_rmem_i8_
      %iter_230 = cute.get_iter(%view_229) : !memref_rmem_i8_
      %lay_231 = cute.get_layout(%view_229) : !memref_rmem_i8_
      %59 = cute.get_shape(%lay_231) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_232, %e1_233, %e2_234, %e3_235, %e4_236 = cute.get_leaves(%59) : !cute.shape<"((1,(4,4)),1,1)">
      %grouped_237 = cute.group_modes(%view_229) <1, 3> : (!memref_rmem_i8_) -> !memref_rmem_i8_1
      %iter_238 = cute.get_iter(%grouped_237) : !memref_rmem_i8_1
      %iter_239 = cute.get_iter(%grouped_237) : !memref_rmem_i8_1
      %lay_240 = cute.get_layout(%grouped) : !memref_rmem_f32_1
      %60 = cute.get_shape(%lay_240) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
      %e0_241, %e1_242, %e2_243, %e3_244, %e4_245 = cute.get_leaves(%60) : !cute.shape<"((1,(4,4)),(1,1))">
      %lay_246 = cute.get_layout(%grouped_222) : !memref_gmem_f32_3
      %61 = cute.get_shape(%lay_246) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
      %e0_247, %e1_248, %e2_249, %e3_250, %e4_251 = cute.get_leaves(%61) : !cute.shape<"((1,(4,4)),(1,1))">
      %sz_252 = cute.size(%grouped) <{mode = [1]}> : (!memref_rmem_f32_1) -> !cute.int_tuple<"1">
      %e0_253 = cute.get_leaves(%sz_252) : !cute.int_tuple<"1">
      %sz_254 = cute.size(%grouped_222) <{mode = [1]}> : (!memref_gmem_f32_3) -> !cute.int_tuple<"1">
      %e0_255 = cute.get_leaves(%sz_254) : !cute.int_tuple<"1">
      cute.copy(%atom_81, %grouped, %grouped_222, %grouped_237) : (!cute_nvgpu.atom.universal_copy<f32>, !memref_rmem_f32_1, !memref_gmem_f32_3, !memref_rmem_i8_1)
      return
    }
  }
  func.func @cutlass_elementwise_add_Tensorgmem_o_i641_Tensorgmem_o_i641_Tensorgmem_o_i641_CUstream_False_False(%arg0: !memref_gmem_f32_4, %arg1: !memref_gmem_f32_4, %arg2: !memref_gmem_f32_4, %arg3: !cuda.stream) -> i32 attributes {llvm.emit_c_interface} {
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
    %tile = cute.make_tile() : () -> !cute.tile<"[16:1;128:1]">
    %div = cute.zipped_divide(%arg0, %tile) : !memref_gmem_f32_4, !cute.tile<"[16:1;128:1]">
    %iter_39 = cute.get_iter(%div) : !memref_gmem_f32_
    %iter_40 = cute.get_iter(%div) : !memref_gmem_f32_
    %tile_41 = cute.make_tile() : () -> !cute.tile<"[16:1;128:1]">
    %div_42 = cute.zipped_divide(%arg1, %tile_41) : !memref_gmem_f32_4, !cute.tile<"[16:1;128:1]">
    %iter_43 = cute.get_iter(%div_42) : !memref_gmem_f32_
    %iter_44 = cute.get_iter(%div_42) : !memref_gmem_f32_
    %tile_45 = cute.make_tile() : () -> !cute.tile<"[16:1;128:1]">
    %div_46 = cute.zipped_divide(%arg2, %tile_45) : !memref_gmem_f32_4, !cute.tile<"[16:1;128:1]">
    %iter_47 = cute.get_iter(%div_46) : !memref_gmem_f32_
    %iter_48 = cute.get_iter(%div_46) : !memref_gmem_f32_
    %lay_49 = cute.get_layout(%arg2) : !memref_gmem_f32_4
    %17 = cute.get_shape(%lay_49) : (!cute.layout<"(?,?):(?{i64},1)">) -> !cute.shape<"(?,?)">
    %e0_50, %e1_51 = cute.get_leaves(%17) : !cute.shape<"(?,?)">
    %itup_52 = cute.to_int_tuple(%e0_50) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %18 = cute.get_scalars(%itup_52) : !cute.int_tuple<"?">
    %itup_53 = cute.to_int_tuple(%e1_51) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %19 = cute.get_scalars(%itup_53) : !cute.int_tuple<"?">
    %shape_54 = cute.make_shape(%itup_52, %itup_53) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.shape<"(?,?)">
    %20 = cute.make_identity_tensor(%shape_54) : !cute.coord_tensor<"(0,0)", "(?,?):(1@0,1@1)">
    %iter_55 = cute.get_iter(%20) : !cute.coord_tensor<"(0,0)", "(?,?):(1@0,1@1)">
    %e0_56, %e1_57 = cute.get_leaves(%iter_55) : !cute.int_tuple<"(0,0)">
    %tile_58 = cute.make_tile() : () -> !cute.tile<"[16:1;128:1]">
    %div_59 = cute.zipped_divide(%20, %tile_58) : !cute.coord_tensor<"(0,0)", "(?,?):(1@0,1@1)">, !cute.tile<"[16:1;128:1]">
    %iter_60 = cute.get_iter(%div_59) : !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
    %e0_61, %e1_62 = cute.get_leaves(%iter_60) : !cute.int_tuple<"(0,0)">
    %iter_63 = cute.get_iter(%div_59) : !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
    %e0_64, %e1_65 = cute.get_leaves(%iter_63) : !cute.int_tuple<"(0,0)">
    %sz_66 = cute.size(%div_46) <{mode = [1]}> : (!memref_gmem_f32_) -> !cute.int_tuple<"?">
    %e0_67 = cute.get_leaves(%sz_66) : !cute.int_tuple<"?">
    %21 = cute.get_scalars(%e0_67) : !cute.int_tuple<"?">
    %sz_68 = cute.size(%15) <{mode = [0]}> : (!cute.layout<"((32,4),(4,4)):((64,4),(16,1))">) -> !cute.int_tuple<"128">
    %e0_69 = cute.get_leaves(%sz_68) : !cute.int_tuple<"128">
    %lay_70 = cute.get_layout(%div) : !memref_gmem_f32_
    %22 = cute.get_shape(%lay_70) : (!cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.shape<"((16,128),(?,?))">
    %e0_71, %e1_72, %e2_73, %e3_74 = cute.get_leaves(%22) : !cute.shape<"((16,128),(?,?))">
    %itup_75 = cute.to_int_tuple(%e2_73) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %23 = cute.get_scalars(%itup_75) : !cute.int_tuple<"?">
    %itup_76 = cute.to_int_tuple(%e3_74) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %24 = cute.get_scalars(%itup_76) : !cute.int_tuple<"?">
    %25 = cute.get_stride(%lay_70) : (!cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.stride<"((?{i64},1),(?{i64 div=16},128))">
    %e0_77, %e1_78, %e2_79, %e3_80 = cute.get_leaves(%25) : !cute.stride<"((?{i64},1),(?{i64 div=16},128))">
    %itup_81 = cute.to_int_tuple(%e0_77) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
    %26 = cute.get_scalars(%itup_81) : !cute.int_tuple<"?{i64}">
    %itup_82 = cute.to_int_tuple(%e2_79) : !cute.stride<"?{i64 div=16}"> to !cute.int_tuple<"?{i64 div=16}">
    %27 = cute.get_scalars(%itup_82) : !cute.int_tuple<"?{i64 div=16}">
    %lay_83 = cute.get_layout(%div_42) : !memref_gmem_f32_
    %28 = cute.get_shape(%lay_83) : (!cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.shape<"((16,128),(?,?))">
    %e0_84, %e1_85, %e2_86, %e3_87 = cute.get_leaves(%28) : !cute.shape<"((16,128),(?,?))">
    %itup_88 = cute.to_int_tuple(%e2_86) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %29 = cute.get_scalars(%itup_88) : !cute.int_tuple<"?">
    %itup_89 = cute.to_int_tuple(%e3_87) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %30 = cute.get_scalars(%itup_89) : !cute.int_tuple<"?">
    %31 = cute.get_stride(%lay_83) : (!cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.stride<"((?{i64},1),(?{i64 div=16},128))">
    %e0_90, %e1_91, %e2_92, %e3_93 = cute.get_leaves(%31) : !cute.stride<"((?{i64},1),(?{i64 div=16},128))">
    %itup_94 = cute.to_int_tuple(%e0_90) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
    %32 = cute.get_scalars(%itup_94) : !cute.int_tuple<"?{i64}">
    %itup_95 = cute.to_int_tuple(%e2_92) : !cute.stride<"?{i64 div=16}"> to !cute.int_tuple<"?{i64 div=16}">
    %33 = cute.get_scalars(%itup_95) : !cute.int_tuple<"?{i64 div=16}">
    %lay_96 = cute.get_layout(%div_46) : !memref_gmem_f32_
    %34 = cute.get_shape(%lay_96) : (!cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.shape<"((16,128),(?,?))">
    %e0_97, %e1_98, %e2_99, %e3_100 = cute.get_leaves(%34) : !cute.shape<"((16,128),(?,?))">
    %itup_101 = cute.to_int_tuple(%e2_99) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %35 = cute.get_scalars(%itup_101) : !cute.int_tuple<"?">
    %itup_102 = cute.to_int_tuple(%e3_100) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %36 = cute.get_scalars(%itup_102) : !cute.int_tuple<"?">
    %37 = cute.get_stride(%lay_96) : (!cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.stride<"((?{i64},1),(?{i64 div=16},128))">
    %e0_103, %e1_104, %e2_105, %e3_106 = cute.get_leaves(%37) : !cute.stride<"((?{i64},1),(?{i64 div=16},128))">
    %itup_107 = cute.to_int_tuple(%e0_103) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
    %38 = cute.get_scalars(%itup_107) : !cute.int_tuple<"?{i64}">
    %itup_108 = cute.to_int_tuple(%e2_105) : !cute.stride<"?{i64 div=16}"> to !cute.int_tuple<"?{i64 div=16}">
    %39 = cute.get_scalars(%itup_108) : !cute.int_tuple<"?{i64 div=16}">
    %lay_109 = cute.get_layout(%div_59) : !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
    %40 = cute.get_shape(%lay_109) : (!cute.layout<"((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">) -> !cute.shape<"((16,128),(?,?))">
    %e0_110, %e1_111, %e2_112, %e3_113 = cute.get_leaves(%40) : !cute.shape<"((16,128),(?,?))">
    %itup_114 = cute.to_int_tuple(%e2_112) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %41 = cute.get_scalars(%itup_114) : !cute.int_tuple<"?">
    %itup_115 = cute.to_int_tuple(%e3_113) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %42 = cute.get_scalars(%itup_115) : !cute.int_tuple<"?">
    %43 = cute.get_stride(%lay_109) : (!cute.layout<"((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">) -> !cute.stride<"((1@0,1@1),(16@0,128@1))">
    %e0_116, %e1_117, %e2_118, %e3_119 = cute.get_leaves(%43) : !cute.stride<"((1@0,1@1),(16@0,128@1))">
    %44 = cute.get_shape(%lay_25) : (!cute.layout<"(4,32):(32,1)">) -> !cute.shape<"(4,32)">
    %e0_120, %e1_121 = cute.get_leaves(%44) : !cute.shape<"(4,32)">
    %45 = cute.get_stride(%lay_25) : (!cute.layout<"(4,32):(32,1)">) -> !cute.stride<"(32,1)">
    %e0_122, %e1_123 = cute.get_leaves(%45) : !cute.stride<"(32,1)">
    %46 = cute.get_shape(%lay_28) : (!cute.layout<"(4,4):(4,1)">) -> !cute.shape<"(4,4)">
    %e0_124, %e1_125 = cute.get_leaves(%46) : !cute.shape<"(4,4)">
    %47 = cute.get_stride(%lay_28) : (!cute.layout<"(4,4):(4,1)">) -> !cute.stride<"(4,1)">
    %e0_126, %e1_127 = cute.get_leaves(%47) : !cute.stride<"(4,1)">
    %c0_i32 = arith.constant 0 : i32
    %48 = arith.extsi %c0_i32 : i32 to i64
    %c128_i32 = arith.constant 128 : i32
    %c1_i32 = arith.constant 1 : i32
    %49 = cuda.launch_cfg.create<max_attrs = 2 : i32> (blockDim = (%c128_i32, %c1_i32, %c1_i32), dynamicSmemBytes = %48, gridDim = (%21, %c1_i32, %c1_i32), stream = %arg3) : i32, i32, i32, i64, i32, i32, i32, !cuda.stream -> !cuda.launch_cfg<max_attrs = 2>
    %50 = cuda.launch_ex @kernels::@kernel_cutlass_elementwise_add_kernel_tensorptrf32gmemo161281i64div16128_tensorptrf32gmemo161281i64div16128_tensorptrf32gmemo161281i64div16128_tensor00o1612810111601281___False_0<%49> (%div, %div_42, %div_46, %div_59, %18, %19) : !cuda.launch_cfg<max_attrs = 2>, (!memref_gmem_f32_, !memref_gmem_f32_, !memref_gmem_f32_, !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">, i32, i32) -> !cuda.result
    %51 = cuda.cast %50 : !cuda.result -> i32
    cuda.return_if_error %51 : i32
    %c0_i32_128 = arith.constant 0 : i32
    return %c0_i32_128 : i32
  }
}
