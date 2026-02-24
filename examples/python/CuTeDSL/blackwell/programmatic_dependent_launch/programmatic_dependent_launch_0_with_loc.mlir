

!copy_simt = !cute.tiled_copy<!cute_nvgpu.atom.universal_copy<f32>, layout_copy_tv = <"((32,4),(4,4)):((64,4),(16,1))">, tiler_mn = <"[16:1;128:1]">>
!memref_gmem_f32_ = !cute.memref<f32, gmem, "((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
!memref_gmem_f32_1 = !cute.memref<f32, gmem, "(16,128):(?{i64},1)">
!memref_gmem_f32_2 = !cute.memref<f32, gmem, "((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
!memref_gmem_f32_3 = !cute.memref<f32, gmem, "((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
!memref_gmem_f32_4 = !cute.memref<f32, gmem, "(?,?):(?{i64},1)">
!memref_rmem_f32_ = !cute.memref<f32, rmem, align<32>, "((1,(4,4)),1,1):((0,(1,4)),0,0)">
!memref_rmem_f32_1 = !cute.memref<f32, rmem, align<32>, "((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
!memref_rmem_i8_ = !cute.memref<i8, rmem, align<32>, "((1,(4,4)),1,1):((0,(1,4)),0,0)">
!memref_rmem_i8_1 = !cute.memref<i8, rmem, align<32>, "((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
module attributes {gpu.container_module} {
  gpu.module @kernels {
    cuda.kernel @kernel_cutlass_elementwise_add_kernel_tensorptrf32gmemo16128i641i64div16128_tensorptrf32gmemo16128i641i64div16128_tensorptrf32gmemo16128i641i64div16128_tensor00o1612810111601281___True_0(%arg0: !memref_gmem_f32_, %arg1: !memref_gmem_f32_, %arg2: !memref_gmem_f32_, %arg3: !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">, %arg4: i32, %arg5: i32, %arg6: !cute.layout<"(4,32):(32,1)">, %arg7: !cute.layout<"(4,4):(4,1)">) attributes {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} {
      %iter = cute.get_iter(%arg0) : !memref_gmem_f32_
      %iter_0 = cute.get_iter(%arg1) : !memref_gmem_f32_
      %iter_1 = cute.get_iter(%arg2) : !memref_gmem_f32_
      %iter_2 = cute.get_iter(%arg3) : !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
      %tup = cute.deref_arith_tuple_iter(%iter_2) : !cute.arith_tuple_iter<"(0,0)">
      %e0, %e1 = cute.get_leaves(%tup) : !cute.int_tuple<"(0,0)">
      %iter_3 = cute.get_iter(%arg0) : !memref_gmem_f32_
      %iter_4 = cute.get_iter(%arg1) : !memref_gmem_f32_
      %iter_5 = cute.get_iter(%arg2) : !memref_gmem_f32_
      %iter_6 = cute.get_iter(%arg3) : !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
      %tup_7 = cute.deref_arith_tuple_iter(%iter_6) : !cute.arith_tuple_iter<"(0,0)">
      %e0_8, %e1_9 = cute.get_leaves(%tup_7) : !cute.int_tuple<"(0,0)">
      %lay = cute.get_layout(%arg0) : !memref_gmem_f32_
      %lay_10 = cute.get_layout(%arg1) : !memref_gmem_f32_
      %lay_11 = cute.get_layout(%arg2) : !memref_gmem_f32_
      %lay_12 = cute.get_layout(%arg3) : !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
      %lay_13 = cute.get_layout(%arg0) : !memref_gmem_f32_
      %lay_14 = cute.get_layout(%arg1) : !memref_gmem_f32_
      %lay_15 = cute.get_layout(%arg2) : !memref_gmem_f32_
      %lay_16 = cute.get_layout(%arg3) : !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
      %0 = nvvm.read.ptx.sreg.tid.x : i32
      %1 = nvvm.read.ptx.sreg.tid.y : i32
      %2 = nvvm.read.ptx.sreg.tid.z : i32
      %3 = nvvm.read.ptx.sreg.ctaid.x : i32
      %4 = nvvm.read.ptx.sreg.ctaid.y : i32
      %5 = nvvm.read.ptx.sreg.ctaid.z : i32
      %coord = cute.make_coord(%3) : (i32) -> !cute.coord<"((_,_),?)">
      %slice = cute.slice(%arg0, %coord) : !memref_gmem_f32_, !cute.coord<"((_,_),?)">
      %iter_17 = cute.get_iter(%slice) : !memref_gmem_f32_1
      %iter_18 = cute.get_iter(%slice) : !memref_gmem_f32_1
      %coord_19 = cute.make_coord(%3) : (i32) -> !cute.coord<"((_,_),?)">
      %slice_20 = cute.slice(%arg1, %coord_19) : !memref_gmem_f32_, !cute.coord<"((_,_),?)">
      %iter_21 = cute.get_iter(%slice_20) : !memref_gmem_f32_1
      %iter_22 = cute.get_iter(%slice_20) : !memref_gmem_f32_1
      %coord_23 = cute.make_coord(%3) : (i32) -> !cute.coord<"((_,_),?)">
      %slice_24 = cute.slice(%arg2, %coord_23) : !memref_gmem_f32_, !cute.coord<"((_,_),?)">
      %iter_25 = cute.get_iter(%slice_24) : !memref_gmem_f32_1
      %iter_26 = cute.get_iter(%slice_24) : !memref_gmem_f32_1
      %coord_27 = cute.make_coord(%3) : (i32) -> !cute.coord<"((_,_),?)">
      %slice_28 = cute.slice(%arg3, %coord_27) : !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">, !cute.coord<"((_,_),?)">
      %iter_29 = cute.get_iter(%slice_28) : !cute.coord_tensor<"(?{div=16},?{div=128})", "(16,128):(1@0,1@1)">
      %tup_30 = cute.deref_arith_tuple_iter(%iter_29) : !cute.arith_tuple_iter<"(?{div=16},?{div=128})">
      %e0_31, %e1_32 = cute.get_leaves(%tup_30) : !cute.int_tuple<"(?{div=16},?{div=128})">
      %6 = cute.get_scalars(%e0_31) : !cute.int_tuple<"?{div=16}">
      %7 = cute.get_scalars(%e1_32) : !cute.int_tuple<"?{div=128}">
      %iter_33 = cute.get_iter(%slice_28) : !cute.coord_tensor<"(?{div=16},?{div=128})", "(16,128):(1@0,1@1)">
      %tup_34 = cute.deref_arith_tuple_iter(%iter_33) : !cute.arith_tuple_iter<"(?{div=16},?{div=128})">
      %e0_35, %e1_36 = cute.get_leaves(%tup_34) : !cute.int_tuple<"(?{div=16},?{div=128})">
      %8 = cute.get_scalars(%e0_35) : !cute.int_tuple<"?{div=16}">
      %9 = cute.get_scalars(%e1_36) : !cute.int_tuple<"?{div=128}">
      %atom = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<f32>
      %atom_37 = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<f32>
      %prod = cute.raked_product(%arg6, %arg7) : (!cute.layout<"(4,32):(32,1)">, !cute.layout<"(4,4):(4,1)">) -> !cute.layout<"((4,4),(4,32)):((512,32),(128,1))">
      %sz = cute.size(%arg6) : (!cute.layout<"(4,32):(32,1)">) -> !cute.int_tuple<"128">
      %e0_38 = cute.get_leaves(%sz) : !cute.int_tuple<"128">
      %sz_39 = cute.size(%arg7) : (!cute.layout<"(4,4):(4,1)">) -> !cute.int_tuple<"16">
      %e0_40 = cute.get_leaves(%sz_39) : !cute.int_tuple<"16">
      %shape = cute.make_shape() : () -> !cute.shape<"(128,16)">
      %lay_41 = cute.make_layout(%shape) : !cute.layout<"(128,16):(1,128)">
      %rinv = cute.right_inverse(%prod) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.layout<"(32,16,4):(64,4,1)">
      %10 = cute.composition(%rinv, %lay_41) : (!cute.layout<"(32,16,4):(64,4,1)">, !cute.layout<"(128,16):(1,128)">) -> !cute.layout<"((32,4),(4,4)):((64,4),(16,1))">
      %11 = cute.get_shape(%prod) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.shape<"((4,4),(4,32))">
      %e0_42, %e1_43, %e2, %e3 = cute.get_leaves(%11) : !cute.shape<"((4,4),(4,32))">
      %int_tuple = cute.make_int_tuple() : () -> !cute.int_tuple<"((4,4),(4,32))">
      %res = cute.tuple.product_each(%int_tuple) : (!cute.int_tuple<"((4,4),(4,32))">) -> !cute.int_tuple<"(16,128)">
      %e0_44, %e1_45 = cute.get_leaves(%res) : !cute.int_tuple<"(16,128)">
      %int_tuple_46 = cute.make_int_tuple() : () -> !cute.int_tuple<"(16,128)">
      %res_47 = cute.tuple.product_each(%int_tuple_46) : (!cute.int_tuple<"(16,128)">) -> !cute.int_tuple<"(16,128)">
      %e0_48, %e1_49 = cute.get_leaves(%res_47) : !cute.int_tuple<"(16,128)">
      %tile = cute.make_tile() : () -> !cute.tile<"[16:1;128:1]">
      %12 = cute.make_tiled_copy(%atom) : !copy_simt
      %prod_50 = cute.raked_product(%arg6, %arg7) : (!cute.layout<"(4,32):(32,1)">, !cute.layout<"(4,4):(4,1)">) -> !cute.layout<"((4,4),(4,32)):((512,32),(128,1))">
      %sz_51 = cute.size(%arg6) : (!cute.layout<"(4,32):(32,1)">) -> !cute.int_tuple<"128">
      %e0_52 = cute.get_leaves(%sz_51) : !cute.int_tuple<"128">
      %sz_53 = cute.size(%arg7) : (!cute.layout<"(4,4):(4,1)">) -> !cute.int_tuple<"16">
      %e0_54 = cute.get_leaves(%sz_53) : !cute.int_tuple<"16">
      %shape_55 = cute.make_shape() : () -> !cute.shape<"(128,16)">
      %lay_56 = cute.make_layout(%shape_55) : !cute.layout<"(128,16):(1,128)">
      %rinv_57 = cute.right_inverse(%prod_50) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.layout<"(32,16,4):(64,4,1)">
      %13 = cute.composition(%rinv_57, %lay_56) : (!cute.layout<"(32,16,4):(64,4,1)">, !cute.layout<"(128,16):(1,128)">) -> !cute.layout<"((32,4),(4,4)):((64,4),(16,1))">
      %14 = cute.get_shape(%prod_50) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.shape<"((4,4),(4,32))">
      %e0_58, %e1_59, %e2_60, %e3_61 = cute.get_leaves(%14) : !cute.shape<"((4,4),(4,32))">
      %int_tuple_62 = cute.make_int_tuple() : () -> !cute.int_tuple<"((4,4),(4,32))">
      %res_63 = cute.tuple.product_each(%int_tuple_62) : (!cute.int_tuple<"((4,4),(4,32))">) -> !cute.int_tuple<"(16,128)">
      %e0_64, %e1_65 = cute.get_leaves(%res_63) : !cute.int_tuple<"(16,128)">
      %int_tuple_66 = cute.make_int_tuple() : () -> !cute.int_tuple<"(16,128)">
      %res_67 = cute.tuple.product_each(%int_tuple_66) : (!cute.int_tuple<"(16,128)">) -> !cute.int_tuple<"(16,128)">
      %e0_68, %e1_69 = cute.get_leaves(%res_67) : !cute.int_tuple<"(16,128)">
      %tile_70 = cute.make_tile() : () -> !cute.tile<"[16:1;128:1]">
      %15 = cute.make_tiled_copy(%atom) : !copy_simt
      %prod_71 = cute.raked_product(%arg6, %arg7) : (!cute.layout<"(4,32):(32,1)">, !cute.layout<"(4,4):(4,1)">) -> !cute.layout<"((4,4),(4,32)):((512,32),(128,1))">
      %sz_72 = cute.size(%arg6) : (!cute.layout<"(4,32):(32,1)">) -> !cute.int_tuple<"128">
      %e0_73 = cute.get_leaves(%sz_72) : !cute.int_tuple<"128">
      %sz_74 = cute.size(%arg7) : (!cute.layout<"(4,4):(4,1)">) -> !cute.int_tuple<"16">
      %e0_75 = cute.get_leaves(%sz_74) : !cute.int_tuple<"16">
      %shape_76 = cute.make_shape() : () -> !cute.shape<"(128,16)">
      %lay_77 = cute.make_layout(%shape_76) : !cute.layout<"(128,16):(1,128)">
      %rinv_78 = cute.right_inverse(%prod_71) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.layout<"(32,16,4):(64,4,1)">
      %16 = cute.composition(%rinv_78, %lay_77) : (!cute.layout<"(32,16,4):(64,4,1)">, !cute.layout<"(128,16):(1,128)">) -> !cute.layout<"((32,4),(4,4)):((64,4),(16,1))">
      %17 = cute.get_shape(%prod_71) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.shape<"((4,4),(4,32))">
      %e0_79, %e1_80, %e2_81, %e3_82 = cute.get_leaves(%17) : !cute.shape<"((4,4),(4,32))">
      %int_tuple_83 = cute.make_int_tuple() : () -> !cute.int_tuple<"((4,4),(4,32))">
      %res_84 = cute.tuple.product_each(%int_tuple_83) : (!cute.int_tuple<"((4,4),(4,32))">) -> !cute.int_tuple<"(16,128)">
      %e0_85, %e1_86 = cute.get_leaves(%res_84) : !cute.int_tuple<"(16,128)">
      %int_tuple_87 = cute.make_int_tuple() : () -> !cute.int_tuple<"(16,128)">
      %res_88 = cute.tuple.product_each(%int_tuple_87) : (!cute.int_tuple<"(16,128)">) -> !cute.int_tuple<"(16,128)">
      %e0_89, %e1_90 = cute.get_leaves(%res_88) : !cute.int_tuple<"(16,128)">
      %tile_91 = cute.make_tile() : () -> !cute.tile<"[16:1;128:1]">
      %18 = cute.make_tiled_copy(%atom_37) : !copy_simt
      %coord_92 = cute.make_coord(%0) : (i32) -> !cute.coord<"?">
      %src_partitioned = cute.tiled.copy.partition_S(%12, %slice, %coord_92) : (!copy_simt, !memref_gmem_f32_1, !cute.coord<"?">) -> !memref_gmem_f32_2
      %iter_93 = cute.get_iter(%src_partitioned) : !memref_gmem_f32_2
      %coord_94 = cute.make_coord(%0) : (i32) -> !cute.coord<"?">
      %src_partitioned_95 = cute.tiled.copy.partition_S(%15, %slice_20, %coord_94) : (!copy_simt, !memref_gmem_f32_1, !cute.coord<"?">) -> !memref_gmem_f32_2
      %iter_96 = cute.get_iter(%src_partitioned_95) : !memref_gmem_f32_2
      %coord_97 = cute.make_coord(%0) : (i32) -> !cute.coord<"?">
      %src_partitioned_98 = cute.tiled.copy.partition_S(%18, %slice_24, %coord_97) : (!copy_simt, !memref_gmem_f32_1, !cute.coord<"?">) -> !memref_gmem_f32_2
      %iter_99 = cute.get_iter(%src_partitioned_98) : !memref_gmem_f32_2
      %lay_100 = cute.get_layout(%src_partitioned) : !memref_gmem_f32_2
      %19 = cute.make_layout_like(%lay_100) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)"> to !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %rmem = cute.memref.alloca(%19) : !memref_rmem_f32_
      %iter_101 = cute.get_iter(%rmem) : !memref_rmem_f32_
      %iter_102 = cute.get_iter(%rmem) : !memref_rmem_f32_
      %lay_103 = cute.get_layout(%src_partitioned_95) : !memref_gmem_f32_2
      %20 = cute.make_layout_like(%lay_103) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)"> to !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %rmem_104 = cute.memref.alloca(%20) : !memref_rmem_f32_
      %iter_105 = cute.get_iter(%rmem_104) : !memref_rmem_f32_
      %iter_106 = cute.get_iter(%rmem_104) : !memref_rmem_f32_
      %lay_107 = cute.get_layout(%src_partitioned_98) : !memref_gmem_f32_2
      %21 = cute.make_layout_like(%lay_107) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)"> to !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %rmem_108 = cute.memref.alloca(%21) : !memref_rmem_f32_
      %iter_109 = cute.get_iter(%rmem_108) : !memref_rmem_f32_
      %iter_110 = cute.get_iter(%rmem_108) : !memref_rmem_f32_
      %coord_111 = cute.make_coord(%0) : (i32) -> !cute.coord<"?">
      %src_partitioned_112 = cute.tiled.copy.partition_S(%18, %slice_28, %coord_111) : (!copy_simt, !cute.coord_tensor<"(?{div=16},?{div=128})", "(16,128):(1@0,1@1)">, !cute.coord<"?">) -> !cute.coord_tensor<"(?{div=4},?{div=4})", "((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">
      %iter_113 = cute.get_iter(%src_partitioned_112) : !cute.coord_tensor<"(?{div=4},?{div=4})", "((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">
      %tup_114 = cute.deref_arith_tuple_iter(%iter_113) : !cute.arith_tuple_iter<"(?{div=4},?{div=4})">
      %e0_115, %e1_116 = cute.get_leaves(%tup_114) : !cute.int_tuple<"(?{div=4},?{div=4})">
      %22 = cute.get_scalars(%e0_115) : !cute.int_tuple<"?{div=4}">
      %23 = cute.get_scalars(%e1_116) : !cute.int_tuple<"?{div=4}">
      %lay_117 = cute.get_layout(%src_partitioned_112) : !cute.coord_tensor<"(?{div=4},?{div=4})", "((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">
      %24 = cute.get_shape(%lay_117) : (!cute.layout<"((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_118, %e1_119, %e2_120, %e3_121, %e4 = cute.get_leaves(%24) : !cute.shape<"((1,(4,4)),1,1)">
      %shape_122 = cute.make_shape() : () -> !cute.shape<"((1,(4,4)),1,1)">
      %lay_123 = cute.make_layout(%shape_122) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %rmem_124 = cute.memref.alloca(%lay_123) : !memref_rmem_i8_
      %iter_125 = cute.get_iter(%rmem_124) : !memref_rmem_i8_
      %iter_126 = cute.get_iter(%rmem_124) : !memref_rmem_i8_
      %sz_127 = cute.size(%rmem_124) : (!memref_rmem_i8_) -> !cute.int_tuple<"16">
      %e0_128 = cute.get_leaves(%sz_127) : !cute.int_tuple<"16">
      %c0_i32 = arith.constant 0 : i32
      %c16_i32 = arith.constant 16 : i32
      %c1_i32 = arith.constant 1 : i32
      %25 = scf.for %arg8 = %c0_i32 to %c16_i32 step %c1_i32 iter_args(%arg9 = %rmem_124) -> (!memref_rmem_i8_)  : i32 {
        %iter_229 = cute.get_iter(%arg9) : !memref_rmem_i8_
        %iter_230 = cute.get_iter(%arg9) : !memref_rmem_i8_
        %coord_231 = cute.make_coord(%arg8) : (i32) -> !cute.coord<"?">
        %slice_232 = cute.slice(%src_partitioned_112, %coord_231) : !cute.coord_tensor<"(?{div=4},?{div=4})", "((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">, !cute.coord<"?">
        %iter_233 = cute.get_iter(%slice_232) : !cute.coord_tensor<"(?,?)", "():()">
        %tup_234 = cute.deref_arith_tuple_iter(%iter_233) : !cute.arith_tuple_iter<"(?,?)">
        %e0_235, %e1_236 = cute.get_leaves(%tup_234) : !cute.int_tuple<"(?,?)">
        %37 = cute.get_scalars(%e0_235) : !cute.int_tuple<"?">
        %38 = cute.get_scalars(%e1_236) : !cute.int_tuple<"?">
        %iter_237 = cute.get_iter(%slice_232) : !cute.coord_tensor<"(?,?)", "():()">
        %tup_238 = cute.deref_arith_tuple_iter(%iter_237) : !cute.arith_tuple_iter<"(?,?)">
        %e0_239, %e1_240 = cute.get_leaves(%tup_238) : !cute.int_tuple<"(?,?)">
        %39 = cute.get_scalars(%e0_239) : !cute.int_tuple<"?">
        %40 = cute.get_scalars(%e1_240) : !cute.int_tuple<"?">
        %iter_241 = cute.get_iter(%slice_232) : !cute.coord_tensor<"(?,?)", "():()">
        %tup_242 = cute.deref_arith_tuple_iter(%iter_241) : !cute.arith_tuple_iter<"(?,?)">
        %e0_243, %e1_244 = cute.get_leaves(%tup_242) : !cute.int_tuple<"(?,?)">
        %41 = cute.get_scalars(%e0_243) : !cute.int_tuple<"?">
        %42 = cute.get_scalars(%e1_244) : !cute.int_tuple<"?">
        %coord_245 = cute.make_coord(%e0_243, %e1_244) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
        %coord_246 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
        %43 = cute.elem_less(%coord_245, %coord_246) : !cute.coord<"(?,?)">, !cute.coord<"(?,?)">
        %44 = arith.extui %43 : i1 to i8
        %coord_247 = cute.make_coord(%arg8) : (i32) -> !cute.coord<"?">
        cute.memref.store(%arg9, %coord_247, %44) : (!memref_rmem_i8_, !cute.coord<"?">, i8) -> ()
        scf.yield %arg9 : !memref_rmem_i8_
      }
      %iter_129 = cute.get_iter(%25) : !memref_rmem_i8_
      %iter_130 = cute.get_iter(%25) : !memref_rmem_i8_
      %iter_131 = cute.get_iter(%25) : !memref_rmem_i8_
      %true = arith.constant true
      scf.if %true {
        %c0_i32_229 = arith.constant 0 : i32
        %c10_i32_230 = arith.constant 10 : i32
        %c1_i32_231 = arith.constant 1 : i32
        scf.for %arg8 = %c0_i32_229 to %c10_i32_230 step %c1_i32_231  : i32 {
          %lay_232 = cute.get_layout(%src_partitioned) : !memref_gmem_f32_2
          %37 = cute.get_shape(%lay_232) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_233, %e1_234, %e2_235, %e3_236, %e4_237 = cute.get_leaves(%37) : !cute.shape<"((1,(4,4)),1,1)">
          %lay_238 = cute.get_layout(%rmem) : !memref_rmem_f32_
          %38 = cute.get_shape(%lay_238) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_239, %e1_240, %e2_241, %e3_242, %e4_243 = cute.get_leaves(%38) : !cute.shape<"((1,(4,4)),1,1)">
          %lay_244 = cute.get_layout(%src_partitioned) : !memref_gmem_f32_2
          %shape_245 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_246 = cute.make_layout(%shape_245) : !cute.layout<"1:0">
          %append_247 = cute.append_to_rank<2> (%lay_244, %lay_246) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">
          %view_248 = cute.make_view(%iter_93, %append_247) : !memref_gmem_f32_2
          %iter_249 = cute.get_iter(%view_248) : !memref_gmem_f32_2
          %lay_250 = cute.get_layout(%view_248) : !memref_gmem_f32_2
          %39 = cute.get_shape(%lay_250) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_251, %e1_252, %e2_253, %e3_254, %e4_255 = cute.get_leaves(%39) : !cute.shape<"((1,(4,4)),1,1)">
          %lay_256 = cute.get_layout(%view_248) : !memref_gmem_f32_2
          %40 = cute.get_shape(%lay_256) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_257, %e1_258, %e2_259, %e3_260, %e4_261 = cute.get_leaves(%40) : !cute.shape<"((1,(4,4)),1,1)">
          %grouped_262 = cute.group_modes(%view_248) <1, 3> : (!memref_gmem_f32_2) -> !memref_gmem_f32_3
          %iter_263 = cute.get_iter(%grouped_262) : !memref_gmem_f32_3
          %iter_264 = cute.get_iter(%grouped_262) : !memref_gmem_f32_3
          %lay_265 = cute.get_layout(%rmem) : !memref_rmem_f32_
          %shape_266 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_267 = cute.make_layout(%shape_266) : !cute.layout<"1:0">
          %append_268 = cute.append_to_rank<2> (%lay_265, %lay_267) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
          %view_269 = cute.make_view(%iter_102, %append_268) : !memref_rmem_f32_
          %iter_270 = cute.get_iter(%view_269) : !memref_rmem_f32_
          %lay_271 = cute.get_layout(%view_269) : !memref_rmem_f32_
          %41 = cute.get_shape(%lay_271) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_272, %e1_273, %e2_274, %e3_275, %e4_276 = cute.get_leaves(%41) : !cute.shape<"((1,(4,4)),1,1)">
          %lay_277 = cute.get_layout(%view_269) : !memref_rmem_f32_
          %42 = cute.get_shape(%lay_277) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_278, %e1_279, %e2_280, %e3_281, %e4_282 = cute.get_leaves(%42) : !cute.shape<"((1,(4,4)),1,1)">
          %grouped_283 = cute.group_modes(%view_269) <1, 3> : (!memref_rmem_f32_) -> !memref_rmem_f32_1
          %iter_284 = cute.get_iter(%grouped_283) : !memref_rmem_f32_1
          %iter_285 = cute.get_iter(%grouped_283) : !memref_rmem_f32_1
          %lay_286 = cute.get_layout(%25) : !memref_rmem_i8_
          %shape_287 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_288 = cute.make_layout(%shape_287) : !cute.layout<"1:0">
          %append_289 = cute.append_to_rank<2> (%lay_286, %lay_288) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
          %view_290 = cute.make_view(%iter_131, %append_289) : !memref_rmem_i8_
          %iter_291 = cute.get_iter(%view_290) : !memref_rmem_i8_
          %lay_292 = cute.get_layout(%view_290) : !memref_rmem_i8_
          %43 = cute.get_shape(%lay_292) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_293, %e1_294, %e2_295, %e3_296, %e4_297 = cute.get_leaves(%43) : !cute.shape<"((1,(4,4)),1,1)">
          %lay_298 = cute.get_layout(%view_290) : !memref_rmem_i8_
          %44 = cute.get_shape(%lay_298) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_299, %e1_300, %e2_301, %e3_302, %e4_303 = cute.get_leaves(%44) : !cute.shape<"((1,(4,4)),1,1)">
          %grouped_304 = cute.group_modes(%view_290) <1, 3> : (!memref_rmem_i8_) -> !memref_rmem_i8_1
          %iter_305 = cute.get_iter(%grouped_304) : !memref_rmem_i8_1
          %iter_306 = cute.get_iter(%grouped_304) : !memref_rmem_i8_1
          %lay_307 = cute.get_layout(%grouped_262) : !memref_gmem_f32_3
          %45 = cute.get_shape(%lay_307) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
          %e0_308, %e1_309, %e2_310, %e3_311, %e4_312 = cute.get_leaves(%45) : !cute.shape<"((1,(4,4)),(1,1))">
          %lay_313 = cute.get_layout(%grouped_283) : !memref_rmem_f32_1
          %46 = cute.get_shape(%lay_313) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
          %e0_314, %e1_315, %e2_316, %e3_317, %e4_318 = cute.get_leaves(%46) : !cute.shape<"((1,(4,4)),(1,1))">
          %sz_319 = cute.size(%grouped_262) <{mode = [1]}> : (!memref_gmem_f32_3) -> !cute.int_tuple<"1">
          %e0_320 = cute.get_leaves(%sz_319) : !cute.int_tuple<"1">
          %sz_321 = cute.size(%grouped_283) <{mode = [1]}> : (!memref_rmem_f32_1) -> !cute.int_tuple<"1">
          %e0_322 = cute.get_leaves(%sz_321) : !cute.int_tuple<"1">
          cute.copy(%atom, %grouped_262, %grouped_283, %grouped_304) : (!cute_nvgpu.atom.universal_copy<f32>, !memref_gmem_f32_3, !memref_rmem_f32_1, !memref_rmem_i8_1)
          %lay_323 = cute.get_layout(%src_partitioned_95) : !memref_gmem_f32_2
          %47 = cute.get_shape(%lay_323) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_324, %e1_325, %e2_326, %e3_327, %e4_328 = cute.get_leaves(%47) : !cute.shape<"((1,(4,4)),1,1)">
          %lay_329 = cute.get_layout(%rmem_104) : !memref_rmem_f32_
          %48 = cute.get_shape(%lay_329) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_330, %e1_331, %e2_332, %e3_333, %e4_334 = cute.get_leaves(%48) : !cute.shape<"((1,(4,4)),1,1)">
          %lay_335 = cute.get_layout(%src_partitioned_95) : !memref_gmem_f32_2
          %shape_336 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_337 = cute.make_layout(%shape_336) : !cute.layout<"1:0">
          %append_338 = cute.append_to_rank<2> (%lay_335, %lay_337) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">
          %view_339 = cute.make_view(%iter_96, %append_338) : !memref_gmem_f32_2
          %iter_340 = cute.get_iter(%view_339) : !memref_gmem_f32_2
          %lay_341 = cute.get_layout(%view_339) : !memref_gmem_f32_2
          %49 = cute.get_shape(%lay_341) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_342, %e1_343, %e2_344, %e3_345, %e4_346 = cute.get_leaves(%49) : !cute.shape<"((1,(4,4)),1,1)">
          %lay_347 = cute.get_layout(%view_339) : !memref_gmem_f32_2
          %50 = cute.get_shape(%lay_347) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_348, %e1_349, %e2_350, %e3_351, %e4_352 = cute.get_leaves(%50) : !cute.shape<"((1,(4,4)),1,1)">
          %grouped_353 = cute.group_modes(%view_339) <1, 3> : (!memref_gmem_f32_2) -> !memref_gmem_f32_3
          %iter_354 = cute.get_iter(%grouped_353) : !memref_gmem_f32_3
          %iter_355 = cute.get_iter(%grouped_353) : !memref_gmem_f32_3
          %lay_356 = cute.get_layout(%rmem_104) : !memref_rmem_f32_
          %shape_357 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_358 = cute.make_layout(%shape_357) : !cute.layout<"1:0">
          %append_359 = cute.append_to_rank<2> (%lay_356, %lay_358) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
          %view_360 = cute.make_view(%iter_106, %append_359) : !memref_rmem_f32_
          %iter_361 = cute.get_iter(%view_360) : !memref_rmem_f32_
          %lay_362 = cute.get_layout(%view_360) : !memref_rmem_f32_
          %51 = cute.get_shape(%lay_362) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_363, %e1_364, %e2_365, %e3_366, %e4_367 = cute.get_leaves(%51) : !cute.shape<"((1,(4,4)),1,1)">
          %lay_368 = cute.get_layout(%view_360) : !memref_rmem_f32_
          %52 = cute.get_shape(%lay_368) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_369, %e1_370, %e2_371, %e3_372, %e4_373 = cute.get_leaves(%52) : !cute.shape<"((1,(4,4)),1,1)">
          %grouped_374 = cute.group_modes(%view_360) <1, 3> : (!memref_rmem_f32_) -> !memref_rmem_f32_1
          %iter_375 = cute.get_iter(%grouped_374) : !memref_rmem_f32_1
          %iter_376 = cute.get_iter(%grouped_374) : !memref_rmem_f32_1
          %lay_377 = cute.get_layout(%25) : !memref_rmem_i8_
          %shape_378 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_379 = cute.make_layout(%shape_378) : !cute.layout<"1:0">
          %append_380 = cute.append_to_rank<2> (%lay_377, %lay_379) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
          %view_381 = cute.make_view(%iter_131, %append_380) : !memref_rmem_i8_
          %iter_382 = cute.get_iter(%view_381) : !memref_rmem_i8_
          %lay_383 = cute.get_layout(%view_381) : !memref_rmem_i8_
          %53 = cute.get_shape(%lay_383) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_384, %e1_385, %e2_386, %e3_387, %e4_388 = cute.get_leaves(%53) : !cute.shape<"((1,(4,4)),1,1)">
          %lay_389 = cute.get_layout(%view_381) : !memref_rmem_i8_
          %54 = cute.get_shape(%lay_389) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_390, %e1_391, %e2_392, %e3_393, %e4_394 = cute.get_leaves(%54) : !cute.shape<"((1,(4,4)),1,1)">
          %grouped_395 = cute.group_modes(%view_381) <1, 3> : (!memref_rmem_i8_) -> !memref_rmem_i8_1
          %iter_396 = cute.get_iter(%grouped_395) : !memref_rmem_i8_1
          %iter_397 = cute.get_iter(%grouped_395) : !memref_rmem_i8_1
          %lay_398 = cute.get_layout(%grouped_353) : !memref_gmem_f32_3
          %55 = cute.get_shape(%lay_398) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
          %e0_399, %e1_400, %e2_401, %e3_402, %e4_403 = cute.get_leaves(%55) : !cute.shape<"((1,(4,4)),(1,1))">
          %lay_404 = cute.get_layout(%grouped_374) : !memref_rmem_f32_1
          %56 = cute.get_shape(%lay_404) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
          %e0_405, %e1_406, %e2_407, %e3_408, %e4_409 = cute.get_leaves(%56) : !cute.shape<"((1,(4,4)),(1,1))">
          %sz_410 = cute.size(%grouped_353) <{mode = [1]}> : (!memref_gmem_f32_3) -> !cute.int_tuple<"1">
          %e0_411 = cute.get_leaves(%sz_410) : !cute.int_tuple<"1">
          %sz_412 = cute.size(%grouped_374) <{mode = [1]}> : (!memref_rmem_f32_1) -> !cute.int_tuple<"1">
          %e0_413 = cute.get_leaves(%sz_412) : !cute.int_tuple<"1">
          cute.copy(%atom, %grouped_353, %grouped_374, %grouped_395) : (!cute_nvgpu.atom.universal_copy<f32>, !memref_gmem_f32_3, !memref_rmem_f32_1, !memref_rmem_i8_1)
        }
        llvm.inline_asm has_side_effects asm_dialect = att "griddepcontrol.launch_dependents;", ""  : () -> ()
      } else {
        %c0_i32_229 = arith.constant 0 : i32
        %c10_i32_230 = arith.constant 10 : i32
        %c1_i32_231 = arith.constant 1 : i32
        scf.for %arg8 = %c0_i32_229 to %c10_i32_230 step %c1_i32_231  : i32 {
          %lay_232 = cute.get_layout(%src_partitioned_95) : !memref_gmem_f32_2
          %37 = cute.get_shape(%lay_232) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_233, %e1_234, %e2_235, %e3_236, %e4_237 = cute.get_leaves(%37) : !cute.shape<"((1,(4,4)),1,1)">
          %lay_238 = cute.get_layout(%rmem_104) : !memref_rmem_f32_
          %38 = cute.get_shape(%lay_238) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_239, %e1_240, %e2_241, %e3_242, %e4_243 = cute.get_leaves(%38) : !cute.shape<"((1,(4,4)),1,1)">
          %lay_244 = cute.get_layout(%src_partitioned_95) : !memref_gmem_f32_2
          %shape_245 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_246 = cute.make_layout(%shape_245) : !cute.layout<"1:0">
          %append_247 = cute.append_to_rank<2> (%lay_244, %lay_246) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">
          %view_248 = cute.make_view(%iter_96, %append_247) : !memref_gmem_f32_2
          %iter_249 = cute.get_iter(%view_248) : !memref_gmem_f32_2
          %lay_250 = cute.get_layout(%view_248) : !memref_gmem_f32_2
          %39 = cute.get_shape(%lay_250) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_251, %e1_252, %e2_253, %e3_254, %e4_255 = cute.get_leaves(%39) : !cute.shape<"((1,(4,4)),1,1)">
          %lay_256 = cute.get_layout(%view_248) : !memref_gmem_f32_2
          %40 = cute.get_shape(%lay_256) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_257, %e1_258, %e2_259, %e3_260, %e4_261 = cute.get_leaves(%40) : !cute.shape<"((1,(4,4)),1,1)">
          %grouped_262 = cute.group_modes(%view_248) <1, 3> : (!memref_gmem_f32_2) -> !memref_gmem_f32_3
          %iter_263 = cute.get_iter(%grouped_262) : !memref_gmem_f32_3
          %iter_264 = cute.get_iter(%grouped_262) : !memref_gmem_f32_3
          %lay_265 = cute.get_layout(%rmem_104) : !memref_rmem_f32_
          %shape_266 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_267 = cute.make_layout(%shape_266) : !cute.layout<"1:0">
          %append_268 = cute.append_to_rank<2> (%lay_265, %lay_267) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
          %view_269 = cute.make_view(%iter_106, %append_268) : !memref_rmem_f32_
          %iter_270 = cute.get_iter(%view_269) : !memref_rmem_f32_
          %lay_271 = cute.get_layout(%view_269) : !memref_rmem_f32_
          %41 = cute.get_shape(%lay_271) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_272, %e1_273, %e2_274, %e3_275, %e4_276 = cute.get_leaves(%41) : !cute.shape<"((1,(4,4)),1,1)">
          %lay_277 = cute.get_layout(%view_269) : !memref_rmem_f32_
          %42 = cute.get_shape(%lay_277) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_278, %e1_279, %e2_280, %e3_281, %e4_282 = cute.get_leaves(%42) : !cute.shape<"((1,(4,4)),1,1)">
          %grouped_283 = cute.group_modes(%view_269) <1, 3> : (!memref_rmem_f32_) -> !memref_rmem_f32_1
          %iter_284 = cute.get_iter(%grouped_283) : !memref_rmem_f32_1
          %iter_285 = cute.get_iter(%grouped_283) : !memref_rmem_f32_1
          %lay_286 = cute.get_layout(%25) : !memref_rmem_i8_
          %shape_287 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_288 = cute.make_layout(%shape_287) : !cute.layout<"1:0">
          %append_289 = cute.append_to_rank<2> (%lay_286, %lay_288) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
          %view_290 = cute.make_view(%iter_131, %append_289) : !memref_rmem_i8_
          %iter_291 = cute.get_iter(%view_290) : !memref_rmem_i8_
          %lay_292 = cute.get_layout(%view_290) : !memref_rmem_i8_
          %43 = cute.get_shape(%lay_292) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_293, %e1_294, %e2_295, %e3_296, %e4_297 = cute.get_leaves(%43) : !cute.shape<"((1,(4,4)),1,1)">
          %lay_298 = cute.get_layout(%view_290) : !memref_rmem_i8_
          %44 = cute.get_shape(%lay_298) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_299, %e1_300, %e2_301, %e3_302, %e4_303 = cute.get_leaves(%44) : !cute.shape<"((1,(4,4)),1,1)">
          %grouped_304 = cute.group_modes(%view_290) <1, 3> : (!memref_rmem_i8_) -> !memref_rmem_i8_1
          %iter_305 = cute.get_iter(%grouped_304) : !memref_rmem_i8_1
          %iter_306 = cute.get_iter(%grouped_304) : !memref_rmem_i8_1
          %lay_307 = cute.get_layout(%grouped_262) : !memref_gmem_f32_3
          %45 = cute.get_shape(%lay_307) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
          %e0_308, %e1_309, %e2_310, %e3_311, %e4_312 = cute.get_leaves(%45) : !cute.shape<"((1,(4,4)),(1,1))">
          %lay_313 = cute.get_layout(%grouped_283) : !memref_rmem_f32_1
          %46 = cute.get_shape(%lay_313) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
          %e0_314, %e1_315, %e2_316, %e3_317, %e4_318 = cute.get_leaves(%46) : !cute.shape<"((1,(4,4)),(1,1))">
          %sz_319 = cute.size(%grouped_262) <{mode = [1]}> : (!memref_gmem_f32_3) -> !cute.int_tuple<"1">
          %e0_320 = cute.get_leaves(%sz_319) : !cute.int_tuple<"1">
          %sz_321 = cute.size(%grouped_283) <{mode = [1]}> : (!memref_rmem_f32_1) -> !cute.int_tuple<"1">
          %e0_322 = cute.get_leaves(%sz_321) : !cute.int_tuple<"1">
          cute.copy(%atom, %grouped_262, %grouped_283, %grouped_304) : (!cute_nvgpu.atom.universal_copy<f32>, !memref_gmem_f32_3, !memref_rmem_f32_1, !memref_rmem_i8_1)
        }
        llvm.inline_asm has_side_effects asm_dialect = att "griddepcontrol.wait;", ""  : () -> ()
        scf.for %arg8 = %c0_i32_229 to %c10_i32_230 step %c1_i32_231  : i32 {
          %lay_232 = cute.get_layout(%src_partitioned) : !memref_gmem_f32_2
          %37 = cute.get_shape(%lay_232) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_233, %e1_234, %e2_235, %e3_236, %e4_237 = cute.get_leaves(%37) : !cute.shape<"((1,(4,4)),1,1)">
          %lay_238 = cute.get_layout(%rmem) : !memref_rmem_f32_
          %38 = cute.get_shape(%lay_238) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_239, %e1_240, %e2_241, %e3_242, %e4_243 = cute.get_leaves(%38) : !cute.shape<"((1,(4,4)),1,1)">
          %lay_244 = cute.get_layout(%src_partitioned) : !memref_gmem_f32_2
          %shape_245 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_246 = cute.make_layout(%shape_245) : !cute.layout<"1:0">
          %append_247 = cute.append_to_rank<2> (%lay_244, %lay_246) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">
          %view_248 = cute.make_view(%iter_93, %append_247) : !memref_gmem_f32_2
          %iter_249 = cute.get_iter(%view_248) : !memref_gmem_f32_2
          %lay_250 = cute.get_layout(%view_248) : !memref_gmem_f32_2
          %39 = cute.get_shape(%lay_250) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_251, %e1_252, %e2_253, %e3_254, %e4_255 = cute.get_leaves(%39) : !cute.shape<"((1,(4,4)),1,1)">
          %lay_256 = cute.get_layout(%view_248) : !memref_gmem_f32_2
          %40 = cute.get_shape(%lay_256) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_257, %e1_258, %e2_259, %e3_260, %e4_261 = cute.get_leaves(%40) : !cute.shape<"((1,(4,4)),1,1)">
          %grouped_262 = cute.group_modes(%view_248) <1, 3> : (!memref_gmem_f32_2) -> !memref_gmem_f32_3
          %iter_263 = cute.get_iter(%grouped_262) : !memref_gmem_f32_3
          %iter_264 = cute.get_iter(%grouped_262) : !memref_gmem_f32_3
          %lay_265 = cute.get_layout(%rmem) : !memref_rmem_f32_
          %shape_266 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_267 = cute.make_layout(%shape_266) : !cute.layout<"1:0">
          %append_268 = cute.append_to_rank<2> (%lay_265, %lay_267) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
          %view_269 = cute.make_view(%iter_102, %append_268) : !memref_rmem_f32_
          %iter_270 = cute.get_iter(%view_269) : !memref_rmem_f32_
          %lay_271 = cute.get_layout(%view_269) : !memref_rmem_f32_
          %41 = cute.get_shape(%lay_271) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_272, %e1_273, %e2_274, %e3_275, %e4_276 = cute.get_leaves(%41) : !cute.shape<"((1,(4,4)),1,1)">
          %lay_277 = cute.get_layout(%view_269) : !memref_rmem_f32_
          %42 = cute.get_shape(%lay_277) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_278, %e1_279, %e2_280, %e3_281, %e4_282 = cute.get_leaves(%42) : !cute.shape<"((1,(4,4)),1,1)">
          %grouped_283 = cute.group_modes(%view_269) <1, 3> : (!memref_rmem_f32_) -> !memref_rmem_f32_1
          %iter_284 = cute.get_iter(%grouped_283) : !memref_rmem_f32_1
          %iter_285 = cute.get_iter(%grouped_283) : !memref_rmem_f32_1
          %lay_286 = cute.get_layout(%25) : !memref_rmem_i8_
          %shape_287 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_288 = cute.make_layout(%shape_287) : !cute.layout<"1:0">
          %append_289 = cute.append_to_rank<2> (%lay_286, %lay_288) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
          %view_290 = cute.make_view(%iter_131, %append_289) : !memref_rmem_i8_
          %iter_291 = cute.get_iter(%view_290) : !memref_rmem_i8_
          %lay_292 = cute.get_layout(%view_290) : !memref_rmem_i8_
          %43 = cute.get_shape(%lay_292) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_293, %e1_294, %e2_295, %e3_296, %e4_297 = cute.get_leaves(%43) : !cute.shape<"((1,(4,4)),1,1)">
          %lay_298 = cute.get_layout(%view_290) : !memref_rmem_i8_
          %44 = cute.get_shape(%lay_298) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_299, %e1_300, %e2_301, %e3_302, %e4_303 = cute.get_leaves(%44) : !cute.shape<"((1,(4,4)),1,1)">
          %grouped_304 = cute.group_modes(%view_290) <1, 3> : (!memref_rmem_i8_) -> !memref_rmem_i8_1
          %iter_305 = cute.get_iter(%grouped_304) : !memref_rmem_i8_1
          %iter_306 = cute.get_iter(%grouped_304) : !memref_rmem_i8_1
          %lay_307 = cute.get_layout(%grouped_262) : !memref_gmem_f32_3
          %45 = cute.get_shape(%lay_307) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
          %e0_308, %e1_309, %e2_310, %e3_311, %e4_312 = cute.get_leaves(%45) : !cute.shape<"((1,(4,4)),(1,1))">
          %lay_313 = cute.get_layout(%grouped_283) : !memref_rmem_f32_1
          %46 = cute.get_shape(%lay_313) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
          %e0_314, %e1_315, %e2_316, %e3_317, %e4_318 = cute.get_leaves(%46) : !cute.shape<"((1,(4,4)),(1,1))">
          %sz_319 = cute.size(%grouped_262) <{mode = [1]}> : (!memref_gmem_f32_3) -> !cute.int_tuple<"1">
          %e0_320 = cute.get_leaves(%sz_319) : !cute.int_tuple<"1">
          %sz_321 = cute.size(%grouped_283) <{mode = [1]}> : (!memref_rmem_f32_1) -> !cute.int_tuple<"1">
          %e0_322 = cute.get_leaves(%sz_321) : !cute.int_tuple<"1">
          cute.copy(%atom, %grouped_262, %grouped_283, %grouped_304) : (!cute_nvgpu.atom.universal_copy<f32>, !memref_gmem_f32_3, !memref_rmem_f32_1, !memref_rmem_i8_1)
        }
      }
      %c10_i32 = arith.constant 10 : i32
      %26:3 = scf.for %arg8 = %c0_i32 to %c10_i32 step %c1_i32 iter_args(%arg9 = %rmem, %arg10 = %rmem_104, %arg11 = %rmem_108) -> (!memref_rmem_f32_, !memref_rmem_f32_, !memref_rmem_f32_)  : i32 {
        %iter_229 = cute.get_iter(%arg9) : !memref_rmem_f32_
        %iter_230 = cute.get_iter(%arg10) : !memref_rmem_f32_
        %iter_231 = cute.get_iter(%arg11) : !memref_rmem_f32_
        %iter_232 = cute.get_iter(%arg9) : !memref_rmem_f32_
        %iter_233 = cute.get_iter(%arg10) : !memref_rmem_f32_
        %iter_234 = cute.get_iter(%arg11) : !memref_rmem_f32_
        %lay_235 = cute.get_layout(%arg9) : !memref_rmem_f32_
        %37 = cute.get_shape(%lay_235) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
        %e0_236, %e1_237, %e2_238, %e3_239, %e4_240 = cute.get_leaves(%37) : !cute.shape<"((1,(4,4)),1,1)">
        %38 = cute.memref.load_vec %arg9 : !memref_rmem_f32_
        %lay_241 = cute.get_layout(%arg9) : !memref_rmem_f32_
        %39 = cute.get_shape(%lay_241) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
        %e0_242, %e1_243, %e2_244, %e3_245, %e4_246 = cute.get_leaves(%39) : !cute.shape<"((1,(4,4)),1,1)">
        %lay_247 = cute.get_layout(%arg10) : !memref_rmem_f32_
        %40 = cute.get_shape(%lay_247) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
        %e0_248, %e1_249, %e2_250, %e3_251, %e4_252 = cute.get_leaves(%40) : !cute.shape<"((1,(4,4)),1,1)">
        %41 = cute.memref.load_vec %arg10 : !memref_rmem_f32_
        %lay_253 = cute.get_layout(%arg10) : !memref_rmem_f32_
        %42 = cute.get_shape(%lay_253) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
        %e0_254, %e1_255, %e2_256, %e3_257, %e4_258 = cute.get_leaves(%42) : !cute.shape<"((1,(4,4)),1,1)">
        %43 = arith.addf %38, %41 : vector<16xf32>
        %lay_259 = cute.get_layout(%arg11) : !memref_rmem_f32_
        %44 = cute.get_shape(%lay_259) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
        %e0_260, %e1_261, %e2_262, %e3_263, %e4_264 = cute.get_leaves(%44) : !cute.shape<"((1,(4,4)),1,1)">
        %lay_265 = cute.get_layout(%arg11) : !memref_rmem_f32_
        %45 = cute.get_shape(%lay_265) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
        %e0_266, %e1_267, %e2_268, %e3_269, %e4_270 = cute.get_leaves(%45) : !cute.shape<"((1,(4,4)),1,1)">
        %int_tuple_271 = cute.make_int_tuple() : () -> !cute.int_tuple<"((1,(4,4)),1,1)">
        %sz_272 = cute.size(%int_tuple_271) : (!cute.int_tuple<"((1,(4,4)),1,1)">) -> !cute.int_tuple<"16">
        %e0_273 = cute.get_leaves(%sz_272) : !cute.int_tuple<"16">
        %int_tuple_274 = cute.make_int_tuple() : () -> !cute.int_tuple<"((1,(4,4)),1,1)">
        %sz_275 = cute.size(%int_tuple_274) : (!cute.int_tuple<"((1,(4,4)),1,1)">) -> !cute.int_tuple<"16">
        %e0_276 = cute.get_leaves(%sz_275) : !cute.int_tuple<"16">
        cute.memref.store_vec %43, %arg11 : !memref_rmem_f32_
        scf.yield %arg9, %arg10, %arg11 : !memref_rmem_f32_, !memref_rmem_f32_, !memref_rmem_f32_
      }
      %iter_132 = cute.get_iter(%26#0) : !memref_rmem_f32_
      %iter_133 = cute.get_iter(%26#1) : !memref_rmem_f32_
      %iter_134 = cute.get_iter(%26#2) : !memref_rmem_f32_
      %iter_135 = cute.get_iter(%26#0) : !memref_rmem_f32_
      %iter_136 = cute.get_iter(%26#0) : !memref_rmem_f32_
      %iter_137 = cute.get_iter(%26#1) : !memref_rmem_f32_
      %iter_138 = cute.get_iter(%26#1) : !memref_rmem_f32_
      %iter_139 = cute.get_iter(%26#2) : !memref_rmem_f32_
      %iter_140 = cute.get_iter(%26#2) : !memref_rmem_f32_
      %lay_141 = cute.get_layout(%26#2) : !memref_rmem_f32_
      %27 = cute.get_shape(%lay_141) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_142, %e1_143, %e2_144, %e3_145, %e4_146 = cute.get_leaves(%27) : !cute.shape<"((1,(4,4)),1,1)">
      %lay_147 = cute.get_layout(%src_partitioned_98) : !memref_gmem_f32_2
      %28 = cute.get_shape(%lay_147) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_148, %e1_149, %e2_150, %e3_151, %e4_152 = cute.get_leaves(%28) : !cute.shape<"((1,(4,4)),1,1)">
      %lay_153 = cute.get_layout(%26#2) : !memref_rmem_f32_
      %shape_154 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_155 = cute.make_layout(%shape_154) : !cute.layout<"1:0">
      %append = cute.append_to_rank<2> (%lay_153, %lay_155) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
      %view = cute.make_view(%iter_140, %append) : !memref_rmem_f32_
      %iter_156 = cute.get_iter(%view) : !memref_rmem_f32_
      %lay_157 = cute.get_layout(%view) : !memref_rmem_f32_
      %29 = cute.get_shape(%lay_157) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_158, %e1_159, %e2_160, %e3_161, %e4_162 = cute.get_leaves(%29) : !cute.shape<"((1,(4,4)),1,1)">
      %lay_163 = cute.get_layout(%view) : !memref_rmem_f32_
      %30 = cute.get_shape(%lay_163) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_164, %e1_165, %e2_166, %e3_167, %e4_168 = cute.get_leaves(%30) : !cute.shape<"((1,(4,4)),1,1)">
      %grouped = cute.group_modes(%view) <1, 3> : (!memref_rmem_f32_) -> !memref_rmem_f32_1
      %iter_169 = cute.get_iter(%grouped) : !memref_rmem_f32_1
      %iter_170 = cute.get_iter(%grouped) : !memref_rmem_f32_1
      %lay_171 = cute.get_layout(%src_partitioned_98) : !memref_gmem_f32_2
      %shape_172 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_173 = cute.make_layout(%shape_172) : !cute.layout<"1:0">
      %append_174 = cute.append_to_rank<2> (%lay_171, %lay_173) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">
      %view_175 = cute.make_view(%iter_99, %append_174) : !memref_gmem_f32_2
      %iter_176 = cute.get_iter(%view_175) : !memref_gmem_f32_2
      %lay_177 = cute.get_layout(%view_175) : !memref_gmem_f32_2
      %31 = cute.get_shape(%lay_177) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_178, %e1_179, %e2_180, %e3_181, %e4_182 = cute.get_leaves(%31) : !cute.shape<"((1,(4,4)),1,1)">
      %lay_183 = cute.get_layout(%view_175) : !memref_gmem_f32_2
      %32 = cute.get_shape(%lay_183) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_184, %e1_185, %e2_186, %e3_187, %e4_188 = cute.get_leaves(%32) : !cute.shape<"((1,(4,4)),1,1)">
      %grouped_189 = cute.group_modes(%view_175) <1, 3> : (!memref_gmem_f32_2) -> !memref_gmem_f32_3
      %iter_190 = cute.get_iter(%grouped_189) : !memref_gmem_f32_3
      %iter_191 = cute.get_iter(%grouped_189) : !memref_gmem_f32_3
      %lay_192 = cute.get_layout(%25) : !memref_rmem_i8_
      %shape_193 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_194 = cute.make_layout(%shape_193) : !cute.layout<"1:0">
      %append_195 = cute.append_to_rank<2> (%lay_192, %lay_194) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
      %view_196 = cute.make_view(%iter_131, %append_195) : !memref_rmem_i8_
      %iter_197 = cute.get_iter(%view_196) : !memref_rmem_i8_
      %lay_198 = cute.get_layout(%view_196) : !memref_rmem_i8_
      %33 = cute.get_shape(%lay_198) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_199, %e1_200, %e2_201, %e3_202, %e4_203 = cute.get_leaves(%33) : !cute.shape<"((1,(4,4)),1,1)">
      %lay_204 = cute.get_layout(%view_196) : !memref_rmem_i8_
      %34 = cute.get_shape(%lay_204) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_205, %e1_206, %e2_207, %e3_208, %e4_209 = cute.get_leaves(%34) : !cute.shape<"((1,(4,4)),1,1)">
      %grouped_210 = cute.group_modes(%view_196) <1, 3> : (!memref_rmem_i8_) -> !memref_rmem_i8_1
      %iter_211 = cute.get_iter(%grouped_210) : !memref_rmem_i8_1
      %iter_212 = cute.get_iter(%grouped_210) : !memref_rmem_i8_1
      %lay_213 = cute.get_layout(%grouped) : !memref_rmem_f32_1
      %35 = cute.get_shape(%lay_213) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
      %e0_214, %e1_215, %e2_216, %e3_217, %e4_218 = cute.get_leaves(%35) : !cute.shape<"((1,(4,4)),(1,1))">
      %lay_219 = cute.get_layout(%grouped_189) : !memref_gmem_f32_3
      %36 = cute.get_shape(%lay_219) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
      %e0_220, %e1_221, %e2_222, %e3_223, %e4_224 = cute.get_leaves(%36) : !cute.shape<"((1,(4,4)),(1,1))">
      %sz_225 = cute.size(%grouped) <{mode = [1]}> : (!memref_rmem_f32_1) -> !cute.int_tuple<"1">
      %e0_226 = cute.get_leaves(%sz_225) : !cute.int_tuple<"1">
      %sz_227 = cute.size(%grouped_189) <{mode = [1]}> : (!memref_gmem_f32_3) -> !cute.int_tuple<"1">
      %e0_228 = cute.get_leaves(%sz_227) : !cute.int_tuple<"1">
      cute.copy(%atom_37, %grouped, %grouped_189, %grouped_210) : (!cute_nvgpu.atom.universal_copy<f32>, !memref_rmem_f32_1, !memref_gmem_f32_3, !memref_rmem_i8_1)
      return
    }
  }
  func.func @cutlass_elementwise_add_Tensorgmem_o_i641_Tensorgmem_o_i641_Tensorgmem_o_i641_CUstream_False_True(%arg0: !memref_gmem_f32_4, %arg1: !memref_gmem_f32_4, %arg2: !memref_gmem_f32_4, %arg3: !cuda.stream) -> i32 attributes {llvm.emit_c_interface} {
    %iter = cute.get_iter(%arg0) : !memref_gmem_f32_4
    %iter_0 = cute.get_iter(%arg1) : !memref_gmem_f32_4
    %iter_1 = cute.get_iter(%arg2) : !memref_gmem_f32_4
    %iter_2 = cute.get_iter(%arg0) : !memref_gmem_f32_4
    %iter_3 = cute.get_iter(%arg1) : !memref_gmem_f32_4
    %iter_4 = cute.get_iter(%arg2) : !memref_gmem_f32_4
    %lay = cute.get_layout(%arg0) : !memref_gmem_f32_4
    %lay_5 = cute.get_layout(%arg1) : !memref_gmem_f32_4
    %lay_6 = cute.get_layout(%arg2) : !memref_gmem_f32_4
    %shape = cute.make_shape() : () -> !cute.shape<"(4,32)">
    %int_tuple = cute.make_int_tuple() : () -> !cute.int_tuple<"(1,0)">
    %lay_7 = cute.make_ordered_layout(%shape, %int_tuple) : (!cute.shape<"(4,32)">, !cute.int_tuple<"(1,0)">) -> !cute.layout<"(4,32):(32,1)">
    %shape_8 = cute.make_shape() : () -> !cute.shape<"(4,4)">
    %int_tuple_9 = cute.make_int_tuple() : () -> !cute.int_tuple<"(1,0)">
    %lay_10 = cute.make_ordered_layout(%shape_8, %int_tuple_9) : (!cute.shape<"(4,4)">, !cute.int_tuple<"(1,0)">) -> !cute.layout<"(4,4):(4,1)">
    %prod = cute.raked_product(%lay_7, %lay_10) : (!cute.layout<"(4,32):(32,1)">, !cute.layout<"(4,4):(4,1)">) -> !cute.layout<"((4,4),(4,32)):((512,32),(128,1))">
    %sz = cute.size(%lay_7) : (!cute.layout<"(4,32):(32,1)">) -> !cute.int_tuple<"128">
    %e0 = cute.get_leaves(%sz) : !cute.int_tuple<"128">
    %sz_11 = cute.size(%lay_10) : (!cute.layout<"(4,4):(4,1)">) -> !cute.int_tuple<"16">
    %e0_12 = cute.get_leaves(%sz_11) : !cute.int_tuple<"16">
    %shape_13 = cute.make_shape() : () -> !cute.shape<"(128,16)">
    %lay_14 = cute.make_layout(%shape_13) : !cute.layout<"(128,16):(1,128)">
    %rinv = cute.right_inverse(%prod) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.layout<"(32,16,4):(64,4,1)">
    %0 = cute.composition(%rinv, %lay_14) : (!cute.layout<"(32,16,4):(64,4,1)">, !cute.layout<"(128,16):(1,128)">) -> !cute.layout<"((32,4),(4,4)):((64,4),(16,1))">
    %1 = cute.get_shape(%prod) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.shape<"((4,4),(4,32))">
    %e0_15, %e1, %e2, %e3 = cute.get_leaves(%1) : !cute.shape<"((4,4),(4,32))">
    %int_tuple_16 = cute.make_int_tuple() : () -> !cute.int_tuple<"((4,4),(4,32))">
    %res = cute.tuple.product_each(%int_tuple_16) : (!cute.int_tuple<"((4,4),(4,32))">) -> !cute.int_tuple<"(16,128)">
    %e0_17, %e1_18 = cute.get_leaves(%res) : !cute.int_tuple<"(16,128)">
    %tile = cute.make_tile() : () -> !cute.tile<"[16:1;128:1]">
    %div = cute.zipped_divide(%arg0, %tile) : !memref_gmem_f32_4, !cute.tile<"[16:1;128:1]">
    %iter_19 = cute.get_iter(%div) : !memref_gmem_f32_
    %iter_20 = cute.get_iter(%div) : !memref_gmem_f32_
    %tile_21 = cute.make_tile() : () -> !cute.tile<"[16:1;128:1]">
    %div_22 = cute.zipped_divide(%arg1, %tile_21) : !memref_gmem_f32_4, !cute.tile<"[16:1;128:1]">
    %iter_23 = cute.get_iter(%div_22) : !memref_gmem_f32_
    %iter_24 = cute.get_iter(%div_22) : !memref_gmem_f32_
    %tile_25 = cute.make_tile() : () -> !cute.tile<"[16:1;128:1]">
    %div_26 = cute.zipped_divide(%arg2, %tile_25) : !memref_gmem_f32_4, !cute.tile<"[16:1;128:1]">
    %iter_27 = cute.get_iter(%div_26) : !memref_gmem_f32_
    %iter_28 = cute.get_iter(%div_26) : !memref_gmem_f32_
    %lay_29 = cute.get_layout(%arg2) : !memref_gmem_f32_4
    %2 = cute.get_shape(%lay_29) : (!cute.layout<"(?,?):(?{i64},1)">) -> !cute.shape<"(?,?)">
    %e0_30, %e1_31 = cute.get_leaves(%2) : !cute.shape<"(?,?)">
    %itup = cute.to_int_tuple(%e0_30) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %3 = cute.get_scalars(%itup) : !cute.int_tuple<"?">
    %itup_32 = cute.to_int_tuple(%e1_31) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %4 = cute.get_scalars(%itup_32) : !cute.int_tuple<"?">
    %shape_33 = cute.make_shape(%itup, %itup_32) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.shape<"(?,?)">
    %5 = cute.make_identity_tensor(%shape_33) : !cute.coord_tensor<"(0,0)", "(?,?):(1@0,1@1)">
    %iter_34 = cute.get_iter(%5) : !cute.coord_tensor<"(0,0)", "(?,?):(1@0,1@1)">
    %tup = cute.deref_arith_tuple_iter(%iter_34) : !cute.arith_tuple_iter<"(0,0)">
    %e0_35, %e1_36 = cute.get_leaves(%tup) : !cute.int_tuple<"(0,0)">
    %tile_37 = cute.make_tile() : () -> !cute.tile<"[16:1;128:1]">
    %div_38 = cute.zipped_divide(%5, %tile_37) : !cute.coord_tensor<"(0,0)", "(?,?):(1@0,1@1)">, !cute.tile<"[16:1;128:1]">
    %iter_39 = cute.get_iter(%div_38) : !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
    %tup_40 = cute.deref_arith_tuple_iter(%iter_39) : !cute.arith_tuple_iter<"(0,0)">
    %e0_41, %e1_42 = cute.get_leaves(%tup_40) : !cute.int_tuple<"(0,0)">
    %iter_43 = cute.get_iter(%div_38) : !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
    %tup_44 = cute.deref_arith_tuple_iter(%iter_43) : !cute.arith_tuple_iter<"(0,0)">
    %e0_45, %e1_46 = cute.get_leaves(%tup_44) : !cute.int_tuple<"(0,0)">
    %lay_47 = cute.get_layout(%arg2) : !memref_gmem_f32_4
    %6 = cute.get_shape(%lay_47) : (!cute.layout<"(?,?):(?{i64},1)">) -> !cute.shape<"(?,?)">
    %e0_48, %e1_49 = cute.get_leaves(%6) : !cute.shape<"(?,?)">
    %itup_50 = cute.to_int_tuple(%e0_48) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %7 = cute.get_scalars(%itup_50) : !cute.int_tuple<"?">
    %itup_51 = cute.to_int_tuple(%e1_49) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %8 = cute.get_scalars(%itup_51) : !cute.int_tuple<"?">
    %sz_52 = cute.size(%div_26) <{mode = [1]}> : (!memref_gmem_f32_) -> !cute.int_tuple<"?">
    %e0_53 = cute.get_leaves(%sz_52) : !cute.int_tuple<"?">
    %9 = cute.get_scalars(%e0_53) : !cute.int_tuple<"?">
    %sz_54 = cute.size(%0) <{mode = [0]}> : (!cute.layout<"((32,4),(4,4)):((64,4),(16,1))">) -> !cute.int_tuple<"128">
    %e0_55 = cute.get_leaves(%sz_54) : !cute.int_tuple<"128">
    %lay_56 = cute.get_layout(%div) : !memref_gmem_f32_
    %lay_57 = cute.get_layout(%div_22) : !memref_gmem_f32_
    %lay_58 = cute.get_layout(%div_26) : !memref_gmem_f32_
    %lay_59 = cute.get_layout(%div_38) : !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
    %c0_i32 = arith.constant 0 : i32
    %10 = arith.extsi %c0_i32 : i32 to i64
    %c128_i32 = arith.constant 128 : i32
    %c1_i32 = arith.constant 1 : i32
    %11 = cuda.launch_cfg.create<max_attrs = 3 : i32> (blockDim = (%c128_i32, %c1_i32, %c1_i32), dynamicSmemBytes = %10, gridDim = (%9, %c1_i32, %c1_i32), stream = %arg3) : i32, i32, i32, i64, i32, i32, i32, !cuda.stream -> !cuda.launch_cfg<max_attrs = 3>
    %c0_i32_60 = arith.constant 0 : i32
    cuda.launch_cfg.programmatic_stream_serialization_allowed[%11] %c0_i32_60 : !cuda.launch_cfg<max_attrs = 3>, i32
    %c0_i32_61 = arith.constant 0 : i32
    cuda.launch_cfg.cooperative[%11] %c0_i32_61 : !cuda.launch_cfg<max_attrs = 3>, i32
    %12 = cuda.launch_ex @kernels::@kernel_cutlass_elementwise_add_kernel_tensorptrf32gmemo16128i641i64div16128_tensorptrf32gmemo16128i641i64div16128_tensorptrf32gmemo16128i641i64div16128_tensor00o1612810111601281___True_0<%11> (%div, %div_22, %div_26, %div_38, %7, %8, %lay_7, %lay_10) {assume_kernel_attr = #cuda.assume_kernel_attr<true>} : !cuda.launch_cfg<max_attrs = 3>, (!memref_gmem_f32_, !memref_gmem_f32_, !memref_gmem_f32_, !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">, i32, i32, !cute.layout<"(4,32):(32,1)">, !cute.layout<"(4,4):(4,1)">) -> !cuda.result
    %13 = cuda.cast %12 : !cuda.result -> i32
    cuda.return_if_error %13 : i32
    %c0_i32_62 = arith.constant 0 : i32
    return %c0_i32_62 : i32
  }
}



!copy_simt = !cute.tiled_copy<!cute_nvgpu.atom.universal_copy<f32>, layout_copy_tv = <"((32,4),(4,4)):((64,4),(16,1))">, tiler_mn = <"[16:1;128:1]">>
!memref_gmem_f32_ = !cute.memref<f32, gmem, "((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
!memref_gmem_f32_1 = !cute.memref<f32, gmem, "(16,128):(?{i64},1)">
!memref_gmem_f32_2 = !cute.memref<f32, gmem, "((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
!memref_gmem_f32_3 = !cute.memref<f32, gmem, "((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
!memref_gmem_f32_4 = !cute.memref<f32, gmem, "(?,?):(?{i64},1)">
!memref_rmem_f32_ = !cute.memref<f32, rmem, align<32>, "((1,(4,4)),1,1):((0,(1,4)),0,0)">
!memref_rmem_f32_1 = !cute.memref<f32, rmem, align<32>, "((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
!memref_rmem_i8_ = !cute.memref<i8, rmem, align<32>, "((1,(4,4)),1,1):((0,(1,4)),0,0)">
!memref_rmem_i8_1 = !cute.memref<i8, rmem, align<32>, "((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
module attributes {gpu.container_module} {
  gpu.module @kernels {
    cuda.kernel @kernel_cutlass_elementwise_add_kernel_tensorptrf32gmemo16128i641i64div16128_tensorptrf32gmemo16128i641i64div16128_tensorptrf32gmemo16128i641i64div16128_tensor00o1612810111601281___False_0(%arg0: !memref_gmem_f32_, %arg1: !memref_gmem_f32_, %arg2: !memref_gmem_f32_, %arg3: !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">, %arg4: i32, %arg5: i32, %arg6: !cute.layout<"(4,32):(32,1)">, %arg7: !cute.layout<"(4,4):(4,1)">) attributes {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} {
      %iter = cute.get_iter(%arg0) : !memref_gmem_f32_
      %iter_0 = cute.get_iter(%arg1) : !memref_gmem_f32_
      %iter_1 = cute.get_iter(%arg2) : !memref_gmem_f32_
      %iter_2 = cute.get_iter(%arg3) : !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
      %tup = cute.deref_arith_tuple_iter(%iter_2) : !cute.arith_tuple_iter<"(0,0)">
      %e0, %e1 = cute.get_leaves(%tup) : !cute.int_tuple<"(0,0)">
      %iter_3 = cute.get_iter(%arg0) : !memref_gmem_f32_
      %iter_4 = cute.get_iter(%arg1) : !memref_gmem_f32_
      %iter_5 = cute.get_iter(%arg2) : !memref_gmem_f32_
      %iter_6 = cute.get_iter(%arg3) : !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
      %tup_7 = cute.deref_arith_tuple_iter(%iter_6) : !cute.arith_tuple_iter<"(0,0)">
      %e0_8, %e1_9 = cute.get_leaves(%tup_7) : !cute.int_tuple<"(0,0)">
      %lay = cute.get_layout(%arg0) : !memref_gmem_f32_
      %lay_10 = cute.get_layout(%arg1) : !memref_gmem_f32_
      %lay_11 = cute.get_layout(%arg2) : !memref_gmem_f32_
      %lay_12 = cute.get_layout(%arg3) : !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
      %lay_13 = cute.get_layout(%arg0) : !memref_gmem_f32_
      %lay_14 = cute.get_layout(%arg1) : !memref_gmem_f32_
      %lay_15 = cute.get_layout(%arg2) : !memref_gmem_f32_
      %lay_16 = cute.get_layout(%arg3) : !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
      %0 = nvvm.read.ptx.sreg.tid.x : i32
      %1 = nvvm.read.ptx.sreg.tid.y : i32
      %2 = nvvm.read.ptx.sreg.tid.z : i32
      %3 = nvvm.read.ptx.sreg.ctaid.x : i32
      %4 = nvvm.read.ptx.sreg.ctaid.y : i32
      %5 = nvvm.read.ptx.sreg.ctaid.z : i32
      %coord = cute.make_coord(%3) : (i32) -> !cute.coord<"((_,_),?)">
      %slice = cute.slice(%arg0, %coord) : !memref_gmem_f32_, !cute.coord<"((_,_),?)">
      %iter_17 = cute.get_iter(%slice) : !memref_gmem_f32_1
      %iter_18 = cute.get_iter(%slice) : !memref_gmem_f32_1
      %coord_19 = cute.make_coord(%3) : (i32) -> !cute.coord<"((_,_),?)">
      %slice_20 = cute.slice(%arg1, %coord_19) : !memref_gmem_f32_, !cute.coord<"((_,_),?)">
      %iter_21 = cute.get_iter(%slice_20) : !memref_gmem_f32_1
      %iter_22 = cute.get_iter(%slice_20) : !memref_gmem_f32_1
      %coord_23 = cute.make_coord(%3) : (i32) -> !cute.coord<"((_,_),?)">
      %slice_24 = cute.slice(%arg2, %coord_23) : !memref_gmem_f32_, !cute.coord<"((_,_),?)">
      %iter_25 = cute.get_iter(%slice_24) : !memref_gmem_f32_1
      %iter_26 = cute.get_iter(%slice_24) : !memref_gmem_f32_1
      %coord_27 = cute.make_coord(%3) : (i32) -> !cute.coord<"((_,_),?)">
      %slice_28 = cute.slice(%arg3, %coord_27) : !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">, !cute.coord<"((_,_),?)">
      %iter_29 = cute.get_iter(%slice_28) : !cute.coord_tensor<"(?{div=16},?{div=128})", "(16,128):(1@0,1@1)">
      %tup_30 = cute.deref_arith_tuple_iter(%iter_29) : !cute.arith_tuple_iter<"(?{div=16},?{div=128})">
      %e0_31, %e1_32 = cute.get_leaves(%tup_30) : !cute.int_tuple<"(?{div=16},?{div=128})">
      %6 = cute.get_scalars(%e0_31) : !cute.int_tuple<"?{div=16}">
      %7 = cute.get_scalars(%e1_32) : !cute.int_tuple<"?{div=128}">
      %iter_33 = cute.get_iter(%slice_28) : !cute.coord_tensor<"(?{div=16},?{div=128})", "(16,128):(1@0,1@1)">
      %tup_34 = cute.deref_arith_tuple_iter(%iter_33) : !cute.arith_tuple_iter<"(?{div=16},?{div=128})">
      %e0_35, %e1_36 = cute.get_leaves(%tup_34) : !cute.int_tuple<"(?{div=16},?{div=128})">
      %8 = cute.get_scalars(%e0_35) : !cute.int_tuple<"?{div=16}">
      %9 = cute.get_scalars(%e1_36) : !cute.int_tuple<"?{div=128}">
      %atom = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<f32>
      %atom_37 = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<f32>
      %prod = cute.raked_product(%arg6, %arg7) : (!cute.layout<"(4,32):(32,1)">, !cute.layout<"(4,4):(4,1)">) -> !cute.layout<"((4,4),(4,32)):((512,32),(128,1))">
      %sz = cute.size(%arg6) : (!cute.layout<"(4,32):(32,1)">) -> !cute.int_tuple<"128">
      %e0_38 = cute.get_leaves(%sz) : !cute.int_tuple<"128">
      %sz_39 = cute.size(%arg7) : (!cute.layout<"(4,4):(4,1)">) -> !cute.int_tuple<"16">
      %e0_40 = cute.get_leaves(%sz_39) : !cute.int_tuple<"16">
      %shape = cute.make_shape() : () -> !cute.shape<"(128,16)">
      %lay_41 = cute.make_layout(%shape) : !cute.layout<"(128,16):(1,128)">
      %rinv = cute.right_inverse(%prod) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.layout<"(32,16,4):(64,4,1)">
      %10 = cute.composition(%rinv, %lay_41) : (!cute.layout<"(32,16,4):(64,4,1)">, !cute.layout<"(128,16):(1,128)">) -> !cute.layout<"((32,4),(4,4)):((64,4),(16,1))">
      %11 = cute.get_shape(%prod) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.shape<"((4,4),(4,32))">
      %e0_42, %e1_43, %e2, %e3 = cute.get_leaves(%11) : !cute.shape<"((4,4),(4,32))">
      %int_tuple = cute.make_int_tuple() : () -> !cute.int_tuple<"((4,4),(4,32))">
      %res = cute.tuple.product_each(%int_tuple) : (!cute.int_tuple<"((4,4),(4,32))">) -> !cute.int_tuple<"(16,128)">
      %e0_44, %e1_45 = cute.get_leaves(%res) : !cute.int_tuple<"(16,128)">
      %int_tuple_46 = cute.make_int_tuple() : () -> !cute.int_tuple<"(16,128)">
      %res_47 = cute.tuple.product_each(%int_tuple_46) : (!cute.int_tuple<"(16,128)">) -> !cute.int_tuple<"(16,128)">
      %e0_48, %e1_49 = cute.get_leaves(%res_47) : !cute.int_tuple<"(16,128)">
      %tile = cute.make_tile() : () -> !cute.tile<"[16:1;128:1]">
      %12 = cute.make_tiled_copy(%atom) : !copy_simt
      %prod_50 = cute.raked_product(%arg6, %arg7) : (!cute.layout<"(4,32):(32,1)">, !cute.layout<"(4,4):(4,1)">) -> !cute.layout<"((4,4),(4,32)):((512,32),(128,1))">
      %sz_51 = cute.size(%arg6) : (!cute.layout<"(4,32):(32,1)">) -> !cute.int_tuple<"128">
      %e0_52 = cute.get_leaves(%sz_51) : !cute.int_tuple<"128">
      %sz_53 = cute.size(%arg7) : (!cute.layout<"(4,4):(4,1)">) -> !cute.int_tuple<"16">
      %e0_54 = cute.get_leaves(%sz_53) : !cute.int_tuple<"16">
      %shape_55 = cute.make_shape() : () -> !cute.shape<"(128,16)">
      %lay_56 = cute.make_layout(%shape_55) : !cute.layout<"(128,16):(1,128)">
      %rinv_57 = cute.right_inverse(%prod_50) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.layout<"(32,16,4):(64,4,1)">
      %13 = cute.composition(%rinv_57, %lay_56) : (!cute.layout<"(32,16,4):(64,4,1)">, !cute.layout<"(128,16):(1,128)">) -> !cute.layout<"((32,4),(4,4)):((64,4),(16,1))">
      %14 = cute.get_shape(%prod_50) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.shape<"((4,4),(4,32))">
      %e0_58, %e1_59, %e2_60, %e3_61 = cute.get_leaves(%14) : !cute.shape<"((4,4),(4,32))">
      %int_tuple_62 = cute.make_int_tuple() : () -> !cute.int_tuple<"((4,4),(4,32))">
      %res_63 = cute.tuple.product_each(%int_tuple_62) : (!cute.int_tuple<"((4,4),(4,32))">) -> !cute.int_tuple<"(16,128)">
      %e0_64, %e1_65 = cute.get_leaves(%res_63) : !cute.int_tuple<"(16,128)">
      %int_tuple_66 = cute.make_int_tuple() : () -> !cute.int_tuple<"(16,128)">
      %res_67 = cute.tuple.product_each(%int_tuple_66) : (!cute.int_tuple<"(16,128)">) -> !cute.int_tuple<"(16,128)">
      %e0_68, %e1_69 = cute.get_leaves(%res_67) : !cute.int_tuple<"(16,128)">
      %tile_70 = cute.make_tile() : () -> !cute.tile<"[16:1;128:1]">
      %15 = cute.make_tiled_copy(%atom) : !copy_simt
      %prod_71 = cute.raked_product(%arg6, %arg7) : (!cute.layout<"(4,32):(32,1)">, !cute.layout<"(4,4):(4,1)">) -> !cute.layout<"((4,4),(4,32)):((512,32),(128,1))">
      %sz_72 = cute.size(%arg6) : (!cute.layout<"(4,32):(32,1)">) -> !cute.int_tuple<"128">
      %e0_73 = cute.get_leaves(%sz_72) : !cute.int_tuple<"128">
      %sz_74 = cute.size(%arg7) : (!cute.layout<"(4,4):(4,1)">) -> !cute.int_tuple<"16">
      %e0_75 = cute.get_leaves(%sz_74) : !cute.int_tuple<"16">
      %shape_76 = cute.make_shape() : () -> !cute.shape<"(128,16)">
      %lay_77 = cute.make_layout(%shape_76) : !cute.layout<"(128,16):(1,128)">
      %rinv_78 = cute.right_inverse(%prod_71) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.layout<"(32,16,4):(64,4,1)">
      %16 = cute.composition(%rinv_78, %lay_77) : (!cute.layout<"(32,16,4):(64,4,1)">, !cute.layout<"(128,16):(1,128)">) -> !cute.layout<"((32,4),(4,4)):((64,4),(16,1))">
      %17 = cute.get_shape(%prod_71) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.shape<"((4,4),(4,32))">
      %e0_79, %e1_80, %e2_81, %e3_82 = cute.get_leaves(%17) : !cute.shape<"((4,4),(4,32))">
      %int_tuple_83 = cute.make_int_tuple() : () -> !cute.int_tuple<"((4,4),(4,32))">
      %res_84 = cute.tuple.product_each(%int_tuple_83) : (!cute.int_tuple<"((4,4),(4,32))">) -> !cute.int_tuple<"(16,128)">
      %e0_85, %e1_86 = cute.get_leaves(%res_84) : !cute.int_tuple<"(16,128)">
      %int_tuple_87 = cute.make_int_tuple() : () -> !cute.int_tuple<"(16,128)">
      %res_88 = cute.tuple.product_each(%int_tuple_87) : (!cute.int_tuple<"(16,128)">) -> !cute.int_tuple<"(16,128)">
      %e0_89, %e1_90 = cute.get_leaves(%res_88) : !cute.int_tuple<"(16,128)">
      %tile_91 = cute.make_tile() : () -> !cute.tile<"[16:1;128:1]">
      %18 = cute.make_tiled_copy(%atom_37) : !copy_simt
      %coord_92 = cute.make_coord(%0) : (i32) -> !cute.coord<"?">
      %src_partitioned = cute.tiled.copy.partition_S(%12, %slice, %coord_92) : (!copy_simt, !memref_gmem_f32_1, !cute.coord<"?">) -> !memref_gmem_f32_2
      %iter_93 = cute.get_iter(%src_partitioned) : !memref_gmem_f32_2
      %coord_94 = cute.make_coord(%0) : (i32) -> !cute.coord<"?">
      %src_partitioned_95 = cute.tiled.copy.partition_S(%15, %slice_20, %coord_94) : (!copy_simt, !memref_gmem_f32_1, !cute.coord<"?">) -> !memref_gmem_f32_2
      %iter_96 = cute.get_iter(%src_partitioned_95) : !memref_gmem_f32_2
      %coord_97 = cute.make_coord(%0) : (i32) -> !cute.coord<"?">
      %src_partitioned_98 = cute.tiled.copy.partition_S(%18, %slice_24, %coord_97) : (!copy_simt, !memref_gmem_f32_1, !cute.coord<"?">) -> !memref_gmem_f32_2
      %iter_99 = cute.get_iter(%src_partitioned_98) : !memref_gmem_f32_2
      %lay_100 = cute.get_layout(%src_partitioned) : !memref_gmem_f32_2
      %19 = cute.make_layout_like(%lay_100) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)"> to !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %rmem = cute.memref.alloca(%19) : !memref_rmem_f32_
      %iter_101 = cute.get_iter(%rmem) : !memref_rmem_f32_
      %iter_102 = cute.get_iter(%rmem) : !memref_rmem_f32_
      %lay_103 = cute.get_layout(%src_partitioned_95) : !memref_gmem_f32_2
      %20 = cute.make_layout_like(%lay_103) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)"> to !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %rmem_104 = cute.memref.alloca(%20) : !memref_rmem_f32_
      %iter_105 = cute.get_iter(%rmem_104) : !memref_rmem_f32_
      %iter_106 = cute.get_iter(%rmem_104) : !memref_rmem_f32_
      %lay_107 = cute.get_layout(%src_partitioned_98) : !memref_gmem_f32_2
      %21 = cute.make_layout_like(%lay_107) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)"> to !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %rmem_108 = cute.memref.alloca(%21) : !memref_rmem_f32_
      %iter_109 = cute.get_iter(%rmem_108) : !memref_rmem_f32_
      %iter_110 = cute.get_iter(%rmem_108) : !memref_rmem_f32_
      %coord_111 = cute.make_coord(%0) : (i32) -> !cute.coord<"?">
      %src_partitioned_112 = cute.tiled.copy.partition_S(%18, %slice_28, %coord_111) : (!copy_simt, !cute.coord_tensor<"(?{div=16},?{div=128})", "(16,128):(1@0,1@1)">, !cute.coord<"?">) -> !cute.coord_tensor<"(?{div=4},?{div=4})", "((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">
      %iter_113 = cute.get_iter(%src_partitioned_112) : !cute.coord_tensor<"(?{div=4},?{div=4})", "((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">
      %tup_114 = cute.deref_arith_tuple_iter(%iter_113) : !cute.arith_tuple_iter<"(?{div=4},?{div=4})">
      %e0_115, %e1_116 = cute.get_leaves(%tup_114) : !cute.int_tuple<"(?{div=4},?{div=4})">
      %22 = cute.get_scalars(%e0_115) : !cute.int_tuple<"?{div=4}">
      %23 = cute.get_scalars(%e1_116) : !cute.int_tuple<"?{div=4}">
      %lay_117 = cute.get_layout(%src_partitioned_112) : !cute.coord_tensor<"(?{div=4},?{div=4})", "((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">
      %24 = cute.get_shape(%lay_117) : (!cute.layout<"((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_118, %e1_119, %e2_120, %e3_121, %e4 = cute.get_leaves(%24) : !cute.shape<"((1,(4,4)),1,1)">
      %shape_122 = cute.make_shape() : () -> !cute.shape<"((1,(4,4)),1,1)">
      %lay_123 = cute.make_layout(%shape_122) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %rmem_124 = cute.memref.alloca(%lay_123) : !memref_rmem_i8_
      %iter_125 = cute.get_iter(%rmem_124) : !memref_rmem_i8_
      %iter_126 = cute.get_iter(%rmem_124) : !memref_rmem_i8_
      %sz_127 = cute.size(%rmem_124) : (!memref_rmem_i8_) -> !cute.int_tuple<"16">
      %e0_128 = cute.get_leaves(%sz_127) : !cute.int_tuple<"16">
      %c0_i32 = arith.constant 0 : i32
      %c16_i32 = arith.constant 16 : i32
      %c1_i32 = arith.constant 1 : i32
      %25 = scf.for %arg8 = %c0_i32 to %c16_i32 step %c1_i32 iter_args(%arg9 = %rmem_124) -> (!memref_rmem_i8_)  : i32 {
        %iter_229 = cute.get_iter(%arg9) : !memref_rmem_i8_
        %iter_230 = cute.get_iter(%arg9) : !memref_rmem_i8_
        %coord_231 = cute.make_coord(%arg8) : (i32) -> !cute.coord<"?">
        %slice_232 = cute.slice(%src_partitioned_112, %coord_231) : !cute.coord_tensor<"(?{div=4},?{div=4})", "((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">, !cute.coord<"?">
        %iter_233 = cute.get_iter(%slice_232) : !cute.coord_tensor<"(?,?)", "():()">
        %tup_234 = cute.deref_arith_tuple_iter(%iter_233) : !cute.arith_tuple_iter<"(?,?)">
        %e0_235, %e1_236 = cute.get_leaves(%tup_234) : !cute.int_tuple<"(?,?)">
        %37 = cute.get_scalars(%e0_235) : !cute.int_tuple<"?">
        %38 = cute.get_scalars(%e1_236) : !cute.int_tuple<"?">
        %iter_237 = cute.get_iter(%slice_232) : !cute.coord_tensor<"(?,?)", "():()">
        %tup_238 = cute.deref_arith_tuple_iter(%iter_237) : !cute.arith_tuple_iter<"(?,?)">
        %e0_239, %e1_240 = cute.get_leaves(%tup_238) : !cute.int_tuple<"(?,?)">
        %39 = cute.get_scalars(%e0_239) : !cute.int_tuple<"?">
        %40 = cute.get_scalars(%e1_240) : !cute.int_tuple<"?">
        %iter_241 = cute.get_iter(%slice_232) : !cute.coord_tensor<"(?,?)", "():()">
        %tup_242 = cute.deref_arith_tuple_iter(%iter_241) : !cute.arith_tuple_iter<"(?,?)">
        %e0_243, %e1_244 = cute.get_leaves(%tup_242) : !cute.int_tuple<"(?,?)">
        %41 = cute.get_scalars(%e0_243) : !cute.int_tuple<"?">
        %42 = cute.get_scalars(%e1_244) : !cute.int_tuple<"?">
        %coord_245 = cute.make_coord(%e0_243, %e1_244) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
        %coord_246 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
        %43 = cute.elem_less(%coord_245, %coord_246) : !cute.coord<"(?,?)">, !cute.coord<"(?,?)">
        %44 = arith.extui %43 : i1 to i8
        %coord_247 = cute.make_coord(%arg8) : (i32) -> !cute.coord<"?">
        cute.memref.store(%arg9, %coord_247, %44) : (!memref_rmem_i8_, !cute.coord<"?">, i8) -> ()
        scf.yield %arg9 : !memref_rmem_i8_
      }
      %iter_129 = cute.get_iter(%25) : !memref_rmem_i8_
      %iter_130 = cute.get_iter(%25) : !memref_rmem_i8_
      %iter_131 = cute.get_iter(%25) : !memref_rmem_i8_
      %false = arith.constant false
      scf.if %false {
        %c0_i32_229 = arith.constant 0 : i32
        %c10_i32_230 = arith.constant 10 : i32
        %c1_i32_231 = arith.constant 1 : i32
        scf.for %arg8 = %c0_i32_229 to %c10_i32_230 step %c1_i32_231  : i32 {
          %lay_232 = cute.get_layout(%src_partitioned) : !memref_gmem_f32_2
          %37 = cute.get_shape(%lay_232) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_233, %e1_234, %e2_235, %e3_236, %e4_237 = cute.get_leaves(%37) : !cute.shape<"((1,(4,4)),1,1)">
          %lay_238 = cute.get_layout(%rmem) : !memref_rmem_f32_
          %38 = cute.get_shape(%lay_238) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_239, %e1_240, %e2_241, %e3_242, %e4_243 = cute.get_leaves(%38) : !cute.shape<"((1,(4,4)),1,1)">
          %lay_244 = cute.get_layout(%src_partitioned) : !memref_gmem_f32_2
          %shape_245 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_246 = cute.make_layout(%shape_245) : !cute.layout<"1:0">
          %append_247 = cute.append_to_rank<2> (%lay_244, %lay_246) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">
          %view_248 = cute.make_view(%iter_93, %append_247) : !memref_gmem_f32_2
          %iter_249 = cute.get_iter(%view_248) : !memref_gmem_f32_2
          %lay_250 = cute.get_layout(%view_248) : !memref_gmem_f32_2
          %39 = cute.get_shape(%lay_250) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_251, %e1_252, %e2_253, %e3_254, %e4_255 = cute.get_leaves(%39) : !cute.shape<"((1,(4,4)),1,1)">
          %lay_256 = cute.get_layout(%view_248) : !memref_gmem_f32_2
          %40 = cute.get_shape(%lay_256) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_257, %e1_258, %e2_259, %e3_260, %e4_261 = cute.get_leaves(%40) : !cute.shape<"((1,(4,4)),1,1)">
          %grouped_262 = cute.group_modes(%view_248) <1, 3> : (!memref_gmem_f32_2) -> !memref_gmem_f32_3
          %iter_263 = cute.get_iter(%grouped_262) : !memref_gmem_f32_3
          %iter_264 = cute.get_iter(%grouped_262) : !memref_gmem_f32_3
          %lay_265 = cute.get_layout(%rmem) : !memref_rmem_f32_
          %shape_266 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_267 = cute.make_layout(%shape_266) : !cute.layout<"1:0">
          %append_268 = cute.append_to_rank<2> (%lay_265, %lay_267) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
          %view_269 = cute.make_view(%iter_102, %append_268) : !memref_rmem_f32_
          %iter_270 = cute.get_iter(%view_269) : !memref_rmem_f32_
          %lay_271 = cute.get_layout(%view_269) : !memref_rmem_f32_
          %41 = cute.get_shape(%lay_271) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_272, %e1_273, %e2_274, %e3_275, %e4_276 = cute.get_leaves(%41) : !cute.shape<"((1,(4,4)),1,1)">
          %lay_277 = cute.get_layout(%view_269) : !memref_rmem_f32_
          %42 = cute.get_shape(%lay_277) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_278, %e1_279, %e2_280, %e3_281, %e4_282 = cute.get_leaves(%42) : !cute.shape<"((1,(4,4)),1,1)">
          %grouped_283 = cute.group_modes(%view_269) <1, 3> : (!memref_rmem_f32_) -> !memref_rmem_f32_1
          %iter_284 = cute.get_iter(%grouped_283) : !memref_rmem_f32_1
          %iter_285 = cute.get_iter(%grouped_283) : !memref_rmem_f32_1
          %lay_286 = cute.get_layout(%25) : !memref_rmem_i8_
          %shape_287 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_288 = cute.make_layout(%shape_287) : !cute.layout<"1:0">
          %append_289 = cute.append_to_rank<2> (%lay_286, %lay_288) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
          %view_290 = cute.make_view(%iter_131, %append_289) : !memref_rmem_i8_
          %iter_291 = cute.get_iter(%view_290) : !memref_rmem_i8_
          %lay_292 = cute.get_layout(%view_290) : !memref_rmem_i8_
          %43 = cute.get_shape(%lay_292) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_293, %e1_294, %e2_295, %e3_296, %e4_297 = cute.get_leaves(%43) : !cute.shape<"((1,(4,4)),1,1)">
          %lay_298 = cute.get_layout(%view_290) : !memref_rmem_i8_
          %44 = cute.get_shape(%lay_298) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_299, %e1_300, %e2_301, %e3_302, %e4_303 = cute.get_leaves(%44) : !cute.shape<"((1,(4,4)),1,1)">
          %grouped_304 = cute.group_modes(%view_290) <1, 3> : (!memref_rmem_i8_) -> !memref_rmem_i8_1
          %iter_305 = cute.get_iter(%grouped_304) : !memref_rmem_i8_1
          %iter_306 = cute.get_iter(%grouped_304) : !memref_rmem_i8_1
          %lay_307 = cute.get_layout(%grouped_262) : !memref_gmem_f32_3
          %45 = cute.get_shape(%lay_307) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
          %e0_308, %e1_309, %e2_310, %e3_311, %e4_312 = cute.get_leaves(%45) : !cute.shape<"((1,(4,4)),(1,1))">
          %lay_313 = cute.get_layout(%grouped_283) : !memref_rmem_f32_1
          %46 = cute.get_shape(%lay_313) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
          %e0_314, %e1_315, %e2_316, %e3_317, %e4_318 = cute.get_leaves(%46) : !cute.shape<"((1,(4,4)),(1,1))">
          %sz_319 = cute.size(%grouped_262) <{mode = [1]}> : (!memref_gmem_f32_3) -> !cute.int_tuple<"1">
          %e0_320 = cute.get_leaves(%sz_319) : !cute.int_tuple<"1">
          %sz_321 = cute.size(%grouped_283) <{mode = [1]}> : (!memref_rmem_f32_1) -> !cute.int_tuple<"1">
          %e0_322 = cute.get_leaves(%sz_321) : !cute.int_tuple<"1">
          cute.copy(%atom, %grouped_262, %grouped_283, %grouped_304) : (!cute_nvgpu.atom.universal_copy<f32>, !memref_gmem_f32_3, !memref_rmem_f32_1, !memref_rmem_i8_1)
          %lay_323 = cute.get_layout(%src_partitioned_95) : !memref_gmem_f32_2
          %47 = cute.get_shape(%lay_323) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_324, %e1_325, %e2_326, %e3_327, %e4_328 = cute.get_leaves(%47) : !cute.shape<"((1,(4,4)),1,1)">
          %lay_329 = cute.get_layout(%rmem_104) : !memref_rmem_f32_
          %48 = cute.get_shape(%lay_329) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_330, %e1_331, %e2_332, %e3_333, %e4_334 = cute.get_leaves(%48) : !cute.shape<"((1,(4,4)),1,1)">
          %lay_335 = cute.get_layout(%src_partitioned_95) : !memref_gmem_f32_2
          %shape_336 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_337 = cute.make_layout(%shape_336) : !cute.layout<"1:0">
          %append_338 = cute.append_to_rank<2> (%lay_335, %lay_337) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">
          %view_339 = cute.make_view(%iter_96, %append_338) : !memref_gmem_f32_2
          %iter_340 = cute.get_iter(%view_339) : !memref_gmem_f32_2
          %lay_341 = cute.get_layout(%view_339) : !memref_gmem_f32_2
          %49 = cute.get_shape(%lay_341) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_342, %e1_343, %e2_344, %e3_345, %e4_346 = cute.get_leaves(%49) : !cute.shape<"((1,(4,4)),1,1)">
          %lay_347 = cute.get_layout(%view_339) : !memref_gmem_f32_2
          %50 = cute.get_shape(%lay_347) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_348, %e1_349, %e2_350, %e3_351, %e4_352 = cute.get_leaves(%50) : !cute.shape<"((1,(4,4)),1,1)">
          %grouped_353 = cute.group_modes(%view_339) <1, 3> : (!memref_gmem_f32_2) -> !memref_gmem_f32_3
          %iter_354 = cute.get_iter(%grouped_353) : !memref_gmem_f32_3
          %iter_355 = cute.get_iter(%grouped_353) : !memref_gmem_f32_3
          %lay_356 = cute.get_layout(%rmem_104) : !memref_rmem_f32_
          %shape_357 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_358 = cute.make_layout(%shape_357) : !cute.layout<"1:0">
          %append_359 = cute.append_to_rank<2> (%lay_356, %lay_358) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
          %view_360 = cute.make_view(%iter_106, %append_359) : !memref_rmem_f32_
          %iter_361 = cute.get_iter(%view_360) : !memref_rmem_f32_
          %lay_362 = cute.get_layout(%view_360) : !memref_rmem_f32_
          %51 = cute.get_shape(%lay_362) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_363, %e1_364, %e2_365, %e3_366, %e4_367 = cute.get_leaves(%51) : !cute.shape<"((1,(4,4)),1,1)">
          %lay_368 = cute.get_layout(%view_360) : !memref_rmem_f32_
          %52 = cute.get_shape(%lay_368) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_369, %e1_370, %e2_371, %e3_372, %e4_373 = cute.get_leaves(%52) : !cute.shape<"((1,(4,4)),1,1)">
          %grouped_374 = cute.group_modes(%view_360) <1, 3> : (!memref_rmem_f32_) -> !memref_rmem_f32_1
          %iter_375 = cute.get_iter(%grouped_374) : !memref_rmem_f32_1
          %iter_376 = cute.get_iter(%grouped_374) : !memref_rmem_f32_1
          %lay_377 = cute.get_layout(%25) : !memref_rmem_i8_
          %shape_378 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_379 = cute.make_layout(%shape_378) : !cute.layout<"1:0">
          %append_380 = cute.append_to_rank<2> (%lay_377, %lay_379) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
          %view_381 = cute.make_view(%iter_131, %append_380) : !memref_rmem_i8_
          %iter_382 = cute.get_iter(%view_381) : !memref_rmem_i8_
          %lay_383 = cute.get_layout(%view_381) : !memref_rmem_i8_
          %53 = cute.get_shape(%lay_383) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_384, %e1_385, %e2_386, %e3_387, %e4_388 = cute.get_leaves(%53) : !cute.shape<"((1,(4,4)),1,1)">
          %lay_389 = cute.get_layout(%view_381) : !memref_rmem_i8_
          %54 = cute.get_shape(%lay_389) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_390, %e1_391, %e2_392, %e3_393, %e4_394 = cute.get_leaves(%54) : !cute.shape<"((1,(4,4)),1,1)">
          %grouped_395 = cute.group_modes(%view_381) <1, 3> : (!memref_rmem_i8_) -> !memref_rmem_i8_1
          %iter_396 = cute.get_iter(%grouped_395) : !memref_rmem_i8_1
          %iter_397 = cute.get_iter(%grouped_395) : !memref_rmem_i8_1
          %lay_398 = cute.get_layout(%grouped_353) : !memref_gmem_f32_3
          %55 = cute.get_shape(%lay_398) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
          %e0_399, %e1_400, %e2_401, %e3_402, %e4_403 = cute.get_leaves(%55) : !cute.shape<"((1,(4,4)),(1,1))">
          %lay_404 = cute.get_layout(%grouped_374) : !memref_rmem_f32_1
          %56 = cute.get_shape(%lay_404) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
          %e0_405, %e1_406, %e2_407, %e3_408, %e4_409 = cute.get_leaves(%56) : !cute.shape<"((1,(4,4)),(1,1))">
          %sz_410 = cute.size(%grouped_353) <{mode = [1]}> : (!memref_gmem_f32_3) -> !cute.int_tuple<"1">
          %e0_411 = cute.get_leaves(%sz_410) : !cute.int_tuple<"1">
          %sz_412 = cute.size(%grouped_374) <{mode = [1]}> : (!memref_rmem_f32_1) -> !cute.int_tuple<"1">
          %e0_413 = cute.get_leaves(%sz_412) : !cute.int_tuple<"1">
          cute.copy(%atom, %grouped_353, %grouped_374, %grouped_395) : (!cute_nvgpu.atom.universal_copy<f32>, !memref_gmem_f32_3, !memref_rmem_f32_1, !memref_rmem_i8_1)
        }
        llvm.inline_asm has_side_effects asm_dialect = att "griddepcontrol.launch_dependents;", ""  : () -> ()
      } else {
        %c0_i32_229 = arith.constant 0 : i32
        %c10_i32_230 = arith.constant 10 : i32
        %c1_i32_231 = arith.constant 1 : i32
        scf.for %arg8 = %c0_i32_229 to %c10_i32_230 step %c1_i32_231  : i32 {
          %lay_232 = cute.get_layout(%src_partitioned_95) : !memref_gmem_f32_2
          %37 = cute.get_shape(%lay_232) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_233, %e1_234, %e2_235, %e3_236, %e4_237 = cute.get_leaves(%37) : !cute.shape<"((1,(4,4)),1,1)">
          %lay_238 = cute.get_layout(%rmem_104) : !memref_rmem_f32_
          %38 = cute.get_shape(%lay_238) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_239, %e1_240, %e2_241, %e3_242, %e4_243 = cute.get_leaves(%38) : !cute.shape<"((1,(4,4)),1,1)">
          %lay_244 = cute.get_layout(%src_partitioned_95) : !memref_gmem_f32_2
          %shape_245 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_246 = cute.make_layout(%shape_245) : !cute.layout<"1:0">
          %append_247 = cute.append_to_rank<2> (%lay_244, %lay_246) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">
          %view_248 = cute.make_view(%iter_96, %append_247) : !memref_gmem_f32_2
          %iter_249 = cute.get_iter(%view_248) : !memref_gmem_f32_2
          %lay_250 = cute.get_layout(%view_248) : !memref_gmem_f32_2
          %39 = cute.get_shape(%lay_250) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_251, %e1_252, %e2_253, %e3_254, %e4_255 = cute.get_leaves(%39) : !cute.shape<"((1,(4,4)),1,1)">
          %lay_256 = cute.get_layout(%view_248) : !memref_gmem_f32_2
          %40 = cute.get_shape(%lay_256) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_257, %e1_258, %e2_259, %e3_260, %e4_261 = cute.get_leaves(%40) : !cute.shape<"((1,(4,4)),1,1)">
          %grouped_262 = cute.group_modes(%view_248) <1, 3> : (!memref_gmem_f32_2) -> !memref_gmem_f32_3
          %iter_263 = cute.get_iter(%grouped_262) : !memref_gmem_f32_3
          %iter_264 = cute.get_iter(%grouped_262) : !memref_gmem_f32_3
          %lay_265 = cute.get_layout(%rmem_104) : !memref_rmem_f32_
          %shape_266 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_267 = cute.make_layout(%shape_266) : !cute.layout<"1:0">
          %append_268 = cute.append_to_rank<2> (%lay_265, %lay_267) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
          %view_269 = cute.make_view(%iter_106, %append_268) : !memref_rmem_f32_
          %iter_270 = cute.get_iter(%view_269) : !memref_rmem_f32_
          %lay_271 = cute.get_layout(%view_269) : !memref_rmem_f32_
          %41 = cute.get_shape(%lay_271) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_272, %e1_273, %e2_274, %e3_275, %e4_276 = cute.get_leaves(%41) : !cute.shape<"((1,(4,4)),1,1)">
          %lay_277 = cute.get_layout(%view_269) : !memref_rmem_f32_
          %42 = cute.get_shape(%lay_277) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_278, %e1_279, %e2_280, %e3_281, %e4_282 = cute.get_leaves(%42) : !cute.shape<"((1,(4,4)),1,1)">
          %grouped_283 = cute.group_modes(%view_269) <1, 3> : (!memref_rmem_f32_) -> !memref_rmem_f32_1
          %iter_284 = cute.get_iter(%grouped_283) : !memref_rmem_f32_1
          %iter_285 = cute.get_iter(%grouped_283) : !memref_rmem_f32_1
          %lay_286 = cute.get_layout(%25) : !memref_rmem_i8_
          %shape_287 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_288 = cute.make_layout(%shape_287) : !cute.layout<"1:0">
          %append_289 = cute.append_to_rank<2> (%lay_286, %lay_288) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
          %view_290 = cute.make_view(%iter_131, %append_289) : !memref_rmem_i8_
          %iter_291 = cute.get_iter(%view_290) : !memref_rmem_i8_
          %lay_292 = cute.get_layout(%view_290) : !memref_rmem_i8_
          %43 = cute.get_shape(%lay_292) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_293, %e1_294, %e2_295, %e3_296, %e4_297 = cute.get_leaves(%43) : !cute.shape<"((1,(4,4)),1,1)">
          %lay_298 = cute.get_layout(%view_290) : !memref_rmem_i8_
          %44 = cute.get_shape(%lay_298) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_299, %e1_300, %e2_301, %e3_302, %e4_303 = cute.get_leaves(%44) : !cute.shape<"((1,(4,4)),1,1)">
          %grouped_304 = cute.group_modes(%view_290) <1, 3> : (!memref_rmem_i8_) -> !memref_rmem_i8_1
          %iter_305 = cute.get_iter(%grouped_304) : !memref_rmem_i8_1
          %iter_306 = cute.get_iter(%grouped_304) : !memref_rmem_i8_1
          %lay_307 = cute.get_layout(%grouped_262) : !memref_gmem_f32_3
          %45 = cute.get_shape(%lay_307) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
          %e0_308, %e1_309, %e2_310, %e3_311, %e4_312 = cute.get_leaves(%45) : !cute.shape<"((1,(4,4)),(1,1))">
          %lay_313 = cute.get_layout(%grouped_283) : !memref_rmem_f32_1
          %46 = cute.get_shape(%lay_313) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
          %e0_314, %e1_315, %e2_316, %e3_317, %e4_318 = cute.get_leaves(%46) : !cute.shape<"((1,(4,4)),(1,1))">
          %sz_319 = cute.size(%grouped_262) <{mode = [1]}> : (!memref_gmem_f32_3) -> !cute.int_tuple<"1">
          %e0_320 = cute.get_leaves(%sz_319) : !cute.int_tuple<"1">
          %sz_321 = cute.size(%grouped_283) <{mode = [1]}> : (!memref_rmem_f32_1) -> !cute.int_tuple<"1">
          %e0_322 = cute.get_leaves(%sz_321) : !cute.int_tuple<"1">
          cute.copy(%atom, %grouped_262, %grouped_283, %grouped_304) : (!cute_nvgpu.atom.universal_copy<f32>, !memref_gmem_f32_3, !memref_rmem_f32_1, !memref_rmem_i8_1)
        }
        llvm.inline_asm has_side_effects asm_dialect = att "griddepcontrol.wait;", ""  : () -> ()
        scf.for %arg8 = %c0_i32_229 to %c10_i32_230 step %c1_i32_231  : i32 {
          %lay_232 = cute.get_layout(%src_partitioned) : !memref_gmem_f32_2
          %37 = cute.get_shape(%lay_232) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_233, %e1_234, %e2_235, %e3_236, %e4_237 = cute.get_leaves(%37) : !cute.shape<"((1,(4,4)),1,1)">
          %lay_238 = cute.get_layout(%rmem) : !memref_rmem_f32_
          %38 = cute.get_shape(%lay_238) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_239, %e1_240, %e2_241, %e3_242, %e4_243 = cute.get_leaves(%38) : !cute.shape<"((1,(4,4)),1,1)">
          %lay_244 = cute.get_layout(%src_partitioned) : !memref_gmem_f32_2
          %shape_245 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_246 = cute.make_layout(%shape_245) : !cute.layout<"1:0">
          %append_247 = cute.append_to_rank<2> (%lay_244, %lay_246) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">
          %view_248 = cute.make_view(%iter_93, %append_247) : !memref_gmem_f32_2
          %iter_249 = cute.get_iter(%view_248) : !memref_gmem_f32_2
          %lay_250 = cute.get_layout(%view_248) : !memref_gmem_f32_2
          %39 = cute.get_shape(%lay_250) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_251, %e1_252, %e2_253, %e3_254, %e4_255 = cute.get_leaves(%39) : !cute.shape<"((1,(4,4)),1,1)">
          %lay_256 = cute.get_layout(%view_248) : !memref_gmem_f32_2
          %40 = cute.get_shape(%lay_256) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_257, %e1_258, %e2_259, %e3_260, %e4_261 = cute.get_leaves(%40) : !cute.shape<"((1,(4,4)),1,1)">
          %grouped_262 = cute.group_modes(%view_248) <1, 3> : (!memref_gmem_f32_2) -> !memref_gmem_f32_3
          %iter_263 = cute.get_iter(%grouped_262) : !memref_gmem_f32_3
          %iter_264 = cute.get_iter(%grouped_262) : !memref_gmem_f32_3
          %lay_265 = cute.get_layout(%rmem) : !memref_rmem_f32_
          %shape_266 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_267 = cute.make_layout(%shape_266) : !cute.layout<"1:0">
          %append_268 = cute.append_to_rank<2> (%lay_265, %lay_267) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
          %view_269 = cute.make_view(%iter_102, %append_268) : !memref_rmem_f32_
          %iter_270 = cute.get_iter(%view_269) : !memref_rmem_f32_
          %lay_271 = cute.get_layout(%view_269) : !memref_rmem_f32_
          %41 = cute.get_shape(%lay_271) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_272, %e1_273, %e2_274, %e3_275, %e4_276 = cute.get_leaves(%41) : !cute.shape<"((1,(4,4)),1,1)">
          %lay_277 = cute.get_layout(%view_269) : !memref_rmem_f32_
          %42 = cute.get_shape(%lay_277) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_278, %e1_279, %e2_280, %e3_281, %e4_282 = cute.get_leaves(%42) : !cute.shape<"((1,(4,4)),1,1)">
          %grouped_283 = cute.group_modes(%view_269) <1, 3> : (!memref_rmem_f32_) -> !memref_rmem_f32_1
          %iter_284 = cute.get_iter(%grouped_283) : !memref_rmem_f32_1
          %iter_285 = cute.get_iter(%grouped_283) : !memref_rmem_f32_1
          %lay_286 = cute.get_layout(%25) : !memref_rmem_i8_
          %shape_287 = cute.make_shape() : () -> !cute.shape<"1">
          %lay_288 = cute.make_layout(%shape_287) : !cute.layout<"1:0">
          %append_289 = cute.append_to_rank<2> (%lay_286, %lay_288) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
          %view_290 = cute.make_view(%iter_131, %append_289) : !memref_rmem_i8_
          %iter_291 = cute.get_iter(%view_290) : !memref_rmem_i8_
          %lay_292 = cute.get_layout(%view_290) : !memref_rmem_i8_
          %43 = cute.get_shape(%lay_292) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_293, %e1_294, %e2_295, %e3_296, %e4_297 = cute.get_leaves(%43) : !cute.shape<"((1,(4,4)),1,1)">
          %lay_298 = cute.get_layout(%view_290) : !memref_rmem_i8_
          %44 = cute.get_shape(%lay_298) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
          %e0_299, %e1_300, %e2_301, %e3_302, %e4_303 = cute.get_leaves(%44) : !cute.shape<"((1,(4,4)),1,1)">
          %grouped_304 = cute.group_modes(%view_290) <1, 3> : (!memref_rmem_i8_) -> !memref_rmem_i8_1
          %iter_305 = cute.get_iter(%grouped_304) : !memref_rmem_i8_1
          %iter_306 = cute.get_iter(%grouped_304) : !memref_rmem_i8_1
          %lay_307 = cute.get_layout(%grouped_262) : !memref_gmem_f32_3
          %45 = cute.get_shape(%lay_307) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
          %e0_308, %e1_309, %e2_310, %e3_311, %e4_312 = cute.get_leaves(%45) : !cute.shape<"((1,(4,4)),(1,1))">
          %lay_313 = cute.get_layout(%grouped_283) : !memref_rmem_f32_1
          %46 = cute.get_shape(%lay_313) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
          %e0_314, %e1_315, %e2_316, %e3_317, %e4_318 = cute.get_leaves(%46) : !cute.shape<"((1,(4,4)),(1,1))">
          %sz_319 = cute.size(%grouped_262) <{mode = [1]}> : (!memref_gmem_f32_3) -> !cute.int_tuple<"1">
          %e0_320 = cute.get_leaves(%sz_319) : !cute.int_tuple<"1">
          %sz_321 = cute.size(%grouped_283) <{mode = [1]}> : (!memref_rmem_f32_1) -> !cute.int_tuple<"1">
          %e0_322 = cute.get_leaves(%sz_321) : !cute.int_tuple<"1">
          cute.copy(%atom, %grouped_262, %grouped_283, %grouped_304) : (!cute_nvgpu.atom.universal_copy<f32>, !memref_gmem_f32_3, !memref_rmem_f32_1, !memref_rmem_i8_1)
        }
      }
      %c10_i32 = arith.constant 10 : i32
      %26:3 = scf.for %arg8 = %c0_i32 to %c10_i32 step %c1_i32 iter_args(%arg9 = %rmem, %arg10 = %rmem_104, %arg11 = %rmem_108) -> (!memref_rmem_f32_, !memref_rmem_f32_, !memref_rmem_f32_)  : i32 {
        %iter_229 = cute.get_iter(%arg9) : !memref_rmem_f32_
        %iter_230 = cute.get_iter(%arg10) : !memref_rmem_f32_
        %iter_231 = cute.get_iter(%arg11) : !memref_rmem_f32_
        %iter_232 = cute.get_iter(%arg9) : !memref_rmem_f32_
        %iter_233 = cute.get_iter(%arg10) : !memref_rmem_f32_
        %iter_234 = cute.get_iter(%arg11) : !memref_rmem_f32_
        %lay_235 = cute.get_layout(%arg9) : !memref_rmem_f32_
        %37 = cute.get_shape(%lay_235) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
        %e0_236, %e1_237, %e2_238, %e3_239, %e4_240 = cute.get_leaves(%37) : !cute.shape<"((1,(4,4)),1,1)">
        %38 = cute.memref.load_vec %arg9 : !memref_rmem_f32_
        %lay_241 = cute.get_layout(%arg9) : !memref_rmem_f32_
        %39 = cute.get_shape(%lay_241) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
        %e0_242, %e1_243, %e2_244, %e3_245, %e4_246 = cute.get_leaves(%39) : !cute.shape<"((1,(4,4)),1,1)">
        %lay_247 = cute.get_layout(%arg10) : !memref_rmem_f32_
        %40 = cute.get_shape(%lay_247) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
        %e0_248, %e1_249, %e2_250, %e3_251, %e4_252 = cute.get_leaves(%40) : !cute.shape<"((1,(4,4)),1,1)">
        %41 = cute.memref.load_vec %arg10 : !memref_rmem_f32_
        %lay_253 = cute.get_layout(%arg10) : !memref_rmem_f32_
        %42 = cute.get_shape(%lay_253) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
        %e0_254, %e1_255, %e2_256, %e3_257, %e4_258 = cute.get_leaves(%42) : !cute.shape<"((1,(4,4)),1,1)">
        %43 = arith.addf %38, %41 : vector<16xf32>
        %lay_259 = cute.get_layout(%arg11) : !memref_rmem_f32_
        %44 = cute.get_shape(%lay_259) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
        %e0_260, %e1_261, %e2_262, %e3_263, %e4_264 = cute.get_leaves(%44) : !cute.shape<"((1,(4,4)),1,1)">
        %lay_265 = cute.get_layout(%arg11) : !memref_rmem_f32_
        %45 = cute.get_shape(%lay_265) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
        %e0_266, %e1_267, %e2_268, %e3_269, %e4_270 = cute.get_leaves(%45) : !cute.shape<"((1,(4,4)),1,1)">
        %int_tuple_271 = cute.make_int_tuple() : () -> !cute.int_tuple<"((1,(4,4)),1,1)">
        %sz_272 = cute.size(%int_tuple_271) : (!cute.int_tuple<"((1,(4,4)),1,1)">) -> !cute.int_tuple<"16">
        %e0_273 = cute.get_leaves(%sz_272) : !cute.int_tuple<"16">
        %int_tuple_274 = cute.make_int_tuple() : () -> !cute.int_tuple<"((1,(4,4)),1,1)">
        %sz_275 = cute.size(%int_tuple_274) : (!cute.int_tuple<"((1,(4,4)),1,1)">) -> !cute.int_tuple<"16">
        %e0_276 = cute.get_leaves(%sz_275) : !cute.int_tuple<"16">
        cute.memref.store_vec %43, %arg11 : !memref_rmem_f32_
        scf.yield %arg9, %arg10, %arg11 : !memref_rmem_f32_, !memref_rmem_f32_, !memref_rmem_f32_
      }
      %iter_132 = cute.get_iter(%26#0) : !memref_rmem_f32_
      %iter_133 = cute.get_iter(%26#1) : !memref_rmem_f32_
      %iter_134 = cute.get_iter(%26#2) : !memref_rmem_f32_
      %iter_135 = cute.get_iter(%26#0) : !memref_rmem_f32_
      %iter_136 = cute.get_iter(%26#0) : !memref_rmem_f32_
      %iter_137 = cute.get_iter(%26#1) : !memref_rmem_f32_
      %iter_138 = cute.get_iter(%26#1) : !memref_rmem_f32_
      %iter_139 = cute.get_iter(%26#2) : !memref_rmem_f32_
      %iter_140 = cute.get_iter(%26#2) : !memref_rmem_f32_
      %lay_141 = cute.get_layout(%26#2) : !memref_rmem_f32_
      %27 = cute.get_shape(%lay_141) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_142, %e1_143, %e2_144, %e3_145, %e4_146 = cute.get_leaves(%27) : !cute.shape<"((1,(4,4)),1,1)">
      %lay_147 = cute.get_layout(%src_partitioned_98) : !memref_gmem_f32_2
      %28 = cute.get_shape(%lay_147) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_148, %e1_149, %e2_150, %e3_151, %e4_152 = cute.get_leaves(%28) : !cute.shape<"((1,(4,4)),1,1)">
      %lay_153 = cute.get_layout(%26#2) : !memref_rmem_f32_
      %shape_154 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_155 = cute.make_layout(%shape_154) : !cute.layout<"1:0">
      %append = cute.append_to_rank<2> (%lay_153, %lay_155) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
      %view = cute.make_view(%iter_140, %append) : !memref_rmem_f32_
      %iter_156 = cute.get_iter(%view) : !memref_rmem_f32_
      %lay_157 = cute.get_layout(%view) : !memref_rmem_f32_
      %29 = cute.get_shape(%lay_157) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_158, %e1_159, %e2_160, %e3_161, %e4_162 = cute.get_leaves(%29) : !cute.shape<"((1,(4,4)),1,1)">
      %lay_163 = cute.get_layout(%view) : !memref_rmem_f32_
      %30 = cute.get_shape(%lay_163) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_164, %e1_165, %e2_166, %e3_167, %e4_168 = cute.get_leaves(%30) : !cute.shape<"((1,(4,4)),1,1)">
      %grouped = cute.group_modes(%view) <1, 3> : (!memref_rmem_f32_) -> !memref_rmem_f32_1
      %iter_169 = cute.get_iter(%grouped) : !memref_rmem_f32_1
      %iter_170 = cute.get_iter(%grouped) : !memref_rmem_f32_1
      %lay_171 = cute.get_layout(%src_partitioned_98) : !memref_gmem_f32_2
      %shape_172 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_173 = cute.make_layout(%shape_172) : !cute.layout<"1:0">
      %append_174 = cute.append_to_rank<2> (%lay_171, %lay_173) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">
      %view_175 = cute.make_view(%iter_99, %append_174) : !memref_gmem_f32_2
      %iter_176 = cute.get_iter(%view_175) : !memref_gmem_f32_2
      %lay_177 = cute.get_layout(%view_175) : !memref_gmem_f32_2
      %31 = cute.get_shape(%lay_177) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_178, %e1_179, %e2_180, %e3_181, %e4_182 = cute.get_leaves(%31) : !cute.shape<"((1,(4,4)),1,1)">
      %lay_183 = cute.get_layout(%view_175) : !memref_gmem_f32_2
      %32 = cute.get_shape(%lay_183) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_184, %e1_185, %e2_186, %e3_187, %e4_188 = cute.get_leaves(%32) : !cute.shape<"((1,(4,4)),1,1)">
      %grouped_189 = cute.group_modes(%view_175) <1, 3> : (!memref_gmem_f32_2) -> !memref_gmem_f32_3
      %iter_190 = cute.get_iter(%grouped_189) : !memref_gmem_f32_3
      %iter_191 = cute.get_iter(%grouped_189) : !memref_gmem_f32_3
      %lay_192 = cute.get_layout(%25) : !memref_rmem_i8_
      %shape_193 = cute.make_shape() : () -> !cute.shape<"1">
      %lay_194 = cute.make_layout(%shape_193) : !cute.layout<"1:0">
      %append_195 = cute.append_to_rank<2> (%lay_192, %lay_194) : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">, !cute.layout<"1:0">
      %view_196 = cute.make_view(%iter_131, %append_195) : !memref_rmem_i8_
      %iter_197 = cute.get_iter(%view_196) : !memref_rmem_i8_
      %lay_198 = cute.get_layout(%view_196) : !memref_rmem_i8_
      %33 = cute.get_shape(%lay_198) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_199, %e1_200, %e2_201, %e3_202, %e4_203 = cute.get_leaves(%33) : !cute.shape<"((1,(4,4)),1,1)">
      %lay_204 = cute.get_layout(%view_196) : !memref_rmem_i8_
      %34 = cute.get_shape(%lay_204) : (!cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">) -> !cute.shape<"((1,(4,4)),1,1)">
      %e0_205, %e1_206, %e2_207, %e3_208, %e4_209 = cute.get_leaves(%34) : !cute.shape<"((1,(4,4)),1,1)">
      %grouped_210 = cute.group_modes(%view_196) <1, 3> : (!memref_rmem_i8_) -> !memref_rmem_i8_1
      %iter_211 = cute.get_iter(%grouped_210) : !memref_rmem_i8_1
      %iter_212 = cute.get_iter(%grouped_210) : !memref_rmem_i8_1
      %lay_213 = cute.get_layout(%grouped) : !memref_rmem_f32_1
      %35 = cute.get_shape(%lay_213) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
      %e0_214, %e1_215, %e2_216, %e3_217, %e4_218 = cute.get_leaves(%35) : !cute.shape<"((1,(4,4)),(1,1))">
      %lay_219 = cute.get_layout(%grouped_189) : !memref_gmem_f32_3
      %36 = cute.get_shape(%lay_219) : (!cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">) -> !cute.shape<"((1,(4,4)),(1,1))">
      %e0_220, %e1_221, %e2_222, %e3_223, %e4_224 = cute.get_leaves(%36) : !cute.shape<"((1,(4,4)),(1,1))">
      %sz_225 = cute.size(%grouped) <{mode = [1]}> : (!memref_rmem_f32_1) -> !cute.int_tuple<"1">
      %e0_226 = cute.get_leaves(%sz_225) : !cute.int_tuple<"1">
      %sz_227 = cute.size(%grouped_189) <{mode = [1]}> : (!memref_gmem_f32_3) -> !cute.int_tuple<"1">
      %e0_228 = cute.get_leaves(%sz_227) : !cute.int_tuple<"1">
      cute.copy(%atom_37, %grouped, %grouped_189, %grouped_210) : (!cute_nvgpu.atom.universal_copy<f32>, !memref_rmem_f32_1, !memref_gmem_f32_3, !memref_rmem_i8_1)
      return
    }
  }
  func.func @cutlass_elementwise_add_Tensorgmem_o_i641_Tensorgmem_o_i641_Tensorgmem_o_i641_CUstream_False_False(%arg0: !memref_gmem_f32_4, %arg1: !memref_gmem_f32_4, %arg2: !memref_gmem_f32_4, %arg3: !cuda.stream) -> i32 attributes {llvm.emit_c_interface} {
    %iter = cute.get_iter(%arg0) : !memref_gmem_f32_4
    %iter_0 = cute.get_iter(%arg1) : !memref_gmem_f32_4
    %iter_1 = cute.get_iter(%arg2) : !memref_gmem_f32_4
    %iter_2 = cute.get_iter(%arg0) : !memref_gmem_f32_4
    %iter_3 = cute.get_iter(%arg1) : !memref_gmem_f32_4
    %iter_4 = cute.get_iter(%arg2) : !memref_gmem_f32_4
    %lay = cute.get_layout(%arg0) : !memref_gmem_f32_4
    %lay_5 = cute.get_layout(%arg1) : !memref_gmem_f32_4
    %lay_6 = cute.get_layout(%arg2) : !memref_gmem_f32_4
    %shape = cute.make_shape() : () -> !cute.shape<"(4,32)">
    %int_tuple = cute.make_int_tuple() : () -> !cute.int_tuple<"(1,0)">
    %lay_7 = cute.make_ordered_layout(%shape, %int_tuple) : (!cute.shape<"(4,32)">, !cute.int_tuple<"(1,0)">) -> !cute.layout<"(4,32):(32,1)">
    %shape_8 = cute.make_shape() : () -> !cute.shape<"(4,4)">
    %int_tuple_9 = cute.make_int_tuple() : () -> !cute.int_tuple<"(1,0)">
    %lay_10 = cute.make_ordered_layout(%shape_8, %int_tuple_9) : (!cute.shape<"(4,4)">, !cute.int_tuple<"(1,0)">) -> !cute.layout<"(4,4):(4,1)">
    %prod = cute.raked_product(%lay_7, %lay_10) : (!cute.layout<"(4,32):(32,1)">, !cute.layout<"(4,4):(4,1)">) -> !cute.layout<"((4,4),(4,32)):((512,32),(128,1))">
    %sz = cute.size(%lay_7) : (!cute.layout<"(4,32):(32,1)">) -> !cute.int_tuple<"128">
    %e0 = cute.get_leaves(%sz) : !cute.int_tuple<"128">
    %sz_11 = cute.size(%lay_10) : (!cute.layout<"(4,4):(4,1)">) -> !cute.int_tuple<"16">
    %e0_12 = cute.get_leaves(%sz_11) : !cute.int_tuple<"16">
    %shape_13 = cute.make_shape() : () -> !cute.shape<"(128,16)">
    %lay_14 = cute.make_layout(%shape_13) : !cute.layout<"(128,16):(1,128)">
    %rinv = cute.right_inverse(%prod) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.layout<"(32,16,4):(64,4,1)">
    %0 = cute.composition(%rinv, %lay_14) : (!cute.layout<"(32,16,4):(64,4,1)">, !cute.layout<"(128,16):(1,128)">) -> !cute.layout<"((32,4),(4,4)):((64,4),(16,1))">
    %1 = cute.get_shape(%prod) : (!cute.layout<"((4,4),(4,32)):((512,32),(128,1))">) -> !cute.shape<"((4,4),(4,32))">
    %e0_15, %e1, %e2, %e3 = cute.get_leaves(%1) : !cute.shape<"((4,4),(4,32))">
    %int_tuple_16 = cute.make_int_tuple() : () -> !cute.int_tuple<"((4,4),(4,32))">
    %res = cute.tuple.product_each(%int_tuple_16) : (!cute.int_tuple<"((4,4),(4,32))">) -> !cute.int_tuple<"(16,128)">
    %e0_17, %e1_18 = cute.get_leaves(%res) : !cute.int_tuple<"(16,128)">
    %tile = cute.make_tile() : () -> !cute.tile<"[16:1;128:1]">
    %div = cute.zipped_divide(%arg0, %tile) : !memref_gmem_f32_4, !cute.tile<"[16:1;128:1]">
    %iter_19 = cute.get_iter(%div) : !memref_gmem_f32_
    %iter_20 = cute.get_iter(%div) : !memref_gmem_f32_
    %tile_21 = cute.make_tile() : () -> !cute.tile<"[16:1;128:1]">
    %div_22 = cute.zipped_divide(%arg1, %tile_21) : !memref_gmem_f32_4, !cute.tile<"[16:1;128:1]">
    %iter_23 = cute.get_iter(%div_22) : !memref_gmem_f32_
    %iter_24 = cute.get_iter(%div_22) : !memref_gmem_f32_
    %tile_25 = cute.make_tile() : () -> !cute.tile<"[16:1;128:1]">
    %div_26 = cute.zipped_divide(%arg2, %tile_25) : !memref_gmem_f32_4, !cute.tile<"[16:1;128:1]">
    %iter_27 = cute.get_iter(%div_26) : !memref_gmem_f32_
    %iter_28 = cute.get_iter(%div_26) : !memref_gmem_f32_
    %lay_29 = cute.get_layout(%arg2) : !memref_gmem_f32_4
    %2 = cute.get_shape(%lay_29) : (!cute.layout<"(?,?):(?{i64},1)">) -> !cute.shape<"(?,?)">
    %e0_30, %e1_31 = cute.get_leaves(%2) : !cute.shape<"(?,?)">
    %itup = cute.to_int_tuple(%e0_30) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %3 = cute.get_scalars(%itup) : !cute.int_tuple<"?">
    %itup_32 = cute.to_int_tuple(%e1_31) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %4 = cute.get_scalars(%itup_32) : !cute.int_tuple<"?">
    %shape_33 = cute.make_shape(%itup, %itup_32) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.shape<"(?,?)">
    %5 = cute.make_identity_tensor(%shape_33) : !cute.coord_tensor<"(0,0)", "(?,?):(1@0,1@1)">
    %iter_34 = cute.get_iter(%5) : !cute.coord_tensor<"(0,0)", "(?,?):(1@0,1@1)">
    %tup = cute.deref_arith_tuple_iter(%iter_34) : !cute.arith_tuple_iter<"(0,0)">
    %e0_35, %e1_36 = cute.get_leaves(%tup) : !cute.int_tuple<"(0,0)">
    %tile_37 = cute.make_tile() : () -> !cute.tile<"[16:1;128:1]">
    %div_38 = cute.zipped_divide(%5, %tile_37) : !cute.coord_tensor<"(0,0)", "(?,?):(1@0,1@1)">, !cute.tile<"[16:1;128:1]">
    %iter_39 = cute.get_iter(%div_38) : !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
    %tup_40 = cute.deref_arith_tuple_iter(%iter_39) : !cute.arith_tuple_iter<"(0,0)">
    %e0_41, %e1_42 = cute.get_leaves(%tup_40) : !cute.int_tuple<"(0,0)">
    %iter_43 = cute.get_iter(%div_38) : !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
    %tup_44 = cute.deref_arith_tuple_iter(%iter_43) : !cute.arith_tuple_iter<"(0,0)">
    %e0_45, %e1_46 = cute.get_leaves(%tup_44) : !cute.int_tuple<"(0,0)">
    %lay_47 = cute.get_layout(%arg2) : !memref_gmem_f32_4
    %6 = cute.get_shape(%lay_47) : (!cute.layout<"(?,?):(?{i64},1)">) -> !cute.shape<"(?,?)">
    %e0_48, %e1_49 = cute.get_leaves(%6) : !cute.shape<"(?,?)">
    %itup_50 = cute.to_int_tuple(%e0_48) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %7 = cute.get_scalars(%itup_50) : !cute.int_tuple<"?">
    %itup_51 = cute.to_int_tuple(%e1_49) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %8 = cute.get_scalars(%itup_51) : !cute.int_tuple<"?">
    %sz_52 = cute.size(%div_26) <{mode = [1]}> : (!memref_gmem_f32_) -> !cute.int_tuple<"?">
    %e0_53 = cute.get_leaves(%sz_52) : !cute.int_tuple<"?">
    %9 = cute.get_scalars(%e0_53) : !cute.int_tuple<"?">
    %sz_54 = cute.size(%0) <{mode = [0]}> : (!cute.layout<"((32,4),(4,4)):((64,4),(16,1))">) -> !cute.int_tuple<"128">
    %e0_55 = cute.get_leaves(%sz_54) : !cute.int_tuple<"128">
    %lay_56 = cute.get_layout(%div) : !memref_gmem_f32_
    %lay_57 = cute.get_layout(%div_22) : !memref_gmem_f32_
    %lay_58 = cute.get_layout(%div_26) : !memref_gmem_f32_
    %lay_59 = cute.get_layout(%div_38) : !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
    %c0_i32 = arith.constant 0 : i32
    %10 = arith.extsi %c0_i32 : i32 to i64
    %c128_i32 = arith.constant 128 : i32
    %c1_i32 = arith.constant 1 : i32
    %11 = cuda.launch_cfg.create<max_attrs = 3 : i32> (blockDim = (%c128_i32, %c1_i32, %c1_i32), dynamicSmemBytes = %10, gridDim = (%9, %c1_i32, %c1_i32), stream = %arg3) : i32, i32, i32, i64, i32, i32, i32, !cuda.stream -> !cuda.launch_cfg<max_attrs = 3>
    %c0_i32_60 = arith.constant 0 : i32
    cuda.launch_cfg.programmatic_stream_serialization_allowed[%11] %c0_i32_60 : !cuda.launch_cfg<max_attrs = 3>, i32
    %c0_i32_61 = arith.constant 0 : i32
    cuda.launch_cfg.cooperative[%11] %c0_i32_61 : !cuda.launch_cfg<max_attrs = 3>, i32
    %12 = cuda.launch_ex @kernels::@kernel_cutlass_elementwise_add_kernel_tensorptrf32gmemo16128i641i64div16128_tensorptrf32gmemo16128i641i64div16128_tensorptrf32gmemo16128i641i64div16128_tensor00o1612810111601281___False_0<%11> (%div, %div_22, %div_26, %div_38, %7, %8, %lay_7, %lay_10) {assume_kernel_attr = #cuda.assume_kernel_attr<true>} : !cuda.launch_cfg<max_attrs = 3>, (!memref_gmem_f32_, !memref_gmem_f32_, !memref_gmem_f32_, !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">, i32, i32, !cute.layout<"(4,32):(32,1)">, !cute.layout<"(4,4):(4,1)">) -> !cuda.result
    %13 = cuda.cast %12 : !cuda.result -> i32
    cuda.return_if_error %13 : i32
    %c0_i32_62 = arith.constant 0 : i32
    return %c0_i32_62 : i32
  }
}

