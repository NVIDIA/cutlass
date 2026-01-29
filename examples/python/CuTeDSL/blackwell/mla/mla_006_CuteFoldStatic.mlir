!memref_gmem_f32_ = !cute.memref<f32, gmem, "((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">
!memref_gmem_f32_1 = !cute.memref<f32, gmem, "((1,512,1)):((0,1,0))">
!memref_gmem_f32_2 = !cute.memref<f32, gmem, "(128,4):(4,1)">
!memref_gmem_f32_3 = !cute.memref<f32, gmem, "(4):(1)">
!memref_gmem_f32_4 = !cute.memref<f32, gmem, "(4,1):(1,0)">
!memref_gmem_f32_5 = !cute.memref<f32, gmem, "(4,(1)):(1,(0))">
!memref_gmem_f32_6 = !cute.memref<f32, gmem, "(?,?,?):(?{i64},1,?{i64})">
!memref_gmem_f8E4M3FN = !cute.memref<f8E4M3FN, gmem, align<16>, "((1,512,1),(?,?,?)):((0,1,0),(?{div=16},512,?{div=16}))">
!memref_gmem_f8E4M3FN1 = !cute.memref<f8E4M3FN, gmem, align<16>, "((1,512,1)):((0,1,0))">
!memref_gmem_f8E4M3FN2 = !cute.memref<f8E4M3FN, gmem, align<16>, "(128,4):(4,1)">
!memref_gmem_f8E4M3FN3 = !cute.memref<f8E4M3FN, gmem, align<4>, "(4):(1)">
!memref_gmem_f8E4M3FN4 = !cute.memref<f8E4M3FN, gmem, align<4>, "(4,1):(1,0)">
!memref_gmem_f8E4M3FN5 = !cute.memref<f8E4M3FN, gmem, align<4>, "(4,(1)):(1,(0))">
!memref_gmem_f8E4M3FN6 = !cute.memref<f8E4M3FN, gmem, align<16>, "(?,?{div=16},?):(?{div=16},1,?{div=16})">
!memref_rmem_f32_ = !cute.memref<f32, rmem, align<32>, "4:1">
!memref_rmem_f32_1 = !cute.memref<f32, rmem, align<32>, "(4,1):(1,0)">
!memref_rmem_f32_2 = !cute.memref<f32, rmem, align<32>, "(4,(1)):(1,(0))">
!memref_rmem_f32_3 = !cute.memref<f32, rmem, align<32>, "(4):(1)">
!memref_rmem_f8E4M3FN = !cute.memref<f8E4M3FN, rmem, align<32>, "4:1">
!memref_rmem_f8E4M3FN1 = !cute.memref<f8E4M3FN, rmem, align<32>, "(4,1):(1,0)">
!memref_rmem_f8E4M3FN2 = !cute.memref<f8E4M3FN, rmem, align<32>, "(4,(1)):(1,(0))">
!memref_rmem_f8E4M3FN3 = !cute.memref<f8E4M3FN, rmem, align<32>, "(4):(1)">
#loop_unroll = #llvm.loop_unroll<disable = false, full = true>
#loop_annotation = #llvm.loop_annotation<unroll = #loop_unroll>
module attributes {gpu.container_module} {
  gpu.module @kernels {
    cuda.kernel @kernel_cutlass__convert_kernel_tensorptrf32gmemo15121010512_tensorptrf8E4M3FNgmemalign16o15121010div16512div16_tensor000o15121011010512112____Float32_Float8E4M3FN_0(%arg0: !memref_gmem_f32_, %arg1: !memref_gmem_f8E4M3FN, %arg2: !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">, %arg3: i32, %arg4: i32, %arg5: i32) attributes {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} {
      %0 = cute.static : !cute.layout<"(128,4):(4,1)">
      %1 = cute.static : !cute.layout<"(128,4):(4,1)">
      %2 = nvvm.read.ptx.sreg.tid.x : i32
      %3 = nvvm.read.ptx.sreg.ctaid.x : i32
      %coord = cute.make_coord(%3) : (i32) -> !cute.coord<"(_,?)">
      %lay = cute.get_layout(%arg0) : !memref_gmem_f32_
      %idx = cute.crd2idx(%coord, %lay) : (!cute.coord<"(_,?)">, !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !cute.int_tuple<"?{i64}">
      %iter = cute.get_iter(%arg0) : !memref_gmem_f32_
      %ptr = cute.add_offset(%iter, %idx) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %view = cute.make_view(%ptr) : !memref_gmem_f32_1
      %coord_0 = cute.make_coord(%3) : (i32) -> !cute.coord<"(_,?)">
      %lay_1 = cute.get_layout(%arg1) : !memref_gmem_f8E4M3FN
      %idx_2 = cute.crd2idx(%coord_0, %lay_1) : (!cute.coord<"(_,?)">, !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{div=16},512,?{div=16}))">) -> !cute.int_tuple<"?{div=16}">
      %iter_3 = cute.get_iter(%arg1) : !memref_gmem_f8E4M3FN
      %ptr_4 = cute.add_offset(%iter_3, %idx_2) : (!cute.ptr<f8E4M3FN, gmem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<f8E4M3FN, gmem, align<16>>
      %view_5 = cute.make_view(%ptr_4) : !memref_gmem_f8E4M3FN1
      %coord_6 = cute.make_coord(%3) : (i32) -> !cute.coord<"(_,?)">
      %lay_7 = cute.get_layout(%arg2) : !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">
      %idx_8 = cute.crd2idx(%coord_6, %lay_7) : (!cute.coord<"(_,?)">, !cute.layout<"((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">) -> !cute.int_tuple<"(?,?{div=512},?)">
      %4 = cute.static : !cute.int_tuple<"(0,0,0)">
      %tup = cute.add_offset(%4, %idx_8) : (!cute.int_tuple<"(0,0,0)">, !cute.int_tuple<"(?,?{div=512},?)">) -> !cute.int_tuple<"(?,?{div=512},?)">
      %view_9 = cute.make_view(%tup) : !cute.coord_tensor<"(?,?{div=512},?)", "((1,512,1)):((0,1@1,0))">
      %iter_10 = cute.get_iter(%view) : !memref_gmem_f32_1
      %view_11 = cute.make_view(%iter_10) : !memref_gmem_f32_2
      %iter_12 = cute.get_iter(%view_5) : !memref_gmem_f8E4M3FN1
      %view_13 = cute.make_view(%iter_12) : !memref_gmem_f8E4M3FN2
      %iter_14 = cute.get_iter(%view_9) : !cute.coord_tensor<"(?,?{div=512},?)", "((1,512,1)):((0,1@1,0))">
      %view_15 = cute.make_view(%iter_14) : !cute.coord_tensor<"(?,?{div=512},?)", "(128,4):(4@1,1@1)">
      %coord_16 = cute.make_coord(%2) : (i32) -> !cute.coord<"(?,_)">
      %5 = cute.static : !cute.layout<"(128,4):(4,1)">
      %idx_17 = cute.crd2idx(%coord_16, %5) : (!cute.coord<"(?,_)">, !cute.layout<"(128,4):(4,1)">) -> !cute.int_tuple<"?{div=4}">
      %iter_18 = cute.get_iter(%view_11) : !memref_gmem_f32_2
      %ptr_19 = cute.add_offset(%iter_18, %idx_17) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, gmem>
      %view_20 = cute.make_view(%ptr_19) : !memref_gmem_f32_3
      %iter_21 = cute.get_iter(%view_20) : !memref_gmem_f32_3
      %coord_22 = cute.make_coord(%2) : (i32) -> !cute.coord<"(?,_)">
      %6 = cute.static : !cute.layout<"(128,4):(4,1)">
      %idx_23 = cute.crd2idx(%coord_22, %6) : (!cute.coord<"(?,_)">, !cute.layout<"(128,4):(4,1)">) -> !cute.int_tuple<"?{div=4}">
      %iter_24 = cute.get_iter(%view_13) : !memref_gmem_f8E4M3FN2
      %ptr_25 = cute.add_offset(%iter_24, %idx_23) : (!cute.ptr<f8E4M3FN, gmem, align<16>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f8E4M3FN, gmem, align<4>>
      %view_26 = cute.make_view(%ptr_25) : !memref_gmem_f8E4M3FN3
      %iter_27 = cute.get_iter(%view_26) : !memref_gmem_f8E4M3FN3
      %coord_28 = cute.make_coord(%2) : (i32) -> !cute.coord<"(?,_)">
      %7 = cute.static : !cute.layout<"(128,4):(4@1,1@1)">
      %idx_29 = cute.crd2idx(%coord_28, %7) : (!cute.coord<"(?,_)">, !cute.layout<"(128,4):(4@1,1@1)">) -> !cute.int_tuple<"(0,?{div=4})">
      %iter_30 = cute.get_iter(%view_15) : !cute.coord_tensor<"(?,?{div=512},?)", "(128,4):(4@1,1@1)">
      %tup_31 = cute.add_offset(%iter_30, %idx_29) : (!cute.int_tuple<"(?,?{div=512},?)">, !cute.int_tuple<"(0,?{div=4})">) -> !cute.int_tuple<"(?,?{div=4},?)">
      %view_32 = cute.make_view(%tup_31) : !cute.coord_tensor<"(?,?{div=4},?)", "(4):(1@1)">
      %8 = cute.static : !cute.int_tuple<"(0,0)">
      %iter_33 = cute.get_iter(%view_32) : !cute.coord_tensor<"(?,?{div=4},?)", "(4):(1@1)">
      %tup_34 = cute.add_offset(%iter_33, %8) : (!cute.int_tuple<"(?,?{div=4},?)">, !cute.int_tuple<"(0,0)">) -> !cute.int_tuple<"(?,?{div=4},?)">
      %view_35 = cute.make_view(%tup_34) : !cute.coord_tensor<"(?,?{div=4},?)", "():()">
      %iter_36 = cute.get_iter(%view_35) : !cute.coord_tensor<"(?,?{div=4},?)", "():()">
      %e0, %e1, %e2 = cute.get_leaves(%iter_36) : !cute.int_tuple<"(?,?{div=4},?)">
      %coord_37 = cute.make_coord(%e0, %e1, %e2) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=4}">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?{div=4},?)">
      %coord_38 = cute.make_coord(%arg3, %arg4, %arg5) : (i32, i32, i32) -> !cute.coord<"(?,?,?)">
      %9:3 = cute.get_scalars(%coord_37) : !cute.coord<"(?,?{div=4},?)">
      %10:3 = cute.get_scalars(%coord_38) : !cute.coord<"(?,?,?)">
      %true = arith.constant true
      %11 = arith.cmpi slt, %9#0, %10#0 : i32
      %12 = arith.andi %true, %11 : i1
      %13 = arith.cmpi slt, %9#1, %10#1 : i32
      %14 = arith.andi %12, %13 : i1
      %15 = arith.cmpi slt, %9#2, %10#2 : i32
      %16 = arith.andi %14, %15 : i1
      scf.if %16 {
        %17 = cute.static : !cute.layout<"4:1">
        %rmem = cute.memref.alloca(%17) : !memref_rmem_f32_
        %iter_39 = cute.get_iter(%rmem) : !memref_rmem_f32_
        %18 = cute.static : !cute.layout<"4:1">
        %rmem_40 = cute.memref.alloca(%18) : !memref_rmem_f8E4M3FN
        %iter_41 = cute.get_iter(%rmem_40) : !memref_rmem_f8E4M3FN
        %19 = cute.static : !cute.layout<"(4,1):(1,0)">
        %view_42 = cute.make_view(%iter_21, %19) : !memref_gmem_f32_4
        %iter_43 = cute.get_iter(%view_42) : !memref_gmem_f32_4
        %view_44 = cute.make_view(%iter_43) : !memref_gmem_f32_5
        %20 = cute.static : !cute.layout<"(4,1):(1,0)">
        %view_45 = cute.make_view(%iter_39, %20) : !memref_rmem_f32_1
        %iter_46 = cute.get_iter(%view_45) : !memref_rmem_f32_1
        %view_47 = cute.make_view(%iter_46) : !memref_rmem_f32_2
        %21 = cute.static : !cute.layout<"1:0">
        %iter_48 = cute.get_iter(%view_44) : !memref_gmem_f32_5
        %iter_49 = cute.get_iter(%view_47) : !memref_rmem_f32_2
        %22 = cute.static : !cute.int_tuple<"1">
        %23 = cute.get_scalars(%22) : !cute.int_tuple<"1">
        %c0_i32 = arith.constant 0 : i32
        %c1_i32 = arith.constant 1 : i32
        scf.for %arg6 = %c0_i32 to %23 step %c1_i32  : i32 {
          %31 = cute.static : !cute.layout<"(4):(1)">
          %32 = cute.static : !cute.int_tuple<"0">
          %ptr_60 = cute.add_offset(%iter_48, %32) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<f32, gmem>
          %view_61 = cute.make_view(%ptr_60, %31) : !memref_gmem_f32_3
          %33 = cute.static : !cute.layout<"(4):(1)">
          %34 = cute.static : !cute.int_tuple<"0">
          %ptr_62 = cute.add_offset(%iter_49, %34) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, rmem, align<32>>
          %view_63 = cute.make_view(%ptr_62, %33) : !memref_rmem_f32_3
          %iter_64 = cute.get_iter(%view_61) : !memref_gmem_f32_3
          %iter_65 = cute.get_iter(%view_63) : !memref_rmem_f32_3
          %35 = builtin.unrealized_conversion_cast %iter_64 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %36 = builtin.unrealized_conversion_cast %iter_65 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
          %37 = llvm.load %35 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %37, %36 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          %38 = cute.static : !cute.int_tuple<"1">
          %ptr_66 = cute.add_offset(%iter_64, %38) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
          %39 = cute.static : !cute.int_tuple<"1">
          %ptr_67 = cute.add_offset(%iter_65, %39) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
          %40 = builtin.unrealized_conversion_cast %ptr_66 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %41 = builtin.unrealized_conversion_cast %ptr_67 : !cute.ptr<f32, rmem> to !llvm.ptr
          %42 = llvm.load %40 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %42, %41 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          %43 = cute.static : !cute.int_tuple<"2">
          %ptr_68 = cute.add_offset(%iter_64, %43) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
          %44 = cute.static : !cute.int_tuple<"2">
          %ptr_69 = cute.add_offset(%iter_65, %44) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
          %45 = builtin.unrealized_conversion_cast %ptr_68 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %46 = builtin.unrealized_conversion_cast %ptr_69 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %47 = llvm.load %45 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %47, %46 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          %48 = cute.static : !cute.int_tuple<"3">
          %ptr_70 = cute.add_offset(%iter_64, %48) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
          %49 = cute.static : !cute.int_tuple<"3">
          %ptr_71 = cute.add_offset(%iter_65, %49) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
          %50 = builtin.unrealized_conversion_cast %ptr_70 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %51 = builtin.unrealized_conversion_cast %ptr_71 : !cute.ptr<f32, rmem> to !llvm.ptr
          %52 = llvm.load %50 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %52, %51 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %24 = cute.memref.load_vec %rmem : !memref_rmem_f32_
        %25 = nvgpu.cvt_fptrunc %24 : vector<4xf32> to vector<4xf8E4M3FN>
        cute.memref.store_vec %25, %rmem_40 : !memref_rmem_f8E4M3FN
        %26 = cute.static : !cute.layout<"(4,1):(1,0)">
        %view_50 = cute.make_view(%iter_41, %26) : !memref_rmem_f8E4M3FN1
        %iter_51 = cute.get_iter(%view_50) : !memref_rmem_f8E4M3FN1
        %view_52 = cute.make_view(%iter_51) : !memref_rmem_f8E4M3FN2
        %27 = cute.static : !cute.layout<"(4,1):(1,0)">
        %view_53 = cute.make_view(%iter_27, %27) : !memref_gmem_f8E4M3FN4
        %iter_54 = cute.get_iter(%view_53) : !memref_gmem_f8E4M3FN4
        %view_55 = cute.make_view(%iter_54) : !memref_gmem_f8E4M3FN5
        %28 = cute.static : !cute.layout<"1:0">
        %iter_56 = cute.get_iter(%view_52) : !memref_rmem_f8E4M3FN2
        %iter_57 = cute.get_iter(%view_55) : !memref_gmem_f8E4M3FN5
        %29 = cute.static : !cute.int_tuple<"1">
        %30 = cute.get_scalars(%29) : !cute.int_tuple<"1">
        %c0_i32_58 = arith.constant 0 : i32
        %c1_i32_59 = arith.constant 1 : i32
        scf.for %arg6 = %c0_i32_58 to %30 step %c1_i32_59  : i32 {
          %31 = cute.static : !cute.layout<"(4):(1)">
          %32 = cute.static : !cute.int_tuple<"0">
          %ptr_60 = cute.add_offset(%iter_56, %32) : (!cute.ptr<f8E4M3FN, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f8E4M3FN, rmem, align<32>>
          %view_61 = cute.make_view(%ptr_60, %31) : !memref_rmem_f8E4M3FN3
          %33 = cute.static : !cute.layout<"(4):(1)">
          %34 = cute.static : !cute.int_tuple<"0">
          %ptr_62 = cute.add_offset(%iter_57, %34) : (!cute.ptr<f8E4M3FN, gmem, align<4>>, !cute.int_tuple<"0">) -> !cute.ptr<f8E4M3FN, gmem, align<4>>
          %view_63 = cute.make_view(%ptr_62, %33) : !memref_gmem_f8E4M3FN3
          %iter_64 = cute.get_iter(%view_61) : !memref_rmem_f8E4M3FN3
          %iter_65 = cute.get_iter(%view_63) : !memref_gmem_f8E4M3FN3
          %35 = builtin.unrealized_conversion_cast %iter_64 : !cute.ptr<f8E4M3FN, rmem, align<32>> to !llvm.ptr
          %36 = builtin.unrealized_conversion_cast %iter_65 : !cute.ptr<f8E4M3FN, gmem, align<4>> to !llvm.ptr<1>
          %37 = llvm.load %35 {alignment = 4 : i64} : !llvm.ptr -> vector<4xi8>
          llvm.store %37, %36 {alignment = 4 : i64} : vector<4xi8>, !llvm.ptr<1>
        } {llvm.loop_annotation = #loop_annotation}
      }
      return
    }
  }
  func.func @cutlass__convert_Tensorgmemoi641i64_Tensorgmemodiv16div161div16_1_4(%arg0: !memref_gmem_f32_6, %arg1: !memref_gmem_f8E4M3FN6) -> i32 attributes {llvm.emit_c_interface} {
    %lay = cute.get_layout(%arg0) : !memref_gmem_f32_6
    %0 = cute.get_shape(%lay) : (!cute.layout<"(?,?,?):(?{i64},1,?{i64})">) -> !cute.shape<"(?,?,?)">
    %e0, %e1, %e2 = cute.get_leaves(%0) : !cute.shape<"(?,?,?)">
    %itup = cute.to_int_tuple(%e0) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %1 = cute.get_scalars(%itup) : !cute.int_tuple<"?">
    %itup_0 = cute.to_int_tuple(%e1) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %2 = cute.get_scalars(%itup_0) : !cute.int_tuple<"?">
    %itup_1 = cute.to_int_tuple(%e2) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %3 = cute.get_scalars(%itup_1) : !cute.int_tuple<"?">
    %shape = cute.make_shape(%itup, %itup_0, %itup_1) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.shape<"(?,?,?)">
    %4 = cute.static : !cute.int_tuple<"(0,0,0)">
    %5 = cute.static : !cute.stride<"(1@0,1@1,1@2)">
    %lay_2 = cute.make_layout(%shape, %5) : !cute.layout<"(?,?,?):(1@0,1@1,1@2)">
    %view = cute.make_view(%4, %lay_2) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">
    %iter = cute.get_iter(%arg0) : !memref_gmem_f32_6
    %lay_3 = cute.get_layout(%arg0) : !memref_gmem_f32_6
    %6:5 = cute.get_scalars(%lay_3) <{only_dynamic}> : !cute.layout<"(?,?,?):(?{i64},1,?{i64})">
    %c512_i32 = arith.constant 512 : i32
    %7 = arith.ceildivsi %6#1, %c512_i32 : i32
    %shape_4 = cute.make_shape(%6#0, %7, %6#2) : (i32, i32, i32) -> !cute.shape<"((1,512,1),(?,?,?))">
    %stride = cute.make_stride(%6#3, %6#4) : (i64, i64) -> !cute.stride<"((0,1,0),(?{i64},512,?{i64}))">
    %lay_5 = cute.make_layout(%shape_4, %stride) : !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">
    %view_6 = cute.make_view(%iter, %lay_5) : !memref_gmem_f32_
    %8 = cute.static : !cute.int_tuple<"(0,0,0)">
    %lay_7 = cute.get_layout(%view) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">
    %9:3 = cute.get_scalars(%lay_7) <{only_dynamic}> : !cute.layout<"(?,?,?):(1@0,1@1,1@2)">
    %c512_i32_8 = arith.constant 512 : i32
    %10 = arith.ceildivsi %9#1, %c512_i32_8 : i32
    %shape_9 = cute.make_shape(%9#0, %10, %9#2) : (i32, i32, i32) -> !cute.shape<"((1,512,1),(?,?,?))">
    %11 = cute.static : !cute.stride<"((0,1@1,0),(1@0,512@1,1@2))">
    %lay_10 = cute.make_layout(%shape_9, %11) : !cute.layout<"((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">
    %view_11 = cute.make_view(%8, %lay_10) : !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">
    %iter_12 = cute.get_iter(%arg1) : !memref_gmem_f8E4M3FN6
    %lay_13 = cute.get_layout(%arg1) : !memref_gmem_f8E4M3FN6
    %12:5 = cute.get_scalars(%lay_13) <{only_dynamic}> : !cute.layout<"(?,?{div=16},?):(?{div=16},1,?{div=16})">
    %c512_i32_14 = arith.constant 512 : i32
    %13 = arith.ceildivsi %12#1, %c512_i32_14 : i32
    %shape_15 = cute.make_shape(%12#0, %13, %12#2) : (i32, i32, i32) -> !cute.shape<"((1,512,1),(?,?,?))">
    %iv = cute.assume(%12#3) : (i32) -> !cute.i32<divby 16>
    %iv_16 = cute.assume(%12#4) : (i32) -> !cute.i32<divby 16>
    %stride_17 = cute.make_stride(%iv, %iv_16) : (!cute.i32<divby 16>, !cute.i32<divby 16>) -> !cute.stride<"((0,1,0),(?{div=16},512,?{div=16}))">
    %lay_18 = cute.make_layout(%shape_15, %stride_17) : !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{div=16},512,?{div=16}))">
    %view_19 = cute.make_view(%iter_12, %lay_18) : !memref_gmem_f8E4M3FN
    %lay_20 = cute.get_layout(%view_6) : !memref_gmem_f32_
    %sz = cute.size(%lay_20) <{mode = [1]}> : (!cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !cute.int_tuple<"?">
    %e0_21 = cute.get_leaves(%sz) : !cute.int_tuple<"?">
    %14 = cute.get_scalars(%e0_21) : !cute.int_tuple<"?">
    %c0_i32 = arith.constant 0 : i32
    %c0_i64 = arith.constant 0 : i64
    %15 = cuda.cast %c0_i64 : i64 -> !cuda.stream
    %16 = arith.extsi %c0_i32 : i32 to i64
    %c128_i32 = arith.constant 128 : i32
    %c1_i32 = arith.constant 1 : i32
    %17 = cuda.launch_cfg.create<max_attrs = 2 : i32> (blockDim = (%c128_i32, %c1_i32, %c1_i32), dynamicSmemBytes = %16, gridDim = (%14, %c1_i32, %c1_i32), stream = %15) : i32, i32, i32, i64, i32, i32, i32, !cuda.stream -> !cuda.launch_cfg<max_attrs = 2>
    %18 = cuda.launch_ex @kernels::@kernel_cutlass__convert_kernel_tensorptrf32gmemo15121010512_tensorptrf8E4M3FNgmemalign16o15121010div16512div16_tensor000o15121011010512112____Float32_Float8E4M3FN_0<%17> (%view_6, %view_19, %view_11, %1, %2, %3) : !cuda.launch_cfg<max_attrs = 2>, (!memref_gmem_f32_, !memref_gmem_f8E4M3FN, !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">, i32, i32, i32) -> !cuda.result
    %19 = cuda.cast %18 : !cuda.result -> i32
    cuda.return_if_error %19 : i32
    %c0_i32_22 = arith.constant 0 : i32
    return %c0_i32_22 : i32
  }
}
