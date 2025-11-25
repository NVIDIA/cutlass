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
!memref_rmem_i8_ = !cute.memref<i8, rmem, align<32>, "4:1">
!memref_rmem_i8_1 = !cute.memref<i8, rmem, align<32>, "(4,1):(1,0)">
!memref_rmem_i8_2 = !cute.memref<i8, rmem, align<32>, "(4,(1)):(1,(0))">
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
      %slice = cute.slice(%arg0, %coord) : !memref_gmem_f32_, !cute.coord<"(_,?)">
      %iter_63 = cute.get_iter(%slice) : !memref_gmem_f32_1
      %coord_64 = cute.make_coord(%26) : (i32) -> !cute.coord<"(_,?)">
      %slice_65 = cute.slice(%arg1, %coord_64) : !memref_gmem_i8_, !cute.coord<"(_,?)">
      %iter_66 = cute.get_iter(%slice_65) : !memref_gmem_i8_1
      %coord_67 = cute.make_coord(%26) : (i32) -> !cute.coord<"(_,?)">
      %slice_68 = cute.slice(%arg2, %coord_67) : !cute.coord_tensor<"(0,0,0)", "((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">, !cute.coord<"(_,?)">
      %iter_69 = cute.get_iter(%slice_68) : !cute.coord_tensor<"(?{div=1024},?,?)", "((1024,1,1)):((1@0,0,0))">
      %e0_70, %e1_71, %e2_72 = cute.get_leaves(%iter_69) : !cute.int_tuple<"(?{div=1024},?,?)">
      %27 = cute.get_scalars(%e0_70) : !cute.int_tuple<"?{div=1024}">
      %28 = cute.get_scalars(%e1_71) : !cute.int_tuple<"?">
      %29 = cute.get_scalars(%e2_72) : !cute.int_tuple<"?">
      %30 = cute.composition(%slice, %0) : (!memref_gmem_f32_1, !cute.layout<"(128,8):(8,1)">) -> !memref_gmem_f32_2
      %iter_73 = cute.get_iter(%30) : !memref_gmem_f32_2
      %31 = cute.composition(%slice_65, %1) : (!memref_gmem_i8_1, !cute.layout<"(128,4):(4,1)">) -> !memref_gmem_i8_2
      %iter_74 = cute.get_iter(%31) : !memref_gmem_i8_2
      %32 = cute.composition(%slice_68, %0) : (!cute.coord_tensor<"(?{div=1024},?,?)", "((1024,1,1)):((1@0,0,0))">, !cute.layout<"(128,8):(8,1)">) -> !cute.coord_tensor<"(?{div=1024},?,?)", "(128,8):(8@0,1@0)">
      %iter_75 = cute.get_iter(%32) : !cute.coord_tensor<"(?{div=1024},?,?)", "(128,8):(8@0,1@0)">
      %e0_76, %e1_77, %e2_78 = cute.get_leaves(%iter_75) : !cute.int_tuple<"(?{div=1024},?,?)">
      %33 = cute.get_scalars(%e0_76) : !cute.int_tuple<"?{div=1024}">
      %34 = cute.get_scalars(%e1_77) : !cute.int_tuple<"?">
      %35 = cute.get_scalars(%e2_78) : !cute.int_tuple<"?">
      %coord_79 = cute.make_coord(%25) : (i32) -> !cute.coord<"(?,_)">
      %slice_80 = cute.slice(%30, %coord_79) : !memref_gmem_f32_2, !cute.coord<"(?,_)">
      %iter_81 = cute.get_iter(%slice_80) : !memref_gmem_f32_3
      %coord_82 = cute.make_coord(%25) : (i32) -> !cute.coord<"(?,_)">
      %slice_83 = cute.slice(%31, %coord_82) : !memref_gmem_i8_2, !cute.coord<"(?,_)">
      %iter_84 = cute.get_iter(%slice_83) : !memref_gmem_i8_3
      %coord_85 = cute.make_coord(%25) : (i32) -> !cute.coord<"(?,_)">
      %slice_86 = cute.slice(%32, %coord_85) : !cute.coord_tensor<"(?{div=1024},?,?)", "(128,8):(8@0,1@0)">, !cute.coord<"(?,_)">
      %iter_87 = cute.get_iter(%slice_86) : !cute.coord_tensor<"(?{div=8},?,?)", "(8):(1@0)">
      %e0_88, %e1_89, %e2_90 = cute.get_leaves(%iter_87) : !cute.int_tuple<"(?{div=8},?,?)">
      %36 = cute.get_scalars(%e0_88) : !cute.int_tuple<"?{div=8}">
      %37 = cute.get_scalars(%e1_89) : !cute.int_tuple<"?">
      %38 = cute.get_scalars(%e2_90) : !cute.int_tuple<"?">
      %coord_91 = cute.make_coord() : () -> !cute.coord<"0">
      %slice_92 = cute.slice(%slice_86, %coord_91) : !cute.coord_tensor<"(?{div=8},?,?)", "(8):(1@0)">, !cute.coord<"0">
      %iter_93 = cute.get_iter(%slice_92) : !cute.coord_tensor<"(?{div=8},?,?)", "():()">
      %e0_94, %e1_95, %e2_96 = cute.get_leaves(%iter_93) : !cute.int_tuple<"(?{div=8},?,?)">
      %39 = cute.get_scalars(%e0_94) : !cute.int_tuple<"?{div=8}">
      %40 = cute.get_scalars(%e1_95) : !cute.int_tuple<"?">
      %41 = cute.get_scalars(%e2_96) : !cute.int_tuple<"?">
      %iter_97 = cute.get_iter(%slice_92) : !cute.coord_tensor<"(?{div=8},?,?)", "():()">
      %e0_98, %e1_99, %e2_100 = cute.get_leaves(%iter_97) : !cute.int_tuple<"(?{div=8},?,?)">
      %42 = cute.get_scalars(%e0_98) : !cute.int_tuple<"?{div=8}">
      %43 = cute.get_scalars(%e1_99) : !cute.int_tuple<"?">
      %44 = cute.get_scalars(%e2_100) : !cute.int_tuple<"?">
      %iter_101 = cute.get_iter(%slice_92) : !cute.coord_tensor<"(?{div=8},?,?)", "():()">
      %e0_102, %e1_103, %e2_104 = cute.get_leaves(%iter_101) : !cute.int_tuple<"(?{div=8},?,?)">
      %45 = cute.get_scalars(%e0_102) : !cute.int_tuple<"?{div=8}">
      %46 = cute.get_scalars(%e1_103) : !cute.int_tuple<"?">
      %47 = cute.get_scalars(%e2_104) : !cute.int_tuple<"?">
      %coord_105 = cute.make_coord(%e0_102, %e1_103, %e2_104) : (!cute.int_tuple<"?{div=8}">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?{div=8},?,?)">
      %coord_106 = cute.make_coord(%arg3, %arg4, %arg5) : (i32, i32, i32) -> !cute.coord<"(?,?,?)">
      %48 = cute.elem_less(%coord_105, %coord_106) : !cute.coord<"(?{div=8},?,?)">, !cute.coord<"(?,?,?)">
      scf.if %48 {
        %49 = cute.get_shape(%0) : (!cute.layout<"(128,8):(8,1)">) -> !cute.shape<"(128,8)">
        %e0_107, %e1_108 = cute.get_leaves(%49) : !cute.shape<"(128,8)">
        %50 = cute.get_shape(%0) : (!cute.layout<"(128,8):(8,1)">) -> !cute.shape<"(128,8)">
        %e0_109, %e1_110 = cute.get_leaves(%50) : !cute.shape<"(128,8)">
        %51 = cute.get(%0) <{mode = [1]}> : !cute.layout<"(128,8):(8,1)"> -> !cute.layout<"8:1">
        %rmem = cute.memref.alloca(%51) : !memref_rmem_f32_
        %iter_111 = cute.get_iter(%rmem) : !memref_rmem_f32_
        %iter_112 = cute.get_iter(%rmem) : !memref_rmem_f32_
        %52 = cute.get_shape(%1) : (!cute.layout<"(128,4):(4,1)">) -> !cute.shape<"(128,4)">
        %e0_113, %e1_114 = cute.get_leaves(%52) : !cute.shape<"(128,4)">
        %53 = cute.get_shape(%1) : (!cute.layout<"(128,4):(4,1)">) -> !cute.shape<"(128,4)">
        %e0_115, %e1_116 = cute.get_leaves(%53) : !cute.shape<"(128,4)">
        %54 = cute.get(%1) <{mode = [1]}> : !cute.layout<"(128,4):(4,1)"> -> !cute.layout<"4:1">
        %rmem_117 = cute.memref.alloca(%54) : !memref_rmem_i8_
        %iter_118 = cute.get_iter(%rmem_117) : !memref_rmem_i8_
        %iter_119 = cute.get_iter(%rmem_117) : !memref_rmem_i8_
        %atom = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<f32>
        %lay_120 = cute.get_layout(%slice_80) : !memref_gmem_f32_3
        %55 = cute.get_shape(%lay_120) : (!cute.layout<"(8):(1)">) -> !cute.shape<"(8)">
        %e0_121 = cute.get_leaves(%55) : !cute.shape<"(8)">
        %lay_122 = cute.get_layout(%rmem) : !memref_rmem_f32_
        %56 = cute.get_shape(%lay_122) : (!cute.layout<"8:1">) -> !cute.shape<"8">
        %e0_123 = cute.get_leaves(%56) : !cute.shape<"8">
        %lay_124 = cute.get_layout(%slice_80) : !memref_gmem_f32_3
        %shape = cute.make_shape() : () -> !cute.shape<"1">
        %lay_125 = cute.make_layout(%shape) : !cute.layout<"1:0">
        %append = cute.append_to_rank<2> (%lay_124, %lay_125) : !cute.layout<"(8):(1)">, !cute.layout<"1:0">
        %view = cute.make_view(%iter_81, %append) : !memref_gmem_f32_4
        %iter_126 = cute.get_iter(%view) : !memref_gmem_f32_4
        %lay_127 = cute.get_layout(%view) : !memref_gmem_f32_4
        %57 = cute.get_shape(%lay_127) : (!cute.layout<"(8,1):(1,0)">) -> !cute.shape<"(8,1)">
        %e0_128, %e1_129 = cute.get_leaves(%57) : !cute.shape<"(8,1)">
        %grouped = cute.group_modes(%view) <1, 2> : (!memref_gmem_f32_4) -> !memref_gmem_f32_5
        %iter_130 = cute.get_iter(%grouped) : !memref_gmem_f32_5
        %iter_131 = cute.get_iter(%grouped) : !memref_gmem_f32_5
        %lay_132 = cute.get_layout(%rmem) : !memref_rmem_f32_
        %shape_133 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_134 = cute.make_layout(%shape_133) : !cute.layout<"1:0">
        %append_135 = cute.append_to_rank<2> (%lay_132, %lay_134) : !cute.layout<"8:1">, !cute.layout<"1:0">
        %view_136 = cute.make_view(%iter_112, %append_135) : !memref_rmem_f32_1
        %iter_137 = cute.get_iter(%view_136) : !memref_rmem_f32_1
        %lay_138 = cute.get_layout(%view_136) : !memref_rmem_f32_1
        %58 = cute.get_shape(%lay_138) : (!cute.layout<"(8,1):(1,0)">) -> !cute.shape<"(8,1)">
        %e0_139, %e1_140 = cute.get_leaves(%58) : !cute.shape<"(8,1)">
        %grouped_141 = cute.group_modes(%view_136) <1, 2> : (!memref_rmem_f32_1) -> !memref_rmem_f32_2
        %iter_142 = cute.get_iter(%grouped_141) : !memref_rmem_f32_2
        %iter_143 = cute.get_iter(%grouped_141) : !memref_rmem_f32_2
        %lay_144 = cute.get_layout(%grouped) : !memref_gmem_f32_5
        %59 = cute.get_shape(%lay_144) : (!cute.layout<"(8,(1)):(1,(0))">) -> !cute.shape<"(8,(1))">
        %e0_145, %e1_146 = cute.get_leaves(%59) : !cute.shape<"(8,(1))">
        %lay_147 = cute.get_layout(%grouped_141) : !memref_rmem_f32_2
        %60 = cute.get_shape(%lay_147) : (!cute.layout<"(8,(1)):(1,(0))">) -> !cute.shape<"(8,(1))">
        %e0_148, %e1_149 = cute.get_leaves(%60) : !cute.shape<"(8,(1))">
        %sz = cute.size(%grouped) <{mode = [1]}> : (!memref_gmem_f32_5) -> !cute.int_tuple<"1">
        %e0_150 = cute.get_leaves(%sz) : !cute.int_tuple<"1">
        %sz_151 = cute.size(%grouped_141) <{mode = [1]}> : (!memref_rmem_f32_2) -> !cute.int_tuple<"1">
        %e0_152 = cute.get_leaves(%sz_151) : !cute.int_tuple<"1">
        cute.copy(%atom, %grouped, %grouped_141) : (!cute_nvgpu.atom.universal_copy<f32>, !memref_gmem_f32_5, !memref_rmem_f32_2)
        %61 = cute.memref.load_vec %rmem, row_major : !memref_rmem_f32_
        %62 = arith.fptosi %61 : vector<8xf32> to vector<8xi4>
        %shape_153 = cute.make_shape() : () -> !cute.shape<"8">
        %lay_154 = cute.make_layout(%shape_153) : !cute.layout<"8:1">
        %63 = cute.recast_layout<8, 4> (%lay_154) : !cute.layout<"8:1"> to !cute.layout<"4:1">
        %64 = cute.get_shape(%63) : (!cute.layout<"4:1">) -> !cute.shape<"4">
        %e0_155 = cute.get_leaves(%64) : !cute.shape<"4">
        %65 = builtin.unrealized_conversion_cast %62 : vector<8xi4> to vector<8xi4>
        %66 = vector.bitcast %65 : vector<8xi4> to vector<4xi8>
        %lay_156 = cute.get_layout(%rmem_117) : !memref_rmem_i8_
        %67 = cute.get_shape(%lay_156) : (!cute.layout<"4:1">) -> !cute.shape<"4">
        %e0_157 = cute.get_leaves(%67) : !cute.shape<"4">
        %int_tuple = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
        %sz_158 = cute.size(%int_tuple) : (!cute.int_tuple<"4">) -> !cute.int_tuple<"4">
        %e0_159 = cute.get_leaves(%sz_158) : !cute.int_tuple<"4">
        %int_tuple_160 = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
        %sz_161 = cute.size(%int_tuple_160) : (!cute.int_tuple<"4">) -> !cute.int_tuple<"4">
        %e0_162 = cute.get_leaves(%sz_161) : !cute.int_tuple<"4">
        cute.memref.store_vec %66, %rmem_117, row_major : !memref_rmem_i8_
        %atom_163 = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<i8>
        %lay_164 = cute.get_layout(%slice_83) : !memref_gmem_i8_3
        %68 = cute.get_shape(%lay_164) : (!cute.layout<"(4):(1)">) -> !cute.shape<"(4)">
        %e0_165 = cute.get_leaves(%68) : !cute.shape<"(4)">
        %lay_166 = cute.get_layout(%rmem_117) : !memref_rmem_i8_
        %shape_167 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_168 = cute.make_layout(%shape_167) : !cute.layout<"1:0">
        %append_169 = cute.append_to_rank<2> (%lay_166, %lay_168) : !cute.layout<"4:1">, !cute.layout<"1:0">
        %view_170 = cute.make_view(%iter_119, %append_169) : !memref_rmem_i8_1
        %iter_171 = cute.get_iter(%view_170) : !memref_rmem_i8_1
        %lay_172 = cute.get_layout(%view_170) : !memref_rmem_i8_1
        %69 = cute.get_shape(%lay_172) : (!cute.layout<"(4,1):(1,0)">) -> !cute.shape<"(4,1)">
        %e0_173, %e1_174 = cute.get_leaves(%69) : !cute.shape<"(4,1)">
        %grouped_175 = cute.group_modes(%view_170) <1, 2> : (!memref_rmem_i8_1) -> !memref_rmem_i8_2
        %iter_176 = cute.get_iter(%grouped_175) : !memref_rmem_i8_2
        %iter_177 = cute.get_iter(%grouped_175) : !memref_rmem_i8_2
        %lay_178 = cute.get_layout(%slice_83) : !memref_gmem_i8_3
        %shape_179 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_180 = cute.make_layout(%shape_179) : !cute.layout<"1:0">
        %append_181 = cute.append_to_rank<2> (%lay_178, %lay_180) : !cute.layout<"(4):(1)">, !cute.layout<"1:0">
        %view_182 = cute.make_view(%iter_84, %append_181) : !memref_gmem_i8_4
        %iter_183 = cute.get_iter(%view_182) : !memref_gmem_i8_4
        %lay_184 = cute.get_layout(%view_182) : !memref_gmem_i8_4
        %70 = cute.get_shape(%lay_184) : (!cute.layout<"(4,1):(1,0)">) -> !cute.shape<"(4,1)">
        %e0_185, %e1_186 = cute.get_leaves(%70) : !cute.shape<"(4,1)">
        %grouped_187 = cute.group_modes(%view_182) <1, 2> : (!memref_gmem_i8_4) -> !memref_gmem_i8_5
        %iter_188 = cute.get_iter(%grouped_187) : !memref_gmem_i8_5
        %iter_189 = cute.get_iter(%grouped_187) : !memref_gmem_i8_5
        %lay_190 = cute.get_layout(%grouped_175) : !memref_rmem_i8_2
        %71 = cute.get_shape(%lay_190) : (!cute.layout<"(4,(1)):(1,(0))">) -> !cute.shape<"(4,(1))">
        %e0_191, %e1_192 = cute.get_leaves(%71) : !cute.shape<"(4,(1))">
        %lay_193 = cute.get_layout(%grouped_187) : !memref_gmem_i8_5
        %72 = cute.get_shape(%lay_193) : (!cute.layout<"(4,(1)):(1,(0))">) -> !cute.shape<"(4,(1))">
        %e0_194, %e1_195 = cute.get_leaves(%72) : !cute.shape<"(4,(1))">
        %sz_196 = cute.size(%grouped_175) <{mode = [1]}> : (!memref_rmem_i8_2) -> !cute.int_tuple<"1">
        %e0_197 = cute.get_leaves(%sz_196) : !cute.int_tuple<"1">
        %sz_198 = cute.size(%grouped_187) <{mode = [1]}> : (!memref_gmem_i8_5) -> !cute.int_tuple<"1">
        %e0_199 = cute.get_leaves(%sz_198) : !cute.int_tuple<"1">
        cute.copy(%atom_163, %grouped_175, %grouped_187) : (!cute_nvgpu.atom.universal_copy<i8>, !memref_rmem_i8_2, !memref_gmem_i8_5)
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
    %lay_22 = cute.make_layout(%shape, %stride) : !cute.layout<"(128,8):(8,1)">
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
    %div = cute.zipped_divide(%arg0, %tile) : !memref_gmem_f32_6, !cute.tile<"[1024:1;1:0;1:0]">
    %iter_55 = cute.get_iter(%div) : !memref_gmem_f32_
    %iter_56 = cute.get_iter(%div) : !memref_gmem_f32_
    %tile_57 = cute.make_tile() : () -> !cute.tile<"[1024:1;1:0;1:0]">
    %div_58 = cute.zipped_divide(%20, %tile_57) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">, !cute.tile<"[1024:1;1:0;1:0]">
    %iter_59 = cute.get_iter(%div_58) : !cute.coord_tensor<"(0,0,0)", "((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">
    %e0_60, %e1_61, %e2_62 = cute.get_leaves(%iter_59) : !cute.int_tuple<"(0,0,0)">
    %iter_63 = cute.get_iter(%div_58) : !cute.coord_tensor<"(0,0,0)", "((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">
    %e0_64, %e1_65, %e2_66 = cute.get_leaves(%iter_63) : !cute.int_tuple<"(0,0,0)">
    %tile_67 = cute.make_tile() : () -> !cute.tile<"[512:1;1:0;1:0]">
    %div_68 = cute.zipped_divide(%view, %tile_67) : !memref_gmem_i8_6, !cute.tile<"[512:1;1:0;1:0]">
    %iter_69 = cute.get_iter(%div_68) : !memref_gmem_i8_
    %iter_70 = cute.get_iter(%div_68) : !memref_gmem_i8_
    %sz_71 = cute.size(%div) <{mode = [1]}> : (!memref_gmem_f32_) -> !cute.int_tuple<"?">
    %e0_72 = cute.get_leaves(%sz_71) : !cute.int_tuple<"?">
    %29 = cute.get_scalars(%e0_72) : !cute.int_tuple<"?">
    %sz_73 = cute.size(%lay_22) <{mode = [0]}> : (!cute.layout<"(128,8):(8,1)">) -> !cute.int_tuple<"128">
    %e0_74 = cute.get_leaves(%sz_73) : !cute.int_tuple<"128">
    %lay_75 = cute.get_layout(%div) : !memref_gmem_f32_
    %30 = cute.get_shape(%lay_75) : (!cute.layout<"((1024,1,1),(?,?,?)):((1,0,0),(1024,?{i64},?{i64}))">) -> !cute.shape<"((1024,1,1),(?,?,?))">
    %e0_76, %e1_77, %e2_78, %e3, %e4, %e5 = cute.get_leaves(%30) : !cute.shape<"((1024,1,1),(?,?,?))">
    %itup_79 = cute.to_int_tuple(%e3) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %31 = cute.get_scalars(%itup_79) : !cute.int_tuple<"?">
    %itup_80 = cute.to_int_tuple(%e4) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %32 = cute.get_scalars(%itup_80) : !cute.int_tuple<"?">
    %itup_81 = cute.to_int_tuple(%e5) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %33 = cute.get_scalars(%itup_81) : !cute.int_tuple<"?">
    %34 = cute.get_stride(%lay_75) : (!cute.layout<"((1024,1,1),(?,?,?)):((1,0,0),(1024,?{i64},?{i64}))">) -> !cute.stride<"((1,0,0),(1024,?{i64},?{i64}))">
    %e0_82, %e1_83, %e2_84, %e3_85, %e4_86, %e5_87 = cute.get_leaves(%34) : !cute.stride<"((1,0,0),(1024,?{i64},?{i64}))">
    %itup_88 = cute.to_int_tuple(%e4_86) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
    %35 = cute.get_scalars(%itup_88) : !cute.int_tuple<"?{i64}">
    %itup_89 = cute.to_int_tuple(%e5_87) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
    %36 = cute.get_scalars(%itup_89) : !cute.int_tuple<"?{i64}">
    %lay_90 = cute.get_layout(%div_68) : !memref_gmem_i8_
    %37 = cute.get_shape(%lay_90) : (!cute.layout<"((512,1,1),(?,?,?)):((1,0,0),(512,?{i64},?{i64}))">) -> !cute.shape<"((512,1,1),(?,?,?))">
    %e0_91, %e1_92, %e2_93, %e3_94, %e4_95, %e5_96 = cute.get_leaves(%37) : !cute.shape<"((512,1,1),(?,?,?))">
    %itup_97 = cute.to_int_tuple(%e3_94) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %38 = cute.get_scalars(%itup_97) : !cute.int_tuple<"?">
    %itup_98 = cute.to_int_tuple(%e4_95) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %39 = cute.get_scalars(%itup_98) : !cute.int_tuple<"?">
    %itup_99 = cute.to_int_tuple(%e5_96) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %40 = cute.get_scalars(%itup_99) : !cute.int_tuple<"?">
    %41 = cute.get_stride(%lay_90) : (!cute.layout<"((512,1,1),(?,?,?)):((1,0,0),(512,?{i64},?{i64}))">) -> !cute.stride<"((1,0,0),(512,?{i64},?{i64}))">
    %e0_100, %e1_101, %e2_102, %e3_103, %e4_104, %e5_105 = cute.get_leaves(%41) : !cute.stride<"((1,0,0),(512,?{i64},?{i64}))">
    %itup_106 = cute.to_int_tuple(%e4_104) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
    %42 = cute.get_scalars(%itup_106) : !cute.int_tuple<"?{i64}">
    %itup_107 = cute.to_int_tuple(%e5_105) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
    %43 = cute.get_scalars(%itup_107) : !cute.int_tuple<"?{i64}">
    %lay_108 = cute.get_layout(%div_58) : !cute.coord_tensor<"(0,0,0)", "((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">
    %44 = cute.get_shape(%lay_108) : (!cute.layout<"((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">) -> !cute.shape<"((1024,1,1),(?,?,?))">
    %e0_109, %e1_110, %e2_111, %e3_112, %e4_113, %e5_114 = cute.get_leaves(%44) : !cute.shape<"((1024,1,1),(?,?,?))">
    %itup_115 = cute.to_int_tuple(%e3_112) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %45 = cute.get_scalars(%itup_115) : !cute.int_tuple<"?">
    %itup_116 = cute.to_int_tuple(%e4_113) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %46 = cute.get_scalars(%itup_116) : !cute.int_tuple<"?">
    %itup_117 = cute.to_int_tuple(%e5_114) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %47 = cute.get_scalars(%itup_117) : !cute.int_tuple<"?">
    %48 = cute.get_stride(%lay_108) : (!cute.layout<"((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">) -> !cute.stride<"((1@0,0,0),(1024@0,1@1,1@2))">
    %e0_118, %e1_119, %e2_120, %e3_121, %e4_122, %e5_123 = cute.get_leaves(%48) : !cute.stride<"((1@0,0,0),(1024@0,1@1,1@2))">
    %49 = cute.get_shape(%lay_22) : (!cute.layout<"(128,8):(8,1)">) -> !cute.shape<"(128,8)">
    %e0_124, %e1_125 = cute.get_leaves(%49) : !cute.shape<"(128,8)">
    %50 = cute.get_stride(%lay_22) : (!cute.layout<"(128,8):(8,1)">) -> !cute.stride<"(8,1)">
    %e0_126, %e1_127 = cute.get_leaves(%50) : !cute.stride<"(8,1)">
    %51 = cute.get_shape(%14) : (!cute.layout<"(128,4):(4,1)">) -> !cute.shape<"(128,4)">
    %e0_128, %e1_129 = cute.get_leaves(%51) : !cute.shape<"(128,4)">
    %52 = cute.get_stride(%14) : (!cute.layout<"(128,4):(4,1)">) -> !cute.stride<"(4,1)">
    %e0_130, %e1_131 = cute.get_leaves(%52) : !cute.stride<"(4,1)">
    %53 = arith.index_cast %29 : i32 to index
    %c1 = arith.constant 1 : index
    %c128 = arith.constant 128 : index
    %c0_i32 = arith.constant 0 : i32
    gpu.launch_func  @kernels::@kernel_cutlass__convert_kernel_tensorptrf32gmemo1024111001024_tensorptri8gmemalign128o51211100512_tensor000o1024111000102401112____Float32_Int4_0 blocks in (%53, %c1, %c1) threads in (%c128, %c1, %c1)  dynamic_shared_memory_size %c0_i32 args(%div : !memref_gmem_f32_, %div_68 : !memref_gmem_i8_, %div_58 : !cute.coord_tensor<"(0,0,0)", "((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">, %17 : i32, %18 : i32, %19 : i32) {use_pdl = false}
    return
  }
}
