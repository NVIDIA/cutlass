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
!memref_rmem_f32_3 = !cute.memref<f32, rmem, align<32>, "(8):(1)">
!memref_rmem_i8_ = !cute.memref<i8, rmem, align<32>, "4:1">
!memref_rmem_i8_1 = !cute.memref<i8, rmem, align<32>, "(4,1):(1,0)">
!memref_rmem_i8_2 = !cute.memref<i8, rmem, align<32>, "(4,(1)):(1,(0))">
!memref_rmem_i8_3 = !cute.memref<i8, rmem, align<32>, "(4):(1)">
#loop_unroll = #llvm.loop_unroll<disable = false, full = true>
#loop_annotation = #llvm.loop_annotation<unroll = #loop_unroll>
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
      %lay_64 = cute.get_layout(%arg0) : !memref_gmem_f32_
      %28:6 = cute.get_scalars(%lay_64) <{only_dynamic}> : !cute.layout<"((1,1024,1),(?,?,?)):((0,?{i64},0),(?{i64},?{i64 div=1024},1))">
      %29 = cute.get_scalars(%coord) <{only_dynamic}> : !cute.coord<"(_,?)">
      %shape = cute.make_shape() : () -> !cute.shape<"((1,1024,1))">
      %stride = cute.make_stride(%28#3) : (i64) -> !cute.stride<"((0,?{i64},0))">
      %lay_65 = cute.make_layout(%shape, %stride) : !cute.layout<"((1,1024,1)):((0,?{i64},0))">
      %idx = cute.crd2idx(%coord, %lay_64) : (!cute.coord<"(_,?)">, !cute.layout<"((1,1024,1),(?,?,?)):((0,?{i64},0),(?{i64},?{i64 div=1024},1))">) -> !cute.int_tuple<"?{i64}">
      %iter_66 = cute.get_iter(%arg0) : !memref_gmem_f32_
      %ptr = cute.add_offset(%iter_66, %idx) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %view = cute.make_view(%ptr, %lay_65) : !memref_gmem_f32_1
      %iter_67 = cute.get_iter(%view) : !memref_gmem_f32_1
      %coord_68 = cute.make_coord(%27) : (i32) -> !cute.coord<"(_,?)">
      %lay_69 = cute.get_layout(%arg1) : !memref_gmem_i8_
      %idx_70 = cute.crd2idx(%coord_68, %lay_69) : (!cute.coord<"(_,?)">, !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !cute.int_tuple<"?{i64}">
      %iter_71 = cute.get_iter(%arg1) : !memref_gmem_i8_
      %ptr_72 = cute.add_offset(%iter_71, %idx_70) : (!cute.ptr<i8, gmem, align<16>>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<i8, gmem>
      %view_73 = cute.make_view(%ptr_72) : !memref_gmem_i8_1
      %iter_74 = cute.get_iter(%view_73) : !memref_gmem_i8_1
      %coord_75 = cute.make_coord(%27) : (i32) -> !cute.coord<"(_,?)">
      %lay_76 = cute.get_layout(%arg2) : !cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">
      %idx_77 = cute.crd2idx(%coord_75, %lay_76) : (!cute.coord<"(_,?)">, !cute.layout<"((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">) -> !cute.int_tuple<"(?,?{div=1024},?)">
      %iter_78 = cute.get_iter(%arg2) : !cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">
      %tup = cute.add_offset(%iter_78, %idx_77) : (!cute.int_tuple<"(0,0,0)">, !cute.int_tuple<"(?,?{div=1024},?)">) -> !cute.int_tuple<"(?,?{div=1024},?)">
      %view_79 = cute.make_view(%tup) : !cute.coord_tensor<"(?,?{div=1024},?)", "((1,1024,1)):((0,1@1,0))">
      %iter_80 = cute.get_iter(%view_79) : !cute.coord_tensor<"(?,?{div=1024},?)", "((1,1024,1)):((0,1@1,0))">
      %e0_81, %e1_82, %e2_83 = cute.get_leaves(%iter_80) : !cute.int_tuple<"(?,?{div=1024},?)">
      %30 = cute.get_scalars(%e0_81) : !cute.int_tuple<"?">
      %31 = cute.get_scalars(%e1_82) : !cute.int_tuple<"?{div=1024}">
      %32 = cute.get_scalars(%e2_83) : !cute.int_tuple<"?">
      %iter_84 = cute.get_iter(%view) : !memref_gmem_f32_1
      %lay_85 = cute.get_layout(%view) : !memref_gmem_f32_1
      %33 = cute.get_scalars(%lay_85) <{only_dynamic}> : !cute.layout<"((1,1024,1)):((0,?{i64},0))">
      %c8_i64 = arith.constant 8 : i64
      %34 = arith.muli %33, %c8_i64 : i64
      %shape_86 = cute.make_shape() : () -> !cute.shape<"(128,8)">
      %iv = cute.assume(%34) : (i64) -> !cute.i64<divby 8>
      %stride_87 = cute.make_stride(%iv, %33) : (!cute.i64<divby 8>, i64) -> !cute.stride<"(?{i64 div=8},?{i64})">
      %lay_88 = cute.make_layout(%shape_86, %stride_87) : !cute.layout<"(128,8):(?{i64 div=8},?{i64})">
      %view_89 = cute.make_view(%iter_84, %lay_88) : !memref_gmem_f32_2
      %iter_90 = cute.get_iter(%view_89) : !memref_gmem_f32_2
      %iter_91 = cute.get_iter(%view_73) : !memref_gmem_i8_1
      %view_92 = cute.make_view(%iter_91) : !memref_gmem_i8_2
      %iter_93 = cute.get_iter(%view_92) : !memref_gmem_i8_2
      %iter_94 = cute.get_iter(%view_79) : !cute.coord_tensor<"(?,?{div=1024},?)", "((1,1024,1)):((0,1@1,0))">
      %view_95 = cute.make_view(%iter_94) : !cute.coord_tensor<"(?,?{div=1024},?)", "(128,8):(8@1,1@1)">
      %iter_96 = cute.get_iter(%view_95) : !cute.coord_tensor<"(?,?{div=1024},?)", "(128,8):(8@1,1@1)">
      %e0_97, %e1_98, %e2_99 = cute.get_leaves(%iter_96) : !cute.int_tuple<"(?,?{div=1024},?)">
      %35 = cute.get_scalars(%e0_97) : !cute.int_tuple<"?">
      %36 = cute.get_scalars(%e1_98) : !cute.int_tuple<"?{div=1024}">
      %37 = cute.get_scalars(%e2_99) : !cute.int_tuple<"?">
      %coord_100 = cute.make_coord(%26) : (i32) -> !cute.coord<"(?,_)">
      %lay_101 = cute.get_layout(%view_89) : !memref_gmem_f32_2
      %38:2 = cute.get_scalars(%lay_101) <{only_dynamic}> : !cute.layout<"(128,8):(?{i64 div=8},?{i64})">
      %39 = cute.get_scalars(%coord_100) <{only_dynamic}> : !cute.coord<"(?,_)">
      %shape_102 = cute.make_shape() : () -> !cute.shape<"(8)">
      %stride_103 = cute.make_stride(%38#1) : (i64) -> !cute.stride<"(?{i64})">
      %lay_104 = cute.make_layout(%shape_102, %stride_103) : !cute.layout<"(8):(?{i64})">
      %idx_105 = cute.crd2idx(%coord_100, %lay_101) : (!cute.coord<"(?,_)">, !cute.layout<"(128,8):(?{i64 div=8},?{i64})">) -> !cute.int_tuple<"?{i64 div=8}">
      %iter_106 = cute.get_iter(%view_89) : !memref_gmem_f32_2
      %ptr_107 = cute.add_offset(%iter_106, %idx_105) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=8}">) -> !cute.ptr<f32, gmem>
      %view_108 = cute.make_view(%ptr_107, %lay_104) : !memref_gmem_f32_3
      %iter_109 = cute.get_iter(%view_108) : !memref_gmem_f32_3
      %coord_110 = cute.make_coord(%26) : (i32) -> !cute.coord<"(?,_)">
      %lay_111 = cute.get_layout(%view_92) : !memref_gmem_i8_2
      %idx_112 = cute.crd2idx(%coord_110, %lay_111) : (!cute.coord<"(?,_)">, !cute.layout<"(128,4):(4,1)">) -> !cute.int_tuple<"?{div=4}">
      %iter_113 = cute.get_iter(%view_92) : !memref_gmem_i8_2
      %ptr_114 = cute.add_offset(%iter_113, %idx_112) : (!cute.ptr<i8, gmem>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<i8, gmem>
      %view_115 = cute.make_view(%ptr_114) : !memref_gmem_i8_3
      %iter_116 = cute.get_iter(%view_115) : !memref_gmem_i8_3
      %coord_117 = cute.make_coord(%26) : (i32) -> !cute.coord<"(?,_)">
      %lay_118 = cute.get_layout(%view_95) : !cute.coord_tensor<"(?,?{div=1024},?)", "(128,8):(8@1,1@1)">
      %idx_119 = cute.crd2idx(%coord_117, %lay_118) : (!cute.coord<"(?,_)">, !cute.layout<"(128,8):(8@1,1@1)">) -> !cute.int_tuple<"(0,?{div=8})">
      %iter_120 = cute.get_iter(%view_95) : !cute.coord_tensor<"(?,?{div=1024},?)", "(128,8):(8@1,1@1)">
      %tup_121 = cute.add_offset(%iter_120, %idx_119) : (!cute.int_tuple<"(?,?{div=1024},?)">, !cute.int_tuple<"(0,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8},?)">
      %view_122 = cute.make_view(%tup_121) : !cute.coord_tensor<"(?,?{div=8},?)", "(8):(1@1)">
      %iter_123 = cute.get_iter(%view_122) : !cute.coord_tensor<"(?,?{div=8},?)", "(8):(1@1)">
      %e0_124, %e1_125, %e2_126 = cute.get_leaves(%iter_123) : !cute.int_tuple<"(?,?{div=8},?)">
      %40 = cute.get_scalars(%e0_124) : !cute.int_tuple<"?">
      %41 = cute.get_scalars(%e1_125) : !cute.int_tuple<"?{div=8}">
      %42 = cute.get_scalars(%e2_126) : !cute.int_tuple<"?">
      %coord_127 = cute.make_coord() : () -> !cute.coord<"0">
      %lay_128 = cute.get_layout(%view_122) : !cute.coord_tensor<"(?,?{div=8},?)", "(8):(1@1)">
      %idx_129 = cute.crd2idx(%coord_127, %lay_128) : (!cute.coord<"0">, !cute.layout<"(8):(1@1)">) -> !cute.int_tuple<"(0,0)">
      %iter_130 = cute.get_iter(%view_122) : !cute.coord_tensor<"(?,?{div=8},?)", "(8):(1@1)">
      %tup_131 = cute.add_offset(%iter_130, %idx_129) : (!cute.int_tuple<"(?,?{div=8},?)">, !cute.int_tuple<"(0,0)">) -> !cute.int_tuple<"(?,?{div=8},?)">
      %view_132 = cute.make_view(%tup_131) : !cute.coord_tensor<"(?,?{div=8},?)", "():()">
      %iter_133 = cute.get_iter(%view_132) : !cute.coord_tensor<"(?,?{div=8},?)", "():()">
      %e0_134, %e1_135, %e2_136 = cute.get_leaves(%iter_133) : !cute.int_tuple<"(?,?{div=8},?)">
      %43 = cute.get_scalars(%e0_134) : !cute.int_tuple<"?">
      %44 = cute.get_scalars(%e1_135) : !cute.int_tuple<"?{div=8}">
      %45 = cute.get_scalars(%e2_136) : !cute.int_tuple<"?">
      %iter_137 = cute.get_iter(%view_132) : !cute.coord_tensor<"(?,?{div=8},?)", "():()">
      %e0_138, %e1_139, %e2_140 = cute.get_leaves(%iter_137) : !cute.int_tuple<"(?,?{div=8},?)">
      %46 = cute.get_scalars(%e0_138) : !cute.int_tuple<"?">
      %47 = cute.get_scalars(%e1_139) : !cute.int_tuple<"?{div=8}">
      %48 = cute.get_scalars(%e2_140) : !cute.int_tuple<"?">
      %iter_141 = cute.get_iter(%view_132) : !cute.coord_tensor<"(?,?{div=8},?)", "():()">
      %e0_142, %e1_143, %e2_144 = cute.get_leaves(%iter_141) : !cute.int_tuple<"(?,?{div=8},?)">
      %49 = cute.get_scalars(%e0_142) : !cute.int_tuple<"?">
      %50 = cute.get_scalars(%e1_143) : !cute.int_tuple<"?{div=8}">
      %51 = cute.get_scalars(%e2_144) : !cute.int_tuple<"?">
      %coord_145 = cute.make_coord(%e0_142, %e1_143, %e2_144) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?{div=8},?)">
      %coord_146 = cute.make_coord(%arg3, %arg4, %arg5) : (i32, i32, i32) -> !cute.coord<"(?,?,?)">
      %52:3 = cute.get_scalars(%coord_145) : !cute.coord<"(?,?{div=8},?)">
      %53:3 = cute.get_scalars(%coord_146) : !cute.coord<"(?,?,?)">
      %true = arith.constant true
      %54 = arith.cmpi slt, %52#0, %53#0 : i32
      %55 = arith.andi %true, %54 : i1
      %56 = arith.cmpi slt, %52#1, %53#1 : i32
      %57 = arith.andi %55, %56 : i1
      %58 = arith.cmpi slt, %52#2, %53#2 : i32
      %59 = arith.andi %57, %58 : i1
      scf.if %59 {
        %60 = cute.get_shape(%0) : (!cute.layout<"(128,8):(8,1)">) -> !cute.shape<"(128,8)">
        %e0_147, %e1_148 = cute.get_leaves(%60) : !cute.shape<"(128,8)">
        %61 = cute.get_shape(%0) : (!cute.layout<"(128,8):(8,1)">) -> !cute.shape<"(128,8)">
        %e0_149, %e1_150 = cute.get_leaves(%61) : !cute.shape<"(128,8)">
        %lay_151 = cute.make_layout() : !cute.layout<"8:1">
        %rmem = cute.memref.alloca(%lay_151) : !memref_rmem_f32_
        %iter_152 = cute.get_iter(%rmem) : !memref_rmem_f32_
        %iter_153 = cute.get_iter(%rmem) : !memref_rmem_f32_
        %62 = cute.get_shape(%1) : (!cute.layout<"(128,4):(4,1)">) -> !cute.shape<"(128,4)">
        %e0_154, %e1_155 = cute.get_leaves(%62) : !cute.shape<"(128,4)">
        %63 = cute.get_shape(%1) : (!cute.layout<"(128,4):(4,1)">) -> !cute.shape<"(128,4)">
        %e0_156, %e1_157 = cute.get_leaves(%63) : !cute.shape<"(128,4)">
        %lay_158 = cute.make_layout() : !cute.layout<"4:1">
        %rmem_159 = cute.memref.alloca(%lay_158) : !memref_rmem_i8_
        %iter_160 = cute.get_iter(%rmem_159) : !memref_rmem_i8_
        %iter_161 = cute.get_iter(%rmem_159) : !memref_rmem_i8_
        %atom = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<f32>
        %lay_162 = cute.get_layout(%view_108) : !memref_gmem_f32_3
        %64 = cute.get_shape(%lay_162) : (!cute.layout<"(8):(?{i64})">) -> !cute.shape<"(8)">
        %e0_163 = cute.get_leaves(%64) : !cute.shape<"(8)">
        %lay_164 = cute.get_layout(%rmem) : !memref_rmem_f32_
        %65 = cute.get_shape(%lay_164) : (!cute.layout<"8:1">) -> !cute.shape<"8">
        %e0_165 = cute.get_leaves(%65) : !cute.shape<"8">
        %lay_166 = cute.get_layout(%view_108) : !memref_gmem_f32_3
        %shape_167 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_168 = cute.make_layout() : !cute.layout<"1:0">
        %append = cute.append_to_rank<2> (%lay_166, %lay_168) : !cute.layout<"(8):(?{i64})">, !cute.layout<"1:0">
        %view_169 = cute.make_view(%iter_109, %append) : !memref_gmem_f32_4
        %iter_170 = cute.get_iter(%view_169) : !memref_gmem_f32_4
        %lay_171 = cute.get_layout(%view_169) : !memref_gmem_f32_4
        %66 = cute.get_shape(%lay_171) : (!cute.layout<"(8,1):(?{i64},0)">) -> !cute.shape<"(8,1)">
        %e0_172, %e1_173 = cute.get_leaves(%66) : !cute.shape<"(8,1)">
        %iter_174 = cute.get_iter(%view_169) : !memref_gmem_f32_4
        %lay_175 = cute.get_layout(%view_169) : !memref_gmem_f32_4
        %67 = cute.get_scalars(%lay_175) <{only_dynamic}> : !cute.layout<"(8,1):(?{i64},0)">
        %shape_176 = cute.make_shape() : () -> !cute.shape<"(8,(1))">
        %stride_177 = cute.make_stride(%67) : (i64) -> !cute.stride<"(?{i64},(0))">
        %lay_178 = cute.make_layout(%shape_176, %stride_177) : !cute.layout<"(8,(1)):(?{i64},(0))">
        %view_179 = cute.make_view(%iter_174, %lay_178) : !memref_gmem_f32_5
        %iter_180 = cute.get_iter(%view_179) : !memref_gmem_f32_5
        %iter_181 = cute.get_iter(%view_179) : !memref_gmem_f32_5
        %lay_182 = cute.get_layout(%rmem) : !memref_rmem_f32_
        %shape_183 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_184 = cute.make_layout() : !cute.layout<"1:0">
        %append_185 = cute.append_to_rank<2> (%lay_182, %lay_184) : !cute.layout<"8:1">, !cute.layout<"1:0">
        %view_186 = cute.make_view(%iter_153, %append_185) : !memref_rmem_f32_1
        %iter_187 = cute.get_iter(%view_186) : !memref_rmem_f32_1
        %lay_188 = cute.get_layout(%view_186) : !memref_rmem_f32_1
        %68 = cute.get_shape(%lay_188) : (!cute.layout<"(8,1):(1,0)">) -> !cute.shape<"(8,1)">
        %e0_189, %e1_190 = cute.get_leaves(%68) : !cute.shape<"(8,1)">
        %iter_191 = cute.get_iter(%view_186) : !memref_rmem_f32_1
        %view_192 = cute.make_view(%iter_191) : !memref_rmem_f32_2
        %iter_193 = cute.get_iter(%view_192) : !memref_rmem_f32_2
        %iter_194 = cute.get_iter(%view_192) : !memref_rmem_f32_2
        %lay_195 = cute.get_layout(%view_179) : !memref_gmem_f32_5
        %69 = cute.get_shape(%lay_195) : (!cute.layout<"(8,(1)):(?{i64},(0))">) -> !cute.shape<"(8,(1))">
        %e0_196, %e1_197 = cute.get_leaves(%69) : !cute.shape<"(8,(1))">
        %lay_198 = cute.get_layout(%view_192) : !memref_rmem_f32_2
        %70 = cute.get_shape(%lay_198) : (!cute.layout<"(8,(1)):(1,(0))">) -> !cute.shape<"(8,(1))">
        %e0_199, %e1_200 = cute.get_leaves(%70) : !cute.shape<"(8,(1))">
        %lay_201 = cute.get_layout(%view_179) : !memref_gmem_f32_5
        %sz = cute.size(%lay_201) <{mode = [1]}> : (!cute.layout<"(8,(1)):(?{i64},(0))">) -> !cute.int_tuple<"1">
        %e0_202 = cute.get_leaves(%sz) : !cute.int_tuple<"1">
        %lay_203 = cute.get_layout(%view_192) : !memref_rmem_f32_2
        %sz_204 = cute.size(%lay_203) <{mode = [1]}> : (!cute.layout<"(8,(1)):(1,(0))">) -> !cute.int_tuple<"1">
        %e0_205 = cute.get_leaves(%sz_204) : !cute.int_tuple<"1">
        %71 = cute.static : !cute.layout<"1:0">
        %iter_206 = cute.get_iter(%view_179) : !memref_gmem_f32_5
        %iter_207 = cute.get_iter(%view_192) : !memref_rmem_f32_2
        %lay_208 = cute.get_layout(%view_179) : !memref_gmem_f32_5
        %lay_209 = cute.get_layout(%view_192) : !memref_rmem_f32_2
        %append_210 = cute.append_to_rank<2> (%lay_208, %71) : !cute.layout<"(8,(1)):(?{i64},(0))">, !cute.layout<"1:0">
        %append_211 = cute.append_to_rank<2> (%lay_209, %71) : !cute.layout<"(8,(1)):(1,(0))">, !cute.layout<"1:0">
        %72 = cute.get_scalars(%append_210) <{only_dynamic}> : !cute.layout<"(8,(1)):(?{i64},(0))">
        %shape_212 = cute.make_shape() : () -> !cute.shape<"(8,((1)))">
        %stride_213 = cute.make_stride(%72) : (i64) -> !cute.stride<"(?{i64},((0)))">
        %lay_214 = cute.make_layout(%shape_212, %stride_213) : !cute.layout<"(8,((1))):(?{i64},((0)))">
        %lay_215 = cute.make_layout() : !cute.layout<"(8,((1))):(1,((0)))">
        %sz_216 = cute.size(%lay_214) <{mode = [1]}> : (!cute.layout<"(8,((1))):(?{i64},((0)))">) -> !cute.int_tuple<"1">
        %73 = cute.get_scalars(%sz_216) : !cute.int_tuple<"1">
        %c0_i32 = arith.constant 0 : i32
        %c1_i32 = arith.constant 1 : i32
        scf.for %arg6 = %c0_i32 to %73 step %c1_i32  : i32 {
          %coord_279 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
          %88 = cute.get_scalars(%lay_214) <{only_dynamic}> : !cute.layout<"(8,((1))):(?{i64},((0)))">
          %89 = cute.get_scalars(%coord_279) <{only_dynamic}> : !cute.coord<"(_,?)">
          %shape_280 = cute.make_shape() : () -> !cute.shape<"(8)">
          %stride_281 = cute.make_stride(%88) : (i64) -> !cute.stride<"(?{i64})">
          %lay_282 = cute.make_layout(%shape_280, %stride_281) : !cute.layout<"(8):(?{i64})">
          %idx_283 = cute.crd2idx(%coord_279, %lay_214) : (!cute.coord<"(_,?)">, !cute.layout<"(8,((1))):(?{i64},((0)))">) -> !cute.int_tuple<"0">
          %ptr_284 = cute.add_offset(%iter_206, %idx_283) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<f32, gmem>
          %view_285 = cute.make_view(%ptr_284, %lay_282) : !memref_gmem_f32_3
          %90 = cute.get_scalars(%coord_279) <{only_dynamic}> : !cute.coord<"(_,?)">
          %lay_286 = cute.make_layout() : !cute.layout<"(8):(1)">
          %idx_287 = cute.crd2idx(%coord_279, %lay_215) : (!cute.coord<"(_,?)">, !cute.layout<"(8,((1))):(1,((0)))">) -> !cute.int_tuple<"0">
          %ptr_288 = cute.add_offset(%iter_207, %idx_287) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, rmem, align<32>>
          %view_289 = cute.make_view(%ptr_288, %lay_286) : !memref_rmem_f32_3
          %iter_290 = cute.get_iter(%view_285) : !memref_gmem_f32_3
          %lay_291 = cute.get_layout(%view_285) : !memref_gmem_f32_3
          %91 = cute.get_scalars(%lay_291) <{only_dynamic}> : !cute.layout<"(8):(?{i64})">
          %iter_292 = cute.get_iter(%view_289) : !memref_rmem_f32_3
          %92 = builtin.unrealized_conversion_cast %iter_290 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %93 = builtin.unrealized_conversion_cast %iter_292 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
          %94 = llvm.load %92 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %94, %93 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          %int_tuple_293 = cute.make_int_tuple(%91) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_294 = cute.add_offset(%iter_290, %int_tuple_293) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %int_tuple_295 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
          %ptr_296 = cute.add_offset(%iter_292, %int_tuple_295) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
          %95 = builtin.unrealized_conversion_cast %ptr_294 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %96 = builtin.unrealized_conversion_cast %ptr_296 : !cute.ptr<f32, rmem> to !llvm.ptr
          %97 = llvm.load %95 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %97, %96 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          %c2_i64 = arith.constant 2 : i64
          %98 = arith.muli %91, %c2_i64 : i64
          %iv_297 = cute.assume(%98) : (i64) -> !cute.i64<divby 2>
          %int_tuple_298 = cute.make_int_tuple(%iv_297) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
          %ptr_299 = cute.add_offset(%iter_290, %int_tuple_298) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
          %int_tuple_300 = cute.make_int_tuple() : () -> !cute.int_tuple<"2">
          %ptr_301 = cute.add_offset(%iter_292, %int_tuple_300) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
          %99 = builtin.unrealized_conversion_cast %ptr_299 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %100 = builtin.unrealized_conversion_cast %ptr_301 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %101 = llvm.load %99 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %101, %100 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          %c3_i64 = arith.constant 3 : i64
          %102 = arith.muli %91, %c3_i64 : i64
          %iv_302 = cute.assume(%102) : (i64) -> !cute.i64<divby 3>
          %int_tuple_303 = cute.make_int_tuple(%iv_302) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
          %ptr_304 = cute.add_offset(%iter_290, %int_tuple_303) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
          %int_tuple_305 = cute.make_int_tuple() : () -> !cute.int_tuple<"3">
          %ptr_306 = cute.add_offset(%iter_292, %int_tuple_305) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
          %103 = builtin.unrealized_conversion_cast %ptr_304 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %104 = builtin.unrealized_conversion_cast %ptr_306 : !cute.ptr<f32, rmem> to !llvm.ptr
          %105 = llvm.load %103 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %105, %104 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          %c4_i64 = arith.constant 4 : i64
          %106 = arith.muli %91, %c4_i64 : i64
          %iv_307 = cute.assume(%106) : (i64) -> !cute.i64<divby 4>
          %int_tuple_308 = cute.make_int_tuple(%iv_307) : (!cute.i64<divby 4>) -> !cute.int_tuple<"?{i64 div=4}">
          %ptr_309 = cute.add_offset(%iter_290, %int_tuple_308) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=4}">) -> !cute.ptr<f32, gmem>
          %int_tuple_310 = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
          %ptr_311 = cute.add_offset(%iter_292, %int_tuple_310) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
          %107 = builtin.unrealized_conversion_cast %ptr_309 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %108 = builtin.unrealized_conversion_cast %ptr_311 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
          %109 = llvm.load %107 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %109, %108 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          %c5_i64 = arith.constant 5 : i64
          %110 = arith.muli %91, %c5_i64 : i64
          %iv_312 = cute.assume(%110) : (i64) -> !cute.i64<divby 5>
          %int_tuple_313 = cute.make_int_tuple(%iv_312) : (!cute.i64<divby 5>) -> !cute.int_tuple<"?{i64 div=5}">
          %ptr_314 = cute.add_offset(%iter_290, %int_tuple_313) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=5}">) -> !cute.ptr<f32, gmem>
          %int_tuple_315 = cute.make_int_tuple() : () -> !cute.int_tuple<"5">
          %ptr_316 = cute.add_offset(%iter_292, %int_tuple_315) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<f32, rmem>
          %111 = builtin.unrealized_conversion_cast %ptr_314 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %112 = builtin.unrealized_conversion_cast %ptr_316 : !cute.ptr<f32, rmem> to !llvm.ptr
          %113 = llvm.load %111 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %113, %112 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          %c6_i64 = arith.constant 6 : i64
          %114 = arith.muli %91, %c6_i64 : i64
          %iv_317 = cute.assume(%114) : (i64) -> !cute.i64<divby 6>
          %int_tuple_318 = cute.make_int_tuple(%iv_317) : (!cute.i64<divby 6>) -> !cute.int_tuple<"?{i64 div=6}">
          %ptr_319 = cute.add_offset(%iter_290, %int_tuple_318) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=6}">) -> !cute.ptr<f32, gmem>
          %int_tuple_320 = cute.make_int_tuple() : () -> !cute.int_tuple<"6">
          %ptr_321 = cute.add_offset(%iter_292, %int_tuple_320) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
          %115 = builtin.unrealized_conversion_cast %ptr_319 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %116 = builtin.unrealized_conversion_cast %ptr_321 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %117 = llvm.load %115 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %117, %116 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          %c7_i64 = arith.constant 7 : i64
          %118 = arith.muli %91, %c7_i64 : i64
          %iv_322 = cute.assume(%118) : (i64) -> !cute.i64<divby 7>
          %int_tuple_323 = cute.make_int_tuple(%iv_322) : (!cute.i64<divby 7>) -> !cute.int_tuple<"?{i64 div=7}">
          %ptr_324 = cute.add_offset(%iter_290, %int_tuple_323) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=7}">) -> !cute.ptr<f32, gmem>
          %int_tuple_325 = cute.make_int_tuple() : () -> !cute.int_tuple<"7">
          %ptr_326 = cute.add_offset(%iter_292, %int_tuple_325) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<f32, rmem>
          %119 = builtin.unrealized_conversion_cast %ptr_324 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %120 = builtin.unrealized_conversion_cast %ptr_326 : !cute.ptr<f32, rmem> to !llvm.ptr
          %121 = llvm.load %119 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %121, %120 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %74 = cute.memref.load_vec %rmem, row_major : !memref_rmem_f32_
        %75 = nvgpu.cvt_fptrunc %74 : vector<8xf32> to vector<8xf4E2M1FN>
        %shape_217 = cute.make_shape() : () -> !cute.shape<"8">
        %lay_218 = cute.make_layout() : !cute.layout<"8:1">
        %76 = cute.recast_layout<8, 4> (%lay_218) : !cute.layout<"8:1"> to !cute.layout<"4:1">
        %77 = cute.get_shape(%76) : (!cute.layout<"4:1">) -> !cute.shape<"4">
        %e0_219 = cute.get_leaves(%77) : !cute.shape<"4">
        %78 = builtin.unrealized_conversion_cast %75 : vector<8xf4E2M1FN> to vector<8xi4>
        %79 = vector.bitcast %78 : vector<8xi4> to vector<4xi8>
        %lay_220 = cute.get_layout(%rmem_159) : !memref_rmem_i8_
        %80 = cute.get_shape(%lay_220) : (!cute.layout<"4:1">) -> !cute.shape<"4">
        %e0_221 = cute.get_leaves(%80) : !cute.shape<"4">
        %int_tuple = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
        %sz_222 = cute.size(%int_tuple) : (!cute.int_tuple<"4">) -> !cute.int_tuple<"4">
        %e0_223 = cute.get_leaves(%sz_222) : !cute.int_tuple<"4">
        %int_tuple_224 = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
        %sz_225 = cute.size(%int_tuple_224) : (!cute.int_tuple<"4">) -> !cute.int_tuple<"4">
        %e0_226 = cute.get_leaves(%sz_225) : !cute.int_tuple<"4">
        cute.memref.store_vec %79, %rmem_159, row_major : !memref_rmem_i8_
        %atom_227 = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<i8>
        %lay_228 = cute.get_layout(%view_115) : !memref_gmem_i8_3
        %81 = cute.get_shape(%lay_228) : (!cute.layout<"(4):(1)">) -> !cute.shape<"(4)">
        %e0_229 = cute.get_leaves(%81) : !cute.shape<"(4)">
        %lay_230 = cute.get_layout(%rmem_159) : !memref_rmem_i8_
        %shape_231 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_232 = cute.make_layout() : !cute.layout<"1:0">
        %append_233 = cute.append_to_rank<2> (%lay_230, %lay_232) : !cute.layout<"4:1">, !cute.layout<"1:0">
        %view_234 = cute.make_view(%iter_161, %append_233) : !memref_rmem_i8_1
        %iter_235 = cute.get_iter(%view_234) : !memref_rmem_i8_1
        %lay_236 = cute.get_layout(%view_234) : !memref_rmem_i8_1
        %82 = cute.get_shape(%lay_236) : (!cute.layout<"(4,1):(1,0)">) -> !cute.shape<"(4,1)">
        %e0_237, %e1_238 = cute.get_leaves(%82) : !cute.shape<"(4,1)">
        %iter_239 = cute.get_iter(%view_234) : !memref_rmem_i8_1
        %view_240 = cute.make_view(%iter_239) : !memref_rmem_i8_2
        %iter_241 = cute.get_iter(%view_240) : !memref_rmem_i8_2
        %iter_242 = cute.get_iter(%view_240) : !memref_rmem_i8_2
        %lay_243 = cute.get_layout(%view_115) : !memref_gmem_i8_3
        %shape_244 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_245 = cute.make_layout() : !cute.layout<"1:0">
        %append_246 = cute.append_to_rank<2> (%lay_243, %lay_245) : !cute.layout<"(4):(1)">, !cute.layout<"1:0">
        %view_247 = cute.make_view(%iter_116, %append_246) : !memref_gmem_i8_4
        %iter_248 = cute.get_iter(%view_247) : !memref_gmem_i8_4
        %lay_249 = cute.get_layout(%view_247) : !memref_gmem_i8_4
        %83 = cute.get_shape(%lay_249) : (!cute.layout<"(4,1):(1,0)">) -> !cute.shape<"(4,1)">
        %e0_250, %e1_251 = cute.get_leaves(%83) : !cute.shape<"(4,1)">
        %iter_252 = cute.get_iter(%view_247) : !memref_gmem_i8_4
        %view_253 = cute.make_view(%iter_252) : !memref_gmem_i8_5
        %iter_254 = cute.get_iter(%view_253) : !memref_gmem_i8_5
        %iter_255 = cute.get_iter(%view_253) : !memref_gmem_i8_5
        %lay_256 = cute.get_layout(%view_240) : !memref_rmem_i8_2
        %84 = cute.get_shape(%lay_256) : (!cute.layout<"(4,(1)):(1,(0))">) -> !cute.shape<"(4,(1))">
        %e0_257, %e1_258 = cute.get_leaves(%84) : !cute.shape<"(4,(1))">
        %lay_259 = cute.get_layout(%view_253) : !memref_gmem_i8_5
        %85 = cute.get_shape(%lay_259) : (!cute.layout<"(4,(1)):(1,(0))">) -> !cute.shape<"(4,(1))">
        %e0_260, %e1_261 = cute.get_leaves(%85) : !cute.shape<"(4,(1))">
        %lay_262 = cute.get_layout(%view_240) : !memref_rmem_i8_2
        %sz_263 = cute.size(%lay_262) <{mode = [1]}> : (!cute.layout<"(4,(1)):(1,(0))">) -> !cute.int_tuple<"1">
        %e0_264 = cute.get_leaves(%sz_263) : !cute.int_tuple<"1">
        %lay_265 = cute.get_layout(%view_253) : !memref_gmem_i8_5
        %sz_266 = cute.size(%lay_265) <{mode = [1]}> : (!cute.layout<"(4,(1)):(1,(0))">) -> !cute.int_tuple<"1">
        %e0_267 = cute.get_leaves(%sz_266) : !cute.int_tuple<"1">
        %86 = cute.static : !cute.layout<"1:0">
        %iter_268 = cute.get_iter(%view_240) : !memref_rmem_i8_2
        %iter_269 = cute.get_iter(%view_253) : !memref_gmem_i8_5
        %lay_270 = cute.get_layout(%view_240) : !memref_rmem_i8_2
        %lay_271 = cute.get_layout(%view_253) : !memref_gmem_i8_5
        %append_272 = cute.append_to_rank<2> (%lay_270, %86) : !cute.layout<"(4,(1)):(1,(0))">, !cute.layout<"1:0">
        %append_273 = cute.append_to_rank<2> (%lay_271, %86) : !cute.layout<"(4,(1)):(1,(0))">, !cute.layout<"1:0">
        %lay_274 = cute.make_layout() : !cute.layout<"(4,((1))):(1,((0)))">
        %lay_275 = cute.make_layout() : !cute.layout<"(4,((1))):(1,((0)))">
        %sz_276 = cute.size(%lay_274) <{mode = [1]}> : (!cute.layout<"(4,((1))):(1,((0)))">) -> !cute.int_tuple<"1">
        %87 = cute.get_scalars(%sz_276) : !cute.int_tuple<"1">
        %c0_i32_277 = arith.constant 0 : i32
        %c1_i32_278 = arith.constant 1 : i32
        scf.for %arg6 = %c0_i32_277 to %87 step %c1_i32_278  : i32 {
          %coord_279 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
          %88 = cute.get_scalars(%coord_279) <{only_dynamic}> : !cute.coord<"(_,?)">
          %lay_280 = cute.make_layout() : !cute.layout<"(4):(1)">
          %idx_281 = cute.crd2idx(%coord_279, %lay_274) : (!cute.coord<"(_,?)">, !cute.layout<"(4,((1))):(1,((0)))">) -> !cute.int_tuple<"0">
          %ptr_282 = cute.add_offset(%iter_268, %idx_281) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
          %view_283 = cute.make_view(%ptr_282, %lay_280) : !memref_rmem_i8_3
          %89 = cute.get_scalars(%coord_279) <{only_dynamic}> : !cute.coord<"(_,?)">
          %lay_284 = cute.make_layout() : !cute.layout<"(4):(1)">
          %idx_285 = cute.crd2idx(%coord_279, %lay_275) : (!cute.coord<"(_,?)">, !cute.layout<"(4,((1))):(1,((0)))">) -> !cute.int_tuple<"0">
          %ptr_286 = cute.add_offset(%iter_269, %idx_285) : (!cute.ptr<i8, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<i8, gmem>
          %view_287 = cute.make_view(%ptr_286, %lay_284) : !memref_gmem_i8_3
          %iter_288 = cute.get_iter(%view_283) : !memref_rmem_i8_3
          %iter_289 = cute.get_iter(%view_287) : !memref_gmem_i8_3
          %90 = builtin.unrealized_conversion_cast %iter_288 : !cute.ptr<i8, rmem, align<32>> to !llvm.ptr
          %91 = builtin.unrealized_conversion_cast %iter_289 : !cute.ptr<i8, gmem> to !llvm.ptr<1>
          %92 = llvm.load %90 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
          llvm.store %92, %91 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
          %int_tuple_290 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
          %ptr_291 = cute.add_offset(%iter_288, %int_tuple_290) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
          %int_tuple_292 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
          %ptr_293 = cute.add_offset(%iter_289, %int_tuple_292) : (!cute.ptr<i8, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<i8, gmem>
          %93 = builtin.unrealized_conversion_cast %ptr_291 : !cute.ptr<i8, rmem> to !llvm.ptr
          %94 = builtin.unrealized_conversion_cast %ptr_293 : !cute.ptr<i8, gmem> to !llvm.ptr<1>
          %95 = llvm.load %93 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
          llvm.store %95, %94 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
          %int_tuple_294 = cute.make_int_tuple() : () -> !cute.int_tuple<"2">
          %ptr_295 = cute.add_offset(%iter_288, %int_tuple_294) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem, align<2>>
          %int_tuple_296 = cute.make_int_tuple() : () -> !cute.int_tuple<"2">
          %ptr_297 = cute.add_offset(%iter_289, %int_tuple_296) : (!cute.ptr<i8, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<i8, gmem>
          %96 = builtin.unrealized_conversion_cast %ptr_295 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
          %97 = builtin.unrealized_conversion_cast %ptr_297 : !cute.ptr<i8, gmem> to !llvm.ptr<1>
          %98 = llvm.load %96 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
          llvm.store %98, %97 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
          %int_tuple_298 = cute.make_int_tuple() : () -> !cute.int_tuple<"3">
          %ptr_299 = cute.add_offset(%iter_288, %int_tuple_298) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
          %int_tuple_300 = cute.make_int_tuple() : () -> !cute.int_tuple<"3">
          %ptr_301 = cute.add_offset(%iter_289, %int_tuple_300) : (!cute.ptr<i8, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<i8, gmem>
          %99 = builtin.unrealized_conversion_cast %ptr_299 : !cute.ptr<i8, rmem> to !llvm.ptr
          %100 = builtin.unrealized_conversion_cast %ptr_301 : !cute.ptr<i8, gmem> to !llvm.ptr<1>
          %101 = llvm.load %99 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
          llvm.store %101, %100 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
        } {llvm.loop_annotation = #loop_annotation}
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
    %lay_22 = cute.make_layout() : !cute.layout<"(128,8):(8,1)">
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
    %int_tuple = cute.make_int_tuple() : () -> !cute.int_tuple<"(0,0,0)">
    %stride_34 = cute.make_stride() : () -> !cute.stride<"(1@0,1@1,1@2)">
    %lay_35 = cute.make_layout(%shape_33, %stride_34) : !cute.layout<"(?,?,?):(1@0,1@1,1@2)">
    %view_36 = cute.make_view(%int_tuple, %lay_35) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">
    %iter_37 = cute.get_iter(%view_36) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">
    %e0_38, %e1_39, %e2_40 = cute.get_leaves(%iter_37) : !cute.int_tuple<"(0,0,0)">
    %lay_41 = cute.get_layout(%arg0) : !memref_gmem_f32_6
    %20 = cute.get_shape(%lay_41) : (!cute.layout<"(?,?,?):(?{i64},?{i64},1)">) -> !cute.shape<"(?,?,?)">
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
    %28:5 = cute.get_scalars(%lay_59) <{only_dynamic}> : !cute.layout<"(?,?,?):(?{i64},?{i64},1)">
    %c1024_i32 = arith.constant 1024 : i32
    %29 = arith.ceildivsi %28#1, %c1024_i32 : i32
    %c1024_i64 = arith.constant 1024 : i64
    %30 = arith.muli %28#4, %c1024_i64 : i64
    %shape_60 = cute.make_shape(%28#0, %29, %28#2) : (i32, i32, i32) -> !cute.shape<"((1,1024,1),(?,?,?))">
    %iv = cute.assume(%30) : (i64) -> !cute.i64<divby 1024>
    %stride_61 = cute.make_stride(%28#4, %28#3, %iv) : (i64, i64, !cute.i64<divby 1024>) -> !cute.stride<"((0,?{i64},0),(?{i64},?{i64 div=1024},1))">
    %lay_62 = cute.make_layout(%shape_60, %stride_61) : !cute.layout<"((1,1024,1),(?,?,?)):((0,?{i64},0),(?{i64},?{i64 div=1024},1))">
    %view_63 = cute.make_view(%iter_58, %lay_62) : !memref_gmem_f32_
    %iter_64 = cute.get_iter(%view_63) : !memref_gmem_f32_
    %iter_65 = cute.get_iter(%view_63) : !memref_gmem_f32_
    %tile_66 = cute.make_tile() : () -> !cute.tile<"[1:0;1024:1;1:0]">
    %iter_67 = cute.get_iter(%view_36) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">
    %lay_68 = cute.get_layout(%view_36) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">
    %31:3 = cute.get_scalars(%lay_68) <{only_dynamic}> : !cute.layout<"(?,?,?):(1@0,1@1,1@2)">
    %c1024_i32_69 = arith.constant 1024 : i32
    %32 = arith.ceildivsi %31#1, %c1024_i32_69 : i32
    %shape_70 = cute.make_shape(%31#0, %32, %31#2) : (i32, i32, i32) -> !cute.shape<"((1,1024,1),(?,?,?))">
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
    %33:5 = cute.get_scalars(%lay_84) <{only_dynamic}> : !cute.layout<"(?,?,?):(?{i64},1,?{i64})">
    %c512_i32 = arith.constant 512 : i32
    %34 = arith.ceildivsi %33#1, %c512_i32 : i32
    %shape_85 = cute.make_shape(%33#0, %34, %33#2) : (i32, i32, i32) -> !cute.shape<"((1,512,1),(?,?,?))">
    %stride_86 = cute.make_stride(%33#3, %33#4) : (i64, i64) -> !cute.stride<"((0,1,0),(?{i64},512,?{i64}))">
    %lay_87 = cute.make_layout(%shape_85, %stride_86) : !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">
    %view_88 = cute.make_view(%iter_83, %lay_87) : !memref_gmem_i8_
    %iter_89 = cute.get_iter(%view_88) : !memref_gmem_i8_
    %iter_90 = cute.get_iter(%view_88) : !memref_gmem_i8_
    %lay_91 = cute.get_layout(%view_63) : !memref_gmem_f32_
    %sz_92 = cute.size(%lay_91) <{mode = [1]}> : (!cute.layout<"((1,1024,1),(?,?,?)):((0,?{i64},0),(?{i64},?{i64 div=1024},1))">) -> !cute.int_tuple<"?">
    %e0_93 = cute.get_leaves(%sz_92) : !cute.int_tuple<"?">
    %35 = cute.get_scalars(%e0_93) : !cute.int_tuple<"?">
    %sz_94 = cute.size(%lay_22) <{mode = [0]}> : (!cute.layout<"(128,8):(8,1)">) -> !cute.int_tuple<"128">
    %e0_95 = cute.get_leaves(%sz_94) : !cute.int_tuple<"128">
    %lay_96 = cute.get_layout(%view_63) : !memref_gmem_f32_
    %36 = cute.get_shape(%lay_96) : (!cute.layout<"((1,1024,1),(?,?,?)):((0,?{i64},0),(?{i64},?{i64 div=1024},1))">) -> !cute.shape<"((1,1024,1),(?,?,?))">
    %e0_97, %e1_98, %e2_99, %e3, %e4, %e5 = cute.get_leaves(%36) : !cute.shape<"((1,1024,1),(?,?,?))">
    %itup_100 = cute.to_int_tuple(%e3) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %37 = cute.get_scalars(%itup_100) : !cute.int_tuple<"?">
    %itup_101 = cute.to_int_tuple(%e4) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %38 = cute.get_scalars(%itup_101) : !cute.int_tuple<"?">
    %itup_102 = cute.to_int_tuple(%e5) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %39 = cute.get_scalars(%itup_102) : !cute.int_tuple<"?">
    %40 = cute.get_stride(%lay_96) : (!cute.layout<"((1,1024,1),(?,?,?)):((0,?{i64},0),(?{i64},?{i64 div=1024},1))">) -> !cute.stride<"((0,?{i64},0),(?{i64},?{i64 div=1024},1))">
    %e0_103, %e1_104, %e2_105, %e3_106, %e4_107, %e5_108 = cute.get_leaves(%40) : !cute.stride<"((0,?{i64},0),(?{i64},?{i64 div=1024},1))">
    %itup_109 = cute.to_int_tuple(%e1_104) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
    %41 = cute.get_scalars(%itup_109) : !cute.int_tuple<"?{i64}">
    %itup_110 = cute.to_int_tuple(%e3_106) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
    %42 = cute.get_scalars(%itup_110) : !cute.int_tuple<"?{i64}">
    %itup_111 = cute.to_int_tuple(%e4_107) : !cute.stride<"?{i64 div=1024}"> to !cute.int_tuple<"?{i64 div=1024}">
    %43 = cute.get_scalars(%itup_111) : !cute.int_tuple<"?{i64 div=1024}">
    %lay_112 = cute.get_layout(%view_88) : !memref_gmem_i8_
    %44 = cute.get_shape(%lay_112) : (!cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !cute.shape<"((1,512,1),(?,?,?))">
    %e0_113, %e1_114, %e2_115, %e3_116, %e4_117, %e5_118 = cute.get_leaves(%44) : !cute.shape<"((1,512,1),(?,?,?))">
    %itup_119 = cute.to_int_tuple(%e3_116) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %45 = cute.get_scalars(%itup_119) : !cute.int_tuple<"?">
    %itup_120 = cute.to_int_tuple(%e4_117) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %46 = cute.get_scalars(%itup_120) : !cute.int_tuple<"?">
    %itup_121 = cute.to_int_tuple(%e5_118) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %47 = cute.get_scalars(%itup_121) : !cute.int_tuple<"?">
    %48 = cute.get_stride(%lay_112) : (!cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !cute.stride<"((0,1,0),(?{i64},512,?{i64}))">
    %e0_122, %e1_123, %e2_124, %e3_125, %e4_126, %e5_127 = cute.get_leaves(%48) : !cute.stride<"((0,1,0),(?{i64},512,?{i64}))">
    %itup_128 = cute.to_int_tuple(%e3_125) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
    %49 = cute.get_scalars(%itup_128) : !cute.int_tuple<"?{i64}">
    %itup_129 = cute.to_int_tuple(%e5_127) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
    %50 = cute.get_scalars(%itup_129) : !cute.int_tuple<"?{i64}">
    %lay_130 = cute.get_layout(%view_73) : !cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">
    %51 = cute.get_shape(%lay_130) : (!cute.layout<"((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">) -> !cute.shape<"((1,1024,1),(?,?,?))">
    %e0_131, %e1_132, %e2_133, %e3_134, %e4_135, %e5_136 = cute.get_leaves(%51) : !cute.shape<"((1,1024,1),(?,?,?))">
    %itup_137 = cute.to_int_tuple(%e3_134) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %52 = cute.get_scalars(%itup_137) : !cute.int_tuple<"?">
    %itup_138 = cute.to_int_tuple(%e4_135) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %53 = cute.get_scalars(%itup_138) : !cute.int_tuple<"?">
    %itup_139 = cute.to_int_tuple(%e5_136) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %54 = cute.get_scalars(%itup_139) : !cute.int_tuple<"?">
    %55 = cute.get_stride(%lay_130) : (!cute.layout<"((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">) -> !cute.stride<"((0,1@1,0),(1@0,1024@1,1@2))">
    %e0_140, %e1_141, %e2_142, %e3_143, %e4_144, %e5_145 = cute.get_leaves(%55) : !cute.stride<"((0,1@1,0),(1@0,1024@1,1@2))">
    %56 = cute.get_shape(%lay_22) : (!cute.layout<"(128,8):(8,1)">) -> !cute.shape<"(128,8)">
    %e0_146, %e1_147 = cute.get_leaves(%56) : !cute.shape<"(128,8)">
    %57 = cute.get_stride(%lay_22) : (!cute.layout<"(128,8):(8,1)">) -> !cute.stride<"(8,1)">
    %e0_148, %e1_149 = cute.get_leaves(%57) : !cute.stride<"(8,1)">
    %58 = cute.get_shape(%14) : (!cute.layout<"(128,4):(4,1)">) -> !cute.shape<"(128,4)">
    %e0_150, %e1_151 = cute.get_leaves(%58) : !cute.shape<"(128,4)">
    %59 = cute.get_stride(%14) : (!cute.layout<"(128,4):(4,1)">) -> !cute.stride<"(4,1)">
    %e0_152, %e1_153 = cute.get_leaves(%59) : !cute.stride<"(4,1)">
    %60 = arith.index_cast %35 : i32 to index
    %c1 = arith.constant 1 : index
    %c128 = arith.constant 128 : index
    %c0_i32 = arith.constant 0 : i32
    gpu.launch_func  @kernels::@kernel_cutlass__convert_kernel_tensorptrf32gmemo11024100div10241_tensorptri8gmemalign16o15121010512_tensor000o1102410110101024112____Float32_Float4E2M1FN_0 blocks in (%60, %c1, %c1) threads in (%c128, %c1, %c1)  dynamic_shared_memory_size %c0_i32 args(%view_63 : !memref_gmem_f32_, %view_88 : !memref_gmem_i8_, %view_73 : !cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">, %17 : i32, %18 : i32, %19 : i32) {use_pdl = false}
    return
  }
}
