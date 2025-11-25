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
    func.func public @kernel_cutlass__convert_kernel_tensorptrf16gmemalign16o125611101000256_tensorptrf32gmemalign16o12561110000div2561_tensor00000o1256111011000102561121314______Float16_Float32_0(%arg0: !memref_gmem_f16_, %arg1: !memref_gmem_f32_, %arg2: !cute.coord_tensor<"(0,0,0,0,0)", "((1,256,1,1,1),(?,?,?,?,?)):((0,1@1,0,0,0),(1@0,256@1,1@2,1@3,1@4))">, %arg3: i32, %arg4: i32, %arg5: i32, %arg6: i32, %arg7: i32) attributes {cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} {
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
      %coord_0 = cute.make_coord(%11) : (i32) -> !cute.coord<"(_,?)">
      %lay_1 = cute.get_layout(%arg1) : !memref_gmem_f32_
      %12:10 = cute.get_scalars(%lay_1) <{only_dynamic}> : !cute.layout<"((1,256,1,1,1),(?,?,?,?,?)):((0,?{i64},0,0,0),(?{i64},?{i64 div=256},?{i64},1,?{i64}))">
      %stride = cute.make_stride(%12#5) : (i64) -> !cute.stride<"((0,?{i64},0,0,0))">
      %lay_2 = cute.make_layout(%8, %stride) : !cute.layout<"((1,256,1,1,1)):((0,?{i64},0,0,0))">
      %idx_3 = cute.crd2idx(%coord_0, %lay_1) : (!cute.coord<"(_,?)">, !cute.layout<"((1,256,1,1,1),(?,?,?,?,?)):((0,?{i64},0,0,0),(?{i64},?{i64 div=256},?{i64},1,?{i64}))">) -> !cute.int_tuple<"?{i64}">
      %iter_4 = cute.get_iter(%arg1) : !memref_gmem_f32_
      %ptr_5 = cute.add_offset(%iter_4, %idx_3) : (!cute.ptr<f32, gmem, align<16>>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %coord_6 = cute.make_coord(%11) : (i32) -> !cute.coord<"(_,?)">
      %lay_7 = cute.get_layout(%arg2) : !cute.coord_tensor<"(0,0,0,0,0)", "((1,256,1,1,1),(?,?,?,?,?)):((0,1@1,0,0,0),(1@0,256@1,1@2,1@3,1@4))">
      %idx_8 = cute.crd2idx(%coord_6, %lay_7) : (!cute.coord<"(_,?)">, !cute.layout<"((1,256,1,1,1),(?,?,?,?,?)):((0,1@1,0,0,0),(1@0,256@1,1@2,1@3,1@4))">) -> !cute.int_tuple<"(?,?{div=256},?,?,?)">
      %tup = cute.add_offset(%7, %idx_8) : (!cute.int_tuple<"(0,0,0,0,0)">, !cute.int_tuple<"(?,?{div=256},?,?,?)">) -> !cute.int_tuple<"(?,?{div=256},?,?,?)">
      %13 = cute.get_scalars(%lay_2) <{only_dynamic}> : !cute.layout<"((1,256,1,1,1)):((0,?{i64},0,0,0))">
      %14 = arith.muli %13, %c2_i64 : i64
      %iv = cute.assume(%14) : (i64) -> !cute.i64<divby 2>
      %stride_9 = cute.make_stride(%iv, %13) : (!cute.i64<divby 2>, i64) -> !cute.stride<"(?{i64 div=2},?{i64})">
      %lay_10 = cute.make_layout(%6, %stride_9) : !cute.layout<"(128,2):(?{i64 div=2},?{i64})">
      %coord_11 = cute.make_coord(%10) : (i32) -> !cute.coord<"(?,_)">
      %idx_12 = cute.crd2idx(%coord_11, %9) : (!cute.coord<"(?,_)">, !cute.layout<"(128,2):(2,1)">) -> !cute.int_tuple<"?{div=2}">
      %ptr_13 = cute.add_offset(%ptr, %idx_12) : (!cute.ptr<f16, gmem>, !cute.int_tuple<"?{div=2}">) -> !cute.ptr<f16, gmem>
      %coord_14 = cute.make_coord(%10) : (i32) -> !cute.coord<"(?,_)">
      %15:2 = cute.get_scalars(%lay_10) <{only_dynamic}> : !cute.layout<"(128,2):(?{i64 div=2},?{i64})">
      %stride_15 = cute.make_stride(%15#1) : (i64) -> !cute.stride<"(?{i64})">
      %lay_16 = cute.make_layout(%5, %stride_15) : !cute.layout<"(2):(?{i64})">
      %idx_17 = cute.crd2idx(%coord_14, %lay_10) : (!cute.coord<"(?,_)">, !cute.layout<"(128,2):(?{i64 div=2},?{i64})">) -> !cute.int_tuple<"?{i64 div=2}">
      %ptr_18 = cute.add_offset(%ptr_5, %idx_17) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
      %coord_19 = cute.make_coord(%10) : (i32) -> !cute.coord<"(?,_)">
      %idx_20 = cute.crd2idx(%coord_19, %4) : (!cute.coord<"(?,_)">, !cute.layout<"(128,2):(2@1,1@1)">) -> !cute.int_tuple<"(0,?{div=2})">
      %tup_21 = cute.add_offset(%tup, %idx_20) : (!cute.int_tuple<"(?,?{div=256},?,?,?)">, !cute.int_tuple<"(0,?{div=2})">) -> !cute.int_tuple<"(?,?{div=2},?,?,?)">
      %e0, %e1, %e2, %e3, %e4 = cute.get_leaves(%tup_21) : !cute.int_tuple<"(?,?{div=2},?,?,?)">
      %coord_22 = cute.make_coord(%e0, %e1, %e2, %e3, %e4) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=2}">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?{div=2},?,?,?)">
      %coord_23 = cute.make_coord(%arg3, %arg4, %arg5, %arg6, %arg7) : (i32, i32, i32, i32, i32) -> !cute.coord<"(?,?,?,?,?)">
      %16:5 = cute.get_scalars(%coord_22) : !cute.coord<"(?,?{div=2},?,?,?)">
      %17:5 = cute.get_scalars(%coord_23) : !cute.coord<"(?,?,?,?,?)">
      %18 = arith.cmpi slt, %16#0, %17#0 : i32
      %19 = arith.cmpi slt, %16#1, %17#1 : i32
      %20 = arith.andi %18, %19 : i1
      %21 = arith.cmpi slt, %16#2, %17#2 : i32
      %22 = arith.andi %20, %21 : i1
      %23 = arith.cmpi slt, %16#3, %17#3 : i32
      %24 = arith.andi %22, %23 : i1
      %25 = arith.cmpi slt, %16#4, %17#4 : i32
      %26 = arith.andi %24, %25 : i1
      scf.if %26 {
        %rmem = cute.memref.alloca() : !memref_rmem_f16_
        %iter_24 = cute.get_iter(%rmem) : !memref_rmem_f16_
        %rmem_25 = cute.memref.alloca() : !memref_rmem_f32_
        %iter_26 = cute.get_iter(%rmem_25) : !memref_rmem_f32_
        %27 = cute.get_scalars(%2) : !cute.int_tuple<"1">
        scf.for %arg8 = %c0_i32 to %27 step %c1_i32  : i32 {
          %33 = builtin.unrealized_conversion_cast %ptr_13 : !cute.ptr<f16, gmem> to !llvm.ptr<1>
          %34 = builtin.unrealized_conversion_cast %iter_24 : !cute.ptr<f16, rmem, align<32>> to !llvm.ptr
          %35 = llvm.load %33 {alignment = 2 : i64} : !llvm.ptr<1> -> vector<1xf16>
          llvm.store %35, %34 {alignment = 2 : i64} : vector<1xf16>, !llvm.ptr
          %ptr_32 = cute.add_offset(%ptr_13, %2) : (!cute.ptr<f16, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f16, gmem>
          %ptr_33 = cute.add_offset(%iter_24, %2) : (!cute.ptr<f16, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f16, rmem>
          %36 = builtin.unrealized_conversion_cast %ptr_32 : !cute.ptr<f16, gmem> to !llvm.ptr<1>
          %37 = builtin.unrealized_conversion_cast %ptr_33 : !cute.ptr<f16, rmem> to !llvm.ptr
          %38 = llvm.load %36 {alignment = 2 : i64} : !llvm.ptr<1> -> vector<1xf16>
          llvm.store %38, %37 {alignment = 2 : i64} : vector<1xf16>, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %28 = cute.memref.load_vec %rmem, row_major : !memref_rmem_f16_
        %29 = arith.extf %28 : vector<2xf16> to vector<2xf32>
        cute.memref.store_vec %29, %rmem_25, row_major : !memref_rmem_f32_
        %append = cute.append_to_rank<2> (%lay_16, %3) : !cute.layout<"(2):(?{i64})">, !cute.layout<"1:0">
        %30 = cute.get_scalars(%append) <{only_dynamic}> : !cute.layout<"(2,1):(?{i64},0)">
        %stride_27 = cute.make_stride(%30) : (i64) -> !cute.stride<"(?{i64},(0))">
        %lay_28 = cute.make_layout(%1, %stride_27) : !cute.layout<"(2,(1)):(?{i64},(0))">
        %append_29 = cute.append_to_rank<2> (%lay_28, %3) : !cute.layout<"(2,(1)):(?{i64},(0))">, !cute.layout<"1:0">
        %31 = cute.get_scalars(%append_29) <{only_dynamic}> : !cute.layout<"(2,(1)):(?{i64},(0))">
        %stride_30 = cute.make_stride(%31) : (i64) -> !cute.stride<"(?{i64},((0)))">
        %lay_31 = cute.make_layout(%0, %stride_30) : !cute.layout<"(2,((1))):(?{i64},((0)))">
        %32 = cute.get_scalars(%2) : !cute.int_tuple<"1">
        scf.for %arg8 = %c0_i32 to %32 step %c1_i32  : i32 {
          %33 = cute.get_scalars(%lay_31) <{only_dynamic}> : !cute.layout<"(2,((1))):(?{i64},((0)))">
          %stride_32 = cute.make_stride(%33) : (i64) -> !cute.stride<"(?{i64})">
          %lay_33 = cute.make_layout(%5, %stride_32) : !cute.layout<"(2):(?{i64})">
          %34 = cute.get_scalars(%lay_33) <{only_dynamic}> : !cute.layout<"(2):(?{i64})">
          %35 = builtin.unrealized_conversion_cast %iter_26 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
          %36 = builtin.unrealized_conversion_cast %ptr_18 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %37 = llvm.load %35 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %37, %36 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
          %ptr_34 = cute.add_offset(%iter_26, %2) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
          %int_tuple = cute.make_int_tuple(%34) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_35 = cute.add_offset(%ptr_18, %int_tuple) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %38 = builtin.unrealized_conversion_cast %ptr_34 : !cute.ptr<f32, rmem> to !llvm.ptr
          %39 = builtin.unrealized_conversion_cast %ptr_35 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %40 = llvm.load %38 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %40, %39 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        } {llvm.loop_annotation = #loop_annotation}
      }
      return
    }
  }
  func.func @cutlass__convert_Tensorgmemoi641i64i64i64_Tensorgmemoi64i64i641i64_1_2(%arg0: !memref_gmem_f16_1, %arg1: !memref_gmem_f32_1) attributes {llvm.emit_c_interface} {
    %c0_i32 = arith.constant 0 : i32
    %c128 = arith.constant 128 : index
    %c1 = arith.constant 1 : index
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
    %lay_5 = cute.get_layout(%arg0) : !memref_gmem_f16_1
    %9:9 = cute.get_scalars(%lay_5) <{only_dynamic}> : !cute.layout<"(?,?,?,?,?):(?{i64},1,?{i64},?{i64},?{i64})">
    %10 = arith.ceildivsi %9#1, %c256_i32 : i32
    %shape_6 = cute.make_shape(%9#0, %10, %9#2, %9#3, %9#4) : (i32, i32, i32, i32, i32) -> !cute.shape<"((1,256,1,1,1),(?,?,?,?,?))">
    %stride = cute.make_stride(%9#5, %9#6, %9#7, %9#8) : (i64, i64, i64, i64) -> !cute.stride<"((0,1,0,0,0),(?{i64},256,?{i64},?{i64},?{i64}))">
    %lay_7 = cute.make_layout(%shape_6, %stride) : !cute.layout<"((1,256,1,1,1),(?,?,?,?,?)):((0,1,0,0,0),(?{i64},256,?{i64},?{i64},?{i64}))">
    %view = cute.make_view(%iter, %lay_7) : !memref_gmem_f16_
    %11:5 = cute.get_scalars(%lay_4) <{only_dynamic}> : !cute.layout<"(?,?,?,?,?):(1@0,1@1,1@2,1@3,1@4)">
    %12 = arith.ceildivsi %11#1, %c256_i32 : i32
    %shape_8 = cute.make_shape(%11#0, %12, %11#2, %11#3, %11#4) : (i32, i32, i32, i32, i32) -> !cute.shape<"((1,256,1,1,1),(?,?,?,?,?))">
    %lay_9 = cute.make_layout(%shape_8, %0) : !cute.layout<"((1,256,1,1,1),(?,?,?,?,?)):((0,1@1,0,0,0),(1@0,256@1,1@2,1@3,1@4))">
    %view_10 = cute.make_view(%2, %lay_9) : !cute.coord_tensor<"(0,0,0,0,0)", "((1,256,1,1,1),(?,?,?,?,?)):((0,1@1,0,0,0),(1@0,256@1,1@2,1@3,1@4))">
    %iter_11 = cute.get_iter(%arg1) : !memref_gmem_f32_1
    %lay_12 = cute.get_layout(%arg1) : !memref_gmem_f32_1
    %13:9 = cute.get_scalars(%lay_12) <{only_dynamic}> : !cute.layout<"(?,?,?,?,?):(?{i64},?{i64},?{i64},1,?{i64})">
    %14 = arith.ceildivsi %13#1, %c256_i32 : i32
    %15 = arith.muli %13#6, %c256_i64 : i64
    %shape_13 = cute.make_shape(%13#0, %14, %13#2, %13#3, %13#4) : (i32, i32, i32, i32, i32) -> !cute.shape<"((1,256,1,1,1),(?,?,?,?,?))">
    %iv = cute.assume(%15) : (i64) -> !cute.i64<divby 256>
    %stride_14 = cute.make_stride(%13#6, %13#5, %iv, %13#7, %13#8) : (i64, i64, !cute.i64<divby 256>, i64, i64) -> !cute.stride<"((0,?{i64},0,0,0),(?{i64},?{i64 div=256},?{i64},1,?{i64}))">
    %lay_15 = cute.make_layout(%shape_13, %stride_14) : !cute.layout<"((1,256,1,1,1),(?,?,?,?,?)):((0,?{i64},0,0,0),(?{i64},?{i64 div=256},?{i64},1,?{i64}))">
    %view_16 = cute.make_view(%iter_11, %lay_15) : !memref_gmem_f32_
    %sz = cute.size(%lay_7) <{mode = [1]}> : (!cute.layout<"((1,256,1,1,1),(?,?,?,?,?)):((0,1,0,0,0),(?{i64},256,?{i64},?{i64},?{i64}))">) -> !cute.int_tuple<"?">
    %e0_17 = cute.get_leaves(%sz) : !cute.int_tuple<"?">
    %16 = cute.get_scalars(%e0_17) : !cute.int_tuple<"?">
    %17 = arith.index_cast %16 : i32 to index
    gpu.launch_func  @kernels::@kernel_cutlass__convert_kernel_tensorptrf16gmemalign16o125611101000256_tensorptrf32gmemalign16o12561110000div2561_tensor00000o1256111011000102561121314______Float16_Float32_0 blocks in (%17, %c1, %c1) threads in (%c128, %c1, %c1)  dynamic_shared_memory_size %c0_i32 args(%view : !memref_gmem_f16_, %view_16 : !memref_gmem_f32_, %view_10 : !cute.coord_tensor<"(0,0,0,0,0)", "((1,256,1,1,1),(?,?,?,?,?)):((0,1@1,0,0,0),(1@0,256@1,1@2,1@3,1@4))">, %4 : i32, %5 : i32, %6 : i32, %7 : i32, %8 : i32) {use_pdl = false}
    return
  }
}
