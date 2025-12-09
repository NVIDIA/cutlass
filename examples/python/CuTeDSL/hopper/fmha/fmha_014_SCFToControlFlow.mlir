!memref_gmem_f16_ = !cute.memref<f16, gmem, align<16>, "((1,256,1,1,1),(?,?,?,?,?)):((0,1,0,0,0),(?{i64},256,?{i64},?{i64},?{i64}))">
!memref_gmem_f16_1 = !cute.memref<f16, gmem, align<16>, "(?,?,?,?,?):(?{i64},1,?{i64},?{i64},?{i64})">
!memref_gmem_f32_ = !cute.memref<f32, gmem, align<16>, "((1,256,1,1,1),(?,?,?,?,?)):((0,?{i64},0,0,0),(?{i64},?{i64 div=256},?{i64},1,?{i64}))">
!memref_gmem_f32_1 = !cute.memref<f32, gmem, align<16>, "(?,?,?,?,?):(?{i64},?{i64},?{i64},1,?{i64})">
!memref_rmem_f16_ = !cute.memref<f16, rmem, align<32>, "2:1">
!memref_rmem_f32_ = !cute.memref<f32, rmem, align<32>, "2:1">
#loop_unroll = #llvm.loop_unroll<disable = false, full = true>
#loop_annotation = #llvm.loop_annotation<unroll = #loop_unroll>
module attributes {gpu.container_module} {
  gpu.module @kernels {
    cuda.kernel @kernel_cutlass__convert_kernel_tensorptrf16gmemalign16o125611101000256_tensorptrf32gmemalign16o12561110000i64div2561_tensor00000o1256111011000102561121314______Float16_Float32_0(%arg0: !memref_gmem_f16_, %arg1: !memref_gmem_f32_, %arg2: !cute.coord_tensor<"(0,0,0,0,0)", "((1,256,1,1,1),(?,?,?,?,?)):((0,1@1,0,0,0),(1@0,256@1,1@2,1@3,1@4))">, %arg3: i32, %arg4: i32, %arg5: i32, %arg6: i32, %arg7: i32) attributes {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} {
      %0 = cute.static : !cute.shape<"(2,((1)))">
      %1 = cute.static : !cute.shape<"(2,(1))">
      %c1_i32 = arith.constant 1 : i32
      %c0_i32 = arith.constant 0 : i32
      %2 = cute.static : !cute.int_tuple<"1">
      %3 = cute.static : !cute.layout<"1:0">
      %4 = cute.static : !cute.layout<"(128,2):(2@1,1@1)">
      %5 = cute.static : !cute.shape<"(2)">
      %6 = cute.static : !cute.shape<"(128,2)">
      %c2_i64 = arith.constant 2 : i64
      %7 = cute.static : !cute.int_tuple<"(0,0,0,0,0)">
      %8 = cute.static : !cute.shape<"((1,256,1,1,1))">
      %9 = cute.static : !cute.layout<"(128,2):(2,1)">
      %10 = nvvm.read.ptx.sreg.tid.x range <i32, 0, 1024> : i32
      %11 = nvvm.read.ptx.sreg.ctaid.x range <i32, 0, 2147483647> : i32
      %coord = cute.make_coord(%11) : (i32) -> !cute.coord<"(_,?)">
      %lay = cute.get_layout(%arg0) : !memref_gmem_f16_
      %idx = cute.crd2idx(%coord, %lay) : (!cute.coord<"(_,?)">, !cute.layout<"((1,256,1,1,1),(?,?,?,?,?)):((0,1,0,0,0),(?{i64},256,?{i64},?{i64},?{i64}))">) -> !cute.int_tuple<"?{i64}">
      %iter = cute.get_iter(%arg0) : !memref_gmem_f16_
      %ptr = cute.add_offset(%iter, %idx) : (!cute.ptr<f16, gmem, align<16>>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f16, gmem>
      %lay_0 = cute.get_layout(%arg1) : !memref_gmem_f32_
      %12:10 = cute.get_scalars(%lay_0) <{only_dynamic}> : !cute.layout<"((1,256,1,1,1),(?,?,?,?,?)):((0,?{i64},0,0,0),(?{i64},?{i64 div=256},?{i64},1,?{i64}))">
      %stride = cute.make_stride(%12#5) : (i64) -> !cute.stride<"((0,?{i64},0,0,0))">
      %lay_1 = cute.make_layout(%8, %stride) : !cute.layout<"((1,256,1,1,1)):((0,?{i64},0,0,0))">
      %idx_2 = cute.crd2idx(%coord, %lay_0) : (!cute.coord<"(_,?)">, !cute.layout<"((1,256,1,1,1),(?,?,?,?,?)):((0,?{i64},0,0,0),(?{i64},?{i64 div=256},?{i64},1,?{i64}))">) -> !cute.int_tuple<"?{i64}">
      %iter_3 = cute.get_iter(%arg1) : !memref_gmem_f32_
      %ptr_4 = cute.add_offset(%iter_3, %idx_2) : (!cute.ptr<f32, gmem, align<16>>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %lay_5 = cute.get_layout(%arg2) : !cute.coord_tensor<"(0,0,0,0,0)", "((1,256,1,1,1),(?,?,?,?,?)):((0,1@1,0,0,0),(1@0,256@1,1@2,1@3,1@4))">
      %idx_6 = cute.crd2idx(%coord, %lay_5) : (!cute.coord<"(_,?)">, !cute.layout<"((1,256,1,1,1),(?,?,?,?,?)):((0,1@1,0,0,0),(1@0,256@1,1@2,1@3,1@4))">) -> !cute.int_tuple<"(?,?{div=256},?,?,?)">
      %tup = cute.add_offset(%7, %idx_6) : (!cute.int_tuple<"(0,0,0,0,0)">, !cute.int_tuple<"(?,?{div=256},?,?,?)">) -> !cute.int_tuple<"(?,?{div=256},?,?,?)">
      %13 = cute.get_scalars(%lay_1) <{only_dynamic}> : !cute.layout<"((1,256,1,1,1)):((0,?{i64},0,0,0))">
      %14 = arith.muli %13, %c2_i64 : i64
      %iv = cute.assume(%14) : (i64) -> !cute.i64<divby 2>
      %stride_7 = cute.make_stride(%iv, %13) : (!cute.i64<divby 2>, i64) -> !cute.stride<"(?{i64 div=2},?{i64})">
      %lay_8 = cute.make_layout(%6, %stride_7) : !cute.layout<"(128,2):(?{i64 div=2},?{i64})">
      %coord_9 = cute.make_coord(%10) : (i32) -> !cute.coord<"(?,_)">
      %idx_10 = cute.crd2idx(%coord_9, %9) : (!cute.coord<"(?,_)">, !cute.layout<"(128,2):(2,1)">) -> !cute.int_tuple<"?{div=2}">
      %ptr_11 = cute.add_offset(%ptr, %idx_10) : (!cute.ptr<f16, gmem>, !cute.int_tuple<"?{div=2}">) -> !cute.ptr<f16, gmem>
      %15:2 = cute.get_scalars(%lay_8) <{only_dynamic}> : !cute.layout<"(128,2):(?{i64 div=2},?{i64})">
      %stride_12 = cute.make_stride(%15#1) : (i64) -> !cute.stride<"(?{i64})">
      %lay_13 = cute.make_layout(%5, %stride_12) : !cute.layout<"(2):(?{i64})">
      %idx_14 = cute.crd2idx(%coord_9, %lay_8) : (!cute.coord<"(?,_)">, !cute.layout<"(128,2):(?{i64 div=2},?{i64})">) -> !cute.int_tuple<"?{i64 div=2}">
      %ptr_15 = cute.add_offset(%ptr_4, %idx_14) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
      %idx_16 = cute.crd2idx(%coord_9, %4) : (!cute.coord<"(?,_)">, !cute.layout<"(128,2):(2@1,1@1)">) -> !cute.int_tuple<"(0,?{div=2})">
      %tup_17 = cute.add_offset(%tup, %idx_16) : (!cute.int_tuple<"(?,?{div=256},?,?,?)">, !cute.int_tuple<"(0,?{div=2})">) -> !cute.int_tuple<"(?,?{div=2},?,?,?)">
      %e0, %e1, %e2, %e3, %e4 = cute.get_leaves(%tup_17) : !cute.int_tuple<"(?,?{div=2},?,?,?)">
      %coord_18 = cute.make_coord(%e0, %e1, %e2, %e3, %e4) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=2}">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?{div=2},?,?,?)">
      %coord_19 = cute.make_coord(%arg3, %arg4, %arg5, %arg6, %arg7) : (i32, i32, i32, i32, i32) -> !cute.coord<"(?,?,?,?,?)">
      %16:5 = cute.get_scalars(%coord_18) : !cute.coord<"(?,?{div=2},?,?,?)">
      %17:5 = cute.get_scalars(%coord_19) : !cute.coord<"(?,?,?,?,?)">
      %18 = arith.cmpi slt, %16#0, %17#0 : i32
      %19 = arith.cmpi slt, %16#1, %17#1 : i32
      %20 = arith.andi %18, %19 : i1
      %21 = arith.cmpi slt, %16#2, %17#2 : i32
      %22 = arith.andi %20, %21 : i1
      %23 = arith.cmpi slt, %16#3, %17#3 : i32
      %24 = arith.andi %22, %23 : i1
      %25 = arith.cmpi slt, %16#4, %17#4 : i32
      %26 = arith.andi %24, %25 : i1
      cf.cond_br %26, ^bb1, ^bb8
    ^bb1:  // pred: ^bb0
      %rmem = cute.memref.alloca() : !memref_rmem_f16_
      %iter_20 = cute.get_iter(%rmem) : !memref_rmem_f16_
      %rmem_21 = cute.memref.alloca() : !memref_rmem_f32_
      %iter_22 = cute.get_iter(%rmem_21) : !memref_rmem_f32_
      %27 = cute.get_scalars(%2) : !cute.int_tuple<"1">
      %28 = builtin.unrealized_conversion_cast %ptr_11 : !cute.ptr<f16, gmem> to !llvm.ptr<1>
      %29 = builtin.unrealized_conversion_cast %iter_20 : !cute.ptr<f16, rmem, align<32>> to !llvm.ptr
      %ptr_23 = cute.add_offset(%ptr_11, %2) : (!cute.ptr<f16, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f16, gmem>
      %ptr_24 = cute.add_offset(%iter_20, %2) : (!cute.ptr<f16, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f16, rmem>
      %30 = builtin.unrealized_conversion_cast %ptr_23 : !cute.ptr<f16, gmem> to !llvm.ptr<1>
      %31 = builtin.unrealized_conversion_cast %ptr_24 : !cute.ptr<f16, rmem> to !llvm.ptr
      cf.br ^bb2(%c0_i32 : i32)
    ^bb2(%32: i32):  // 2 preds: ^bb1, ^bb3
      %33 = arith.cmpi slt, %32, %27 : i32
      cf.cond_br %33, ^bb3, ^bb4 {llvm.loop_annotation = #loop_annotation}
    ^bb3:  // pred: ^bb2
      %34 = llvm.load %28 {alignment = 2 : i64} : !llvm.ptr<1> -> vector<1xf16>
      llvm.store %34, %29 {alignment = 2 : i64} : vector<1xf16>, !llvm.ptr
      %35 = llvm.load %30 {alignment = 2 : i64} : !llvm.ptr<1> -> vector<1xf16>
      llvm.store %35, %31 {alignment = 2 : i64} : vector<1xf16>, !llvm.ptr
      %36 = arith.addi %32, %c1_i32 : i32
      cf.br ^bb2(%36 : i32)
    ^bb4:  // pred: ^bb2
      %37 = cute.memref.load_vec %rmem : !memref_rmem_f16_
      %38 = arith.extf %37 : vector<2xf16> to vector<2xf32>
      cute.memref.store_vec %38, %rmem_21 : !memref_rmem_f32_
      %append = cute.append_to_rank<2> (%lay_13, %3) : !cute.layout<"(2):(?{i64})">, !cute.layout<"1:0">
      %39 = cute.get_scalars(%append) <{only_dynamic}> : !cute.layout<"(2,1):(?{i64},0)">
      %stride_25 = cute.make_stride(%39) : (i64) -> !cute.stride<"(?{i64},(0))">
      %lay_26 = cute.make_layout(%1, %stride_25) : !cute.layout<"(2,(1)):(?{i64},(0))">
      %append_27 = cute.append_to_rank<2> (%lay_26, %3) : !cute.layout<"(2,(1)):(?{i64},(0))">, !cute.layout<"1:0">
      %40 = cute.get_scalars(%append_27) <{only_dynamic}> : !cute.layout<"(2,(1)):(?{i64},(0))">
      %stride_28 = cute.make_stride(%40) : (i64) -> !cute.stride<"(?{i64},((0)))">
      %lay_29 = cute.make_layout(%0, %stride_28) : !cute.layout<"(2,((1))):(?{i64},((0)))">
      %41 = cute.get_scalars(%lay_29) <{only_dynamic}> : !cute.layout<"(2,((1))):(?{i64},((0)))">
      %stride_30 = cute.make_stride(%41) : (i64) -> !cute.stride<"(?{i64})">
      %lay_31 = cute.make_layout(%5, %stride_30) : !cute.layout<"(2):(?{i64})">
      %42 = cute.get_scalars(%lay_31) <{only_dynamic}> : !cute.layout<"(2):(?{i64})">
      %43 = builtin.unrealized_conversion_cast %iter_22 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
      %44 = builtin.unrealized_conversion_cast %ptr_15 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      %ptr_32 = cute.add_offset(%iter_22, %2) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
      %int_tuple = cute.make_int_tuple(%42) : (i64) -> !cute.int_tuple<"?{i64}">
      %ptr_33 = cute.add_offset(%ptr_15, %int_tuple) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %45 = builtin.unrealized_conversion_cast %ptr_32 : !cute.ptr<f32, rmem> to !llvm.ptr
      %46 = builtin.unrealized_conversion_cast %ptr_33 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
      cf.br ^bb5(%c0_i32 : i32)
    ^bb5(%47: i32):  // 2 preds: ^bb4, ^bb6
      %48 = arith.cmpi slt, %47, %27 : i32
      cf.cond_br %48, ^bb6, ^bb7 {llvm.loop_annotation = #loop_annotation}
    ^bb6:  // pred: ^bb5
      %49 = llvm.load %43 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
      llvm.store %49, %44 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
      %50 = llvm.load %45 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
      llvm.store %50, %46 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
      %51 = arith.addi %47, %c1_i32 : i32
      cf.br ^bb5(%51 : i32)
    ^bb7:  // pred: ^bb5
      cf.br ^bb8
    ^bb8:  // 2 preds: ^bb0, ^bb7
      return
    }
  }
  func.func @cutlass__convert_Tensorgmemoi641i64i64i64_Tensorgmemoi64i64i641i64_1_2(%arg0: !memref_gmem_f16_1, %arg1: !memref_gmem_f32_1) -> i32 attributes {llvm.emit_c_interface} {
    %c1_i32 = arith.constant 1 : i32
    %c128_i32 = arith.constant 128 : i32
    %c0_i64 = arith.constant 0 : i64
    %c0_i32 = arith.constant 0 : i32
    %c256_i64 = arith.constant 256 : i64
    %0 = cute.static : !cute.stride<"((0,1@1,0,0,0),(1@0,256@1,1@2,1@3,1@4))">
    %c256_i32 = arith.constant 256 : i32
    %1 = cute.static : !cute.stride<"(1@0,1@1,1@2,1@3,1@4)">
    %2 = cute.static : !cute.int_tuple<"(0,0,0,0,0)">
    %lay = cute.get_layout(%arg0) : !memref_gmem_f16_1
    %3 = cute.get_shape(%lay) : (!cute.layout<"(?,?,?,?,?):(?{i64},1,?{i64},?{i64},?{i64})">) -> !cute.shape<"(?,?,?,?,?)">
    %e0, %e1, %e2, %e3, %e4 = cute.get_leaves(%3) : !cute.shape<"(?,?,?,?,?)">
    %itup = cute.to_int_tuple(%e0) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %4 = cute.get_scalars(%itup) : !cute.int_tuple<"?">
    %itup_0 = cute.to_int_tuple(%e1) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %5 = cute.get_scalars(%itup_0) : !cute.int_tuple<"?">
    %itup_1 = cute.to_int_tuple(%e2) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %6 = cute.get_scalars(%itup_1) : !cute.int_tuple<"?">
    %itup_2 = cute.to_int_tuple(%e3) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %7 = cute.get_scalars(%itup_2) : !cute.int_tuple<"?">
    %itup_3 = cute.to_int_tuple(%e4) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %8 = cute.get_scalars(%itup_3) : !cute.int_tuple<"?">
    %shape = cute.make_shape(%itup, %itup_0, %itup_1, %itup_2, %itup_3) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.shape<"(?,?,?,?,?)">
    %lay_4 = cute.make_layout(%shape, %1) : !cute.layout<"(?,?,?,?,?):(1@0,1@1,1@2,1@3,1@4)">
    %iter = cute.get_iter(%arg0) : !memref_gmem_f16_1
    %9:9 = cute.get_scalars(%lay) <{only_dynamic}> : !cute.layout<"(?,?,?,?,?):(?{i64},1,?{i64},?{i64},?{i64})">
    %10 = arith.ceildivsi %9#1, %c256_i32 : i32
    %shape_5 = cute.make_shape(%9#0, %10, %9#2, %9#3, %9#4) : (i32, i32, i32, i32, i32) -> !cute.shape<"((1,256,1,1,1),(?,?,?,?,?))">
    %stride = cute.make_stride(%9#5, %9#6, %9#7, %9#8) : (i64, i64, i64, i64) -> !cute.stride<"((0,1,0,0,0),(?{i64},256,?{i64},?{i64},?{i64}))">
    %lay_6 = cute.make_layout(%shape_5, %stride) : !cute.layout<"((1,256,1,1,1),(?,?,?,?,?)):((0,1,0,0,0),(?{i64},256,?{i64},?{i64},?{i64}))">
    %view = cute.make_view(%iter, %lay_6) : !memref_gmem_f16_
    %11:5 = cute.get_scalars(%lay_4) <{only_dynamic}> : !cute.layout<"(?,?,?,?,?):(1@0,1@1,1@2,1@3,1@4)">
    %12 = arith.ceildivsi %11#1, %c256_i32 : i32
    %shape_7 = cute.make_shape(%11#0, %12, %11#2, %11#3, %11#4) : (i32, i32, i32, i32, i32) -> !cute.shape<"((1,256,1,1,1),(?,?,?,?,?))">
    %lay_8 = cute.make_layout(%shape_7, %0) : !cute.layout<"((1,256,1,1,1),(?,?,?,?,?)):((0,1@1,0,0,0),(1@0,256@1,1@2,1@3,1@4))">
    %view_9 = cute.make_view(%2, %lay_8) : !cute.coord_tensor<"(0,0,0,0,0)", "((1,256,1,1,1),(?,?,?,?,?)):((0,1@1,0,0,0),(1@0,256@1,1@2,1@3,1@4))">
    %iter_10 = cute.get_iter(%arg1) : !memref_gmem_f32_1
    %lay_11 = cute.get_layout(%arg1) : !memref_gmem_f32_1
    %13:9 = cute.get_scalars(%lay_11) <{only_dynamic}> : !cute.layout<"(?,?,?,?,?):(?{i64},?{i64},?{i64},1,?{i64})">
    %14 = arith.ceildivsi %13#1, %c256_i32 : i32
    %15 = arith.muli %13#6, %c256_i64 : i64
    %shape_12 = cute.make_shape(%13#0, %14, %13#2, %13#3, %13#4) : (i32, i32, i32, i32, i32) -> !cute.shape<"((1,256,1,1,1),(?,?,?,?,?))">
    %iv = cute.assume(%15) : (i64) -> !cute.i64<divby 256>
    %stride_13 = cute.make_stride(%13#6, %13#5, %iv, %13#7, %13#8) : (i64, i64, !cute.i64<divby 256>, i64, i64) -> !cute.stride<"((0,?{i64},0,0,0),(?{i64},?{i64 div=256},?{i64},1,?{i64}))">
    %lay_14 = cute.make_layout(%shape_12, %stride_13) : !cute.layout<"((1,256,1,1,1),(?,?,?,?,?)):((0,?{i64},0,0,0),(?{i64},?{i64 div=256},?{i64},1,?{i64}))">
    %view_15 = cute.make_view(%iter_10, %lay_14) : !memref_gmem_f32_
    %sz = cute.size(%lay_6) <{mode = [1]}> : (!cute.layout<"((1,256,1,1,1),(?,?,?,?,?)):((0,1,0,0,0),(?{i64},256,?{i64},?{i64},?{i64}))">) -> !cute.int_tuple<"?">
    %e0_16 = cute.get_leaves(%sz) : !cute.int_tuple<"?">
    %16 = cute.get_scalars(%e0_16) : !cute.int_tuple<"?">
    %17 = cuda.cast %c0_i64 : i64 -> !cuda.stream
    %18 = cuda.launch_cfg.create<max_attrs = 2 : i32> (blockDim = (%c128_i32, %c1_i32, %c1_i32), dynamicSmemBytes = %c0_i64, gridDim = (%16, %c1_i32, %c1_i32), stream = %17) : i32, i32, i32, i64, i32, i32, i32, !cuda.stream -> !cuda.launch_cfg<max_attrs = 2>
    %19 = cuda.launch_ex @kernels::@kernel_cutlass__convert_kernel_tensorptrf16gmemalign16o125611101000256_tensorptrf32gmemalign16o12561110000i64div2561_tensor00000o1256111011000102561121314______Float16_Float32_0<%18> (%view, %view_15, %view_9, %4, %5, %6, %7, %8) : !cuda.launch_cfg<max_attrs = 2>, (!memref_gmem_f16_, !memref_gmem_f32_, !cute.coord_tensor<"(0,0,0,0,0)", "((1,256,1,1,1),(?,?,?,?,?)):((0,1@1,0,0,0),(1@0,256@1,1@2,1@3,1@4))">, i32, i32, i32, i32, i32) -> !cuda.result
    %20 = cuda.cast %19 : !cuda.result -> i32
    cuda.return_if_error %20 : i32
    return %c0_i32 : i32
  }
}
