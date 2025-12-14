!memref_gmem_f32_ = !cute.memref<f32, gmem, "((1,1024,1),(?,?,?)):((0,1,0),(?{i64},1024,?{i64}))">
!memref_gmem_f32_1 = !cute.memref<f32, gmem, "((1,1024,1)):((0,1,0))">
!memref_gmem_f32_2 = !cute.memref<f32, gmem, "(128,8):(8,1)">
!memref_gmem_f32_3 = !cute.memref<f32, gmem, "(8):(1)">
!memref_gmem_f32_4 = !cute.memref<f32, gmem, "(8,1):(1,0)">
!memref_gmem_f32_5 = !cute.memref<f32, gmem, "(8,(1)):(1,(0))">
!memref_gmem_f32_6 = !cute.memref<f32, gmem, "(?,?,?):(?{i64},1,?{i64})">
!memref_gmem_f4E2M1FN = !cute.memref<f4E2M1FN, gmem, align<16>, "(?,?,?):(?{i64},1,?{i64})">
!memref_gmem_i8_ = !cute.memref<i8, gmem, align<16>, "((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">
!memref_gmem_i8_1 = !cute.memref<i8, gmem, "((1,512,1)):((0,1,0))">
!memref_gmem_i8_2 = !cute.memref<i8, gmem, "(128,4):(4,1)">
!memref_gmem_i8_3 = !cute.memref<i8, gmem, "(4):(1)">
!memref_gmem_i8_4 = !cute.memref<i8, gmem, "(4,1):(1,0)">
!memref_gmem_i8_5 = !cute.memref<i8, gmem, "(4,(1)):(1,(0))">
!memref_gmem_i8_6 = !cute.memref<i8, gmem, align<16>, "(?,?,?):(?{i64},1,?{i64})">
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
    cuda.kernel @kernel_cutlass__convert_kernel_tensorptrf32gmemo1102410101024_tensorptri8gmemalign16o15121010512_tensor000o1102410110101024112____Float32_Float4E2M1FN_0(%arg0: !memref_gmem_f32_, %arg1: !memref_gmem_i8_, %arg2: !cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">, %arg3: i32, %arg4: i32, %arg5: i32) attributes {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} {
      %0 = cute.static : !cute.layout<"(128,8):(8,1)">
      %1 = cute.static : !cute.layout<"(128,4):(4,1)">
      %iter = cute.get_iter(%arg0) : !memref_gmem_f32_
      %iter_0 = cute.get_iter(%arg1) : !memref_gmem_i8_
      %iter_1 = cute.get_iter(%arg2) : !cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">
      %e0, %e1, %e2 = cute.get_leaves(%iter_1) : !cute.int_tuple<"(0,0,0)">
      %iter_2 = cute.get_iter(%arg0) : !memref_gmem_f32_
      %iter_3 = cute.get_iter(%arg1) : !memref_gmem_i8_
      %iter_4 = cute.get_iter(%arg2) : !cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">
      %e0_5, %e1_6, %e2_7 = cute.get_leaves(%iter_4) : !cute.int_tuple<"(0,0,0)">
      %lay = cute.get_layout(%arg0) : !memref_gmem_f32_
      %2 = cute.get_shape(%lay) : (!cute.layout<"((1,1024,1),(?,?,?)):((0,1,0),(?{i64},1024,?{i64}))">) -> !cute.shape<"((1,1024,1),(?,?,?))">
      %e0_8, %e1_9, %e2_10, %e3, %e4, %e5 = cute.get_leaves(%2) : !cute.shape<"((1,1024,1),(?,?,?))">
      %itup = cute.to_int_tuple(%e3) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %3 = cute.get_scalars(%itup) : !cute.int_tuple<"?">
      %itup_11 = cute.to_int_tuple(%e4) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %4 = cute.get_scalars(%itup_11) : !cute.int_tuple<"?">
      %itup_12 = cute.to_int_tuple(%e5) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %5 = cute.get_scalars(%itup_12) : !cute.int_tuple<"?">
      %6 = cute.get_stride(%lay) : (!cute.layout<"((1,1024,1),(?,?,?)):((0,1,0),(?{i64},1024,?{i64}))">) -> !cute.stride<"((0,1,0),(?{i64},1024,?{i64}))">
      %e0_13, %e1_14, %e2_15, %e3_16, %e4_17, %e5_18 = cute.get_leaves(%6) : !cute.stride<"((0,1,0),(?{i64},1024,?{i64}))">
      %itup_19 = cute.to_int_tuple(%e3_16) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
      %7 = cute.get_scalars(%itup_19) : !cute.int_tuple<"?{i64}">
      %itup_20 = cute.to_int_tuple(%e5_18) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
      %8 = cute.get_scalars(%itup_20) : !cute.int_tuple<"?{i64}">
      %lay_21 = cute.get_layout(%arg1) : !memref_gmem_i8_
      %9 = cute.get_shape(%lay_21) : (!cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !cute.shape<"((1,512,1),(?,?,?))">
      %e0_22, %e1_23, %e2_24, %e3_25, %e4_26, %e5_27 = cute.get_leaves(%9) : !cute.shape<"((1,512,1),(?,?,?))">
      %itup_28 = cute.to_int_tuple(%e3_25) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %10 = cute.get_scalars(%itup_28) : !cute.int_tuple<"?">
      %itup_29 = cute.to_int_tuple(%e4_26) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %11 = cute.get_scalars(%itup_29) : !cute.int_tuple<"?">
      %itup_30 = cute.to_int_tuple(%e5_27) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %12 = cute.get_scalars(%itup_30) : !cute.int_tuple<"?">
      %13 = cute.get_stride(%lay_21) : (!cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !cute.stride<"((0,1,0),(?{i64},512,?{i64}))">
      %e0_31, %e1_32, %e2_33, %e3_34, %e4_35, %e5_36 = cute.get_leaves(%13) : !cute.stride<"((0,1,0),(?{i64},512,?{i64}))">
      %itup_37 = cute.to_int_tuple(%e3_34) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
      %14 = cute.get_scalars(%itup_37) : !cute.int_tuple<"?{i64}">
      %itup_38 = cute.to_int_tuple(%e5_36) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
      %15 = cute.get_scalars(%itup_38) : !cute.int_tuple<"?{i64}">
      %lay_39 = cute.get_layout(%arg2) : !cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">
      %16 = cute.get_shape(%lay_39) : (!cute.layout<"((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">) -> !cute.shape<"((1,1024,1),(?,?,?))">
      %e0_40, %e1_41, %e2_42, %e3_43, %e4_44, %e5_45 = cute.get_leaves(%16) : !cute.shape<"((1,1024,1),(?,?,?))">
      %itup_46 = cute.to_int_tuple(%e3_43) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %17 = cute.get_scalars(%itup_46) : !cute.int_tuple<"?">
      %itup_47 = cute.to_int_tuple(%e4_44) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %18 = cute.get_scalars(%itup_47) : !cute.int_tuple<"?">
      %itup_48 = cute.to_int_tuple(%e5_45) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %19 = cute.get_scalars(%itup_48) : !cute.int_tuple<"?">
      %20 = cute.get_stride(%lay_39) : (!cute.layout<"((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">) -> !cute.stride<"((0,1@1,0),(1@0,1024@1,1@2))">
      %e0_49, %e1_50, %e2_51, %e3_52, %e4_53, %e5_54 = cute.get_leaves(%20) : !cute.stride<"((0,1@1,0),(1@0,1024@1,1@2))">
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
      %idx = cute.crd2idx(%coord, %lay_63) : (!cute.coord<"(_,?)">, !cute.layout<"((1,1024,1),(?,?,?)):((0,1,0),(?{i64},1024,?{i64}))">) -> !cute.int_tuple<"?{i64}">
      %iter_64 = cute.get_iter(%arg0) : !memref_gmem_f32_
      %ptr = cute.add_offset(%iter_64, %idx) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %view = cute.make_view(%ptr) : !memref_gmem_f32_1
      %iter_65 = cute.get_iter(%view) : !memref_gmem_f32_1
      %iter_66 = cute.get_iter(%view) : !memref_gmem_f32_1
      %coord_67 = cute.make_coord(%26) : (i32) -> !cute.coord<"(_,?)">
      %lay_68 = cute.get_layout(%arg1) : !memref_gmem_i8_
      %idx_69 = cute.crd2idx(%coord_67, %lay_68) : (!cute.coord<"(_,?)">, !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !cute.int_tuple<"?{i64}">
      %iter_70 = cute.get_iter(%arg1) : !memref_gmem_i8_
      %ptr_71 = cute.add_offset(%iter_70, %idx_69) : (!cute.ptr<i8, gmem, align<16>>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<i8, gmem>
      %view_72 = cute.make_view(%ptr_71) : !memref_gmem_i8_1
      %iter_73 = cute.get_iter(%view_72) : !memref_gmem_i8_1
      %iter_74 = cute.get_iter(%view_72) : !memref_gmem_i8_1
      %coord_75 = cute.make_coord(%26) : (i32) -> !cute.coord<"(_,?)">
      %lay_76 = cute.get_layout(%arg2) : !cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">
      %idx_77 = cute.crd2idx(%coord_75, %lay_76) : (!cute.coord<"(_,?)">, !cute.layout<"((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">) -> !cute.int_tuple<"(?,?{div=1024},?)">
      %iter_78 = cute.get_iter(%arg2) : !cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">
      %tup = cute.add_offset(%iter_78, %idx_77) : (!cute.int_tuple<"(0,0,0)">, !cute.int_tuple<"(?,?{div=1024},?)">) -> !cute.int_tuple<"(?,?{div=1024},?)">
      %view_79 = cute.make_view(%tup) : !cute.coord_tensor<"(?,?{div=1024},?)", "((1,1024,1)):((0,1@1,0))">
      %iter_80 = cute.get_iter(%view_79) : !cute.coord_tensor<"(?,?{div=1024},?)", "((1,1024,1)):((0,1@1,0))">
      %e0_81, %e1_82, %e2_83 = cute.get_leaves(%iter_80) : !cute.int_tuple<"(?,?{div=1024},?)">
      %27 = cute.get_scalars(%e0_81) : !cute.int_tuple<"?">
      %28 = cute.get_scalars(%e1_82) : !cute.int_tuple<"?{div=1024}">
      %29 = cute.get_scalars(%e2_83) : !cute.int_tuple<"?">
      %iter_84 = cute.get_iter(%view_79) : !cute.coord_tensor<"(?,?{div=1024},?)", "((1,1024,1)):((0,1@1,0))">
      %e0_85, %e1_86, %e2_87 = cute.get_leaves(%iter_84) : !cute.int_tuple<"(?,?{div=1024},?)">
      %30 = cute.get_scalars(%e0_85) : !cute.int_tuple<"?">
      %31 = cute.get_scalars(%e1_86) : !cute.int_tuple<"?{div=1024}">
      %32 = cute.get_scalars(%e2_87) : !cute.int_tuple<"?">
      %iter_88 = cute.get_iter(%view) : !memref_gmem_f32_1
      %view_89 = cute.make_view(%iter_88) : !memref_gmem_f32_2
      %iter_90 = cute.get_iter(%view_89) : !memref_gmem_f32_2
      %iter_91 = cute.get_iter(%view_72) : !memref_gmem_i8_1
      %view_92 = cute.make_view(%iter_91) : !memref_gmem_i8_2
      %iter_93 = cute.get_iter(%view_92) : !memref_gmem_i8_2
      %iter_94 = cute.get_iter(%view_79) : !cute.coord_tensor<"(?,?{div=1024},?)", "((1,1024,1)):((0,1@1,0))">
      %view_95 = cute.make_view(%iter_94) : !cute.coord_tensor<"(?,?{div=1024},?)", "(128,8):(8@1,1@1)">
      %iter_96 = cute.get_iter(%view_95) : !cute.coord_tensor<"(?,?{div=1024},?)", "(128,8):(8@1,1@1)">
      %e0_97, %e1_98, %e2_99 = cute.get_leaves(%iter_96) : !cute.int_tuple<"(?,?{div=1024},?)">
      %33 = cute.get_scalars(%e0_97) : !cute.int_tuple<"?">
      %34 = cute.get_scalars(%e1_98) : !cute.int_tuple<"?{div=1024}">
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
      %lay_117 = cute.get_layout(%view_95) : !cute.coord_tensor<"(?,?{div=1024},?)", "(128,8):(8@1,1@1)">
      %idx_118 = cute.crd2idx(%coord_116, %lay_117) : (!cute.coord<"(?,_)">, !cute.layout<"(128,8):(8@1,1@1)">) -> !cute.int_tuple<"(0,?{div=8})">
      %iter_119 = cute.get_iter(%view_95) : !cute.coord_tensor<"(?,?{div=1024},?)", "(128,8):(8@1,1@1)">
      %tup_120 = cute.add_offset(%iter_119, %idx_118) : (!cute.int_tuple<"(?,?{div=1024},?)">, !cute.int_tuple<"(0,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8},?)">
      %view_121 = cute.make_view(%tup_120) : !cute.coord_tensor<"(?,?{div=8},?)", "(8):(1@1)">
      %iter_122 = cute.get_iter(%view_121) : !cute.coord_tensor<"(?,?{div=8},?)", "(8):(1@1)">
      %e0_123, %e1_124, %e2_125 = cute.get_leaves(%iter_122) : !cute.int_tuple<"(?,?{div=8},?)">
      %36 = cute.get_scalars(%e0_123) : !cute.int_tuple<"?">
      %37 = cute.get_scalars(%e1_124) : !cute.int_tuple<"?{div=8}">
      %38 = cute.get_scalars(%e2_125) : !cute.int_tuple<"?">
      %iter_126 = cute.get_iter(%view_121) : !cute.coord_tensor<"(?,?{div=8},?)", "(8):(1@1)">
      %e0_127, %e1_128, %e2_129 = cute.get_leaves(%iter_126) : !cute.int_tuple<"(?,?{div=8},?)">
      %39 = cute.get_scalars(%e0_127) : !cute.int_tuple<"?">
      %40 = cute.get_scalars(%e1_128) : !cute.int_tuple<"?{div=8}">
      %41 = cute.get_scalars(%e2_129) : !cute.int_tuple<"?">
      %coord_130 = cute.make_coord() : () -> !cute.coord<"0">
      %lay_131 = cute.get_layout(%view_121) : !cute.coord_tensor<"(?,?{div=8},?)", "(8):(1@1)">
      %idx_132 = cute.crd2idx(%coord_130, %lay_131) : (!cute.coord<"0">, !cute.layout<"(8):(1@1)">) -> !cute.int_tuple<"(0,0)">
      %iter_133 = cute.get_iter(%view_121) : !cute.coord_tensor<"(?,?{div=8},?)", "(8):(1@1)">
      %tup_134 = cute.add_offset(%iter_133, %idx_132) : (!cute.int_tuple<"(?,?{div=8},?)">, !cute.int_tuple<"(0,0)">) -> !cute.int_tuple<"(?,?{div=8},?)">
      %view_135 = cute.make_view(%tup_134) : !cute.coord_tensor<"(?,?{div=8},?)", "():()">
      %iter_136 = cute.get_iter(%view_135) : !cute.coord_tensor<"(?,?{div=8},?)", "():()">
      %e0_137, %e1_138, %e2_139 = cute.get_leaves(%iter_136) : !cute.int_tuple<"(?,?{div=8},?)">
      %42 = cute.get_scalars(%e0_137) : !cute.int_tuple<"?">
      %43 = cute.get_scalars(%e1_138) : !cute.int_tuple<"?{div=8}">
      %44 = cute.get_scalars(%e2_139) : !cute.int_tuple<"?">
      %iter_140 = cute.get_iter(%view_135) : !cute.coord_tensor<"(?,?{div=8},?)", "():()">
      %e0_141, %e1_142, %e2_143 = cute.get_leaves(%iter_140) : !cute.int_tuple<"(?,?{div=8},?)">
      %45 = cute.get_scalars(%e0_141) : !cute.int_tuple<"?">
      %46 = cute.get_scalars(%e1_142) : !cute.int_tuple<"?{div=8}">
      %47 = cute.get_scalars(%e2_143) : !cute.int_tuple<"?">
      %iter_144 = cute.get_iter(%view_135) : !cute.coord_tensor<"(?,?{div=8},?)", "():()">
      %e0_145, %e1_146, %e2_147 = cute.get_leaves(%iter_144) : !cute.int_tuple<"(?,?{div=8},?)">
      %48 = cute.get_scalars(%e0_145) : !cute.int_tuple<"?">
      %49 = cute.get_scalars(%e1_146) : !cute.int_tuple<"?{div=8}">
      %50 = cute.get_scalars(%e2_147) : !cute.int_tuple<"?">
      %coord_148 = cute.make_coord(%e0_145, %e1_146, %e2_147) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?{div=8},?)">
      %coord_149 = cute.make_coord(%arg3, %arg4, %arg5) : (i32, i32, i32) -> !cute.coord<"(?,?,?)">
      %51:3 = cute.get_scalars(%coord_148) : !cute.coord<"(?,?{div=8},?)">
      %52:3 = cute.get_scalars(%coord_149) : !cute.coord<"(?,?,?)">
      %true = arith.constant true
      %53 = arith.cmpi slt, %51#0, %52#0 : i32
      %54 = arith.andi %true, %53 : i1
      %55 = arith.cmpi slt, %51#1, %52#1 : i32
      %56 = arith.andi %54, %55 : i1
      %57 = arith.cmpi slt, %51#2, %52#2 : i32
      %58 = arith.andi %56, %57 : i1
      scf.if %58 {
        %59 = cute.get_shape(%0) : (!cute.layout<"(128,8):(8,1)">) -> !cute.shape<"(128,8)">
        %e0_150, %e1_151 = cute.get_leaves(%59) : !cute.shape<"(128,8)">
        %60 = cute.get_shape(%0) : (!cute.layout<"(128,8):(8,1)">) -> !cute.shape<"(128,8)">
        %e0_152, %e1_153 = cute.get_leaves(%60) : !cute.shape<"(128,8)">
        %lay_154 = cute.make_layout() : !cute.layout<"8:1">
        %rmem = cute.memref.alloca(%lay_154) : !memref_rmem_f32_
        %iter_155 = cute.get_iter(%rmem) : !memref_rmem_f32_
        %iter_156 = cute.get_iter(%rmem) : !memref_rmem_f32_
        %61 = cute.get_shape(%1) : (!cute.layout<"(128,4):(4,1)">) -> !cute.shape<"(128,4)">
        %e0_157, %e1_158 = cute.get_leaves(%61) : !cute.shape<"(128,4)">
        %62 = cute.get_shape(%1) : (!cute.layout<"(128,4):(4,1)">) -> !cute.shape<"(128,4)">
        %e0_159, %e1_160 = cute.get_leaves(%62) : !cute.shape<"(128,4)">
        %lay_161 = cute.make_layout() : !cute.layout<"4:1">
        %rmem_162 = cute.memref.alloca(%lay_161) : !memref_rmem_i8_
        %iter_163 = cute.get_iter(%rmem_162) : !memref_rmem_i8_
        %iter_164 = cute.get_iter(%rmem_162) : !memref_rmem_i8_
        %atom = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<f32>
        %lay_165 = cute.get_layout(%view_105) : !memref_gmem_f32_3
        %63 = cute.get_shape(%lay_165) : (!cute.layout<"(8):(1)">) -> !cute.shape<"(8)">
        %e0_166 = cute.get_leaves(%63) : !cute.shape<"(8)">
        %lay_167 = cute.get_layout(%rmem) : !memref_rmem_f32_
        %64 = cute.get_shape(%lay_167) : (!cute.layout<"8:1">) -> !cute.shape<"8">
        %e0_168 = cute.get_leaves(%64) : !cute.shape<"8">
        %lay_169 = cute.get_layout(%view_105) : !memref_gmem_f32_3
        %shape = cute.make_shape() : () -> !cute.shape<"1">
        %lay_170 = cute.make_layout() : !cute.layout<"1:0">
        %append = cute.append_to_rank<2> (%lay_169, %lay_170) : !cute.layout<"(8):(1)">, !cute.layout<"1:0">
        %view_171 = cute.make_view(%iter_107, %append) : !memref_gmem_f32_4
        %iter_172 = cute.get_iter(%view_171) : !memref_gmem_f32_4
        %lay_173 = cute.get_layout(%view_171) : !memref_gmem_f32_4
        %65 = cute.get_shape(%lay_173) : (!cute.layout<"(8,1):(1,0)">) -> !cute.shape<"(8,1)">
        %e0_174, %e1_175 = cute.get_leaves(%65) : !cute.shape<"(8,1)">
        %iter_176 = cute.get_iter(%view_171) : !memref_gmem_f32_4
        %view_177 = cute.make_view(%iter_176) : !memref_gmem_f32_5
        %iter_178 = cute.get_iter(%view_177) : !memref_gmem_f32_5
        %iter_179 = cute.get_iter(%view_177) : !memref_gmem_f32_5
        %lay_180 = cute.get_layout(%rmem) : !memref_rmem_f32_
        %shape_181 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_182 = cute.make_layout() : !cute.layout<"1:0">
        %append_183 = cute.append_to_rank<2> (%lay_180, %lay_182) : !cute.layout<"8:1">, !cute.layout<"1:0">
        %view_184 = cute.make_view(%iter_156, %append_183) : !memref_rmem_f32_1
        %iter_185 = cute.get_iter(%view_184) : !memref_rmem_f32_1
        %lay_186 = cute.get_layout(%view_184) : !memref_rmem_f32_1
        %66 = cute.get_shape(%lay_186) : (!cute.layout<"(8,1):(1,0)">) -> !cute.shape<"(8,1)">
        %e0_187, %e1_188 = cute.get_leaves(%66) : !cute.shape<"(8,1)">
        %iter_189 = cute.get_iter(%view_184) : !memref_rmem_f32_1
        %view_190 = cute.make_view(%iter_189) : !memref_rmem_f32_2
        %iter_191 = cute.get_iter(%view_190) : !memref_rmem_f32_2
        %iter_192 = cute.get_iter(%view_190) : !memref_rmem_f32_2
        %lay_193 = cute.get_layout(%view_177) : !memref_gmem_f32_5
        %67 = cute.get_shape(%lay_193) : (!cute.layout<"(8,(1)):(1,(0))">) -> !cute.shape<"(8,(1))">
        %e0_194, %e1_195 = cute.get_leaves(%67) : !cute.shape<"(8,(1))">
        %lay_196 = cute.get_layout(%view_190) : !memref_rmem_f32_2
        %68 = cute.get_shape(%lay_196) : (!cute.layout<"(8,(1)):(1,(0))">) -> !cute.shape<"(8,(1))">
        %e0_197, %e1_198 = cute.get_leaves(%68) : !cute.shape<"(8,(1))">
        %lay_199 = cute.get_layout(%view_177) : !memref_gmem_f32_5
        %sz = cute.size(%lay_199) <{mode = [1]}> : (!cute.layout<"(8,(1)):(1,(0))">) -> !cute.int_tuple<"1">
        %e0_200 = cute.get_leaves(%sz) : !cute.int_tuple<"1">
        %lay_201 = cute.get_layout(%view_190) : !memref_rmem_f32_2
        %sz_202 = cute.size(%lay_201) <{mode = [1]}> : (!cute.layout<"(8,(1)):(1,(0))">) -> !cute.int_tuple<"1">
        %e0_203 = cute.get_leaves(%sz_202) : !cute.int_tuple<"1">
        %69 = cute.static : !cute.layout<"1:0">
        %iter_204 = cute.get_iter(%view_177) : !memref_gmem_f32_5
        %iter_205 = cute.get_iter(%view_190) : !memref_rmem_f32_2
        %lay_206 = cute.get_layout(%view_177) : !memref_gmem_f32_5
        %lay_207 = cute.get_layout(%view_190) : !memref_rmem_f32_2
        %append_208 = cute.append_to_rank<2> (%lay_206, %69) : !cute.layout<"(8,(1)):(1,(0))">, !cute.layout<"1:0">
        %append_209 = cute.append_to_rank<2> (%lay_207, %69) : !cute.layout<"(8,(1)):(1,(0))">, !cute.layout<"1:0">
        %lay_210 = cute.make_layout() : !cute.layout<"(8,((1))):(1,((0)))">
        %lay_211 = cute.make_layout() : !cute.layout<"(8,((1))):(1,((0)))">
        %sz_212 = cute.size(%lay_210) <{mode = [1]}> : (!cute.layout<"(8,((1))):(1,((0)))">) -> !cute.int_tuple<"1">
        %70 = cute.get_scalars(%sz_212) : !cute.int_tuple<"1">
        %c0_i32 = arith.constant 0 : i32
        %c1_i32 = arith.constant 1 : i32
        scf.for %arg6 = %c0_i32 to %70 step %c1_i32  : i32 {
          %coord_275 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
          %85 = cute.get_scalars(%coord_275) <{only_dynamic}> : !cute.coord<"(_,?)">
          %lay_276 = cute.make_layout() : !cute.layout<"(8):(1)">
          %idx_277 = cute.crd2idx(%coord_275, %lay_210) : (!cute.coord<"(_,?)">, !cute.layout<"(8,((1))):(1,((0)))">) -> !cute.int_tuple<"0">
          %ptr_278 = cute.add_offset(%iter_204, %idx_277) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<f32, gmem>
          %view_279 = cute.make_view(%ptr_278, %lay_276) : !memref_gmem_f32_3
          %86 = cute.get_scalars(%coord_275) <{only_dynamic}> : !cute.coord<"(_,?)">
          %lay_280 = cute.make_layout() : !cute.layout<"(8):(1)">
          %idx_281 = cute.crd2idx(%coord_275, %lay_211) : (!cute.coord<"(_,?)">, !cute.layout<"(8,((1))):(1,((0)))">) -> !cute.int_tuple<"0">
          %ptr_282 = cute.add_offset(%iter_205, %idx_281) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, rmem, align<32>>
          %view_283 = cute.make_view(%ptr_282, %lay_280) : !memref_rmem_f32_3
          %iter_284 = cute.get_iter(%view_279) : !memref_gmem_f32_3
          %iter_285 = cute.get_iter(%view_283) : !memref_rmem_f32_3
          %87 = builtin.unrealized_conversion_cast %iter_284 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %88 = builtin.unrealized_conversion_cast %iter_285 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
          %89 = llvm.load %87 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %89, %88 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          %int_tuple_286 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
          %ptr_287 = cute.add_offset(%iter_284, %int_tuple_286) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
          %int_tuple_288 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
          %ptr_289 = cute.add_offset(%iter_285, %int_tuple_288) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
          %90 = builtin.unrealized_conversion_cast %ptr_287 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %91 = builtin.unrealized_conversion_cast %ptr_289 : !cute.ptr<f32, rmem> to !llvm.ptr
          %92 = llvm.load %90 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %92, %91 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          %int_tuple_290 = cute.make_int_tuple() : () -> !cute.int_tuple<"2">
          %ptr_291 = cute.add_offset(%iter_284, %int_tuple_290) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
          %int_tuple_292 = cute.make_int_tuple() : () -> !cute.int_tuple<"2">
          %ptr_293 = cute.add_offset(%iter_285, %int_tuple_292) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
          %93 = builtin.unrealized_conversion_cast %ptr_291 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %94 = builtin.unrealized_conversion_cast %ptr_293 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %95 = llvm.load %93 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %95, %94 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          %int_tuple_294 = cute.make_int_tuple() : () -> !cute.int_tuple<"3">
          %ptr_295 = cute.add_offset(%iter_284, %int_tuple_294) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
          %int_tuple_296 = cute.make_int_tuple() : () -> !cute.int_tuple<"3">
          %ptr_297 = cute.add_offset(%iter_285, %int_tuple_296) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
          %96 = builtin.unrealized_conversion_cast %ptr_295 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %97 = builtin.unrealized_conversion_cast %ptr_297 : !cute.ptr<f32, rmem> to !llvm.ptr
          %98 = llvm.load %96 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %98, %97 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          %int_tuple_298 = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
          %ptr_299 = cute.add_offset(%iter_284, %int_tuple_298) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"4">) -> !cute.ptr<f32, gmem>
          %int_tuple_300 = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
          %ptr_301 = cute.add_offset(%iter_285, %int_tuple_300) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
          %99 = builtin.unrealized_conversion_cast %ptr_299 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %100 = builtin.unrealized_conversion_cast %ptr_301 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
          %101 = llvm.load %99 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %101, %100 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          %int_tuple_302 = cute.make_int_tuple() : () -> !cute.int_tuple<"5">
          %ptr_303 = cute.add_offset(%iter_284, %int_tuple_302) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"5">) -> !cute.ptr<f32, gmem>
          %int_tuple_304 = cute.make_int_tuple() : () -> !cute.int_tuple<"5">
          %ptr_305 = cute.add_offset(%iter_285, %int_tuple_304) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<f32, rmem>
          %102 = builtin.unrealized_conversion_cast %ptr_303 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %103 = builtin.unrealized_conversion_cast %ptr_305 : !cute.ptr<f32, rmem> to !llvm.ptr
          %104 = llvm.load %102 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %104, %103 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          %int_tuple_306 = cute.make_int_tuple() : () -> !cute.int_tuple<"6">
          %ptr_307 = cute.add_offset(%iter_284, %int_tuple_306) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"6">) -> !cute.ptr<f32, gmem>
          %int_tuple_308 = cute.make_int_tuple() : () -> !cute.int_tuple<"6">
          %ptr_309 = cute.add_offset(%iter_285, %int_tuple_308) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
          %105 = builtin.unrealized_conversion_cast %ptr_307 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %106 = builtin.unrealized_conversion_cast %ptr_309 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %107 = llvm.load %105 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %107, %106 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          %int_tuple_310 = cute.make_int_tuple() : () -> !cute.int_tuple<"7">
          %ptr_311 = cute.add_offset(%iter_284, %int_tuple_310) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"7">) -> !cute.ptr<f32, gmem>
          %int_tuple_312 = cute.make_int_tuple() : () -> !cute.int_tuple<"7">
          %ptr_313 = cute.add_offset(%iter_285, %int_tuple_312) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<f32, rmem>
          %108 = builtin.unrealized_conversion_cast %ptr_311 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %109 = builtin.unrealized_conversion_cast %ptr_313 : !cute.ptr<f32, rmem> to !llvm.ptr
          %110 = llvm.load %108 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %110, %109 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %71 = cute.memref.load_vec %rmem : !memref_rmem_f32_
        %72 = nvgpu.cvt_fptrunc %71 : vector<8xf32> to vector<8xf4E2M1FN>
        %shape_213 = cute.make_shape() : () -> !cute.shape<"8">
        %lay_214 = cute.make_layout() : !cute.layout<"8:1">
        %73 = cute.recast_layout<8, 4> (%lay_214) : !cute.layout<"8:1"> to !cute.layout<"4:1">
        %74 = cute.get_shape(%73) : (!cute.layout<"4:1">) -> !cute.shape<"4">
        %e0_215 = cute.get_leaves(%74) : !cute.shape<"4">
        %75 = builtin.unrealized_conversion_cast %72 : vector<8xf4E2M1FN> to vector<8xi4>
        %76 = vector.bitcast %75 : vector<8xi4> to vector<4xi8>
        %lay_216 = cute.get_layout(%rmem_162) : !memref_rmem_i8_
        %77 = cute.get_shape(%lay_216) : (!cute.layout<"4:1">) -> !cute.shape<"4">
        %e0_217 = cute.get_leaves(%77) : !cute.shape<"4">
        %int_tuple = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
        %sz_218 = cute.size(%int_tuple) : (!cute.int_tuple<"4">) -> !cute.int_tuple<"4">
        %e0_219 = cute.get_leaves(%sz_218) : !cute.int_tuple<"4">
        %int_tuple_220 = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
        %sz_221 = cute.size(%int_tuple_220) : (!cute.int_tuple<"4">) -> !cute.int_tuple<"4">
        %e0_222 = cute.get_leaves(%sz_221) : !cute.int_tuple<"4">
        cute.memref.store_vec %76, %rmem_162 : !memref_rmem_i8_
        %atom_223 = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<i8>
        %lay_224 = cute.get_layout(%view_113) : !memref_gmem_i8_3
        %78 = cute.get_shape(%lay_224) : (!cute.layout<"(4):(1)">) -> !cute.shape<"(4)">
        %e0_225 = cute.get_leaves(%78) : !cute.shape<"(4)">
        %lay_226 = cute.get_layout(%rmem_162) : !memref_rmem_i8_
        %shape_227 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_228 = cute.make_layout() : !cute.layout<"1:0">
        %append_229 = cute.append_to_rank<2> (%lay_226, %lay_228) : !cute.layout<"4:1">, !cute.layout<"1:0">
        %view_230 = cute.make_view(%iter_164, %append_229) : !memref_rmem_i8_1
        %iter_231 = cute.get_iter(%view_230) : !memref_rmem_i8_1
        %lay_232 = cute.get_layout(%view_230) : !memref_rmem_i8_1
        %79 = cute.get_shape(%lay_232) : (!cute.layout<"(4,1):(1,0)">) -> !cute.shape<"(4,1)">
        %e0_233, %e1_234 = cute.get_leaves(%79) : !cute.shape<"(4,1)">
        %iter_235 = cute.get_iter(%view_230) : !memref_rmem_i8_1
        %view_236 = cute.make_view(%iter_235) : !memref_rmem_i8_2
        %iter_237 = cute.get_iter(%view_236) : !memref_rmem_i8_2
        %iter_238 = cute.get_iter(%view_236) : !memref_rmem_i8_2
        %lay_239 = cute.get_layout(%view_113) : !memref_gmem_i8_3
        %shape_240 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_241 = cute.make_layout() : !cute.layout<"1:0">
        %append_242 = cute.append_to_rank<2> (%lay_239, %lay_241) : !cute.layout<"(4):(1)">, !cute.layout<"1:0">
        %view_243 = cute.make_view(%iter_115, %append_242) : !memref_gmem_i8_4
        %iter_244 = cute.get_iter(%view_243) : !memref_gmem_i8_4
        %lay_245 = cute.get_layout(%view_243) : !memref_gmem_i8_4
        %80 = cute.get_shape(%lay_245) : (!cute.layout<"(4,1):(1,0)">) -> !cute.shape<"(4,1)">
        %e0_246, %e1_247 = cute.get_leaves(%80) : !cute.shape<"(4,1)">
        %iter_248 = cute.get_iter(%view_243) : !memref_gmem_i8_4
        %view_249 = cute.make_view(%iter_248) : !memref_gmem_i8_5
        %iter_250 = cute.get_iter(%view_249) : !memref_gmem_i8_5
        %iter_251 = cute.get_iter(%view_249) : !memref_gmem_i8_5
        %lay_252 = cute.get_layout(%view_236) : !memref_rmem_i8_2
        %81 = cute.get_shape(%lay_252) : (!cute.layout<"(4,(1)):(1,(0))">) -> !cute.shape<"(4,(1))">
        %e0_253, %e1_254 = cute.get_leaves(%81) : !cute.shape<"(4,(1))">
        %lay_255 = cute.get_layout(%view_249) : !memref_gmem_i8_5
        %82 = cute.get_shape(%lay_255) : (!cute.layout<"(4,(1)):(1,(0))">) -> !cute.shape<"(4,(1))">
        %e0_256, %e1_257 = cute.get_leaves(%82) : !cute.shape<"(4,(1))">
        %lay_258 = cute.get_layout(%view_236) : !memref_rmem_i8_2
        %sz_259 = cute.size(%lay_258) <{mode = [1]}> : (!cute.layout<"(4,(1)):(1,(0))">) -> !cute.int_tuple<"1">
        %e0_260 = cute.get_leaves(%sz_259) : !cute.int_tuple<"1">
        %lay_261 = cute.get_layout(%view_249) : !memref_gmem_i8_5
        %sz_262 = cute.size(%lay_261) <{mode = [1]}> : (!cute.layout<"(4,(1)):(1,(0))">) -> !cute.int_tuple<"1">
        %e0_263 = cute.get_leaves(%sz_262) : !cute.int_tuple<"1">
        %83 = cute.static : !cute.layout<"1:0">
        %iter_264 = cute.get_iter(%view_236) : !memref_rmem_i8_2
        %iter_265 = cute.get_iter(%view_249) : !memref_gmem_i8_5
        %lay_266 = cute.get_layout(%view_236) : !memref_rmem_i8_2
        %lay_267 = cute.get_layout(%view_249) : !memref_gmem_i8_5
        %append_268 = cute.append_to_rank<2> (%lay_266, %83) : !cute.layout<"(4,(1)):(1,(0))">, !cute.layout<"1:0">
        %append_269 = cute.append_to_rank<2> (%lay_267, %83) : !cute.layout<"(4,(1)):(1,(0))">, !cute.layout<"1:0">
        %lay_270 = cute.make_layout() : !cute.layout<"(4,((1))):(1,((0)))">
        %lay_271 = cute.make_layout() : !cute.layout<"(4,((1))):(1,((0)))">
        %sz_272 = cute.size(%lay_270) <{mode = [1]}> : (!cute.layout<"(4,((1))):(1,((0)))">) -> !cute.int_tuple<"1">
        %84 = cute.get_scalars(%sz_272) : !cute.int_tuple<"1">
        %c0_i32_273 = arith.constant 0 : i32
        %c1_i32_274 = arith.constant 1 : i32
        scf.for %arg6 = %c0_i32_273 to %84 step %c1_i32_274  : i32 {
          %coord_275 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
          %85 = cute.get_scalars(%coord_275) <{only_dynamic}> : !cute.coord<"(_,?)">
          %lay_276 = cute.make_layout() : !cute.layout<"(4):(1)">
          %idx_277 = cute.crd2idx(%coord_275, %lay_270) : (!cute.coord<"(_,?)">, !cute.layout<"(4,((1))):(1,((0)))">) -> !cute.int_tuple<"0">
          %ptr_278 = cute.add_offset(%iter_264, %idx_277) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
          %view_279 = cute.make_view(%ptr_278, %lay_276) : !memref_rmem_i8_3
          %86 = cute.get_scalars(%coord_275) <{only_dynamic}> : !cute.coord<"(_,?)">
          %lay_280 = cute.make_layout() : !cute.layout<"(4):(1)">
          %idx_281 = cute.crd2idx(%coord_275, %lay_271) : (!cute.coord<"(_,?)">, !cute.layout<"(4,((1))):(1,((0)))">) -> !cute.int_tuple<"0">
          %ptr_282 = cute.add_offset(%iter_265, %idx_281) : (!cute.ptr<i8, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<i8, gmem>
          %view_283 = cute.make_view(%ptr_282, %lay_280) : !memref_gmem_i8_3
          %iter_284 = cute.get_iter(%view_279) : !memref_rmem_i8_3
          %iter_285 = cute.get_iter(%view_283) : !memref_gmem_i8_3
          %87 = builtin.unrealized_conversion_cast %iter_284 : !cute.ptr<i8, rmem, align<32>> to !llvm.ptr
          %88 = builtin.unrealized_conversion_cast %iter_285 : !cute.ptr<i8, gmem> to !llvm.ptr<1>
          %89 = llvm.load %87 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
          llvm.store %89, %88 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
          %int_tuple_286 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
          %ptr_287 = cute.add_offset(%iter_284, %int_tuple_286) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
          %int_tuple_288 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
          %ptr_289 = cute.add_offset(%iter_285, %int_tuple_288) : (!cute.ptr<i8, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<i8, gmem>
          %90 = builtin.unrealized_conversion_cast %ptr_287 : !cute.ptr<i8, rmem> to !llvm.ptr
          %91 = builtin.unrealized_conversion_cast %ptr_289 : !cute.ptr<i8, gmem> to !llvm.ptr<1>
          %92 = llvm.load %90 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
          llvm.store %92, %91 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
          %int_tuple_290 = cute.make_int_tuple() : () -> !cute.int_tuple<"2">
          %ptr_291 = cute.add_offset(%iter_284, %int_tuple_290) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem, align<2>>
          %int_tuple_292 = cute.make_int_tuple() : () -> !cute.int_tuple<"2">
          %ptr_293 = cute.add_offset(%iter_285, %int_tuple_292) : (!cute.ptr<i8, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<i8, gmem>
          %93 = builtin.unrealized_conversion_cast %ptr_291 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
          %94 = builtin.unrealized_conversion_cast %ptr_293 : !cute.ptr<i8, gmem> to !llvm.ptr<1>
          %95 = llvm.load %93 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
          llvm.store %95, %94 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
          %int_tuple_294 = cute.make_int_tuple() : () -> !cute.int_tuple<"3">
          %ptr_295 = cute.add_offset(%iter_284, %int_tuple_294) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
          %int_tuple_296 = cute.make_int_tuple() : () -> !cute.int_tuple<"3">
          %ptr_297 = cute.add_offset(%iter_285, %int_tuple_296) : (!cute.ptr<i8, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<i8, gmem>
          %96 = builtin.unrealized_conversion_cast %ptr_295 : !cute.ptr<i8, rmem> to !llvm.ptr
          %97 = builtin.unrealized_conversion_cast %ptr_297 : !cute.ptr<i8, gmem> to !llvm.ptr<1>
          %98 = llvm.load %96 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
          llvm.store %98, %97 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
        } {llvm.loop_annotation = #loop_annotation}
      }
      return
    }
  }
  func.func @cutlass__convert_Tensorgmemoi641i64_Tensorgmemoi641i64_1_8(%arg0: !memref_gmem_f32_6, %arg1: !memref_gmem_f4E2M1FN) -> i32 attributes {llvm.emit_c_interface} {
    %iter = cute.get_iter(%arg0) : !memref_gmem_f32_6
    %iter_0 = cute.get_iter(%arg1) : !memref_gmem_f4E2M1FN
    %iter_1 = cute.get_iter(%arg0) : !memref_gmem_f32_6
    %iter_2 = cute.get_iter(%arg1) : !memref_gmem_f4E2M1FN
    %lay = cute.get_layout(%arg0) : !memref_gmem_f32_6
    %0 = cute.get_shape(%lay) : (!cute.layout<"(?,?,?):(?{i64},1,?{i64})">) -> !cute.shape<"(?,?,?)">
    %e0, %e1, %e2 = cute.get_leaves(%0) : !cute.shape<"(?,?,?)">
    %itup = cute.to_int_tuple(%e0) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %1 = cute.get_scalars(%itup) : !cute.int_tuple<"?">
    %itup_3 = cute.to_int_tuple(%e1) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %2 = cute.get_scalars(%itup_3) : !cute.int_tuple<"?">
    %itup_4 = cute.to_int_tuple(%e2) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %3 = cute.get_scalars(%itup_4) : !cute.int_tuple<"?">
    %4 = cute.get_stride(%lay) : (!cute.layout<"(?,?,?):(?{i64},1,?{i64})">) -> !cute.stride<"(?{i64},1,?{i64})">
    %e0_5, %e1_6, %e2_7 = cute.get_leaves(%4) : !cute.stride<"(?{i64},1,?{i64})">
    %itup_8 = cute.to_int_tuple(%e0_5) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
    %5 = cute.get_scalars(%itup_8) : !cute.int_tuple<"?{i64}">
    %itup_9 = cute.to_int_tuple(%e2_7) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
    %6 = cute.get_scalars(%itup_9) : !cute.int_tuple<"?{i64}">
    %lay_10 = cute.get_layout(%arg1) : !memref_gmem_f4E2M1FN
    %7 = cute.get_shape(%lay_10) : (!cute.layout<"(?,?,?):(?{i64},1,?{i64})">) -> !cute.shape<"(?,?,?)">
    %e0_11, %e1_12, %e2_13 = cute.get_leaves(%7) : !cute.shape<"(?,?,?)">
    %itup_14 = cute.to_int_tuple(%e0_11) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %8 = cute.get_scalars(%itup_14) : !cute.int_tuple<"?">
    %itup_15 = cute.to_int_tuple(%e1_12) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %9 = cute.get_scalars(%itup_15) : !cute.int_tuple<"?">
    %itup_16 = cute.to_int_tuple(%e2_13) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %10 = cute.get_scalars(%itup_16) : !cute.int_tuple<"?">
    %11 = cute.get_stride(%lay_10) : (!cute.layout<"(?,?,?):(?{i64},1,?{i64})">) -> !cute.stride<"(?{i64},1,?{i64})">
    %e0_17, %e1_18, %e2_19 = cute.get_leaves(%11) : !cute.stride<"(?{i64},1,?{i64})">
    %itup_20 = cute.to_int_tuple(%e0_17) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
    %12 = cute.get_scalars(%itup_20) : !cute.int_tuple<"?{i64}">
    %itup_21 = cute.to_int_tuple(%e2_19) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
    %13 = cute.get_scalars(%itup_21) : !cute.int_tuple<"?{i64}">
    %shape = cute.make_shape() : () -> !cute.shape<"(128,8)">
    %stride = cute.make_stride() : () -> !cute.stride<"(8,1)">
    %lay_22 = cute.make_layout() : !cute.layout<"(128,8):(8,1)">
    %14 = cute.recast_layout<8, 4> (%lay_22) : !cute.layout<"(128,8):(8,1)"> to !cute.layout<"(128,4):(4,1)">
    %iter_23 = cute.recast_iter(%iter_2) : !cute.ptr<f4E2M1FN, gmem, align<16>> to !cute.ptr<i8, gmem, align<16>>
    %lay_24 = cute.get_layout(%arg1) : !memref_gmem_f4E2M1FN
    %15 = cute.recast_layout<8, 4> (%lay_24) : !cute.layout<"(?,?,?):(?{i64},1,?{i64})"> to !cute.layout<"(?,?,?):(?{i64},1,?{i64})">
    %view = cute.make_view(%iter_23, %15) : !memref_gmem_i8_6
    %iter_25 = cute.get_iter(%view) : !memref_gmem_i8_6
    %lay_26 = cute.get_layout(%arg0) : !memref_gmem_f32_6
    %16 = cute.get_shape(%lay_26) : (!cute.layout<"(?,?,?):(?{i64},1,?{i64})">) -> !cute.shape<"(?,?,?)">
    %e0_27, %e1_28, %e2_29 = cute.get_leaves(%16) : !cute.shape<"(?,?,?)">
    %itup_30 = cute.to_int_tuple(%e0_27) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %17 = cute.get_scalars(%itup_30) : !cute.int_tuple<"?">
    %itup_31 = cute.to_int_tuple(%e1_28) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %18 = cute.get_scalars(%itup_31) : !cute.int_tuple<"?">
    %itup_32 = cute.to_int_tuple(%e2_29) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %19 = cute.get_scalars(%itup_32) : !cute.int_tuple<"?">
    %shape_33 = cute.make_shape(%itup_30, %itup_31, %itup_32) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.shape<"(?,?,?)">
    %int_tuple = cute.make_int_tuple() : () -> !cute.int_tuple<"(0,0,0)">
    %stride_34 = cute.make_stride() : () -> !cute.stride<"(1@0,1@1,1@2)">
    %lay_35 = cute.make_layout(%shape_33, %stride_34) : !cute.layout<"(?,?,?):(1@0,1@1,1@2)">
    %view_36 = cute.make_view(%int_tuple, %lay_35) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">
    %iter_37 = cute.get_iter(%view_36) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">
    %e0_38, %e1_39, %e2_40 = cute.get_leaves(%iter_37) : !cute.int_tuple<"(0,0,0)">
    %lay_41 = cute.get_layout(%arg0) : !memref_gmem_f32_6
    %20 = cute.get_shape(%lay_41) : (!cute.layout<"(?,?,?):(?{i64},1,?{i64})">) -> !cute.shape<"(?,?,?)">
    %e0_42, %e1_43, %e2_44 = cute.get_leaves(%20) : !cute.shape<"(?,?,?)">
    %itup_45 = cute.to_int_tuple(%e0_42) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %21 = cute.get_scalars(%itup_45) : !cute.int_tuple<"?">
    %itup_46 = cute.to_int_tuple(%e1_43) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %22 = cute.get_scalars(%itup_46) : !cute.int_tuple<"?">
    %itup_47 = cute.to_int_tuple(%e2_44) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %23 = cute.get_scalars(%itup_47) : !cute.int_tuple<"?">
    %sz = cute.size(%lay_22) : (!cute.layout<"(128,8):(8,1)">) -> !cute.int_tuple<"1024">
    %e0_48 = cute.get_leaves(%sz) : !cute.int_tuple<"1024">
    %lay_49 = cute.get_layout(%view) : !memref_gmem_i8_6
    %24 = cute.get_shape(%lay_49) : (!cute.layout<"(?,?,?):(?{i64},1,?{i64})">) -> !cute.shape<"(?,?,?)">
    %e0_50, %e1_51, %e2_52 = cute.get_leaves(%24) : !cute.shape<"(?,?,?)">
    %itup_53 = cute.to_int_tuple(%e0_50) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %25 = cute.get_scalars(%itup_53) : !cute.int_tuple<"?">
    %itup_54 = cute.to_int_tuple(%e1_51) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %26 = cute.get_scalars(%itup_54) : !cute.int_tuple<"?">
    %itup_55 = cute.to_int_tuple(%e2_52) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %27 = cute.get_scalars(%itup_55) : !cute.int_tuple<"?">
    %sz_56 = cute.size(%14) : (!cute.layout<"(128,4):(4,1)">) -> !cute.int_tuple<"512">
    %e0_57 = cute.get_leaves(%sz_56) : !cute.int_tuple<"512">
    %tile = cute.make_tile() : () -> !cute.tile<"[1:0;1024:1;1:0]">
    %iter_58 = cute.get_iter(%arg0) : !memref_gmem_f32_6
    %lay_59 = cute.get_layout(%arg0) : !memref_gmem_f32_6
    %28:5 = cute.get_scalars(%lay_59) <{only_dynamic}> : !cute.layout<"(?,?,?):(?{i64},1,?{i64})">
    %c1024_i32 = arith.constant 1024 : i32
    %29 = arith.ceildivsi %28#1, %c1024_i32 : i32
    %shape_60 = cute.make_shape(%28#0, %29, %28#2) : (i32, i32, i32) -> !cute.shape<"((1,1024,1),(?,?,?))">
    %stride_61 = cute.make_stride(%28#3, %28#4) : (i64, i64) -> !cute.stride<"((0,1,0),(?{i64},1024,?{i64}))">
    %lay_62 = cute.make_layout(%shape_60, %stride_61) : !cute.layout<"((1,1024,1),(?,?,?)):((0,1,0),(?{i64},1024,?{i64}))">
    %view_63 = cute.make_view(%iter_58, %lay_62) : !memref_gmem_f32_
    %iter_64 = cute.get_iter(%view_63) : !memref_gmem_f32_
    %iter_65 = cute.get_iter(%view_63) : !memref_gmem_f32_
    %tile_66 = cute.make_tile() : () -> !cute.tile<"[1:0;1024:1;1:0]">
    %iter_67 = cute.get_iter(%view_36) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">
    %lay_68 = cute.get_layout(%view_36) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">
    %30:3 = cute.get_scalars(%lay_68) <{only_dynamic}> : !cute.layout<"(?,?,?):(1@0,1@1,1@2)">
    %c1024_i32_69 = arith.constant 1024 : i32
    %31 = arith.ceildivsi %30#1, %c1024_i32_69 : i32
    %shape_70 = cute.make_shape(%30#0, %31, %30#2) : (i32, i32, i32) -> !cute.shape<"((1,1024,1),(?,?,?))">
    %stride_71 = cute.make_stride() : () -> !cute.stride<"((0,1@1,0),(1@0,1024@1,1@2))">
    %lay_72 = cute.make_layout(%shape_70, %stride_71) : !cute.layout<"((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">
    %view_73 = cute.make_view(%iter_67, %lay_72) : !cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">
    %iter_74 = cute.get_iter(%view_73) : !cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">
    %e0_75, %e1_76, %e2_77 = cute.get_leaves(%iter_74) : !cute.int_tuple<"(0,0,0)">
    %iter_78 = cute.get_iter(%view_73) : !cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">
    %e0_79, %e1_80, %e2_81 = cute.get_leaves(%iter_78) : !cute.int_tuple<"(0,0,0)">
    %tile_82 = cute.make_tile() : () -> !cute.tile<"[1:0;512:1;1:0]">
    %iter_83 = cute.get_iter(%view) : !memref_gmem_i8_6
    %lay_84 = cute.get_layout(%view) : !memref_gmem_i8_6
    %32:5 = cute.get_scalars(%lay_84) <{only_dynamic}> : !cute.layout<"(?,?,?):(?{i64},1,?{i64})">
    %c512_i32 = arith.constant 512 : i32
    %33 = arith.ceildivsi %32#1, %c512_i32 : i32
    %shape_85 = cute.make_shape(%32#0, %33, %32#2) : (i32, i32, i32) -> !cute.shape<"((1,512,1),(?,?,?))">
    %stride_86 = cute.make_stride(%32#3, %32#4) : (i64, i64) -> !cute.stride<"((0,1,0),(?{i64},512,?{i64}))">
    %lay_87 = cute.make_layout(%shape_85, %stride_86) : !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">
    %view_88 = cute.make_view(%iter_83, %lay_87) : !memref_gmem_i8_
    %iter_89 = cute.get_iter(%view_88) : !memref_gmem_i8_
    %iter_90 = cute.get_iter(%view_88) : !memref_gmem_i8_
    %lay_91 = cute.get_layout(%view_63) : !memref_gmem_f32_
    %sz_92 = cute.size(%lay_91) <{mode = [1]}> : (!cute.layout<"((1,1024,1),(?,?,?)):((0,1,0),(?{i64},1024,?{i64}))">) -> !cute.int_tuple<"?">
    %e0_93 = cute.get_leaves(%sz_92) : !cute.int_tuple<"?">
    %34 = cute.get_scalars(%e0_93) : !cute.int_tuple<"?">
    %sz_94 = cute.size(%lay_22) <{mode = [0]}> : (!cute.layout<"(128,8):(8,1)">) -> !cute.int_tuple<"128">
    %e0_95 = cute.get_leaves(%sz_94) : !cute.int_tuple<"128">
    %lay_96 = cute.get_layout(%view_63) : !memref_gmem_f32_
    %35 = cute.get_shape(%lay_96) : (!cute.layout<"((1,1024,1),(?,?,?)):((0,1,0),(?{i64},1024,?{i64}))">) -> !cute.shape<"((1,1024,1),(?,?,?))">
    %e0_97, %e1_98, %e2_99, %e3, %e4, %e5 = cute.get_leaves(%35) : !cute.shape<"((1,1024,1),(?,?,?))">
    %itup_100 = cute.to_int_tuple(%e3) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %36 = cute.get_scalars(%itup_100) : !cute.int_tuple<"?">
    %itup_101 = cute.to_int_tuple(%e4) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %37 = cute.get_scalars(%itup_101) : !cute.int_tuple<"?">
    %itup_102 = cute.to_int_tuple(%e5) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %38 = cute.get_scalars(%itup_102) : !cute.int_tuple<"?">
    %39 = cute.get_stride(%lay_96) : (!cute.layout<"((1,1024,1),(?,?,?)):((0,1,0),(?{i64},1024,?{i64}))">) -> !cute.stride<"((0,1,0),(?{i64},1024,?{i64}))">
    %e0_103, %e1_104, %e2_105, %e3_106, %e4_107, %e5_108 = cute.get_leaves(%39) : !cute.stride<"((0,1,0),(?{i64},1024,?{i64}))">
    %itup_109 = cute.to_int_tuple(%e3_106) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
    %40 = cute.get_scalars(%itup_109) : !cute.int_tuple<"?{i64}">
    %itup_110 = cute.to_int_tuple(%e5_108) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
    %41 = cute.get_scalars(%itup_110) : !cute.int_tuple<"?{i64}">
    %lay_111 = cute.get_layout(%view_88) : !memref_gmem_i8_
    %42 = cute.get_shape(%lay_111) : (!cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !cute.shape<"((1,512,1),(?,?,?))">
    %e0_112, %e1_113, %e2_114, %e3_115, %e4_116, %e5_117 = cute.get_leaves(%42) : !cute.shape<"((1,512,1),(?,?,?))">
    %itup_118 = cute.to_int_tuple(%e3_115) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %43 = cute.get_scalars(%itup_118) : !cute.int_tuple<"?">
    %itup_119 = cute.to_int_tuple(%e4_116) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %44 = cute.get_scalars(%itup_119) : !cute.int_tuple<"?">
    %itup_120 = cute.to_int_tuple(%e5_117) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %45 = cute.get_scalars(%itup_120) : !cute.int_tuple<"?">
    %46 = cute.get_stride(%lay_111) : (!cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !cute.stride<"((0,1,0),(?{i64},512,?{i64}))">
    %e0_121, %e1_122, %e2_123, %e3_124, %e4_125, %e5_126 = cute.get_leaves(%46) : !cute.stride<"((0,1,0),(?{i64},512,?{i64}))">
    %itup_127 = cute.to_int_tuple(%e3_124) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
    %47 = cute.get_scalars(%itup_127) : !cute.int_tuple<"?{i64}">
    %itup_128 = cute.to_int_tuple(%e5_126) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
    %48 = cute.get_scalars(%itup_128) : !cute.int_tuple<"?{i64}">
    %lay_129 = cute.get_layout(%view_73) : !cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">
    %49 = cute.get_shape(%lay_129) : (!cute.layout<"((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">) -> !cute.shape<"((1,1024,1),(?,?,?))">
    %e0_130, %e1_131, %e2_132, %e3_133, %e4_134, %e5_135 = cute.get_leaves(%49) : !cute.shape<"((1,1024,1),(?,?,?))">
    %itup_136 = cute.to_int_tuple(%e3_133) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %50 = cute.get_scalars(%itup_136) : !cute.int_tuple<"?">
    %itup_137 = cute.to_int_tuple(%e4_134) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %51 = cute.get_scalars(%itup_137) : !cute.int_tuple<"?">
    %itup_138 = cute.to_int_tuple(%e5_135) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %52 = cute.get_scalars(%itup_138) : !cute.int_tuple<"?">
    %53 = cute.get_stride(%lay_129) : (!cute.layout<"((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">) -> !cute.stride<"((0,1@1,0),(1@0,1024@1,1@2))">
    %e0_139, %e1_140, %e2_141, %e3_142, %e4_143, %e5_144 = cute.get_leaves(%53) : !cute.stride<"((0,1@1,0),(1@0,1024@1,1@2))">
    %54 = cute.get_shape(%lay_22) : (!cute.layout<"(128,8):(8,1)">) -> !cute.shape<"(128,8)">
    %e0_145, %e1_146 = cute.get_leaves(%54) : !cute.shape<"(128,8)">
    %55 = cute.get_stride(%lay_22) : (!cute.layout<"(128,8):(8,1)">) -> !cute.stride<"(8,1)">
    %e0_147, %e1_148 = cute.get_leaves(%55) : !cute.stride<"(8,1)">
    %56 = cute.get_shape(%14) : (!cute.layout<"(128,4):(4,1)">) -> !cute.shape<"(128,4)">
    %e0_149, %e1_150 = cute.get_leaves(%56) : !cute.shape<"(128,4)">
    %57 = cute.get_stride(%14) : (!cute.layout<"(128,4):(4,1)">) -> !cute.stride<"(4,1)">
    %e0_151, %e1_152 = cute.get_leaves(%57) : !cute.stride<"(4,1)">
    %c0_i32 = arith.constant 0 : i32
    %c0_i64 = arith.constant 0 : i64
    %58 = cuda.cast %c0_i64 : i64 -> !cuda.stream
    %59 = arith.extsi %c0_i32 : i32 to i64
    %c128_i32 = arith.constant 128 : i32
    %c1_i32 = arith.constant 1 : i32
    %60 = cuda.launch_cfg.create<max_attrs = 2 : i32> (blockDim = (%c128_i32, %c1_i32, %c1_i32), dynamicSmemBytes = %59, gridDim = (%34, %c1_i32, %c1_i32), stream = %58) : i32, i32, i32, i64, i32, i32, i32, !cuda.stream -> !cuda.launch_cfg<max_attrs = 2>
    %61 = cuda.launch_ex @kernels::@kernel_cutlass__convert_kernel_tensorptrf32gmemo1102410101024_tensorptri8gmemalign16o15121010512_tensor000o1102410110101024112____Float32_Float4E2M1FN_0<%60> (%view_63, %view_88, %view_73, %17, %18, %19) : !cuda.launch_cfg<max_attrs = 2>, (!memref_gmem_f32_, !memref_gmem_i8_, !cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">, i32, i32, i32) -> !cuda.result
    %62 = cuda.cast %61 : !cuda.result -> i32
    cuda.return_if_error %62 : i32
    %c0_i32_153 = arith.constant 0 : i32
    return %c0_i32_153 : i32
  }
}
