"gpu.module"() <{sym_name = "kernels"}> ({
  "llvm.mlir.global"() <{addr_space = 3 : i32, alignment = 1024 : i64, dso_local, global_type = !llvm.array<0 x i8>, linkage = #llvm.linkage<external>, sym_name = "__dynamic_shmem__0", visibility_ = 0 : i64}> ({
  }) : () -> ()
  "llvm.func"() <{CConv = #llvm.cconv<ccc>, function_type = !llvm.func<f32 (f32)>, linkage = #llvm.linkage<external>, sym_name = "__nv_rsqrtf", visibility_ = 0 : i64}> ({
  }) : () -> ()
  "llvm.func"() <{CConv = #llvm.cconv<ccc>, function_type = !llvm.func<void (struct<(ptr<1>, struct<(i32, struct<()>)>)>, struct<(ptr<1>, struct<(struct<()>, struct<()>)>)>, struct<(ptr<1>, struct<(i32, struct<()>)>)>, f32)>, linkage = #llvm.linkage<external>, sym_name = "kernel_cutlass_kernel___main__RMSNormKernel_object_at__tensorptrbf16gmemalign16o409640961_tensorptrbf16_gmem_align16_o_40961_tensorptrbf16gmemalign16o409640961__2_4096_0", visibility_ = 0 : i64}> ({
  ^bb0(%arg0: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, %arg1: !llvm.struct<(ptr<1>, struct<(struct<()>, struct<()>)>)>, %arg2: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, %arg3: f32):
    %0 = "llvm.mlir.undef"() : () -> vector<64xf32>
    %1 = "llvm.mlir.constant"() <{value = 3584 : i32}> : () -> i32
    %2 = "llvm.mlir.constant"() <{value = 3072 : i32}> : () -> i32
    %3 = "llvm.mlir.constant"() <{value = 2560 : i32}> : () -> i32
    %4 = "llvm.mlir.constant"() <{value = 2048 : i32}> : () -> i32
    %5 = "llvm.mlir.constant"() <{value = 1536 : i32}> : () -> i32
    %6 = "llvm.mlir.constant"() <{value = 1024 : i32}> : () -> i32
    %7 = "llvm.mlir.constant"() <{value = 512 : i32}> : () -> i32
    %8 = "llvm.mlir.constant"() <{value = 8192 : i32}> : () -> i32
    %9 = "llvm.mlir.constant"() <{value = false}> : () -> i1
    %10 = "llvm.mlir.addressof"() <{global_name = @__dynamic_shmem__0}> : () -> !llvm.ptr<3>
    %11 = "llvm.mlir.constant"() <{value = 2 : i32}> : () -> i32
    %12 = "llvm.mlir.constant"() <{value = 4096 : i32}> : () -> i32
    %13 = "llvm.mlir.constant"() <{value = 0 : i32}> : () -> i32
    %14 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
    %15 = "llvm.mlir.constant"() <{value = 0.000000e+00 : f32}> : () -> f32
    %16 = "llvm.mlir.constant"() <{value = -1 : i32}> : () -> i32
    %17 = "llvm.mlir.constant"() <{value = 16 : i32}> : () -> i32
    %18 = "llvm.mlir.constant"() <{value = 31 : i32}> : () -> i32
    %19 = "llvm.mlir.constant"() <{value = 4 : i32}> : () -> i32
    %20 = "llvm.mlir.constant"() <{value = 32 : i32}> : () -> i32
    %21 = "llvm.mlir.constant"() <{value = 4.096000e+03 : f32}> : () -> f32
    %22 = "llvm.mlir.constant"() <{value = 64 : i32}> : () -> i32
    %23 = "llvm.mlir.constant"() <{value = 8 : i32}> : () -> i32
    %24 = "llvm.mlir.constant"() <{value = 1 : i32}> : () -> i32
    %25 = "llvm.alloca"(%23) <{alignment = 32 : i64, elem_type = i8}> : (i32) -> !llvm.ptr
    %26 = "llvm.alloca"(%23) <{alignment = 32 : i64, elem_type = i8}> : (i32) -> !llvm.ptr
    %27 = "llvm.alloca"(%22) <{alignment = 32 : i64, elem_type = i16}> : (i32) -> !llvm.ptr
    %28 = "llvm.alloca"(%22) <{alignment = 32 : i64, elem_type = i16}> : (i32) -> !llvm.ptr
    %29 = "llvm.alloca"(%22) <{alignment = 32 : i64, elem_type = i16}> : (i32) -> !llvm.ptr
    %30 = "llvm.extractvalue"(%arg1) <{position = array<i64: 0>}> : (!llvm.struct<(ptr<1>, struct<(struct<()>, struct<()>)>)>) -> !llvm.ptr<1>
    %31 = "nvvm.read.ptx.sreg.tid.x"() <{range = #llvm.constant_range<i32, 0, 1024>}> : () -> i32
    %32 = "nvvm.read.ptx.sreg.ctaid.x"() <{range = #llvm.constant_range<i32, 0, 2147483647>}> : () -> i32
    %33 = "llvm.extractvalue"(%arg0) <{position = array<i64: 1>}> : (!llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>) -> !llvm.struct<(i32, struct<()>)>
    %34 = "llvm.extractvalue"(%33) <{position = array<i64: 0>}> : (!llvm.struct<(i32, struct<()>)>) -> i32
    %35 = "llvm.getelementptr"(%10) <{elem_type = i8, rawConstantIndices = array<i32: 16384>}> : (!llvm.ptr<3>) -> !llvm.ptr<3>
    %36 = "llvm.mul"(%32, %8) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %37 = "llvm.extractvalue"(%arg0) <{position = array<i64: 0>}> : (!llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>) -> !llvm.ptr<1>
    %38 = "llvm.getelementptr"(%37, %36) <{elem_type = bf16, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>
    %39 = "llvm.extractvalue"(%arg2) <{position = array<i64: 0>}> : (!llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>) -> !llvm.ptr<1>
    %40 = "llvm.getelementptr"(%39, %36) <{elem_type = bf16, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>
    %41 = "llvm.mul"(%32, %11) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %42 = "llvm.sdiv"(%31, %22) : (i32, i32) -> i32
    %43 = "llvm.srem"(%31, %22) : (i32, i32) -> i32
    %44 = "llvm.mul"(%43, %23) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %45 = "llvm.mul"(%42, %12) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %46 = "llvm.add"(%44, %45) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %47 = "llvm.getelementptr"(%38, %46) <{elem_type = bf16, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>
    %48 = "llvm.getelementptr"(%10, %46) <{elem_type = bf16, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>
    %49 = "llvm.getelementptr"(%40, %46) <{elem_type = bf16, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>
    %50 = "llvm.add"(%41, %42) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %51 = "llvm.getelementptr"(%30, %44) <{elem_type = bf16, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>
    %52 = "llvm.icmp"(%44, %12) <{predicate = 2 : i64}> : (i32, i32) -> i1
    %53 = "llvm.zext"(%52) : (i1) -> i8
    %54 = "llvm.ptrtoint"(%26) : (!llvm.ptr) -> i64
    %55 = "llvm.inttoptr"(%54) : (i64) -> !llvm.ptr
    "llvm.store"(%53, %55) <{alignment = 32 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
    %56 = "llvm.add"(%44, %7) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %57 = "llvm.icmp"(%56, %12) <{predicate = 2 : i64}> : (i32, i32) -> i1
    %58 = "llvm.zext"(%57) : (i1) -> i8
    %59 = "llvm.getelementptr"(%26) <{elem_type = i8, rawConstantIndices = array<i32: 1>}> : (!llvm.ptr) -> !llvm.ptr
    %60 = "llvm.ptrtoint"(%59) : (!llvm.ptr) -> i64
    %61 = "llvm.inttoptr"(%60) : (i64) -> !llvm.ptr
    "llvm.store"(%58, %61) <{alignment = 1 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
    %62 = "llvm.add"(%44, %6) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %63 = "llvm.icmp"(%62, %12) <{predicate = 2 : i64}> : (i32, i32) -> i1
    %64 = "llvm.zext"(%63) : (i1) -> i8
    %65 = "llvm.getelementptr"(%26) <{elem_type = i8, rawConstantIndices = array<i32: 2>}> : (!llvm.ptr) -> !llvm.ptr
    %66 = "llvm.ptrtoint"(%65) : (!llvm.ptr) -> i64
    %67 = "llvm.inttoptr"(%66) : (i64) -> !llvm.ptr
    "llvm.store"(%64, %67) <{alignment = 2 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
    %68 = "llvm.add"(%44, %5) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %69 = "llvm.icmp"(%68, %12) <{predicate = 2 : i64}> : (i32, i32) -> i1
    %70 = "llvm.zext"(%69) : (i1) -> i8
    %71 = "llvm.getelementptr"(%26) <{elem_type = i8, rawConstantIndices = array<i32: 3>}> : (!llvm.ptr) -> !llvm.ptr
    %72 = "llvm.ptrtoint"(%71) : (!llvm.ptr) -> i64
    %73 = "llvm.inttoptr"(%72) : (i64) -> !llvm.ptr
    "llvm.store"(%70, %73) <{alignment = 1 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
    %74 = "llvm.add"(%44, %4) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %75 = "llvm.icmp"(%74, %12) <{predicate = 2 : i64}> : (i32, i32) -> i1
    %76 = "llvm.zext"(%75) : (i1) -> i8
    %77 = "llvm.getelementptr"(%26) <{elem_type = i8, rawConstantIndices = array<i32: 4>}> : (!llvm.ptr) -> !llvm.ptr
    %78 = "llvm.ptrtoint"(%77) : (!llvm.ptr) -> i64
    %79 = "llvm.inttoptr"(%78) : (i64) -> !llvm.ptr
    "llvm.store"(%76, %79) <{alignment = 4 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
    %80 = "llvm.add"(%44, %3) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %81 = "llvm.icmp"(%80, %12) <{predicate = 2 : i64}> : (i32, i32) -> i1
    %82 = "llvm.zext"(%81) : (i1) -> i8
    %83 = "llvm.getelementptr"(%26) <{elem_type = i8, rawConstantIndices = array<i32: 5>}> : (!llvm.ptr) -> !llvm.ptr
    %84 = "llvm.ptrtoint"(%83) : (!llvm.ptr) -> i64
    %85 = "llvm.inttoptr"(%84) : (i64) -> !llvm.ptr
    "llvm.store"(%82, %85) <{alignment = 1 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
    %86 = "llvm.add"(%44, %2) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %87 = "llvm.icmp"(%86, %12) <{predicate = 2 : i64}> : (i32, i32) -> i1
    %88 = "llvm.zext"(%87) : (i1) -> i8
    %89 = "llvm.getelementptr"(%26) <{elem_type = i8, rawConstantIndices = array<i32: 6>}> : (!llvm.ptr) -> !llvm.ptr
    %90 = "llvm.ptrtoint"(%89) : (!llvm.ptr) -> i64
    %91 = "llvm.inttoptr"(%90) : (i64) -> !llvm.ptr
    "llvm.store"(%88, %91) <{alignment = 2 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
    %92 = "llvm.add"(%44, %1) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %93 = "llvm.icmp"(%92, %12) <{predicate = 2 : i64}> : (i32, i32) -> i1
    %94 = "llvm.zext"(%93) : (i1) -> i8
    %95 = "llvm.getelementptr"(%26) <{elem_type = i8, rawConstantIndices = array<i32: 7>}> : (!llvm.ptr) -> !llvm.ptr
    %96 = "llvm.ptrtoint"(%95) : (!llvm.ptr) -> i64
    %97 = "llvm.inttoptr"(%96) : (i64) -> !llvm.ptr
    "llvm.store"(%94, %97) <{alignment = 1 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
    %98 = "llvm.icmp"(%50, %34) <{predicate = 2 : i64}> : (i32, i32) -> i1
    "llvm.cond_br"(%98)[^bb1, ^bb2] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb1:  // pred: ^bb0
    %99 = "llvm.load"(%26) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
    %100 = "llvm.trunc"(%99) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
    %101 = "llvm.select"(%100, %17, %13) <{fastmathFlags = #llvm.fastmath<none>}> : (i1, i32, i32) -> i32
    "llvm.inline_asm"(%48, %47, %17, %101) <{asm_dialect = 0 : i64, asm_string = "cp.async.ca.shared.global [$0], [$1], $2, $3;\0A", constraints = "r,l,n,r", has_side_effects}> : (!llvm.ptr<3>, !llvm.ptr<1>, i32, i32) -> ()
    %102 = "llvm.getelementptr"(%47) <{elem_type = bf16, rawConstantIndices = array<i32: 512>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
    %103 = "llvm.getelementptr"(%48) <{elem_type = bf16, rawConstantIndices = array<i32: 512>}> : (!llvm.ptr<3>) -> !llvm.ptr<3>
    %104 = "llvm.load"(%59) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
    %105 = "llvm.trunc"(%104) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
    %106 = "llvm.select"(%105, %17, %13) <{fastmathFlags = #llvm.fastmath<none>}> : (i1, i32, i32) -> i32
    "llvm.inline_asm"(%103, %102, %17, %106) <{asm_dialect = 0 : i64, asm_string = "cp.async.ca.shared.global [$0], [$1], $2, $3;\0A", constraints = "r,l,n,r", has_side_effects}> : (!llvm.ptr<3>, !llvm.ptr<1>, i32, i32) -> ()
    %107 = "llvm.getelementptr"(%47) <{elem_type = bf16, rawConstantIndices = array<i32: 1024>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
    %108 = "llvm.getelementptr"(%48) <{elem_type = bf16, rawConstantIndices = array<i32: 1024>}> : (!llvm.ptr<3>) -> !llvm.ptr<3>
    %109 = "llvm.load"(%65) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
    %110 = "llvm.trunc"(%109) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
    %111 = "llvm.select"(%110, %17, %13) <{fastmathFlags = #llvm.fastmath<none>}> : (i1, i32, i32) -> i32
    "llvm.inline_asm"(%108, %107, %17, %111) <{asm_dialect = 0 : i64, asm_string = "cp.async.ca.shared.global [$0], [$1], $2, $3;\0A", constraints = "r,l,n,r", has_side_effects}> : (!llvm.ptr<3>, !llvm.ptr<1>, i32, i32) -> ()
    %112 = "llvm.getelementptr"(%47) <{elem_type = bf16, rawConstantIndices = array<i32: 1536>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
    %113 = "llvm.getelementptr"(%48) <{elem_type = bf16, rawConstantIndices = array<i32: 1536>}> : (!llvm.ptr<3>) -> !llvm.ptr<3>
    %114 = "llvm.load"(%71) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
    %115 = "llvm.trunc"(%114) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
    %116 = "llvm.select"(%115, %17, %13) <{fastmathFlags = #llvm.fastmath<none>}> : (i1, i32, i32) -> i32
    "llvm.inline_asm"(%113, %112, %17, %116) <{asm_dialect = 0 : i64, asm_string = "cp.async.ca.shared.global [$0], [$1], $2, $3;\0A", constraints = "r,l,n,r", has_side_effects}> : (!llvm.ptr<3>, !llvm.ptr<1>, i32, i32) -> ()
    %117 = "llvm.getelementptr"(%47) <{elem_type = bf16, rawConstantIndices = array<i32: 2048>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
    %118 = "llvm.getelementptr"(%48) <{elem_type = bf16, rawConstantIndices = array<i32: 2048>}> : (!llvm.ptr<3>) -> !llvm.ptr<3>
    %119 = "llvm.load"(%77) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
    %120 = "llvm.trunc"(%119) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
    %121 = "llvm.select"(%120, %17, %13) <{fastmathFlags = #llvm.fastmath<none>}> : (i1, i32, i32) -> i32
    "llvm.inline_asm"(%118, %117, %17, %121) <{asm_dialect = 0 : i64, asm_string = "cp.async.ca.shared.global [$0], [$1], $2, $3;\0A", constraints = "r,l,n,r", has_side_effects}> : (!llvm.ptr<3>, !llvm.ptr<1>, i32, i32) -> ()
    %122 = "llvm.getelementptr"(%47) <{elem_type = bf16, rawConstantIndices = array<i32: 2560>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
    %123 = "llvm.getelementptr"(%48) <{elem_type = bf16, rawConstantIndices = array<i32: 2560>}> : (!llvm.ptr<3>) -> !llvm.ptr<3>
    %124 = "llvm.load"(%83) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
    %125 = "llvm.trunc"(%124) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
    %126 = "llvm.select"(%125, %17, %13) <{fastmathFlags = #llvm.fastmath<none>}> : (i1, i32, i32) -> i32
    "llvm.inline_asm"(%123, %122, %17, %126) <{asm_dialect = 0 : i64, asm_string = "cp.async.ca.shared.global [$0], [$1], $2, $3;\0A", constraints = "r,l,n,r", has_side_effects}> : (!llvm.ptr<3>, !llvm.ptr<1>, i32, i32) -> ()
    %127 = "llvm.getelementptr"(%47) <{elem_type = bf16, rawConstantIndices = array<i32: 3072>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
    %128 = "llvm.getelementptr"(%48) <{elem_type = bf16, rawConstantIndices = array<i32: 3072>}> : (!llvm.ptr<3>) -> !llvm.ptr<3>
    %129 = "llvm.load"(%89) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
    %130 = "llvm.trunc"(%129) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
    %131 = "llvm.select"(%130, %17, %13) <{fastmathFlags = #llvm.fastmath<none>}> : (i1, i32, i32) -> i32
    "llvm.inline_asm"(%128, %127, %17, %131) <{asm_dialect = 0 : i64, asm_string = "cp.async.ca.shared.global [$0], [$1], $2, $3;\0A", constraints = "r,l,n,r", has_side_effects}> : (!llvm.ptr<3>, !llvm.ptr<1>, i32, i32) -> ()
    %132 = "llvm.getelementptr"(%47) <{elem_type = bf16, rawConstantIndices = array<i32: 3584>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
    %133 = "llvm.getelementptr"(%48) <{elem_type = bf16, rawConstantIndices = array<i32: 3584>}> : (!llvm.ptr<3>) -> !llvm.ptr<3>
    %134 = "llvm.load"(%95) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
    %135 = "llvm.trunc"(%134) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
    %136 = "llvm.select"(%135, %17, %13) <{fastmathFlags = #llvm.fastmath<none>}> : (i1, i32, i32) -> i32
    "llvm.inline_asm"(%133, %132, %17, %136) <{asm_dialect = 0 : i64, asm_string = "cp.async.ca.shared.global [$0], [$1], $2, $3;\0A", constraints = "r,l,n,r", has_side_effects}> : (!llvm.ptr<3>, !llvm.ptr<1>, i32, i32) -> ()
    "llvm.br"()[^bb2] : () -> ()
  ^bb2:  // 2 preds: ^bb0, ^bb1
    "nvvm.cp.async.commit.group"() : () -> ()
    %137 = "llvm.ptrtoint"(%25) : (!llvm.ptr) -> i64
    %138 = "llvm.inttoptr"(%137) : (i64) -> !llvm.ptr
    "llvm.store"(%53, %138) <{alignment = 32 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
    %139 = "llvm.getelementptr"(%25) <{elem_type = i8, rawConstantIndices = array<i32: 1>}> : (!llvm.ptr) -> !llvm.ptr
    %140 = "llvm.ptrtoint"(%139) : (!llvm.ptr) -> i64
    %141 = "llvm.inttoptr"(%140) : (i64) -> !llvm.ptr
    "llvm.store"(%58, %141) <{alignment = 1 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
    %142 = "llvm.getelementptr"(%25) <{elem_type = i8, rawConstantIndices = array<i32: 2>}> : (!llvm.ptr) -> !llvm.ptr
    %143 = "llvm.ptrtoint"(%142) : (!llvm.ptr) -> i64
    %144 = "llvm.inttoptr"(%143) : (i64) -> !llvm.ptr
    "llvm.store"(%64, %144) <{alignment = 2 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
    %145 = "llvm.getelementptr"(%25) <{elem_type = i8, rawConstantIndices = array<i32: 3>}> : (!llvm.ptr) -> !llvm.ptr
    %146 = "llvm.ptrtoint"(%145) : (!llvm.ptr) -> i64
    %147 = "llvm.inttoptr"(%146) : (i64) -> !llvm.ptr
    "llvm.store"(%70, %147) <{alignment = 1 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
    %148 = "llvm.getelementptr"(%25) <{elem_type = i8, rawConstantIndices = array<i32: 4>}> : (!llvm.ptr) -> !llvm.ptr
    %149 = "llvm.ptrtoint"(%148) : (!llvm.ptr) -> i64
    %150 = "llvm.inttoptr"(%149) : (i64) -> !llvm.ptr
    "llvm.store"(%76, %150) <{alignment = 4 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
    %151 = "llvm.getelementptr"(%25) <{elem_type = i8, rawConstantIndices = array<i32: 5>}> : (!llvm.ptr) -> !llvm.ptr
    %152 = "llvm.ptrtoint"(%151) : (!llvm.ptr) -> i64
    %153 = "llvm.inttoptr"(%152) : (i64) -> !llvm.ptr
    "llvm.store"(%82, %153) <{alignment = 1 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
    %154 = "llvm.getelementptr"(%25) <{elem_type = i8, rawConstantIndices = array<i32: 6>}> : (!llvm.ptr) -> !llvm.ptr
    %155 = "llvm.ptrtoint"(%154) : (!llvm.ptr) -> i64
    %156 = "llvm.inttoptr"(%155) : (i64) -> !llvm.ptr
    "llvm.store"(%88, %156) <{alignment = 2 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
    %157 = "llvm.getelementptr"(%25) <{elem_type = i8, rawConstantIndices = array<i32: 7>}> : (!llvm.ptr) -> !llvm.ptr
    %158 = "llvm.ptrtoint"(%157) : (!llvm.ptr) -> i64
    %159 = "llvm.inttoptr"(%158) : (i64) -> !llvm.ptr
    "llvm.store"(%94, %159) <{alignment = 1 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
    %160 = "llvm.load"(%25) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
    %161 = "llvm.icmp"(%160, %14) <{predicate = 1 : i64}> : (i8, i8) -> i1
    "llvm.cond_br"(%161)[^bb3, ^bb4] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb3:  // pred: ^bb2
    %162 = "llvm.load"(%51) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
    "llvm.store"(%162, %27) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
    "llvm.br"()[^bb4] : () -> ()
  ^bb4:  // 2 preds: ^bb2, ^bb3
    %163 = "llvm.load"(%139) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
    %164 = "llvm.icmp"(%163, %14) <{predicate = 1 : i64}> : (i8, i8) -> i1
    "llvm.cond_br"(%164)[^bb5, ^bb6] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb5:  // pred: ^bb4
    %165 = "llvm.getelementptr"(%51) <{elem_type = bf16, rawConstantIndices = array<i32: 512>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
    %166 = "llvm.getelementptr"(%27) <{elem_type = bf16, rawConstantIndices = array<i32: 8>}> : (!llvm.ptr) -> !llvm.ptr
    %167 = "llvm.load"(%165) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
    "llvm.store"(%167, %166) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
    "llvm.br"()[^bb6] : () -> ()
  ^bb6:  // 2 preds: ^bb4, ^bb5
    %168 = "llvm.load"(%142) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
    %169 = "llvm.icmp"(%168, %14) <{predicate = 1 : i64}> : (i8, i8) -> i1
    "llvm.cond_br"(%169)[^bb7, ^bb8] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb7:  // pred: ^bb6
    %170 = "llvm.getelementptr"(%51) <{elem_type = bf16, rawConstantIndices = array<i32: 1024>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
    %171 = "llvm.getelementptr"(%27) <{elem_type = bf16, rawConstantIndices = array<i32: 16>}> : (!llvm.ptr) -> !llvm.ptr
    %172 = "llvm.load"(%170) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
    "llvm.store"(%172, %171) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
    "llvm.br"()[^bb8] : () -> ()
  ^bb8:  // 2 preds: ^bb6, ^bb7
    %173 = "llvm.load"(%145) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
    %174 = "llvm.icmp"(%173, %14) <{predicate = 1 : i64}> : (i8, i8) -> i1
    "llvm.cond_br"(%174)[^bb9, ^bb10] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb9:  // pred: ^bb8
    %175 = "llvm.getelementptr"(%51) <{elem_type = bf16, rawConstantIndices = array<i32: 1536>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
    %176 = "llvm.getelementptr"(%27) <{elem_type = bf16, rawConstantIndices = array<i32: 24>}> : (!llvm.ptr) -> !llvm.ptr
    %177 = "llvm.load"(%175) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
    "llvm.store"(%177, %176) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
    "llvm.br"()[^bb10] : () -> ()
  ^bb10:  // 2 preds: ^bb8, ^bb9
    %178 = "llvm.load"(%148) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
    %179 = "llvm.icmp"(%178, %14) <{predicate = 1 : i64}> : (i8, i8) -> i1
    "llvm.cond_br"(%179)[^bb11, ^bb12] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb11:  // pred: ^bb10
    %180 = "llvm.getelementptr"(%51) <{elem_type = bf16, rawConstantIndices = array<i32: 2048>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
    %181 = "llvm.getelementptr"(%27) <{elem_type = bf16, rawConstantIndices = array<i32: 32>}> : (!llvm.ptr) -> !llvm.ptr
    %182 = "llvm.load"(%180) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
    "llvm.store"(%182, %181) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
    "llvm.br"()[^bb12] : () -> ()
  ^bb12:  // 2 preds: ^bb10, ^bb11
    %183 = "llvm.load"(%151) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
    %184 = "llvm.icmp"(%183, %14) <{predicate = 1 : i64}> : (i8, i8) -> i1
    "llvm.cond_br"(%184)[^bb13, ^bb14] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb13:  // pred: ^bb12
    %185 = "llvm.getelementptr"(%51) <{elem_type = bf16, rawConstantIndices = array<i32: 2560>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
    %186 = "llvm.getelementptr"(%27) <{elem_type = bf16, rawConstantIndices = array<i32: 40>}> : (!llvm.ptr) -> !llvm.ptr
    %187 = "llvm.load"(%185) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
    "llvm.store"(%187, %186) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
    "llvm.br"()[^bb14] : () -> ()
  ^bb14:  // 2 preds: ^bb12, ^bb13
    %188 = "llvm.load"(%154) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
    %189 = "llvm.icmp"(%188, %14) <{predicate = 1 : i64}> : (i8, i8) -> i1
    "llvm.cond_br"(%189)[^bb15, ^bb16] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb15:  // pred: ^bb14
    %190 = "llvm.getelementptr"(%51) <{elem_type = bf16, rawConstantIndices = array<i32: 3072>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
    %191 = "llvm.getelementptr"(%27) <{elem_type = bf16, rawConstantIndices = array<i32: 48>}> : (!llvm.ptr) -> !llvm.ptr
    %192 = "llvm.load"(%190) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
    "llvm.store"(%192, %191) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
    "llvm.br"()[^bb16] : () -> ()
  ^bb16:  // 2 preds: ^bb14, ^bb15
    %193 = "llvm.load"(%157) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
    %194 = "llvm.icmp"(%193, %14) <{predicate = 1 : i64}> : (i8, i8) -> i1
    "llvm.cond_br"(%194)[^bb17, ^bb18] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb17:  // pred: ^bb16
    %195 = "llvm.getelementptr"(%51) <{elem_type = bf16, rawConstantIndices = array<i32: 3584>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
    %196 = "llvm.getelementptr"(%27) <{elem_type = bf16, rawConstantIndices = array<i32: 56>}> : (!llvm.ptr) -> !llvm.ptr
    %197 = "llvm.load"(%195) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
    "llvm.store"(%197, %196) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
    "llvm.br"()[^bb18] : () -> ()
  ^bb18:  // 2 preds: ^bb16, ^bb17
    "nvvm.cp.async.wait.group"() <{n = 0 : i32}> : () -> ()
    "llvm.br"(%13)[^bb19] : (i32) -> ()
  ^bb19(%198: i32):  // 2 preds: ^bb18, ^bb20
    %199 = "llvm.icmp"(%198, %23) <{predicate = 2 : i64}> : (i32, i32) -> i1
    "llvm.cond_br"(%199)[^bb20, ^bb21] <{operandSegmentSizes = array<i32: 1, 0, 0>}> {llvm.loop_annotation = #llvm.loop_annotation<unroll = <disable = false, full = true>>} : (i1) -> ()
  ^bb20:  // pred: ^bb19
    %200 = "llvm.mul"(%198, %7) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %201 = "llvm.getelementptr"(%48, %200) <{elem_type = bf16, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>
    %202 = "llvm.mul"(%198, %23) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %203 = "llvm.getelementptr"(%29, %202) <{elem_type = bf16, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr, i32) -> !llvm.ptr
    %204 = "llvm.load"(%201) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<3>) -> vector<8xbf16>
    "llvm.store"(%204, %203) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
    %205 = "llvm.add"(%198, %24) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    "llvm.br"(%205)[^bb19] : (i32) -> ()
  ^bb21:  // pred: ^bb19
    %206 = "llvm.load"(%29) <{alignment = 32 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<64xbf16>
    %207 = "llvm.fpext"(%206) : (vector<64xbf16>) -> vector<64xf32>
    %208 = "llvm.fmul"(%207, %207) <{fastmathFlags = #llvm.fastmath<none>}> : (vector<64xf32>, vector<64xf32>) -> vector<64xf32>
    %209 = "llvm.intr.vector.reduce.fadd"(%15, %208) <{fastmathFlags = #llvm.fastmath<none>}> : (f32, vector<64xf32>) -> f32
    %210 = "nvvm.shfl.sync"(%16, %209, %17, %18) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
    %211 = "llvm.fadd"(%210, %209) <{fastmathFlags = #llvm.fastmath<none>}> : (f32, f32) -> f32
    %212 = "nvvm.shfl.sync"(%16, %211, %23, %18) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
    %213 = "llvm.fadd"(%211, %212) <{fastmathFlags = #llvm.fastmath<none>}> : (f32, f32) -> f32
    %214 = "nvvm.shfl.sync"(%16, %213, %19, %18) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
    %215 = "llvm.fadd"(%213, %214) <{fastmathFlags = #llvm.fastmath<none>}> : (f32, f32) -> f32
    %216 = "nvvm.shfl.sync"(%16, %215, %11, %18) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
    %217 = "llvm.fadd"(%215, %216) <{fastmathFlags = #llvm.fastmath<none>}> : (f32, f32) -> f32
    %218 = "nvvm.shfl.sync"(%16, %217, %24, %18) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
    %219 = "llvm.fadd"(%217, %218) <{fastmathFlags = #llvm.fastmath<none>}> : (f32, f32) -> f32
    %220 = "nvvm.read.ptx.sreg.laneid"() <{range = #llvm.constant_range<i32, 0, 32>}> : () -> i32
    %221 = "nvvm.read.ptx.sreg.tid.y"() <{range = #llvm.constant_range<i32, 0, 1024>}> : () -> i32
    %222 = "nvvm.read.ptx.sreg.tid.z"() <{range = #llvm.constant_range<i32, 0, 64>}> : () -> i32
    %223 = "nvvm.read.ptx.sreg.ntid.x"() <{range = #llvm.constant_range<i32, 1, 1024>}> : () -> i32
    %224 = "nvvm.read.ptx.sreg.ntid.y"() <{range = #llvm.constant_range<i32, 1, 1024>}> : () -> i32
    %225 = "llvm.mul"(%221, %223) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %226 = "llvm.add"(%31, %225) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %227 = "llvm.mul"(%222, %223) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %228 = "llvm.mul"(%227, %224) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %229 = "llvm.add"(%226, %228) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %230 = "llvm.sdiv"(%229, %20) : (i32, i32) -> i32
    %231 = "llvm.mul"(%230, %20) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %232 = "llvm.icmp"(%229, %231) <{predicate = 1 : i64}> : (i32, i32) -> i1
    %233 = "llvm.icmp"(%229, %13) <{predicate = 2 : i64}> : (i32, i32) -> i1
    %234 = "llvm.icmp"(%233, %9) <{predicate = 1 : i64}> : (i1, i1) -> i1
    %235 = "llvm.and"(%232, %234) : (i1, i1) -> i1
    %236 = "llvm.add"(%230, %16) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %237 = "llvm.select"(%235, %236, %230) <{fastmathFlags = #llvm.fastmath<none>}> : (i1, i32, i32) -> i32
    %238 = "llvm.sdiv"(%237, %11) : (i32, i32) -> i32
    %239 = "llvm.mul"(%238, %11) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %240 = "llvm.icmp"(%237, %239) <{predicate = 1 : i64}> : (i32, i32) -> i1
    %241 = "llvm.icmp"(%237, %13) <{predicate = 2 : i64}> : (i32, i32) -> i1
    %242 = "llvm.icmp"(%241, %9) <{predicate = 1 : i64}> : (i1, i1) -> i1
    %243 = "llvm.and"(%240, %242) : (i1, i1) -> i1
    %244 = "llvm.add"(%238, %16) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %245 = "llvm.select"(%243, %244, %238) <{fastmathFlags = #llvm.fastmath<none>}> : (i1, i32, i32) -> i32
    %246 = "llvm.srem"(%237, %11) : (i32, i32) -> i32
    %247 = "llvm.icmp"(%220, %13) <{predicate = 0 : i64}> : (i32, i32) -> i1
    "llvm.cond_br"(%247)[^bb22, ^bb23] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb22:  // pred: ^bb21
    %248 = "llvm.mul"(%246, %11) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %249 = "llvm.add"(%245, %248) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %250 = "llvm.getelementptr"(%35, %249) <{elem_type = f32, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>
    %251 = "llvm.ptrtoint"(%250) : (!llvm.ptr<3>) -> i64
    %252 = "llvm.inttoptr"(%251) : (i64) -> !llvm.ptr<3>
    "llvm.store"(%219, %252) <{alignment = 4 : i64, ordering = 0 : i64}> : (f32, !llvm.ptr<3>) -> ()
    "llvm.br"()[^bb23] : () -> ()
  ^bb23:  // 2 preds: ^bb21, ^bb22
    "llvm.inline_asm"(%13) <{asm_dialect = 0 : i64, asm_string = "bar.sync $0;", constraints = "r", has_side_effects}> : (i32) -> ()
    %253 = "llvm.icmp"(%220, %11) <{predicate = 2 : i64}> : (i32, i32) -> i1
    "llvm.cond_br"(%253)[^bb24, ^bb25] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb24:  // pred: ^bb23
    %254 = "llvm.mul"(%220, %11) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %255 = "llvm.add"(%245, %254) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %256 = "llvm.getelementptr"(%35, %255) <{elem_type = f32, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>
    %257 = "llvm.ptrtoint"(%256) : (!llvm.ptr<3>) -> i64
    %258 = "llvm.inttoptr"(%257) : (i64) -> !llvm.ptr<3>
    %259 = "llvm.load"(%258) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<3>) -> f32
    "llvm.br"(%259)[^bb26] : (f32) -> ()
  ^bb25:  // pred: ^bb23
    "llvm.br"(%15)[^bb26] : (f32) -> ()
  ^bb26(%260: f32):  // 2 preds: ^bb24, ^bb25
    "llvm.br"()[^bb27] : () -> ()
  ^bb27:  // pred: ^bb26
    %261 = "nvvm.shfl.sync"(%16, %260, %17, %18) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
    %262 = "llvm.fadd"(%260, %261) <{fastmathFlags = #llvm.fastmath<none>}> : (f32, f32) -> f32
    %263 = "nvvm.shfl.sync"(%16, %262, %23, %18) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
    %264 = "llvm.fadd"(%262, %263) <{fastmathFlags = #llvm.fastmath<none>}> : (f32, f32) -> f32
    %265 = "nvvm.shfl.sync"(%16, %264, %19, %18) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
    %266 = "llvm.fadd"(%264, %265) <{fastmathFlags = #llvm.fastmath<none>}> : (f32, f32) -> f32
    %267 = "nvvm.shfl.sync"(%16, %266, %11, %18) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
    %268 = "llvm.fadd"(%266, %267) <{fastmathFlags = #llvm.fastmath<none>}> : (f32, f32) -> f32
    %269 = "nvvm.shfl.sync"(%16, %268, %24, %18) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
    %270 = "llvm.fadd"(%268, %269) <{fastmathFlags = #llvm.fastmath<none>}> : (f32, f32) -> f32
    %271 = "llvm.fdiv"(%270, %21) <{fastmathFlags = #llvm.fastmath<none>}> : (f32, f32) -> f32
    %272 = "llvm.fadd"(%271, %arg3) <{fastmathFlags = #llvm.fastmath<none>}> : (f32, f32) -> f32
    %273 = "llvm.call"(%272) <{CConv = #llvm.cconv<ccc>, TailCallKind = #llvm.tailcallkind<none>, callee = @__nv_rsqrtf, fastmathFlags = #llvm.fastmath<none>, op_bundle_sizes = array<i32>, operandSegmentSizes = array<i32: 1, 0>}> : (f32) -> f32
    "llvm.inline_asm"(%13) <{asm_dialect = 0 : i64, asm_string = "bar.sync $0;", constraints = "r", has_side_effects}> : (i32) -> ()
    "llvm.br"(%13)[^bb28] : (i32) -> ()
  ^bb28(%274: i32):  // 2 preds: ^bb27, ^bb29
    %275 = "llvm.icmp"(%274, %23) <{predicate = 2 : i64}> : (i32, i32) -> i1
    "llvm.cond_br"(%275)[^bb29, ^bb30] <{operandSegmentSizes = array<i32: 1, 0, 0>}> {llvm.loop_annotation = #llvm.loop_annotation<unroll = <disable = false, full = true>>} : (i1) -> ()
  ^bb29:  // pred: ^bb28
    %276 = "llvm.mul"(%274, %7) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %277 = "llvm.getelementptr"(%48, %276) <{elem_type = bf16, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>
    %278 = "llvm.mul"(%274, %23) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %279 = "llvm.getelementptr"(%29, %278) <{elem_type = bf16, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr, i32) -> !llvm.ptr
    %280 = "llvm.load"(%277) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<3>) -> vector<8xbf16>
    "llvm.store"(%280, %279) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
    %281 = "llvm.add"(%274, %24) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    "llvm.br"(%281)[^bb28] : (i32) -> ()
  ^bb30:  // pred: ^bb28
    %282 = "llvm.load"(%29) <{alignment = 32 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<64xbf16>
    %283 = "llvm.fpext"(%282) : (vector<64xbf16>) -> vector<64xf32>
    %284 = "llvm.insertelement"(%0, %273, %13) : (vector<64xf32>, f32, i32) -> vector<64xf32>
    %285 = "llvm.shufflevector"(%284, %0) <{mask = array<i32: 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>}> : (vector<64xf32>, vector<64xf32>) -> vector<64xf32>
    %286 = "llvm.fmul"(%283, %285) <{fastmathFlags = #llvm.fastmath<none>}> : (vector<64xf32>, vector<64xf32>) -> vector<64xf32>
    %287 = "llvm.load"(%27) <{alignment = 32 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<64xbf16>
    %288 = "llvm.fpext"(%287) : (vector<64xbf16>) -> vector<64xf32>
    %289 = "llvm.fmul"(%286, %288) <{fastmathFlags = #llvm.fastmath<none>}> : (vector<64xf32>, vector<64xf32>) -> vector<64xf32>
    %290 = "llvm.fptrunc"(%289) : (vector<64xf32>) -> vector<64xbf16>
    "llvm.store"(%290, %28) <{alignment = 32 : i64, ordering = 0 : i64}> : (vector<64xbf16>, !llvm.ptr) -> ()
    "llvm.cond_br"(%98)[^bb31, ^bb48] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb31:  // pred: ^bb30
    %291 = "llvm.load"(%26) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
    %292 = "llvm.icmp"(%291, %14) <{predicate = 1 : i64}> : (i8, i8) -> i1
    "llvm.cond_br"(%292)[^bb32, ^bb33] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb32:  // pred: ^bb31
    %293 = "llvm.load"(%28) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
    "llvm.store"(%293, %49) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
    "llvm.br"()[^bb33] : () -> ()
  ^bb33:  // 2 preds: ^bb31, ^bb32
    %294 = "llvm.load"(%59) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
    %295 = "llvm.icmp"(%294, %14) <{predicate = 1 : i64}> : (i8, i8) -> i1
    "llvm.cond_br"(%295)[^bb34, ^bb35] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb34:  // pred: ^bb33
    %296 = "llvm.getelementptr"(%28) <{elem_type = bf16, rawConstantIndices = array<i32: 8>}> : (!llvm.ptr) -> !llvm.ptr
    %297 = "llvm.getelementptr"(%49) <{elem_type = bf16, rawConstantIndices = array<i32: 512>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
    %298 = "llvm.load"(%296) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
    "llvm.store"(%298, %297) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
    "llvm.br"()[^bb35] : () -> ()
  ^bb35:  // 2 preds: ^bb33, ^bb34
    %299 = "llvm.load"(%65) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
    %300 = "llvm.icmp"(%299, %14) <{predicate = 1 : i64}> : (i8, i8) -> i1
    "llvm.cond_br"(%300)[^bb36, ^bb37] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb36:  // pred: ^bb35
    %301 = "llvm.getelementptr"(%28) <{elem_type = bf16, rawConstantIndices = array<i32: 16>}> : (!llvm.ptr) -> !llvm.ptr
    %302 = "llvm.getelementptr"(%49) <{elem_type = bf16, rawConstantIndices = array<i32: 1024>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
    %303 = "llvm.load"(%301) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
    "llvm.store"(%303, %302) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
    "llvm.br"()[^bb37] : () -> ()
  ^bb37:  // 2 preds: ^bb35, ^bb36
    %304 = "llvm.load"(%71) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
    %305 = "llvm.icmp"(%304, %14) <{predicate = 1 : i64}> : (i8, i8) -> i1
    "llvm.cond_br"(%305)[^bb38, ^bb39] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb38:  // pred: ^bb37
    %306 = "llvm.getelementptr"(%28) <{elem_type = bf16, rawConstantIndices = array<i32: 24>}> : (!llvm.ptr) -> !llvm.ptr
    %307 = "llvm.getelementptr"(%49) <{elem_type = bf16, rawConstantIndices = array<i32: 1536>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
    %308 = "llvm.load"(%306) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
    "llvm.store"(%308, %307) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
    "llvm.br"()[^bb39] : () -> ()
  ^bb39:  // 2 preds: ^bb37, ^bb38
    %309 = "llvm.load"(%77) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
    %310 = "llvm.icmp"(%309, %14) <{predicate = 1 : i64}> : (i8, i8) -> i1
    "llvm.cond_br"(%310)[^bb40, ^bb41] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb40:  // pred: ^bb39
    %311 = "llvm.getelementptr"(%28) <{elem_type = bf16, rawConstantIndices = array<i32: 32>}> : (!llvm.ptr) -> !llvm.ptr
    %312 = "llvm.getelementptr"(%49) <{elem_type = bf16, rawConstantIndices = array<i32: 2048>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
    %313 = "llvm.load"(%311) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
    "llvm.store"(%313, %312) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
    "llvm.br"()[^bb41] : () -> ()
  ^bb41:  // 2 preds: ^bb39, ^bb40
    %314 = "llvm.load"(%83) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
    %315 = "llvm.icmp"(%314, %14) <{predicate = 1 : i64}> : (i8, i8) -> i1
    "llvm.cond_br"(%315)[^bb42, ^bb43] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb42:  // pred: ^bb41
    %316 = "llvm.getelementptr"(%28) <{elem_type = bf16, rawConstantIndices = array<i32: 40>}> : (!llvm.ptr) -> !llvm.ptr
    %317 = "llvm.getelementptr"(%49) <{elem_type = bf16, rawConstantIndices = array<i32: 2560>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
    %318 = "llvm.load"(%316) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
    "llvm.store"(%318, %317) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
    "llvm.br"()[^bb43] : () -> ()
  ^bb43:  // 2 preds: ^bb41, ^bb42
    %319 = "llvm.load"(%89) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
    %320 = "llvm.icmp"(%319, %14) <{predicate = 1 : i64}> : (i8, i8) -> i1
    "llvm.cond_br"(%320)[^bb44, ^bb45] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb44:  // pred: ^bb43
    %321 = "llvm.getelementptr"(%28) <{elem_type = bf16, rawConstantIndices = array<i32: 48>}> : (!llvm.ptr) -> !llvm.ptr
    %322 = "llvm.getelementptr"(%49) <{elem_type = bf16, rawConstantIndices = array<i32: 3072>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
    %323 = "llvm.load"(%321) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
    "llvm.store"(%323, %322) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
    "llvm.br"()[^bb45] : () -> ()
  ^bb45:  // 2 preds: ^bb43, ^bb44
    %324 = "llvm.load"(%95) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
    %325 = "llvm.icmp"(%324, %14) <{predicate = 1 : i64}> : (i8, i8) -> i1
    "llvm.cond_br"(%325)[^bb46, ^bb47] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb46:  // pred: ^bb45
    %326 = "llvm.getelementptr"(%28) <{elem_type = bf16, rawConstantIndices = array<i32: 56>}> : (!llvm.ptr) -> !llvm.ptr
    %327 = "llvm.getelementptr"(%49) <{elem_type = bf16, rawConstantIndices = array<i32: 3584>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
    %328 = "llvm.load"(%326) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
    "llvm.store"(%328, %327) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
    "llvm.br"()[^bb47] : () -> ()
  ^bb47:  // 2 preds: ^bb45, ^bb46
    "llvm.br"()[^bb48] : () -> ()
  ^bb48:  // 2 preds: ^bb30, ^bb47
    "llvm.return"() : () -> ()
  }) {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, gpu.kernel, nvvm.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} : () -> ()
}) {compute_targets = [#cuda.compute_target<sass, conditional, [sm_100]>]} : () -> ()
