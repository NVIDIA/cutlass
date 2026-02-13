!memref_gmem_f32_ = !cute.memref<f32, gmem, "((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">
!memref_gmem_f32_1 = !cute.memref<f32, gmem, "(?,?,?):(?{i64},1,?{i64})">
!memref_gmem_f8E4M3FN = !cute.memref<f8E4M3FN, gmem, align<16>, "((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">
!memref_gmem_f8E4M3FN1 = !cute.memref<f8E4M3FN, gmem, align<16>, "(?,?,?):(?{i64},1,?{i64})">
!memref_rmem_f32_ = !cute.memref<f32, rmem, align<32>, "4:1">
!memref_rmem_f8E4M3FN = !cute.memref<f8E4M3FN, rmem, align<32>, "4:1">
#loop_unroll = #llvm.loop_unroll<disable = false, full = true>
#loop_annotation = #llvm.loop_annotation<unroll = #loop_unroll>
module attributes {gpu.container_module} {
  gpu.module @kernels {
    cuda.kernel @kernel_cutlass__convert_kernel_tensorptrf32gmemo15121010512_tensorptrf8E4M3FNgmemalign16o15121010512_tensor000o15121011010512112____Float32_Float8E4M3FN_0(%arg0: !memref_gmem_f32_, %arg1: !memref_gmem_f8E4M3FN, %arg2: !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">, %arg3: i32, %arg4: i32, %arg5: i32) attributes {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} {
      %0 = cute.static : !cute.int_tuple<"3">
      %1 = cute.static : !cute.int_tuple<"2">
      %c1_i32 = arith.constant 1 : i32
      %c0_i32 = arith.constant 0 : i32
      %2 = cute.static : !cute.int_tuple<"1">
      %3 = cute.static : !cute.layout<"(128,4):(4@1,1@1)">
      %4 = cute.static : !cute.int_tuple<"(0,0,0)">
      %5 = cute.static : !cute.layout<"(128,4):(4,1)">
      %6 = nvvm.read.ptx.sreg.tid.x range <i32, 0, 1024> : i32
      %7 = nvvm.read.ptx.sreg.ctaid.x range <i32, 0, 2147483647> : i32
      %coord = cute.make_coord(%7) : (i32) -> !cute.coord<"(_,?)">
      %lay = cute.get_layout(%arg0) : !memref_gmem_f32_
      %idx = cute.crd2idx(%coord, %lay) : (!cute.coord<"(_,?)">, !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !cute.int_tuple<"?{i64}">
      %iter = cute.get_iter(%arg0) : !memref_gmem_f32_
      %ptr = cute.add_offset(%iter, %idx) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %lay_0 = cute.get_layout(%arg1) : !memref_gmem_f8E4M3FN
      %idx_1 = cute.crd2idx(%coord, %lay_0) : (!cute.coord<"(_,?)">, !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !cute.int_tuple<"?{i64}">
      %iter_2 = cute.get_iter(%arg1) : !memref_gmem_f8E4M3FN
      %ptr_3 = cute.add_offset(%iter_2, %idx_1) : (!cute.ptr<f8E4M3FN, gmem, align<16>>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f8E4M3FN, gmem>
      %lay_4 = cute.get_layout(%arg2) : !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">
      %idx_5 = cute.crd2idx(%coord, %lay_4) : (!cute.coord<"(_,?)">, !cute.layout<"((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">) -> !cute.int_tuple<"(?,?{div=512},?)">
      %tup = cute.add_offset(%4, %idx_5) : (!cute.int_tuple<"(0,0,0)">, !cute.int_tuple<"(?,?{div=512},?)">) -> !cute.int_tuple<"(?,?{div=512},?)">
      %coord_6 = cute.make_coord(%6) : (i32) -> !cute.coord<"(?,_)">
      %idx_7 = cute.crd2idx(%coord_6, %5) : (!cute.coord<"(?,_)">, !cute.layout<"(128,4):(4,1)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_8 = cute.add_offset(%ptr, %idx_7) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, gmem>
      %ptr_9 = cute.add_offset(%ptr_3, %idx_7) : (!cute.ptr<f8E4M3FN, gmem>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f8E4M3FN, gmem>
      %idx_10 = cute.crd2idx(%coord_6, %3) : (!cute.coord<"(?,_)">, !cute.layout<"(128,4):(4@1,1@1)">) -> !cute.int_tuple<"(0,?{div=4})">
      %tup_11 = cute.add_offset(%tup, %idx_10) : (!cute.int_tuple<"(?,?{div=512},?)">, !cute.int_tuple<"(0,?{div=4})">) -> !cute.int_tuple<"(?,?{div=4},?)">
      %e0, %e1, %e2 = cute.get_leaves(%tup_11) : !cute.int_tuple<"(?,?{div=4},?)">
      %coord_12 = cute.make_coord(%e0, %e1, %e2) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=4}">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?{div=4},?)">
      %coord_13 = cute.make_coord(%arg3, %arg4, %arg5) : (i32, i32, i32) -> !cute.coord<"(?,?,?)">
      %8:3 = cute.get_scalars(%coord_12) : !cute.coord<"(?,?{div=4},?)">
      %9:3 = cute.get_scalars(%coord_13) : !cute.coord<"(?,?,?)">
      %10 = arith.cmpi slt, %8#0, %9#0 : i32
      %11 = arith.cmpi slt, %8#1, %9#1 : i32
      %12 = arith.andi %10, %11 : i1
      %13 = arith.cmpi slt, %8#2, %9#2 : i32
      %14 = arith.andi %12, %13 : i1
      cf.cond_br %14, ^bb1, ^bb8
    ^bb1:  // pred: ^bb0
      %rmem = cute.memref.alloca() : !memref_rmem_f32_
      %iter_14 = cute.get_iter(%rmem) : !memref_rmem_f32_
      %rmem_15 = cute.memref.alloca() : !memref_rmem_f8E4M3FN
      %iter_16 = cute.get_iter(%rmem_15) : !memref_rmem_f8E4M3FN
      %15 = cute.get_scalars(%2) : !cute.int_tuple<"1">
      %16 = builtin.unrealized_conversion_cast %ptr_8 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %17 = builtin.unrealized_conversion_cast %iter_14 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
      %ptr_17 = cute.add_offset(%ptr_8, %2) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
      %ptr_18 = cute.add_offset(%iter_14, %2) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
      %18 = builtin.unrealized_conversion_cast %ptr_17 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %19 = builtin.unrealized_conversion_cast %ptr_18 : !cute.ptr<f32, rmem> to !llvm.ptr
      %ptr_19 = cute.add_offset(%ptr_8, %1) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
      %ptr_20 = cute.add_offset(%iter_14, %1) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
      %20 = builtin.unrealized_conversion_cast %ptr_19 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %21 = builtin.unrealized_conversion_cast %ptr_20 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
      %ptr_21 = cute.add_offset(%ptr_8, %0) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
      %ptr_22 = cute.add_offset(%iter_14, %0) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
      %22 = builtin.unrealized_conversion_cast %ptr_21 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %23 = builtin.unrealized_conversion_cast %ptr_22 : !cute.ptr<f32, rmem> to !llvm.ptr
      cf.br ^bb2(%c0_i32 : i32)
    ^bb2(%24: i32):  // 2 preds: ^bb1, ^bb3
      %25 = arith.cmpi slt, %24, %15 : i32
      cf.cond_br %25, ^bb3, ^bb4 {llvm.loop_annotation = #loop_annotation}
    ^bb3:  // pred: ^bb2
      %26 = llvm.load %16 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %26, %17 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      %27 = llvm.load %18 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %27, %19 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      %28 = llvm.load %20 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %28, %21 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      %29 = llvm.load %22 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
      llvm.store %29, %23 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
      %30 = arith.addi %24, %c1_i32 : i32
      cf.br ^bb2(%30 : i32)
    ^bb4:  // pred: ^bb2
      %31 = cute.memref.load_vec %rmem : !memref_rmem_f32_
      %32 = nvgpu.cvt_fptrunc %31 : vector<4xf32> to vector<4xf8E4M3FN>
      cute.memref.store_vec %32, %rmem_15 : !memref_rmem_f8E4M3FN
      %33 = builtin.unrealized_conversion_cast %iter_16 : !cute.ptr<f8E4M3FN, rmem, align<32>> to !llvm.ptr
      %34 = builtin.unrealized_conversion_cast %ptr_9 : !cute.ptr<f8E4M3FN, gmem> to !llvm.ptr<1>
      %ptr_23 = cute.add_offset(%iter_16, %2) : (!cute.ptr<f8E4M3FN, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f8E4M3FN, rmem>
      %ptr_24 = cute.add_offset(%ptr_9, %2) : (!cute.ptr<f8E4M3FN, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f8E4M3FN, gmem>
      %35 = builtin.unrealized_conversion_cast %ptr_23 : !cute.ptr<f8E4M3FN, rmem> to !llvm.ptr
      %36 = builtin.unrealized_conversion_cast %ptr_24 : !cute.ptr<f8E4M3FN, gmem> to !llvm.ptr<1>
      %ptr_25 = cute.add_offset(%iter_16, %1) : (!cute.ptr<f8E4M3FN, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f8E4M3FN, rmem, align<2>>
      %ptr_26 = cute.add_offset(%ptr_9, %1) : (!cute.ptr<f8E4M3FN, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f8E4M3FN, gmem>
      %37 = builtin.unrealized_conversion_cast %ptr_25 : !cute.ptr<f8E4M3FN, rmem, align<2>> to !llvm.ptr
      %38 = builtin.unrealized_conversion_cast %ptr_26 : !cute.ptr<f8E4M3FN, gmem> to !llvm.ptr<1>
      %ptr_27 = cute.add_offset(%iter_16, %0) : (!cute.ptr<f8E4M3FN, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f8E4M3FN, rmem>
      %ptr_28 = cute.add_offset(%ptr_9, %0) : (!cute.ptr<f8E4M3FN, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f8E4M3FN, gmem>
      %39 = builtin.unrealized_conversion_cast %ptr_27 : !cute.ptr<f8E4M3FN, rmem> to !llvm.ptr
      %40 = builtin.unrealized_conversion_cast %ptr_28 : !cute.ptr<f8E4M3FN, gmem> to !llvm.ptr<1>
      cf.br ^bb5(%c0_i32 : i32)
    ^bb5(%41: i32):  // 2 preds: ^bb4, ^bb6
      %42 = arith.cmpi slt, %41, %15 : i32
      cf.cond_br %42, ^bb6, ^bb7 {llvm.loop_annotation = #loop_annotation}
    ^bb6:  // pred: ^bb5
      %43 = llvm.load %33 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
      llvm.store %43, %34 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
      %44 = llvm.load %35 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
      llvm.store %44, %36 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
      %45 = llvm.load %37 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
      llvm.store %45, %38 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
      %46 = llvm.load %39 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
      llvm.store %46, %40 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
      %47 = arith.addi %41, %c1_i32 : i32
      cf.br ^bb5(%47 : i32)
    ^bb7:  // pred: ^bb5
      cf.br ^bb8
    ^bb8:  // 2 preds: ^bb0, ^bb7
      return
    }
  }
  func.func @cutlass__convert_Tensorgmemoi641i64_Tensorgmemoi641i64_1_4(%arg0: !memref_gmem_f32_1, %arg1: !memref_gmem_f8E4M3FN1) -> i32 attributes {llvm.emit_c_interface} {
    %c1_i32 = arith.constant 1 : i32
    %c128_i32 = arith.constant 128 : i32
    %c0_i64 = arith.constant 0 : i64
    %c0_i32 = arith.constant 0 : i32
    %0 = cute.static : !cute.stride<"((0,1@1,0),(1@0,512@1,1@2))">
    %c512_i32 = arith.constant 512 : i32
    %1 = cute.static : !cute.stride<"(1@0,1@1,1@2)">
    %2 = cute.static : !cute.int_tuple<"(0,0,0)">
    %lay = cute.get_layout(%arg0) : !memref_gmem_f32_1
    %3 = cute.get_shape(%lay) : (!cute.layout<"(?,?,?):(?{i64},1,?{i64})">) -> !cute.shape<"(?,?,?)">
    %e0, %e1, %e2 = cute.get_leaves(%3) : !cute.shape<"(?,?,?)">
    %itup = cute.to_int_tuple(%e0) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %4 = cute.get_scalars(%itup) : !cute.int_tuple<"?">
    %itup_0 = cute.to_int_tuple(%e1) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %5 = cute.get_scalars(%itup_0) : !cute.int_tuple<"?">
    %itup_1 = cute.to_int_tuple(%e2) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %6 = cute.get_scalars(%itup_1) : !cute.int_tuple<"?">
    %shape = cute.make_shape(%itup, %itup_0, %itup_1) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.shape<"(?,?,?)">
    %lay_2 = cute.make_layout(%shape, %1) : !cute.layout<"(?,?,?):(1@0,1@1,1@2)">
    %iter = cute.get_iter(%arg0) : !memref_gmem_f32_1
    %7:5 = cute.get_scalars(%lay) <{only_dynamic}> : !cute.layout<"(?,?,?):(?{i64},1,?{i64})">
    %c1_i32_3 = arith.constant 1 : i32
    %c0_i32_4 = arith.constant 0 : i32
    %c-1_i32 = arith.constant -1 : i32
    %8 = arith.cmpi sgt, %c512_i32, %c0_i32_4 : i32
    %9 = arith.select %8, %c-1_i32, %c1_i32_3 : i32
    %10 = arith.addi %9, %7#1 : i32
    %11 = arith.divsi %10, %c512_i32 : i32
    %12 = arith.addi %c1_i32_3, %11 : i32
    %13 = arith.subi %c0_i32_4, %7#1 : i32
    %14 = arith.divsi %13, %c512_i32 : i32
    %15 = arith.subi %c0_i32_4, %14 : i32
    %16 = arith.cmpi slt, %7#1, %c0_i32_4 : i32
    %17 = arith.cmpi sgt, %7#1, %c0_i32_4 : i32
    %18 = arith.cmpi slt, %c512_i32, %c0_i32_4 : i32
    %19 = arith.cmpi sgt, %c512_i32, %c0_i32_4 : i32
    %20 = arith.andi %16, %18 : i1
    %21 = arith.andi %17, %19 : i1
    %22 = arith.ori %20, %21 : i1
    %23 = arith.select %22, %12, %15 : i32
    %shape_5 = cute.make_shape(%7#0, %23, %7#2) : (i32, i32, i32) -> !cute.shape<"((1,512,1),(?,?,?))">
    %stride = cute.make_stride(%7#3, %7#4) : (i64, i64) -> !cute.stride<"((0,1,0),(?{i64},512,?{i64}))">
    %lay_6 = cute.make_layout(%shape_5, %stride) : !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">
    %view = cute.make_view(%iter, %lay_6) : !memref_gmem_f32_
    %24:3 = cute.get_scalars(%lay_2) <{only_dynamic}> : !cute.layout<"(?,?,?):(1@0,1@1,1@2)">
    %c1_i32_7 = arith.constant 1 : i32
    %c0_i32_8 = arith.constant 0 : i32
    %c-1_i32_9 = arith.constant -1 : i32
    %25 = arith.cmpi sgt, %c512_i32, %c0_i32_8 : i32
    %26 = arith.select %25, %c-1_i32_9, %c1_i32_7 : i32
    %27 = arith.addi %26, %24#1 : i32
    %28 = arith.divsi %27, %c512_i32 : i32
    %29 = arith.addi %c1_i32_7, %28 : i32
    %30 = arith.subi %c0_i32_8, %24#1 : i32
    %31 = arith.divsi %30, %c512_i32 : i32
    %32 = arith.subi %c0_i32_8, %31 : i32
    %33 = arith.cmpi slt, %24#1, %c0_i32_8 : i32
    %34 = arith.cmpi sgt, %24#1, %c0_i32_8 : i32
    %35 = arith.cmpi slt, %c512_i32, %c0_i32_8 : i32
    %36 = arith.cmpi sgt, %c512_i32, %c0_i32_8 : i32
    %37 = arith.andi %33, %35 : i1
    %38 = arith.andi %34, %36 : i1
    %39 = arith.ori %37, %38 : i1
    %40 = arith.select %39, %29, %32 : i32
    %shape_10 = cute.make_shape(%24#0, %40, %24#2) : (i32, i32, i32) -> !cute.shape<"((1,512,1),(?,?,?))">
    %lay_11 = cute.make_layout(%shape_10, %0) : !cute.layout<"((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">
    %view_12 = cute.make_view(%2, %lay_11) : !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">
    %iter_13 = cute.get_iter(%arg1) : !memref_gmem_f8E4M3FN1
    %lay_14 = cute.get_layout(%arg1) : !memref_gmem_f8E4M3FN1
    %41:5 = cute.get_scalars(%lay_14) <{only_dynamic}> : !cute.layout<"(?,?,?):(?{i64},1,?{i64})">
    %c1_i32_15 = arith.constant 1 : i32
    %c0_i32_16 = arith.constant 0 : i32
    %c-1_i32_17 = arith.constant -1 : i32
    %42 = arith.cmpi sgt, %c512_i32, %c0_i32_16 : i32
    %43 = arith.select %42, %c-1_i32_17, %c1_i32_15 : i32
    %44 = arith.addi %43, %41#1 : i32
    %45 = arith.divsi %44, %c512_i32 : i32
    %46 = arith.addi %c1_i32_15, %45 : i32
    %47 = arith.subi %c0_i32_16, %41#1 : i32
    %48 = arith.divsi %47, %c512_i32 : i32
    %49 = arith.subi %c0_i32_16, %48 : i32
    %50 = arith.cmpi slt, %41#1, %c0_i32_16 : i32
    %51 = arith.cmpi sgt, %41#1, %c0_i32_16 : i32
    %52 = arith.cmpi slt, %c512_i32, %c0_i32_16 : i32
    %53 = arith.cmpi sgt, %c512_i32, %c0_i32_16 : i32
    %54 = arith.andi %50, %52 : i1
    %55 = arith.andi %51, %53 : i1
    %56 = arith.ori %54, %55 : i1
    %57 = arith.select %56, %46, %49 : i32
    %shape_18 = cute.make_shape(%41#0, %57, %41#2) : (i32, i32, i32) -> !cute.shape<"((1,512,1),(?,?,?))">
    %stride_19 = cute.make_stride(%41#3, %41#4) : (i64, i64) -> !cute.stride<"((0,1,0),(?{i64},512,?{i64}))">
    %lay_20 = cute.make_layout(%shape_18, %stride_19) : !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">
    %view_21 = cute.make_view(%iter_13, %lay_20) : !memref_gmem_f8E4M3FN
    %sz = cute.size(%lay_6) <{mode = [1]}> : (!cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !cute.int_tuple<"?">
    %e0_22 = cute.get_leaves(%sz) : !cute.int_tuple<"?">
    %58 = cute.get_scalars(%e0_22) : !cute.int_tuple<"?">
    %59 = cuda.cast %c0_i64 : i64 -> !cuda.stream
    %60 = cuda.launch_cfg.create<max_attrs = 2 : i32> (blockDim = (%c128_i32, %c1_i32, %c1_i32), dynamicSmemBytes = %c0_i64, gridDim = (%58, %c1_i32, %c1_i32), stream = %59) : i32, i32, i32, i64, i32, i32, i32, !cuda.stream -> !cuda.launch_cfg<max_attrs = 2>
    %61 = cuda.launch_ex @kernels::@kernel_cutlass__convert_kernel_tensorptrf32gmemo15121010512_tensorptrf8E4M3FNgmemalign16o15121010512_tensor000o15121011010512112____Float32_Float8E4M3FN_0<%60> (%view, %view_21, %view_12, %4, %5, %6) : !cuda.launch_cfg<max_attrs = 2>, (!memref_gmem_f32_, !memref_gmem_f8E4M3FN, !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">, i32, i32, i32) -> !cuda.result
    %62 = cuda.cast %61 : !cuda.result -> i32
    cuda.return_if_error %62 : i32
    return %c0_i32 : i32
  }
}
