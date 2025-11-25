!memref_gmem_f16_ = !cute.memref<f16, gmem, align<16>, "((1,256,1,1,1),(?,?,?,?,?)):((0,1,0,0,0),(?{i64},256,?{i64},?{i64},?{i64}))">
!memref_gmem_f16_1 = !cute.memref<f16, gmem, "((1,256,1,1,1)):((0,1,0,0,0))">
!memref_gmem_f16_2 = !cute.memref<f16, gmem, "(128,2):(2,1)">
!memref_gmem_f16_3 = !cute.memref<f16, gmem, "(2):(1)">
!memref_gmem_f16_4 = !cute.memref<f16, gmem, "(2,1):(1,0)">
!memref_gmem_f16_5 = !cute.memref<f16, gmem, "(2,(1)):(1,(0))">
!memref_gmem_f16_6 = !cute.memref<f16, gmem, align<16>, "(?,?,?,?,?):(?{i64},1,?{i64},?{i64},?{i64})">
!memref_gmem_f32_ = !cute.memref<f32, gmem, align<16>, "((1,256,1,1,1),(?,?,?,?,?)):((0,?{i64},0,0,0),(?{i64},?{i64 div=256},?{i64},1,?{i64}))">
!memref_gmem_f32_1 = !cute.memref<f32, gmem, "((1,256,1,1,1)):((0,?{i64},0,0,0))">
!memref_gmem_f32_2 = !cute.memref<f32, gmem, "(128,2):(?{i64 div=2},?{i64})">
!memref_gmem_f32_3 = !cute.memref<f32, gmem, "(2):(?{i64})">
!memref_gmem_f32_4 = !cute.memref<f32, gmem, "(2,1):(?{i64},0)">
!memref_gmem_f32_5 = !cute.memref<f32, gmem, "(2,(1)):(?{i64},(0))">
!memref_gmem_f32_6 = !cute.memref<f32, gmem, align<16>, "(?,?,?,?,?):(?{i64},?{i64},?{i64},1,?{i64})">
!memref_rmem_f16_ = !cute.memref<f16, rmem, align<32>, "2:1">
!memref_rmem_f16_1 = !cute.memref<f16, rmem, align<32>, "(2,1):(1,0)">
!memref_rmem_f16_2 = !cute.memref<f16, rmem, align<32>, "(2,(1)):(1,(0))">
!memref_rmem_f16_3 = !cute.memref<f16, rmem, align<32>, "(2):(1)">
!memref_rmem_f32_ = !cute.memref<f32, rmem, align<32>, "2:1">
!memref_rmem_f32_1 = !cute.memref<f32, rmem, align<32>, "(2,1):(1,0)">
!memref_rmem_f32_2 = !cute.memref<f32, rmem, align<32>, "(2,(1)):(1,(0))">
!memref_rmem_f32_3 = !cute.memref<f32, rmem, align<32>, "(2):(1)">
#loop_unroll = #llvm.loop_unroll<disable = false, full = true>
#loop_annotation = #llvm.loop_annotation<unroll = #loop_unroll>
module attributes {gpu.container_module} {
  gpu.module @kernels {
    func.func public @kernel_cutlass__convert_kernel_tensorptrf16gmemalign16o125611101000256_tensorptrf32gmemalign16o12561110000div2561_tensor00000o1256111011000102561121314______Float16_Float32_0(%arg0: !memref_gmem_f16_, %arg1: !memref_gmem_f32_, %arg2: !cute.coord_tensor<"(0,0,0,0,0)", "((1,256,1,1,1),(?,?,?,?,?)):((0,1@1,0,0,0),(1@0,256@1,1@2,1@3,1@4))">, %arg3: i32, %arg4: i32, %arg5: i32, %arg6: i32, %arg7: i32) attributes {cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} {
      %0 = cute.static : !cute.layout<"(128,2):(2,1)">
      %1 = cute.static : !cute.layout<"(128,2):(2,1)">
      %2 = nvvm.read.ptx.sreg.tid.x : i32
      %3 = nvvm.read.ptx.sreg.ctaid.x : i32
      %coord = cute.make_coord(%3) : (i32) -> !cute.coord<"(_,?)">
      %lay = cute.get_layout(%arg0) : !memref_gmem_f16_
      %idx = cute.crd2idx(%coord, %lay) : (!cute.coord<"(_,?)">, !cute.layout<"((1,256,1,1,1),(?,?,?,?,?)):((0,1,0,0,0),(?{i64},256,?{i64},?{i64},?{i64}))">) -> !cute.int_tuple<"?{i64}">
      %iter = cute.get_iter(%arg0) : !memref_gmem_f16_
      %ptr = cute.add_offset(%iter, %idx) : (!cute.ptr<f16, gmem, align<16>>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f16, gmem>
      %view = cute.make_view(%ptr) : !memref_gmem_f16_1
      %coord_0 = cute.make_coord(%3) : (i32) -> !cute.coord<"(_,?)">
      %lay_1 = cute.get_layout(%arg1) : !memref_gmem_f32_
      %4:10 = cute.get_scalars(%lay_1) <{only_dynamic}> : !cute.layout<"((1,256,1,1,1),(?,?,?,?,?)):((0,?{i64},0,0,0),(?{i64},?{i64 div=256},?{i64},1,?{i64}))">
      %5 = cute.static : !cute.shape<"((1,256,1,1,1))">
      %stride = cute.make_stride(%4#5) : (i64) -> !cute.stride<"((0,?{i64},0,0,0))">
      %lay_2 = cute.make_layout(%5, %stride) : !cute.layout<"((1,256,1,1,1)):((0,?{i64},0,0,0))">
      %idx_3 = cute.crd2idx(%coord_0, %lay_1) : (!cute.coord<"(_,?)">, !cute.layout<"((1,256,1,1,1),(?,?,?,?,?)):((0,?{i64},0,0,0),(?{i64},?{i64 div=256},?{i64},1,?{i64}))">) -> !cute.int_tuple<"?{i64}">
      %iter_4 = cute.get_iter(%arg1) : !memref_gmem_f32_
      %ptr_5 = cute.add_offset(%iter_4, %idx_3) : (!cute.ptr<f32, gmem, align<16>>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %view_6 = cute.make_view(%ptr_5, %lay_2) : !memref_gmem_f32_1
      %coord_7 = cute.make_coord(%3) : (i32) -> !cute.coord<"(_,?)">
      %lay_8 = cute.get_layout(%arg2) : !cute.coord_tensor<"(0,0,0,0,0)", "((1,256,1,1,1),(?,?,?,?,?)):((0,1@1,0,0,0),(1@0,256@1,1@2,1@3,1@4))">
      %idx_9 = cute.crd2idx(%coord_7, %lay_8) : (!cute.coord<"(_,?)">, !cute.layout<"((1,256,1,1,1),(?,?,?,?,?)):((0,1@1,0,0,0),(1@0,256@1,1@2,1@3,1@4))">) -> !cute.int_tuple<"(?,?{div=256},?,?,?)">
      %6 = cute.static : !cute.int_tuple<"(0,0,0,0,0)">
      %tup = cute.add_offset(%6, %idx_9) : (!cute.int_tuple<"(0,0,0,0,0)">, !cute.int_tuple<"(?,?{div=256},?,?,?)">) -> !cute.int_tuple<"(?,?{div=256},?,?,?)">
      %view_10 = cute.make_view(%tup) : !cute.coord_tensor<"(?,?{div=256},?,?,?)", "((1,256,1,1,1)):((0,1@1,0,0,0))">
      %iter_11 = cute.get_iter(%view) : !memref_gmem_f16_1
      %view_12 = cute.make_view(%iter_11) : !memref_gmem_f16_2
      %iter_13 = cute.get_iter(%view_6) : !memref_gmem_f32_1
      %lay_14 = cute.get_layout(%view_6) : !memref_gmem_f32_1
      %7 = cute.get_scalars(%lay_14) <{only_dynamic}> : !cute.layout<"((1,256,1,1,1)):((0,?{i64},0,0,0))">
      %c2_i64 = arith.constant 2 : i64
      %8 = arith.muli %7, %c2_i64 : i64
      %9 = cute.static : !cute.shape<"(128,2)">
      %iv = cute.assume(%8) : (i64) -> !cute.i64<divby 2>
      %stride_15 = cute.make_stride(%iv, %7) : (!cute.i64<divby 2>, i64) -> !cute.stride<"(?{i64 div=2},?{i64})">
      %lay_16 = cute.make_layout(%9, %stride_15) : !cute.layout<"(128,2):(?{i64 div=2},?{i64})">
      %view_17 = cute.make_view(%iter_13, %lay_16) : !memref_gmem_f32_2
      %iter_18 = cute.get_iter(%view_10) : !cute.coord_tensor<"(?,?{div=256},?,?,?)", "((1,256,1,1,1)):((0,1@1,0,0,0))">
      %view_19 = cute.make_view(%iter_18) : !cute.coord_tensor<"(?,?{div=256},?,?,?)", "(128,2):(2@1,1@1)">
      %coord_20 = cute.make_coord(%2) : (i32) -> !cute.coord<"(?,_)">
      %10 = cute.static : !cute.layout<"(128,2):(2,1)">
      %idx_21 = cute.crd2idx(%coord_20, %10) : (!cute.coord<"(?,_)">, !cute.layout<"(128,2):(2,1)">) -> !cute.int_tuple<"?{div=2}">
      %iter_22 = cute.get_iter(%view_12) : !memref_gmem_f16_2
      %ptr_23 = cute.add_offset(%iter_22, %idx_21) : (!cute.ptr<f16, gmem>, !cute.int_tuple<"?{div=2}">) -> !cute.ptr<f16, gmem>
      %view_24 = cute.make_view(%ptr_23) : !memref_gmem_f16_3
      %iter_25 = cute.get_iter(%view_24) : !memref_gmem_f16_3
      %coord_26 = cute.make_coord(%2) : (i32) -> !cute.coord<"(?,_)">
      %lay_27 = cute.get_layout(%view_17) : !memref_gmem_f32_2
      %11:2 = cute.get_scalars(%lay_27) <{only_dynamic}> : !cute.layout<"(128,2):(?{i64 div=2},?{i64})">
      %12 = cute.static : !cute.shape<"(2)">
      %stride_28 = cute.make_stride(%11#1) : (i64) -> !cute.stride<"(?{i64})">
      %lay_29 = cute.make_layout(%12, %stride_28) : !cute.layout<"(2):(?{i64})">
      %idx_30 = cute.crd2idx(%coord_26, %lay_27) : (!cute.coord<"(?,_)">, !cute.layout<"(128,2):(?{i64 div=2},?{i64})">) -> !cute.int_tuple<"?{i64 div=2}">
      %iter_31 = cute.get_iter(%view_17) : !memref_gmem_f32_2
      %ptr_32 = cute.add_offset(%iter_31, %idx_30) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
      %view_33 = cute.make_view(%ptr_32, %lay_29) : !memref_gmem_f32_3
      %iter_34 = cute.get_iter(%view_33) : !memref_gmem_f32_3
      %coord_35 = cute.make_coord(%2) : (i32) -> !cute.coord<"(?,_)">
      %13 = cute.static : !cute.layout<"(128,2):(2@1,1@1)">
      %idx_36 = cute.crd2idx(%coord_35, %13) : (!cute.coord<"(?,_)">, !cute.layout<"(128,2):(2@1,1@1)">) -> !cute.int_tuple<"(0,?{div=2})">
      %iter_37 = cute.get_iter(%view_19) : !cute.coord_tensor<"(?,?{div=256},?,?,?)", "(128,2):(2@1,1@1)">
      %tup_38 = cute.add_offset(%iter_37, %idx_36) : (!cute.int_tuple<"(?,?{div=256},?,?,?)">, !cute.int_tuple<"(0,?{div=2})">) -> !cute.int_tuple<"(?,?{div=2},?,?,?)">
      %view_39 = cute.make_view(%tup_38) : !cute.coord_tensor<"(?,?{div=2},?,?,?)", "(2):(1@1)">
      %14 = cute.static : !cute.int_tuple<"(0,0)">
      %iter_40 = cute.get_iter(%view_39) : !cute.coord_tensor<"(?,?{div=2},?,?,?)", "(2):(1@1)">
      %tup_41 = cute.add_offset(%iter_40, %14) : (!cute.int_tuple<"(?,?{div=2},?,?,?)">, !cute.int_tuple<"(0,0)">) -> !cute.int_tuple<"(?,?{div=2},?,?,?)">
      %view_42 = cute.make_view(%tup_41) : !cute.coord_tensor<"(?,?{div=2},?,?,?)", "():()">
      %iter_43 = cute.get_iter(%view_42) : !cute.coord_tensor<"(?,?{div=2},?,?,?)", "():()">
      %e0, %e1, %e2, %e3, %e4 = cute.get_leaves(%iter_43) : !cute.int_tuple<"(?,?{div=2},?,?,?)">
      %coord_44 = cute.make_coord(%e0, %e1, %e2, %e3, %e4) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=2}">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?{div=2},?,?,?)">
      %coord_45 = cute.make_coord(%arg3, %arg4, %arg5, %arg6, %arg7) : (i32, i32, i32, i32, i32) -> !cute.coord<"(?,?,?,?,?)">
      %15:5 = cute.get_scalars(%coord_44) : !cute.coord<"(?,?{div=2},?,?,?)">
      %16:5 = cute.get_scalars(%coord_45) : !cute.coord<"(?,?,?,?,?)">
      %true = arith.constant true
      %17 = arith.cmpi slt, %15#0, %16#0 : i32
      %18 = arith.andi %true, %17 : i1
      %19 = arith.cmpi slt, %15#1, %16#1 : i32
      %20 = arith.andi %18, %19 : i1
      %21 = arith.cmpi slt, %15#2, %16#2 : i32
      %22 = arith.andi %20, %21 : i1
      %23 = arith.cmpi slt, %15#3, %16#3 : i32
      %24 = arith.andi %22, %23 : i1
      %25 = arith.cmpi slt, %15#4, %16#4 : i32
      %26 = arith.andi %24, %25 : i1
      scf.if %26 {
        %27 = cute.static : !cute.layout<"2:1">
        %rmem = cute.memref.alloca(%27) : !memref_rmem_f16_
        %iter_46 = cute.get_iter(%rmem) : !memref_rmem_f16_
        %28 = cute.static : !cute.layout<"2:1">
        %rmem_47 = cute.memref.alloca(%28) : !memref_rmem_f32_
        %iter_48 = cute.get_iter(%rmem_47) : !memref_rmem_f32_
        %29 = cute.static : !cute.layout<"(2,1):(1,0)">
        %view_49 = cute.make_view(%iter_25, %29) : !memref_gmem_f16_4
        %iter_50 = cute.get_iter(%view_49) : !memref_gmem_f16_4
        %view_51 = cute.make_view(%iter_50) : !memref_gmem_f16_5
        %30 = cute.static : !cute.layout<"(2,1):(1,0)">
        %view_52 = cute.make_view(%iter_46, %30) : !memref_rmem_f16_1
        %iter_53 = cute.get_iter(%view_52) : !memref_rmem_f16_1
        %view_54 = cute.make_view(%iter_53) : !memref_rmem_f16_2
        %31 = cute.static : !cute.layout<"1:0">
        %iter_55 = cute.get_iter(%view_51) : !memref_gmem_f16_5
        %iter_56 = cute.get_iter(%view_54) : !memref_rmem_f16_2
        %32 = cute.static : !cute.int_tuple<"1">
        %33 = cute.get_scalars(%32) : !cute.int_tuple<"1">
        %c0_i32 = arith.constant 0 : i32
        %c1_i32 = arith.constant 1 : i32
        scf.for %arg8 = %c0_i32 to %33 step %c1_i32  : i32 {
          %45 = cute.static : !cute.layout<"(2):(1)">
          %46 = cute.static : !cute.int_tuple<"0">
          %ptr_75 = cute.add_offset(%iter_55, %46) : (!cute.ptr<f16, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<f16, gmem>
          %view_76 = cute.make_view(%ptr_75, %45) : !memref_gmem_f16_3
          %47 = cute.static : !cute.layout<"(2):(1)">
          %48 = cute.static : !cute.int_tuple<"0">
          %ptr_77 = cute.add_offset(%iter_56, %48) : (!cute.ptr<f16, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f16, rmem, align<32>>
          %view_78 = cute.make_view(%ptr_77, %47) : !memref_rmem_f16_3
          %iter_79 = cute.get_iter(%view_76) : !memref_gmem_f16_3
          %iter_80 = cute.get_iter(%view_78) : !memref_rmem_f16_3
          %49 = builtin.unrealized_conversion_cast %iter_79 : !cute.ptr<f16, gmem> to !llvm.ptr<1>
          %50 = builtin.unrealized_conversion_cast %iter_80 : !cute.ptr<f16, rmem, align<32>> to !llvm.ptr
          %51 = llvm.load %49 {alignment = 2 : i64} : !llvm.ptr<1> -> vector<1xf16>
          llvm.store %51, %50 {alignment = 2 : i64} : vector<1xf16>, !llvm.ptr
          %52 = cute.static : !cute.int_tuple<"1">
          %ptr_81 = cute.add_offset(%iter_79, %52) : (!cute.ptr<f16, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f16, gmem>
          %53 = cute.static : !cute.int_tuple<"1">
          %ptr_82 = cute.add_offset(%iter_80, %53) : (!cute.ptr<f16, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f16, rmem>
          %54 = builtin.unrealized_conversion_cast %ptr_81 : !cute.ptr<f16, gmem> to !llvm.ptr<1>
          %55 = builtin.unrealized_conversion_cast %ptr_82 : !cute.ptr<f16, rmem> to !llvm.ptr
          %56 = llvm.load %54 {alignment = 2 : i64} : !llvm.ptr<1> -> vector<1xf16>
          llvm.store %56, %55 {alignment = 2 : i64} : vector<1xf16>, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %34 = cute.memref.load_vec %rmem, row_major : !memref_rmem_f16_
        %35 = arith.extf %34 : vector<2xf16> to vector<2xf32>
        cute.memref.store_vec %35, %rmem_47, row_major : !memref_rmem_f32_
        %36 = cute.static : !cute.layout<"(2,1):(1,0)">
        %view_57 = cute.make_view(%iter_48, %36) : !memref_rmem_f32_1
        %iter_58 = cute.get_iter(%view_57) : !memref_rmem_f32_1
        %view_59 = cute.make_view(%iter_58) : !memref_rmem_f32_2
        %lay_60 = cute.get_layout(%view_33) : !memref_gmem_f32_3
        %37 = cute.static : !cute.layout<"1:0">
        %append = cute.append_to_rank<2> (%lay_60, %37) : !cute.layout<"(2):(?{i64})">, !cute.layout<"1:0">
        %view_61 = cute.make_view(%iter_34, %append) : !memref_gmem_f32_4
        %iter_62 = cute.get_iter(%view_61) : !memref_gmem_f32_4
        %lay_63 = cute.get_layout(%view_61) : !memref_gmem_f32_4
        %38 = cute.get_scalars(%lay_63) <{only_dynamic}> : !cute.layout<"(2,1):(?{i64},0)">
        %39 = cute.static : !cute.shape<"(2,(1))">
        %stride_64 = cute.make_stride(%38) : (i64) -> !cute.stride<"(?{i64},(0))">
        %lay_65 = cute.make_layout(%39, %stride_64) : !cute.layout<"(2,(1)):(?{i64},(0))">
        %view_66 = cute.make_view(%iter_62, %lay_65) : !memref_gmem_f32_5
        %40 = cute.static : !cute.layout<"1:0">
        %iter_67 = cute.get_iter(%view_59) : !memref_rmem_f32_2
        %iter_68 = cute.get_iter(%view_66) : !memref_gmem_f32_5
        %lay_69 = cute.get_layout(%view_66) : !memref_gmem_f32_5
        %append_70 = cute.append_to_rank<2> (%lay_69, %40) : !cute.layout<"(2,(1)):(?{i64},(0))">, !cute.layout<"1:0">
        %41 = cute.get_scalars(%append_70) <{only_dynamic}> : !cute.layout<"(2,(1)):(?{i64},(0))">
        %42 = cute.static : !cute.shape<"(2,((1)))">
        %stride_71 = cute.make_stride(%41) : (i64) -> !cute.stride<"(?{i64},((0)))">
        %lay_72 = cute.make_layout(%42, %stride_71) : !cute.layout<"(2,((1))):(?{i64},((0)))">
        %43 = cute.static : !cute.int_tuple<"1">
        %44 = cute.get_scalars(%43) : !cute.int_tuple<"1">
        %c0_i32_73 = arith.constant 0 : i32
        %c1_i32_74 = arith.constant 1 : i32
        scf.for %arg8 = %c0_i32_73 to %44 step %c1_i32_74  : i32 {
          %45 = cute.static : !cute.layout<"(2):(1)">
          %46 = cute.static : !cute.int_tuple<"0">
          %ptr_75 = cute.add_offset(%iter_67, %46) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, rmem, align<32>>
          %view_76 = cute.make_view(%ptr_75, %45) : !memref_rmem_f32_3
          %47 = cute.get_scalars(%lay_72) <{only_dynamic}> : !cute.layout<"(2,((1))):(?{i64},((0)))">
          %48 = cute.static : !cute.shape<"(2)">
          %stride_77 = cute.make_stride(%47) : (i64) -> !cute.stride<"(?{i64})">
          %lay_78 = cute.make_layout(%48, %stride_77) : !cute.layout<"(2):(?{i64})">
          %49 = cute.static : !cute.int_tuple<"0">
          %ptr_79 = cute.add_offset(%iter_68, %49) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<f32, gmem>
          %view_80 = cute.make_view(%ptr_79, %lay_78) : !memref_gmem_f32_3
          %iter_81 = cute.get_iter(%view_76) : !memref_rmem_f32_3
          %iter_82 = cute.get_iter(%view_80) : !memref_gmem_f32_3
          %lay_83 = cute.get_layout(%view_80) : !memref_gmem_f32_3
          %50 = cute.get_scalars(%lay_83) <{only_dynamic}> : !cute.layout<"(2):(?{i64})">
          %51 = builtin.unrealized_conversion_cast %iter_81 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
          %52 = builtin.unrealized_conversion_cast %iter_82 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %53 = llvm.load %51 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %53, %52 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
          %54 = cute.static : !cute.int_tuple<"1">
          %ptr_84 = cute.add_offset(%iter_81, %54) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
          %int_tuple = cute.make_int_tuple(%50) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_85 = cute.add_offset(%iter_82, %int_tuple) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %55 = builtin.unrealized_conversion_cast %ptr_84 : !cute.ptr<f32, rmem> to !llvm.ptr
          %56 = builtin.unrealized_conversion_cast %ptr_85 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %57 = llvm.load %55 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %57, %56 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        } {llvm.loop_annotation = #loop_annotation}
      }
      return
    }
  }
  func.func @cutlass__convert_Tensorgmemoi641i64i64i64_Tensorgmemoi64i64i641i64_1_2(%arg0: !memref_gmem_f16_6, %arg1: !memref_gmem_f32_6) attributes {llvm.emit_c_interface} {
    %lay = cute.get_layout(%arg0) : !memref_gmem_f16_6
    %0 = cute.get_shape(%lay) : (!cute.layout<"(?,?,?,?,?):(?{i64},1,?{i64},?{i64},?{i64})">) -> !cute.shape<"(?,?,?,?,?)">
    %e0, %e1, %e2, %e3, %e4 = cute.get_leaves(%0) : !cute.shape<"(?,?,?,?,?)">
    %itup = cute.to_int_tuple(%e0) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %1 = cute.get_scalars(%itup) : !cute.int_tuple<"?">
    %itup_0 = cute.to_int_tuple(%e1) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %2 = cute.get_scalars(%itup_0) : !cute.int_tuple<"?">
    %itup_1 = cute.to_int_tuple(%e2) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %3 = cute.get_scalars(%itup_1) : !cute.int_tuple<"?">
    %itup_2 = cute.to_int_tuple(%e3) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %4 = cute.get_scalars(%itup_2) : !cute.int_tuple<"?">
    %itup_3 = cute.to_int_tuple(%e4) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %5 = cute.get_scalars(%itup_3) : !cute.int_tuple<"?">
    %shape = cute.make_shape(%itup, %itup_0, %itup_1, %itup_2, %itup_3) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.shape<"(?,?,?,?,?)">
    %6 = cute.static : !cute.int_tuple<"(0,0,0,0,0)">
    %7 = cute.static : !cute.stride<"(1@0,1@1,1@2,1@3,1@4)">
    %lay_4 = cute.make_layout(%shape, %7) : !cute.layout<"(?,?,?,?,?):(1@0,1@1,1@2,1@3,1@4)">
    %view = cute.make_view(%6, %lay_4) : !cute.coord_tensor<"(0,0,0,0,0)", "(?,?,?,?,?):(1@0,1@1,1@2,1@3,1@4)">
    %iter = cute.get_iter(%arg0) : !memref_gmem_f16_6
    %lay_5 = cute.get_layout(%arg0) : !memref_gmem_f16_6
    %8:9 = cute.get_scalars(%lay_5) <{only_dynamic}> : !cute.layout<"(?,?,?,?,?):(?{i64},1,?{i64},?{i64},?{i64})">
    %c256_i32 = arith.constant 256 : i32
    %9 = arith.ceildivsi %8#1, %c256_i32 : i32
    %shape_6 = cute.make_shape(%8#0, %9, %8#2, %8#3, %8#4) : (i32, i32, i32, i32, i32) -> !cute.shape<"((1,256,1,1,1),(?,?,?,?,?))">
    %stride = cute.make_stride(%8#5, %8#6, %8#7, %8#8) : (i64, i64, i64, i64) -> !cute.stride<"((0,1,0,0,0),(?{i64},256,?{i64},?{i64},?{i64}))">
    %lay_7 = cute.make_layout(%shape_6, %stride) : !cute.layout<"((1,256,1,1,1),(?,?,?,?,?)):((0,1,0,0,0),(?{i64},256,?{i64},?{i64},?{i64}))">
    %view_8 = cute.make_view(%iter, %lay_7) : !memref_gmem_f16_
    %10 = cute.static : !cute.int_tuple<"(0,0,0,0,0)">
    %lay_9 = cute.get_layout(%view) : !cute.coord_tensor<"(0,0,0,0,0)", "(?,?,?,?,?):(1@0,1@1,1@2,1@3,1@4)">
    %11:5 = cute.get_scalars(%lay_9) <{only_dynamic}> : !cute.layout<"(?,?,?,?,?):(1@0,1@1,1@2,1@3,1@4)">
    %c256_i32_10 = arith.constant 256 : i32
    %12 = arith.ceildivsi %11#1, %c256_i32_10 : i32
    %shape_11 = cute.make_shape(%11#0, %12, %11#2, %11#3, %11#4) : (i32, i32, i32, i32, i32) -> !cute.shape<"((1,256,1,1,1),(?,?,?,?,?))">
    %13 = cute.static : !cute.stride<"((0,1@1,0,0,0),(1@0,256@1,1@2,1@3,1@4))">
    %lay_12 = cute.make_layout(%shape_11, %13) : !cute.layout<"((1,256,1,1,1),(?,?,?,?,?)):((0,1@1,0,0,0),(1@0,256@1,1@2,1@3,1@4))">
    %view_13 = cute.make_view(%10, %lay_12) : !cute.coord_tensor<"(0,0,0,0,0)", "((1,256,1,1,1),(?,?,?,?,?)):((0,1@1,0,0,0),(1@0,256@1,1@2,1@3,1@4))">
    %iter_14 = cute.get_iter(%arg1) : !memref_gmem_f32_6
    %lay_15 = cute.get_layout(%arg1) : !memref_gmem_f32_6
    %14:9 = cute.get_scalars(%lay_15) <{only_dynamic}> : !cute.layout<"(?,?,?,?,?):(?{i64},?{i64},?{i64},1,?{i64})">
    %c256_i32_16 = arith.constant 256 : i32
    %15 = arith.ceildivsi %14#1, %c256_i32_16 : i32
    %c256_i64 = arith.constant 256 : i64
    %16 = arith.muli %14#6, %c256_i64 : i64
    %shape_17 = cute.make_shape(%14#0, %15, %14#2, %14#3, %14#4) : (i32, i32, i32, i32, i32) -> !cute.shape<"((1,256,1,1,1),(?,?,?,?,?))">
    %iv = cute.assume(%16) : (i64) -> !cute.i64<divby 256>
    %stride_18 = cute.make_stride(%14#6, %14#5, %iv, %14#7, %14#8) : (i64, i64, !cute.i64<divby 256>, i64, i64) -> !cute.stride<"((0,?{i64},0,0,0),(?{i64},?{i64 div=256},?{i64},1,?{i64}))">
    %lay_19 = cute.make_layout(%shape_17, %stride_18) : !cute.layout<"((1,256,1,1,1),(?,?,?,?,?)):((0,?{i64},0,0,0),(?{i64},?{i64 div=256},?{i64},1,?{i64}))">
    %view_20 = cute.make_view(%iter_14, %lay_19) : !memref_gmem_f32_
    %lay_21 = cute.get_layout(%view_8) : !memref_gmem_f16_
    %sz = cute.size(%lay_21) <{mode = [1]}> : (!cute.layout<"((1,256,1,1,1),(?,?,?,?,?)):((0,1,0,0,0),(?{i64},256,?{i64},?{i64},?{i64}))">) -> !cute.int_tuple<"?">
    %e0_22 = cute.get_leaves(%sz) : !cute.int_tuple<"?">
    %17 = cute.get_scalars(%e0_22) : !cute.int_tuple<"?">
    %18 = arith.index_cast %17 : i32 to index
    %c1 = arith.constant 1 : index
    %c128 = arith.constant 128 : index
    %c0_i32 = arith.constant 0 : i32
    gpu.launch_func  @kernels::@kernel_cutlass__convert_kernel_tensorptrf16gmemalign16o125611101000256_tensorptrf32gmemalign16o12561110000div2561_tensor00000o1256111011000102561121314______Float16_Float32_0 blocks in (%18, %c1, %c1) threads in (%c128, %c1, %c1)  dynamic_shared_memory_size %c0_i32 args(%view_8 : !memref_gmem_f16_, %view_20 : !memref_gmem_f32_, %view_13 : !cute.coord_tensor<"(0,0,0,0,0)", "((1,256,1,1,1),(?,?,?,?,?)):((0,1@1,0,0,0),(1@0,256@1,1@2,1@3,1@4))">, %1 : i32, %2 : i32, %3 : i32, %4 : i32, %5 : i32) {use_pdl = false}
    return
  }
}
