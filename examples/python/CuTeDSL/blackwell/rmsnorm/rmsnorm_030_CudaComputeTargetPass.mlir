"gpu.module"() <{sym_name = "kernels"}> ({
  "llvm.mlir.global"() <{addr_space = 3 : i32, alignment = 1024 : i64, dso_local, global_type = !llvm.array<0 x i8>, linkage = #llvm.linkage<external>, sym_name = "__dynamic_shmem__0", visibility_ = 0 : i64}> ({
  }) : () -> ()
  "llvm.func"() <{CConv = #llvm.cconv<ccc>, function_type = !llvm.func<void (struct<(ptr<1>, struct<(i32, struct<()>)>)>, struct<(ptr<1>, struct<(struct<()>, struct<()>)>)>, struct<(ptr<1>, struct<(i32, struct<()>)>)>, f32)>, linkage = #llvm.linkage<external>, sym_name = "kernel_cutlass_kernel___main__RMSNormKernel_object_at__tensorptrbf16gmemalign16o409640961_tensorptrbf16_gmem_align16_o_40961_tensorptrbf16gmemalign16o409640961__2_4096_0", visibility_ = 0 : i64}> ({
  ^bb0(%arg0: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, %arg1: !llvm.struct<(ptr<1>, struct<(struct<()>, struct<()>)>)>, %arg2: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, %arg3: f32):
    %0 = "llvm.mlir.constant"() <{value = 3584 : i32}> : () -> i32
    %1 = "llvm.mlir.constant"() <{value = 3072 : i32}> : () -> i32
    %2 = "llvm.mlir.constant"() <{value = 2560 : i32}> : () -> i32
    %3 = "llvm.mlir.constant"() <{value = 2048 : i32}> : () -> i32
    %4 = "llvm.mlir.constant"() <{value = 1536 : i32}> : () -> i32
    %5 = "llvm.mlir.constant"() <{value = 1024 : i32}> : () -> i32
    %6 = "llvm.mlir.constant"() <{value = 512 : i32}> : () -> i32
    %7 = "llvm.mlir.constant"() <{value = 8192 : i32}> : () -> i32
    %8 = "llvm.mlir.constant"() <{value = false}> : () -> i1
    %9 = "llvm.mlir.addressof"() <{global_name = @__dynamic_shmem__0}> : () -> !llvm.ptr<3>
    %10 = "llvm.mlir.constant"() <{value = 2 : i32}> : () -> i32
    %11 = "llvm.mlir.constant"() <{value = 4096 : i32}> : () -> i32
    %12 = "llvm.mlir.constant"() <{value = 0 : i32}> : () -> i32
    %13 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
    %14 = "llvm.mlir.constant"() <{value = 0.000000e+00 : f32}> : () -> f32
    %15 = "llvm.mlir.constant"() <{value = -1 : i32}> : () -> i32
    %16 = "llvm.mlir.constant"() <{value = 16 : i32}> : () -> i32
    %17 = "llvm.mlir.constant"() <{value = 31 : i32}> : () -> i32
    %18 = "llvm.mlir.constant"() <{value = 4 : i32}> : () -> i32
    %19 = "llvm.mlir.constant"() <{value = 32 : i32}> : () -> i32
    %20 = "llvm.mlir.constant"() <{value = 4.096000e+03 : f32}> : () -> f32
    %21 = "llvm.mlir.constant"() <{value = 64 : i32}> : () -> i32
    %22 = "llvm.mlir.constant"() <{value = 8 : i32}> : () -> i32
    %23 = "llvm.mlir.constant"() <{value = 1 : i32}> : () -> i32
    %24 = "llvm.alloca"(%22) <{alignment = 32 : i64, elem_type = i8}> : (i32) -> !llvm.ptr
    %25 = "llvm.alloca"(%22) <{alignment = 32 : i64, elem_type = i8}> : (i32) -> !llvm.ptr
    %26 = "llvm.alloca"(%21) <{alignment = 32 : i64, elem_type = i16}> : (i32) -> !llvm.ptr
    %27 = "llvm.alloca"(%21) <{alignment = 32 : i64, elem_type = i16}> : (i32) -> !llvm.ptr
    %28 = "llvm.alloca"(%21) <{alignment = 32 : i64, elem_type = i16}> : (i32) -> !llvm.ptr
    %29 = "llvm.extractvalue"(%arg1) <{position = array<i64: 0>}> : (!llvm.struct<(ptr<1>, struct<(struct<()>, struct<()>)>)>) -> !llvm.ptr<1>
    %30 = "nvvm.read.ptx.sreg.tid.x"() <{range = #llvm.constant_range<i32, 0, 1024>}> : () -> i32
    %31 = "nvvm.read.ptx.sreg.ctaid.x"() <{range = #llvm.constant_range<i32, 0, 2147483647>}> : () -> i32
    %32 = "llvm.extractvalue"(%arg0) <{position = array<i64: 1>}> : (!llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>) -> !llvm.struct<(i32, struct<()>)>
    %33 = "llvm.extractvalue"(%32) <{position = array<i64: 0>}> : (!llvm.struct<(i32, struct<()>)>) -> i32
    %34 = "llvm.getelementptr"(%9) <{elem_type = i8, rawConstantIndices = array<i32: 16384>}> : (!llvm.ptr<3>) -> !llvm.ptr<3>
    %35 = "llvm.mul"(%31, %7) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %36 = "llvm.extractvalue"(%arg0) <{position = array<i64: 0>}> : (!llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>) -> !llvm.ptr<1>
    %37 = "llvm.getelementptr"(%36, %35) <{elem_type = bf16, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>
    %38 = "llvm.extractvalue"(%arg2) <{position = array<i64: 0>}> : (!llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>) -> !llvm.ptr<1>
    %39 = "llvm.getelementptr"(%38, %35) <{elem_type = bf16, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>
    %40 = "llvm.mul"(%31, %10) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %41 = "llvm.sdiv"(%30, %21) : (i32, i32) -> i32
    %42 = "llvm.srem"(%30, %21) : (i32, i32) -> i32
    %43 = "llvm.mul"(%42, %22) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %44 = "llvm.mul"(%41, %11) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %45 = "llvm.add"(%43, %44) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %46 = "llvm.getelementptr"(%37, %45) <{elem_type = bf16, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>
    %47 = "llvm.getelementptr"(%9, %45) <{elem_type = bf16, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>
    %48 = "llvm.getelementptr"(%39, %45) <{elem_type = bf16, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>
    %49 = "llvm.add"(%40, %41) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %50 = "llvm.getelementptr"(%29, %43) <{elem_type = bf16, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>
    %51 = "llvm.icmp"(%43, %11) <{predicate = 2 : i64}> : (i32, i32) -> i1
    %52 = "llvm.zext"(%51) : (i1) -> i8
    %53 = "llvm.ptrtoint"(%25) : (!llvm.ptr) -> i64
    %54 = "llvm.inttoptr"(%53) : (i64) -> !llvm.ptr
    "llvm.store"(%52, %54) <{alignment = 32 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
    %55 = "llvm.add"(%43, %6) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %56 = "llvm.icmp"(%55, %11) <{predicate = 2 : i64}> : (i32, i32) -> i1
    %57 = "llvm.zext"(%56) : (i1) -> i8
    %58 = "llvm.getelementptr"(%25) <{elem_type = i8, rawConstantIndices = array<i32: 1>}> : (!llvm.ptr) -> !llvm.ptr
    %59 = "llvm.ptrtoint"(%58) : (!llvm.ptr) -> i64
    %60 = "llvm.inttoptr"(%59) : (i64) -> !llvm.ptr
    "llvm.store"(%57, %60) <{alignment = 1 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
    %61 = "llvm.add"(%43, %5) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %62 = "llvm.icmp"(%61, %11) <{predicate = 2 : i64}> : (i32, i32) -> i1
    %63 = "llvm.zext"(%62) : (i1) -> i8
    %64 = "llvm.getelementptr"(%25) <{elem_type = i8, rawConstantIndices = array<i32: 2>}> : (!llvm.ptr) -> !llvm.ptr
    %65 = "llvm.ptrtoint"(%64) : (!llvm.ptr) -> i64
    %66 = "llvm.inttoptr"(%65) : (i64) -> !llvm.ptr
    "llvm.store"(%63, %66) <{alignment = 2 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
    %67 = "llvm.add"(%43, %4) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %68 = "llvm.icmp"(%67, %11) <{predicate = 2 : i64}> : (i32, i32) -> i1
    %69 = "llvm.zext"(%68) : (i1) -> i8
    %70 = "llvm.getelementptr"(%25) <{elem_type = i8, rawConstantIndices = array<i32: 3>}> : (!llvm.ptr) -> !llvm.ptr
    %71 = "llvm.ptrtoint"(%70) : (!llvm.ptr) -> i64
    %72 = "llvm.inttoptr"(%71) : (i64) -> !llvm.ptr
    "llvm.store"(%69, %72) <{alignment = 1 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
    %73 = "llvm.add"(%43, %3) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %74 = "llvm.icmp"(%73, %11) <{predicate = 2 : i64}> : (i32, i32) -> i1
    %75 = "llvm.zext"(%74) : (i1) -> i8
    %76 = "llvm.getelementptr"(%25) <{elem_type = i8, rawConstantIndices = array<i32: 4>}> : (!llvm.ptr) -> !llvm.ptr
    %77 = "llvm.ptrtoint"(%76) : (!llvm.ptr) -> i64
    %78 = "llvm.inttoptr"(%77) : (i64) -> !llvm.ptr
    "llvm.store"(%75, %78) <{alignment = 4 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
    %79 = "llvm.add"(%43, %2) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %80 = "llvm.icmp"(%79, %11) <{predicate = 2 : i64}> : (i32, i32) -> i1
    %81 = "llvm.zext"(%80) : (i1) -> i8
    %82 = "llvm.getelementptr"(%25) <{elem_type = i8, rawConstantIndices = array<i32: 5>}> : (!llvm.ptr) -> !llvm.ptr
    %83 = "llvm.ptrtoint"(%82) : (!llvm.ptr) -> i64
    %84 = "llvm.inttoptr"(%83) : (i64) -> !llvm.ptr
    "llvm.store"(%81, %84) <{alignment = 1 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
    %85 = "llvm.add"(%43, %1) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %86 = "llvm.icmp"(%85, %11) <{predicate = 2 : i64}> : (i32, i32) -> i1
    %87 = "llvm.zext"(%86) : (i1) -> i8
    %88 = "llvm.getelementptr"(%25) <{elem_type = i8, rawConstantIndices = array<i32: 6>}> : (!llvm.ptr) -> !llvm.ptr
    %89 = "llvm.ptrtoint"(%88) : (!llvm.ptr) -> i64
    %90 = "llvm.inttoptr"(%89) : (i64) -> !llvm.ptr
    "llvm.store"(%87, %90) <{alignment = 2 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
    %91 = "llvm.add"(%43, %0) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %92 = "llvm.icmp"(%91, %11) <{predicate = 2 : i64}> : (i32, i32) -> i1
    %93 = "llvm.zext"(%92) : (i1) -> i8
    %94 = "llvm.getelementptr"(%25) <{elem_type = i8, rawConstantIndices = array<i32: 7>}> : (!llvm.ptr) -> !llvm.ptr
    %95 = "llvm.ptrtoint"(%94) : (!llvm.ptr) -> i64
    %96 = "llvm.inttoptr"(%95) : (i64) -> !llvm.ptr
    "llvm.store"(%93, %96) <{alignment = 1 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
    %97 = "llvm.icmp"(%49, %33) <{predicate = 2 : i64}> : (i32, i32) -> i1
    "llvm.cond_br"(%97)[^bb1, ^bb2] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb1:  // pred: ^bb0
    %98 = "llvm.load"(%25) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
    %99 = "llvm.trunc"(%98) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
    %100 = "llvm.select"(%99, %16, %12) <{fastmathFlags = #llvm.fastmath<none>}> : (i1, i32, i32) -> i32
    %101 = "llvm.mlir.constant"() <{value = 16 : i32}> : () -> i32
    "llvm.inline_asm"(%47, %46, %101, %100) <{asm_dialect = 0 : i64, asm_string = "cp.async.ca.shared.global [$0], [$1], $2, $3;\0A", constraints = "r,l,n,r", has_side_effects}> : (!llvm.ptr<3>, !llvm.ptr<1>, i32, i32) -> ()
    %102 = "llvm.getelementptr"(%46) <{elem_type = bf16, rawConstantIndices = array<i32: 512>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
    %103 = "llvm.getelementptr"(%47) <{elem_type = bf16, rawConstantIndices = array<i32: 512>}> : (!llvm.ptr<3>) -> !llvm.ptr<3>
    %104 = "llvm.load"(%58) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
    %105 = "llvm.trunc"(%104) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
    %106 = "llvm.select"(%105, %16, %12) <{fastmathFlags = #llvm.fastmath<none>}> : (i1, i32, i32) -> i32
    %107 = "llvm.mlir.constant"() <{value = 16 : i32}> : () -> i32
    "llvm.inline_asm"(%103, %102, %107, %106) <{asm_dialect = 0 : i64, asm_string = "cp.async.ca.shared.global [$0], [$1], $2, $3;\0A", constraints = "r,l,n,r", has_side_effects}> : (!llvm.ptr<3>, !llvm.ptr<1>, i32, i32) -> ()
    %108 = "llvm.getelementptr"(%46) <{elem_type = bf16, rawConstantIndices = array<i32: 1024>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
    %109 = "llvm.getelementptr"(%47) <{elem_type = bf16, rawConstantIndices = array<i32: 1024>}> : (!llvm.ptr<3>) -> !llvm.ptr<3>
    %110 = "llvm.load"(%64) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
    %111 = "llvm.trunc"(%110) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
    %112 = "llvm.select"(%111, %16, %12) <{fastmathFlags = #llvm.fastmath<none>}> : (i1, i32, i32) -> i32
    %113 = "llvm.mlir.constant"() <{value = 16 : i32}> : () -> i32
    "llvm.inline_asm"(%109, %108, %113, %112) <{asm_dialect = 0 : i64, asm_string = "cp.async.ca.shared.global [$0], [$1], $2, $3;\0A", constraints = "r,l,n,r", has_side_effects}> : (!llvm.ptr<3>, !llvm.ptr<1>, i32, i32) -> ()
    %114 = "llvm.getelementptr"(%46) <{elem_type = bf16, rawConstantIndices = array<i32: 1536>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
    %115 = "llvm.getelementptr"(%47) <{elem_type = bf16, rawConstantIndices = array<i32: 1536>}> : (!llvm.ptr<3>) -> !llvm.ptr<3>
    %116 = "llvm.load"(%70) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
    %117 = "llvm.trunc"(%116) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
    %118 = "llvm.select"(%117, %16, %12) <{fastmathFlags = #llvm.fastmath<none>}> : (i1, i32, i32) -> i32
    %119 = "llvm.mlir.constant"() <{value = 16 : i32}> : () -> i32
    "llvm.inline_asm"(%115, %114, %119, %118) <{asm_dialect = 0 : i64, asm_string = "cp.async.ca.shared.global [$0], [$1], $2, $3;\0A", constraints = "r,l,n,r", has_side_effects}> : (!llvm.ptr<3>, !llvm.ptr<1>, i32, i32) -> ()
    %120 = "llvm.getelementptr"(%46) <{elem_type = bf16, rawConstantIndices = array<i32: 2048>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
    %121 = "llvm.getelementptr"(%47) <{elem_type = bf16, rawConstantIndices = array<i32: 2048>}> : (!llvm.ptr<3>) -> !llvm.ptr<3>
    %122 = "llvm.load"(%76) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
    %123 = "llvm.trunc"(%122) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
    %124 = "llvm.select"(%123, %16, %12) <{fastmathFlags = #llvm.fastmath<none>}> : (i1, i32, i32) -> i32
    %125 = "llvm.mlir.constant"() <{value = 16 : i32}> : () -> i32
    "llvm.inline_asm"(%121, %120, %125, %124) <{asm_dialect = 0 : i64, asm_string = "cp.async.ca.shared.global [$0], [$1], $2, $3;\0A", constraints = "r,l,n,r", has_side_effects}> : (!llvm.ptr<3>, !llvm.ptr<1>, i32, i32) -> ()
    %126 = "llvm.getelementptr"(%46) <{elem_type = bf16, rawConstantIndices = array<i32: 2560>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
    %127 = "llvm.getelementptr"(%47) <{elem_type = bf16, rawConstantIndices = array<i32: 2560>}> : (!llvm.ptr<3>) -> !llvm.ptr<3>
    %128 = "llvm.load"(%82) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
    %129 = "llvm.trunc"(%128) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
    %130 = "llvm.select"(%129, %16, %12) <{fastmathFlags = #llvm.fastmath<none>}> : (i1, i32, i32) -> i32
    %131 = "llvm.mlir.constant"() <{value = 16 : i32}> : () -> i32
    "llvm.inline_asm"(%127, %126, %131, %130) <{asm_dialect = 0 : i64, asm_string = "cp.async.ca.shared.global [$0], [$1], $2, $3;\0A", constraints = "r,l,n,r", has_side_effects}> : (!llvm.ptr<3>, !llvm.ptr<1>, i32, i32) -> ()
    %132 = "llvm.getelementptr"(%46) <{elem_type = bf16, rawConstantIndices = array<i32: 3072>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
    %133 = "llvm.getelementptr"(%47) <{elem_type = bf16, rawConstantIndices = array<i32: 3072>}> : (!llvm.ptr<3>) -> !llvm.ptr<3>
    %134 = "llvm.load"(%88) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
    %135 = "llvm.trunc"(%134) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
    %136 = "llvm.select"(%135, %16, %12) <{fastmathFlags = #llvm.fastmath<none>}> : (i1, i32, i32) -> i32
    %137 = "llvm.mlir.constant"() <{value = 16 : i32}> : () -> i32
    "llvm.inline_asm"(%133, %132, %137, %136) <{asm_dialect = 0 : i64, asm_string = "cp.async.ca.shared.global [$0], [$1], $2, $3;\0A", constraints = "r,l,n,r", has_side_effects}> : (!llvm.ptr<3>, !llvm.ptr<1>, i32, i32) -> ()
    %138 = "llvm.getelementptr"(%46) <{elem_type = bf16, rawConstantIndices = array<i32: 3584>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
    %139 = "llvm.getelementptr"(%47) <{elem_type = bf16, rawConstantIndices = array<i32: 3584>}> : (!llvm.ptr<3>) -> !llvm.ptr<3>
    %140 = "llvm.load"(%94) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
    %141 = "llvm.trunc"(%140) <{overflowFlags = #llvm.overflow<none>}> : (i8) -> i1
    %142 = "llvm.select"(%141, %16, %12) <{fastmathFlags = #llvm.fastmath<none>}> : (i1, i32, i32) -> i32
    %143 = "llvm.mlir.constant"() <{value = 16 : i32}> : () -> i32
    "llvm.inline_asm"(%139, %138, %143, %142) <{asm_dialect = 0 : i64, asm_string = "cp.async.ca.shared.global [$0], [$1], $2, $3;\0A", constraints = "r,l,n,r", has_side_effects}> : (!llvm.ptr<3>, !llvm.ptr<1>, i32, i32) -> ()
    "llvm.br"()[^bb2] : () -> ()
  ^bb2:  // 2 preds: ^bb0, ^bb1
    "nvvm.cp.async.commit.group"() : () -> ()
    %144 = "llvm.ptrtoint"(%24) : (!llvm.ptr) -> i64
    %145 = "llvm.inttoptr"(%144) : (i64) -> !llvm.ptr
    "llvm.store"(%52, %145) <{alignment = 32 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
    %146 = "llvm.getelementptr"(%24) <{elem_type = i8, rawConstantIndices = array<i32: 1>}> : (!llvm.ptr) -> !llvm.ptr
    %147 = "llvm.ptrtoint"(%146) : (!llvm.ptr) -> i64
    %148 = "llvm.inttoptr"(%147) : (i64) -> !llvm.ptr
    "llvm.store"(%57, %148) <{alignment = 1 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
    %149 = "llvm.getelementptr"(%24) <{elem_type = i8, rawConstantIndices = array<i32: 2>}> : (!llvm.ptr) -> !llvm.ptr
    %150 = "llvm.ptrtoint"(%149) : (!llvm.ptr) -> i64
    %151 = "llvm.inttoptr"(%150) : (i64) -> !llvm.ptr
    "llvm.store"(%63, %151) <{alignment = 2 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
    %152 = "llvm.getelementptr"(%24) <{elem_type = i8, rawConstantIndices = array<i32: 3>}> : (!llvm.ptr) -> !llvm.ptr
    %153 = "llvm.ptrtoint"(%152) : (!llvm.ptr) -> i64
    %154 = "llvm.inttoptr"(%153) : (i64) -> !llvm.ptr
    "llvm.store"(%69, %154) <{alignment = 1 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
    %155 = "llvm.getelementptr"(%24) <{elem_type = i8, rawConstantIndices = array<i32: 4>}> : (!llvm.ptr) -> !llvm.ptr
    %156 = "llvm.ptrtoint"(%155) : (!llvm.ptr) -> i64
    %157 = "llvm.inttoptr"(%156) : (i64) -> !llvm.ptr
    "llvm.store"(%75, %157) <{alignment = 4 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
    %158 = "llvm.getelementptr"(%24) <{elem_type = i8, rawConstantIndices = array<i32: 5>}> : (!llvm.ptr) -> !llvm.ptr
    %159 = "llvm.ptrtoint"(%158) : (!llvm.ptr) -> i64
    %160 = "llvm.inttoptr"(%159) : (i64) -> !llvm.ptr
    "llvm.store"(%81, %160) <{alignment = 1 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
    %161 = "llvm.getelementptr"(%24) <{elem_type = i8, rawConstantIndices = array<i32: 6>}> : (!llvm.ptr) -> !llvm.ptr
    %162 = "llvm.ptrtoint"(%161) : (!llvm.ptr) -> i64
    %163 = "llvm.inttoptr"(%162) : (i64) -> !llvm.ptr
    "llvm.store"(%87, %163) <{alignment = 2 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
    %164 = "llvm.getelementptr"(%24) <{elem_type = i8, rawConstantIndices = array<i32: 7>}> : (!llvm.ptr) -> !llvm.ptr
    %165 = "llvm.ptrtoint"(%164) : (!llvm.ptr) -> i64
    %166 = "llvm.inttoptr"(%165) : (i64) -> !llvm.ptr
    "llvm.store"(%93, %166) <{alignment = 1 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr) -> ()
    %167 = "llvm.load"(%24) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
    %168 = "llvm.icmp"(%167, %13) <{predicate = 1 : i64}> : (i8, i8) -> i1
    "llvm.cond_br"(%168)[^bb3, ^bb4] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb3:  // pred: ^bb2
    %169 = "llvm.load"(%50) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
    "llvm.store"(%169, %26) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
    "llvm.br"()[^bb4] : () -> ()
  ^bb4:  // 2 preds: ^bb2, ^bb3
    %170 = "llvm.load"(%146) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
    %171 = "llvm.icmp"(%170, %13) <{predicate = 1 : i64}> : (i8, i8) -> i1
    "llvm.cond_br"(%171)[^bb5, ^bb6] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb5:  // pred: ^bb4
    %172 = "llvm.getelementptr"(%50) <{elem_type = bf16, rawConstantIndices = array<i32: 512>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
    %173 = "llvm.getelementptr"(%26) <{elem_type = bf16, rawConstantIndices = array<i32: 8>}> : (!llvm.ptr) -> !llvm.ptr
    %174 = "llvm.load"(%172) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
    "llvm.store"(%174, %173) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
    "llvm.br"()[^bb6] : () -> ()
  ^bb6:  // 2 preds: ^bb4, ^bb5
    %175 = "llvm.load"(%149) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
    %176 = "llvm.icmp"(%175, %13) <{predicate = 1 : i64}> : (i8, i8) -> i1
    "llvm.cond_br"(%176)[^bb7, ^bb8] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb7:  // pred: ^bb6
    %177 = "llvm.getelementptr"(%50) <{elem_type = bf16, rawConstantIndices = array<i32: 1024>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
    %178 = "llvm.getelementptr"(%26) <{elem_type = bf16, rawConstantIndices = array<i32: 16>}> : (!llvm.ptr) -> !llvm.ptr
    %179 = "llvm.load"(%177) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
    "llvm.store"(%179, %178) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
    "llvm.br"()[^bb8] : () -> ()
  ^bb8:  // 2 preds: ^bb6, ^bb7
    %180 = "llvm.load"(%152) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
    %181 = "llvm.icmp"(%180, %13) <{predicate = 1 : i64}> : (i8, i8) -> i1
    "llvm.cond_br"(%181)[^bb9, ^bb10] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb9:  // pred: ^bb8
    %182 = "llvm.getelementptr"(%50) <{elem_type = bf16, rawConstantIndices = array<i32: 1536>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
    %183 = "llvm.getelementptr"(%26) <{elem_type = bf16, rawConstantIndices = array<i32: 24>}> : (!llvm.ptr) -> !llvm.ptr
    %184 = "llvm.load"(%182) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
    "llvm.store"(%184, %183) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
    "llvm.br"()[^bb10] : () -> ()
  ^bb10:  // 2 preds: ^bb8, ^bb9
    %185 = "llvm.load"(%155) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
    %186 = "llvm.icmp"(%185, %13) <{predicate = 1 : i64}> : (i8, i8) -> i1
    "llvm.cond_br"(%186)[^bb11, ^bb12] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb11:  // pred: ^bb10
    %187 = "llvm.getelementptr"(%50) <{elem_type = bf16, rawConstantIndices = array<i32: 2048>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
    %188 = "llvm.getelementptr"(%26) <{elem_type = bf16, rawConstantIndices = array<i32: 32>}> : (!llvm.ptr) -> !llvm.ptr
    %189 = "llvm.load"(%187) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
    "llvm.store"(%189, %188) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
    "llvm.br"()[^bb12] : () -> ()
  ^bb12:  // 2 preds: ^bb10, ^bb11
    %190 = "llvm.load"(%158) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
    %191 = "llvm.icmp"(%190, %13) <{predicate = 1 : i64}> : (i8, i8) -> i1
    "llvm.cond_br"(%191)[^bb13, ^bb14] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb13:  // pred: ^bb12
    %192 = "llvm.getelementptr"(%50) <{elem_type = bf16, rawConstantIndices = array<i32: 2560>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
    %193 = "llvm.getelementptr"(%26) <{elem_type = bf16, rawConstantIndices = array<i32: 40>}> : (!llvm.ptr) -> !llvm.ptr
    %194 = "llvm.load"(%192) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
    "llvm.store"(%194, %193) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
    "llvm.br"()[^bb14] : () -> ()
  ^bb14:  // 2 preds: ^bb12, ^bb13
    %195 = "llvm.load"(%161) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
    %196 = "llvm.icmp"(%195, %13) <{predicate = 1 : i64}> : (i8, i8) -> i1
    "llvm.cond_br"(%196)[^bb15, ^bb16] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb15:  // pred: ^bb14
    %197 = "llvm.getelementptr"(%50) <{elem_type = bf16, rawConstantIndices = array<i32: 3072>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
    %198 = "llvm.getelementptr"(%26) <{elem_type = bf16, rawConstantIndices = array<i32: 48>}> : (!llvm.ptr) -> !llvm.ptr
    %199 = "llvm.load"(%197) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
    "llvm.store"(%199, %198) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
    "llvm.br"()[^bb16] : () -> ()
  ^bb16:  // 2 preds: ^bb14, ^bb15
    %200 = "llvm.load"(%164) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
    %201 = "llvm.icmp"(%200, %13) <{predicate = 1 : i64}> : (i8, i8) -> i1
    "llvm.cond_br"(%201)[^bb17, ^bb18] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb17:  // pred: ^bb16
    %202 = "llvm.getelementptr"(%50) <{elem_type = bf16, rawConstantIndices = array<i32: 3584>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
    %203 = "llvm.getelementptr"(%26) <{elem_type = bf16, rawConstantIndices = array<i32: 56>}> : (!llvm.ptr) -> !llvm.ptr
    %204 = "llvm.load"(%202) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<1>) -> vector<8xbf16>
    "llvm.store"(%204, %203) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
    "llvm.br"()[^bb18] : () -> ()
  ^bb18:  // 2 preds: ^bb16, ^bb17
    "nvvm.cp.async.wait.group"() <{n = 0 : i32}> : () -> ()
    "llvm.br"(%12)[^bb19] : (i32) -> ()
  ^bb19(%205: i32):  // 2 preds: ^bb18, ^bb20
    %206 = "llvm.icmp"(%205, %22) <{predicate = 2 : i64}> : (i32, i32) -> i1
    "llvm.cond_br"(%206)[^bb20, ^bb21] <{operandSegmentSizes = array<i32: 1, 0, 0>}> {llvm.loop_annotation = #llvm.loop_annotation<unroll = <disable = false, full = true>>} : (i1) -> ()
  ^bb20:  // pred: ^bb19
    %207 = "llvm.mul"(%205, %6) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %208 = "llvm.getelementptr"(%47, %207) <{elem_type = bf16, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>
    %209 = "llvm.mul"(%205, %22) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %210 = "llvm.getelementptr"(%28, %209) <{elem_type = bf16, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr, i32) -> !llvm.ptr
    %211 = "llvm.load"(%208) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<3>) -> vector<8xbf16>
    "llvm.store"(%211, %210) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
    %212 = "llvm.add"(%205, %23) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    "llvm.br"(%212)[^bb19] : (i32) -> ()
  ^bb21:  // pred: ^bb19
    %213 = "llvm.load"(%28) <{alignment = 32 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<64xbf16>
    %214 = "llvm.fpext"(%213) : (vector<64xbf16>) -> vector<64xf32>
    %215 = "llvm.fmul"(%214, %214) <{fastmathFlags = #llvm.fastmath<none>}> : (vector<64xf32>, vector<64xf32>) -> vector<64xf32>
    %216 = "llvm.intr.vector.reduce.fadd"(%14, %215) <{fastmathFlags = #llvm.fastmath<none>}> : (f32, vector<64xf32>) -> f32
    %217 = "nvvm.shfl.sync"(%15, %216, %16, %17) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
    %218 = "llvm.fadd"(%217, %216) <{fastmathFlags = #llvm.fastmath<none>}> : (f32, f32) -> f32
    %219 = "nvvm.shfl.sync"(%15, %218, %22, %17) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
    %220 = "llvm.fadd"(%218, %219) <{fastmathFlags = #llvm.fastmath<none>}> : (f32, f32) -> f32
    %221 = "nvvm.shfl.sync"(%15, %220, %18, %17) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
    %222 = "llvm.fadd"(%220, %221) <{fastmathFlags = #llvm.fastmath<none>}> : (f32, f32) -> f32
    %223 = "nvvm.shfl.sync"(%15, %222, %10, %17) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
    %224 = "llvm.fadd"(%222, %223) <{fastmathFlags = #llvm.fastmath<none>}> : (f32, f32) -> f32
    %225 = "nvvm.shfl.sync"(%15, %224, %23, %17) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
    %226 = "llvm.fadd"(%224, %225) <{fastmathFlags = #llvm.fastmath<none>}> : (f32, f32) -> f32
    %227 = "nvvm.read.ptx.sreg.laneid"() <{range = #llvm.constant_range<i32, 0, 32>}> : () -> i32
    %228 = "nvvm.read.ptx.sreg.tid.y"() <{range = #llvm.constant_range<i32, 0, 1024>}> : () -> i32
    %229 = "nvvm.read.ptx.sreg.tid.z"() <{range = #llvm.constant_range<i32, 0, 64>}> : () -> i32
    %230 = "nvvm.read.ptx.sreg.ntid.x"() <{range = #llvm.constant_range<i32, 1, 1024>}> : () -> i32
    %231 = "nvvm.read.ptx.sreg.ntid.y"() <{range = #llvm.constant_range<i32, 1, 1024>}> : () -> i32
    %232 = "llvm.mul"(%228, %230) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %233 = "llvm.add"(%30, %232) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %234 = "llvm.mul"(%229, %230) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %235 = "llvm.mul"(%234, %231) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %236 = "llvm.add"(%233, %235) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %237 = "llvm.sdiv"(%236, %19) : (i32, i32) -> i32
    %238 = "llvm.mul"(%237, %19) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %239 = "llvm.icmp"(%236, %238) <{predicate = 1 : i64}> : (i32, i32) -> i1
    %240 = "llvm.icmp"(%236, %12) <{predicate = 2 : i64}> : (i32, i32) -> i1
    %241 = "llvm.icmp"(%240, %8) <{predicate = 1 : i64}> : (i1, i1) -> i1
    %242 = "llvm.and"(%239, %241) : (i1, i1) -> i1
    %243 = "llvm.add"(%237, %15) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %244 = "llvm.select"(%242, %243, %237) <{fastmathFlags = #llvm.fastmath<none>}> : (i1, i32, i32) -> i32
    %245 = "llvm.sdiv"(%244, %10) : (i32, i32) -> i32
    %246 = "llvm.mul"(%245, %10) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %247 = "llvm.icmp"(%244, %246) <{predicate = 1 : i64}> : (i32, i32) -> i1
    %248 = "llvm.icmp"(%244, %12) <{predicate = 2 : i64}> : (i32, i32) -> i1
    %249 = "llvm.icmp"(%248, %8) <{predicate = 1 : i64}> : (i1, i1) -> i1
    %250 = "llvm.and"(%247, %249) : (i1, i1) -> i1
    %251 = "llvm.add"(%245, %15) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %252 = "llvm.select"(%250, %251, %245) <{fastmathFlags = #llvm.fastmath<none>}> : (i1, i32, i32) -> i32
    %253 = "llvm.srem"(%244, %10) : (i32, i32) -> i32
    %254 = "llvm.icmp"(%227, %12) <{predicate = 0 : i64}> : (i32, i32) -> i1
    "llvm.cond_br"(%254)[^bb22, ^bb23] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb22:  // pred: ^bb21
    %255 = "llvm.mul"(%253, %10) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %256 = "llvm.add"(%252, %255) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %257 = "llvm.getelementptr"(%34, %256) <{elem_type = f32, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>
    %258 = "llvm.ptrtoint"(%257) : (!llvm.ptr<3>) -> i64
    %259 = "llvm.inttoptr"(%258) : (i64) -> !llvm.ptr<3>
    "llvm.store"(%226, %259) <{alignment = 4 : i64, ordering = 0 : i64}> : (f32, !llvm.ptr<3>) -> ()
    "llvm.br"()[^bb23] : () -> ()
  ^bb23:  // 2 preds: ^bb21, ^bb22
    "llvm.inline_asm"(%12) <{asm_dialect = 0 : i64, asm_string = "bar.sync $0;", constraints = "r", has_side_effects}> : (i32) -> ()
    %260 = "llvm.icmp"(%227, %10) <{predicate = 2 : i64}> : (i32, i32) -> i1
    "llvm.cond_br"(%260)[^bb24, ^bb25] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb24:  // pred: ^bb23
    %261 = "llvm.mul"(%227, %10) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %262 = "llvm.add"(%252, %261) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %263 = "llvm.getelementptr"(%34, %262) <{elem_type = f32, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>
    %264 = "llvm.ptrtoint"(%263) : (!llvm.ptr<3>) -> i64
    %265 = "llvm.inttoptr"(%264) : (i64) -> !llvm.ptr<3>
    %266 = "llvm.load"(%265) <{alignment = 4 : i64, ordering = 0 : i64}> : (!llvm.ptr<3>) -> f32
    "llvm.br"(%266)[^bb26] : (f32) -> ()
  ^bb25:  // pred: ^bb23
    "llvm.br"(%14)[^bb26] : (f32) -> ()
  ^bb26(%267: f32):  // 2 preds: ^bb24, ^bb25
    "llvm.br"()[^bb27] : () -> ()
  ^bb27:  // pred: ^bb26
    %268 = "nvvm.shfl.sync"(%15, %267, %16, %17) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
    %269 = "llvm.fadd"(%267, %268) <{fastmathFlags = #llvm.fastmath<none>}> : (f32, f32) -> f32
    %270 = "nvvm.shfl.sync"(%15, %269, %22, %17) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
    %271 = "llvm.fadd"(%269, %270) <{fastmathFlags = #llvm.fastmath<none>}> : (f32, f32) -> f32
    %272 = "nvvm.shfl.sync"(%15, %271, %18, %17) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
    %273 = "llvm.fadd"(%271, %272) <{fastmathFlags = #llvm.fastmath<none>}> : (f32, f32) -> f32
    %274 = "nvvm.shfl.sync"(%15, %273, %10, %17) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
    %275 = "llvm.fadd"(%273, %274) <{fastmathFlags = #llvm.fastmath<none>}> : (f32, f32) -> f32
    %276 = "nvvm.shfl.sync"(%15, %275, %23, %17) <{kind = #nvvm<shfl_kind bfly>}> : (i32, f32, i32, i32) -> f32
    %277 = "llvm.fadd"(%275, %276) <{fastmathFlags = #llvm.fastmath<none>}> : (f32, f32) -> f32
    %278 = "llvm.fdiv"(%277, %20) <{fastmathFlags = #llvm.fastmath<none>}> : (f32, f32) -> f32
    %279 = "llvm.fadd"(%278, %arg3) <{fastmathFlags = #llvm.fastmath<none>}> : (f32, f32) -> f32
    %280 = "math.rsqrt"(%279) <{fastmath = #arith.fastmath<fast>}> : (f32) -> f32
    "llvm.inline_asm"(%12) <{asm_dialect = 0 : i64, asm_string = "bar.sync $0;", constraints = "r", has_side_effects}> : (i32) -> ()
    "llvm.br"(%12)[^bb28] : (i32) -> ()
  ^bb28(%281: i32):  // 2 preds: ^bb27, ^bb29
    %282 = "llvm.icmp"(%281, %22) <{predicate = 2 : i64}> : (i32, i32) -> i1
    "llvm.cond_br"(%282)[^bb29, ^bb30] <{operandSegmentSizes = array<i32: 1, 0, 0>}> {llvm.loop_annotation = #llvm.loop_annotation<unroll = <disable = false, full = true>>} : (i1) -> ()
  ^bb29:  // pred: ^bb28
    %283 = "llvm.mul"(%281, %6) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %284 = "llvm.getelementptr"(%47, %283) <{elem_type = bf16, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>
    %285 = "llvm.mul"(%281, %22) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %286 = "llvm.getelementptr"(%28, %285) <{elem_type = bf16, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr, i32) -> !llvm.ptr
    %287 = "llvm.load"(%284) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr<3>) -> vector<8xbf16>
    "llvm.store"(%287, %286) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr) -> ()
    %288 = "llvm.add"(%281, %23) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    "llvm.br"(%288)[^bb28] : (i32) -> ()
  ^bb30:  // pred: ^bb28
    %289 = "llvm.load"(%28) <{alignment = 32 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<64xbf16>
    %290 = "llvm.fpext"(%289) : (vector<64xbf16>) -> vector<64xf32>
    %291 = "llvm.mlir.undef"() : () -> vector<64xf32>
    %292 = "llvm.mlir.constant"() <{value = 0 : i32}> : () -> i32
    %293 = "llvm.insertelement"(%291, %280, %292) : (vector<64xf32>, f32, i32) -> vector<64xf32>
    %294 = "llvm.shufflevector"(%293, %291) <{mask = array<i32: 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>}> : (vector<64xf32>, vector<64xf32>) -> vector<64xf32>
    %295 = "llvm.fmul"(%290, %294) <{fastmathFlags = #llvm.fastmath<none>}> : (vector<64xf32>, vector<64xf32>) -> vector<64xf32>
    %296 = "llvm.load"(%26) <{alignment = 32 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<64xbf16>
    %297 = "llvm.fpext"(%296) : (vector<64xbf16>) -> vector<64xf32>
    %298 = "llvm.fmul"(%295, %297) <{fastmathFlags = #llvm.fastmath<none>}> : (vector<64xf32>, vector<64xf32>) -> vector<64xf32>
    %299 = "llvm.fptrunc"(%298) : (vector<64xf32>) -> vector<64xbf16>
    "llvm.store"(%299, %27) <{alignment = 32 : i64, ordering = 0 : i64}> : (vector<64xbf16>, !llvm.ptr) -> ()
    "llvm.cond_br"(%97)[^bb31, ^bb48] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb31:  // pred: ^bb30
    %300 = "llvm.load"(%25) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
    %301 = "llvm.icmp"(%300, %13) <{predicate = 1 : i64}> : (i8, i8) -> i1
    "llvm.cond_br"(%301)[^bb32, ^bb33] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb32:  // pred: ^bb31
    %302 = "llvm.load"(%27) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
    "llvm.store"(%302, %48) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
    "llvm.br"()[^bb33] : () -> ()
  ^bb33:  // 2 preds: ^bb31, ^bb32
    %303 = "llvm.load"(%58) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
    %304 = "llvm.icmp"(%303, %13) <{predicate = 1 : i64}> : (i8, i8) -> i1
    "llvm.cond_br"(%304)[^bb34, ^bb35] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb34:  // pred: ^bb33
    %305 = "llvm.getelementptr"(%27) <{elem_type = bf16, rawConstantIndices = array<i32: 8>}> : (!llvm.ptr) -> !llvm.ptr
    %306 = "llvm.getelementptr"(%48) <{elem_type = bf16, rawConstantIndices = array<i32: 512>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
    %307 = "llvm.load"(%305) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
    "llvm.store"(%307, %306) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
    "llvm.br"()[^bb35] : () -> ()
  ^bb35:  // 2 preds: ^bb33, ^bb34
    %308 = "llvm.load"(%64) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
    %309 = "llvm.icmp"(%308, %13) <{predicate = 1 : i64}> : (i8, i8) -> i1
    "llvm.cond_br"(%309)[^bb36, ^bb37] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb36:  // pred: ^bb35
    %310 = "llvm.getelementptr"(%27) <{elem_type = bf16, rawConstantIndices = array<i32: 16>}> : (!llvm.ptr) -> !llvm.ptr
    %311 = "llvm.getelementptr"(%48) <{elem_type = bf16, rawConstantIndices = array<i32: 1024>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
    %312 = "llvm.load"(%310) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
    "llvm.store"(%312, %311) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
    "llvm.br"()[^bb37] : () -> ()
  ^bb37:  // 2 preds: ^bb35, ^bb36
    %313 = "llvm.load"(%70) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
    %314 = "llvm.icmp"(%313, %13) <{predicate = 1 : i64}> : (i8, i8) -> i1
    "llvm.cond_br"(%314)[^bb38, ^bb39] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb38:  // pred: ^bb37
    %315 = "llvm.getelementptr"(%27) <{elem_type = bf16, rawConstantIndices = array<i32: 24>}> : (!llvm.ptr) -> !llvm.ptr
    %316 = "llvm.getelementptr"(%48) <{elem_type = bf16, rawConstantIndices = array<i32: 1536>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
    %317 = "llvm.load"(%315) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
    "llvm.store"(%317, %316) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
    "llvm.br"()[^bb39] : () -> ()
  ^bb39:  // 2 preds: ^bb37, ^bb38
    %318 = "llvm.load"(%76) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
    %319 = "llvm.icmp"(%318, %13) <{predicate = 1 : i64}> : (i8, i8) -> i1
    "llvm.cond_br"(%319)[^bb40, ^bb41] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb40:  // pred: ^bb39
    %320 = "llvm.getelementptr"(%27) <{elem_type = bf16, rawConstantIndices = array<i32: 32>}> : (!llvm.ptr) -> !llvm.ptr
    %321 = "llvm.getelementptr"(%48) <{elem_type = bf16, rawConstantIndices = array<i32: 2048>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
    %322 = "llvm.load"(%320) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
    "llvm.store"(%322, %321) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
    "llvm.br"()[^bb41] : () -> ()
  ^bb41:  // 2 preds: ^bb39, ^bb40
    %323 = "llvm.load"(%82) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
    %324 = "llvm.icmp"(%323, %13) <{predicate = 1 : i64}> : (i8, i8) -> i1
    "llvm.cond_br"(%324)[^bb42, ^bb43] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb42:  // pred: ^bb41
    %325 = "llvm.getelementptr"(%27) <{elem_type = bf16, rawConstantIndices = array<i32: 40>}> : (!llvm.ptr) -> !llvm.ptr
    %326 = "llvm.getelementptr"(%48) <{elem_type = bf16, rawConstantIndices = array<i32: 2560>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
    %327 = "llvm.load"(%325) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
    "llvm.store"(%327, %326) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
    "llvm.br"()[^bb43] : () -> ()
  ^bb43:  // 2 preds: ^bb41, ^bb42
    %328 = "llvm.load"(%88) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
    %329 = "llvm.icmp"(%328, %13) <{predicate = 1 : i64}> : (i8, i8) -> i1
    "llvm.cond_br"(%329)[^bb44, ^bb45] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb44:  // pred: ^bb43
    %330 = "llvm.getelementptr"(%27) <{elem_type = bf16, rawConstantIndices = array<i32: 48>}> : (!llvm.ptr) -> !llvm.ptr
    %331 = "llvm.getelementptr"(%48) <{elem_type = bf16, rawConstantIndices = array<i32: 3072>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
    %332 = "llvm.load"(%330) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
    "llvm.store"(%332, %331) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
    "llvm.br"()[^bb45] : () -> ()
  ^bb45:  // 2 preds: ^bb43, ^bb44
    %333 = "llvm.load"(%94) <{ordering = 0 : i64}> : (!llvm.ptr) -> i8
    %334 = "llvm.icmp"(%333, %13) <{predicate = 1 : i64}> : (i8, i8) -> i1
    "llvm.cond_br"(%334)[^bb46, ^bb47] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb46:  // pred: ^bb45
    %335 = "llvm.getelementptr"(%27) <{elem_type = bf16, rawConstantIndices = array<i32: 56>}> : (!llvm.ptr) -> !llvm.ptr
    %336 = "llvm.getelementptr"(%48) <{elem_type = bf16, rawConstantIndices = array<i32: 3584>}> : (!llvm.ptr<1>) -> !llvm.ptr<1>
    %337 = "llvm.load"(%335) <{alignment = 16 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<8xbf16>
    "llvm.store"(%337, %336) <{alignment = 16 : i64, ordering = 0 : i64}> : (vector<8xbf16>, !llvm.ptr<1>) -> ()
    "llvm.br"()[^bb47] : () -> ()
  ^bb47:  // 2 preds: ^bb45, ^bb46
    "llvm.br"()[^bb48] : () -> ()
  ^bb48:  // 2 preds: ^bb30, ^bb47
    "llvm.return"() : () -> ()
  }) {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, gpu.kernel, nvvm.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} : () -> ()
}) {compute_targets = [#cuda.compute_target<sass, conditional, [sm_100]>]} : () -> ()
