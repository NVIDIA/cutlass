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
    func.func public @kernel_cutlass_elementwise_add_kernel_tensorptrf32gmemo161281div16128_tensorptrf32gmemo161281div16128_tensorptrf32gmemo161281div16128_tensor00o1612810111601281___0(%arg0: !memref_gmem_f32_, %arg1: !memref_gmem_f32_, %arg2: !memref_gmem_f32_, %arg3: !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">, %arg4: i32, %arg5: i32) attributes {cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} {
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
      %iter_63 = cute.get_iter(%rmem_62) : !memref_rmem_f32_
      %coord_64 = cute.make_coord(%2) : (i32) -> !cute.coord<"?">
      %iter_65 = cute.get_iter(%view_20) : !cute.coord_tensor<"(?{div=16},?{div=128})", "(16,128):(1@0,1@1)">
      %50 = cute.get_scalars(%coord_64) <{only_dynamic}> : !cute.coord<"?">
      %c32_i32_66 = arith.constant 32 : i32
      %51 = arith.divsi %50, %c32_i32_66 : i32
      %c32_i32_67 = arith.constant 32 : i32
      %52 = arith.remsi %50, %c32_i32_67 : i32
      %c4_i32_68 = arith.constant 4 : i32
      %53 = arith.muli %52, %c4_i32_68 : i32
      %c4_i32_69 = arith.constant 4 : i32
      %54 = arith.muli %51, %c4_i32_69 : i32
      %iv_70 = cute.assume(%54) : (i32) -> !cute.i32<divby 4>
      %iv_71 = cute.assume(%53) : (i32) -> !cute.i32<divby 4>
      %int_tuple_72 = cute.make_int_tuple(%iv_70, %iv_71) : (!cute.i32<divby 4>, !cute.i32<divby 4>) -> !cute.int_tuple<"(?{div=4},?{div=4})">
      %tup_73 = cute.add_offset(%iter_65, %int_tuple_72) : (!cute.int_tuple<"(?{div=16},?{div=128})">, !cute.int_tuple<"(?{div=4},?{div=4})">) -> !cute.int_tuple<"(?{div=4},?{div=4})">
      %view_74 = cute.make_view(%tup_73) : !cute.coord_tensor<"(?{div=4},?{div=4})", "((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">
      %55 = cute.static : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %rmem_75 = cute.memref.alloca(%55) : !memref_rmem_i8_
      %c0_i32 = arith.constant 0 : i32
      %c16_i32 = arith.constant 16 : i32
      %c1_i32 = arith.constant 1 : i32
      %56 = scf.for %arg6 = %c0_i32 to %c16_i32 step %c1_i32 iter_args(%arg7 = %rmem_75) -> (!memref_rmem_i8_)  : i32 {
        %coord_145 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"?">
        %90 = cute.static : !cute.layout<"((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">
        %idx_146 = cute.crd2idx(%coord_145, %90) : (!cute.coord<"?">, !cute.layout<"((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">) -> !cute.int_tuple<"(?,?)">
        %iter_147 = cute.get_iter(%view_74) : !cute.coord_tensor<"(?{div=4},?{div=4})", "((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">
        %tup_148 = cute.add_offset(%iter_147, %idx_146) : (!cute.int_tuple<"(?{div=4},?{div=4})">, !cute.int_tuple<"(?,?)">) -> !cute.int_tuple<"(?,?)">
        %view_149 = cute.make_view(%tup_148) : !cute.coord_tensor<"(?,?)", "():()">
        %iter_150 = cute.get_iter(%view_149) : !cute.coord_tensor<"(?,?)", "():()">
        %e0, %e1 = cute.get_leaves(%iter_150) : !cute.int_tuple<"(?,?)">
        %coord_151 = cute.make_coord(%e0, %e1) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
        %coord_152 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
        %91:2 = cute.get_scalars(%coord_151) : !cute.coord<"(?,?)">
        %92:2 = cute.get_scalars(%coord_152) : !cute.coord<"(?,?)">
        %true = arith.constant true
        %93 = arith.cmpi slt, %91#0, %92#0 : i32
        %94 = arith.andi %true, %93 : i1
        %95 = arith.cmpi slt, %91#1, %92#1 : i32
        %96 = arith.andi %94, %95 : i1
        %97 = arith.extui %96 : i1 to i8
        %coord_153 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"?">
        cute.memref.store(%arg7, %coord_153, %97) : (!memref_rmem_i8_, !cute.coord<"?">, i8) -> ()
        scf.yield %arg7 : !memref_rmem_i8_
      }
      %iter_76 = cute.get_iter(%56) : !memref_rmem_i8_
      %lay_77 = cute.get_layout(%view_29) : !memref_gmem_f32_2
      %57 = cute.static : !cute.layout<"1:0">
      %append = cute.append_to_rank<2> (%lay_77, %57) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">
      %view_78 = cute.make_view(%iter_30, %append) : !memref_gmem_f32_2
      %iter_79 = cute.get_iter(%view_78) : !memref_gmem_f32_2
      %lay_80 = cute.get_layout(%view_78) : !memref_gmem_f32_2
      %58 = cute.get_scalars(%lay_80) <{only_dynamic}> : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %59 = cute.static : !cute.shape<"((1,(4,4)),(1,1))">
      %stride_81 = cute.make_stride(%58) : (i64) -> !cute.stride<"((0,(1,?{i64})),(0,0))">
      %lay_82 = cute.make_layout(%59, %stride_81) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %view_83 = cute.make_view(%iter_79, %lay_82) : !memref_gmem_f32_3
      %60 = cute.static : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %view_84 = cute.make_view(%iter_59, %60) : !memref_rmem_f32_
      %iter_85 = cute.get_iter(%view_84) : !memref_rmem_f32_
      %view_86 = cute.make_view(%iter_85) : !memref_rmem_f32_1
      %61 = cute.static : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %view_87 = cute.make_view(%iter_76, %61) : !memref_rmem_i8_
      %iter_88 = cute.get_iter(%view_87) : !memref_rmem_i8_
      %view_89 = cute.make_view(%iter_88) : !memref_rmem_i8_1
      %62 = cute.static : !cute.layout<"1:0">
      %iter_90 = cute.get_iter(%view_83) : !memref_gmem_f32_3
      %iter_91 = cute.get_iter(%view_86) : !memref_rmem_f32_1
      %lay_92 = cute.get_layout(%view_83) : !memref_gmem_f32_3
      %append_93 = cute.append_to_rank<2> (%lay_92, %62) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">, !cute.layout<"1:0">
      %63 = cute.get_scalars(%append_93) <{only_dynamic}> : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %64 = cute.static : !cute.shape<"((1,(4,4)),((1,1)))">
      %stride_94 = cute.make_stride(%63) : (i64) -> !cute.stride<"((0,(1,?{i64})),((0,0)))">
      %lay_95 = cute.make_layout(%64, %stride_94) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
      %iter_96 = cute.get_iter(%view_89) : !memref_rmem_i8_1
      %65 = cute.static : !cute.int_tuple<"1">
      %66 = cute.get_scalars(%65) : !cute.int_tuple<"1">
      %c0_i32_97 = arith.constant 0 : i32
      %c1_i32_98 = arith.constant 1 : i32
      scf.for %arg6 = %c0_i32_97 to %66 step %c1_i32_98  : i32 {
        %90 = cute.get_scalars(%lay_95) <{only_dynamic}> : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
        %91 = cute.static : !cute.shape<"((1,(4,4)))">
        %stride_145 = cute.make_stride(%90) : (i64) -> !cute.stride<"((0,(1,?{i64})))">
        %lay_146 = cute.make_layout(%91, %stride_145) : !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
        %92 = cute.static : !cute.int_tuple<"0">
        %ptr_147 = cute.add_offset(%iter_90, %92) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<f32, gmem>
        %view_148 = cute.make_view(%ptr_147, %lay_146) : !memref_gmem_f32_4
        %93 = cute.static : !cute.layout<"((1,(4,4))):((0,(1,4)))">
        %94 = cute.static : !cute.int_tuple<"0">
        %ptr_149 = cute.add_offset(%iter_91, %94) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, rmem, align<32>>
        %view_150 = cute.make_view(%ptr_149, %93) : !memref_rmem_f32_2
        %95 = cute.static : !cute.layout<"((1,(4,4))):((0,(1,4)))">
        %96 = cute.static : !cute.int_tuple<"0">
        %ptr_151 = cute.add_offset(%iter_96, %96) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
        %view_152 = cute.make_view(%ptr_151, %95) : !memref_rmem_i8_2
        %iter_153 = cute.get_iter(%view_148) : !memref_gmem_f32_4
        %lay_154 = cute.get_layout(%view_148) : !memref_gmem_f32_4
        %97 = cute.get_scalars(%lay_154) <{only_dynamic}> : !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
        %iter_155 = cute.get_iter(%view_150) : !memref_rmem_f32_2
        %iter_156 = cute.get_iter(%view_152) : !memref_rmem_i8_2
        %98 = builtin.unrealized_conversion_cast %iter_156 : !cute.ptr<i8, rmem, align<32>> to !llvm.ptr
        %99 = llvm.load %98 : !llvm.ptr -> i8
        %100 = llvm.mlir.constant(0 : i8) : i8
        %101 = llvm.icmp "ne" %99, %100 : i8
        scf.if %101 {
          %177 = builtin.unrealized_conversion_cast %iter_153 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %178 = builtin.unrealized_conversion_cast %iter_155 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
          %179 = llvm.load %177 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %179, %178 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %102 = cute.static : !cute.int_tuple<"1">
        %ptr_157 = cute.add_offset(%iter_156, %102) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
        %103 = builtin.unrealized_conversion_cast %ptr_157 : !cute.ptr<i8, rmem> to !llvm.ptr
        %104 = llvm.load %103 : !llvm.ptr -> i8
        %105 = llvm.mlir.constant(0 : i8) : i8
        %106 = llvm.icmp "ne" %104, %105 : i8
        scf.if %106 {
          %177 = cute.static : !cute.int_tuple<"1">
          %ptr_172 = cute.add_offset(%iter_153, %177) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
          %178 = cute.static : !cute.int_tuple<"1">
          %ptr_173 = cute.add_offset(%iter_155, %178) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
          %179 = builtin.unrealized_conversion_cast %ptr_172 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %180 = builtin.unrealized_conversion_cast %ptr_173 : !cute.ptr<f32, rmem> to !llvm.ptr
          %181 = llvm.load %179 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %181, %180 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %107 = cute.static : !cute.int_tuple<"2">
        %ptr_158 = cute.add_offset(%iter_156, %107) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem, align<2>>
        %108 = builtin.unrealized_conversion_cast %ptr_158 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
        %109 = llvm.load %108 : !llvm.ptr -> i8
        %110 = llvm.mlir.constant(0 : i8) : i8
        %111 = llvm.icmp "ne" %109, %110 : i8
        scf.if %111 {
          %177 = cute.static : !cute.int_tuple<"2">
          %ptr_172 = cute.add_offset(%iter_153, %177) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
          %178 = cute.static : !cute.int_tuple<"2">
          %ptr_173 = cute.add_offset(%iter_155, %178) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
          %179 = builtin.unrealized_conversion_cast %ptr_172 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %180 = builtin.unrealized_conversion_cast %ptr_173 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %181 = llvm.load %179 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %181, %180 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %112 = cute.static : !cute.int_tuple<"3">
        %ptr_159 = cute.add_offset(%iter_156, %112) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
        %113 = builtin.unrealized_conversion_cast %ptr_159 : !cute.ptr<i8, rmem> to !llvm.ptr
        %114 = llvm.load %113 : !llvm.ptr -> i8
        %115 = llvm.mlir.constant(0 : i8) : i8
        %116 = llvm.icmp "ne" %114, %115 : i8
        scf.if %116 {
          %177 = cute.static : !cute.int_tuple<"3">
          %ptr_172 = cute.add_offset(%iter_153, %177) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
          %178 = cute.static : !cute.int_tuple<"3">
          %ptr_173 = cute.add_offset(%iter_155, %178) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
          %179 = builtin.unrealized_conversion_cast %ptr_172 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %180 = builtin.unrealized_conversion_cast %ptr_173 : !cute.ptr<f32, rmem> to !llvm.ptr
          %181 = llvm.load %179 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %181, %180 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %117 = cute.static : !cute.int_tuple<"4">
        %ptr_160 = cute.add_offset(%iter_156, %117) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem, align<4>>
        %118 = builtin.unrealized_conversion_cast %ptr_160 : !cute.ptr<i8, rmem, align<4>> to !llvm.ptr
        %119 = llvm.load %118 : !llvm.ptr -> i8
        %120 = llvm.mlir.constant(0 : i8) : i8
        %121 = llvm.icmp "ne" %119, %120 : i8
        scf.if %121 {
          %int_tuple_172 = cute.make_int_tuple(%97) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_173 = cute.add_offset(%iter_153, %int_tuple_172) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %177 = cute.static : !cute.int_tuple<"4">
          %ptr_174 = cute.add_offset(%iter_155, %177) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
          %178 = builtin.unrealized_conversion_cast %ptr_173 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %179 = builtin.unrealized_conversion_cast %ptr_174 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
          %180 = llvm.load %178 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %180, %179 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %122 = cute.static : !cute.int_tuple<"5">
        %ptr_161 = cute.add_offset(%iter_156, %122) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
        %123 = builtin.unrealized_conversion_cast %ptr_161 : !cute.ptr<i8, rmem> to !llvm.ptr
        %124 = llvm.load %123 : !llvm.ptr -> i8
        %125 = llvm.mlir.constant(0 : i8) : i8
        %126 = llvm.icmp "ne" %124, %125 : i8
        scf.if %126 {
          %c1_i64 = arith.constant 1 : i64
          %177 = arith.addi %97, %c1_i64 : i64
          %int_tuple_172 = cute.make_int_tuple(%177) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_173 = cute.add_offset(%iter_153, %int_tuple_172) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %178 = cute.static : !cute.int_tuple<"5">
          %ptr_174 = cute.add_offset(%iter_155, %178) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<f32, rmem>
          %179 = builtin.unrealized_conversion_cast %ptr_173 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %180 = builtin.unrealized_conversion_cast %ptr_174 : !cute.ptr<f32, rmem> to !llvm.ptr
          %181 = llvm.load %179 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %181, %180 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %127 = cute.static : !cute.int_tuple<"6">
        %ptr_162 = cute.add_offset(%iter_156, %127) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem, align<2>>
        %128 = builtin.unrealized_conversion_cast %ptr_162 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
        %129 = llvm.load %128 : !llvm.ptr -> i8
        %130 = llvm.mlir.constant(0 : i8) : i8
        %131 = llvm.icmp "ne" %129, %130 : i8
        scf.if %131 {
          %c2_i64 = arith.constant 2 : i64
          %177 = arith.addi %97, %c2_i64 : i64
          %int_tuple_172 = cute.make_int_tuple(%177) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_173 = cute.add_offset(%iter_153, %int_tuple_172) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %178 = cute.static : !cute.int_tuple<"6">
          %ptr_174 = cute.add_offset(%iter_155, %178) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
          %179 = builtin.unrealized_conversion_cast %ptr_173 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %180 = builtin.unrealized_conversion_cast %ptr_174 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %181 = llvm.load %179 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %181, %180 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %132 = cute.static : !cute.int_tuple<"7">
        %ptr_163 = cute.add_offset(%iter_156, %132) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
        %133 = builtin.unrealized_conversion_cast %ptr_163 : !cute.ptr<i8, rmem> to !llvm.ptr
        %134 = llvm.load %133 : !llvm.ptr -> i8
        %135 = llvm.mlir.constant(0 : i8) : i8
        %136 = llvm.icmp "ne" %134, %135 : i8
        scf.if %136 {
          %c3_i64 = arith.constant 3 : i64
          %177 = arith.addi %97, %c3_i64 : i64
          %int_tuple_172 = cute.make_int_tuple(%177) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_173 = cute.add_offset(%iter_153, %int_tuple_172) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %178 = cute.static : !cute.int_tuple<"7">
          %ptr_174 = cute.add_offset(%iter_155, %178) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<f32, rmem>
          %179 = builtin.unrealized_conversion_cast %ptr_173 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %180 = builtin.unrealized_conversion_cast %ptr_174 : !cute.ptr<f32, rmem> to !llvm.ptr
          %181 = llvm.load %179 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %181, %180 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %137 = cute.static : !cute.int_tuple<"8">
        %ptr_164 = cute.add_offset(%iter_156, %137) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<i8, rmem, align<8>>
        %138 = builtin.unrealized_conversion_cast %ptr_164 : !cute.ptr<i8, rmem, align<8>> to !llvm.ptr
        %139 = llvm.load %138 : !llvm.ptr -> i8
        %140 = llvm.mlir.constant(0 : i8) : i8
        %141 = llvm.icmp "ne" %139, %140 : i8
        scf.if %141 {
          %c2_i64 = arith.constant 2 : i64
          %177 = arith.muli %97, %c2_i64 : i64
          %iv_172 = cute.assume(%177) : (i64) -> !cute.i64<divby 2>
          %int_tuple_173 = cute.make_int_tuple(%iv_172) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
          %ptr_174 = cute.add_offset(%iter_153, %int_tuple_173) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
          %178 = cute.static : !cute.int_tuple<"8">
          %ptr_175 = cute.add_offset(%iter_155, %178) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<f32, rmem, align<32>>
          %179 = builtin.unrealized_conversion_cast %ptr_174 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %180 = builtin.unrealized_conversion_cast %ptr_175 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
          %181 = llvm.load %179 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %181, %180 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %142 = cute.static : !cute.int_tuple<"9">
        %ptr_165 = cute.add_offset(%iter_156, %142) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<i8, rmem>
        %143 = builtin.unrealized_conversion_cast %ptr_165 : !cute.ptr<i8, rmem> to !llvm.ptr
        %144 = llvm.load %143 : !llvm.ptr -> i8
        %145 = llvm.mlir.constant(0 : i8) : i8
        %146 = llvm.icmp "ne" %144, %145 : i8
        scf.if %146 {
          %c2_i64 = arith.constant 2 : i64
          %177 = arith.muli %97, %c2_i64 : i64
          %c1_i64 = arith.constant 1 : i64
          %178 = arith.addi %177, %c1_i64 : i64
          %int_tuple_172 = cute.make_int_tuple(%178) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_173 = cute.add_offset(%iter_153, %int_tuple_172) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %179 = cute.static : !cute.int_tuple<"9">
          %ptr_174 = cute.add_offset(%iter_155, %179) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<f32, rmem>
          %180 = builtin.unrealized_conversion_cast %ptr_173 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %181 = builtin.unrealized_conversion_cast %ptr_174 : !cute.ptr<f32, rmem> to !llvm.ptr
          %182 = llvm.load %180 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %182, %181 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %147 = cute.static : !cute.int_tuple<"10">
        %ptr_166 = cute.add_offset(%iter_156, %147) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<i8, rmem, align<2>>
        %148 = builtin.unrealized_conversion_cast %ptr_166 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
        %149 = llvm.load %148 : !llvm.ptr -> i8
        %150 = llvm.mlir.constant(0 : i8) : i8
        %151 = llvm.icmp "ne" %149, %150 : i8
        scf.if %151 {
          %c2_i64 = arith.constant 2 : i64
          %177 = arith.muli %97, %c2_i64 : i64
          %c2_i64_172 = arith.constant 2 : i64
          %178 = arith.addi %177, %c2_i64_172 : i64
          %iv_173 = cute.assume(%178) : (i64) -> !cute.i64<divby 2>
          %int_tuple_174 = cute.make_int_tuple(%iv_173) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
          %ptr_175 = cute.add_offset(%iter_153, %int_tuple_174) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
          %179 = cute.static : !cute.int_tuple<"10">
          %ptr_176 = cute.add_offset(%iter_155, %179) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<f32, rmem, align<8>>
          %180 = builtin.unrealized_conversion_cast %ptr_175 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %181 = builtin.unrealized_conversion_cast %ptr_176 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %182 = llvm.load %180 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %182, %181 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %152 = cute.static : !cute.int_tuple<"11">
        %ptr_167 = cute.add_offset(%iter_156, %152) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<i8, rmem>
        %153 = builtin.unrealized_conversion_cast %ptr_167 : !cute.ptr<i8, rmem> to !llvm.ptr
        %154 = llvm.load %153 : !llvm.ptr -> i8
        %155 = llvm.mlir.constant(0 : i8) : i8
        %156 = llvm.icmp "ne" %154, %155 : i8
        scf.if %156 {
          %c2_i64 = arith.constant 2 : i64
          %177 = arith.muli %97, %c2_i64 : i64
          %c3_i64 = arith.constant 3 : i64
          %178 = arith.addi %177, %c3_i64 : i64
          %int_tuple_172 = cute.make_int_tuple(%178) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_173 = cute.add_offset(%iter_153, %int_tuple_172) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %179 = cute.static : !cute.int_tuple<"11">
          %ptr_174 = cute.add_offset(%iter_155, %179) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<f32, rmem>
          %180 = builtin.unrealized_conversion_cast %ptr_173 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %181 = builtin.unrealized_conversion_cast %ptr_174 : !cute.ptr<f32, rmem> to !llvm.ptr
          %182 = llvm.load %180 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %182, %181 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %157 = cute.static : !cute.int_tuple<"12">
        %ptr_168 = cute.add_offset(%iter_156, %157) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<i8, rmem, align<4>>
        %158 = builtin.unrealized_conversion_cast %ptr_168 : !cute.ptr<i8, rmem, align<4>> to !llvm.ptr
        %159 = llvm.load %158 : !llvm.ptr -> i8
        %160 = llvm.mlir.constant(0 : i8) : i8
        %161 = llvm.icmp "ne" %159, %160 : i8
        scf.if %161 {
          %c3_i64 = arith.constant 3 : i64
          %177 = arith.muli %97, %c3_i64 : i64
          %iv_172 = cute.assume(%177) : (i64) -> !cute.i64<divby 3>
          %int_tuple_173 = cute.make_int_tuple(%iv_172) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
          %ptr_174 = cute.add_offset(%iter_153, %int_tuple_173) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
          %178 = cute.static : !cute.int_tuple<"12">
          %ptr_175 = cute.add_offset(%iter_155, %178) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<f32, rmem, align<16>>
          %179 = builtin.unrealized_conversion_cast %ptr_174 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %180 = builtin.unrealized_conversion_cast %ptr_175 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
          %181 = llvm.load %179 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %181, %180 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %162 = cute.static : !cute.int_tuple<"13">
        %ptr_169 = cute.add_offset(%iter_156, %162) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<i8, rmem>
        %163 = builtin.unrealized_conversion_cast %ptr_169 : !cute.ptr<i8, rmem> to !llvm.ptr
        %164 = llvm.load %163 : !llvm.ptr -> i8
        %165 = llvm.mlir.constant(0 : i8) : i8
        %166 = llvm.icmp "ne" %164, %165 : i8
        scf.if %166 {
          %c3_i64 = arith.constant 3 : i64
          %177 = arith.muli %97, %c3_i64 : i64
          %c1_i64 = arith.constant 1 : i64
          %178 = arith.addi %177, %c1_i64 : i64
          %int_tuple_172 = cute.make_int_tuple(%178) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_173 = cute.add_offset(%iter_153, %int_tuple_172) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %179 = cute.static : !cute.int_tuple<"13">
          %ptr_174 = cute.add_offset(%iter_155, %179) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<f32, rmem>
          %180 = builtin.unrealized_conversion_cast %ptr_173 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %181 = builtin.unrealized_conversion_cast %ptr_174 : !cute.ptr<f32, rmem> to !llvm.ptr
          %182 = llvm.load %180 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %182, %181 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %167 = cute.static : !cute.int_tuple<"14">
        %ptr_170 = cute.add_offset(%iter_156, %167) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<i8, rmem, align<2>>
        %168 = builtin.unrealized_conversion_cast %ptr_170 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
        %169 = llvm.load %168 : !llvm.ptr -> i8
        %170 = llvm.mlir.constant(0 : i8) : i8
        %171 = llvm.icmp "ne" %169, %170 : i8
        scf.if %171 {
          %c3_i64 = arith.constant 3 : i64
          %177 = arith.muli %97, %c3_i64 : i64
          %c2_i64 = arith.constant 2 : i64
          %178 = arith.addi %177, %c2_i64 : i64
          %int_tuple_172 = cute.make_int_tuple(%178) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_173 = cute.add_offset(%iter_153, %int_tuple_172) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %179 = cute.static : !cute.int_tuple<"14">
          %ptr_174 = cute.add_offset(%iter_155, %179) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<f32, rmem, align<8>>
          %180 = builtin.unrealized_conversion_cast %ptr_173 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %181 = builtin.unrealized_conversion_cast %ptr_174 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %182 = llvm.load %180 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %182, %181 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %172 = cute.static : !cute.int_tuple<"15">
        %ptr_171 = cute.add_offset(%iter_156, %172) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<i8, rmem>
        %173 = builtin.unrealized_conversion_cast %ptr_171 : !cute.ptr<i8, rmem> to !llvm.ptr
        %174 = llvm.load %173 : !llvm.ptr -> i8
        %175 = llvm.mlir.constant(0 : i8) : i8
        %176 = llvm.icmp "ne" %174, %175 : i8
        scf.if %176 {
          %c3_i64 = arith.constant 3 : i64
          %177 = arith.muli %97, %c3_i64 : i64
          %c3_i64_172 = arith.constant 3 : i64
          %178 = arith.addi %177, %c3_i64_172 : i64
          %iv_173 = cute.assume(%178) : (i64) -> !cute.i64<divby 3>
          %int_tuple_174 = cute.make_int_tuple(%iv_173) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
          %ptr_175 = cute.add_offset(%iter_153, %int_tuple_174) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
          %179 = cute.static : !cute.int_tuple<"15">
          %ptr_176 = cute.add_offset(%iter_155, %179) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<f32, rmem>
          %180 = builtin.unrealized_conversion_cast %ptr_175 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %181 = builtin.unrealized_conversion_cast %ptr_176 : !cute.ptr<f32, rmem> to !llvm.ptr
          %182 = llvm.load %180 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %182, %181 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
      } {llvm.loop_annotation = #loop_annotation}
      %lay_99 = cute.get_layout(%view_43) : !memref_gmem_f32_2
      %67 = cute.static : !cute.layout<"1:0">
      %append_100 = cute.append_to_rank<2> (%lay_99, %67) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">
      %view_101 = cute.make_view(%iter_44, %append_100) : !memref_gmem_f32_2
      %iter_102 = cute.get_iter(%view_101) : !memref_gmem_f32_2
      %lay_103 = cute.get_layout(%view_101) : !memref_gmem_f32_2
      %68 = cute.get_scalars(%lay_103) <{only_dynamic}> : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %69 = cute.static : !cute.shape<"((1,(4,4)),(1,1))">
      %stride_104 = cute.make_stride(%68) : (i64) -> !cute.stride<"((0,(1,?{i64})),(0,0))">
      %lay_105 = cute.make_layout(%69, %stride_104) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %view_106 = cute.make_view(%iter_102, %lay_105) : !memref_gmem_f32_3
      %70 = cute.static : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %view_107 = cute.make_view(%iter_61, %70) : !memref_rmem_f32_
      %iter_108 = cute.get_iter(%view_107) : !memref_rmem_f32_
      %view_109 = cute.make_view(%iter_108) : !memref_rmem_f32_1
      %71 = cute.static : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %view_110 = cute.make_view(%iter_76, %71) : !memref_rmem_i8_
      %iter_111 = cute.get_iter(%view_110) : !memref_rmem_i8_
      %view_112 = cute.make_view(%iter_111) : !memref_rmem_i8_1
      %72 = cute.static : !cute.layout<"1:0">
      %iter_113 = cute.get_iter(%view_106) : !memref_gmem_f32_3
      %iter_114 = cute.get_iter(%view_109) : !memref_rmem_f32_1
      %lay_115 = cute.get_layout(%view_106) : !memref_gmem_f32_3
      %append_116 = cute.append_to_rank<2> (%lay_115, %72) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">, !cute.layout<"1:0">
      %73 = cute.get_scalars(%append_116) <{only_dynamic}> : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %74 = cute.static : !cute.shape<"((1,(4,4)),((1,1)))">
      %stride_117 = cute.make_stride(%73) : (i64) -> !cute.stride<"((0,(1,?{i64})),((0,0)))">
      %lay_118 = cute.make_layout(%74, %stride_117) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
      %iter_119 = cute.get_iter(%view_112) : !memref_rmem_i8_1
      %75 = cute.static : !cute.int_tuple<"1">
      %76 = cute.get_scalars(%75) : !cute.int_tuple<"1">
      %c0_i32_120 = arith.constant 0 : i32
      %c1_i32_121 = arith.constant 1 : i32
      scf.for %arg6 = %c0_i32_120 to %76 step %c1_i32_121  : i32 {
        %90 = cute.get_scalars(%lay_118) <{only_dynamic}> : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
        %91 = cute.static : !cute.shape<"((1,(4,4)))">
        %stride_145 = cute.make_stride(%90) : (i64) -> !cute.stride<"((0,(1,?{i64})))">
        %lay_146 = cute.make_layout(%91, %stride_145) : !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
        %92 = cute.static : !cute.int_tuple<"0">
        %ptr_147 = cute.add_offset(%iter_113, %92) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<f32, gmem>
        %view_148 = cute.make_view(%ptr_147, %lay_146) : !memref_gmem_f32_4
        %93 = cute.static : !cute.layout<"((1,(4,4))):((0,(1,4)))">
        %94 = cute.static : !cute.int_tuple<"0">
        %ptr_149 = cute.add_offset(%iter_114, %94) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, rmem, align<32>>
        %view_150 = cute.make_view(%ptr_149, %93) : !memref_rmem_f32_2
        %95 = cute.static : !cute.layout<"((1,(4,4))):((0,(1,4)))">
        %96 = cute.static : !cute.int_tuple<"0">
        %ptr_151 = cute.add_offset(%iter_119, %96) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
        %view_152 = cute.make_view(%ptr_151, %95) : !memref_rmem_i8_2
        %iter_153 = cute.get_iter(%view_148) : !memref_gmem_f32_4
        %lay_154 = cute.get_layout(%view_148) : !memref_gmem_f32_4
        %97 = cute.get_scalars(%lay_154) <{only_dynamic}> : !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
        %iter_155 = cute.get_iter(%view_150) : !memref_rmem_f32_2
        %iter_156 = cute.get_iter(%view_152) : !memref_rmem_i8_2
        %98 = builtin.unrealized_conversion_cast %iter_156 : !cute.ptr<i8, rmem, align<32>> to !llvm.ptr
        %99 = llvm.load %98 : !llvm.ptr -> i8
        %100 = llvm.mlir.constant(0 : i8) : i8
        %101 = llvm.icmp "ne" %99, %100 : i8
        scf.if %101 {
          %177 = builtin.unrealized_conversion_cast %iter_153 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %178 = builtin.unrealized_conversion_cast %iter_155 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
          %179 = llvm.load %177 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %179, %178 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %102 = cute.static : !cute.int_tuple<"1">
        %ptr_157 = cute.add_offset(%iter_156, %102) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
        %103 = builtin.unrealized_conversion_cast %ptr_157 : !cute.ptr<i8, rmem> to !llvm.ptr
        %104 = llvm.load %103 : !llvm.ptr -> i8
        %105 = llvm.mlir.constant(0 : i8) : i8
        %106 = llvm.icmp "ne" %104, %105 : i8
        scf.if %106 {
          %177 = cute.static : !cute.int_tuple<"1">
          %ptr_172 = cute.add_offset(%iter_153, %177) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
          %178 = cute.static : !cute.int_tuple<"1">
          %ptr_173 = cute.add_offset(%iter_155, %178) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
          %179 = builtin.unrealized_conversion_cast %ptr_172 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %180 = builtin.unrealized_conversion_cast %ptr_173 : !cute.ptr<f32, rmem> to !llvm.ptr
          %181 = llvm.load %179 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %181, %180 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %107 = cute.static : !cute.int_tuple<"2">
        %ptr_158 = cute.add_offset(%iter_156, %107) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem, align<2>>
        %108 = builtin.unrealized_conversion_cast %ptr_158 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
        %109 = llvm.load %108 : !llvm.ptr -> i8
        %110 = llvm.mlir.constant(0 : i8) : i8
        %111 = llvm.icmp "ne" %109, %110 : i8
        scf.if %111 {
          %177 = cute.static : !cute.int_tuple<"2">
          %ptr_172 = cute.add_offset(%iter_153, %177) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
          %178 = cute.static : !cute.int_tuple<"2">
          %ptr_173 = cute.add_offset(%iter_155, %178) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
          %179 = builtin.unrealized_conversion_cast %ptr_172 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %180 = builtin.unrealized_conversion_cast %ptr_173 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %181 = llvm.load %179 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %181, %180 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %112 = cute.static : !cute.int_tuple<"3">
        %ptr_159 = cute.add_offset(%iter_156, %112) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
        %113 = builtin.unrealized_conversion_cast %ptr_159 : !cute.ptr<i8, rmem> to !llvm.ptr
        %114 = llvm.load %113 : !llvm.ptr -> i8
        %115 = llvm.mlir.constant(0 : i8) : i8
        %116 = llvm.icmp "ne" %114, %115 : i8
        scf.if %116 {
          %177 = cute.static : !cute.int_tuple<"3">
          %ptr_172 = cute.add_offset(%iter_153, %177) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
          %178 = cute.static : !cute.int_tuple<"3">
          %ptr_173 = cute.add_offset(%iter_155, %178) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
          %179 = builtin.unrealized_conversion_cast %ptr_172 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %180 = builtin.unrealized_conversion_cast %ptr_173 : !cute.ptr<f32, rmem> to !llvm.ptr
          %181 = llvm.load %179 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %181, %180 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %117 = cute.static : !cute.int_tuple<"4">
        %ptr_160 = cute.add_offset(%iter_156, %117) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem, align<4>>
        %118 = builtin.unrealized_conversion_cast %ptr_160 : !cute.ptr<i8, rmem, align<4>> to !llvm.ptr
        %119 = llvm.load %118 : !llvm.ptr -> i8
        %120 = llvm.mlir.constant(0 : i8) : i8
        %121 = llvm.icmp "ne" %119, %120 : i8
        scf.if %121 {
          %int_tuple_172 = cute.make_int_tuple(%97) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_173 = cute.add_offset(%iter_153, %int_tuple_172) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %177 = cute.static : !cute.int_tuple<"4">
          %ptr_174 = cute.add_offset(%iter_155, %177) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
          %178 = builtin.unrealized_conversion_cast %ptr_173 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %179 = builtin.unrealized_conversion_cast %ptr_174 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
          %180 = llvm.load %178 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %180, %179 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %122 = cute.static : !cute.int_tuple<"5">
        %ptr_161 = cute.add_offset(%iter_156, %122) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
        %123 = builtin.unrealized_conversion_cast %ptr_161 : !cute.ptr<i8, rmem> to !llvm.ptr
        %124 = llvm.load %123 : !llvm.ptr -> i8
        %125 = llvm.mlir.constant(0 : i8) : i8
        %126 = llvm.icmp "ne" %124, %125 : i8
        scf.if %126 {
          %c1_i64 = arith.constant 1 : i64
          %177 = arith.addi %97, %c1_i64 : i64
          %int_tuple_172 = cute.make_int_tuple(%177) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_173 = cute.add_offset(%iter_153, %int_tuple_172) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %178 = cute.static : !cute.int_tuple<"5">
          %ptr_174 = cute.add_offset(%iter_155, %178) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<f32, rmem>
          %179 = builtin.unrealized_conversion_cast %ptr_173 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %180 = builtin.unrealized_conversion_cast %ptr_174 : !cute.ptr<f32, rmem> to !llvm.ptr
          %181 = llvm.load %179 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %181, %180 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %127 = cute.static : !cute.int_tuple<"6">
        %ptr_162 = cute.add_offset(%iter_156, %127) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem, align<2>>
        %128 = builtin.unrealized_conversion_cast %ptr_162 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
        %129 = llvm.load %128 : !llvm.ptr -> i8
        %130 = llvm.mlir.constant(0 : i8) : i8
        %131 = llvm.icmp "ne" %129, %130 : i8
        scf.if %131 {
          %c2_i64 = arith.constant 2 : i64
          %177 = arith.addi %97, %c2_i64 : i64
          %int_tuple_172 = cute.make_int_tuple(%177) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_173 = cute.add_offset(%iter_153, %int_tuple_172) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %178 = cute.static : !cute.int_tuple<"6">
          %ptr_174 = cute.add_offset(%iter_155, %178) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
          %179 = builtin.unrealized_conversion_cast %ptr_173 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %180 = builtin.unrealized_conversion_cast %ptr_174 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %181 = llvm.load %179 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %181, %180 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %132 = cute.static : !cute.int_tuple<"7">
        %ptr_163 = cute.add_offset(%iter_156, %132) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
        %133 = builtin.unrealized_conversion_cast %ptr_163 : !cute.ptr<i8, rmem> to !llvm.ptr
        %134 = llvm.load %133 : !llvm.ptr -> i8
        %135 = llvm.mlir.constant(0 : i8) : i8
        %136 = llvm.icmp "ne" %134, %135 : i8
        scf.if %136 {
          %c3_i64 = arith.constant 3 : i64
          %177 = arith.addi %97, %c3_i64 : i64
          %int_tuple_172 = cute.make_int_tuple(%177) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_173 = cute.add_offset(%iter_153, %int_tuple_172) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %178 = cute.static : !cute.int_tuple<"7">
          %ptr_174 = cute.add_offset(%iter_155, %178) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<f32, rmem>
          %179 = builtin.unrealized_conversion_cast %ptr_173 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %180 = builtin.unrealized_conversion_cast %ptr_174 : !cute.ptr<f32, rmem> to !llvm.ptr
          %181 = llvm.load %179 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %181, %180 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %137 = cute.static : !cute.int_tuple<"8">
        %ptr_164 = cute.add_offset(%iter_156, %137) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<i8, rmem, align<8>>
        %138 = builtin.unrealized_conversion_cast %ptr_164 : !cute.ptr<i8, rmem, align<8>> to !llvm.ptr
        %139 = llvm.load %138 : !llvm.ptr -> i8
        %140 = llvm.mlir.constant(0 : i8) : i8
        %141 = llvm.icmp "ne" %139, %140 : i8
        scf.if %141 {
          %c2_i64 = arith.constant 2 : i64
          %177 = arith.muli %97, %c2_i64 : i64
          %iv_172 = cute.assume(%177) : (i64) -> !cute.i64<divby 2>
          %int_tuple_173 = cute.make_int_tuple(%iv_172) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
          %ptr_174 = cute.add_offset(%iter_153, %int_tuple_173) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
          %178 = cute.static : !cute.int_tuple<"8">
          %ptr_175 = cute.add_offset(%iter_155, %178) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<f32, rmem, align<32>>
          %179 = builtin.unrealized_conversion_cast %ptr_174 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %180 = builtin.unrealized_conversion_cast %ptr_175 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
          %181 = llvm.load %179 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %181, %180 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %142 = cute.static : !cute.int_tuple<"9">
        %ptr_165 = cute.add_offset(%iter_156, %142) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<i8, rmem>
        %143 = builtin.unrealized_conversion_cast %ptr_165 : !cute.ptr<i8, rmem> to !llvm.ptr
        %144 = llvm.load %143 : !llvm.ptr -> i8
        %145 = llvm.mlir.constant(0 : i8) : i8
        %146 = llvm.icmp "ne" %144, %145 : i8
        scf.if %146 {
          %c2_i64 = arith.constant 2 : i64
          %177 = arith.muli %97, %c2_i64 : i64
          %c1_i64 = arith.constant 1 : i64
          %178 = arith.addi %177, %c1_i64 : i64
          %int_tuple_172 = cute.make_int_tuple(%178) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_173 = cute.add_offset(%iter_153, %int_tuple_172) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %179 = cute.static : !cute.int_tuple<"9">
          %ptr_174 = cute.add_offset(%iter_155, %179) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<f32, rmem>
          %180 = builtin.unrealized_conversion_cast %ptr_173 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %181 = builtin.unrealized_conversion_cast %ptr_174 : !cute.ptr<f32, rmem> to !llvm.ptr
          %182 = llvm.load %180 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %182, %181 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %147 = cute.static : !cute.int_tuple<"10">
        %ptr_166 = cute.add_offset(%iter_156, %147) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<i8, rmem, align<2>>
        %148 = builtin.unrealized_conversion_cast %ptr_166 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
        %149 = llvm.load %148 : !llvm.ptr -> i8
        %150 = llvm.mlir.constant(0 : i8) : i8
        %151 = llvm.icmp "ne" %149, %150 : i8
        scf.if %151 {
          %c2_i64 = arith.constant 2 : i64
          %177 = arith.muli %97, %c2_i64 : i64
          %c2_i64_172 = arith.constant 2 : i64
          %178 = arith.addi %177, %c2_i64_172 : i64
          %iv_173 = cute.assume(%178) : (i64) -> !cute.i64<divby 2>
          %int_tuple_174 = cute.make_int_tuple(%iv_173) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
          %ptr_175 = cute.add_offset(%iter_153, %int_tuple_174) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
          %179 = cute.static : !cute.int_tuple<"10">
          %ptr_176 = cute.add_offset(%iter_155, %179) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<f32, rmem, align<8>>
          %180 = builtin.unrealized_conversion_cast %ptr_175 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %181 = builtin.unrealized_conversion_cast %ptr_176 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %182 = llvm.load %180 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %182, %181 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %152 = cute.static : !cute.int_tuple<"11">
        %ptr_167 = cute.add_offset(%iter_156, %152) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<i8, rmem>
        %153 = builtin.unrealized_conversion_cast %ptr_167 : !cute.ptr<i8, rmem> to !llvm.ptr
        %154 = llvm.load %153 : !llvm.ptr -> i8
        %155 = llvm.mlir.constant(0 : i8) : i8
        %156 = llvm.icmp "ne" %154, %155 : i8
        scf.if %156 {
          %c2_i64 = arith.constant 2 : i64
          %177 = arith.muli %97, %c2_i64 : i64
          %c3_i64 = arith.constant 3 : i64
          %178 = arith.addi %177, %c3_i64 : i64
          %int_tuple_172 = cute.make_int_tuple(%178) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_173 = cute.add_offset(%iter_153, %int_tuple_172) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %179 = cute.static : !cute.int_tuple<"11">
          %ptr_174 = cute.add_offset(%iter_155, %179) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<f32, rmem>
          %180 = builtin.unrealized_conversion_cast %ptr_173 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %181 = builtin.unrealized_conversion_cast %ptr_174 : !cute.ptr<f32, rmem> to !llvm.ptr
          %182 = llvm.load %180 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %182, %181 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %157 = cute.static : !cute.int_tuple<"12">
        %ptr_168 = cute.add_offset(%iter_156, %157) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<i8, rmem, align<4>>
        %158 = builtin.unrealized_conversion_cast %ptr_168 : !cute.ptr<i8, rmem, align<4>> to !llvm.ptr
        %159 = llvm.load %158 : !llvm.ptr -> i8
        %160 = llvm.mlir.constant(0 : i8) : i8
        %161 = llvm.icmp "ne" %159, %160 : i8
        scf.if %161 {
          %c3_i64 = arith.constant 3 : i64
          %177 = arith.muli %97, %c3_i64 : i64
          %iv_172 = cute.assume(%177) : (i64) -> !cute.i64<divby 3>
          %int_tuple_173 = cute.make_int_tuple(%iv_172) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
          %ptr_174 = cute.add_offset(%iter_153, %int_tuple_173) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
          %178 = cute.static : !cute.int_tuple<"12">
          %ptr_175 = cute.add_offset(%iter_155, %178) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<f32, rmem, align<16>>
          %179 = builtin.unrealized_conversion_cast %ptr_174 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %180 = builtin.unrealized_conversion_cast %ptr_175 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
          %181 = llvm.load %179 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %181, %180 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %162 = cute.static : !cute.int_tuple<"13">
        %ptr_169 = cute.add_offset(%iter_156, %162) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<i8, rmem>
        %163 = builtin.unrealized_conversion_cast %ptr_169 : !cute.ptr<i8, rmem> to !llvm.ptr
        %164 = llvm.load %163 : !llvm.ptr -> i8
        %165 = llvm.mlir.constant(0 : i8) : i8
        %166 = llvm.icmp "ne" %164, %165 : i8
        scf.if %166 {
          %c3_i64 = arith.constant 3 : i64
          %177 = arith.muli %97, %c3_i64 : i64
          %c1_i64 = arith.constant 1 : i64
          %178 = arith.addi %177, %c1_i64 : i64
          %int_tuple_172 = cute.make_int_tuple(%178) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_173 = cute.add_offset(%iter_153, %int_tuple_172) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %179 = cute.static : !cute.int_tuple<"13">
          %ptr_174 = cute.add_offset(%iter_155, %179) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<f32, rmem>
          %180 = builtin.unrealized_conversion_cast %ptr_173 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %181 = builtin.unrealized_conversion_cast %ptr_174 : !cute.ptr<f32, rmem> to !llvm.ptr
          %182 = llvm.load %180 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %182, %181 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %167 = cute.static : !cute.int_tuple<"14">
        %ptr_170 = cute.add_offset(%iter_156, %167) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<i8, rmem, align<2>>
        %168 = builtin.unrealized_conversion_cast %ptr_170 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
        %169 = llvm.load %168 : !llvm.ptr -> i8
        %170 = llvm.mlir.constant(0 : i8) : i8
        %171 = llvm.icmp "ne" %169, %170 : i8
        scf.if %171 {
          %c3_i64 = arith.constant 3 : i64
          %177 = arith.muli %97, %c3_i64 : i64
          %c2_i64 = arith.constant 2 : i64
          %178 = arith.addi %177, %c2_i64 : i64
          %int_tuple_172 = cute.make_int_tuple(%178) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_173 = cute.add_offset(%iter_153, %int_tuple_172) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %179 = cute.static : !cute.int_tuple<"14">
          %ptr_174 = cute.add_offset(%iter_155, %179) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<f32, rmem, align<8>>
          %180 = builtin.unrealized_conversion_cast %ptr_173 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %181 = builtin.unrealized_conversion_cast %ptr_174 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %182 = llvm.load %180 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %182, %181 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %172 = cute.static : !cute.int_tuple<"15">
        %ptr_171 = cute.add_offset(%iter_156, %172) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<i8, rmem>
        %173 = builtin.unrealized_conversion_cast %ptr_171 : !cute.ptr<i8, rmem> to !llvm.ptr
        %174 = llvm.load %173 : !llvm.ptr -> i8
        %175 = llvm.mlir.constant(0 : i8) : i8
        %176 = llvm.icmp "ne" %174, %175 : i8
        scf.if %176 {
          %c3_i64 = arith.constant 3 : i64
          %177 = arith.muli %97, %c3_i64 : i64
          %c3_i64_172 = arith.constant 3 : i64
          %178 = arith.addi %177, %c3_i64_172 : i64
          %iv_173 = cute.assume(%178) : (i64) -> !cute.i64<divby 3>
          %int_tuple_174 = cute.make_int_tuple(%iv_173) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
          %ptr_175 = cute.add_offset(%iter_153, %int_tuple_174) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
          %179 = cute.static : !cute.int_tuple<"15">
          %ptr_176 = cute.add_offset(%iter_155, %179) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<f32, rmem>
          %180 = builtin.unrealized_conversion_cast %ptr_175 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %181 = builtin.unrealized_conversion_cast %ptr_176 : !cute.ptr<f32, rmem> to !llvm.ptr
          %182 = llvm.load %180 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %182, %181 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
      } {llvm.loop_annotation = #loop_annotation}
      %77 = cute.memref.load_vec %rmem, row_major : !memref_rmem_f32_
      %78 = cute.memref.load_vec %rmem_60, row_major : !memref_rmem_f32_
      %79 = arith.addf %77, %78 : vector<16xf32>
      cute.memref.store_vec %79, %rmem_62, row_major : !memref_rmem_f32_
      %80 = cute.static : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %view_122 = cute.make_view(%iter_63, %80) : !memref_rmem_f32_
      %iter_123 = cute.get_iter(%view_122) : !memref_rmem_f32_
      %view_124 = cute.make_view(%iter_123) : !memref_rmem_f32_1
      %lay_125 = cute.get_layout(%view_57) : !memref_gmem_f32_2
      %81 = cute.static : !cute.layout<"1:0">
      %append_126 = cute.append_to_rank<2> (%lay_125, %81) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">
      %view_127 = cute.make_view(%iter_58, %append_126) : !memref_gmem_f32_2
      %iter_128 = cute.get_iter(%view_127) : !memref_gmem_f32_2
      %lay_129 = cute.get_layout(%view_127) : !memref_gmem_f32_2
      %82 = cute.get_scalars(%lay_129) <{only_dynamic}> : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %83 = cute.static : !cute.shape<"((1,(4,4)),(1,1))">
      %stride_130 = cute.make_stride(%82) : (i64) -> !cute.stride<"((0,(1,?{i64})),(0,0))">
      %lay_131 = cute.make_layout(%83, %stride_130) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %view_132 = cute.make_view(%iter_128, %lay_131) : !memref_gmem_f32_3
      %84 = cute.static : !cute.layout<"((1,(4,4)),1,1):((0,(1,4)),0,0)">
      %view_133 = cute.make_view(%iter_76, %84) : !memref_rmem_i8_
      %iter_134 = cute.get_iter(%view_133) : !memref_rmem_i8_
      %view_135 = cute.make_view(%iter_134) : !memref_rmem_i8_1
      %85 = cute.static : !cute.layout<"1:0">
      %iter_136 = cute.get_iter(%view_124) : !memref_rmem_f32_1
      %iter_137 = cute.get_iter(%view_132) : !memref_gmem_f32_3
      %lay_138 = cute.get_layout(%view_132) : !memref_gmem_f32_3
      %append_139 = cute.append_to_rank<2> (%lay_138, %85) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">, !cute.layout<"1:0">
      %86 = cute.get_scalars(%append_139) <{only_dynamic}> : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %87 = cute.static : !cute.shape<"((1,(4,4)),((1,1)))">
      %stride_140 = cute.make_stride(%86) : (i64) -> !cute.stride<"((0,(1,?{i64})),((0,0)))">
      %lay_141 = cute.make_layout(%87, %stride_140) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
      %iter_142 = cute.get_iter(%view_135) : !memref_rmem_i8_1
      %88 = cute.static : !cute.int_tuple<"1">
      %89 = cute.get_scalars(%88) : !cute.int_tuple<"1">
      %c0_i32_143 = arith.constant 0 : i32
      %c1_i32_144 = arith.constant 1 : i32
      scf.for %arg6 = %c0_i32_143 to %89 step %c1_i32_144  : i32 {
        %90 = cute.static : !cute.layout<"((1,(4,4))):((0,(1,4)))">
        %91 = cute.static : !cute.int_tuple<"0">
        %ptr_145 = cute.add_offset(%iter_136, %91) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, rmem, align<32>>
        %view_146 = cute.make_view(%ptr_145, %90) : !memref_rmem_f32_2
        %92 = cute.get_scalars(%lay_141) <{only_dynamic}> : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
        %93 = cute.static : !cute.shape<"((1,(4,4)))">
        %stride_147 = cute.make_stride(%92) : (i64) -> !cute.stride<"((0,(1,?{i64})))">
        %lay_148 = cute.make_layout(%93, %stride_147) : !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
        %94 = cute.static : !cute.int_tuple<"0">
        %ptr_149 = cute.add_offset(%iter_137, %94) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<f32, gmem>
        %view_150 = cute.make_view(%ptr_149, %lay_148) : !memref_gmem_f32_4
        %95 = cute.static : !cute.layout<"((1,(4,4))):((0,(1,4)))">
        %96 = cute.static : !cute.int_tuple<"0">
        %ptr_151 = cute.add_offset(%iter_142, %96) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
        %view_152 = cute.make_view(%ptr_151, %95) : !memref_rmem_i8_2
        %iter_153 = cute.get_iter(%view_146) : !memref_rmem_f32_2
        %iter_154 = cute.get_iter(%view_150) : !memref_gmem_f32_4
        %lay_155 = cute.get_layout(%view_150) : !memref_gmem_f32_4
        %97 = cute.get_scalars(%lay_155) <{only_dynamic}> : !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
        %iter_156 = cute.get_iter(%view_152) : !memref_rmem_i8_2
        %98 = builtin.unrealized_conversion_cast %iter_156 : !cute.ptr<i8, rmem, align<32>> to !llvm.ptr
        %99 = llvm.load %98 : !llvm.ptr -> i8
        %100 = llvm.mlir.constant(0 : i8) : i8
        %101 = llvm.icmp "ne" %99, %100 : i8
        scf.if %101 {
          %177 = builtin.unrealized_conversion_cast %iter_153 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
          %178 = builtin.unrealized_conversion_cast %iter_154 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %179 = llvm.load %177 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %179, %178 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %102 = cute.static : !cute.int_tuple<"1">
        %ptr_157 = cute.add_offset(%iter_156, %102) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
        %103 = builtin.unrealized_conversion_cast %ptr_157 : !cute.ptr<i8, rmem> to !llvm.ptr
        %104 = llvm.load %103 : !llvm.ptr -> i8
        %105 = llvm.mlir.constant(0 : i8) : i8
        %106 = llvm.icmp "ne" %104, %105 : i8
        scf.if %106 {
          %177 = cute.static : !cute.int_tuple<"1">
          %ptr_172 = cute.add_offset(%iter_153, %177) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
          %178 = cute.static : !cute.int_tuple<"1">
          %ptr_173 = cute.add_offset(%iter_154, %178) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
          %179 = builtin.unrealized_conversion_cast %ptr_172 : !cute.ptr<f32, rmem> to !llvm.ptr
          %180 = builtin.unrealized_conversion_cast %ptr_173 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %181 = llvm.load %179 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %181, %180 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %107 = cute.static : !cute.int_tuple<"2">
        %ptr_158 = cute.add_offset(%iter_156, %107) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem, align<2>>
        %108 = builtin.unrealized_conversion_cast %ptr_158 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
        %109 = llvm.load %108 : !llvm.ptr -> i8
        %110 = llvm.mlir.constant(0 : i8) : i8
        %111 = llvm.icmp "ne" %109, %110 : i8
        scf.if %111 {
          %177 = cute.static : !cute.int_tuple<"2">
          %ptr_172 = cute.add_offset(%iter_153, %177) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
          %178 = cute.static : !cute.int_tuple<"2">
          %ptr_173 = cute.add_offset(%iter_154, %178) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
          %179 = builtin.unrealized_conversion_cast %ptr_172 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %180 = builtin.unrealized_conversion_cast %ptr_173 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %181 = llvm.load %179 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %181, %180 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %112 = cute.static : !cute.int_tuple<"3">
        %ptr_159 = cute.add_offset(%iter_156, %112) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
        %113 = builtin.unrealized_conversion_cast %ptr_159 : !cute.ptr<i8, rmem> to !llvm.ptr
        %114 = llvm.load %113 : !llvm.ptr -> i8
        %115 = llvm.mlir.constant(0 : i8) : i8
        %116 = llvm.icmp "ne" %114, %115 : i8
        scf.if %116 {
          %177 = cute.static : !cute.int_tuple<"3">
          %ptr_172 = cute.add_offset(%iter_153, %177) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
          %178 = cute.static : !cute.int_tuple<"3">
          %ptr_173 = cute.add_offset(%iter_154, %178) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
          %179 = builtin.unrealized_conversion_cast %ptr_172 : !cute.ptr<f32, rmem> to !llvm.ptr
          %180 = builtin.unrealized_conversion_cast %ptr_173 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %181 = llvm.load %179 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %181, %180 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %117 = cute.static : !cute.int_tuple<"4">
        %ptr_160 = cute.add_offset(%iter_156, %117) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem, align<4>>
        %118 = builtin.unrealized_conversion_cast %ptr_160 : !cute.ptr<i8, rmem, align<4>> to !llvm.ptr
        %119 = llvm.load %118 : !llvm.ptr -> i8
        %120 = llvm.mlir.constant(0 : i8) : i8
        %121 = llvm.icmp "ne" %119, %120 : i8
        scf.if %121 {
          %177 = cute.static : !cute.int_tuple<"4">
          %ptr_172 = cute.add_offset(%iter_153, %177) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
          %int_tuple_173 = cute.make_int_tuple(%97) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_174 = cute.add_offset(%iter_154, %int_tuple_173) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %178 = builtin.unrealized_conversion_cast %ptr_172 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
          %179 = builtin.unrealized_conversion_cast %ptr_174 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %180 = llvm.load %178 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %180, %179 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %122 = cute.static : !cute.int_tuple<"5">
        %ptr_161 = cute.add_offset(%iter_156, %122) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
        %123 = builtin.unrealized_conversion_cast %ptr_161 : !cute.ptr<i8, rmem> to !llvm.ptr
        %124 = llvm.load %123 : !llvm.ptr -> i8
        %125 = llvm.mlir.constant(0 : i8) : i8
        %126 = llvm.icmp "ne" %124, %125 : i8
        scf.if %126 {
          %177 = cute.static : !cute.int_tuple<"5">
          %ptr_172 = cute.add_offset(%iter_153, %177) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<f32, rmem>
          %c1_i64 = arith.constant 1 : i64
          %178 = arith.addi %97, %c1_i64 : i64
          %int_tuple_173 = cute.make_int_tuple(%178) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_174 = cute.add_offset(%iter_154, %int_tuple_173) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %179 = builtin.unrealized_conversion_cast %ptr_172 : !cute.ptr<f32, rmem> to !llvm.ptr
          %180 = builtin.unrealized_conversion_cast %ptr_174 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %181 = llvm.load %179 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %181, %180 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %127 = cute.static : !cute.int_tuple<"6">
        %ptr_162 = cute.add_offset(%iter_156, %127) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem, align<2>>
        %128 = builtin.unrealized_conversion_cast %ptr_162 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
        %129 = llvm.load %128 : !llvm.ptr -> i8
        %130 = llvm.mlir.constant(0 : i8) : i8
        %131 = llvm.icmp "ne" %129, %130 : i8
        scf.if %131 {
          %177 = cute.static : !cute.int_tuple<"6">
          %ptr_172 = cute.add_offset(%iter_153, %177) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
          %c2_i64 = arith.constant 2 : i64
          %178 = arith.addi %97, %c2_i64 : i64
          %int_tuple_173 = cute.make_int_tuple(%178) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_174 = cute.add_offset(%iter_154, %int_tuple_173) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %179 = builtin.unrealized_conversion_cast %ptr_172 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %180 = builtin.unrealized_conversion_cast %ptr_174 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %181 = llvm.load %179 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %181, %180 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %132 = cute.static : !cute.int_tuple<"7">
        %ptr_163 = cute.add_offset(%iter_156, %132) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
        %133 = builtin.unrealized_conversion_cast %ptr_163 : !cute.ptr<i8, rmem> to !llvm.ptr
        %134 = llvm.load %133 : !llvm.ptr -> i8
        %135 = llvm.mlir.constant(0 : i8) : i8
        %136 = llvm.icmp "ne" %134, %135 : i8
        scf.if %136 {
          %177 = cute.static : !cute.int_tuple<"7">
          %ptr_172 = cute.add_offset(%iter_153, %177) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<f32, rmem>
          %c3_i64 = arith.constant 3 : i64
          %178 = arith.addi %97, %c3_i64 : i64
          %int_tuple_173 = cute.make_int_tuple(%178) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_174 = cute.add_offset(%iter_154, %int_tuple_173) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %179 = builtin.unrealized_conversion_cast %ptr_172 : !cute.ptr<f32, rmem> to !llvm.ptr
          %180 = builtin.unrealized_conversion_cast %ptr_174 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %181 = llvm.load %179 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %181, %180 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %137 = cute.static : !cute.int_tuple<"8">
        %ptr_164 = cute.add_offset(%iter_156, %137) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<i8, rmem, align<8>>
        %138 = builtin.unrealized_conversion_cast %ptr_164 : !cute.ptr<i8, rmem, align<8>> to !llvm.ptr
        %139 = llvm.load %138 : !llvm.ptr -> i8
        %140 = llvm.mlir.constant(0 : i8) : i8
        %141 = llvm.icmp "ne" %139, %140 : i8
        scf.if %141 {
          %177 = cute.static : !cute.int_tuple<"8">
          %ptr_172 = cute.add_offset(%iter_153, %177) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<f32, rmem, align<32>>
          %c2_i64 = arith.constant 2 : i64
          %178 = arith.muli %97, %c2_i64 : i64
          %iv_173 = cute.assume(%178) : (i64) -> !cute.i64<divby 2>
          %int_tuple_174 = cute.make_int_tuple(%iv_173) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
          %ptr_175 = cute.add_offset(%iter_154, %int_tuple_174) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
          %179 = builtin.unrealized_conversion_cast %ptr_172 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
          %180 = builtin.unrealized_conversion_cast %ptr_175 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %181 = llvm.load %179 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %181, %180 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %142 = cute.static : !cute.int_tuple<"9">
        %ptr_165 = cute.add_offset(%iter_156, %142) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<i8, rmem>
        %143 = builtin.unrealized_conversion_cast %ptr_165 : !cute.ptr<i8, rmem> to !llvm.ptr
        %144 = llvm.load %143 : !llvm.ptr -> i8
        %145 = llvm.mlir.constant(0 : i8) : i8
        %146 = llvm.icmp "ne" %144, %145 : i8
        scf.if %146 {
          %177 = cute.static : !cute.int_tuple<"9">
          %ptr_172 = cute.add_offset(%iter_153, %177) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<f32, rmem>
          %c2_i64 = arith.constant 2 : i64
          %178 = arith.muli %97, %c2_i64 : i64
          %c1_i64 = arith.constant 1 : i64
          %179 = arith.addi %178, %c1_i64 : i64
          %int_tuple_173 = cute.make_int_tuple(%179) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_174 = cute.add_offset(%iter_154, %int_tuple_173) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %180 = builtin.unrealized_conversion_cast %ptr_172 : !cute.ptr<f32, rmem> to !llvm.ptr
          %181 = builtin.unrealized_conversion_cast %ptr_174 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %182 = llvm.load %180 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %182, %181 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %147 = cute.static : !cute.int_tuple<"10">
        %ptr_166 = cute.add_offset(%iter_156, %147) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<i8, rmem, align<2>>
        %148 = builtin.unrealized_conversion_cast %ptr_166 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
        %149 = llvm.load %148 : !llvm.ptr -> i8
        %150 = llvm.mlir.constant(0 : i8) : i8
        %151 = llvm.icmp "ne" %149, %150 : i8
        scf.if %151 {
          %177 = cute.static : !cute.int_tuple<"10">
          %ptr_172 = cute.add_offset(%iter_153, %177) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<f32, rmem, align<8>>
          %c2_i64 = arith.constant 2 : i64
          %178 = arith.muli %97, %c2_i64 : i64
          %c2_i64_173 = arith.constant 2 : i64
          %179 = arith.addi %178, %c2_i64_173 : i64
          %iv_174 = cute.assume(%179) : (i64) -> !cute.i64<divby 2>
          %int_tuple_175 = cute.make_int_tuple(%iv_174) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
          %ptr_176 = cute.add_offset(%iter_154, %int_tuple_175) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
          %180 = builtin.unrealized_conversion_cast %ptr_172 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %181 = builtin.unrealized_conversion_cast %ptr_176 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %182 = llvm.load %180 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %182, %181 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %152 = cute.static : !cute.int_tuple<"11">
        %ptr_167 = cute.add_offset(%iter_156, %152) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<i8, rmem>
        %153 = builtin.unrealized_conversion_cast %ptr_167 : !cute.ptr<i8, rmem> to !llvm.ptr
        %154 = llvm.load %153 : !llvm.ptr -> i8
        %155 = llvm.mlir.constant(0 : i8) : i8
        %156 = llvm.icmp "ne" %154, %155 : i8
        scf.if %156 {
          %177 = cute.static : !cute.int_tuple<"11">
          %ptr_172 = cute.add_offset(%iter_153, %177) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<f32, rmem>
          %c2_i64 = arith.constant 2 : i64
          %178 = arith.muli %97, %c2_i64 : i64
          %c3_i64 = arith.constant 3 : i64
          %179 = arith.addi %178, %c3_i64 : i64
          %int_tuple_173 = cute.make_int_tuple(%179) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_174 = cute.add_offset(%iter_154, %int_tuple_173) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %180 = builtin.unrealized_conversion_cast %ptr_172 : !cute.ptr<f32, rmem> to !llvm.ptr
          %181 = builtin.unrealized_conversion_cast %ptr_174 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %182 = llvm.load %180 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %182, %181 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %157 = cute.static : !cute.int_tuple<"12">
        %ptr_168 = cute.add_offset(%iter_156, %157) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<i8, rmem, align<4>>
        %158 = builtin.unrealized_conversion_cast %ptr_168 : !cute.ptr<i8, rmem, align<4>> to !llvm.ptr
        %159 = llvm.load %158 : !llvm.ptr -> i8
        %160 = llvm.mlir.constant(0 : i8) : i8
        %161 = llvm.icmp "ne" %159, %160 : i8
        scf.if %161 {
          %177 = cute.static : !cute.int_tuple<"12">
          %ptr_172 = cute.add_offset(%iter_153, %177) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<f32, rmem, align<16>>
          %c3_i64 = arith.constant 3 : i64
          %178 = arith.muli %97, %c3_i64 : i64
          %iv_173 = cute.assume(%178) : (i64) -> !cute.i64<divby 3>
          %int_tuple_174 = cute.make_int_tuple(%iv_173) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
          %ptr_175 = cute.add_offset(%iter_154, %int_tuple_174) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
          %179 = builtin.unrealized_conversion_cast %ptr_172 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
          %180 = builtin.unrealized_conversion_cast %ptr_175 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %181 = llvm.load %179 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %181, %180 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %162 = cute.static : !cute.int_tuple<"13">
        %ptr_169 = cute.add_offset(%iter_156, %162) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<i8, rmem>
        %163 = builtin.unrealized_conversion_cast %ptr_169 : !cute.ptr<i8, rmem> to !llvm.ptr
        %164 = llvm.load %163 : !llvm.ptr -> i8
        %165 = llvm.mlir.constant(0 : i8) : i8
        %166 = llvm.icmp "ne" %164, %165 : i8
        scf.if %166 {
          %177 = cute.static : !cute.int_tuple<"13">
          %ptr_172 = cute.add_offset(%iter_153, %177) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<f32, rmem>
          %c3_i64 = arith.constant 3 : i64
          %178 = arith.muli %97, %c3_i64 : i64
          %c1_i64 = arith.constant 1 : i64
          %179 = arith.addi %178, %c1_i64 : i64
          %int_tuple_173 = cute.make_int_tuple(%179) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_174 = cute.add_offset(%iter_154, %int_tuple_173) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %180 = builtin.unrealized_conversion_cast %ptr_172 : !cute.ptr<f32, rmem> to !llvm.ptr
          %181 = builtin.unrealized_conversion_cast %ptr_174 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %182 = llvm.load %180 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %182, %181 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %167 = cute.static : !cute.int_tuple<"14">
        %ptr_170 = cute.add_offset(%iter_156, %167) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<i8, rmem, align<2>>
        %168 = builtin.unrealized_conversion_cast %ptr_170 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
        %169 = llvm.load %168 : !llvm.ptr -> i8
        %170 = llvm.mlir.constant(0 : i8) : i8
        %171 = llvm.icmp "ne" %169, %170 : i8
        scf.if %171 {
          %177 = cute.static : !cute.int_tuple<"14">
          %ptr_172 = cute.add_offset(%iter_153, %177) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<f32, rmem, align<8>>
          %c3_i64 = arith.constant 3 : i64
          %178 = arith.muli %97, %c3_i64 : i64
          %c2_i64 = arith.constant 2 : i64
          %179 = arith.addi %178, %c2_i64 : i64
          %int_tuple_173 = cute.make_int_tuple(%179) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_174 = cute.add_offset(%iter_154, %int_tuple_173) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %180 = builtin.unrealized_conversion_cast %ptr_172 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %181 = builtin.unrealized_conversion_cast %ptr_174 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %182 = llvm.load %180 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %182, %181 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %172 = cute.static : !cute.int_tuple<"15">
        %ptr_171 = cute.add_offset(%iter_156, %172) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<i8, rmem>
        %173 = builtin.unrealized_conversion_cast %ptr_171 : !cute.ptr<i8, rmem> to !llvm.ptr
        %174 = llvm.load %173 : !llvm.ptr -> i8
        %175 = llvm.mlir.constant(0 : i8) : i8
        %176 = llvm.icmp "ne" %174, %175 : i8
        scf.if %176 {
          %177 = cute.static : !cute.int_tuple<"15">
          %ptr_172 = cute.add_offset(%iter_153, %177) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<f32, rmem>
          %c3_i64 = arith.constant 3 : i64
          %178 = arith.muli %97, %c3_i64 : i64
          %c3_i64_173 = arith.constant 3 : i64
          %179 = arith.addi %178, %c3_i64_173 : i64
          %iv_174 = cute.assume(%179) : (i64) -> !cute.i64<divby 3>
          %int_tuple_175 = cute.make_int_tuple(%iv_174) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
          %ptr_176 = cute.add_offset(%iter_154, %int_tuple_175) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
          %180 = builtin.unrealized_conversion_cast %ptr_172 : !cute.ptr<f32, rmem> to !llvm.ptr
          %181 = builtin.unrealized_conversion_cast %ptr_176 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %182 = llvm.load %180 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %182, %181 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
      } {llvm.loop_annotation = #loop_annotation}
      return
    }
  }
  func.func @cutlass_elementwise_add_tensor_00795_21652_04639_03193_15897_02304_02971_12990_02319_03973_00495_05866_09467_06015_06234_07404_19793_05333_01425_01997_05745_11222_16922_13492_04451(%arg0: !memref_gmem_f32_5, %arg1: !memref_gmem_f32_5, %arg2: !memref_gmem_f32_5) attributes {llvm.emit_c_interface} {
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
    %23 = arith.index_cast %22 : i32 to index
    %c1 = arith.constant 1 : index
    %c128 = arith.constant 128 : index
    %c0_i32 = arith.constant 0 : i32
    gpu.launch_func  @kernels::@kernel_cutlass_elementwise_add_kernel_tensorptrf32gmemo161281div16128_tensorptrf32gmemo161281div16128_tensorptrf32gmemo161281div16128_tensor00o1612810111601281___0 blocks in (%23, %c1, %c1) threads in (%c128, %c1, %c1)  dynamic_shared_memory_size %c0_i32 args(%view : !memref_gmem_f32_, %view_10 : !memref_gmem_f32_, %view_20 : !memref_gmem_f32_, %view_31 : !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">, %13 : i32, %14 : i32) {use_pdl = false}
    return
  }
}
