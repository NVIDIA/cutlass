!copy_simt = !cute.tiled_copy<!cute_nvgpu.atom.universal_copy<f32>, layout_copy_tv = <"((32,4),(4,4)):((64,4),(16,1))">, tiler_mn = <"[16:1;128:1]">>
!memref_gmem_f32_ = !cute.memref<f32, gmem, "((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
!memref_gmem_f32_1 = !cute.memref<f32, gmem, "(16,128):(?{i64},1)">
!memref_gmem_f32_2 = !cute.memref<f32, gmem, "((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
!memref_gmem_f32_3 = !cute.memref<f32, gmem, "((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
!memref_gmem_f32_4 = !cute.memref<f32, gmem, "((1,(4,4))):((0,(1,?{i64})))">
!memref_gmem_f32_5 = !cute.memref<f32, gmem, "(?,?):(?{i64},1)">
!memref_rmem_f32_ = !cute.memref<f32, rmem, align<32>, "((1,(4,4)),1,1):((0,(1,4)),0,0)">
!memref_rmem_f32_1 = !cute.memref<f32, rmem, align<32>, "((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
!memref_rmem_f32_2 = !cute.memref<f32, rmem, align<32>, "((1,(4,4))):((0,(1,4)))">
!memref_rmem_i8_ = !cute.memref<i8, rmem, align<32>, "((1,(4,4)),1,1):((0,(1,4)),0,0)">
!memref_rmem_i8_1 = !cute.memref<i8, rmem, align<32>, "((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
!memref_rmem_i8_2 = !cute.memref<i8, rmem, align<32>, "((1,(4,4))):((0,(1,4)))">
#loop_unroll = #llvm.loop_unroll<disable = false, full = true>
#loop_annotation = #llvm.loop_annotation<unroll = #loop_unroll>
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
      %lay_63 = cute.get_layout(%arg0) : !memref_gmem_f32_
      %slice = cute.slice(%lay_63, %coord) : !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">, !cute.coord<"((_,_),?)">
      %idx = cute.crd2idx(%coord, %lay_63) : (!cute.coord<"((_,_),?)">, !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.int_tuple<"?{i64 div=16}">
      %iter_64 = cute.get_iter(%arg0) : !memref_gmem_f32_
      %ptr = cute.add_offset(%iter_64, %idx) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=16}">) -> !cute.ptr<f32, gmem>
      %view = cute.make_view(%ptr, %slice) : !memref_gmem_f32_1
      %iter_65 = cute.get_iter(%view) : !memref_gmem_f32_1
      %coord_66 = cute.make_coord(%31) : (i32) -> !cute.coord<"((_,_),?)">
      %lay_67 = cute.get_layout(%arg1) : !memref_gmem_f32_
      %slice_68 = cute.slice(%lay_67, %coord_66) : !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">, !cute.coord<"((_,_),?)">
      %idx_69 = cute.crd2idx(%coord_66, %lay_67) : (!cute.coord<"((_,_),?)">, !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.int_tuple<"?{i64 div=16}">
      %iter_70 = cute.get_iter(%arg1) : !memref_gmem_f32_
      %ptr_71 = cute.add_offset(%iter_70, %idx_69) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=16}">) -> !cute.ptr<f32, gmem>
      %view_72 = cute.make_view(%ptr_71, %slice_68) : !memref_gmem_f32_1
      %iter_73 = cute.get_iter(%view_72) : !memref_gmem_f32_1
      %coord_74 = cute.make_coord(%31) : (i32) -> !cute.coord<"((_,_),?)">
      %lay_75 = cute.get_layout(%arg2) : !memref_gmem_f32_
      %slice_76 = cute.slice(%lay_75, %coord_74) : !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">, !cute.coord<"((_,_),?)">
      %idx_77 = cute.crd2idx(%coord_74, %lay_75) : (!cute.coord<"((_,_),?)">, !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.int_tuple<"?{i64 div=16}">
      %iter_78 = cute.get_iter(%arg2) : !memref_gmem_f32_
      %ptr_79 = cute.add_offset(%iter_78, %idx_77) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=16}">) -> !cute.ptr<f32, gmem>
      %view_80 = cute.make_view(%ptr_79, %slice_76) : !memref_gmem_f32_1
      %iter_81 = cute.get_iter(%view_80) : !memref_gmem_f32_1
      %coord_82 = cute.make_coord(%31) : (i32) -> !cute.coord<"((_,_),?)">
      %lay_83 = cute.get_layout(%arg3) : !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
      %idx_84 = cute.crd2idx(%coord_82, %lay_83) : (!cute.coord<"((_,_),?)">, !cute.layout<"((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">) -> !cute.int_tuple<"(?{div=16},?{div=128})">
      %iter_85 = cute.get_iter(%arg3) : !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
      %tup = cute.add_offset(%iter_85, %idx_84) : (!cute.int_tuple<"(0,0)">, !cute.int_tuple<"(?{div=16},?{div=128})">) -> !cute.int_tuple<"(?{div=16},?{div=128})">
      %view_86 = cute.make_view(%tup) : !cute.coord_tensor<"(?{div=16},?{div=128})", "(16,128):(1@0,1@1)">
      %iter_87 = cute.get_iter(%view_86) : !cute.coord_tensor<"(?{div=16},?{div=128})", "(16,128):(1@0,1@1)">
      %e0_88, %e1_89 = cute.get_leaves(%iter_87) : !cute.int_tuple<"(?{div=16},?{div=128})">
      %34 = cute.get_scalars(%e0_88) : !cute.int_tuple<"?{div=16}">
      %35 = cute.get_scalars(%e1_89) : !cute.int_tuple<"?{div=128}">
      %atom = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<f32>
      %atom_90 = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<f32>
      %prod = cute.raked_product(%0, %1) : (!cute.layout<"(4,32):(32,1)">, !cute.layout<"(4,4):(4,1)">) -> !cute.layout<"((4,4),(4,32)):((512,32),(128,1))">
      %sz = cute.size(%0) : (!cute.layout<"(4,32):(32,1)">) -> !cute.int_tuple<"128">
      %e0_91 = cute.get_leaves(%sz) : !cute.int_tuple<"128">
      %sz_92 = cute.size(%1) : (!cute.layout<"(4,4):(4,1)">) -> !cute.int_tuple<"16">
      %e0_93 = cute.get_leaves(%sz_92) : !cute.int_tuple<"16">
      %shape = cute.make_shape() : () -> !cute.shape<"(128,16)">
      %lay_94 = cute.make_layout() : !cute.layout<"(128,16):(1,128)">
      %rinv = cute.right_inverse(%prod) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.layout<"(32,16,4):(64,4,1)">
      %lay_95 = cute.make_layout() : !cute.layout<"((32,4),(4,4)):((64,4),(16,1))">
      %36 = cute.get_shape(%prod) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.shape<"((4,4),(4,32))">
      %e0_96, %e1_97, %e2_98, %e3_99 = cute.get_leaves(%36) : !cute.shape<"((4,4),(4,32))">
      %int_tuple = cute.make_int_tuple() : () -> !cute.int_tuple<"((4,4),(4,32))">
      %res = cute.tuple.product_each(%int_tuple) : (!cute.int_tuple<"((4,4),(4,32))">) -> !cute.int_tuple<"(16,128)">
      %e0_100, %e1_101 = cute.get_leaves(%res) : !cute.int_tuple<"(16,128)">
      %int_tuple_102 = cute.make_int_tuple() : () -> !cute.int_tuple<"(16,128)">
      %res_103 = cute.tuple.product_each(%int_tuple_102) : (!cute.int_tuple<"(16,128)">) -> !cute.int_tuple<"(16,128)">
      %e0_104, %e1_105 = cute.get_leaves(%res_103) : !cute.int_tuple<"(16,128)">
      %tile = cute.make_tile() : () -> !cute.tile<"[16:1;128:1]">
      %37 = cute.make_tiled_copy(%atom) : !copy_simt
      %prod_106 = cute.raked_product(%0, %1) : (!cute.layout<"(4,32):(32,1)">, !cute.layout<"(4,4):(4,1)">) -> !cute.layout<"((4,4),(4,32)):((512,32),(128,1))">
      %sz_107 = cute.size(%0) : (!cute.layout<"(4,32):(32,1)">) -> !cute.int_tuple<"128">
      %e0_108 = cute.get_leaves(%sz_107) : !cute.int_tuple<"128">
      %sz_109 = cute.size(%1) : (!cute.layout<"(4,4):(4,1)">) -> !cute.int_tuple<"16">
      %e0_110 = cute.get_leaves(%sz_109) : !cute.int_tuple<"16">
      %shape_111 = cute.make_shape() : () -> !cute.shape<"(128,16)">
      %lay_112 = cute.make_layout() : !cute.layout<"(128,16):(1,128)">
      %rinv_113 = cute.right_inverse(%prod_106) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.layout<"(32,16,4):(64,4,1)">
      %lay_114 = cute.make_layout() : !cute.layout<"((32,4),(4,4)):((64,4),(16,1))">
      %38 = cute.get_shape(%prod_106) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.shape<"((4,4),(4,32))">
      %e0_115, %e1_116, %e2_117, %e3_118 = cute.get_leaves(%38) : !cute.shape<"((4,4),(4,32))">
      %int_tuple_119 = cute.make_int_tuple() : () -> !cute.int_tuple<"((4,4),(4,32))">
      %res_120 = cute.tuple.product_each(%int_tuple_119) : (!cute.int_tuple<"((4,4),(4,32))">) -> !cute.int_tuple<"(16,128)">
      %e0_121, %e1_122 = cute.get_leaves(%res_120) : !cute.int_tuple<"(16,128)">
      %int_tuple_123 = cute.make_int_tuple() : () -> !cute.int_tuple<"(16,128)">
      %res_124 = cute.tuple.product_each(%int_tuple_123) : (!cute.int_tuple<"(16,128)">) -> !cute.int_tuple<"(16,128)">
      %e0_125, %e1_126 = cute.get_leaves(%res_124) : !cute.int_tuple<"(16,128)">
      %tile_127 = cute.make_tile() : () -> !cute.tile<"[16:1;128:1]">
      %39 = cute.make_tiled_copy(%atom) : !copy_simt
      %prod_128 = cute.raked_product(%0, %1) : (!cute.layout<"(4,32):(32,1)">, !cute.layout<"(4,4):(4,1)">) -> !cute.layout<"((4,4),(4,32)):((512,32),(128,1))">
      %sz_129 = cute.size(%0) : (!cute.layout<"(4,32):(32,1)">) -> !cute.int_tuple<"128">
      %e0_130 = cute.get_leaves(%sz_129) : !cute.int_tuple<"128">
      %sz_131 = cute.size(%1) : (!cute.layout<"(4,4):(4,1)">) -> !cute.int_tuple<"16">
      %e0_132 = cute.get_leaves(%sz_131) : !cute.int_tuple<"16">
      %shape_133 = cute.make_shape() : () -> !cute.shape<"(128,16)">
      %lay_134 = cute.make_layout() : !cute.layout<"(128,16):(1,128)">
      %rinv_135 = cute.right_inverse(%prod_128) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.layout<"(32,16,4):(64,4,1)">
      %lay_136 = cute.make_layout() : !cute.layout<"((32,4),(4,4)):((64,4),(16,1))">
      %40 = cute.get_shape(%prod_128) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.shape<"((4,4),(4,32))">
      %e0_137, %e1_138, %e2_139, %e3_140 = cute.get_leaves(%40) : !cute.shape<"((4,4),(4,32))">
      %int_tuple_141 = cute.make_int_tuple() : () -> !cute.int_tuple<"((4,4),(4,32))">
      %res_142 = cute.tuple.product_each(%int_tuple_141) : (!cute.int_tuple<"((4,4),(4,32))">) -> !cute.int_tuple<"(16,128)">
      %e0_143, %e1_144 = cute.get_leaves(%res_142) : !cute.int_tuple<"(16,128)">
      %int_tuple_145 = cute.make_int_tuple() : () -> !cute.int_tuple<"(16,128)">
      %res_146 = cute.tuple.product_each(%int_tuple_145) : (!cute.int_tuple<"(16,128)">) -> !cute.int_tuple<"(16,128)">
      %e0_147, %e1_148 = cute.get_leaves(%res_146) : !cute.int_tuple<"(16,128)">
      %tile_149 = cute.make_tile() : () -> !cute.tile<"[16:1;128:1]">
      %41 = cute.make_tiled_copy(%atom_90) : !copy_simt
      %coord_150 = cute.make_coord(%28) : (i32) -> !cute.coord<"?">
      %src_partitioned = cute.tiled.copy.partition_S(%37, %view, %coord_150) : (!copy_simt, !memref_gmem_f32_1, !cute.coord<"?">) -> !memref_gmem_f32_2
      %iter_151 = cute.get_iter(%src_partitioned) : !memref_gmem_f32_2
      %coord_152 = cute.make_coord(%28) : (i32) -> !cute.coord<"?">
      %src_partitioned_153 = cute.tiled.copy.partition_S(%39, %view_72, %coord_152) : (!copy_simt, !memref_gmem_f32_1, !cute.coord<"?">) -> !memref_gmem_f32_2
      %iter_154 = cute.get_iter(%src_partitioned_153) : !memref_gmem_f32_2
      %coord_155 = cute.make_coord(%28) : (i32) -> !cute.coord<"?">
      %src_partitioned_156 = cute.tiled.copy.partition_S(%41, %view_80, %coord_155) : (!copy_simt, !memref_gmem_f32_1, !cute.coord<"?">) -> !memref_gmem_f32_2
      %iter_157 = cute.get_iter(%src_partitioned_156) : !memref_gmem_f32_2
      %lay_158 = cute.get_layout(%src_partitioned) : !memref_gmem_f32_2
      %42 = cute.make_layout_like(%lay_158) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)"> to !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %rmem = cute.memref.alloca(%42) : !memref_rmem_f32_
      %iter_159 = cute.get_iter(%rmem) : !memref_rmem_f32_
      %iter_160 = cute.get_iter(%rmem) : !memref_rmem_f32_
      %lay_161 = cute.get_layout(%src_partitioned_153) : !memref_gmem_f32_2
      %43 = cute.make_layout_like(%lay_161) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)"> to !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %rmem_162 = cute.memref.alloca(%43) : !memref_rmem_f32_
      %iter_163 = cute.get_iter(%rmem_162) : !memref_rmem_f32_
      %iter_164 = cute.get_iter(%rmem_162) : !memref_rmem_f32_
      %lay_165 = cute.get_layout(%src_partitioned_156) : !memref_gmem_f32_2
      %44 = cute.make_layout_like(%lay_165) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)"> to !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %rmem_166 = cute.memref.alloca(%44) : !memref_rmem_f32_
      %iter_167 = cute.get_iter(%rmem_166) : !memref_rmem_f32_
      %iter_168 = cute.get_iter(%rmem_166) : !memref_rmem_f32_
      %coord_169 = cute.make_coord(%28) : (i32) -> !cute.coord<"?">
      %src_partitioned_170 = cute.tiled.copy.partition_S(%41, %view_86, %coord_169) : (!copy_simt, !cute.coord_tensor<"(?{div=16},?{div=128})", "(16,128):(1@0,1@1)">, !cute.coord<"?">) -> !cute.coord_tensor<"(?{div=4},?{div=4})", "((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">
      %iter_171 = cute.get_iter(%src_partitioned_170) : !cute.coord_tensor<"(?{div=4},?{div=4})", "((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">
      %e0_172, %e1_173 = cute.get_leaves(%iter_171) : !cute.int_tuple<"(?{div=4},?{div=4})">
      %45 = cute.get_scalars(%e0_172) : !cute.int_tuple<"?{div=4}">
      %46 = cute.get_scalars(%e1_173) : !cute.int_tuple<"?{div=4}">
      %lay_174 = cute.get_layout(%src_partitioned_170) : !cute.coord_tensor<"(?{div=4},?{div=4})", "((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">
      %47 = cute.get_shape(%lay_174) : (!cute.layout<"((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_175, %e1_176, %e2_177, %e3_178, %e4 = cute.get_leaves(%47) : !cute.shape<"((1,(4,4)),1,1)">
      %shape_179 = cute.make_shape() : () -> !cute.shape<"((1,(4,4)),1,1)">
      %lay_180 = cute.make_layout() : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %rmem_181 = cute.memref.alloca(%lay_180) : !memref_rmem_i8_
      %iter_182 = cute.get_iter(%rmem_181) : !memref_rmem_i8_
      %iter_183 = cute.get_iter(%rmem_181) : !memref_rmem_i8_
      %lay_184 = cute.get_layout(%rmem_181) : !memref_rmem_i8_
      %sz_185 = cute.size(%lay_184) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.int_tuple<"16">
      %e0_186 = cute.get_leaves(%sz_185) : !cute.int_tuple<"16">
      %lay_187 = cute.get_layout(%rmem_181) : !memref_rmem_i8_
      %48 = cute.get_shape(%lay_187) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_188, %e1_189, %e2_190, %e3_191, %e4_192 = cute.get_leaves(%48) : !cute.shape<"((1,(4,4)),1,1)">
      %49 = cute.get_stride(%lay_187) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.stride<"((0,(1,4)),0,0)">
      %e0_193, %e1_194, %e2_195, %e3_196, %e4_197 = cute.get_leaves(%49) : !cute.stride<"((0,(1,4)),0,0)">
      %c0_i32 = arith.constant 0 : i32
      %c16_i32 = arith.constant 16 : i32
      %c1_i32 = arith.constant 1 : i32
      %50 = scf.for %arg6 = %c0_i32 to %c16_i32 step %c1_i32 iter_args(%arg7 = %rmem_181) -> (!memref_rmem_i8_)  : i32 {
        %iter_513 = cute.get_iter(%arg7) : !memref_rmem_i8_
        %lay_514 = cute.get_layout(%arg7) : !memref_rmem_i8_
        %89 = cute.get_shape(%lay_514) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
        %e0_515, %e1_516, %e2_517, %e3_518, %e4_519 = cute.get_leaves(%89) : !cute.shape<"((1,(4,4)),1,1)">
        %90 = cute.get_stride(%lay_514) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.stride<"((0,(1,4)),0,0)">
        %e0_520, %e1_521, %e2_522, %e3_523, %e4_524 = cute.get_leaves(%90) : !cute.stride<"((0,(1,4)),0,0)">
        %iter_525 = cute.get_iter(%arg7) : !memref_rmem_i8_
        %coord_526 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"?">
        %lay_527 = cute.get_layout(%src_partitioned_170) : !cute.coord_tensor<"(?{div=4},?{div=4})", "((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">
        %idx_528 = cute.crd2idx(%coord_526, %lay_527) : (!cute.coord<"?">, !cute.layout<"((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">) -> !cute.int_tuple<"(?,?)">
        %iter_529 = cute.get_iter(%src_partitioned_170) : !cute.coord_tensor<"(?{div=4},?{div=4})", "((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">
        %tup_530 = cute.add_offset(%iter_529, %idx_528) : (!cute.int_tuple<"(?{div=4},?{div=4})">, !cute.int_tuple<"(?,?)">) -> !cute.int_tuple<"(?,?)">
        %view_531 = cute.make_view(%tup_530) : !cute.coord_tensor<"(?,?)", "():()">
        %iter_532 = cute.get_iter(%view_531) : !cute.coord_tensor<"(?,?)", "():()">
        %e0_533, %e1_534 = cute.get_leaves(%iter_532) : !cute.int_tuple<"(?,?)">
        %91 = cute.get_scalars(%e0_533) : !cute.int_tuple<"?">
        %92 = cute.get_scalars(%e1_534) : !cute.int_tuple<"?">
        %iter_535 = cute.get_iter(%view_531) : !cute.coord_tensor<"(?,?)", "():()">
        %e0_536, %e1_537 = cute.get_leaves(%iter_535) : !cute.int_tuple<"(?,?)">
        %93 = cute.get_scalars(%e0_536) : !cute.int_tuple<"?">
        %94 = cute.get_scalars(%e1_537) : !cute.int_tuple<"?">
        %iter_538 = cute.get_iter(%view_531) : !cute.coord_tensor<"(?,?)", "():()">
        %e0_539, %e1_540 = cute.get_leaves(%iter_538) : !cute.int_tuple<"(?,?)">
        %95 = cute.get_scalars(%e0_539) : !cute.int_tuple<"?">
        %96 = cute.get_scalars(%e1_540) : !cute.int_tuple<"?">
        %coord_541 = cute.make_coord(%e0_539, %e1_540) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
        %coord_542 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
        %97 = cute.elem_less(%coord_541, %coord_542) : !cute.coord<"(?,?)">, !cute.coord<"(?,?)">
        %98 = arith.extui %97 : i1 to i8
        %coord_543 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"?">
        cute.memref.store(%arg7, %coord_543, %98) : (!memref_rmem_i8_, !cute.coord<"?">, i8) -> ()
        %lay_544 = cute.get_layout(%arg7) : !memref_rmem_i8_
        %99 = cute.get_shape(%lay_544) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
        %e0_545, %e1_546, %e2_547, %e3_548, %e4_549 = cute.get_leaves(%99) : !cute.shape<"((1,(4,4)),1,1)">
        %100 = cute.get_stride(%lay_544) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.stride<"((0,(1,4)),0,0)">
        %e0_550, %e1_551, %e2_552, %e3_553, %e4_554 = cute.get_leaves(%100) : !cute.stride<"((0,(1,4)),0,0)">
        scf.yield %arg7 : !memref_rmem_i8_
      }
      %iter_198 = cute.get_iter(%50) : !memref_rmem_i8_
      %lay_199 = cute.get_layout(%50) : !memref_rmem_i8_
      %51 = cute.get_shape(%lay_199) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_200, %e1_201, %e2_202, %e3_203, %e4_204 = cute.get_leaves(%51) : !cute.shape<"((1,(4,4)),1,1)">
      %52 = cute.get_stride(%lay_199) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.stride<"((0,(1,4)),0,0)">
      %e0_205, %e1_206, %e2_207, %e3_208, %e4_209 = cute.get_leaves(%52) : !cute.stride<"((0,(1,4)),0,0)">
      %iter_210 = cute.get_iter(%50) : !memref_rmem_i8_
      %iter_211 = cute.get_iter(%50) : !memref_rmem_i8_
      %lay_212 = cute.get_layout(%src_partitioned) : !memref_gmem_f32_2
      %53 = cute.get_shape(%lay_212) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_213, %e1_214, %e2_215, %e3_216, %e4_217 = cute.get_leaves(%53) : !cute.shape<"((1,(4,4)),1,1)">
      %lay_218 = cute.get_layout(%rmem) : !memref_rmem_f32_
      %54 = cute.get_shape(%lay_218) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_219, %e1_220, %e2_221, %e3_222, %e4_223 = cute.get_leaves(%54) : !cute.shape<"((1,(4,4)),1,1)">
      %lay_224 = cute.get_layout(%src_partitioned) : !memref_gmem_f32_2
      %shape_225 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_226 = cute.make_layout() : !cute.layout<"1:0">
      %append = cute.append_to_rank<2> (%lay_224, %lay_226) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">
      %view_227 = cute.make_view(%iter_151, %append) : !memref_gmem_f32_2
      %iter_228 = cute.get_iter(%view_227) : !memref_gmem_f32_2
      %lay_229 = cute.get_layout(%view_227) : !memref_gmem_f32_2
      %55 = cute.get_shape(%lay_229) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_230, %e1_231, %e2_232, %e3_233, %e4_234 = cute.get_leaves(%55) : !cute.shape<"((1,(4,4)),1,1)">
      %iter_235 = cute.get_iter(%view_227) : !memref_gmem_f32_2
      %lay_236 = cute.get_layout(%view_227) : !memref_gmem_f32_2
      %56 = cute.get_scalars(%lay_236) <{only_dynamic}> : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %shape_237 = cute.make_shape() : () -> !cute.shape<"((1,(4,4)),(1,1))">
      %stride = cute.make_stride(%56) : (i64) -> !cute.stride<"((0,(1,?{i64})),(0,0))">
      %lay_238 = cute.make_layout(%shape_237, %stride) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %view_239 = cute.make_view(%iter_235, %lay_238) : !memref_gmem_f32_3
      %iter_240 = cute.get_iter(%view_239) : !memref_gmem_f32_3
      %iter_241 = cute.get_iter(%view_239) : !memref_gmem_f32_3
      %lay_242 = cute.get_layout(%rmem) : !memref_rmem_f32_
      %shape_243 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_244 = cute.make_layout() : !cute.layout<"1:0">
      %append_245 = cute.append_to_rank<2> (%lay_242, %lay_244) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
      %view_246 = cute.make_view(%iter_160, %append_245) : !memref_rmem_f32_
      %iter_247 = cute.get_iter(%view_246) : !memref_rmem_f32_
      %lay_248 = cute.get_layout(%view_246) : !memref_rmem_f32_
      %57 = cute.get_shape(%lay_248) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_249, %e1_250, %e2_251, %e3_252, %e4_253 = cute.get_leaves(%57) : !cute.shape<"((1,(4,4)),1,1)">
      %iter_254 = cute.get_iter(%view_246) : !memref_rmem_f32_
      %view_255 = cute.make_view(%iter_254) : !memref_rmem_f32_1
      %iter_256 = cute.get_iter(%view_255) : !memref_rmem_f32_1
      %iter_257 = cute.get_iter(%view_255) : !memref_rmem_f32_1
      %lay_258 = cute.get_layout(%50) : !memref_rmem_i8_
      %shape_259 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_260 = cute.make_layout() : !cute.layout<"1:0">
      %append_261 = cute.append_to_rank<2> (%lay_258, %lay_260) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
      %view_262 = cute.make_view(%iter_211, %append_261) : !memref_rmem_i8_
      %iter_263 = cute.get_iter(%view_262) : !memref_rmem_i8_
      %lay_264 = cute.get_layout(%view_262) : !memref_rmem_i8_
      %58 = cute.get_shape(%lay_264) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_265, %e1_266, %e2_267, %e3_268, %e4_269 = cute.get_leaves(%58) : !cute.shape<"((1,(4,4)),1,1)">
      %iter_270 = cute.get_iter(%view_262) : !memref_rmem_i8_
      %view_271 = cute.make_view(%iter_270) : !memref_rmem_i8_1
      %iter_272 = cute.get_iter(%view_271) : !memref_rmem_i8_1
      %iter_273 = cute.get_iter(%view_271) : !memref_rmem_i8_1
      %lay_274 = cute.get_layout(%view_239) : !memref_gmem_f32_3
      %59 = cute.get_shape(%lay_274) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
      %e0_275, %e1_276, %e2_277, %e3_278, %e4_279 = cute.get_leaves(%59) : !cute.shape<"((1,(4,4)),(1,1))">
      %lay_280 = cute.get_layout(%view_255) : !memref_rmem_f32_1
      %60 = cute.get_shape(%lay_280) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
      %e0_281, %e1_282, %e2_283, %e3_284, %e4_285 = cute.get_leaves(%60) : !cute.shape<"((1,(4,4)),(1,1))">
      %lay_286 = cute.get_layout(%view_239) : !memref_gmem_f32_3
      %sz_287 = cute.size(%lay_286) <{mode = [1]}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.int_tuple<"1">
      %e0_288 = cute.get_leaves(%sz_287) : !cute.int_tuple<"1">
      %lay_289 = cute.get_layout(%view_255) : !memref_rmem_f32_1
      %sz_290 = cute.size(%lay_289) <{mode = [1]}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.int_tuple<"1">
      %e0_291 = cute.get_leaves(%sz_290) : !cute.int_tuple<"1">
      %61 = cute.static : !cute.layout<"1:0">
      %iter_292 = cute.get_iter(%view_239) : !memref_gmem_f32_3
      %iter_293 = cute.get_iter(%view_255) : !memref_rmem_f32_1
      %lay_294 = cute.get_layout(%view_239) : !memref_gmem_f32_3
      %lay_295 = cute.get_layout(%view_255) : !memref_rmem_f32_1
      %append_296 = cute.append_to_rank<2> (%lay_294, %61) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">, !cute.layout<"1:0">
      %append_297 = cute.append_to_rank<2> (%lay_295, %61) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">, !cute.layout<"1:0">
      %62 = cute.get_scalars(%append_296) <{only_dynamic}> : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %shape_298 = cute.make_shape() : () -> !cute.shape<"((1,(4,4)),((1,1)))">
      %stride_299 = cute.make_stride(%62) : (i64) -> !cute.stride<"((0,(1,?{i64})),((0,0)))">
      %lay_300 = cute.make_layout(%shape_298, %stride_299) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
      %lay_301 = cute.make_layout() : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">
      %iter_302 = cute.get_iter(%view_271) : !memref_rmem_i8_1
      %lay_303 = cute.get_layout(%view_271) : !memref_rmem_i8_1
      %append_304 = cute.append_to_rank<2> (%lay_303, %61) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">, !cute.layout<"1:0">
      %lay_305 = cute.make_layout() : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">
      %sz_306 = cute.size(%lay_300) <{mode = [1]}> : (!cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">) -> !cute.int_tuple<"1">
      %63 = cute.get_scalars(%sz_306) : !cute.int_tuple<"1">
      %c0_i32_307 = arith.constant 0 : i32
      %c1_i32_308 = arith.constant 1 : i32
      scf.for %arg6 = %c0_i32_307 to %63 step %c1_i32_308  : i32 {
        %coord_513 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
        %slice_514 = cute.slice(%lay_300, %coord_513) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">, !cute.coord<"(_,?)">
        %idx_515 = cute.crd2idx(%coord_513, %lay_300) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">) -> !cute.int_tuple<"0">
        %ptr_516 = cute.add_offset(%iter_292, %idx_515) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<f32, gmem>
        %view_517 = cute.make_view(%ptr_516, %slice_514) : !memref_gmem_f32_4
        %slice_518 = cute.slice(%lay_301, %coord_513) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">, !cute.coord<"(_,?)">
        %idx_519 = cute.crd2idx(%coord_513, %lay_301) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">) -> !cute.int_tuple<"0">
        %ptr_520 = cute.add_offset(%iter_293, %idx_519) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, rmem, align<32>>
        %view_521 = cute.make_view(%ptr_520, %slice_518) : !memref_rmem_f32_2
        %slice_522 = cute.slice(%lay_305, %coord_513) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">, !cute.coord<"(_,?)">
        %idx_523 = cute.crd2idx(%coord_513, %lay_305) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">) -> !cute.int_tuple<"0">
        %ptr_524 = cute.add_offset(%iter_302, %idx_523) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
        %view_525 = cute.make_view(%ptr_524, %slice_522) : !memref_rmem_i8_2
        cute.copy_atom_call(%atom, %view_517, %view_521, %view_525) : (!cute_nvgpu.atom.universal_copy<f32>, !memref_gmem_f32_4, !memref_rmem_f32_2, !memref_rmem_i8_2) -> ()
      } {llvm.loop_annotation = #loop_annotation}
      %lay_309 = cute.get_layout(%src_partitioned_153) : !memref_gmem_f32_2
      %64 = cute.get_shape(%lay_309) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_310, %e1_311, %e2_312, %e3_313, %e4_314 = cute.get_leaves(%64) : !cute.shape<"((1,(4,4)),1,1)">
      %lay_315 = cute.get_layout(%rmem_162) : !memref_rmem_f32_
      %65 = cute.get_shape(%lay_315) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_316, %e1_317, %e2_318, %e3_319, %e4_320 = cute.get_leaves(%65) : !cute.shape<"((1,(4,4)),1,1)">
      %lay_321 = cute.get_layout(%src_partitioned_153) : !memref_gmem_f32_2
      %shape_322 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_323 = cute.make_layout() : !cute.layout<"1:0">
      %append_324 = cute.append_to_rank<2> (%lay_321, %lay_323) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">
      %view_325 = cute.make_view(%iter_154, %append_324) : !memref_gmem_f32_2
      %iter_326 = cute.get_iter(%view_325) : !memref_gmem_f32_2
      %lay_327 = cute.get_layout(%view_325) : !memref_gmem_f32_2
      %66 = cute.get_shape(%lay_327) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_328, %e1_329, %e2_330, %e3_331, %e4_332 = cute.get_leaves(%66) : !cute.shape<"((1,(4,4)),1,1)">
      %iter_333 = cute.get_iter(%view_325) : !memref_gmem_f32_2
      %lay_334 = cute.get_layout(%view_325) : !memref_gmem_f32_2
      %67 = cute.get_scalars(%lay_334) <{only_dynamic}> : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %shape_335 = cute.make_shape() : () -> !cute.shape<"((1,(4,4)),(1,1))">
      %stride_336 = cute.make_stride(%67) : (i64) -> !cute.stride<"((0,(1,?{i64})),(0,0))">
      %lay_337 = cute.make_layout(%shape_335, %stride_336) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %view_338 = cute.make_view(%iter_333, %lay_337) : !memref_gmem_f32_3
      %iter_339 = cute.get_iter(%view_338) : !memref_gmem_f32_3
      %iter_340 = cute.get_iter(%view_338) : !memref_gmem_f32_3
      %lay_341 = cute.get_layout(%rmem_162) : !memref_rmem_f32_
      %shape_342 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_343 = cute.make_layout() : !cute.layout<"1:0">
      %append_344 = cute.append_to_rank<2> (%lay_341, %lay_343) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
      %view_345 = cute.make_view(%iter_164, %append_344) : !memref_rmem_f32_
      %iter_346 = cute.get_iter(%view_345) : !memref_rmem_f32_
      %lay_347 = cute.get_layout(%view_345) : !memref_rmem_f32_
      %68 = cute.get_shape(%lay_347) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_348, %e1_349, %e2_350, %e3_351, %e4_352 = cute.get_leaves(%68) : !cute.shape<"((1,(4,4)),1,1)">
      %iter_353 = cute.get_iter(%view_345) : !memref_rmem_f32_
      %view_354 = cute.make_view(%iter_353) : !memref_rmem_f32_1
      %iter_355 = cute.get_iter(%view_354) : !memref_rmem_f32_1
      %iter_356 = cute.get_iter(%view_354) : !memref_rmem_f32_1
      %lay_357 = cute.get_layout(%50) : !memref_rmem_i8_
      %shape_358 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_359 = cute.make_layout() : !cute.layout<"1:0">
      %append_360 = cute.append_to_rank<2> (%lay_357, %lay_359) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
      %view_361 = cute.make_view(%iter_211, %append_360) : !memref_rmem_i8_
      %iter_362 = cute.get_iter(%view_361) : !memref_rmem_i8_
      %lay_363 = cute.get_layout(%view_361) : !memref_rmem_i8_
      %69 = cute.get_shape(%lay_363) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_364, %e1_365, %e2_366, %e3_367, %e4_368 = cute.get_leaves(%69) : !cute.shape<"((1,(4,4)),1,1)">
      %iter_369 = cute.get_iter(%view_361) : !memref_rmem_i8_
      %view_370 = cute.make_view(%iter_369) : !memref_rmem_i8_1
      %iter_371 = cute.get_iter(%view_370) : !memref_rmem_i8_1
      %iter_372 = cute.get_iter(%view_370) : !memref_rmem_i8_1
      %lay_373 = cute.get_layout(%view_338) : !memref_gmem_f32_3
      %70 = cute.get_shape(%lay_373) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
      %e0_374, %e1_375, %e2_376, %e3_377, %e4_378 = cute.get_leaves(%70) : !cute.shape<"((1,(4,4)),(1,1))">
      %lay_379 = cute.get_layout(%view_354) : !memref_rmem_f32_1
      %71 = cute.get_shape(%lay_379) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
      %e0_380, %e1_381, %e2_382, %e3_383, %e4_384 = cute.get_leaves(%71) : !cute.shape<"((1,(4,4)),(1,1))">
      %lay_385 = cute.get_layout(%view_338) : !memref_gmem_f32_3
      %sz_386 = cute.size(%lay_385) <{mode = [1]}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.int_tuple<"1">
      %e0_387 = cute.get_leaves(%sz_386) : !cute.int_tuple<"1">
      %lay_388 = cute.get_layout(%view_354) : !memref_rmem_f32_1
      %sz_389 = cute.size(%lay_388) <{mode = [1]}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.int_tuple<"1">
      %e0_390 = cute.get_leaves(%sz_389) : !cute.int_tuple<"1">
      %72 = cute.static : !cute.layout<"1:0">
      %iter_391 = cute.get_iter(%view_338) : !memref_gmem_f32_3
      %iter_392 = cute.get_iter(%view_354) : !memref_rmem_f32_1
      %lay_393 = cute.get_layout(%view_338) : !memref_gmem_f32_3
      %lay_394 = cute.get_layout(%view_354) : !memref_rmem_f32_1
      %append_395 = cute.append_to_rank<2> (%lay_393, %72) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">, !cute.layout<"1:0">
      %append_396 = cute.append_to_rank<2> (%lay_394, %72) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">, !cute.layout<"1:0">
      %73 = cute.get_scalars(%append_395) <{only_dynamic}> : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %shape_397 = cute.make_shape() : () -> !cute.shape<"((1,(4,4)),((1,1)))">
      %stride_398 = cute.make_stride(%73) : (i64) -> !cute.stride<"((0,(1,?{i64})),((0,0)))">
      %lay_399 = cute.make_layout(%shape_397, %stride_398) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
      %lay_400 = cute.make_layout() : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">
      %iter_401 = cute.get_iter(%view_370) : !memref_rmem_i8_1
      %lay_402 = cute.get_layout(%view_370) : !memref_rmem_i8_1
      %append_403 = cute.append_to_rank<2> (%lay_402, %72) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">, !cute.layout<"1:0">
      %lay_404 = cute.make_layout() : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">
      %sz_405 = cute.size(%lay_399) <{mode = [1]}> : (!cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">) -> !cute.int_tuple<"1">
      %74 = cute.get_scalars(%sz_405) : !cute.int_tuple<"1">
      %c0_i32_406 = arith.constant 0 : i32
      %c1_i32_407 = arith.constant 1 : i32
      scf.for %arg6 = %c0_i32_406 to %74 step %c1_i32_407  : i32 {
        %coord_513 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
        %slice_514 = cute.slice(%lay_399, %coord_513) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">, !cute.coord<"(_,?)">
        %idx_515 = cute.crd2idx(%coord_513, %lay_399) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">) -> !cute.int_tuple<"0">
        %ptr_516 = cute.add_offset(%iter_391, %idx_515) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<f32, gmem>
        %view_517 = cute.make_view(%ptr_516, %slice_514) : !memref_gmem_f32_4
        %slice_518 = cute.slice(%lay_400, %coord_513) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">, !cute.coord<"(_,?)">
        %idx_519 = cute.crd2idx(%coord_513, %lay_400) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">) -> !cute.int_tuple<"0">
        %ptr_520 = cute.add_offset(%iter_392, %idx_519) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, rmem, align<32>>
        %view_521 = cute.make_view(%ptr_520, %slice_518) : !memref_rmem_f32_2
        %slice_522 = cute.slice(%lay_404, %coord_513) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">, !cute.coord<"(_,?)">
        %idx_523 = cute.crd2idx(%coord_513, %lay_404) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">) -> !cute.int_tuple<"0">
        %ptr_524 = cute.add_offset(%iter_401, %idx_523) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
        %view_525 = cute.make_view(%ptr_524, %slice_522) : !memref_rmem_i8_2
        cute.copy_atom_call(%atom, %view_517, %view_521, %view_525) : (!cute_nvgpu.atom.universal_copy<f32>, !memref_gmem_f32_4, !memref_rmem_f32_2, !memref_rmem_i8_2) -> ()
      } {llvm.loop_annotation = #loop_annotation}
      %75 = cute.memref.load_vec %rmem, row_major : !memref_rmem_f32_
      %76 = cute.memref.load_vec %rmem_162, row_major : !memref_rmem_f32_
      %77 = arith.addf %75, %76 : vector<16xf32>
      %lay_408 = cute.get_layout(%rmem_166) : !memref_rmem_f32_
      %78 = cute.get_shape(%lay_408) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_409, %e1_410, %e2_411, %e3_412, %e4_413 = cute.get_leaves(%78) : !cute.shape<"((1,(4,4)),1,1)">
      %int_tuple_414 = cute.make_int_tuple() : () -> !cute.int_tuple<"((1,(4,4)),1,1)">
      %sz_415 = cute.size(%int_tuple_414) : (!cute.int_tuple<"((1,(4,4)),1,1)">) -> !cute.int_tuple<"16">
      %e0_416 = cute.get_leaves(%sz_415) : !cute.int_tuple<"16">
      %int_tuple_417 = cute.make_int_tuple() : () -> !cute.int_tuple<"((1,(4,4)),1,1)">
      %sz_418 = cute.size(%int_tuple_417) : (!cute.int_tuple<"((1,(4,4)),1,1)">) -> !cute.int_tuple<"16">
      %e0_419 = cute.get_leaves(%sz_418) : !cute.int_tuple<"16">
      cute.memref.store_vec %77, %rmem_166, row_major : !memref_rmem_f32_
      %lay_420 = cute.get_layout(%src_partitioned_156) : !memref_gmem_f32_2
      %79 = cute.get_shape(%lay_420) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_421, %e1_422, %e2_423, %e3_424, %e4_425 = cute.get_leaves(%79) : !cute.shape<"((1,(4,4)),1,1)">
      %lay_426 = cute.get_layout(%rmem_166) : !memref_rmem_f32_
      %shape_427 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_428 = cute.make_layout() : !cute.layout<"1:0">
      %append_429 = cute.append_to_rank<2> (%lay_426, %lay_428) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
      %view_430 = cute.make_view(%iter_168, %append_429) : !memref_rmem_f32_
      %iter_431 = cute.get_iter(%view_430) : !memref_rmem_f32_
      %lay_432 = cute.get_layout(%view_430) : !memref_rmem_f32_
      %80 = cute.get_shape(%lay_432) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_433, %e1_434, %e2_435, %e3_436, %e4_437 = cute.get_leaves(%80) : !cute.shape<"((1,(4,4)),1,1)">
      %iter_438 = cute.get_iter(%view_430) : !memref_rmem_f32_
      %view_439 = cute.make_view(%iter_438) : !memref_rmem_f32_1
      %iter_440 = cute.get_iter(%view_439) : !memref_rmem_f32_1
      %iter_441 = cute.get_iter(%view_439) : !memref_rmem_f32_1
      %lay_442 = cute.get_layout(%src_partitioned_156) : !memref_gmem_f32_2
      %shape_443 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_444 = cute.make_layout() : !cute.layout<"1:0">
      %append_445 = cute.append_to_rank<2> (%lay_442, %lay_444) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">
      %view_446 = cute.make_view(%iter_157, %append_445) : !memref_gmem_f32_2
      %iter_447 = cute.get_iter(%view_446) : !memref_gmem_f32_2
      %lay_448 = cute.get_layout(%view_446) : !memref_gmem_f32_2
      %81 = cute.get_shape(%lay_448) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_449, %e1_450, %e2_451, %e3_452, %e4_453 = cute.get_leaves(%81) : !cute.shape<"((1,(4,4)),1,1)">
      %iter_454 = cute.get_iter(%view_446) : !memref_gmem_f32_2
      %lay_455 = cute.get_layout(%view_446) : !memref_gmem_f32_2
      %82 = cute.get_scalars(%lay_455) <{only_dynamic}> : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %shape_456 = cute.make_shape() : () -> !cute.shape<"((1,(4,4)),(1,1))">
      %stride_457 = cute.make_stride(%82) : (i64) -> !cute.stride<"((0,(1,?{i64})),(0,0))">
      %lay_458 = cute.make_layout(%shape_456, %stride_457) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %view_459 = cute.make_view(%iter_454, %lay_458) : !memref_gmem_f32_3
      %iter_460 = cute.get_iter(%view_459) : !memref_gmem_f32_3
      %iter_461 = cute.get_iter(%view_459) : !memref_gmem_f32_3
      %lay_462 = cute.get_layout(%50) : !memref_rmem_i8_
      %shape_463 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_464 = cute.make_layout() : !cute.layout<"1:0">
      %append_465 = cute.append_to_rank<2> (%lay_462, %lay_464) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
      %view_466 = cute.make_view(%iter_211, %append_465) : !memref_rmem_i8_
      %iter_467 = cute.get_iter(%view_466) : !memref_rmem_i8_
      %lay_468 = cute.get_layout(%view_466) : !memref_rmem_i8_
      %83 = cute.get_shape(%lay_468) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_469, %e1_470, %e2_471, %e3_472, %e4_473 = cute.get_leaves(%83) : !cute.shape<"((1,(4,4)),1,1)">
      %iter_474 = cute.get_iter(%view_466) : !memref_rmem_i8_
      %view_475 = cute.make_view(%iter_474) : !memref_rmem_i8_1
      %iter_476 = cute.get_iter(%view_475) : !memref_rmem_i8_1
      %iter_477 = cute.get_iter(%view_475) : !memref_rmem_i8_1
      %lay_478 = cute.get_layout(%view_439) : !memref_rmem_f32_1
      %84 = cute.get_shape(%lay_478) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
      %e0_479, %e1_480, %e2_481, %e3_482, %e4_483 = cute.get_leaves(%84) : !cute.shape<"((1,(4,4)),(1,1))">
      %lay_484 = cute.get_layout(%view_459) : !memref_gmem_f32_3
      %85 = cute.get_shape(%lay_484) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
      %e0_485, %e1_486, %e2_487, %e3_488, %e4_489 = cute.get_leaves(%85) : !cute.shape<"((1,(4,4)),(1,1))">
      %lay_490 = cute.get_layout(%view_439) : !memref_rmem_f32_1
      %sz_491 = cute.size(%lay_490) <{mode = [1]}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.int_tuple<"1">
      %e0_492 = cute.get_leaves(%sz_491) : !cute.int_tuple<"1">
      %lay_493 = cute.get_layout(%view_459) : !memref_gmem_f32_3
      %sz_494 = cute.size(%lay_493) <{mode = [1]}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.int_tuple<"1">
      %e0_495 = cute.get_leaves(%sz_494) : !cute.int_tuple<"1">
      %86 = cute.static : !cute.layout<"1:0">
      %iter_496 = cute.get_iter(%view_439) : !memref_rmem_f32_1
      %iter_497 = cute.get_iter(%view_459) : !memref_gmem_f32_3
      %lay_498 = cute.get_layout(%view_439) : !memref_rmem_f32_1
      %lay_499 = cute.get_layout(%view_459) : !memref_gmem_f32_3
      %append_500 = cute.append_to_rank<2> (%lay_498, %86) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">, !cute.layout<"1:0">
      %append_501 = cute.append_to_rank<2> (%lay_499, %86) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">, !cute.layout<"1:0">
      %lay_502 = cute.make_layout() : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">
      %87 = cute.get_scalars(%append_501) <{only_dynamic}> : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %shape_503 = cute.make_shape() : () -> !cute.shape<"((1,(4,4)),((1,1)))">
      %stride_504 = cute.make_stride(%87) : (i64) -> !cute.stride<"((0,(1,?{i64})),((0,0)))">
      %lay_505 = cute.make_layout(%shape_503, %stride_504) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
      %iter_506 = cute.get_iter(%view_475) : !memref_rmem_i8_1
      %lay_507 = cute.get_layout(%view_475) : !memref_rmem_i8_1
      %append_508 = cute.append_to_rank<2> (%lay_507, %86) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">, !cute.layout<"1:0">
      %lay_509 = cute.make_layout() : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">
      %sz_510 = cute.size(%lay_502) <{mode = [1]}> : (!cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">) -> !cute.int_tuple<"1">
      %88 = cute.get_scalars(%sz_510) : !cute.int_tuple<"1">
      %c0_i32_511 = arith.constant 0 : i32
      %c1_i32_512 = arith.constant 1 : i32
      scf.for %arg6 = %c0_i32_511 to %88 step %c1_i32_512  : i32 {
        %coord_513 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
        %slice_514 = cute.slice(%lay_502, %coord_513) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">, !cute.coord<"(_,?)">
        %idx_515 = cute.crd2idx(%coord_513, %lay_502) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">) -> !cute.int_tuple<"0">
        %ptr_516 = cute.add_offset(%iter_496, %idx_515) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, rmem, align<32>>
        %view_517 = cute.make_view(%ptr_516, %slice_514) : !memref_rmem_f32_2
        %slice_518 = cute.slice(%lay_505, %coord_513) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">, !cute.coord<"(_,?)">
        %idx_519 = cute.crd2idx(%coord_513, %lay_505) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">) -> !cute.int_tuple<"0">
        %ptr_520 = cute.add_offset(%iter_497, %idx_519) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<f32, gmem>
        %view_521 = cute.make_view(%ptr_520, %slice_518) : !memref_gmem_f32_4
        %slice_522 = cute.slice(%lay_509, %coord_513) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">, !cute.coord<"(_,?)">
        %idx_523 = cute.crd2idx(%coord_513, %lay_509) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">) -> !cute.int_tuple<"0">
        %ptr_524 = cute.add_offset(%iter_506, %idx_523) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
        %view_525 = cute.make_view(%ptr_524, %slice_522) : !memref_rmem_i8_2
        cute.copy_atom_call(%atom_90, %view_517, %view_521, %view_525) : (!cute_nvgpu.atom.universal_copy<f32>, !memref_rmem_f32_2, !memref_gmem_f32_4, !memref_rmem_i8_2) -> ()
      } {llvm.loop_annotation = #loop_annotation}
      return
    }
  }
  func.func @cutlass_elementwise_add_tensor12172_02436_09155_14039_01618_04011_05577_09551_06691_04439_00270_01901_19478_25692_12886_22370_05617_20513_02754_03422_05042_12216_02342_13762_01969_(%arg0: !memref_gmem_f32_5, %arg1: !memref_gmem_f32_5, %arg2: !memref_gmem_f32_5) attributes {llvm.emit_c_interface} {
    %iter = cute.get_iter(%arg0) : !memref_gmem_f32_5
    %iter_0 = cute.get_iter(%arg1) : !memref_gmem_f32_5
    %iter_1 = cute.get_iter(%arg2) : !memref_gmem_f32_5
    %iter_2 = cute.get_iter(%arg0) : !memref_gmem_f32_5
    %iter_3 = cute.get_iter(%arg1) : !memref_gmem_f32_5
    %iter_4 = cute.get_iter(%arg2) : !memref_gmem_f32_5
    %lay = cute.get_layout(%arg0) : !memref_gmem_f32_5
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
    %lay_9 = cute.get_layout(%arg1) : !memref_gmem_f32_5
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
    %lay_17 = cute.get_layout(%arg2) : !memref_gmem_f32_5
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
    %lay_25 = cute.make_layout() : !cute.layout<"(4,32):(32,1)">
    %shape_26 = cute.make_shape() : () -> !cute.shape<"(4,4)">
    %int_tuple_27 = cute.make_int_tuple() : () -> !cute.int_tuple<"(1,0)">
    %lay_28 = cute.make_layout() : !cute.layout<"(4,4):(4,1)">
    %prod = cute.raked_product(%lay_25, %lay_28) : (!cute.layout<"(4,32):(32,1)">, !cute.layout<"(4,4):(4,1)">) -> !cute.layout<"((4,4),(4,32)):((512,32),(128,1))">
    %sz = cute.size(%lay_25) : (!cute.layout<"(4,32):(32,1)">) -> !cute.int_tuple<"128">
    %e0_29 = cute.get_leaves(%sz) : !cute.int_tuple<"128">
    %sz_30 = cute.size(%lay_28) : (!cute.layout<"(4,4):(4,1)">) -> !cute.int_tuple<"16">
    %e0_31 = cute.get_leaves(%sz_30) : !cute.int_tuple<"16">
    %shape_32 = cute.make_shape() : () -> !cute.shape<"(128,16)">
    %lay_33 = cute.make_layout() : !cute.layout<"(128,16):(1,128)">
    %rinv = cute.right_inverse(%prod) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.layout<"(32,16,4):(64,4,1)">
    %lay_34 = cute.make_layout() : !cute.layout<"((32,4),(4,4)):((64,4),(16,1))">
    %15 = cute.get_shape(%prod) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.shape<"((4,4),(4,32))">
    %e0_35, %e1_36, %e2, %e3 = cute.get_leaves(%15) : !cute.shape<"((4,4),(4,32))">
    %int_tuple_37 = cute.make_int_tuple() : () -> !cute.int_tuple<"((4,4),(4,32))">
    %res = cute.tuple.product_each(%int_tuple_37) : (!cute.int_tuple<"((4,4),(4,32))">) -> !cute.int_tuple<"(16,128)">
    %e0_38, %e1_39 = cute.get_leaves(%res) : !cute.int_tuple<"(16,128)">
    %16 = cute.get_shape(%lay_34) : (!cute.layout<"((32,4),(4,4)):((64,4),(16,1))">) -> !cute.shape<"((32,4),(4,4))">
    %e0_40, %e1_41, %e2_42, %e3_43 = cute.get_leaves(%16) : !cute.shape<"((32,4),(4,4))">
    %17 = cute.get_stride(%lay_34) : (!cute.layout<"((32,4),(4,4)):((64,4),(16,1))">) -> !cute.stride<"((64,4),(16,1))">
    %e0_44, %e1_45, %e2_46, %e3_47 = cute.get_leaves(%17) : !cute.stride<"((64,4),(16,1))">
    %tile = cute.make_tile() : () -> !cute.tile<"[16:1;128:1]">
    %iter_48 = cute.get_iter(%arg0) : !memref_gmem_f32_5
    %lay_49 = cute.get_layout(%arg0) : !memref_gmem_f32_5
    %18:3 = cute.get_scalars(%lay_49) <{only_dynamic}> : !cute.layout<"(?,?):(?{i64},1)">
    %c16_i32 = arith.constant 16 : i32
    %19 = arith.ceildivsi %18#0, %c16_i32 : i32
    %c16_i64 = arith.constant 16 : i64
    %20 = arith.muli %18#2, %c16_i64 : i64
    %c128_i32 = arith.constant 128 : i32
    %21 = arith.ceildivsi %18#1, %c128_i32 : i32
    %shape_50 = cute.make_shape(%19, %21) : (i32, i32) -> !cute.shape<"((16,128),(?,?))">
    %iv = cute.assume(%20) : (i64) -> !cute.i64<divby 16>
    %stride = cute.make_stride(%18#2, %iv) : (i64, !cute.i64<divby 16>) -> !cute.stride<"((?{i64},1),(?{i64 div=16},128))">
    %lay_51 = cute.make_layout(%shape_50, %stride) : !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
    %view = cute.make_view(%iter_48, %lay_51) : !memref_gmem_f32_
    %iter_52 = cute.get_iter(%view) : !memref_gmem_f32_
    %iter_53 = cute.get_iter(%view) : !memref_gmem_f32_
    %tile_54 = cute.make_tile() : () -> !cute.tile<"[16:1;128:1]">
    %iter_55 = cute.get_iter(%arg1) : !memref_gmem_f32_5
    %lay_56 = cute.get_layout(%arg1) : !memref_gmem_f32_5
    %22:3 = cute.get_scalars(%lay_56) <{only_dynamic}> : !cute.layout<"(?,?):(?{i64},1)">
    %c16_i32_57 = arith.constant 16 : i32
    %23 = arith.ceildivsi %22#0, %c16_i32_57 : i32
    %c16_i64_58 = arith.constant 16 : i64
    %24 = arith.muli %22#2, %c16_i64_58 : i64
    %c128_i32_59 = arith.constant 128 : i32
    %25 = arith.ceildivsi %22#1, %c128_i32_59 : i32
    %shape_60 = cute.make_shape(%23, %25) : (i32, i32) -> !cute.shape<"((16,128),(?,?))">
    %iv_61 = cute.assume(%24) : (i64) -> !cute.i64<divby 16>
    %stride_62 = cute.make_stride(%22#2, %iv_61) : (i64, !cute.i64<divby 16>) -> !cute.stride<"((?{i64},1),(?{i64 div=16},128))">
    %lay_63 = cute.make_layout(%shape_60, %stride_62) : !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
    %view_64 = cute.make_view(%iter_55, %lay_63) : !memref_gmem_f32_
    %iter_65 = cute.get_iter(%view_64) : !memref_gmem_f32_
    %iter_66 = cute.get_iter(%view_64) : !memref_gmem_f32_
    %tile_67 = cute.make_tile() : () -> !cute.tile<"[16:1;128:1]">
    %iter_68 = cute.get_iter(%arg2) : !memref_gmem_f32_5
    %lay_69 = cute.get_layout(%arg2) : !memref_gmem_f32_5
    %26:3 = cute.get_scalars(%lay_69) <{only_dynamic}> : !cute.layout<"(?,?):(?{i64},1)">
    %c16_i32_70 = arith.constant 16 : i32
    %27 = arith.ceildivsi %26#0, %c16_i32_70 : i32
    %c16_i64_71 = arith.constant 16 : i64
    %28 = arith.muli %26#2, %c16_i64_71 : i64
    %c128_i32_72 = arith.constant 128 : i32
    %29 = arith.ceildivsi %26#1, %c128_i32_72 : i32
    %shape_73 = cute.make_shape(%27, %29) : (i32, i32) -> !cute.shape<"((16,128),(?,?))">
    %iv_74 = cute.assume(%28) : (i64) -> !cute.i64<divby 16>
    %stride_75 = cute.make_stride(%26#2, %iv_74) : (i64, !cute.i64<divby 16>) -> !cute.stride<"((?{i64},1),(?{i64 div=16},128))">
    %lay_76 = cute.make_layout(%shape_73, %stride_75) : !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
    %view_77 = cute.make_view(%iter_68, %lay_76) : !memref_gmem_f32_
    %iter_78 = cute.get_iter(%view_77) : !memref_gmem_f32_
    %iter_79 = cute.get_iter(%view_77) : !memref_gmem_f32_
    %lay_80 = cute.get_layout(%arg2) : !memref_gmem_f32_5
    %30 = cute.get_shape(%lay_80) : (!cute.layout<"(?,?):(?{i64},1)">) -> !cute.shape<"(?,?)">
    %e0_81, %e1_82 = cute.get_leaves(%30) : !cute.shape<"(?,?)">
    %itup_83 = cute.to_int_tuple(%e0_81) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %31 = cute.get_scalars(%itup_83) : !cute.int_tuple<"?">
    %itup_84 = cute.to_int_tuple(%e1_82) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %32 = cute.get_scalars(%itup_84) : !cute.int_tuple<"?">
    %shape_85 = cute.make_shape(%itup_83, %itup_84) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.shape<"(?,?)">
    %33 = cute.make_identity_tensor(%shape_85) : !cute.coord_tensor<"(0,0)", "(?,?):(1@0,1@1)">
    %iter_86 = cute.get_iter(%33) : !cute.coord_tensor<"(0,0)", "(?,?):(1@0,1@1)">
    %e0_87, %e1_88 = cute.get_leaves(%iter_86) : !cute.int_tuple<"(0,0)">
    %tile_89 = cute.make_tile() : () -> !cute.tile<"[16:1;128:1]">
    %iter_90 = cute.get_iter(%33) : !cute.coord_tensor<"(0,0)", "(?,?):(1@0,1@1)">
    %lay_91 = cute.get_layout(%33) : !cute.coord_tensor<"(0,0)", "(?,?):(1@0,1@1)">
    %34:2 = cute.get_scalars(%lay_91) <{only_dynamic}> : !cute.layout<"(?,?):(1@0,1@1)">
    %c16_i32_92 = arith.constant 16 : i32
    %35 = arith.ceildivsi %34#0, %c16_i32_92 : i32
    %c128_i32_93 = arith.constant 128 : i32
    %36 = arith.ceildivsi %34#1, %c128_i32_93 : i32
    %shape_94 = cute.make_shape(%35, %36) : (i32, i32) -> !cute.shape<"((16,128),(?,?))">
    %stride_95 = cute.make_stride() : () -> !cute.stride<"((1@0,1@1),(16@0,128@1))">
    %lay_96 = cute.make_layout(%shape_94, %stride_95) : !cute.layout<"((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
    %view_97 = cute.make_view(%iter_90, %lay_96) : !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
    %iter_98 = cute.get_iter(%view_97) : !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
    %e0_99, %e1_100 = cute.get_leaves(%iter_98) : !cute.int_tuple<"(0,0)">
    %iter_101 = cute.get_iter(%view_97) : !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
    %e0_102, %e1_103 = cute.get_leaves(%iter_101) : !cute.int_tuple<"(0,0)">
    %lay_104 = cute.get_layout(%view_77) : !memref_gmem_f32_
    %sz_105 = cute.size(%lay_104) <{mode = [1]}> : (!cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.int_tuple<"?">
    %e0_106 = cute.get_leaves(%sz_105) : !cute.int_tuple<"?">
    %37 = cute.get_scalars(%e0_106) : !cute.int_tuple<"?">
    %sz_107 = cute.size(%lay_34) <{mode = [0]}> : (!cute.layout<"((32,4),(4,4)):((64,4),(16,1))">) -> !cute.int_tuple<"128">
    %e0_108 = cute.get_leaves(%sz_107) : !cute.int_tuple<"128">
    %lay_109 = cute.get_layout(%view) : !memref_gmem_f32_
    %38 = cute.get_shape(%lay_109) : (!cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.shape<"((16,128),(?,?))">
    %e0_110, %e1_111, %e2_112, %e3_113 = cute.get_leaves(%38) : !cute.shape<"((16,128),(?,?))">
    %itup_114 = cute.to_int_tuple(%e2_112) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %39 = cute.get_scalars(%itup_114) : !cute.int_tuple<"?">
    %itup_115 = cute.to_int_tuple(%e3_113) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %40 = cute.get_scalars(%itup_115) : !cute.int_tuple<"?">
    %41 = cute.get_stride(%lay_109) : (!cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.stride<"((?{i64},1),(?{i64 div=16},128))">
    %e0_116, %e1_117, %e2_118, %e3_119 = cute.get_leaves(%41) : !cute.stride<"((?{i64},1),(?{i64 div=16},128))">
    %itup_120 = cute.to_int_tuple(%e0_116) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
    %42 = cute.get_scalars(%itup_120) : !cute.int_tuple<"?{i64}">
    %itup_121 = cute.to_int_tuple(%e2_118) : !cute.stride<"?{i64 div=16}"> to !cute.int_tuple<"?{i64 div=16}">
    %43 = cute.get_scalars(%itup_121) : !cute.int_tuple<"?{i64 div=16}">
    %lay_122 = cute.get_layout(%view_64) : !memref_gmem_f32_
    %44 = cute.get_shape(%lay_122) : (!cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.shape<"((16,128),(?,?))">
    %e0_123, %e1_124, %e2_125, %e3_126 = cute.get_leaves(%44) : !cute.shape<"((16,128),(?,?))">
    %itup_127 = cute.to_int_tuple(%e2_125) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %45 = cute.get_scalars(%itup_127) : !cute.int_tuple<"?">
    %itup_128 = cute.to_int_tuple(%e3_126) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %46 = cute.get_scalars(%itup_128) : !cute.int_tuple<"?">
    %47 = cute.get_stride(%lay_122) : (!cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.stride<"((?{i64},1),(?{i64 div=16},128))">
    %e0_129, %e1_130, %e2_131, %e3_132 = cute.get_leaves(%47) : !cute.stride<"((?{i64},1),(?{i64 div=16},128))">
    %itup_133 = cute.to_int_tuple(%e0_129) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
    %48 = cute.get_scalars(%itup_133) : !cute.int_tuple<"?{i64}">
    %itup_134 = cute.to_int_tuple(%e2_131) : !cute.stride<"?{i64 div=16}"> to !cute.int_tuple<"?{i64 div=16}">
    %49 = cute.get_scalars(%itup_134) : !cute.int_tuple<"?{i64 div=16}">
    %lay_135 = cute.get_layout(%view_77) : !memref_gmem_f32_
    %50 = cute.get_shape(%lay_135) : (!cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.shape<"((16,128),(?,?))">
    %e0_136, %e1_137, %e2_138, %e3_139 = cute.get_leaves(%50) : !cute.shape<"((16,128),(?,?))">
    %itup_140 = cute.to_int_tuple(%e2_138) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %51 = cute.get_scalars(%itup_140) : !cute.int_tuple<"?">
    %itup_141 = cute.to_int_tuple(%e3_139) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %52 = cute.get_scalars(%itup_141) : !cute.int_tuple<"?">
    %53 = cute.get_stride(%lay_135) : (!cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.stride<"((?{i64},1),(?{i64 div=16},128))">
    %e0_142, %e1_143, %e2_144, %e3_145 = cute.get_leaves(%53) : !cute.stride<"((?{i64},1),(?{i64 div=16},128))">
    %itup_146 = cute.to_int_tuple(%e0_142) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
    %54 = cute.get_scalars(%itup_146) : !cute.int_tuple<"?{i64}">
    %itup_147 = cute.to_int_tuple(%e2_144) : !cute.stride<"?{i64 div=16}"> to !cute.int_tuple<"?{i64 div=16}">
    %55 = cute.get_scalars(%itup_147) : !cute.int_tuple<"?{i64 div=16}">
    %lay_148 = cute.get_layout(%view_97) : !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
    %56 = cute.get_shape(%lay_148) : (!cute.layout<"((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">) -> !cute.shape<"((16,128),(?,?))">
    %e0_149, %e1_150, %e2_151, %e3_152 = cute.get_leaves(%56) : !cute.shape<"((16,128),(?,?))">
    %itup_153 = cute.to_int_tuple(%e2_151) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %57 = cute.get_scalars(%itup_153) : !cute.int_tuple<"?">
    %itup_154 = cute.to_int_tuple(%e3_152) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %58 = cute.get_scalars(%itup_154) : !cute.int_tuple<"?">
    %59 = cute.get_stride(%lay_148) : (!cute.layout<"((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">) -> !cute.stride<"((1@0,1@1),(16@0,128@1))">
    %e0_155, %e1_156, %e2_157, %e3_158 = cute.get_leaves(%59) : !cute.stride<"((1@0,1@1),(16@0,128@1))">
    %60 = cute.get_shape(%lay_25) : (!cute.layout<"(4,32):(32,1)">) -> !cute.shape<"(4,32)">
    %e0_159, %e1_160 = cute.get_leaves(%60) : !cute.shape<"(4,32)">
    %61 = cute.get_stride(%lay_25) : (!cute.layout<"(4,32):(32,1)">) -> !cute.stride<"(32,1)">
    %e0_161, %e1_162 = cute.get_leaves(%61) : !cute.stride<"(32,1)">
    %62 = cute.get_shape(%lay_28) : (!cute.layout<"(4,4):(4,1)">) -> !cute.shape<"(4,4)">
    %e0_163, %e1_164 = cute.get_leaves(%62) : !cute.shape<"(4,4)">
    %63 = cute.get_stride(%lay_28) : (!cute.layout<"(4,4):(4,1)">) -> !cute.stride<"(4,1)">
    %e0_165, %e1_166 = cute.get_leaves(%63) : !cute.stride<"(4,1)">
    %64 = arith.index_cast %37 : i32 to index
    %c1 = arith.constant 1 : index
    %c128 = arith.constant 128 : index
    %c0_i32 = arith.constant 0 : i32
    gpu.launch_func  @kernels::@kernel_cutlass_elementwise_add_kernel_tensorptrf32gmemo161281div16128_tensorptrf32gmemo161281div16128_tensorptrf32gmemo161281div16128_tensor00o1612810111601281___0 blocks in (%64, %c1, %c1) threads in (%c128, %c1, %c1)  dynamic_shared_memory_size %c0_i32 args(%view : !memref_gmem_f32_, %view_64 : !memref_gmem_f32_, %view_77 : !memref_gmem_f32_, %view_97 : !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">, %31 : i32, %32 : i32) {use_pdl = false}
    return
  }
}
