

!memref_gmem_f32_ = !cute.memref<f32, gmem, "((1,1024,1),(?,?,?)):((0,1,0),(?{i64},1024,?{i64}))">
!memref_gmem_f32_1 = !cute.memref<f32, gmem, "((1,1024,1)):((0,1,0))">
!memref_gmem_f32_2 = !cute.memref<f32, gmem, "(128,8):(8,1)">
!memref_gmem_f32_3 = !cute.memref<f32, gmem, "(8):(1)">
!memref_gmem_f32_4 = !cute.memref<f32, gmem, "(8,1):(1,0)">
!memref_gmem_f32_5 = !cute.memref<f32, gmem, "(8,(1)):(1,(0))">
!memref_gmem_f32_6 = !cute.memref<f32, gmem, "(?,?,?):(?{i64},1,?{i64})">
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
    cuda.kernel @kernel_cutlass__convert_kernel_tensorptrf32gmemo110241010i641024i64_tensorptri8gmemalign16o15121010i64512i64_tensor000o1102410110101024112____Float32_Float4E2M1FN_0(%arg0: !memref_gmem_f32_, %arg1: !memref_gmem_i8_, %arg2: !cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">, %arg3: !cute.layout<"(128,8):(8,1)">, %arg4: !cute.layout<"(128,4):(4,1)">, %arg5: i32, %arg6: i32, %arg7: i32) attributes {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} {
      %iter = cute.get_iter(%arg0) : !memref_gmem_f32_
      %iter_0 = cute.get_iter(%arg1) : !memref_gmem_i8_
      %iter_1 = cute.get_iter(%arg2) : !cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">
      %tup = cute.deref_arith_tuple_iter(%iter_1) : !cute.arith_tuple_iter<"(0,0,0)">
      %e0, %e1, %e2 = cute.get_leaves(%tup) : !cute.int_tuple<"(0,0,0)">
      %iter_2 = cute.get_iter(%arg0) : !memref_gmem_f32_
      %iter_3 = cute.get_iter(%arg1) : !memref_gmem_i8_
      %iter_4 = cute.get_iter(%arg2) : !cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">
      %tup_5 = cute.deref_arith_tuple_iter(%iter_4) : !cute.arith_tuple_iter<"(0,0,0)">
      %e0_6, %e1_7, %e2_8 = cute.get_leaves(%tup_5) : !cute.int_tuple<"(0,0,0)">
      %lay = cute.get_layout(%arg0) : !memref_gmem_f32_
      %lay_9 = cute.get_layout(%arg1) : !memref_gmem_i8_
      %lay_10 = cute.get_layout(%arg2) : !cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">
      %lay_11 = cute.get_layout(%arg0) : !memref_gmem_f32_
      %lay_12 = cute.get_layout(%arg1) : !memref_gmem_i8_
      %lay_13 = cute.get_layout(%arg2) : !cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">
      %0 = nvvm.read.ptx.sreg.tid.x : i32
      %1 = nvvm.read.ptx.sreg.ctaid.x : i32
      %coord = cute.make_coord(%1) : (i32) -> !cute.coord<"(_,?)">
      %slice = cute.slice(%arg0, %coord) : !memref_gmem_f32_, !cute.coord<"(_,?)">
      %iter_14 = cute.get_iter(%slice) : !memref_gmem_f32_1
      %iter_15 = cute.get_iter(%slice) : !memref_gmem_f32_1
      %coord_16 = cute.make_coord(%1) : (i32) -> !cute.coord<"(_,?)">
      %slice_17 = cute.slice(%arg1, %coord_16) : !memref_gmem_i8_, !cute.coord<"(_,?)">
      %iter_18 = cute.get_iter(%slice_17) : !memref_gmem_i8_1
      %iter_19 = cute.get_iter(%slice_17) : !memref_gmem_i8_1
      %coord_20 = cute.make_coord(%1) : (i32) -> !cute.coord<"(_,?)">
      %slice_21 = cute.slice(%arg2, %coord_20) : !cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">, !cute.coord<"(_,?)">
      %iter_22 = cute.get_iter(%slice_21) : !cute.coord_tensor<"(?,?{div=1024},?)", "((1,1024,1)):((0,1@1,0))">
      %tup_23 = cute.deref_arith_tuple_iter(%iter_22) : !cute.arith_tuple_iter<"(?,?{div=1024},?)">
      %e0_24, %e1_25, %e2_26 = cute.get_leaves(%tup_23) : !cute.int_tuple<"(?,?{div=1024},?)">
      %2 = cute.get_scalars(%e0_24) : !cute.int_tuple<"?">
      %3 = cute.get_scalars(%e1_25) : !cute.int_tuple<"?{div=1024}">
      %4 = cute.get_scalars(%e2_26) : !cute.int_tuple<"?">
      %iter_27 = cute.get_iter(%slice_21) : !cute.coord_tensor<"(?,?{div=1024},?)", "((1,1024,1)):((0,1@1,0))">
      %tup_28 = cute.deref_arith_tuple_iter(%iter_27) : !cute.arith_tuple_iter<"(?,?{div=1024},?)">
      %e0_29, %e1_30, %e2_31 = cute.get_leaves(%tup_28) : !cute.int_tuple<"(?,?{div=1024},?)">
      %5 = cute.get_scalars(%e0_29) : !cute.int_tuple<"?">
      %6 = cute.get_scalars(%e1_30) : !cute.int_tuple<"?{div=1024}">
      %7 = cute.get_scalars(%e2_31) : !cute.int_tuple<"?">
      %8 = cute.composition(%slice, %arg3) : (!memref_gmem_f32_1, !cute.layout<"(128,8):(8,1)">) -> !memref_gmem_f32_2
      %iter_32 = cute.get_iter(%8) : !memref_gmem_f32_2
      %9 = cute.composition(%slice_17, %arg4) : (!memref_gmem_i8_1, !cute.layout<"(128,4):(4,1)">) -> !memref_gmem_i8_2
      %iter_33 = cute.get_iter(%9) : !memref_gmem_i8_2
      %10 = cute.composition(%slice_21, %arg3) : (!cute.coord_tensor<"(?,?{div=1024},?)", "((1,1024,1)):((0,1@1,0))">, !cute.layout<"(128,8):(8,1)">) -> !cute.coord_tensor<"(?,?{div=1024},?)", "(128,8):(8@1,1@1)">
      %iter_34 = cute.get_iter(%10) : !cute.coord_tensor<"(?,?{div=1024},?)", "(128,8):(8@1,1@1)">
      %tup_35 = cute.deref_arith_tuple_iter(%iter_34) : !cute.arith_tuple_iter<"(?,?{div=1024},?)">
      %e0_36, %e1_37, %e2_38 = cute.get_leaves(%tup_35) : !cute.int_tuple<"(?,?{div=1024},?)">
      %11 = cute.get_scalars(%e0_36) : !cute.int_tuple<"?">
      %12 = cute.get_scalars(%e1_37) : !cute.int_tuple<"?{div=1024}">
      %13 = cute.get_scalars(%e2_38) : !cute.int_tuple<"?">
      %coord_39 = cute.make_coord(%0) : (i32) -> !cute.coord<"(?,_)">
      %slice_40 = cute.slice(%8, %coord_39) : !memref_gmem_f32_2, !cute.coord<"(?,_)">
      %iter_41 = cute.get_iter(%slice_40) : !memref_gmem_f32_3
      %iter_42 = cute.get_iter(%slice_40) : !memref_gmem_f32_3
      %coord_43 = cute.make_coord(%0) : (i32) -> !cute.coord<"(?,_)">
      %slice_44 = cute.slice(%9, %coord_43) : !memref_gmem_i8_2, !cute.coord<"(?,_)">
      %iter_45 = cute.get_iter(%slice_44) : !memref_gmem_i8_3
      %iter_46 = cute.get_iter(%slice_44) : !memref_gmem_i8_3
      %coord_47 = cute.make_coord(%0) : (i32) -> !cute.coord<"(?,_)">
      %slice_48 = cute.slice(%10, %coord_47) : !cute.coord_tensor<"(?,?{div=1024},?)", "(128,8):(8@1,1@1)">, !cute.coord<"(?,_)">
      %iter_49 = cute.get_iter(%slice_48) : !cute.coord_tensor<"(?,?{div=8},?)", "(8):(1@1)">
      %tup_50 = cute.deref_arith_tuple_iter(%iter_49) : !cute.arith_tuple_iter<"(?,?{div=8},?)">
      %e0_51, %e1_52, %e2_53 = cute.get_leaves(%tup_50) : !cute.int_tuple<"(?,?{div=8},?)">
      %14 = cute.get_scalars(%e0_51) : !cute.int_tuple<"?">
      %15 = cute.get_scalars(%e1_52) : !cute.int_tuple<"?{div=8}">
      %16 = cute.get_scalars(%e2_53) : !cute.int_tuple<"?">
      %iter_54 = cute.get_iter(%slice_48) : !cute.coord_tensor<"(?,?{div=8},?)", "(8):(1@1)">
      %tup_55 = cute.deref_arith_tuple_iter(%iter_54) : !cute.arith_tuple_iter<"(?,?{div=8},?)">
      %e0_56, %e1_57, %e2_58 = cute.get_leaves(%tup_55) : !cute.int_tuple<"(?,?{div=8},?)">
      %17 = cute.get_scalars(%e0_56) : !cute.int_tuple<"?">
      %18 = cute.get_scalars(%e1_57) : !cute.int_tuple<"?{div=8}">
      %19 = cute.get_scalars(%e2_58) : !cute.int_tuple<"?">
      %coord_59 = cute.make_coord() : () -> !cute.coord<"0">
      %slice_60 = cute.slice(%slice_48, %coord_59) : !cute.coord_tensor<"(?,?{div=8},?)", "(8):(1@1)">, !cute.coord<"0">
      %iter_61 = cute.get_iter(%slice_60) : !cute.coord_tensor<"(?,?{div=8},?)", "():()">
      %tup_62 = cute.deref_arith_tuple_iter(%iter_61) : !cute.arith_tuple_iter<"(?,?{div=8},?)">
      %e0_63, %e1_64, %e2_65 = cute.get_leaves(%tup_62) : !cute.int_tuple<"(?,?{div=8},?)">
      %20 = cute.get_scalars(%e0_63) : !cute.int_tuple<"?">
      %21 = cute.get_scalars(%e1_64) : !cute.int_tuple<"?{div=8}">
      %22 = cute.get_scalars(%e2_65) : !cute.int_tuple<"?">
      %iter_66 = cute.get_iter(%slice_60) : !cute.coord_tensor<"(?,?{div=8},?)", "():()">
      %tup_67 = cute.deref_arith_tuple_iter(%iter_66) : !cute.arith_tuple_iter<"(?,?{div=8},?)">
      %e0_68, %e1_69, %e2_70 = cute.get_leaves(%tup_67) : !cute.int_tuple<"(?,?{div=8},?)">
      %23 = cute.get_scalars(%e0_68) : !cute.int_tuple<"?">
      %24 = cute.get_scalars(%e1_69) : !cute.int_tuple<"?{div=8}">
      %25 = cute.get_scalars(%e2_70) : !cute.int_tuple<"?">
      %iter_71 = cute.get_iter(%slice_60) : !cute.coord_tensor<"(?,?{div=8},?)", "():()">
      %tup_72 = cute.deref_arith_tuple_iter(%iter_71) : !cute.arith_tuple_iter<"(?,?{div=8},?)">
      %e0_73, %e1_74, %e2_75 = cute.get_leaves(%tup_72) : !cute.int_tuple<"(?,?{div=8},?)">
      %26 = cute.get_scalars(%e0_73) : !cute.int_tuple<"?">
      %27 = cute.get_scalars(%e1_74) : !cute.int_tuple<"?{div=8}">
      %28 = cute.get_scalars(%e2_75) : !cute.int_tuple<"?">
      %coord_76 = cute.make_coord(%e0_73, %e1_74, %e2_75) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?{div=8},?)">
      %coord_77 = cute.make_coord(%arg5, %arg6, %arg7) : (i32, i32, i32) -> !cute.coord<"(?,?,?)">
      %29 = cute.elem_less(%coord_76, %coord_77) : !cute.coord<"(?,?{div=8},?)">, !cute.coord<"(?,?,?)">
      scf.if %29 {
        %30 = cute.get_shape(%arg3) : (!cute.layout<"(128,8):(8,1)">) -> !cute.shape<"(128,8)">
        %e0_78, %e1_79 = cute.get_leaves(%30) : !cute.shape<"(128,8)">
        %31 = cute.get_shape(%arg3) : (!cute.layout<"(128,8):(8,1)">) -> !cute.shape<"(128,8)">
        %e0_80, %e1_81 = cute.get_leaves(%31) : !cute.shape<"(128,8)">
        %32 = cute.get(%arg3) <{mode = [1]}> : !cute.layout<"(128,8):(8,1)"> -> !cute.layout<"8:1">
        %rmem = cute.memref.alloca(%32) : !memref_rmem_f32_
        %iter_82 = cute.get_iter(%rmem) : !memref_rmem_f32_
        %iter_83 = cute.get_iter(%rmem) : !memref_rmem_f32_
        %33 = cute.get_shape(%arg4) : (!cute.layout<"(128,4):(4,1)">) -> !cute.shape<"(128,4)">
        %e0_84, %e1_85 = cute.get_leaves(%33) : !cute.shape<"(128,4)">
        %34 = cute.get_shape(%arg4) : (!cute.layout<"(128,4):(4,1)">) -> !cute.shape<"(128,4)">
        %e0_86, %e1_87 = cute.get_leaves(%34) : !cute.shape<"(128,4)">
        %35 = cute.get(%arg4) <{mode = [1]}> : !cute.layout<"(128,4):(4,1)"> -> !cute.layout<"4:1">
        %rmem_88 = cute.memref.alloca(%35) : !memref_rmem_i8_
        %iter_89 = cute.get_iter(%rmem_88) : !memref_rmem_i8_
        %iter_90 = cute.get_iter(%rmem_88) : !memref_rmem_i8_
        %atom = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<f32>
        %lay_91 = cute.get_layout(%slice_40) : !memref_gmem_f32_3
        %36 = cute.get_shape(%lay_91) : (!cute.layout<"(8):(1)">) -> !cute.shape<"(8)">
        %e0_92 = cute.get_leaves(%36) : !cute.shape<"(8)">
        %lay_93 = cute.get_layout(%rmem) : !memref_rmem_f32_
        %37 = cute.get_shape(%lay_93) : (!cute.layout<"8:1">) -> !cute.shape<"8">
        %e0_94 = cute.get_leaves(%37) : !cute.shape<"8">
        %lay_95 = cute.get_layout(%slice_40) : !memref_gmem_f32_3
        %shape = cute.make_shape() : () -> !cute.shape<"1">
        %lay_96 = cute.make_layout(%shape) : !cute.layout<"1:0">
        %append = cute.append_to_rank<2> (%lay_95, %lay_96) : !cute.layout<"(8):(1)">, !cute.layout<"1:0">
        %view = cute.make_view(%iter_42, %append) : !memref_gmem_f32_4
        %iter_97 = cute.get_iter(%view) : !memref_gmem_f32_4
        %lay_98 = cute.get_layout(%view) : !memref_gmem_f32_4
        %38 = cute.get_shape(%lay_98) : (!cute.layout<"(8,1):(1,0)">) -> !cute.shape<"(8,1)">
        %e0_99, %e1_100 = cute.get_leaves(%38) : !cute.shape<"(8,1)">
        %lay_101 = cute.get_layout(%view) : !memref_gmem_f32_4
        %39 = cute.get_shape(%lay_101) : (!cute.layout<"(8,1):(1,0)">) -> !cute.shape<"(8,1)">
        %e0_102, %e1_103 = cute.get_leaves(%39) : !cute.shape<"(8,1)">
        %grouped = cute.group_modes(%view) <1, 2> : (!memref_gmem_f32_4) -> !memref_gmem_f32_5
        %iter_104 = cute.get_iter(%grouped) : !memref_gmem_f32_5
        %iter_105 = cute.get_iter(%grouped) : !memref_gmem_f32_5
        %lay_106 = cute.get_layout(%rmem) : !memref_rmem_f32_
        %shape_107 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_108 = cute.make_layout(%shape_107) : !cute.layout<"1:0">
        %append_109 = cute.append_to_rank<2> (%lay_106, %lay_108) : !cute.layout<"8:1">, !cute.layout<"1:0">
        %view_110 = cute.make_view(%iter_83, %append_109) : !memref_rmem_f32_1
        %iter_111 = cute.get_iter(%view_110) : !memref_rmem_f32_1
        %lay_112 = cute.get_layout(%view_110) : !memref_rmem_f32_1
        %40 = cute.get_shape(%lay_112) : (!cute.layout<"(8,1):(1,0)">) -> !cute.shape<"(8,1)">
        %e0_113, %e1_114 = cute.get_leaves(%40) : !cute.shape<"(8,1)">
        %lay_115 = cute.get_layout(%view_110) : !memref_rmem_f32_1
        %41 = cute.get_shape(%lay_115) : (!cute.layout<"(8,1):(1,0)">) -> !cute.shape<"(8,1)">
        %e0_116, %e1_117 = cute.get_leaves(%41) : !cute.shape<"(8,1)">
        %grouped_118 = cute.group_modes(%view_110) <1, 2> : (!memref_rmem_f32_1) -> !memref_rmem_f32_2
        %iter_119 = cute.get_iter(%grouped_118) : !memref_rmem_f32_2
        %iter_120 = cute.get_iter(%grouped_118) : !memref_rmem_f32_2
        %lay_121 = cute.get_layout(%grouped) : !memref_gmem_f32_5
        %42 = cute.get_shape(%lay_121) : (!cute.layout<"(8,(1)):(1,(0))">) -> !cute.shape<"(8,(1))">
        %e0_122, %e1_123 = cute.get_leaves(%42) : !cute.shape<"(8,(1))">
        %lay_124 = cute.get_layout(%grouped_118) : !memref_rmem_f32_2
        %43 = cute.get_shape(%lay_124) : (!cute.layout<"(8,(1)):(1,(0))">) -> !cute.shape<"(8,(1))">
        %e0_125, %e1_126 = cute.get_leaves(%43) : !cute.shape<"(8,(1))">
        %sz = cute.size(%grouped) <{mode = [1]}> : (!memref_gmem_f32_5) -> !cute.int_tuple<"1">
        %e0_127 = cute.get_leaves(%sz) : !cute.int_tuple<"1">
        %sz_128 = cute.size(%grouped_118) <{mode = [1]}> : (!memref_rmem_f32_2) -> !cute.int_tuple<"1">
        %e0_129 = cute.get_leaves(%sz_128) : !cute.int_tuple<"1">
        cute.copy(%atom, %grouped, %grouped_118) : (!cute_nvgpu.atom.universal_copy<f32>, !memref_gmem_f32_5, !memref_rmem_f32_2)
        %lay_130 = cute.get_layout(%rmem) : !memref_rmem_f32_
        %44 = cute.get_shape(%lay_130) : (!cute.layout<"8:1">) -> !cute.shape<"8">
        %e0_131 = cute.get_leaves(%44) : !cute.shape<"8">
        %45 = cute.memref.load_vec %rmem : !memref_rmem_f32_
        %lay_132 = cute.get_layout(%rmem) : !memref_rmem_f32_
        %46 = cute.get_shape(%lay_132) : (!cute.layout<"8:1">) -> !cute.shape<"8">
        %e0_133 = cute.get_leaves(%46) : !cute.shape<"8">
        %47 = nvgpu.cvt_fptrunc %45 : vector<8xf32> to vector<8xf4E2M1FN>
        %shape_134 = cute.make_shape() : () -> !cute.shape<"8">
        %lay_135 = cute.make_layout(%shape_134) : !cute.layout<"8:1">
        %48 = cute.recast_layout<8, 4> (%lay_135) : !cute.layout<"8:1"> to !cute.layout<"4:1">
        %49 = cute.get_shape(%48) : (!cute.layout<"4:1">) -> !cute.shape<"4">
        %e0_136 = cute.get_leaves(%49) : !cute.shape<"4">
        %50 = builtin.unrealized_conversion_cast %47 : vector<8xf4E2M1FN> to vector<8xi4>
        %51 = vector.bitcast %50 : vector<8xi4> to vector<4xi8>
        %lay_137 = cute.get_layout(%rmem_88) : !memref_rmem_i8_
        %52 = cute.get_shape(%lay_137) : (!cute.layout<"4:1">) -> !cute.shape<"4">
        %e0_138 = cute.get_leaves(%52) : !cute.shape<"4">
        %lay_139 = cute.get_layout(%rmem_88) : !memref_rmem_i8_
        %53 = cute.get_shape(%lay_139) : (!cute.layout<"4:1">) -> !cute.shape<"4">
        %e0_140 = cute.get_leaves(%53) : !cute.shape<"4">
        %int_tuple = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
        %sz_141 = cute.size(%int_tuple) : (!cute.int_tuple<"4">) -> !cute.int_tuple<"4">
        %e0_142 = cute.get_leaves(%sz_141) : !cute.int_tuple<"4">
        %int_tuple_143 = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
        %sz_144 = cute.size(%int_tuple_143) : (!cute.int_tuple<"4">) -> !cute.int_tuple<"4">
        %e0_145 = cute.get_leaves(%sz_144) : !cute.int_tuple<"4">
        cute.memref.store_vec %51, %rmem_88 : !memref_rmem_i8_
        %atom_146 = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<i8>
        %lay_147 = cute.get_layout(%rmem_88) : !memref_rmem_i8_
        %54 = cute.get_shape(%lay_147) : (!cute.layout<"4:1">) -> !cute.shape<"4">
        %e0_148 = cute.get_leaves(%54) : !cute.shape<"4">
        %lay_149 = cute.get_layout(%slice_44) : !memref_gmem_i8_3
        %55 = cute.get_shape(%lay_149) : (!cute.layout<"(4):(1)">) -> !cute.shape<"(4)">
        %e0_150 = cute.get_leaves(%55) : !cute.shape<"(4)">
        %lay_151 = cute.get_layout(%rmem_88) : !memref_rmem_i8_
        %shape_152 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_153 = cute.make_layout(%shape_152) : !cute.layout<"1:0">
        %append_154 = cute.append_to_rank<2> (%lay_151, %lay_153) : !cute.layout<"4:1">, !cute.layout<"1:0">
        %view_155 = cute.make_view(%iter_90, %append_154) : !memref_rmem_i8_1
        %iter_156 = cute.get_iter(%view_155) : !memref_rmem_i8_1
        %lay_157 = cute.get_layout(%view_155) : !memref_rmem_i8_1
        %56 = cute.get_shape(%lay_157) : (!cute.layout<"(4,1):(1,0)">) -> !cute.shape<"(4,1)">
        %e0_158, %e1_159 = cute.get_leaves(%56) : !cute.shape<"(4,1)">
        %lay_160 = cute.get_layout(%view_155) : !memref_rmem_i8_1
        %57 = cute.get_shape(%lay_160) : (!cute.layout<"(4,1):(1,0)">) -> !cute.shape<"(4,1)">
        %e0_161, %e1_162 = cute.get_leaves(%57) : !cute.shape<"(4,1)">
        %grouped_163 = cute.group_modes(%view_155) <1, 2> : (!memref_rmem_i8_1) -> !memref_rmem_i8_2
        %iter_164 = cute.get_iter(%grouped_163) : !memref_rmem_i8_2
        %iter_165 = cute.get_iter(%grouped_163) : !memref_rmem_i8_2
        %lay_166 = cute.get_layout(%slice_44) : !memref_gmem_i8_3
        %shape_167 = cute.make_shape() : () -> !cute.shape<"1">
        %lay_168 = cute.make_layout(%shape_167) : !cute.layout<"1:0">
        %append_169 = cute.append_to_rank<2> (%lay_166, %lay_168) : !cute.layout<"(4):(1)">, !cute.layout<"1:0">
        %view_170 = cute.make_view(%iter_46, %append_169) : !memref_gmem_i8_4
        %iter_171 = cute.get_iter(%view_170) : !memref_gmem_i8_4
        %lay_172 = cute.get_layout(%view_170) : !memref_gmem_i8_4
        %58 = cute.get_shape(%lay_172) : (!cute.layout<"(4,1):(1,0)">) -> !cute.shape<"(4,1)">
        %e0_173, %e1_174 = cute.get_leaves(%58) : !cute.shape<"(4,1)">
        %lay_175 = cute.get_layout(%view_170) : !memref_gmem_i8_4
        %59 = cute.get_shape(%lay_175) : (!cute.layout<"(4,1):(1,0)">) -> !cute.shape<"(4,1)">
        %e0_176, %e1_177 = cute.get_leaves(%59) : !cute.shape<"(4,1)">
        %grouped_178 = cute.group_modes(%view_170) <1, 2> : (!memref_gmem_i8_4) -> !memref_gmem_i8_5
        %iter_179 = cute.get_iter(%grouped_178) : !memref_gmem_i8_5
        %iter_180 = cute.get_iter(%grouped_178) : !memref_gmem_i8_5
        %lay_181 = cute.get_layout(%grouped_163) : !memref_rmem_i8_2
        %60 = cute.get_shape(%lay_181) : (!cute.layout<"(4,(1)):(1,(0))">) -> !cute.shape<"(4,(1))">
        %e0_182, %e1_183 = cute.get_leaves(%60) : !cute.shape<"(4,(1))">
        %lay_184 = cute.get_layout(%grouped_178) : !memref_gmem_i8_5
        %61 = cute.get_shape(%lay_184) : (!cute.layout<"(4,(1)):(1,(0))">) -> !cute.shape<"(4,(1))">
        %e0_185, %e1_186 = cute.get_leaves(%61) : !cute.shape<"(4,(1))">
        %sz_187 = cute.size(%grouped_163) <{mode = [1]}> : (!memref_rmem_i8_2) -> !cute.int_tuple<"1">
        %e0_188 = cute.get_leaves(%sz_187) : !cute.int_tuple<"1">
        %sz_189 = cute.size(%grouped_178) <{mode = [1]}> : (!memref_gmem_i8_5) -> !cute.int_tuple<"1">
        %e0_190 = cute.get_leaves(%sz_189) : !cute.int_tuple<"1">
        cute.copy(%atom_146, %grouped_163, %grouped_178) : (!cute_nvgpu.atom.universal_copy<i8>, !memref_rmem_i8_2, !memref_gmem_i8_5)
      }
      return
    }
  }
  func.func @cutlass__convert_Tensorgmemoi641i64_Tensorgmemoi641i64_1_8(%arg0: !memref_gmem_f32_6, %arg1: !memref_gmem_f4E2M1FN) -> i32 attributes {llvm.emit_c_interface} {
    %iter = cute.get_iter(%arg0) : !memref_gmem_f32_6
    %iter_0 = cute.get_iter(%arg1) : !memref_gmem_f4E2M1FN
    %iter_1 = cute.get_iter(%arg0) : !memref_gmem_f32_6
    %iter_2 = cute.get_iter(%arg1) : !memref_gmem_f4E2M1FN
    %lay = cute.get_layout(%arg0) : !memref_gmem_f32_6
    %lay_3 = cute.get_layout(%arg1) : !memref_gmem_f4E2M1FN
    %shape = cute.make_shape() : () -> !cute.shape<"(128,8)">
    %stride = cute.make_stride() : () -> !cute.stride<"(8,1)">
    %lay_4 = cute.make_layout(%shape, %stride) : !cute.layout<"(128,8):(8,1)">
    %0 = cute.recast_layout<8, 4> (%lay_4) : !cute.layout<"(128,8):(8,1)"> to !cute.layout<"(128,4):(4,1)">
    %iter_5 = cute.recast_iter(%iter_2) : !cute.ptr<f4E2M1FN, gmem, align<16>> to !cute.ptr<i8, gmem, align<16>>
    %lay_6 = cute.get_layout(%arg1) : !memref_gmem_f4E2M1FN
    %1 = cute.recast_layout<8, 4> (%lay_6) : !cute.layout<"(?,?,?):(?{i64},1,?{i64})"> to !cute.layout<"(?,?,?):(?{i64},1,?{i64})">
    %view = cute.make_view(%iter_5, %1) : !memref_gmem_i8_6
    %iter_7 = cute.get_iter(%view) : !memref_gmem_i8_6
    %lay_8 = cute.get_layout(%arg0) : !memref_gmem_f32_6
    %2 = cute.get_shape(%lay_8) : (!cute.layout<"(?,?,?):(?{i64},1,?{i64})">) -> !cute.shape<"(?,?,?)">
    %e0, %e1, %e2 = cute.get_leaves(%2) : !cute.shape<"(?,?,?)">
    %itup = cute.to_int_tuple(%e0) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %3 = cute.get_scalars(%itup) : !cute.int_tuple<"?">
    %itup_9 = cute.to_int_tuple(%e1) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %4 = cute.get_scalars(%itup_9) : !cute.int_tuple<"?">
    %itup_10 = cute.to_int_tuple(%e2) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %5 = cute.get_scalars(%itup_10) : !cute.int_tuple<"?">
    %lay_11 = cute.get_layout(%arg0) : !memref_gmem_f32_6
    %6 = cute.get_shape(%lay_11) : (!cute.layout<"(?,?,?):(?{i64},1,?{i64})">) -> !cute.shape<"(?,?,?)">
    %e0_12, %e1_13, %e2_14 = cute.get_leaves(%6) : !cute.shape<"(?,?,?)">
    %itup_15 = cute.to_int_tuple(%e0_12) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %7 = cute.get_scalars(%itup_15) : !cute.int_tuple<"?">
    %itup_16 = cute.to_int_tuple(%e1_13) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %8 = cute.get_scalars(%itup_16) : !cute.int_tuple<"?">
    %itup_17 = cute.to_int_tuple(%e2_14) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %9 = cute.get_scalars(%itup_17) : !cute.int_tuple<"?">
    %shape_18 = cute.make_shape(%itup_15, %itup_16, %itup_17) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.shape<"(?,?,?)">
    %10 = cute.make_identity_tensor(%shape_18) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">
    %iter_19 = cute.get_iter(%10) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">
    %tup = cute.deref_arith_tuple_iter(%iter_19) : !cute.arith_tuple_iter<"(0,0,0)">
    %e0_20, %e1_21, %e2_22 = cute.get_leaves(%tup) : !cute.int_tuple<"(0,0,0)">
    %lay_23 = cute.get_layout(%arg0) : !memref_gmem_f32_6
    %11 = cute.get_shape(%lay_23) : (!cute.layout<"(?,?,?):(?{i64},1,?{i64})">) -> !cute.shape<"(?,?,?)">
    %e0_24, %e1_25, %e2_26 = cute.get_leaves(%11) : !cute.shape<"(?,?,?)">
    %itup_27 = cute.to_int_tuple(%e0_24) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %12 = cute.get_scalars(%itup_27) : !cute.int_tuple<"?">
    %itup_28 = cute.to_int_tuple(%e1_25) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %13 = cute.get_scalars(%itup_28) : !cute.int_tuple<"?">
    %itup_29 = cute.to_int_tuple(%e2_26) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %14 = cute.get_scalars(%itup_29) : !cute.int_tuple<"?">
    %sz = cute.size(%lay_4) : (!cute.layout<"(128,8):(8,1)">) -> !cute.int_tuple<"1024">
    %e0_30 = cute.get_leaves(%sz) : !cute.int_tuple<"1024">
    %lay_31 = cute.get_layout(%view) : !memref_gmem_i8_6
    %15 = cute.get_shape(%lay_31) : (!cute.layout<"(?,?,?):(?{i64},1,?{i64})">) -> !cute.shape<"(?,?,?)">
    %e0_32, %e1_33, %e2_34 = cute.get_leaves(%15) : !cute.shape<"(?,?,?)">
    %itup_35 = cute.to_int_tuple(%e0_32) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %16 = cute.get_scalars(%itup_35) : !cute.int_tuple<"?">
    %itup_36 = cute.to_int_tuple(%e1_33) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %17 = cute.get_scalars(%itup_36) : !cute.int_tuple<"?">
    %itup_37 = cute.to_int_tuple(%e2_34) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %18 = cute.get_scalars(%itup_37) : !cute.int_tuple<"?">
    %sz_38 = cute.size(%0) : (!cute.layout<"(128,4):(4,1)">) -> !cute.int_tuple<"512">
    %e0_39 = cute.get_leaves(%sz_38) : !cute.int_tuple<"512">
    %tile = cute.make_tile() : () -> !cute.tile<"[1:0;1024:1;1:0]">
    %div = cute.zipped_divide(%arg0, %tile) : !memref_gmem_f32_6, !cute.tile<"[1:0;1024:1;1:0]">
    %iter_40 = cute.get_iter(%div) : !memref_gmem_f32_
    %iter_41 = cute.get_iter(%div) : !memref_gmem_f32_
    %tile_42 = cute.make_tile() : () -> !cute.tile<"[1:0;1024:1;1:0]">
    %div_43 = cute.zipped_divide(%10, %tile_42) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">, !cute.tile<"[1:0;1024:1;1:0]">
    %iter_44 = cute.get_iter(%div_43) : !cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">
    %tup_45 = cute.deref_arith_tuple_iter(%iter_44) : !cute.arith_tuple_iter<"(0,0,0)">
    %e0_46, %e1_47, %e2_48 = cute.get_leaves(%tup_45) : !cute.int_tuple<"(0,0,0)">
    %iter_49 = cute.get_iter(%div_43) : !cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">
    %tup_50 = cute.deref_arith_tuple_iter(%iter_49) : !cute.arith_tuple_iter<"(0,0,0)">
    %e0_51, %e1_52, %e2_53 = cute.get_leaves(%tup_50) : !cute.int_tuple<"(0,0,0)">
    %tile_54 = cute.make_tile() : () -> !cute.tile<"[1:0;512:1;1:0]">
    %div_55 = cute.zipped_divide(%view, %tile_54) : !memref_gmem_i8_6, !cute.tile<"[1:0;512:1;1:0]">
    %iter_56 = cute.get_iter(%div_55) : !memref_gmem_i8_
    %iter_57 = cute.get_iter(%div_55) : !memref_gmem_i8_
    %sz_58 = cute.size(%div) <{mode = [1]}> : (!memref_gmem_f32_) -> !cute.int_tuple<"?">
    %e0_59 = cute.get_leaves(%sz_58) : !cute.int_tuple<"?">
    %19 = cute.get_scalars(%e0_59) : !cute.int_tuple<"?">
    %sz_60 = cute.size(%lay_4) <{mode = [0]}> : (!cute.layout<"(128,8):(8,1)">) -> !cute.int_tuple<"128">
    %e0_61 = cute.get_leaves(%sz_60) : !cute.int_tuple<"128">
    %lay_62 = cute.get_layout(%div) : !memref_gmem_f32_
    %lay_63 = cute.get_layout(%div_55) : !memref_gmem_i8_
    %lay_64 = cute.get_layout(%div_43) : !cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">
    %c0_i32 = arith.constant 0 : i32
    %c0_i64 = arith.constant 0 : i64
    %20 = cuda.cast %c0_i64 : i64 -> !cuda.stream
    %21 = arith.extsi %c0_i32 : i32 to i64
    %c128_i32 = arith.constant 128 : i32
    %c1_i32 = arith.constant 1 : i32
    %22 = cuda.launch_cfg.create<max_attrs = 3 : i32> (blockDim = (%c128_i32, %c1_i32, %c1_i32), dynamicSmemBytes = %21, gridDim = (%19, %c1_i32, %c1_i32), stream = %20) : i32, i32, i32, i64, i32, i32, i32, !cuda.stream -> !cuda.launch_cfg<max_attrs = 3>
    %c0_i32_65 = arith.constant 0 : i32
    cuda.launch_cfg.programmatic_stream_serialization_allowed[%22] %c0_i32_65 : !cuda.launch_cfg<max_attrs = 3>, i32
    %c0_i32_66 = arith.constant 0 : i32
    cuda.launch_cfg.cooperative[%22] %c0_i32_66 : !cuda.launch_cfg<max_attrs = 3>, i32
    %23 = cuda.launch_ex @kernels::@kernel_cutlass__convert_kernel_tensorptrf32gmemo110241010i641024i64_tensorptri8gmemalign16o15121010i64512i64_tensor000o1102410110101024112____Float32_Float4E2M1FN_0<%22> (%div, %div_55, %div_43, %lay_4, %0, %3, %4, %5) {assume_kernel_attr = #cuda.assume_kernel_attr<true>} : !cuda.launch_cfg<max_attrs = 3>, (!memref_gmem_f32_, !memref_gmem_i8_, !cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">, !cute.layout<"(128,8):(8,1)">, !cute.layout<"(128,4):(4,1)">, i32, i32, i32) -> !cuda.result
    %24 = cuda.cast %23 : !cuda.result -> i32
    cuda.return_if_error %24 : i32
    %c0_i32_67 = arith.constant 0 : i32
    return %c0_i32_67 : i32
  }
}

