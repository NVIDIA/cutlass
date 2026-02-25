"gpu.module"() <{sym_name = "kernels"}> ({
  "llvm.func"() <{CConv = #llvm.cconv<ccc>, function_type = !llvm.func<void (struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)>, struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)>, struct<(struct<()>, struct<(struct<(i32, i32, i32)>, struct<()>)>)>, i32, i32, i32)>, linkage = #llvm.linkage<external>, sym_name = "kernel_cutlass__convert_kernel_tensorptrf32gmemo1024111001024i64i64_tensorptri8gmemalign128o51211100512i64i64_tensor000o1024111000102401112____Float32_Int4_0", visibility_ = 0 : i64}> ({
  ^bb0(%arg0: !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)>, %arg1: !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)>, %arg2: !llvm.struct<(struct<()>, struct<(struct<(i32, i32, i32)>, struct<()>)>)>, %arg3: i32, %arg4: i32, %arg5: i32):
    %0 = "llvm.mlir.constant"() <{value = 512 : i32}> : () -> i32
    %1 = "llvm.mlir.constant"() <{value = 1024 : i32}> : () -> i32
    %2 = "llvm.mlir.constant"() <{value = 8 : i32}> : () -> i32
    %3 = "llvm.mlir.constant"() <{value = 4 : i32}> : () -> i32
    %4 = "llvm.alloca"(%3) <{alignment = 32 : i64, elem_type = i8}> : (i32) -> !llvm.ptr
    %5 = "llvm.alloca"(%2) <{alignment = 32 : i64, elem_type = i32}> : (i32) -> !llvm.ptr
    %6 = "nvvm.read.ptx.sreg.tid.x"() <{range = #llvm.constant_range<i32, 0, 1024>}> : () -> i32
    %7 = "nvvm.read.ptx.sreg.ctaid.x"() <{range = #llvm.constant_range<i32, 0, 2147483647>}> : () -> i32
    %8 = "llvm.extractvalue"(%arg0) <{position = array<i64: 1>}> : (!llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)>) -> !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>
    %9 = "llvm.extractvalue"(%8) <{position = array<i64: 0>}> : (!llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>) -> !llvm.struct<(i32, i32, i32)>
    %10 = "llvm.extractvalue"(%9) <{position = array<i64: 0>}> : (!llvm.struct<(i32, i32, i32)>) -> i32
    %11 = "llvm.extractvalue"(%9) <{position = array<i64: 1>}> : (!llvm.struct<(i32, i32, i32)>) -> i32
    %12 = "llvm.extractvalue"(%8) <{position = array<i64: 1>}> : (!llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>) -> !llvm.struct<(i64, i64)>
    %13 = "llvm.extractvalue"(%12) <{position = array<i64: 0>}> : (!llvm.struct<(i64, i64)>) -> i64
    %14 = "llvm.extractvalue"(%12) <{position = array<i64: 1>}> : (!llvm.struct<(i64, i64)>) -> i64
    %15 = "llvm.sdiv"(%7, %10) : (i32, i32) -> i32
    %16 = "llvm.srem"(%7, %10) : (i32, i32) -> i32
    %17 = "llvm.mul"(%16, %1) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %18 = "llvm.sdiv"(%15, %11) : (i32, i32) -> i32
    %19 = "llvm.srem"(%15, %11) : (i32, i32) -> i32
    %20 = "llvm.sext"(%19) : (i32) -> i64
    %21 = "llvm.mul"(%20, %13) <{overflowFlags = #llvm.overflow<none>}> : (i64, i64) -> i64
    %22 = "llvm.sext"(%17) : (i32) -> i64
    %23 = "llvm.add"(%22, %21) <{overflowFlags = #llvm.overflow<none>}> : (i64, i64) -> i64
    %24 = "llvm.sext"(%18) : (i32) -> i64
    %25 = "llvm.mul"(%24, %14) <{overflowFlags = #llvm.overflow<none>}> : (i64, i64) -> i64
    %26 = "llvm.add"(%23, %25) <{overflowFlags = #llvm.overflow<none>}> : (i64, i64) -> i64
    %27 = "llvm.extractvalue"(%arg0) <{position = array<i64: 0>}> : (!llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)>) -> !llvm.ptr<1>
    %28 = "llvm.getelementptr"(%27, %26) <{elem_type = f32, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>
    %29 = "llvm.extractvalue"(%arg1) <{position = array<i64: 1>}> : (!llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)>) -> !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>
    %30 = "llvm.extractvalue"(%29) <{position = array<i64: 0>}> : (!llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>) -> !llvm.struct<(i32, i32, i32)>
    %31 = "llvm.extractvalue"(%30) <{position = array<i64: 0>}> : (!llvm.struct<(i32, i32, i32)>) -> i32
    %32 = "llvm.extractvalue"(%30) <{position = array<i64: 1>}> : (!llvm.struct<(i32, i32, i32)>) -> i32
    %33 = "llvm.extractvalue"(%29) <{position = array<i64: 1>}> : (!llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>) -> !llvm.struct<(i64, i64)>
    %34 = "llvm.extractvalue"(%33) <{position = array<i64: 0>}> : (!llvm.struct<(i64, i64)>) -> i64
    %35 = "llvm.extractvalue"(%33) <{position = array<i64: 1>}> : (!llvm.struct<(i64, i64)>) -> i64
    %36 = "llvm.sdiv"(%7, %31) : (i32, i32) -> i32
    %37 = "llvm.srem"(%7, %31) : (i32, i32) -> i32
    %38 = "llvm.mul"(%37, %0) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %39 = "llvm.sdiv"(%36, %32) : (i32, i32) -> i32
    %40 = "llvm.srem"(%36, %32) : (i32, i32) -> i32
    %41 = "llvm.sext"(%40) : (i32) -> i64
    %42 = "llvm.mul"(%41, %34) <{overflowFlags = #llvm.overflow<none>}> : (i64, i64) -> i64
    %43 = "llvm.sext"(%38) : (i32) -> i64
    %44 = "llvm.add"(%43, %42) <{overflowFlags = #llvm.overflow<none>}> : (i64, i64) -> i64
    %45 = "llvm.sext"(%39) : (i32) -> i64
    %46 = "llvm.mul"(%45, %35) <{overflowFlags = #llvm.overflow<none>}> : (i64, i64) -> i64
    %47 = "llvm.add"(%44, %46) <{overflowFlags = #llvm.overflow<none>}> : (i64, i64) -> i64
    %48 = "llvm.extractvalue"(%arg1) <{position = array<i64: 0>}> : (!llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)>) -> !llvm.ptr<1>
    %49 = "llvm.getelementptr"(%48, %47) <{elem_type = i8, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>
    %50 = "llvm.extractvalue"(%arg2) <{position = array<i64: 1>}> : (!llvm.struct<(struct<()>, struct<(struct<(i32, i32, i32)>, struct<()>)>)>) -> !llvm.struct<(struct<(i32, i32, i32)>, struct<()>)>
    %51 = "llvm.extractvalue"(%50) <{position = array<i64: 0>}> : (!llvm.struct<(struct<(i32, i32, i32)>, struct<()>)>) -> !llvm.struct<(i32, i32, i32)>
    %52 = "llvm.extractvalue"(%51) <{position = array<i64: 0>}> : (!llvm.struct<(i32, i32, i32)>) -> i32
    %53 = "llvm.extractvalue"(%51) <{position = array<i64: 1>}> : (!llvm.struct<(i32, i32, i32)>) -> i32
    %54 = "llvm.sdiv"(%7, %52) : (i32, i32) -> i32
    %55 = "llvm.srem"(%7, %52) : (i32, i32) -> i32
    %56 = "llvm.mul"(%55, %1) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %57 = "llvm.sdiv"(%54, %53) : (i32, i32) -> i32
    %58 = "llvm.srem"(%54, %53) : (i32, i32) -> i32
    %59 = "llvm.mul"(%6, %2) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %60 = "llvm.getelementptr"(%28, %59) <{elem_type = f32, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>
    %61 = "llvm.mul"(%6, %3) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %62 = "llvm.getelementptr"(%49, %61) <{elem_type = i8, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>
    %63 = "llvm.add"(%56, %59) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %64 = "llvm.icmp"(%63, %arg3) <{predicate = 2 : i64}> : (i32, i32) -> i1
    %65 = "llvm.icmp"(%58, %arg4) <{predicate = 2 : i64}> : (i32, i32) -> i1
    %66 = "llvm.and"(%64, %65) : (i1, i1) -> i1
    %67 = "llvm.icmp"(%57, %arg5) <{predicate = 2 : i64}> : (i32, i32) -> i1
    %68 = "llvm.and"(%66, %67) : (i1, i1) -> i1
    "llvm.cond_br"(%68)[^bb1, ^bb2] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb1:  // pred: ^bb0
    %69 = "llvm.load"(%60) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
    "llvm.store"(%69, %5) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
    %70 = "llvm.getelementptr"(%60) <{elem_type = f32, rawConstantIndices = array<i32: 1>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
    %71 = "llvm.getelementptr"(%5) <{elem_type = f32, rawConstantIndices = array<i32: 1>}> : (!llvm.ptr) -> !llvm.ptr
    %72 = "llvm.load"(%70) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
    "llvm.store"(%72, %71) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
    %73 = "llvm.getelementptr"(%60) <{elem_type = f32, rawConstantIndices = array<i32: 2>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
    %74 = "llvm.getelementptr"(%5) <{elem_type = f32, rawConstantIndices = array<i32: 2>}> : (!llvm.ptr) -> !llvm.ptr
    %75 = "llvm.load"(%73) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
    "llvm.store"(%75, %74) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
    %76 = "llvm.getelementptr"(%60) <{elem_type = f32, rawConstantIndices = array<i32: 3>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
    %77 = "llvm.getelementptr"(%5) <{elem_type = f32, rawConstantIndices = array<i32: 3>}> : (!llvm.ptr) -> !llvm.ptr
    %78 = "llvm.load"(%76) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
    "llvm.store"(%78, %77) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
    %79 = "llvm.getelementptr"(%60) <{elem_type = f32, rawConstantIndices = array<i32: 4>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
    %80 = "llvm.getelementptr"(%5) <{elem_type = f32, rawConstantIndices = array<i32: 4>}> : (!llvm.ptr) -> !llvm.ptr
    %81 = "llvm.load"(%79) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
    "llvm.store"(%81, %80) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
    %82 = "llvm.getelementptr"(%60) <{elem_type = f32, rawConstantIndices = array<i32: 5>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
    %83 = "llvm.getelementptr"(%5) <{elem_type = f32, rawConstantIndices = array<i32: 5>}> : (!llvm.ptr) -> !llvm.ptr
    %84 = "llvm.load"(%82) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
    "llvm.store"(%84, %83) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
    %85 = "llvm.getelementptr"(%60) <{elem_type = f32, rawConstantIndices = array<i32: 6>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
    %86 = "llvm.getelementptr"(%5) <{elem_type = f32, rawConstantIndices = array<i32: 6>}> : (!llvm.ptr) -> !llvm.ptr
    %87 = "llvm.load"(%85) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
    "llvm.store"(%87, %86) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
    %88 = "llvm.getelementptr"(%60) <{elem_type = f32, rawConstantIndices = array<i32: 7>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
    %89 = "llvm.getelementptr"(%5) <{elem_type = f32, rawConstantIndices = array<i32: 7>}> : (!llvm.ptr) -> !llvm.ptr
    %90 = "llvm.load"(%88) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
    "llvm.store"(%90, %89) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
    %91 = "llvm.load"(%5) <{alignment = 32 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xf32>
    %92 = "llvm.fptosi"(%91) : (vector<8xf32>) -> vector<8xi4>
    %93 = "llvm.bitcast"(%92) : (vector<8xi4>) -> vector<4xi8>
    "llvm.store"(%93, %4) <{alignment = 32 : i64, ordering = 0 : i64}> : (vector<4xi8>, !llvm.ptr) -> ()
    %94 = "llvm.load"(%4) <{alignment = 1 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xi8>
    "llvm.store"(%94, %62) <{alignment = 1 : i64, ordering = 0 : i64}> : (vector<1xi8>, !llvm.ptr<1>) -> ()
    %95 = "llvm.getelementptr"(%4) <{elem_type = i8, rawConstantIndices = array<i32: 1>}> : (!llvm.ptr) -> !llvm.ptr
    %96 = "llvm.getelementptr"(%62) <{elem_type = i8, rawConstantIndices = array<i32: 1>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
    %97 = "llvm.load"(%95) <{alignment = 1 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xi8>
    "llvm.store"(%97, %96) <{alignment = 1 : i64, ordering = 0 : i64}> : (vector<1xi8>, !llvm.ptr<1>) -> ()
    %98 = "llvm.getelementptr"(%4) <{elem_type = i8, rawConstantIndices = array<i32: 2>}> : (!llvm.ptr) -> !llvm.ptr
    %99 = "llvm.getelementptr"(%62) <{elem_type = i8, rawConstantIndices = array<i32: 2>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
    %100 = "llvm.load"(%98) <{alignment = 1 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xi8>
    "llvm.store"(%100, %99) <{alignment = 1 : i64, ordering = 0 : i64}> : (vector<1xi8>, !llvm.ptr<1>) -> ()
    %101 = "llvm.getelementptr"(%4) <{elem_type = i8, rawConstantIndices = array<i32: 3>}> : (!llvm.ptr) -> !llvm.ptr
    %102 = "llvm.getelementptr"(%62) <{elem_type = i8, rawConstantIndices = array<i32: 3>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
    %103 = "llvm.load"(%101) <{alignment = 1 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xi8>
    "llvm.store"(%103, %102) <{alignment = 1 : i64, ordering = 0 : i64}> : (vector<1xi8>, !llvm.ptr<1>) -> ()
    "llvm.br"()[^bb2] : () -> ()
  ^bb2:  // 2 preds: ^bb0, ^bb1
    "llvm.return"() : () -> ()
  }) {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, gpu.kernel, nvvm.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} : () -> ()
}) {compute_targets = [#cuda.compute_target<sass, conditional, [sm_100]>]} : () -> ()
