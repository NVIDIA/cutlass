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
      %coord_67 = cute.make_coord(%31) : (i32) -> !cute.coord<"((_,_),?)">
      %lay_68 = cute.get_layout(%arg1) : !memref_gmem_f32_
      %36:4 = cute.get_scalars(%lay_68) <{only_dynamic}> : !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
      %37 = cute.get_scalars(%coord_67) <{only_dynamic}> : !cute.coord<"((_,_),?)">
      %shape_69 = cute.make_shape() : () -> !cute.shape<"(16,128)">
      %stride_70 = cute.make_stride(%36#2) : (i64) -> !cute.stride<"(?{i64},1)">
      %lay_71 = cute.make_layout(%shape_69, %stride_70) : !cute.layout<"(16,128):(?{i64},1)">
      %idx_72 = cute.crd2idx(%coord_67, %lay_68) : (!cute.coord<"((_,_),?)">, !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.int_tuple<"?{i64 div=16}">
      %iter_73 = cute.get_iter(%arg1) : !memref_gmem_f32_
      %ptr_74 = cute.add_offset(%iter_73, %idx_72) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=16}">) -> !cute.ptr<f32, gmem>
      %view_75 = cute.make_view(%ptr_74, %lay_71) : !memref_gmem_f32_1
      %iter_76 = cute.get_iter(%view_75) : !memref_gmem_f32_1
      %coord_77 = cute.make_coord(%31) : (i32) -> !cute.coord<"((_,_),?)">
      %lay_78 = cute.get_layout(%arg2) : !memref_gmem_f32_
      %38:4 = cute.get_scalars(%lay_78) <{only_dynamic}> : !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
      %39 = cute.get_scalars(%coord_77) <{only_dynamic}> : !cute.coord<"((_,_),?)">
      %shape_79 = cute.make_shape() : () -> !cute.shape<"(16,128)">
      %stride_80 = cute.make_stride(%38#2) : (i64) -> !cute.stride<"(?{i64},1)">
      %lay_81 = cute.make_layout(%shape_79, %stride_80) : !cute.layout<"(16,128):(?{i64},1)">
      %idx_82 = cute.crd2idx(%coord_77, %lay_78) : (!cute.coord<"((_,_),?)">, !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.int_tuple<"?{i64 div=16}">
      %iter_83 = cute.get_iter(%arg2) : !memref_gmem_f32_
      %ptr_84 = cute.add_offset(%iter_83, %idx_82) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=16}">) -> !cute.ptr<f32, gmem>
      %view_85 = cute.make_view(%ptr_84, %lay_81) : !memref_gmem_f32_1
      %iter_86 = cute.get_iter(%view_85) : !memref_gmem_f32_1
      %coord_87 = cute.make_coord(%31) : (i32) -> !cute.coord<"((_,_),?)">
      %lay_88 = cute.get_layout(%arg3) : !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
      %idx_89 = cute.crd2idx(%coord_87, %lay_88) : (!cute.coord<"((_,_),?)">, !cute.layout<"((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">) -> !cute.int_tuple<"(?{div=16},?{div=128})">
      %iter_90 = cute.get_iter(%arg3) : !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
      %tup = cute.add_offset(%iter_90, %idx_89) : (!cute.int_tuple<"(0,0)">, !cute.int_tuple<"(?{div=16},?{div=128})">) -> !cute.int_tuple<"(?{div=16},?{div=128})">
      %view_91 = cute.make_view(%tup) : !cute.coord_tensor<"(?{div=16},?{div=128})", "(16,128):(1@0,1@1)">
      %iter_92 = cute.get_iter(%view_91) : !cute.coord_tensor<"(?{div=16},?{div=128})", "(16,128):(1@0,1@1)">
      %e0_93, %e1_94 = cute.get_leaves(%iter_92) : !cute.int_tuple<"(?{div=16},?{div=128})">
      %40 = cute.get_scalars(%e0_93) : !cute.int_tuple<"?{div=16}">
      %41 = cute.get_scalars(%e1_94) : !cute.int_tuple<"?{div=128}">
      %atom = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<f32>
      %atom_95 = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<f32>
      %lay_96 = cute.make_layout() : !cute.layout<"((4,4),(4,32)):((512,32),(128,1))">
      %sz = cute.size(%0) : (!cute.layout<"(4,32):(32,1)">) -> !cute.int_tuple<"128">
      %e0_97 = cute.get_leaves(%sz) : !cute.int_tuple<"128">
      %sz_98 = cute.size(%1) : (!cute.layout<"(4,4):(4,1)">) -> !cute.int_tuple<"16">
      %e0_99 = cute.get_leaves(%sz_98) : !cute.int_tuple<"16">
      %shape_100 = cute.make_shape() : () -> !cute.shape<"(128,16)">
      %lay_101 = cute.make_layout() : !cute.layout<"(128,16):(1,128)">
      %rinv = cute.right_inverse(%lay_96) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.layout<"(32,16,4):(64,4,1)">
      %lay_102 = cute.make_layout() : !cute.layout<"((32,4),(4,4)):((64,4),(16,1))">
      %42 = cute.get_shape(%lay_96) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.shape<"((4,4),(4,32))">
      %e0_103, %e1_104, %e2_105, %e3_106 = cute.get_leaves(%42) : !cute.shape<"((4,4),(4,32))">
      %int_tuple = cute.make_int_tuple() : () -> !cute.int_tuple<"((4,4),(4,32))">
      %int_tuple_107 = cute.make_int_tuple() : () -> !cute.int_tuple<"(16,128)">
      %e0_108, %e1_109 = cute.get_leaves(%int_tuple_107) : !cute.int_tuple<"(16,128)">
      %int_tuple_110 = cute.make_int_tuple() : () -> !cute.int_tuple<"(16,128)">
      %int_tuple_111 = cute.make_int_tuple() : () -> !cute.int_tuple<"(16,128)">
      %e0_112, %e1_113 = cute.get_leaves(%int_tuple_111) : !cute.int_tuple<"(16,128)">
      %tile = cute.make_tile() : () -> !cute.tile<"[16:1;128:1]">
      %43 = cute.make_tiled_copy(%atom) : !copy_simt
      %lay_114 = cute.make_layout() : !cute.layout<"((4,4),(4,32)):((512,32),(128,1))">
      %sz_115 = cute.size(%0) : (!cute.layout<"(4,32):(32,1)">) -> !cute.int_tuple<"128">
      %e0_116 = cute.get_leaves(%sz_115) : !cute.int_tuple<"128">
      %sz_117 = cute.size(%1) : (!cute.layout<"(4,4):(4,1)">) -> !cute.int_tuple<"16">
      %e0_118 = cute.get_leaves(%sz_117) : !cute.int_tuple<"16">
      %shape_119 = cute.make_shape() : () -> !cute.shape<"(128,16)">
      %lay_120 = cute.make_layout() : !cute.layout<"(128,16):(1,128)">
      %rinv_121 = cute.right_inverse(%lay_114) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.layout<"(32,16,4):(64,4,1)">
      %lay_122 = cute.make_layout() : !cute.layout<"((32,4),(4,4)):((64,4),(16,1))">
      %44 = cute.get_shape(%lay_114) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.shape<"((4,4),(4,32))">
      %e0_123, %e1_124, %e2_125, %e3_126 = cute.get_leaves(%44) : !cute.shape<"((4,4),(4,32))">
      %int_tuple_127 = cute.make_int_tuple() : () -> !cute.int_tuple<"((4,4),(4,32))">
      %int_tuple_128 = cute.make_int_tuple() : () -> !cute.int_tuple<"(16,128)">
      %e0_129, %e1_130 = cute.get_leaves(%int_tuple_128) : !cute.int_tuple<"(16,128)">
      %int_tuple_131 = cute.make_int_tuple() : () -> !cute.int_tuple<"(16,128)">
      %int_tuple_132 = cute.make_int_tuple() : () -> !cute.int_tuple<"(16,128)">
      %e0_133, %e1_134 = cute.get_leaves(%int_tuple_132) : !cute.int_tuple<"(16,128)">
      %tile_135 = cute.make_tile() : () -> !cute.tile<"[16:1;128:1]">
      %45 = cute.make_tiled_copy(%atom) : !copy_simt
      %lay_136 = cute.make_layout() : !cute.layout<"((4,4),(4,32)):((512,32),(128,1))">
      %sz_137 = cute.size(%0) : (!cute.layout<"(4,32):(32,1)">) -> !cute.int_tuple<"128">
      %e0_138 = cute.get_leaves(%sz_137) : !cute.int_tuple<"128">
      %sz_139 = cute.size(%1) : (!cute.layout<"(4,4):(4,1)">) -> !cute.int_tuple<"16">
      %e0_140 = cute.get_leaves(%sz_139) : !cute.int_tuple<"16">
      %shape_141 = cute.make_shape() : () -> !cute.shape<"(128,16)">
      %lay_142 = cute.make_layout() : !cute.layout<"(128,16):(1,128)">
      %rinv_143 = cute.right_inverse(%lay_136) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.layout<"(32,16,4):(64,4,1)">
      %lay_144 = cute.make_layout() : !cute.layout<"((32,4),(4,4)):((64,4),(16,1))">
      %46 = cute.get_shape(%lay_136) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.shape<"((4,4),(4,32))">
      %e0_145, %e1_146, %e2_147, %e3_148 = cute.get_leaves(%46) : !cute.shape<"((4,4),(4,32))">
      %int_tuple_149 = cute.make_int_tuple() : () -> !cute.int_tuple<"((4,4),(4,32))">
      %int_tuple_150 = cute.make_int_tuple() : () -> !cute.int_tuple<"(16,128)">
      %e0_151, %e1_152 = cute.get_leaves(%int_tuple_150) : !cute.int_tuple<"(16,128)">
      %int_tuple_153 = cute.make_int_tuple() : () -> !cute.int_tuple<"(16,128)">
      %int_tuple_154 = cute.make_int_tuple() : () -> !cute.int_tuple<"(16,128)">
      %e0_155, %e1_156 = cute.get_leaves(%int_tuple_154) : !cute.int_tuple<"(16,128)">
      %tile_157 = cute.make_tile() : () -> !cute.tile<"[16:1;128:1]">
      %47 = cute.make_tiled_copy(%atom_95) : !copy_simt
      %coord_158 = cute.make_coord(%28) : (i32) -> !cute.coord<"?">
      %iter_159 = cute.get_iter(%view) : !memref_gmem_f32_1
      %lay_160 = cute.get_layout(%view) : !memref_gmem_f32_1
      %48 = cute.get_scalars(%lay_160) <{only_dynamic}> : !cute.layout<"(16,128):(?{i64},1)">
      %49 = cute.get_scalars(%coord_158) <{only_dynamic}> : !cute.coord<"?">
      %c64_i64 = arith.constant 64 : i64
      %50 = arith.muli %48, %c64_i64 : i64
      %c4_i64 = arith.constant 4 : i64
      %51 = arith.muli %48, %c4_i64 : i64
      %c16_i64 = arith.constant 16 : i64
      %52 = arith.muli %48, %c16_i64 : i64
      %c32_i32 = arith.constant 32 : i32
      %53 = arith.divsi %49, %c32_i32 : i32
      %c32_i32_161 = arith.constant 32 : i32
      %54 = arith.remsi %49, %c32_i32_161 : i32
      %c4_i32 = arith.constant 4 : i32
      %55 = arith.muli %54, %c4_i32 : i32
      %56 = arith.extsi %53 : i32 to i64
      %57 = arith.muli %56, %51 : i64
      %58 = arith.extsi %55 : i32 to i64
      %59 = arith.addi %58, %57 : i64
      %iv = cute.assume(%59) : (i64) -> !cute.i64<divby 4>
      %int_tuple_162 = cute.make_int_tuple(%iv) : (!cute.i64<divby 4>) -> !cute.int_tuple<"?{i64 div=4}">
      %ptr_163 = cute.add_offset(%iter_159, %int_tuple_162) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=4}">) -> !cute.ptr<f32, gmem>
      %shape_164 = cute.make_shape() : () -> !cute.shape<"((1,(4,4)),1,1)">
      %stride_165 = cute.make_stride(%48) : (i64) -> !cute.stride<"((0,(1,?{i64})),0,0)">
      %lay_166 = cute.make_layout(%shape_164, %stride_165) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %view_167 = cute.make_view(%ptr_163, %lay_166) : !memref_gmem_f32_2
      %iter_168 = cute.get_iter(%view_167) : !memref_gmem_f32_2
      %coord_169 = cute.make_coord(%28) : (i32) -> !cute.coord<"?">
      %iter_170 = cute.get_iter(%view_75) : !memref_gmem_f32_1
      %lay_171 = cute.get_layout(%view_75) : !memref_gmem_f32_1
      %60 = cute.get_scalars(%lay_171) <{only_dynamic}> : !cute.layout<"(16,128):(?{i64},1)">
      %61 = cute.get_scalars(%coord_169) <{only_dynamic}> : !cute.coord<"?">
      %c64_i64_172 = arith.constant 64 : i64
      %62 = arith.muli %60, %c64_i64_172 : i64
      %c4_i64_173 = arith.constant 4 : i64
      %63 = arith.muli %60, %c4_i64_173 : i64
      %c16_i64_174 = arith.constant 16 : i64
      %64 = arith.muli %60, %c16_i64_174 : i64
      %c32_i32_175 = arith.constant 32 : i32
      %65 = arith.divsi %61, %c32_i32_175 : i32
      %c32_i32_176 = arith.constant 32 : i32
      %66 = arith.remsi %61, %c32_i32_176 : i32
      %c4_i32_177 = arith.constant 4 : i32
      %67 = arith.muli %66, %c4_i32_177 : i32
      %68 = arith.extsi %65 : i32 to i64
      %69 = arith.muli %68, %63 : i64
      %70 = arith.extsi %67 : i32 to i64
      %71 = arith.addi %70, %69 : i64
      %iv_178 = cute.assume(%71) : (i64) -> !cute.i64<divby 4>
      %int_tuple_179 = cute.make_int_tuple(%iv_178) : (!cute.i64<divby 4>) -> !cute.int_tuple<"?{i64 div=4}">
      %ptr_180 = cute.add_offset(%iter_170, %int_tuple_179) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=4}">) -> !cute.ptr<f32, gmem>
      %shape_181 = cute.make_shape() : () -> !cute.shape<"((1,(4,4)),1,1)">
      %stride_182 = cute.make_stride(%60) : (i64) -> !cute.stride<"((0,(1,?{i64})),0,0)">
      %lay_183 = cute.make_layout(%shape_181, %stride_182) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %view_184 = cute.make_view(%ptr_180, %lay_183) : !memref_gmem_f32_2
      %iter_185 = cute.get_iter(%view_184) : !memref_gmem_f32_2
      %coord_186 = cute.make_coord(%28) : (i32) -> !cute.coord<"?">
      %iter_187 = cute.get_iter(%view_85) : !memref_gmem_f32_1
      %lay_188 = cute.get_layout(%view_85) : !memref_gmem_f32_1
      %72 = cute.get_scalars(%lay_188) <{only_dynamic}> : !cute.layout<"(16,128):(?{i64},1)">
      %73 = cute.get_scalars(%coord_186) <{only_dynamic}> : !cute.coord<"?">
      %c64_i64_189 = arith.constant 64 : i64
      %74 = arith.muli %72, %c64_i64_189 : i64
      %c4_i64_190 = arith.constant 4 : i64
      %75 = arith.muli %72, %c4_i64_190 : i64
      %c16_i64_191 = arith.constant 16 : i64
      %76 = arith.muli %72, %c16_i64_191 : i64
      %c32_i32_192 = arith.constant 32 : i32
      %77 = arith.divsi %73, %c32_i32_192 : i32
      %c32_i32_193 = arith.constant 32 : i32
      %78 = arith.remsi %73, %c32_i32_193 : i32
      %c4_i32_194 = arith.constant 4 : i32
      %79 = arith.muli %78, %c4_i32_194 : i32
      %80 = arith.extsi %77 : i32 to i64
      %81 = arith.muli %80, %75 : i64
      %82 = arith.extsi %79 : i32 to i64
      %83 = arith.addi %82, %81 : i64
      %iv_195 = cute.assume(%83) : (i64) -> !cute.i64<divby 4>
      %int_tuple_196 = cute.make_int_tuple(%iv_195) : (!cute.i64<divby 4>) -> !cute.int_tuple<"?{i64 div=4}">
      %ptr_197 = cute.add_offset(%iter_187, %int_tuple_196) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=4}">) -> !cute.ptr<f32, gmem>
      %shape_198 = cute.make_shape() : () -> !cute.shape<"((1,(4,4)),1,1)">
      %stride_199 = cute.make_stride(%72) : (i64) -> !cute.stride<"((0,(1,?{i64})),0,0)">
      %lay_200 = cute.make_layout(%shape_198, %stride_199) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %view_201 = cute.make_view(%ptr_197, %lay_200) : !memref_gmem_f32_2
      %iter_202 = cute.get_iter(%view_201) : !memref_gmem_f32_2
      %lay_203 = cute.get_layout(%view_167) : !memref_gmem_f32_2
      %84 = cute.get_scalars(%lay_203) <{only_dynamic}> : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %lay_204 = cute.make_layout() : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %rmem = cute.memref.alloca(%lay_204) : !memref_rmem_f32_
      %iter_205 = cute.get_iter(%rmem) : !memref_rmem_f32_
      %iter_206 = cute.get_iter(%rmem) : !memref_rmem_f32_
      %lay_207 = cute.get_layout(%view_184) : !memref_gmem_f32_2
      %85 = cute.get_scalars(%lay_207) <{only_dynamic}> : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %lay_208 = cute.make_layout() : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %rmem_209 = cute.memref.alloca(%lay_208) : !memref_rmem_f32_
      %iter_210 = cute.get_iter(%rmem_209) : !memref_rmem_f32_
      %iter_211 = cute.get_iter(%rmem_209) : !memref_rmem_f32_
      %lay_212 = cute.get_layout(%view_201) : !memref_gmem_f32_2
      %86 = cute.get_scalars(%lay_212) <{only_dynamic}> : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %lay_213 = cute.make_layout() : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %rmem_214 = cute.memref.alloca(%lay_213) : !memref_rmem_f32_
      %iter_215 = cute.get_iter(%rmem_214) : !memref_rmem_f32_
      %iter_216 = cute.get_iter(%rmem_214) : !memref_rmem_f32_
      %coord_217 = cute.make_coord(%28) : (i32) -> !cute.coord<"?">
      %iter_218 = cute.get_iter(%view_91) : !cute.coord_tensor<"(?{div=16},?{div=128})", "(16,128):(1@0,1@1)">
      %87 = cute.get_scalars(%coord_217) <{only_dynamic}> : !cute.coord<"?">
      %c32_i32_219 = arith.constant 32 : i32
      %88 = arith.divsi %87, %c32_i32_219 : i32
      %c32_i32_220 = arith.constant 32 : i32
      %89 = arith.remsi %87, %c32_i32_220 : i32
      %c4_i32_221 = arith.constant 4 : i32
      %90 = arith.muli %89, %c4_i32_221 : i32
      %c4_i32_222 = arith.constant 4 : i32
      %91 = arith.muli %88, %c4_i32_222 : i32
      %iv_223 = cute.assume(%91) : (i32) -> !cute.i32<divby 4>
      %iv_224 = cute.assume(%90) : (i32) -> !cute.i32<divby 4>
      %int_tuple_225 = cute.make_int_tuple(%iv_223, %iv_224) : (!cute.i32<divby 4>, !cute.i32<divby 4>) -> !cute.int_tuple<"(?{div=4},?{div=4})">
      %tup_226 = cute.add_offset(%iter_218, %int_tuple_225) : (!cute.int_tuple<"(?{div=16},?{div=128})">, !cute.int_tuple<"(?{div=4},?{div=4})">) -> !cute.int_tuple<"(?{div=4},?{div=4})">
      %view_227 = cute.make_view(%tup_226) : !cute.coord_tensor<"(?{div=4},?{div=4})", "((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">
      %iter_228 = cute.get_iter(%view_227) : !cute.coord_tensor<"(?{div=4},?{div=4})", "((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">
      %e0_229, %e1_230 = cute.get_leaves(%iter_228) : !cute.int_tuple<"(?{div=4},?{div=4})">
      %92 = cute.get_scalars(%e0_229) : !cute.int_tuple<"?{div=4}">
      %93 = cute.get_scalars(%e1_230) : !cute.int_tuple<"?{div=4}">
      %lay_231 = cute.get_layout(%view_227) : !cute.coord_tensor<"(?{div=4},?{div=4})", "((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">
      %94 = cute.get_shape(%lay_231) : (!cute.layout<"((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_232, %e1_233, %e2_234, %e3_235, %e4 = cute.get_leaves(%94) : !cute.shape<"((1,(4,4)),1,1)">
      %shape_236 = cute.make_shape() : () -> !cute.shape<"((1,(4,4)),1,1)">
      %lay_237 = cute.make_layout() : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %rmem_238 = cute.memref.alloca(%lay_237) : !memref_rmem_i8_
      %iter_239 = cute.get_iter(%rmem_238) : !memref_rmem_i8_
      %iter_240 = cute.get_iter(%rmem_238) : !memref_rmem_i8_
      %lay_241 = cute.get_layout(%rmem_238) : !memref_rmem_i8_
      %sz_242 = cute.size(%lay_241) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.int_tuple<"16">
      %e0_243 = cute.get_leaves(%sz_242) : !cute.int_tuple<"16">
      %lay_244 = cute.get_layout(%rmem_238) : !memref_rmem_i8_
      %95 = cute.get_shape(%lay_244) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_245, %e1_246, %e2_247, %e3_248, %e4_249 = cute.get_leaves(%95) : !cute.shape<"((1,(4,4)),1,1)">
      %96 = cute.get_stride(%lay_244) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.stride<"((0,(1,4)),0,0)">
      %e0_250, %e1_251, %e2_252, %e3_253, %e4_254 = cute.get_leaves(%96) : !cute.stride<"((0,(1,4)),0,0)">
      %c0_i32 = arith.constant 0 : i32
      %c16_i32 = arith.constant 16 : i32
      %c1_i32 = arith.constant 1 : i32
      %97 = scf.for %arg6 = %c0_i32 to %c16_i32 step %c1_i32 iter_args(%arg7 = %rmem_238) -> (!memref_rmem_i8_)  : i32 {
        %iter_571 = cute.get_iter(%arg7) : !memref_rmem_i8_
        %lay_572 = cute.get_layout(%arg7) : !memref_rmem_i8_
        %136 = cute.get_shape(%lay_572) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
        %e0_573, %e1_574, %e2_575, %e3_576, %e4_577 = cute.get_leaves(%136) : !cute.shape<"((1,(4,4)),1,1)">
        %137 = cute.get_stride(%lay_572) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.stride<"((0,(1,4)),0,0)">
        %e0_578, %e1_579, %e2_580, %e3_581, %e4_582 = cute.get_leaves(%137) : !cute.stride<"((0,(1,4)),0,0)">
        %iter_583 = cute.get_iter(%arg7) : !memref_rmem_i8_
        %coord_584 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"?">
        %lay_585 = cute.get_layout(%view_227) : !cute.coord_tensor<"(?{div=4},?{div=4})", "((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">
        %idx_586 = cute.crd2idx(%coord_584, %lay_585) : (!cute.coord<"?">, !cute.layout<"((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">) -> !cute.int_tuple<"(?,?)">
        %iter_587 = cute.get_iter(%view_227) : !cute.coord_tensor<"(?{div=4},?{div=4})", "((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">
        %tup_588 = cute.add_offset(%iter_587, %idx_586) : (!cute.int_tuple<"(?{div=4},?{div=4})">, !cute.int_tuple<"(?,?)">) -> !cute.int_tuple<"(?,?)">
        %view_589 = cute.make_view(%tup_588) : !cute.coord_tensor<"(?,?)", "():()">
        %iter_590 = cute.get_iter(%view_589) : !cute.coord_tensor<"(?,?)", "():()">
        %e0_591, %e1_592 = cute.get_leaves(%iter_590) : !cute.int_tuple<"(?,?)">
        %138 = cute.get_scalars(%e0_591) : !cute.int_tuple<"?">
        %139 = cute.get_scalars(%e1_592) : !cute.int_tuple<"?">
        %iter_593 = cute.get_iter(%view_589) : !cute.coord_tensor<"(?,?)", "():()">
        %e0_594, %e1_595 = cute.get_leaves(%iter_593) : !cute.int_tuple<"(?,?)">
        %140 = cute.get_scalars(%e0_594) : !cute.int_tuple<"?">
        %141 = cute.get_scalars(%e1_595) : !cute.int_tuple<"?">
        %iter_596 = cute.get_iter(%view_589) : !cute.coord_tensor<"(?,?)", "():()">
        %e0_597, %e1_598 = cute.get_leaves(%iter_596) : !cute.int_tuple<"(?,?)">
        %142 = cute.get_scalars(%e0_597) : !cute.int_tuple<"?">
        %143 = cute.get_scalars(%e1_598) : !cute.int_tuple<"?">
        %coord_599 = cute.make_coord(%e0_597, %e1_598) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
        %coord_600 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
        %144:2 = cute.get_scalars(%coord_599) : !cute.coord<"(?,?)">
        %145:2 = cute.get_scalars(%coord_600) : !cute.coord<"(?,?)">
        %true = arith.constant true
        %146 = arith.cmpi slt, %144#0, %145#0 : i32
        %147 = arith.andi %true, %146 : i1
        %148 = arith.cmpi slt, %144#1, %145#1 : i32
        %149 = arith.andi %147, %148 : i1
        %150 = arith.extui %149 : i1 to i8
        %coord_601 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"?">
        cute.memref.store(%arg7, %coord_601, %150) : (!memref_rmem_i8_, !cute.coord<"?">, i8) -> ()
        %lay_602 = cute.get_layout(%arg7) : !memref_rmem_i8_
        %151 = cute.get_shape(%lay_602) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
        %e0_603, %e1_604, %e2_605, %e3_606, %e4_607 = cute.get_leaves(%151) : !cute.shape<"((1,(4,4)),1,1)">
        %152 = cute.get_stride(%lay_602) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.stride<"((0,(1,4)),0,0)">
        %e0_608, %e1_609, %e2_610, %e3_611, %e4_612 = cute.get_leaves(%152) : !cute.stride<"((0,(1,4)),0,0)">
        scf.yield %arg7 : !memref_rmem_i8_
      }
      %iter_255 = cute.get_iter(%97) : !memref_rmem_i8_
      %lay_256 = cute.get_layout(%97) : !memref_rmem_i8_
      %98 = cute.get_shape(%lay_256) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_257, %e1_258, %e2_259, %e3_260, %e4_261 = cute.get_leaves(%98) : !cute.shape<"((1,(4,4)),1,1)">
      %99 = cute.get_stride(%lay_256) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.stride<"((0,(1,4)),0,0)">
      %e0_262, %e1_263, %e2_264, %e3_265, %e4_266 = cute.get_leaves(%99) : !cute.stride<"((0,(1,4)),0,0)">
      %iter_267 = cute.get_iter(%97) : !memref_rmem_i8_
      %iter_268 = cute.get_iter(%97) : !memref_rmem_i8_
      %lay_269 = cute.get_layout(%view_167) : !memref_gmem_f32_2
      %100 = cute.get_shape(%lay_269) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_270, %e1_271, %e2_272, %e3_273, %e4_274 = cute.get_leaves(%100) : !cute.shape<"((1,(4,4)),1,1)">
      %lay_275 = cute.get_layout(%rmem) : !memref_rmem_f32_
      %101 = cute.get_shape(%lay_275) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_276, %e1_277, %e2_278, %e3_279, %e4_280 = cute.get_leaves(%101) : !cute.shape<"((1,(4,4)),1,1)">
      %lay_281 = cute.get_layout(%view_167) : !memref_gmem_f32_2
      %shape_282 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_283 = cute.make_layout() : !cute.layout<"1:0">
      %append = cute.append_to_rank<2> (%lay_281, %lay_283) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">
      %view_284 = cute.make_view(%iter_168, %append) : !memref_gmem_f32_2
      %iter_285 = cute.get_iter(%view_284) : !memref_gmem_f32_2
      %lay_286 = cute.get_layout(%view_284) : !memref_gmem_f32_2
      %102 = cute.get_shape(%lay_286) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_287, %e1_288, %e2_289, %e3_290, %e4_291 = cute.get_leaves(%102) : !cute.shape<"((1,(4,4)),1,1)">
      %iter_292 = cute.get_iter(%view_284) : !memref_gmem_f32_2
      %lay_293 = cute.get_layout(%view_284) : !memref_gmem_f32_2
      %103 = cute.get_scalars(%lay_293) <{only_dynamic}> : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %shape_294 = cute.make_shape() : () -> !cute.shape<"((1,(4,4)),(1,1))">
      %stride_295 = cute.make_stride(%103) : (i64) -> !cute.stride<"((0,(1,?{i64})),(0,0))">
      %lay_296 = cute.make_layout(%shape_294, %stride_295) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %view_297 = cute.make_view(%iter_292, %lay_296) : !memref_gmem_f32_3
      %iter_298 = cute.get_iter(%view_297) : !memref_gmem_f32_3
      %iter_299 = cute.get_iter(%view_297) : !memref_gmem_f32_3
      %lay_300 = cute.get_layout(%rmem) : !memref_rmem_f32_
      %shape_301 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_302 = cute.make_layout() : !cute.layout<"1:0">
      %append_303 = cute.append_to_rank<2> (%lay_300, %lay_302) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
      %view_304 = cute.make_view(%iter_206, %append_303) : !memref_rmem_f32_
      %iter_305 = cute.get_iter(%view_304) : !memref_rmem_f32_
      %lay_306 = cute.get_layout(%view_304) : !memref_rmem_f32_
      %104 = cute.get_shape(%lay_306) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_307, %e1_308, %e2_309, %e3_310, %e4_311 = cute.get_leaves(%104) : !cute.shape<"((1,(4,4)),1,1)">
      %iter_312 = cute.get_iter(%view_304) : !memref_rmem_f32_
      %view_313 = cute.make_view(%iter_312) : !memref_rmem_f32_1
      %iter_314 = cute.get_iter(%view_313) : !memref_rmem_f32_1
      %iter_315 = cute.get_iter(%view_313) : !memref_rmem_f32_1
      %lay_316 = cute.get_layout(%97) : !memref_rmem_i8_
      %shape_317 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_318 = cute.make_layout() : !cute.layout<"1:0">
      %append_319 = cute.append_to_rank<2> (%lay_316, %lay_318) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
      %view_320 = cute.make_view(%iter_268, %append_319) : !memref_rmem_i8_
      %iter_321 = cute.get_iter(%view_320) : !memref_rmem_i8_
      %lay_322 = cute.get_layout(%view_320) : !memref_rmem_i8_
      %105 = cute.get_shape(%lay_322) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_323, %e1_324, %e2_325, %e3_326, %e4_327 = cute.get_leaves(%105) : !cute.shape<"((1,(4,4)),1,1)">
      %iter_328 = cute.get_iter(%view_320) : !memref_rmem_i8_
      %view_329 = cute.make_view(%iter_328) : !memref_rmem_i8_1
      %iter_330 = cute.get_iter(%view_329) : !memref_rmem_i8_1
      %iter_331 = cute.get_iter(%view_329) : !memref_rmem_i8_1
      %lay_332 = cute.get_layout(%view_297) : !memref_gmem_f32_3
      %106 = cute.get_shape(%lay_332) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
      %e0_333, %e1_334, %e2_335, %e3_336, %e4_337 = cute.get_leaves(%106) : !cute.shape<"((1,(4,4)),(1,1))">
      %lay_338 = cute.get_layout(%view_313) : !memref_rmem_f32_1
      %107 = cute.get_shape(%lay_338) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
      %e0_339, %e1_340, %e2_341, %e3_342, %e4_343 = cute.get_leaves(%107) : !cute.shape<"((1,(4,4)),(1,1))">
      %lay_344 = cute.get_layout(%view_297) : !memref_gmem_f32_3
      %sz_345 = cute.size(%lay_344) <{mode = [1]}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.int_tuple<"1">
      %e0_346 = cute.get_leaves(%sz_345) : !cute.int_tuple<"1">
      %lay_347 = cute.get_layout(%view_313) : !memref_rmem_f32_1
      %sz_348 = cute.size(%lay_347) <{mode = [1]}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.int_tuple<"1">
      %e0_349 = cute.get_leaves(%sz_348) : !cute.int_tuple<"1">
      %108 = cute.static : !cute.layout<"1:0">
      %iter_350 = cute.get_iter(%view_297) : !memref_gmem_f32_3
      %iter_351 = cute.get_iter(%view_313) : !memref_rmem_f32_1
      %lay_352 = cute.get_layout(%view_297) : !memref_gmem_f32_3
      %lay_353 = cute.get_layout(%view_313) : !memref_rmem_f32_1
      %append_354 = cute.append_to_rank<2> (%lay_352, %108) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">, !cute.layout<"1:0">
      %append_355 = cute.append_to_rank<2> (%lay_353, %108) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">, !cute.layout<"1:0">
      %109 = cute.get_scalars(%append_354) <{only_dynamic}> : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %shape_356 = cute.make_shape() : () -> !cute.shape<"((1,(4,4)),((1,1)))">
      %stride_357 = cute.make_stride(%109) : (i64) -> !cute.stride<"((0,(1,?{i64})),((0,0)))">
      %lay_358 = cute.make_layout(%shape_356, %stride_357) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
      %lay_359 = cute.make_layout() : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">
      %iter_360 = cute.get_iter(%view_329) : !memref_rmem_i8_1
      %lay_361 = cute.get_layout(%view_329) : !memref_rmem_i8_1
      %append_362 = cute.append_to_rank<2> (%lay_361, %108) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">, !cute.layout<"1:0">
      %lay_363 = cute.make_layout() : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">
      %sz_364 = cute.size(%lay_358) <{mode = [1]}> : (!cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">) -> !cute.int_tuple<"1">
      %110 = cute.get_scalars(%sz_364) : !cute.int_tuple<"1">
      %c0_i32_365 = arith.constant 0 : i32
      %c1_i32_366 = arith.constant 1 : i32
      scf.for %arg6 = %c0_i32_365 to %110 step %c1_i32_366  : i32 {
        %coord_571 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
        %136 = cute.get_scalars(%lay_358) <{only_dynamic}> : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
        %137 = cute.get_scalars(%coord_571) <{only_dynamic}> : !cute.coord<"(_,?)">
        %shape_572 = cute.make_shape() : () -> !cute.shape<"((1,(4,4)))">
        %stride_573 = cute.make_stride(%136) : (i64) -> !cute.stride<"((0,(1,?{i64})))">
        %lay_574 = cute.make_layout(%shape_572, %stride_573) : !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
        %idx_575 = cute.crd2idx(%coord_571, %lay_358) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">) -> !cute.int_tuple<"0">
        %ptr_576 = cute.add_offset(%iter_350, %idx_575) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<f32, gmem>
        %view_577 = cute.make_view(%ptr_576, %lay_574) : !memref_gmem_f32_4
        %138 = cute.get_scalars(%coord_571) <{only_dynamic}> : !cute.coord<"(_,?)">
        %lay_578 = cute.make_layout() : !cute.layout<"((1,(4,4))):((0,(1,4)))">
        %idx_579 = cute.crd2idx(%coord_571, %lay_359) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">) -> !cute.int_tuple<"0">
        %ptr_580 = cute.add_offset(%iter_351, %idx_579) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, rmem, align<32>>
        %view_581 = cute.make_view(%ptr_580, %lay_578) : !memref_rmem_f32_2
        %139 = cute.get_scalars(%coord_571) <{only_dynamic}> : !cute.coord<"(_,?)">
        %lay_582 = cute.make_layout() : !cute.layout<"((1,(4,4))):((0,(1,4)))">
        %idx_583 = cute.crd2idx(%coord_571, %lay_363) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">) -> !cute.int_tuple<"0">
        %ptr_584 = cute.add_offset(%iter_360, %idx_583) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
        %view_585 = cute.make_view(%ptr_584, %lay_582) : !memref_rmem_i8_2
        %iter_586 = cute.get_iter(%view_577) : !memref_gmem_f32_4
        %lay_587 = cute.get_layout(%view_577) : !memref_gmem_f32_4
        %140 = cute.get_scalars(%lay_587) <{only_dynamic}> : !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
        %iter_588 = cute.get_iter(%view_581) : !memref_rmem_f32_2
        %iter_589 = cute.get_iter(%view_585) : !memref_rmem_i8_2
        %141 = builtin.unrealized_conversion_cast %iter_589 : !cute.ptr<i8, rmem, align<32>> to !llvm.ptr
        %142 = llvm.load %141 : !llvm.ptr -> i8
        %143 = llvm.mlir.constant(0 : i8) : i8
        %144 = llvm.icmp "ne" %142, %143 : i8
        scf.if %144 {
          %205 = builtin.unrealized_conversion_cast %iter_586 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %206 = builtin.unrealized_conversion_cast %iter_588 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
          %207 = llvm.load %205 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %207, %206 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %int_tuple_590 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
        %ptr_591 = cute.add_offset(%iter_589, %int_tuple_590) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
        %145 = builtin.unrealized_conversion_cast %ptr_591 : !cute.ptr<i8, rmem> to !llvm.ptr
        %146 = llvm.load %145 : !llvm.ptr -> i8
        %147 = llvm.mlir.constant(0 : i8) : i8
        %148 = llvm.icmp "ne" %146, %147 : i8
        scf.if %148 {
          %int_tuple_620 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
          %ptr_621 = cute.add_offset(%iter_586, %int_tuple_620) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
          %int_tuple_622 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
          %ptr_623 = cute.add_offset(%iter_588, %int_tuple_622) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
          %205 = builtin.unrealized_conversion_cast %ptr_621 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %206 = builtin.unrealized_conversion_cast %ptr_623 : !cute.ptr<f32, rmem> to !llvm.ptr
          %207 = llvm.load %205 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %207, %206 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %int_tuple_592 = cute.make_int_tuple() : () -> !cute.int_tuple<"2">
        %ptr_593 = cute.add_offset(%iter_589, %int_tuple_592) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem, align<2>>
        %149 = builtin.unrealized_conversion_cast %ptr_593 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
        %150 = llvm.load %149 : !llvm.ptr -> i8
        %151 = llvm.mlir.constant(0 : i8) : i8
        %152 = llvm.icmp "ne" %150, %151 : i8
        scf.if %152 {
          %int_tuple_620 = cute.make_int_tuple() : () -> !cute.int_tuple<"2">
          %ptr_621 = cute.add_offset(%iter_586, %int_tuple_620) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
          %int_tuple_622 = cute.make_int_tuple() : () -> !cute.int_tuple<"2">
          %ptr_623 = cute.add_offset(%iter_588, %int_tuple_622) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
          %205 = builtin.unrealized_conversion_cast %ptr_621 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %206 = builtin.unrealized_conversion_cast %ptr_623 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %207 = llvm.load %205 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %207, %206 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %int_tuple_594 = cute.make_int_tuple() : () -> !cute.int_tuple<"3">
        %ptr_595 = cute.add_offset(%iter_589, %int_tuple_594) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
        %153 = builtin.unrealized_conversion_cast %ptr_595 : !cute.ptr<i8, rmem> to !llvm.ptr
        %154 = llvm.load %153 : !llvm.ptr -> i8
        %155 = llvm.mlir.constant(0 : i8) : i8
        %156 = llvm.icmp "ne" %154, %155 : i8
        scf.if %156 {
          %int_tuple_620 = cute.make_int_tuple() : () -> !cute.int_tuple<"3">
          %ptr_621 = cute.add_offset(%iter_586, %int_tuple_620) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
          %int_tuple_622 = cute.make_int_tuple() : () -> !cute.int_tuple<"3">
          %ptr_623 = cute.add_offset(%iter_588, %int_tuple_622) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
          %205 = builtin.unrealized_conversion_cast %ptr_621 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %206 = builtin.unrealized_conversion_cast %ptr_623 : !cute.ptr<f32, rmem> to !llvm.ptr
          %207 = llvm.load %205 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %207, %206 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %int_tuple_596 = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
        %ptr_597 = cute.add_offset(%iter_589, %int_tuple_596) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem, align<4>>
        %157 = builtin.unrealized_conversion_cast %ptr_597 : !cute.ptr<i8, rmem, align<4>> to !llvm.ptr
        %158 = llvm.load %157 : !llvm.ptr -> i8
        %159 = llvm.mlir.constant(0 : i8) : i8
        %160 = llvm.icmp "ne" %158, %159 : i8
        scf.if %160 {
          %int_tuple_620 = cute.make_int_tuple(%140) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_621 = cute.add_offset(%iter_586, %int_tuple_620) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %int_tuple_622 = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
          %ptr_623 = cute.add_offset(%iter_588, %int_tuple_622) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
          %205 = builtin.unrealized_conversion_cast %ptr_621 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %206 = builtin.unrealized_conversion_cast %ptr_623 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
          %207 = llvm.load %205 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %207, %206 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %int_tuple_598 = cute.make_int_tuple() : () -> !cute.int_tuple<"5">
        %ptr_599 = cute.add_offset(%iter_589, %int_tuple_598) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
        %161 = builtin.unrealized_conversion_cast %ptr_599 : !cute.ptr<i8, rmem> to !llvm.ptr
        %162 = llvm.load %161 : !llvm.ptr -> i8
        %163 = llvm.mlir.constant(0 : i8) : i8
        %164 = llvm.icmp "ne" %162, %163 : i8
        scf.if %164 {
          %c1_i64 = arith.constant 1 : i64
          %205 = arith.addi %140, %c1_i64 : i64
          %int_tuple_620 = cute.make_int_tuple(%205) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_621 = cute.add_offset(%iter_586, %int_tuple_620) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %int_tuple_622 = cute.make_int_tuple() : () -> !cute.int_tuple<"5">
          %ptr_623 = cute.add_offset(%iter_588, %int_tuple_622) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<f32, rmem>
          %206 = builtin.unrealized_conversion_cast %ptr_621 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %207 = builtin.unrealized_conversion_cast %ptr_623 : !cute.ptr<f32, rmem> to !llvm.ptr
          %208 = llvm.load %206 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %208, %207 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %int_tuple_600 = cute.make_int_tuple() : () -> !cute.int_tuple<"6">
        %ptr_601 = cute.add_offset(%iter_589, %int_tuple_600) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem, align<2>>
        %165 = builtin.unrealized_conversion_cast %ptr_601 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
        %166 = llvm.load %165 : !llvm.ptr -> i8
        %167 = llvm.mlir.constant(0 : i8) : i8
        %168 = llvm.icmp "ne" %166, %167 : i8
        scf.if %168 {
          %c2_i64 = arith.constant 2 : i64
          %205 = arith.addi %140, %c2_i64 : i64
          %int_tuple_620 = cute.make_int_tuple(%205) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_621 = cute.add_offset(%iter_586, %int_tuple_620) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %int_tuple_622 = cute.make_int_tuple() : () -> !cute.int_tuple<"6">
          %ptr_623 = cute.add_offset(%iter_588, %int_tuple_622) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
          %206 = builtin.unrealized_conversion_cast %ptr_621 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %207 = builtin.unrealized_conversion_cast %ptr_623 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %208 = llvm.load %206 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %208, %207 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %int_tuple_602 = cute.make_int_tuple() : () -> !cute.int_tuple<"7">
        %ptr_603 = cute.add_offset(%iter_589, %int_tuple_602) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
        %169 = builtin.unrealized_conversion_cast %ptr_603 : !cute.ptr<i8, rmem> to !llvm.ptr
        %170 = llvm.load %169 : !llvm.ptr -> i8
        %171 = llvm.mlir.constant(0 : i8) : i8
        %172 = llvm.icmp "ne" %170, %171 : i8
        scf.if %172 {
          %c3_i64 = arith.constant 3 : i64
          %205 = arith.addi %140, %c3_i64 : i64
          %int_tuple_620 = cute.make_int_tuple(%205) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_621 = cute.add_offset(%iter_586, %int_tuple_620) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %int_tuple_622 = cute.make_int_tuple() : () -> !cute.int_tuple<"7">
          %ptr_623 = cute.add_offset(%iter_588, %int_tuple_622) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<f32, rmem>
          %206 = builtin.unrealized_conversion_cast %ptr_621 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %207 = builtin.unrealized_conversion_cast %ptr_623 : !cute.ptr<f32, rmem> to !llvm.ptr
          %208 = llvm.load %206 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %208, %207 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %int_tuple_604 = cute.make_int_tuple() : () -> !cute.int_tuple<"8">
        %ptr_605 = cute.add_offset(%iter_589, %int_tuple_604) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<i8, rmem, align<8>>
        %173 = builtin.unrealized_conversion_cast %ptr_605 : !cute.ptr<i8, rmem, align<8>> to !llvm.ptr
        %174 = llvm.load %173 : !llvm.ptr -> i8
        %175 = llvm.mlir.constant(0 : i8) : i8
        %176 = llvm.icmp "ne" %174, %175 : i8
        scf.if %176 {
          %c2_i64 = arith.constant 2 : i64
          %205 = arith.muli %140, %c2_i64 : i64
          %iv_620 = cute.assume(%205) : (i64) -> !cute.i64<divby 2>
          %int_tuple_621 = cute.make_int_tuple(%iv_620) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
          %ptr_622 = cute.add_offset(%iter_586, %int_tuple_621) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
          %int_tuple_623 = cute.make_int_tuple() : () -> !cute.int_tuple<"8">
          %ptr_624 = cute.add_offset(%iter_588, %int_tuple_623) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<f32, rmem, align<32>>
          %206 = builtin.unrealized_conversion_cast %ptr_622 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %207 = builtin.unrealized_conversion_cast %ptr_624 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
          %208 = llvm.load %206 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %208, %207 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %int_tuple_606 = cute.make_int_tuple() : () -> !cute.int_tuple<"9">
        %ptr_607 = cute.add_offset(%iter_589, %int_tuple_606) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<i8, rmem>
        %177 = builtin.unrealized_conversion_cast %ptr_607 : !cute.ptr<i8, rmem> to !llvm.ptr
        %178 = llvm.load %177 : !llvm.ptr -> i8
        %179 = llvm.mlir.constant(0 : i8) : i8
        %180 = llvm.icmp "ne" %178, %179 : i8
        scf.if %180 {
          %c2_i64 = arith.constant 2 : i64
          %205 = arith.muli %140, %c2_i64 : i64
          %c1_i64 = arith.constant 1 : i64
          %206 = arith.addi %205, %c1_i64 : i64
          %int_tuple_620 = cute.make_int_tuple(%206) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_621 = cute.add_offset(%iter_586, %int_tuple_620) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %int_tuple_622 = cute.make_int_tuple() : () -> !cute.int_tuple<"9">
          %ptr_623 = cute.add_offset(%iter_588, %int_tuple_622) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<f32, rmem>
          %207 = builtin.unrealized_conversion_cast %ptr_621 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %208 = builtin.unrealized_conversion_cast %ptr_623 : !cute.ptr<f32, rmem> to !llvm.ptr
          %209 = llvm.load %207 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %209, %208 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %int_tuple_608 = cute.make_int_tuple() : () -> !cute.int_tuple<"10">
        %ptr_609 = cute.add_offset(%iter_589, %int_tuple_608) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<i8, rmem, align<2>>
        %181 = builtin.unrealized_conversion_cast %ptr_609 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
        %182 = llvm.load %181 : !llvm.ptr -> i8
        %183 = llvm.mlir.constant(0 : i8) : i8
        %184 = llvm.icmp "ne" %182, %183 : i8
        scf.if %184 {
          %c2_i64 = arith.constant 2 : i64
          %205 = arith.muli %140, %c2_i64 : i64
          %c2_i64_620 = arith.constant 2 : i64
          %206 = arith.addi %205, %c2_i64_620 : i64
          %iv_621 = cute.assume(%206) : (i64) -> !cute.i64<divby 2>
          %int_tuple_622 = cute.make_int_tuple(%iv_621) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
          %ptr_623 = cute.add_offset(%iter_586, %int_tuple_622) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
          %int_tuple_624 = cute.make_int_tuple() : () -> !cute.int_tuple<"10">
          %ptr_625 = cute.add_offset(%iter_588, %int_tuple_624) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<f32, rmem, align<8>>
          %207 = builtin.unrealized_conversion_cast %ptr_623 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %208 = builtin.unrealized_conversion_cast %ptr_625 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %209 = llvm.load %207 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %209, %208 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %int_tuple_610 = cute.make_int_tuple() : () -> !cute.int_tuple<"11">
        %ptr_611 = cute.add_offset(%iter_589, %int_tuple_610) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<i8, rmem>
        %185 = builtin.unrealized_conversion_cast %ptr_611 : !cute.ptr<i8, rmem> to !llvm.ptr
        %186 = llvm.load %185 : !llvm.ptr -> i8
        %187 = llvm.mlir.constant(0 : i8) : i8
        %188 = llvm.icmp "ne" %186, %187 : i8
        scf.if %188 {
          %c2_i64 = arith.constant 2 : i64
          %205 = arith.muli %140, %c2_i64 : i64
          %c3_i64 = arith.constant 3 : i64
          %206 = arith.addi %205, %c3_i64 : i64
          %int_tuple_620 = cute.make_int_tuple(%206) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_621 = cute.add_offset(%iter_586, %int_tuple_620) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %int_tuple_622 = cute.make_int_tuple() : () -> !cute.int_tuple<"11">
          %ptr_623 = cute.add_offset(%iter_588, %int_tuple_622) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<f32, rmem>
          %207 = builtin.unrealized_conversion_cast %ptr_621 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %208 = builtin.unrealized_conversion_cast %ptr_623 : !cute.ptr<f32, rmem> to !llvm.ptr
          %209 = llvm.load %207 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %209, %208 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %int_tuple_612 = cute.make_int_tuple() : () -> !cute.int_tuple<"12">
        %ptr_613 = cute.add_offset(%iter_589, %int_tuple_612) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<i8, rmem, align<4>>
        %189 = builtin.unrealized_conversion_cast %ptr_613 : !cute.ptr<i8, rmem, align<4>> to !llvm.ptr
        %190 = llvm.load %189 : !llvm.ptr -> i8
        %191 = llvm.mlir.constant(0 : i8) : i8
        %192 = llvm.icmp "ne" %190, %191 : i8
        scf.if %192 {
          %c3_i64 = arith.constant 3 : i64
          %205 = arith.muli %140, %c3_i64 : i64
          %iv_620 = cute.assume(%205) : (i64) -> !cute.i64<divby 3>
          %int_tuple_621 = cute.make_int_tuple(%iv_620) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
          %ptr_622 = cute.add_offset(%iter_586, %int_tuple_621) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
          %int_tuple_623 = cute.make_int_tuple() : () -> !cute.int_tuple<"12">
          %ptr_624 = cute.add_offset(%iter_588, %int_tuple_623) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<f32, rmem, align<16>>
          %206 = builtin.unrealized_conversion_cast %ptr_622 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %207 = builtin.unrealized_conversion_cast %ptr_624 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
          %208 = llvm.load %206 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %208, %207 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %int_tuple_614 = cute.make_int_tuple() : () -> !cute.int_tuple<"13">
        %ptr_615 = cute.add_offset(%iter_589, %int_tuple_614) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<i8, rmem>
        %193 = builtin.unrealized_conversion_cast %ptr_615 : !cute.ptr<i8, rmem> to !llvm.ptr
        %194 = llvm.load %193 : !llvm.ptr -> i8
        %195 = llvm.mlir.constant(0 : i8) : i8
        %196 = llvm.icmp "ne" %194, %195 : i8
        scf.if %196 {
          %c3_i64 = arith.constant 3 : i64
          %205 = arith.muli %140, %c3_i64 : i64
          %c1_i64 = arith.constant 1 : i64
          %206 = arith.addi %205, %c1_i64 : i64
          %int_tuple_620 = cute.make_int_tuple(%206) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_621 = cute.add_offset(%iter_586, %int_tuple_620) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %int_tuple_622 = cute.make_int_tuple() : () -> !cute.int_tuple<"13">
          %ptr_623 = cute.add_offset(%iter_588, %int_tuple_622) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<f32, rmem>
          %207 = builtin.unrealized_conversion_cast %ptr_621 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %208 = builtin.unrealized_conversion_cast %ptr_623 : !cute.ptr<f32, rmem> to !llvm.ptr
          %209 = llvm.load %207 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %209, %208 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %int_tuple_616 = cute.make_int_tuple() : () -> !cute.int_tuple<"14">
        %ptr_617 = cute.add_offset(%iter_589, %int_tuple_616) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<i8, rmem, align<2>>
        %197 = builtin.unrealized_conversion_cast %ptr_617 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
        %198 = llvm.load %197 : !llvm.ptr -> i8
        %199 = llvm.mlir.constant(0 : i8) : i8
        %200 = llvm.icmp "ne" %198, %199 : i8
        scf.if %200 {
          %c3_i64 = arith.constant 3 : i64
          %205 = arith.muli %140, %c3_i64 : i64
          %c2_i64 = arith.constant 2 : i64
          %206 = arith.addi %205, %c2_i64 : i64
          %int_tuple_620 = cute.make_int_tuple(%206) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_621 = cute.add_offset(%iter_586, %int_tuple_620) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %int_tuple_622 = cute.make_int_tuple() : () -> !cute.int_tuple<"14">
          %ptr_623 = cute.add_offset(%iter_588, %int_tuple_622) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<f32, rmem, align<8>>
          %207 = builtin.unrealized_conversion_cast %ptr_621 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %208 = builtin.unrealized_conversion_cast %ptr_623 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %209 = llvm.load %207 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %209, %208 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %int_tuple_618 = cute.make_int_tuple() : () -> !cute.int_tuple<"15">
        %ptr_619 = cute.add_offset(%iter_589, %int_tuple_618) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<i8, rmem>
        %201 = builtin.unrealized_conversion_cast %ptr_619 : !cute.ptr<i8, rmem> to !llvm.ptr
        %202 = llvm.load %201 : !llvm.ptr -> i8
        %203 = llvm.mlir.constant(0 : i8) : i8
        %204 = llvm.icmp "ne" %202, %203 : i8
        scf.if %204 {
          %c3_i64 = arith.constant 3 : i64
          %205 = arith.muli %140, %c3_i64 : i64
          %c3_i64_620 = arith.constant 3 : i64
          %206 = arith.addi %205, %c3_i64_620 : i64
          %iv_621 = cute.assume(%206) : (i64) -> !cute.i64<divby 3>
          %int_tuple_622 = cute.make_int_tuple(%iv_621) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
          %ptr_623 = cute.add_offset(%iter_586, %int_tuple_622) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
          %int_tuple_624 = cute.make_int_tuple() : () -> !cute.int_tuple<"15">
          %ptr_625 = cute.add_offset(%iter_588, %int_tuple_624) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<f32, rmem>
          %207 = builtin.unrealized_conversion_cast %ptr_623 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %208 = builtin.unrealized_conversion_cast %ptr_625 : !cute.ptr<f32, rmem> to !llvm.ptr
          %209 = llvm.load %207 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %209, %208 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
      } {llvm.loop_annotation = #loop_annotation}
      %lay_367 = cute.get_layout(%view_184) : !memref_gmem_f32_2
      %111 = cute.get_shape(%lay_367) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_368, %e1_369, %e2_370, %e3_371, %e4_372 = cute.get_leaves(%111) : !cute.shape<"((1,(4,4)),1,1)">
      %lay_373 = cute.get_layout(%rmem_209) : !memref_rmem_f32_
      %112 = cute.get_shape(%lay_373) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_374, %e1_375, %e2_376, %e3_377, %e4_378 = cute.get_leaves(%112) : !cute.shape<"((1,(4,4)),1,1)">
      %lay_379 = cute.get_layout(%view_184) : !memref_gmem_f32_2
      %shape_380 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_381 = cute.make_layout() : !cute.layout<"1:0">
      %append_382 = cute.append_to_rank<2> (%lay_379, %lay_381) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">
      %view_383 = cute.make_view(%iter_185, %append_382) : !memref_gmem_f32_2
      %iter_384 = cute.get_iter(%view_383) : !memref_gmem_f32_2
      %lay_385 = cute.get_layout(%view_383) : !memref_gmem_f32_2
      %113 = cute.get_shape(%lay_385) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_386, %e1_387, %e2_388, %e3_389, %e4_390 = cute.get_leaves(%113) : !cute.shape<"((1,(4,4)),1,1)">
      %iter_391 = cute.get_iter(%view_383) : !memref_gmem_f32_2
      %lay_392 = cute.get_layout(%view_383) : !memref_gmem_f32_2
      %114 = cute.get_scalars(%lay_392) <{only_dynamic}> : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %shape_393 = cute.make_shape() : () -> !cute.shape<"((1,(4,4)),(1,1))">
      %stride_394 = cute.make_stride(%114) : (i64) -> !cute.stride<"((0,(1,?{i64})),(0,0))">
      %lay_395 = cute.make_layout(%shape_393, %stride_394) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %view_396 = cute.make_view(%iter_391, %lay_395) : !memref_gmem_f32_3
      %iter_397 = cute.get_iter(%view_396) : !memref_gmem_f32_3
      %iter_398 = cute.get_iter(%view_396) : !memref_gmem_f32_3
      %lay_399 = cute.get_layout(%rmem_209) : !memref_rmem_f32_
      %shape_400 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_401 = cute.make_layout() : !cute.layout<"1:0">
      %append_402 = cute.append_to_rank<2> (%lay_399, %lay_401) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
      %view_403 = cute.make_view(%iter_211, %append_402) : !memref_rmem_f32_
      %iter_404 = cute.get_iter(%view_403) : !memref_rmem_f32_
      %lay_405 = cute.get_layout(%view_403) : !memref_rmem_f32_
      %115 = cute.get_shape(%lay_405) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_406, %e1_407, %e2_408, %e3_409, %e4_410 = cute.get_leaves(%115) : !cute.shape<"((1,(4,4)),1,1)">
      %iter_411 = cute.get_iter(%view_403) : !memref_rmem_f32_
      %view_412 = cute.make_view(%iter_411) : !memref_rmem_f32_1
      %iter_413 = cute.get_iter(%view_412) : !memref_rmem_f32_1
      %iter_414 = cute.get_iter(%view_412) : !memref_rmem_f32_1
      %lay_415 = cute.get_layout(%97) : !memref_rmem_i8_
      %shape_416 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_417 = cute.make_layout() : !cute.layout<"1:0">
      %append_418 = cute.append_to_rank<2> (%lay_415, %lay_417) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
      %view_419 = cute.make_view(%iter_268, %append_418) : !memref_rmem_i8_
      %iter_420 = cute.get_iter(%view_419) : !memref_rmem_i8_
      %lay_421 = cute.get_layout(%view_419) : !memref_rmem_i8_
      %116 = cute.get_shape(%lay_421) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_422, %e1_423, %e2_424, %e3_425, %e4_426 = cute.get_leaves(%116) : !cute.shape<"((1,(4,4)),1,1)">
      %iter_427 = cute.get_iter(%view_419) : !memref_rmem_i8_
      %view_428 = cute.make_view(%iter_427) : !memref_rmem_i8_1
      %iter_429 = cute.get_iter(%view_428) : !memref_rmem_i8_1
      %iter_430 = cute.get_iter(%view_428) : !memref_rmem_i8_1
      %lay_431 = cute.get_layout(%view_396) : !memref_gmem_f32_3
      %117 = cute.get_shape(%lay_431) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
      %e0_432, %e1_433, %e2_434, %e3_435, %e4_436 = cute.get_leaves(%117) : !cute.shape<"((1,(4,4)),(1,1))">
      %lay_437 = cute.get_layout(%view_412) : !memref_rmem_f32_1
      %118 = cute.get_shape(%lay_437) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
      %e0_438, %e1_439, %e2_440, %e3_441, %e4_442 = cute.get_leaves(%118) : !cute.shape<"((1,(4,4)),(1,1))">
      %lay_443 = cute.get_layout(%view_396) : !memref_gmem_f32_3
      %sz_444 = cute.size(%lay_443) <{mode = [1]}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.int_tuple<"1">
      %e0_445 = cute.get_leaves(%sz_444) : !cute.int_tuple<"1">
      %lay_446 = cute.get_layout(%view_412) : !memref_rmem_f32_1
      %sz_447 = cute.size(%lay_446) <{mode = [1]}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.int_tuple<"1">
      %e0_448 = cute.get_leaves(%sz_447) : !cute.int_tuple<"1">
      %119 = cute.static : !cute.layout<"1:0">
      %iter_449 = cute.get_iter(%view_396) : !memref_gmem_f32_3
      %iter_450 = cute.get_iter(%view_412) : !memref_rmem_f32_1
      %lay_451 = cute.get_layout(%view_396) : !memref_gmem_f32_3
      %lay_452 = cute.get_layout(%view_412) : !memref_rmem_f32_1
      %append_453 = cute.append_to_rank<2> (%lay_451, %119) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">, !cute.layout<"1:0">
      %append_454 = cute.append_to_rank<2> (%lay_452, %119) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">, !cute.layout<"1:0">
      %120 = cute.get_scalars(%append_453) <{only_dynamic}> : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %shape_455 = cute.make_shape() : () -> !cute.shape<"((1,(4,4)),((1,1)))">
      %stride_456 = cute.make_stride(%120) : (i64) -> !cute.stride<"((0,(1,?{i64})),((0,0)))">
      %lay_457 = cute.make_layout(%shape_455, %stride_456) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
      %lay_458 = cute.make_layout() : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">
      %iter_459 = cute.get_iter(%view_428) : !memref_rmem_i8_1
      %lay_460 = cute.get_layout(%view_428) : !memref_rmem_i8_1
      %append_461 = cute.append_to_rank<2> (%lay_460, %119) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">, !cute.layout<"1:0">
      %lay_462 = cute.make_layout() : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">
      %sz_463 = cute.size(%lay_457) <{mode = [1]}> : (!cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">) -> !cute.int_tuple<"1">
      %121 = cute.get_scalars(%sz_463) : !cute.int_tuple<"1">
      %c0_i32_464 = arith.constant 0 : i32
      %c1_i32_465 = arith.constant 1 : i32
      scf.for %arg6 = %c0_i32_464 to %121 step %c1_i32_465  : i32 {
        %coord_571 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
        %136 = cute.get_scalars(%lay_457) <{only_dynamic}> : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
        %137 = cute.get_scalars(%coord_571) <{only_dynamic}> : !cute.coord<"(_,?)">
        %shape_572 = cute.make_shape() : () -> !cute.shape<"((1,(4,4)))">
        %stride_573 = cute.make_stride(%136) : (i64) -> !cute.stride<"((0,(1,?{i64})))">
        %lay_574 = cute.make_layout(%shape_572, %stride_573) : !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
        %idx_575 = cute.crd2idx(%coord_571, %lay_457) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">) -> !cute.int_tuple<"0">
        %ptr_576 = cute.add_offset(%iter_449, %idx_575) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<f32, gmem>
        %view_577 = cute.make_view(%ptr_576, %lay_574) : !memref_gmem_f32_4
        %138 = cute.get_scalars(%coord_571) <{only_dynamic}> : !cute.coord<"(_,?)">
        %lay_578 = cute.make_layout() : !cute.layout<"((1,(4,4))):((0,(1,4)))">
        %idx_579 = cute.crd2idx(%coord_571, %lay_458) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">) -> !cute.int_tuple<"0">
        %ptr_580 = cute.add_offset(%iter_450, %idx_579) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, rmem, align<32>>
        %view_581 = cute.make_view(%ptr_580, %lay_578) : !memref_rmem_f32_2
        %139 = cute.get_scalars(%coord_571) <{only_dynamic}> : !cute.coord<"(_,?)">
        %lay_582 = cute.make_layout() : !cute.layout<"((1,(4,4))):((0,(1,4)))">
        %idx_583 = cute.crd2idx(%coord_571, %lay_462) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">) -> !cute.int_tuple<"0">
        %ptr_584 = cute.add_offset(%iter_459, %idx_583) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
        %view_585 = cute.make_view(%ptr_584, %lay_582) : !memref_rmem_i8_2
        %iter_586 = cute.get_iter(%view_577) : !memref_gmem_f32_4
        %lay_587 = cute.get_layout(%view_577) : !memref_gmem_f32_4
        %140 = cute.get_scalars(%lay_587) <{only_dynamic}> : !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
        %iter_588 = cute.get_iter(%view_581) : !memref_rmem_f32_2
        %iter_589 = cute.get_iter(%view_585) : !memref_rmem_i8_2
        %141 = builtin.unrealized_conversion_cast %iter_589 : !cute.ptr<i8, rmem, align<32>> to !llvm.ptr
        %142 = llvm.load %141 : !llvm.ptr -> i8
        %143 = llvm.mlir.constant(0 : i8) : i8
        %144 = llvm.icmp "ne" %142, %143 : i8
        scf.if %144 {
          %205 = builtin.unrealized_conversion_cast %iter_586 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %206 = builtin.unrealized_conversion_cast %iter_588 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
          %207 = llvm.load %205 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %207, %206 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %int_tuple_590 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
        %ptr_591 = cute.add_offset(%iter_589, %int_tuple_590) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
        %145 = builtin.unrealized_conversion_cast %ptr_591 : !cute.ptr<i8, rmem> to !llvm.ptr
        %146 = llvm.load %145 : !llvm.ptr -> i8
        %147 = llvm.mlir.constant(0 : i8) : i8
        %148 = llvm.icmp "ne" %146, %147 : i8
        scf.if %148 {
          %int_tuple_620 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
          %ptr_621 = cute.add_offset(%iter_586, %int_tuple_620) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
          %int_tuple_622 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
          %ptr_623 = cute.add_offset(%iter_588, %int_tuple_622) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
          %205 = builtin.unrealized_conversion_cast %ptr_621 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %206 = builtin.unrealized_conversion_cast %ptr_623 : !cute.ptr<f32, rmem> to !llvm.ptr
          %207 = llvm.load %205 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %207, %206 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %int_tuple_592 = cute.make_int_tuple() : () -> !cute.int_tuple<"2">
        %ptr_593 = cute.add_offset(%iter_589, %int_tuple_592) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem, align<2>>
        %149 = builtin.unrealized_conversion_cast %ptr_593 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
        %150 = llvm.load %149 : !llvm.ptr -> i8
        %151 = llvm.mlir.constant(0 : i8) : i8
        %152 = llvm.icmp "ne" %150, %151 : i8
        scf.if %152 {
          %int_tuple_620 = cute.make_int_tuple() : () -> !cute.int_tuple<"2">
          %ptr_621 = cute.add_offset(%iter_586, %int_tuple_620) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
          %int_tuple_622 = cute.make_int_tuple() : () -> !cute.int_tuple<"2">
          %ptr_623 = cute.add_offset(%iter_588, %int_tuple_622) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
          %205 = builtin.unrealized_conversion_cast %ptr_621 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %206 = builtin.unrealized_conversion_cast %ptr_623 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %207 = llvm.load %205 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %207, %206 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %int_tuple_594 = cute.make_int_tuple() : () -> !cute.int_tuple<"3">
        %ptr_595 = cute.add_offset(%iter_589, %int_tuple_594) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
        %153 = builtin.unrealized_conversion_cast %ptr_595 : !cute.ptr<i8, rmem> to !llvm.ptr
        %154 = llvm.load %153 : !llvm.ptr -> i8
        %155 = llvm.mlir.constant(0 : i8) : i8
        %156 = llvm.icmp "ne" %154, %155 : i8
        scf.if %156 {
          %int_tuple_620 = cute.make_int_tuple() : () -> !cute.int_tuple<"3">
          %ptr_621 = cute.add_offset(%iter_586, %int_tuple_620) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
          %int_tuple_622 = cute.make_int_tuple() : () -> !cute.int_tuple<"3">
          %ptr_623 = cute.add_offset(%iter_588, %int_tuple_622) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
          %205 = builtin.unrealized_conversion_cast %ptr_621 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %206 = builtin.unrealized_conversion_cast %ptr_623 : !cute.ptr<f32, rmem> to !llvm.ptr
          %207 = llvm.load %205 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %207, %206 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %int_tuple_596 = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
        %ptr_597 = cute.add_offset(%iter_589, %int_tuple_596) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem, align<4>>
        %157 = builtin.unrealized_conversion_cast %ptr_597 : !cute.ptr<i8, rmem, align<4>> to !llvm.ptr
        %158 = llvm.load %157 : !llvm.ptr -> i8
        %159 = llvm.mlir.constant(0 : i8) : i8
        %160 = llvm.icmp "ne" %158, %159 : i8
        scf.if %160 {
          %int_tuple_620 = cute.make_int_tuple(%140) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_621 = cute.add_offset(%iter_586, %int_tuple_620) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %int_tuple_622 = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
          %ptr_623 = cute.add_offset(%iter_588, %int_tuple_622) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
          %205 = builtin.unrealized_conversion_cast %ptr_621 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %206 = builtin.unrealized_conversion_cast %ptr_623 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
          %207 = llvm.load %205 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %207, %206 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %int_tuple_598 = cute.make_int_tuple() : () -> !cute.int_tuple<"5">
        %ptr_599 = cute.add_offset(%iter_589, %int_tuple_598) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
        %161 = builtin.unrealized_conversion_cast %ptr_599 : !cute.ptr<i8, rmem> to !llvm.ptr
        %162 = llvm.load %161 : !llvm.ptr -> i8
        %163 = llvm.mlir.constant(0 : i8) : i8
        %164 = llvm.icmp "ne" %162, %163 : i8
        scf.if %164 {
          %c1_i64 = arith.constant 1 : i64
          %205 = arith.addi %140, %c1_i64 : i64
          %int_tuple_620 = cute.make_int_tuple(%205) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_621 = cute.add_offset(%iter_586, %int_tuple_620) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %int_tuple_622 = cute.make_int_tuple() : () -> !cute.int_tuple<"5">
          %ptr_623 = cute.add_offset(%iter_588, %int_tuple_622) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<f32, rmem>
          %206 = builtin.unrealized_conversion_cast %ptr_621 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %207 = builtin.unrealized_conversion_cast %ptr_623 : !cute.ptr<f32, rmem> to !llvm.ptr
          %208 = llvm.load %206 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %208, %207 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %int_tuple_600 = cute.make_int_tuple() : () -> !cute.int_tuple<"6">
        %ptr_601 = cute.add_offset(%iter_589, %int_tuple_600) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem, align<2>>
        %165 = builtin.unrealized_conversion_cast %ptr_601 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
        %166 = llvm.load %165 : !llvm.ptr -> i8
        %167 = llvm.mlir.constant(0 : i8) : i8
        %168 = llvm.icmp "ne" %166, %167 : i8
        scf.if %168 {
          %c2_i64 = arith.constant 2 : i64
          %205 = arith.addi %140, %c2_i64 : i64
          %int_tuple_620 = cute.make_int_tuple(%205) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_621 = cute.add_offset(%iter_586, %int_tuple_620) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %int_tuple_622 = cute.make_int_tuple() : () -> !cute.int_tuple<"6">
          %ptr_623 = cute.add_offset(%iter_588, %int_tuple_622) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
          %206 = builtin.unrealized_conversion_cast %ptr_621 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %207 = builtin.unrealized_conversion_cast %ptr_623 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %208 = llvm.load %206 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %208, %207 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %int_tuple_602 = cute.make_int_tuple() : () -> !cute.int_tuple<"7">
        %ptr_603 = cute.add_offset(%iter_589, %int_tuple_602) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
        %169 = builtin.unrealized_conversion_cast %ptr_603 : !cute.ptr<i8, rmem> to !llvm.ptr
        %170 = llvm.load %169 : !llvm.ptr -> i8
        %171 = llvm.mlir.constant(0 : i8) : i8
        %172 = llvm.icmp "ne" %170, %171 : i8
        scf.if %172 {
          %c3_i64 = arith.constant 3 : i64
          %205 = arith.addi %140, %c3_i64 : i64
          %int_tuple_620 = cute.make_int_tuple(%205) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_621 = cute.add_offset(%iter_586, %int_tuple_620) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %int_tuple_622 = cute.make_int_tuple() : () -> !cute.int_tuple<"7">
          %ptr_623 = cute.add_offset(%iter_588, %int_tuple_622) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<f32, rmem>
          %206 = builtin.unrealized_conversion_cast %ptr_621 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %207 = builtin.unrealized_conversion_cast %ptr_623 : !cute.ptr<f32, rmem> to !llvm.ptr
          %208 = llvm.load %206 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %208, %207 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %int_tuple_604 = cute.make_int_tuple() : () -> !cute.int_tuple<"8">
        %ptr_605 = cute.add_offset(%iter_589, %int_tuple_604) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<i8, rmem, align<8>>
        %173 = builtin.unrealized_conversion_cast %ptr_605 : !cute.ptr<i8, rmem, align<8>> to !llvm.ptr
        %174 = llvm.load %173 : !llvm.ptr -> i8
        %175 = llvm.mlir.constant(0 : i8) : i8
        %176 = llvm.icmp "ne" %174, %175 : i8
        scf.if %176 {
          %c2_i64 = arith.constant 2 : i64
          %205 = arith.muli %140, %c2_i64 : i64
          %iv_620 = cute.assume(%205) : (i64) -> !cute.i64<divby 2>
          %int_tuple_621 = cute.make_int_tuple(%iv_620) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
          %ptr_622 = cute.add_offset(%iter_586, %int_tuple_621) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
          %int_tuple_623 = cute.make_int_tuple() : () -> !cute.int_tuple<"8">
          %ptr_624 = cute.add_offset(%iter_588, %int_tuple_623) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<f32, rmem, align<32>>
          %206 = builtin.unrealized_conversion_cast %ptr_622 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %207 = builtin.unrealized_conversion_cast %ptr_624 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
          %208 = llvm.load %206 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %208, %207 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %int_tuple_606 = cute.make_int_tuple() : () -> !cute.int_tuple<"9">
        %ptr_607 = cute.add_offset(%iter_589, %int_tuple_606) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<i8, rmem>
        %177 = builtin.unrealized_conversion_cast %ptr_607 : !cute.ptr<i8, rmem> to !llvm.ptr
        %178 = llvm.load %177 : !llvm.ptr -> i8
        %179 = llvm.mlir.constant(0 : i8) : i8
        %180 = llvm.icmp "ne" %178, %179 : i8
        scf.if %180 {
          %c2_i64 = arith.constant 2 : i64
          %205 = arith.muli %140, %c2_i64 : i64
          %c1_i64 = arith.constant 1 : i64
          %206 = arith.addi %205, %c1_i64 : i64
          %int_tuple_620 = cute.make_int_tuple(%206) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_621 = cute.add_offset(%iter_586, %int_tuple_620) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %int_tuple_622 = cute.make_int_tuple() : () -> !cute.int_tuple<"9">
          %ptr_623 = cute.add_offset(%iter_588, %int_tuple_622) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<f32, rmem>
          %207 = builtin.unrealized_conversion_cast %ptr_621 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %208 = builtin.unrealized_conversion_cast %ptr_623 : !cute.ptr<f32, rmem> to !llvm.ptr
          %209 = llvm.load %207 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %209, %208 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %int_tuple_608 = cute.make_int_tuple() : () -> !cute.int_tuple<"10">
        %ptr_609 = cute.add_offset(%iter_589, %int_tuple_608) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<i8, rmem, align<2>>
        %181 = builtin.unrealized_conversion_cast %ptr_609 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
        %182 = llvm.load %181 : !llvm.ptr -> i8
        %183 = llvm.mlir.constant(0 : i8) : i8
        %184 = llvm.icmp "ne" %182, %183 : i8
        scf.if %184 {
          %c2_i64 = arith.constant 2 : i64
          %205 = arith.muli %140, %c2_i64 : i64
          %c2_i64_620 = arith.constant 2 : i64
          %206 = arith.addi %205, %c2_i64_620 : i64
          %iv_621 = cute.assume(%206) : (i64) -> !cute.i64<divby 2>
          %int_tuple_622 = cute.make_int_tuple(%iv_621) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
          %ptr_623 = cute.add_offset(%iter_586, %int_tuple_622) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
          %int_tuple_624 = cute.make_int_tuple() : () -> !cute.int_tuple<"10">
          %ptr_625 = cute.add_offset(%iter_588, %int_tuple_624) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<f32, rmem, align<8>>
          %207 = builtin.unrealized_conversion_cast %ptr_623 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %208 = builtin.unrealized_conversion_cast %ptr_625 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %209 = llvm.load %207 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %209, %208 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %int_tuple_610 = cute.make_int_tuple() : () -> !cute.int_tuple<"11">
        %ptr_611 = cute.add_offset(%iter_589, %int_tuple_610) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<i8, rmem>
        %185 = builtin.unrealized_conversion_cast %ptr_611 : !cute.ptr<i8, rmem> to !llvm.ptr
        %186 = llvm.load %185 : !llvm.ptr -> i8
        %187 = llvm.mlir.constant(0 : i8) : i8
        %188 = llvm.icmp "ne" %186, %187 : i8
        scf.if %188 {
          %c2_i64 = arith.constant 2 : i64
          %205 = arith.muli %140, %c2_i64 : i64
          %c3_i64 = arith.constant 3 : i64
          %206 = arith.addi %205, %c3_i64 : i64
          %int_tuple_620 = cute.make_int_tuple(%206) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_621 = cute.add_offset(%iter_586, %int_tuple_620) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %int_tuple_622 = cute.make_int_tuple() : () -> !cute.int_tuple<"11">
          %ptr_623 = cute.add_offset(%iter_588, %int_tuple_622) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<f32, rmem>
          %207 = builtin.unrealized_conversion_cast %ptr_621 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %208 = builtin.unrealized_conversion_cast %ptr_623 : !cute.ptr<f32, rmem> to !llvm.ptr
          %209 = llvm.load %207 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %209, %208 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %int_tuple_612 = cute.make_int_tuple() : () -> !cute.int_tuple<"12">
        %ptr_613 = cute.add_offset(%iter_589, %int_tuple_612) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<i8, rmem, align<4>>
        %189 = builtin.unrealized_conversion_cast %ptr_613 : !cute.ptr<i8, rmem, align<4>> to !llvm.ptr
        %190 = llvm.load %189 : !llvm.ptr -> i8
        %191 = llvm.mlir.constant(0 : i8) : i8
        %192 = llvm.icmp "ne" %190, %191 : i8
        scf.if %192 {
          %c3_i64 = arith.constant 3 : i64
          %205 = arith.muli %140, %c3_i64 : i64
          %iv_620 = cute.assume(%205) : (i64) -> !cute.i64<divby 3>
          %int_tuple_621 = cute.make_int_tuple(%iv_620) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
          %ptr_622 = cute.add_offset(%iter_586, %int_tuple_621) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
          %int_tuple_623 = cute.make_int_tuple() : () -> !cute.int_tuple<"12">
          %ptr_624 = cute.add_offset(%iter_588, %int_tuple_623) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<f32, rmem, align<16>>
          %206 = builtin.unrealized_conversion_cast %ptr_622 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %207 = builtin.unrealized_conversion_cast %ptr_624 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
          %208 = llvm.load %206 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %208, %207 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %int_tuple_614 = cute.make_int_tuple() : () -> !cute.int_tuple<"13">
        %ptr_615 = cute.add_offset(%iter_589, %int_tuple_614) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<i8, rmem>
        %193 = builtin.unrealized_conversion_cast %ptr_615 : !cute.ptr<i8, rmem> to !llvm.ptr
        %194 = llvm.load %193 : !llvm.ptr -> i8
        %195 = llvm.mlir.constant(0 : i8) : i8
        %196 = llvm.icmp "ne" %194, %195 : i8
        scf.if %196 {
          %c3_i64 = arith.constant 3 : i64
          %205 = arith.muli %140, %c3_i64 : i64
          %c1_i64 = arith.constant 1 : i64
          %206 = arith.addi %205, %c1_i64 : i64
          %int_tuple_620 = cute.make_int_tuple(%206) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_621 = cute.add_offset(%iter_586, %int_tuple_620) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %int_tuple_622 = cute.make_int_tuple() : () -> !cute.int_tuple<"13">
          %ptr_623 = cute.add_offset(%iter_588, %int_tuple_622) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<f32, rmem>
          %207 = builtin.unrealized_conversion_cast %ptr_621 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %208 = builtin.unrealized_conversion_cast %ptr_623 : !cute.ptr<f32, rmem> to !llvm.ptr
          %209 = llvm.load %207 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %209, %208 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %int_tuple_616 = cute.make_int_tuple() : () -> !cute.int_tuple<"14">
        %ptr_617 = cute.add_offset(%iter_589, %int_tuple_616) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<i8, rmem, align<2>>
        %197 = builtin.unrealized_conversion_cast %ptr_617 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
        %198 = llvm.load %197 : !llvm.ptr -> i8
        %199 = llvm.mlir.constant(0 : i8) : i8
        %200 = llvm.icmp "ne" %198, %199 : i8
        scf.if %200 {
          %c3_i64 = arith.constant 3 : i64
          %205 = arith.muli %140, %c3_i64 : i64
          %c2_i64 = arith.constant 2 : i64
          %206 = arith.addi %205, %c2_i64 : i64
          %int_tuple_620 = cute.make_int_tuple(%206) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_621 = cute.add_offset(%iter_586, %int_tuple_620) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %int_tuple_622 = cute.make_int_tuple() : () -> !cute.int_tuple<"14">
          %ptr_623 = cute.add_offset(%iter_588, %int_tuple_622) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<f32, rmem, align<8>>
          %207 = builtin.unrealized_conversion_cast %ptr_621 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %208 = builtin.unrealized_conversion_cast %ptr_623 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %209 = llvm.load %207 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %209, %208 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %int_tuple_618 = cute.make_int_tuple() : () -> !cute.int_tuple<"15">
        %ptr_619 = cute.add_offset(%iter_589, %int_tuple_618) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<i8, rmem>
        %201 = builtin.unrealized_conversion_cast %ptr_619 : !cute.ptr<i8, rmem> to !llvm.ptr
        %202 = llvm.load %201 : !llvm.ptr -> i8
        %203 = llvm.mlir.constant(0 : i8) : i8
        %204 = llvm.icmp "ne" %202, %203 : i8
        scf.if %204 {
          %c3_i64 = arith.constant 3 : i64
          %205 = arith.muli %140, %c3_i64 : i64
          %c3_i64_620 = arith.constant 3 : i64
          %206 = arith.addi %205, %c3_i64_620 : i64
          %iv_621 = cute.assume(%206) : (i64) -> !cute.i64<divby 3>
          %int_tuple_622 = cute.make_int_tuple(%iv_621) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
          %ptr_623 = cute.add_offset(%iter_586, %int_tuple_622) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
          %int_tuple_624 = cute.make_int_tuple() : () -> !cute.int_tuple<"15">
          %ptr_625 = cute.add_offset(%iter_588, %int_tuple_624) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<f32, rmem>
          %207 = builtin.unrealized_conversion_cast %ptr_623 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %208 = builtin.unrealized_conversion_cast %ptr_625 : !cute.ptr<f32, rmem> to !llvm.ptr
          %209 = llvm.load %207 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %209, %208 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
      } {llvm.loop_annotation = #loop_annotation}
      %122 = cute.memref.load_vec %rmem, row_major : !memref_rmem_f32_
      %123 = cute.memref.load_vec %rmem_209, row_major : !memref_rmem_f32_
      %124 = arith.addf %122, %123 : vector<16xf32>
      %lay_466 = cute.get_layout(%rmem_214) : !memref_rmem_f32_
      %125 = cute.get_shape(%lay_466) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_467, %e1_468, %e2_469, %e3_470, %e4_471 = cute.get_leaves(%125) : !cute.shape<"((1,(4,4)),1,1)">
      %int_tuple_472 = cute.make_int_tuple() : () -> !cute.int_tuple<"((1,(4,4)),1,1)">
      %sz_473 = cute.size(%int_tuple_472) : (!cute.int_tuple<"((1,(4,4)),1,1)">) -> !cute.int_tuple<"16">
      %e0_474 = cute.get_leaves(%sz_473) : !cute.int_tuple<"16">
      %int_tuple_475 = cute.make_int_tuple() : () -> !cute.int_tuple<"((1,(4,4)),1,1)">
      %sz_476 = cute.size(%int_tuple_475) : (!cute.int_tuple<"((1,(4,4)),1,1)">) -> !cute.int_tuple<"16">
      %e0_477 = cute.get_leaves(%sz_476) : !cute.int_tuple<"16">
      cute.memref.store_vec %124, %rmem_214, row_major : !memref_rmem_f32_
      %lay_478 = cute.get_layout(%view_201) : !memref_gmem_f32_2
      %126 = cute.get_shape(%lay_478) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_479, %e1_480, %e2_481, %e3_482, %e4_483 = cute.get_leaves(%126) : !cute.shape<"((1,(4,4)),1,1)">
      %lay_484 = cute.get_layout(%rmem_214) : !memref_rmem_f32_
      %shape_485 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_486 = cute.make_layout() : !cute.layout<"1:0">
      %append_487 = cute.append_to_rank<2> (%lay_484, %lay_486) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
      %view_488 = cute.make_view(%iter_216, %append_487) : !memref_rmem_f32_
      %iter_489 = cute.get_iter(%view_488) : !memref_rmem_f32_
      %lay_490 = cute.get_layout(%view_488) : !memref_rmem_f32_
      %127 = cute.get_shape(%lay_490) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_491, %e1_492, %e2_493, %e3_494, %e4_495 = cute.get_leaves(%127) : !cute.shape<"((1,(4,4)),1,1)">
      %iter_496 = cute.get_iter(%view_488) : !memref_rmem_f32_
      %view_497 = cute.make_view(%iter_496) : !memref_rmem_f32_1
      %iter_498 = cute.get_iter(%view_497) : !memref_rmem_f32_1
      %iter_499 = cute.get_iter(%view_497) : !memref_rmem_f32_1
      %lay_500 = cute.get_layout(%view_201) : !memref_gmem_f32_2
      %shape_501 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_502 = cute.make_layout() : !cute.layout<"1:0">
      %append_503 = cute.append_to_rank<2> (%lay_500, %lay_502) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">
      %view_504 = cute.make_view(%iter_202, %append_503) : !memref_gmem_f32_2
      %iter_505 = cute.get_iter(%view_504) : !memref_gmem_f32_2
      %lay_506 = cute.get_layout(%view_504) : !memref_gmem_f32_2
      %128 = cute.get_shape(%lay_506) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_507, %e1_508, %e2_509, %e3_510, %e4_511 = cute.get_leaves(%128) : !cute.shape<"((1,(4,4)),1,1)">
      %iter_512 = cute.get_iter(%view_504) : !memref_gmem_f32_2
      %lay_513 = cute.get_layout(%view_504) : !memref_gmem_f32_2
      %129 = cute.get_scalars(%lay_513) <{only_dynamic}> : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %shape_514 = cute.make_shape() : () -> !cute.shape<"((1,(4,4)),(1,1))">
      %stride_515 = cute.make_stride(%129) : (i64) -> !cute.stride<"((0,(1,?{i64})),(0,0))">
      %lay_516 = cute.make_layout(%shape_514, %stride_515) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %view_517 = cute.make_view(%iter_512, %lay_516) : !memref_gmem_f32_3
      %iter_518 = cute.get_iter(%view_517) : !memref_gmem_f32_3
      %iter_519 = cute.get_iter(%view_517) : !memref_gmem_f32_3
      %lay_520 = cute.get_layout(%97) : !memref_rmem_i8_
      %shape_521 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_522 = cute.make_layout() : !cute.layout<"1:0">
      %append_523 = cute.append_to_rank<2> (%lay_520, %lay_522) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
      %view_524 = cute.make_view(%iter_268, %append_523) : !memref_rmem_i8_
      %iter_525 = cute.get_iter(%view_524) : !memref_rmem_i8_
      %lay_526 = cute.get_layout(%view_524) : !memref_rmem_i8_
      %130 = cute.get_shape(%lay_526) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_527, %e1_528, %e2_529, %e3_530, %e4_531 = cute.get_leaves(%130) : !cute.shape<"((1,(4,4)),1,1)">
      %iter_532 = cute.get_iter(%view_524) : !memref_rmem_i8_
      %view_533 = cute.make_view(%iter_532) : !memref_rmem_i8_1
      %iter_534 = cute.get_iter(%view_533) : !memref_rmem_i8_1
      %iter_535 = cute.get_iter(%view_533) : !memref_rmem_i8_1
      %lay_536 = cute.get_layout(%view_497) : !memref_rmem_f32_1
      %131 = cute.get_shape(%lay_536) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
      %e0_537, %e1_538, %e2_539, %e3_540, %e4_541 = cute.get_leaves(%131) : !cute.shape<"((1,(4,4)),(1,1))">
      %lay_542 = cute.get_layout(%view_517) : !memref_gmem_f32_3
      %132 = cute.get_shape(%lay_542) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
      %e0_543, %e1_544, %e2_545, %e3_546, %e4_547 = cute.get_leaves(%132) : !cute.shape<"((1,(4,4)),(1,1))">
      %lay_548 = cute.get_layout(%view_497) : !memref_rmem_f32_1
      %sz_549 = cute.size(%lay_548) <{mode = [1]}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.int_tuple<"1">
      %e0_550 = cute.get_leaves(%sz_549) : !cute.int_tuple<"1">
      %lay_551 = cute.get_layout(%view_517) : !memref_gmem_f32_3
      %sz_552 = cute.size(%lay_551) <{mode = [1]}> : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.int_tuple<"1">
      %e0_553 = cute.get_leaves(%sz_552) : !cute.int_tuple<"1">
      %133 = cute.static : !cute.layout<"1:0">
      %iter_554 = cute.get_iter(%view_497) : !memref_rmem_f32_1
      %iter_555 = cute.get_iter(%view_517) : !memref_gmem_f32_3
      %lay_556 = cute.get_layout(%view_497) : !memref_rmem_f32_1
      %lay_557 = cute.get_layout(%view_517) : !memref_gmem_f32_3
      %append_558 = cute.append_to_rank<2> (%lay_556, %133) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">, !cute.layout<"1:0">
      %append_559 = cute.append_to_rank<2> (%lay_557, %133) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">, !cute.layout<"1:0">
      %lay_560 = cute.make_layout() : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">
      %134 = cute.get_scalars(%append_559) <{only_dynamic}> : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %shape_561 = cute.make_shape() : () -> !cute.shape<"((1,(4,4)),((1,1)))">
      %stride_562 = cute.make_stride(%134) : (i64) -> !cute.stride<"((0,(1,?{i64})),((0,0)))">
      %lay_563 = cute.make_layout(%shape_561, %stride_562) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
      %iter_564 = cute.get_iter(%view_533) : !memref_rmem_i8_1
      %lay_565 = cute.get_layout(%view_533) : !memref_rmem_i8_1
      %append_566 = cute.append_to_rank<2> (%lay_565, %133) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">, !cute.layout<"1:0">
      %lay_567 = cute.make_layout() : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">
      %sz_568 = cute.size(%lay_560) <{mode = [1]}> : (!cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">) -> !cute.int_tuple<"1">
      %135 = cute.get_scalars(%sz_568) : !cute.int_tuple<"1">
      %c0_i32_569 = arith.constant 0 : i32
      %c1_i32_570 = arith.constant 1 : i32
      scf.for %arg6 = %c0_i32_569 to %135 step %c1_i32_570  : i32 {
        %coord_571 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
        %136 = cute.get_scalars(%coord_571) <{only_dynamic}> : !cute.coord<"(_,?)">
        %lay_572 = cute.make_layout() : !cute.layout<"((1,(4,4))):((0,(1,4)))">
        %idx_573 = cute.crd2idx(%coord_571, %lay_560) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">) -> !cute.int_tuple<"0">
        %ptr_574 = cute.add_offset(%iter_554, %idx_573) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, rmem, align<32>>
        %view_575 = cute.make_view(%ptr_574, %lay_572) : !memref_rmem_f32_2
        %137 = cute.get_scalars(%lay_563) <{only_dynamic}> : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
        %138 = cute.get_scalars(%coord_571) <{only_dynamic}> : !cute.coord<"(_,?)">
        %shape_576 = cute.make_shape() : () -> !cute.shape<"((1,(4,4)))">
        %stride_577 = cute.make_stride(%137) : (i64) -> !cute.stride<"((0,(1,?{i64})))">
        %lay_578 = cute.make_layout(%shape_576, %stride_577) : !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
        %idx_579 = cute.crd2idx(%coord_571, %lay_563) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">) -> !cute.int_tuple<"0">
        %ptr_580 = cute.add_offset(%iter_555, %idx_579) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<f32, gmem>
        %view_581 = cute.make_view(%ptr_580, %lay_578) : !memref_gmem_f32_4
        %139 = cute.get_scalars(%coord_571) <{only_dynamic}> : !cute.coord<"(_,?)">
        %lay_582 = cute.make_layout() : !cute.layout<"((1,(4,4))):((0,(1,4)))">
        %idx_583 = cute.crd2idx(%coord_571, %lay_567) : (!cute.coord<"(_,?)">, !cute.layout<"((1,(4,4)),((1,1))):((0,(1,4)),((0,0)))">) -> !cute.int_tuple<"0">
        %ptr_584 = cute.add_offset(%iter_564, %idx_583) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
        %view_585 = cute.make_view(%ptr_584, %lay_582) : !memref_rmem_i8_2
        %iter_586 = cute.get_iter(%view_575) : !memref_rmem_f32_2
        %iter_587 = cute.get_iter(%view_581) : !memref_gmem_f32_4
        %lay_588 = cute.get_layout(%view_581) : !memref_gmem_f32_4
        %140 = cute.get_scalars(%lay_588) <{only_dynamic}> : !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
        %iter_589 = cute.get_iter(%view_585) : !memref_rmem_i8_2
        %141 = builtin.unrealized_conversion_cast %iter_589 : !cute.ptr<i8, rmem, align<32>> to !llvm.ptr
        %142 = llvm.load %141 : !llvm.ptr -> i8
        %143 = llvm.mlir.constant(0 : i8) : i8
        %144 = llvm.icmp "ne" %142, %143 : i8
        scf.if %144 {
          %205 = builtin.unrealized_conversion_cast %iter_586 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
          %206 = builtin.unrealized_conversion_cast %iter_587 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %207 = llvm.load %205 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %207, %206 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %int_tuple_590 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
        %ptr_591 = cute.add_offset(%iter_589, %int_tuple_590) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
        %145 = builtin.unrealized_conversion_cast %ptr_591 : !cute.ptr<i8, rmem> to !llvm.ptr
        %146 = llvm.load %145 : !llvm.ptr -> i8
        %147 = llvm.mlir.constant(0 : i8) : i8
        %148 = llvm.icmp "ne" %146, %147 : i8
        scf.if %148 {
          %int_tuple_620 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
          %ptr_621 = cute.add_offset(%iter_586, %int_tuple_620) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
          %int_tuple_622 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
          %ptr_623 = cute.add_offset(%iter_587, %int_tuple_622) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
          %205 = builtin.unrealized_conversion_cast %ptr_621 : !cute.ptr<f32, rmem> to !llvm.ptr
          %206 = builtin.unrealized_conversion_cast %ptr_623 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %207 = llvm.load %205 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %207, %206 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %int_tuple_592 = cute.make_int_tuple() : () -> !cute.int_tuple<"2">
        %ptr_593 = cute.add_offset(%iter_589, %int_tuple_592) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem, align<2>>
        %149 = builtin.unrealized_conversion_cast %ptr_593 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
        %150 = llvm.load %149 : !llvm.ptr -> i8
        %151 = llvm.mlir.constant(0 : i8) : i8
        %152 = llvm.icmp "ne" %150, %151 : i8
        scf.if %152 {
          %int_tuple_620 = cute.make_int_tuple() : () -> !cute.int_tuple<"2">
          %ptr_621 = cute.add_offset(%iter_586, %int_tuple_620) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
          %int_tuple_622 = cute.make_int_tuple() : () -> !cute.int_tuple<"2">
          %ptr_623 = cute.add_offset(%iter_587, %int_tuple_622) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
          %205 = builtin.unrealized_conversion_cast %ptr_621 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %206 = builtin.unrealized_conversion_cast %ptr_623 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %207 = llvm.load %205 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %207, %206 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %int_tuple_594 = cute.make_int_tuple() : () -> !cute.int_tuple<"3">
        %ptr_595 = cute.add_offset(%iter_589, %int_tuple_594) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
        %153 = builtin.unrealized_conversion_cast %ptr_595 : !cute.ptr<i8, rmem> to !llvm.ptr
        %154 = llvm.load %153 : !llvm.ptr -> i8
        %155 = llvm.mlir.constant(0 : i8) : i8
        %156 = llvm.icmp "ne" %154, %155 : i8
        scf.if %156 {
          %int_tuple_620 = cute.make_int_tuple() : () -> !cute.int_tuple<"3">
          %ptr_621 = cute.add_offset(%iter_586, %int_tuple_620) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
          %int_tuple_622 = cute.make_int_tuple() : () -> !cute.int_tuple<"3">
          %ptr_623 = cute.add_offset(%iter_587, %int_tuple_622) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
          %205 = builtin.unrealized_conversion_cast %ptr_621 : !cute.ptr<f32, rmem> to !llvm.ptr
          %206 = builtin.unrealized_conversion_cast %ptr_623 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %207 = llvm.load %205 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %207, %206 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %int_tuple_596 = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
        %ptr_597 = cute.add_offset(%iter_589, %int_tuple_596) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem, align<4>>
        %157 = builtin.unrealized_conversion_cast %ptr_597 : !cute.ptr<i8, rmem, align<4>> to !llvm.ptr
        %158 = llvm.load %157 : !llvm.ptr -> i8
        %159 = llvm.mlir.constant(0 : i8) : i8
        %160 = llvm.icmp "ne" %158, %159 : i8
        scf.if %160 {
          %int_tuple_620 = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
          %ptr_621 = cute.add_offset(%iter_586, %int_tuple_620) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
          %int_tuple_622 = cute.make_int_tuple(%140) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_623 = cute.add_offset(%iter_587, %int_tuple_622) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %205 = builtin.unrealized_conversion_cast %ptr_621 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
          %206 = builtin.unrealized_conversion_cast %ptr_623 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %207 = llvm.load %205 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %207, %206 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %int_tuple_598 = cute.make_int_tuple() : () -> !cute.int_tuple<"5">
        %ptr_599 = cute.add_offset(%iter_589, %int_tuple_598) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
        %161 = builtin.unrealized_conversion_cast %ptr_599 : !cute.ptr<i8, rmem> to !llvm.ptr
        %162 = llvm.load %161 : !llvm.ptr -> i8
        %163 = llvm.mlir.constant(0 : i8) : i8
        %164 = llvm.icmp "ne" %162, %163 : i8
        scf.if %164 {
          %int_tuple_620 = cute.make_int_tuple() : () -> !cute.int_tuple<"5">
          %ptr_621 = cute.add_offset(%iter_586, %int_tuple_620) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<f32, rmem>
          %c1_i64 = arith.constant 1 : i64
          %205 = arith.addi %140, %c1_i64 : i64
          %int_tuple_622 = cute.make_int_tuple(%205) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_623 = cute.add_offset(%iter_587, %int_tuple_622) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %206 = builtin.unrealized_conversion_cast %ptr_621 : !cute.ptr<f32, rmem> to !llvm.ptr
          %207 = builtin.unrealized_conversion_cast %ptr_623 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %208 = llvm.load %206 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %208, %207 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %int_tuple_600 = cute.make_int_tuple() : () -> !cute.int_tuple<"6">
        %ptr_601 = cute.add_offset(%iter_589, %int_tuple_600) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem, align<2>>
        %165 = builtin.unrealized_conversion_cast %ptr_601 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
        %166 = llvm.load %165 : !llvm.ptr -> i8
        %167 = llvm.mlir.constant(0 : i8) : i8
        %168 = llvm.icmp "ne" %166, %167 : i8
        scf.if %168 {
          %int_tuple_620 = cute.make_int_tuple() : () -> !cute.int_tuple<"6">
          %ptr_621 = cute.add_offset(%iter_586, %int_tuple_620) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
          %c2_i64 = arith.constant 2 : i64
          %205 = arith.addi %140, %c2_i64 : i64
          %int_tuple_622 = cute.make_int_tuple(%205) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_623 = cute.add_offset(%iter_587, %int_tuple_622) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %206 = builtin.unrealized_conversion_cast %ptr_621 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %207 = builtin.unrealized_conversion_cast %ptr_623 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %208 = llvm.load %206 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %208, %207 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %int_tuple_602 = cute.make_int_tuple() : () -> !cute.int_tuple<"7">
        %ptr_603 = cute.add_offset(%iter_589, %int_tuple_602) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
        %169 = builtin.unrealized_conversion_cast %ptr_603 : !cute.ptr<i8, rmem> to !llvm.ptr
        %170 = llvm.load %169 : !llvm.ptr -> i8
        %171 = llvm.mlir.constant(0 : i8) : i8
        %172 = llvm.icmp "ne" %170, %171 : i8
        scf.if %172 {
          %int_tuple_620 = cute.make_int_tuple() : () -> !cute.int_tuple<"7">
          %ptr_621 = cute.add_offset(%iter_586, %int_tuple_620) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<f32, rmem>
          %c3_i64 = arith.constant 3 : i64
          %205 = arith.addi %140, %c3_i64 : i64
          %int_tuple_622 = cute.make_int_tuple(%205) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_623 = cute.add_offset(%iter_587, %int_tuple_622) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %206 = builtin.unrealized_conversion_cast %ptr_621 : !cute.ptr<f32, rmem> to !llvm.ptr
          %207 = builtin.unrealized_conversion_cast %ptr_623 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %208 = llvm.load %206 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %208, %207 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %int_tuple_604 = cute.make_int_tuple() : () -> !cute.int_tuple<"8">
        %ptr_605 = cute.add_offset(%iter_589, %int_tuple_604) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<i8, rmem, align<8>>
        %173 = builtin.unrealized_conversion_cast %ptr_605 : !cute.ptr<i8, rmem, align<8>> to !llvm.ptr
        %174 = llvm.load %173 : !llvm.ptr -> i8
        %175 = llvm.mlir.constant(0 : i8) : i8
        %176 = llvm.icmp "ne" %174, %175 : i8
        scf.if %176 {
          %int_tuple_620 = cute.make_int_tuple() : () -> !cute.int_tuple<"8">
          %ptr_621 = cute.add_offset(%iter_586, %int_tuple_620) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<f32, rmem, align<32>>
          %c2_i64 = arith.constant 2 : i64
          %205 = arith.muli %140, %c2_i64 : i64
          %iv_622 = cute.assume(%205) : (i64) -> !cute.i64<divby 2>
          %int_tuple_623 = cute.make_int_tuple(%iv_622) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
          %ptr_624 = cute.add_offset(%iter_587, %int_tuple_623) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
          %206 = builtin.unrealized_conversion_cast %ptr_621 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
          %207 = builtin.unrealized_conversion_cast %ptr_624 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %208 = llvm.load %206 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %208, %207 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %int_tuple_606 = cute.make_int_tuple() : () -> !cute.int_tuple<"9">
        %ptr_607 = cute.add_offset(%iter_589, %int_tuple_606) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<i8, rmem>
        %177 = builtin.unrealized_conversion_cast %ptr_607 : !cute.ptr<i8, rmem> to !llvm.ptr
        %178 = llvm.load %177 : !llvm.ptr -> i8
        %179 = llvm.mlir.constant(0 : i8) : i8
        %180 = llvm.icmp "ne" %178, %179 : i8
        scf.if %180 {
          %int_tuple_620 = cute.make_int_tuple() : () -> !cute.int_tuple<"9">
          %ptr_621 = cute.add_offset(%iter_586, %int_tuple_620) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<f32, rmem>
          %c2_i64 = arith.constant 2 : i64
          %205 = arith.muli %140, %c2_i64 : i64
          %c1_i64 = arith.constant 1 : i64
          %206 = arith.addi %205, %c1_i64 : i64
          %int_tuple_622 = cute.make_int_tuple(%206) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_623 = cute.add_offset(%iter_587, %int_tuple_622) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %207 = builtin.unrealized_conversion_cast %ptr_621 : !cute.ptr<f32, rmem> to !llvm.ptr
          %208 = builtin.unrealized_conversion_cast %ptr_623 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %209 = llvm.load %207 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %209, %208 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %int_tuple_608 = cute.make_int_tuple() : () -> !cute.int_tuple<"10">
        %ptr_609 = cute.add_offset(%iter_589, %int_tuple_608) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<i8, rmem, align<2>>
        %181 = builtin.unrealized_conversion_cast %ptr_609 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
        %182 = llvm.load %181 : !llvm.ptr -> i8
        %183 = llvm.mlir.constant(0 : i8) : i8
        %184 = llvm.icmp "ne" %182, %183 : i8
        scf.if %184 {
          %int_tuple_620 = cute.make_int_tuple() : () -> !cute.int_tuple<"10">
          %ptr_621 = cute.add_offset(%iter_586, %int_tuple_620) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<f32, rmem, align<8>>
          %c2_i64 = arith.constant 2 : i64
          %205 = arith.muli %140, %c2_i64 : i64
          %c2_i64_622 = arith.constant 2 : i64
          %206 = arith.addi %205, %c2_i64_622 : i64
          %iv_623 = cute.assume(%206) : (i64) -> !cute.i64<divby 2>
          %int_tuple_624 = cute.make_int_tuple(%iv_623) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
          %ptr_625 = cute.add_offset(%iter_587, %int_tuple_624) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
          %207 = builtin.unrealized_conversion_cast %ptr_621 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %208 = builtin.unrealized_conversion_cast %ptr_625 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %209 = llvm.load %207 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %209, %208 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %int_tuple_610 = cute.make_int_tuple() : () -> !cute.int_tuple<"11">
        %ptr_611 = cute.add_offset(%iter_589, %int_tuple_610) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<i8, rmem>
        %185 = builtin.unrealized_conversion_cast %ptr_611 : !cute.ptr<i8, rmem> to !llvm.ptr
        %186 = llvm.load %185 : !llvm.ptr -> i8
        %187 = llvm.mlir.constant(0 : i8) : i8
        %188 = llvm.icmp "ne" %186, %187 : i8
        scf.if %188 {
          %int_tuple_620 = cute.make_int_tuple() : () -> !cute.int_tuple<"11">
          %ptr_621 = cute.add_offset(%iter_586, %int_tuple_620) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<f32, rmem>
          %c2_i64 = arith.constant 2 : i64
          %205 = arith.muli %140, %c2_i64 : i64
          %c3_i64 = arith.constant 3 : i64
          %206 = arith.addi %205, %c3_i64 : i64
          %int_tuple_622 = cute.make_int_tuple(%206) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_623 = cute.add_offset(%iter_587, %int_tuple_622) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %207 = builtin.unrealized_conversion_cast %ptr_621 : !cute.ptr<f32, rmem> to !llvm.ptr
          %208 = builtin.unrealized_conversion_cast %ptr_623 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %209 = llvm.load %207 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %209, %208 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %int_tuple_612 = cute.make_int_tuple() : () -> !cute.int_tuple<"12">
        %ptr_613 = cute.add_offset(%iter_589, %int_tuple_612) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<i8, rmem, align<4>>
        %189 = builtin.unrealized_conversion_cast %ptr_613 : !cute.ptr<i8, rmem, align<4>> to !llvm.ptr
        %190 = llvm.load %189 : !llvm.ptr -> i8
        %191 = llvm.mlir.constant(0 : i8) : i8
        %192 = llvm.icmp "ne" %190, %191 : i8
        scf.if %192 {
          %int_tuple_620 = cute.make_int_tuple() : () -> !cute.int_tuple<"12">
          %ptr_621 = cute.add_offset(%iter_586, %int_tuple_620) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<f32, rmem, align<16>>
          %c3_i64 = arith.constant 3 : i64
          %205 = arith.muli %140, %c3_i64 : i64
          %iv_622 = cute.assume(%205) : (i64) -> !cute.i64<divby 3>
          %int_tuple_623 = cute.make_int_tuple(%iv_622) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
          %ptr_624 = cute.add_offset(%iter_587, %int_tuple_623) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
          %206 = builtin.unrealized_conversion_cast %ptr_621 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
          %207 = builtin.unrealized_conversion_cast %ptr_624 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %208 = llvm.load %206 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %208, %207 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %int_tuple_614 = cute.make_int_tuple() : () -> !cute.int_tuple<"13">
        %ptr_615 = cute.add_offset(%iter_589, %int_tuple_614) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<i8, rmem>
        %193 = builtin.unrealized_conversion_cast %ptr_615 : !cute.ptr<i8, rmem> to !llvm.ptr
        %194 = llvm.load %193 : !llvm.ptr -> i8
        %195 = llvm.mlir.constant(0 : i8) : i8
        %196 = llvm.icmp "ne" %194, %195 : i8
        scf.if %196 {
          %int_tuple_620 = cute.make_int_tuple() : () -> !cute.int_tuple<"13">
          %ptr_621 = cute.add_offset(%iter_586, %int_tuple_620) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<f32, rmem>
          %c3_i64 = arith.constant 3 : i64
          %205 = arith.muli %140, %c3_i64 : i64
          %c1_i64 = arith.constant 1 : i64
          %206 = arith.addi %205, %c1_i64 : i64
          %int_tuple_622 = cute.make_int_tuple(%206) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_623 = cute.add_offset(%iter_587, %int_tuple_622) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %207 = builtin.unrealized_conversion_cast %ptr_621 : !cute.ptr<f32, rmem> to !llvm.ptr
          %208 = builtin.unrealized_conversion_cast %ptr_623 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %209 = llvm.load %207 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %209, %208 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %int_tuple_616 = cute.make_int_tuple() : () -> !cute.int_tuple<"14">
        %ptr_617 = cute.add_offset(%iter_589, %int_tuple_616) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<i8, rmem, align<2>>
        %197 = builtin.unrealized_conversion_cast %ptr_617 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
        %198 = llvm.load %197 : !llvm.ptr -> i8
        %199 = llvm.mlir.constant(0 : i8) : i8
        %200 = llvm.icmp "ne" %198, %199 : i8
        scf.if %200 {
          %int_tuple_620 = cute.make_int_tuple() : () -> !cute.int_tuple<"14">
          %ptr_621 = cute.add_offset(%iter_586, %int_tuple_620) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<f32, rmem, align<8>>
          %c3_i64 = arith.constant 3 : i64
          %205 = arith.muli %140, %c3_i64 : i64
          %c2_i64 = arith.constant 2 : i64
          %206 = arith.addi %205, %c2_i64 : i64
          %int_tuple_622 = cute.make_int_tuple(%206) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_623 = cute.add_offset(%iter_587, %int_tuple_622) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %207 = builtin.unrealized_conversion_cast %ptr_621 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %208 = builtin.unrealized_conversion_cast %ptr_623 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %209 = llvm.load %207 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %209, %208 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %int_tuple_618 = cute.make_int_tuple() : () -> !cute.int_tuple<"15">
        %ptr_619 = cute.add_offset(%iter_589, %int_tuple_618) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<i8, rmem>
        %201 = builtin.unrealized_conversion_cast %ptr_619 : !cute.ptr<i8, rmem> to !llvm.ptr
        %202 = llvm.load %201 : !llvm.ptr -> i8
        %203 = llvm.mlir.constant(0 : i8) : i8
        %204 = llvm.icmp "ne" %202, %203 : i8
        scf.if %204 {
          %int_tuple_620 = cute.make_int_tuple() : () -> !cute.int_tuple<"15">
          %ptr_621 = cute.add_offset(%iter_586, %int_tuple_620) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<f32, rmem>
          %c3_i64 = arith.constant 3 : i64
          %205 = arith.muli %140, %c3_i64 : i64
          %c3_i64_622 = arith.constant 3 : i64
          %206 = arith.addi %205, %c3_i64_622 : i64
          %iv_623 = cute.assume(%206) : (i64) -> !cute.i64<divby 3>
          %int_tuple_624 = cute.make_int_tuple(%iv_623) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
          %ptr_625 = cute.add_offset(%iter_587, %int_tuple_624) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
          %207 = builtin.unrealized_conversion_cast %ptr_621 : !cute.ptr<f32, rmem> to !llvm.ptr
          %208 = builtin.unrealized_conversion_cast %ptr_625 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %209 = llvm.load %207 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %209, %208 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
      } {llvm.loop_annotation = #loop_annotation}
      return
    }
  }
  func.func @cutlass_elementwise_add_tensor_00795_21652_04639_03193_15897_02304_02971_12990_02319_03973_00495_05866_09467_06015_06234_07404_19793_05333_01425_01997_05745_11222_16922_13492_04451(%arg0: !memref_gmem_f32_5, %arg1: !memref_gmem_f32_5, %arg2: !memref_gmem_f32_5) attributes {llvm.emit_c_interface} {
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
    %63 = arith.index_cast %36 : i32 to index
    %c1 = arith.constant 1 : index
    %c128 = arith.constant 128 : index
    %c0_i32 = arith.constant 0 : i32
    gpu.launch_func  @kernels::@kernel_cutlass_elementwise_add_kernel_tensorptrf32gmemo161281div16128_tensorptrf32gmemo161281div16128_tensorptrf32gmemo161281div16128_tensor00o1612810111601281___0 blocks in (%63, %c1, %c1) threads in (%c128, %c1, %c1)  dynamic_shared_memory_size %c0_i32 args(%view : !memref_gmem_f32_, %view_66 : !memref_gmem_f32_, %view_79 : !memref_gmem_f32_, %view_103 : !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">, %31 : i32, %32 : i32) {use_pdl = false}
    return
  }
}
