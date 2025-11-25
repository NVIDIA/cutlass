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
      %slice = cute.slice(%lay_64, %coord) : !cute.layout<"((1,1024,1),(?,?,?)):((0,?{i64},0),(?{i64},?{i64 div=1024},1))">, !cute.coord<"(_,?)">
      %idx = cute.crd2idx(%coord, %lay_64) : (!cute.coord<"(_,?)">, !cute.layout<"((1,1024,1),(?,?,?)):((0,?{i64},0),(?{i64},?{i64 div=1024},1))">) -> !cute.int_tuple<"?{i64}">
      %iter_65 = cute.get_iter(%arg0) : !memref_gmem_f32_
      %ptr = cute.add_offset(%iter_65, %idx) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %view = cute.make_view(%ptr, %slice) : !memref_gmem_f32_1
      %iter_66 = cute.get_iter(%view) : !memref_gmem_f32_1
      %coord_67 = cute.make_coord(%27) : (i32) -> !cute.coord<"(_,?)">
      %lay_68 = cute.get_layout(%arg1) : !memref_gmem_i8_
      %idx_69 = cute.crd2idx(%coord_67, %lay_68) : (!cute.coord<"(_,?)">, !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !cute.int_tuple<"?{i64}">
      %iter_70 = cute.get_iter(%arg1) : !memref_gmem_i8_
      %ptr_71 = cute.add_offset(%iter_70, %idx_69) : (!cute.ptr<i8, gmem, align<16>>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<i8, gmem>
      %view_72 = cute.make_view(%ptr_71) : !memref_gmem_i8_1
      %iter_73 = cute.get_iter(%view_72) : !memref_gmem_i8_1
      %coord_74 = cute.make_coord(%27) : (i32) -> !cute.coord<"(_,?)">
      %lay_75 = cute.get_layout(%arg2) : !cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">
      %idx_76 = cute.crd2idx(%coord_74, %lay_75) : (!cute.coord<"(_,?)">, !cute.layout<"((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">) -> !cute.int_tuple<"(?,?{div=1024},?)">
      %iter_77 = cute.get_iter(%arg2) : !cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">
      %tup = cute.add_offset(%iter_77, %idx_76) : (!cute.int_tuple<"(0,0,0)">, !cute.int_tuple<"(?,?{div=1024},?)">) -> !cute.int_tuple<"(?,?{div=1024},?)">
      %view_78 = cute.make_view(%tup) : !cute.coord_tensor<"(?,?{div=1024},?)", "((1,1024,1)):((0,1@1,0))">
      %iter_79 = cute.get_iter(%view_78) : !cute.coord_tensor<"(?,?{div=1024},?)", "((1,1024,1)):((0,1@1,0))">
      %e0_80, %e1_81, %e2_82 = cute.get_leaves(%iter_79) : !cute.int_tuple<"(?,?{div=1024},?)">
      %28 = cute.get_scalars(%e0_80) : !cute.int_tuple<"?">
      %29 = cute.get_scalars(%e1_81) : !cute.int_tuple<"?{div=1024}">
      %30 = cute.get_scalars(%e2_82) : !cute.int_tuple<"?">
      %iter_83 = cute.get_iter(%view) : !memref_gmem_f32_1
      %lay_84 = cute.get_layout(%view) : !memref_gmem_f32_1
      %31 = cute.get_scalars(%lay_84) <{only_dynamic}> : !cute.layout<"((1,1024,1)):((0,?{i64},0))">
      %c8_i64 = arith.constant 8 : i64
      %32 = arith.muli %31, %c8_i64 : i64
      %shape = cute.make_shape() : () -> !cute.shape<"(128,8)">
      %iv = cute.assume(%32) : (i64) -> !cute.i64<divby 8>
      %stride = cute.make_stride(%iv, %31) : (!cute.i64<divby 8>, i64) -> !cute.stride<"(?{i64 div=8},?{i64})">
      %lay_85 = cute.make_layout(%shape, %stride) : !cute.layout<"(128,8):(?{i64 div=8},?{i64})">
      %view_86 = cute.make_view(%iter_83, %lay_85) : !memref_gmem_f32_2
      %iter_87 = cute.get_iter(%view_86) : !memref_gmem_f32_2
      %iter_88 = cute.get_iter(%view_72) : !memref_gmem_i8_1
      %view_89 = cute.make_view(%iter_88) : !memref_gmem_i8_2
      %iter_90 = cute.get_iter(%view_89) : !memref_gmem_i8_2
      %iter_91 = cute.get_iter(%view_78) : !cute.coord_tensor<"(?,?{div=1024},?)", "((1,1024,1)):((0,1@1,0))">
      %view_92 = cute.make_view(%iter_91) : !cute.coord_tensor<"(?,?{div=1024},?)", "(128,8):(8@1,1@1)">
      %iter_93 = cute.get_iter(%view_92) : !cute.coord_tensor<"(?,?{div=1024},?)", "(128,8):(8@1,1@1)">
      %e0_94, %e1_95, %e2_96 = cute.get_leaves(%iter_93) : !cute.int_tuple<"(?,?{div=1024},?)">
      %33 = cute.get_scalars(%e0_94) : !cute.int_tuple<"?">
      %34 = cute.get_scalars(%e1_95) : !cute.int_tuple<"?{div=1024}">
      %35 = cute.get_scalars(%e2_96) : !cute.int_tuple<"?">
      %coord_97 = cute.make_coord(%26) : (i32) -> !cute.coord<"(?,_)">
      %lay_98 = cute.get_layout(%view_86) : !memref_gmem_f32_2
      %slice_99 = cute.slice(%lay_98, %coord_97) : !cute.layout<"(128,8):(?{i64 div=8},?{i64})">, !cute.coord<"(?,_)">
      %idx_100 = cute.crd2idx(%coord_97, %lay_98) : (!cute.coord<"(?,_)">, !cute.layout<"(128,8):(?{i64 div=8},?{i64})">) -> !cute.int_tuple<"?{i64 div=8}">
      %iter_101 = cute.get_iter(%view_86) : !memref_gmem_f32_2
      %ptr_102 = cute.add_offset(%iter_101, %idx_100) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=8}">) -> !cute.ptr<f32, gmem>
      %view_103 = cute.make_view(%ptr_102, %slice_99) : !memref_gmem_f32_3
      %iter_104 = cute.get_iter(%view_103) : !memref_gmem_f32_3
      %coord_105 = cute.make_coord(%26) : (i32) -> !cute.coord<"(?,_)">
      %lay_106 = cute.get_layout(%view_89) : !memref_gmem_i8_2
      %idx_107 = cute.crd2idx(%coord_105, %lay_106) : (!cute.coord<"(?,_)">, !cute.layout<"(128,4):(4,1)">) -> !cute.int_tuple<"?{div=4}">
      %iter_108 = cute.get_iter(%view_89) : !memref_gmem_i8_2
      %ptr_109 = cute.add_offset(%iter_108, %idx_107) : (!cute.ptr<i8, gmem>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<i8, gmem>
      %view_110 = cute.make_view(%ptr_109) : !memref_gmem_i8_3
      %iter_111 = cute.get_iter(%view_110) : !memref_gmem_i8_3
      %coord_112 = cute.make_coord(%26) : (i32) -> !cute.coord<"(?,_)">
      %lay_113 = cute.get_layout(%view_92) : !cute.coord_tensor<"(?,?{div=1024},?)", "(128,8):(8@1,1@1)">
      %idx_114 = cute.crd2idx(%coord_112, %lay_113) : (!cute.coord<"(?,_)">, !cute.layout<"(128,8):(8@1,1@1)">) -> !cute.int_tuple<"(0,?{div=8})">
      %iter_115 = cute.get_iter(%view_92) : !cute.coord_tensor<"(?,?{div=1024},?)", "(128,8):(8@1,1@1)">
      %tup_116 = cute.add_offset(%iter_115, %idx_114) : (!cute.int_tuple<"(?,?{div=1024},?)">, !cute.int_tuple<"(0,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8},?)">
      %view_117 = cute.make_view(%tup_116) : !cute.coord_tensor<"(?,?{div=8},?)", "(8):(1@1)">
      %iter_118 = cute.get_iter(%view_117) : !cute.coord_tensor<"(?,?{div=8},?)", "(8):(1@1)">
      %e0_119, %e1_120, %e2_121 = cute.get_leaves(%iter_118) : !cute.int_tuple<"(?,?{div=8},?)">
      %36 = cute.get_scalars(%e0_119) : !cute.int_tuple<"?">
      %37 = cute.get_scalars(%e1_120) : !cute.int_tuple<"?{div=8}">
      %38 = cute.get_scalars(%e2_121) : !cute.int_tuple<"?">
      %coord_122 = cute.make_coord() : () -> !cute.coord<"0">
      %lay_123 = cute.get_layout(%view_117) : !cute.coord_tensor<"(?,?{div=8},?)", "(8):(1@1)">
      %idx_124 = cute.crd2idx(%coord_122, %lay_123) : (!cute.coord<"0">, !cute.layout<"(8):(1@1)">) -> !cute.int_tuple<"(0,0)">
      %iter_125 = cute.get_iter(%view_117) : !cute.coord_tensor<"(?,?{div=8},?)", "(8):(1@1)">
      %tup_126 = cute.add_offset(%iter_125, %idx_124) : (!cute.int_tuple<"(?,?{div=8},?)">, !cute.int_tuple<"(0,0)">) -> !cute.int_tuple<"(?,?{div=8},?)">
      %view_127 = cute.make_view(%tup_126) : !cute.coord_tensor<"(?,?{div=8},?)", "():()">
      %iter_128 = cute.get_iter(%view_127) : !cute.coord_tensor<"(?,?{div=8},?)", "():()">
      %e0_129, %e1_130, %e2_131 = cute.get_leaves(%iter_128) : !cute.int_tuple<"(?,?{div=8},?)">
      %39 = cute.get_scalars(%e0_129) : !cute.int_tuple<"?">
      %40 = cute.get_scalars(%e1_130) : !cute.int_tuple<"?{div=8}">
      %41 = cute.get_scalars(%e2_131) : !cute.int_tuple<"?">
      %iter_132 = cute.get_iter(%view_127) : !cute.coord_tensor<"(?,?{div=8},?)", "():()">
      %e0_133, %e1_134, %e2_135 = cute.get_leaves(%iter_132) : !cute.int_tuple<"(?,?{div=8},?)">
      %42 = cute.get_scalars(%e0_133) : !cute.int_tuple<"?">
      %43 = cute.get_scalars(%e1_134) : !cute.int_tuple<"?{div=8}">
      %44 = cute.get_scalars(%e2_135) : !cute.int_tuple<"?">
      %iter_136 = cute.get_iter(%view_127) : !cute.coord_tensor<"(?,?{div=8},?)", "():()">
      %e0_137, %e1_138, %e2_139 = cute.get_leaves(%iter_136) : !cute.int_tuple<"(?,?{div=8},?)">
      %45 = cute.get_scalars(%e0_137) : !cute.int_tuple<"?">
      %46 = cute.get_scalars(%e1_138) : !cute.int_tuple<"?{div=8}">
      %47 = cute.get_scalars(%e2_139) : !cute.int_tuple<"?">
      %coord_140 = cute.make_coord(%e0_137, %e1_138, %e2_139) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?{div=8},?)">
      %coord_141 = cute.make_coord(%arg3, %arg4, %arg5) : (i32, i32, i32) -> !cute.coord<"(?,?,?)">
      %48 = cute.elem_less(%coord_140, %coord_141) : !cute.coord<"(?,?{div=8},?)">, !cute.coord<"(?,?,?)">
      scf.if %48 {
        %49 = cute.get_shape(%0) : (!cute.layout<"(128,8):(8,1)">) -> !cute.shape<"(128,8)">
        %e0_142, %e1_143 = cute.get_leaves(%49) : !cute.shape<"(128,8)">
        %50 = cute.get_shape(%0) : (!cute.layout<"(128,8):(8,1)">) -> !cute.shape<"(128,8)">
        %e0_144, %e1_145 = cute.get_leaves(%50) : !cute.shape<"(128,8)">
        %51 = cute.get(%0) <{mode = [1]}> : !cute.layout<"(128,8):(8,1)"> -> !cute.layout<"8:1">
        %rmem = cute.memref.alloca(%51) : !memref_rmem_f32_
        %iter_146 = cute.get_iter(%rmem) : !memref_rmem_f32_
        %iter_147 = cute.get_iter(%rmem) : !memref_rmem_f32_
        %52 = cute.get_shape(%1) : (!cute.layout<"(128,4):(4,1)">) -> !cute.shape<"(128,4)">
        %e0_148, %e1_149 = cute.get_leaves(%52) : !cute.shape<"(128,4)">
        %53 = cute.get_shape(%1) : (!cute.layout<"(128,4):(4,1)">) -> !cute.shape<"(128,4)">
        %e0_150, %e1_151 = cute.get_leaves(%53) : !cute.shape<"(128,4)">
        %54 = cute.get(%1) <{mode = [1]}> : !cute.layout<"(128,4):(4,1)"> -> !cute.layout<"4:1">
        %rmem_152 = cute.memref.alloca(%54) : !memref_rmem_i8_
        %iter_153 = cute.get_iter(%rmem_152) : !memref_rmem_i8_
        %iter_154 = cute.get_iter(%rmem_152) : !memref_rmem_i8_
        %atom = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<f32>
        %lay_155 = cute.get_layout(%view_103) : !memref_gmem_f32_3
        %55 = cute.get_shape(%lay_155) : (!cute.layout<"(8):(?{i64})">) -> !cute.shape<"(8)">
        %e0_156 = cute.get_leaves(%55) : !cute.shape<"(8)">
        %lay_157 = cute.get_layout(%rmem) : !memref_rmem_f32_
        %56 = cute.get_shape(%lay_157) : (!cute.layout<"8:1">) -> !cute.shape<"8">
        %e0_158 = cute.get_leaves(%56) : !cute.shape<"8">
        %lay_159 = cute.get_layout(%view_103) : !memref_gmem_f32_3
        %shape_160 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_161 = cute.make_layout() : !cute.layout<"1:0">
        %append = cute.append_to_rank<2> (%lay_159, %lay_161) : !cute.layout<"(8):(?{i64})">, !cute.layout<"1:0">
        %view_162 = cute.make_view(%iter_104, %append) : !memref_gmem_f32_4
        %iter_163 = cute.get_iter(%view_162) : !memref_gmem_f32_4
        %lay_164 = cute.get_layout(%view_162) : !memref_gmem_f32_4
        %57 = cute.get_shape(%lay_164) : (!cute.layout<"(8,1):(?{i64},0)">) -> !cute.shape<"(8,1)">
        %e0_165, %e1_166 = cute.get_leaves(%57) : !cute.shape<"(8,1)">
        %iter_167 = cute.get_iter(%view_162) : !memref_gmem_f32_4
        %lay_168 = cute.get_layout(%view_162) : !memref_gmem_f32_4
        %58 = cute.get_scalars(%lay_168) <{only_dynamic}> : !cute.layout<"(8,1):(?{i64},0)">
        %shape_169 = cute.make_shape() : () -> !cute.shape<"(8,(1))">
        %stride_170 = cute.make_stride(%58) : (i64) -> !cute.stride<"(?{i64},(0))">
        %lay_171 = cute.make_layout(%shape_169, %stride_170) : !cute.layout<"(8,(1)):(?{i64},(0))">
        %view_172 = cute.make_view(%iter_167, %lay_171) : !memref_gmem_f32_5
        %iter_173 = cute.get_iter(%view_172) : !memref_gmem_f32_5
        %iter_174 = cute.get_iter(%view_172) : !memref_gmem_f32_5
        %lay_175 = cute.get_layout(%rmem) : !memref_rmem_f32_
        %shape_176 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_177 = cute.make_layout() : !cute.layout<"1:0">
        %append_178 = cute.append_to_rank<2> (%lay_175, %lay_177) : !cute.layout<"8:1">, !cute.layout<"1:0">
        %view_179 = cute.make_view(%iter_147, %append_178) : !memref_rmem_f32_1
        %iter_180 = cute.get_iter(%view_179) : !memref_rmem_f32_1
        %lay_181 = cute.get_layout(%view_179) : !memref_rmem_f32_1
        %59 = cute.get_shape(%lay_181) : (!cute.layout<"(8,1):(1,0)">) -> !cute.shape<"(8,1)">
        %e0_182, %e1_183 = cute.get_leaves(%59) : !cute.shape<"(8,1)">
        %iter_184 = cute.get_iter(%view_179) : !memref_rmem_f32_1
        %view_185 = cute.make_view(%iter_184) : !memref_rmem_f32_2
        %iter_186 = cute.get_iter(%view_185) : !memref_rmem_f32_2
        %iter_187 = cute.get_iter(%view_185) : !memref_rmem_f32_2
        %lay_188 = cute.get_layout(%view_172) : !memref_gmem_f32_5
        %60 = cute.get_shape(%lay_188) : (!cute.layout<"(8,(1)):(?{i64},(0))">) -> !cute.shape<"(8,(1))">
        %e0_189, %e1_190 = cute.get_leaves(%60) : !cute.shape<"(8,(1))">
        %lay_191 = cute.get_layout(%view_185) : !memref_rmem_f32_2
        %61 = cute.get_shape(%lay_191) : (!cute.layout<"(8,(1)):(1,(0))">) -> !cute.shape<"(8,(1))">
        %e0_192, %e1_193 = cute.get_leaves(%61) : !cute.shape<"(8,(1))">
        %lay_194 = cute.get_layout(%view_172) : !memref_gmem_f32_5
        %sz = cute.size(%lay_194) <{mode = [1]}> : (!cute.layout<"(8,(1)):(?{i64},(0))">) -> !cute.int_tuple<"1">
        %e0_195 = cute.get_leaves(%sz) : !cute.int_tuple<"1">
        %lay_196 = cute.get_layout(%view_185) : !memref_rmem_f32_2
        %sz_197 = cute.size(%lay_196) <{mode = [1]}> : (!cute.layout<"(8,(1)):(1,(0))">) -> !cute.int_tuple<"1">
        %e0_198 = cute.get_leaves(%sz_197) : !cute.int_tuple<"1">
        %62 = cute.static : !cute.layout<"1:0">
        %iter_199 = cute.get_iter(%view_172) : !memref_gmem_f32_5
        %iter_200 = cute.get_iter(%view_185) : !memref_rmem_f32_2
        %lay_201 = cute.get_layout(%view_172) : !memref_gmem_f32_5
        %lay_202 = cute.get_layout(%view_185) : !memref_rmem_f32_2
        %append_203 = cute.append_to_rank<2> (%lay_201, %62) : !cute.layout<"(8,(1)):(?{i64},(0))">, !cute.layout<"1:0">
        %append_204 = cute.append_to_rank<2> (%lay_202, %62) : !cute.layout<"(8,(1)):(1,(0))">, !cute.layout<"1:0">
        %63 = cute.get_scalars(%append_203) <{only_dynamic}> : !cute.layout<"(8,(1)):(?{i64},(0))">
        %shape_205 = cute.make_shape() : () -> !cute.shape<"(8,((1)))">
        %stride_206 = cute.make_stride(%63) : (i64) -> !cute.stride<"(?{i64},((0)))">
        %lay_207 = cute.make_layout(%shape_205, %stride_206) : !cute.layout<"(8,((1))):(?{i64},((0)))">
        %lay_208 = cute.make_layout() : !cute.layout<"(8,((1))):(1,((0)))">
        %sz_209 = cute.size(%lay_207) <{mode = [1]}> : (!cute.layout<"(8,((1))):(?{i64},((0)))">) -> !cute.int_tuple<"1">
        %64 = cute.get_scalars(%sz_209) : !cute.int_tuple<"1">
        %c0_i32 = arith.constant 0 : i32
        %c1_i32 = arith.constant 1 : i32
        scf.for %arg6 = %c0_i32 to %64 step %c1_i32  : i32 {
          %coord_272 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
          %slice_273 = cute.slice(%lay_207, %coord_272) : !cute.layout<"(8,((1))):(?{i64},((0)))">, !cute.coord<"(_,?)">
          %idx_274 = cute.crd2idx(%coord_272, %lay_207) : (!cute.coord<"(_,?)">, !cute.layout<"(8,((1))):(?{i64},((0)))">) -> !cute.int_tuple<"0">
          %ptr_275 = cute.add_offset(%iter_199, %idx_274) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<f32, gmem>
          %view_276 = cute.make_view(%ptr_275, %slice_273) : !memref_gmem_f32_3
          %slice_277 = cute.slice(%lay_208, %coord_272) : !cute.layout<"(8,((1))):(1,((0)))">, !cute.coord<"(_,?)">
          %idx_278 = cute.crd2idx(%coord_272, %lay_208) : (!cute.coord<"(_,?)">, !cute.layout<"(8,((1))):(1,((0)))">) -> !cute.int_tuple<"0">
          %ptr_279 = cute.add_offset(%iter_200, %idx_278) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, rmem, align<32>>
          %view_280 = cute.make_view(%ptr_279, %slice_277) : !memref_rmem_f32_3
          cute.copy_atom_call(%atom, %view_276, %view_280) : (!cute_nvgpu.atom.universal_copy<f32>, !memref_gmem_f32_3, !memref_rmem_f32_3) -> ()
        } {llvm.loop_annotation = #loop_annotation}
        %65 = cute.memref.load_vec %rmem, row_major : !memref_rmem_f32_
        %66 = nvgpu.cvt_fptrunc %65 : vector<8xf32> to vector<8xf4E2M1FN>
        %shape_210 = cute.make_shape() : () -> !cute.shape<"8">
        %lay_211 = cute.make_layout() : !cute.layout<"8:1">
        %67 = cute.recast_layout<8, 4> (%lay_211) : !cute.layout<"8:1"> to !cute.layout<"4:1">
        %68 = cute.get_shape(%67) : (!cute.layout<"4:1">) -> !cute.shape<"4">
        %e0_212 = cute.get_leaves(%68) : !cute.shape<"4">
        %69 = builtin.unrealized_conversion_cast %66 : vector<8xf4E2M1FN> to vector<8xi4>
        %70 = vector.bitcast %69 : vector<8xi4> to vector<4xi8>
        %lay_213 = cute.get_layout(%rmem_152) : !memref_rmem_i8_
        %71 = cute.get_shape(%lay_213) : (!cute.layout<"4:1">) -> !cute.shape<"4">
        %e0_214 = cute.get_leaves(%71) : !cute.shape<"4">
        %int_tuple = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
        %sz_215 = cute.size(%int_tuple) : (!cute.int_tuple<"4">) -> !cute.int_tuple<"4">
        %e0_216 = cute.get_leaves(%sz_215) : !cute.int_tuple<"4">
        %int_tuple_217 = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
        %sz_218 = cute.size(%int_tuple_217) : (!cute.int_tuple<"4">) -> !cute.int_tuple<"4">
        %e0_219 = cute.get_leaves(%sz_218) : !cute.int_tuple<"4">
        cute.memref.store_vec %70, %rmem_152, row_major : !memref_rmem_i8_
        %atom_220 = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<i8>
        %lay_221 = cute.get_layout(%view_110) : !memref_gmem_i8_3
        %72 = cute.get_shape(%lay_221) : (!cute.layout<"(4):(1)">) -> !cute.shape<"(4)">
        %e0_222 = cute.get_leaves(%72) : !cute.shape<"(4)">
        %lay_223 = cute.get_layout(%rmem_152) : !memref_rmem_i8_
        %shape_224 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_225 = cute.make_layout() : !cute.layout<"1:0">
        %append_226 = cute.append_to_rank<2> (%lay_223, %lay_225) : !cute.layout<"4:1">, !cute.layout<"1:0">
        %view_227 = cute.make_view(%iter_154, %append_226) : !memref_rmem_i8_1
        %iter_228 = cute.get_iter(%view_227) : !memref_rmem_i8_1
        %lay_229 = cute.get_layout(%view_227) : !memref_rmem_i8_1
        %73 = cute.get_shape(%lay_229) : (!cute.layout<"(4,1):(1,0)">) -> !cute.shape<"(4,1)">
        %e0_230, %e1_231 = cute.get_leaves(%73) : !cute.shape<"(4,1)">
        %iter_232 = cute.get_iter(%view_227) : !memref_rmem_i8_1
        %view_233 = cute.make_view(%iter_232) : !memref_rmem_i8_2
        %iter_234 = cute.get_iter(%view_233) : !memref_rmem_i8_2
        %iter_235 = cute.get_iter(%view_233) : !memref_rmem_i8_2
        %lay_236 = cute.get_layout(%view_110) : !memref_gmem_i8_3
        %shape_237 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_238 = cute.make_layout() : !cute.layout<"1:0">
        %append_239 = cute.append_to_rank<2> (%lay_236, %lay_238) : !cute.layout<"(4):(1)">, !cute.layout<"1:0">
        %view_240 = cute.make_view(%iter_111, %append_239) : !memref_gmem_i8_4
        %iter_241 = cute.get_iter(%view_240) : !memref_gmem_i8_4
        %lay_242 = cute.get_layout(%view_240) : !memref_gmem_i8_4
        %74 = cute.get_shape(%lay_242) : (!cute.layout<"(4,1):(1,0)">) -> !cute.shape<"(4,1)">
        %e0_243, %e1_244 = cute.get_leaves(%74) : !cute.shape<"(4,1)">
        %iter_245 = cute.get_iter(%view_240) : !memref_gmem_i8_4
        %view_246 = cute.make_view(%iter_245) : !memref_gmem_i8_5
        %iter_247 = cute.get_iter(%view_246) : !memref_gmem_i8_5
        %iter_248 = cute.get_iter(%view_246) : !memref_gmem_i8_5
        %lay_249 = cute.get_layout(%view_233) : !memref_rmem_i8_2
        %75 = cute.get_shape(%lay_249) : (!cute.layout<"(4,(1)):(1,(0))">) -> !cute.shape<"(4,(1))">
        %e0_250, %e1_251 = cute.get_leaves(%75) : !cute.shape<"(4,(1))">
        %lay_252 = cute.get_layout(%view_246) : !memref_gmem_i8_5
        %76 = cute.get_shape(%lay_252) : (!cute.layout<"(4,(1)):(1,(0))">) -> !cute.shape<"(4,(1))">
        %e0_253, %e1_254 = cute.get_leaves(%76) : !cute.shape<"(4,(1))">
        %lay_255 = cute.get_layout(%view_233) : !memref_rmem_i8_2
        %sz_256 = cute.size(%lay_255) <{mode = [1]}> : (!cute.layout<"(4,(1)):(1,(0))">) -> !cute.int_tuple<"1">
        %e0_257 = cute.get_leaves(%sz_256) : !cute.int_tuple<"1">
        %lay_258 = cute.get_layout(%view_246) : !memref_gmem_i8_5
        %sz_259 = cute.size(%lay_258) <{mode = [1]}> : (!cute.layout<"(4,(1)):(1,(0))">) -> !cute.int_tuple<"1">
        %e0_260 = cute.get_leaves(%sz_259) : !cute.int_tuple<"1">
        %77 = cute.static : !cute.layout<"1:0">
        %iter_261 = cute.get_iter(%view_233) : !memref_rmem_i8_2
        %iter_262 = cute.get_iter(%view_246) : !memref_gmem_i8_5
        %lay_263 = cute.get_layout(%view_233) : !memref_rmem_i8_2
        %lay_264 = cute.get_layout(%view_246) : !memref_gmem_i8_5
        %append_265 = cute.append_to_rank<2> (%lay_263, %77) : !cute.layout<"(4,(1)):(1,(0))">, !cute.layout<"1:0">
        %append_266 = cute.append_to_rank<2> (%lay_264, %77) : !cute.layout<"(4,(1)):(1,(0))">, !cute.layout<"1:0">
        %lay_267 = cute.make_layout() : !cute.layout<"(4,((1))):(1,((0)))">
        %lay_268 = cute.make_layout() : !cute.layout<"(4,((1))):(1,((0)))">
        %sz_269 = cute.size(%lay_267) <{mode = [1]}> : (!cute.layout<"(4,((1))):(1,((0)))">) -> !cute.int_tuple<"1">
        %78 = cute.get_scalars(%sz_269) : !cute.int_tuple<"1">
        %c0_i32_270 = arith.constant 0 : i32
        %c1_i32_271 = arith.constant 1 : i32
        scf.for %arg6 = %c0_i32_270 to %78 step %c1_i32_271  : i32 {
          %coord_272 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
          %slice_273 = cute.slice(%lay_267, %coord_272) : !cute.layout<"(4,((1))):(1,((0)))">, !cute.coord<"(_,?)">
          %idx_274 = cute.crd2idx(%coord_272, %lay_267) : (!cute.coord<"(_,?)">, !cute.layout<"(4,((1))):(1,((0)))">) -> !cute.int_tuple<"0">
          %ptr_275 = cute.add_offset(%iter_261, %idx_274) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
          %view_276 = cute.make_view(%ptr_275, %slice_273) : !memref_rmem_i8_3
          %slice_277 = cute.slice(%lay_268, %coord_272) : !cute.layout<"(4,((1))):(1,((0)))">, !cute.coord<"(_,?)">
          %idx_278 = cute.crd2idx(%coord_272, %lay_268) : (!cute.coord<"(_,?)">, !cute.layout<"(4,((1))):(1,((0)))">) -> !cute.int_tuple<"0">
          %ptr_279 = cute.add_offset(%iter_262, %idx_278) : (!cute.ptr<i8, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<i8, gmem>
          %view_280 = cute.make_view(%ptr_279, %slice_277) : !memref_gmem_i8_3
          cute.copy_atom_call(%atom_220, %view_276, %view_280) : (!cute_nvgpu.atom.universal_copy<i8>, !memref_rmem_i8_3, !memref_gmem_i8_3) -> ()
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
    %iter_55 = cute.get_iter(%arg0) : !memref_gmem_f32_6
    %lay_56 = cute.get_layout(%arg0) : !memref_gmem_f32_6
    %29:5 = cute.get_scalars(%lay_56) <{only_dynamic}> : !cute.layout<"(?,?,?):(?{i64},?{i64},1)">
    %c1024_i32 = arith.constant 1024 : i32
    %30 = arith.ceildivsi %29#1, %c1024_i32 : i32
    %c1024_i64 = arith.constant 1024 : i64
    %31 = arith.muli %29#4, %c1024_i64 : i64
    %shape_57 = cute.make_shape(%29#0, %30, %29#2) : (i32, i32, i32) -> !cute.shape<"((1,1024,1),(?,?,?))">
    %iv = cute.assume(%31) : (i64) -> !cute.i64<divby 1024>
    %stride_58 = cute.make_stride(%29#4, %29#3, %iv) : (i64, i64, !cute.i64<divby 1024>) -> !cute.stride<"((0,?{i64},0),(?{i64},?{i64 div=1024},1))">
    %lay_59 = cute.make_layout(%shape_57, %stride_58) : !cute.layout<"((1,1024,1),(?,?,?)):((0,?{i64},0),(?{i64},?{i64 div=1024},1))">
    %view_60 = cute.make_view(%iter_55, %lay_59) : !memref_gmem_f32_
    %iter_61 = cute.get_iter(%view_60) : !memref_gmem_f32_
    %iter_62 = cute.get_iter(%view_60) : !memref_gmem_f32_
    %tile_63 = cute.make_tile() : () -> !cute.tile<"[1:0;1024:1;1:0]">
    %iter_64 = cute.get_iter(%20) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">
    %lay_65 = cute.get_layout(%20) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">
    %32:3 = cute.get_scalars(%lay_65) <{only_dynamic}> : !cute.layout<"(?,?,?):(1@0,1@1,1@2)">
    %c1024_i32_66 = arith.constant 1024 : i32
    %33 = arith.ceildivsi %32#1, %c1024_i32_66 : i32
    %shape_67 = cute.make_shape(%32#0, %33, %32#2) : (i32, i32, i32) -> !cute.shape<"((1,1024,1),(?,?,?))">
    %stride_68 = cute.make_stride() : () -> !cute.stride<"((0,1@1,0),(1@0,1024@1,1@2))">
    %lay_69 = cute.make_layout(%shape_67, %stride_68) : !cute.layout<"((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">
    %view_70 = cute.make_view(%iter_64, %lay_69) : !cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">
    %iter_71 = cute.get_iter(%view_70) : !cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">
    %e0_72, %e1_73, %e2_74 = cute.get_leaves(%iter_71) : !cute.int_tuple<"(0,0,0)">
    %iter_75 = cute.get_iter(%view_70) : !cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">
    %e0_76, %e1_77, %e2_78 = cute.get_leaves(%iter_75) : !cute.int_tuple<"(0,0,0)">
    %tile_79 = cute.make_tile() : () -> !cute.tile<"[1:0;512:1;1:0]">
    %iter_80 = cute.get_iter(%view) : !memref_gmem_i8_6
    %lay_81 = cute.get_layout(%view) : !memref_gmem_i8_6
    %34:5 = cute.get_scalars(%lay_81) <{only_dynamic}> : !cute.layout<"(?,?,?):(?{i64},1,?{i64})">
    %c512_i32 = arith.constant 512 : i32
    %35 = arith.ceildivsi %34#1, %c512_i32 : i32
    %shape_82 = cute.make_shape(%34#0, %35, %34#2) : (i32, i32, i32) -> !cute.shape<"((1,512,1),(?,?,?))">
    %stride_83 = cute.make_stride(%34#3, %34#4) : (i64, i64) -> !cute.stride<"((0,1,0),(?{i64},512,?{i64}))">
    %lay_84 = cute.make_layout(%shape_82, %stride_83) : !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">
    %view_85 = cute.make_view(%iter_80, %lay_84) : !memref_gmem_i8_
    %iter_86 = cute.get_iter(%view_85) : !memref_gmem_i8_
    %iter_87 = cute.get_iter(%view_85) : !memref_gmem_i8_
    %lay_88 = cute.get_layout(%view_60) : !memref_gmem_f32_
    %sz_89 = cute.size(%lay_88) <{mode = [1]}> : (!cute.layout<"((1,1024,1),(?,?,?)):((0,?{i64},0),(?{i64},?{i64 div=1024},1))">) -> !cute.int_tuple<"?">
    %e0_90 = cute.get_leaves(%sz_89) : !cute.int_tuple<"?">
    %36 = cute.get_scalars(%e0_90) : !cute.int_tuple<"?">
    %sz_91 = cute.size(%lay_22) <{mode = [0]}> : (!cute.layout<"(128,8):(8,1)">) -> !cute.int_tuple<"128">
    %e0_92 = cute.get_leaves(%sz_91) : !cute.int_tuple<"128">
    %lay_93 = cute.get_layout(%view_60) : !memref_gmem_f32_
    %37 = cute.get_shape(%lay_93) : (!cute.layout<"((1,1024,1),(?,?,?)):((0,?{i64},0),(?{i64},?{i64 div=1024},1))">) -> !cute.shape<"((1,1024,1),(?,?,?))">
    %e0_94, %e1_95, %e2_96, %e3, %e4, %e5 = cute.get_leaves(%37) : !cute.shape<"((1,1024,1),(?,?,?))">
    %itup_97 = cute.to_int_tuple(%e3) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %38 = cute.get_scalars(%itup_97) : !cute.int_tuple<"?">
    %itup_98 = cute.to_int_tuple(%e4) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %39 = cute.get_scalars(%itup_98) : !cute.int_tuple<"?">
    %itup_99 = cute.to_int_tuple(%e5) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %40 = cute.get_scalars(%itup_99) : !cute.int_tuple<"?">
    %41 = cute.get_stride(%lay_93) : (!cute.layout<"((1,1024,1),(?,?,?)):((0,?{i64},0),(?{i64},?{i64 div=1024},1))">) -> !cute.stride<"((0,?{i64},0),(?{i64},?{i64 div=1024},1))">
    %e0_100, %e1_101, %e2_102, %e3_103, %e4_104, %e5_105 = cute.get_leaves(%41) : !cute.stride<"((0,?{i64},0),(?{i64},?{i64 div=1024},1))">
    %itup_106 = cute.to_int_tuple(%e1_101) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
    %42 = cute.get_scalars(%itup_106) : !cute.int_tuple<"?{i64}">
    %itup_107 = cute.to_int_tuple(%e3_103) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
    %43 = cute.get_scalars(%itup_107) : !cute.int_tuple<"?{i64}">
    %itup_108 = cute.to_int_tuple(%e4_104) : !cute.stride<"?{i64 div=1024}"> to !cute.int_tuple<"?{i64 div=1024}">
    %44 = cute.get_scalars(%itup_108) : !cute.int_tuple<"?{i64 div=1024}">
    %lay_109 = cute.get_layout(%view_85) : !memref_gmem_i8_
    %45 = cute.get_shape(%lay_109) : (!cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !cute.shape<"((1,512,1),(?,?,?))">
    %e0_110, %e1_111, %e2_112, %e3_113, %e4_114, %e5_115 = cute.get_leaves(%45) : !cute.shape<"((1,512,1),(?,?,?))">
    %itup_116 = cute.to_int_tuple(%e3_113) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %46 = cute.get_scalars(%itup_116) : !cute.int_tuple<"?">
    %itup_117 = cute.to_int_tuple(%e4_114) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %47 = cute.get_scalars(%itup_117) : !cute.int_tuple<"?">
    %itup_118 = cute.to_int_tuple(%e5_115) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %48 = cute.get_scalars(%itup_118) : !cute.int_tuple<"?">
    %49 = cute.get_stride(%lay_109) : (!cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !cute.stride<"((0,1,0),(?{i64},512,?{i64}))">
    %e0_119, %e1_120, %e2_121, %e3_122, %e4_123, %e5_124 = cute.get_leaves(%49) : !cute.stride<"((0,1,0),(?{i64},512,?{i64}))">
    %itup_125 = cute.to_int_tuple(%e3_122) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
    %50 = cute.get_scalars(%itup_125) : !cute.int_tuple<"?{i64}">
    %itup_126 = cute.to_int_tuple(%e5_124) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
    %51 = cute.get_scalars(%itup_126) : !cute.int_tuple<"?{i64}">
    %lay_127 = cute.get_layout(%view_70) : !cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">
    %52 = cute.get_shape(%lay_127) : (!cute.layout<"((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">) -> !cute.shape<"((1,1024,1),(?,?,?))">
    %e0_128, %e1_129, %e2_130, %e3_131, %e4_132, %e5_133 = cute.get_leaves(%52) : !cute.shape<"((1,1024,1),(?,?,?))">
    %itup_134 = cute.to_int_tuple(%e3_131) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %53 = cute.get_scalars(%itup_134) : !cute.int_tuple<"?">
    %itup_135 = cute.to_int_tuple(%e4_132) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %54 = cute.get_scalars(%itup_135) : !cute.int_tuple<"?">
    %itup_136 = cute.to_int_tuple(%e5_133) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %55 = cute.get_scalars(%itup_136) : !cute.int_tuple<"?">
    %56 = cute.get_stride(%lay_127) : (!cute.layout<"((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">) -> !cute.stride<"((0,1@1,0),(1@0,1024@1,1@2))">
    %e0_137, %e1_138, %e2_139, %e3_140, %e4_141, %e5_142 = cute.get_leaves(%56) : !cute.stride<"((0,1@1,0),(1@0,1024@1,1@2))">
    %57 = cute.get_shape(%lay_22) : (!cute.layout<"(128,8):(8,1)">) -> !cute.shape<"(128,8)">
    %e0_143, %e1_144 = cute.get_leaves(%57) : !cute.shape<"(128,8)">
    %58 = cute.get_stride(%lay_22) : (!cute.layout<"(128,8):(8,1)">) -> !cute.stride<"(8,1)">
    %e0_145, %e1_146 = cute.get_leaves(%58) : !cute.stride<"(8,1)">
    %59 = cute.get_shape(%14) : (!cute.layout<"(128,4):(4,1)">) -> !cute.shape<"(128,4)">
    %e0_147, %e1_148 = cute.get_leaves(%59) : !cute.shape<"(128,4)">
    %60 = cute.get_stride(%14) : (!cute.layout<"(128,4):(4,1)">) -> !cute.stride<"(4,1)">
    %e0_149, %e1_150 = cute.get_leaves(%60) : !cute.stride<"(4,1)">
    %61 = arith.index_cast %36 : i32 to index
    %c1 = arith.constant 1 : index
    %c128 = arith.constant 128 : index
    %c0_i32 = arith.constant 0 : i32
    gpu.launch_func  @kernels::@kernel_cutlass__convert_kernel_tensorptrf32gmemo11024100div10241_tensorptri8gmemalign16o15121010512_tensor000o1102410110101024112____Float32_Float4E2M1FN_0 blocks in (%61, %c1, %c1) threads in (%c128, %c1, %c1)  dynamic_shared_memory_size %c0_i32 args(%view_60 : !memref_gmem_f32_, %view_85 : !memref_gmem_i8_, %view_70 : !cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">, %17 : i32, %18 : i32, %19 : i32) {use_pdl = false}
    return
  }
}
