!memref_gmem_f32_ = !cute.memref<f32, gmem, "((1,1024,1),(?,?,?)):((0,1,0),(?{i64},1024,?{i64}))">
!memref_gmem_f32_1 = !cute.memref<f32, gmem, "(?,?,?):(?{i64},1,?{i64})">
!memref_gmem_f4E2M1FN = !cute.memref<f4E2M1FN, gmem, align<16>, "(?,?,?):(?{i64},1,?{i64})">
!memref_gmem_i8_ = !cute.memref<i8, gmem, align<16>, "((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">
!memref_rmem_f32_ = !cute.memref<f32, rmem, align<32>, "8:1">
!memref_rmem_i8_ = !cute.memref<i8, rmem, align<32>, "4:1">
#loop_unroll = #llvm.loop_unroll<disable = false, full = true>
#loop_annotation = #llvm.loop_annotation<unroll = #loop_unroll>
module attributes {gpu.container_module} {
  gpu.module @kernels {
    cuda.kernel @kernel_cutlass__convert_kernel_tensorptrf32gmemo1102410101024_tensorptri8gmemalign16o15121010512_tensor000o1102410110101024112____Float32_Float4E2M1FN_0(%arg0: !memref_gmem_f32_, %arg1: !memref_gmem_i8_, %arg2: !cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">, %arg3: i32, %arg4: i32, %arg5: i32) attributes {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} {
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
      %8 = cute.static : !cute.layout<"(128,8):(8@1,1@1)">
      %9 = cute.static : !cute.int_tuple<"(0,0,0)">
      %10 = cute.static : !cute.layout<"(128,8):(8,1)">
      %11 = cute.static : !cute.layout<"(128,4):(4,1)">
      %12 = nvvm.read.ptx.sreg.tid.x range <i32, 0, 1024> : i32
      %13 = nvvm.read.ptx.sreg.ctaid.x range <i32, 0, 2147483647> : i32
      %coord = cute.make_coord(%13) : (i32) -> !cute.coord<"(_,?)">
      %lay = cute.get_layout(%arg0) : !memref_gmem_f32_
      %idx = cute.crd2idx(%coord, %lay) : (!cute.coord<"(_,?)">, !cute.layout<"((1,1024,1),(?,?,?)):((0,1,0),(?{i64},1024,?{i64}))">) -> !cute.int_tuple<"?{i64}">
      %iter = cute.get_iter(%arg0) : !memref_gmem_f32_
      %ptr = cute.add_offset(%iter, %idx) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %coord_0 = cute.make_coord(%13) : (i32) -> !cute.coord<"(_,?)">
      %lay_1 = cute.get_layout(%arg1) : !memref_gmem_i8_
      %idx_2 = cute.crd2idx(%coord_0, %lay_1) : (!cute.coord<"(_,?)">, !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !cute.int_tuple<"?{i64}">
      %iter_3 = cute.get_iter(%arg1) : !memref_gmem_i8_
      %ptr_4 = cute.add_offset(%iter_3, %idx_2) : (!cute.ptr<i8, gmem, align<16>>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<i8, gmem>
      %coord_5 = cute.make_coord(%13) : (i32) -> !cute.coord<"(_,?)">
      %lay_6 = cute.get_layout(%arg2) : !cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">
      %idx_7 = cute.crd2idx(%coord_5, %lay_6) : (!cute.coord<"(_,?)">, !cute.layout<"((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">) -> !cute.int_tuple<"(?,?{div=1024},?)">
      %tup = cute.add_offset(%9, %idx_7) : (!cute.int_tuple<"(0,0,0)">, !cute.int_tuple<"(?,?{div=1024},?)">) -> !cute.int_tuple<"(?,?{div=1024},?)">
      %coord_8 = cute.make_coord(%12) : (i32) -> !cute.coord<"(?,_)">
      %idx_9 = cute.crd2idx(%coord_8, %10) : (!cute.coord<"(?,_)">, !cute.layout<"(128,8):(8,1)">) -> !cute.int_tuple<"?{div=8}">
      %ptr_10 = cute.add_offset(%ptr, %idx_9) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f32, gmem>
      %coord_11 = cute.make_coord(%12) : (i32) -> !cute.coord<"(?,_)">
      %idx_12 = cute.crd2idx(%coord_11, %11) : (!cute.coord<"(?,_)">, !cute.layout<"(128,4):(4,1)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_13 = cute.add_offset(%ptr_4, %idx_12) : (!cute.ptr<i8, gmem>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<i8, gmem>
      %coord_14 = cute.make_coord(%12) : (i32) -> !cute.coord<"(?,_)">
      %idx_15 = cute.crd2idx(%coord_14, %8) : (!cute.coord<"(?,_)">, !cute.layout<"(128,8):(8@1,1@1)">) -> !cute.int_tuple<"(0,?{div=8})">
      %tup_16 = cute.add_offset(%tup, %idx_15) : (!cute.int_tuple<"(?,?{div=1024},?)">, !cute.int_tuple<"(0,?{div=8})">) -> !cute.int_tuple<"(?,?{div=8},?)">
      %e0, %e1, %e2 = cute.get_leaves(%tup_16) : !cute.int_tuple<"(?,?{div=8},?)">
      %coord_17 = cute.make_coord(%e0, %e1, %e2) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=8}">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?{div=8},?)">
      %coord_18 = cute.make_coord(%arg3, %arg4, %arg5) : (i32, i32, i32) -> !cute.coord<"(?,?,?)">
      %14:3 = cute.get_scalars(%coord_17) : !cute.coord<"(?,?{div=8},?)">
      %15:3 = cute.get_scalars(%coord_18) : !cute.coord<"(?,?,?)">
      %16 = arith.cmpi slt, %14#0, %15#0 : i32
      %17 = arith.cmpi slt, %14#1, %15#1 : i32
      %18 = arith.andi %16, %17 : i1
      %19 = arith.cmpi slt, %14#2, %15#2 : i32
      %20 = arith.andi %18, %19 : i1
      scf.if %20 {
        %rmem = cute.memref.alloca() : !memref_rmem_f32_
        %iter_19 = cute.get_iter(%rmem) : !memref_rmem_f32_
        %rmem_20 = cute.memref.alloca() : !memref_rmem_i8_
        %iter_21 = cute.get_iter(%rmem_20) : !memref_rmem_i8_
        %21 = cute.get_scalars(%6) : !cute.int_tuple<"1">
        scf.for %arg6 = %c0_i32 to %21 step %c1_i32  : i32 {
          %28 = builtin.unrealized_conversion_cast %ptr_10 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %29 = builtin.unrealized_conversion_cast %iter_19 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
          %30 = llvm.load %28 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %30, %29 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          %ptr_22 = cute.add_offset(%ptr_10, %6) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
          %ptr_23 = cute.add_offset(%iter_19, %6) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
          %31 = builtin.unrealized_conversion_cast %ptr_22 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %32 = builtin.unrealized_conversion_cast %ptr_23 : !cute.ptr<f32, rmem> to !llvm.ptr
          %33 = llvm.load %31 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %33, %32 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          %ptr_24 = cute.add_offset(%ptr_10, %5) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
          %ptr_25 = cute.add_offset(%iter_19, %5) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
          %34 = builtin.unrealized_conversion_cast %ptr_24 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %35 = builtin.unrealized_conversion_cast %ptr_25 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %36 = llvm.load %34 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %36, %35 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          %ptr_26 = cute.add_offset(%ptr_10, %4) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
          %ptr_27 = cute.add_offset(%iter_19, %4) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
          %37 = builtin.unrealized_conversion_cast %ptr_26 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %38 = builtin.unrealized_conversion_cast %ptr_27 : !cute.ptr<f32, rmem> to !llvm.ptr
          %39 = llvm.load %37 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %39, %38 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          %ptr_28 = cute.add_offset(%ptr_10, %3) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"4">) -> !cute.ptr<f32, gmem>
          %ptr_29 = cute.add_offset(%iter_19, %3) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
          %40 = builtin.unrealized_conversion_cast %ptr_28 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %41 = builtin.unrealized_conversion_cast %ptr_29 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
          %42 = llvm.load %40 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %42, %41 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          %ptr_30 = cute.add_offset(%ptr_10, %2) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"5">) -> !cute.ptr<f32, gmem>
          %ptr_31 = cute.add_offset(%iter_19, %2) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<f32, rmem>
          %43 = builtin.unrealized_conversion_cast %ptr_30 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %44 = builtin.unrealized_conversion_cast %ptr_31 : !cute.ptr<f32, rmem> to !llvm.ptr
          %45 = llvm.load %43 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %45, %44 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          %ptr_32 = cute.add_offset(%ptr_10, %1) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"6">) -> !cute.ptr<f32, gmem>
          %ptr_33 = cute.add_offset(%iter_19, %1) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
          %46 = builtin.unrealized_conversion_cast %ptr_32 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %47 = builtin.unrealized_conversion_cast %ptr_33 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %48 = llvm.load %46 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %48, %47 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          %ptr_34 = cute.add_offset(%ptr_10, %0) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"7">) -> !cute.ptr<f32, gmem>
          %ptr_35 = cute.add_offset(%iter_19, %0) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<f32, rmem>
          %49 = builtin.unrealized_conversion_cast %ptr_34 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %50 = builtin.unrealized_conversion_cast %ptr_35 : !cute.ptr<f32, rmem> to !llvm.ptr
          %51 = llvm.load %49 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %51, %50 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %22 = cute.memref.load_vec %rmem : !memref_rmem_f32_
        %23 = nvgpu.cvt_fptrunc %22 : vector<8xf32> to vector<8xf4E2M1FN>
        %24 = cute.recast_layout<8, 4> (%7) : !cute.layout<"8:1"> to !cute.layout<"4:1">
        %25 = builtin.unrealized_conversion_cast %23 : vector<8xf4E2M1FN> to vector<8xi4>
        %26 = vector.bitcast %25 : vector<8xi4> to vector<4xi8>
        cute.memref.store_vec %26, %rmem_20 : !memref_rmem_i8_
        %27 = cute.get_scalars(%6) : !cute.int_tuple<"1">
        scf.for %arg6 = %c0_i32 to %27 step %c1_i32  : i32 {
          %28 = builtin.unrealized_conversion_cast %iter_21 : !cute.ptr<i8, rmem, align<32>> to !llvm.ptr
          %29 = builtin.unrealized_conversion_cast %ptr_13 : !cute.ptr<i8, gmem> to !llvm.ptr<1>
          %30 = llvm.load %28 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
          llvm.store %30, %29 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
          %ptr_22 = cute.add_offset(%iter_21, %6) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
          %ptr_23 = cute.add_offset(%ptr_13, %6) : (!cute.ptr<i8, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<i8, gmem>
          %31 = builtin.unrealized_conversion_cast %ptr_22 : !cute.ptr<i8, rmem> to !llvm.ptr
          %32 = builtin.unrealized_conversion_cast %ptr_23 : !cute.ptr<i8, gmem> to !llvm.ptr<1>
          %33 = llvm.load %31 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
          llvm.store %33, %32 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
          %ptr_24 = cute.add_offset(%iter_21, %5) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem, align<2>>
          %ptr_25 = cute.add_offset(%ptr_13, %5) : (!cute.ptr<i8, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<i8, gmem>
          %34 = builtin.unrealized_conversion_cast %ptr_24 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
          %35 = builtin.unrealized_conversion_cast %ptr_25 : !cute.ptr<i8, gmem> to !llvm.ptr<1>
          %36 = llvm.load %34 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
          llvm.store %36, %35 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
          %ptr_26 = cute.add_offset(%iter_21, %4) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
          %ptr_27 = cute.add_offset(%ptr_13, %4) : (!cute.ptr<i8, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<i8, gmem>
          %37 = builtin.unrealized_conversion_cast %ptr_26 : !cute.ptr<i8, rmem> to !llvm.ptr
          %38 = builtin.unrealized_conversion_cast %ptr_27 : !cute.ptr<i8, gmem> to !llvm.ptr<1>
          %39 = llvm.load %37 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
          llvm.store %39, %38 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
        } {llvm.loop_annotation = #loop_annotation}
      }
      return
    }
  }
  func.func @cutlass__convert_Tensorgmemoi641i64_Tensorgmemoi641i64_1_8(%arg0: !memref_gmem_f32_1, %arg1: !memref_gmem_f4E2M1FN) -> i32 attributes {llvm.emit_c_interface} {
    %c1_i32 = arith.constant 1 : i32
    %c128_i32 = arith.constant 128 : i32
    %c0_i64 = arith.constant 0 : i64
    %c0_i32 = arith.constant 0 : i32
    %c512_i32 = arith.constant 512 : i32
    %0 = cute.static : !cute.stride<"((0,1@1,0),(1@0,1024@1,1@2))">
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
    %6 = cute.get_shape(%lay_1) : (!cute.layout<"(?,?,?):(?{i64},1,?{i64})">) -> !cute.shape<"(?,?,?)">
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
    %10:5 = cute.get_scalars(%lay_6) <{only_dynamic}> : !cute.layout<"(?,?,?):(?{i64},1,?{i64})">
    %11 = arith.ceildivsi %10#1, %c1024_i32 : i32
    %shape_7 = cute.make_shape(%10#0, %11, %10#2) : (i32, i32, i32) -> !cute.shape<"((1,1024,1),(?,?,?))">
    %stride = cute.make_stride(%10#3, %10#4) : (i64, i64) -> !cute.stride<"((0,1,0),(?{i64},1024,?{i64}))">
    %lay_8 = cute.make_layout(%shape_7, %stride) : !cute.layout<"((1,1024,1),(?,?,?)):((0,1,0),(?{i64},1024,?{i64}))">
    %view = cute.make_view(%iter_5, %lay_8) : !memref_gmem_f32_
    %12:3 = cute.get_scalars(%lay_4) <{only_dynamic}> : !cute.layout<"(?,?,?):(1@0,1@1,1@2)">
    %13 = arith.ceildivsi %12#1, %c1024_i32 : i32
    %shape_9 = cute.make_shape(%12#0, %13, %12#2) : (i32, i32, i32) -> !cute.shape<"((1,1024,1),(?,?,?))">
    %lay_10 = cute.make_layout(%shape_9, %0) : !cute.layout<"((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">
    %view_11 = cute.make_view(%2, %lay_10) : !cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">
    %14:5 = cute.get_scalars(%5) <{only_dynamic}> : !cute.layout<"(?,?,?):(?{i64},1,?{i64})">
    %15 = arith.ceildivsi %14#1, %c512_i32 : i32
    %shape_12 = cute.make_shape(%14#0, %15, %14#2) : (i32, i32, i32) -> !cute.shape<"((1,512,1),(?,?,?))">
    %stride_13 = cute.make_stride(%14#3, %14#4) : (i64, i64) -> !cute.stride<"((0,1,0),(?{i64},512,?{i64}))">
    %lay_14 = cute.make_layout(%shape_12, %stride_13) : !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">
    %view_15 = cute.make_view(%iter_0, %lay_14) : !memref_gmem_i8_
    %sz = cute.size(%lay_8) <{mode = [1]}> : (!cute.layout<"((1,1024,1),(?,?,?)):((0,1,0),(?{i64},1024,?{i64}))">) -> !cute.int_tuple<"?">
    %e0_16 = cute.get_leaves(%sz) : !cute.int_tuple<"?">
    %16 = cute.get_scalars(%e0_16) : !cute.int_tuple<"?">
    %17 = cuda.cast %c0_i64 : i64 -> !cuda.stream
    %18 = cuda.launch_cfg.create<max_attrs = 2 : i32> (blockDim = (%c128_i32, %c1_i32, %c1_i32), dynamicSmemBytes = %c0_i64, gridDim = (%16, %c1_i32, %c1_i32), stream = %17) : i32, i32, i32, i64, i32, i32, i32, !cuda.stream -> !cuda.launch_cfg<max_attrs = 2>
    %19 = cuda.launch_ex @kernels::@kernel_cutlass__convert_kernel_tensorptrf32gmemo1102410101024_tensorptri8gmemalign16o15121010512_tensor000o1102410110101024112____Float32_Float4E2M1FN_0<%18> (%view, %view_15, %view_11, %7, %8, %9) : !cuda.launch_cfg<max_attrs = 2>, (!memref_gmem_f32_, !memref_gmem_i8_, !cute.coord_tensor<"(0,0,0)", "((1,1024,1),(?,?,?)):((0,1@1,0),(1@0,1024@1,1@2))">, i32, i32, i32) -> !cuda.result
    %20 = cuda.cast %19 : !cuda.result -> i32
    cuda.return_if_error %20 : i32
    return %c0_i32 : i32
  }
}
