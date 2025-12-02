!memref_gmem_f32_ = !cute.memref<f32, gmem, align<16>, "((64,256),(16,64)):((4096,1),(256,262144))">
!memref_gmem_f32_1 = !cute.memref<f32, gmem, align<16>, "((64,256),((?,?),(?,?))):((?{i64},1),((?{i64 div=4096},?{div=256}),(?{i64 div=64},?{div=256})))">
!memref_gmem_f32_2 = !cute.memref<f32, gmem, align<16>, "(64,256):(4096,1)">
!memref_gmem_f32_3 = !cute.memref<f32, gmem, align<16>, "(64,256):(?{i64},1)">
!memref_gmem_f32_4 = !cute.memref<f32, gmem, align<16>, "((64,4),(4,16)):((4,65536),(1,4096))">
!memref_gmem_f32_5 = !cute.memref<f32, gmem, align<16>, "((64,4),(4,16)):((4,?{i64 div=16}),(1,?{i64}))">
!memref_gmem_f32_6 = !cute.memref<f32, gmem, align<16>, "((4,16)):((1,4096))">
!memref_gmem_f32_7 = !cute.memref<f32, gmem, align<16>, "((4,16)):((1,?{i64}))">
!memref_gmem_f32_8 = !cute.memref<f32, gmem, align<16>, "(4096,4096):(4096,1)">
!memref_gmem_f32_9 = !cute.memref<f32, gmem, align<16>, "(?,?):(?{i64},1)">
!memref_gmem_f32_10 = !cute.memref<f32, gmem, align<16>, "((64,256),(64,16)):((4096,1),(262144,256))">
!memref_gmem_f32_11 = !cute.memref<f32, gmem, align<16>, "((64,256),(?,?)):((?{i64},1),(?{i64 div=64},256))">
!memref_rmem_i8_ = !cute.memref<i8, rmem, align<32>, "((4,16)):((1,4))">
module attributes {gpu.container_module} {
  gpu.module @kernels {
    func.func public @kernel_cutlass_elementwise_apply_kernel_builtinfunctionadd_tensorptrf32_gmem_align16_o_64256166440961256262144_tensorptrf32_gmem_align16_o_64256166440961256262144_tensorptrf32gmemalign16o_0(%arg0: !memref_gmem_f32_, %arg1: !memref_gmem_f32_, %arg2: !memref_gmem_f32_1, %arg3: !cute.coord_tensor<"(0,0)", "((64,256),(?,?)):((1@0,1@1),(64@0,256@1))">, %arg4: i32, %arg5: i32) attributes {cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 256, 1, 1>} {
      %0 = cute.static : !cute.layout<"((64,4),(4,16)):((256,16),(64,1))">
      %1 = nvvm.read.ptx.sreg.tid.x : i32
      %2 = nvvm.read.ptx.sreg.ctaid.x : i32
      %3 = nvvm.read.ptx.sreg.ctaid.y : i32
      %coord = cute.make_coord(%2, %3) : (i32, i32) -> !cute.coord<"((_,_),(?,?))">
      %4 = cute.static : !cute.layout<"((64,256),(16,64)):((4096,1),(256,262144))">
      %idx = cute.crd2idx(%coord, %4) : (!cute.coord<"((_,_),(?,?))">, !cute.layout<"((64,256),(16,64)):((4096,1),(256,262144))">) -> !cute.int_tuple<"?{div=256}">
      %iter = cute.get_iter(%arg0) : !memref_gmem_f32_
      %ptr = cute.add_offset(%iter, %idx) : (!cute.ptr<f32, gmem, align<16>>, !cute.int_tuple<"?{div=256}">) -> !cute.ptr<f32, gmem, align<16>>
      %view = cute.make_view(%ptr) : !memref_gmem_f32_2
      %coord_0 = cute.make_coord(%2, %3) : (i32, i32) -> !cute.coord<"((_,_),(?,?))">
      %5 = cute.static : !cute.layout<"((64,256),(16,64)):((4096,1),(256,262144))">
      %idx_1 = cute.crd2idx(%coord_0, %5) : (!cute.coord<"((_,_),(?,?))">, !cute.layout<"((64,256),(16,64)):((4096,1),(256,262144))">) -> !cute.int_tuple<"?{div=256}">
      %iter_2 = cute.get_iter(%arg1) : !memref_gmem_f32_
      %ptr_3 = cute.add_offset(%iter_2, %idx_1) : (!cute.ptr<f32, gmem, align<16>>, !cute.int_tuple<"?{div=256}">) -> !cute.ptr<f32, gmem, align<16>>
      %view_4 = cute.make_view(%ptr_3) : !memref_gmem_f32_2
      %coord_5 = cute.make_coord(%2, %3) : (i32, i32) -> !cute.coord<"((_,_),(?,?))">
      %lay = cute.get_layout(%arg2) : !memref_gmem_f32_1
      %6:9 = cute.get_scalars(%lay) <{only_dynamic}> : !cute.layout<"((64,256),((?,?),(?,?))):((?{i64},1),((?{i64 div=4096},?{div=256}),(?{i64 div=64},?{div=256})))">
      %7 = cute.static : !cute.shape<"(64,256)">
      %stride = cute.make_stride(%6#4) : (i64) -> !cute.stride<"(?{i64},1)">
      %lay_6 = cute.make_layout(%7, %stride) : !cute.layout<"(64,256):(?{i64},1)">
      %idx_7 = cute.crd2idx(%coord_5, %lay) : (!cute.coord<"((_,_),(?,?))">, !cute.layout<"((64,256),((?,?),(?,?))):((?{i64},1),((?{i64 div=4096},?{div=256}),(?{i64 div=64},?{div=256})))">) -> !cute.int_tuple<"?{i64 div=64}">
      %iter_8 = cute.get_iter(%arg2) : !memref_gmem_f32_1
      %ptr_9 = cute.add_offset(%iter_8, %idx_7) : (!cute.ptr<f32, gmem, align<16>>, !cute.int_tuple<"?{i64 div=64}">) -> !cute.ptr<f32, gmem, align<16>>
      %view_10 = cute.make_view(%ptr_9, %lay_6) : !memref_gmem_f32_3
      %coord_11 = cute.make_coord(%2, %3) : (i32, i32) -> !cute.coord<"((_,_),(?,?))">
      %lay_12 = cute.get_layout(%arg3) : !cute.coord_tensor<"(0,0)", "((64,256),(?,?)):((1@0,1@1),(64@0,256@1))">
      %idx_13 = cute.crd2idx(%coord_11, %lay_12) : (!cute.coord<"((_,_),(?,?))">, !cute.layout<"((64,256),(?,?)):((1@0,1@1),(64@0,256@1))">) -> !cute.int_tuple<"(?{div=64},?{div=256})">
      %8 = cute.static : !cute.int_tuple<"(0,0)">
      %tup = cute.add_offset(%8, %idx_13) : (!cute.int_tuple<"(0,0)">, !cute.int_tuple<"(?{div=64},?{div=256})">) -> !cute.int_tuple<"(?{div=64},?{div=256})">
      %view_14 = cute.make_view(%tup) : !cute.coord_tensor<"(?{div=64},?{div=256})", "(64,256):(1@0,1@1)">
      %iter_15 = cute.get_iter(%view) : !memref_gmem_f32_2
      %view_16 = cute.make_view(%iter_15) : !memref_gmem_f32_4
      %iter_17 = cute.get_iter(%view_4) : !memref_gmem_f32_2
      %view_18 = cute.make_view(%iter_17) : !memref_gmem_f32_4
      %iter_19 = cute.get_iter(%view_10) : !memref_gmem_f32_3
      %lay_20 = cute.get_layout(%view_10) : !memref_gmem_f32_3
      %9 = cute.get_scalars(%lay_20) <{only_dynamic}> : !cute.layout<"(64,256):(?{i64},1)">
      %c16_i64 = arith.constant 16 : i64
      %10 = arith.muli %9, %c16_i64 : i64
      %11 = cute.static : !cute.shape<"((64,4),(4,16))">
      %iv = cute.assume(%10) : (i64) -> !cute.i64<divby 16>
      %stride_21 = cute.make_stride(%iv, %9) : (!cute.i64<divby 16>, i64) -> !cute.stride<"((4,?{i64 div=16}),(1,?{i64}))">
      %lay_22 = cute.make_layout(%11, %stride_21) : !cute.layout<"((64,4),(4,16)):((4,?{i64 div=16}),(1,?{i64}))">
      %view_23 = cute.make_view(%iter_19, %lay_22) : !memref_gmem_f32_5
      %iter_24 = cute.get_iter(%view_14) : !cute.coord_tensor<"(?{div=64},?{div=256})", "(64,256):(1@0,1@1)">
      %view_25 = cute.make_view(%iter_24) : !cute.coord_tensor<"(?{div=64},?{div=256})", "((64,4),(4,16)):((4@1,16@0),(1@1,1@0))">
      %12 = cute.static : !cute.coord<"1">
      %13 = cute.memref.load(%view_16, %12) : (!memref_gmem_f32_4, !cute.coord<"1">) -> f32
      %coord_26 = cute.make_coord(%1) : (i32) -> !cute.coord<"(?,_)">
      %14 = cute.static : !cute.layout<"((64,4),(4,16)):((4,65536),(1,4096))">
      %idx_27 = cute.crd2idx(%coord_26, %14) : (!cute.coord<"(?,_)">, !cute.layout<"((64,4),(4,16)):((4,65536),(1,4096))">) -> !cute.int_tuple<"?{div=4}">
      %iter_28 = cute.get_iter(%view_16) : !memref_gmem_f32_4
      %ptr_29 = cute.add_offset(%iter_28, %idx_27) : (!cute.ptr<f32, gmem, align<16>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, gmem, align<16>>
      %view_30 = cute.make_view(%ptr_29) : !memref_gmem_f32_6
      %coord_31 = cute.make_coord(%1) : (i32) -> !cute.coord<"(?,_)">
      %15 = cute.static : !cute.layout<"((64,4),(4,16)):((4,65536),(1,4096))">
      %idx_32 = cute.crd2idx(%coord_31, %15) : (!cute.coord<"(?,_)">, !cute.layout<"((64,4),(4,16)):((4,65536),(1,4096))">) -> !cute.int_tuple<"?{div=4}">
      %iter_33 = cute.get_iter(%view_18) : !memref_gmem_f32_4
      %ptr_34 = cute.add_offset(%iter_33, %idx_32) : (!cute.ptr<f32, gmem, align<16>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, gmem, align<16>>
      %view_35 = cute.make_view(%ptr_34) : !memref_gmem_f32_6
      %coord_36 = cute.make_coord(%1) : (i32) -> !cute.coord<"(?,_)">
      %lay_37 = cute.get_layout(%view_23) : !memref_gmem_f32_5
      %16:2 = cute.get_scalars(%lay_37) <{only_dynamic}> : !cute.layout<"((64,4),(4,16)):((4,?{i64 div=16}),(1,?{i64}))">
      %17 = cute.static : !cute.shape<"((4,16))">
      %stride_38 = cute.make_stride(%16#1) : (i64) -> !cute.stride<"((1,?{i64}))">
      %lay_39 = cute.make_layout(%17, %stride_38) : !cute.layout<"((4,16)):((1,?{i64}))">
      %idx_40 = cute.crd2idx(%coord_36, %lay_37) : (!cute.coord<"(?,_)">, !cute.layout<"((64,4),(4,16)):((4,?{i64 div=16}),(1,?{i64}))">) -> !cute.int_tuple<"?{i64 div=4}">
      %iter_41 = cute.get_iter(%view_23) : !memref_gmem_f32_5
      %ptr_42 = cute.add_offset(%iter_41, %idx_40) : (!cute.ptr<f32, gmem, align<16>>, !cute.int_tuple<"?{i64 div=4}">) -> !cute.ptr<f32, gmem, align<16>>
      %view_43 = cute.make_view(%ptr_42, %lay_39) : !memref_gmem_f32_7
      %coord_44 = cute.make_coord(%1) : (i32) -> !cute.coord<"(?,_)">
      %18 = cute.static : !cute.layout<"((64,4),(4,16)):((4@1,16@0),(1@1,1@0))">
      %idx_45 = cute.crd2idx(%coord_44, %18) : (!cute.coord<"(?,_)">, !cute.layout<"((64,4),(4,16)):((4@1,16@0),(1@1,1@0))">) -> !cute.int_tuple<"(?{div=16},?{div=4})">
      %iter_46 = cute.get_iter(%view_25) : !cute.coord_tensor<"(?{div=64},?{div=256})", "((64,4),(4,16)):((4@1,16@0),(1@1,1@0))">
      %tup_47 = cute.add_offset(%iter_46, %idx_45) : (!cute.int_tuple<"(?{div=64},?{div=256})">, !cute.int_tuple<"(?{div=16},?{div=4})">) -> !cute.int_tuple<"(?{div=16},?{div=4})">
      %view_48 = cute.make_view(%tup_47) : !cute.coord_tensor<"(?{div=16},?{div=4})", "((4,16)):((1@1,1@0))">
      %19 = cute.static : !cute.layout<"((4,16)):((1,4))">
      %rmem = cute.memref.alloca(%19) : !memref_rmem_i8_
      %20 = cute.static : !cute.int_tuple<"(0,0)">
      %iter_49 = cute.get_iter(%view_48) : !cute.coord_tensor<"(?{div=16},?{div=4})", "((4,16)):((1@1,1@0))">
      %tup_50 = cute.add_offset(%iter_49, %20) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(0,0)">) -> !cute.int_tuple<"(?{div=16},?{div=4})">
      %view_51 = cute.make_view(%tup_50) : !cute.coord_tensor<"(?{div=16},?{div=4})", "():()">
      %iter_52 = cute.get_iter(%view_51) : !cute.coord_tensor<"(?{div=16},?{div=4})", "():()">
      %e0, %e1 = cute.get_leaves(%iter_52) : !cute.int_tuple<"(?{div=16},?{div=4})">
      %coord_53 = cute.make_coord(%e0, %e1) : (!cute.int_tuple<"?{div=16}">, !cute.int_tuple<"?{div=4}">) -> !cute.coord<"(?{div=16},?{div=4})">
      %coord_54 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %21:2 = cute.get_scalars(%coord_53) : !cute.coord<"(?{div=16},?{div=4})">
      %22:2 = cute.get_scalars(%coord_54) : !cute.coord<"(?,?)">
      %true = arith.constant true
      %23 = arith.cmpi slt, %21#0, %22#0 : i32
      %24 = arith.andi %true, %23 : i1
      %25 = arith.cmpi slt, %21#1, %22#1 : i32
      %26 = arith.andi %24, %25 : i1
      %27 = arith.extui %26 : i1 to i8
      %28 = cute.static : !cute.coord<"0">
      cute.memref.store(%rmem, %28, %27) : (!memref_rmem_i8_, !cute.coord<"0">, i8) -> ()
      %29 = cute.static : !cute.int_tuple<"(0,1)">
      %iter_55 = cute.get_iter(%view_48) : !cute.coord_tensor<"(?{div=16},?{div=4})", "((4,16)):((1@1,1@0))">
      %tup_56 = cute.add_offset(%iter_55, %29) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(0,1)">) -> !cute.int_tuple<"(?{div=16},?)">
      %view_57 = cute.make_view(%tup_56) : !cute.coord_tensor<"(?{div=16},?)", "():()">
      %iter_58 = cute.get_iter(%view_57) : !cute.coord_tensor<"(?{div=16},?)", "():()">
      %e0_59, %e1_60 = cute.get_leaves(%iter_58) : !cute.int_tuple<"(?{div=16},?)">
      %coord_61 = cute.make_coord(%e0_59, %e1_60) : (!cute.int_tuple<"?{div=16}">, !cute.int_tuple<"?">) -> !cute.coord<"(?{div=16},?)">
      %coord_62 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %30:2 = cute.get_scalars(%coord_61) : !cute.coord<"(?{div=16},?)">
      %31:2 = cute.get_scalars(%coord_62) : !cute.coord<"(?,?)">
      %true_63 = arith.constant true
      %32 = arith.cmpi slt, %30#0, %31#0 : i32
      %33 = arith.andi %true_63, %32 : i1
      %34 = arith.cmpi slt, %30#1, %31#1 : i32
      %35 = arith.andi %33, %34 : i1
      %36 = arith.extui %35 : i1 to i8
      %37 = cute.static : !cute.coord<"1">
      cute.memref.store(%rmem, %37, %36) : (!memref_rmem_i8_, !cute.coord<"1">, i8) -> ()
      %38 = cute.static : !cute.int_tuple<"(0,2)">
      %iter_64 = cute.get_iter(%view_48) : !cute.coord_tensor<"(?{div=16},?{div=4})", "((4,16)):((1@1,1@0))">
      %tup_65 = cute.add_offset(%iter_64, %38) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(0,2)">) -> !cute.int_tuple<"(?{div=16},?{div=2})">
      %view_66 = cute.make_view(%tup_65) : !cute.coord_tensor<"(?{div=16},?{div=2})", "():()">
      %iter_67 = cute.get_iter(%view_66) : !cute.coord_tensor<"(?{div=16},?{div=2})", "():()">
      %e0_68, %e1_69 = cute.get_leaves(%iter_67) : !cute.int_tuple<"(?{div=16},?{div=2})">
      %coord_70 = cute.make_coord(%e0_68, %e1_69) : (!cute.int_tuple<"?{div=16}">, !cute.int_tuple<"?{div=2}">) -> !cute.coord<"(?{div=16},?{div=2})">
      %coord_71 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %39:2 = cute.get_scalars(%coord_70) : !cute.coord<"(?{div=16},?{div=2})">
      %40:2 = cute.get_scalars(%coord_71) : !cute.coord<"(?,?)">
      %true_72 = arith.constant true
      %41 = arith.cmpi slt, %39#0, %40#0 : i32
      %42 = arith.andi %true_72, %41 : i1
      %43 = arith.cmpi slt, %39#1, %40#1 : i32
      %44 = arith.andi %42, %43 : i1
      %45 = arith.extui %44 : i1 to i8
      %46 = cute.static : !cute.coord<"2">
      cute.memref.store(%rmem, %46, %45) : (!memref_rmem_i8_, !cute.coord<"2">, i8) -> ()
      %47 = cute.static : !cute.int_tuple<"(0,3)">
      %iter_73 = cute.get_iter(%view_48) : !cute.coord_tensor<"(?{div=16},?{div=4})", "((4,16)):((1@1,1@0))">
      %tup_74 = cute.add_offset(%iter_73, %47) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(0,3)">) -> !cute.int_tuple<"(?{div=16},?)">
      %view_75 = cute.make_view(%tup_74) : !cute.coord_tensor<"(?{div=16},?)", "():()">
      %iter_76 = cute.get_iter(%view_75) : !cute.coord_tensor<"(?{div=16},?)", "():()">
      %e0_77, %e1_78 = cute.get_leaves(%iter_76) : !cute.int_tuple<"(?{div=16},?)">
      %coord_79 = cute.make_coord(%e0_77, %e1_78) : (!cute.int_tuple<"?{div=16}">, !cute.int_tuple<"?">) -> !cute.coord<"(?{div=16},?)">
      %coord_80 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %48:2 = cute.get_scalars(%coord_79) : !cute.coord<"(?{div=16},?)">
      %49:2 = cute.get_scalars(%coord_80) : !cute.coord<"(?,?)">
      %true_81 = arith.constant true
      %50 = arith.cmpi slt, %48#0, %49#0 : i32
      %51 = arith.andi %true_81, %50 : i1
      %52 = arith.cmpi slt, %48#1, %49#1 : i32
      %53 = arith.andi %51, %52 : i1
      %54 = arith.extui %53 : i1 to i8
      %55 = cute.static : !cute.coord<"3">
      cute.memref.store(%rmem, %55, %54) : (!memref_rmem_i8_, !cute.coord<"3">, i8) -> ()
      %56 = cute.static : !cute.int_tuple<"(1,0)">
      %iter_82 = cute.get_iter(%view_48) : !cute.coord_tensor<"(?{div=16},?{div=4})", "((4,16)):((1@1,1@0))">
      %tup_83 = cute.add_offset(%iter_82, %56) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(1,0)">) -> !cute.int_tuple<"(?,?{div=4})">
      %view_84 = cute.make_view(%tup_83) : !cute.coord_tensor<"(?,?{div=4})", "():()">
      %iter_85 = cute.get_iter(%view_84) : !cute.coord_tensor<"(?,?{div=4})", "():()">
      %e0_86, %e1_87 = cute.get_leaves(%iter_85) : !cute.int_tuple<"(?,?{div=4})">
      %coord_88 = cute.make_coord(%e0_86, %e1_87) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=4}">) -> !cute.coord<"(?,?{div=4})">
      %coord_89 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %57:2 = cute.get_scalars(%coord_88) : !cute.coord<"(?,?{div=4})">
      %58:2 = cute.get_scalars(%coord_89) : !cute.coord<"(?,?)">
      %true_90 = arith.constant true
      %59 = arith.cmpi slt, %57#0, %58#0 : i32
      %60 = arith.andi %true_90, %59 : i1
      %61 = arith.cmpi slt, %57#1, %58#1 : i32
      %62 = arith.andi %60, %61 : i1
      %63 = arith.extui %62 : i1 to i8
      %64 = cute.static : !cute.coord<"4">
      cute.memref.store(%rmem, %64, %63) : (!memref_rmem_i8_, !cute.coord<"4">, i8) -> ()
      %65 = cute.static : !cute.int_tuple<"(1,1)">
      %iter_91 = cute.get_iter(%view_48) : !cute.coord_tensor<"(?{div=16},?{div=4})", "((4,16)):((1@1,1@0))">
      %tup_92 = cute.add_offset(%iter_91, %65) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(1,1)">) -> !cute.int_tuple<"(?,?)">
      %view_93 = cute.make_view(%tup_92) : !cute.coord_tensor<"(?,?)", "():()">
      %iter_94 = cute.get_iter(%view_93) : !cute.coord_tensor<"(?,?)", "():()">
      %e0_95, %e1_96 = cute.get_leaves(%iter_94) : !cute.int_tuple<"(?,?)">
      %coord_97 = cute.make_coord(%e0_95, %e1_96) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
      %coord_98 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %66:2 = cute.get_scalars(%coord_97) : !cute.coord<"(?,?)">
      %67:2 = cute.get_scalars(%coord_98) : !cute.coord<"(?,?)">
      %true_99 = arith.constant true
      %68 = arith.cmpi slt, %66#0, %67#0 : i32
      %69 = arith.andi %true_99, %68 : i1
      %70 = arith.cmpi slt, %66#1, %67#1 : i32
      %71 = arith.andi %69, %70 : i1
      %72 = arith.extui %71 : i1 to i8
      %73 = cute.static : !cute.coord<"5">
      cute.memref.store(%rmem, %73, %72) : (!memref_rmem_i8_, !cute.coord<"5">, i8) -> ()
      %74 = cute.static : !cute.int_tuple<"(1,2)">
      %iter_100 = cute.get_iter(%view_48) : !cute.coord_tensor<"(?{div=16},?{div=4})", "((4,16)):((1@1,1@0))">
      %tup_101 = cute.add_offset(%iter_100, %74) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(1,2)">) -> !cute.int_tuple<"(?,?{div=2})">
      %view_102 = cute.make_view(%tup_101) : !cute.coord_tensor<"(?,?{div=2})", "():()">
      %iter_103 = cute.get_iter(%view_102) : !cute.coord_tensor<"(?,?{div=2})", "():()">
      %e0_104, %e1_105 = cute.get_leaves(%iter_103) : !cute.int_tuple<"(?,?{div=2})">
      %coord_106 = cute.make_coord(%e0_104, %e1_105) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=2}">) -> !cute.coord<"(?,?{div=2})">
      %coord_107 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %75:2 = cute.get_scalars(%coord_106) : !cute.coord<"(?,?{div=2})">
      %76:2 = cute.get_scalars(%coord_107) : !cute.coord<"(?,?)">
      %true_108 = arith.constant true
      %77 = arith.cmpi slt, %75#0, %76#0 : i32
      %78 = arith.andi %true_108, %77 : i1
      %79 = arith.cmpi slt, %75#1, %76#1 : i32
      %80 = arith.andi %78, %79 : i1
      %81 = arith.extui %80 : i1 to i8
      %82 = cute.static : !cute.coord<"6">
      cute.memref.store(%rmem, %82, %81) : (!memref_rmem_i8_, !cute.coord<"6">, i8) -> ()
      %83 = cute.static : !cute.int_tuple<"(1,3)">
      %iter_109 = cute.get_iter(%view_48) : !cute.coord_tensor<"(?{div=16},?{div=4})", "((4,16)):((1@1,1@0))">
      %tup_110 = cute.add_offset(%iter_109, %83) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(1,3)">) -> !cute.int_tuple<"(?,?)">
      %view_111 = cute.make_view(%tup_110) : !cute.coord_tensor<"(?,?)", "():()">
      %iter_112 = cute.get_iter(%view_111) : !cute.coord_tensor<"(?,?)", "():()">
      %e0_113, %e1_114 = cute.get_leaves(%iter_112) : !cute.int_tuple<"(?,?)">
      %coord_115 = cute.make_coord(%e0_113, %e1_114) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
      %coord_116 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %84:2 = cute.get_scalars(%coord_115) : !cute.coord<"(?,?)">
      %85:2 = cute.get_scalars(%coord_116) : !cute.coord<"(?,?)">
      %true_117 = arith.constant true
      %86 = arith.cmpi slt, %84#0, %85#0 : i32
      %87 = arith.andi %true_117, %86 : i1
      %88 = arith.cmpi slt, %84#1, %85#1 : i32
      %89 = arith.andi %87, %88 : i1
      %90 = arith.extui %89 : i1 to i8
      %91 = cute.static : !cute.coord<"7">
      cute.memref.store(%rmem, %91, %90) : (!memref_rmem_i8_, !cute.coord<"7">, i8) -> ()
      %92 = cute.static : !cute.int_tuple<"(2,0)">
      %iter_118 = cute.get_iter(%view_48) : !cute.coord_tensor<"(?{div=16},?{div=4})", "((4,16)):((1@1,1@0))">
      %tup_119 = cute.add_offset(%iter_118, %92) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(2,0)">) -> !cute.int_tuple<"(?{div=2},?{div=4})">
      %view_120 = cute.make_view(%tup_119) : !cute.coord_tensor<"(?{div=2},?{div=4})", "():()">
      %iter_121 = cute.get_iter(%view_120) : !cute.coord_tensor<"(?{div=2},?{div=4})", "():()">
      %e0_122, %e1_123 = cute.get_leaves(%iter_121) : !cute.int_tuple<"(?{div=2},?{div=4})">
      %coord_124 = cute.make_coord(%e0_122, %e1_123) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"?{div=4}">) -> !cute.coord<"(?{div=2},?{div=4})">
      %coord_125 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %93:2 = cute.get_scalars(%coord_124) : !cute.coord<"(?{div=2},?{div=4})">
      %94:2 = cute.get_scalars(%coord_125) : !cute.coord<"(?,?)">
      %true_126 = arith.constant true
      %95 = arith.cmpi slt, %93#0, %94#0 : i32
      %96 = arith.andi %true_126, %95 : i1
      %97 = arith.cmpi slt, %93#1, %94#1 : i32
      %98 = arith.andi %96, %97 : i1
      %99 = arith.extui %98 : i1 to i8
      %100 = cute.static : !cute.coord<"8">
      cute.memref.store(%rmem, %100, %99) : (!memref_rmem_i8_, !cute.coord<"8">, i8) -> ()
      %101 = cute.static : !cute.int_tuple<"(2,1)">
      %iter_127 = cute.get_iter(%view_48) : !cute.coord_tensor<"(?{div=16},?{div=4})", "((4,16)):((1@1,1@0))">
      %tup_128 = cute.add_offset(%iter_127, %101) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(2,1)">) -> !cute.int_tuple<"(?{div=2},?)">
      %view_129 = cute.make_view(%tup_128) : !cute.coord_tensor<"(?{div=2},?)", "():()">
      %iter_130 = cute.get_iter(%view_129) : !cute.coord_tensor<"(?{div=2},?)", "():()">
      %e0_131, %e1_132 = cute.get_leaves(%iter_130) : !cute.int_tuple<"(?{div=2},?)">
      %coord_133 = cute.make_coord(%e0_131, %e1_132) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"?">) -> !cute.coord<"(?{div=2},?)">
      %coord_134 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %102:2 = cute.get_scalars(%coord_133) : !cute.coord<"(?{div=2},?)">
      %103:2 = cute.get_scalars(%coord_134) : !cute.coord<"(?,?)">
      %true_135 = arith.constant true
      %104 = arith.cmpi slt, %102#0, %103#0 : i32
      %105 = arith.andi %true_135, %104 : i1
      %106 = arith.cmpi slt, %102#1, %103#1 : i32
      %107 = arith.andi %105, %106 : i1
      %108 = arith.extui %107 : i1 to i8
      %109 = cute.static : !cute.coord<"9">
      cute.memref.store(%rmem, %109, %108) : (!memref_rmem_i8_, !cute.coord<"9">, i8) -> ()
      %110 = cute.static : !cute.int_tuple<"(2,2)">
      %iter_136 = cute.get_iter(%view_48) : !cute.coord_tensor<"(?{div=16},?{div=4})", "((4,16)):((1@1,1@0))">
      %tup_137 = cute.add_offset(%iter_136, %110) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(2,2)">) -> !cute.int_tuple<"(?{div=2},?{div=2})">
      %view_138 = cute.make_view(%tup_137) : !cute.coord_tensor<"(?{div=2},?{div=2})", "():()">
      %iter_139 = cute.get_iter(%view_138) : !cute.coord_tensor<"(?{div=2},?{div=2})", "():()">
      %e0_140, %e1_141 = cute.get_leaves(%iter_139) : !cute.int_tuple<"(?{div=2},?{div=2})">
      %coord_142 = cute.make_coord(%e0_140, %e1_141) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"?{div=2}">) -> !cute.coord<"(?{div=2},?{div=2})">
      %coord_143 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %111:2 = cute.get_scalars(%coord_142) : !cute.coord<"(?{div=2},?{div=2})">
      %112:2 = cute.get_scalars(%coord_143) : !cute.coord<"(?,?)">
      %true_144 = arith.constant true
      %113 = arith.cmpi slt, %111#0, %112#0 : i32
      %114 = arith.andi %true_144, %113 : i1
      %115 = arith.cmpi slt, %111#1, %112#1 : i32
      %116 = arith.andi %114, %115 : i1
      %117 = arith.extui %116 : i1 to i8
      %118 = cute.static : !cute.coord<"10">
      cute.memref.store(%rmem, %118, %117) : (!memref_rmem_i8_, !cute.coord<"10">, i8) -> ()
      %119 = cute.static : !cute.int_tuple<"(2,3)">
      %iter_145 = cute.get_iter(%view_48) : !cute.coord_tensor<"(?{div=16},?{div=4})", "((4,16)):((1@1,1@0))">
      %tup_146 = cute.add_offset(%iter_145, %119) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(2,3)">) -> !cute.int_tuple<"(?{div=2},?)">
      %view_147 = cute.make_view(%tup_146) : !cute.coord_tensor<"(?{div=2},?)", "():()">
      %iter_148 = cute.get_iter(%view_147) : !cute.coord_tensor<"(?{div=2},?)", "():()">
      %e0_149, %e1_150 = cute.get_leaves(%iter_148) : !cute.int_tuple<"(?{div=2},?)">
      %coord_151 = cute.make_coord(%e0_149, %e1_150) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"?">) -> !cute.coord<"(?{div=2},?)">
      %coord_152 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %120:2 = cute.get_scalars(%coord_151) : !cute.coord<"(?{div=2},?)">
      %121:2 = cute.get_scalars(%coord_152) : !cute.coord<"(?,?)">
      %true_153 = arith.constant true
      %122 = arith.cmpi slt, %120#0, %121#0 : i32
      %123 = arith.andi %true_153, %122 : i1
      %124 = arith.cmpi slt, %120#1, %121#1 : i32
      %125 = arith.andi %123, %124 : i1
      %126 = arith.extui %125 : i1 to i8
      %127 = cute.static : !cute.coord<"11">
      cute.memref.store(%rmem, %127, %126) : (!memref_rmem_i8_, !cute.coord<"11">, i8) -> ()
      %128 = cute.static : !cute.int_tuple<"(3,0)">
      %iter_154 = cute.get_iter(%view_48) : !cute.coord_tensor<"(?{div=16},?{div=4})", "((4,16)):((1@1,1@0))">
      %tup_155 = cute.add_offset(%iter_154, %128) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(3,0)">) -> !cute.int_tuple<"(?,?{div=4})">
      %view_156 = cute.make_view(%tup_155) : !cute.coord_tensor<"(?,?{div=4})", "():()">
      %iter_157 = cute.get_iter(%view_156) : !cute.coord_tensor<"(?,?{div=4})", "():()">
      %e0_158, %e1_159 = cute.get_leaves(%iter_157) : !cute.int_tuple<"(?,?{div=4})">
      %coord_160 = cute.make_coord(%e0_158, %e1_159) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=4}">) -> !cute.coord<"(?,?{div=4})">
      %coord_161 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %129:2 = cute.get_scalars(%coord_160) : !cute.coord<"(?,?{div=4})">
      %130:2 = cute.get_scalars(%coord_161) : !cute.coord<"(?,?)">
      %true_162 = arith.constant true
      %131 = arith.cmpi slt, %129#0, %130#0 : i32
      %132 = arith.andi %true_162, %131 : i1
      %133 = arith.cmpi slt, %129#1, %130#1 : i32
      %134 = arith.andi %132, %133 : i1
      %135 = arith.extui %134 : i1 to i8
      %136 = cute.static : !cute.coord<"12">
      cute.memref.store(%rmem, %136, %135) : (!memref_rmem_i8_, !cute.coord<"12">, i8) -> ()
      %137 = cute.static : !cute.int_tuple<"(3,1)">
      %iter_163 = cute.get_iter(%view_48) : !cute.coord_tensor<"(?{div=16},?{div=4})", "((4,16)):((1@1,1@0))">
      %tup_164 = cute.add_offset(%iter_163, %137) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(3,1)">) -> !cute.int_tuple<"(?,?)">
      %view_165 = cute.make_view(%tup_164) : !cute.coord_tensor<"(?,?)", "():()">
      %iter_166 = cute.get_iter(%view_165) : !cute.coord_tensor<"(?,?)", "():()">
      %e0_167, %e1_168 = cute.get_leaves(%iter_166) : !cute.int_tuple<"(?,?)">
      %coord_169 = cute.make_coord(%e0_167, %e1_168) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
      %coord_170 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %138:2 = cute.get_scalars(%coord_169) : !cute.coord<"(?,?)">
      %139:2 = cute.get_scalars(%coord_170) : !cute.coord<"(?,?)">
      %true_171 = arith.constant true
      %140 = arith.cmpi slt, %138#0, %139#0 : i32
      %141 = arith.andi %true_171, %140 : i1
      %142 = arith.cmpi slt, %138#1, %139#1 : i32
      %143 = arith.andi %141, %142 : i1
      %144 = arith.extui %143 : i1 to i8
      %145 = cute.static : !cute.coord<"13">
      cute.memref.store(%rmem, %145, %144) : (!memref_rmem_i8_, !cute.coord<"13">, i8) -> ()
      %146 = cute.static : !cute.int_tuple<"(3,2)">
      %iter_172 = cute.get_iter(%view_48) : !cute.coord_tensor<"(?{div=16},?{div=4})", "((4,16)):((1@1,1@0))">
      %tup_173 = cute.add_offset(%iter_172, %146) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(3,2)">) -> !cute.int_tuple<"(?,?{div=2})">
      %view_174 = cute.make_view(%tup_173) : !cute.coord_tensor<"(?,?{div=2})", "():()">
      %iter_175 = cute.get_iter(%view_174) : !cute.coord_tensor<"(?,?{div=2})", "():()">
      %e0_176, %e1_177 = cute.get_leaves(%iter_175) : !cute.int_tuple<"(?,?{div=2})">
      %coord_178 = cute.make_coord(%e0_176, %e1_177) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=2}">) -> !cute.coord<"(?,?{div=2})">
      %coord_179 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %147:2 = cute.get_scalars(%coord_178) : !cute.coord<"(?,?{div=2})">
      %148:2 = cute.get_scalars(%coord_179) : !cute.coord<"(?,?)">
      %true_180 = arith.constant true
      %149 = arith.cmpi slt, %147#0, %148#0 : i32
      %150 = arith.andi %true_180, %149 : i1
      %151 = arith.cmpi slt, %147#1, %148#1 : i32
      %152 = arith.andi %150, %151 : i1
      %153 = arith.extui %152 : i1 to i8
      %154 = cute.static : !cute.coord<"14">
      cute.memref.store(%rmem, %154, %153) : (!memref_rmem_i8_, !cute.coord<"14">, i8) -> ()
      %155 = cute.static : !cute.int_tuple<"(3,3)">
      %iter_181 = cute.get_iter(%view_48) : !cute.coord_tensor<"(?{div=16},?{div=4})", "((4,16)):((1@1,1@0))">
      %tup_182 = cute.add_offset(%iter_181, %155) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(3,3)">) -> !cute.int_tuple<"(?,?)">
      %view_183 = cute.make_view(%tup_182) : !cute.coord_tensor<"(?,?)", "():()">
      %iter_184 = cute.get_iter(%view_183) : !cute.coord_tensor<"(?,?)", "():()">
      %e0_185, %e1_186 = cute.get_leaves(%iter_184) : !cute.int_tuple<"(?,?)">
      %coord_187 = cute.make_coord(%e0_185, %e1_186) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
      %coord_188 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %156:2 = cute.get_scalars(%coord_187) : !cute.coord<"(?,?)">
      %157:2 = cute.get_scalars(%coord_188) : !cute.coord<"(?,?)">
      %true_189 = arith.constant true
      %158 = arith.cmpi slt, %156#0, %157#0 : i32
      %159 = arith.andi %true_189, %158 : i1
      %160 = arith.cmpi slt, %156#1, %157#1 : i32
      %161 = arith.andi %159, %160 : i1
      %162 = arith.extui %161 : i1 to i8
      %163 = cute.static : !cute.coord<"15">
      cute.memref.store(%rmem, %163, %162) : (!memref_rmem_i8_, !cute.coord<"15">, i8) -> ()
      %164 = cute.static : !cute.int_tuple<"(4,0)">
      %iter_190 = cute.get_iter(%view_48) : !cute.coord_tensor<"(?{div=16},?{div=4})", "((4,16)):((1@1,1@0))">
      %tup_191 = cute.add_offset(%iter_190, %164) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(4,0)">) -> !cute.int_tuple<"(?{div=4},?{div=4})">
      %view_192 = cute.make_view(%tup_191) : !cute.coord_tensor<"(?{div=4},?{div=4})", "():()">
      %iter_193 = cute.get_iter(%view_192) : !cute.coord_tensor<"(?{div=4},?{div=4})", "():()">
      %e0_194, %e1_195 = cute.get_leaves(%iter_193) : !cute.int_tuple<"(?{div=4},?{div=4})">
      %coord_196 = cute.make_coord(%e0_194, %e1_195) : (!cute.int_tuple<"?{div=4}">, !cute.int_tuple<"?{div=4}">) -> !cute.coord<"(?{div=4},?{div=4})">
      %coord_197 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %165:2 = cute.get_scalars(%coord_196) : !cute.coord<"(?{div=4},?{div=4})">
      %166:2 = cute.get_scalars(%coord_197) : !cute.coord<"(?,?)">
      %true_198 = arith.constant true
      %167 = arith.cmpi slt, %165#0, %166#0 : i32
      %168 = arith.andi %true_198, %167 : i1
      %169 = arith.cmpi slt, %165#1, %166#1 : i32
      %170 = arith.andi %168, %169 : i1
      %171 = arith.extui %170 : i1 to i8
      %172 = cute.static : !cute.coord<"16">
      cute.memref.store(%rmem, %172, %171) : (!memref_rmem_i8_, !cute.coord<"16">, i8) -> ()
      %173 = cute.static : !cute.int_tuple<"(4,1)">
      %iter_199 = cute.get_iter(%view_48) : !cute.coord_tensor<"(?{div=16},?{div=4})", "((4,16)):((1@1,1@0))">
      %tup_200 = cute.add_offset(%iter_199, %173) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(4,1)">) -> !cute.int_tuple<"(?{div=4},?)">
      %view_201 = cute.make_view(%tup_200) : !cute.coord_tensor<"(?{div=4},?)", "():()">
      %iter_202 = cute.get_iter(%view_201) : !cute.coord_tensor<"(?{div=4},?)", "():()">
      %e0_203, %e1_204 = cute.get_leaves(%iter_202) : !cute.int_tuple<"(?{div=4},?)">
      %coord_205 = cute.make_coord(%e0_203, %e1_204) : (!cute.int_tuple<"?{div=4}">, !cute.int_tuple<"?">) -> !cute.coord<"(?{div=4},?)">
      %coord_206 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %174:2 = cute.get_scalars(%coord_205) : !cute.coord<"(?{div=4},?)">
      %175:2 = cute.get_scalars(%coord_206) : !cute.coord<"(?,?)">
      %true_207 = arith.constant true
      %176 = arith.cmpi slt, %174#0, %175#0 : i32
      %177 = arith.andi %true_207, %176 : i1
      %178 = arith.cmpi slt, %174#1, %175#1 : i32
      %179 = arith.andi %177, %178 : i1
      %180 = arith.extui %179 : i1 to i8
      %181 = cute.static : !cute.coord<"17">
      cute.memref.store(%rmem, %181, %180) : (!memref_rmem_i8_, !cute.coord<"17">, i8) -> ()
      %182 = cute.static : !cute.int_tuple<"(4,2)">
      %iter_208 = cute.get_iter(%view_48) : !cute.coord_tensor<"(?{div=16},?{div=4})", "((4,16)):((1@1,1@0))">
      %tup_209 = cute.add_offset(%iter_208, %182) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(4,2)">) -> !cute.int_tuple<"(?{div=4},?{div=2})">
      %view_210 = cute.make_view(%tup_209) : !cute.coord_tensor<"(?{div=4},?{div=2})", "():()">
      %iter_211 = cute.get_iter(%view_210) : !cute.coord_tensor<"(?{div=4},?{div=2})", "():()">
      %e0_212, %e1_213 = cute.get_leaves(%iter_211) : !cute.int_tuple<"(?{div=4},?{div=2})">
      %coord_214 = cute.make_coord(%e0_212, %e1_213) : (!cute.int_tuple<"?{div=4}">, !cute.int_tuple<"?{div=2}">) -> !cute.coord<"(?{div=4},?{div=2})">
      %coord_215 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %183:2 = cute.get_scalars(%coord_214) : !cute.coord<"(?{div=4},?{div=2})">
      %184:2 = cute.get_scalars(%coord_215) : !cute.coord<"(?,?)">
      %true_216 = arith.constant true
      %185 = arith.cmpi slt, %183#0, %184#0 : i32
      %186 = arith.andi %true_216, %185 : i1
      %187 = arith.cmpi slt, %183#1, %184#1 : i32
      %188 = arith.andi %186, %187 : i1
      %189 = arith.extui %188 : i1 to i8
      %190 = cute.static : !cute.coord<"18">
      cute.memref.store(%rmem, %190, %189) : (!memref_rmem_i8_, !cute.coord<"18">, i8) -> ()
      %191 = cute.static : !cute.int_tuple<"(4,3)">
      %iter_217 = cute.get_iter(%view_48) : !cute.coord_tensor<"(?{div=16},?{div=4})", "((4,16)):((1@1,1@0))">
      %tup_218 = cute.add_offset(%iter_217, %191) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(4,3)">) -> !cute.int_tuple<"(?{div=4},?)">
      %view_219 = cute.make_view(%tup_218) : !cute.coord_tensor<"(?{div=4},?)", "():()">
      %iter_220 = cute.get_iter(%view_219) : !cute.coord_tensor<"(?{div=4},?)", "():()">
      %e0_221, %e1_222 = cute.get_leaves(%iter_220) : !cute.int_tuple<"(?{div=4},?)">
      %coord_223 = cute.make_coord(%e0_221, %e1_222) : (!cute.int_tuple<"?{div=4}">, !cute.int_tuple<"?">) -> !cute.coord<"(?{div=4},?)">
      %coord_224 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %192:2 = cute.get_scalars(%coord_223) : !cute.coord<"(?{div=4},?)">
      %193:2 = cute.get_scalars(%coord_224) : !cute.coord<"(?,?)">
      %true_225 = arith.constant true
      %194 = arith.cmpi slt, %192#0, %193#0 : i32
      %195 = arith.andi %true_225, %194 : i1
      %196 = arith.cmpi slt, %192#1, %193#1 : i32
      %197 = arith.andi %195, %196 : i1
      %198 = arith.extui %197 : i1 to i8
      %199 = cute.static : !cute.coord<"19">
      cute.memref.store(%rmem, %199, %198) : (!memref_rmem_i8_, !cute.coord<"19">, i8) -> ()
      %200 = cute.static : !cute.int_tuple<"(5,0)">
      %iter_226 = cute.get_iter(%view_48) : !cute.coord_tensor<"(?{div=16},?{div=4})", "((4,16)):((1@1,1@0))">
      %tup_227 = cute.add_offset(%iter_226, %200) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(5,0)">) -> !cute.int_tuple<"(?,?{div=4})">
      %view_228 = cute.make_view(%tup_227) : !cute.coord_tensor<"(?,?{div=4})", "():()">
      %iter_229 = cute.get_iter(%view_228) : !cute.coord_tensor<"(?,?{div=4})", "():()">
      %e0_230, %e1_231 = cute.get_leaves(%iter_229) : !cute.int_tuple<"(?,?{div=4})">
      %coord_232 = cute.make_coord(%e0_230, %e1_231) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=4}">) -> !cute.coord<"(?,?{div=4})">
      %coord_233 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %201:2 = cute.get_scalars(%coord_232) : !cute.coord<"(?,?{div=4})">
      %202:2 = cute.get_scalars(%coord_233) : !cute.coord<"(?,?)">
      %true_234 = arith.constant true
      %203 = arith.cmpi slt, %201#0, %202#0 : i32
      %204 = arith.andi %true_234, %203 : i1
      %205 = arith.cmpi slt, %201#1, %202#1 : i32
      %206 = arith.andi %204, %205 : i1
      %207 = arith.extui %206 : i1 to i8
      %208 = cute.static : !cute.coord<"20">
      cute.memref.store(%rmem, %208, %207) : (!memref_rmem_i8_, !cute.coord<"20">, i8) -> ()
      %209 = cute.static : !cute.int_tuple<"(5,1)">
      %iter_235 = cute.get_iter(%view_48) : !cute.coord_tensor<"(?{div=16},?{div=4})", "((4,16)):((1@1,1@0))">
      %tup_236 = cute.add_offset(%iter_235, %209) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(5,1)">) -> !cute.int_tuple<"(?,?)">
      %view_237 = cute.make_view(%tup_236) : !cute.coord_tensor<"(?,?)", "():()">
      %iter_238 = cute.get_iter(%view_237) : !cute.coord_tensor<"(?,?)", "():()">
      %e0_239, %e1_240 = cute.get_leaves(%iter_238) : !cute.int_tuple<"(?,?)">
      %coord_241 = cute.make_coord(%e0_239, %e1_240) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
      %coord_242 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %210:2 = cute.get_scalars(%coord_241) : !cute.coord<"(?,?)">
      %211:2 = cute.get_scalars(%coord_242) : !cute.coord<"(?,?)">
      %true_243 = arith.constant true
      %212 = arith.cmpi slt, %210#0, %211#0 : i32
      %213 = arith.andi %true_243, %212 : i1
      %214 = arith.cmpi slt, %210#1, %211#1 : i32
      %215 = arith.andi %213, %214 : i1
      %216 = arith.extui %215 : i1 to i8
      %217 = cute.static : !cute.coord<"21">
      cute.memref.store(%rmem, %217, %216) : (!memref_rmem_i8_, !cute.coord<"21">, i8) -> ()
      %218 = cute.static : !cute.int_tuple<"(5,2)">
      %iter_244 = cute.get_iter(%view_48) : !cute.coord_tensor<"(?{div=16},?{div=4})", "((4,16)):((1@1,1@0))">
      %tup_245 = cute.add_offset(%iter_244, %218) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(5,2)">) -> !cute.int_tuple<"(?,?{div=2})">
      %view_246 = cute.make_view(%tup_245) : !cute.coord_tensor<"(?,?{div=2})", "():()">
      %iter_247 = cute.get_iter(%view_246) : !cute.coord_tensor<"(?,?{div=2})", "():()">
      %e0_248, %e1_249 = cute.get_leaves(%iter_247) : !cute.int_tuple<"(?,?{div=2})">
      %coord_250 = cute.make_coord(%e0_248, %e1_249) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=2}">) -> !cute.coord<"(?,?{div=2})">
      %coord_251 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %219:2 = cute.get_scalars(%coord_250) : !cute.coord<"(?,?{div=2})">
      %220:2 = cute.get_scalars(%coord_251) : !cute.coord<"(?,?)">
      %true_252 = arith.constant true
      %221 = arith.cmpi slt, %219#0, %220#0 : i32
      %222 = arith.andi %true_252, %221 : i1
      %223 = arith.cmpi slt, %219#1, %220#1 : i32
      %224 = arith.andi %222, %223 : i1
      %225 = arith.extui %224 : i1 to i8
      %226 = cute.static : !cute.coord<"22">
      cute.memref.store(%rmem, %226, %225) : (!memref_rmem_i8_, !cute.coord<"22">, i8) -> ()
      %227 = cute.static : !cute.int_tuple<"(5,3)">
      %iter_253 = cute.get_iter(%view_48) : !cute.coord_tensor<"(?{div=16},?{div=4})", "((4,16)):((1@1,1@0))">
      %tup_254 = cute.add_offset(%iter_253, %227) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(5,3)">) -> !cute.int_tuple<"(?,?)">
      %view_255 = cute.make_view(%tup_254) : !cute.coord_tensor<"(?,?)", "():()">
      %iter_256 = cute.get_iter(%view_255) : !cute.coord_tensor<"(?,?)", "():()">
      %e0_257, %e1_258 = cute.get_leaves(%iter_256) : !cute.int_tuple<"(?,?)">
      %coord_259 = cute.make_coord(%e0_257, %e1_258) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
      %coord_260 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %228:2 = cute.get_scalars(%coord_259) : !cute.coord<"(?,?)">
      %229:2 = cute.get_scalars(%coord_260) : !cute.coord<"(?,?)">
      %true_261 = arith.constant true
      %230 = arith.cmpi slt, %228#0, %229#0 : i32
      %231 = arith.andi %true_261, %230 : i1
      %232 = arith.cmpi slt, %228#1, %229#1 : i32
      %233 = arith.andi %231, %232 : i1
      %234 = arith.extui %233 : i1 to i8
      %235 = cute.static : !cute.coord<"23">
      cute.memref.store(%rmem, %235, %234) : (!memref_rmem_i8_, !cute.coord<"23">, i8) -> ()
      %236 = cute.static : !cute.int_tuple<"(6,0)">
      %iter_262 = cute.get_iter(%view_48) : !cute.coord_tensor<"(?{div=16},?{div=4})", "((4,16)):((1@1,1@0))">
      %tup_263 = cute.add_offset(%iter_262, %236) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(6,0)">) -> !cute.int_tuple<"(?{div=2},?{div=4})">
      %view_264 = cute.make_view(%tup_263) : !cute.coord_tensor<"(?{div=2},?{div=4})", "():()">
      %iter_265 = cute.get_iter(%view_264) : !cute.coord_tensor<"(?{div=2},?{div=4})", "():()">
      %e0_266, %e1_267 = cute.get_leaves(%iter_265) : !cute.int_tuple<"(?{div=2},?{div=4})">
      %coord_268 = cute.make_coord(%e0_266, %e1_267) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"?{div=4}">) -> !cute.coord<"(?{div=2},?{div=4})">
      %coord_269 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %237:2 = cute.get_scalars(%coord_268) : !cute.coord<"(?{div=2},?{div=4})">
      %238:2 = cute.get_scalars(%coord_269) : !cute.coord<"(?,?)">
      %true_270 = arith.constant true
      %239 = arith.cmpi slt, %237#0, %238#0 : i32
      %240 = arith.andi %true_270, %239 : i1
      %241 = arith.cmpi slt, %237#1, %238#1 : i32
      %242 = arith.andi %240, %241 : i1
      %243 = arith.extui %242 : i1 to i8
      %244 = cute.static : !cute.coord<"24">
      cute.memref.store(%rmem, %244, %243) : (!memref_rmem_i8_, !cute.coord<"24">, i8) -> ()
      %245 = cute.static : !cute.int_tuple<"(6,1)">
      %iter_271 = cute.get_iter(%view_48) : !cute.coord_tensor<"(?{div=16},?{div=4})", "((4,16)):((1@1,1@0))">
      %tup_272 = cute.add_offset(%iter_271, %245) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(6,1)">) -> !cute.int_tuple<"(?{div=2},?)">
      %view_273 = cute.make_view(%tup_272) : !cute.coord_tensor<"(?{div=2},?)", "():()">
      %iter_274 = cute.get_iter(%view_273) : !cute.coord_tensor<"(?{div=2},?)", "():()">
      %e0_275, %e1_276 = cute.get_leaves(%iter_274) : !cute.int_tuple<"(?{div=2},?)">
      %coord_277 = cute.make_coord(%e0_275, %e1_276) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"?">) -> !cute.coord<"(?{div=2},?)">
      %coord_278 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %246:2 = cute.get_scalars(%coord_277) : !cute.coord<"(?{div=2},?)">
      %247:2 = cute.get_scalars(%coord_278) : !cute.coord<"(?,?)">
      %true_279 = arith.constant true
      %248 = arith.cmpi slt, %246#0, %247#0 : i32
      %249 = arith.andi %true_279, %248 : i1
      %250 = arith.cmpi slt, %246#1, %247#1 : i32
      %251 = arith.andi %249, %250 : i1
      %252 = arith.extui %251 : i1 to i8
      %253 = cute.static : !cute.coord<"25">
      cute.memref.store(%rmem, %253, %252) : (!memref_rmem_i8_, !cute.coord<"25">, i8) -> ()
      %254 = cute.static : !cute.int_tuple<"(6,2)">
      %iter_280 = cute.get_iter(%view_48) : !cute.coord_tensor<"(?{div=16},?{div=4})", "((4,16)):((1@1,1@0))">
      %tup_281 = cute.add_offset(%iter_280, %254) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(6,2)">) -> !cute.int_tuple<"(?{div=2},?{div=2})">
      %view_282 = cute.make_view(%tup_281) : !cute.coord_tensor<"(?{div=2},?{div=2})", "():()">
      %iter_283 = cute.get_iter(%view_282) : !cute.coord_tensor<"(?{div=2},?{div=2})", "():()">
      %e0_284, %e1_285 = cute.get_leaves(%iter_283) : !cute.int_tuple<"(?{div=2},?{div=2})">
      %coord_286 = cute.make_coord(%e0_284, %e1_285) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"?{div=2}">) -> !cute.coord<"(?{div=2},?{div=2})">
      %coord_287 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %255:2 = cute.get_scalars(%coord_286) : !cute.coord<"(?{div=2},?{div=2})">
      %256:2 = cute.get_scalars(%coord_287) : !cute.coord<"(?,?)">
      %true_288 = arith.constant true
      %257 = arith.cmpi slt, %255#0, %256#0 : i32
      %258 = arith.andi %true_288, %257 : i1
      %259 = arith.cmpi slt, %255#1, %256#1 : i32
      %260 = arith.andi %258, %259 : i1
      %261 = arith.extui %260 : i1 to i8
      %262 = cute.static : !cute.coord<"26">
      cute.memref.store(%rmem, %262, %261) : (!memref_rmem_i8_, !cute.coord<"26">, i8) -> ()
      %263 = cute.static : !cute.int_tuple<"(6,3)">
      %iter_289 = cute.get_iter(%view_48) : !cute.coord_tensor<"(?{div=16},?{div=4})", "((4,16)):((1@1,1@0))">
      %tup_290 = cute.add_offset(%iter_289, %263) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(6,3)">) -> !cute.int_tuple<"(?{div=2},?)">
      %view_291 = cute.make_view(%tup_290) : !cute.coord_tensor<"(?{div=2},?)", "():()">
      %iter_292 = cute.get_iter(%view_291) : !cute.coord_tensor<"(?{div=2},?)", "():()">
      %e0_293, %e1_294 = cute.get_leaves(%iter_292) : !cute.int_tuple<"(?{div=2},?)">
      %coord_295 = cute.make_coord(%e0_293, %e1_294) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"?">) -> !cute.coord<"(?{div=2},?)">
      %coord_296 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %264:2 = cute.get_scalars(%coord_295) : !cute.coord<"(?{div=2},?)">
      %265:2 = cute.get_scalars(%coord_296) : !cute.coord<"(?,?)">
      %true_297 = arith.constant true
      %266 = arith.cmpi slt, %264#0, %265#0 : i32
      %267 = arith.andi %true_297, %266 : i1
      %268 = arith.cmpi slt, %264#1, %265#1 : i32
      %269 = arith.andi %267, %268 : i1
      %270 = arith.extui %269 : i1 to i8
      %271 = cute.static : !cute.coord<"27">
      cute.memref.store(%rmem, %271, %270) : (!memref_rmem_i8_, !cute.coord<"27">, i8) -> ()
      %272 = cute.static : !cute.int_tuple<"(7,0)">
      %iter_298 = cute.get_iter(%view_48) : !cute.coord_tensor<"(?{div=16},?{div=4})", "((4,16)):((1@1,1@0))">
      %tup_299 = cute.add_offset(%iter_298, %272) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(7,0)">) -> !cute.int_tuple<"(?,?{div=4})">
      %view_300 = cute.make_view(%tup_299) : !cute.coord_tensor<"(?,?{div=4})", "():()">
      %iter_301 = cute.get_iter(%view_300) : !cute.coord_tensor<"(?,?{div=4})", "():()">
      %e0_302, %e1_303 = cute.get_leaves(%iter_301) : !cute.int_tuple<"(?,?{div=4})">
      %coord_304 = cute.make_coord(%e0_302, %e1_303) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=4}">) -> !cute.coord<"(?,?{div=4})">
      %coord_305 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %273:2 = cute.get_scalars(%coord_304) : !cute.coord<"(?,?{div=4})">
      %274:2 = cute.get_scalars(%coord_305) : !cute.coord<"(?,?)">
      %true_306 = arith.constant true
      %275 = arith.cmpi slt, %273#0, %274#0 : i32
      %276 = arith.andi %true_306, %275 : i1
      %277 = arith.cmpi slt, %273#1, %274#1 : i32
      %278 = arith.andi %276, %277 : i1
      %279 = arith.extui %278 : i1 to i8
      %280 = cute.static : !cute.coord<"28">
      cute.memref.store(%rmem, %280, %279) : (!memref_rmem_i8_, !cute.coord<"28">, i8) -> ()
      %281 = cute.static : !cute.int_tuple<"(7,1)">
      %iter_307 = cute.get_iter(%view_48) : !cute.coord_tensor<"(?{div=16},?{div=4})", "((4,16)):((1@1,1@0))">
      %tup_308 = cute.add_offset(%iter_307, %281) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(7,1)">) -> !cute.int_tuple<"(?,?)">
      %view_309 = cute.make_view(%tup_308) : !cute.coord_tensor<"(?,?)", "():()">
      %iter_310 = cute.get_iter(%view_309) : !cute.coord_tensor<"(?,?)", "():()">
      %e0_311, %e1_312 = cute.get_leaves(%iter_310) : !cute.int_tuple<"(?,?)">
      %coord_313 = cute.make_coord(%e0_311, %e1_312) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
      %coord_314 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %282:2 = cute.get_scalars(%coord_313) : !cute.coord<"(?,?)">
      %283:2 = cute.get_scalars(%coord_314) : !cute.coord<"(?,?)">
      %true_315 = arith.constant true
      %284 = arith.cmpi slt, %282#0, %283#0 : i32
      %285 = arith.andi %true_315, %284 : i1
      %286 = arith.cmpi slt, %282#1, %283#1 : i32
      %287 = arith.andi %285, %286 : i1
      %288 = arith.extui %287 : i1 to i8
      %289 = cute.static : !cute.coord<"29">
      cute.memref.store(%rmem, %289, %288) : (!memref_rmem_i8_, !cute.coord<"29">, i8) -> ()
      %290 = cute.static : !cute.int_tuple<"(7,2)">
      %iter_316 = cute.get_iter(%view_48) : !cute.coord_tensor<"(?{div=16},?{div=4})", "((4,16)):((1@1,1@0))">
      %tup_317 = cute.add_offset(%iter_316, %290) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(7,2)">) -> !cute.int_tuple<"(?,?{div=2})">
      %view_318 = cute.make_view(%tup_317) : !cute.coord_tensor<"(?,?{div=2})", "():()">
      %iter_319 = cute.get_iter(%view_318) : !cute.coord_tensor<"(?,?{div=2})", "():()">
      %e0_320, %e1_321 = cute.get_leaves(%iter_319) : !cute.int_tuple<"(?,?{div=2})">
      %coord_322 = cute.make_coord(%e0_320, %e1_321) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=2}">) -> !cute.coord<"(?,?{div=2})">
      %coord_323 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %291:2 = cute.get_scalars(%coord_322) : !cute.coord<"(?,?{div=2})">
      %292:2 = cute.get_scalars(%coord_323) : !cute.coord<"(?,?)">
      %true_324 = arith.constant true
      %293 = arith.cmpi slt, %291#0, %292#0 : i32
      %294 = arith.andi %true_324, %293 : i1
      %295 = arith.cmpi slt, %291#1, %292#1 : i32
      %296 = arith.andi %294, %295 : i1
      %297 = arith.extui %296 : i1 to i8
      %298 = cute.static : !cute.coord<"30">
      cute.memref.store(%rmem, %298, %297) : (!memref_rmem_i8_, !cute.coord<"30">, i8) -> ()
      %299 = cute.static : !cute.int_tuple<"(7,3)">
      %iter_325 = cute.get_iter(%view_48) : !cute.coord_tensor<"(?{div=16},?{div=4})", "((4,16)):((1@1,1@0))">
      %tup_326 = cute.add_offset(%iter_325, %299) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(7,3)">) -> !cute.int_tuple<"(?,?)">
      %view_327 = cute.make_view(%tup_326) : !cute.coord_tensor<"(?,?)", "():()">
      %iter_328 = cute.get_iter(%view_327) : !cute.coord_tensor<"(?,?)", "():()">
      %e0_329, %e1_330 = cute.get_leaves(%iter_328) : !cute.int_tuple<"(?,?)">
      %coord_331 = cute.make_coord(%e0_329, %e1_330) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
      %coord_332 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %300:2 = cute.get_scalars(%coord_331) : !cute.coord<"(?,?)">
      %301:2 = cute.get_scalars(%coord_332) : !cute.coord<"(?,?)">
      %true_333 = arith.constant true
      %302 = arith.cmpi slt, %300#0, %301#0 : i32
      %303 = arith.andi %true_333, %302 : i1
      %304 = arith.cmpi slt, %300#1, %301#1 : i32
      %305 = arith.andi %303, %304 : i1
      %306 = arith.extui %305 : i1 to i8
      %307 = cute.static : !cute.coord<"31">
      cute.memref.store(%rmem, %307, %306) : (!memref_rmem_i8_, !cute.coord<"31">, i8) -> ()
      %308 = cute.static : !cute.int_tuple<"(8,0)">
      %iter_334 = cute.get_iter(%view_48) : !cute.coord_tensor<"(?{div=16},?{div=4})", "((4,16)):((1@1,1@0))">
      %tup_335 = cute.add_offset(%iter_334, %308) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(8,0)">) -> !cute.int_tuple<"(?{div=8},?{div=4})">
      %view_336 = cute.make_view(%tup_335) : !cute.coord_tensor<"(?{div=8},?{div=4})", "():()">
      %iter_337 = cute.get_iter(%view_336) : !cute.coord_tensor<"(?{div=8},?{div=4})", "():()">
      %e0_338, %e1_339 = cute.get_leaves(%iter_337) : !cute.int_tuple<"(?{div=8},?{div=4})">
      %coord_340 = cute.make_coord(%e0_338, %e1_339) : (!cute.int_tuple<"?{div=8}">, !cute.int_tuple<"?{div=4}">) -> !cute.coord<"(?{div=8},?{div=4})">
      %coord_341 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %309:2 = cute.get_scalars(%coord_340) : !cute.coord<"(?{div=8},?{div=4})">
      %310:2 = cute.get_scalars(%coord_341) : !cute.coord<"(?,?)">
      %true_342 = arith.constant true
      %311 = arith.cmpi slt, %309#0, %310#0 : i32
      %312 = arith.andi %true_342, %311 : i1
      %313 = arith.cmpi slt, %309#1, %310#1 : i32
      %314 = arith.andi %312, %313 : i1
      %315 = arith.extui %314 : i1 to i8
      %316 = cute.static : !cute.coord<"32">
      cute.memref.store(%rmem, %316, %315) : (!memref_rmem_i8_, !cute.coord<"32">, i8) -> ()
      %317 = cute.static : !cute.int_tuple<"(8,1)">
      %iter_343 = cute.get_iter(%view_48) : !cute.coord_tensor<"(?{div=16},?{div=4})", "((4,16)):((1@1,1@0))">
      %tup_344 = cute.add_offset(%iter_343, %317) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(8,1)">) -> !cute.int_tuple<"(?{div=8},?)">
      %view_345 = cute.make_view(%tup_344) : !cute.coord_tensor<"(?{div=8},?)", "():()">
      %iter_346 = cute.get_iter(%view_345) : !cute.coord_tensor<"(?{div=8},?)", "():()">
      %e0_347, %e1_348 = cute.get_leaves(%iter_346) : !cute.int_tuple<"(?{div=8},?)">
      %coord_349 = cute.make_coord(%e0_347, %e1_348) : (!cute.int_tuple<"?{div=8}">, !cute.int_tuple<"?">) -> !cute.coord<"(?{div=8},?)">
      %coord_350 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %318:2 = cute.get_scalars(%coord_349) : !cute.coord<"(?{div=8},?)">
      %319:2 = cute.get_scalars(%coord_350) : !cute.coord<"(?,?)">
      %true_351 = arith.constant true
      %320 = arith.cmpi slt, %318#0, %319#0 : i32
      %321 = arith.andi %true_351, %320 : i1
      %322 = arith.cmpi slt, %318#1, %319#1 : i32
      %323 = arith.andi %321, %322 : i1
      %324 = arith.extui %323 : i1 to i8
      %325 = cute.static : !cute.coord<"33">
      cute.memref.store(%rmem, %325, %324) : (!memref_rmem_i8_, !cute.coord<"33">, i8) -> ()
      %326 = cute.static : !cute.int_tuple<"(8,2)">
      %iter_352 = cute.get_iter(%view_48) : !cute.coord_tensor<"(?{div=16},?{div=4})", "((4,16)):((1@1,1@0))">
      %tup_353 = cute.add_offset(%iter_352, %326) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(8,2)">) -> !cute.int_tuple<"(?{div=8},?{div=2})">
      %view_354 = cute.make_view(%tup_353) : !cute.coord_tensor<"(?{div=8},?{div=2})", "():()">
      %iter_355 = cute.get_iter(%view_354) : !cute.coord_tensor<"(?{div=8},?{div=2})", "():()">
      %e0_356, %e1_357 = cute.get_leaves(%iter_355) : !cute.int_tuple<"(?{div=8},?{div=2})">
      %coord_358 = cute.make_coord(%e0_356, %e1_357) : (!cute.int_tuple<"?{div=8}">, !cute.int_tuple<"?{div=2}">) -> !cute.coord<"(?{div=8},?{div=2})">
      %coord_359 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %327:2 = cute.get_scalars(%coord_358) : !cute.coord<"(?{div=8},?{div=2})">
      %328:2 = cute.get_scalars(%coord_359) : !cute.coord<"(?,?)">
      %true_360 = arith.constant true
      %329 = arith.cmpi slt, %327#0, %328#0 : i32
      %330 = arith.andi %true_360, %329 : i1
      %331 = arith.cmpi slt, %327#1, %328#1 : i32
      %332 = arith.andi %330, %331 : i1
      %333 = arith.extui %332 : i1 to i8
      %334 = cute.static : !cute.coord<"34">
      cute.memref.store(%rmem, %334, %333) : (!memref_rmem_i8_, !cute.coord<"34">, i8) -> ()
      %335 = cute.static : !cute.int_tuple<"(8,3)">
      %iter_361 = cute.get_iter(%view_48) : !cute.coord_tensor<"(?{div=16},?{div=4})", "((4,16)):((1@1,1@0))">
      %tup_362 = cute.add_offset(%iter_361, %335) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(8,3)">) -> !cute.int_tuple<"(?{div=8},?)">
      %view_363 = cute.make_view(%tup_362) : !cute.coord_tensor<"(?{div=8},?)", "():()">
      %iter_364 = cute.get_iter(%view_363) : !cute.coord_tensor<"(?{div=8},?)", "():()">
      %e0_365, %e1_366 = cute.get_leaves(%iter_364) : !cute.int_tuple<"(?{div=8},?)">
      %coord_367 = cute.make_coord(%e0_365, %e1_366) : (!cute.int_tuple<"?{div=8}">, !cute.int_tuple<"?">) -> !cute.coord<"(?{div=8},?)">
      %coord_368 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %336:2 = cute.get_scalars(%coord_367) : !cute.coord<"(?{div=8},?)">
      %337:2 = cute.get_scalars(%coord_368) : !cute.coord<"(?,?)">
      %true_369 = arith.constant true
      %338 = arith.cmpi slt, %336#0, %337#0 : i32
      %339 = arith.andi %true_369, %338 : i1
      %340 = arith.cmpi slt, %336#1, %337#1 : i32
      %341 = arith.andi %339, %340 : i1
      %342 = arith.extui %341 : i1 to i8
      %343 = cute.static : !cute.coord<"35">
      cute.memref.store(%rmem, %343, %342) : (!memref_rmem_i8_, !cute.coord<"35">, i8) -> ()
      %344 = cute.static : !cute.int_tuple<"(9,0)">
      %iter_370 = cute.get_iter(%view_48) : !cute.coord_tensor<"(?{div=16},?{div=4})", "((4,16)):((1@1,1@0))">
      %tup_371 = cute.add_offset(%iter_370, %344) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(9,0)">) -> !cute.int_tuple<"(?,?{div=4})">
      %view_372 = cute.make_view(%tup_371) : !cute.coord_tensor<"(?,?{div=4})", "():()">
      %iter_373 = cute.get_iter(%view_372) : !cute.coord_tensor<"(?,?{div=4})", "():()">
      %e0_374, %e1_375 = cute.get_leaves(%iter_373) : !cute.int_tuple<"(?,?{div=4})">
      %coord_376 = cute.make_coord(%e0_374, %e1_375) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=4}">) -> !cute.coord<"(?,?{div=4})">
      %coord_377 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %345:2 = cute.get_scalars(%coord_376) : !cute.coord<"(?,?{div=4})">
      %346:2 = cute.get_scalars(%coord_377) : !cute.coord<"(?,?)">
      %true_378 = arith.constant true
      %347 = arith.cmpi slt, %345#0, %346#0 : i32
      %348 = arith.andi %true_378, %347 : i1
      %349 = arith.cmpi slt, %345#1, %346#1 : i32
      %350 = arith.andi %348, %349 : i1
      %351 = arith.extui %350 : i1 to i8
      %352 = cute.static : !cute.coord<"36">
      cute.memref.store(%rmem, %352, %351) : (!memref_rmem_i8_, !cute.coord<"36">, i8) -> ()
      %353 = cute.static : !cute.int_tuple<"(9,1)">
      %iter_379 = cute.get_iter(%view_48) : !cute.coord_tensor<"(?{div=16},?{div=4})", "((4,16)):((1@1,1@0))">
      %tup_380 = cute.add_offset(%iter_379, %353) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(9,1)">) -> !cute.int_tuple<"(?,?)">
      %view_381 = cute.make_view(%tup_380) : !cute.coord_tensor<"(?,?)", "():()">
      %iter_382 = cute.get_iter(%view_381) : !cute.coord_tensor<"(?,?)", "():()">
      %e0_383, %e1_384 = cute.get_leaves(%iter_382) : !cute.int_tuple<"(?,?)">
      %coord_385 = cute.make_coord(%e0_383, %e1_384) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
      %coord_386 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %354:2 = cute.get_scalars(%coord_385) : !cute.coord<"(?,?)">
      %355:2 = cute.get_scalars(%coord_386) : !cute.coord<"(?,?)">
      %true_387 = arith.constant true
      %356 = arith.cmpi slt, %354#0, %355#0 : i32
      %357 = arith.andi %true_387, %356 : i1
      %358 = arith.cmpi slt, %354#1, %355#1 : i32
      %359 = arith.andi %357, %358 : i1
      %360 = arith.extui %359 : i1 to i8
      %361 = cute.static : !cute.coord<"37">
      cute.memref.store(%rmem, %361, %360) : (!memref_rmem_i8_, !cute.coord<"37">, i8) -> ()
      %362 = cute.static : !cute.int_tuple<"(9,2)">
      %iter_388 = cute.get_iter(%view_48) : !cute.coord_tensor<"(?{div=16},?{div=4})", "((4,16)):((1@1,1@0))">
      %tup_389 = cute.add_offset(%iter_388, %362) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(9,2)">) -> !cute.int_tuple<"(?,?{div=2})">
      %view_390 = cute.make_view(%tup_389) : !cute.coord_tensor<"(?,?{div=2})", "():()">
      %iter_391 = cute.get_iter(%view_390) : !cute.coord_tensor<"(?,?{div=2})", "():()">
      %e0_392, %e1_393 = cute.get_leaves(%iter_391) : !cute.int_tuple<"(?,?{div=2})">
      %coord_394 = cute.make_coord(%e0_392, %e1_393) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=2}">) -> !cute.coord<"(?,?{div=2})">
      %coord_395 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %363:2 = cute.get_scalars(%coord_394) : !cute.coord<"(?,?{div=2})">
      %364:2 = cute.get_scalars(%coord_395) : !cute.coord<"(?,?)">
      %true_396 = arith.constant true
      %365 = arith.cmpi slt, %363#0, %364#0 : i32
      %366 = arith.andi %true_396, %365 : i1
      %367 = arith.cmpi slt, %363#1, %364#1 : i32
      %368 = arith.andi %366, %367 : i1
      %369 = arith.extui %368 : i1 to i8
      %370 = cute.static : !cute.coord<"38">
      cute.memref.store(%rmem, %370, %369) : (!memref_rmem_i8_, !cute.coord<"38">, i8) -> ()
      %371 = cute.static : !cute.int_tuple<"(9,3)">
      %iter_397 = cute.get_iter(%view_48) : !cute.coord_tensor<"(?{div=16},?{div=4})", "((4,16)):((1@1,1@0))">
      %tup_398 = cute.add_offset(%iter_397, %371) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(9,3)">) -> !cute.int_tuple<"(?,?)">
      %view_399 = cute.make_view(%tup_398) : !cute.coord_tensor<"(?,?)", "():()">
      %iter_400 = cute.get_iter(%view_399) : !cute.coord_tensor<"(?,?)", "():()">
      %e0_401, %e1_402 = cute.get_leaves(%iter_400) : !cute.int_tuple<"(?,?)">
      %coord_403 = cute.make_coord(%e0_401, %e1_402) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
      %coord_404 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %372:2 = cute.get_scalars(%coord_403) : !cute.coord<"(?,?)">
      %373:2 = cute.get_scalars(%coord_404) : !cute.coord<"(?,?)">
      %true_405 = arith.constant true
      %374 = arith.cmpi slt, %372#0, %373#0 : i32
      %375 = arith.andi %true_405, %374 : i1
      %376 = arith.cmpi slt, %372#1, %373#1 : i32
      %377 = arith.andi %375, %376 : i1
      %378 = arith.extui %377 : i1 to i8
      %379 = cute.static : !cute.coord<"39">
      cute.memref.store(%rmem, %379, %378) : (!memref_rmem_i8_, !cute.coord<"39">, i8) -> ()
      %380 = cute.static : !cute.int_tuple<"(10,0)">
      %iter_406 = cute.get_iter(%view_48) : !cute.coord_tensor<"(?{div=16},?{div=4})", "((4,16)):((1@1,1@0))">
      %tup_407 = cute.add_offset(%iter_406, %380) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(10,0)">) -> !cute.int_tuple<"(?{div=2},?{div=4})">
      %view_408 = cute.make_view(%tup_407) : !cute.coord_tensor<"(?{div=2},?{div=4})", "():()">
      %iter_409 = cute.get_iter(%view_408) : !cute.coord_tensor<"(?{div=2},?{div=4})", "():()">
      %e0_410, %e1_411 = cute.get_leaves(%iter_409) : !cute.int_tuple<"(?{div=2},?{div=4})">
      %coord_412 = cute.make_coord(%e0_410, %e1_411) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"?{div=4}">) -> !cute.coord<"(?{div=2},?{div=4})">
      %coord_413 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %381:2 = cute.get_scalars(%coord_412) : !cute.coord<"(?{div=2},?{div=4})">
      %382:2 = cute.get_scalars(%coord_413) : !cute.coord<"(?,?)">
      %true_414 = arith.constant true
      %383 = arith.cmpi slt, %381#0, %382#0 : i32
      %384 = arith.andi %true_414, %383 : i1
      %385 = arith.cmpi slt, %381#1, %382#1 : i32
      %386 = arith.andi %384, %385 : i1
      %387 = arith.extui %386 : i1 to i8
      %388 = cute.static : !cute.coord<"40">
      cute.memref.store(%rmem, %388, %387) : (!memref_rmem_i8_, !cute.coord<"40">, i8) -> ()
      %389 = cute.static : !cute.int_tuple<"(10,1)">
      %iter_415 = cute.get_iter(%view_48) : !cute.coord_tensor<"(?{div=16},?{div=4})", "((4,16)):((1@1,1@0))">
      %tup_416 = cute.add_offset(%iter_415, %389) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(10,1)">) -> !cute.int_tuple<"(?{div=2},?)">
      %view_417 = cute.make_view(%tup_416) : !cute.coord_tensor<"(?{div=2},?)", "():()">
      %iter_418 = cute.get_iter(%view_417) : !cute.coord_tensor<"(?{div=2},?)", "():()">
      %e0_419, %e1_420 = cute.get_leaves(%iter_418) : !cute.int_tuple<"(?{div=2},?)">
      %coord_421 = cute.make_coord(%e0_419, %e1_420) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"?">) -> !cute.coord<"(?{div=2},?)">
      %coord_422 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %390:2 = cute.get_scalars(%coord_421) : !cute.coord<"(?{div=2},?)">
      %391:2 = cute.get_scalars(%coord_422) : !cute.coord<"(?,?)">
      %true_423 = arith.constant true
      %392 = arith.cmpi slt, %390#0, %391#0 : i32
      %393 = arith.andi %true_423, %392 : i1
      %394 = arith.cmpi slt, %390#1, %391#1 : i32
      %395 = arith.andi %393, %394 : i1
      %396 = arith.extui %395 : i1 to i8
      %397 = cute.static : !cute.coord<"41">
      cute.memref.store(%rmem, %397, %396) : (!memref_rmem_i8_, !cute.coord<"41">, i8) -> ()
      %398 = cute.static : !cute.int_tuple<"(10,2)">
      %iter_424 = cute.get_iter(%view_48) : !cute.coord_tensor<"(?{div=16},?{div=4})", "((4,16)):((1@1,1@0))">
      %tup_425 = cute.add_offset(%iter_424, %398) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(10,2)">) -> !cute.int_tuple<"(?{div=2},?{div=2})">
      %view_426 = cute.make_view(%tup_425) : !cute.coord_tensor<"(?{div=2},?{div=2})", "():()">
      %iter_427 = cute.get_iter(%view_426) : !cute.coord_tensor<"(?{div=2},?{div=2})", "():()">
      %e0_428, %e1_429 = cute.get_leaves(%iter_427) : !cute.int_tuple<"(?{div=2},?{div=2})">
      %coord_430 = cute.make_coord(%e0_428, %e1_429) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"?{div=2}">) -> !cute.coord<"(?{div=2},?{div=2})">
      %coord_431 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %399:2 = cute.get_scalars(%coord_430) : !cute.coord<"(?{div=2},?{div=2})">
      %400:2 = cute.get_scalars(%coord_431) : !cute.coord<"(?,?)">
      %true_432 = arith.constant true
      %401 = arith.cmpi slt, %399#0, %400#0 : i32
      %402 = arith.andi %true_432, %401 : i1
      %403 = arith.cmpi slt, %399#1, %400#1 : i32
      %404 = arith.andi %402, %403 : i1
      %405 = arith.extui %404 : i1 to i8
      %406 = cute.static : !cute.coord<"42">
      cute.memref.store(%rmem, %406, %405) : (!memref_rmem_i8_, !cute.coord<"42">, i8) -> ()
      %407 = cute.static : !cute.int_tuple<"(10,3)">
      %iter_433 = cute.get_iter(%view_48) : !cute.coord_tensor<"(?{div=16},?{div=4})", "((4,16)):((1@1,1@0))">
      %tup_434 = cute.add_offset(%iter_433, %407) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(10,3)">) -> !cute.int_tuple<"(?{div=2},?)">
      %view_435 = cute.make_view(%tup_434) : !cute.coord_tensor<"(?{div=2},?)", "():()">
      %iter_436 = cute.get_iter(%view_435) : !cute.coord_tensor<"(?{div=2},?)", "():()">
      %e0_437, %e1_438 = cute.get_leaves(%iter_436) : !cute.int_tuple<"(?{div=2},?)">
      %coord_439 = cute.make_coord(%e0_437, %e1_438) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"?">) -> !cute.coord<"(?{div=2},?)">
      %coord_440 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %408:2 = cute.get_scalars(%coord_439) : !cute.coord<"(?{div=2},?)">
      %409:2 = cute.get_scalars(%coord_440) : !cute.coord<"(?,?)">
      %true_441 = arith.constant true
      %410 = arith.cmpi slt, %408#0, %409#0 : i32
      %411 = arith.andi %true_441, %410 : i1
      %412 = arith.cmpi slt, %408#1, %409#1 : i32
      %413 = arith.andi %411, %412 : i1
      %414 = arith.extui %413 : i1 to i8
      %415 = cute.static : !cute.coord<"43">
      cute.memref.store(%rmem, %415, %414) : (!memref_rmem_i8_, !cute.coord<"43">, i8) -> ()
      %416 = cute.static : !cute.int_tuple<"(11,0)">
      %iter_442 = cute.get_iter(%view_48) : !cute.coord_tensor<"(?{div=16},?{div=4})", "((4,16)):((1@1,1@0))">
      %tup_443 = cute.add_offset(%iter_442, %416) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(11,0)">) -> !cute.int_tuple<"(?,?{div=4})">
      %view_444 = cute.make_view(%tup_443) : !cute.coord_tensor<"(?,?{div=4})", "():()">
      %iter_445 = cute.get_iter(%view_444) : !cute.coord_tensor<"(?,?{div=4})", "():()">
      %e0_446, %e1_447 = cute.get_leaves(%iter_445) : !cute.int_tuple<"(?,?{div=4})">
      %coord_448 = cute.make_coord(%e0_446, %e1_447) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=4}">) -> !cute.coord<"(?,?{div=4})">
      %coord_449 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %417:2 = cute.get_scalars(%coord_448) : !cute.coord<"(?,?{div=4})">
      %418:2 = cute.get_scalars(%coord_449) : !cute.coord<"(?,?)">
      %true_450 = arith.constant true
      %419 = arith.cmpi slt, %417#0, %418#0 : i32
      %420 = arith.andi %true_450, %419 : i1
      %421 = arith.cmpi slt, %417#1, %418#1 : i32
      %422 = arith.andi %420, %421 : i1
      %423 = arith.extui %422 : i1 to i8
      %424 = cute.static : !cute.coord<"44">
      cute.memref.store(%rmem, %424, %423) : (!memref_rmem_i8_, !cute.coord<"44">, i8) -> ()
      %425 = cute.static : !cute.int_tuple<"(11,1)">
      %iter_451 = cute.get_iter(%view_48) : !cute.coord_tensor<"(?{div=16},?{div=4})", "((4,16)):((1@1,1@0))">
      %tup_452 = cute.add_offset(%iter_451, %425) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(11,1)">) -> !cute.int_tuple<"(?,?)">
      %view_453 = cute.make_view(%tup_452) : !cute.coord_tensor<"(?,?)", "():()">
      %iter_454 = cute.get_iter(%view_453) : !cute.coord_tensor<"(?,?)", "():()">
      %e0_455, %e1_456 = cute.get_leaves(%iter_454) : !cute.int_tuple<"(?,?)">
      %coord_457 = cute.make_coord(%e0_455, %e1_456) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
      %coord_458 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %426:2 = cute.get_scalars(%coord_457) : !cute.coord<"(?,?)">
      %427:2 = cute.get_scalars(%coord_458) : !cute.coord<"(?,?)">
      %true_459 = arith.constant true
      %428 = arith.cmpi slt, %426#0, %427#0 : i32
      %429 = arith.andi %true_459, %428 : i1
      %430 = arith.cmpi slt, %426#1, %427#1 : i32
      %431 = arith.andi %429, %430 : i1
      %432 = arith.extui %431 : i1 to i8
      %433 = cute.static : !cute.coord<"45">
      cute.memref.store(%rmem, %433, %432) : (!memref_rmem_i8_, !cute.coord<"45">, i8) -> ()
      %434 = cute.static : !cute.int_tuple<"(11,2)">
      %iter_460 = cute.get_iter(%view_48) : !cute.coord_tensor<"(?{div=16},?{div=4})", "((4,16)):((1@1,1@0))">
      %tup_461 = cute.add_offset(%iter_460, %434) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(11,2)">) -> !cute.int_tuple<"(?,?{div=2})">
      %view_462 = cute.make_view(%tup_461) : !cute.coord_tensor<"(?,?{div=2})", "():()">
      %iter_463 = cute.get_iter(%view_462) : !cute.coord_tensor<"(?,?{div=2})", "():()">
      %e0_464, %e1_465 = cute.get_leaves(%iter_463) : !cute.int_tuple<"(?,?{div=2})">
      %coord_466 = cute.make_coord(%e0_464, %e1_465) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=2}">) -> !cute.coord<"(?,?{div=2})">
      %coord_467 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %435:2 = cute.get_scalars(%coord_466) : !cute.coord<"(?,?{div=2})">
      %436:2 = cute.get_scalars(%coord_467) : !cute.coord<"(?,?)">
      %true_468 = arith.constant true
      %437 = arith.cmpi slt, %435#0, %436#0 : i32
      %438 = arith.andi %true_468, %437 : i1
      %439 = arith.cmpi slt, %435#1, %436#1 : i32
      %440 = arith.andi %438, %439 : i1
      %441 = arith.extui %440 : i1 to i8
      %442 = cute.static : !cute.coord<"46">
      cute.memref.store(%rmem, %442, %441) : (!memref_rmem_i8_, !cute.coord<"46">, i8) -> ()
      %443 = cute.static : !cute.int_tuple<"(11,3)">
      %iter_469 = cute.get_iter(%view_48) : !cute.coord_tensor<"(?{div=16},?{div=4})", "((4,16)):((1@1,1@0))">
      %tup_470 = cute.add_offset(%iter_469, %443) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(11,3)">) -> !cute.int_tuple<"(?,?)">
      %view_471 = cute.make_view(%tup_470) : !cute.coord_tensor<"(?,?)", "():()">
      %iter_472 = cute.get_iter(%view_471) : !cute.coord_tensor<"(?,?)", "():()">
      %e0_473, %e1_474 = cute.get_leaves(%iter_472) : !cute.int_tuple<"(?,?)">
      %coord_475 = cute.make_coord(%e0_473, %e1_474) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
      %coord_476 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %444:2 = cute.get_scalars(%coord_475) : !cute.coord<"(?,?)">
      %445:2 = cute.get_scalars(%coord_476) : !cute.coord<"(?,?)">
      %true_477 = arith.constant true
      %446 = arith.cmpi slt, %444#0, %445#0 : i32
      %447 = arith.andi %true_477, %446 : i1
      %448 = arith.cmpi slt, %444#1, %445#1 : i32
      %449 = arith.andi %447, %448 : i1
      %450 = arith.extui %449 : i1 to i8
      %451 = cute.static : !cute.coord<"47">
      cute.memref.store(%rmem, %451, %450) : (!memref_rmem_i8_, !cute.coord<"47">, i8) -> ()
      %452 = cute.static : !cute.int_tuple<"(12,0)">
      %iter_478 = cute.get_iter(%view_48) : !cute.coord_tensor<"(?{div=16},?{div=4})", "((4,16)):((1@1,1@0))">
      %tup_479 = cute.add_offset(%iter_478, %452) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(12,0)">) -> !cute.int_tuple<"(?{div=4},?{div=4})">
      %view_480 = cute.make_view(%tup_479) : !cute.coord_tensor<"(?{div=4},?{div=4})", "():()">
      %iter_481 = cute.get_iter(%view_480) : !cute.coord_tensor<"(?{div=4},?{div=4})", "():()">
      %e0_482, %e1_483 = cute.get_leaves(%iter_481) : !cute.int_tuple<"(?{div=4},?{div=4})">
      %coord_484 = cute.make_coord(%e0_482, %e1_483) : (!cute.int_tuple<"?{div=4}">, !cute.int_tuple<"?{div=4}">) -> !cute.coord<"(?{div=4},?{div=4})">
      %coord_485 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %453:2 = cute.get_scalars(%coord_484) : !cute.coord<"(?{div=4},?{div=4})">
      %454:2 = cute.get_scalars(%coord_485) : !cute.coord<"(?,?)">
      %true_486 = arith.constant true
      %455 = arith.cmpi slt, %453#0, %454#0 : i32
      %456 = arith.andi %true_486, %455 : i1
      %457 = arith.cmpi slt, %453#1, %454#1 : i32
      %458 = arith.andi %456, %457 : i1
      %459 = arith.extui %458 : i1 to i8
      %460 = cute.static : !cute.coord<"48">
      cute.memref.store(%rmem, %460, %459) : (!memref_rmem_i8_, !cute.coord<"48">, i8) -> ()
      %461 = cute.static : !cute.int_tuple<"(12,1)">
      %iter_487 = cute.get_iter(%view_48) : !cute.coord_tensor<"(?{div=16},?{div=4})", "((4,16)):((1@1,1@0))">
      %tup_488 = cute.add_offset(%iter_487, %461) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(12,1)">) -> !cute.int_tuple<"(?{div=4},?)">
      %view_489 = cute.make_view(%tup_488) : !cute.coord_tensor<"(?{div=4},?)", "():()">
      %iter_490 = cute.get_iter(%view_489) : !cute.coord_tensor<"(?{div=4},?)", "():()">
      %e0_491, %e1_492 = cute.get_leaves(%iter_490) : !cute.int_tuple<"(?{div=4},?)">
      %coord_493 = cute.make_coord(%e0_491, %e1_492) : (!cute.int_tuple<"?{div=4}">, !cute.int_tuple<"?">) -> !cute.coord<"(?{div=4},?)">
      %coord_494 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %462:2 = cute.get_scalars(%coord_493) : !cute.coord<"(?{div=4},?)">
      %463:2 = cute.get_scalars(%coord_494) : !cute.coord<"(?,?)">
      %true_495 = arith.constant true
      %464 = arith.cmpi slt, %462#0, %463#0 : i32
      %465 = arith.andi %true_495, %464 : i1
      %466 = arith.cmpi slt, %462#1, %463#1 : i32
      %467 = arith.andi %465, %466 : i1
      %468 = arith.extui %467 : i1 to i8
      %469 = cute.static : !cute.coord<"49">
      cute.memref.store(%rmem, %469, %468) : (!memref_rmem_i8_, !cute.coord<"49">, i8) -> ()
      %470 = cute.static : !cute.int_tuple<"(12,2)">
      %iter_496 = cute.get_iter(%view_48) : !cute.coord_tensor<"(?{div=16},?{div=4})", "((4,16)):((1@1,1@0))">
      %tup_497 = cute.add_offset(%iter_496, %470) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(12,2)">) -> !cute.int_tuple<"(?{div=4},?{div=2})">
      %view_498 = cute.make_view(%tup_497) : !cute.coord_tensor<"(?{div=4},?{div=2})", "():()">
      %iter_499 = cute.get_iter(%view_498) : !cute.coord_tensor<"(?{div=4},?{div=2})", "():()">
      %e0_500, %e1_501 = cute.get_leaves(%iter_499) : !cute.int_tuple<"(?{div=4},?{div=2})">
      %coord_502 = cute.make_coord(%e0_500, %e1_501) : (!cute.int_tuple<"?{div=4}">, !cute.int_tuple<"?{div=2}">) -> !cute.coord<"(?{div=4},?{div=2})">
      %coord_503 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %471:2 = cute.get_scalars(%coord_502) : !cute.coord<"(?{div=4},?{div=2})">
      %472:2 = cute.get_scalars(%coord_503) : !cute.coord<"(?,?)">
      %true_504 = arith.constant true
      %473 = arith.cmpi slt, %471#0, %472#0 : i32
      %474 = arith.andi %true_504, %473 : i1
      %475 = arith.cmpi slt, %471#1, %472#1 : i32
      %476 = arith.andi %474, %475 : i1
      %477 = arith.extui %476 : i1 to i8
      %478 = cute.static : !cute.coord<"50">
      cute.memref.store(%rmem, %478, %477) : (!memref_rmem_i8_, !cute.coord<"50">, i8) -> ()
      %479 = cute.static : !cute.int_tuple<"(12,3)">
      %iter_505 = cute.get_iter(%view_48) : !cute.coord_tensor<"(?{div=16},?{div=4})", "((4,16)):((1@1,1@0))">
      %tup_506 = cute.add_offset(%iter_505, %479) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(12,3)">) -> !cute.int_tuple<"(?{div=4},?)">
      %view_507 = cute.make_view(%tup_506) : !cute.coord_tensor<"(?{div=4},?)", "():()">
      %iter_508 = cute.get_iter(%view_507) : !cute.coord_tensor<"(?{div=4},?)", "():()">
      %e0_509, %e1_510 = cute.get_leaves(%iter_508) : !cute.int_tuple<"(?{div=4},?)">
      %coord_511 = cute.make_coord(%e0_509, %e1_510) : (!cute.int_tuple<"?{div=4}">, !cute.int_tuple<"?">) -> !cute.coord<"(?{div=4},?)">
      %coord_512 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %480:2 = cute.get_scalars(%coord_511) : !cute.coord<"(?{div=4},?)">
      %481:2 = cute.get_scalars(%coord_512) : !cute.coord<"(?,?)">
      %true_513 = arith.constant true
      %482 = arith.cmpi slt, %480#0, %481#0 : i32
      %483 = arith.andi %true_513, %482 : i1
      %484 = arith.cmpi slt, %480#1, %481#1 : i32
      %485 = arith.andi %483, %484 : i1
      %486 = arith.extui %485 : i1 to i8
      %487 = cute.static : !cute.coord<"51">
      cute.memref.store(%rmem, %487, %486) : (!memref_rmem_i8_, !cute.coord<"51">, i8) -> ()
      %488 = cute.static : !cute.int_tuple<"(13,0)">
      %iter_514 = cute.get_iter(%view_48) : !cute.coord_tensor<"(?{div=16},?{div=4})", "((4,16)):((1@1,1@0))">
      %tup_515 = cute.add_offset(%iter_514, %488) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(13,0)">) -> !cute.int_tuple<"(?,?{div=4})">
      %view_516 = cute.make_view(%tup_515) : !cute.coord_tensor<"(?,?{div=4})", "():()">
      %iter_517 = cute.get_iter(%view_516) : !cute.coord_tensor<"(?,?{div=4})", "():()">
      %e0_518, %e1_519 = cute.get_leaves(%iter_517) : !cute.int_tuple<"(?,?{div=4})">
      %coord_520 = cute.make_coord(%e0_518, %e1_519) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=4}">) -> !cute.coord<"(?,?{div=4})">
      %coord_521 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %489:2 = cute.get_scalars(%coord_520) : !cute.coord<"(?,?{div=4})">
      %490:2 = cute.get_scalars(%coord_521) : !cute.coord<"(?,?)">
      %true_522 = arith.constant true
      %491 = arith.cmpi slt, %489#0, %490#0 : i32
      %492 = arith.andi %true_522, %491 : i1
      %493 = arith.cmpi slt, %489#1, %490#1 : i32
      %494 = arith.andi %492, %493 : i1
      %495 = arith.extui %494 : i1 to i8
      %496 = cute.static : !cute.coord<"52">
      cute.memref.store(%rmem, %496, %495) : (!memref_rmem_i8_, !cute.coord<"52">, i8) -> ()
      %497 = cute.static : !cute.int_tuple<"(13,1)">
      %iter_523 = cute.get_iter(%view_48) : !cute.coord_tensor<"(?{div=16},?{div=4})", "((4,16)):((1@1,1@0))">
      %tup_524 = cute.add_offset(%iter_523, %497) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(13,1)">) -> !cute.int_tuple<"(?,?)">
      %view_525 = cute.make_view(%tup_524) : !cute.coord_tensor<"(?,?)", "():()">
      %iter_526 = cute.get_iter(%view_525) : !cute.coord_tensor<"(?,?)", "():()">
      %e0_527, %e1_528 = cute.get_leaves(%iter_526) : !cute.int_tuple<"(?,?)">
      %coord_529 = cute.make_coord(%e0_527, %e1_528) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
      %coord_530 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %498:2 = cute.get_scalars(%coord_529) : !cute.coord<"(?,?)">
      %499:2 = cute.get_scalars(%coord_530) : !cute.coord<"(?,?)">
      %true_531 = arith.constant true
      %500 = arith.cmpi slt, %498#0, %499#0 : i32
      %501 = arith.andi %true_531, %500 : i1
      %502 = arith.cmpi slt, %498#1, %499#1 : i32
      %503 = arith.andi %501, %502 : i1
      %504 = arith.extui %503 : i1 to i8
      %505 = cute.static : !cute.coord<"53">
      cute.memref.store(%rmem, %505, %504) : (!memref_rmem_i8_, !cute.coord<"53">, i8) -> ()
      %506 = cute.static : !cute.int_tuple<"(13,2)">
      %iter_532 = cute.get_iter(%view_48) : !cute.coord_tensor<"(?{div=16},?{div=4})", "((4,16)):((1@1,1@0))">
      %tup_533 = cute.add_offset(%iter_532, %506) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(13,2)">) -> !cute.int_tuple<"(?,?{div=2})">
      %view_534 = cute.make_view(%tup_533) : !cute.coord_tensor<"(?,?{div=2})", "():()">
      %iter_535 = cute.get_iter(%view_534) : !cute.coord_tensor<"(?,?{div=2})", "():()">
      %e0_536, %e1_537 = cute.get_leaves(%iter_535) : !cute.int_tuple<"(?,?{div=2})">
      %coord_538 = cute.make_coord(%e0_536, %e1_537) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=2}">) -> !cute.coord<"(?,?{div=2})">
      %coord_539 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %507:2 = cute.get_scalars(%coord_538) : !cute.coord<"(?,?{div=2})">
      %508:2 = cute.get_scalars(%coord_539) : !cute.coord<"(?,?)">
      %true_540 = arith.constant true
      %509 = arith.cmpi slt, %507#0, %508#0 : i32
      %510 = arith.andi %true_540, %509 : i1
      %511 = arith.cmpi slt, %507#1, %508#1 : i32
      %512 = arith.andi %510, %511 : i1
      %513 = arith.extui %512 : i1 to i8
      %514 = cute.static : !cute.coord<"54">
      cute.memref.store(%rmem, %514, %513) : (!memref_rmem_i8_, !cute.coord<"54">, i8) -> ()
      %515 = cute.static : !cute.int_tuple<"(13,3)">
      %iter_541 = cute.get_iter(%view_48) : !cute.coord_tensor<"(?{div=16},?{div=4})", "((4,16)):((1@1,1@0))">
      %tup_542 = cute.add_offset(%iter_541, %515) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(13,3)">) -> !cute.int_tuple<"(?,?)">
      %view_543 = cute.make_view(%tup_542) : !cute.coord_tensor<"(?,?)", "():()">
      %iter_544 = cute.get_iter(%view_543) : !cute.coord_tensor<"(?,?)", "():()">
      %e0_545, %e1_546 = cute.get_leaves(%iter_544) : !cute.int_tuple<"(?,?)">
      %coord_547 = cute.make_coord(%e0_545, %e1_546) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
      %coord_548 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %516:2 = cute.get_scalars(%coord_547) : !cute.coord<"(?,?)">
      %517:2 = cute.get_scalars(%coord_548) : !cute.coord<"(?,?)">
      %true_549 = arith.constant true
      %518 = arith.cmpi slt, %516#0, %517#0 : i32
      %519 = arith.andi %true_549, %518 : i1
      %520 = arith.cmpi slt, %516#1, %517#1 : i32
      %521 = arith.andi %519, %520 : i1
      %522 = arith.extui %521 : i1 to i8
      %523 = cute.static : !cute.coord<"55">
      cute.memref.store(%rmem, %523, %522) : (!memref_rmem_i8_, !cute.coord<"55">, i8) -> ()
      %524 = cute.static : !cute.int_tuple<"(14,0)">
      %iter_550 = cute.get_iter(%view_48) : !cute.coord_tensor<"(?{div=16},?{div=4})", "((4,16)):((1@1,1@0))">
      %tup_551 = cute.add_offset(%iter_550, %524) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(14,0)">) -> !cute.int_tuple<"(?{div=2},?{div=4})">
      %view_552 = cute.make_view(%tup_551) : !cute.coord_tensor<"(?{div=2},?{div=4})", "():()">
      %iter_553 = cute.get_iter(%view_552) : !cute.coord_tensor<"(?{div=2},?{div=4})", "():()">
      %e0_554, %e1_555 = cute.get_leaves(%iter_553) : !cute.int_tuple<"(?{div=2},?{div=4})">
      %coord_556 = cute.make_coord(%e0_554, %e1_555) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"?{div=4}">) -> !cute.coord<"(?{div=2},?{div=4})">
      %coord_557 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %525:2 = cute.get_scalars(%coord_556) : !cute.coord<"(?{div=2},?{div=4})">
      %526:2 = cute.get_scalars(%coord_557) : !cute.coord<"(?,?)">
      %true_558 = arith.constant true
      %527 = arith.cmpi slt, %525#0, %526#0 : i32
      %528 = arith.andi %true_558, %527 : i1
      %529 = arith.cmpi slt, %525#1, %526#1 : i32
      %530 = arith.andi %528, %529 : i1
      %531 = arith.extui %530 : i1 to i8
      %532 = cute.static : !cute.coord<"56">
      cute.memref.store(%rmem, %532, %531) : (!memref_rmem_i8_, !cute.coord<"56">, i8) -> ()
      %533 = cute.static : !cute.int_tuple<"(14,1)">
      %iter_559 = cute.get_iter(%view_48) : !cute.coord_tensor<"(?{div=16},?{div=4})", "((4,16)):((1@1,1@0))">
      %tup_560 = cute.add_offset(%iter_559, %533) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(14,1)">) -> !cute.int_tuple<"(?{div=2},?)">
      %view_561 = cute.make_view(%tup_560) : !cute.coord_tensor<"(?{div=2},?)", "():()">
      %iter_562 = cute.get_iter(%view_561) : !cute.coord_tensor<"(?{div=2},?)", "():()">
      %e0_563, %e1_564 = cute.get_leaves(%iter_562) : !cute.int_tuple<"(?{div=2},?)">
      %coord_565 = cute.make_coord(%e0_563, %e1_564) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"?">) -> !cute.coord<"(?{div=2},?)">
      %coord_566 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %534:2 = cute.get_scalars(%coord_565) : !cute.coord<"(?{div=2},?)">
      %535:2 = cute.get_scalars(%coord_566) : !cute.coord<"(?,?)">
      %true_567 = arith.constant true
      %536 = arith.cmpi slt, %534#0, %535#0 : i32
      %537 = arith.andi %true_567, %536 : i1
      %538 = arith.cmpi slt, %534#1, %535#1 : i32
      %539 = arith.andi %537, %538 : i1
      %540 = arith.extui %539 : i1 to i8
      %541 = cute.static : !cute.coord<"57">
      cute.memref.store(%rmem, %541, %540) : (!memref_rmem_i8_, !cute.coord<"57">, i8) -> ()
      %542 = cute.static : !cute.int_tuple<"(14,2)">
      %iter_568 = cute.get_iter(%view_48) : !cute.coord_tensor<"(?{div=16},?{div=4})", "((4,16)):((1@1,1@0))">
      %tup_569 = cute.add_offset(%iter_568, %542) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(14,2)">) -> !cute.int_tuple<"(?{div=2},?{div=2})">
      %view_570 = cute.make_view(%tup_569) : !cute.coord_tensor<"(?{div=2},?{div=2})", "():()">
      %iter_571 = cute.get_iter(%view_570) : !cute.coord_tensor<"(?{div=2},?{div=2})", "():()">
      %e0_572, %e1_573 = cute.get_leaves(%iter_571) : !cute.int_tuple<"(?{div=2},?{div=2})">
      %coord_574 = cute.make_coord(%e0_572, %e1_573) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"?{div=2}">) -> !cute.coord<"(?{div=2},?{div=2})">
      %coord_575 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %543:2 = cute.get_scalars(%coord_574) : !cute.coord<"(?{div=2},?{div=2})">
      %544:2 = cute.get_scalars(%coord_575) : !cute.coord<"(?,?)">
      %true_576 = arith.constant true
      %545 = arith.cmpi slt, %543#0, %544#0 : i32
      %546 = arith.andi %true_576, %545 : i1
      %547 = arith.cmpi slt, %543#1, %544#1 : i32
      %548 = arith.andi %546, %547 : i1
      %549 = arith.extui %548 : i1 to i8
      %550 = cute.static : !cute.coord<"58">
      cute.memref.store(%rmem, %550, %549) : (!memref_rmem_i8_, !cute.coord<"58">, i8) -> ()
      %551 = cute.static : !cute.int_tuple<"(14,3)">
      %iter_577 = cute.get_iter(%view_48) : !cute.coord_tensor<"(?{div=16},?{div=4})", "((4,16)):((1@1,1@0))">
      %tup_578 = cute.add_offset(%iter_577, %551) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(14,3)">) -> !cute.int_tuple<"(?{div=2},?)">
      %view_579 = cute.make_view(%tup_578) : !cute.coord_tensor<"(?{div=2},?)", "():()">
      %iter_580 = cute.get_iter(%view_579) : !cute.coord_tensor<"(?{div=2},?)", "():()">
      %e0_581, %e1_582 = cute.get_leaves(%iter_580) : !cute.int_tuple<"(?{div=2},?)">
      %coord_583 = cute.make_coord(%e0_581, %e1_582) : (!cute.int_tuple<"?{div=2}">, !cute.int_tuple<"?">) -> !cute.coord<"(?{div=2},?)">
      %coord_584 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %552:2 = cute.get_scalars(%coord_583) : !cute.coord<"(?{div=2},?)">
      %553:2 = cute.get_scalars(%coord_584) : !cute.coord<"(?,?)">
      %true_585 = arith.constant true
      %554 = arith.cmpi slt, %552#0, %553#0 : i32
      %555 = arith.andi %true_585, %554 : i1
      %556 = arith.cmpi slt, %552#1, %553#1 : i32
      %557 = arith.andi %555, %556 : i1
      %558 = arith.extui %557 : i1 to i8
      %559 = cute.static : !cute.coord<"59">
      cute.memref.store(%rmem, %559, %558) : (!memref_rmem_i8_, !cute.coord<"59">, i8) -> ()
      %560 = cute.static : !cute.int_tuple<"(15,0)">
      %iter_586 = cute.get_iter(%view_48) : !cute.coord_tensor<"(?{div=16},?{div=4})", "((4,16)):((1@1,1@0))">
      %tup_587 = cute.add_offset(%iter_586, %560) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(15,0)">) -> !cute.int_tuple<"(?,?{div=4})">
      %view_588 = cute.make_view(%tup_587) : !cute.coord_tensor<"(?,?{div=4})", "():()">
      %iter_589 = cute.get_iter(%view_588) : !cute.coord_tensor<"(?,?{div=4})", "():()">
      %e0_590, %e1_591 = cute.get_leaves(%iter_589) : !cute.int_tuple<"(?,?{div=4})">
      %coord_592 = cute.make_coord(%e0_590, %e1_591) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=4}">) -> !cute.coord<"(?,?{div=4})">
      %coord_593 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %561:2 = cute.get_scalars(%coord_592) : !cute.coord<"(?,?{div=4})">
      %562:2 = cute.get_scalars(%coord_593) : !cute.coord<"(?,?)">
      %true_594 = arith.constant true
      %563 = arith.cmpi slt, %561#0, %562#0 : i32
      %564 = arith.andi %true_594, %563 : i1
      %565 = arith.cmpi slt, %561#1, %562#1 : i32
      %566 = arith.andi %564, %565 : i1
      %567 = arith.extui %566 : i1 to i8
      %568 = cute.static : !cute.coord<"60">
      cute.memref.store(%rmem, %568, %567) : (!memref_rmem_i8_, !cute.coord<"60">, i8) -> ()
      %569 = cute.static : !cute.int_tuple<"(15,1)">
      %iter_595 = cute.get_iter(%view_48) : !cute.coord_tensor<"(?{div=16},?{div=4})", "((4,16)):((1@1,1@0))">
      %tup_596 = cute.add_offset(%iter_595, %569) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(15,1)">) -> !cute.int_tuple<"(?,?)">
      %view_597 = cute.make_view(%tup_596) : !cute.coord_tensor<"(?,?)", "():()">
      %iter_598 = cute.get_iter(%view_597) : !cute.coord_tensor<"(?,?)", "():()">
      %e0_599, %e1_600 = cute.get_leaves(%iter_598) : !cute.int_tuple<"(?,?)">
      %coord_601 = cute.make_coord(%e0_599, %e1_600) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
      %coord_602 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %570:2 = cute.get_scalars(%coord_601) : !cute.coord<"(?,?)">
      %571:2 = cute.get_scalars(%coord_602) : !cute.coord<"(?,?)">
      %true_603 = arith.constant true
      %572 = arith.cmpi slt, %570#0, %571#0 : i32
      %573 = arith.andi %true_603, %572 : i1
      %574 = arith.cmpi slt, %570#1, %571#1 : i32
      %575 = arith.andi %573, %574 : i1
      %576 = arith.extui %575 : i1 to i8
      %577 = cute.static : !cute.coord<"61">
      cute.memref.store(%rmem, %577, %576) : (!memref_rmem_i8_, !cute.coord<"61">, i8) -> ()
      %578 = cute.static : !cute.int_tuple<"(15,2)">
      %iter_604 = cute.get_iter(%view_48) : !cute.coord_tensor<"(?{div=16},?{div=4})", "((4,16)):((1@1,1@0))">
      %tup_605 = cute.add_offset(%iter_604, %578) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(15,2)">) -> !cute.int_tuple<"(?,?{div=2})">
      %view_606 = cute.make_view(%tup_605) : !cute.coord_tensor<"(?,?{div=2})", "():()">
      %iter_607 = cute.get_iter(%view_606) : !cute.coord_tensor<"(?,?{div=2})", "():()">
      %e0_608, %e1_609 = cute.get_leaves(%iter_607) : !cute.int_tuple<"(?,?{div=2})">
      %coord_610 = cute.make_coord(%e0_608, %e1_609) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=2}">) -> !cute.coord<"(?,?{div=2})">
      %coord_611 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %579:2 = cute.get_scalars(%coord_610) : !cute.coord<"(?,?{div=2})">
      %580:2 = cute.get_scalars(%coord_611) : !cute.coord<"(?,?)">
      %true_612 = arith.constant true
      %581 = arith.cmpi slt, %579#0, %580#0 : i32
      %582 = arith.andi %true_612, %581 : i1
      %583 = arith.cmpi slt, %579#1, %580#1 : i32
      %584 = arith.andi %582, %583 : i1
      %585 = arith.extui %584 : i1 to i8
      %586 = cute.static : !cute.coord<"62">
      cute.memref.store(%rmem, %586, %585) : (!memref_rmem_i8_, !cute.coord<"62">, i8) -> ()
      %587 = cute.static : !cute.int_tuple<"(15,3)">
      %iter_613 = cute.get_iter(%view_48) : !cute.coord_tensor<"(?{div=16},?{div=4})", "((4,16)):((1@1,1@0))">
      %tup_614 = cute.add_offset(%iter_613, %587) : (!cute.int_tuple<"(?{div=16},?{div=4})">, !cute.int_tuple<"(15,3)">) -> !cute.int_tuple<"(?,?)">
      %view_615 = cute.make_view(%tup_614) : !cute.coord_tensor<"(?,?)", "():()">
      %iter_616 = cute.get_iter(%view_615) : !cute.coord_tensor<"(?,?)", "():()">
      %e0_617, %e1_618 = cute.get_leaves(%iter_616) : !cute.int_tuple<"(?,?)">
      %coord_619 = cute.make_coord(%e0_617, %e1_618) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
      %coord_620 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %588:2 = cute.get_scalars(%coord_619) : !cute.coord<"(?,?)">
      %589:2 = cute.get_scalars(%coord_620) : !cute.coord<"(?,?)">
      %true_621 = arith.constant true
      %590 = arith.cmpi slt, %588#0, %589#0 : i32
      %591 = arith.andi %true_621, %590 : i1
      %592 = arith.cmpi slt, %588#1, %589#1 : i32
      %593 = arith.andi %591, %592 : i1
      %594 = arith.extui %593 : i1 to i8
      %595 = cute.static : !cute.coord<"63">
      cute.memref.store(%rmem, %595, %594) : (!memref_rmem_i8_, !cute.coord<"63">, i8) -> ()
      %596 = cute.memref.load_vec %view_30, row_major : !memref_gmem_f32_6
      %597 = cute.memref.load_vec %view_35, row_major : !memref_gmem_f32_6
      %598 = arith.addf %596, %597 : vector<64xf32>
      cute.memref.store_vec %598, %view_43, row_major : !memref_gmem_f32_7
      return
    }
  }
  func.func @cutlass_elementwise_apply_builtinfunctionadd_Tensorgmem_o_4096409640961_Tensorgmem_o_4096409640961_Tensorgmemoi641_CUstream0x9998240(%arg0: !memref_gmem_f32_8, %arg1: !memref_gmem_f32_8, %arg2: !memref_gmem_f32_9, %arg3: !gpu.async.token) attributes {llvm.emit_c_interface} {
    %0 = cute.static : !cute.layout<"(16,16):(16,1)">
    %1 = cute.recast_layout<32, 8> (%0) : !cute.layout<"(16,16):(16,1)"> to !cute.layout<"(16,4):(4,1)">
    %iter = cute.get_iter(%arg0) : !memref_gmem_f32_8
    %view = cute.make_view(%iter) : !memref_gmem_f32_10
    %iter_0 = cute.get_iter(%arg1) : !memref_gmem_f32_8
    %view_1 = cute.make_view(%iter_0) : !memref_gmem_f32_10
    %iter_2 = cute.get_iter(%arg2) : !memref_gmem_f32_9
    %lay = cute.get_layout(%arg2) : !memref_gmem_f32_9
    %2:3 = cute.get_scalars(%lay) <{only_dynamic}> : !cute.layout<"(?,?):(?{i64},1)">
    %c64_i32 = arith.constant 64 : i32
    %3 = arith.ceildivsi %2#0, %c64_i32 : i32
    %c64_i64 = arith.constant 64 : i64
    %4 = arith.muli %2#2, %c64_i64 : i64
    %c256_i32 = arith.constant 256 : i32
    %5 = arith.ceildivsi %2#1, %c256_i32 : i32
    %shape = cute.make_shape(%3, %5) : (i32, i32) -> !cute.shape<"((64,256),(?,?))">
    %iv = cute.assume(%4) : (i64) -> !cute.i64<divby 64>
    %stride = cute.make_stride(%2#2, %iv) : (i64, !cute.i64<divby 64>) -> !cute.stride<"((?{i64},1),(?{i64 div=64},256))">
    %lay_3 = cute.make_layout(%shape, %stride) : !cute.layout<"((64,256),(?,?)):((?{i64},1),(?{i64 div=64},256))">
    %view_4 = cute.make_view(%iter_2, %lay_3) : !memref_gmem_f32_11
    %iter_5 = cute.get_iter(%view) : !memref_gmem_f32_10
    %view_6 = cute.make_view(%iter_5) : !memref_gmem_f32_
    %iter_7 = cute.get_iter(%view_1) : !memref_gmem_f32_10
    %view_8 = cute.make_view(%iter_7) : !memref_gmem_f32_
    %iter_9 = cute.get_iter(%view_4) : !memref_gmem_f32_11
    %lay_10 = cute.get_layout(%view_4) : !memref_gmem_f32_11
    %6:4 = cute.get_scalars(%lay_10) <{only_dynamic}> : !cute.layout<"((64,256),(?,?)):((?{i64},1),(?{i64 div=64},256))">
    %c64_i32_11 = arith.constant 64 : i32
    %7 = arith.divsi %6#0, %c64_i32_11 : i32
    %c0_i32 = arith.constant 0 : i32
    %8 = arith.cmpi ne, %7, %c0_i32 : i32
    %9 = scf.if %8 -> (i32) {
      scf.yield %7 : i32
    } else {
      %c0_i32_54 = arith.constant 0 : i32
      %52 = arith.cmpi sgt, %6#0, %c0_i32_54 : i32
      %53 = scf.if %52 -> (i32) {
        %c1_i32_55 = arith.constant 1 : i32
        scf.yield %c1_i32_55 : i32
      } else {
        %c0_i32_55 = arith.constant 0 : i32
        %54 = arith.cmpi eq, %6#0, %c0_i32_55 : i32
        %55 = scf.if %54 -> (i32) {
          %c0_i32_56 = arith.constant 0 : i32
          scf.yield %c0_i32_56 : i32
        } else {
          %c-1_i32 = arith.constant -1 : i32
          scf.yield %c-1_i32 : i32
        }
        scf.yield %55 : i32
      }
      scf.yield %53 : i32
    }
    %c16_i32 = arith.constant 16 : i32
    %10 = arith.minsi %9, %c16_i32 : i32
    %c64_i64_12 = arith.constant 64 : i64
    %11 = arith.muli %6#3, %c64_i64_12 : i64
    %12 = math.absi %9 : i32
    %c16_i32_13 = arith.constant 16 : i32
    %13 = arith.divsi %c16_i32_13, %12 : i32
    %c0_i32_14 = arith.constant 0 : i32
    %14 = arith.cmpi ne, %13, %c0_i32_14 : i32
    %15 = scf.if %14 -> (i32) {
      scf.yield %13 : i32
    } else {
      %c0_i32_54 = arith.constant 0 : i32
      %52 = arith.cmpi sgt, %12, %c0_i32_54 : i32
      %53 = scf.if %52 -> (i32) {
        %c1_i32_55 = arith.constant 1 : i32
        scf.yield %c1_i32_55 : i32
      } else {
        %c0_i32_55 = arith.constant 0 : i32
        %54 = arith.cmpi eq, %12, %c0_i32_55 : i32
        %55 = scf.if %54 -> (i32) {
          %c0_i32_56 = arith.constant 0 : i32
          scf.yield %c0_i32_56 : i32
        } else {
          %c-1_i32 = arith.constant -1 : i32
          scf.yield %c-1_i32 : i32
        }
        scf.yield %55 : i32
      }
      scf.yield %53 : i32
    }
    %c64_i32_15 = arith.constant 64 : i32
    %16 = arith.divsi %c64_i32_15, %6#0 : i32
    %c0_i32_16 = arith.constant 0 : i32
    %17 = arith.cmpi ne, %16, %c0_i32_16 : i32
    %18 = scf.if %17 -> (i32) {
      scf.yield %16 : i32
    } else {
      %c0_i32_54 = arith.constant 0 : i32
      %52 = arith.cmpi sgt, %6#0, %c0_i32_54 : i32
      %53 = scf.if %52 -> (i32) {
        %c1_i32_55 = arith.constant 1 : i32
        scf.yield %c1_i32_55 : i32
      } else {
        %c0_i32_55 = arith.constant 0 : i32
        %54 = arith.cmpi eq, %6#0, %c0_i32_55 : i32
        %55 = scf.if %54 -> (i32) {
          %c0_i32_56 = arith.constant 0 : i32
          scf.yield %c0_i32_56 : i32
        } else {
          %c-1_i32 = arith.constant -1 : i32
          scf.yield %c-1_i32 : i32
        }
        scf.yield %55 : i32
      }
      scf.yield %53 : i32
    }
    %c256_i32_17 = arith.constant 256 : i32
    %19 = arith.muli %18, %c256_i32_17 : i32
    %c0_i32_18 = arith.constant 0 : i32
    %20 = arith.cmpi ne, %6#0, %c0_i32_18 : i32
    %21 = scf.if %20 -> (i32) {
      scf.yield %6#0 : i32
    } else {
      %c0_i32_54 = arith.constant 0 : i32
      %52 = arith.cmpi sgt, %6#0, %c0_i32_54 : i32
      %53 = scf.if %52 -> (i32) {
        %c1_i32_55 = arith.constant 1 : i32
        scf.yield %c1_i32_55 : i32
      } else {
        %c0_i32_55 = arith.constant 0 : i32
        %54 = arith.cmpi eq, %6#0, %c0_i32_55 : i32
        %55 = scf.if %54 -> (i32) {
          %c0_i32_56 = arith.constant 0 : i32
          scf.yield %c0_i32_56 : i32
        } else {
          %c-1_i32 = arith.constant -1 : i32
          scf.yield %c-1_i32 : i32
        }
        scf.yield %55 : i32
      }
      scf.yield %53 : i32
    }
    %c64_i32_19 = arith.constant 64 : i32
    %22 = arith.minsi %21, %c64_i32_19 : i32
    %23 = math.absi %21 : i32
    %c64_i32_20 = arith.constant 64 : i32
    %24 = arith.divsi %c64_i32_20, %23 : i32
    %c0_i32_21 = arith.constant 0 : i32
    %25 = arith.cmpi ne, %24, %c0_i32_21 : i32
    %26 = scf.if %25 -> (i32) {
      scf.yield %24 : i32
    } else {
      %c0_i32_54 = arith.constant 0 : i32
      %52 = arith.cmpi sgt, %23, %c0_i32_54 : i32
      %53 = scf.if %52 -> (i32) {
        %c1_i32_55 = arith.constant 1 : i32
        scf.yield %c1_i32_55 : i32
      } else {
        %c0_i32_55 = arith.constant 0 : i32
        %54 = arith.cmpi eq, %23, %c0_i32_55 : i32
        %55 = scf.if %54 -> (i32) {
          %c0_i32_56 = arith.constant 0 : i32
          scf.yield %c0_i32_56 : i32
        } else {
          %c-1_i32 = arith.constant -1 : i32
          scf.yield %c-1_i32 : i32
        }
        scf.yield %55 : i32
      }
      scf.yield %53 : i32
    }
    %c1_i32 = arith.constant 1 : i32
    %27 = arith.divsi %c1_i32, %6#0 : i32
    %c0_i32_22 = arith.constant 0 : i32
    %28 = arith.cmpi ne, %27, %c0_i32_22 : i32
    %29 = scf.if %28 -> (i32) {
      scf.yield %27 : i32
    } else {
      %c0_i32_54 = arith.constant 0 : i32
      %52 = arith.cmpi sgt, %6#0, %c0_i32_54 : i32
      %53 = scf.if %52 -> (i32) {
        %c1_i32_55 = arith.constant 1 : i32
        scf.yield %c1_i32_55 : i32
      } else {
        %c0_i32_55 = arith.constant 0 : i32
        %54 = arith.cmpi eq, %6#0, %c0_i32_55 : i32
        %55 = scf.if %54 -> (i32) {
          %c0_i32_56 = arith.constant 0 : i32
          scf.yield %c0_i32_56 : i32
        } else {
          %c-1_i32 = arith.constant -1 : i32
          scf.yield %c-1_i32 : i32
        }
        scf.yield %55 : i32
      }
      scf.yield %53 : i32
    }
    %c256_i32_23 = arith.constant 256 : i32
    %30 = arith.muli %29, %c256_i32_23 : i32
    %shape_24 = cute.make_shape(%10, %15, %22, %26) : (i32, i32, i32, i32) -> !cute.shape<"((64,256),((?,?),(?,?)))">
    %iv_25 = cute.assume(%11) : (i64) -> !cute.i64<divby 4096>
    %iv_26 = cute.assume(%19) : (i32) -> !cute.i32<divby 256>
    %iv_27 = cute.assume(%6#3) : (i64) -> !cute.i64<divby 64>
    %iv_28 = cute.assume(%30) : (i32) -> !cute.i32<divby 256>
    %stride_29 = cute.make_stride(%6#2, %iv_25, %iv_26, %iv_27, %iv_28) : (i64, !cute.i64<divby 4096>, !cute.i32<divby 256>, !cute.i64<divby 64>, !cute.i32<divby 256>) -> !cute.stride<"((?{i64},1),((?{i64 div=4096},?{div=256}),(?{i64 div=64},?{div=256})))">
    %lay_30 = cute.make_layout(%shape_24, %stride_29) : !cute.layout<"((64,256),((?,?),(?,?))):((?{i64},1),((?{i64 div=4096},?{div=256}),(?{i64 div=64},?{div=256})))">
    %view_31 = cute.make_view(%iter_9, %lay_30) : !memref_gmem_f32_1
    %lay_32 = cute.get_layout(%arg2) : !memref_gmem_f32_9
    %31 = cute.get_shape(%lay_32) : (!cute.layout<"(?,?):(?{i64},1)">) -> !cute.shape<"(?,?)">
    %e0, %e1 = cute.get_leaves(%31) : !cute.shape<"(?,?)">
    %itup = cute.to_int_tuple(%e0) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %32 = cute.get_scalars(%itup) : !cute.int_tuple<"?">
    %itup_33 = cute.to_int_tuple(%e1) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %33 = cute.get_scalars(%itup_33) : !cute.int_tuple<"?">
    %shape_34 = cute.make_shape(%itup, %itup_33) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.shape<"(?,?)">
    %34 = cute.static : !cute.int_tuple<"(0,0)">
    %35 = cute.static : !cute.stride<"(1@0,1@1)">
    %lay_35 = cute.make_layout(%shape_34, %35) : !cute.layout<"(?,?):(1@0,1@1)">
    %view_36 = cute.make_view(%34, %lay_35) : !cute.coord_tensor<"(0,0)", "(?,?):(1@0,1@1)">
    %36 = cute.static : !cute.int_tuple<"(0,0)">
    %lay_37 = cute.get_layout(%view_36) : !cute.coord_tensor<"(0,0)", "(?,?):(1@0,1@1)">
    %37:2 = cute.get_scalars(%lay_37) <{only_dynamic}> : !cute.layout<"(?,?):(1@0,1@1)">
    %c64_i32_38 = arith.constant 64 : i32
    %38 = arith.ceildivsi %37#0, %c64_i32_38 : i32
    %c256_i32_39 = arith.constant 256 : i32
    %39 = arith.ceildivsi %37#1, %c256_i32_39 : i32
    %shape_40 = cute.make_shape(%38, %39) : (i32, i32) -> !cute.shape<"((64,256),(?,?))">
    %40 = cute.static : !cute.stride<"((1@0,1@1),(64@0,256@1))">
    %lay_41 = cute.make_layout(%shape_40, %40) : !cute.layout<"((64,256),(?,?)):((1@0,1@1),(64@0,256@1))">
    %view_42 = cute.make_view(%36, %lay_41) : !cute.coord_tensor<"(0,0)", "((64,256),(?,?)):((1@0,1@1),(64@0,256@1))">
    %lay_43 = cute.get_layout(%view_31) : !memref_gmem_f32_1
    %41 = cute.get_shape(%lay_43) : (!cute.layout<"((64,256),((?,?),(?,?))):((?{i64},1),((?{i64 div=4096},?{div=256}),(?{i64 div=64},?{div=256})))">) -> !cute.shape<"((64,256),((?,?),(?,?)))">
    %42 = cute.static : !cute.shape<"64">
    %43 = cute.static : !cute.shape<"256">
    %e0_44, %e1_45, %e2, %e3, %e4, %e5 = cute.get_leaves(%41) : !cute.shape<"((64,256),((?,?),(?,?)))">
    %itup_46 = cute.to_int_tuple(%e2) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %itup_47 = cute.to_int_tuple(%e3) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %itup_48 = cute.to_int_tuple(%e4) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %itup_49 = cute.to_int_tuple(%e5) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %int_tuple = cute.make_int_tuple(%itup_46, %itup_47, %itup_48, %itup_49) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.int_tuple<"((?,?),(?,?))">
    %44:4 = cute.get_scalars(%int_tuple) <{only_dynamic}> : !cute.int_tuple<"((?,?),(?,?))">
    %45 = arith.muli %44#0, %44#1 : i32
    %46 = arith.muli %44#2, %44#3 : i32
    %int_tuple_50 = cute.make_int_tuple(%45, %46) : (i32, i32) -> !cute.int_tuple<"(?,?)">
    %e0_51, %e1_52 = cute.get_leaves(%int_tuple_50) : !cute.int_tuple<"(?,?)">
    %47 = cute.get_scalars(%e0_51) : !cute.int_tuple<"?">
    %48 = cute.get_scalars(%e1_52) : !cute.int_tuple<"?">
    %49 = arith.index_cast %47 : i32 to index
    %50 = arith.index_cast %48 : i32 to index
    %c1 = arith.constant 1 : index
    %c256 = arith.constant 256 : index
    %c0_i32_53 = arith.constant 0 : i32
    %51 = gpu.launch_func async [%arg3] @kernels::@kernel_cutlass_elementwise_apply_kernel_builtinfunctionadd_tensorptrf32_gmem_align16_o_64256166440961256262144_tensorptrf32_gmem_align16_o_64256166440961256262144_tensorptrf32gmemalign16o_0 blocks in (%49, %50, %c1) threads in (%c256, %c1, %c1)  dynamic_shared_memory_size %c0_i32_53 args(%view_6 : !memref_gmem_f32_, %view_8 : !memref_gmem_f32_, %view_31 : !memref_gmem_f32_1, %view_42 : !cute.coord_tensor<"(0,0)", "((64,256),(?,?)):((1@0,1@1),(64@0,256@1))">, %32 : i32, %33 : i32) {use_pdl = false}
    return
  }
}
