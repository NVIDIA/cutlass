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
      %lay_250 = cute.get_layout(%rmem_244) : !memref_rmem_i8_
      %97 = cute.get_shape(%lay_250) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_251, %e1_252, %e2_253, %e3_254, %e4_255 = cute.get_leaves(%97) : !cute.shape<"((1,(4,4)),1,1)">
      %98 = cute.get_stride(%lay_250) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.stride<"((0,(1,4)),0,0)">
      %e0_256, %e1_257, %e2_258, %e3_259, %e4_260 = cute.get_leaves(%98) : !cute.stride<"((0,(1,4)),0,0)">
      %c0_i32 = arith.constant 0 : i32
      %c16_i32 = arith.constant 16 : i32
      %c1_i32 = arith.constant 1 : i32
      %99 = scf.for %arg6 = %c0_i32 to %c16_i32 step %c1_i32 iter_args(%arg7 = %rmem_244) -> (!memref_rmem_i8_)  : i32 {
        %iter_577 = cute.get_iter(%arg7) : !memref_rmem_i8_
        %lay_578 = cute.get_layout(%arg7) : !memref_rmem_i8_
        %138 = cute.get_shape(%lay_578) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
        %e0_579, %e1_580, %e2_581, %e3_582, %e4_583 = cute.get_leaves(%138) : !cute.shape<"((1,(4,4)),1,1)">
        %139 = cute.get_stride(%lay_578) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.stride<"((0,(1,4)),0,0)">
        %e0_584, %e1_585, %e2_586, %e3_587, %e4_588 = cute.get_leaves(%139) : !cute.stride<"((0,(1,4)),0,0)">
        %iter_589 = cute.get_iter(%arg7) : !memref_rmem_i8_
        %coord_590 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"?">
        %lay_591 = cute.get_layout(%view_233) : !cute.coord_tensor<"(?{div=4},?{div=4})", "((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">
        %idx_592 = cute.crd2idx(%coord_590, %lay_591) : (!cute.coord<"?">, !cute.layout<"((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">) -> !cute.int_tuple<"(?,?)">
        %iter_593 = cute.get_iter(%view_233) : !cute.coord_tensor<"(?{div=4},?{div=4})", "((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">
        %tup_594 = cute.add_offset(%iter_593, %idx_592) : (!cute.int_tuple<"(?{div=4},?{div=4})">, !cute.int_tuple<"(?,?)">) -> !cute.int_tuple<"(?,?)">
        %view_595 = cute.make_view(%tup_594) : !cute.coord_tensor<"(?,?)", "():()">
        %iter_596 = cute.get_iter(%view_595) : !cute.coord_tensor<"(?,?)", "():()">
        %e0_597, %e1_598 = cute.get_leaves(%iter_596) : !cute.int_tuple<"(?,?)">
        %140 = cute.get_scalars(%e0_597) : !cute.int_tuple<"?">
        %141 = cute.get_scalars(%e1_598) : !cute.int_tuple<"?">
        %iter_599 = cute.get_iter(%view_595) : !cute.coord_tensor<"(?,?)", "():()">
        %e0_600, %e1_601 = cute.get_leaves(%iter_599) : !cute.int_tuple<"(?,?)">
        %142 = cute.get_scalars(%e0_600) : !cute.int_tuple<"?">
        %143 = cute.get_scalars(%e1_601) : !cute.int_tuple<"?">
        %iter_602 = cute.get_iter(%view_595) : !cute.coord_tensor<"(?,?)", "():()">
        %e0_603, %e1_604 = cute.get_leaves(%iter_602) : !cute.int_tuple<"(?,?)">
        %144 = cute.get_scalars(%e0_603) : !cute.int_tuple<"?">
        %145 = cute.get_scalars(%e1_604) : !cute.int_tuple<"?">
        %coord_605 = cute.make_coord(%e0_603, %e1_604) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
        %coord_606 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
        %146:2 = cute.get_scalars(%coord_605) : !cute.coord<"(?,?)">
        %147:2 = cute.get_scalars(%coord_606) : !cute.coord<"(?,?)">
        %true = arith.constant true
        %148 = arith.cmpi slt, %146#0, %147#0 : i32
        %149 = arith.andi %true, %148 : i1
        %150 = arith.cmpi slt, %146#1, %147#1 : i32
        %151 = arith.andi %149, %150 : i1
        %152 = arith.extui %151 : i1 to i8
        %coord_607 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"?">
        cute.memref.store(%arg7, %coord_607, %152) : (!memref_rmem_i8_, !cute.coord<"?">, i8) -> ()
        %lay_608 = cute.get_layout(%arg7) : !memref_rmem_i8_
        %153 = cute.get_shape(%lay_608) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
        %e0_609, %e1_610, %e2_611, %e3_612, %e4_613 = cute.get_leaves(%153) : !cute.shape<"((1,(4,4)),1,1)">
        %154 = cute.get_stride(%lay_608) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.stride<"((0,(1,4)),0,0)">
        %e0_614, %e1_615, %e2_616, %e3_617, %e4_618 = cute.get_leaves(%154) : !cute.stride<"((0,(1,4)),0,0)">
        scf.yield %arg7 : !memref_rmem_i8_
      }
      %iter_261 = cute.get_iter(%99) : !memref_rmem_i8_
      %lay_262 = cute.get_layout(%99) : !memref_rmem_i8_
      %100 = cute.get_shape(%lay_262) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_263, %e1_264, %e2_265, %e3_266, %e4_267 = cute.get_leaves(%100) : !cute.shape<"((1,(4,4)),1,1)">
      %101 = cute.get_stride(%lay_262) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.stride<"((0,(1,4)),0,0)">
      %e0_268, %e1_269, %e2_270, %e3_271, %e4_272 = cute.get_leaves(%101) : !cute.stride<"((0,(1,4)),0,0)">
      %iter_273 = cute.get_iter(%99) : !memref_rmem_i8_
      %iter_274 = cute.get_iter(%99) : !memref_rmem_i8_
      %lay_275 = cute.get_layout(%view_173) : !memref_gmem_f32_2
      %102 = cute.get_shape(%lay_275) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_276, %e1_277, %e2_278, %e3_279, %e4_280 = cute.get_leaves(%102) : !cute.shape<"((1,(4,4)),1,1)">
      %lay_281 = cute.get_layout(%rmem) : !memref_rmem_f32_
      %103 = cute.get_shape(%lay_281) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_282, %e1_283, %e2_284, %e3_285, %e4_286 = cute.get_leaves(%103) : !cute.shape<"((1,(4,4)),1,1)">
      %lay_287 = cute.get_layout(%view_173) : !memref_gmem_f32_2
      %shape_288 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_289 = cute.make_layout() : !cute.layout<"1:0">
      %append = cute.append_to_rank<2> (%lay_287, %lay_289) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">
      %view_290 = cute.make_view(%iter_174, %append) : !memref_gmem_f32_2
      %iter_291 = cute.get_iter(%view_290) : !memref_gmem_f32_2
      %lay_292 = cute.get_layout(%view_290) : !memref_gmem_f32_2
      %104 = cute.get_shape(%lay_292) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_293, %e1_294, %e2_295, %e3_296, %e4_297 = cute.get_leaves(%104) : !cute.shape<"((1,(4,4)),1,1)">
      %iter_298 = cute.get_iter(%view_290) : !memref_gmem_f32_2
      %lay_299 = cute.get_layout(%view_290) : !memref_gmem_f32_2
      %105 = cute.get_scalars(%lay_299) <{only_dynamic}> : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %shape_300 = cute.make_shape() : () -> !cute.shape<"((1,(4,4)),(1,1))">
      %stride_301 = cute.make_stride(%105) : (i64) -> !cute.stride<"((0,(1,?{i64})),(0,0))">
      %lay_302 = cute.make_layout(%shape_300, %stride_301) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %view_303 = cute.make_view(%iter_298, %lay_302) : !memref_gmem_f32_3
      %iter_304 = cute.get_iter(%view_303) : !memref_gmem_f32_3
      %iter_305 = cute.get_iter(%view_303) : !memref_gmem_f32_3
      %lay_306 = cute.get_layout(%rmem) : !memref_rmem_f32_
      %shape_307 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_308 = cute.make_layout() : !cute.layout<"1:0">
      %append_309 = cute.append_to_rank<2> (%lay_306, %lay_308) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
      %view_310 = cute.make_view(%iter_212, %append_309) : !memref_rmem_f32_
      %iter_311 = cute.get_iter(%view_310) : !memref_rmem_f32_
      %lay_312 = cute.get_layout(%view_310) : !memref_rmem_f32_
      %106 = cute.get_shape(%lay_312) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_313, %e1_314, %e2_315, %e3_316, %e4_317 = cute.get_leaves(%106) : !cute.shape<"((1,(4,4)),1,1)">
      %iter_318 = cute.get_iter(%view_310) : !memref_rmem_f32_
      %view_319 = cute.make_view(%iter_318) : !memref_rmem_f32_1
      %iter_320 = cute.get_iter(%view_319) : !memref_rmem_f32_1
      %iter_321 = cute.get_iter(%view_319) : !memref_rmem_f32_1
      %lay_322 = cute.get_layout(%99) : !memref_rmem_i8_
      %shape_323 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_324 = cute.make_layout() : !cute.layout<"1:0">
      %append_325 = cute.append_to_rank<2> (%lay_322, %lay_324) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
      %view_326 = cute.make_view(%iter_274, %append_325) : !memref_rmem_i8_
      %iter_327 = cute.get_iter(%view_326) : !memref_rmem_i8_
      %lay_328 = cute.get_layout(%view_326) : !memref_rmem_i8_
      %107 = cute.get_shape(%lay_328) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_329, %e1_330, %e2_331, %e3_332, %e4_333 = cute.get_leaves(%107) : !cute.shape<"((1,(4,4)),1,1)">
      %iter_334 = cute.get_iter(%view_326) : !memref_rmem_i8_
      %view_335 = cute.make_view(%iter_334) : !memref_rmem_i8_1
      %iter_336 = cute.get_iter(%view_335) : !memref_rmem_i8_1
      %iter_337 = cute.get_iter(%view_335) : !memref_rmem_i8_1
      %lay_338 = cute.get_layout(%view_303) : !memref_gmem_f32_3
      %108 = cute.get_shape(%lay_338) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
      %e0_339, %e1_340, %e2_341, %e3_342, %e4_343 = cute.get_leaves(%108) : !cute.shape<"((1,(4,4)),(1,1))">
      %lay_344 = cute.get_layout(%view_319) : !memref_rmem_f32_1
      %109 = cute.get_shape(%lay_344) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
      %e0_345, %e1_346, %e2_347, %e3_348, %e4_349 = cute.get_leaves(%109) : !cute.shape<"((1,(4,4)),(1,1))">
      %lay_350 = cute.get_layout(%view_303) : !memref_gmem_f32_3
      %sz_351 = cute.size(%lay_350) <{mode = [1]}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.int_tuple<"1">
      %e0_352 = cute.get_leaves(%sz_351) : !cute.int_tuple<"1">
      %lay_353 = cute.get_layout(%view_319) : !memref_rmem_f32_1
      %sz_354 = cute.size(%lay_353) <{mode = [1]}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.int_tuple<"1">
      %e0_355 = cute.get_leaves(%sz_354) : !cute.int_tuple<"1">
      %110 = cute.static : !cute.layout<"1:0">
      %iter_356 = cute.get_iter(%view_303) : !memref_gmem_f32_3
      %iter_357 = cute.get_iter(%view_319) : !memref_rmem_f32_1
      %lay_358 = cute.get_layout(%view_303) : !memref_gmem_f32_3
      %lay_359 = cute.get_layout(%view_319) : !memref_rmem_f32_1
      %append_360 = cute.append_to_rank<2> (%lay_358, %110) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">, !cute.layout<"1:0">
      %append_361 = cute.append_to_rank<2> (%lay_359, %110) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">, !cute.layout<"1:0">
      %111 = cute.get_scalars(%append_360) <{only_dynamic}> : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %shape_362 = cute.make_shape() : () -> !cute.shape<"((1,(4,4)),((1,1)))">
      %stride_363 = cute.make_stride(%111) : (i64) -> !cute.stride<"((0,(1,?{i64})),((0,0)))">
      %lay_364 = cute.make_layout(%shape_362, %stride_363) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
      %lay_365 = cute.make_layout() : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">
      %iter_366 = cute.get_iter(%view_335) : !memref_rmem_i8_1
      %lay_367 = cute.get_layout(%view_335) : !memref_rmem_i8_1
      %append_368 = cute.append_to_rank<2> (%lay_367, %110) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">, !cute.layout<"1:0">
      %lay_369 = cute.make_layout() : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">
      %sz_370 = cute.size(%lay_364) <{mode = [1]}> : (!cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">) -> !cute.int_tuple<"1">
      %112 = cute.get_scalars(%sz_370) : !cute.int_tuple<"1">
      %c0_i32_371 = arith.constant 0 : i32
      %c1_i32_372 = arith.constant 1 : i32
      scf.for %arg6 = %c0_i32_371 to %112 step %c1_i32_372  : i32 {
        %coord_577 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
        %138 = cute.get_scalars(%lay_364) <{only_dynamic}> : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
        %139 = cute.get_scalars(%coord_577) <{only_dynamic}> : !cute.coord<"(_,?)">
        %shape_578 = cute.make_shape() : () -> !cute.shape<"((1,(4,4)))">
        %stride_579 = cute.make_stride(%138) : (i64) -> !cute.stride<"((0,(1,?{i64})))">
        %lay_580 = cute.make_layout(%shape_578, %stride_579) : !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
        %idx_581 = cute.crd2idx(%coord_577, %lay_364) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">) -> !cute.int_tuple<"0">
        %ptr_582 = cute.add_offset(%iter_356, %idx_581) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<f32, gmem>
        %view_583 = cute.make_view(%ptr_582, %lay_580) : !memref_gmem_f32_4
        %140 = cute.get_scalars(%coord_577) <{only_dynamic}> : !cute.coord<"(_,?)">
        %lay_584 = cute.make_layout() : !cute.layout<"((1,(4,4))):((0,(1,4)))">
        %idx_585 = cute.crd2idx(%coord_577, %lay_365) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">) -> !cute.int_tuple<"0">
        %ptr_586 = cute.add_offset(%iter_357, %idx_585) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, rmem, align<32>>
        %view_587 = cute.make_view(%ptr_586, %lay_584) : !memref_rmem_f32_2
        %141 = cute.get_scalars(%coord_577) <{only_dynamic}> : !cute.coord<"(_,?)">
        %lay_588 = cute.make_layout() : !cute.layout<"((1,(4,4))):((0,(1,4)))">
        %idx_589 = cute.crd2idx(%coord_577, %lay_369) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">) -> !cute.int_tuple<"0">
        %ptr_590 = cute.add_offset(%iter_366, %idx_589) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
        %view_591 = cute.make_view(%ptr_590, %lay_588) : !memref_rmem_i8_2
        %iter_592 = cute.get_iter(%view_583) : !memref_gmem_f32_4
        %lay_593 = cute.get_layout(%view_583) : !memref_gmem_f32_4
        %142 = cute.get_scalars(%lay_593) <{only_dynamic}> : !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
        %iter_594 = cute.get_iter(%view_587) : !memref_rmem_f32_2
        %iter_595 = cute.get_iter(%view_591) : !memref_rmem_i8_2
        %143 = builtin.unrealized_conversion_cast %iter_595 : !cute.ptr<i8, rmem, align<32>> to !llvm.ptr
        %144 = llvm.load %143 : !llvm.ptr -> i8
        %145 = llvm.mlir.constant(0 : i8) : i8
        %146 = llvm.icmp "ne" %144, %145 : i8
        scf.if %146 {
          %207 = builtin.unrealized_conversion_cast %iter_592 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %208 = builtin.unrealized_conversion_cast %iter_594 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
          %209 = llvm.load %207 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %209, %208 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %int_tuple_596 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
        %ptr_597 = cute.add_offset(%iter_595, %int_tuple_596) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
        %147 = builtin.unrealized_conversion_cast %ptr_597 : !cute.ptr<i8, rmem> to !llvm.ptr
        %148 = llvm.load %147 : !llvm.ptr -> i8
        %149 = llvm.mlir.constant(0 : i8) : i8
        %150 = llvm.icmp "ne" %148, %149 : i8
        scf.if %150 {
          %int_tuple_626 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
          %ptr_627 = cute.add_offset(%iter_592, %int_tuple_626) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
          %int_tuple_628 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
          %ptr_629 = cute.add_offset(%iter_594, %int_tuple_628) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
          %207 = builtin.unrealized_conversion_cast %ptr_627 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %208 = builtin.unrealized_conversion_cast %ptr_629 : !cute.ptr<f32, rmem> to !llvm.ptr
          %209 = llvm.load %207 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %209, %208 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %int_tuple_598 = cute.make_int_tuple() : () -> !cute.int_tuple<"2">
        %ptr_599 = cute.add_offset(%iter_595, %int_tuple_598) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem, align<2>>
        %151 = builtin.unrealized_conversion_cast %ptr_599 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
        %152 = llvm.load %151 : !llvm.ptr -> i8
        %153 = llvm.mlir.constant(0 : i8) : i8
        %154 = llvm.icmp "ne" %152, %153 : i8
        scf.if %154 {
          %int_tuple_626 = cute.make_int_tuple() : () -> !cute.int_tuple<"2">
          %ptr_627 = cute.add_offset(%iter_592, %int_tuple_626) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
          %int_tuple_628 = cute.make_int_tuple() : () -> !cute.int_tuple<"2">
          %ptr_629 = cute.add_offset(%iter_594, %int_tuple_628) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
          %207 = builtin.unrealized_conversion_cast %ptr_627 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %208 = builtin.unrealized_conversion_cast %ptr_629 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %209 = llvm.load %207 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %209, %208 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %int_tuple_600 = cute.make_int_tuple() : () -> !cute.int_tuple<"3">
        %ptr_601 = cute.add_offset(%iter_595, %int_tuple_600) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
        %155 = builtin.unrealized_conversion_cast %ptr_601 : !cute.ptr<i8, rmem> to !llvm.ptr
        %156 = llvm.load %155 : !llvm.ptr -> i8
        %157 = llvm.mlir.constant(0 : i8) : i8
        %158 = llvm.icmp "ne" %156, %157 : i8
        scf.if %158 {
          %int_tuple_626 = cute.make_int_tuple() : () -> !cute.int_tuple<"3">
          %ptr_627 = cute.add_offset(%iter_592, %int_tuple_626) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
          %int_tuple_628 = cute.make_int_tuple() : () -> !cute.int_tuple<"3">
          %ptr_629 = cute.add_offset(%iter_594, %int_tuple_628) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
          %207 = builtin.unrealized_conversion_cast %ptr_627 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %208 = builtin.unrealized_conversion_cast %ptr_629 : !cute.ptr<f32, rmem> to !llvm.ptr
          %209 = llvm.load %207 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %209, %208 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %int_tuple_602 = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
        %ptr_603 = cute.add_offset(%iter_595, %int_tuple_602) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem, align<4>>
        %159 = builtin.unrealized_conversion_cast %ptr_603 : !cute.ptr<i8, rmem, align<4>> to !llvm.ptr
        %160 = llvm.load %159 : !llvm.ptr -> i8
        %161 = llvm.mlir.constant(0 : i8) : i8
        %162 = llvm.icmp "ne" %160, %161 : i8
        scf.if %162 {
          %int_tuple_626 = cute.make_int_tuple(%142) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_627 = cute.add_offset(%iter_592, %int_tuple_626) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %int_tuple_628 = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
          %ptr_629 = cute.add_offset(%iter_594, %int_tuple_628) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
          %207 = builtin.unrealized_conversion_cast %ptr_627 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %208 = builtin.unrealized_conversion_cast %ptr_629 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
          %209 = llvm.load %207 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %209, %208 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %int_tuple_604 = cute.make_int_tuple() : () -> !cute.int_tuple<"5">
        %ptr_605 = cute.add_offset(%iter_595, %int_tuple_604) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
        %163 = builtin.unrealized_conversion_cast %ptr_605 : !cute.ptr<i8, rmem> to !llvm.ptr
        %164 = llvm.load %163 : !llvm.ptr -> i8
        %165 = llvm.mlir.constant(0 : i8) : i8
        %166 = llvm.icmp "ne" %164, %165 : i8
        scf.if %166 {
          %c1_i64 = arith.constant 1 : i64
          %207 = arith.addi %142, %c1_i64 : i64
          %int_tuple_626 = cute.make_int_tuple(%207) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_627 = cute.add_offset(%iter_592, %int_tuple_626) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %int_tuple_628 = cute.make_int_tuple() : () -> !cute.int_tuple<"5">
          %ptr_629 = cute.add_offset(%iter_594, %int_tuple_628) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<f32, rmem>
          %208 = builtin.unrealized_conversion_cast %ptr_627 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %209 = builtin.unrealized_conversion_cast %ptr_629 : !cute.ptr<f32, rmem> to !llvm.ptr
          %210 = llvm.load %208 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %210, %209 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %int_tuple_606 = cute.make_int_tuple() : () -> !cute.int_tuple<"6">
        %ptr_607 = cute.add_offset(%iter_595, %int_tuple_606) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem, align<2>>
        %167 = builtin.unrealized_conversion_cast %ptr_607 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
        %168 = llvm.load %167 : !llvm.ptr -> i8
        %169 = llvm.mlir.constant(0 : i8) : i8
        %170 = llvm.icmp "ne" %168, %169 : i8
        scf.if %170 {
          %c2_i64 = arith.constant 2 : i64
          %207 = arith.addi %142, %c2_i64 : i64
          %int_tuple_626 = cute.make_int_tuple(%207) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_627 = cute.add_offset(%iter_592, %int_tuple_626) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %int_tuple_628 = cute.make_int_tuple() : () -> !cute.int_tuple<"6">
          %ptr_629 = cute.add_offset(%iter_594, %int_tuple_628) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
          %208 = builtin.unrealized_conversion_cast %ptr_627 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %209 = builtin.unrealized_conversion_cast %ptr_629 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %210 = llvm.load %208 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %210, %209 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %int_tuple_608 = cute.make_int_tuple() : () -> !cute.int_tuple<"7">
        %ptr_609 = cute.add_offset(%iter_595, %int_tuple_608) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
        %171 = builtin.unrealized_conversion_cast %ptr_609 : !cute.ptr<i8, rmem> to !llvm.ptr
        %172 = llvm.load %171 : !llvm.ptr -> i8
        %173 = llvm.mlir.constant(0 : i8) : i8
        %174 = llvm.icmp "ne" %172, %173 : i8
        scf.if %174 {
          %c3_i64 = arith.constant 3 : i64
          %207 = arith.addi %142, %c3_i64 : i64
          %int_tuple_626 = cute.make_int_tuple(%207) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_627 = cute.add_offset(%iter_592, %int_tuple_626) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %int_tuple_628 = cute.make_int_tuple() : () -> !cute.int_tuple<"7">
          %ptr_629 = cute.add_offset(%iter_594, %int_tuple_628) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<f32, rmem>
          %208 = builtin.unrealized_conversion_cast %ptr_627 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %209 = builtin.unrealized_conversion_cast %ptr_629 : !cute.ptr<f32, rmem> to !llvm.ptr
          %210 = llvm.load %208 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %210, %209 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %int_tuple_610 = cute.make_int_tuple() : () -> !cute.int_tuple<"8">
        %ptr_611 = cute.add_offset(%iter_595, %int_tuple_610) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<i8, rmem, align<8>>
        %175 = builtin.unrealized_conversion_cast %ptr_611 : !cute.ptr<i8, rmem, align<8>> to !llvm.ptr
        %176 = llvm.load %175 : !llvm.ptr -> i8
        %177 = llvm.mlir.constant(0 : i8) : i8
        %178 = llvm.icmp "ne" %176, %177 : i8
        scf.if %178 {
          %c2_i64 = arith.constant 2 : i64
          %207 = arith.muli %142, %c2_i64 : i64
          %iv_626 = cute.assume(%207) : (i64) -> !cute.i64<divby 2>
          %int_tuple_627 = cute.make_int_tuple(%iv_626) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
          %ptr_628 = cute.add_offset(%iter_592, %int_tuple_627) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
          %int_tuple_629 = cute.make_int_tuple() : () -> !cute.int_tuple<"8">
          %ptr_630 = cute.add_offset(%iter_594, %int_tuple_629) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<f32, rmem, align<32>>
          %208 = builtin.unrealized_conversion_cast %ptr_628 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %209 = builtin.unrealized_conversion_cast %ptr_630 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
          %210 = llvm.load %208 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %210, %209 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %int_tuple_612 = cute.make_int_tuple() : () -> !cute.int_tuple<"9">
        %ptr_613 = cute.add_offset(%iter_595, %int_tuple_612) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<i8, rmem>
        %179 = builtin.unrealized_conversion_cast %ptr_613 : !cute.ptr<i8, rmem> to !llvm.ptr
        %180 = llvm.load %179 : !llvm.ptr -> i8
        %181 = llvm.mlir.constant(0 : i8) : i8
        %182 = llvm.icmp "ne" %180, %181 : i8
        scf.if %182 {
          %c2_i64 = arith.constant 2 : i64
          %207 = arith.muli %142, %c2_i64 : i64
          %c1_i64 = arith.constant 1 : i64
          %208 = arith.addi %207, %c1_i64 : i64
          %int_tuple_626 = cute.make_int_tuple(%208) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_627 = cute.add_offset(%iter_592, %int_tuple_626) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %int_tuple_628 = cute.make_int_tuple() : () -> !cute.int_tuple<"9">
          %ptr_629 = cute.add_offset(%iter_594, %int_tuple_628) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<f32, rmem>
          %209 = builtin.unrealized_conversion_cast %ptr_627 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %210 = builtin.unrealized_conversion_cast %ptr_629 : !cute.ptr<f32, rmem> to !llvm.ptr
          %211 = llvm.load %209 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %211, %210 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %int_tuple_614 = cute.make_int_tuple() : () -> !cute.int_tuple<"10">
        %ptr_615 = cute.add_offset(%iter_595, %int_tuple_614) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<i8, rmem, align<2>>
        %183 = builtin.unrealized_conversion_cast %ptr_615 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
        %184 = llvm.load %183 : !llvm.ptr -> i8
        %185 = llvm.mlir.constant(0 : i8) : i8
        %186 = llvm.icmp "ne" %184, %185 : i8
        scf.if %186 {
          %c2_i64 = arith.constant 2 : i64
          %207 = arith.muli %142, %c2_i64 : i64
          %c2_i64_626 = arith.constant 2 : i64
          %208 = arith.addi %207, %c2_i64_626 : i64
          %iv_627 = cute.assume(%208) : (i64) -> !cute.i64<divby 2>
          %int_tuple_628 = cute.make_int_tuple(%iv_627) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
          %ptr_629 = cute.add_offset(%iter_592, %int_tuple_628) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
          %int_tuple_630 = cute.make_int_tuple() : () -> !cute.int_tuple<"10">
          %ptr_631 = cute.add_offset(%iter_594, %int_tuple_630) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<f32, rmem, align<8>>
          %209 = builtin.unrealized_conversion_cast %ptr_629 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %210 = builtin.unrealized_conversion_cast %ptr_631 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %211 = llvm.load %209 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %211, %210 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %int_tuple_616 = cute.make_int_tuple() : () -> !cute.int_tuple<"11">
        %ptr_617 = cute.add_offset(%iter_595, %int_tuple_616) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<i8, rmem>
        %187 = builtin.unrealized_conversion_cast %ptr_617 : !cute.ptr<i8, rmem> to !llvm.ptr
        %188 = llvm.load %187 : !llvm.ptr -> i8
        %189 = llvm.mlir.constant(0 : i8) : i8
        %190 = llvm.icmp "ne" %188, %189 : i8
        scf.if %190 {
          %c2_i64 = arith.constant 2 : i64
          %207 = arith.muli %142, %c2_i64 : i64
          %c3_i64 = arith.constant 3 : i64
          %208 = arith.addi %207, %c3_i64 : i64
          %int_tuple_626 = cute.make_int_tuple(%208) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_627 = cute.add_offset(%iter_592, %int_tuple_626) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %int_tuple_628 = cute.make_int_tuple() : () -> !cute.int_tuple<"11">
          %ptr_629 = cute.add_offset(%iter_594, %int_tuple_628) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<f32, rmem>
          %209 = builtin.unrealized_conversion_cast %ptr_627 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %210 = builtin.unrealized_conversion_cast %ptr_629 : !cute.ptr<f32, rmem> to !llvm.ptr
          %211 = llvm.load %209 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %211, %210 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %int_tuple_618 = cute.make_int_tuple() : () -> !cute.int_tuple<"12">
        %ptr_619 = cute.add_offset(%iter_595, %int_tuple_618) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<i8, rmem, align<4>>
        %191 = builtin.unrealized_conversion_cast %ptr_619 : !cute.ptr<i8, rmem, align<4>> to !llvm.ptr
        %192 = llvm.load %191 : !llvm.ptr -> i8
        %193 = llvm.mlir.constant(0 : i8) : i8
        %194 = llvm.icmp "ne" %192, %193 : i8
        scf.if %194 {
          %c3_i64 = arith.constant 3 : i64
          %207 = arith.muli %142, %c3_i64 : i64
          %iv_626 = cute.assume(%207) : (i64) -> !cute.i64<divby 3>
          %int_tuple_627 = cute.make_int_tuple(%iv_626) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
          %ptr_628 = cute.add_offset(%iter_592, %int_tuple_627) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
          %int_tuple_629 = cute.make_int_tuple() : () -> !cute.int_tuple<"12">
          %ptr_630 = cute.add_offset(%iter_594, %int_tuple_629) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<f32, rmem, align<16>>
          %208 = builtin.unrealized_conversion_cast %ptr_628 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %209 = builtin.unrealized_conversion_cast %ptr_630 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
          %210 = llvm.load %208 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %210, %209 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %int_tuple_620 = cute.make_int_tuple() : () -> !cute.int_tuple<"13">
        %ptr_621 = cute.add_offset(%iter_595, %int_tuple_620) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<i8, rmem>
        %195 = builtin.unrealized_conversion_cast %ptr_621 : !cute.ptr<i8, rmem> to !llvm.ptr
        %196 = llvm.load %195 : !llvm.ptr -> i8
        %197 = llvm.mlir.constant(0 : i8) : i8
        %198 = llvm.icmp "ne" %196, %197 : i8
        scf.if %198 {
          %c3_i64 = arith.constant 3 : i64
          %207 = arith.muli %142, %c3_i64 : i64
          %c1_i64 = arith.constant 1 : i64
          %208 = arith.addi %207, %c1_i64 : i64
          %int_tuple_626 = cute.make_int_tuple(%208) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_627 = cute.add_offset(%iter_592, %int_tuple_626) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %int_tuple_628 = cute.make_int_tuple() : () -> !cute.int_tuple<"13">
          %ptr_629 = cute.add_offset(%iter_594, %int_tuple_628) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<f32, rmem>
          %209 = builtin.unrealized_conversion_cast %ptr_627 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %210 = builtin.unrealized_conversion_cast %ptr_629 : !cute.ptr<f32, rmem> to !llvm.ptr
          %211 = llvm.load %209 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %211, %210 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %int_tuple_622 = cute.make_int_tuple() : () -> !cute.int_tuple<"14">
        %ptr_623 = cute.add_offset(%iter_595, %int_tuple_622) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<i8, rmem, align<2>>
        %199 = builtin.unrealized_conversion_cast %ptr_623 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
        %200 = llvm.load %199 : !llvm.ptr -> i8
        %201 = llvm.mlir.constant(0 : i8) : i8
        %202 = llvm.icmp "ne" %200, %201 : i8
        scf.if %202 {
          %c3_i64 = arith.constant 3 : i64
          %207 = arith.muli %142, %c3_i64 : i64
          %c2_i64 = arith.constant 2 : i64
          %208 = arith.addi %207, %c2_i64 : i64
          %int_tuple_626 = cute.make_int_tuple(%208) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_627 = cute.add_offset(%iter_592, %int_tuple_626) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %int_tuple_628 = cute.make_int_tuple() : () -> !cute.int_tuple<"14">
          %ptr_629 = cute.add_offset(%iter_594, %int_tuple_628) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<f32, rmem, align<8>>
          %209 = builtin.unrealized_conversion_cast %ptr_627 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %210 = builtin.unrealized_conversion_cast %ptr_629 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %211 = llvm.load %209 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %211, %210 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %int_tuple_624 = cute.make_int_tuple() : () -> !cute.int_tuple<"15">
        %ptr_625 = cute.add_offset(%iter_595, %int_tuple_624) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<i8, rmem>
        %203 = builtin.unrealized_conversion_cast %ptr_625 : !cute.ptr<i8, rmem> to !llvm.ptr
        %204 = llvm.load %203 : !llvm.ptr -> i8
        %205 = llvm.mlir.constant(0 : i8) : i8
        %206 = llvm.icmp "ne" %204, %205 : i8
        scf.if %206 {
          %c3_i64 = arith.constant 3 : i64
          %207 = arith.muli %142, %c3_i64 : i64
          %c3_i64_626 = arith.constant 3 : i64
          %208 = arith.addi %207, %c3_i64_626 : i64
          %iv_627 = cute.assume(%208) : (i64) -> !cute.i64<divby 3>
          %int_tuple_628 = cute.make_int_tuple(%iv_627) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
          %ptr_629 = cute.add_offset(%iter_592, %int_tuple_628) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
          %int_tuple_630 = cute.make_int_tuple() : () -> !cute.int_tuple<"15">
          %ptr_631 = cute.add_offset(%iter_594, %int_tuple_630) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<f32, rmem>
          %209 = builtin.unrealized_conversion_cast %ptr_629 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %210 = builtin.unrealized_conversion_cast %ptr_631 : !cute.ptr<f32, rmem> to !llvm.ptr
          %211 = llvm.load %209 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %211, %210 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
      } {llvm.loop_annotation = #loop_annotation}
      %lay_373 = cute.get_layout(%view_190) : !memref_gmem_f32_2
      %113 = cute.get_shape(%lay_373) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_374, %e1_375, %e2_376, %e3_377, %e4_378 = cute.get_leaves(%113) : !cute.shape<"((1,(4,4)),1,1)">
      %lay_379 = cute.get_layout(%rmem_215) : !memref_rmem_f32_
      %114 = cute.get_shape(%lay_379) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_380, %e1_381, %e2_382, %e3_383, %e4_384 = cute.get_leaves(%114) : !cute.shape<"((1,(4,4)),1,1)">
      %lay_385 = cute.get_layout(%view_190) : !memref_gmem_f32_2
      %shape_386 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_387 = cute.make_layout() : !cute.layout<"1:0">
      %append_388 = cute.append_to_rank<2> (%lay_385, %lay_387) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">
      %view_389 = cute.make_view(%iter_191, %append_388) : !memref_gmem_f32_2
      %iter_390 = cute.get_iter(%view_389) : !memref_gmem_f32_2
      %lay_391 = cute.get_layout(%view_389) : !memref_gmem_f32_2
      %115 = cute.get_shape(%lay_391) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_392, %e1_393, %e2_394, %e3_395, %e4_396 = cute.get_leaves(%115) : !cute.shape<"((1,(4,4)),1,1)">
      %iter_397 = cute.get_iter(%view_389) : !memref_gmem_f32_2
      %lay_398 = cute.get_layout(%view_389) : !memref_gmem_f32_2
      %116 = cute.get_scalars(%lay_398) <{only_dynamic}> : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %shape_399 = cute.make_shape() : () -> !cute.shape<"((1,(4,4)),(1,1))">
      %stride_400 = cute.make_stride(%116) : (i64) -> !cute.stride<"((0,(1,?{i64})),(0,0))">
      %lay_401 = cute.make_layout(%shape_399, %stride_400) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %view_402 = cute.make_view(%iter_397, %lay_401) : !memref_gmem_f32_3
      %iter_403 = cute.get_iter(%view_402) : !memref_gmem_f32_3
      %iter_404 = cute.get_iter(%view_402) : !memref_gmem_f32_3
      %lay_405 = cute.get_layout(%rmem_215) : !memref_rmem_f32_
      %shape_406 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_407 = cute.make_layout() : !cute.layout<"1:0">
      %append_408 = cute.append_to_rank<2> (%lay_405, %lay_407) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
      %view_409 = cute.make_view(%iter_217, %append_408) : !memref_rmem_f32_
      %iter_410 = cute.get_iter(%view_409) : !memref_rmem_f32_
      %lay_411 = cute.get_layout(%view_409) : !memref_rmem_f32_
      %117 = cute.get_shape(%lay_411) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_412, %e1_413, %e2_414, %e3_415, %e4_416 = cute.get_leaves(%117) : !cute.shape<"((1,(4,4)),1,1)">
      %iter_417 = cute.get_iter(%view_409) : !memref_rmem_f32_
      %view_418 = cute.make_view(%iter_417) : !memref_rmem_f32_1
      %iter_419 = cute.get_iter(%view_418) : !memref_rmem_f32_1
      %iter_420 = cute.get_iter(%view_418) : !memref_rmem_f32_1
      %lay_421 = cute.get_layout(%99) : !memref_rmem_i8_
      %shape_422 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_423 = cute.make_layout() : !cute.layout<"1:0">
      %append_424 = cute.append_to_rank<2> (%lay_421, %lay_423) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
      %view_425 = cute.make_view(%iter_274, %append_424) : !memref_rmem_i8_
      %iter_426 = cute.get_iter(%view_425) : !memref_rmem_i8_
      %lay_427 = cute.get_layout(%view_425) : !memref_rmem_i8_
      %118 = cute.get_shape(%lay_427) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_428, %e1_429, %e2_430, %e3_431, %e4_432 = cute.get_leaves(%118) : !cute.shape<"((1,(4,4)),1,1)">
      %iter_433 = cute.get_iter(%view_425) : !memref_rmem_i8_
      %view_434 = cute.make_view(%iter_433) : !memref_rmem_i8_1
      %iter_435 = cute.get_iter(%view_434) : !memref_rmem_i8_1
      %iter_436 = cute.get_iter(%view_434) : !memref_rmem_i8_1
      %lay_437 = cute.get_layout(%view_402) : !memref_gmem_f32_3
      %119 = cute.get_shape(%lay_437) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
      %e0_438, %e1_439, %e2_440, %e3_441, %e4_442 = cute.get_leaves(%119) : !cute.shape<"((1,(4,4)),(1,1))">
      %lay_443 = cute.get_layout(%view_418) : !memref_rmem_f32_1
      %120 = cute.get_shape(%lay_443) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
      %e0_444, %e1_445, %e2_446, %e3_447, %e4_448 = cute.get_leaves(%120) : !cute.shape<"((1,(4,4)),(1,1))">
      %lay_449 = cute.get_layout(%view_402) : !memref_gmem_f32_3
      %sz_450 = cute.size(%lay_449) <{mode = [1]}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.int_tuple<"1">
      %e0_451 = cute.get_leaves(%sz_450) : !cute.int_tuple<"1">
      %lay_452 = cute.get_layout(%view_418) : !memref_rmem_f32_1
      %sz_453 = cute.size(%lay_452) <{mode = [1]}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.int_tuple<"1">
      %e0_454 = cute.get_leaves(%sz_453) : !cute.int_tuple<"1">
      %121 = cute.static : !cute.layout<"1:0">
      %iter_455 = cute.get_iter(%view_402) : !memref_gmem_f32_3
      %iter_456 = cute.get_iter(%view_418) : !memref_rmem_f32_1
      %lay_457 = cute.get_layout(%view_402) : !memref_gmem_f32_3
      %lay_458 = cute.get_layout(%view_418) : !memref_rmem_f32_1
      %append_459 = cute.append_to_rank<2> (%lay_457, %121) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">, !cute.layout<"1:0">
      %append_460 = cute.append_to_rank<2> (%lay_458, %121) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">, !cute.layout<"1:0">
      %122 = cute.get_scalars(%append_459) <{only_dynamic}> : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %shape_461 = cute.make_shape() : () -> !cute.shape<"((1,(4,4)),((1,1)))">
      %stride_462 = cute.make_stride(%122) : (i64) -> !cute.stride<"((0,(1,?{i64})),((0,0)))">
      %lay_463 = cute.make_layout(%shape_461, %stride_462) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
      %lay_464 = cute.make_layout() : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">
      %iter_465 = cute.get_iter(%view_434) : !memref_rmem_i8_1
      %lay_466 = cute.get_layout(%view_434) : !memref_rmem_i8_1
      %append_467 = cute.append_to_rank<2> (%lay_466, %121) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">, !cute.layout<"1:0">
      %lay_468 = cute.make_layout() : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">
      %sz_469 = cute.size(%lay_463) <{mode = [1]}> : (!cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">) -> !cute.int_tuple<"1">
      %123 = cute.get_scalars(%sz_469) : !cute.int_tuple<"1">
      %c0_i32_470 = arith.constant 0 : i32
      %c1_i32_471 = arith.constant 1 : i32
      scf.for %arg6 = %c0_i32_470 to %123 step %c1_i32_471  : i32 {
        %coord_577 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
        %138 = cute.get_scalars(%lay_463) <{only_dynamic}> : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
        %139 = cute.get_scalars(%coord_577) <{only_dynamic}> : !cute.coord<"(_,?)">
        %shape_578 = cute.make_shape() : () -> !cute.shape<"((1,(4,4)))">
        %stride_579 = cute.make_stride(%138) : (i64) -> !cute.stride<"((0,(1,?{i64})))">
        %lay_580 = cute.make_layout(%shape_578, %stride_579) : !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
        %idx_581 = cute.crd2idx(%coord_577, %lay_463) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">) -> !cute.int_tuple<"0">
        %ptr_582 = cute.add_offset(%iter_455, %idx_581) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<f32, gmem>
        %view_583 = cute.make_view(%ptr_582, %lay_580) : !memref_gmem_f32_4
        %140 = cute.get_scalars(%coord_577) <{only_dynamic}> : !cute.coord<"(_,?)">
        %lay_584 = cute.make_layout() : !cute.layout<"((1,(4,4))):((0,(1,4)))">
        %idx_585 = cute.crd2idx(%coord_577, %lay_464) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">) -> !cute.int_tuple<"0">
        %ptr_586 = cute.add_offset(%iter_456, %idx_585) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, rmem, align<32>>
        %view_587 = cute.make_view(%ptr_586, %lay_584) : !memref_rmem_f32_2
        %141 = cute.get_scalars(%coord_577) <{only_dynamic}> : !cute.coord<"(_,?)">
        %lay_588 = cute.make_layout() : !cute.layout<"((1,(4,4))):((0,(1,4)))">
        %idx_589 = cute.crd2idx(%coord_577, %lay_468) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">) -> !cute.int_tuple<"0">
        %ptr_590 = cute.add_offset(%iter_465, %idx_589) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
        %view_591 = cute.make_view(%ptr_590, %lay_588) : !memref_rmem_i8_2
        %iter_592 = cute.get_iter(%view_583) : !memref_gmem_f32_4
        %lay_593 = cute.get_layout(%view_583) : !memref_gmem_f32_4
        %142 = cute.get_scalars(%lay_593) <{only_dynamic}> : !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
        %iter_594 = cute.get_iter(%view_587) : !memref_rmem_f32_2
        %iter_595 = cute.get_iter(%view_591) : !memref_rmem_i8_2
        %143 = builtin.unrealized_conversion_cast %iter_595 : !cute.ptr<i8, rmem, align<32>> to !llvm.ptr
        %144 = llvm.load %143 : !llvm.ptr -> i8
        %145 = llvm.mlir.constant(0 : i8) : i8
        %146 = llvm.icmp "ne" %144, %145 : i8
        scf.if %146 {
          %207 = builtin.unrealized_conversion_cast %iter_592 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %208 = builtin.unrealized_conversion_cast %iter_594 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
          %209 = llvm.load %207 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %209, %208 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %int_tuple_596 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
        %ptr_597 = cute.add_offset(%iter_595, %int_tuple_596) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
        %147 = builtin.unrealized_conversion_cast %ptr_597 : !cute.ptr<i8, rmem> to !llvm.ptr
        %148 = llvm.load %147 : !llvm.ptr -> i8
        %149 = llvm.mlir.constant(0 : i8) : i8
        %150 = llvm.icmp "ne" %148, %149 : i8
        scf.if %150 {
          %int_tuple_626 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
          %ptr_627 = cute.add_offset(%iter_592, %int_tuple_626) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
          %int_tuple_628 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
          %ptr_629 = cute.add_offset(%iter_594, %int_tuple_628) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
          %207 = builtin.unrealized_conversion_cast %ptr_627 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %208 = builtin.unrealized_conversion_cast %ptr_629 : !cute.ptr<f32, rmem> to !llvm.ptr
          %209 = llvm.load %207 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %209, %208 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %int_tuple_598 = cute.make_int_tuple() : () -> !cute.int_tuple<"2">
        %ptr_599 = cute.add_offset(%iter_595, %int_tuple_598) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem, align<2>>
        %151 = builtin.unrealized_conversion_cast %ptr_599 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
        %152 = llvm.load %151 : !llvm.ptr -> i8
        %153 = llvm.mlir.constant(0 : i8) : i8
        %154 = llvm.icmp "ne" %152, %153 : i8
        scf.if %154 {
          %int_tuple_626 = cute.make_int_tuple() : () -> !cute.int_tuple<"2">
          %ptr_627 = cute.add_offset(%iter_592, %int_tuple_626) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
          %int_tuple_628 = cute.make_int_tuple() : () -> !cute.int_tuple<"2">
          %ptr_629 = cute.add_offset(%iter_594, %int_tuple_628) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
          %207 = builtin.unrealized_conversion_cast %ptr_627 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %208 = builtin.unrealized_conversion_cast %ptr_629 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %209 = llvm.load %207 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %209, %208 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %int_tuple_600 = cute.make_int_tuple() : () -> !cute.int_tuple<"3">
        %ptr_601 = cute.add_offset(%iter_595, %int_tuple_600) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
        %155 = builtin.unrealized_conversion_cast %ptr_601 : !cute.ptr<i8, rmem> to !llvm.ptr
        %156 = llvm.load %155 : !llvm.ptr -> i8
        %157 = llvm.mlir.constant(0 : i8) : i8
        %158 = llvm.icmp "ne" %156, %157 : i8
        scf.if %158 {
          %int_tuple_626 = cute.make_int_tuple() : () -> !cute.int_tuple<"3">
          %ptr_627 = cute.add_offset(%iter_592, %int_tuple_626) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
          %int_tuple_628 = cute.make_int_tuple() : () -> !cute.int_tuple<"3">
          %ptr_629 = cute.add_offset(%iter_594, %int_tuple_628) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
          %207 = builtin.unrealized_conversion_cast %ptr_627 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %208 = builtin.unrealized_conversion_cast %ptr_629 : !cute.ptr<f32, rmem> to !llvm.ptr
          %209 = llvm.load %207 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %209, %208 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %int_tuple_602 = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
        %ptr_603 = cute.add_offset(%iter_595, %int_tuple_602) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem, align<4>>
        %159 = builtin.unrealized_conversion_cast %ptr_603 : !cute.ptr<i8, rmem, align<4>> to !llvm.ptr
        %160 = llvm.load %159 : !llvm.ptr -> i8
        %161 = llvm.mlir.constant(0 : i8) : i8
        %162 = llvm.icmp "ne" %160, %161 : i8
        scf.if %162 {
          %int_tuple_626 = cute.make_int_tuple(%142) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_627 = cute.add_offset(%iter_592, %int_tuple_626) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %int_tuple_628 = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
          %ptr_629 = cute.add_offset(%iter_594, %int_tuple_628) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
          %207 = builtin.unrealized_conversion_cast %ptr_627 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %208 = builtin.unrealized_conversion_cast %ptr_629 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
          %209 = llvm.load %207 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %209, %208 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %int_tuple_604 = cute.make_int_tuple() : () -> !cute.int_tuple<"5">
        %ptr_605 = cute.add_offset(%iter_595, %int_tuple_604) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
        %163 = builtin.unrealized_conversion_cast %ptr_605 : !cute.ptr<i8, rmem> to !llvm.ptr
        %164 = llvm.load %163 : !llvm.ptr -> i8
        %165 = llvm.mlir.constant(0 : i8) : i8
        %166 = llvm.icmp "ne" %164, %165 : i8
        scf.if %166 {
          %c1_i64 = arith.constant 1 : i64
          %207 = arith.addi %142, %c1_i64 : i64
          %int_tuple_626 = cute.make_int_tuple(%207) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_627 = cute.add_offset(%iter_592, %int_tuple_626) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %int_tuple_628 = cute.make_int_tuple() : () -> !cute.int_tuple<"5">
          %ptr_629 = cute.add_offset(%iter_594, %int_tuple_628) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<f32, rmem>
          %208 = builtin.unrealized_conversion_cast %ptr_627 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %209 = builtin.unrealized_conversion_cast %ptr_629 : !cute.ptr<f32, rmem> to !llvm.ptr
          %210 = llvm.load %208 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %210, %209 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %int_tuple_606 = cute.make_int_tuple() : () -> !cute.int_tuple<"6">
        %ptr_607 = cute.add_offset(%iter_595, %int_tuple_606) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem, align<2>>
        %167 = builtin.unrealized_conversion_cast %ptr_607 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
        %168 = llvm.load %167 : !llvm.ptr -> i8
        %169 = llvm.mlir.constant(0 : i8) : i8
        %170 = llvm.icmp "ne" %168, %169 : i8
        scf.if %170 {
          %c2_i64 = arith.constant 2 : i64
          %207 = arith.addi %142, %c2_i64 : i64
          %int_tuple_626 = cute.make_int_tuple(%207) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_627 = cute.add_offset(%iter_592, %int_tuple_626) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %int_tuple_628 = cute.make_int_tuple() : () -> !cute.int_tuple<"6">
          %ptr_629 = cute.add_offset(%iter_594, %int_tuple_628) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
          %208 = builtin.unrealized_conversion_cast %ptr_627 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %209 = builtin.unrealized_conversion_cast %ptr_629 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %210 = llvm.load %208 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %210, %209 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %int_tuple_608 = cute.make_int_tuple() : () -> !cute.int_tuple<"7">
        %ptr_609 = cute.add_offset(%iter_595, %int_tuple_608) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
        %171 = builtin.unrealized_conversion_cast %ptr_609 : !cute.ptr<i8, rmem> to !llvm.ptr
        %172 = llvm.load %171 : !llvm.ptr -> i8
        %173 = llvm.mlir.constant(0 : i8) : i8
        %174 = llvm.icmp "ne" %172, %173 : i8
        scf.if %174 {
          %c3_i64 = arith.constant 3 : i64
          %207 = arith.addi %142, %c3_i64 : i64
          %int_tuple_626 = cute.make_int_tuple(%207) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_627 = cute.add_offset(%iter_592, %int_tuple_626) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %int_tuple_628 = cute.make_int_tuple() : () -> !cute.int_tuple<"7">
          %ptr_629 = cute.add_offset(%iter_594, %int_tuple_628) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<f32, rmem>
          %208 = builtin.unrealized_conversion_cast %ptr_627 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %209 = builtin.unrealized_conversion_cast %ptr_629 : !cute.ptr<f32, rmem> to !llvm.ptr
          %210 = llvm.load %208 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %210, %209 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %int_tuple_610 = cute.make_int_tuple() : () -> !cute.int_tuple<"8">
        %ptr_611 = cute.add_offset(%iter_595, %int_tuple_610) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<i8, rmem, align<8>>
        %175 = builtin.unrealized_conversion_cast %ptr_611 : !cute.ptr<i8, rmem, align<8>> to !llvm.ptr
        %176 = llvm.load %175 : !llvm.ptr -> i8
        %177 = llvm.mlir.constant(0 : i8) : i8
        %178 = llvm.icmp "ne" %176, %177 : i8
        scf.if %178 {
          %c2_i64 = arith.constant 2 : i64
          %207 = arith.muli %142, %c2_i64 : i64
          %iv_626 = cute.assume(%207) : (i64) -> !cute.i64<divby 2>
          %int_tuple_627 = cute.make_int_tuple(%iv_626) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
          %ptr_628 = cute.add_offset(%iter_592, %int_tuple_627) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
          %int_tuple_629 = cute.make_int_tuple() : () -> !cute.int_tuple<"8">
          %ptr_630 = cute.add_offset(%iter_594, %int_tuple_629) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<f32, rmem, align<32>>
          %208 = builtin.unrealized_conversion_cast %ptr_628 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %209 = builtin.unrealized_conversion_cast %ptr_630 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
          %210 = llvm.load %208 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %210, %209 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %int_tuple_612 = cute.make_int_tuple() : () -> !cute.int_tuple<"9">
        %ptr_613 = cute.add_offset(%iter_595, %int_tuple_612) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<i8, rmem>
        %179 = builtin.unrealized_conversion_cast %ptr_613 : !cute.ptr<i8, rmem> to !llvm.ptr
        %180 = llvm.load %179 : !llvm.ptr -> i8
        %181 = llvm.mlir.constant(0 : i8) : i8
        %182 = llvm.icmp "ne" %180, %181 : i8
        scf.if %182 {
          %c2_i64 = arith.constant 2 : i64
          %207 = arith.muli %142, %c2_i64 : i64
          %c1_i64 = arith.constant 1 : i64
          %208 = arith.addi %207, %c1_i64 : i64
          %int_tuple_626 = cute.make_int_tuple(%208) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_627 = cute.add_offset(%iter_592, %int_tuple_626) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %int_tuple_628 = cute.make_int_tuple() : () -> !cute.int_tuple<"9">
          %ptr_629 = cute.add_offset(%iter_594, %int_tuple_628) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<f32, rmem>
          %209 = builtin.unrealized_conversion_cast %ptr_627 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %210 = builtin.unrealized_conversion_cast %ptr_629 : !cute.ptr<f32, rmem> to !llvm.ptr
          %211 = llvm.load %209 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %211, %210 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %int_tuple_614 = cute.make_int_tuple() : () -> !cute.int_tuple<"10">
        %ptr_615 = cute.add_offset(%iter_595, %int_tuple_614) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<i8, rmem, align<2>>
        %183 = builtin.unrealized_conversion_cast %ptr_615 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
        %184 = llvm.load %183 : !llvm.ptr -> i8
        %185 = llvm.mlir.constant(0 : i8) : i8
        %186 = llvm.icmp "ne" %184, %185 : i8
        scf.if %186 {
          %c2_i64 = arith.constant 2 : i64
          %207 = arith.muli %142, %c2_i64 : i64
          %c2_i64_626 = arith.constant 2 : i64
          %208 = arith.addi %207, %c2_i64_626 : i64
          %iv_627 = cute.assume(%208) : (i64) -> !cute.i64<divby 2>
          %int_tuple_628 = cute.make_int_tuple(%iv_627) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
          %ptr_629 = cute.add_offset(%iter_592, %int_tuple_628) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
          %int_tuple_630 = cute.make_int_tuple() : () -> !cute.int_tuple<"10">
          %ptr_631 = cute.add_offset(%iter_594, %int_tuple_630) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<f32, rmem, align<8>>
          %209 = builtin.unrealized_conversion_cast %ptr_629 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %210 = builtin.unrealized_conversion_cast %ptr_631 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %211 = llvm.load %209 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %211, %210 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %int_tuple_616 = cute.make_int_tuple() : () -> !cute.int_tuple<"11">
        %ptr_617 = cute.add_offset(%iter_595, %int_tuple_616) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<i8, rmem>
        %187 = builtin.unrealized_conversion_cast %ptr_617 : !cute.ptr<i8, rmem> to !llvm.ptr
        %188 = llvm.load %187 : !llvm.ptr -> i8
        %189 = llvm.mlir.constant(0 : i8) : i8
        %190 = llvm.icmp "ne" %188, %189 : i8
        scf.if %190 {
          %c2_i64 = arith.constant 2 : i64
          %207 = arith.muli %142, %c2_i64 : i64
          %c3_i64 = arith.constant 3 : i64
          %208 = arith.addi %207, %c3_i64 : i64
          %int_tuple_626 = cute.make_int_tuple(%208) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_627 = cute.add_offset(%iter_592, %int_tuple_626) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %int_tuple_628 = cute.make_int_tuple() : () -> !cute.int_tuple<"11">
          %ptr_629 = cute.add_offset(%iter_594, %int_tuple_628) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<f32, rmem>
          %209 = builtin.unrealized_conversion_cast %ptr_627 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %210 = builtin.unrealized_conversion_cast %ptr_629 : !cute.ptr<f32, rmem> to !llvm.ptr
          %211 = llvm.load %209 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %211, %210 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %int_tuple_618 = cute.make_int_tuple() : () -> !cute.int_tuple<"12">
        %ptr_619 = cute.add_offset(%iter_595, %int_tuple_618) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<i8, rmem, align<4>>
        %191 = builtin.unrealized_conversion_cast %ptr_619 : !cute.ptr<i8, rmem, align<4>> to !llvm.ptr
        %192 = llvm.load %191 : !llvm.ptr -> i8
        %193 = llvm.mlir.constant(0 : i8) : i8
        %194 = llvm.icmp "ne" %192, %193 : i8
        scf.if %194 {
          %c3_i64 = arith.constant 3 : i64
          %207 = arith.muli %142, %c3_i64 : i64
          %iv_626 = cute.assume(%207) : (i64) -> !cute.i64<divby 3>
          %int_tuple_627 = cute.make_int_tuple(%iv_626) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
          %ptr_628 = cute.add_offset(%iter_592, %int_tuple_627) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
          %int_tuple_629 = cute.make_int_tuple() : () -> !cute.int_tuple<"12">
          %ptr_630 = cute.add_offset(%iter_594, %int_tuple_629) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<f32, rmem, align<16>>
          %208 = builtin.unrealized_conversion_cast %ptr_628 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %209 = builtin.unrealized_conversion_cast %ptr_630 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
          %210 = llvm.load %208 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %210, %209 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %int_tuple_620 = cute.make_int_tuple() : () -> !cute.int_tuple<"13">
        %ptr_621 = cute.add_offset(%iter_595, %int_tuple_620) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<i8, rmem>
        %195 = builtin.unrealized_conversion_cast %ptr_621 : !cute.ptr<i8, rmem> to !llvm.ptr
        %196 = llvm.load %195 : !llvm.ptr -> i8
        %197 = llvm.mlir.constant(0 : i8) : i8
        %198 = llvm.icmp "ne" %196, %197 : i8
        scf.if %198 {
          %c3_i64 = arith.constant 3 : i64
          %207 = arith.muli %142, %c3_i64 : i64
          %c1_i64 = arith.constant 1 : i64
          %208 = arith.addi %207, %c1_i64 : i64
          %int_tuple_626 = cute.make_int_tuple(%208) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_627 = cute.add_offset(%iter_592, %int_tuple_626) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %int_tuple_628 = cute.make_int_tuple() : () -> !cute.int_tuple<"13">
          %ptr_629 = cute.add_offset(%iter_594, %int_tuple_628) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<f32, rmem>
          %209 = builtin.unrealized_conversion_cast %ptr_627 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %210 = builtin.unrealized_conversion_cast %ptr_629 : !cute.ptr<f32, rmem> to !llvm.ptr
          %211 = llvm.load %209 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %211, %210 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %int_tuple_622 = cute.make_int_tuple() : () -> !cute.int_tuple<"14">
        %ptr_623 = cute.add_offset(%iter_595, %int_tuple_622) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<i8, rmem, align<2>>
        %199 = builtin.unrealized_conversion_cast %ptr_623 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
        %200 = llvm.load %199 : !llvm.ptr -> i8
        %201 = llvm.mlir.constant(0 : i8) : i8
        %202 = llvm.icmp "ne" %200, %201 : i8
        scf.if %202 {
          %c3_i64 = arith.constant 3 : i64
          %207 = arith.muli %142, %c3_i64 : i64
          %c2_i64 = arith.constant 2 : i64
          %208 = arith.addi %207, %c2_i64 : i64
          %int_tuple_626 = cute.make_int_tuple(%208) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_627 = cute.add_offset(%iter_592, %int_tuple_626) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %int_tuple_628 = cute.make_int_tuple() : () -> !cute.int_tuple<"14">
          %ptr_629 = cute.add_offset(%iter_594, %int_tuple_628) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<f32, rmem, align<8>>
          %209 = builtin.unrealized_conversion_cast %ptr_627 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %210 = builtin.unrealized_conversion_cast %ptr_629 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %211 = llvm.load %209 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %211, %210 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %int_tuple_624 = cute.make_int_tuple() : () -> !cute.int_tuple<"15">
        %ptr_625 = cute.add_offset(%iter_595, %int_tuple_624) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<i8, rmem>
        %203 = builtin.unrealized_conversion_cast %ptr_625 : !cute.ptr<i8, rmem> to !llvm.ptr
        %204 = llvm.load %203 : !llvm.ptr -> i8
        %205 = llvm.mlir.constant(0 : i8) : i8
        %206 = llvm.icmp "ne" %204, %205 : i8
        scf.if %206 {
          %c3_i64 = arith.constant 3 : i64
          %207 = arith.muli %142, %c3_i64 : i64
          %c3_i64_626 = arith.constant 3 : i64
          %208 = arith.addi %207, %c3_i64_626 : i64
          %iv_627 = cute.assume(%208) : (i64) -> !cute.i64<divby 3>
          %int_tuple_628 = cute.make_int_tuple(%iv_627) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
          %ptr_629 = cute.add_offset(%iter_592, %int_tuple_628) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
          %int_tuple_630 = cute.make_int_tuple() : () -> !cute.int_tuple<"15">
          %ptr_631 = cute.add_offset(%iter_594, %int_tuple_630) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<f32, rmem>
          %209 = builtin.unrealized_conversion_cast %ptr_629 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %210 = builtin.unrealized_conversion_cast %ptr_631 : !cute.ptr<f32, rmem> to !llvm.ptr
          %211 = llvm.load %209 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %211, %210 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
      } {llvm.loop_annotation = #loop_annotation}
      %124 = cute.memref.load_vec %rmem : !memref_rmem_f32_
      %125 = cute.memref.load_vec %rmem_215 : !memref_rmem_f32_
      %126 = arith.addf %124, %125 : vector<16xf32>
      %lay_472 = cute.get_layout(%rmem_220) : !memref_rmem_f32_
      %127 = cute.get_shape(%lay_472) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_473, %e1_474, %e2_475, %e3_476, %e4_477 = cute.get_leaves(%127) : !cute.shape<"((1,(4,4)),1,1)">
      %int_tuple_478 = cute.make_int_tuple() : () -> !cute.int_tuple<"((1,(4,4)),1,1)">
      %sz_479 = cute.size(%int_tuple_478) : (!cute.int_tuple<"((1,(4,4)),1,1)">) -> !cute.int_tuple<"16">
      %e0_480 = cute.get_leaves(%sz_479) : !cute.int_tuple<"16">
      %int_tuple_481 = cute.make_int_tuple() : () -> !cute.int_tuple<"((1,(4,4)),1,1)">
      %sz_482 = cute.size(%int_tuple_481) : (!cute.int_tuple<"((1,(4,4)),1,1)">) -> !cute.int_tuple<"16">
      %e0_483 = cute.get_leaves(%sz_482) : !cute.int_tuple<"16">
      cute.memref.store_vec %126, %rmem_220 : !memref_rmem_f32_
      %lay_484 = cute.get_layout(%view_207) : !memref_gmem_f32_2
      %128 = cute.get_shape(%lay_484) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_485, %e1_486, %e2_487, %e3_488, %e4_489 = cute.get_leaves(%128) : !cute.shape<"((1,(4,4)),1,1)">
      %lay_490 = cute.get_layout(%rmem_220) : !memref_rmem_f32_
      %shape_491 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_492 = cute.make_layout() : !cute.layout<"1:0">
      %append_493 = cute.append_to_rank<2> (%lay_490, %lay_492) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
      %view_494 = cute.make_view(%iter_222, %append_493) : !memref_rmem_f32_
      %iter_495 = cute.get_iter(%view_494) : !memref_rmem_f32_
      %lay_496 = cute.get_layout(%view_494) : !memref_rmem_f32_
      %129 = cute.get_shape(%lay_496) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_497, %e1_498, %e2_499, %e3_500, %e4_501 = cute.get_leaves(%129) : !cute.shape<"((1,(4,4)),1,1)">
      %iter_502 = cute.get_iter(%view_494) : !memref_rmem_f32_
      %view_503 = cute.make_view(%iter_502) : !memref_rmem_f32_1
      %iter_504 = cute.get_iter(%view_503) : !memref_rmem_f32_1
      %iter_505 = cute.get_iter(%view_503) : !memref_rmem_f32_1
      %lay_506 = cute.get_layout(%view_207) : !memref_gmem_f32_2
      %shape_507 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_508 = cute.make_layout() : !cute.layout<"1:0">
      %append_509 = cute.append_to_rank<2> (%lay_506, %lay_508) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">
      %view_510 = cute.make_view(%iter_208, %append_509) : !memref_gmem_f32_2
      %iter_511 = cute.get_iter(%view_510) : !memref_gmem_f32_2
      %lay_512 = cute.get_layout(%view_510) : !memref_gmem_f32_2
      %130 = cute.get_shape(%lay_512) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_513, %e1_514, %e2_515, %e3_516, %e4_517 = cute.get_leaves(%130) : !cute.shape<"((1,(4,4)),1,1)">
      %iter_518 = cute.get_iter(%view_510) : !memref_gmem_f32_2
      %lay_519 = cute.get_layout(%view_510) : !memref_gmem_f32_2
      %131 = cute.get_scalars(%lay_519) <{only_dynamic}> : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %shape_520 = cute.make_shape() : () -> !cute.shape<"((1,(4,4)),(1,1))">
      %stride_521 = cute.make_stride(%131) : (i64) -> !cute.stride<"((0,(1,?{i64})),(0,0))">
      %lay_522 = cute.make_layout(%shape_520, %stride_521) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %view_523 = cute.make_view(%iter_518, %lay_522) : !memref_gmem_f32_3
      %iter_524 = cute.get_iter(%view_523) : !memref_gmem_f32_3
      %iter_525 = cute.get_iter(%view_523) : !memref_gmem_f32_3
      %lay_526 = cute.get_layout(%99) : !memref_rmem_i8_
      %shape_527 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_528 = cute.make_layout() : !cute.layout<"1:0">
      %append_529 = cute.append_to_rank<2> (%lay_526, %lay_528) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
      %view_530 = cute.make_view(%iter_274, %append_529) : !memref_rmem_i8_
      %iter_531 = cute.get_iter(%view_530) : !memref_rmem_i8_
      %lay_532 = cute.get_layout(%view_530) : !memref_rmem_i8_
      %132 = cute.get_shape(%lay_532) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_533, %e1_534, %e2_535, %e3_536, %e4_537 = cute.get_leaves(%132) : !cute.shape<"((1,(4,4)),1,1)">
      %iter_538 = cute.get_iter(%view_530) : !memref_rmem_i8_
      %view_539 = cute.make_view(%iter_538) : !memref_rmem_i8_1
      %iter_540 = cute.get_iter(%view_539) : !memref_rmem_i8_1
      %iter_541 = cute.get_iter(%view_539) : !memref_rmem_i8_1
      %lay_542 = cute.get_layout(%view_503) : !memref_rmem_f32_1
      %133 = cute.get_shape(%lay_542) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
      %e0_543, %e1_544, %e2_545, %e3_546, %e4_547 = cute.get_leaves(%133) : !cute.shape<"((1,(4,4)),(1,1))">
      %lay_548 = cute.get_layout(%view_523) : !memref_gmem_f32_3
      %134 = cute.get_shape(%lay_548) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
      %e0_549, %e1_550, %e2_551, %e3_552, %e4_553 = cute.get_leaves(%134) : !cute.shape<"((1,(4,4)),(1,1))">
      %lay_554 = cute.get_layout(%view_503) : !memref_rmem_f32_1
      %sz_555 = cute.size(%lay_554) <{mode = [1]}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.int_tuple<"1">
      %e0_556 = cute.get_leaves(%sz_555) : !cute.int_tuple<"1">
      %lay_557 = cute.get_layout(%view_523) : !memref_gmem_f32_3
      %sz_558 = cute.size(%lay_557) <{mode = [1]}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.int_tuple<"1">
      %e0_559 = cute.get_leaves(%sz_558) : !cute.int_tuple<"1">
      %135 = cute.static : !cute.layout<"1:0">
      %iter_560 = cute.get_iter(%view_503) : !memref_rmem_f32_1
      %iter_561 = cute.get_iter(%view_523) : !memref_gmem_f32_3
      %lay_562 = cute.get_layout(%view_503) : !memref_rmem_f32_1
      %lay_563 = cute.get_layout(%view_523) : !memref_gmem_f32_3
      %append_564 = cute.append_to_rank<2> (%lay_562, %135) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">, !cute.layout<"1:0">
      %append_565 = cute.append_to_rank<2> (%lay_563, %135) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">, !cute.layout<"1:0">
      %lay_566 = cute.make_layout() : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">
      %136 = cute.get_scalars(%append_565) <{only_dynamic}> : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %shape_567 = cute.make_shape() : () -> !cute.shape<"((1,(4,4)),((1,1)))">
      %stride_568 = cute.make_stride(%136) : (i64) -> !cute.stride<"((0,(1,?{i64})),((0,0)))">
      %lay_569 = cute.make_layout(%shape_567, %stride_568) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
      %iter_570 = cute.get_iter(%view_539) : !memref_rmem_i8_1
      %lay_571 = cute.get_layout(%view_539) : !memref_rmem_i8_1
      %append_572 = cute.append_to_rank<2> (%lay_571, %135) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">, !cute.layout<"1:0">
      %lay_573 = cute.make_layout() : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">
      %sz_574 = cute.size(%lay_566) <{mode = [1]}> : (!cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">) -> !cute.int_tuple<"1">
      %137 = cute.get_scalars(%sz_574) : !cute.int_tuple<"1">
      %c0_i32_575 = arith.constant 0 : i32
      %c1_i32_576 = arith.constant 1 : i32
      scf.for %arg6 = %c0_i32_575 to %137 step %c1_i32_576  : i32 {
        %coord_577 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
        %138 = cute.get_scalars(%coord_577) <{only_dynamic}> : !cute.coord<"(_,?)">
        %lay_578 = cute.make_layout() : !cute.layout<"((1,(4,4))):((0,(1,4)))">
        %idx_579 = cute.crd2idx(%coord_577, %lay_566) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">) -> !cute.int_tuple<"0">
        %ptr_580 = cute.add_offset(%iter_560, %idx_579) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, rmem, align<32>>
        %view_581 = cute.make_view(%ptr_580, %lay_578) : !memref_rmem_f32_2
        %139 = cute.get_scalars(%lay_569) <{only_dynamic}> : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
        %140 = cute.get_scalars(%coord_577) <{only_dynamic}> : !cute.coord<"(_,?)">
        %shape_582 = cute.make_shape() : () -> !cute.shape<"((1,(4,4)))">
        %stride_583 = cute.make_stride(%139) : (i64) -> !cute.stride<"((0,(1,?{i64})))">
        %lay_584 = cute.make_layout(%shape_582, %stride_583) : !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
        %idx_585 = cute.crd2idx(%coord_577, %lay_569) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">) -> !cute.int_tuple<"0">
        %ptr_586 = cute.add_offset(%iter_561, %idx_585) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<f32, gmem>
        %view_587 = cute.make_view(%ptr_586, %lay_584) : !memref_gmem_f32_4
        %141 = cute.get_scalars(%coord_577) <{only_dynamic}> : !cute.coord<"(_,?)">
        %lay_588 = cute.make_layout() : !cute.layout<"((1,(4,4))):((0,(1,4)))">
        %idx_589 = cute.crd2idx(%coord_577, %lay_573) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">) -> !cute.int_tuple<"0">
        %ptr_590 = cute.add_offset(%iter_570, %idx_589) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
        %view_591 = cute.make_view(%ptr_590, %lay_588) : !memref_rmem_i8_2
        %iter_592 = cute.get_iter(%view_581) : !memref_rmem_f32_2
        %iter_593 = cute.get_iter(%view_587) : !memref_gmem_f32_4
        %lay_594 = cute.get_layout(%view_587) : !memref_gmem_f32_4
        %142 = cute.get_scalars(%lay_594) <{only_dynamic}> : !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
        %iter_595 = cute.get_iter(%view_591) : !memref_rmem_i8_2
        %143 = builtin.unrealized_conversion_cast %iter_595 : !cute.ptr<i8, rmem, align<32>> to !llvm.ptr
        %144 = llvm.load %143 : !llvm.ptr -> i8
        %145 = llvm.mlir.constant(0 : i8) : i8
        %146 = llvm.icmp "ne" %144, %145 : i8
        scf.if %146 {
          %207 = builtin.unrealized_conversion_cast %iter_592 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
          %208 = builtin.unrealized_conversion_cast %iter_593 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %209 = llvm.load %207 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %209, %208 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %int_tuple_596 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
        %ptr_597 = cute.add_offset(%iter_595, %int_tuple_596) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
        %147 = builtin.unrealized_conversion_cast %ptr_597 : !cute.ptr<i8, rmem> to !llvm.ptr
        %148 = llvm.load %147 : !llvm.ptr -> i8
        %149 = llvm.mlir.constant(0 : i8) : i8
        %150 = llvm.icmp "ne" %148, %149 : i8
        scf.if %150 {
          %int_tuple_626 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
          %ptr_627 = cute.add_offset(%iter_592, %int_tuple_626) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
          %int_tuple_628 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
          %ptr_629 = cute.add_offset(%iter_593, %int_tuple_628) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
          %207 = builtin.unrealized_conversion_cast %ptr_627 : !cute.ptr<f32, rmem> to !llvm.ptr
          %208 = builtin.unrealized_conversion_cast %ptr_629 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %209 = llvm.load %207 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %209, %208 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %int_tuple_598 = cute.make_int_tuple() : () -> !cute.int_tuple<"2">
        %ptr_599 = cute.add_offset(%iter_595, %int_tuple_598) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem, align<2>>
        %151 = builtin.unrealized_conversion_cast %ptr_599 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
        %152 = llvm.load %151 : !llvm.ptr -> i8
        %153 = llvm.mlir.constant(0 : i8) : i8
        %154 = llvm.icmp "ne" %152, %153 : i8
        scf.if %154 {
          %int_tuple_626 = cute.make_int_tuple() : () -> !cute.int_tuple<"2">
          %ptr_627 = cute.add_offset(%iter_592, %int_tuple_626) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
          %int_tuple_628 = cute.make_int_tuple() : () -> !cute.int_tuple<"2">
          %ptr_629 = cute.add_offset(%iter_593, %int_tuple_628) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
          %207 = builtin.unrealized_conversion_cast %ptr_627 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %208 = builtin.unrealized_conversion_cast %ptr_629 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %209 = llvm.load %207 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %209, %208 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %int_tuple_600 = cute.make_int_tuple() : () -> !cute.int_tuple<"3">
        %ptr_601 = cute.add_offset(%iter_595, %int_tuple_600) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
        %155 = builtin.unrealized_conversion_cast %ptr_601 : !cute.ptr<i8, rmem> to !llvm.ptr
        %156 = llvm.load %155 : !llvm.ptr -> i8
        %157 = llvm.mlir.constant(0 : i8) : i8
        %158 = llvm.icmp "ne" %156, %157 : i8
        scf.if %158 {
          %int_tuple_626 = cute.make_int_tuple() : () -> !cute.int_tuple<"3">
          %ptr_627 = cute.add_offset(%iter_592, %int_tuple_626) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
          %int_tuple_628 = cute.make_int_tuple() : () -> !cute.int_tuple<"3">
          %ptr_629 = cute.add_offset(%iter_593, %int_tuple_628) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
          %207 = builtin.unrealized_conversion_cast %ptr_627 : !cute.ptr<f32, rmem> to !llvm.ptr
          %208 = builtin.unrealized_conversion_cast %ptr_629 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %209 = llvm.load %207 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %209, %208 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %int_tuple_602 = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
        %ptr_603 = cute.add_offset(%iter_595, %int_tuple_602) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem, align<4>>
        %159 = builtin.unrealized_conversion_cast %ptr_603 : !cute.ptr<i8, rmem, align<4>> to !llvm.ptr
        %160 = llvm.load %159 : !llvm.ptr -> i8
        %161 = llvm.mlir.constant(0 : i8) : i8
        %162 = llvm.icmp "ne" %160, %161 : i8
        scf.if %162 {
          %int_tuple_626 = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
          %ptr_627 = cute.add_offset(%iter_592, %int_tuple_626) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
          %int_tuple_628 = cute.make_int_tuple(%142) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_629 = cute.add_offset(%iter_593, %int_tuple_628) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %207 = builtin.unrealized_conversion_cast %ptr_627 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
          %208 = builtin.unrealized_conversion_cast %ptr_629 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %209 = llvm.load %207 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %209, %208 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %int_tuple_604 = cute.make_int_tuple() : () -> !cute.int_tuple<"5">
        %ptr_605 = cute.add_offset(%iter_595, %int_tuple_604) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
        %163 = builtin.unrealized_conversion_cast %ptr_605 : !cute.ptr<i8, rmem> to !llvm.ptr
        %164 = llvm.load %163 : !llvm.ptr -> i8
        %165 = llvm.mlir.constant(0 : i8) : i8
        %166 = llvm.icmp "ne" %164, %165 : i8
        scf.if %166 {
          %int_tuple_626 = cute.make_int_tuple() : () -> !cute.int_tuple<"5">
          %ptr_627 = cute.add_offset(%iter_592, %int_tuple_626) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<f32, rmem>
          %c1_i64 = arith.constant 1 : i64
          %207 = arith.addi %142, %c1_i64 : i64
          %int_tuple_628 = cute.make_int_tuple(%207) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_629 = cute.add_offset(%iter_593, %int_tuple_628) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %208 = builtin.unrealized_conversion_cast %ptr_627 : !cute.ptr<f32, rmem> to !llvm.ptr
          %209 = builtin.unrealized_conversion_cast %ptr_629 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %210 = llvm.load %208 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %210, %209 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %int_tuple_606 = cute.make_int_tuple() : () -> !cute.int_tuple<"6">
        %ptr_607 = cute.add_offset(%iter_595, %int_tuple_606) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem, align<2>>
        %167 = builtin.unrealized_conversion_cast %ptr_607 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
        %168 = llvm.load %167 : !llvm.ptr -> i8
        %169 = llvm.mlir.constant(0 : i8) : i8
        %170 = llvm.icmp "ne" %168, %169 : i8
        scf.if %170 {
          %int_tuple_626 = cute.make_int_tuple() : () -> !cute.int_tuple<"6">
          %ptr_627 = cute.add_offset(%iter_592, %int_tuple_626) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
          %c2_i64 = arith.constant 2 : i64
          %207 = arith.addi %142, %c2_i64 : i64
          %int_tuple_628 = cute.make_int_tuple(%207) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_629 = cute.add_offset(%iter_593, %int_tuple_628) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %208 = builtin.unrealized_conversion_cast %ptr_627 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %209 = builtin.unrealized_conversion_cast %ptr_629 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %210 = llvm.load %208 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %210, %209 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %int_tuple_608 = cute.make_int_tuple() : () -> !cute.int_tuple<"7">
        %ptr_609 = cute.add_offset(%iter_595, %int_tuple_608) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
        %171 = builtin.unrealized_conversion_cast %ptr_609 : !cute.ptr<i8, rmem> to !llvm.ptr
        %172 = llvm.load %171 : !llvm.ptr -> i8
        %173 = llvm.mlir.constant(0 : i8) : i8
        %174 = llvm.icmp "ne" %172, %173 : i8
        scf.if %174 {
          %int_tuple_626 = cute.make_int_tuple() : () -> !cute.int_tuple<"7">
          %ptr_627 = cute.add_offset(%iter_592, %int_tuple_626) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<f32, rmem>
          %c3_i64 = arith.constant 3 : i64
          %207 = arith.addi %142, %c3_i64 : i64
          %int_tuple_628 = cute.make_int_tuple(%207) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_629 = cute.add_offset(%iter_593, %int_tuple_628) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %208 = builtin.unrealized_conversion_cast %ptr_627 : !cute.ptr<f32, rmem> to !llvm.ptr
          %209 = builtin.unrealized_conversion_cast %ptr_629 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %210 = llvm.load %208 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %210, %209 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %int_tuple_610 = cute.make_int_tuple() : () -> !cute.int_tuple<"8">
        %ptr_611 = cute.add_offset(%iter_595, %int_tuple_610) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<i8, rmem, align<8>>
        %175 = builtin.unrealized_conversion_cast %ptr_611 : !cute.ptr<i8, rmem, align<8>> to !llvm.ptr
        %176 = llvm.load %175 : !llvm.ptr -> i8
        %177 = llvm.mlir.constant(0 : i8) : i8
        %178 = llvm.icmp "ne" %176, %177 : i8
        scf.if %178 {
          %int_tuple_626 = cute.make_int_tuple() : () -> !cute.int_tuple<"8">
          %ptr_627 = cute.add_offset(%iter_592, %int_tuple_626) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<f32, rmem, align<32>>
          %c2_i64 = arith.constant 2 : i64
          %207 = arith.muli %142, %c2_i64 : i64
          %iv_628 = cute.assume(%207) : (i64) -> !cute.i64<divby 2>
          %int_tuple_629 = cute.make_int_tuple(%iv_628) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
          %ptr_630 = cute.add_offset(%iter_593, %int_tuple_629) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
          %208 = builtin.unrealized_conversion_cast %ptr_627 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
          %209 = builtin.unrealized_conversion_cast %ptr_630 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %210 = llvm.load %208 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %210, %209 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %int_tuple_612 = cute.make_int_tuple() : () -> !cute.int_tuple<"9">
        %ptr_613 = cute.add_offset(%iter_595, %int_tuple_612) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<i8, rmem>
        %179 = builtin.unrealized_conversion_cast %ptr_613 : !cute.ptr<i8, rmem> to !llvm.ptr
        %180 = llvm.load %179 : !llvm.ptr -> i8
        %181 = llvm.mlir.constant(0 : i8) : i8
        %182 = llvm.icmp "ne" %180, %181 : i8
        scf.if %182 {
          %int_tuple_626 = cute.make_int_tuple() : () -> !cute.int_tuple<"9">
          %ptr_627 = cute.add_offset(%iter_592, %int_tuple_626) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<f32, rmem>
          %c2_i64 = arith.constant 2 : i64
          %207 = arith.muli %142, %c2_i64 : i64
          %c1_i64 = arith.constant 1 : i64
          %208 = arith.addi %207, %c1_i64 : i64
          %int_tuple_628 = cute.make_int_tuple(%208) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_629 = cute.add_offset(%iter_593, %int_tuple_628) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %209 = builtin.unrealized_conversion_cast %ptr_627 : !cute.ptr<f32, rmem> to !llvm.ptr
          %210 = builtin.unrealized_conversion_cast %ptr_629 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %211 = llvm.load %209 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %211, %210 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %int_tuple_614 = cute.make_int_tuple() : () -> !cute.int_tuple<"10">
        %ptr_615 = cute.add_offset(%iter_595, %int_tuple_614) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<i8, rmem, align<2>>
        %183 = builtin.unrealized_conversion_cast %ptr_615 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
        %184 = llvm.load %183 : !llvm.ptr -> i8
        %185 = llvm.mlir.constant(0 : i8) : i8
        %186 = llvm.icmp "ne" %184, %185 : i8
        scf.if %186 {
          %int_tuple_626 = cute.make_int_tuple() : () -> !cute.int_tuple<"10">
          %ptr_627 = cute.add_offset(%iter_592, %int_tuple_626) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<f32, rmem, align<8>>
          %c2_i64 = arith.constant 2 : i64
          %207 = arith.muli %142, %c2_i64 : i64
          %c2_i64_628 = arith.constant 2 : i64
          %208 = arith.addi %207, %c2_i64_628 : i64
          %iv_629 = cute.assume(%208) : (i64) -> !cute.i64<divby 2>
          %int_tuple_630 = cute.make_int_tuple(%iv_629) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
          %ptr_631 = cute.add_offset(%iter_593, %int_tuple_630) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
          %209 = builtin.unrealized_conversion_cast %ptr_627 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %210 = builtin.unrealized_conversion_cast %ptr_631 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %211 = llvm.load %209 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %211, %210 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %int_tuple_616 = cute.make_int_tuple() : () -> !cute.int_tuple<"11">
        %ptr_617 = cute.add_offset(%iter_595, %int_tuple_616) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<i8, rmem>
        %187 = builtin.unrealized_conversion_cast %ptr_617 : !cute.ptr<i8, rmem> to !llvm.ptr
        %188 = llvm.load %187 : !llvm.ptr -> i8
        %189 = llvm.mlir.constant(0 : i8) : i8
        %190 = llvm.icmp "ne" %188, %189 : i8
        scf.if %190 {
          %int_tuple_626 = cute.make_int_tuple() : () -> !cute.int_tuple<"11">
          %ptr_627 = cute.add_offset(%iter_592, %int_tuple_626) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<f32, rmem>
          %c2_i64 = arith.constant 2 : i64
          %207 = arith.muli %142, %c2_i64 : i64
          %c3_i64 = arith.constant 3 : i64
          %208 = arith.addi %207, %c3_i64 : i64
          %int_tuple_628 = cute.make_int_tuple(%208) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_629 = cute.add_offset(%iter_593, %int_tuple_628) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %209 = builtin.unrealized_conversion_cast %ptr_627 : !cute.ptr<f32, rmem> to !llvm.ptr
          %210 = builtin.unrealized_conversion_cast %ptr_629 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %211 = llvm.load %209 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %211, %210 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %int_tuple_618 = cute.make_int_tuple() : () -> !cute.int_tuple<"12">
        %ptr_619 = cute.add_offset(%iter_595, %int_tuple_618) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<i8, rmem, align<4>>
        %191 = builtin.unrealized_conversion_cast %ptr_619 : !cute.ptr<i8, rmem, align<4>> to !llvm.ptr
        %192 = llvm.load %191 : !llvm.ptr -> i8
        %193 = llvm.mlir.constant(0 : i8) : i8
        %194 = llvm.icmp "ne" %192, %193 : i8
        scf.if %194 {
          %int_tuple_626 = cute.make_int_tuple() : () -> !cute.int_tuple<"12">
          %ptr_627 = cute.add_offset(%iter_592, %int_tuple_626) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<f32, rmem, align<16>>
          %c3_i64 = arith.constant 3 : i64
          %207 = arith.muli %142, %c3_i64 : i64
          %iv_628 = cute.assume(%207) : (i64) -> !cute.i64<divby 3>
          %int_tuple_629 = cute.make_int_tuple(%iv_628) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
          %ptr_630 = cute.add_offset(%iter_593, %int_tuple_629) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
          %208 = builtin.unrealized_conversion_cast %ptr_627 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
          %209 = builtin.unrealized_conversion_cast %ptr_630 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %210 = llvm.load %208 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %210, %209 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %int_tuple_620 = cute.make_int_tuple() : () -> !cute.int_tuple<"13">
        %ptr_621 = cute.add_offset(%iter_595, %int_tuple_620) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<i8, rmem>
        %195 = builtin.unrealized_conversion_cast %ptr_621 : !cute.ptr<i8, rmem> to !llvm.ptr
        %196 = llvm.load %195 : !llvm.ptr -> i8
        %197 = llvm.mlir.constant(0 : i8) : i8
        %198 = llvm.icmp "ne" %196, %197 : i8
        scf.if %198 {
          %int_tuple_626 = cute.make_int_tuple() : () -> !cute.int_tuple<"13">
          %ptr_627 = cute.add_offset(%iter_592, %int_tuple_626) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<f32, rmem>
          %c3_i64 = arith.constant 3 : i64
          %207 = arith.muli %142, %c3_i64 : i64
          %c1_i64 = arith.constant 1 : i64
          %208 = arith.addi %207, %c1_i64 : i64
          %int_tuple_628 = cute.make_int_tuple(%208) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_629 = cute.add_offset(%iter_593, %int_tuple_628) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %209 = builtin.unrealized_conversion_cast %ptr_627 : !cute.ptr<f32, rmem> to !llvm.ptr
          %210 = builtin.unrealized_conversion_cast %ptr_629 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %211 = llvm.load %209 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %211, %210 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %int_tuple_622 = cute.make_int_tuple() : () -> !cute.int_tuple<"14">
        %ptr_623 = cute.add_offset(%iter_595, %int_tuple_622) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<i8, rmem, align<2>>
        %199 = builtin.unrealized_conversion_cast %ptr_623 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
        %200 = llvm.load %199 : !llvm.ptr -> i8
        %201 = llvm.mlir.constant(0 : i8) : i8
        %202 = llvm.icmp "ne" %200, %201 : i8
        scf.if %202 {
          %int_tuple_626 = cute.make_int_tuple() : () -> !cute.int_tuple<"14">
          %ptr_627 = cute.add_offset(%iter_592, %int_tuple_626) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<f32, rmem, align<8>>
          %c3_i64 = arith.constant 3 : i64
          %207 = arith.muli %142, %c3_i64 : i64
          %c2_i64 = arith.constant 2 : i64
          %208 = arith.addi %207, %c2_i64 : i64
          %int_tuple_628 = cute.make_int_tuple(%208) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_629 = cute.add_offset(%iter_593, %int_tuple_628) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %209 = builtin.unrealized_conversion_cast %ptr_627 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %210 = builtin.unrealized_conversion_cast %ptr_629 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %211 = llvm.load %209 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %211, %210 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %int_tuple_624 = cute.make_int_tuple() : () -> !cute.int_tuple<"15">
        %ptr_625 = cute.add_offset(%iter_595, %int_tuple_624) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<i8, rmem>
        %203 = builtin.unrealized_conversion_cast %ptr_625 : !cute.ptr<i8, rmem> to !llvm.ptr
        %204 = llvm.load %203 : !llvm.ptr -> i8
        %205 = llvm.mlir.constant(0 : i8) : i8
        %206 = llvm.icmp "ne" %204, %205 : i8
        scf.if %206 {
          %int_tuple_626 = cute.make_int_tuple() : () -> !cute.int_tuple<"15">
          %ptr_627 = cute.add_offset(%iter_592, %int_tuple_626) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<f32, rmem>
          %c3_i64 = arith.constant 3 : i64
          %207 = arith.muli %142, %c3_i64 : i64
          %c3_i64_628 = arith.constant 3 : i64
          %208 = arith.addi %207, %c3_i64_628 : i64
          %iv_629 = cute.assume(%208) : (i64) -> !cute.i64<divby 3>
          %int_tuple_630 = cute.make_int_tuple(%iv_629) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
          %ptr_631 = cute.add_offset(%iter_593, %int_tuple_630) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
          %209 = builtin.unrealized_conversion_cast %ptr_627 : !cute.ptr<f32, rmem> to !llvm.ptr
          %210 = builtin.unrealized_conversion_cast %ptr_631 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %211 = llvm.load %209 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %211, %210 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
      } {llvm.loop_annotation = #loop_annotation}
      return
    }
  }
  func.func @cutlass_elementwise_add_tensor02841_02912_01912_08313_09196_09403_10126_01202_16746_01064_01796_23174_06047_09508_18613_09638_07238_13885_01225_14714_08045_25177_11321_05292_11895_(%arg0: !memref_gmem_f32_5, %arg1: !memref_gmem_f32_5, %arg2: !memref_gmem_f32_5) -> i32 attributes {llvm.emit_c_interface} {
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
    %16 = cute.get_shape(%lay_35) : (!cute.layout<"((32,4),(4,4)):((64,4),(16,1))">) -> !cute.shape<"((32,4),(4,4))">
    %e0_42, %e1_43, %e2_44, %e3_45 = cute.get_leaves(%16) : !cute.shape<"((32,4),(4,4))">
    %17 = cute.get_stride(%lay_35) : (!cute.layout<"((32,4),(4,4)):((64,4),(16,1))">) -> !cute.stride<"((64,4),(16,1))">
    %e0_46, %e1_47, %e2_48, %e3_49 = cute.get_leaves(%17) : !cute.stride<"((64,4),(16,1))">
    %tile = cute.make_tile() : () -> !cute.tile<"[16:1;128:1]">
    %iter_50 = cute.get_iter(%arg0) : !memref_gmem_f32_5
    %lay_51 = cute.get_layout(%arg0) : !memref_gmem_f32_5
    %18:3 = cute.get_scalars(%lay_51) <{only_dynamic}> : !cute.layout<"(?,?):(?{i64},1)">
    %c16_i32 = arith.constant 16 : i32
    %19 = arith.ceildivsi %18#0, %c16_i32 : i32
    %c16_i64 = arith.constant 16 : i64
    %20 = arith.muli %18#2, %c16_i64 : i64
    %c128_i32 = arith.constant 128 : i32
    %21 = arith.ceildivsi %18#1, %c128_i32 : i32
    %shape_52 = cute.make_shape(%19, %21) : (i32, i32) -> !cute.shape<"((16,128),(?,?))">
    %iv = cute.assume(%20) : (i64) -> !cute.i64<divby 16>
    %stride = cute.make_stride(%18#2, %iv) : (i64, !cute.i64<divby 16>) -> !cute.stride<"((?{i64},1),(?{i64 div=16},128))">
    %lay_53 = cute.make_layout(%shape_52, %stride) : !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
    %view = cute.make_view(%iter_50, %lay_53) : !memref_gmem_f32_
    %iter_54 = cute.get_iter(%view) : !memref_gmem_f32_
    %iter_55 = cute.get_iter(%view) : !memref_gmem_f32_
    %tile_56 = cute.make_tile() : () -> !cute.tile<"[16:1;128:1]">
    %iter_57 = cute.get_iter(%arg1) : !memref_gmem_f32_5
    %lay_58 = cute.get_layout(%arg1) : !memref_gmem_f32_5
    %22:3 = cute.get_scalars(%lay_58) <{only_dynamic}> : !cute.layout<"(?,?):(?{i64},1)">
    %c16_i32_59 = arith.constant 16 : i32
    %23 = arith.ceildivsi %22#0, %c16_i32_59 : i32
    %c16_i64_60 = arith.constant 16 : i64
    %24 = arith.muli %22#2, %c16_i64_60 : i64
    %c128_i32_61 = arith.constant 128 : i32
    %25 = arith.ceildivsi %22#1, %c128_i32_61 : i32
    %shape_62 = cute.make_shape(%23, %25) : (i32, i32) -> !cute.shape<"((16,128),(?,?))">
    %iv_63 = cute.assume(%24) : (i64) -> !cute.i64<divby 16>
    %stride_64 = cute.make_stride(%22#2, %iv_63) : (i64, !cute.i64<divby 16>) -> !cute.stride<"((?{i64},1),(?{i64 div=16},128))">
    %lay_65 = cute.make_layout(%shape_62, %stride_64) : !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
    %view_66 = cute.make_view(%iter_57, %lay_65) : !memref_gmem_f32_
    %iter_67 = cute.get_iter(%view_66) : !memref_gmem_f32_
    %iter_68 = cute.get_iter(%view_66) : !memref_gmem_f32_
    %tile_69 = cute.make_tile() : () -> !cute.tile<"[16:1;128:1]">
    %iter_70 = cute.get_iter(%arg2) : !memref_gmem_f32_5
    %lay_71 = cute.get_layout(%arg2) : !memref_gmem_f32_5
    %26:3 = cute.get_scalars(%lay_71) <{only_dynamic}> : !cute.layout<"(?,?):(?{i64},1)">
    %c16_i32_72 = arith.constant 16 : i32
    %27 = arith.ceildivsi %26#0, %c16_i32_72 : i32
    %c16_i64_73 = arith.constant 16 : i64
    %28 = arith.muli %26#2, %c16_i64_73 : i64
    %c128_i32_74 = arith.constant 128 : i32
    %29 = arith.ceildivsi %26#1, %c128_i32_74 : i32
    %shape_75 = cute.make_shape(%27, %29) : (i32, i32) -> !cute.shape<"((16,128),(?,?))">
    %iv_76 = cute.assume(%28) : (i64) -> !cute.i64<divby 16>
    %stride_77 = cute.make_stride(%26#2, %iv_76) : (i64, !cute.i64<divby 16>) -> !cute.stride<"((?{i64},1),(?{i64 div=16},128))">
    %lay_78 = cute.make_layout(%shape_75, %stride_77) : !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
    %view_79 = cute.make_view(%iter_70, %lay_78) : !memref_gmem_f32_
    %iter_80 = cute.get_iter(%view_79) : !memref_gmem_f32_
    %iter_81 = cute.get_iter(%view_79) : !memref_gmem_f32_
    %lay_82 = cute.get_layout(%arg2) : !memref_gmem_f32_5
    %30 = cute.get_shape(%lay_82) : (!cute.layout<"(?,?):(?{i64},1)">) -> !cute.shape<"(?,?)">
    %e0_83, %e1_84 = cute.get_leaves(%30) : !cute.shape<"(?,?)">
    %itup_85 = cute.to_int_tuple(%e0_83) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %31 = cute.get_scalars(%itup_85) : !cute.int_tuple<"?">
    %itup_86 = cute.to_int_tuple(%e1_84) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %32 = cute.get_scalars(%itup_86) : !cute.int_tuple<"?">
    %shape_87 = cute.make_shape(%itup_85, %itup_86) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.shape<"(?,?)">
    %int_tuple_88 = cute.make_int_tuple() : () -> !cute.int_tuple<"(0,0)">
    %stride_89 = cute.make_stride() : () -> !cute.stride<"(1@0,1@1)">
    %lay_90 = cute.make_layout(%shape_87, %stride_89) : !cute.layout<"(?,?):(1@0,1@1)">
    %view_91 = cute.make_view(%int_tuple_88, %lay_90) : !cute.coord_tensor<"(0,0)", "(?,?):(1@0,1@1)">
    %iter_92 = cute.get_iter(%view_91) : !cute.coord_tensor<"(0,0)", "(?,?):(1@0,1@1)">
    %e0_93, %e1_94 = cute.get_leaves(%iter_92) : !cute.int_tuple<"(0,0)">
    %tile_95 = cute.make_tile() : () -> !cute.tile<"[16:1;128:1]">
    %iter_96 = cute.get_iter(%view_91) : !cute.coord_tensor<"(0,0)", "(?,?):(1@0,1@1)">
    %lay_97 = cute.get_layout(%view_91) : !cute.coord_tensor<"(0,0)", "(?,?):(1@0,1@1)">
    %33:2 = cute.get_scalars(%lay_97) <{only_dynamic}> : !cute.layout<"(?,?):(1@0,1@1)">
    %c16_i32_98 = arith.constant 16 : i32
    %34 = arith.ceildivsi %33#0, %c16_i32_98 : i32
    %c128_i32_99 = arith.constant 128 : i32
    %35 = arith.ceildivsi %33#1, %c128_i32_99 : i32
    %shape_100 = cute.make_shape(%34, %35) : (i32, i32) -> !cute.shape<"((16,128),(?,?))">
    %stride_101 = cute.make_stride() : () -> !cute.stride<"((1@0,1@1),(16@0,128@1))">
    %lay_102 = cute.make_layout(%shape_100, %stride_101) : !cute.layout<"((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
    %view_103 = cute.make_view(%iter_96, %lay_102) : !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
    %iter_104 = cute.get_iter(%view_103) : !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
    %e0_105, %e1_106 = cute.get_leaves(%iter_104) : !cute.int_tuple<"(0,0)">
    %iter_107 = cute.get_iter(%view_103) : !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
    %e0_108, %e1_109 = cute.get_leaves(%iter_107) : !cute.int_tuple<"(0,0)">
    %lay_110 = cute.get_layout(%view_79) : !memref_gmem_f32_
    %sz_111 = cute.size(%lay_110) <{mode = [1]}> : (!cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.int_tuple<"?">
    %e0_112 = cute.get_leaves(%sz_111) : !cute.int_tuple<"?">
    %36 = cute.get_scalars(%e0_112) : !cute.int_tuple<"?">
    %sz_113 = cute.size(%lay_35) <{mode = [0]}> : (!cute.layout<"((32,4),(4,4)):((64,4),(16,1))">) -> !cute.int_tuple<"128">
    %e0_114 = cute.get_leaves(%sz_113) : !cute.int_tuple<"128">
    %lay_115 = cute.get_layout(%view) : !memref_gmem_f32_
    %37 = cute.get_shape(%lay_115) : (!cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.shape<"((16,128),(?,?))">
    %e0_116, %e1_117, %e2_118, %e3_119 = cute.get_leaves(%37) : !cute.shape<"((16,128),(?,?))">
    %itup_120 = cute.to_int_tuple(%e2_118) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %38 = cute.get_scalars(%itup_120) : !cute.int_tuple<"?">
    %itup_121 = cute.to_int_tuple(%e3_119) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %39 = cute.get_scalars(%itup_121) : !cute.int_tuple<"?">
    %40 = cute.get_stride(%lay_115) : (!cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.stride<"((?{i64},1),(?{i64 div=16},128))">
    %e0_122, %e1_123, %e2_124, %e3_125 = cute.get_leaves(%40) : !cute.stride<"((?{i64},1),(?{i64 div=16},128))">
    %itup_126 = cute.to_int_tuple(%e0_122) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
    %41 = cute.get_scalars(%itup_126) : !cute.int_tuple<"?{i64}">
    %itup_127 = cute.to_int_tuple(%e2_124) : !cute.stride<"?{i64 div=16}"> to !cute.int_tuple<"?{i64 div=16}">
    %42 = cute.get_scalars(%itup_127) : !cute.int_tuple<"?{i64 div=16}">
    %lay_128 = cute.get_layout(%view_66) : !memref_gmem_f32_
    %43 = cute.get_shape(%lay_128) : (!cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.shape<"((16,128),(?,?))">
    %e0_129, %e1_130, %e2_131, %e3_132 = cute.get_leaves(%43) : !cute.shape<"((16,128),(?,?))">
    %itup_133 = cute.to_int_tuple(%e2_131) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %44 = cute.get_scalars(%itup_133) : !cute.int_tuple<"?">
    %itup_134 = cute.to_int_tuple(%e3_132) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %45 = cute.get_scalars(%itup_134) : !cute.int_tuple<"?">
    %46 = cute.get_stride(%lay_128) : (!cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.stride<"((?{i64},1),(?{i64 div=16},128))">
    %e0_135, %e1_136, %e2_137, %e3_138 = cute.get_leaves(%46) : !cute.stride<"((?{i64},1),(?{i64 div=16},128))">
    %itup_139 = cute.to_int_tuple(%e0_135) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
    %47 = cute.get_scalars(%itup_139) : !cute.int_tuple<"?{i64}">
    %itup_140 = cute.to_int_tuple(%e2_137) : !cute.stride<"?{i64 div=16}"> to !cute.int_tuple<"?{i64 div=16}">
    %48 = cute.get_scalars(%itup_140) : !cute.int_tuple<"?{i64 div=16}">
    %lay_141 = cute.get_layout(%view_79) : !memref_gmem_f32_
    %49 = cute.get_shape(%lay_141) : (!cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.shape<"((16,128),(?,?))">
    %e0_142, %e1_143, %e2_144, %e3_145 = cute.get_leaves(%49) : !cute.shape<"((16,128),(?,?))">
    %itup_146 = cute.to_int_tuple(%e2_144) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %50 = cute.get_scalars(%itup_146) : !cute.int_tuple<"?">
    %itup_147 = cute.to_int_tuple(%e3_145) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %51 = cute.get_scalars(%itup_147) : !cute.int_tuple<"?">
    %52 = cute.get_stride(%lay_141) : (!cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.stride<"((?{i64},1),(?{i64 div=16},128))">
    %e0_148, %e1_149, %e2_150, %e3_151 = cute.get_leaves(%52) : !cute.stride<"((?{i64},1),(?{i64 div=16},128))">
    %itup_152 = cute.to_int_tuple(%e0_148) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
    %53 = cute.get_scalars(%itup_152) : !cute.int_tuple<"?{i64}">
    %itup_153 = cute.to_int_tuple(%e2_150) : !cute.stride<"?{i64 div=16}"> to !cute.int_tuple<"?{i64 div=16}">
    %54 = cute.get_scalars(%itup_153) : !cute.int_tuple<"?{i64 div=16}">
    %lay_154 = cute.get_layout(%view_103) : !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
    %55 = cute.get_shape(%lay_154) : (!cute.layout<"((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">) -> !cute.shape<"((16,128),(?,?))">
    %e0_155, %e1_156, %e2_157, %e3_158 = cute.get_leaves(%55) : !cute.shape<"((16,128),(?,?))">
    %itup_159 = cute.to_int_tuple(%e2_157) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %56 = cute.get_scalars(%itup_159) : !cute.int_tuple<"?">
    %itup_160 = cute.to_int_tuple(%e3_158) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %57 = cute.get_scalars(%itup_160) : !cute.int_tuple<"?">
    %58 = cute.get_stride(%lay_154) : (!cute.layout<"((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">) -> !cute.stride<"((1@0,1@1),(16@0,128@1))">
    %e0_161, %e1_162, %e2_163, %e3_164 = cute.get_leaves(%58) : !cute.stride<"((1@0,1@1),(16@0,128@1))">
    %59 = cute.get_shape(%lay_25) : (!cute.layout<"(4,32):(32,1)">) -> !cute.shape<"(4,32)">
    %e0_165, %e1_166 = cute.get_leaves(%59) : !cute.shape<"(4,32)">
    %60 = cute.get_stride(%lay_25) : (!cute.layout<"(4,32):(32,1)">) -> !cute.stride<"(32,1)">
    %e0_167, %e1_168 = cute.get_leaves(%60) : !cute.stride<"(32,1)">
    %61 = cute.get_shape(%lay_28) : (!cute.layout<"(4,4):(4,1)">) -> !cute.shape<"(4,4)">
    %e0_169, %e1_170 = cute.get_leaves(%61) : !cute.shape<"(4,4)">
    %62 = cute.get_stride(%lay_28) : (!cute.layout<"(4,4):(4,1)">) -> !cute.stride<"(4,1)">
    %e0_171, %e1_172 = cute.get_leaves(%62) : !cute.stride<"(4,1)">
    %c0_i32 = arith.constant 0 : i32
    %c0_i64 = arith.constant 0 : i64
    %63 = cuda.cast %c0_i64 : i64 -> !cuda.stream
    %64 = arith.extsi %c0_i32 : i32 to i64
    %c128_i32_173 = arith.constant 128 : i32
    %c1_i32 = arith.constant 1 : i32
    %65 = cuda.launch_cfg.create<max_attrs = 2 : i32> (blockDim = (%c128_i32_173, %c1_i32, %c1_i32), dynamicSmemBytes = %64, gridDim = (%36, %c1_i32, %c1_i32), stream = %63) : i32, i32, i32, i64, i32, i32, i32, !cuda.stream -> !cuda.launch_cfg<max_attrs = 2>
    %66 = cuda.launch_ex @kernels::@kernel_cutlass_elementwise_add_kernel_tensorptrf32gmemo161281i64div16128_tensorptrf32gmemo161281i64div16128_tensorptrf32gmemo161281i64div16128_tensor00o1612810111601281___0<%65> (%view, %view_66, %view_79, %view_103, %31, %32) : !cuda.launch_cfg<max_attrs = 2>, (!memref_gmem_f32_, !memref_gmem_f32_, !memref_gmem_f32_, !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">, i32, i32) -> !cuda.result
    %67 = cuda.cast %66 : !cuda.result -> i32
    cuda.return_if_error %67 : i32
    %c0_i32_174 = arith.constant 0 : i32
    return %c0_i32_174 : i32
  }
}
