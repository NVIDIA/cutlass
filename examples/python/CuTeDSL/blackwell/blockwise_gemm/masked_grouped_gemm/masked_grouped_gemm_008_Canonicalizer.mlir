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
      %53 = "cute.static"() : () -> !cute.int_tuple<"3">
      %54 = "cute.static"() : () -> !cute.int_tuple<"2">
      %55 = "cute.static"() : () -> !cute.int_tuple<"1">
      %56 = "cute.static"() : () -> !cute.layout<"(128,4):(4@1,1@1)">
      %57 = "cute.static"() : () -> !cute.layout<"(128,4):(4,1)">
      %58 = "nvvm.read.ptx.sreg.tid.x"() <{range = #llvm.constant_range<i32, 0, 1024>}> : () -> i32
      %59 = "nvvm.read.ptx.sreg.ctaid.x"() <{range = #llvm.constant_range<i32, 0, 2147483647>}> : () -> i32
      %60 = "cute.make_coord"(%59) : (i32) -> !cute.coord<"(_,?)">
      %61 = "cute.get_layout"(%arg2) : (!memref_gmem_f32_) -> !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">
      %62 = "cute.crd2idx"(%60, %61) : (!cute.coord<"(_,?)">, !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !cute.int_tuple<"?{i64}">
      %63 = "cute.get_iter"(%arg2) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %64 = "cute.add_offset"(%63, %62) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %65 = "cute.make_coord"(%59) : (i32) -> !cute.coord<"(_,?)">
      %66 = "cute.get_layout"(%arg3) : (!memref_gmem_f8E4M3FN) -> !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">
      %67 = "cute.crd2idx"(%65, %66) : (!cute.coord<"(_,?)">, !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !cute.int_tuple<"?{i64}">
      %68 = "cute.get_iter"(%arg3) : (!memref_gmem_f8E4M3FN) -> !cute.ptr<f8E4M3FN, gmem, align<16>>
      %69 = "cute.add_offset"(%68, %67) : (!cute.ptr<f8E4M3FN, gmem, align<16>>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f8E4M3FN, gmem>
      %70 = "cute.make_coord"(%59) : (i32) -> !cute.coord<"(_,?)">
      %71 = "cute.get_layout"(%arg4) : (!cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">) -> !cute.layout<"((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">
      %72 = "cute.crd2idx"(%70, %71) : (!cute.coord<"(_,?)">, !cute.layout<"((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">) -> !cute.int_tuple<"(?,?{div=512},?)">
      %73 = "cute.get_iter"(%arg4) : (!cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">) -> !cute.arith_tuple_iter<"(0,0,0)">
      %74 = "cute.add_offset"(%73, %72) : (!cute.arith_tuple_iter<"(0,0,0)">, !cute.int_tuple<"(?,?{div=512},?)">) -> !cute.arith_tuple_iter<"(?,?{div=512},?)">
      %75 = "cute.make_coord"(%58) : (i32) -> !cute.coord<"(?,_)">
      %76 = "cute.crd2idx"(%75, %57) : (!cute.coord<"(?,_)">, !cute.layout<"(128,4):(4,1)">) -> !cute.int_tuple<"?{div=4}">
      %77 = "cute.add_offset"(%64, %76) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, gmem>
      %78 = "cute.make_coord"(%58) : (i32) -> !cute.coord<"(?,_)">
      %79 = "cute.crd2idx"(%78, %57) : (!cute.coord<"(?,_)">, !cute.layout<"(128,4):(4,1)">) -> !cute.int_tuple<"?{div=4}">
      %80 = "cute.add_offset"(%69, %79) : (!cute.ptr<f8E4M3FN, gmem>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f8E4M3FN, gmem>
      %81 = "cute.make_coord"(%58) : (i32) -> !cute.coord<"(?,_)">
      %82 = "cute.crd2idx"(%81, %56) : (!cute.coord<"(?,_)">, !cute.layout<"(128,4):(4@1,1@1)">) -> !cute.int_tuple<"(0,?{div=4})">
      %83 = "cute.add_offset"(%74, %82) : (!cute.arith_tuple_iter<"(?,?{div=512},?)">, !cute.int_tuple<"(0,?{div=4})">) -> !cute.arith_tuple_iter<"(?,?{div=4},?)">
      %84 = "cute.deref_arith_tuple_iter"(%83) : (!cute.arith_tuple_iter<"(?,?{div=4},?)">) -> !cute.int_tuple<"(?,?{div=4},?)">
      %85:3 = "cute.get_leaves"(%84) : (!cute.int_tuple<"(?,?{div=4},?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=4}">, !cute.int_tuple<"?">)
      %86 = "cute.make_coord"(%85#0, %85#1, %85#2) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=4}">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?{div=4},?)">
      %87 = "cute.make_coord"(%arg5, %arg6, %arg7) : (i32, i32, i32) -> !cute.coord<"(?,?,?)">
      %88:3 = "cute.get_scalars"(%86) : (!cute.coord<"(?,?{div=4},?)">) -> (i32, i32, i32)
      %89:3 = "cute.get_scalars"(%87) : (!cute.coord<"(?,?,?)">) -> (i32, i32, i32)
      %90 = "arith.cmpi"(%88#0, %89#0) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %91 = "arith.cmpi"(%88#1, %89#1) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %92 = "arith.andi"(%90, %91) : (i1, i1) -> i1
      %93 = "arith.cmpi"(%88#2, %89#2) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %94 = "arith.andi"(%92, %93) : (i1, i1) -> i1
      "scf.if"(%94) ({
        %95 = "cute.memref.alloca"() : () -> !memref_rmem_f32_
        %96 = "cute.get_iter"(%95) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
        %97 = "cute.memref.alloca"() : () -> !memref_rmem_f8E4M3FN
        %98 = "cute.get_iter"(%97) : (!memref_rmem_f8E4M3FN) -> !cute.ptr<f8E4M3FN, rmem, align<32>>
        %99 = "builtin.unrealized_conversion_cast"(%77) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %100 = "builtin.unrealized_conversion_cast"(%96) : (!cute.ptr<f32, rmem, align<32>>) -> !llvm.ptr
        %101 = "llvm.load"(%99) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%101, %100) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        %102 = "cute.add_offset"(%77, %55) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
        %103 = "cute.add_offset"(%96, %55) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
        %104 = "builtin.unrealized_conversion_cast"(%102) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %105 = "builtin.unrealized_conversion_cast"(%103) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %106 = "llvm.load"(%104) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%106, %105) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        %107 = "cute.add_offset"(%77, %54) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
        %108 = "cute.add_offset"(%96, %54) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
        %109 = "builtin.unrealized_conversion_cast"(%107) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %110 = "builtin.unrealized_conversion_cast"(%108) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
        %111 = "llvm.load"(%109) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%111, %110) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        %112 = "cute.add_offset"(%77, %53) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
        %113 = "cute.add_offset"(%96, %53) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
        %114 = "builtin.unrealized_conversion_cast"(%112) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %115 = "builtin.unrealized_conversion_cast"(%113) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %116 = "llvm.load"(%114) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%116, %115) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        %117 = "cute.memref.load_vec"(%95) : (!memref_rmem_f32_) -> vector<4xf32>
        %118 = "nvgpu.cvt_fptrunc"(%117) <{packed_kind = #nvgpu.subbytes_packedkind<compact>, rnd = #nvgpu.rnd<rn>}> : (vector<4xf32>) -> vector<4xf8E4M3FN>
        "cute.memref.store_vec"(%118, %97) : (vector<4xf8E4M3FN>, !memref_rmem_f8E4M3FN) -> ()
        %119 = "builtin.unrealized_conversion_cast"(%98) : (!cute.ptr<f8E4M3FN, rmem, align<32>>) -> !llvm.ptr
        %120 = "builtin.unrealized_conversion_cast"(%80) : (!cute.ptr<f8E4M3FN, gmem>) -> !llvm.ptr<1>
        %121 = "llvm.load"(%119) <{alignment = 1 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xi8>
        "llvm.store"(%121, %120) <{alignment = 1 : i64, ordering = 0 : i64}> : (vector<1xi8>, !llvm.ptr<1>) -> ()
        %122 = "cute.add_offset"(%98, %55) : (!cute.ptr<f8E4M3FN, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f8E4M3FN, rmem>
        %123 = "cute.add_offset"(%80, %55) : (!cute.ptr<f8E4M3FN, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f8E4M3FN, gmem>
        %124 = "builtin.unrealized_conversion_cast"(%122) : (!cute.ptr<f8E4M3FN, rmem>) -> !llvm.ptr
        %125 = "builtin.unrealized_conversion_cast"(%123) : (!cute.ptr<f8E4M3FN, gmem>) -> !llvm.ptr<1>
        %126 = "llvm.load"(%124) <{alignment = 1 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xi8>
        "llvm.store"(%126, %125) <{alignment = 1 : i64, ordering = 0 : i64}> : (vector<1xi8>, !llvm.ptr<1>) -> ()
        %127 = "cute.add_offset"(%98, %54) : (!cute.ptr<f8E4M3FN, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f8E4M3FN, rmem, align<2>>
        %128 = "cute.add_offset"(%80, %54) : (!cute.ptr<f8E4M3FN, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f8E4M3FN, gmem>
        %129 = "builtin.unrealized_conversion_cast"(%127) : (!cute.ptr<f8E4M3FN, rmem, align<2>>) -> !llvm.ptr
        %130 = "builtin.unrealized_conversion_cast"(%128) : (!cute.ptr<f8E4M3FN, gmem>) -> !llvm.ptr<1>
        %131 = "llvm.load"(%129) <{alignment = 1 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xi8>
        "llvm.store"(%131, %130) <{alignment = 1 : i64, ordering = 0 : i64}> : (vector<1xi8>, !llvm.ptr<1>) -> ()
        %132 = "cute.add_offset"(%98, %53) : (!cute.ptr<f8E4M3FN, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f8E4M3FN, rmem>
        %133 = "cute.add_offset"(%80, %53) : (!cute.ptr<f8E4M3FN, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f8E4M3FN, gmem>
        %134 = "builtin.unrealized_conversion_cast"(%132) : (!cute.ptr<f8E4M3FN, rmem>) -> !llvm.ptr
        %135 = "builtin.unrealized_conversion_cast"(%133) : (!cute.ptr<f8E4M3FN, gmem>) -> !llvm.ptr<1>
        %136 = "llvm.load"(%134) <{alignment = 1 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xi8>
        "llvm.store"(%136, %135) <{alignment = 1 : i64, ordering = 0 : i64}> : (vector<1xi8>, !llvm.ptr<1>) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
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
    %16 = "cute.get_layout"(%arg0) : (!memref_gmem_f32_1) -> !cute.layout<"(?,?,?):(?{i64},1,?{i64})">
    %17 = "cute.get_shape"(%16) : (!cute.layout<"(?,?,?):(?{i64},1,?{i64})">) -> !cute.shape<"(?,?,?)">
    %18:3 = "cute.get_leaves"(%17) : (!cute.shape<"(?,?,?)">) -> (!cute.shape<"?">, !cute.shape<"?">, !cute.shape<"?">)
    %19 = "cute.to_int_tuple"(%18#0) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %20 = "cute.to_int_tuple"(%18#1) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %21 = "cute.to_int_tuple"(%18#2) : (!cute.shape<"?">) -> !cute.int_tuple<"?">
    %22 = "cute.make_shape"(%19, %20, %21) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.shape<"(?,?,?)">
    %23 = "cute.make_arith_tuple_iter"() : () -> !cute.arith_tuple_iter<"(0,0,0)">
    %24 = "cute.make_layout"(%22, %6) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(?,?,?)">, !cute.stride<"(1@0,1@1,1@2)">) -> !cute.layout<"(?,?,?):(1@0,1@1,1@2)">
    %25 = "cute.get_iter"(%arg0) : (!memref_gmem_f32_1) -> !cute.ptr<f32, gmem>
    %26 = "cute.get_layout"(%arg0) : (!memref_gmem_f32_1) -> !cute.layout<"(?,?,?):(?{i64},1,?{i64})">
    %27:5 = "cute.get_scalars"(%26) <{only_dynamic}> : (!cute.layout<"(?,?,?):(?{i64},1,?{i64})">) -> (i32, i32, i32, i64, i64)
    %28 = "arith.ceildivsi"(%27#1, %5) : (i32, i32) -> i32
    %29 = "cute.make_shape"(%27#0, %28, %27#2) : (i32, i32, i32) -> !cute.shape<"((1,512,1),(?,?,?))">
    %30 = "cute.make_stride"(%27#3, %27#4) : (i64, i64) -> !cute.stride<"((0,1,0),(?{i64},512,?{i64}))">
    %31 = "cute.make_layout"(%29, %30) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,512,1),(?,?,?))">, !cute.stride<"((0,1,0),(?{i64},512,?{i64}))">) -> !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">
    %32 = "cute.make_view"(%25, %31) : (!cute.ptr<f32, gmem>, !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !memref_gmem_f32_
    %33:3 = "cute.get_scalars"(%24) <{only_dynamic}> : (!cute.layout<"(?,?,?):(1@0,1@1,1@2)">) -> (i32, i32, i32)
    %34 = "arith.ceildivsi"(%33#1, %5) : (i32, i32) -> i32
    %35 = "cute.make_shape"(%33#0, %34, %33#2) : (i32, i32, i32) -> !cute.shape<"((1,512,1),(?,?,?))">
    %36 = "cute.make_layout"(%35, %4) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,512,1),(?,?,?))">, !cute.stride<"((0,1@1,0),(1@0,512@1,1@2))">) -> !cute.layout<"((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">
    %37 = "cute.make_view"(%23, %36) : (!cute.arith_tuple_iter<"(0,0,0)">, !cute.layout<"((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">) -> !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">
    %38 = "cute.get_iter"(%arg1) : (!memref_gmem_f8E4M3FN1) -> !cute.ptr<f8E4M3FN, gmem, align<16>>
    %39 = "cute.get_layout"(%arg1) : (!memref_gmem_f8E4M3FN1) -> !cute.layout<"(?,?,?):(?{i64},1,?{i64})">
    %40:5 = "cute.get_scalars"(%39) <{only_dynamic}> : (!cute.layout<"(?,?,?):(?{i64},1,?{i64})">) -> (i32, i32, i32, i64, i64)
    %41 = "arith.ceildivsi"(%40#1, %5) : (i32, i32) -> i32
    %42 = "cute.make_shape"(%40#0, %41, %40#2) : (i32, i32, i32) -> !cute.shape<"((1,512,1),(?,?,?))">
    %43 = "cute.make_stride"(%40#3, %40#4) : (i64, i64) -> !cute.stride<"((0,1,0),(?{i64},512,?{i64}))">
    %44 = "cute.make_layout"(%42, %43) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,512,1),(?,?,?))">, !cute.stride<"((0,1,0),(?{i64},512,?{i64}))">) -> !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">
    %45 = "cute.make_view"(%38, %44) : (!cute.ptr<f8E4M3FN, gmem, align<16>>, !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !memref_gmem_f8E4M3FN
    %46 = "cute.size"(%31) <{mode = array<i32: 1>}> : (!cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !cute.int_tuple<"?">
    %47 = "cute.get_leaves"(%46) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
    %48 = "cute.get_scalars"(%47) : (!cute.int_tuple<"?">) -> i32
    %49 = "cuda.cast"(%2) : (i64) -> !cuda.stream
    %50 = "cuda.launch_cfg.create"(%1, %0, %0, %2, %48, %0, %0, %49) <{maxNumAttrs = 3 : i32}> : (i32, i32, i32, i64, i32, i32, i32, !cuda.stream) -> !cuda.launch_cfg<max_attrs = 3>
    "cuda.launch_cfg.programmatic_stream_serialization_allowed"(%50, %3) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    "cuda.launch_cfg.cooperative"(%50, %3) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    %51 = "cuda.launch_ex"(%50, %32, %45, %37, %11, %13, %15) <{assume_kernel_attr = #cuda.assume_kernel_attr<true>, callee = @kernels::@kernel_cutlass__convert_kernel_tensorptrf32gmemo15121010i64512i64_tensorptrf8E4M3FNgmemalign16o15121010i64512i64_tensor000o15121011010512112____Float32_Float8E4M3FN_0}> : (!cuda.launch_cfg<max_attrs = 3>, !memref_gmem_f32_, !memref_gmem_f8E4M3FN, !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">, i32, i32, i32) -> !cuda.result
    %52 = "cuda.cast"(%51) : (!cuda.result) -> i32
    "cuda.return_if_error"(%52) : (i32) -> ()
    "func.return"(%3) : (i32) -> ()
  }) {llvm.emit_c_interface} : () -> ()
}) {gpu.container_module} : () -> ()
