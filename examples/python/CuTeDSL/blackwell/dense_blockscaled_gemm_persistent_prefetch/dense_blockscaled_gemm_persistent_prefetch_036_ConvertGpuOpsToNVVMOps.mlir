"gpu.module"() <{sym_name = "kernels"}> ({
  "llvm.func"() <{CConv = #llvm.cconv<ccc>, function_type = !llvm.func<void (struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)>, struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)>, struct<(struct<()>, struct<(struct<(i32, i32, i32)>, struct<()>)>)>, i32, i32, i32)>, linkage = #llvm.linkage<external>, sym_name = "kernel_cutlass__convert_kernel_tensorptrf32gmemo110241010i641024i64_tensorptri8gmemalign16o15121010i64512i64_tensor000o1102410110101024112____Float32_Float4E2M1FN_0", visibility_ = 0 : i64}> ({
  ^bb0(%arg0: !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)>, %arg1: !llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)>, %arg2: !llvm.struct<(struct<()>, struct<(struct<(i32, i32, i32)>, struct<()>)>)>, %arg3: i32, %arg4: i32, %arg5: i32):
    %0 = "llvm.mlir.constant"() <{value = 1 : i64}> : () -> i64
    %1 = "llvm.mlir.constant"() <{value = 3 : i64}> : () -> i64
    %2 = "llvm.mlir.constant"() <{value = 2 : i64}> : () -> i64
    %3 = "llvm.mlir.constant"() <{value = 5 : i64}> : () -> i64
    %4 = "llvm.mlir.constant"() <{value = 4 : i64}> : () -> i64
    %5 = "llvm.mlir.constant"() <{value = 7 : i64}> : () -> i64
    %6 = "llvm.mlir.constant"() <{value = 6 : i64}> : () -> i64
    %7 = "llvm.mlir.constant"() <{value = 0 : i64}> : () -> i64
    %8 = "llvm.mlir.constant"() <{value = 0 : i32}> : () -> i32
    %9 = "llvm.mlir.undef"() : () -> vector<1xi32>
    %10 = "llvm.mlir.constant"() <{value = 512 : i32}> : () -> i32
    %11 = "llvm.mlir.constant"() <{value = 1024 : i32}> : () -> i32
    %12 = "llvm.mlir.constant"() <{value = 8 : i32}> : () -> i32
    %13 = "llvm.mlir.constant"() <{value = 4 : i32}> : () -> i32
    %14 = "llvm.alloca"(%13) <{alignment = 32 : i64, elem_type = i8}> : (i32) -> !llvm.ptr
    %15 = "llvm.alloca"(%12) <{alignment = 32 : i64, elem_type = i32}> : (i32) -> !llvm.ptr
    %16 = "nvvm.read.ptx.sreg.tid.x"() <{range = #llvm.constant_range<i32, 0, 1024>}> : () -> i32
    %17 = "nvvm.read.ptx.sreg.ctaid.x"() <{range = #llvm.constant_range<i32, 0, 2147483647>}> : () -> i32
    %18 = "llvm.extractvalue"(%arg0) <{position = array<i64: 1>}> : (!llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)>) -> !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>
    %19 = "llvm.extractvalue"(%18) <{position = array<i64: 0>}> : (!llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>) -> !llvm.struct<(i32, i32, i32)>
    %20 = "llvm.extractvalue"(%19) <{position = array<i64: 0>}> : (!llvm.struct<(i32, i32, i32)>) -> i32
    %21 = "llvm.extractvalue"(%19) <{position = array<i64: 1>}> : (!llvm.struct<(i32, i32, i32)>) -> i32
    %22 = "llvm.extractvalue"(%18) <{position = array<i64: 1>}> : (!llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>) -> !llvm.struct<(i64, i64)>
    %23 = "llvm.extractvalue"(%22) <{position = array<i64: 0>}> : (!llvm.struct<(i64, i64)>) -> i64
    %24 = "llvm.extractvalue"(%22) <{position = array<i64: 1>}> : (!llvm.struct<(i64, i64)>) -> i64
    %25 = "llvm.sdiv"(%17, %20) : (i32, i32) -> i32
    %26 = "llvm.srem"(%17, %20) : (i32, i32) -> i32
    %27 = "llvm.sext"(%26) : (i32) -> i64
    %28 = "llvm.mul"(%27, %23) <{overflowFlags = #llvm.overflow<none>}> : (i64, i64) -> i64
    %29 = "llvm.sdiv"(%25, %21) : (i32, i32) -> i32
    %30 = "llvm.srem"(%25, %21) : (i32, i32) -> i32
    %31 = "llvm.mul"(%30, %11) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %32 = "llvm.sext"(%31) : (i32) -> i64
    %33 = "llvm.add"(%28, %32) <{overflowFlags = #llvm.overflow<none>}> : (i64, i64) -> i64
    %34 = "llvm.sext"(%29) : (i32) -> i64
    %35 = "llvm.mul"(%34, %24) <{overflowFlags = #llvm.overflow<none>}> : (i64, i64) -> i64
    %36 = "llvm.add"(%33, %35) <{overflowFlags = #llvm.overflow<none>}> : (i64, i64) -> i64
    %37 = "llvm.extractvalue"(%arg0) <{position = array<i64: 0>}> : (!llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)>) -> !llvm.ptr<1>
    %38 = "llvm.getelementptr"(%37, %36) <{elem_type = f32, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>
    %39 = "llvm.extractvalue"(%arg1) <{position = array<i64: 1>}> : (!llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)>) -> !llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>
    %40 = "llvm.extractvalue"(%39) <{position = array<i64: 0>}> : (!llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>) -> !llvm.struct<(i32, i32, i32)>
    %41 = "llvm.extractvalue"(%40) <{position = array<i64: 0>}> : (!llvm.struct<(i32, i32, i32)>) -> i32
    %42 = "llvm.extractvalue"(%40) <{position = array<i64: 1>}> : (!llvm.struct<(i32, i32, i32)>) -> i32
    %43 = "llvm.extractvalue"(%39) <{position = array<i64: 1>}> : (!llvm.struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>) -> !llvm.struct<(i64, i64)>
    %44 = "llvm.extractvalue"(%43) <{position = array<i64: 0>}> : (!llvm.struct<(i64, i64)>) -> i64
    %45 = "llvm.extractvalue"(%43) <{position = array<i64: 1>}> : (!llvm.struct<(i64, i64)>) -> i64
    %46 = "llvm.sdiv"(%17, %41) : (i32, i32) -> i32
    %47 = "llvm.srem"(%17, %41) : (i32, i32) -> i32
    %48 = "llvm.sext"(%47) : (i32) -> i64
    %49 = "llvm.mul"(%48, %44) <{overflowFlags = #llvm.overflow<none>}> : (i64, i64) -> i64
    %50 = "llvm.sdiv"(%46, %42) : (i32, i32) -> i32
    %51 = "llvm.srem"(%46, %42) : (i32, i32) -> i32
    %52 = "llvm.mul"(%51, %10) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %53 = "llvm.sext"(%52) : (i32) -> i64
    %54 = "llvm.add"(%49, %53) <{overflowFlags = #llvm.overflow<none>}> : (i64, i64) -> i64
    %55 = "llvm.sext"(%50) : (i32) -> i64
    %56 = "llvm.mul"(%55, %45) <{overflowFlags = #llvm.overflow<none>}> : (i64, i64) -> i64
    %57 = "llvm.add"(%54, %56) <{overflowFlags = #llvm.overflow<none>}> : (i64, i64) -> i64
    %58 = "llvm.extractvalue"(%arg1) <{position = array<i64: 0>}> : (!llvm.struct<(ptr<1>, struct<(struct<(i32, i32, i32)>, struct<(i64, i64)>)>)>) -> !llvm.ptr<1>
    %59 = "llvm.getelementptr"(%58, %57) <{elem_type = i8, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>
    %60 = "llvm.extractvalue"(%arg2) <{position = array<i64: 1>}> : (!llvm.struct<(struct<()>, struct<(struct<(i32, i32, i32)>, struct<()>)>)>) -> !llvm.struct<(struct<(i32, i32, i32)>, struct<()>)>
    %61 = "llvm.extractvalue"(%60) <{position = array<i64: 0>}> : (!llvm.struct<(struct<(i32, i32, i32)>, struct<()>)>) -> !llvm.struct<(i32, i32, i32)>
    %62 = "llvm.extractvalue"(%61) <{position = array<i64: 0>}> : (!llvm.struct<(i32, i32, i32)>) -> i32
    %63 = "llvm.extractvalue"(%61) <{position = array<i64: 1>}> : (!llvm.struct<(i32, i32, i32)>) -> i32
    %64 = "llvm.sdiv"(%17, %62) : (i32, i32) -> i32
    %65 = "llvm.srem"(%17, %62) : (i32, i32) -> i32
    %66 = "llvm.sdiv"(%64, %63) : (i32, i32) -> i32
    %67 = "llvm.srem"(%64, %63) : (i32, i32) -> i32
    %68 = "llvm.mul"(%67, %11) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %69 = "llvm.mul"(%16, %12) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %70 = "llvm.getelementptr"(%38, %69) <{elem_type = f32, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>
    %71 = "llvm.mul"(%16, %13) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %72 = "llvm.getelementptr"(%59, %71) <{elem_type = i8, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>
    %73 = "llvm.add"(%68, %69) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %74 = "llvm.icmp"(%65, %arg3) <{predicate = 2 : i64}> : (i32, i32) -> i1
    %75 = "llvm.icmp"(%73, %arg4) <{predicate = 2 : i64}> : (i32, i32) -> i1
    %76 = "llvm.and"(%74, %75) : (i1, i1) -> i1
    %77 = "llvm.icmp"(%66, %arg5) <{predicate = 2 : i64}> : (i32, i32) -> i1
    %78 = "llvm.and"(%76, %77) : (i1, i1) -> i1
    "llvm.cond_br"(%78)[^bb1, ^bb2] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb1:  // pred: ^bb0
    %79 = "llvm.load"(%70) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
    "llvm.store"(%79, %15) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
    %80 = "llvm.getelementptr"(%70) <{elem_type = f32, rawConstantIndices = array<i32: 1>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
    %81 = "llvm.getelementptr"(%15) <{elem_type = f32, rawConstantIndices = array<i32: 1>}> : (!llvm.ptr) -> !llvm.ptr
    %82 = "llvm.load"(%80) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
    "llvm.store"(%82, %81) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
    %83 = "llvm.getelementptr"(%70) <{elem_type = f32, rawConstantIndices = array<i32: 2>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
    %84 = "llvm.getelementptr"(%15) <{elem_type = f32, rawConstantIndices = array<i32: 2>}> : (!llvm.ptr) -> !llvm.ptr
    %85 = "llvm.load"(%83) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
    "llvm.store"(%85, %84) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
    %86 = "llvm.getelementptr"(%70) <{elem_type = f32, rawConstantIndices = array<i32: 3>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
    %87 = "llvm.getelementptr"(%15) <{elem_type = f32, rawConstantIndices = array<i32: 3>}> : (!llvm.ptr) -> !llvm.ptr
    %88 = "llvm.load"(%86) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
    "llvm.store"(%88, %87) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
    %89 = "llvm.getelementptr"(%70) <{elem_type = f32, rawConstantIndices = array<i32: 4>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
    %90 = "llvm.getelementptr"(%15) <{elem_type = f32, rawConstantIndices = array<i32: 4>}> : (!llvm.ptr) -> !llvm.ptr
    %91 = "llvm.load"(%89) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
    "llvm.store"(%91, %90) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
    %92 = "llvm.getelementptr"(%70) <{elem_type = f32, rawConstantIndices = array<i32: 5>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
    %93 = "llvm.getelementptr"(%15) <{elem_type = f32, rawConstantIndices = array<i32: 5>}> : (!llvm.ptr) -> !llvm.ptr
    %94 = "llvm.load"(%92) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
    "llvm.store"(%94, %93) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
    %95 = "llvm.getelementptr"(%70) <{elem_type = f32, rawConstantIndices = array<i32: 6>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
    %96 = "llvm.getelementptr"(%15) <{elem_type = f32, rawConstantIndices = array<i32: 6>}> : (!llvm.ptr) -> !llvm.ptr
    %97 = "llvm.load"(%95) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
    "llvm.store"(%97, %96) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
    %98 = "llvm.getelementptr"(%70) <{elem_type = f32, rawConstantIndices = array<i32: 7>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
    %99 = "llvm.getelementptr"(%15) <{elem_type = f32, rawConstantIndices = array<i32: 7>}> : (!llvm.ptr) -> !llvm.ptr
    %100 = "llvm.load"(%98) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<1xf32>
    "llvm.store"(%100, %99) <{alignment = 4 : i64, ordering = 0 : i64}> : (vector<1xf32>, !llvm.ptr) -> ()
    %101 = "llvm.load"(%15) <{alignment = 32 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xf32>
    %102 = "llvm.bitcast"(%101) : (vector<8xf32>) -> vector<8xi32>
    %103 = "llvm.extractelement"(%102, %6) : (vector<8xi32>, i64) -> i32
    %104 = "llvm.extractelement"(%102, %5) : (vector<8xi32>, i64) -> i32
    %105 = "llvm.bitcast"(%103) : (i32) -> f32
    %106 = "llvm.bitcast"(%104) : (i32) -> f32
    %107 = "nvvm.cvt.packfloat.f32"(%106, %105, %8) <{extractHi = false, relu = false, rnd = #nvvm.rnd<rn>, sat = #nvvm.sat<satfinite>, to = #nvvm.packfloat_type<e2m1x2>}> : (f32, f32, i32) -> i32
    %108 = "llvm.or"(%8, %107) : (i32, i32) -> i32
    %109 = "llvm.extractelement"(%102, %4) : (vector<8xi32>, i64) -> i32
    %110 = "llvm.extractelement"(%102, %3) : (vector<8xi32>, i64) -> i32
    %111 = "llvm.bitcast"(%109) : (i32) -> f32
    %112 = "llvm.bitcast"(%110) : (i32) -> f32
    %113 = "nvvm.cvt.packfloat.f32"(%112, %111, %8) <{extractHi = false, relu = false, rnd = #nvvm.rnd<rn>, sat = #nvvm.sat<satfinite>, to = #nvvm.packfloat_type<e2m1x2>}> : (f32, f32, i32) -> i32
    %114 = "llvm.shl"(%108, %12) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %115 = "llvm.or"(%114, %113) : (i32, i32) -> i32
    %116 = "llvm.extractelement"(%102, %2) : (vector<8xi32>, i64) -> i32
    %117 = "llvm.extractelement"(%102, %1) : (vector<8xi32>, i64) -> i32
    %118 = "llvm.bitcast"(%116) : (i32) -> f32
    %119 = "llvm.bitcast"(%117) : (i32) -> f32
    %120 = "nvvm.cvt.packfloat.f32"(%119, %118, %8) <{extractHi = false, relu = false, rnd = #nvvm.rnd<rn>, sat = #nvvm.sat<satfinite>, to = #nvvm.packfloat_type<e2m1x2>}> : (f32, f32, i32) -> i32
    %121 = "llvm.shl"(%115, %12) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %122 = "llvm.or"(%121, %120) : (i32, i32) -> i32
    %123 = "llvm.extractelement"(%102, %7) : (vector<8xi32>, i64) -> i32
    %124 = "llvm.extractelement"(%102, %0) : (vector<8xi32>, i64) -> i32
    %125 = "llvm.bitcast"(%123) : (i32) -> f32
    %126 = "llvm.bitcast"(%124) : (i32) -> f32
    %127 = "nvvm.cvt.packfloat.f32"(%126, %125, %8) <{extractHi = false, relu = false, rnd = #nvvm.rnd<rn>, sat = #nvvm.sat<satfinite>, to = #nvvm.packfloat_type<e2m1x2>}> : (f32, f32, i32) -> i32
    %128 = "llvm.shl"(%122, %12) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %129 = "llvm.or"(%128, %127) : (i32, i32) -> i32
    %130 = "llvm.insertelement"(%9, %129, %7) : (vector<1xi32>, i32, i64) -> vector<1xi32>
    %131 = "llvm.bitcast"(%130) : (vector<1xi32>) -> vector<4xi8>
    "llvm.store"(%131, %14) <{alignment = 32 : i64, ordering = 0 : i64}> : (vector<4xi8>, !llvm.ptr) -> ()
    %132 = "llvm.load"(%14) <{alignment = 1 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xi8>
    "llvm.store"(%132, %72) <{alignment = 1 : i64, ordering = 0 : i64}> : (vector<1xi8>, !llvm.ptr<1>) -> ()
    %133 = "llvm.getelementptr"(%14) <{elem_type = i8, rawConstantIndices = array<i32: 1>}> : (!llvm.ptr) -> !llvm.ptr
    %134 = "llvm.getelementptr"(%72) <{elem_type = i8, rawConstantIndices = array<i32: 1>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
    %135 = "llvm.load"(%133) <{alignment = 1 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xi8>
    "llvm.store"(%135, %134) <{alignment = 1 : i64, ordering = 0 : i64}> : (vector<1xi8>, !llvm.ptr<1>) -> ()
    %136 = "llvm.getelementptr"(%14) <{elem_type = i8, rawConstantIndices = array<i32: 2>}> : (!llvm.ptr) -> !llvm.ptr
    %137 = "llvm.getelementptr"(%72) <{elem_type = i8, rawConstantIndices = array<i32: 2>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
    %138 = "llvm.load"(%136) <{alignment = 1 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xi8>
    "llvm.store"(%138, %137) <{alignment = 1 : i64, ordering = 0 : i64}> : (vector<1xi8>, !llvm.ptr<1>) -> ()
    %139 = "llvm.getelementptr"(%14) <{elem_type = i8, rawConstantIndices = array<i32: 3>}> : (!llvm.ptr) -> !llvm.ptr
    %140 = "llvm.getelementptr"(%72) <{elem_type = i8, rawConstantIndices = array<i32: 3>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
    %141 = "llvm.load"(%139) <{alignment = 1 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<1xi8>
    "llvm.store"(%141, %140) <{alignment = 1 : i64, ordering = 0 : i64}> : (vector<1xi8>, !llvm.ptr<1>) -> ()
    "llvm.br"()[^bb2] : () -> ()
  ^bb2:  // 2 preds: ^bb0, ^bb1
    "llvm.return"() : () -> ()
  }) {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, gpu.kernel, nvvm.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} : () -> ()
}) {compute_targets = [#cuda.compute_target<sass, conditional, [sm_100]>]} : () -> ()
