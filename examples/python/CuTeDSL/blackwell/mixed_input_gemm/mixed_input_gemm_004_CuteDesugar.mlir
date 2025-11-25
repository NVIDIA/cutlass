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
    func.func public @kernel_cutlass__convert_kernel_tensorptrf32gmemo1024111001024_tensorptri8gmemalign128o51211100512_tensor000o1024111000102401112____Float32_Int4_0(%arg0: !memref_gmem_f32_, %arg1: !memref_gmem_i8_, %arg2: !cute.coord_tensor<"(0,0,0)", "((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">, %arg3: i32, %arg4: i32, %arg5: i32) attributes {cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} {
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
      %coord_66 = cute.make_coord(%26) : (i32) -> !cute.coord<"(_,?)">
      %lay_67 = cute.get_layout(%arg1) : !memref_gmem_i8_
      %idx_68 = cute.crd2idx(%coord_66, %lay_67) : (!cute.coord<"(_,?)">, !cute.layout<"((512,1,1),(?,?,?)):((1,0,0),(512,?{i64},?{i64}))">) -> !cute.int_tuple<"?{i64}">
      %iter_69 = cute.get_iter(%arg1) : !memref_gmem_i8_
      %ptr_70 = cute.add_offset(%iter_69, %idx_68) : (!cute.ptr<i8, gmem, align<128>>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<i8, gmem>
      %view_71 = cute.make_view(%ptr_70) : !memref_gmem_i8_1
      %iter_72 = cute.get_iter(%view_71) : !memref_gmem_i8_1
      %coord_73 = cute.make_coord(%26) : (i32) -> !cute.coord<"(_,?)">
      %lay_74 = cute.get_layout(%arg2) : !cute.coord_tensor<"(0,0,0)", "((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">
      %idx_75 = cute.crd2idx(%coord_73, %lay_74) : (!cute.coord<"(_,?)">, !cute.layout<"((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">) -> !cute.int_tuple<"(?{div=1024},?,?)">
      %iter_76 = cute.get_iter(%arg2) : !cute.coord_tensor<"(0,0,0)", "((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">
      %tup = cute.add_offset(%iter_76, %idx_75) : (!cute.int_tuple<"(0,0,0)">, !cute.int_tuple<"(?{div=1024},?,?)">) -> !cute.int_tuple<"(?{div=1024},?,?)">
      %view_77 = cute.make_view(%tup) : !cute.coord_tensor<"(?{div=1024},?,?)", "((1024,1,1)):((1@0,0,0))">
      %iter_78 = cute.get_iter(%view_77) : !cute.coord_tensor<"(?{div=1024},?,?)", "((1024,1,1)):((1@0,0,0))">
      %e0_79, %e1_80, %e2_81 = cute.get_leaves(%iter_78) : !cute.int_tuple<"(?{div=1024},?,?)">
      %27 = cute.get_scalars(%e0_79) : !cute.int_tuple<"?{div=1024}">
      %28 = cute.get_scalars(%e1_80) : !cute.int_tuple<"?">
      %29 = cute.get_scalars(%e2_81) : !cute.int_tuple<"?">
      %iter_82 = cute.get_iter(%view) : !memref_gmem_f32_1
      %view_83 = cute.make_view(%iter_82) : !memref_gmem_f32_2
      %iter_84 = cute.get_iter(%view_83) : !memref_gmem_f32_2
      %iter_85 = cute.get_iter(%view_71) : !memref_gmem_i8_1
      %view_86 = cute.make_view(%iter_85) : !memref_gmem_i8_2
      %iter_87 = cute.get_iter(%view_86) : !memref_gmem_i8_2
      %iter_88 = cute.get_iter(%view_77) : !cute.coord_tensor<"(?{div=1024},?,?)", "((1024,1,1)):((1@0,0,0))">
      %view_89 = cute.make_view(%iter_88) : !cute.coord_tensor<"(?{div=1024},?,?)", "(128,8):(8@0,1@0)">
      %iter_90 = cute.get_iter(%view_89) : !cute.coord_tensor<"(?{div=1024},?,?)", "(128,8):(8@0,1@0)">
      %e0_91, %e1_92, %e2_93 = cute.get_leaves(%iter_90) : !cute.int_tuple<"(?{div=1024},?,?)">
      %30 = cute.get_scalars(%e0_91) : !cute.int_tuple<"?{div=1024}">
      %31 = cute.get_scalars(%e1_92) : !cute.int_tuple<"?">
      %32 = cute.get_scalars(%e2_93) : !cute.int_tuple<"?">
      %coord_94 = cute.make_coord(%25) : (i32) -> !cute.coord<"(?,_)">
      %lay_95 = cute.get_layout(%view_83) : !memref_gmem_f32_2
      %idx_96 = cute.crd2idx(%coord_94, %lay_95) : (!cute.coord<"(?,_)">, !cute.layout<"(128,8):(8,1)">) -> !cute.int_tuple<"?{div=8}">
      %iter_97 = cute.get_iter(%view_83) : !memref_gmem_f32_2
      %ptr_98 = cute.add_offset(%iter_97, %idx_96) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f32, gmem>
      %view_99 = cute.make_view(%ptr_98) : !memref_gmem_f32_3
      %iter_100 = cute.get_iter(%view_99) : !memref_gmem_f32_3
      %coord_101 = cute.make_coord(%25) : (i32) -> !cute.coord<"(?,_)">
      %lay_102 = cute.get_layout(%view_86) : !memref_gmem_i8_2
      %idx_103 = cute.crd2idx(%coord_101, %lay_102) : (!cute.coord<"(?,_)">, !cute.layout<"(128,4):(4,1)">) -> !cute.int_tuple<"?{div=4}">
      %iter_104 = cute.get_iter(%view_86) : !memref_gmem_i8_2
      %ptr_105 = cute.add_offset(%iter_104, %idx_103) : (!cute.ptr<i8, gmem>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<i8, gmem>
      %view_106 = cute.make_view(%ptr_105) : !memref_gmem_i8_3
      %iter_107 = cute.get_iter(%view_106) : !memref_gmem_i8_3
      %coord_108 = cute.make_coord(%25) : (i32) -> !cute.coord<"(?,_)">
      %lay_109 = cute.get_layout(%view_89) : !cute.coord_tensor<"(?{div=1024},?,?)", "(128,8):(8@0,1@0)">
      %idx_110 = cute.crd2idx(%coord_108, %lay_109) : (!cute.coord<"(?,_)">, !cute.layout<"(128,8):(8@0,1@0)">) -> !cute.int_tuple<"(?{div=8})">
      %iter_111 = cute.get_iter(%view_89) : !cute.coord_tensor<"(?{div=1024},?,?)", "(128,8):(8@0,1@0)">
      %tup_112 = cute.add_offset(%iter_111, %idx_110) : (!cute.int_tuple<"(?{div=1024},?,?)">, !cute.int_tuple<"(?{div=8})">) -> !cute.int_tuple<"(?{div=8},?,?)">
      %view_113 = cute.make_view(%tup_112) : !cute.coord_tensor<"(?{div=8},?,?)", "(8):(1@0)">
      %iter_114 = cute.get_iter(%view_113) : !cute.coord_tensor<"(?{div=8},?,?)", "(8):(1@0)">
      %e0_115, %e1_116, %e2_117 = cute.get_leaves(%iter_114) : !cute.int_tuple<"(?{div=8},?,?)">
      %33 = cute.get_scalars(%e0_115) : !cute.int_tuple<"?{div=8}">
      %34 = cute.get_scalars(%e1_116) : !cute.int_tuple<"?">
      %35 = cute.get_scalars(%e2_117) : !cute.int_tuple<"?">
      %coord_118 = cute.make_coord() : () -> !cute.coord<"0">
      %lay_119 = cute.get_layout(%view_113) : !cute.coord_tensor<"(?{div=8},?,?)", "(8):(1@0)">
      %idx_120 = cute.crd2idx(%coord_118, %lay_119) : (!cute.coord<"0">, !cute.layout<"(8):(1@0)">) -> !cute.int_tuple<"(0)">
      %iter_121 = cute.get_iter(%view_113) : !cute.coord_tensor<"(?{div=8},?,?)", "(8):(1@0)">
      %tup_122 = cute.add_offset(%iter_121, %idx_120) : (!cute.int_tuple<"(?{div=8},?,?)">, !cute.int_tuple<"(0)">) -> !cute.int_tuple<"(?{div=8},?,?)">
      %view_123 = cute.make_view(%tup_122) : !cute.coord_tensor<"(?{div=8},?,?)", "():()">
      %iter_124 = cute.get_iter(%view_123) : !cute.coord_tensor<"(?{div=8},?,?)", "():()">
      %e0_125, %e1_126, %e2_127 = cute.get_leaves(%iter_124) : !cute.int_tuple<"(?{div=8},?,?)">
      %36 = cute.get_scalars(%e0_125) : !cute.int_tuple<"?{div=8}">
      %37 = cute.get_scalars(%e1_126) : !cute.int_tuple<"?">
      %38 = cute.get_scalars(%e2_127) : !cute.int_tuple<"?">
      %iter_128 = cute.get_iter(%view_123) : !cute.coord_tensor<"(?{div=8},?,?)", "():()">
      %e0_129, %e1_130, %e2_131 = cute.get_leaves(%iter_128) : !cute.int_tuple<"(?{div=8},?,?)">
      %39 = cute.get_scalars(%e0_129) : !cute.int_tuple<"?{div=8}">
      %40 = cute.get_scalars(%e1_130) : !cute.int_tuple<"?">
      %41 = cute.get_scalars(%e2_131) : !cute.int_tuple<"?">
      %iter_132 = cute.get_iter(%view_123) : !cute.coord_tensor<"(?{div=8},?,?)", "():()">
      %e0_133, %e1_134, %e2_135 = cute.get_leaves(%iter_132) : !cute.int_tuple<"(?{div=8},?,?)">
      %42 = cute.get_scalars(%e0_133) : !cute.int_tuple<"?{div=8}">
      %43 = cute.get_scalars(%e1_134) : !cute.int_tuple<"?">
      %44 = cute.get_scalars(%e2_135) : !cute.int_tuple<"?">
      %coord_136 = cute.make_coord(%e0_133, %e1_134, %e2_135) : (!cute.int_tuple<"?{div=8}">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?{div=8},?,?)">
      %coord_137 = cute.make_coord(%arg3, %arg4, %arg5) : (i32, i32, i32) -> !cute.coord<"(?,?,?)">
      %45 = cute.elem_less(%coord_136, %coord_137) : !cute.coord<"(?{div=8},?,?)">, !cute.coord<"(?,?,?)">
      scf.if %45 {
        %46 = cute.get_shape(%0) : (!cute.layout<"(128,8):(8,1)">) -> !cute.shape<"(128,8)">
        %e0_138, %e1_139 = cute.get_leaves(%46) : !cute.shape<"(128,8)">
        %47 = cute.get_shape(%0) : (!cute.layout<"(128,8):(8,1)">) -> !cute.shape<"(128,8)">
        %e0_140, %e1_141 = cute.get_leaves(%47) : !cute.shape<"(128,8)">
        %48 = cute.get(%0) <{mode = [1]}> : !cute.layout<"(128,8):(8,1)"> -> !cute.layout<"8:1">
        %rmem = cute.memref.alloca(%48) : !memref_rmem_f32_
        %iter_142 = cute.get_iter(%rmem) : !memref_rmem_f32_
        %iter_143 = cute.get_iter(%rmem) : !memref_rmem_f32_
        %49 = cute.get_shape(%1) : (!cute.layout<"(128,4):(4,1)">) -> !cute.shape<"(128,4)">
        %e0_144, %e1_145 = cute.get_leaves(%49) : !cute.shape<"(128,4)">
        %50 = cute.get_shape(%1) : (!cute.layout<"(128,4):(4,1)">) -> !cute.shape<"(128,4)">
        %e0_146, %e1_147 = cute.get_leaves(%50) : !cute.shape<"(128,4)">
        %51 = cute.get(%1) <{mode = [1]}> : !cute.layout<"(128,4):(4,1)"> -> !cute.layout<"4:1">
        %rmem_148 = cute.memref.alloca(%51) : !memref_rmem_i8_
        %iter_149 = cute.get_iter(%rmem_148) : !memref_rmem_i8_
        %iter_150 = cute.get_iter(%rmem_148) : !memref_rmem_i8_
        %atom = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<f32>
        %lay_151 = cute.get_layout(%view_99) : !memref_gmem_f32_3
        %52 = cute.get_shape(%lay_151) : (!cute.layout<"(8):(1)">) -> !cute.shape<"(8)">
        %e0_152 = cute.get_leaves(%52) : !cute.shape<"(8)">
        %lay_153 = cute.get_layout(%rmem) : !memref_rmem_f32_
        %53 = cute.get_shape(%lay_153) : (!cute.layout<"8:1">) -> !cute.shape<"8">
        %e0_154 = cute.get_leaves(%53) : !cute.shape<"8">
        %lay_155 = cute.get_layout(%view_99) : !memref_gmem_f32_3
        %shape = cute.make_shape() : () -> !cute.shape<"1">
        %lay_156 = cute.make_layout() : !cute.layout<"1:0">
        %append = cute.append_to_rank<2> (%lay_155, %lay_156) : !cute.layout<"(8):(1)">, !cute.layout<"1:0">
        %view_157 = cute.make_view(%iter_100, %append) : !memref_gmem_f32_4
        %iter_158 = cute.get_iter(%view_157) : !memref_gmem_f32_4
        %lay_159 = cute.get_layout(%view_157) : !memref_gmem_f32_4
        %54 = cute.get_shape(%lay_159) : (!cute.layout<"(8,1):(1,0)">) -> !cute.shape<"(8,1)">
        %e0_160, %e1_161 = cute.get_leaves(%54) : !cute.shape<"(8,1)">
        %iter_162 = cute.get_iter(%view_157) : !memref_gmem_f32_4
        %view_163 = cute.make_view(%iter_162) : !memref_gmem_f32_5
        %iter_164 = cute.get_iter(%view_163) : !memref_gmem_f32_5
        %iter_165 = cute.get_iter(%view_163) : !memref_gmem_f32_5
        %lay_166 = cute.get_layout(%rmem) : !memref_rmem_f32_
        %shape_167 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_168 = cute.make_layout() : !cute.layout<"1:0">
        %append_169 = cute.append_to_rank<2> (%lay_166, %lay_168) : !cute.layout<"8:1">, !cute.layout<"1:0">
        %view_170 = cute.make_view(%iter_143, %append_169) : !memref_rmem_f32_1
        %iter_171 = cute.get_iter(%view_170) : !memref_rmem_f32_1
        %lay_172 = cute.get_layout(%view_170) : !memref_rmem_f32_1
        %55 = cute.get_shape(%lay_172) : (!cute.layout<"(8,1):(1,0)">) -> !cute.shape<"(8,1)">
        %e0_173, %e1_174 = cute.get_leaves(%55) : !cute.shape<"(8,1)">
        %iter_175 = cute.get_iter(%view_170) : !memref_rmem_f32_1
        %view_176 = cute.make_view(%iter_175) : !memref_rmem_f32_2
        %iter_177 = cute.get_iter(%view_176) : !memref_rmem_f32_2
        %iter_178 = cute.get_iter(%view_176) : !memref_rmem_f32_2
        %lay_179 = cute.get_layout(%view_163) : !memref_gmem_f32_5
        %56 = cute.get_shape(%lay_179) : (!cute.layout<"(8,(1)):(1,(0))">) -> !cute.shape<"(8,(1))">
        %e0_180, %e1_181 = cute.get_leaves(%56) : !cute.shape<"(8,(1))">
        %lay_182 = cute.get_layout(%view_176) : !memref_rmem_f32_2
        %57 = cute.get_shape(%lay_182) : (!cute.layout<"(8,(1)):(1,(0))">) -> !cute.shape<"(8,(1))">
        %e0_183, %e1_184 = cute.get_leaves(%57) : !cute.shape<"(8,(1))">
        %lay_185 = cute.get_layout(%view_163) : !memref_gmem_f32_5
        %sz = cute.size(%lay_185) <{mode = [1]}> : (!cute.layout<"(8,(1)):(1,(0))">) -> !cute.int_tuple<"1">
        %e0_186 = cute.get_leaves(%sz) : !cute.int_tuple<"1">
        %lay_187 = cute.get_layout(%view_176) : !memref_rmem_f32_2
        %sz_188 = cute.size(%lay_187) <{mode = [1]}> : (!cute.layout<"(8,(1)):(1,(0))">) -> !cute.int_tuple<"1">
        %e0_189 = cute.get_leaves(%sz_188) : !cute.int_tuple<"1">
        %58 = cute.static : !cute.layout<"1:0">
        %iter_190 = cute.get_iter(%view_163) : !memref_gmem_f32_5
        %iter_191 = cute.get_iter(%view_176) : !memref_rmem_f32_2
        %lay_192 = cute.get_layout(%view_163) : !memref_gmem_f32_5
        %lay_193 = cute.get_layout(%view_176) : !memref_rmem_f32_2
        %append_194 = cute.append_to_rank<2> (%lay_192, %58) : !cute.layout<"(8,(1)):(1,(0))">, !cute.layout<"1:0">
        %append_195 = cute.append_to_rank<2> (%lay_193, %58) : !cute.layout<"(8,(1)):(1,(0))">, !cute.layout<"1:0">
        %lay_196 = cute.make_layout() : !cute.layout<"(8,((1))):(1,((0)))">
        %lay_197 = cute.make_layout() : !cute.layout<"(8,((1))):(1,((0)))">
        %sz_198 = cute.size(%lay_196) <{mode = [1]}> : (!cute.layout<"(8,((1))):(1,((0)))">) -> !cute.int_tuple<"1">
        %59 = cute.get_scalars(%sz_198) : !cute.int_tuple<"1">
        %c0_i32 = arith.constant 0 : i32
        %c1_i32 = arith.constant 1 : i32
        scf.for %arg6 = %c0_i32 to %59 step %c1_i32  : i32 {
          %coord_261 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
          %slice = cute.slice(%lay_196, %coord_261) : !cute.layout<"(8,((1))):(1,((0)))">, !cute.coord<"(_,?)">
          %idx_262 = cute.crd2idx(%coord_261, %lay_196) : (!cute.coord<"(_,?)">, !cute.layout<"(8,((1))):(1,((0)))">) -> !cute.int_tuple<"0">
          %ptr_263 = cute.add_offset(%iter_190, %idx_262) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<f32, gmem>
          %view_264 = cute.make_view(%ptr_263, %slice) : !memref_gmem_f32_3
          %slice_265 = cute.slice(%lay_197, %coord_261) : !cute.layout<"(8,((1))):(1,((0)))">, !cute.coord<"(_,?)">
          %idx_266 = cute.crd2idx(%coord_261, %lay_197) : (!cute.coord<"(_,?)">, !cute.layout<"(8,((1))):(1,((0)))">) -> !cute.int_tuple<"0">
          %ptr_267 = cute.add_offset(%iter_191, %idx_266) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, rmem, align<32>>
          %view_268 = cute.make_view(%ptr_267, %slice_265) : !memref_rmem_f32_3
          cute.copy_atom_call(%atom, %view_264, %view_268) : (!cute_nvgpu.atom.universal_copy<f32>, !memref_gmem_f32_3, !memref_rmem_f32_3) -> ()
        } {llvm.loop_annotation = #loop_annotation}
        %60 = cute.memref.load_vec %rmem, row_major : !memref_rmem_f32_
        %61 = arith.fptosi %60 : vector<8xf32> to vector<8xi4>
        %shape_199 = cute.make_shape() : () -> !cute.shape<"8">
        %lay_200 = cute.make_layout() : !cute.layout<"8:1">
        %62 = cute.recast_layout<8, 4> (%lay_200) : !cute.layout<"8:1"> to !cute.layout<"4:1">
        %63 = cute.get_shape(%62) : (!cute.layout<"4:1">) -> !cute.shape<"4">
        %e0_201 = cute.get_leaves(%63) : !cute.shape<"4">
        %64 = builtin.unrealized_conversion_cast %61 : vector<8xi4> to vector<8xi4>
        %65 = vector.bitcast %64 : vector<8xi4> to vector<4xi8>
        %lay_202 = cute.get_layout(%rmem_148) : !memref_rmem_i8_
        %66 = cute.get_shape(%lay_202) : (!cute.layout<"4:1">) -> !cute.shape<"4">
        %e0_203 = cute.get_leaves(%66) : !cute.shape<"4">
        %int_tuple = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
        %sz_204 = cute.size(%int_tuple) : (!cute.int_tuple<"4">) -> !cute.int_tuple<"4">
        %e0_205 = cute.get_leaves(%sz_204) : !cute.int_tuple<"4">
        %int_tuple_206 = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
        %sz_207 = cute.size(%int_tuple_206) : (!cute.int_tuple<"4">) -> !cute.int_tuple<"4">
        %e0_208 = cute.get_leaves(%sz_207) : !cute.int_tuple<"4">
        cute.memref.store_vec %65, %rmem_148, row_major : !memref_rmem_i8_
        %atom_209 = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<i8>
        %lay_210 = cute.get_layout(%view_106) : !memref_gmem_i8_3
        %67 = cute.get_shape(%lay_210) : (!cute.layout<"(4):(1)">) -> !cute.shape<"(4)">
        %e0_211 = cute.get_leaves(%67) : !cute.shape<"(4)">
        %lay_212 = cute.get_layout(%rmem_148) : !memref_rmem_i8_
        %shape_213 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_214 = cute.make_layout() : !cute.layout<"1:0">
        %append_215 = cute.append_to_rank<2> (%lay_212, %lay_214) : !cute.layout<"4:1">, !cute.layout<"1:0">
        %view_216 = cute.make_view(%iter_150, %append_215) : !memref_rmem_i8_1
        %iter_217 = cute.get_iter(%view_216) : !memref_rmem_i8_1
        %lay_218 = cute.get_layout(%view_216) : !memref_rmem_i8_1
        %68 = cute.get_shape(%lay_218) : (!cute.layout<"(4,1):(1,0)">) -> !cute.shape<"(4,1)">
        %e0_219, %e1_220 = cute.get_leaves(%68) : !cute.shape<"(4,1)">
        %iter_221 = cute.get_iter(%view_216) : !memref_rmem_i8_1
        %view_222 = cute.make_view(%iter_221) : !memref_rmem_i8_2
        %iter_223 = cute.get_iter(%view_222) : !memref_rmem_i8_2
        %iter_224 = cute.get_iter(%view_222) : !memref_rmem_i8_2
        %lay_225 = cute.get_layout(%view_106) : !memref_gmem_i8_3
        %shape_226 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_227 = cute.make_layout() : !cute.layout<"1:0">
        %append_228 = cute.append_to_rank<2> (%lay_225, %lay_227) : !cute.layout<"(4):(1)">, !cute.layout<"1:0">
        %view_229 = cute.make_view(%iter_107, %append_228) : !memref_gmem_i8_4
        %iter_230 = cute.get_iter(%view_229) : !memref_gmem_i8_4
        %lay_231 = cute.get_layout(%view_229) : !memref_gmem_i8_4
        %69 = cute.get_shape(%lay_231) : (!cute.layout<"(4,1):(1,0)">) -> !cute.shape<"(4,1)">
        %e0_232, %e1_233 = cute.get_leaves(%69) : !cute.shape<"(4,1)">
        %iter_234 = cute.get_iter(%view_229) : !memref_gmem_i8_4
        %view_235 = cute.make_view(%iter_234) : !memref_gmem_i8_5
        %iter_236 = cute.get_iter(%view_235) : !memref_gmem_i8_5
        %iter_237 = cute.get_iter(%view_235) : !memref_gmem_i8_5
        %lay_238 = cute.get_layout(%view_222) : !memref_rmem_i8_2
        %70 = cute.get_shape(%lay_238) : (!cute.layout<"(4,(1)):(1,(0))">) -> !cute.shape<"(4,(1))">
        %e0_239, %e1_240 = cute.get_leaves(%70) : !cute.shape<"(4,(1))">
        %lay_241 = cute.get_layout(%view_235) : !memref_gmem_i8_5
        %71 = cute.get_shape(%lay_241) : (!cute.layout<"(4,(1)):(1,(0))">) -> !cute.shape<"(4,(1))">
        %e0_242, %e1_243 = cute.get_leaves(%71) : !cute.shape<"(4,(1))">
        %lay_244 = cute.get_layout(%view_222) : !memref_rmem_i8_2
        %sz_245 = cute.size(%lay_244) <{mode = [1]}> : (!cute.layout<"(4,(1)):(1,(0))">) -> !cute.int_tuple<"1">
        %e0_246 = cute.get_leaves(%sz_245) : !cute.int_tuple<"1">
        %lay_247 = cute.get_layout(%view_235) : !memref_gmem_i8_5
        %sz_248 = cute.size(%lay_247) <{mode = [1]}> : (!cute.layout<"(4,(1)):(1,(0))">) -> !cute.int_tuple<"1">
        %e0_249 = cute.get_leaves(%sz_248) : !cute.int_tuple<"1">
        %72 = cute.static : !cute.layout<"1:0">
        %iter_250 = cute.get_iter(%view_222) : !memref_rmem_i8_2
        %iter_251 = cute.get_iter(%view_235) : !memref_gmem_i8_5
        %lay_252 = cute.get_layout(%view_222) : !memref_rmem_i8_2
        %lay_253 = cute.get_layout(%view_235) : !memref_gmem_i8_5
        %append_254 = cute.append_to_rank<2> (%lay_252, %72) : !cute.layout<"(4,(1)):(1,(0))">, !cute.layout<"1:0">
        %append_255 = cute.append_to_rank<2> (%lay_253, %72) : !cute.layout<"(4,(1)):(1,(0))">, !cute.layout<"1:0">
        %lay_256 = cute.make_layout() : !cute.layout<"(4,((1))):(1,((0)))">
        %lay_257 = cute.make_layout() : !cute.layout<"(4,((1))):(1,((0)))">
        %sz_258 = cute.size(%lay_256) <{mode = [1]}> : (!cute.layout<"(4,((1))):(1,((0)))">) -> !cute.int_tuple<"1">
        %73 = cute.get_scalars(%sz_258) : !cute.int_tuple<"1">
        %c0_i32_259 = arith.constant 0 : i32
        %c1_i32_260 = arith.constant 1 : i32
        scf.for %arg6 = %c0_i32_259 to %73 step %c1_i32_260  : i32 {
          %coord_261 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
          %slice = cute.slice(%lay_256, %coord_261) : !cute.layout<"(4,((1))):(1,((0)))">, !cute.coord<"(_,?)">
          %idx_262 = cute.crd2idx(%coord_261, %lay_256) : (!cute.coord<"(_,?)">, !cute.layout<"(4,((1))):(1,((0)))">) -> !cute.int_tuple<"0">
          %ptr_263 = cute.add_offset(%iter_250, %idx_262) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
          %view_264 = cute.make_view(%ptr_263, %slice) : !memref_rmem_i8_3
          %slice_265 = cute.slice(%lay_257, %coord_261) : !cute.layout<"(4,((1))):(1,((0)))">, !cute.coord<"(_,?)">
          %idx_266 = cute.crd2idx(%coord_261, %lay_257) : (!cute.coord<"(_,?)">, !cute.layout<"(4,((1))):(1,((0)))">) -> !cute.int_tuple<"0">
          %ptr_267 = cute.add_offset(%iter_251, %idx_266) : (!cute.ptr<i8, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<i8, gmem>
          %view_268 = cute.make_view(%ptr_267, %slice_265) : !memref_gmem_i8_3
          cute.copy_atom_call(%atom_209, %view_264, %view_268) : (!cute_nvgpu.atom.universal_copy<i8>, !memref_rmem_i8_3, !memref_gmem_i8_3) -> ()
        } {llvm.loop_annotation = #loop_annotation}
      }
      return
    }
  }
  func.func @cutlass__convert_Tensorgmemo1i64i64_Tensorgmemo1i64i64_0_8(%arg0: !memref_gmem_f32_6, %arg1: !memref_gmem_i4_) attributes {llvm.emit_c_interface} {
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
    %59 = arith.index_cast %35 : i32 to index
    %c1 = arith.constant 1 : index
    %c128 = arith.constant 128 : index
    %c0_i32 = arith.constant 0 : i32
    gpu.launch_func  @kernels::@kernel_cutlass__convert_kernel_tensorptrf32gmemo1024111001024_tensorptri8gmemalign128o51211100512_tensor000o1024111000102401112____Float32_Int4_0 blocks in (%59, %c1, %c1) threads in (%c128, %c1, %c1)  dynamic_shared_memory_size %c0_i32 args(%view_60 : !memref_gmem_f32_, %view_85 : !memref_gmem_i8_, %view_70 : !cute.coord_tensor<"(0,0,0)", "((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">, %17 : i32, %18 : i32, %19 : i32) {use_pdl = false}
    return
  }
}
