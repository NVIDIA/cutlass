!memref_gmem_f32_ = !cute.memref<f32, gmem, "((1,1024,1),(?,?,?)):((0,?{i64},0),(?{i64},?{i64 div=1024},1))">
!memref_gmem_f32_1 = !cute.memref<f32, gmem, "(?,?,?):(?{i64},?{i64},1)">
!memref_gmem_f4E2M1FN = !cute.memref<f4E2M1FN, gmem, align<16>, "(?,?,?):(?{i64},1,?{i64})">
!memref_gmem_i8_ = !cute.memref<i8, gmem, align<16>, "((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">
!memref_rmem_f32_ = !cute.memref<f32, rmem, align<32>, "8:1">
!memref_rmem_i8_ = !cute.memref<i8, rmem, align<32>, "4:1">
#loop_unroll = #llvm.loop_unroll<disable = false, full = true>
#loop_annotation = #llvm.loop_annotation<unroll = #loop_unroll>
module attributes {gpu.container_module} {
  gpu.module @kernels {
    func.func public @kernel_cutlass__convert_kernel_tensorptrf32gmemo11024100div10241_tensorptri8gmemalign16o15121010512_tensor000o1102410110101024112____Float32_Float4E2M1FN_0(%arg0: !memref_gmem_f32_, %arg1: !memref_gmem_i8_, %arg2: !cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">, %arg3: i32, %arg4: i32, %arg5: i32) attributes {cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} {
      %0 = cute.static : !cute.int_tuple<"7">
      %c7_i64 = arith.constant 7 : i64
      %1 = cute.static : !cute.int_tuple<"6">
      %c6_i64 = arith.constant 6 : i64
      %2 = cute.static : !cute.int_tuple<"5">
      %c5_i64 = arith.constant 5 : i64
      %3 = cute.static : !cute.int_tuple<"4">
      %c4_i64 = arith.constant 4 : i64
      %4 = cute.static : !cute.int_tuple<"3">
      %c3_i64 = arith.constant 3 : i64
      %5 = cute.static : !cute.int_tuple<"2">
      %c2_i64 = arith.constant 2 : i64
      %c1_i32 = arith.constant 1 : i32
      %c0_i32 = arith.constant 0 : i32
      %6 = cute.static : !cute.int_tuple<"1">
      %7 = cute.static : !cute.shape<"(8,((1)))">
      %8 = cute.static : !cute.shape<"(8,(1))">
      %9 = cute.static : !cute.layout<"1:0">
      %10 = cute.static : !cute.layout<"8:1">
      %11 = cute.static : !cute.layout<"(128,8):(8@1,1@1)">
      %12 = cute.static : !cute.shape<"(8)">
      %13 = cute.static : !cute.shape<"(128,8)">
      %c8_i64 = arith.constant 8 : i64
      %14 = cute.static : !cute.int_tuple<"(0,0,0)">
      %15 = cute.static : !cute.shape<"((1,1024,1))">
      %16 = cute.static : !cute.layout<"(128,4):(4,1)">
      %17 = nvvm.read.ptx.sreg.tid.x range <i32, 0, 1024> : i32
      %18 = nvvm.read.ptx.sreg.ctaid.x range <i32, 0, 2147483647> : i32
      %coord = cute.make_coord(%18) : (i32) -> !cute.coord<"(_,?)">
      %lay = cute.get_layout(%arg0) : !memref_gmem_f32_
      %19:6 = cute.get_scalars(%lay) <{only_dynamic}> : !cute.layout<"((1,1024,1),(?,?,?)):((0,?{i64},0),(?{i64},?{i64 div=1024},1))">
      %stride = cute.make_stride(%19#3) : (i64) -> !cute.stride<"((0,?{i64},0))">
      %lay_0 = cute.make_layout(%15, %stride) : !cute.layout<"((1,1024,1)):((0,?{i64},0))">
      %idx = cute.crd2idx(%coord, %lay) : (!cute.coord<"(_,?)">, !cute.layout<"((1,1024,1),(?,?,?)):((0,?{i64},0),(?{i64},?{i64 div=1024},1))">) -> !cute.int_tuple<"?{i64}">
      %iter = cute.get_iter(%arg0) : !memref_gmem_f32_
      %ptr = cute.add_offset(%iter, %idx) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %coord_1 = cute.make_coord(%18) : (i32) -> !cute.coord<"(_,?)">
      %lay_2 = cute.get_layout(%arg1) : !memref_gmem_i8_
      %idx_3 = cute.crd2idx(%coord_1, %lay_2) : (!cute.coord<"(_,?)">, !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !cute.int_tuple<"?{i64}">
      %iter_4 = cute.get_iter(%arg1) : !memref_gmem_i8_
      %ptr_5 = cute.add_offset(%iter_4, %idx_3) : (!cute.ptr<i8, gmem, align<16>>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<i8, gmem>
      %coord_6 = cute.make_coord(%18) : (i32) -> !cute.coord<"(_,?)">
      %lay_7 = cute.get_layout(%arg2) : !cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">
      %idx_8 = cute.crd2idx(%coord_6, %lay_7) : (!cute.coord<"(_,?)">, !cute.layout<"((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">) -> !cute.int_tuple<"(?,?{div=1024},?)">
      %tup = cute.add_offset(%14, %idx_8) : (!cute.int_tuple<"(0,0,0)">, !cute.int_tuple<"(?,?{div=1024},?)">) -> !cute.int_tuple<"(?,?{div=1024},?)">
      %20 = cute.get_scalars(%lay_0) <{only_dynamic}> : !cute.layout<"((1,1024,1)):((0,?{i64},0))">
      %21 = arith.muli %20, %c8_i64 : i64
      %iv = cute.assume(%21) : (i64) -> !cute.i64<divby 8>
      %stride_9 = cute.make_stride(%iv, %20) : (!cute.i64<divby 8>, i64) -> !cute.stride<"(?{i64 div=8},?{i64})">
      %lay_10 = cute.make_layout(%13, %stride_9) : !cute.layout<"(128,8):(?{i64 div=8},?{i64})">
      %coord_11 = cute.make_coord(%17) : (i32) -> !cute.coord<"(?,_)">
      %22:2 = cute.get_scalars(%lay_10) <{only_dynamic}> : !cute.layout<"(128,8):(?{i64 div=8},?{i64})">
      %stride_12 = cute.make_stride(%22#1) : (i64) -> !cute.stride<"(?{i64})">
      %lay_13 = cute.make_layout(%12, %stride_12) : !cute.layout<"(8):(?{i64})">
      %idx_14 = cute.crd2idx(%coord_11, %lay_10) : (!cute.coord<"(?,_)">, !cute.layout<"(128,8):(?{i64 div=8},?{i64})">) -> !cute.int_tuple<"?{i64 div=8}">
      %ptr_15 = cute.add_offset(%ptr, %idx_14) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=8}">) -> !cute.ptr<f32, gmem>
      %coord_16 = cute.make_coord(%17) : (i32) -> !cute.coord<"(?,_)">
      %idx_17 = cute.crd2idx(%coord_16, %16) : (!cute.coord<"(?,_)">, !cute.layout<"(128,4):(4,1)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_18 = cute.add_offset(%ptr_5, %idx_17) : (!cute.ptr<i8, gmem>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<i8, gmem>
      %coord_19 = cute.make_coord(%17) : (i32) -> !cute.coord<"(?,_)">
      %idx_20 = cute.crd2idx(%coord_19, %11) : (!cute.coord<"(?,_)">, !cute.layout<"(128,8):(8@1,1@1)">) -> !cute.int_tuple<"(0,?{div=8})">
      %tup_21 = cute.add_offset(%tup, %idx_20) : (!cute.int_tuple<"(?,?{div=1024},?)">, !cute.int_tuple<"(0,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8},?)">
      %e0, %e1, %e2 = cute.get_leaves(%tup_21) : !cute.int_tuple<"(?,?{div=8},?)">
      %coord_22 = cute.make_coord(%e0, %e1, %e2) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?{div=8},?)">
      %coord_23 = cute.make_coord(%arg3, %arg4, %arg5) : (i32, i32, i32) -> !cute.coord<"(?,?,?)">
      %23:3 = cute.get_scalars(%coord_22) : !cute.coord<"(?,?{div=8},?)">
      %24:3 = cute.get_scalars(%coord_23) : !cute.coord<"(?,?,?)">
      %25 = arith.cmpi slt, %23#0, %24#0 : i32
      %26 = arith.cmpi slt, %23#1, %24#1 : i32
      %27 = arith.andi %25, %26 : i1
      %28 = arith.cmpi slt, %23#2, %24#2 : i32
      %29 = arith.andi %27, %28 : i1
      scf.if %29 {
        %rmem = cute.memref.alloca() : !memref_rmem_f32_
        %iter_24 = cute.get_iter(%rmem) : !memref_rmem_f32_
        %rmem_25 = cute.memref.alloca() : !memref_rmem_i8_
        %iter_26 = cute.get_iter(%rmem_25) : !memref_rmem_i8_
        %append = cute.append_to_rank<2> (%lay_13, %9) : !cute.layout<"(8):(?{i64})">, !cute.layout<"1:0">
        %30 = cute.get_scalars(%append) <{only_dynamic}> : !cute.layout<"(8,1):(?{i64},0)">
        %stride_27 = cute.make_stride(%30) : (i64) -> !cute.stride<"(?{i64},(0))">
        %lay_28 = cute.make_layout(%8, %stride_27) : !cute.layout<"(8,(1)):(?{i64},(0))">
        %append_29 = cute.append_to_rank<2> (%lay_28, %9) : !cute.layout<"(8,(1)):(?{i64},(0))">, !cute.layout<"1:0">
        %31 = cute.get_scalars(%append_29) <{only_dynamic}> : !cute.layout<"(8,(1)):(?{i64},(0))">
        %stride_30 = cute.make_stride(%31) : (i64) -> !cute.stride<"(?{i64},((0)))">
        %lay_31 = cute.make_layout(%7, %stride_30) : !cute.layout<"(8,((1))):(?{i64},((0)))">
        %32 = cute.get_scalars(%6) : !cute.int_tuple<"1">
        scf.for %arg6 = %c0_i32 to %32 step %c1_i32  : i32 {
          %39 = cute.get_scalars(%lay_31) <{only_dynamic}> : !cute.layout<"(8,((1))):(?{i64},((0)))">
          %stride_32 = cute.make_stride(%39) : (i64) -> !cute.stride<"(?{i64})">
          %lay_33 = cute.make_layout(%12, %stride_32) : !cute.layout<"(8):(?{i64})">
          %40 = cute.get_scalars(%lay_33) <{only_dynamic}> : !cute.layout<"(8):(?{i64})">
          %41 = builtin.unrealized_conversion_cast %ptr_15 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %42 = builtin.unrealized_conversion_cast %iter_24 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
          %43 = llvm.load %41 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %43, %42 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          %int_tuple = cute.make_int_tuple(%40) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_34 = cute.add_offset(%ptr_15, %int_tuple) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %ptr_35 = cute.add_offset(%iter_24, %6) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
          %44 = builtin.unrealized_conversion_cast %ptr_34 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %45 = builtin.unrealized_conversion_cast %ptr_35 : !cute.ptr<f32, rmem> to !llvm.ptr
          %46 = llvm.load %44 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %46, %45 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          %47 = arith.muli %40, %c2_i64 : i64
          %iv_36 = cute.assume(%47) : (i64) -> !cute.i64<divby 2>
          %int_tuple_37 = cute.make_int_tuple(%iv_36) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
          %ptr_38 = cute.add_offset(%ptr_15, %int_tuple_37) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
          %ptr_39 = cute.add_offset(%iter_24, %5) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
          %48 = builtin.unrealized_conversion_cast %ptr_38 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %49 = builtin.unrealized_conversion_cast %ptr_39 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %50 = llvm.load %48 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %50, %49 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          %51 = arith.muli %40, %c3_i64 : i64
          %iv_40 = cute.assume(%51) : (i64) -> !cute.i64<divby 3>
          %int_tuple_41 = cute.make_int_tuple(%iv_40) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
          %ptr_42 = cute.add_offset(%ptr_15, %int_tuple_41) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
          %ptr_43 = cute.add_offset(%iter_24, %4) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
          %52 = builtin.unrealized_conversion_cast %ptr_42 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %53 = builtin.unrealized_conversion_cast %ptr_43 : !cute.ptr<f32, rmem> to !llvm.ptr
          %54 = llvm.load %52 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %54, %53 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          %55 = arith.muli %40, %c4_i64 : i64
          %iv_44 = cute.assume(%55) : (i64) -> !cute.i64<divby 4>
          %int_tuple_45 = cute.make_int_tuple(%iv_44) : (!cute.i64<divby 4>) -> !cute.int_tuple<"?{i64 div=4}">
          %ptr_46 = cute.add_offset(%ptr_15, %int_tuple_45) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=4}">) -> !cute.ptr<f32, gmem>
          %ptr_47 = cute.add_offset(%iter_24, %3) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
          %56 = builtin.unrealized_conversion_cast %ptr_46 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %57 = builtin.unrealized_conversion_cast %ptr_47 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
          %58 = llvm.load %56 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %58, %57 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          %59 = arith.muli %40, %c5_i64 : i64
          %iv_48 = cute.assume(%59) : (i64) -> !cute.i64<divby 5>
          %int_tuple_49 = cute.make_int_tuple(%iv_48) : (!cute.i64<divby 5>) -> !cute.int_tuple<"?{i64 div=5}">
          %ptr_50 = cute.add_offset(%ptr_15, %int_tuple_49) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=5}">) -> !cute.ptr<f32, gmem>
          %ptr_51 = cute.add_offset(%iter_24, %2) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<f32, rmem>
          %60 = builtin.unrealized_conversion_cast %ptr_50 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %61 = builtin.unrealized_conversion_cast %ptr_51 : !cute.ptr<f32, rmem> to !llvm.ptr
          %62 = llvm.load %60 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %62, %61 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          %63 = arith.muli %40, %c6_i64 : i64
          %iv_52 = cute.assume(%63) : (i64) -> !cute.i64<divby 6>
          %int_tuple_53 = cute.make_int_tuple(%iv_52) : (!cute.i64<divby 6>) -> !cute.int_tuple<"?{i64 div=6}">
          %ptr_54 = cute.add_offset(%ptr_15, %int_tuple_53) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=6}">) -> !cute.ptr<f32, gmem>
          %ptr_55 = cute.add_offset(%iter_24, %1) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
          %64 = builtin.unrealized_conversion_cast %ptr_54 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %65 = builtin.unrealized_conversion_cast %ptr_55 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %66 = llvm.load %64 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %66, %65 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          %67 = arith.muli %40, %c7_i64 : i64
          %iv_56 = cute.assume(%67) : (i64) -> !cute.i64<divby 7>
          %int_tuple_57 = cute.make_int_tuple(%iv_56) : (!cute.i64<divby 7>) -> !cute.int_tuple<"?{i64 div=7}">
          %ptr_58 = cute.add_offset(%ptr_15, %int_tuple_57) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=7}">) -> !cute.ptr<f32, gmem>
          %ptr_59 = cute.add_offset(%iter_24, %0) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<f32, rmem>
          %68 = builtin.unrealized_conversion_cast %ptr_58 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %69 = builtin.unrealized_conversion_cast %ptr_59 : !cute.ptr<f32, rmem> to !llvm.ptr
          %70 = llvm.load %68 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %70, %69 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %33 = cute.memref.load_vec %rmem, row_major : !memref_rmem_f32_
        %34 = nvgpu.cvt_fptrunc %33 : vector<8xf32> to vector<8xf4E2M1FN>
        %35 = cute.recast_layout<8, 4> (%10) : !cute.layout<"8:1"> to !cute.layout<"4:1">
        %36 = builtin.unrealized_conversion_cast %34 : vector<8xf4E2M1FN> to vector<8xi4>
        %37 = vector.bitcast %36 : vector<8xi4> to vector<4xi8>
        cute.memref.store_vec %37, %rmem_25, row_major : !memref_rmem_i8_
        %38 = cute.get_scalars(%6) : !cute.int_tuple<"1">
        scf.for %arg6 = %c0_i32 to %38 step %c1_i32  : i32 {
          %39 = builtin.unrealized_conversion_cast %iter_26 : !cute.ptr<i8, rmem, align<32>> to !llvm.ptr
          %40 = builtin.unrealized_conversion_cast %ptr_18 : !cute.ptr<i8, gmem> to !llvm.ptr<1>
          %41 = llvm.load %39 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
          llvm.store %41, %40 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
          %ptr_32 = cute.add_offset(%iter_26, %6) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
          %ptr_33 = cute.add_offset(%ptr_18, %6) : (!cute.ptr<i8, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<i8, gmem>
          %42 = builtin.unrealized_conversion_cast %ptr_32 : !cute.ptr<i8, rmem> to !llvm.ptr
          %43 = builtin.unrealized_conversion_cast %ptr_33 : !cute.ptr<i8, gmem> to !llvm.ptr<1>
          %44 = llvm.load %42 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
          llvm.store %44, %43 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
          %ptr_34 = cute.add_offset(%iter_26, %5) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem, align<2>>
          %ptr_35 = cute.add_offset(%ptr_18, %5) : (!cute.ptr<i8, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<i8, gmem>
          %45 = builtin.unrealized_conversion_cast %ptr_34 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
          %46 = builtin.unrealized_conversion_cast %ptr_35 : !cute.ptr<i8, gmem> to !llvm.ptr<1>
          %47 = llvm.load %45 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
          llvm.store %47, %46 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
          %ptr_36 = cute.add_offset(%iter_26, %4) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
          %ptr_37 = cute.add_offset(%ptr_18, %4) : (!cute.ptr<i8, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<i8, gmem>
          %48 = builtin.unrealized_conversion_cast %ptr_36 : !cute.ptr<i8, rmem> to !llvm.ptr
          %49 = builtin.unrealized_conversion_cast %ptr_37 : !cute.ptr<i8, gmem> to !llvm.ptr<1>
          %50 = llvm.load %48 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
          llvm.store %50, %49 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
        } {llvm.loop_annotation = #loop_annotation}
      }
      return
    }
  }
  func.func @cutlass__convert_Tensorgmemoi64i641_Tensorgmemoi641i64_1_8(%arg0: !memref_gmem_f32_1, %arg1: !memref_gmem_f4E2M1FN) attributes {llvm.emit_c_interface} {
    %c0_i32 = arith.constant 0 : i32
    %c128 = arith.constant 128 : index
    %c1 = arith.constant 1 : index
    %c512_i32 = arith.constant 512 : i32
    %0 = cute.static : !cute.stride<"((0,1@1,0),(1@0,1024@1,1@2))">
    %c1024_i64 = arith.constant 1024 : i64
    %c1024_i32 = arith.constant 1024 : i32
    %1 = cute.static : !cute.stride<"(1@0,1@1,1@2)">
    %2 = cute.static : !cute.int_tuple<"(0,0,0)">
    %3 = cute.static : !cute.layout<"(128,8):(8,1)">
    %iter = cute.get_iter(%arg1) : !memref_gmem_f4E2M1FN
    %4 = cute.recast_layout<8, 4> (%3) : !cute.layout<"(128,8):(8,1)"> to !cute.layout<"(128,4):(4,1)">
    %iter_0 = cute.recast_iter(%iter) : !cute.ptr<f4E2M1FN, gmem, align<16>> to !cute.ptr<i8, gmem, align<16>>
    %lay = cute.get_layout(%arg1) : !memref_gmem_f4E2M1FN
    %5 = cute.recast_layout<8, 4> (%lay) : !cute.layout<"(?,?,?):(?{i64},1,?{i64})"> to !cute.layout<"(?,?,?):(?{i64},1,?{i64})">
    %lay_1 = cute.get_layout(%arg0) : !memref_gmem_f32_1
    %6 = cute.get_shape(%lay_1) : (!cute.layout<"(?,?,?):(?{i64},?{i64},1)">) -> !cute.shape<"(?,?,?)">
    %e0, %e1, %e2 = cute.get_leaves(%6) : !cute.shape<"(?,?,?)">
    %itup = cute.to_int_tuple(%e0) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %7 = cute.get_scalars(%itup) : !cute.int_tuple<"?">
    %itup_2 = cute.to_int_tuple(%e1) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %8 = cute.get_scalars(%itup_2) : !cute.int_tuple<"?">
    %itup_3 = cute.to_int_tuple(%e2) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %9 = cute.get_scalars(%itup_3) : !cute.int_tuple<"?">
    %shape = cute.make_shape(%itup, %itup_2, %itup_3) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.shape<"(?,?,?)">
    %lay_4 = cute.make_layout(%shape, %1) : !cute.layout<"(?,?,?):(1@0,1@1,1@2)">
    %iter_5 = cute.get_iter(%arg0) : !memref_gmem_f32_1
    %lay_6 = cute.get_layout(%arg0) : !memref_gmem_f32_1
    %10:5 = cute.get_scalars(%lay_6) <{only_dynamic}> : !cute.layout<"(?,?,?):(?{i64},?{i64},1)">
    %11 = arith.ceildivsi %10#1, %c1024_i32 : i32
    %12 = arith.muli %10#4, %c1024_i64 : i64
    %shape_7 = cute.make_shape(%10#0, %11, %10#2) : (i32, i32, i32) -> !cute.shape<"((1,1024,1),(?,?,?))">
    %iv = cute.assume(%12) : (i64) -> !cute.i64<divby 1024>
    %stride = cute.make_stride(%10#4, %10#3, %iv) : (i64, i64, !cute.i64<divby 1024>) -> !cute.stride<"((0,?{i64},0),(?{i64},?{i64 div=1024},1))">
    %lay_8 = cute.make_layout(%shape_7, %stride) : !cute.layout<"((1,1024,1),(?,?,?)):((0,?{i64},0),(?{i64},?{i64 div=1024},1))">
    %view = cute.make_view(%iter_5, %lay_8) : !memref_gmem_f32_
    %13:3 = cute.get_scalars(%lay_4) <{only_dynamic}> : !cute.layout<"(?,?,?):(1@0,1@1,1@2)">
    %14 = arith.ceildivsi %13#1, %c1024_i32 : i32
    %shape_9 = cute.make_shape(%13#0, %14, %13#2) : (i32, i32, i32) -> !cute.shape<"((1,1024,1),(?,?,?))">
    %lay_10 = cute.make_layout(%shape_9, %0) : !cute.layout<"((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">
    %view_11 = cute.make_view(%2, %lay_10) : !cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">
    %15:5 = cute.get_scalars(%5) <{only_dynamic}> : !cute.layout<"(?,?,?):(?{i64},1,?{i64})">
    %16 = arith.ceildivsi %15#1, %c512_i32 : i32
    %shape_12 = cute.make_shape(%15#0, %16, %15#2) : (i32, i32, i32) -> !cute.shape<"((1,512,1),(?,?,?))">
    %stride_13 = cute.make_stride(%15#3, %15#4) : (i64, i64) -> !cute.stride<"((0,1,0),(?{i64},512,?{i64}))">
    %lay_14 = cute.make_layout(%shape_12, %stride_13) : !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">
    %view_15 = cute.make_view(%iter_0, %lay_14) : !memref_gmem_i8_
    %sz = cute.size(%lay_8) <{mode = [1]}> : (!cute.layout<"((1,1024,1),(?,?,?)):((0,?{i64},0),(?{i64},?{i64 div=1024},1))">) -> !cute.int_tuple<"?">
    %e0_16 = cute.get_leaves(%sz) : !cute.int_tuple<"?">
    %17 = cute.get_scalars(%e0_16) : !cute.int_tuple<"?">
    %18 = arith.index_cast %17 : i32 to index
    gpu.launch_func  @kernels::@kernel_cutlass__convert_kernel_tensorptrf32gmemo11024100div10241_tensorptri8gmemalign16o15121010512_tensor000o1102410110101024112____Float32_Float4E2M1FN_0 blocks in (%18, %c1, %c1) threads in (%c128, %c1, %c1)  dynamic_shared_memory_size %c0_i32 args(%view : !memref_gmem_f32_, %view_15 : !memref_gmem_i8_, %view_11 : !cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">, %7 : i32, %8 : i32, %9 : i32) {use_pdl = false}
    return
  }
}
