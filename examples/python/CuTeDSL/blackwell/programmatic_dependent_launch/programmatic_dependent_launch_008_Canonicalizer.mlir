!copy_simt = !cute.tiled_copy<!cute_nvgpu.atom.universal_copy<f32>, layout_copy_tv = <"((32,4),(4,4)):((64,4),(16,1))">, tiler_mn = <"[16:1;128:1]">>
!memref_gmem_f32_ = !cute.memref<f32, gmem, "((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
!memref_gmem_f32_1 = !cute.memref<f32, gmem, "(?,?):(?{i64},1)">
!memref_rmem_f32_ = !cute.memref<f32, rmem, align<32>, "((1,(4,4)),1,1):((0,(1,4)),0,0)">
!memref_rmem_i8_ = !cute.memref<i8, rmem, align<32>, "((1,(4,4)),1,1):((0,(1,4)),0,0)">
#loop_unroll = #llvm.loop_unroll<disable = false, full = true>
#loop_annotation = #llvm.loop_annotation<unroll = #loop_unroll>
module attributes {gpu.container_module} {
  gpu.module @kernels {
    cuda.kernel @kernel_cutlass_elementwise_add_kernel_tensorptrf32gmemo161281i64div16128_tensorptrf32gmemo161281i64div16128_tensorptrf32gmemo161281i64div16128_tensor00o1612810111601281___False_0(%arg0: !memref_gmem_f32_, %arg1: !memref_gmem_f32_, %arg2: !memref_gmem_f32_, %arg3: !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">, %arg4: i32, %arg5: i32) attributes {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} {
      %0 = cute.static : !cute.int_tuple<"15">
      %1 = cute.static : !cute.int_tuple<"14">
      %2 = cute.static : !cute.int_tuple<"13">
      %3 = cute.static : !cute.int_tuple<"12">
      %4 = cute.static : !cute.int_tuple<"11">
      %5 = cute.static : !cute.int_tuple<"10">
      %6 = cute.static : !cute.int_tuple<"9">
      %7 = cute.static : !cute.int_tuple<"8">
      %c3_i64 = arith.constant 3 : i64
      %8 = cute.static : !cute.int_tuple<"7">
      %c2_i64 = arith.constant 2 : i64
      %9 = cute.static : !cute.int_tuple<"6">
      %c1_i64 = arith.constant 1 : i64
      %10 = cute.static : !cute.int_tuple<"5">
      %11 = cute.static : !cute.int_tuple<"4">
      %12 = cute.static : !cute.int_tuple<"3">
      %13 = cute.static : !cute.int_tuple<"2">
      %14 = llvm.mlir.constant(0 : i8) : i8
      %15 = cute.static : !cute.shape<"((1,(4,4)))">
      %16 = cute.static : !cute.int_tuple<"1">
      %17 = cute.static : !cute.shape<"((1,(4,4)),((1,1)))">
      %18 = cute.static : !cute.shape<"((1,(4,4)),(1,1))">
      %19 = cute.static : !cute.layout<"1:0">
      %c10_i32 = arith.constant 10 : i32
      %20 = cute.static : !cute.layout<"((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">
      %c1_i32 = arith.constant 1 : i32
      %c16_i32 = arith.constant 16 : i32
      %c0_i32 = arith.constant 0 : i32
      %21 = cute.static : !cute.shape<"((1,(4,4)),1,1)">
      %c4_i32 = arith.constant 4 : i32
      %c32_i32 = arith.constant 32 : i32
      %c4_i64 = arith.constant 4 : i64
      %22 = cute.static : !cute.int_tuple<"(0,0)">
      %23 = cute.static : !cute.shape<"(16,128)">
      %24 = nvvm.read.ptx.sreg.tid.x range <i32, 0, 1024> : i32
      %25 = nvvm.read.ptx.sreg.ctaid.x range <i32, 0, 2147483647> : i32
      %coord = cute.make_coord(%25) : (i32) -> !cute.coord<"((_,_),?)">
      %lay = cute.get_layout(%arg0) : !memref_gmem_f32_
      %26:4 = cute.get_scalars(%lay) <{only_dynamic}> : !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
      %stride = cute.make_stride(%26#2) : (i64) -> !cute.stride<"(?{i64},1)">
      %lay_0 = cute.make_layout(%23, %stride) : !cute.layout<"(16,128):(?{i64},1)">
      %idx = cute.crd2idx(%coord, %lay) : (!cute.coord<"((_,_),?)">, !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.int_tuple<"?{i64 div=16}">
      %iter = cute.get_iter(%arg0) : !memref_gmem_f32_
      %ptr = cute.add_offset(%iter, %idx) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=16}">) -> !cute.ptr<f32, gmem>
      %coord_1 = cute.make_coord(%25) : (i32) -> !cute.coord<"((_,_),?)">
      %lay_2 = cute.get_layout(%arg1) : !memref_gmem_f32_
      %27:4 = cute.get_scalars(%lay_2) <{only_dynamic}> : !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
      %stride_3 = cute.make_stride(%27#2) : (i64) -> !cute.stride<"(?{i64},1)">
      %lay_4 = cute.make_layout(%23, %stride_3) : !cute.layout<"(16,128):(?{i64},1)">
      %idx_5 = cute.crd2idx(%coord_1, %lay_2) : (!cute.coord<"((_,_),?)">, !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.int_tuple<"?{i64 div=16}">
      %iter_6 = cute.get_iter(%arg1) : !memref_gmem_f32_
      %ptr_7 = cute.add_offset(%iter_6, %idx_5) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=16}">) -> !cute.ptr<f32, gmem>
      %coord_8 = cute.make_coord(%25) : (i32) -> !cute.coord<"((_,_),?)">
      %lay_9 = cute.get_layout(%arg2) : !memref_gmem_f32_
      %28:4 = cute.get_scalars(%lay_9) <{only_dynamic}> : !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
      %stride_10 = cute.make_stride(%28#2) : (i64) -> !cute.stride<"(?{i64},1)">
      %lay_11 = cute.make_layout(%23, %stride_10) : !cute.layout<"(16,128):(?{i64},1)">
      %idx_12 = cute.crd2idx(%coord_8, %lay_9) : (!cute.coord<"((_,_),?)">, !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.int_tuple<"?{i64 div=16}">
      %iter_13 = cute.get_iter(%arg2) : !memref_gmem_f32_
      %ptr_14 = cute.add_offset(%iter_13, %idx_12) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=16}">) -> !cute.ptr<f32, gmem>
      %coord_15 = cute.make_coord(%25) : (i32) -> !cute.coord<"((_,_),?)">
      %lay_16 = cute.get_layout(%arg3) : !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
      %idx_17 = cute.crd2idx(%coord_15, %lay_16) : (!cute.coord<"((_,_),?)">, !cute.layout<"((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">) -> !cute.int_tuple<"(?{div=16},?{div=128})">
      %tup = cute.add_offset(%22, %idx_17) : (!cute.int_tuple<"(0,0)">, !cute.int_tuple<"(?{div=16},?{div=128})">) -> !cute.int_tuple<"(?{div=16},?{div=128})">
      %atom = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<f32>
      %atom_18 = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<f32>
      %29 = cute.make_tiled_copy(%atom) : !copy_simt
      %30 = cute.make_tiled_copy(%atom) : !copy_simt
      %31 = cute.make_tiled_copy(%atom_18) : !copy_simt
      %coord_19 = cute.make_coord(%24) : (i32) -> !cute.coord<"?">
      %32 = cute.get_scalars(%lay_0) <{only_dynamic}> : !cute.layout<"(16,128):(?{i64},1)">
      %33 = cute.get_scalars(%coord_19) <{only_dynamic}> : !cute.coord<"?">
      %34 = arith.muli %32, %c4_i64 : i64
      %35 = arith.divsi %33, %c32_i32 : i32
      %36 = arith.remsi %33, %c32_i32 : i32
      %37 = arith.muli %36, %c4_i32 : i32
      %38 = arith.extsi %35 : i32 to i64
      %39 = arith.muli %38, %34 : i64
      %40 = arith.extsi %37 : i32 to i64
      %41 = arith.addi %40, %39 : i64
      %iv = cute.assume(%41) : (i64) -> !cute.i64<divby 4>
      %int_tuple = cute.make_int_tuple(%iv) : (!cute.i64<divby 4>) -> !cute.int_tuple<"?{i64 div=4}">
      %ptr_20 = cute.add_offset(%ptr, %int_tuple) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=4}">) -> !cute.ptr<f32, gmem>
      %stride_21 = cute.make_stride(%32) : (i64) -> !cute.stride<"((0,(1,?{i64})),0,0)">
      %lay_22 = cute.make_layout(%21, %stride_21) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %coord_23 = cute.make_coord(%24) : (i32) -> !cute.coord<"?">
      %42 = cute.get_scalars(%lay_4) <{only_dynamic}> : !cute.layout<"(16,128):(?{i64},1)">
      %43 = cute.get_scalars(%coord_23) <{only_dynamic}> : !cute.coord<"?">
      %44 = arith.muli %42, %c4_i64 : i64
      %45 = arith.divsi %43, %c32_i32 : i32
      %46 = arith.remsi %43, %c32_i32 : i32
      %47 = arith.muli %46, %c4_i32 : i32
      %48 = arith.extsi %45 : i32 to i64
      %49 = arith.muli %48, %44 : i64
      %50 = arith.extsi %47 : i32 to i64
      %51 = arith.addi %50, %49 : i64
      %iv_24 = cute.assume(%51) : (i64) -> !cute.i64<divby 4>
      %int_tuple_25 = cute.make_int_tuple(%iv_24) : (!cute.i64<divby 4>) -> !cute.int_tuple<"?{i64 div=4}">
      %ptr_26 = cute.add_offset(%ptr_7, %int_tuple_25) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=4}">) -> !cute.ptr<f32, gmem>
      %stride_27 = cute.make_stride(%42) : (i64) -> !cute.stride<"((0,(1,?{i64})),0,0)">
      %lay_28 = cute.make_layout(%21, %stride_27) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %coord_29 = cute.make_coord(%24) : (i32) -> !cute.coord<"?">
      %52 = cute.get_scalars(%lay_11) <{only_dynamic}> : !cute.layout<"(16,128):(?{i64},1)">
      %53 = cute.get_scalars(%coord_29) <{only_dynamic}> : !cute.coord<"?">
      %54 = arith.muli %52, %c4_i64 : i64
      %55 = arith.divsi %53, %c32_i32 : i32
      %56 = arith.remsi %53, %c32_i32 : i32
      %57 = arith.muli %56, %c4_i32 : i32
      %58 = arith.extsi %55 : i32 to i64
      %59 = arith.muli %58, %54 : i64
      %60 = arith.extsi %57 : i32 to i64
      %61 = arith.addi %60, %59 : i64
      %iv_30 = cute.assume(%61) : (i64) -> !cute.i64<divby 4>
      %int_tuple_31 = cute.make_int_tuple(%iv_30) : (!cute.i64<divby 4>) -> !cute.int_tuple<"?{i64 div=4}">
      %ptr_32 = cute.add_offset(%ptr_14, %int_tuple_31) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=4}">) -> !cute.ptr<f32, gmem>
      %stride_33 = cute.make_stride(%52) : (i64) -> !cute.stride<"((0,(1,?{i64})),0,0)">
      %lay_34 = cute.make_layout(%21, %stride_33) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %rmem = cute.memref.alloca() : !memref_rmem_f32_
      %iter_35 = cute.get_iter(%rmem) : !memref_rmem_f32_
      %rmem_36 = cute.memref.alloca() : !memref_rmem_f32_
      %iter_37 = cute.get_iter(%rmem_36) : !memref_rmem_f32_
      %rmem_38 = cute.memref.alloca() : !memref_rmem_f32_
      %coord_39 = cute.make_coord(%24) : (i32) -> !cute.coord<"?">
      %62 = cute.get_scalars(%coord_39) <{only_dynamic}> : !cute.coord<"?">
      %63 = arith.divsi %62, %c32_i32 : i32
      %64 = arith.remsi %62, %c32_i32 : i32
      %65 = arith.muli %64, %c4_i32 : i32
      %66 = arith.muli %63, %c4_i32 : i32
      %iv_40 = cute.assume(%66) : (i32) -> !cute.i32<divby 4>
      %iv_41 = cute.assume(%65) : (i32) -> !cute.i32<divby 4>
      %int_tuple_42 = cute.make_int_tuple(%iv_40, %iv_41) : (!cute.i32<divby 4>, !cute.i32<divby 4>) -> !cute.int_tuple<"(?{div=4},?{div=4})">
      %tup_43 = cute.add_offset(%tup, %int_tuple_42) : (!cute.int_tuple<"(?{div=16},?{div=128})">, !cute.int_tuple<"(?{div=4},?{div=4})">) -> !cute.int_tuple<"(?{div=4},?{div=4})">
      %rmem_44 = cute.memref.alloca() : !memref_rmem_i8_
      scf.for %arg6 = %c0_i32 to %c16_i32 step %c1_i32  : i32 {
        %coord_52 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"?">
        %idx_53 = cute.crd2idx(%coord_52, %20) : (!cute.coord<"?">, !cute.layout<"((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">) -> !cute.int_tuple<"(?,?)">
        %tup_54 = cute.add_offset(%tup_43, %idx_53) : (!cute.int_tuple<"(?{div=4},?{div=4})">, !cute.int_tuple<"(?,?)">) -> !cute.int_tuple<"(?,?)">
        %e0, %e1 = cute.get_leaves(%tup_54) : !cute.int_tuple<"(?,?)">
        %coord_55 = cute.make_coord(%e0, %e1) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
        %coord_56 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
        %70:2 = cute.get_scalars(%coord_55) : !cute.coord<"(?,?)">
        %71:2 = cute.get_scalars(%coord_56) : !cute.coord<"(?,?)">
        %72 = arith.cmpi slt, %70#0, %71#0 : i32
        %73 = arith.cmpi slt, %70#1, %71#1 : i32
        %74 = arith.andi %72, %73 : i1
        %75 = arith.extui %74 : i1 to i8
        %coord_57 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"?">
        cute.memref.store(%rmem_44, %coord_57, %75) : (!memref_rmem_i8_, !cute.coord<"?">, i8) -> ()
      }
      %iter_45 = cute.get_iter(%rmem_44) : !memref_rmem_i8_
      scf.for %arg6 = %c0_i32 to %c10_i32 step %c1_i32  : i32 {
        %append_52 = cute.append_to_rank<2> (%lay_28, %19) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">
        %70 = cute.get_scalars(%append_52) <{only_dynamic}> : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
        %stride_53 = cute.make_stride(%70) : (i64) -> !cute.stride<"((0,(1,?{i64})),(0,0))">
        %lay_54 = cute.make_layout(%18, %stride_53) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
        %append_55 = cute.append_to_rank<2> (%lay_54, %19) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">, !cute.layout<"1:0">
        %71 = cute.get_scalars(%append_55) <{only_dynamic}> : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
        %stride_56 = cute.make_stride(%71) : (i64) -> !cute.stride<"((0,(1,?{i64})),((0,0)))">
        %lay_57 = cute.make_layout(%17, %stride_56) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
        %72 = cute.get_scalars(%16) : !cute.int_tuple<"1">
        scf.for %arg7 = %c0_i32 to %72 step %c1_i32  : i32 {
          %73 = cute.get_scalars(%lay_57) <{only_dynamic}> : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
          %stride_58 = cute.make_stride(%73) : (i64) -> !cute.stride<"((0,(1,?{i64})))">
          %lay_59 = cute.make_layout(%15, %stride_58) : !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
          %74 = cute.get_scalars(%lay_59) <{only_dynamic}> : !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
          %75 = builtin.unrealized_conversion_cast %iter_45 : !cute.ptr<i8, rmem, align<32>> to !llvm.ptr
          %76 = llvm.load %75 : !llvm.ptr -> i8
          %77 = llvm.icmp "ne" %76, %14 : i8
          scf.if %77 {
            %123 = builtin.unrealized_conversion_cast %ptr_26 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
            %124 = builtin.unrealized_conversion_cast %iter_37 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
            %125 = llvm.load %123 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
            llvm.store %125, %124 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          }
          %ptr_60 = cute.add_offset(%iter_45, %16) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
          %78 = builtin.unrealized_conversion_cast %ptr_60 : !cute.ptr<i8, rmem> to !llvm.ptr
          %79 = llvm.load %78 : !llvm.ptr -> i8
          %80 = llvm.icmp "ne" %79, %14 : i8
          scf.if %80 {
            %ptr_75 = cute.add_offset(%ptr_26, %16) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
            %ptr_76 = cute.add_offset(%iter_37, %16) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
            %123 = builtin.unrealized_conversion_cast %ptr_75 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
            %124 = builtin.unrealized_conversion_cast %ptr_76 : !cute.ptr<f32, rmem> to !llvm.ptr
            %125 = llvm.load %123 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
            llvm.store %125, %124 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          }
          %ptr_61 = cute.add_offset(%iter_45, %13) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem, align<2>>
          %81 = builtin.unrealized_conversion_cast %ptr_61 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
          %82 = llvm.load %81 : !llvm.ptr -> i8
          %83 = llvm.icmp "ne" %82, %14 : i8
          scf.if %83 {
            %ptr_75 = cute.add_offset(%ptr_26, %13) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
            %ptr_76 = cute.add_offset(%iter_37, %13) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
            %123 = builtin.unrealized_conversion_cast %ptr_75 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
            %124 = builtin.unrealized_conversion_cast %ptr_76 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
            %125 = llvm.load %123 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
            llvm.store %125, %124 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          }
          %ptr_62 = cute.add_offset(%iter_45, %12) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
          %84 = builtin.unrealized_conversion_cast %ptr_62 : !cute.ptr<i8, rmem> to !llvm.ptr
          %85 = llvm.load %84 : !llvm.ptr -> i8
          %86 = llvm.icmp "ne" %85, %14 : i8
          scf.if %86 {
            %ptr_75 = cute.add_offset(%ptr_26, %12) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
            %ptr_76 = cute.add_offset(%iter_37, %12) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
            %123 = builtin.unrealized_conversion_cast %ptr_75 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
            %124 = builtin.unrealized_conversion_cast %ptr_76 : !cute.ptr<f32, rmem> to !llvm.ptr
            %125 = llvm.load %123 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
            llvm.store %125, %124 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          }
          %ptr_63 = cute.add_offset(%iter_45, %11) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem, align<4>>
          %87 = builtin.unrealized_conversion_cast %ptr_63 : !cute.ptr<i8, rmem, align<4>> to !llvm.ptr
          %88 = llvm.load %87 : !llvm.ptr -> i8
          %89 = llvm.icmp "ne" %88, %14 : i8
          scf.if %89 {
            %int_tuple_75 = cute.make_int_tuple(%74) : (i64) -> !cute.int_tuple<"?{i64}">
            %ptr_76 = cute.add_offset(%ptr_26, %int_tuple_75) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
            %ptr_77 = cute.add_offset(%iter_37, %11) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
            %123 = builtin.unrealized_conversion_cast %ptr_76 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
            %124 = builtin.unrealized_conversion_cast %ptr_77 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
            %125 = llvm.load %123 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
            llvm.store %125, %124 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          }
          %ptr_64 = cute.add_offset(%iter_45, %10) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
          %90 = builtin.unrealized_conversion_cast %ptr_64 : !cute.ptr<i8, rmem> to !llvm.ptr
          %91 = llvm.load %90 : !llvm.ptr -> i8
          %92 = llvm.icmp "ne" %91, %14 : i8
          scf.if %92 {
            %123 = arith.addi %74, %c1_i64 : i64
            %int_tuple_75 = cute.make_int_tuple(%123) : (i64) -> !cute.int_tuple<"?{i64}">
            %ptr_76 = cute.add_offset(%ptr_26, %int_tuple_75) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
            %ptr_77 = cute.add_offset(%iter_37, %10) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<f32, rmem>
            %124 = builtin.unrealized_conversion_cast %ptr_76 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
            %125 = builtin.unrealized_conversion_cast %ptr_77 : !cute.ptr<f32, rmem> to !llvm.ptr
            %126 = llvm.load %124 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
            llvm.store %126, %125 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          }
          %ptr_65 = cute.add_offset(%iter_45, %9) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem, align<2>>
          %93 = builtin.unrealized_conversion_cast %ptr_65 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
          %94 = llvm.load %93 : !llvm.ptr -> i8
          %95 = llvm.icmp "ne" %94, %14 : i8
          scf.if %95 {
            %123 = arith.addi %74, %c2_i64 : i64
            %int_tuple_75 = cute.make_int_tuple(%123) : (i64) -> !cute.int_tuple<"?{i64}">
            %ptr_76 = cute.add_offset(%ptr_26, %int_tuple_75) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
            %ptr_77 = cute.add_offset(%iter_37, %9) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
            %124 = builtin.unrealized_conversion_cast %ptr_76 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
            %125 = builtin.unrealized_conversion_cast %ptr_77 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
            %126 = llvm.load %124 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
            llvm.store %126, %125 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          }
          %ptr_66 = cute.add_offset(%iter_45, %8) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
          %96 = builtin.unrealized_conversion_cast %ptr_66 : !cute.ptr<i8, rmem> to !llvm.ptr
          %97 = llvm.load %96 : !llvm.ptr -> i8
          %98 = llvm.icmp "ne" %97, %14 : i8
          scf.if %98 {
            %123 = arith.addi %74, %c3_i64 : i64
            %int_tuple_75 = cute.make_int_tuple(%123) : (i64) -> !cute.int_tuple<"?{i64}">
            %ptr_76 = cute.add_offset(%ptr_26, %int_tuple_75) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
            %ptr_77 = cute.add_offset(%iter_37, %8) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<f32, rmem>
            %124 = builtin.unrealized_conversion_cast %ptr_76 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
            %125 = builtin.unrealized_conversion_cast %ptr_77 : !cute.ptr<f32, rmem> to !llvm.ptr
            %126 = llvm.load %124 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
            llvm.store %126, %125 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          }
          %ptr_67 = cute.add_offset(%iter_45, %7) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<i8, rmem, align<8>>
          %99 = builtin.unrealized_conversion_cast %ptr_67 : !cute.ptr<i8, rmem, align<8>> to !llvm.ptr
          %100 = llvm.load %99 : !llvm.ptr -> i8
          %101 = llvm.icmp "ne" %100, %14 : i8
          scf.if %101 {
            %123 = arith.muli %74, %c2_i64 : i64
            %iv_75 = cute.assume(%123) : (i64) -> !cute.i64<divby 2>
            %int_tuple_76 = cute.make_int_tuple(%iv_75) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
            %ptr_77 = cute.add_offset(%ptr_26, %int_tuple_76) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
            %ptr_78 = cute.add_offset(%iter_37, %7) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<f32, rmem, align<32>>
            %124 = builtin.unrealized_conversion_cast %ptr_77 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
            %125 = builtin.unrealized_conversion_cast %ptr_78 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
            %126 = llvm.load %124 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
            llvm.store %126, %125 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          }
          %ptr_68 = cute.add_offset(%iter_45, %6) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<i8, rmem>
          %102 = builtin.unrealized_conversion_cast %ptr_68 : !cute.ptr<i8, rmem> to !llvm.ptr
          %103 = llvm.load %102 : !llvm.ptr -> i8
          %104 = llvm.icmp "ne" %103, %14 : i8
          scf.if %104 {
            %123 = arith.muli %74, %c2_i64 : i64
            %124 = arith.addi %123, %c1_i64 : i64
            %int_tuple_75 = cute.make_int_tuple(%124) : (i64) -> !cute.int_tuple<"?{i64}">
            %ptr_76 = cute.add_offset(%ptr_26, %int_tuple_75) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
            %ptr_77 = cute.add_offset(%iter_37, %6) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<f32, rmem>
            %125 = builtin.unrealized_conversion_cast %ptr_76 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
            %126 = builtin.unrealized_conversion_cast %ptr_77 : !cute.ptr<f32, rmem> to !llvm.ptr
            %127 = llvm.load %125 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
            llvm.store %127, %126 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          }
          %ptr_69 = cute.add_offset(%iter_45, %5) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<i8, rmem, align<2>>
          %105 = builtin.unrealized_conversion_cast %ptr_69 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
          %106 = llvm.load %105 : !llvm.ptr -> i8
          %107 = llvm.icmp "ne" %106, %14 : i8
          scf.if %107 {
            %123 = arith.muli %74, %c2_i64 : i64
            %124 = arith.addi %123, %c2_i64 : i64
            %iv_75 = cute.assume(%124) : (i64) -> !cute.i64<divby 2>
            %int_tuple_76 = cute.make_int_tuple(%iv_75) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
            %ptr_77 = cute.add_offset(%ptr_26, %int_tuple_76) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
            %ptr_78 = cute.add_offset(%iter_37, %5) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<f32, rmem, align<8>>
            %125 = builtin.unrealized_conversion_cast %ptr_77 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
            %126 = builtin.unrealized_conversion_cast %ptr_78 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
            %127 = llvm.load %125 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
            llvm.store %127, %126 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          }
          %ptr_70 = cute.add_offset(%iter_45, %4) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<i8, rmem>
          %108 = builtin.unrealized_conversion_cast %ptr_70 : !cute.ptr<i8, rmem> to !llvm.ptr
          %109 = llvm.load %108 : !llvm.ptr -> i8
          %110 = llvm.icmp "ne" %109, %14 : i8
          scf.if %110 {
            %123 = arith.muli %74, %c2_i64 : i64
            %124 = arith.addi %123, %c3_i64 : i64
            %int_tuple_75 = cute.make_int_tuple(%124) : (i64) -> !cute.int_tuple<"?{i64}">
            %ptr_76 = cute.add_offset(%ptr_26, %int_tuple_75) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
            %ptr_77 = cute.add_offset(%iter_37, %4) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<f32, rmem>
            %125 = builtin.unrealized_conversion_cast %ptr_76 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
            %126 = builtin.unrealized_conversion_cast %ptr_77 : !cute.ptr<f32, rmem> to !llvm.ptr
            %127 = llvm.load %125 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
            llvm.store %127, %126 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          }
          %ptr_71 = cute.add_offset(%iter_45, %3) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<i8, rmem, align<4>>
          %111 = builtin.unrealized_conversion_cast %ptr_71 : !cute.ptr<i8, rmem, align<4>> to !llvm.ptr
          %112 = llvm.load %111 : !llvm.ptr -> i8
          %113 = llvm.icmp "ne" %112, %14 : i8
          scf.if %113 {
            %123 = arith.muli %74, %c3_i64 : i64
            %iv_75 = cute.assume(%123) : (i64) -> !cute.i64<divby 3>
            %int_tuple_76 = cute.make_int_tuple(%iv_75) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
            %ptr_77 = cute.add_offset(%ptr_26, %int_tuple_76) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
            %ptr_78 = cute.add_offset(%iter_37, %3) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<f32, rmem, align<16>>
            %124 = builtin.unrealized_conversion_cast %ptr_77 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
            %125 = builtin.unrealized_conversion_cast %ptr_78 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
            %126 = llvm.load %124 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
            llvm.store %126, %125 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          }
          %ptr_72 = cute.add_offset(%iter_45, %2) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<i8, rmem>
          %114 = builtin.unrealized_conversion_cast %ptr_72 : !cute.ptr<i8, rmem> to !llvm.ptr
          %115 = llvm.load %114 : !llvm.ptr -> i8
          %116 = llvm.icmp "ne" %115, %14 : i8
          scf.if %116 {
            %123 = arith.muli %74, %c3_i64 : i64
            %124 = arith.addi %123, %c1_i64 : i64
            %int_tuple_75 = cute.make_int_tuple(%124) : (i64) -> !cute.int_tuple<"?{i64}">
            %ptr_76 = cute.add_offset(%ptr_26, %int_tuple_75) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
            %ptr_77 = cute.add_offset(%iter_37, %2) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<f32, rmem>
            %125 = builtin.unrealized_conversion_cast %ptr_76 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
            %126 = builtin.unrealized_conversion_cast %ptr_77 : !cute.ptr<f32, rmem> to !llvm.ptr
            %127 = llvm.load %125 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
            llvm.store %127, %126 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          }
          %ptr_73 = cute.add_offset(%iter_45, %1) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<i8, rmem, align<2>>
          %117 = builtin.unrealized_conversion_cast %ptr_73 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
          %118 = llvm.load %117 : !llvm.ptr -> i8
          %119 = llvm.icmp "ne" %118, %14 : i8
          scf.if %119 {
            %123 = arith.muli %74, %c3_i64 : i64
            %124 = arith.addi %123, %c2_i64 : i64
            %int_tuple_75 = cute.make_int_tuple(%124) : (i64) -> !cute.int_tuple<"?{i64}">
            %ptr_76 = cute.add_offset(%ptr_26, %int_tuple_75) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
            %ptr_77 = cute.add_offset(%iter_37, %1) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<f32, rmem, align<8>>
            %125 = builtin.unrealized_conversion_cast %ptr_76 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
            %126 = builtin.unrealized_conversion_cast %ptr_77 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
            %127 = llvm.load %125 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
            llvm.store %127, %126 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          }
          %ptr_74 = cute.add_offset(%iter_45, %0) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<i8, rmem>
          %120 = builtin.unrealized_conversion_cast %ptr_74 : !cute.ptr<i8, rmem> to !llvm.ptr
          %121 = llvm.load %120 : !llvm.ptr -> i8
          %122 = llvm.icmp "ne" %121, %14 : i8
          scf.if %122 {
            %123 = arith.muli %74, %c3_i64 : i64
            %124 = arith.addi %123, %c3_i64 : i64
            %iv_75 = cute.assume(%124) : (i64) -> !cute.i64<divby 3>
            %int_tuple_76 = cute.make_int_tuple(%iv_75) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
            %ptr_77 = cute.add_offset(%ptr_26, %int_tuple_76) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
            %ptr_78 = cute.add_offset(%iter_37, %0) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<f32, rmem>
            %125 = builtin.unrealized_conversion_cast %ptr_77 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
            %126 = builtin.unrealized_conversion_cast %ptr_78 : !cute.ptr<f32, rmem> to !llvm.ptr
            %127 = llvm.load %125 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
            llvm.store %127, %126 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          }
        } {llvm.loop_annotation = #loop_annotation}
      }
      llvm.inline_asm has_side_effects asm_dialect = att "griddepcontrol.wait;", ""  : () -> ()
      scf.for %arg6 = %c0_i32 to %c10_i32 step %c1_i32  : i32 {
        %append_52 = cute.append_to_rank<2> (%lay_22, %19) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">
        %70 = cute.get_scalars(%append_52) <{only_dynamic}> : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
        %stride_53 = cute.make_stride(%70) : (i64) -> !cute.stride<"((0,(1,?{i64})),(0,0))">
        %lay_54 = cute.make_layout(%18, %stride_53) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
        %append_55 = cute.append_to_rank<2> (%lay_54, %19) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">, !cute.layout<"1:0">
        %71 = cute.get_scalars(%append_55) <{only_dynamic}> : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
        %stride_56 = cute.make_stride(%71) : (i64) -> !cute.stride<"((0,(1,?{i64})),((0,0)))">
        %lay_57 = cute.make_layout(%17, %stride_56) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
        %72 = cute.get_scalars(%16) : !cute.int_tuple<"1">
        scf.for %arg7 = %c0_i32 to %72 step %c1_i32  : i32 {
          %73 = cute.get_scalars(%lay_57) <{only_dynamic}> : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
          %stride_58 = cute.make_stride(%73) : (i64) -> !cute.stride<"((0,(1,?{i64})))">
          %lay_59 = cute.make_layout(%15, %stride_58) : !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
          %74 = cute.get_scalars(%lay_59) <{only_dynamic}> : !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
          %75 = builtin.unrealized_conversion_cast %iter_45 : !cute.ptr<i8, rmem, align<32>> to !llvm.ptr
          %76 = llvm.load %75 : !llvm.ptr -> i8
          %77 = llvm.icmp "ne" %76, %14 : i8
          scf.if %77 {
            %123 = builtin.unrealized_conversion_cast %ptr_20 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
            %124 = builtin.unrealized_conversion_cast %iter_35 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
            %125 = llvm.load %123 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
            llvm.store %125, %124 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          }
          %ptr_60 = cute.add_offset(%iter_45, %16) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
          %78 = builtin.unrealized_conversion_cast %ptr_60 : !cute.ptr<i8, rmem> to !llvm.ptr
          %79 = llvm.load %78 : !llvm.ptr -> i8
          %80 = llvm.icmp "ne" %79, %14 : i8
          scf.if %80 {
            %ptr_75 = cute.add_offset(%ptr_20, %16) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
            %ptr_76 = cute.add_offset(%iter_35, %16) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
            %123 = builtin.unrealized_conversion_cast %ptr_75 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
            %124 = builtin.unrealized_conversion_cast %ptr_76 : !cute.ptr<f32, rmem> to !llvm.ptr
            %125 = llvm.load %123 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
            llvm.store %125, %124 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          }
          %ptr_61 = cute.add_offset(%iter_45, %13) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem, align<2>>
          %81 = builtin.unrealized_conversion_cast %ptr_61 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
          %82 = llvm.load %81 : !llvm.ptr -> i8
          %83 = llvm.icmp "ne" %82, %14 : i8
          scf.if %83 {
            %ptr_75 = cute.add_offset(%ptr_20, %13) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
            %ptr_76 = cute.add_offset(%iter_35, %13) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
            %123 = builtin.unrealized_conversion_cast %ptr_75 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
            %124 = builtin.unrealized_conversion_cast %ptr_76 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
            %125 = llvm.load %123 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
            llvm.store %125, %124 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          }
          %ptr_62 = cute.add_offset(%iter_45, %12) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
          %84 = builtin.unrealized_conversion_cast %ptr_62 : !cute.ptr<i8, rmem> to !llvm.ptr
          %85 = llvm.load %84 : !llvm.ptr -> i8
          %86 = llvm.icmp "ne" %85, %14 : i8
          scf.if %86 {
            %ptr_75 = cute.add_offset(%ptr_20, %12) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
            %ptr_76 = cute.add_offset(%iter_35, %12) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
            %123 = builtin.unrealized_conversion_cast %ptr_75 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
            %124 = builtin.unrealized_conversion_cast %ptr_76 : !cute.ptr<f32, rmem> to !llvm.ptr
            %125 = llvm.load %123 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
            llvm.store %125, %124 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          }
          %ptr_63 = cute.add_offset(%iter_45, %11) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem, align<4>>
          %87 = builtin.unrealized_conversion_cast %ptr_63 : !cute.ptr<i8, rmem, align<4>> to !llvm.ptr
          %88 = llvm.load %87 : !llvm.ptr -> i8
          %89 = llvm.icmp "ne" %88, %14 : i8
          scf.if %89 {
            %int_tuple_75 = cute.make_int_tuple(%74) : (i64) -> !cute.int_tuple<"?{i64}">
            %ptr_76 = cute.add_offset(%ptr_20, %int_tuple_75) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
            %ptr_77 = cute.add_offset(%iter_35, %11) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
            %123 = builtin.unrealized_conversion_cast %ptr_76 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
            %124 = builtin.unrealized_conversion_cast %ptr_77 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
            %125 = llvm.load %123 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
            llvm.store %125, %124 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          }
          %ptr_64 = cute.add_offset(%iter_45, %10) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
          %90 = builtin.unrealized_conversion_cast %ptr_64 : !cute.ptr<i8, rmem> to !llvm.ptr
          %91 = llvm.load %90 : !llvm.ptr -> i8
          %92 = llvm.icmp "ne" %91, %14 : i8
          scf.if %92 {
            %123 = arith.addi %74, %c1_i64 : i64
            %int_tuple_75 = cute.make_int_tuple(%123) : (i64) -> !cute.int_tuple<"?{i64}">
            %ptr_76 = cute.add_offset(%ptr_20, %int_tuple_75) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
            %ptr_77 = cute.add_offset(%iter_35, %10) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<f32, rmem>
            %124 = builtin.unrealized_conversion_cast %ptr_76 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
            %125 = builtin.unrealized_conversion_cast %ptr_77 : !cute.ptr<f32, rmem> to !llvm.ptr
            %126 = llvm.load %124 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
            llvm.store %126, %125 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          }
          %ptr_65 = cute.add_offset(%iter_45, %9) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem, align<2>>
          %93 = builtin.unrealized_conversion_cast %ptr_65 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
          %94 = llvm.load %93 : !llvm.ptr -> i8
          %95 = llvm.icmp "ne" %94, %14 : i8
          scf.if %95 {
            %123 = arith.addi %74, %c2_i64 : i64
            %int_tuple_75 = cute.make_int_tuple(%123) : (i64) -> !cute.int_tuple<"?{i64}">
            %ptr_76 = cute.add_offset(%ptr_20, %int_tuple_75) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
            %ptr_77 = cute.add_offset(%iter_35, %9) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
            %124 = builtin.unrealized_conversion_cast %ptr_76 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
            %125 = builtin.unrealized_conversion_cast %ptr_77 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
            %126 = llvm.load %124 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
            llvm.store %126, %125 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          }
          %ptr_66 = cute.add_offset(%iter_45, %8) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
          %96 = builtin.unrealized_conversion_cast %ptr_66 : !cute.ptr<i8, rmem> to !llvm.ptr
          %97 = llvm.load %96 : !llvm.ptr -> i8
          %98 = llvm.icmp "ne" %97, %14 : i8
          scf.if %98 {
            %123 = arith.addi %74, %c3_i64 : i64
            %int_tuple_75 = cute.make_int_tuple(%123) : (i64) -> !cute.int_tuple<"?{i64}">
            %ptr_76 = cute.add_offset(%ptr_20, %int_tuple_75) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
            %ptr_77 = cute.add_offset(%iter_35, %8) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<f32, rmem>
            %124 = builtin.unrealized_conversion_cast %ptr_76 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
            %125 = builtin.unrealized_conversion_cast %ptr_77 : !cute.ptr<f32, rmem> to !llvm.ptr
            %126 = llvm.load %124 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
            llvm.store %126, %125 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          }
          %ptr_67 = cute.add_offset(%iter_45, %7) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<i8, rmem, align<8>>
          %99 = builtin.unrealized_conversion_cast %ptr_67 : !cute.ptr<i8, rmem, align<8>> to !llvm.ptr
          %100 = llvm.load %99 : !llvm.ptr -> i8
          %101 = llvm.icmp "ne" %100, %14 : i8
          scf.if %101 {
            %123 = arith.muli %74, %c2_i64 : i64
            %iv_75 = cute.assume(%123) : (i64) -> !cute.i64<divby 2>
            %int_tuple_76 = cute.make_int_tuple(%iv_75) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
            %ptr_77 = cute.add_offset(%ptr_20, %int_tuple_76) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
            %ptr_78 = cute.add_offset(%iter_35, %7) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<f32, rmem, align<32>>
            %124 = builtin.unrealized_conversion_cast %ptr_77 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
            %125 = builtin.unrealized_conversion_cast %ptr_78 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
            %126 = llvm.load %124 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
            llvm.store %126, %125 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          }
          %ptr_68 = cute.add_offset(%iter_45, %6) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<i8, rmem>
          %102 = builtin.unrealized_conversion_cast %ptr_68 : !cute.ptr<i8, rmem> to !llvm.ptr
          %103 = llvm.load %102 : !llvm.ptr -> i8
          %104 = llvm.icmp "ne" %103, %14 : i8
          scf.if %104 {
            %123 = arith.muli %74, %c2_i64 : i64
            %124 = arith.addi %123, %c1_i64 : i64
            %int_tuple_75 = cute.make_int_tuple(%124) : (i64) -> !cute.int_tuple<"?{i64}">
            %ptr_76 = cute.add_offset(%ptr_20, %int_tuple_75) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
            %ptr_77 = cute.add_offset(%iter_35, %6) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<f32, rmem>
            %125 = builtin.unrealized_conversion_cast %ptr_76 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
            %126 = builtin.unrealized_conversion_cast %ptr_77 : !cute.ptr<f32, rmem> to !llvm.ptr
            %127 = llvm.load %125 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
            llvm.store %127, %126 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          }
          %ptr_69 = cute.add_offset(%iter_45, %5) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<i8, rmem, align<2>>
          %105 = builtin.unrealized_conversion_cast %ptr_69 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
          %106 = llvm.load %105 : !llvm.ptr -> i8
          %107 = llvm.icmp "ne" %106, %14 : i8
          scf.if %107 {
            %123 = arith.muli %74, %c2_i64 : i64
            %124 = arith.addi %123, %c2_i64 : i64
            %iv_75 = cute.assume(%124) : (i64) -> !cute.i64<divby 2>
            %int_tuple_76 = cute.make_int_tuple(%iv_75) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
            %ptr_77 = cute.add_offset(%ptr_20, %int_tuple_76) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
            %ptr_78 = cute.add_offset(%iter_35, %5) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<f32, rmem, align<8>>
            %125 = builtin.unrealized_conversion_cast %ptr_77 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
            %126 = builtin.unrealized_conversion_cast %ptr_78 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
            %127 = llvm.load %125 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
            llvm.store %127, %126 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          }
          %ptr_70 = cute.add_offset(%iter_45, %4) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<i8, rmem>
          %108 = builtin.unrealized_conversion_cast %ptr_70 : !cute.ptr<i8, rmem> to !llvm.ptr
          %109 = llvm.load %108 : !llvm.ptr -> i8
          %110 = llvm.icmp "ne" %109, %14 : i8
          scf.if %110 {
            %123 = arith.muli %74, %c2_i64 : i64
            %124 = arith.addi %123, %c3_i64 : i64
            %int_tuple_75 = cute.make_int_tuple(%124) : (i64) -> !cute.int_tuple<"?{i64}">
            %ptr_76 = cute.add_offset(%ptr_20, %int_tuple_75) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
            %ptr_77 = cute.add_offset(%iter_35, %4) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<f32, rmem>
            %125 = builtin.unrealized_conversion_cast %ptr_76 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
            %126 = builtin.unrealized_conversion_cast %ptr_77 : !cute.ptr<f32, rmem> to !llvm.ptr
            %127 = llvm.load %125 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
            llvm.store %127, %126 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          }
          %ptr_71 = cute.add_offset(%iter_45, %3) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<i8, rmem, align<4>>
          %111 = builtin.unrealized_conversion_cast %ptr_71 : !cute.ptr<i8, rmem, align<4>> to !llvm.ptr
          %112 = llvm.load %111 : !llvm.ptr -> i8
          %113 = llvm.icmp "ne" %112, %14 : i8
          scf.if %113 {
            %123 = arith.muli %74, %c3_i64 : i64
            %iv_75 = cute.assume(%123) : (i64) -> !cute.i64<divby 3>
            %int_tuple_76 = cute.make_int_tuple(%iv_75) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
            %ptr_77 = cute.add_offset(%ptr_20, %int_tuple_76) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
            %ptr_78 = cute.add_offset(%iter_35, %3) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<f32, rmem, align<16>>
            %124 = builtin.unrealized_conversion_cast %ptr_77 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
            %125 = builtin.unrealized_conversion_cast %ptr_78 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
            %126 = llvm.load %124 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
            llvm.store %126, %125 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          }
          %ptr_72 = cute.add_offset(%iter_45, %2) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<i8, rmem>
          %114 = builtin.unrealized_conversion_cast %ptr_72 : !cute.ptr<i8, rmem> to !llvm.ptr
          %115 = llvm.load %114 : !llvm.ptr -> i8
          %116 = llvm.icmp "ne" %115, %14 : i8
          scf.if %116 {
            %123 = arith.muli %74, %c3_i64 : i64
            %124 = arith.addi %123, %c1_i64 : i64
            %int_tuple_75 = cute.make_int_tuple(%124) : (i64) -> !cute.int_tuple<"?{i64}">
            %ptr_76 = cute.add_offset(%ptr_20, %int_tuple_75) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
            %ptr_77 = cute.add_offset(%iter_35, %2) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<f32, rmem>
            %125 = builtin.unrealized_conversion_cast %ptr_76 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
            %126 = builtin.unrealized_conversion_cast %ptr_77 : !cute.ptr<f32, rmem> to !llvm.ptr
            %127 = llvm.load %125 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
            llvm.store %127, %126 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          }
          %ptr_73 = cute.add_offset(%iter_45, %1) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<i8, rmem, align<2>>
          %117 = builtin.unrealized_conversion_cast %ptr_73 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
          %118 = llvm.load %117 : !llvm.ptr -> i8
          %119 = llvm.icmp "ne" %118, %14 : i8
          scf.if %119 {
            %123 = arith.muli %74, %c3_i64 : i64
            %124 = arith.addi %123, %c2_i64 : i64
            %int_tuple_75 = cute.make_int_tuple(%124) : (i64) -> !cute.int_tuple<"?{i64}">
            %ptr_76 = cute.add_offset(%ptr_20, %int_tuple_75) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
            %ptr_77 = cute.add_offset(%iter_35, %1) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<f32, rmem, align<8>>
            %125 = builtin.unrealized_conversion_cast %ptr_76 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
            %126 = builtin.unrealized_conversion_cast %ptr_77 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
            %127 = llvm.load %125 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
            llvm.store %127, %126 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          }
          %ptr_74 = cute.add_offset(%iter_45, %0) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<i8, rmem>
          %120 = builtin.unrealized_conversion_cast %ptr_74 : !cute.ptr<i8, rmem> to !llvm.ptr
          %121 = llvm.load %120 : !llvm.ptr -> i8
          %122 = llvm.icmp "ne" %121, %14 : i8
          scf.if %122 {
            %123 = arith.muli %74, %c3_i64 : i64
            %124 = arith.addi %123, %c3_i64 : i64
            %iv_75 = cute.assume(%124) : (i64) -> !cute.i64<divby 3>
            %int_tuple_76 = cute.make_int_tuple(%iv_75) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
            %ptr_77 = cute.add_offset(%ptr_20, %int_tuple_76) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
            %ptr_78 = cute.add_offset(%iter_35, %0) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<f32, rmem>
            %125 = builtin.unrealized_conversion_cast %ptr_77 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
            %126 = builtin.unrealized_conversion_cast %ptr_78 : !cute.ptr<f32, rmem> to !llvm.ptr
            %127 = llvm.load %125 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
            llvm.store %127, %126 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          }
        } {llvm.loop_annotation = #loop_annotation}
      }
      scf.for %arg6 = %c0_i32 to %c10_i32 step %c1_i32  : i32 {
        %70 = cute.memref.load_vec %rmem : !memref_rmem_f32_
        %71 = cute.memref.load_vec %rmem_36 : !memref_rmem_f32_
        %72 = arith.addf %70, %71 : vector<16xf32>
        cute.memref.store_vec %72, %rmem_38 : !memref_rmem_f32_
      }
      %iter_46 = cute.get_iter(%rmem_38) : !memref_rmem_f32_
      %append = cute.append_to_rank<2> (%lay_34, %19) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">
      %67 = cute.get_scalars(%append) <{only_dynamic}> : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %stride_47 = cute.make_stride(%67) : (i64) -> !cute.stride<"((0,(1,?{i64})),(0,0))">
      %lay_48 = cute.make_layout(%18, %stride_47) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %append_49 = cute.append_to_rank<2> (%lay_48, %19) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">, !cute.layout<"1:0">
      %68 = cute.get_scalars(%append_49) <{only_dynamic}> : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %stride_50 = cute.make_stride(%68) : (i64) -> !cute.stride<"((0,(1,?{i64})),((0,0)))">
      %lay_51 = cute.make_layout(%17, %stride_50) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
      %69 = cute.get_scalars(%16) : !cute.int_tuple<"1">
      scf.for %arg6 = %c0_i32 to %69 step %c1_i32  : i32 {
        %70 = cute.get_scalars(%lay_51) <{only_dynamic}> : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
        %stride_52 = cute.make_stride(%70) : (i64) -> !cute.stride<"((0,(1,?{i64})))">
        %lay_53 = cute.make_layout(%15, %stride_52) : !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
        %71 = cute.get_scalars(%lay_53) <{only_dynamic}> : !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
        %72 = builtin.unrealized_conversion_cast %iter_45 : !cute.ptr<i8, rmem, align<32>> to !llvm.ptr
        %73 = llvm.load %72 : !llvm.ptr -> i8
        %74 = llvm.icmp "ne" %73, %14 : i8
        scf.if %74 {
          %120 = builtin.unrealized_conversion_cast %iter_46 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
          %121 = builtin.unrealized_conversion_cast %ptr_32 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %122 = llvm.load %120 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %122, %121 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %ptr_54 = cute.add_offset(%iter_45, %16) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
        %75 = builtin.unrealized_conversion_cast %ptr_54 : !cute.ptr<i8, rmem> to !llvm.ptr
        %76 = llvm.load %75 : !llvm.ptr -> i8
        %77 = llvm.icmp "ne" %76, %14 : i8
        scf.if %77 {
          %ptr_69 = cute.add_offset(%iter_46, %16) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
          %ptr_70 = cute.add_offset(%ptr_32, %16) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
          %120 = builtin.unrealized_conversion_cast %ptr_69 : !cute.ptr<f32, rmem> to !llvm.ptr
          %121 = builtin.unrealized_conversion_cast %ptr_70 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %122 = llvm.load %120 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %122, %121 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %ptr_55 = cute.add_offset(%iter_45, %13) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem, align<2>>
        %78 = builtin.unrealized_conversion_cast %ptr_55 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
        %79 = llvm.load %78 : !llvm.ptr -> i8
        %80 = llvm.icmp "ne" %79, %14 : i8
        scf.if %80 {
          %ptr_69 = cute.add_offset(%iter_46, %13) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
          %ptr_70 = cute.add_offset(%ptr_32, %13) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
          %120 = builtin.unrealized_conversion_cast %ptr_69 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %121 = builtin.unrealized_conversion_cast %ptr_70 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %122 = llvm.load %120 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %122, %121 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %ptr_56 = cute.add_offset(%iter_45, %12) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
        %81 = builtin.unrealized_conversion_cast %ptr_56 : !cute.ptr<i8, rmem> to !llvm.ptr
        %82 = llvm.load %81 : !llvm.ptr -> i8
        %83 = llvm.icmp "ne" %82, %14 : i8
        scf.if %83 {
          %ptr_69 = cute.add_offset(%iter_46, %12) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
          %ptr_70 = cute.add_offset(%ptr_32, %12) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
          %120 = builtin.unrealized_conversion_cast %ptr_69 : !cute.ptr<f32, rmem> to !llvm.ptr
          %121 = builtin.unrealized_conversion_cast %ptr_70 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %122 = llvm.load %120 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %122, %121 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %ptr_57 = cute.add_offset(%iter_45, %11) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem, align<4>>
        %84 = builtin.unrealized_conversion_cast %ptr_57 : !cute.ptr<i8, rmem, align<4>> to !llvm.ptr
        %85 = llvm.load %84 : !llvm.ptr -> i8
        %86 = llvm.icmp "ne" %85, %14 : i8
        scf.if %86 {
          %ptr_69 = cute.add_offset(%iter_46, %11) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
          %int_tuple_70 = cute.make_int_tuple(%71) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_71 = cute.add_offset(%ptr_32, %int_tuple_70) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %120 = builtin.unrealized_conversion_cast %ptr_69 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
          %121 = builtin.unrealized_conversion_cast %ptr_71 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %122 = llvm.load %120 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %122, %121 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %ptr_58 = cute.add_offset(%iter_45, %10) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
        %87 = builtin.unrealized_conversion_cast %ptr_58 : !cute.ptr<i8, rmem> to !llvm.ptr
        %88 = llvm.load %87 : !llvm.ptr -> i8
        %89 = llvm.icmp "ne" %88, %14 : i8
        scf.if %89 {
          %ptr_69 = cute.add_offset(%iter_46, %10) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<f32, rmem>
          %120 = arith.addi %71, %c1_i64 : i64
          %int_tuple_70 = cute.make_int_tuple(%120) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_71 = cute.add_offset(%ptr_32, %int_tuple_70) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %121 = builtin.unrealized_conversion_cast %ptr_69 : !cute.ptr<f32, rmem> to !llvm.ptr
          %122 = builtin.unrealized_conversion_cast %ptr_71 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %123 = llvm.load %121 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %123, %122 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %ptr_59 = cute.add_offset(%iter_45, %9) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem, align<2>>
        %90 = builtin.unrealized_conversion_cast %ptr_59 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
        %91 = llvm.load %90 : !llvm.ptr -> i8
        %92 = llvm.icmp "ne" %91, %14 : i8
        scf.if %92 {
          %ptr_69 = cute.add_offset(%iter_46, %9) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
          %120 = arith.addi %71, %c2_i64 : i64
          %int_tuple_70 = cute.make_int_tuple(%120) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_71 = cute.add_offset(%ptr_32, %int_tuple_70) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %121 = builtin.unrealized_conversion_cast %ptr_69 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %122 = builtin.unrealized_conversion_cast %ptr_71 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %123 = llvm.load %121 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %123, %122 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %ptr_60 = cute.add_offset(%iter_45, %8) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
        %93 = builtin.unrealized_conversion_cast %ptr_60 : !cute.ptr<i8, rmem> to !llvm.ptr
        %94 = llvm.load %93 : !llvm.ptr -> i8
        %95 = llvm.icmp "ne" %94, %14 : i8
        scf.if %95 {
          %ptr_69 = cute.add_offset(%iter_46, %8) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<f32, rmem>
          %120 = arith.addi %71, %c3_i64 : i64
          %int_tuple_70 = cute.make_int_tuple(%120) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_71 = cute.add_offset(%ptr_32, %int_tuple_70) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %121 = builtin.unrealized_conversion_cast %ptr_69 : !cute.ptr<f32, rmem> to !llvm.ptr
          %122 = builtin.unrealized_conversion_cast %ptr_71 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %123 = llvm.load %121 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %123, %122 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %ptr_61 = cute.add_offset(%iter_45, %7) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<i8, rmem, align<8>>
        %96 = builtin.unrealized_conversion_cast %ptr_61 : !cute.ptr<i8, rmem, align<8>> to !llvm.ptr
        %97 = llvm.load %96 : !llvm.ptr -> i8
        %98 = llvm.icmp "ne" %97, %14 : i8
        scf.if %98 {
          %ptr_69 = cute.add_offset(%iter_46, %7) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<f32, rmem, align<32>>
          %120 = arith.muli %71, %c2_i64 : i64
          %iv_70 = cute.assume(%120) : (i64) -> !cute.i64<divby 2>
          %int_tuple_71 = cute.make_int_tuple(%iv_70) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
          %ptr_72 = cute.add_offset(%ptr_32, %int_tuple_71) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
          %121 = builtin.unrealized_conversion_cast %ptr_69 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
          %122 = builtin.unrealized_conversion_cast %ptr_72 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %123 = llvm.load %121 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %123, %122 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %ptr_62 = cute.add_offset(%iter_45, %6) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<i8, rmem>
        %99 = builtin.unrealized_conversion_cast %ptr_62 : !cute.ptr<i8, rmem> to !llvm.ptr
        %100 = llvm.load %99 : !llvm.ptr -> i8
        %101 = llvm.icmp "ne" %100, %14 : i8
        scf.if %101 {
          %ptr_69 = cute.add_offset(%iter_46, %6) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<f32, rmem>
          %120 = arith.muli %71, %c2_i64 : i64
          %121 = arith.addi %120, %c1_i64 : i64
          %int_tuple_70 = cute.make_int_tuple(%121) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_71 = cute.add_offset(%ptr_32, %int_tuple_70) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %122 = builtin.unrealized_conversion_cast %ptr_69 : !cute.ptr<f32, rmem> to !llvm.ptr
          %123 = builtin.unrealized_conversion_cast %ptr_71 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %124 = llvm.load %122 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %124, %123 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %ptr_63 = cute.add_offset(%iter_45, %5) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<i8, rmem, align<2>>
        %102 = builtin.unrealized_conversion_cast %ptr_63 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
        %103 = llvm.load %102 : !llvm.ptr -> i8
        %104 = llvm.icmp "ne" %103, %14 : i8
        scf.if %104 {
          %ptr_69 = cute.add_offset(%iter_46, %5) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<f32, rmem, align<8>>
          %120 = arith.muli %71, %c2_i64 : i64
          %121 = arith.addi %120, %c2_i64 : i64
          %iv_70 = cute.assume(%121) : (i64) -> !cute.i64<divby 2>
          %int_tuple_71 = cute.make_int_tuple(%iv_70) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
          %ptr_72 = cute.add_offset(%ptr_32, %int_tuple_71) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
          %122 = builtin.unrealized_conversion_cast %ptr_69 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %123 = builtin.unrealized_conversion_cast %ptr_72 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %124 = llvm.load %122 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %124, %123 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %ptr_64 = cute.add_offset(%iter_45, %4) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<i8, rmem>
        %105 = builtin.unrealized_conversion_cast %ptr_64 : !cute.ptr<i8, rmem> to !llvm.ptr
        %106 = llvm.load %105 : !llvm.ptr -> i8
        %107 = llvm.icmp "ne" %106, %14 : i8
        scf.if %107 {
          %ptr_69 = cute.add_offset(%iter_46, %4) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<f32, rmem>
          %120 = arith.muli %71, %c2_i64 : i64
          %121 = arith.addi %120, %c3_i64 : i64
          %int_tuple_70 = cute.make_int_tuple(%121) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_71 = cute.add_offset(%ptr_32, %int_tuple_70) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %122 = builtin.unrealized_conversion_cast %ptr_69 : !cute.ptr<f32, rmem> to !llvm.ptr
          %123 = builtin.unrealized_conversion_cast %ptr_71 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %124 = llvm.load %122 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %124, %123 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %ptr_65 = cute.add_offset(%iter_45, %3) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<i8, rmem, align<4>>
        %108 = builtin.unrealized_conversion_cast %ptr_65 : !cute.ptr<i8, rmem, align<4>> to !llvm.ptr
        %109 = llvm.load %108 : !llvm.ptr -> i8
        %110 = llvm.icmp "ne" %109, %14 : i8
        scf.if %110 {
          %ptr_69 = cute.add_offset(%iter_46, %3) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<f32, rmem, align<16>>
          %120 = arith.muli %71, %c3_i64 : i64
          %iv_70 = cute.assume(%120) : (i64) -> !cute.i64<divby 3>
          %int_tuple_71 = cute.make_int_tuple(%iv_70) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
          %ptr_72 = cute.add_offset(%ptr_32, %int_tuple_71) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
          %121 = builtin.unrealized_conversion_cast %ptr_69 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
          %122 = builtin.unrealized_conversion_cast %ptr_72 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %123 = llvm.load %121 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %123, %122 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %ptr_66 = cute.add_offset(%iter_45, %2) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<i8, rmem>
        %111 = builtin.unrealized_conversion_cast %ptr_66 : !cute.ptr<i8, rmem> to !llvm.ptr
        %112 = llvm.load %111 : !llvm.ptr -> i8
        %113 = llvm.icmp "ne" %112, %14 : i8
        scf.if %113 {
          %ptr_69 = cute.add_offset(%iter_46, %2) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<f32, rmem>
          %120 = arith.muli %71, %c3_i64 : i64
          %121 = arith.addi %120, %c1_i64 : i64
          %int_tuple_70 = cute.make_int_tuple(%121) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_71 = cute.add_offset(%ptr_32, %int_tuple_70) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %122 = builtin.unrealized_conversion_cast %ptr_69 : !cute.ptr<f32, rmem> to !llvm.ptr
          %123 = builtin.unrealized_conversion_cast %ptr_71 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %124 = llvm.load %122 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %124, %123 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %ptr_67 = cute.add_offset(%iter_45, %1) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<i8, rmem, align<2>>
        %114 = builtin.unrealized_conversion_cast %ptr_67 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
        %115 = llvm.load %114 : !llvm.ptr -> i8
        %116 = llvm.icmp "ne" %115, %14 : i8
        scf.if %116 {
          %ptr_69 = cute.add_offset(%iter_46, %1) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<f32, rmem, align<8>>
          %120 = arith.muli %71, %c3_i64 : i64
          %121 = arith.addi %120, %c2_i64 : i64
          %int_tuple_70 = cute.make_int_tuple(%121) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_71 = cute.add_offset(%ptr_32, %int_tuple_70) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %122 = builtin.unrealized_conversion_cast %ptr_69 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %123 = builtin.unrealized_conversion_cast %ptr_71 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %124 = llvm.load %122 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %124, %123 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %ptr_68 = cute.add_offset(%iter_45, %0) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<i8, rmem>
        %117 = builtin.unrealized_conversion_cast %ptr_68 : !cute.ptr<i8, rmem> to !llvm.ptr
        %118 = llvm.load %117 : !llvm.ptr -> i8
        %119 = llvm.icmp "ne" %118, %14 : i8
        scf.if %119 {
          %ptr_69 = cute.add_offset(%iter_46, %0) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<f32, rmem>
          %120 = arith.muli %71, %c3_i64 : i64
          %121 = arith.addi %120, %c3_i64 : i64
          %iv_70 = cute.assume(%121) : (i64) -> !cute.i64<divby 3>
          %int_tuple_71 = cute.make_int_tuple(%iv_70) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
          %ptr_72 = cute.add_offset(%ptr_32, %int_tuple_71) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
          %122 = builtin.unrealized_conversion_cast %ptr_69 : !cute.ptr<f32, rmem> to !llvm.ptr
          %123 = builtin.unrealized_conversion_cast %ptr_72 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %124 = llvm.load %122 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %124, %123 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
      } {llvm.loop_annotation = #loop_annotation}
      return
    }
  }
  func.func @cutlass_elementwise_add_Tensorgmem_o_i641_Tensorgmem_o_i641_Tensorgmem_o_i641_CUstream_False_False(%arg0: !memref_gmem_f32_1, %arg1: !memref_gmem_f32_1, %arg2: !memref_gmem_f32_1, %arg3: !cuda.stream) -> i32 attributes {llvm.emit_c_interface} {
    %c0_i64 = arith.constant 0 : i64
    %c1_i32 = arith.constant 1 : i32
    %c0_i32 = arith.constant 0 : i32
    %0 = cute.static : !cute.stride<"((1@0,1@1),(16@0,128@1))">
    %1 = cute.static : !cute.stride<"(1@0,1@1)">
    %2 = cute.static : !cute.int_tuple<"(0,0)">
    %c128_i32 = arith.constant 128 : i32
    %c16_i64 = arith.constant 16 : i64
    %c16_i32 = arith.constant 16 : i32
    %iter = cute.get_iter(%arg0) : !memref_gmem_f32_1
    %lay = cute.get_layout(%arg0) : !memref_gmem_f32_1
    %3:3 = cute.get_scalars(%lay) <{only_dynamic}> : !cute.layout<"(?,?):(?{i64},1)">
    %4 = arith.ceildivsi %3#0, %c16_i32 : i32
    %5 = arith.muli %3#2, %c16_i64 : i64
    %6 = arith.ceildivsi %3#1, %c128_i32 : i32
    %shape = cute.make_shape(%4, %6) : (i32, i32) -> !cute.shape<"((16,128),(?,?))">
    %iv = cute.assume(%5) : (i64) -> !cute.i64<divby 16>
    %stride = cute.make_stride(%3#2, %iv) : (i64, !cute.i64<divby 16>) -> !cute.stride<"((?{i64},1),(?{i64 div=16},128))">
    %lay_0 = cute.make_layout(%shape, %stride) : !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
    %view = cute.make_view(%iter, %lay_0) : !memref_gmem_f32_
    %iter_1 = cute.get_iter(%arg1) : !memref_gmem_f32_1
    %lay_2 = cute.get_layout(%arg1) : !memref_gmem_f32_1
    %7:3 = cute.get_scalars(%lay_2) <{only_dynamic}> : !cute.layout<"(?,?):(?{i64},1)">
    %8 = arith.ceildivsi %7#0, %c16_i32 : i32
    %9 = arith.muli %7#2, %c16_i64 : i64
    %10 = arith.ceildivsi %7#1, %c128_i32 : i32
    %shape_3 = cute.make_shape(%8, %10) : (i32, i32) -> !cute.shape<"((16,128),(?,?))">
    %iv_4 = cute.assume(%9) : (i64) -> !cute.i64<divby 16>
    %stride_5 = cute.make_stride(%7#2, %iv_4) : (i64, !cute.i64<divby 16>) -> !cute.stride<"((?{i64},1),(?{i64 div=16},128))">
    %lay_6 = cute.make_layout(%shape_3, %stride_5) : !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
    %view_7 = cute.make_view(%iter_1, %lay_6) : !memref_gmem_f32_
    %iter_8 = cute.get_iter(%arg2) : !memref_gmem_f32_1
    %lay_9 = cute.get_layout(%arg2) : !memref_gmem_f32_1
    %11:3 = cute.get_scalars(%lay_9) <{only_dynamic}> : !cute.layout<"(?,?):(?{i64},1)">
    %12 = arith.ceildivsi %11#0, %c16_i32 : i32
    %13 = arith.muli %11#2, %c16_i64 : i64
    %14 = arith.ceildivsi %11#1, %c128_i32 : i32
    %shape_10 = cute.make_shape(%12, %14) : (i32, i32) -> !cute.shape<"((16,128),(?,?))">
    %iv_11 = cute.assume(%13) : (i64) -> !cute.i64<divby 16>
    %stride_12 = cute.make_stride(%11#2, %iv_11) : (i64, !cute.i64<divby 16>) -> !cute.stride<"((?{i64},1),(?{i64 div=16},128))">
    %lay_13 = cute.make_layout(%shape_10, %stride_12) : !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
    %view_14 = cute.make_view(%iter_8, %lay_13) : !memref_gmem_f32_
    %lay_15 = cute.get_layout(%arg2) : !memref_gmem_f32_1
    %15 = cute.get_shape(%lay_15) : (!cute.layout<"(?,?):(?{i64},1)">) -> !cute.shape<"(?,?)">
    %e0, %e1 = cute.get_leaves(%15) : !cute.shape<"(?,?)">
    %itup = cute.to_int_tuple(%e0) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %16 = cute.get_scalars(%itup) : !cute.int_tuple<"?">
    %itup_16 = cute.to_int_tuple(%e1) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %17 = cute.get_scalars(%itup_16) : !cute.int_tuple<"?">
    %shape_17 = cute.make_shape(%itup, %itup_16) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.shape<"(?,?)">
    %lay_18 = cute.make_layout(%shape_17, %1) : !cute.layout<"(?,?):(1@0,1@1)">
    %18:2 = cute.get_scalars(%lay_18) <{only_dynamic}> : !cute.layout<"(?,?):(1@0,1@1)">
    %19 = arith.ceildivsi %18#0, %c16_i32 : i32
    %20 = arith.ceildivsi %18#1, %c128_i32 : i32
    %shape_19 = cute.make_shape(%19, %20) : (i32, i32) -> !cute.shape<"((16,128),(?,?))">
    %lay_20 = cute.make_layout(%shape_19, %0) : !cute.layout<"((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
    %view_21 = cute.make_view(%2, %lay_20) : !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
    %sz = cute.size(%lay_13) <{mode = [1]}> : (!cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.int_tuple<"?">
    %e0_22 = cute.get_leaves(%sz) : !cute.int_tuple<"?">
    %21 = cute.get_scalars(%e0_22) : !cute.int_tuple<"?">
    %22 = cuda.launch_cfg.create<max_attrs = 2 : i32> (blockDim = (%c128_i32, %c1_i32, %c1_i32), dynamicSmemBytes = %c0_i64, gridDim = (%21, %c1_i32, %c1_i32), stream = %arg3) : i32, i32, i32, i64, i32, i32, i32, !cuda.stream -> !cuda.launch_cfg<max_attrs = 2>
    %23 = cuda.launch_ex @kernels::@kernel_cutlass_elementwise_add_kernel_tensorptrf32gmemo161281i64div16128_tensorptrf32gmemo161281i64div16128_tensorptrf32gmemo161281i64div16128_tensor00o1612810111601281___False_0<%22> (%view, %view_7, %view_14, %view_21, %16, %17) : !cuda.launch_cfg<max_attrs = 2>, (!memref_gmem_f32_, !memref_gmem_f32_, !memref_gmem_f32_, !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">, i32, i32) -> !cuda.result
    %24 = cuda.cast %23 : !cuda.result -> i32
    cuda.return_if_error %24 : i32
    return %c0_i32 : i32
  }
}
