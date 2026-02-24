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
      %48 = "cute.static"() : () -> !cute.int_tuple<"3">
      %49 = "cute.static"() : () -> !cute.int_tuple<"2">
      %50 = "cute.static"() : () -> !cute.int_tuple<"1">
      %51 = "cute.static"() : () -> !cute.layout<"(128,4):(4@1,1@1)">
      %52 = "cute.static"() : () -> !cute.layout<"(128,4):(4,1)">
      %53 = "nvvm.read.ptx.sreg.tid.x"() <{range = #llvm.constant_range<i32, 0, 1024>}> : () -> i32
      %54 = "nvvm.read.ptx.sreg.ctaid.x"() <{range = #llvm.constant_range<i32, 0, 2147483647>}> : () -> i32
      %55 = "cute.make_coord"(%54) : (i32) -> !cute.coord<"(_,?)">
      %56 = "cute.get_layout"(%arg2) : (!memref_gmem_f32_) -> !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">
      %57 = "cute.crd2idx"(%55, %56) : (!cute.coord<"(_,?)">, !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !cute.int_tuple<"?{i64}">
      %58 = "cute.get_iter"(%arg2) : (!memref_gmem_f32_) -> !cute.ptr<f32, gmem>
      %59 = "cute.add_offset"(%58, %57) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{i64}">) -> !cute.ptr<f32, gmem>
      %60 = "cute.get_layout"(%arg3) : (!memref_gmem_f8E4M3FN) -> !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{div=16},512,?{div=16}))">
      %61 = "cute.crd2idx"(%55, %60) : (!cute.coord<"(_,?)">, !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{div=16},512,?{div=16}))">) -> !cute.int_tuple<"?{div=16}">
      %62 = "cute.get_iter"(%arg3) : (!memref_gmem_f8E4M3FN) -> !cute.ptr<f8E4M3FN, gmem, align<16>>
      %63 = "cute.add_offset"(%62, %61) : (!cute.ptr<f8E4M3FN, gmem, align<16>>, !cute.int_tuple<"?{div=16}">) -> !cute.ptr<f8E4M3FN, gmem, align<16>>
      %64 = "cute.get_layout"(%arg4) : (!cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">) -> !cute.layout<"((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">
      %65 = "cute.crd2idx"(%55, %64) : (!cute.coord<"(_,?)">, !cute.layout<"((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">) -> !cute.int_tuple<"(?,?{div=512},?)">
      %66 = "cute.get_iter"(%arg4) : (!cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">) -> !cute.arith_tuple_iter<"(0,0,0)">
      %67 = "cute.add_offset"(%66, %65) : (!cute.arith_tuple_iter<"(0,0,0)">, !cute.int_tuple<"(?,?{div=512},?)">) -> !cute.arith_tuple_iter<"(?,?{div=512},?)">
      %68 = "cute.make_coord"(%53) : (i32) -> !cute.coord<"(?,_)">
      %69 = "cute.crd2idx"(%68, %52) : (!cute.coord<"(?,_)">, !cute.layout<"(128,4):(4,1)">) -> !cute.int_tuple<"?{div=4}">
      %70 = "cute.add_offset"(%59, %69) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f32, gmem>
      %71 = "cute.add_offset"(%63, %69) : (!cute.ptr<f8E4M3FN, gmem, align<16>>, !cute.int_tuple<"?{div=4}">) -> !cute.ptr<f8E4M3FN, gmem, align<4>>
      %72 = "cute.crd2idx"(%68, %51) : (!cute.coord<"(?,_)">, !cute.layout<"(128,4):(4@1,1@1)">) -> !cute.int_tuple<"(0,?{div=4})">
      %73 = "cute.add_offset"(%67, %72) : (!cute.arith_tuple_iter<"(?,?{div=512},?)">, !cute.int_tuple<"(0,?{div=4})">) -> !cute.arith_tuple_iter<"(?,?{div=4},?)">
      %74 = "cute.deref_arith_tuple_iter"(%73) : (!cute.arith_tuple_iter<"(?,?{div=4},?)">) -> !cute.int_tuple<"(?,?{div=4},?)">
      %75:3 = "cute.get_leaves"(%74) : (!cute.int_tuple<"(?,?{div=4},?)">) -> (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=4}">, !cute.int_tuple<"?">)
      %76 = "cute.make_coord"(%75#0, %75#1, %75#2) : (!cute.int_tuple<"?">, !cute.int_tuple<"?{div=4}">, !cute.int_tuple<"?">) -> !cute.coord<"(?,?{div=4},?)">
      %77 = "cute.make_coord"(%arg5, %arg6, %arg7) : (i32, i32, i32) -> !cute.coord<"(?,?,?)">
      %78:3 = "cute.get_scalars"(%76) : (!cute.coord<"(?,?{div=4},?)">) -> (i32, i32, i32)
      %79:3 = "cute.get_scalars"(%77) : (!cute.coord<"(?,?,?)">) -> (i32, i32, i32)
      %80 = "arith.cmpi"(%78#0, %79#0) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %81 = "arith.cmpi"(%78#1, %79#1) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %82 = "arith.andi"(%80, %81) : (i1, i1) -> i1
      %83 = "arith.cmpi"(%78#2, %79#2) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %84 = "arith.andi"(%82, %83) : (i1, i1) -> i1
      "cf.cond_br"(%84)[^bb1, ^bb2] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb1:  // pred: ^bb0
      %85 = "cute.memref.alloca"() : () -> !memref_rmem_f32_
      %86 = "cute.get_iter"(%85) : (!memref_rmem_f32_) -> !cute.ptr<f32, rmem, align<32>>
      %87 = "cute.memref.alloca"() : () -> !memref_rmem_f8E4M3FN
      %88 = "cute.get_iter"(%87) : (!memref_rmem_f8E4M3FN) -> !cute.ptr<f8E4M3FN, rmem, align<32>>
      %89 = "builtin.unrealized_conversion_cast"(%70) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %90 = "builtin.unrealized_conversion_cast"(%86) : (!cute.ptr<f32, rmem, align<32>>) -> !llvm.ptr
      %91 = "llvm.load"(%89) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%91, %90) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      %92 = "cute.add_offset"(%70, %50) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"1">) -> !cute.ptr<f32, gmem>
      %93 = "cute.add_offset"(%86, %50) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"1">) -> !cute.ptr<f32, rmem>
      %94 = "builtin.unrealized_conversion_cast"(%92) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %95 = "builtin.unrealized_conversion_cast"(%93) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
      %96 = "llvm.load"(%94) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%96, %95) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      %97 = "cute.add_offset"(%70, %49) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"2">) -> !cute.ptr<f32, gmem>
      %98 = "cute.add_offset"(%86, %49) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"2">) -> !cute.ptr<f32, rmem, align<8>>
      %99 = "builtin.unrealized_conversion_cast"(%97) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %100 = "builtin.unrealized_conversion_cast"(%98) : (!cute.ptr<f32, rmem, align<8>>) -> !llvm.ptr
      %101 = "llvm.load"(%99) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%101, %100) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      %102 = "cute.add_offset"(%70, %48) : (!cute.ptr<f32, gmem>, !cute.int_tuple<"3">) -> !cute.ptr<f32, gmem>
      %103 = "cute.add_offset"(%86, %48) : (!cute.ptr<f32, rmem, align<32>>, !cute.int_tuple<"3">) -> !cute.ptr<f32, rmem>
      %104 = "builtin.unrealized_conversion_cast"(%102) : (!cute.ptr<f32, gmem>) -> !llvm.ptr<1>
      %105 = "builtin.unrealized_conversion_cast"(%103) : (!cute.ptr<f32, rmem>) -> !llvm.ptr
      %106 = "llvm.load"(%104) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
      "llvm.store"(%106, %105) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
      %107 = "cute.memref.load_vec"(%85) : (!memref_rmem_f32_) -> vector<4xf32>
      %108 = "nvgpu.cvt_fptrunc"(%107) <{packed_kind = #nvgpu.subbytes_packedkind<compact>, rnd = #nvgpu.rnd<rn>}> : (vector<4xf32>) -> vector<4xf8E4M3FN>
      "cute.memref.store_vec"(%108, %87) : (vector<4xf8E4M3FN>, !memref_rmem_f8E4M3FN) -> ()
      %109 = "builtin.unrealized_conversion_cast"(%88) : (!cute.ptr<f8E4M3FN, rmem, align<32>>) -> !llvm.ptr
      %110 = "builtin.unrealized_conversion_cast"(%71) : (!cute.ptr<f8E4M3FN, gmem, align<4>>) -> !llvm.ptr<1>
      %111 = "llvm.load"(%109) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<4xi8>
      "llvm.store"(%111, %110) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<4xi8>, !llvm.ptr<1>) -> ()
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
    %32 = "cute.get_layout"(%arg1) : (!memref_gmem_f8E4M3FN1) -> !cute.layout<"(?,?{div=16},?):(?{div=16},1,?{div=16})">
    %33:5 = "cute.get_scalars"(%32) <{only_dynamic}> : (!cute.layout<"(?,?{div=16},?):(?{div=16},1,?{div=16})">) -> (i32, i32, i32, i32, i32)
    %34 = "arith.ceildivsi"(%33#1, %5) : (i32, i32) -> i32
    %35 = "cute.make_shape"(%33#0, %34, %33#2) : (i32, i32, i32) -> !cute.shape<"((1,512,1),(?,?,?))">
    %36 = "cute.assume"(%33#3) : (i32) -> !cute.i32<divby 16>
    %37 = "cute.assume"(%33#4) : (i32) -> !cute.i32<divby 16>
    %38 = "cute.make_stride"(%36, %37) : (!cute.i32<divby 16>, !cute.i32<divby 16>) -> !cute.stride<"((0,1,0),(?{div=16},512,?{div=16}))">
    %39 = "cute.make_layout"(%35, %38) <{operandSegmentSizes = array<i32: 1, 1>}> : (!cute.shape<"((1,512,1),(?,?,?))">, !cute.stride<"((0,1,0),(?{div=16},512,?{div=16}))">) -> !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{div=16},512,?{div=16}))">
    %40 = "cute.make_view"(%31, %39) : (!cute.ptr<f8E4M3FN, gmem, align<16>>, !cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{div=16},512,?{div=16}))">) -> !memref_gmem_f8E4M3FN
    %41 = "cute.size"(%24) <{mode = array<i32: 1>}> : (!cute.layout<"((1,512,1),(?,?,?)):((0,1,0),(?{i64},512,?{i64}))">) -> !cute.int_tuple<"?">
    %42 = "cute.get_leaves"(%41) : (!cute.int_tuple<"?">) -> !cute.int_tuple<"?">
    %43 = "cute.get_scalars"(%42) : (!cute.int_tuple<"?">) -> i32
    %44 = "cuda.cast"(%2) : (i64) -> !cuda.stream
    %45 = "cuda.launch_cfg.create"(%1, %0, %0, %2, %43, %0, %0, %44) <{maxNumAttrs = 3 : i32}> : (i32, i32, i32, i64, i32, i32, i32, !cuda.stream) -> !cuda.launch_cfg<max_attrs = 3>
    "cuda.launch_cfg.programmatic_stream_serialization_allowed"(%45, %3) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    "cuda.launch_cfg.cooperative"(%45, %3) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    %46 = "cuda.launch_ex"(%45, %25, %40, %30, %11, %13, %15) <{assume_kernel_attr = #cuda.assume_kernel_attr<true>, callee = @kernels::@kernel_cutlass__convert_kernel_tensorptrf32gmemo15121010i64512i64_tensorptrf8E4M3FNgmemalign16o15121010div16512div16_tensor000o15121011010512112____Float32_Float8E4M3FN_0}> : (!cuda.launch_cfg<max_attrs = 3>, !memref_gmem_f32_, !memref_gmem_f8E4M3FN, !cute.coord_tensor<"(0,0,0)", "((1,512,1),(?,?,?)):((0,1@1,0),(1@0,512@1,1@2))">, i32, i32, i32) -> !cuda.result
    %47 = "cuda.cast"(%46) : (!cuda.result) -> i32
    "cuda.return_if_error"(%47) : (i32) -> ()
    "func.return"(%3) : (i32) -> ()
  }) {llvm.emit_c_interface} : () -> ()
}) {gpu.container_module} : () -> ()
