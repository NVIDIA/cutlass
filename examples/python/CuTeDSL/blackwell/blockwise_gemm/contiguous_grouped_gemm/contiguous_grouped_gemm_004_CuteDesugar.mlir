!memref_gmem_f32_ = !cute.memref<f32, gmem, "((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">
!memref_gmem_f32_1 = !cute.memref<f32, gmem, "((1,512,1)):((0,1,0))">
!memref_gmem_f32_2 = !cute.memref<f32, gmem, "(128,4):(4,1)">
!memref_gmem_f32_3 = !cute.memref<f32, gmem, "(4):(1)">
!memref_gmem_f32_4 = !cute.memref<f32, gmem, "(4,1):(1,0)">
!memref_gmem_f32_5 = !cute.memref<f32, gmem, "(4,(1)):(1,(0))">
!memref_gmem_f32_6 = !cute.memref<f32, gmem, "(?,?,?):(?{i64},1,?{i64})">
!memref_gmem_f8E4M3FN = !cute.memref<f8E4M3FN, gmem, align<16>, "((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">
!memref_gmem_f8E4M3FN1 = !cute.memref<f8E4M3FN, gmem, "((1,512,1)):((0,1,0))">
!memref_gmem_f8E4M3FN2 = !cute.memref<f8E4M3FN, gmem, "(128,4):(4,1)">
!memref_gmem_f8E4M3FN3 = !cute.memref<f8E4M3FN, gmem, "(4):(1)">
!memref_gmem_f8E4M3FN4 = !cute.memref<f8E4M3FN, gmem, "(4,1):(1,0)">
!memref_gmem_f8E4M3FN5 = !cute.memref<f8E4M3FN, gmem, "(4,(1)):(1,(0))">
!memref_gmem_f8E4M3FN6 = !cute.memref<f8E4M3FN, gmem, align<16>, "(?,?,?):(?{i64},1,?{i64})">
!memref_rmem_f32_ = !cute.memref<f32, rmem, align<32>, "4:1">
!memref_rmem_f32_1 = !cute.memref<f32, rmem, align<32>, "(4,1):(1,0)">
!memref_rmem_f32_2 = !cute.memref<f32, rmem, align<32>, "(4,(1)):(1,(0))">
!memref_rmem_f32_3 = !cute.memref<f32, rmem, align<32>, "(4):(1)">
!memref_rmem_f8E4M3FN = !cute.memref<f8E4M3FN, rmem, align<32>, "4:1">
!memref_rmem_f8E4M3FN1 = !cute.memref<f8E4M3FN, rmem, align<32>, "(4,1):(1,0)">
!memref_rmem_f8E4M3FN2 = !cute.memref<f8E4M3FN, rmem, align<32>, "(4,(1)):(1,(0))">
!memref_rmem_f8E4M3FN3 = !cute.memref<f8E4M3FN, rmem, align<32>, "(4):(1)">
#loop_unroll = #llvm.loop_unroll<disable = false, full = true>
#loop_annotation = #llvm.loop_annotation<unroll = #loop_unroll>
module attributes {gpu.container_module} {
  gpu.module @kernels {
    cuda.kernel @kernel_cutlass__convert_kernel_tensorptrf32gmemo15121010512_tensorptrf8E4M3FNgmemalign16o15121010512_tensor000o15121011010512112____Float32_Float8E4M3FN_0(%arg0: !memref_gmem_f32_, %arg1: !memref_gmem_f8E4M3FN, %arg2: !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">, %arg3: i32, %arg4: i32, %arg5: i32) attributes {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} {
      %0 = cute.static : !cute.layout<"(128,4):(4,1)">
      %1 = cute.static : !cute.layout<"(128,4):(4,1)">
      %iter = cute.get_iter(%arg0) : !memref_gmem_f32_
      %iter_0 = cute.get_iter(%arg1) : !memref_gmem_f8E4M3FN
      %iter_1 = cute.get_iter(%arg2) : !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">
      %e0, %e1, %e2 = cute.get_leaves(%iter_1) : !cute.int_tuple<"(0,0,0)">
      %iter_2 = cute.get_iter(%arg0) : !memref_gmem_f32_
      %iter_3 = cute.get_iter(%arg1) : !memref_gmem_f8E4M3FN
      %iter_4 = cute.get_iter(%arg2) : !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">
      %e0_5, %e1_6, %e2_7 = cute.get_leaves(%iter_4) : !cute.int_tuple<"(0,0,0)">
      %lay = cute.get_layout(%arg0) : !memref_gmem_f32_
      %2 = cute.get_shape(%lay) : (!cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !cute.shape<"((1,512,1),(?,?,?))">
      %e0_8, %e1_9, %e2_10, %e3, %e4, %e5 = cute.get_leaves(%2) : !cute.shape<"((1,512,1),(?,?,?))">
      %itup = cute.to_int_tuple(%e3) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %3 = cute.get_scalars(%itup) : !cute.int_tuple<"?">
      %itup_11 = cute.to_int_tuple(%e4) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %4 = cute.get_scalars(%itup_11) : !cute.int_tuple<"?">
      %itup_12 = cute.to_int_tuple(%e5) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %5 = cute.get_scalars(%itup_12) : !cute.int_tuple<"?">
      %6 = cute.get_stride(%lay) : (!cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !cute.stride<"((0,1,0),(?{i64},512,?{i64}))">
      %e0_13, %e1_14, %e2_15, %e3_16, %e4_17, %e5_18 = cute.get_leaves(%6) : !cute.stride<"((0,1,0),(?{i64},512,?{i64}))">
      %itup_19 = cute.to_int_tuple(%e3_16) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
      %7 = cute.get_scalars(%itup_19) : !cute.int_tuple<"?{i64}">
      %itup_20 = cute.to_int_tuple(%e5_18) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
      %8 = cute.get_scalars(%itup_20) : !cute.int_tuple<"?{i64}">
      %lay_21 = cute.get_layout(%arg1) : !memref_gmem_f8E4M3FN
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
      %lay_39 = cute.get_layout(%arg2) : !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">
      %16 = cute.get_shape(%lay_39) : (!cute.layout<"((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">) -> !cute.shape<"((1,512,1),(?,?,?))">
      %e0_40, %e1_41, %e2_42, %e3_43, %e4_44, %e5_45 = cute.get_leaves(%16) : !cute.shape<"((1,512,1),(?,?,?))">
      %itup_46 = cute.to_int_tuple(%e3_43) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %17 = cute.get_scalars(%itup_46) : !cute.int_tuple<"?">
      %itup_47 = cute.to_int_tuple(%e4_44) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %18 = cute.get_scalars(%itup_47) : !cute.int_tuple<"?">
      %itup_48 = cute.to_int_tuple(%e5_45) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %19 = cute.get_scalars(%itup_48) : !cute.int_tuple<"?">
      %20 = cute.get_stride(%lay_39) : (!cute.layout<"((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">) -> !cute.stride<"((0,1@1,0),(1@0,512@1,1@2))">
      %e0_49, %e1_50, %e2_51, %e3_52, %e4_53, %e5_54 = cute.get_leaves(%20) : !cute.stride<"((0,1@1,0),(1@0,512@1,1@2))">
      %21 = cute.get_shape(%0) : (!cute.layout<"(128,4):(4,1)">) -> !cute.shape<"(128,4)">
      %e0_55, %e1_56 = cute.get_leaves(%21) : !cute.shape<"(128,4)">
      %22 = cute.get_stride(%0) : (!cute.layout<"(128,4):(4,1)">) -> !cute.stride<"(4,1)">
      %e0_57, %e1_58 = cute.get_leaves(%22) : !cute.stride<"(4,1)">
      %23 = cute.get_shape(%1) : (!cute.layout<"(128,4):(4,1)">) -> !cute.shape<"(128,4)">
      %e0_59, %e1_60 = cute.get_leaves(%23) : !cute.shape<"(128,4)">
      %24 = cute.get_stride(%1) : (!cute.layout<"(128,4):(4,1)">) -> !cute.stride<"(4,1)">
      %e0_61, %e1_62 = cute.get_leaves(%24) : !cute.stride<"(4,1)">
      %25 = nvvm.read.ptx.sreg.tid.x : i32
      %26 = nvvm.read.ptx.sreg.ctaid.x : i32
      %coord = cute.make_coord(%26) : (i32) -> !cute.coord<"(_,?)">
      %lay_63 = cute.get_layout(%arg0) : !memref_gmem_f32_
      %idx = cute.crd2idx(%coord, %lay_63) : (!cute.coord<"(_,?)">, !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !cute.int_tuple<"?{i64}">
      %iter_64 = cute.get_iter(%arg0) : !memref_gmem_f32_
      %ptr = cute.add_offset(%iter_64, %idx) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %view = cute.make_view(%ptr) : !memref_gmem_f32_1
      %iter_65 = cute.get_iter(%view) : !memref_gmem_f32_1
      %iter_66 = cute.get_iter(%view) : !memref_gmem_f32_1
      %coord_67 = cute.make_coord(%26) : (i32) -> !cute.coord<"(_,?)">
      %lay_68 = cute.get_layout(%arg1) : !memref_gmem_f8E4M3FN
      %idx_69 = cute.crd2idx(%coord_67, %lay_68) : (!cute.coord<"(_,?)">, !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !cute.int_tuple<"?{i64}">
      %iter_70 = cute.get_iter(%arg1) : !memref_gmem_f8E4M3FN
      %ptr_71 = cute.add_offset(%iter_70, %idx_69) : (!cute.ptr<f8E4M3FN, gmem, align<16>>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f8E4M3FN, gmem>
      %view_72 = cute.make_view(%ptr_71) : !memref_gmem_f8E4M3FN1
      %iter_73 = cute.get_iter(%view_72) : !memref_gmem_f8E4M3FN1
      %iter_74 = cute.get_iter(%view_72) : !memref_gmem_f8E4M3FN1
      %coord_75 = cute.make_coord(%26) : (i32) -> !cute.coord<"(_,?)">
      %lay_76 = cute.get_layout(%arg2) : !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">
      %idx_77 = cute.crd2idx(%coord_75, %lay_76) : (!cute.coord<"(_,?)">, !cute.layout<"((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">) -> !cute.int_tuple<"(?,?{div=512},?)">
      %iter_78 = cute.get_iter(%arg2) : !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">
      %tup = cute.add_offset(%iter_78, %idx_77) : (!cute.int_tuple<"(0,0,0)">, !cute.int_tuple<"(?,?{div=512},?)">) -> !cute.int_tuple<"(?,?{div=512},?)">
      %view_79 = cute.make_view(%tup) : !cute.coord_tensor<"(?,?{div=512},?)", "((1,512,1)):((0,1@1,0))">
      %iter_80 = cute.get_iter(%view_79) : !cute.coord_tensor<"(?,?{div=512},?)", "((1,512,1)):((0,1@1,0))">
      %e0_81, %e1_82, %e2_83 = cute.get_leaves(%iter_80) : !cute.int_tuple<"(?,?{div=512},?)">
      %27 = cute.get_scalars(%e0_81) : !cute.int_tuple<"?">
      %28 = cute.get_scalars(%e1_82) : !cute.int_tuple<"?{div=512}">
      %29 = cute.get_scalars(%e2_83) : !cute.int_tuple<"?">
      %iter_84 = cute.get_iter(%view_79) : !cute.coord_tensor<"(?,?{div=512},?)", "((1,512,1)):((0,1@1,0))">
      %e0_85, %e1_86, %e2_87 = cute.get_leaves(%iter_84) : !cute.int_tuple<"(?,?{div=512},?)">
      %30 = cute.get_scalars(%e0_85) : !cute.int_tuple<"?">
      %31 = cute.get_scalars(%e1_86) : !cute.int_tuple<"?{div=512}">
      %32 = cute.get_scalars(%e2_87) : !cute.int_tuple<"?">
      %iter_88 = cute.get_iter(%view) : !memref_gmem_f32_1
      %view_89 = cute.make_view(%iter_88) : !memref_gmem_f32_2
      %iter_90 = cute.get_iter(%view_89) : !memref_gmem_f32_2
      %iter_91 = cute.get_iter(%view_72) : !memref_gmem_f8E4M3FN1
      %view_92 = cute.make_view(%iter_91) : !memref_gmem_f8E4M3FN2
      %iter_93 = cute.get_iter(%view_92) : !memref_gmem_f8E4M3FN2
      %iter_94 = cute.get_iter(%view_79) : !cute.coord_tensor<"(?,?{div=512},?)", "((1,512,1)):((0,1@1,0))">
      %view_95 = cute.make_view(%iter_94) : !cute.coord_tensor<"(?,?{div=512},?)", "(128,4):(4@1,1@1)">
      %iter_96 = cute.get_iter(%view_95) : !cute.coord_tensor<"(?,?{div=512},?)", "(128,4):(4@1,1@1)">
      %e0_97, %e1_98, %e2_99 = cute.get_leaves(%iter_96) : !cute.int_tuple<"(?,?{div=512},?)">
      %33 = cute.get_scalars(%e0_97) : !cute.int_tuple<"?">
      %34 = cute.get_scalars(%e1_98) : !cute.int_tuple<"?{div=512}">
      %35 = cute.get_scalars(%e2_99) : !cute.int_tuple<"?">
      %coord_100 = cute.make_coord(%25) : (i32) -> !cute.coord<"(?,_)">
      %lay_101 = cute.get_layout(%view_89) : !memref_gmem_f32_2
      %idx_102 = cute.crd2idx(%coord_100, %lay_101) : (!cute.coord<"(?,_)">, !cute.layout<"(128,4):(4,1)">) -> !cute.int_tuple<"?{div=4}">
      %iter_103 = cute.get_iter(%view_89) : !memref_gmem_f32_2
      %ptr_104 = cute.add_offset(%iter_103, %idx_102) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, gmem>
      %view_105 = cute.make_view(%ptr_104) : !memref_gmem_f32_3
      %iter_106 = cute.get_iter(%view_105) : !memref_gmem_f32_3
      %iter_107 = cute.get_iter(%view_105) : !memref_gmem_f32_3
      %coord_108 = cute.make_coord(%25) : (i32) -> !cute.coord<"(?,_)">
      %lay_109 = cute.get_layout(%view_92) : !memref_gmem_f8E4M3FN2
      %idx_110 = cute.crd2idx(%coord_108, %lay_109) : (!cute.coord<"(?,_)">, !cute.layout<"(128,4):(4,1)">) -> !cute.int_tuple<"?{div=4}">
      %iter_111 = cute.get_iter(%view_92) : !memref_gmem_f8E4M3FN2
      %ptr_112 = cute.add_offset(%iter_111, %idx_110) : (!cute.ptr<f8E4M3FN, gmem>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f8E4M3FN, gmem>
      %view_113 = cute.make_view(%ptr_112) : !memref_gmem_f8E4M3FN3
      %iter_114 = cute.get_iter(%view_113) : !memref_gmem_f8E4M3FN3
      %iter_115 = cute.get_iter(%view_113) : !memref_gmem_f8E4M3FN3
      %coord_116 = cute.make_coord(%25) : (i32) -> !cute.coord<"(?,_)">
      %lay_117 = cute.get_layout(%view_95) : !cute.coord_tensor<"(?,?{div=512},?)", "(128,4):(4@1,1@1)">
      %idx_118 = cute.crd2idx(%coord_116, %lay_117) : (!cute.coord<"(?,_)">, !cute.layout<"(128,4):(4@1,1@1)">) -> !cute.int_tuple<"(0,?{div=4})">
      %iter_119 = cute.get_iter(%view_95) : !cute.coord_tensor<"(?,?{div=512},?)", "(128,4):(4@1,1@1)">
      %tup_120 = cute.add_offset(%iter_119, %idx_118) : (!cute.int_tuple<"(?,?{div=512},?)">, !cute.int_tuple<"(0,?{div=4})">) -> !cute.int_tuple<"(?,?{div=4},?)">
      %view_121 = cute.make_view(%tup_120) : !cute.coord_tensor<"(?,?{div=4},?)", "(4):(1@1)">
      %iter_122 = cute.get_iter(%view_121) : !cute.coord_tensor<"(?,?{div=4},?)", "(4):(1@1)">
      %e0_123, %e1_124, %e2_125 = cute.get_leaves(%iter_122) : !cute.int_tuple<"(?,?{div=4},?)">
      %36 = cute.get_scalars(%e0_123) : !cute.int_tuple<"?">
      %37 = cute.get_scalars(%e1_124) : !cute.int_tuple<"?{div=4}">
      %38 = cute.get_scalars(%e2_125) : !cute.int_tuple<"?">
      %iter_126 = cute.get_iter(%view_121) : !cute.coord_tensor<"(?,?{div=4},?)", "(4):(1@1)">
      %e0_127, %e1_128, %e2_129 = cute.get_leaves(%iter_126) : !cute.int_tuple<"(?,?{div=4},?)">
      %39 = cute.get_scalars(%e0_127) : !cute.int_tuple<"?">
      %40 = cute.get_scalars(%e1_128) : !cute.int_tuple<"?{div=4}">
      %41 = cute.get_scalars(%e2_129) : !cute.int_tuple<"?">
      %coord_130 = cute.make_coord() : () -> !cute.coord<"0">
      %lay_131 = cute.get_layout(%view_121) : !cute.coord_tensor<"(?,?{div=4},?)", "(4):(1@1)">
      %idx_132 = cute.crd2idx(%coord_130, %lay_131) : (!cute.coord<"0">, !cute.layout<"(4):(1@1)">) -> !cute.int_tuple<"(0,0)">
      %iter_133 = cute.get_iter(%view_121) : !cute.coord_tensor<"(?,?{div=4},?)", "(4):(1@1)">
      %tup_134 = cute.add_offset(%iter_133, %idx_132) : (!cute.int_tuple<"(?,?{div=4},?)">, !cute.int_tuple<"(0,0)">) -> !cute.int_tuple<"(?,?{div=4},?)">
      %view_135 = cute.make_view(%tup_134) : !cute.coord_tensor<"(?,?{div=4},?)", "():()">
      %iter_136 = cute.get_iter(%view_135) : !cute.coord_tensor<"(?,?{div=4},?)", "():()">
      %e0_137, %e1_138, %e2_139 = cute.get_leaves(%iter_136) : !cute.int_tuple<"(?,?{div=4},?)">
      %42 = cute.get_scalars(%e0_137) : !cute.int_tuple<"?">
      %43 = cute.get_scalars(%e1_138) : !cute.int_tuple<"?{div=4}">
      %44 = cute.get_scalars(%e2_139) : !cute.int_tuple<"?">
      %iter_140 = cute.get_iter(%view_135) : !cute.coord_tensor<"(?,?{div=4},?)", "():()">
      %e0_141, %e1_142, %e2_143 = cute.get_leaves(%iter_140) : !cute.int_tuple<"(?,?{div=4},?)">
      %45 = cute.get_scalars(%e0_141) : !cute.int_tuple<"?">
      %46 = cute.get_scalars(%e1_142) : !cute.int_tuple<"?{div=4}">
      %47 = cute.get_scalars(%e2_143) : !cute.int_tuple<"?">
      %iter_144 = cute.get_iter(%view_135) : !cute.coord_tensor<"(?,?{div=4},?)", "():()">
      %e0_145, %e1_146, %e2_147 = cute.get_leaves(%iter_144) : !cute.int_tuple<"(?,?{div=4},?)">
      %48 = cute.get_scalars(%e0_145) : !cute.int_tuple<"?">
      %49 = cute.get_scalars(%e1_146) : !cute.int_tuple<"?{div=4}">
      %50 = cute.get_scalars(%e2_147) : !cute.int_tuple<"?">
      %coord_148 = cute.make_coord(%e0_145, %e1_146, %e2_147) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=4}">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?{div=4},?)">
      %coord_149 = cute.make_coord(%arg3, %arg4, %arg5) : (i32, i32, i32) -> !cute.coord<"(?,?,?)">
      %51 = cute.elem_less(%coord_148, %coord_149) : !cute.coord<"(?,?{div=4},?)">, !cute.coord<"(?,?,?)">
      scf.if %51 {
        %52 = cute.get_shape(%0) : (!cute.layout<"(128,4):(4,1)">) -> !cute.shape<"(128,4)">
        %e0_150, %e1_151 = cute.get_leaves(%52) : !cute.shape<"(128,4)">
        %53 = cute.get_shape(%0) : (!cute.layout<"(128,4):(4,1)">) -> !cute.shape<"(128,4)">
        %e0_152, %e1_153 = cute.get_leaves(%53) : !cute.shape<"(128,4)">
        %54 = cute.get(%0) <{mode = [1]}> : !cute.layout<"(128,4):(4,1)"> -> !cute.layout<"4:1">
        %rmem = cute.memref.alloca(%54) : !memref_rmem_f32_
        %iter_154 = cute.get_iter(%rmem) : !memref_rmem_f32_
        %iter_155 = cute.get_iter(%rmem) : !memref_rmem_f32_
        %55 = cute.get_shape(%1) : (!cute.layout<"(128,4):(4,1)">) -> !cute.shape<"(128,4)">
        %e0_156, %e1_157 = cute.get_leaves(%55) : !cute.shape<"(128,4)">
        %56 = cute.get_shape(%1) : (!cute.layout<"(128,4):(4,1)">) -> !cute.shape<"(128,4)">
        %e0_158, %e1_159 = cute.get_leaves(%56) : !cute.shape<"(128,4)">
        %57 = cute.get(%1) <{mode = [1]}> : !cute.layout<"(128,4):(4,1)"> -> !cute.layout<"4:1">
        %rmem_160 = cute.memref.alloca(%57) : !memref_rmem_f8E4M3FN
        %iter_161 = cute.get_iter(%rmem_160) : !memref_rmem_f8E4M3FN
        %iter_162 = cute.get_iter(%rmem_160) : !memref_rmem_f8E4M3FN
        %atom = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<f32>
        %lay_163 = cute.get_layout(%view_105) : !memref_gmem_f32_3
        %58 = cute.get_shape(%lay_163) : (!cute.layout<"(4):(1)">) -> !cute.shape<"(4)">
        %e0_164 = cute.get_leaves(%58) : !cute.shape<"(4)">
        %lay_165 = cute.get_layout(%rmem) : !memref_rmem_f32_
        %59 = cute.get_shape(%lay_165) : (!cute.layout<"4:1">) -> !cute.shape<"4">
        %e0_166 = cute.get_leaves(%59) : !cute.shape<"4">
        %lay_167 = cute.get_layout(%view_105) : !memref_gmem_f32_3
        %shape = cute.make_shape() : () -> !cute.shape<"1">
        %lay_168 = cute.make_layout() : !cute.layout<"1:0">
        %append = cute.append_to_rank<2> (%lay_167, %lay_168) : !cute.layout<"(4):(1)">, !cute.layout<"1:0">
        %view_169 = cute.make_view(%iter_107, %append) : !memref_gmem_f32_4
        %iter_170 = cute.get_iter(%view_169) : !memref_gmem_f32_4
        %lay_171 = cute.get_layout(%view_169) : !memref_gmem_f32_4
        %60 = cute.get_shape(%lay_171) : (!cute.layout<"(4,1):(1,0)">) -> !cute.shape<"(4,1)">
        %e0_172, %e1_173 = cute.get_leaves(%60) : !cute.shape<"(4,1)">
        %iter_174 = cute.get_iter(%view_169) : !memref_gmem_f32_4
        %view_175 = cute.make_view(%iter_174) : !memref_gmem_f32_5
        %iter_176 = cute.get_iter(%view_175) : !memref_gmem_f32_5
        %iter_177 = cute.get_iter(%view_175) : !memref_gmem_f32_5
        %lay_178 = cute.get_layout(%rmem) : !memref_rmem_f32_
        %shape_179 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_180 = cute.make_layout() : !cute.layout<"1:0">
        %append_181 = cute.append_to_rank<2> (%lay_178, %lay_180) : !cute.layout<"4:1">, !cute.layout<"1:0">
        %view_182 = cute.make_view(%iter_155, %append_181) : !memref_rmem_f32_1
        %iter_183 = cute.get_iter(%view_182) : !memref_rmem_f32_1
        %lay_184 = cute.get_layout(%view_182) : !memref_rmem_f32_1
        %61 = cute.get_shape(%lay_184) : (!cute.layout<"(4,1):(1,0)">) -> !cute.shape<"(4,1)">
        %e0_185, %e1_186 = cute.get_leaves(%61) : !cute.shape<"(4,1)">
        %iter_187 = cute.get_iter(%view_182) : !memref_rmem_f32_1
        %view_188 = cute.make_view(%iter_187) : !memref_rmem_f32_2
        %iter_189 = cute.get_iter(%view_188) : !memref_rmem_f32_2
        %iter_190 = cute.get_iter(%view_188) : !memref_rmem_f32_2
        %lay_191 = cute.get_layout(%view_175) : !memref_gmem_f32_5
        %62 = cute.get_shape(%lay_191) : (!cute.layout<"(4,(1)):(1,(0))">) -> !cute.shape<"(4,(1))">
        %e0_192, %e1_193 = cute.get_leaves(%62) : !cute.shape<"(4,(1))">
        %lay_194 = cute.get_layout(%view_188) : !memref_rmem_f32_2
        %63 = cute.get_shape(%lay_194) : (!cute.layout<"(4,(1)):(1,(0))">) -> !cute.shape<"(4,(1))">
        %e0_195, %e1_196 = cute.get_leaves(%63) : !cute.shape<"(4,(1))">
        %lay_197 = cute.get_layout(%view_175) : !memref_gmem_f32_5
        %sz = cute.size(%lay_197) <{mode = [1]}> : (!cute.layout<"(4,(1)):(1,(0))">) -> !cute.int_tuple<"1">
        %e0_198 = cute.get_leaves(%sz) : !cute.int_tuple<"1">
        %lay_199 = cute.get_layout(%view_188) : !memref_rmem_f32_2
        %sz_200 = cute.size(%lay_199) <{mode = [1]}> : (!cute.layout<"(4,(1)):(1,(0))">) -> !cute.int_tuple<"1">
        %e0_201 = cute.get_leaves(%sz_200) : !cute.int_tuple<"1">
        %64 = cute.static : !cute.layout<"1:0">
        %iter_202 = cute.get_iter(%view_175) : !memref_gmem_f32_5
        %iter_203 = cute.get_iter(%view_188) : !memref_rmem_f32_2
        %lay_204 = cute.get_layout(%view_175) : !memref_gmem_f32_5
        %lay_205 = cute.get_layout(%view_188) : !memref_rmem_f32_2
        %append_206 = cute.append_to_rank<2> (%lay_204, %64) : !cute.layout<"(4,(1)):(1,(0))">, !cute.layout<"1:0">
        %append_207 = cute.append_to_rank<2> (%lay_205, %64) : !cute.layout<"(4,(1)):(1,(0))">, !cute.layout<"1:0">
        %lay_208 = cute.make_layout() : !cute.layout<"(4,((1))):(1,((0)))">
        %lay_209 = cute.make_layout() : !cute.layout<"(4,((1))):(1,((0)))">
        %sz_210 = cute.size(%lay_208) <{mode = [1]}> : (!cute.layout<"(4,((1))):(1,((0)))">) -> !cute.int_tuple<"1">
        %65 = cute.get_scalars(%sz_210) : !cute.int_tuple<"1">
        %c0_i32 = arith.constant 0 : i32
        %c1_i32 = arith.constant 1 : i32
        scf.for %arg6 = %c0_i32 to %65 step %c1_i32  : i32 {
          %coord_270 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
          %slice = cute.slice(%lay_208, %coord_270) : !cute.layout<"(4,((1))):(1,((0)))">, !cute.coord<"(_,?)">
          %idx_271 = cute.crd2idx(%coord_270, %lay_208) : (!cute.coord<"(_,?)">, !cute.layout<"(4,((1))):(1,((0)))">) -> !cute.int_tuple<"0">
          %ptr_272 = cute.add_offset(%iter_202, %idx_271) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<f32, gmem>
          %view_273 = cute.make_view(%ptr_272, %slice) : !memref_gmem_f32_3
          %slice_274 = cute.slice(%lay_209, %coord_270) : !cute.layout<"(4,((1))):(1,((0)))">, !cute.coord<"(_,?)">
          %idx_275 = cute.crd2idx(%coord_270, %lay_209) : (!cute.coord<"(_,?)">, !cute.layout<"(4,((1))):(1,((0)))">) -> !cute.int_tuple<"0">
          %ptr_276 = cute.add_offset(%iter_203, %idx_275) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, rmem, align<32>>
          %view_277 = cute.make_view(%ptr_276, %slice_274) : !memref_rmem_f32_3
          cute.copy_atom_call(%atom, %view_273, %view_277) : (!cute_nvgpu.atom.universal_copy<f32>, !memref_gmem_f32_3, !memref_rmem_f32_3) -> ()
        } {llvm.loop_annotation = #loop_annotation}
        %66 = cute.memref.load_vec %rmem : !memref_rmem_f32_
        %67 = nvgpu.cvt_fptrunc %66 : vector<4xf32> to vector<4xf8E4M3FN>
        %lay_211 = cute.get_layout(%rmem_160) : !memref_rmem_f8E4M3FN
        %68 = cute.get_shape(%lay_211) : (!cute.layout<"4:1">) -> !cute.shape<"4">
        %e0_212 = cute.get_leaves(%68) : !cute.shape<"4">
        %int_tuple = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
        %sz_213 = cute.size(%int_tuple) : (!cute.int_tuple<"4">) -> !cute.int_tuple<"4">
        %e0_214 = cute.get_leaves(%sz_213) : !cute.int_tuple<"4">
        %int_tuple_215 = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
        %sz_216 = cute.size(%int_tuple_215) : (!cute.int_tuple<"4">) -> !cute.int_tuple<"4">
        %e0_217 = cute.get_leaves(%sz_216) : !cute.int_tuple<"4">
        cute.memref.store_vec %67, %rmem_160 : !memref_rmem_f8E4M3FN
        %atom_218 = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<f8E4M3FN>
        %lay_219 = cute.get_layout(%view_113) : !memref_gmem_f8E4M3FN3
        %69 = cute.get_shape(%lay_219) : (!cute.layout<"(4):(1)">) -> !cute.shape<"(4)">
        %e0_220 = cute.get_leaves(%69) : !cute.shape<"(4)">
        %lay_221 = cute.get_layout(%rmem_160) : !memref_rmem_f8E4M3FN
        %shape_222 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_223 = cute.make_layout() : !cute.layout<"1:0">
        %append_224 = cute.append_to_rank<2> (%lay_221, %lay_223) : !cute.layout<"4:1">, !cute.layout<"1:0">
        %view_225 = cute.make_view(%iter_162, %append_224) : !memref_rmem_f8E4M3FN1
        %iter_226 = cute.get_iter(%view_225) : !memref_rmem_f8E4M3FN1
        %lay_227 = cute.get_layout(%view_225) : !memref_rmem_f8E4M3FN1
        %70 = cute.get_shape(%lay_227) : (!cute.layout<"(4,1):(1,0)">) -> !cute.shape<"(4,1)">
        %e0_228, %e1_229 = cute.get_leaves(%70) : !cute.shape<"(4,1)">
        %iter_230 = cute.get_iter(%view_225) : !memref_rmem_f8E4M3FN1
        %view_231 = cute.make_view(%iter_230) : !memref_rmem_f8E4M3FN2
        %iter_232 = cute.get_iter(%view_231) : !memref_rmem_f8E4M3FN2
        %iter_233 = cute.get_iter(%view_231) : !memref_rmem_f8E4M3FN2
        %lay_234 = cute.get_layout(%view_113) : !memref_gmem_f8E4M3FN3
        %shape_235 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_236 = cute.make_layout() : !cute.layout<"1:0">
        %append_237 = cute.append_to_rank<2> (%lay_234, %lay_236) : !cute.layout<"(4):(1)">, !cute.layout<"1:0">
        %view_238 = cute.make_view(%iter_115, %append_237) : !memref_gmem_f8E4M3FN4
        %iter_239 = cute.get_iter(%view_238) : !memref_gmem_f8E4M3FN4
        %lay_240 = cute.get_layout(%view_238) : !memref_gmem_f8E4M3FN4
        %71 = cute.get_shape(%lay_240) : (!cute.layout<"(4,1):(1,0)">) -> !cute.shape<"(4,1)">
        %e0_241, %e1_242 = cute.get_leaves(%71) : !cute.shape<"(4,1)">
        %iter_243 = cute.get_iter(%view_238) : !memref_gmem_f8E4M3FN4
        %view_244 = cute.make_view(%iter_243) : !memref_gmem_f8E4M3FN5
        %iter_245 = cute.get_iter(%view_244) : !memref_gmem_f8E4M3FN5
        %iter_246 = cute.get_iter(%view_244) : !memref_gmem_f8E4M3FN5
        %lay_247 = cute.get_layout(%view_231) : !memref_rmem_f8E4M3FN2
        %72 = cute.get_shape(%lay_247) : (!cute.layout<"(4,(1)):(1,(0))">) -> !cute.shape<"(4,(1))">
        %e0_248, %e1_249 = cute.get_leaves(%72) : !cute.shape<"(4,(1))">
        %lay_250 = cute.get_layout(%view_244) : !memref_gmem_f8E4M3FN5
        %73 = cute.get_shape(%lay_250) : (!cute.layout<"(4,(1)):(1,(0))">) -> !cute.shape<"(4,(1))">
        %e0_251, %e1_252 = cute.get_leaves(%73) : !cute.shape<"(4,(1))">
        %lay_253 = cute.get_layout(%view_231) : !memref_rmem_f8E4M3FN2
        %sz_254 = cute.size(%lay_253) <{mode = [1]}> : (!cute.layout<"(4,(1)):(1,(0))">) -> !cute.int_tuple<"1">
        %e0_255 = cute.get_leaves(%sz_254) : !cute.int_tuple<"1">
        %lay_256 = cute.get_layout(%view_244) : !memref_gmem_f8E4M3FN5
        %sz_257 = cute.size(%lay_256) <{mode = [1]}> : (!cute.layout<"(4,(1)):(1,(0))">) -> !cute.int_tuple<"1">
        %e0_258 = cute.get_leaves(%sz_257) : !cute.int_tuple<"1">
        %74 = cute.static : !cute.layout<"1:0">
        %iter_259 = cute.get_iter(%view_231) : !memref_rmem_f8E4M3FN2
        %iter_260 = cute.get_iter(%view_244) : !memref_gmem_f8E4M3FN5
        %lay_261 = cute.get_layout(%view_231) : !memref_rmem_f8E4M3FN2
        %lay_262 = cute.get_layout(%view_244) : !memref_gmem_f8E4M3FN5
        %append_263 = cute.append_to_rank<2> (%lay_261, %74) : !cute.layout<"(4,(1)):(1,(0))">, !cute.layout<"1:0">
        %append_264 = cute.append_to_rank<2> (%lay_262, %74) : !cute.layout<"(4,(1)):(1,(0))">, !cute.layout<"1:0">
        %lay_265 = cute.make_layout() : !cute.layout<"(4,((1))):(1,((0)))">
        %lay_266 = cute.make_layout() : !cute.layout<"(4,((1))):(1,((0)))">
        %sz_267 = cute.size(%lay_265) <{mode = [1]}> : (!cute.layout<"(4,((1))):(1,((0)))">) -> !cute.int_tuple<"1">
        %75 = cute.get_scalars(%sz_267) : !cute.int_tuple<"1">
        %c0_i32_268 = arith.constant 0 : i32
        %c1_i32_269 = arith.constant 1 : i32
        scf.for %arg6 = %c0_i32_268 to %75 step %c1_i32_269  : i32 {
          %coord_270 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
          %slice = cute.slice(%lay_265, %coord_270) : !cute.layout<"(4,((1))):(1,((0)))">, !cute.coord<"(_,?)">
          %idx_271 = cute.crd2idx(%coord_270, %lay_265) : (!cute.coord<"(_,?)">, !cute.layout<"(4,((1))):(1,((0)))">) -> !cute.int_tuple<"0">
          %ptr_272 = cute.add_offset(%iter_259, %idx_271) : (!cute.ptr<f8E4M3FN, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f8E4M3FN, rmem, align<32>>
          %view_273 = cute.make_view(%ptr_272, %slice) : !memref_rmem_f8E4M3FN3
          %slice_274 = cute.slice(%lay_266, %coord_270) : !cute.layout<"(4,((1))):(1,((0)))">, !cute.coord<"(_,?)">
          %idx_275 = cute.crd2idx(%coord_270, %lay_266) : (!cute.coord<"(_,?)">, !cute.layout<"(4,((1))):(1,((0)))">) -> !cute.int_tuple<"0">
          %ptr_276 = cute.add_offset(%iter_260, %idx_275) : (!cute.ptr<f8E4M3FN, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<f8E4M3FN, gmem>
          %view_277 = cute.make_view(%ptr_276, %slice_274) : !memref_gmem_f8E4M3FN3
          cute.copy_atom_call(%atom_218, %view_273, %view_277) : (!cute_nvgpu.atom.universal_copy<f8E4M3FN>, !memref_rmem_f8E4M3FN3, !memref_gmem_f8E4M3FN3) -> ()
        } {llvm.loop_annotation = #loop_annotation}
      }
      return
    }
  }
  func.func @cutlass__convert_Tensorgmemoi641i64_Tensorgmemoi641i64_1_4(%arg0: !memref_gmem_f32_6, %arg1: !memref_gmem_f8E4M3FN6) -> i32 attributes {llvm.emit_c_interface} {
    %iter = cute.get_iter(%arg0) : !memref_gmem_f32_6
    %iter_0 = cute.get_iter(%arg1) : !memref_gmem_f8E4M3FN6
    %iter_1 = cute.get_iter(%arg0) : !memref_gmem_f32_6
    %iter_2 = cute.get_iter(%arg1) : !memref_gmem_f8E4M3FN6
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
    %lay_10 = cute.get_layout(%arg1) : !memref_gmem_f8E4M3FN6
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
    %shape = cute.make_shape() : () -> !cute.shape<"(128,4)">
    %stride = cute.make_stride() : () -> !cute.stride<"(4,1)">
    %lay_22 = cute.make_layout() : !cute.layout<"(128,4):(4,1)">
    %lay_23 = cute.get_layout(%arg0) : !memref_gmem_f32_6
    %14 = cute.get_shape(%lay_23) : (!cute.layout<"(?,?,?):(?{i64},1,?{i64})">) -> !cute.shape<"(?,?,?)">
    %e0_24, %e1_25, %e2_26 = cute.get_leaves(%14) : !cute.shape<"(?,?,?)">
    %itup_27 = cute.to_int_tuple(%e0_24) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %15 = cute.get_scalars(%itup_27) : !cute.int_tuple<"?">
    %itup_28 = cute.to_int_tuple(%e1_25) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %16 = cute.get_scalars(%itup_28) : !cute.int_tuple<"?">
    %itup_29 = cute.to_int_tuple(%e2_26) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %17 = cute.get_scalars(%itup_29) : !cute.int_tuple<"?">
    %shape_30 = cute.make_shape(%itup_27, %itup_28, %itup_29) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.shape<"(?,?,?)">
    %18 = cute.make_identity_tensor(%shape_30) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">
    %iter_31 = cute.get_iter(%18) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">
    %e0_32, %e1_33, %e2_34 = cute.get_leaves(%iter_31) : !cute.int_tuple<"(0,0,0)">
    %lay_35 = cute.get_layout(%arg0) : !memref_gmem_f32_6
    %19 = cute.get_shape(%lay_35) : (!cute.layout<"(?,?,?):(?{i64},1,?{i64})">) -> !cute.shape<"(?,?,?)">
    %e0_36, %e1_37, %e2_38 = cute.get_leaves(%19) : !cute.shape<"(?,?,?)">
    %itup_39 = cute.to_int_tuple(%e0_36) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %20 = cute.get_scalars(%itup_39) : !cute.int_tuple<"?">
    %itup_40 = cute.to_int_tuple(%e1_37) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %21 = cute.get_scalars(%itup_40) : !cute.int_tuple<"?">
    %itup_41 = cute.to_int_tuple(%e2_38) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %22 = cute.get_scalars(%itup_41) : !cute.int_tuple<"?">
    %sz = cute.size(%lay_22) : (!cute.layout<"(128,4):(4,1)">) -> !cute.int_tuple<"512">
    %e0_42 = cute.get_leaves(%sz) : !cute.int_tuple<"512">
    %lay_43 = cute.get_layout(%arg1) : !memref_gmem_f8E4M3FN6
    %23 = cute.get_shape(%lay_43) : (!cute.layout<"(?,?,?):(?{i64},1,?{i64})">) -> !cute.shape<"(?,?,?)">
    %e0_44, %e1_45, %e2_46 = cute.get_leaves(%23) : !cute.shape<"(?,?,?)">
    %itup_47 = cute.to_int_tuple(%e0_44) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %24 = cute.get_scalars(%itup_47) : !cute.int_tuple<"?">
    %itup_48 = cute.to_int_tuple(%e1_45) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %25 = cute.get_scalars(%itup_48) : !cute.int_tuple<"?">
    %itup_49 = cute.to_int_tuple(%e2_46) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %26 = cute.get_scalars(%itup_49) : !cute.int_tuple<"?">
    %sz_50 = cute.size(%lay_22) : (!cute.layout<"(128,4):(4,1)">) -> !cute.int_tuple<"512">
    %e0_51 = cute.get_leaves(%sz_50) : !cute.int_tuple<"512">
    %tile = cute.make_tile() : () -> !cute.tile<"[1:0;512:1;1:0]">
    %iter_52 = cute.get_iter(%arg0) : !memref_gmem_f32_6
    %lay_53 = cute.get_layout(%arg0) : !memref_gmem_f32_6
    %27:5 = cute.get_scalars(%lay_53) <{only_dynamic}> : !cute.layout<"(?,?,?):(?{i64},1,?{i64})">
    %c512_i32 = arith.constant 512 : i32
    %28 = arith.ceildivsi %27#1, %c512_i32 : i32
    %shape_54 = cute.make_shape(%27#0, %28, %27#2) : (i32, i32, i32) -> !cute.shape<"((1,512,1),(?,?,?))">
    %stride_55 = cute.make_stride(%27#3, %27#4) : (i64, i64) -> !cute.stride<"((0,1,0),(?{i64},512,?{i64}))">
    %lay_56 = cute.make_layout(%shape_54, %stride_55) : !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">
    %view = cute.make_view(%iter_52, %lay_56) : !memref_gmem_f32_
    %iter_57 = cute.get_iter(%view) : !memref_gmem_f32_
    %iter_58 = cute.get_iter(%view) : !memref_gmem_f32_
    %tile_59 = cute.make_tile() : () -> !cute.tile<"[1:0;512:1;1:0]">
    %iter_60 = cute.get_iter(%18) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">
    %lay_61 = cute.get_layout(%18) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">
    %29:3 = cute.get_scalars(%lay_61) <{only_dynamic}> : !cute.layout<"(?,?,?):(1@0,1@1,1@2)">
    %c512_i32_62 = arith.constant 512 : i32
    %30 = arith.ceildivsi %29#1, %c512_i32_62 : i32
    %shape_63 = cute.make_shape(%29#0, %30, %29#2) : (i32, i32, i32) -> !cute.shape<"((1,512,1),(?,?,?))">
    %stride_64 = cute.make_stride() : () -> !cute.stride<"((0,1@1,0),(1@0,512@1,1@2))">
    %lay_65 = cute.make_layout(%shape_63, %stride_64) : !cute.layout<"((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">
    %view_66 = cute.make_view(%iter_60, %lay_65) : !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">
    %iter_67 = cute.get_iter(%view_66) : !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">
    %e0_68, %e1_69, %e2_70 = cute.get_leaves(%iter_67) : !cute.int_tuple<"(0,0,0)">
    %iter_71 = cute.get_iter(%view_66) : !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">
    %e0_72, %e1_73, %e2_74 = cute.get_leaves(%iter_71) : !cute.int_tuple<"(0,0,0)">
    %tile_75 = cute.make_tile() : () -> !cute.tile<"[1:0;512:1;1:0]">
    %iter_76 = cute.get_iter(%arg1) : !memref_gmem_f8E4M3FN6
    %lay_77 = cute.get_layout(%arg1) : !memref_gmem_f8E4M3FN6
    %31:5 = cute.get_scalars(%lay_77) <{only_dynamic}> : !cute.layout<"(?,?,?):(?{i64},1,?{i64})">
    %c512_i32_78 = arith.constant 512 : i32
    %32 = arith.ceildivsi %31#1, %c512_i32_78 : i32
    %shape_79 = cute.make_shape(%31#0, %32, %31#2) : (i32, i32, i32) -> !cute.shape<"((1,512,1),(?,?,?))">
    %stride_80 = cute.make_stride(%31#3, %31#4) : (i64, i64) -> !cute.stride<"((0,1,0),(?{i64},512,?{i64}))">
    %lay_81 = cute.make_layout(%shape_79, %stride_80) : !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">
    %view_82 = cute.make_view(%iter_76, %lay_81) : !memref_gmem_f8E4M3FN
    %iter_83 = cute.get_iter(%view_82) : !memref_gmem_f8E4M3FN
    %iter_84 = cute.get_iter(%view_82) : !memref_gmem_f8E4M3FN
    %lay_85 = cute.get_layout(%view) : !memref_gmem_f32_
    %sz_86 = cute.size(%lay_85) <{mode = [1]}> : (!cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !cute.int_tuple<"?">
    %e0_87 = cute.get_leaves(%sz_86) : !cute.int_tuple<"?">
    %33 = cute.get_scalars(%e0_87) : !cute.int_tuple<"?">
    %sz_88 = cute.size(%lay_22) <{mode = [0]}> : (!cute.layout<"(128,4):(4,1)">) -> !cute.int_tuple<"128">
    %e0_89 = cute.get_leaves(%sz_88) : !cute.int_tuple<"128">
    %lay_90 = cute.get_layout(%view) : !memref_gmem_f32_
    %34 = cute.get_shape(%lay_90) : (!cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !cute.shape<"((1,512,1),(?,?,?))">
    %e0_91, %e1_92, %e2_93, %e3, %e4, %e5 = cute.get_leaves(%34) : !cute.shape<"((1,512,1),(?,?,?))">
    %itup_94 = cute.to_int_tuple(%e3) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %35 = cute.get_scalars(%itup_94) : !cute.int_tuple<"?">
    %itup_95 = cute.to_int_tuple(%e4) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %36 = cute.get_scalars(%itup_95) : !cute.int_tuple<"?">
    %itup_96 = cute.to_int_tuple(%e5) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %37 = cute.get_scalars(%itup_96) : !cute.int_tuple<"?">
    %38 = cute.get_stride(%lay_90) : (!cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !cute.stride<"((0,1,0),(?{i64},512,?{i64}))">
    %e0_97, %e1_98, %e2_99, %e3_100, %e4_101, %e5_102 = cute.get_leaves(%38) : !cute.stride<"((0,1,0),(?{i64},512,?{i64}))">
    %itup_103 = cute.to_int_tuple(%e3_100) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
    %39 = cute.get_scalars(%itup_103) : !cute.int_tuple<"?{i64}">
    %itup_104 = cute.to_int_tuple(%e5_102) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
    %40 = cute.get_scalars(%itup_104) : !cute.int_tuple<"?{i64}">
    %lay_105 = cute.get_layout(%view_82) : !memref_gmem_f8E4M3FN
    %41 = cute.get_shape(%lay_105) : (!cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !cute.shape<"((1,512,1),(?,?,?))">
    %e0_106, %e1_107, %e2_108, %e3_109, %e4_110, %e5_111 = cute.get_leaves(%41) : !cute.shape<"((1,512,1),(?,?,?))">
    %itup_112 = cute.to_int_tuple(%e3_109) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %42 = cute.get_scalars(%itup_112) : !cute.int_tuple<"?">
    %itup_113 = cute.to_int_tuple(%e4_110) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %43 = cute.get_scalars(%itup_113) : !cute.int_tuple<"?">
    %itup_114 = cute.to_int_tuple(%e5_111) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %44 = cute.get_scalars(%itup_114) : !cute.int_tuple<"?">
    %45 = cute.get_stride(%lay_105) : (!cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !cute.stride<"((0,1,0),(?{i64},512,?{i64}))">
    %e0_115, %e1_116, %e2_117, %e3_118, %e4_119, %e5_120 = cute.get_leaves(%45) : !cute.stride<"((0,1,0),(?{i64},512,?{i64}))">
    %itup_121 = cute.to_int_tuple(%e3_118) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
    %46 = cute.get_scalars(%itup_121) : !cute.int_tuple<"?{i64}">
    %itup_122 = cute.to_int_tuple(%e5_120) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
    %47 = cute.get_scalars(%itup_122) : !cute.int_tuple<"?{i64}">
    %lay_123 = cute.get_layout(%view_66) : !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">
    %48 = cute.get_shape(%lay_123) : (!cute.layout<"((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">) -> !cute.shape<"((1,512,1),(?,?,?))">
    %e0_124, %e1_125, %e2_126, %e3_127, %e4_128, %e5_129 = cute.get_leaves(%48) : !cute.shape<"((1,512,1),(?,?,?))">
    %itup_130 = cute.to_int_tuple(%e3_127) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %49 = cute.get_scalars(%itup_130) : !cute.int_tuple<"?">
    %itup_131 = cute.to_int_tuple(%e4_128) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %50 = cute.get_scalars(%itup_131) : !cute.int_tuple<"?">
    %itup_132 = cute.to_int_tuple(%e5_129) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %51 = cute.get_scalars(%itup_132) : !cute.int_tuple<"?">
    %52 = cute.get_stride(%lay_123) : (!cute.layout<"((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">) -> !cute.stride<"((0,1@1,0),(1@0,512@1,1@2))">
    %e0_133, %e1_134, %e2_135, %e3_136, %e4_137, %e5_138 = cute.get_leaves(%52) : !cute.stride<"((0,1@1,0),(1@0,512@1,1@2))">
    %53 = cute.get_shape(%lay_22) : (!cute.layout<"(128,4):(4,1)">) -> !cute.shape<"(128,4)">
    %e0_139, %e1_140 = cute.get_leaves(%53) : !cute.shape<"(128,4)">
    %54 = cute.get_stride(%lay_22) : (!cute.layout<"(128,4):(4,1)">) -> !cute.stride<"(4,1)">
    %e0_141, %e1_142 = cute.get_leaves(%54) : !cute.stride<"(4,1)">
    %55 = cute.get_shape(%lay_22) : (!cute.layout<"(128,4):(4,1)">) -> !cute.shape<"(128,4)">
    %e0_143, %e1_144 = cute.get_leaves(%55) : !cute.shape<"(128,4)">
    %56 = cute.get_stride(%lay_22) : (!cute.layout<"(128,4):(4,1)">) -> !cute.stride<"(4,1)">
    %e0_145, %e1_146 = cute.get_leaves(%56) : !cute.stride<"(4,1)">
    %c0_i32 = arith.constant 0 : i32
    %c0_i64 = arith.constant 0 : i64
    %57 = cuda.cast %c0_i64 : i64 -> !cuda.stream
    %58 = arith.extsi %c0_i32 : i32 to i64
    %c128_i32 = arith.constant 128 : i32
    %c1_i32 = arith.constant 1 : i32
    %59 = cuda.launch_cfg.create<max_attrs = 2 : i32> (blockDim = (%c128_i32, %c1_i32, %c1_i32), dynamicSmemBytes = %58, gridDim = (%33, %c1_i32, %c1_i32), stream = %57) : i32, i32, i32, i64, i32, i32, i32, !cuda.stream -> !cuda.launch_cfg<max_attrs = 2>
    %60 = cuda.launch_ex @kernels::@kernel_cutlass__convert_kernel_tensorptrf32gmemo15121010512_tensorptrf8E4M3FNgmemalign16o15121010512_tensor000o15121011010512112____Float32_Float8E4M3FN_0<%59> (%view, %view_82, %view_66, %15, %16, %17) : !cuda.launch_cfg<max_attrs = 2>, (!memref_gmem_f32_, !memref_gmem_f8E4M3FN, !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">, i32, i32, i32) -> !cuda.result
    %61 = cuda.cast %60 : !cuda.result -> i32
    cuda.return_if_error %61 : i32
    %c0_i32_147 = arith.constant 0 : i32
    return %c0_i32_147 : i32
  }
}
