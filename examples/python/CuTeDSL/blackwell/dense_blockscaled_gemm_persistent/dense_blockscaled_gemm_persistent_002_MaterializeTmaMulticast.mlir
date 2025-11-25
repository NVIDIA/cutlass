!memref_gmem_f32_ = !cute.memref<f32, gmem, "((1,1024,1),(?,?,?)):((0,?{i64},0),(?{i64},?{i64 div=1024},1))">
!memref_gmem_f32_1 = !cute.memref<f32, gmem, "((1,1024,1)):((0,?{i64},0))">
!memref_gmem_f32_2 = !cute.memref<f32, gmem, "(128,8):(?{i64 div=8},?{i64})">
!memref_gmem_f32_3 = !cute.memref<f32, gmem, "(8):(?{i64})">
!memref_gmem_f32_4 = !cute.memref<f32, gmem, "(8,1):(?{i64},0)">
!memref_gmem_f32_5 = !cute.memref<f32, gmem, "(8,(1)):(?{i64},(0))">
!memref_gmem_f32_6 = !cute.memref<f32, gmem, "(?,?,?):(?{i64},?{i64},1)">
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
!memref_rmem_i8_ = !cute.memref<i8, rmem, align<32>, "4:1">
!memref_rmem_i8_1 = !cute.memref<i8, rmem, align<32>, "(4,1):(1,0)">
!memref_rmem_i8_2 = !cute.memref<i8, rmem, align<32>, "(4,(1)):(1,(0))">
module attributes {gpu.container_module} {
  gpu.module @kernels {
    func.func public @kernel_cutlass__convert_kernel_tensorptrf32gmemo11024100div10241_tensorptri8gmemalign16o15121010512_tensor000o1102410110101024112____Float32_Float4E2M1FN_0(%arg0: !memref_gmem_f32_, %arg1: !memref_gmem_i8_, %arg2: !cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">, %arg3: i32, %arg4: i32, %arg5: i32) attributes {cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} {
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
      %2 = cute.get_shape(%lay) : (!cute.layout<"((1,1024,1),(?,?,?)):((0,?{i64},0),(?{i64},?{i64 div=1024},1))">) -> !cute.shape<"((1,1024,1),(?,?,?))">
      %e0_8, %e1_9, %e2_10, %e3, %e4, %e5 = cute.get_leaves(%2) : !cute.shape<"((1,1024,1),(?,?,?))">
      %itup = cute.to_int_tuple(%e3) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %3 = cute.get_scalars(%itup) : !cute.int_tuple<"?">
      %itup_11 = cute.to_int_tuple(%e4) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %4 = cute.get_scalars(%itup_11) : !cute.int_tuple<"?">
      %itup_12 = cute.to_int_tuple(%e5) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %5 = cute.get_scalars(%itup_12) : !cute.int_tuple<"?">
      %6 = cute.get_stride(%lay) : (!cute.layout<"((1,1024,1),(?,?,?)):((0,?{i64},0),(?{i64},?{i64 div=1024},1))">) -> !cute.stride<"((0,?{i64},0),(?{i64},?{i64 div=1024},1))">
      %e0_13, %e1_14, %e2_15, %e3_16, %e4_17, %e5_18 = cute.get_leaves(%6) : !cute.stride<"((0,?{i64},0),(?{i64},?{i64 div=1024},1))">
      %itup_19 = cute.to_int_tuple(%e1_14) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
      %7 = cute.get_scalars(%itup_19) : !cute.int_tuple<"?{i64}">
      %itup_20 = cute.to_int_tuple(%e3_16) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
      %8 = cute.get_scalars(%itup_20) : !cute.int_tuple<"?{i64}">
      %itup_21 = cute.to_int_tuple(%e4_17) : !cute.stride<"?{i64 div=1024}"> to !cute.int_tuple<"?{i64 div=1024}">
      %9 = cute.get_scalars(%itup_21) : !cute.int_tuple<"?{i64 div=1024}">
      %lay_22 = cute.get_layout(%arg1) : !memref_gmem_i8_
      %10 = cute.get_shape(%lay_22) : (!cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !cute.shape<"((1,512,1),(?,?,?))">
      %e0_23, %e1_24, %e2_25, %e3_26, %e4_27, %e5_28 = cute.get_leaves(%10) : !cute.shape<"((1,512,1),(?,?,?))">
      %itup_29 = cute.to_int_tuple(%e3_26) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %11 = cute.get_scalars(%itup_29) : !cute.int_tuple<"?">
      %itup_30 = cute.to_int_tuple(%e4_27) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %12 = cute.get_scalars(%itup_30) : !cute.int_tuple<"?">
      %itup_31 = cute.to_int_tuple(%e5_28) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %13 = cute.get_scalars(%itup_31) : !cute.int_tuple<"?">
      %14 = cute.get_stride(%lay_22) : (!cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !cute.stride<"((0,1,0),(?{i64},512,?{i64}))">
      %e0_32, %e1_33, %e2_34, %e3_35, %e4_36, %e5_37 = cute.get_leaves(%14) : !cute.stride<"((0,1,0),(?{i64},512,?{i64}))">
      %itup_38 = cute.to_int_tuple(%e3_35) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
      %15 = cute.get_scalars(%itup_38) : !cute.int_tuple<"?{i64}">
      %itup_39 = cute.to_int_tuple(%e5_37) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
      %16 = cute.get_scalars(%itup_39) : !cute.int_tuple<"?{i64}">
      %lay_40 = cute.get_layout(%arg2) : !cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">
      %17 = cute.get_shape(%lay_40) : (!cute.layout<"((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">) -> !cute.shape<"((1,1024,1),(?,?,?))">
      %e0_41, %e1_42, %e2_43, %e3_44, %e4_45, %e5_46 = cute.get_leaves(%17) : !cute.shape<"((1,1024,1),(?,?,?))">
      %itup_47 = cute.to_int_tuple(%e3_44) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %18 = cute.get_scalars(%itup_47) : !cute.int_tuple<"?">
      %itup_48 = cute.to_int_tuple(%e4_45) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %19 = cute.get_scalars(%itup_48) : !cute.int_tuple<"?">
      %itup_49 = cute.to_int_tuple(%e5_46) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %20 = cute.get_scalars(%itup_49) : !cute.int_tuple<"?">
      %21 = cute.get_stride(%lay_40) : (!cute.layout<"((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">) -> !cute.stride<"((0,1@1,0),(1@0,1024@1,1@2))">
      %e0_50, %e1_51, %e2_52, %e3_53, %e4_54, %e5_55 = cute.get_leaves(%21) : !cute.stride<"((0,1@1,0),(1@0,1024@1,1@2))">
      %22 = cute.get_shape(%0) : (!cute.layout<"(128,8):(8,1)">) -> !cute.shape<"(128,8)">
      %e0_56, %e1_57 = cute.get_leaves(%22) : !cute.shape<"(128,8)">
      %23 = cute.get_stride(%0) : (!cute.layout<"(128,8):(8,1)">) -> !cute.stride<"(8,1)">
      %e0_58, %e1_59 = cute.get_leaves(%23) : !cute.stride<"(8,1)">
      %24 = cute.get_shape(%1) : (!cute.layout<"(128,4):(4,1)">) -> !cute.shape<"(128,4)">
      %e0_60, %e1_61 = cute.get_leaves(%24) : !cute.shape<"(128,4)">
      %25 = cute.get_stride(%1) : (!cute.layout<"(128,4):(4,1)">) -> !cute.stride<"(4,1)">
      %e0_62, %e1_63 = cute.get_leaves(%25) : !cute.stride<"(4,1)">
      %26 = nvvm.read.ptx.sreg.tid.x : i32
      %27 = nvvm.read.ptx.sreg.ctaid.x : i32
      %coord = cute.make_coord(%27) : (i32) -> !cute.coord<"(_,?)">
      %slice = cute.slice(%arg0, %coord) : !memref_gmem_f32_, !cute.coord<"(_,?)">
      %iter_64 = cute.get_iter(%slice) : !memref_gmem_f32_1
      %coord_65 = cute.make_coord(%27) : (i32) -> !cute.coord<"(_,?)">
      %slice_66 = cute.slice(%arg1, %coord_65) : !memref_gmem_i8_, !cute.coord<"(_,?)">
      %iter_67 = cute.get_iter(%slice_66) : !memref_gmem_i8_1
      %coord_68 = cute.make_coord(%27) : (i32) -> !cute.coord<"(_,?)">
      %slice_69 = cute.slice(%arg2, %coord_68) : !cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">, !cute.coord<"(_,?)">
      %iter_70 = cute.get_iter(%slice_69) : !cute.coord_tensor<"(?,?{div=1024},?)", "((1,1024,1)):((0,1@1,0))">
      %e0_71, %e1_72, %e2_73 = cute.get_leaves(%iter_70) : !cute.int_tuple<"(?,?{div=1024},?)">
      %28 = cute.get_scalars(%e0_71) : !cute.int_tuple<"?">
      %29 = cute.get_scalars(%e1_72) : !cute.int_tuple<"?{div=1024}">
      %30 = cute.get_scalars(%e2_73) : !cute.int_tuple<"?">
      %31 = cute.composition(%slice, %0) : (!memref_gmem_f32_1, !cute.layout<"(128,8):(8,1)">) -> !memref_gmem_f32_2
      %iter_74 = cute.get_iter(%31) : !memref_gmem_f32_2
      %32 = cute.composition(%slice_66, %1) : (!memref_gmem_i8_1, !cute.layout<"(128,4):(4,1)">) -> !memref_gmem_i8_2
      %iter_75 = cute.get_iter(%32) : !memref_gmem_i8_2
      %33 = cute.composition(%slice_69, %0) : (!cute.coord_tensor<"(?,?{div=1024},?)", "((1,1024,1)):((0,1@1,0))">, !cute.layout<"(128,8):(8,1)">) -> !cute.coord_tensor<"(?,?{div=1024},?)", "(128,8):(8@1,1@1)">
      %iter_76 = cute.get_iter(%33) : !cute.coord_tensor<"(?,?{div=1024},?)", "(128,8):(8@1,1@1)">
      %e0_77, %e1_78, %e2_79 = cute.get_leaves(%iter_76) : !cute.int_tuple<"(?,?{div=1024},?)">
      %34 = cute.get_scalars(%e0_77) : !cute.int_tuple<"?">
      %35 = cute.get_scalars(%e1_78) : !cute.int_tuple<"?{div=1024}">
      %36 = cute.get_scalars(%e2_79) : !cute.int_tuple<"?">
      %coord_80 = cute.make_coord(%26) : (i32) -> !cute.coord<"(?,_)">
      %slice_81 = cute.slice(%31, %coord_80) : !memref_gmem_f32_2, !cute.coord<"(?,_)">
      %iter_82 = cute.get_iter(%slice_81) : !memref_gmem_f32_3
      %coord_83 = cute.make_coord(%26) : (i32) -> !cute.coord<"(?,_)">
      %slice_84 = cute.slice(%32, %coord_83) : !memref_gmem_i8_2, !cute.coord<"(?,_)">
      %iter_85 = cute.get_iter(%slice_84) : !memref_gmem_i8_3
      %coord_86 = cute.make_coord(%26) : (i32) -> !cute.coord<"(?,_)">
      %slice_87 = cute.slice(%33, %coord_86) : !cute.coord_tensor<"(?,?{div=1024},?)", "(128,8):(8@1,1@1)">, !cute.coord<"(?,_)">
      %iter_88 = cute.get_iter(%slice_87) : !cute.coord_tensor<"(?,?{div=8},?)", "(8):(1@1)">
      %e0_89, %e1_90, %e2_91 = cute.get_leaves(%iter_88) : !cute.int_tuple<"(?,?{div=8},?)">
      %37 = cute.get_scalars(%e0_89) : !cute.int_tuple<"?">
      %38 = cute.get_scalars(%e1_90) : !cute.int_tuple<"?{div=8}">
      %39 = cute.get_scalars(%e2_91) : !cute.int_tuple<"?">
      %coord_92 = cute.make_coord() : () -> !cute.coord<"0">
      %slice_93 = cute.slice(%slice_87, %coord_92) : !cute.coord_tensor<"(?,?{div=8},?)", "(8):(1@1)">, !cute.coord<"0">
      %iter_94 = cute.get_iter(%slice_93) : !cute.coord_tensor<"(?,?{div=8},?)", "():()">
      %e0_95, %e1_96, %e2_97 = cute.get_leaves(%iter_94) : !cute.int_tuple<"(?,?{div=8},?)">
      %40 = cute.get_scalars(%e0_95) : !cute.int_tuple<"?">
      %41 = cute.get_scalars(%e1_96) : !cute.int_tuple<"?{div=8}">
      %42 = cute.get_scalars(%e2_97) : !cute.int_tuple<"?">
      %iter_98 = cute.get_iter(%slice_93) : !cute.coord_tensor<"(?,?{div=8},?)", "():()">
      %e0_99, %e1_100, %e2_101 = cute.get_leaves(%iter_98) : !cute.int_tuple<"(?,?{div=8},?)">
      %43 = cute.get_scalars(%e0_99) : !cute.int_tuple<"?">
      %44 = cute.get_scalars(%e1_100) : !cute.int_tuple<"?{div=8}">
      %45 = cute.get_scalars(%e2_101) : !cute.int_tuple<"?">
      %iter_102 = cute.get_iter(%slice_93) : !cute.coord_tensor<"(?,?{div=8},?)", "():()">
      %e0_103, %e1_104, %e2_105 = cute.get_leaves(%iter_102) : !cute.int_tuple<"(?,?{div=8},?)">
      %46 = cute.get_scalars(%e0_103) : !cute.int_tuple<"?">
      %47 = cute.get_scalars(%e1_104) : !cute.int_tuple<"?{div=8}">
      %48 = cute.get_scalars(%e2_105) : !cute.int_tuple<"?">
      %coord_106 = cute.make_coord(%e0_103, %e1_104, %e2_105) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?{div=8},?)">
      %coord_107 = cute.make_coord(%arg3, %arg4, %arg5) : (i32, i32, i32) -> !cute.coord<"(?,?,?)">
      %49 = cute.elem_less(%coord_106, %coord_107) : !cute.coord<"(?,?{div=8},?)">, !cute.coord<"(?,?,?)">
      scf.if %49 {
        %50 = cute.get_shape(%0) : (!cute.layout<"(128,8):(8,1)">) -> !cute.shape<"(128,8)">
        %e0_108, %e1_109 = cute.get_leaves(%50) : !cute.shape<"(128,8)">
        %51 = cute.get_shape(%0) : (!cute.layout<"(128,8):(8,1)">) -> !cute.shape<"(128,8)">
        %e0_110, %e1_111 = cute.get_leaves(%51) : !cute.shape<"(128,8)">
        %52 = cute.get(%0) <{mode = [1]}> : !cute.layout<"(128,8):(8,1)"> -> !cute.layout<"8:1">
        %rmem = cute.memref.alloca(%52) : !memref_rmem_f32_
        %iter_112 = cute.get_iter(%rmem) : !memref_rmem_f32_
        %iter_113 = cute.get_iter(%rmem) : !memref_rmem_f32_
        %53 = cute.get_shape(%1) : (!cute.layout<"(128,4):(4,1)">) -> !cute.shape<"(128,4)">
        %e0_114, %e1_115 = cute.get_leaves(%53) : !cute.shape<"(128,4)">
        %54 = cute.get_shape(%1) : (!cute.layout<"(128,4):(4,1)">) -> !cute.shape<"(128,4)">
        %e0_116, %e1_117 = cute.get_leaves(%54) : !cute.shape<"(128,4)">
        %55 = cute.get(%1) <{mode = [1]}> : !cute.layout<"(128,4):(4,1)"> -> !cute.layout<"4:1">
        %rmem_118 = cute.memref.alloca(%55) : !memref_rmem_i8_
        %iter_119 = cute.get_iter(%rmem_118) : !memref_rmem_i8_
        %iter_120 = cute.get_iter(%rmem_118) : !memref_rmem_i8_
        %atom = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<f32>
        %lay_121 = cute.get_layout(%slice_81) : !memref_gmem_f32_3
        %56 = cute.get_shape(%lay_121) : (!cute.layout<"(8):(?{i64})">) -> !cute.shape<"(8)">
        %e0_122 = cute.get_leaves(%56) : !cute.shape<"(8)">
        %lay_123 = cute.get_layout(%rmem) : !memref_rmem_f32_
        %57 = cute.get_shape(%lay_123) : (!cute.layout<"8:1">) -> !cute.shape<"8">
        %e0_124 = cute.get_leaves(%57) : !cute.shape<"8">
        %lay_125 = cute.get_layout(%slice_81) : !memref_gmem_f32_3
        %shape = cute.make_shape() : () -> !cute.shape<"1">
        %lay_126 = cute.make_layout(%shape) : !cute.layout<"1:0">
        %append = cute.append_to_rank<2> (%lay_125, %lay_126) : !cute.layout<"(8):(?{i64})">, !cute.layout<"1:0">
        %view = cute.make_view(%iter_82, %append) : !memref_gmem_f32_4
        %iter_127 = cute.get_iter(%view) : !memref_gmem_f32_4
        %lay_128 = cute.get_layout(%view) : !memref_gmem_f32_4
        %58 = cute.get_shape(%lay_128) : (!cute.layout<"(8,1):(?{i64},0)">) -> !cute.shape<"(8,1)">
        %e0_129, %e1_130 = cute.get_leaves(%58) : !cute.shape<"(8,1)">
        %grouped = cute.group_modes(%view) <1, 2> : (!memref_gmem_f32_4) -> !memref_gmem_f32_5
        %iter_131 = cute.get_iter(%grouped) : !memref_gmem_f32_5
        %iter_132 = cute.get_iter(%grouped) : !memref_gmem_f32_5
        %lay_133 = cute.get_layout(%rmem) : !memref_rmem_f32_
        %shape_134 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_135 = cute.make_layout(%shape_134) : !cute.layout<"1:0">
        %append_136 = cute.append_to_rank<2> (%lay_133, %lay_135) : !cute.layout<"8:1">, !cute.layout<"1:0">
        %view_137 = cute.make_view(%iter_113, %append_136) : !memref_rmem_f32_1
        %iter_138 = cute.get_iter(%view_137) : !memref_rmem_f32_1
        %lay_139 = cute.get_layout(%view_137) : !memref_rmem_f32_1
        %59 = cute.get_shape(%lay_139) : (!cute.layout<"(8,1):(1,0)">) -> !cute.shape<"(8,1)">
        %e0_140, %e1_141 = cute.get_leaves(%59) : !cute.shape<"(8,1)">
        %grouped_142 = cute.group_modes(%view_137) <1, 2> : (!memref_rmem_f32_1) -> !memref_rmem_f32_2
        %iter_143 = cute.get_iter(%grouped_142) : !memref_rmem_f32_2
        %iter_144 = cute.get_iter(%grouped_142) : !memref_rmem_f32_2
        %lay_145 = cute.get_layout(%grouped) : !memref_gmem_f32_5
        %60 = cute.get_shape(%lay_145) : (!cute.layout<"(8,(1)):(?{i64},(0))">) -> !cute.shape<"(8,(1))">
        %e0_146, %e1_147 = cute.get_leaves(%60) : !cute.shape<"(8,(1))">
        %lay_148 = cute.get_layout(%grouped_142) : !memref_rmem_f32_2
        %61 = cute.get_shape(%lay_148) : (!cute.layout<"(8,(1)):(1,(0))">) -> !cute.shape<"(8,(1))">
        %e0_149, %e1_150 = cute.get_leaves(%61) : !cute.shape<"(8,(1))">
        %sz = cute.size(%grouped) <{mode = [1]}> : (!memref_gmem_f32_5) -> !cute.int_tuple<"1">
        %e0_151 = cute.get_leaves(%sz) : !cute.int_tuple<"1">
        %sz_152 = cute.size(%grouped_142) <{mode = [1]}> : (!memref_rmem_f32_2) -> !cute.int_tuple<"1">
        %e0_153 = cute.get_leaves(%sz_152) : !cute.int_tuple<"1">
        cute.copy(%atom, %grouped, %grouped_142) : (!cute_nvgpu.atom.universal_copy<f32>, !memref_gmem_f32_5, !memref_rmem_f32_2)
        %62 = cute.memref.load_vec %rmem, row_major : !memref_rmem_f32_
        %63 = nvgpu.cvt_fptrunc %62 : vector<8xf32> to vector<8xf4E2M1FN>
        %shape_154 = cute.make_shape() : () -> !cute.shape<"8">
        %lay_155 = cute.make_layout(%shape_154) : !cute.layout<"8:1">
        %64 = cute.recast_layout<8, 4> (%lay_155) : !cute.layout<"8:1"> to !cute.layout<"4:1">
        %65 = cute.get_shape(%64) : (!cute.layout<"4:1">) -> !cute.shape<"4">
        %e0_156 = cute.get_leaves(%65) : !cute.shape<"4">
        %66 = builtin.unrealized_conversion_cast %63 : vector<8xf4E2M1FN> to vector<8xi4>
        %67 = vector.bitcast %66 : vector<8xi4> to vector<4xi8>
        %lay_157 = cute.get_layout(%rmem_118) : !memref_rmem_i8_
        %68 = cute.get_shape(%lay_157) : (!cute.layout<"4:1">) -> !cute.shape<"4">
        %e0_158 = cute.get_leaves(%68) : !cute.shape<"4">
        %int_tuple = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
        %sz_159 = cute.size(%int_tuple) : (!cute.int_tuple<"4">) -> !cute.int_tuple<"4">
        %e0_160 = cute.get_leaves(%sz_159) : !cute.int_tuple<"4">
        %int_tuple_161 = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
        %sz_162 = cute.size(%int_tuple_161) : (!cute.int_tuple<"4">) -> !cute.int_tuple<"4">
        %e0_163 = cute.get_leaves(%sz_162) : !cute.int_tuple<"4">
        cute.memref.store_vec %67, %rmem_118, row_major : !memref_rmem_i8_
        %atom_164 = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<i8>
        %lay_165 = cute.get_layout(%slice_84) : !memref_gmem_i8_3
        %69 = cute.get_shape(%lay_165) : (!cute.layout<"(4):(1)">) -> !cute.shape<"(4)">
        %e0_166 = cute.get_leaves(%69) : !cute.shape<"(4)">
        %lay_167 = cute.get_layout(%rmem_118) : !memref_rmem_i8_
        %shape_168 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_169 = cute.make_layout(%shape_168) : !cute.layout<"1:0">
        %append_170 = cute.append_to_rank<2> (%lay_167, %lay_169) : !cute.layout<"4:1">, !cute.layout<"1:0">
        %view_171 = cute.make_view(%iter_120, %append_170) : !memref_rmem_i8_1
        %iter_172 = cute.get_iter(%view_171) : !memref_rmem_i8_1
        %lay_173 = cute.get_layout(%view_171) : !memref_rmem_i8_1
        %70 = cute.get_shape(%lay_173) : (!cute.layout<"(4,1):(1,0)">) -> !cute.shape<"(4,1)">
        %e0_174, %e1_175 = cute.get_leaves(%70) : !cute.shape<"(4,1)">
        %grouped_176 = cute.group_modes(%view_171) <1, 2> : (!memref_rmem_i8_1) -> !memref_rmem_i8_2
        %iter_177 = cute.get_iter(%grouped_176) : !memref_rmem_i8_2
        %iter_178 = cute.get_iter(%grouped_176) : !memref_rmem_i8_2
        %lay_179 = cute.get_layout(%slice_84) : !memref_gmem_i8_3
        %shape_180 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_181 = cute.make_layout(%shape_180) : !cute.layout<"1:0">
        %append_182 = cute.append_to_rank<2> (%lay_179, %lay_181) : !cute.layout<"(4):(1)">, !cute.layout<"1:0">
        %view_183 = cute.make_view(%iter_85, %append_182) : !memref_gmem_i8_4
        %iter_184 = cute.get_iter(%view_183) : !memref_gmem_i8_4
        %lay_185 = cute.get_layout(%view_183) : !memref_gmem_i8_4
        %71 = cute.get_shape(%lay_185) : (!cute.layout<"(4,1):(1,0)">) -> !cute.shape<"(4,1)">
        %e0_186, %e1_187 = cute.get_leaves(%71) : !cute.shape<"(4,1)">
        %grouped_188 = cute.group_modes(%view_183) <1, 2> : (!memref_gmem_i8_4) -> !memref_gmem_i8_5
        %iter_189 = cute.get_iter(%grouped_188) : !memref_gmem_i8_5
        %iter_190 = cute.get_iter(%grouped_188) : !memref_gmem_i8_5
        %lay_191 = cute.get_layout(%grouped_176) : !memref_rmem_i8_2
        %72 = cute.get_shape(%lay_191) : (!cute.layout<"(4,(1)):(1,(0))">) -> !cute.shape<"(4,(1))">
        %e0_192, %e1_193 = cute.get_leaves(%72) : !cute.shape<"(4,(1))">
        %lay_194 = cute.get_layout(%grouped_188) : !memref_gmem_i8_5
        %73 = cute.get_shape(%lay_194) : (!cute.layout<"(4,(1)):(1,(0))">) -> !cute.shape<"(4,(1))">
        %e0_195, %e1_196 = cute.get_leaves(%73) : !cute.shape<"(4,(1))">
        %sz_197 = cute.size(%grouped_176) <{mode = [1]}> : (!memref_rmem_i8_2) -> !cute.int_tuple<"1">
        %e0_198 = cute.get_leaves(%sz_197) : !cute.int_tuple<"1">
        %sz_199 = cute.size(%grouped_188) <{mode = [1]}> : (!memref_gmem_i8_5) -> !cute.int_tuple<"1">
        %e0_200 = cute.get_leaves(%sz_199) : !cute.int_tuple<"1">
        cute.copy(%atom_164, %grouped_176, %grouped_188) : (!cute_nvgpu.atom.universal_copy<i8>, !memref_rmem_i8_2, !memref_gmem_i8_5)
      }
      return
    }
  }
  func.func @cutlass__convert_Tensorgmemoi64i641_Tensorgmemoi641i64_1_8(%arg0: !memref_gmem_f32_6, %arg1: !memref_gmem_f4E2M1FN) attributes {llvm.emit_c_interface} {
    %iter = cute.get_iter(%arg0) : !memref_gmem_f32_6
    %iter_0 = cute.get_iter(%arg1) : !memref_gmem_f4E2M1FN
    %iter_1 = cute.get_iter(%arg0) : !memref_gmem_f32_6
    %iter_2 = cute.get_iter(%arg1) : !memref_gmem_f4E2M1FN
    %lay = cute.get_layout(%arg0) : !memref_gmem_f32_6
    %0 = cute.get_shape(%lay) : (!cute.layout<"(?,?,?):(?{i64},?{i64},1)">) -> !cute.shape<"(?,?,?)">
    %e0, %e1, %e2 = cute.get_leaves(%0) : !cute.shape<"(?,?,?)">
    %itup = cute.to_int_tuple(%e0) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %1 = cute.get_scalars(%itup) : !cute.int_tuple<"?">
    %itup_3 = cute.to_int_tuple(%e1) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %2 = cute.get_scalars(%itup_3) : !cute.int_tuple<"?">
    %itup_4 = cute.to_int_tuple(%e2) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %3 = cute.get_scalars(%itup_4) : !cute.int_tuple<"?">
    %4 = cute.get_stride(%lay) : (!cute.layout<"(?,?,?):(?{i64},?{i64},1)">) -> !cute.stride<"(?{i64},?{i64},1)">
    %e0_5, %e1_6, %e2_7 = cute.get_leaves(%4) : !cute.stride<"(?{i64},?{i64},1)">
    %itup_8 = cute.to_int_tuple(%e0_5) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
    %5 = cute.get_scalars(%itup_8) : !cute.int_tuple<"?{i64}">
    %itup_9 = cute.to_int_tuple(%e1_6) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
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
    %lay_22 = cute.make_layout(%shape, %stride) : !cute.layout<"(128,8):(8,1)">
    %14 = cute.recast_layout<8, 4> (%lay_22) : !cute.layout<"(128,8):(8,1)"> to !cute.layout<"(128,4):(4,1)">
    %iter_23 = cute.recast_iter(%iter_2) : !cute.ptr<f4E2M1FN, gmem, align<16>> to !cute.ptr<i8, gmem, align<16>>
    %lay_24 = cute.get_layout(%arg1) : !memref_gmem_f4E2M1FN
    %15 = cute.recast_layout<8, 4> (%lay_24) : !cute.layout<"(?,?,?):(?{i64},1,?{i64})"> to !cute.layout<"(?,?,?):(?{i64},1,?{i64})">
    %view = cute.make_view(%iter_23, %15) : !memref_gmem_i8_6
    %iter_25 = cute.get_iter(%view) : !memref_gmem_i8_6
    %lay_26 = cute.get_layout(%arg0) : !memref_gmem_f32_6
    %16 = cute.get_shape(%lay_26) : (!cute.layout<"(?,?,?):(?{i64},?{i64},1)">) -> !cute.shape<"(?,?,?)">
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
    %21 = cute.get_shape(%lay_38) : (!cute.layout<"(?,?,?):(?{i64},?{i64},1)">) -> !cute.shape<"(?,?,?)">
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
    %25 = cute.get_shape(%lay_46) : (!cute.layout<"(?,?,?):(?{i64},1,?{i64})">) -> !cute.shape<"(?,?,?)">
    %e0_47, %e1_48, %e2_49 = cute.get_leaves(%25) : !cute.shape<"(?,?,?)">
    %itup_50 = cute.to_int_tuple(%e0_47) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %26 = cute.get_scalars(%itup_50) : !cute.int_tuple<"?">
    %itup_51 = cute.to_int_tuple(%e1_48) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %27 = cute.get_scalars(%itup_51) : !cute.int_tuple<"?">
    %itup_52 = cute.to_int_tuple(%e2_49) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %28 = cute.get_scalars(%itup_52) : !cute.int_tuple<"?">
    %sz_53 = cute.size(%14) : (!cute.layout<"(128,4):(4,1)">) -> !cute.int_tuple<"512">
    %e0_54 = cute.get_leaves(%sz_53) : !cute.int_tuple<"512">
    %tile = cute.make_tile() : () -> !cute.tile<"[1:0;1024:1;1:0]">
    %div = cute.zipped_divide(%arg0, %tile) : !memref_gmem_f32_6, !cute.tile<"[1:0;1024:1;1:0]">
    %iter_55 = cute.get_iter(%div) : !memref_gmem_f32_
    %iter_56 = cute.get_iter(%div) : !memref_gmem_f32_
    %tile_57 = cute.make_tile() : () -> !cute.tile<"[1:0;1024:1;1:0]">
    %div_58 = cute.zipped_divide(%20, %tile_57) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">, !cute.tile<"[1:0;1024:1;1:0]">
    %iter_59 = cute.get_iter(%div_58) : !cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">
    %e0_60, %e1_61, %e2_62 = cute.get_leaves(%iter_59) : !cute.int_tuple<"(0,0,0)">
    %iter_63 = cute.get_iter(%div_58) : !cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">
    %e0_64, %e1_65, %e2_66 = cute.get_leaves(%iter_63) : !cute.int_tuple<"(0,0,0)">
    %tile_67 = cute.make_tile() : () -> !cute.tile<"[1:0;512:1;1:0]">
    %div_68 = cute.zipped_divide(%view, %tile_67) : !memref_gmem_i8_6, !cute.tile<"[1:0;512:1;1:0]">
    %iter_69 = cute.get_iter(%div_68) : !memref_gmem_i8_
    %iter_70 = cute.get_iter(%div_68) : !memref_gmem_i8_
    %sz_71 = cute.size(%div) <{mode = [1]}> : (!memref_gmem_f32_) -> !cute.int_tuple<"?">
    %e0_72 = cute.get_leaves(%sz_71) : !cute.int_tuple<"?">
    %29 = cute.get_scalars(%e0_72) : !cute.int_tuple<"?">
    %sz_73 = cute.size(%lay_22) <{mode = [0]}> : (!cute.layout<"(128,8):(8,1)">) -> !cute.int_tuple<"128">
    %e0_74 = cute.get_leaves(%sz_73) : !cute.int_tuple<"128">
    %lay_75 = cute.get_layout(%div) : !memref_gmem_f32_
    %30 = cute.get_shape(%lay_75) : (!cute.layout<"((1,1024,1),(?,?,?)):((0,?{i64},0),(?{i64},?{i64 div=1024},1))">) -> !cute.shape<"((1,1024,1),(?,?,?))">
    %e0_76, %e1_77, %e2_78, %e3, %e4, %e5 = cute.get_leaves(%30) : !cute.shape<"((1,1024,1),(?,?,?))">
    %itup_79 = cute.to_int_tuple(%e3) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %31 = cute.get_scalars(%itup_79) : !cute.int_tuple<"?">
    %itup_80 = cute.to_int_tuple(%e4) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %32 = cute.get_scalars(%itup_80) : !cute.int_tuple<"?">
    %itup_81 = cute.to_int_tuple(%e5) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %33 = cute.get_scalars(%itup_81) : !cute.int_tuple<"?">
    %34 = cute.get_stride(%lay_75) : (!cute.layout<"((1,1024,1),(?,?,?)):((0,?{i64},0),(?{i64},?{i64 div=1024},1))">) -> !cute.stride<"((0,?{i64},0),(?{i64},?{i64 div=1024},1))">
    %e0_82, %e1_83, %e2_84, %e3_85, %e4_86, %e5_87 = cute.get_leaves(%34) : !cute.stride<"((0,?{i64},0),(?{i64},?{i64 div=1024},1))">
    %itup_88 = cute.to_int_tuple(%e1_83) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
    %35 = cute.get_scalars(%itup_88) : !cute.int_tuple<"?{i64}">
    %itup_89 = cute.to_int_tuple(%e3_85) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
    %36 = cute.get_scalars(%itup_89) : !cute.int_tuple<"?{i64}">
    %itup_90 = cute.to_int_tuple(%e4_86) : !cute.stride<"?{i64 div=1024}"> to !cute.int_tuple<"?{i64 div=1024}">
    %37 = cute.get_scalars(%itup_90) : !cute.int_tuple<"?{i64 div=1024}">
    %lay_91 = cute.get_layout(%div_68) : !memref_gmem_i8_
    %38 = cute.get_shape(%lay_91) : (!cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !cute.shape<"((1,512,1),(?,?,?))">
    %e0_92, %e1_93, %e2_94, %e3_95, %e4_96, %e5_97 = cute.get_leaves(%38) : !cute.shape<"((1,512,1),(?,?,?))">
    %itup_98 = cute.to_int_tuple(%e3_95) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %39 = cute.get_scalars(%itup_98) : !cute.int_tuple<"?">
    %itup_99 = cute.to_int_tuple(%e4_96) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %40 = cute.get_scalars(%itup_99) : !cute.int_tuple<"?">
    %itup_100 = cute.to_int_tuple(%e5_97) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %41 = cute.get_scalars(%itup_100) : !cute.int_tuple<"?">
    %42 = cute.get_stride(%lay_91) : (!cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !cute.stride<"((0,1,0),(?{i64},512,?{i64}))">
    %e0_101, %e1_102, %e2_103, %e3_104, %e4_105, %e5_106 = cute.get_leaves(%42) : !cute.stride<"((0,1,0),(?{i64},512,?{i64}))">
    %itup_107 = cute.to_int_tuple(%e3_104) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
    %43 = cute.get_scalars(%itup_107) : !cute.int_tuple<"?{i64}">
    %itup_108 = cute.to_int_tuple(%e5_106) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
    %44 = cute.get_scalars(%itup_108) : !cute.int_tuple<"?{i64}">
    %lay_109 = cute.get_layout(%div_58) : !cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">
    %45 = cute.get_shape(%lay_109) : (!cute.layout<"((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">) -> !cute.shape<"((1,1024,1),(?,?,?))">
    %e0_110, %e1_111, %e2_112, %e3_113, %e4_114, %e5_115 = cute.get_leaves(%45) : !cute.shape<"((1,1024,1),(?,?,?))">
    %itup_116 = cute.to_int_tuple(%e3_113) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %46 = cute.get_scalars(%itup_116) : !cute.int_tuple<"?">
    %itup_117 = cute.to_int_tuple(%e4_114) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %47 = cute.get_scalars(%itup_117) : !cute.int_tuple<"?">
    %itup_118 = cute.to_int_tuple(%e5_115) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %48 = cute.get_scalars(%itup_118) : !cute.int_tuple<"?">
    %49 = cute.get_stride(%lay_109) : (!cute.layout<"((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">) -> !cute.stride<"((0,1@1,0),(1@0,1024@1,1@2))">
    %e0_119, %e1_120, %e2_121, %e3_122, %e4_123, %e5_124 = cute.get_leaves(%49) : !cute.stride<"((0,1@1,0),(1@0,1024@1,1@2))">
    %50 = cute.get_shape(%lay_22) : (!cute.layout<"(128,8):(8,1)">) -> !cute.shape<"(128,8)">
    %e0_125, %e1_126 = cute.get_leaves(%50) : !cute.shape<"(128,8)">
    %51 = cute.get_stride(%lay_22) : (!cute.layout<"(128,8):(8,1)">) -> !cute.stride<"(8,1)">
    %e0_127, %e1_128 = cute.get_leaves(%51) : !cute.stride<"(8,1)">
    %52 = cute.get_shape(%14) : (!cute.layout<"(128,4):(4,1)">) -> !cute.shape<"(128,4)">
    %e0_129, %e1_130 = cute.get_leaves(%52) : !cute.shape<"(128,4)">
    %53 = cute.get_stride(%14) : (!cute.layout<"(128,4):(4,1)">) -> !cute.stride<"(4,1)">
    %e0_131, %e1_132 = cute.get_leaves(%53) : !cute.stride<"(4,1)">
    %54 = arith.index_cast %29 : i32 to index
    %c1 = arith.constant 1 : index
    %c128 = arith.constant 128 : index
    %c0_i32 = arith.constant 0 : i32
    gpu.launch_func  @kernels::@kernel_cutlass__convert_kernel_tensorptrf32gmemo11024100div10241_tensorptri8gmemalign16o15121010512_tensor000o1102410110101024112____Float32_Float4E2M1FN_0 blocks in (%54, %c1, %c1) threads in (%c128, %c1, %c1)  dynamic_shared_memory_size %c0_i32 args(%div : !memref_gmem_f32_, %div_68 : !memref_gmem_i8_, %div_58 : !cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">, %17 : i32, %18 : i32, %19 : i32) {use_pdl = false}
    return
  }
}
