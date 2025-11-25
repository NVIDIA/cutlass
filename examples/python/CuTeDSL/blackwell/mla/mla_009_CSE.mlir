!memref_gmem_f32_ = !cute.memref<f32, gmem, "((1,512,1),(?,?,?)):((0,?{i64},0),(?{i64},?{i64 div=512},1))">
!memref_gmem_f32_1 = !cute.memref<f32, gmem, "(?,?,?):(?{i64},?{i64},1)">
!memref_gmem_f8E4M3FN = !cute.memref<f8E4M3FN, gmem, align<16>, "((1,512,1),(?,?,?)):((0,1,0),(?{div=16},512,?{div=16}))">
!memref_gmem_f8E4M3FN1 = !cute.memref<f8E4M3FN, gmem, align<16>, "(?,?{div=16},?):(?{div=16},1,?{div=16})">
!memref_rmem_f32_ = !cute.memref<f32, rmem, align<32>, "4:1">
!memref_rmem_f8E4M3FN = !cute.memref<f8E4M3FN, rmem, align<32>, "4:1">
#loop_unroll = #llvm.loop_unroll<disable = false, full = true>
#loop_annotation = #llvm.loop_annotation<unroll = #loop_unroll>
module attributes {gpu.container_module} {
  gpu.module @kernels {
    func.func public @kernel_cutlass__convert_kernel_tensorptrf32gmemo1512100div5121_tensorptrf8E4M3FNgmemalign16o15121010div16512div16_tensor000o15121011010512112____Float32_Float8E4M3FN_0(%arg0: !memref_gmem_f32_, %arg1: !memref_gmem_f8E4M3FN, %arg2: !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">, %arg3: i32, %arg4: i32, %arg5: i32) attributes {cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} {
      %0 = cute.static : !cute.int_tuple<"3">
      %c3_i64 = arith.constant 3 : i64
      %1 = cute.static : !cute.int_tuple<"2">
      %c2_i64 = arith.constant 2 : i64
      %c1_i32 = arith.constant 1 : i32
      %c0_i32 = arith.constant 0 : i32
      %2 = cute.static : !cute.int_tuple<"1">
      %3 = cute.static : !cute.shape<"(4,((1)))">
      %4 = cute.static : !cute.shape<"(4,(1))">
      %5 = cute.static : !cute.layout<"1:0">
      %6 = cute.static : !cute.layout<"(128,4):(4@1,1@1)">
      %7 = cute.static : !cute.shape<"(4)">
      %8 = cute.static : !cute.shape<"(128,4)">
      %c4_i64 = arith.constant 4 : i64
      %9 = cute.static : !cute.int_tuple<"(0,0,0)">
      %10 = cute.static : !cute.shape<"((1,512,1))">
      %11 = cute.static : !cute.layout<"(128,4):(4,1)">
      %12 = nvvm.read.ptx.sreg.tid.x range <i32, 0, 1024> : i32
      %13 = nvvm.read.ptx.sreg.ctaid.x range <i32, 0, 2147483647> : i32
      %coord = cute.make_coord(%13) : (i32) -> !cute.coord<"(_,?)">
      %lay = cute.get_layout(%arg0) : !memref_gmem_f32_
      %14:6 = cute.get_scalars(%lay) <{only_dynamic}> : !cute.layout<"((1,512,1),(?,?,?)):((0,?{i64},0),(?{i64},?{i64 div=512},1))">
      %stride = cute.make_stride(%14#3) : (i64) -> !cute.stride<"((0,?{i64},0))">
      %lay_0 = cute.make_layout(%10, %stride) : !cute.layout<"((1,512,1)):((0,?{i64},0))">
      %idx = cute.crd2idx(%coord, %lay) : (!cute.coord<"(_,?)">, !cute.layout<"((1,512,1),(?,?,?)):((0,?{i64},0),(?{i64},?{i64 div=512},1))">) -> !cute.int_tuple<"?{i64}">
      %iter = cute.get_iter(%arg0) : !memref_gmem_f32_
      %ptr = cute.add_offset(%iter, %idx) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %lay_1 = cute.get_layout(%arg1) : !memref_gmem_f8E4M3FN
      %idx_2 = cute.crd2idx(%coord, %lay_1) : (!cute.coord<"(_,?)">, !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{div=16},512,?{div=16}))">) -> !cute.int_tuple<"?{div=16}">
      %iter_3 = cute.get_iter(%arg1) : !memref_gmem_f8E4M3FN
      %ptr_4 = cute.add_offset(%iter_3, %idx_2) : (!cute.ptr<f8E4M3FN, gmem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<f8E4M3FN, gmem, align<16>>
      %lay_5 = cute.get_layout(%arg2) : !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">
      %idx_6 = cute.crd2idx(%coord, %lay_5) : (!cute.coord<"(_,?)">, !cute.layout<"((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">) -> !cute.int_tuple<"(?,?{div=512},?)">
      %tup = cute.add_offset(%9, %idx_6) : (!cute.int_tuple<"(0,0,0)">, !cute.int_tuple<"(?,?{div=512},?)">) -> !cute.int_tuple<"(?,?{div=512},?)">
      %15 = cute.get_scalars(%lay_0) <{only_dynamic}> : !cute.layout<"((1,512,1)):((0,?{i64},0))">
      %16 = arith.muli %15, %c4_i64 : i64
      %iv = cute.assume(%16) : (i64) -> !cute.i64<divby 4>
      %stride_7 = cute.make_stride(%iv, %15) : (!cute.i64<divby 4>, i64) -> !cute.stride<"(?{i64 div=4},?{i64})">
      %lay_8 = cute.make_layout(%8, %stride_7) : !cute.layout<"(128,4):(?{i64 div=4},?{i64})">
      %coord_9 = cute.make_coord(%12) : (i32) -> !cute.coord<"(?,_)">
      %17:2 = cute.get_scalars(%lay_8) <{only_dynamic}> : !cute.layout<"(128,4):(?{i64 div=4},?{i64})">
      %stride_10 = cute.make_stride(%17#1) : (i64) -> !cute.stride<"(?{i64})">
      %lay_11 = cute.make_layout(%7, %stride_10) : !cute.layout<"(4):(?{i64})">
      %idx_12 = cute.crd2idx(%coord_9, %lay_8) : (!cute.coord<"(?,_)">, !cute.layout<"(128,4):(?{i64 div=4},?{i64})">) -> !cute.int_tuple<"?{i64 div=4}">
      %ptr_13 = cute.add_offset(%ptr, %idx_12) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=4}">) -> !cute.ptr<f32, gmem>
      %idx_14 = cute.crd2idx(%coord_9, %11) : (!cute.coord<"(?,_)">, !cute.layout<"(128,4):(4,1)">) -> !cute.int_tuple<"?{div=4}">
      %ptr_15 = cute.add_offset(%ptr_4, %idx_14) : (!cute.ptr<f8E4M3FN, gmem, align<16>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f8E4M3FN, gmem, align<4>>
      %idx_16 = cute.crd2idx(%coord_9, %6) : (!cute.coord<"(?,_)">, !cute.layout<"(128,4):(4@1,1@1)">) -> !cute.int_tuple<"(0,?{div=4})">
      %tup_17 = cute.add_offset(%tup, %idx_16) : (!cute.int_tuple<"(?,?{div=512},?)">, !cute.int_tuple<"(0,?{div=4})">) -> !cute.int_tuple<"(?,?{div=4},?)">
      %e0, %e1, %e2 = cute.get_leaves(%tup_17) : !cute.int_tuple<"(?,?{div=4},?)">
      %coord_18 = cute.make_coord(%e0, %e1, %e2) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=4}">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?{div=4},?)">
      %coord_19 = cute.make_coord(%arg3, %arg4, %arg5) : (i32, i32, i32) -> !cute.coord<"(?,?,?)">
      %18:3 = cute.get_scalars(%coord_18) : !cute.coord<"(?,?{div=4},?)">
      %19:3 = cute.get_scalars(%coord_19) : !cute.coord<"(?,?,?)">
      %20 = arith.cmpi slt, %18#0, %19#0 : i32
      %21 = arith.cmpi slt, %18#1, %19#1 : i32
      %22 = arith.andi %20, %21 : i1
      %23 = arith.cmpi slt, %18#2, %19#2 : i32
      %24 = arith.andi %22, %23 : i1
      scf.if %24 {
        %rmem = cute.memref.alloca() : !memref_rmem_f32_
        %iter_20 = cute.get_iter(%rmem) : !memref_rmem_f32_
        %rmem_21 = cute.memref.alloca() : !memref_rmem_f8E4M3FN
        %iter_22 = cute.get_iter(%rmem_21) : !memref_rmem_f8E4M3FN
        %append = cute.append_to_rank<2> (%lay_11, %5) : !cute.layout<"(4):(?{i64})">, !cute.layout<"1:0">
        %25 = cute.get_scalars(%append) <{only_dynamic}> : !cute.layout<"(4,1):(?{i64},0)">
        %stride_23 = cute.make_stride(%25) : (i64) -> !cute.stride<"(?{i64},(0))">
        %lay_24 = cute.make_layout(%4, %stride_23) : !cute.layout<"(4,(1)):(?{i64},(0))">
        %append_25 = cute.append_to_rank<2> (%lay_24, %5) : !cute.layout<"(4,(1)):(?{i64},(0))">, !cute.layout<"1:0">
        %26 = cute.get_scalars(%append_25) <{only_dynamic}> : !cute.layout<"(4,(1)):(?{i64},(0))">
        %stride_26 = cute.make_stride(%26) : (i64) -> !cute.stride<"(?{i64},((0)))">
        %lay_27 = cute.make_layout(%3, %stride_26) : !cute.layout<"(4,((1))):(?{i64},((0)))">
        %27 = cute.get_scalars(%2) : !cute.int_tuple<"1">
        scf.for %arg6 = %c0_i32 to %27 step %c1_i32  : i32 {
          %30 = cute.get_scalars(%lay_27) <{only_dynamic}> : !cute.layout<"(4,((1))):(?{i64},((0)))">
          %stride_28 = cute.make_stride(%30) : (i64) -> !cute.stride<"(?{i64})">
          %lay_29 = cute.make_layout(%7, %stride_28) : !cute.layout<"(4):(?{i64})">
          %31 = cute.get_scalars(%lay_29) <{only_dynamic}> : !cute.layout<"(4):(?{i64})">
          %32 = builtin.unrealized_conversion_cast %ptr_13 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %33 = builtin.unrealized_conversion_cast %iter_20 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
          %34 = llvm.load %32 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %34, %33 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          %int_tuple = cute.make_int_tuple(%31) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_30 = cute.add_offset(%ptr_13, %int_tuple) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %ptr_31 = cute.add_offset(%iter_20, %2) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
          %35 = builtin.unrealized_conversion_cast %ptr_30 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %36 = builtin.unrealized_conversion_cast %ptr_31 : !cute.ptr<f32, rmem> to !llvm.ptr
          %37 = llvm.load %35 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %37, %36 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          %38 = arith.muli %31, %c2_i64 : i64
          %iv_32 = cute.assume(%38) : (i64) -> !cute.i64<divby 2>
          %int_tuple_33 = cute.make_int_tuple(%iv_32) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
          %ptr_34 = cute.add_offset(%ptr_13, %int_tuple_33) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
          %ptr_35 = cute.add_offset(%iter_20, %1) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
          %39 = builtin.unrealized_conversion_cast %ptr_34 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %40 = builtin.unrealized_conversion_cast %ptr_35 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %41 = llvm.load %39 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %41, %40 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          %42 = arith.muli %31, %c3_i64 : i64
          %iv_36 = cute.assume(%42) : (i64) -> !cute.i64<divby 3>
          %int_tuple_37 = cute.make_int_tuple(%iv_36) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
          %ptr_38 = cute.add_offset(%ptr_13, %int_tuple_37) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
          %ptr_39 = cute.add_offset(%iter_20, %0) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
          %43 = builtin.unrealized_conversion_cast %ptr_38 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %44 = builtin.unrealized_conversion_cast %ptr_39 : !cute.ptr<f32, rmem> to !llvm.ptr
          %45 = llvm.load %43 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %45, %44 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %28 = cute.memref.load_vec %rmem, row_major : !memref_rmem_f32_
        %29 = nvgpu.cvt_fptrunc %28 : vector<4xf32> to vector<4xf8E4M3FN>
        cute.memref.store_vec %29, %rmem_21, row_major : !memref_rmem_f8E4M3FN
        scf.for %arg6 = %c0_i32 to %27 step %c1_i32  : i32 {
          %30 = builtin.unrealized_conversion_cast %iter_22 : !cute.ptr<f8E4M3FN, rmem, align<32>> to !llvm.ptr
          %31 = builtin.unrealized_conversion_cast %ptr_15 : !cute.ptr<f8E4M3FN, gmem, align<4>> to !llvm.ptr<1>
          %32 = llvm.load %30 {alignment = 4 : i64} : !llvm.ptr -> vector<4xi8>
          llvm.store %32, %31 {alignment = 4 : i64} : vector<4xi8>, !llvm.ptr<1>
        } {llvm.loop_annotation = #loop_annotation}
      }
      return
    }
  }
  func.func @cutlass__convert_Tensorgmemoi64i641_Tensorgmemodiv16div161div16_1_4(%arg0: !memref_gmem_f32_1, %arg1: !memref_gmem_f8E4M3FN1) attributes {llvm.emit_c_interface} {
    %c0_i32 = arith.constant 0 : i32
    %c128 = arith.constant 128 : index
    %c1 = arith.constant 1 : index
    %0 = cute.static : !cute.stride<"((0,1@1,0),(1@0,512@1,1@2))">
    %c512_i64 = arith.constant 512 : i64
    %c512_i32 = arith.constant 512 : i32
    %1 = cute.static : !cute.stride<"(1@0,1@1,1@2)">
    %2 = cute.static : !cute.int_tuple<"(0,0,0)">
    %lay = cute.get_layout(%arg0) : !memref_gmem_f32_1
    %3 = cute.get_shape(%lay) : (!cute.layout<"(?,?,?):(?{i64},?{i64},1)">) -> !cute.shape<"(?,?,?)">
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
    %7:5 = cute.get_scalars(%lay) <{only_dynamic}> : !cute.layout<"(?,?,?):(?{i64},?{i64},1)">
    %8 = arith.ceildivsi %7#1, %c512_i32 : i32
    %9 = arith.muli %7#4, %c512_i64 : i64
    %shape_3 = cute.make_shape(%7#0, %8, %7#2) : (i32, i32, i32) -> !cute.shape<"((1,512,1),(?,?,?))">
    %iv = cute.assume(%9) : (i64) -> !cute.i64<divby 512>
    %stride = cute.make_stride(%7#4, %7#3, %iv) : (i64, i64, !cute.i64<divby 512>) -> !cute.stride<"((0,?{i64},0),(?{i64},?{i64 div=512},1))">
    %lay_4 = cute.make_layout(%shape_3, %stride) : !cute.layout<"((1,512,1),(?,?,?)):((0,?{i64},0),(?{i64},?{i64 div=512},1))">
    %view = cute.make_view(%iter, %lay_4) : !memref_gmem_f32_
    %10:3 = cute.get_scalars(%lay_2) <{only_dynamic}> : !cute.layout<"(?,?,?):(1@0,1@1,1@2)">
    %11 = arith.ceildivsi %10#1, %c512_i32 : i32
    %shape_5 = cute.make_shape(%10#0, %11, %10#2) : (i32, i32, i32) -> !cute.shape<"((1,512,1),(?,?,?))">
    %lay_6 = cute.make_layout(%shape_5, %0) : !cute.layout<"((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">
    %view_7 = cute.make_view(%2, %lay_6) : !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">
    %iter_8 = cute.get_iter(%arg1) : !memref_gmem_f8E4M3FN1
    %lay_9 = cute.get_layout(%arg1) : !memref_gmem_f8E4M3FN1
    %12:5 = cute.get_scalars(%lay_9) <{only_dynamic}> : !cute.layout<"(?,?{div=16},?):(?{div=16},1,?{div=16})">
    %13 = arith.ceildivsi %12#1, %c512_i32 : i32
    %shape_10 = cute.make_shape(%12#0, %13, %12#2) : (i32, i32, i32) -> !cute.shape<"((1,512,1),(?,?,?))">
    %iv_11 = cute.assume(%12#3) : (i32) -> !cute.i32<divby 16>
    %iv_12 = cute.assume(%12#4) : (i32) -> !cute.i32<divby 16>
    %stride_13 = cute.make_stride(%iv_11, %iv_12) : (!cute.i32<divby 16>, !cute.i32<divby 16>) -> !cute.stride<"((0,1,0),(?{div=16},512,?{div=16}))">
    %lay_14 = cute.make_layout(%shape_10, %stride_13) : !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{div=16},512,?{div=16}))">
    %view_15 = cute.make_view(%iter_8, %lay_14) : !memref_gmem_f8E4M3FN
    %sz = cute.size(%lay_4) <{mode = [1]}> : (!cute.layout<"((1,512,1),(?,?,?)):((0,?{i64},0),(?{i64},?{i64 div=512},1))">) -> !cute.int_tuple<"?">
    %e0_16 = cute.get_leaves(%sz) : !cute.int_tuple<"?">
    %14 = cute.get_scalars(%e0_16) : !cute.int_tuple<"?">
    %15 = arith.index_cast %14 : i32 to index
    gpu.launch_func  @kernels::@kernel_cutlass__convert_kernel_tensorptrf32gmemo1512100div5121_tensorptrf8E4M3FNgmemalign16o15121010div16512div16_tensor000o15121011010512112____Float32_Float8E4M3FN_0 blocks in (%15, %c1, %c1) threads in (%c128, %c1, %c1)  dynamic_shared_memory_size %c0_i32 args(%view : !memref_gmem_f32_, %view_15 : !memref_gmem_f8E4M3FN, %view_7 : !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">, %4 : i32, %5 : i32, %6 : i32) {use_pdl = false}
    return
  }
}
