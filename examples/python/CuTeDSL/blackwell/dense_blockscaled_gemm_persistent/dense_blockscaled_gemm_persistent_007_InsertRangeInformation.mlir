!memref_gmem_f32_ = !cute.memref<f32, gmem, "((1,1024,1),(?,?,?)):((0,?{i64},0),(?{i64},?{i64 div=1024},1))">
!memref_gmem_f32_1 = !cute.memref<f32, gmem, "((1,1024,1)):((0,?{i64},0))">
!memref_gmem_f32_2 = !cute.memref<f32, gmem, "(128,8):(?{i64 div=8},?{i64})">
!memref_gmem_f32_3 = !cute.memref<f32, gmem, "(8):(?{i64})">
!memref_gmem_f32_4 = !cute.memref<f32, gmem, "(8,1):(?{i64},0)">
!memref_gmem_f32_5 = !cute.memref<f32, gmem, "(8,(1)):(?{i64},(0))">
!memref_gmem_f32_6 = !cute.memref<f32, gmem, "(?,?,?):(?{i64},?{i64},1)">
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
!memref_rmem_f32_3 = !cute.memref<f32, rmem, align<32>, "(8):(1)">
!memref_rmem_i8_ = !cute.memref<i8, rmem, align<32>, "4:1">
!memref_rmem_i8_1 = !cute.memref<i8, rmem, align<32>, "(4,1):(1,0)">
!memref_rmem_i8_2 = !cute.memref<i8, rmem, align<32>, "(4,(1)):(1,(0))">
!memref_rmem_i8_3 = !cute.memref<i8, rmem, align<32>, "(4):(1)">
#loop_unroll = #llvm.loop_unroll<disable = false, full = true>
#loop_annotation = #llvm.loop_annotation<unroll = #loop_unroll>
module attributes {gpu.container_module} {
  gpu.module @kernels {
    func.func public @kernel_cutlass__convert_kernel_tensorptrf32gmemo11024100div10241_tensorptri8gmemalign16o15121010512_tensor000o1102410110101024112____Float32_Float4E2M1FN_0(%arg0: !memref_gmem_f32_, %arg1: !memref_gmem_i8_, %arg2: !cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">, %arg3: i32, %arg4: i32, %arg5: i32) attributes {cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} {
      %0 = cute.static : !cute.layout<"(128,8):(8,1)">
      %1 = cute.static : !cute.layout<"(128,4):(4,1)">
      %2 = nvvm.read.ptx.sreg.tid.x range <i32, 0, 1024> : i32
      %3 = nvvm.read.ptx.sreg.ctaid.x range <i32, 0, 2147483647> : i32
      %coord = cute.make_coord(%3) : (i32) -> !cute.coord<"(_,?)">
      %lay = cute.get_layout(%arg0) : !memref_gmem_f32_
      %4:6 = cute.get_scalars(%lay) <{only_dynamic}> : !cute.layout<"((1,1024,1),(?,?,?)):((0,?{i64},0),(?{i64},?{i64 div=1024},1))">
      %5 = cute.static : !cute.shape<"((1,1024,1))">
      %stride = cute.make_stride(%4#3) : (i64) -> !cute.stride<"((0,?{i64},0))">
      %lay_0 = cute.make_layout(%5, %stride) : !cute.layout<"((1,1024,1)):((0,?{i64},0))">
      %idx = cute.crd2idx(%coord, %lay) : (!cute.coord<"(_,?)">, !cute.layout<"((1,1024,1),(?,?,?)):((0,?{i64},0),(?{i64},?{i64 div=1024},1))">) -> !cute.int_tuple<"?{i64}">
      %iter = cute.get_iter(%arg0) : !memref_gmem_f32_
      %ptr = cute.add_offset(%iter, %idx) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %view = cute.make_view(%ptr, %lay_0) : !memref_gmem_f32_1
      %coord_1 = cute.make_coord(%3) : (i32) -> !cute.coord<"(_,?)">
      %lay_2 = cute.get_layout(%arg1) : !memref_gmem_i8_
      %idx_3 = cute.crd2idx(%coord_1, %lay_2) : (!cute.coord<"(_,?)">, !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !cute.int_tuple<"?{i64}">
      %iter_4 = cute.get_iter(%arg1) : !memref_gmem_i8_
      %ptr_5 = cute.add_offset(%iter_4, %idx_3) : (!cute.ptr<i8, gmem, align<16>>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<i8, gmem>
      %view_6 = cute.make_view(%ptr_5) : !memref_gmem_i8_1
      %coord_7 = cute.make_coord(%3) : (i32) -> !cute.coord<"(_,?)">
      %lay_8 = cute.get_layout(%arg2) : !cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">
      %idx_9 = cute.crd2idx(%coord_7, %lay_8) : (!cute.coord<"(_,?)">, !cute.layout<"((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">) -> !cute.int_tuple<"(?,?{div=1024},?)">
      %6 = cute.static : !cute.int_tuple<"(0,0,0)">
      %tup = cute.add_offset(%6, %idx_9) : (!cute.int_tuple<"(0,0,0)">, !cute.int_tuple<"(?,?{div=1024},?)">) -> !cute.int_tuple<"(?,?{div=1024},?)">
      %view_10 = cute.make_view(%tup) : !cute.coord_tensor<"(?,?{div=1024},?)", "((1,1024,1)):((0,1@1,0))">
      %iter_11 = cute.get_iter(%view) : !memref_gmem_f32_1
      %lay_12 = cute.get_layout(%view) : !memref_gmem_f32_1
      %7 = cute.get_scalars(%lay_12) <{only_dynamic}> : !cute.layout<"((1,1024,1)):((0,?{i64},0))">
      %c8_i64 = arith.constant 8 : i64
      %8 = arith.muli %7, %c8_i64 : i64
      %9 = cute.static : !cute.shape<"(128,8)">
      %iv = cute.assume(%8) : (i64) -> !cute.i64<divby 8>
      %stride_13 = cute.make_stride(%iv, %7) : (!cute.i64<divby 8>, i64) -> !cute.stride<"(?{i64 div=8},?{i64})">
      %lay_14 = cute.make_layout(%9, %stride_13) : !cute.layout<"(128,8):(?{i64 div=8},?{i64})">
      %view_15 = cute.make_view(%iter_11, %lay_14) : !memref_gmem_f32_2
      %iter_16 = cute.get_iter(%view_6) : !memref_gmem_i8_1
      %view_17 = cute.make_view(%iter_16) : !memref_gmem_i8_2
      %iter_18 = cute.get_iter(%view_10) : !cute.coord_tensor<"(?,?{div=1024},?)", "((1,1024,1)):((0,1@1,0))">
      %view_19 = cute.make_view(%iter_18) : !cute.coord_tensor<"(?,?{div=1024},?)", "(128,8):(8@1,1@1)">
      %coord_20 = cute.make_coord(%2) : (i32) -> !cute.coord<"(?,_)">
      %lay_21 = cute.get_layout(%view_15) : !memref_gmem_f32_2
      %10:2 = cute.get_scalars(%lay_21) <{only_dynamic}> : !cute.layout<"(128,8):(?{i64 div=8},?{i64})">
      %11 = cute.static : !cute.shape<"(8)">
      %stride_22 = cute.make_stride(%10#1) : (i64) -> !cute.stride<"(?{i64})">
      %lay_23 = cute.make_layout(%11, %stride_22) : !cute.layout<"(8):(?{i64})">
      %idx_24 = cute.crd2idx(%coord_20, %lay_21) : (!cute.coord<"(?,_)">, !cute.layout<"(128,8):(?{i64 div=8},?{i64})">) -> !cute.int_tuple<"?{i64 div=8}">
      %iter_25 = cute.get_iter(%view_15) : !memref_gmem_f32_2
      %ptr_26 = cute.add_offset(%iter_25, %idx_24) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=8}">) -> !cute.ptr<f32, gmem>
      %view_27 = cute.make_view(%ptr_26, %lay_23) : !memref_gmem_f32_3
      %iter_28 = cute.get_iter(%view_27) : !memref_gmem_f32_3
      %coord_29 = cute.make_coord(%2) : (i32) -> !cute.coord<"(?,_)">
      %12 = cute.static : !cute.layout<"(128,4):(4,1)">
      %idx_30 = cute.crd2idx(%coord_29, %12) : (!cute.coord<"(?,_)">, !cute.layout<"(128,4):(4,1)">) -> !cute.int_tuple<"?{div=4}">
      %iter_31 = cute.get_iter(%view_17) : !memref_gmem_i8_2
      %ptr_32 = cute.add_offset(%iter_31, %idx_30) : (!cute.ptr<i8, gmem>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<i8, gmem>
      %view_33 = cute.make_view(%ptr_32) : !memref_gmem_i8_3
      %iter_34 = cute.get_iter(%view_33) : !memref_gmem_i8_3
      %coord_35 = cute.make_coord(%2) : (i32) -> !cute.coord<"(?,_)">
      %13 = cute.static : !cute.layout<"(128,8):(8@1,1@1)">
      %idx_36 = cute.crd2idx(%coord_35, %13) : (!cute.coord<"(?,_)">, !cute.layout<"(128,8):(8@1,1@1)">) -> !cute.int_tuple<"(0,?{div=8})">
      %iter_37 = cute.get_iter(%view_19) : !cute.coord_tensor<"(?,?{div=1024},?)", "(128,8):(8@1,1@1)">
      %tup_38 = cute.add_offset(%iter_37, %idx_36) : (!cute.int_tuple<"(?,?{div=1024},?)">, !cute.int_tuple<"(0,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8},?)">
      %view_39 = cute.make_view(%tup_38) : !cute.coord_tensor<"(?,?{div=8},?)", "(8):(1@1)">
      %14 = cute.static : !cute.int_tuple<"(0,0)">
      %iter_40 = cute.get_iter(%view_39) : !cute.coord_tensor<"(?,?{div=8},?)", "(8):(1@1)">
      %tup_41 = cute.add_offset(%iter_40, %14) : (!cute.int_tuple<"(?,?{div=8},?)">, !cute.int_tuple<"(0,0)">) -> !cute.int_tuple<"(?,?{div=8},?)">
      %view_42 = cute.make_view(%tup_41) : !cute.coord_tensor<"(?,?{div=8},?)", "():()">
      %iter_43 = cute.get_iter(%view_42) : !cute.coord_tensor<"(?,?{div=8},?)", "():()">
      %e0, %e1, %e2 = cute.get_leaves(%iter_43) : !cute.int_tuple<"(?,?{div=8},?)">
      %coord_44 = cute.make_coord(%e0, %e1, %e2) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?{div=8},?)">
      %coord_45 = cute.make_coord(%arg3, %arg4, %arg5) : (i32, i32, i32) -> !cute.coord<"(?,?,?)">
      %15:3 = cute.get_scalars(%coord_44) : !cute.coord<"(?,?{div=8},?)">
      %16:3 = cute.get_scalars(%coord_45) : !cute.coord<"(?,?,?)">
      %true = arith.constant true
      %17 = arith.cmpi slt, %15#0, %16#0 : i32
      %18 = arith.andi %true, %17 : i1
      %19 = arith.cmpi slt, %15#1, %16#1 : i32
      %20 = arith.andi %18, %19 : i1
      %21 = arith.cmpi slt, %15#2, %16#2 : i32
      %22 = arith.andi %20, %21 : i1
      scf.if %22 {
        %23 = cute.static : !cute.layout<"8:1">
        %rmem = cute.memref.alloca(%23) : !memref_rmem_f32_
        %iter_46 = cute.get_iter(%rmem) : !memref_rmem_f32_
        %24 = cute.static : !cute.layout<"4:1">
        %rmem_47 = cute.memref.alloca(%24) : !memref_rmem_i8_
        %iter_48 = cute.get_iter(%rmem_47) : !memref_rmem_i8_
        %lay_49 = cute.get_layout(%view_27) : !memref_gmem_f32_3
        %25 = cute.static : !cute.layout<"1:0">
        %append = cute.append_to_rank<2> (%lay_49, %25) : !cute.layout<"(8):(?{i64})">, !cute.layout<"1:0">
        %view_50 = cute.make_view(%iter_28, %append) : !memref_gmem_f32_4
        %iter_51 = cute.get_iter(%view_50) : !memref_gmem_f32_4
        %lay_52 = cute.get_layout(%view_50) : !memref_gmem_f32_4
        %26 = cute.get_scalars(%lay_52) <{only_dynamic}> : !cute.layout<"(8,1):(?{i64},0)">
        %27 = cute.static : !cute.shape<"(8,(1))">
        %stride_53 = cute.make_stride(%26) : (i64) -> !cute.stride<"(?{i64},(0))">
        %lay_54 = cute.make_layout(%27, %stride_53) : !cute.layout<"(8,(1)):(?{i64},(0))">
        %view_55 = cute.make_view(%iter_51, %lay_54) : !memref_gmem_f32_5
        %28 = cute.static : !cute.layout<"(8,1):(1,0)">
        %view_56 = cute.make_view(%iter_46, %28) : !memref_rmem_f32_1
        %iter_57 = cute.get_iter(%view_56) : !memref_rmem_f32_1
        %view_58 = cute.make_view(%iter_57) : !memref_rmem_f32_2
        %29 = cute.static : !cute.layout<"1:0">
        %iter_59 = cute.get_iter(%view_55) : !memref_gmem_f32_5
        %iter_60 = cute.get_iter(%view_58) : !memref_rmem_f32_2
        %lay_61 = cute.get_layout(%view_55) : !memref_gmem_f32_5
        %append_62 = cute.append_to_rank<2> (%lay_61, %29) : !cute.layout<"(8,(1)):(?{i64},(0))">, !cute.layout<"1:0">
        %30 = cute.get_scalars(%append_62) <{only_dynamic}> : !cute.layout<"(8,(1)):(?{i64},(0))">
        %31 = cute.static : !cute.shape<"(8,((1)))">
        %stride_63 = cute.make_stride(%30) : (i64) -> !cute.stride<"(?{i64},((0)))">
        %lay_64 = cute.make_layout(%31, %stride_63) : !cute.layout<"(8,((1))):(?{i64},((0)))">
        %32 = cute.static : !cute.int_tuple<"1">
        %33 = cute.get_scalars(%32) : !cute.int_tuple<"1">
        %c0_i32 = arith.constant 0 : i32
        %c1_i32 = arith.constant 1 : i32
        scf.for %arg6 = %c0_i32 to %33 step %c1_i32  : i32 {
          %45 = cute.get_scalars(%lay_64) <{only_dynamic}> : !cute.layout<"(8,((1))):(?{i64},((0)))">
          %46 = cute.static : !cute.shape<"(8)">
          %stride_75 = cute.make_stride(%45) : (i64) -> !cute.stride<"(?{i64})">
          %lay_76 = cute.make_layout(%46, %stride_75) : !cute.layout<"(8):(?{i64})">
          %47 = cute.static : !cute.int_tuple<"0">
          %ptr_77 = cute.add_offset(%iter_59, %47) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<f32, gmem>
          %view_78 = cute.make_view(%ptr_77, %lay_76) : !memref_gmem_f32_3
          %48 = cute.static : !cute.layout<"(8):(1)">
          %49 = cute.static : !cute.int_tuple<"0">
          %ptr_79 = cute.add_offset(%iter_60, %49) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, rmem, align<32>>
          %view_80 = cute.make_view(%ptr_79, %48) : !memref_rmem_f32_3
          %iter_81 = cute.get_iter(%view_78) : !memref_gmem_f32_3
          %lay_82 = cute.get_layout(%view_78) : !memref_gmem_f32_3
          %50 = cute.get_scalars(%lay_82) <{only_dynamic}> : !cute.layout<"(8):(?{i64})">
          %iter_83 = cute.get_iter(%view_80) : !memref_rmem_f32_3
          %51 = builtin.unrealized_conversion_cast %iter_81 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %52 = builtin.unrealized_conversion_cast %iter_83 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
          %53 = llvm.load %51 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %53, %52 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          %int_tuple = cute.make_int_tuple(%50) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_84 = cute.add_offset(%iter_81, %int_tuple) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %54 = cute.static : !cute.int_tuple<"1">
          %ptr_85 = cute.add_offset(%iter_83, %54) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
          %55 = builtin.unrealized_conversion_cast %ptr_84 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %56 = builtin.unrealized_conversion_cast %ptr_85 : !cute.ptr<f32, rmem> to !llvm.ptr
          %57 = llvm.load %55 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %57, %56 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          %c2_i64 = arith.constant 2 : i64
          %58 = arith.muli %50, %c2_i64 : i64
          %iv_86 = cute.assume(%58) : (i64) -> !cute.i64<divby 2>
          %int_tuple_87 = cute.make_int_tuple(%iv_86) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
          %ptr_88 = cute.add_offset(%iter_81, %int_tuple_87) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
          %59 = cute.static : !cute.int_tuple<"2">
          %ptr_89 = cute.add_offset(%iter_83, %59) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
          %60 = builtin.unrealized_conversion_cast %ptr_88 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %61 = builtin.unrealized_conversion_cast %ptr_89 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %62 = llvm.load %60 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %62, %61 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          %c3_i64 = arith.constant 3 : i64
          %63 = arith.muli %50, %c3_i64 : i64
          %iv_90 = cute.assume(%63) : (i64) -> !cute.i64<divby 3>
          %int_tuple_91 = cute.make_int_tuple(%iv_90) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
          %ptr_92 = cute.add_offset(%iter_81, %int_tuple_91) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
          %64 = cute.static : !cute.int_tuple<"3">
          %ptr_93 = cute.add_offset(%iter_83, %64) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
          %65 = builtin.unrealized_conversion_cast %ptr_92 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %66 = builtin.unrealized_conversion_cast %ptr_93 : !cute.ptr<f32, rmem> to !llvm.ptr
          %67 = llvm.load %65 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %67, %66 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          %c4_i64 = arith.constant 4 : i64
          %68 = arith.muli %50, %c4_i64 : i64
          %iv_94 = cute.assume(%68) : (i64) -> !cute.i64<divby 4>
          %int_tuple_95 = cute.make_int_tuple(%iv_94) : (!cute.i64<divby 4>) -> !cute.int_tuple<"?{i64 div=4}">
          %ptr_96 = cute.add_offset(%iter_81, %int_tuple_95) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=4}">) -> !cute.ptr<f32, gmem>
          %69 = cute.static : !cute.int_tuple<"4">
          %ptr_97 = cute.add_offset(%iter_83, %69) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
          %70 = builtin.unrealized_conversion_cast %ptr_96 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %71 = builtin.unrealized_conversion_cast %ptr_97 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
          %72 = llvm.load %70 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %72, %71 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          %c5_i64 = arith.constant 5 : i64
          %73 = arith.muli %50, %c5_i64 : i64
          %iv_98 = cute.assume(%73) : (i64) -> !cute.i64<divby 5>
          %int_tuple_99 = cute.make_int_tuple(%iv_98) : (!cute.i64<divby 5>) -> !cute.int_tuple<"?{i64 div=5}">
          %ptr_100 = cute.add_offset(%iter_81, %int_tuple_99) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=5}">) -> !cute.ptr<f32, gmem>
          %74 = cute.static : !cute.int_tuple<"5">
          %ptr_101 = cute.add_offset(%iter_83, %74) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<f32, rmem>
          %75 = builtin.unrealized_conversion_cast %ptr_100 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %76 = builtin.unrealized_conversion_cast %ptr_101 : !cute.ptr<f32, rmem> to !llvm.ptr
          %77 = llvm.load %75 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %77, %76 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          %c6_i64 = arith.constant 6 : i64
          %78 = arith.muli %50, %c6_i64 : i64
          %iv_102 = cute.assume(%78) : (i64) -> !cute.i64<divby 6>
          %int_tuple_103 = cute.make_int_tuple(%iv_102) : (!cute.i64<divby 6>) -> !cute.int_tuple<"?{i64 div=6}">
          %ptr_104 = cute.add_offset(%iter_81, %int_tuple_103) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=6}">) -> !cute.ptr<f32, gmem>
          %79 = cute.static : !cute.int_tuple<"6">
          %ptr_105 = cute.add_offset(%iter_83, %79) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
          %80 = builtin.unrealized_conversion_cast %ptr_104 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %81 = builtin.unrealized_conversion_cast %ptr_105 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %82 = llvm.load %80 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %82, %81 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          %c7_i64 = arith.constant 7 : i64
          %83 = arith.muli %50, %c7_i64 : i64
          %iv_106 = cute.assume(%83) : (i64) -> !cute.i64<divby 7>
          %int_tuple_107 = cute.make_int_tuple(%iv_106) : (!cute.i64<divby 7>) -> !cute.int_tuple<"?{i64 div=7}">
          %ptr_108 = cute.add_offset(%iter_81, %int_tuple_107) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=7}">) -> !cute.ptr<f32, gmem>
          %84 = cute.static : !cute.int_tuple<"7">
          %ptr_109 = cute.add_offset(%iter_83, %84) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<f32, rmem>
          %85 = builtin.unrealized_conversion_cast %ptr_108 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %86 = builtin.unrealized_conversion_cast %ptr_109 : !cute.ptr<f32, rmem> to !llvm.ptr
          %87 = llvm.load %85 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %87, %86 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %34 = cute.memref.load_vec %rmem, row_major : !memref_rmem_f32_
        %35 = nvgpu.cvt_fptrunc %34 : vector<8xf32> to vector<8xf4E2M1FN>
        %36 = cute.static : !cute.layout<"8:1">
        %37 = cute.recast_layout<8, 4> (%36) : !cute.layout<"8:1"> to !cute.layout<"4:1">
        %38 = builtin.unrealized_conversion_cast %35 : vector<8xf4E2M1FN> to vector<8xi4>
        %39 = vector.bitcast %38 : vector<8xi4> to vector<4xi8>
        cute.memref.store_vec %39, %rmem_47, row_major : !memref_rmem_i8_
        %40 = cute.static : !cute.layout<"(4,1):(1,0)">
        %view_65 = cute.make_view(%iter_48, %40) : !memref_rmem_i8_1
        %iter_66 = cute.get_iter(%view_65) : !memref_rmem_i8_1
        %view_67 = cute.make_view(%iter_66) : !memref_rmem_i8_2
        %41 = cute.static : !cute.layout<"(4,1):(1,0)">
        %view_68 = cute.make_view(%iter_34, %41) : !memref_gmem_i8_4
        %iter_69 = cute.get_iter(%view_68) : !memref_gmem_i8_4
        %view_70 = cute.make_view(%iter_69) : !memref_gmem_i8_5
        %42 = cute.static : !cute.layout<"1:0">
        %iter_71 = cute.get_iter(%view_67) : !memref_rmem_i8_2
        %iter_72 = cute.get_iter(%view_70) : !memref_gmem_i8_5
        %43 = cute.static : !cute.int_tuple<"1">
        %44 = cute.get_scalars(%43) : !cute.int_tuple<"1">
        %c0_i32_73 = arith.constant 0 : i32
        %c1_i32_74 = arith.constant 1 : i32
        scf.for %arg6 = %c0_i32_73 to %44 step %c1_i32_74  : i32 {
          %45 = cute.static : !cute.layout<"(4):(1)">
          %46 = cute.static : !cute.int_tuple<"0">
          %ptr_75 = cute.add_offset(%iter_71, %46) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
          %view_76 = cute.make_view(%ptr_75, %45) : !memref_rmem_i8_3
          %47 = cute.static : !cute.layout<"(4):(1)">
          %48 = cute.static : !cute.int_tuple<"0">
          %ptr_77 = cute.add_offset(%iter_72, %48) : (!cute.ptr<i8, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<i8, gmem>
          %view_78 = cute.make_view(%ptr_77, %47) : !memref_gmem_i8_3
          %iter_79 = cute.get_iter(%view_76) : !memref_rmem_i8_3
          %iter_80 = cute.get_iter(%view_78) : !memref_gmem_i8_3
          %49 = builtin.unrealized_conversion_cast %iter_79 : !cute.ptr<i8, rmem, align<32>> to !llvm.ptr
          %50 = builtin.unrealized_conversion_cast %iter_80 : !cute.ptr<i8, gmem> to !llvm.ptr<1>
          %51 = llvm.load %49 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
          llvm.store %51, %50 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
          %52 = cute.static : !cute.int_tuple<"1">
          %ptr_81 = cute.add_offset(%iter_79, %52) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
          %53 = cute.static : !cute.int_tuple<"1">
          %ptr_82 = cute.add_offset(%iter_80, %53) : (!cute.ptr<i8, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<i8, gmem>
          %54 = builtin.unrealized_conversion_cast %ptr_81 : !cute.ptr<i8, rmem> to !llvm.ptr
          %55 = builtin.unrealized_conversion_cast %ptr_82 : !cute.ptr<i8, gmem> to !llvm.ptr<1>
          %56 = llvm.load %54 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
          llvm.store %56, %55 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
          %57 = cute.static : !cute.int_tuple<"2">
          %ptr_83 = cute.add_offset(%iter_79, %57) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem, align<2>>
          %58 = cute.static : !cute.int_tuple<"2">
          %ptr_84 = cute.add_offset(%iter_80, %58) : (!cute.ptr<i8, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<i8, gmem>
          %59 = builtin.unrealized_conversion_cast %ptr_83 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
          %60 = builtin.unrealized_conversion_cast %ptr_84 : !cute.ptr<i8, gmem> to !llvm.ptr<1>
          %61 = llvm.load %59 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
          llvm.store %61, %60 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
          %62 = cute.static : !cute.int_tuple<"3">
          %ptr_85 = cute.add_offset(%iter_79, %62) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
          %63 = cute.static : !cute.int_tuple<"3">
          %ptr_86 = cute.add_offset(%iter_80, %63) : (!cute.ptr<i8, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<i8, gmem>
          %64 = builtin.unrealized_conversion_cast %ptr_85 : !cute.ptr<i8, rmem> to !llvm.ptr
          %65 = builtin.unrealized_conversion_cast %ptr_86 : !cute.ptr<i8, gmem> to !llvm.ptr<1>
          %66 = llvm.load %64 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
          llvm.store %66, %65 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
        } {llvm.loop_annotation = #loop_annotation}
      }
      return
    }
  }
  func.func @cutlass__convert_Tensorgmemoi64i641_Tensorgmemoi641i64_1_8(%arg0: !memref_gmem_f32_6, %arg1: !memref_gmem_f4E2M1FN) attributes {llvm.emit_c_interface} {
    %iter = cute.get_iter(%arg1) : !memref_gmem_f4E2M1FN
    %0 = cute.static : !cute.layout<"(128,8):(8,1)">
    %1 = cute.recast_layout<8, 4> (%0) : !cute.layout<"(128,8):(8,1)"> to !cute.layout<"(128,4):(4,1)">
    %iter_0 = cute.recast_iter(%iter) : !cute.ptr<f4E2M1FN, gmem, align<16>> to !cute.ptr<i8, gmem, align<16>>
    %lay = cute.get_layout(%arg1) : !memref_gmem_f4E2M1FN
    %2 = cute.recast_layout<8, 4> (%lay) : !cute.layout<"(?,?,?):(?{i64},1,?{i64})"> to !cute.layout<"(?,?,?):(?{i64},1,?{i64})">
    %view = cute.make_view(%iter_0, %2) : !memref_gmem_i8_6
    %lay_1 = cute.get_layout(%arg0) : !memref_gmem_f32_6
    %3 = cute.get_shape(%lay_1) : (!cute.layout<"(?,?,?):(?{i64},?{i64},1)">) -> !cute.shape<"(?,?,?)">
    %e0, %e1, %e2 = cute.get_leaves(%3) : !cute.shape<"(?,?,?)">
    %itup = cute.to_int_tuple(%e0) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %4 = cute.get_scalars(%itup) : !cute.int_tuple<"?">
    %itup_2 = cute.to_int_tuple(%e1) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %5 = cute.get_scalars(%itup_2) : !cute.int_tuple<"?">
    %itup_3 = cute.to_int_tuple(%e2) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %6 = cute.get_scalars(%itup_3) : !cute.int_tuple<"?">
    %shape = cute.make_shape(%itup, %itup_2, %itup_3) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.shape<"(?,?,?)">
    %7 = cute.static : !cute.int_tuple<"(0,0,0)">
    %8 = cute.static : !cute.stride<"(1@0,1@1,1@2)">
    %lay_4 = cute.make_layout(%shape, %8) : !cute.layout<"(?,?,?):(1@0,1@1,1@2)">
    %view_5 = cute.make_view(%7, %lay_4) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">
    %iter_6 = cute.get_iter(%arg0) : !memref_gmem_f32_6
    %lay_7 = cute.get_layout(%arg0) : !memref_gmem_f32_6
    %9:5 = cute.get_scalars(%lay_7) <{only_dynamic}> : !cute.layout<"(?,?,?):(?{i64},?{i64},1)">
    %c1024_i32 = arith.constant 1024 : i32
    %10 = arith.ceildivsi %9#1, %c1024_i32 : i32
    %c1024_i64 = arith.constant 1024 : i64
    %11 = arith.muli %9#4, %c1024_i64 : i64
    %shape_8 = cute.make_shape(%9#0, %10, %9#2) : (i32, i32, i32) -> !cute.shape<"((1,1024,1),(?,?,?))">
    %iv = cute.assume(%11) : (i64) -> !cute.i64<divby 1024>
    %stride = cute.make_stride(%9#4, %9#3, %iv) : (i64, i64, !cute.i64<divby 1024>) -> !cute.stride<"((0,?{i64},0),(?{i64},?{i64 div=1024},1))">
    %lay_9 = cute.make_layout(%shape_8, %stride) : !cute.layout<"((1,1024,1),(?,?,?)):((0,?{i64},0),(?{i64},?{i64 div=1024},1))">
    %view_10 = cute.make_view(%iter_6, %lay_9) : !memref_gmem_f32_
    %12 = cute.static : !cute.int_tuple<"(0,0,0)">
    %lay_11 = cute.get_layout(%view_5) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">
    %13:3 = cute.get_scalars(%lay_11) <{only_dynamic}> : !cute.layout<"(?,?,?):(1@0,1@1,1@2)">
    %c1024_i32_12 = arith.constant 1024 : i32
    %14 = arith.ceildivsi %13#1, %c1024_i32_12 : i32
    %shape_13 = cute.make_shape(%13#0, %14, %13#2) : (i32, i32, i32) -> !cute.shape<"((1,1024,1),(?,?,?))">
    %15 = cute.static : !cute.stride<"((0,1@1,0),(1@0,1024@1,1@2))">
    %lay_14 = cute.make_layout(%shape_13, %15) : !cute.layout<"((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">
    %view_15 = cute.make_view(%12, %lay_14) : !cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">
    %iter_16 = cute.get_iter(%view) : !memref_gmem_i8_6
    %lay_17 = cute.get_layout(%view) : !memref_gmem_i8_6
    %16:5 = cute.get_scalars(%lay_17) <{only_dynamic}> : !cute.layout<"(?,?,?):(?{i64},1,?{i64})">
    %c512_i32 = arith.constant 512 : i32
    %17 = arith.ceildivsi %16#1, %c512_i32 : i32
    %shape_18 = cute.make_shape(%16#0, %17, %16#2) : (i32, i32, i32) -> !cute.shape<"((1,512,1),(?,?,?))">
    %stride_19 = cute.make_stride(%16#3, %16#4) : (i64, i64) -> !cute.stride<"((0,1,0),(?{i64},512,?{i64}))">
    %lay_20 = cute.make_layout(%shape_18, %stride_19) : !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">
    %view_21 = cute.make_view(%iter_16, %lay_20) : !memref_gmem_i8_
    %lay_22 = cute.get_layout(%view_10) : !memref_gmem_f32_
    %sz = cute.size(%lay_22) <{mode = [1]}> : (!cute.layout<"((1,1024,1),(?,?,?)):((0,?{i64},0),(?{i64},?{i64 div=1024},1))">) -> !cute.int_tuple<"?">
    %e0_23 = cute.get_leaves(%sz) : !cute.int_tuple<"?">
    %18 = cute.get_scalars(%e0_23) : !cute.int_tuple<"?">
    %19 = arith.index_cast %18 : i32 to index
    %c1 = arith.constant 1 : index
    %c128 = arith.constant 128 : index
    %c0_i32 = arith.constant 0 : i32
    gpu.launch_func  @kernels::@kernel_cutlass__convert_kernel_tensorptrf32gmemo11024100div10241_tensorptri8gmemalign16o15121010512_tensor000o1102410110101024112____Float32_Float4E2M1FN_0 blocks in (%19, %c1, %c1) threads in (%c128, %c1, %c1)  dynamic_shared_memory_size %c0_i32 args(%view_10 : !memref_gmem_f32_, %view_21 : !memref_gmem_i8_, %view_15 : !cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">, %4 : i32, %5 : i32, %6 : i32) {use_pdl = false}
    return
  }
}
