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
      %45:3 = cute.get_scalars(%coord_136) : !cute.coord<"(?{div=8},?,?)">
      %46:3 = cute.get_scalars(%coord_137) : !cute.coord<"(?,?,?)">
      %true = arith.constant true
      %47 = arith.cmpi slt, %45#0, %46#0 : i32
      %48 = arith.andi %true, %47 : i1
      %49 = arith.cmpi slt, %45#1, %46#1 : i32
      %50 = arith.andi %48, %49 : i1
      %51 = arith.cmpi slt, %45#2, %46#2 : i32
      %52 = arith.andi %50, %51 : i1
      scf.if %52 {
        %53 = cute.get_shape(%0) : (!cute.layout<"(128,8):(8,1)">) -> !cute.shape<"(128,8)">
        %e0_138, %e1_139 = cute.get_leaves(%53) : !cute.shape<"(128,8)">
        %54 = cute.get_shape(%0) : (!cute.layout<"(128,8):(8,1)">) -> !cute.shape<"(128,8)">
        %e0_140, %e1_141 = cute.get_leaves(%54) : !cute.shape<"(128,8)">
        %lay_142 = cute.make_layout() : !cute.layout<"8:1">
        %rmem = cute.memref.alloca(%lay_142) : !memref_rmem_f32_
        %iter_143 = cute.get_iter(%rmem) : !memref_rmem_f32_
        %iter_144 = cute.get_iter(%rmem) : !memref_rmem_f32_
        %55 = cute.get_shape(%1) : (!cute.layout<"(128,4):(4,1)">) -> !cute.shape<"(128,4)">
        %e0_145, %e1_146 = cute.get_leaves(%55) : !cute.shape<"(128,4)">
        %56 = cute.get_shape(%1) : (!cute.layout<"(128,4):(4,1)">) -> !cute.shape<"(128,4)">
        %e0_147, %e1_148 = cute.get_leaves(%56) : !cute.shape<"(128,4)">
        %lay_149 = cute.make_layout() : !cute.layout<"4:1">
        %rmem_150 = cute.memref.alloca(%lay_149) : !memref_rmem_i8_
        %iter_151 = cute.get_iter(%rmem_150) : !memref_rmem_i8_
        %iter_152 = cute.get_iter(%rmem_150) : !memref_rmem_i8_
        %atom = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<f32>
        %lay_153 = cute.get_layout(%view_99) : !memref_gmem_f32_3
        %57 = cute.get_shape(%lay_153) : (!cute.layout<"(8):(1)">) -> !cute.shape<"(8)">
        %e0_154 = cute.get_leaves(%57) : !cute.shape<"(8)">
        %lay_155 = cute.get_layout(%rmem) : !memref_rmem_f32_
        %58 = cute.get_shape(%lay_155) : (!cute.layout<"8:1">) -> !cute.shape<"8">
        %e0_156 = cute.get_leaves(%58) : !cute.shape<"8">
        %lay_157 = cute.get_layout(%view_99) : !memref_gmem_f32_3
        %shape = cute.make_shape() : () -> !cute.shape<"1">
        %lay_158 = cute.make_layout() : !cute.layout<"1:0">
        %append = cute.append_to_rank<2> (%lay_157, %lay_158) : !cute.layout<"(8):(1)">, !cute.layout<"1:0">
        %view_159 = cute.make_view(%iter_100, %append) : !memref_gmem_f32_4
        %iter_160 = cute.get_iter(%view_159) : !memref_gmem_f32_4
        %lay_161 = cute.get_layout(%view_159) : !memref_gmem_f32_4
        %59 = cute.get_shape(%lay_161) : (!cute.layout<"(8,1):(1,0)">) -> !cute.shape<"(8,1)">
        %e0_162, %e1_163 = cute.get_leaves(%59) : !cute.shape<"(8,1)">
        %iter_164 = cute.get_iter(%view_159) : !memref_gmem_f32_4
        %view_165 = cute.make_view(%iter_164) : !memref_gmem_f32_5
        %iter_166 = cute.get_iter(%view_165) : !memref_gmem_f32_5
        %iter_167 = cute.get_iter(%view_165) : !memref_gmem_f32_5
        %lay_168 = cute.get_layout(%rmem) : !memref_rmem_f32_
        %shape_169 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_170 = cute.make_layout() : !cute.layout<"1:0">
        %append_171 = cute.append_to_rank<2> (%lay_168, %lay_170) : !cute.layout<"8:1">, !cute.layout<"1:0">
        %view_172 = cute.make_view(%iter_144, %append_171) : !memref_rmem_f32_1
        %iter_173 = cute.get_iter(%view_172) : !memref_rmem_f32_1
        %lay_174 = cute.get_layout(%view_172) : !memref_rmem_f32_1
        %60 = cute.get_shape(%lay_174) : (!cute.layout<"(8,1):(1,0)">) -> !cute.shape<"(8,1)">
        %e0_175, %e1_176 = cute.get_leaves(%60) : !cute.shape<"(8,1)">
        %iter_177 = cute.get_iter(%view_172) : !memref_rmem_f32_1
        %view_178 = cute.make_view(%iter_177) : !memref_rmem_f32_2
        %iter_179 = cute.get_iter(%view_178) : !memref_rmem_f32_2
        %iter_180 = cute.get_iter(%view_178) : !memref_rmem_f32_2
        %lay_181 = cute.get_layout(%view_165) : !memref_gmem_f32_5
        %61 = cute.get_shape(%lay_181) : (!cute.layout<"(8,(1)):(1,(0))">) -> !cute.shape<"(8,(1))">
        %e0_182, %e1_183 = cute.get_leaves(%61) : !cute.shape<"(8,(1))">
        %lay_184 = cute.get_layout(%view_178) : !memref_rmem_f32_2
        %62 = cute.get_shape(%lay_184) : (!cute.layout<"(8,(1)):(1,(0))">) -> !cute.shape<"(8,(1))">
        %e0_185, %e1_186 = cute.get_leaves(%62) : !cute.shape<"(8,(1))">
        %lay_187 = cute.get_layout(%view_165) : !memref_gmem_f32_5
        %sz = cute.size(%lay_187) <{mode = [1]}> : (!cute.layout<"(8,(1)):(1,(0))">) -> !cute.int_tuple<"1">
        %e0_188 = cute.get_leaves(%sz) : !cute.int_tuple<"1">
        %lay_189 = cute.get_layout(%view_178) : !memref_rmem_f32_2
        %sz_190 = cute.size(%lay_189) <{mode = [1]}> : (!cute.layout<"(8,(1)):(1,(0))">) -> !cute.int_tuple<"1">
        %e0_191 = cute.get_leaves(%sz_190) : !cute.int_tuple<"1">
        %63 = cute.static : !cute.layout<"1:0">
        %iter_192 = cute.get_iter(%view_165) : !memref_gmem_f32_5
        %iter_193 = cute.get_iter(%view_178) : !memref_rmem_f32_2
        %lay_194 = cute.get_layout(%view_165) : !memref_gmem_f32_5
        %lay_195 = cute.get_layout(%view_178) : !memref_rmem_f32_2
        %append_196 = cute.append_to_rank<2> (%lay_194, %63) : !cute.layout<"(8,(1)):(1,(0))">, !cute.layout<"1:0">
        %append_197 = cute.append_to_rank<2> (%lay_195, %63) : !cute.layout<"(8,(1)):(1,(0))">, !cute.layout<"1:0">
        %lay_198 = cute.make_layout() : !cute.layout<"(8,((1))):(1,((0)))">
        %lay_199 = cute.make_layout() : !cute.layout<"(8,((1))):(1,((0)))">
        %sz_200 = cute.size(%lay_198) <{mode = [1]}> : (!cute.layout<"(8,((1))):(1,((0)))">) -> !cute.int_tuple<"1">
        %64 = cute.get_scalars(%sz_200) : !cute.int_tuple<"1">
        %c0_i32 = arith.constant 0 : i32
        %c1_i32 = arith.constant 1 : i32
        scf.for %arg6 = %c0_i32 to %64 step %c1_i32  : i32 {
          %coord_263 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
          %79 = cute.get_scalars(%coord_263) <{only_dynamic}> : !cute.coord<"(_,?)">
          %lay_264 = cute.make_layout() : !cute.layout<"(8):(1)">
          %idx_265 = cute.crd2idx(%coord_263, %lay_198) : (!cute.coord<"(_,?)">, !cute.layout<"(8,((1))):(1,((0)))">) -> !cute.int_tuple<"0">
          %ptr_266 = cute.add_offset(%iter_192, %idx_265) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<f32, gmem>
          %view_267 = cute.make_view(%ptr_266, %lay_264) : !memref_gmem_f32_3
          %80 = cute.get_scalars(%coord_263) <{only_dynamic}> : !cute.coord<"(_,?)">
          %lay_268 = cute.make_layout() : !cute.layout<"(8):(1)">
          %idx_269 = cute.crd2idx(%coord_263, %lay_199) : (!cute.coord<"(_,?)">, !cute.layout<"(8,((1))):(1,((0)))">) -> !cute.int_tuple<"0">
          %ptr_270 = cute.add_offset(%iter_193, %idx_269) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, rmem, align<32>>
          %view_271 = cute.make_view(%ptr_270, %lay_268) : !memref_rmem_f32_3
          %iter_272 = cute.get_iter(%view_267) : !memref_gmem_f32_3
          %iter_273 = cute.get_iter(%view_271) : !memref_rmem_f32_3
          %81 = builtin.unrealized_conversion_cast %iter_272 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %82 = builtin.unrealized_conversion_cast %iter_273 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
          %83 = llvm.load %81 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %83, %82 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          %int_tuple_274 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
          %ptr_275 = cute.add_offset(%iter_272, %int_tuple_274) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
          %int_tuple_276 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
          %ptr_277 = cute.add_offset(%iter_273, %int_tuple_276) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
          %84 = builtin.unrealized_conversion_cast %ptr_275 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %85 = builtin.unrealized_conversion_cast %ptr_277 : !cute.ptr<f32, rmem> to !llvm.ptr
          %86 = llvm.load %84 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %86, %85 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          %int_tuple_278 = cute.make_int_tuple() : () -> !cute.int_tuple<"2">
          %ptr_279 = cute.add_offset(%iter_272, %int_tuple_278) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
          %int_tuple_280 = cute.make_int_tuple() : () -> !cute.int_tuple<"2">
          %ptr_281 = cute.add_offset(%iter_273, %int_tuple_280) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
          %87 = builtin.unrealized_conversion_cast %ptr_279 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %88 = builtin.unrealized_conversion_cast %ptr_281 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %89 = llvm.load %87 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %89, %88 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          %int_tuple_282 = cute.make_int_tuple() : () -> !cute.int_tuple<"3">
          %ptr_283 = cute.add_offset(%iter_272, %int_tuple_282) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
          %int_tuple_284 = cute.make_int_tuple() : () -> !cute.int_tuple<"3">
          %ptr_285 = cute.add_offset(%iter_273, %int_tuple_284) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
          %90 = builtin.unrealized_conversion_cast %ptr_283 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %91 = builtin.unrealized_conversion_cast %ptr_285 : !cute.ptr<f32, rmem> to !llvm.ptr
          %92 = llvm.load %90 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %92, %91 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          %int_tuple_286 = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
          %ptr_287 = cute.add_offset(%iter_272, %int_tuple_286) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"4">) -> !cute.ptr<f32, gmem>
          %int_tuple_288 = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
          %ptr_289 = cute.add_offset(%iter_273, %int_tuple_288) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
          %93 = builtin.unrealized_conversion_cast %ptr_287 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %94 = builtin.unrealized_conversion_cast %ptr_289 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
          %95 = llvm.load %93 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %95, %94 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          %int_tuple_290 = cute.make_int_tuple() : () -> !cute.int_tuple<"5">
          %ptr_291 = cute.add_offset(%iter_272, %int_tuple_290) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"5">) -> !cute.ptr<f32, gmem>
          %int_tuple_292 = cute.make_int_tuple() : () -> !cute.int_tuple<"5">
          %ptr_293 = cute.add_offset(%iter_273, %int_tuple_292) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<f32, rmem>
          %96 = builtin.unrealized_conversion_cast %ptr_291 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %97 = builtin.unrealized_conversion_cast %ptr_293 : !cute.ptr<f32, rmem> to !llvm.ptr
          %98 = llvm.load %96 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %98, %97 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          %int_tuple_294 = cute.make_int_tuple() : () -> !cute.int_tuple<"6">
          %ptr_295 = cute.add_offset(%iter_272, %int_tuple_294) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"6">) -> !cute.ptr<f32, gmem>
          %int_tuple_296 = cute.make_int_tuple() : () -> !cute.int_tuple<"6">
          %ptr_297 = cute.add_offset(%iter_273, %int_tuple_296) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
          %99 = builtin.unrealized_conversion_cast %ptr_295 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %100 = builtin.unrealized_conversion_cast %ptr_297 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %101 = llvm.load %99 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %101, %100 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          %int_tuple_298 = cute.make_int_tuple() : () -> !cute.int_tuple<"7">
          %ptr_299 = cute.add_offset(%iter_272, %int_tuple_298) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"7">) -> !cute.ptr<f32, gmem>
          %int_tuple_300 = cute.make_int_tuple() : () -> !cute.int_tuple<"7">
          %ptr_301 = cute.add_offset(%iter_273, %int_tuple_300) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<f32, rmem>
          %102 = builtin.unrealized_conversion_cast %ptr_299 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %103 = builtin.unrealized_conversion_cast %ptr_301 : !cute.ptr<f32, rmem> to !llvm.ptr
          %104 = llvm.load %102 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %104, %103 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %65 = cute.memref.load_vec %rmem, row_major : !memref_rmem_f32_
        %66 = arith.fptosi %65 : vector<8xf32> to vector<8xi4>
        %shape_201 = cute.make_shape() : () -> !cute.shape<"8">
        %lay_202 = cute.make_layout() : !cute.layout<"8:1">
        %67 = cute.recast_layout<8, 4> (%lay_202) : !cute.layout<"8:1"> to !cute.layout<"4:1">
        %68 = cute.get_shape(%67) : (!cute.layout<"4:1">) -> !cute.shape<"4">
        %e0_203 = cute.get_leaves(%68) : !cute.shape<"4">
        %69 = builtin.unrealized_conversion_cast %66 : vector<8xi4> to vector<8xi4>
        %70 = vector.bitcast %69 : vector<8xi4> to vector<4xi8>
        %lay_204 = cute.get_layout(%rmem_150) : !memref_rmem_i8_
        %71 = cute.get_shape(%lay_204) : (!cute.layout<"4:1">) -> !cute.shape<"4">
        %e0_205 = cute.get_leaves(%71) : !cute.shape<"4">
        %int_tuple = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
        %sz_206 = cute.size(%int_tuple) : (!cute.int_tuple<"4">) -> !cute.int_tuple<"4">
        %e0_207 = cute.get_leaves(%sz_206) : !cute.int_tuple<"4">
        %int_tuple_208 = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
        %sz_209 = cute.size(%int_tuple_208) : (!cute.int_tuple<"4">) -> !cute.int_tuple<"4">
        %e0_210 = cute.get_leaves(%sz_209) : !cute.int_tuple<"4">
        cute.memref.store_vec %70, %rmem_150, row_major : !memref_rmem_i8_
        %atom_211 = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<i8>
        %lay_212 = cute.get_layout(%view_106) : !memref_gmem_i8_3
        %72 = cute.get_shape(%lay_212) : (!cute.layout<"(4):(1)">) -> !cute.shape<"(4)">
        %e0_213 = cute.get_leaves(%72) : !cute.shape<"(4)">
        %lay_214 = cute.get_layout(%rmem_150) : !memref_rmem_i8_
        %shape_215 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_216 = cute.make_layout() : !cute.layout<"1:0">
        %append_217 = cute.append_to_rank<2> (%lay_214, %lay_216) : !cute.layout<"4:1">, !cute.layout<"1:0">
        %view_218 = cute.make_view(%iter_152, %append_217) : !memref_rmem_i8_1
        %iter_219 = cute.get_iter(%view_218) : !memref_rmem_i8_1
        %lay_220 = cute.get_layout(%view_218) : !memref_rmem_i8_1
        %73 = cute.get_shape(%lay_220) : (!cute.layout<"(4,1):(1,0)">) -> !cute.shape<"(4,1)">
        %e0_221, %e1_222 = cute.get_leaves(%73) : !cute.shape<"(4,1)">
        %iter_223 = cute.get_iter(%view_218) : !memref_rmem_i8_1
        %view_224 = cute.make_view(%iter_223) : !memref_rmem_i8_2
        %iter_225 = cute.get_iter(%view_224) : !memref_rmem_i8_2
        %iter_226 = cute.get_iter(%view_224) : !memref_rmem_i8_2
        %lay_227 = cute.get_layout(%view_106) : !memref_gmem_i8_3
        %shape_228 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_229 = cute.make_layout() : !cute.layout<"1:0">
        %append_230 = cute.append_to_rank<2> (%lay_227, %lay_229) : !cute.layout<"(4):(1)">, !cute.layout<"1:0">
        %view_231 = cute.make_view(%iter_107, %append_230) : !memref_gmem_i8_4
        %iter_232 = cute.get_iter(%view_231) : !memref_gmem_i8_4
        %lay_233 = cute.get_layout(%view_231) : !memref_gmem_i8_4
        %74 = cute.get_shape(%lay_233) : (!cute.layout<"(4,1):(1,0)">) -> !cute.shape<"(4,1)">
        %e0_234, %e1_235 = cute.get_leaves(%74) : !cute.shape<"(4,1)">
        %iter_236 = cute.get_iter(%view_231) : !memref_gmem_i8_4
        %view_237 = cute.make_view(%iter_236) : !memref_gmem_i8_5
        %iter_238 = cute.get_iter(%view_237) : !memref_gmem_i8_5
        %iter_239 = cute.get_iter(%view_237) : !memref_gmem_i8_5
        %lay_240 = cute.get_layout(%view_224) : !memref_rmem_i8_2
        %75 = cute.get_shape(%lay_240) : (!cute.layout<"(4,(1)):(1,(0))">) -> !cute.shape<"(4,(1))">
        %e0_241, %e1_242 = cute.get_leaves(%75) : !cute.shape<"(4,(1))">
        %lay_243 = cute.get_layout(%view_237) : !memref_gmem_i8_5
        %76 = cute.get_shape(%lay_243) : (!cute.layout<"(4,(1)):(1,(0))">) -> !cute.shape<"(4,(1))">
        %e0_244, %e1_245 = cute.get_leaves(%76) : !cute.shape<"(4,(1))">
        %lay_246 = cute.get_layout(%view_224) : !memref_rmem_i8_2
        %sz_247 = cute.size(%lay_246) <{mode = [1]}> : (!cute.layout<"(4,(1)):(1,(0))">) -> !cute.int_tuple<"1">
        %e0_248 = cute.get_leaves(%sz_247) : !cute.int_tuple<"1">
        %lay_249 = cute.get_layout(%view_237) : !memref_gmem_i8_5
        %sz_250 = cute.size(%lay_249) <{mode = [1]}> : (!cute.layout<"(4,(1)):(1,(0))">) -> !cute.int_tuple<"1">
        %e0_251 = cute.get_leaves(%sz_250) : !cute.int_tuple<"1">
        %77 = cute.static : !cute.layout<"1:0">
        %iter_252 = cute.get_iter(%view_224) : !memref_rmem_i8_2
        %iter_253 = cute.get_iter(%view_237) : !memref_gmem_i8_5
        %lay_254 = cute.get_layout(%view_224) : !memref_rmem_i8_2
        %lay_255 = cute.get_layout(%view_237) : !memref_gmem_i8_5
        %append_256 = cute.append_to_rank<2> (%lay_254, %77) : !cute.layout<"(4,(1)):(1,(0))">, !cute.layout<"1:0">
        %append_257 = cute.append_to_rank<2> (%lay_255, %77) : !cute.layout<"(4,(1)):(1,(0))">, !cute.layout<"1:0">
        %lay_258 = cute.make_layout() : !cute.layout<"(4,((1))):(1,((0)))">
        %lay_259 = cute.make_layout() : !cute.layout<"(4,((1))):(1,((0)))">
        %sz_260 = cute.size(%lay_258) <{mode = [1]}> : (!cute.layout<"(4,((1))):(1,((0)))">) -> !cute.int_tuple<"1">
        %78 = cute.get_scalars(%sz_260) : !cute.int_tuple<"1">
        %c0_i32_261 = arith.constant 0 : i32
        %c1_i32_262 = arith.constant 1 : i32
        scf.for %arg6 = %c0_i32_261 to %78 step %c1_i32_262  : i32 {
          %coord_263 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
          %79 = cute.get_scalars(%coord_263) <{only_dynamic}> : !cute.coord<"(_,?)">
          %lay_264 = cute.make_layout() : !cute.layout<"(4):(1)">
          %idx_265 = cute.crd2idx(%coord_263, %lay_258) : (!cute.coord<"(_,?)">, !cute.layout<"(4,((1))):(1,((0)))">) -> !cute.int_tuple<"0">
          %ptr_266 = cute.add_offset(%iter_252, %idx_265) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
          %view_267 = cute.make_view(%ptr_266, %lay_264) : !memref_rmem_i8_3
          %80 = cute.get_scalars(%coord_263) <{only_dynamic}> : !cute.coord<"(_,?)">
          %lay_268 = cute.make_layout() : !cute.layout<"(4):(1)">
          %idx_269 = cute.crd2idx(%coord_263, %lay_259) : (!cute.coord<"(_,?)">, !cute.layout<"(4,((1))):(1,((0)))">) -> !cute.int_tuple<"0">
          %ptr_270 = cute.add_offset(%iter_253, %idx_269) : (!cute.ptr<i8, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<i8, gmem>
          %view_271 = cute.make_view(%ptr_270, %lay_268) : !memref_gmem_i8_3
          %iter_272 = cute.get_iter(%view_267) : !memref_rmem_i8_3
          %iter_273 = cute.get_iter(%view_271) : !memref_gmem_i8_3
          %81 = builtin.unrealized_conversion_cast %iter_272 : !cute.ptr<i8, rmem, align<32>> to !llvm.ptr
          %82 = builtin.unrealized_conversion_cast %iter_273 : !cute.ptr<i8, gmem> to !llvm.ptr<1>
          %83 = llvm.load %81 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
          llvm.store %83, %82 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
          %int_tuple_274 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
          %ptr_275 = cute.add_offset(%iter_272, %int_tuple_274) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
          %int_tuple_276 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
          %ptr_277 = cute.add_offset(%iter_273, %int_tuple_276) : (!cute.ptr<i8, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<i8, gmem>
          %84 = builtin.unrealized_conversion_cast %ptr_275 : !cute.ptr<i8, rmem> to !llvm.ptr
          %85 = builtin.unrealized_conversion_cast %ptr_277 : !cute.ptr<i8, gmem> to !llvm.ptr<1>
          %86 = llvm.load %84 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
          llvm.store %86, %85 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
          %int_tuple_278 = cute.make_int_tuple() : () -> !cute.int_tuple<"2">
          %ptr_279 = cute.add_offset(%iter_272, %int_tuple_278) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem, align<2>>
          %int_tuple_280 = cute.make_int_tuple() : () -> !cute.int_tuple<"2">
          %ptr_281 = cute.add_offset(%iter_273, %int_tuple_280) : (!cute.ptr<i8, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<i8, gmem>
          %87 = builtin.unrealized_conversion_cast %ptr_279 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
          %88 = builtin.unrealized_conversion_cast %ptr_281 : !cute.ptr<i8, gmem> to !llvm.ptr<1>
          %89 = llvm.load %87 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
          llvm.store %89, %88 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
          %int_tuple_282 = cute.make_int_tuple() : () -> !cute.int_tuple<"3">
          %ptr_283 = cute.add_offset(%iter_272, %int_tuple_282) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
          %int_tuple_284 = cute.make_int_tuple() : () -> !cute.int_tuple<"3">
          %ptr_285 = cute.add_offset(%iter_273, %int_tuple_284) : (!cute.ptr<i8, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<i8, gmem>
          %90 = builtin.unrealized_conversion_cast %ptr_283 : !cute.ptr<i8, rmem> to !llvm.ptr
          %91 = builtin.unrealized_conversion_cast %ptr_285 : !cute.ptr<i8, gmem> to !llvm.ptr<1>
          %92 = llvm.load %90 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
          llvm.store %92, %91 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
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
    %int_tuple = cute.make_int_tuple() : () -> !cute.int_tuple<"(0,0,0)">
    %stride_34 = cute.make_stride() : () -> !cute.stride<"(1@0,1@1,1@2)">
    %lay_35 = cute.make_layout(%shape_33, %stride_34) : !cute.layout<"(?,?,?):(1@0,1@1,1@2)">
    %view_36 = cute.make_view(%int_tuple, %lay_35) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">
    %iter_37 = cute.get_iter(%view_36) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">
    %e0_38, %e1_39, %e2_40 = cute.get_leaves(%iter_37) : !cute.int_tuple<"(0,0,0)">
    %lay_41 = cute.get_layout(%arg0) : !memref_gmem_f32_6
    %20 = cute.get_shape(%lay_41) : (!cute.layout<"(?,?,?):(1,?{i64},?{i64})">) -> !cute.shape<"(?,?,?)">
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
    %24 = cute.get_shape(%lay_49) : (!cute.layout<"(?,?,?):(1,?{i64},?{i64})">) -> !cute.shape<"(?,?,?)">
    %e0_50, %e1_51, %e2_52 = cute.get_leaves(%24) : !cute.shape<"(?,?,?)">
    %itup_53 = cute.to_int_tuple(%e0_50) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %25 = cute.get_scalars(%itup_53) : !cute.int_tuple<"?">
    %itup_54 = cute.to_int_tuple(%e1_51) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %26 = cute.get_scalars(%itup_54) : !cute.int_tuple<"?">
    %itup_55 = cute.to_int_tuple(%e2_52) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %27 = cute.get_scalars(%itup_55) : !cute.int_tuple<"?">
    %sz_56 = cute.size(%14) : (!cute.layout<"(128,4):(4,1)">) -> !cute.int_tuple<"512">
    %e0_57 = cute.get_leaves(%sz_56) : !cute.int_tuple<"512">
    %tile = cute.make_tile() : () -> !cute.tile<"[1024:1;1:0;1:0]">
    %iter_58 = cute.get_iter(%arg0) : !memref_gmem_f32_6
    %lay_59 = cute.get_layout(%arg0) : !memref_gmem_f32_6
    %28:5 = cute.get_scalars(%lay_59) <{only_dynamic}> : !cute.layout<"(?,?,?):(1,?{i64},?{i64})">
    %c1024_i32 = arith.constant 1024 : i32
    %29 = arith.ceildivsi %28#0, %c1024_i32 : i32
    %shape_60 = cute.make_shape(%29, %28#1, %28#2) : (i32, i32, i32) -> !cute.shape<"((1024,1,1),(?,?,?))">
    %stride_61 = cute.make_stride(%28#3, %28#4) : (i64, i64) -> !cute.stride<"((1,0,0),(1024,?{i64},?{i64}))">
    %lay_62 = cute.make_layout(%shape_60, %stride_61) : !cute.layout<"((1024,1,1),(?,?,?)):((1,0,0),(1024,?{i64},?{i64}))">
    %view_63 = cute.make_view(%iter_58, %lay_62) : !memref_gmem_f32_
    %iter_64 = cute.get_iter(%view_63) : !memref_gmem_f32_
    %iter_65 = cute.get_iter(%view_63) : !memref_gmem_f32_
    %tile_66 = cute.make_tile() : () -> !cute.tile<"[1024:1;1:0;1:0]">
    %iter_67 = cute.get_iter(%view_36) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">
    %lay_68 = cute.get_layout(%view_36) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">
    %30:3 = cute.get_scalars(%lay_68) <{only_dynamic}> : !cute.layout<"(?,?,?):(1@0,1@1,1@2)">
    %c1024_i32_69 = arith.constant 1024 : i32
    %31 = arith.ceildivsi %30#0, %c1024_i32_69 : i32
    %shape_70 = cute.make_shape(%31, %30#1, %30#2) : (i32, i32, i32) -> !cute.shape<"((1024,1,1),(?,?,?))">
    %stride_71 = cute.make_stride() : () -> !cute.stride<"((1@0,0,0),(1024@0,1@1,1@2))">
    %lay_72 = cute.make_layout(%shape_70, %stride_71) : !cute.layout<"((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">
    %view_73 = cute.make_view(%iter_67, %lay_72) : !cute.coord_tensor<"(0,0,0)", "((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">
    %iter_74 = cute.get_iter(%view_73) : !cute.coord_tensor<"(0,0,0)", "((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">
    %e0_75, %e1_76, %e2_77 = cute.get_leaves(%iter_74) : !cute.int_tuple<"(0,0,0)">
    %iter_78 = cute.get_iter(%view_73) : !cute.coord_tensor<"(0,0,0)", "((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">
    %e0_79, %e1_80, %e2_81 = cute.get_leaves(%iter_78) : !cute.int_tuple<"(0,0,0)">
    %tile_82 = cute.make_tile() : () -> !cute.tile<"[512:1;1:0;1:0]">
    %iter_83 = cute.get_iter(%view) : !memref_gmem_i8_6
    %lay_84 = cute.get_layout(%view) : !memref_gmem_i8_6
    %32:5 = cute.get_scalars(%lay_84) <{only_dynamic}> : !cute.layout<"(?,?,?):(1,?{i64},?{i64})">
    %c512_i32 = arith.constant 512 : i32
    %33 = arith.ceildivsi %32#0, %c512_i32 : i32
    %shape_85 = cute.make_shape(%33, %32#1, %32#2) : (i32, i32, i32) -> !cute.shape<"((512,1,1),(?,?,?))">
    %stride_86 = cute.make_stride(%32#3, %32#4) : (i64, i64) -> !cute.stride<"((1,0,0),(512,?{i64},?{i64}))">
    %lay_87 = cute.make_layout(%shape_85, %stride_86) : !cute.layout<"((512,1,1),(?,?,?)):((1,0,0),(512,?{i64},?{i64}))">
    %view_88 = cute.make_view(%iter_83, %lay_87) : !memref_gmem_i8_
    %iter_89 = cute.get_iter(%view_88) : !memref_gmem_i8_
    %iter_90 = cute.get_iter(%view_88) : !memref_gmem_i8_
    %lay_91 = cute.get_layout(%view_63) : !memref_gmem_f32_
    %sz_92 = cute.size(%lay_91) <{mode = [1]}> : (!cute.layout<"((1024,1,1),(?,?,?)):((1,0,0),(1024,?{i64},?{i64}))">) -> !cute.int_tuple<"?">
    %e0_93 = cute.get_leaves(%sz_92) : !cute.int_tuple<"?">
    %34 = cute.get_scalars(%e0_93) : !cute.int_tuple<"?">
    %sz_94 = cute.size(%lay_22) <{mode = [0]}> : (!cute.layout<"(128,8):(8,1)">) -> !cute.int_tuple<"128">
    %e0_95 = cute.get_leaves(%sz_94) : !cute.int_tuple<"128">
    %lay_96 = cute.get_layout(%view_63) : !memref_gmem_f32_
    %35 = cute.get_shape(%lay_96) : (!cute.layout<"((1024,1,1),(?,?,?)):((1,0,0),(1024,?{i64},?{i64}))">) -> !cute.shape<"((1024,1,1),(?,?,?))">
    %e0_97, %e1_98, %e2_99, %e3, %e4, %e5 = cute.get_leaves(%35) : !cute.shape<"((1024,1,1),(?,?,?))">
    %itup_100 = cute.to_int_tuple(%e3) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %36 = cute.get_scalars(%itup_100) : !cute.int_tuple<"?">
    %itup_101 = cute.to_int_tuple(%e4) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %37 = cute.get_scalars(%itup_101) : !cute.int_tuple<"?">
    %itup_102 = cute.to_int_tuple(%e5) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %38 = cute.get_scalars(%itup_102) : !cute.int_tuple<"?">
    %39 = cute.get_stride(%lay_96) : (!cute.layout<"((1024,1,1),(?,?,?)):((1,0,0),(1024,?{i64},?{i64}))">) -> !cute.stride<"((1,0,0),(1024,?{i64},?{i64}))">
    %e0_103, %e1_104, %e2_105, %e3_106, %e4_107, %e5_108 = cute.get_leaves(%39) : !cute.stride<"((1,0,0),(1024,?{i64},?{i64}))">
    %itup_109 = cute.to_int_tuple(%e4_107) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
    %40 = cute.get_scalars(%itup_109) : !cute.int_tuple<"?{i64}">
    %itup_110 = cute.to_int_tuple(%e5_108) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
    %41 = cute.get_scalars(%itup_110) : !cute.int_tuple<"?{i64}">
    %lay_111 = cute.get_layout(%view_88) : !memref_gmem_i8_
    %42 = cute.get_shape(%lay_111) : (!cute.layout<"((512,1,1),(?,?,?)):((1,0,0),(512,?{i64},?{i64}))">) -> !cute.shape<"((512,1,1),(?,?,?))">
    %e0_112, %e1_113, %e2_114, %e3_115, %e4_116, %e5_117 = cute.get_leaves(%42) : !cute.shape<"((512,1,1),(?,?,?))">
    %itup_118 = cute.to_int_tuple(%e3_115) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %43 = cute.get_scalars(%itup_118) : !cute.int_tuple<"?">
    %itup_119 = cute.to_int_tuple(%e4_116) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %44 = cute.get_scalars(%itup_119) : !cute.int_tuple<"?">
    %itup_120 = cute.to_int_tuple(%e5_117) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %45 = cute.get_scalars(%itup_120) : !cute.int_tuple<"?">
    %46 = cute.get_stride(%lay_111) : (!cute.layout<"((512,1,1),(?,?,?)):((1,0,0),(512,?{i64},?{i64}))">) -> !cute.stride<"((1,0,0),(512,?{i64},?{i64}))">
    %e0_121, %e1_122, %e2_123, %e3_124, %e4_125, %e5_126 = cute.get_leaves(%46) : !cute.stride<"((1,0,0),(512,?{i64},?{i64}))">
    %itup_127 = cute.to_int_tuple(%e4_125) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
    %47 = cute.get_scalars(%itup_127) : !cute.int_tuple<"?{i64}">
    %itup_128 = cute.to_int_tuple(%e5_126) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
    %48 = cute.get_scalars(%itup_128) : !cute.int_tuple<"?{i64}">
    %lay_129 = cute.get_layout(%view_73) : !cute.coord_tensor<"(0,0,0)", "((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">
    %49 = cute.get_shape(%lay_129) : (!cute.layout<"((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">) -> !cute.shape<"((1024,1,1),(?,?,?))">
    %e0_130, %e1_131, %e2_132, %e3_133, %e4_134, %e5_135 = cute.get_leaves(%49) : !cute.shape<"((1024,1,1),(?,?,?))">
    %itup_136 = cute.to_int_tuple(%e3_133) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %50 = cute.get_scalars(%itup_136) : !cute.int_tuple<"?">
    %itup_137 = cute.to_int_tuple(%e4_134) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %51 = cute.get_scalars(%itup_137) : !cute.int_tuple<"?">
    %itup_138 = cute.to_int_tuple(%e5_135) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %52 = cute.get_scalars(%itup_138) : !cute.int_tuple<"?">
    %53 = cute.get_stride(%lay_129) : (!cute.layout<"((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">) -> !cute.stride<"((1@0,0,0),(1024@0,1@1,1@2))">
    %e0_139, %e1_140, %e2_141, %e3_142, %e4_143, %e5_144 = cute.get_leaves(%53) : !cute.stride<"((1@0,0,0),(1024@0,1@1,1@2))">
    %54 = cute.get_shape(%lay_22) : (!cute.layout<"(128,8):(8,1)">) -> !cute.shape<"(128,8)">
    %e0_145, %e1_146 = cute.get_leaves(%54) : !cute.shape<"(128,8)">
    %55 = cute.get_stride(%lay_22) : (!cute.layout<"(128,8):(8,1)">) -> !cute.stride<"(8,1)">
    %e0_147, %e1_148 = cute.get_leaves(%55) : !cute.stride<"(8,1)">
    %56 = cute.get_shape(%14) : (!cute.layout<"(128,4):(4,1)">) -> !cute.shape<"(128,4)">
    %e0_149, %e1_150 = cute.get_leaves(%56) : !cute.shape<"(128,4)">
    %57 = cute.get_stride(%14) : (!cute.layout<"(128,4):(4,1)">) -> !cute.stride<"(4,1)">
    %e0_151, %e1_152 = cute.get_leaves(%57) : !cute.stride<"(4,1)">
    %58 = arith.index_cast %34 : i32 to index
    %c1 = arith.constant 1 : index
    %c128 = arith.constant 128 : index
    %c0_i32 = arith.constant 0 : i32
    gpu.launch_func  @kernels::@kernel_cutlass__convert_kernel_tensorptrf32gmemo1024111001024_tensorptri8gmemalign128o51211100512_tensor000o1024111000102401112____Float32_Int4_0 blocks in (%58, %c1, %c1) threads in (%c128, %c1, %c1)  dynamic_shared_memory_size %c0_i32 args(%view_63 : !memref_gmem_f32_, %view_88 : !memref_gmem_i8_, %view_73 : !cute.coord_tensor<"(0,0,0)", "((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">, %17 : i32, %18 : i32, %19 : i32) {use_pdl = false}
    return
  }
}
