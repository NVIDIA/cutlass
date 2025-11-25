!memref_gmem_f32_ = !cute.memref<f32, gmem, "((1,512,1),(?,?,?)):((0,?{i64},0),(?{i64},?{i64 div=512},1))">
!memref_gmem_f32_1 = !cute.memref<f32, gmem, "((1,512,1)):((0,?{i64},0))">
!memref_gmem_f32_2 = !cute.memref<f32, gmem, "(128,4):(?{i64 div=4},?{i64})">
!memref_gmem_f32_3 = !cute.memref<f32, gmem, "(4):(?{i64})">
!memref_gmem_f32_4 = !cute.memref<f32, gmem, "(4,1):(?{i64},0)">
!memref_gmem_f32_5 = !cute.memref<f32, gmem, "(4,(1)):(?{i64},(0))">
!memref_gmem_f32_6 = !cute.memref<f32, gmem, "(?,?,?):(?{i64},?{i64},1)">
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
!memref_rmem_f32_3 = !cute.memref<f32, rmem, align<32>, "(4):(1)">
!memref_rmem_f8E4M3FN = !cute.memref<f8E4M3FN, rmem, align<32>, "4:1">
!memref_rmem_f8E4M3FN1 = !cute.memref<f8E4M3FN, rmem, align<32>, "(4,1):(1,0)">
!memref_rmem_f8E4M3FN2 = !cute.memref<f8E4M3FN, rmem, align<32>, "(4,(1)):(1,(0))">
!memref_rmem_f8E4M3FN3 = !cute.memref<f8E4M3FN, rmem, align<32>, "(4):(1)">
#loop_unroll = #llvm.loop_unroll<disable = false, full = true>
#loop_annotation = #llvm.loop_annotation<unroll = #loop_unroll>
module attributes {gpu.container_module} {
  gpu.module @kernels {
    func.func public @kernel_cutlass__convert_kernel_tensorptrf32gmemo1512100div5121_tensorptrf8E4M3FNgmemalign16o15121010div16512div16_tensor000o15121011010512112____Float32_Float8E4M3FN_0(%arg0: !memref_gmem_f32_, %arg1: !memref_gmem_f8E4M3FN, %arg2: !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">, %arg3: i32, %arg4: i32, %arg5: i32) attributes {cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} {
      %0 = cute.static : !cute.layout<"(128,4):(4,1)">
      %1 = cute.static : !cute.layout<"(128,4):(4,1)">
      %2 = nvvm.read.ptx.sreg.tid.x range <i32, 0, 1024> : i32
      %3 = nvvm.read.ptx.sreg.ctaid.x range <i32, 0, 2147483647> : i32
      %coord = cute.make_coord(%3) : (i32) -> !cute.coord<"(_,?)">
      %lay = cute.get_layout(%arg0) : !memref_gmem_f32_
      %4:6 = cute.get_scalars(%lay) <{only_dynamic}> : !cute.layout<"((1,512,1),(?,?,?)):((0,?{i64},0),(?{i64},?{i64 div=512},1))">
      %5 = cute.static : !cute.shape<"((1,512,1))">
      %stride = cute.make_stride(%4#3) : (i64) -> !cute.stride<"((0,?{i64},0))">
      %lay_0 = cute.make_layout(%5, %stride) : !cute.layout<"((1,512,1)):((0,?{i64},0))">
      %idx = cute.crd2idx(%coord, %lay) : (!cute.coord<"(_,?)">, !cute.layout<"((1,512,1),(?,?,?)):((0,?{i64},0),(?{i64},?{i64 div=512},1))">) -> !cute.int_tuple<"?{i64}">
      %iter = cute.get_iter(%arg0) : !memref_gmem_f32_
      %ptr = cute.add_offset(%iter, %idx) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %view = cute.make_view(%ptr, %lay_0) : !memref_gmem_f32_1
      %coord_1 = cute.make_coord(%3) : (i32) -> !cute.coord<"(_,?)">
      %lay_2 = cute.get_layout(%arg1) : !memref_gmem_f8E4M3FN
      %idx_3 = cute.crd2idx(%coord_1, %lay_2) : (!cute.coord<"(_,?)">, !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{div=16},512,?{div=16}))">) -> !cute.int_tuple<"?{div=16}">
      %iter_4 = cute.get_iter(%arg1) : !memref_gmem_f8E4M3FN
      %ptr_5 = cute.add_offset(%iter_4, %idx_3) : (!cute.ptr<f8E4M3FN, gmem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<f8E4M3FN, gmem, align<16>>
      %view_6 = cute.make_view(%ptr_5) : !memref_gmem_f8E4M3FN1
      %coord_7 = cute.make_coord(%3) : (i32) -> !cute.coord<"(_,?)">
      %lay_8 = cute.get_layout(%arg2) : !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">
      %idx_9 = cute.crd2idx(%coord_7, %lay_8) : (!cute.coord<"(_,?)">, !cute.layout<"((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">) -> !cute.int_tuple<"(?,?{div=512},?)">
      %6 = cute.static : !cute.int_tuple<"(0,0,0)">
      %tup = cute.add_offset(%6, %idx_9) : (!cute.int_tuple<"(0,0,0)">, !cute.int_tuple<"(?,?{div=512},?)">) -> !cute.int_tuple<"(?,?{div=512},?)">
      %view_10 = cute.make_view(%tup) : !cute.coord_tensor<"(?,?{div=512},?)", "((1,512,1)):((0,1@1,0))">
      %iter_11 = cute.get_iter(%view) : !memref_gmem_f32_1
      %lay_12 = cute.get_layout(%view) : !memref_gmem_f32_1
      %7 = cute.get_scalars(%lay_12) <{only_dynamic}> : !cute.layout<"((1,512,1)):((0,?{i64},0))">
      %c4_i64 = arith.constant 4 : i64
      %8 = arith.muli %7, %c4_i64 : i64
      %9 = cute.static : !cute.shape<"(128,4)">
      %iv = cute.assume(%8) : (i64) -> !cute.i64<divby 4>
      %stride_13 = cute.make_stride(%iv, %7) : (!cute.i64<divby 4>, i64) -> !cute.stride<"(?{i64 div=4},?{i64})">
      %lay_14 = cute.make_layout(%9, %stride_13) : !cute.layout<"(128,4):(?{i64 div=4},?{i64})">
      %view_15 = cute.make_view(%iter_11, %lay_14) : !memref_gmem_f32_2
      %iter_16 = cute.get_iter(%view_6) : !memref_gmem_f8E4M3FN1
      %view_17 = cute.make_view(%iter_16) : !memref_gmem_f8E4M3FN2
      %iter_18 = cute.get_iter(%view_10) : !cute.coord_tensor<"(?,?{div=512},?)", "((1,512,1)):((0,1@1,0))">
      %view_19 = cute.make_view(%iter_18) : !cute.coord_tensor<"(?,?{div=512},?)", "(128,4):(4@1,1@1)">
      %coord_20 = cute.make_coord(%2) : (i32) -> !cute.coord<"(?,_)">
      %lay_21 = cute.get_layout(%view_15) : !memref_gmem_f32_2
      %10:2 = cute.get_scalars(%lay_21) <{only_dynamic}> : !cute.layout<"(128,4):(?{i64 div=4},?{i64})">
      %11 = cute.static : !cute.shape<"(4)">
      %stride_22 = cute.make_stride(%10#1) : (i64) -> !cute.stride<"(?{i64})">
      %lay_23 = cute.make_layout(%11, %stride_22) : !cute.layout<"(4):(?{i64})">
      %idx_24 = cute.crd2idx(%coord_20, %lay_21) : (!cute.coord<"(?,_)">, !cute.layout<"(128,4):(?{i64 div=4},?{i64})">) -> !cute.int_tuple<"?{i64 div=4}">
      %iter_25 = cute.get_iter(%view_15) : !memref_gmem_f32_2
      %ptr_26 = cute.add_offset(%iter_25, %idx_24) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=4}">) -> !cute.ptr<f32, gmem>
      %view_27 = cute.make_view(%ptr_26, %lay_23) : !memref_gmem_f32_3
      %iter_28 = cute.get_iter(%view_27) : !memref_gmem_f32_3
      %coord_29 = cute.make_coord(%2) : (i32) -> !cute.coord<"(?,_)">
      %12 = cute.static : !cute.layout<"(128,4):(4,1)">
      %idx_30 = cute.crd2idx(%coord_29, %12) : (!cute.coord<"(?,_)">, !cute.layout<"(128,4):(4,1)">) -> !cute.int_tuple<"?{div=4}">
      %iter_31 = cute.get_iter(%view_17) : !memref_gmem_f8E4M3FN2
      %ptr_32 = cute.add_offset(%iter_31, %idx_30) : (!cute.ptr<f8E4M3FN, gmem, align<16>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f8E4M3FN, gmem, align<4>>
      %view_33 = cute.make_view(%ptr_32) : !memref_gmem_f8E4M3FN3
      %iter_34 = cute.get_iter(%view_33) : !memref_gmem_f8E4M3FN3
      %coord_35 = cute.make_coord(%2) : (i32) -> !cute.coord<"(?,_)">
      %13 = cute.static : !cute.layout<"(128,4):(4@1,1@1)">
      %idx_36 = cute.crd2idx(%coord_35, %13) : (!cute.coord<"(?,_)">, !cute.layout<"(128,4):(4@1,1@1)">) -> !cute.int_tuple<"(0,?{div=4})">
      %iter_37 = cute.get_iter(%view_19) : !cute.coord_tensor<"(?,?{div=512},?)", "(128,4):(4@1,1@1)">
      %tup_38 = cute.add_offset(%iter_37, %idx_36) : (!cute.int_tuple<"(?,?{div=512},?)">, !cute.int_tuple<"(0,?{div=4})">) -> !cute.int_tuple<"(?,?{div=4},?)">
      %view_39 = cute.make_view(%tup_38) : !cute.coord_tensor<"(?,?{div=4},?)", "(4):(1@1)">
      %14 = cute.static : !cute.int_tuple<"(0,0)">
      %iter_40 = cute.get_iter(%view_39) : !cute.coord_tensor<"(?,?{div=4},?)", "(4):(1@1)">
      %tup_41 = cute.add_offset(%iter_40, %14) : (!cute.int_tuple<"(?,?{div=4},?)">, !cute.int_tuple<"(0,0)">) -> !cute.int_tuple<"(?,?{div=4},?)">
      %view_42 = cute.make_view(%tup_41) : !cute.coord_tensor<"(?,?{div=4},?)", "():()">
      %iter_43 = cute.get_iter(%view_42) : !cute.coord_tensor<"(?,?{div=4},?)", "():()">
      %e0, %e1, %e2 = cute.get_leaves(%iter_43) : !cute.int_tuple<"(?,?{div=4},?)">
      %coord_44 = cute.make_coord(%e0, %e1, %e2) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=4}">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?{div=4},?)">
      %coord_45 = cute.make_coord(%arg3, %arg4, %arg5) : (i32, i32, i32) -> !cute.coord<"(?,?,?)">
      %15:3 = cute.get_scalars(%coord_44) : !cute.coord<"(?,?{div=4},?)">
      %16:3 = cute.get_scalars(%coord_45) : !cute.coord<"(?,?,?)">
      %true = arith.constant true
      %17 = arith.cmpi slt, %15#0, %16#0 : i32
      %18 = arith.andi %true, %17 : i1
      %19 = arith.cmpi slt, %15#1, %16#1 : i32
      %20 = arith.andi %18, %19 : i1
      %21 = arith.cmpi slt, %15#2, %16#2 : i32
      %22 = arith.andi %20, %21 : i1
      scf.if %22 {
        %23 = cute.static : !cute.layout<"4:1">
        %rmem = cute.memref.alloca(%23) : !memref_rmem_f32_
        %iter_46 = cute.get_iter(%rmem) : !memref_rmem_f32_
        %24 = cute.static : !cute.layout<"4:1">
        %rmem_47 = cute.memref.alloca(%24) : !memref_rmem_f8E4M3FN
        %iter_48 = cute.get_iter(%rmem_47) : !memref_rmem_f8E4M3FN
        %lay_49 = cute.get_layout(%view_27) : !memref_gmem_f32_3
        %25 = cute.static : !cute.layout<"1:0">
        %append = cute.append_to_rank<2> (%lay_49, %25) : !cute.layout<"(4):(?{i64})">, !cute.layout<"1:0">
        %view_50 = cute.make_view(%iter_28, %append) : !memref_gmem_f32_4
        %iter_51 = cute.get_iter(%view_50) : !memref_gmem_f32_4
        %lay_52 = cute.get_layout(%view_50) : !memref_gmem_f32_4
        %26 = cute.get_scalars(%lay_52) <{only_dynamic}> : !cute.layout<"(4,1):(?{i64},0)">
        %27 = cute.static : !cute.shape<"(4,(1))">
        %stride_53 = cute.make_stride(%26) : (i64) -> !cute.stride<"(?{i64},(0))">
        %lay_54 = cute.make_layout(%27, %stride_53) : !cute.layout<"(4,(1)):(?{i64},(0))">
        %view_55 = cute.make_view(%iter_51, %lay_54) : !memref_gmem_f32_5
        %28 = cute.static : !cute.layout<"(4,1):(1,0)">
        %view_56 = cute.make_view(%iter_46, %28) : !memref_rmem_f32_1
        %iter_57 = cute.get_iter(%view_56) : !memref_rmem_f32_1
        %view_58 = cute.make_view(%iter_57) : !memref_rmem_f32_2
        %29 = cute.static : !cute.layout<"1:0">
        %iter_59 = cute.get_iter(%view_55) : !memref_gmem_f32_5
        %iter_60 = cute.get_iter(%view_58) : !memref_rmem_f32_2
        %lay_61 = cute.get_layout(%view_55) : !memref_gmem_f32_5
        %append_62 = cute.append_to_rank<2> (%lay_61, %29) : !cute.layout<"(4,(1)):(?{i64},(0))">, !cute.layout<"1:0">
        %30 = cute.get_scalars(%append_62) <{only_dynamic}> : !cute.layout<"(4,(1)):(?{i64},(0))">
        %31 = cute.static : !cute.shape<"(4,((1)))">
        %stride_63 = cute.make_stride(%30) : (i64) -> !cute.stride<"(?{i64},((0)))">
        %lay_64 = cute.make_layout(%31, %stride_63) : !cute.layout<"(4,((1))):(?{i64},((0)))">
        %32 = cute.static : !cute.int_tuple<"1">
        %33 = cute.get_scalars(%32) : !cute.int_tuple<"1">
        %c0_i32 = arith.constant 0 : i32
        %c1_i32 = arith.constant 1 : i32
        scf.for %arg6 = %c0_i32 to %33 step %c1_i32  : i32 {
          %41 = cute.get_scalars(%lay_64) <{only_dynamic}> : !cute.layout<"(4,((1))):(?{i64},((0)))">
          %42 = cute.static : !cute.shape<"(4)">
          %stride_75 = cute.make_stride(%41) : (i64) -> !cute.stride<"(?{i64})">
          %lay_76 = cute.make_layout(%42, %stride_75) : !cute.layout<"(4):(?{i64})">
          %43 = cute.static : !cute.int_tuple<"0">
          %ptr_77 = cute.add_offset(%iter_59, %43) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<f32, gmem>
          %view_78 = cute.make_view(%ptr_77, %lay_76) : !memref_gmem_f32_3
          %44 = cute.static : !cute.layout<"(4):(1)">
          %45 = cute.static : !cute.int_tuple<"0">
          %ptr_79 = cute.add_offset(%iter_60, %45) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, rmem, align<32>>
          %view_80 = cute.make_view(%ptr_79, %44) : !memref_rmem_f32_3
          %iter_81 = cute.get_iter(%view_78) : !memref_gmem_f32_3
          %lay_82 = cute.get_layout(%view_78) : !memref_gmem_f32_3
          %46 = cute.get_scalars(%lay_82) <{only_dynamic}> : !cute.layout<"(4):(?{i64})">
          %iter_83 = cute.get_iter(%view_80) : !memref_rmem_f32_3
          %47 = builtin.unrealized_conversion_cast %iter_81 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %48 = builtin.unrealized_conversion_cast %iter_83 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
          %49 = llvm.load %47 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %49, %48 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          %int_tuple = cute.make_int_tuple(%46) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_84 = cute.add_offset(%iter_81, %int_tuple) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %50 = cute.static : !cute.int_tuple<"1">
          %ptr_85 = cute.add_offset(%iter_83, %50) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
          %51 = builtin.unrealized_conversion_cast %ptr_84 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %52 = builtin.unrealized_conversion_cast %ptr_85 : !cute.ptr<f32, rmem> to !llvm.ptr
          %53 = llvm.load %51 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %53, %52 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          %c2_i64 = arith.constant 2 : i64
          %54 = arith.muli %46, %c2_i64 : i64
          %iv_86 = cute.assume(%54) : (i64) -> !cute.i64<divby 2>
          %int_tuple_87 = cute.make_int_tuple(%iv_86) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
          %ptr_88 = cute.add_offset(%iter_81, %int_tuple_87) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
          %55 = cute.static : !cute.int_tuple<"2">
          %ptr_89 = cute.add_offset(%iter_83, %55) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
          %56 = builtin.unrealized_conversion_cast %ptr_88 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %57 = builtin.unrealized_conversion_cast %ptr_89 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %58 = llvm.load %56 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %58, %57 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          %c3_i64 = arith.constant 3 : i64
          %59 = arith.muli %46, %c3_i64 : i64
          %iv_90 = cute.assume(%59) : (i64) -> !cute.i64<divby 3>
          %int_tuple_91 = cute.make_int_tuple(%iv_90) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
          %ptr_92 = cute.add_offset(%iter_81, %int_tuple_91) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
          %60 = cute.static : !cute.int_tuple<"3">
          %ptr_93 = cute.add_offset(%iter_83, %60) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
          %61 = builtin.unrealized_conversion_cast %ptr_92 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %62 = builtin.unrealized_conversion_cast %ptr_93 : !cute.ptr<f32, rmem> to !llvm.ptr
          %63 = llvm.load %61 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %63, %62 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %34 = cute.memref.load_vec %rmem, row_major : !memref_rmem_f32_
        %35 = nvgpu.cvt_fptrunc %34 : vector<4xf32> to vector<4xf8E4M3FN>
        cute.memref.store_vec %35, %rmem_47, row_major : !memref_rmem_f8E4M3FN
        %36 = cute.static : !cute.layout<"(4,1):(1,0)">
        %view_65 = cute.make_view(%iter_48, %36) : !memref_rmem_f8E4M3FN1
        %iter_66 = cute.get_iter(%view_65) : !memref_rmem_f8E4M3FN1
        %view_67 = cute.make_view(%iter_66) : !memref_rmem_f8E4M3FN2
        %37 = cute.static : !cute.layout<"(4,1):(1,0)">
        %view_68 = cute.make_view(%iter_34, %37) : !memref_gmem_f8E4M3FN4
        %iter_69 = cute.get_iter(%view_68) : !memref_gmem_f8E4M3FN4
        %view_70 = cute.make_view(%iter_69) : !memref_gmem_f8E4M3FN5
        %38 = cute.static : !cute.layout<"1:0">
        %iter_71 = cute.get_iter(%view_67) : !memref_rmem_f8E4M3FN2
        %iter_72 = cute.get_iter(%view_70) : !memref_gmem_f8E4M3FN5
        %39 = cute.static : !cute.int_tuple<"1">
        %40 = cute.get_scalars(%39) : !cute.int_tuple<"1">
        %c0_i32_73 = arith.constant 0 : i32
        %c1_i32_74 = arith.constant 1 : i32
        scf.for %arg6 = %c0_i32_73 to %40 step %c1_i32_74  : i32 {
          %41 = cute.static : !cute.layout<"(4):(1)">
          %42 = cute.static : !cute.int_tuple<"0">
          %ptr_75 = cute.add_offset(%iter_71, %42) : (!cute.ptr<f8E4M3FN, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f8E4M3FN, rmem, align<32>>
          %view_76 = cute.make_view(%ptr_75, %41) : !memref_rmem_f8E4M3FN3
          %43 = cute.static : !cute.layout<"(4):(1)">
          %44 = cute.static : !cute.int_tuple<"0">
          %ptr_77 = cute.add_offset(%iter_72, %44) : (!cute.ptr<f8E4M3FN, gmem, align<4>>, !cute.int_tuple<"0">) -> !cute.ptr<f8E4M3FN, gmem, align<4>>
          %view_78 = cute.make_view(%ptr_77, %43) : !memref_gmem_f8E4M3FN3
          %iter_79 = cute.get_iter(%view_76) : !memref_rmem_f8E4M3FN3
          %iter_80 = cute.get_iter(%view_78) : !memref_gmem_f8E4M3FN3
          %45 = builtin.unrealized_conversion_cast %iter_79 : !cute.ptr<f8E4M3FN, rmem, align<32>> to !llvm.ptr
          %46 = builtin.unrealized_conversion_cast %iter_80 : !cute.ptr<f8E4M3FN, gmem, align<4>> to !llvm.ptr<1>
          %47 = llvm.load %45 {alignment = 4 : i64} : !llvm.ptr -> vector<4xi8>
          llvm.store %47, %46 {alignment = 4 : i64} : vector<4xi8>, !llvm.ptr<1>
        } {llvm.loop_annotation = #loop_annotation}
      }
      return
    }
  }
  func.func @cutlass__convert_Tensorgmemoi64i641_Tensorgmemodiv16div161div16_1_4(%arg0: !memref_gmem_f32_6, %arg1: !memref_gmem_f8E4M3FN6) attributes {llvm.emit_c_interface} {
    %lay = cute.get_layout(%arg0) : !memref_gmem_f32_6
    %0 = cute.get_shape(%lay) : (!cute.layout<"(?,?,?):(?{i64},?{i64},1)">) -> !cute.shape<"(?,?,?)">
    %e0, %e1, %e2 = cute.get_leaves(%0) : !cute.shape<"(?,?,?)">
    %itup = cute.to_int_tuple(%e0) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %1 = cute.get_scalars(%itup) : !cute.int_tuple<"?">
    %itup_0 = cute.to_int_tuple(%e1) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %2 = cute.get_scalars(%itup_0) : !cute.int_tuple<"?">
    %itup_1 = cute.to_int_tuple(%e2) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %3 = cute.get_scalars(%itup_1) : !cute.int_tuple<"?">
    %shape = cute.make_shape(%itup, %itup_0, %itup_1) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.shape<"(?,?,?)">
    %4 = cute.static : !cute.int_tuple<"(0,0,0)">
    %5 = cute.static : !cute.stride<"(1@0,1@1,1@2)">
    %lay_2 = cute.make_layout(%shape, %5) : !cute.layout<"(?,?,?):(1@0,1@1,1@2)">
    %view = cute.make_view(%4, %lay_2) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">
    %iter = cute.get_iter(%arg0) : !memref_gmem_f32_6
    %lay_3 = cute.get_layout(%arg0) : !memref_gmem_f32_6
    %6:5 = cute.get_scalars(%lay_3) <{only_dynamic}> : !cute.layout<"(?,?,?):(?{i64},?{i64},1)">
    %c512_i32 = arith.constant 512 : i32
    %7 = arith.ceildivsi %6#1, %c512_i32 : i32
    %c512_i64 = arith.constant 512 : i64
    %8 = arith.muli %6#4, %c512_i64 : i64
    %shape_4 = cute.make_shape(%6#0, %7, %6#2) : (i32, i32, i32) -> !cute.shape<"((1,512,1),(?,?,?))">
    %iv = cute.assume(%8) : (i64) -> !cute.i64<divby 512>
    %stride = cute.make_stride(%6#4, %6#3, %iv) : (i64, i64, !cute.i64<divby 512>) -> !cute.stride<"((0,?{i64},0),(?{i64},?{i64 div=512},1))">
    %lay_5 = cute.make_layout(%shape_4, %stride) : !cute.layout<"((1,512,1),(?,?,?)):((0,?{i64},0),(?{i64},?{i64 div=512},1))">
    %view_6 = cute.make_view(%iter, %lay_5) : !memref_gmem_f32_
    %9 = cute.static : !cute.int_tuple<"(0,0,0)">
    %lay_7 = cute.get_layout(%view) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">
    %10:3 = cute.get_scalars(%lay_7) <{only_dynamic}> : !cute.layout<"(?,?,?):(1@0,1@1,1@2)">
    %c512_i32_8 = arith.constant 512 : i32
    %11 = arith.ceildivsi %10#1, %c512_i32_8 : i32
    %shape_9 = cute.make_shape(%10#0, %11, %10#2) : (i32, i32, i32) -> !cute.shape<"((1,512,1),(?,?,?))">
    %12 = cute.static : !cute.stride<"((0,1@1,0),(1@0,512@1,1@2))">
    %lay_10 = cute.make_layout(%shape_9, %12) : !cute.layout<"((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">
    %view_11 = cute.make_view(%9, %lay_10) : !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">
    %iter_12 = cute.get_iter(%arg1) : !memref_gmem_f8E4M3FN6
    %lay_13 = cute.get_layout(%arg1) : !memref_gmem_f8E4M3FN6
    %13:5 = cute.get_scalars(%lay_13) <{only_dynamic}> : !cute.layout<"(?,?{div=16},?):(?{div=16},1,?{div=16})">
    %c512_i32_14 = arith.constant 512 : i32
    %14 = arith.ceildivsi %13#1, %c512_i32_14 : i32
    %shape_15 = cute.make_shape(%13#0, %14, %13#2) : (i32, i32, i32) -> !cute.shape<"((1,512,1),(?,?,?))">
    %iv_16 = cute.assume(%13#3) : (i32) -> !cute.i32<divby 16>
    %iv_17 = cute.assume(%13#4) : (i32) -> !cute.i32<divby 16>
    %stride_18 = cute.make_stride(%iv_16, %iv_17) : (!cute.i32<divby 16>, !cute.i32<divby 16>) -> !cute.stride<"((0,1,0),(?{div=16},512,?{div=16}))">
    %lay_19 = cute.make_layout(%shape_15, %stride_18) : !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{div=16},512,?{div=16}))">
    %view_20 = cute.make_view(%iter_12, %lay_19) : !memref_gmem_f8E4M3FN
    %lay_21 = cute.get_layout(%view_6) : !memref_gmem_f32_
    %sz = cute.size(%lay_21) <{mode = [1]}> : (!cute.layout<"((1,512,1),(?,?,?)):((0,?{i64},0),(?{i64},?{i64 div=512},1))">) -> !cute.int_tuple<"?">
    %e0_22 = cute.get_leaves(%sz) : !cute.int_tuple<"?">
    %15 = cute.get_scalars(%e0_22) : !cute.int_tuple<"?">
    %16 = arith.index_cast %15 : i32 to index
    %c1 = arith.constant 1 : index
    %c128 = arith.constant 128 : index
    %c0_i32 = arith.constant 0 : i32
    gpu.launch_func  @kernels::@kernel_cutlass__convert_kernel_tensorptrf32gmemo1512100div5121_tensorptrf8E4M3FNgmemalign16o15121010div16512div16_tensor000o15121011010512112____Float32_Float8E4M3FN_0 blocks in (%16, %c1, %c1) threads in (%c128, %c1, %c1)  dynamic_shared_memory_size %c0_i32 args(%view_6 : !memref_gmem_f32_, %view_20 : !memref_gmem_f8E4M3FN, %view_11 : !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">, %1 : i32, %2 : i32, %3 : i32) {use_pdl = false}
    return
  }
}
