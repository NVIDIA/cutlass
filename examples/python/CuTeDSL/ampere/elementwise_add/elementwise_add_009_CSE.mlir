!copy_simt = !cute.tiled_copy<!cute_nvgpu.atom.universal_copy<f32>, layout_copy_tv = <"((32,4),(4,4)):((64,4),(16,1))">, tiler_mn = <"[16:1;128:1]">>
!memref_gmem_f32_ = !cute.memref<f32, gmem, "((16,128),(?,?)):((?{i64},1),(?{i64 div=16},128))">
!memref_gmem_f32_1 = !cute.memref<f32, gmem, "(?,?):(?{i64},1)">
!memref_rmem_f32_ = !cute.memref<f32, rmem, align<32>, "((1,(4,4)),1,1):((0,(1,4)),0,0)">
!memref_rmem_i8_ = !cute.memref<i8, rmem, align<32>, "((1,(4,4)),1,1):((0,(1,4)),0,0)">
#loop_unroll = #llvm.loop_unroll<disable = false, full = true>
#loop_annotation = #llvm.loop_annotation<unroll = #loop_unroll>
module attributes {gpu.container_module} {
  gpu.module @kernels {
    func.func public @kernel_cutlass_elementwise_add_kernel_tensorptrf32gmemo161281div16128_tensorptrf32gmemo161281div16128_tensorptrf32gmemo161281div16128_tensor00o1612810111601281___0(%arg0: !memref_gmem_f32_, %arg1: !memref_gmem_f32_, %arg2: !memref_gmem_f32_, %arg3: !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">, %arg4: i32, %arg5: i32) attributes {cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} {
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
      %iter_33 = cute.get_iter(%rmem_32) : !memref_rmem_f32_
      %50 = arith.muli %35, %c4_i32 : i32
      %iv_34 = cute.assume(%50) : (i32) -> !cute.i32<divby 4>
      %iv_35 = cute.assume(%37) : (i32) -> !cute.i32<divby 4>
      %int_tuple_36 = cute.make_int_tuple(%iv_34, %iv_35) : (!cute.i32<divby 4>, !cute.i32<divby 4>) -> !cute.int_tuple<"(?{div=4},?{div=4})">
      %tup_37 = cute.add_offset(%tup, %int_tuple_36) : (!cute.int_tuple<"(?{div=16},?{div=128})">, !cute.int_tuple<"(?{div=4},?{div=4})">) -> !cute.int_tuple<"(?{div=4},?{div=4})">
      %rmem_38 = cute.memref.alloca() : !memref_rmem_i8_
      scf.for %arg6 = %c0_i32 to %c16_i32 step %c1_i32  : i32 {
        %coord_57 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"?">
        %idx_58 = cute.crd2idx(%coord_57, %20) : (!cute.coord<"?">, !cute.layout<"((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">) -> !cute.int_tuple<"(?,?)">
        %tup_59 = cute.add_offset(%tup_37, %idx_58) : (!cute.int_tuple<"(?{div=4},?{div=4})">, !cute.int_tuple<"(?,?)">) -> !cute.int_tuple<"(?,?)">
        %e0, %e1 = cute.get_leaves(%tup_59) : !cute.int_tuple<"(?,?)">
        %coord_60 = cute.make_coord(%e0, %e1) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
        %coord_61 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
        %61:2 = cute.get_scalars(%coord_60) : !cute.coord<"(?,?)">
        %62:2 = cute.get_scalars(%coord_61) : !cute.coord<"(?,?)">
        %63 = arith.cmpi slt, %61#0, %62#0 : i32
        %64 = arith.cmpi slt, %61#1, %62#1 : i32
        %65 = arith.andi %63, %64 : i1
        %66 = arith.extui %65 : i1 to i8
        cute.memref.store(%rmem_38, %coord_57, %66) : (!memref_rmem_i8_, !cute.coord<"?">, i8) -> ()
      }
      %iter_39 = cute.get_iter(%rmem_38) : !memref_rmem_i8_
      %append = cute.append_to_rank<2> (%lay_18, %19) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">
      %51 = cute.get_scalars(%append) <{only_dynamic}> : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %stride_40 = cute.make_stride(%51) : (i64) -> !cute.stride<"((0,(1,?{i64})),(0,0))">
      %lay_41 = cute.make_layout(%18, %stride_40) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %append_42 = cute.append_to_rank<2> (%lay_41, %19) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">, !cute.layout<"1:0">
      %52 = cute.get_scalars(%append_42) <{only_dynamic}> : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %stride_43 = cute.make_stride(%52) : (i64) -> !cute.stride<"((0,(1,?{i64})),((0,0)))">
      %lay_44 = cute.make_layout(%17, %stride_43) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
      %53 = cute.get_scalars(%16) : !cute.int_tuple<"1">
      scf.for %arg6 = %c0_i32 to %53 step %c1_i32  : i32 {
        %61 = cute.get_scalars(%lay_44) <{only_dynamic}> : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
        %stride_57 = cute.make_stride(%61) : (i64) -> !cute.stride<"((0,(1,?{i64})))">
        %lay_58 = cute.make_layout(%15, %stride_57) : !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
        %62 = cute.get_scalars(%lay_58) <{only_dynamic}> : !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
        %63 = builtin.unrealized_conversion_cast %iter_39 : !cute.ptr<i8, rmem, align<32>> to !llvm.ptr
        %64 = llvm.load %63 : !llvm.ptr -> i8
        %65 = llvm.icmp "ne" %64, %14 : i8
        scf.if %65 {
          %111 = builtin.unrealized_conversion_cast %ptr_16 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %112 = builtin.unrealized_conversion_cast %iter_29 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
          %113 = llvm.load %111 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %113, %112 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %ptr_59 = cute.add_offset(%iter_39, %16) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
        %66 = builtin.unrealized_conversion_cast %ptr_59 : !cute.ptr<i8, rmem> to !llvm.ptr
        %67 = llvm.load %66 : !llvm.ptr -> i8
        %68 = llvm.icmp "ne" %67, %14 : i8
        scf.if %68 {
          %ptr_74 = cute.add_offset(%ptr_16, %16) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
          %ptr_75 = cute.add_offset(%iter_29, %16) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
          %111 = builtin.unrealized_conversion_cast %ptr_74 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %112 = builtin.unrealized_conversion_cast %ptr_75 : !cute.ptr<f32, rmem> to !llvm.ptr
          %113 = llvm.load %111 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %113, %112 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %ptr_60 = cute.add_offset(%iter_39, %13) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem, align<2>>
        %69 = builtin.unrealized_conversion_cast %ptr_60 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
        %70 = llvm.load %69 : !llvm.ptr -> i8
        %71 = llvm.icmp "ne" %70, %14 : i8
        scf.if %71 {
          %ptr_74 = cute.add_offset(%ptr_16, %13) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
          %ptr_75 = cute.add_offset(%iter_29, %13) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
          %111 = builtin.unrealized_conversion_cast %ptr_74 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %112 = builtin.unrealized_conversion_cast %ptr_75 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %113 = llvm.load %111 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %113, %112 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %ptr_61 = cute.add_offset(%iter_39, %12) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
        %72 = builtin.unrealized_conversion_cast %ptr_61 : !cute.ptr<i8, rmem> to !llvm.ptr
        %73 = llvm.load %72 : !llvm.ptr -> i8
        %74 = llvm.icmp "ne" %73, %14 : i8
        scf.if %74 {
          %ptr_74 = cute.add_offset(%ptr_16, %12) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
          %ptr_75 = cute.add_offset(%iter_29, %12) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
          %111 = builtin.unrealized_conversion_cast %ptr_74 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %112 = builtin.unrealized_conversion_cast %ptr_75 : !cute.ptr<f32, rmem> to !llvm.ptr
          %113 = llvm.load %111 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %113, %112 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %ptr_62 = cute.add_offset(%iter_39, %11) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem, align<4>>
        %75 = builtin.unrealized_conversion_cast %ptr_62 : !cute.ptr<i8, rmem, align<4>> to !llvm.ptr
        %76 = llvm.load %75 : !llvm.ptr -> i8
        %77 = llvm.icmp "ne" %76, %14 : i8
        scf.if %77 {
          %int_tuple_74 = cute.make_int_tuple(%62) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_75 = cute.add_offset(%ptr_16, %int_tuple_74) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %ptr_76 = cute.add_offset(%iter_29, %11) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
          %111 = builtin.unrealized_conversion_cast %ptr_75 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %112 = builtin.unrealized_conversion_cast %ptr_76 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
          %113 = llvm.load %111 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %113, %112 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %ptr_63 = cute.add_offset(%iter_39, %10) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
        %78 = builtin.unrealized_conversion_cast %ptr_63 : !cute.ptr<i8, rmem> to !llvm.ptr
        %79 = llvm.load %78 : !llvm.ptr -> i8
        %80 = llvm.icmp "ne" %79, %14 : i8
        scf.if %80 {
          %111 = arith.addi %62, %c1_i64 : i64
          %int_tuple_74 = cute.make_int_tuple(%111) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_75 = cute.add_offset(%ptr_16, %int_tuple_74) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %ptr_76 = cute.add_offset(%iter_29, %10) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<f32, rmem>
          %112 = builtin.unrealized_conversion_cast %ptr_75 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %113 = builtin.unrealized_conversion_cast %ptr_76 : !cute.ptr<f32, rmem> to !llvm.ptr
          %114 = llvm.load %112 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %114, %113 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %ptr_64 = cute.add_offset(%iter_39, %9) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem, align<2>>
        %81 = builtin.unrealized_conversion_cast %ptr_64 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
        %82 = llvm.load %81 : !llvm.ptr -> i8
        %83 = llvm.icmp "ne" %82, %14 : i8
        scf.if %83 {
          %111 = arith.addi %62, %c2_i64 : i64
          %int_tuple_74 = cute.make_int_tuple(%111) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_75 = cute.add_offset(%ptr_16, %int_tuple_74) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %ptr_76 = cute.add_offset(%iter_29, %9) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
          %112 = builtin.unrealized_conversion_cast %ptr_75 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %113 = builtin.unrealized_conversion_cast %ptr_76 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %114 = llvm.load %112 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %114, %113 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %ptr_65 = cute.add_offset(%iter_39, %8) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
        %84 = builtin.unrealized_conversion_cast %ptr_65 : !cute.ptr<i8, rmem> to !llvm.ptr
        %85 = llvm.load %84 : !llvm.ptr -> i8
        %86 = llvm.icmp "ne" %85, %14 : i8
        scf.if %86 {
          %111 = arith.addi %62, %c3_i64 : i64
          %int_tuple_74 = cute.make_int_tuple(%111) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_75 = cute.add_offset(%ptr_16, %int_tuple_74) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %ptr_76 = cute.add_offset(%iter_29, %8) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<f32, rmem>
          %112 = builtin.unrealized_conversion_cast %ptr_75 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %113 = builtin.unrealized_conversion_cast %ptr_76 : !cute.ptr<f32, rmem> to !llvm.ptr
          %114 = llvm.load %112 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %114, %113 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %ptr_66 = cute.add_offset(%iter_39, %7) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<i8, rmem, align<8>>
        %87 = builtin.unrealized_conversion_cast %ptr_66 : !cute.ptr<i8, rmem, align<8>> to !llvm.ptr
        %88 = llvm.load %87 : !llvm.ptr -> i8
        %89 = llvm.icmp "ne" %88, %14 : i8
        scf.if %89 {
          %111 = arith.muli %62, %c2_i64 : i64
          %iv_74 = cute.assume(%111) : (i64) -> !cute.i64<divby 2>
          %int_tuple_75 = cute.make_int_tuple(%iv_74) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
          %ptr_76 = cute.add_offset(%ptr_16, %int_tuple_75) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
          %ptr_77 = cute.add_offset(%iter_29, %7) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<f32, rmem, align<32>>
          %112 = builtin.unrealized_conversion_cast %ptr_76 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %113 = builtin.unrealized_conversion_cast %ptr_77 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
          %114 = llvm.load %112 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %114, %113 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %ptr_67 = cute.add_offset(%iter_39, %6) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<i8, rmem>
        %90 = builtin.unrealized_conversion_cast %ptr_67 : !cute.ptr<i8, rmem> to !llvm.ptr
        %91 = llvm.load %90 : !llvm.ptr -> i8
        %92 = llvm.icmp "ne" %91, %14 : i8
        scf.if %92 {
          %111 = arith.muli %62, %c2_i64 : i64
          %112 = arith.addi %111, %c1_i64 : i64
          %int_tuple_74 = cute.make_int_tuple(%112) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_75 = cute.add_offset(%ptr_16, %int_tuple_74) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %ptr_76 = cute.add_offset(%iter_29, %6) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<f32, rmem>
          %113 = builtin.unrealized_conversion_cast %ptr_75 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %114 = builtin.unrealized_conversion_cast %ptr_76 : !cute.ptr<f32, rmem> to !llvm.ptr
          %115 = llvm.load %113 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %115, %114 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %ptr_68 = cute.add_offset(%iter_39, %5) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<i8, rmem, align<2>>
        %93 = builtin.unrealized_conversion_cast %ptr_68 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
        %94 = llvm.load %93 : !llvm.ptr -> i8
        %95 = llvm.icmp "ne" %94, %14 : i8
        scf.if %95 {
          %111 = arith.muli %62, %c2_i64 : i64
          %112 = arith.addi %111, %c2_i64 : i64
          %iv_74 = cute.assume(%112) : (i64) -> !cute.i64<divby 2>
          %int_tuple_75 = cute.make_int_tuple(%iv_74) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
          %ptr_76 = cute.add_offset(%ptr_16, %int_tuple_75) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
          %ptr_77 = cute.add_offset(%iter_29, %5) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<f32, rmem, align<8>>
          %113 = builtin.unrealized_conversion_cast %ptr_76 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %114 = builtin.unrealized_conversion_cast %ptr_77 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %115 = llvm.load %113 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %115, %114 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %ptr_69 = cute.add_offset(%iter_39, %4) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<i8, rmem>
        %96 = builtin.unrealized_conversion_cast %ptr_69 : !cute.ptr<i8, rmem> to !llvm.ptr
        %97 = llvm.load %96 : !llvm.ptr -> i8
        %98 = llvm.icmp "ne" %97, %14 : i8
        scf.if %98 {
          %111 = arith.muli %62, %c2_i64 : i64
          %112 = arith.addi %111, %c3_i64 : i64
          %int_tuple_74 = cute.make_int_tuple(%112) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_75 = cute.add_offset(%ptr_16, %int_tuple_74) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %ptr_76 = cute.add_offset(%iter_29, %4) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<f32, rmem>
          %113 = builtin.unrealized_conversion_cast %ptr_75 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %114 = builtin.unrealized_conversion_cast %ptr_76 : !cute.ptr<f32, rmem> to !llvm.ptr
          %115 = llvm.load %113 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %115, %114 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %ptr_70 = cute.add_offset(%iter_39, %3) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<i8, rmem, align<4>>
        %99 = builtin.unrealized_conversion_cast %ptr_70 : !cute.ptr<i8, rmem, align<4>> to !llvm.ptr
        %100 = llvm.load %99 : !llvm.ptr -> i8
        %101 = llvm.icmp "ne" %100, %14 : i8
        scf.if %101 {
          %111 = arith.muli %62, %c3_i64 : i64
          %iv_74 = cute.assume(%111) : (i64) -> !cute.i64<divby 3>
          %int_tuple_75 = cute.make_int_tuple(%iv_74) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
          %ptr_76 = cute.add_offset(%ptr_16, %int_tuple_75) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
          %ptr_77 = cute.add_offset(%iter_29, %3) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<f32, rmem, align<16>>
          %112 = builtin.unrealized_conversion_cast %ptr_76 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %113 = builtin.unrealized_conversion_cast %ptr_77 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
          %114 = llvm.load %112 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %114, %113 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %ptr_71 = cute.add_offset(%iter_39, %2) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<i8, rmem>
        %102 = builtin.unrealized_conversion_cast %ptr_71 : !cute.ptr<i8, rmem> to !llvm.ptr
        %103 = llvm.load %102 : !llvm.ptr -> i8
        %104 = llvm.icmp "ne" %103, %14 : i8
        scf.if %104 {
          %111 = arith.muli %62, %c3_i64 : i64
          %112 = arith.addi %111, %c1_i64 : i64
          %int_tuple_74 = cute.make_int_tuple(%112) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_75 = cute.add_offset(%ptr_16, %int_tuple_74) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %ptr_76 = cute.add_offset(%iter_29, %2) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<f32, rmem>
          %113 = builtin.unrealized_conversion_cast %ptr_75 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %114 = builtin.unrealized_conversion_cast %ptr_76 : !cute.ptr<f32, rmem> to !llvm.ptr
          %115 = llvm.load %113 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %115, %114 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %ptr_72 = cute.add_offset(%iter_39, %1) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<i8, rmem, align<2>>
        %105 = builtin.unrealized_conversion_cast %ptr_72 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
        %106 = llvm.load %105 : !llvm.ptr -> i8
        %107 = llvm.icmp "ne" %106, %14 : i8
        scf.if %107 {
          %111 = arith.muli %62, %c3_i64 : i64
          %112 = arith.addi %111, %c2_i64 : i64
          %int_tuple_74 = cute.make_int_tuple(%112) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_75 = cute.add_offset(%ptr_16, %int_tuple_74) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %ptr_76 = cute.add_offset(%iter_29, %1) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<f32, rmem, align<8>>
          %113 = builtin.unrealized_conversion_cast %ptr_75 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %114 = builtin.unrealized_conversion_cast %ptr_76 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %115 = llvm.load %113 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %115, %114 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %ptr_73 = cute.add_offset(%iter_39, %0) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<i8, rmem>
        %108 = builtin.unrealized_conversion_cast %ptr_73 : !cute.ptr<i8, rmem> to !llvm.ptr
        %109 = llvm.load %108 : !llvm.ptr -> i8
        %110 = llvm.icmp "ne" %109, %14 : i8
        scf.if %110 {
          %111 = arith.muli %62, %c3_i64 : i64
          %112 = arith.addi %111, %c3_i64 : i64
          %iv_74 = cute.assume(%112) : (i64) -> !cute.i64<divby 3>
          %int_tuple_75 = cute.make_int_tuple(%iv_74) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
          %ptr_76 = cute.add_offset(%ptr_16, %int_tuple_75) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
          %ptr_77 = cute.add_offset(%iter_29, %0) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<f32, rmem>
          %113 = builtin.unrealized_conversion_cast %ptr_76 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %114 = builtin.unrealized_conversion_cast %ptr_77 : !cute.ptr<f32, rmem> to !llvm.ptr
          %115 = llvm.load %113 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %115, %114 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
      } {llvm.loop_annotation = #loop_annotation}
      %append_45 = cute.append_to_rank<2> (%lay_23, %19) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">
      %54 = cute.get_scalars(%append_45) <{only_dynamic}> : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %stride_46 = cute.make_stride(%54) : (i64) -> !cute.stride<"((0,(1,?{i64})),(0,0))">
      %lay_47 = cute.make_layout(%18, %stride_46) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %append_48 = cute.append_to_rank<2> (%lay_47, %19) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">, !cute.layout<"1:0">
      %55 = cute.get_scalars(%append_48) <{only_dynamic}> : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %stride_49 = cute.make_stride(%55) : (i64) -> !cute.stride<"((0,(1,?{i64})),((0,0)))">
      %lay_50 = cute.make_layout(%17, %stride_49) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
      scf.for %arg6 = %c0_i32 to %53 step %c1_i32  : i32 {
        %61 = cute.get_scalars(%lay_50) <{only_dynamic}> : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
        %stride_57 = cute.make_stride(%61) : (i64) -> !cute.stride<"((0,(1,?{i64})))">
        %lay_58 = cute.make_layout(%15, %stride_57) : !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
        %62 = cute.get_scalars(%lay_58) <{only_dynamic}> : !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
        %63 = builtin.unrealized_conversion_cast %iter_39 : !cute.ptr<i8, rmem, align<32>> to !llvm.ptr
        %64 = llvm.load %63 : !llvm.ptr -> i8
        %65 = llvm.icmp "ne" %64, %14 : i8
        scf.if %65 {
          %111 = builtin.unrealized_conversion_cast %ptr_21 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %112 = builtin.unrealized_conversion_cast %iter_31 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
          %113 = llvm.load %111 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %113, %112 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %ptr_59 = cute.add_offset(%iter_39, %16) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
        %66 = builtin.unrealized_conversion_cast %ptr_59 : !cute.ptr<i8, rmem> to !llvm.ptr
        %67 = llvm.load %66 : !llvm.ptr -> i8
        %68 = llvm.icmp "ne" %67, %14 : i8
        scf.if %68 {
          %ptr_74 = cute.add_offset(%ptr_21, %16) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
          %ptr_75 = cute.add_offset(%iter_31, %16) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
          %111 = builtin.unrealized_conversion_cast %ptr_74 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %112 = builtin.unrealized_conversion_cast %ptr_75 : !cute.ptr<f32, rmem> to !llvm.ptr
          %113 = llvm.load %111 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %113, %112 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %ptr_60 = cute.add_offset(%iter_39, %13) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem, align<2>>
        %69 = builtin.unrealized_conversion_cast %ptr_60 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
        %70 = llvm.load %69 : !llvm.ptr -> i8
        %71 = llvm.icmp "ne" %70, %14 : i8
        scf.if %71 {
          %ptr_74 = cute.add_offset(%ptr_21, %13) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
          %ptr_75 = cute.add_offset(%iter_31, %13) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
          %111 = builtin.unrealized_conversion_cast %ptr_74 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %112 = builtin.unrealized_conversion_cast %ptr_75 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %113 = llvm.load %111 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %113, %112 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %ptr_61 = cute.add_offset(%iter_39, %12) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
        %72 = builtin.unrealized_conversion_cast %ptr_61 : !cute.ptr<i8, rmem> to !llvm.ptr
        %73 = llvm.load %72 : !llvm.ptr -> i8
        %74 = llvm.icmp "ne" %73, %14 : i8
        scf.if %74 {
          %ptr_74 = cute.add_offset(%ptr_21, %12) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
          %ptr_75 = cute.add_offset(%iter_31, %12) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
          %111 = builtin.unrealized_conversion_cast %ptr_74 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %112 = builtin.unrealized_conversion_cast %ptr_75 : !cute.ptr<f32, rmem> to !llvm.ptr
          %113 = llvm.load %111 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %113, %112 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %ptr_62 = cute.add_offset(%iter_39, %11) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem, align<4>>
        %75 = builtin.unrealized_conversion_cast %ptr_62 : !cute.ptr<i8, rmem, align<4>> to !llvm.ptr
        %76 = llvm.load %75 : !llvm.ptr -> i8
        %77 = llvm.icmp "ne" %76, %14 : i8
        scf.if %77 {
          %int_tuple_74 = cute.make_int_tuple(%62) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_75 = cute.add_offset(%ptr_21, %int_tuple_74) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %ptr_76 = cute.add_offset(%iter_31, %11) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
          %111 = builtin.unrealized_conversion_cast %ptr_75 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %112 = builtin.unrealized_conversion_cast %ptr_76 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
          %113 = llvm.load %111 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %113, %112 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %ptr_63 = cute.add_offset(%iter_39, %10) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
        %78 = builtin.unrealized_conversion_cast %ptr_63 : !cute.ptr<i8, rmem> to !llvm.ptr
        %79 = llvm.load %78 : !llvm.ptr -> i8
        %80 = llvm.icmp "ne" %79, %14 : i8
        scf.if %80 {
          %111 = arith.addi %62, %c1_i64 : i64
          %int_tuple_74 = cute.make_int_tuple(%111) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_75 = cute.add_offset(%ptr_21, %int_tuple_74) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %ptr_76 = cute.add_offset(%iter_31, %10) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<f32, rmem>
          %112 = builtin.unrealized_conversion_cast %ptr_75 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %113 = builtin.unrealized_conversion_cast %ptr_76 : !cute.ptr<f32, rmem> to !llvm.ptr
          %114 = llvm.load %112 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %114, %113 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %ptr_64 = cute.add_offset(%iter_39, %9) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem, align<2>>
        %81 = builtin.unrealized_conversion_cast %ptr_64 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
        %82 = llvm.load %81 : !llvm.ptr -> i8
        %83 = llvm.icmp "ne" %82, %14 : i8
        scf.if %83 {
          %111 = arith.addi %62, %c2_i64 : i64
          %int_tuple_74 = cute.make_int_tuple(%111) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_75 = cute.add_offset(%ptr_21, %int_tuple_74) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %ptr_76 = cute.add_offset(%iter_31, %9) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
          %112 = builtin.unrealized_conversion_cast %ptr_75 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %113 = builtin.unrealized_conversion_cast %ptr_76 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %114 = llvm.load %112 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %114, %113 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %ptr_65 = cute.add_offset(%iter_39, %8) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
        %84 = builtin.unrealized_conversion_cast %ptr_65 : !cute.ptr<i8, rmem> to !llvm.ptr
        %85 = llvm.load %84 : !llvm.ptr -> i8
        %86 = llvm.icmp "ne" %85, %14 : i8
        scf.if %86 {
          %111 = arith.addi %62, %c3_i64 : i64
          %int_tuple_74 = cute.make_int_tuple(%111) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_75 = cute.add_offset(%ptr_21, %int_tuple_74) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %ptr_76 = cute.add_offset(%iter_31, %8) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<f32, rmem>
          %112 = builtin.unrealized_conversion_cast %ptr_75 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %113 = builtin.unrealized_conversion_cast %ptr_76 : !cute.ptr<f32, rmem> to !llvm.ptr
          %114 = llvm.load %112 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %114, %113 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %ptr_66 = cute.add_offset(%iter_39, %7) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<i8, rmem, align<8>>
        %87 = builtin.unrealized_conversion_cast %ptr_66 : !cute.ptr<i8, rmem, align<8>> to !llvm.ptr
        %88 = llvm.load %87 : !llvm.ptr -> i8
        %89 = llvm.icmp "ne" %88, %14 : i8
        scf.if %89 {
          %111 = arith.muli %62, %c2_i64 : i64
          %iv_74 = cute.assume(%111) : (i64) -> !cute.i64<divby 2>
          %int_tuple_75 = cute.make_int_tuple(%iv_74) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
          %ptr_76 = cute.add_offset(%ptr_21, %int_tuple_75) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
          %ptr_77 = cute.add_offset(%iter_31, %7) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<f32, rmem, align<32>>
          %112 = builtin.unrealized_conversion_cast %ptr_76 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %113 = builtin.unrealized_conversion_cast %ptr_77 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
          %114 = llvm.load %112 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %114, %113 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %ptr_67 = cute.add_offset(%iter_39, %6) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<i8, rmem>
        %90 = builtin.unrealized_conversion_cast %ptr_67 : !cute.ptr<i8, rmem> to !llvm.ptr
        %91 = llvm.load %90 : !llvm.ptr -> i8
        %92 = llvm.icmp "ne" %91, %14 : i8
        scf.if %92 {
          %111 = arith.muli %62, %c2_i64 : i64
          %112 = arith.addi %111, %c1_i64 : i64
          %int_tuple_74 = cute.make_int_tuple(%112) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_75 = cute.add_offset(%ptr_21, %int_tuple_74) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %ptr_76 = cute.add_offset(%iter_31, %6) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<f32, rmem>
          %113 = builtin.unrealized_conversion_cast %ptr_75 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %114 = builtin.unrealized_conversion_cast %ptr_76 : !cute.ptr<f32, rmem> to !llvm.ptr
          %115 = llvm.load %113 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %115, %114 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %ptr_68 = cute.add_offset(%iter_39, %5) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<i8, rmem, align<2>>
        %93 = builtin.unrealized_conversion_cast %ptr_68 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
        %94 = llvm.load %93 : !llvm.ptr -> i8
        %95 = llvm.icmp "ne" %94, %14 : i8
        scf.if %95 {
          %111 = arith.muli %62, %c2_i64 : i64
          %112 = arith.addi %111, %c2_i64 : i64
          %iv_74 = cute.assume(%112) : (i64) -> !cute.i64<divby 2>
          %int_tuple_75 = cute.make_int_tuple(%iv_74) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
          %ptr_76 = cute.add_offset(%ptr_21, %int_tuple_75) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
          %ptr_77 = cute.add_offset(%iter_31, %5) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<f32, rmem, align<8>>
          %113 = builtin.unrealized_conversion_cast %ptr_76 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %114 = builtin.unrealized_conversion_cast %ptr_77 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %115 = llvm.load %113 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %115, %114 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %ptr_69 = cute.add_offset(%iter_39, %4) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<i8, rmem>
        %96 = builtin.unrealized_conversion_cast %ptr_69 : !cute.ptr<i8, rmem> to !llvm.ptr
        %97 = llvm.load %96 : !llvm.ptr -> i8
        %98 = llvm.icmp "ne" %97, %14 : i8
        scf.if %98 {
          %111 = arith.muli %62, %c2_i64 : i64
          %112 = arith.addi %111, %c3_i64 : i64
          %int_tuple_74 = cute.make_int_tuple(%112) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_75 = cute.add_offset(%ptr_21, %int_tuple_74) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %ptr_76 = cute.add_offset(%iter_31, %4) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<f32, rmem>
          %113 = builtin.unrealized_conversion_cast %ptr_75 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %114 = builtin.unrealized_conversion_cast %ptr_76 : !cute.ptr<f32, rmem> to !llvm.ptr
          %115 = llvm.load %113 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %115, %114 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %ptr_70 = cute.add_offset(%iter_39, %3) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<i8, rmem, align<4>>
        %99 = builtin.unrealized_conversion_cast %ptr_70 : !cute.ptr<i8, rmem, align<4>> to !llvm.ptr
        %100 = llvm.load %99 : !llvm.ptr -> i8
        %101 = llvm.icmp "ne" %100, %14 : i8
        scf.if %101 {
          %111 = arith.muli %62, %c3_i64 : i64
          %iv_74 = cute.assume(%111) : (i64) -> !cute.i64<divby 3>
          %int_tuple_75 = cute.make_int_tuple(%iv_74) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
          %ptr_76 = cute.add_offset(%ptr_21, %int_tuple_75) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
          %ptr_77 = cute.add_offset(%iter_31, %3) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<f32, rmem, align<16>>
          %112 = builtin.unrealized_conversion_cast %ptr_76 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %113 = builtin.unrealized_conversion_cast %ptr_77 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
          %114 = llvm.load %112 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %114, %113 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %ptr_71 = cute.add_offset(%iter_39, %2) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<i8, rmem>
        %102 = builtin.unrealized_conversion_cast %ptr_71 : !cute.ptr<i8, rmem> to !llvm.ptr
        %103 = llvm.load %102 : !llvm.ptr -> i8
        %104 = llvm.icmp "ne" %103, %14 : i8
        scf.if %104 {
          %111 = arith.muli %62, %c3_i64 : i64
          %112 = arith.addi %111, %c1_i64 : i64
          %int_tuple_74 = cute.make_int_tuple(%112) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_75 = cute.add_offset(%ptr_21, %int_tuple_74) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %ptr_76 = cute.add_offset(%iter_31, %2) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<f32, rmem>
          %113 = builtin.unrealized_conversion_cast %ptr_75 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %114 = builtin.unrealized_conversion_cast %ptr_76 : !cute.ptr<f32, rmem> to !llvm.ptr
          %115 = llvm.load %113 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %115, %114 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %ptr_72 = cute.add_offset(%iter_39, %1) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<i8, rmem, align<2>>
        %105 = builtin.unrealized_conversion_cast %ptr_72 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
        %106 = llvm.load %105 : !llvm.ptr -> i8
        %107 = llvm.icmp "ne" %106, %14 : i8
        scf.if %107 {
          %111 = arith.muli %62, %c3_i64 : i64
          %112 = arith.addi %111, %c2_i64 : i64
          %int_tuple_74 = cute.make_int_tuple(%112) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_75 = cute.add_offset(%ptr_21, %int_tuple_74) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %ptr_76 = cute.add_offset(%iter_31, %1) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<f32, rmem, align<8>>
          %113 = builtin.unrealized_conversion_cast %ptr_75 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %114 = builtin.unrealized_conversion_cast %ptr_76 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %115 = llvm.load %113 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %115, %114 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %ptr_73 = cute.add_offset(%iter_39, %0) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<i8, rmem>
        %108 = builtin.unrealized_conversion_cast %ptr_73 : !cute.ptr<i8, rmem> to !llvm.ptr
        %109 = llvm.load %108 : !llvm.ptr -> i8
        %110 = llvm.icmp "ne" %109, %14 : i8
        scf.if %110 {
          %111 = arith.muli %62, %c3_i64 : i64
          %112 = arith.addi %111, %c3_i64 : i64
          %iv_74 = cute.assume(%112) : (i64) -> !cute.i64<divby 3>
          %int_tuple_75 = cute.make_int_tuple(%iv_74) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
          %ptr_76 = cute.add_offset(%ptr_21, %int_tuple_75) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
          %ptr_77 = cute.add_offset(%iter_31, %0) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<f32, rmem>
          %113 = builtin.unrealized_conversion_cast %ptr_76 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %114 = builtin.unrealized_conversion_cast %ptr_77 : !cute.ptr<f32, rmem> to !llvm.ptr
          %115 = llvm.load %113 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %115, %114 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
      } {llvm.loop_annotation = #loop_annotation}
      %56 = cute.memref.load_vec %rmem, row_major : !memref_rmem_f32_
      %57 = cute.memref.load_vec %rmem_30, row_major : !memref_rmem_f32_
      %58 = arith.addf %56, %57 : vector<16xf32>
      cute.memref.store_vec %58, %rmem_32, row_major : !memref_rmem_f32_
      %append_51 = cute.append_to_rank<2> (%lay_28, %19) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">
      %59 = cute.get_scalars(%append_51) <{only_dynamic}> : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %stride_52 = cute.make_stride(%59) : (i64) -> !cute.stride<"((0,(1,?{i64})),(0,0))">
      %lay_53 = cute.make_layout(%18, %stride_52) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %append_54 = cute.append_to_rank<2> (%lay_53, %19) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">, !cute.layout<"1:0">
      %60 = cute.get_scalars(%append_54) <{only_dynamic}> : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %stride_55 = cute.make_stride(%60) : (i64) -> !cute.stride<"((0,(1,?{i64})),((0,0)))">
      %lay_56 = cute.make_layout(%17, %stride_55) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
      scf.for %arg6 = %c0_i32 to %53 step %c1_i32  : i32 {
        %61 = cute.get_scalars(%lay_56) <{only_dynamic}> : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
        %stride_57 = cute.make_stride(%61) : (i64) -> !cute.stride<"((0,(1,?{i64})))">
        %lay_58 = cute.make_layout(%15, %stride_57) : !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
        %62 = cute.get_scalars(%lay_58) <{only_dynamic}> : !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
        %63 = builtin.unrealized_conversion_cast %iter_39 : !cute.ptr<i8, rmem, align<32>> to !llvm.ptr
        %64 = llvm.load %63 : !llvm.ptr -> i8
        %65 = llvm.icmp "ne" %64, %14 : i8
        scf.if %65 {
          %111 = builtin.unrealized_conversion_cast %iter_33 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
          %112 = builtin.unrealized_conversion_cast %ptr_26 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %113 = llvm.load %111 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %113, %112 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %ptr_59 = cute.add_offset(%iter_39, %16) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
        %66 = builtin.unrealized_conversion_cast %ptr_59 : !cute.ptr<i8, rmem> to !llvm.ptr
        %67 = llvm.load %66 : !llvm.ptr -> i8
        %68 = llvm.icmp "ne" %67, %14 : i8
        scf.if %68 {
          %ptr_74 = cute.add_offset(%iter_33, %16) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
          %ptr_75 = cute.add_offset(%ptr_26, %16) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
          %111 = builtin.unrealized_conversion_cast %ptr_74 : !cute.ptr<f32, rmem> to !llvm.ptr
          %112 = builtin.unrealized_conversion_cast %ptr_75 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %113 = llvm.load %111 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %113, %112 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %ptr_60 = cute.add_offset(%iter_39, %13) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem, align<2>>
        %69 = builtin.unrealized_conversion_cast %ptr_60 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
        %70 = llvm.load %69 : !llvm.ptr -> i8
        %71 = llvm.icmp "ne" %70, %14 : i8
        scf.if %71 {
          %ptr_74 = cute.add_offset(%iter_33, %13) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
          %ptr_75 = cute.add_offset(%ptr_26, %13) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
          %111 = builtin.unrealized_conversion_cast %ptr_74 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %112 = builtin.unrealized_conversion_cast %ptr_75 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %113 = llvm.load %111 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %113, %112 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %ptr_61 = cute.add_offset(%iter_39, %12) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
        %72 = builtin.unrealized_conversion_cast %ptr_61 : !cute.ptr<i8, rmem> to !llvm.ptr
        %73 = llvm.load %72 : !llvm.ptr -> i8
        %74 = llvm.icmp "ne" %73, %14 : i8
        scf.if %74 {
          %ptr_74 = cute.add_offset(%iter_33, %12) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
          %ptr_75 = cute.add_offset(%ptr_26, %12) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
          %111 = builtin.unrealized_conversion_cast %ptr_74 : !cute.ptr<f32, rmem> to !llvm.ptr
          %112 = builtin.unrealized_conversion_cast %ptr_75 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %113 = llvm.load %111 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %113, %112 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %ptr_62 = cute.add_offset(%iter_39, %11) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem, align<4>>
        %75 = builtin.unrealized_conversion_cast %ptr_62 : !cute.ptr<i8, rmem, align<4>> to !llvm.ptr
        %76 = llvm.load %75 : !llvm.ptr -> i8
        %77 = llvm.icmp "ne" %76, %14 : i8
        scf.if %77 {
          %ptr_74 = cute.add_offset(%iter_33, %11) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
          %int_tuple_75 = cute.make_int_tuple(%62) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_76 = cute.add_offset(%ptr_26, %int_tuple_75) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %111 = builtin.unrealized_conversion_cast %ptr_74 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
          %112 = builtin.unrealized_conversion_cast %ptr_76 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %113 = llvm.load %111 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %113, %112 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %ptr_63 = cute.add_offset(%iter_39, %10) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
        %78 = builtin.unrealized_conversion_cast %ptr_63 : !cute.ptr<i8, rmem> to !llvm.ptr
        %79 = llvm.load %78 : !llvm.ptr -> i8
        %80 = llvm.icmp "ne" %79, %14 : i8
        scf.if %80 {
          %ptr_74 = cute.add_offset(%iter_33, %10) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<f32, rmem>
          %111 = arith.addi %62, %c1_i64 : i64
          %int_tuple_75 = cute.make_int_tuple(%111) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_76 = cute.add_offset(%ptr_26, %int_tuple_75) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %112 = builtin.unrealized_conversion_cast %ptr_74 : !cute.ptr<f32, rmem> to !llvm.ptr
          %113 = builtin.unrealized_conversion_cast %ptr_76 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %114 = llvm.load %112 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %114, %113 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %ptr_64 = cute.add_offset(%iter_39, %9) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem, align<2>>
        %81 = builtin.unrealized_conversion_cast %ptr_64 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
        %82 = llvm.load %81 : !llvm.ptr -> i8
        %83 = llvm.icmp "ne" %82, %14 : i8
        scf.if %83 {
          %ptr_74 = cute.add_offset(%iter_33, %9) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
          %111 = arith.addi %62, %c2_i64 : i64
          %int_tuple_75 = cute.make_int_tuple(%111) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_76 = cute.add_offset(%ptr_26, %int_tuple_75) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %112 = builtin.unrealized_conversion_cast %ptr_74 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %113 = builtin.unrealized_conversion_cast %ptr_76 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %114 = llvm.load %112 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %114, %113 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %ptr_65 = cute.add_offset(%iter_39, %8) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
        %84 = builtin.unrealized_conversion_cast %ptr_65 : !cute.ptr<i8, rmem> to !llvm.ptr
        %85 = llvm.load %84 : !llvm.ptr -> i8
        %86 = llvm.icmp "ne" %85, %14 : i8
        scf.if %86 {
          %ptr_74 = cute.add_offset(%iter_33, %8) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<f32, rmem>
          %111 = arith.addi %62, %c3_i64 : i64
          %int_tuple_75 = cute.make_int_tuple(%111) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_76 = cute.add_offset(%ptr_26, %int_tuple_75) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %112 = builtin.unrealized_conversion_cast %ptr_74 : !cute.ptr<f32, rmem> to !llvm.ptr
          %113 = builtin.unrealized_conversion_cast %ptr_76 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %114 = llvm.load %112 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %114, %113 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %ptr_66 = cute.add_offset(%iter_39, %7) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<i8, rmem, align<8>>
        %87 = builtin.unrealized_conversion_cast %ptr_66 : !cute.ptr<i8, rmem, align<8>> to !llvm.ptr
        %88 = llvm.load %87 : !llvm.ptr -> i8
        %89 = llvm.icmp "ne" %88, %14 : i8
        scf.if %89 {
          %ptr_74 = cute.add_offset(%iter_33, %7) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<f32, rmem, align<32>>
          %111 = arith.muli %62, %c2_i64 : i64
          %iv_75 = cute.assume(%111) : (i64) -> !cute.i64<divby 2>
          %int_tuple_76 = cute.make_int_tuple(%iv_75) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
          %ptr_77 = cute.add_offset(%ptr_26, %int_tuple_76) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
          %112 = builtin.unrealized_conversion_cast %ptr_74 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
          %113 = builtin.unrealized_conversion_cast %ptr_77 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %114 = llvm.load %112 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %114, %113 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %ptr_67 = cute.add_offset(%iter_39, %6) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<i8, rmem>
        %90 = builtin.unrealized_conversion_cast %ptr_67 : !cute.ptr<i8, rmem> to !llvm.ptr
        %91 = llvm.load %90 : !llvm.ptr -> i8
        %92 = llvm.icmp "ne" %91, %14 : i8
        scf.if %92 {
          %ptr_74 = cute.add_offset(%iter_33, %6) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<f32, rmem>
          %111 = arith.muli %62, %c2_i64 : i64
          %112 = arith.addi %111, %c1_i64 : i64
          %int_tuple_75 = cute.make_int_tuple(%112) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_76 = cute.add_offset(%ptr_26, %int_tuple_75) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %113 = builtin.unrealized_conversion_cast %ptr_74 : !cute.ptr<f32, rmem> to !llvm.ptr
          %114 = builtin.unrealized_conversion_cast %ptr_76 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %115 = llvm.load %113 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %115, %114 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %ptr_68 = cute.add_offset(%iter_39, %5) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<i8, rmem, align<2>>
        %93 = builtin.unrealized_conversion_cast %ptr_68 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
        %94 = llvm.load %93 : !llvm.ptr -> i8
        %95 = llvm.icmp "ne" %94, %14 : i8
        scf.if %95 {
          %ptr_74 = cute.add_offset(%iter_33, %5) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<f32, rmem, align<8>>
          %111 = arith.muli %62, %c2_i64 : i64
          %112 = arith.addi %111, %c2_i64 : i64
          %iv_75 = cute.assume(%112) : (i64) -> !cute.i64<divby 2>
          %int_tuple_76 = cute.make_int_tuple(%iv_75) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
          %ptr_77 = cute.add_offset(%ptr_26, %int_tuple_76) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
          %113 = builtin.unrealized_conversion_cast %ptr_74 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %114 = builtin.unrealized_conversion_cast %ptr_77 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %115 = llvm.load %113 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %115, %114 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %ptr_69 = cute.add_offset(%iter_39, %4) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<i8, rmem>
        %96 = builtin.unrealized_conversion_cast %ptr_69 : !cute.ptr<i8, rmem> to !llvm.ptr
        %97 = llvm.load %96 : !llvm.ptr -> i8
        %98 = llvm.icmp "ne" %97, %14 : i8
        scf.if %98 {
          %ptr_74 = cute.add_offset(%iter_33, %4) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<f32, rmem>
          %111 = arith.muli %62, %c2_i64 : i64
          %112 = arith.addi %111, %c3_i64 : i64
          %int_tuple_75 = cute.make_int_tuple(%112) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_76 = cute.add_offset(%ptr_26, %int_tuple_75) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %113 = builtin.unrealized_conversion_cast %ptr_74 : !cute.ptr<f32, rmem> to !llvm.ptr
          %114 = builtin.unrealized_conversion_cast %ptr_76 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %115 = llvm.load %113 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %115, %114 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %ptr_70 = cute.add_offset(%iter_39, %3) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<i8, rmem, align<4>>
        %99 = builtin.unrealized_conversion_cast %ptr_70 : !cute.ptr<i8, rmem, align<4>> to !llvm.ptr
        %100 = llvm.load %99 : !llvm.ptr -> i8
        %101 = llvm.icmp "ne" %100, %14 : i8
        scf.if %101 {
          %ptr_74 = cute.add_offset(%iter_33, %3) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<f32, rmem, align<16>>
          %111 = arith.muli %62, %c3_i64 : i64
          %iv_75 = cute.assume(%111) : (i64) -> !cute.i64<divby 3>
          %int_tuple_76 = cute.make_int_tuple(%iv_75) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
          %ptr_77 = cute.add_offset(%ptr_26, %int_tuple_76) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
          %112 = builtin.unrealized_conversion_cast %ptr_74 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
          %113 = builtin.unrealized_conversion_cast %ptr_77 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %114 = llvm.load %112 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %114, %113 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %ptr_71 = cute.add_offset(%iter_39, %2) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<i8, rmem>
        %102 = builtin.unrealized_conversion_cast %ptr_71 : !cute.ptr<i8, rmem> to !llvm.ptr
        %103 = llvm.load %102 : !llvm.ptr -> i8
        %104 = llvm.icmp "ne" %103, %14 : i8
        scf.if %104 {
          %ptr_74 = cute.add_offset(%iter_33, %2) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<f32, rmem>
          %111 = arith.muli %62, %c3_i64 : i64
          %112 = arith.addi %111, %c1_i64 : i64
          %int_tuple_75 = cute.make_int_tuple(%112) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_76 = cute.add_offset(%ptr_26, %int_tuple_75) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %113 = builtin.unrealized_conversion_cast %ptr_74 : !cute.ptr<f32, rmem> to !llvm.ptr
          %114 = builtin.unrealized_conversion_cast %ptr_76 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %115 = llvm.load %113 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %115, %114 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %ptr_72 = cute.add_offset(%iter_39, %1) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<i8, rmem, align<2>>
        %105 = builtin.unrealized_conversion_cast %ptr_72 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
        %106 = llvm.load %105 : !llvm.ptr -> i8
        %107 = llvm.icmp "ne" %106, %14 : i8
        scf.if %107 {
          %ptr_74 = cute.add_offset(%iter_33, %1) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<f32, rmem, align<8>>
          %111 = arith.muli %62, %c3_i64 : i64
          %112 = arith.addi %111, %c2_i64 : i64
          %int_tuple_75 = cute.make_int_tuple(%112) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_76 = cute.add_offset(%ptr_26, %int_tuple_75) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %113 = builtin.unrealized_conversion_cast %ptr_74 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %114 = builtin.unrealized_conversion_cast %ptr_76 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %115 = llvm.load %113 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %115, %114 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %ptr_73 = cute.add_offset(%iter_39, %0) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<i8, rmem>
        %108 = builtin.unrealized_conversion_cast %ptr_73 : !cute.ptr<i8, rmem> to !llvm.ptr
        %109 = llvm.load %108 : !llvm.ptr -> i8
        %110 = llvm.icmp "ne" %109, %14 : i8
        scf.if %110 {
          %ptr_74 = cute.add_offset(%iter_33, %0) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<f32, rmem>
          %111 = arith.muli %62, %c3_i64 : i64
          %112 = arith.addi %111, %c3_i64 : i64
          %iv_75 = cute.assume(%112) : (i64) -> !cute.i64<divby 3>
          %int_tuple_76 = cute.make_int_tuple(%iv_75) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
          %ptr_77 = cute.add_offset(%ptr_26, %int_tuple_76) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
          %113 = builtin.unrealized_conversion_cast %ptr_74 : !cute.ptr<f32, rmem> to !llvm.ptr
          %114 = builtin.unrealized_conversion_cast %ptr_77 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %115 = llvm.load %113 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %115, %114 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
      } {llvm.loop_annotation = #loop_annotation}
      return
    }
  }
  func.func @cutlass_elementwise_add_tensor_00795_21652_04639_03193_15897_02304_02971_12990_02319_03973_00495_05866_09467_06015_06234_07404_19793_05333_01425_01997_05745_11222_16922_13492_04451(%arg0: !memref_gmem_f32_1, %arg1: !memref_gmem_f32_1, %arg2: !memref_gmem_f32_1) attributes {llvm.emit_c_interface} {
    %c0_i32 = arith.constant 0 : i32
    %c128 = arith.constant 128 : index
    %c1 = arith.constant 1 : index
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
    %22 = arith.index_cast %21 : i32 to index
    gpu.launch_func  @kernels::@kernel_cutlass_elementwise_add_kernel_tensorptrf32gmemo161281div16128_tensorptrf32gmemo161281div16128_tensorptrf32gmemo161281div16128_tensor00o1612810111601281___0 blocks in (%22, %c1, %c1) threads in (%c128, %c1, %c1)  dynamic_shared_memory_size %c0_i32 args(%view : !memref_gmem_f32_, %view_7 : !memref_gmem_f32_, %view_14 : !memref_gmem_f32_, %view_20 : !cute.coord_tensor<"(0,0)", "((16,128),(?,?)):((1@0,1@1),(16@0,128@1))">, %16 : i32, %17 : i32) {use_pdl = false}
    return
  }
}
