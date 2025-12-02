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
      %coord_39 = cute.make_coord(%arg4, %arg5) : (i32, i32) -> !cute.coord<"(?,?)">
      %51:2 = cute.get_scalars(%coord_39) : !cute.coord<"(?,?)">
      scf.for %arg6 = %c0_i32 to %c16_i32 step %c1_i32  : i32 {
        %coord_109 = cute.make_coord(%arg6) : (i32) -> !cute.coord<"?">
        %idx_110 = cute.crd2idx(%coord_109, %20) : (!cute.coord<"?">, !cute.layout<"((1,(4,4)),1,1):((0,(1@1,1@0)),0,0)">) -> !cute.int_tuple<"(?,?)">
        %tup_111 = cute.add_offset(%tup_37, %idx_110) : (!cute.int_tuple<"(?{div=4},?{div=4})">, !cute.int_tuple<"(?,?)">) -> !cute.int_tuple<"(?,?)">
        %e0, %e1 = cute.get_leaves(%tup_111) : !cute.int_tuple<"(?,?)">
        %coord_112 = cute.make_coord(%e0, %e1) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
        %116:2 = cute.get_scalars(%coord_112) : !cute.coord<"(?,?)">
        %117 = arith.cmpi slt, %116#0, %51#0 : i32
        %118 = arith.cmpi slt, %116#1, %51#1 : i32
        %119 = arith.andi %117, %118 : i1
        %120 = arith.extui %119 : i1 to i8
        cute.memref.store(%rmem_38, %coord_109, %120) : (!memref_rmem_i8_, !cute.coord<"?">, i8) -> ()
      }
      %iter_40 = cute.get_iter(%rmem_38) : !memref_rmem_i8_
      %append = cute.append_to_rank<2> (%lay_18, %19) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">
      %52 = cute.get_scalars(%append) <{only_dynamic}> : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %stride_41 = cute.make_stride(%52) : (i64) -> !cute.stride<"((0,(1,?{i64})),(0,0))">
      %lay_42 = cute.make_layout(%18, %stride_41) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %append_43 = cute.append_to_rank<2> (%lay_42, %19) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">, !cute.layout<"1:0">
      %53 = cute.get_scalars(%append_43) <{only_dynamic}> : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %stride_44 = cute.make_stride(%53) : (i64) -> !cute.stride<"((0,(1,?{i64})),((0,0)))">
      %lay_45 = cute.make_layout(%17, %stride_44) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
      %54 = cute.get_scalars(%16) : !cute.int_tuple<"1">
      %55 = cute.get_scalars(%lay_45) <{only_dynamic}> : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
      %stride_46 = cute.make_stride(%55) : (i64) -> !cute.stride<"((0,(1,?{i64})))">
      %lay_47 = cute.make_layout(%15, %stride_46) : !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
      %56 = cute.get_scalars(%lay_47) <{only_dynamic}> : !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
      %57 = builtin.unrealized_conversion_cast %iter_40 : !cute.ptr<i8, rmem, align<32>> to !llvm.ptr
      %ptr_48 = cute.add_offset(%iter_40, %16) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
      %58 = builtin.unrealized_conversion_cast %ptr_48 : !cute.ptr<i8, rmem> to !llvm.ptr
      %ptr_49 = cute.add_offset(%iter_40, %13) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem, align<2>>
      %59 = builtin.unrealized_conversion_cast %ptr_49 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
      %ptr_50 = cute.add_offset(%iter_40, %12) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
      %60 = builtin.unrealized_conversion_cast %ptr_50 : !cute.ptr<i8, rmem> to !llvm.ptr
      %ptr_51 = cute.add_offset(%iter_40, %11) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem, align<4>>
      %61 = builtin.unrealized_conversion_cast %ptr_51 : !cute.ptr<i8, rmem, align<4>> to !llvm.ptr
      %ptr_52 = cute.add_offset(%iter_40, %10) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
      %62 = builtin.unrealized_conversion_cast %ptr_52 : !cute.ptr<i8, rmem> to !llvm.ptr
      %ptr_53 = cute.add_offset(%iter_40, %9) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem, align<2>>
      %63 = builtin.unrealized_conversion_cast %ptr_53 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
      %ptr_54 = cute.add_offset(%iter_40, %8) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
      %64 = builtin.unrealized_conversion_cast %ptr_54 : !cute.ptr<i8, rmem> to !llvm.ptr
      %ptr_55 = cute.add_offset(%iter_40, %7) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<i8, rmem, align<8>>
      %65 = builtin.unrealized_conversion_cast %ptr_55 : !cute.ptr<i8, rmem, align<8>> to !llvm.ptr
      %ptr_56 = cute.add_offset(%iter_40, %6) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<i8, rmem>
      %66 = builtin.unrealized_conversion_cast %ptr_56 : !cute.ptr<i8, rmem> to !llvm.ptr
      %ptr_57 = cute.add_offset(%iter_40, %5) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<i8, rmem, align<2>>
      %67 = builtin.unrealized_conversion_cast %ptr_57 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
      %ptr_58 = cute.add_offset(%iter_40, %4) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<i8, rmem>
      %68 = builtin.unrealized_conversion_cast %ptr_58 : !cute.ptr<i8, rmem> to !llvm.ptr
      %ptr_59 = cute.add_offset(%iter_40, %3) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<i8, rmem, align<4>>
      %69 = builtin.unrealized_conversion_cast %ptr_59 : !cute.ptr<i8, rmem, align<4>> to !llvm.ptr
      %ptr_60 = cute.add_offset(%iter_40, %2) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<i8, rmem>
      %70 = builtin.unrealized_conversion_cast %ptr_60 : !cute.ptr<i8, rmem> to !llvm.ptr
      %ptr_61 = cute.add_offset(%iter_40, %1) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<i8, rmem, align<2>>
      %71 = builtin.unrealized_conversion_cast %ptr_61 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
      %ptr_62 = cute.add_offset(%iter_40, %0) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<i8, rmem>
      %72 = builtin.unrealized_conversion_cast %ptr_62 : !cute.ptr<i8, rmem> to !llvm.ptr
      scf.for %arg6 = %c0_i32 to %54 step %c1_i32  : i32 {
        %116 = llvm.load %57 : !llvm.ptr -> i8
        %117 = llvm.icmp "ne" %116, %14 : i8
        scf.if %117 {
          %148 = builtin.unrealized_conversion_cast %ptr_16 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %149 = builtin.unrealized_conversion_cast %iter_29 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
          %150 = llvm.load %148 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %150, %149 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %118 = llvm.load %58 : !llvm.ptr -> i8
        %119 = llvm.icmp "ne" %118, %14 : i8
        scf.if %119 {
          %ptr_109 = cute.add_offset(%ptr_16, %16) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
          %ptr_110 = cute.add_offset(%iter_29, %16) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
          %148 = builtin.unrealized_conversion_cast %ptr_109 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %149 = builtin.unrealized_conversion_cast %ptr_110 : !cute.ptr<f32, rmem> to !llvm.ptr
          %150 = llvm.load %148 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %150, %149 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %120 = llvm.load %59 : !llvm.ptr -> i8
        %121 = llvm.icmp "ne" %120, %14 : i8
        scf.if %121 {
          %ptr_109 = cute.add_offset(%ptr_16, %13) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
          %ptr_110 = cute.add_offset(%iter_29, %13) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
          %148 = builtin.unrealized_conversion_cast %ptr_109 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %149 = builtin.unrealized_conversion_cast %ptr_110 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %150 = llvm.load %148 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %150, %149 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %122 = llvm.load %60 : !llvm.ptr -> i8
        %123 = llvm.icmp "ne" %122, %14 : i8
        scf.if %123 {
          %ptr_109 = cute.add_offset(%ptr_16, %12) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
          %ptr_110 = cute.add_offset(%iter_29, %12) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
          %148 = builtin.unrealized_conversion_cast %ptr_109 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %149 = builtin.unrealized_conversion_cast %ptr_110 : !cute.ptr<f32, rmem> to !llvm.ptr
          %150 = llvm.load %148 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %150, %149 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %124 = llvm.load %61 : !llvm.ptr -> i8
        %125 = llvm.icmp "ne" %124, %14 : i8
        scf.if %125 {
          %int_tuple_109 = cute.make_int_tuple(%56) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_110 = cute.add_offset(%ptr_16, %int_tuple_109) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %ptr_111 = cute.add_offset(%iter_29, %11) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
          %148 = builtin.unrealized_conversion_cast %ptr_110 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %149 = builtin.unrealized_conversion_cast %ptr_111 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
          %150 = llvm.load %148 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %150, %149 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %126 = llvm.load %62 : !llvm.ptr -> i8
        %127 = llvm.icmp "ne" %126, %14 : i8
        scf.if %127 {
          %148 = arith.addi %56, %c1_i64 : i64
          %int_tuple_109 = cute.make_int_tuple(%148) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_110 = cute.add_offset(%ptr_16, %int_tuple_109) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %ptr_111 = cute.add_offset(%iter_29, %10) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<f32, rmem>
          %149 = builtin.unrealized_conversion_cast %ptr_110 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %150 = builtin.unrealized_conversion_cast %ptr_111 : !cute.ptr<f32, rmem> to !llvm.ptr
          %151 = llvm.load %149 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %151, %150 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %128 = llvm.load %63 : !llvm.ptr -> i8
        %129 = llvm.icmp "ne" %128, %14 : i8
        scf.if %129 {
          %148 = arith.addi %56, %c2_i64 : i64
          %int_tuple_109 = cute.make_int_tuple(%148) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_110 = cute.add_offset(%ptr_16, %int_tuple_109) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %ptr_111 = cute.add_offset(%iter_29, %9) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
          %149 = builtin.unrealized_conversion_cast %ptr_110 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %150 = builtin.unrealized_conversion_cast %ptr_111 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %151 = llvm.load %149 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %151, %150 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %130 = llvm.load %64 : !llvm.ptr -> i8
        %131 = llvm.icmp "ne" %130, %14 : i8
        scf.if %131 {
          %148 = arith.addi %56, %c3_i64 : i64
          %int_tuple_109 = cute.make_int_tuple(%148) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_110 = cute.add_offset(%ptr_16, %int_tuple_109) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %ptr_111 = cute.add_offset(%iter_29, %8) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<f32, rmem>
          %149 = builtin.unrealized_conversion_cast %ptr_110 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %150 = builtin.unrealized_conversion_cast %ptr_111 : !cute.ptr<f32, rmem> to !llvm.ptr
          %151 = llvm.load %149 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %151, %150 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %132 = llvm.load %65 : !llvm.ptr -> i8
        %133 = llvm.icmp "ne" %132, %14 : i8
        scf.if %133 {
          %148 = arith.muli %56, %c2_i64 : i64
          %iv_109 = cute.assume(%148) : (i64) -> !cute.i64<divby 2>
          %int_tuple_110 = cute.make_int_tuple(%iv_109) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
          %ptr_111 = cute.add_offset(%ptr_16, %int_tuple_110) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
          %ptr_112 = cute.add_offset(%iter_29, %7) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<f32, rmem, align<32>>
          %149 = builtin.unrealized_conversion_cast %ptr_111 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %150 = builtin.unrealized_conversion_cast %ptr_112 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
          %151 = llvm.load %149 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %151, %150 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %134 = llvm.load %66 : !llvm.ptr -> i8
        %135 = llvm.icmp "ne" %134, %14 : i8
        scf.if %135 {
          %148 = arith.muli %56, %c2_i64 : i64
          %149 = arith.addi %148, %c1_i64 : i64
          %int_tuple_109 = cute.make_int_tuple(%149) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_110 = cute.add_offset(%ptr_16, %int_tuple_109) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %ptr_111 = cute.add_offset(%iter_29, %6) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<f32, rmem>
          %150 = builtin.unrealized_conversion_cast %ptr_110 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %151 = builtin.unrealized_conversion_cast %ptr_111 : !cute.ptr<f32, rmem> to !llvm.ptr
          %152 = llvm.load %150 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %152, %151 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %136 = llvm.load %67 : !llvm.ptr -> i8
        %137 = llvm.icmp "ne" %136, %14 : i8
        scf.if %137 {
          %148 = arith.muli %56, %c2_i64 : i64
          %149 = arith.addi %148, %c2_i64 : i64
          %iv_109 = cute.assume(%149) : (i64) -> !cute.i64<divby 2>
          %int_tuple_110 = cute.make_int_tuple(%iv_109) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
          %ptr_111 = cute.add_offset(%ptr_16, %int_tuple_110) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
          %ptr_112 = cute.add_offset(%iter_29, %5) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<f32, rmem, align<8>>
          %150 = builtin.unrealized_conversion_cast %ptr_111 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %151 = builtin.unrealized_conversion_cast %ptr_112 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %152 = llvm.load %150 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %152, %151 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %138 = llvm.load %68 : !llvm.ptr -> i8
        %139 = llvm.icmp "ne" %138, %14 : i8
        scf.if %139 {
          %148 = arith.muli %56, %c2_i64 : i64
          %149 = arith.addi %148, %c3_i64 : i64
          %int_tuple_109 = cute.make_int_tuple(%149) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_110 = cute.add_offset(%ptr_16, %int_tuple_109) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %ptr_111 = cute.add_offset(%iter_29, %4) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<f32, rmem>
          %150 = builtin.unrealized_conversion_cast %ptr_110 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %151 = builtin.unrealized_conversion_cast %ptr_111 : !cute.ptr<f32, rmem> to !llvm.ptr
          %152 = llvm.load %150 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %152, %151 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %140 = llvm.load %69 : !llvm.ptr -> i8
        %141 = llvm.icmp "ne" %140, %14 : i8
        scf.if %141 {
          %148 = arith.muli %56, %c3_i64 : i64
          %iv_109 = cute.assume(%148) : (i64) -> !cute.i64<divby 3>
          %int_tuple_110 = cute.make_int_tuple(%iv_109) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
          %ptr_111 = cute.add_offset(%ptr_16, %int_tuple_110) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
          %ptr_112 = cute.add_offset(%iter_29, %3) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<f32, rmem, align<16>>
          %149 = builtin.unrealized_conversion_cast %ptr_111 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %150 = builtin.unrealized_conversion_cast %ptr_112 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
          %151 = llvm.load %149 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %151, %150 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %142 = llvm.load %70 : !llvm.ptr -> i8
        %143 = llvm.icmp "ne" %142, %14 : i8
        scf.if %143 {
          %148 = arith.muli %56, %c3_i64 : i64
          %149 = arith.addi %148, %c1_i64 : i64
          %int_tuple_109 = cute.make_int_tuple(%149) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_110 = cute.add_offset(%ptr_16, %int_tuple_109) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %ptr_111 = cute.add_offset(%iter_29, %2) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<f32, rmem>
          %150 = builtin.unrealized_conversion_cast %ptr_110 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %151 = builtin.unrealized_conversion_cast %ptr_111 : !cute.ptr<f32, rmem> to !llvm.ptr
          %152 = llvm.load %150 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %152, %151 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %144 = llvm.load %71 : !llvm.ptr -> i8
        %145 = llvm.icmp "ne" %144, %14 : i8
        scf.if %145 {
          %148 = arith.muli %56, %c3_i64 : i64
          %149 = arith.addi %148, %c2_i64 : i64
          %int_tuple_109 = cute.make_int_tuple(%149) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_110 = cute.add_offset(%ptr_16, %int_tuple_109) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %ptr_111 = cute.add_offset(%iter_29, %1) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<f32, rmem, align<8>>
          %150 = builtin.unrealized_conversion_cast %ptr_110 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %151 = builtin.unrealized_conversion_cast %ptr_111 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %152 = llvm.load %150 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %152, %151 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %146 = llvm.load %72 : !llvm.ptr -> i8
        %147 = llvm.icmp "ne" %146, %14 : i8
        scf.if %147 {
          %148 = arith.muli %56, %c3_i64 : i64
          %149 = arith.addi %148, %c3_i64 : i64
          %iv_109 = cute.assume(%149) : (i64) -> !cute.i64<divby 3>
          %int_tuple_110 = cute.make_int_tuple(%iv_109) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
          %ptr_111 = cute.add_offset(%ptr_16, %int_tuple_110) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
          %ptr_112 = cute.add_offset(%iter_29, %0) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<f32, rmem>
          %150 = builtin.unrealized_conversion_cast %ptr_111 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %151 = builtin.unrealized_conversion_cast %ptr_112 : !cute.ptr<f32, rmem> to !llvm.ptr
          %152 = llvm.load %150 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %152, %151 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
      } {llvm.loop_annotation = #loop_annotation}
      %append_63 = cute.append_to_rank<2> (%lay_23, %19) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">
      %73 = cute.get_scalars(%append_63) <{only_dynamic}> : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %stride_64 = cute.make_stride(%73) : (i64) -> !cute.stride<"((0,(1,?{i64})),(0,0))">
      %lay_65 = cute.make_layout(%18, %stride_64) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %append_66 = cute.append_to_rank<2> (%lay_65, %19) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">, !cute.layout<"1:0">
      %74 = cute.get_scalars(%append_66) <{only_dynamic}> : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %stride_67 = cute.make_stride(%74) : (i64) -> !cute.stride<"((0,(1,?{i64})),((0,0)))">
      %lay_68 = cute.make_layout(%17, %stride_67) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
      %75 = cute.get_scalars(%lay_68) <{only_dynamic}> : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
      %stride_69 = cute.make_stride(%75) : (i64) -> !cute.stride<"((0,(1,?{i64})))">
      %lay_70 = cute.make_layout(%15, %stride_69) : !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
      %76 = cute.get_scalars(%lay_70) <{only_dynamic}> : !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
      %77 = builtin.unrealized_conversion_cast %iter_40 : !cute.ptr<i8, rmem, align<32>> to !llvm.ptr
      %ptr_71 = cute.add_offset(%iter_40, %16) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
      %78 = builtin.unrealized_conversion_cast %ptr_71 : !cute.ptr<i8, rmem> to !llvm.ptr
      %ptr_72 = cute.add_offset(%iter_40, %13) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem, align<2>>
      %79 = builtin.unrealized_conversion_cast %ptr_72 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
      %ptr_73 = cute.add_offset(%iter_40, %12) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
      %80 = builtin.unrealized_conversion_cast %ptr_73 : !cute.ptr<i8, rmem> to !llvm.ptr
      %ptr_74 = cute.add_offset(%iter_40, %11) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem, align<4>>
      %81 = builtin.unrealized_conversion_cast %ptr_74 : !cute.ptr<i8, rmem, align<4>> to !llvm.ptr
      %ptr_75 = cute.add_offset(%iter_40, %10) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
      %82 = builtin.unrealized_conversion_cast %ptr_75 : !cute.ptr<i8, rmem> to !llvm.ptr
      %ptr_76 = cute.add_offset(%iter_40, %9) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem, align<2>>
      %83 = builtin.unrealized_conversion_cast %ptr_76 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
      %ptr_77 = cute.add_offset(%iter_40, %8) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
      %84 = builtin.unrealized_conversion_cast %ptr_77 : !cute.ptr<i8, rmem> to !llvm.ptr
      %ptr_78 = cute.add_offset(%iter_40, %7) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<i8, rmem, align<8>>
      %85 = builtin.unrealized_conversion_cast %ptr_78 : !cute.ptr<i8, rmem, align<8>> to !llvm.ptr
      %ptr_79 = cute.add_offset(%iter_40, %6) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<i8, rmem>
      %86 = builtin.unrealized_conversion_cast %ptr_79 : !cute.ptr<i8, rmem> to !llvm.ptr
      %ptr_80 = cute.add_offset(%iter_40, %5) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<i8, rmem, align<2>>
      %87 = builtin.unrealized_conversion_cast %ptr_80 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
      %ptr_81 = cute.add_offset(%iter_40, %4) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<i8, rmem>
      %88 = builtin.unrealized_conversion_cast %ptr_81 : !cute.ptr<i8, rmem> to !llvm.ptr
      %ptr_82 = cute.add_offset(%iter_40, %3) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<i8, rmem, align<4>>
      %89 = builtin.unrealized_conversion_cast %ptr_82 : !cute.ptr<i8, rmem, align<4>> to !llvm.ptr
      %ptr_83 = cute.add_offset(%iter_40, %2) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<i8, rmem>
      %90 = builtin.unrealized_conversion_cast %ptr_83 : !cute.ptr<i8, rmem> to !llvm.ptr
      %ptr_84 = cute.add_offset(%iter_40, %1) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<i8, rmem, align<2>>
      %91 = builtin.unrealized_conversion_cast %ptr_84 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
      %ptr_85 = cute.add_offset(%iter_40, %0) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<i8, rmem>
      %92 = builtin.unrealized_conversion_cast %ptr_85 : !cute.ptr<i8, rmem> to !llvm.ptr
      scf.for %arg6 = %c0_i32 to %54 step %c1_i32  : i32 {
        %116 = llvm.load %77 : !llvm.ptr -> i8
        %117 = llvm.icmp "ne" %116, %14 : i8
        scf.if %117 {
          %148 = builtin.unrealized_conversion_cast %ptr_21 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %149 = builtin.unrealized_conversion_cast %iter_31 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
          %150 = llvm.load %148 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %150, %149 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %118 = llvm.load %78 : !llvm.ptr -> i8
        %119 = llvm.icmp "ne" %118, %14 : i8
        scf.if %119 {
          %ptr_109 = cute.add_offset(%ptr_21, %16) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
          %ptr_110 = cute.add_offset(%iter_31, %16) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
          %148 = builtin.unrealized_conversion_cast %ptr_109 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %149 = builtin.unrealized_conversion_cast %ptr_110 : !cute.ptr<f32, rmem> to !llvm.ptr
          %150 = llvm.load %148 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %150, %149 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %120 = llvm.load %79 : !llvm.ptr -> i8
        %121 = llvm.icmp "ne" %120, %14 : i8
        scf.if %121 {
          %ptr_109 = cute.add_offset(%ptr_21, %13) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
          %ptr_110 = cute.add_offset(%iter_31, %13) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
          %148 = builtin.unrealized_conversion_cast %ptr_109 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %149 = builtin.unrealized_conversion_cast %ptr_110 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %150 = llvm.load %148 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %150, %149 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %122 = llvm.load %80 : !llvm.ptr -> i8
        %123 = llvm.icmp "ne" %122, %14 : i8
        scf.if %123 {
          %ptr_109 = cute.add_offset(%ptr_21, %12) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
          %ptr_110 = cute.add_offset(%iter_31, %12) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
          %148 = builtin.unrealized_conversion_cast %ptr_109 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %149 = builtin.unrealized_conversion_cast %ptr_110 : !cute.ptr<f32, rmem> to !llvm.ptr
          %150 = llvm.load %148 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %150, %149 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %124 = llvm.load %81 : !llvm.ptr -> i8
        %125 = llvm.icmp "ne" %124, %14 : i8
        scf.if %125 {
          %int_tuple_109 = cute.make_int_tuple(%76) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_110 = cute.add_offset(%ptr_21, %int_tuple_109) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %ptr_111 = cute.add_offset(%iter_31, %11) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
          %148 = builtin.unrealized_conversion_cast %ptr_110 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %149 = builtin.unrealized_conversion_cast %ptr_111 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
          %150 = llvm.load %148 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %150, %149 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %126 = llvm.load %82 : !llvm.ptr -> i8
        %127 = llvm.icmp "ne" %126, %14 : i8
        scf.if %127 {
          %148 = arith.addi %76, %c1_i64 : i64
          %int_tuple_109 = cute.make_int_tuple(%148) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_110 = cute.add_offset(%ptr_21, %int_tuple_109) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %ptr_111 = cute.add_offset(%iter_31, %10) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<f32, rmem>
          %149 = builtin.unrealized_conversion_cast %ptr_110 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %150 = builtin.unrealized_conversion_cast %ptr_111 : !cute.ptr<f32, rmem> to !llvm.ptr
          %151 = llvm.load %149 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %151, %150 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %128 = llvm.load %83 : !llvm.ptr -> i8
        %129 = llvm.icmp "ne" %128, %14 : i8
        scf.if %129 {
          %148 = arith.addi %76, %c2_i64 : i64
          %int_tuple_109 = cute.make_int_tuple(%148) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_110 = cute.add_offset(%ptr_21, %int_tuple_109) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %ptr_111 = cute.add_offset(%iter_31, %9) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
          %149 = builtin.unrealized_conversion_cast %ptr_110 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %150 = builtin.unrealized_conversion_cast %ptr_111 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %151 = llvm.load %149 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %151, %150 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %130 = llvm.load %84 : !llvm.ptr -> i8
        %131 = llvm.icmp "ne" %130, %14 : i8
        scf.if %131 {
          %148 = arith.addi %76, %c3_i64 : i64
          %int_tuple_109 = cute.make_int_tuple(%148) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_110 = cute.add_offset(%ptr_21, %int_tuple_109) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %ptr_111 = cute.add_offset(%iter_31, %8) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<f32, rmem>
          %149 = builtin.unrealized_conversion_cast %ptr_110 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %150 = builtin.unrealized_conversion_cast %ptr_111 : !cute.ptr<f32, rmem> to !llvm.ptr
          %151 = llvm.load %149 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %151, %150 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %132 = llvm.load %85 : !llvm.ptr -> i8
        %133 = llvm.icmp "ne" %132, %14 : i8
        scf.if %133 {
          %148 = arith.muli %76, %c2_i64 : i64
          %iv_109 = cute.assume(%148) : (i64) -> !cute.i64<divby 2>
          %int_tuple_110 = cute.make_int_tuple(%iv_109) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
          %ptr_111 = cute.add_offset(%ptr_21, %int_tuple_110) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
          %ptr_112 = cute.add_offset(%iter_31, %7) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<f32, rmem, align<32>>
          %149 = builtin.unrealized_conversion_cast %ptr_111 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %150 = builtin.unrealized_conversion_cast %ptr_112 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
          %151 = llvm.load %149 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %151, %150 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %134 = llvm.load %86 : !llvm.ptr -> i8
        %135 = llvm.icmp "ne" %134, %14 : i8
        scf.if %135 {
          %148 = arith.muli %76, %c2_i64 : i64
          %149 = arith.addi %148, %c1_i64 : i64
          %int_tuple_109 = cute.make_int_tuple(%149) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_110 = cute.add_offset(%ptr_21, %int_tuple_109) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %ptr_111 = cute.add_offset(%iter_31, %6) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<f32, rmem>
          %150 = builtin.unrealized_conversion_cast %ptr_110 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %151 = builtin.unrealized_conversion_cast %ptr_111 : !cute.ptr<f32, rmem> to !llvm.ptr
          %152 = llvm.load %150 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %152, %151 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %136 = llvm.load %87 : !llvm.ptr -> i8
        %137 = llvm.icmp "ne" %136, %14 : i8
        scf.if %137 {
          %148 = arith.muli %76, %c2_i64 : i64
          %149 = arith.addi %148, %c2_i64 : i64
          %iv_109 = cute.assume(%149) : (i64) -> !cute.i64<divby 2>
          %int_tuple_110 = cute.make_int_tuple(%iv_109) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
          %ptr_111 = cute.add_offset(%ptr_21, %int_tuple_110) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
          %ptr_112 = cute.add_offset(%iter_31, %5) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<f32, rmem, align<8>>
          %150 = builtin.unrealized_conversion_cast %ptr_111 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %151 = builtin.unrealized_conversion_cast %ptr_112 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %152 = llvm.load %150 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %152, %151 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %138 = llvm.load %88 : !llvm.ptr -> i8
        %139 = llvm.icmp "ne" %138, %14 : i8
        scf.if %139 {
          %148 = arith.muli %76, %c2_i64 : i64
          %149 = arith.addi %148, %c3_i64 : i64
          %int_tuple_109 = cute.make_int_tuple(%149) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_110 = cute.add_offset(%ptr_21, %int_tuple_109) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %ptr_111 = cute.add_offset(%iter_31, %4) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<f32, rmem>
          %150 = builtin.unrealized_conversion_cast %ptr_110 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %151 = builtin.unrealized_conversion_cast %ptr_111 : !cute.ptr<f32, rmem> to !llvm.ptr
          %152 = llvm.load %150 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %152, %151 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %140 = llvm.load %89 : !llvm.ptr -> i8
        %141 = llvm.icmp "ne" %140, %14 : i8
        scf.if %141 {
          %148 = arith.muli %76, %c3_i64 : i64
          %iv_109 = cute.assume(%148) : (i64) -> !cute.i64<divby 3>
          %int_tuple_110 = cute.make_int_tuple(%iv_109) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
          %ptr_111 = cute.add_offset(%ptr_21, %int_tuple_110) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
          %ptr_112 = cute.add_offset(%iter_31, %3) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<f32, rmem, align<16>>
          %149 = builtin.unrealized_conversion_cast %ptr_111 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %150 = builtin.unrealized_conversion_cast %ptr_112 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
          %151 = llvm.load %149 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %151, %150 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %142 = llvm.load %90 : !llvm.ptr -> i8
        %143 = llvm.icmp "ne" %142, %14 : i8
        scf.if %143 {
          %148 = arith.muli %76, %c3_i64 : i64
          %149 = arith.addi %148, %c1_i64 : i64
          %int_tuple_109 = cute.make_int_tuple(%149) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_110 = cute.add_offset(%ptr_21, %int_tuple_109) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %ptr_111 = cute.add_offset(%iter_31, %2) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<f32, rmem>
          %150 = builtin.unrealized_conversion_cast %ptr_110 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %151 = builtin.unrealized_conversion_cast %ptr_111 : !cute.ptr<f32, rmem> to !llvm.ptr
          %152 = llvm.load %150 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %152, %151 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %144 = llvm.load %91 : !llvm.ptr -> i8
        %145 = llvm.icmp "ne" %144, %14 : i8
        scf.if %145 {
          %148 = arith.muli %76, %c3_i64 : i64
          %149 = arith.addi %148, %c2_i64 : i64
          %int_tuple_109 = cute.make_int_tuple(%149) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_110 = cute.add_offset(%ptr_21, %int_tuple_109) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %ptr_111 = cute.add_offset(%iter_31, %1) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<f32, rmem, align<8>>
          %150 = builtin.unrealized_conversion_cast %ptr_110 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %151 = builtin.unrealized_conversion_cast %ptr_111 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %152 = llvm.load %150 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %152, %151 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
        %146 = llvm.load %92 : !llvm.ptr -> i8
        %147 = llvm.icmp "ne" %146, %14 : i8
        scf.if %147 {
          %148 = arith.muli %76, %c3_i64 : i64
          %149 = arith.addi %148, %c3_i64 : i64
          %iv_109 = cute.assume(%149) : (i64) -> !cute.i64<divby 3>
          %int_tuple_110 = cute.make_int_tuple(%iv_109) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
          %ptr_111 = cute.add_offset(%ptr_21, %int_tuple_110) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
          %ptr_112 = cute.add_offset(%iter_31, %0) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<f32, rmem>
          %150 = builtin.unrealized_conversion_cast %ptr_111 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %151 = builtin.unrealized_conversion_cast %ptr_112 : !cute.ptr<f32, rmem> to !llvm.ptr
          %152 = llvm.load %150 {alignment = 4 : i64} : !llvm.ptr<1> -> vector<1xf32>
          llvm.store %152, %151 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr
        }
      } {llvm.loop_annotation = #loop_annotation}
      %93 = cute.memref.load_vec %rmem, row_major : !memref_rmem_f32_
      %94 = cute.memref.load_vec %rmem_30, row_major : !memref_rmem_f32_
      %95 = arith.addf %93, %94 : vector<16xf32>
      cute.memref.store_vec %95, %rmem_32, row_major : !memref_rmem_f32_
      %append_86 = cute.append_to_rank<2> (%lay_28, %19) : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">, !cute.layout<"1:0">
      %96 = cute.get_scalars(%append_86) <{only_dynamic}> : !cute.layout<"((1,(4,4)),1,1):((0,(1,?{i64})),0,0)">
      %stride_87 = cute.make_stride(%96) : (i64) -> !cute.stride<"((0,(1,?{i64})),(0,0))">
      %lay_88 = cute.make_layout(%18, %stride_87) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %append_89 = cute.append_to_rank<2> (%lay_88, %19) : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">, !cute.layout<"1:0">
      %97 = cute.get_scalars(%append_89) <{only_dynamic}> : !cute.layout<"((1,(4,4)),(1,1)):((0,(1,?{i64})),(0,0))">
      %stride_90 = cute.make_stride(%97) : (i64) -> !cute.stride<"((0,(1,?{i64})),((0,0)))">
      %lay_91 = cute.make_layout(%17, %stride_90) : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
      %98 = cute.get_scalars(%lay_91) <{only_dynamic}> : !cute.layout<"((1,(4,4)),((1,1))):((0,(1,?{i64})),((0,0)))">
      %stride_92 = cute.make_stride(%98) : (i64) -> !cute.stride<"((0,(1,?{i64})))">
      %lay_93 = cute.make_layout(%15, %stride_92) : !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
      %99 = cute.get_scalars(%lay_93) <{only_dynamic}> : !cute.layout<"((1,(4,4))):((0,(1,?{i64})))">
      %100 = builtin.unrealized_conversion_cast %iter_40 : !cute.ptr<i8, rmem, align<32>> to !llvm.ptr
      %ptr_94 = cute.add_offset(%iter_40, %16) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<i8, rmem>
      %101 = builtin.unrealized_conversion_cast %ptr_94 : !cute.ptr<i8, rmem> to !llvm.ptr
      %ptr_95 = cute.add_offset(%iter_40, %13) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<i8, rmem, align<2>>
      %102 = builtin.unrealized_conversion_cast %ptr_95 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
      %ptr_96 = cute.add_offset(%iter_40, %12) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<i8, rmem>
      %103 = builtin.unrealized_conversion_cast %ptr_96 : !cute.ptr<i8, rmem> to !llvm.ptr
      %ptr_97 = cute.add_offset(%iter_40, %11) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<i8, rmem, align<4>>
      %104 = builtin.unrealized_conversion_cast %ptr_97 : !cute.ptr<i8, rmem, align<4>> to !llvm.ptr
      %ptr_98 = cute.add_offset(%iter_40, %10) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<i8, rmem>
      %105 = builtin.unrealized_conversion_cast %ptr_98 : !cute.ptr<i8, rmem> to !llvm.ptr
      %ptr_99 = cute.add_offset(%iter_40, %9) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<i8, rmem, align<2>>
      %106 = builtin.unrealized_conversion_cast %ptr_99 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
      %ptr_100 = cute.add_offset(%iter_40, %8) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<i8, rmem>
      %107 = builtin.unrealized_conversion_cast %ptr_100 : !cute.ptr<i8, rmem> to !llvm.ptr
      %ptr_101 = cute.add_offset(%iter_40, %7) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<i8, rmem, align<8>>
      %108 = builtin.unrealized_conversion_cast %ptr_101 : !cute.ptr<i8, rmem, align<8>> to !llvm.ptr
      %ptr_102 = cute.add_offset(%iter_40, %6) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<i8, rmem>
      %109 = builtin.unrealized_conversion_cast %ptr_102 : !cute.ptr<i8, rmem> to !llvm.ptr
      %ptr_103 = cute.add_offset(%iter_40, %5) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<i8, rmem, align<2>>
      %110 = builtin.unrealized_conversion_cast %ptr_103 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
      %ptr_104 = cute.add_offset(%iter_40, %4) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<i8, rmem>
      %111 = builtin.unrealized_conversion_cast %ptr_104 : !cute.ptr<i8, rmem> to !llvm.ptr
      %ptr_105 = cute.add_offset(%iter_40, %3) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<i8, rmem, align<4>>
      %112 = builtin.unrealized_conversion_cast %ptr_105 : !cute.ptr<i8, rmem, align<4>> to !llvm.ptr
      %ptr_106 = cute.add_offset(%iter_40, %2) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<i8, rmem>
      %113 = builtin.unrealized_conversion_cast %ptr_106 : !cute.ptr<i8, rmem> to !llvm.ptr
      %ptr_107 = cute.add_offset(%iter_40, %1) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<i8, rmem, align<2>>
      %114 = builtin.unrealized_conversion_cast %ptr_107 : !cute.ptr<i8, rmem, align<2>> to !llvm.ptr
      %ptr_108 = cute.add_offset(%iter_40, %0) : (!cute.ptr<i8, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<i8, rmem>
      %115 = builtin.unrealized_conversion_cast %ptr_108 : !cute.ptr<i8, rmem> to !llvm.ptr
      scf.for %arg6 = %c0_i32 to %54 step %c1_i32  : i32 {
        %116 = llvm.load %100 : !llvm.ptr -> i8
        %117 = llvm.icmp "ne" %116, %14 : i8
        scf.if %117 {
          %148 = builtin.unrealized_conversion_cast %iter_33 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
          %149 = builtin.unrealized_conversion_cast %ptr_26 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %150 = llvm.load %148 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %150, %149 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %118 = llvm.load %101 : !llvm.ptr -> i8
        %119 = llvm.icmp "ne" %118, %14 : i8
        scf.if %119 {
          %ptr_109 = cute.add_offset(%iter_33, %16) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
          %ptr_110 = cute.add_offset(%ptr_26, %16) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
          %148 = builtin.unrealized_conversion_cast %ptr_109 : !cute.ptr<f32, rmem> to !llvm.ptr
          %149 = builtin.unrealized_conversion_cast %ptr_110 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %150 = llvm.load %148 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %150, %149 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %120 = llvm.load %102 : !llvm.ptr -> i8
        %121 = llvm.icmp "ne" %120, %14 : i8
        scf.if %121 {
          %ptr_109 = cute.add_offset(%iter_33, %13) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
          %ptr_110 = cute.add_offset(%ptr_26, %13) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
          %148 = builtin.unrealized_conversion_cast %ptr_109 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %149 = builtin.unrealized_conversion_cast %ptr_110 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %150 = llvm.load %148 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %150, %149 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %122 = llvm.load %103 : !llvm.ptr -> i8
        %123 = llvm.icmp "ne" %122, %14 : i8
        scf.if %123 {
          %ptr_109 = cute.add_offset(%iter_33, %12) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
          %ptr_110 = cute.add_offset(%ptr_26, %12) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
          %148 = builtin.unrealized_conversion_cast %ptr_109 : !cute.ptr<f32, rmem> to !llvm.ptr
          %149 = builtin.unrealized_conversion_cast %ptr_110 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %150 = llvm.load %148 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %150, %149 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %124 = llvm.load %104 : !llvm.ptr -> i8
        %125 = llvm.icmp "ne" %124, %14 : i8
        scf.if %125 {
          %ptr_109 = cute.add_offset(%iter_33, %11) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"4">) -> !cute.ptr<f32, rmem, align<16>>
          %int_tuple_110 = cute.make_int_tuple(%99) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_111 = cute.add_offset(%ptr_26, %int_tuple_110) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %148 = builtin.unrealized_conversion_cast %ptr_109 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
          %149 = builtin.unrealized_conversion_cast %ptr_111 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %150 = llvm.load %148 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %150, %149 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %126 = llvm.load %105 : !llvm.ptr -> i8
        %127 = llvm.icmp "ne" %126, %14 : i8
        scf.if %127 {
          %ptr_109 = cute.add_offset(%iter_33, %10) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"5">) -> !cute.ptr<f32, rmem>
          %148 = arith.addi %99, %c1_i64 : i64
          %int_tuple_110 = cute.make_int_tuple(%148) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_111 = cute.add_offset(%ptr_26, %int_tuple_110) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %149 = builtin.unrealized_conversion_cast %ptr_109 : !cute.ptr<f32, rmem> to !llvm.ptr
          %150 = builtin.unrealized_conversion_cast %ptr_111 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %151 = llvm.load %149 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %151, %150 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %128 = llvm.load %106 : !llvm.ptr -> i8
        %129 = llvm.icmp "ne" %128, %14 : i8
        scf.if %129 {
          %ptr_109 = cute.add_offset(%iter_33, %9) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"6">) -> !cute.ptr<f32, rmem, align<8>>
          %148 = arith.addi %99, %c2_i64 : i64
          %int_tuple_110 = cute.make_int_tuple(%148) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_111 = cute.add_offset(%ptr_26, %int_tuple_110) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %149 = builtin.unrealized_conversion_cast %ptr_109 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %150 = builtin.unrealized_conversion_cast %ptr_111 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %151 = llvm.load %149 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %151, %150 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %130 = llvm.load %107 : !llvm.ptr -> i8
        %131 = llvm.icmp "ne" %130, %14 : i8
        scf.if %131 {
          %ptr_109 = cute.add_offset(%iter_33, %8) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"7">) -> !cute.ptr<f32, rmem>
          %148 = arith.addi %99, %c3_i64 : i64
          %int_tuple_110 = cute.make_int_tuple(%148) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_111 = cute.add_offset(%ptr_26, %int_tuple_110) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %149 = builtin.unrealized_conversion_cast %ptr_109 : !cute.ptr<f32, rmem> to !llvm.ptr
          %150 = builtin.unrealized_conversion_cast %ptr_111 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %151 = llvm.load %149 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %151, %150 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %132 = llvm.load %108 : !llvm.ptr -> i8
        %133 = llvm.icmp "ne" %132, %14 : i8
        scf.if %133 {
          %ptr_109 = cute.add_offset(%iter_33, %7) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"8">) -> !cute.ptr<f32, rmem, align<32>>
          %148 = arith.muli %99, %c2_i64 : i64
          %iv_110 = cute.assume(%148) : (i64) -> !cute.i64<divby 2>
          %int_tuple_111 = cute.make_int_tuple(%iv_110) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
          %ptr_112 = cute.add_offset(%ptr_26, %int_tuple_111) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
          %149 = builtin.unrealized_conversion_cast %ptr_109 : !cute.ptr<f32, rmem, align<32>> to !llvm.ptr
          %150 = builtin.unrealized_conversion_cast %ptr_112 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %151 = llvm.load %149 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %151, %150 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %134 = llvm.load %109 : !llvm.ptr -> i8
        %135 = llvm.icmp "ne" %134, %14 : i8
        scf.if %135 {
          %ptr_109 = cute.add_offset(%iter_33, %6) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"9">) -> !cute.ptr<f32, rmem>
          %148 = arith.muli %99, %c2_i64 : i64
          %149 = arith.addi %148, %c1_i64 : i64
          %int_tuple_110 = cute.make_int_tuple(%149) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_111 = cute.add_offset(%ptr_26, %int_tuple_110) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %150 = builtin.unrealized_conversion_cast %ptr_109 : !cute.ptr<f32, rmem> to !llvm.ptr
          %151 = builtin.unrealized_conversion_cast %ptr_111 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %152 = llvm.load %150 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %152, %151 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %136 = llvm.load %110 : !llvm.ptr -> i8
        %137 = llvm.icmp "ne" %136, %14 : i8
        scf.if %137 {
          %ptr_109 = cute.add_offset(%iter_33, %5) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"10">) -> !cute.ptr<f32, rmem, align<8>>
          %148 = arith.muli %99, %c2_i64 : i64
          %149 = arith.addi %148, %c2_i64 : i64
          %iv_110 = cute.assume(%149) : (i64) -> !cute.i64<divby 2>
          %int_tuple_111 = cute.make_int_tuple(%iv_110) : (!cute.i64<divby 2>) -> !cute.int_tuple<"?{i64 div=2}">
          %ptr_112 = cute.add_offset(%ptr_26, %int_tuple_111) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=2}">) -> !cute.ptr<f32, gmem>
          %150 = builtin.unrealized_conversion_cast %ptr_109 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %151 = builtin.unrealized_conversion_cast %ptr_112 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %152 = llvm.load %150 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %152, %151 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %138 = llvm.load %111 : !llvm.ptr -> i8
        %139 = llvm.icmp "ne" %138, %14 : i8
        scf.if %139 {
          %ptr_109 = cute.add_offset(%iter_33, %4) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"11">) -> !cute.ptr<f32, rmem>
          %148 = arith.muli %99, %c2_i64 : i64
          %149 = arith.addi %148, %c3_i64 : i64
          %int_tuple_110 = cute.make_int_tuple(%149) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_111 = cute.add_offset(%ptr_26, %int_tuple_110) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %150 = builtin.unrealized_conversion_cast %ptr_109 : !cute.ptr<f32, rmem> to !llvm.ptr
          %151 = builtin.unrealized_conversion_cast %ptr_111 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %152 = llvm.load %150 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %152, %151 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %140 = llvm.load %112 : !llvm.ptr -> i8
        %141 = llvm.icmp "ne" %140, %14 : i8
        scf.if %141 {
          %ptr_109 = cute.add_offset(%iter_33, %3) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"12">) -> !cute.ptr<f32, rmem, align<16>>
          %148 = arith.muli %99, %c3_i64 : i64
          %iv_110 = cute.assume(%148) : (i64) -> !cute.i64<divby 3>
          %int_tuple_111 = cute.make_int_tuple(%iv_110) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
          %ptr_112 = cute.add_offset(%ptr_26, %int_tuple_111) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
          %149 = builtin.unrealized_conversion_cast %ptr_109 : !cute.ptr<f32, rmem, align<16>> to !llvm.ptr
          %150 = builtin.unrealized_conversion_cast %ptr_112 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %151 = llvm.load %149 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %151, %150 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %142 = llvm.load %113 : !llvm.ptr -> i8
        %143 = llvm.icmp "ne" %142, %14 : i8
        scf.if %143 {
          %ptr_109 = cute.add_offset(%iter_33, %2) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"13">) -> !cute.ptr<f32, rmem>
          %148 = arith.muli %99, %c3_i64 : i64
          %149 = arith.addi %148, %c1_i64 : i64
          %int_tuple_110 = cute.make_int_tuple(%149) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_111 = cute.add_offset(%ptr_26, %int_tuple_110) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %150 = builtin.unrealized_conversion_cast %ptr_109 : !cute.ptr<f32, rmem> to !llvm.ptr
          %151 = builtin.unrealized_conversion_cast %ptr_111 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %152 = llvm.load %150 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %152, %151 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %144 = llvm.load %114 : !llvm.ptr -> i8
        %145 = llvm.icmp "ne" %144, %14 : i8
        scf.if %145 {
          %ptr_109 = cute.add_offset(%iter_33, %1) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"14">) -> !cute.ptr<f32, rmem, align<8>>
          %148 = arith.muli %99, %c3_i64 : i64
          %149 = arith.addi %148, %c2_i64 : i64
          %int_tuple_110 = cute.make_int_tuple(%149) : (i64) -> !cute.int_tuple<"?{i64}">
          %ptr_111 = cute.add_offset(%ptr_26, %int_tuple_110) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
          %150 = builtin.unrealized_conversion_cast %ptr_109 : !cute.ptr<f32, rmem, align<8>> to !llvm.ptr
          %151 = builtin.unrealized_conversion_cast %ptr_111 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %152 = llvm.load %150 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %152, %151 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
        %146 = llvm.load %115 : !llvm.ptr -> i8
        %147 = llvm.icmp "ne" %146, %14 : i8
        scf.if %147 {
          %ptr_109 = cute.add_offset(%iter_33, %0) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"15">) -> !cute.ptr<f32, rmem>
          %148 = arith.muli %99, %c3_i64 : i64
          %149 = arith.addi %148, %c3_i64 : i64
          %iv_110 = cute.assume(%149) : (i64) -> !cute.i64<divby 3>
          %int_tuple_111 = cute.make_int_tuple(%iv_110) : (!cute.i64<divby 3>) -> !cute.int_tuple<"?{i64 div=3}">
          %ptr_112 = cute.add_offset(%ptr_26, %int_tuple_111) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64 div=3}">) -> !cute.ptr<f32, gmem>
          %150 = builtin.unrealized_conversion_cast %ptr_109 : !cute.ptr<f32, rmem> to !llvm.ptr
          %151 = builtin.unrealized_conversion_cast %ptr_112 : !cute.ptr<f32, gmem> to !llvm.ptr<1>
          %152 = llvm.load %150 {alignment = 4 : i64} : !llvm.ptr -> vector<1xf32>
          llvm.store %152, %151 {alignment = 4 : i64} : vector<1xf32>, !llvm.ptr<1>
        }
      } {llvm.loop_annotation = #loop_annotation}
      return
    }
  }
  func.func @cutlass_elementwise_add_tensor12172_02436_09155_14039_01618_04011_05577_09551_06691_04439_00270_01901_19478_25692_12886_22370_05617_20513_02754_03422_05042_12216_02342_13762_01969_(%arg0: !memref_gmem_f32_1, %arg1: !memref_gmem_f32_1, %arg2: !memref_gmem_f32_1) attributes {llvm.emit_c_interface} {
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
