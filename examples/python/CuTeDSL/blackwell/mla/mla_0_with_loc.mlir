

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
    cuda.kernel @kernel_cutlass__convert_kernel_tensorptrf32gmemo15121010i64512i64_tensorptrf8E4M3FNgmemalign16o15121010div16512div16_tensor000o15121011010512112____Float32_Float8E4M3FN_0(%arg0: !memref_gmem_f32_, %arg1: !memref_gmem_f8E4M3FN, %arg2: !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">, %arg3: !cute.layout<"(128,4):(4,1)">, %arg4: !cute.layout<"(128,4):(4,1)">, %arg5: i32, %arg6: i32, %arg7: i32) attributes {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} {
      %iter = cute.get_iter(%arg0) : !memref_gmem_f32_
      %iter_0 = cute.get_iter(%arg1) : !memref_gmem_f8E4M3FN
      %iter_1 = cute.get_iter(%arg2) : !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">
      %tup = cute.deref_arith_tuple_iter(%iter_1) : !cute.arith_tuple_iter<"(0,0,0)">
      %e0, %e1, %e2 = cute.get_leaves(%tup) : !cute.int_tuple<"(0,0,0)">
      %iter_2 = cute.get_iter(%arg0) : !memref_gmem_f32_
      %iter_3 = cute.get_iter(%arg1) : !memref_gmem_f8E4M3FN
      %iter_4 = cute.get_iter(%arg2) : !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">
      %tup_5 = cute.deref_arith_tuple_iter(%iter_4) : !cute.arith_tuple_iter<"(0,0,0)">
      %e0_6, %e1_7, %e2_8 = cute.get_leaves(%tup_5) : !cute.int_tuple<"(0,0,0)">
      %lay = cute.get_layout(%arg0) : !memref_gmem_f32_
      %lay_9 = cute.get_layout(%arg1) : !memref_gmem_f8E4M3FN
      %lay_10 = cute.get_layout(%arg2) : !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">
      %lay_11 = cute.get_layout(%arg0) : !memref_gmem_f32_
      %lay_12 = cute.get_layout(%arg1) : !memref_gmem_f8E4M3FN
      %lay_13 = cute.get_layout(%arg2) : !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">
      %0 = nvvm.read.ptx.sreg.tid.x : i32
      %1 = nvvm.read.ptx.sreg.ctaid.x : i32
      %coord = cute.make_coord(%1) : (i32) -> !cute.coord<"(_,?)">
      %slice = cute.slice(%arg0, %coord) : !memref_gmem_f32_, !cute.coord<"(_,?)">
      %iter_14 = cute.get_iter(%slice) : !memref_gmem_f32_1
      %iter_15 = cute.get_iter(%slice) : !memref_gmem_f32_1
      %coord_16 = cute.make_coord(%1) : (i32) -> !cute.coord<"(_,?)">
      %slice_17 = cute.slice(%arg1, %coord_16) : !memref_gmem_f8E4M3FN, !cute.coord<"(_,?)">
      %iter_18 = cute.get_iter(%slice_17) : !memref_gmem_f8E4M3FN1
      %iter_19 = cute.get_iter(%slice_17) : !memref_gmem_f8E4M3FN1
      %coord_20 = cute.make_coord(%1) : (i32) -> !cute.coord<"(_,?)">
      %slice_21 = cute.slice(%arg2, %coord_20) : !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">, !cute.coord<"(_,?)">
      %iter_22 = cute.get_iter(%slice_21) : !cute.coord_tensor<"(?,?{div=512},?)", "((1,512,1)):((0,1@1,0))">
      %tup_23 = cute.deref_arith_tuple_iter(%iter_22) : !cute.arith_tuple_iter<"(?,?{div=512},?)">
      %e0_24, %e1_25, %e2_26 = cute.get_leaves(%tup_23) : !cute.int_tuple<"(?,?{div=512},?)">
      %2 = cute.get_scalars(%e0_24) : !cute.int_tuple<"?">
      %3 = cute.get_scalars(%e1_25) : !cute.int_tuple<"?{div=512}">
      %4 = cute.get_scalars(%e2_26) : !cute.int_tuple<"?">
      %iter_27 = cute.get_iter(%slice_21) : !cute.coord_tensor<"(?,?{div=512},?)", "((1,512,1)):((0,1@1,0))">
      %tup_28 = cute.deref_arith_tuple_iter(%iter_27) : !cute.arith_tuple_iter<"(?,?{div=512},?)">
      %e0_29, %e1_30, %e2_31 = cute.get_leaves(%tup_28) : !cute.int_tuple<"(?,?{div=512},?)">
      %5 = cute.get_scalars(%e0_29) : !cute.int_tuple<"?">
      %6 = cute.get_scalars(%e1_30) : !cute.int_tuple<"?{div=512}">
      %7 = cute.get_scalars(%e2_31) : !cute.int_tuple<"?">
      %8 = cute.composition(%slice, %arg3) : (!memref_gmem_f32_1, !cute.layout<"(128,4):(4,1)">) -> !memref_gmem_f32_2
      %iter_32 = cute.get_iter(%8) : !memref_gmem_f32_2
      %9 = cute.composition(%slice_17, %arg4) : (!memref_gmem_f8E4M3FN1, !cute.layout<"(128,4):(4,1)">) -> !memref_gmem_f8E4M3FN2
      %iter_33 = cute.get_iter(%9) : !memref_gmem_f8E4M3FN2
      %10 = cute.composition(%slice_21, %arg3) : (!cute.coord_tensor<"(?,?{div=512},?)", "((1,512,1)):((0,1@1,0))">, !cute.layout<"(128,4):(4,1)">) -> !cute.coord_tensor<"(?,?{div=512},?)", "(128,4):(4@1,1@1)">
      %iter_34 = cute.get_iter(%10) : !cute.coord_tensor<"(?,?{div=512},?)", "(128,4):(4@1,1@1)">
      %tup_35 = cute.deref_arith_tuple_iter(%iter_34) : !cute.arith_tuple_iter<"(?,?{div=512},?)">
      %e0_36, %e1_37, %e2_38 = cute.get_leaves(%tup_35) : !cute.int_tuple<"(?,?{div=512},?)">
      %11 = cute.get_scalars(%e0_36) : !cute.int_tuple<"?">
      %12 = cute.get_scalars(%e1_37) : !cute.int_tuple<"?{div=512}">
      %13 = cute.get_scalars(%e2_38) : !cute.int_tuple<"?">
      %coord_39 = cute.make_coord(%0) : (i32) -> !cute.coord<"(?,_)">
      %slice_40 = cute.slice(%8, %coord_39) : !memref_gmem_f32_2, !cute.coord<"(?,_)">
      %iter_41 = cute.get_iter(%slice_40) : !memref_gmem_f32_3
      %iter_42 = cute.get_iter(%slice_40) : !memref_gmem_f32_3
      %coord_43 = cute.make_coord(%0) : (i32) -> !cute.coord<"(?,_)">
      %slice_44 = cute.slice(%9, %coord_43) : !memref_gmem_f8E4M3FN2, !cute.coord<"(?,_)">
      %iter_45 = cute.get_iter(%slice_44) : !memref_gmem_f8E4M3FN3
      %iter_46 = cute.get_iter(%slice_44) : !memref_gmem_f8E4M3FN3
      %coord_47 = cute.make_coord(%0) : (i32) -> !cute.coord<"(?,_)">
      %slice_48 = cute.slice(%10, %coord_47) : !cute.coord_tensor<"(?,?{div=512},?)", "(128,4):(4@1,1@1)">, !cute.coord<"(?,_)">
      %iter_49 = cute.get_iter(%slice_48) : !cute.coord_tensor<"(?,?{div=4},?)", "(4):(1@1)">
      %tup_50 = cute.deref_arith_tuple_iter(%iter_49) : !cute.arith_tuple_iter<"(?,?{div=4},?)">
      %e0_51, %e1_52, %e2_53 = cute.get_leaves(%tup_50) : !cute.int_tuple<"(?,?{div=4},?)">
      %14 = cute.get_scalars(%e0_51) : !cute.int_tuple<"?">
      %15 = cute.get_scalars(%e1_52) : !cute.int_tuple<"?{div=4}">
      %16 = cute.get_scalars(%e2_53) : !cute.int_tuple<"?">
      %iter_54 = cute.get_iter(%slice_48) : !cute.coord_tensor<"(?,?{div=4},?)", "(4):(1@1)">
      %tup_55 = cute.deref_arith_tuple_iter(%iter_54) : !cute.arith_tuple_iter<"(?,?{div=4},?)">
      %e0_56, %e1_57, %e2_58 = cute.get_leaves(%tup_55) : !cute.int_tuple<"(?,?{div=4},?)">
      %17 = cute.get_scalars(%e0_56) : !cute.int_tuple<"?">
      %18 = cute.get_scalars(%e1_57) : !cute.int_tuple<"?{div=4}">
      %19 = cute.get_scalars(%e2_58) : !cute.int_tuple<"?">
      %coord_59 = cute.make_coord() : () -> !cute.coord<"0">
      %slice_60 = cute.slice(%slice_48, %coord_59) : !cute.coord_tensor<"(?,?{div=4},?)", "(4):(1@1)">, !cute.coord<"0">
      %iter_61 = cute.get_iter(%slice_60) : !cute.coord_tensor<"(?,?{div=4},?)", "():()">
      %tup_62 = cute.deref_arith_tuple_iter(%iter_61) : !cute.arith_tuple_iter<"(?,?{div=4},?)">
      %e0_63, %e1_64, %e2_65 = cute.get_leaves(%tup_62) : !cute.int_tuple<"(?,?{div=4},?)">
      %20 = cute.get_scalars(%e0_63) : !cute.int_tuple<"?">
      %21 = cute.get_scalars(%e1_64) : !cute.int_tuple<"?{div=4}">
      %22 = cute.get_scalars(%e2_65) : !cute.int_tuple<"?">
      %iter_66 = cute.get_iter(%slice_60) : !cute.coord_tensor<"(?,?{div=4},?)", "():()">
      %tup_67 = cute.deref_arith_tuple_iter(%iter_66) : !cute.arith_tuple_iter<"(?,?{div=4},?)">
      %e0_68, %e1_69, %e2_70 = cute.get_leaves(%tup_67) : !cute.int_tuple<"(?,?{div=4},?)">
      %23 = cute.get_scalars(%e0_68) : !cute.int_tuple<"?">
      %24 = cute.get_scalars(%e1_69) : !cute.int_tuple<"?{div=4}">
      %25 = cute.get_scalars(%e2_70) : !cute.int_tuple<"?">
      %iter_71 = cute.get_iter(%slice_60) : !cute.coord_tensor<"(?,?{div=4},?)", "():()">
      %tup_72 = cute.deref_arith_tuple_iter(%iter_71) : !cute.arith_tuple_iter<"(?,?{div=4},?)">
      %e0_73, %e1_74, %e2_75 = cute.get_leaves(%tup_72) : !cute.int_tuple<"(?,?{div=4},?)">
      %26 = cute.get_scalars(%e0_73) : !cute.int_tuple<"?">
      %27 = cute.get_scalars(%e1_74) : !cute.int_tuple<"?{div=4}">
      %28 = cute.get_scalars(%e2_75) : !cute.int_tuple<"?">
      %coord_76 = cute.make_coord(%e0_73, %e1_74, %e2_75) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=4}">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?{div=4},?)">
      %coord_77 = cute.make_coord(%arg5, %arg6, %arg7) : (i32, i32, i32) -> !cute.coord<"(?,?,?)">
      %29 = cute.elem_less(%coord_76, %coord_77) : !cute.coord<"(?,?{div=4},?)">, !cute.coord<"(?,?,?)">
      scf.if %29 {
        %30 = cute.get_shape(%arg3) : (!cute.layout<"(128,4):(4,1)">) -> !cute.shape<"(128,4)">
        %e0_78, %e1_79 = cute.get_leaves(%30) : !cute.shape<"(128,4)">
        %31 = cute.get_shape(%arg3) : (!cute.layout<"(128,4):(4,1)">) -> !cute.shape<"(128,4)">
        %e0_80, %e1_81 = cute.get_leaves(%31) : !cute.shape<"(128,4)">
        %32 = cute.get(%arg3) <{mode = [1]}> : !cute.layout<"(128,4):(4,1)"> -> !cute.layout<"4:1">
        %rmem = cute.memref.alloca(%32) : !memref_rmem_f32_
        %iter_82 = cute.get_iter(%rmem) : !memref_rmem_f32_
        %iter_83 = cute.get_iter(%rmem) : !memref_rmem_f32_
        %33 = cute.get_shape(%arg4) : (!cute.layout<"(128,4):(4,1)">) -> !cute.shape<"(128,4)">
        %e0_84, %e1_85 = cute.get_leaves(%33) : !cute.shape<"(128,4)">
        %34 = cute.get_shape(%arg4) : (!cute.layout<"(128,4):(4,1)">) -> !cute.shape<"(128,4)">
        %e0_86, %e1_87 = cute.get_leaves(%34) : !cute.shape<"(128,4)">
        %35 = cute.get(%arg4) <{mode = [1]}> : !cute.layout<"(128,4):(4,1)"> -> !cute.layout<"4:1">
        %rmem_88 = cute.memref.alloca(%35) : !memref_rmem_f8E4M3FN
        %iter_89 = cute.get_iter(%rmem_88) : !memref_rmem_f8E4M3FN
        %iter_90 = cute.get_iter(%rmem_88) : !memref_rmem_f8E4M3FN
        %atom = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<f32>
        %lay_91 = cute.get_layout(%slice_40) : !memref_gmem_f32_3
        %36 = cute.get_shape(%lay_91) : (!cute.layout<"(4):(1)">) -> !cute.shape<"(4)">
        %e0_92 = cute.get_leaves(%36) : !cute.shape<"(4)">
        %lay_93 = cute.get_layout(%rmem) : !memref_rmem_f32_
        %37 = cute.get_shape(%lay_93) : (!cute.layout<"4:1">) -> !cute.shape<"4">
        %e0_94 = cute.get_leaves(%37) : !cute.shape<"4">
        %lay_95 = cute.get_layout(%slice_40) : !memref_gmem_f32_3
        %shape = cute.make_shape() : () -> !cute.shape<"1">
        %lay_96 = cute.make_layout(%shape) : !cute.layout<"1:0">
        %append = cute.append_to_rank<2> (%lay_95, %lay_96) : !cute.layout<"(4):(1)">, !cute.layout<"1:0">
        %view = cute.make_view(%iter_42, %append) : !memref_gmem_f32_4
        %iter_97 = cute.get_iter(%view) : !memref_gmem_f32_4
        %lay_98 = cute.get_layout(%view) : !memref_gmem_f32_4
        %38 = cute.get_shape(%lay_98) : (!cute.layout<"(4,1):(1,0)">) -> !cute.shape<"(4,1)">
        %e0_99, %e1_100 = cute.get_leaves(%38) : !cute.shape<"(4,1)">
        %lay_101 = cute.get_layout(%view) : !memref_gmem_f32_4
        %39 = cute.get_shape(%lay_101) : (!cute.layout<"(4,1):(1,0)">) -> !cute.shape<"(4,1)">
        %e0_102, %e1_103 = cute.get_leaves(%39) : !cute.shape<"(4,1)">
        %grouped = cute.group_modes(%view) <1, 2> : (!memref_gmem_f32_4) -> !memref_gmem_f32_5
        %iter_104 = cute.get_iter(%grouped) : !memref_gmem_f32_5
        %iter_105 = cute.get_iter(%grouped) : !memref_gmem_f32_5
        %lay_106 = cute.get_layout(%rmem) : !memref_rmem_f32_
        %shape_107 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_108 = cute.make_layout(%shape_107) : !cute.layout<"1:0">
        %append_109 = cute.append_to_rank<2> (%lay_106, %lay_108) : !cute.layout<"4:1">, !cute.layout<"1:0">
        %view_110 = cute.make_view(%iter_83, %append_109) : !memref_rmem_f32_1
        %iter_111 = cute.get_iter(%view_110) : !memref_rmem_f32_1
        %lay_112 = cute.get_layout(%view_110) : !memref_rmem_f32_1
        %40 = cute.get_shape(%lay_112) : (!cute.layout<"(4,1):(1,0)">) -> !cute.shape<"(4,1)">
        %e0_113, %e1_114 = cute.get_leaves(%40) : !cute.shape<"(4,1)">
        %lay_115 = cute.get_layout(%view_110) : !memref_rmem_f32_1
        %41 = cute.get_shape(%lay_115) : (!cute.layout<"(4,1):(1,0)">) -> !cute.shape<"(4,1)">
        %e0_116, %e1_117 = cute.get_leaves(%41) : !cute.shape<"(4,1)">
        %grouped_118 = cute.group_modes(%view_110) <1, 2> : (!memref_rmem_f32_1) -> !memref_rmem_f32_2
        %iter_119 = cute.get_iter(%grouped_118) : !memref_rmem_f32_2
        %iter_120 = cute.get_iter(%grouped_118) : !memref_rmem_f32_2
        %lay_121 = cute.get_layout(%grouped) : !memref_gmem_f32_5
        %42 = cute.get_shape(%lay_121) : (!cute.layout<"(4,(1)):(1,(0))">) -> !cute.shape<"(4,(1))">
        %e0_122, %e1_123 = cute.get_leaves(%42) : !cute.shape<"(4,(1))">
        %lay_124 = cute.get_layout(%grouped_118) : !memref_rmem_f32_2
        %43 = cute.get_shape(%lay_124) : (!cute.layout<"(4,(1)):(1,(0))">) -> !cute.shape<"(4,(1))">
        %e0_125, %e1_126 = cute.get_leaves(%43) : !cute.shape<"(4,(1))">
        %sz = cute.size(%grouped) <{mode = [1]}> : (!memref_gmem_f32_5) -> !cute.int_tuple<"1">
        %e0_127 = cute.get_leaves(%sz) : !cute.int_tuple<"1">
        %sz_128 = cute.size(%grouped_118) <{mode = [1]}> : (!memref_rmem_f32_2) -> !cute.int_tuple<"1">
        %e0_129 = cute.get_leaves(%sz_128) : !cute.int_tuple<"1">
        cute.copy(%atom, %grouped, %grouped_118) : (!cute_nvgpu.atom.universal_copy<f32>, !memref_gmem_f32_5, !memref_rmem_f32_2)
        %lay_130 = cute.get_layout(%rmem) : !memref_rmem_f32_
        %44 = cute.get_shape(%lay_130) : (!cute.layout<"4:1">) -> !cute.shape<"4">
        %e0_131 = cute.get_leaves(%44) : !cute.shape<"4">
        %45 = cute.memref.load_vec %rmem : !memref_rmem_f32_
        %lay_132 = cute.get_layout(%rmem) : !memref_rmem_f32_
        %46 = cute.get_shape(%lay_132) : (!cute.layout<"4:1">) -> !cute.shape<"4">
        %e0_133 = cute.get_leaves(%46) : !cute.shape<"4">
        %47 = nvgpu.cvt_fptrunc %45 : vector<4xf32> to vector<4xf8E4M3FN>
        %lay_134 = cute.get_layout(%rmem_88) : !memref_rmem_f8E4M3FN
        %48 = cute.get_shape(%lay_134) : (!cute.layout<"4:1">) -> !cute.shape<"4">
        %e0_135 = cute.get_leaves(%48) : !cute.shape<"4">
        %lay_136 = cute.get_layout(%rmem_88) : !memref_rmem_f8E4M3FN
        %49 = cute.get_shape(%lay_136) : (!cute.layout<"4:1">) -> !cute.shape<"4">
        %e0_137 = cute.get_leaves(%49) : !cute.shape<"4">
        %int_tuple = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
        %sz_138 = cute.size(%int_tuple) : (!cute.int_tuple<"4">) -> !cute.int_tuple<"4">
        %e0_139 = cute.get_leaves(%sz_138) : !cute.int_tuple<"4">
        %int_tuple_140 = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
        %sz_141 = cute.size(%int_tuple_140) : (!cute.int_tuple<"4">) -> !cute.int_tuple<"4">
        %e0_142 = cute.get_leaves(%sz_141) : !cute.int_tuple<"4">
        cute.memref.store_vec %47, %rmem_88 : !memref_rmem_f8E4M3FN
        %atom_143 = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<f8E4M3FN>
        %lay_144 = cute.get_layout(%rmem_88) : !memref_rmem_f8E4M3FN
        %50 = cute.get_shape(%lay_144) : (!cute.layout<"4:1">) -> !cute.shape<"4">
        %e0_145 = cute.get_leaves(%50) : !cute.shape<"4">
        %lay_146 = cute.get_layout(%slice_44) : !memref_gmem_f8E4M3FN3
        %51 = cute.get_shape(%lay_146) : (!cute.layout<"(4):(1)">) -> !cute.shape<"(4)">
        %e0_147 = cute.get_leaves(%51) : !cute.shape<"(4)">
        %lay_148 = cute.get_layout(%rmem_88) : !memref_rmem_f8E4M3FN
        %shape_149 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_150 = cute.make_layout(%shape_149) : !cute.layout<"1:0">
        %append_151 = cute.append_to_rank<2> (%lay_148, %lay_150) : !cute.layout<"4:1">, !cute.layout<"1:0">
        %view_152 = cute.make_view(%iter_90, %append_151) : !memref_rmem_f8E4M3FN1
        %iter_153 = cute.get_iter(%view_152) : !memref_rmem_f8E4M3FN1
        %lay_154 = cute.get_layout(%view_152) : !memref_rmem_f8E4M3FN1
        %52 = cute.get_shape(%lay_154) : (!cute.layout<"(4,1):(1,0)">) -> !cute.shape<"(4,1)">
        %e0_155, %e1_156 = cute.get_leaves(%52) : !cute.shape<"(4,1)">
        %lay_157 = cute.get_layout(%view_152) : !memref_rmem_f8E4M3FN1
        %53 = cute.get_shape(%lay_157) : (!cute.layout<"(4,1):(1,0)">) -> !cute.shape<"(4,1)">
        %e0_158, %e1_159 = cute.get_leaves(%53) : !cute.shape<"(4,1)">
        %grouped_160 = cute.group_modes(%view_152) <1, 2> : (!memref_rmem_f8E4M3FN1) -> !memref_rmem_f8E4M3FN2
        %iter_161 = cute.get_iter(%grouped_160) : !memref_rmem_f8E4M3FN2
        %iter_162 = cute.get_iter(%grouped_160) : !memref_rmem_f8E4M3FN2
        %lay_163 = cute.get_layout(%slice_44) : !memref_gmem_f8E4M3FN3
        %shape_164 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_165 = cute.make_layout(%shape_164) : !cute.layout<"1:0">
        %append_166 = cute.append_to_rank<2> (%lay_163, %lay_165) : !cute.layout<"(4):(1)">, !cute.layout<"1:0">
        %view_167 = cute.make_view(%iter_46, %append_166) : !memref_gmem_f8E4M3FN4
        %iter_168 = cute.get_iter(%view_167) : !memref_gmem_f8E4M3FN4
        %lay_169 = cute.get_layout(%view_167) : !memref_gmem_f8E4M3FN4
        %54 = cute.get_shape(%lay_169) : (!cute.layout<"(4,1):(1,0)">) -> !cute.shape<"(4,1)">
        %e0_170, %e1_171 = cute.get_leaves(%54) : !cute.shape<"(4,1)">
        %lay_172 = cute.get_layout(%view_167) : !memref_gmem_f8E4M3FN4
        %55 = cute.get_shape(%lay_172) : (!cute.layout<"(4,1):(1,0)">) -> !cute.shape<"(4,1)">
        %e0_173, %e1_174 = cute.get_leaves(%55) : !cute.shape<"(4,1)">
        %grouped_175 = cute.group_modes(%view_167) <1, 2> : (!memref_gmem_f8E4M3FN4) -> !memref_gmem_f8E4M3FN5
        %iter_176 = cute.get_iter(%grouped_175) : !memref_gmem_f8E4M3FN5
        %iter_177 = cute.get_iter(%grouped_175) : !memref_gmem_f8E4M3FN5
        %lay_178 = cute.get_layout(%grouped_160) : !memref_rmem_f8E4M3FN2
        %56 = cute.get_shape(%lay_178) : (!cute.layout<"(4,(1)):(1,(0))">) -> !cute.shape<"(4,(1))">
        %e0_179, %e1_180 = cute.get_leaves(%56) : !cute.shape<"(4,(1))">
        %lay_181 = cute.get_layout(%grouped_175) : !memref_gmem_f8E4M3FN5
        %57 = cute.get_shape(%lay_181) : (!cute.layout<"(4,(1)):(1,(0))">) -> !cute.shape<"(4,(1))">
        %e0_182, %e1_183 = cute.get_leaves(%57) : !cute.shape<"(4,(1))">
        %sz_184 = cute.size(%grouped_160) <{mode = [1]}> : (!memref_rmem_f8E4M3FN2) -> !cute.int_tuple<"1">
        %e0_185 = cute.get_leaves(%sz_184) : !cute.int_tuple<"1">
        %sz_186 = cute.size(%grouped_175) <{mode = [1]}> : (!memref_gmem_f8E4M3FN5) -> !cute.int_tuple<"1">
        %e0_187 = cute.get_leaves(%sz_186) : !cute.int_tuple<"1">
        cute.copy(%atom_143, %grouped_160, %grouped_175) : (!cute_nvgpu.atom.universal_copy<f8E4M3FN>, !memref_rmem_f8E4M3FN2, !memref_gmem_f8E4M3FN5)
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
    %lay_3 = cute.get_layout(%arg1) : !memref_gmem_f8E4M3FN6
    %shape = cute.make_shape() : () -> !cute.shape<"(128,4)">
    %stride = cute.make_stride() : () -> !cute.stride<"(4,1)">
    %lay_4 = cute.make_layout(%shape, %stride) : !cute.layout<"(128,4):(4,1)">
    %lay_5 = cute.get_layout(%arg0) : !memref_gmem_f32_6
    %0 = cute.get_shape(%lay_5) : (!cute.layout<"(?,?,?):(?{i64},1,?{i64})">) -> !cute.shape<"(?,?,?)">
    %e0, %e1, %e2 = cute.get_leaves(%0) : !cute.shape<"(?,?,?)">
    %itup = cute.to_int_tuple(%e0) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %1 = cute.get_scalars(%itup) : !cute.int_tuple<"?">
    %itup_6 = cute.to_int_tuple(%e1) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %2 = cute.get_scalars(%itup_6) : !cute.int_tuple<"?">
    %itup_7 = cute.to_int_tuple(%e2) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %3 = cute.get_scalars(%itup_7) : !cute.int_tuple<"?">
    %lay_8 = cute.get_layout(%arg0) : !memref_gmem_f32_6
    %4 = cute.get_shape(%lay_8) : (!cute.layout<"(?,?,?):(?{i64},1,?{i64})">) -> !cute.shape<"(?,?,?)">
    %e0_9, %e1_10, %e2_11 = cute.get_leaves(%4) : !cute.shape<"(?,?,?)">
    %itup_12 = cute.to_int_tuple(%e0_9) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %5 = cute.get_scalars(%itup_12) : !cute.int_tuple<"?">
    %itup_13 = cute.to_int_tuple(%e1_10) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %6 = cute.get_scalars(%itup_13) : !cute.int_tuple<"?">
    %itup_14 = cute.to_int_tuple(%e2_11) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %7 = cute.get_scalars(%itup_14) : !cute.int_tuple<"?">
    %shape_15 = cute.make_shape(%itup_12, %itup_13, %itup_14) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.shape<"(?,?,?)">
    %8 = cute.make_identity_tensor(%shape_15) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">
    %iter_16 = cute.get_iter(%8) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">
    %tup = cute.deref_arith_tuple_iter(%iter_16) : !cute.arith_tuple_iter<"(0,0,0)">
    %e0_17, %e1_18, %e2_19 = cute.get_leaves(%tup) : !cute.int_tuple<"(0,0,0)">
    %lay_20 = cute.get_layout(%arg0) : !memref_gmem_f32_6
    %9 = cute.get_shape(%lay_20) : (!cute.layout<"(?,?,?):(?{i64},1,?{i64})">) -> !cute.shape<"(?,?,?)">
    %e0_21, %e1_22, %e2_23 = cute.get_leaves(%9) : !cute.shape<"(?,?,?)">
    %itup_24 = cute.to_int_tuple(%e0_21) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %10 = cute.get_scalars(%itup_24) : !cute.int_tuple<"?">
    %itup_25 = cute.to_int_tuple(%e1_22) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %11 = cute.get_scalars(%itup_25) : !cute.int_tuple<"?">
    %itup_26 = cute.to_int_tuple(%e2_23) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %12 = cute.get_scalars(%itup_26) : !cute.int_tuple<"?">
    %sz = cute.size(%lay_4) : (!cute.layout<"(128,4):(4,1)">) -> !cute.int_tuple<"512">
    %e0_27 = cute.get_leaves(%sz) : !cute.int_tuple<"512">
    %lay_28 = cute.get_layout(%arg1) : !memref_gmem_f8E4M3FN6
    %13 = cute.get_shape(%lay_28) : (!cute.layout<"(?,?{div=16},?):(?{div=16},1,?{div=16})">) -> !cute.shape<"(?,?{div=16},?)">
    %e0_29, %e1_30, %e2_31 = cute.get_leaves(%13) : !cute.shape<"(?,?{div=16},?)">
    %itup_32 = cute.to_int_tuple(%e0_29) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %14 = cute.get_scalars(%itup_32) : !cute.int_tuple<"?">
    %itup_33 = cute.to_int_tuple(%e1_30) : !cute.shape<"?{div=16}"> to !cute.int_tuple<"?{div=16}">
    %15 = cute.get_scalars(%itup_33) : !cute.int_tuple<"?{div=16}">
    %itup_34 = cute.to_int_tuple(%e2_31) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %16 = cute.get_scalars(%itup_34) : !cute.int_tuple<"?">
    %sz_35 = cute.size(%lay_4) : (!cute.layout<"(128,4):(4,1)">) -> !cute.int_tuple<"512">
    %e0_36 = cute.get_leaves(%sz_35) : !cute.int_tuple<"512">
    %tile = cute.make_tile() : () -> !cute.tile<"[1:0;512:1;1:0]">
    %div = cute.zipped_divide(%arg0, %tile) : !memref_gmem_f32_6, !cute.tile<"[1:0;512:1;1:0]">
    %iter_37 = cute.get_iter(%div) : !memref_gmem_f32_
    %iter_38 = cute.get_iter(%div) : !memref_gmem_f32_
    %tile_39 = cute.make_tile() : () -> !cute.tile<"[1:0;512:1;1:0]">
    %div_40 = cute.zipped_divide(%8, %tile_39) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">, !cute.tile<"[1:0;512:1;1:0]">
    %iter_41 = cute.get_iter(%div_40) : !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">
    %tup_42 = cute.deref_arith_tuple_iter(%iter_41) : !cute.arith_tuple_iter<"(0,0,0)">
    %e0_43, %e1_44, %e2_45 = cute.get_leaves(%tup_42) : !cute.int_tuple<"(0,0,0)">
    %iter_46 = cute.get_iter(%div_40) : !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">
    %tup_47 = cute.deref_arith_tuple_iter(%iter_46) : !cute.arith_tuple_iter<"(0,0,0)">
    %e0_48, %e1_49, %e2_50 = cute.get_leaves(%tup_47) : !cute.int_tuple<"(0,0,0)">
    %tile_51 = cute.make_tile() : () -> !cute.tile<"[1:0;512:1;1:0]">
    %div_52 = cute.zipped_divide(%arg1, %tile_51) : !memref_gmem_f8E4M3FN6, !cute.tile<"[1:0;512:1;1:0]">
    %iter_53 = cute.get_iter(%div_52) : !memref_gmem_f8E4M3FN
    %iter_54 = cute.get_iter(%div_52) : !memref_gmem_f8E4M3FN
    %sz_55 = cute.size(%div) <{mode = [1]}> : (!memref_gmem_f32_) -> !cute.int_tuple<"?">
    %e0_56 = cute.get_leaves(%sz_55) : !cute.int_tuple<"?">
    %17 = cute.get_scalars(%e0_56) : !cute.int_tuple<"?">
    %sz_57 = cute.size(%lay_4) <{mode = [0]}> : (!cute.layout<"(128,4):(4,1)">) -> !cute.int_tuple<"128">
    %e0_58 = cute.get_leaves(%sz_57) : !cute.int_tuple<"128">
    %lay_59 = cute.get_layout(%div) : !memref_gmem_f32_
    %lay_60 = cute.get_layout(%div_52) : !memref_gmem_f8E4M3FN
    %lay_61 = cute.get_layout(%div_40) : !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">
    %c0_i32 = arith.constant 0 : i32
    %c0_i64 = arith.constant 0 : i64
    %18 = cuda.cast %c0_i64 : i64 -> !cuda.stream
    %19 = arith.extsi %c0_i32 : i32 to i64
    %c128_i32 = arith.constant 128 : i32
    %c1_i32 = arith.constant 1 : i32
    %20 = cuda.launch_cfg.create<max_attrs = 3 : i32> (blockDim = (%c128_i32, %c1_i32, %c1_i32), dynamicSmemBytes = %19, gridDim = (%17, %c1_i32, %c1_i32), stream = %18) : i32, i32, i32, i64, i32, i32, i32, !cuda.stream -> !cuda.launch_cfg<max_attrs = 3>
    %c0_i32_62 = arith.constant 0 : i32
    cuda.launch_cfg.programmatic_stream_serialization_allowed[%20] %c0_i32_62 : !cuda.launch_cfg<max_attrs = 3>, i32
    %c0_i32_63 = arith.constant 0 : i32
    cuda.launch_cfg.cooperative[%20] %c0_i32_63 : !cuda.launch_cfg<max_attrs = 3>, i32
    %21 = cuda.launch_ex @kernels::@kernel_cutlass__convert_kernel_tensorptrf32gmemo15121010i64512i64_tensorptrf8E4M3FNgmemalign16o15121010div16512div16_tensor000o15121011010512112____Float32_Float8E4M3FN_0<%20> (%div, %div_52, %div_40, %lay_4, %lay_4, %1, %2, %3) {assume_kernel_attr = #cuda.assume_kernel_attr<true>} : !cuda.launch_cfg<max_attrs = 3>, (!memref_gmem_f32_, !memref_gmem_f8E4M3FN, !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">, !cute.layout<"(128,4):(4,1)">, !cute.layout<"(128,4):(4,1)">, i32, i32, i32) -> !cuda.result
    %22 = cuda.cast %21 : !cuda.result -> i32
    cuda.return_if_error %22 : i32
    %c0_i32_64 = arith.constant 0 : i32
    return %c0_i32_64 : i32
  }
}

