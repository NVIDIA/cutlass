"gpu.module"() <{sym_name = "kernels"}> ({
  "llvm.func"() <{CConv = #llvm.cconv<ccc>, function_type = !llvm.func<void (struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)>, struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)>, struct<(struct<()>, struct<(struct<(i32, i32, i32)>, struct<()>)>)>, i32, i32, i32)>, linkage = #llvm.linkage<external>, sym_name = "kernel_cutlass__convert_kernel_tensorptrf32gmemo15121010i64512i64_tensorptrf8E4M3FNgmemalign16o15121010i64512i64_tensor000o15121011010512112____Float32_Float8E4M3FN_0", visibility_ = 0 : i64}> ({
  ^bb0(%arg0: !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)>, %arg1: !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)>, %arg2: !llvm.struct<(struct<()>, struct<(struct<(i32, i32, i32)>, struct<()>)>)>, %arg3: i32, %arg4: i32, %arg5: i32):
    %0 = "llvm.mlir.constant"() <{value = 1 : i64}> : () -> i64
    %1 = "llvm.mlir.constant"() <{value = 3 : i64}> : () -> i64
    %2 = "llvm.mlir.constant"() <{value = 2 : i64}> : () -> i64
    %3 = "llvm.mlir.constant"() <{value = 0 : i64}> : () -> i64
    %4 = "llvm.mlir.constant"() <{value = 0 : i32}> : () -> i32
    %5 = "llvm.mlir.constant"() <{value = 16 : i32}> : () -> i32
    %6 = "llvm.mlir.undef"() : () -> vector<1xi32>
    %7 = "llvm.mlir.constant"() <{value = 512 : i32}> : () -> i32
    %8 = "llvm.mlir.constant"() <{value = 4 : i32}> : () -> i32
    %9 = "llvm.alloca"(%8) <{alignment = 32 : i64, elem_type = i8}> : (i32) -> !llvm.ptr
    %10 = "llvm.alloca"(%8) <{alignment = 32 : i64, elem_type = i32}> : (i32) -> !llvm.ptr
    %11 = "nvvm.read.ptx.sreg.tid.x"() <{range = #llvm.constant_range<i32, 0, 1024>}> : () -> i32
    %12 = "nvvm.read.ptx.sreg.ctaid.x"() <{range = #llvm.constant_range<i32, 0, 2147483647>}> : () -> i32
    %13 = "llvm.extractvalue"(%arg0) <{position = array<i64: 1>}> : (!llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)>) -> !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>
    %14 = "llvm.extractvalue"(%13) <{position = array<i64: 0>}> : (!llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>) -> !llvm.struct<(i32, i32, i32)>
    %15 = "llvm.extractvalue"(%14) <{position = array<i64: 0>}> : (!llvm.struct<(i32, i32, i32)>) -> i32
    %16 = "llvm.extractvalue"(%14) <{position = array<i64: 1>}> : (!llvm.struct<(i32, i32, i32)>) -> i32
    %17 = "llvm.extractvalue"(%13) <{position = array<i64: 1>}> : (!llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>) -> !llvm.struct<(i64, i64)>
    %18 = "llvm.extractvalue"(%17) <{position = array<i64: 0>}> : (!llvm.struct<(i64, i64)>) -> i64
    %19 = "llvm.extractvalue"(%17) <{position = array<i64: 1>}> : (!llvm.struct<(i64, i64)>) -> i64
    %20 = "llvm.sdiv"(%12, %15) : (i32, i32) -> i32
    %21 = "llvm.srem"(%12, %15) : (i32, i32) -> i32
    %22 = "llvm.sext"(%21) : (i32) -> i64
    %23 = "llvm.mul"(%22, %18) <{overflowFlags = #llvm.overflow<none>}> : (i64, i64) -> i64
    %24 = "llvm.sdiv"(%20, %16) : (i32, i32) -> i32
    %25 = "llvm.srem"(%20, %16) : (i32, i32) -> i32
    %26 = "llvm.mul"(%25, %7) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %27 = "llvm.sext"(%26) : (i32) -> i64
    %28 = "llvm.add"(%23, %27) <{overflowFlags = #llvm.overflow<none>}> : (i64, i64) -> i64
    %29 = "llvm.sext"(%24) : (i32) -> i64
    %30 = "llvm.mul"(%29, %19) <{overflowFlags = #llvm.overflow<none>}> : (i64, i64) -> i64
    %31 = "llvm.add"(%28, %30) <{overflowFlags = #llvm.overflow<none>}> : (i64, i64) -> i64
    %32 = "llvm.extractvalue"(%arg0) <{position = array<i64: 0>}> : (!llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)>) -> !llvm.ptr<1>
    %33 = "llvm.getelementptr"(%32, %31) <{elem_type = f32, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>
    %34 = "llvm.extractvalue"(%arg1) <{position = array<i64: 1>}> : (!llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)>) -> !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>
    %35 = "llvm.extractvalue"(%34) <{position = array<i64: 0>}> : (!llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>) -> !llvm.struct<(i32, i32, i32)>
    %36 = "llvm.extractvalue"(%35) <{position = array<i64: 0>}> : (!llvm.struct<(i32, i32, i32)>) -> i32
    %37 = "llvm.extractvalue"(%35) <{position = array<i64: 1>}> : (!llvm.struct<(i32, i32, i32)>) -> i32
    %38 = "llvm.extractvalue"(%34) <{position = array<i64: 1>}> : (!llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>) -> !llvm.struct<(i64, i64)>
    %39 = "llvm.extractvalue"(%38) <{position = array<i64: 0>}> : (!llvm.struct<(i64, i64)>) -> i64
    %40 = "llvm.extractvalue"(%38) <{position = array<i64: 1>}> : (!llvm.struct<(i64, i64)>) -> i64
    %41 = "llvm.sdiv"(%12, %36) : (i32, i32) -> i32
    %42 = "llvm.srem"(%12, %36) : (i32, i32) -> i32
    %43 = "llvm.sext"(%42) : (i32) -> i64
    %44 = "llvm.mul"(%43, %39) <{overflowFlags = #llvm.overflow<none>}> : (i64, i64) -> i64
    %45 = "llvm.sdiv"(%41, %37) : (i32, i32) -> i32
    %46 = "llvm.srem"(%41, %37) : (i32, i32) -> i32
    %47 = "llvm.mul"(%46, %7) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %48 = "llvm.sext"(%47) : (i32) -> i64
    %49 = "llvm.add"(%44, %48) <{overflowFlags = #llvm.overflow<none>}> : (i64, i64) -> i64
    %50 = "llvm.sext"(%45) : (i32) -> i64
    %51 = "llvm.mul"(%50, %40) <{overflowFlags = #llvm.overflow<none>}> : (i64, i64) -> i64
    %52 = "llvm.add"(%49, %51) <{overflowFlags = #llvm.overflow<none>}> : (i64, i64) -> i64
    %53 = "llvm.extractvalue"(%arg1) <{position = array<i64: 0>}> : (!llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)>) -> !llvm.ptr<1>
    %54 = "llvm.getelementptr"(%53, %52) <{elem_type = i8, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>
    %55 = "llvm.extractvalue"(%arg2) <{position = array<i64: 1>}> : (!llvm.struct<(struct<()>, struct<(struct<(i32, i32, i32)>, struct<()>)>)>) -> !llvm.struct<(struct<(i32, i32, i32)>, struct<()>)>
    %56 = "llvm.extractvalue"(%55) <{position = array<i64: 0>}> : (!llvm.struct<(struct<(i32, i32, i32)>, struct<()>)>) -> !llvm.struct<(i32, i32, i32)>
    %57 = "llvm.extractvalue"(%56) <{position = array<i64: 0>}> : (!llvm.struct<(i32, i32, i32)>) -> i32
    %58 = "llvm.extractvalue"(%56) <{position = array<i64: 1>}> : (!llvm.struct<(i32, i32, i32)>) -> i32
    %59 = "llvm.sdiv"(%12, %57) : (i32, i32) -> i32
    %60 = "llvm.srem"(%12, %57) : (i32, i32) -> i32
    %61 = "llvm.sdiv"(%59, %58) : (i32, i32) -> i32
    %62 = "llvm.srem"(%59, %58) : (i32, i32) -> i32
    %63 = "llvm.mul"(%62, %7) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %64 = "llvm.mul"(%11, %8) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %65 = "llvm.getelementptr"(%33, %64) <{elem_type = f32, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>
    %66 = "llvm.getelementptr"(%54, %64) <{elem_type = i8, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>
    %67 = "llvm.add"(%63, %64) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %68 = "llvm.icmp"(%60, %arg3) <{predicate = 2 : i64}> : (i32, i32) -> i1
    %69 = "llvm.icmp"(%67, %arg4) <{predicate = 2 : i64}> : (i32, i32) -> i1
    %70 = "llvm.and"(%68, %69) : (i1, i1) -> i1
    %71 = "llvm.icmp"(%61, %arg5) <{predicate = 2 : i64}> : (i32, i32) -> i1
    %72 = "llvm.and"(%70, %71) : (i1, i1) -> i1
    "llvm.cond_br"(%72)[^bb1, ^bb2] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb1:  // pred: ^bb0
    %73 = "llvm.load"(%65) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
    "llvm.store"(%73, %10) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
    %74 = "llvm.getelementptr"(%65) <{elem_type = f32, rawConstantIndices = array<i32: 1>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
    %75 = "llvm.getelementptr"(%10) <{elem_type = f32, rawConstantIndices = array<i32: 1>}> : (!llvm.ptr) -> !llvm.ptr
    %76 = "llvm.load"(%74) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
    "llvm.store"(%76, %75) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
    %77 = "llvm.getelementptr"(%65) <{elem_type = f32, rawConstantIndices = array<i32: 2>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
    %78 = "llvm.getelementptr"(%10) <{elem_type = f32, rawConstantIndices = array<i32: 2>}> : (!llvm.ptr) -> !llvm.ptr
    %79 = "llvm.load"(%77) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
    "llvm.store"(%79, %78) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
    %80 = "llvm.getelementptr"(%65) <{elem_type = f32, rawConstantIndices = array<i32: 3>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
    %81 = "llvm.getelementptr"(%10) <{elem_type = f32, rawConstantIndices = array<i32: 3>}> : (!llvm.ptr) -> !llvm.ptr
    %82 = "llvm.load"(%80) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
    "llvm.store"(%82, %81) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
    %83 = "llvm.load"(%10) <{alignment = 32 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<4xf32>
    %84 = "llvm.bitcast"(%83) : (vector<4xf32>) -> vector<4xi32>
    %85 = "llvm.extractelement"(%84, %2) : (vector<4xi32>, i64) -> i32
    %86 = "llvm.extractelement"(%84, %1) : (vector<4xi32>, i64) -> i32
    %87 = "llvm.bitcast"(%85) : (i32) -> f32
    %88 = "llvm.bitcast"(%86) : (i32) -> f32
    %89 = "nvvm.cvt.packfloat.f32"(%88, %87, %4) <{extractHi = false, relu = false, rnd = #nvvm.rnd<rn>, sat = #nvvm.sat<satfinite>, to = #nvvm.packfloat_type<e4m3x2>}> : (f32, f32, i32) -> i32
    %90 = "llvm.or"(%4, %89) : (i32, i32) -> i32
    %91 = "llvm.extractelement"(%84, %3) : (vector<4xi32>, i64) -> i32
    %92 = "llvm.extractelement"(%84, %0) : (vector<4xi32>, i64) -> i32
    %93 = "llvm.bitcast"(%91) : (i32) -> f32
    %94 = "llvm.bitcast"(%92) : (i32) -> f32
    %95 = "nvvm.cvt.packfloat.f32"(%94, %93, %4) <{extractHi = false, relu = false, rnd = #nvvm.rnd<rn>, sat = #nvvm.sat<satfinite>, to = #nvvm.packfloat_type<e4m3x2>}> : (f32, f32, i32) -> i32
    %96 = "llvm.shl"(%90, %5) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %97 = "llvm.or"(%96, %95) : (i32, i32) -> i32
    %98 = "llvm.insertelement"(%6, %97, %3) : (vector<1xi32>, i32, i64) -> vector<1xi32>
    %99 = "llvm.bitcast"(%98) : (vector<1xi32>) -> vector<4xi8>
    "llvm.store"(%99, %9) <{alignment = 32 : i64, ordering = 0 : i64}> : (vector<4xi8>, !llvm.ptr) -> ()
    %100 = "llvm.load"(%9) <{alignment = 1 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xi8>
    "llvm.store"(%100, %66) <{alignment = 1 : i64, ordering = 0 : i64}> : (vector<1xi8>, !llvm.ptr<1>) -> ()
    %101 = "llvm.getelementptr"(%9) <{elem_type = i8, rawConstantIndices = array<i32: 1>}> : (!llvm.ptr) -> !llvm.ptr
    %102 = "llvm.getelementptr"(%66) <{elem_type = i8, rawConstantIndices = array<i32: 1>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
    %103 = "llvm.load"(%101) <{alignment = 1 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xi8>
    "llvm.store"(%103, %102) <{alignment = 1 : i64, ordering = 0 : i64}> : (vector<1xi8>, !llvm.ptr<1>) -> ()
    %104 = "llvm.getelementptr"(%9) <{elem_type = i8, rawConstantIndices = array<i32: 2>}> : (!llvm.ptr) -> !llvm.ptr
    %105 = "llvm.getelementptr"(%66) <{elem_type = i8, rawConstantIndices = array<i32: 2>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
    %106 = "llvm.load"(%104) <{alignment = 1 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xi8>
    "llvm.store"(%106, %105) <{alignment = 1 : i64, ordering = 0 : i64}> : (vector<1xi8>, !llvm.ptr<1>) -> ()
    %107 = "llvm.getelementptr"(%9) <{elem_type = i8, rawConstantIndices = array<i32: 3>}> : (!llvm.ptr) -> !llvm.ptr
    %108 = "llvm.getelementptr"(%66) <{elem_type = i8, rawConstantIndices = array<i32: 3>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
    %109 = "llvm.load"(%107) <{alignment = 1 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xi8>
    "llvm.store"(%109, %108) <{alignment = 1 : i64, ordering = 0 : i64}> : (vector<1xi8>, !llvm.ptr<1>) -> ()
    "llvm.br"()[^bb2] : () -> ()
  ^bb2:  // 2 preds: ^bb0, ^bb1
    "llvm.return"() : () -> ()
  }) {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, gpu.kernel, nvvm.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} : () -> ()
}) {compute_targets = [#cuda.compute_target<sass, conditional, [sm_100]>]} : () -> ()
