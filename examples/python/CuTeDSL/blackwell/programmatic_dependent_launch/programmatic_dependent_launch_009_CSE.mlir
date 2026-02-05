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
      %lay_1 = cute.get_layout(%arg1) : !memref_gmem_f32_
      %27:4 = cute.get_scalars(%lay_1) <{only_dynamic}> : !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
      %stride_2 = cute.make_stride(%27#2) : (i64) -> !cute.stride<"(?{i64},1)">
      %lay_3 = cute.make_layout(%23, %stride_2) : !cute.layout<"(16,128):(?{i64},1)">
      %idx_4 = cute.crd2idx(%coord, %lay_1) : (!cute.coord<"((_,_),?)">, !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.int_tuple<"?{i64 div=16}">
      %iter_5 = cute.get_iter(%arg1) : !memref_gmem_f32_
      %ptr_6 = cute.add_offset(%iter_5, %idx_4) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=16}">) -> !cute.ptr<f32, gmem>
      %lay_7 = cute.get_layout(%arg2) : !memref_gmem_f32_
      %28:4 = cute.get_scalars(%lay_7) <{only_dynamic}> : !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
      %stride_8 = cute.make_stride(%28#2) : (i64) -> !cute.stride<"(?{i64},1)">
      %lay_9 = cute.make_layout(%23, %stride_8) : !cute.layout<"(16,128):(?{i64},1)">
      %idx_10 = cute.crd2idx(%coord, %lay_7) : (!cute.coord<"((_,_),?)">, !cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.int_tuple<"?{i64 div=16}">
      %iter_11 = cute.get_iter(%arg2) : !memref_gmem_f32_
      %ptr_12 = cute.add_offset(%iter_11, %idx_10) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=16}">) -> !cute.ptr<f32, gmem>
      %lay_13 = cute.get_layout(%arg3) : !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
      %idx_14 = cute.crd2idx(%coord, %lay_13) : (!cute.coord<"((_,_),?)">, !cute.layout<"((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">) -> !cute.int_tuple<"(?{div=16},?{div=128})">
      %tup = cute.add_offset(%22, %idx_14) : (!cute.int_tuple<"(0,0)">, !cute.int_tuple<"(?{div=16},?{div=128})">) -> !cute.int_tuple<"(?{div=16},?{div=128})">
      %atom = cute.make_atom() : () -> !cute_nvgpu.atom.universal_copy<f32>
      %29 = cute.make_tiled_copy(%atom) : !copy_simt
      %30 = cute.make_tiled_copy(%atom) : !copy_simt
      %31 = cute.make_tiled_copy(%atom) : !copy_simt
      %coord_15 = cute.make_coord(%24) : (i32) -> !cute.coord<"?">
      %32 = cute.get_scalars(%lay_0) <{only_dynamic}> : !cute.layout<"(16,128):(?{i64},1)">
      %33 = cute.get_scalars(%coord_15) <{only_dynamic}> : !cute.coord<"?">
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
      %ptr_16 = cute.add_offset(%ptr, %int_tuple) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=4}">) -> !cute.ptr<f32, gmem>
      %stride_17 = cute.make_stride(%32) : (i64) -> !cute.stride<"((0,(1,?{i64})),0,0)">
      %lay_18 = cute.make_layout(%21, %stride_17) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %42 = cute.get_scalars(%lay_3) <{only_dynamic}> : !cute.layout<"(16,128):(?{i64},1)">
      %43 = arith.muli %42, %c4_i64 : i64
      %44 = arith.muli %38, %43 : i64
      %45 = arith.addi %40, %44 : i64
      %iv_19 = cute.assume(%45) : (i64) -> !cute.i64<divby 4>
      %int_tuple_20 = cute.make_int_tuple(%iv_19) : (!cute.i64<divby 4>) -> !cute.int_tuple<"?{i64 div=4}">
      %ptr_21 = cute.add_offset(%ptr_6, %int_tuple_20) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=4}">) -> !cute.ptr<f32, gmem>
      %stride_22 = cute.make_stride(%42) : (i64) -> !cute.stride<"((0,(1,?{i64})),0,0)">
      %lay_23 = cute.make_layout(%21, %stride_22) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %46 = cute.get_scalars(%lay_9) <{only_dynamic}> : !cute.layout<"(16,128):(?{i64},1)">
      %47 = arith.muli %46, %c4_i64 : i64
      %48 = arith.muli %38, %47 : i64
      %49 = arith.addi %40, %48 : i64
      %iv_24 = cute.assume(%49) : (i64) -> !cute.i64<divby 4>
      %int_tuple_25 = cute.make_int_tuple(%iv_24) : (!cute.i64<divby 4>) -> !cute.int_tuple<"?{i64 div=4}">
      %ptr_26 = cute.add_offset(%ptr_12, %int_tuple_25) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=4}">) -> !cute.ptr<f32, gmem>
      %stride_27 = cute.make_stride(%46) : (i64) -> !cute.stride<"((0,(1,?{i64})),0,0)">
      %lay_28 = cute.make_layout(%21, %stride_27) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %rmem = cute.memref.alloca() : !memref_rmem_f32_
      %iter_29 = cute.get_iter(%rmem) : !memref_rmem_f32_
      %rmem_30 = cute.memref.alloca() : !memref_rmem_f32_
      %iter_31 = cute.get_iter(%rmem_30) : !memref_rmem_f32_
      %rmem_32 = cute.memref.alloca() : !memref_rmem_f32_
      %50 = arith.muli %35, %c4_i32 : i32
      %iv_33 = cute.assume(%50) : (i32) -> !cute.i32<divby 4>
      %iv_34 = cute.assume(%37) : (i32) -> !cute.i32<divby 4>
      %int_tuple_35 = cute.make_int_tuple(%iv_33, %iv_34) : (!cute.i32<divby 4>, !cute.i32<divby 4>) -> !cute.int_tuple<"(?{div=4},?{div=4})">
      %tup_36 = cute.add_offset(%tup, %int_tuple_35) : (!cute.int_tuple<"(?{div=16},?{div=128})">, !cute.int_tuple<"(?{div=4},?{div=4})">) -> !cute.int_tuple<"(?{div=4},?{div=4})">
      %rmem_37 = cute.memref.alloca() : !memref_rmem_i8_
      scf.for %arg6 = %c0_i32 to %c16_i32 step %c1_i32  : i32 {
        %coord_45 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"?">
        %idx_46 = cute.crd2idx(%coord_45, %20) : (!cute.coord<"?">, !cute.layout<"((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">) -> !cute.int_tuple<"(?,?)">
        %tup_47 = cute.add_offset(%tup_36, %idx_46) : (!cute.int_tuple<"(?{div=4},?{div=4})">, !cute.int_tuple<"(?,?)">) -> !cute.int_tuple<"(?,?)">
        %e0, %e1 = cute.get_leaves(%tup_47) : !cute.int_tuple<"(?,?)">
        %coord_48 = cute.make_coord(%e0, %e1) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
        %coord_49 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
        %54:2 = cute.get_scalars(%coord_48) : !cute.coord<"(?,?)">
        %55:2 = cute.get_scalars(%coord_49) : !cute.coord<"(?,?)">
        %56 = arith.cmpi slt, %54#0, %55#0 : i32
        %57 = arith.cmpi slt, %54#1, %55#1 : i32
        %58 = arith.andi %56, %57 : i1
        %59 = arith.extui %58 : i1 to i8
        cute.memref.store(%rmem_37, %coord_45, %59) : (!memref_rmem_i8_, !cute.coord<"?">, i8) -> ()
      }
      %iter_38 = cute.get_iter(%rmem_37) : !memref_rmem_i8_
      scf.for %arg6 = %c0_i32 to %c10_i32 step %c1_i32  : i32 {
        %append_45 = cute.append_to_rank<2> (%lay_23, %19) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">
        %54 = cute.get_scalars(%append_45) <{only_dynamic}> : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
        %stride_46 = cute.make_stride(%54) : (i64) -> !cute.stride<"((0,(1,?{i64})),(0,0))">
        %lay_47 = cute.make_layout(%18, %stride_46) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
        %append_48 = cute.append_to_rank<2> (%lay_47, %19) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">, !cute.layout<"1:0">
        %55 = cute.get_scalars(%append_48) <{only_dynamic}> : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
        %stride_49 = cute.make_stride(%55) : (i64) -> !cute.stride<"((0,(1,?{i64})),((0,0)))">
        %lay_50 = cute.make_layout(%17, %stride_49) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
        %56 = cute.get_scalars(%16) : !cute.int_tuple<"1">
        scf.for %arg7 = %c0_i32 to %56 step %c1_i32  : i32 {
          %57 = cute.get_scalars(%lay_50) <{only_dynamic}> : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
          %stride_51 = cute.make_stride(%57) : (i64) -> !cute.stride<"((0,(1,?{i64})))">
          %lay_52 = cute.make_layout(%15, %stride_51) : !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
          %58 = cute.get_scalars(%lay_52) <{only_dynamic}> : !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
          %59 = builtin.unrealized_conversion_cast %iter_38 : !cute.ptr<i8, rmem, align<32>> to !llvm.ptr
          %60 = llvm.load %59 : !llvm.ptr -> i8
          %61 = llvm.icmp "ne" %60, %14 : i8
          scf.if %61 {
            %107 = builtin.unrealized_conversion_cast %ptr_21 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
            %108 = builtin.unrealized_conversion_cast %iter_31 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
            %109 = llvm.load %107 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
            llvm.store %109, %108 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          }
          %ptr_53 = cute.add_offset(%iter_38, %16) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
          %62 = builtin.unrealized_conversion_cast %ptr_53 : !cute.ptr<i8, rmem> to !llvm.ptr
          %63 = llvm.load %62 : !llvm.ptr -> i8
          %64 = llvm.icmp "ne" %63, %14 : i8
          scf.if %64 {
            %ptr_68 = cute.add_offset(%ptr_21, %16) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
            %ptr_69 = cute.add_offset(%iter_31, %16) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
            %107 = builtin.unrealized_conversion_cast %ptr_68 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
            %108 = builtin.unrealized_conversion_cast %ptr_69 : !cute.ptr<f32, rmem> to !llvm.ptr
            %109 = llvm.load %107 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
            llvm.store %109, %108 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          }
          %ptr_54 = cute.add_offset(%iter_38, %13) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem, align<2>>
          %65 = builtin.unrealized_conversion_cast %ptr_54 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
          %66 = llvm.load %65 : !llvm.ptr -> i8
          %67 = llvm.icmp "ne" %66, %14 : i8
          scf.if %67 {
            %ptr_68 = cute.add_offset(%ptr_21, %13) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
            %ptr_69 = cute.add_offset(%iter_31, %13) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
            %107 = builtin.unrealized_conversion_cast %ptr_68 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
            %108 = builtin.unrealized_conversion_cast %ptr_69 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
            %109 = llvm.load %107 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
            llvm.store %109, %108 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          }
          %ptr_55 = cute.add_offset(%iter_38, %12) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
          %68 = builtin.unrealized_conversion_cast %ptr_55 : !cute.ptr<i8, rmem> to !llvm.ptr
          %69 = llvm.load %68 : !llvm.ptr -> i8
          %70 = llvm.icmp "ne" %69, %14 : i8
          scf.if %70 {
            %ptr_68 = cute.add_offset(%ptr_21, %12) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
            %ptr_69 = cute.add_offset(%iter_31, %12) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
            %107 = builtin.unrealized_conversion_cast %ptr_68 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
            %108 = builtin.unrealized_conversion_cast %ptr_69 : !cute.ptr<f32, rmem> to !llvm.ptr
            %109 = llvm.load %107 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
            llvm.store %109, %108 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          }
          %ptr_56 = cute.add_offset(%iter_38, %11) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem, align<4>>
          %71 = builtin.unrealized_conversion_cast %ptr_56 : !cute.ptr<i8, rmem, align<4>> to !llvm.ptr
          %72 = llvm.load %71 : !llvm.ptr -> i8
          %73 = llvm.icmp "ne" %72, %14 : i8
          scf.if %73 {
            %int_tuple_68 = cute.make_int_tuple(%58) : (i64) -> !cute.int_tuple<"?{i64}">
            %ptr_69 = cute.add_offset(%ptr_21, %int_tuple_68) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
            %ptr_70 = cute.add_offset(%iter_31, %11) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
            %107 = builtin.unrealized_conversion_cast %ptr_69 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
            %108 = builtin.unrealized_conversion_cast %ptr_70 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
            %109 = llvm.load %107 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
            llvm.store %109, %108 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          }
          %ptr_57 = cute.add_offset(%iter_38, %10) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
          %74 = builtin.unrealized_conversion_cast %ptr_57 : !cute.ptr<i8, rmem> to !llvm.ptr
          %75 = llvm.load %74 : !llvm.ptr -> i8
          %76 = llvm.icmp "ne" %75, %14 : i8
          scf.if %76 {
            %107 = arith.addi %58, %c1_i64 : i64
            %int_tuple_68 = cute.make_int_tuple(%107) : (i64) -> !cute.int_tuple<"?{i64}">
            %ptr_69 = cute.add_offset(%ptr_21, %int_tuple_68) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
            %ptr_70 = cute.add_offset(%iter_31, %10) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<f32, rmem>
            %108 = builtin.unrealized_conversion_cast %ptr_69 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
            %109 = builtin.unrealized_conversion_cast %ptr_70 : !cute.ptr<f32, rmem> to !llvm.ptr
            %110 = llvm.load %108 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
            llvm.store %110, %109 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          }
          %ptr_58 = cute.add_offset(%iter_38, %9) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem, align<2>>
          %77 = builtin.unrealized_conversion_cast %ptr_58 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
          %78 = llvm.load %77 : !llvm.ptr -> i8
          %79 = llvm.icmp "ne" %78, %14 : i8
          scf.if %79 {
            %107 = arith.addi %58, %c2_i64 : i64
            %int_tuple_68 = cute.make_int_tuple(%107) : (i64) -> !cute.int_tuple<"?{i64}">
            %ptr_69 = cute.add_offset(%ptr_21, %int_tuple_68) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
            %ptr_70 = cute.add_offset(%iter_31, %9) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
            %108 = builtin.unrealized_conversion_cast %ptr_69 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
            %109 = builtin.unrealized_conversion_cast %ptr_70 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
            %110 = llvm.load %108 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
            llvm.store %110, %109 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          }
          %ptr_59 = cute.add_offset(%iter_38, %8) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
          %80 = builtin.unrealized_conversion_cast %ptr_59 : !cute.ptr<i8, rmem> to !llvm.ptr
          %81 = llvm.load %80 : !llvm.ptr -> i8
          %82 = llvm.icmp "ne" %81, %14 : i8
          scf.if %82 {
            %107 = arith.addi %58, %c3_i64 : i64
            %int_tuple_68 = cute.make_int_tuple(%107) : (i64) -> !cute.int_tuple<"?{i64}">
            %ptr_69 = cute.add_offset(%ptr_21, %int_tuple_68) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
            %ptr_70 = cute.add_offset(%iter_31, %8) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<f32, rmem>
            %108 = builtin.unrealized_conversion_cast %ptr_69 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
            %109 = builtin.unrealized_conversion_cast %ptr_70 : !cute.ptr<f32, rmem> to !llvm.ptr
            %110 = llvm.load %108 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
            llvm.store %110, %109 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          }
          %ptr_60 = cute.add_offset(%iter_38, %7) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<i8, rmem, align<8>>
          %83 = builtin.unrealized_conversion_cast %ptr_60 : !cute.ptr<i8, rmem, align<8>> to !llvm.ptr
          %84 = llvm.load %83 : !llvm.ptr -> i8
          %85 = llvm.icmp "ne" %84, %14 : i8
          scf.if %85 {
            %107 = arith.muli %58, %c2_i64 : i64
            %iv_68 = cute.assume(%107) : (i64) -> !cute.i64<divby 2>
            %int_tuple_69 = cute.make_int_tuple(%iv_68) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
            %ptr_70 = cute.add_offset(%ptr_21, %int_tuple_69) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
            %ptr_71 = cute.add_offset(%iter_31, %7) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<f32, rmem, align<32>>
            %108 = builtin.unrealized_conversion_cast %ptr_70 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
            %109 = builtin.unrealized_conversion_cast %ptr_71 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
            %110 = llvm.load %108 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
            llvm.store %110, %109 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          }
          %ptr_61 = cute.add_offset(%iter_38, %6) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<i8, rmem>
          %86 = builtin.unrealized_conversion_cast %ptr_61 : !cute.ptr<i8, rmem> to !llvm.ptr
          %87 = llvm.load %86 : !llvm.ptr -> i8
          %88 = llvm.icmp "ne" %87, %14 : i8
          scf.if %88 {
            %107 = arith.muli %58, %c2_i64 : i64
            %108 = arith.addi %107, %c1_i64 : i64
            %int_tuple_68 = cute.make_int_tuple(%108) : (i64) -> !cute.int_tuple<"?{i64}">
            %ptr_69 = cute.add_offset(%ptr_21, %int_tuple_68) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
            %ptr_70 = cute.add_offset(%iter_31, %6) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<f32, rmem>
            %109 = builtin.unrealized_conversion_cast %ptr_69 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
            %110 = builtin.unrealized_conversion_cast %ptr_70 : !cute.ptr<f32, rmem> to !llvm.ptr
            %111 = llvm.load %109 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
            llvm.store %111, %110 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          }
          %ptr_62 = cute.add_offset(%iter_38, %5) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<i8, rmem, align<2>>
          %89 = builtin.unrealized_conversion_cast %ptr_62 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
          %90 = llvm.load %89 : !llvm.ptr -> i8
          %91 = llvm.icmp "ne" %90, %14 : i8
          scf.if %91 {
            %107 = arith.muli %58, %c2_i64 : i64
            %108 = arith.addi %107, %c2_i64 : i64
            %iv_68 = cute.assume(%108) : (i64) -> !cute.i64<divby 2>
            %int_tuple_69 = cute.make_int_tuple(%iv_68) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
            %ptr_70 = cute.add_offset(%ptr_21, %int_tuple_69) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
            %ptr_71 = cute.add_offset(%iter_31, %5) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<f32, rmem, align<8>>
            %109 = builtin.unrealized_conversion_cast %ptr_70 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
            %110 = builtin.unrealized_conversion_cast %ptr_71 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
            %111 = llvm.load %109 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
            llvm.store %111, %110 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          }
          %ptr_63 = cute.add_offset(%iter_38, %4) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<i8, rmem>
          %92 = builtin.unrealized_conversion_cast %ptr_63 : !cute.ptr<i8, rmem> to !llvm.ptr
          %93 = llvm.load %92 : !llvm.ptr -> i8
          %94 = llvm.icmp "ne" %93, %14 : i8
          scf.if %94 {
            %107 = arith.muli %58, %c2_i64 : i64
            %108 = arith.addi %107, %c3_i64 : i64
            %int_tuple_68 = cute.make_int_tuple(%108) : (i64) -> !cute.int_tuple<"?{i64}">
            %ptr_69 = cute.add_offset(%ptr_21, %int_tuple_68) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
            %ptr_70 = cute.add_offset(%iter_31, %4) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<f32, rmem>
            %109 = builtin.unrealized_conversion_cast %ptr_69 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
            %110 = builtin.unrealized_conversion_cast %ptr_70 : !cute.ptr<f32, rmem> to !llvm.ptr
            %111 = llvm.load %109 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
            llvm.store %111, %110 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          }
          %ptr_64 = cute.add_offset(%iter_38, %3) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<i8, rmem, align<4>>
          %95 = builtin.unrealized_conversion_cast %ptr_64 : !cute.ptr<i8, rmem, align<4>> to !llvm.ptr
          %96 = llvm.load %95 : !llvm.ptr -> i8
          %97 = llvm.icmp "ne" %96, %14 : i8
          scf.if %97 {
            %107 = arith.muli %58, %c3_i64 : i64
            %iv_68 = cute.assume(%107) : (i64) -> !cute.i64<divby 3>
            %int_tuple_69 = cute.make_int_tuple(%iv_68) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
            %ptr_70 = cute.add_offset(%ptr_21, %int_tuple_69) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
            %ptr_71 = cute.add_offset(%iter_31, %3) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<f32, rmem, align<16>>
            %108 = builtin.unrealized_conversion_cast %ptr_70 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
            %109 = builtin.unrealized_conversion_cast %ptr_71 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
            %110 = llvm.load %108 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
            llvm.store %110, %109 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          }
          %ptr_65 = cute.add_offset(%iter_38, %2) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<i8, rmem>
          %98 = builtin.unrealized_conversion_cast %ptr_65 : !cute.ptr<i8, rmem> to !llvm.ptr
          %99 = llvm.load %98 : !llvm.ptr -> i8
          %100 = llvm.icmp "ne" %99, %14 : i8
          scf.if %100 {
            %107 = arith.muli %58, %c3_i64 : i64
            %108 = arith.addi %107, %c1_i64 : i64
            %int_tuple_68 = cute.make_int_tuple(%108) : (i64) -> !cute.int_tuple<"?{i64}">
            %ptr_69 = cute.add_offset(%ptr_21, %int_tuple_68) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
            %ptr_70 = cute.add_offset(%iter_31, %2) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<f32, rmem>
            %109 = builtin.unrealized_conversion_cast %ptr_69 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
            %110 = builtin.unrealized_conversion_cast %ptr_70 : !cute.ptr<f32, rmem> to !llvm.ptr
            %111 = llvm.load %109 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
            llvm.store %111, %110 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          }
          %ptr_66 = cute.add_offset(%iter_38, %1) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<i8, rmem, align<2>>
          %101 = builtin.unrealized_conversion_cast %ptr_66 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
          %102 = llvm.load %101 : !llvm.ptr -> i8
          %103 = llvm.icmp "ne" %102, %14 : i8
          scf.if %103 {
            %107 = arith.muli %58, %c3_i64 : i64
            %108 = arith.addi %107, %c2_i64 : i64
            %int_tuple_68 = cute.make_int_tuple(%108) : (i64) -> !cute.int_tuple<"?{i64}">
            %ptr_69 = cute.add_offset(%ptr_21, %int_tuple_68) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
            %ptr_70 = cute.add_offset(%iter_31, %1) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<f32, rmem, align<8>>
            %109 = builtin.unrealized_conversion_cast %ptr_69 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
            %110 = builtin.unrealized_conversion_cast %ptr_70 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
            %111 = llvm.load %109 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
            llvm.store %111, %110 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          }
          %ptr_67 = cute.add_offset(%iter_38, %0) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<i8, rmem>
          %104 = builtin.unrealized_conversion_cast %ptr_67 : !cute.ptr<i8, rmem> to !llvm.ptr
          %105 = llvm.load %104 : !llvm.ptr -> i8
          %106 = llvm.icmp "ne" %105, %14 : i8
          scf.if %106 {
            %107 = arith.muli %58, %c3_i64 : i64
            %108 = arith.addi %107, %c3_i64 : i64
            %iv_68 = cute.assume(%108) : (i64) -> !cute.i64<divby 3>
            %int_tuple_69 = cute.make_int_tuple(%iv_68) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
            %ptr_70 = cute.add_offset(%ptr_21, %int_tuple_69) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
            %ptr_71 = cute.add_offset(%iter_31, %0) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<f32, rmem>
            %109 = builtin.unrealized_conversion_cast %ptr_70 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
            %110 = builtin.unrealized_conversion_cast %ptr_71 : !cute.ptr<f32, rmem> to !llvm.ptr
            %111 = llvm.load %109 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
            llvm.store %111, %110 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          }
        } {llvm.loop_annotation = #loop_annotation}
      }
      llvm.inline_asm has_side_effects asm_dialect = att "griddepcontrol.wait;", ""  : () -> ()
      scf.for %arg6 = %c0_i32 to %c10_i32 step %c1_i32  : i32 {
        %append_45 = cute.append_to_rank<2> (%lay_18, %19) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">
        %54 = cute.get_scalars(%append_45) <{only_dynamic}> : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
        %stride_46 = cute.make_stride(%54) : (i64) -> !cute.stride<"((0,(1,?{i64})),(0,0))">
        %lay_47 = cute.make_layout(%18, %stride_46) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
        %append_48 = cute.append_to_rank<2> (%lay_47, %19) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">, !cute.layout<"1:0">
        %55 = cute.get_scalars(%append_48) <{only_dynamic}> : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
        %stride_49 = cute.make_stride(%55) : (i64) -> !cute.stride<"((0,(1,?{i64})),((0,0)))">
        %lay_50 = cute.make_layout(%17, %stride_49) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
        %56 = cute.get_scalars(%16) : !cute.int_tuple<"1">
        scf.for %arg7 = %c0_i32 to %56 step %c1_i32  : i32 {
          %57 = cute.get_scalars(%lay_50) <{only_dynamic}> : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
          %stride_51 = cute.make_stride(%57) : (i64) -> !cute.stride<"((0,(1,?{i64})))">
          %lay_52 = cute.make_layout(%15, %stride_51) : !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
          %58 = cute.get_scalars(%lay_52) <{only_dynamic}> : !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
          %59 = builtin.unrealized_conversion_cast %iter_38 : !cute.ptr<i8, rmem, align<32>> to !llvm.ptr
          %60 = llvm.load %59 : !llvm.ptr -> i8
          %61 = llvm.icmp "ne" %60, %14 : i8
          scf.if %61 {
            %107 = builtin.unrealized_conversion_cast %ptr_16 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
            %108 = builtin.unrealized_conversion_cast %iter_29 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
            %109 = llvm.load %107 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
            llvm.store %109, %108 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          }
          %ptr_53 = cute.add_offset(%iter_38, %16) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
          %62 = builtin.unrealized_conversion_cast %ptr_53 : !cute.ptr<i8, rmem> to !llvm.ptr
          %63 = llvm.load %62 : !llvm.ptr -> i8
          %64 = llvm.icmp "ne" %63, %14 : i8
          scf.if %64 {
            %ptr_68 = cute.add_offset(%ptr_16, %16) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
            %ptr_69 = cute.add_offset(%iter_29, %16) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
            %107 = builtin.unrealized_conversion_cast %ptr_68 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
            %108 = builtin.unrealized_conversion_cast %ptr_69 : !cute.ptr<f32, rmem> to !llvm.ptr
            %109 = llvm.load %107 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
            llvm.store %109, %108 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          }
          %ptr_54 = cute.add_offset(%iter_38, %13) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem, align<2>>
          %65 = builtin.unrealized_conversion_cast %ptr_54 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
          %66 = llvm.load %65 : !llvm.ptr -> i8
          %67 = llvm.icmp "ne" %66, %14 : i8
          scf.if %67 {
            %ptr_68 = cute.add_offset(%ptr_16, %13) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
            %ptr_69 = cute.add_offset(%iter_29, %13) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
            %107 = builtin.unrealized_conversion_cast %ptr_68 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
            %108 = builtin.unrealized_conversion_cast %ptr_69 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
            %109 = llvm.load %107 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
            llvm.store %109, %108 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          }
          %ptr_55 = cute.add_offset(%iter_38, %12) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
          %68 = builtin.unrealized_conversion_cast %ptr_55 : !cute.ptr<i8, rmem> to !llvm.ptr
          %69 = llvm.load %68 : !llvm.ptr -> i8
          %70 = llvm.icmp "ne" %69, %14 : i8
          scf.if %70 {
            %ptr_68 = cute.add_offset(%ptr_16, %12) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
            %ptr_69 = cute.add_offset(%iter_29, %12) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
            %107 = builtin.unrealized_conversion_cast %ptr_68 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
            %108 = builtin.unrealized_conversion_cast %ptr_69 : !cute.ptr<f32, rmem> to !llvm.ptr
            %109 = llvm.load %107 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
            llvm.store %109, %108 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          }
          %ptr_56 = cute.add_offset(%iter_38, %11) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem, align<4>>
          %71 = builtin.unrealized_conversion_cast %ptr_56 : !cute.ptr<i8, rmem, align<4>> to !llvm.ptr
          %72 = llvm.load %71 : !llvm.ptr -> i8
          %73 = llvm.icmp "ne" %72, %14 : i8
          scf.if %73 {
            %int_tuple_68 = cute.make_int_tuple(%58) : (i64) -> !cute.int_tuple<"?{i64}">
            %ptr_69 = cute.add_offset(%ptr_16, %int_tuple_68) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
            %ptr_70 = cute.add_offset(%iter_29, %11) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
            %107 = builtin.unrealized_conversion_cast %ptr_69 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
            %108 = builtin.unrealized_conversion_cast %ptr_70 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
            %109 = llvm.load %107 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
            llvm.store %109, %108 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          }
          %ptr_57 = cute.add_offset(%iter_38, %10) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
          %74 = builtin.unrealized_conversion_cast %ptr_57 : !cute.ptr<i8, rmem> to !llvm.ptr
          %75 = llvm.load %74 : !llvm.ptr -> i8
          %76 = llvm.icmp "ne" %75, %14 : i8
          scf.if %76 {
            %107 = arith.addi %58, %c1_i64 : i64
            %int_tuple_68 = cute.make_int_tuple(%107) : (i64) -> !cute.int_tuple<"?{i64}">
            %ptr_69 = cute.add_offset(%ptr_16, %int_tuple_68) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
            %ptr_70 = cute.add_offset(%iter_29, %10) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<f32, rmem>
            %108 = builtin.unrealized_conversion_cast %ptr_69 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
            %109 = builtin.unrealized_conversion_cast %ptr_70 : !cute.ptr<f32, rmem> to !llvm.ptr
            %110 = llvm.load %108 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
            llvm.store %110, %109 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          }
          %ptr_58 = cute.add_offset(%iter_38, %9) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem, align<2>>
          %77 = builtin.unrealized_conversion_cast %ptr_58 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
          %78 = llvm.load %77 : !llvm.ptr -> i8
          %79 = llvm.icmp "ne" %78, %14 : i8
          scf.if %79 {
            %107 = arith.addi %58, %c2_i64 : i64
            %int_tuple_68 = cute.make_int_tuple(%107) : (i64) -> !cute.int_tuple<"?{i64}">
            %ptr_69 = cute.add_offset(%ptr_16, %int_tuple_68) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
            %ptr_70 = cute.add_offset(%iter_29, %9) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
            %108 = builtin.unrealized_conversion_cast %ptr_69 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
            %109 = builtin.unrealized_conversion_cast %ptr_70 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
            %110 = llvm.load %108 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
            llvm.store %110, %109 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          }
          %ptr_59 = cute.add_offset(%iter_38, %8) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
          %80 = builtin.unrealized_conversion_cast %ptr_59 : !cute.ptr<i8, rmem> to !llvm.ptr
          %81 = llvm.load %80 : !llvm.ptr -> i8
          %82 = llvm.icmp "ne" %81, %14 : i8
          scf.if %82 {
            %107 = arith.addi %58, %c3_i64 : i64
            %int_tuple_68 = cute.make_int_tuple(%107) : (i64) -> !cute.int_tuple<"?{i64}">
            %ptr_69 = cute.add_offset(%ptr_16, %int_tuple_68) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
            %ptr_70 = cute.add_offset(%iter_29, %8) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<f32, rmem>
            %108 = builtin.unrealized_conversion_cast %ptr_69 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
            %109 = builtin.unrealized_conversion_cast %ptr_70 : !cute.ptr<f32, rmem> to !llvm.ptr
            %110 = llvm.load %108 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
            llvm.store %110, %109 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          }
          %ptr_60 = cute.add_offset(%iter_38, %7) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<i8, rmem, align<8>>
          %83 = builtin.unrealized_conversion_cast %ptr_60 : !cute.ptr<i8, rmem, align<8>> to !llvm.ptr
          %84 = llvm.load %83 : !llvm.ptr -> i8
          %85 = llvm.icmp "ne" %84, %14 : i8
          scf.if %85 {
            %107 = arith.muli %58, %c2_i64 : i64
            %iv_68 = cute.assume(%107) : (i64) -> !cute.i64<divby 2>
            %int_tuple_69 = cute.make_int_tuple(%iv_68) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
            %ptr_70 = cute.add_offset(%ptr_16, %int_tuple_69) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
            %ptr_71 = cute.add_offset(%iter_29, %7) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<f32, rmem, align<32>>
            %108 = builtin.unrealized_conversion_cast %ptr_70 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
            %109 = builtin.unrealized_conversion_cast %ptr_71 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
            %110 = llvm.load %108 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
            llvm.store %110, %109 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          }
          %ptr_61 = cute.add_offset(%iter_38, %6) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<i8, rmem>
          %86 = builtin.unrealized_conversion_cast %ptr_61 : !cute.ptr<i8, rmem> to !llvm.ptr
          %87 = llvm.load %86 : !llvm.ptr -> i8
          %88 = llvm.icmp "ne" %87, %14 : i8
          scf.if %88 {
            %107 = arith.muli %58, %c2_i64 : i64
            %108 = arith.addi %107, %c1_i64 : i64
            %int_tuple_68 = cute.make_int_tuple(%108) : (i64) -> !cute.int_tuple<"?{i64}">
            %ptr_69 = cute.add_offset(%ptr_16, %int_tuple_68) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
            %ptr_70 = cute.add_offset(%iter_29, %6) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<f32, rmem>
            %109 = builtin.unrealized_conversion_cast %ptr_69 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
            %110 = builtin.unrealized_conversion_cast %ptr_70 : !cute.ptr<f32, rmem> to !llvm.ptr
            %111 = llvm.load %109 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
            llvm.store %111, %110 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          }
          %ptr_62 = cute.add_offset(%iter_38, %5) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<i8, rmem, align<2>>
          %89 = builtin.unrealized_conversion_cast %ptr_62 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
          %90 = llvm.load %89 : !llvm.ptr -> i8
          %91 = llvm.icmp "ne" %90, %14 : i8
          scf.if %91 {
            %107 = arith.muli %58, %c2_i64 : i64
            %108 = arith.addi %107, %c2_i64 : i64
            %iv_68 = cute.assume(%108) : (i64) -> !cute.i64<divby 2>
            %int_tuple_69 = cute.make_int_tuple(%iv_68) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
            %ptr_70 = cute.add_offset(%ptr_16, %int_tuple_69) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
            %ptr_71 = cute.add_offset(%iter_29, %5) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<f32, rmem, align<8>>
            %109 = builtin.unrealized_conversion_cast %ptr_70 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
            %110 = builtin.unrealized_conversion_cast %ptr_71 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
            %111 = llvm.load %109 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
            llvm.store %111, %110 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          }
          %ptr_63 = cute.add_offset(%iter_38, %4) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<i8, rmem>
          %92 = builtin.unrealized_conversion_cast %ptr_63 : !cute.ptr<i8, rmem> to !llvm.ptr
          %93 = llvm.load %92 : !llvm.ptr -> i8
          %94 = llvm.icmp "ne" %93, %14 : i8
          scf.if %94 {
            %107 = arith.muli %58, %c2_i64 : i64
            %108 = arith.addi %107, %c3_i64 : i64
            %int_tuple_68 = cute.make_int_tuple(%108) : (i64) -> !cute.int_tuple<"?{i64}">
            %ptr_69 = cute.add_offset(%ptr_16, %int_tuple_68) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
            %ptr_70 = cute.add_offset(%iter_29, %4) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<f32, rmem>
            %109 = builtin.unrealized_conversion_cast %ptr_69 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
            %110 = builtin.unrealized_conversion_cast %ptr_70 : !cute.ptr<f32, rmem> to !llvm.ptr
            %111 = llvm.load %109 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
            llvm.store %111, %110 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          }
          %ptr_64 = cute.add_offset(%iter_38, %3) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<i8, rmem, align<4>>
          %95 = builtin.unrealized_conversion_cast %ptr_64 : !cute.ptr<i8, rmem, align<4>> to !llvm.ptr
          %96 = llvm.load %95 : !llvm.ptr -> i8
          %97 = llvm.icmp "ne" %96, %14 : i8
          scf.if %97 {
            %107 = arith.muli %58, %c3_i64 : i64
            %iv_68 = cute.assume(%107) : (i64) -> !cute.i64<divby 3>
            %int_tuple_69 = cute.make_int_tuple(%iv_68) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
            %ptr_70 = cute.add_offset(%ptr_16, %int_tuple_69) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
            %ptr_71 = cute.add_offset(%iter_29, %3) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<f32, rmem, align<16>>
            %108 = builtin.unrealized_conversion_cast %ptr_70 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
            %109 = builtin.unrealized_conversion_cast %ptr_71 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
            %110 = llvm.load %108 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
            llvm.store %110, %109 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          }
          %ptr_65 = cute.add_offset(%iter_38, %2) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<i8, rmem>
          %98 = builtin.unrealized_conversion_cast %ptr_65 : !cute.ptr<i8, rmem> to !llvm.ptr
          %99 = llvm.load %98 : !llvm.ptr -> i8
          %100 = llvm.icmp "ne" %99, %14 : i8
          scf.if %100 {
            %107 = arith.muli %58, %c3_i64 : i64
            %108 = arith.addi %107, %c1_i64 : i64
            %int_tuple_68 = cute.make_int_tuple(%108) : (i64) -> !cute.int_tuple<"?{i64}">
            %ptr_69 = cute.add_offset(%ptr_16, %int_tuple_68) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
            %ptr_70 = cute.add_offset(%iter_29, %2) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<f32, rmem>
            %109 = builtin.unrealized_conversion_cast %ptr_69 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
            %110 = builtin.unrealized_conversion_cast %ptr_70 : !cute.ptr<f32, rmem> to !llvm.ptr
            %111 = llvm.load %109 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
            llvm.store %111, %110 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          }
          %ptr_66 = cute.add_offset(%iter_38, %1) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<i8, rmem, align<2>>
          %101 = builtin.unrealized_conversion_cast %ptr_66 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
          %102 = llvm.load %101 : !llvm.ptr -> i8
          %103 = llvm.icmp "ne" %102, %14 : i8
          scf.if %103 {
            %107 = arith.muli %58, %c3_i64 : i64
            %108 = arith.addi %107, %c2_i64 : i64
            %int_tuple_68 = cute.make_int_tuple(%108) : (i64) -> !cute.int_tuple<"?{i64}">
            %ptr_69 = cute.add_offset(%ptr_16, %int_tuple_68) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
            %ptr_70 = cute.add_offset(%iter_29, %1) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<f32, rmem, align<8>>
            %109 = builtin.unrealized_conversion_cast %ptr_69 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
            %110 = builtin.unrealized_conversion_cast %ptr_70 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
            %111 = llvm.load %109 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
            llvm.store %111, %110 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          }
          %ptr_67 = cute.add_offset(%iter_38, %0) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<i8, rmem>
          %104 = builtin.unrealized_conversion_cast %ptr_67 : !cute.ptr<i8, rmem> to !llvm.ptr
          %105 = llvm.load %104 : !llvm.ptr -> i8
          %106 = llvm.icmp "ne" %105, %14 : i8
          scf.if %106 {
            %107 = arith.muli %58, %c3_i64 : i64
            %108 = arith.addi %107, %c3_i64 : i64
            %iv_68 = cute.assume(%108) : (i64) -> !cute.i64<divby 3>
            %int_tuple_69 = cute.make_int_tuple(%iv_68) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
            %ptr_70 = cute.add_offset(%ptr_16, %int_tuple_69) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
            %ptr_71 = cute.add_offset(%iter_29, %0) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<f32, rmem>
            %109 = builtin.unrealized_conversion_cast %ptr_70 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
            %110 = builtin.unrealized_conversion_cast %ptr_71 : !cute.ptr<f32, rmem> to !llvm.ptr
            %111 = llvm.load %109 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
            llvm.store %111, %110 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
          }
        } {llvm.loop_annotation = #loop_annotation}
      }
      scf.for %arg6 = %c0_i32 to %c10_i32 step %c1_i32  : i32 {
        %54 = cute.memref.load_vec %rmem : !memref_rmem_f32_
        %55 = cute.memref.load_vec %rmem_30 : !memref_rmem_f32_
        %56 = arith.addf %54, %55 : vector<16xf32>
        cute.memref.store_vec %56, %rmem_32 : !memref_rmem_f32_
      }
      %iter_39 = cute.get_iter(%rmem_32) : !memref_rmem_f32_
      %append = cute.append_to_rank<2> (%lay_28, %19) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">
      %51 = cute.get_scalars(%append) <{only_dynamic}> : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %stride_40 = cute.make_stride(%51) : (i64) -> !cute.stride<"((0,(1,?{i64})),(0,0))">
      %lay_41 = cute.make_layout(%18, %stride_40) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %append_42 = cute.append_to_rank<2> (%lay_41, %19) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">, !cute.layout<"1:0">
      %52 = cute.get_scalars(%append_42) <{only_dynamic}> : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %stride_43 = cute.make_stride(%52) : (i64) -> !cute.stride<"((0,(1,?{i64})),((0,0)))">
      %lay_44 = cute.make_layout(%17, %stride_43) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
      %53 = cute.get_scalars(%16) : !cute.int_tuple<"1">
      scf.for %arg6 = %c0_i32 to %53 step %c1_i32  : i32 {
        %54 = cute.get_scalars(%lay_44) <{only_dynamic}> : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
        %stride_45 = cute.make_stride(%54) : (i64) -> !cute.stride<"((0,(1,?{i64})))">
        %lay_46 = cute.make_layout(%15, %stride_45) : !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
        %55 = cute.get_scalars(%lay_46) <{only_dynamic}> : !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
        %56 = builtin.unrealized_conversion_cast %iter_38 : !cute.ptr<i8, rmem, align<32>> to !llvm.ptr
        %57 = llvm.load %56 : !llvm.ptr -> i8
        %58 = llvm.icmp "ne" %57, %14 : i8
        scf.if %58 {
          %104 = builtin.unrealized_conversion_cast %iter_39 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
          %105 = builtin.unrealized_conversion_cast %ptr_26 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %106 = llvm.load %104 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %106, %105 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %ptr_47 = cute.add_offset(%iter_38, %16) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
        %59 = builtin.unrealized_conversion_cast %ptr_47 : !cute.ptr<i8, rmem> to !llvm.ptr
        %60 = llvm.load %59 : !llvm.ptr -> i8
        %61 = llvm.icmp "ne" %60, %14 : i8
        scf.if %61 {
          %ptr_62 = cute.add_offset(%iter_39, %16) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
          %ptr_63 = cute.add_offset(%ptr_26, %16) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
          %104 = builtin.unrealized_conversion_cast %ptr_62 : !cute.ptr<f32, rmem> to !llvm.ptr
          %105 = builtin.unrealized_conversion_cast %ptr_63 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %106 = llvm.load %104 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %106, %105 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %ptr_48 = cute.add_offset(%iter_38, %13) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem, align<2>>
        %62 = builtin.unrealized_conversion_cast %ptr_48 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
        %63 = llvm.load %62 : !llvm.ptr -> i8
        %64 = llvm.icmp "ne" %63, %14 : i8
        scf.if %64 {
          %ptr_62 = cute.add_offset(%iter_39, %13) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
          %ptr_63 = cute.add_offset(%ptr_26, %13) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
          %104 = builtin.unrealized_conversion_cast %ptr_62 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %105 = builtin.unrealized_conversion_cast %ptr_63 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %106 = llvm.load %104 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %106, %105 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %ptr_49 = cute.add_offset(%iter_38, %12) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
        %65 = builtin.unrealized_conversion_cast %ptr_49 : !cute.ptr<i8, rmem> to !llvm.ptr
        %66 = llvm.load %65 : !llvm.ptr -> i8
        %67 = llvm.icmp "ne" %66, %14 : i8
        scf.if %67 {
          %ptr_62 = cute.add_offset(%iter_39, %12) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
          %ptr_63 = cute.add_offset(%ptr_26, %12) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
          %104 = builtin.unrealized_conversion_cast %ptr_62 : !cute.ptr<f32, rmem> to !llvm.ptr
          %105 = builtin.unrealized_conversion_cast %ptr_63 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %106 = llvm.load %104 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %106, %105 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %ptr_50 = cute.add_offset(%iter_38, %11) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem, align<4>>
        %68 = builtin.unrealized_conversion_cast %ptr_50 : !cute.ptr<i8, rmem, align<4>> to !llvm.ptr
        %69 = llvm.load %68 : !llvm.ptr -> i8
        %70 = llvm.icmp "ne" %69, %14 : i8
        scf.if %70 {
          %ptr_62 = cute.add_offset(%iter_39, %11) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
          %int_tuple_63 = cute.make_int_tuple(%55) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_64 = cute.add_offset(%ptr_26, %int_tuple_63) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %104 = builtin.unrealized_conversion_cast %ptr_62 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
          %105 = builtin.unrealized_conversion_cast %ptr_64 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %106 = llvm.load %104 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %106, %105 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %ptr_51 = cute.add_offset(%iter_38, %10) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
        %71 = builtin.unrealized_conversion_cast %ptr_51 : !cute.ptr<i8, rmem> to !llvm.ptr
        %72 = llvm.load %71 : !llvm.ptr -> i8
        %73 = llvm.icmp "ne" %72, %14 : i8
        scf.if %73 {
          %ptr_62 = cute.add_offset(%iter_39, %10) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<f32, rmem>
          %104 = arith.addi %55, %c1_i64 : i64
          %int_tuple_63 = cute.make_int_tuple(%104) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_64 = cute.add_offset(%ptr_26, %int_tuple_63) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %105 = builtin.unrealized_conversion_cast %ptr_62 : !cute.ptr<f32, rmem> to !llvm.ptr
          %106 = builtin.unrealized_conversion_cast %ptr_64 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %107 = llvm.load %105 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %107, %106 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %ptr_52 = cute.add_offset(%iter_38, %9) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem, align<2>>
        %74 = builtin.unrealized_conversion_cast %ptr_52 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
        %75 = llvm.load %74 : !llvm.ptr -> i8
        %76 = llvm.icmp "ne" %75, %14 : i8
        scf.if %76 {
          %ptr_62 = cute.add_offset(%iter_39, %9) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
          %104 = arith.addi %55, %c2_i64 : i64
          %int_tuple_63 = cute.make_int_tuple(%104) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_64 = cute.add_offset(%ptr_26, %int_tuple_63) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %105 = builtin.unrealized_conversion_cast %ptr_62 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %106 = builtin.unrealized_conversion_cast %ptr_64 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %107 = llvm.load %105 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %107, %106 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %ptr_53 = cute.add_offset(%iter_38, %8) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
        %77 = builtin.unrealized_conversion_cast %ptr_53 : !cute.ptr<i8, rmem> to !llvm.ptr
        %78 = llvm.load %77 : !llvm.ptr -> i8
        %79 = llvm.icmp "ne" %78, %14 : i8
        scf.if %79 {
          %ptr_62 = cute.add_offset(%iter_39, %8) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<f32, rmem>
          %104 = arith.addi %55, %c3_i64 : i64
          %int_tuple_63 = cute.make_int_tuple(%104) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_64 = cute.add_offset(%ptr_26, %int_tuple_63) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %105 = builtin.unrealized_conversion_cast %ptr_62 : !cute.ptr<f32, rmem> to !llvm.ptr
          %106 = builtin.unrealized_conversion_cast %ptr_64 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %107 = llvm.load %105 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %107, %106 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %ptr_54 = cute.add_offset(%iter_38, %7) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<i8, rmem, align<8>>
        %80 = builtin.unrealized_conversion_cast %ptr_54 : !cute.ptr<i8, rmem, align<8>> to !llvm.ptr
        %81 = llvm.load %80 : !llvm.ptr -> i8
        %82 = llvm.icmp "ne" %81, %14 : i8
        scf.if %82 {
          %ptr_62 = cute.add_offset(%iter_39, %7) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<f32, rmem, align<32>>
          %104 = arith.muli %55, %c2_i64 : i64
          %iv_63 = cute.assume(%104) : (i64) -> !cute.i64<divby 2>
          %int_tuple_64 = cute.make_int_tuple(%iv_63) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
          %ptr_65 = cute.add_offset(%ptr_26, %int_tuple_64) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
          %105 = builtin.unrealized_conversion_cast %ptr_62 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
          %106 = builtin.unrealized_conversion_cast %ptr_65 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %107 = llvm.load %105 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %107, %106 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %ptr_55 = cute.add_offset(%iter_38, %6) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<i8, rmem>
        %83 = builtin.unrealized_conversion_cast %ptr_55 : !cute.ptr<i8, rmem> to !llvm.ptr
        %84 = llvm.load %83 : !llvm.ptr -> i8
        %85 = llvm.icmp "ne" %84, %14 : i8
        scf.if %85 {
          %ptr_62 = cute.add_offset(%iter_39, %6) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<f32, rmem>
          %104 = arith.muli %55, %c2_i64 : i64
          %105 = arith.addi %104, %c1_i64 : i64
          %int_tuple_63 = cute.make_int_tuple(%105) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_64 = cute.add_offset(%ptr_26, %int_tuple_63) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %106 = builtin.unrealized_conversion_cast %ptr_62 : !cute.ptr<f32, rmem> to !llvm.ptr
          %107 = builtin.unrealized_conversion_cast %ptr_64 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %108 = llvm.load %106 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %108, %107 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %ptr_56 = cute.add_offset(%iter_38, %5) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<i8, rmem, align<2>>
        %86 = builtin.unrealized_conversion_cast %ptr_56 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
        %87 = llvm.load %86 : !llvm.ptr -> i8
        %88 = llvm.icmp "ne" %87, %14 : i8
        scf.if %88 {
          %ptr_62 = cute.add_offset(%iter_39, %5) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<f32, rmem, align<8>>
          %104 = arith.muli %55, %c2_i64 : i64
          %105 = arith.addi %104, %c2_i64 : i64
          %iv_63 = cute.assume(%105) : (i64) -> !cute.i64<divby 2>
          %int_tuple_64 = cute.make_int_tuple(%iv_63) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
          %ptr_65 = cute.add_offset(%ptr_26, %int_tuple_64) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
          %106 = builtin.unrealized_conversion_cast %ptr_62 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %107 = builtin.unrealized_conversion_cast %ptr_65 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %108 = llvm.load %106 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %108, %107 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %ptr_57 = cute.add_offset(%iter_38, %4) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<i8, rmem>
        %89 = builtin.unrealized_conversion_cast %ptr_57 : !cute.ptr<i8, rmem> to !llvm.ptr
        %90 = llvm.load %89 : !llvm.ptr -> i8
        %91 = llvm.icmp "ne" %90, %14 : i8
        scf.if %91 {
          %ptr_62 = cute.add_offset(%iter_39, %4) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<f32, rmem>
          %104 = arith.muli %55, %c2_i64 : i64
          %105 = arith.addi %104, %c3_i64 : i64
          %int_tuple_63 = cute.make_int_tuple(%105) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_64 = cute.add_offset(%ptr_26, %int_tuple_63) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %106 = builtin.unrealized_conversion_cast %ptr_62 : !cute.ptr<f32, rmem> to !llvm.ptr
          %107 = builtin.unrealized_conversion_cast %ptr_64 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %108 = llvm.load %106 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %108, %107 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %ptr_58 = cute.add_offset(%iter_38, %3) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<i8, rmem, align<4>>
        %92 = builtin.unrealized_conversion_cast %ptr_58 : !cute.ptr<i8, rmem, align<4>> to !llvm.ptr
        %93 = llvm.load %92 : !llvm.ptr -> i8
        %94 = llvm.icmp "ne" %93, %14 : i8
        scf.if %94 {
          %ptr_62 = cute.add_offset(%iter_39, %3) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<f32, rmem, align<16>>
          %104 = arith.muli %55, %c3_i64 : i64
          %iv_63 = cute.assume(%104) : (i64) -> !cute.i64<divby 3>
          %int_tuple_64 = cute.make_int_tuple(%iv_63) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
          %ptr_65 = cute.add_offset(%ptr_26, %int_tuple_64) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
          %105 = builtin.unrealized_conversion_cast %ptr_62 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
          %106 = builtin.unrealized_conversion_cast %ptr_65 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %107 = llvm.load %105 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %107, %106 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %ptr_59 = cute.add_offset(%iter_38, %2) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<i8, rmem>
        %95 = builtin.unrealized_conversion_cast %ptr_59 : !cute.ptr<i8, rmem> to !llvm.ptr
        %96 = llvm.load %95 : !llvm.ptr -> i8
        %97 = llvm.icmp "ne" %96, %14 : i8
        scf.if %97 {
          %ptr_62 = cute.add_offset(%iter_39, %2) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<f32, rmem>
          %104 = arith.muli %55, %c3_i64 : i64
          %105 = arith.addi %104, %c1_i64 : i64
          %int_tuple_63 = cute.make_int_tuple(%105) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_64 = cute.add_offset(%ptr_26, %int_tuple_63) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %106 = builtin.unrealized_conversion_cast %ptr_62 : !cute.ptr<f32, rmem> to !llvm.ptr
          %107 = builtin.unrealized_conversion_cast %ptr_64 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %108 = llvm.load %106 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %108, %107 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %ptr_60 = cute.add_offset(%iter_38, %1) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<i8, rmem, align<2>>
        %98 = builtin.unrealized_conversion_cast %ptr_60 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
        %99 = llvm.load %98 : !llvm.ptr -> i8
        %100 = llvm.icmp "ne" %99, %14 : i8
        scf.if %100 {
          %ptr_62 = cute.add_offset(%iter_39, %1) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<f32, rmem, align<8>>
          %104 = arith.muli %55, %c3_i64 : i64
          %105 = arith.addi %104, %c2_i64 : i64
          %int_tuple_63 = cute.make_int_tuple(%105) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_64 = cute.add_offset(%ptr_26, %int_tuple_63) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %106 = builtin.unrealized_conversion_cast %ptr_62 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %107 = builtin.unrealized_conversion_cast %ptr_64 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %108 = llvm.load %106 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %108, %107 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %ptr_61 = cute.add_offset(%iter_38, %0) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<i8, rmem>
        %101 = builtin.unrealized_conversion_cast %ptr_61 : !cute.ptr<i8, rmem> to !llvm.ptr
        %102 = llvm.load %101 : !llvm.ptr -> i8
        %103 = llvm.icmp "ne" %102, %14 : i8
        scf.if %103 {
          %ptr_62 = cute.add_offset(%iter_39, %0) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<f32, rmem>
          %104 = arith.muli %55, %c3_i64 : i64
          %105 = arith.addi %104, %c3_i64 : i64
          %iv_63 = cute.assume(%105) : (i64) -> !cute.i64<divby 3>
          %int_tuple_64 = cute.make_int_tuple(%iv_63) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
          %ptr_65 = cute.add_offset(%ptr_26, %int_tuple_64) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
          %106 = builtin.unrealized_conversion_cast %ptr_62 : !cute.ptr<f32, rmem> to !llvm.ptr
          %107 = builtin.unrealized_conversion_cast %ptr_65 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %108 = llvm.load %106 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %108, %107 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
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
    %15 = cute.get_shape(%lay_9) : (!cute.layout<"(?,?):(?{i64},1)">) -> !cute.shape<"(?,?)">
    %e0, %e1 = cute.get_leaves(%15) : !cute.shape<"(?,?)">
    %itup = cute.to_int_tuple(%e0) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %16 = cute.get_scalars(%itup) : !cute.int_tuple<"?">
    %itup_15 = cute.to_int_tuple(%e1) : !cute.shape<"?"> to !cute.int_tuple<"?">
    %17 = cute.get_scalars(%itup_15) : !cute.int_tuple<"?">
    %shape_16 = cute.make_shape(%itup, %itup_15) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.shape<"(?,?)">
    %lay_17 = cute.make_layout(%shape_16, %1) : !cute.layout<"(?,?):(1@0,1@1)">
    %18:2 = cute.get_scalars(%lay_17) <{only_dynamic}> : !cute.layout<"(?,?):(1@0,1@1)">
    %19 = arith.ceildivsi %18#0, %c16_i32 : i32
    %20 = arith.ceildivsi %18#1, %c128_i32 : i32
    %shape_18 = cute.make_shape(%19, %20) : (i32, i32) -> !cute.shape<"((16,128),(?,?))">
    %lay_19 = cute.make_layout(%shape_18, %0) : !cute.layout<"((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
    %view_20 = cute.make_view(%2, %lay_19) : !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">
    %sz = cute.size(%lay_13) <{mode = [1]}> : (!cute.layout<"((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">) -> !cute.int_tuple<"?">
    %e0_21 = cute.get_leaves(%sz) : !cute.int_tuple<"?">
    %21 = cute.get_scalars(%e0_21) : !cute.int_tuple<"?">
    %22 = cuda.launch_cfg.create<max_attrs = 2 : i32> (blockDim = (%c128_i32, %c1_i32, %c1_i32), dynamicSmemBytes = %c0_i64, gridDim = (%21, %c1_i32, %c1_i32), stream = %arg3) : i32, i32, i32, i64, i32, i32, i32, !cuda.stream -> !cuda.launch_cfg<max_attrs = 2>
    %23 = cuda.launch_ex @kernels::@kernel_cutlass_elementwise_add_kernel_tensorptrf32gmemo161281i64div16128_tensorptrf32gmemo161281i64div16128_tensorptrf32gmemo161281i64div16128_tensor00o1612810111601281___False_0<%22> (%view, %view_7, %view_14, %view_20, %16, %17) : !cuda.launch_cfg<max_attrs = 2>, (!memref_gmem_f32_, !memref_gmem_f32_, !memref_gmem_f32_, !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">, i32, i32) -> !cuda.result
    %24 = cuda.cast %23 : !cuda.result -> i32
    cuda.return_if_error %24 : i32
    return %c0_i32 : i32
  }
}
