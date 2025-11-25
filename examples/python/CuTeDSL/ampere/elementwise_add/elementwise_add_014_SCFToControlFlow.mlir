!copy_simt = !cute.tiled_copy<!cute_nvgpu.atom.universal_copy<f32>, layout_copy_tv = <"((32,4),(4,4)):((64,4),(16,1))">, tiler_mn = <"[16:1;128:1]">>
!memref_gmem_f32_ = !cute.memref<f32, gmem, "((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
!memref_gmem_f32_1 = !cute.memref<f32, gmem, "(?,?):(?{i64},1)">
!memref_rmem_f32_ = !cute.memref<f32, rmem, align<32>, "((1,(4,4)),1,1):((0,(1,4)),0,0)">
!memref_rmem_i8_ = !cute.memref<i8, rmem, align<32>, "((1,(4,4)),1,1):((0,(1,4)),0,0)">
#loop_unroll = #llvm.loop_unroll<disable = false, full = true>
#loop_annotation = #llvm.loop_annotation<unroll = #loop_unroll>
module attributes {gpu.container_module} {
  gpu.module @kernels {
    func.func public @kernel_cutlass_elementwise_add_kernel_tensorptrf32gmemo161281div16128_tensorptrf32gmemo161281div16128_tensorptrf32gmemo161281div16128_tensor00o1612810111601281___0(%arg0: !memref_gmem_f32_, %arg1: !memref_gmem_f32_, %arg2: !memref_gmem_f32_, %arg3: !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">, %arg4: i32, %arg5: i32) attributes {cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} {
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
      %iter_33 = cute.get_iter(%rmem_32) : !memref_rmem_f32_
      %50 = arith.muli %35, %c4_i32 : i32
      %iv_34 = cute.assume(%50) : (i32) -> !cute.i32<divby 4>
      %iv_35 = cute.assume(%37) : (i32) -> !cute.i32<divby 4>
      %int_tuple_36 = cute.make_int_tuple(%iv_34, %iv_35) : (!cute.i32<divby 4>, !cute.i32<divby 4>) -> !cute.int_tuple<"(?{div=4},?{div=4})">
      %tup_37 = cute.add_offset(%tup, %int_tuple_36) : (!cute.int_tuple<"(?{div=16},?{div=128})">, !cute.int_tuple<"(?{div=4},?{div=4})">) -> !cute.int_tuple<"(?{div=4},?{div=4})">
      %rmem_38 = cute.memref.alloca() : !memref_rmem_i8_
      %coord_39 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %51:2 = cute.get_scalars(%coord_39) : !cute.coord<"(?,?)">
      cf.br ^bb1(%c0_i32 : i32)
    ^bb1(%52: i32):  // 2 preds: ^bb0, ^bb2
      %53 = arith.cmpi slt, %52, %c16_i32 : i32
      cf.cond_br %53, ^bb2, ^bb3
    ^bb2:  // pred: ^bb1
      %coord_40 = cute.make_coord(%52) : (i32) -> !cute.coord<"?">
      %idx_41 = cute.crd2idx(%coord_40, %20) : (!cute.coord<"?">, !cute.layout<"((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">) -> !cute.int_tuple<"(?,?)">
      %tup_42 = cute.add_offset(%tup_37, %idx_41) : (!cute.int_tuple<"(?{div=4},?{div=4})">, !cute.int_tuple<"(?,?)">) -> !cute.int_tuple<"(?,?)">
      %e0, %e1 = cute.get_leaves(%tup_42) : !cute.int_tuple<"(?,?)">
      %coord_43 = cute.make_coord(%e0, %e1) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
      %54:2 = cute.get_scalars(%coord_43) : !cute.coord<"(?,?)">
      %55 = arith.cmpi slt, %54#0, %51#0 : i32
      %56 = arith.cmpi slt, %54#1, %51#1 : i32
      %57 = arith.andi %55, %56 : i1
      %58 = arith.extui %57 : i1 to i8
      cute.memref.store(%rmem_38, %coord_40, %58) : (!memref_rmem_i8_, !cute.coord<"?">, i8) -> ()
      %59 = arith.addi %52, %c1_i32 : i32
      cf.br ^bb1(%59 : i32)
    ^bb3:  // pred: ^bb1
      %iter_44 = cute.get_iter(%rmem_38) : !memref_rmem_i8_
      %append = cute.append_to_rank<2> (%lay_18, %19) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">
      %60 = cute.get_scalars(%append) <{only_dynamic}> : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %stride_45 = cute.make_stride(%60) : (i64) -> !cute.stride<"((0,(1,?{i64})),(0,0))">
      %lay_46 = cute.make_layout(%18, %stride_45) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %append_47 = cute.append_to_rank<2> (%lay_46, %19) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">, !cute.layout<"1:0">
      %61 = cute.get_scalars(%append_47) <{only_dynamic}> : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %stride_48 = cute.make_stride(%61) : (i64) -> !cute.stride<"((0,(1,?{i64})),((0,0)))">
      %lay_49 = cute.make_layout(%17, %stride_48) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
      %62 = cute.get_scalars(%16) : !cute.int_tuple<"1">
      %63 = cute.get_scalars(%lay_49) <{only_dynamic}> : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
      %stride_50 = cute.make_stride(%63) : (i64) -> !cute.stride<"((0,(1,?{i64})))">
      %lay_51 = cute.make_layout(%15, %stride_50) : !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
      %64 = cute.get_scalars(%lay_51) <{only_dynamic}> : !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
      %65 = builtin.unrealized_conversion_cast %iter_44 : !cute.ptr<i8, rmem, align<32>> to !llvm.ptr
      %ptr_52 = cute.add_offset(%iter_44, %16) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
      %66 = builtin.unrealized_conversion_cast %ptr_52 : !cute.ptr<i8, rmem> to !llvm.ptr
      %ptr_53 = cute.add_offset(%iter_44, %13) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem, align<2>>
      %67 = builtin.unrealized_conversion_cast %ptr_53 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
      %ptr_54 = cute.add_offset(%iter_44, %12) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
      %68 = builtin.unrealized_conversion_cast %ptr_54 : !cute.ptr<i8, rmem> to !llvm.ptr
      %ptr_55 = cute.add_offset(%iter_44, %11) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem, align<4>>
      %69 = builtin.unrealized_conversion_cast %ptr_55 : !cute.ptr<i8, rmem, align<4>> to !llvm.ptr
      %ptr_56 = cute.add_offset(%iter_44, %10) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
      %70 = builtin.unrealized_conversion_cast %ptr_56 : !cute.ptr<i8, rmem> to !llvm.ptr
      %ptr_57 = cute.add_offset(%iter_44, %9) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem, align<2>>
      %71 = builtin.unrealized_conversion_cast %ptr_57 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
      %ptr_58 = cute.add_offset(%iter_44, %8) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
      %72 = builtin.unrealized_conversion_cast %ptr_58 : !cute.ptr<i8, rmem> to !llvm.ptr
      %ptr_59 = cute.add_offset(%iter_44, %7) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<i8, rmem, align<8>>
      %73 = builtin.unrealized_conversion_cast %ptr_59 : !cute.ptr<i8, rmem, align<8>> to !llvm.ptr
      %ptr_60 = cute.add_offset(%iter_44, %6) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<i8, rmem>
      %74 = builtin.unrealized_conversion_cast %ptr_60 : !cute.ptr<i8, rmem> to !llvm.ptr
      %ptr_61 = cute.add_offset(%iter_44, %5) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<i8, rmem, align<2>>
      %75 = builtin.unrealized_conversion_cast %ptr_61 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
      %ptr_62 = cute.add_offset(%iter_44, %4) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<i8, rmem>
      %76 = builtin.unrealized_conversion_cast %ptr_62 : !cute.ptr<i8, rmem> to !llvm.ptr
      %ptr_63 = cute.add_offset(%iter_44, %3) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<i8, rmem, align<4>>
      %77 = builtin.unrealized_conversion_cast %ptr_63 : !cute.ptr<i8, rmem, align<4>> to !llvm.ptr
      %ptr_64 = cute.add_offset(%iter_44, %2) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<i8, rmem>
      %78 = builtin.unrealized_conversion_cast %ptr_64 : !cute.ptr<i8, rmem> to !llvm.ptr
      %ptr_65 = cute.add_offset(%iter_44, %1) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<i8, rmem, align<2>>
      %79 = builtin.unrealized_conversion_cast %ptr_65 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
      %ptr_66 = cute.add_offset(%iter_44, %0) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<i8, rmem>
      %80 = builtin.unrealized_conversion_cast %ptr_66 : !cute.ptr<i8, rmem> to !llvm.ptr
      cf.br ^bb4(%c0_i32 : i32)
    ^bb4(%81: i32):  // 2 preds: ^bb3, ^bb37
      %82 = arith.cmpi slt, %81, %62 : i32
      cf.cond_br %82, ^bb5, ^bb38 {llvm.loop_annotation = #loop_annotation}
    ^bb5:  // pred: ^bb4
      %83 = llvm.load %65 : !llvm.ptr -> i8
      %84 = llvm.icmp "ne" %83, %14 : i8
      cf.cond_br %84, ^bb6, ^bb7
    ^bb6:  // pred: ^bb5
      %85 = builtin.unrealized_conversion_cast %ptr_16 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %86 = builtin.unrealized_conversion_cast %iter_29 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
      %87 = llvm.load %85 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %87, %86 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      cf.br ^bb7
    ^bb7:  // 2 preds: ^bb5, ^bb6
      %88 = llvm.load %66 : !llvm.ptr -> i8
      %89 = llvm.icmp "ne" %88, %14 : i8
      cf.cond_br %89, ^bb8, ^bb9
    ^bb8:  // pred: ^bb7
      %ptr_67 = cute.add_offset(%ptr_16, %16) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
      %ptr_68 = cute.add_offset(%iter_29, %16) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
      %90 = builtin.unrealized_conversion_cast %ptr_67 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %91 = builtin.unrealized_conversion_cast %ptr_68 : !cute.ptr<f32, rmem> to !llvm.ptr
      %92 = llvm.load %90 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %92, %91 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      cf.br ^bb9
    ^bb9:  // 2 preds: ^bb7, ^bb8
      %93 = llvm.load %67 : !llvm.ptr -> i8
      %94 = llvm.icmp "ne" %93, %14 : i8
      cf.cond_br %94, ^bb10, ^bb11
    ^bb10:  // pred: ^bb9
      %ptr_69 = cute.add_offset(%ptr_16, %13) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
      %ptr_70 = cute.add_offset(%iter_29, %13) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
      %95 = builtin.unrealized_conversion_cast %ptr_69 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %96 = builtin.unrealized_conversion_cast %ptr_70 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
      %97 = llvm.load %95 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %97, %96 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      cf.br ^bb11
    ^bb11:  // 2 preds: ^bb9, ^bb10
      %98 = llvm.load %68 : !llvm.ptr -> i8
      %99 = llvm.icmp "ne" %98, %14 : i8
      cf.cond_br %99, ^bb12, ^bb13
    ^bb12:  // pred: ^bb11
      %ptr_71 = cute.add_offset(%ptr_16, %12) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
      %ptr_72 = cute.add_offset(%iter_29, %12) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
      %100 = builtin.unrealized_conversion_cast %ptr_71 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %101 = builtin.unrealized_conversion_cast %ptr_72 : !cute.ptr<f32, rmem> to !llvm.ptr
      %102 = llvm.load %100 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %102, %101 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      cf.br ^bb13
    ^bb13:  // 2 preds: ^bb11, ^bb12
      %103 = llvm.load %69 : !llvm.ptr -> i8
      %104 = llvm.icmp "ne" %103, %14 : i8
      cf.cond_br %104, ^bb14, ^bb15
    ^bb14:  // pred: ^bb13
      %int_tuple_73 = cute.make_int_tuple(%64) : (i64) -> !cute.int_tuple<"?{i64}">
      %ptr_74 = cute.add_offset(%ptr_16, %int_tuple_73) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %ptr_75 = cute.add_offset(%iter_29, %11) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
      %105 = builtin.unrealized_conversion_cast %ptr_74 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %106 = builtin.unrealized_conversion_cast %ptr_75 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %107 = llvm.load %105 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %107, %106 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      cf.br ^bb15
    ^bb15:  // 2 preds: ^bb13, ^bb14
      %108 = llvm.load %70 : !llvm.ptr -> i8
      %109 = llvm.icmp "ne" %108, %14 : i8
      cf.cond_br %109, ^bb16, ^bb17
    ^bb16:  // pred: ^bb15
      %110 = arith.addi %64, %c1_i64 : i64
      %int_tuple_76 = cute.make_int_tuple(%110) : (i64) -> !cute.int_tuple<"?{i64}">
      %ptr_77 = cute.add_offset(%ptr_16, %int_tuple_76) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %ptr_78 = cute.add_offset(%iter_29, %10) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<f32, rmem>
      %111 = builtin.unrealized_conversion_cast %ptr_77 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %112 = builtin.unrealized_conversion_cast %ptr_78 : !cute.ptr<f32, rmem> to !llvm.ptr
      %113 = llvm.load %111 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %113, %112 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      cf.br ^bb17
    ^bb17:  // 2 preds: ^bb15, ^bb16
      %114 = llvm.load %71 : !llvm.ptr -> i8
      %115 = llvm.icmp "ne" %114, %14 : i8
      cf.cond_br %115, ^bb18, ^bb19
    ^bb18:  // pred: ^bb17
      %116 = arith.addi %64, %c2_i64 : i64
      %int_tuple_79 = cute.make_int_tuple(%116) : (i64) -> !cute.int_tuple<"?{i64}">
      %ptr_80 = cute.add_offset(%ptr_16, %int_tuple_79) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %ptr_81 = cute.add_offset(%iter_29, %9) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
      %117 = builtin.unrealized_conversion_cast %ptr_80 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %118 = builtin.unrealized_conversion_cast %ptr_81 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
      %119 = llvm.load %117 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %119, %118 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      cf.br ^bb19
    ^bb19:  // 2 preds: ^bb17, ^bb18
      %120 = llvm.load %72 : !llvm.ptr -> i8
      %121 = llvm.icmp "ne" %120, %14 : i8
      cf.cond_br %121, ^bb20, ^bb21
    ^bb20:  // pred: ^bb19
      %122 = arith.addi %64, %c3_i64 : i64
      %int_tuple_82 = cute.make_int_tuple(%122) : (i64) -> !cute.int_tuple<"?{i64}">
      %ptr_83 = cute.add_offset(%ptr_16, %int_tuple_82) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %ptr_84 = cute.add_offset(%iter_29, %8) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<f32, rmem>
      %123 = builtin.unrealized_conversion_cast %ptr_83 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %124 = builtin.unrealized_conversion_cast %ptr_84 : !cute.ptr<f32, rmem> to !llvm.ptr
      %125 = llvm.load %123 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %125, %124 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      cf.br ^bb21
    ^bb21:  // 2 preds: ^bb19, ^bb20
      %126 = llvm.load %73 : !llvm.ptr -> i8
      %127 = llvm.icmp "ne" %126, %14 : i8
      cf.cond_br %127, ^bb22, ^bb23
    ^bb22:  // pred: ^bb21
      %128 = arith.muli %64, %c2_i64 : i64
      %iv_85 = cute.assume(%128) : (i64) -> !cute.i64<divby 2>
      %int_tuple_86 = cute.make_int_tuple(%iv_85) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
      %ptr_87 = cute.add_offset(%ptr_16, %int_tuple_86) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
      %ptr_88 = cute.add_offset(%iter_29, %7) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<f32, rmem, align<32>>
      %129 = builtin.unrealized_conversion_cast %ptr_87 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %130 = builtin.unrealized_conversion_cast %ptr_88 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
      %131 = llvm.load %129 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %131, %130 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      cf.br ^bb23
    ^bb23:  // 2 preds: ^bb21, ^bb22
      %132 = llvm.load %74 : !llvm.ptr -> i8
      %133 = llvm.icmp "ne" %132, %14 : i8
      cf.cond_br %133, ^bb24, ^bb25
    ^bb24:  // pred: ^bb23
      %134 = arith.muli %64, %c2_i64 : i64
      %135 = arith.addi %134, %c1_i64 : i64
      %int_tuple_89 = cute.make_int_tuple(%135) : (i64) -> !cute.int_tuple<"?{i64}">
      %ptr_90 = cute.add_offset(%ptr_16, %int_tuple_89) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %ptr_91 = cute.add_offset(%iter_29, %6) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<f32, rmem>
      %136 = builtin.unrealized_conversion_cast %ptr_90 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %137 = builtin.unrealized_conversion_cast %ptr_91 : !cute.ptr<f32, rmem> to !llvm.ptr
      %138 = llvm.load %136 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %138, %137 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      cf.br ^bb25
    ^bb25:  // 2 preds: ^bb23, ^bb24
      %139 = llvm.load %75 : !llvm.ptr -> i8
      %140 = llvm.icmp "ne" %139, %14 : i8
      cf.cond_br %140, ^bb26, ^bb27
    ^bb26:  // pred: ^bb25
      %141 = arith.muli %64, %c2_i64 : i64
      %142 = arith.addi %141, %c2_i64 : i64
      %iv_92 = cute.assume(%142) : (i64) -> !cute.i64<divby 2>
      %int_tuple_93 = cute.make_int_tuple(%iv_92) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
      %ptr_94 = cute.add_offset(%ptr_16, %int_tuple_93) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
      %ptr_95 = cute.add_offset(%iter_29, %5) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<f32, rmem, align<8>>
      %143 = builtin.unrealized_conversion_cast %ptr_94 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %144 = builtin.unrealized_conversion_cast %ptr_95 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
      %145 = llvm.load %143 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %145, %144 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      cf.br ^bb27
    ^bb27:  // 2 preds: ^bb25, ^bb26
      %146 = llvm.load %76 : !llvm.ptr -> i8
      %147 = llvm.icmp "ne" %146, %14 : i8
      cf.cond_br %147, ^bb28, ^bb29
    ^bb28:  // pred: ^bb27
      %148 = arith.muli %64, %c2_i64 : i64
      %149 = arith.addi %148, %c3_i64 : i64
      %int_tuple_96 = cute.make_int_tuple(%149) : (i64) -> !cute.int_tuple<"?{i64}">
      %ptr_97 = cute.add_offset(%ptr_16, %int_tuple_96) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %ptr_98 = cute.add_offset(%iter_29, %4) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<f32, rmem>
      %150 = builtin.unrealized_conversion_cast %ptr_97 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %151 = builtin.unrealized_conversion_cast %ptr_98 : !cute.ptr<f32, rmem> to !llvm.ptr
      %152 = llvm.load %150 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %152, %151 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      cf.br ^bb29
    ^bb29:  // 2 preds: ^bb27, ^bb28
      %153 = llvm.load %77 : !llvm.ptr -> i8
      %154 = llvm.icmp "ne" %153, %14 : i8
      cf.cond_br %154, ^bb30, ^bb31
    ^bb30:  // pred: ^bb29
      %155 = arith.muli %64, %c3_i64 : i64
      %iv_99 = cute.assume(%155) : (i64) -> !cute.i64<divby 3>
      %int_tuple_100 = cute.make_int_tuple(%iv_99) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
      %ptr_101 = cute.add_offset(%ptr_16, %int_tuple_100) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
      %ptr_102 = cute.add_offset(%iter_29, %3) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<f32, rmem, align<16>>
      %156 = builtin.unrealized_conversion_cast %ptr_101 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %157 = builtin.unrealized_conversion_cast %ptr_102 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %158 = llvm.load %156 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %158, %157 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      cf.br ^bb31
    ^bb31:  // 2 preds: ^bb29, ^bb30
      %159 = llvm.load %78 : !llvm.ptr -> i8
      %160 = llvm.icmp "ne" %159, %14 : i8
      cf.cond_br %160, ^bb32, ^bb33
    ^bb32:  // pred: ^bb31
      %161 = arith.muli %64, %c3_i64 : i64
      %162 = arith.addi %161, %c1_i64 : i64
      %int_tuple_103 = cute.make_int_tuple(%162) : (i64) -> !cute.int_tuple<"?{i64}">
      %ptr_104 = cute.add_offset(%ptr_16, %int_tuple_103) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %ptr_105 = cute.add_offset(%iter_29, %2) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<f32, rmem>
      %163 = builtin.unrealized_conversion_cast %ptr_104 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %164 = builtin.unrealized_conversion_cast %ptr_105 : !cute.ptr<f32, rmem> to !llvm.ptr
      %165 = llvm.load %163 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %165, %164 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      cf.br ^bb33
    ^bb33:  // 2 preds: ^bb31, ^bb32
      %166 = llvm.load %79 : !llvm.ptr -> i8
      %167 = llvm.icmp "ne" %166, %14 : i8
      cf.cond_br %167, ^bb34, ^bb35
    ^bb34:  // pred: ^bb33
      %168 = arith.muli %64, %c3_i64 : i64
      %169 = arith.addi %168, %c2_i64 : i64
      %int_tuple_106 = cute.make_int_tuple(%169) : (i64) -> !cute.int_tuple<"?{i64}">
      %ptr_107 = cute.add_offset(%ptr_16, %int_tuple_106) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %ptr_108 = cute.add_offset(%iter_29, %1) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<f32, rmem, align<8>>
      %170 = builtin.unrealized_conversion_cast %ptr_107 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %171 = builtin.unrealized_conversion_cast %ptr_108 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
      %172 = llvm.load %170 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %172, %171 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      cf.br ^bb35
    ^bb35:  // 2 preds: ^bb33, ^bb34
      %173 = llvm.load %80 : !llvm.ptr -> i8
      %174 = llvm.icmp "ne" %173, %14 : i8
      cf.cond_br %174, ^bb36, ^bb37
    ^bb36:  // pred: ^bb35
      %175 = arith.muli %64, %c3_i64 : i64
      %176 = arith.addi %175, %c3_i64 : i64
      %iv_109 = cute.assume(%176) : (i64) -> !cute.i64<divby 3>
      %int_tuple_110 = cute.make_int_tuple(%iv_109) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
      %ptr_111 = cute.add_offset(%ptr_16, %int_tuple_110) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
      %ptr_112 = cute.add_offset(%iter_29, %0) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<f32, rmem>
      %177 = builtin.unrealized_conversion_cast %ptr_111 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %178 = builtin.unrealized_conversion_cast %ptr_112 : !cute.ptr<f32, rmem> to !llvm.ptr
      %179 = llvm.load %177 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %179, %178 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      cf.br ^bb37
    ^bb37:  // 2 preds: ^bb35, ^bb36
      %180 = arith.addi %81, %c1_i32 : i32
      cf.br ^bb4(%180 : i32)
    ^bb38:  // pred: ^bb4
      %append_113 = cute.append_to_rank<2> (%lay_23, %19) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">
      %181 = cute.get_scalars(%append_113) <{only_dynamic}> : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %stride_114 = cute.make_stride(%181) : (i64) -> !cute.stride<"((0,(1,?{i64})),(0,0))">
      %lay_115 = cute.make_layout(%18, %stride_114) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %append_116 = cute.append_to_rank<2> (%lay_115, %19) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">, !cute.layout<"1:0">
      %182 = cute.get_scalars(%append_116) <{only_dynamic}> : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %stride_117 = cute.make_stride(%182) : (i64) -> !cute.stride<"((0,(1,?{i64})),((0,0)))">
      %lay_118 = cute.make_layout(%17, %stride_117) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
      %183 = cute.get_scalars(%lay_118) <{only_dynamic}> : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
      %stride_119 = cute.make_stride(%183) : (i64) -> !cute.stride<"((0,(1,?{i64})))">
      %lay_120 = cute.make_layout(%15, %stride_119) : !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
      %184 = cute.get_scalars(%lay_120) <{only_dynamic}> : !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
      %185 = builtin.unrealized_conversion_cast %iter_44 : !cute.ptr<i8, rmem, align<32>> to !llvm.ptr
      %ptr_121 = cute.add_offset(%iter_44, %16) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
      %186 = builtin.unrealized_conversion_cast %ptr_121 : !cute.ptr<i8, rmem> to !llvm.ptr
      %ptr_122 = cute.add_offset(%iter_44, %13) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem, align<2>>
      %187 = builtin.unrealized_conversion_cast %ptr_122 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
      %ptr_123 = cute.add_offset(%iter_44, %12) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
      %188 = builtin.unrealized_conversion_cast %ptr_123 : !cute.ptr<i8, rmem> to !llvm.ptr
      %ptr_124 = cute.add_offset(%iter_44, %11) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem, align<4>>
      %189 = builtin.unrealized_conversion_cast %ptr_124 : !cute.ptr<i8, rmem, align<4>> to !llvm.ptr
      %ptr_125 = cute.add_offset(%iter_44, %10) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
      %190 = builtin.unrealized_conversion_cast %ptr_125 : !cute.ptr<i8, rmem> to !llvm.ptr
      %ptr_126 = cute.add_offset(%iter_44, %9) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem, align<2>>
      %191 = builtin.unrealized_conversion_cast %ptr_126 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
      %ptr_127 = cute.add_offset(%iter_44, %8) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
      %192 = builtin.unrealized_conversion_cast %ptr_127 : !cute.ptr<i8, rmem> to !llvm.ptr
      %ptr_128 = cute.add_offset(%iter_44, %7) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<i8, rmem, align<8>>
      %193 = builtin.unrealized_conversion_cast %ptr_128 : !cute.ptr<i8, rmem, align<8>> to !llvm.ptr
      %ptr_129 = cute.add_offset(%iter_44, %6) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<i8, rmem>
      %194 = builtin.unrealized_conversion_cast %ptr_129 : !cute.ptr<i8, rmem> to !llvm.ptr
      %ptr_130 = cute.add_offset(%iter_44, %5) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<i8, rmem, align<2>>
      %195 = builtin.unrealized_conversion_cast %ptr_130 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
      %ptr_131 = cute.add_offset(%iter_44, %4) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<i8, rmem>
      %196 = builtin.unrealized_conversion_cast %ptr_131 : !cute.ptr<i8, rmem> to !llvm.ptr
      %ptr_132 = cute.add_offset(%iter_44, %3) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<i8, rmem, align<4>>
      %197 = builtin.unrealized_conversion_cast %ptr_132 : !cute.ptr<i8, rmem, align<4>> to !llvm.ptr
      %ptr_133 = cute.add_offset(%iter_44, %2) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<i8, rmem>
      %198 = builtin.unrealized_conversion_cast %ptr_133 : !cute.ptr<i8, rmem> to !llvm.ptr
      %ptr_134 = cute.add_offset(%iter_44, %1) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<i8, rmem, align<2>>
      %199 = builtin.unrealized_conversion_cast %ptr_134 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
      %ptr_135 = cute.add_offset(%iter_44, %0) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<i8, rmem>
      %200 = builtin.unrealized_conversion_cast %ptr_135 : !cute.ptr<i8, rmem> to !llvm.ptr
      cf.br ^bb39(%c0_i32 : i32)
    ^bb39(%201: i32):  // 2 preds: ^bb38, ^bb72
      %202 = arith.cmpi slt, %201, %62 : i32
      cf.cond_br %202, ^bb40, ^bb73 {llvm.loop_annotation = #loop_annotation}
    ^bb40:  // pred: ^bb39
      %203 = llvm.load %185 : !llvm.ptr -> i8
      %204 = llvm.icmp "ne" %203, %14 : i8
      cf.cond_br %204, ^bb41, ^bb42
    ^bb41:  // pred: ^bb40
      %205 = builtin.unrealized_conversion_cast %ptr_21 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %206 = builtin.unrealized_conversion_cast %iter_31 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
      %207 = llvm.load %205 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %207, %206 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      cf.br ^bb42
    ^bb42:  // 2 preds: ^bb40, ^bb41
      %208 = llvm.load %186 : !llvm.ptr -> i8
      %209 = llvm.icmp "ne" %208, %14 : i8
      cf.cond_br %209, ^bb43, ^bb44
    ^bb43:  // pred: ^bb42
      %ptr_136 = cute.add_offset(%ptr_21, %16) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
      %ptr_137 = cute.add_offset(%iter_31, %16) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
      %210 = builtin.unrealized_conversion_cast %ptr_136 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %211 = builtin.unrealized_conversion_cast %ptr_137 : !cute.ptr<f32, rmem> to !llvm.ptr
      %212 = llvm.load %210 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %212, %211 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      cf.br ^bb44
    ^bb44:  // 2 preds: ^bb42, ^bb43
      %213 = llvm.load %187 : !llvm.ptr -> i8
      %214 = llvm.icmp "ne" %213, %14 : i8
      cf.cond_br %214, ^bb45, ^bb46
    ^bb45:  // pred: ^bb44
      %ptr_138 = cute.add_offset(%ptr_21, %13) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
      %ptr_139 = cute.add_offset(%iter_31, %13) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
      %215 = builtin.unrealized_conversion_cast %ptr_138 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %216 = builtin.unrealized_conversion_cast %ptr_139 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
      %217 = llvm.load %215 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %217, %216 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      cf.br ^bb46
    ^bb46:  // 2 preds: ^bb44, ^bb45
      %218 = llvm.load %188 : !llvm.ptr -> i8
      %219 = llvm.icmp "ne" %218, %14 : i8
      cf.cond_br %219, ^bb47, ^bb48
    ^bb47:  // pred: ^bb46
      %ptr_140 = cute.add_offset(%ptr_21, %12) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
      %ptr_141 = cute.add_offset(%iter_31, %12) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
      %220 = builtin.unrealized_conversion_cast %ptr_140 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %221 = builtin.unrealized_conversion_cast %ptr_141 : !cute.ptr<f32, rmem> to !llvm.ptr
      %222 = llvm.load %220 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %222, %221 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      cf.br ^bb48
    ^bb48:  // 2 preds: ^bb46, ^bb47
      %223 = llvm.load %189 : !llvm.ptr -> i8
      %224 = llvm.icmp "ne" %223, %14 : i8
      cf.cond_br %224, ^bb49, ^bb50
    ^bb49:  // pred: ^bb48
      %int_tuple_142 = cute.make_int_tuple(%184) : (i64) -> !cute.int_tuple<"?{i64}">
      %ptr_143 = cute.add_offset(%ptr_21, %int_tuple_142) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %ptr_144 = cute.add_offset(%iter_31, %11) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
      %225 = builtin.unrealized_conversion_cast %ptr_143 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %226 = builtin.unrealized_conversion_cast %ptr_144 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %227 = llvm.load %225 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %227, %226 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      cf.br ^bb50
    ^bb50:  // 2 preds: ^bb48, ^bb49
      %228 = llvm.load %190 : !llvm.ptr -> i8
      %229 = llvm.icmp "ne" %228, %14 : i8
      cf.cond_br %229, ^bb51, ^bb52
    ^bb51:  // pred: ^bb50
      %230 = arith.addi %184, %c1_i64 : i64
      %int_tuple_145 = cute.make_int_tuple(%230) : (i64) -> !cute.int_tuple<"?{i64}">
      %ptr_146 = cute.add_offset(%ptr_21, %int_tuple_145) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %ptr_147 = cute.add_offset(%iter_31, %10) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<f32, rmem>
      %231 = builtin.unrealized_conversion_cast %ptr_146 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %232 = builtin.unrealized_conversion_cast %ptr_147 : !cute.ptr<f32, rmem> to !llvm.ptr
      %233 = llvm.load %231 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %233, %232 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      cf.br ^bb52
    ^bb52:  // 2 preds: ^bb50, ^bb51
      %234 = llvm.load %191 : !llvm.ptr -> i8
      %235 = llvm.icmp "ne" %234, %14 : i8
      cf.cond_br %235, ^bb53, ^bb54
    ^bb53:  // pred: ^bb52
      %236 = arith.addi %184, %c2_i64 : i64
      %int_tuple_148 = cute.make_int_tuple(%236) : (i64) -> !cute.int_tuple<"?{i64}">
      %ptr_149 = cute.add_offset(%ptr_21, %int_tuple_148) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %ptr_150 = cute.add_offset(%iter_31, %9) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
      %237 = builtin.unrealized_conversion_cast %ptr_149 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %238 = builtin.unrealized_conversion_cast %ptr_150 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
      %239 = llvm.load %237 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %239, %238 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      cf.br ^bb54
    ^bb54:  // 2 preds: ^bb52, ^bb53
      %240 = llvm.load %192 : !llvm.ptr -> i8
      %241 = llvm.icmp "ne" %240, %14 : i8
      cf.cond_br %241, ^bb55, ^bb56
    ^bb55:  // pred: ^bb54
      %242 = arith.addi %184, %c3_i64 : i64
      %int_tuple_151 = cute.make_int_tuple(%242) : (i64) -> !cute.int_tuple<"?{i64}">
      %ptr_152 = cute.add_offset(%ptr_21, %int_tuple_151) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %ptr_153 = cute.add_offset(%iter_31, %8) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<f32, rmem>
      %243 = builtin.unrealized_conversion_cast %ptr_152 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %244 = builtin.unrealized_conversion_cast %ptr_153 : !cute.ptr<f32, rmem> to !llvm.ptr
      %245 = llvm.load %243 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %245, %244 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      cf.br ^bb56
    ^bb56:  // 2 preds: ^bb54, ^bb55
      %246 = llvm.load %193 : !llvm.ptr -> i8
      %247 = llvm.icmp "ne" %246, %14 : i8
      cf.cond_br %247, ^bb57, ^bb58
    ^bb57:  // pred: ^bb56
      %248 = arith.muli %184, %c2_i64 : i64
      %iv_154 = cute.assume(%248) : (i64) -> !cute.i64<divby 2>
      %int_tuple_155 = cute.make_int_tuple(%iv_154) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
      %ptr_156 = cute.add_offset(%ptr_21, %int_tuple_155) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
      %ptr_157 = cute.add_offset(%iter_31, %7) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<f32, rmem, align<32>>
      %249 = builtin.unrealized_conversion_cast %ptr_156 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %250 = builtin.unrealized_conversion_cast %ptr_157 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
      %251 = llvm.load %249 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %251, %250 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      cf.br ^bb58
    ^bb58:  // 2 preds: ^bb56, ^bb57
      %252 = llvm.load %194 : !llvm.ptr -> i8
      %253 = llvm.icmp "ne" %252, %14 : i8
      cf.cond_br %253, ^bb59, ^bb60
    ^bb59:  // pred: ^bb58
      %254 = arith.muli %184, %c2_i64 : i64
      %255 = arith.addi %254, %c1_i64 : i64
      %int_tuple_158 = cute.make_int_tuple(%255) : (i64) -> !cute.int_tuple<"?{i64}">
      %ptr_159 = cute.add_offset(%ptr_21, %int_tuple_158) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %ptr_160 = cute.add_offset(%iter_31, %6) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<f32, rmem>
      %256 = builtin.unrealized_conversion_cast %ptr_159 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %257 = builtin.unrealized_conversion_cast %ptr_160 : !cute.ptr<f32, rmem> to !llvm.ptr
      %258 = llvm.load %256 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %258, %257 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      cf.br ^bb60
    ^bb60:  // 2 preds: ^bb58, ^bb59
      %259 = llvm.load %195 : !llvm.ptr -> i8
      %260 = llvm.icmp "ne" %259, %14 : i8
      cf.cond_br %260, ^bb61, ^bb62
    ^bb61:  // pred: ^bb60
      %261 = arith.muli %184, %c2_i64 : i64
      %262 = arith.addi %261, %c2_i64 : i64
      %iv_161 = cute.assume(%262) : (i64) -> !cute.i64<divby 2>
      %int_tuple_162 = cute.make_int_tuple(%iv_161) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
      %ptr_163 = cute.add_offset(%ptr_21, %int_tuple_162) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
      %ptr_164 = cute.add_offset(%iter_31, %5) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<f32, rmem, align<8>>
      %263 = builtin.unrealized_conversion_cast %ptr_163 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %264 = builtin.unrealized_conversion_cast %ptr_164 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
      %265 = llvm.load %263 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %265, %264 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      cf.br ^bb62
    ^bb62:  // 2 preds: ^bb60, ^bb61
      %266 = llvm.load %196 : !llvm.ptr -> i8
      %267 = llvm.icmp "ne" %266, %14 : i8
      cf.cond_br %267, ^bb63, ^bb64
    ^bb63:  // pred: ^bb62
      %268 = arith.muli %184, %c2_i64 : i64
      %269 = arith.addi %268, %c3_i64 : i64
      %int_tuple_165 = cute.make_int_tuple(%269) : (i64) -> !cute.int_tuple<"?{i64}">
      %ptr_166 = cute.add_offset(%ptr_21, %int_tuple_165) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %ptr_167 = cute.add_offset(%iter_31, %4) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<f32, rmem>
      %270 = builtin.unrealized_conversion_cast %ptr_166 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %271 = builtin.unrealized_conversion_cast %ptr_167 : !cute.ptr<f32, rmem> to !llvm.ptr
      %272 = llvm.load %270 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %272, %271 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      cf.br ^bb64
    ^bb64:  // 2 preds: ^bb62, ^bb63
      %273 = llvm.load %197 : !llvm.ptr -> i8
      %274 = llvm.icmp "ne" %273, %14 : i8
      cf.cond_br %274, ^bb65, ^bb66
    ^bb65:  // pred: ^bb64
      %275 = arith.muli %184, %c3_i64 : i64
      %iv_168 = cute.assume(%275) : (i64) -> !cute.i64<divby 3>
      %int_tuple_169 = cute.make_int_tuple(%iv_168) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
      %ptr_170 = cute.add_offset(%ptr_21, %int_tuple_169) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
      %ptr_171 = cute.add_offset(%iter_31, %3) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<f32, rmem, align<16>>
      %276 = builtin.unrealized_conversion_cast %ptr_170 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %277 = builtin.unrealized_conversion_cast %ptr_171 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %278 = llvm.load %276 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %278, %277 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      cf.br ^bb66
    ^bb66:  // 2 preds: ^bb64, ^bb65
      %279 = llvm.load %198 : !llvm.ptr -> i8
      %280 = llvm.icmp "ne" %279, %14 : i8
      cf.cond_br %280, ^bb67, ^bb68
    ^bb67:  // pred: ^bb66
      %281 = arith.muli %184, %c3_i64 : i64
      %282 = arith.addi %281, %c1_i64 : i64
      %int_tuple_172 = cute.make_int_tuple(%282) : (i64) -> !cute.int_tuple<"?{i64}">
      %ptr_173 = cute.add_offset(%ptr_21, %int_tuple_172) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %ptr_174 = cute.add_offset(%iter_31, %2) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<f32, rmem>
      %283 = builtin.unrealized_conversion_cast %ptr_173 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %284 = builtin.unrealized_conversion_cast %ptr_174 : !cute.ptr<f32, rmem> to !llvm.ptr
      %285 = llvm.load %283 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %285, %284 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      cf.br ^bb68
    ^bb68:  // 2 preds: ^bb66, ^bb67
      %286 = llvm.load %199 : !llvm.ptr -> i8
      %287 = llvm.icmp "ne" %286, %14 : i8
      cf.cond_br %287, ^bb69, ^bb70
    ^bb69:  // pred: ^bb68
      %288 = arith.muli %184, %c3_i64 : i64
      %289 = arith.addi %288, %c2_i64 : i64
      %int_tuple_175 = cute.make_int_tuple(%289) : (i64) -> !cute.int_tuple<"?{i64}">
      %ptr_176 = cute.add_offset(%ptr_21, %int_tuple_175) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %ptr_177 = cute.add_offset(%iter_31, %1) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<f32, rmem, align<8>>
      %290 = builtin.unrealized_conversion_cast %ptr_176 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %291 = builtin.unrealized_conversion_cast %ptr_177 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
      %292 = llvm.load %290 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %292, %291 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      cf.br ^bb70
    ^bb70:  // 2 preds: ^bb68, ^bb69
      %293 = llvm.load %200 : !llvm.ptr -> i8
      %294 = llvm.icmp "ne" %293, %14 : i8
      cf.cond_br %294, ^bb71, ^bb72
    ^bb71:  // pred: ^bb70
      %295 = arith.muli %184, %c3_i64 : i64
      %296 = arith.addi %295, %c3_i64 : i64
      %iv_178 = cute.assume(%296) : (i64) -> !cute.i64<divby 3>
      %int_tuple_179 = cute.make_int_tuple(%iv_178) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
      %ptr_180 = cute.add_offset(%ptr_21, %int_tuple_179) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
      %ptr_181 = cute.add_offset(%iter_31, %0) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<f32, rmem>
      %297 = builtin.unrealized_conversion_cast %ptr_180 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %298 = builtin.unrealized_conversion_cast %ptr_181 : !cute.ptr<f32, rmem> to !llvm.ptr
      %299 = llvm.load %297 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %299, %298 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      cf.br ^bb72
    ^bb72:  // 2 preds: ^bb70, ^bb71
      %300 = arith.addi %201, %c1_i32 : i32
      cf.br ^bb39(%300 : i32)
    ^bb73:  // pred: ^bb39
      %301 = cute.memref.load_vec %rmem, row_major : !memref_rmem_f32_
      %302 = cute.memref.load_vec %rmem_30, row_major : !memref_rmem_f32_
      %303 = arith.addf %301, %302 : vector<16xf32>
      cute.memref.store_vec %303, %rmem_32, row_major : !memref_rmem_f32_
      %append_182 = cute.append_to_rank<2> (%lay_28, %19) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">
      %304 = cute.get_scalars(%append_182) <{only_dynamic}> : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %stride_183 = cute.make_stride(%304) : (i64) -> !cute.stride<"((0,(1,?{i64})),(0,0))">
      %lay_184 = cute.make_layout(%18, %stride_183) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %append_185 = cute.append_to_rank<2> (%lay_184, %19) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">, !cute.layout<"1:0">
      %305 = cute.get_scalars(%append_185) <{only_dynamic}> : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %stride_186 = cute.make_stride(%305) : (i64) -> !cute.stride<"((0,(1,?{i64})),((0,0)))">
      %lay_187 = cute.make_layout(%17, %stride_186) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
      %306 = cute.get_scalars(%lay_187) <{only_dynamic}> : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
      %stride_188 = cute.make_stride(%306) : (i64) -> !cute.stride<"((0,(1,?{i64})))">
      %lay_189 = cute.make_layout(%15, %stride_188) : !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
      %307 = cute.get_scalars(%lay_189) <{only_dynamic}> : !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
      %308 = builtin.unrealized_conversion_cast %iter_44 : !cute.ptr<i8, rmem, align<32>> to !llvm.ptr
      %ptr_190 = cute.add_offset(%iter_44, %16) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
      %309 = builtin.unrealized_conversion_cast %ptr_190 : !cute.ptr<i8, rmem> to !llvm.ptr
      %ptr_191 = cute.add_offset(%iter_44, %13) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem, align<2>>
      %310 = builtin.unrealized_conversion_cast %ptr_191 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
      %ptr_192 = cute.add_offset(%iter_44, %12) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
      %311 = builtin.unrealized_conversion_cast %ptr_192 : !cute.ptr<i8, rmem> to !llvm.ptr
      %ptr_193 = cute.add_offset(%iter_44, %11) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem, align<4>>
      %312 = builtin.unrealized_conversion_cast %ptr_193 : !cute.ptr<i8, rmem, align<4>> to !llvm.ptr
      %ptr_194 = cute.add_offset(%iter_44, %10) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
      %313 = builtin.unrealized_conversion_cast %ptr_194 : !cute.ptr<i8, rmem> to !llvm.ptr
      %ptr_195 = cute.add_offset(%iter_44, %9) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem, align<2>>
      %314 = builtin.unrealized_conversion_cast %ptr_195 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
      %ptr_196 = cute.add_offset(%iter_44, %8) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
      %315 = builtin.unrealized_conversion_cast %ptr_196 : !cute.ptr<i8, rmem> to !llvm.ptr
      %ptr_197 = cute.add_offset(%iter_44, %7) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<i8, rmem, align<8>>
      %316 = builtin.unrealized_conversion_cast %ptr_197 : !cute.ptr<i8, rmem, align<8>> to !llvm.ptr
      %ptr_198 = cute.add_offset(%iter_44, %6) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<i8, rmem>
      %317 = builtin.unrealized_conversion_cast %ptr_198 : !cute.ptr<i8, rmem> to !llvm.ptr
      %ptr_199 = cute.add_offset(%iter_44, %5) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<i8, rmem, align<2>>
      %318 = builtin.unrealized_conversion_cast %ptr_199 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
      %ptr_200 = cute.add_offset(%iter_44, %4) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<i8, rmem>
      %319 = builtin.unrealized_conversion_cast %ptr_200 : !cute.ptr<i8, rmem> to !llvm.ptr
      %ptr_201 = cute.add_offset(%iter_44, %3) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<i8, rmem, align<4>>
      %320 = builtin.unrealized_conversion_cast %ptr_201 : !cute.ptr<i8, rmem, align<4>> to !llvm.ptr
      %ptr_202 = cute.add_offset(%iter_44, %2) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<i8, rmem>
      %321 = builtin.unrealized_conversion_cast %ptr_202 : !cute.ptr<i8, rmem> to !llvm.ptr
      %ptr_203 = cute.add_offset(%iter_44, %1) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<i8, rmem, align<2>>
      %322 = builtin.unrealized_conversion_cast %ptr_203 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
      %ptr_204 = cute.add_offset(%iter_44, %0) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<i8, rmem>
      %323 = builtin.unrealized_conversion_cast %ptr_204 : !cute.ptr<i8, rmem> to !llvm.ptr
      cf.br ^bb74(%c0_i32 : i32)
    ^bb74(%324: i32):  // 2 preds: ^bb73, ^bb107
      %325 = arith.cmpi slt, %324, %62 : i32
      cf.cond_br %325, ^bb75, ^bb108 {llvm.loop_annotation = #loop_annotation}
    ^bb75:  // pred: ^bb74
      %326 = llvm.load %308 : !llvm.ptr -> i8
      %327 = llvm.icmp "ne" %326, %14 : i8
      cf.cond_br %327, ^bb76, ^bb77
    ^bb76:  // pred: ^bb75
      %328 = builtin.unrealized_conversion_cast %iter_33 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
      %329 = builtin.unrealized_conversion_cast %ptr_26 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %330 = llvm.load %328 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
      llvm.store %330, %329 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
      cf.br ^bb77
    ^bb77:  // 2 preds: ^bb75, ^bb76
      %331 = llvm.load %309 : !llvm.ptr -> i8
      %332 = llvm.icmp "ne" %331, %14 : i8
      cf.cond_br %332, ^bb78, ^bb79
    ^bb78:  // pred: ^bb77
      %ptr_205 = cute.add_offset(%iter_33, %16) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
      %ptr_206 = cute.add_offset(%ptr_26, %16) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
      %333 = builtin.unrealized_conversion_cast %ptr_205 : !cute.ptr<f32, rmem> to !llvm.ptr
      %334 = builtin.unrealized_conversion_cast %ptr_206 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %335 = llvm.load %333 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
      llvm.store %335, %334 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
      cf.br ^bb79
    ^bb79:  // 2 preds: ^bb77, ^bb78
      %336 = llvm.load %310 : !llvm.ptr -> i8
      %337 = llvm.icmp "ne" %336, %14 : i8
      cf.cond_br %337, ^bb80, ^bb81
    ^bb80:  // pred: ^bb79
      %ptr_207 = cute.add_offset(%iter_33, %13) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
      %ptr_208 = cute.add_offset(%ptr_26, %13) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
      %338 = builtin.unrealized_conversion_cast %ptr_207 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
      %339 = builtin.unrealized_conversion_cast %ptr_208 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %340 = llvm.load %338 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
      llvm.store %340, %339 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
      cf.br ^bb81
    ^bb81:  // 2 preds: ^bb79, ^bb80
      %341 = llvm.load %311 : !llvm.ptr -> i8
      %342 = llvm.icmp "ne" %341, %14 : i8
      cf.cond_br %342, ^bb82, ^bb83
    ^bb82:  // pred: ^bb81
      %ptr_209 = cute.add_offset(%iter_33, %12) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
      %ptr_210 = cute.add_offset(%ptr_26, %12) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
      %343 = builtin.unrealized_conversion_cast %ptr_209 : !cute.ptr<f32, rmem> to !llvm.ptr
      %344 = builtin.unrealized_conversion_cast %ptr_210 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %345 = llvm.load %343 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
      llvm.store %345, %344 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
      cf.br ^bb83
    ^bb83:  // 2 preds: ^bb81, ^bb82
      %346 = llvm.load %312 : !llvm.ptr -> i8
      %347 = llvm.icmp "ne" %346, %14 : i8
      cf.cond_br %347, ^bb84, ^bb85
    ^bb84:  // pred: ^bb83
      %ptr_211 = cute.add_offset(%iter_33, %11) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
      %int_tuple_212 = cute.make_int_tuple(%307) : (i64) -> !cute.int_tuple<"?{i64}">
      %ptr_213 = cute.add_offset(%ptr_26, %int_tuple_212) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %348 = builtin.unrealized_conversion_cast %ptr_211 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %349 = builtin.unrealized_conversion_cast %ptr_213 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %350 = llvm.load %348 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
      llvm.store %350, %349 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
      cf.br ^bb85
    ^bb85:  // 2 preds: ^bb83, ^bb84
      %351 = llvm.load %313 : !llvm.ptr -> i8
      %352 = llvm.icmp "ne" %351, %14 : i8
      cf.cond_br %352, ^bb86, ^bb87
    ^bb86:  // pred: ^bb85
      %ptr_214 = cute.add_offset(%iter_33, %10) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<f32, rmem>
      %353 = arith.addi %307, %c1_i64 : i64
      %int_tuple_215 = cute.make_int_tuple(%353) : (i64) -> !cute.int_tuple<"?{i64}">
      %ptr_216 = cute.add_offset(%ptr_26, %int_tuple_215) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %354 = builtin.unrealized_conversion_cast %ptr_214 : !cute.ptr<f32, rmem> to !llvm.ptr
      %355 = builtin.unrealized_conversion_cast %ptr_216 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %356 = llvm.load %354 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
      llvm.store %356, %355 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
      cf.br ^bb87
    ^bb87:  // 2 preds: ^bb85, ^bb86
      %357 = llvm.load %314 : !llvm.ptr -> i8
      %358 = llvm.icmp "ne" %357, %14 : i8
      cf.cond_br %358, ^bb88, ^bb89
    ^bb88:  // pred: ^bb87
      %ptr_217 = cute.add_offset(%iter_33, %9) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
      %359 = arith.addi %307, %c2_i64 : i64
      %int_tuple_218 = cute.make_int_tuple(%359) : (i64) -> !cute.int_tuple<"?{i64}">
      %ptr_219 = cute.add_offset(%ptr_26, %int_tuple_218) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %360 = builtin.unrealized_conversion_cast %ptr_217 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
      %361 = builtin.unrealized_conversion_cast %ptr_219 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %362 = llvm.load %360 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
      llvm.store %362, %361 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
      cf.br ^bb89
    ^bb89:  // 2 preds: ^bb87, ^bb88
      %363 = llvm.load %315 : !llvm.ptr -> i8
      %364 = llvm.icmp "ne" %363, %14 : i8
      cf.cond_br %364, ^bb90, ^bb91
    ^bb90:  // pred: ^bb89
      %ptr_220 = cute.add_offset(%iter_33, %8) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<f32, rmem>
      %365 = arith.addi %307, %c3_i64 : i64
      %int_tuple_221 = cute.make_int_tuple(%365) : (i64) -> !cute.int_tuple<"?{i64}">
      %ptr_222 = cute.add_offset(%ptr_26, %int_tuple_221) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %366 = builtin.unrealized_conversion_cast %ptr_220 : !cute.ptr<f32, rmem> to !llvm.ptr
      %367 = builtin.unrealized_conversion_cast %ptr_222 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %368 = llvm.load %366 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
      llvm.store %368, %367 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
      cf.br ^bb91
    ^bb91:  // 2 preds: ^bb89, ^bb90
      %369 = llvm.load %316 : !llvm.ptr -> i8
      %370 = llvm.icmp "ne" %369, %14 : i8
      cf.cond_br %370, ^bb92, ^bb93
    ^bb92:  // pred: ^bb91
      %ptr_223 = cute.add_offset(%iter_33, %7) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<f32, rmem, align<32>>
      %371 = arith.muli %307, %c2_i64 : i64
      %iv_224 = cute.assume(%371) : (i64) -> !cute.i64<divby 2>
      %int_tuple_225 = cute.make_int_tuple(%iv_224) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
      %ptr_226 = cute.add_offset(%ptr_26, %int_tuple_225) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
      %372 = builtin.unrealized_conversion_cast %ptr_223 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
      %373 = builtin.unrealized_conversion_cast %ptr_226 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %374 = llvm.load %372 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
      llvm.store %374, %373 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
      cf.br ^bb93
    ^bb93:  // 2 preds: ^bb91, ^bb92
      %375 = llvm.load %317 : !llvm.ptr -> i8
      %376 = llvm.icmp "ne" %375, %14 : i8
      cf.cond_br %376, ^bb94, ^bb95
    ^bb94:  // pred: ^bb93
      %ptr_227 = cute.add_offset(%iter_33, %6) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<f32, rmem>
      %377 = arith.muli %307, %c2_i64 : i64
      %378 = arith.addi %377, %c1_i64 : i64
      %int_tuple_228 = cute.make_int_tuple(%378) : (i64) -> !cute.int_tuple<"?{i64}">
      %ptr_229 = cute.add_offset(%ptr_26, %int_tuple_228) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %379 = builtin.unrealized_conversion_cast %ptr_227 : !cute.ptr<f32, rmem> to !llvm.ptr
      %380 = builtin.unrealized_conversion_cast %ptr_229 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %381 = llvm.load %379 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
      llvm.store %381, %380 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
      cf.br ^bb95
    ^bb95:  // 2 preds: ^bb93, ^bb94
      %382 = llvm.load %318 : !llvm.ptr -> i8
      %383 = llvm.icmp "ne" %382, %14 : i8
      cf.cond_br %383, ^bb96, ^bb97
    ^bb96:  // pred: ^bb95
      %ptr_230 = cute.add_offset(%iter_33, %5) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<f32, rmem, align<8>>
      %384 = arith.muli %307, %c2_i64 : i64
      %385 = arith.addi %384, %c2_i64 : i64
      %iv_231 = cute.assume(%385) : (i64) -> !cute.i64<divby 2>
      %int_tuple_232 = cute.make_int_tuple(%iv_231) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
      %ptr_233 = cute.add_offset(%ptr_26, %int_tuple_232) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
      %386 = builtin.unrealized_conversion_cast %ptr_230 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
      %387 = builtin.unrealized_conversion_cast %ptr_233 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %388 = llvm.load %386 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
      llvm.store %388, %387 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
      cf.br ^bb97
    ^bb97:  // 2 preds: ^bb95, ^bb96
      %389 = llvm.load %319 : !llvm.ptr -> i8
      %390 = llvm.icmp "ne" %389, %14 : i8
      cf.cond_br %390, ^bb98, ^bb99
    ^bb98:  // pred: ^bb97
      %ptr_234 = cute.add_offset(%iter_33, %4) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<f32, rmem>
      %391 = arith.muli %307, %c2_i64 : i64
      %392 = arith.addi %391, %c3_i64 : i64
      %int_tuple_235 = cute.make_int_tuple(%392) : (i64) -> !cute.int_tuple<"?{i64}">
      %ptr_236 = cute.add_offset(%ptr_26, %int_tuple_235) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %393 = builtin.unrealized_conversion_cast %ptr_234 : !cute.ptr<f32, rmem> to !llvm.ptr
      %394 = builtin.unrealized_conversion_cast %ptr_236 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %395 = llvm.load %393 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
      llvm.store %395, %394 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
      cf.br ^bb99
    ^bb99:  // 2 preds: ^bb97, ^bb98
      %396 = llvm.load %320 : !llvm.ptr -> i8
      %397 = llvm.icmp "ne" %396, %14 : i8
      cf.cond_br %397, ^bb100, ^bb101
    ^bb100:  // pred: ^bb99
      %ptr_237 = cute.add_offset(%iter_33, %3) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<f32, rmem, align<16>>
      %398 = arith.muli %307, %c3_i64 : i64
      %iv_238 = cute.assume(%398) : (i64) -> !cute.i64<divby 3>
      %int_tuple_239 = cute.make_int_tuple(%iv_238) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
      %ptr_240 = cute.add_offset(%ptr_26, %int_tuple_239) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
      %399 = builtin.unrealized_conversion_cast %ptr_237 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %400 = builtin.unrealized_conversion_cast %ptr_240 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %401 = llvm.load %399 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
      llvm.store %401, %400 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
      cf.br ^bb101
    ^bb101:  // 2 preds: ^bb99, ^bb100
      %402 = llvm.load %321 : !llvm.ptr -> i8
      %403 = llvm.icmp "ne" %402, %14 : i8
      cf.cond_br %403, ^bb102, ^bb103
    ^bb102:  // pred: ^bb101
      %ptr_241 = cute.add_offset(%iter_33, %2) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<f32, rmem>
      %404 = arith.muli %307, %c3_i64 : i64
      %405 = arith.addi %404, %c1_i64 : i64
      %int_tuple_242 = cute.make_int_tuple(%405) : (i64) -> !cute.int_tuple<"?{i64}">
      %ptr_243 = cute.add_offset(%ptr_26, %int_tuple_242) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %406 = builtin.unrealized_conversion_cast %ptr_241 : !cute.ptr<f32, rmem> to !llvm.ptr
      %407 = builtin.unrealized_conversion_cast %ptr_243 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %408 = llvm.load %406 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
      llvm.store %408, %407 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
      cf.br ^bb103
    ^bb103:  // 2 preds: ^bb101, ^bb102
      %409 = llvm.load %322 : !llvm.ptr -> i8
      %410 = llvm.icmp "ne" %409, %14 : i8
      cf.cond_br %410, ^bb104, ^bb105
    ^bb104:  // pred: ^bb103
      %ptr_244 = cute.add_offset(%iter_33, %1) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<f32, rmem, align<8>>
      %411 = arith.muli %307, %c3_i64 : i64
      %412 = arith.addi %411, %c2_i64 : i64
      %int_tuple_245 = cute.make_int_tuple(%412) : (i64) -> !cute.int_tuple<"?{i64}">
      %ptr_246 = cute.add_offset(%ptr_26, %int_tuple_245) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %413 = builtin.unrealized_conversion_cast %ptr_244 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
      %414 = builtin.unrealized_conversion_cast %ptr_246 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %415 = llvm.load %413 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
      llvm.store %415, %414 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
      cf.br ^bb105
    ^bb105:  // 2 preds: ^bb103, ^bb104
      %416 = llvm.load %323 : !llvm.ptr -> i8
      %417 = llvm.icmp "ne" %416, %14 : i8
      cf.cond_br %417, ^bb106, ^bb107
    ^bb106:  // pred: ^bb105
      %ptr_247 = cute.add_offset(%iter_33, %0) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<f32, rmem>
      %418 = arith.muli %307, %c3_i64 : i64
      %419 = arith.addi %418, %c3_i64 : i64
      %iv_248 = cute.assume(%419) : (i64) -> !cute.i64<divby 3>
      %int_tuple_249 = cute.make_int_tuple(%iv_248) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
      %ptr_250 = cute.add_offset(%ptr_26, %int_tuple_249) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
      %420 = builtin.unrealized_conversion_cast %ptr_247 : !cute.ptr<f32, rmem> to !llvm.ptr
      %421 = builtin.unrealized_conversion_cast %ptr_250 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %422 = llvm.load %420 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
      llvm.store %422, %421 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
      cf.br ^bb107
    ^bb107:  // 2 preds: ^bb105, ^bb106
      %423 = arith.addi %324, %c1_i32 : i32
      cf.br ^bb74(%423 : i32)
    ^bb108:  // pred: ^bb74
      return
    }
  }
  func.func @cutlass_elementwise_add_tensor_00795_21652_04639_03193_15897_02304_02971_12990_02319_03973_00495_05866_09467_06015_06234_07404_19793_05333_01425_01997_05745_11222_16922_13492_04451(%arg0: !memref_gmem_f32_1, %arg1: !memref_gmem_f32_1, %arg2: !memref_gmem_f32_1) attributes {llvm.emit_c_interface} {
    %c0_i32 = arith.constant 0 : i32
    %c128 = arith.constant 128 : index
    %c1 = arith.constant 1 : index
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
    %22 = arith.index_cast %21 : i32 to index
    gpu.launch_func  @kernels::@kernel_cutlass_elementwise_add_kernel_tensorptrf32gmemo161281div16128_tensorptrf32gmemo161281div16128_tensorptrf32gmemo161281div16128_tensor00o1612810111601281___0 blocks in (%22, %c1, %c1) threads in (%c128, %c1, %c1)  dynamic_shared_memory_size %c0_i32 args(%view : !memref_gmem_f32_, %view_7 : !memref_gmem_f32_, %view_14 : !memref_gmem_f32_, %view_20 : !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">, %16 : i32, %17 : i32) {use_pdl = false}
    return
  }
}
