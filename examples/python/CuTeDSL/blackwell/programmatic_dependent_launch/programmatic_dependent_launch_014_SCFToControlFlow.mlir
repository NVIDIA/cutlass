!copy_simt = !cute.tiled_copy<!cute_nvgpu.atom.universal_copy<f32>, layout_copy_tv = <"((32,4),(4,4)):((64,4),(16,1))">, tiler_mn = <"[16:1;128:1]">>
!memref_gmem_f32_ = !cute.memref<f32, gmem, "((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
!memref_gmem_f32_1 = !cute.memref<f32, gmem, "(?,?):(?{i64},1)">
!memref_rmem_f32_ = !cute.memref<f32, rmem, align<32>, "((1,(4,4)),1,1):((0,(1,4)),0,0)">
!memref_rmem_i8_ = !cute.memref<i8, rmem, align<32>, "((1,(4,4)),1,1):((0,(1,4)),0,0)">
#loop_unroll = #llvm.loop_unroll<disable = false, full = true>
#loop_annotation = #llvm.loop_annotation<unroll = #loop_unroll>
module attributes {gpu.container_module} {
  gpu.module @kernels {
    cuda.kernel @kernel_cutlass_elementwise_add_kernel_tensorptrf32gmemo161281i64div16128_tensorptrf32gmemo161281i64div16128_tensorptrf32gmemo161281i64div16128_tensor00o1612810111601281___False_0(%arg0: !memref_gmem_f32_, %arg1: !memref_gmem_f32_, %arg2: !memref_gmem_f32_, %arg3: !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">, %arg4: i32, %arg5: i32) attributes {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} {
      %0 = cute.static : !cute.int_tuple<"15">
      %1 = cute.static : !cute.int_tuple<"14">
      %2 = cute.static : !cute.int_tuple<"13">
      %3 = cute.static : !cute.int_tuple<"12">
      %4 = cute.static : !cute.int_tuple<"11">
      %5 = cute.static : !cute.int_tuple<"10">
      %6 = cute.static : !cute.int_tuple<"9">
      %7 = cute.static : !cute.int_tuple<"8">
      %c3_i64 = arith.constant 3 : i64
      %8 = cute.static : !cute.int_tuple<"7">
      %c2_i64 = arith.constant 2 : i64
      %9 = cute.static : !cute.int_tuple<"6">
      %c1_i64 = arith.constant 1 : i64
      %10 = cute.static : !cute.int_tuple<"5">
      %11 = cute.static : !cute.int_tuple<"4">
      %12 = cute.static : !cute.int_tuple<"3">
      %13 = cute.static : !cute.int_tuple<"2">
      %14 = llvm.mlir.constant(0 : i8) : i8
      %15 = cute.static : !cute.shape<"((1,(4,4)))">
      %16 = cute.static : !cute.int_tuple<"1">
      %17 = cute.static : !cute.shape<"((1,(4,4)),((1,1)))">
      %18 = cute.static : !cute.shape<"((1,(4,4)),(1,1))">
      %19 = cute.static : !cute.layout<"1:0">
      %c10_i32 = arith.constant 10 : i32
      %20 = cute.static : !cute.layout<"((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">
      %c1_i32 = arith.constant 1 : i32
      %c16_i32 = arith.constant 16 : i32
      %c0_i32 = arith.constant 0 : i32
      %21 = cute.static : !cute.shape<"((1,(4,4)),1,1)">
      %c4_i32 = arith.constant 4 : i32
      %c32_i32 = arith.constant 32 : i32
      %c4_i64 = arith.constant 4 : i64
      %22 = cute.static : !cute.int_tuple<"(0,0)">
      %23 = cute.static : !cute.shape<"(16,128)">
      %24 = nvvm.read.ptx.sreg.tid.x range <i32, 0, 1024> : i32
      %25 = nvvm.read.ptx.sreg.ctaid.x range <i32, 0, 2147483647> : i32
      %coord = cute.make_coord(%25) : (i32) -> !cute.coord<"((_,_),?)">
      %lay = cute.get_layout(%arg0) : !memref_gmem_f32_
      %26:4 = cute.get_scalars(%lay) <{only_dynamic}> : !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
      %stride = cute.make_stride(%26#2) : (i64) -> !cute.stride<"(?{i64},1)">
      %lay_0 = cute.make_layout(%23, %stride) : !cute.layout<"(16,128):(?{i64},1)">
      %idx = cute.crd2idx(%coord, %lay) : (!cute.coord<"((_,_),?)">, !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.int_tuple<"?{i64 div=16}">
      %iter = cute.get_iter(%arg0) : !memref_gmem_f32_
      %ptr = cute.add_offset(%iter, %idx) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=16}">) -> !cute.ptr<f32, gmem>
      %lay_1 = cute.get_layout(%arg1) : !memref_gmem_f32_
      %27:4 = cute.get_scalars(%lay_1) <{only_dynamic}> : !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
      %stride_2 = cute.make_stride(%27#2) : (i64) -> !cute.stride<"(?{i64},1)">
      %lay_3 = cute.make_layout(%23, %stride_2) : !cute.layout<"(16,128):(?{i64},1)">
      %idx_4 = cute.crd2idx(%coord, %lay_1) : (!cute.coord<"((_,_),?)">, !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.int_tuple<"?{i64 div=16}">
      %iter_5 = cute.get_iter(%arg1) : !memref_gmem_f32_
      %ptr_6 = cute.add_offset(%iter_5, %idx_4) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=16}">) -> !cute.ptr<f32, gmem>
      %lay_7 = cute.get_layout(%arg2) : !memref_gmem_f32_
      %28:4 = cute.get_scalars(%lay_7) <{only_dynamic}> : !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
      %stride_8 = cute.make_stride(%28#2) : (i64) -> !cute.stride<"(?{i64},1)">
      %lay_9 = cute.make_layout(%23, %stride_8) : !cute.layout<"(16,128):(?{i64},1)">
      %idx_10 = cute.crd2idx(%coord, %lay_7) : (!cute.coord<"((_,_),?)">, !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.int_tuple<"?{i64 div=16}">
      %iter_11 = cute.get_iter(%arg2) : !memref_gmem_f32_
      %ptr_12 = cute.add_offset(%iter_11, %idx_10) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=16}">) -> !cute.ptr<f32, gmem>
      %lay_13 = cute.get_layout(%arg3) : !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
      %idx_14 = cute.crd2idx(%coord, %lay_13) : (!cute.coord<"((_,_),?)">, !cute.layout<"((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">) -> !cute.int_tuple<"(?{div=16},?{div=128})">
      %tup = cute.add_offset(%22, %idx_14) : (!cute.int_tuple<"(0,0)">, !cute.int_tuple<"(?{div=16},?{div=128})">) -> !cute.int_tuple<"(?{div=16},?{div=128})">
      %atom = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<f32>
      %29 = cute.make_tiled_copy(%atom) : !copy_simt
      %30 = cute.make_tiled_copy(%atom) : !copy_simt
      %31 = cute.make_tiled_copy(%atom) : !copy_simt
      %coord_15 = cute.make_coord(%24) : (i32) -> !cute.coord<"?">
      %32 = cute.get_scalars(%lay_0) <{only_dynamic}> : !cute.layout<"(16,128):(?{i64},1)">
      %33 = cute.get_scalars(%coord_15) <{only_dynamic}> : !cute.coord<"?">
      %34 = arith.muli %32, %c4_i64 : i64
      %35 = arith.divsi %33, %c32_i32 : i32
      %36 = arith.remsi %33, %c32_i32 : i32
      %37 = arith.muli %36, %c4_i32 : i32
      %38 = arith.extsi %35 : i32 to i64
      %39 = arith.muli %38, %34 : i64
      %40 = arith.extsi %37 : i32 to i64
      %41 = arith.addi %40, %39 : i64
      %iv = cute.assume(%41) : (i64) -> !cute.i64<divby 4>
      %int_tuple = cute.make_int_tuple(%iv) : (!cute.i64<divby 4>) -> !cute.int_tuple<"?{i64 div=4}">
      %ptr_16 = cute.add_offset(%ptr, %int_tuple) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=4}">) -> !cute.ptr<f32, gmem>
      %stride_17 = cute.make_stride(%32) : (i64) -> !cute.stride<"((0,(1,?{i64})),0,0)">
      %lay_18 = cute.make_layout(%21, %stride_17) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %42 = cute.get_scalars(%lay_3) <{only_dynamic}> : !cute.layout<"(16,128):(?{i64},1)">
      %43 = arith.muli %42, %c4_i64 : i64
      %44 = arith.muli %38, %43 : i64
      %45 = arith.addi %40, %44 : i64
      %iv_19 = cute.assume(%45) : (i64) -> !cute.i64<divby 4>
      %int_tuple_20 = cute.make_int_tuple(%iv_19) : (!cute.i64<divby 4>) -> !cute.int_tuple<"?{i64 div=4}">
      %ptr_21 = cute.add_offset(%ptr_6, %int_tuple_20) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=4}">) -> !cute.ptr<f32, gmem>
      %stride_22 = cute.make_stride(%42) : (i64) -> !cute.stride<"((0,(1,?{i64})),0,0)">
      %lay_23 = cute.make_layout(%21, %stride_22) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %46 = cute.get_scalars(%lay_9) <{only_dynamic}> : !cute.layout<"(16,128):(?{i64},1)">
      %47 = arith.muli %46, %c4_i64 : i64
      %48 = arith.muli %38, %47 : i64
      %49 = arith.addi %40, %48 : i64
      %iv_24 = cute.assume(%49) : (i64) -> !cute.i64<divby 4>
      %int_tuple_25 = cute.make_int_tuple(%iv_24) : (!cute.i64<divby 4>) -> !cute.int_tuple<"?{i64 div=4}">
      %ptr_26 = cute.add_offset(%ptr_12, %int_tuple_25) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=4}">) -> !cute.ptr<f32, gmem>
      %stride_27 = cute.make_stride(%46) : (i64) -> !cute.stride<"((0,(1,?{i64})),0,0)">
      %lay_28 = cute.make_layout(%21, %stride_27) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %rmem = cute.memref.alloca() : !memref_rmem_f32_
      %iter_29 = cute.get_iter(%rmem) : !memref_rmem_f32_
      %rmem_30 = cute.memref.alloca() : !memref_rmem_f32_
      %iter_31 = cute.get_iter(%rmem_30) : !memref_rmem_f32_
      %rmem_32 = cute.memref.alloca() : !memref_rmem_f32_
      %50 = arith.muli %35, %c4_i32 : i32
      %iv_33 = cute.assume(%50) : (i32) -> !cute.i32<divby 4>
      %iv_34 = cute.assume(%37) : (i32) -> !cute.i32<divby 4>
      %int_tuple_35 = cute.make_int_tuple(%iv_33, %iv_34) : (!cute.i32<divby 4>, !cute.i32<divby 4>) -> !cute.int_tuple<"(?{div=4},?{div=4})">
      %tup_36 = cute.add_offset(%tup, %int_tuple_35) : (!cute.int_tuple<"(?{div=16},?{div=128})">, !cute.int_tuple<"(?{div=4},?{div=4})">) -> !cute.int_tuple<"(?{div=4},?{div=4})">
      %rmem_37 = cute.memref.alloca() : !memref_rmem_i8_
      %coord_38 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %51:2 = cute.get_scalars(%coord_38) : !cute.coord<"(?,?)">
      cf.br ^bb1(%c0_i32 : i32)
    ^bb1(%52: i32):  // 2 preds: ^bb0, ^bb2
      %53 = arith.cmpi slt, %52, %c16_i32 : i32
      cf.cond_br %53, ^bb2, ^bb3
    ^bb2:  // pred: ^bb1
      %coord_39 = cute.make_coord(%52) : (i32) -> !cute.coord<"?">
      %idx_40 = cute.crd2idx(%coord_39, %20) : (!cute.coord<"?">, !cute.layout<"((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">) -> !cute.int_tuple<"(?,?)">
      %tup_41 = cute.add_offset(%tup_36, %idx_40) : (!cute.int_tuple<"(?{div=4},?{div=4})">, !cute.int_tuple<"(?,?)">) -> !cute.int_tuple<"(?,?)">
      %e0, %e1 = cute.get_leaves(%tup_41) : !cute.int_tuple<"(?,?)">
      %coord_42 = cute.make_coord(%e0, %e1) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
      %54:2 = cute.get_scalars(%coord_42) : !cute.coord<"(?,?)">
      %55 = arith.cmpi slt, %54#0, %51#0 : i32
      %56 = arith.cmpi slt, %54#1, %51#1 : i32
      %57 = arith.andi %55, %56 : i1
      %58 = arith.extui %57 : i1 to i8
      cute.memref.store(%rmem_37, %coord_39, %58) : (!memref_rmem_i8_, !cute.coord<"?">, i8) -> ()
      %59 = arith.addi %52, %c1_i32 : i32
      cf.br ^bb1(%59 : i32)
    ^bb3:  // pred: ^bb1
      %iter_43 = cute.get_iter(%rmem_37) : !memref_rmem_i8_
      %append = cute.append_to_rank<2> (%lay_23, %19) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">
      %60 = cute.get_scalars(%append) <{only_dynamic}> : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %stride_44 = cute.make_stride(%60) : (i64) -> !cute.stride<"((0,(1,?{i64})),(0,0))">
      %lay_45 = cute.make_layout(%18, %stride_44) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %append_46 = cute.append_to_rank<2> (%lay_45, %19) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">, !cute.layout<"1:0">
      %61 = cute.get_scalars(%append_46) <{only_dynamic}> : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %stride_47 = cute.make_stride(%61) : (i64) -> !cute.stride<"((0,(1,?{i64})),((0,0)))">
      %lay_48 = cute.make_layout(%17, %stride_47) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
      %62 = cute.get_scalars(%16) : !cute.int_tuple<"1">
      %63 = cute.get_scalars(%lay_48) <{only_dynamic}> : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
      %stride_49 = cute.make_stride(%63) : (i64) -> !cute.stride<"((0,(1,?{i64})))">
      %lay_50 = cute.make_layout(%15, %stride_49) : !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
      %64 = cute.get_scalars(%lay_50) <{only_dynamic}> : !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
      %65 = builtin.unrealized_conversion_cast %iter_43 : !cute.ptr<i8, rmem, align<32>> to !llvm.ptr
      %ptr_51 = cute.add_offset(%iter_43, %16) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
      %66 = builtin.unrealized_conversion_cast %ptr_51 : !cute.ptr<i8, rmem> to !llvm.ptr
      %ptr_52 = cute.add_offset(%iter_43, %13) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem, align<2>>
      %67 = builtin.unrealized_conversion_cast %ptr_52 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
      %ptr_53 = cute.add_offset(%iter_43, %12) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
      %68 = builtin.unrealized_conversion_cast %ptr_53 : !cute.ptr<i8, rmem> to !llvm.ptr
      %ptr_54 = cute.add_offset(%iter_43, %11) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem, align<4>>
      %69 = builtin.unrealized_conversion_cast %ptr_54 : !cute.ptr<i8, rmem, align<4>> to !llvm.ptr
      %ptr_55 = cute.add_offset(%iter_43, %10) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
      %70 = builtin.unrealized_conversion_cast %ptr_55 : !cute.ptr<i8, rmem> to !llvm.ptr
      %ptr_56 = cute.add_offset(%iter_43, %9) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem, align<2>>
      %71 = builtin.unrealized_conversion_cast %ptr_56 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
      %ptr_57 = cute.add_offset(%iter_43, %8) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
      %72 = builtin.unrealized_conversion_cast %ptr_57 : !cute.ptr<i8, rmem> to !llvm.ptr
      %ptr_58 = cute.add_offset(%iter_43, %7) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<i8, rmem, align<8>>
      %73 = builtin.unrealized_conversion_cast %ptr_58 : !cute.ptr<i8, rmem, align<8>> to !llvm.ptr
      %ptr_59 = cute.add_offset(%iter_43, %6) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<i8, rmem>
      %74 = builtin.unrealized_conversion_cast %ptr_59 : !cute.ptr<i8, rmem> to !llvm.ptr
      %ptr_60 = cute.add_offset(%iter_43, %5) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<i8, rmem, align<2>>
      %75 = builtin.unrealized_conversion_cast %ptr_60 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
      %ptr_61 = cute.add_offset(%iter_43, %4) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<i8, rmem>
      %76 = builtin.unrealized_conversion_cast %ptr_61 : !cute.ptr<i8, rmem> to !llvm.ptr
      %ptr_62 = cute.add_offset(%iter_43, %3) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<i8, rmem, align<4>>
      %77 = builtin.unrealized_conversion_cast %ptr_62 : !cute.ptr<i8, rmem, align<4>> to !llvm.ptr
      %ptr_63 = cute.add_offset(%iter_43, %2) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<i8, rmem>
      %78 = builtin.unrealized_conversion_cast %ptr_63 : !cute.ptr<i8, rmem> to !llvm.ptr
      %ptr_64 = cute.add_offset(%iter_43, %1) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<i8, rmem, align<2>>
      %79 = builtin.unrealized_conversion_cast %ptr_64 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
      %ptr_65 = cute.add_offset(%iter_43, %0) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<i8, rmem>
      %80 = builtin.unrealized_conversion_cast %ptr_65 : !cute.ptr<i8, rmem> to !llvm.ptr
      cf.br ^bb4(%c0_i32 : i32)
    ^bb4(%81: i32):  // 2 preds: ^bb3, ^bb40
      %82 = arith.cmpi slt, %81, %c10_i32 : i32
      cf.cond_br %82, ^bb5, ^bb41
    ^bb5:  // pred: ^bb4
      cf.br ^bb6(%c0_i32 : i32)
    ^bb6(%83: i32):  // 2 preds: ^bb5, ^bb39
      %84 = arith.cmpi slt, %83, %62 : i32
      cf.cond_br %84, ^bb7, ^bb40 {llvm.loop_annotation = #loop_annotation}
    ^bb7:  // pred: ^bb6
      %85 = llvm.load %65 : !llvm.ptr -> i8
      %86 = llvm.icmp "ne" %85, %14 : i8
      cf.cond_br %86, ^bb8, ^bb9
    ^bb8:  // pred: ^bb7
      %87 = builtin.unrealized_conversion_cast %ptr_21 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %88 = builtin.unrealized_conversion_cast %iter_31 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
      %89 = llvm.load %87 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %89, %88 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      cf.br ^bb9
    ^bb9:  // 2 preds: ^bb7, ^bb8
      %90 = llvm.load %66 : !llvm.ptr -> i8
      %91 = llvm.icmp "ne" %90, %14 : i8
      cf.cond_br %91, ^bb10, ^bb11
    ^bb10:  // pred: ^bb9
      %ptr_66 = cute.add_offset(%ptr_21, %16) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
      %ptr_67 = cute.add_offset(%iter_31, %16) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
      %92 = builtin.unrealized_conversion_cast %ptr_66 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %93 = builtin.unrealized_conversion_cast %ptr_67 : !cute.ptr<f32, rmem> to !llvm.ptr
      %94 = llvm.load %92 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %94, %93 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      cf.br ^bb11
    ^bb11:  // 2 preds: ^bb9, ^bb10
      %95 = llvm.load %67 : !llvm.ptr -> i8
      %96 = llvm.icmp "ne" %95, %14 : i8
      cf.cond_br %96, ^bb12, ^bb13
    ^bb12:  // pred: ^bb11
      %ptr_68 = cute.add_offset(%ptr_21, %13) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
      %ptr_69 = cute.add_offset(%iter_31, %13) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
      %97 = builtin.unrealized_conversion_cast %ptr_68 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %98 = builtin.unrealized_conversion_cast %ptr_69 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
      %99 = llvm.load %97 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %99, %98 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      cf.br ^bb13
    ^bb13:  // 2 preds: ^bb11, ^bb12
      %100 = llvm.load %68 : !llvm.ptr -> i8
      %101 = llvm.icmp "ne" %100, %14 : i8
      cf.cond_br %101, ^bb14, ^bb15
    ^bb14:  // pred: ^bb13
      %ptr_70 = cute.add_offset(%ptr_21, %12) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
      %ptr_71 = cute.add_offset(%iter_31, %12) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
      %102 = builtin.unrealized_conversion_cast %ptr_70 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %103 = builtin.unrealized_conversion_cast %ptr_71 : !cute.ptr<f32, rmem> to !llvm.ptr
      %104 = llvm.load %102 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %104, %103 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      cf.br ^bb15
    ^bb15:  // 2 preds: ^bb13, ^bb14
      %105 = llvm.load %69 : !llvm.ptr -> i8
      %106 = llvm.icmp "ne" %105, %14 : i8
      cf.cond_br %106, ^bb16, ^bb17
    ^bb16:  // pred: ^bb15
      %int_tuple_72 = cute.make_int_tuple(%64) : (i64) -> !cute.int_tuple<"?{i64}">
      %ptr_73 = cute.add_offset(%ptr_21, %int_tuple_72) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %ptr_74 = cute.add_offset(%iter_31, %11) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
      %107 = builtin.unrealized_conversion_cast %ptr_73 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %108 = builtin.unrealized_conversion_cast %ptr_74 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %109 = llvm.load %107 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %109, %108 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      cf.br ^bb17
    ^bb17:  // 2 preds: ^bb15, ^bb16
      %110 = llvm.load %70 : !llvm.ptr -> i8
      %111 = llvm.icmp "ne" %110, %14 : i8
      cf.cond_br %111, ^bb18, ^bb19
    ^bb18:  // pred: ^bb17
      %112 = arith.addi %64, %c1_i64 : i64
      %int_tuple_75 = cute.make_int_tuple(%112) : (i64) -> !cute.int_tuple<"?{i64}">
      %ptr_76 = cute.add_offset(%ptr_21, %int_tuple_75) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %ptr_77 = cute.add_offset(%iter_31, %10) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<f32, rmem>
      %113 = builtin.unrealized_conversion_cast %ptr_76 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %114 = builtin.unrealized_conversion_cast %ptr_77 : !cute.ptr<f32, rmem> to !llvm.ptr
      %115 = llvm.load %113 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %115, %114 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      cf.br ^bb19
    ^bb19:  // 2 preds: ^bb17, ^bb18
      %116 = llvm.load %71 : !llvm.ptr -> i8
      %117 = llvm.icmp "ne" %116, %14 : i8
      cf.cond_br %117, ^bb20, ^bb21
    ^bb20:  // pred: ^bb19
      %118 = arith.addi %64, %c2_i64 : i64
      %int_tuple_78 = cute.make_int_tuple(%118) : (i64) -> !cute.int_tuple<"?{i64}">
      %ptr_79 = cute.add_offset(%ptr_21, %int_tuple_78) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %ptr_80 = cute.add_offset(%iter_31, %9) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
      %119 = builtin.unrealized_conversion_cast %ptr_79 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %120 = builtin.unrealized_conversion_cast %ptr_80 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
      %121 = llvm.load %119 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %121, %120 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      cf.br ^bb21
    ^bb21:  // 2 preds: ^bb19, ^bb20
      %122 = llvm.load %72 : !llvm.ptr -> i8
      %123 = llvm.icmp "ne" %122, %14 : i8
      cf.cond_br %123, ^bb22, ^bb23
    ^bb22:  // pred: ^bb21
      %124 = arith.addi %64, %c3_i64 : i64
      %int_tuple_81 = cute.make_int_tuple(%124) : (i64) -> !cute.int_tuple<"?{i64}">
      %ptr_82 = cute.add_offset(%ptr_21, %int_tuple_81) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %ptr_83 = cute.add_offset(%iter_31, %8) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<f32, rmem>
      %125 = builtin.unrealized_conversion_cast %ptr_82 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %126 = builtin.unrealized_conversion_cast %ptr_83 : !cute.ptr<f32, rmem> to !llvm.ptr
      %127 = llvm.load %125 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %127, %126 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      cf.br ^bb23
    ^bb23:  // 2 preds: ^bb21, ^bb22
      %128 = llvm.load %73 : !llvm.ptr -> i8
      %129 = llvm.icmp "ne" %128, %14 : i8
      cf.cond_br %129, ^bb24, ^bb25
    ^bb24:  // pred: ^bb23
      %130 = arith.muli %64, %c2_i64 : i64
      %iv_84 = cute.assume(%130) : (i64) -> !cute.i64<divby 2>
      %int_tuple_85 = cute.make_int_tuple(%iv_84) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
      %ptr_86 = cute.add_offset(%ptr_21, %int_tuple_85) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
      %ptr_87 = cute.add_offset(%iter_31, %7) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<f32, rmem, align<32>>
      %131 = builtin.unrealized_conversion_cast %ptr_86 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %132 = builtin.unrealized_conversion_cast %ptr_87 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
      %133 = llvm.load %131 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %133, %132 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      cf.br ^bb25
    ^bb25:  // 2 preds: ^bb23, ^bb24
      %134 = llvm.load %74 : !llvm.ptr -> i8
      %135 = llvm.icmp "ne" %134, %14 : i8
      cf.cond_br %135, ^bb26, ^bb27
    ^bb26:  // pred: ^bb25
      %136 = arith.muli %64, %c2_i64 : i64
      %137 = arith.addi %136, %c1_i64 : i64
      %int_tuple_88 = cute.make_int_tuple(%137) : (i64) -> !cute.int_tuple<"?{i64}">
      %ptr_89 = cute.add_offset(%ptr_21, %int_tuple_88) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %ptr_90 = cute.add_offset(%iter_31, %6) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<f32, rmem>
      %138 = builtin.unrealized_conversion_cast %ptr_89 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %139 = builtin.unrealized_conversion_cast %ptr_90 : !cute.ptr<f32, rmem> to !llvm.ptr
      %140 = llvm.load %138 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %140, %139 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      cf.br ^bb27
    ^bb27:  // 2 preds: ^bb25, ^bb26
      %141 = llvm.load %75 : !llvm.ptr -> i8
      %142 = llvm.icmp "ne" %141, %14 : i8
      cf.cond_br %142, ^bb28, ^bb29
    ^bb28:  // pred: ^bb27
      %143 = arith.muli %64, %c2_i64 : i64
      %144 = arith.addi %143, %c2_i64 : i64
      %iv_91 = cute.assume(%144) : (i64) -> !cute.i64<divby 2>
      %int_tuple_92 = cute.make_int_tuple(%iv_91) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
      %ptr_93 = cute.add_offset(%ptr_21, %int_tuple_92) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
      %ptr_94 = cute.add_offset(%iter_31, %5) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<f32, rmem, align<8>>
      %145 = builtin.unrealized_conversion_cast %ptr_93 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %146 = builtin.unrealized_conversion_cast %ptr_94 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
      %147 = llvm.load %145 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %147, %146 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      cf.br ^bb29
    ^bb29:  // 2 preds: ^bb27, ^bb28
      %148 = llvm.load %76 : !llvm.ptr -> i8
      %149 = llvm.icmp "ne" %148, %14 : i8
      cf.cond_br %149, ^bb30, ^bb31
    ^bb30:  // pred: ^bb29
      %150 = arith.muli %64, %c2_i64 : i64
      %151 = arith.addi %150, %c3_i64 : i64
      %int_tuple_95 = cute.make_int_tuple(%151) : (i64) -> !cute.int_tuple<"?{i64}">
      %ptr_96 = cute.add_offset(%ptr_21, %int_tuple_95) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %ptr_97 = cute.add_offset(%iter_31, %4) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<f32, rmem>
      %152 = builtin.unrealized_conversion_cast %ptr_96 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %153 = builtin.unrealized_conversion_cast %ptr_97 : !cute.ptr<f32, rmem> to !llvm.ptr
      %154 = llvm.load %152 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %154, %153 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      cf.br ^bb31
    ^bb31:  // 2 preds: ^bb29, ^bb30
      %155 = llvm.load %77 : !llvm.ptr -> i8
      %156 = llvm.icmp "ne" %155, %14 : i8
      cf.cond_br %156, ^bb32, ^bb33
    ^bb32:  // pred: ^bb31
      %157 = arith.muli %64, %c3_i64 : i64
      %iv_98 = cute.assume(%157) : (i64) -> !cute.i64<divby 3>
      %int_tuple_99 = cute.make_int_tuple(%iv_98) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
      %ptr_100 = cute.add_offset(%ptr_21, %int_tuple_99) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
      %ptr_101 = cute.add_offset(%iter_31, %3) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<f32, rmem, align<16>>
      %158 = builtin.unrealized_conversion_cast %ptr_100 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %159 = builtin.unrealized_conversion_cast %ptr_101 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %160 = llvm.load %158 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %160, %159 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      cf.br ^bb33
    ^bb33:  // 2 preds: ^bb31, ^bb32
      %161 = llvm.load %78 : !llvm.ptr -> i8
      %162 = llvm.icmp "ne" %161, %14 : i8
      cf.cond_br %162, ^bb34, ^bb35
    ^bb34:  // pred: ^bb33
      %163 = arith.muli %64, %c3_i64 : i64
      %164 = arith.addi %163, %c1_i64 : i64
      %int_tuple_102 = cute.make_int_tuple(%164) : (i64) -> !cute.int_tuple<"?{i64}">
      %ptr_103 = cute.add_offset(%ptr_21, %int_tuple_102) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %ptr_104 = cute.add_offset(%iter_31, %2) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<f32, rmem>
      %165 = builtin.unrealized_conversion_cast %ptr_103 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %166 = builtin.unrealized_conversion_cast %ptr_104 : !cute.ptr<f32, rmem> to !llvm.ptr
      %167 = llvm.load %165 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %167, %166 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      cf.br ^bb35
    ^bb35:  // 2 preds: ^bb33, ^bb34
      %168 = llvm.load %79 : !llvm.ptr -> i8
      %169 = llvm.icmp "ne" %168, %14 : i8
      cf.cond_br %169, ^bb36, ^bb37
    ^bb36:  // pred: ^bb35
      %170 = arith.muli %64, %c3_i64 : i64
      %171 = arith.addi %170, %c2_i64 : i64
      %int_tuple_105 = cute.make_int_tuple(%171) : (i64) -> !cute.int_tuple<"?{i64}">
      %ptr_106 = cute.add_offset(%ptr_21, %int_tuple_105) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %ptr_107 = cute.add_offset(%iter_31, %1) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<f32, rmem, align<8>>
      %172 = builtin.unrealized_conversion_cast %ptr_106 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %173 = builtin.unrealized_conversion_cast %ptr_107 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
      %174 = llvm.load %172 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %174, %173 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      cf.br ^bb37
    ^bb37:  // 2 preds: ^bb35, ^bb36
      %175 = llvm.load %80 : !llvm.ptr -> i8
      %176 = llvm.icmp "ne" %175, %14 : i8
      cf.cond_br %176, ^bb38, ^bb39
    ^bb38:  // pred: ^bb37
      %177 = arith.muli %64, %c3_i64 : i64
      %178 = arith.addi %177, %c3_i64 : i64
      %iv_108 = cute.assume(%178) : (i64) -> !cute.i64<divby 3>
      %int_tuple_109 = cute.make_int_tuple(%iv_108) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
      %ptr_110 = cute.add_offset(%ptr_21, %int_tuple_109) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
      %ptr_111 = cute.add_offset(%iter_31, %0) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<f32, rmem>
      %179 = builtin.unrealized_conversion_cast %ptr_110 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %180 = builtin.unrealized_conversion_cast %ptr_111 : !cute.ptr<f32, rmem> to !llvm.ptr
      %181 = llvm.load %179 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %181, %180 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      cf.br ^bb39
    ^bb39:  // 2 preds: ^bb37, ^bb38
      %182 = arith.addi %83, %c1_i32 : i32
      cf.br ^bb6(%182 : i32)
    ^bb40:  // pred: ^bb6
      %183 = arith.addi %81, %c1_i32 : i32
      cf.br ^bb4(%183 : i32)
    ^bb41:  // pred: ^bb4
      llvm.inline_asm has_side_effects asm_dialect = att "griddepcontrol.wait;", ""  : () -> ()
      %append_112 = cute.append_to_rank<2> (%lay_18, %19) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">
      %184 = cute.get_scalars(%append_112) <{only_dynamic}> : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %stride_113 = cute.make_stride(%184) : (i64) -> !cute.stride<"((0,(1,?{i64})),(0,0))">
      %lay_114 = cute.make_layout(%18, %stride_113) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %append_115 = cute.append_to_rank<2> (%lay_114, %19) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">, !cute.layout<"1:0">
      %185 = cute.get_scalars(%append_115) <{only_dynamic}> : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %stride_116 = cute.make_stride(%185) : (i64) -> !cute.stride<"((0,(1,?{i64})),((0,0)))">
      %lay_117 = cute.make_layout(%17, %stride_116) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
      %186 = cute.get_scalars(%16) : !cute.int_tuple<"1">
      %187 = cute.get_scalars(%lay_117) <{only_dynamic}> : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
      %stride_118 = cute.make_stride(%187) : (i64) -> !cute.stride<"((0,(1,?{i64})))">
      %lay_119 = cute.make_layout(%15, %stride_118) : !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
      %188 = cute.get_scalars(%lay_119) <{only_dynamic}> : !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
      %189 = builtin.unrealized_conversion_cast %iter_43 : !cute.ptr<i8, rmem, align<32>> to !llvm.ptr
      %ptr_120 = cute.add_offset(%iter_43, %16) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
      %190 = builtin.unrealized_conversion_cast %ptr_120 : !cute.ptr<i8, rmem> to !llvm.ptr
      %ptr_121 = cute.add_offset(%iter_43, %13) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem, align<2>>
      %191 = builtin.unrealized_conversion_cast %ptr_121 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
      %ptr_122 = cute.add_offset(%iter_43, %12) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
      %192 = builtin.unrealized_conversion_cast %ptr_122 : !cute.ptr<i8, rmem> to !llvm.ptr
      %ptr_123 = cute.add_offset(%iter_43, %11) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem, align<4>>
      %193 = builtin.unrealized_conversion_cast %ptr_123 : !cute.ptr<i8, rmem, align<4>> to !llvm.ptr
      %ptr_124 = cute.add_offset(%iter_43, %10) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
      %194 = builtin.unrealized_conversion_cast %ptr_124 : !cute.ptr<i8, rmem> to !llvm.ptr
      %ptr_125 = cute.add_offset(%iter_43, %9) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem, align<2>>
      %195 = builtin.unrealized_conversion_cast %ptr_125 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
      %ptr_126 = cute.add_offset(%iter_43, %8) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
      %196 = builtin.unrealized_conversion_cast %ptr_126 : !cute.ptr<i8, rmem> to !llvm.ptr
      %ptr_127 = cute.add_offset(%iter_43, %7) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<i8, rmem, align<8>>
      %197 = builtin.unrealized_conversion_cast %ptr_127 : !cute.ptr<i8, rmem, align<8>> to !llvm.ptr
      %ptr_128 = cute.add_offset(%iter_43, %6) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<i8, rmem>
      %198 = builtin.unrealized_conversion_cast %ptr_128 : !cute.ptr<i8, rmem> to !llvm.ptr
      %ptr_129 = cute.add_offset(%iter_43, %5) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<i8, rmem, align<2>>
      %199 = builtin.unrealized_conversion_cast %ptr_129 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
      %ptr_130 = cute.add_offset(%iter_43, %4) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<i8, rmem>
      %200 = builtin.unrealized_conversion_cast %ptr_130 : !cute.ptr<i8, rmem> to !llvm.ptr
      %ptr_131 = cute.add_offset(%iter_43, %3) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<i8, rmem, align<4>>
      %201 = builtin.unrealized_conversion_cast %ptr_131 : !cute.ptr<i8, rmem, align<4>> to !llvm.ptr
      %ptr_132 = cute.add_offset(%iter_43, %2) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<i8, rmem>
      %202 = builtin.unrealized_conversion_cast %ptr_132 : !cute.ptr<i8, rmem> to !llvm.ptr
      %ptr_133 = cute.add_offset(%iter_43, %1) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<i8, rmem, align<2>>
      %203 = builtin.unrealized_conversion_cast %ptr_133 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
      %ptr_134 = cute.add_offset(%iter_43, %0) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<i8, rmem>
      %204 = builtin.unrealized_conversion_cast %ptr_134 : !cute.ptr<i8, rmem> to !llvm.ptr
      cf.br ^bb42(%c0_i32 : i32)
    ^bb42(%205: i32):  // 2 preds: ^bb41, ^bb78
      %206 = arith.cmpi slt, %205, %c10_i32 : i32
      cf.cond_br %206, ^bb43, ^bb79
    ^bb43:  // pred: ^bb42
      cf.br ^bb44(%c0_i32 : i32)
    ^bb44(%207: i32):  // 2 preds: ^bb43, ^bb77
      %208 = arith.cmpi slt, %207, %186 : i32
      cf.cond_br %208, ^bb45, ^bb78 {llvm.loop_annotation = #loop_annotation}
    ^bb45:  // pred: ^bb44
      %209 = llvm.load %189 : !llvm.ptr -> i8
      %210 = llvm.icmp "ne" %209, %14 : i8
      cf.cond_br %210, ^bb46, ^bb47
    ^bb46:  // pred: ^bb45
      %211 = builtin.unrealized_conversion_cast %ptr_16 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %212 = builtin.unrealized_conversion_cast %iter_29 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
      %213 = llvm.load %211 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %213, %212 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      cf.br ^bb47
    ^bb47:  // 2 preds: ^bb45, ^bb46
      %214 = llvm.load %190 : !llvm.ptr -> i8
      %215 = llvm.icmp "ne" %214, %14 : i8
      cf.cond_br %215, ^bb48, ^bb49
    ^bb48:  // pred: ^bb47
      %ptr_135 = cute.add_offset(%ptr_16, %16) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
      %ptr_136 = cute.add_offset(%iter_29, %16) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
      %216 = builtin.unrealized_conversion_cast %ptr_135 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %217 = builtin.unrealized_conversion_cast %ptr_136 : !cute.ptr<f32, rmem> to !llvm.ptr
      %218 = llvm.load %216 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %218, %217 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      cf.br ^bb49
    ^bb49:  // 2 preds: ^bb47, ^bb48
      %219 = llvm.load %191 : !llvm.ptr -> i8
      %220 = llvm.icmp "ne" %219, %14 : i8
      cf.cond_br %220, ^bb50, ^bb51
    ^bb50:  // pred: ^bb49
      %ptr_137 = cute.add_offset(%ptr_16, %13) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
      %ptr_138 = cute.add_offset(%iter_29, %13) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
      %221 = builtin.unrealized_conversion_cast %ptr_137 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %222 = builtin.unrealized_conversion_cast %ptr_138 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
      %223 = llvm.load %221 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %223, %222 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      cf.br ^bb51
    ^bb51:  // 2 preds: ^bb49, ^bb50
      %224 = llvm.load %192 : !llvm.ptr -> i8
      %225 = llvm.icmp "ne" %224, %14 : i8
      cf.cond_br %225, ^bb52, ^bb53
    ^bb52:  // pred: ^bb51
      %ptr_139 = cute.add_offset(%ptr_16, %12) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
      %ptr_140 = cute.add_offset(%iter_29, %12) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
      %226 = builtin.unrealized_conversion_cast %ptr_139 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %227 = builtin.unrealized_conversion_cast %ptr_140 : !cute.ptr<f32, rmem> to !llvm.ptr
      %228 = llvm.load %226 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %228, %227 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      cf.br ^bb53
    ^bb53:  // 2 preds: ^bb51, ^bb52
      %229 = llvm.load %193 : !llvm.ptr -> i8
      %230 = llvm.icmp "ne" %229, %14 : i8
      cf.cond_br %230, ^bb54, ^bb55
    ^bb54:  // pred: ^bb53
      %int_tuple_141 = cute.make_int_tuple(%188) : (i64) -> !cute.int_tuple<"?{i64}">
      %ptr_142 = cute.add_offset(%ptr_16, %int_tuple_141) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %ptr_143 = cute.add_offset(%iter_29, %11) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
      %231 = builtin.unrealized_conversion_cast %ptr_142 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %232 = builtin.unrealized_conversion_cast %ptr_143 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %233 = llvm.load %231 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %233, %232 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      cf.br ^bb55
    ^bb55:  // 2 preds: ^bb53, ^bb54
      %234 = llvm.load %194 : !llvm.ptr -> i8
      %235 = llvm.icmp "ne" %234, %14 : i8
      cf.cond_br %235, ^bb56, ^bb57
    ^bb56:  // pred: ^bb55
      %236 = arith.addi %188, %c1_i64 : i64
      %int_tuple_144 = cute.make_int_tuple(%236) : (i64) -> !cute.int_tuple<"?{i64}">
      %ptr_145 = cute.add_offset(%ptr_16, %int_tuple_144) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %ptr_146 = cute.add_offset(%iter_29, %10) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<f32, rmem>
      %237 = builtin.unrealized_conversion_cast %ptr_145 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %238 = builtin.unrealized_conversion_cast %ptr_146 : !cute.ptr<f32, rmem> to !llvm.ptr
      %239 = llvm.load %237 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %239, %238 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      cf.br ^bb57
    ^bb57:  // 2 preds: ^bb55, ^bb56
      %240 = llvm.load %195 : !llvm.ptr -> i8
      %241 = llvm.icmp "ne" %240, %14 : i8
      cf.cond_br %241, ^bb58, ^bb59
    ^bb58:  // pred: ^bb57
      %242 = arith.addi %188, %c2_i64 : i64
      %int_tuple_147 = cute.make_int_tuple(%242) : (i64) -> !cute.int_tuple<"?{i64}">
      %ptr_148 = cute.add_offset(%ptr_16, %int_tuple_147) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %ptr_149 = cute.add_offset(%iter_29, %9) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
      %243 = builtin.unrealized_conversion_cast %ptr_148 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %244 = builtin.unrealized_conversion_cast %ptr_149 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
      %245 = llvm.load %243 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %245, %244 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      cf.br ^bb59
    ^bb59:  // 2 preds: ^bb57, ^bb58
      %246 = llvm.load %196 : !llvm.ptr -> i8
      %247 = llvm.icmp "ne" %246, %14 : i8
      cf.cond_br %247, ^bb60, ^bb61
    ^bb60:  // pred: ^bb59
      %248 = arith.addi %188, %c3_i64 : i64
      %int_tuple_150 = cute.make_int_tuple(%248) : (i64) -> !cute.int_tuple<"?{i64}">
      %ptr_151 = cute.add_offset(%ptr_16, %int_tuple_150) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %ptr_152 = cute.add_offset(%iter_29, %8) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<f32, rmem>
      %249 = builtin.unrealized_conversion_cast %ptr_151 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %250 = builtin.unrealized_conversion_cast %ptr_152 : !cute.ptr<f32, rmem> to !llvm.ptr
      %251 = llvm.load %249 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %251, %250 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      cf.br ^bb61
    ^bb61:  // 2 preds: ^bb59, ^bb60
      %252 = llvm.load %197 : !llvm.ptr -> i8
      %253 = llvm.icmp "ne" %252, %14 : i8
      cf.cond_br %253, ^bb62, ^bb63
    ^bb62:  // pred: ^bb61
      %254 = arith.muli %188, %c2_i64 : i64
      %iv_153 = cute.assume(%254) : (i64) -> !cute.i64<divby 2>
      %int_tuple_154 = cute.make_int_tuple(%iv_153) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
      %ptr_155 = cute.add_offset(%ptr_16, %int_tuple_154) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
      %ptr_156 = cute.add_offset(%iter_29, %7) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<f32, rmem, align<32>>
      %255 = builtin.unrealized_conversion_cast %ptr_155 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %256 = builtin.unrealized_conversion_cast %ptr_156 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
      %257 = llvm.load %255 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %257, %256 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      cf.br ^bb63
    ^bb63:  // 2 preds: ^bb61, ^bb62
      %258 = llvm.load %198 : !llvm.ptr -> i8
      %259 = llvm.icmp "ne" %258, %14 : i8
      cf.cond_br %259, ^bb64, ^bb65
    ^bb64:  // pred: ^bb63
      %260 = arith.muli %188, %c2_i64 : i64
      %261 = arith.addi %260, %c1_i64 : i64
      %int_tuple_157 = cute.make_int_tuple(%261) : (i64) -> !cute.int_tuple<"?{i64}">
      %ptr_158 = cute.add_offset(%ptr_16, %int_tuple_157) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %ptr_159 = cute.add_offset(%iter_29, %6) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<f32, rmem>
      %262 = builtin.unrealized_conversion_cast %ptr_158 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %263 = builtin.unrealized_conversion_cast %ptr_159 : !cute.ptr<f32, rmem> to !llvm.ptr
      %264 = llvm.load %262 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %264, %263 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      cf.br ^bb65
    ^bb65:  // 2 preds: ^bb63, ^bb64
      %265 = llvm.load %199 : !llvm.ptr -> i8
      %266 = llvm.icmp "ne" %265, %14 : i8
      cf.cond_br %266, ^bb66, ^bb67
    ^bb66:  // pred: ^bb65
      %267 = arith.muli %188, %c2_i64 : i64
      %268 = arith.addi %267, %c2_i64 : i64
      %iv_160 = cute.assume(%268) : (i64) -> !cute.i64<divby 2>
      %int_tuple_161 = cute.make_int_tuple(%iv_160) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
      %ptr_162 = cute.add_offset(%ptr_16, %int_tuple_161) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
      %ptr_163 = cute.add_offset(%iter_29, %5) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<f32, rmem, align<8>>
      %269 = builtin.unrealized_conversion_cast %ptr_162 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %270 = builtin.unrealized_conversion_cast %ptr_163 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
      %271 = llvm.load %269 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %271, %270 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      cf.br ^bb67
    ^bb67:  // 2 preds: ^bb65, ^bb66
      %272 = llvm.load %200 : !llvm.ptr -> i8
      %273 = llvm.icmp "ne" %272, %14 : i8
      cf.cond_br %273, ^bb68, ^bb69
    ^bb68:  // pred: ^bb67
      %274 = arith.muli %188, %c2_i64 : i64
      %275 = arith.addi %274, %c3_i64 : i64
      %int_tuple_164 = cute.make_int_tuple(%275) : (i64) -> !cute.int_tuple<"?{i64}">
      %ptr_165 = cute.add_offset(%ptr_16, %int_tuple_164) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %ptr_166 = cute.add_offset(%iter_29, %4) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<f32, rmem>
      %276 = builtin.unrealized_conversion_cast %ptr_165 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %277 = builtin.unrealized_conversion_cast %ptr_166 : !cute.ptr<f32, rmem> to !llvm.ptr
      %278 = llvm.load %276 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %278, %277 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      cf.br ^bb69
    ^bb69:  // 2 preds: ^bb67, ^bb68
      %279 = llvm.load %201 : !llvm.ptr -> i8
      %280 = llvm.icmp "ne" %279, %14 : i8
      cf.cond_br %280, ^bb70, ^bb71
    ^bb70:  // pred: ^bb69
      %281 = arith.muli %188, %c3_i64 : i64
      %iv_167 = cute.assume(%281) : (i64) -> !cute.i64<divby 3>
      %int_tuple_168 = cute.make_int_tuple(%iv_167) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
      %ptr_169 = cute.add_offset(%ptr_16, %int_tuple_168) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
      %ptr_170 = cute.add_offset(%iter_29, %3) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<f32, rmem, align<16>>
      %282 = builtin.unrealized_conversion_cast %ptr_169 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %283 = builtin.unrealized_conversion_cast %ptr_170 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %284 = llvm.load %282 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %284, %283 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      cf.br ^bb71
    ^bb71:  // 2 preds: ^bb69, ^bb70
      %285 = llvm.load %202 : !llvm.ptr -> i8
      %286 = llvm.icmp "ne" %285, %14 : i8
      cf.cond_br %286, ^bb72, ^bb73
    ^bb72:  // pred: ^bb71
      %287 = arith.muli %188, %c3_i64 : i64
      %288 = arith.addi %287, %c1_i64 : i64
      %int_tuple_171 = cute.make_int_tuple(%288) : (i64) -> !cute.int_tuple<"?{i64}">
      %ptr_172 = cute.add_offset(%ptr_16, %int_tuple_171) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %ptr_173 = cute.add_offset(%iter_29, %2) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<f32, rmem>
      %289 = builtin.unrealized_conversion_cast %ptr_172 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %290 = builtin.unrealized_conversion_cast %ptr_173 : !cute.ptr<f32, rmem> to !llvm.ptr
      %291 = llvm.load %289 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %291, %290 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      cf.br ^bb73
    ^bb73:  // 2 preds: ^bb71, ^bb72
      %292 = llvm.load %203 : !llvm.ptr -> i8
      %293 = llvm.icmp "ne" %292, %14 : i8
      cf.cond_br %293, ^bb74, ^bb75
    ^bb74:  // pred: ^bb73
      %294 = arith.muli %188, %c3_i64 : i64
      %295 = arith.addi %294, %c2_i64 : i64
      %int_tuple_174 = cute.make_int_tuple(%295) : (i64) -> !cute.int_tuple<"?{i64}">
      %ptr_175 = cute.add_offset(%ptr_16, %int_tuple_174) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %ptr_176 = cute.add_offset(%iter_29, %1) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<f32, rmem, align<8>>
      %296 = builtin.unrealized_conversion_cast %ptr_175 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %297 = builtin.unrealized_conversion_cast %ptr_176 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
      %298 = llvm.load %296 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %298, %297 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      cf.br ^bb75
    ^bb75:  // 2 preds: ^bb73, ^bb74
      %299 = llvm.load %204 : !llvm.ptr -> i8
      %300 = llvm.icmp "ne" %299, %14 : i8
      cf.cond_br %300, ^bb76, ^bb77
    ^bb76:  // pred: ^bb75
      %301 = arith.muli %188, %c3_i64 : i64
      %302 = arith.addi %301, %c3_i64 : i64
      %iv_177 = cute.assume(%302) : (i64) -> !cute.i64<divby 3>
      %int_tuple_178 = cute.make_int_tuple(%iv_177) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
      %ptr_179 = cute.add_offset(%ptr_16, %int_tuple_178) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
      %ptr_180 = cute.add_offset(%iter_29, %0) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<f32, rmem>
      %303 = builtin.unrealized_conversion_cast %ptr_179 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %304 = builtin.unrealized_conversion_cast %ptr_180 : !cute.ptr<f32, rmem> to !llvm.ptr
      %305 = llvm.load %303 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %305, %304 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      cf.br ^bb77
    ^bb77:  // 2 preds: ^bb75, ^bb76
      %306 = arith.addi %207, %c1_i32 : i32
      cf.br ^bb44(%306 : i32)
    ^bb78:  // pred: ^bb44
      %307 = arith.addi %205, %c1_i32 : i32
      cf.br ^bb42(%307 : i32)
    ^bb79:  // pred: ^bb42
      cf.br ^bb80(%c0_i32 : i32)
    ^bb80(%308: i32):  // 2 preds: ^bb79, ^bb81
      %309 = arith.cmpi slt, %308, %c10_i32 : i32
      cf.cond_br %309, ^bb81, ^bb82
    ^bb81:  // pred: ^bb80
      %310 = cute.memref.load_vec %rmem : !memref_rmem_f32_
      %311 = cute.memref.load_vec %rmem_30 : !memref_rmem_f32_
      %312 = arith.addf %310, %311 : vector<16xf32>
      cute.memref.store_vec %312, %rmem_32 : !memref_rmem_f32_
      %313 = arith.addi %308, %c1_i32 : i32
      cf.br ^bb80(%313 : i32)
    ^bb82:  // pred: ^bb80
      %iter_181 = cute.get_iter(%rmem_32) : !memref_rmem_f32_
      %append_182 = cute.append_to_rank<2> (%lay_28, %19) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">
      %314 = cute.get_scalars(%append_182) <{only_dynamic}> : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %stride_183 = cute.make_stride(%314) : (i64) -> !cute.stride<"((0,(1,?{i64})),(0,0))">
      %lay_184 = cute.make_layout(%18, %stride_183) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %append_185 = cute.append_to_rank<2> (%lay_184, %19) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">, !cute.layout<"1:0">
      %315 = cute.get_scalars(%append_185) <{only_dynamic}> : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %stride_186 = cute.make_stride(%315) : (i64) -> !cute.stride<"((0,(1,?{i64})),((0,0)))">
      %lay_187 = cute.make_layout(%17, %stride_186) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
      %316 = cute.get_scalars(%16) : !cute.int_tuple<"1">
      %317 = cute.get_scalars(%lay_187) <{only_dynamic}> : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
      %stride_188 = cute.make_stride(%317) : (i64) -> !cute.stride<"((0,(1,?{i64})))">
      %lay_189 = cute.make_layout(%15, %stride_188) : !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
      %318 = cute.get_scalars(%lay_189) <{only_dynamic}> : !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
      %319 = builtin.unrealized_conversion_cast %iter_43 : !cute.ptr<i8, rmem, align<32>> to !llvm.ptr
      %ptr_190 = cute.add_offset(%iter_43, %16) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
      %320 = builtin.unrealized_conversion_cast %ptr_190 : !cute.ptr<i8, rmem> to !llvm.ptr
      %ptr_191 = cute.add_offset(%iter_43, %13) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem, align<2>>
      %321 = builtin.unrealized_conversion_cast %ptr_191 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
      %ptr_192 = cute.add_offset(%iter_43, %12) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
      %322 = builtin.unrealized_conversion_cast %ptr_192 : !cute.ptr<i8, rmem> to !llvm.ptr
      %ptr_193 = cute.add_offset(%iter_43, %11) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem, align<4>>
      %323 = builtin.unrealized_conversion_cast %ptr_193 : !cute.ptr<i8, rmem, align<4>> to !llvm.ptr
      %ptr_194 = cute.add_offset(%iter_43, %10) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
      %324 = builtin.unrealized_conversion_cast %ptr_194 : !cute.ptr<i8, rmem> to !llvm.ptr
      %ptr_195 = cute.add_offset(%iter_43, %9) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem, align<2>>
      %325 = builtin.unrealized_conversion_cast %ptr_195 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
      %ptr_196 = cute.add_offset(%iter_43, %8) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
      %326 = builtin.unrealized_conversion_cast %ptr_196 : !cute.ptr<i8, rmem> to !llvm.ptr
      %ptr_197 = cute.add_offset(%iter_43, %7) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<i8, rmem, align<8>>
      %327 = builtin.unrealized_conversion_cast %ptr_197 : !cute.ptr<i8, rmem, align<8>> to !llvm.ptr
      %ptr_198 = cute.add_offset(%iter_43, %6) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<i8, rmem>
      %328 = builtin.unrealized_conversion_cast %ptr_198 : !cute.ptr<i8, rmem> to !llvm.ptr
      %ptr_199 = cute.add_offset(%iter_43, %5) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<i8, rmem, align<2>>
      %329 = builtin.unrealized_conversion_cast %ptr_199 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
      %ptr_200 = cute.add_offset(%iter_43, %4) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<i8, rmem>
      %330 = builtin.unrealized_conversion_cast %ptr_200 : !cute.ptr<i8, rmem> to !llvm.ptr
      %ptr_201 = cute.add_offset(%iter_43, %3) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<i8, rmem, align<4>>
      %331 = builtin.unrealized_conversion_cast %ptr_201 : !cute.ptr<i8, rmem, align<4>> to !llvm.ptr
      %ptr_202 = cute.add_offset(%iter_43, %2) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<i8, rmem>
      %332 = builtin.unrealized_conversion_cast %ptr_202 : !cute.ptr<i8, rmem> to !llvm.ptr
      %ptr_203 = cute.add_offset(%iter_43, %1) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<i8, rmem, align<2>>
      %333 = builtin.unrealized_conversion_cast %ptr_203 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
      %ptr_204 = cute.add_offset(%iter_43, %0) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<i8, rmem>
      %334 = builtin.unrealized_conversion_cast %ptr_204 : !cute.ptr<i8, rmem> to !llvm.ptr
      cf.br ^bb83(%c0_i32 : i32)
    ^bb83(%335: i32):  // 2 preds: ^bb82, ^bb116
      %336 = arith.cmpi slt, %335, %316 : i32
      cf.cond_br %336, ^bb84, ^bb117 {llvm.loop_annotation = #loop_annotation}
    ^bb84:  // pred: ^bb83
      %337 = llvm.load %319 : !llvm.ptr -> i8
      %338 = llvm.icmp "ne" %337, %14 : i8
      cf.cond_br %338, ^bb85, ^bb86
    ^bb85:  // pred: ^bb84
      %339 = builtin.unrealized_conversion_cast %iter_181 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
      %340 = builtin.unrealized_conversion_cast %ptr_26 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %341 = llvm.load %339 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
      llvm.store %341, %340 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
      cf.br ^bb86
    ^bb86:  // 2 preds: ^bb84, ^bb85
      %342 = llvm.load %320 : !llvm.ptr -> i8
      %343 = llvm.icmp "ne" %342, %14 : i8
      cf.cond_br %343, ^bb87, ^bb88
    ^bb87:  // pred: ^bb86
      %ptr_205 = cute.add_offset(%iter_181, %16) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
      %ptr_206 = cute.add_offset(%ptr_26, %16) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
      %344 = builtin.unrealized_conversion_cast %ptr_205 : !cute.ptr<f32, rmem> to !llvm.ptr
      %345 = builtin.unrealized_conversion_cast %ptr_206 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %346 = llvm.load %344 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
      llvm.store %346, %345 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
      cf.br ^bb88
    ^bb88:  // 2 preds: ^bb86, ^bb87
      %347 = llvm.load %321 : !llvm.ptr -> i8
      %348 = llvm.icmp "ne" %347, %14 : i8
      cf.cond_br %348, ^bb89, ^bb90
    ^bb89:  // pred: ^bb88
      %ptr_207 = cute.add_offset(%iter_181, %13) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
      %ptr_208 = cute.add_offset(%ptr_26, %13) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
      %349 = builtin.unrealized_conversion_cast %ptr_207 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
      %350 = builtin.unrealized_conversion_cast %ptr_208 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %351 = llvm.load %349 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
      llvm.store %351, %350 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
      cf.br ^bb90
    ^bb90:  // 2 preds: ^bb88, ^bb89
      %352 = llvm.load %322 : !llvm.ptr -> i8
      %353 = llvm.icmp "ne" %352, %14 : i8
      cf.cond_br %353, ^bb91, ^bb92
    ^bb91:  // pred: ^bb90
      %ptr_209 = cute.add_offset(%iter_181, %12) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
      %ptr_210 = cute.add_offset(%ptr_26, %12) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
      %354 = builtin.unrealized_conversion_cast %ptr_209 : !cute.ptr<f32, rmem> to !llvm.ptr
      %355 = builtin.unrealized_conversion_cast %ptr_210 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %356 = llvm.load %354 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
      llvm.store %356, %355 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
      cf.br ^bb92
    ^bb92:  // 2 preds: ^bb90, ^bb91
      %357 = llvm.load %323 : !llvm.ptr -> i8
      %358 = llvm.icmp "ne" %357, %14 : i8
      cf.cond_br %358, ^bb93, ^bb94
    ^bb93:  // pred: ^bb92
      %ptr_211 = cute.add_offset(%iter_181, %11) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
      %int_tuple_212 = cute.make_int_tuple(%318) : (i64) -> !cute.int_tuple<"?{i64}">
      %ptr_213 = cute.add_offset(%ptr_26, %int_tuple_212) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %359 = builtin.unrealized_conversion_cast %ptr_211 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %360 = builtin.unrealized_conversion_cast %ptr_213 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %361 = llvm.load %359 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
      llvm.store %361, %360 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
      cf.br ^bb94
    ^bb94:  // 2 preds: ^bb92, ^bb93
      %362 = llvm.load %324 : !llvm.ptr -> i8
      %363 = llvm.icmp "ne" %362, %14 : i8
      cf.cond_br %363, ^bb95, ^bb96
    ^bb95:  // pred: ^bb94
      %ptr_214 = cute.add_offset(%iter_181, %10) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<f32, rmem>
      %364 = arith.addi %318, %c1_i64 : i64
      %int_tuple_215 = cute.make_int_tuple(%364) : (i64) -> !cute.int_tuple<"?{i64}">
      %ptr_216 = cute.add_offset(%ptr_26, %int_tuple_215) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %365 = builtin.unrealized_conversion_cast %ptr_214 : !cute.ptr<f32, rmem> to !llvm.ptr
      %366 = builtin.unrealized_conversion_cast %ptr_216 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %367 = llvm.load %365 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
      llvm.store %367, %366 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
      cf.br ^bb96
    ^bb96:  // 2 preds: ^bb94, ^bb95
      %368 = llvm.load %325 : !llvm.ptr -> i8
      %369 = llvm.icmp "ne" %368, %14 : i8
      cf.cond_br %369, ^bb97, ^bb98
    ^bb97:  // pred: ^bb96
      %ptr_217 = cute.add_offset(%iter_181, %9) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
      %370 = arith.addi %318, %c2_i64 : i64
      %int_tuple_218 = cute.make_int_tuple(%370) : (i64) -> !cute.int_tuple<"?{i64}">
      %ptr_219 = cute.add_offset(%ptr_26, %int_tuple_218) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %371 = builtin.unrealized_conversion_cast %ptr_217 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
      %372 = builtin.unrealized_conversion_cast %ptr_219 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %373 = llvm.load %371 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
      llvm.store %373, %372 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
      cf.br ^bb98
    ^bb98:  // 2 preds: ^bb96, ^bb97
      %374 = llvm.load %326 : !llvm.ptr -> i8
      %375 = llvm.icmp "ne" %374, %14 : i8
      cf.cond_br %375, ^bb99, ^bb100
    ^bb99:  // pred: ^bb98
      %ptr_220 = cute.add_offset(%iter_181, %8) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<f32, rmem>
      %376 = arith.addi %318, %c3_i64 : i64
      %int_tuple_221 = cute.make_int_tuple(%376) : (i64) -> !cute.int_tuple<"?{i64}">
      %ptr_222 = cute.add_offset(%ptr_26, %int_tuple_221) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %377 = builtin.unrealized_conversion_cast %ptr_220 : !cute.ptr<f32, rmem> to !llvm.ptr
      %378 = builtin.unrealized_conversion_cast %ptr_222 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %379 = llvm.load %377 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
      llvm.store %379, %378 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
      cf.br ^bb100
    ^bb100:  // 2 preds: ^bb98, ^bb99
      %380 = llvm.load %327 : !llvm.ptr -> i8
      %381 = llvm.icmp "ne" %380, %14 : i8
      cf.cond_br %381, ^bb101, ^bb102
    ^bb101:  // pred: ^bb100
      %ptr_223 = cute.add_offset(%iter_181, %7) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<f32, rmem, align<32>>
      %382 = arith.muli %318, %c2_i64 : i64
      %iv_224 = cute.assume(%382) : (i64) -> !cute.i64<divby 2>
      %int_tuple_225 = cute.make_int_tuple(%iv_224) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
      %ptr_226 = cute.add_offset(%ptr_26, %int_tuple_225) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
      %383 = builtin.unrealized_conversion_cast %ptr_223 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
      %384 = builtin.unrealized_conversion_cast %ptr_226 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %385 = llvm.load %383 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
      llvm.store %385, %384 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
      cf.br ^bb102
    ^bb102:  // 2 preds: ^bb100, ^bb101
      %386 = llvm.load %328 : !llvm.ptr -> i8
      %387 = llvm.icmp "ne" %386, %14 : i8
      cf.cond_br %387, ^bb103, ^bb104
    ^bb103:  // pred: ^bb102
      %ptr_227 = cute.add_offset(%iter_181, %6) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<f32, rmem>
      %388 = arith.muli %318, %c2_i64 : i64
      %389 = arith.addi %388, %c1_i64 : i64
      %int_tuple_228 = cute.make_int_tuple(%389) : (i64) -> !cute.int_tuple<"?{i64}">
      %ptr_229 = cute.add_offset(%ptr_26, %int_tuple_228) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %390 = builtin.unrealized_conversion_cast %ptr_227 : !cute.ptr<f32, rmem> to !llvm.ptr
      %391 = builtin.unrealized_conversion_cast %ptr_229 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %392 = llvm.load %390 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
      llvm.store %392, %391 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
      cf.br ^bb104
    ^bb104:  // 2 preds: ^bb102, ^bb103
      %393 = llvm.load %329 : !llvm.ptr -> i8
      %394 = llvm.icmp "ne" %393, %14 : i8
      cf.cond_br %394, ^bb105, ^bb106
    ^bb105:  // pred: ^bb104
      %ptr_230 = cute.add_offset(%iter_181, %5) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<f32, rmem, align<8>>
      %395 = arith.muli %318, %c2_i64 : i64
      %396 = arith.addi %395, %c2_i64 : i64
      %iv_231 = cute.assume(%396) : (i64) -> !cute.i64<divby 2>
      %int_tuple_232 = cute.make_int_tuple(%iv_231) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
      %ptr_233 = cute.add_offset(%ptr_26, %int_tuple_232) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
      %397 = builtin.unrealized_conversion_cast %ptr_230 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
      %398 = builtin.unrealized_conversion_cast %ptr_233 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %399 = llvm.load %397 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
      llvm.store %399, %398 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
      cf.br ^bb106
    ^bb106:  // 2 preds: ^bb104, ^bb105
      %400 = llvm.load %330 : !llvm.ptr -> i8
      %401 = llvm.icmp "ne" %400, %14 : i8
      cf.cond_br %401, ^bb107, ^bb108
    ^bb107:  // pred: ^bb106
      %ptr_234 = cute.add_offset(%iter_181, %4) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<f32, rmem>
      %402 = arith.muli %318, %c2_i64 : i64
      %403 = arith.addi %402, %c3_i64 : i64
      %int_tuple_235 = cute.make_int_tuple(%403) : (i64) -> !cute.int_tuple<"?{i64}">
      %ptr_236 = cute.add_offset(%ptr_26, %int_tuple_235) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %404 = builtin.unrealized_conversion_cast %ptr_234 : !cute.ptr<f32, rmem> to !llvm.ptr
      %405 = builtin.unrealized_conversion_cast %ptr_236 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %406 = llvm.load %404 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
      llvm.store %406, %405 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
      cf.br ^bb108
    ^bb108:  // 2 preds: ^bb106, ^bb107
      %407 = llvm.load %331 : !llvm.ptr -> i8
      %408 = llvm.icmp "ne" %407, %14 : i8
      cf.cond_br %408, ^bb109, ^bb110
    ^bb109:  // pred: ^bb108
      %ptr_237 = cute.add_offset(%iter_181, %3) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<f32, rmem, align<16>>
      %409 = arith.muli %318, %c3_i64 : i64
      %iv_238 = cute.assume(%409) : (i64) -> !cute.i64<divby 3>
      %int_tuple_239 = cute.make_int_tuple(%iv_238) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
      %ptr_240 = cute.add_offset(%ptr_26, %int_tuple_239) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
      %410 = builtin.unrealized_conversion_cast %ptr_237 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %411 = builtin.unrealized_conversion_cast %ptr_240 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %412 = llvm.load %410 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
      llvm.store %412, %411 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
      cf.br ^bb110
    ^bb110:  // 2 preds: ^bb108, ^bb109
      %413 = llvm.load %332 : !llvm.ptr -> i8
      %414 = llvm.icmp "ne" %413, %14 : i8
      cf.cond_br %414, ^bb111, ^bb112
    ^bb111:  // pred: ^bb110
      %ptr_241 = cute.add_offset(%iter_181, %2) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<f32, rmem>
      %415 = arith.muli %318, %c3_i64 : i64
      %416 = arith.addi %415, %c1_i64 : i64
      %int_tuple_242 = cute.make_int_tuple(%416) : (i64) -> !cute.int_tuple<"?{i64}">
      %ptr_243 = cute.add_offset(%ptr_26, %int_tuple_242) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %417 = builtin.unrealized_conversion_cast %ptr_241 : !cute.ptr<f32, rmem> to !llvm.ptr
      %418 = builtin.unrealized_conversion_cast %ptr_243 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %419 = llvm.load %417 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
      llvm.store %419, %418 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
      cf.br ^bb112
    ^bb112:  // 2 preds: ^bb110, ^bb111
      %420 = llvm.load %333 : !llvm.ptr -> i8
      %421 = llvm.icmp "ne" %420, %14 : i8
      cf.cond_br %421, ^bb113, ^bb114
    ^bb113:  // pred: ^bb112
      %ptr_244 = cute.add_offset(%iter_181, %1) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<f32, rmem, align<8>>
      %422 = arith.muli %318, %c3_i64 : i64
      %423 = arith.addi %422, %c2_i64 : i64
      %int_tuple_245 = cute.make_int_tuple(%423) : (i64) -> !cute.int_tuple<"?{i64}">
      %ptr_246 = cute.add_offset(%ptr_26, %int_tuple_245) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %424 = builtin.unrealized_conversion_cast %ptr_244 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
      %425 = builtin.unrealized_conversion_cast %ptr_246 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %426 = llvm.load %424 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
      llvm.store %426, %425 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
      cf.br ^bb114
    ^bb114:  // 2 preds: ^bb112, ^bb113
      %427 = llvm.load %334 : !llvm.ptr -> i8
      %428 = llvm.icmp "ne" %427, %14 : i8
      cf.cond_br %428, ^bb115, ^bb116
    ^bb115:  // pred: ^bb114
      %ptr_247 = cute.add_offset(%iter_181, %0) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<f32, rmem>
      %429 = arith.muli %318, %c3_i64 : i64
      %430 = arith.addi %429, %c3_i64 : i64
      %iv_248 = cute.assume(%430) : (i64) -> !cute.i64<divby 3>
      %int_tuple_249 = cute.make_int_tuple(%iv_248) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
      %ptr_250 = cute.add_offset(%ptr_26, %int_tuple_249) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
      %431 = builtin.unrealized_conversion_cast %ptr_247 : !cute.ptr<f32, rmem> to !llvm.ptr
      %432 = builtin.unrealized_conversion_cast %ptr_250 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %433 = llvm.load %431 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
      llvm.store %433, %432 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
      cf.br ^bb116
    ^bb116:  // 2 preds: ^bb114, ^bb115
      %434 = arith.addi %335, %c1_i32 : i32
      cf.br ^bb83(%434 : i32)
    ^bb117:  // pred: ^bb83
      return
    }
  }
  func.func @cutlass_elementwise_add_Tensorgmem_o_i641_Tensorgmem_o_i641_Tensorgmem_o_i641_CUstream_False_False(%arg0: !memref_gmem_f32_1, %arg1: !memref_gmem_f32_1, %arg2: !memref_gmem_f32_1, %arg3: !cuda.stream) -> i32 attributes {llvm.emit_c_interface} {
    %c0_i64 = arith.constant 0 : i64
    %c1_i32 = arith.constant 1 : i32
    %c0_i32 = arith.constant 0 : i32
    %0 = cute.static : !cute.stride<"((1@0,1@1),(16@0,128@1))">
    %1 = cute.static : !cute.stride<"(1@0,1@1)">
    %2 = cute.static : !cute.int_tuple<"(0,0)">
    %c128_i32 = arith.constant 128 : i32
    %c16_i64 = arith.constant 16 : i64
    %c16_i32 = arith.constant 16 : i32
    %iter = cute.get_iter(%arg0) : !memref_gmem_f32_1
    %lay = cute.get_layout(%arg0) : !memref_gmem_f32_1
    %3:3 = cute.get_scalars(%lay) <{only_dynamic}> : !cute.layout<"(?,?):(?{i64},1)">
    %4 = arith.ceildivsi %3#0, %c16_i32 : i32
    %5 = arith.muli %3#2, %c16_i64 : i64
    %6 = arith.ceildivsi %3#1, %c128_i32 : i32
    %shape = cute.make_shape(%4, %6) : (i32, i32) -> !cute.shape<"((16,128),(?,?))">
    %iv = cute.assume(%5) : (i64) -> !cute.i64<divby 16>
    %stride = cute.make_stride(%3#2, %iv) : (i64, !cute.i64<divby 16>) -> !cute.stride<"((?{i64},1),(?{i64 div=16},128))">
    %lay_0 = cute.make_layout(%shape, %stride) : !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
    %view = cute.make_view(%iter, %lay_0) : !memref_gmem_f32_
    %iter_1 = cute.get_iter(%arg1) : !memref_gmem_f32_1
    %lay_2 = cute.get_layout(%arg1) : !memref_gmem_f32_1
    %7:3 = cute.get_scalars(%lay_2) <{only_dynamic}> : !cute.layout<"(?,?):(?{i64},1)">
    %8 = arith.ceildivsi %7#0, %c16_i32 : i32
    %9 = arith.muli %7#2, %c16_i64 : i64
    %10 = arith.ceildivsi %7#1, %c128_i32 : i32
    %shape_3 = cute.make_shape(%8, %10) : (i32, i32) -> !cute.shape<"((16,128),(?,?))">
    %iv_4 = cute.assume(%9) : (i64) -> !cute.i64<divby 16>
    %stride_5 = cute.make_stride(%7#2, %iv_4) : (i64, !cute.i64<divby 16>) -> !cute.stride<"((?{i64},1),(?{i64 div=16},128))">
    %lay_6 = cute.make_layout(%shape_3, %stride_5) : !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
    %view_7 = cute.make_view(%iter_1, %lay_6) : !memref_gmem_f32_
    %iter_8 = cute.get_iter(%arg2) : !memref_gmem_f32_1
    %lay_9 = cute.get_layout(%arg2) : !memref_gmem_f32_1
    %11:3 = cute.get_scalars(%lay_9) <{only_dynamic}> : !cute.layout<"(?,?):(?{i64},1)">
    %12 = arith.ceildivsi %11#0, %c16_i32 : i32
    %13 = arith.muli %11#2, %c16_i64 : i64
    %14 = arith.ceildivsi %11#1, %c128_i32 : i32
    %shape_10 = cute.make_shape(%12, %14) : (i32, i32) -> !cute.shape<"((16,128),(?,?))">
    %iv_11 = cute.assume(%13) : (i64) -> !cute.i64<divby 16>
    %stride_12 = cute.make_stride(%11#2, %iv_11) : (i64, !cute.i64<divby 16>) -> !cute.stride<"((?{i64},1),(?{i64 div=16},128))">
    %lay_13 = cute.make_layout(%shape_10, %stride_12) : !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
    %view_14 = cute.make_view(%iter_8, %lay_13) : !memref_gmem_f32_
    %15 = cute.get_shape(%lay_9) : (!cute.layout<"(?,?):(?{i64},1)">) -> !cute.shape<"(?,?)">
    %e0, %e1 = cute.get_leaves(%15) : !cute.shape<"(?,?)">
    %itup = cute.to_int_tuple(%e0) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %16 = cute.get_scalars(%itup) : !cute.int_tuple<"?">
    %itup_15 = cute.to_int_tuple(%e1) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %17 = cute.get_scalars(%itup_15) : !cute.int_tuple<"?">
    %shape_16 = cute.make_shape(%itup, %itup_15) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.shape<"(?,?)">
    %lay_17 = cute.make_layout(%shape_16, %1) : !cute.layout<"(?,?):(1@0,1@1)">
    %18:2 = cute.get_scalars(%lay_17) <{only_dynamic}> : !cute.layout<"(?,?):(1@0,1@1)">
    %19 = arith.ceildivsi %18#0, %c16_i32 : i32
    %20 = arith.ceildivsi %18#1, %c128_i32 : i32
    %shape_18 = cute.make_shape(%19, %20) : (i32, i32) -> !cute.shape<"((16,128),(?,?))">
    %lay_19 = cute.make_layout(%shape_18, %0) : !cute.layout<"((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
    %view_20 = cute.make_view(%2, %lay_19) : !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
    %sz = cute.size(%lay_13) <{mode = [1]}> : (!cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.int_tuple<"?">
    %e0_21 = cute.get_leaves(%sz) : !cute.int_tuple<"?">
    %21 = cute.get_scalars(%e0_21) : !cute.int_tuple<"?">
    %22 = cuda.launch_cfg.create<max_attrs = 2 : i32> (blockDim = (%c128_i32, %c1_i32, %c1_i32), dynamicSmemBytes = %c0_i64, gridDim = (%21, %c1_i32, %c1_i32), stream = %arg3) : i32, i32, i32, i64, i32, i32, i32, !cuda.stream -> !cuda.launch_cfg<max_attrs = 2>
    %23 = cuda.launch_ex @kernels::@kernel_cutlass_elementwise_add_kernel_tensorptrf32gmemo161281i64div16128_tensorptrf32gmemo161281i64div16128_tensorptrf32gmemo161281i64div16128_tensor00o1612810111601281___False_0<%22> (%view, %view_7, %view_14, %view_20, %16, %17) : !cuda.launch_cfg<max_attrs = 2>, (!memref_gmem_f32_, !memref_gmem_f32_, !memref_gmem_f32_, !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">, i32, i32) -> !cuda.result
    %24 = cuda.cast %23 : !cuda.result -> i32
    cuda.return_if_error %24 : i32
    return %c0_i32 : i32
  }
}
