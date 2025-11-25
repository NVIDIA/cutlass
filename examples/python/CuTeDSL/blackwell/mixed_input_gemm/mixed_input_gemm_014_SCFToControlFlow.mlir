!memref_gmem_f32_ = !cute.memref<f32, gmem, "((1024,1,1),(?,?,?)):((1,0,0),(1024,?{i64},?{i64}))">
!memref_gmem_f32_1 = !cute.memref<f32, gmem, "(?,?,?):(1,?{i64},?{i64})">
!memref_gmem_i4_ = !cute.memref<i4, gmem, align<128>, "(?,?,?):(1,?{i64},?{i64})">
!memref_gmem_i8_ = !cute.memref<i8, gmem, align<128>, "((512,1,1),(?,?,?)):((1,0,0),(512,?{i64},?{i64}))">
!memref_rmem_f32_ = !cute.memref<f32, rmem, align<32>, "8:1">
!memref_rmem_i8_ = !cute.memref<i8, rmem, align<32>, "4:1">
#loop_unroll = #llvm.loop_unroll<disable = false, full = true>
#loop_annotation = #llvm.loop_annotation<unroll = #loop_unroll>
module attributes {gpu.container_module} {
  gpu.module @kernels {
    func.func public @kernel_cutlass__convert_kernel_tensorptrf32gmemo1024111001024_tensorptri8gmemalign128o51211100512_tensor000o1024111000102401112____Float32_Int4_0(%arg0: !memref_gmem_f32_, %arg1: !memref_gmem_i8_, %arg2: !cute.coord_tensor<"(0,0,0)", "((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">, %arg3: i32, %arg4: i32, %arg5: i32) attributes {cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} {
      %0 = cute.static : !cute.int_tuple<"7">
      %1 = cute.static : !cute.int_tuple<"6">
      %2 = cute.static : !cute.int_tuple<"5">
      %3 = cute.static : !cute.int_tuple<"4">
      %4 = cute.static : !cute.int_tuple<"3">
      %5 = cute.static : !cute.int_tuple<"2">
      %c1_i32 = arith.constant 1 : i32
      %c0_i32 = arith.constant 0 : i32
      %6 = cute.static : !cute.int_tuple<"1">
      %7 = cute.static : !cute.layout<"8:1">
      %8 = cute.static : !cute.layout<"(128,8):(8@0,1@0)">
      %9 = cute.static : !cute.int_tuple<"(0,0,0)">
      %10 = cute.static : !cute.layout<"(128,8):(8,1)">
      %11 = cute.static : !cute.layout<"(128,4):(4,1)">
      %12 = nvvm.read.ptx.sreg.tid.x range <i32, 0, 1024> : i32
      %13 = nvvm.read.ptx.sreg.ctaid.x range <i32, 0, 2147483647> : i32
      %coord = cute.make_coord(%13) : (i32) -> !cute.coord<"(_,?)">
      %lay = cute.get_layout(%arg0) : !memref_gmem_f32_
      %idx = cute.crd2idx(%coord, %lay) : (!cute.coord<"(_,?)">, !cute.layout<"((1024,1,1),(?,?,?)):((1,0,0),(1024,?{i64},?{i64}))">) -> !cute.int_tuple<"?{i64}">
      %iter = cute.get_iter(%arg0) : !memref_gmem_f32_
      %ptr = cute.add_offset(%iter, %idx) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %lay_0 = cute.get_layout(%arg1) : !memref_gmem_i8_
      %idx_1 = cute.crd2idx(%coord, %lay_0) : (!cute.coord<"(_,?)">, !cute.layout<"((512,1,1),(?,?,?)):((1,0,0),(512,?{i64},?{i64}))">) -> !cute.int_tuple<"?{i64}">
      %iter_2 = cute.get_iter(%arg1) : !memref_gmem_i8_
      %ptr_3 = cute.add_offset(%iter_2, %idx_1) : (!cute.ptr<i8, gmem, align<128>>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<i8, gmem>
      %lay_4 = cute.get_layout(%arg2) : !cute.coord_tensor<"(0,0,0)", "((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">
      %idx_5 = cute.crd2idx(%coord, %lay_4) : (!cute.coord<"(_,?)">, !cute.layout<"((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">) -> !cute.int_tuple<"(?{div=1024},?,?)">
      %tup = cute.add_offset(%9, %idx_5) : (!cute.int_tuple<"(0,0,0)">, !cute.int_tuple<"(?{div=1024},?,?)">) -> !cute.int_tuple<"(?{div=1024},?,?)">
      %coord_6 = cute.make_coord(%12) : (i32) -> !cute.coord<"(?,_)">
      %idx_7 = cute.crd2idx(%coord_6, %10) : (!cute.coord<"(?,_)">, !cute.layout<"(128,8):(8,1)">) -> !cute.int_tuple<"?{div=8}">
      %ptr_8 = cute.add_offset(%ptr, %idx_7) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f32, gmem>
      %idx_9 = cute.crd2idx(%coord_6, %11) : (!cute.coord<"(?,_)">, !cute.layout<"(128,4):(4,1)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_10 = cute.add_offset(%ptr_3, %idx_9) : (!cute.ptr<i8, gmem>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<i8, gmem>
      %idx_11 = cute.crd2idx(%coord_6, %8) : (!cute.coord<"(?,_)">, !cute.layout<"(128,8):(8@0,1@0)">) -> !cute.int_tuple<"(?{div=8})">
      %tup_12 = cute.add_offset(%tup, %idx_11) : (!cute.int_tuple<"(?{div=1024},?,?)">, !cute.int_tuple<"(?{div=8})">) -> !cute.int_tuple<"(?{div=8},?,?)">
      %e0, %e1, %e2 = cute.get_leaves(%tup_12) : !cute.int_tuple<"(?{div=8},?,?)">
      %coord_13 = cute.make_coord(%e0, %e1, %e2) : (!cute.int_tuple<"?{div=8}">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?{div=8},?,?)">
      %coord_14 = cute.make_coord(%arg3, %arg4, %arg5) : (i32, i32, i32) -> !cute.coord<"(?,?,?)">
      %14:3 = cute.get_scalars(%coord_13) : !cute.coord<"(?{div=8},?,?)">
      %15:3 = cute.get_scalars(%coord_14) : !cute.coord<"(?,?,?)">
      %16 = arith.cmpi slt, %14#0, %15#0 : i32
      %17 = arith.cmpi slt, %14#1, %15#1 : i32
      %18 = arith.andi %16, %17 : i1
      %19 = arith.cmpi slt, %14#2, %15#2 : i32
      %20 = arith.andi %18, %19 : i1
      cf.cond_br %20, ^bb1, ^bb8
    ^bb1:  // pred: ^bb0
      %rmem = cute.memref.alloca() : !memref_rmem_f32_
      %iter_15 = cute.get_iter(%rmem) : !memref_rmem_f32_
      %rmem_16 = cute.memref.alloca() : !memref_rmem_i8_
      %iter_17 = cute.get_iter(%rmem_16) : !memref_rmem_i8_
      %21 = cute.get_scalars(%6) : !cute.int_tuple<"1">
      %22 = builtin.unrealized_conversion_cast %ptr_8 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %23 = builtin.unrealized_conversion_cast %iter_15 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
      %ptr_18 = cute.add_offset(%ptr_8, %6) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
      %ptr_19 = cute.add_offset(%iter_15, %6) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
      %24 = builtin.unrealized_conversion_cast %ptr_18 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %25 = builtin.unrealized_conversion_cast %ptr_19 : !cute.ptr<f32, rmem> to !llvm.ptr
      %ptr_20 = cute.add_offset(%ptr_8, %5) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
      %ptr_21 = cute.add_offset(%iter_15, %5) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
      %26 = builtin.unrealized_conversion_cast %ptr_20 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %27 = builtin.unrealized_conversion_cast %ptr_21 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
      %ptr_22 = cute.add_offset(%ptr_8, %4) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
      %ptr_23 = cute.add_offset(%iter_15, %4) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
      %28 = builtin.unrealized_conversion_cast %ptr_22 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %29 = builtin.unrealized_conversion_cast %ptr_23 : !cute.ptr<f32, rmem> to !llvm.ptr
      %ptr_24 = cute.add_offset(%ptr_8, %3) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"4">) -> !cute.ptr<f32, gmem>
      %ptr_25 = cute.add_offset(%iter_15, %3) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
      %30 = builtin.unrealized_conversion_cast %ptr_24 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %31 = builtin.unrealized_conversion_cast %ptr_25 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
      %ptr_26 = cute.add_offset(%ptr_8, %2) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"5">) -> !cute.ptr<f32, gmem>
      %ptr_27 = cute.add_offset(%iter_15, %2) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<f32, rmem>
      %32 = builtin.unrealized_conversion_cast %ptr_26 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %33 = builtin.unrealized_conversion_cast %ptr_27 : !cute.ptr<f32, rmem> to !llvm.ptr
      %ptr_28 = cute.add_offset(%ptr_8, %1) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"6">) -> !cute.ptr<f32, gmem>
      %ptr_29 = cute.add_offset(%iter_15, %1) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
      %34 = builtin.unrealized_conversion_cast %ptr_28 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %35 = builtin.unrealized_conversion_cast %ptr_29 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
      %ptr_30 = cute.add_offset(%ptr_8, %0) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"7">) -> !cute.ptr<f32, gmem>
      %ptr_31 = cute.add_offset(%iter_15, %0) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<f32, rmem>
      %36 = builtin.unrealized_conversion_cast %ptr_30 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %37 = builtin.unrealized_conversion_cast %ptr_31 : !cute.ptr<f32, rmem> to !llvm.ptr
      cf.br ^bb2(%c0_i32 : i32)
    ^bb2(%38: i32):  // 2 preds: ^bb1, ^bb3
      %39 = arith.cmpi slt, %38, %21 : i32
      cf.cond_br %39, ^bb3, ^bb4 {llvm.loop_annotation = #loop_annotation}
    ^bb3:  // pred: ^bb2
      %40 = llvm.load %22 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %40, %23 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      %41 = llvm.load %24 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %41, %25 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      %42 = llvm.load %26 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %42, %27 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      %43 = llvm.load %28 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %43, %29 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      %44 = llvm.load %30 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %44, %31 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      %45 = llvm.load %32 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %45, %33 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      %46 = llvm.load %34 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %46, %35 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      %47 = llvm.load %36 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %47, %37 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      %48 = arith.addi %38, %c1_i32 : i32
      cf.br ^bb2(%48 : i32)
    ^bb4:  // pred: ^bb2
      %49 = cute.memref.load_vec %rmem, row_major : !memref_rmem_f32_
      %50 = arith.fptosi %49 : vector<8xf32> to vector<8xi4>
      %51 = cute.recast_layout<8, 4> (%7) : !cute.layout<"8:1"> to !cute.layout<"4:1">
      %52 = vector.bitcast %50 : vector<8xi4> to vector<4xi8>
      cute.memref.store_vec %52, %rmem_16, row_major : !memref_rmem_i8_
      %53 = builtin.unrealized_conversion_cast %iter_17 : !cute.ptr<i8, rmem, align<32>> to !llvm.ptr
      %54 = builtin.unrealized_conversion_cast %ptr_10 : !cute.ptr<i8, gmem> to !llvm.ptr<1>
      %ptr_32 = cute.add_offset(%iter_17, %6) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
      %ptr_33 = cute.add_offset(%ptr_10, %6) : (!cute.ptr<i8, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<i8, gmem>
      %55 = builtin.unrealized_conversion_cast %ptr_32 : !cute.ptr<i8, rmem> to !llvm.ptr
      %56 = builtin.unrealized_conversion_cast %ptr_33 : !cute.ptr<i8, gmem> to !llvm.ptr<1>
      %ptr_34 = cute.add_offset(%iter_17, %5) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem, align<2>>
      %ptr_35 = cute.add_offset(%ptr_10, %5) : (!cute.ptr<i8, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<i8, gmem>
      %57 = builtin.unrealized_conversion_cast %ptr_34 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
      %58 = builtin.unrealized_conversion_cast %ptr_35 : !cute.ptr<i8, gmem> to !llvm.ptr<1>
      %ptr_36 = cute.add_offset(%iter_17, %4) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
      %ptr_37 = cute.add_offset(%ptr_10, %4) : (!cute.ptr<i8, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<i8, gmem>
      %59 = builtin.unrealized_conversion_cast %ptr_36 : !cute.ptr<i8, rmem> to !llvm.ptr
      %60 = builtin.unrealized_conversion_cast %ptr_37 : !cute.ptr<i8, gmem> to !llvm.ptr<1>
      cf.br ^bb5(%c0_i32 : i32)
    ^bb5(%61: i32):  // 2 preds: ^bb4, ^bb6
      %62 = arith.cmpi slt, %61, %21 : i32
      cf.cond_br %62, ^bb6, ^bb7 {llvm.loop_annotation = #loop_annotation}
    ^bb6:  // pred: ^bb5
      %63 = llvm.load %53 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
      llvm.store %63, %54 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
      %64 = llvm.load %55 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
      llvm.store %64, %56 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
      %65 = llvm.load %57 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
      llvm.store %65, %58 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
      %66 = llvm.load %59 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
      llvm.store %66, %60 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
      %67 = arith.addi %61, %c1_i32 : i32
      cf.br ^bb5(%67 : i32)
    ^bb7:  // pred: ^bb5
      cf.br ^bb8
    ^bb8:  // 2 preds: ^bb0, ^bb7
      return
    }
  }
  func.func @cutlass__convert_Tensorgmemo1i64i64_Tensorgmemo1i64i64_0_8(%arg0: !memref_gmem_f32_1, %arg1: !memref_gmem_i4_) attributes {llvm.emit_c_interface} {
    %c0_i32 = arith.constant 0 : i32
    %c128 = arith.constant 128 : index
    %c1 = arith.constant 1 : index
    %c512_i32 = arith.constant 512 : i32
    %0 = cute.static : !cute.stride<"((1@0,0,0),(1024@0,1@1,1@2))">
    %c1024_i32 = arith.constant 1024 : i32
    %1 = cute.static : !cute.stride<"(1@0,1@1,1@2)">
    %2 = cute.static : !cute.int_tuple<"(0,0,0)">
    %3 = cute.static : !cute.layout<"(128,8):(8,1)">
    %iter = cute.get_iter(%arg1) : !memref_gmem_i4_
    %4 = cute.recast_layout<8, 4> (%3) : !cute.layout<"(128,8):(8,1)"> to !cute.layout<"(128,4):(4,1)">
    %iter_0 = cute.recast_iter(%iter) : !cute.ptr<i4, gmem, align<128>> to !cute.ptr<i8, gmem, align<128>>
    %lay = cute.get_layout(%arg1) : !memref_gmem_i4_
    %5 = cute.recast_layout<8, 4> (%lay) : !cute.layout<"(?,?,?):(1,?{i64},?{i64})"> to !cute.layout<"(?,?,?):(1,?{i64},?{i64})">
    %lay_1 = cute.get_layout(%arg0) : !memref_gmem_f32_1
    %6 = cute.get_shape(%lay_1) : (!cute.layout<"(?,?,?):(1,?{i64},?{i64})">) -> !cute.shape<"(?,?,?)">
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
    %10:5 = cute.get_scalars(%lay_1) <{only_dynamic}> : !cute.layout<"(?,?,?):(1,?{i64},?{i64})">
    %11 = arith.ceildivsi %10#0, %c1024_i32 : i32
    %shape_6 = cute.make_shape(%11, %10#1, %10#2) : (i32, i32, i32) -> !cute.shape<"((1024,1,1),(?,?,?))">
    %stride = cute.make_stride(%10#3, %10#4) : (i64, i64) -> !cute.stride<"((1,0,0),(1024,?{i64},?{i64}))">
    %lay_7 = cute.make_layout(%shape_6, %stride) : !cute.layout<"((1024,1,1),(?,?,?)):((1,0,0),(1024,?{i64},?{i64}))">
    %view = cute.make_view(%iter_5, %lay_7) : !memref_gmem_f32_
    %12:3 = cute.get_scalars(%lay_4) <{only_dynamic}> : !cute.layout<"(?,?,?):(1@0,1@1,1@2)">
    %13 = arith.ceildivsi %12#0, %c1024_i32 : i32
    %shape_8 = cute.make_shape(%13, %12#1, %12#2) : (i32, i32, i32) -> !cute.shape<"((1024,1,1),(?,?,?))">
    %lay_9 = cute.make_layout(%shape_8, %0) : !cute.layout<"((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">
    %view_10 = cute.make_view(%2, %lay_9) : !cute.coord_tensor<"(0,0,0)", "((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">
    %14:5 = cute.get_scalars(%5) <{only_dynamic}> : !cute.layout<"(?,?,?):(1,?{i64},?{i64})">
    %15 = arith.ceildivsi %14#0, %c512_i32 : i32
    %shape_11 = cute.make_shape(%15, %14#1, %14#2) : (i32, i32, i32) -> !cute.shape<"((512,1,1),(?,?,?))">
    %stride_12 = cute.make_stride(%14#3, %14#4) : (i64, i64) -> !cute.stride<"((1,0,0),(512,?{i64},?{i64}))">
    %lay_13 = cute.make_layout(%shape_11, %stride_12) : !cute.layout<"((512,1,1),(?,?,?)):((1,0,0),(512,?{i64},?{i64}))">
    %view_14 = cute.make_view(%iter_0, %lay_13) : !memref_gmem_i8_
    %sz = cute.size(%lay_7) <{mode = [1]}> : (!cute.layout<"((1024,1,1),(?,?,?)):((1,0,0),(1024,?{i64},?{i64}))">) -> !cute.int_tuple<"?">
    %e0_15 = cute.get_leaves(%sz) : !cute.int_tuple<"?">
    %16 = cute.get_scalars(%e0_15) : !cute.int_tuple<"?">
    %17 = arith.index_cast %16 : i32 to index
    gpu.launch_func  @kernels::@kernel_cutlass__convert_kernel_tensorptrf32gmemo1024111001024_tensorptri8gmemalign128o51211100512_tensor000o1024111000102401112____Float32_Int4_0 blocks in (%17, %c1, %c1) threads in (%c128, %c1, %c1)  dynamic_shared_memory_size %c0_i32 args(%view : !memref_gmem_f32_, %view_14 : !memref_gmem_i8_, %view_10 : !cute.coord_tensor<"(0,0,0)", "((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">, %7 : i32, %8 : i32, %9 : i32) {use_pdl = false}
    return
  }
}
