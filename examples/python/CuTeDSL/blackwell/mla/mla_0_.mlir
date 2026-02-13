!memref_gmem_f32_ = !cute.memref<f32, gmem, "((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">
!memref_gmem_f32_1 = !cute.memref<f32, gmem, "((1,512,1)):((0,1,0))">
!memref_gmem_f32_2 = !cute.memref<f32, gmem, "(128,4):(4,1)">
!memref_gmem_f32_3 = !cute.memref<f32, gmem, "(4):(1)">
!memref_gmem_f32_4 = !cute.memref<f32, gmem, "(4,1):(1,0)">
!memref_gmem_f32_5 = !cute.memref<f32, gmem, "(4,(1)):(1,(0))">
!memref_gmem_f32_6 = !cute.memref<f32, gmem, "(?,?,?):(?{i64},1,?{i64})">
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
!memref_rmem_f8E4M3FN = !cute.memref<f8E4M3FN, rmem, align<32>, "4:1">
!memref_rmem_f8E4M3FN1 = !cute.memref<f8E4M3FN, rmem, align<32>, "(4,1):(1,0)">
!memref_rmem_f8E4M3FN2 = !cute.memref<f8E4M3FN, rmem, align<32>, "(4,(1)):(1,(0))">
module attributes {gpu.container_module} {
  gpu.module @kernels {
    cuda.kernel @kernel_cutlass__convert_kernel_tensorptrf32gmemo15121010512_tensorptrf8E4M3FNgmemalign16o15121010div16512div16_tensor000o15121011010512112____Float32_Float8E4M3FN_0(%arg0: !memref_gmem_f32_, %arg1: !memref_gmem_f8E4M3FN, %arg2: !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">, %arg3: !cute.layout<"(128,4):(4,1)">, %arg4: !cute.layout<"(128,4):(4,1)">, %arg5: i32, %arg6: i32, %arg7: i32) attributes {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} {
      %iter = cute.get_iter(%arg0) : !memref_gmem_f32_
      %iter_0 = cute.get_iter(%arg1) : !memref_gmem_f8E4M3FN
      %iter_1 = cute.get_iter(%arg2) : !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">
      %e0, %e1, %e2 = cute.get_leaves(%iter_1) : !cute.int_tuple<"(0,0,0)">
      %iter_2 = cute.get_iter(%arg0) : !memref_gmem_f32_
      %iter_3 = cute.get_iter(%arg1) : !memref_gmem_f8E4M3FN
      %iter_4 = cute.get_iter(%arg2) : !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">
      %e0_5, %e1_6, %e2_7 = cute.get_leaves(%iter_4) : !cute.int_tuple<"(0,0,0)">
      %lay = cute.get_layout(%arg0) : !memref_gmem_f32_
      %0 = cute.get_shape(%lay) : (!cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !cute.shape<"((1,512,1),(?,?,?))">
      %e0_8, %e1_9, %e2_10, %e3, %e4, %e5 = cute.get_leaves(%0) : !cute.shape<"((1,512,1),(?,?,?))">
      %itup = cute.to_int_tuple(%e3) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %1 = cute.get_scalars(%itup) : !cute.int_tuple<"?">
      %itup_11 = cute.to_int_tuple(%e4) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %2 = cute.get_scalars(%itup_11) : !cute.int_tuple<"?">
      %itup_12 = cute.to_int_tuple(%e5) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %3 = cute.get_scalars(%itup_12) : !cute.int_tuple<"?">
      %4 = cute.get_stride(%lay) : (!cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !cute.stride<"((0,1,0),(?{i64},512,?{i64}))">
      %e0_13, %e1_14, %e2_15, %e3_16, %e4_17, %e5_18 = cute.get_leaves(%4) : !cute.stride<"((0,1,0),(?{i64},512,?{i64}))">
      %itup_19 = cute.to_int_tuple(%e3_16) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
      %5 = cute.get_scalars(%itup_19) : !cute.int_tuple<"?{i64}">
      %itup_20 = cute.to_int_tuple(%e5_18) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
      %6 = cute.get_scalars(%itup_20) : !cute.int_tuple<"?{i64}">
      %lay_21 = cute.get_layout(%arg1) : !memref_gmem_f8E4M3FN
      %7 = cute.get_shape(%lay_21) : (!cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{div=16},512,?{div=16}))">) -> !cute.shape<"((1,512,1),(?,?,?))">
      %e0_22, %e1_23, %e2_24, %e3_25, %e4_26, %e5_27 = cute.get_leaves(%7) : !cute.shape<"((1,512,1),(?,?,?))">
      %itup_28 = cute.to_int_tuple(%e3_25) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %8 = cute.get_scalars(%itup_28) : !cute.int_tuple<"?">
      %itup_29 = cute.to_int_tuple(%e4_26) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %9 = cute.get_scalars(%itup_29) : !cute.int_tuple<"?">
      %itup_30 = cute.to_int_tuple(%e5_27) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %10 = cute.get_scalars(%itup_30) : !cute.int_tuple<"?">
      %11 = cute.get_stride(%lay_21) : (!cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{div=16},512,?{div=16}))">) -> !cute.stride<"((0,1,0),(?{div=16},512,?{div=16}))">
      %e0_31, %e1_32, %e2_33, %e3_34, %e4_35, %e5_36 = cute.get_leaves(%11) : !cute.stride<"((0,1,0),(?{div=16},512,?{div=16}))">
      %itup_37 = cute.to_int_tuple(%e3_34) : !cute.stride<"?{div=16}"> to !cute.int_tuple<"?{div=16}">
      %12 = cute.get_scalars(%itup_37) : !cute.int_tuple<"?{div=16}">
      %itup_38 = cute.to_int_tuple(%e5_36) : !cute.stride<"?{div=16}"> to !cute.int_tuple<"?{div=16}">
      %13 = cute.get_scalars(%itup_38) : !cute.int_tuple<"?{div=16}">
      %lay_39 = cute.get_layout(%arg2) : !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">
      %14 = cute.get_shape(%lay_39) : (!cute.layout<"((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">) -> !cute.shape<"((1,512,1),(?,?,?))">
      %e0_40, %e1_41, %e2_42, %e3_43, %e4_44, %e5_45 = cute.get_leaves(%14) : !cute.shape<"((1,512,1),(?,?,?))">
      %itup_46 = cute.to_int_tuple(%e3_43) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %15 = cute.get_scalars(%itup_46) : !cute.int_tuple<"?">
      %itup_47 = cute.to_int_tuple(%e4_44) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %16 = cute.get_scalars(%itup_47) : !cute.int_tuple<"?">
      %itup_48 = cute.to_int_tuple(%e5_45) : !cute.shape<"?"> to !cute.int_tuple<"?">
      %17 = cute.get_scalars(%itup_48) : !cute.int_tuple<"?">
      %18 = cute.get_stride(%lay_39) : (!cute.layout<"((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">) -> !cute.stride<"((0,1@1,0),(1@0,512@1,1@2))">
      %e0_49, %e1_50, %e2_51, %e3_52, %e4_53, %e5_54 = cute.get_leaves(%18) : !cute.stride<"((0,1@1,0),(1@0,512@1,1@2))">
      %19 = cute.get_shape(%arg3) : (!cute.layout<"(128,4):(4,1)">) -> !cute.shape<"(128,4)">
      %e0_55, %e1_56 = cute.get_leaves(%19) : !cute.shape<"(128,4)">
      %20 = cute.get_stride(%arg3) : (!cute.layout<"(128,4):(4,1)">) -> !cute.stride<"(4,1)">
      %e0_57, %e1_58 = cute.get_leaves(%20) : !cute.stride<"(4,1)">
      %21 = cute.get_shape(%arg4) : (!cute.layout<"(128,4):(4,1)">) -> !cute.shape<"(128,4)">
      %e0_59, %e1_60 = cute.get_leaves(%21) : !cute.shape<"(128,4)">
      %22 = cute.get_stride(%arg4) : (!cute.layout<"(128,4):(4,1)">) -> !cute.stride<"(4,1)">
      %e0_61, %e1_62 = cute.get_leaves(%22) : !cute.stride<"(4,1)">
      %23 = nvvm.read.ptx.sreg.tid.x : i32
      %24 = nvvm.read.ptx.sreg.ctaid.x : i32
      %coord = cute.make_coord(%24) : (i32) -> !cute.coord<"(_,?)">
      %slice = cute.slice(%arg0, %coord) : !memref_gmem_f32_, !cute.coord<"(_,?)">
      %iter_63 = cute.get_iter(%slice) : !memref_gmem_f32_1
      %iter_64 = cute.get_iter(%slice) : !memref_gmem_f32_1
      %coord_65 = cute.make_coord(%24) : (i32) -> !cute.coord<"(_,?)">
      %slice_66 = cute.slice(%arg1, %coord_65) : !memref_gmem_f8E4M3FN, !cute.coord<"(_,?)">
      %iter_67 = cute.get_iter(%slice_66) : !memref_gmem_f8E4M3FN1
      %iter_68 = cute.get_iter(%slice_66) : !memref_gmem_f8E4M3FN1
      %coord_69 = cute.make_coord(%24) : (i32) -> !cute.coord<"(_,?)">
      %slice_70 = cute.slice(%arg2, %coord_69) : !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">, !cute.coord<"(_,?)">
      %iter_71 = cute.get_iter(%slice_70) : !cute.coord_tensor<"(?,?{div=512},?)", "((1,512,1)):((0,1@1,0))">
      %e0_72, %e1_73, %e2_74 = cute.get_leaves(%iter_71) : !cute.int_tuple<"(?,?{div=512},?)">
      %25 = cute.get_scalars(%e0_72) : !cute.int_tuple<"?">
      %26 = cute.get_scalars(%e1_73) : !cute.int_tuple<"?{div=512}">
      %27 = cute.get_scalars(%e2_74) : !cute.int_tuple<"?">
      %iter_75 = cute.get_iter(%slice_70) : !cute.coord_tensor<"(?,?{div=512},?)", "((1,512,1)):((0,1@1,0))">
      %e0_76, %e1_77, %e2_78 = cute.get_leaves(%iter_75) : !cute.int_tuple<"(?,?{div=512},?)">
      %28 = cute.get_scalars(%e0_76) : !cute.int_tuple<"?">
      %29 = cute.get_scalars(%e1_77) : !cute.int_tuple<"?{div=512}">
      %30 = cute.get_scalars(%e2_78) : !cute.int_tuple<"?">
      %31 = cute.composition(%slice, %arg3) : (!memref_gmem_f32_1, !cute.layout<"(128,4):(4,1)">) -> !memref_gmem_f32_2
      %iter_79 = cute.get_iter(%31) : !memref_gmem_f32_2
      %32 = cute.composition(%slice_66, %arg4) : (!memref_gmem_f8E4M3FN1, !cute.layout<"(128,4):(4,1)">) -> !memref_gmem_f8E4M3FN2
      %iter_80 = cute.get_iter(%32) : !memref_gmem_f8E4M3FN2
      %33 = cute.composition(%slice_70, %arg3) : (!cute.coord_tensor<"(?,?{div=512},?)", "((1,512,1)):((0,1@1,0))">, !cute.layout<"(128,4):(4,1)">) -> !cute.coord_tensor<"(?,?{div=512},?)", "(128,4):(4@1,1@1)">
      %iter_81 = cute.get_iter(%33) : !cute.coord_tensor<"(?,?{div=512},?)", "(128,4):(4@1,1@1)">
      %e0_82, %e1_83, %e2_84 = cute.get_leaves(%iter_81) : !cute.int_tuple<"(?,?{div=512},?)">
      %34 = cute.get_scalars(%e0_82) : !cute.int_tuple<"?">
      %35 = cute.get_scalars(%e1_83) : !cute.int_tuple<"?{div=512}">
      %36 = cute.get_scalars(%e2_84) : !cute.int_tuple<"?">
      %coord_85 = cute.make_coord(%23) : (i32) -> !cute.coord<"(?,_)">
      %slice_86 = cute.slice(%31, %coord_85) : !memref_gmem_f32_2, !cute.coord<"(?,_)">
      %iter_87 = cute.get_iter(%slice_86) : !memref_gmem_f32_3
      %iter_88 = cute.get_iter(%slice_86) : !memref_gmem_f32_3
      %coord_89 = cute.make_coord(%23) : (i32) -> !cute.coord<"(?,_)">
      %slice_90 = cute.slice(%32, %coord_89) : !memref_gmem_f8E4M3FN2, !cute.coord<"(?,_)">
      %iter_91 = cute.get_iter(%slice_90) : !memref_gmem_f8E4M3FN3
      %iter_92 = cute.get_iter(%slice_90) : !memref_gmem_f8E4M3FN3
      %coord_93 = cute.make_coord(%23) : (i32) -> !cute.coord<"(?,_)">
      %slice_94 = cute.slice(%33, %coord_93) : !cute.coord_tensor<"(?,?{div=512},?)", "(128,4):(4@1,1@1)">, !cute.coord<"(?,_)">
      %iter_95 = cute.get_iter(%slice_94) : !cute.coord_tensor<"(?,?{div=4},?)", "(4):(1@1)">
      %e0_96, %e1_97, %e2_98 = cute.get_leaves(%iter_95) : !cute.int_tuple<"(?,?{div=4},?)">
      %37 = cute.get_scalars(%e0_96) : !cute.int_tuple<"?">
      %38 = cute.get_scalars(%e1_97) : !cute.int_tuple<"?{div=4}">
      %39 = cute.get_scalars(%e2_98) : !cute.int_tuple<"?">
      %iter_99 = cute.get_iter(%slice_94) : !cute.coord_tensor<"(?,?{div=4},?)", "(4):(1@1)">
      %e0_100, %e1_101, %e2_102 = cute.get_leaves(%iter_99) : !cute.int_tuple<"(?,?{div=4},?)">
      %40 = cute.get_scalars(%e0_100) : !cute.int_tuple<"?">
      %41 = cute.get_scalars(%e1_101) : !cute.int_tuple<"?{div=4}">
      %42 = cute.get_scalars(%e2_102) : !cute.int_tuple<"?">
      %coord_103 = cute.make_coord() : () -> !cute.coord<"0">
      %slice_104 = cute.slice(%slice_94, %coord_103) : !cute.coord_tensor<"(?,?{div=4},?)", "(4):(1@1)">, !cute.coord<"0">
      %iter_105 = cute.get_iter(%slice_104) : !cute.coord_tensor<"(?,?{div=4},?)", "():()">
      %e0_106, %e1_107, %e2_108 = cute.get_leaves(%iter_105) : !cute.int_tuple<"(?,?{div=4},?)">
      %43 = cute.get_scalars(%e0_106) : !cute.int_tuple<"?">
      %44 = cute.get_scalars(%e1_107) : !cute.int_tuple<"?{div=4}">
      %45 = cute.get_scalars(%e2_108) : !cute.int_tuple<"?">
      %iter_109 = cute.get_iter(%slice_104) : !cute.coord_tensor<"(?,?{div=4},?)", "():()">
      %e0_110, %e1_111, %e2_112 = cute.get_leaves(%iter_109) : !cute.int_tuple<"(?,?{div=4},?)">
      %46 = cute.get_scalars(%e0_110) : !cute.int_tuple<"?">
      %47 = cute.get_scalars(%e1_111) : !cute.int_tuple<"?{div=4}">
      %48 = cute.get_scalars(%e2_112) : !cute.int_tuple<"?">
      %iter_113 = cute.get_iter(%slice_104) : !cute.coord_tensor<"(?,?{div=4},?)", "():()">
      %e0_114, %e1_115, %e2_116 = cute.get_leaves(%iter_113) : !cute.int_tuple<"(?,?{div=4},?)">
      %49 = cute.get_scalars(%e0_114) : !cute.int_tuple<"?">
      %50 = cute.get_scalars(%e1_115) : !cute.int_tuple<"?{div=4}">
      %51 = cute.get_scalars(%e2_116) : !cute.int_tuple<"?">
      %coord_117 = cute.make_coord(%e0_114, %e1_115, %e2_116) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=4}">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?{div=4},?)">
      %coord_118 = cute.make_coord(%arg5, %arg6, %arg7) : (i32, i32, i32) -> !cute.coord<"(?,?,?)">
      %52 = cute.elem_less(%coord_117, %coord_118) : !cute.coord<"(?,?{div=4},?)">, !cute.coord<"(?,?,?)">
      scf.if %52 {
        %53 = cute.get_shape(%arg3) : (!cute.layout<"(128,4):(4,1)">) -> !cute.shape<"(128,4)">
        %e0_119, %e1_120 = cute.get_leaves(%53) : !cute.shape<"(128,4)">
        %54 = cute.get_shape(%arg3) : (!cute.layout<"(128,4):(4,1)">) -> !cute.shape<"(128,4)">
        %e0_121, %e1_122 = cute.get_leaves(%54) : !cute.shape<"(128,4)">
        %55 = cute.get(%arg3) <{mode = [1]}> : !cute.layout<"(128,4):(4,1)"> -> !cute.layout<"4:1">
        %rmem = cute.memref.alloca(%55) : !memref_rmem_f32_
        %iter_123 = cute.get_iter(%rmem) : !memref_rmem_f32_
        %iter_124 = cute.get_iter(%rmem) : !memref_rmem_f32_
        %56 = cute.get_shape(%arg4) : (!cute.layout<"(128,4):(4,1)">) -> !cute.shape<"(128,4)">
        %e0_125, %e1_126 = cute.get_leaves(%56) : !cute.shape<"(128,4)">
        %57 = cute.get_shape(%arg4) : (!cute.layout<"(128,4):(4,1)">) -> !cute.shape<"(128,4)">
        %e0_127, %e1_128 = cute.get_leaves(%57) : !cute.shape<"(128,4)">
        %58 = cute.get(%arg4) <{mode = [1]}> : !cute.layout<"(128,4):(4,1)"> -> !cute.layout<"4:1">
        %rmem_129 = cute.memref.alloca(%58) : !memref_rmem_f8E4M3FN
        %iter_130 = cute.get_iter(%rmem_129) : !memref_rmem_f8E4M3FN
        %iter_131 = cute.get_iter(%rmem_129) : !memref_rmem_f8E4M3FN
        %atom = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<f32>
        %lay_132 = cute.get_layout(%slice_86) : !memref_gmem_f32_3
        %59 = cute.get_shape(%lay_132) : (!cute.layout<"(4):(1)">) -> !cute.shape<"(4)">
        %e0_133 = cute.get_leaves(%59) : !cute.shape<"(4)">
        %lay_134 = cute.get_layout(%rmem) : !memref_rmem_f32_
        %60 = cute.get_shape(%lay_134) : (!cute.layout<"4:1">) -> !cute.shape<"4">
        %e0_135 = cute.get_leaves(%60) : !cute.shape<"4">
        %lay_136 = cute.get_layout(%slice_86) : !memref_gmem_f32_3
        %shape = cute.make_shape() : () -> !cute.shape<"1">
        %lay_137 = cute.make_layout(%shape) : !cute.layout<"1:0">
        %append = cute.append_to_rank<2> (%lay_136, %lay_137) : !cute.layout<"(4):(1)">, !cute.layout<"1:0">
        %view = cute.make_view(%iter_88, %append) : !memref_gmem_f32_4
        %iter_138 = cute.get_iter(%view) : !memref_gmem_f32_4
        %lay_139 = cute.get_layout(%view) : !memref_gmem_f32_4
        %61 = cute.get_shape(%lay_139) : (!cute.layout<"(4,1):(1,0)">) -> !cute.shape<"(4,1)">
        %e0_140, %e1_141 = cute.get_leaves(%61) : !cute.shape<"(4,1)">
        %grouped = cute.group_modes(%view) <1, 2> : (!memref_gmem_f32_4) -> !memref_gmem_f32_5
        %iter_142 = cute.get_iter(%grouped) : !memref_gmem_f32_5
        %iter_143 = cute.get_iter(%grouped) : !memref_gmem_f32_5
        %lay_144 = cute.get_layout(%rmem) : !memref_rmem_f32_
        %shape_145 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_146 = cute.make_layout(%shape_145) : !cute.layout<"1:0">
        %append_147 = cute.append_to_rank<2> (%lay_144, %lay_146) : !cute.layout<"4:1">, !cute.layout<"1:0">
        %view_148 = cute.make_view(%iter_124, %append_147) : !memref_rmem_f32_1
        %iter_149 = cute.get_iter(%view_148) : !memref_rmem_f32_1
        %lay_150 = cute.get_layout(%view_148) : !memref_rmem_f32_1
        %62 = cute.get_shape(%lay_150) : (!cute.layout<"(4,1):(1,0)">) -> !cute.shape<"(4,1)">
        %e0_151, %e1_152 = cute.get_leaves(%62) : !cute.shape<"(4,1)">
        %grouped_153 = cute.group_modes(%view_148) <1, 2> : (!memref_rmem_f32_1) -> !memref_rmem_f32_2
        %iter_154 = cute.get_iter(%grouped_153) : !memref_rmem_f32_2
        %iter_155 = cute.get_iter(%grouped_153) : !memref_rmem_f32_2
        %lay_156 = cute.get_layout(%grouped) : !memref_gmem_f32_5
        %63 = cute.get_shape(%lay_156) : (!cute.layout<"(4,(1)):(1,(0))">) -> !cute.shape<"(4,(1))">
        %e0_157, %e1_158 = cute.get_leaves(%63) : !cute.shape<"(4,(1))">
        %lay_159 = cute.get_layout(%grouped_153) : !memref_rmem_f32_2
        %64 = cute.get_shape(%lay_159) : (!cute.layout<"(4,(1)):(1,(0))">) -> !cute.shape<"(4,(1))">
        %e0_160, %e1_161 = cute.get_leaves(%64) : !cute.shape<"(4,(1))">
        %sz = cute.size(%grouped) <{mode = [1]}> : (!memref_gmem_f32_5) -> !cute.int_tuple<"1">
        %e0_162 = cute.get_leaves(%sz) : !cute.int_tuple<"1">
        %sz_163 = cute.size(%grouped_153) <{mode = [1]}> : (!memref_rmem_f32_2) -> !cute.int_tuple<"1">
        %e0_164 = cute.get_leaves(%sz_163) : !cute.int_tuple<"1">
        cute.copy(%atom, %grouped, %grouped_153) : (!cute_nvgpu.atom.universal_copy<f32>, !memref_gmem_f32_5, !memref_rmem_f32_2)
        %65 = cute.memref.load_vec %rmem : !memref_rmem_f32_
        %66 = nvgpu.cvt_fptrunc %65 : vector<4xf32> to vector<4xf8E4M3FN>
        %lay_165 = cute.get_layout(%rmem_129) : !memref_rmem_f8E4M3FN
        %67 = cute.get_shape(%lay_165) : (!cute.layout<"4:1">) -> !cute.shape<"4">
        %e0_166 = cute.get_leaves(%67) : !cute.shape<"4">
        %int_tuple = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
        %sz_167 = cute.size(%int_tuple) : (!cute.int_tuple<"4">) -> !cute.int_tuple<"4">
        %e0_168 = cute.get_leaves(%sz_167) : !cute.int_tuple<"4">
        %int_tuple_169 = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
        %sz_170 = cute.size(%int_tuple_169) : (!cute.int_tuple<"4">) -> !cute.int_tuple<"4">
        %e0_171 = cute.get_leaves(%sz_170) : !cute.int_tuple<"4">
        cute.memref.store_vec %66, %rmem_129 : !memref_rmem_f8E4M3FN
        %atom_172 = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<f8E4M3FN>
        %lay_173 = cute.get_layout(%slice_90) : !memref_gmem_f8E4M3FN3
        %68 = cute.get_shape(%lay_173) : (!cute.layout<"(4):(1)">) -> !cute.shape<"(4)">
        %e0_174 = cute.get_leaves(%68) : !cute.shape<"(4)">
        %lay_175 = cute.get_layout(%rmem_129) : !memref_rmem_f8E4M3FN
        %shape_176 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_177 = cute.make_layout(%shape_176) : !cute.layout<"1:0">
        %append_178 = cute.append_to_rank<2> (%lay_175, %lay_177) : !cute.layout<"4:1">, !cute.layout<"1:0">
        %view_179 = cute.make_view(%iter_131, %append_178) : !memref_rmem_f8E4M3FN1
        %iter_180 = cute.get_iter(%view_179) : !memref_rmem_f8E4M3FN1
        %lay_181 = cute.get_layout(%view_179) : !memref_rmem_f8E4M3FN1
        %69 = cute.get_shape(%lay_181) : (!cute.layout<"(4,1):(1,0)">) -> !cute.shape<"(4,1)">
        %e0_182, %e1_183 = cute.get_leaves(%69) : !cute.shape<"(4,1)">
        %grouped_184 = cute.group_modes(%view_179) <1, 2> : (!memref_rmem_f8E4M3FN1) -> !memref_rmem_f8E4M3FN2
        %iter_185 = cute.get_iter(%grouped_184) : !memref_rmem_f8E4M3FN2
        %iter_186 = cute.get_iter(%grouped_184) : !memref_rmem_f8E4M3FN2
        %lay_187 = cute.get_layout(%slice_90) : !memref_gmem_f8E4M3FN3
        %shape_188 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_189 = cute.make_layout(%shape_188) : !cute.layout<"1:0">
        %append_190 = cute.append_to_rank<2> (%lay_187, %lay_189) : !cute.layout<"(4):(1)">, !cute.layout<"1:0">
        %view_191 = cute.make_view(%iter_92, %append_190) : !memref_gmem_f8E4M3FN4
        %iter_192 = cute.get_iter(%view_191) : !memref_gmem_f8E4M3FN4
        %lay_193 = cute.get_layout(%view_191) : !memref_gmem_f8E4M3FN4
        %70 = cute.get_shape(%lay_193) : (!cute.layout<"(4,1):(1,0)">) -> !cute.shape<"(4,1)">
        %e0_194, %e1_195 = cute.get_leaves(%70) : !cute.shape<"(4,1)">
        %grouped_196 = cute.group_modes(%view_191) <1, 2> : (!memref_gmem_f8E4M3FN4) -> !memref_gmem_f8E4M3FN5
        %iter_197 = cute.get_iter(%grouped_196) : !memref_gmem_f8E4M3FN5
        %iter_198 = cute.get_iter(%grouped_196) : !memref_gmem_f8E4M3FN5
        %lay_199 = cute.get_layout(%grouped_184) : !memref_rmem_f8E4M3FN2
        %71 = cute.get_shape(%lay_199) : (!cute.layout<"(4,(1)):(1,(0))">) -> !cute.shape<"(4,(1))">
        %e0_200, %e1_201 = cute.get_leaves(%71) : !cute.shape<"(4,(1))">
        %lay_202 = cute.get_layout(%grouped_196) : !memref_gmem_f8E4M3FN5
        %72 = cute.get_shape(%lay_202) : (!cute.layout<"(4,(1)):(1,(0))">) -> !cute.shape<"(4,(1))">
        %e0_203, %e1_204 = cute.get_leaves(%72) : !cute.shape<"(4,(1))">
        %sz_205 = cute.size(%grouped_184) <{mode = [1]}> : (!memref_rmem_f8E4M3FN2) -> !cute.int_tuple<"1">
        %e0_206 = cute.get_leaves(%sz_205) : !cute.int_tuple<"1">
        %sz_207 = cute.size(%grouped_196) <{mode = [1]}> : (!memref_gmem_f8E4M3FN5) -> !cute.int_tuple<"1">
        %e0_208 = cute.get_leaves(%sz_207) : !cute.int_tuple<"1">
        cute.copy(%atom_172, %grouped_184, %grouped_196) : (!cute_nvgpu.atom.universal_copy<f8E4M3FN>, !memref_rmem_f8E4M3FN2, !memref_gmem_f8E4M3FN5)
      }
      return
    }
  }
  func.func @cutlass__convert_Tensorgmemoi641i64_Tensorgmemodiv16div161div16_1_4(%arg0: !memref_gmem_f32_6, %arg1: !memref_gmem_f8E4M3FN6) -> i32 attributes {llvm.emit_c_interface} {
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
    %lay_22 = cute.make_layout(%shape, %stride) : !cute.layout<"(128,4):(4,1)">
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
    %23 = cute.get_shape(%lay_43) : (!cute.layout<"(?,?{div=16},?):(?{div=16},1,?{div=16})">) -> !cute.shape<"(?,?{div=16},?)">
    %e0_44, %e1_45, %e2_46 = cute.get_leaves(%23) : !cute.shape<"(?,?{div=16},?)">
    %itup_47 = cute.to_int_tuple(%e0_44) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %24 = cute.get_scalars(%itup_47) : !cute.int_tuple<"?">
    %itup_48 = cute.to_int_tuple(%e1_45) : !cute.shape<"?{div=16}"> to !cute.int_tuple<"?{div=16}">
    %25 = cute.get_scalars(%itup_48) : !cute.int_tuple<"?{div=16}">
    %itup_49 = cute.to_int_tuple(%e2_46) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %26 = cute.get_scalars(%itup_49) : !cute.int_tuple<"?">
    %sz_50 = cute.size(%lay_22) : (!cute.layout<"(128,4):(4,1)">) -> !cute.int_tuple<"512">
    %e0_51 = cute.get_leaves(%sz_50) : !cute.int_tuple<"512">
    %tile = cute.make_tile() : () -> !cute.tile<"[1:0;512:1;1:0]">
    %div = cute.zipped_divide(%arg0, %tile) : !memref_gmem_f32_6, !cute.tile<"[1:0;512:1;1:0]">
    %iter_52 = cute.get_iter(%div) : !memref_gmem_f32_
    %iter_53 = cute.get_iter(%div) : !memref_gmem_f32_
    %tile_54 = cute.make_tile() : () -> !cute.tile<"[1:0;512:1;1:0]">
    %div_55 = cute.zipped_divide(%18, %tile_54) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">, !cute.tile<"[1:0;512:1;1:0]">
    %iter_56 = cute.get_iter(%div_55) : !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">
    %e0_57, %e1_58, %e2_59 = cute.get_leaves(%iter_56) : !cute.int_tuple<"(0,0,0)">
    %iter_60 = cute.get_iter(%div_55) : !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">
    %e0_61, %e1_62, %e2_63 = cute.get_leaves(%iter_60) : !cute.int_tuple<"(0,0,0)">
    %tile_64 = cute.make_tile() : () -> !cute.tile<"[1:0;512:1;1:0]">
    %div_65 = cute.zipped_divide(%arg1, %tile_64) : !memref_gmem_f8E4M3FN6, !cute.tile<"[1:0;512:1;1:0]">
    %iter_66 = cute.get_iter(%div_65) : !memref_gmem_f8E4M3FN
    %iter_67 = cute.get_iter(%div_65) : !memref_gmem_f8E4M3FN
    %sz_68 = cute.size(%div) <{mode = [1]}> : (!memref_gmem_f32_) -> !cute.int_tuple<"?">
    %e0_69 = cute.get_leaves(%sz_68) : !cute.int_tuple<"?">
    %27 = cute.get_scalars(%e0_69) : !cute.int_tuple<"?">
    %sz_70 = cute.size(%lay_22) <{mode = [0]}> : (!cute.layout<"(128,4):(4,1)">) -> !cute.int_tuple<"128">
    %e0_71 = cute.get_leaves(%sz_70) : !cute.int_tuple<"128">
    %lay_72 = cute.get_layout(%div) : !memref_gmem_f32_
    %28 = cute.get_shape(%lay_72) : (!cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !cute.shape<"((1,512,1),(?,?,?))">
    %e0_73, %e1_74, %e2_75, %e3, %e4, %e5 = cute.get_leaves(%28) : !cute.shape<"((1,512,1),(?,?,?))">
    %itup_76 = cute.to_int_tuple(%e3) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %29 = cute.get_scalars(%itup_76) : !cute.int_tuple<"?">
    %itup_77 = cute.to_int_tuple(%e4) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %30 = cute.get_scalars(%itup_77) : !cute.int_tuple<"?">
    %itup_78 = cute.to_int_tuple(%e5) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %31 = cute.get_scalars(%itup_78) : !cute.int_tuple<"?">
    %32 = cute.get_stride(%lay_72) : (!cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !cute.stride<"((0,1,0),(?{i64},512,?{i64}))">
    %e0_79, %e1_80, %e2_81, %e3_82, %e4_83, %e5_84 = cute.get_leaves(%32) : !cute.stride<"((0,1,0),(?{i64},512,?{i64}))">
    %itup_85 = cute.to_int_tuple(%e3_82) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
    %33 = cute.get_scalars(%itup_85) : !cute.int_tuple<"?{i64}">
    %itup_86 = cute.to_int_tuple(%e5_84) : !cute.stride<"?{i64}"> to !cute.int_tuple<"?{i64}">
    %34 = cute.get_scalars(%itup_86) : !cute.int_tuple<"?{i64}">
    %lay_87 = cute.get_layout(%div_65) : !memref_gmem_f8E4M3FN
    %35 = cute.get_shape(%lay_87) : (!cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{div=16},512,?{div=16}))">) -> !cute.shape<"((1,512,1),(?,?,?))">
    %e0_88, %e1_89, %e2_90, %e3_91, %e4_92, %e5_93 = cute.get_leaves(%35) : !cute.shape<"((1,512,1),(?,?,?))">
    %itup_94 = cute.to_int_tuple(%e3_91) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %36 = cute.get_scalars(%itup_94) : !cute.int_tuple<"?">
    %itup_95 = cute.to_int_tuple(%e4_92) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %37 = cute.get_scalars(%itup_95) : !cute.int_tuple<"?">
    %itup_96 = cute.to_int_tuple(%e5_93) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %38 = cute.get_scalars(%itup_96) : !cute.int_tuple<"?">
    %39 = cute.get_stride(%lay_87) : (!cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{div=16},512,?{div=16}))">) -> !cute.stride<"((0,1,0),(?{div=16},512,?{div=16}))">
    %e0_97, %e1_98, %e2_99, %e3_100, %e4_101, %e5_102 = cute.get_leaves(%39) : !cute.stride<"((0,1,0),(?{div=16},512,?{div=16}))">
    %itup_103 = cute.to_int_tuple(%e3_100) : !cute.stride<"?{div=16}"> to !cute.int_tuple<"?{div=16}">
    %40 = cute.get_scalars(%itup_103) : !cute.int_tuple<"?{div=16}">
    %itup_104 = cute.to_int_tuple(%e5_102) : !cute.stride<"?{div=16}"> to !cute.int_tuple<"?{div=16}">
    %41 = cute.get_scalars(%itup_104) : !cute.int_tuple<"?{div=16}">
    %lay_105 = cute.get_layout(%div_55) : !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">
    %42 = cute.get_shape(%lay_105) : (!cute.layout<"((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">) -> !cute.shape<"((1,512,1),(?,?,?))">
    %e0_106, %e1_107, %e2_108, %e3_109, %e4_110, %e5_111 = cute.get_leaves(%42) : !cute.shape<"((1,512,1),(?,?,?))">
    %itup_112 = cute.to_int_tuple(%e3_109) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %43 = cute.get_scalars(%itup_112) : !cute.int_tuple<"?">
    %itup_113 = cute.to_int_tuple(%e4_110) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %44 = cute.get_scalars(%itup_113) : !cute.int_tuple<"?">
    %itup_114 = cute.to_int_tuple(%e5_111) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %45 = cute.get_scalars(%itup_114) : !cute.int_tuple<"?">
    %46 = cute.get_stride(%lay_105) : (!cute.layout<"((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">) -> !cute.stride<"((0,1@1,0),(1@0,512@1,1@2))">
    %e0_115, %e1_116, %e2_117, %e3_118, %e4_119, %e5_120 = cute.get_leaves(%46) : !cute.stride<"((0,1@1,0),(1@0,512@1,1@2))">
    %47 = cute.get_shape(%lay_22) : (!cute.layout<"(128,4):(4,1)">) -> !cute.shape<"(128,4)">
    %e0_121, %e1_122 = cute.get_leaves(%47) : !cute.shape<"(128,4)">
    %48 = cute.get_stride(%lay_22) : (!cute.layout<"(128,4):(4,1)">) -> !cute.stride<"(4,1)">
    %e0_123, %e1_124 = cute.get_leaves(%48) : !cute.stride<"(4,1)">
    %49 = cute.get_shape(%lay_22) : (!cute.layout<"(128,4):(4,1)">) -> !cute.shape<"(128,4)">
    %e0_125, %e1_126 = cute.get_leaves(%49) : !cute.shape<"(128,4)">
    %50 = cute.get_stride(%lay_22) : (!cute.layout<"(128,4):(4,1)">) -> !cute.stride<"(4,1)">
    %e0_127, %e1_128 = cute.get_leaves(%50) : !cute.stride<"(4,1)">
    %c0_i32 = arith.constant 0 : i32
    %c0_i64 = arith.constant 0 : i64
    %51 = cuda.cast %c0_i64 : i64 -> !cuda.stream
    %52 = arith.extsi %c0_i32 : i32 to i64
    %c128_i32 = arith.constant 128 : i32
    %c1_i32 = arith.constant 1 : i32
    %53 = cuda.launch_cfg.create<max_attrs = 2 : i32> (blockDim = (%c128_i32, %c1_i32, %c1_i32), dynamicSmemBytes = %52, gridDim = (%27, %c1_i32, %c1_i32), stream = %51) : i32, i32, i32, i64, i32, i32, i32, !cuda.stream -> !cuda.launch_cfg<max_attrs = 2>
    %54 = cuda.launch_ex @kernels::@kernel_cutlass__convert_kernel_tensorptrf32gmemo15121010512_tensorptrf8E4M3FNgmemalign16o15121010div16512div16_tensor000o15121011010512112____Float32_Float8E4M3FN_0<%53> (%div, %div_65, %div_55, %lay_22, %lay_22, %15, %16, %17) : !cuda.launch_cfg<max_attrs = 2>, (!memref_gmem_f32_, !memref_gmem_f8E4M3FN, !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">, !cute.layout<"(128,4):(4,1)">, !cute.layout<"(128,4):(4,1)">, i32, i32, i32) -> !cuda.result
    %55 = cuda.cast %54 : !cuda.result -> i32
    cuda.return_if_error %55 : i32
    %c0_i32_129 = arith.constant 0 : i32
    return %c0_i32_129 : i32
  }
}
