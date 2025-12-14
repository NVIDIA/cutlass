!memref_gmem_f32_ = !cute.memref<f32, gmem, "((1024,1,1),(?,?,?)):((1,0,0),(1024,?{i64},?{i64}))">
!memref_gmem_f32_1 = !cute.memref<f32, gmem, "((1024,1,1)):((1,0,0))">
!memref_gmem_f32_2 = !cute.memref<f32, gmem, "(128,8):(8,1)">
!memref_gmem_f32_3 = !cute.memref<f32, gmem, "(8):(1)">
!memref_gmem_f32_4 = !cute.memref<f32, gmem, "(8,1):(1,0)">
!memref_gmem_f32_5 = !cute.memref<f32, gmem, "(8,(1)):(1,(0))">
!memref_gmem_f32_6 = !cute.memref<f32, gmem, "(?,?,?):(1,?{i64},?{i64})">
!memref_gmem_i4_ = !cute.memref<i4, gmem, align<128>, "(?,?,?):(1,?{i64},?{i64})">
!memref_gmem_i8_ = !cute.memref<i8, gmem, align<128>, "((512,1,1),(?,?,?)):((1,0,0),(512,?{i64},?{i64}))">
!memref_gmem_i8_1 = !cute.memref<i8, gmem, "((512,1,1)):((1,0,0))">
!memref_gmem_i8_2 = !cute.memref<i8, gmem, "(128,4):(4,1)">
!memref_gmem_i8_3 = !cute.memref<i8, gmem, "(4):(1)">
!memref_gmem_i8_4 = !cute.memref<i8, gmem, "(4,1):(1,0)">
!memref_gmem_i8_5 = !cute.memref<i8, gmem, "(4,(1)):(1,(0))">
!memref_gmem_i8_6 = !cute.memref<i8, gmem, align<128>, "(?,?,?):(1,?{i64},?{i64})">
!memref_rmem_f32_ = !cute.memref<f32, rmem, align<32>, "8:1">
!memref_rmem_f32_1 = !cute.memref<f32, rmem, align<32>, "(8,1):(1,0)">
!memref_rmem_f32_2 = !cute.memref<f32, rmem, align<32>, "(8,(1)):(1,(0))">
!memref_rmem_f32_3 = !cute.memref<f32, rmem, align<32>, "(8):(1)">
!memref_rmem_i8_ = !cute.memref<i8, rmem, align<32>, "4:1">
!memref_rmem_i8_1 = !cute.memref<i8, rmem, align<32>, "(4,1):(1,0)">
!memref_rmem_i8_2 = !cute.memref<i8, rmem, align<32>, "(4,(1)):(1,(0))">
!memref_rmem_i8_3 = !cute.memref<i8, rmem, align<32>, "(4):(1)">
#loop_unroll = #llvm.loop_unroll<disable = false, full = true>
#loop_annotation = #llvm.loop_annotation<unroll = #loop_unroll>
module attributes {gpu.container_module} {
  gpu.module @kernels {
    cuda.kernel @kernel_cutlass__convert_kernel_tensorptrf32gmemo1024111001024_tensorptri8gmemalign128o51211100512_tensor000o1024111000102401112____Float32_Int4_0(%arg0: !memref_gmem_f32_, %arg1: !memref_gmem_i8_, %arg2: !cute.coord_tensor<"(0,0,0)", "((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">, %arg3: i32, %arg4: i32, %arg5: i32) attributes {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} {
      %0 = cute.static : !cute.layout<"(128,8):(8,1)">
      %1 = cute.static : !cute.layout<"(128,4):(4,1)">
      %iter = cute.get_iter(%arg0) : !memref_gmem_f32_
      %iter_0 = cute.get_iter(%arg1) : !memref_gmem_i8_
      %iter_1 = cute.get_iter(%arg2) : !cute.coord_tensor<"(0,0,0)", "((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">
      %e0, %e1, %e2 = cute.get_leaves(%iter_1) : !cute.int_tuple<"(0,0,0)">
      %iter_2 = cute.get_iter(%arg0) : !memref_gmem_f32_
      %iter_3 = cute.get_iter(%arg1) : !memref_gmem_i8_
      %iter_4 = cute.get_iter(%arg2) : !cute.coord_tensor<"(0,0,0)", "((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">
      %e0_5, %e1_6, %e2_7 = cute.get_leaves(%iter_4) : !cute.int_tuple<"(0,0,0)">
      %lay = cute.get_layout(%arg0) : !memref_gmem_f32_
      %2 = cute.get_shape(%lay) : (!cute.layout<"((1024,1,1),(?,?,?)):((1,0,0),(1024,?{i64},?{i64}))">) -> !cute.shape<"((1024,1,1),(?,?,?))">
      %e0_8, %e1_9, %e2_10, %e3, %e4, %e5 = cute.get_leaves(%2) : !cute.shape<"((1024,1,1),(?,?,?))">
      %itup = cute.to_int_tuple(%e3) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %3 = cute.get_scalars(%itup) : !cute.int_tuple<"?">
      %itup_11 = cute.to_int_tuple(%e4) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %4 = cute.get_scalars(%itup_11) : !cute.int_tuple<"?">
      %itup_12 = cute.to_int_tuple(%e5) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %5 = cute.get_scalars(%itup_12) : !cute.int_tuple<"?">
      %6 = cute.get_stride(%lay) : (!cute.layout<"((1024,1,1),(?,?,?)):((1,0,0),(1024,?{i64},?{i64}))">) -> !cute.stride<"((1,0,0),(1024,?{i64},?{i64}))">
      %e0_13, %e1_14, %e2_15, %e3_16, %e4_17, %e5_18 = cute.get_leaves(%6) : !cute.stride<"((1,0,0),(1024,?{i64},?{i64}))">
      %itup_19 = cute.to_int_tuple(%e4_17) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
      %7 = cute.get_scalars(%itup_19) : !cute.int_tuple<"?{i64}">
      %itup_20 = cute.to_int_tuple(%e5_18) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
      %8 = cute.get_scalars(%itup_20) : !cute.int_tuple<"?{i64}">
      %lay_21 = cute.get_layout(%arg1) : !memref_gmem_i8_
      %9 = cute.get_shape(%lay_21) : (!cute.layout<"((512,1,1),(?,?,?)):((1,0,0),(512,?{i64},?{i64}))">) -> !cute.shape<"((512,1,1),(?,?,?))">
      %e0_22, %e1_23, %e2_24, %e3_25, %e4_26, %e5_27 = cute.get_leaves(%9) : !cute.shape<"((512,1,1),(?,?,?))">
      %itup_28 = cute.to_int_tuple(%e3_25) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %10 = cute.get_scalars(%itup_28) : !cute.int_tuple<"?">
      %itup_29 = cute.to_int_tuple(%e4_26) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %11 = cute.get_scalars(%itup_29) : !cute.int_tuple<"?">
      %itup_30 = cute.to_int_tuple(%e5_27) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %12 = cute.get_scalars(%itup_30) : !cute.int_tuple<"?">
      %13 = cute.get_stride(%lay_21) : (!cute.layout<"((512,1,1),(?,?,?)):((1,0,0),(512,?{i64},?{i64}))">) -> !cute.stride<"((1,0,0),(512,?{i64},?{i64}))">
      %e0_31, %e1_32, %e2_33, %e3_34, %e4_35, %e5_36 = cute.get_leaves(%13) : !cute.stride<"((1,0,0),(512,?{i64},?{i64}))">
      %itup_37 = cute.to_int_tuple(%e4_35) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
      %14 = cute.get_scalars(%itup_37) : !cute.int_tuple<"?{i64}">
      %itup_38 = cute.to_int_tuple(%e5_36) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
      %15 = cute.get_scalars(%itup_38) : !cute.int_tuple<"?{i64}">
      %lay_39 = cute.get_layout(%arg2) : !cute.coord_tensor<"(0,0,0)", "((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">
      %16 = cute.get_shape(%lay_39) : (!cute.layout<"((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">) -> !cute.shape<"((1024,1,1),(?,?,?))">
      %e0_40, %e1_41, %e2_42, %e3_43, %e4_44, %e5_45 = cute.get_leaves(%16) : !cute.shape<"((1024,1,1),(?,?,?))">
      %itup_46 = cute.to_int_tuple(%e3_43) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %17 = cute.get_scalars(%itup_46) : !cute.int_tuple<"?">
      %itup_47 = cute.to_int_tuple(%e4_44) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %18 = cute.get_scalars(%itup_47) : !cute.int_tuple<"?">
      %itup_48 = cute.to_int_tuple(%e5_45) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %19 = cute.get_scalars(%itup_48) : !cute.int_tuple<"?">
      %20 = cute.get_stride(%lay_39) : (!cute.layout<"((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">) -> !cute.stride<"((1@0,0,0),(1024@0,1@1,1@2))">
      %e0_49, %e1_50, %e2_51, %e3_52, %e4_53, %e5_54 = cute.get_leaves(%20) : !cute.stride<"((1@0,0,0),(1024@0,1@1,1@2))">
      %21 = cute.get_shape(%0) : (!cute.layout<"(128,8):(8,1)">) -> !cute.shape<"(128,8)">
      %e0_55, %e1_56 = cute.get_leaves(%21) : !cute.shape<"(128,8)">
      %22 = cute.get_stride(%0) : (!cute.layout<"(128,8):(8,1)">) -> !cute.stride<"(8,1)">
      %e0_57, %e1_58 = cute.get_leaves(%22) : !cute.stride<"(8,1)">
      %23 = cute.get_shape(%1) : (!cute.layout<"(128,4):(4,1)">) -> !cute.shape<"(128,4)">
      %e0_59, %e1_60 = cute.get_leaves(%23) : !cute.shape<"(128,4)">
      %24 = cute.get_stride(%1) : (!cute.layout<"(128,4):(4,1)">) -> !cute.stride<"(4,1)">
      %e0_61, %e1_62 = cute.get_leaves(%24) : !cute.stride<"(4,1)">
      %25 = nvvm.read.ptx.sreg.tid.x : i32
      %26 = nvvm.read.ptx.sreg.ctaid.x : i32
      %coord = cute.make_coord(%26) : (i32) -> !cute.coord<"(_,?)">
      %lay_63 = cute.get_layout(%arg0) : !memref_gmem_f32_
      %idx = cute.crd2idx(%coord, %lay_63) : (!cute.coord<"(_,?)">, !cute.layout<"((1024,1,1),(?,?,?)):((1,0,0),(1024,?{i64},?{i64}))">) -> !cute.int_tuple<"?{i64}">
      %iter_64 = cute.get_iter(%arg0) : !memref_gmem_f32_
      %ptr = cute.add_offset(%iter_64, %idx) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %view = cute.make_view(%ptr) : !memref_gmem_f32_1
      %iter_65 = cute.get_iter(%view) : !memref_gmem_f32_1
      %iter_66 = cute.get_iter(%view) : !memref_gmem_f32_1
      %coord_67 = cute.make_coord(%26) : (i32) -> !cute.coord<"(_,?)">
      %lay_68 = cute.get_layout(%arg1) : !memref_gmem_i8_
      %idx_69 = cute.crd2idx(%coord_67, %lay_68) : (!cute.coord<"(_,?)">, !cute.layout<"((512,1,1),(?,?,?)):((1,0,0),(512,?{i64},?{i64}))">) -> !cute.int_tuple<"?{i64}">
      %iter_70 = cute.get_iter(%arg1) : !memref_gmem_i8_
      %ptr_71 = cute.add_offset(%iter_70, %idx_69) : (!cute.ptr<i8, gmem, align<128>>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<i8, gmem>
      %view_72 = cute.make_view(%ptr_71) : !memref_gmem_i8_1
      %iter_73 = cute.get_iter(%view_72) : !memref_gmem_i8_1
      %iter_74 = cute.get_iter(%view_72) : !memref_gmem_i8_1
      %coord_75 = cute.make_coord(%26) : (i32) -> !cute.coord<"(_,?)">
      %lay_76 = cute.get_layout(%arg2) : !cute.coord_tensor<"(0,0,0)", "((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">
      %idx_77 = cute.crd2idx(%coord_75, %lay_76) : (!cute.coord<"(_,?)">, !cute.layout<"((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">) -> !cute.int_tuple<"(?{div=1024},?,?)">
      %iter_78 = cute.get_iter(%arg2) : !cute.coord_tensor<"(0,0,0)", "((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">
      %tup = cute.add_offset(%iter_78, %idx_77) : (!cute.int_tuple<"(0,0,0)">, !cute.int_tuple<"(?{div=1024},?,?)">) -> !cute.int_tuple<"(?{div=1024},?,?)">
      %view_79 = cute.make_view(%tup) : !cute.coord_tensor<"(?{div=1024},?,?)", "((1024,1,1)):((1@0,0,0))">
      %iter_80 = cute.get_iter(%view_79) : !cute.coord_tensor<"(?{div=1024},?,?)", "((1024,1,1)):((1@0,0,0))">
      %e0_81, %e1_82, %e2_83 = cute.get_leaves(%iter_80) : !cute.int_tuple<"(?{div=1024},?,?)">
      %27 = cute.get_scalars(%e0_81) : !cute.int_tuple<"?{div=1024}">
      %28 = cute.get_scalars(%e1_82) : !cute.int_tuple<"?">
      %29 = cute.get_scalars(%e2_83) : !cute.int_tuple<"?">
      %iter_84 = cute.get_iter(%view_79) : !cute.coord_tensor<"(?{div=1024},?,?)", "((1024,1,1)):((1@0,0,0))">
      %e0_85, %e1_86, %e2_87 = cute.get_leaves(%iter_84) : !cute.int_tuple<"(?{div=1024},?,?)">
      %30 = cute.get_scalars(%e0_85) : !cute.int_tuple<"?{div=1024}">
      %31 = cute.get_scalars(%e1_86) : !cute.int_tuple<"?">
      %32 = cute.get_scalars(%e2_87) : !cute.int_tuple<"?">
      %iter_88 = cute.get_iter(%view) : !memref_gmem_f32_1
      %view_89 = cute.make_view(%iter_88) : !memref_gmem_f32_2
      %iter_90 = cute.get_iter(%view_89) : !memref_gmem_f32_2
      %iter_91 = cute.get_iter(%view_72) : !memref_gmem_i8_1
      %view_92 = cute.make_view(%iter_91) : !memref_gmem_i8_2
      %iter_93 = cute.get_iter(%view_92) : !memref_gmem_i8_2
      %iter_94 = cute.get_iter(%view_79) : !cute.coord_tensor<"(?{div=1024},?,?)", "((1024,1,1)):((1@0,0,0))">
      %view_95 = cute.make_view(%iter_94) : !cute.coord_tensor<"(?{div=1024},?,?)", "(128,8):(8@0,1@0)">
      %iter_96 = cute.get_iter(%view_95) : !cute.coord_tensor<"(?{div=1024},?,?)", "(128,8):(8@0,1@0)">
      %e0_97, %e1_98, %e2_99 = cute.get_leaves(%iter_96) : !cute.int_tuple<"(?{div=1024},?,?)">
      %33 = cute.get_scalars(%e0_97) : !cute.int_tuple<"?{div=1024}">
      %34 = cute.get_scalars(%e1_98) : !cute.int_tuple<"?">
      %35 = cute.get_scalars(%e2_99) : !cute.int_tuple<"?">
      %coord_100 = cute.make_coord(%25) : (i32) -> !cute.coord<"(?,_)">
      %lay_101 = cute.get_layout(%view_89) : !memref_gmem_f32_2
      %idx_102 = cute.crd2idx(%coord_100, %lay_101) : (!cute.coord<"(?,_)">, !cute.layout<"(128,8):(8,1)">) -> !cute.int_tuple<"?{div=8}">
      %iter_103 = cute.get_iter(%view_89) : !memref_gmem_f32_2
      %ptr_104 = cute.add_offset(%iter_103, %idx_102) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f32, gmem>
      %view_105 = cute.make_view(%ptr_104) : !memref_gmem_f32_3
      %iter_106 = cute.get_iter(%view_105) : !memref_gmem_f32_3
      %iter_107 = cute.get_iter(%view_105) : !memref_gmem_f32_3
      %coord_108 = cute.make_coord(%25) : (i32) -> !cute.coord<"(?,_)">
      %lay_109 = cute.get_layout(%view_92) : !memref_gmem_i8_2
      %idx_110 = cute.crd2idx(%coord_108, %lay_109) : (!cute.coord<"(?,_)">, !cute.layout<"(128,4):(4,1)">) -> !cute.int_tuple<"?{div=4}">
      %iter_111 = cute.get_iter(%view_92) : !memref_gmem_i8_2
      %ptr_112 = cute.add_offset(%iter_111, %idx_110) : (!cute.ptr<i8, gmem>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<i8, gmem>
      %view_113 = cute.make_view(%ptr_112) : !memref_gmem_i8_3
      %iter_114 = cute.get_iter(%view_113) : !memref_gmem_i8_3
      %iter_115 = cute.get_iter(%view_113) : !memref_gmem_i8_3
      %coord_116 = cute.make_coord(%25) : (i32) -> !cute.coord<"(?,_)">
      %lay_117 = cute.get_layout(%view_95) : !cute.coord_tensor<"(?{div=1024},?,?)", "(128,8):(8@0,1@0)">
      %idx_118 = cute.crd2idx(%coord_116, %lay_117) : (!cute.coord<"(?,_)">, !cute.layout<"(128,8):(8@0,1@0)">) -> !cute.int_tuple<"(?{div=8})">
      %iter_119 = cute.get_iter(%view_95) : !cute.coord_tensor<"(?{div=1024},?,?)", "(128,8):(8@0,1@0)">
      %tup_120 = cute.add_offset(%iter_119, %idx_118) : (!cute.int_tuple<"(?{div=1024},?,?)">, !cute.int_tuple<"(?{div=8})">) -> !cute.int_tuple<"(?{div=8},?,?)">
      %view_121 = cute.make_view(%tup_120) : !cute.coord_tensor<"(?{div=8},?,?)", "(8):(1@0)">
      %iter_122 = cute.get_iter(%view_121) : !cute.coord_tensor<"(?{div=8},?,?)", "(8):(1@0)">
      %e0_123, %e1_124, %e2_125 = cute.get_leaves(%iter_122) : !cute.int_tuple<"(?{div=8},?,?)">
      %36 = cute.get_scalars(%e0_123) : !cute.int_tuple<"?{div=8}">
      %37 = cute.get_scalars(%e1_124) : !cute.int_tuple<"?">
      %38 = cute.get_scalars(%e2_125) : !cute.int_tuple<"?">
      %iter_126 = cute.get_iter(%view_121) : !cute.coord_tensor<"(?{div=8},?,?)", "(8):(1@0)">
      %e0_127, %e1_128, %e2_129 = cute.get_leaves(%iter_126) : !cute.int_tuple<"(?{div=8},?,?)">
      %39 = cute.get_scalars(%e0_127) : !cute.int_tuple<"?{div=8}">
      %40 = cute.get_scalars(%e1_128) : !cute.int_tuple<"?">
      %41 = cute.get_scalars(%e2_129) : !cute.int_tuple<"?">
      %coord_130 = cute.make_coord() : () -> !cute.coord<"0">
      %lay_131 = cute.get_layout(%view_121) : !cute.coord_tensor<"(?{div=8},?,?)", "(8):(1@0)">
      %idx_132 = cute.crd2idx(%coord_130, %lay_131) : (!cute.coord<"0">, !cute.layout<"(8):(1@0)">) -> !cute.int_tuple<"(0)">
      %iter_133 = cute.get_iter(%view_121) : !cute.coord_tensor<"(?{div=8},?,?)", "(8):(1@0)">
      %tup_134 = cute.add_offset(%iter_133, %idx_132) : (!cute.int_tuple<"(?{div=8},?,?)">, !cute.int_tuple<"(0)">) -> !cute.int_tuple<"(?{div=8},?,?)">
      %view_135 = cute.make_view(%tup_134) : !cute.coord_tensor<"(?{div=8},?,?)", "():()">
      %iter_136 = cute.get_iter(%view_135) : !cute.coord_tensor<"(?{div=8},?,?)", "():()">
      %e0_137, %e1_138, %e2_139 = cute.get_leaves(%iter_136) : !cute.int_tuple<"(?{div=8},?,?)">
      %42 = cute.get_scalars(%e0_137) : !cute.int_tuple<"?{div=8}">
      %43 = cute.get_scalars(%e1_138) : !cute.int_tuple<"?">
      %44 = cute.get_scalars(%e2_139) : !cute.int_tuple<"?">
      %iter_140 = cute.get_iter(%view_135) : !cute.coord_tensor<"(?{div=8},?,?)", "():()">
      %e0_141, %e1_142, %e2_143 = cute.get_leaves(%iter_140) : !cute.int_tuple<"(?{div=8},?,?)">
      %45 = cute.get_scalars(%e0_141) : !cute.int_tuple<"?{div=8}">
      %46 = cute.get_scalars(%e1_142) : !cute.int_tuple<"?">
      %47 = cute.get_scalars(%e2_143) : !cute.int_tuple<"?">
      %iter_144 = cute.get_iter(%view_135) : !cute.coord_tensor<"(?{div=8},?,?)", "():()">
      %e0_145, %e1_146, %e2_147 = cute.get_leaves(%iter_144) : !cute.int_tuple<"(?{div=8},?,?)">
      %48 = cute.get_scalars(%e0_145) : !cute.int_tuple<"?{div=8}">
      %49 = cute.get_scalars(%e1_146) : !cute.int_tuple<"?">
      %50 = cute.get_scalars(%e2_147) : !cute.int_tuple<"?">
      %coord_148 = cute.make_coord(%e0_145, %e1_146, %e2_147) : (!cute.int_tuple<"?{div=8}">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?{div=8},?,?)">
      %coord_149 = cute.make_coord(%arg3, %arg4, %arg5) : (i32, i32, i32) -> !cute.coord<"(?,?,?)">
      %51 = cute.elem_less(%coord_148, %coord_149) : !cute.coord<"(?{div=8},?,?)">, !cute.coord<"(?,?,?)">
      scf.if %51 {
        %52 = cute.get_shape(%0) : (!cute.layout<"(128,8):(8,1)">) -> !cute.shape<"(128,8)">
        %e0_150, %e1_151 = cute.get_leaves(%52) : !cute.shape<"(128,8)">
        %53 = cute.get_shape(%0) : (!cute.layout<"(128,8):(8,1)">) -> !cute.shape<"(128,8)">
        %e0_152, %e1_153 = cute.get_leaves(%53) : !cute.shape<"(128,8)">
        %54 = cute.get(%0) <{mode = [1]}> : !cute.layout<"(128,8):(8,1)"> -> !cute.layout<"8:1">
        %rmem = cute.memref.alloca(%54) : !memref_rmem_f32_
        %iter_154 = cute.get_iter(%rmem) : !memref_rmem_f32_
        %iter_155 = cute.get_iter(%rmem) : !memref_rmem_f32_
        %55 = cute.get_shape(%1) : (!cute.layout<"(128,4):(4,1)">) -> !cute.shape<"(128,4)">
        %e0_156, %e1_157 = cute.get_leaves(%55) : !cute.shape<"(128,4)">
        %56 = cute.get_shape(%1) : (!cute.layout<"(128,4):(4,1)">) -> !cute.shape<"(128,4)">
        %e0_158, %e1_159 = cute.get_leaves(%56) : !cute.shape<"(128,4)">
        %57 = cute.get(%1) <{mode = [1]}> : !cute.layout<"(128,4):(4,1)"> -> !cute.layout<"4:1">
        %rmem_160 = cute.memref.alloca(%57) : !memref_rmem_i8_
        %iter_161 = cute.get_iter(%rmem_160) : !memref_rmem_i8_
        %iter_162 = cute.get_iter(%rmem_160) : !memref_rmem_i8_
        %atom = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<f32>
        %lay_163 = cute.get_layout(%view_105) : !memref_gmem_f32_3
        %58 = cute.get_shape(%lay_163) : (!cute.layout<"(8):(1)">) -> !cute.shape<"(8)">
        %e0_164 = cute.get_leaves(%58) : !cute.shape<"(8)">
        %lay_165 = cute.get_layout(%rmem) : !memref_rmem_f32_
        %59 = cute.get_shape(%lay_165) : (!cute.layout<"8:1">) -> !cute.shape<"8">
        %e0_166 = cute.get_leaves(%59) : !cute.shape<"8">
        %lay_167 = cute.get_layout(%view_105) : !memref_gmem_f32_3
        %shape = cute.make_shape() : () -> !cute.shape<"1">
        %lay_168 = cute.make_layout() : !cute.layout<"1:0">
        %append = cute.append_to_rank<2> (%lay_167, %lay_168) : !cute.layout<"(8):(1)">, !cute.layout<"1:0">
        %view_169 = cute.make_view(%iter_107, %append) : !memref_gmem_f32_4
        %iter_170 = cute.get_iter(%view_169) : !memref_gmem_f32_4
        %lay_171 = cute.get_layout(%view_169) : !memref_gmem_f32_4
        %60 = cute.get_shape(%lay_171) : (!cute.layout<"(8,1):(1,0)">) -> !cute.shape<"(8,1)">
        %e0_172, %e1_173 = cute.get_leaves(%60) : !cute.shape<"(8,1)">
        %iter_174 = cute.get_iter(%view_169) : !memref_gmem_f32_4
        %view_175 = cute.make_view(%iter_174) : !memref_gmem_f32_5
        %iter_176 = cute.get_iter(%view_175) : !memref_gmem_f32_5
        %iter_177 = cute.get_iter(%view_175) : !memref_gmem_f32_5
        %lay_178 = cute.get_layout(%rmem) : !memref_rmem_f32_
        %shape_179 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_180 = cute.make_layout() : !cute.layout<"1:0">
        %append_181 = cute.append_to_rank<2> (%lay_178, %lay_180) : !cute.layout<"8:1">, !cute.layout<"1:0">
        %view_182 = cute.make_view(%iter_155, %append_181) : !memref_rmem_f32_1
        %iter_183 = cute.get_iter(%view_182) : !memref_rmem_f32_1
        %lay_184 = cute.get_layout(%view_182) : !memref_rmem_f32_1
        %61 = cute.get_shape(%lay_184) : (!cute.layout<"(8,1):(1,0)">) -> !cute.shape<"(8,1)">
        %e0_185, %e1_186 = cute.get_leaves(%61) : !cute.shape<"(8,1)">
        %iter_187 = cute.get_iter(%view_182) : !memref_rmem_f32_1
        %view_188 = cute.make_view(%iter_187) : !memref_rmem_f32_2
        %iter_189 = cute.get_iter(%view_188) : !memref_rmem_f32_2
        %iter_190 = cute.get_iter(%view_188) : !memref_rmem_f32_2
        %lay_191 = cute.get_layout(%view_175) : !memref_gmem_f32_5
        %62 = cute.get_shape(%lay_191) : (!cute.layout<"(8,(1)):(1,(0))">) -> !cute.shape<"(8,(1))">
        %e0_192, %e1_193 = cute.get_leaves(%62) : !cute.shape<"(8,(1))">
        %lay_194 = cute.get_layout(%view_188) : !memref_rmem_f32_2
        %63 = cute.get_shape(%lay_194) : (!cute.layout<"(8,(1)):(1,(0))">) -> !cute.shape<"(8,(1))">
        %e0_195, %e1_196 = cute.get_leaves(%63) : !cute.shape<"(8,(1))">
        %lay_197 = cute.get_layout(%view_175) : !memref_gmem_f32_5
        %sz = cute.size(%lay_197) <{mode = [1]}> : (!cute.layout<"(8,(1)):(1,(0))">) -> !cute.int_tuple<"1">
        %e0_198 = cute.get_leaves(%sz) : !cute.int_tuple<"1">
        %lay_199 = cute.get_layout(%view_188) : !memref_rmem_f32_2
        %sz_200 = cute.size(%lay_199) <{mode = [1]}> : (!cute.layout<"(8,(1)):(1,(0))">) -> !cute.int_tuple<"1">
        %e0_201 = cute.get_leaves(%sz_200) : !cute.int_tuple<"1">
        %64 = cute.static : !cute.layout<"1:0">
        %iter_202 = cute.get_iter(%view_175) : !memref_gmem_f32_5
        %iter_203 = cute.get_iter(%view_188) : !memref_rmem_f32_2
        %lay_204 = cute.get_layout(%view_175) : !memref_gmem_f32_5
        %lay_205 = cute.get_layout(%view_188) : !memref_rmem_f32_2
        %append_206 = cute.append_to_rank<2> (%lay_204, %64) : !cute.layout<"(8,(1)):(1,(0))">, !cute.layout<"1:0">
        %append_207 = cute.append_to_rank<2> (%lay_205, %64) : !cute.layout<"(8,(1)):(1,(0))">, !cute.layout<"1:0">
        %lay_208 = cute.make_layout() : !cute.layout<"(8,((1))):(1,((0)))">
        %lay_209 = cute.make_layout() : !cute.layout<"(8,((1))):(1,((0)))">
        %sz_210 = cute.size(%lay_208) <{mode = [1]}> : (!cute.layout<"(8,((1))):(1,((0)))">) -> !cute.int_tuple<"1">
        %65 = cute.get_scalars(%sz_210) : !cute.int_tuple<"1">
        %c0_i32 = arith.constant 0 : i32
        %c1_i32 = arith.constant 1 : i32
        scf.for %arg6 = %c0_i32 to %65 step %c1_i32  : i32 {
          %coord_273 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
          %slice = cute.slice(%lay_208, %coord_273) : !cute.layout<"(8,((1))):(1,((0)))">, !cute.coord<"(_,?)">
          %idx_274 = cute.crd2idx(%coord_273, %lay_208) : (!cute.coord<"(_,?)">, !cute.layout<"(8,((1))):(1,((0)))">) -> !cute.int_tuple<"0">
          %ptr_275 = cute.add_offset(%iter_202, %idx_274) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<f32, gmem>
          %view_276 = cute.make_view(%ptr_275, %slice) : !memref_gmem_f32_3
          %slice_277 = cute.slice(%lay_209, %coord_273) : !cute.layout<"(8,((1))):(1,((0)))">, !cute.coord<"(_,?)">
          %idx_278 = cute.crd2idx(%coord_273, %lay_209) : (!cute.coord<"(_,?)">, !cute.layout<"(8,((1))):(1,((0)))">) -> !cute.int_tuple<"0">
          %ptr_279 = cute.add_offset(%iter_203, %idx_278) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, rmem, align<32>>
          %view_280 = cute.make_view(%ptr_279, %slice_277) : !memref_rmem_f32_3
          cute.copy_atom_call(%atom, %view_276, %view_280) : (!cute_nvgpu.atom.universal_copy<f32>, !memref_gmem_f32_3, !memref_rmem_f32_3) -> ()
        } {llvm.loop_annotation = #loop_annotation}
        %66 = cute.memref.load_vec %rmem : !memref_rmem_f32_
        %67 = arith.fptosi %66 : vector<8xf32> to vector<8xi4>
        %shape_211 = cute.make_shape() : () -> !cute.shape<"8">
        %lay_212 = cute.make_layout() : !cute.layout<"8:1">
        %68 = cute.recast_layout<8, 4> (%lay_212) : !cute.layout<"8:1"> to !cute.layout<"4:1">
        %69 = cute.get_shape(%68) : (!cute.layout<"4:1">) -> !cute.shape<"4">
        %e0_213 = cute.get_leaves(%69) : !cute.shape<"4">
        %70 = builtin.unrealized_conversion_cast %67 : vector<8xi4> to vector<8xi4>
        %71 = vector.bitcast %70 : vector<8xi4> to vector<4xi8>
        %lay_214 = cute.get_layout(%rmem_160) : !memref_rmem_i8_
        %72 = cute.get_shape(%lay_214) : (!cute.layout<"4:1">) -> !cute.shape<"4">
        %e0_215 = cute.get_leaves(%72) : !cute.shape<"4">
        %int_tuple = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
        %sz_216 = cute.size(%int_tuple) : (!cute.int_tuple<"4">) -> !cute.int_tuple<"4">
        %e0_217 = cute.get_leaves(%sz_216) : !cute.int_tuple<"4">
        %int_tuple_218 = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
        %sz_219 = cute.size(%int_tuple_218) : (!cute.int_tuple<"4">) -> !cute.int_tuple<"4">
        %e0_220 = cute.get_leaves(%sz_219) : !cute.int_tuple<"4">
        cute.memref.store_vec %71, %rmem_160 : !memref_rmem_i8_
        %atom_221 = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<i8>
        %lay_222 = cute.get_layout(%view_113) : !memref_gmem_i8_3
        %73 = cute.get_shape(%lay_222) : (!cute.layout<"(4):(1)">) -> !cute.shape<"(4)">
        %e0_223 = cute.get_leaves(%73) : !cute.shape<"(4)">
        %lay_224 = cute.get_layout(%rmem_160) : !memref_rmem_i8_
        %shape_225 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_226 = cute.make_layout() : !cute.layout<"1:0">
        %append_227 = cute.append_to_rank<2> (%lay_224, %lay_226) : !cute.layout<"4:1">, !cute.layout<"1:0">
        %view_228 = cute.make_view(%iter_162, %append_227) : !memref_rmem_i8_1
        %iter_229 = cute.get_iter(%view_228) : !memref_rmem_i8_1
        %lay_230 = cute.get_layout(%view_228) : !memref_rmem_i8_1
        %74 = cute.get_shape(%lay_230) : (!cute.layout<"(4,1):(1,0)">) -> !cute.shape<"(4,1)">
        %e0_231, %e1_232 = cute.get_leaves(%74) : !cute.shape<"(4,1)">
        %iter_233 = cute.get_iter(%view_228) : !memref_rmem_i8_1
        %view_234 = cute.make_view(%iter_233) : !memref_rmem_i8_2
        %iter_235 = cute.get_iter(%view_234) : !memref_rmem_i8_2
        %iter_236 = cute.get_iter(%view_234) : !memref_rmem_i8_2
        %lay_237 = cute.get_layout(%view_113) : !memref_gmem_i8_3
        %shape_238 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_239 = cute.make_layout() : !cute.layout<"1:0">
        %append_240 = cute.append_to_rank<2> (%lay_237, %lay_239) : !cute.layout<"(4):(1)">, !cute.layout<"1:0">
        %view_241 = cute.make_view(%iter_115, %append_240) : !memref_gmem_i8_4
        %iter_242 = cute.get_iter(%view_241) : !memref_gmem_i8_4
        %lay_243 = cute.get_layout(%view_241) : !memref_gmem_i8_4
        %75 = cute.get_shape(%lay_243) : (!cute.layout<"(4,1):(1,0)">) -> !cute.shape<"(4,1)">
        %e0_244, %e1_245 = cute.get_leaves(%75) : !cute.shape<"(4,1)">
        %iter_246 = cute.get_iter(%view_241) : !memref_gmem_i8_4
        %view_247 = cute.make_view(%iter_246) : !memref_gmem_i8_5
        %iter_248 = cute.get_iter(%view_247) : !memref_gmem_i8_5
        %iter_249 = cute.get_iter(%view_247) : !memref_gmem_i8_5
        %lay_250 = cute.get_layout(%view_234) : !memref_rmem_i8_2
        %76 = cute.get_shape(%lay_250) : (!cute.layout<"(4,(1)):(1,(0))">) -> !cute.shape<"(4,(1))">
        %e0_251, %e1_252 = cute.get_leaves(%76) : !cute.shape<"(4,(1))">
        %lay_253 = cute.get_layout(%view_247) : !memref_gmem_i8_5
        %77 = cute.get_shape(%lay_253) : (!cute.layout<"(4,(1)):(1,(0))">) -> !cute.shape<"(4,(1))">
        %e0_254, %e1_255 = cute.get_leaves(%77) : !cute.shape<"(4,(1))">
        %lay_256 = cute.get_layout(%view_234) : !memref_rmem_i8_2
        %sz_257 = cute.size(%lay_256) <{mode = [1]}> : (!cute.layout<"(4,(1)):(1,(0))">) -> !cute.int_tuple<"1">
        %e0_258 = cute.get_leaves(%sz_257) : !cute.int_tuple<"1">
        %lay_259 = cute.get_layout(%view_247) : !memref_gmem_i8_5
        %sz_260 = cute.size(%lay_259) <{mode = [1]}> : (!cute.layout<"(4,(1)):(1,(0))">) -> !cute.int_tuple<"1">
        %e0_261 = cute.get_leaves(%sz_260) : !cute.int_tuple<"1">
        %78 = cute.static : !cute.layout<"1:0">
        %iter_262 = cute.get_iter(%view_234) : !memref_rmem_i8_2
        %iter_263 = cute.get_iter(%view_247) : !memref_gmem_i8_5
        %lay_264 = cute.get_layout(%view_234) : !memref_rmem_i8_2
        %lay_265 = cute.get_layout(%view_247) : !memref_gmem_i8_5
        %append_266 = cute.append_to_rank<2> (%lay_264, %78) : !cute.layout<"(4,(1)):(1,(0))">, !cute.layout<"1:0">
        %append_267 = cute.append_to_rank<2> (%lay_265, %78) : !cute.layout<"(4,(1)):(1,(0))">, !cute.layout<"1:0">
        %lay_268 = cute.make_layout() : !cute.layout<"(4,((1))):(1,((0)))">
        %lay_269 = cute.make_layout() : !cute.layout<"(4,((1))):(1,((0)))">
        %sz_270 = cute.size(%lay_268) <{mode = [1]}> : (!cute.layout<"(4,((1))):(1,((0)))">) -> !cute.int_tuple<"1">
        %79 = cute.get_scalars(%sz_270) : !cute.int_tuple<"1">
        %c0_i32_271 = arith.constant 0 : i32
        %c1_i32_272 = arith.constant 1 : i32
        scf.for %arg6 = %c0_i32_271 to %79 step %c1_i32_272  : i32 {
          %coord_273 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
          %slice = cute.slice(%lay_268, %coord_273) : !cute.layout<"(4,((1))):(1,((0)))">, !cute.coord<"(_,?)">
          %idx_274 = cute.crd2idx(%coord_273, %lay_268) : (!cute.coord<"(_,?)">, !cute.layout<"(4,((1))):(1,((0)))">) -> !cute.int_tuple<"0">
          %ptr_275 = cute.add_offset(%iter_262, %idx_274) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
          %view_276 = cute.make_view(%ptr_275, %slice) : !memref_rmem_i8_3
          %slice_277 = cute.slice(%lay_269, %coord_273) : !cute.layout<"(4,((1))):(1,((0)))">, !cute.coord<"(_,?)">
          %idx_278 = cute.crd2idx(%coord_273, %lay_269) : (!cute.coord<"(_,?)">, !cute.layout<"(4,((1))):(1,((0)))">) -> !cute.int_tuple<"0">
          %ptr_279 = cute.add_offset(%iter_263, %idx_278) : (!cute.ptr<i8, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<i8, gmem>
          %view_280 = cute.make_view(%ptr_279, %slice_277) : !memref_gmem_i8_3
          cute.copy_atom_call(%atom_221, %view_276, %view_280) : (!cute_nvgpu.atom.universal_copy<i8>, !memref_rmem_i8_3, !memref_gmem_i8_3) -> ()
        } {llvm.loop_annotation = #loop_annotation}
      }
      return
    }
  }
  func.func @cutlass__convert_Tensorgmemo1i64i64_Tensorgmemo1i64i64_0_8(%arg0: !memref_gmem_f32_6, %arg1: !memref_gmem_i4_) -> i32 attributes {llvm.emit_c_interface} {
    %iter = cute.get_iter(%arg0) : !memref_gmem_f32_6
    %iter_0 = cute.get_iter(%arg1) : !memref_gmem_i4_
    %iter_1 = cute.get_iter(%arg0) : !memref_gmem_f32_6
    %iter_2 = cute.get_iter(%arg1) : !memref_gmem_i4_
    %lay = cute.get_layout(%arg0) : !memref_gmem_f32_6
    %0 = cute.get_shape(%lay) : (!cute.layout<"(?,?,?):(1,?{i64},?{i64})">) -> !cute.shape<"(?,?,?)">
    %e0, %e1, %e2 = cute.get_leaves(%0) : !cute.shape<"(?,?,?)">
    %itup = cute.to_int_tuple(%e0) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %1 = cute.get_scalars(%itup) : !cute.int_tuple<"?">
    %itup_3 = cute.to_int_tuple(%e1) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %2 = cute.get_scalars(%itup_3) : !cute.int_tuple<"?">
    %itup_4 = cute.to_int_tuple(%e2) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %3 = cute.get_scalars(%itup_4) : !cute.int_tuple<"?">
    %4 = cute.get_stride(%lay) : (!cute.layout<"(?,?,?):(1,?{i64},?{i64})">) -> !cute.stride<"(1,?{i64},?{i64})">
    %e0_5, %e1_6, %e2_7 = cute.get_leaves(%4) : !cute.stride<"(1,?{i64},?{i64})">
    %itup_8 = cute.to_int_tuple(%e1_6) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
    %5 = cute.get_scalars(%itup_8) : !cute.int_tuple<"?{i64}">
    %itup_9 = cute.to_int_tuple(%e2_7) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
    %6 = cute.get_scalars(%itup_9) : !cute.int_tuple<"?{i64}">
    %lay_10 = cute.get_layout(%arg1) : !memref_gmem_i4_
    %7 = cute.get_shape(%lay_10) : (!cute.layout<"(?,?,?):(1,?{i64},?{i64})">) -> !cute.shape<"(?,?,?)">
    %e0_11, %e1_12, %e2_13 = cute.get_leaves(%7) : !cute.shape<"(?,?,?)">
    %itup_14 = cute.to_int_tuple(%e0_11) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %8 = cute.get_scalars(%itup_14) : !cute.int_tuple<"?">
    %itup_15 = cute.to_int_tuple(%e1_12) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %9 = cute.get_scalars(%itup_15) : !cute.int_tuple<"?">
    %itup_16 = cute.to_int_tuple(%e2_13) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %10 = cute.get_scalars(%itup_16) : !cute.int_tuple<"?">
    %11 = cute.get_stride(%lay_10) : (!cute.layout<"(?,?,?):(1,?{i64},?{i64})">) -> !cute.stride<"(1,?{i64},?{i64})">
    %e0_17, %e1_18, %e2_19 = cute.get_leaves(%11) : !cute.stride<"(1,?{i64},?{i64})">
    %itup_20 = cute.to_int_tuple(%e1_18) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
    %12 = cute.get_scalars(%itup_20) : !cute.int_tuple<"?{i64}">
    %itup_21 = cute.to_int_tuple(%e2_19) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
    %13 = cute.get_scalars(%itup_21) : !cute.int_tuple<"?{i64}">
    %shape = cute.make_shape() : () -> !cute.shape<"(128,8)">
    %stride = cute.make_stride() : () -> !cute.stride<"(8,1)">
    %lay_22 = cute.make_layout() : !cute.layout<"(128,8):(8,1)">
    %14 = cute.recast_layout<8, 4> (%lay_22) : !cute.layout<"(128,8):(8,1)"> to !cute.layout<"(128,4):(4,1)">
    %iter_23 = cute.recast_iter(%iter_2) : !cute.ptr<i4, gmem, align<128>> to !cute.ptr<i8, gmem, align<128>>
    %lay_24 = cute.get_layout(%arg1) : !memref_gmem_i4_
    %15 = cute.recast_layout<8, 4> (%lay_24) : !cute.layout<"(?,?,?):(1,?{i64},?{i64})"> to !cute.layout<"(?,?,?):(1,?{i64},?{i64})">
    %view = cute.make_view(%iter_23, %15) : !memref_gmem_i8_6
    %iter_25 = cute.get_iter(%view) : !memref_gmem_i8_6
    %lay_26 = cute.get_layout(%arg0) : !memref_gmem_f32_6
    %16 = cute.get_shape(%lay_26) : (!cute.layout<"(?,?,?):(1,?{i64},?{i64})">) -> !cute.shape<"(?,?,?)">
    %e0_27, %e1_28, %e2_29 = cute.get_leaves(%16) : !cute.shape<"(?,?,?)">
    %itup_30 = cute.to_int_tuple(%e0_27) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %17 = cute.get_scalars(%itup_30) : !cute.int_tuple<"?">
    %itup_31 = cute.to_int_tuple(%e1_28) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %18 = cute.get_scalars(%itup_31) : !cute.int_tuple<"?">
    %itup_32 = cute.to_int_tuple(%e2_29) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %19 = cute.get_scalars(%itup_32) : !cute.int_tuple<"?">
    %shape_33 = cute.make_shape(%itup_30, %itup_31, %itup_32) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.shape<"(?,?,?)">
    %20 = cute.make_identity_tensor(%shape_33) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">
    %iter_34 = cute.get_iter(%20) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">
    %e0_35, %e1_36, %e2_37 = cute.get_leaves(%iter_34) : !cute.int_tuple<"(0,0,0)">
    %lay_38 = cute.get_layout(%arg0) : !memref_gmem_f32_6
    %21 = cute.get_shape(%lay_38) : (!cute.layout<"(?,?,?):(1,?{i64},?{i64})">) -> !cute.shape<"(?,?,?)">
    %e0_39, %e1_40, %e2_41 = cute.get_leaves(%21) : !cute.shape<"(?,?,?)">
    %itup_42 = cute.to_int_tuple(%e0_39) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %22 = cute.get_scalars(%itup_42) : !cute.int_tuple<"?">
    %itup_43 = cute.to_int_tuple(%e1_40) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %23 = cute.get_scalars(%itup_43) : !cute.int_tuple<"?">
    %itup_44 = cute.to_int_tuple(%e2_41) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %24 = cute.get_scalars(%itup_44) : !cute.int_tuple<"?">
    %sz = cute.size(%lay_22) : (!cute.layout<"(128,8):(8,1)">) -> !cute.int_tuple<"1024">
    %e0_45 = cute.get_leaves(%sz) : !cute.int_tuple<"1024">
    %lay_46 = cute.get_layout(%view) : !memref_gmem_i8_6
    %25 = cute.get_shape(%lay_46) : (!cute.layout<"(?,?,?):(1,?{i64},?{i64})">) -> !cute.shape<"(?,?,?)">
    %e0_47, %e1_48, %e2_49 = cute.get_leaves(%25) : !cute.shape<"(?,?,?)">
    %itup_50 = cute.to_int_tuple(%e0_47) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %26 = cute.get_scalars(%itup_50) : !cute.int_tuple<"?">
    %itup_51 = cute.to_int_tuple(%e1_48) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %27 = cute.get_scalars(%itup_51) : !cute.int_tuple<"?">
    %itup_52 = cute.to_int_tuple(%e2_49) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %28 = cute.get_scalars(%itup_52) : !cute.int_tuple<"?">
    %sz_53 = cute.size(%14) : (!cute.layout<"(128,4):(4,1)">) -> !cute.int_tuple<"512">
    %e0_54 = cute.get_leaves(%sz_53) : !cute.int_tuple<"512">
    %tile = cute.make_tile() : () -> !cute.tile<"[1024:1;1:0;1:0]">
    %iter_55 = cute.get_iter(%arg0) : !memref_gmem_f32_6
    %lay_56 = cute.get_layout(%arg0) : !memref_gmem_f32_6
    %29:5 = cute.get_scalars(%lay_56) <{only_dynamic}> : !cute.layout<"(?,?,?):(1,?{i64},?{i64})">
    %c1024_i32 = arith.constant 1024 : i32
    %30 = arith.ceildivsi %29#0, %c1024_i32 : i32
    %shape_57 = cute.make_shape(%30, %29#1, %29#2) : (i32, i32, i32) -> !cute.shape<"((1024,1,1),(?,?,?))">
    %stride_58 = cute.make_stride(%29#3, %29#4) : (i64, i64) -> !cute.stride<"((1,0,0),(1024,?{i64},?{i64}))">
    %lay_59 = cute.make_layout(%shape_57, %stride_58) : !cute.layout<"((1024,1,1),(?,?,?)):((1,0,0),(1024,?{i64},?{i64}))">
    %view_60 = cute.make_view(%iter_55, %lay_59) : !memref_gmem_f32_
    %iter_61 = cute.get_iter(%view_60) : !memref_gmem_f32_
    %iter_62 = cute.get_iter(%view_60) : !memref_gmem_f32_
    %tile_63 = cute.make_tile() : () -> !cute.tile<"[1024:1;1:0;1:0]">
    %iter_64 = cute.get_iter(%20) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">
    %lay_65 = cute.get_layout(%20) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">
    %31:3 = cute.get_scalars(%lay_65) <{only_dynamic}> : !cute.layout<"(?,?,?):(1@0,1@1,1@2)">
    %c1024_i32_66 = arith.constant 1024 : i32
    %32 = arith.ceildivsi %31#0, %c1024_i32_66 : i32
    %shape_67 = cute.make_shape(%32, %31#1, %31#2) : (i32, i32, i32) -> !cute.shape<"((1024,1,1),(?,?,?))">
    %stride_68 = cute.make_stride() : () -> !cute.stride<"((1@0,0,0),(1024@0,1@1,1@2))">
    %lay_69 = cute.make_layout(%shape_67, %stride_68) : !cute.layout<"((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">
    %view_70 = cute.make_view(%iter_64, %lay_69) : !cute.coord_tensor<"(0,0,0)", "((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">
    %iter_71 = cute.get_iter(%view_70) : !cute.coord_tensor<"(0,0,0)", "((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">
    %e0_72, %e1_73, %e2_74 = cute.get_leaves(%iter_71) : !cute.int_tuple<"(0,0,0)">
    %iter_75 = cute.get_iter(%view_70) : !cute.coord_tensor<"(0,0,0)", "((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">
    %e0_76, %e1_77, %e2_78 = cute.get_leaves(%iter_75) : !cute.int_tuple<"(0,0,0)">
    %tile_79 = cute.make_tile() : () -> !cute.tile<"[512:1;1:0;1:0]">
    %iter_80 = cute.get_iter(%view) : !memref_gmem_i8_6
    %lay_81 = cute.get_layout(%view) : !memref_gmem_i8_6
    %33:5 = cute.get_scalars(%lay_81) <{only_dynamic}> : !cute.layout<"(?,?,?):(1,?{i64},?{i64})">
    %c512_i32 = arith.constant 512 : i32
    %34 = arith.ceildivsi %33#0, %c512_i32 : i32
    %shape_82 = cute.make_shape(%34, %33#1, %33#2) : (i32, i32, i32) -> !cute.shape<"((512,1,1),(?,?,?))">
    %stride_83 = cute.make_stride(%33#3, %33#4) : (i64, i64) -> !cute.stride<"((1,0,0),(512,?{i64},?{i64}))">
    %lay_84 = cute.make_layout(%shape_82, %stride_83) : !cute.layout<"((512,1,1),(?,?,?)):((1,0,0),(512,?{i64},?{i64}))">
    %view_85 = cute.make_view(%iter_80, %lay_84) : !memref_gmem_i8_
    %iter_86 = cute.get_iter(%view_85) : !memref_gmem_i8_
    %iter_87 = cute.get_iter(%view_85) : !memref_gmem_i8_
    %lay_88 = cute.get_layout(%view_60) : !memref_gmem_f32_
    %sz_89 = cute.size(%lay_88) <{mode = [1]}> : (!cute.layout<"((1024,1,1),(?,?,?)):((1,0,0),(1024,?{i64},?{i64}))">) -> !cute.int_tuple<"?">
    %e0_90 = cute.get_leaves(%sz_89) : !cute.int_tuple<"?">
    %35 = cute.get_scalars(%e0_90) : !cute.int_tuple<"?">
    %sz_91 = cute.size(%lay_22) <{mode = [0]}> : (!cute.layout<"(128,8):(8,1)">) -> !cute.int_tuple<"128">
    %e0_92 = cute.get_leaves(%sz_91) : !cute.int_tuple<"128">
    %lay_93 = cute.get_layout(%view_60) : !memref_gmem_f32_
    %36 = cute.get_shape(%lay_93) : (!cute.layout<"((1024,1,1),(?,?,?)):((1,0,0),(1024,?{i64},?{i64}))">) -> !cute.shape<"((1024,1,1),(?,?,?))">
    %e0_94, %e1_95, %e2_96, %e3, %e4, %e5 = cute.get_leaves(%36) : !cute.shape<"((1024,1,1),(?,?,?))">
    %itup_97 = cute.to_int_tuple(%e3) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %37 = cute.get_scalars(%itup_97) : !cute.int_tuple<"?">
    %itup_98 = cute.to_int_tuple(%e4) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %38 = cute.get_scalars(%itup_98) : !cute.int_tuple<"?">
    %itup_99 = cute.to_int_tuple(%e5) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %39 = cute.get_scalars(%itup_99) : !cute.int_tuple<"?">
    %40 = cute.get_stride(%lay_93) : (!cute.layout<"((1024,1,1),(?,?,?)):((1,0,0),(1024,?{i64},?{i64}))">) -> !cute.stride<"((1,0,0),(1024,?{i64},?{i64}))">
    %e0_100, %e1_101, %e2_102, %e3_103, %e4_104, %e5_105 = cute.get_leaves(%40) : !cute.stride<"((1,0,0),(1024,?{i64},?{i64}))">
    %itup_106 = cute.to_int_tuple(%e4_104) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
    %41 = cute.get_scalars(%itup_106) : !cute.int_tuple<"?{i64}">
    %itup_107 = cute.to_int_tuple(%e5_105) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
    %42 = cute.get_scalars(%itup_107) : !cute.int_tuple<"?{i64}">
    %lay_108 = cute.get_layout(%view_85) : !memref_gmem_i8_
    %43 = cute.get_shape(%lay_108) : (!cute.layout<"((512,1,1),(?,?,?)):((1,0,0),(512,?{i64},?{i64}))">) -> !cute.shape<"((512,1,1),(?,?,?))">
    %e0_109, %e1_110, %e2_111, %e3_112, %e4_113, %e5_114 = cute.get_leaves(%43) : !cute.shape<"((512,1,1),(?,?,?))">
    %itup_115 = cute.to_int_tuple(%e3_112) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %44 = cute.get_scalars(%itup_115) : !cute.int_tuple<"?">
    %itup_116 = cute.to_int_tuple(%e4_113) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %45 = cute.get_scalars(%itup_116) : !cute.int_tuple<"?">
    %itup_117 = cute.to_int_tuple(%e5_114) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %46 = cute.get_scalars(%itup_117) : !cute.int_tuple<"?">
    %47 = cute.get_stride(%lay_108) : (!cute.layout<"((512,1,1),(?,?,?)):((1,0,0),(512,?{i64},?{i64}))">) -> !cute.stride<"((1,0,0),(512,?{i64},?{i64}))">
    %e0_118, %e1_119, %e2_120, %e3_121, %e4_122, %e5_123 = cute.get_leaves(%47) : !cute.stride<"((1,0,0),(512,?{i64},?{i64}))">
    %itup_124 = cute.to_int_tuple(%e4_122) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
    %48 = cute.get_scalars(%itup_124) : !cute.int_tuple<"?{i64}">
    %itup_125 = cute.to_int_tuple(%e5_123) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
    %49 = cute.get_scalars(%itup_125) : !cute.int_tuple<"?{i64}">
    %lay_126 = cute.get_layout(%view_70) : !cute.coord_tensor<"(0,0,0)", "((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">
    %50 = cute.get_shape(%lay_126) : (!cute.layout<"((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">) -> !cute.shape<"((1024,1,1),(?,?,?))">
    %e0_127, %e1_128, %e2_129, %e3_130, %e4_131, %e5_132 = cute.get_leaves(%50) : !cute.shape<"((1024,1,1),(?,?,?))">
    %itup_133 = cute.to_int_tuple(%e3_130) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %51 = cute.get_scalars(%itup_133) : !cute.int_tuple<"?">
    %itup_134 = cute.to_int_tuple(%e4_131) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %52 = cute.get_scalars(%itup_134) : !cute.int_tuple<"?">
    %itup_135 = cute.to_int_tuple(%e5_132) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %53 = cute.get_scalars(%itup_135) : !cute.int_tuple<"?">
    %54 = cute.get_stride(%lay_126) : (!cute.layout<"((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">) -> !cute.stride<"((1@0,0,0),(1024@0,1@1,1@2))">
    %e0_136, %e1_137, %e2_138, %e3_139, %e4_140, %e5_141 = cute.get_leaves(%54) : !cute.stride<"((1@0,0,0),(1024@0,1@1,1@2))">
    %55 = cute.get_shape(%lay_22) : (!cute.layout<"(128,8):(8,1)">) -> !cute.shape<"(128,8)">
    %e0_142, %e1_143 = cute.get_leaves(%55) : !cute.shape<"(128,8)">
    %56 = cute.get_stride(%lay_22) : (!cute.layout<"(128,8):(8,1)">) -> !cute.stride<"(8,1)">
    %e0_144, %e1_145 = cute.get_leaves(%56) : !cute.stride<"(8,1)">
    %57 = cute.get_shape(%14) : (!cute.layout<"(128,4):(4,1)">) -> !cute.shape<"(128,4)">
    %e0_146, %e1_147 = cute.get_leaves(%57) : !cute.shape<"(128,4)">
    %58 = cute.get_stride(%14) : (!cute.layout<"(128,4):(4,1)">) -> !cute.stride<"(4,1)">
    %e0_148, %e1_149 = cute.get_leaves(%58) : !cute.stride<"(4,1)">
    %c0_i32 = arith.constant 0 : i32
    %c0_i64 = arith.constant 0 : i64
    %59 = cuda.cast %c0_i64 : i64 -> !cuda.stream
    %60 = arith.extsi %c0_i32 : i32 to i64
    %c128_i32 = arith.constant 128 : i32
    %c1_i32 = arith.constant 1 : i32
    %61 = cuda.launch_cfg.create<max_attrs = 2 : i32> (blockDim = (%c128_i32, %c1_i32, %c1_i32), dynamicSmemBytes = %60, gridDim = (%35, %c1_i32, %c1_i32), stream = %59) : i32, i32, i32, i64, i32, i32, i32, !cuda.stream -> !cuda.launch_cfg<max_attrs = 2>
    %62 = cuda.launch_ex @kernels::@kernel_cutlass__convert_kernel_tensorptrf32gmemo1024111001024_tensorptri8gmemalign128o51211100512_tensor000o1024111000102401112____Float32_Int4_0<%61> (%view_60, %view_85, %view_70, %17, %18, %19) : !cuda.launch_cfg<max_attrs = 2>, (!memref_gmem_f32_, !memref_gmem_i8_, !cute.coord_tensor<"(0,0,0)", "((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">, i32, i32, i32) -> !cuda.result
    %63 = cuda.cast %62 : !cuda.result -> i32
    cuda.return_if_error %63 : i32
    %c0_i32_150 = arith.constant 0 : i32
    return %c0_i32_150 : i32
  }
}
