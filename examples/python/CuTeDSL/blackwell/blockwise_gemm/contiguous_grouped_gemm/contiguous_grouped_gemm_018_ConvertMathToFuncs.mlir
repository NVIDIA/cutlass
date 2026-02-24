!memref_gmem_f32_ = !cute.memref<f32, gmem, "((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">
!memref_gmem_f32_1 = !cute.memref<f32, gmem, "(?,?,?):(?{i64},1,?{i64})">
!memref_gmem_f8E4M3FN = !cute.memref<f8E4M3FN, gmem, align<16>, "((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">
!memref_gmem_f8E4M3FN1 = !cute.memref<f8E4M3FN, gmem, align<16>, "(?,?,?):(?{i64},1,?{i64})">
!memref_rmem_f32_ = !cute.memref<f32, rmem, align<32>, "4:1">
!memref_rmem_f8E4M3FN = !cute.memref<f8E4M3FN, rmem, align<32>, "4:1">
"builtin.module"() ({
  "gpu.module"() <{sym_name = "kernels"}> ({
    "cuda.kernel"() <{function_type = (!memref_gmem_f32_, !memref_gmem_f8E4M3FN, !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">, i32, i32, i32) -> (), sym_name = "kernel_cutlass__convert_kernel_tensorptrf32gmemo15121010i64512i64_tensorptrf8E4M3FNgmemalign16o15121010i64512i64_tensor000o15121011010512112____Float32_Float8E4M3FN_0"}> ({
    ^bb0(%arg2: !memref_gmem_f32_, %arg3: !memref_gmem_f8E4M3FN, %arg4: !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">, %arg5: i32, %arg6: i32, %arg7: i32):
      %100 = "cute.static"() : () -> !cute.int_tuple<"3">
      %101 = "cute.static"() : () -> !cute.int_tuple<"2">
      %102 = "cute.static"() : () -> !cute.int_tuple<"1">
      %103 = "cute.static"() : () -> !cute.layout<"(128,4):(4@1,1@1)">
      %104 = "cute.static"() : () -> !cute.layout<"(128,4):(4,1)">
      %105 = "nvvm.read.ptx.sreg.tid.x"() <{range = #llvm.constant_range<i32, 0, 1024>}> : () -> i32
      %106 = "nvvm.read.ptx.sreg.ctaid.x"() <{range = #llvm.constant_range<i32, 0, 2147483647>}> : () -> i32
      %107 = "cute.make_coord"(%106) : (i32) -> !cute.coord<"(_,?)">
      %108 = "cute.get_layout"(%arg2) : (!memref_gmem_f32_) -> !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">
      %109 = "cute.crd2idx"(%107, %108) : (!cute.coord<"(_,?)">, !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !cute.int_tuple<"?{i64}">
      %110 = "cute.get_iter"(%arg2) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %111 = "cute.add_offset"(%110, %109) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %112 = "cute.get_layout"(%arg3) : (!memref_gmem_f8E4M3FN) -> !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">
      %113 = "cute.crd2idx"(%107, %112) : (!cute.coord<"(_,?)">, !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !cute.int_tuple<"?{i64}">
      %114 = "cute.get_iter"(%arg3) : (!memref_gmem_f8E4M3FN) -> !cute.ptr<f8E4M3FN, gmem, align<16>>
      %115 = "cute.add_offset"(%114, %113) : (!cute.ptr<f8E4M3FN, gmem, align<16>>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f8E4M3FN, gmem>
      %116 = "cute.get_layout"(%arg4) : (!cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">) -> !cute.layout<"((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">
      %117 = "cute.crd2idx"(%107, %116) : (!cute.coord<"(_,?)">, !cute.layout<"((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">) -> !cute.int_tuple<"(?,?{div=512},?)">
      %118 = "cute.get_iter"(%arg4) : (!cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">) -> !cute.arith_tuple_iter<"(0,0,0)">
      %119 = "cute.add_offset"(%118, %117) : (!cute.arith_tuple_iter<"(0,0,0)">, !cute.int_tuple<"(?,?{div=512},?)">) -> !cute.arith_tuple_iter<"(?,?{div=512},?)">
      %120 = "cute.make_coord"(%105) : (i32) -> !cute.coord<"(?,_)">
      %121 = "cute.crd2idx"(%120, %104) : (!cute.coord<"(?,_)">, !cute.layout<"(128,4):(4,1)">) -> !cute.int_tuple<"?{div=4}">
      %122 = "cute.add_offset"(%111, %121) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, gmem>
      %123 = "cute.add_offset"(%115, %121) : (!cute.ptr<f8E4M3FN, gmem>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f8E4M3FN, gmem>
      %124 = "cute.crd2idx"(%120, %103) : (!cute.coord<"(?,_)">, !cute.layout<"(128,4):(4@1,1@1)">) -> !cute.int_tuple<"(0,?{div=4})">
      %125 = "cute.add_offset"(%119, %124) : (!cute.arith_tuple_iter<"(?,?{div=512},?)">, !cute.int_tuple<"(0,?{div=4})">) -> !cute.arith_tuple_iter<"(?,?{div=4},?)">
      %126 = "cute.deref_arith_tuple_iter"(%125) : (!cute.arith_tuple_iter<"(?,?{div=4},?)">) -> !cute.int_tuple<"(?,?{div=4},?)">
      %127:3 = "cute.get_leaves"(%126) : (!cute.int_tuple<"(?,?{div=4},?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=4}">, !cute.int_tuple<"?">)
      %128 = "cute.make_coord"(%127#0, %127#1, %127#2) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=4}">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?{div=4},?)">
      %129 = "cute.make_coord"(%arg5, %arg6, %arg7) : (i32, i32, i32) -> !cute.coord<"(?,?,?)">
      %130:3 = "cute.get_scalars"(%128) : (!cute.coord<"(?,?{div=4},?)">) -> (i32, i32, i32)
      %131:3 = "cute.get_scalars"(%129) : (!cute.coord<"(?,?,?)">) -> (i32, i32, i32)
      %132 = "arith.cmpi"(%130#0, %131#0) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %133 = "arith.cmpi"(%130#1, %131#1) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %134 = "arith.andi"(%132, %133) : (i1, i1) -> i1
      %135 = "arith.cmpi"(%130#2, %131#2) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %136 = "arith.andi"(%134, %135) : (i1, i1) -> i1
      "cf.cond_br"(%136)[^bb1, ^bb2] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb1:  // pred: ^bb0
      %137 = "cute.memref.alloca"() : () -> !memref_rmem_f32_
      %138 = "cute.get_iter"(%137) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %139 = "cute.memref.alloca"() : () -> !memref_rmem_f8E4M3FN
      %140 = "cute.get_iter"(%139) : (!memref_rmem_f8E4M3FN) -> !cute.ptr<f8E4M3FN, rmem, align<32>>
      %141 = "builtin.unrealized_conversion_cast"(%122) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %142 = "builtin.unrealized_conversion_cast"(%138) : (!cute.ptr<f32, rmem, align<32>>) -> !llvm.ptr
      %143 = "llvm.load"(%141) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%143, %142) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      %144 = "cute.add_offset"(%122, %102) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
      %145 = "cute.add_offset"(%138, %102) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
      %146 = "builtin.unrealized_conversion_cast"(%144) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %147 = "builtin.unrealized_conversion_cast"(%145) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
      %148 = "llvm.load"(%146) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%148, %147) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      %149 = "cute.add_offset"(%122, %101) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
      %150 = "cute.add_offset"(%138, %101) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
      %151 = "builtin.unrealized_conversion_cast"(%149) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %152 = "builtin.unrealized_conversion_cast"(%150) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
      %153 = "llvm.load"(%151) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%153, %152) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      %154 = "cute.add_offset"(%122, %100) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
      %155 = "cute.add_offset"(%138, %100) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
      %156 = "builtin.unrealized_conversion_cast"(%154) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %157 = "builtin.unrealized_conversion_cast"(%155) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
      %158 = "llvm.load"(%156) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%158, %157) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      %159 = "cute.memref.load_vec"(%137) : (!memref_rmem_f32_) -> vector<4xf32>
      %160 = "nvgpu.cvt_fptrunc"(%159) <{packed_kind = #nvgpu.subbytes_packedkind<compact>, rnd = #nvgpu.rnd<rn>}> : (vector<4xf32>) -> vector<4xf8E4M3FN>
      "cute.memref.store_vec"(%160, %139) : (vector<4xf8E4M3FN>, !memref_rmem_f8E4M3FN) -> ()
      %161 = "builtin.unrealized_conversion_cast"(%140) : (!cute.ptr<f8E4M3FN, rmem, align<32>>) -> !llvm.ptr
      %162 = "builtin.unrealized_conversion_cast"(%123) : (!cute.ptr<f8E4M3FN, gmem>) -> !llvm.ptr<1>
      %163 = "llvm.load"(%161) <{alignment = 1 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xi8>
      "llvm.store"(%163, %162) <{alignment = 1 : i64, ordering = 0 : i64}> : (vector<1xi8>, !llvm.ptr<1>) -> ()
      %164 = "cute.add_offset"(%140, %102) : (!cute.ptr<f8E4M3FN, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f8E4M3FN, rmem>
      %165 = "cute.add_offset"(%123, %102) : (!cute.ptr<f8E4M3FN, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f8E4M3FN, gmem>
      %166 = "builtin.unrealized_conversion_cast"(%164) : (!cute.ptr<f8E4M3FN, rmem>) -> !llvm.ptr
      %167 = "builtin.unrealized_conversion_cast"(%165) : (!cute.ptr<f8E4M3FN, gmem>) -> !llvm.ptr<1>
      %168 = "llvm.load"(%166) <{alignment = 1 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xi8>
      "llvm.store"(%168, %167) <{alignment = 1 : i64, ordering = 0 : i64}> : (vector<1xi8>, !llvm.ptr<1>) -> ()
      %169 = "cute.add_offset"(%140, %101) : (!cute.ptr<f8E4M3FN, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f8E4M3FN, rmem, align<2>>
      %170 = "cute.add_offset"(%123, %101) : (!cute.ptr<f8E4M3FN, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f8E4M3FN, gmem>
      %171 = "builtin.unrealized_conversion_cast"(%169) : (!cute.ptr<f8E4M3FN, rmem, align<2>>) -> !llvm.ptr
      %172 = "builtin.unrealized_conversion_cast"(%170) : (!cute.ptr<f8E4M3FN, gmem>) -> !llvm.ptr<1>
      %173 = "llvm.load"(%171) <{alignment = 1 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xi8>
      "llvm.store"(%173, %172) <{alignment = 1 : i64, ordering = 0 : i64}> : (vector<1xi8>, !llvm.ptr<1>) -> ()
      %174 = "cute.add_offset"(%140, %100) : (!cute.ptr<f8E4M3FN, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f8E4M3FN, rmem>
      %175 = "cute.add_offset"(%123, %100) : (!cute.ptr<f8E4M3FN, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f8E4M3FN, gmem>
      %176 = "builtin.unrealized_conversion_cast"(%174) : (!cute.ptr<f8E4M3FN, rmem>) -> !llvm.ptr
      %177 = "builtin.unrealized_conversion_cast"(%175) : (!cute.ptr<f8E4M3FN, gmem>) -> !llvm.ptr<1>
      %178 = "llvm.load"(%176) <{alignment = 1 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xi8>
      "llvm.store"(%178, %177) <{alignment = 1 : i64, ordering = 0 : i64}> : (vector<1xi8>, !llvm.ptr<1>) -> ()
      "cf.br"()[^bb2] : () -> ()
    ^bb2:  // 2 preds: ^bb0, ^bb1
      "cuda.return"() : () -> ()
    }) {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} : () -> ()
  }) : () -> ()
  "func.func"() <{function_type = (!memref_gmem_f32_1, !memref_gmem_f8E4M3FN1) -> i32, sym_name = "cutlass__convert_Tensorgmemoi641i64_Tensorgmemoi641i64_1_4"}> ({
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
    %68 = "cute.get_layout"(%arg1) : (!memref_gmem_f8E4M3FN1) -> !cute.layout<"(?,?,?):(?{i64},1,?{i64})">
    %69:5 = "cute.get_scalars"(%68) <{only_dynamic}> : (!cute.layout<"(?,?,?):(?{i64},1,?{i64})">) -> (i32, i32, i32, i64, i64)
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
    %90 = "cute.make_stride"(%69#3, %69#4) : (i64, i64) -> !cute.stride<"((0,1,0),(?{i64},512,?{i64}))">
    %91 = "cute.make_layout"(%89, %90) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,512,1),(?,?,?))">, !cute.stride<"((0,1,0),(?{i64},512,?{i64}))">) -> !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">
    %92 = "cute.make_view"(%67, %91) : (!cute.ptr<f8E4M3FN, gmem, align<16>>, !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !memref_gmem_f8E4M3FN
    %93 = "cute.size"(%42) <{mode = array<i32: 1>}> : (!cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !cute.int_tuple<"?">
    %94 = "cute.get_leaves"(%93) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
    %95 = "cute.get_scalars"(%94) : (!cute.int_tuple<"?">) -> i32
    %96 = "cuda.cast"(%2) : (i64) -> !cuda.stream
    %97 = "cuda.launch_cfg.create"(%1, %0, %0, %2, %95, %0, %0, %96) <{maxNumAttrs = 3 : i32}> : (i32, i32, i32, i64, i32, i32, i32, !cuda.stream) -> !cuda.launch_cfg<max_attrs = 3>
    "cuda.launch_cfg.programmatic_stream_serialization_allowed"(%97, %3) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    "cuda.launch_cfg.cooperative"(%97, %3) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    %98 = "cuda.launch_ex"(%97, %43, %92, %66, %11, %13, %15) <{assume_kernel_attr = #cuda.assume_kernel_attr<true>, callee = @kernels::@kernel_cutlass__convert_kernel_tensorptrf32gmemo15121010i64512i64_tensorptrf8E4M3FNgmemalign16o15121010i64512i64_tensor000o15121011010512112____Float32_Float8E4M3FN_0}> : (!cuda.launch_cfg<max_attrs = 3>, !memref_gmem_f32_, !memref_gmem_f8E4M3FN, !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">, i32, i32, i32) -> !cuda.result
    %99 = "cuda.cast"(%98) : (!cuda.result) -> i32
    "cuda.return_if_error"(%99) : (i32) -> ()
    "func.return"(%3) : (i32) -> ()
  }) {llvm.emit_c_interface} : () -> ()
}) {gpu.container_module} : () -> ()
