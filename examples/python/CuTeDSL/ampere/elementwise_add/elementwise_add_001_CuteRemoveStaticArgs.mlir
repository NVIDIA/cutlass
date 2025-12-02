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
    func.func public @kernel_cutlass_elementwise_add_kernel_tensorptrf32gmemo161281div16128_tensorptrf32gmemo161281div16128_tensorptrf32gmemo161281div16128_tensor00o1612810111601281___0(%arg0: !memref_gmem_f32_, %arg1: !memref_gmem_f32_, %arg2: !memref_gmem_f32_, %arg3: !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">, %arg4: i32, %arg5: i32) attributes {cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} {
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
      %coord_64 = cute.make_coord(%31) : (i32) -> !cute.coord<"((_,_),?)">
      %slice_65 = cute.slice(%arg1, %coord_64) : !memref_gmem_f32_, !cute.coord<"((_,_),?)">
      %iter_66 = cute.get_iter(%slice_65) : !memref_gmem_f32_1
      %coord_67 = cute.make_coord(%31) : (i32) -> !cute.coord<"((_,_),?)">
      %slice_68 = cute.slice(%arg2, %coord_67) : !memref_gmem_f32_, !cute.coord<"((_,_),?)">
      %iter_69 = cute.get_iter(%slice_68) : !memref_gmem_f32_1
      %coord_70 = cute.make_coord(%31) : (i32) -> !cute.coord<"((_,_),?)">
      %slice_71 = cute.slice(%arg3, %coord_70) : !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">, !cute.coord<"((_,_),?)">
      %iter_72 = cute.get_iter(%slice_71) : !cute.coord_tensor<"(?{div=16},?{div=128})", "(16,128):(1@0,1@1)">
      %e0_73, %e1_74 = cute.get_leaves(%iter_72) : !cute.int_tuple<"(?{div=16},?{div=128})">
      %34 = cute.get_scalars(%e0_73) : !cute.int_tuple<"?{div=16}">
      %35 = cute.get_scalars(%e1_74) : !cute.int_tuple<"?{div=128}">
      %atom = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<f32>
      %atom_75 = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<f32>
      %prod = cute.raked_product(%0, %1) : (!cute.layout<"(4,32):(32,1)">, !cute.layout<"(4,4):(4,1)">) -> !cute.layout<"((4,4),(4,32)):((512,32),(128,1))">
      %sz = cute.size(%0) : (!cute.layout<"(4,32):(32,1)">) -> !cute.int_tuple<"128">
      %e0_76 = cute.get_leaves(%sz) : !cute.int_tuple<"128">
      %sz_77 = cute.size(%1) : (!cute.layout<"(4,4):(4,1)">) -> !cute.int_tuple<"16">
      %e0_78 = cute.get_leaves(%sz_77) : !cute.int_tuple<"16">
      %shape = cute.make_shape() : () -> !cute.shape<"(128,16)">
      %lay_79 = cute.make_layout(%shape) : !cute.layout<"(128,16):(1,128)">
      %rinv = cute.right_inverse(%prod) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.layout<"(32,16,4):(64,4,1)">
      %36 = cute.composition(%rinv, %lay_79) : (!cute.layout<"(32,16,4):(64,4,1)">, !cute.layout<"(128,16):(1,128)">) -> !cute.layout<"((32,4),(4,4)):((64,4),(16,1))">
      %37 = cute.get_shape(%prod) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.shape<"((4,4),(4,32))">
      %e0_80, %e1_81, %e2_82, %e3_83 = cute.get_leaves(%37) : !cute.shape<"((4,4),(4,32))">
      %int_tuple = cute.make_int_tuple() : () -> !cute.int_tuple<"((4,4),(4,32))">
      %res = cute.tuple.product_each(%int_tuple) : (!cute.int_tuple<"((4,4),(4,32))">) -> !cute.int_tuple<"(16,128)">
      %e0_84, %e1_85 = cute.get_leaves(%res) : !cute.int_tuple<"(16,128)">
      %int_tuple_86 = cute.make_int_tuple() : () -> !cute.int_tuple<"(16,128)">
      %res_87 = cute.tuple.product_each(%int_tuple_86) : (!cute.int_tuple<"(16,128)">) -> !cute.int_tuple<"(16,128)">
      %e0_88, %e1_89 = cute.get_leaves(%res_87) : !cute.int_tuple<"(16,128)">
      %tile = cute.make_tile() : () -> !cute.tile<"[16:1;128:1]">
      %38 = cute.make_tiled_copy(%atom) : !copy_simt
      %prod_90 = cute.raked_product(%0, %1) : (!cute.layout<"(4,32):(32,1)">, !cute.layout<"(4,4):(4,1)">) -> !cute.layout<"((4,4),(4,32)):((512,32),(128,1))">
      %sz_91 = cute.size(%0) : (!cute.layout<"(4,32):(32,1)">) -> !cute.int_tuple<"128">
      %e0_92 = cute.get_leaves(%sz_91) : !cute.int_tuple<"128">
      %sz_93 = cute.size(%1) : (!cute.layout<"(4,4):(4,1)">) -> !cute.int_tuple<"16">
      %e0_94 = cute.get_leaves(%sz_93) : !cute.int_tuple<"16">
      %shape_95 = cute.make_shape() : () -> !cute.shape<"(128,16)">
      %lay_96 = cute.make_layout(%shape_95) : !cute.layout<"(128,16):(1,128)">
      %rinv_97 = cute.right_inverse(%prod_90) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.layout<"(32,16,4):(64,4,1)">
      %39 = cute.composition(%rinv_97, %lay_96) : (!cute.layout<"(32,16,4):(64,4,1)">, !cute.layout<"(128,16):(1,128)">) -> !cute.layout<"((32,4),(4,4)):((64,4),(16,1))">
      %40 = cute.get_shape(%prod_90) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.shape<"((4,4),(4,32))">
      %e0_98, %e1_99, %e2_100, %e3_101 = cute.get_leaves(%40) : !cute.shape<"((4,4),(4,32))">
      %int_tuple_102 = cute.make_int_tuple() : () -> !cute.int_tuple<"((4,4),(4,32))">
      %res_103 = cute.tuple.product_each(%int_tuple_102) : (!cute.int_tuple<"((4,4),(4,32))">) -> !cute.int_tuple<"(16,128)">
      %e0_104, %e1_105 = cute.get_leaves(%res_103) : !cute.int_tuple<"(16,128)">
      %int_tuple_106 = cute.make_int_tuple() : () -> !cute.int_tuple<"(16,128)">
      %res_107 = cute.tuple.product_each(%int_tuple_106) : (!cute.int_tuple<"(16,128)">) -> !cute.int_tuple<"(16,128)">
      %e0_108, %e1_109 = cute.get_leaves(%res_107) : !cute.int_tuple<"(16,128)">
      %tile_110 = cute.make_tile() : () -> !cute.tile<"[16:1;128:1]">
      %41 = cute.make_tiled_copy(%atom) : !copy_simt
      %prod_111 = cute.raked_product(%0, %1) : (!cute.layout<"(4,32):(32,1)">, !cute.layout<"(4,4):(4,1)">) -> !cute.layout<"((4,4),(4,32)):((512,32),(128,1))">
      %sz_112 = cute.size(%0) : (!cute.layout<"(4,32):(32,1)">) -> !cute.int_tuple<"128">
      %e0_113 = cute.get_leaves(%sz_112) : !cute.int_tuple<"128">
      %sz_114 = cute.size(%1) : (!cute.layout<"(4,4):(4,1)">) -> !cute.int_tuple<"16">
      %e0_115 = cute.get_leaves(%sz_114) : !cute.int_tuple<"16">
      %shape_116 = cute.make_shape() : () -> !cute.shape<"(128,16)">
      %lay_117 = cute.make_layout(%shape_116) : !cute.layout<"(128,16):(1,128)">
      %rinv_118 = cute.right_inverse(%prod_111) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.layout<"(32,16,4):(64,4,1)">
      %42 = cute.composition(%rinv_118, %lay_117) : (!cute.layout<"(32,16,4):(64,4,1)">, !cute.layout<"(128,16):(1,128)">) -> !cute.layout<"((32,4),(4,4)):((64,4),(16,1))">
      %43 = cute.get_shape(%prod_111) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.shape<"((4,4),(4,32))">
      %e0_119, %e1_120, %e2_121, %e3_122 = cute.get_leaves(%43) : !cute.shape<"((4,4),(4,32))">
      %int_tuple_123 = cute.make_int_tuple() : () -> !cute.int_tuple<"((4,4),(4,32))">
      %res_124 = cute.tuple.product_each(%int_tuple_123) : (!cute.int_tuple<"((4,4),(4,32))">) -> !cute.int_tuple<"(16,128)">
      %e0_125, %e1_126 = cute.get_leaves(%res_124) : !cute.int_tuple<"(16,128)">
      %int_tuple_127 = cute.make_int_tuple() : () -> !cute.int_tuple<"(16,128)">
      %res_128 = cute.tuple.product_each(%int_tuple_127) : (!cute.int_tuple<"(16,128)">) -> !cute.int_tuple<"(16,128)">
      %e0_129, %e1_130 = cute.get_leaves(%res_128) : !cute.int_tuple<"(16,128)">
      %tile_131 = cute.make_tile() : () -> !cute.tile<"[16:1;128:1]">
      %44 = cute.make_tiled_copy(%atom_75) : !copy_simt
      %coord_132 = cute.make_coord(%28) : (i32) -> !cute.coord<"?">
      %src_partitioned = cute.tiled.copy.partition_S(%38, %slice, %coord_132) : (!copy_simt, !memref_gmem_f32_1, !cute.coord<"?">) -> !memref_gmem_f32_2
      %iter_133 = cute.get_iter(%src_partitioned) : !memref_gmem_f32_2
      %coord_134 = cute.make_coord(%28) : (i32) -> !cute.coord<"?">
      %src_partitioned_135 = cute.tiled.copy.partition_S(%41, %slice_65, %coord_134) : (!copy_simt, !memref_gmem_f32_1, !cute.coord<"?">) -> !memref_gmem_f32_2
      %iter_136 = cute.get_iter(%src_partitioned_135) : !memref_gmem_f32_2
      %coord_137 = cute.make_coord(%28) : (i32) -> !cute.coord<"?">
      %src_partitioned_138 = cute.tiled.copy.partition_S(%44, %slice_68, %coord_137) : (!copy_simt, !memref_gmem_f32_1, !cute.coord<"?">) -> !memref_gmem_f32_2
      %iter_139 = cute.get_iter(%src_partitioned_138) : !memref_gmem_f32_2
      %lay_140 = cute.get_layout(%src_partitioned) : !memref_gmem_f32_2
      %45 = cute.make_layout_like(%lay_140) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)"> to !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %rmem = cute.memref.alloca(%45) : !memref_rmem_f32_
      %iter_141 = cute.get_iter(%rmem) : !memref_rmem_f32_
      %iter_142 = cute.get_iter(%rmem) : !memref_rmem_f32_
      %lay_143 = cute.get_layout(%src_partitioned_135) : !memref_gmem_f32_2
      %46 = cute.make_layout_like(%lay_143) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)"> to !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %rmem_144 = cute.memref.alloca(%46) : !memref_rmem_f32_
      %iter_145 = cute.get_iter(%rmem_144) : !memref_rmem_f32_
      %iter_146 = cute.get_iter(%rmem_144) : !memref_rmem_f32_
      %lay_147 = cute.get_layout(%src_partitioned_138) : !memref_gmem_f32_2
      %47 = cute.make_layout_like(%lay_147) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)"> to !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %rmem_148 = cute.memref.alloca(%47) : !memref_rmem_f32_
      %iter_149 = cute.get_iter(%rmem_148) : !memref_rmem_f32_
      %iter_150 = cute.get_iter(%rmem_148) : !memref_rmem_f32_
      %coord_151 = cute.make_coord(%28) : (i32) -> !cute.coord<"?">
      %src_partitioned_152 = cute.tiled.copy.partition_S(%44, %slice_71, %coord_151) : (!copy_simt, !cute.coord_tensor<"(?{div=16},?{div=128})", "(16,128):(1@0,1@1)">, !cute.coord<"?">) -> !cute.coord_tensor<"(?{div=4},?{div=4})", "((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">
      %iter_153 = cute.get_iter(%src_partitioned_152) : !cute.coord_tensor<"(?{div=4},?{div=4})", "((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">
      %e0_154, %e1_155 = cute.get_leaves(%iter_153) : !cute.int_tuple<"(?{div=4},?{div=4})">
      %48 = cute.get_scalars(%e0_154) : !cute.int_tuple<"?{div=4}">
      %49 = cute.get_scalars(%e1_155) : !cute.int_tuple<"?{div=4}">
      %lay_156 = cute.get_layout(%src_partitioned_152) : !cute.coord_tensor<"(?{div=4},?{div=4})", "((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">
      %50 = cute.get_shape(%lay_156) : (!cute.layout<"((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_157, %e1_158, %e2_159, %e3_160, %e4 = cute.get_leaves(%50) : !cute.shape<"((1,(4,4)),1,1)">
      %shape_161 = cute.make_shape() : () -> !cute.shape<"((1,(4,4)),1,1)">
      %lay_162 = cute.make_layout(%shape_161) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %rmem_163 = cute.memref.alloca(%lay_162) : !memref_rmem_i8_
      %iter_164 = cute.get_iter(%rmem_163) : !memref_rmem_i8_
      %iter_165 = cute.get_iter(%rmem_163) : !memref_rmem_i8_
      %sz_166 = cute.size(%rmem_163) : (!memref_rmem_i8_) -> !cute.int_tuple<"16">
      %e0_167 = cute.get_leaves(%sz_166) : !cute.int_tuple<"16">
      %lay_168 = cute.get_layout(%rmem_163) : !memref_rmem_i8_
      %51 = cute.get_shape(%lay_168) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_169, %e1_170, %e2_171, %e3_172, %e4_173 = cute.get_leaves(%51) : !cute.shape<"((1,(4,4)),1,1)">
      %52 = cute.get_stride(%lay_168) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.stride<"((0,(1,4)),0,0)">
      %e0_174, %e1_175, %e2_176, %e3_177, %e4_178 = cute.get_leaves(%52) : !cute.stride<"((0,(1,4)),0,0)">
      %c0_i32 = arith.constant 0 : i32
      %c16_i32 = arith.constant 16 : i32
      %c1_i32 = arith.constant 1 : i32
      %53 = scf.for %arg6 = %c0_i32 to %c16_i32 step %c1_i32 iter_args(%arg7 = %rmem_163) -> (!memref_rmem_i8_)  : i32 {
        %iter_415 = cute.get_iter(%arg7) : !memref_rmem_i8_
        %lay_416 = cute.get_layout(%arg7) : !memref_rmem_i8_
        %80 = cute.get_shape(%lay_416) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
        %e0_417, %e1_418, %e2_419, %e3_420, %e4_421 = cute.get_leaves(%80) : !cute.shape<"((1,(4,4)),1,1)">
        %81 = cute.get_stride(%lay_416) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.stride<"((0,(1,4)),0,0)">
        %e0_422, %e1_423, %e2_424, %e3_425, %e4_426 = cute.get_leaves(%81) : !cute.stride<"((0,(1,4)),0,0)">
        %iter_427 = cute.get_iter(%arg7) : !memref_rmem_i8_
        %coord_428 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"?">
        %slice_429 = cute.slice(%src_partitioned_152, %coord_428) : !cute.coord_tensor<"(?{div=4},?{div=4})", "((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">, !cute.coord<"?">
        %iter_430 = cute.get_iter(%slice_429) : !cute.coord_tensor<"(?,?)", "():()">
        %e0_431, %e1_432 = cute.get_leaves(%iter_430) : !cute.int_tuple<"(?,?)">
        %82 = cute.get_scalars(%e0_431) : !cute.int_tuple<"?">
        %83 = cute.get_scalars(%e1_432) : !cute.int_tuple<"?">
        %iter_433 = cute.get_iter(%slice_429) : !cute.coord_tensor<"(?,?)", "():()">
        %e0_434, %e1_435 = cute.get_leaves(%iter_433) : !cute.int_tuple<"(?,?)">
        %84 = cute.get_scalars(%e0_434) : !cute.int_tuple<"?">
        %85 = cute.get_scalars(%e1_435) : !cute.int_tuple<"?">
        %iter_436 = cute.get_iter(%slice_429) : !cute.coord_tensor<"(?,?)", "():()">
        %e0_437, %e1_438 = cute.get_leaves(%iter_436) : !cute.int_tuple<"(?,?)">
        %86 = cute.get_scalars(%e0_437) : !cute.int_tuple<"?">
        %87 = cute.get_scalars(%e1_438) : !cute.int_tuple<"?">
        %coord_439 = cute.make_coord(%e0_437, %e1_438) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
        %coord_440 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
        %88 = cute.elem_less(%coord_439, %coord_440) : !cute.coord<"(?,?)">, !cute.coord<"(?,?)">
        %89 = arith.extui %88 : i1 to i8
        %coord_441 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"?">
        cute.memref.store(%arg7, %coord_441, %89) : (!memref_rmem_i8_, !cute.coord<"?">, i8) -> ()
        %lay_442 = cute.get_layout(%arg7) : !memref_rmem_i8_
        %90 = cute.get_shape(%lay_442) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
        %e0_443, %e1_444, %e2_445, %e3_446, %e4_447 = cute.get_leaves(%90) : !cute.shape<"((1,(4,4)),1,1)">
        %91 = cute.get_stride(%lay_442) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.stride<"((0,(1,4)),0,0)">
        %e0_448, %e1_449, %e2_450, %e3_451, %e4_452 = cute.get_leaves(%91) : !cute.stride<"((0,(1,4)),0,0)">
        scf.yield %arg7 : !memref_rmem_i8_
      }
      %iter_179 = cute.get_iter(%53) : !memref_rmem_i8_
      %lay_180 = cute.get_layout(%53) : !memref_rmem_i8_
      %54 = cute.get_shape(%lay_180) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_181, %e1_182, %e2_183, %e3_184, %e4_185 = cute.get_leaves(%54) : !cute.shape<"((1,(4,4)),1,1)">
      %55 = cute.get_stride(%lay_180) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.stride<"((0,(1,4)),0,0)">
      %e0_186, %e1_187, %e2_188, %e3_189, %e4_190 = cute.get_leaves(%55) : !cute.stride<"((0,(1,4)),0,0)">
      %iter_191 = cute.get_iter(%53) : !memref_rmem_i8_
      %iter_192 = cute.get_iter(%53) : !memref_rmem_i8_
      %lay_193 = cute.get_layout(%src_partitioned) : !memref_gmem_f32_2
      %56 = cute.get_shape(%lay_193) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_194, %e1_195, %e2_196, %e3_197, %e4_198 = cute.get_leaves(%56) : !cute.shape<"((1,(4,4)),1,1)">
      %lay_199 = cute.get_layout(%rmem) : !memref_rmem_f32_
      %57 = cute.get_shape(%lay_199) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_200, %e1_201, %e2_202, %e3_203, %e4_204 = cute.get_leaves(%57) : !cute.shape<"((1,(4,4)),1,1)">
      %lay_205 = cute.get_layout(%src_partitioned) : !memref_gmem_f32_2
      %shape_206 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_207 = cute.make_layout(%shape_206) : !cute.layout<"1:0">
      %append = cute.append_to_rank<2> (%lay_205, %lay_207) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">
      %view = cute.make_view(%iter_133, %append) : !memref_gmem_f32_2
      %iter_208 = cute.get_iter(%view) : !memref_gmem_f32_2
      %lay_209 = cute.get_layout(%view) : !memref_gmem_f32_2
      %58 = cute.get_shape(%lay_209) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_210, %e1_211, %e2_212, %e3_213, %e4_214 = cute.get_leaves(%58) : !cute.shape<"((1,(4,4)),1,1)">
      %grouped = cute.group_modes(%view) <1, 3> : (!memref_gmem_f32_2) -> !memref_gmem_f32_3
      %iter_215 = cute.get_iter(%grouped) : !memref_gmem_f32_3
      %iter_216 = cute.get_iter(%grouped) : !memref_gmem_f32_3
      %lay_217 = cute.get_layout(%rmem) : !memref_rmem_f32_
      %shape_218 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_219 = cute.make_layout(%shape_218) : !cute.layout<"1:0">
      %append_220 = cute.append_to_rank<2> (%lay_217, %lay_219) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
      %view_221 = cute.make_view(%iter_142, %append_220) : !memref_rmem_f32_
      %iter_222 = cute.get_iter(%view_221) : !memref_rmem_f32_
      %lay_223 = cute.get_layout(%view_221) : !memref_rmem_f32_
      %59 = cute.get_shape(%lay_223) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_224, %e1_225, %e2_226, %e3_227, %e4_228 = cute.get_leaves(%59) : !cute.shape<"((1,(4,4)),1,1)">
      %grouped_229 = cute.group_modes(%view_221) <1, 3> : (!memref_rmem_f32_) -> !memref_rmem_f32_1
      %iter_230 = cute.get_iter(%grouped_229) : !memref_rmem_f32_1
      %iter_231 = cute.get_iter(%grouped_229) : !memref_rmem_f32_1
      %lay_232 = cute.get_layout(%53) : !memref_rmem_i8_
      %shape_233 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_234 = cute.make_layout(%shape_233) : !cute.layout<"1:0">
      %append_235 = cute.append_to_rank<2> (%lay_232, %lay_234) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
      %view_236 = cute.make_view(%iter_192, %append_235) : !memref_rmem_i8_
      %iter_237 = cute.get_iter(%view_236) : !memref_rmem_i8_
      %lay_238 = cute.get_layout(%view_236) : !memref_rmem_i8_
      %60 = cute.get_shape(%lay_238) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_239, %e1_240, %e2_241, %e3_242, %e4_243 = cute.get_leaves(%60) : !cute.shape<"((1,(4,4)),1,1)">
      %grouped_244 = cute.group_modes(%view_236) <1, 3> : (!memref_rmem_i8_) -> !memref_rmem_i8_1
      %iter_245 = cute.get_iter(%grouped_244) : !memref_rmem_i8_1
      %iter_246 = cute.get_iter(%grouped_244) : !memref_rmem_i8_1
      %lay_247 = cute.get_layout(%grouped) : !memref_gmem_f32_3
      %61 = cute.get_shape(%lay_247) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
      %e0_248, %e1_249, %e2_250, %e3_251, %e4_252 = cute.get_leaves(%61) : !cute.shape<"((1,(4,4)),(1,1))">
      %lay_253 = cute.get_layout(%grouped_229) : !memref_rmem_f32_1
      %62 = cute.get_shape(%lay_253) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
      %e0_254, %e1_255, %e2_256, %e3_257, %e4_258 = cute.get_leaves(%62) : !cute.shape<"((1,(4,4)),(1,1))">
      %sz_259 = cute.size(%grouped) <{mode = [1]}> : (!memref_gmem_f32_3) -> !cute.int_tuple<"1">
      %e0_260 = cute.get_leaves(%sz_259) : !cute.int_tuple<"1">
      %sz_261 = cute.size(%grouped_229) <{mode = [1]}> : (!memref_rmem_f32_1) -> !cute.int_tuple<"1">
      %e0_262 = cute.get_leaves(%sz_261) : !cute.int_tuple<"1">
      cute.copy(%atom, %grouped, %grouped_229, %grouped_244) : (!cute_nvgpu.atom.universal_copy<f32>, !memref_gmem_f32_3, !memref_rmem_f32_1, !memref_rmem_i8_1)
      %lay_263 = cute.get_layout(%src_partitioned_135) : !memref_gmem_f32_2
      %63 = cute.get_shape(%lay_263) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_264, %e1_265, %e2_266, %e3_267, %e4_268 = cute.get_leaves(%63) : !cute.shape<"((1,(4,4)),1,1)">
      %lay_269 = cute.get_layout(%rmem_144) : !memref_rmem_f32_
      %64 = cute.get_shape(%lay_269) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_270, %e1_271, %e2_272, %e3_273, %e4_274 = cute.get_leaves(%64) : !cute.shape<"((1,(4,4)),1,1)">
      %lay_275 = cute.get_layout(%src_partitioned_135) : !memref_gmem_f32_2
      %shape_276 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_277 = cute.make_layout(%shape_276) : !cute.layout<"1:0">
      %append_278 = cute.append_to_rank<2> (%lay_275, %lay_277) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">
      %view_279 = cute.make_view(%iter_136, %append_278) : !memref_gmem_f32_2
      %iter_280 = cute.get_iter(%view_279) : !memref_gmem_f32_2
      %lay_281 = cute.get_layout(%view_279) : !memref_gmem_f32_2
      %65 = cute.get_shape(%lay_281) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_282, %e1_283, %e2_284, %e3_285, %e4_286 = cute.get_leaves(%65) : !cute.shape<"((1,(4,4)),1,1)">
      %grouped_287 = cute.group_modes(%view_279) <1, 3> : (!memref_gmem_f32_2) -> !memref_gmem_f32_3
      %iter_288 = cute.get_iter(%grouped_287) : !memref_gmem_f32_3
      %iter_289 = cute.get_iter(%grouped_287) : !memref_gmem_f32_3
      %lay_290 = cute.get_layout(%rmem_144) : !memref_rmem_f32_
      %shape_291 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_292 = cute.make_layout(%shape_291) : !cute.layout<"1:0">
      %append_293 = cute.append_to_rank<2> (%lay_290, %lay_292) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
      %view_294 = cute.make_view(%iter_146, %append_293) : !memref_rmem_f32_
      %iter_295 = cute.get_iter(%view_294) : !memref_rmem_f32_
      %lay_296 = cute.get_layout(%view_294) : !memref_rmem_f32_
      %66 = cute.get_shape(%lay_296) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_297, %e1_298, %e2_299, %e3_300, %e4_301 = cute.get_leaves(%66) : !cute.shape<"((1,(4,4)),1,1)">
      %grouped_302 = cute.group_modes(%view_294) <1, 3> : (!memref_rmem_f32_) -> !memref_rmem_f32_1
      %iter_303 = cute.get_iter(%grouped_302) : !memref_rmem_f32_1
      %iter_304 = cute.get_iter(%grouped_302) : !memref_rmem_f32_1
      %lay_305 = cute.get_layout(%53) : !memref_rmem_i8_
      %shape_306 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_307 = cute.make_layout(%shape_306) : !cute.layout<"1:0">
      %append_308 = cute.append_to_rank<2> (%lay_305, %lay_307) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
      %view_309 = cute.make_view(%iter_192, %append_308) : !memref_rmem_i8_
      %iter_310 = cute.get_iter(%view_309) : !memref_rmem_i8_
      %lay_311 = cute.get_layout(%view_309) : !memref_rmem_i8_
      %67 = cute.get_shape(%lay_311) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_312, %e1_313, %e2_314, %e3_315, %e4_316 = cute.get_leaves(%67) : !cute.shape<"((1,(4,4)),1,1)">
      %grouped_317 = cute.group_modes(%view_309) <1, 3> : (!memref_rmem_i8_) -> !memref_rmem_i8_1
      %iter_318 = cute.get_iter(%grouped_317) : !memref_rmem_i8_1
      %iter_319 = cute.get_iter(%grouped_317) : !memref_rmem_i8_1
      %lay_320 = cute.get_layout(%grouped_287) : !memref_gmem_f32_3
      %68 = cute.get_shape(%lay_320) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
      %e0_321, %e1_322, %e2_323, %e3_324, %e4_325 = cute.get_leaves(%68) : !cute.shape<"((1,(4,4)),(1,1))">
      %lay_326 = cute.get_layout(%grouped_302) : !memref_rmem_f32_1
      %69 = cute.get_shape(%lay_326) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
      %e0_327, %e1_328, %e2_329, %e3_330, %e4_331 = cute.get_leaves(%69) : !cute.shape<"((1,(4,4)),(1,1))">
      %sz_332 = cute.size(%grouped_287) <{mode = [1]}> : (!memref_gmem_f32_3) -> !cute.int_tuple<"1">
      %e0_333 = cute.get_leaves(%sz_332) : !cute.int_tuple<"1">
      %sz_334 = cute.size(%grouped_302) <{mode = [1]}> : (!memref_rmem_f32_1) -> !cute.int_tuple<"1">
      %e0_335 = cute.get_leaves(%sz_334) : !cute.int_tuple<"1">
      cute.copy(%atom, %grouped_287, %grouped_302, %grouped_317) : (!cute_nvgpu.atom.universal_copy<f32>, !memref_gmem_f32_3, !memref_rmem_f32_1, !memref_rmem_i8_1)
      %70 = cute.memref.load_vec %rmem, row_major : !memref_rmem_f32_
      %71 = cute.memref.load_vec %rmem_144, row_major : !memref_rmem_f32_
      %72 = arith.addf %70, %71 : vector<16xf32>
      %lay_336 = cute.get_layout(%rmem_148) : !memref_rmem_f32_
      %73 = cute.get_shape(%lay_336) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_337, %e1_338, %e2_339, %e3_340, %e4_341 = cute.get_leaves(%73) : !cute.shape<"((1,(4,4)),1,1)">
      %int_tuple_342 = cute.make_int_tuple() : () -> !cute.int_tuple<"((1,(4,4)),1,1)">
      %sz_343 = cute.size(%int_tuple_342) : (!cute.int_tuple<"((1,(4,4)),1,1)">) -> !cute.int_tuple<"16">
      %e0_344 = cute.get_leaves(%sz_343) : !cute.int_tuple<"16">
      %int_tuple_345 = cute.make_int_tuple() : () -> !cute.int_tuple<"((1,(4,4)),1,1)">
      %sz_346 = cute.size(%int_tuple_345) : (!cute.int_tuple<"((1,(4,4)),1,1)">) -> !cute.int_tuple<"16">
      %e0_347 = cute.get_leaves(%sz_346) : !cute.int_tuple<"16">
      cute.memref.store_vec %72, %rmem_148, row_major : !memref_rmem_f32_
      %lay_348 = cute.get_layout(%src_partitioned_138) : !memref_gmem_f32_2
      %74 = cute.get_shape(%lay_348) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_349, %e1_350, %e2_351, %e3_352, %e4_353 = cute.get_leaves(%74) : !cute.shape<"((1,(4,4)),1,1)">
      %lay_354 = cute.get_layout(%rmem_148) : !memref_rmem_f32_
      %shape_355 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_356 = cute.make_layout(%shape_355) : !cute.layout<"1:0">
      %append_357 = cute.append_to_rank<2> (%lay_354, %lay_356) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
      %view_358 = cute.make_view(%iter_150, %append_357) : !memref_rmem_f32_
      %iter_359 = cute.get_iter(%view_358) : !memref_rmem_f32_
      %lay_360 = cute.get_layout(%view_358) : !memref_rmem_f32_
      %75 = cute.get_shape(%lay_360) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_361, %e1_362, %e2_363, %e3_364, %e4_365 = cute.get_leaves(%75) : !cute.shape<"((1,(4,4)),1,1)">
      %grouped_366 = cute.group_modes(%view_358) <1, 3> : (!memref_rmem_f32_) -> !memref_rmem_f32_1
      %iter_367 = cute.get_iter(%grouped_366) : !memref_rmem_f32_1
      %iter_368 = cute.get_iter(%grouped_366) : !memref_rmem_f32_1
      %lay_369 = cute.get_layout(%src_partitioned_138) : !memref_gmem_f32_2
      %shape_370 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_371 = cute.make_layout(%shape_370) : !cute.layout<"1:0">
      %append_372 = cute.append_to_rank<2> (%lay_369, %lay_371) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">
      %view_373 = cute.make_view(%iter_139, %append_372) : !memref_gmem_f32_2
      %iter_374 = cute.get_iter(%view_373) : !memref_gmem_f32_2
      %lay_375 = cute.get_layout(%view_373) : !memref_gmem_f32_2
      %76 = cute.get_shape(%lay_375) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_376, %e1_377, %e2_378, %e3_379, %e4_380 = cute.get_leaves(%76) : !cute.shape<"((1,(4,4)),1,1)">
      %grouped_381 = cute.group_modes(%view_373) <1, 3> : (!memref_gmem_f32_2) -> !memref_gmem_f32_3
      %iter_382 = cute.get_iter(%grouped_381) : !memref_gmem_f32_3
      %iter_383 = cute.get_iter(%grouped_381) : !memref_gmem_f32_3
      %lay_384 = cute.get_layout(%53) : !memref_rmem_i8_
      %shape_385 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_386 = cute.make_layout(%shape_385) : !cute.layout<"1:0">
      %append_387 = cute.append_to_rank<2> (%lay_384, %lay_386) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
      %view_388 = cute.make_view(%iter_192, %append_387) : !memref_rmem_i8_
      %iter_389 = cute.get_iter(%view_388) : !memref_rmem_i8_
      %lay_390 = cute.get_layout(%view_388) : !memref_rmem_i8_
      %77 = cute.get_shape(%lay_390) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_391, %e1_392, %e2_393, %e3_394, %e4_395 = cute.get_leaves(%77) : !cute.shape<"((1,(4,4)),1,1)">
      %grouped_396 = cute.group_modes(%view_388) <1, 3> : (!memref_rmem_i8_) -> !memref_rmem_i8_1
      %iter_397 = cute.get_iter(%grouped_396) : !memref_rmem_i8_1
      %iter_398 = cute.get_iter(%grouped_396) : !memref_rmem_i8_1
      %lay_399 = cute.get_layout(%grouped_366) : !memref_rmem_f32_1
      %78 = cute.get_shape(%lay_399) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
      %e0_400, %e1_401, %e2_402, %e3_403, %e4_404 = cute.get_leaves(%78) : !cute.shape<"((1,(4,4)),(1,1))">
      %lay_405 = cute.get_layout(%grouped_381) : !memref_gmem_f32_3
      %79 = cute.get_shape(%lay_405) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
      %e0_406, %e1_407, %e2_408, %e3_409, %e4_410 = cute.get_leaves(%79) : !cute.shape<"((1,(4,4)),(1,1))">
      %sz_411 = cute.size(%grouped_366) <{mode = [1]}> : (!memref_rmem_f32_1) -> !cute.int_tuple<"1">
      %e0_412 = cute.get_leaves(%sz_411) : !cute.int_tuple<"1">
      %sz_413 = cute.size(%grouped_381) <{mode = [1]}> : (!memref_gmem_f32_3) -> !cute.int_tuple<"1">
      %e0_414 = cute.get_leaves(%sz_413) : !cute.int_tuple<"1">
      cute.copy(%atom_75, %grouped_366, %grouped_381, %grouped_396) : (!cute_nvgpu.atom.universal_copy<f32>, !memref_rmem_f32_1, !memref_gmem_f32_3, !memref_rmem_i8_1)
      return
    }
  }
  func.func @cutlass_elementwise_add_tensor12172_02436_09155_14039_01618_04011_05577_09551_06691_04439_00270_01901_19478_25692_12886_22370_05617_20513_02754_03422_05042_12216_02342_13762_01969_(%arg0: !memref_gmem_f32_4, %arg1: !memref_gmem_f32_4, %arg2: !memref_gmem_f32_4) attributes {llvm.emit_c_interface} {
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
    %50 = arith.index_cast %23 : i32 to index
    %c1 = arith.constant 1 : index
    %c128 = arith.constant 128 : index
    %c0_i32 = arith.constant 0 : i32
    gpu.launch_func  @kernels::@kernel_cutlass_elementwise_add_kernel_tensorptrf32gmemo161281div16128_tensorptrf32gmemo161281div16128_tensorptrf32gmemo161281div16128_tensor00o1612810111601281___0 blocks in (%50, %c1, %c1) threads in (%c128, %c1, %c1)  dynamic_shared_memory_size %c0_i32 args(%div : !memref_gmem_f32_, %div_50 : !memref_gmem_f32_, %div_54 : !memref_gmem_f32_, %div_67 : !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">, %20 : i32, %21 : i32) {use_pdl = false}
    return
  }
}
