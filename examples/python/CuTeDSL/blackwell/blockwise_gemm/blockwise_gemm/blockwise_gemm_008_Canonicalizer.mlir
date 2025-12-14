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
      %coord_0 = cute.make_coord(%7) : (i32) -> !cute.coord<"(_,?)">
      %lay_1 = cute.get_layout(%arg1) : !memref_gmem_f8E4M3FN
      %idx_2 = cute.crd2idx(%coord_0, %lay_1) : (!cute.coord<"(_,?)">, !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !cute.int_tuple<"?{i64}">
      %iter_3 = cute.get_iter(%arg1) : !memref_gmem_f8E4M3FN
      %ptr_4 = cute.add_offset(%iter_3, %idx_2) : (!cute.ptr<f8E4M3FN, gmem, align<16>>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f8E4M3FN, gmem>
      %coord_5 = cute.make_coord(%7) : (i32) -> !cute.coord<"(_,?)">
      %lay_6 = cute.get_layout(%arg2) : !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">
      %idx_7 = cute.crd2idx(%coord_5, %lay_6) : (!cute.coord<"(_,?)">, !cute.layout<"((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">) -> !cute.int_tuple<"(?,?{div=512},?)">
      %tup = cute.add_offset(%4, %idx_7) : (!cute.int_tuple<"(0,0,0)">, !cute.int_tuple<"(?,?{div=512},?)">) -> !cute.int_tuple<"(?,?{div=512},?)">
      %coord_8 = cute.make_coord(%6) : (i32) -> !cute.coord<"(?,_)">
      %idx_9 = cute.crd2idx(%coord_8, %5) : (!cute.coord<"(?,_)">, !cute.layout<"(128,4):(4,1)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_10 = cute.add_offset(%ptr, %idx_9) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, gmem>
      %coord_11 = cute.make_coord(%6) : (i32) -> !cute.coord<"(?,_)">
      %idx_12 = cute.crd2idx(%coord_11, %5) : (!cute.coord<"(?,_)">, !cute.layout<"(128,4):(4,1)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_13 = cute.add_offset(%ptr_4, %idx_12) : (!cute.ptr<f8E4M3FN, gmem>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f8E4M3FN, gmem>
      %coord_14 = cute.make_coord(%6) : (i32) -> !cute.coord<"(?,_)">
      %idx_15 = cute.crd2idx(%coord_14, %3) : (!cute.coord<"(?,_)">, !cute.layout<"(128,4):(4@1,1@1)">) -> !cute.int_tuple<"(0,?{div=4})">
      %tup_16 = cute.add_offset(%tup, %idx_15) : (!cute.int_tuple<"(?,?{div=512},?)">, !cute.int_tuple<"(0,?{div=4})">) -> !cute.int_tuple<"(?,?{div=4},?)">
      %e0, %e1, %e2 = cute.get_leaves(%tup_16) : !cute.int_tuple<"(?,?{div=4},?)">
      %coord_17 = cute.make_coord(%e0, %e1, %e2) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=4}">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?{div=4},?)">
      %coord_18 = cute.make_coord(%arg3, %arg4, %arg5) : (i32, i32, i32) -> !cute.coord<"(?,?,?)">
      %8:3 = cute.get_scalars(%coord_17) : !cute.coord<"(?,?{div=4},?)">
      %9:3 = cute.get_scalars(%coord_18) : !cute.coord<"(?,?,?)">
      %10 = arith.cmpi slt, %8#0, %9#0 : i32
      %11 = arith.cmpi slt, %8#1, %9#1 : i32
      %12 = arith.andi %10, %11 : i1
      %13 = arith.cmpi slt, %8#2, %9#2 : i32
      %14 = arith.andi %12, %13 : i1
      scf.if %14 {
        %rmem = cute.memref.alloca() : !memref_rmem_f32_
        %iter_19 = cute.get_iter(%rmem) : !memref_rmem_f32_
        %rmem_20 = cute.memref.alloca() : !memref_rmem_f8E4M3FN
        %iter_21 = cute.get_iter(%rmem_20) : !memref_rmem_f8E4M3FN
        %15 = cute.get_scalars(%2) : !cute.int_tuple<"1">
        scf.for %arg6 = %c0_i32 to %15 step %c1_i32  : i32 {
          %19 = builtin.unrealized_conversion_cast %ptr_10 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %20 = builtin.unrealized_conversion_cast %iter_19 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
          %21 = llvm.load %19 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %21, %20 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          %ptr_22 = cute.add_offset(%ptr_10, %2) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
          %ptr_23 = cute.add_offset(%iter_19, %2) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
          %22 = builtin.unrealized_conversion_cast %ptr_22 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %23 = builtin.unrealized_conversion_cast %ptr_23 : !cute.ptr<f32, rmem> to !llvm.ptr
          %24 = llvm.load %22 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %24, %23 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          %ptr_24 = cute.add_offset(%ptr_10, %1) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
          %ptr_25 = cute.add_offset(%iter_19, %1) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
          %25 = builtin.unrealized_conversion_cast %ptr_24 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %26 = builtin.unrealized_conversion_cast %ptr_25 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %27 = llvm.load %25 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %27, %26 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          %ptr_26 = cute.add_offset(%ptr_10, %0) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
          %ptr_27 = cute.add_offset(%iter_19, %0) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
          %28 = builtin.unrealized_conversion_cast %ptr_26 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %29 = builtin.unrealized_conversion_cast %ptr_27 : !cute.ptr<f32, rmem> to !llvm.ptr
          %30 = llvm.load %28 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %30, %29 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %16 = cute.memref.load_vec %rmem : !memref_rmem_f32_
        %17 = nvgpu.cvt_fptrunc %16 : vector<4xf32> to vector<4xf8E4M3FN>
        cute.memref.store_vec %17, %rmem_20 : !memref_rmem_f8E4M3FN
        %18 = cute.get_scalars(%2) : !cute.int_tuple<"1">
        scf.for %arg6 = %c0_i32 to %18 step %c1_i32  : i32 {
          %19 = builtin.unrealized_conversion_cast %iter_21 : !cute.ptr<f8E4M3FN, rmem, align<32>> to !llvm.ptr
          %20 = builtin.unrealized_conversion_cast %ptr_13 : !cute.ptr<f8E4M3FN, gmem> to !llvm.ptr<1>
          %21 = llvm.load %19 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
          llvm.store %21, %20 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
          %ptr_22 = cute.add_offset(%iter_21, %2) : (!cute.ptr<f8E4M3FN, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f8E4M3FN, rmem>
          %ptr_23 = cute.add_offset(%ptr_13, %2) : (!cute.ptr<f8E4M3FN, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f8E4M3FN, gmem>
          %22 = builtin.unrealized_conversion_cast %ptr_22 : !cute.ptr<f8E4M3FN, rmem> to !llvm.ptr
          %23 = builtin.unrealized_conversion_cast %ptr_23 : !cute.ptr<f8E4M3FN, gmem> to !llvm.ptr<1>
          %24 = llvm.load %22 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
          llvm.store %24, %23 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
          %ptr_24 = cute.add_offset(%iter_21, %1) : (!cute.ptr<f8E4M3FN, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f8E4M3FN, rmem, align<2>>
          %ptr_25 = cute.add_offset(%ptr_13, %1) : (!cute.ptr<f8E4M3FN, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f8E4M3FN, gmem>
          %25 = builtin.unrealized_conversion_cast %ptr_24 : !cute.ptr<f8E4M3FN, rmem, align<2>> to !llvm.ptr
          %26 = builtin.unrealized_conversion_cast %ptr_25 : !cute.ptr<f8E4M3FN, gmem> to !llvm.ptr<1>
          %27 = llvm.load %25 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
          llvm.store %27, %26 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
          %ptr_26 = cute.add_offset(%iter_21, %0) : (!cute.ptr<f8E4M3FN, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f8E4M3FN, rmem>
          %ptr_27 = cute.add_offset(%ptr_13, %0) : (!cute.ptr<f8E4M3FN, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f8E4M3FN, gmem>
          %28 = builtin.unrealized_conversion_cast %ptr_26 : !cute.ptr<f8E4M3FN, rmem> to !llvm.ptr
          %29 = builtin.unrealized_conversion_cast %ptr_27 : !cute.ptr<f8E4M3FN, gmem> to !llvm.ptr<1>
          %30 = llvm.load %28 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
          llvm.store %30, %29 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
        } {llvm.loop_annotation = #loop_annotation}
      }
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
    %lay_3 = cute.get_layout(%arg0) : !memref_gmem_f32_1
    %7:5 = cute.get_scalars(%lay_3) <{only_dynamic}> : !cute.layout<"(?,?,?):(?{i64},1,?{i64})">
    %8 = arith.ceildivsi %7#1, %c512_i32 : i32
    %shape_4 = cute.make_shape(%7#0, %8, %7#2) : (i32, i32, i32) -> !cute.shape<"((1,512,1),(?,?,?))">
    %stride = cute.make_stride(%7#3, %7#4) : (i64, i64) -> !cute.stride<"((0,1,0),(?{i64},512,?{i64}))">
    %lay_5 = cute.make_layout(%shape_4, %stride) : !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">
    %view = cute.make_view(%iter, %lay_5) : !memref_gmem_f32_
    %9:3 = cute.get_scalars(%lay_2) <{only_dynamic}> : !cute.layout<"(?,?,?):(1@0,1@1,1@2)">
    %10 = arith.ceildivsi %9#1, %c512_i32 : i32
    %shape_6 = cute.make_shape(%9#0, %10, %9#2) : (i32, i32, i32) -> !cute.shape<"((1,512,1),(?,?,?))">
    %lay_7 = cute.make_layout(%shape_6, %0) : !cute.layout<"((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">
    %view_8 = cute.make_view(%2, %lay_7) : !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">
    %iter_9 = cute.get_iter(%arg1) : !memref_gmem_f8E4M3FN1
    %lay_10 = cute.get_layout(%arg1) : !memref_gmem_f8E4M3FN1
    %11:5 = cute.get_scalars(%lay_10) <{only_dynamic}> : !cute.layout<"(?,?,?):(?{i64},1,?{i64})">
    %12 = arith.ceildivsi %11#1, %c512_i32 : i32
    %shape_11 = cute.make_shape(%11#0, %12, %11#2) : (i32, i32, i32) -> !cute.shape<"((1,512,1),(?,?,?))">
    %stride_12 = cute.make_stride(%11#3, %11#4) : (i64, i64) -> !cute.stride<"((0,1,0),(?{i64},512,?{i64}))">
    %lay_13 = cute.make_layout(%shape_11, %stride_12) : !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">
    %view_14 = cute.make_view(%iter_9, %lay_13) : !memref_gmem_f8E4M3FN
    %sz = cute.size(%lay_5) <{mode = [1]}> : (!cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !cute.int_tuple<"?">
    %e0_15 = cute.get_leaves(%sz) : !cute.int_tuple<"?">
    %13 = cute.get_scalars(%e0_15) : !cute.int_tuple<"?">
    %14 = cuda.cast %c0_i64 : i64 -> !cuda.stream
    %15 = cuda.launch_cfg.create<max_attrs = 2 : i32> (blockDim = (%c128_i32, %c1_i32, %c1_i32), dynamicSmemBytes = %c0_i64, gridDim = (%13, %c1_i32, %c1_i32), stream = %14) : i32, i32, i32, i64, i32, i32, i32, !cuda.stream -> !cuda.launch_cfg<max_attrs = 2>
    %16 = cuda.launch_ex @kernels::@kernel_cutlass__convert_kernel_tensorptrf32gmemo15121010512_tensorptrf8E4M3FNgmemalign16o15121010512_tensor000o15121011010512112____Float32_Float8E4M3FN_0<%15> (%view, %view_14, %view_8, %4, %5, %6) : !cuda.launch_cfg<max_attrs = 2>, (!memref_gmem_f32_, !memref_gmem_f8E4M3FN, !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">, i32, i32, i32) -> !cuda.result
    %17 = cuda.cast %16 : !cuda.result -> i32
    cuda.return_if_error %17 : i32
    return %c0_i32 : i32
  }
}
