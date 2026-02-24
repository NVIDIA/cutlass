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
      %55 = "cute.static"() : () -> !cute.int_tuple<"3">
      %56 = "cute.static"() : () -> !cute.int_tuple<"2">
      %57 = "cute.static"() : () -> !cute.int_tuple<"1">
      %58 = "cute.static"() : () -> !cute.layout<"(128,4):(4@1,1@1)">
      %59 = "cute.static"() : () -> !cute.layout<"(128,4):(4,1)">
      %60 = "nvvm.read.ptx.sreg.tid.x"() <{range = #llvm.constant_range<i32, 0, 1024>}> : () -> i32
      %61 = "nvvm.read.ptx.sreg.ctaid.x"() <{range = #llvm.constant_range<i32, 0, 2147483647>}> : () -> i32
      %62 = "cute.make_coord"(%61) : (i32) -> !cute.coord<"(_,?)">
      %63 = "cute.get_layout"(%arg2) : (!memref_gmem_f32_) -> !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">
      %64 = "cute.crd2idx"(%62, %63) : (!cute.coord<"(_,?)">, !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !cute.int_tuple<"?{i64}">
      %65 = "cute.get_iter"(%arg2) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %66 = "cute.add_offset"(%65, %64) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %67 = "cute.make_coord"(%61) : (i32) -> !cute.coord<"(_,?)">
      %68 = "cute.get_layout"(%arg3) : (!memref_gmem_f8E4M3FN) -> !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{div=16},512,?{div=16}))">
      %69 = "cute.crd2idx"(%67, %68) : (!cute.coord<"(_,?)">, !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{div=16},512,?{div=16}))">) -> !cute.int_tuple<"?{div=16}">
      %70 = "cute.get_iter"(%arg3) : (!memref_gmem_f8E4M3FN) -> !cute.ptr<f8E4M3FN, gmem, align<16>>
      %71 = "cute.add_offset"(%70, %69) : (!cute.ptr<f8E4M3FN, gmem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<f8E4M3FN, gmem, align<16>>
      %72 = "cute.make_coord"(%61) : (i32) -> !cute.coord<"(_,?)">
      %73 = "cute.get_layout"(%arg4) : (!cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">) -> !cute.layout<"((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">
      %74 = "cute.crd2idx"(%72, %73) : (!cute.coord<"(_,?)">, !cute.layout<"((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">) -> !cute.int_tuple<"(?,?{div=512},?)">
      %75 = "cute.get_iter"(%arg4) : (!cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">) -> !cute.arith_tuple_iter<"(0,0,0)">
      %76 = "cute.add_offset"(%75, %74) : (!cute.arith_tuple_iter<"(0,0,0)">, !cute.int_tuple<"(?,?{div=512},?)">) -> !cute.arith_tuple_iter<"(?,?{div=512},?)">
      %77 = "cute.make_coord"(%60) : (i32) -> !cute.coord<"(?,_)">
      %78 = "cute.crd2idx"(%77, %59) : (!cute.coord<"(?,_)">, !cute.layout<"(128,4):(4,1)">) -> !cute.int_tuple<"?{div=4}">
      %79 = "cute.add_offset"(%66, %78) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, gmem>
      %80 = "cute.make_coord"(%60) : (i32) -> !cute.coord<"(?,_)">
      %81 = "cute.crd2idx"(%80, %59) : (!cute.coord<"(?,_)">, !cute.layout<"(128,4):(4,1)">) -> !cute.int_tuple<"?{div=4}">
      %82 = "cute.add_offset"(%71, %81) : (!cute.ptr<f8E4M3FN, gmem, align<16>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f8E4M3FN, gmem, align<4>>
      %83 = "cute.make_coord"(%60) : (i32) -> !cute.coord<"(?,_)">
      %84 = "cute.crd2idx"(%83, %58) : (!cute.coord<"(?,_)">, !cute.layout<"(128,4):(4@1,1@1)">) -> !cute.int_tuple<"(0,?{div=4})">
      %85 = "cute.add_offset"(%76, %84) : (!cute.arith_tuple_iter<"(?,?{div=512},?)">, !cute.int_tuple<"(0,?{div=4})">) -> !cute.arith_tuple_iter<"(?,?{div=4},?)">
      %86 = "cute.deref_arith_tuple_iter"(%85) : (!cute.arith_tuple_iter<"(?,?{div=4},?)">) -> !cute.int_tuple<"(?,?{div=4},?)">
      %87:3 = "cute.get_leaves"(%86) : (!cute.int_tuple<"(?,?{div=4},?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=4}">, !cute.int_tuple<"?">)
      %88 = "cute.make_coord"(%87#0, %87#1, %87#2) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=4}">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?{div=4},?)">
      %89 = "cute.make_coord"(%arg5, %arg6, %arg7) : (i32, i32, i32) -> !cute.coord<"(?,?,?)">
      %90:3 = "cute.get_scalars"(%88) : (!cute.coord<"(?,?{div=4},?)">) -> (i32, i32, i32)
      %91:3 = "cute.get_scalars"(%89) : (!cute.coord<"(?,?,?)">) -> (i32, i32, i32)
      %92 = "arith.cmpi"(%90#0, %91#0) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %93 = "arith.cmpi"(%90#1, %91#1) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %94 = "arith.andi"(%92, %93) : (i1, i1) -> i1
      %95 = "arith.cmpi"(%90#2, %91#2) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %96 = "arith.andi"(%94, %95) : (i1, i1) -> i1
      "scf.if"(%96) ({
        %97 = "cute.memref.alloca"() : () -> !memref_rmem_f32_
        %98 = "cute.get_iter"(%97) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
        %99 = "cute.memref.alloca"() : () -> !memref_rmem_f8E4M3FN
        %100 = "cute.get_iter"(%99) : (!memref_rmem_f8E4M3FN) -> !cute.ptr<f8E4M3FN, rmem, align<32>>
        %101 = "builtin.unrealized_conversion_cast"(%79) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %102 = "builtin.unrealized_conversion_cast"(%98) : (!cute.ptr<f32, rmem, align<32>>) -> !llvm.ptr
        %103 = "llvm.load"(%101) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%103, %102) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        %104 = "cute.add_offset"(%79, %57) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
        %105 = "cute.add_offset"(%98, %57) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
        %106 = "builtin.unrealized_conversion_cast"(%104) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %107 = "builtin.unrealized_conversion_cast"(%105) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %108 = "llvm.load"(%106) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%108, %107) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        %109 = "cute.add_offset"(%79, %56) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
        %110 = "cute.add_offset"(%98, %56) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
        %111 = "builtin.unrealized_conversion_cast"(%109) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %112 = "builtin.unrealized_conversion_cast"(%110) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
        %113 = "llvm.load"(%111) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%113, %112) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        %114 = "cute.add_offset"(%79, %55) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
        %115 = "cute.add_offset"(%98, %55) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
        %116 = "builtin.unrealized_conversion_cast"(%114) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
        %117 = "builtin.unrealized_conversion_cast"(%115) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
        %118 = "llvm.load"(%116) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
        "llvm.store"(%118, %117) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
        %119 = "cute.memref.load_vec"(%97) : (!memref_rmem_f32_) -> vector<4xf32>
        %120 = "nvgpu.cvt_fptrunc"(%119) <{packed_kind = #nvgpu.subbytes_packedkind<compact>, rnd = #nvgpu.rnd<rn>}> : (vector<4xf32>) -> vector<4xf8E4M3FN>
        "cute.memref.store_vec"(%120, %99) : (vector<4xf8E4M3FN>, !memref_rmem_f8E4M3FN) -> ()
        %121 = "builtin.unrealized_conversion_cast"(%100) : (!cute.ptr<f8E4M3FN, rmem, align<32>>) -> !llvm.ptr
        %122 = "builtin.unrealized_conversion_cast"(%82) : (!cute.ptr<f8E4M3FN, gmem, align<4>>) -> !llvm.ptr<1>
        %123 = "llvm.load"(%121) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<4xi8>
        "llvm.store"(%123, %122) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<4xi8>, !llvm.ptr<1>) -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
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
    %39 = "cute.get_layout"(%arg1) : (!memref_gmem_f8E4M3FN1) -> !cute.layout<"(?,?{div=16},?):(?{div=16},1,?{div=16})">
    %40:5 = "cute.get_scalars"(%39) <{only_dynamic}> : (!cute.layout<"(?,?{div=16},?):(?{div=16},1,?{div=16})">) -> (i32, i32, i32, i32, i32)
    %41 = "arith.ceildivsi"(%40#1, %5) : (i32, i32) -> i32
    %42 = "cute.make_shape"(%40#0, %41, %40#2) : (i32, i32, i32) -> !cute.shape<"((1,512,1),(?,?,?))">
    %43 = "cute.assume"(%40#3) : (i32) -> !cute.i32<divby 16>
    %44 = "cute.assume"(%40#4) : (i32) -> !cute.i32<divby 16>
    %45 = "cute.make_stride"(%43, %44) : (!cute.i32<divby 16>, !cute.i32<divby 16>) -> !cute.stride<"((0,1,0),(?{div=16},512,?{div=16}))">
    %46 = "cute.make_layout"(%42, %45) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,512,1),(?,?,?))">, !cute.stride<"((0,1,0),(?{div=16},512,?{div=16}))">) -> !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{div=16},512,?{div=16}))">
    %47 = "cute.make_view"(%38, %46) : (!cute.ptr<f8E4M3FN, gmem, align<16>>, !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{div=16},512,?{div=16}))">) -> !memref_gmem_f8E4M3FN
    %48 = "cute.size"(%31) <{mode = array<i32: 1>}> : (!cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !cute.int_tuple<"?">
    %49 = "cute.get_leaves"(%48) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
    %50 = "cute.get_scalars"(%49) : (!cute.int_tuple<"?">) -> i32
    %51 = "cuda.cast"(%2) : (i64) -> !cuda.stream
    %52 = "cuda.launch_cfg.create"(%1, %0, %0, %2, %50, %0, %0, %51) <{maxNumAttrs = 3 : i32}> : (i32, i32, i32, i64, i32, i32, i32, !cuda.stream) -> !cuda.launch_cfg<max_attrs = 3>
    "cuda.launch_cfg.programmatic_stream_serialization_allowed"(%52, %3) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    "cuda.launch_cfg.cooperative"(%52, %3) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    %53 = "cuda.launch_ex"(%52, %32, %47, %37, %11, %13, %15) <{assume_kernel_attr = #cuda.assume_kernel_attr<true>, callee = @kernels::@kernel_cutlass__convert_kernel_tensorptrf32gmemo15121010i64512i64_tensorptrf8E4M3FNgmemalign16o15121010div16512div16_tensor000o15121011010512112____Float32_Float8E4M3FN_0}> : (!cuda.launch_cfg<max_attrs = 3>, !memref_gmem_f32_, !memref_gmem_f8E4M3FN, !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">, i32, i32, i32) -> !cuda.result
    %54 = "cuda.cast"(%53) : (!cuda.result) -> i32
    "cuda.return_if_error"(%54) : (i32) -> ()
    "func.return"(%3) : (i32) -> ()
  }) {llvm.emit_c_interface} : () -> ()
}) {gpu.container_module} : () -> ()
