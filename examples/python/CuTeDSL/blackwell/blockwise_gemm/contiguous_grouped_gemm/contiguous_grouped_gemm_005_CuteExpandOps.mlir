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
      %51:3 = cute.get_scalars(%coord_148) : !cute.coord<"(?,?{div=4},?)">
      %52:3 = cute.get_scalars(%coord_149) : !cute.coord<"(?,?,?)">
      %true = arith.constant true
      %53 = arith.cmpi slt, %51#0, %52#0 : i32
      %54 = arith.andi %true, %53 : i1
      %55 = arith.cmpi slt, %51#1, %52#1 : i32
      %56 = arith.andi %54, %55 : i1
      %57 = arith.cmpi slt, %51#2, %52#2 : i32
      %58 = arith.andi %56, %57 : i1
      scf.if %58 {
        %59 = cute.get_shape(%0) : (!cute.layout<"(128,4):(4,1)">) -> !cute.shape<"(128,4)">
        %e0_150, %e1_151 = cute.get_leaves(%59) : !cute.shape<"(128,4)">
        %60 = cute.get_shape(%0) : (!cute.layout<"(128,4):(4,1)">) -> !cute.shape<"(128,4)">
        %e0_152, %e1_153 = cute.get_leaves(%60) : !cute.shape<"(128,4)">
        %lay_154 = cute.make_layout() : !cute.layout<"4:1">
        %rmem = cute.memref.alloca(%lay_154) : !memref_rmem_f32_
        %iter_155 = cute.get_iter(%rmem) : !memref_rmem_f32_
        %iter_156 = cute.get_iter(%rmem) : !memref_rmem_f32_
        %61 = cute.get_shape(%1) : (!cute.layout<"(128,4):(4,1)">) -> !cute.shape<"(128,4)">
        %e0_157, %e1_158 = cute.get_leaves(%61) : !cute.shape<"(128,4)">
        %62 = cute.get_shape(%1) : (!cute.layout<"(128,4):(4,1)">) -> !cute.shape<"(128,4)">
        %e0_159, %e1_160 = cute.get_leaves(%62) : !cute.shape<"(128,4)">
        %lay_161 = cute.make_layout() : !cute.layout<"4:1">
        %rmem_162 = cute.memref.alloca(%lay_161) : !memref_rmem_f8E4M3FN
        %iter_163 = cute.get_iter(%rmem_162) : !memref_rmem_f8E4M3FN
        %iter_164 = cute.get_iter(%rmem_162) : !memref_rmem_f8E4M3FN
        %atom = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<f32>
        %lay_165 = cute.get_layout(%view_105) : !memref_gmem_f32_3
        %63 = cute.get_shape(%lay_165) : (!cute.layout<"(4):(1)">) -> !cute.shape<"(4)">
        %e0_166 = cute.get_leaves(%63) : !cute.shape<"(4)">
        %lay_167 = cute.get_layout(%rmem) : !memref_rmem_f32_
        %64 = cute.get_shape(%lay_167) : (!cute.layout<"4:1">) -> !cute.shape<"4">
        %e0_168 = cute.get_leaves(%64) : !cute.shape<"4">
        %lay_169 = cute.get_layout(%view_105) : !memref_gmem_f32_3
        %shape = cute.make_shape() : () -> !cute.shape<"1">
        %lay_170 = cute.make_layout() : !cute.layout<"1:0">
        %append = cute.append_to_rank<2> (%lay_169, %lay_170) : !cute.layout<"(4):(1)">, !cute.layout<"1:0">
        %view_171 = cute.make_view(%iter_107, %append) : !memref_gmem_f32_4
        %iter_172 = cute.get_iter(%view_171) : !memref_gmem_f32_4
        %lay_173 = cute.get_layout(%view_171) : !memref_gmem_f32_4
        %65 = cute.get_shape(%lay_173) : (!cute.layout<"(4,1):(1,0)">) -> !cute.shape<"(4,1)">
        %e0_174, %e1_175 = cute.get_leaves(%65) : !cute.shape<"(4,1)">
        %iter_176 = cute.get_iter(%view_171) : !memref_gmem_f32_4
        %view_177 = cute.make_view(%iter_176) : !memref_gmem_f32_5
        %iter_178 = cute.get_iter(%view_177) : !memref_gmem_f32_5
        %iter_179 = cute.get_iter(%view_177) : !memref_gmem_f32_5
        %lay_180 = cute.get_layout(%rmem) : !memref_rmem_f32_
        %shape_181 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_182 = cute.make_layout() : !cute.layout<"1:0">
        %append_183 = cute.append_to_rank<2> (%lay_180, %lay_182) : !cute.layout<"4:1">, !cute.layout<"1:0">
        %view_184 = cute.make_view(%iter_156, %append_183) : !memref_rmem_f32_1
        %iter_185 = cute.get_iter(%view_184) : !memref_rmem_f32_1
        %lay_186 = cute.get_layout(%view_184) : !memref_rmem_f32_1
        %66 = cute.get_shape(%lay_186) : (!cute.layout<"(4,1):(1,0)">) -> !cute.shape<"(4,1)">
        %e0_187, %e1_188 = cute.get_leaves(%66) : !cute.shape<"(4,1)">
        %iter_189 = cute.get_iter(%view_184) : !memref_rmem_f32_1
        %view_190 = cute.make_view(%iter_189) : !memref_rmem_f32_2
        %iter_191 = cute.get_iter(%view_190) : !memref_rmem_f32_2
        %iter_192 = cute.get_iter(%view_190) : !memref_rmem_f32_2
        %lay_193 = cute.get_layout(%view_177) : !memref_gmem_f32_5
        %67 = cute.get_shape(%lay_193) : (!cute.layout<"(4,(1)):(1,(0))">) -> !cute.shape<"(4,(1))">
        %e0_194, %e1_195 = cute.get_leaves(%67) : !cute.shape<"(4,(1))">
        %lay_196 = cute.get_layout(%view_190) : !memref_rmem_f32_2
        %68 = cute.get_shape(%lay_196) : (!cute.layout<"(4,(1)):(1,(0))">) -> !cute.shape<"(4,(1))">
        %e0_197, %e1_198 = cute.get_leaves(%68) : !cute.shape<"(4,(1))">
        %lay_199 = cute.get_layout(%view_177) : !memref_gmem_f32_5
        %sz = cute.size(%lay_199) <{mode = [1]}> : (!cute.layout<"(4,(1)):(1,(0))">) -> !cute.int_tuple<"1">
        %e0_200 = cute.get_leaves(%sz) : !cute.int_tuple<"1">
        %lay_201 = cute.get_layout(%view_190) : !memref_rmem_f32_2
        %sz_202 = cute.size(%lay_201) <{mode = [1]}> : (!cute.layout<"(4,(1)):(1,(0))">) -> !cute.int_tuple<"1">
        %e0_203 = cute.get_leaves(%sz_202) : !cute.int_tuple<"1">
        %69 = cute.static : !cute.layout<"1:0">
        %iter_204 = cute.get_iter(%view_177) : !memref_gmem_f32_5
        %iter_205 = cute.get_iter(%view_190) : !memref_rmem_f32_2
        %lay_206 = cute.get_layout(%view_177) : !memref_gmem_f32_5
        %lay_207 = cute.get_layout(%view_190) : !memref_rmem_f32_2
        %append_208 = cute.append_to_rank<2> (%lay_206, %69) : !cute.layout<"(4,(1)):(1,(0))">, !cute.layout<"1:0">
        %append_209 = cute.append_to_rank<2> (%lay_207, %69) : !cute.layout<"(4,(1)):(1,(0))">, !cute.layout<"1:0">
        %lay_210 = cute.make_layout() : !cute.layout<"(4,((1))):(1,((0)))">
        %lay_211 = cute.make_layout() : !cute.layout<"(4,((1))):(1,((0)))">
        %sz_212 = cute.size(%lay_210) <{mode = [1]}> : (!cute.layout<"(4,((1))):(1,((0)))">) -> !cute.int_tuple<"1">
        %70 = cute.get_scalars(%sz_212) : !cute.int_tuple<"1">
        %c0_i32 = arith.constant 0 : i32
        %c1_i32 = arith.constant 1 : i32
        scf.for %arg6 = %c0_i32 to %70 step %c1_i32  : i32 {
          %coord_272 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
          %81 = cute.get_scalars(%coord_272) <{only_dynamic}> : !cute.coord<"(_,?)">
          %lay_273 = cute.make_layout() : !cute.layout<"(4):(1)">
          %idx_274 = cute.crd2idx(%coord_272, %lay_210) : (!cute.coord<"(_,?)">, !cute.layout<"(4,((1))):(1,((0)))">) -> !cute.int_tuple<"0">
          %ptr_275 = cute.add_offset(%iter_204, %idx_274) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<f32, gmem>
          %view_276 = cute.make_view(%ptr_275, %lay_273) : !memref_gmem_f32_3
          %82 = cute.get_scalars(%coord_272) <{only_dynamic}> : !cute.coord<"(_,?)">
          %lay_277 = cute.make_layout() : !cute.layout<"(4):(1)">
          %idx_278 = cute.crd2idx(%coord_272, %lay_211) : (!cute.coord<"(_,?)">, !cute.layout<"(4,((1))):(1,((0)))">) -> !cute.int_tuple<"0">
          %ptr_279 = cute.add_offset(%iter_205, %idx_278) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, rmem, align<32>>
          %view_280 = cute.make_view(%ptr_279, %lay_277) : !memref_rmem_f32_3
          %iter_281 = cute.get_iter(%view_276) : !memref_gmem_f32_3
          %iter_282 = cute.get_iter(%view_280) : !memref_rmem_f32_3
          %83 = builtin.unrealized_conversion_cast %iter_281 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %84 = builtin.unrealized_conversion_cast %iter_282 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
          %85 = llvm.load %83 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %85, %84 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          %int_tuple_283 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
          %ptr_284 = cute.add_offset(%iter_281, %int_tuple_283) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
          %int_tuple_285 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
          %ptr_286 = cute.add_offset(%iter_282, %int_tuple_285) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
          %86 = builtin.unrealized_conversion_cast %ptr_284 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %87 = builtin.unrealized_conversion_cast %ptr_286 : !cute.ptr<f32, rmem> to !llvm.ptr
          %88 = llvm.load %86 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %88, %87 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          %int_tuple_287 = cute.make_int_tuple() : () -> !cute.int_tuple<"2">
          %ptr_288 = cute.add_offset(%iter_281, %int_tuple_287) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
          %int_tuple_289 = cute.make_int_tuple() : () -> !cute.int_tuple<"2">
          %ptr_290 = cute.add_offset(%iter_282, %int_tuple_289) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
          %89 = builtin.unrealized_conversion_cast %ptr_288 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %90 = builtin.unrealized_conversion_cast %ptr_290 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %91 = llvm.load %89 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %91, %90 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          %int_tuple_291 = cute.make_int_tuple() : () -> !cute.int_tuple<"3">
          %ptr_292 = cute.add_offset(%iter_281, %int_tuple_291) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
          %int_tuple_293 = cute.make_int_tuple() : () -> !cute.int_tuple<"3">
          %ptr_294 = cute.add_offset(%iter_282, %int_tuple_293) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
          %92 = builtin.unrealized_conversion_cast %ptr_292 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %93 = builtin.unrealized_conversion_cast %ptr_294 : !cute.ptr<f32, rmem> to !llvm.ptr
          %94 = llvm.load %92 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %94, %93 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %71 = cute.memref.load_vec %rmem : !memref_rmem_f32_
        %72 = nvgpu.cvt_fptrunc %71 : vector<4xf32> to vector<4xf8E4M3FN>
        %lay_213 = cute.get_layout(%rmem_162) : !memref_rmem_f8E4M3FN
        %73 = cute.get_shape(%lay_213) : (!cute.layout<"4:1">) -> !cute.shape<"4">
        %e0_214 = cute.get_leaves(%73) : !cute.shape<"4">
        %int_tuple = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
        %sz_215 = cute.size(%int_tuple) : (!cute.int_tuple<"4">) -> !cute.int_tuple<"4">
        %e0_216 = cute.get_leaves(%sz_215) : !cute.int_tuple<"4">
        %int_tuple_217 = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
        %sz_218 = cute.size(%int_tuple_217) : (!cute.int_tuple<"4">) -> !cute.int_tuple<"4">
        %e0_219 = cute.get_leaves(%sz_218) : !cute.int_tuple<"4">
        cute.memref.store_vec %72, %rmem_162 : !memref_rmem_f8E4M3FN
        %atom_220 = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<f8E4M3FN>
        %lay_221 = cute.get_layout(%view_113) : !memref_gmem_f8E4M3FN3
        %74 = cute.get_shape(%lay_221) : (!cute.layout<"(4):(1)">) -> !cute.shape<"(4)">
        %e0_222 = cute.get_leaves(%74) : !cute.shape<"(4)">
        %lay_223 = cute.get_layout(%rmem_162) : !memref_rmem_f8E4M3FN
        %shape_224 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_225 = cute.make_layout() : !cute.layout<"1:0">
        %append_226 = cute.append_to_rank<2> (%lay_223, %lay_225) : !cute.layout<"4:1">, !cute.layout<"1:0">
        %view_227 = cute.make_view(%iter_164, %append_226) : !memref_rmem_f8E4M3FN1
        %iter_228 = cute.get_iter(%view_227) : !memref_rmem_f8E4M3FN1
        %lay_229 = cute.get_layout(%view_227) : !memref_rmem_f8E4M3FN1
        %75 = cute.get_shape(%lay_229) : (!cute.layout<"(4,1):(1,0)">) -> !cute.shape<"(4,1)">
        %e0_230, %e1_231 = cute.get_leaves(%75) : !cute.shape<"(4,1)">
        %iter_232 = cute.get_iter(%view_227) : !memref_rmem_f8E4M3FN1
        %view_233 = cute.make_view(%iter_232) : !memref_rmem_f8E4M3FN2
        %iter_234 = cute.get_iter(%view_233) : !memref_rmem_f8E4M3FN2
        %iter_235 = cute.get_iter(%view_233) : !memref_rmem_f8E4M3FN2
        %lay_236 = cute.get_layout(%view_113) : !memref_gmem_f8E4M3FN3
        %shape_237 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_238 = cute.make_layout() : !cute.layout<"1:0">
        %append_239 = cute.append_to_rank<2> (%lay_236, %lay_238) : !cute.layout<"(4):(1)">, !cute.layout<"1:0">
        %view_240 = cute.make_view(%iter_115, %append_239) : !memref_gmem_f8E4M3FN4
        %iter_241 = cute.get_iter(%view_240) : !memref_gmem_f8E4M3FN4
        %lay_242 = cute.get_layout(%view_240) : !memref_gmem_f8E4M3FN4
        %76 = cute.get_shape(%lay_242) : (!cute.layout<"(4,1):(1,0)">) -> !cute.shape<"(4,1)">
        %e0_243, %e1_244 = cute.get_leaves(%76) : !cute.shape<"(4,1)">
        %iter_245 = cute.get_iter(%view_240) : !memref_gmem_f8E4M3FN4
        %view_246 = cute.make_view(%iter_245) : !memref_gmem_f8E4M3FN5
        %iter_247 = cute.get_iter(%view_246) : !memref_gmem_f8E4M3FN5
        %iter_248 = cute.get_iter(%view_246) : !memref_gmem_f8E4M3FN5
        %lay_249 = cute.get_layout(%view_233) : !memref_rmem_f8E4M3FN2
        %77 = cute.get_shape(%lay_249) : (!cute.layout<"(4,(1)):(1,(0))">) -> !cute.shape<"(4,(1))">
        %e0_250, %e1_251 = cute.get_leaves(%77) : !cute.shape<"(4,(1))">
        %lay_252 = cute.get_layout(%view_246) : !memref_gmem_f8E4M3FN5
        %78 = cute.get_shape(%lay_252) : (!cute.layout<"(4,(1)):(1,(0))">) -> !cute.shape<"(4,(1))">
        %e0_253, %e1_254 = cute.get_leaves(%78) : !cute.shape<"(4,(1))">
        %lay_255 = cute.get_layout(%view_233) : !memref_rmem_f8E4M3FN2
        %sz_256 = cute.size(%lay_255) <{mode = [1]}> : (!cute.layout<"(4,(1)):(1,(0))">) -> !cute.int_tuple<"1">
        %e0_257 = cute.get_leaves(%sz_256) : !cute.int_tuple<"1">
        %lay_258 = cute.get_layout(%view_246) : !memref_gmem_f8E4M3FN5
        %sz_259 = cute.size(%lay_258) <{mode = [1]}> : (!cute.layout<"(4,(1)):(1,(0))">) -> !cute.int_tuple<"1">
        %e0_260 = cute.get_leaves(%sz_259) : !cute.int_tuple<"1">
        %79 = cute.static : !cute.layout<"1:0">
        %iter_261 = cute.get_iter(%view_233) : !memref_rmem_f8E4M3FN2
        %iter_262 = cute.get_iter(%view_246) : !memref_gmem_f8E4M3FN5
        %lay_263 = cute.get_layout(%view_233) : !memref_rmem_f8E4M3FN2
        %lay_264 = cute.get_layout(%view_246) : !memref_gmem_f8E4M3FN5
        %append_265 = cute.append_to_rank<2> (%lay_263, %79) : !cute.layout<"(4,(1)):(1,(0))">, !cute.layout<"1:0">
        %append_266 = cute.append_to_rank<2> (%lay_264, %79) : !cute.layout<"(4,(1)):(1,(0))">, !cute.layout<"1:0">
        %lay_267 = cute.make_layout() : !cute.layout<"(4,((1))):(1,((0)))">
        %lay_268 = cute.make_layout() : !cute.layout<"(4,((1))):(1,((0)))">
        %sz_269 = cute.size(%lay_267) <{mode = [1]}> : (!cute.layout<"(4,((1))):(1,((0)))">) -> !cute.int_tuple<"1">
        %80 = cute.get_scalars(%sz_269) : !cute.int_tuple<"1">
        %c0_i32_270 = arith.constant 0 : i32
        %c1_i32_271 = arith.constant 1 : i32
        scf.for %arg6 = %c0_i32_270 to %80 step %c1_i32_271  : i32 {
          %coord_272 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
          %81 = cute.get_scalars(%coord_272) <{only_dynamic}> : !cute.coord<"(_,?)">
          %lay_273 = cute.make_layout() : !cute.layout<"(4):(1)">
          %idx_274 = cute.crd2idx(%coord_272, %lay_267) : (!cute.coord<"(_,?)">, !cute.layout<"(4,((1))):(1,((0)))">) -> !cute.int_tuple<"0">
          %ptr_275 = cute.add_offset(%iter_261, %idx_274) : (!cute.ptr<f8E4M3FN, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f8E4M3FN, rmem, align<32>>
          %view_276 = cute.make_view(%ptr_275, %lay_273) : !memref_rmem_f8E4M3FN3
          %82 = cute.get_scalars(%coord_272) <{only_dynamic}> : !cute.coord<"(_,?)">
          %lay_277 = cute.make_layout() : !cute.layout<"(4):(1)">
          %idx_278 = cute.crd2idx(%coord_272, %lay_268) : (!cute.coord<"(_,?)">, !cute.layout<"(4,((1))):(1,((0)))">) -> !cute.int_tuple<"0">
          %ptr_279 = cute.add_offset(%iter_262, %idx_278) : (!cute.ptr<f8E4M3FN, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<f8E4M3FN, gmem>
          %view_280 = cute.make_view(%ptr_279, %lay_277) : !memref_gmem_f8E4M3FN3
          %iter_281 = cute.get_iter(%view_276) : !memref_rmem_f8E4M3FN3
          %iter_282 = cute.get_iter(%view_280) : !memref_gmem_f8E4M3FN3
          %83 = builtin.unrealized_conversion_cast %iter_281 : !cute.ptr<f8E4M3FN, rmem, align<32>> to !llvm.ptr
          %84 = builtin.unrealized_conversion_cast %iter_282 : !cute.ptr<f8E4M3FN, gmem> to !llvm.ptr<1>
          %85 = llvm.load %83 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
          llvm.store %85, %84 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
          %int_tuple_283 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
          %ptr_284 = cute.add_offset(%iter_281, %int_tuple_283) : (!cute.ptr<f8E4M3FN, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f8E4M3FN, rmem>
          %int_tuple_285 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
          %ptr_286 = cute.add_offset(%iter_282, %int_tuple_285) : (!cute.ptr<f8E4M3FN, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f8E4M3FN, gmem>
          %86 = builtin.unrealized_conversion_cast %ptr_284 : !cute.ptr<f8E4M3FN, rmem> to !llvm.ptr
          %87 = builtin.unrealized_conversion_cast %ptr_286 : !cute.ptr<f8E4M3FN, gmem> to !llvm.ptr<1>
          %88 = llvm.load %86 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
          llvm.store %88, %87 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
          %int_tuple_287 = cute.make_int_tuple() : () -> !cute.int_tuple<"2">
          %ptr_288 = cute.add_offset(%iter_281, %int_tuple_287) : (!cute.ptr<f8E4M3FN, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f8E4M3FN, rmem, align<2>>
          %int_tuple_289 = cute.make_int_tuple() : () -> !cute.int_tuple<"2">
          %ptr_290 = cute.add_offset(%iter_282, %int_tuple_289) : (!cute.ptr<f8E4M3FN, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f8E4M3FN, gmem>
          %89 = builtin.unrealized_conversion_cast %ptr_288 : !cute.ptr<f8E4M3FN, rmem, align<2>> to !llvm.ptr
          %90 = builtin.unrealized_conversion_cast %ptr_290 : !cute.ptr<f8E4M3FN, gmem> to !llvm.ptr<1>
          %91 = llvm.load %89 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
          llvm.store %91, %90 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
          %int_tuple_291 = cute.make_int_tuple() : () -> !cute.int_tuple<"3">
          %ptr_292 = cute.add_offset(%iter_281, %int_tuple_291) : (!cute.ptr<f8E4M3FN, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f8E4M3FN, rmem>
          %int_tuple_293 = cute.make_int_tuple() : () -> !cute.int_tuple<"3">
          %ptr_294 = cute.add_offset(%iter_282, %int_tuple_293) : (!cute.ptr<f8E4M3FN, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f8E4M3FN, gmem>
          %92 = builtin.unrealized_conversion_cast %ptr_292 : !cute.ptr<f8E4M3FN, rmem> to !llvm.ptr
          %93 = builtin.unrealized_conversion_cast %ptr_294 : !cute.ptr<f8E4M3FN, gmem> to !llvm.ptr<1>
          %94 = llvm.load %92 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
          llvm.store %94, %93 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
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
    %int_tuple = cute.make_int_tuple() : () -> !cute.int_tuple<"(0,0,0)">
    %stride_31 = cute.make_stride() : () -> !cute.stride<"(1@0,1@1,1@2)">
    %lay_32 = cute.make_layout(%shape_30, %stride_31) : !cute.layout<"(?,?,?):(1@0,1@1,1@2)">
    %view = cute.make_view(%int_tuple, %lay_32) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">
    %iter_33 = cute.get_iter(%view) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">
    %e0_34, %e1_35, %e2_36 = cute.get_leaves(%iter_33) : !cute.int_tuple<"(0,0,0)">
    %lay_37 = cute.get_layout(%arg0) : !memref_gmem_f32_6
    %18 = cute.get_shape(%lay_37) : (!cute.layout<"(?,?,?):(?{i64},1,?{i64})">) -> !cute.shape<"(?,?,?)">
    %e0_38, %e1_39, %e2_40 = cute.get_leaves(%18) : !cute.shape<"(?,?,?)">
    %itup_41 = cute.to_int_tuple(%e0_38) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %19 = cute.get_scalars(%itup_41) : !cute.int_tuple<"?">
    %itup_42 = cute.to_int_tuple(%e1_39) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %20 = cute.get_scalars(%itup_42) : !cute.int_tuple<"?">
    %itup_43 = cute.to_int_tuple(%e2_40) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %21 = cute.get_scalars(%itup_43) : !cute.int_tuple<"?">
    %sz = cute.size(%lay_22) : (!cute.layout<"(128,4):(4,1)">) -> !cute.int_tuple<"512">
    %e0_44 = cute.get_leaves(%sz) : !cute.int_tuple<"512">
    %lay_45 = cute.get_layout(%arg1) : !memref_gmem_f8E4M3FN6
    %22 = cute.get_shape(%lay_45) : (!cute.layout<"(?,?,?):(?{i64},1,?{i64})">) -> !cute.shape<"(?,?,?)">
    %e0_46, %e1_47, %e2_48 = cute.get_leaves(%22) : !cute.shape<"(?,?,?)">
    %itup_49 = cute.to_int_tuple(%e0_46) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %23 = cute.get_scalars(%itup_49) : !cute.int_tuple<"?">
    %itup_50 = cute.to_int_tuple(%e1_47) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %24 = cute.get_scalars(%itup_50) : !cute.int_tuple<"?">
    %itup_51 = cute.to_int_tuple(%e2_48) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %25 = cute.get_scalars(%itup_51) : !cute.int_tuple<"?">
    %sz_52 = cute.size(%lay_22) : (!cute.layout<"(128,4):(4,1)">) -> !cute.int_tuple<"512">
    %e0_53 = cute.get_leaves(%sz_52) : !cute.int_tuple<"512">
    %tile = cute.make_tile() : () -> !cute.tile<"[1:0;512:1;1:0]">
    %iter_54 = cute.get_iter(%arg0) : !memref_gmem_f32_6
    %lay_55 = cute.get_layout(%arg0) : !memref_gmem_f32_6
    %26:5 = cute.get_scalars(%lay_55) <{only_dynamic}> : !cute.layout<"(?,?,?):(?{i64},1,?{i64})">
    %c512_i32 = arith.constant 512 : i32
    %27 = arith.ceildivsi %26#1, %c512_i32 : i32
    %shape_56 = cute.make_shape(%26#0, %27, %26#2) : (i32, i32, i32) -> !cute.shape<"((1,512,1),(?,?,?))">
    %stride_57 = cute.make_stride(%26#3, %26#4) : (i64, i64) -> !cute.stride<"((0,1,0),(?{i64},512,?{i64}))">
    %lay_58 = cute.make_layout(%shape_56, %stride_57) : !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">
    %view_59 = cute.make_view(%iter_54, %lay_58) : !memref_gmem_f32_
    %iter_60 = cute.get_iter(%view_59) : !memref_gmem_f32_
    %iter_61 = cute.get_iter(%view_59) : !memref_gmem_f32_
    %tile_62 = cute.make_tile() : () -> !cute.tile<"[1:0;512:1;1:0]">
    %iter_63 = cute.get_iter(%view) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">
    %lay_64 = cute.get_layout(%view) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">
    %28:3 = cute.get_scalars(%lay_64) <{only_dynamic}> : !cute.layout<"(?,?,?):(1@0,1@1,1@2)">
    %c512_i32_65 = arith.constant 512 : i32
    %29 = arith.ceildivsi %28#1, %c512_i32_65 : i32
    %shape_66 = cute.make_shape(%28#0, %29, %28#2) : (i32, i32, i32) -> !cute.shape<"((1,512,1),(?,?,?))">
    %stride_67 = cute.make_stride() : () -> !cute.stride<"((0,1@1,0),(1@0,512@1,1@2))">
    %lay_68 = cute.make_layout(%shape_66, %stride_67) : !cute.layout<"((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">
    %view_69 = cute.make_view(%iter_63, %lay_68) : !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">
    %iter_70 = cute.get_iter(%view_69) : !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">
    %e0_71, %e1_72, %e2_73 = cute.get_leaves(%iter_70) : !cute.int_tuple<"(0,0,0)">
    %iter_74 = cute.get_iter(%view_69) : !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">
    %e0_75, %e1_76, %e2_77 = cute.get_leaves(%iter_74) : !cute.int_tuple<"(0,0,0)">
    %tile_78 = cute.make_tile() : () -> !cute.tile<"[1:0;512:1;1:0]">
    %iter_79 = cute.get_iter(%arg1) : !memref_gmem_f8E4M3FN6
    %lay_80 = cute.get_layout(%arg1) : !memref_gmem_f8E4M3FN6
    %30:5 = cute.get_scalars(%lay_80) <{only_dynamic}> : !cute.layout<"(?,?,?):(?{i64},1,?{i64})">
    %c512_i32_81 = arith.constant 512 : i32
    %31 = arith.ceildivsi %30#1, %c512_i32_81 : i32
    %shape_82 = cute.make_shape(%30#0, %31, %30#2) : (i32, i32, i32) -> !cute.shape<"((1,512,1),(?,?,?))">
    %stride_83 = cute.make_stride(%30#3, %30#4) : (i64, i64) -> !cute.stride<"((0,1,0),(?{i64},512,?{i64}))">
    %lay_84 = cute.make_layout(%shape_82, %stride_83) : !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">
    %view_85 = cute.make_view(%iter_79, %lay_84) : !memref_gmem_f8E4M3FN
    %iter_86 = cute.get_iter(%view_85) : !memref_gmem_f8E4M3FN
    %iter_87 = cute.get_iter(%view_85) : !memref_gmem_f8E4M3FN
    %lay_88 = cute.get_layout(%view_59) : !memref_gmem_f32_
    %sz_89 = cute.size(%lay_88) <{mode = [1]}> : (!cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !cute.int_tuple<"?">
    %e0_90 = cute.get_leaves(%sz_89) : !cute.int_tuple<"?">
    %32 = cute.get_scalars(%e0_90) : !cute.int_tuple<"?">
    %sz_91 = cute.size(%lay_22) <{mode = [0]}> : (!cute.layout<"(128,4):(4,1)">) -> !cute.int_tuple<"128">
    %e0_92 = cute.get_leaves(%sz_91) : !cute.int_tuple<"128">
    %lay_93 = cute.get_layout(%view_59) : !memref_gmem_f32_
    %33 = cute.get_shape(%lay_93) : (!cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !cute.shape<"((1,512,1),(?,?,?))">
    %e0_94, %e1_95, %e2_96, %e3, %e4, %e5 = cute.get_leaves(%33) : !cute.shape<"((1,512,1),(?,?,?))">
    %itup_97 = cute.to_int_tuple(%e3) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %34 = cute.get_scalars(%itup_97) : !cute.int_tuple<"?">
    %itup_98 = cute.to_int_tuple(%e4) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %35 = cute.get_scalars(%itup_98) : !cute.int_tuple<"?">
    %itup_99 = cute.to_int_tuple(%e5) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %36 = cute.get_scalars(%itup_99) : !cute.int_tuple<"?">
    %37 = cute.get_stride(%lay_93) : (!cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !cute.stride<"((0,1,0),(?{i64},512,?{i64}))">
    %e0_100, %e1_101, %e2_102, %e3_103, %e4_104, %e5_105 = cute.get_leaves(%37) : !cute.stride<"((0,1,0),(?{i64},512,?{i64}))">
    %itup_106 = cute.to_int_tuple(%e3_103) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
    %38 = cute.get_scalars(%itup_106) : !cute.int_tuple<"?{i64}">
    %itup_107 = cute.to_int_tuple(%e5_105) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
    %39 = cute.get_scalars(%itup_107) : !cute.int_tuple<"?{i64}">
    %lay_108 = cute.get_layout(%view_85) : !memref_gmem_f8E4M3FN
    %40 = cute.get_shape(%lay_108) : (!cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !cute.shape<"((1,512,1),(?,?,?))">
    %e0_109, %e1_110, %e2_111, %e3_112, %e4_113, %e5_114 = cute.get_leaves(%40) : !cute.shape<"((1,512,1),(?,?,?))">
    %itup_115 = cute.to_int_tuple(%e3_112) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %41 = cute.get_scalars(%itup_115) : !cute.int_tuple<"?">
    %itup_116 = cute.to_int_tuple(%e4_113) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %42 = cute.get_scalars(%itup_116) : !cute.int_tuple<"?">
    %itup_117 = cute.to_int_tuple(%e5_114) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %43 = cute.get_scalars(%itup_117) : !cute.int_tuple<"?">
    %44 = cute.get_stride(%lay_108) : (!cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !cute.stride<"((0,1,0),(?{i64},512,?{i64}))">
    %e0_118, %e1_119, %e2_120, %e3_121, %e4_122, %e5_123 = cute.get_leaves(%44) : !cute.stride<"((0,1,0),(?{i64},512,?{i64}))">
    %itup_124 = cute.to_int_tuple(%e3_121) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
    %45 = cute.get_scalars(%itup_124) : !cute.int_tuple<"?{i64}">
    %itup_125 = cute.to_int_tuple(%e5_123) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
    %46 = cute.get_scalars(%itup_125) : !cute.int_tuple<"?{i64}">
    %lay_126 = cute.get_layout(%view_69) : !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">
    %47 = cute.get_shape(%lay_126) : (!cute.layout<"((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">) -> !cute.shape<"((1,512,1),(?,?,?))">
    %e0_127, %e1_128, %e2_129, %e3_130, %e4_131, %e5_132 = cute.get_leaves(%47) : !cute.shape<"((1,512,1),(?,?,?))">
    %itup_133 = cute.to_int_tuple(%e3_130) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %48 = cute.get_scalars(%itup_133) : !cute.int_tuple<"?">
    %itup_134 = cute.to_int_tuple(%e4_131) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %49 = cute.get_scalars(%itup_134) : !cute.int_tuple<"?">
    %itup_135 = cute.to_int_tuple(%e5_132) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %50 = cute.get_scalars(%itup_135) : !cute.int_tuple<"?">
    %51 = cute.get_stride(%lay_126) : (!cute.layout<"((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">) -> !cute.stride<"((0,1@1,0),(1@0,512@1,1@2))">
    %e0_136, %e1_137, %e2_138, %e3_139, %e4_140, %e5_141 = cute.get_leaves(%51) : !cute.stride<"((0,1@1,0),(1@0,512@1,1@2))">
    %52 = cute.get_shape(%lay_22) : (!cute.layout<"(128,4):(4,1)">) -> !cute.shape<"(128,4)">
    %e0_142, %e1_143 = cute.get_leaves(%52) : !cute.shape<"(128,4)">
    %53 = cute.get_stride(%lay_22) : (!cute.layout<"(128,4):(4,1)">) -> !cute.stride<"(4,1)">
    %e0_144, %e1_145 = cute.get_leaves(%53) : !cute.stride<"(4,1)">
    %54 = cute.get_shape(%lay_22) : (!cute.layout<"(128,4):(4,1)">) -> !cute.shape<"(128,4)">
    %e0_146, %e1_147 = cute.get_leaves(%54) : !cute.shape<"(128,4)">
    %55 = cute.get_stride(%lay_22) : (!cute.layout<"(128,4):(4,1)">) -> !cute.stride<"(4,1)">
    %e0_148, %e1_149 = cute.get_leaves(%55) : !cute.stride<"(4,1)">
    %c0_i32 = arith.constant 0 : i32
    %c0_i64 = arith.constant 0 : i64
    %56 = cuda.cast %c0_i64 : i64 -> !cuda.stream
    %57 = arith.extsi %c0_i32 : i32 to i64
    %c128_i32 = arith.constant 128 : i32
    %c1_i32 = arith.constant 1 : i32
    %58 = cuda.launch_cfg.create<max_attrs = 2 : i32> (blockDim = (%c128_i32, %c1_i32, %c1_i32), dynamicSmemBytes = %57, gridDim = (%32, %c1_i32, %c1_i32), stream = %56) : i32, i32, i32, i64, i32, i32, i32, !cuda.stream -> !cuda.launch_cfg<max_attrs = 2>
    %59 = cuda.launch_ex @kernels::@kernel_cutlass__convert_kernel_tensorptrf32gmemo15121010512_tensorptrf8E4M3FNgmemalign16o15121010512_tensor000o15121011010512112____Float32_Float8E4M3FN_0<%58> (%view_59, %view_85, %view_69, %15, %16, %17) : !cuda.launch_cfg<max_attrs = 2>, (!memref_gmem_f32_, !memref_gmem_f8E4M3FN, !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">, i32, i32, i32) -> !cuda.result
    %60 = cuda.cast %59 : !cuda.result -> i32
    cuda.return_if_error %60 : i32
    %c0_i32_150 = arith.constant 0 : i32
    return %c0_i32_150 : i32
  }
}
