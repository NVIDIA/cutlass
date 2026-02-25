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
      %46 = "cute.static"() : () -> !cute.int_tuple<"3">
      %47 = "cute.static"() : () -> !cute.int_tuple<"2">
      %48 = "cute.static"() : () -> !cute.int_tuple<"1">
      %49 = "cute.static"() : () -> !cute.layout<"(128,4):(4@1,1@1)">
      %50 = "cute.static"() : () -> !cute.layout<"(128,4):(4,1)">
      %51 = "nvvm.read.ptx.sreg.tid.x"() <{range = #llvm.constant_range<i32, 0, 1024>}> : () -> i32
      %52 = "nvvm.read.ptx.sreg.ctaid.x"() <{range = #llvm.constant_range<i32, 0, 2147483647>}> : () -> i32
      %53 = "cute.make_coord"(%52) : (i32) -> !cute.coord<"(_,?)">
      %54 = "cute.get_layout"(%arg2) : (!memref_gmem_f32_) -> !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">
      %55 = "cute.crd2idx"(%53, %54) : (!cute.coord<"(_,?)">, !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !cute.int_tuple<"?{i64}">
      %56 = "cute.get_iter"(%arg2) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %57 = "cute.add_offset"(%56, %55) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %58 = "cute.get_layout"(%arg3) : (!memref_gmem_f8E4M3FN) -> !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">
      %59 = "cute.crd2idx"(%53, %58) : (!cute.coord<"(_,?)">, !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !cute.int_tuple<"?{i64}">
      %60 = "cute.get_iter"(%arg3) : (!memref_gmem_f8E4M3FN) -> !cute.ptr<f8E4M3FN, gmem, align<16>>
      %61 = "cute.add_offset"(%60, %59) : (!cute.ptr<f8E4M3FN, gmem, align<16>>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f8E4M3FN, gmem>
      %62 = "cute.get_layout"(%arg4) : (!cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">) -> !cute.layout<"((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">
      %63 = "cute.crd2idx"(%53, %62) : (!cute.coord<"(_,?)">, !cute.layout<"((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">) -> !cute.int_tuple<"(?,?{div=512},?)">
      %64 = "cute.get_iter"(%arg4) : (!cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">) -> !cute.arith_tuple_iter<"(0,0,0)">
      %65 = "cute.add_offset"(%64, %63) : (!cute.arith_tuple_iter<"(0,0,0)">, !cute.int_tuple<"(?,?{div=512},?)">) -> !cute.arith_tuple_iter<"(?,?{div=512},?)">
      %66 = "cute.make_coord"(%51) : (i32) -> !cute.coord<"(?,_)">
      %67 = "cute.crd2idx"(%66, %50) : (!cute.coord<"(?,_)">, !cute.layout<"(128,4):(4,1)">) -> !cute.int_tuple<"?{div=4}">
      %68 = "cute.add_offset"(%57, %67) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, gmem>
      %69 = "cute.add_offset"(%61, %67) : (!cute.ptr<f8E4M3FN, gmem>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f8E4M3FN, gmem>
      %70 = "cute.crd2idx"(%66, %49) : (!cute.coord<"(?,_)">, !cute.layout<"(128,4):(4@1,1@1)">) -> !cute.int_tuple<"(0,?{div=4})">
      %71 = "cute.add_offset"(%65, %70) : (!cute.arith_tuple_iter<"(?,?{div=512},?)">, !cute.int_tuple<"(0,?{div=4})">) -> !cute.arith_tuple_iter<"(?,?{div=4},?)">
      %72 = "cute.deref_arith_tuple_iter"(%71) : (!cute.arith_tuple_iter<"(?,?{div=4},?)">) -> !cute.int_tuple<"(?,?{div=4},?)">
      %73:3 = "cute.get_leaves"(%72) : (!cute.int_tuple<"(?,?{div=4},?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=4}">, !cute.int_tuple<"?">)
      %74 = "cute.make_coord"(%73#0, %73#1, %73#2) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=4}">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?{div=4},?)">
      %75 = "cute.make_coord"(%arg5, %arg6, %arg7) : (i32, i32, i32) -> !cute.coord<"(?,?,?)">
      %76:3 = "cute.get_scalars"(%74) : (!cute.coord<"(?,?{div=4},?)">) -> (i32, i32, i32)
      %77:3 = "cute.get_scalars"(%75) : (!cute.coord<"(?,?,?)">) -> (i32, i32, i32)
      %78 = "arith.cmpi"(%76#0, %77#0) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %79 = "arith.cmpi"(%76#1, %77#1) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %80 = "arith.andi"(%78, %79) : (i1, i1) -> i1
      %81 = "arith.cmpi"(%76#2, %77#2) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %82 = "arith.andi"(%80, %81) : (i1, i1) -> i1
      "scf.if"(%82) ({
        %83 = "cute.memref.alloca"() : () -> !memref_rmem_f32_
        %84 = "cute.get_iter"(%83) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
        %85 = "cute.memref.alloca"() : () -> !memref_rmem_f8E4M3FN
        %86 = "cute.get_iter"(%85) : (!memref_rmem_f8E4M3FN) -> !cute.ptr<f8E4M3FN, rmem, align<32>>
        %87 = "builtin.unrealized_conversion_cast"(%68) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %88 = "builtin.unrealized_conversion_cast"(%84) : (!cute.ptr<f32, rmem, align<32>>) -> !llvm.ptr
        %89 = "llvm.load"(%87) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%89, %88) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        %90 = "cute.add_offset"(%68, %48) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
        %91 = "cute.add_offset"(%84, %48) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
        %92 = "builtin.unrealized_conversion_cast"(%90) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %93 = "builtin.unrealized_conversion_cast"(%91) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %94 = "llvm.load"(%92) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%94, %93) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        %95 = "cute.add_offset"(%68, %47) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
        %96 = "cute.add_offset"(%84, %47) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
        %97 = "builtin.unrealized_conversion_cast"(%95) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %98 = "builtin.unrealized_conversion_cast"(%96) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
        %99 = "llvm.load"(%97) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%99, %98) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        %100 = "cute.add_offset"(%68, %46) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
        %101 = "cute.add_offset"(%84, %46) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
        %102 = "builtin.unrealized_conversion_cast"(%100) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %103 = "builtin.unrealized_conversion_cast"(%101) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %104 = "llvm.load"(%102) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%104, %103) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        %105 = "cute.memref.load_vec"(%83) : (!memref_rmem_f32_) -> vector<4xf32>
        %106 = "nvgpu.cvt_fptrunc"(%105) <{packed_kind = #nvgpu.subbytes_packedkind<compact>, rnd = #nvgpu.rnd<rn>}> : (vector<4xf32>) -> vector<4xf8E4M3FN>
        "cute.memref.store_vec"(%106, %85) : (vector<4xf8E4M3FN>, !memref_rmem_f8E4M3FN) -> ()
        %107 = "builtin.unrealized_conversion_cast"(%86) : (!cute.ptr<f8E4M3FN, rmem, align<32>>) -> !llvm.ptr
        %108 = "builtin.unrealized_conversion_cast"(%69) : (!cute.ptr<f8E4M3FN, gmem>) -> !llvm.ptr<1>
        %109 = "llvm.load"(%107) <{alignment = 1 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xi8>
        "llvm.store"(%109, %108) <{alignment = 1 : i64, ordering = 0 : i64}> : (vector<1xi8>, !llvm.ptr<1>) -> ()
        %110 = "cute.add_offset"(%86, %48) : (!cute.ptr<f8E4M3FN, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f8E4M3FN, rmem>
        %111 = "cute.add_offset"(%69, %48) : (!cute.ptr<f8E4M3FN, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f8E4M3FN, gmem>
        %112 = "builtin.unrealized_conversion_cast"(%110) : (!cute.ptr<f8E4M3FN, rmem>) -> !llvm.ptr
        %113 = "builtin.unrealized_conversion_cast"(%111) : (!cute.ptr<f8E4M3FN, gmem>) -> !llvm.ptr<1>
        %114 = "llvm.load"(%112) <{alignment = 1 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xi8>
        "llvm.store"(%114, %113) <{alignment = 1 : i64, ordering = 0 : i64}> : (vector<1xi8>, !llvm.ptr<1>) -> ()
        %115 = "cute.add_offset"(%86, %47) : (!cute.ptr<f8E4M3FN, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f8E4M3FN, rmem, align<2>>
        %116 = "cute.add_offset"(%69, %47) : (!cute.ptr<f8E4M3FN, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f8E4M3FN, gmem>
        %117 = "builtin.unrealized_conversion_cast"(%115) : (!cute.ptr<f8E4M3FN, rmem, align<2>>) -> !llvm.ptr
        %118 = "builtin.unrealized_conversion_cast"(%116) : (!cute.ptr<f8E4M3FN, gmem>) -> !llvm.ptr<1>
        %119 = "llvm.load"(%117) <{alignment = 1 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xi8>
        "llvm.store"(%119, %118) <{alignment = 1 : i64, ordering = 0 : i64}> : (vector<1xi8>, !llvm.ptr<1>) -> ()
        %120 = "cute.add_offset"(%86, %46) : (!cute.ptr<f8E4M3FN, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f8E4M3FN, rmem>
        %121 = "cute.add_offset"(%69, %46) : (!cute.ptr<f8E4M3FN, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f8E4M3FN, gmem>
        %122 = "builtin.unrealized_conversion_cast"(%120) : (!cute.ptr<f8E4M3FN, rmem>) -> !llvm.ptr
        %123 = "builtin.unrealized_conversion_cast"(%121) : (!cute.ptr<f8E4M3FN, gmem>) -> !llvm.ptr<1>
        %124 = "llvm.load"(%122) <{alignment = 1 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xi8>
        "llvm.store"(%124, %123) <{alignment = 1 : i64, ordering = 0 : i64}> : (vector<1xi8>, !llvm.ptr<1>) -> ()
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
    %16 = "cute.make_shape"(%10, %12, %14) : (!cute.int_tuple<"?">, !cute.int_tuple<"?">, !cute.int_tuple<"?">) -> !cute.shape<"(?,?,?)">
    %17 = "cute.make_arith_tuple_iter"() : () -> !cute.arith_tuple_iter<"(0,0,0)">
    %18 = "cute.make_layout"(%16, %6) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"(?,?,?)">, !cute.stride<"(1@0,1@1,1@2)">) -> !cute.layout<"(?,?,?):(1@0,1@1,1@2)">
    %19 = "cute.get_iter"(%arg0) : (!memref_gmem_f32_1) -> !cute.ptr<f32, gmem>
    %20:5 = "cute.get_scalars"(%7) <{only_dynamic}> : (!cute.layout<"(?,?,?):(?{i64},1,?{i64})">) -> (i32, i32, i32, i64, i64)
    %21 = "arith.ceildivsi"(%20#1, %5) : (i32, i32) -> i32
    %22 = "cute.make_shape"(%20#0, %21, %20#2) : (i32, i32, i32) -> !cute.shape<"((1,512,1),(?,?,?))">
    %23 = "cute.make_stride"(%20#3, %20#4) : (i64, i64) -> !cute.stride<"((0,1,0),(?{i64},512,?{i64}))">
    %24 = "cute.make_layout"(%22, %23) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,512,1),(?,?,?))">, !cute.stride<"((0,1,0),(?{i64},512,?{i64}))">) -> !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">
    %25 = "cute.make_view"(%19, %24) : (!cute.ptr<f32, gmem>, !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !memref_gmem_f32_
    %26:3 = "cute.get_scalars"(%18) <{only_dynamic}> : (!cute.layout<"(?,?,?):(1@0,1@1,1@2)">) -> (i32, i32, i32)
    %27 = "arith.ceildivsi"(%26#1, %5) : (i32, i32) -> i32
    %28 = "cute.make_shape"(%26#0, %27, %26#2) : (i32, i32, i32) -> !cute.shape<"((1,512,1),(?,?,?))">
    %29 = "cute.make_layout"(%28, %4) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,512,1),(?,?,?))">, !cute.stride<"((0,1@1,0),(1@0,512@1,1@2))">) -> !cute.layout<"((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">
    %30 = "cute.make_view"(%17, %29) : (!cute.arith_tuple_iter<"(0,0,0)">, !cute.layout<"((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">) -> !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">
    %31 = "cute.get_iter"(%arg1) : (!memref_gmem_f8E4M3FN1) -> !cute.ptr<f8E4M3FN, gmem, align<16>>
    %32 = "cute.get_layout"(%arg1) : (!memref_gmem_f8E4M3FN1) -> !cute.layout<"(?,?,?):(?{i64},1,?{i64})">
    %33:5 = "cute.get_scalars"(%32) <{only_dynamic}> : (!cute.layout<"(?,?,?):(?{i64},1,?{i64})">) -> (i32, i32, i32, i64, i64)
    %34 = "arith.ceildivsi"(%33#1, %5) : (i32, i32) -> i32
    %35 = "cute.make_shape"(%33#0, %34, %33#2) : (i32, i32, i32) -> !cute.shape<"((1,512,1),(?,?,?))">
    %36 = "cute.make_stride"(%33#3, %33#4) : (i64, i64) -> !cute.stride<"((0,1,0),(?{i64},512,?{i64}))">
    %37 = "cute.make_layout"(%35, %36) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,512,1),(?,?,?))">, !cute.stride<"((0,1,0),(?{i64},512,?{i64}))">) -> !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">
    %38 = "cute.make_view"(%31, %37) : (!cute.ptr<f8E4M3FN, gmem, align<16>>, !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !memref_gmem_f8E4M3FN
    %39 = "cute.size"(%24) <{mode = array<i32: 1>}> : (!cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !cute.int_tuple<"?">
    %40 = "cute.get_leaves"(%39) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
    %41 = "cute.get_scalars"(%40) : (!cute.int_tuple<"?">) -> i32
    %42 = "cuda.cast"(%2) : (i64) -> !cuda.stream
    %43 = "cuda.launch_cfg.create"(%1, %0, %0, %2, %41, %0, %0, %42) <{maxNumAttrs = 3 : i32}> : (i32, i32, i32, i64, i32, i32, i32, !cuda.stream) -> !cuda.launch_cfg<max_attrs = 3>
    "cuda.launch_cfg.programmatic_stream_serialization_allowed"(%43, %3) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    "cuda.launch_cfg.cooperative"(%43, %3) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    %44 = "cuda.launch_ex"(%43, %25, %38, %30, %11, %13, %15) <{assume_kernel_attr = #cuda.assume_kernel_attr<true>, callee = @kernels::@kernel_cutlass__convert_kernel_tensorptrf32gmemo15121010i64512i64_tensorptrf8E4M3FNgmemalign16o15121010i64512i64_tensor000o15121011010512112____Float32_Float8E4M3FN_0}> : (!cuda.launch_cfg<max_attrs = 3>, !memref_gmem_f32_, !memref_gmem_f8E4M3FN, !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">, i32, i32, i32) -> !cuda.result
    %45 = "cuda.cast"(%44) : (!cuda.result) -> i32
    "cuda.return_if_error"(%45) : (i32) -> ()
    "func.return"(%3) : (i32) -> ()
  }) {llvm.emit_c_interface} : () -> ()
}) {gpu.container_module} : () -> ()
