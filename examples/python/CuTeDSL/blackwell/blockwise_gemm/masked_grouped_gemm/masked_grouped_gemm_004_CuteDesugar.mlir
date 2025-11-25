!memref_gmem_f32_ = !cute.memref<f32, gmem, "((1,512,1),(?,?,?)):((0,?{i64},0),(?{i64},?{i64 div=512},1))">
!memref_gmem_f32_1 = !cute.memref<f32, gmem, "((1,512,1)):((0,?{i64},0))">
!memref_gmem_f32_2 = !cute.memref<f32, gmem, "(128,4):(?{i64 div=4},?{i64})">
!memref_gmem_f32_3 = !cute.memref<f32, gmem, "(4):(?{i64})">
!memref_gmem_f32_4 = !cute.memref<f32, gmem, "(4,1):(?{i64},0)">
!memref_gmem_f32_5 = !cute.memref<f32, gmem, "(4,(1)):(?{i64},(0))">
!memref_gmem_f32_6 = !cute.memref<f32, gmem, "(?,?,?):(?{i64},?{i64},1)">
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
    func.func public @kernel_cutlass__convert_kernel_tensorptrf32gmemo1512100div5121_tensorptrf8E4M3FNgmemalign16o15121010512_tensor000o15121011010512112____Float32_Float8E4M3FN_0(%arg0: !memref_gmem_f32_, %arg1: !memref_gmem_f8E4M3FN, %arg2: !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">, %arg3: i32, %arg4: i32, %arg5: i32) attributes {cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} {
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
      %slice = cute.slice(%lay_64, %coord) : !cute.layout<"((1,512,1),(?,?,?)):((0,?{i64},0),(?{i64},?{i64 div=512},1))">, !cute.coord<"(_,?)">
      %idx = cute.crd2idx(%coord, %lay_64) : (!cute.coord<"(_,?)">, !cute.layout<"((1,512,1),(?,?,?)):((0,?{i64},0),(?{i64},?{i64 div=512},1))">) -> !cute.int_tuple<"?{i64}">
      %iter_65 = cute.get_iter(%arg0) : !memref_gmem_f32_
      %ptr = cute.add_offset(%iter_65, %idx) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %view = cute.make_view(%ptr, %slice) : !memref_gmem_f32_1
      %iter_66 = cute.get_iter(%view) : !memref_gmem_f32_1
      %coord_67 = cute.make_coord(%27) : (i32) -> !cute.coord<"(_,?)">
      %lay_68 = cute.get_layout(%arg1) : !memref_gmem_f8E4M3FN
      %idx_69 = cute.crd2idx(%coord_67, %lay_68) : (!cute.coord<"(_,?)">, !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !cute.int_tuple<"?{i64}">
      %iter_70 = cute.get_iter(%arg1) : !memref_gmem_f8E4M3FN
      %ptr_71 = cute.add_offset(%iter_70, %idx_69) : (!cute.ptr<f8E4M3FN, gmem, align<16>>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f8E4M3FN, gmem>
      %view_72 = cute.make_view(%ptr_71) : !memref_gmem_f8E4M3FN1
      %iter_73 = cute.get_iter(%view_72) : !memref_gmem_f8E4M3FN1
      %coord_74 = cute.make_coord(%27) : (i32) -> !cute.coord<"(_,?)">
      %lay_75 = cute.get_layout(%arg2) : !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">
      %idx_76 = cute.crd2idx(%coord_74, %lay_75) : (!cute.coord<"(_,?)">, !cute.layout<"((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">) -> !cute.int_tuple<"(?,?{div=512},?)">
      %iter_77 = cute.get_iter(%arg2) : !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">
      %tup = cute.add_offset(%iter_77, %idx_76) : (!cute.int_tuple<"(0,0,0)">, !cute.int_tuple<"(?,?{div=512},?)">) -> !cute.int_tuple<"(?,?{div=512},?)">
      %view_78 = cute.make_view(%tup) : !cute.coord_tensor<"(?,?{div=512},?)", "((1,512,1)):((0,1@1,0))">
      %iter_79 = cute.get_iter(%view_78) : !cute.coord_tensor<"(?,?{div=512},?)", "((1,512,1)):((0,1@1,0))">
      %e0_80, %e1_81, %e2_82 = cute.get_leaves(%iter_79) : !cute.int_tuple<"(?,?{div=512},?)">
      %28 = cute.get_scalars(%e0_80) : !cute.int_tuple<"?">
      %29 = cute.get_scalars(%e1_81) : !cute.int_tuple<"?{div=512}">
      %30 = cute.get_scalars(%e2_82) : !cute.int_tuple<"?">
      %iter_83 = cute.get_iter(%view) : !memref_gmem_f32_1
      %lay_84 = cute.get_layout(%view) : !memref_gmem_f32_1
      %31 = cute.get_scalars(%lay_84) <{only_dynamic}> : !cute.layout<"((1,512,1)):((0,?{i64},0))">
      %c4_i64 = arith.constant 4 : i64
      %32 = arith.muli %31, %c4_i64 : i64
      %shape = cute.make_shape() : () -> !cute.shape<"(128,4)">
      %iv = cute.assume(%32) : (i64) -> !cute.i64<divby 4>
      %stride = cute.make_stride(%iv, %31) : (!cute.i64<divby 4>, i64) -> !cute.stride<"(?{i64 div=4},?{i64})">
      %lay_85 = cute.make_layout(%shape, %stride) : !cute.layout<"(128,4):(?{i64 div=4},?{i64})">
      %view_86 = cute.make_view(%iter_83, %lay_85) : !memref_gmem_f32_2
      %iter_87 = cute.get_iter(%view_86) : !memref_gmem_f32_2
      %iter_88 = cute.get_iter(%view_72) : !memref_gmem_f8E4M3FN1
      %view_89 = cute.make_view(%iter_88) : !memref_gmem_f8E4M3FN2
      %iter_90 = cute.get_iter(%view_89) : !memref_gmem_f8E4M3FN2
      %iter_91 = cute.get_iter(%view_78) : !cute.coord_tensor<"(?,?{div=512},?)", "((1,512,1)):((0,1@1,0))">
      %view_92 = cute.make_view(%iter_91) : !cute.coord_tensor<"(?,?{div=512},?)", "(128,4):(4@1,1@1)">
      %iter_93 = cute.get_iter(%view_92) : !cute.coord_tensor<"(?,?{div=512},?)", "(128,4):(4@1,1@1)">
      %e0_94, %e1_95, %e2_96 = cute.get_leaves(%iter_93) : !cute.int_tuple<"(?,?{div=512},?)">
      %33 = cute.get_scalars(%e0_94) : !cute.int_tuple<"?">
      %34 = cute.get_scalars(%e1_95) : !cute.int_tuple<"?{div=512}">
      %35 = cute.get_scalars(%e2_96) : !cute.int_tuple<"?">
      %coord_97 = cute.make_coord(%26) : (i32) -> !cute.coord<"(?,_)">
      %lay_98 = cute.get_layout(%view_86) : !memref_gmem_f32_2
      %slice_99 = cute.slice(%lay_98, %coord_97) : !cute.layout<"(128,4):(?{i64 div=4},?{i64})">, !cute.coord<"(?,_)">
      %idx_100 = cute.crd2idx(%coord_97, %lay_98) : (!cute.coord<"(?,_)">, !cute.layout<"(128,4):(?{i64 div=4},?{i64})">) -> !cute.int_tuple<"?{i64 div=4}">
      %iter_101 = cute.get_iter(%view_86) : !memref_gmem_f32_2
      %ptr_102 = cute.add_offset(%iter_101, %idx_100) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=4}">) -> !cute.ptr<f32, gmem>
      %view_103 = cute.make_view(%ptr_102, %slice_99) : !memref_gmem_f32_3
      %iter_104 = cute.get_iter(%view_103) : !memref_gmem_f32_3
      %coord_105 = cute.make_coord(%26) : (i32) -> !cute.coord<"(?,_)">
      %lay_106 = cute.get_layout(%view_89) : !memref_gmem_f8E4M3FN2
      %idx_107 = cute.crd2idx(%coord_105, %lay_106) : (!cute.coord<"(?,_)">, !cute.layout<"(128,4):(4,1)">) -> !cute.int_tuple<"?{div=4}">
      %iter_108 = cute.get_iter(%view_89) : !memref_gmem_f8E4M3FN2
      %ptr_109 = cute.add_offset(%iter_108, %idx_107) : (!cute.ptr<f8E4M3FN, gmem>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f8E4M3FN, gmem>
      %view_110 = cute.make_view(%ptr_109) : !memref_gmem_f8E4M3FN3
      %iter_111 = cute.get_iter(%view_110) : !memref_gmem_f8E4M3FN3
      %coord_112 = cute.make_coord(%26) : (i32) -> !cute.coord<"(?,_)">
      %lay_113 = cute.get_layout(%view_92) : !cute.coord_tensor<"(?,?{div=512},?)", "(128,4):(4@1,1@1)">
      %idx_114 = cute.crd2idx(%coord_112, %lay_113) : (!cute.coord<"(?,_)">, !cute.layout<"(128,4):(4@1,1@1)">) -> !cute.int_tuple<"(0,?{div=4})">
      %iter_115 = cute.get_iter(%view_92) : !cute.coord_tensor<"(?,?{div=512},?)", "(128,4):(4@1,1@1)">
      %tup_116 = cute.add_offset(%iter_115, %idx_114) : (!cute.int_tuple<"(?,?{div=512},?)">, !cute.int_tuple<"(0,?{div=4})">) -> !cute.int_tuple<"(?,?{div=4},?)">
      %view_117 = cute.make_view(%tup_116) : !cute.coord_tensor<"(?,?{div=4},?)", "(4):(1@1)">
      %iter_118 = cute.get_iter(%view_117) : !cute.coord_tensor<"(?,?{div=4},?)", "(4):(1@1)">
      %e0_119, %e1_120, %e2_121 = cute.get_leaves(%iter_118) : !cute.int_tuple<"(?,?{div=4},?)">
      %36 = cute.get_scalars(%e0_119) : !cute.int_tuple<"?">
      %37 = cute.get_scalars(%e1_120) : !cute.int_tuple<"?{div=4}">
      %38 = cute.get_scalars(%e2_121) : !cute.int_tuple<"?">
      %coord_122 = cute.make_coord() : () -> !cute.coord<"0">
      %lay_123 = cute.get_layout(%view_117) : !cute.coord_tensor<"(?,?{div=4},?)", "(4):(1@1)">
      %idx_124 = cute.crd2idx(%coord_122, %lay_123) : (!cute.coord<"0">, !cute.layout<"(4):(1@1)">) -> !cute.int_tuple<"(0,0)">
      %iter_125 = cute.get_iter(%view_117) : !cute.coord_tensor<"(?,?{div=4},?)", "(4):(1@1)">
      %tup_126 = cute.add_offset(%iter_125, %idx_124) : (!cute.int_tuple<"(?,?{div=4},?)">, !cute.int_tuple<"(0,0)">) -> !cute.int_tuple<"(?,?{div=4},?)">
      %view_127 = cute.make_view(%tup_126) : !cute.coord_tensor<"(?,?{div=4},?)", "():()">
      %iter_128 = cute.get_iter(%view_127) : !cute.coord_tensor<"(?,?{div=4},?)", "():()">
      %e0_129, %e1_130, %e2_131 = cute.get_leaves(%iter_128) : !cute.int_tuple<"(?,?{div=4},?)">
      %39 = cute.get_scalars(%e0_129) : !cute.int_tuple<"?">
      %40 = cute.get_scalars(%e1_130) : !cute.int_tuple<"?{div=4}">
      %41 = cute.get_scalars(%e2_131) : !cute.int_tuple<"?">
      %iter_132 = cute.get_iter(%view_127) : !cute.coord_tensor<"(?,?{div=4},?)", "():()">
      %e0_133, %e1_134, %e2_135 = cute.get_leaves(%iter_132) : !cute.int_tuple<"(?,?{div=4},?)">
      %42 = cute.get_scalars(%e0_133) : !cute.int_tuple<"?">
      %43 = cute.get_scalars(%e1_134) : !cute.int_tuple<"?{div=4}">
      %44 = cute.get_scalars(%e2_135) : !cute.int_tuple<"?">
      %iter_136 = cute.get_iter(%view_127) : !cute.coord_tensor<"(?,?{div=4},?)", "():()">
      %e0_137, %e1_138, %e2_139 = cute.get_leaves(%iter_136) : !cute.int_tuple<"(?,?{div=4},?)">
      %45 = cute.get_scalars(%e0_137) : !cute.int_tuple<"?">
      %46 = cute.get_scalars(%e1_138) : !cute.int_tuple<"?{div=4}">
      %47 = cute.get_scalars(%e2_139) : !cute.int_tuple<"?">
      %coord_140 = cute.make_coord(%e0_137, %e1_138, %e2_139) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=4}">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?{div=4},?)">
      %coord_141 = cute.make_coord(%arg3, %arg4, %arg5) : (i32, i32, i32) -> !cute.coord<"(?,?,?)">
      %48 = cute.elem_less(%coord_140, %coord_141) : !cute.coord<"(?,?{div=4},?)">, !cute.coord<"(?,?,?)">
      scf.if %48 {
        %49 = cute.get_shape(%0) : (!cute.layout<"(128,4):(4,1)">) -> !cute.shape<"(128,4)">
        %e0_142, %e1_143 = cute.get_leaves(%49) : !cute.shape<"(128,4)">
        %50 = cute.get_shape(%0) : (!cute.layout<"(128,4):(4,1)">) -> !cute.shape<"(128,4)">
        %e0_144, %e1_145 = cute.get_leaves(%50) : !cute.shape<"(128,4)">
        %51 = cute.get(%0) <{mode = [1]}> : !cute.layout<"(128,4):(4,1)"> -> !cute.layout<"4:1">
        %rmem = cute.memref.alloca(%51) : !memref_rmem_f32_
        %iter_146 = cute.get_iter(%rmem) : !memref_rmem_f32_
        %iter_147 = cute.get_iter(%rmem) : !memref_rmem_f32_
        %52 = cute.get_shape(%1) : (!cute.layout<"(128,4):(4,1)">) -> !cute.shape<"(128,4)">
        %e0_148, %e1_149 = cute.get_leaves(%52) : !cute.shape<"(128,4)">
        %53 = cute.get_shape(%1) : (!cute.layout<"(128,4):(4,1)">) -> !cute.shape<"(128,4)">
        %e0_150, %e1_151 = cute.get_leaves(%53) : !cute.shape<"(128,4)">
        %54 = cute.get(%1) <{mode = [1]}> : !cute.layout<"(128,4):(4,1)"> -> !cute.layout<"4:1">
        %rmem_152 = cute.memref.alloca(%54) : !memref_rmem_f8E4M3FN
        %iter_153 = cute.get_iter(%rmem_152) : !memref_rmem_f8E4M3FN
        %iter_154 = cute.get_iter(%rmem_152) : !memref_rmem_f8E4M3FN
        %atom = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<f32>
        %lay_155 = cute.get_layout(%view_103) : !memref_gmem_f32_3
        %55 = cute.get_shape(%lay_155) : (!cute.layout<"(4):(?{i64})">) -> !cute.shape<"(4)">
        %e0_156 = cute.get_leaves(%55) : !cute.shape<"(4)">
        %lay_157 = cute.get_layout(%rmem) : !memref_rmem_f32_
        %56 = cute.get_shape(%lay_157) : (!cute.layout<"4:1">) -> !cute.shape<"4">
        %e0_158 = cute.get_leaves(%56) : !cute.shape<"4">
        %lay_159 = cute.get_layout(%view_103) : !memref_gmem_f32_3
        %shape_160 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_161 = cute.make_layout() : !cute.layout<"1:0">
        %append = cute.append_to_rank<2> (%lay_159, %lay_161) : !cute.layout<"(4):(?{i64})">, !cute.layout<"1:0">
        %view_162 = cute.make_view(%iter_104, %append) : !memref_gmem_f32_4
        %iter_163 = cute.get_iter(%view_162) : !memref_gmem_f32_4
        %lay_164 = cute.get_layout(%view_162) : !memref_gmem_f32_4
        %57 = cute.get_shape(%lay_164) : (!cute.layout<"(4,1):(?{i64},0)">) -> !cute.shape<"(4,1)">
        %e0_165, %e1_166 = cute.get_leaves(%57) : !cute.shape<"(4,1)">
        %iter_167 = cute.get_iter(%view_162) : !memref_gmem_f32_4
        %lay_168 = cute.get_layout(%view_162) : !memref_gmem_f32_4
        %58 = cute.get_scalars(%lay_168) <{only_dynamic}> : !cute.layout<"(4,1):(?{i64},0)">
        %shape_169 = cute.make_shape() : () -> !cute.shape<"(4,(1))">
        %stride_170 = cute.make_stride(%58) : (i64) -> !cute.stride<"(?{i64},(0))">
        %lay_171 = cute.make_layout(%shape_169, %stride_170) : !cute.layout<"(4,(1)):(?{i64},(0))">
        %view_172 = cute.make_view(%iter_167, %lay_171) : !memref_gmem_f32_5
        %iter_173 = cute.get_iter(%view_172) : !memref_gmem_f32_5
        %iter_174 = cute.get_iter(%view_172) : !memref_gmem_f32_5
        %lay_175 = cute.get_layout(%rmem) : !memref_rmem_f32_
        %shape_176 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_177 = cute.make_layout() : !cute.layout<"1:0">
        %append_178 = cute.append_to_rank<2> (%lay_175, %lay_177) : !cute.layout<"4:1">, !cute.layout<"1:0">
        %view_179 = cute.make_view(%iter_147, %append_178) : !memref_rmem_f32_1
        %iter_180 = cute.get_iter(%view_179) : !memref_rmem_f32_1
        %lay_181 = cute.get_layout(%view_179) : !memref_rmem_f32_1
        %59 = cute.get_shape(%lay_181) : (!cute.layout<"(4,1):(1,0)">) -> !cute.shape<"(4,1)">
        %e0_182, %e1_183 = cute.get_leaves(%59) : !cute.shape<"(4,1)">
        %iter_184 = cute.get_iter(%view_179) : !memref_rmem_f32_1
        %view_185 = cute.make_view(%iter_184) : !memref_rmem_f32_2
        %iter_186 = cute.get_iter(%view_185) : !memref_rmem_f32_2
        %iter_187 = cute.get_iter(%view_185) : !memref_rmem_f32_2
        %lay_188 = cute.get_layout(%view_172) : !memref_gmem_f32_5
        %60 = cute.get_shape(%lay_188) : (!cute.layout<"(4,(1)):(?{i64},(0))">) -> !cute.shape<"(4,(1))">
        %e0_189, %e1_190 = cute.get_leaves(%60) : !cute.shape<"(4,(1))">
        %lay_191 = cute.get_layout(%view_185) : !memref_rmem_f32_2
        %61 = cute.get_shape(%lay_191) : (!cute.layout<"(4,(1)):(1,(0))">) -> !cute.shape<"(4,(1))">
        %e0_192, %e1_193 = cute.get_leaves(%61) : !cute.shape<"(4,(1))">
        %lay_194 = cute.get_layout(%view_172) : !memref_gmem_f32_5
        %sz = cute.size(%lay_194) <{mode = [1]}> : (!cute.layout<"(4,(1)):(?{i64},(0))">) -> !cute.int_tuple<"1">
        %e0_195 = cute.get_leaves(%sz) : !cute.int_tuple<"1">
        %lay_196 = cute.get_layout(%view_185) : !memref_rmem_f32_2
        %sz_197 = cute.size(%lay_196) <{mode = [1]}> : (!cute.layout<"(4,(1)):(1,(0))">) -> !cute.int_tuple<"1">
        %e0_198 = cute.get_leaves(%sz_197) : !cute.int_tuple<"1">
        %62 = cute.static : !cute.layout<"1:0">
        %iter_199 = cute.get_iter(%view_172) : !memref_gmem_f32_5
        %iter_200 = cute.get_iter(%view_185) : !memref_rmem_f32_2
        %lay_201 = cute.get_layout(%view_172) : !memref_gmem_f32_5
        %lay_202 = cute.get_layout(%view_185) : !memref_rmem_f32_2
        %append_203 = cute.append_to_rank<2> (%lay_201, %62) : !cute.layout<"(4,(1)):(?{i64},(0))">, !cute.layout<"1:0">
        %append_204 = cute.append_to_rank<2> (%lay_202, %62) : !cute.layout<"(4,(1)):(1,(0))">, !cute.layout<"1:0">
        %63 = cute.get_scalars(%append_203) <{only_dynamic}> : !cute.layout<"(4,(1)):(?{i64},(0))">
        %shape_205 = cute.make_shape() : () -> !cute.shape<"(4,((1)))">
        %stride_206 = cute.make_stride(%63) : (i64) -> !cute.stride<"(?{i64},((0)))">
        %lay_207 = cute.make_layout(%shape_205, %stride_206) : !cute.layout<"(4,((1))):(?{i64},((0)))">
        %lay_208 = cute.make_layout() : !cute.layout<"(4,((1))):(1,((0)))">
        %sz_209 = cute.size(%lay_207) <{mode = [1]}> : (!cute.layout<"(4,((1))):(?{i64},((0)))">) -> !cute.int_tuple<"1">
        %64 = cute.get_scalars(%sz_209) : !cute.int_tuple<"1">
        %c0_i32 = arith.constant 0 : i32
        %c1_i32 = arith.constant 1 : i32
        scf.for %arg6 = %c0_i32 to %64 step %c1_i32  : i32 {
          %coord_269 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
          %slice_270 = cute.slice(%lay_207, %coord_269) : !cute.layout<"(4,((1))):(?{i64},((0)))">, !cute.coord<"(_,?)">
          %idx_271 = cute.crd2idx(%coord_269, %lay_207) : (!cute.coord<"(_,?)">, !cute.layout<"(4,((1))):(?{i64},((0)))">) -> !cute.int_tuple<"0">
          %ptr_272 = cute.add_offset(%iter_199, %idx_271) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<f32, gmem>
          %view_273 = cute.make_view(%ptr_272, %slice_270) : !memref_gmem_f32_3
          %slice_274 = cute.slice(%lay_208, %coord_269) : !cute.layout<"(4,((1))):(1,((0)))">, !cute.coord<"(_,?)">
          %idx_275 = cute.crd2idx(%coord_269, %lay_208) : (!cute.coord<"(_,?)">, !cute.layout<"(4,((1))):(1,((0)))">) -> !cute.int_tuple<"0">
          %ptr_276 = cute.add_offset(%iter_200, %idx_275) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, rmem, align<32>>
          %view_277 = cute.make_view(%ptr_276, %slice_274) : !memref_rmem_f32_3
          cute.copy_atom_call(%atom, %view_273, %view_277) : (!cute_nvgpu.atom.universal_copy<f32>, !memref_gmem_f32_3, !memref_rmem_f32_3) -> ()
        } {llvm.loop_annotation = #loop_annotation}
        %65 = cute.memref.load_vec %rmem, row_major : !memref_rmem_f32_
        %66 = nvgpu.cvt_fptrunc %65 : vector<4xf32> to vector<4xf8E4M3FN>
        %lay_210 = cute.get_layout(%rmem_152) : !memref_rmem_f8E4M3FN
        %67 = cute.get_shape(%lay_210) : (!cute.layout<"4:1">) -> !cute.shape<"4">
        %e0_211 = cute.get_leaves(%67) : !cute.shape<"4">
        %int_tuple = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
        %sz_212 = cute.size(%int_tuple) : (!cute.int_tuple<"4">) -> !cute.int_tuple<"4">
        %e0_213 = cute.get_leaves(%sz_212) : !cute.int_tuple<"4">
        %int_tuple_214 = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
        %sz_215 = cute.size(%int_tuple_214) : (!cute.int_tuple<"4">) -> !cute.int_tuple<"4">
        %e0_216 = cute.get_leaves(%sz_215) : !cute.int_tuple<"4">
        cute.memref.store_vec %66, %rmem_152, row_major : !memref_rmem_f8E4M3FN
        %atom_217 = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<f8E4M3FN>
        %lay_218 = cute.get_layout(%view_110) : !memref_gmem_f8E4M3FN3
        %68 = cute.get_shape(%lay_218) : (!cute.layout<"(4):(1)">) -> !cute.shape<"(4)">
        %e0_219 = cute.get_leaves(%68) : !cute.shape<"(4)">
        %lay_220 = cute.get_layout(%rmem_152) : !memref_rmem_f8E4M3FN
        %shape_221 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_222 = cute.make_layout() : !cute.layout<"1:0">
        %append_223 = cute.append_to_rank<2> (%lay_220, %lay_222) : !cute.layout<"4:1">, !cute.layout<"1:0">
        %view_224 = cute.make_view(%iter_154, %append_223) : !memref_rmem_f8E4M3FN1
        %iter_225 = cute.get_iter(%view_224) : !memref_rmem_f8E4M3FN1
        %lay_226 = cute.get_layout(%view_224) : !memref_rmem_f8E4M3FN1
        %69 = cute.get_shape(%lay_226) : (!cute.layout<"(4,1):(1,0)">) -> !cute.shape<"(4,1)">
        %e0_227, %e1_228 = cute.get_leaves(%69) : !cute.shape<"(4,1)">
        %iter_229 = cute.get_iter(%view_224) : !memref_rmem_f8E4M3FN1
        %view_230 = cute.make_view(%iter_229) : !memref_rmem_f8E4M3FN2
        %iter_231 = cute.get_iter(%view_230) : !memref_rmem_f8E4M3FN2
        %iter_232 = cute.get_iter(%view_230) : !memref_rmem_f8E4M3FN2
        %lay_233 = cute.get_layout(%view_110) : !memref_gmem_f8E4M3FN3
        %shape_234 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_235 = cute.make_layout() : !cute.layout<"1:0">
        %append_236 = cute.append_to_rank<2> (%lay_233, %lay_235) : !cute.layout<"(4):(1)">, !cute.layout<"1:0">
        %view_237 = cute.make_view(%iter_111, %append_236) : !memref_gmem_f8E4M3FN4
        %iter_238 = cute.get_iter(%view_237) : !memref_gmem_f8E4M3FN4
        %lay_239 = cute.get_layout(%view_237) : !memref_gmem_f8E4M3FN4
        %70 = cute.get_shape(%lay_239) : (!cute.layout<"(4,1):(1,0)">) -> !cute.shape<"(4,1)">
        %e0_240, %e1_241 = cute.get_leaves(%70) : !cute.shape<"(4,1)">
        %iter_242 = cute.get_iter(%view_237) : !memref_gmem_f8E4M3FN4
        %view_243 = cute.make_view(%iter_242) : !memref_gmem_f8E4M3FN5
        %iter_244 = cute.get_iter(%view_243) : !memref_gmem_f8E4M3FN5
        %iter_245 = cute.get_iter(%view_243) : !memref_gmem_f8E4M3FN5
        %lay_246 = cute.get_layout(%view_230) : !memref_rmem_f8E4M3FN2
        %71 = cute.get_shape(%lay_246) : (!cute.layout<"(4,(1)):(1,(0))">) -> !cute.shape<"(4,(1))">
        %e0_247, %e1_248 = cute.get_leaves(%71) : !cute.shape<"(4,(1))">
        %lay_249 = cute.get_layout(%view_243) : !memref_gmem_f8E4M3FN5
        %72 = cute.get_shape(%lay_249) : (!cute.layout<"(4,(1)):(1,(0))">) -> !cute.shape<"(4,(1))">
        %e0_250, %e1_251 = cute.get_leaves(%72) : !cute.shape<"(4,(1))">
        %lay_252 = cute.get_layout(%view_230) : !memref_rmem_f8E4M3FN2
        %sz_253 = cute.size(%lay_252) <{mode = [1]}> : (!cute.layout<"(4,(1)):(1,(0))">) -> !cute.int_tuple<"1">
        %e0_254 = cute.get_leaves(%sz_253) : !cute.int_tuple<"1">
        %lay_255 = cute.get_layout(%view_243) : !memref_gmem_f8E4M3FN5
        %sz_256 = cute.size(%lay_255) <{mode = [1]}> : (!cute.layout<"(4,(1)):(1,(0))">) -> !cute.int_tuple<"1">
        %e0_257 = cute.get_leaves(%sz_256) : !cute.int_tuple<"1">
        %73 = cute.static : !cute.layout<"1:0">
        %iter_258 = cute.get_iter(%view_230) : !memref_rmem_f8E4M3FN2
        %iter_259 = cute.get_iter(%view_243) : !memref_gmem_f8E4M3FN5
        %lay_260 = cute.get_layout(%view_230) : !memref_rmem_f8E4M3FN2
        %lay_261 = cute.get_layout(%view_243) : !memref_gmem_f8E4M3FN5
        %append_262 = cute.append_to_rank<2> (%lay_260, %73) : !cute.layout<"(4,(1)):(1,(0))">, !cute.layout<"1:0">
        %append_263 = cute.append_to_rank<2> (%lay_261, %73) : !cute.layout<"(4,(1)):(1,(0))">, !cute.layout<"1:0">
        %lay_264 = cute.make_layout() : !cute.layout<"(4,((1))):(1,((0)))">
        %lay_265 = cute.make_layout() : !cute.layout<"(4,((1))):(1,((0)))">
        %sz_266 = cute.size(%lay_264) <{mode = [1]}> : (!cute.layout<"(4,((1))):(1,((0)))">) -> !cute.int_tuple<"1">
        %74 = cute.get_scalars(%sz_266) : !cute.int_tuple<"1">
        %c0_i32_267 = arith.constant 0 : i32
        %c1_i32_268 = arith.constant 1 : i32
        scf.for %arg6 = %c0_i32_267 to %74 step %c1_i32_268  : i32 {
          %coord_269 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"(_,?)">
          %slice_270 = cute.slice(%lay_264, %coord_269) : !cute.layout<"(4,((1))):(1,((0)))">, !cute.coord<"(_,?)">
          %idx_271 = cute.crd2idx(%coord_269, %lay_264) : (!cute.coord<"(_,?)">, !cute.layout<"(4,((1))):(1,((0)))">) -> !cute.int_tuple<"0">
          %ptr_272 = cute.add_offset(%iter_258, %idx_271) : (!cute.ptr<f8E4M3FN, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f8E4M3FN, rmem, align<32>>
          %view_273 = cute.make_view(%ptr_272, %slice_270) : !memref_rmem_f8E4M3FN3
          %slice_274 = cute.slice(%lay_265, %coord_269) : !cute.layout<"(4,((1))):(1,((0)))">, !cute.coord<"(_,?)">
          %idx_275 = cute.crd2idx(%coord_269, %lay_265) : (!cute.coord<"(_,?)">, !cute.layout<"(4,((1))):(1,((0)))">) -> !cute.int_tuple<"0">
          %ptr_276 = cute.add_offset(%iter_259, %idx_275) : (!cute.ptr<f8E4M3FN, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<f8E4M3FN, gmem>
          %view_277 = cute.make_view(%ptr_276, %slice_274) : !memref_gmem_f8E4M3FN3
          cute.copy_atom_call(%atom_217, %view_273, %view_277) : (!cute_nvgpu.atom.universal_copy<f8E4M3FN>, !memref_rmem_f8E4M3FN3, !memref_gmem_f8E4M3FN3) -> ()
        } {llvm.loop_annotation = #loop_annotation}
      }
      return
    }
  }
  func.func @cutlass__convert_Tensorgmemoi64i641_Tensorgmemoi641i64_1_4(%arg0: !memref_gmem_f32_6, %arg1: !memref_gmem_f8E4M3FN6) attributes {llvm.emit_c_interface} {
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
    %14 = cute.get_shape(%lay_23) : (!cute.layout<"(?,?,?):(?{i64},?{i64},1)">) -> !cute.shape<"(?,?,?)">
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
    %19 = cute.get_shape(%lay_35) : (!cute.layout<"(?,?,?):(?{i64},?{i64},1)">) -> !cute.shape<"(?,?,?)">
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
    %27:5 = cute.get_scalars(%lay_53) <{only_dynamic}> : !cute.layout<"(?,?,?):(?{i64},?{i64},1)">
    %c512_i32 = arith.constant 512 : i32
    %28 = arith.ceildivsi %27#1, %c512_i32 : i32
    %c512_i64 = arith.constant 512 : i64
    %29 = arith.muli %27#4, %c512_i64 : i64
    %shape_54 = cute.make_shape(%27#0, %28, %27#2) : (i32, i32, i32) -> !cute.shape<"((1,512,1),(?,?,?))">
    %iv = cute.assume(%29) : (i64) -> !cute.i64<divby 512>
    %stride_55 = cute.make_stride(%27#4, %27#3, %iv) : (i64, i64, !cute.i64<divby 512>) -> !cute.stride<"((0,?{i64},0),(?{i64},?{i64 div=512},1))">
    %lay_56 = cute.make_layout(%shape_54, %stride_55) : !cute.layout<"((1,512,1),(?,?,?)):((0,?{i64},0),(?{i64},?{i64 div=512},1))">
    %view = cute.make_view(%iter_52, %lay_56) : !memref_gmem_f32_
    %iter_57 = cute.get_iter(%view) : !memref_gmem_f32_
    %iter_58 = cute.get_iter(%view) : !memref_gmem_f32_
    %tile_59 = cute.make_tile() : () -> !cute.tile<"[1:0;512:1;1:0]">
    %iter_60 = cute.get_iter(%18) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">
    %lay_61 = cute.get_layout(%18) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">
    %30:3 = cute.get_scalars(%lay_61) <{only_dynamic}> : !cute.layout<"(?,?,?):(1@0,1@1,1@2)">
    %c512_i32_62 = arith.constant 512 : i32
    %31 = arith.ceildivsi %30#1, %c512_i32_62 : i32
    %shape_63 = cute.make_shape(%30#0, %31, %30#2) : (i32, i32, i32) -> !cute.shape<"((1,512,1),(?,?,?))">
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
    %32:5 = cute.get_scalars(%lay_77) <{only_dynamic}> : !cute.layout<"(?,?,?):(?{i64},1,?{i64})">
    %c512_i32_78 = arith.constant 512 : i32
    %33 = arith.ceildivsi %32#1, %c512_i32_78 : i32
    %shape_79 = cute.make_shape(%32#0, %33, %32#2) : (i32, i32, i32) -> !cute.shape<"((1,512,1),(?,?,?))">
    %stride_80 = cute.make_stride(%32#3, %32#4) : (i64, i64) -> !cute.stride<"((0,1,0),(?{i64},512,?{i64}))">
    %lay_81 = cute.make_layout(%shape_79, %stride_80) : !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">
    %view_82 = cute.make_view(%iter_76, %lay_81) : !memref_gmem_f8E4M3FN
    %iter_83 = cute.get_iter(%view_82) : !memref_gmem_f8E4M3FN
    %iter_84 = cute.get_iter(%view_82) : !memref_gmem_f8E4M3FN
    %lay_85 = cute.get_layout(%view) : !memref_gmem_f32_
    %sz_86 = cute.size(%lay_85) <{mode = [1]}> : (!cute.layout<"((1,512,1),(?,?,?)):((0,?{i64},0),(?{i64},?{i64 div=512},1))">) -> !cute.int_tuple<"?">
    %e0_87 = cute.get_leaves(%sz_86) : !cute.int_tuple<"?">
    %34 = cute.get_scalars(%e0_87) : !cute.int_tuple<"?">
    %sz_88 = cute.size(%lay_22) <{mode = [0]}> : (!cute.layout<"(128,4):(4,1)">) -> !cute.int_tuple<"128">
    %e0_89 = cute.get_leaves(%sz_88) : !cute.int_tuple<"128">
    %lay_90 = cute.get_layout(%view) : !memref_gmem_f32_
    %35 = cute.get_shape(%lay_90) : (!cute.layout<"((1,512,1),(?,?,?)):((0,?{i64},0),(?{i64},?{i64 div=512},1))">) -> !cute.shape<"((1,512,1),(?,?,?))">
    %e0_91, %e1_92, %e2_93, %e3, %e4, %e5 = cute.get_leaves(%35) : !cute.shape<"((1,512,1),(?,?,?))">
    %itup_94 = cute.to_int_tuple(%e3) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %36 = cute.get_scalars(%itup_94) : !cute.int_tuple<"?">
    %itup_95 = cute.to_int_tuple(%e4) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %37 = cute.get_scalars(%itup_95) : !cute.int_tuple<"?">
    %itup_96 = cute.to_int_tuple(%e5) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %38 = cute.get_scalars(%itup_96) : !cute.int_tuple<"?">
    %39 = cute.get_stride(%lay_90) : (!cute.layout<"((1,512,1),(?,?,?)):((0,?{i64},0),(?{i64},?{i64 div=512},1))">) -> !cute.stride<"((0,?{i64},0),(?{i64},?{i64 div=512},1))">
    %e0_97, %e1_98, %e2_99, %e3_100, %e4_101, %e5_102 = cute.get_leaves(%39) : !cute.stride<"((0,?{i64},0),(?{i64},?{i64 div=512},1))">
    %itup_103 = cute.to_int_tuple(%e1_98) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
    %40 = cute.get_scalars(%itup_103) : !cute.int_tuple<"?{i64}">
    %itup_104 = cute.to_int_tuple(%e3_100) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
    %41 = cute.get_scalars(%itup_104) : !cute.int_tuple<"?{i64}">
    %itup_105 = cute.to_int_tuple(%e4_101) : !cute.stride<"?{i64 div=512}"> to !cute.int_tuple<"?{i64 div=512}">
    %42 = cute.get_scalars(%itup_105) : !cute.int_tuple<"?{i64 div=512}">
    %lay_106 = cute.get_layout(%view_82) : !memref_gmem_f8E4M3FN
    %43 = cute.get_shape(%lay_106) : (!cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !cute.shape<"((1,512,1),(?,?,?))">
    %e0_107, %e1_108, %e2_109, %e3_110, %e4_111, %e5_112 = cute.get_leaves(%43) : !cute.shape<"((1,512,1),(?,?,?))">
    %itup_113 = cute.to_int_tuple(%e3_110) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %44 = cute.get_scalars(%itup_113) : !cute.int_tuple<"?">
    %itup_114 = cute.to_int_tuple(%e4_111) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %45 = cute.get_scalars(%itup_114) : !cute.int_tuple<"?">
    %itup_115 = cute.to_int_tuple(%e5_112) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %46 = cute.get_scalars(%itup_115) : !cute.int_tuple<"?">
    %47 = cute.get_stride(%lay_106) : (!cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !cute.stride<"((0,1,0),(?{i64},512,?{i64}))">
    %e0_116, %e1_117, %e2_118, %e3_119, %e4_120, %e5_121 = cute.get_leaves(%47) : !cute.stride<"((0,1,0),(?{i64},512,?{i64}))">
    %itup_122 = cute.to_int_tuple(%e3_119) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
    %48 = cute.get_scalars(%itup_122) : !cute.int_tuple<"?{i64}">
    %itup_123 = cute.to_int_tuple(%e5_121) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
    %49 = cute.get_scalars(%itup_123) : !cute.int_tuple<"?{i64}">
    %lay_124 = cute.get_layout(%view_66) : !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">
    %50 = cute.get_shape(%lay_124) : (!cute.layout<"((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">) -> !cute.shape<"((1,512,1),(?,?,?))">
    %e0_125, %e1_126, %e2_127, %e3_128, %e4_129, %e5_130 = cute.get_leaves(%50) : !cute.shape<"((1,512,1),(?,?,?))">
    %itup_131 = cute.to_int_tuple(%e3_128) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %51 = cute.get_scalars(%itup_131) : !cute.int_tuple<"?">
    %itup_132 = cute.to_int_tuple(%e4_129) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %52 = cute.get_scalars(%itup_132) : !cute.int_tuple<"?">
    %itup_133 = cute.to_int_tuple(%e5_130) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %53 = cute.get_scalars(%itup_133) : !cute.int_tuple<"?">
    %54 = cute.get_stride(%lay_124) : (!cute.layout<"((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">) -> !cute.stride<"((0,1@1,0),(1@0,512@1,1@2))">
    %e0_134, %e1_135, %e2_136, %e3_137, %e4_138, %e5_139 = cute.get_leaves(%54) : !cute.stride<"((0,1@1,0),(1@0,512@1,1@2))">
    %55 = cute.get_shape(%lay_22) : (!cute.layout<"(128,4):(4,1)">) -> !cute.shape<"(128,4)">
    %e0_140, %e1_141 = cute.get_leaves(%55) : !cute.shape<"(128,4)">
    %56 = cute.get_stride(%lay_22) : (!cute.layout<"(128,4):(4,1)">) -> !cute.stride<"(4,1)">
    %e0_142, %e1_143 = cute.get_leaves(%56) : !cute.stride<"(4,1)">
    %57 = cute.get_shape(%lay_22) : (!cute.layout<"(128,4):(4,1)">) -> !cute.shape<"(128,4)">
    %e0_144, %e1_145 = cute.get_leaves(%57) : !cute.shape<"(128,4)">
    %58 = cute.get_stride(%lay_22) : (!cute.layout<"(128,4):(4,1)">) -> !cute.stride<"(4,1)">
    %e0_146, %e1_147 = cute.get_leaves(%58) : !cute.stride<"(4,1)">
    %59 = arith.index_cast %34 : i32 to index
    %c1 = arith.constant 1 : index
    %c128 = arith.constant 128 : index
    %c0_i32 = arith.constant 0 : i32
    gpu.launch_func  @kernels::@kernel_cutlass__convert_kernel_tensorptrf32gmemo1512100div5121_tensorptrf8E4M3FNgmemalign16o15121010512_tensor000o15121011010512112____Float32_Float8E4M3FN_0 blocks in (%59, %c1, %c1) threads in (%c128, %c1, %c1)  dynamic_shared_memory_size %c0_i32 args(%view : !memref_gmem_f32_, %view_82 : !memref_gmem_f8E4M3FN, %view_66 : !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">, %15 : i32, %16 : i32, %17 : i32) {use_pdl = false}
    return
  }
}
