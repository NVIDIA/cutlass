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
      %lay_63 = cute.get_layout(%arg0) : !memref_gmem_f32_
      %slice = cute.slice(%lay_63, %coord) : !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">, !cute.coord<"((_,_),?)">
      %idx = cute.crd2idx(%coord, %lay_63) : (!cute.coord<"((_,_),?)">, !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.int_tuple<"?{i64 div=16}">
      %iter_64 = cute.get_iter(%arg0) : !memref_gmem_f32_
      %ptr = cute.add_offset(%iter_64, %idx) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=16}">) -> !cute.ptr<f32, gmem>
      %view = cute.make_view(%ptr, %slice) : !memref_gmem_f32_1
      %iter_65 = cute.get_iter(%view) : !memref_gmem_f32_1
      %iter_66 = cute.get_iter(%view) : !memref_gmem_f32_1
      %coord_67 = cute.make_coord(%31) : (i32) -> !cute.coord<"((_,_),?)">
      %lay_68 = cute.get_layout(%arg1) : !memref_gmem_f32_
      %slice_69 = cute.slice(%lay_68, %coord_67) : !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">, !cute.coord<"((_,_),?)">
      %idx_70 = cute.crd2idx(%coord_67, %lay_68) : (!cute.coord<"((_,_),?)">, !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.int_tuple<"?{i64 div=16}">
      %iter_71 = cute.get_iter(%arg1) : !memref_gmem_f32_
      %ptr_72 = cute.add_offset(%iter_71, %idx_70) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=16}">) -> !cute.ptr<f32, gmem>
      %view_73 = cute.make_view(%ptr_72, %slice_69) : !memref_gmem_f32_1
      %iter_74 = cute.get_iter(%view_73) : !memref_gmem_f32_1
      %iter_75 = cute.get_iter(%view_73) : !memref_gmem_f32_1
      %coord_76 = cute.make_coord(%31) : (i32) -> !cute.coord<"((_,_),?)">
      %lay_77 = cute.get_layout(%arg2) : !memref_gmem_f32_
      %slice_78 = cute.slice(%lay_77, %coord_76) : !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">, !cute.coord<"((_,_),?)">
      %idx_79 = cute.crd2idx(%coord_76, %lay_77) : (!cute.coord<"((_,_),?)">, !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.int_tuple<"?{i64 div=16}">
      %iter_80 = cute.get_iter(%arg2) : !memref_gmem_f32_
      %ptr_81 = cute.add_offset(%iter_80, %idx_79) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=16}">) -> !cute.ptr<f32, gmem>
      %view_82 = cute.make_view(%ptr_81, %slice_78) : !memref_gmem_f32_1
      %iter_83 = cute.get_iter(%view_82) : !memref_gmem_f32_1
      %iter_84 = cute.get_iter(%view_82) : !memref_gmem_f32_1
      %coord_85 = cute.make_coord(%31) : (i32) -> !cute.coord<"((_,_),?)">
      %lay_86 = cute.get_layout(%arg3) : !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
      %idx_87 = cute.crd2idx(%coord_85, %lay_86) : (!cute.coord<"((_,_),?)">, !cute.layout<"((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">) -> !cute.int_tuple<"(?{div=16},?{div=128})">
      %iter_88 = cute.get_iter(%arg3) : !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
      %tup = cute.add_offset(%iter_88, %idx_87) : (!cute.int_tuple<"(0,0)">, !cute.int_tuple<"(?{div=16},?{div=128})">) -> !cute.int_tuple<"(?{div=16},?{div=128})">
      %view_89 = cute.make_view(%tup) : !cute.coord_tensor<"(?{div=16},?{div=128})", "(16,128):(1@0,1@1)">
      %iter_90 = cute.get_iter(%view_89) : !cute.coord_tensor<"(?{div=16},?{div=128})", "(16,128):(1@0,1@1)">
      %e0_91, %e1_92 = cute.get_leaves(%iter_90) : !cute.int_tuple<"(?{div=16},?{div=128})">
      %34 = cute.get_scalars(%e0_91) : !cute.int_tuple<"?{div=16}">
      %35 = cute.get_scalars(%e1_92) : !cute.int_tuple<"?{div=128}">
      %iter_93 = cute.get_iter(%view_89) : !cute.coord_tensor<"(?{div=16},?{div=128})", "(16,128):(1@0,1@1)">
      %e0_94, %e1_95 = cute.get_leaves(%iter_93) : !cute.int_tuple<"(?{div=16},?{div=128})">
      %36 = cute.get_scalars(%e0_94) : !cute.int_tuple<"?{div=16}">
      %37 = cute.get_scalars(%e1_95) : !cute.int_tuple<"?{div=128}">
      %atom = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<f32>
      %atom_96 = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<f32>
      %prod = cute.raked_product(%0, %1) : (!cute.layout<"(4,32):(32,1)">, !cute.layout<"(4,4):(4,1)">) -> !cute.layout<"((4,4),(4,32)):((512,32),(128,1))">
      %sz = cute.size(%0) : (!cute.layout<"(4,32):(32,1)">) -> !cute.int_tuple<"128">
      %e0_97 = cute.get_leaves(%sz) : !cute.int_tuple<"128">
      %sz_98 = cute.size(%1) : (!cute.layout<"(4,4):(4,1)">) -> !cute.int_tuple<"16">
      %e0_99 = cute.get_leaves(%sz_98) : !cute.int_tuple<"16">
      %shape = cute.make_shape() : () -> !cute.shape<"(128,16)">
      %lay_100 = cute.make_layout() : !cute.layout<"(128,16):(1,128)">
      %rinv = cute.right_inverse(%prod) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.layout<"(32,16,4):(64,4,1)">
      %lay_101 = cute.make_layout() : !cute.layout<"((32,4),(4,4)):((64,4),(16,1))">
      %38 = cute.get_shape(%prod) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.shape<"((4,4),(4,32))">
      %e0_102, %e1_103, %e2_104, %e3_105 = cute.get_leaves(%38) : !cute.shape<"((4,4),(4,32))">
      %int_tuple = cute.make_int_tuple() : () -> !cute.int_tuple<"((4,4),(4,32))">
      %res = cute.tuple.product_each(%int_tuple) : (!cute.int_tuple<"((4,4),(4,32))">) -> !cute.int_tuple<"(16,128)">
      %e0_106, %e1_107 = cute.get_leaves(%res) : !cute.int_tuple<"(16,128)">
      %int_tuple_108 = cute.make_int_tuple() : () -> !cute.int_tuple<"(16,128)">
      %res_109 = cute.tuple.product_each(%int_tuple_108) : (!cute.int_tuple<"(16,128)">) -> !cute.int_tuple<"(16,128)">
      %e0_110, %e1_111 = cute.get_leaves(%res_109) : !cute.int_tuple<"(16,128)">
      %tile = cute.make_tile() : () -> !cute.tile<"[16:1;128:1]">
      %39 = cute.make_tiled_copy(%atom) : !copy_simt
      %prod_112 = cute.raked_product(%0, %1) : (!cute.layout<"(4,32):(32,1)">, !cute.layout<"(4,4):(4,1)">) -> !cute.layout<"((4,4),(4,32)):((512,32),(128,1))">
      %sz_113 = cute.size(%0) : (!cute.layout<"(4,32):(32,1)">) -> !cute.int_tuple<"128">
      %e0_114 = cute.get_leaves(%sz_113) : !cute.int_tuple<"128">
      %sz_115 = cute.size(%1) : (!cute.layout<"(4,4):(4,1)">) -> !cute.int_tuple<"16">
      %e0_116 = cute.get_leaves(%sz_115) : !cute.int_tuple<"16">
      %shape_117 = cute.make_shape() : () -> !cute.shape<"(128,16)">
      %lay_118 = cute.make_layout() : !cute.layout<"(128,16):(1,128)">
      %rinv_119 = cute.right_inverse(%prod_112) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.layout<"(32,16,4):(64,4,1)">
      %lay_120 = cute.make_layout() : !cute.layout<"((32,4),(4,4)):((64,4),(16,1))">
      %40 = cute.get_shape(%prod_112) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.shape<"((4,4),(4,32))">
      %e0_121, %e1_122, %e2_123, %e3_124 = cute.get_leaves(%40) : !cute.shape<"((4,4),(4,32))">
      %int_tuple_125 = cute.make_int_tuple() : () -> !cute.int_tuple<"((4,4),(4,32))">
      %res_126 = cute.tuple.product_each(%int_tuple_125) : (!cute.int_tuple<"((4,4),(4,32))">) -> !cute.int_tuple<"(16,128)">
      %e0_127, %e1_128 = cute.get_leaves(%res_126) : !cute.int_tuple<"(16,128)">
      %int_tuple_129 = cute.make_int_tuple() : () -> !cute.int_tuple<"(16,128)">
      %res_130 = cute.tuple.product_each(%int_tuple_129) : (!cute.int_tuple<"(16,128)">) -> !cute.int_tuple<"(16,128)">
      %e0_131, %e1_132 = cute.get_leaves(%res_130) : !cute.int_tuple<"(16,128)">
      %tile_133 = cute.make_tile() : () -> !cute.tile<"[16:1;128:1]">
      %41 = cute.make_tiled_copy(%atom) : !copy_simt
      %prod_134 = cute.raked_product(%0, %1) : (!cute.layout<"(4,32):(32,1)">, !cute.layout<"(4,4):(4,1)">) -> !cute.layout<"((4,4),(4,32)):((512,32),(128,1))">
      %sz_135 = cute.size(%0) : (!cute.layout<"(4,32):(32,1)">) -> !cute.int_tuple<"128">
      %e0_136 = cute.get_leaves(%sz_135) : !cute.int_tuple<"128">
      %sz_137 = cute.size(%1) : (!cute.layout<"(4,4):(4,1)">) -> !cute.int_tuple<"16">
      %e0_138 = cute.get_leaves(%sz_137) : !cute.int_tuple<"16">
      %shape_139 = cute.make_shape() : () -> !cute.shape<"(128,16)">
      %lay_140 = cute.make_layout() : !cute.layout<"(128,16):(1,128)">
      %rinv_141 = cute.right_inverse(%prod_134) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.layout<"(32,16,4):(64,4,1)">
      %lay_142 = cute.make_layout() : !cute.layout<"((32,4),(4,4)):((64,4),(16,1))">
      %42 = cute.get_shape(%prod_134) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.shape<"((4,4),(4,32))">
      %e0_143, %e1_144, %e2_145, %e3_146 = cute.get_leaves(%42) : !cute.shape<"((4,4),(4,32))">
      %int_tuple_147 = cute.make_int_tuple() : () -> !cute.int_tuple<"((4,4),(4,32))">
      %res_148 = cute.tuple.product_each(%int_tuple_147) : (!cute.int_tuple<"((4,4),(4,32))">) -> !cute.int_tuple<"(16,128)">
      %e0_149, %e1_150 = cute.get_leaves(%res_148) : !cute.int_tuple<"(16,128)">
      %int_tuple_151 = cute.make_int_tuple() : () -> !cute.int_tuple<"(16,128)">
      %res_152 = cute.tuple.product_each(%int_tuple_151) : (!cute.int_tuple<"(16,128)">) -> !cute.int_tuple<"(16,128)">
      %e0_153, %e1_154 = cute.get_leaves(%res_152) : !cute.int_tuple<"(16,128)">
      %tile_155 = cute.make_tile() : () -> !cute.tile<"[16:1;128:1]">
      %43 = cute.make_tiled_copy(%atom_96) : !copy_simt
      %coord_156 = cute.make_coord(%28) : (i32) -> !cute.coord<"?">
      %src_partitioned = cute.tiled.copy.partition_S(%39, %view, %coord_156) : (!copy_simt, !memref_gmem_f32_1, !cute.coord<"?">) -> !memref_gmem_f32_2
      %iter_157 = cute.get_iter(%src_partitioned) : !memref_gmem_f32_2
      %coord_158 = cute.make_coord(%28) : (i32) -> !cute.coord<"?">
      %src_partitioned_159 = cute.tiled.copy.partition_S(%41, %view_73, %coord_158) : (!copy_simt, !memref_gmem_f32_1, !cute.coord<"?">) -> !memref_gmem_f32_2
      %iter_160 = cute.get_iter(%src_partitioned_159) : !memref_gmem_f32_2
      %coord_161 = cute.make_coord(%28) : (i32) -> !cute.coord<"?">
      %src_partitioned_162 = cute.tiled.copy.partition_S(%43, %view_82, %coord_161) : (!copy_simt, !memref_gmem_f32_1, !cute.coord<"?">) -> !memref_gmem_f32_2
      %iter_163 = cute.get_iter(%src_partitioned_162) : !memref_gmem_f32_2
      %lay_164 = cute.get_layout(%src_partitioned) : !memref_gmem_f32_2
      %44 = cute.make_layout_like(%lay_164) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)"> to !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %rmem = cute.memref.alloca(%44) : !memref_rmem_f32_
      %iter_165 = cute.get_iter(%rmem) : !memref_rmem_f32_
      %iter_166 = cute.get_iter(%rmem) : !memref_rmem_f32_
      %lay_167 = cute.get_layout(%src_partitioned_159) : !memref_gmem_f32_2
      %45 = cute.make_layout_like(%lay_167) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)"> to !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %rmem_168 = cute.memref.alloca(%45) : !memref_rmem_f32_
      %iter_169 = cute.get_iter(%rmem_168) : !memref_rmem_f32_
      %iter_170 = cute.get_iter(%rmem_168) : !memref_rmem_f32_
      %lay_171 = cute.get_layout(%src_partitioned_162) : !memref_gmem_f32_2
      %46 = cute.make_layout_like(%lay_171) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)"> to !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %rmem_172 = cute.memref.alloca(%46) : !memref_rmem_f32_
      %iter_173 = cute.get_iter(%rmem_172) : !memref_rmem_f32_
      %iter_174 = cute.get_iter(%rmem_172) : !memref_rmem_f32_
      %coord_175 = cute.make_coord(%28) : (i32) -> !cute.coord<"?">
      %src_partitioned_176 = cute.tiled.copy.partition_S(%43, %view_89, %coord_175) : (!copy_simt, !cute.coord_tensor<"(?{div=16},?{div=128})", "(16,128):(1@0,1@1)">, !cute.coord<"?">) -> !cute.coord_tensor<"(?{div=4},?{div=4})", "((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">
      %iter_177 = cute.get_iter(%src_partitioned_176) : !cute.coord_tensor<"(?{div=4},?{div=4})", "((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">
      %e0_178, %e1_179 = cute.get_leaves(%iter_177) : !cute.int_tuple<"(?{div=4},?{div=4})">
      %47 = cute.get_scalars(%e0_178) : !cute.int_tuple<"?{div=4}">
      %48 = cute.get_scalars(%e1_179) : !cute.int_tuple<"?{div=4}">
      %lay_180 = cute.get_layout(%src_partitioned_176) : !cute.coord_tensor<"(?{div=4},?{div=4})", "((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">
      %49 = cute.get_shape(%lay_180) : (!cute.layout<"((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_181, %e1_182, %e2_183, %e3_184, %e4 = cute.get_leaves(%49) : !cute.shape<"((1,(4,4)),1,1)">
      %shape_185 = cute.make_shape() : () -> !cute.shape<"((1,(4,4)),1,1)">
      %lay_186 = cute.make_layout() : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %rmem_187 = cute.memref.alloca(%lay_186) : !memref_rmem_i8_
      %iter_188 = cute.get_iter(%rmem_187) : !memref_rmem_i8_
      %iter_189 = cute.get_iter(%rmem_187) : !memref_rmem_i8_
      %lay_190 = cute.get_layout(%rmem_187) : !memref_rmem_i8_
      %sz_191 = cute.size(%lay_190) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.int_tuple<"16">
      %e0_192 = cute.get_leaves(%sz_191) : !cute.int_tuple<"16">
      %c0_i32 = arith.constant 0 : i32
      %c16_i32 = arith.constant 16 : i32
      %c1_i32 = arith.constant 1 : i32
      %50 = scf.for %arg6 = %c0_i32 to %c16_i32 step %c1_i32 iter_args(%arg7 = %rmem_187) -> (!memref_rmem_i8_)  : i32 {
        %iter_302 = cute.get_iter(%arg7) : !memref_rmem_i8_
        %iter_303 = cute.get_iter(%arg7) : !memref_rmem_i8_
        %coord_304 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"?">
        %lay_305 = cute.get_layout(%src_partitioned_176) : !cute.coord_tensor<"(?{div=4},?{div=4})", "((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">
        %idx_306 = cute.crd2idx(%coord_304, %lay_305) : (!cute.coord<"?">, !cute.layout<"((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">) -> !cute.int_tuple<"(?,?)">
        %iter_307 = cute.get_iter(%src_partitioned_176) : !cute.coord_tensor<"(?{div=4},?{div=4})", "((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">
        %tup_308 = cute.add_offset(%iter_307, %idx_306) : (!cute.int_tuple<"(?{div=4},?{div=4})">, !cute.int_tuple<"(?,?)">) -> !cute.int_tuple<"(?,?)">
        %view_309 = cute.make_view(%tup_308) : !cute.coord_tensor<"(?,?)", "():()">
        %iter_310 = cute.get_iter(%view_309) : !cute.coord_tensor<"(?,?)", "():()">
        %e0_311, %e1_312 = cute.get_leaves(%iter_310) : !cute.int_tuple<"(?,?)">
        %63 = cute.get_scalars(%e0_311) : !cute.int_tuple<"?">
        %64 = cute.get_scalars(%e1_312) : !cute.int_tuple<"?">
        %iter_313 = cute.get_iter(%view_309) : !cute.coord_tensor<"(?,?)", "():()">
        %e0_314, %e1_315 = cute.get_leaves(%iter_313) : !cute.int_tuple<"(?,?)">
        %65 = cute.get_scalars(%e0_314) : !cute.int_tuple<"?">
        %66 = cute.get_scalars(%e1_315) : !cute.int_tuple<"?">
        %iter_316 = cute.get_iter(%view_309) : !cute.coord_tensor<"(?,?)", "():()">
        %e0_317, %e1_318 = cute.get_leaves(%iter_316) : !cute.int_tuple<"(?,?)">
        %67 = cute.get_scalars(%e0_317) : !cute.int_tuple<"?">
        %68 = cute.get_scalars(%e1_318) : !cute.int_tuple<"?">
        %coord_319 = cute.make_coord(%e0_317, %e1_318) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
        %coord_320 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
        %69 = cute.elem_less(%coord_319, %coord_320) : !cute.coord<"(?,?)">, !cute.coord<"(?,?)">
        %70 = arith.extui %69 : i1 to i8
        %coord_321 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"?">
        cute.memref.store(%arg7, %coord_321, %70) : (!memref_rmem_i8_, !cute.coord<"?">, i8) -> ()
        scf.yield %arg7 : !memref_rmem_i8_
      }
      %iter_193 = cute.get_iter(%50) : !memref_rmem_i8_
      %iter_194 = cute.get_iter(%50) : !memref_rmem_i8_
      %iter_195 = cute.get_iter(%50) : !memref_rmem_i8_
      %false = arith.constant false
      scf.if %false {
        %c0_i32_302 = arith.constant 0 : i32
        %c10_i32_303 = arith.constant 10 : i32
        %c1_i32_304 = arith.constant 1 : i32
        scf.for %arg6 = %c0_i32_302 to %c10_i32_303 step %c1_i32_304  : i32 {
          %lay_305 = cute.get_layout(%src_partitioned) : !memref_gmem_f32_2
          %63 = cute.get_shape(%lay_305) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_306, %e1_307, %e2_308, %e3_309, %e4_310 = cute.get_leaves(%63) : !cute.shape<"((1,(4,4)),1,1)">
          %lay_311 = cute.get_layout(%rmem) : !memref_rmem_f32_
          %64 = cute.get_shape(%lay_311) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_312, %e1_313, %e2_314, %e3_315, %e4_316 = cute.get_leaves(%64) : !cute.shape<"((1,(4,4)),1,1)">
          %lay_317 = cute.get_layout(%src_partitioned) : !memref_gmem_f32_2
          %shape_318 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_319 = cute.make_layout() : !cute.layout<"1:0">
          %append_320 = cute.append_to_rank<2> (%lay_317, %lay_319) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">
          %view_321 = cute.make_view(%iter_157, %append_320) : !memref_gmem_f32_2
          %iter_322 = cute.get_iter(%view_321) : !memref_gmem_f32_2
          %lay_323 = cute.get_layout(%view_321) : !memref_gmem_f32_2
          %65 = cute.get_shape(%lay_323) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_324, %e1_325, %e2_326, %e3_327, %e4_328 = cute.get_leaves(%65) : !cute.shape<"((1,(4,4)),1,1)">
          %iter_329 = cute.get_iter(%view_321) : !memref_gmem_f32_2
          %lay_330 = cute.get_layout(%view_321) : !memref_gmem_f32_2
          %66 = cute.get_scalars(%lay_330) <{only_dynamic}> : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
          %shape_331 = cute.make_shape() : () -> !cute.shape<"((1,(4,4)),(1,1))">
          %stride_332 = cute.make_stride(%66) : (i64) -> !cute.stride<"((0,(1,?{i64})),(0,0))">
          %lay_333 = cute.make_layout(%shape_331, %stride_332) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
          %view_334 = cute.make_view(%iter_329, %lay_333) : !memref_gmem_f32_3
          %iter_335 = cute.get_iter(%view_334) : !memref_gmem_f32_3
          %iter_336 = cute.get_iter(%view_334) : !memref_gmem_f32_3
          %lay_337 = cute.get_layout(%rmem) : !memref_rmem_f32_
          %shape_338 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_339 = cute.make_layout() : !cute.layout<"1:0">
          %append_340 = cute.append_to_rank<2> (%lay_337, %lay_339) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
          %view_341 = cute.make_view(%iter_166, %append_340) : !memref_rmem_f32_
          %iter_342 = cute.get_iter(%view_341) : !memref_rmem_f32_
          %lay_343 = cute.get_layout(%view_341) : !memref_rmem_f32_
          %67 = cute.get_shape(%lay_343) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_344, %e1_345, %e2_346, %e3_347, %e4_348 = cute.get_leaves(%67) : !cute.shape<"((1,(4,4)),1,1)">
          %iter_349 = cute.get_iter(%view_341) : !memref_rmem_f32_
          %view_350 = cute.make_view(%iter_349) : !memref_rmem_f32_1
          %iter_351 = cute.get_iter(%view_350) : !memref_rmem_f32_1
          %iter_352 = cute.get_iter(%view_350) : !memref_rmem_f32_1
          %lay_353 = cute.get_layout(%50) : !memref_rmem_i8_
          %shape_354 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_355 = cute.make_layout() : !cute.layout<"1:0">
          %append_356 = cute.append_to_rank<2> (%lay_353, %lay_355) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
          %view_357 = cute.make_view(%iter_195, %append_356) : !memref_rmem_i8_
          %iter_358 = cute.get_iter(%view_357) : !memref_rmem_i8_
          %lay_359 = cute.get_layout(%view_357) : !memref_rmem_i8_
          %68 = cute.get_shape(%lay_359) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_360, %e1_361, %e2_362, %e3_363, %e4_364 = cute.get_leaves(%68) : !cute.shape<"((1,(4,4)),1,1)">
          %iter_365 = cute.get_iter(%view_357) : !memref_rmem_i8_
          %view_366 = cute.make_view(%iter_365) : !memref_rmem_i8_1
          %iter_367 = cute.get_iter(%view_366) : !memref_rmem_i8_1
          %iter_368 = cute.get_iter(%view_366) : !memref_rmem_i8_1
          %lay_369 = cute.get_layout(%view_334) : !memref_gmem_f32_3
          %69 = cute.get_shape(%lay_369) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
          %e0_370, %e1_371, %e2_372, %e3_373, %e4_374 = cute.get_leaves(%69) : !cute.shape<"((1,(4,4)),(1,1))">
          %lay_375 = cute.get_layout(%view_350) : !memref_rmem_f32_1
          %70 = cute.get_shape(%lay_375) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
          %e0_376, %e1_377, %e2_378, %e3_379, %e4_380 = cute.get_leaves(%70) : !cute.shape<"((1,(4,4)),(1,1))">
          %lay_381 = cute.get_layout(%view_334) : !memref_gmem_f32_3
          %sz_382 = cute.size(%lay_381) <{mode = [1]}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.int_tuple<"1">
          %e0_383 = cute.get_leaves(%sz_382) : !cute.int_tuple<"1">
          %lay_384 = cute.get_layout(%view_350) : !memref_rmem_f32_1
          %sz_385 = cute.size(%lay_384) <{mode = [1]}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.int_tuple<"1">
          %e0_386 = cute.get_leaves(%sz_385) : !cute.int_tuple<"1">
          %71 = cute.static : !cute.layout<"1:0">
          %iter_387 = cute.get_iter(%view_334) : !memref_gmem_f32_3
          %iter_388 = cute.get_iter(%view_350) : !memref_rmem_f32_1
          %lay_389 = cute.get_layout(%view_334) : !memref_gmem_f32_3
          %lay_390 = cute.get_layout(%view_350) : !memref_rmem_f32_1
          %append_391 = cute.append_to_rank<2> (%lay_389, %71) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">, !cute.layout<"1:0">
          %append_392 = cute.append_to_rank<2> (%lay_390, %71) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">, !cute.layout<"1:0">
          %72 = cute.get_scalars(%append_391) <{only_dynamic}> : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
          %shape_393 = cute.make_shape() : () -> !cute.shape<"((1,(4,4)),((1,1)))">
          %stride_394 = cute.make_stride(%72) : (i64) -> !cute.stride<"((0,(1,?{i64})),((0,0)))">
          %lay_395 = cute.make_layout(%shape_393, %stride_394) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
          %lay_396 = cute.make_layout() : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">
          %iter_397 = cute.get_iter(%view_366) : !memref_rmem_i8_1
          %lay_398 = cute.get_layout(%view_366) : !memref_rmem_i8_1
          %append_399 = cute.append_to_rank<2> (%lay_398, %71) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">, !cute.layout<"1:0">
          %lay_400 = cute.make_layout() : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">
          %sz_401 = cute.size(%lay_395) <{mode = [1]}> : (!cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">) -> !cute.int_tuple<"1">
          %73 = cute.get_scalars(%sz_401) : !cute.int_tuple<"1">
          %c0_i32_402 = arith.constant 0 : i32
          %c1_i32_403 = arith.constant 1 : i32
          scf.for %arg7 = %c0_i32_402 to %73 step %c1_i32_403  : i32 {
            %coord_503 = cute.make_coord(%arg7) : (i32) -> !cute.coord<"(_,?)">
            %slice_504 = cute.slice(%lay_395, %coord_503) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">, !cute.coord<"(_,?)">
            %idx_505 = cute.crd2idx(%coord_503, %lay_395) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">) -> !cute.int_tuple<"0">
            %ptr_506 = cute.add_offset(%iter_387, %idx_505) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<f32, gmem>
            %view_507 = cute.make_view(%ptr_506, %slice_504) : !memref_gmem_f32_4
            %slice_508 = cute.slice(%lay_396, %coord_503) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">, !cute.coord<"(_,?)">
            %idx_509 = cute.crd2idx(%coord_503, %lay_396) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">) -> !cute.int_tuple<"0">
            %ptr_510 = cute.add_offset(%iter_388, %idx_509) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, rmem, align<32>>
            %view_511 = cute.make_view(%ptr_510, %slice_508) : !memref_rmem_f32_2
            %slice_512 = cute.slice(%lay_400, %coord_503) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">, !cute.coord<"(_,?)">
            %idx_513 = cute.crd2idx(%coord_503, %lay_400) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">) -> !cute.int_tuple<"0">
            %ptr_514 = cute.add_offset(%iter_397, %idx_513) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
            %view_515 = cute.make_view(%ptr_514, %slice_512) : !memref_rmem_i8_2
            cute.copy_atom_call(%atom, %view_507, %view_511, %view_515) : (!cute_nvgpu.atom.universal_copy<f32>, !memref_gmem_f32_4, !memref_rmem_f32_2, !memref_rmem_i8_2) -> ()
          } {llvm.loop_annotation = #loop_annotation}
          %lay_404 = cute.get_layout(%src_partitioned_159) : !memref_gmem_f32_2
          %74 = cute.get_shape(%lay_404) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_405, %e1_406, %e2_407, %e3_408, %e4_409 = cute.get_leaves(%74) : !cute.shape<"((1,(4,4)),1,1)">
          %lay_410 = cute.get_layout(%rmem_168) : !memref_rmem_f32_
          %75 = cute.get_shape(%lay_410) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_411, %e1_412, %e2_413, %e3_414, %e4_415 = cute.get_leaves(%75) : !cute.shape<"((1,(4,4)),1,1)">
          %lay_416 = cute.get_layout(%src_partitioned_159) : !memref_gmem_f32_2
          %shape_417 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_418 = cute.make_layout() : !cute.layout<"1:0">
          %append_419 = cute.append_to_rank<2> (%lay_416, %lay_418) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">
          %view_420 = cute.make_view(%iter_160, %append_419) : !memref_gmem_f32_2
          %iter_421 = cute.get_iter(%view_420) : !memref_gmem_f32_2
          %lay_422 = cute.get_layout(%view_420) : !memref_gmem_f32_2
          %76 = cute.get_shape(%lay_422) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_423, %e1_424, %e2_425, %e3_426, %e4_427 = cute.get_leaves(%76) : !cute.shape<"((1,(4,4)),1,1)">
          %iter_428 = cute.get_iter(%view_420) : !memref_gmem_f32_2
          %lay_429 = cute.get_layout(%view_420) : !memref_gmem_f32_2
          %77 = cute.get_scalars(%lay_429) <{only_dynamic}> : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
          %shape_430 = cute.make_shape() : () -> !cute.shape<"((1,(4,4)),(1,1))">
          %stride_431 = cute.make_stride(%77) : (i64) -> !cute.stride<"((0,(1,?{i64})),(0,0))">
          %lay_432 = cute.make_layout(%shape_430, %stride_431) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
          %view_433 = cute.make_view(%iter_428, %lay_432) : !memref_gmem_f32_3
          %iter_434 = cute.get_iter(%view_433) : !memref_gmem_f32_3
          %iter_435 = cute.get_iter(%view_433) : !memref_gmem_f32_3
          %lay_436 = cute.get_layout(%rmem_168) : !memref_rmem_f32_
          %shape_437 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_438 = cute.make_layout() : !cute.layout<"1:0">
          %append_439 = cute.append_to_rank<2> (%lay_436, %lay_438) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
          %view_440 = cute.make_view(%iter_170, %append_439) : !memref_rmem_f32_
          %iter_441 = cute.get_iter(%view_440) : !memref_rmem_f32_
          %lay_442 = cute.get_layout(%view_440) : !memref_rmem_f32_
          %78 = cute.get_shape(%lay_442) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_443, %e1_444, %e2_445, %e3_446, %e4_447 = cute.get_leaves(%78) : !cute.shape<"((1,(4,4)),1,1)">
          %iter_448 = cute.get_iter(%view_440) : !memref_rmem_f32_
          %view_449 = cute.make_view(%iter_448) : !memref_rmem_f32_1
          %iter_450 = cute.get_iter(%view_449) : !memref_rmem_f32_1
          %iter_451 = cute.get_iter(%view_449) : !memref_rmem_f32_1
          %lay_452 = cute.get_layout(%50) : !memref_rmem_i8_
          %shape_453 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_454 = cute.make_layout() : !cute.layout<"1:0">
          %append_455 = cute.append_to_rank<2> (%lay_452, %lay_454) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
          %view_456 = cute.make_view(%iter_195, %append_455) : !memref_rmem_i8_
          %iter_457 = cute.get_iter(%view_456) : !memref_rmem_i8_
          %lay_458 = cute.get_layout(%view_456) : !memref_rmem_i8_
          %79 = cute.get_shape(%lay_458) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_459, %e1_460, %e2_461, %e3_462, %e4_463 = cute.get_leaves(%79) : !cute.shape<"((1,(4,4)),1,1)">
          %iter_464 = cute.get_iter(%view_456) : !memref_rmem_i8_
          %view_465 = cute.make_view(%iter_464) : !memref_rmem_i8_1
          %iter_466 = cute.get_iter(%view_465) : !memref_rmem_i8_1
          %iter_467 = cute.get_iter(%view_465) : !memref_rmem_i8_1
          %lay_468 = cute.get_layout(%view_433) : !memref_gmem_f32_3
          %80 = cute.get_shape(%lay_468) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
          %e0_469, %e1_470, %e2_471, %e3_472, %e4_473 = cute.get_leaves(%80) : !cute.shape<"((1,(4,4)),(1,1))">
          %lay_474 = cute.get_layout(%view_449) : !memref_rmem_f32_1
          %81 = cute.get_shape(%lay_474) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
          %e0_475, %e1_476, %e2_477, %e3_478, %e4_479 = cute.get_leaves(%81) : !cute.shape<"((1,(4,4)),(1,1))">
          %lay_480 = cute.get_layout(%view_433) : !memref_gmem_f32_3
          %sz_481 = cute.size(%lay_480) <{mode = [1]}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.int_tuple<"1">
          %e0_482 = cute.get_leaves(%sz_481) : !cute.int_tuple<"1">
          %lay_483 = cute.get_layout(%view_449) : !memref_rmem_f32_1
          %sz_484 = cute.size(%lay_483) <{mode = [1]}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.int_tuple<"1">
          %e0_485 = cute.get_leaves(%sz_484) : !cute.int_tuple<"1">
          %82 = cute.static : !cute.layout<"1:0">
          %iter_486 = cute.get_iter(%view_433) : !memref_gmem_f32_3
          %iter_487 = cute.get_iter(%view_449) : !memref_rmem_f32_1
          %lay_488 = cute.get_layout(%view_433) : !memref_gmem_f32_3
          %lay_489 = cute.get_layout(%view_449) : !memref_rmem_f32_1
          %append_490 = cute.append_to_rank<2> (%lay_488, %82) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">, !cute.layout<"1:0">
          %append_491 = cute.append_to_rank<2> (%lay_489, %82) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">, !cute.layout<"1:0">
          %83 = cute.get_scalars(%append_490) <{only_dynamic}> : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
          %shape_492 = cute.make_shape() : () -> !cute.shape<"((1,(4,4)),((1,1)))">
          %stride_493 = cute.make_stride(%83) : (i64) -> !cute.stride<"((0,(1,?{i64})),((0,0)))">
          %lay_494 = cute.make_layout(%shape_492, %stride_493) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
          %lay_495 = cute.make_layout() : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">
          %iter_496 = cute.get_iter(%view_465) : !memref_rmem_i8_1
          %lay_497 = cute.get_layout(%view_465) : !memref_rmem_i8_1
          %append_498 = cute.append_to_rank<2> (%lay_497, %82) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">, !cute.layout<"1:0">
          %lay_499 = cute.make_layout() : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">
          %sz_500 = cute.size(%lay_494) <{mode = [1]}> : (!cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">) -> !cute.int_tuple<"1">
          %84 = cute.get_scalars(%sz_500) : !cute.int_tuple<"1">
          %c0_i32_501 = arith.constant 0 : i32
          %c1_i32_502 = arith.constant 1 : i32
          scf.for %arg7 = %c0_i32_501 to %84 step %c1_i32_502  : i32 {
            %coord_503 = cute.make_coord(%arg7) : (i32) -> !cute.coord<"(_,?)">
            %slice_504 = cute.slice(%lay_494, %coord_503) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">, !cute.coord<"(_,?)">
            %idx_505 = cute.crd2idx(%coord_503, %lay_494) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">) -> !cute.int_tuple<"0">
            %ptr_506 = cute.add_offset(%iter_486, %idx_505) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<f32, gmem>
            %view_507 = cute.make_view(%ptr_506, %slice_504) : !memref_gmem_f32_4
            %slice_508 = cute.slice(%lay_495, %coord_503) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">, !cute.coord<"(_,?)">
            %idx_509 = cute.crd2idx(%coord_503, %lay_495) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">) -> !cute.int_tuple<"0">
            %ptr_510 = cute.add_offset(%iter_487, %idx_509) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, rmem, align<32>>
            %view_511 = cute.make_view(%ptr_510, %slice_508) : !memref_rmem_f32_2
            %slice_512 = cute.slice(%lay_499, %coord_503) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">, !cute.coord<"(_,?)">
            %idx_513 = cute.crd2idx(%coord_503, %lay_499) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">) -> !cute.int_tuple<"0">
            %ptr_514 = cute.add_offset(%iter_496, %idx_513) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
            %view_515 = cute.make_view(%ptr_514, %slice_512) : !memref_rmem_i8_2
            cute.copy_atom_call(%atom, %view_507, %view_511, %view_515) : (!cute_nvgpu.atom.universal_copy<f32>, !memref_gmem_f32_4, !memref_rmem_f32_2, !memref_rmem_i8_2) -> ()
          } {llvm.loop_annotation = #loop_annotation}
        }
        llvm.inline_asm has_side_effects asm_dialect = att "griddepcontrol.launch_dependents;", ""  : () -> ()
      } else {
        %c0_i32_302 = arith.constant 0 : i32
        %c10_i32_303 = arith.constant 10 : i32
        %c1_i32_304 = arith.constant 1 : i32
        scf.for %arg6 = %c0_i32_302 to %c10_i32_303 step %c1_i32_304  : i32 {
          %lay_305 = cute.get_layout(%src_partitioned_159) : !memref_gmem_f32_2
          %63 = cute.get_shape(%lay_305) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_306, %e1_307, %e2_308, %e3_309, %e4_310 = cute.get_leaves(%63) : !cute.shape<"((1,(4,4)),1,1)">
          %lay_311 = cute.get_layout(%rmem_168) : !memref_rmem_f32_
          %64 = cute.get_shape(%lay_311) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_312, %e1_313, %e2_314, %e3_315, %e4_316 = cute.get_leaves(%64) : !cute.shape<"((1,(4,4)),1,1)">
          %lay_317 = cute.get_layout(%src_partitioned_159) : !memref_gmem_f32_2
          %shape_318 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_319 = cute.make_layout() : !cute.layout<"1:0">
          %append_320 = cute.append_to_rank<2> (%lay_317, %lay_319) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">
          %view_321 = cute.make_view(%iter_160, %append_320) : !memref_gmem_f32_2
          %iter_322 = cute.get_iter(%view_321) : !memref_gmem_f32_2
          %lay_323 = cute.get_layout(%view_321) : !memref_gmem_f32_2
          %65 = cute.get_shape(%lay_323) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_324, %e1_325, %e2_326, %e3_327, %e4_328 = cute.get_leaves(%65) : !cute.shape<"((1,(4,4)),1,1)">
          %iter_329 = cute.get_iter(%view_321) : !memref_gmem_f32_2
          %lay_330 = cute.get_layout(%view_321) : !memref_gmem_f32_2
          %66 = cute.get_scalars(%lay_330) <{only_dynamic}> : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
          %shape_331 = cute.make_shape() : () -> !cute.shape<"((1,(4,4)),(1,1))">
          %stride_332 = cute.make_stride(%66) : (i64) -> !cute.stride<"((0,(1,?{i64})),(0,0))">
          %lay_333 = cute.make_layout(%shape_331, %stride_332) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
          %view_334 = cute.make_view(%iter_329, %lay_333) : !memref_gmem_f32_3
          %iter_335 = cute.get_iter(%view_334) : !memref_gmem_f32_3
          %iter_336 = cute.get_iter(%view_334) : !memref_gmem_f32_3
          %lay_337 = cute.get_layout(%rmem_168) : !memref_rmem_f32_
          %shape_338 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_339 = cute.make_layout() : !cute.layout<"1:0">
          %append_340 = cute.append_to_rank<2> (%lay_337, %lay_339) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
          %view_341 = cute.make_view(%iter_170, %append_340) : !memref_rmem_f32_
          %iter_342 = cute.get_iter(%view_341) : !memref_rmem_f32_
          %lay_343 = cute.get_layout(%view_341) : !memref_rmem_f32_
          %67 = cute.get_shape(%lay_343) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_344, %e1_345, %e2_346, %e3_347, %e4_348 = cute.get_leaves(%67) : !cute.shape<"((1,(4,4)),1,1)">
          %iter_349 = cute.get_iter(%view_341) : !memref_rmem_f32_
          %view_350 = cute.make_view(%iter_349) : !memref_rmem_f32_1
          %iter_351 = cute.get_iter(%view_350) : !memref_rmem_f32_1
          %iter_352 = cute.get_iter(%view_350) : !memref_rmem_f32_1
          %lay_353 = cute.get_layout(%50) : !memref_rmem_i8_
          %shape_354 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_355 = cute.make_layout() : !cute.layout<"1:0">
          %append_356 = cute.append_to_rank<2> (%lay_353, %lay_355) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
          %view_357 = cute.make_view(%iter_195, %append_356) : !memref_rmem_i8_
          %iter_358 = cute.get_iter(%view_357) : !memref_rmem_i8_
          %lay_359 = cute.get_layout(%view_357) : !memref_rmem_i8_
          %68 = cute.get_shape(%lay_359) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_360, %e1_361, %e2_362, %e3_363, %e4_364 = cute.get_leaves(%68) : !cute.shape<"((1,(4,4)),1,1)">
          %iter_365 = cute.get_iter(%view_357) : !memref_rmem_i8_
          %view_366 = cute.make_view(%iter_365) : !memref_rmem_i8_1
          %iter_367 = cute.get_iter(%view_366) : !memref_rmem_i8_1
          %iter_368 = cute.get_iter(%view_366) : !memref_rmem_i8_1
          %lay_369 = cute.get_layout(%view_334) : !memref_gmem_f32_3
          %69 = cute.get_shape(%lay_369) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
          %e0_370, %e1_371, %e2_372, %e3_373, %e4_374 = cute.get_leaves(%69) : !cute.shape<"((1,(4,4)),(1,1))">
          %lay_375 = cute.get_layout(%view_350) : !memref_rmem_f32_1
          %70 = cute.get_shape(%lay_375) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
          %e0_376, %e1_377, %e2_378, %e3_379, %e4_380 = cute.get_leaves(%70) : !cute.shape<"((1,(4,4)),(1,1))">
          %lay_381 = cute.get_layout(%view_334) : !memref_gmem_f32_3
          %sz_382 = cute.size(%lay_381) <{mode = [1]}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.int_tuple<"1">
          %e0_383 = cute.get_leaves(%sz_382) : !cute.int_tuple<"1">
          %lay_384 = cute.get_layout(%view_350) : !memref_rmem_f32_1
          %sz_385 = cute.size(%lay_384) <{mode = [1]}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.int_tuple<"1">
          %e0_386 = cute.get_leaves(%sz_385) : !cute.int_tuple<"1">
          %71 = cute.static : !cute.layout<"1:0">
          %iter_387 = cute.get_iter(%view_334) : !memref_gmem_f32_3
          %iter_388 = cute.get_iter(%view_350) : !memref_rmem_f32_1
          %lay_389 = cute.get_layout(%view_334) : !memref_gmem_f32_3
          %lay_390 = cute.get_layout(%view_350) : !memref_rmem_f32_1
          %append_391 = cute.append_to_rank<2> (%lay_389, %71) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">, !cute.layout<"1:0">
          %append_392 = cute.append_to_rank<2> (%lay_390, %71) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">, !cute.layout<"1:0">
          %72 = cute.get_scalars(%append_391) <{only_dynamic}> : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
          %shape_393 = cute.make_shape() : () -> !cute.shape<"((1,(4,4)),((1,1)))">
          %stride_394 = cute.make_stride(%72) : (i64) -> !cute.stride<"((0,(1,?{i64})),((0,0)))">
          %lay_395 = cute.make_layout(%shape_393, %stride_394) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
          %lay_396 = cute.make_layout() : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">
          %iter_397 = cute.get_iter(%view_366) : !memref_rmem_i8_1
          %lay_398 = cute.get_layout(%view_366) : !memref_rmem_i8_1
          %append_399 = cute.append_to_rank<2> (%lay_398, %71) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">, !cute.layout<"1:0">
          %lay_400 = cute.make_layout() : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">
          %sz_401 = cute.size(%lay_395) <{mode = [1]}> : (!cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">) -> !cute.int_tuple<"1">
          %73 = cute.get_scalars(%sz_401) : !cute.int_tuple<"1">
          %c0_i32_402 = arith.constant 0 : i32
          %c1_i32_403 = arith.constant 1 : i32
          scf.for %arg7 = %c0_i32_402 to %73 step %c1_i32_403  : i32 {
            %coord_404 = cute.make_coord(%arg7) : (i32) -> !cute.coord<"(_,?)">
            %slice_405 = cute.slice(%lay_395, %coord_404) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">, !cute.coord<"(_,?)">
            %idx_406 = cute.crd2idx(%coord_404, %lay_395) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">) -> !cute.int_tuple<"0">
            %ptr_407 = cute.add_offset(%iter_387, %idx_406) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<f32, gmem>
            %view_408 = cute.make_view(%ptr_407, %slice_405) : !memref_gmem_f32_4
            %slice_409 = cute.slice(%lay_396, %coord_404) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">, !cute.coord<"(_,?)">
            %idx_410 = cute.crd2idx(%coord_404, %lay_396) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">) -> !cute.int_tuple<"0">
            %ptr_411 = cute.add_offset(%iter_388, %idx_410) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, rmem, align<32>>
            %view_412 = cute.make_view(%ptr_411, %slice_409) : !memref_rmem_f32_2
            %slice_413 = cute.slice(%lay_400, %coord_404) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">, !cute.coord<"(_,?)">
            %idx_414 = cute.crd2idx(%coord_404, %lay_400) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">) -> !cute.int_tuple<"0">
            %ptr_415 = cute.add_offset(%iter_397, %idx_414) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
            %view_416 = cute.make_view(%ptr_415, %slice_413) : !memref_rmem_i8_2
            cute.copy_atom_call(%atom, %view_408, %view_412, %view_416) : (!cute_nvgpu.atom.universal_copy<f32>, !memref_gmem_f32_4, !memref_rmem_f32_2, !memref_rmem_i8_2) -> ()
          } {llvm.loop_annotation = #loop_annotation}
        }
        llvm.inline_asm has_side_effects asm_dialect = att "griddepcontrol.wait;", ""  : () -> ()
        scf.for %arg6 = %c0_i32_302 to %c10_i32_303 step %c1_i32_304  : i32 {
          %lay_305 = cute.get_layout(%src_partitioned) : !memref_gmem_f32_2
          %63 = cute.get_shape(%lay_305) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_306, %e1_307, %e2_308, %e3_309, %e4_310 = cute.get_leaves(%63) : !cute.shape<"((1,(4,4)),1,1)">
          %lay_311 = cute.get_layout(%rmem) : !memref_rmem_f32_
          %64 = cute.get_shape(%lay_311) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_312, %e1_313, %e2_314, %e3_315, %e4_316 = cute.get_leaves(%64) : !cute.shape<"((1,(4,4)),1,1)">
          %lay_317 = cute.get_layout(%src_partitioned) : !memref_gmem_f32_2
          %shape_318 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_319 = cute.make_layout() : !cute.layout<"1:0">
          %append_320 = cute.append_to_rank<2> (%lay_317, %lay_319) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">
          %view_321 = cute.make_view(%iter_157, %append_320) : !memref_gmem_f32_2
          %iter_322 = cute.get_iter(%view_321) : !memref_gmem_f32_2
          %lay_323 = cute.get_layout(%view_321) : !memref_gmem_f32_2
          %65 = cute.get_shape(%lay_323) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_324, %e1_325, %e2_326, %e3_327, %e4_328 = cute.get_leaves(%65) : !cute.shape<"((1,(4,4)),1,1)">
          %iter_329 = cute.get_iter(%view_321) : !memref_gmem_f32_2
          %lay_330 = cute.get_layout(%view_321) : !memref_gmem_f32_2
          %66 = cute.get_scalars(%lay_330) <{only_dynamic}> : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
          %shape_331 = cute.make_shape() : () -> !cute.shape<"((1,(4,4)),(1,1))">
          %stride_332 = cute.make_stride(%66) : (i64) -> !cute.stride<"((0,(1,?{i64})),(0,0))">
          %lay_333 = cute.make_layout(%shape_331, %stride_332) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
          %view_334 = cute.make_view(%iter_329, %lay_333) : !memref_gmem_f32_3
          %iter_335 = cute.get_iter(%view_334) : !memref_gmem_f32_3
          %iter_336 = cute.get_iter(%view_334) : !memref_gmem_f32_3
          %lay_337 = cute.get_layout(%rmem) : !memref_rmem_f32_
          %shape_338 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_339 = cute.make_layout() : !cute.layout<"1:0">
          %append_340 = cute.append_to_rank<2> (%lay_337, %lay_339) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
          %view_341 = cute.make_view(%iter_166, %append_340) : !memref_rmem_f32_
          %iter_342 = cute.get_iter(%view_341) : !memref_rmem_f32_
          %lay_343 = cute.get_layout(%view_341) : !memref_rmem_f32_
          %67 = cute.get_shape(%lay_343) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_344, %e1_345, %e2_346, %e3_347, %e4_348 = cute.get_leaves(%67) : !cute.shape<"((1,(4,4)),1,1)">
          %iter_349 = cute.get_iter(%view_341) : !memref_rmem_f32_
          %view_350 = cute.make_view(%iter_349) : !memref_rmem_f32_1
          %iter_351 = cute.get_iter(%view_350) : !memref_rmem_f32_1
          %iter_352 = cute.get_iter(%view_350) : !memref_rmem_f32_1
          %lay_353 = cute.get_layout(%50) : !memref_rmem_i8_
          %shape_354 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_355 = cute.make_layout() : !cute.layout<"1:0">
          %append_356 = cute.append_to_rank<2> (%lay_353, %lay_355) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
          %view_357 = cute.make_view(%iter_195, %append_356) : !memref_rmem_i8_
          %iter_358 = cute.get_iter(%view_357) : !memref_rmem_i8_
          %lay_359 = cute.get_layout(%view_357) : !memref_rmem_i8_
          %68 = cute.get_shape(%lay_359) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_360, %e1_361, %e2_362, %e3_363, %e4_364 = cute.get_leaves(%68) : !cute.shape<"((1,(4,4)),1,1)">
          %iter_365 = cute.get_iter(%view_357) : !memref_rmem_i8_
          %view_366 = cute.make_view(%iter_365) : !memref_rmem_i8_1
          %iter_367 = cute.get_iter(%view_366) : !memref_rmem_i8_1
          %iter_368 = cute.get_iter(%view_366) : !memref_rmem_i8_1
          %lay_369 = cute.get_layout(%view_334) : !memref_gmem_f32_3
          %69 = cute.get_shape(%lay_369) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
          %e0_370, %e1_371, %e2_372, %e3_373, %e4_374 = cute.get_leaves(%69) : !cute.shape<"((1,(4,4)),(1,1))">
          %lay_375 = cute.get_layout(%view_350) : !memref_rmem_f32_1
          %70 = cute.get_shape(%lay_375) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
          %e0_376, %e1_377, %e2_378, %e3_379, %e4_380 = cute.get_leaves(%70) : !cute.shape<"((1,(4,4)),(1,1))">
          %lay_381 = cute.get_layout(%view_334) : !memref_gmem_f32_3
          %sz_382 = cute.size(%lay_381) <{mode = [1]}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.int_tuple<"1">
          %e0_383 = cute.get_leaves(%sz_382) : !cute.int_tuple<"1">
          %lay_384 = cute.get_layout(%view_350) : !memref_rmem_f32_1
          %sz_385 = cute.size(%lay_384) <{mode = [1]}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.int_tuple<"1">
          %e0_386 = cute.get_leaves(%sz_385) : !cute.int_tuple<"1">
          %71 = cute.static : !cute.layout<"1:0">
          %iter_387 = cute.get_iter(%view_334) : !memref_gmem_f32_3
          %iter_388 = cute.get_iter(%view_350) : !memref_rmem_f32_1
          %lay_389 = cute.get_layout(%view_334) : !memref_gmem_f32_3
          %lay_390 = cute.get_layout(%view_350) : !memref_rmem_f32_1
          %append_391 = cute.append_to_rank<2> (%lay_389, %71) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">, !cute.layout<"1:0">
          %append_392 = cute.append_to_rank<2> (%lay_390, %71) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">, !cute.layout<"1:0">
          %72 = cute.get_scalars(%append_391) <{only_dynamic}> : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
          %shape_393 = cute.make_shape() : () -> !cute.shape<"((1,(4,4)),((1,1)))">
          %stride_394 = cute.make_stride(%72) : (i64) -> !cute.stride<"((0,(1,?{i64})),((0,0)))">
          %lay_395 = cute.make_layout(%shape_393, %stride_394) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
          %lay_396 = cute.make_layout() : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">
          %iter_397 = cute.get_iter(%view_366) : !memref_rmem_i8_1
          %lay_398 = cute.get_layout(%view_366) : !memref_rmem_i8_1
          %append_399 = cute.append_to_rank<2> (%lay_398, %71) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">, !cute.layout<"1:0">
          %lay_400 = cute.make_layout() : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">
          %sz_401 = cute.size(%lay_395) <{mode = [1]}> : (!cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">) -> !cute.int_tuple<"1">
          %73 = cute.get_scalars(%sz_401) : !cute.int_tuple<"1">
          %c0_i32_402 = arith.constant 0 : i32
          %c1_i32_403 = arith.constant 1 : i32
          scf.for %arg7 = %c0_i32_402 to %73 step %c1_i32_403  : i32 {
            %coord_404 = cute.make_coord(%arg7) : (i32) -> !cute.coord<"(_,?)">
            %slice_405 = cute.slice(%lay_395, %coord_404) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">, !cute.coord<"(_,?)">
            %idx_406 = cute.crd2idx(%coord_404, %lay_395) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">) -> !cute.int_tuple<"0">
            %ptr_407 = cute.add_offset(%iter_387, %idx_406) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<f32, gmem>
            %view_408 = cute.make_view(%ptr_407, %slice_405) : !memref_gmem_f32_4
            %slice_409 = cute.slice(%lay_396, %coord_404) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">, !cute.coord<"(_,?)">
            %idx_410 = cute.crd2idx(%coord_404, %lay_396) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">) -> !cute.int_tuple<"0">
            %ptr_411 = cute.add_offset(%iter_388, %idx_410) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, rmem, align<32>>
            %view_412 = cute.make_view(%ptr_411, %slice_409) : !memref_rmem_f32_2
            %slice_413 = cute.slice(%lay_400, %coord_404) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">, !cute.coord<"(_,?)">
            %idx_414 = cute.crd2idx(%coord_404, %lay_400) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">) -> !cute.int_tuple<"0">
            %ptr_415 = cute.add_offset(%iter_397, %idx_414) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
            %view_416 = cute.make_view(%ptr_415, %slice_413) : !memref_rmem_i8_2
            cute.copy_atom_call(%atom, %view_408, %view_412, %view_416) : (!cute_nvgpu.atom.universal_copy<f32>, !memref_gmem_f32_4, !memref_rmem_f32_2, !memref_rmem_i8_2) -> ()
          } {llvm.loop_annotation = #loop_annotation}
        }
      }
      %c10_i32 = arith.constant 10 : i32
      %51:3 = scf.for %arg6 = %c0_i32 to %c10_i32 step %c1_i32 iter_args(%arg7 = %rmem, %arg8 = %rmem_168, %arg9 = %rmem_172) -> (!memref_rmem_f32_, !memref_rmem_f32_, !memref_rmem_f32_)  : i32 {
        %iter_302 = cute.get_iter(%arg7) : !memref_rmem_f32_
        %iter_303 = cute.get_iter(%arg8) : !memref_rmem_f32_
        %iter_304 = cute.get_iter(%arg9) : !memref_rmem_f32_
        %iter_305 = cute.get_iter(%arg7) : !memref_rmem_f32_
        %iter_306 = cute.get_iter(%arg8) : !memref_rmem_f32_
        %iter_307 = cute.get_iter(%arg9) : !memref_rmem_f32_
        %lay_308 = cute.get_layout(%arg7) : !memref_rmem_f32_
        %63 = cute.get_shape(%lay_308) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
        %e0_309, %e1_310, %e2_311, %e3_312, %e4_313 = cute.get_leaves(%63) : !cute.shape<"((1,(4,4)),1,1)">
        %64 = cute.memref.load_vec %arg7 : !memref_rmem_f32_
        %lay_314 = cute.get_layout(%arg8) : !memref_rmem_f32_
        %65 = cute.get_shape(%lay_314) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
        %e0_315, %e1_316, %e2_317, %e3_318, %e4_319 = cute.get_leaves(%65) : !cute.shape<"((1,(4,4)),1,1)">
        %66 = cute.memref.load_vec %arg8 : !memref_rmem_f32_
        %67 = arith.addf %64, %66 : vector<16xf32>
        %lay_320 = cute.get_layout(%arg9) : !memref_rmem_f32_
        %68 = cute.get_shape(%lay_320) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
        %e0_321, %e1_322, %e2_323, %e3_324, %e4_325 = cute.get_leaves(%68) : !cute.shape<"((1,(4,4)),1,1)">
        %int_tuple_326 = cute.make_int_tuple() : () -> !cute.int_tuple<"((1,(4,4)),1,1)">
        %sz_327 = cute.size(%int_tuple_326) : (!cute.int_tuple<"((1,(4,4)),1,1)">) -> !cute.int_tuple<"16">
        %e0_328 = cute.get_leaves(%sz_327) : !cute.int_tuple<"16">
        %int_tuple_329 = cute.make_int_tuple() : () -> !cute.int_tuple<"((1,(4,4)),1,1)">
        %sz_330 = cute.size(%int_tuple_329) : (!cute.int_tuple<"((1,(4,4)),1,1)">) -> !cute.int_tuple<"16">
        %e0_331 = cute.get_leaves(%sz_330) : !cute.int_tuple<"16">
        cute.memref.store_vec %67, %arg9 : !memref_rmem_f32_
        scf.yield %arg7, %arg8, %arg9 : !memref_rmem_f32_, !memref_rmem_f32_, !memref_rmem_f32_
      }
      %iter_196 = cute.get_iter(%51#0) : !memref_rmem_f32_
      %iter_197 = cute.get_iter(%51#1) : !memref_rmem_f32_
      %iter_198 = cute.get_iter(%51#2) : !memref_rmem_f32_
      %iter_199 = cute.get_iter(%51#0) : !memref_rmem_f32_
      %iter_200 = cute.get_iter(%51#0) : !memref_rmem_f32_
      %iter_201 = cute.get_iter(%51#1) : !memref_rmem_f32_
      %iter_202 = cute.get_iter(%51#1) : !memref_rmem_f32_
      %iter_203 = cute.get_iter(%51#2) : !memref_rmem_f32_
      %iter_204 = cute.get_iter(%51#2) : !memref_rmem_f32_
      %lay_205 = cute.get_layout(%51#2) : !memref_rmem_f32_
      %52 = cute.get_shape(%lay_205) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_206, %e1_207, %e2_208, %e3_209, %e4_210 = cute.get_leaves(%52) : !cute.shape<"((1,(4,4)),1,1)">
      %lay_211 = cute.get_layout(%src_partitioned_162) : !memref_gmem_f32_2
      %53 = cute.get_shape(%lay_211) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_212, %e1_213, %e2_214, %e3_215, %e4_216 = cute.get_leaves(%53) : !cute.shape<"((1,(4,4)),1,1)">
      %lay_217 = cute.get_layout(%51#2) : !memref_rmem_f32_
      %shape_218 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_219 = cute.make_layout() : !cute.layout<"1:0">
      %append = cute.append_to_rank<2> (%lay_217, %lay_219) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
      %view_220 = cute.make_view(%iter_204, %append) : !memref_rmem_f32_
      %iter_221 = cute.get_iter(%view_220) : !memref_rmem_f32_
      %lay_222 = cute.get_layout(%view_220) : !memref_rmem_f32_
      %54 = cute.get_shape(%lay_222) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_223, %e1_224, %e2_225, %e3_226, %e4_227 = cute.get_leaves(%54) : !cute.shape<"((1,(4,4)),1,1)">
      %iter_228 = cute.get_iter(%view_220) : !memref_rmem_f32_
      %view_229 = cute.make_view(%iter_228) : !memref_rmem_f32_1
      %iter_230 = cute.get_iter(%view_229) : !memref_rmem_f32_1
      %iter_231 = cute.get_iter(%view_229) : !memref_rmem_f32_1
      %lay_232 = cute.get_layout(%src_partitioned_162) : !memref_gmem_f32_2
      %shape_233 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_234 = cute.make_layout() : !cute.layout<"1:0">
      %append_235 = cute.append_to_rank<2> (%lay_232, %lay_234) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">
      %view_236 = cute.make_view(%iter_163, %append_235) : !memref_gmem_f32_2
      %iter_237 = cute.get_iter(%view_236) : !memref_gmem_f32_2
      %lay_238 = cute.get_layout(%view_236) : !memref_gmem_f32_2
      %55 = cute.get_shape(%lay_238) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_239, %e1_240, %e2_241, %e3_242, %e4_243 = cute.get_leaves(%55) : !cute.shape<"((1,(4,4)),1,1)">
      %iter_244 = cute.get_iter(%view_236) : !memref_gmem_f32_2
      %lay_245 = cute.get_layout(%view_236) : !memref_gmem_f32_2
      %56 = cute.get_scalars(%lay_245) <{only_dynamic}> : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %shape_246 = cute.make_shape() : () -> !cute.shape<"((1,(4,4)),(1,1))">
      %stride = cute.make_stride(%56) : (i64) -> !cute.stride<"((0,(1,?{i64})),(0,0))">
      %lay_247 = cute.make_layout(%shape_246, %stride) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %view_248 = cute.make_view(%iter_244, %lay_247) : !memref_gmem_f32_3
      %iter_249 = cute.get_iter(%view_248) : !memref_gmem_f32_3
      %iter_250 = cute.get_iter(%view_248) : !memref_gmem_f32_3
      %lay_251 = cute.get_layout(%50) : !memref_rmem_i8_
      %shape_252 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_253 = cute.make_layout() : !cute.layout<"1:0">
      %append_254 = cute.append_to_rank<2> (%lay_251, %lay_253) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
      %view_255 = cute.make_view(%iter_195, %append_254) : !memref_rmem_i8_
      %iter_256 = cute.get_iter(%view_255) : !memref_rmem_i8_
      %lay_257 = cute.get_layout(%view_255) : !memref_rmem_i8_
      %57 = cute.get_shape(%lay_257) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_258, %e1_259, %e2_260, %e3_261, %e4_262 = cute.get_leaves(%57) : !cute.shape<"((1,(4,4)),1,1)">
      %iter_263 = cute.get_iter(%view_255) : !memref_rmem_i8_
      %view_264 = cute.make_view(%iter_263) : !memref_rmem_i8_1
      %iter_265 = cute.get_iter(%view_264) : !memref_rmem_i8_1
      %iter_266 = cute.get_iter(%view_264) : !memref_rmem_i8_1
      %lay_267 = cute.get_layout(%view_229) : !memref_rmem_f32_1
      %58 = cute.get_shape(%lay_267) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
      %e0_268, %e1_269, %e2_270, %e3_271, %e4_272 = cute.get_leaves(%58) : !cute.shape<"((1,(4,4)),(1,1))">
      %lay_273 = cute.get_layout(%view_248) : !memref_gmem_f32_3
      %59 = cute.get_shape(%lay_273) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
      %e0_274, %e1_275, %e2_276, %e3_277, %e4_278 = cute.get_leaves(%59) : !cute.shape<"((1,(4,4)),(1,1))">
      %lay_279 = cute.get_layout(%view_229) : !memref_rmem_f32_1
      %sz_280 = cute.size(%lay_279) <{mode = [1]}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.int_tuple<"1">
      %e0_281 = cute.get_leaves(%sz_280) : !cute.int_tuple<"1">
      %lay_282 = cute.get_layout(%view_248) : !memref_gmem_f32_3
      %sz_283 = cute.size(%lay_282) <{mode = [1]}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.int_tuple<"1">
      %e0_284 = cute.get_leaves(%sz_283) : !cute.int_tuple<"1">
      %60 = cute.static : !cute.layout<"1:0">
      %iter_285 = cute.get_iter(%view_229) : !memref_rmem_f32_1
      %iter_286 = cute.get_iter(%view_248) : !memref_gmem_f32_3
      %lay_287 = cute.get_layout(%view_229) : !memref_rmem_f32_1
      %lay_288 = cute.get_layout(%view_248) : !memref_gmem_f32_3
      %append_289 = cute.append_to_rank<2> (%lay_287, %60) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">, !cute.layout<"1:0">
      %append_290 = cute.append_to_rank<2> (%lay_288, %60) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">, !cute.layout<"1:0">
      %lay_291 = cute.make_layout() : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">
      %61 = cute.get_scalars(%append_290) <{only_dynamic}> : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %shape_292 = cute.make_shape() : () -> !cute.shape<"((1,(4,4)),((1,1)))">
      %stride_293 = cute.make_stride(%61) : (i64) -> !cute.stride<"((0,(1,?{i64})),((0,0)))">
      %lay_294 = cute.make_layout(%shape_292, %stride_293) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
      %iter_295 = cute.get_iter(%view_264) : !memref_rmem_i8_1
      %lay_296 = cute.get_layout(%view_264) : !memref_rmem_i8_1
      %append_297 = cute.append_to_rank<2> (%lay_296, %60) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">, !cute.layout<"1:0">
      %lay_298 = cute.make_layout() : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">
      %sz_299 = cute.size(%lay_291) <{mode = [1]}> : (!cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">) -> !cute.int_tuple<"1">
      %62 = cute.get_scalars(%sz_299) : !cute.int_tuple<"1">
      %c0_i32_300 = arith.constant 0 : i32
      %c1_i32_301 = arith.constant 1 : i32
      scf.for %arg6 = %c0_i32_300 to %62 step %c1_i32_301  : i32 {
        %coord_302 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
        %slice_303 = cute.slice(%lay_291, %coord_302) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">, !cute.coord<"(_,?)">
        %idx_304 = cute.crd2idx(%coord_302, %lay_291) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">) -> !cute.int_tuple<"0">
        %ptr_305 = cute.add_offset(%iter_285, %idx_304) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, rmem, align<32>>
        %view_306 = cute.make_view(%ptr_305, %slice_303) : !memref_rmem_f32_2
        %slice_307 = cute.slice(%lay_294, %coord_302) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">, !cute.coord<"(_,?)">
        %idx_308 = cute.crd2idx(%coord_302, %lay_294) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">) -> !cute.int_tuple<"0">
        %ptr_309 = cute.add_offset(%iter_286, %idx_308) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<f32, gmem>
        %view_310 = cute.make_view(%ptr_309, %slice_307) : !memref_gmem_f32_4
        %slice_311 = cute.slice(%lay_298, %coord_302) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">, !cute.coord<"(_,?)">
        %idx_312 = cute.crd2idx(%coord_302, %lay_298) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">) -> !cute.int_tuple<"0">
        %ptr_313 = cute.add_offset(%iter_295, %idx_312) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
        %view_314 = cute.make_view(%ptr_313, %slice_311) : !memref_rmem_i8_2
        cute.copy_atom_call(%atom_96, %view_306, %view_310, %view_314) : (!cute_nvgpu.atom.universal_copy<f32>, !memref_rmem_f32_2, !memref_gmem_f32_4, !memref_rmem_i8_2) -> ()
      } {llvm.loop_annotation = #loop_annotation}
      return
    }
  }
  func.func @cutlass_elementwise_add_Tensorgmem_o_i641_Tensorgmem_o_i641_Tensorgmem_o_i641_CUstream_False_False(%arg0: !memref_gmem_f32_5, %arg1: !memref_gmem_f32_5, %arg2: !memref_gmem_f32_5, %arg3: !cuda.stream) -> i32 attributes {llvm.emit_c_interface} {
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
    %tile = cute.make_tile() : () -> !cute.tile<"[16:1;128:1]">
    %iter_40 = cute.get_iter(%arg0) : !memref_gmem_f32_5
    %lay_41 = cute.get_layout(%arg0) : !memref_gmem_f32_5
    %16:3 = cute.get_scalars(%lay_41) <{only_dynamic}> : !cute.layout<"(?,?):(?{i64},1)">
    %c16_i32 = arith.constant 16 : i32
    %17 = arith.ceildivsi %16#0, %c16_i32 : i32
    %c16_i64 = arith.constant 16 : i64
    %18 = arith.muli %16#2, %c16_i64 : i64
    %c128_i32 = arith.constant 128 : i32
    %19 = arith.ceildivsi %16#1, %c128_i32 : i32
    %shape_42 = cute.make_shape(%17, %19) : (i32, i32) -> !cute.shape<"((16,128),(?,?))">
    %iv = cute.assume(%18) : (i64) -> !cute.i64<divby 16>
    %stride = cute.make_stride(%16#2, %iv) : (i64, !cute.i64<divby 16>) -> !cute.stride<"((?{i64},1),(?{i64 div=16},128))">
    %lay_43 = cute.make_layout(%shape_42, %stride) : !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
    %view = cute.make_view(%iter_40, %lay_43) : !memref_gmem_f32_
    %iter_44 = cute.get_iter(%view) : !memref_gmem_f32_
    %iter_45 = cute.get_iter(%view) : !memref_gmem_f32_
    %tile_46 = cute.make_tile() : () -> !cute.tile<"[16:1;128:1]">
    %iter_47 = cute.get_iter(%arg1) : !memref_gmem_f32_5
    %lay_48 = cute.get_layout(%arg1) : !memref_gmem_f32_5
    %20:3 = cute.get_scalars(%lay_48) <{only_dynamic}> : !cute.layout<"(?,?):(?{i64},1)">
    %c16_i32_49 = arith.constant 16 : i32
    %21 = arith.ceildivsi %20#0, %c16_i32_49 : i32
    %c16_i64_50 = arith.constant 16 : i64
    %22 = arith.muli %20#2, %c16_i64_50 : i64
    %c128_i32_51 = arith.constant 128 : i32
    %23 = arith.ceildivsi %20#1, %c128_i32_51 : i32
    %shape_52 = cute.make_shape(%21, %23) : (i32, i32) -> !cute.shape<"((16,128),(?,?))">
    %iv_53 = cute.assume(%22) : (i64) -> !cute.i64<divby 16>
    %stride_54 = cute.make_stride(%20#2, %iv_53) : (i64, !cute.i64<divby 16>) -> !cute.stride<"((?{i64},1),(?{i64 div=16},128))">
    %lay_55 = cute.make_layout(%shape_52, %stride_54) : !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
    %view_56 = cute.make_view(%iter_47, %lay_55) : !memref_gmem_f32_
    %iter_57 = cute.get_iter(%view_56) : !memref_gmem_f32_
    %iter_58 = cute.get_iter(%view_56) : !memref_gmem_f32_
    %tile_59 = cute.make_tile() : () -> !cute.tile<"[16:1;128:1]">
    %iter_60 = cute.get_iter(%arg2) : !memref_gmem_f32_5
    %lay_61 = cute.get_layout(%arg2) : !memref_gmem_f32_5
    %24:3 = cute.get_scalars(%lay_61) <{only_dynamic}> : !cute.layout<"(?,?):(?{i64},1)">
    %c16_i32_62 = arith.constant 16 : i32
    %25 = arith.ceildivsi %24#0, %c16_i32_62 : i32
    %c16_i64_63 = arith.constant 16 : i64
    %26 = arith.muli %24#2, %c16_i64_63 : i64
    %c128_i32_64 = arith.constant 128 : i32
    %27 = arith.ceildivsi %24#1, %c128_i32_64 : i32
    %shape_65 = cute.make_shape(%25, %27) : (i32, i32) -> !cute.shape<"((16,128),(?,?))">
    %iv_66 = cute.assume(%26) : (i64) -> !cute.i64<divby 16>
    %stride_67 = cute.make_stride(%24#2, %iv_66) : (i64, !cute.i64<divby 16>) -> !cute.stride<"((?{i64},1),(?{i64 div=16},128))">
    %lay_68 = cute.make_layout(%shape_65, %stride_67) : !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
    %view_69 = cute.make_view(%iter_60, %lay_68) : !memref_gmem_f32_
    %iter_70 = cute.get_iter(%view_69) : !memref_gmem_f32_
    %iter_71 = cute.get_iter(%view_69) : !memref_gmem_f32_
    %lay_72 = cute.get_layout(%arg2) : !memref_gmem_f32_5
    %28 = cute.get_shape(%lay_72) : (!cute.layout<"(?,?):(?{i64},1)">) -> !cute.shape<"(?,?)">
    %e0_73, %e1_74 = cute.get_leaves(%28) : !cute.shape<"(?,?)">
    %itup_75 = cute.to_int_tuple(%e0_73) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %29 = cute.get_scalars(%itup_75) : !cute.int_tuple<"?">
    %itup_76 = cute.to_int_tuple(%e1_74) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %30 = cute.get_scalars(%itup_76) : !cute.int_tuple<"?">
    %shape_77 = cute.make_shape(%itup_75, %itup_76) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.shape<"(?,?)">
    %31 = cute.make_identity_tensor(%shape_77) : !cute.coord_tensor<"(0,0)", "(?,?):(1@0,1@1)">
    %iter_78 = cute.get_iter(%31) : !cute.coord_tensor<"(0,0)", "(?,?):(1@0,1@1)">
    %e0_79, %e1_80 = cute.get_leaves(%iter_78) : !cute.int_tuple<"(0,0)">
    %tile_81 = cute.make_tile() : () -> !cute.tile<"[16:1;128:1]">
    %iter_82 = cute.get_iter(%31) : !cute.coord_tensor<"(0,0)", "(?,?):(1@0,1@1)">
    %lay_83 = cute.get_layout(%31) : !cute.coord_tensor<"(0,0)", "(?,?):(1@0,1@1)">
    %32:2 = cute.get_scalars(%lay_83) <{only_dynamic}> : !cute.layout<"(?,?):(1@0,1@1)">
    %c16_i32_84 = arith.constant 16 : i32
    %33 = arith.ceildivsi %32#0, %c16_i32_84 : i32
    %c128_i32_85 = arith.constant 128 : i32
    %34 = arith.ceildivsi %32#1, %c128_i32_85 : i32
    %shape_86 = cute.make_shape(%33, %34) : (i32, i32) -> !cute.shape<"((16,128),(?,?))">
    %stride_87 = cute.make_stride() : () -> !cute.stride<"((1@0,1@1),(16@0,128@1))">
    %lay_88 = cute.make_layout(%shape_86, %stride_87) : !cute.layout<"((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
    %view_89 = cute.make_view(%iter_82, %lay_88) : !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
    %iter_90 = cute.get_iter(%view_89) : !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
    %e0_91, %e1_92 = cute.get_leaves(%iter_90) : !cute.int_tuple<"(0,0)">
    %iter_93 = cute.get_iter(%view_89) : !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
    %e0_94, %e1_95 = cute.get_leaves(%iter_93) : !cute.int_tuple<"(0,0)">
    %lay_96 = cute.get_layout(%view_69) : !memref_gmem_f32_
    %sz_97 = cute.size(%lay_96) <{mode = [1]}> : (!cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.int_tuple<"?">
    %e0_98 = cute.get_leaves(%sz_97) : !cute.int_tuple<"?">
    %35 = cute.get_scalars(%e0_98) : !cute.int_tuple<"?">
    %sz_99 = cute.size(%lay_34) <{mode = [0]}> : (!cute.layout<"((32,4),(4,4)):((64,4),(16,1))">) -> !cute.int_tuple<"128">
    %e0_100 = cute.get_leaves(%sz_99) : !cute.int_tuple<"128">
    %lay_101 = cute.get_layout(%view) : !memref_gmem_f32_
    %36 = cute.get_shape(%lay_101) : (!cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.shape<"((16,128),(?,?))">
    %e0_102, %e1_103, %e2_104, %e3_105 = cute.get_leaves(%36) : !cute.shape<"((16,128),(?,?))">
    %itup_106 = cute.to_int_tuple(%e2_104) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %37 = cute.get_scalars(%itup_106) : !cute.int_tuple<"?">
    %itup_107 = cute.to_int_tuple(%e3_105) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %38 = cute.get_scalars(%itup_107) : !cute.int_tuple<"?">
    %39 = cute.get_stride(%lay_101) : (!cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.stride<"((?{i64},1),(?{i64 div=16},128))">
    %e0_108, %e1_109, %e2_110, %e3_111 = cute.get_leaves(%39) : !cute.stride<"((?{i64},1),(?{i64 div=16},128))">
    %itup_112 = cute.to_int_tuple(%e0_108) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
    %40 = cute.get_scalars(%itup_112) : !cute.int_tuple<"?{i64}">
    %itup_113 = cute.to_int_tuple(%e2_110) : !cute.stride<"?{i64 div=16}"> to !cute.int_tuple<"?{i64 div=16}">
    %41 = cute.get_scalars(%itup_113) : !cute.int_tuple<"?{i64 div=16}">
    %lay_114 = cute.get_layout(%view_56) : !memref_gmem_f32_
    %42 = cute.get_shape(%lay_114) : (!cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.shape<"((16,128),(?,?))">
    %e0_115, %e1_116, %e2_117, %e3_118 = cute.get_leaves(%42) : !cute.shape<"((16,128),(?,?))">
    %itup_119 = cute.to_int_tuple(%e2_117) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %43 = cute.get_scalars(%itup_119) : !cute.int_tuple<"?">
    %itup_120 = cute.to_int_tuple(%e3_118) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %44 = cute.get_scalars(%itup_120) : !cute.int_tuple<"?">
    %45 = cute.get_stride(%lay_114) : (!cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.stride<"((?{i64},1),(?{i64 div=16},128))">
    %e0_121, %e1_122, %e2_123, %e3_124 = cute.get_leaves(%45) : !cute.stride<"((?{i64},1),(?{i64 div=16},128))">
    %itup_125 = cute.to_int_tuple(%e0_121) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
    %46 = cute.get_scalars(%itup_125) : !cute.int_tuple<"?{i64}">
    %itup_126 = cute.to_int_tuple(%e2_123) : !cute.stride<"?{i64 div=16}"> to !cute.int_tuple<"?{i64 div=16}">
    %47 = cute.get_scalars(%itup_126) : !cute.int_tuple<"?{i64 div=16}">
    %lay_127 = cute.get_layout(%view_69) : !memref_gmem_f32_
    %48 = cute.get_shape(%lay_127) : (!cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.shape<"((16,128),(?,?))">
    %e0_128, %e1_129, %e2_130, %e3_131 = cute.get_leaves(%48) : !cute.shape<"((16,128),(?,?))">
    %itup_132 = cute.to_int_tuple(%e2_130) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %49 = cute.get_scalars(%itup_132) : !cute.int_tuple<"?">
    %itup_133 = cute.to_int_tuple(%e3_131) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %50 = cute.get_scalars(%itup_133) : !cute.int_tuple<"?">
    %51 = cute.get_stride(%lay_127) : (!cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.stride<"((?{i64},1),(?{i64 div=16},128))">
    %e0_134, %e1_135, %e2_136, %e3_137 = cute.get_leaves(%51) : !cute.stride<"((?{i64},1),(?{i64 div=16},128))">
    %itup_138 = cute.to_int_tuple(%e0_134) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
    %52 = cute.get_scalars(%itup_138) : !cute.int_tuple<"?{i64}">
    %itup_139 = cute.to_int_tuple(%e2_136) : !cute.stride<"?{i64 div=16}"> to !cute.int_tuple<"?{i64 div=16}">
    %53 = cute.get_scalars(%itup_139) : !cute.int_tuple<"?{i64 div=16}">
    %lay_140 = cute.get_layout(%view_89) : !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
    %54 = cute.get_shape(%lay_140) : (!cute.layout<"((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">) -> !cute.shape<"((16,128),(?,?))">
    %e0_141, %e1_142, %e2_143, %e3_144 = cute.get_leaves(%54) : !cute.shape<"((16,128),(?,?))">
    %itup_145 = cute.to_int_tuple(%e2_143) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %55 = cute.get_scalars(%itup_145) : !cute.int_tuple<"?">
    %itup_146 = cute.to_int_tuple(%e3_144) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %56 = cute.get_scalars(%itup_146) : !cute.int_tuple<"?">
    %57 = cute.get_stride(%lay_140) : (!cute.layout<"((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">) -> !cute.stride<"((1@0,1@1),(16@0,128@1))">
    %e0_147, %e1_148, %e2_149, %e3_150 = cute.get_leaves(%57) : !cute.stride<"((1@0,1@1),(16@0,128@1))">
    %58 = cute.get_shape(%lay_25) : (!cute.layout<"(4,32):(32,1)">) -> !cute.shape<"(4,32)">
    %e0_151, %e1_152 = cute.get_leaves(%58) : !cute.shape<"(4,32)">
    %59 = cute.get_stride(%lay_25) : (!cute.layout<"(4,32):(32,1)">) -> !cute.stride<"(32,1)">
    %e0_153, %e1_154 = cute.get_leaves(%59) : !cute.stride<"(32,1)">
    %60 = cute.get_shape(%lay_28) : (!cute.layout<"(4,4):(4,1)">) -> !cute.shape<"(4,4)">
    %e0_155, %e1_156 = cute.get_leaves(%60) : !cute.shape<"(4,4)">
    %61 = cute.get_stride(%lay_28) : (!cute.layout<"(4,4):(4,1)">) -> !cute.stride<"(4,1)">
    %e0_157, %e1_158 = cute.get_leaves(%61) : !cute.stride<"(4,1)">
    %c0_i32 = arith.constant 0 : i32
    %62 = arith.extsi %c0_i32 : i32 to i64
    %c128_i32_159 = arith.constant 128 : i32
    %c1_i32 = arith.constant 1 : i32
    %63 = cuda.launch_cfg.create<max_attrs = 2 : i32> (blockDim = (%c128_i32_159, %c1_i32, %c1_i32), dynamicSmemBytes = %62, gridDim = (%35, %c1_i32, %c1_i32), stream = %arg3) : i32, i32, i32, i64, i32, i32, i32, !cuda.stream -> !cuda.launch_cfg<max_attrs = 2>
    %64 = cuda.launch_ex @kernels::@kernel_cutlass_elementwise_add_kernel_tensorptrf32gmemo161281i64div16128_tensorptrf32gmemo161281i64div16128_tensorptrf32gmemo161281i64div16128_tensor00o1612810111601281___False_0<%63> (%view, %view_56, %view_69, %view_89, %29, %30) : !cuda.launch_cfg<max_attrs = 2>, (!memref_gmem_f32_, !memref_gmem_f32_, !memref_gmem_f32_, !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">, i32, i32) -> !cuda.result
    %65 = cuda.cast %64 : !cuda.result -> i32
    cuda.return_if_error %65 : i32
    %c0_i32_160 = arith.constant 0 : i32
    return %c0_i32_160 : i32
  }
}
