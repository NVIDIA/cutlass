!copy_simt = !cute.tiled_copy<!cute_nvgpu.atom.universal_copy<f32>, layout_copy_tv = <"((32,4),(4,4)):((64,4),(16,1))">, tiler_mn = <"[16:1;128:1]">>
!memref_gmem_f32_ = !cute.memref<f32, gmem, "((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
!memref_gmem_f32_1 = !cute.memref<f32, gmem, "(16,128):(?{i64},1)">
!memref_gmem_f32_2 = !cute.memref<f32, gmem, "((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
!memref_gmem_f32_3 = !cute.memref<f32, gmem, "((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
!memref_gmem_f32_4 = !cute.memref<f32, gmem, "((1,(4,4))):((0,(1,?{i64})))">
!memref_gmem_f32_5 = !cute.memref<f32, gmem, "(?,?):(?{i64},1)">
!memref_rmem_f32_ = !cute.memref<f32, rmem, align<32>, "((1,(4,4)),1,1):((0,(1,4)),0,0)">
!memref_rmem_f32_1 = !cute.memref<f32, rmem, align<32>, "((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
!memref_rmem_f32_2 = !cute.memref<f32, rmem, align<32>, "((1,(4,4))):((0,(1,4)))">
!memref_rmem_i8_ = !cute.memref<i8, rmem, align<32>, "((1,(4,4)),1,1):((0,(1,4)),0,0)">
!memref_rmem_i8_1 = !cute.memref<i8, rmem, align<32>, "((1,(4,4)),(1,1)):((0,(1,4)),(0,0))">
!memref_rmem_i8_2 = !cute.memref<i8, rmem, align<32>, "((1,(4,4))):((0,(1,4)))">
#loop_unroll = #llvm.loop_unroll<disable = false, full = true>
#loop_annotation = #llvm.loop_annotation<unroll = #loop_unroll>
module attributes {gpu.container_module} {
  gpu.module @kernels {
    cuda.kernel @kernel_cutlass_elementwise_add_kernel_tensorptrf32gmemo161281i64div16128_tensorptrf32gmemo161281i64div16128_tensorptrf32gmemo161281i64div16128_tensor00o1612810111601281___False_0(%arg0: !memref_gmem_f32_, %arg1: !memref_gmem_f32_, %arg2: !memref_gmem_f32_, %arg3: !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">, %arg4: i32, %arg5: i32) attributes {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} {
      %0 = cute.static : !cute.layout<"(4,32):(32,1)">
      %1 = cute.static : !cute.layout<"(4,4):(4,1)">
      %2 = nvvm.read.ptx.sreg.tid.x range <i32, 0, 1024> : i32
      %3 = nvvm.read.ptx.sreg.ctaid.x range <i32, 0, 2147483647> : i32
      %coord = cute.make_coord(%3) : (i32) -> !cute.coord<"((_,_),?)">
      %lay = cute.get_layout(%arg0) : !memref_gmem_f32_
      %4:4 = cute.get_scalars(%lay) <{only_dynamic}> : !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
      %5 = cute.static : !cute.shape<"(16,128)">
      %stride = cute.make_stride(%4#2) : (i64) -> !cute.stride<"(?{i64},1)">
      %lay_0 = cute.make_layout(%5, %stride) : !cute.layout<"(16,128):(?{i64},1)">
      %idx = cute.crd2idx(%coord, %lay) : (!cute.coord<"((_,_),?)">, !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.int_tuple<"?{i64 div=16}">
      %iter = cute.get_iter(%arg0) : !memref_gmem_f32_
      %ptr = cute.add_offset(%iter, %idx) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=16}">) -> !cute.ptr<f32, gmem>
      %view = cute.make_view(%ptr, %lay_0) : !memref_gmem_f32_1
      %coord_1 = cute.make_coord(%3) : (i32) -> !cute.coord<"((_,_),?)">
      %lay_2 = cute.get_layout(%arg1) : !memref_gmem_f32_
      %6:4 = cute.get_scalars(%lay_2) <{only_dynamic}> : !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
      %7 = cute.static : !cute.shape<"(16,128)">
      %stride_3 = cute.make_stride(%6#2) : (i64) -> !cute.stride<"(?{i64},1)">
      %lay_4 = cute.make_layout(%7, %stride_3) : !cute.layout<"(16,128):(?{i64},1)">
      %idx_5 = cute.crd2idx(%coord_1, %lay_2) : (!cute.coord<"((_,_),?)">, !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.int_tuple<"?{i64 div=16}">
      %iter_6 = cute.get_iter(%arg1) : !memref_gmem_f32_
      %ptr_7 = cute.add_offset(%iter_6, %idx_5) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=16}">) -> !cute.ptr<f32, gmem>
      %view_8 = cute.make_view(%ptr_7, %lay_4) : !memref_gmem_f32_1
      %coord_9 = cute.make_coord(%3) : (i32) -> !cute.coord<"((_,_),?)">
      %lay_10 = cute.get_layout(%arg2) : !memref_gmem_f32_
      %8:4 = cute.get_scalars(%lay_10) <{only_dynamic}> : !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
      %9 = cute.static : !cute.shape<"(16,128)">
      %stride_11 = cute.make_stride(%8#2) : (i64) -> !cute.stride<"(?{i64},1)">
      %lay_12 = cute.make_layout(%9, %stride_11) : !cute.layout<"(16,128):(?{i64},1)">
      %idx_13 = cute.crd2idx(%coord_9, %lay_10) : (!cute.coord<"((_,_),?)">, !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.int_tuple<"?{i64 div=16}">
      %iter_14 = cute.get_iter(%arg2) : !memref_gmem_f32_
      %ptr_15 = cute.add_offset(%iter_14, %idx_13) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=16}">) -> !cute.ptr<f32, gmem>
      %view_16 = cute.make_view(%ptr_15, %lay_12) : !memref_gmem_f32_1
      %coord_17 = cute.make_coord(%3) : (i32) -> !cute.coord<"((_,_),?)">
      %lay_18 = cute.get_layout(%arg3) : !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
      %idx_19 = cute.crd2idx(%coord_17, %lay_18) : (!cute.coord<"((_,_),?)">, !cute.layout<"((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">) -> !cute.int_tuple<"(?{div=16},?{div=128})">
      %10 = cute.static : !cute.int_tuple<"(0,0)">
      %tup = cute.add_offset(%10, %idx_19) : (!cute.int_tuple<"(0,0)">, !cute.int_tuple<"(?{div=16},?{div=128})">) -> !cute.int_tuple<"(?{div=16},?{div=128})">
      %view_20 = cute.make_view(%tup) : !cute.coord_tensor<"(?{div=16},?{div=128})", "(16,128):(1@0,1@1)">
      %atom = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<f32>
      %atom_21 = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<f32>
      %11 = cute.make_tiled_copy(%atom) : !copy_simt
      %12 = cute.make_tiled_copy(%atom) : !copy_simt
      %13 = cute.make_tiled_copy(%atom_21) : !copy_simt
      %coord_22 = cute.make_coord(%2) : (i32) -> !cute.coord<"?">
      %iter_23 = cute.get_iter(%view) : !memref_gmem_f32_1
      %lay_24 = cute.get_layout(%view) : !memref_gmem_f32_1
      %14 = cute.get_scalars(%lay_24) <{only_dynamic}> : !cute.layout<"(16,128):(?{i64},1)">
      %15 = cute.get_scalars(%coord_22) <{only_dynamic}> : !cute.coord<"?">
      %c4_i64 = arith.constant 4 : i64
      %16 = arith.muli %14, %c4_i64 : i64
      %c32_i32 = arith.constant 32 : i32
      %17 = arith.divsi %15, %c32_i32 : i32
      %c32_i32_25 = arith.constant 32 : i32
      %18 = arith.remsi %15, %c32_i32_25 : i32
      %c4_i32 = arith.constant 4 : i32
      %19 = arith.muli %18, %c4_i32 : i32
      %20 = arith.extsi %17 : i32 to i64
      %21 = arith.muli %20, %16 : i64
      %22 = arith.extsi %19 : i32 to i64
      %23 = arith.addi %22, %21 : i64
      %iv = cute.assume(%23) : (i64) -> !cute.i64<divby 4>
      %int_tuple = cute.make_int_tuple(%iv) : (!cute.i64<divby 4>) -> !cute.int_tuple<"?{i64 div=4}">
      %ptr_26 = cute.add_offset(%iter_23, %int_tuple) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=4}">) -> !cute.ptr<f32, gmem>
      %24 = cute.static : !cute.shape<"((1,(4,4)),1,1)">
      %stride_27 = cute.make_stride(%14) : (i64) -> !cute.stride<"((0,(1,?{i64})),0,0)">
      %lay_28 = cute.make_layout(%24, %stride_27) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %view_29 = cute.make_view(%ptr_26, %lay_28) : !memref_gmem_f32_2
      %iter_30 = cute.get_iter(%view_29) : !memref_gmem_f32_2
      %coord_31 = cute.make_coord(%2) : (i32) -> !cute.coord<"?">
      %iter_32 = cute.get_iter(%view_8) : !memref_gmem_f32_1
      %lay_33 = cute.get_layout(%view_8) : !memref_gmem_f32_1
      %25 = cute.get_scalars(%lay_33) <{only_dynamic}> : !cute.layout<"(16,128):(?{i64},1)">
      %26 = cute.get_scalars(%coord_31) <{only_dynamic}> : !cute.coord<"?">
      %c4_i64_34 = arith.constant 4 : i64
      %27 = arith.muli %25, %c4_i64_34 : i64
      %c32_i32_35 = arith.constant 32 : i32
      %28 = arith.divsi %26, %c32_i32_35 : i32
      %c32_i32_36 = arith.constant 32 : i32
      %29 = arith.remsi %26, %c32_i32_36 : i32
      %c4_i32_37 = arith.constant 4 : i32
      %30 = arith.muli %29, %c4_i32_37 : i32
      %31 = arith.extsi %28 : i32 to i64
      %32 = arith.muli %31, %27 : i64
      %33 = arith.extsi %30 : i32 to i64
      %34 = arith.addi %33, %32 : i64
      %iv_38 = cute.assume(%34) : (i64) -> !cute.i64<divby 4>
      %int_tuple_39 = cute.make_int_tuple(%iv_38) : (!cute.i64<divby 4>) -> !cute.int_tuple<"?{i64 div=4}">
      %ptr_40 = cute.add_offset(%iter_32, %int_tuple_39) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=4}">) -> !cute.ptr<f32, gmem>
      %35 = cute.static : !cute.shape<"((1,(4,4)),1,1)">
      %stride_41 = cute.make_stride(%25) : (i64) -> !cute.stride<"((0,(1,?{i64})),0,0)">
      %lay_42 = cute.make_layout(%35, %stride_41) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %view_43 = cute.make_view(%ptr_40, %lay_42) : !memref_gmem_f32_2
      %iter_44 = cute.get_iter(%view_43) : !memref_gmem_f32_2
      %coord_45 = cute.make_coord(%2) : (i32) -> !cute.coord<"?">
      %iter_46 = cute.get_iter(%view_16) : !memref_gmem_f32_1
      %lay_47 = cute.get_layout(%view_16) : !memref_gmem_f32_1
      %36 = cute.get_scalars(%lay_47) <{only_dynamic}> : !cute.layout<"(16,128):(?{i64},1)">
      %37 = cute.get_scalars(%coord_45) <{only_dynamic}> : !cute.coord<"?">
      %c4_i64_48 = arith.constant 4 : i64
      %38 = arith.muli %36, %c4_i64_48 : i64
      %c32_i32_49 = arith.constant 32 : i32
      %39 = arith.divsi %37, %c32_i32_49 : i32
      %c32_i32_50 = arith.constant 32 : i32
      %40 = arith.remsi %37, %c32_i32_50 : i32
      %c4_i32_51 = arith.constant 4 : i32
      %41 = arith.muli %40, %c4_i32_51 : i32
      %42 = arith.extsi %39 : i32 to i64
      %43 = arith.muli %42, %38 : i64
      %44 = arith.extsi %41 : i32 to i64
      %45 = arith.addi %44, %43 : i64
      %iv_52 = cute.assume(%45) : (i64) -> !cute.i64<divby 4>
      %int_tuple_53 = cute.make_int_tuple(%iv_52) : (!cute.i64<divby 4>) -> !cute.int_tuple<"?{i64 div=4}">
      %ptr_54 = cute.add_offset(%iter_46, %int_tuple_53) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=4}">) -> !cute.ptr<f32, gmem>
      %46 = cute.static : !cute.shape<"((1,(4,4)),1,1)">
      %stride_55 = cute.make_stride(%36) : (i64) -> !cute.stride<"((0,(1,?{i64})),0,0)">
      %lay_56 = cute.make_layout(%46, %stride_55) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %view_57 = cute.make_view(%ptr_54, %lay_56) : !memref_gmem_f32_2
      %iter_58 = cute.get_iter(%view_57) : !memref_gmem_f32_2
      %47 = cute.static : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %rmem = cute.memref.alloca(%47) : !memref_rmem_f32_
      %iter_59 = cute.get_iter(%rmem) : !memref_rmem_f32_
      %48 = cute.static : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %rmem_60 = cute.memref.alloca(%48) : !memref_rmem_f32_
      %iter_61 = cute.get_iter(%rmem_60) : !memref_rmem_f32_
      %49 = cute.static : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %rmem_62 = cute.memref.alloca(%49) : !memref_rmem_f32_
      %coord_63 = cute.make_coord(%2) : (i32) -> !cute.coord<"?">
      %iter_64 = cute.get_iter(%view_20) : !cute.coord_tensor<"(?{div=16},?{div=128})", "(16,128):(1@0,1@1)">
      %50 = cute.get_scalars(%coord_63) <{only_dynamic}> : !cute.coord<"?">
      %c32_i32_65 = arith.constant 32 : i32
      %51 = arith.divsi %50, %c32_i32_65 : i32
      %c32_i32_66 = arith.constant 32 : i32
      %52 = arith.remsi %50, %c32_i32_66 : i32
      %c4_i32_67 = arith.constant 4 : i32
      %53 = arith.muli %52, %c4_i32_67 : i32
      %c4_i32_68 = arith.constant 4 : i32
      %54 = arith.muli %51, %c4_i32_68 : i32
      %iv_69 = cute.assume(%54) : (i32) -> !cute.i32<divby 4>
      %iv_70 = cute.assume(%53) : (i32) -> !cute.i32<divby 4>
      %int_tuple_71 = cute.make_int_tuple(%iv_69, %iv_70) : (!cute.i32<divby 4>, !cute.i32<divby 4>) -> !cute.int_tuple<"(?{div=4},?{div=4})">
      %tup_72 = cute.add_offset(%iter_64, %int_tuple_71) : (!cute.int_tuple<"(?{div=16},?{div=128})">, !cute.int_tuple<"(?{div=4},?{div=4})">) -> !cute.int_tuple<"(?{div=4},?{div=4})">
      %view_73 = cute.make_view(%tup_72) : !cute.coord_tensor<"(?{div=4},?{div=4})", "((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">
      %55 = cute.static : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %rmem_74 = cute.memref.alloca(%55) : !memref_rmem_i8_
      %c0_i32 = arith.constant 0 : i32
      %c16_i32 = arith.constant 16 : i32
      %c1_i32 = arith.constant 1 : i32
      %56 = scf.for %arg6 = %c0_i32 to %c16_i32 step %c1_i32 iter_args(%arg7 = %rmem_74) -> (!memref_rmem_i8_)  : i32 {
        %coord_99 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"?">
        %68 = cute.static : !cute.layout<"((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">
        %idx_100 = cute.crd2idx(%coord_99, %68) : (!cute.coord<"?">, !cute.layout<"((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">) -> !cute.int_tuple<"(?,?)">
        %iter_101 = cute.get_iter(%view_73) : !cute.coord_tensor<"(?{div=4},?{div=4})", "((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">
        %tup_102 = cute.add_offset(%iter_101, %idx_100) : (!cute.int_tuple<"(?{div=4},?{div=4})">, !cute.int_tuple<"(?,?)">) -> !cute.int_tuple<"(?,?)">
        %view_103 = cute.make_view(%tup_102) : !cute.coord_tensor<"(?,?)", "():()">
        %iter_104 = cute.get_iter(%view_103) : !cute.coord_tensor<"(?,?)", "():()">
        %e0, %e1 = cute.get_leaves(%iter_104) : !cute.int_tuple<"(?,?)">
        %coord_105 = cute.make_coord(%e0, %e1) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
        %coord_106 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
        %69:2 = cute.get_scalars(%coord_105) : !cute.coord<"(?,?)">
        %70:2 = cute.get_scalars(%coord_106) : !cute.coord<"(?,?)">
        %true = arith.constant true
        %71 = arith.cmpi slt, %69#0, %70#0 : i32
        %72 = arith.andi %true, %71 : i1
        %73 = arith.cmpi slt, %69#1, %70#1 : i32
        %74 = arith.andi %72, %73 : i1
        %75 = arith.extui %74 : i1 to i8
        %coord_107 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"?">
        cute.memref.store(%arg7, %coord_107, %75) : (!memref_rmem_i8_, !cute.coord<"?">, i8) -> ()
        scf.yield %arg7 : !memref_rmem_i8_
      }
      %iter_75 = cute.get_iter(%56) : !memref_rmem_i8_
      %false = arith.constant false
      scf.if %false {
        %c0_i32_99 = arith.constant 0 : i32
        %c10_i32_100 = arith.constant 10 : i32
        %c1_i32_101 = arith.constant 1 : i32
        scf.for %arg6 = %c0_i32_99 to %c10_i32_100 step %c1_i32_101  : i32 {
          %lay_102 = cute.get_layout(%view_29) : !memref_gmem_f32_2
          %68 = cute.static : !cute.layout<"1:0">
          %append_103 = cute.append_to_rank<2> (%lay_102, %68) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">
          %view_104 = cute.make_view(%iter_30, %append_103) : !memref_gmem_f32_2
          %iter_105 = cute.get_iter(%view_104) : !memref_gmem_f32_2
          %lay_106 = cute.get_layout(%view_104) : !memref_gmem_f32_2
          %69 = cute.get_scalars(%lay_106) <{only_dynamic}> : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
          %70 = cute.static : !cute.shape<"((1,(4,4)),(1,1))">
          %stride_107 = cute.make_stride(%69) : (i64) -> !cute.stride<"((0,(1,?{i64})),(0,0))">
          %lay_108 = cute.make_layout(%70, %stride_107) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
          %view_109 = cute.make_view(%iter_105, %lay_108) : !memref_gmem_f32_3
          %71 = cute.static : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %view_110 = cute.make_view(%iter_59, %71) : !memref_rmem_f32_
          %iter_111 = cute.get_iter(%view_110) : !memref_rmem_f32_
          %view_112 = cute.make_view(%iter_111) : !memref_rmem_f32_1
          %72 = cute.static : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %view_113 = cute.make_view(%iter_75, %72) : !memref_rmem_i8_
          %iter_114 = cute.get_iter(%view_113) : !memref_rmem_i8_
          %view_115 = cute.make_view(%iter_114) : !memref_rmem_i8_1
          %73 = cute.static : !cute.layout<"1:0">
          %iter_116 = cute.get_iter(%view_109) : !memref_gmem_f32_3
          %iter_117 = cute.get_iter(%view_112) : !memref_rmem_f32_1
          %lay_118 = cute.get_layout(%view_109) : !memref_gmem_f32_3
          %append_119 = cute.append_to_rank<2> (%lay_118, %73) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">, !cute.layout<"1:0">
          %74 = cute.get_scalars(%append_119) <{only_dynamic}> : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
          %75 = cute.static : !cute.shape<"((1,(4,4)),((1,1)))">
          %stride_120 = cute.make_stride(%74) : (i64) -> !cute.stride<"((0,(1,?{i64})),((0,0)))">
          %lay_121 = cute.make_layout(%75, %stride_120) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
          %iter_122 = cute.get_iter(%view_115) : !memref_rmem_i8_1
          %76 = cute.static : !cute.int_tuple<"1">
          %77 = cute.get_scalars(%76) : !cute.int_tuple<"1">
          %c0_i32_123 = arith.constant 0 : i32
          %c1_i32_124 = arith.constant 1 : i32
          scf.for %arg7 = %c0_i32_123 to %77 step %c1_i32_124  : i32 {
            %88 = cute.get_scalars(%lay_121) <{only_dynamic}> : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
            %89 = cute.static : !cute.shape<"((1,(4,4)))">
            %stride_148 = cute.make_stride(%88) : (i64) -> !cute.stride<"((0,(1,?{i64})))">
            %lay_149 = cute.make_layout(%89, %stride_148) : !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
            %90 = cute.static : !cute.int_tuple<"0">
            %ptr_150 = cute.add_offset(%iter_116, %90) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<f32, gmem>
            %view_151 = cute.make_view(%ptr_150, %lay_149) : !memref_gmem_f32_4
            %91 = cute.static : !cute.layout<"((1,(4,4))):((0,(1,4)))">
            %92 = cute.static : !cute.int_tuple<"0">
            %ptr_152 = cute.add_offset(%iter_117, %92) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, rmem, align<32>>
            %view_153 = cute.make_view(%ptr_152, %91) : !memref_rmem_f32_2
            %93 = cute.static : !cute.layout<"((1,(4,4))):((0,(1,4)))">
            %94 = cute.static : !cute.int_tuple<"0">
            %ptr_154 = cute.add_offset(%iter_122, %94) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
            %view_155 = cute.make_view(%ptr_154, %93) : !memref_rmem_i8_2
            %iter_156 = cute.get_iter(%view_151) : !memref_gmem_f32_4
            %lay_157 = cute.get_layout(%view_151) : !memref_gmem_f32_4
            %95 = cute.get_scalars(%lay_157) <{only_dynamic}> : !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
            %iter_158 = cute.get_iter(%view_153) : !memref_rmem_f32_2
            %iter_159 = cute.get_iter(%view_155) : !memref_rmem_i8_2
            %96 = builtin.unrealized_conversion_cast %iter_159 : !cute.ptr<i8, rmem, align<32>> to !llvm.ptr
            %97 = llvm.load %96 : !llvm.ptr -> i8
            %98 = llvm.mlir.constant(0 : i8) : i8
            %99 = llvm.icmp "ne" %97, %98 : i8
            scf.if %99 {
              %175 = builtin.unrealized_conversion_cast %iter_156 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %176 = builtin.unrealized_conversion_cast %iter_158 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
              %177 = llvm.load %175 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %177, %176 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %100 = cute.static : !cute.int_tuple<"1">
            %ptr_160 = cute.add_offset(%iter_159, %100) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
            %101 = builtin.unrealized_conversion_cast %ptr_160 : !cute.ptr<i8, rmem> to !llvm.ptr
            %102 = llvm.load %101 : !llvm.ptr -> i8
            %103 = llvm.mlir.constant(0 : i8) : i8
            %104 = llvm.icmp "ne" %102, %103 : i8
            scf.if %104 {
              %175 = cute.static : !cute.int_tuple<"1">
              %ptr_175 = cute.add_offset(%iter_156, %175) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
              %176 = cute.static : !cute.int_tuple<"1">
              %ptr_176 = cute.add_offset(%iter_158, %176) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
              %177 = builtin.unrealized_conversion_cast %ptr_175 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %178 = builtin.unrealized_conversion_cast %ptr_176 : !cute.ptr<f32, rmem> to !llvm.ptr
              %179 = llvm.load %177 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %179, %178 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %105 = cute.static : !cute.int_tuple<"2">
            %ptr_161 = cute.add_offset(%iter_159, %105) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem, align<2>>
            %106 = builtin.unrealized_conversion_cast %ptr_161 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
            %107 = llvm.load %106 : !llvm.ptr -> i8
            %108 = llvm.mlir.constant(0 : i8) : i8
            %109 = llvm.icmp "ne" %107, %108 : i8
            scf.if %109 {
              %175 = cute.static : !cute.int_tuple<"2">
              %ptr_175 = cute.add_offset(%iter_156, %175) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
              %176 = cute.static : !cute.int_tuple<"2">
              %ptr_176 = cute.add_offset(%iter_158, %176) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
              %177 = builtin.unrealized_conversion_cast %ptr_175 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %178 = builtin.unrealized_conversion_cast %ptr_176 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
              %179 = llvm.load %177 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %179, %178 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %110 = cute.static : !cute.int_tuple<"3">
            %ptr_162 = cute.add_offset(%iter_159, %110) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
            %111 = builtin.unrealized_conversion_cast %ptr_162 : !cute.ptr<i8, rmem> to !llvm.ptr
            %112 = llvm.load %111 : !llvm.ptr -> i8
            %113 = llvm.mlir.constant(0 : i8) : i8
            %114 = llvm.icmp "ne" %112, %113 : i8
            scf.if %114 {
              %175 = cute.static : !cute.int_tuple<"3">
              %ptr_175 = cute.add_offset(%iter_156, %175) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
              %176 = cute.static : !cute.int_tuple<"3">
              %ptr_176 = cute.add_offset(%iter_158, %176) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
              %177 = builtin.unrealized_conversion_cast %ptr_175 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %178 = builtin.unrealized_conversion_cast %ptr_176 : !cute.ptr<f32, rmem> to !llvm.ptr
              %179 = llvm.load %177 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %179, %178 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %115 = cute.static : !cute.int_tuple<"4">
            %ptr_163 = cute.add_offset(%iter_159, %115) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem, align<4>>
            %116 = builtin.unrealized_conversion_cast %ptr_163 : !cute.ptr<i8, rmem, align<4>> to !llvm.ptr
            %117 = llvm.load %116 : !llvm.ptr -> i8
            %118 = llvm.mlir.constant(0 : i8) : i8
            %119 = llvm.icmp "ne" %117, %118 : i8
            scf.if %119 {
              %int_tuple_175 = cute.make_int_tuple(%95) : (i64) -> !cute.int_tuple<"?{i64}">
              %ptr_176 = cute.add_offset(%iter_156, %int_tuple_175) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
              %175 = cute.static : !cute.int_tuple<"4">
              %ptr_177 = cute.add_offset(%iter_158, %175) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
              %176 = builtin.unrealized_conversion_cast %ptr_176 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %177 = builtin.unrealized_conversion_cast %ptr_177 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              %178 = llvm.load %176 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %178, %177 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %120 = cute.static : !cute.int_tuple<"5">
            %ptr_164 = cute.add_offset(%iter_159, %120) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
            %121 = builtin.unrealized_conversion_cast %ptr_164 : !cute.ptr<i8, rmem> to !llvm.ptr
            %122 = llvm.load %121 : !llvm.ptr -> i8
            %123 = llvm.mlir.constant(0 : i8) : i8
            %124 = llvm.icmp "ne" %122, %123 : i8
            scf.if %124 {
              %c1_i64 = arith.constant 1 : i64
              %175 = arith.addi %95, %c1_i64 : i64
              %int_tuple_175 = cute.make_int_tuple(%175) : (i64) -> !cute.int_tuple<"?{i64}">
              %ptr_176 = cute.add_offset(%iter_156, %int_tuple_175) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
              %176 = cute.static : !cute.int_tuple<"5">
              %ptr_177 = cute.add_offset(%iter_158, %176) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<f32, rmem>
              %177 = builtin.unrealized_conversion_cast %ptr_176 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %178 = builtin.unrealized_conversion_cast %ptr_177 : !cute.ptr<f32, rmem> to !llvm.ptr
              %179 = llvm.load %177 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %179, %178 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %125 = cute.static : !cute.int_tuple<"6">
            %ptr_165 = cute.add_offset(%iter_159, %125) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem, align<2>>
            %126 = builtin.unrealized_conversion_cast %ptr_165 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
            %127 = llvm.load %126 : !llvm.ptr -> i8
            %128 = llvm.mlir.constant(0 : i8) : i8
            %129 = llvm.icmp "ne" %127, %128 : i8
            scf.if %129 {
              %c2_i64 = arith.constant 2 : i64
              %175 = arith.addi %95, %c2_i64 : i64
              %int_tuple_175 = cute.make_int_tuple(%175) : (i64) -> !cute.int_tuple<"?{i64}">
              %ptr_176 = cute.add_offset(%iter_156, %int_tuple_175) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
              %176 = cute.static : !cute.int_tuple<"6">
              %ptr_177 = cute.add_offset(%iter_158, %176) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
              %177 = builtin.unrealized_conversion_cast %ptr_176 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %178 = builtin.unrealized_conversion_cast %ptr_177 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
              %179 = llvm.load %177 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %179, %178 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %130 = cute.static : !cute.int_tuple<"7">
            %ptr_166 = cute.add_offset(%iter_159, %130) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
            %131 = builtin.unrealized_conversion_cast %ptr_166 : !cute.ptr<i8, rmem> to !llvm.ptr
            %132 = llvm.load %131 : !llvm.ptr -> i8
            %133 = llvm.mlir.constant(0 : i8) : i8
            %134 = llvm.icmp "ne" %132, %133 : i8
            scf.if %134 {
              %c3_i64 = arith.constant 3 : i64
              %175 = arith.addi %95, %c3_i64 : i64
              %int_tuple_175 = cute.make_int_tuple(%175) : (i64) -> !cute.int_tuple<"?{i64}">
              %ptr_176 = cute.add_offset(%iter_156, %int_tuple_175) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
              %176 = cute.static : !cute.int_tuple<"7">
              %ptr_177 = cute.add_offset(%iter_158, %176) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<f32, rmem>
              %177 = builtin.unrealized_conversion_cast %ptr_176 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %178 = builtin.unrealized_conversion_cast %ptr_177 : !cute.ptr<f32, rmem> to !llvm.ptr
              %179 = llvm.load %177 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %179, %178 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %135 = cute.static : !cute.int_tuple<"8">
            %ptr_167 = cute.add_offset(%iter_159, %135) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<i8, rmem, align<8>>
            %136 = builtin.unrealized_conversion_cast %ptr_167 : !cute.ptr<i8, rmem, align<8>> to !llvm.ptr
            %137 = llvm.load %136 : !llvm.ptr -> i8
            %138 = llvm.mlir.constant(0 : i8) : i8
            %139 = llvm.icmp "ne" %137, %138 : i8
            scf.if %139 {
              %c2_i64 = arith.constant 2 : i64
              %175 = arith.muli %95, %c2_i64 : i64
              %iv_175 = cute.assume(%175) : (i64) -> !cute.i64<divby 2>
              %int_tuple_176 = cute.make_int_tuple(%iv_175) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
              %ptr_177 = cute.add_offset(%iter_156, %int_tuple_176) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
              %176 = cute.static : !cute.int_tuple<"8">
              %ptr_178 = cute.add_offset(%iter_158, %176) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<f32, rmem, align<32>>
              %177 = builtin.unrealized_conversion_cast %ptr_177 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %178 = builtin.unrealized_conversion_cast %ptr_178 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
              %179 = llvm.load %177 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %179, %178 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %140 = cute.static : !cute.int_tuple<"9">
            %ptr_168 = cute.add_offset(%iter_159, %140) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<i8, rmem>
            %141 = builtin.unrealized_conversion_cast %ptr_168 : !cute.ptr<i8, rmem> to !llvm.ptr
            %142 = llvm.load %141 : !llvm.ptr -> i8
            %143 = llvm.mlir.constant(0 : i8) : i8
            %144 = llvm.icmp "ne" %142, %143 : i8
            scf.if %144 {
              %c2_i64 = arith.constant 2 : i64
              %175 = arith.muli %95, %c2_i64 : i64
              %c1_i64 = arith.constant 1 : i64
              %176 = arith.addi %175, %c1_i64 : i64
              %int_tuple_175 = cute.make_int_tuple(%176) : (i64) -> !cute.int_tuple<"?{i64}">
              %ptr_176 = cute.add_offset(%iter_156, %int_tuple_175) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
              %177 = cute.static : !cute.int_tuple<"9">
              %ptr_177 = cute.add_offset(%iter_158, %177) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<f32, rmem>
              %178 = builtin.unrealized_conversion_cast %ptr_176 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %179 = builtin.unrealized_conversion_cast %ptr_177 : !cute.ptr<f32, rmem> to !llvm.ptr
              %180 = llvm.load %178 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %180, %179 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %145 = cute.static : !cute.int_tuple<"10">
            %ptr_169 = cute.add_offset(%iter_159, %145) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<i8, rmem, align<2>>
            %146 = builtin.unrealized_conversion_cast %ptr_169 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
            %147 = llvm.load %146 : !llvm.ptr -> i8
            %148 = llvm.mlir.constant(0 : i8) : i8
            %149 = llvm.icmp "ne" %147, %148 : i8
            scf.if %149 {
              %c2_i64 = arith.constant 2 : i64
              %175 = arith.muli %95, %c2_i64 : i64
              %c2_i64_175 = arith.constant 2 : i64
              %176 = arith.addi %175, %c2_i64_175 : i64
              %iv_176 = cute.assume(%176) : (i64) -> !cute.i64<divby 2>
              %int_tuple_177 = cute.make_int_tuple(%iv_176) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
              %ptr_178 = cute.add_offset(%iter_156, %int_tuple_177) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
              %177 = cute.static : !cute.int_tuple<"10">
              %ptr_179 = cute.add_offset(%iter_158, %177) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<f32, rmem, align<8>>
              %178 = builtin.unrealized_conversion_cast %ptr_178 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %179 = builtin.unrealized_conversion_cast %ptr_179 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
              %180 = llvm.load %178 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %180, %179 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %150 = cute.static : !cute.int_tuple<"11">
            %ptr_170 = cute.add_offset(%iter_159, %150) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<i8, rmem>
            %151 = builtin.unrealized_conversion_cast %ptr_170 : !cute.ptr<i8, rmem> to !llvm.ptr
            %152 = llvm.load %151 : !llvm.ptr -> i8
            %153 = llvm.mlir.constant(0 : i8) : i8
            %154 = llvm.icmp "ne" %152, %153 : i8
            scf.if %154 {
              %c2_i64 = arith.constant 2 : i64
              %175 = arith.muli %95, %c2_i64 : i64
              %c3_i64 = arith.constant 3 : i64
              %176 = arith.addi %175, %c3_i64 : i64
              %int_tuple_175 = cute.make_int_tuple(%176) : (i64) -> !cute.int_tuple<"?{i64}">
              %ptr_176 = cute.add_offset(%iter_156, %int_tuple_175) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
              %177 = cute.static : !cute.int_tuple<"11">
              %ptr_177 = cute.add_offset(%iter_158, %177) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<f32, rmem>
              %178 = builtin.unrealized_conversion_cast %ptr_176 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %179 = builtin.unrealized_conversion_cast %ptr_177 : !cute.ptr<f32, rmem> to !llvm.ptr
              %180 = llvm.load %178 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %180, %179 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %155 = cute.static : !cute.int_tuple<"12">
            %ptr_171 = cute.add_offset(%iter_159, %155) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<i8, rmem, align<4>>
            %156 = builtin.unrealized_conversion_cast %ptr_171 : !cute.ptr<i8, rmem, align<4>> to !llvm.ptr
            %157 = llvm.load %156 : !llvm.ptr -> i8
            %158 = llvm.mlir.constant(0 : i8) : i8
            %159 = llvm.icmp "ne" %157, %158 : i8
            scf.if %159 {
              %c3_i64 = arith.constant 3 : i64
              %175 = arith.muli %95, %c3_i64 : i64
              %iv_175 = cute.assume(%175) : (i64) -> !cute.i64<divby 3>
              %int_tuple_176 = cute.make_int_tuple(%iv_175) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
              %ptr_177 = cute.add_offset(%iter_156, %int_tuple_176) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
              %176 = cute.static : !cute.int_tuple<"12">
              %ptr_178 = cute.add_offset(%iter_158, %176) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<f32, rmem, align<16>>
              %177 = builtin.unrealized_conversion_cast %ptr_177 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %178 = builtin.unrealized_conversion_cast %ptr_178 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              %179 = llvm.load %177 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %179, %178 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %160 = cute.static : !cute.int_tuple<"13">
            %ptr_172 = cute.add_offset(%iter_159, %160) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<i8, rmem>
            %161 = builtin.unrealized_conversion_cast %ptr_172 : !cute.ptr<i8, rmem> to !llvm.ptr
            %162 = llvm.load %161 : !llvm.ptr -> i8
            %163 = llvm.mlir.constant(0 : i8) : i8
            %164 = llvm.icmp "ne" %162, %163 : i8
            scf.if %164 {
              %c3_i64 = arith.constant 3 : i64
              %175 = arith.muli %95, %c3_i64 : i64
              %c1_i64 = arith.constant 1 : i64
              %176 = arith.addi %175, %c1_i64 : i64
              %int_tuple_175 = cute.make_int_tuple(%176) : (i64) -> !cute.int_tuple<"?{i64}">
              %ptr_176 = cute.add_offset(%iter_156, %int_tuple_175) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
              %177 = cute.static : !cute.int_tuple<"13">
              %ptr_177 = cute.add_offset(%iter_158, %177) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<f32, rmem>
              %178 = builtin.unrealized_conversion_cast %ptr_176 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %179 = builtin.unrealized_conversion_cast %ptr_177 : !cute.ptr<f32, rmem> to !llvm.ptr
              %180 = llvm.load %178 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %180, %179 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %165 = cute.static : !cute.int_tuple<"14">
            %ptr_173 = cute.add_offset(%iter_159, %165) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<i8, rmem, align<2>>
            %166 = builtin.unrealized_conversion_cast %ptr_173 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
            %167 = llvm.load %166 : !llvm.ptr -> i8
            %168 = llvm.mlir.constant(0 : i8) : i8
            %169 = llvm.icmp "ne" %167, %168 : i8
            scf.if %169 {
              %c3_i64 = arith.constant 3 : i64
              %175 = arith.muli %95, %c3_i64 : i64
              %c2_i64 = arith.constant 2 : i64
              %176 = arith.addi %175, %c2_i64 : i64
              %int_tuple_175 = cute.make_int_tuple(%176) : (i64) -> !cute.int_tuple<"?{i64}">
              %ptr_176 = cute.add_offset(%iter_156, %int_tuple_175) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
              %177 = cute.static : !cute.int_tuple<"14">
              %ptr_177 = cute.add_offset(%iter_158, %177) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<f32, rmem, align<8>>
              %178 = builtin.unrealized_conversion_cast %ptr_176 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %179 = builtin.unrealized_conversion_cast %ptr_177 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
              %180 = llvm.load %178 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %180, %179 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %170 = cute.static : !cute.int_tuple<"15">
            %ptr_174 = cute.add_offset(%iter_159, %170) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<i8, rmem>
            %171 = builtin.unrealized_conversion_cast %ptr_174 : !cute.ptr<i8, rmem> to !llvm.ptr
            %172 = llvm.load %171 : !llvm.ptr -> i8
            %173 = llvm.mlir.constant(0 : i8) : i8
            %174 = llvm.icmp "ne" %172, %173 : i8
            scf.if %174 {
              %c3_i64 = arith.constant 3 : i64
              %175 = arith.muli %95, %c3_i64 : i64
              %c3_i64_175 = arith.constant 3 : i64
              %176 = arith.addi %175, %c3_i64_175 : i64
              %iv_176 = cute.assume(%176) : (i64) -> !cute.i64<divby 3>
              %int_tuple_177 = cute.make_int_tuple(%iv_176) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
              %ptr_178 = cute.add_offset(%iter_156, %int_tuple_177) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
              %177 = cute.static : !cute.int_tuple<"15">
              %ptr_179 = cute.add_offset(%iter_158, %177) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<f32, rmem>
              %178 = builtin.unrealized_conversion_cast %ptr_178 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %179 = builtin.unrealized_conversion_cast %ptr_179 : !cute.ptr<f32, rmem> to !llvm.ptr
              %180 = llvm.load %178 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %180, %179 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
          } {llvm.loop_annotation = #loop_annotation}
          %lay_125 = cute.get_layout(%view_43) : !memref_gmem_f32_2
          %78 = cute.static : !cute.layout<"1:0">
          %append_126 = cute.append_to_rank<2> (%lay_125, %78) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">
          %view_127 = cute.make_view(%iter_44, %append_126) : !memref_gmem_f32_2
          %iter_128 = cute.get_iter(%view_127) : !memref_gmem_f32_2
          %lay_129 = cute.get_layout(%view_127) : !memref_gmem_f32_2
          %79 = cute.get_scalars(%lay_129) <{only_dynamic}> : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
          %80 = cute.static : !cute.shape<"((1,(4,4)),(1,1))">
          %stride_130 = cute.make_stride(%79) : (i64) -> !cute.stride<"((0,(1,?{i64})),(0,0))">
          %lay_131 = cute.make_layout(%80, %stride_130) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
          %view_132 = cute.make_view(%iter_128, %lay_131) : !memref_gmem_f32_3
          %81 = cute.static : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %view_133 = cute.make_view(%iter_61, %81) : !memref_rmem_f32_
          %iter_134 = cute.get_iter(%view_133) : !memref_rmem_f32_
          %view_135 = cute.make_view(%iter_134) : !memref_rmem_f32_1
          %82 = cute.static : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %view_136 = cute.make_view(%iter_75, %82) : !memref_rmem_i8_
          %iter_137 = cute.get_iter(%view_136) : !memref_rmem_i8_
          %view_138 = cute.make_view(%iter_137) : !memref_rmem_i8_1
          %83 = cute.static : !cute.layout<"1:0">
          %iter_139 = cute.get_iter(%view_132) : !memref_gmem_f32_3
          %iter_140 = cute.get_iter(%view_135) : !memref_rmem_f32_1
          %lay_141 = cute.get_layout(%view_132) : !memref_gmem_f32_3
          %append_142 = cute.append_to_rank<2> (%lay_141, %83) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">, !cute.layout<"1:0">
          %84 = cute.get_scalars(%append_142) <{only_dynamic}> : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
          %85 = cute.static : !cute.shape<"((1,(4,4)),((1,1)))">
          %stride_143 = cute.make_stride(%84) : (i64) -> !cute.stride<"((0,(1,?{i64})),((0,0)))">
          %lay_144 = cute.make_layout(%85, %stride_143) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
          %iter_145 = cute.get_iter(%view_138) : !memref_rmem_i8_1
          %86 = cute.static : !cute.int_tuple<"1">
          %87 = cute.get_scalars(%86) : !cute.int_tuple<"1">
          %c0_i32_146 = arith.constant 0 : i32
          %c1_i32_147 = arith.constant 1 : i32
          scf.for %arg7 = %c0_i32_146 to %87 step %c1_i32_147  : i32 {
            %88 = cute.get_scalars(%lay_144) <{only_dynamic}> : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
            %89 = cute.static : !cute.shape<"((1,(4,4)))">
            %stride_148 = cute.make_stride(%88) : (i64) -> !cute.stride<"((0,(1,?{i64})))">
            %lay_149 = cute.make_layout(%89, %stride_148) : !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
            %90 = cute.static : !cute.int_tuple<"0">
            %ptr_150 = cute.add_offset(%iter_139, %90) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<f32, gmem>
            %view_151 = cute.make_view(%ptr_150, %lay_149) : !memref_gmem_f32_4
            %91 = cute.static : !cute.layout<"((1,(4,4))):((0,(1,4)))">
            %92 = cute.static : !cute.int_tuple<"0">
            %ptr_152 = cute.add_offset(%iter_140, %92) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, rmem, align<32>>
            %view_153 = cute.make_view(%ptr_152, %91) : !memref_rmem_f32_2
            %93 = cute.static : !cute.layout<"((1,(4,4))):((0,(1,4)))">
            %94 = cute.static : !cute.int_tuple<"0">
            %ptr_154 = cute.add_offset(%iter_145, %94) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
            %view_155 = cute.make_view(%ptr_154, %93) : !memref_rmem_i8_2
            %iter_156 = cute.get_iter(%view_151) : !memref_gmem_f32_4
            %lay_157 = cute.get_layout(%view_151) : !memref_gmem_f32_4
            %95 = cute.get_scalars(%lay_157) <{only_dynamic}> : !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
            %iter_158 = cute.get_iter(%view_153) : !memref_rmem_f32_2
            %iter_159 = cute.get_iter(%view_155) : !memref_rmem_i8_2
            %96 = builtin.unrealized_conversion_cast %iter_159 : !cute.ptr<i8, rmem, align<32>> to !llvm.ptr
            %97 = llvm.load %96 : !llvm.ptr -> i8
            %98 = llvm.mlir.constant(0 : i8) : i8
            %99 = llvm.icmp "ne" %97, %98 : i8
            scf.if %99 {
              %175 = builtin.unrealized_conversion_cast %iter_156 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %176 = builtin.unrealized_conversion_cast %iter_158 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
              %177 = llvm.load %175 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %177, %176 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %100 = cute.static : !cute.int_tuple<"1">
            %ptr_160 = cute.add_offset(%iter_159, %100) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
            %101 = builtin.unrealized_conversion_cast %ptr_160 : !cute.ptr<i8, rmem> to !llvm.ptr
            %102 = llvm.load %101 : !llvm.ptr -> i8
            %103 = llvm.mlir.constant(0 : i8) : i8
            %104 = llvm.icmp "ne" %102, %103 : i8
            scf.if %104 {
              %175 = cute.static : !cute.int_tuple<"1">
              %ptr_175 = cute.add_offset(%iter_156, %175) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
              %176 = cute.static : !cute.int_tuple<"1">
              %ptr_176 = cute.add_offset(%iter_158, %176) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
              %177 = builtin.unrealized_conversion_cast %ptr_175 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %178 = builtin.unrealized_conversion_cast %ptr_176 : !cute.ptr<f32, rmem> to !llvm.ptr
              %179 = llvm.load %177 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %179, %178 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %105 = cute.static : !cute.int_tuple<"2">
            %ptr_161 = cute.add_offset(%iter_159, %105) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem, align<2>>
            %106 = builtin.unrealized_conversion_cast %ptr_161 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
            %107 = llvm.load %106 : !llvm.ptr -> i8
            %108 = llvm.mlir.constant(0 : i8) : i8
            %109 = llvm.icmp "ne" %107, %108 : i8
            scf.if %109 {
              %175 = cute.static : !cute.int_tuple<"2">
              %ptr_175 = cute.add_offset(%iter_156, %175) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
              %176 = cute.static : !cute.int_tuple<"2">
              %ptr_176 = cute.add_offset(%iter_158, %176) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
              %177 = builtin.unrealized_conversion_cast %ptr_175 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %178 = builtin.unrealized_conversion_cast %ptr_176 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
              %179 = llvm.load %177 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %179, %178 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %110 = cute.static : !cute.int_tuple<"3">
            %ptr_162 = cute.add_offset(%iter_159, %110) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
            %111 = builtin.unrealized_conversion_cast %ptr_162 : !cute.ptr<i8, rmem> to !llvm.ptr
            %112 = llvm.load %111 : !llvm.ptr -> i8
            %113 = llvm.mlir.constant(0 : i8) : i8
            %114 = llvm.icmp "ne" %112, %113 : i8
            scf.if %114 {
              %175 = cute.static : !cute.int_tuple<"3">
              %ptr_175 = cute.add_offset(%iter_156, %175) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
              %176 = cute.static : !cute.int_tuple<"3">
              %ptr_176 = cute.add_offset(%iter_158, %176) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
              %177 = builtin.unrealized_conversion_cast %ptr_175 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %178 = builtin.unrealized_conversion_cast %ptr_176 : !cute.ptr<f32, rmem> to !llvm.ptr
              %179 = llvm.load %177 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %179, %178 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %115 = cute.static : !cute.int_tuple<"4">
            %ptr_163 = cute.add_offset(%iter_159, %115) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem, align<4>>
            %116 = builtin.unrealized_conversion_cast %ptr_163 : !cute.ptr<i8, rmem, align<4>> to !llvm.ptr
            %117 = llvm.load %116 : !llvm.ptr -> i8
            %118 = llvm.mlir.constant(0 : i8) : i8
            %119 = llvm.icmp "ne" %117, %118 : i8
            scf.if %119 {
              %int_tuple_175 = cute.make_int_tuple(%95) : (i64) -> !cute.int_tuple<"?{i64}">
              %ptr_176 = cute.add_offset(%iter_156, %int_tuple_175) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
              %175 = cute.static : !cute.int_tuple<"4">
              %ptr_177 = cute.add_offset(%iter_158, %175) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
              %176 = builtin.unrealized_conversion_cast %ptr_176 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %177 = builtin.unrealized_conversion_cast %ptr_177 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              %178 = llvm.load %176 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %178, %177 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %120 = cute.static : !cute.int_tuple<"5">
            %ptr_164 = cute.add_offset(%iter_159, %120) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
            %121 = builtin.unrealized_conversion_cast %ptr_164 : !cute.ptr<i8, rmem> to !llvm.ptr
            %122 = llvm.load %121 : !llvm.ptr -> i8
            %123 = llvm.mlir.constant(0 : i8) : i8
            %124 = llvm.icmp "ne" %122, %123 : i8
            scf.if %124 {
              %c1_i64 = arith.constant 1 : i64
              %175 = arith.addi %95, %c1_i64 : i64
              %int_tuple_175 = cute.make_int_tuple(%175) : (i64) -> !cute.int_tuple<"?{i64}">
              %ptr_176 = cute.add_offset(%iter_156, %int_tuple_175) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
              %176 = cute.static : !cute.int_tuple<"5">
              %ptr_177 = cute.add_offset(%iter_158, %176) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<f32, rmem>
              %177 = builtin.unrealized_conversion_cast %ptr_176 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %178 = builtin.unrealized_conversion_cast %ptr_177 : !cute.ptr<f32, rmem> to !llvm.ptr
              %179 = llvm.load %177 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %179, %178 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %125 = cute.static : !cute.int_tuple<"6">
            %ptr_165 = cute.add_offset(%iter_159, %125) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem, align<2>>
            %126 = builtin.unrealized_conversion_cast %ptr_165 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
            %127 = llvm.load %126 : !llvm.ptr -> i8
            %128 = llvm.mlir.constant(0 : i8) : i8
            %129 = llvm.icmp "ne" %127, %128 : i8
            scf.if %129 {
              %c2_i64 = arith.constant 2 : i64
              %175 = arith.addi %95, %c2_i64 : i64
              %int_tuple_175 = cute.make_int_tuple(%175) : (i64) -> !cute.int_tuple<"?{i64}">
              %ptr_176 = cute.add_offset(%iter_156, %int_tuple_175) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
              %176 = cute.static : !cute.int_tuple<"6">
              %ptr_177 = cute.add_offset(%iter_158, %176) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
              %177 = builtin.unrealized_conversion_cast %ptr_176 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %178 = builtin.unrealized_conversion_cast %ptr_177 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
              %179 = llvm.load %177 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %179, %178 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %130 = cute.static : !cute.int_tuple<"7">
            %ptr_166 = cute.add_offset(%iter_159, %130) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
            %131 = builtin.unrealized_conversion_cast %ptr_166 : !cute.ptr<i8, rmem> to !llvm.ptr
            %132 = llvm.load %131 : !llvm.ptr -> i8
            %133 = llvm.mlir.constant(0 : i8) : i8
            %134 = llvm.icmp "ne" %132, %133 : i8
            scf.if %134 {
              %c3_i64 = arith.constant 3 : i64
              %175 = arith.addi %95, %c3_i64 : i64
              %int_tuple_175 = cute.make_int_tuple(%175) : (i64) -> !cute.int_tuple<"?{i64}">
              %ptr_176 = cute.add_offset(%iter_156, %int_tuple_175) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
              %176 = cute.static : !cute.int_tuple<"7">
              %ptr_177 = cute.add_offset(%iter_158, %176) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<f32, rmem>
              %177 = builtin.unrealized_conversion_cast %ptr_176 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %178 = builtin.unrealized_conversion_cast %ptr_177 : !cute.ptr<f32, rmem> to !llvm.ptr
              %179 = llvm.load %177 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %179, %178 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %135 = cute.static : !cute.int_tuple<"8">
            %ptr_167 = cute.add_offset(%iter_159, %135) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<i8, rmem, align<8>>
            %136 = builtin.unrealized_conversion_cast %ptr_167 : !cute.ptr<i8, rmem, align<8>> to !llvm.ptr
            %137 = llvm.load %136 : !llvm.ptr -> i8
            %138 = llvm.mlir.constant(0 : i8) : i8
            %139 = llvm.icmp "ne" %137, %138 : i8
            scf.if %139 {
              %c2_i64 = arith.constant 2 : i64
              %175 = arith.muli %95, %c2_i64 : i64
              %iv_175 = cute.assume(%175) : (i64) -> !cute.i64<divby 2>
              %int_tuple_176 = cute.make_int_tuple(%iv_175) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
              %ptr_177 = cute.add_offset(%iter_156, %int_tuple_176) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
              %176 = cute.static : !cute.int_tuple<"8">
              %ptr_178 = cute.add_offset(%iter_158, %176) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<f32, rmem, align<32>>
              %177 = builtin.unrealized_conversion_cast %ptr_177 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %178 = builtin.unrealized_conversion_cast %ptr_178 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
              %179 = llvm.load %177 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %179, %178 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %140 = cute.static : !cute.int_tuple<"9">
            %ptr_168 = cute.add_offset(%iter_159, %140) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<i8, rmem>
            %141 = builtin.unrealized_conversion_cast %ptr_168 : !cute.ptr<i8, rmem> to !llvm.ptr
            %142 = llvm.load %141 : !llvm.ptr -> i8
            %143 = llvm.mlir.constant(0 : i8) : i8
            %144 = llvm.icmp "ne" %142, %143 : i8
            scf.if %144 {
              %c2_i64 = arith.constant 2 : i64
              %175 = arith.muli %95, %c2_i64 : i64
              %c1_i64 = arith.constant 1 : i64
              %176 = arith.addi %175, %c1_i64 : i64
              %int_tuple_175 = cute.make_int_tuple(%176) : (i64) -> !cute.int_tuple<"?{i64}">
              %ptr_176 = cute.add_offset(%iter_156, %int_tuple_175) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
              %177 = cute.static : !cute.int_tuple<"9">
              %ptr_177 = cute.add_offset(%iter_158, %177) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<f32, rmem>
              %178 = builtin.unrealized_conversion_cast %ptr_176 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %179 = builtin.unrealized_conversion_cast %ptr_177 : !cute.ptr<f32, rmem> to !llvm.ptr
              %180 = llvm.load %178 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %180, %179 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %145 = cute.static : !cute.int_tuple<"10">
            %ptr_169 = cute.add_offset(%iter_159, %145) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<i8, rmem, align<2>>
            %146 = builtin.unrealized_conversion_cast %ptr_169 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
            %147 = llvm.load %146 : !llvm.ptr -> i8
            %148 = llvm.mlir.constant(0 : i8) : i8
            %149 = llvm.icmp "ne" %147, %148 : i8
            scf.if %149 {
              %c2_i64 = arith.constant 2 : i64
              %175 = arith.muli %95, %c2_i64 : i64
              %c2_i64_175 = arith.constant 2 : i64
              %176 = arith.addi %175, %c2_i64_175 : i64
              %iv_176 = cute.assume(%176) : (i64) -> !cute.i64<divby 2>
              %int_tuple_177 = cute.make_int_tuple(%iv_176) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
              %ptr_178 = cute.add_offset(%iter_156, %int_tuple_177) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
              %177 = cute.static : !cute.int_tuple<"10">
              %ptr_179 = cute.add_offset(%iter_158, %177) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<f32, rmem, align<8>>
              %178 = builtin.unrealized_conversion_cast %ptr_178 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %179 = builtin.unrealized_conversion_cast %ptr_179 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
              %180 = llvm.load %178 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %180, %179 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %150 = cute.static : !cute.int_tuple<"11">
            %ptr_170 = cute.add_offset(%iter_159, %150) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<i8, rmem>
            %151 = builtin.unrealized_conversion_cast %ptr_170 : !cute.ptr<i8, rmem> to !llvm.ptr
            %152 = llvm.load %151 : !llvm.ptr -> i8
            %153 = llvm.mlir.constant(0 : i8) : i8
            %154 = llvm.icmp "ne" %152, %153 : i8
            scf.if %154 {
              %c2_i64 = arith.constant 2 : i64
              %175 = arith.muli %95, %c2_i64 : i64
              %c3_i64 = arith.constant 3 : i64
              %176 = arith.addi %175, %c3_i64 : i64
              %int_tuple_175 = cute.make_int_tuple(%176) : (i64) -> !cute.int_tuple<"?{i64}">
              %ptr_176 = cute.add_offset(%iter_156, %int_tuple_175) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
              %177 = cute.static : !cute.int_tuple<"11">
              %ptr_177 = cute.add_offset(%iter_158, %177) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<f32, rmem>
              %178 = builtin.unrealized_conversion_cast %ptr_176 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %179 = builtin.unrealized_conversion_cast %ptr_177 : !cute.ptr<f32, rmem> to !llvm.ptr
              %180 = llvm.load %178 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %180, %179 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %155 = cute.static : !cute.int_tuple<"12">
            %ptr_171 = cute.add_offset(%iter_159, %155) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<i8, rmem, align<4>>
            %156 = builtin.unrealized_conversion_cast %ptr_171 : !cute.ptr<i8, rmem, align<4>> to !llvm.ptr
            %157 = llvm.load %156 : !llvm.ptr -> i8
            %158 = llvm.mlir.constant(0 : i8) : i8
            %159 = llvm.icmp "ne" %157, %158 : i8
            scf.if %159 {
              %c3_i64 = arith.constant 3 : i64
              %175 = arith.muli %95, %c3_i64 : i64
              %iv_175 = cute.assume(%175) : (i64) -> !cute.i64<divby 3>
              %int_tuple_176 = cute.make_int_tuple(%iv_175) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
              %ptr_177 = cute.add_offset(%iter_156, %int_tuple_176) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
              %176 = cute.static : !cute.int_tuple<"12">
              %ptr_178 = cute.add_offset(%iter_158, %176) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<f32, rmem, align<16>>
              %177 = builtin.unrealized_conversion_cast %ptr_177 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %178 = builtin.unrealized_conversion_cast %ptr_178 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              %179 = llvm.load %177 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %179, %178 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %160 = cute.static : !cute.int_tuple<"13">
            %ptr_172 = cute.add_offset(%iter_159, %160) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<i8, rmem>
            %161 = builtin.unrealized_conversion_cast %ptr_172 : !cute.ptr<i8, rmem> to !llvm.ptr
            %162 = llvm.load %161 : !llvm.ptr -> i8
            %163 = llvm.mlir.constant(0 : i8) : i8
            %164 = llvm.icmp "ne" %162, %163 : i8
            scf.if %164 {
              %c3_i64 = arith.constant 3 : i64
              %175 = arith.muli %95, %c3_i64 : i64
              %c1_i64 = arith.constant 1 : i64
              %176 = arith.addi %175, %c1_i64 : i64
              %int_tuple_175 = cute.make_int_tuple(%176) : (i64) -> !cute.int_tuple<"?{i64}">
              %ptr_176 = cute.add_offset(%iter_156, %int_tuple_175) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
              %177 = cute.static : !cute.int_tuple<"13">
              %ptr_177 = cute.add_offset(%iter_158, %177) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<f32, rmem>
              %178 = builtin.unrealized_conversion_cast %ptr_176 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %179 = builtin.unrealized_conversion_cast %ptr_177 : !cute.ptr<f32, rmem> to !llvm.ptr
              %180 = llvm.load %178 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %180, %179 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %165 = cute.static : !cute.int_tuple<"14">
            %ptr_173 = cute.add_offset(%iter_159, %165) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<i8, rmem, align<2>>
            %166 = builtin.unrealized_conversion_cast %ptr_173 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
            %167 = llvm.load %166 : !llvm.ptr -> i8
            %168 = llvm.mlir.constant(0 : i8) : i8
            %169 = llvm.icmp "ne" %167, %168 : i8
            scf.if %169 {
              %c3_i64 = arith.constant 3 : i64
              %175 = arith.muli %95, %c3_i64 : i64
              %c2_i64 = arith.constant 2 : i64
              %176 = arith.addi %175, %c2_i64 : i64
              %int_tuple_175 = cute.make_int_tuple(%176) : (i64) -> !cute.int_tuple<"?{i64}">
              %ptr_176 = cute.add_offset(%iter_156, %int_tuple_175) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
              %177 = cute.static : !cute.int_tuple<"14">
              %ptr_177 = cute.add_offset(%iter_158, %177) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<f32, rmem, align<8>>
              %178 = builtin.unrealized_conversion_cast %ptr_176 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %179 = builtin.unrealized_conversion_cast %ptr_177 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
              %180 = llvm.load %178 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %180, %179 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %170 = cute.static : !cute.int_tuple<"15">
            %ptr_174 = cute.add_offset(%iter_159, %170) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<i8, rmem>
            %171 = builtin.unrealized_conversion_cast %ptr_174 : !cute.ptr<i8, rmem> to !llvm.ptr
            %172 = llvm.load %171 : !llvm.ptr -> i8
            %173 = llvm.mlir.constant(0 : i8) : i8
            %174 = llvm.icmp "ne" %172, %173 : i8
            scf.if %174 {
              %c3_i64 = arith.constant 3 : i64
              %175 = arith.muli %95, %c3_i64 : i64
              %c3_i64_175 = arith.constant 3 : i64
              %176 = arith.addi %175, %c3_i64_175 : i64
              %iv_176 = cute.assume(%176) : (i64) -> !cute.i64<divby 3>
              %int_tuple_177 = cute.make_int_tuple(%iv_176) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
              %ptr_178 = cute.add_offset(%iter_156, %int_tuple_177) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
              %177 = cute.static : !cute.int_tuple<"15">
              %ptr_179 = cute.add_offset(%iter_158, %177) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<f32, rmem>
              %178 = builtin.unrealized_conversion_cast %ptr_178 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %179 = builtin.unrealized_conversion_cast %ptr_179 : !cute.ptr<f32, rmem> to !llvm.ptr
              %180 = llvm.load %178 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %180, %179 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
          } {llvm.loop_annotation = #loop_annotation}
        }
        llvm.inline_asm has_side_effects asm_dialect = att "griddepcontrol.launch_dependents;", ""  : () -> ()
      } else {
        %c0_i32_99 = arith.constant 0 : i32
        %c10_i32_100 = arith.constant 10 : i32
        %c1_i32_101 = arith.constant 1 : i32
        scf.for %arg6 = %c0_i32_99 to %c10_i32_100 step %c1_i32_101  : i32 {
          %lay_102 = cute.get_layout(%view_43) : !memref_gmem_f32_2
          %68 = cute.static : !cute.layout<"1:0">
          %append_103 = cute.append_to_rank<2> (%lay_102, %68) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">
          %view_104 = cute.make_view(%iter_44, %append_103) : !memref_gmem_f32_2
          %iter_105 = cute.get_iter(%view_104) : !memref_gmem_f32_2
          %lay_106 = cute.get_layout(%view_104) : !memref_gmem_f32_2
          %69 = cute.get_scalars(%lay_106) <{only_dynamic}> : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
          %70 = cute.static : !cute.shape<"((1,(4,4)),(1,1))">
          %stride_107 = cute.make_stride(%69) : (i64) -> !cute.stride<"((0,(1,?{i64})),(0,0))">
          %lay_108 = cute.make_layout(%70, %stride_107) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
          %view_109 = cute.make_view(%iter_105, %lay_108) : !memref_gmem_f32_3
          %71 = cute.static : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %view_110 = cute.make_view(%iter_61, %71) : !memref_rmem_f32_
          %iter_111 = cute.get_iter(%view_110) : !memref_rmem_f32_
          %view_112 = cute.make_view(%iter_111) : !memref_rmem_f32_1
          %72 = cute.static : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %view_113 = cute.make_view(%iter_75, %72) : !memref_rmem_i8_
          %iter_114 = cute.get_iter(%view_113) : !memref_rmem_i8_
          %view_115 = cute.make_view(%iter_114) : !memref_rmem_i8_1
          %73 = cute.static : !cute.layout<"1:0">
          %iter_116 = cute.get_iter(%view_109) : !memref_gmem_f32_3
          %iter_117 = cute.get_iter(%view_112) : !memref_rmem_f32_1
          %lay_118 = cute.get_layout(%view_109) : !memref_gmem_f32_3
          %append_119 = cute.append_to_rank<2> (%lay_118, %73) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">, !cute.layout<"1:0">
          %74 = cute.get_scalars(%append_119) <{only_dynamic}> : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
          %75 = cute.static : !cute.shape<"((1,(4,4)),((1,1)))">
          %stride_120 = cute.make_stride(%74) : (i64) -> !cute.stride<"((0,(1,?{i64})),((0,0)))">
          %lay_121 = cute.make_layout(%75, %stride_120) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
          %iter_122 = cute.get_iter(%view_115) : !memref_rmem_i8_1
          %76 = cute.static : !cute.int_tuple<"1">
          %77 = cute.get_scalars(%76) : !cute.int_tuple<"1">
          %c0_i32_123 = arith.constant 0 : i32
          %c1_i32_124 = arith.constant 1 : i32
          scf.for %arg7 = %c0_i32_123 to %77 step %c1_i32_124  : i32 {
            %78 = cute.get_scalars(%lay_121) <{only_dynamic}> : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
            %79 = cute.static : !cute.shape<"((1,(4,4)))">
            %stride_125 = cute.make_stride(%78) : (i64) -> !cute.stride<"((0,(1,?{i64})))">
            %lay_126 = cute.make_layout(%79, %stride_125) : !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
            %80 = cute.static : !cute.int_tuple<"0">
            %ptr_127 = cute.add_offset(%iter_116, %80) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<f32, gmem>
            %view_128 = cute.make_view(%ptr_127, %lay_126) : !memref_gmem_f32_4
            %81 = cute.static : !cute.layout<"((1,(4,4))):((0,(1,4)))">
            %82 = cute.static : !cute.int_tuple<"0">
            %ptr_129 = cute.add_offset(%iter_117, %82) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, rmem, align<32>>
            %view_130 = cute.make_view(%ptr_129, %81) : !memref_rmem_f32_2
            %83 = cute.static : !cute.layout<"((1,(4,4))):((0,(1,4)))">
            %84 = cute.static : !cute.int_tuple<"0">
            %ptr_131 = cute.add_offset(%iter_122, %84) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
            %view_132 = cute.make_view(%ptr_131, %83) : !memref_rmem_i8_2
            %iter_133 = cute.get_iter(%view_128) : !memref_gmem_f32_4
            %lay_134 = cute.get_layout(%view_128) : !memref_gmem_f32_4
            %85 = cute.get_scalars(%lay_134) <{only_dynamic}> : !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
            %iter_135 = cute.get_iter(%view_130) : !memref_rmem_f32_2
            %iter_136 = cute.get_iter(%view_132) : !memref_rmem_i8_2
            %86 = builtin.unrealized_conversion_cast %iter_136 : !cute.ptr<i8, rmem, align<32>> to !llvm.ptr
            %87 = llvm.load %86 : !llvm.ptr -> i8
            %88 = llvm.mlir.constant(0 : i8) : i8
            %89 = llvm.icmp "ne" %87, %88 : i8
            scf.if %89 {
              %165 = builtin.unrealized_conversion_cast %iter_133 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %166 = builtin.unrealized_conversion_cast %iter_135 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
              %167 = llvm.load %165 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %167, %166 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %90 = cute.static : !cute.int_tuple<"1">
            %ptr_137 = cute.add_offset(%iter_136, %90) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
            %91 = builtin.unrealized_conversion_cast %ptr_137 : !cute.ptr<i8, rmem> to !llvm.ptr
            %92 = llvm.load %91 : !llvm.ptr -> i8
            %93 = llvm.mlir.constant(0 : i8) : i8
            %94 = llvm.icmp "ne" %92, %93 : i8
            scf.if %94 {
              %165 = cute.static : !cute.int_tuple<"1">
              %ptr_152 = cute.add_offset(%iter_133, %165) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
              %166 = cute.static : !cute.int_tuple<"1">
              %ptr_153 = cute.add_offset(%iter_135, %166) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
              %167 = builtin.unrealized_conversion_cast %ptr_152 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %168 = builtin.unrealized_conversion_cast %ptr_153 : !cute.ptr<f32, rmem> to !llvm.ptr
              %169 = llvm.load %167 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %169, %168 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %95 = cute.static : !cute.int_tuple<"2">
            %ptr_138 = cute.add_offset(%iter_136, %95) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem, align<2>>
            %96 = builtin.unrealized_conversion_cast %ptr_138 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
            %97 = llvm.load %96 : !llvm.ptr -> i8
            %98 = llvm.mlir.constant(0 : i8) : i8
            %99 = llvm.icmp "ne" %97, %98 : i8
            scf.if %99 {
              %165 = cute.static : !cute.int_tuple<"2">
              %ptr_152 = cute.add_offset(%iter_133, %165) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
              %166 = cute.static : !cute.int_tuple<"2">
              %ptr_153 = cute.add_offset(%iter_135, %166) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
              %167 = builtin.unrealized_conversion_cast %ptr_152 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %168 = builtin.unrealized_conversion_cast %ptr_153 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
              %169 = llvm.load %167 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %169, %168 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %100 = cute.static : !cute.int_tuple<"3">
            %ptr_139 = cute.add_offset(%iter_136, %100) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
            %101 = builtin.unrealized_conversion_cast %ptr_139 : !cute.ptr<i8, rmem> to !llvm.ptr
            %102 = llvm.load %101 : !llvm.ptr -> i8
            %103 = llvm.mlir.constant(0 : i8) : i8
            %104 = llvm.icmp "ne" %102, %103 : i8
            scf.if %104 {
              %165 = cute.static : !cute.int_tuple<"3">
              %ptr_152 = cute.add_offset(%iter_133, %165) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
              %166 = cute.static : !cute.int_tuple<"3">
              %ptr_153 = cute.add_offset(%iter_135, %166) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
              %167 = builtin.unrealized_conversion_cast %ptr_152 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %168 = builtin.unrealized_conversion_cast %ptr_153 : !cute.ptr<f32, rmem> to !llvm.ptr
              %169 = llvm.load %167 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %169, %168 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %105 = cute.static : !cute.int_tuple<"4">
            %ptr_140 = cute.add_offset(%iter_136, %105) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem, align<4>>
            %106 = builtin.unrealized_conversion_cast %ptr_140 : !cute.ptr<i8, rmem, align<4>> to !llvm.ptr
            %107 = llvm.load %106 : !llvm.ptr -> i8
            %108 = llvm.mlir.constant(0 : i8) : i8
            %109 = llvm.icmp "ne" %107, %108 : i8
            scf.if %109 {
              %int_tuple_152 = cute.make_int_tuple(%85) : (i64) -> !cute.int_tuple<"?{i64}">
              %ptr_153 = cute.add_offset(%iter_133, %int_tuple_152) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
              %165 = cute.static : !cute.int_tuple<"4">
              %ptr_154 = cute.add_offset(%iter_135, %165) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
              %166 = builtin.unrealized_conversion_cast %ptr_153 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %167 = builtin.unrealized_conversion_cast %ptr_154 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              %168 = llvm.load %166 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %168, %167 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %110 = cute.static : !cute.int_tuple<"5">
            %ptr_141 = cute.add_offset(%iter_136, %110) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
            %111 = builtin.unrealized_conversion_cast %ptr_141 : !cute.ptr<i8, rmem> to !llvm.ptr
            %112 = llvm.load %111 : !llvm.ptr -> i8
            %113 = llvm.mlir.constant(0 : i8) : i8
            %114 = llvm.icmp "ne" %112, %113 : i8
            scf.if %114 {
              %c1_i64 = arith.constant 1 : i64
              %165 = arith.addi %85, %c1_i64 : i64
              %int_tuple_152 = cute.make_int_tuple(%165) : (i64) -> !cute.int_tuple<"?{i64}">
              %ptr_153 = cute.add_offset(%iter_133, %int_tuple_152) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
              %166 = cute.static : !cute.int_tuple<"5">
              %ptr_154 = cute.add_offset(%iter_135, %166) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<f32, rmem>
              %167 = builtin.unrealized_conversion_cast %ptr_153 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %168 = builtin.unrealized_conversion_cast %ptr_154 : !cute.ptr<f32, rmem> to !llvm.ptr
              %169 = llvm.load %167 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %169, %168 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %115 = cute.static : !cute.int_tuple<"6">
            %ptr_142 = cute.add_offset(%iter_136, %115) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem, align<2>>
            %116 = builtin.unrealized_conversion_cast %ptr_142 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
            %117 = llvm.load %116 : !llvm.ptr -> i8
            %118 = llvm.mlir.constant(0 : i8) : i8
            %119 = llvm.icmp "ne" %117, %118 : i8
            scf.if %119 {
              %c2_i64 = arith.constant 2 : i64
              %165 = arith.addi %85, %c2_i64 : i64
              %int_tuple_152 = cute.make_int_tuple(%165) : (i64) -> !cute.int_tuple<"?{i64}">
              %ptr_153 = cute.add_offset(%iter_133, %int_tuple_152) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
              %166 = cute.static : !cute.int_tuple<"6">
              %ptr_154 = cute.add_offset(%iter_135, %166) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
              %167 = builtin.unrealized_conversion_cast %ptr_153 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %168 = builtin.unrealized_conversion_cast %ptr_154 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
              %169 = llvm.load %167 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %169, %168 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %120 = cute.static : !cute.int_tuple<"7">
            %ptr_143 = cute.add_offset(%iter_136, %120) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
            %121 = builtin.unrealized_conversion_cast %ptr_143 : !cute.ptr<i8, rmem> to !llvm.ptr
            %122 = llvm.load %121 : !llvm.ptr -> i8
            %123 = llvm.mlir.constant(0 : i8) : i8
            %124 = llvm.icmp "ne" %122, %123 : i8
            scf.if %124 {
              %c3_i64 = arith.constant 3 : i64
              %165 = arith.addi %85, %c3_i64 : i64
              %int_tuple_152 = cute.make_int_tuple(%165) : (i64) -> !cute.int_tuple<"?{i64}">
              %ptr_153 = cute.add_offset(%iter_133, %int_tuple_152) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
              %166 = cute.static : !cute.int_tuple<"7">
              %ptr_154 = cute.add_offset(%iter_135, %166) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<f32, rmem>
              %167 = builtin.unrealized_conversion_cast %ptr_153 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %168 = builtin.unrealized_conversion_cast %ptr_154 : !cute.ptr<f32, rmem> to !llvm.ptr
              %169 = llvm.load %167 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %169, %168 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %125 = cute.static : !cute.int_tuple<"8">
            %ptr_144 = cute.add_offset(%iter_136, %125) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<i8, rmem, align<8>>
            %126 = builtin.unrealized_conversion_cast %ptr_144 : !cute.ptr<i8, rmem, align<8>> to !llvm.ptr
            %127 = llvm.load %126 : !llvm.ptr -> i8
            %128 = llvm.mlir.constant(0 : i8) : i8
            %129 = llvm.icmp "ne" %127, %128 : i8
            scf.if %129 {
              %c2_i64 = arith.constant 2 : i64
              %165 = arith.muli %85, %c2_i64 : i64
              %iv_152 = cute.assume(%165) : (i64) -> !cute.i64<divby 2>
              %int_tuple_153 = cute.make_int_tuple(%iv_152) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
              %ptr_154 = cute.add_offset(%iter_133, %int_tuple_153) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
              %166 = cute.static : !cute.int_tuple<"8">
              %ptr_155 = cute.add_offset(%iter_135, %166) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<f32, rmem, align<32>>
              %167 = builtin.unrealized_conversion_cast %ptr_154 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %168 = builtin.unrealized_conversion_cast %ptr_155 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
              %169 = llvm.load %167 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %169, %168 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %130 = cute.static : !cute.int_tuple<"9">
            %ptr_145 = cute.add_offset(%iter_136, %130) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<i8, rmem>
            %131 = builtin.unrealized_conversion_cast %ptr_145 : !cute.ptr<i8, rmem> to !llvm.ptr
            %132 = llvm.load %131 : !llvm.ptr -> i8
            %133 = llvm.mlir.constant(0 : i8) : i8
            %134 = llvm.icmp "ne" %132, %133 : i8
            scf.if %134 {
              %c2_i64 = arith.constant 2 : i64
              %165 = arith.muli %85, %c2_i64 : i64
              %c1_i64 = arith.constant 1 : i64
              %166 = arith.addi %165, %c1_i64 : i64
              %int_tuple_152 = cute.make_int_tuple(%166) : (i64) -> !cute.int_tuple<"?{i64}">
              %ptr_153 = cute.add_offset(%iter_133, %int_tuple_152) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
              %167 = cute.static : !cute.int_tuple<"9">
              %ptr_154 = cute.add_offset(%iter_135, %167) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<f32, rmem>
              %168 = builtin.unrealized_conversion_cast %ptr_153 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %169 = builtin.unrealized_conversion_cast %ptr_154 : !cute.ptr<f32, rmem> to !llvm.ptr
              %170 = llvm.load %168 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %170, %169 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %135 = cute.static : !cute.int_tuple<"10">
            %ptr_146 = cute.add_offset(%iter_136, %135) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<i8, rmem, align<2>>
            %136 = builtin.unrealized_conversion_cast %ptr_146 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
            %137 = llvm.load %136 : !llvm.ptr -> i8
            %138 = llvm.mlir.constant(0 : i8) : i8
            %139 = llvm.icmp "ne" %137, %138 : i8
            scf.if %139 {
              %c2_i64 = arith.constant 2 : i64
              %165 = arith.muli %85, %c2_i64 : i64
              %c2_i64_152 = arith.constant 2 : i64
              %166 = arith.addi %165, %c2_i64_152 : i64
              %iv_153 = cute.assume(%166) : (i64) -> !cute.i64<divby 2>
              %int_tuple_154 = cute.make_int_tuple(%iv_153) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
              %ptr_155 = cute.add_offset(%iter_133, %int_tuple_154) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
              %167 = cute.static : !cute.int_tuple<"10">
              %ptr_156 = cute.add_offset(%iter_135, %167) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<f32, rmem, align<8>>
              %168 = builtin.unrealized_conversion_cast %ptr_155 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %169 = builtin.unrealized_conversion_cast %ptr_156 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
              %170 = llvm.load %168 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %170, %169 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %140 = cute.static : !cute.int_tuple<"11">
            %ptr_147 = cute.add_offset(%iter_136, %140) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<i8, rmem>
            %141 = builtin.unrealized_conversion_cast %ptr_147 : !cute.ptr<i8, rmem> to !llvm.ptr
            %142 = llvm.load %141 : !llvm.ptr -> i8
            %143 = llvm.mlir.constant(0 : i8) : i8
            %144 = llvm.icmp "ne" %142, %143 : i8
            scf.if %144 {
              %c2_i64 = arith.constant 2 : i64
              %165 = arith.muli %85, %c2_i64 : i64
              %c3_i64 = arith.constant 3 : i64
              %166 = arith.addi %165, %c3_i64 : i64
              %int_tuple_152 = cute.make_int_tuple(%166) : (i64) -> !cute.int_tuple<"?{i64}">
              %ptr_153 = cute.add_offset(%iter_133, %int_tuple_152) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
              %167 = cute.static : !cute.int_tuple<"11">
              %ptr_154 = cute.add_offset(%iter_135, %167) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<f32, rmem>
              %168 = builtin.unrealized_conversion_cast %ptr_153 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %169 = builtin.unrealized_conversion_cast %ptr_154 : !cute.ptr<f32, rmem> to !llvm.ptr
              %170 = llvm.load %168 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %170, %169 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %145 = cute.static : !cute.int_tuple<"12">
            %ptr_148 = cute.add_offset(%iter_136, %145) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<i8, rmem, align<4>>
            %146 = builtin.unrealized_conversion_cast %ptr_148 : !cute.ptr<i8, rmem, align<4>> to !llvm.ptr
            %147 = llvm.load %146 : !llvm.ptr -> i8
            %148 = llvm.mlir.constant(0 : i8) : i8
            %149 = llvm.icmp "ne" %147, %148 : i8
            scf.if %149 {
              %c3_i64 = arith.constant 3 : i64
              %165 = arith.muli %85, %c3_i64 : i64
              %iv_152 = cute.assume(%165) : (i64) -> !cute.i64<divby 3>
              %int_tuple_153 = cute.make_int_tuple(%iv_152) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
              %ptr_154 = cute.add_offset(%iter_133, %int_tuple_153) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
              %166 = cute.static : !cute.int_tuple<"12">
              %ptr_155 = cute.add_offset(%iter_135, %166) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<f32, rmem, align<16>>
              %167 = builtin.unrealized_conversion_cast %ptr_154 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %168 = builtin.unrealized_conversion_cast %ptr_155 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              %169 = llvm.load %167 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %169, %168 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %150 = cute.static : !cute.int_tuple<"13">
            %ptr_149 = cute.add_offset(%iter_136, %150) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<i8, rmem>
            %151 = builtin.unrealized_conversion_cast %ptr_149 : !cute.ptr<i8, rmem> to !llvm.ptr
            %152 = llvm.load %151 : !llvm.ptr -> i8
            %153 = llvm.mlir.constant(0 : i8) : i8
            %154 = llvm.icmp "ne" %152, %153 : i8
            scf.if %154 {
              %c3_i64 = arith.constant 3 : i64
              %165 = arith.muli %85, %c3_i64 : i64
              %c1_i64 = arith.constant 1 : i64
              %166 = arith.addi %165, %c1_i64 : i64
              %int_tuple_152 = cute.make_int_tuple(%166) : (i64) -> !cute.int_tuple<"?{i64}">
              %ptr_153 = cute.add_offset(%iter_133, %int_tuple_152) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
              %167 = cute.static : !cute.int_tuple<"13">
              %ptr_154 = cute.add_offset(%iter_135, %167) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<f32, rmem>
              %168 = builtin.unrealized_conversion_cast %ptr_153 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %169 = builtin.unrealized_conversion_cast %ptr_154 : !cute.ptr<f32, rmem> to !llvm.ptr
              %170 = llvm.load %168 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %170, %169 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %155 = cute.static : !cute.int_tuple<"14">
            %ptr_150 = cute.add_offset(%iter_136, %155) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<i8, rmem, align<2>>
            %156 = builtin.unrealized_conversion_cast %ptr_150 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
            %157 = llvm.load %156 : !llvm.ptr -> i8
            %158 = llvm.mlir.constant(0 : i8) : i8
            %159 = llvm.icmp "ne" %157, %158 : i8
            scf.if %159 {
              %c3_i64 = arith.constant 3 : i64
              %165 = arith.muli %85, %c3_i64 : i64
              %c2_i64 = arith.constant 2 : i64
              %166 = arith.addi %165, %c2_i64 : i64
              %int_tuple_152 = cute.make_int_tuple(%166) : (i64) -> !cute.int_tuple<"?{i64}">
              %ptr_153 = cute.add_offset(%iter_133, %int_tuple_152) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
              %167 = cute.static : !cute.int_tuple<"14">
              %ptr_154 = cute.add_offset(%iter_135, %167) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<f32, rmem, align<8>>
              %168 = builtin.unrealized_conversion_cast %ptr_153 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %169 = builtin.unrealized_conversion_cast %ptr_154 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
              %170 = llvm.load %168 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %170, %169 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %160 = cute.static : !cute.int_tuple<"15">
            %ptr_151 = cute.add_offset(%iter_136, %160) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<i8, rmem>
            %161 = builtin.unrealized_conversion_cast %ptr_151 : !cute.ptr<i8, rmem> to !llvm.ptr
            %162 = llvm.load %161 : !llvm.ptr -> i8
            %163 = llvm.mlir.constant(0 : i8) : i8
            %164 = llvm.icmp "ne" %162, %163 : i8
            scf.if %164 {
              %c3_i64 = arith.constant 3 : i64
              %165 = arith.muli %85, %c3_i64 : i64
              %c3_i64_152 = arith.constant 3 : i64
              %166 = arith.addi %165, %c3_i64_152 : i64
              %iv_153 = cute.assume(%166) : (i64) -> !cute.i64<divby 3>
              %int_tuple_154 = cute.make_int_tuple(%iv_153) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
              %ptr_155 = cute.add_offset(%iter_133, %int_tuple_154) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
              %167 = cute.static : !cute.int_tuple<"15">
              %ptr_156 = cute.add_offset(%iter_135, %167) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<f32, rmem>
              %168 = builtin.unrealized_conversion_cast %ptr_155 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %169 = builtin.unrealized_conversion_cast %ptr_156 : !cute.ptr<f32, rmem> to !llvm.ptr
              %170 = llvm.load %168 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %170, %169 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
          } {llvm.loop_annotation = #loop_annotation}
        }
        llvm.inline_asm has_side_effects asm_dialect = att "griddepcontrol.wait;", ""  : () -> ()
        scf.for %arg6 = %c0_i32_99 to %c10_i32_100 step %c1_i32_101  : i32 {
          %lay_102 = cute.get_layout(%view_29) : !memref_gmem_f32_2
          %68 = cute.static : !cute.layout<"1:0">
          %append_103 = cute.append_to_rank<2> (%lay_102, %68) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">
          %view_104 = cute.make_view(%iter_30, %append_103) : !memref_gmem_f32_2
          %iter_105 = cute.get_iter(%view_104) : !memref_gmem_f32_2
          %lay_106 = cute.get_layout(%view_104) : !memref_gmem_f32_2
          %69 = cute.get_scalars(%lay_106) <{only_dynamic}> : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
          %70 = cute.static : !cute.shape<"((1,(4,4)),(1,1))">
          %stride_107 = cute.make_stride(%69) : (i64) -> !cute.stride<"((0,(1,?{i64})),(0,0))">
          %lay_108 = cute.make_layout(%70, %stride_107) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
          %view_109 = cute.make_view(%iter_105, %lay_108) : !memref_gmem_f32_3
          %71 = cute.static : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %view_110 = cute.make_view(%iter_59, %71) : !memref_rmem_f32_
          %iter_111 = cute.get_iter(%view_110) : !memref_rmem_f32_
          %view_112 = cute.make_view(%iter_111) : !memref_rmem_f32_1
          %72 = cute.static : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
          %view_113 = cute.make_view(%iter_75, %72) : !memref_rmem_i8_
          %iter_114 = cute.get_iter(%view_113) : !memref_rmem_i8_
          %view_115 = cute.make_view(%iter_114) : !memref_rmem_i8_1
          %73 = cute.static : !cute.layout<"1:0">
          %iter_116 = cute.get_iter(%view_109) : !memref_gmem_f32_3
          %iter_117 = cute.get_iter(%view_112) : !memref_rmem_f32_1
          %lay_118 = cute.get_layout(%view_109) : !memref_gmem_f32_3
          %append_119 = cute.append_to_rank<2> (%lay_118, %73) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">, !cute.layout<"1:0">
          %74 = cute.get_scalars(%append_119) <{only_dynamic}> : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
          %75 = cute.static : !cute.shape<"((1,(4,4)),((1,1)))">
          %stride_120 = cute.make_stride(%74) : (i64) -> !cute.stride<"((0,(1,?{i64})),((0,0)))">
          %lay_121 = cute.make_layout(%75, %stride_120) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
          %iter_122 = cute.get_iter(%view_115) : !memref_rmem_i8_1
          %76 = cute.static : !cute.int_tuple<"1">
          %77 = cute.get_scalars(%76) : !cute.int_tuple<"1">
          %c0_i32_123 = arith.constant 0 : i32
          %c1_i32_124 = arith.constant 1 : i32
          scf.for %arg7 = %c0_i32_123 to %77 step %c1_i32_124  : i32 {
            %78 = cute.get_scalars(%lay_121) <{only_dynamic}> : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
            %79 = cute.static : !cute.shape<"((1,(4,4)))">
            %stride_125 = cute.make_stride(%78) : (i64) -> !cute.stride<"((0,(1,?{i64})))">
            %lay_126 = cute.make_layout(%79, %stride_125) : !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
            %80 = cute.static : !cute.int_tuple<"0">
            %ptr_127 = cute.add_offset(%iter_116, %80) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<f32, gmem>
            %view_128 = cute.make_view(%ptr_127, %lay_126) : !memref_gmem_f32_4
            %81 = cute.static : !cute.layout<"((1,(4,4))):((0,(1,4)))">
            %82 = cute.static : !cute.int_tuple<"0">
            %ptr_129 = cute.add_offset(%iter_117, %82) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, rmem, align<32>>
            %view_130 = cute.make_view(%ptr_129, %81) : !memref_rmem_f32_2
            %83 = cute.static : !cute.layout<"((1,(4,4))):((0,(1,4)))">
            %84 = cute.static : !cute.int_tuple<"0">
            %ptr_131 = cute.add_offset(%iter_122, %84) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
            %view_132 = cute.make_view(%ptr_131, %83) : !memref_rmem_i8_2
            %iter_133 = cute.get_iter(%view_128) : !memref_gmem_f32_4
            %lay_134 = cute.get_layout(%view_128) : !memref_gmem_f32_4
            %85 = cute.get_scalars(%lay_134) <{only_dynamic}> : !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
            %iter_135 = cute.get_iter(%view_130) : !memref_rmem_f32_2
            %iter_136 = cute.get_iter(%view_132) : !memref_rmem_i8_2
            %86 = builtin.unrealized_conversion_cast %iter_136 : !cute.ptr<i8, rmem, align<32>> to !llvm.ptr
            %87 = llvm.load %86 : !llvm.ptr -> i8
            %88 = llvm.mlir.constant(0 : i8) : i8
            %89 = llvm.icmp "ne" %87, %88 : i8
            scf.if %89 {
              %165 = builtin.unrealized_conversion_cast %iter_133 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %166 = builtin.unrealized_conversion_cast %iter_135 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
              %167 = llvm.load %165 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %167, %166 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %90 = cute.static : !cute.int_tuple<"1">
            %ptr_137 = cute.add_offset(%iter_136, %90) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
            %91 = builtin.unrealized_conversion_cast %ptr_137 : !cute.ptr<i8, rmem> to !llvm.ptr
            %92 = llvm.load %91 : !llvm.ptr -> i8
            %93 = llvm.mlir.constant(0 : i8) : i8
            %94 = llvm.icmp "ne" %92, %93 : i8
            scf.if %94 {
              %165 = cute.static : !cute.int_tuple<"1">
              %ptr_152 = cute.add_offset(%iter_133, %165) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
              %166 = cute.static : !cute.int_tuple<"1">
              %ptr_153 = cute.add_offset(%iter_135, %166) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
              %167 = builtin.unrealized_conversion_cast %ptr_152 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %168 = builtin.unrealized_conversion_cast %ptr_153 : !cute.ptr<f32, rmem> to !llvm.ptr
              %169 = llvm.load %167 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %169, %168 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %95 = cute.static : !cute.int_tuple<"2">
            %ptr_138 = cute.add_offset(%iter_136, %95) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem, align<2>>
            %96 = builtin.unrealized_conversion_cast %ptr_138 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
            %97 = llvm.load %96 : !llvm.ptr -> i8
            %98 = llvm.mlir.constant(0 : i8) : i8
            %99 = llvm.icmp "ne" %97, %98 : i8
            scf.if %99 {
              %165 = cute.static : !cute.int_tuple<"2">
              %ptr_152 = cute.add_offset(%iter_133, %165) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
              %166 = cute.static : !cute.int_tuple<"2">
              %ptr_153 = cute.add_offset(%iter_135, %166) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
              %167 = builtin.unrealized_conversion_cast %ptr_152 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %168 = builtin.unrealized_conversion_cast %ptr_153 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
              %169 = llvm.load %167 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %169, %168 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %100 = cute.static : !cute.int_tuple<"3">
            %ptr_139 = cute.add_offset(%iter_136, %100) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
            %101 = builtin.unrealized_conversion_cast %ptr_139 : !cute.ptr<i8, rmem> to !llvm.ptr
            %102 = llvm.load %101 : !llvm.ptr -> i8
            %103 = llvm.mlir.constant(0 : i8) : i8
            %104 = llvm.icmp "ne" %102, %103 : i8
            scf.if %104 {
              %165 = cute.static : !cute.int_tuple<"3">
              %ptr_152 = cute.add_offset(%iter_133, %165) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
              %166 = cute.static : !cute.int_tuple<"3">
              %ptr_153 = cute.add_offset(%iter_135, %166) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
              %167 = builtin.unrealized_conversion_cast %ptr_152 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %168 = builtin.unrealized_conversion_cast %ptr_153 : !cute.ptr<f32, rmem> to !llvm.ptr
              %169 = llvm.load %167 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %169, %168 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %105 = cute.static : !cute.int_tuple<"4">
            %ptr_140 = cute.add_offset(%iter_136, %105) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem, align<4>>
            %106 = builtin.unrealized_conversion_cast %ptr_140 : !cute.ptr<i8, rmem, align<4>> to !llvm.ptr
            %107 = llvm.load %106 : !llvm.ptr -> i8
            %108 = llvm.mlir.constant(0 : i8) : i8
            %109 = llvm.icmp "ne" %107, %108 : i8
            scf.if %109 {
              %int_tuple_152 = cute.make_int_tuple(%85) : (i64) -> !cute.int_tuple<"?{i64}">
              %ptr_153 = cute.add_offset(%iter_133, %int_tuple_152) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
              %165 = cute.static : !cute.int_tuple<"4">
              %ptr_154 = cute.add_offset(%iter_135, %165) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
              %166 = builtin.unrealized_conversion_cast %ptr_153 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %167 = builtin.unrealized_conversion_cast %ptr_154 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              %168 = llvm.load %166 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %168, %167 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %110 = cute.static : !cute.int_tuple<"5">
            %ptr_141 = cute.add_offset(%iter_136, %110) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
            %111 = builtin.unrealized_conversion_cast %ptr_141 : !cute.ptr<i8, rmem> to !llvm.ptr
            %112 = llvm.load %111 : !llvm.ptr -> i8
            %113 = llvm.mlir.constant(0 : i8) : i8
            %114 = llvm.icmp "ne" %112, %113 : i8
            scf.if %114 {
              %c1_i64 = arith.constant 1 : i64
              %165 = arith.addi %85, %c1_i64 : i64
              %int_tuple_152 = cute.make_int_tuple(%165) : (i64) -> !cute.int_tuple<"?{i64}">
              %ptr_153 = cute.add_offset(%iter_133, %int_tuple_152) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
              %166 = cute.static : !cute.int_tuple<"5">
              %ptr_154 = cute.add_offset(%iter_135, %166) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<f32, rmem>
              %167 = builtin.unrealized_conversion_cast %ptr_153 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %168 = builtin.unrealized_conversion_cast %ptr_154 : !cute.ptr<f32, rmem> to !llvm.ptr
              %169 = llvm.load %167 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %169, %168 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %115 = cute.static : !cute.int_tuple<"6">
            %ptr_142 = cute.add_offset(%iter_136, %115) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem, align<2>>
            %116 = builtin.unrealized_conversion_cast %ptr_142 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
            %117 = llvm.load %116 : !llvm.ptr -> i8
            %118 = llvm.mlir.constant(0 : i8) : i8
            %119 = llvm.icmp "ne" %117, %118 : i8
            scf.if %119 {
              %c2_i64 = arith.constant 2 : i64
              %165 = arith.addi %85, %c2_i64 : i64
              %int_tuple_152 = cute.make_int_tuple(%165) : (i64) -> !cute.int_tuple<"?{i64}">
              %ptr_153 = cute.add_offset(%iter_133, %int_tuple_152) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
              %166 = cute.static : !cute.int_tuple<"6">
              %ptr_154 = cute.add_offset(%iter_135, %166) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
              %167 = builtin.unrealized_conversion_cast %ptr_153 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %168 = builtin.unrealized_conversion_cast %ptr_154 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
              %169 = llvm.load %167 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %169, %168 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %120 = cute.static : !cute.int_tuple<"7">
            %ptr_143 = cute.add_offset(%iter_136, %120) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
            %121 = builtin.unrealized_conversion_cast %ptr_143 : !cute.ptr<i8, rmem> to !llvm.ptr
            %122 = llvm.load %121 : !llvm.ptr -> i8
            %123 = llvm.mlir.constant(0 : i8) : i8
            %124 = llvm.icmp "ne" %122, %123 : i8
            scf.if %124 {
              %c3_i64 = arith.constant 3 : i64
              %165 = arith.addi %85, %c3_i64 : i64
              %int_tuple_152 = cute.make_int_tuple(%165) : (i64) -> !cute.int_tuple<"?{i64}">
              %ptr_153 = cute.add_offset(%iter_133, %int_tuple_152) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
              %166 = cute.static : !cute.int_tuple<"7">
              %ptr_154 = cute.add_offset(%iter_135, %166) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<f32, rmem>
              %167 = builtin.unrealized_conversion_cast %ptr_153 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %168 = builtin.unrealized_conversion_cast %ptr_154 : !cute.ptr<f32, rmem> to !llvm.ptr
              %169 = llvm.load %167 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %169, %168 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %125 = cute.static : !cute.int_tuple<"8">
            %ptr_144 = cute.add_offset(%iter_136, %125) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<i8, rmem, align<8>>
            %126 = builtin.unrealized_conversion_cast %ptr_144 : !cute.ptr<i8, rmem, align<8>> to !llvm.ptr
            %127 = llvm.load %126 : !llvm.ptr -> i8
            %128 = llvm.mlir.constant(0 : i8) : i8
            %129 = llvm.icmp "ne" %127, %128 : i8
            scf.if %129 {
              %c2_i64 = arith.constant 2 : i64
              %165 = arith.muli %85, %c2_i64 : i64
              %iv_152 = cute.assume(%165) : (i64) -> !cute.i64<divby 2>
              %int_tuple_153 = cute.make_int_tuple(%iv_152) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
              %ptr_154 = cute.add_offset(%iter_133, %int_tuple_153) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
              %166 = cute.static : !cute.int_tuple<"8">
              %ptr_155 = cute.add_offset(%iter_135, %166) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<f32, rmem, align<32>>
              %167 = builtin.unrealized_conversion_cast %ptr_154 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %168 = builtin.unrealized_conversion_cast %ptr_155 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
              %169 = llvm.load %167 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %169, %168 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %130 = cute.static : !cute.int_tuple<"9">
            %ptr_145 = cute.add_offset(%iter_136, %130) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<i8, rmem>
            %131 = builtin.unrealized_conversion_cast %ptr_145 : !cute.ptr<i8, rmem> to !llvm.ptr
            %132 = llvm.load %131 : !llvm.ptr -> i8
            %133 = llvm.mlir.constant(0 : i8) : i8
            %134 = llvm.icmp "ne" %132, %133 : i8
            scf.if %134 {
              %c2_i64 = arith.constant 2 : i64
              %165 = arith.muli %85, %c2_i64 : i64
              %c1_i64 = arith.constant 1 : i64
              %166 = arith.addi %165, %c1_i64 : i64
              %int_tuple_152 = cute.make_int_tuple(%166) : (i64) -> !cute.int_tuple<"?{i64}">
              %ptr_153 = cute.add_offset(%iter_133, %int_tuple_152) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
              %167 = cute.static : !cute.int_tuple<"9">
              %ptr_154 = cute.add_offset(%iter_135, %167) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<f32, rmem>
              %168 = builtin.unrealized_conversion_cast %ptr_153 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %169 = builtin.unrealized_conversion_cast %ptr_154 : !cute.ptr<f32, rmem> to !llvm.ptr
              %170 = llvm.load %168 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %170, %169 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %135 = cute.static : !cute.int_tuple<"10">
            %ptr_146 = cute.add_offset(%iter_136, %135) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<i8, rmem, align<2>>
            %136 = builtin.unrealized_conversion_cast %ptr_146 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
            %137 = llvm.load %136 : !llvm.ptr -> i8
            %138 = llvm.mlir.constant(0 : i8) : i8
            %139 = llvm.icmp "ne" %137, %138 : i8
            scf.if %139 {
              %c2_i64 = arith.constant 2 : i64
              %165 = arith.muli %85, %c2_i64 : i64
              %c2_i64_152 = arith.constant 2 : i64
              %166 = arith.addi %165, %c2_i64_152 : i64
              %iv_153 = cute.assume(%166) : (i64) -> !cute.i64<divby 2>
              %int_tuple_154 = cute.make_int_tuple(%iv_153) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
              %ptr_155 = cute.add_offset(%iter_133, %int_tuple_154) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
              %167 = cute.static : !cute.int_tuple<"10">
              %ptr_156 = cute.add_offset(%iter_135, %167) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<f32, rmem, align<8>>
              %168 = builtin.unrealized_conversion_cast %ptr_155 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %169 = builtin.unrealized_conversion_cast %ptr_156 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
              %170 = llvm.load %168 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %170, %169 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %140 = cute.static : !cute.int_tuple<"11">
            %ptr_147 = cute.add_offset(%iter_136, %140) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<i8, rmem>
            %141 = builtin.unrealized_conversion_cast %ptr_147 : !cute.ptr<i8, rmem> to !llvm.ptr
            %142 = llvm.load %141 : !llvm.ptr -> i8
            %143 = llvm.mlir.constant(0 : i8) : i8
            %144 = llvm.icmp "ne" %142, %143 : i8
            scf.if %144 {
              %c2_i64 = arith.constant 2 : i64
              %165 = arith.muli %85, %c2_i64 : i64
              %c3_i64 = arith.constant 3 : i64
              %166 = arith.addi %165, %c3_i64 : i64
              %int_tuple_152 = cute.make_int_tuple(%166) : (i64) -> !cute.int_tuple<"?{i64}">
              %ptr_153 = cute.add_offset(%iter_133, %int_tuple_152) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
              %167 = cute.static : !cute.int_tuple<"11">
              %ptr_154 = cute.add_offset(%iter_135, %167) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<f32, rmem>
              %168 = builtin.unrealized_conversion_cast %ptr_153 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %169 = builtin.unrealized_conversion_cast %ptr_154 : !cute.ptr<f32, rmem> to !llvm.ptr
              %170 = llvm.load %168 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %170, %169 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %145 = cute.static : !cute.int_tuple<"12">
            %ptr_148 = cute.add_offset(%iter_136, %145) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<i8, rmem, align<4>>
            %146 = builtin.unrealized_conversion_cast %ptr_148 : !cute.ptr<i8, rmem, align<4>> to !llvm.ptr
            %147 = llvm.load %146 : !llvm.ptr -> i8
            %148 = llvm.mlir.constant(0 : i8) : i8
            %149 = llvm.icmp "ne" %147, %148 : i8
            scf.if %149 {
              %c3_i64 = arith.constant 3 : i64
              %165 = arith.muli %85, %c3_i64 : i64
              %iv_152 = cute.assume(%165) : (i64) -> !cute.i64<divby 3>
              %int_tuple_153 = cute.make_int_tuple(%iv_152) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
              %ptr_154 = cute.add_offset(%iter_133, %int_tuple_153) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
              %166 = cute.static : !cute.int_tuple<"12">
              %ptr_155 = cute.add_offset(%iter_135, %166) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<f32, rmem, align<16>>
              %167 = builtin.unrealized_conversion_cast %ptr_154 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %168 = builtin.unrealized_conversion_cast %ptr_155 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
              %169 = llvm.load %167 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %169, %168 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %150 = cute.static : !cute.int_tuple<"13">
            %ptr_149 = cute.add_offset(%iter_136, %150) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<i8, rmem>
            %151 = builtin.unrealized_conversion_cast %ptr_149 : !cute.ptr<i8, rmem> to !llvm.ptr
            %152 = llvm.load %151 : !llvm.ptr -> i8
            %153 = llvm.mlir.constant(0 : i8) : i8
            %154 = llvm.icmp "ne" %152, %153 : i8
            scf.if %154 {
              %c3_i64 = arith.constant 3 : i64
              %165 = arith.muli %85, %c3_i64 : i64
              %c1_i64 = arith.constant 1 : i64
              %166 = arith.addi %165, %c1_i64 : i64
              %int_tuple_152 = cute.make_int_tuple(%166) : (i64) -> !cute.int_tuple<"?{i64}">
              %ptr_153 = cute.add_offset(%iter_133, %int_tuple_152) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
              %167 = cute.static : !cute.int_tuple<"13">
              %ptr_154 = cute.add_offset(%iter_135, %167) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<f32, rmem>
              %168 = builtin.unrealized_conversion_cast %ptr_153 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %169 = builtin.unrealized_conversion_cast %ptr_154 : !cute.ptr<f32, rmem> to !llvm.ptr
              %170 = llvm.load %168 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %170, %169 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %155 = cute.static : !cute.int_tuple<"14">
            %ptr_150 = cute.add_offset(%iter_136, %155) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<i8, rmem, align<2>>
            %156 = builtin.unrealized_conversion_cast %ptr_150 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
            %157 = llvm.load %156 : !llvm.ptr -> i8
            %158 = llvm.mlir.constant(0 : i8) : i8
            %159 = llvm.icmp "ne" %157, %158 : i8
            scf.if %159 {
              %c3_i64 = arith.constant 3 : i64
              %165 = arith.muli %85, %c3_i64 : i64
              %c2_i64 = arith.constant 2 : i64
              %166 = arith.addi %165, %c2_i64 : i64
              %int_tuple_152 = cute.make_int_tuple(%166) : (i64) -> !cute.int_tuple<"?{i64}">
              %ptr_153 = cute.add_offset(%iter_133, %int_tuple_152) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
              %167 = cute.static : !cute.int_tuple<"14">
              %ptr_154 = cute.add_offset(%iter_135, %167) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<f32, rmem, align<8>>
              %168 = builtin.unrealized_conversion_cast %ptr_153 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %169 = builtin.unrealized_conversion_cast %ptr_154 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
              %170 = llvm.load %168 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %170, %169 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
            %160 = cute.static : !cute.int_tuple<"15">
            %ptr_151 = cute.add_offset(%iter_136, %160) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<i8, rmem>
            %161 = builtin.unrealized_conversion_cast %ptr_151 : !cute.ptr<i8, rmem> to !llvm.ptr
            %162 = llvm.load %161 : !llvm.ptr -> i8
            %163 = llvm.mlir.constant(0 : i8) : i8
            %164 = llvm.icmp "ne" %162, %163 : i8
            scf.if %164 {
              %c3_i64 = arith.constant 3 : i64
              %165 = arith.muli %85, %c3_i64 : i64
              %c3_i64_152 = arith.constant 3 : i64
              %166 = arith.addi %165, %c3_i64_152 : i64
              %iv_153 = cute.assume(%166) : (i64) -> !cute.i64<divby 3>
              %int_tuple_154 = cute.make_int_tuple(%iv_153) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
              %ptr_155 = cute.add_offset(%iter_133, %int_tuple_154) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
              %167 = cute.static : !cute.int_tuple<"15">
              %ptr_156 = cute.add_offset(%iter_135, %167) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<f32, rmem>
              %168 = builtin.unrealized_conversion_cast %ptr_155 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
              %169 = builtin.unrealized_conversion_cast %ptr_156 : !cute.ptr<f32, rmem> to !llvm.ptr
              %170 = llvm.load %168 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
              llvm.store %170, %169 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
            }
          } {llvm.loop_annotation = #loop_annotation}
        }
      }
      %c10_i32 = arith.constant 10 : i32
      %57:3 = scf.for %arg6 = %c0_i32 to %c10_i32 step %c1_i32 iter_args(%arg7 = %rmem, %arg8 = %rmem_60, %arg9 = %rmem_62) -> (!memref_rmem_f32_, !memref_rmem_f32_, !memref_rmem_f32_)  : i32 {
        %68 = cute.memref.load_vec %arg7 : !memref_rmem_f32_
        %69 = cute.memref.load_vec %arg8 : !memref_rmem_f32_
        %70 = arith.addf %68, %69 : vector<16xf32>
        cute.memref.store_vec %70, %arg9 : !memref_rmem_f32_
        scf.yield %arg7, %arg8, %arg9 : !memref_rmem_f32_, !memref_rmem_f32_, !memref_rmem_f32_
      }
      %iter_76 = cute.get_iter(%57#2) : !memref_rmem_f32_
      %58 = cute.static : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %view_77 = cute.make_view(%iter_76, %58) : !memref_rmem_f32_
      %iter_78 = cute.get_iter(%view_77) : !memref_rmem_f32_
      %view_79 = cute.make_view(%iter_78) : !memref_rmem_f32_1
      %lay_80 = cute.get_layout(%view_57) : !memref_gmem_f32_2
      %59 = cute.static : !cute.layout<"1:0">
      %append = cute.append_to_rank<2> (%lay_80, %59) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">
      %view_81 = cute.make_view(%iter_58, %append) : !memref_gmem_f32_2
      %iter_82 = cute.get_iter(%view_81) : !memref_gmem_f32_2
      %lay_83 = cute.get_layout(%view_81) : !memref_gmem_f32_2
      %60 = cute.get_scalars(%lay_83) <{only_dynamic}> : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %61 = cute.static : !cute.shape<"((1,(4,4)),(1,1))">
      %stride_84 = cute.make_stride(%60) : (i64) -> !cute.stride<"((0,(1,?{i64})),(0,0))">
      %lay_85 = cute.make_layout(%61, %stride_84) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %view_86 = cute.make_view(%iter_82, %lay_85) : !memref_gmem_f32_3
      %62 = cute.static : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %view_87 = cute.make_view(%iter_75, %62) : !memref_rmem_i8_
      %iter_88 = cute.get_iter(%view_87) : !memref_rmem_i8_
      %view_89 = cute.make_view(%iter_88) : !memref_rmem_i8_1
      %63 = cute.static : !cute.layout<"1:0">
      %iter_90 = cute.get_iter(%view_79) : !memref_rmem_f32_1
      %iter_91 = cute.get_iter(%view_86) : !memref_gmem_f32_3
      %lay_92 = cute.get_layout(%view_86) : !memref_gmem_f32_3
      %append_93 = cute.append_to_rank<2> (%lay_92, %63) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">, !cute.layout<"1:0">
      %64 = cute.get_scalars(%append_93) <{only_dynamic}> : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %65 = cute.static : !cute.shape<"((1,(4,4)),((1,1)))">
      %stride_94 = cute.make_stride(%64) : (i64) -> !cute.stride<"((0,(1,?{i64})),((0,0)))">
      %lay_95 = cute.make_layout(%65, %stride_94) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
      %iter_96 = cute.get_iter(%view_89) : !memref_rmem_i8_1
      %66 = cute.static : !cute.int_tuple<"1">
      %67 = cute.get_scalars(%66) : !cute.int_tuple<"1">
      %c0_i32_97 = arith.constant 0 : i32
      %c1_i32_98 = arith.constant 1 : i32
      scf.for %arg6 = %c0_i32_97 to %67 step %c1_i32_98  : i32 {
        %68 = cute.static : !cute.layout<"((1,(4,4))):((0,(1,4)))">
        %69 = cute.static : !cute.int_tuple<"0">
        %ptr_99 = cute.add_offset(%iter_90, %69) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, rmem, align<32>>
        %view_100 = cute.make_view(%ptr_99, %68) : !memref_rmem_f32_2
        %70 = cute.get_scalars(%lay_95) <{only_dynamic}> : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
        %71 = cute.static : !cute.shape<"((1,(4,4)))">
        %stride_101 = cute.make_stride(%70) : (i64) -> !cute.stride<"((0,(1,?{i64})))">
        %lay_102 = cute.make_layout(%71, %stride_101) : !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
        %72 = cute.static : !cute.int_tuple<"0">
        %ptr_103 = cute.add_offset(%iter_91, %72) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<f32, gmem>
        %view_104 = cute.make_view(%ptr_103, %lay_102) : !memref_gmem_f32_4
        %73 = cute.static : !cute.layout<"((1,(4,4))):((0,(1,4)))">
        %74 = cute.static : !cute.int_tuple<"0">
        %ptr_105 = cute.add_offset(%iter_96, %74) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
        %view_106 = cute.make_view(%ptr_105, %73) : !memref_rmem_i8_2
        %iter_107 = cute.get_iter(%view_100) : !memref_rmem_f32_2
        %iter_108 = cute.get_iter(%view_104) : !memref_gmem_f32_4
        %lay_109 = cute.get_layout(%view_104) : !memref_gmem_f32_4
        %75 = cute.get_scalars(%lay_109) <{only_dynamic}> : !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
        %iter_110 = cute.get_iter(%view_106) : !memref_rmem_i8_2
        %76 = builtin.unrealized_conversion_cast %iter_110 : !cute.ptr<i8, rmem, align<32>> to !llvm.ptr
        %77 = llvm.load %76 : !llvm.ptr -> i8
        %78 = llvm.mlir.constant(0 : i8) : i8
        %79 = llvm.icmp "ne" %77, %78 : i8
        scf.if %79 {
          %155 = builtin.unrealized_conversion_cast %iter_107 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
          %156 = builtin.unrealized_conversion_cast %iter_108 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %157 = llvm.load %155 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %157, %156 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %80 = cute.static : !cute.int_tuple<"1">
        %ptr_111 = cute.add_offset(%iter_110, %80) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
        %81 = builtin.unrealized_conversion_cast %ptr_111 : !cute.ptr<i8, rmem> to !llvm.ptr
        %82 = llvm.load %81 : !llvm.ptr -> i8
        %83 = llvm.mlir.constant(0 : i8) : i8
        %84 = llvm.icmp "ne" %82, %83 : i8
        scf.if %84 {
          %155 = cute.static : !cute.int_tuple<"1">
          %ptr_126 = cute.add_offset(%iter_107, %155) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
          %156 = cute.static : !cute.int_tuple<"1">
          %ptr_127 = cute.add_offset(%iter_108, %156) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
          %157 = builtin.unrealized_conversion_cast %ptr_126 : !cute.ptr<f32, rmem> to !llvm.ptr
          %158 = builtin.unrealized_conversion_cast %ptr_127 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %159 = llvm.load %157 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %159, %158 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %85 = cute.static : !cute.int_tuple<"2">
        %ptr_112 = cute.add_offset(%iter_110, %85) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem, align<2>>
        %86 = builtin.unrealized_conversion_cast %ptr_112 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
        %87 = llvm.load %86 : !llvm.ptr -> i8
        %88 = llvm.mlir.constant(0 : i8) : i8
        %89 = llvm.icmp "ne" %87, %88 : i8
        scf.if %89 {
          %155 = cute.static : !cute.int_tuple<"2">
          %ptr_126 = cute.add_offset(%iter_107, %155) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
          %156 = cute.static : !cute.int_tuple<"2">
          %ptr_127 = cute.add_offset(%iter_108, %156) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
          %157 = builtin.unrealized_conversion_cast %ptr_126 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %158 = builtin.unrealized_conversion_cast %ptr_127 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %159 = llvm.load %157 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %159, %158 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %90 = cute.static : !cute.int_tuple<"3">
        %ptr_113 = cute.add_offset(%iter_110, %90) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
        %91 = builtin.unrealized_conversion_cast %ptr_113 : !cute.ptr<i8, rmem> to !llvm.ptr
        %92 = llvm.load %91 : !llvm.ptr -> i8
        %93 = llvm.mlir.constant(0 : i8) : i8
        %94 = llvm.icmp "ne" %92, %93 : i8
        scf.if %94 {
          %155 = cute.static : !cute.int_tuple<"3">
          %ptr_126 = cute.add_offset(%iter_107, %155) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
          %156 = cute.static : !cute.int_tuple<"3">
          %ptr_127 = cute.add_offset(%iter_108, %156) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
          %157 = builtin.unrealized_conversion_cast %ptr_126 : !cute.ptr<f32, rmem> to !llvm.ptr
          %158 = builtin.unrealized_conversion_cast %ptr_127 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %159 = llvm.load %157 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %159, %158 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %95 = cute.static : !cute.int_tuple<"4">
        %ptr_114 = cute.add_offset(%iter_110, %95) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem, align<4>>
        %96 = builtin.unrealized_conversion_cast %ptr_114 : !cute.ptr<i8, rmem, align<4>> to !llvm.ptr
        %97 = llvm.load %96 : !llvm.ptr -> i8
        %98 = llvm.mlir.constant(0 : i8) : i8
        %99 = llvm.icmp "ne" %97, %98 : i8
        scf.if %99 {
          %155 = cute.static : !cute.int_tuple<"4">
          %ptr_126 = cute.add_offset(%iter_107, %155) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
          %int_tuple_127 = cute.make_int_tuple(%75) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_128 = cute.add_offset(%iter_108, %int_tuple_127) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %156 = builtin.unrealized_conversion_cast %ptr_126 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
          %157 = builtin.unrealized_conversion_cast %ptr_128 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %158 = llvm.load %156 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %158, %157 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %100 = cute.static : !cute.int_tuple<"5">
        %ptr_115 = cute.add_offset(%iter_110, %100) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
        %101 = builtin.unrealized_conversion_cast %ptr_115 : !cute.ptr<i8, rmem> to !llvm.ptr
        %102 = llvm.load %101 : !llvm.ptr -> i8
        %103 = llvm.mlir.constant(0 : i8) : i8
        %104 = llvm.icmp "ne" %102, %103 : i8
        scf.if %104 {
          %155 = cute.static : !cute.int_tuple<"5">
          %ptr_126 = cute.add_offset(%iter_107, %155) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<f32, rmem>
          %c1_i64 = arith.constant 1 : i64
          %156 = arith.addi %75, %c1_i64 : i64
          %int_tuple_127 = cute.make_int_tuple(%156) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_128 = cute.add_offset(%iter_108, %int_tuple_127) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %157 = builtin.unrealized_conversion_cast %ptr_126 : !cute.ptr<f32, rmem> to !llvm.ptr
          %158 = builtin.unrealized_conversion_cast %ptr_128 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %159 = llvm.load %157 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %159, %158 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %105 = cute.static : !cute.int_tuple<"6">
        %ptr_116 = cute.add_offset(%iter_110, %105) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem, align<2>>
        %106 = builtin.unrealized_conversion_cast %ptr_116 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
        %107 = llvm.load %106 : !llvm.ptr -> i8
        %108 = llvm.mlir.constant(0 : i8) : i8
        %109 = llvm.icmp "ne" %107, %108 : i8
        scf.if %109 {
          %155 = cute.static : !cute.int_tuple<"6">
          %ptr_126 = cute.add_offset(%iter_107, %155) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
          %c2_i64 = arith.constant 2 : i64
          %156 = arith.addi %75, %c2_i64 : i64
          %int_tuple_127 = cute.make_int_tuple(%156) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_128 = cute.add_offset(%iter_108, %int_tuple_127) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %157 = builtin.unrealized_conversion_cast %ptr_126 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %158 = builtin.unrealized_conversion_cast %ptr_128 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %159 = llvm.load %157 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %159, %158 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %110 = cute.static : !cute.int_tuple<"7">
        %ptr_117 = cute.add_offset(%iter_110, %110) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
        %111 = builtin.unrealized_conversion_cast %ptr_117 : !cute.ptr<i8, rmem> to !llvm.ptr
        %112 = llvm.load %111 : !llvm.ptr -> i8
        %113 = llvm.mlir.constant(0 : i8) : i8
        %114 = llvm.icmp "ne" %112, %113 : i8
        scf.if %114 {
          %155 = cute.static : !cute.int_tuple<"7">
          %ptr_126 = cute.add_offset(%iter_107, %155) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<f32, rmem>
          %c3_i64 = arith.constant 3 : i64
          %156 = arith.addi %75, %c3_i64 : i64
          %int_tuple_127 = cute.make_int_tuple(%156) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_128 = cute.add_offset(%iter_108, %int_tuple_127) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %157 = builtin.unrealized_conversion_cast %ptr_126 : !cute.ptr<f32, rmem> to !llvm.ptr
          %158 = builtin.unrealized_conversion_cast %ptr_128 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %159 = llvm.load %157 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %159, %158 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %115 = cute.static : !cute.int_tuple<"8">
        %ptr_118 = cute.add_offset(%iter_110, %115) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<i8, rmem, align<8>>
        %116 = builtin.unrealized_conversion_cast %ptr_118 : !cute.ptr<i8, rmem, align<8>> to !llvm.ptr
        %117 = llvm.load %116 : !llvm.ptr -> i8
        %118 = llvm.mlir.constant(0 : i8) : i8
        %119 = llvm.icmp "ne" %117, %118 : i8
        scf.if %119 {
          %155 = cute.static : !cute.int_tuple<"8">
          %ptr_126 = cute.add_offset(%iter_107, %155) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<f32, rmem, align<32>>
          %c2_i64 = arith.constant 2 : i64
          %156 = arith.muli %75, %c2_i64 : i64
          %iv_127 = cute.assume(%156) : (i64) -> !cute.i64<divby 2>
          %int_tuple_128 = cute.make_int_tuple(%iv_127) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
          %ptr_129 = cute.add_offset(%iter_108, %int_tuple_128) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
          %157 = builtin.unrealized_conversion_cast %ptr_126 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
          %158 = builtin.unrealized_conversion_cast %ptr_129 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %159 = llvm.load %157 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %159, %158 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %120 = cute.static : !cute.int_tuple<"9">
        %ptr_119 = cute.add_offset(%iter_110, %120) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<i8, rmem>
        %121 = builtin.unrealized_conversion_cast %ptr_119 : !cute.ptr<i8, rmem> to !llvm.ptr
        %122 = llvm.load %121 : !llvm.ptr -> i8
        %123 = llvm.mlir.constant(0 : i8) : i8
        %124 = llvm.icmp "ne" %122, %123 : i8
        scf.if %124 {
          %155 = cute.static : !cute.int_tuple<"9">
          %ptr_126 = cute.add_offset(%iter_107, %155) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<f32, rmem>
          %c2_i64 = arith.constant 2 : i64
          %156 = arith.muli %75, %c2_i64 : i64
          %c1_i64 = arith.constant 1 : i64
          %157 = arith.addi %156, %c1_i64 : i64
          %int_tuple_127 = cute.make_int_tuple(%157) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_128 = cute.add_offset(%iter_108, %int_tuple_127) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %158 = builtin.unrealized_conversion_cast %ptr_126 : !cute.ptr<f32, rmem> to !llvm.ptr
          %159 = builtin.unrealized_conversion_cast %ptr_128 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %160 = llvm.load %158 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %160, %159 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %125 = cute.static : !cute.int_tuple<"10">
        %ptr_120 = cute.add_offset(%iter_110, %125) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<i8, rmem, align<2>>
        %126 = builtin.unrealized_conversion_cast %ptr_120 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
        %127 = llvm.load %126 : !llvm.ptr -> i8
        %128 = llvm.mlir.constant(0 : i8) : i8
        %129 = llvm.icmp "ne" %127, %128 : i8
        scf.if %129 {
          %155 = cute.static : !cute.int_tuple<"10">
          %ptr_126 = cute.add_offset(%iter_107, %155) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<f32, rmem, align<8>>
          %c2_i64 = arith.constant 2 : i64
          %156 = arith.muli %75, %c2_i64 : i64
          %c2_i64_127 = arith.constant 2 : i64
          %157 = arith.addi %156, %c2_i64_127 : i64
          %iv_128 = cute.assume(%157) : (i64) -> !cute.i64<divby 2>
          %int_tuple_129 = cute.make_int_tuple(%iv_128) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
          %ptr_130 = cute.add_offset(%iter_108, %int_tuple_129) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
          %158 = builtin.unrealized_conversion_cast %ptr_126 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %159 = builtin.unrealized_conversion_cast %ptr_130 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %160 = llvm.load %158 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %160, %159 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %130 = cute.static : !cute.int_tuple<"11">
        %ptr_121 = cute.add_offset(%iter_110, %130) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<i8, rmem>
        %131 = builtin.unrealized_conversion_cast %ptr_121 : !cute.ptr<i8, rmem> to !llvm.ptr
        %132 = llvm.load %131 : !llvm.ptr -> i8
        %133 = llvm.mlir.constant(0 : i8) : i8
        %134 = llvm.icmp "ne" %132, %133 : i8
        scf.if %134 {
          %155 = cute.static : !cute.int_tuple<"11">
          %ptr_126 = cute.add_offset(%iter_107, %155) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<f32, rmem>
          %c2_i64 = arith.constant 2 : i64
          %156 = arith.muli %75, %c2_i64 : i64
          %c3_i64 = arith.constant 3 : i64
          %157 = arith.addi %156, %c3_i64 : i64
          %int_tuple_127 = cute.make_int_tuple(%157) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_128 = cute.add_offset(%iter_108, %int_tuple_127) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %158 = builtin.unrealized_conversion_cast %ptr_126 : !cute.ptr<f32, rmem> to !llvm.ptr
          %159 = builtin.unrealized_conversion_cast %ptr_128 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %160 = llvm.load %158 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %160, %159 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %135 = cute.static : !cute.int_tuple<"12">
        %ptr_122 = cute.add_offset(%iter_110, %135) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<i8, rmem, align<4>>
        %136 = builtin.unrealized_conversion_cast %ptr_122 : !cute.ptr<i8, rmem, align<4>> to !llvm.ptr
        %137 = llvm.load %136 : !llvm.ptr -> i8
        %138 = llvm.mlir.constant(0 : i8) : i8
        %139 = llvm.icmp "ne" %137, %138 : i8
        scf.if %139 {
          %155 = cute.static : !cute.int_tuple<"12">
          %ptr_126 = cute.add_offset(%iter_107, %155) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<f32, rmem, align<16>>
          %c3_i64 = arith.constant 3 : i64
          %156 = arith.muli %75, %c3_i64 : i64
          %iv_127 = cute.assume(%156) : (i64) -> !cute.i64<divby 3>
          %int_tuple_128 = cute.make_int_tuple(%iv_127) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
          %ptr_129 = cute.add_offset(%iter_108, %int_tuple_128) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
          %157 = builtin.unrealized_conversion_cast %ptr_126 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
          %158 = builtin.unrealized_conversion_cast %ptr_129 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %159 = llvm.load %157 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %159, %158 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %140 = cute.static : !cute.int_tuple<"13">
        %ptr_123 = cute.add_offset(%iter_110, %140) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<i8, rmem>
        %141 = builtin.unrealized_conversion_cast %ptr_123 : !cute.ptr<i8, rmem> to !llvm.ptr
        %142 = llvm.load %141 : !llvm.ptr -> i8
        %143 = llvm.mlir.constant(0 : i8) : i8
        %144 = llvm.icmp "ne" %142, %143 : i8
        scf.if %144 {
          %155 = cute.static : !cute.int_tuple<"13">
          %ptr_126 = cute.add_offset(%iter_107, %155) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<f32, rmem>
          %c3_i64 = arith.constant 3 : i64
          %156 = arith.muli %75, %c3_i64 : i64
          %c1_i64 = arith.constant 1 : i64
          %157 = arith.addi %156, %c1_i64 : i64
          %int_tuple_127 = cute.make_int_tuple(%157) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_128 = cute.add_offset(%iter_108, %int_tuple_127) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %158 = builtin.unrealized_conversion_cast %ptr_126 : !cute.ptr<f32, rmem> to !llvm.ptr
          %159 = builtin.unrealized_conversion_cast %ptr_128 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %160 = llvm.load %158 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %160, %159 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %145 = cute.static : !cute.int_tuple<"14">
        %ptr_124 = cute.add_offset(%iter_110, %145) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<i8, rmem, align<2>>
        %146 = builtin.unrealized_conversion_cast %ptr_124 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
        %147 = llvm.load %146 : !llvm.ptr -> i8
        %148 = llvm.mlir.constant(0 : i8) : i8
        %149 = llvm.icmp "ne" %147, %148 : i8
        scf.if %149 {
          %155 = cute.static : !cute.int_tuple<"14">
          %ptr_126 = cute.add_offset(%iter_107, %155) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<f32, rmem, align<8>>
          %c3_i64 = arith.constant 3 : i64
          %156 = arith.muli %75, %c3_i64 : i64
          %c2_i64 = arith.constant 2 : i64
          %157 = arith.addi %156, %c2_i64 : i64
          %int_tuple_127 = cute.make_int_tuple(%157) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_128 = cute.add_offset(%iter_108, %int_tuple_127) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %158 = builtin.unrealized_conversion_cast %ptr_126 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %159 = builtin.unrealized_conversion_cast %ptr_128 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %160 = llvm.load %158 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %160, %159 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %150 = cute.static : !cute.int_tuple<"15">
        %ptr_125 = cute.add_offset(%iter_110, %150) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<i8, rmem>
        %151 = builtin.unrealized_conversion_cast %ptr_125 : !cute.ptr<i8, rmem> to !llvm.ptr
        %152 = llvm.load %151 : !llvm.ptr -> i8
        %153 = llvm.mlir.constant(0 : i8) : i8
        %154 = llvm.icmp "ne" %152, %153 : i8
        scf.if %154 {
          %155 = cute.static : !cute.int_tuple<"15">
          %ptr_126 = cute.add_offset(%iter_107, %155) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<f32, rmem>
          %c3_i64 = arith.constant 3 : i64
          %156 = arith.muli %75, %c3_i64 : i64
          %c3_i64_127 = arith.constant 3 : i64
          %157 = arith.addi %156, %c3_i64_127 : i64
          %iv_128 = cute.assume(%157) : (i64) -> !cute.i64<divby 3>
          %int_tuple_129 = cute.make_int_tuple(%iv_128) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
          %ptr_130 = cute.add_offset(%iter_108, %int_tuple_129) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
          %158 = builtin.unrealized_conversion_cast %ptr_126 : !cute.ptr<f32, rmem> to !llvm.ptr
          %159 = builtin.unrealized_conversion_cast %ptr_130 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %160 = llvm.load %158 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %160, %159 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
      } {llvm.loop_annotation = #loop_annotation}
      return
    }
  }
  func.func @cutlass_elementwise_add_Tensorgmem_o_i641_Tensorgmem_o_i641_Tensorgmem_o_i641_CUstream_False_False(%arg0: !memref_gmem_f32_5, %arg1: !memref_gmem_f32_5, %arg2: !memref_gmem_f32_5, %arg3: !cuda.stream) -> i32 attributes {llvm.emit_c_interface} {
    %iter = cute.get_iter(%arg0) : !memref_gmem_f32_5
    %lay = cute.get_layout(%arg0) : !memref_gmem_f32_5
    %0:3 = cute.get_scalars(%lay) <{only_dynamic}> : !cute.layout<"(?,?):(?{i64},1)">
    %c16_i32 = arith.constant 16 : i32
    %1 = arith.ceildivsi %0#0, %c16_i32 : i32
    %c16_i64 = arith.constant 16 : i64
    %2 = arith.muli %0#2, %c16_i64 : i64
    %c128_i32 = arith.constant 128 : i32
    %3 = arith.ceildivsi %0#1, %c128_i32 : i32
    %shape = cute.make_shape(%1, %3) : (i32, i32) -> !cute.shape<"((16,128),(?,?))">
    %iv = cute.assume(%2) : (i64) -> !cute.i64<divby 16>
    %stride = cute.make_stride(%0#2, %iv) : (i64, !cute.i64<divby 16>) -> !cute.stride<"((?{i64},1),(?{i64 div=16},128))">
    %lay_0 = cute.make_layout(%shape, %stride) : !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
    %view = cute.make_view(%iter, %lay_0) : !memref_gmem_f32_
    %iter_1 = cute.get_iter(%arg1) : !memref_gmem_f32_5
    %lay_2 = cute.get_layout(%arg1) : !memref_gmem_f32_5
    %4:3 = cute.get_scalars(%lay_2) <{only_dynamic}> : !cute.layout<"(?,?):(?{i64},1)">
    %c16_i32_3 = arith.constant 16 : i32
    %5 = arith.ceildivsi %4#0, %c16_i32_3 : i32
    %c16_i64_4 = arith.constant 16 : i64
    %6 = arith.muli %4#2, %c16_i64_4 : i64
    %c128_i32_5 = arith.constant 128 : i32
    %7 = arith.ceildivsi %4#1, %c128_i32_5 : i32
    %shape_6 = cute.make_shape(%5, %7) : (i32, i32) -> !cute.shape<"((16,128),(?,?))">
    %iv_7 = cute.assume(%6) : (i64) -> !cute.i64<divby 16>
    %stride_8 = cute.make_stride(%4#2, %iv_7) : (i64, !cute.i64<divby 16>) -> !cute.stride<"((?{i64},1),(?{i64 div=16},128))">
    %lay_9 = cute.make_layout(%shape_6, %stride_8) : !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
    %view_10 = cute.make_view(%iter_1, %lay_9) : !memref_gmem_f32_
    %iter_11 = cute.get_iter(%arg2) : !memref_gmem_f32_5
    %lay_12 = cute.get_layout(%arg2) : !memref_gmem_f32_5
    %8:3 = cute.get_scalars(%lay_12) <{only_dynamic}> : !cute.layout<"(?,?):(?{i64},1)">
    %c16_i32_13 = arith.constant 16 : i32
    %9 = arith.ceildivsi %8#0, %c16_i32_13 : i32
    %c16_i64_14 = arith.constant 16 : i64
    %10 = arith.muli %8#2, %c16_i64_14 : i64
    %c128_i32_15 = arith.constant 128 : i32
    %11 = arith.ceildivsi %8#1, %c128_i32_15 : i32
    %shape_16 = cute.make_shape(%9, %11) : (i32, i32) -> !cute.shape<"((16,128),(?,?))">
    %iv_17 = cute.assume(%10) : (i64) -> !cute.i64<divby 16>
    %stride_18 = cute.make_stride(%8#2, %iv_17) : (i64, !cute.i64<divby 16>) -> !cute.stride<"((?{i64},1),(?{i64 div=16},128))">
    %lay_19 = cute.make_layout(%shape_16, %stride_18) : !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
    %view_20 = cute.make_view(%iter_11, %lay_19) : !memref_gmem_f32_
    %lay_21 = cute.get_layout(%arg2) : !memref_gmem_f32_5
    %12 = cute.get_shape(%lay_21) : (!cute.layout<"(?,?):(?{i64},1)">) -> !cute.shape<"(?,?)">
    %e0, %e1 = cute.get_leaves(%12) : !cute.shape<"(?,?)">
    %itup = cute.to_int_tuple(%e0) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %13 = cute.get_scalars(%itup) : !cute.int_tuple<"?">
    %itup_22 = cute.to_int_tuple(%e1) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %14 = cute.get_scalars(%itup_22) : !cute.int_tuple<"?">
    %shape_23 = cute.make_shape(%itup, %itup_22) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.shape<"(?,?)">
    %15 = cute.static : !cute.int_tuple<"(0,0)">
    %16 = cute.static : !cute.stride<"(1@0,1@1)">
    %lay_24 = cute.make_layout(%shape_23, %16) : !cute.layout<"(?,?):(1@0,1@1)">
    %view_25 = cute.make_view(%15, %lay_24) : !cute.coord_tensor<"(0,0)", "(?,?):(1@0,1@1)">
    %17 = cute.static : !cute.int_tuple<"(0,0)">
    %lay_26 = cute.get_layout(%view_25) : !cute.coord_tensor<"(0,0)", "(?,?):(1@0,1@1)">
    %18:2 = cute.get_scalars(%lay_26) <{only_dynamic}> : !cute.layout<"(?,?):(1@0,1@1)">
    %c16_i32_27 = arith.constant 16 : i32
    %19 = arith.ceildivsi %18#0, %c16_i32_27 : i32
    %c128_i32_28 = arith.constant 128 : i32
    %20 = arith.ceildivsi %18#1, %c128_i32_28 : i32
    %shape_29 = cute.make_shape(%19, %20) : (i32, i32) -> !cute.shape<"((16,128),(?,?))">
    %21 = cute.static : !cute.stride<"((1@0,1@1),(16@0,128@1))">
    %lay_30 = cute.make_layout(%shape_29, %21) : !cute.layout<"((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
    %view_31 = cute.make_view(%17, %lay_30) : !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
    %lay_32 = cute.get_layout(%view_20) : !memref_gmem_f32_
    %sz = cute.size(%lay_32) <{mode = [1]}> : (!cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.int_tuple<"?">
    %e0_33 = cute.get_leaves(%sz) : !cute.int_tuple<"?">
    %22 = cute.get_scalars(%e0_33) : !cute.int_tuple<"?">
    %c0_i32 = arith.constant 0 : i32
    %23 = arith.extsi %c0_i32 : i32 to i64
    %c128_i32_34 = arith.constant 128 : i32
    %c1_i32 = arith.constant 1 : i32
    %24 = cuda.launch_cfg.create<max_attrs = 2 : i32> (blockDim = (%c128_i32_34, %c1_i32, %c1_i32), dynamicSmemBytes = %23, gridDim = (%22, %c1_i32, %c1_i32), stream = %arg3) : i32, i32, i32, i64, i32, i32, i32, !cuda.stream -> !cuda.launch_cfg<max_attrs = 2>
    %25 = cuda.launch_ex @kernels::@kernel_cutlass_elementwise_add_kernel_tensorptrf32gmemo161281i64div16128_tensorptrf32gmemo161281i64div16128_tensorptrf32gmemo161281i64div16128_tensor00o1612810111601281___False_0<%24> (%view, %view_10, %view_20, %view_31, %13, %14) : !cuda.launch_cfg<max_attrs = 2>, (!memref_gmem_f32_, !memref_gmem_f32_, !memref_gmem_f32_, !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">, i32, i32) -> !cuda.result
    %26 = cuda.cast %25 : !cuda.result -> i32
    cuda.return_if_error %26 : i32
    %c0_i32_35 = arith.constant 0 : i32
    return %c0_i32_35 : i32
  }
}
