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
      %34:4 = cute.get_scalars(%lay_63) <{only_dynamic}> : !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
      %35 = cute.get_scalars(%coord) <{only_dynamic}> : !cute.coord<"((_,_),?)">
      %shape = cute.make_shape() : () -> !cute.shape<"(16,128)">
      %stride = cute.make_stride(%34#2) : (i64) -> !cute.stride<"(?{i64},1)">
      %lay_64 = cute.make_layout(%shape, %stride) : !cute.layout<"(16,128):(?{i64},1)">
      %idx = cute.crd2idx(%coord, %lay_63) : (!cute.coord<"((_,_),?)">, !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.int_tuple<"?{i64 div=16}">
      %iter_65 = cute.get_iter(%arg0) : !memref_gmem_f32_
      %ptr = cute.add_offset(%iter_65, %idx) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=16}">) -> !cute.ptr<f32, gmem>
      %view = cute.make_view(%ptr, %lay_64) : !memref_gmem_f32_1
      %iter_66 = cute.get_iter(%view) : !memref_gmem_f32_1
      %iter_67 = cute.get_iter(%view) : !memref_gmem_f32_1
      %coord_68 = cute.make_coord(%31) : (i32) -> !cute.coord<"((_,_),?)">
      %lay_69 = cute.get_layout(%arg1) : !memref_gmem_f32_
      %36:4 = cute.get_scalars(%lay_69) <{only_dynamic}> : !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
      %37 = cute.get_scalars(%coord_68) <{only_dynamic}> : !cute.coord<"((_,_),?)">
      %shape_70 = cute.make_shape() : () -> !cute.shape<"(16,128)">
      %stride_71 = cute.make_stride(%36#2) : (i64) -> !cute.stride<"(?{i64},1)">
      %lay_72 = cute.make_layout(%shape_70, %stride_71) : !cute.layout<"(16,128):(?{i64},1)">
      %idx_73 = cute.crd2idx(%coord_68, %lay_69) : (!cute.coord<"((_,_),?)">, !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.int_tuple<"?{i64 div=16}">
      %iter_74 = cute.get_iter(%arg1) : !memref_gmem_f32_
      %ptr_75 = cute.add_offset(%iter_74, %idx_73) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=16}">) -> !cute.ptr<f32, gmem>
      %view_76 = cute.make_view(%ptr_75, %lay_72) : !memref_gmem_f32_1
      %iter_77 = cute.get_iter(%view_76) : !memref_gmem_f32_1
      %iter_78 = cute.get_iter(%view_76) : !memref_gmem_f32_1
      %coord_79 = cute.make_coord(%31) : (i32) -> !cute.coord<"((_,_),?)">
      %lay_80 = cute.get_layout(%arg2) : !memref_gmem_f32_
      %38:4 = cute.get_scalars(%lay_80) <{only_dynamic}> : !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
      %39 = cute.get_scalars(%coord_79) <{only_dynamic}> : !cute.coord<"((_,_),?)">
      %shape_81 = cute.make_shape() : () -> !cute.shape<"(16,128)">
      %stride_82 = cute.make_stride(%38#2) : (i64) -> !cute.stride<"(?{i64},1)">
      %lay_83 = cute.make_layout(%shape_81, %stride_82) : !cute.layout<"(16,128):(?{i64},1)">
      %idx_84 = cute.crd2idx(%coord_79, %lay_80) : (!cute.coord<"((_,_),?)">, !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.int_tuple<"?{i64 div=16}">
      %iter_85 = cute.get_iter(%arg2) : !memref_gmem_f32_
      %ptr_86 = cute.add_offset(%iter_85, %idx_84) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=16}">) -> !cute.ptr<f32, gmem>
      %view_87 = cute.make_view(%ptr_86, %lay_83) : !memref_gmem_f32_1
      %iter_88 = cute.get_iter(%view_87) : !memref_gmem_f32_1
      %iter_89 = cute.get_iter(%view_87) : !memref_gmem_f32_1
      %coord_90 = cute.make_coord(%31) : (i32) -> !cute.coord<"((_,_),?)">
      %lay_91 = cute.get_layout(%arg3) : !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
      %idx_92 = cute.crd2idx(%coord_90, %lay_91) : (!cute.coord<"((_,_),?)">, !cute.layout<"((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">) -> !cute.int_tuple<"(?{div=16},?{div=128})">
      %iter_93 = cute.get_iter(%arg3) : !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
      %tup = cute.add_offset(%iter_93, %idx_92) : (!cute.int_tuple<"(0,0)">, !cute.int_tuple<"(?{div=16},?{div=128})">) -> !cute.int_tuple<"(?{div=16},?{div=128})">
      %view_94 = cute.make_view(%tup) : !cute.coord_tensor<"(?{div=16},?{div=128})", "(16,128):(1@0,1@1)">
      %iter_95 = cute.get_iter(%view_94) : !cute.coord_tensor<"(?{div=16},?{div=128})", "(16,128):(1@0,1@1)">
      %e0_96, %e1_97 = cute.get_leaves(%iter_95) : !cute.int_tuple<"(?{div=16},?{div=128})">
      %40 = cute.get_scalars(%e0_96) : !cute.int_tuple<"?{div=16}">
      %41 = cute.get_scalars(%e1_97) : !cute.int_tuple<"?{div=128}">
      %iter_98 = cute.get_iter(%view_94) : !cute.coord_tensor<"(?{div=16},?{div=128})", "(16,128):(1@0,1@1)">
      %e0_99, %e1_100 = cute.get_leaves(%iter_98) : !cute.int_tuple<"(?{div=16},?{div=128})">
      %42 = cute.get_scalars(%e0_99) : !cute.int_tuple<"?{div=16}">
      %43 = cute.get_scalars(%e1_100) : !cute.int_tuple<"?{div=128}">
      %atom = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<f32>
      %atom_101 = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<f32>
      %lay_102 = cute.make_layout() : !cute.layout<"((4,4),(4,32)):((512,32),(128,1))">
      %sz = cute.size(%0) : (!cute.layout<"(4,32):(32,1)">) -> !cute.int_tuple<"128">
      %e0_103 = cute.get_leaves(%sz) : !cute.int_tuple<"128">
      %sz_104 = cute.size(%1) : (!cute.layout<"(4,4):(4,1)">) -> !cute.int_tuple<"16">
      %e0_105 = cute.get_leaves(%sz_104) : !cute.int_tuple<"16">
      %shape_106 = cute.make_shape() : () -> !cute.shape<"(128,16)">
      %lay_107 = cute.make_layout() : !cute.layout<"(128,16):(1,128)">
      %rinv = cute.right_inverse(%lay_102) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.layout<"(32,16,4):(64,4,1)">
      %lay_108 = cute.make_layout() : !cute.layout<"((32,4),(4,4)):((64,4),(16,1))">
      %44 = cute.get_shape(%lay_102) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.shape<"((4,4),(4,32))">
      %e0_109, %e1_110, %e2_111, %e3_112 = cute.get_leaves(%44) : !cute.shape<"((4,4),(4,32))">
      %int_tuple = cute.make_int_tuple() : () -> !cute.int_tuple<"((4,4),(4,32))">
      %int_tuple_113 = cute.make_int_tuple() : () -> !cute.int_tuple<"(16,128)">
      %e0_114, %e1_115 = cute.get_leaves(%int_tuple_113) : !cute.int_tuple<"(16,128)">
      %int_tuple_116 = cute.make_int_tuple() : () -> !cute.int_tuple<"(16,128)">
      %int_tuple_117 = cute.make_int_tuple() : () -> !cute.int_tuple<"(16,128)">
      %e0_118, %e1_119 = cute.get_leaves(%int_tuple_117) : !cute.int_tuple<"(16,128)">
      %tile = cute.make_tile() : () -> !cute.tile<"[16:1;128:1]">
      %45 = cute.make_tiled_copy(%atom) : !copy_simt
      %lay_120 = cute.make_layout() : !cute.layout<"((4,4),(4,32)):((512,32),(128,1))">
      %sz_121 = cute.size(%0) : (!cute.layout<"(4,32):(32,1)">) -> !cute.int_tuple<"128">
      %e0_122 = cute.get_leaves(%sz_121) : !cute.int_tuple<"128">
      %sz_123 = cute.size(%1) : (!cute.layout<"(4,4):(4,1)">) -> !cute.int_tuple<"16">
      %e0_124 = cute.get_leaves(%sz_123) : !cute.int_tuple<"16">
      %shape_125 = cute.make_shape() : () -> !cute.shape<"(128,16)">
      %lay_126 = cute.make_layout() : !cute.layout<"(128,16):(1,128)">
      %rinv_127 = cute.right_inverse(%lay_120) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.layout<"(32,16,4):(64,4,1)">
      %lay_128 = cute.make_layout() : !cute.layout<"((32,4),(4,4)):((64,4),(16,1))">
      %46 = cute.get_shape(%lay_120) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.shape<"((4,4),(4,32))">
      %e0_129, %e1_130, %e2_131, %e3_132 = cute.get_leaves(%46) : !cute.shape<"((4,4),(4,32))">
      %int_tuple_133 = cute.make_int_tuple() : () -> !cute.int_tuple<"((4,4),(4,32))">
      %int_tuple_134 = cute.make_int_tuple() : () -> !cute.int_tuple<"(16,128)">
      %e0_135, %e1_136 = cute.get_leaves(%int_tuple_134) : !cute.int_tuple<"(16,128)">
      %int_tuple_137 = cute.make_int_tuple() : () -> !cute.int_tuple<"(16,128)">
      %int_tuple_138 = cute.make_int_tuple() : () -> !cute.int_tuple<"(16,128)">
      %e0_139, %e1_140 = cute.get_leaves(%int_tuple_138) : !cute.int_tuple<"(16,128)">
      %tile_141 = cute.make_tile() : () -> !cute.tile<"[16:1;128:1]">
      %47 = cute.make_tiled_copy(%atom) : !copy_simt
      %lay_142 = cute.make_layout() : !cute.layout<"((4,4),(4,32)):((512,32),(128,1))">
      %sz_143 = cute.size(%0) : (!cute.layout<"(4,32):(32,1)">) -> !cute.int_tuple<"128">
      %e0_144 = cute.get_leaves(%sz_143) : !cute.int_tuple<"128">
      %sz_145 = cute.size(%1) : (!cute.layout<"(4,4):(4,1)">) -> !cute.int_tuple<"16">
      %e0_146 = cute.get_leaves(%sz_145) : !cute.int_tuple<"16">
      %shape_147 = cute.make_shape() : () -> !cute.shape<"(128,16)">
      %lay_148 = cute.make_layout() : !cute.layout<"(128,16):(1,128)">
      %rinv_149 = cute.right_inverse(%lay_142) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.layout<"(32,16,4):(64,4,1)">
      %lay_150 = cute.make_layout() : !cute.layout<"((32,4),(4,4)):((64,4),(16,1))">
      %48 = cute.get_shape(%lay_142) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.shape<"((4,4),(4,32))">
      %e0_151, %e1_152, %e2_153, %e3_154 = cute.get_leaves(%48) : !cute.shape<"((4,4),(4,32))">
      %int_tuple_155 = cute.make_int_tuple() : () -> !cute.int_tuple<"((4,4),(4,32))">
      %int_tuple_156 = cute.make_int_tuple() : () -> !cute.int_tuple<"(16,128)">
      %e0_157, %e1_158 = cute.get_leaves(%int_tuple_156) : !cute.int_tuple<"(16,128)">
      %int_tuple_159 = cute.make_int_tuple() : () -> !cute.int_tuple<"(16,128)">
      %int_tuple_160 = cute.make_int_tuple() : () -> !cute.int_tuple<"(16,128)">
      %e0_161, %e1_162 = cute.get_leaves(%int_tuple_160) : !cute.int_tuple<"(16,128)">
      %tile_163 = cute.make_tile() : () -> !cute.tile<"[16:1;128:1]">
      %49 = cute.make_tiled_copy(%atom_101) : !copy_simt
      %coord_164 = cute.make_coord(%28) : (i32) -> !cute.coord<"?">
      %iter_165 = cute.get_iter(%view) : !memref_gmem_f32_1
      %lay_166 = cute.get_layout(%view) : !memref_gmem_f32_1
      %50 = cute.get_scalars(%lay_166) <{only_dynamic}> : !cute.layout<"(16,128):(?{i64},1)">
      %51 = cute.get_scalars(%coord_164) <{only_dynamic}> : !cute.coord<"?">
      %c64_i64 = arith.constant 64 : i64
      %52 = arith.muli %50, %c64_i64 : i64
      %c4_i64 = arith.constant 4 : i64
      %53 = arith.muli %50, %c4_i64 : i64
      %c16_i64 = arith.constant 16 : i64
      %54 = arith.muli %50, %c16_i64 : i64
      %c32_i32 = arith.constant 32 : i32
      %55 = arith.divsi %51, %c32_i32 : i32
      %c32_i32_167 = arith.constant 32 : i32
      %56 = arith.remsi %51, %c32_i32_167 : i32
      %c4_i32 = arith.constant 4 : i32
      %57 = arith.muli %56, %c4_i32 : i32
      %58 = arith.extsi %55 : i32 to i64
      %59 = arith.muli %58, %53 : i64
      %60 = arith.extsi %57 : i32 to i64
      %61 = arith.addi %60, %59 : i64
      %iv = cute.assume(%61) : (i64) -> !cute.i64<divby 4>
      %int_tuple_168 = cute.make_int_tuple(%iv) : (!cute.i64<divby 4>) -> !cute.int_tuple<"?{i64 div=4}">
      %ptr_169 = cute.add_offset(%iter_165, %int_tuple_168) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=4}">) -> !cute.ptr<f32, gmem>
      %shape_170 = cute.make_shape() : () -> !cute.shape<"((1,(4,4)),1,1)">
      %stride_171 = cute.make_stride(%50) : (i64) -> !cute.stride<"((0,(1,?{i64})),0,0)">
      %lay_172 = cute.make_layout(%shape_170, %stride_171) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %view_173 = cute.make_view(%ptr_169, %lay_172) : !memref_gmem_f32_2
      %iter_174 = cute.get_iter(%view_173) : !memref_gmem_f32_2
      %coord_175 = cute.make_coord(%28) : (i32) -> !cute.coord<"?">
      %iter_176 = cute.get_iter(%view_76) : !memref_gmem_f32_1
      %lay_177 = cute.get_layout(%view_76) : !memref_gmem_f32_1
      %62 = cute.get_scalars(%lay_177) <{only_dynamic}> : !cute.layout<"(16,128):(?{i64},1)">
      %63 = cute.get_scalars(%coord_175) <{only_dynamic}> : !cute.coord<"?">
      %c64_i64_178 = arith.constant 64 : i64
      %64 = arith.muli %62, %c64_i64_178 : i64
      %c4_i64_179 = arith.constant 4 : i64
      %65 = arith.muli %62, %c4_i64_179 : i64
      %c16_i64_180 = arith.constant 16 : i64
      %66 = arith.muli %62, %c16_i64_180 : i64
      %c32_i32_181 = arith.constant 32 : i32
      %67 = arith.divsi %63, %c32_i32_181 : i32
      %c32_i32_182 = arith.constant 32 : i32
      %68 = arith.remsi %63, %c32_i32_182 : i32
      %c4_i32_183 = arith.constant 4 : i32
      %69 = arith.muli %68, %c4_i32_183 : i32
      %70 = arith.extsi %67 : i32 to i64
      %71 = arith.muli %70, %65 : i64
      %72 = arith.extsi %69 : i32 to i64
      %73 = arith.addi %72, %71 : i64
      %iv_184 = cute.assume(%73) : (i64) -> !cute.i64<divby 4>
      %int_tuple_185 = cute.make_int_tuple(%iv_184) : (!cute.i64<divby 4>) -> !cute.int_tuple<"?{i64 div=4}">
      %ptr_186 = cute.add_offset(%iter_176, %int_tuple_185) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=4}">) -> !cute.ptr<f32, gmem>
      %shape_187 = cute.make_shape() : () -> !cute.shape<"((1,(4,4)),1,1)">
      %stride_188 = cute.make_stride(%62) : (i64) -> !cute.stride<"((0,(1,?{i64})),0,0)">
      %lay_189 = cute.make_layout(%shape_187, %stride_188) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %view_190 = cute.make_view(%ptr_186, %lay_189) : !memref_gmem_f32_2
      %iter_191 = cute.get_iter(%view_190) : !memref_gmem_f32_2
      %coord_192 = cute.make_coord(%28) : (i32) -> !cute.coord<"?">
      %iter_193 = cute.get_iter(%view_87) : !memref_gmem_f32_1
      %lay_194 = cute.get_layout(%view_87) : !memref_gmem_f32_1
      %74 = cute.get_scalars(%lay_194) <{only_dynamic}> : !cute.layout<"(16,128):(?{i64},1)">
      %75 = cute.get_scalars(%coord_192) <{only_dynamic}> : !cute.coord<"?">
      %c64_i64_195 = arith.constant 64 : i64
      %76 = arith.muli %74, %c64_i64_195 : i64
      %c4_i64_196 = arith.constant 4 : i64
      %77 = arith.muli %74, %c4_i64_196 : i64
      %c16_i64_197 = arith.constant 16 : i64
      %78 = arith.muli %74, %c16_i64_197 : i64
      %c32_i32_198 = arith.constant 32 : i32
      %79 = arith.divsi %75, %c32_i32_198 : i32
      %c32_i32_199 = arith.constant 32 : i32
      %80 = arith.remsi %75, %c32_i32_199 : i32
      %c4_i32_200 = arith.constant 4 : i32
      %81 = arith.muli %80, %c4_i32_200 : i32
      %82 = arith.extsi %79 : i32 to i64
      %83 = arith.muli %82, %77 : i64
      %84 = arith.extsi %81 : i32 to i64
      %85 = arith.addi %84, %83 : i64
      %iv_201 = cute.assume(%85) : (i64) -> !cute.i64<divby 4>
      %int_tuple_202 = cute.make_int_tuple(%iv_201) : (!cute.i64<divby 4>) -> !cute.int_tuple<"?{i64 div=4}">
      %ptr_203 = cute.add_offset(%iter_193, %int_tuple_202) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=4}">) -> !cute.ptr<f32, gmem>
      %shape_204 = cute.make_shape() : () -> !cute.shape<"((1,(4,4)),1,1)">
      %stride_205 = cute.make_stride(%74) : (i64) -> !cute.stride<"((0,(1,?{i64})),0,0)">
      %lay_206 = cute.make_layout(%shape_204, %stride_205) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %view_207 = cute.make_view(%ptr_203, %lay_206) : !memref_gmem_f32_2
      %iter_208 = cute.get_iter(%view_207) : !memref_gmem_f32_2
      %lay_209 = cute.get_layout(%view_173) : !memref_gmem_f32_2
      %86 = cute.get_scalars(%lay_209) <{only_dynamic}> : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %lay_210 = cute.make_layout() : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %rmem = cute.memref.alloca(%lay_210) : !memref_rmem_f32_
      %iter_211 = cute.get_iter(%rmem) : !memref_rmem_f32_
      %iter_212 = cute.get_iter(%rmem) : !memref_rmem_f32_
      %lay_213 = cute.get_layout(%view_190) : !memref_gmem_f32_2
      %87 = cute.get_scalars(%lay_213) <{only_dynamic}> : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %lay_214 = cute.make_layout() : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %rmem_215 = cute.memref.alloca(%lay_214) : !memref_rmem_f32_
      %iter_216 = cute.get_iter(%rmem_215) : !memref_rmem_f32_
      %iter_217 = cute.get_iter(%rmem_215) : !memref_rmem_f32_
      %lay_218 = cute.get_layout(%view_207) : !memref_gmem_f32_2
      %88 = cute.get_scalars(%lay_218) <{only_dynamic}> : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %lay_219 = cute.make_layout() : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %rmem_220 = cute.memref.alloca(%lay_219) : !memref_rmem_f32_
      %iter_221 = cute.get_iter(%rmem_220) : !memref_rmem_f32_
      %iter_222 = cute.get_iter(%rmem_220) : !memref_rmem_f32_
      %coord_223 = cute.make_coord(%28) : (i32) -> !cute.coord<"?">
      %iter_224 = cute.get_iter(%view_94) : !cute.coord_tensor<"(?{div=16},?{div=128})", "(16,128):(1@0,1@1)">
      %89 = cute.get_scalars(%coord_223) <{only_dynamic}> : !cute.coord<"?">
      %c32_i32_225 = arith.constant 32 : i32
      %90 = arith.divsi %89, %c32_i32_225 : i32
      %c32_i32_226 = arith.constant 32 : i32
      %91 = arith.remsi %89, %c32_i32_226 : i32
      %c4_i32_227 = arith.constant 4 : i32
      %92 = arith.muli %91, %c4_i32_227 : i32
      %c4_i32_228 = arith.constant 4 : i32
      %93 = arith.muli %90, %c4_i32_228 : i32
      %iv_229 = cute.assume(%93) : (i32) -> !cute.i32<divby 4>
      %iv_230 = cute.assume(%92) : (i32) -> !cute.i32<divby 4>
      %int_tuple_231 = cute.make_int_tuple(%iv_229, %iv_230) : (!cute.i32<divby 4>, !cute.i32<divby 4>) -> !cute.int_tuple<"(?{div=4},?{div=4})">
      %tup_232 = cute.add_offset(%iter_224, %int_tuple_231) : (!cute.int_tuple<"(?{div=16},?{div=128})">, !cute.int_tuple<"(?{div=4},?{div=4})">) -> !cute.int_tuple<"(?{div=4},?{div=4})">
      %view_233 = cute.make_view(%tup_232) : !cute.coord_tensor<"(?{div=4},?{div=4})", "((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">
      %iter_234 = cute.get_iter(%view_233) : !cute.coord_tensor<"(?{div=4},?{div=4})", "((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">
      %e0_235, %e1_236 = cute.get_leaves(%iter_234) : !cute.int_tuple<"(?{div=4},?{div=4})">
      %94 = cute.get_scalars(%e0_235) : !cute.int_tuple<"?{div=4}">
      %95 = cute.get_scalars(%e1_236) : !cute.int_tuple<"?{div=4}">
      %lay_237 = cute.get_layout(%view_233) : !cute.coord_tensor<"(?{div=4},?{div=4})", "((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">
      %96 = cute.get_shape(%lay_237) : (!cute.layout<"((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_238, %e1_239, %e2_240, %e3_241, %e4 = cute.get_leaves(%96) : !cute.shape<"((1,(4,4)),1,1)">
      %shape_242 = cute.make_shape() : () -> !cute.shape<"((1,(4,4)),1,1)">
      %lay_243 = cute.make_layout() : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %rmem_244 = cute.memref.alloca(%lay_243) : !memref_rmem_i8_
      %iter_245 = cute.get_iter(%rmem_244) : !memref_rmem_i8_
      %iter_246 = cute.get_iter(%rmem_244) : !memref_rmem_i8_
      %lay_247 = cute.get_layout(%rmem_244) : !memref_rmem_i8_
      %sz_248 = cute.size(%lay_247) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.int_tuple<"16">
      %e0_249 = cute.get_leaves(%sz_248) : !cute.int_tuple<"16">
      %c0_i32 = arith.constant 0 : i32
      %c16_i32 = arith.constant 16 : i32
      %c1_i32 = arith.constant 1 : i32
      %97 = scf.for %arg6 = %c0_i32 to %c16_i32 step %c1_i32 iter_args(%arg7 = %rmem_244) -> (!memref_rmem_i8_)  : i32 {
        %iter_360 = cute.get_iter(%arg7) : !memref_rmem_i8_
        %iter_361 = cute.get_iter(%arg7) : !memref_rmem_i8_
        %coord_362 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"?">
        %lay_363 = cute.get_layout(%view_233) : !cute.coord_tensor<"(?{div=4},?{div=4})", "((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">
        %idx_364 = cute.crd2idx(%coord_362, %lay_363) : (!cute.coord<"?">, !cute.layout<"((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">) -> !cute.int_tuple<"(?,?)">
        %iter_365 = cute.get_iter(%view_233) : !cute.coord_tensor<"(?{div=4},?{div=4})", "((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">
        %tup_366 = cute.add_offset(%iter_365, %idx_364) : (!cute.int_tuple<"(?{div=4},?{div=4})">, !cute.int_tuple<"(?,?)">) -> !cute.int_tuple<"(?,?)">
        %view_367 = cute.make_view(%tup_366) : !cute.coord_tensor<"(?,?)", "():()">
        %iter_368 = cute.get_iter(%view_367) : !cute.coord_tensor<"(?,?)", "():()">
        %e0_369, %e1_370 = cute.get_leaves(%iter_368) : !cute.int_tuple<"(?,?)">
        %110 = cute.get_scalars(%e0_369) : !cute.int_tuple<"?">
        %111 = cute.get_scalars(%e1_370) : !cute.int_tuple<"?">
        %iter_371 = cute.get_iter(%view_367) : !cute.coord_tensor<"(?,?)", "():()">
        %e0_372, %e1_373 = cute.get_leaves(%iter_371) : !cute.int_tuple<"(?,?)">
        %112 = cute.get_scalars(%e0_372) : !cute.int_tuple<"?">
        %113 = cute.get_scalars(%e1_373) : !cute.int_tuple<"?">
        %iter_374 = cute.get_iter(%view_367) : !cute.coord_tensor<"(?,?)", "():()">
        %e0_375, %e1_376 = cute.get_leaves(%iter_374) : !cute.int_tuple<"(?,?)">
        %114 = cute.get_scalars(%e0_375) : !cute.int_tuple<"?">
        %115 = cute.get_scalars(%e1_376) : !cute.int_tuple<"?">
        %coord_377 = cute.make_coord(%e0_375, %e1_376) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
        %coord_378 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
        %116:2 = cute.get_scalars(%coord_377) : !cute.coord<"(?,?)">
        %117:2 = cute.get_scalars(%coord_378) : !cute.coord<"(?,?)">
        %true = arith.constant true
        %118 = arith.cmpi slt, %116#0, %117#0 : i32
        %119 = arith.andi %true, %118 : i1
        %120 = arith.cmpi slt, %116#1, %117#1 : i32
        %121 = arith.andi %119, %120 : i1
        %122 = arith.extui %121 : i1 to i8
        %coord_379 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"?">
        cute.memref.store(%arg7, %coord_379, %122) : (!memref_rmem_i8_, !cute.coord<"?">, i8) -> ()
        scf.yield %arg7 : !memref_rmem_i8_
      }
      %iter_250 = cute.get_iter(%97) : !memref_rmem_i8_
      %iter_251 = cute.get_iter(%97) : !memref_rmem_i8_
      %iter_252 = cute.get_iter(%97) : !memref_rmem_i8_
      %false = arith.constant false
      scf.if %false {
        %c0_i32_360 = arith.constant 0 : i32
        %c10_i32_361 = arith.constant 10 : i32
        %c1_i32_362 = arith.constant 1 : i32
        scf.for %arg6 = %c0_i32_360 to %c10_i32_361 step %c1_i32_362  : i32 {
          %lay_363 = cute.get_layout(%view_173) : !memref_gmem_f32_2
          %110 = cute.get_shape(%lay_363) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_364, %e1_365, %e2_366, %e3_367, %e4_368 = cute.get_leaves(%110) : !cute.shape<"((1,(4,4)),1,1)">
          %lay_369 = cute.get_layout(%rmem) : !memref_rmem_f32_
          %111 = cute.get_shape(%lay_369) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_370, %e1_371, %e2_372, %e3_373, %e4_374 = cute.get_leaves(%111) : !cute.shape<"((1,(4,4)),1,1)">
          %lay_375 = cute.get_layout(%view_173) : !memref_gmem_f32_2
          %shape_376 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_377 = cute.make_layout() : !cute.layout<"1:0">
          %append_378 = cute.append_to_rank<2> (%lay_375, %lay_377) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">
          %view_379 = cute.make_view(%iter_174, %append_378) : !memref_gmem_f32_2
          %iter_380 = cute.get_iter(%view_379) : !memref_gmem_f32_2
          %lay_381 = cute.get_layout(%view_379) : !memref_gmem_f32_2
          %112 = cute.get_shape(%lay_381) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_382, %e1_383, %e2_384, %e3_385, %e4_386 = cute.get_leaves(%112) : !cute.shape<"((1,(4,4)),1,1)">
          %iter_387 = cute.get_iter(%view_379) : !memref_gmem_f32_2
          %lay_388 = cute.get_layout(%view_379) : !memref_gmem_f32_2
          %113 = cute.get_scalars(%lay_388) <{only_dynamic}> : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
          %shape_389 = cute.make_shape() : () -> !cute.shape<"((1,(4,4)),(1,1))">
          %stride_390 = cute.make_stride(%113) : (i64) -> !cute.stride<"((0,(1,?{i64})),(0,0))">
          %lay_391 = cute.make_layout(%shape_389, %stride_390) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
          %view_392 = cute.make_view(%iter_387, %lay_391) : !memref_gmem_f32_3
          %iter_393 = cute.get_iter(%view_392) : !memref_gmem_f32_3
          %iter_394 = cute.get_iter(%view_392) : !memref_gmem_f32_3
          %lay_395 = cute.get_layout(%rmem) : !memref_rmem_f32_
          %shape_396 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_397 = cute.make_layout() : !cute.layout<"1:0">
          %append_398 = cute.append_to_rank<2> (%lay_395, %lay_397) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
          %view_399 = cute.make_view(%iter_212, %append_398) : !memref_rmem_f32_
          %iter_400 = cute.get_iter(%view_399) : !memref_rmem_f32_
          %lay_401 = cute.get_layout(%view_399) : !memref_rmem_f32_
          %114 = cute.get_shape(%lay_401) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_402, %e1_403, %e2_404, %e3_405, %e4_406 = cute.get_leaves(%114) : !cute.shape<"((1,(4,4)),1,1)">
          %iter_407 = cute.get_iter(%view_399) : !memref_rmem_f32_
          %view_408 = cute.make_view(%iter_407) : !memref_rmem_f32_1
          %iter_409 = cute.get_iter(%view_408) : !memref_rmem_f32_1
          %iter_410 = cute.get_iter(%view_408) : !memref_rmem_f32_1
          %lay_411 = cute.get_layout(%97) : !memref_rmem_i8_
          %shape_412 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_413 = cute.make_layout() : !cute.layout<"1:0">
          %append_414 = cute.append_to_rank<2> (%lay_411, %lay_413) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
          %view_415 = cute.make_view(%iter_252, %append_414) : !memref_rmem_i8_
          %iter_416 = cute.get_iter(%view_415) : !memref_rmem_i8_
          %lay_417 = cute.get_layout(%view_415) : !memref_rmem_i8_
          %115 = cute.get_shape(%lay_417) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_418, %e1_419, %e2_420, %e3_421, %e4_422 = cute.get_leaves(%115) : !cute.shape<"((1,(4,4)),1,1)">
          %iter_423 = cute.get_iter(%view_415) : !memref_rmem_i8_
          %view_424 = cute.make_view(%iter_423) : !memref_rmem_i8_1
          %iter_425 = cute.get_iter(%view_424) : !memref_rmem_i8_1
          %iter_426 = cute.get_iter(%view_424) : !memref_rmem_i8_1
          %lay_427 = cute.get_layout(%view_392) : !memref_gmem_f32_3
          %116 = cute.get_shape(%lay_427) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
          %e0_428, %e1_429, %e2_430, %e3_431, %e4_432 = cute.get_leaves(%116) : !cute.shape<"((1,(4,4)),(1,1))">
          %lay_433 = cute.get_layout(%view_408) : !memref_rmem_f32_1
          %117 = cute.get_shape(%lay_433) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
          %e0_434, %e1_435, %e2_436, %e3_437, %e4_438 = cute.get_leaves(%117) : !cute.shape<"((1,(4,4)),(1,1))">
          %lay_439 = cute.get_layout(%view_392) : !memref_gmem_f32_3
          %sz_440 = cute.size(%lay_439) <{mode = [1]}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.int_tuple<"1">
          %e0_441 = cute.get_leaves(%sz_440) : !cute.int_tuple<"1">
          %lay_442 = cute.get_layout(%view_408) : !memref_rmem_f32_1
          %sz_443 = cute.size(%lay_442) <{mode = [1]}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.int_tuple<"1">
          %e0_444 = cute.get_leaves(%sz_443) : !cute.int_tuple<"1">
          %118 = cute.static : !cute.layout<"1:0">
          %iter_445 = cute.get_iter(%view_392) : !memref_gmem_f32_3
          %iter_446 = cute.get_iter(%view_408) : !memref_rmem_f32_1
          %lay_447 = cute.get_layout(%view_392) : !memref_gmem_f32_3
          %lay_448 = cute.get_layout(%view_408) : !memref_rmem_f32_1
          %append_449 = cute.append_to_rank<2> (%lay_447, %118) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">, !cute.layout<"1:0">
          %append_450 = cute.append_to_rank<2> (%lay_448, %118) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">, !cute.layout<"1:0">
          %119 = cute.get_scalars(%append_449) <{only_dynamic}> : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
          %shape_451 = cute.make_shape() : () -> !cute.shape<"((1,(4,4)),((1,1)))">
          %stride_452 = cute.make_stride(%119) : (i64) -> !cute.stride<"((0,(1,?{i64})),((0,0)))">
          %lay_453 = cute.make_layout(%shape_451, %stride_452) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
          %lay_454 = cute.make_layout() : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">
          %iter_455 = cute.get_iter(%view_424) : !memref_rmem_i8_1
          %lay_456 = cute.get_layout(%view_424) : !memref_rmem_i8_1
          %append_457 = cute.append_to_rank<2> (%lay_456, %118) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">, !cute.layout<"1:0">
          %lay_458 = cute.make_layout() : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">
          %sz_459 = cute.size(%lay_453) <{mode = [1]}> : (!cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">) -> !cute.int_tuple<"1">
          %120 = cute.get_scalars(%sz_459) : !cute.int_tuple<"1">
          %c0_i32_460 = arith.constant 0 : i32
          %c1_i32_461 = arith.constant 1 : i32
          scf.for %arg7 = %c0_i32_460 to %120 step %c1_i32_461  : i32 {
            %coord_561 = cute.make_coord(%arg7) : (i32) -> !cute.coord<"(_,?)">
            %132 = cute.get_scalars(%lay_453) <{only_dynamic}> : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
            %133 = cute.get_scalars(%coord_561) <{only_dynamic}> : !cute.coord<"(_,?)">
            %shape_562 = cute.make_shape() : () -> !cute.shape<"((1,(4,4)))">
            %stride_563 = cute.make_stride(%132) : (i64) -> !cute.stride<"((0,(1,?{i64})))">
            %lay_564 = cute.make_layout(%shape_562, %stride_563) : !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
            %idx_565 = cute.crd2idx(%coord_561, %lay_453) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">) -> !cute.int_tuple<"0">
            %ptr_566 = cute.add_offset(%iter_445, %idx_565) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<f32, gmem>
            %view_567 = cute.make_view(%ptr_566, %lay_564) : !memref_gmem_f32_4
            %134 = cute.get_scalars(%coord_561) <{only_dynamic}> : !cute.coord<"(_,?)">
            %lay_568 = cute.make_layout() : !cute.layout<"((1,(4,4))):((0,(1,4)))">
            %idx_569 = cute.crd2idx(%coord_561, %lay_454) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">) -> !cute.int_tuple<"0">
            %ptr_570 = cute.add_offset(%iter_446, %idx_569) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, rmem, align<32>>
            %view_571 = cute.make_view(%ptr_570, %lay_568) : !memref_rmem_f32_2
            %135 = cute.get_scalars(%coord_561) <{only_dynamic}> : !cute.coord<"(_,?)">
            %lay_572 = cute.make_layout() : !cute.layout<"((1,(4,4))):((0,(1,4)))">
            %idx_573 = cute.crd2idx(%coord_561, %lay_458) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">) -> !cute.int_tuple<"0">
            %ptr_574 = cute.add_offset(%iter_455, %idx_573) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
            %view_575 = cute.make_view(%ptr_574, %lay_572) : !memref_rmem_i8_2
            %iter_576 = cute.get_iter(%view_567) : !memref_gmem_f32_4
            %lay_577 = cute.get_layout(%view_567) : !memref_gmem_f32_4
            %136 = cute.get_scalars(%lay_577) <{only_dynamic}> : !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
            %iter_578 = cute.get_iter(%view_571) : !memref_rmem_f32_2
            %iter_579 = cute.get_iter(%view_575) : !memref_rmem_i8_2
            %137 = builtin.unrealized_conversion_cast %iter_579 : !cute.ptr<i8, rmem, align<32>> to !llvm.ptr
            %138 = llvm.load %137 : !llvm.ptr -> i8
            %139 = llvm.mlir.constant(0 : i8) : i8
            %140 = llvm.icmp "ne" %138, %139 : i8
            scf.if %140 {
              %201 = builtin.unrealized_conversion_cast %iter_576 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %202 = builtin.unrealized_conversion_cast %iter_578 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
              %203 = llvm.load %201 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %203, %202 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %int_tuple_580 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
            %ptr_581 = cute.add_offset(%iter_579, %int_tuple_580) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
            %141 = builtin.unrealized_conversion_cast %ptr_581 : !cute.ptr<i8, rmem> to !llvm.ptr
            %142 = llvm.load %141 : !llvm.ptr -> i8
            %143 = llvm.mlir.constant(0 : i8) : i8
            %144 = llvm.icmp "ne" %142, %143 : i8
            scf.if %144 {
              %int_tuple_610 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
              %ptr_611 = cute.add_offset(%iter_576, %int_tuple_610) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
              %int_tuple_612 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
              %ptr_613 = cute.add_offset(%iter_578, %int_tuple_612) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
              %201 = builtin.unrealized_conversion_cast %ptr_611 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %202 = builtin.unrealized_conversion_cast %ptr_613 : !cute.ptr<f32, rmem> to !llvm.ptr
              %203 = llvm.load %201 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %203, %202 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %int_tuple_582 = cute.make_int_tuple() : () -> !cute.int_tuple<"2">
            %ptr_583 = cute.add_offset(%iter_579, %int_tuple_582) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem, align<2>>
            %145 = builtin.unrealized_conversion_cast %ptr_583 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
            %146 = llvm.load %145 : !llvm.ptr -> i8
            %147 = llvm.mlir.constant(0 : i8) : i8
            %148 = llvm.icmp "ne" %146, %147 : i8
            scf.if %148 {
              %int_tuple_610 = cute.make_int_tuple() : () -> !cute.int_tuple<"2">
              %ptr_611 = cute.add_offset(%iter_576, %int_tuple_610) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
              %int_tuple_612 = cute.make_int_tuple() : () -> !cute.int_tuple<"2">
              %ptr_613 = cute.add_offset(%iter_578, %int_tuple_612) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
              %201 = builtin.unrealized_conversion_cast %ptr_611 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %202 = builtin.unrealized_conversion_cast %ptr_613 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
              %203 = llvm.load %201 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %203, %202 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %int_tuple_584 = cute.make_int_tuple() : () -> !cute.int_tuple<"3">
            %ptr_585 = cute.add_offset(%iter_579, %int_tuple_584) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
            %149 = builtin.unrealized_conversion_cast %ptr_585 : !cute.ptr<i8, rmem> to !llvm.ptr
            %150 = llvm.load %149 : !llvm.ptr -> i8
            %151 = llvm.mlir.constant(0 : i8) : i8
            %152 = llvm.icmp "ne" %150, %151 : i8
            scf.if %152 {
              %int_tuple_610 = cute.make_int_tuple() : () -> !cute.int_tuple<"3">
              %ptr_611 = cute.add_offset(%iter_576, %int_tuple_610) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
              %int_tuple_612 = cute.make_int_tuple() : () -> !cute.int_tuple<"3">
              %ptr_613 = cute.add_offset(%iter_578, %int_tuple_612) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
              %201 = builtin.unrealized_conversion_cast %ptr_611 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %202 = builtin.unrealized_conversion_cast %ptr_613 : !cute.ptr<f32, rmem> to !llvm.ptr
              %203 = llvm.load %201 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %203, %202 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %int_tuple_586 = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
            %ptr_587 = cute.add_offset(%iter_579, %int_tuple_586) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem, align<4>>
            %153 = builtin.unrealized_conversion_cast %ptr_587 : !cute.ptr<i8, rmem, align<4>> to !llvm.ptr
            %154 = llvm.load %153 : !llvm.ptr -> i8
            %155 = llvm.mlir.constant(0 : i8) : i8
            %156 = llvm.icmp "ne" %154, %155 : i8
            scf.if %156 {
              %int_tuple_610 = cute.make_int_tuple(%136) : (i64) -> !cute.int_tuple<"?{i64}">
              %ptr_611 = cute.add_offset(%iter_576, %int_tuple_610) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
              %int_tuple_612 = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
              %ptr_613 = cute.add_offset(%iter_578, %int_tuple_612) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
              %201 = builtin.unrealized_conversion_cast %ptr_611 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %202 = builtin.unrealized_conversion_cast %ptr_613 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              %203 = llvm.load %201 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %203, %202 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %int_tuple_588 = cute.make_int_tuple() : () -> !cute.int_tuple<"5">
            %ptr_589 = cute.add_offset(%iter_579, %int_tuple_588) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
            %157 = builtin.unrealized_conversion_cast %ptr_589 : !cute.ptr<i8, rmem> to !llvm.ptr
            %158 = llvm.load %157 : !llvm.ptr -> i8
            %159 = llvm.mlir.constant(0 : i8) : i8
            %160 = llvm.icmp "ne" %158, %159 : i8
            scf.if %160 {
              %c1_i64 = arith.constant 1 : i64
              %201 = arith.addi %136, %c1_i64 : i64
              %int_tuple_610 = cute.make_int_tuple(%201) : (i64) -> !cute.int_tuple<"?{i64}">
              %ptr_611 = cute.add_offset(%iter_576, %int_tuple_610) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
              %int_tuple_612 = cute.make_int_tuple() : () -> !cute.int_tuple<"5">
              %ptr_613 = cute.add_offset(%iter_578, %int_tuple_612) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<f32, rmem>
              %202 = builtin.unrealized_conversion_cast %ptr_611 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %203 = builtin.unrealized_conversion_cast %ptr_613 : !cute.ptr<f32, rmem> to !llvm.ptr
              %204 = llvm.load %202 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %204, %203 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %int_tuple_590 = cute.make_int_tuple() : () -> !cute.int_tuple<"6">
            %ptr_591 = cute.add_offset(%iter_579, %int_tuple_590) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem, align<2>>
            %161 = builtin.unrealized_conversion_cast %ptr_591 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
            %162 = llvm.load %161 : !llvm.ptr -> i8
            %163 = llvm.mlir.constant(0 : i8) : i8
            %164 = llvm.icmp "ne" %162, %163 : i8
            scf.if %164 {
              %c2_i64 = arith.constant 2 : i64
              %201 = arith.addi %136, %c2_i64 : i64
              %int_tuple_610 = cute.make_int_tuple(%201) : (i64) -> !cute.int_tuple<"?{i64}">
              %ptr_611 = cute.add_offset(%iter_576, %int_tuple_610) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
              %int_tuple_612 = cute.make_int_tuple() : () -> !cute.int_tuple<"6">
              %ptr_613 = cute.add_offset(%iter_578, %int_tuple_612) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
              %202 = builtin.unrealized_conversion_cast %ptr_611 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %203 = builtin.unrealized_conversion_cast %ptr_613 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
              %204 = llvm.load %202 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %204, %203 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %int_tuple_592 = cute.make_int_tuple() : () -> !cute.int_tuple<"7">
            %ptr_593 = cute.add_offset(%iter_579, %int_tuple_592) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
            %165 = builtin.unrealized_conversion_cast %ptr_593 : !cute.ptr<i8, rmem> to !llvm.ptr
            %166 = llvm.load %165 : !llvm.ptr -> i8
            %167 = llvm.mlir.constant(0 : i8) : i8
            %168 = llvm.icmp "ne" %166, %167 : i8
            scf.if %168 {
              %c3_i64 = arith.constant 3 : i64
              %201 = arith.addi %136, %c3_i64 : i64
              %int_tuple_610 = cute.make_int_tuple(%201) : (i64) -> !cute.int_tuple<"?{i64}">
              %ptr_611 = cute.add_offset(%iter_576, %int_tuple_610) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
              %int_tuple_612 = cute.make_int_tuple() : () -> !cute.int_tuple<"7">
              %ptr_613 = cute.add_offset(%iter_578, %int_tuple_612) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<f32, rmem>
              %202 = builtin.unrealized_conversion_cast %ptr_611 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %203 = builtin.unrealized_conversion_cast %ptr_613 : !cute.ptr<f32, rmem> to !llvm.ptr
              %204 = llvm.load %202 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %204, %203 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %int_tuple_594 = cute.make_int_tuple() : () -> !cute.int_tuple<"8">
            %ptr_595 = cute.add_offset(%iter_579, %int_tuple_594) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<i8, rmem, align<8>>
            %169 = builtin.unrealized_conversion_cast %ptr_595 : !cute.ptr<i8, rmem, align<8>> to !llvm.ptr
            %170 = llvm.load %169 : !llvm.ptr -> i8
            %171 = llvm.mlir.constant(0 : i8) : i8
            %172 = llvm.icmp "ne" %170, %171 : i8
            scf.if %172 {
              %c2_i64 = arith.constant 2 : i64
              %201 = arith.muli %136, %c2_i64 : i64
              %iv_610 = cute.assume(%201) : (i64) -> !cute.i64<divby 2>
              %int_tuple_611 = cute.make_int_tuple(%iv_610) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
              %ptr_612 = cute.add_offset(%iter_576, %int_tuple_611) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
              %int_tuple_613 = cute.make_int_tuple() : () -> !cute.int_tuple<"8">
              %ptr_614 = cute.add_offset(%iter_578, %int_tuple_613) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<f32, rmem, align<32>>
              %202 = builtin.unrealized_conversion_cast %ptr_612 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %203 = builtin.unrealized_conversion_cast %ptr_614 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
              %204 = llvm.load %202 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %204, %203 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %int_tuple_596 = cute.make_int_tuple() : () -> !cute.int_tuple<"9">
            %ptr_597 = cute.add_offset(%iter_579, %int_tuple_596) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<i8, rmem>
            %173 = builtin.unrealized_conversion_cast %ptr_597 : !cute.ptr<i8, rmem> to !llvm.ptr
            %174 = llvm.load %173 : !llvm.ptr -> i8
            %175 = llvm.mlir.constant(0 : i8) : i8
            %176 = llvm.icmp "ne" %174, %175 : i8
            scf.if %176 {
              %c2_i64 = arith.constant 2 : i64
              %201 = arith.muli %136, %c2_i64 : i64
              %c1_i64 = arith.constant 1 : i64
              %202 = arith.addi %201, %c1_i64 : i64
              %int_tuple_610 = cute.make_int_tuple(%202) : (i64) -> !cute.int_tuple<"?{i64}">
              %ptr_611 = cute.add_offset(%iter_576, %int_tuple_610) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
              %int_tuple_612 = cute.make_int_tuple() : () -> !cute.int_tuple<"9">
              %ptr_613 = cute.add_offset(%iter_578, %int_tuple_612) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<f32, rmem>
              %203 = builtin.unrealized_conversion_cast %ptr_611 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %204 = builtin.unrealized_conversion_cast %ptr_613 : !cute.ptr<f32, rmem> to !llvm.ptr
              %205 = llvm.load %203 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %205, %204 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %int_tuple_598 = cute.make_int_tuple() : () -> !cute.int_tuple<"10">
            %ptr_599 = cute.add_offset(%iter_579, %int_tuple_598) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<i8, rmem, align<2>>
            %177 = builtin.unrealized_conversion_cast %ptr_599 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
            %178 = llvm.load %177 : !llvm.ptr -> i8
            %179 = llvm.mlir.constant(0 : i8) : i8
            %180 = llvm.icmp "ne" %178, %179 : i8
            scf.if %180 {
              %c2_i64 = arith.constant 2 : i64
              %201 = arith.muli %136, %c2_i64 : i64
              %c2_i64_610 = arith.constant 2 : i64
              %202 = arith.addi %201, %c2_i64_610 : i64
              %iv_611 = cute.assume(%202) : (i64) -> !cute.i64<divby 2>
              %int_tuple_612 = cute.make_int_tuple(%iv_611) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
              %ptr_613 = cute.add_offset(%iter_576, %int_tuple_612) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
              %int_tuple_614 = cute.make_int_tuple() : () -> !cute.int_tuple<"10">
              %ptr_615 = cute.add_offset(%iter_578, %int_tuple_614) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<f32, rmem, align<8>>
              %203 = builtin.unrealized_conversion_cast %ptr_613 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %204 = builtin.unrealized_conversion_cast %ptr_615 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
              %205 = llvm.load %203 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %205, %204 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %int_tuple_600 = cute.make_int_tuple() : () -> !cute.int_tuple<"11">
            %ptr_601 = cute.add_offset(%iter_579, %int_tuple_600) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<i8, rmem>
            %181 = builtin.unrealized_conversion_cast %ptr_601 : !cute.ptr<i8, rmem> to !llvm.ptr
            %182 = llvm.load %181 : !llvm.ptr -> i8
            %183 = llvm.mlir.constant(0 : i8) : i8
            %184 = llvm.icmp "ne" %182, %183 : i8
            scf.if %184 {
              %c2_i64 = arith.constant 2 : i64
              %201 = arith.muli %136, %c2_i64 : i64
              %c3_i64 = arith.constant 3 : i64
              %202 = arith.addi %201, %c3_i64 : i64
              %int_tuple_610 = cute.make_int_tuple(%202) : (i64) -> !cute.int_tuple<"?{i64}">
              %ptr_611 = cute.add_offset(%iter_576, %int_tuple_610) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
              %int_tuple_612 = cute.make_int_tuple() : () -> !cute.int_tuple<"11">
              %ptr_613 = cute.add_offset(%iter_578, %int_tuple_612) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<f32, rmem>
              %203 = builtin.unrealized_conversion_cast %ptr_611 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %204 = builtin.unrealized_conversion_cast %ptr_613 : !cute.ptr<f32, rmem> to !llvm.ptr
              %205 = llvm.load %203 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %205, %204 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %int_tuple_602 = cute.make_int_tuple() : () -> !cute.int_tuple<"12">
            %ptr_603 = cute.add_offset(%iter_579, %int_tuple_602) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<i8, rmem, align<4>>
            %185 = builtin.unrealized_conversion_cast %ptr_603 : !cute.ptr<i8, rmem, align<4>> to !llvm.ptr
            %186 = llvm.load %185 : !llvm.ptr -> i8
            %187 = llvm.mlir.constant(0 : i8) : i8
            %188 = llvm.icmp "ne" %186, %187 : i8
            scf.if %188 {
              %c3_i64 = arith.constant 3 : i64
              %201 = arith.muli %136, %c3_i64 : i64
              %iv_610 = cute.assume(%201) : (i64) -> !cute.i64<divby 3>
              %int_tuple_611 = cute.make_int_tuple(%iv_610) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
              %ptr_612 = cute.add_offset(%iter_576, %int_tuple_611) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
              %int_tuple_613 = cute.make_int_tuple() : () -> !cute.int_tuple<"12">
              %ptr_614 = cute.add_offset(%iter_578, %int_tuple_613) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<f32, rmem, align<16>>
              %202 = builtin.unrealized_conversion_cast %ptr_612 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %203 = builtin.unrealized_conversion_cast %ptr_614 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              %204 = llvm.load %202 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %204, %203 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %int_tuple_604 = cute.make_int_tuple() : () -> !cute.int_tuple<"13">
            %ptr_605 = cute.add_offset(%iter_579, %int_tuple_604) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<i8, rmem>
            %189 = builtin.unrealized_conversion_cast %ptr_605 : !cute.ptr<i8, rmem> to !llvm.ptr
            %190 = llvm.load %189 : !llvm.ptr -> i8
            %191 = llvm.mlir.constant(0 : i8) : i8
            %192 = llvm.icmp "ne" %190, %191 : i8
            scf.if %192 {
              %c3_i64 = arith.constant 3 : i64
              %201 = arith.muli %136, %c3_i64 : i64
              %c1_i64 = arith.constant 1 : i64
              %202 = arith.addi %201, %c1_i64 : i64
              %int_tuple_610 = cute.make_int_tuple(%202) : (i64) -> !cute.int_tuple<"?{i64}">
              %ptr_611 = cute.add_offset(%iter_576, %int_tuple_610) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
              %int_tuple_612 = cute.make_int_tuple() : () -> !cute.int_tuple<"13">
              %ptr_613 = cute.add_offset(%iter_578, %int_tuple_612) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<f32, rmem>
              %203 = builtin.unrealized_conversion_cast %ptr_611 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %204 = builtin.unrealized_conversion_cast %ptr_613 : !cute.ptr<f32, rmem> to !llvm.ptr
              %205 = llvm.load %203 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %205, %204 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %int_tuple_606 = cute.make_int_tuple() : () -> !cute.int_tuple<"14">
            %ptr_607 = cute.add_offset(%iter_579, %int_tuple_606) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<i8, rmem, align<2>>
            %193 = builtin.unrealized_conversion_cast %ptr_607 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
            %194 = llvm.load %193 : !llvm.ptr -> i8
            %195 = llvm.mlir.constant(0 : i8) : i8
            %196 = llvm.icmp "ne" %194, %195 : i8
            scf.if %196 {
              %c3_i64 = arith.constant 3 : i64
              %201 = arith.muli %136, %c3_i64 : i64
              %c2_i64 = arith.constant 2 : i64
              %202 = arith.addi %201, %c2_i64 : i64
              %int_tuple_610 = cute.make_int_tuple(%202) : (i64) -> !cute.int_tuple<"?{i64}">
              %ptr_611 = cute.add_offset(%iter_576, %int_tuple_610) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
              %int_tuple_612 = cute.make_int_tuple() : () -> !cute.int_tuple<"14">
              %ptr_613 = cute.add_offset(%iter_578, %int_tuple_612) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<f32, rmem, align<8>>
              %203 = builtin.unrealized_conversion_cast %ptr_611 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %204 = builtin.unrealized_conversion_cast %ptr_613 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
              %205 = llvm.load %203 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %205, %204 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %int_tuple_608 = cute.make_int_tuple() : () -> !cute.int_tuple<"15">
            %ptr_609 = cute.add_offset(%iter_579, %int_tuple_608) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<i8, rmem>
            %197 = builtin.unrealized_conversion_cast %ptr_609 : !cute.ptr<i8, rmem> to !llvm.ptr
            %198 = llvm.load %197 : !llvm.ptr -> i8
            %199 = llvm.mlir.constant(0 : i8) : i8
            %200 = llvm.icmp "ne" %198, %199 : i8
            scf.if %200 {
              %c3_i64 = arith.constant 3 : i64
              %201 = arith.muli %136, %c3_i64 : i64
              %c3_i64_610 = arith.constant 3 : i64
              %202 = arith.addi %201, %c3_i64_610 : i64
              %iv_611 = cute.assume(%202) : (i64) -> !cute.i64<divby 3>
              %int_tuple_612 = cute.make_int_tuple(%iv_611) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
              %ptr_613 = cute.add_offset(%iter_576, %int_tuple_612) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
              %int_tuple_614 = cute.make_int_tuple() : () -> !cute.int_tuple<"15">
              %ptr_615 = cute.add_offset(%iter_578, %int_tuple_614) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<f32, rmem>
              %203 = builtin.unrealized_conversion_cast %ptr_613 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %204 = builtin.unrealized_conversion_cast %ptr_615 : !cute.ptr<f32, rmem> to !llvm.ptr
              %205 = llvm.load %203 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %205, %204 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
          } {llvm.loop_annotation = #loop_annotation}
          %lay_462 = cute.get_layout(%view_190) : !memref_gmem_f32_2
          %121 = cute.get_shape(%lay_462) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_463, %e1_464, %e2_465, %e3_466, %e4_467 = cute.get_leaves(%121) : !cute.shape<"((1,(4,4)),1,1)">
          %lay_468 = cute.get_layout(%rmem_215) : !memref_rmem_f32_
          %122 = cute.get_shape(%lay_468) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_469, %e1_470, %e2_471, %e3_472, %e4_473 = cute.get_leaves(%122) : !cute.shape<"((1,(4,4)),1,1)">
          %lay_474 = cute.get_layout(%view_190) : !memref_gmem_f32_2
          %shape_475 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_476 = cute.make_layout() : !cute.layout<"1:0">
          %append_477 = cute.append_to_rank<2> (%lay_474, %lay_476) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">
          %view_478 = cute.make_view(%iter_191, %append_477) : !memref_gmem_f32_2
          %iter_479 = cute.get_iter(%view_478) : !memref_gmem_f32_2
          %lay_480 = cute.get_layout(%view_478) : !memref_gmem_f32_2
          %123 = cute.get_shape(%lay_480) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_481, %e1_482, %e2_483, %e3_484, %e4_485 = cute.get_leaves(%123) : !cute.shape<"((1,(4,4)),1,1)">
          %iter_486 = cute.get_iter(%view_478) : !memref_gmem_f32_2
          %lay_487 = cute.get_layout(%view_478) : !memref_gmem_f32_2
          %124 = cute.get_scalars(%lay_487) <{only_dynamic}> : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
          %shape_488 = cute.make_shape() : () -> !cute.shape<"((1,(4,4)),(1,1))">
          %stride_489 = cute.make_stride(%124) : (i64) -> !cute.stride<"((0,(1,?{i64})),(0,0))">
          %lay_490 = cute.make_layout(%shape_488, %stride_489) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
          %view_491 = cute.make_view(%iter_486, %lay_490) : !memref_gmem_f32_3
          %iter_492 = cute.get_iter(%view_491) : !memref_gmem_f32_3
          %iter_493 = cute.get_iter(%view_491) : !memref_gmem_f32_3
          %lay_494 = cute.get_layout(%rmem_215) : !memref_rmem_f32_
          %shape_495 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_496 = cute.make_layout() : !cute.layout<"1:0">
          %append_497 = cute.append_to_rank<2> (%lay_494, %lay_496) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
          %view_498 = cute.make_view(%iter_217, %append_497) : !memref_rmem_f32_
          %iter_499 = cute.get_iter(%view_498) : !memref_rmem_f32_
          %lay_500 = cute.get_layout(%view_498) : !memref_rmem_f32_
          %125 = cute.get_shape(%lay_500) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_501, %e1_502, %e2_503, %e3_504, %e4_505 = cute.get_leaves(%125) : !cute.shape<"((1,(4,4)),1,1)">
          %iter_506 = cute.get_iter(%view_498) : !memref_rmem_f32_
          %view_507 = cute.make_view(%iter_506) : !memref_rmem_f32_1
          %iter_508 = cute.get_iter(%view_507) : !memref_rmem_f32_1
          %iter_509 = cute.get_iter(%view_507) : !memref_rmem_f32_1
          %lay_510 = cute.get_layout(%97) : !memref_rmem_i8_
          %shape_511 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_512 = cute.make_layout() : !cute.layout<"1:0">
          %append_513 = cute.append_to_rank<2> (%lay_510, %lay_512) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
          %view_514 = cute.make_view(%iter_252, %append_513) : !memref_rmem_i8_
          %iter_515 = cute.get_iter(%view_514) : !memref_rmem_i8_
          %lay_516 = cute.get_layout(%view_514) : !memref_rmem_i8_
          %126 = cute.get_shape(%lay_516) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_517, %e1_518, %e2_519, %e3_520, %e4_521 = cute.get_leaves(%126) : !cute.shape<"((1,(4,4)),1,1)">
          %iter_522 = cute.get_iter(%view_514) : !memref_rmem_i8_
          %view_523 = cute.make_view(%iter_522) : !memref_rmem_i8_1
          %iter_524 = cute.get_iter(%view_523) : !memref_rmem_i8_1
          %iter_525 = cute.get_iter(%view_523) : !memref_rmem_i8_1
          %lay_526 = cute.get_layout(%view_491) : !memref_gmem_f32_3
          %127 = cute.get_shape(%lay_526) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
          %e0_527, %e1_528, %e2_529, %e3_530, %e4_531 = cute.get_leaves(%127) : !cute.shape<"((1,(4,4)),(1,1))">
          %lay_532 = cute.get_layout(%view_507) : !memref_rmem_f32_1
          %128 = cute.get_shape(%lay_532) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
          %e0_533, %e1_534, %e2_535, %e3_536, %e4_537 = cute.get_leaves(%128) : !cute.shape<"((1,(4,4)),(1,1))">
          %lay_538 = cute.get_layout(%view_491) : !memref_gmem_f32_3
          %sz_539 = cute.size(%lay_538) <{mode = [1]}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.int_tuple<"1">
          %e0_540 = cute.get_leaves(%sz_539) : !cute.int_tuple<"1">
          %lay_541 = cute.get_layout(%view_507) : !memref_rmem_f32_1
          %sz_542 = cute.size(%lay_541) <{mode = [1]}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.int_tuple<"1">
          %e0_543 = cute.get_leaves(%sz_542) : !cute.int_tuple<"1">
          %129 = cute.static : !cute.layout<"1:0">
          %iter_544 = cute.get_iter(%view_491) : !memref_gmem_f32_3
          %iter_545 = cute.get_iter(%view_507) : !memref_rmem_f32_1
          %lay_546 = cute.get_layout(%view_491) : !memref_gmem_f32_3
          %lay_547 = cute.get_layout(%view_507) : !memref_rmem_f32_1
          %append_548 = cute.append_to_rank<2> (%lay_546, %129) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">, !cute.layout<"1:0">
          %append_549 = cute.append_to_rank<2> (%lay_547, %129) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">, !cute.layout<"1:0">
          %130 = cute.get_scalars(%append_548) <{only_dynamic}> : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
          %shape_550 = cute.make_shape() : () -> !cute.shape<"((1,(4,4)),((1,1)))">
          %stride_551 = cute.make_stride(%130) : (i64) -> !cute.stride<"((0,(1,?{i64})),((0,0)))">
          %lay_552 = cute.make_layout(%shape_550, %stride_551) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
          %lay_553 = cute.make_layout() : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">
          %iter_554 = cute.get_iter(%view_523) : !memref_rmem_i8_1
          %lay_555 = cute.get_layout(%view_523) : !memref_rmem_i8_1
          %append_556 = cute.append_to_rank<2> (%lay_555, %129) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">, !cute.layout<"1:0">
          %lay_557 = cute.make_layout() : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">
          %sz_558 = cute.size(%lay_552) <{mode = [1]}> : (!cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">) -> !cute.int_tuple<"1">
          %131 = cute.get_scalars(%sz_558) : !cute.int_tuple<"1">
          %c0_i32_559 = arith.constant 0 : i32
          %c1_i32_560 = arith.constant 1 : i32
          scf.for %arg7 = %c0_i32_559 to %131 step %c1_i32_560  : i32 {
            %coord_561 = cute.make_coord(%arg7) : (i32) -> !cute.coord<"(_,?)">
            %132 = cute.get_scalars(%lay_552) <{only_dynamic}> : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
            %133 = cute.get_scalars(%coord_561) <{only_dynamic}> : !cute.coord<"(_,?)">
            %shape_562 = cute.make_shape() : () -> !cute.shape<"((1,(4,4)))">
            %stride_563 = cute.make_stride(%132) : (i64) -> !cute.stride<"((0,(1,?{i64})))">
            %lay_564 = cute.make_layout(%shape_562, %stride_563) : !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
            %idx_565 = cute.crd2idx(%coord_561, %lay_552) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">) -> !cute.int_tuple<"0">
            %ptr_566 = cute.add_offset(%iter_544, %idx_565) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<f32, gmem>
            %view_567 = cute.make_view(%ptr_566, %lay_564) : !memref_gmem_f32_4
            %134 = cute.get_scalars(%coord_561) <{only_dynamic}> : !cute.coord<"(_,?)">
            %lay_568 = cute.make_layout() : !cute.layout<"((1,(4,4))):((0,(1,4)))">
            %idx_569 = cute.crd2idx(%coord_561, %lay_553) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">) -> !cute.int_tuple<"0">
            %ptr_570 = cute.add_offset(%iter_545, %idx_569) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, rmem, align<32>>
            %view_571 = cute.make_view(%ptr_570, %lay_568) : !memref_rmem_f32_2
            %135 = cute.get_scalars(%coord_561) <{only_dynamic}> : !cute.coord<"(_,?)">
            %lay_572 = cute.make_layout() : !cute.layout<"((1,(4,4))):((0,(1,4)))">
            %idx_573 = cute.crd2idx(%coord_561, %lay_557) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">) -> !cute.int_tuple<"0">
            %ptr_574 = cute.add_offset(%iter_554, %idx_573) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
            %view_575 = cute.make_view(%ptr_574, %lay_572) : !memref_rmem_i8_2
            %iter_576 = cute.get_iter(%view_567) : !memref_gmem_f32_4
            %lay_577 = cute.get_layout(%view_567) : !memref_gmem_f32_4
            %136 = cute.get_scalars(%lay_577) <{only_dynamic}> : !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
            %iter_578 = cute.get_iter(%view_571) : !memref_rmem_f32_2
            %iter_579 = cute.get_iter(%view_575) : !memref_rmem_i8_2
            %137 = builtin.unrealized_conversion_cast %iter_579 : !cute.ptr<i8, rmem, align<32>> to !llvm.ptr
            %138 = llvm.load %137 : !llvm.ptr -> i8
            %139 = llvm.mlir.constant(0 : i8) : i8
            %140 = llvm.icmp "ne" %138, %139 : i8
            scf.if %140 {
              %201 = builtin.unrealized_conversion_cast %iter_576 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %202 = builtin.unrealized_conversion_cast %iter_578 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
              %203 = llvm.load %201 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %203, %202 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %int_tuple_580 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
            %ptr_581 = cute.add_offset(%iter_579, %int_tuple_580) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
            %141 = builtin.unrealized_conversion_cast %ptr_581 : !cute.ptr<i8, rmem> to !llvm.ptr
            %142 = llvm.load %141 : !llvm.ptr -> i8
            %143 = llvm.mlir.constant(0 : i8) : i8
            %144 = llvm.icmp "ne" %142, %143 : i8
            scf.if %144 {
              %int_tuple_610 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
              %ptr_611 = cute.add_offset(%iter_576, %int_tuple_610) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
              %int_tuple_612 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
              %ptr_613 = cute.add_offset(%iter_578, %int_tuple_612) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
              %201 = builtin.unrealized_conversion_cast %ptr_611 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %202 = builtin.unrealized_conversion_cast %ptr_613 : !cute.ptr<f32, rmem> to !llvm.ptr
              %203 = llvm.load %201 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %203, %202 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %int_tuple_582 = cute.make_int_tuple() : () -> !cute.int_tuple<"2">
            %ptr_583 = cute.add_offset(%iter_579, %int_tuple_582) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem, align<2>>
            %145 = builtin.unrealized_conversion_cast %ptr_583 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
            %146 = llvm.load %145 : !llvm.ptr -> i8
            %147 = llvm.mlir.constant(0 : i8) : i8
            %148 = llvm.icmp "ne" %146, %147 : i8
            scf.if %148 {
              %int_tuple_610 = cute.make_int_tuple() : () -> !cute.int_tuple<"2">
              %ptr_611 = cute.add_offset(%iter_576, %int_tuple_610) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
              %int_tuple_612 = cute.make_int_tuple() : () -> !cute.int_tuple<"2">
              %ptr_613 = cute.add_offset(%iter_578, %int_tuple_612) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
              %201 = builtin.unrealized_conversion_cast %ptr_611 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %202 = builtin.unrealized_conversion_cast %ptr_613 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
              %203 = llvm.load %201 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %203, %202 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %int_tuple_584 = cute.make_int_tuple() : () -> !cute.int_tuple<"3">
            %ptr_585 = cute.add_offset(%iter_579, %int_tuple_584) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
            %149 = builtin.unrealized_conversion_cast %ptr_585 : !cute.ptr<i8, rmem> to !llvm.ptr
            %150 = llvm.load %149 : !llvm.ptr -> i8
            %151 = llvm.mlir.constant(0 : i8) : i8
            %152 = llvm.icmp "ne" %150, %151 : i8
            scf.if %152 {
              %int_tuple_610 = cute.make_int_tuple() : () -> !cute.int_tuple<"3">
              %ptr_611 = cute.add_offset(%iter_576, %int_tuple_610) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
              %int_tuple_612 = cute.make_int_tuple() : () -> !cute.int_tuple<"3">
              %ptr_613 = cute.add_offset(%iter_578, %int_tuple_612) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
              %201 = builtin.unrealized_conversion_cast %ptr_611 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %202 = builtin.unrealized_conversion_cast %ptr_613 : !cute.ptr<f32, rmem> to !llvm.ptr
              %203 = llvm.load %201 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %203, %202 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %int_tuple_586 = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
            %ptr_587 = cute.add_offset(%iter_579, %int_tuple_586) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem, align<4>>
            %153 = builtin.unrealized_conversion_cast %ptr_587 : !cute.ptr<i8, rmem, align<4>> to !llvm.ptr
            %154 = llvm.load %153 : !llvm.ptr -> i8
            %155 = llvm.mlir.constant(0 : i8) : i8
            %156 = llvm.icmp "ne" %154, %155 : i8
            scf.if %156 {
              %int_tuple_610 = cute.make_int_tuple(%136) : (i64) -> !cute.int_tuple<"?{i64}">
              %ptr_611 = cute.add_offset(%iter_576, %int_tuple_610) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
              %int_tuple_612 = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
              %ptr_613 = cute.add_offset(%iter_578, %int_tuple_612) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
              %201 = builtin.unrealized_conversion_cast %ptr_611 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %202 = builtin.unrealized_conversion_cast %ptr_613 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              %203 = llvm.load %201 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %203, %202 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %int_tuple_588 = cute.make_int_tuple() : () -> !cute.int_tuple<"5">
            %ptr_589 = cute.add_offset(%iter_579, %int_tuple_588) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
            %157 = builtin.unrealized_conversion_cast %ptr_589 : !cute.ptr<i8, rmem> to !llvm.ptr
            %158 = llvm.load %157 : !llvm.ptr -> i8
            %159 = llvm.mlir.constant(0 : i8) : i8
            %160 = llvm.icmp "ne" %158, %159 : i8
            scf.if %160 {
              %c1_i64 = arith.constant 1 : i64
              %201 = arith.addi %136, %c1_i64 : i64
              %int_tuple_610 = cute.make_int_tuple(%201) : (i64) -> !cute.int_tuple<"?{i64}">
              %ptr_611 = cute.add_offset(%iter_576, %int_tuple_610) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
              %int_tuple_612 = cute.make_int_tuple() : () -> !cute.int_tuple<"5">
              %ptr_613 = cute.add_offset(%iter_578, %int_tuple_612) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<f32, rmem>
              %202 = builtin.unrealized_conversion_cast %ptr_611 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %203 = builtin.unrealized_conversion_cast %ptr_613 : !cute.ptr<f32, rmem> to !llvm.ptr
              %204 = llvm.load %202 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %204, %203 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %int_tuple_590 = cute.make_int_tuple() : () -> !cute.int_tuple<"6">
            %ptr_591 = cute.add_offset(%iter_579, %int_tuple_590) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem, align<2>>
            %161 = builtin.unrealized_conversion_cast %ptr_591 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
            %162 = llvm.load %161 : !llvm.ptr -> i8
            %163 = llvm.mlir.constant(0 : i8) : i8
            %164 = llvm.icmp "ne" %162, %163 : i8
            scf.if %164 {
              %c2_i64 = arith.constant 2 : i64
              %201 = arith.addi %136, %c2_i64 : i64
              %int_tuple_610 = cute.make_int_tuple(%201) : (i64) -> !cute.int_tuple<"?{i64}">
              %ptr_611 = cute.add_offset(%iter_576, %int_tuple_610) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
              %int_tuple_612 = cute.make_int_tuple() : () -> !cute.int_tuple<"6">
              %ptr_613 = cute.add_offset(%iter_578, %int_tuple_612) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
              %202 = builtin.unrealized_conversion_cast %ptr_611 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %203 = builtin.unrealized_conversion_cast %ptr_613 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
              %204 = llvm.load %202 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %204, %203 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %int_tuple_592 = cute.make_int_tuple() : () -> !cute.int_tuple<"7">
            %ptr_593 = cute.add_offset(%iter_579, %int_tuple_592) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
            %165 = builtin.unrealized_conversion_cast %ptr_593 : !cute.ptr<i8, rmem> to !llvm.ptr
            %166 = llvm.load %165 : !llvm.ptr -> i8
            %167 = llvm.mlir.constant(0 : i8) : i8
            %168 = llvm.icmp "ne" %166, %167 : i8
            scf.if %168 {
              %c3_i64 = arith.constant 3 : i64
              %201 = arith.addi %136, %c3_i64 : i64
              %int_tuple_610 = cute.make_int_tuple(%201) : (i64) -> !cute.int_tuple<"?{i64}">
              %ptr_611 = cute.add_offset(%iter_576, %int_tuple_610) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
              %int_tuple_612 = cute.make_int_tuple() : () -> !cute.int_tuple<"7">
              %ptr_613 = cute.add_offset(%iter_578, %int_tuple_612) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<f32, rmem>
              %202 = builtin.unrealized_conversion_cast %ptr_611 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %203 = builtin.unrealized_conversion_cast %ptr_613 : !cute.ptr<f32, rmem> to !llvm.ptr
              %204 = llvm.load %202 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %204, %203 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %int_tuple_594 = cute.make_int_tuple() : () -> !cute.int_tuple<"8">
            %ptr_595 = cute.add_offset(%iter_579, %int_tuple_594) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<i8, rmem, align<8>>
            %169 = builtin.unrealized_conversion_cast %ptr_595 : !cute.ptr<i8, rmem, align<8>> to !llvm.ptr
            %170 = llvm.load %169 : !llvm.ptr -> i8
            %171 = llvm.mlir.constant(0 : i8) : i8
            %172 = llvm.icmp "ne" %170, %171 : i8
            scf.if %172 {
              %c2_i64 = arith.constant 2 : i64
              %201 = arith.muli %136, %c2_i64 : i64
              %iv_610 = cute.assume(%201) : (i64) -> !cute.i64<divby 2>
              %int_tuple_611 = cute.make_int_tuple(%iv_610) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
              %ptr_612 = cute.add_offset(%iter_576, %int_tuple_611) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
              %int_tuple_613 = cute.make_int_tuple() : () -> !cute.int_tuple<"8">
              %ptr_614 = cute.add_offset(%iter_578, %int_tuple_613) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<f32, rmem, align<32>>
              %202 = builtin.unrealized_conversion_cast %ptr_612 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %203 = builtin.unrealized_conversion_cast %ptr_614 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
              %204 = llvm.load %202 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %204, %203 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %int_tuple_596 = cute.make_int_tuple() : () -> !cute.int_tuple<"9">
            %ptr_597 = cute.add_offset(%iter_579, %int_tuple_596) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<i8, rmem>
            %173 = builtin.unrealized_conversion_cast %ptr_597 : !cute.ptr<i8, rmem> to !llvm.ptr
            %174 = llvm.load %173 : !llvm.ptr -> i8
            %175 = llvm.mlir.constant(0 : i8) : i8
            %176 = llvm.icmp "ne" %174, %175 : i8
            scf.if %176 {
              %c2_i64 = arith.constant 2 : i64
              %201 = arith.muli %136, %c2_i64 : i64
              %c1_i64 = arith.constant 1 : i64
              %202 = arith.addi %201, %c1_i64 : i64
              %int_tuple_610 = cute.make_int_tuple(%202) : (i64) -> !cute.int_tuple<"?{i64}">
              %ptr_611 = cute.add_offset(%iter_576, %int_tuple_610) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
              %int_tuple_612 = cute.make_int_tuple() : () -> !cute.int_tuple<"9">
              %ptr_613 = cute.add_offset(%iter_578, %int_tuple_612) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<f32, rmem>
              %203 = builtin.unrealized_conversion_cast %ptr_611 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %204 = builtin.unrealized_conversion_cast %ptr_613 : !cute.ptr<f32, rmem> to !llvm.ptr
              %205 = llvm.load %203 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %205, %204 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %int_tuple_598 = cute.make_int_tuple() : () -> !cute.int_tuple<"10">
            %ptr_599 = cute.add_offset(%iter_579, %int_tuple_598) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<i8, rmem, align<2>>
            %177 = builtin.unrealized_conversion_cast %ptr_599 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
            %178 = llvm.load %177 : !llvm.ptr -> i8
            %179 = llvm.mlir.constant(0 : i8) : i8
            %180 = llvm.icmp "ne" %178, %179 : i8
            scf.if %180 {
              %c2_i64 = arith.constant 2 : i64
              %201 = arith.muli %136, %c2_i64 : i64
              %c2_i64_610 = arith.constant 2 : i64
              %202 = arith.addi %201, %c2_i64_610 : i64
              %iv_611 = cute.assume(%202) : (i64) -> !cute.i64<divby 2>
              %int_tuple_612 = cute.make_int_tuple(%iv_611) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
              %ptr_613 = cute.add_offset(%iter_576, %int_tuple_612) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
              %int_tuple_614 = cute.make_int_tuple() : () -> !cute.int_tuple<"10">
              %ptr_615 = cute.add_offset(%iter_578, %int_tuple_614) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<f32, rmem, align<8>>
              %203 = builtin.unrealized_conversion_cast %ptr_613 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %204 = builtin.unrealized_conversion_cast %ptr_615 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
              %205 = llvm.load %203 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %205, %204 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %int_tuple_600 = cute.make_int_tuple() : () -> !cute.int_tuple<"11">
            %ptr_601 = cute.add_offset(%iter_579, %int_tuple_600) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<i8, rmem>
            %181 = builtin.unrealized_conversion_cast %ptr_601 : !cute.ptr<i8, rmem> to !llvm.ptr
            %182 = llvm.load %181 : !llvm.ptr -> i8
            %183 = llvm.mlir.constant(0 : i8) : i8
            %184 = llvm.icmp "ne" %182, %183 : i8
            scf.if %184 {
              %c2_i64 = arith.constant 2 : i64
              %201 = arith.muli %136, %c2_i64 : i64
              %c3_i64 = arith.constant 3 : i64
              %202 = arith.addi %201, %c3_i64 : i64
              %int_tuple_610 = cute.make_int_tuple(%202) : (i64) -> !cute.int_tuple<"?{i64}">
              %ptr_611 = cute.add_offset(%iter_576, %int_tuple_610) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
              %int_tuple_612 = cute.make_int_tuple() : () -> !cute.int_tuple<"11">
              %ptr_613 = cute.add_offset(%iter_578, %int_tuple_612) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<f32, rmem>
              %203 = builtin.unrealized_conversion_cast %ptr_611 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %204 = builtin.unrealized_conversion_cast %ptr_613 : !cute.ptr<f32, rmem> to !llvm.ptr
              %205 = llvm.load %203 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %205, %204 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %int_tuple_602 = cute.make_int_tuple() : () -> !cute.int_tuple<"12">
            %ptr_603 = cute.add_offset(%iter_579, %int_tuple_602) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<i8, rmem, align<4>>
            %185 = builtin.unrealized_conversion_cast %ptr_603 : !cute.ptr<i8, rmem, align<4>> to !llvm.ptr
            %186 = llvm.load %185 : !llvm.ptr -> i8
            %187 = llvm.mlir.constant(0 : i8) : i8
            %188 = llvm.icmp "ne" %186, %187 : i8
            scf.if %188 {
              %c3_i64 = arith.constant 3 : i64
              %201 = arith.muli %136, %c3_i64 : i64
              %iv_610 = cute.assume(%201) : (i64) -> !cute.i64<divby 3>
              %int_tuple_611 = cute.make_int_tuple(%iv_610) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
              %ptr_612 = cute.add_offset(%iter_576, %int_tuple_611) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
              %int_tuple_613 = cute.make_int_tuple() : () -> !cute.int_tuple<"12">
              %ptr_614 = cute.add_offset(%iter_578, %int_tuple_613) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<f32, rmem, align<16>>
              %202 = builtin.unrealized_conversion_cast %ptr_612 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %203 = builtin.unrealized_conversion_cast %ptr_614 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              %204 = llvm.load %202 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %204, %203 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %int_tuple_604 = cute.make_int_tuple() : () -> !cute.int_tuple<"13">
            %ptr_605 = cute.add_offset(%iter_579, %int_tuple_604) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<i8, rmem>
            %189 = builtin.unrealized_conversion_cast %ptr_605 : !cute.ptr<i8, rmem> to !llvm.ptr
            %190 = llvm.load %189 : !llvm.ptr -> i8
            %191 = llvm.mlir.constant(0 : i8) : i8
            %192 = llvm.icmp "ne" %190, %191 : i8
            scf.if %192 {
              %c3_i64 = arith.constant 3 : i64
              %201 = arith.muli %136, %c3_i64 : i64
              %c1_i64 = arith.constant 1 : i64
              %202 = arith.addi %201, %c1_i64 : i64
              %int_tuple_610 = cute.make_int_tuple(%202) : (i64) -> !cute.int_tuple<"?{i64}">
              %ptr_611 = cute.add_offset(%iter_576, %int_tuple_610) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
              %int_tuple_612 = cute.make_int_tuple() : () -> !cute.int_tuple<"13">
              %ptr_613 = cute.add_offset(%iter_578, %int_tuple_612) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<f32, rmem>
              %203 = builtin.unrealized_conversion_cast %ptr_611 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %204 = builtin.unrealized_conversion_cast %ptr_613 : !cute.ptr<f32, rmem> to !llvm.ptr
              %205 = llvm.load %203 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %205, %204 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %int_tuple_606 = cute.make_int_tuple() : () -> !cute.int_tuple<"14">
            %ptr_607 = cute.add_offset(%iter_579, %int_tuple_606) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<i8, rmem, align<2>>
            %193 = builtin.unrealized_conversion_cast %ptr_607 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
            %194 = llvm.load %193 : !llvm.ptr -> i8
            %195 = llvm.mlir.constant(0 : i8) : i8
            %196 = llvm.icmp "ne" %194, %195 : i8
            scf.if %196 {
              %c3_i64 = arith.constant 3 : i64
              %201 = arith.muli %136, %c3_i64 : i64
              %c2_i64 = arith.constant 2 : i64
              %202 = arith.addi %201, %c2_i64 : i64
              %int_tuple_610 = cute.make_int_tuple(%202) : (i64) -> !cute.int_tuple<"?{i64}">
              %ptr_611 = cute.add_offset(%iter_576, %int_tuple_610) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
              %int_tuple_612 = cute.make_int_tuple() : () -> !cute.int_tuple<"14">
              %ptr_613 = cute.add_offset(%iter_578, %int_tuple_612) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<f32, rmem, align<8>>
              %203 = builtin.unrealized_conversion_cast %ptr_611 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %204 = builtin.unrealized_conversion_cast %ptr_613 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
              %205 = llvm.load %203 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %205, %204 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %int_tuple_608 = cute.make_int_tuple() : () -> !cute.int_tuple<"15">
            %ptr_609 = cute.add_offset(%iter_579, %int_tuple_608) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<i8, rmem>
            %197 = builtin.unrealized_conversion_cast %ptr_609 : !cute.ptr<i8, rmem> to !llvm.ptr
            %198 = llvm.load %197 : !llvm.ptr -> i8
            %199 = llvm.mlir.constant(0 : i8) : i8
            %200 = llvm.icmp "ne" %198, %199 : i8
            scf.if %200 {
              %c3_i64 = arith.constant 3 : i64
              %201 = arith.muli %136, %c3_i64 : i64
              %c3_i64_610 = arith.constant 3 : i64
              %202 = arith.addi %201, %c3_i64_610 : i64
              %iv_611 = cute.assume(%202) : (i64) -> !cute.i64<divby 3>
              %int_tuple_612 = cute.make_int_tuple(%iv_611) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
              %ptr_613 = cute.add_offset(%iter_576, %int_tuple_612) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
              %int_tuple_614 = cute.make_int_tuple() : () -> !cute.int_tuple<"15">
              %ptr_615 = cute.add_offset(%iter_578, %int_tuple_614) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<f32, rmem>
              %203 = builtin.unrealized_conversion_cast %ptr_613 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %204 = builtin.unrealized_conversion_cast %ptr_615 : !cute.ptr<f32, rmem> to !llvm.ptr
              %205 = llvm.load %203 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %205, %204 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
          } {llvm.loop_annotation = #loop_annotation}
        }
        llvm.inline_asm has_side_effects asm_dialect = att "griddepcontrol.launch_dependents;", ""  : () -> ()
      } else {
        %c0_i32_360 = arith.constant 0 : i32
        %c10_i32_361 = arith.constant 10 : i32
        %c1_i32_362 = arith.constant 1 : i32
        scf.for %arg6 = %c0_i32_360 to %c10_i32_361 step %c1_i32_362  : i32 {
          %lay_363 = cute.get_layout(%view_190) : !memref_gmem_f32_2
          %110 = cute.get_shape(%lay_363) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_364, %e1_365, %e2_366, %e3_367, %e4_368 = cute.get_leaves(%110) : !cute.shape<"((1,(4,4)),1,1)">
          %lay_369 = cute.get_layout(%rmem_215) : !memref_rmem_f32_
          %111 = cute.get_shape(%lay_369) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_370, %e1_371, %e2_372, %e3_373, %e4_374 = cute.get_leaves(%111) : !cute.shape<"((1,(4,4)),1,1)">
          %lay_375 = cute.get_layout(%view_190) : !memref_gmem_f32_2
          %shape_376 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_377 = cute.make_layout() : !cute.layout<"1:0">
          %append_378 = cute.append_to_rank<2> (%lay_375, %lay_377) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">
          %view_379 = cute.make_view(%iter_191, %append_378) : !memref_gmem_f32_2
          %iter_380 = cute.get_iter(%view_379) : !memref_gmem_f32_2
          %lay_381 = cute.get_layout(%view_379) : !memref_gmem_f32_2
          %112 = cute.get_shape(%lay_381) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_382, %e1_383, %e2_384, %e3_385, %e4_386 = cute.get_leaves(%112) : !cute.shape<"((1,(4,4)),1,1)">
          %iter_387 = cute.get_iter(%view_379) : !memref_gmem_f32_2
          %lay_388 = cute.get_layout(%view_379) : !memref_gmem_f32_2
          %113 = cute.get_scalars(%lay_388) <{only_dynamic}> : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
          %shape_389 = cute.make_shape() : () -> !cute.shape<"((1,(4,4)),(1,1))">
          %stride_390 = cute.make_stride(%113) : (i64) -> !cute.stride<"((0,(1,?{i64})),(0,0))">
          %lay_391 = cute.make_layout(%shape_389, %stride_390) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
          %view_392 = cute.make_view(%iter_387, %lay_391) : !memref_gmem_f32_3
          %iter_393 = cute.get_iter(%view_392) : !memref_gmem_f32_3
          %iter_394 = cute.get_iter(%view_392) : !memref_gmem_f32_3
          %lay_395 = cute.get_layout(%rmem_215) : !memref_rmem_f32_
          %shape_396 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_397 = cute.make_layout() : !cute.layout<"1:0">
          %append_398 = cute.append_to_rank<2> (%lay_395, %lay_397) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
          %view_399 = cute.make_view(%iter_217, %append_398) : !memref_rmem_f32_
          %iter_400 = cute.get_iter(%view_399) : !memref_rmem_f32_
          %lay_401 = cute.get_layout(%view_399) : !memref_rmem_f32_
          %114 = cute.get_shape(%lay_401) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_402, %e1_403, %e2_404, %e3_405, %e4_406 = cute.get_leaves(%114) : !cute.shape<"((1,(4,4)),1,1)">
          %iter_407 = cute.get_iter(%view_399) : !memref_rmem_f32_
          %view_408 = cute.make_view(%iter_407) : !memref_rmem_f32_1
          %iter_409 = cute.get_iter(%view_408) : !memref_rmem_f32_1
          %iter_410 = cute.get_iter(%view_408) : !memref_rmem_f32_1
          %lay_411 = cute.get_layout(%97) : !memref_rmem_i8_
          %shape_412 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_413 = cute.make_layout() : !cute.layout<"1:0">
          %append_414 = cute.append_to_rank<2> (%lay_411, %lay_413) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
          %view_415 = cute.make_view(%iter_252, %append_414) : !memref_rmem_i8_
          %iter_416 = cute.get_iter(%view_415) : !memref_rmem_i8_
          %lay_417 = cute.get_layout(%view_415) : !memref_rmem_i8_
          %115 = cute.get_shape(%lay_417) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_418, %e1_419, %e2_420, %e3_421, %e4_422 = cute.get_leaves(%115) : !cute.shape<"((1,(4,4)),1,1)">
          %iter_423 = cute.get_iter(%view_415) : !memref_rmem_i8_
          %view_424 = cute.make_view(%iter_423) : !memref_rmem_i8_1
          %iter_425 = cute.get_iter(%view_424) : !memref_rmem_i8_1
          %iter_426 = cute.get_iter(%view_424) : !memref_rmem_i8_1
          %lay_427 = cute.get_layout(%view_392) : !memref_gmem_f32_3
          %116 = cute.get_shape(%lay_427) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
          %e0_428, %e1_429, %e2_430, %e3_431, %e4_432 = cute.get_leaves(%116) : !cute.shape<"((1,(4,4)),(1,1))">
          %lay_433 = cute.get_layout(%view_408) : !memref_rmem_f32_1
          %117 = cute.get_shape(%lay_433) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
          %e0_434, %e1_435, %e2_436, %e3_437, %e4_438 = cute.get_leaves(%117) : !cute.shape<"((1,(4,4)),(1,1))">
          %lay_439 = cute.get_layout(%view_392) : !memref_gmem_f32_3
          %sz_440 = cute.size(%lay_439) <{mode = [1]}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.int_tuple<"1">
          %e0_441 = cute.get_leaves(%sz_440) : !cute.int_tuple<"1">
          %lay_442 = cute.get_layout(%view_408) : !memref_rmem_f32_1
          %sz_443 = cute.size(%lay_442) <{mode = [1]}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.int_tuple<"1">
          %e0_444 = cute.get_leaves(%sz_443) : !cute.int_tuple<"1">
          %118 = cute.static : !cute.layout<"1:0">
          %iter_445 = cute.get_iter(%view_392) : !memref_gmem_f32_3
          %iter_446 = cute.get_iter(%view_408) : !memref_rmem_f32_1
          %lay_447 = cute.get_layout(%view_392) : !memref_gmem_f32_3
          %lay_448 = cute.get_layout(%view_408) : !memref_rmem_f32_1
          %append_449 = cute.append_to_rank<2> (%lay_447, %118) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">, !cute.layout<"1:0">
          %append_450 = cute.append_to_rank<2> (%lay_448, %118) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">, !cute.layout<"1:0">
          %119 = cute.get_scalars(%append_449) <{only_dynamic}> : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
          %shape_451 = cute.make_shape() : () -> !cute.shape<"((1,(4,4)),((1,1)))">
          %stride_452 = cute.make_stride(%119) : (i64) -> !cute.stride<"((0,(1,?{i64})),((0,0)))">
          %lay_453 = cute.make_layout(%shape_451, %stride_452) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
          %lay_454 = cute.make_layout() : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">
          %iter_455 = cute.get_iter(%view_424) : !memref_rmem_i8_1
          %lay_456 = cute.get_layout(%view_424) : !memref_rmem_i8_1
          %append_457 = cute.append_to_rank<2> (%lay_456, %118) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">, !cute.layout<"1:0">
          %lay_458 = cute.make_layout() : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">
          %sz_459 = cute.size(%lay_453) <{mode = [1]}> : (!cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">) -> !cute.int_tuple<"1">
          %120 = cute.get_scalars(%sz_459) : !cute.int_tuple<"1">
          %c0_i32_460 = arith.constant 0 : i32
          %c1_i32_461 = arith.constant 1 : i32
          scf.for %arg7 = %c0_i32_460 to %120 step %c1_i32_461  : i32 {
            %coord_462 = cute.make_coord(%arg7) : (i32) -> !cute.coord<"(_,?)">
            %121 = cute.get_scalars(%lay_453) <{only_dynamic}> : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
            %122 = cute.get_scalars(%coord_462) <{only_dynamic}> : !cute.coord<"(_,?)">
            %shape_463 = cute.make_shape() : () -> !cute.shape<"((1,(4,4)))">
            %stride_464 = cute.make_stride(%121) : (i64) -> !cute.stride<"((0,(1,?{i64})))">
            %lay_465 = cute.make_layout(%shape_463, %stride_464) : !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
            %idx_466 = cute.crd2idx(%coord_462, %lay_453) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">) -> !cute.int_tuple<"0">
            %ptr_467 = cute.add_offset(%iter_445, %idx_466) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<f32, gmem>
            %view_468 = cute.make_view(%ptr_467, %lay_465) : !memref_gmem_f32_4
            %123 = cute.get_scalars(%coord_462) <{only_dynamic}> : !cute.coord<"(_,?)">
            %lay_469 = cute.make_layout() : !cute.layout<"((1,(4,4))):((0,(1,4)))">
            %idx_470 = cute.crd2idx(%coord_462, %lay_454) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">) -> !cute.int_tuple<"0">
            %ptr_471 = cute.add_offset(%iter_446, %idx_470) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, rmem, align<32>>
            %view_472 = cute.make_view(%ptr_471, %lay_469) : !memref_rmem_f32_2
            %124 = cute.get_scalars(%coord_462) <{only_dynamic}> : !cute.coord<"(_,?)">
            %lay_473 = cute.make_layout() : !cute.layout<"((1,(4,4))):((0,(1,4)))">
            %idx_474 = cute.crd2idx(%coord_462, %lay_458) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">) -> !cute.int_tuple<"0">
            %ptr_475 = cute.add_offset(%iter_455, %idx_474) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
            %view_476 = cute.make_view(%ptr_475, %lay_473) : !memref_rmem_i8_2
            %iter_477 = cute.get_iter(%view_468) : !memref_gmem_f32_4
            %lay_478 = cute.get_layout(%view_468) : !memref_gmem_f32_4
            %125 = cute.get_scalars(%lay_478) <{only_dynamic}> : !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
            %iter_479 = cute.get_iter(%view_472) : !memref_rmem_f32_2
            %iter_480 = cute.get_iter(%view_476) : !memref_rmem_i8_2
            %126 = builtin.unrealized_conversion_cast %iter_480 : !cute.ptr<i8, rmem, align<32>> to !llvm.ptr
            %127 = llvm.load %126 : !llvm.ptr -> i8
            %128 = llvm.mlir.constant(0 : i8) : i8
            %129 = llvm.icmp "ne" %127, %128 : i8
            scf.if %129 {
              %190 = builtin.unrealized_conversion_cast %iter_477 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %191 = builtin.unrealized_conversion_cast %iter_479 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
              %192 = llvm.load %190 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %192, %191 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %int_tuple_481 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
            %ptr_482 = cute.add_offset(%iter_480, %int_tuple_481) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
            %130 = builtin.unrealized_conversion_cast %ptr_482 : !cute.ptr<i8, rmem> to !llvm.ptr
            %131 = llvm.load %130 : !llvm.ptr -> i8
            %132 = llvm.mlir.constant(0 : i8) : i8
            %133 = llvm.icmp "ne" %131, %132 : i8
            scf.if %133 {
              %int_tuple_511 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
              %ptr_512 = cute.add_offset(%iter_477, %int_tuple_511) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
              %int_tuple_513 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
              %ptr_514 = cute.add_offset(%iter_479, %int_tuple_513) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
              %190 = builtin.unrealized_conversion_cast %ptr_512 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %191 = builtin.unrealized_conversion_cast %ptr_514 : !cute.ptr<f32, rmem> to !llvm.ptr
              %192 = llvm.load %190 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %192, %191 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %int_tuple_483 = cute.make_int_tuple() : () -> !cute.int_tuple<"2">
            %ptr_484 = cute.add_offset(%iter_480, %int_tuple_483) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem, align<2>>
            %134 = builtin.unrealized_conversion_cast %ptr_484 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
            %135 = llvm.load %134 : !llvm.ptr -> i8
            %136 = llvm.mlir.constant(0 : i8) : i8
            %137 = llvm.icmp "ne" %135, %136 : i8
            scf.if %137 {
              %int_tuple_511 = cute.make_int_tuple() : () -> !cute.int_tuple<"2">
              %ptr_512 = cute.add_offset(%iter_477, %int_tuple_511) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
              %int_tuple_513 = cute.make_int_tuple() : () -> !cute.int_tuple<"2">
              %ptr_514 = cute.add_offset(%iter_479, %int_tuple_513) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
              %190 = builtin.unrealized_conversion_cast %ptr_512 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %191 = builtin.unrealized_conversion_cast %ptr_514 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
              %192 = llvm.load %190 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %192, %191 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %int_tuple_485 = cute.make_int_tuple() : () -> !cute.int_tuple<"3">
            %ptr_486 = cute.add_offset(%iter_480, %int_tuple_485) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
            %138 = builtin.unrealized_conversion_cast %ptr_486 : !cute.ptr<i8, rmem> to !llvm.ptr
            %139 = llvm.load %138 : !llvm.ptr -> i8
            %140 = llvm.mlir.constant(0 : i8) : i8
            %141 = llvm.icmp "ne" %139, %140 : i8
            scf.if %141 {
              %int_tuple_511 = cute.make_int_tuple() : () -> !cute.int_tuple<"3">
              %ptr_512 = cute.add_offset(%iter_477, %int_tuple_511) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
              %int_tuple_513 = cute.make_int_tuple() : () -> !cute.int_tuple<"3">
              %ptr_514 = cute.add_offset(%iter_479, %int_tuple_513) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
              %190 = builtin.unrealized_conversion_cast %ptr_512 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %191 = builtin.unrealized_conversion_cast %ptr_514 : !cute.ptr<f32, rmem> to !llvm.ptr
              %192 = llvm.load %190 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %192, %191 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %int_tuple_487 = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
            %ptr_488 = cute.add_offset(%iter_480, %int_tuple_487) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem, align<4>>
            %142 = builtin.unrealized_conversion_cast %ptr_488 : !cute.ptr<i8, rmem, align<4>> to !llvm.ptr
            %143 = llvm.load %142 : !llvm.ptr -> i8
            %144 = llvm.mlir.constant(0 : i8) : i8
            %145 = llvm.icmp "ne" %143, %144 : i8
            scf.if %145 {
              %int_tuple_511 = cute.make_int_tuple(%125) : (i64) -> !cute.int_tuple<"?{i64}">
              %ptr_512 = cute.add_offset(%iter_477, %int_tuple_511) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
              %int_tuple_513 = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
              %ptr_514 = cute.add_offset(%iter_479, %int_tuple_513) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
              %190 = builtin.unrealized_conversion_cast %ptr_512 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %191 = builtin.unrealized_conversion_cast %ptr_514 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              %192 = llvm.load %190 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %192, %191 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %int_tuple_489 = cute.make_int_tuple() : () -> !cute.int_tuple<"5">
            %ptr_490 = cute.add_offset(%iter_480, %int_tuple_489) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
            %146 = builtin.unrealized_conversion_cast %ptr_490 : !cute.ptr<i8, rmem> to !llvm.ptr
            %147 = llvm.load %146 : !llvm.ptr -> i8
            %148 = llvm.mlir.constant(0 : i8) : i8
            %149 = llvm.icmp "ne" %147, %148 : i8
            scf.if %149 {
              %c1_i64 = arith.constant 1 : i64
              %190 = arith.addi %125, %c1_i64 : i64
              %int_tuple_511 = cute.make_int_tuple(%190) : (i64) -> !cute.int_tuple<"?{i64}">
              %ptr_512 = cute.add_offset(%iter_477, %int_tuple_511) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
              %int_tuple_513 = cute.make_int_tuple() : () -> !cute.int_tuple<"5">
              %ptr_514 = cute.add_offset(%iter_479, %int_tuple_513) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<f32, rmem>
              %191 = builtin.unrealized_conversion_cast %ptr_512 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %192 = builtin.unrealized_conversion_cast %ptr_514 : !cute.ptr<f32, rmem> to !llvm.ptr
              %193 = llvm.load %191 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %193, %192 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %int_tuple_491 = cute.make_int_tuple() : () -> !cute.int_tuple<"6">
            %ptr_492 = cute.add_offset(%iter_480, %int_tuple_491) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem, align<2>>
            %150 = builtin.unrealized_conversion_cast %ptr_492 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
            %151 = llvm.load %150 : !llvm.ptr -> i8
            %152 = llvm.mlir.constant(0 : i8) : i8
            %153 = llvm.icmp "ne" %151, %152 : i8
            scf.if %153 {
              %c2_i64 = arith.constant 2 : i64
              %190 = arith.addi %125, %c2_i64 : i64
              %int_tuple_511 = cute.make_int_tuple(%190) : (i64) -> !cute.int_tuple<"?{i64}">
              %ptr_512 = cute.add_offset(%iter_477, %int_tuple_511) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
              %int_tuple_513 = cute.make_int_tuple() : () -> !cute.int_tuple<"6">
              %ptr_514 = cute.add_offset(%iter_479, %int_tuple_513) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
              %191 = builtin.unrealized_conversion_cast %ptr_512 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %192 = builtin.unrealized_conversion_cast %ptr_514 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
              %193 = llvm.load %191 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %193, %192 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %int_tuple_493 = cute.make_int_tuple() : () -> !cute.int_tuple<"7">
            %ptr_494 = cute.add_offset(%iter_480, %int_tuple_493) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
            %154 = builtin.unrealized_conversion_cast %ptr_494 : !cute.ptr<i8, rmem> to !llvm.ptr
            %155 = llvm.load %154 : !llvm.ptr -> i8
            %156 = llvm.mlir.constant(0 : i8) : i8
            %157 = llvm.icmp "ne" %155, %156 : i8
            scf.if %157 {
              %c3_i64 = arith.constant 3 : i64
              %190 = arith.addi %125, %c3_i64 : i64
              %int_tuple_511 = cute.make_int_tuple(%190) : (i64) -> !cute.int_tuple<"?{i64}">
              %ptr_512 = cute.add_offset(%iter_477, %int_tuple_511) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
              %int_tuple_513 = cute.make_int_tuple() : () -> !cute.int_tuple<"7">
              %ptr_514 = cute.add_offset(%iter_479, %int_tuple_513) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<f32, rmem>
              %191 = builtin.unrealized_conversion_cast %ptr_512 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %192 = builtin.unrealized_conversion_cast %ptr_514 : !cute.ptr<f32, rmem> to !llvm.ptr
              %193 = llvm.load %191 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %193, %192 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %int_tuple_495 = cute.make_int_tuple() : () -> !cute.int_tuple<"8">
            %ptr_496 = cute.add_offset(%iter_480, %int_tuple_495) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<i8, rmem, align<8>>
            %158 = builtin.unrealized_conversion_cast %ptr_496 : !cute.ptr<i8, rmem, align<8>> to !llvm.ptr
            %159 = llvm.load %158 : !llvm.ptr -> i8
            %160 = llvm.mlir.constant(0 : i8) : i8
            %161 = llvm.icmp "ne" %159, %160 : i8
            scf.if %161 {
              %c2_i64 = arith.constant 2 : i64
              %190 = arith.muli %125, %c2_i64 : i64
              %iv_511 = cute.assume(%190) : (i64) -> !cute.i64<divby 2>
              %int_tuple_512 = cute.make_int_tuple(%iv_511) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
              %ptr_513 = cute.add_offset(%iter_477, %int_tuple_512) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
              %int_tuple_514 = cute.make_int_tuple() : () -> !cute.int_tuple<"8">
              %ptr_515 = cute.add_offset(%iter_479, %int_tuple_514) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<f32, rmem, align<32>>
              %191 = builtin.unrealized_conversion_cast %ptr_513 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %192 = builtin.unrealized_conversion_cast %ptr_515 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
              %193 = llvm.load %191 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %193, %192 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %int_tuple_497 = cute.make_int_tuple() : () -> !cute.int_tuple<"9">
            %ptr_498 = cute.add_offset(%iter_480, %int_tuple_497) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<i8, rmem>
            %162 = builtin.unrealized_conversion_cast %ptr_498 : !cute.ptr<i8, rmem> to !llvm.ptr
            %163 = llvm.load %162 : !llvm.ptr -> i8
            %164 = llvm.mlir.constant(0 : i8) : i8
            %165 = llvm.icmp "ne" %163, %164 : i8
            scf.if %165 {
              %c2_i64 = arith.constant 2 : i64
              %190 = arith.muli %125, %c2_i64 : i64
              %c1_i64 = arith.constant 1 : i64
              %191 = arith.addi %190, %c1_i64 : i64
              %int_tuple_511 = cute.make_int_tuple(%191) : (i64) -> !cute.int_tuple<"?{i64}">
              %ptr_512 = cute.add_offset(%iter_477, %int_tuple_511) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
              %int_tuple_513 = cute.make_int_tuple() : () -> !cute.int_tuple<"9">
              %ptr_514 = cute.add_offset(%iter_479, %int_tuple_513) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<f32, rmem>
              %192 = builtin.unrealized_conversion_cast %ptr_512 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %193 = builtin.unrealized_conversion_cast %ptr_514 : !cute.ptr<f32, rmem> to !llvm.ptr
              %194 = llvm.load %192 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %194, %193 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %int_tuple_499 = cute.make_int_tuple() : () -> !cute.int_tuple<"10">
            %ptr_500 = cute.add_offset(%iter_480, %int_tuple_499) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<i8, rmem, align<2>>
            %166 = builtin.unrealized_conversion_cast %ptr_500 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
            %167 = llvm.load %166 : !llvm.ptr -> i8
            %168 = llvm.mlir.constant(0 : i8) : i8
            %169 = llvm.icmp "ne" %167, %168 : i8
            scf.if %169 {
              %c2_i64 = arith.constant 2 : i64
              %190 = arith.muli %125, %c2_i64 : i64
              %c2_i64_511 = arith.constant 2 : i64
              %191 = arith.addi %190, %c2_i64_511 : i64
              %iv_512 = cute.assume(%191) : (i64) -> !cute.i64<divby 2>
              %int_tuple_513 = cute.make_int_tuple(%iv_512) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
              %ptr_514 = cute.add_offset(%iter_477, %int_tuple_513) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
              %int_tuple_515 = cute.make_int_tuple() : () -> !cute.int_tuple<"10">
              %ptr_516 = cute.add_offset(%iter_479, %int_tuple_515) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<f32, rmem, align<8>>
              %192 = builtin.unrealized_conversion_cast %ptr_514 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %193 = builtin.unrealized_conversion_cast %ptr_516 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
              %194 = llvm.load %192 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %194, %193 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %int_tuple_501 = cute.make_int_tuple() : () -> !cute.int_tuple<"11">
            %ptr_502 = cute.add_offset(%iter_480, %int_tuple_501) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<i8, rmem>
            %170 = builtin.unrealized_conversion_cast %ptr_502 : !cute.ptr<i8, rmem> to !llvm.ptr
            %171 = llvm.load %170 : !llvm.ptr -> i8
            %172 = llvm.mlir.constant(0 : i8) : i8
            %173 = llvm.icmp "ne" %171, %172 : i8
            scf.if %173 {
              %c2_i64 = arith.constant 2 : i64
              %190 = arith.muli %125, %c2_i64 : i64
              %c3_i64 = arith.constant 3 : i64
              %191 = arith.addi %190, %c3_i64 : i64
              %int_tuple_511 = cute.make_int_tuple(%191) : (i64) -> !cute.int_tuple<"?{i64}">
              %ptr_512 = cute.add_offset(%iter_477, %int_tuple_511) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
              %int_tuple_513 = cute.make_int_tuple() : () -> !cute.int_tuple<"11">
              %ptr_514 = cute.add_offset(%iter_479, %int_tuple_513) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<f32, rmem>
              %192 = builtin.unrealized_conversion_cast %ptr_512 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %193 = builtin.unrealized_conversion_cast %ptr_514 : !cute.ptr<f32, rmem> to !llvm.ptr
              %194 = llvm.load %192 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %194, %193 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %int_tuple_503 = cute.make_int_tuple() : () -> !cute.int_tuple<"12">
            %ptr_504 = cute.add_offset(%iter_480, %int_tuple_503) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<i8, rmem, align<4>>
            %174 = builtin.unrealized_conversion_cast %ptr_504 : !cute.ptr<i8, rmem, align<4>> to !llvm.ptr
            %175 = llvm.load %174 : !llvm.ptr -> i8
            %176 = llvm.mlir.constant(0 : i8) : i8
            %177 = llvm.icmp "ne" %175, %176 : i8
            scf.if %177 {
              %c3_i64 = arith.constant 3 : i64
              %190 = arith.muli %125, %c3_i64 : i64
              %iv_511 = cute.assume(%190) : (i64) -> !cute.i64<divby 3>
              %int_tuple_512 = cute.make_int_tuple(%iv_511) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
              %ptr_513 = cute.add_offset(%iter_477, %int_tuple_512) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
              %int_tuple_514 = cute.make_int_tuple() : () -> !cute.int_tuple<"12">
              %ptr_515 = cute.add_offset(%iter_479, %int_tuple_514) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<f32, rmem, align<16>>
              %191 = builtin.unrealized_conversion_cast %ptr_513 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %192 = builtin.unrealized_conversion_cast %ptr_515 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              %193 = llvm.load %191 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %193, %192 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %int_tuple_505 = cute.make_int_tuple() : () -> !cute.int_tuple<"13">
            %ptr_506 = cute.add_offset(%iter_480, %int_tuple_505) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<i8, rmem>
            %178 = builtin.unrealized_conversion_cast %ptr_506 : !cute.ptr<i8, rmem> to !llvm.ptr
            %179 = llvm.load %178 : !llvm.ptr -> i8
            %180 = llvm.mlir.constant(0 : i8) : i8
            %181 = llvm.icmp "ne" %179, %180 : i8
            scf.if %181 {
              %c3_i64 = arith.constant 3 : i64
              %190 = arith.muli %125, %c3_i64 : i64
              %c1_i64 = arith.constant 1 : i64
              %191 = arith.addi %190, %c1_i64 : i64
              %int_tuple_511 = cute.make_int_tuple(%191) : (i64) -> !cute.int_tuple<"?{i64}">
              %ptr_512 = cute.add_offset(%iter_477, %int_tuple_511) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
              %int_tuple_513 = cute.make_int_tuple() : () -> !cute.int_tuple<"13">
              %ptr_514 = cute.add_offset(%iter_479, %int_tuple_513) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<f32, rmem>
              %192 = builtin.unrealized_conversion_cast %ptr_512 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %193 = builtin.unrealized_conversion_cast %ptr_514 : !cute.ptr<f32, rmem> to !llvm.ptr
              %194 = llvm.load %192 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %194, %193 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %int_tuple_507 = cute.make_int_tuple() : () -> !cute.int_tuple<"14">
            %ptr_508 = cute.add_offset(%iter_480, %int_tuple_507) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<i8, rmem, align<2>>
            %182 = builtin.unrealized_conversion_cast %ptr_508 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
            %183 = llvm.load %182 : !llvm.ptr -> i8
            %184 = llvm.mlir.constant(0 : i8) : i8
            %185 = llvm.icmp "ne" %183, %184 : i8
            scf.if %185 {
              %c3_i64 = arith.constant 3 : i64
              %190 = arith.muli %125, %c3_i64 : i64
              %c2_i64 = arith.constant 2 : i64
              %191 = arith.addi %190, %c2_i64 : i64
              %int_tuple_511 = cute.make_int_tuple(%191) : (i64) -> !cute.int_tuple<"?{i64}">
              %ptr_512 = cute.add_offset(%iter_477, %int_tuple_511) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
              %int_tuple_513 = cute.make_int_tuple() : () -> !cute.int_tuple<"14">
              %ptr_514 = cute.add_offset(%iter_479, %int_tuple_513) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<f32, rmem, align<8>>
              %192 = builtin.unrealized_conversion_cast %ptr_512 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %193 = builtin.unrealized_conversion_cast %ptr_514 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
              %194 = llvm.load %192 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %194, %193 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %int_tuple_509 = cute.make_int_tuple() : () -> !cute.int_tuple<"15">
            %ptr_510 = cute.add_offset(%iter_480, %int_tuple_509) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<i8, rmem>
            %186 = builtin.unrealized_conversion_cast %ptr_510 : !cute.ptr<i8, rmem> to !llvm.ptr
            %187 = llvm.load %186 : !llvm.ptr -> i8
            %188 = llvm.mlir.constant(0 : i8) : i8
            %189 = llvm.icmp "ne" %187, %188 : i8
            scf.if %189 {
              %c3_i64 = arith.constant 3 : i64
              %190 = arith.muli %125, %c3_i64 : i64
              %c3_i64_511 = arith.constant 3 : i64
              %191 = arith.addi %190, %c3_i64_511 : i64
              %iv_512 = cute.assume(%191) : (i64) -> !cute.i64<divby 3>
              %int_tuple_513 = cute.make_int_tuple(%iv_512) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
              %ptr_514 = cute.add_offset(%iter_477, %int_tuple_513) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
              %int_tuple_515 = cute.make_int_tuple() : () -> !cute.int_tuple<"15">
              %ptr_516 = cute.add_offset(%iter_479, %int_tuple_515) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<f32, rmem>
              %192 = builtin.unrealized_conversion_cast %ptr_514 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %193 = builtin.unrealized_conversion_cast %ptr_516 : !cute.ptr<f32, rmem> to !llvm.ptr
              %194 = llvm.load %192 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %194, %193 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
          } {llvm.loop_annotation = #loop_annotation}
        }
        llvm.inline_asm has_side_effects asm_dialect = att "griddepcontrol.wait;", ""  : () -> ()
        scf.for %arg6 = %c0_i32_360 to %c10_i32_361 step %c1_i32_362  : i32 {
          %lay_363 = cute.get_layout(%view_173) : !memref_gmem_f32_2
          %110 = cute.get_shape(%lay_363) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_364, %e1_365, %e2_366, %e3_367, %e4_368 = cute.get_leaves(%110) : !cute.shape<"((1,(4,4)),1,1)">
          %lay_369 = cute.get_layout(%rmem) : !memref_rmem_f32_
          %111 = cute.get_shape(%lay_369) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_370, %e1_371, %e2_372, %e3_373, %e4_374 = cute.get_leaves(%111) : !cute.shape<"((1,(4,4)),1,1)">
          %lay_375 = cute.get_layout(%view_173) : !memref_gmem_f32_2
          %shape_376 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_377 = cute.make_layout() : !cute.layout<"1:0">
          %append_378 = cute.append_to_rank<2> (%lay_375, %lay_377) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">
          %view_379 = cute.make_view(%iter_174, %append_378) : !memref_gmem_f32_2
          %iter_380 = cute.get_iter(%view_379) : !memref_gmem_f32_2
          %lay_381 = cute.get_layout(%view_379) : !memref_gmem_f32_2
          %112 = cute.get_shape(%lay_381) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_382, %e1_383, %e2_384, %e3_385, %e4_386 = cute.get_leaves(%112) : !cute.shape<"((1,(4,4)),1,1)">
          %iter_387 = cute.get_iter(%view_379) : !memref_gmem_f32_2
          %lay_388 = cute.get_layout(%view_379) : !memref_gmem_f32_2
          %113 = cute.get_scalars(%lay_388) <{only_dynamic}> : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
          %shape_389 = cute.make_shape() : () -> !cute.shape<"((1,(4,4)),(1,1))">
          %stride_390 = cute.make_stride(%113) : (i64) -> !cute.stride<"((0,(1,?{i64})),(0,0))">
          %lay_391 = cute.make_layout(%shape_389, %stride_390) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
          %view_392 = cute.make_view(%iter_387, %lay_391) : !memref_gmem_f32_3
          %iter_393 = cute.get_iter(%view_392) : !memref_gmem_f32_3
          %iter_394 = cute.get_iter(%view_392) : !memref_gmem_f32_3
          %lay_395 = cute.get_layout(%rmem) : !memref_rmem_f32_
          %shape_396 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_397 = cute.make_layout() : !cute.layout<"1:0">
          %append_398 = cute.append_to_rank<2> (%lay_395, %lay_397) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
          %view_399 = cute.make_view(%iter_212, %append_398) : !memref_rmem_f32_
          %iter_400 = cute.get_iter(%view_399) : !memref_rmem_f32_
          %lay_401 = cute.get_layout(%view_399) : !memref_rmem_f32_
          %114 = cute.get_shape(%lay_401) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_402, %e1_403, %e2_404, %e3_405, %e4_406 = cute.get_leaves(%114) : !cute.shape<"((1,(4,4)),1,1)">
          %iter_407 = cute.get_iter(%view_399) : !memref_rmem_f32_
          %view_408 = cute.make_view(%iter_407) : !memref_rmem_f32_1
          %iter_409 = cute.get_iter(%view_408) : !memref_rmem_f32_1
          %iter_410 = cute.get_iter(%view_408) : !memref_rmem_f32_1
          %lay_411 = cute.get_layout(%97) : !memref_rmem_i8_
          %shape_412 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_413 = cute.make_layout() : !cute.layout<"1:0">
          %append_414 = cute.append_to_rank<2> (%lay_411, %lay_413) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
          %view_415 = cute.make_view(%iter_252, %append_414) : !memref_rmem_i8_
          %iter_416 = cute.get_iter(%view_415) : !memref_rmem_i8_
          %lay_417 = cute.get_layout(%view_415) : !memref_rmem_i8_
          %115 = cute.get_shape(%lay_417) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_418, %e1_419, %e2_420, %e3_421, %e4_422 = cute.get_leaves(%115) : !cute.shape<"((1,(4,4)),1,1)">
          %iter_423 = cute.get_iter(%view_415) : !memref_rmem_i8_
          %view_424 = cute.make_view(%iter_423) : !memref_rmem_i8_1
          %iter_425 = cute.get_iter(%view_424) : !memref_rmem_i8_1
          %iter_426 = cute.get_iter(%view_424) : !memref_rmem_i8_1
          %lay_427 = cute.get_layout(%view_392) : !memref_gmem_f32_3
          %116 = cute.get_shape(%lay_427) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
          %e0_428, %e1_429, %e2_430, %e3_431, %e4_432 = cute.get_leaves(%116) : !cute.shape<"((1,(4,4)),(1,1))">
          %lay_433 = cute.get_layout(%view_408) : !memref_rmem_f32_1
          %117 = cute.get_shape(%lay_433) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
          %e0_434, %e1_435, %e2_436, %e3_437, %e4_438 = cute.get_leaves(%117) : !cute.shape<"((1,(4,4)),(1,1))">
          %lay_439 = cute.get_layout(%view_392) : !memref_gmem_f32_3
          %sz_440 = cute.size(%lay_439) <{mode = [1]}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.int_tuple<"1">
          %e0_441 = cute.get_leaves(%sz_440) : !cute.int_tuple<"1">
          %lay_442 = cute.get_layout(%view_408) : !memref_rmem_f32_1
          %sz_443 = cute.size(%lay_442) <{mode = [1]}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.int_tuple<"1">
          %e0_444 = cute.get_leaves(%sz_443) : !cute.int_tuple<"1">
          %118 = cute.static : !cute.layout<"1:0">
          %iter_445 = cute.get_iter(%view_392) : !memref_gmem_f32_3
          %iter_446 = cute.get_iter(%view_408) : !memref_rmem_f32_1
          %lay_447 = cute.get_layout(%view_392) : !memref_gmem_f32_3
          %lay_448 = cute.get_layout(%view_408) : !memref_rmem_f32_1
          %append_449 = cute.append_to_rank<2> (%lay_447, %118) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">, !cute.layout<"1:0">
          %append_450 = cute.append_to_rank<2> (%lay_448, %118) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">, !cute.layout<"1:0">
          %119 = cute.get_scalars(%append_449) <{only_dynamic}> : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
          %shape_451 = cute.make_shape() : () -> !cute.shape<"((1,(4,4)),((1,1)))">
          %stride_452 = cute.make_stride(%119) : (i64) -> !cute.stride<"((0,(1,?{i64})),((0,0)))">
          %lay_453 = cute.make_layout(%shape_451, %stride_452) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
          %lay_454 = cute.make_layout() : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">
          %iter_455 = cute.get_iter(%view_424) : !memref_rmem_i8_1
          %lay_456 = cute.get_layout(%view_424) : !memref_rmem_i8_1
          %append_457 = cute.append_to_rank<2> (%lay_456, %118) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">, !cute.layout<"1:0">
          %lay_458 = cute.make_layout() : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">
          %sz_459 = cute.size(%lay_453) <{mode = [1]}> : (!cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">) -> !cute.int_tuple<"1">
          %120 = cute.get_scalars(%sz_459) : !cute.int_tuple<"1">
          %c0_i32_460 = arith.constant 0 : i32
          %c1_i32_461 = arith.constant 1 : i32
          scf.for %arg7 = %c0_i32_460 to %120 step %c1_i32_461  : i32 {
            %coord_462 = cute.make_coord(%arg7) : (i32) -> !cute.coord<"(_,?)">
            %121 = cute.get_scalars(%lay_453) <{only_dynamic}> : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
            %122 = cute.get_scalars(%coord_462) <{only_dynamic}> : !cute.coord<"(_,?)">
            %shape_463 = cute.make_shape() : () -> !cute.shape<"((1,(4,4)))">
            %stride_464 = cute.make_stride(%121) : (i64) -> !cute.stride<"((0,(1,?{i64})))">
            %lay_465 = cute.make_layout(%shape_463, %stride_464) : !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
            %idx_466 = cute.crd2idx(%coord_462, %lay_453) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">) -> !cute.int_tuple<"0">
            %ptr_467 = cute.add_offset(%iter_445, %idx_466) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<f32, gmem>
            %view_468 = cute.make_view(%ptr_467, %lay_465) : !memref_gmem_f32_4
            %123 = cute.get_scalars(%coord_462) <{only_dynamic}> : !cute.coord<"(_,?)">
            %lay_469 = cute.make_layout() : !cute.layout<"((1,(4,4))):((0,(1,4)))">
            %idx_470 = cute.crd2idx(%coord_462, %lay_454) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">) -> !cute.int_tuple<"0">
            %ptr_471 = cute.add_offset(%iter_446, %idx_470) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, rmem, align<32>>
            %view_472 = cute.make_view(%ptr_471, %lay_469) : !memref_rmem_f32_2
            %124 = cute.get_scalars(%coord_462) <{only_dynamic}> : !cute.coord<"(_,?)">
            %lay_473 = cute.make_layout() : !cute.layout<"((1,(4,4))):((0,(1,4)))">
            %idx_474 = cute.crd2idx(%coord_462, %lay_458) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">) -> !cute.int_tuple<"0">
            %ptr_475 = cute.add_offset(%iter_455, %idx_474) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
            %view_476 = cute.make_view(%ptr_475, %lay_473) : !memref_rmem_i8_2
            %iter_477 = cute.get_iter(%view_468) : !memref_gmem_f32_4
            %lay_478 = cute.get_layout(%view_468) : !memref_gmem_f32_4
            %125 = cute.get_scalars(%lay_478) <{only_dynamic}> : !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
            %iter_479 = cute.get_iter(%view_472) : !memref_rmem_f32_2
            %iter_480 = cute.get_iter(%view_476) : !memref_rmem_i8_2
            %126 = builtin.unrealized_conversion_cast %iter_480 : !cute.ptr<i8, rmem, align<32>> to !llvm.ptr
            %127 = llvm.load %126 : !llvm.ptr -> i8
            %128 = llvm.mlir.constant(0 : i8) : i8
            %129 = llvm.icmp "ne" %127, %128 : i8
            scf.if %129 {
              %190 = builtin.unrealized_conversion_cast %iter_477 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %191 = builtin.unrealized_conversion_cast %iter_479 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
              %192 = llvm.load %190 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %192, %191 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %int_tuple_481 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
            %ptr_482 = cute.add_offset(%iter_480, %int_tuple_481) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
            %130 = builtin.unrealized_conversion_cast %ptr_482 : !cute.ptr<i8, rmem> to !llvm.ptr
            %131 = llvm.load %130 : !llvm.ptr -> i8
            %132 = llvm.mlir.constant(0 : i8) : i8
            %133 = llvm.icmp "ne" %131, %132 : i8
            scf.if %133 {
              %int_tuple_511 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
              %ptr_512 = cute.add_offset(%iter_477, %int_tuple_511) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
              %int_tuple_513 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
              %ptr_514 = cute.add_offset(%iter_479, %int_tuple_513) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
              %190 = builtin.unrealized_conversion_cast %ptr_512 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %191 = builtin.unrealized_conversion_cast %ptr_514 : !cute.ptr<f32, rmem> to !llvm.ptr
              %192 = llvm.load %190 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %192, %191 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %int_tuple_483 = cute.make_int_tuple() : () -> !cute.int_tuple<"2">
            %ptr_484 = cute.add_offset(%iter_480, %int_tuple_483) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem, align<2>>
            %134 = builtin.unrealized_conversion_cast %ptr_484 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
            %135 = llvm.load %134 : !llvm.ptr -> i8
            %136 = llvm.mlir.constant(0 : i8) : i8
            %137 = llvm.icmp "ne" %135, %136 : i8
            scf.if %137 {
              %int_tuple_511 = cute.make_int_tuple() : () -> !cute.int_tuple<"2">
              %ptr_512 = cute.add_offset(%iter_477, %int_tuple_511) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
              %int_tuple_513 = cute.make_int_tuple() : () -> !cute.int_tuple<"2">
              %ptr_514 = cute.add_offset(%iter_479, %int_tuple_513) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
              %190 = builtin.unrealized_conversion_cast %ptr_512 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %191 = builtin.unrealized_conversion_cast %ptr_514 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
              %192 = llvm.load %190 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %192, %191 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %int_tuple_485 = cute.make_int_tuple() : () -> !cute.int_tuple<"3">
            %ptr_486 = cute.add_offset(%iter_480, %int_tuple_485) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
            %138 = builtin.unrealized_conversion_cast %ptr_486 : !cute.ptr<i8, rmem> to !llvm.ptr
            %139 = llvm.load %138 : !llvm.ptr -> i8
            %140 = llvm.mlir.constant(0 : i8) : i8
            %141 = llvm.icmp "ne" %139, %140 : i8
            scf.if %141 {
              %int_tuple_511 = cute.make_int_tuple() : () -> !cute.int_tuple<"3">
              %ptr_512 = cute.add_offset(%iter_477, %int_tuple_511) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
              %int_tuple_513 = cute.make_int_tuple() : () -> !cute.int_tuple<"3">
              %ptr_514 = cute.add_offset(%iter_479, %int_tuple_513) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
              %190 = builtin.unrealized_conversion_cast %ptr_512 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %191 = builtin.unrealized_conversion_cast %ptr_514 : !cute.ptr<f32, rmem> to !llvm.ptr
              %192 = llvm.load %190 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %192, %191 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %int_tuple_487 = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
            %ptr_488 = cute.add_offset(%iter_480, %int_tuple_487) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem, align<4>>
            %142 = builtin.unrealized_conversion_cast %ptr_488 : !cute.ptr<i8, rmem, align<4>> to !llvm.ptr
            %143 = llvm.load %142 : !llvm.ptr -> i8
            %144 = llvm.mlir.constant(0 : i8) : i8
            %145 = llvm.icmp "ne" %143, %144 : i8
            scf.if %145 {
              %int_tuple_511 = cute.make_int_tuple(%125) : (i64) -> !cute.int_tuple<"?{i64}">
              %ptr_512 = cute.add_offset(%iter_477, %int_tuple_511) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
              %int_tuple_513 = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
              %ptr_514 = cute.add_offset(%iter_479, %int_tuple_513) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
              %190 = builtin.unrealized_conversion_cast %ptr_512 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %191 = builtin.unrealized_conversion_cast %ptr_514 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              %192 = llvm.load %190 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %192, %191 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %int_tuple_489 = cute.make_int_tuple() : () -> !cute.int_tuple<"5">
            %ptr_490 = cute.add_offset(%iter_480, %int_tuple_489) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
            %146 = builtin.unrealized_conversion_cast %ptr_490 : !cute.ptr<i8, rmem> to !llvm.ptr
            %147 = llvm.load %146 : !llvm.ptr -> i8
            %148 = llvm.mlir.constant(0 : i8) : i8
            %149 = llvm.icmp "ne" %147, %148 : i8
            scf.if %149 {
              %c1_i64 = arith.constant 1 : i64
              %190 = arith.addi %125, %c1_i64 : i64
              %int_tuple_511 = cute.make_int_tuple(%190) : (i64) -> !cute.int_tuple<"?{i64}">
              %ptr_512 = cute.add_offset(%iter_477, %int_tuple_511) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
              %int_tuple_513 = cute.make_int_tuple() : () -> !cute.int_tuple<"5">
              %ptr_514 = cute.add_offset(%iter_479, %int_tuple_513) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<f32, rmem>
              %191 = builtin.unrealized_conversion_cast %ptr_512 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %192 = builtin.unrealized_conversion_cast %ptr_514 : !cute.ptr<f32, rmem> to !llvm.ptr
              %193 = llvm.load %191 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %193, %192 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %int_tuple_491 = cute.make_int_tuple() : () -> !cute.int_tuple<"6">
            %ptr_492 = cute.add_offset(%iter_480, %int_tuple_491) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem, align<2>>
            %150 = builtin.unrealized_conversion_cast %ptr_492 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
            %151 = llvm.load %150 : !llvm.ptr -> i8
            %152 = llvm.mlir.constant(0 : i8) : i8
            %153 = llvm.icmp "ne" %151, %152 : i8
            scf.if %153 {
              %c2_i64 = arith.constant 2 : i64
              %190 = arith.addi %125, %c2_i64 : i64
              %int_tuple_511 = cute.make_int_tuple(%190) : (i64) -> !cute.int_tuple<"?{i64}">
              %ptr_512 = cute.add_offset(%iter_477, %int_tuple_511) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
              %int_tuple_513 = cute.make_int_tuple() : () -> !cute.int_tuple<"6">
              %ptr_514 = cute.add_offset(%iter_479, %int_tuple_513) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
              %191 = builtin.unrealized_conversion_cast %ptr_512 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %192 = builtin.unrealized_conversion_cast %ptr_514 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
              %193 = llvm.load %191 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %193, %192 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %int_tuple_493 = cute.make_int_tuple() : () -> !cute.int_tuple<"7">
            %ptr_494 = cute.add_offset(%iter_480, %int_tuple_493) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
            %154 = builtin.unrealized_conversion_cast %ptr_494 : !cute.ptr<i8, rmem> to !llvm.ptr
            %155 = llvm.load %154 : !llvm.ptr -> i8
            %156 = llvm.mlir.constant(0 : i8) : i8
            %157 = llvm.icmp "ne" %155, %156 : i8
            scf.if %157 {
              %c3_i64 = arith.constant 3 : i64
              %190 = arith.addi %125, %c3_i64 : i64
              %int_tuple_511 = cute.make_int_tuple(%190) : (i64) -> !cute.int_tuple<"?{i64}">
              %ptr_512 = cute.add_offset(%iter_477, %int_tuple_511) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
              %int_tuple_513 = cute.make_int_tuple() : () -> !cute.int_tuple<"7">
              %ptr_514 = cute.add_offset(%iter_479, %int_tuple_513) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<f32, rmem>
              %191 = builtin.unrealized_conversion_cast %ptr_512 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %192 = builtin.unrealized_conversion_cast %ptr_514 : !cute.ptr<f32, rmem> to !llvm.ptr
              %193 = llvm.load %191 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %193, %192 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %int_tuple_495 = cute.make_int_tuple() : () -> !cute.int_tuple<"8">
            %ptr_496 = cute.add_offset(%iter_480, %int_tuple_495) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<i8, rmem, align<8>>
            %158 = builtin.unrealized_conversion_cast %ptr_496 : !cute.ptr<i8, rmem, align<8>> to !llvm.ptr
            %159 = llvm.load %158 : !llvm.ptr -> i8
            %160 = llvm.mlir.constant(0 : i8) : i8
            %161 = llvm.icmp "ne" %159, %160 : i8
            scf.if %161 {
              %c2_i64 = arith.constant 2 : i64
              %190 = arith.muli %125, %c2_i64 : i64
              %iv_511 = cute.assume(%190) : (i64) -> !cute.i64<divby 2>
              %int_tuple_512 = cute.make_int_tuple(%iv_511) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
              %ptr_513 = cute.add_offset(%iter_477, %int_tuple_512) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
              %int_tuple_514 = cute.make_int_tuple() : () -> !cute.int_tuple<"8">
              %ptr_515 = cute.add_offset(%iter_479, %int_tuple_514) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<f32, rmem, align<32>>
              %191 = builtin.unrealized_conversion_cast %ptr_513 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %192 = builtin.unrealized_conversion_cast %ptr_515 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
              %193 = llvm.load %191 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %193, %192 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %int_tuple_497 = cute.make_int_tuple() : () -> !cute.int_tuple<"9">
            %ptr_498 = cute.add_offset(%iter_480, %int_tuple_497) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<i8, rmem>
            %162 = builtin.unrealized_conversion_cast %ptr_498 : !cute.ptr<i8, rmem> to !llvm.ptr
            %163 = llvm.load %162 : !llvm.ptr -> i8
            %164 = llvm.mlir.constant(0 : i8) : i8
            %165 = llvm.icmp "ne" %163, %164 : i8
            scf.if %165 {
              %c2_i64 = arith.constant 2 : i64
              %190 = arith.muli %125, %c2_i64 : i64
              %c1_i64 = arith.constant 1 : i64
              %191 = arith.addi %190, %c1_i64 : i64
              %int_tuple_511 = cute.make_int_tuple(%191) : (i64) -> !cute.int_tuple<"?{i64}">
              %ptr_512 = cute.add_offset(%iter_477, %int_tuple_511) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
              %int_tuple_513 = cute.make_int_tuple() : () -> !cute.int_tuple<"9">
              %ptr_514 = cute.add_offset(%iter_479, %int_tuple_513) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<f32, rmem>
              %192 = builtin.unrealized_conversion_cast %ptr_512 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %193 = builtin.unrealized_conversion_cast %ptr_514 : !cute.ptr<f32, rmem> to !llvm.ptr
              %194 = llvm.load %192 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %194, %193 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %int_tuple_499 = cute.make_int_tuple() : () -> !cute.int_tuple<"10">
            %ptr_500 = cute.add_offset(%iter_480, %int_tuple_499) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<i8, rmem, align<2>>
            %166 = builtin.unrealized_conversion_cast %ptr_500 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
            %167 = llvm.load %166 : !llvm.ptr -> i8
            %168 = llvm.mlir.constant(0 : i8) : i8
            %169 = llvm.icmp "ne" %167, %168 : i8
            scf.if %169 {
              %c2_i64 = arith.constant 2 : i64
              %190 = arith.muli %125, %c2_i64 : i64
              %c2_i64_511 = arith.constant 2 : i64
              %191 = arith.addi %190, %c2_i64_511 : i64
              %iv_512 = cute.assume(%191) : (i64) -> !cute.i64<divby 2>
              %int_tuple_513 = cute.make_int_tuple(%iv_512) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
              %ptr_514 = cute.add_offset(%iter_477, %int_tuple_513) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
              %int_tuple_515 = cute.make_int_tuple() : () -> !cute.int_tuple<"10">
              %ptr_516 = cute.add_offset(%iter_479, %int_tuple_515) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<f32, rmem, align<8>>
              %192 = builtin.unrealized_conversion_cast %ptr_514 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %193 = builtin.unrealized_conversion_cast %ptr_516 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
              %194 = llvm.load %192 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %194, %193 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %int_tuple_501 = cute.make_int_tuple() : () -> !cute.int_tuple<"11">
            %ptr_502 = cute.add_offset(%iter_480, %int_tuple_501) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<i8, rmem>
            %170 = builtin.unrealized_conversion_cast %ptr_502 : !cute.ptr<i8, rmem> to !llvm.ptr
            %171 = llvm.load %170 : !llvm.ptr -> i8
            %172 = llvm.mlir.constant(0 : i8) : i8
            %173 = llvm.icmp "ne" %171, %172 : i8
            scf.if %173 {
              %c2_i64 = arith.constant 2 : i64
              %190 = arith.muli %125, %c2_i64 : i64
              %c3_i64 = arith.constant 3 : i64
              %191 = arith.addi %190, %c3_i64 : i64
              %int_tuple_511 = cute.make_int_tuple(%191) : (i64) -> !cute.int_tuple<"?{i64}">
              %ptr_512 = cute.add_offset(%iter_477, %int_tuple_511) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
              %int_tuple_513 = cute.make_int_tuple() : () -> !cute.int_tuple<"11">
              %ptr_514 = cute.add_offset(%iter_479, %int_tuple_513) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<f32, rmem>
              %192 = builtin.unrealized_conversion_cast %ptr_512 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %193 = builtin.unrealized_conversion_cast %ptr_514 : !cute.ptr<f32, rmem> to !llvm.ptr
              %194 = llvm.load %192 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %194, %193 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %int_tuple_503 = cute.make_int_tuple() : () -> !cute.int_tuple<"12">
            %ptr_504 = cute.add_offset(%iter_480, %int_tuple_503) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<i8, rmem, align<4>>
            %174 = builtin.unrealized_conversion_cast %ptr_504 : !cute.ptr<i8, rmem, align<4>> to !llvm.ptr
            %175 = llvm.load %174 : !llvm.ptr -> i8
            %176 = llvm.mlir.constant(0 : i8) : i8
            %177 = llvm.icmp "ne" %175, %176 : i8
            scf.if %177 {
              %c3_i64 = arith.constant 3 : i64
              %190 = arith.muli %125, %c3_i64 : i64
              %iv_511 = cute.assume(%190) : (i64) -> !cute.i64<divby 3>
              %int_tuple_512 = cute.make_int_tuple(%iv_511) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
              %ptr_513 = cute.add_offset(%iter_477, %int_tuple_512) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
              %int_tuple_514 = cute.make_int_tuple() : () -> !cute.int_tuple<"12">
              %ptr_515 = cute.add_offset(%iter_479, %int_tuple_514) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<f32, rmem, align<16>>
              %191 = builtin.unrealized_conversion_cast %ptr_513 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %192 = builtin.unrealized_conversion_cast %ptr_515 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              %193 = llvm.load %191 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %193, %192 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %int_tuple_505 = cute.make_int_tuple() : () -> !cute.int_tuple<"13">
            %ptr_506 = cute.add_offset(%iter_480, %int_tuple_505) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<i8, rmem>
            %178 = builtin.unrealized_conversion_cast %ptr_506 : !cute.ptr<i8, rmem> to !llvm.ptr
            %179 = llvm.load %178 : !llvm.ptr -> i8
            %180 = llvm.mlir.constant(0 : i8) : i8
            %181 = llvm.icmp "ne" %179, %180 : i8
            scf.if %181 {
              %c3_i64 = arith.constant 3 : i64
              %190 = arith.muli %125, %c3_i64 : i64
              %c1_i64 = arith.constant 1 : i64
              %191 = arith.addi %190, %c1_i64 : i64
              %int_tuple_511 = cute.make_int_tuple(%191) : (i64) -> !cute.int_tuple<"?{i64}">
              %ptr_512 = cute.add_offset(%iter_477, %int_tuple_511) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
              %int_tuple_513 = cute.make_int_tuple() : () -> !cute.int_tuple<"13">
              %ptr_514 = cute.add_offset(%iter_479, %int_tuple_513) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<f32, rmem>
              %192 = builtin.unrealized_conversion_cast %ptr_512 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %193 = builtin.unrealized_conversion_cast %ptr_514 : !cute.ptr<f32, rmem> to !llvm.ptr
              %194 = llvm.load %192 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %194, %193 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %int_tuple_507 = cute.make_int_tuple() : () -> !cute.int_tuple<"14">
            %ptr_508 = cute.add_offset(%iter_480, %int_tuple_507) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<i8, rmem, align<2>>
            %182 = builtin.unrealized_conversion_cast %ptr_508 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
            %183 = llvm.load %182 : !llvm.ptr -> i8
            %184 = llvm.mlir.constant(0 : i8) : i8
            %185 = llvm.icmp "ne" %183, %184 : i8
            scf.if %185 {
              %c3_i64 = arith.constant 3 : i64
              %190 = arith.muli %125, %c3_i64 : i64
              %c2_i64 = arith.constant 2 : i64
              %191 = arith.addi %190, %c2_i64 : i64
              %int_tuple_511 = cute.make_int_tuple(%191) : (i64) -> !cute.int_tuple<"?{i64}">
              %ptr_512 = cute.add_offset(%iter_477, %int_tuple_511) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
              %int_tuple_513 = cute.make_int_tuple() : () -> !cute.int_tuple<"14">
              %ptr_514 = cute.add_offset(%iter_479, %int_tuple_513) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<f32, rmem, align<8>>
              %192 = builtin.unrealized_conversion_cast %ptr_512 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %193 = builtin.unrealized_conversion_cast %ptr_514 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
              %194 = llvm.load %192 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %194, %193 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %int_tuple_509 = cute.make_int_tuple() : () -> !cute.int_tuple<"15">
            %ptr_510 = cute.add_offset(%iter_480, %int_tuple_509) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<i8, rmem>
            %186 = builtin.unrealized_conversion_cast %ptr_510 : !cute.ptr<i8, rmem> to !llvm.ptr
            %187 = llvm.load %186 : !llvm.ptr -> i8
            %188 = llvm.mlir.constant(0 : i8) : i8
            %189 = llvm.icmp "ne" %187, %188 : i8
            scf.if %189 {
              %c3_i64 = arith.constant 3 : i64
              %190 = arith.muli %125, %c3_i64 : i64
              %c3_i64_511 = arith.constant 3 : i64
              %191 = arith.addi %190, %c3_i64_511 : i64
              %iv_512 = cute.assume(%191) : (i64) -> !cute.i64<divby 3>
              %int_tuple_513 = cute.make_int_tuple(%iv_512) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
              %ptr_514 = cute.add_offset(%iter_477, %int_tuple_513) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
              %int_tuple_515 = cute.make_int_tuple() : () -> !cute.int_tuple<"15">
              %ptr_516 = cute.add_offset(%iter_479, %int_tuple_515) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<f32, rmem>
              %192 = builtin.unrealized_conversion_cast %ptr_514 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %193 = builtin.unrealized_conversion_cast %ptr_516 : !cute.ptr<f32, rmem> to !llvm.ptr
              %194 = llvm.load %192 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %194, %193 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
          } {llvm.loop_annotation = #loop_annotation}
        }
      }
      %c10_i32 = arith.constant 10 : i32
      %98:3 = scf.for %arg6 = %c0_i32 to %c10_i32 step %c1_i32 iter_args(%arg7 = %rmem, %arg8 = %rmem_215, %arg9 = %rmem_220) -> (!memref_rmem_f32_, !memref_rmem_f32_, !memref_rmem_f32_)  : i32 {
        %iter_360 = cute.get_iter(%arg7) : !memref_rmem_f32_
        %iter_361 = cute.get_iter(%arg8) : !memref_rmem_f32_
        %iter_362 = cute.get_iter(%arg9) : !memref_rmem_f32_
        %iter_363 = cute.get_iter(%arg7) : !memref_rmem_f32_
        %iter_364 = cute.get_iter(%arg8) : !memref_rmem_f32_
        %iter_365 = cute.get_iter(%arg9) : !memref_rmem_f32_
        %lay_366 = cute.get_layout(%arg7) : !memref_rmem_f32_
        %110 = cute.get_shape(%lay_366) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
        %e0_367, %e1_368, %e2_369, %e3_370, %e4_371 = cute.get_leaves(%110) : !cute.shape<"((1,(4,4)),1,1)">
        %111 = cute.memref.load_vec %arg7 : !memref_rmem_f32_
        %lay_372 = cute.get_layout(%arg8) : !memref_rmem_f32_
        %112 = cute.get_shape(%lay_372) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
        %e0_373, %e1_374, %e2_375, %e3_376, %e4_377 = cute.get_leaves(%112) : !cute.shape<"((1,(4,4)),1,1)">
        %113 = cute.memref.load_vec %arg8 : !memref_rmem_f32_
        %114 = arith.addf %111, %113 : vector<16xf32>
        %lay_378 = cute.get_layout(%arg9) : !memref_rmem_f32_
        %115 = cute.get_shape(%lay_378) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
        %e0_379, %e1_380, %e2_381, %e3_382, %e4_383 = cute.get_leaves(%115) : !cute.shape<"((1,(4,4)),1,1)">
        %int_tuple_384 = cute.make_int_tuple() : () -> !cute.int_tuple<"((1,(4,4)),1,1)">
        %sz_385 = cute.size(%int_tuple_384) : (!cute.int_tuple<"((1,(4,4)),1,1)">) -> !cute.int_tuple<"16">
        %e0_386 = cute.get_leaves(%sz_385) : !cute.int_tuple<"16">
        %int_tuple_387 = cute.make_int_tuple() : () -> !cute.int_tuple<"((1,(4,4)),1,1)">
        %sz_388 = cute.size(%int_tuple_387) : (!cute.int_tuple<"((1,(4,4)),1,1)">) -> !cute.int_tuple<"16">
        %e0_389 = cute.get_leaves(%sz_388) : !cute.int_tuple<"16">
        cute.memref.store_vec %114, %arg9 : !memref_rmem_f32_
        scf.yield %arg7, %arg8, %arg9 : !memref_rmem_f32_, !memref_rmem_f32_, !memref_rmem_f32_
      }
      %iter_253 = cute.get_iter(%98#0) : !memref_rmem_f32_
      %iter_254 = cute.get_iter(%98#1) : !memref_rmem_f32_
      %iter_255 = cute.get_iter(%98#2) : !memref_rmem_f32_
      %iter_256 = cute.get_iter(%98#0) : !memref_rmem_f32_
      %iter_257 = cute.get_iter(%98#0) : !memref_rmem_f32_
      %iter_258 = cute.get_iter(%98#1) : !memref_rmem_f32_
      %iter_259 = cute.get_iter(%98#1) : !memref_rmem_f32_
      %iter_260 = cute.get_iter(%98#2) : !memref_rmem_f32_
      %iter_261 = cute.get_iter(%98#2) : !memref_rmem_f32_
      %lay_262 = cute.get_layout(%98#2) : !memref_rmem_f32_
      %99 = cute.get_shape(%lay_262) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_263, %e1_264, %e2_265, %e3_266, %e4_267 = cute.get_leaves(%99) : !cute.shape<"((1,(4,4)),1,1)">
      %lay_268 = cute.get_layout(%view_207) : !memref_gmem_f32_2
      %100 = cute.get_shape(%lay_268) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_269, %e1_270, %e2_271, %e3_272, %e4_273 = cute.get_leaves(%100) : !cute.shape<"((1,(4,4)),1,1)">
      %lay_274 = cute.get_layout(%98#2) : !memref_rmem_f32_
      %shape_275 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_276 = cute.make_layout() : !cute.layout<"1:0">
      %append = cute.append_to_rank<2> (%lay_274, %lay_276) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
      %view_277 = cute.make_view(%iter_261, %append) : !memref_rmem_f32_
      %iter_278 = cute.get_iter(%view_277) : !memref_rmem_f32_
      %lay_279 = cute.get_layout(%view_277) : !memref_rmem_f32_
      %101 = cute.get_shape(%lay_279) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_280, %e1_281, %e2_282, %e3_283, %e4_284 = cute.get_leaves(%101) : !cute.shape<"((1,(4,4)),1,1)">
      %iter_285 = cute.get_iter(%view_277) : !memref_rmem_f32_
      %view_286 = cute.make_view(%iter_285) : !memref_rmem_f32_1
      %iter_287 = cute.get_iter(%view_286) : !memref_rmem_f32_1
      %iter_288 = cute.get_iter(%view_286) : !memref_rmem_f32_1
      %lay_289 = cute.get_layout(%view_207) : !memref_gmem_f32_2
      %shape_290 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_291 = cute.make_layout() : !cute.layout<"1:0">
      %append_292 = cute.append_to_rank<2> (%lay_289, %lay_291) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">
      %view_293 = cute.make_view(%iter_208, %append_292) : !memref_gmem_f32_2
      %iter_294 = cute.get_iter(%view_293) : !memref_gmem_f32_2
      %lay_295 = cute.get_layout(%view_293) : !memref_gmem_f32_2
      %102 = cute.get_shape(%lay_295) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_296, %e1_297, %e2_298, %e3_299, %e4_300 = cute.get_leaves(%102) : !cute.shape<"((1,(4,4)),1,1)">
      %iter_301 = cute.get_iter(%view_293) : !memref_gmem_f32_2
      %lay_302 = cute.get_layout(%view_293) : !memref_gmem_f32_2
      %103 = cute.get_scalars(%lay_302) <{only_dynamic}> : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %shape_303 = cute.make_shape() : () -> !cute.shape<"((1,(4,4)),(1,1))">
      %stride_304 = cute.make_stride(%103) : (i64) -> !cute.stride<"((0,(1,?{i64})),(0,0))">
      %lay_305 = cute.make_layout(%shape_303, %stride_304) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %view_306 = cute.make_view(%iter_301, %lay_305) : !memref_gmem_f32_3
      %iter_307 = cute.get_iter(%view_306) : !memref_gmem_f32_3
      %iter_308 = cute.get_iter(%view_306) : !memref_gmem_f32_3
      %lay_309 = cute.get_layout(%97) : !memref_rmem_i8_
      %shape_310 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_311 = cute.make_layout() : !cute.layout<"1:0">
      %append_312 = cute.append_to_rank<2> (%lay_309, %lay_311) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
      %view_313 = cute.make_view(%iter_252, %append_312) : !memref_rmem_i8_
      %iter_314 = cute.get_iter(%view_313) : !memref_rmem_i8_
      %lay_315 = cute.get_layout(%view_313) : !memref_rmem_i8_
      %104 = cute.get_shape(%lay_315) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_316, %e1_317, %e2_318, %e3_319, %e4_320 = cute.get_leaves(%104) : !cute.shape<"((1,(4,4)),1,1)">
      %iter_321 = cute.get_iter(%view_313) : !memref_rmem_i8_
      %view_322 = cute.make_view(%iter_321) : !memref_rmem_i8_1
      %iter_323 = cute.get_iter(%view_322) : !memref_rmem_i8_1
      %iter_324 = cute.get_iter(%view_322) : !memref_rmem_i8_1
      %lay_325 = cute.get_layout(%view_286) : !memref_rmem_f32_1
      %105 = cute.get_shape(%lay_325) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
      %e0_326, %e1_327, %e2_328, %e3_329, %e4_330 = cute.get_leaves(%105) : !cute.shape<"((1,(4,4)),(1,1))">
      %lay_331 = cute.get_layout(%view_306) : !memref_gmem_f32_3
      %106 = cute.get_shape(%lay_331) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
      %e0_332, %e1_333, %e2_334, %e3_335, %e4_336 = cute.get_leaves(%106) : !cute.shape<"((1,(4,4)),(1,1))">
      %lay_337 = cute.get_layout(%view_286) : !memref_rmem_f32_1
      %sz_338 = cute.size(%lay_337) <{mode = [1]}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.int_tuple<"1">
      %e0_339 = cute.get_leaves(%sz_338) : !cute.int_tuple<"1">
      %lay_340 = cute.get_layout(%view_306) : !memref_gmem_f32_3
      %sz_341 = cute.size(%lay_340) <{mode = [1]}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.int_tuple<"1">
      %e0_342 = cute.get_leaves(%sz_341) : !cute.int_tuple<"1">
      %107 = cute.static : !cute.layout<"1:0">
      %iter_343 = cute.get_iter(%view_286) : !memref_rmem_f32_1
      %iter_344 = cute.get_iter(%view_306) : !memref_gmem_f32_3
      %lay_345 = cute.get_layout(%view_286) : !memref_rmem_f32_1
      %lay_346 = cute.get_layout(%view_306) : !memref_gmem_f32_3
      %append_347 = cute.append_to_rank<2> (%lay_345, %107) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">, !cute.layout<"1:0">
      %append_348 = cute.append_to_rank<2> (%lay_346, %107) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">, !cute.layout<"1:0">
      %lay_349 = cute.make_layout() : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">
      %108 = cute.get_scalars(%append_348) <{only_dynamic}> : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %shape_350 = cute.make_shape() : () -> !cute.shape<"((1,(4,4)),((1,1)))">
      %stride_351 = cute.make_stride(%108) : (i64) -> !cute.stride<"((0,(1,?{i64})),((0,0)))">
      %lay_352 = cute.make_layout(%shape_350, %stride_351) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
      %iter_353 = cute.get_iter(%view_322) : !memref_rmem_i8_1
      %lay_354 = cute.get_layout(%view_322) : !memref_rmem_i8_1
      %append_355 = cute.append_to_rank<2> (%lay_354, %107) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">, !cute.layout<"1:0">
      %lay_356 = cute.make_layout() : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">
      %sz_357 = cute.size(%lay_349) <{mode = [1]}> : (!cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">) -> !cute.int_tuple<"1">
      %109 = cute.get_scalars(%sz_357) : !cute.int_tuple<"1">
      %c0_i32_358 = arith.constant 0 : i32
      %c1_i32_359 = arith.constant 1 : i32
      scf.for %arg6 = %c0_i32_358 to %109 step %c1_i32_359  : i32 {
        %coord_360 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
        %110 = cute.get_scalars(%coord_360) <{only_dynamic}> : !cute.coord<"(_,?)">
        %lay_361 = cute.make_layout() : !cute.layout<"((1,(4,4))):((0,(1,4)))">
        %idx_362 = cute.crd2idx(%coord_360, %lay_349) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">) -> !cute.int_tuple<"0">
        %ptr_363 = cute.add_offset(%iter_343, %idx_362) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, rmem, align<32>>
        %view_364 = cute.make_view(%ptr_363, %lay_361) : !memref_rmem_f32_2
        %111 = cute.get_scalars(%lay_352) <{only_dynamic}> : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
        %112 = cute.get_scalars(%coord_360) <{only_dynamic}> : !cute.coord<"(_,?)">
        %shape_365 = cute.make_shape() : () -> !cute.shape<"((1,(4,4)))">
        %stride_366 = cute.make_stride(%111) : (i64) -> !cute.stride<"((0,(1,?{i64})))">
        %lay_367 = cute.make_layout(%shape_365, %stride_366) : !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
        %idx_368 = cute.crd2idx(%coord_360, %lay_352) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">) -> !cute.int_tuple<"0">
        %ptr_369 = cute.add_offset(%iter_344, %idx_368) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<f32, gmem>
        %view_370 = cute.make_view(%ptr_369, %lay_367) : !memref_gmem_f32_4
        %113 = cute.get_scalars(%coord_360) <{only_dynamic}> : !cute.coord<"(_,?)">
        %lay_371 = cute.make_layout() : !cute.layout<"((1,(4,4))):((0,(1,4)))">
        %idx_372 = cute.crd2idx(%coord_360, %lay_356) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">) -> !cute.int_tuple<"0">
        %ptr_373 = cute.add_offset(%iter_353, %idx_372) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
        %view_374 = cute.make_view(%ptr_373, %lay_371) : !memref_rmem_i8_2
        %iter_375 = cute.get_iter(%view_364) : !memref_rmem_f32_2
        %iter_376 = cute.get_iter(%view_370) : !memref_gmem_f32_4
        %lay_377 = cute.get_layout(%view_370) : !memref_gmem_f32_4
        %114 = cute.get_scalars(%lay_377) <{only_dynamic}> : !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
        %iter_378 = cute.get_iter(%view_374) : !memref_rmem_i8_2
        %115 = builtin.unrealized_conversion_cast %iter_378 : !cute.ptr<i8, rmem, align<32>> to !llvm.ptr
        %116 = llvm.load %115 : !llvm.ptr -> i8
        %117 = llvm.mlir.constant(0 : i8) : i8
        %118 = llvm.icmp "ne" %116, %117 : i8
        scf.if %118 {
          %179 = builtin.unrealized_conversion_cast %iter_375 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
          %180 = builtin.unrealized_conversion_cast %iter_376 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %181 = llvm.load %179 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %181, %180 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %int_tuple_379 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
        %ptr_380 = cute.add_offset(%iter_378, %int_tuple_379) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
        %119 = builtin.unrealized_conversion_cast %ptr_380 : !cute.ptr<i8, rmem> to !llvm.ptr
        %120 = llvm.load %119 : !llvm.ptr -> i8
        %121 = llvm.mlir.constant(0 : i8) : i8
        %122 = llvm.icmp "ne" %120, %121 : i8
        scf.if %122 {
          %int_tuple_409 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
          %ptr_410 = cute.add_offset(%iter_375, %int_tuple_409) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
          %int_tuple_411 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
          %ptr_412 = cute.add_offset(%iter_376, %int_tuple_411) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
          %179 = builtin.unrealized_conversion_cast %ptr_410 : !cute.ptr<f32, rmem> to !llvm.ptr
          %180 = builtin.unrealized_conversion_cast %ptr_412 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %181 = llvm.load %179 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %181, %180 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %int_tuple_381 = cute.make_int_tuple() : () -> !cute.int_tuple<"2">
        %ptr_382 = cute.add_offset(%iter_378, %int_tuple_381) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem, align<2>>
        %123 = builtin.unrealized_conversion_cast %ptr_382 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
        %124 = llvm.load %123 : !llvm.ptr -> i8
        %125 = llvm.mlir.constant(0 : i8) : i8
        %126 = llvm.icmp "ne" %124, %125 : i8
        scf.if %126 {
          %int_tuple_409 = cute.make_int_tuple() : () -> !cute.int_tuple<"2">
          %ptr_410 = cute.add_offset(%iter_375, %int_tuple_409) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
          %int_tuple_411 = cute.make_int_tuple() : () -> !cute.int_tuple<"2">
          %ptr_412 = cute.add_offset(%iter_376, %int_tuple_411) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
          %179 = builtin.unrealized_conversion_cast %ptr_410 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %180 = builtin.unrealized_conversion_cast %ptr_412 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %181 = llvm.load %179 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %181, %180 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %int_tuple_383 = cute.make_int_tuple() : () -> !cute.int_tuple<"3">
        %ptr_384 = cute.add_offset(%iter_378, %int_tuple_383) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
        %127 = builtin.unrealized_conversion_cast %ptr_384 : !cute.ptr<i8, rmem> to !llvm.ptr
        %128 = llvm.load %127 : !llvm.ptr -> i8
        %129 = llvm.mlir.constant(0 : i8) : i8
        %130 = llvm.icmp "ne" %128, %129 : i8
        scf.if %130 {
          %int_tuple_409 = cute.make_int_tuple() : () -> !cute.int_tuple<"3">
          %ptr_410 = cute.add_offset(%iter_375, %int_tuple_409) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
          %int_tuple_411 = cute.make_int_tuple() : () -> !cute.int_tuple<"3">
          %ptr_412 = cute.add_offset(%iter_376, %int_tuple_411) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
          %179 = builtin.unrealized_conversion_cast %ptr_410 : !cute.ptr<f32, rmem> to !llvm.ptr
          %180 = builtin.unrealized_conversion_cast %ptr_412 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %181 = llvm.load %179 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %181, %180 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %int_tuple_385 = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
        %ptr_386 = cute.add_offset(%iter_378, %int_tuple_385) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem, align<4>>
        %131 = builtin.unrealized_conversion_cast %ptr_386 : !cute.ptr<i8, rmem, align<4>> to !llvm.ptr
        %132 = llvm.load %131 : !llvm.ptr -> i8
        %133 = llvm.mlir.constant(0 : i8) : i8
        %134 = llvm.icmp "ne" %132, %133 : i8
        scf.if %134 {
          %int_tuple_409 = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
          %ptr_410 = cute.add_offset(%iter_375, %int_tuple_409) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
          %int_tuple_411 = cute.make_int_tuple(%114) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_412 = cute.add_offset(%iter_376, %int_tuple_411) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %179 = builtin.unrealized_conversion_cast %ptr_410 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
          %180 = builtin.unrealized_conversion_cast %ptr_412 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %181 = llvm.load %179 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %181, %180 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %int_tuple_387 = cute.make_int_tuple() : () -> !cute.int_tuple<"5">
        %ptr_388 = cute.add_offset(%iter_378, %int_tuple_387) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
        %135 = builtin.unrealized_conversion_cast %ptr_388 : !cute.ptr<i8, rmem> to !llvm.ptr
        %136 = llvm.load %135 : !llvm.ptr -> i8
        %137 = llvm.mlir.constant(0 : i8) : i8
        %138 = llvm.icmp "ne" %136, %137 : i8
        scf.if %138 {
          %int_tuple_409 = cute.make_int_tuple() : () -> !cute.int_tuple<"5">
          %ptr_410 = cute.add_offset(%iter_375, %int_tuple_409) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<f32, rmem>
          %c1_i64 = arith.constant 1 : i64
          %179 = arith.addi %114, %c1_i64 : i64
          %int_tuple_411 = cute.make_int_tuple(%179) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_412 = cute.add_offset(%iter_376, %int_tuple_411) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %180 = builtin.unrealized_conversion_cast %ptr_410 : !cute.ptr<f32, rmem> to !llvm.ptr
          %181 = builtin.unrealized_conversion_cast %ptr_412 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %182 = llvm.load %180 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %182, %181 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %int_tuple_389 = cute.make_int_tuple() : () -> !cute.int_tuple<"6">
        %ptr_390 = cute.add_offset(%iter_378, %int_tuple_389) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem, align<2>>
        %139 = builtin.unrealized_conversion_cast %ptr_390 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
        %140 = llvm.load %139 : !llvm.ptr -> i8
        %141 = llvm.mlir.constant(0 : i8) : i8
        %142 = llvm.icmp "ne" %140, %141 : i8
        scf.if %142 {
          %int_tuple_409 = cute.make_int_tuple() : () -> !cute.int_tuple<"6">
          %ptr_410 = cute.add_offset(%iter_375, %int_tuple_409) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
          %c2_i64 = arith.constant 2 : i64
          %179 = arith.addi %114, %c2_i64 : i64
          %int_tuple_411 = cute.make_int_tuple(%179) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_412 = cute.add_offset(%iter_376, %int_tuple_411) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %180 = builtin.unrealized_conversion_cast %ptr_410 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %181 = builtin.unrealized_conversion_cast %ptr_412 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %182 = llvm.load %180 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %182, %181 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %int_tuple_391 = cute.make_int_tuple() : () -> !cute.int_tuple<"7">
        %ptr_392 = cute.add_offset(%iter_378, %int_tuple_391) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
        %143 = builtin.unrealized_conversion_cast %ptr_392 : !cute.ptr<i8, rmem> to !llvm.ptr
        %144 = llvm.load %143 : !llvm.ptr -> i8
        %145 = llvm.mlir.constant(0 : i8) : i8
        %146 = llvm.icmp "ne" %144, %145 : i8
        scf.if %146 {
          %int_tuple_409 = cute.make_int_tuple() : () -> !cute.int_tuple<"7">
          %ptr_410 = cute.add_offset(%iter_375, %int_tuple_409) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<f32, rmem>
          %c3_i64 = arith.constant 3 : i64
          %179 = arith.addi %114, %c3_i64 : i64
          %int_tuple_411 = cute.make_int_tuple(%179) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_412 = cute.add_offset(%iter_376, %int_tuple_411) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %180 = builtin.unrealized_conversion_cast %ptr_410 : !cute.ptr<f32, rmem> to !llvm.ptr
          %181 = builtin.unrealized_conversion_cast %ptr_412 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %182 = llvm.load %180 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %182, %181 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %int_tuple_393 = cute.make_int_tuple() : () -> !cute.int_tuple<"8">
        %ptr_394 = cute.add_offset(%iter_378, %int_tuple_393) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<i8, rmem, align<8>>
        %147 = builtin.unrealized_conversion_cast %ptr_394 : !cute.ptr<i8, rmem, align<8>> to !llvm.ptr
        %148 = llvm.load %147 : !llvm.ptr -> i8
        %149 = llvm.mlir.constant(0 : i8) : i8
        %150 = llvm.icmp "ne" %148, %149 : i8
        scf.if %150 {
          %int_tuple_409 = cute.make_int_tuple() : () -> !cute.int_tuple<"8">
          %ptr_410 = cute.add_offset(%iter_375, %int_tuple_409) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<f32, rmem, align<32>>
          %c2_i64 = arith.constant 2 : i64
          %179 = arith.muli %114, %c2_i64 : i64
          %iv_411 = cute.assume(%179) : (i64) -> !cute.i64<divby 2>
          %int_tuple_412 = cute.make_int_tuple(%iv_411) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
          %ptr_413 = cute.add_offset(%iter_376, %int_tuple_412) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
          %180 = builtin.unrealized_conversion_cast %ptr_410 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
          %181 = builtin.unrealized_conversion_cast %ptr_413 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %182 = llvm.load %180 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %182, %181 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %int_tuple_395 = cute.make_int_tuple() : () -> !cute.int_tuple<"9">
        %ptr_396 = cute.add_offset(%iter_378, %int_tuple_395) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<i8, rmem>
        %151 = builtin.unrealized_conversion_cast %ptr_396 : !cute.ptr<i8, rmem> to !llvm.ptr
        %152 = llvm.load %151 : !llvm.ptr -> i8
        %153 = llvm.mlir.constant(0 : i8) : i8
        %154 = llvm.icmp "ne" %152, %153 : i8
        scf.if %154 {
          %int_tuple_409 = cute.make_int_tuple() : () -> !cute.int_tuple<"9">
          %ptr_410 = cute.add_offset(%iter_375, %int_tuple_409) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<f32, rmem>
          %c2_i64 = arith.constant 2 : i64
          %179 = arith.muli %114, %c2_i64 : i64
          %c1_i64 = arith.constant 1 : i64
          %180 = arith.addi %179, %c1_i64 : i64
          %int_tuple_411 = cute.make_int_tuple(%180) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_412 = cute.add_offset(%iter_376, %int_tuple_411) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %181 = builtin.unrealized_conversion_cast %ptr_410 : !cute.ptr<f32, rmem> to !llvm.ptr
          %182 = builtin.unrealized_conversion_cast %ptr_412 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %183 = llvm.load %181 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %183, %182 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %int_tuple_397 = cute.make_int_tuple() : () -> !cute.int_tuple<"10">
        %ptr_398 = cute.add_offset(%iter_378, %int_tuple_397) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<i8, rmem, align<2>>
        %155 = builtin.unrealized_conversion_cast %ptr_398 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
        %156 = llvm.load %155 : !llvm.ptr -> i8
        %157 = llvm.mlir.constant(0 : i8) : i8
        %158 = llvm.icmp "ne" %156, %157 : i8
        scf.if %158 {
          %int_tuple_409 = cute.make_int_tuple() : () -> !cute.int_tuple<"10">
          %ptr_410 = cute.add_offset(%iter_375, %int_tuple_409) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<f32, rmem, align<8>>
          %c2_i64 = arith.constant 2 : i64
          %179 = arith.muli %114, %c2_i64 : i64
          %c2_i64_411 = arith.constant 2 : i64
          %180 = arith.addi %179, %c2_i64_411 : i64
          %iv_412 = cute.assume(%180) : (i64) -> !cute.i64<divby 2>
          %int_tuple_413 = cute.make_int_tuple(%iv_412) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
          %ptr_414 = cute.add_offset(%iter_376, %int_tuple_413) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
          %181 = builtin.unrealized_conversion_cast %ptr_410 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %182 = builtin.unrealized_conversion_cast %ptr_414 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %183 = llvm.load %181 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %183, %182 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %int_tuple_399 = cute.make_int_tuple() : () -> !cute.int_tuple<"11">
        %ptr_400 = cute.add_offset(%iter_378, %int_tuple_399) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<i8, rmem>
        %159 = builtin.unrealized_conversion_cast %ptr_400 : !cute.ptr<i8, rmem> to !llvm.ptr
        %160 = llvm.load %159 : !llvm.ptr -> i8
        %161 = llvm.mlir.constant(0 : i8) : i8
        %162 = llvm.icmp "ne" %160, %161 : i8
        scf.if %162 {
          %int_tuple_409 = cute.make_int_tuple() : () -> !cute.int_tuple<"11">
          %ptr_410 = cute.add_offset(%iter_375, %int_tuple_409) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<f32, rmem>
          %c2_i64 = arith.constant 2 : i64
          %179 = arith.muli %114, %c2_i64 : i64
          %c3_i64 = arith.constant 3 : i64
          %180 = arith.addi %179, %c3_i64 : i64
          %int_tuple_411 = cute.make_int_tuple(%180) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_412 = cute.add_offset(%iter_376, %int_tuple_411) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %181 = builtin.unrealized_conversion_cast %ptr_410 : !cute.ptr<f32, rmem> to !llvm.ptr
          %182 = builtin.unrealized_conversion_cast %ptr_412 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %183 = llvm.load %181 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %183, %182 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %int_tuple_401 = cute.make_int_tuple() : () -> !cute.int_tuple<"12">
        %ptr_402 = cute.add_offset(%iter_378, %int_tuple_401) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<i8, rmem, align<4>>
        %163 = builtin.unrealized_conversion_cast %ptr_402 : !cute.ptr<i8, rmem, align<4>> to !llvm.ptr
        %164 = llvm.load %163 : !llvm.ptr -> i8
        %165 = llvm.mlir.constant(0 : i8) : i8
        %166 = llvm.icmp "ne" %164, %165 : i8
        scf.if %166 {
          %int_tuple_409 = cute.make_int_tuple() : () -> !cute.int_tuple<"12">
          %ptr_410 = cute.add_offset(%iter_375, %int_tuple_409) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<f32, rmem, align<16>>
          %c3_i64 = arith.constant 3 : i64
          %179 = arith.muli %114, %c3_i64 : i64
          %iv_411 = cute.assume(%179) : (i64) -> !cute.i64<divby 3>
          %int_tuple_412 = cute.make_int_tuple(%iv_411) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
          %ptr_413 = cute.add_offset(%iter_376, %int_tuple_412) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
          %180 = builtin.unrealized_conversion_cast %ptr_410 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
          %181 = builtin.unrealized_conversion_cast %ptr_413 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %182 = llvm.load %180 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %182, %181 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %int_tuple_403 = cute.make_int_tuple() : () -> !cute.int_tuple<"13">
        %ptr_404 = cute.add_offset(%iter_378, %int_tuple_403) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<i8, rmem>
        %167 = builtin.unrealized_conversion_cast %ptr_404 : !cute.ptr<i8, rmem> to !llvm.ptr
        %168 = llvm.load %167 : !llvm.ptr -> i8
        %169 = llvm.mlir.constant(0 : i8) : i8
        %170 = llvm.icmp "ne" %168, %169 : i8
        scf.if %170 {
          %int_tuple_409 = cute.make_int_tuple() : () -> !cute.int_tuple<"13">
          %ptr_410 = cute.add_offset(%iter_375, %int_tuple_409) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<f32, rmem>
          %c3_i64 = arith.constant 3 : i64
          %179 = arith.muli %114, %c3_i64 : i64
          %c1_i64 = arith.constant 1 : i64
          %180 = arith.addi %179, %c1_i64 : i64
          %int_tuple_411 = cute.make_int_tuple(%180) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_412 = cute.add_offset(%iter_376, %int_tuple_411) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %181 = builtin.unrealized_conversion_cast %ptr_410 : !cute.ptr<f32, rmem> to !llvm.ptr
          %182 = builtin.unrealized_conversion_cast %ptr_412 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %183 = llvm.load %181 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %183, %182 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %int_tuple_405 = cute.make_int_tuple() : () -> !cute.int_tuple<"14">
        %ptr_406 = cute.add_offset(%iter_378, %int_tuple_405) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<i8, rmem, align<2>>
        %171 = builtin.unrealized_conversion_cast %ptr_406 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
        %172 = llvm.load %171 : !llvm.ptr -> i8
        %173 = llvm.mlir.constant(0 : i8) : i8
        %174 = llvm.icmp "ne" %172, %173 : i8
        scf.if %174 {
          %int_tuple_409 = cute.make_int_tuple() : () -> !cute.int_tuple<"14">
          %ptr_410 = cute.add_offset(%iter_375, %int_tuple_409) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<f32, rmem, align<8>>
          %c3_i64 = arith.constant 3 : i64
          %179 = arith.muli %114, %c3_i64 : i64
          %c2_i64 = arith.constant 2 : i64
          %180 = arith.addi %179, %c2_i64 : i64
          %int_tuple_411 = cute.make_int_tuple(%180) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_412 = cute.add_offset(%iter_376, %int_tuple_411) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %181 = builtin.unrealized_conversion_cast %ptr_410 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %182 = builtin.unrealized_conversion_cast %ptr_412 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %183 = llvm.load %181 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %183, %182 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %int_tuple_407 = cute.make_int_tuple() : () -> !cute.int_tuple<"15">
        %ptr_408 = cute.add_offset(%iter_378, %int_tuple_407) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<i8, rmem>
        %175 = builtin.unrealized_conversion_cast %ptr_408 : !cute.ptr<i8, rmem> to !llvm.ptr
        %176 = llvm.load %175 : !llvm.ptr -> i8
        %177 = llvm.mlir.constant(0 : i8) : i8
        %178 = llvm.icmp "ne" %176, %177 : i8
        scf.if %178 {
          %int_tuple_409 = cute.make_int_tuple() : () -> !cute.int_tuple<"15">
          %ptr_410 = cute.add_offset(%iter_375, %int_tuple_409) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<f32, rmem>
          %c3_i64 = arith.constant 3 : i64
          %179 = arith.muli %114, %c3_i64 : i64
          %c3_i64_411 = arith.constant 3 : i64
          %180 = arith.addi %179, %c3_i64_411 : i64
          %iv_412 = cute.assume(%180) : (i64) -> !cute.i64<divby 3>
          %int_tuple_413 = cute.make_int_tuple(%iv_412) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
          %ptr_414 = cute.add_offset(%iter_376, %int_tuple_413) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
          %181 = builtin.unrealized_conversion_cast %ptr_410 : !cute.ptr<f32, rmem> to !llvm.ptr
          %182 = builtin.unrealized_conversion_cast %ptr_414 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %183 = llvm.load %181 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %183, %182 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
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
    %lay_29 = cute.make_layout() : !cute.layout<"((4,4),(4,32)):((512,32),(128,1))">
    %sz = cute.size(%lay_25) : (!cute.layout<"(4,32):(32,1)">) -> !cute.int_tuple<"128">
    %e0_30 = cute.get_leaves(%sz) : !cute.int_tuple<"128">
    %sz_31 = cute.size(%lay_28) : (!cute.layout<"(4,4):(4,1)">) -> !cute.int_tuple<"16">
    %e0_32 = cute.get_leaves(%sz_31) : !cute.int_tuple<"16">
    %shape_33 = cute.make_shape() : () -> !cute.shape<"(128,16)">
    %lay_34 = cute.make_layout() : !cute.layout<"(128,16):(1,128)">
    %rinv = cute.right_inverse(%lay_29) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.layout<"(32,16,4):(64,4,1)">
    %lay_35 = cute.make_layout() : !cute.layout<"((32,4),(4,4)):((64,4),(16,1))">
    %15 = cute.get_shape(%lay_29) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.shape<"((4,4),(4,32))">
    %e0_36, %e1_37, %e2, %e3 = cute.get_leaves(%15) : !cute.shape<"((4,4),(4,32))">
    %int_tuple_38 = cute.make_int_tuple() : () -> !cute.int_tuple<"((4,4),(4,32))">
    %int_tuple_39 = cute.make_int_tuple() : () -> !cute.int_tuple<"(16,128)">
    %e0_40, %e1_41 = cute.get_leaves(%int_tuple_39) : !cute.int_tuple<"(16,128)">
    %tile = cute.make_tile() : () -> !cute.tile<"[16:1;128:1]">
    %iter_42 = cute.get_iter(%arg0) : !memref_gmem_f32_5
    %lay_43 = cute.get_layout(%arg0) : !memref_gmem_f32_5
    %16:3 = cute.get_scalars(%lay_43) <{only_dynamic}> : !cute.layout<"(?,?):(?{i64},1)">
    %c16_i32 = arith.constant 16 : i32
    %17 = arith.ceildivsi %16#0, %c16_i32 : i32
    %c16_i64 = arith.constant 16 : i64
    %18 = arith.muli %16#2, %c16_i64 : i64
    %c128_i32 = arith.constant 128 : i32
    %19 = arith.ceildivsi %16#1, %c128_i32 : i32
    %shape_44 = cute.make_shape(%17, %19) : (i32, i32) -> !cute.shape<"((16,128),(?,?))">
    %iv = cute.assume(%18) : (i64) -> !cute.i64<divby 16>
    %stride = cute.make_stride(%16#2, %iv) : (i64, !cute.i64<divby 16>) -> !cute.stride<"((?{i64},1),(?{i64 div=16},128))">
    %lay_45 = cute.make_layout(%shape_44, %stride) : !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
    %view = cute.make_view(%iter_42, %lay_45) : !memref_gmem_f32_
    %iter_46 = cute.get_iter(%view) : !memref_gmem_f32_
    %iter_47 = cute.get_iter(%view) : !memref_gmem_f32_
    %tile_48 = cute.make_tile() : () -> !cute.tile<"[16:1;128:1]">
    %iter_49 = cute.get_iter(%arg1) : !memref_gmem_f32_5
    %lay_50 = cute.get_layout(%arg1) : !memref_gmem_f32_5
    %20:3 = cute.get_scalars(%lay_50) <{only_dynamic}> : !cute.layout<"(?,?):(?{i64},1)">
    %c16_i32_51 = arith.constant 16 : i32
    %21 = arith.ceildivsi %20#0, %c16_i32_51 : i32
    %c16_i64_52 = arith.constant 16 : i64
    %22 = arith.muli %20#2, %c16_i64_52 : i64
    %c128_i32_53 = arith.constant 128 : i32
    %23 = arith.ceildivsi %20#1, %c128_i32_53 : i32
    %shape_54 = cute.make_shape(%21, %23) : (i32, i32) -> !cute.shape<"((16,128),(?,?))">
    %iv_55 = cute.assume(%22) : (i64) -> !cute.i64<divby 16>
    %stride_56 = cute.make_stride(%20#2, %iv_55) : (i64, !cute.i64<divby 16>) -> !cute.stride<"((?{i64},1),(?{i64 div=16},128))">
    %lay_57 = cute.make_layout(%shape_54, %stride_56) : !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
    %view_58 = cute.make_view(%iter_49, %lay_57) : !memref_gmem_f32_
    %iter_59 = cute.get_iter(%view_58) : !memref_gmem_f32_
    %iter_60 = cute.get_iter(%view_58) : !memref_gmem_f32_
    %tile_61 = cute.make_tile() : () -> !cute.tile<"[16:1;128:1]">
    %iter_62 = cute.get_iter(%arg2) : !memref_gmem_f32_5
    %lay_63 = cute.get_layout(%arg2) : !memref_gmem_f32_5
    %24:3 = cute.get_scalars(%lay_63) <{only_dynamic}> : !cute.layout<"(?,?):(?{i64},1)">
    %c16_i32_64 = arith.constant 16 : i32
    %25 = arith.ceildivsi %24#0, %c16_i32_64 : i32
    %c16_i64_65 = arith.constant 16 : i64
    %26 = arith.muli %24#2, %c16_i64_65 : i64
    %c128_i32_66 = arith.constant 128 : i32
    %27 = arith.ceildivsi %24#1, %c128_i32_66 : i32
    %shape_67 = cute.make_shape(%25, %27) : (i32, i32) -> !cute.shape<"((16,128),(?,?))">
    %iv_68 = cute.assume(%26) : (i64) -> !cute.i64<divby 16>
    %stride_69 = cute.make_stride(%24#2, %iv_68) : (i64, !cute.i64<divby 16>) -> !cute.stride<"((?{i64},1),(?{i64 div=16},128))">
    %lay_70 = cute.make_layout(%shape_67, %stride_69) : !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
    %view_71 = cute.make_view(%iter_62, %lay_70) : !memref_gmem_f32_
    %iter_72 = cute.get_iter(%view_71) : !memref_gmem_f32_
    %iter_73 = cute.get_iter(%view_71) : !memref_gmem_f32_
    %lay_74 = cute.get_layout(%arg2) : !memref_gmem_f32_5
    %28 = cute.get_shape(%lay_74) : (!cute.layout<"(?,?):(?{i64},1)">) -> !cute.shape<"(?,?)">
    %e0_75, %e1_76 = cute.get_leaves(%28) : !cute.shape<"(?,?)">
    %itup_77 = cute.to_int_tuple(%e0_75) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %29 = cute.get_scalars(%itup_77) : !cute.int_tuple<"?">
    %itup_78 = cute.to_int_tuple(%e1_76) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %30 = cute.get_scalars(%itup_78) : !cute.int_tuple<"?">
    %shape_79 = cute.make_shape(%itup_77, %itup_78) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.shape<"(?,?)">
    %int_tuple_80 = cute.make_int_tuple() : () -> !cute.int_tuple<"(0,0)">
    %stride_81 = cute.make_stride() : () -> !cute.stride<"(1@0,1@1)">
    %lay_82 = cute.make_layout(%shape_79, %stride_81) : !cute.layout<"(?,?):(1@0,1@1)">
    %view_83 = cute.make_view(%int_tuple_80, %lay_82) : !cute.coord_tensor<"(0,0)", "(?,?):(1@0,1@1)">
    %iter_84 = cute.get_iter(%view_83) : !cute.coord_tensor<"(0,0)", "(?,?):(1@0,1@1)">
    %e0_85, %e1_86 = cute.get_leaves(%iter_84) : !cute.int_tuple<"(0,0)">
    %tile_87 = cute.make_tile() : () -> !cute.tile<"[16:1;128:1]">
    %iter_88 = cute.get_iter(%view_83) : !cute.coord_tensor<"(0,0)", "(?,?):(1@0,1@1)">
    %lay_89 = cute.get_layout(%view_83) : !cute.coord_tensor<"(0,0)", "(?,?):(1@0,1@1)">
    %31:2 = cute.get_scalars(%lay_89) <{only_dynamic}> : !cute.layout<"(?,?):(1@0,1@1)">
    %c16_i32_90 = arith.constant 16 : i32
    %32 = arith.ceildivsi %31#0, %c16_i32_90 : i32
    %c128_i32_91 = arith.constant 128 : i32
    %33 = arith.ceildivsi %31#1, %c128_i32_91 : i32
    %shape_92 = cute.make_shape(%32, %33) : (i32, i32) -> !cute.shape<"((16,128),(?,?))">
    %stride_93 = cute.make_stride() : () -> !cute.stride<"((1@0,1@1),(16@0,128@1))">
    %lay_94 = cute.make_layout(%shape_92, %stride_93) : !cute.layout<"((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
    %view_95 = cute.make_view(%iter_88, %lay_94) : !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
    %iter_96 = cute.get_iter(%view_95) : !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
    %e0_97, %e1_98 = cute.get_leaves(%iter_96) : !cute.int_tuple<"(0,0)">
    %iter_99 = cute.get_iter(%view_95) : !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
    %e0_100, %e1_101 = cute.get_leaves(%iter_99) : !cute.int_tuple<"(0,0)">
    %lay_102 = cute.get_layout(%view_71) : !memref_gmem_f32_
    %sz_103 = cute.size(%lay_102) <{mode = [1]}> : (!cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.int_tuple<"?">
    %e0_104 = cute.get_leaves(%sz_103) : !cute.int_tuple<"?">
    %34 = cute.get_scalars(%e0_104) : !cute.int_tuple<"?">
    %sz_105 = cute.size(%lay_35) <{mode = [0]}> : (!cute.layout<"((32,4),(4,4)):((64,4),(16,1))">) -> !cute.int_tuple<"128">
    %e0_106 = cute.get_leaves(%sz_105) : !cute.int_tuple<"128">
    %lay_107 = cute.get_layout(%view) : !memref_gmem_f32_
    %35 = cute.get_shape(%lay_107) : (!cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.shape<"((16,128),(?,?))">
    %e0_108, %e1_109, %e2_110, %e3_111 = cute.get_leaves(%35) : !cute.shape<"((16,128),(?,?))">
    %itup_112 = cute.to_int_tuple(%e2_110) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %36 = cute.get_scalars(%itup_112) : !cute.int_tuple<"?">
    %itup_113 = cute.to_int_tuple(%e3_111) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %37 = cute.get_scalars(%itup_113) : !cute.int_tuple<"?">
    %38 = cute.get_stride(%lay_107) : (!cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.stride<"((?{i64},1),(?{i64 div=16},128))">
    %e0_114, %e1_115, %e2_116, %e3_117 = cute.get_leaves(%38) : !cute.stride<"((?{i64},1),(?{i64 div=16},128))">
    %itup_118 = cute.to_int_tuple(%e0_114) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
    %39 = cute.get_scalars(%itup_118) : !cute.int_tuple<"?{i64}">
    %itup_119 = cute.to_int_tuple(%e2_116) : !cute.stride<"?{i64 div=16}"> to !cute.int_tuple<"?{i64 div=16}">
    %40 = cute.get_scalars(%itup_119) : !cute.int_tuple<"?{i64 div=16}">
    %lay_120 = cute.get_layout(%view_58) : !memref_gmem_f32_
    %41 = cute.get_shape(%lay_120) : (!cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.shape<"((16,128),(?,?))">
    %e0_121, %e1_122, %e2_123, %e3_124 = cute.get_leaves(%41) : !cute.shape<"((16,128),(?,?))">
    %itup_125 = cute.to_int_tuple(%e2_123) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %42 = cute.get_scalars(%itup_125) : !cute.int_tuple<"?">
    %itup_126 = cute.to_int_tuple(%e3_124) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %43 = cute.get_scalars(%itup_126) : !cute.int_tuple<"?">
    %44 = cute.get_stride(%lay_120) : (!cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.stride<"((?{i64},1),(?{i64 div=16},128))">
    %e0_127, %e1_128, %e2_129, %e3_130 = cute.get_leaves(%44) : !cute.stride<"((?{i64},1),(?{i64 div=16},128))">
    %itup_131 = cute.to_int_tuple(%e0_127) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
    %45 = cute.get_scalars(%itup_131) : !cute.int_tuple<"?{i64}">
    %itup_132 = cute.to_int_tuple(%e2_129) : !cute.stride<"?{i64 div=16}"> to !cute.int_tuple<"?{i64 div=16}">
    %46 = cute.get_scalars(%itup_132) : !cute.int_tuple<"?{i64 div=16}">
    %lay_133 = cute.get_layout(%view_71) : !memref_gmem_f32_
    %47 = cute.get_shape(%lay_133) : (!cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.shape<"((16,128),(?,?))">
    %e0_134, %e1_135, %e2_136, %e3_137 = cute.get_leaves(%47) : !cute.shape<"((16,128),(?,?))">
    %itup_138 = cute.to_int_tuple(%e2_136) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %48 = cute.get_scalars(%itup_138) : !cute.int_tuple<"?">
    %itup_139 = cute.to_int_tuple(%e3_137) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %49 = cute.get_scalars(%itup_139) : !cute.int_tuple<"?">
    %50 = cute.get_stride(%lay_133) : (!cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.stride<"((?{i64},1),(?{i64 div=16},128))">
    %e0_140, %e1_141, %e2_142, %e3_143 = cute.get_leaves(%50) : !cute.stride<"((?{i64},1),(?{i64 div=16},128))">
    %itup_144 = cute.to_int_tuple(%e0_140) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
    %51 = cute.get_scalars(%itup_144) : !cute.int_tuple<"?{i64}">
    %itup_145 = cute.to_int_tuple(%e2_142) : !cute.stride<"?{i64 div=16}"> to !cute.int_tuple<"?{i64 div=16}">
    %52 = cute.get_scalars(%itup_145) : !cute.int_tuple<"?{i64 div=16}">
    %lay_146 = cute.get_layout(%view_95) : !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
    %53 = cute.get_shape(%lay_146) : (!cute.layout<"((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">) -> !cute.shape<"((16,128),(?,?))">
    %e0_147, %e1_148, %e2_149, %e3_150 = cute.get_leaves(%53) : !cute.shape<"((16,128),(?,?))">
    %itup_151 = cute.to_int_tuple(%e2_149) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %54 = cute.get_scalars(%itup_151) : !cute.int_tuple<"?">
    %itup_152 = cute.to_int_tuple(%e3_150) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %55 = cute.get_scalars(%itup_152) : !cute.int_tuple<"?">
    %56 = cute.get_stride(%lay_146) : (!cute.layout<"((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">) -> !cute.stride<"((1@0,1@1),(16@0,128@1))">
    %e0_153, %e1_154, %e2_155, %e3_156 = cute.get_leaves(%56) : !cute.stride<"((1@0,1@1),(16@0,128@1))">
    %57 = cute.get_shape(%lay_25) : (!cute.layout<"(4,32):(32,1)">) -> !cute.shape<"(4,32)">
    %e0_157, %e1_158 = cute.get_leaves(%57) : !cute.shape<"(4,32)">
    %58 = cute.get_stride(%lay_25) : (!cute.layout<"(4,32):(32,1)">) -> !cute.stride<"(32,1)">
    %e0_159, %e1_160 = cute.get_leaves(%58) : !cute.stride<"(32,1)">
    %59 = cute.get_shape(%lay_28) : (!cute.layout<"(4,4):(4,1)">) -> !cute.shape<"(4,4)">
    %e0_161, %e1_162 = cute.get_leaves(%59) : !cute.shape<"(4,4)">
    %60 = cute.get_stride(%lay_28) : (!cute.layout<"(4,4):(4,1)">) -> !cute.stride<"(4,1)">
    %e0_163, %e1_164 = cute.get_leaves(%60) : !cute.stride<"(4,1)">
    %c0_i32 = arith.constant 0 : i32
    %61 = arith.extsi %c0_i32 : i32 to i64
    %c128_i32_165 = arith.constant 128 : i32
    %c1_i32 = arith.constant 1 : i32
    %62 = cuda.launch_cfg.create<max_attrs = 2 : i32> (blockDim = (%c128_i32_165, %c1_i32, %c1_i32), dynamicSmemBytes = %61, gridDim = (%34, %c1_i32, %c1_i32), stream = %arg3) : i32, i32, i32, i64, i32, i32, i32, !cuda.stream -> !cuda.launch_cfg<max_attrs = 2>
    %63 = cuda.launch_ex @kernels::@kernel_cutlass_elementwise_add_kernel_tensorptrf32gmemo161281i64div16128_tensorptrf32gmemo161281i64div16128_tensorptrf32gmemo161281i64div16128_tensor00o1612810111601281___False_0<%62> (%view, %view_58, %view_71, %view_95, %29, %30) : !cuda.launch_cfg<max_attrs = 2>, (!memref_gmem_f32_, !memref_gmem_f32_, !memref_gmem_f32_, !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">, i32, i32) -> !cuda.result
    %64 = cuda.cast %63 : !cuda.result -> i32
    cuda.return_if_error %64 : i32
    %c0_i32_166 = arith.constant 0 : i32
    return %c0_i32_166 : i32
  }
}
