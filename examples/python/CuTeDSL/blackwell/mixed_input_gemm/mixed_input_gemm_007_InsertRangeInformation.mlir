!memref_gmem_f32_ = !cute.memref<f32, gmem, "((1024,1,1),(?,?,?)):((1,0,0),(1024,?{i64},?{i64}))">
!memref_gmem_f32_1 = !cute.memref<f32, gmem, "((1024,1,1)):((1,0,0))">
!memref_gmem_f32_2 = !cute.memref<f32, gmem, "(128,8):(8,1)">
!memref_gmem_f32_3 = !cute.memref<f32, gmem, "(8):(1)">
!memref_gmem_f32_4 = !cute.memref<f32, gmem, "(8,1):(1,0)">
!memref_gmem_f32_5 = !cute.memref<f32, gmem, "(8,(1)):(1,(0))">
!memref_gmem_f32_6 = !cute.memref<f32, gmem, "(?,?,?):(1,?{i64},?{i64})">
!memref_gmem_i4_ = !cute.memref<i4, gmem, align<128>, "(?,?,?):(1,?{i64},?{i64})">
!memref_gmem_i8_ = !cute.memref<i8, gmem, align<128>, "((512,1,1),(?,?,?)):((1,0,0),(512,?{i64},?{i64}))">
!memref_gmem_i8_1 = !cute.memref<i8, gmem, "((512,1,1)):((1,0,0))">
!memref_gmem_i8_2 = !cute.memref<i8, gmem, "(128,4):(4,1)">
!memref_gmem_i8_3 = !cute.memref<i8, gmem, "(4):(1)">
!memref_gmem_i8_4 = !cute.memref<i8, gmem, "(4,1):(1,0)">
!memref_gmem_i8_5 = !cute.memref<i8, gmem, "(4,(1)):(1,(0))">
!memref_gmem_i8_6 = !cute.memref<i8, gmem, align<128>, "(?,?,?):(1,?{i64},?{i64})">
!memref_rmem_f32_ = !cute.memref<f32, rmem, align<32>, "8:1">
!memref_rmem_f32_1 = !cute.memref<f32, rmem, align<32>, "(8,1):(1,0)">
!memref_rmem_f32_2 = !cute.memref<f32, rmem, align<32>, "(8,(1)):(1,(0))">
!memref_rmem_f32_3 = !cute.memref<f32, rmem, align<32>, "(8):(1)">
!memref_rmem_i8_ = !cute.memref<i8, rmem, align<32>, "4:1">
!memref_rmem_i8_1 = !cute.memref<i8, rmem, align<32>, "(4,1):(1,0)">
!memref_rmem_i8_2 = !cute.memref<i8, rmem, align<32>, "(4,(1)):(1,(0))">
!memref_rmem_i8_3 = !cute.memref<i8, rmem, align<32>, "(4):(1)">
#loop_unroll = #llvm.loop_unroll<disable = false, full = true>
#loop_annotation = #llvm.loop_annotation<unroll = #loop_unroll>
module attributes {gpu.container_module} {
  gpu.module @kernels {
    func.func public @kernel_cutlass__convert_kernel_tensorptrf32gmemo1024111001024_tensorptri8gmemalign128o51211100512_tensor000o1024111000102401112____Float32_Int4_0(%arg0: !memref_gmem_f32_, %arg1: !memref_gmem_i8_, %arg2: !cute.coord_tensor<"(0,0,0)", "((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">, %arg3: i32, %arg4: i32, %arg5: i32) attributes {cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} {
      %0 = cute.static : !cute.layout<"(128,8):(8,1)">
      %1 = cute.static : !cute.layout<"(128,4):(4,1)">
      %2 = nvvm.read.ptx.sreg.tid.x range <i32, 0, 1024> : i32
      %3 = nvvm.read.ptx.sreg.ctaid.x range <i32, 0, 2147483647> : i32
      %coord = cute.make_coord(%3) : (i32) -> !cute.coord<"(_,?)">
      %lay = cute.get_layout(%arg0) : !memref_gmem_f32_
      %idx = cute.crd2idx(%coord, %lay) : (!cute.coord<"(_,?)">, !cute.layout<"((1024,1,1),(?,?,?)):((1,0,0),(1024,?{i64},?{i64}))">) -> !cute.int_tuple<"?{i64}">
      %iter = cute.get_iter(%arg0) : !memref_gmem_f32_
      %ptr = cute.add_offset(%iter, %idx) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %view = cute.make_view(%ptr) : !memref_gmem_f32_1
      %coord_0 = cute.make_coord(%3) : (i32) -> !cute.coord<"(_,?)">
      %lay_1 = cute.get_layout(%arg1) : !memref_gmem_i8_
      %idx_2 = cute.crd2idx(%coord_0, %lay_1) : (!cute.coord<"(_,?)">, !cute.layout<"((512,1,1),(?,?,?)):((1,0,0),(512,?{i64},?{i64}))">) -> !cute.int_tuple<"?{i64}">
      %iter_3 = cute.get_iter(%arg1) : !memref_gmem_i8_
      %ptr_4 = cute.add_offset(%iter_3, %idx_2) : (!cute.ptr<i8, gmem, align<128>>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<i8, gmem>
      %view_5 = cute.make_view(%ptr_4) : !memref_gmem_i8_1
      %coord_6 = cute.make_coord(%3) : (i32) -> !cute.coord<"(_,?)">
      %lay_7 = cute.get_layout(%arg2) : !cute.coord_tensor<"(0,0,0)", "((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">
      %idx_8 = cute.crd2idx(%coord_6, %lay_7) : (!cute.coord<"(_,?)">, !cute.layout<"((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">) -> !cute.int_tuple<"(?{div=1024},?,?)">
      %4 = cute.static : !cute.int_tuple<"(0,0,0)">
      %tup = cute.add_offset(%4, %idx_8) : (!cute.int_tuple<"(0,0,0)">, !cute.int_tuple<"(?{div=1024},?,?)">) -> !cute.int_tuple<"(?{div=1024},?,?)">
      %view_9 = cute.make_view(%tup) : !cute.coord_tensor<"(?{div=1024},?,?)", "((1024,1,1)):((1@0,0,0))">
      %iter_10 = cute.get_iter(%view) : !memref_gmem_f32_1
      %view_11 = cute.make_view(%iter_10) : !memref_gmem_f32_2
      %iter_12 = cute.get_iter(%view_5) : !memref_gmem_i8_1
      %view_13 = cute.make_view(%iter_12) : !memref_gmem_i8_2
      %iter_14 = cute.get_iter(%view_9) : !cute.coord_tensor<"(?{div=1024},?,?)", "((1024,1,1)):((1@0,0,0))">
      %view_15 = cute.make_view(%iter_14) : !cute.coord_tensor<"(?{div=1024},?,?)", "(128,8):(8@0,1@0)">
      %coord_16 = cute.make_coord(%2) : (i32) -> !cute.coord<"(?,_)">
      %5 = cute.static : !cute.layout<"(128,8):(8,1)">
      %idx_17 = cute.crd2idx(%coord_16, %5) : (!cute.coord<"(?,_)">, !cute.layout<"(128,8):(8,1)">) -> !cute.int_tuple<"?{div=8}">
      %iter_18 = cute.get_iter(%view_11) : !memref_gmem_f32_2
      %ptr_19 = cute.add_offset(%iter_18, %idx_17) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{div=8}">) -> !cute.ptr<f32, gmem>
      %view_20 = cute.make_view(%ptr_19) : !memref_gmem_f32_3
      %iter_21 = cute.get_iter(%view_20) : !memref_gmem_f32_3
      %coord_22 = cute.make_coord(%2) : (i32) -> !cute.coord<"(?,_)">
      %6 = cute.static : !cute.layout<"(128,4):(4,1)">
      %idx_23 = cute.crd2idx(%coord_22, %6) : (!cute.coord<"(?,_)">, !cute.layout<"(128,4):(4,1)">) -> !cute.int_tuple<"?{div=4}">
      %iter_24 = cute.get_iter(%view_13) : !memref_gmem_i8_2
      %ptr_25 = cute.add_offset(%iter_24, %idx_23) : (!cute.ptr<i8, gmem>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<i8, gmem>
      %view_26 = cute.make_view(%ptr_25) : !memref_gmem_i8_3
      %iter_27 = cute.get_iter(%view_26) : !memref_gmem_i8_3
      %coord_28 = cute.make_coord(%2) : (i32) -> !cute.coord<"(?,_)">
      %7 = cute.static : !cute.layout<"(128,8):(8@0,1@0)">
      %idx_29 = cute.crd2idx(%coord_28, %7) : (!cute.coord<"(?,_)">, !cute.layout<"(128,8):(8@0,1@0)">) -> !cute.int_tuple<"(?{div=8})">
      %iter_30 = cute.get_iter(%view_15) : !cute.coord_tensor<"(?{div=1024},?,?)", "(128,8):(8@0,1@0)">
      %tup_31 = cute.add_offset(%iter_30, %idx_29) : (!cute.int_tuple<"(?{div=1024},?,?)">, !cute.int_tuple<"(?{div=8})">) -> !cute.int_tuple<"(?{div=8},?,?)">
      %view_32 = cute.make_view(%tup_31) : !cute.coord_tensor<"(?{div=8},?,?)", "(8):(1@0)">
      %8 = cute.static : !cute.int_tuple<"(0)">
      %iter_33 = cute.get_iter(%view_32) : !cute.coord_tensor<"(?{div=8},?,?)", "(8):(1@0)">
      %tup_34 = cute.add_offset(%iter_33, %8) : (!cute.int_tuple<"(?{div=8},?,?)">, !cute.int_tuple<"(0)">) -> !cute.int_tuple<"(?{div=8},?,?)">
      %view_35 = cute.make_view(%tup_34) : !cute.coord_tensor<"(?{div=8},?,?)", "():()">
      %iter_36 = cute.get_iter(%view_35) : !cute.coord_tensor<"(?{div=8},?,?)", "():()">
      %e0, %e1, %e2 = cute.get_leaves(%iter_36) : !cute.int_tuple<"(?{div=8},?,?)">
      %coord_37 = cute.make_coord(%e0, %e1, %e2) : (!cute.int_tuple<"?{div=8}">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?{div=8},?,?)">
      %coord_38 = cute.make_coord(%arg3, %arg4, %arg5) : (i32, i32, i32) -> !cute.coord<"(?,?,?)">
      %9:3 = cute.get_scalars(%coord_37) : !cute.coord<"(?{div=8},?,?)">
      %10:3 = cute.get_scalars(%coord_38) : !cute.coord<"(?,?,?)">
      %true = arith.constant true
      %11 = arith.cmpi slt, %9#0, %10#0 : i32
      %12 = arith.andi %true, %11 : i1
      %13 = arith.cmpi slt, %9#1, %10#1 : i32
      %14 = arith.andi %12, %13 : i1
      %15 = arith.cmpi slt, %9#2, %10#2 : i32
      %16 = arith.andi %14, %15 : i1
      scf.if %16 {
        %17 = cute.static : !cute.layout<"8:1">
        %rmem = cute.memref.alloca(%17) : !memref_rmem_f32_
        %iter_39 = cute.get_iter(%rmem) : !memref_rmem_f32_
        %18 = cute.static : !cute.layout<"4:1">
        %rmem_40 = cute.memref.alloca(%18) : !memref_rmem_i8_
        %iter_41 = cute.get_iter(%rmem_40) : !memref_rmem_i8_
        %19 = cute.static : !cute.layout<"(8,1):(1,0)">
        %view_42 = cute.make_view(%iter_21, %19) : !memref_gmem_f32_4
        %iter_43 = cute.get_iter(%view_42) : !memref_gmem_f32_4
        %view_44 = cute.make_view(%iter_43) : !memref_gmem_f32_5
        %20 = cute.static : !cute.layout<"(8,1):(1,0)">
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
          %35 = cute.static : !cute.layout<"(8):(1)">
          %36 = cute.static : !cute.int_tuple<"0">
          %ptr_60 = cute.add_offset(%iter_48, %36) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<f32, gmem>
          %view_61 = cute.make_view(%ptr_60, %35) : !memref_gmem_f32_3
          %37 = cute.static : !cute.layout<"(8):(1)">
          %38 = cute.static : !cute.int_tuple<"0">
          %ptr_62 = cute.add_offset(%iter_49, %38) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<f32, rmem, align<32>>
          %view_63 = cute.make_view(%ptr_62, %37) : !memref_rmem_f32_3
          %iter_64 = cute.get_iter(%view_61) : !memref_gmem_f32_3
          %iter_65 = cute.get_iter(%view_63) : !memref_rmem_f32_3
          %39 = builtin.unrealized_conversion_cast %iter_64 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %40 = builtin.unrealized_conversion_cast %iter_65 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
          %41 = llvm.load %39 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %41, %40 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          %42 = cute.static : !cute.int_tuple<"1">
          %ptr_66 = cute.add_offset(%iter_64, %42) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
          %43 = cute.static : !cute.int_tuple<"1">
          %ptr_67 = cute.add_offset(%iter_65, %43) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
          %44 = builtin.unrealized_conversion_cast %ptr_66 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %45 = builtin.unrealized_conversion_cast %ptr_67 : !cute.ptr<f32, rmem> to !llvm.ptr
          %46 = llvm.load %44 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %46, %45 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          %47 = cute.static : !cute.int_tuple<"2">
          %ptr_68 = cute.add_offset(%iter_64, %47) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
          %48 = cute.static : !cute.int_tuple<"2">
          %ptr_69 = cute.add_offset(%iter_65, %48) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
          %49 = builtin.unrealized_conversion_cast %ptr_68 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %50 = builtin.unrealized_conversion_cast %ptr_69 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %51 = llvm.load %49 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %51, %50 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          %52 = cute.static : !cute.int_tuple<"3">
          %ptr_70 = cute.add_offset(%iter_64, %52) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
          %53 = cute.static : !cute.int_tuple<"3">
          %ptr_71 = cute.add_offset(%iter_65, %53) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
          %54 = builtin.unrealized_conversion_cast %ptr_70 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %55 = builtin.unrealized_conversion_cast %ptr_71 : !cute.ptr<f32, rmem> to !llvm.ptr
          %56 = llvm.load %54 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %56, %55 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          %57 = cute.static : !cute.int_tuple<"4">
          %ptr_72 = cute.add_offset(%iter_64, %57) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"4">) -> !cute.ptr<f32, gmem>
          %58 = cute.static : !cute.int_tuple<"4">
          %ptr_73 = cute.add_offset(%iter_65, %58) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
          %59 = builtin.unrealized_conversion_cast %ptr_72 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %60 = builtin.unrealized_conversion_cast %ptr_73 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
          %61 = llvm.load %59 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %61, %60 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          %62 = cute.static : !cute.int_tuple<"5">
          %ptr_74 = cute.add_offset(%iter_64, %62) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"5">) -> !cute.ptr<f32, gmem>
          %63 = cute.static : !cute.int_tuple<"5">
          %ptr_75 = cute.add_offset(%iter_65, %63) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<f32, rmem>
          %64 = builtin.unrealized_conversion_cast %ptr_74 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %65 = builtin.unrealized_conversion_cast %ptr_75 : !cute.ptr<f32, rmem> to !llvm.ptr
          %66 = llvm.load %64 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %66, %65 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          %67 = cute.static : !cute.int_tuple<"6">
          %ptr_76 = cute.add_offset(%iter_64, %67) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"6">) -> !cute.ptr<f32, gmem>
          %68 = cute.static : !cute.int_tuple<"6">
          %ptr_77 = cute.add_offset(%iter_65, %68) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
          %69 = builtin.unrealized_conversion_cast %ptr_76 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %70 = builtin.unrealized_conversion_cast %ptr_77 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %71 = llvm.load %69 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %71, %70 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          %72 = cute.static : !cute.int_tuple<"7">
          %ptr_78 = cute.add_offset(%iter_64, %72) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"7">) -> !cute.ptr<f32, gmem>
          %73 = cute.static : !cute.int_tuple<"7">
          %ptr_79 = cute.add_offset(%iter_65, %73) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<f32, rmem>
          %74 = builtin.unrealized_conversion_cast %ptr_78 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %75 = builtin.unrealized_conversion_cast %ptr_79 : !cute.ptr<f32, rmem> to !llvm.ptr
          %76 = llvm.load %74 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %76, %75 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        } {llvm.loop_annotation = #loop_annotation}
        %24 = cute.memref.load_vec %rmem, row_major : !memref_rmem_f32_
        %25 = arith.fptosi %24 : vector<8xf32> to vector<8xi4>
        %26 = cute.static : !cute.layout<"8:1">
        %27 = cute.recast_layout<8, 4> (%26) : !cute.layout<"8:1"> to !cute.layout<"4:1">
        %28 = builtin.unrealized_conversion_cast %25 : vector<8xi4> to vector<8xi4>
        %29 = vector.bitcast %28 : vector<8xi4> to vector<4xi8>
        cute.memref.store_vec %29, %rmem_40, row_major : !memref_rmem_i8_
        %30 = cute.static : !cute.layout<"(4,1):(1,0)">
        %view_50 = cute.make_view(%iter_41, %30) : !memref_rmem_i8_1
        %iter_51 = cute.get_iter(%view_50) : !memref_rmem_i8_1
        %view_52 = cute.make_view(%iter_51) : !memref_rmem_i8_2
        %31 = cute.static : !cute.layout<"(4,1):(1,0)">
        %view_53 = cute.make_view(%iter_27, %31) : !memref_gmem_i8_4
        %iter_54 = cute.get_iter(%view_53) : !memref_gmem_i8_4
        %view_55 = cute.make_view(%iter_54) : !memref_gmem_i8_5
        %32 = cute.static : !cute.layout<"1:0">
        %iter_56 = cute.get_iter(%view_52) : !memref_rmem_i8_2
        %iter_57 = cute.get_iter(%view_55) : !memref_gmem_i8_5
        %33 = cute.static : !cute.int_tuple<"1">
        %34 = cute.get_scalars(%33) : !cute.int_tuple<"1">
        %c0_i32_58 = arith.constant 0 : i32
        %c1_i32_59 = arith.constant 1 : i32
        scf.for %arg6 = %c0_i32_58 to %34 step %c1_i32_59  : i32 {
          %35 = cute.static : !cute.layout<"(4):(1)">
          %36 = cute.static : !cute.int_tuple<"0">
          %ptr_60 = cute.add_offset(%iter_56, %36) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"0">) -> !cute.ptr<i8, rmem, align<32>>
          %view_61 = cute.make_view(%ptr_60, %35) : !memref_rmem_i8_3
          %37 = cute.static : !cute.layout<"(4):(1)">
          %38 = cute.static : !cute.int_tuple<"0">
          %ptr_62 = cute.add_offset(%iter_57, %38) : (!cute.ptr<i8, gmem>, !cute.int_tuple<"0">) -> !cute.ptr<i8, gmem>
          %view_63 = cute.make_view(%ptr_62, %37) : !memref_gmem_i8_3
          %iter_64 = cute.get_iter(%view_61) : !memref_rmem_i8_3
          %iter_65 = cute.get_iter(%view_63) : !memref_gmem_i8_3
          %39 = builtin.unrealized_conversion_cast %iter_64 : !cute.ptr<i8, rmem, align<32>> to !llvm.ptr
          %40 = builtin.unrealized_conversion_cast %iter_65 : !cute.ptr<i8, gmem> to !llvm.ptr<1>
          %41 = llvm.load %39 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
          llvm.store %41, %40 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
          %42 = cute.static : !cute.int_tuple<"1">
          %ptr_66 = cute.add_offset(%iter_64, %42) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
          %43 = cute.static : !cute.int_tuple<"1">
          %ptr_67 = cute.add_offset(%iter_65, %43) : (!cute.ptr<i8, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<i8, gmem>
          %44 = builtin.unrealized_conversion_cast %ptr_66 : !cute.ptr<i8, rmem> to !llvm.ptr
          %45 = builtin.unrealized_conversion_cast %ptr_67 : !cute.ptr<i8, gmem> to !llvm.ptr<1>
          %46 = llvm.load %44 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
          llvm.store %46, %45 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
          %47 = cute.static : !cute.int_tuple<"2">
          %ptr_68 = cute.add_offset(%iter_64, %47) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem, align<2>>
          %48 = cute.static : !cute.int_tuple<"2">
          %ptr_69 = cute.add_offset(%iter_65, %48) : (!cute.ptr<i8, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<i8, gmem>
          %49 = builtin.unrealized_conversion_cast %ptr_68 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
          %50 = builtin.unrealized_conversion_cast %ptr_69 : !cute.ptr<i8, gmem> to !llvm.ptr<1>
          %51 = llvm.load %49 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
          llvm.store %51, %50 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
          %52 = cute.static : !cute.int_tuple<"3">
          %ptr_70 = cute.add_offset(%iter_64, %52) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
          %53 = cute.static : !cute.int_tuple<"3">
          %ptr_71 = cute.add_offset(%iter_65, %53) : (!cute.ptr<i8, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<i8, gmem>
          %54 = builtin.unrealized_conversion_cast %ptr_70 : !cute.ptr<i8, rmem> to !llvm.ptr
          %55 = builtin.unrealized_conversion_cast %ptr_71 : !cute.ptr<i8, gmem> to !llvm.ptr<1>
          %56 = llvm.load %54 {alignment = 1 : i64} : !llvm.ptr -> vector<1xi8>
          llvm.store %56, %55 {alignment = 1 : i64} : vector<1xi8>, !llvm.ptr<1>
        } {llvm.loop_annotation = #loop_annotation}
      }
      return
    }
  }
  func.func @cutlass__convert_Tensorgmemo1i64i64_Tensorgmemo1i64i64_0_8(%arg0: !memref_gmem_f32_6, %arg1: !memref_gmem_i4_) attributes {llvm.emit_c_interface} {
    %iter = cute.get_iter(%arg1) : !memref_gmem_i4_
    %0 = cute.static : !cute.layout<"(128,8):(8,1)">
    %1 = cute.recast_layout<8, 4> (%0) : !cute.layout<"(128,8):(8,1)"> to !cute.layout<"(128,4):(4,1)">
    %iter_0 = cute.recast_iter(%iter) : !cute.ptr<i4, gmem, align<128>> to !cute.ptr<i8, gmem, align<128>>
    %lay = cute.get_layout(%arg1) : !memref_gmem_i4_
    %2 = cute.recast_layout<8, 4> (%lay) : !cute.layout<"(?,?,?):(1,?{i64},?{i64})"> to !cute.layout<"(?,?,?):(1,?{i64},?{i64})">
    %view = cute.make_view(%iter_0, %2) : !memref_gmem_i8_6
    %lay_1 = cute.get_layout(%arg0) : !memref_gmem_f32_6
    %3 = cute.get_shape(%lay_1) : (!cute.layout<"(?,?,?):(1,?{i64},?{i64})">) -> !cute.shape<"(?,?,?)">
    %e0, %e1, %e2 = cute.get_leaves(%3) : !cute.shape<"(?,?,?)">
    %itup = cute.to_int_tuple(%e0) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %4 = cute.get_scalars(%itup) : !cute.int_tuple<"?">
    %itup_2 = cute.to_int_tuple(%e1) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %5 = cute.get_scalars(%itup_2) : !cute.int_tuple<"?">
    %itup_3 = cute.to_int_tuple(%e2) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %6 = cute.get_scalars(%itup_3) : !cute.int_tuple<"?">
    %shape = cute.make_shape(%itup, %itup_2, %itup_3) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.shape<"(?,?,?)">
    %7 = cute.static : !cute.int_tuple<"(0,0,0)">
    %8 = cute.static : !cute.stride<"(1@0,1@1,1@2)">
    %lay_4 = cute.make_layout(%shape, %8) : !cute.layout<"(?,?,?):(1@0,1@1,1@2)">
    %view_5 = cute.make_view(%7, %lay_4) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">
    %iter_6 = cute.get_iter(%arg0) : !memref_gmem_f32_6
    %lay_7 = cute.get_layout(%arg0) : !memref_gmem_f32_6
    %9:5 = cute.get_scalars(%lay_7) <{only_dynamic}> : !cute.layout<"(?,?,?):(1,?{i64},?{i64})">
    %c1024_i32 = arith.constant 1024 : i32
    %10 = arith.ceildivsi %9#0, %c1024_i32 : i32
    %shape_8 = cute.make_shape(%10, %9#1, %9#2) : (i32, i32, i32) -> !cute.shape<"((1024,1,1),(?,?,?))">
    %stride = cute.make_stride(%9#3, %9#4) : (i64, i64) -> !cute.stride<"((1,0,0),(1024,?{i64},?{i64}))">
    %lay_9 = cute.make_layout(%shape_8, %stride) : !cute.layout<"((1024,1,1),(?,?,?)):((1,0,0),(1024,?{i64},?{i64}))">
    %view_10 = cute.make_view(%iter_6, %lay_9) : !memref_gmem_f32_
    %11 = cute.static : !cute.int_tuple<"(0,0,0)">
    %lay_11 = cute.get_layout(%view_5) : !cute.coord_tensor<"(0,0,0)", "(?,?,?):(1@0,1@1,1@2)">
    %12:3 = cute.get_scalars(%lay_11) <{only_dynamic}> : !cute.layout<"(?,?,?):(1@0,1@1,1@2)">
    %c1024_i32_12 = arith.constant 1024 : i32
    %13 = arith.ceildivsi %12#0, %c1024_i32_12 : i32
    %shape_13 = cute.make_shape(%13, %12#1, %12#2) : (i32, i32, i32) -> !cute.shape<"((1024,1,1),(?,?,?))">
    %14 = cute.static : !cute.stride<"((1@0,0,0),(1024@0,1@1,1@2))">
    %lay_14 = cute.make_layout(%shape_13, %14) : !cute.layout<"((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">
    %view_15 = cute.make_view(%11, %lay_14) : !cute.coord_tensor<"(0,0,0)", "((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">
    %iter_16 = cute.get_iter(%view) : !memref_gmem_i8_6
    %lay_17 = cute.get_layout(%view) : !memref_gmem_i8_6
    %15:5 = cute.get_scalars(%lay_17) <{only_dynamic}> : !cute.layout<"(?,?,?):(1,?{i64},?{i64})">
    %c512_i32 = arith.constant 512 : i32
    %16 = arith.ceildivsi %15#0, %c512_i32 : i32
    %shape_18 = cute.make_shape(%16, %15#1, %15#2) : (i32, i32, i32) -> !cute.shape<"((512,1,1),(?,?,?))">
    %stride_19 = cute.make_stride(%15#3, %15#4) : (i64, i64) -> !cute.stride<"((1,0,0),(512,?{i64},?{i64}))">
    %lay_20 = cute.make_layout(%shape_18, %stride_19) : !cute.layout<"((512,1,1),(?,?,?)):((1,0,0),(512,?{i64},?{i64}))">
    %view_21 = cute.make_view(%iter_16, %lay_20) : !memref_gmem_i8_
    %lay_22 = cute.get_layout(%view_10) : !memref_gmem_f32_
    %sz = cute.size(%lay_22) <{mode = [1]}> : (!cute.layout<"((1024,1,1),(?,?,?)):((1,0,0),(1024,?{i64},?{i64}))">) -> !cute.int_tuple<"?">
    %e0_23 = cute.get_leaves(%sz) : !cute.int_tuple<"?">
    %17 = cute.get_scalars(%e0_23) : !cute.int_tuple<"?">
    %18 = arith.index_cast %17 : i32 to index
    %c1 = arith.constant 1 : index
    %c128 = arith.constant 128 : index
    %c0_i32 = arith.constant 0 : i32
    gpu.launch_func  @kernels::@kernel_cutlass__convert_kernel_tensorptrf32gmemo1024111001024_tensorptri8gmemalign128o51211100512_tensor000o1024111000102401112____Float32_Int4_0 blocks in (%18, %c1, %c1) threads in (%c128, %c1, %c1)  dynamic_shared_memory_size %c0_i32 args(%view_10 : !memref_gmem_f32_, %view_21 : !memref_gmem_i8_, %view_15 : !cute.coord_tensor<"(0,0,0)", "((1024,1,1),(?,?,?)):((1@0,0,0),(1024@0,1@1,1@2))">, %4 : i32, %5 : i32, %6 : i32) {use_pdl = false}
    return
  }
}
