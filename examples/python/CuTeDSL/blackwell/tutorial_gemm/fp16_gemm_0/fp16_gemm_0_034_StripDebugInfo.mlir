"gpu.module"() <{sym_name = "kernels"}> ({
  "llvm.mlir.global"() <{addr_space = 3 : i32, alignment = 1024 : i64, dso_local, global_type = !llvm.array<0 x i8>, linkage = #llvm.linkage<external>, sym_name = "__dynamic_shmem__0", visibility_ = 0 : i64}> ({
  }) : () -> ()
  "llvm.func"() <{CConv = #llvm.cconv<ccc>, arg_attrs = [{}, {llvm.align = 64 : i64, llvm.byval = !llvm.struct<(struct<(array<16 x i64>)>)>, nvvm.grid_constant}, {}, {llvm.align = 64 : i64, llvm.byval = !llvm.struct<(struct<(array<16 x i64>)>)>, nvvm.grid_constant}, {}, {}], function_type = !llvm.func<void (struct<(i1, i1, i1)>, ptr, struct<(struct<()>, struct<(struct<(i32, i32)>, struct<()>)>)>, ptr, struct<(struct<()>, struct<(struct<(i32, i32)>, struct<()>)>)>, struct<(ptr<1>, struct<(struct<(i32, i32)>, i64)>)>)>, linkage = #llvm.linkage<external>, sym_name = "kernel_cutlass_kernel_TiledMMA_ThrLayoutVMNK11110000_PermutationMNK____MMAAtom_ThrID10_ShapeMNK12825616_TVLayoutA1128161281128_TVLayoutB1256162561256_TVLayoutC11282561281128_CopyAtom_ThrI_0", visibility_ = 0 : i64}> ({
  ^bb0(%arg0: !llvm.struct<(i1, i1, i1)>, %arg1: !llvm.ptr, %arg2: !llvm.struct<(struct<()>, struct<(struct<(i32, i32)>, struct<()>)>)>, %arg3: !llvm.ptr, %arg4: !llvm.struct<(struct<()>, struct<(struct<(i32, i32)>, struct<()>)>)>, %arg5: !llvm.struct<(ptr<1>, struct<(struct<(i32, i32)>, i64)>)>):
    %0 = "llvm.mlir.constant"() <{value = 16 : i32}> : () -> i32
    %1 = "llvm.mlir.constant"() <{value = dense<0> : vector<4xi32>}> : () -> vector<4xi32>
    %2 = "llvm.mlir.constant"() <{value = 2048 : i32}> : () -> i32
    %3 = "llvm.mlir.constant"() <{value = 1024 : i32}> : () -> i32
    %4 = "llvm.mlir.constant"() <{value = 16384 : i32}> : () -> i32
    %5 = "llvm.mlir.constant"() <{value = 8192 : i32}> : () -> i32
    %6 = "llvm.mlir.zero"() : () -> !llvm.struct<(ptr, ptr<3>, i16, i64, struct<()>)>
    %7 = "llvm.mlir.constant"() <{value = 0 : i8}> : () -> i8
    %8 = "llvm.mlir.constant"() <{value = 2 : i8}> : () -> i8
    %9 = "llvm.mlir.undef"() : () -> !llvm.struct<(struct<(i32, i32)>, struct<(i64, i64)>)>
    %10 = "llvm.mlir.undef"() : () -> !llvm.struct<(i64, i64)>
    %11 = "llvm.mlir.undef"() : () -> !llvm.struct<(struct<(i32, i32)>, struct<()>)>
    %12 = "llvm.mlir.undef"() : () -> !llvm.struct<(i32, i32)>
    %13 = "llvm.mlir.constant"() <{value = 6 : i32}> : () -> i32
    %14 = "llvm.mlir.addressof"() <{global_name = @__dynamic_shmem__0}> : () -> !llvm.ptr<3>
    %15 = "llvm.mlir.constant"() <{value = 31 : i32}> : () -> i32
    %16 = "llvm.mlir.constant"() <{value = -1 : i32}> : () -> i32
    %17 = "llvm.mlir.constant"() <{value = false}> : () -> i1
    %18 = "llvm.mlir.constant"() <{value = 32 : i32}> : () -> i32
    %19 = "llvm.mlir.constant"() <{value = 128 : i32}> : () -> i32
    %20 = "llvm.mlir.constant"() <{value = -128 : i32}> : () -> i32
    %21 = "llvm.mlir.constant"() <{value = 0 : i32}> : () -> i32
    %22 = "llvm.mlir.constant"() <{value = 512 : i32}> : () -> i32
    %23 = "llvm.mlir.constant"() <{value = 256 : i32}> : () -> i32
    %24 = "llvm.mlir.constant"() <{value = 128 : i64}> : () -> i64
    %25 = "llvm.mlir.constant"() <{value = 2097152 : i32}> : () -> i32
    %26 = "llvm.mlir.constant"() <{value = 32 : i64}> : () -> i64
    %27 = "llvm.mlir.constant"() <{value = true}> : () -> i1
    %28 = "llvm.mlir.constant"() <{value = 10000000 : i32}> : () -> i32
    %29 = "llvm.mlir.constant"() <{value = 4 : i32}> : () -> i32
    %30 = "llvm.mlir.constant"() <{value = 2 : i32}> : () -> i32
    %31 = "llvm.mlir.constant"() <{value = 49152 : i32}> : () -> i32
    %32 = "llvm.mlir.constant"() <{value = 138412048 : i32}> : () -> i32
    %33 = "llvm.mlir.constant"() <{value = 13 : i32}> : () -> i32
    %34 = "llvm.mlir.constant"() <{value = 14 : i32}> : () -> i32
    %35 = "llvm.mlir.constant"() <{value = 127 : i32}> : () -> i32
    %36 = "llvm.mlir.constant"() <{value = 64 : i32}> : () -> i32
    %37 = "llvm.mlir.constant"() <{value = 1 : i32}> : () -> i32
    %38 = "llvm.alloca"(%36) <{alignment = 32 : i64, elem_type = i16}> : (i32) -> !llvm.ptr
    %39 = "llvm.alloca"(%36) <{alignment = 32 : i64, elem_type = i32}> : (i32) -> !llvm.ptr
    "llvm.inline_asm"(%arg1) <{asm_dialect = 0 : i64, asm_string = "prefetch.tensormap [$0];", constraints = "l", has_side_effects}> : (!llvm.ptr) -> ()
    "llvm.inline_asm"(%arg3) <{asm_dialect = 0 : i64, asm_string = "prefetch.tensormap [$0];", constraints = "l", has_side_effects}> : (!llvm.ptr) -> ()
    %40 = "nvvm.read.ptx.sreg.tid.x"() <{range = #llvm.constant_range<i32, 0, 1024>}> : () -> i32
    %41 = "nvvm.read.ptx.sreg.tid.y"() <{range = #llvm.constant_range<i32, 0, 1024>}> : () -> i32
    %42 = "nvvm.read.ptx.sreg.tid.z"() <{range = #llvm.constant_range<i32, 0, 64>}> : () -> i32
    %43 = "nvvm.read.ptx.sreg.ntid.x"() <{range = #llvm.constant_range<i32, 1, 1024>}> : () -> i32
    %44 = "nvvm.read.ptx.sreg.ntid.y"() <{range = #llvm.constant_range<i32, 1, 1024>}> : () -> i32
    %45 = "llvm.mul"(%41, %43) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %46 = "llvm.add"(%40, %45) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %47 = "llvm.mul"(%42, %43) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %48 = "llvm.mul"(%47, %44) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %49 = "llvm.add"(%46, %48) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %50 = "llvm.sdiv"(%49, %18) : (i32, i32) -> i32
    %51 = "llvm.mul"(%50, %18) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %52 = "llvm.icmp"(%49, %51) <{predicate = 1 : i64}> : (i32, i32) -> i1
    %53 = "llvm.icmp"(%49, %21) <{predicate = 2 : i64}> : (i32, i32) -> i1
    %54 = "llvm.icmp"(%53, %17) <{predicate = 1 : i64}> : (i1, i1) -> i1
    %55 = "llvm.and"(%52, %54) : (i1, i1) -> i1
    %56 = "llvm.add"(%50, %16) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %57 = "llvm.select"(%55, %56, %50) <{fastmathFlags = #llvm.fastmath<none>}> : (i1, i32, i32) -> i32
    %58 = "nvvm.shfl.sync"(%16, %57, %21, %15) <{kind = #nvvm<shfl_kind idx>}> : (i32, i32, i32, i32) -> i32
    %59 = "nvvm.read.ptx.sreg.ctaid.x"() <{range = #llvm.constant_range<i32, 0, 2147483647>}> : () -> i32
    %60 = "nvvm.read.ptx.sreg.ctaid.y"() <{range = #llvm.constant_range<i32, 0, 65535>}> : () -> i32
    %61 = "llvm.getelementptr"(%14) <{elem_type = i8, rawConstantIndices = array<i32: 88>}> : (!llvm.ptr<3>) -> !llvm.ptr<3>
    %62 = "llvm.getelementptr"(%14) <{elem_type = i8, rawConstantIndices = array<i32: 64>}> : (!llvm.ptr<3>) -> !llvm.ptr<3>
    %63 = "llvm.getelementptr"(%14) <{elem_type = i8, rawConstantIndices = array<i32: 80>}> : (!llvm.ptr<3>) -> !llvm.ptr<3>
    %64 = "llvm.ptrtoint"(%61) : (!llvm.ptr<3>) -> i32
    %65 = "llvm.add"(%64, %35) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %66 = "llvm.and"(%65, %20) : (i32, i32) -> i32
    %67 = "llvm.sext"(%66) : (i32) -> i64
    %68 = "llvm.inttoptr"(%67) : (i64) -> !llvm.ptr<3>
    %69 = "llvm.getelementptr"(%68) <{elem_type = i8, rawConstantIndices = array<i32: 65536>}> : (!llvm.ptr<3>) -> !llvm.ptr<3>
    %70 = "llvm.icmp"(%58, %21) <{predicate = 0 : i64}> : (i32, i32) -> i1
    "llvm.cond_br"(%70)[^bb1, ^bb2] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb1:  // pred: ^bb0
    "nvvm.tcgen05.alloc"(%63, %22) <{group = #nvvm.tcgen05_group<cta_1>}> : (!llvm.ptr<3>, i32) -> ()
    "llvm.br"()[^bb2] : () -> ()
  ^bb2:  // 2 preds: ^bb0, ^bb1
    "llvm.cond_br"(%70)[^bb3, ^bb4] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb3:  // pred: ^bb2
    "llvm.br"()[^bb4] : () -> ()
  ^bb4:  // 2 preds: ^bb2, ^bb3
    "llvm.cond_br"(%70)[^bb5, ^bb6] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb5:  // pred: ^bb4
    "nvvm.mbarrier.init.shared"(%14, %37) : (!llvm.ptr<3>, i32) -> ()
    %71 = "llvm.getelementptr"(%14) <{elem_type = i64, rawConstantIndices = array<i32: 1>}> : (!llvm.ptr<3>) -> !llvm.ptr<3>
    "nvvm.mbarrier.init.shared"(%71, %37) : (!llvm.ptr<3>, i32) -> ()
    %72 = "llvm.getelementptr"(%14) <{elem_type = i64, rawConstantIndices = array<i32: 2>}> : (!llvm.ptr<3>) -> !llvm.ptr<3>
    "nvvm.mbarrier.init.shared"(%72, %37) : (!llvm.ptr<3>, i32) -> ()
    %73 = "llvm.getelementptr"(%14) <{elem_type = i64, rawConstantIndices = array<i32: 3>}> : (!llvm.ptr<3>) -> !llvm.ptr<3>
    "nvvm.mbarrier.init.shared"(%73, %37) : (!llvm.ptr<3>, i32) -> ()
    "llvm.br"()[^bb6] : () -> ()
  ^bb6:  // 2 preds: ^bb4, ^bb5
    %74 = "llvm.getelementptr"(%14) <{elem_type = i64, rawConstantIndices = array<i32: 4>}> : (!llvm.ptr<3>) -> !llvm.ptr<3>
    "llvm.cond_br"(%70)[^bb7, ^bb8] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb7:  // pred: ^bb6
    "nvvm.mbarrier.init.shared"(%74, %37) : (!llvm.ptr<3>, i32) -> ()
    %75 = "llvm.getelementptr"(%14) <{elem_type = i64, rawConstantIndices = array<i32: 5>}> : (!llvm.ptr<3>) -> !llvm.ptr<3>
    "nvvm.mbarrier.init.shared"(%75, %37) : (!llvm.ptr<3>, i32) -> ()
    %76 = "llvm.getelementptr"(%14) <{elem_type = i64, rawConstantIndices = array<i32: 6>}> : (!llvm.ptr<3>) -> !llvm.ptr<3>
    "nvvm.mbarrier.init.shared"(%76, %37) : (!llvm.ptr<3>, i32) -> ()
    %77 = "llvm.getelementptr"(%14) <{elem_type = i64, rawConstantIndices = array<i32: 7>}> : (!llvm.ptr<3>) -> !llvm.ptr<3>
    "nvvm.mbarrier.init.shared"(%77, %37) : (!llvm.ptr<3>, i32) -> ()
    "llvm.br"()[^bb8] : () -> ()
  ^bb8:  // 2 preds: ^bb6, ^bb7
    "llvm.inline_asm"(%21) <{asm_dialect = 0 : i64, asm_string = "fence.mbarrier_init.release.cluster;", constraints = "n", has_side_effects}> : (i32) -> ()
    "nvvm.barrier"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> ()
    "llvm.cond_br"(%70)[^bb9, ^bb10] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb9:  // pred: ^bb8
    "nvvm.mbarrier.init.shared"(%62, %37) : (!llvm.ptr<3>, i32) -> ()
    "llvm.br"()[^bb10] : () -> ()
  ^bb10:  // 2 preds: ^bb8, ^bb9
    %78 = "llvm.getelementptr"(%62) <{elem_type = i64, rawConstantIndices = array<i32: 1>}> : (!llvm.ptr<3>) -> !llvm.ptr<3>
    "llvm.cond_br"(%70)[^bb11, ^bb12] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb11:  // pred: ^bb10
    "nvvm.mbarrier.init.shared"(%78, %19) : (!llvm.ptr<3>, i32) -> ()
    "llvm.br"()[^bb12] : () -> ()
  ^bb12:  // 2 preds: ^bb10, ^bb11
    "llvm.inline_asm"(%21) <{asm_dialect = 0 : i64, asm_string = "fence.mbarrier_init.release.cluster;", constraints = "n", has_side_effects}> : (i32) -> ()
    "nvvm.barrier"() <{operandSegmentSizes = array<i32: 0, 0>}> : () -> ()
    %79 = "llvm.extractvalue"(%arg2) <{position = array<i64: 1>}> : (!llvm.struct<(struct<()>, struct<(struct<(i32, i32)>, struct<()>)>)>) -> !llvm.struct<(struct<(i32, i32)>, struct<()>)>
    %80 = "llvm.extractvalue"(%79) <{position = array<i64: 0, 0>}> : (!llvm.struct<(struct<(i32, i32)>, struct<()>)>) -> i32
    %81 = "llvm.extractvalue"(%79) <{position = array<i64: 0, 1>}> : (!llvm.struct<(struct<(i32, i32)>, struct<()>)>) -> i32
    %82 = "llvm.select"(%27, %16, %37) <{fastmathFlags = #llvm.fastmath<none>}> : (i1, i32, i32) -> i32
    %83 = "llvm.add"(%82, %80) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %84 = "llvm.sdiv"(%83, %19) : (i32, i32) -> i32
    %85 = "llvm.add"(%84, %37) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %86 = "llvm.sub"(%21, %80) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %87 = "llvm.sdiv"(%86, %19) : (i32, i32) -> i32
    %88 = "llvm.sub"(%21, %87) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %89 = "llvm.icmp"(%80, %21) <{predicate = 2 : i64}> : (i32, i32) -> i1
    %90 = "llvm.icmp"(%80, %21) <{predicate = 4 : i64}> : (i32, i32) -> i1
    %91 = "llvm.and"(%89, %17) : (i1, i1) -> i1
    %92 = "llvm.and"(%90, %27) : (i1, i1) -> i1
    %93 = "llvm.or"(%91, %92) : (i1, i1) -> i1
    %94 = "llvm.select"(%93, %85, %88) <{fastmathFlags = #llvm.fastmath<none>}> : (i1, i32, i32) -> i32
    %95 = "llvm.add"(%82, %81) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %96 = "llvm.sdiv"(%95, %36) : (i32, i32) -> i32
    %97 = "llvm.add"(%96, %37) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %98 = "llvm.sub"(%21, %81) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %99 = "llvm.sdiv"(%98, %36) : (i32, i32) -> i32
    %100 = "llvm.sub"(%21, %99) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %101 = "llvm.icmp"(%81, %21) <{predicate = 2 : i64}> : (i32, i32) -> i1
    %102 = "llvm.icmp"(%81, %21) <{predicate = 4 : i64}> : (i32, i32) -> i1
    %103 = "llvm.and"(%101, %17) : (i1, i1) -> i1
    %104 = "llvm.and"(%102, %27) : (i1, i1) -> i1
    %105 = "llvm.or"(%103, %104) : (i1, i1) -> i1
    %106 = "llvm.select"(%105, %97, %100) <{fastmathFlags = #llvm.fastmath<none>}> : (i1, i32, i32) -> i32
    %107 = "llvm.insertvalue"(%12, %94) <{position = array<i64: 0>}> : (!llvm.struct<(i32, i32)>, i32) -> !llvm.struct<(i32, i32)>
    %108 = "llvm.insertvalue"(%107, %106) <{position = array<i64: 1>}> : (!llvm.struct<(i32, i32)>, i32) -> !llvm.struct<(i32, i32)>
    %109 = "llvm.insertvalue"(%11, %108) <{position = array<i64: 0>}> : (!llvm.struct<(struct<(i32, i32)>, struct<()>)>, !llvm.struct<(i32, i32)>) -> !llvm.struct<(struct<(i32, i32)>, struct<()>)>
    %110 = "llvm.extractvalue"(%109) <{position = array<i64: 0, 1>}> : (!llvm.struct<(struct<(i32, i32)>, struct<()>)>) -> i32
    %111 = "llvm.mul"(%59, %19) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %112 = "llvm.mul"(%60, %23) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %113 = "llvm.extractvalue"(%arg5) <{position = array<i64: 1>}> : (!llvm.struct<(ptr<1>, struct<(struct<(i32, i32)>, i64)>)>) -> !llvm.struct<(struct<(i32, i32)>, i64)>
    %114 = "llvm.extractvalue"(%113) <{position = array<i64: 0, 0>}> : (!llvm.struct<(struct<(i32, i32)>, i64)>) -> i32
    %115 = "llvm.extractvalue"(%113) <{position = array<i64: 0, 1>}> : (!llvm.struct<(struct<(i32, i32)>, i64)>) -> i32
    %116 = "llvm.extractvalue"(%113) <{position = array<i64: 1>}> : (!llvm.struct<(struct<(i32, i32)>, i64)>) -> i64
    %117 = "llvm.add"(%82, %114) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %118 = "llvm.sdiv"(%117, %19) : (i32, i32) -> i32
    %119 = "llvm.add"(%118, %37) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %120 = "llvm.sub"(%21, %114) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %121 = "llvm.sdiv"(%120, %19) : (i32, i32) -> i32
    %122 = "llvm.sub"(%21, %121) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %123 = "llvm.icmp"(%114, %21) <{predicate = 2 : i64}> : (i32, i32) -> i1
    %124 = "llvm.icmp"(%114, %21) <{predicate = 4 : i64}> : (i32, i32) -> i1
    %125 = "llvm.and"(%123, %17) : (i1, i1) -> i1
    %126 = "llvm.and"(%124, %27) : (i1, i1) -> i1
    %127 = "llvm.or"(%125, %126) : (i1, i1) -> i1
    %128 = "llvm.select"(%127, %119, %122) <{fastmathFlags = #llvm.fastmath<none>}> : (i1, i32, i32) -> i32
    %129 = "llvm.mul"(%116, %24) <{overflowFlags = #llvm.overflow<none>}> : (i64, i64) -> i64
    %130 = "llvm.add"(%82, %115) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %131 = "llvm.sdiv"(%130, %23) : (i32, i32) -> i32
    %132 = "llvm.add"(%131, %37) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %133 = "llvm.sub"(%21, %115) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %134 = "llvm.sdiv"(%133, %23) : (i32, i32) -> i32
    %135 = "llvm.sub"(%21, %134) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %136 = "llvm.icmp"(%115, %21) <{predicate = 2 : i64}> : (i32, i32) -> i1
    %137 = "llvm.icmp"(%115, %21) <{predicate = 4 : i64}> : (i32, i32) -> i1
    %138 = "llvm.and"(%136, %17) : (i1, i1) -> i1
    %139 = "llvm.and"(%137, %27) : (i1, i1) -> i1
    %140 = "llvm.or"(%138, %139) : (i1, i1) -> i1
    %141 = "llvm.select"(%140, %132, %135) <{fastmathFlags = #llvm.fastmath<none>}> : (i1, i32, i32) -> i32
    %142 = "llvm.insertvalue"(%12, %128) <{position = array<i64: 0>}> : (!llvm.struct<(i32, i32)>, i32) -> !llvm.struct<(i32, i32)>
    %143 = "llvm.insertvalue"(%142, %141) <{position = array<i64: 1>}> : (!llvm.struct<(i32, i32)>, i32) -> !llvm.struct<(i32, i32)>
    %144 = "llvm.insertvalue"(%10, %116) <{position = array<i64: 0>}> : (!llvm.struct<(i64, i64)>, i64) -> !llvm.struct<(i64, i64)>
    %145 = "llvm.insertvalue"(%144, %129) <{position = array<i64: 1>}> : (!llvm.struct<(i64, i64)>, i64) -> !llvm.struct<(i64, i64)>
    %146 = "llvm.insertvalue"(%9, %143) <{position = array<i64: 0>}> : (!llvm.struct<(struct<(i32, i32)>, struct<(i64, i64)>)>, !llvm.struct<(i32, i32)>) -> !llvm.struct<(struct<(i32, i32)>, struct<(i64, i64)>)>
    %147 = "llvm.insertvalue"(%146, %145) <{position = array<i64: 1>}> : (!llvm.struct<(struct<(i32, i32)>, struct<(i64, i64)>)>, !llvm.struct<(i64, i64)>) -> !llvm.struct<(struct<(i32, i32)>, struct<(i64, i64)>)>
    %148 = "llvm.extractvalue"(%147) <{position = array<i64: 1, 0>}> : (!llvm.struct<(struct<(i32, i32)>, struct<(i64, i64)>)>) -> i64
    %149 = "llvm.sext"(%59) : (i32) -> i64
    %150 = "llvm.mul"(%149, %129) <{overflowFlags = #llvm.overflow<none>}> : (i64, i64) -> i64
    %151 = "llvm.sext"(%112) : (i32) -> i64
    %152 = "llvm.add"(%150, %151) <{overflowFlags = #llvm.overflow<none>}> : (i64, i64) -> i64
    %153 = "llvm.extractvalue"(%arg5) <{position = array<i64: 0>}> : (!llvm.struct<(ptr<1>, struct<(struct<(i32, i32)>, i64)>)>) -> !llvm.ptr<1>
    %154 = "llvm.getelementptr"(%153, %152) <{elem_type = f16, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>
    %155 = "llvm.ptrtoint"(%68) : (!llvm.ptr<3>) -> i32
    %156 = "llvm.lshr"(%155, %29) : (i32, i32) -> i32
    %157 = "nvvm.mma_smem_desc"(%156, %37, %36, %7, %8) <{mmaDescVersion = 1 : i32}> : (i32, i32, i32, i8, i8) -> i64
    %158 = "llvm.ptrtoint"(%69) : (!llvm.ptr<3>) -> i32
    %159 = "llvm.lshr"(%158, %29) : (i32, i32) -> i32
    %160 = "nvvm.mma_smem_desc"(%159, %37, %36, %7, %8) <{mmaDescVersion = 1 : i32}> : (i32, i32, i32, i8, i8) -> i64
    "llvm.inline_asm"(%37, %19) <{asm_dialect = 0 : i64, asm_string = "bar.sync $0, $1;", constraints = "r,r", has_side_effects}> : (i32, i32) -> ()
    %161 = "llvm.load"(%63) <{ordering = 0 : i64}> : (!llvm.ptr<3>) -> i32
    %162 = "llvm.sdiv"(%40, %18) : (i32, i32) -> i32
    %163 = "llvm.mul"(%162, %25) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %164 = "llvm.add"(%161, %163) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %165 = "llvm.mul"(%148, %26) <{overflowFlags = #llvm.overflow<none>}> : (i64, i64) -> i64
    %166 = "llvm.srem"(%40, %18) : (i32, i32) -> i32
    %167 = "llvm.sext"(%166) : (i32) -> i64
    %168 = "llvm.mul"(%167, %148) <{overflowFlags = #llvm.overflow<none>}> : (i64, i64) -> i64
    %169 = "llvm.sext"(%162) : (i32) -> i64
    %170 = "llvm.mul"(%169, %165) <{overflowFlags = #llvm.overflow<none>}> : (i64, i64) -> i64
    %171 = "llvm.add"(%168, %170) <{overflowFlags = #llvm.overflow<none>}> : (i64, i64) -> i64
    %172 = "llvm.getelementptr"(%154, %171) <{elem_type = f16, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<1>, i64) -> !llvm.ptr<1>
    "llvm.cond_br"(%70)[^bb13, ^bb59] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb13:  // pred: ^bb12
    "llvm.inline_asm"(%78, %37, %28) <{asm_dialect = 0 : i64, asm_string = "{\0A\09.reg .pred       P1; \0A\09LAB_WAIT: \0A\09mbarrier.try_wait.parity.shared.b64 P1, [$0], $1, $2; \0A\09@P1 bra.uni DONE; \0A\09bra.uni     LAB_WAIT; \0A\09DONE: \0A\09}", constraints = "r,n,n", has_side_effects}> : (!llvm.ptr<3>, i32, i32) -> ()
    %173 = "llvm.getelementptr"(%arg1) <{elem_type = !llvm.struct<(struct<(array<16 x i64>)>)>, rawConstantIndices = array<i32: 0, 0>}> : (!llvm.ptr) -> !llvm.ptr
    %174 = "llvm.getelementptr"(%arg3) <{elem_type = !llvm.struct<(struct<(array<16 x i64>)>)>, rawConstantIndices = array<i32: 0, 0>}> : (!llvm.ptr) -> !llvm.ptr
    %175 = "llvm.icmp"(%110, %30) <{predicate = 2 : i64}> : (i32, i32) -> i1
    %176 = "llvm.select"(%175, %110, %30) <{fastmathFlags = #llvm.fastmath<none>}> : (i1, i32, i32) -> i32
    %177 = "llvm.extractvalue"(%6) <{position = array<i64: 3>}> : (!llvm.struct<(ptr, ptr<3>, i16, i64, struct<()>)>) -> i64
    "llvm.br"(%21, %21, %37, %21)[^bb14] : (i32, i32, i32, i32) -> ()
  ^bb14(%178: i32, %179: i32, %180: i32, %181: i32):  // 2 preds: ^bb13, ^bb25
    %182 = "llvm.icmp"(%178, %176) <{predicate = 2 : i64}> : (i32, i32) -> i1
    "llvm.cond_br"(%182)[^bb15, ^bb26] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb15:  // pred: ^bb14
    %183 = "llvm.getelementptr"(%74, %179) <{elem_type = i64, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>
    "llvm.inline_asm"(%183, %180, %28) <{asm_dialect = 0 : i64, asm_string = "{\0A\09.reg .pred       P1; \0A\09LAB_WAIT: \0A\09mbarrier.try_wait.parity.shared.b64 P1, [$0], $1, $2; \0A\09@P1 bra.uni DONE; \0A\09bra.uni     LAB_WAIT; \0A\09DONE: \0A\09}", constraints = "r,r,n", has_side_effects}> : (!llvm.ptr<3>, i32, i32) -> ()
    %184 = "nvvm.elect.sync"() : () -> i1
    "llvm.cond_br"(%184)[^bb16, ^bb17] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb16:  // pred: ^bb15
    %185 = "llvm.getelementptr"(%14, %179) <{elem_type = i64, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>
    "nvvm.mbarrier.txn"(%185, %31) <{kind = #nvvm.mbar_txn_kind<arrive_expect_tx>, scope = #nvvm.mbar_scope<cta>, space = #nvvm.mbar_space<cta>}> : (!llvm.ptr<3>, i32) -> ()
    "llvm.br"()[^bb17] : () -> ()
  ^bb17:  // 2 preds: ^bb15, ^bb16
    %186 = "llvm.add"(%179, %37) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %187 = "llvm.add"(%181, %37) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %188 = "llvm.icmp"(%186, %29) <{predicate = 0 : i64}> : (i32, i32) -> i1
    %189 = "llvm.select"(%188, %21, %186) <{fastmathFlags = #llvm.fastmath<none>}> : (i1, i32, i32) -> i32
    "llvm.cond_br"(%188)[^bb18, ^bb19] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb18:  // pred: ^bb17
    %190 = "llvm.xor"(%180, %37) : (i32, i32) -> i32
    "llvm.br"(%190)[^bb20] : (i32) -> ()
  ^bb19:  // pred: ^bb17
    "llvm.br"(%180)[^bb20] : (i32) -> ()
  ^bb20(%191: i32):  // 2 preds: ^bb18, ^bb19
    "llvm.br"()[^bb21] : () -> ()
  ^bb21:  // pred: ^bb20
    %192 = "llvm.mul"(%181, %36) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %193 = "llvm.mul"(%179, %5) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %194 = "llvm.getelementptr"(%68, %193) <{elem_type = f16, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>
    %195 = "llvm.getelementptr"(%14, %179) <{elem_type = i64, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>
    %196 = "nvvm.elect.sync"() : () -> i1
    "llvm.cond_br"(%196)[^bb22, ^bb23] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb22:  // pred: ^bb21
    "nvvm.cp.async.bulk.tensor.shared.cluster.global"(%194, %173, %192, %111, %195, %177) <{group = #nvvm.tcgen05_group<cta_1>, loadMode = #nvvm.load_mode<tile>, operandSegmentSizes = array<i32: 1, 1, 2, 1, 0, 0, 0, 0, 1, 0>, useIntrinsic = true}> : (!llvm.ptr<3>, !llvm.ptr, i32, i32, !llvm.ptr<3>, i64) -> ()
    "llvm.br"()[^bb23] : () -> ()
  ^bb23:  // 2 preds: ^bb21, ^bb22
    %197 = "llvm.mul"(%179, %4) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %198 = "llvm.getelementptr"(%69, %197) <{elem_type = f16, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>
    %199 = "nvvm.elect.sync"() : () -> i1
    "llvm.cond_br"(%199)[^bb24, ^bb25] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb24:  // pred: ^bb23
    "nvvm.cp.async.bulk.tensor.shared.cluster.global"(%198, %174, %192, %112, %195, %177) <{group = #nvvm.tcgen05_group<cta_1>, loadMode = #nvvm.load_mode<tile>, operandSegmentSizes = array<i32: 1, 1, 2, 1, 0, 0, 0, 0, 1, 0>, useIntrinsic = true}> : (!llvm.ptr<3>, !llvm.ptr, i32, i32, !llvm.ptr<3>, i64) -> ()
    "llvm.br"()[^bb25] : () -> ()
  ^bb25:  // 2 preds: ^bb23, ^bb24
    %200 = "llvm.add"(%178, %37) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    "llvm.br"(%200, %189, %191, %187)[^bb14] : (i32, i32, i32, i32) -> ()
  ^bb26:  // pred: ^bb14
    "llvm.br"(%21, %181, %179, %180, %21, %21, %arg0)[^bb27] : (i32, i32, i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>) -> ()
  ^bb27(%201: i32, %202: i32, %203: i32, %204: i32, %205: i32, %206: i32, %207: !llvm.struct<(i1, i1, i1)>):  // 2 preds: ^bb26, ^bb55
    %208 = "llvm.icmp"(%201, %110) <{predicate = 2 : i64}> : (i32, i32) -> i1
    "llvm.cond_br"(%208)[^bb28, ^bb56] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb28:  // pred: ^bb27
    %209 = "llvm.add"(%201, %176) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %210 = "llvm.icmp"(%209, %110) <{predicate = 6 : i64}> : (i32, i32) -> i1
    "llvm.cond_br"(%210, %203, %204, %202)[^bb29, ^bb39] <{operandSegmentSizes = array<i32: 1, 0, 3>}> : (i1, i32, i32, i32) -> ()
  ^bb29:  // pred: ^bb28
    %211 = "llvm.getelementptr"(%74, %203) <{elem_type = i64, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>
    "llvm.inline_asm"(%211, %204, %28) <{asm_dialect = 0 : i64, asm_string = "{\0A\09.reg .pred       P1; \0A\09LAB_WAIT: \0A\09mbarrier.try_wait.parity.shared.b64 P1, [$0], $1, $2; \0A\09@P1 bra.uni DONE; \0A\09bra.uni     LAB_WAIT; \0A\09DONE: \0A\09}", constraints = "r,r,n", has_side_effects}> : (!llvm.ptr<3>, i32, i32) -> ()
    %212 = "nvvm.elect.sync"() : () -> i1
    "llvm.cond_br"(%212)[^bb30, ^bb31] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb30:  // pred: ^bb29
    %213 = "llvm.getelementptr"(%14, %203) <{elem_type = i64, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>
    "nvvm.mbarrier.txn"(%213, %31) <{kind = #nvvm.mbar_txn_kind<arrive_expect_tx>, scope = #nvvm.mbar_scope<cta>, space = #nvvm.mbar_space<cta>}> : (!llvm.ptr<3>, i32) -> ()
    "llvm.br"()[^bb31] : () -> ()
  ^bb31:  // 2 preds: ^bb29, ^bb30
    %214 = "llvm.add"(%203, %37) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %215 = "llvm.add"(%202, %37) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %216 = "llvm.icmp"(%214, %29) <{predicate = 0 : i64}> : (i32, i32) -> i1
    %217 = "llvm.select"(%216, %21, %214) <{fastmathFlags = #llvm.fastmath<none>}> : (i1, i32, i32) -> i32
    "llvm.cond_br"(%216)[^bb32, ^bb33] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb32:  // pred: ^bb31
    %218 = "llvm.xor"(%204, %37) : (i32, i32) -> i32
    "llvm.br"(%218)[^bb34] : (i32) -> ()
  ^bb33:  // pred: ^bb31
    "llvm.br"(%204)[^bb34] : (i32) -> ()
  ^bb34(%219: i32):  // 2 preds: ^bb32, ^bb33
    "llvm.br"()[^bb35] : () -> ()
  ^bb35:  // pred: ^bb34
    %220 = "llvm.mul"(%202, %36) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %221 = "llvm.mul"(%203, %5) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %222 = "llvm.getelementptr"(%68, %221) <{elem_type = f16, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>
    %223 = "llvm.getelementptr"(%14, %203) <{elem_type = i64, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>
    %224 = "nvvm.elect.sync"() : () -> i1
    "llvm.cond_br"(%224)[^bb36, ^bb37] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb36:  // pred: ^bb35
    "nvvm.cp.async.bulk.tensor.shared.cluster.global"(%222, %173, %220, %111, %223, %177) <{group = #nvvm.tcgen05_group<cta_1>, loadMode = #nvvm.load_mode<tile>, operandSegmentSizes = array<i32: 1, 1, 2, 1, 0, 0, 0, 0, 1, 0>, useIntrinsic = true}> : (!llvm.ptr<3>, !llvm.ptr, i32, i32, !llvm.ptr<3>, i64) -> ()
    "llvm.br"()[^bb37] : () -> ()
  ^bb37:  // 2 preds: ^bb35, ^bb36
    %225 = "llvm.mul"(%203, %4) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %226 = "llvm.getelementptr"(%69, %225) <{elem_type = f16, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>
    %227 = "nvvm.elect.sync"() : () -> i1
    "llvm.cond_br"(%227, %217, %219, %215)[^bb38, ^bb39] <{operandSegmentSizes = array<i32: 1, 0, 3>}> : (i1, i32, i32, i32) -> ()
  ^bb38:  // pred: ^bb37
    "nvvm.cp.async.bulk.tensor.shared.cluster.global"(%226, %174, %220, %112, %223, %177) <{group = #nvvm.tcgen05_group<cta_1>, loadMode = #nvvm.load_mode<tile>, operandSegmentSizes = array<i32: 1, 1, 2, 1, 0, 0, 0, 0, 1, 0>, useIntrinsic = true}> : (!llvm.ptr<3>, !llvm.ptr, i32, i32, !llvm.ptr<3>, i64) -> ()
    "llvm.br"(%217, %219, %215)[^bb39] : (i32, i32, i32) -> ()
  ^bb39(%228: i32, %229: i32, %230: i32):  // 3 preds: ^bb28, ^bb37, ^bb38
    "llvm.br"()[^bb40] : () -> ()
  ^bb40:  // pred: ^bb39
    "llvm.br"()[^bb41] : () -> ()
  ^bb41:  // pred: ^bb40
    %231 = "llvm.getelementptr"(%14, %205) <{elem_type = i64, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>
    "llvm.inline_asm"(%231, %206, %28) <{asm_dialect = 0 : i64, asm_string = "{\0A\09.reg .pred       P1; \0A\09LAB_WAIT: \0A\09mbarrier.try_wait.parity.shared.b64 P1, [$0], $1, $2; \0A\09@P1 bra.uni DONE; \0A\09bra.uni     LAB_WAIT; \0A\09DONE: \0A\09}", constraints = "r,r,n", has_side_effects}> : (!llvm.ptr<3>, i32, i32) -> ()
    %232 = "llvm.add"(%205, %37) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %233 = "llvm.icmp"(%232, %29) <{predicate = 0 : i64}> : (i32, i32) -> i1
    %234 = "llvm.select"(%233, %21, %232) <{fastmathFlags = #llvm.fastmath<none>}> : (i1, i32, i32) -> i32
    "llvm.cond_br"(%233)[^bb42, ^bb43] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb42:  // pred: ^bb41
    %235 = "llvm.xor"(%206, %37) : (i32, i32) -> i32
    "llvm.br"(%235)[^bb44] : (i32) -> ()
  ^bb43:  // pred: ^bb41
    "llvm.br"(%206)[^bb44] : (i32) -> ()
  ^bb44(%236: i32):  // 2 preds: ^bb42, ^bb43
    "llvm.br"()[^bb45] : () -> ()
  ^bb45:  // pred: ^bb44
    %237 = "llvm.mul"(%205, %3) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %238 = "llvm.bitcast"(%157) : (i64) -> vector<2xi32>
    %239 = "llvm.extractelement"(%238, %21) : (vector<2xi32>, i32) -> i32
    %240 = "llvm.add"(%239, %237) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %241 = "llvm.insertelement"(%238, %240, %21) : (vector<2xi32>, i32, i32) -> vector<2xi32>
    %242 = "llvm.bitcast"(%241) : (vector<2xi32>) -> i64
    %243 = "llvm.mul"(%205, %2) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %244 = "llvm.bitcast"(%160) : (i64) -> vector<2xi32>
    %245 = "llvm.extractelement"(%244, %21) : (vector<2xi32>, i32) -> i32
    %246 = "llvm.add"(%245, %243) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %247 = "llvm.insertelement"(%244, %246, %21) : (vector<2xi32>, i32, i32) -> vector<2xi32>
    %248 = "llvm.bitcast"(%247) : (vector<2xi32>) -> i64
    %249 = "llvm.extractvalue"(%207) <{position = array<i64: 1>}> : (!llvm.struct<(i1, i1, i1)>) -> i1
    %250 = "llvm.extractvalue"(%207) <{position = array<i64: 2>}> : (!llvm.struct<(i1, i1, i1)>) -> i1
    %251 = "llvm.extractvalue"(%207) <{position = array<i64: 0>}> : (!llvm.struct<(i1, i1, i1)>) -> i1
    %252 = "llvm.zext"(%249) : (i1) -> i32
    %253 = "llvm.zext"(%250) : (i1) -> i32
    %254 = "llvm.shl"(%252, %33) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %255 = "llvm.shl"(%253, %34) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %256 = "llvm.or"(%254, %32) : (i32, i32) -> i32
    %257 = "llvm.or"(%256, %255) : (i32, i32) -> i32
    %258 = "llvm.inttoptr"(%161) : (i32) -> !llvm.ptr<6>
    %259 = "nvvm.elect.sync"() : () -> i1
    "llvm.cond_br"(%259)[^bb46, ^bb47] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb46:  // pred: ^bb45
    "nvvm.tcgen05.mma"(%258, %242, %248, %257, %251, %1) <{collectorOp = #nvvm.tcgen05_mma_collectorop<discard>, ctaGroup = #nvvm.tcgen05_group<cta_1>, mmaKind = #nvvm.tcgen05_mma_kind<f16>, operandSegmentSizes = array<i32: 1, 1, 1, 1, 1, 0, 1>}> : (!llvm.ptr<6>, i64, i64, i32, i1, vector<4xi32>) -> ()
    "llvm.br"()[^bb47] : () -> ()
  ^bb47:  // 2 preds: ^bb45, ^bb46
    %260 = "llvm.insertvalue"(%207, %27) <{position = array<i64: 0>}> : (!llvm.struct<(i1, i1, i1)>, i1) -> !llvm.struct<(i1, i1, i1)>
    %261 = "llvm.add"(%237, %30) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %262 = "llvm.add"(%239, %261) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %263 = "llvm.insertelement"(%238, %262, %21) : (vector<2xi32>, i32, i32) -> vector<2xi32>
    %264 = "llvm.bitcast"(%263) : (vector<2xi32>) -> i64
    %265 = "llvm.add"(%243, %30) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %266 = "llvm.add"(%245, %265) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %267 = "llvm.insertelement"(%244, %266, %21) : (vector<2xi32>, i32, i32) -> vector<2xi32>
    %268 = "llvm.bitcast"(%267) : (vector<2xi32>) -> i64
    %269 = "nvvm.elect.sync"() : () -> i1
    "llvm.cond_br"(%269)[^bb48, ^bb49] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb48:  // pred: ^bb47
    "nvvm.tcgen05.mma"(%258, %264, %268, %257, %27, %1) <{collectorOp = #nvvm.tcgen05_mma_collectorop<discard>, ctaGroup = #nvvm.tcgen05_group<cta_1>, mmaKind = #nvvm.tcgen05_mma_kind<f16>, operandSegmentSizes = array<i32: 1, 1, 1, 1, 1, 0, 1>}> : (!llvm.ptr<6>, i64, i64, i32, i1, vector<4xi32>) -> ()
    "llvm.br"()[^bb49] : () -> ()
  ^bb49:  // 2 preds: ^bb47, ^bb48
    %270 = "llvm.insertvalue"(%260, %27) <{position = array<i64: 0>}> : (!llvm.struct<(i1, i1, i1)>, i1) -> !llvm.struct<(i1, i1, i1)>
    %271 = "llvm.add"(%237, %29) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %272 = "llvm.add"(%239, %271) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %273 = "llvm.insertelement"(%238, %272, %21) : (vector<2xi32>, i32, i32) -> vector<2xi32>
    %274 = "llvm.bitcast"(%273) : (vector<2xi32>) -> i64
    %275 = "llvm.add"(%243, %29) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %276 = "llvm.add"(%245, %275) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %277 = "llvm.insertelement"(%244, %276, %21) : (vector<2xi32>, i32, i32) -> vector<2xi32>
    %278 = "llvm.bitcast"(%277) : (vector<2xi32>) -> i64
    %279 = "nvvm.elect.sync"() : () -> i1
    "llvm.cond_br"(%279)[^bb50, ^bb51] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb50:  // pred: ^bb49
    "nvvm.tcgen05.mma"(%258, %274, %278, %257, %27, %1) <{collectorOp = #nvvm.tcgen05_mma_collectorop<discard>, ctaGroup = #nvvm.tcgen05_group<cta_1>, mmaKind = #nvvm.tcgen05_mma_kind<f16>, operandSegmentSizes = array<i32: 1, 1, 1, 1, 1, 0, 1>}> : (!llvm.ptr<6>, i64, i64, i32, i1, vector<4xi32>) -> ()
    "llvm.br"()[^bb51] : () -> ()
  ^bb51:  // 2 preds: ^bb49, ^bb50
    %280 = "llvm.insertvalue"(%270, %27) <{position = array<i64: 0>}> : (!llvm.struct<(i1, i1, i1)>, i1) -> !llvm.struct<(i1, i1, i1)>
    %281 = "llvm.add"(%237, %13) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %282 = "llvm.add"(%239, %281) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %283 = "llvm.insertelement"(%238, %282, %21) : (vector<2xi32>, i32, i32) -> vector<2xi32>
    %284 = "llvm.bitcast"(%283) : (vector<2xi32>) -> i64
    %285 = "llvm.add"(%243, %13) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %286 = "llvm.add"(%245, %285) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %287 = "llvm.insertelement"(%244, %286, %21) : (vector<2xi32>, i32, i32) -> vector<2xi32>
    %288 = "llvm.bitcast"(%287) : (vector<2xi32>) -> i64
    %289 = "nvvm.elect.sync"() : () -> i1
    "llvm.cond_br"(%289)[^bb52, ^bb53] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb52:  // pred: ^bb51
    "nvvm.tcgen05.mma"(%258, %284, %288, %257, %27, %1) <{collectorOp = #nvvm.tcgen05_mma_collectorop<discard>, ctaGroup = #nvvm.tcgen05_group<cta_1>, mmaKind = #nvvm.tcgen05_mma_kind<f16>, operandSegmentSizes = array<i32: 1, 1, 1, 1, 1, 0, 1>}> : (!llvm.ptr<6>, i64, i64, i32, i1, vector<4xi32>) -> ()
    "llvm.br"()[^bb53] : () -> ()
  ^bb53:  // 2 preds: ^bb51, ^bb52
    %290 = "llvm.insertvalue"(%280, %27) <{position = array<i64: 0>}> : (!llvm.struct<(i1, i1, i1)>, i1) -> !llvm.struct<(i1, i1, i1)>
    %291 = "nvvm.elect.sync"() : () -> i1
    "llvm.cond_br"(%291)[^bb54, ^bb55] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb54:  // pred: ^bb53
    %292 = "llvm.getelementptr"(%74, %205) <{elem_type = i64, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<3>, i32) -> !llvm.ptr<3>
    "nvvm.tcgen05.commit.arrive"(%292) <{group = #nvvm.tcgen05_group<cta_1>}> : (!llvm.ptr<3>) -> ()
    "llvm.br"()[^bb55] : () -> ()
  ^bb55:  // 2 preds: ^bb53, ^bb54
    %293 = "llvm.add"(%201, %37) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    "llvm.br"(%293, %230, %228, %229, %234, %236, %290)[^bb27] : (i32, i32, i32, i32, i32, i32, !llvm.struct<(i1, i1, i1)>) -> ()
  ^bb56:  // pred: ^bb27
    %294 = "nvvm.elect.sync"() : () -> i1
    "llvm.cond_br"(%294)[^bb57, ^bb58] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb57:  // pred: ^bb56
    "nvvm.tcgen05.commit.arrive"(%62) <{group = #nvvm.tcgen05_group<cta_1>}> : (!llvm.ptr<3>) -> ()
    "llvm.br"()[^bb58] : () -> ()
  ^bb58:  // 2 preds: ^bb56, ^bb57
    "llvm.br"()[^bb59] : () -> ()
  ^bb59:  // 2 preds: ^bb12, ^bb58
    "llvm.cond_br"(%70)[^bb60, ^bb61] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb60:  // pred: ^bb59
    "nvvm.tcgen05.relinquish_alloc_permit"() <{group = #nvvm.tcgen05_group<cta_1>}> : () -> ()
    "llvm.br"()[^bb61] : () -> ()
  ^bb61:  // 2 preds: ^bb59, ^bb60
    "llvm.inline_asm"(%62, %21, %28) <{asm_dialect = 0 : i64, asm_string = "{\0A\09.reg .pred       P1; \0A\09LAB_WAIT: \0A\09mbarrier.try_wait.parity.shared.b64 P1, [$0], $1, $2; \0A\09@P1 bra.uni DONE; \0A\09bra.uni     LAB_WAIT; \0A\09DONE: \0A\09}", constraints = "r,n,n", has_side_effects}> : (!llvm.ptr<3>, i32, i32) -> ()
    "llvm.br"(%21)[^bb62] : (i32) -> ()
  ^bb62(%295: i32):  // 2 preds: ^bb61, ^bb66
    %296 = "llvm.icmp"(%295, %29) <{predicate = 2 : i64}> : (i32, i32) -> i1
    "llvm.cond_br"(%296)[^bb63, ^bb67] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb63:  // pred: ^bb62
    %297 = "llvm.srem"(%295, %29) : (i32, i32) -> i32
    %298 = "llvm.mul"(%297, %36) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %299 = "llvm.add"(%164, %298) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %300 = "llvm.inttoptr"(%299) : (i32) -> !llvm.ptr<6>
    %301 = "nvvm.tcgen05.ld"(%300) <{num = 64 : i32, pack = false, shape = #nvvm.tcgen05_ldst_shape<shape_32x32b>}> : (!llvm.ptr<6>) -> vector<64xi32>
    "llvm.store"(%301, %39) <{ordering = 0 : i64}> : (vector<64xi32>, !llvm.ptr) -> ()
    %302 = "llvm.load"(%39) <{alignment = 32 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<64xf32>
    %303 = "llvm.fptrunc"(%302) : (vector<64xf32>) -> vector<64xf16>
    "llvm.store"(%303, %38) <{alignment = 32 : i64, ordering = 0 : i64}> : (vector<64xf16>, !llvm.ptr) -> ()
    %304 = "llvm.getelementptr"(%172, %298) <{elem_type = f16, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>
    "llvm.br"(%21)[^bb64] : (i32) -> ()
  ^bb64(%305: i32):  // 2 preds: ^bb63, ^bb65
    %306 = "llvm.icmp"(%305, %29) <{predicate = 2 : i64}> : (i32, i32) -> i1
    "llvm.cond_br"(%306)[^bb65, ^bb66] <{operandSegmentSizes = array<i32: 1, 0, 0>}> {llvm.loop_annotation = #llvm.loop_annotation<unroll = <disable = false, full = true>>} : (i1) -> ()
  ^bb65:  // pred: ^bb64
    %307 = "llvm.mul"(%305, %0) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    %308 = "llvm.getelementptr"(%38, %307) <{elem_type = f16, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr, i32) -> !llvm.ptr
    %309 = "llvm.getelementptr"(%304, %307) <{elem_type = f16, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>
    %310 = "llvm.load"(%308) <{alignment = 32 : i64, ordering = 0 : i64}> : (!llvm.ptr) -> vector<16xf16>
    "llvm.store"(%310, %309) <{alignment = 32 : i64, ordering = 0 : i64}> : (vector<16xf16>, !llvm.ptr<1>) -> ()
    %311 = "llvm.add"(%305, %37) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    "llvm.br"(%311)[^bb64] : (i32) -> ()
  ^bb66:  // pred: ^bb64
    %312 = "llvm.add"(%295, %37) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    "llvm.br"(%312)[^bb62] : (i32) -> ()
  ^bb67:  // pred: ^bb62
    "nvvm.mbarrier.txn"(%78, %37) <{kind = #nvvm.mbar_txn_kind<arrive>, scope = #nvvm.mbar_scope<cta>, space = #nvvm.mbar_space<cta>}> : (!llvm.ptr<3>, i32) -> ()
    "llvm.inline_asm"(%37) <{asm_dialect = 0 : i64, asm_string = "bar.sync $0;", constraints = "r", has_side_effects}> : (i32) -> ()
    "llvm.cond_br"(%70)[^bb68, ^bb69] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb68:  // pred: ^bb67
    %313 = "llvm.inttoptr"(%161) : (i32) -> !llvm.ptr<6>
    "nvvm.tcgen05.dealloc"(%313, %22) <{group = #nvvm.tcgen05_group<cta_1>}> : (!llvm.ptr<6>, i32) -> ()
    "llvm.br"()[^bb69] : () -> ()
  ^bb69:  // 2 preds: ^bb67, ^bb68
    "llvm.return"() : () -> ()
  }) {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, gpu.kernel, nvvm.kernel, nvvm.reqntid = array<i32: 128, 1, 1>} : () -> ()
}) {compute_targets = [#cuda.compute_target<sass, conditional, [sm_100]>]} : () -> ()
