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
      %lay_193 = cute.get_layout(%rmem_187) : !memref_rmem_i8_
      %50 = cute.get_shape(%lay_193) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_194, %e1_195, %e2_196, %e3_197, %e4_198 = cute.get_leaves(%50) : !cute.shape<"((1,(4,4)),1,1)">
      %51 = cute.get_stride(%lay_193) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.stride<"((0,(1,4)),0,0)">
      %e0_199, %e1_200, %e2_201, %e3_202, %e4_203 = cute.get_leaves(%51) : !cute.stride<"((0,(1,4)),0,0)">
      %c0_i32 = arith.constant 0 : i32
      %c16_i32 = arith.constant 16 : i32
      %c1_i32 = arith.constant 1 : i32
      %52 = scf.for %arg6 = %c0_i32 to %c16_i32 step %c1_i32 iter_args(%arg7 = %rmem_187) -> (!memref_rmem_i8_)  : i32 {
        %iter_519 = cute.get_iter(%arg7) : !memref_rmem_i8_
        %lay_520 = cute.get_layout(%arg7) : !memref_rmem_i8_
        %91 = cute.get_shape(%lay_520) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
        %e0_521, %e1_522, %e2_523, %e3_524, %e4_525 = cute.get_leaves(%91) : !cute.shape<"((1,(4,4)),1,1)">
        %92 = cute.get_stride(%lay_520) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.stride<"((0,(1,4)),0,0)">
        %e0_526, %e1_527, %e2_528, %e3_529, %e4_530 = cute.get_leaves(%92) : !cute.stride<"((0,(1,4)),0,0)">
        %iter_531 = cute.get_iter(%arg7) : !memref_rmem_i8_
        %coord_532 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"?">
        %lay_533 = cute.get_layout(%src_partitioned_176) : !cute.coord_tensor<"(?{div=4},?{div=4})", "((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">
        %idx_534 = cute.crd2idx(%coord_532, %lay_533) : (!cute.coord<"?">, !cute.layout<"((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">) -> !cute.int_tuple<"(?,?)">
        %iter_535 = cute.get_iter(%src_partitioned_176) : !cute.coord_tensor<"(?{div=4},?{div=4})", "((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">
        %tup_536 = cute.add_offset(%iter_535, %idx_534) : (!cute.int_tuple<"(?{div=4},?{div=4})">, !cute.int_tuple<"(?,?)">) -> !cute.int_tuple<"(?,?)">
        %view_537 = cute.make_view(%tup_536) : !cute.coord_tensor<"(?,?)", "():()">
        %iter_538 = cute.get_iter(%view_537) : !cute.coord_tensor<"(?,?)", "():()">
        %e0_539, %e1_540 = cute.get_leaves(%iter_538) : !cute.int_tuple<"(?,?)">
        %93 = cute.get_scalars(%e0_539) : !cute.int_tuple<"?">
        %94 = cute.get_scalars(%e1_540) : !cute.int_tuple<"?">
        %iter_541 = cute.get_iter(%view_537) : !cute.coord_tensor<"(?,?)", "():()">
        %e0_542, %e1_543 = cute.get_leaves(%iter_541) : !cute.int_tuple<"(?,?)">
        %95 = cute.get_scalars(%e0_542) : !cute.int_tuple<"?">
        %96 = cute.get_scalars(%e1_543) : !cute.int_tuple<"?">
        %iter_544 = cute.get_iter(%view_537) : !cute.coord_tensor<"(?,?)", "():()">
        %e0_545, %e1_546 = cute.get_leaves(%iter_544) : !cute.int_tuple<"(?,?)">
        %97 = cute.get_scalars(%e0_545) : !cute.int_tuple<"?">
        %98 = cute.get_scalars(%e1_546) : !cute.int_tuple<"?">
        %coord_547 = cute.make_coord(%e0_545, %e1_546) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
        %coord_548 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
        %99 = cute.elem_less(%coord_547, %coord_548) : !cute.coord<"(?,?)">, !cute.coord<"(?,?)">
        %100 = arith.extui %99 : i1 to i8
        %coord_549 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"?">
        cute.memref.store(%arg7, %coord_549, %100) : (!memref_rmem_i8_, !cute.coord<"?">, i8) -> ()
        %lay_550 = cute.get_layout(%arg7) : !memref_rmem_i8_
        %101 = cute.get_shape(%lay_550) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
        %e0_551, %e1_552, %e2_553, %e3_554, %e4_555 = cute.get_leaves(%101) : !cute.shape<"((1,(4,4)),1,1)">
        %102 = cute.get_stride(%lay_550) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.stride<"((0,(1,4)),0,0)">
        %e0_556, %e1_557, %e2_558, %e3_559, %e4_560 = cute.get_leaves(%102) : !cute.stride<"((0,(1,4)),0,0)">
        scf.yield %arg7 : !memref_rmem_i8_
      }
      %iter_204 = cute.get_iter(%52) : !memref_rmem_i8_
      %lay_205 = cute.get_layout(%52) : !memref_rmem_i8_
      %53 = cute.get_shape(%lay_205) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_206, %e1_207, %e2_208, %e3_209, %e4_210 = cute.get_leaves(%53) : !cute.shape<"((1,(4,4)),1,1)">
      %54 = cute.get_stride(%lay_205) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.stride<"((0,(1,4)),0,0)">
      %e0_211, %e1_212, %e2_213, %e3_214, %e4_215 = cute.get_leaves(%54) : !cute.stride<"((0,(1,4)),0,0)">
      %iter_216 = cute.get_iter(%52) : !memref_rmem_i8_
      %iter_217 = cute.get_iter(%52) : !memref_rmem_i8_
      %lay_218 = cute.get_layout(%src_partitioned) : !memref_gmem_f32_2
      %55 = cute.get_shape(%lay_218) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_219, %e1_220, %e2_221, %e3_222, %e4_223 = cute.get_leaves(%55) : !cute.shape<"((1,(4,4)),1,1)">
      %lay_224 = cute.get_layout(%rmem) : !memref_rmem_f32_
      %56 = cute.get_shape(%lay_224) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_225, %e1_226, %e2_227, %e3_228, %e4_229 = cute.get_leaves(%56) : !cute.shape<"((1,(4,4)),1,1)">
      %lay_230 = cute.get_layout(%src_partitioned) : !memref_gmem_f32_2
      %shape_231 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_232 = cute.make_layout() : !cute.layout<"1:0">
      %append = cute.append_to_rank<2> (%lay_230, %lay_232) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">
      %view_233 = cute.make_view(%iter_157, %append) : !memref_gmem_f32_2
      %iter_234 = cute.get_iter(%view_233) : !memref_gmem_f32_2
      %lay_235 = cute.get_layout(%view_233) : !memref_gmem_f32_2
      %57 = cute.get_shape(%lay_235) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_236, %e1_237, %e2_238, %e3_239, %e4_240 = cute.get_leaves(%57) : !cute.shape<"((1,(4,4)),1,1)">
      %iter_241 = cute.get_iter(%view_233) : !memref_gmem_f32_2
      %lay_242 = cute.get_layout(%view_233) : !memref_gmem_f32_2
      %58 = cute.get_scalars(%lay_242) <{only_dynamic}> : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %shape_243 = cute.make_shape() : () -> !cute.shape<"((1,(4,4)),(1,1))">
      %stride = cute.make_stride(%58) : (i64) -> !cute.stride<"((0,(1,?{i64})),(0,0))">
      %lay_244 = cute.make_layout(%shape_243, %stride) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %view_245 = cute.make_view(%iter_241, %lay_244) : !memref_gmem_f32_3
      %iter_246 = cute.get_iter(%view_245) : !memref_gmem_f32_3
      %iter_247 = cute.get_iter(%view_245) : !memref_gmem_f32_3
      %lay_248 = cute.get_layout(%rmem) : !memref_rmem_f32_
      %shape_249 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_250 = cute.make_layout() : !cute.layout<"1:0">
      %append_251 = cute.append_to_rank<2> (%lay_248, %lay_250) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
      %view_252 = cute.make_view(%iter_166, %append_251) : !memref_rmem_f32_
      %iter_253 = cute.get_iter(%view_252) : !memref_rmem_f32_
      %lay_254 = cute.get_layout(%view_252) : !memref_rmem_f32_
      %59 = cute.get_shape(%lay_254) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_255, %e1_256, %e2_257, %e3_258, %e4_259 = cute.get_leaves(%59) : !cute.shape<"((1,(4,4)),1,1)">
      %iter_260 = cute.get_iter(%view_252) : !memref_rmem_f32_
      %view_261 = cute.make_view(%iter_260) : !memref_rmem_f32_1
      %iter_262 = cute.get_iter(%view_261) : !memref_rmem_f32_1
      %iter_263 = cute.get_iter(%view_261) : !memref_rmem_f32_1
      %lay_264 = cute.get_layout(%52) : !memref_rmem_i8_
      %shape_265 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_266 = cute.make_layout() : !cute.layout<"1:0">
      %append_267 = cute.append_to_rank<2> (%lay_264, %lay_266) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
      %view_268 = cute.make_view(%iter_217, %append_267) : !memref_rmem_i8_
      %iter_269 = cute.get_iter(%view_268) : !memref_rmem_i8_
      %lay_270 = cute.get_layout(%view_268) : !memref_rmem_i8_
      %60 = cute.get_shape(%lay_270) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_271, %e1_272, %e2_273, %e3_274, %e4_275 = cute.get_leaves(%60) : !cute.shape<"((1,(4,4)),1,1)">
      %iter_276 = cute.get_iter(%view_268) : !memref_rmem_i8_
      %view_277 = cute.make_view(%iter_276) : !memref_rmem_i8_1
      %iter_278 = cute.get_iter(%view_277) : !memref_rmem_i8_1
      %iter_279 = cute.get_iter(%view_277) : !memref_rmem_i8_1
      %lay_280 = cute.get_layout(%view_245) : !memref_gmem_f32_3
      %61 = cute.get_shape(%lay_280) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
      %e0_281, %e1_282, %e2_283, %e3_284, %e4_285 = cute.get_leaves(%61) : !cute.shape<"((1,(4,4)),(1,1))">
      %lay_286 = cute.get_layout(%view_261) : !memref_rmem_f32_1
      %62 = cute.get_shape(%lay_286) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
      %e0_287, %e1_288, %e2_289, %e3_290, %e4_291 = cute.get_leaves(%62) : !cute.shape<"((1,(4,4)),(1,1))">
      %lay_292 = cute.get_layout(%view_245) : !memref_gmem_f32_3
      %sz_293 = cute.size(%lay_292) <{mode = [1]}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.int_tuple<"1">
      %e0_294 = cute.get_leaves(%sz_293) : !cute.int_tuple<"1">
      %lay_295 = cute.get_layout(%view_261) : !memref_rmem_f32_1
      %sz_296 = cute.size(%lay_295) <{mode = [1]}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.int_tuple<"1">
      %e0_297 = cute.get_leaves(%sz_296) : !cute.int_tuple<"1">
      %63 = cute.static : !cute.layout<"1:0">
      %iter_298 = cute.get_iter(%view_245) : !memref_gmem_f32_3
      %iter_299 = cute.get_iter(%view_261) : !memref_rmem_f32_1
      %lay_300 = cute.get_layout(%view_245) : !memref_gmem_f32_3
      %lay_301 = cute.get_layout(%view_261) : !memref_rmem_f32_1
      %append_302 = cute.append_to_rank<2> (%lay_300, %63) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">, !cute.layout<"1:0">
      %append_303 = cute.append_to_rank<2> (%lay_301, %63) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">, !cute.layout<"1:0">
      %64 = cute.get_scalars(%append_302) <{only_dynamic}> : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %shape_304 = cute.make_shape() : () -> !cute.shape<"((1,(4,4)),((1,1)))">
      %stride_305 = cute.make_stride(%64) : (i64) -> !cute.stride<"((0,(1,?{i64})),((0,0)))">
      %lay_306 = cute.make_layout(%shape_304, %stride_305) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
      %lay_307 = cute.make_layout() : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">
      %iter_308 = cute.get_iter(%view_277) : !memref_rmem_i8_1
      %lay_309 = cute.get_layout(%view_277) : !memref_rmem_i8_1
      %append_310 = cute.append_to_rank<2> (%lay_309, %63) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">, !cute.layout<"1:0">
      %lay_311 = cute.make_layout() : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">
      %sz_312 = cute.size(%lay_306) <{mode = [1]}> : (!cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">) -> !cute.int_tuple<"1">
      %65 = cute.get_scalars(%sz_312) : !cute.int_tuple<"1">
      %c0_i32_313 = arith.constant 0 : i32
      %c1_i32_314 = arith.constant 1 : i32
      scf.for %arg6 = %c0_i32_313 to %65 step %c1_i32_314  : i32 {
        %coord_519 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
        %slice_520 = cute.slice(%lay_306, %coord_519) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">, !cute.coord<"(_,?)">
        %idx_521 = cute.crd2idx(%coord_519, %lay_306) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">) -> !cute.int_tuple<"0">
        %ptr_522 = cute.add_offset(%iter_298, %idx_521) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<f32, gmem>
        %view_523 = cute.make_view(%ptr_522, %slice_520) : !memref_gmem_f32_4
        %slice_524 = cute.slice(%lay_307, %coord_519) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">, !cute.coord<"(_,?)">
        %idx_525 = cute.crd2idx(%coord_519, %lay_307) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">) -> !cute.int_tuple<"0">
        %ptr_526 = cute.add_offset(%iter_299, %idx_525) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, rmem, align<32>>
        %view_527 = cute.make_view(%ptr_526, %slice_524) : !memref_rmem_f32_2
        %slice_528 = cute.slice(%lay_311, %coord_519) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">, !cute.coord<"(_,?)">
        %idx_529 = cute.crd2idx(%coord_519, %lay_311) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">) -> !cute.int_tuple<"0">
        %ptr_530 = cute.add_offset(%iter_308, %idx_529) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
        %view_531 = cute.make_view(%ptr_530, %slice_528) : !memref_rmem_i8_2
        cute.copy_atom_call(%atom, %view_523, %view_527, %view_531) : (!cute_nvgpu.atom.universal_copy<f32>, !memref_gmem_f32_4, !memref_rmem_f32_2, !memref_rmem_i8_2) -> ()
      } {llvm.loop_annotation = #loop_annotation}
      %lay_315 = cute.get_layout(%src_partitioned_159) : !memref_gmem_f32_2
      %66 = cute.get_shape(%lay_315) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_316, %e1_317, %e2_318, %e3_319, %e4_320 = cute.get_leaves(%66) : !cute.shape<"((1,(4,4)),1,1)">
      %lay_321 = cute.get_layout(%rmem_168) : !memref_rmem_f32_
      %67 = cute.get_shape(%lay_321) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_322, %e1_323, %e2_324, %e3_325, %e4_326 = cute.get_leaves(%67) : !cute.shape<"((1,(4,4)),1,1)">
      %lay_327 = cute.get_layout(%src_partitioned_159) : !memref_gmem_f32_2
      %shape_328 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_329 = cute.make_layout() : !cute.layout<"1:0">
      %append_330 = cute.append_to_rank<2> (%lay_327, %lay_329) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">
      %view_331 = cute.make_view(%iter_160, %append_330) : !memref_gmem_f32_2
      %iter_332 = cute.get_iter(%view_331) : !memref_gmem_f32_2
      %lay_333 = cute.get_layout(%view_331) : !memref_gmem_f32_2
      %68 = cute.get_shape(%lay_333) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_334, %e1_335, %e2_336, %e3_337, %e4_338 = cute.get_leaves(%68) : !cute.shape<"((1,(4,4)),1,1)">
      %iter_339 = cute.get_iter(%view_331) : !memref_gmem_f32_2
      %lay_340 = cute.get_layout(%view_331) : !memref_gmem_f32_2
      %69 = cute.get_scalars(%lay_340) <{only_dynamic}> : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %shape_341 = cute.make_shape() : () -> !cute.shape<"((1,(4,4)),(1,1))">
      %stride_342 = cute.make_stride(%69) : (i64) -> !cute.stride<"((0,(1,?{i64})),(0,0))">
      %lay_343 = cute.make_layout(%shape_341, %stride_342) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %view_344 = cute.make_view(%iter_339, %lay_343) : !memref_gmem_f32_3
      %iter_345 = cute.get_iter(%view_344) : !memref_gmem_f32_3
      %iter_346 = cute.get_iter(%view_344) : !memref_gmem_f32_3
      %lay_347 = cute.get_layout(%rmem_168) : !memref_rmem_f32_
      %shape_348 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_349 = cute.make_layout() : !cute.layout<"1:0">
      %append_350 = cute.append_to_rank<2> (%lay_347, %lay_349) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
      %view_351 = cute.make_view(%iter_170, %append_350) : !memref_rmem_f32_
      %iter_352 = cute.get_iter(%view_351) : !memref_rmem_f32_
      %lay_353 = cute.get_layout(%view_351) : !memref_rmem_f32_
      %70 = cute.get_shape(%lay_353) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_354, %e1_355, %e2_356, %e3_357, %e4_358 = cute.get_leaves(%70) : !cute.shape<"((1,(4,4)),1,1)">
      %iter_359 = cute.get_iter(%view_351) : !memref_rmem_f32_
      %view_360 = cute.make_view(%iter_359) : !memref_rmem_f32_1
      %iter_361 = cute.get_iter(%view_360) : !memref_rmem_f32_1
      %iter_362 = cute.get_iter(%view_360) : !memref_rmem_f32_1
      %lay_363 = cute.get_layout(%52) : !memref_rmem_i8_
      %shape_364 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_365 = cute.make_layout() : !cute.layout<"1:0">
      %append_366 = cute.append_to_rank<2> (%lay_363, %lay_365) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
      %view_367 = cute.make_view(%iter_217, %append_366) : !memref_rmem_i8_
      %iter_368 = cute.get_iter(%view_367) : !memref_rmem_i8_
      %lay_369 = cute.get_layout(%view_367) : !memref_rmem_i8_
      %71 = cute.get_shape(%lay_369) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_370, %e1_371, %e2_372, %e3_373, %e4_374 = cute.get_leaves(%71) : !cute.shape<"((1,(4,4)),1,1)">
      %iter_375 = cute.get_iter(%view_367) : !memref_rmem_i8_
      %view_376 = cute.make_view(%iter_375) : !memref_rmem_i8_1
      %iter_377 = cute.get_iter(%view_376) : !memref_rmem_i8_1
      %iter_378 = cute.get_iter(%view_376) : !memref_rmem_i8_1
      %lay_379 = cute.get_layout(%view_344) : !memref_gmem_f32_3
      %72 = cute.get_shape(%lay_379) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
      %e0_380, %e1_381, %e2_382, %e3_383, %e4_384 = cute.get_leaves(%72) : !cute.shape<"((1,(4,4)),(1,1))">
      %lay_385 = cute.get_layout(%view_360) : !memref_rmem_f32_1
      %73 = cute.get_shape(%lay_385) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
      %e0_386, %e1_387, %e2_388, %e3_389, %e4_390 = cute.get_leaves(%73) : !cute.shape<"((1,(4,4)),(1,1))">
      %lay_391 = cute.get_layout(%view_344) : !memref_gmem_f32_3
      %sz_392 = cute.size(%lay_391) <{mode = [1]}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.int_tuple<"1">
      %e0_393 = cute.get_leaves(%sz_392) : !cute.int_tuple<"1">
      %lay_394 = cute.get_layout(%view_360) : !memref_rmem_f32_1
      %sz_395 = cute.size(%lay_394) <{mode = [1]}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.int_tuple<"1">
      %e0_396 = cute.get_leaves(%sz_395) : !cute.int_tuple<"1">
      %74 = cute.static : !cute.layout<"1:0">
      %iter_397 = cute.get_iter(%view_344) : !memref_gmem_f32_3
      %iter_398 = cute.get_iter(%view_360) : !memref_rmem_f32_1
      %lay_399 = cute.get_layout(%view_344) : !memref_gmem_f32_3
      %lay_400 = cute.get_layout(%view_360) : !memref_rmem_f32_1
      %append_401 = cute.append_to_rank<2> (%lay_399, %74) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">, !cute.layout<"1:0">
      %append_402 = cute.append_to_rank<2> (%lay_400, %74) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">, !cute.layout<"1:0">
      %75 = cute.get_scalars(%append_401) <{only_dynamic}> : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %shape_403 = cute.make_shape() : () -> !cute.shape<"((1,(4,4)),((1,1)))">
      %stride_404 = cute.make_stride(%75) : (i64) -> !cute.stride<"((0,(1,?{i64})),((0,0)))">
      %lay_405 = cute.make_layout(%shape_403, %stride_404) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
      %lay_406 = cute.make_layout() : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">
      %iter_407 = cute.get_iter(%view_376) : !memref_rmem_i8_1
      %lay_408 = cute.get_layout(%view_376) : !memref_rmem_i8_1
      %append_409 = cute.append_to_rank<2> (%lay_408, %74) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">, !cute.layout<"1:0">
      %lay_410 = cute.make_layout() : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">
      %sz_411 = cute.size(%lay_405) <{mode = [1]}> : (!cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">) -> !cute.int_tuple<"1">
      %76 = cute.get_scalars(%sz_411) : !cute.int_tuple<"1">
      %c0_i32_412 = arith.constant 0 : i32
      %c1_i32_413 = arith.constant 1 : i32
      scf.for %arg6 = %c0_i32_412 to %76 step %c1_i32_413  : i32 {
        %coord_519 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
        %slice_520 = cute.slice(%lay_405, %coord_519) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">, !cute.coord<"(_,?)">
        %idx_521 = cute.crd2idx(%coord_519, %lay_405) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">) -> !cute.int_tuple<"0">
        %ptr_522 = cute.add_offset(%iter_397, %idx_521) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<f32, gmem>
        %view_523 = cute.make_view(%ptr_522, %slice_520) : !memref_gmem_f32_4
        %slice_524 = cute.slice(%lay_406, %coord_519) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">, !cute.coord<"(_,?)">
        %idx_525 = cute.crd2idx(%coord_519, %lay_406) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">) -> !cute.int_tuple<"0">
        %ptr_526 = cute.add_offset(%iter_398, %idx_525) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, rmem, align<32>>
        %view_527 = cute.make_view(%ptr_526, %slice_524) : !memref_rmem_f32_2
        %slice_528 = cute.slice(%lay_410, %coord_519) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">, !cute.coord<"(_,?)">
        %idx_529 = cute.crd2idx(%coord_519, %lay_410) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">) -> !cute.int_tuple<"0">
        %ptr_530 = cute.add_offset(%iter_407, %idx_529) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
        %view_531 = cute.make_view(%ptr_530, %slice_528) : !memref_rmem_i8_2
        cute.copy_atom_call(%atom, %view_523, %view_527, %view_531) : (!cute_nvgpu.atom.universal_copy<f32>, !memref_gmem_f32_4, !memref_rmem_f32_2, !memref_rmem_i8_2) -> ()
      } {llvm.loop_annotation = #loop_annotation}
      %77 = cute.memref.load_vec %rmem : !memref_rmem_f32_
      %78 = cute.memref.load_vec %rmem_168 : !memref_rmem_f32_
      %79 = arith.addf %77, %78 : vector<16xf32>
      %lay_414 = cute.get_layout(%rmem_172) : !memref_rmem_f32_
      %80 = cute.get_shape(%lay_414) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_415, %e1_416, %e2_417, %e3_418, %e4_419 = cute.get_leaves(%80) : !cute.shape<"((1,(4,4)),1,1)">
      %int_tuple_420 = cute.make_int_tuple() : () -> !cute.int_tuple<"((1,(4,4)),1,1)">
      %sz_421 = cute.size(%int_tuple_420) : (!cute.int_tuple<"((1,(4,4)),1,1)">) -> !cute.int_tuple<"16">
      %e0_422 = cute.get_leaves(%sz_421) : !cute.int_tuple<"16">
      %int_tuple_423 = cute.make_int_tuple() : () -> !cute.int_tuple<"((1,(4,4)),1,1)">
      %sz_424 = cute.size(%int_tuple_423) : (!cute.int_tuple<"((1,(4,4)),1,1)">) -> !cute.int_tuple<"16">
      %e0_425 = cute.get_leaves(%sz_424) : !cute.int_tuple<"16">
      cute.memref.store_vec %79, %rmem_172 : !memref_rmem_f32_
      %lay_426 = cute.get_layout(%src_partitioned_162) : !memref_gmem_f32_2
      %81 = cute.get_shape(%lay_426) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_427, %e1_428, %e2_429, %e3_430, %e4_431 = cute.get_leaves(%81) : !cute.shape<"((1,(4,4)),1,1)">
      %lay_432 = cute.get_layout(%rmem_172) : !memref_rmem_f32_
      %shape_433 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_434 = cute.make_layout() : !cute.layout<"1:0">
      %append_435 = cute.append_to_rank<2> (%lay_432, %lay_434) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
      %view_436 = cute.make_view(%iter_174, %append_435) : !memref_rmem_f32_
      %iter_437 = cute.get_iter(%view_436) : !memref_rmem_f32_
      %lay_438 = cute.get_layout(%view_436) : !memref_rmem_f32_
      %82 = cute.get_shape(%lay_438) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_439, %e1_440, %e2_441, %e3_442, %e4_443 = cute.get_leaves(%82) : !cute.shape<"((1,(4,4)),1,1)">
      %iter_444 = cute.get_iter(%view_436) : !memref_rmem_f32_
      %view_445 = cute.make_view(%iter_444) : !memref_rmem_f32_1
      %iter_446 = cute.get_iter(%view_445) : !memref_rmem_f32_1
      %iter_447 = cute.get_iter(%view_445) : !memref_rmem_f32_1
      %lay_448 = cute.get_layout(%src_partitioned_162) : !memref_gmem_f32_2
      %shape_449 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_450 = cute.make_layout() : !cute.layout<"1:0">
      %append_451 = cute.append_to_rank<2> (%lay_448, %lay_450) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">
      %view_452 = cute.make_view(%iter_163, %append_451) : !memref_gmem_f32_2
      %iter_453 = cute.get_iter(%view_452) : !memref_gmem_f32_2
      %lay_454 = cute.get_layout(%view_452) : !memref_gmem_f32_2
      %83 = cute.get_shape(%lay_454) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_455, %e1_456, %e2_457, %e3_458, %e4_459 = cute.get_leaves(%83) : !cute.shape<"((1,(4,4)),1,1)">
      %iter_460 = cute.get_iter(%view_452) : !memref_gmem_f32_2
      %lay_461 = cute.get_layout(%view_452) : !memref_gmem_f32_2
      %84 = cute.get_scalars(%lay_461) <{only_dynamic}> : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %shape_462 = cute.make_shape() : () -> !cute.shape<"((1,(4,4)),(1,1))">
      %stride_463 = cute.make_stride(%84) : (i64) -> !cute.stride<"((0,(1,?{i64})),(0,0))">
      %lay_464 = cute.make_layout(%shape_462, %stride_463) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %view_465 = cute.make_view(%iter_460, %lay_464) : !memref_gmem_f32_3
      %iter_466 = cute.get_iter(%view_465) : !memref_gmem_f32_3
      %iter_467 = cute.get_iter(%view_465) : !memref_gmem_f32_3
      %lay_468 = cute.get_layout(%52) : !memref_rmem_i8_
      %shape_469 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_470 = cute.make_layout() : !cute.layout<"1:0">
      %append_471 = cute.append_to_rank<2> (%lay_468, %lay_470) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
      %view_472 = cute.make_view(%iter_217, %append_471) : !memref_rmem_i8_
      %iter_473 = cute.get_iter(%view_472) : !memref_rmem_i8_
      %lay_474 = cute.get_layout(%view_472) : !memref_rmem_i8_
      %85 = cute.get_shape(%lay_474) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_475, %e1_476, %e2_477, %e3_478, %e4_479 = cute.get_leaves(%85) : !cute.shape<"((1,(4,4)),1,1)">
      %iter_480 = cute.get_iter(%view_472) : !memref_rmem_i8_
      %view_481 = cute.make_view(%iter_480) : !memref_rmem_i8_1
      %iter_482 = cute.get_iter(%view_481) : !memref_rmem_i8_1
      %iter_483 = cute.get_iter(%view_481) : !memref_rmem_i8_1
      %lay_484 = cute.get_layout(%view_445) : !memref_rmem_f32_1
      %86 = cute.get_shape(%lay_484) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
      %e0_485, %e1_486, %e2_487, %e3_488, %e4_489 = cute.get_leaves(%86) : !cute.shape<"((1,(4,4)),(1,1))">
      %lay_490 = cute.get_layout(%view_465) : !memref_gmem_f32_3
      %87 = cute.get_shape(%lay_490) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
      %e0_491, %e1_492, %e2_493, %e3_494, %e4_495 = cute.get_leaves(%87) : !cute.shape<"((1,(4,4)),(1,1))">
      %lay_496 = cute.get_layout(%view_445) : !memref_rmem_f32_1
      %sz_497 = cute.size(%lay_496) <{mode = [1]}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.int_tuple<"1">
      %e0_498 = cute.get_leaves(%sz_497) : !cute.int_tuple<"1">
      %lay_499 = cute.get_layout(%view_465) : !memref_gmem_f32_3
      %sz_500 = cute.size(%lay_499) <{mode = [1]}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.int_tuple<"1">
      %e0_501 = cute.get_leaves(%sz_500) : !cute.int_tuple<"1">
      %88 = cute.static : !cute.layout<"1:0">
      %iter_502 = cute.get_iter(%view_445) : !memref_rmem_f32_1
      %iter_503 = cute.get_iter(%view_465) : !memref_gmem_f32_3
      %lay_504 = cute.get_layout(%view_445) : !memref_rmem_f32_1
      %lay_505 = cute.get_layout(%view_465) : !memref_gmem_f32_3
      %append_506 = cute.append_to_rank<2> (%lay_504, %88) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">, !cute.layout<"1:0">
      %append_507 = cute.append_to_rank<2> (%lay_505, %88) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">, !cute.layout<"1:0">
      %lay_508 = cute.make_layout() : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">
      %89 = cute.get_scalars(%append_507) <{only_dynamic}> : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %shape_509 = cute.make_shape() : () -> !cute.shape<"((1,(4,4)),((1,1)))">
      %stride_510 = cute.make_stride(%89) : (i64) -> !cute.stride<"((0,(1,?{i64})),((0,0)))">
      %lay_511 = cute.make_layout(%shape_509, %stride_510) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
      %iter_512 = cute.get_iter(%view_481) : !memref_rmem_i8_1
      %lay_513 = cute.get_layout(%view_481) : !memref_rmem_i8_1
      %append_514 = cute.append_to_rank<2> (%lay_513, %88) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">, !cute.layout<"1:0">
      %lay_515 = cute.make_layout() : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">
      %sz_516 = cute.size(%lay_508) <{mode = [1]}> : (!cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">) -> !cute.int_tuple<"1">
      %90 = cute.get_scalars(%sz_516) : !cute.int_tuple<"1">
      %c0_i32_517 = arith.constant 0 : i32
      %c1_i32_518 = arith.constant 1 : i32
      scf.for %arg6 = %c0_i32_517 to %90 step %c1_i32_518  : i32 {
        %coord_519 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
        %slice_520 = cute.slice(%lay_508, %coord_519) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">, !cute.coord<"(_,?)">
        %idx_521 = cute.crd2idx(%coord_519, %lay_508) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">) -> !cute.int_tuple<"0">
        %ptr_522 = cute.add_offset(%iter_502, %idx_521) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, rmem, align<32>>
        %view_523 = cute.make_view(%ptr_522, %slice_520) : !memref_rmem_f32_2
        %slice_524 = cute.slice(%lay_511, %coord_519) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">, !cute.coord<"(_,?)">
        %idx_525 = cute.crd2idx(%coord_519, %lay_511) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">) -> !cute.int_tuple<"0">
        %ptr_526 = cute.add_offset(%iter_503, %idx_525) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<f32, gmem>
        %view_527 = cute.make_view(%ptr_526, %slice_524) : !memref_gmem_f32_4
        %slice_528 = cute.slice(%lay_515, %coord_519) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">, !cute.coord<"(_,?)">
        %idx_529 = cute.crd2idx(%coord_519, %lay_515) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">) -> !cute.int_tuple<"0">
        %ptr_530 = cute.add_offset(%iter_512, %idx_529) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
        %view_531 = cute.make_view(%ptr_530, %slice_528) : !memref_rmem_i8_2
        cute.copy_atom_call(%atom_96, %view_523, %view_527, %view_531) : (!cute_nvgpu.atom.universal_copy<f32>, !memref_rmem_f32_2, !memref_gmem_f32_4, !memref_rmem_i8_2) -> ()
      } {llvm.loop_annotation = #loop_annotation}
      return
    }
  }
  func.func @cutlass_elementwise_add_tensor_11032_05810_07178_04202_14205_07574_02934_04618_12152_01212_04481_01082_15156_02895_18373_01055_06905_00592_06973_10689_21883_00355_01292_08202_14995(%arg0: !memref_gmem_f32_5, %arg1: !memref_gmem_f32_5, %arg2: !memref_gmem_f32_5) -> i32 attributes {llvm.emit_c_interface} {
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
    %c0_i32 = arith.constant 0 : i32
    %c0_i64 = arith.constant 0 : i64
    %64 = cuda.cast %c0_i64 : i64 -> !cuda.stream
    %65 = arith.extsi %c0_i32 : i32 to i64
    %c128_i32_167 = arith.constant 128 : i32
    %c1_i32 = arith.constant 1 : i32
    %66 = cuda.launch_cfg.create<max_attrs = 2 : i32> (blockDim = (%c128_i32_167, %c1_i32, %c1_i32), dynamicSmemBytes = %65, gridDim = (%37, %c1_i32, %c1_i32), stream = %64) : i32, i32, i32, i64, i32, i32, i32, !cuda.stream -> !cuda.launch_cfg<max_attrs = 2>
    %67 = cuda.launch_ex @kernels::@kernel_cutlass_elementwise_add_kernel_tensorptrf32gmemo161281i64div16128_tensorptrf32gmemo161281i64div16128_tensorptrf32gmemo161281i64div16128_tensor00o1612810111601281___0<%66> (%view, %view_64, %view_77, %view_97, %31, %32) : !cuda.launch_cfg<max_attrs = 2>, (!memref_gmem_f32_, !memref_gmem_f32_, !memref_gmem_f32_, !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">, i32, i32) -> !cuda.result
    %68 = cuda.cast %67 : !cuda.result -> i32
    cuda.return_if_error %68 : i32
    %c0_i32_168 = arith.constant 0 : i32
    return %c0_i32_168 : i32
  }
}
