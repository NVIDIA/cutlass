!memref_gmem_f32_ = !cute.memref<f32, gmem, "((1,512,1),(?,?,?)):((0,?{i64},0),(?{i64},?{i64 div=512},1))">
!memref_gmem_f32_1 = !cute.memref<f32, gmem, "((1,512,1)):((0,?{i64},0))">
!memref_gmem_f32_2 = !cute.memref<f32, gmem, "(128,4):(?{i64 div=4},?{i64})">
!memref_gmem_f32_3 = !cute.memref<f32, gmem, "(4):(?{i64})">
!memref_gmem_f32_4 = !cute.memref<f32, gmem, "(4,1):(?{i64},0)">
!memref_gmem_f32_5 = !cute.memref<f32, gmem, "(4,(1)):(?{i64},(0))">
!memref_gmem_f32_6 = !cute.memref<f32, gmem, "(?,?,?):(?{i64},?{i64},1)">
!memref_gmem_f8E4M3FN = !cute.memref<f8E4M3FN, gmem, align<16>, "((1,512,1),(?,?,?)):((0,1,0),(?{div=16},512,?{div=16}))">
!memref_gmem_f8E4M3FN1 = !cute.memref<f8E4M3FN, gmem, align<16>, "((1,512,1)):((0,1,0))">
!memref_gmem_f8E4M3FN2 = !cute.memref<f8E4M3FN, gmem, align<16>, "(128,4):(4,1)">
!memref_gmem_f8E4M3FN3 = !cute.memref<f8E4M3FN, gmem, align<4>, "(4):(1)">
!memref_gmem_f8E4M3FN4 = !cute.memref<f8E4M3FN, gmem, align<4>, "(4,1):(1,0)">
!memref_gmem_f8E4M3FN5 = !cute.memref<f8E4M3FN, gmem, align<4>, "(4,(1)):(1,(0))">
!memref_gmem_f8E4M3FN6 = !cute.memref<f8E4M3FN, gmem, align<16>, "(?,?{div=16},?):(?{div=16},1,?{div=16})">
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
    func.func public @kernel_cutlass__convert_kernel_tensorptrf32gmemo1512100div5121_tensorptrf8E4M3FNgmemalign16o15121010div16512div16_tensor000o15121011010512112____Float32_Float8E4M3FN_0(%arg0: !memref_gmem_f32_, %arg1: !memref_gmem_f8E4M3FN, %arg2: !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">, %arg3: i32, %arg4: i32, %arg5: i32) attributes {cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} {
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
      %2 = cute.get_shape(%lay) : (!cute.layout<"((1,512,1),(?,?,?)):((0,?{i64},0),(?{i64},?{i64 div=512},1))">) -> !cute.shape<"((1,512,1),(?,?,?))">
      %e0_8, %e1_9, %e2_10, %e3, %e4, %e5 = cute.get_leaves(%2) : !cute.shape<"((1,512,1),(?,?,?))">
      %itup = cute.to_int_tuple(%e3) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %3 = cute.get_scalars(%itup) : !cute.int_tuple<"?">
      %itup_11 = cute.to_int_tuple(%e4) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %4 = cute.get_scalars(%itup_11) : !cute.int_tuple<"?">
      %itup_12 = cute.to_int_tuple(%e5) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %5 = cute.get_scalars(%itup_12) : !cute.int_tuple<"?">
      %6 = cute.get_stride(%lay) : (!cute.layout<"((1,512,1),(?,?,?)):((0,?{i64},0),(?{i64},?{i64 div=512},1))">) -> !cute.stride<"((0,?{i64},0),(?{i64},?{i64 div=512},1))">
      %e0_13, %e1_14, %e2_15, %e3_16, %e4_17, %e5_18 = cute.get_leaves(%6) : !cute.stride<"((0,?{i64},0),(?{i64},?{i64 div=512},1))">
      %itup_19 = cute.to_int_tuple(%e1_14) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
      %7 = cute.get_scalars(%itup_19) : !cute.int_tuple<"?{i64}">
      %itup_20 = cute.to_int_tuple(%e3_16) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
      %8 = cute.get_scalars(%itup_20) : !cute.int_tuple<"?{i64}">
      %itup_21 = cute.to_int_tuple(%e4_17) : !cute.stride<"?{i64 div=512}"> to !cute.int_tuple<"?{i64 div=512}">
      %9 = cute.get_scalars(%itup_21) : !cute.int_tuple<"?{i64 div=512}">
      %lay_22 = cute.get_layout(%arg1) : !memref_gmem_f8E4M3FN
      %10 = cute.get_shape(%lay_22) : (!cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{div=16},512,?{div=16}))">) -> !cute.shape<"((1,512,1),(?,?,?))">
      %e0_23, %e1_24, %e2_25, %e3_26, %e4_27, %e5_28 = cute.get_leaves(%10) : !cute.shape<"((1,512,1),(?,?,?))">
      %itup_29 = cute.to_int_tuple(%e3_26) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %11 = cute.get_scalars(%itup_29) : !cute.int_tuple<"?">
      %itup_30 = cute.to_int_tuple(%e4_27) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %12 = cute.get_scalars(%itup_30) : !cute.int_tuple<"?">
      %itup_31 = cute.to_int_tuple(%e5_28) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %13 = cute.get_scalars(%itup_31) : !cute.int_tuple<"?">
      %14 = cute.get_stride(%lay_22) : (!cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{div=16},512,?{div=16}))">) -> !cute.stride<"((0,1,0),(?{div=16},512,?{div=16}))">
      %e0_32, %e1_33, %e2_34, %e3_35, %e4_36, %e5_37 = cute.get_leaves(%14) : !cute.stride<"((0,1,0),(?{div=16},512,?{div=16}))">
      %itup_38 = cute.to_int_tuple(%e3_35) : !cute.stride<"?{div=16}"> to !cute.int_tuple<"?{div=16}">
      %15 = cute.get_scalars(%itup_38) : !cute.int_tuple<"?{div=16}">
      %itup_39 = cute.to_int_tuple(%e5_37) : !cute.stride<"?{div=16}"> to !cute.int_tuple<"?{div=16}">
      %16 = cute.get_scalars(%itup_39) : !cute.int_tuple<"?{div=16}">
      %lay_40 = cute.get_layout(%arg2) : !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">
      %17 = cute.get_shape(%lay_40) : (!cute.layout<"((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">) -> !cute.shape<"((1,512,1),(?,?,?))">
      %e0_41, %e1_42, %e2_43, %e3_44, %e4_45, %e5_46 = cute.get_leaves(%17) : !cute.shape<"((1,512,1),(?,?,?))">
      %itup_47 = cute.to_int_tuple(%e3_44) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %18 = cute.get_scalars(%itup_47) : !cute.int_tuple<"?">
      %itup_48 = cute.to_int_tuple(%e4_45) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %19 = cute.get_scalars(%itup_48) : !cute.int_tuple<"?">
      %itup_49 = cute.to_int_tuple(%e5_46) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %20 = cute.get_scalars(%itup_49) : !cute.int_tuple<"?">
      %21 = cute.get_stride(%lay_40) : (!cute.layout<"((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">) -> !cute.stride<"((0,1@1,0),(1@0,512@1,1@2))">
      %e0_50, %e1_51, %e2_52, %e3_53, %e4_54, %e5_55 = cute.get_leaves(%21) : !cute.stride<"((0,1@1,0),(1@0,512@1,1@2))">
      %22 = cute.get_shape(%0) : (!cute.layout<"(128,4):(4,1)">) -> !cute.shape<"(128,4)">
      %e0_56, %e1_57 = cute.get_leaves(%22) : !cute.shape<"(128,4)">
      %23 = cute.get_stride(%0) : (!cute.layout<"(128,4):(4,1)">) -> !cute.stride<"(4,1)">
      %e0_58, %e1_59 = cute.get_leaves(%23) : !cute.stride<"(4,1)">
      %24 = cute.get_shape(%1) : (!cute.layout<"(128,4):(4,1)">) -> !cute.shape<"(128,4)">
      %e0_60, %e1_61 = cute.get_leaves(%24) : !cute.shape<"(128,4)">
      %25 = cute.get_stride(%1) : (!cute.layout<"(128,4):(4,1)">) -> !cute.stride<"(4,1)">
      %e0_62, %e1_63 = cute.get_leaves(%25) : !cute.stride<"(4,1)">
      %26 = nvvm.read.ptx.sreg.tid.x : i32
      %27 = nvvm.read.ptx.sreg.ctaid.x : i32
      %coord = cute.make_coord(%27) : (i32) -> !cute.coord<"(_,?)">
      %lay_64 = cute.get_layout(%arg0) : !memref_gmem_f32_
      %28:6 = cute.get_scalars(%lay_64) <{only_dynamic}> : !cute.layout<"((1,512,1),(?,?,?)):((0,?{i64},0),(?{i64},?{i64 div=512},1))">
      %29 = cute.get_scalars(%coord) <{only_dynamic}> : !cute.coord<"(_,?)">
      %shape = cute.make_shape() : () -> !cute.shape<"((1,512,1))">
      %stride = cute.make_stride(%28#3) : (i64) -> !cute.stride<"((0,?{i64},0))">
      %lay_65 = cute.make_layout(%shape, %stride) : !cute.layout<"((1,512,1)):((0,?{i64},0))">
      %idx = cute.crd2idx(%coord, %lay_64) : (!cute.coord<"(_,?)">, !cute.layout<"((1,512,1),(?,?,?)):((0,?{i64},0),(?{i64},?{i64 div=512},1))">) -> !cute.int_tuple<"?{i64}">
      %iter_66 = cute.get_iter(%arg0) : !memref_gmem_f32_
      %ptr = cute.add_offset(%iter_66, %idx) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %view = cute.make_view(%ptr, %lay_65) : !memref_gmem_f32_1
      %iter_67 = cute.get_iter(%view) : !memref_gmem_f32_1
      %coord_68 = cute.make_coord(%27) : (i32) -> !cute.coord<"(_,?)">
      %lay_69 = cute.get_layout(%arg1) : !memref_gmem_f8E4M3FN
      %idx_70 = cute.crd2idx(%coord_68, %lay_69) : (!cute.coord<"(_,?)">, !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{div=16},512,?{div=16}))">) -> !cute.int_tuple<"?{div=16}">
      %iter_71 = cute.get_iter(%arg1) : !memref_gmem_f8E4M3FN
      %ptr_72 = cute.add_offset(%iter_71, %idx_70) : (!cute.ptr<f8E4M3FN, gmem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<f8E4M3FN, gmem, align<16>>
      %view_73 = cute.make_view(%ptr_72) : !memref_gmem_f8E4M3FN1
      %iter_74 = cute.get_iter(%view_73) : !memref_gmem_f8E4M3FN1
      %coord_75 = cute.make_coord(%27) : (i32) -> !cute.coord<"(_,?)">
      %lay_76 = cute.get_layout(%arg2) : !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">
      %idx_77 = cute.crd2idx(%coord_75, %lay_76) : (!cute.coord<"(_,?)">, !cute.layout<"((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">) -> !cute.int_tuple<"(?,?{div=512},?)">
      %iter_78 = cute.get_iter(%arg2) : !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">
      %tup = cute.add_offset(%iter_78, %idx_77) : (!cute.int_tuple<"(0,0,0)">, !cute.int_tuple<"(?,?{div=512},?)">) -> !cute.int_tuple<"(?,?{div=512},?)">
      %view_79 = cute.make_view(%tup) : !cute.coord_tensor<"(?,?{div=512},?)", "((1,512,1)):((0,1@1,0))">
      %iter_80 = cute.get_iter(%view_79) : !cute.coord_tensor<"(?,?{div=512},?)", "((1,512,1)):((0,1@1,0))">
      %e0_81, %e1_82, %e2_83 = cute.get_leaves(%iter_80) : !cute.int_tuple<"(?,?{div=512},?)">
      %30 = cute.get_scalars(%e0_81) : !cute.int_tuple<"?">
      %31 = cute.get_scalars(%e1_82) : !cute.int_tuple<"?{div=512}">
      %32 = cute.get_scalars(%e2_83) : !cute.int_tuple<"?">
      %iter_84 = cute.get_iter(%view) : !memref_gmem_f32_1
      %lay_85 = cute.get_layout(%view) : !memref_gmem_f32_1
      %33 = cute.get_scalars(%lay_85) <{only_dynamic}> : !cute.layout<"((1,512,1)):((0,?{i64},0))">
      %c4_i64 = arith.constant 4 : i64
      %34 = arith.muli %33, %c4_i64 : i64
      %shape_86 = cute.make_shape() : () -> !cute.shape<"(128,4)">
      %iv = cute.assume(%34) : (i64) -> !cute.i64<divby 4>
      %stride_87 = cute.make_stride(%iv, %33) : (!cute.i64<divby 4>, i64) -> !cute.stride<"(?{i64 div=4},?{i64})">
      %lay_88 = cute.make_layout(%shape_86, %stride_87) : !cute.layout<"(128,4):(?{i64 div=4},?{i64})">
      %view_89 = cute.make_view(%iter_84, %lay_88) : !memref_gmem_f32_2
      %iter_90 = cute.get_iter(%view_89) : !memref_gmem_f32_2
      %iter_91 = cute.get_iter(%view_73) : !memref_gmem_f8E4M3FN1
      %view_92 = cute.make_view(%iter_91) : !memref_gmem_f8E4M3FN2
      %iter_93 = cute.get_iter(%view_92) : !memref_gmem_f8E4M3FN2
      %iter_94 = cute.get_iter(%view_79) : !cute.coord_tensor<"(?,?{div=512},?)", "((1,512,1)):((0,1@1,0))">
      %view_95 = cute.make_view(%iter_94) : !cute.coord_tensor<"(?,?{div=512},?)", "(128,4):(4@1,1@1)">
      %iter_96 = cute.get_iter(%view_95) : !cute.coord_tensor<"(?,?{div=512},?)", "(128,4):(4@1,1@1)">
      %e0_97, %e1_98, %e2_99 = cute.get_leaves(%iter_96) : !cute.int_tuple<"(?,?{div=512},?)">
      %35 = cute.get_scalars(%e0_97) : !cute.int_tuple<"?">
      %36 = cute.get_scalars(%e1_98) : !cute.int_tuple<"?{div=512}">
      %37 = cute.get_scalars(%e2_99) : !cute.int_tuple<"?">
      %coord_100 = cute.make_coord(%26) : (i32) -> !cute.coord<"(?,_)">
      %lay_101 = cute.get_layout(%view_89) : !memref_gmem_f32_2
      %38:2 = cute.get_scalars(%lay_101) <{only_dynamic}> : !cute.layout<"(128,4):(?{i64 div=4},?{i64})">
      %39 = cute.get_scalars(%coord_100) <{only_dynamic}> : !cute.coord<"(?,_)">
      %shape_102 = cute.make_shape() : () -> !cute.shape<"(4)">
      %stride_103 = cute.make_stride(%38#1) : (i64) -> !cute.stride<"(?{i64})">
      %lay_104 = cute.make_layout(%shape_102, %stride_103) : !cute.layout<"(4):(?{i64})">
      %idx_105 = cute.crd2idx(%coord_100, %lay_101) : (!cute.coord<"(?,_)">, !cute.layout<"(128,4):(?{i64 div=4},?{i64})">) -> !cute.int_tuple<"?{i64 div=4}">
      %iter_106 = cute.get_iter(%view_89) : !memref_gmem_f32_2
      %ptr_107 = cute.add_offset(%iter_106, %idx_105) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=4}">) -> !cute.ptr<f32, gmem>
      %view_108 = cute.make_view(%ptr_107, %lay_104) : !memref_gmem_f32_3
      %iter_109 = cute.get_iter(%view_108) : !memref_gmem_f32_3
      %coord_110 = cute.make_coord(%26) : (i32) -> !cute.coord<"(?,_)">
      %lay_111 = cute.get_layout(%view_92) : !memref_gmem_f8E4M3FN2
      %idx_112 = cute.crd2idx(%coord_110, %lay_111) : (!cute.coord<"(?,_)">, !cute.layout<"(128,4):(4,1)">) -> !cute.int_tuple<"?{div=4}">
      %iter_113 = cute.get_iter(%view_92) : !memref_gmem_f8E4M3FN2
      %ptr_114 = cute.add_offset(%iter_113, %idx_112) : (!cute.ptr<f8E4M3FN, gmem, align<16>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f8E4M3FN, gmem, align<4>>
      %view_115 = cute.make_view(%ptr_114) : !memref_gmem_f8E4M3FN3
      %iter_116 = cute.get_iter(%view_115) : !memref_gmem_f8E4M3FN3
      %coord_117 = cute.make_coord(%26) : (i32) -> !cute.coord<"(?,_)">
      %lay_118 = cute.get_layout(%view_95) : !cute.coord_tensor<"(?,?{div=512},?)", "(128,4):(4@1,1@1)">
      %idx_119 = cute.crd2idx(%coord_117, %lay_118) : (!cute.coord<"(?,_)">, !cute.layout<"(128,4):(4@1,1@1)">) -> !cute.int_tuple<"(0,?{div=4})">
      %iter_120 = cute.get_iter(%view_95) : !cute.coord_tensor<"(?,?{div=512},?)", "(128,4):(4@1,1@1)">
      %tup_121 = cute.add_offset(%iter_120, %idx_119) : (!cute.int_tuple<"(?,?{div=512},?)">, !cute.int_tuple<"(0,?{div=4})">) -> !cute.int_tuple<"(?,?{div=4},?)">
      %view_122 = cute.make_view(%tup_121) : !cute.coord_tensor<"(?,?{div=4},?)", "(4):(1@1)">
      %iter_123 = cute.get_iter(%view_122) : !cute.coord_tensor<"(?,?{div=4},?)", "(4):(1@1)">
      %e0_124, %e1_125, %e2_126 = cute.get_leaves(%iter_123) : !cute.int_tuple<"(?,?{div=4},?)">
      %40 = cute.get_scalars(%e0_124) : !cute.int_tuple<"?">
      %41 = cute.get_scalars(%e1_125) : !cute.int_tuple<"?{div=4}">
      %42 = cute.get_scalars(%e2_126) : !cute.int_tuple<"?">
      %coord_127 = cute.make_coord() : () -> !cute.coord<"0">
      %lay_128 = cute.get_layout(%view_122) : !cute.coord_tensor<"(?,?{div=4},?)", "(4):(1@1)">
      %idx_129 = cute.crd2idx(%coord_127, %lay_128) : (!cute.coord<"0">, !cute.layout<"(4):(1@1)">) -> !cute.int_tuple<"(0,0)">
      %iter_130 = cute.get_iter(%view_122) : !cute.coord_tensor<"(?,?{div=4},?)", "(4):(1@1)">
      %tup_131 = cute.add_offset(%iter_130, %idx_129) : (!cute.int_tuple<"(?,?{div=4},?)">, !cute.int_tuple<"(0,0)">) -> !cute.int_tuple<"(?,?{div=4},?)">
      %view_132 = cute.make_view(%tup_131) : !cute.coord_tensor<"(?,?{div=4},?)", "():()">
      %iter_133 = cute.get_iter(%view_132) : !cute.coord_tensor<"(?,?{div=4},?)", "():()">
      %e0_134, %e1_135, %e2_136 = cute.get_leaves(%iter_133) : !cute.int_tuple<"(?,?{div=4},?)">
      %43 = cute.get_scalars(%e0_134) : !cute.int_tuple<"?">
      %44 = cute.get_scalars(%e1_135) : !cute.int_tuple<"?{div=4}">
      %45 = cute.get_scalars(%e2_136) : !cute.int_tuple<"?">
      %iter_137 = cute.get_iter(%view_132) : !cute.coord_tensor<"(?,?{div=4},?)", "():()">
      %e0_138, %e1_139, %e2_140 = cute.get_leaves(%iter_137) : !cute.int_tuple<"(?,?{div=4},?)">
      %46 = cute.get_scalars(%e0_138) : !cute.int_tuple<"?">
      %47 = cute.get_scalars(%e1_139) : !cute.int_tuple<"?{div=4}">
      %48 = cute.get_scalars(%e2_140) : !cute.int_tuple<"?">
      %iter_141 = cute.get_iter(%view_132) : !cute.coord_tensor<"(?,?{div=4},?)", "():()">
      %e0_142, %e1_143, %e2_144 = cute.get_leaves(%iter_141) : !cute.int_tuple<"(?,?{div=4},?)">
      %49 = cute.get_scalars(%e0_142) : !cute.int_tuple<"?">
      %50 = cute.get_scalars(%e1_143) : !cute.int_tuple<"?{div=4}">
      %51 = cute.get_scalars(%e2_144) : !cute.int_tuple<"?">
      %coord_145 = cute.make_coord(%e0_142, %e1_143, %e2_144) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=4}">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?{div=4},?)">
      %coord_146 = cute.make_coord(%arg3, %arg4, %arg5) : (i32, i32, i32) -> !cute.coord<"(?,?,?)">
      %52:3 = cute.get_scalars(%coord_145) : !cute.coord<"(?,?{div=4},?)">
      %53:3 = cute.get_scalars(%coord_146) : !cute.coord<"(?,?,?)">
      %true = arith.constant true
      %54 = arith.cmpi slt, %52#0, %53#0 : i32
      %55 = arith.andi %true, %54 : i1
      %56 = arith.cmpi slt, %52#1, %53#1 : i32
      %57 = arith.andi %55, %56 : i1
      %58 = arith.cmpi slt, %52#2, %53#2 : i32
      %59 = arith.andi %57, %58 : i1
      scf.if %59 {
        %60 = cute.get_shape(%0) : (!cute.layout<"(128,4):(4,1)">) -> !cute.shape<"(128,4)">
        %e0_147, %e1_148 = cute.get_leaves(%60) : !cute.shape<"(128,4)">
        %61 = cute.get_shape(%0) : (!cute.layout<"(128,4):(4,1)">) -> !cute.shape<"(128,4)">
        %e0_149, %e1_150 = cute.get_leaves(%61) : !cute.shape<"(128,4)">
        %lay_151 = cute.make_layout() : !cute.layout<"4:1">
        %rmem = cute.memref.alloca(%lay_151) : !memref_rmem_f32_
        %iter_152 = cute.get_iter(%rmem) : !memref_rmem_f32_
        %iter_153 = cute.get_iter(%rmem) : !memref_rmem_f32_
        %62 = cute.get_shape(%1) : (!cute.layout<"(128,4):(4,1)">) -> !cute.shape<"(128,4)">
        %e0_154, %e1_155 = cute.get_leaves(%62) : !cute.shape<"(128,4)">
        %63 = cute.get_shape(%1) : (!cute.layout<"(128,4):(4,1)">) -> !cute.shape<"(128,4)">
        %e0_156, %e1_157 = cute.get_leaves(%63) : !cute.shape<"(128,4)">
        %lay_158 = cute.make_layout() : !cute.layout<"4:1">
        %rmem_159 = cute.memref.alloca(%lay_158) : !memref_rmem_f8E4M3FN
        %iter_160 = cute.get_iter(%rmem_159) : !memref_rmem_f8E4M3FN
        %iter_161 = cute.get_iter(%rmem_159) : !memref_rmem_f8E4M3FN
        %atom = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<f32>
        %lay_162 = cute.get_layout(%view_108) : !memref_gmem_f32_3
        %64 = cute.get_shape(%lay_162) : (!cute.layout<"(4):(?{i64})">) -> !cute.shape<"(4)">
        %e0_163 = cute.get_leaves(%64) : !cute.shape<"(4)">
        %lay_164 = cute.get_layout(%rmem) : !memref_rmem_f32_
        %65 = cute.get_shape(%lay_164) : (!cute.layout<"4:1">) -> !cute.shape<"4">
        %e0_165 = cute.get_leaves(%65) : !cute.shape<"4">
        %lay_166 = cute.get_layout(%view_108) : !memref_gmem_f32_3
        %shape_167 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_168 = cute.make_layout() : !cute.layout<"1:0">
        %append = cute.append_to_rank<2> (%lay_166, %lay_168) : !cute.layout<"(4):(?{i64})">, !cute.layout<"1:0">
        %view_169 = cute.make_view(%iter_109, %append) : !memref_gmem_f32_4
        %iter_170 = cute.get_iter(%view_169) : !memref_gmem_f32_4
        %lay_171 = cute.get_layout(%view_169) : !memref_gmem_f32_4
        %66 = cute.get_shape(%lay_171) : (!cute.layout<"(4,1):(?{i64},0)">) -> !cute.shape<"(4,1)">
        %e0_172, %e1_173 = cute.get_leaves(%66) : !cute.shape<"(4,1)">
        %iter_174 = cute.get_iter(%view_169) : !memref_gmem_f32_4
        %lay_175 = cute.get_layout(%view_169) : !memref_gmem_f32_4
        %67 = cute.get_scalars(%lay_175) <{only_dynamic}> : !cute.layout<"(4,1):(?{i64},0)">
        %shape_176 = cute.make_shape() : () -> !cute.shape<"(4,(1))">
        %stride_177 = cute.make_stride(%67) : (i64) -> !cute.stride<"(?{i64},(0))">
        %lay_178 = cute.make_layout(%shape_176, %stride_177) : !cute.layout<"(4,(1)):(?{i64},(0))">
        %view_179 = cute.make_view(%iter_174, %lay_178) : !memref_gmem_f32_5
        %iter_180 = cute.get_iter(%view_179) : !memref_gmem_f32_5
        %iter_181 = cute.get_iter(%view_179) : !memref_gmem_f32_5
        %lay_182 = cute.get_layout(%rmem) : !memref_rmem_f32_
        %shape_183 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_184 = cute.make_layout() : !cute.layout<"1:0">
        %append_185 = cute.append_to_rank<2> (%lay_182, %lay_184) : !cute.layout<"4:1">, !cute.layout<"1:0">
        %view_186 = cute.make_view(%iter_153, %append_185) : !memref_rmem_f32_1
        %iter_187 = cute.get_iter(%view_186) : !memref_rmem_f32_1
        %lay_188 = cute.get_layout(%view_186) : !memref_rmem_f32_1
        %68 = cute.get_shape(%lay_188) : (!cute.layout<"(4,1):(1,0)">) -> !cute.shape<"(4,1)">
        %e0_189, %e1_190 = cute.get_leaves(%68) : !cute.shape<"(4,1)">
        %iter_191 = cute.get_iter(%view_186) : !memref_rmem_f32_1
        %view_192 = cute.make_view(%iter_191) : !memref_rmem_f32_2
        %iter_193 = cute.get_iter(%view_192) : !memref_rmem_f32_2
        %iter_194 = cute.get_iter(%view_192) : !memref_rmem_f32_2
        %lay_195 = cute.get_layout(%view_179) : !memref_gmem_f32_5
        %69 = cute.get_shape(%lay_195) : (!cute.layout<"(4,(1)):(?{i64},(0))">) -> !cute.shape<"(4,(1))">
        %e0_196, %e1_197 = cute.get_leaves(%69) : !cute.shape<"(4,(1))">
        %lay_198 = cute.get_layout(%view_192) : !memref_rmem_f32_2
        %70 = cute.get_shape(%lay_198) : (!cute.layout<"(4,(1)):(1,(0))">) -> !cute.shape<"(4,(1))">
        %e0_199, %e1_200 = cute.get_leaves(%70) : !cute.shape<"(4,(1))">
        %lay_201 = cute.get_layout(%view_179) : !memref_gmem_f32_5
        %sz = cute.size(%lay_201) <{mode = [1]}> : (!cute.layout<"(4,(1)):(?{i64},(0))">) -> !cute.int_tuple<"1">
        %e0_202 = cute.get_leaves(%sz) : !cute.int_tuple<"1">
        %lay_203 = cute.get_layout(%view_192) : !memref_rmem_f32_2
        %sz_204 = cute.size(%lay_203) <{mode = [1]}> : (!cute.layout<"(4,(1)):(1,(0))">) -> !cute.int_tuple<"1">
        %e0_205 = cute.get_leaves(%sz_204) : !cute.int_tuple<"1">
        %71 = cute.static : !cute.layout<"1:0">
        %iter_206 = cute.get_iter(%view_179) : !memref_gmem_f32_5
        %iter_207 = cute.get_iter(%view_192) : !memref_rmem_f32_2
        %lay_208 = cute.get_layout(%view_179) : !memref_gmem_f32_5
        %lay_209 = cute.get_layout(%view_192) : !memref_rmem_f32_2
        %append_210 = cute.append_to_rank<2> (%lay_208, %71) : !cute.layout<"(4,(1)):(?{i64},(0))">, !cute.layout<"1:0">
        %append_211 = cute.append_to_rank<2> (%lay_209, %71) : !cute.layout<"(4,(1)):(1,(0))">, !cute.layout<"1:0">
        %72 = cute.get_scalars(%append_210) <{only_dynamic}> : !cute.layout<"(4,(1)):(?{i64},(0))">
        %shape_212 = cute.make_shape() : () -> !cute.shape<"(4,((1)))">
        %stride_213 = cute.make_stride(%72) : (i64) -> !cute.stride<"(?{i64},((0)))">
        %lay_214 = cute.make_layout(%shape_212, %stride_213) : !cute.layout<"(4,((1))):(?{i64},((0)))">
        %lay_215 = cute.make_layout() : !cute.layout<"(4,((1))):(1,((0)))">
        %sz_216 = cute.size(%lay_214) <{mode = [1]}> : (!cute.layout<"(4,((1))):(?{i64},((0)))">) -> !cute.int_tuple<"1">
        %73 = cute.get_scalars(%sz_216) : !cute.int_tuple<"1">
        %c0_i32 = arith.constant 0 : i32
        %c1_i32 = arith.constant 1 : i32
        scf.for %arg6 = %c0_i32 to %73 step %c1_i32  : i32 {
          %coord_276 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
          %84 = cute.get_scalars(%lay_214) <{only_dynamic}> : !cute.layout<"(4,((1))):(?{i64},((0)))">
          %85 = cute.get_scalars(%coord_276) <{only_dynamic}> : !cute.coord<"(_,?)">
          %shape_277 = cute.make_shape() : () -> !cute.shape<"(4)">
          %stride_278 = cute.make_stride(%84) : (i64) -> !cute.stride<"(?{i64})">
          %lay_279 = cute.make_layout(%shape_277, %stride_278) : !cute.layout<"(4):(?{i64})">
          %idx_280 = cute.crd2idx(%coord_276, %lay_214) : (!cute.coord<"(_,?)">, !cute.layout<"(4,((1))):(?{i64},((0)))">) -> !cute.int_tuple<"0">
          %ptr_281 = cute.add_offset(%iter_206, %idx_280) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<f32, gmem>
          %view_282 = cute.make_view(%ptr_281, %lay_279) : !memref_gmem_f32_3
          %86 = cute.get_scalars(%coord_276) <{only_dynamic}> : !cute.coord<"(_,?)">
          %lay_283 = cute.make_layout() : !cute.layout<"(4):(1)">
          %idx_284 = cute.crd2idx(%coord_276, %lay_215) : (!cute.coord<"(_,?)">, !cute.layout<"(4,((1))):(1,((0)))">) -> !cute.int_tuple<"0">
          %ptr_285 = cute.add_offset(%iter_207, %idx_284) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, rmem, align<32>>
          %view_286 = cute.make_view(%ptr_285, %lay_283) : !memref_rmem_f32_3
          %iter_287 = cute.get_iter(%view_282) : !memref_gmem_f32_3
          %lay_288 = cute.get_layout(%view_282) : !memref_gmem_f32_3
          %87 = cute.get_scalars(%lay_288) <{only_dynamic}> : !cute.layout<"(4):(?{i64})">
          %iter_289 = cute.get_iter(%view_286) : !memref_rmem_f32_3
          %88 = builtin.unrealized_conversion_cast %iter_287 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %89 = builtin.unrealized_conversion_cast %iter_289 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
          %90 = llvm.load %88 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %90, %89 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          %int_tuple_290 = cute.make_int_tuple(%87) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_291 = cute.add_offset(%iter_287, %int_tuple_290) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %int_tuple_292 = cute.make_int_tuple() : () -> !cute.int_tuple<"1">
          %ptr_293 = cute.add_offset(%iter_289, %int_tuple_292) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
          %91 = builtin.unrealized_conversion_cast %ptr_291 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %92 = builtin.unrealized_conversion_cast %ptr_293 : !cute.ptr<f32, rmem> to !llvm.ptr
          %93 = llvm.load %91 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %93, %92 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          %c2_i64 = arith.constant 2 : i64
          %94 = arith.muli %87, %c2_i64 : i64
          %iv_294 = cute.assume(%94) : (i64) -> !cute.i64<divby 2>
          %int_tuple_295 = cute.make_int_tuple(%iv_294) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
          %ptr_296 = cute.add_offset(%iter_287, %int_tuple_295) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
          %int_tuple_297 = cute.make_int_tuple() : () -> !cute.int_tuple<"2">
          %ptr_298 = cute.add_offset(%iter_289, %int_tuple_297) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
          %95 = builtin.unrealized_conversion_cast %ptr_296 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %96 = builtin.unrealized_conversion_cast %ptr_298 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %97 = llvm.load %95 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %97, %96 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          %c3_i64 = arith.constant 3 : i64
          %98 = arith.muli %87, %c3_i64 : i64
          %iv_299 = cute.assume(%98) : (i64) -> !cute.i64<divby 3>
          %int_tuple_300 = cute.make_int_tuple(%iv_299) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
          %ptr_301 = cute.add_offset(%iter_287, %int_tuple_300) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
          %int_tuple_302 = cute.make_int_tuple() : () -> !cute.int_tuple<"3">
          %ptr_303 = cute.add_offset(%iter_289, %int_tuple_302) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
          %99 = builtin.unrealized_conversion_cast %ptr_301 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %100 = builtin.unrealized_conversion_cast %ptr_303 : !cute.ptr<f32, rmem> to !llvm.ptr
          %101 = llvm.load %99 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %101, %100 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %74 = cute.memref.load_vec %rmem, row_major : !memref_rmem_f32_
        %75 = nvgpu.cvt_fptrunc %74 : vector<4xf32> to vector<4xf8E4M3FN>
        %lay_217 = cute.get_layout(%rmem_159) : !memref_rmem_f8E4M3FN
        %76 = cute.get_shape(%lay_217) : (!cute.layout<"4:1">) -> !cute.shape<"4">
        %e0_218 = cute.get_leaves(%76) : !cute.shape<"4">
        %int_tuple = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
        %sz_219 = cute.size(%int_tuple) : (!cute.int_tuple<"4">) -> !cute.int_tuple<"4">
        %e0_220 = cute.get_leaves(%sz_219) : !cute.int_tuple<"4">
        %int_tuple_221 = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
        %sz_222 = cute.size(%int_tuple_221) : (!cute.int_tuple<"4">) -> !cute.int_tuple<"4">
        %e0_223 = cute.get_leaves(%sz_222) : !cute.int_tuple<"4">
        cute.memref.store_vec %75, %rmem_159, row_major : !memref_rmem_f8E4M3FN
        %atom_224 = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<f8E4M3FN>
        %lay_225 = cute.get_layout(%view_115) : !memref_gmem_f8E4M3FN3
        %77 = cute.get_shape(%lay_225) : (!cute.layout<"(4):(1)">) -> !cute.shape<"(4)">
        %e0_226 = cute.get_leaves(%77) : !cute.shape<"(4)">
        %lay_227 = cute.get_layout(%rmem_159) : !memref_rmem_f8E4M3FN
        %shape_228 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_229 = cute.make_layout() : !cute.layout<"1:0">
        %append_230 = cute.append_to_rank<2> (%lay_227, %lay_229) : !cute.layout<"4:1">, !cute.layout<"1:0">
        %view_231 = cute.make_view(%iter_161, %append_230) : !memref_rmem_f8E4M3FN1
        %iter_232 = cute.get_iter(%view_231) : !memref_rmem_f8E4M3FN1
        %lay_233 = cute.get_layout(%view_231) : !memref_rmem_f8E4M3FN1
        %78 = cute.get_shape(%lay_233) : (!cute.layout<"(4,1):(1,0)">) -> !cute.shape<"(4,1)">
        %e0_234, %e1_235 = cute.get_leaves(%78) : !cute.shape<"(4,1)">
        %iter_236 = cute.get_iter(%view_231) : !memref_rmem_f8E4M3FN1
        %view_237 = cute.make_view(%iter_236) : !memref_rmem_f8E4M3FN2
        %iter_238 = cute.get_iter(%view_237) : !memref_rmem_f8E4M3FN2
        %iter_239 = cute.get_iter(%view_237) : !memref_rmem_f8E4M3FN2
        %lay_240 = cute.get_layout(%view_115) : !memref_gmem_f8E4M3FN3
        %shape_241 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_242 = cute.make_layout() : !cute.layout<"1:0">
        %append_243 = cute.append_to_rank<2> (%lay_240, %lay_242) : !cute.layout<"(4):(1)">, !cute.layout<"1:0">
        %view_244 = cute.make_view(%iter_116, %append_243) : !memref_gmem_f8E4M3FN4
        %iter_245 = cute.get_iter(%view_244) : !memref_gmem_f8E4M3FN4
        %lay_246 = cute.get_layout(%view_244) : !memref_gmem_f8E4M3FN4
        %79 = cute.get_shape(%lay_246) : (!cute.layout<"(4,1):(1,0)">) -> !cute.shape<"(4,1)">
        %e0_247, %e1_248 = cute.get_leaves(%79) : !cute.shape<"(4,1)">
        %iter_249 = cute.get_iter(%view_244) : !memref_gmem_f8E4M3FN4
        %view_250 = cute.make_view(%iter_249) : !memref_gmem_f8E4M3FN5
        %iter_251 = cute.get_iter(%view_250) : !memref_gmem_f8E4M3FN5
        %iter_252 = cute.get_iter(%view_250) : !memref_gmem_f8E4M3FN5
        %lay_253 = cute.get_layout(%view_237) : !memref_rmem_f8E4M3FN2
        %80 = cute.get_shape(%lay_253) : (!cute.layout<"(4,(1)):(1,(0))">) -> !cute.shape<"(4,(1))">
        %e0_254, %e1_255 = cute.get_leaves(%80) : !cute.shape<"(4,(1))">
        %lay_256 = cute.get_layout(%view_250) : !memref_gmem_f8E4M3FN5
        %81 = cute.get_shape(%lay_256) : (!cute.layout<"(4,(1)):(1,(0))">) -> !cute.shape<"(4,(1))">
        %e0_257, %e1_258 = cute.get_leaves(%81) : !cute.shape<"(4,(1))">
        %lay_259 = cute.get_layout(%view_237) : !memref_rmem_f8E4M3FN2
        %sz_260 = cute.size(%lay_259) <{mode = [1]}> : (!cute.layout<"(4,(1)):(1,(0))">) -> !cute.int_tuple<"1">
        %e0_261 = cute.get_leaves(%sz_260) : !cute.int_tuple<"1">
        %lay_262 = cute.get_layout(%view_250) : !memref_gmem_f8E4M3FN5
        %sz_263 = cute.size(%lay_262) <{mode = [1]}> : (!cute.layout<"(4,(1)):(1,(0))">) -> !cute.int_tuple<"1">
        %e0_264 = cute.get_leaves(%sz_263) : !cute.int_tuple<"1">
        %82 = cute.static : !cute.layout<"1:0">
        %iter_265 = cute.get_iter(%view_237) : !memref_rmem_f8E4M3FN2
        %iter_266 = cute.get_iter(%view_250) : !memref_gmem_f8E4M3FN5
        %lay_267 = cute.get_layout(%view_237) : !memref_rmem_f8E4M3FN2
        %lay_268 = cute.get_layout(%view_250) : !memref_gmem_f8E4M3FN5
        %append_269 = cute.append_to_rank<2> (%lay_267, %82) : !cute.layout<"(4,(1)):(1,(0))">, !cute.layout<"1:0">
        %append_270 = cute.append_to_rank<2> (%lay_268, %82) : !cute.layout<"(4,(1)):(1,(0))">, !cute.layout<"1:0">
        %lay_271 = cute.make_layout() : !cute.layout<"(4,((1))):(1,((0)))">
        %lay_272 = cute.make_layout() : !cute.layout<"(4,((1))):(1,((0)))">
        %sz_273 = cute.size(%lay_271) <{mode = [1]}> : (!cute.layout<"(4,((1))):(1,((0)))">) -> !cute.int_tuple<"1">
        %83 = cute.get_scalars(%sz_273) : !cute.int_tuple<"1">
        %c0_i32_274 = arith.constant 0 : i32
        %c1_i32_275 = arith.constant 1 : i32
        scf.for %arg6 = %c0_i32_274 to %83 step %c1_i32_275  : i32 {
          %coord_276 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
          %84 = cute.get_scalars(%coord_276) <{only_dynamic}> : !cute.coord<"(_,?)">
          %lay_277 = cute.make_layout() : !cute.layout<"(4):(1)">
          %idx_278 = cute.crd2idx(%coord_276, %lay_271) : (!cute.coord<"(_,?)">, !cute.layout<"(4,((1))):(1,((0)))">) -> !cute.int_tuple<"0">
          %ptr_279 = cute.add_offset(%iter_265, %idx_278) : (!cute.ptr<f8E4M3FN, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f8E4M3FN, rmem, align<32>>
          %view_280 = cute.make_view(%ptr_279, %lay_277) : !memref_rmem_f8E4M3FN3
          %85 = cute.get_scalars(%coord_276) <{only_dynamic}> : !cute.coord<"(_,?)">
          %lay_281 = cute.make_layout() : !cute.layout<"(4):(1)">
          %idx_282 = cute.crd2idx(%coord_276, %lay_272) : (!cute.coord<"(_,?)">, !cute.layout<"(4,((1))):(1,((0)))">) -> !cute.int_tuple<"0">
          %ptr_283 = cute.add_offset(%iter_266, %idx_282) : (!cute.ptr<f8E4M3FN, gmem, align<4>>, !cute.int_tuple<"0">) -> !cute.ptr<f8E4M3FN, gmem, align<4>>
          %view_284 = cute.make_view(%ptr_283, %lay_281) : !memref_gmem_f8E4M3FN3
          %iter_285 = cute.get_iter(%view_280) : !memref_rmem_f8E4M3FN3
          %iter_286 = cute.get_iter(%view_284) : !memref_gmem_f8E4M3FN3
          %86 = builtin.unrealized_conversion_cast %iter_285 : !cute.ptr<f8E4M3FN, rmem, align<32>> to !llvm.ptr
          %87 = builtin.unrealized_conversion_cast %iter_286 : !cute.ptr<f8E4M3FN, gmem, align<4>> to !llvm.ptr<1>
          %88 = llvm.load %86 {alignment = 4 : i64} : !llvm.ptr -> vector<4xi8>
          llvm.store %88, %87 {alignment = 4 : i64} : vector<4xi8>, !llvm.ptr<1>
        } {llvm.loop_annotation = #loop_annotation}
      }
      return
    }
  }
  func.func @cutlass__convert_Tensorgmemoi64i641_Tensorgmemodiv16div161div16_1_4(%arg0: !memref_gmem_f32_6, %arg1: !memref_gmem_f8E4M3FN6) attributes {llvm.emit_c_interface} {
    %iter = cute.get_iter(%arg0) : !memref_gmem_f32_6
    %iter_0 = cute.get_iter(%arg1) : !memref_gmem_f8E4M3FN6
    %iter_1 = cute.get_iter(%arg0) : !memref_gmem_f32_6
    %iter_2 = cute.get_iter(%arg1) : !memref_gmem_f8E4M3FN6
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
    %lay_10 = cute.get_layout(%arg1) : !memref_gmem_f8E4M3FN6
    %7 = cute.get_shape(%lay_10) : (!cute.layout<"(?,?{div=16},?):(?{div=16},1,?{div=16})">) -> !cute.shape<"(?,?{div=16},?)">
    %e0_11, %e1_12, %e2_13 = cute.get_leaves(%7) : !cute.shape<"(?,?{div=16},?)">
    %itup_14 = cute.to_int_tuple(%e0_11) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %8 = cute.get_scalars(%itup_14) : !cute.int_tuple<"?">
    %itup_15 = cute.to_int_tuple(%e1_12) : !cute.shape<"?{div=16}"> to !cute.int_tuple<"?{div=16}">
    %9 = cute.get_scalars(%itup_15) : !cute.int_tuple<"?{div=16}">
    %itup_16 = cute.to_int_tuple(%e2_13) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %10 = cute.get_scalars(%itup_16) : !cute.int_tuple<"?">
    %11 = cute.get_stride(%lay_10) : (!cute.layout<"(?,?{div=16},?):(?{div=16},1,?{div=16})">) -> !cute.stride<"(?{div=16},1,?{div=16})">
    %e0_17, %e1_18, %e2_19 = cute.get_leaves(%11) : !cute.stride<"(?{div=16},1,?{div=16})">
    %itup_20 = cute.to_int_tuple(%e0_17) : !cute.stride<"?{div=16}"> to !cute.int_tuple<"?{div=16}">
    %12 = cute.get_scalars(%itup_20) : !cute.int_tuple<"?{div=16}">
    %itup_21 = cute.to_int_tuple(%e2_19) : !cute.stride<"?{div=16}"> to !cute.int_tuple<"?{div=16}">
    %13 = cute.get_scalars(%itup_21) : !cute.int_tuple<"?{div=16}">
    %shape = cute.make_shape() : () -> !cute.shape<"(128,4)">
    %stride = cute.make_stride() : () -> !cute.stride<"(4,1)">
    %lay_22 = cute.make_layout() : !cute.layout<"(128,4):(4,1)">
    %lay_23 = cute.get_layout(%arg0) : !memref_gmem_f32_6
    %14 = cute.get_shape(%lay_23) : (!cute.layout<"(?,?,?):(?{i64},?{i64},1)">) -> !cute.shape<"(?,?,?)">
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
    %18 = cute.get_shape(%lay_37) : (!cute.layout<"(?,?,?):(?{i64},?{i64},1)">) -> !cute.shape<"(?,?,?)">
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
    %22 = cute.get_shape(%lay_45) : (!cute.layout<"(?,?{div=16},?):(?{div=16},1,?{div=16})">) -> !cute.shape<"(?,?{div=16},?)">
    %e0_46, %e1_47, %e2_48 = cute.get_leaves(%22) : !cute.shape<"(?,?{div=16},?)">
    %itup_49 = cute.to_int_tuple(%e0_46) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %23 = cute.get_scalars(%itup_49) : !cute.int_tuple<"?">
    %itup_50 = cute.to_int_tuple(%e1_47) : !cute.shape<"?{div=16}"> to !cute.int_tuple<"?{div=16}">
    %24 = cute.get_scalars(%itup_50) : !cute.int_tuple<"?{div=16}">
    %itup_51 = cute.to_int_tuple(%e2_48) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %25 = cute.get_scalars(%itup_51) : !cute.int_tuple<"?">
    %sz_52 = cute.size(%lay_22) : (!cute.layout<"(128,4):(4,1)">) -> !cute.int_tuple<"512">
    %e0_53 = cute.get_leaves(%sz_52) : !cute.int_tuple<"512">
    %tile = cute.make_tile() : () -> !cute.tile<"[1:0;512:1;1:0]">
    %iter_54 = cute.get_iter(%arg0) : !memref_gmem_f32_6
    %lay_55 = cute.get_layout(%arg0) : !memref_gmem_f32_6
    %26:5 = cute.get_scalars(%lay_55) <{only_dynamic}> : !cute.layout<"(?,?,?):(?{i64},?{i64},1)">
    %c512_i32 = arith.constant 512 : i32
    %27 = arith.ceildivsi %26#1, %c512_i32 : i32
    %c512_i64 = arith.constant 512 : i64
    %28 = arith.muli %26#4, %c512_i64 : i64
    %shape_56 = cute.make_shape(%26#0, %27, %26#2) : (i32, i32, i32) -> !cute.shape<"((1,512,1),(?,?,?))">
    %iv = cute.assume(%28) : (i64) -> !cute.i64<divby 512>
    %stride_57 = cute.make_stride(%26#4, %26#3, %iv) : (i64, i64, !cute.i64<divby 512>) -> !cute.stride<"((0,?{i64},0),(?{i64},?{i64 div=512},1))">
    %lay_58 = cute.make_layout(%shape_56, %stride_57) : !cute.layout<"((1,512,1),(?,?,?)):((0,?{i64},0),(?{i64},?{i64 div=512},1))">
    %view_59 = cute.make_view(%iter_54, %lay_58) : !memref_gmem_f32_
    %iter_60 = cute.get_iter(%view_59) : !memref_gmem_f32_
    %iter_61 = cute.get_iter(%view_59) : !memref_gmem_f32_
    %tile_62 = cute.make_tile() : () -> !cute.tile<"[1:0;512:1;1:0]">
    %iter_63 = cute.get_iter(%view) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">
    %lay_64 = cute.get_layout(%view) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">
    %29:3 = cute.get_scalars(%lay_64) <{only_dynamic}> : !cute.layout<"(?,?,?):(1@0,1@1,1@2)">
    %c512_i32_65 = arith.constant 512 : i32
    %30 = arith.ceildivsi %29#1, %c512_i32_65 : i32
    %shape_66 = cute.make_shape(%29#0, %30, %29#2) : (i32, i32, i32) -> !cute.shape<"((1,512,1),(?,?,?))">
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
    %31:5 = cute.get_scalars(%lay_80) <{only_dynamic}> : !cute.layout<"(?,?{div=16},?):(?{div=16},1,?{div=16})">
    %c512_i32_81 = arith.constant 512 : i32
    %32 = arith.ceildivsi %31#1, %c512_i32_81 : i32
    %shape_82 = cute.make_shape(%31#0, %32, %31#2) : (i32, i32, i32) -> !cute.shape<"((1,512,1),(?,?,?))">
    %iv_83 = cute.assume(%31#3) : (i32) -> !cute.i32<divby 16>
    %iv_84 = cute.assume(%31#4) : (i32) -> !cute.i32<divby 16>
    %stride_85 = cute.make_stride(%iv_83, %iv_84) : (!cute.i32<divby 16>, !cute.i32<divby 16>) -> !cute.stride<"((0,1,0),(?{div=16},512,?{div=16}))">
    %lay_86 = cute.make_layout(%shape_82, %stride_85) : !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{div=16},512,?{div=16}))">
    %view_87 = cute.make_view(%iter_79, %lay_86) : !memref_gmem_f8E4M3FN
    %iter_88 = cute.get_iter(%view_87) : !memref_gmem_f8E4M3FN
    %iter_89 = cute.get_iter(%view_87) : !memref_gmem_f8E4M3FN
    %lay_90 = cute.get_layout(%view_59) : !memref_gmem_f32_
    %sz_91 = cute.size(%lay_90) <{mode = [1]}> : (!cute.layout<"((1,512,1),(?,?,?)):((0,?{i64},0),(?{i64},?{i64 div=512},1))">) -> !cute.int_tuple<"?">
    %e0_92 = cute.get_leaves(%sz_91) : !cute.int_tuple<"?">
    %33 = cute.get_scalars(%e0_92) : !cute.int_tuple<"?">
    %sz_93 = cute.size(%lay_22) <{mode = [0]}> : (!cute.layout<"(128,4):(4,1)">) -> !cute.int_tuple<"128">
    %e0_94 = cute.get_leaves(%sz_93) : !cute.int_tuple<"128">
    %lay_95 = cute.get_layout(%view_59) : !memref_gmem_f32_
    %34 = cute.get_shape(%lay_95) : (!cute.layout<"((1,512,1),(?,?,?)):((0,?{i64},0),(?{i64},?{i64 div=512},1))">) -> !cute.shape<"((1,512,1),(?,?,?))">
    %e0_96, %e1_97, %e2_98, %e3, %e4, %e5 = cute.get_leaves(%34) : !cute.shape<"((1,512,1),(?,?,?))">
    %itup_99 = cute.to_int_tuple(%e3) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %35 = cute.get_scalars(%itup_99) : !cute.int_tuple<"?">
    %itup_100 = cute.to_int_tuple(%e4) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %36 = cute.get_scalars(%itup_100) : !cute.int_tuple<"?">
    %itup_101 = cute.to_int_tuple(%e5) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %37 = cute.get_scalars(%itup_101) : !cute.int_tuple<"?">
    %38 = cute.get_stride(%lay_95) : (!cute.layout<"((1,512,1),(?,?,?)):((0,?{i64},0),(?{i64},?{i64 div=512},1))">) -> !cute.stride<"((0,?{i64},0),(?{i64},?{i64 div=512},1))">
    %e0_102, %e1_103, %e2_104, %e3_105, %e4_106, %e5_107 = cute.get_leaves(%38) : !cute.stride<"((0,?{i64},0),(?{i64},?{i64 div=512},1))">
    %itup_108 = cute.to_int_tuple(%e1_103) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
    %39 = cute.get_scalars(%itup_108) : !cute.int_tuple<"?{i64}">
    %itup_109 = cute.to_int_tuple(%e3_105) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
    %40 = cute.get_scalars(%itup_109) : !cute.int_tuple<"?{i64}">
    %itup_110 = cute.to_int_tuple(%e4_106) : !cute.stride<"?{i64 div=512}"> to !cute.int_tuple<"?{i64 div=512}">
    %41 = cute.get_scalars(%itup_110) : !cute.int_tuple<"?{i64 div=512}">
    %lay_111 = cute.get_layout(%view_87) : !memref_gmem_f8E4M3FN
    %42 = cute.get_shape(%lay_111) : (!cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{div=16},512,?{div=16}))">) -> !cute.shape<"((1,512,1),(?,?,?))">
    %e0_112, %e1_113, %e2_114, %e3_115, %e4_116, %e5_117 = cute.get_leaves(%42) : !cute.shape<"((1,512,1),(?,?,?))">
    %itup_118 = cute.to_int_tuple(%e3_115) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %43 = cute.get_scalars(%itup_118) : !cute.int_tuple<"?">
    %itup_119 = cute.to_int_tuple(%e4_116) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %44 = cute.get_scalars(%itup_119) : !cute.int_tuple<"?">
    %itup_120 = cute.to_int_tuple(%e5_117) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %45 = cute.get_scalars(%itup_120) : !cute.int_tuple<"?">
    %46 = cute.get_stride(%lay_111) : (!cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{div=16},512,?{div=16}))">) -> !cute.stride<"((0,1,0),(?{div=16},512,?{div=16}))">
    %e0_121, %e1_122, %e2_123, %e3_124, %e4_125, %e5_126 = cute.get_leaves(%46) : !cute.stride<"((0,1,0),(?{div=16},512,?{div=16}))">
    %itup_127 = cute.to_int_tuple(%e3_124) : !cute.stride<"?{div=16}"> to !cute.int_tuple<"?{div=16}">
    %47 = cute.get_scalars(%itup_127) : !cute.int_tuple<"?{div=16}">
    %itup_128 = cute.to_int_tuple(%e5_126) : !cute.stride<"?{div=16}"> to !cute.int_tuple<"?{div=16}">
    %48 = cute.get_scalars(%itup_128) : !cute.int_tuple<"?{div=16}">
    %lay_129 = cute.get_layout(%view_69) : !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">
    %49 = cute.get_shape(%lay_129) : (!cute.layout<"((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">) -> !cute.shape<"((1,512,1),(?,?,?))">
    %e0_130, %e1_131, %e2_132, %e3_133, %e4_134, %e5_135 = cute.get_leaves(%49) : !cute.shape<"((1,512,1),(?,?,?))">
    %itup_136 = cute.to_int_tuple(%e3_133) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %50 = cute.get_scalars(%itup_136) : !cute.int_tuple<"?">
    %itup_137 = cute.to_int_tuple(%e4_134) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %51 = cute.get_scalars(%itup_137) : !cute.int_tuple<"?">
    %itup_138 = cute.to_int_tuple(%e5_135) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %52 = cute.get_scalars(%itup_138) : !cute.int_tuple<"?">
    %53 = cute.get_stride(%lay_129) : (!cute.layout<"((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">) -> !cute.stride<"((0,1@1,0),(1@0,512@1,1@2))">
    %e0_139, %e1_140, %e2_141, %e3_142, %e4_143, %e5_144 = cute.get_leaves(%53) : !cute.stride<"((0,1@1,0),(1@0,512@1,1@2))">
    %54 = cute.get_shape(%lay_22) : (!cute.layout<"(128,4):(4,1)">) -> !cute.shape<"(128,4)">
    %e0_145, %e1_146 = cute.get_leaves(%54) : !cute.shape<"(128,4)">
    %55 = cute.get_stride(%lay_22) : (!cute.layout<"(128,4):(4,1)">) -> !cute.stride<"(4,1)">
    %e0_147, %e1_148 = cute.get_leaves(%55) : !cute.stride<"(4,1)">
    %56 = cute.get_shape(%lay_22) : (!cute.layout<"(128,4):(4,1)">) -> !cute.shape<"(128,4)">
    %e0_149, %e1_150 = cute.get_leaves(%56) : !cute.shape<"(128,4)">
    %57 = cute.get_stride(%lay_22) : (!cute.layout<"(128,4):(4,1)">) -> !cute.stride<"(4,1)">
    %e0_151, %e1_152 = cute.get_leaves(%57) : !cute.stride<"(4,1)">
    %58 = arith.index_cast %33 : i32 to index
    %c1 = arith.constant 1 : index
    %c128 = arith.constant 128 : index
    %c0_i32 = arith.constant 0 : i32
    gpu.launch_func  @kernels::@kernel_cutlass__convert_kernel_tensorptrf32gmemo1512100div5121_tensorptrf8E4M3FNgmemalign16o15121010div16512div16_tensor000o15121011010512112____Float32_Float8E4M3FN_0 blocks in (%58, %c1, %c1) threads in (%c128, %c1, %c1)  dynamic_shared_memory_size %c0_i32 args(%view_59 : !memref_gmem_f32_, %view_87 : !memref_gmem_f8E4M3FN, %view_69 : !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">, %15 : i32, %16 : i32, %17 : i32) {use_pdl = false}
    return
  }
}
