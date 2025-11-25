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
      %lay_1 = cute.get_layout(%arg1) : !memref_gmem_i8_
      %idx_2 = cute.crd2idx(%coord, %lay_1) : (!cute.coord<"(_,?)">, !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !cute.int_tuple<"?{i64}">
      %iter_3 = cute.get_iter(%arg1) : !memref_gmem_i8_
      %ptr_4 = cute.add_offset(%iter_3, %idx_2) : (!cute.ptr<i8, gmem, align<16>>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<i8, gmem>
      %lay_5 = cute.get_layout(%arg2) : !cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">
      %idx_6 = cute.crd2idx(%coord, %lay_5) : (!cute.coord<"(_,?)">, !cute.layout<"((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">) -> !cute.int_tuple<"(?,?{div=1024},?)">
      %tup = cute.add_offset(%14, %idx_6) : (!cute.int_tuple<"(0,0,0)">, !cute.int_tuple<"(?,?{div=1024},?)">) -> !cute.int_tuple<"(?,?{div=1024},?)">
      %20 = cute.get_scalars(%lay_0) <{only_dynamic}> : !cute.layout<"((1,1024,1)):((0,?{i64},0))">
      %21 = arith.muli %20, %c8_i64 : i64
      %iv = cute.assume(%21) : (i64) -> !cute.i64<divby 8>
      %stride_7 = cute.make_stride(%iv, %20) : (!cute.i64<divby 8>, i64) -> !cute.stride<"(?{i64 div=8},?{i64})">
      %lay_8 = cute.make_layout(%13, %stride_7) : !cute.layout<"(128,8):(?{i64 div=8},?{i64})">
      %coord_9 = cute.make_coord(%17) : (i32) -> !cute.coord<"(?,_)">
      %22:2 = cute.get_scalars(%lay_8) <{only_dynamic}> : !cute.layout<"(128,8):(?{i64 div=8},?{i64})">
      %stride_10 = cute.make_stride(%22#1) : (i64) -> !cute.stride<"(?{i64})">
      %lay_11 = cute.make_layout(%12, %stride_10) : !cute.layout<"(8):(?{i64})">
      %idx_12 = cute.crd2idx(%coord_9, %lay_8) : (!cute.coord<"(?,_)">, !cute.layout<"(128,8):(?{i64 div=8},?{i64})">) -> !cute.int_tuple<"?{i64 div=8}">
      %ptr_13 = cute.add_offset(%ptr, %idx_12) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=8}">) -> !cute.ptr<f32, gmem>
      %idx_14 = cute.crd2idx(%coord_9, %16) : (!cute.coord<"(?,_)">, !cute.layout<"(128,4):(4,1)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_15 = cute.add_offset(%ptr_4, %idx_14) : (!cute.ptr<i8, gmem>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<i8, gmem>
      %idx_16 = cute.crd2idx(%coord_9, %11) : (!cute.coord<"(?,_)">, !cute.layout<"(128,8):(8@1,1@1)">) -> !cute.int_tuple<"(0,?{div=8})">
      %tup_17 = cute.add_offset(%tup, %idx_16) : (!cute.int_tuple<"(?,?{div=1024},?)">, !cute.int_tuple<"(0,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8},?)">
      %e0, %e1, %e2 = cute.get_leaves(%tup_17) : !cute.int_tuple<"(?,?{div=8},?)">
      %coord_18 = cute.make_coord(%e0, %e1, %e2) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?{div=8},?)">
      %coord_19 = cute.make_coord(%arg3, %arg4, %arg5) : (i32, i32, i32) -> !cute.coord<"(?,?,?)">
      %23:3 = cute.get_scalars(%coord_18) : !cute.coord<"(?,?{div=8},?)">
      %24:3 = cute.get_scalars(%coord_19) : !cute.coord<"(?,?,?)">
      %25 = arith.cmpi slt, %23#0, %24#0 : i32
      %26 = arith.cmpi slt, %23#1, %24#1 : i32
      %27 = arith.andi %25, %26 : i1
      %28 = arith.cmpi slt, %23#2, %24#2 : i32
      %29 = arith.andi %27, %28 : i1
      scf.if %29 {
        %rmem = cute.memref.alloca() : !memref_rmem_f32_
        %iter_20 = cute.get_iter(%rmem) : !memref_rmem_f32_
        %rmem_21 = cute.memref.alloca() : !memref_rmem_i8_
        %iter_22 = cute.get_iter(%rmem_21) : !memref_rmem_i8_
        %append = cute.append_to_rank<2> (%lay_11, %9) : !cute.layout<"(8):(?{i64})">, !cute.layout<"1:0">
        %30 = cute.get_scalars(%append) <{only_dynamic}> : !cute.layout<"(8,1):(?{i64},0)">
        %stride_23 = cute.make_stride(%30) : (i64) -> !cute.stride<"(?{i64},(0))">
        %lay_24 = cute.make_layout(%8, %stride_23) : !cute.layout<"(8,(1)):(?{i64},(0))">
        %append_25 = cute.append_to_rank<2> (%lay_24, %9) : !cute.layout<"(8,(1)):(?{i64},(0))">, !cute.layout<"1:0">
        %31 = cute.get_scalars(%append_25) <{only_dynamic}> : !cute.layout<"(8,(1)):(?{i64},(0))">
        %stride_26 = cute.make_stride(%31) : (i64) -> !cute.stride<"(?{i64},((0)))">
        %lay_27 = cute.make_layout(%7, %stride_26) : !cute.layout<"(8,((1))):(?{i64},((0)))">
        %32 = cute.get_scalars(%6) : !cute.int_tuple<"1">
        %33 = cute.get_scalars(%lay_27) <{only_dynamic}> : !cute.layout<"(8,((1))):(?{i64},((0)))">
        %stride_28 = cute.make_stride(%33) : (i64) -> !cute.stride<"(?{i64})">
        %lay_29 = cute.make_layout(%12, %stride_28) : !cute.layout<"(8):(?{i64})">
        %34 = cute.get_scalars(%lay_29) <{only_dynamic}> : !cute.layout<"(8):(?{i64})">
        %35 = builtin.unrealized_conversion_cast %ptr_13 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
        %36 = builtin.unrealized_conversion_cast %iter_20 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
        %int_tuple = cute.make_int_tuple(%34) : (i64) -> !cute.int_tuple<"?{i64}">
        %ptr_30 = cute.add_offset(%ptr_13, %int_tuple) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
        %ptr_31 = cute.add_offset(%iter_20, %6) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
        %37 = builtin.unrealized_conversion_cast %ptr_30 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
        %38 = builtin.unrealized_conversion_cast %ptr_31 : !cute.ptr<f32, rmem> to !llvm.ptr
        %39 = arith.muli %34, %c2_i64 : i64
        %iv_32 = cute.assume(%39) : (i64) -> !cute.i64<divby 2>
        %int_tuple_33 = cute.make_int_tuple(%iv_32) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
        %ptr_34 = cute.add_offset(%ptr_13, %int_tuple_33) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
        %ptr_35 = cute.add_offset(%iter_20, %5) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
        %40 = builtin.unrealized_conversion_cast %ptr_34 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
        %41 = builtin.unrealized_conversion_cast %ptr_35 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
        %42 = arith.muli %34, %c3_i64 : i64
        %iv_36 = cute.assume(%42) : (i64) -> !cute.i64<divby 3>
        %int_tuple_37 = cute.make_int_tuple(%iv_36) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
        %ptr_38 = cute.add_offset(%ptr_13, %int_tuple_37) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
        %ptr_39 = cute.add_offset(%iter_20, %4) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
        %43 = builtin.unrealized_conversion_cast %ptr_38 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
        %44 = builtin.unrealized_conversion_cast %ptr_39 : !cute.ptr<f32, rmem> to !llvm.ptr
        %45 = arith.muli %34, %c4_i64 : i64
        %iv_40 = cute.assume(%45) : (i64) -> !cute.i64<divby 4>
        %int_tuple_41 = cute.make_int_tuple(%iv_40) : (!cute.i64<divby 4>) -> !cute.int_tuple<"?{i64 div=4}">
        %ptr_42 = cute.add_offset(%ptr_13, %int_tuple_41) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=4}">) -> !cute.ptr<f32, gmem>
        %ptr_43 = cute.add_offset(%iter_20, %3) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
        %46 = builtin.unrealized_conversion_cast %ptr_42 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
        %47 = builtin.unrealized_conversion_cast %ptr_43 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
        %48 = arith.muli %34, %c5_i64 : i64
        %iv_44 = cute.assume(%48) : (i64) -> !cute.i64<divby 5>
        %int_tuple_45 = cute.make_int_tuple(%iv_44) : (!cute.i64<divby 5>) -> !cute.int_tuple<"?{i64 div=5}">
        %ptr_46 = cute.add_offset(%ptr_13, %int_tuple_45) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=5}">) -> !cute.ptr<f32, gmem>
        %ptr_47 = cute.add_offset(%iter_20, %2) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<f32, rmem>
        %49 = builtin.unrealized_conversion_cast %ptr_46 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
        %50 = builtin.unrealized_conversion_cast %ptr_47 : !cute.ptr<f32, rmem> to !llvm.ptr
        %51 = arith.muli %34, %c6_i64 : i64
        %iv_48 = cute.assume(%51) : (i64) -> !cute.i64<divby 6>
        %int_tuple_49 = cute.make_int_tuple(%iv_48) : (!cute.i64<divby 6>) -> !cute.int_tuple<"?{i64 div=6}">
        %ptr_50 = cute.add_offset(%ptr_13, %int_tuple_49) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=6}">) -> !cute.ptr<f32, gmem>
        %ptr_51 = cute.add_offset(%iter_20, %1) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
        %52 = builtin.unrealized_conversion_cast %ptr_50 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
        %53 = builtin.unrealized_conversion_cast %ptr_51 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
        %54 = arith.muli %34, %c7_i64 : i64
        %iv_52 = cute.assume(%54) : (i64) -> !cute.i64<divby 7>
        %int_tuple_53 = cute.make_int_tuple(%iv_52) : (!cute.i64<divby 7>) -> !cute.int_tuple<"?{i64 div=7}">
        %ptr_54 = cute.add_offset(%ptr_13, %int_tuple_53) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=7}">) -> !cute.ptr<f32, gmem>
        %ptr_55 = cute.add_offset(%iter_20, %0) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<f32, rmem>
        %55 = builtin.unrealized_conversion_cast %ptr_54 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
        %56 = builtin.unrealized_conversion_cast %ptr_55 : !cute.ptr<f32, rmem> to !llvm.ptr
        scf.for %arg6 = %c0_i32 to %32 step %c1_i32  : i32 {
          %70 = llvm.load %35 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %70, %36 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          %71 = llvm.load %37 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %71, %38 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          %72 = llvm.load %40 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %72, %41 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          %73 = llvm.load %43 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %73, %44 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          %74 = llvm.load %46 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %74, %47 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          %75 = llvm.load %49 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %75, %50 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          %76 = llvm.load %52 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %76, %53 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          %77 = llvm.load %55 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %77, %56 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %57 = cute.memref.load_vec %rmem, row_major : !memref_rmem_f32_
        %58 = nvgpu.cvt_fptrunc %57 : vector<8xf32> to vector<8xf4E2M1FN>
        %59 = cute.recast_layout<8, 4> (%10) : !cute.layout<"8:1"> to !cute.layout<"4:1">
        %60 = builtin.unrealized_conversion_cast %58 : vector<8xf4E2M1FN> to vector<8xi4>
        %61 = vector.bitcast %60 : vector<8xi4> to vector<4xi8>
        cute.memref.store_vec %61, %rmem_21, row_major : !memref_rmem_i8_
        %62 = builtin.unrealized_conversion_cast %iter_22 : !cute.ptr<i8, rmem, align<32>> to !llvm.ptr
        %63 = builtin.unrealized_conversion_cast %ptr_15 : !cute.ptr<i8, gmem> to !llvm.ptr<1>
        %ptr_56 = cute.add_offset(%iter_22, %6) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
        %ptr_57 = cute.add_offset(%ptr_15, %6) : (!cute.ptr<i8, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<i8, gmem>
        %64 = builtin.unrealized_conversion_cast %ptr_56 : !cute.ptr<i8, rmem> to !llvm.ptr
        %65 = builtin.unrealized_conversion_cast %ptr_57 : !cute.ptr<i8, gmem> to !llvm.ptr<1>
        %ptr_58 = cute.add_offset(%iter_22, %5) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem, align<2>>
        %ptr_59 = cute.add_offset(%ptr_15, %5) : (!cute.ptr<i8, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<i8, gmem>
        %66 = builtin.unrealized_conversion_cast %ptr_58 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
        %67 = builtin.unrealized_conversion_cast %ptr_59 : !cute.ptr<i8, gmem> to !llvm.ptr<1>
        %ptr_60 = cute.add_offset(%iter_22, %4) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
        %ptr_61 = cute.add_offset(%ptr_15, %4) : (!cute.ptr<i8, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<i8, gmem>
        %68 = builtin.unrealized_conversion_cast %ptr_60 : !cute.ptr<i8, rmem> to !llvm.ptr
        %69 = builtin.unrealized_conversion_cast %ptr_61 : !cute.ptr<i8, gmem> to !llvm.ptr<1>
        scf.for %arg6 = %c0_i32 to %32 step %c1_i32  : i32 {
          %70 = llvm.load %62 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
          llvm.store %70, %63 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
          %71 = llvm.load %64 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
          llvm.store %71, %65 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
          %72 = llvm.load %66 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
          llvm.store %72, %67 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
          %73 = llvm.load %68 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
          llvm.store %73, %69 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
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
    %10:5 = cute.get_scalars(%lay_1) <{only_dynamic}> : !cute.layout<"(?,?,?):(?{i64},?{i64},1)">
    %11 = arith.ceildivsi %10#1, %c1024_i32 : i32
    %12 = arith.muli %10#4, %c1024_i64 : i64
    %shape_6 = cute.make_shape(%10#0, %11, %10#2) : (i32, i32, i32) -> !cute.shape<"((1,1024,1),(?,?,?))">
    %iv = cute.assume(%12) : (i64) -> !cute.i64<divby 1024>
    %stride = cute.make_stride(%10#4, %10#3, %iv) : (i64, i64, !cute.i64<divby 1024>) -> !cute.stride<"((0,?{i64},0),(?{i64},?{i64 div=1024},1))">
    %lay_7 = cute.make_layout(%shape_6, %stride) : !cute.layout<"((1,1024,1),(?,?,?)):((0,?{i64},0),(?{i64},?{i64 div=1024},1))">
    %view = cute.make_view(%iter_5, %lay_7) : !memref_gmem_f32_
    %13:3 = cute.get_scalars(%lay_4) <{only_dynamic}> : !cute.layout<"(?,?,?):(1@0,1@1,1@2)">
    %14 = arith.ceildivsi %13#1, %c1024_i32 : i32
    %shape_8 = cute.make_shape(%13#0, %14, %13#2) : (i32, i32, i32) -> !cute.shape<"((1,1024,1),(?,?,?))">
    %lay_9 = cute.make_layout(%shape_8, %0) : !cute.layout<"((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">
    %view_10 = cute.make_view(%2, %lay_9) : !cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">
    %15:5 = cute.get_scalars(%5) <{only_dynamic}> : !cute.layout<"(?,?,?):(?{i64},1,?{i64})">
    %16 = arith.ceildivsi %15#1, %c512_i32 : i32
    %shape_11 = cute.make_shape(%15#0, %16, %15#2) : (i32, i32, i32) -> !cute.shape<"((1,512,1),(?,?,?))">
    %stride_12 = cute.make_stride(%15#3, %15#4) : (i64, i64) -> !cute.stride<"((0,1,0),(?{i64},512,?{i64}))">
    %lay_13 = cute.make_layout(%shape_11, %stride_12) : !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">
    %view_14 = cute.make_view(%iter_0, %lay_13) : !memref_gmem_i8_
    %sz = cute.size(%lay_7) <{mode = [1]}> : (!cute.layout<"((1,1024,1),(?,?,?)):((0,?{i64},0),(?{i64},?{i64 div=1024},1))">) -> !cute.int_tuple<"?">
    %e0_15 = cute.get_leaves(%sz) : !cute.int_tuple<"?">
    %17 = cute.get_scalars(%e0_15) : !cute.int_tuple<"?">
    %18 = arith.index_cast %17 : i32 to index
    gpu.launch_func  @kernels::@kernel_cutlass__convert_kernel_tensorptrf32gmemo11024100div10241_tensorptri8gmemalign16o15121010512_tensor000o1102410110101024112____Float32_Float4E2M1FN_0 blocks in (%18, %c1, %c1) threads in (%c128, %c1, %c1)  dynamic_shared_memory_size %c0_i32 args(%view : !memref_gmem_f32_, %view_14 : !memref_gmem_i8_, %view_10 : !cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">, %7 : i32, %8 : i32, %9 : i32) {use_pdl = false}
    return
  }
}
