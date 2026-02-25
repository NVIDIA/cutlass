!memref_gmem_f32_ = !cute.memref<f32, gmem, "((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">
!memref_gmem_f32_1 = !cute.memref<f32, gmem, "(?,?,?):(?{i64},1,?{i64})">
!memref_gmem_f8E4M3FN = !cute.memref<f8E4M3FN, gmem, align<16>, "((1,512,1),(?,?,?)):((0,1,0),(?{div=16},512,?{div=16}))">
!memref_gmem_f8E4M3FN1 = !cute.memref<f8E4M3FN, gmem, align<16>, "(?,?{div=16},?):(?{div=16},1,?{div=16})">
!memref_rmem_f32_ = !cute.memref<f32, rmem, align<32>, "4:1">
!memref_rmem_f8E4M3FN = !cute.memref<f8E4M3FN, rmem, align<32>, "4:1">
"builtin.module"() ({
  "gpu.module"() <{sym_name = "kernels"}> ({
    "cuda.kernel"() <{function_type = (!memref_gmem_f32_, !memref_gmem_f8E4M3FN, !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">, i32, i32, i32) -> (), sym_name = "kernel_cutlass__convert_kernel_tensorptrf32gmemo15121010i64512i64_tensorptrf8E4M3FNgmemalign16o15121010div16512div16_tensor000o15121011010512112____Float32_Float8E4M3FN_0"}> ({
    ^bb0(%arg2: !memref_gmem_f32_, %arg3: !memref_gmem_f8E4M3FN, %arg4: !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">, %arg5: i32, %arg6: i32, %arg7: i32):
      %102 = "cute.static"() : () -> !cute.int_tuple<"3">
      %103 = "cute.static"() : () -> !cute.int_tuple<"2">
      %104 = "cute.static"() : () -> !cute.int_tuple<"1">
      %105 = "cute.static"() : () -> !cute.layout<"(128,4):(4@1,1@1)">
      %106 = "cute.static"() : () -> !cute.layout<"(128,4):(4,1)">
      %107 = "nvvm.read.ptx.sreg.tid.x"() <{range = #llvm.constant_range<i32, 0, 1024>}> : () -> i32
      %108 = "nvvm.read.ptx.sreg.ctaid.x"() <{range = #llvm.constant_range<i32, 0, 2147483647>}> : () -> i32
      %109 = "cute.make_coord"(%108) : (i32) -> !cute.coord<"(_,?)">
      %110 = "cute.get_layout"(%arg2) : (!memref_gmem_f32_) -> !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">
      %111 = "cute.crd2idx"(%109, %110) : (!cute.coord<"(_,?)">, !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !cute.int_tuple<"?{i64}">
      %112 = "cute.get_iter"(%arg2) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %113 = "cute.add_offset"(%112, %111) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %114 = "cute.get_layout"(%arg3) : (!memref_gmem_f8E4M3FN) -> !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{div=16},512,?{div=16}))">
      %115 = "cute.crd2idx"(%109, %114) : (!cute.coord<"(_,?)">, !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{div=16},512,?{div=16}))">) -> !cute.int_tuple<"?{div=16}">
      %116 = "cute.get_iter"(%arg3) : (!memref_gmem_f8E4M3FN) -> !cute.ptr<f8E4M3FN, gmem, align<16>>
      %117 = "cute.add_offset"(%116, %115) : (!cute.ptr<f8E4M3FN, gmem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<f8E4M3FN, gmem, align<16>>
      %118 = "cute.get_layout"(%arg4) : (!cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">) -> !cute.layout<"((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">
      %119 = "cute.crd2idx"(%109, %118) : (!cute.coord<"(_,?)">, !cute.layout<"((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">) -> !cute.int_tuple<"(?,?{div=512},?)">
      %120 = "cute.get_iter"(%arg4) : (!cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">) -> !cute.arith_tuple_iter<"(0,0,0)">
      %121 = "cute.add_offset"(%120, %119) : (!cute.arith_tuple_iter<"(0,0,0)">, !cute.int_tuple<"(?,?{div=512},?)">) -> !cute.arith_tuple_iter<"(?,?{div=512},?)">
      %122 = "cute.make_coord"(%107) : (i32) -> !cute.coord<"(?,_)">
      %123 = "cute.crd2idx"(%122, %106) : (!cute.coord<"(?,_)">, !cute.layout<"(128,4):(4,1)">) -> !cute.int_tuple<"?{div=4}">
      %124 = "cute.add_offset"(%113, %123) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, gmem>
      %125 = "cute.add_offset"(%117, %123) : (!cute.ptr<f8E4M3FN, gmem, align<16>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f8E4M3FN, gmem, align<4>>
      %126 = "cute.crd2idx"(%122, %105) : (!cute.coord<"(?,_)">, !cute.layout<"(128,4):(4@1,1@1)">) -> !cute.int_tuple<"(0,?{div=4})">
      %127 = "cute.add_offset"(%121, %126) : (!cute.arith_tuple_iter<"(?,?{div=512},?)">, !cute.int_tuple<"(0,?{div=4})">) -> !cute.arith_tuple_iter<"(?,?{div=4},?)">
      %128 = "cute.deref_arith_tuple_iter"(%127) : (!cute.arith_tuple_iter<"(?,?{div=4},?)">) -> !cute.int_tuple<"(?,?{div=4},?)">
      %129:3 = "cute.get_leaves"(%128) : (!cute.int_tuple<"(?,?{div=4},?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=4}">, !cute.int_tuple<"?">)
      %130 = "cute.make_coord"(%129#0, %129#1, %129#2) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=4}">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?{div=4},?)">
      %131 = "cute.make_coord"(%arg5, %arg6, %arg7) : (i32, i32, i32) -> !cute.coord<"(?,?,?)">
      %132:3 = "cute.get_scalars"(%130) : (!cute.coord<"(?,?{div=4},?)">) -> (i32, i32, i32)
      %133:3 = "cute.get_scalars"(%131) : (!cute.coord<"(?,?,?)">) -> (i32, i32, i32)
      %134 = "arith.cmpi"(%132#0, %133#0) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %135 = "arith.cmpi"(%132#1, %133#1) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %136 = "arith.andi"(%134, %135) : (i1, i1) -> i1
      %137 = "arith.cmpi"(%132#2, %133#2) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %138 = "arith.andi"(%136, %137) : (i1, i1) -> i1
      "cf.cond_br"(%138)[^bb1, ^bb2] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb1:  // pred: ^bb0
      %139 = "cute.memref.alloca"() : () -> !memref_rmem_f32_
      %140 = "cute.get_iter"(%139) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %141 = "cute.memref.alloca"() : () -> !memref_rmem_f8E4M3FN
      %142 = "cute.get_iter"(%141) : (!memref_rmem_f8E4M3FN) -> !cute.ptr<f8E4M3FN, rmem, align<32>>
      %143 = "builtin.unrealized_conversion_cast"(%124) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %144 = "builtin.unrealized_conversion_cast"(%140) : (!cute.ptr<f32, rmem, align<32>>) -> !llvm.ptr
      %145 = "llvm.load"(%143) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%145, %144) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      %146 = "cute.add_offset"(%124, %104) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
      %147 = "cute.add_offset"(%140, %104) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
      %148 = "builtin.unrealized_conversion_cast"(%146) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %149 = "builtin.unrealized_conversion_cast"(%147) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
      %150 = "llvm.load"(%148) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%150, %149) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      %151 = "cute.add_offset"(%124, %103) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
      %152 = "cute.add_offset"(%140, %103) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
      %153 = "builtin.unrealized_conversion_cast"(%151) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %154 = "builtin.unrealized_conversion_cast"(%152) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
      %155 = "llvm.load"(%153) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%155, %154) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      %156 = "cute.add_offset"(%124, %102) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
      %157 = "cute.add_offset"(%140, %102) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
      %158 = "builtin.unrealized_conversion_cast"(%156) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %159 = "builtin.unrealized_conversion_cast"(%157) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
      %160 = "llvm.load"(%158) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%160, %159) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      %161 = "cute.memref.load_vec"(%139) : (!memref_rmem_f32_) -> vector<4xf32>
      %162 = "nvgpu.cvt_fptrunc"(%161) <{packed_kind = #nvgpu.subbytes_packedkind<compact>, rnd = #nvgpu.rnd<rn>}> : (vector<4xf32>) -> vector<4xf8E4M3FN>
      "cute.memref.store_vec"(%162, %141) : (vector<4xf8E4M3FN>, !memref_rmem_f8E4M3FN) -> ()
      %163 = "builtin.unrealized_conversion_cast"(%142) : (!cute.ptr<f8E4M3FN, rmem, align<32>>) -> !llvm.ptr
      %164 = "builtin.unrealized_conversion_cast"(%125) : (!cute.ptr<f8E4M3FN, gmem, align<4>>) -> !llvm.ptr<1>
      %165 = "llvm.load"(%163) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<4xi8>
      "llvm.store"(%165, %164) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<4xi8>, !llvm.ptr<1>) -> ()
      "cf.br"()[^bb2] : () -> ()
    ^bb2:  // 2 preds: ^bb0, ^bb1
      "cuda.return"() : () -> ()
    }) {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} : () -> ()
  }) : () -> ()
  "func.func"() <{function_type = (!memref_gmem_f32_1, !memref_gmem_f8E4M3FN1) -> i32, sym_name = "cutlass__convert_Tensorgmemoi641i64_Tensorgmemodiv16div161div16_1_4"}> ({
  ^bb0(%arg0: !memref_gmem_f32_1, %arg1: !memref_gmem_f8E4M3FN1):
    %0 = "arith.constant"() <{value = 1 : i32}> : () -> i32
    %1 = "arith.constant"() <{value = 128 : i32}> : () -> i32
    %2 = "arith.constant"() <{value = 0 : i64}> : () -> i64
    %3 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    %4 = "cute.static"() : () -> !cute.stride<"((0,1@1,0),(1@0,512@1,1@2))">
    %5 = "arith.constant"() <{value = 512 : i32}> : () -> i32
    %6 = "cute.static"() : () -> !cute.stride<"(1@0,1@1,1@2)">
    %7 = "cute.get_layout"(%arg0) : (!memref_gmem_f32_1) -> !cute.layout<"(?,?,?):(?{i64},1,?{i64})">
    %8 = "cute.get_shape"(%7) : (!cute.layout<"(?,?,?):(?{i64},1,?{i64})">) -> !cute.shape<"(?,?,?)">
    %9:3 = "cute.get_leaves"(%8) : (!cute.shape<"(?,?,?)">) -> (!cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?">)
    %10 = "cute.to_int_tuple"(%9#0) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %11 = "cute.get_scalars"(%10) : (!cute.int_tuple<"?">) -> i32
    %12 = "cute.to_int_tuple"(%9#1) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %13 = "cute.get_scalars"(%12) : (!cute.int_tuple<"?">) -> i32
    %14 = "cute.to_int_tuple"(%9#2) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %15 = "cute.get_scalars"(%14) : (!cute.int_tuple<"?">) -> i32
    %16 = "cute.make_shape"(%10, %12, %14) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.shape<"(?,?,?)">
    %17 = "cute.make_arith_tuple_iter"() : () -> !cute.arith_tuple_iter<"(0,0,0)">
    %18 = "cute.make_layout"(%16, %6) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(?,?,?)">, !cute.stride<"(1@0,1@1,1@2)">) -> !cute.layout<"(?,?,?):(1@0,1@1,1@2)">
    %19 = "cute.get_iter"(%arg0) : (!memref_gmem_f32_1) -> !cute.ptr<f32, gmem>
    %20:5 = "cute.get_scalars"(%7) <{only_dynamic}> : (!cute.layout<"(?,?,?):(?{i64},1,?{i64})">) -> (i32, i32, i32, i64, i64)
    %21 = "arith.constant"() <{value = 1 : i32}> : () -> i32
    %22 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    %23 = "arith.constant"() <{value = -1 : i32}> : () -> i32
    %24 = "arith.cmpi"(%5, %22) <{predicate = 4 : i64}> : (i32, i32) -> i1
    %25 = "arith.select"(%24, %23, %21) : (i1, i32, i32) -> i32
    %26 = "arith.addi"(%25, %20#1) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %27 = "arith.divsi"(%26, %5) : (i32, i32) -> i32
    %28 = "arith.addi"(%21, %27) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %29 = "arith.subi"(%22, %20#1) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %30 = "arith.divsi"(%29, %5) : (i32, i32) -> i32
    %31 = "arith.subi"(%22, %30) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %32 = "arith.cmpi"(%20#1, %22) <{predicate = 2 : i64}> : (i32, i32) -> i1
    %33 = "arith.cmpi"(%20#1, %22) <{predicate = 4 : i64}> : (i32, i32) -> i1
    %34 = "arith.cmpi"(%5, %22) <{predicate = 2 : i64}> : (i32, i32) -> i1
    %35 = "arith.cmpi"(%5, %22) <{predicate = 4 : i64}> : (i32, i32) -> i1
    %36 = "arith.andi"(%32, %34) : (i1, i1) -> i1
    %37 = "arith.andi"(%33, %35) : (i1, i1) -> i1
    %38 = "arith.ori"(%36, %37) : (i1, i1) -> i1
    %39 = "arith.select"(%38, %28, %31) : (i1, i32, i32) -> i32
    %40 = "cute.make_shape"(%20#0, %39, %20#2) : (i32, i32, i32) -> !cute.shape<"((1,512,1),(?,?,?))">
    %41 = "cute.make_stride"(%20#3, %20#4) : (i64, i64) -> !cute.stride<"((0,1,0),(?{i64},512,?{i64}))">
    %42 = "cute.make_layout"(%40, %41) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,512,1),(?,?,?))">, !cute.stride<"((0,1,0),(?{i64},512,?{i64}))">) -> !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">
    %43 = "cute.make_view"(%19, %42) : (!cute.ptr<f32, gmem>, !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !memref_gmem_f32_
    %44:3 = "cute.get_scalars"(%18) <{only_dynamic}> : (!cute.layout<"(?,?,?):(1@0,1@1,1@2)">) -> (i32, i32, i32)
    %45 = "arith.constant"() <{value = 1 : i32}> : () -> i32
    %46 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    %47 = "arith.constant"() <{value = -1 : i32}> : () -> i32
    %48 = "arith.cmpi"(%5, %46) <{predicate = 4 : i64}> : (i32, i32) -> i1
    %49 = "arith.select"(%48, %47, %45) : (i1, i32, i32) -> i32
    %50 = "arith.addi"(%49, %44#1) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %51 = "arith.divsi"(%50, %5) : (i32, i32) -> i32
    %52 = "arith.addi"(%45, %51) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %53 = "arith.subi"(%46, %44#1) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %54 = "arith.divsi"(%53, %5) : (i32, i32) -> i32
    %55 = "arith.subi"(%46, %54) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %56 = "arith.cmpi"(%44#1, %46) <{predicate = 2 : i64}> : (i32, i32) -> i1
    %57 = "arith.cmpi"(%44#1, %46) <{predicate = 4 : i64}> : (i32, i32) -> i1
    %58 = "arith.cmpi"(%5, %46) <{predicate = 2 : i64}> : (i32, i32) -> i1
    %59 = "arith.cmpi"(%5, %46) <{predicate = 4 : i64}> : (i32, i32) -> i1
    %60 = "arith.andi"(%56, %58) : (i1, i1) -> i1
    %61 = "arith.andi"(%57, %59) : (i1, i1) -> i1
    %62 = "arith.ori"(%60, %61) : (i1, i1) -> i1
    %63 = "arith.select"(%62, %52, %55) : (i1, i32, i32) -> i32
    %64 = "cute.make_shape"(%44#0, %63, %44#2) : (i32, i32, i32) -> !cute.shape<"((1,512,1),(?,?,?))">
    %65 = "cute.make_layout"(%64, %4) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,512,1),(?,?,?))">, !cute.stride<"((0,1@1,0),(1@0,512@1,1@2))">) -> !cute.layout<"((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">
    %66 = "cute.make_view"(%17, %65) : (!cute.arith_tuple_iter<"(0,0,0)">, !cute.layout<"((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">) -> !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">
    %67 = "cute.get_iter"(%arg1) : (!memref_gmem_f8E4M3FN1) -> !cute.ptr<f8E4M3FN, gmem, align<16>>
    %68 = "cute.get_layout"(%arg1) : (!memref_gmem_f8E4M3FN1) -> !cute.layout<"(?,?{div=16},?):(?{div=16},1,?{div=16})">
    %69:5 = "cute.get_scalars"(%68) <{only_dynamic}> : (!cute.layout<"(?,?{div=16},?):(?{div=16},1,?{div=16})">) -> (i32, i32, i32, i32, i32)
    %70 = "arith.constant"() <{value = 1 : i32}> : () -> i32
    %71 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    %72 = "arith.constant"() <{value = -1 : i32}> : () -> i32
    %73 = "arith.cmpi"(%5, %71) <{predicate = 4 : i64}> : (i32, i32) -> i1
    %74 = "arith.select"(%73, %72, %70) : (i1, i32, i32) -> i32
    %75 = "arith.addi"(%74, %69#1) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %76 = "arith.divsi"(%75, %5) : (i32, i32) -> i32
    %77 = "arith.addi"(%70, %76) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %78 = "arith.subi"(%71, %69#1) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %79 = "arith.divsi"(%78, %5) : (i32, i32) -> i32
    %80 = "arith.subi"(%71, %79) <{overflowFlags = #arith.overflow<none>}> : (i32, i32) -> i32
    %81 = "arith.cmpi"(%69#1, %71) <{predicate = 2 : i64}> : (i32, i32) -> i1
    %82 = "arith.cmpi"(%69#1, %71) <{predicate = 4 : i64}> : (i32, i32) -> i1
    %83 = "arith.cmpi"(%5, %71) <{predicate = 2 : i64}> : (i32, i32) -> i1
    %84 = "arith.cmpi"(%5, %71) <{predicate = 4 : i64}> : (i32, i32) -> i1
    %85 = "arith.andi"(%81, %83) : (i1, i1) -> i1
    %86 = "arith.andi"(%82, %84) : (i1, i1) -> i1
    %87 = "arith.ori"(%85, %86) : (i1, i1) -> i1
    %88 = "arith.select"(%87, %77, %80) : (i1, i32, i32) -> i32
    %89 = "cute.make_shape"(%69#0, %88, %69#2) : (i32, i32, i32) -> !cute.shape<"((1,512,1),(?,?,?))">
    %90 = "cute.assume"(%69#3) : (i32) -> !cute.i32<divby 16>
    %91 = "cute.assume"(%69#4) : (i32) -> !cute.i32<divby 16>
    %92 = "cute.make_stride"(%90, %91) : (!cute.i32<divby 16>, !cute.i32<divby 16>) -> !cute.stride<"((0,1,0),(?{div=16},512,?{div=16}))">
    %93 = "cute.make_layout"(%89, %92) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,512,1),(?,?,?))">, !cute.stride<"((0,1,0),(?{div=16},512,?{div=16}))">) -> !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{div=16},512,?{div=16}))">
    %94 = "cute.make_view"(%67, %93) : (!cute.ptr<f8E4M3FN, gmem, align<16>>, !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{div=16},512,?{div=16}))">) -> !memref_gmem_f8E4M3FN
    %95 = "cute.size"(%42) <{mode = array<i32: 1>}> : (!cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !cute.int_tuple<"?">
    %96 = "cute.get_leaves"(%95) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
    %97 = "cute.get_scalars"(%96) : (!cute.int_tuple<"?">) -> i32
    %98 = "cuda.cast"(%2) : (i64) -> !cuda.stream
    %99 = "cuda.launch_cfg.create"(%1, %0, %0, %2, %97, %0, %0, %98) <{maxNumAttrs = 3 : i32}> : (i32, i32, i32, i64, i32, i32, i32, !cuda.stream) -> !cuda.launch_cfg<max_attrs = 3>
    "cuda.launch_cfg.programmatic_stream_serialization_allowed"(%99, %3) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    "cuda.launch_cfg.cooperative"(%99, %3) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    %100 = "cuda.launch_ex"(%99, %43, %94, %66, %11, %13, %15) <{assume_kernel_attr = #cuda.assume_kernel_attr<true>, callee = @kernels::@kernel_cutlass__convert_kernel_tensorptrf32gmemo15121010i64512i64_tensorptrf8E4M3FNgmemalign16o15121010div16512div16_tensor000o15121011010512112____Float32_Float8E4M3FN_0}> : (!cuda.launch_cfg<max_attrs = 3>, !memref_gmem_f32_, !memref_gmem_f8E4M3FN, !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">, i32, i32, i32) -> !cuda.result
    %101 = "cuda.cast"(%100) : (!cuda.result) -> i32
    "cuda.return_if_error"(%101) : (i32) -> ()
    "func.return"(%3) : (i32) -> ()
  }) {llvm.emit_c_interface} : () -> ()
}) {gpu.container_module} : () -> ()
