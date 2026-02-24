"builtin.module"() ({
  "llvm.func"() <{CConv = #llvm.cconv<ccc>, function_type = !llvm.func<i32 (ptr, ...)>, linkage = #llvm.linkage<external>, sym_name = "printf", visibility_ = 0 : i64}> ({
  }) : () -> ()
  "llvm.mlir.global"() <{addr_space = 0 : i32, constant, global_type = !llvm.array<4 x i8>, linkage = #llvm.linkage<internal>, sym_name = "%s\0A", value = "%s\0A\00", visibility_ = 0 : i64}> ({
  }) : () -> ()
  "llvm.mlir.global"() <{addr_space = 0 : i32, constant, global_type = !llvm.array<72 x i8>, linkage = #llvm.linkage<internal>, sym_name = "ERROR: Reached max number of attributes, unable to add more attributes.", value = "ERROR: Reached max number of attributes, unable to add more attributes.\00", visibility_ = 0 : i64}> ({
  }) : () -> ()
  "gpu.module"() <{sym_name = "kernels"}> ({
    "llvm.func"() <{CConv = #llvm.cconv<ccc>, arg_attrs = [{}, {}, {}, {}], function_type = !llvm.func<void (struct<(ptr<1>, struct<(i32, struct<()>)>)>, struct<(ptr<1>, struct<(i32, struct<()>)>)>, struct<(ptr<1>, struct<(i32, struct<()>)>)>, struct<(ptr<1>, struct<(i32, struct<()>)>)>)>, linkage = #llvm.linkage<external>, sym_name = "kernel_cutlass_vote_kernel_tensorptri32gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_False_0", visibility_ = 0 : i64}> ({
    ^bb0(%arg8: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, %arg9: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, %arg10: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, %arg11: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>):
      %67 = "llvm.mlir.constant"() <{value = -1 : i32}> : () -> i32
      %68 = "llvm.mlir.constant"() <{value = 10 : i32}> : () -> i32
      %69 = "nvvm.read.ptx.sreg.tid.x"() <{range = #llvm.constant_range<i32, 0, 1024>}> : () -> i32
      %70 = "llvm.icmp"(%69, %68) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %71 = "nvvm.vote.ballot.sync"(%67, %70) : (i32, i1) -> i32
      %72 = "llvm.inline_asm"(%70, %67) <{asm_dialect = 0 : i64, asm_string = "{\0A\09\0A            .reg .pred ps;\0A\09\0A            .reg .pred pd;\0A\09\0A            setp.ne.b32 ps, $1, 0;\0A\09\0A            vote.sync.any.pred pd, ps, $2;\0A\09\0A            selp.b32 $0, 1, 0, pd;\0A\09\0A            }", constraints = "=r,r,i", has_side_effects}> : (i1, i32) -> i1
      %73 = "llvm.inline_asm"(%70, %67) <{asm_dialect = 0 : i64, asm_string = "{\0A\09\0A            .reg .pred ps;\0A\09\0A            .reg .pred pd;\0A\09\0A            setp.ne.b32 ps, $1, 0;\0A\09\0A            vote.sync.all.pred pd, ps, $2;\0A\09\0A            selp.b32 $0, 1, 0, pd;\0A\09\0A            }", constraints = "=r,r,i", has_side_effects}> : (i1, i32) -> i1
      %74 = "llvm.inline_asm"(%70, %67) <{asm_dialect = 0 : i64, asm_string = "{\0A\09\0A            .reg .pred ps;\0A\09\0A            .reg .pred pd;\0A\09\0A            setp.ne.b32 ps, $1, 0;\0A\09\0A            vote.sync.uni.pred pd, ps, $2;\0A\09\0A            selp.b32 $0, 1, 0, pd;\0A\09\0A            }", constraints = "=r,r,i", has_side_effects}> : (i1, i32) -> i1
      %75 = "llvm.extractvalue"(%arg8) <{position = array<i64: 0>}> : (!llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>) -> !llvm.ptr<1>
      %76 = "llvm.getelementptr"(%75, %69) <{elem_type = i32, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>
      %77 = "llvm.ptrtoint"(%76) : (!llvm.ptr<1>) -> i64
      %78 = "llvm.inttoptr"(%77) : (i64) -> !llvm.ptr<1>
      "llvm.store"(%71, %78) <{alignment = 4 : i64, ordering = 0 : i64}> : (i32, !llvm.ptr<1>) -> ()
      %79 = "llvm.zext"(%72) : (i1) -> i8
      %80 = "llvm.extractvalue"(%arg9) <{position = array<i64: 0>}> : (!llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>) -> !llvm.ptr<1>
      %81 = "llvm.getelementptr"(%80, %69) <{elem_type = i8, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>
      %82 = "llvm.ptrtoint"(%81) : (!llvm.ptr<1>) -> i64
      %83 = "llvm.inttoptr"(%82) : (i64) -> !llvm.ptr<1>
      "llvm.store"(%79, %83) <{alignment = 1 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr<1>) -> ()
      %84 = "llvm.zext"(%73) : (i1) -> i8
      %85 = "llvm.extractvalue"(%arg10) <{position = array<i64: 0>}> : (!llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>) -> !llvm.ptr<1>
      %86 = "llvm.getelementptr"(%85, %69) <{elem_type = i8, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>
      %87 = "llvm.ptrtoint"(%86) : (!llvm.ptr<1>) -> i64
      %88 = "llvm.inttoptr"(%87) : (i64) -> !llvm.ptr<1>
      "llvm.store"(%84, %88) <{alignment = 1 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr<1>) -> ()
      %89 = "llvm.zext"(%74) : (i1) -> i8
      %90 = "llvm.extractvalue"(%arg11) <{position = array<i64: 0>}> : (!llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>) -> !llvm.ptr<1>
      %91 = "llvm.getelementptr"(%90, %69) <{elem_type = i8, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>
      %92 = "llvm.ptrtoint"(%91) : (!llvm.ptr<1>) -> i64
      %93 = "llvm.inttoptr"(%92) : (i64) -> !llvm.ptr<1>
      "llvm.store"(%89, %93) <{alignment = 1 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr<1>) -> ()
      "llvm.return"() : () -> ()
    }) {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, gpu.kernel, nvvm.kernel, nvvm.reqntid = array<i32: 32, 1, 1>} : () -> ()
  }) : () -> ()
  "llvm.func"() <{CConv = #llvm.cconv<ccc>, function_type = !llvm.func<i32 (struct<(ptr<1>, struct<(i32, struct<()>)>)>, struct<(ptr<1>, struct<(i32, struct<()>)>)>, struct<(ptr<1>, struct<(i32, struct<()>)>)>, struct<(ptr<1>, struct<(i32, struct<()>)>)>)>, linkage = #llvm.linkage<external>, sym_name = "cutlass_vote_Tensorgmemo1_Tensorgmemo1_Tensorgmemo1_Tensorgmemo1_False", visibility_ = 0 : i64}> ({
  ^bb0(%arg4: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, %arg5: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, %arg6: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, %arg7: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>):
    %1 = "llvm.mlir.constant"() <{value = 2 : i32}> : () -> i32
    %2 = "llvm.mlir.constant"() <{value = 3 : i32}> : () -> i32
    %3 = "llvm.mlir.addressof"() <{global_name = @"%s\0A"}> : () -> !llvm.ptr
    %4 = "llvm.mlir.addressof"() <{global_name = @"ERROR: Reached max number of attributes, unable to add more attributes."}> : () -> !llvm.ptr
    %5 = "llvm.mlir.constant"() <{value = 6 : i32}> : () -> i32
    %6 = "llvm.mlir.constant"() <{value = 1 : i32}> : () -> i32
    %7 = "llvm.mlir.constant"() <{value = 32 : i32}> : () -> i32
    %8 = "llvm.mlir.constant"() <{value = 0 : i32}> : () -> i32
    %9 = "llvm.mlir.constant"() <{value = 0 : i64}> : () -> i64
    %10 = "llvm.inttoptr"(%9) : (i64) -> !llvm.ptr
    %11 = "llvm.alloca"(%6) <{elem_type = !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>}> : (i32) -> !llvm.ptr
    %12 = "llvm.alloca"(%6) <{elem_type = !llvm.array<3 x struct<(i32, array<4 x i8>, array<64 x i8>)>>}> : (i32) -> !llvm.ptr
    %13 = "llvm.getelementptr"(%11) <{elem_type = !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>, rawConstantIndices = array<i32: 0, 4>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%12, %13) <{ordering = 0 : i64}> : (!llvm.ptr, !llvm.ptr) -> ()
    %14 = "llvm.getelementptr"(%11) <{elem_type = !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>, rawConstantIndices = array<i32: 0, 1, 0>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%7, %14) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
    %15 = "llvm.getelementptr"(%11) <{elem_type = !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>, rawConstantIndices = array<i32: 0, 1, 1>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%6, %15) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
    %16 = "llvm.getelementptr"(%11) <{elem_type = !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>, rawConstantIndices = array<i32: 0, 1, 2>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%6, %16) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
    %17 = "llvm.getelementptr"(%11) <{elem_type = !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>, rawConstantIndices = array<i32: 0, 2>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%9, %17) <{ordering = 0 : i64}> : (i64, !llvm.ptr) -> ()
    %18 = "llvm.getelementptr"(%11) <{elem_type = !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>, rawConstantIndices = array<i32: 0, 0, 0>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%6, %18) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
    %19 = "llvm.getelementptr"(%11) <{elem_type = !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>, rawConstantIndices = array<i32: 0, 0, 1>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%6, %19) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
    %20 = "llvm.getelementptr"(%11) <{elem_type = !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>, rawConstantIndices = array<i32: 0, 0, 2>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%6, %20) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
    %21 = "llvm.getelementptr"(%11) <{elem_type = !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>, rawConstantIndices = array<i32: 0, 5>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%8, %21) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
    %22 = "llvm.getelementptr"(%11) <{elem_type = !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>, rawConstantIndices = array<i32: 0, 3>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%10, %22) <{ordering = 0 : i64}> : (!llvm.ptr, !llvm.ptr) -> ()
    %23 = "llvm.alloca"(%6) <{elem_type = !llvm.array<1 x ptr>}> : (i32) -> !llvm.ptr
    %24 = "llvm.getelementptr"(%23) <{elem_type = !llvm.array<1 x ptr>, rawConstantIndices = array<i32: 0, 0>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%11, %24) <{ordering = 0 : i64}> : (!llvm.ptr, !llvm.ptr) -> ()
    %25 = "llvm.load"(%24) <{ordering = 0 : i64}> : (!llvm.ptr) -> !llvm.ptr
    %26 = "llvm.getelementptr"(%25) <{elem_type = !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>, rawConstantIndices = array<i32: 0, 5>}> : (!llvm.ptr) -> !llvm.ptr
    %27 = "llvm.load"(%26) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
    %28 = "llvm.getelementptr"(%25) <{elem_type = !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>, rawConstantIndices = array<i32: 0, 4>}> : (!llvm.ptr) -> !llvm.ptr
    %29 = "llvm.load"(%28) <{ordering = 0 : i64}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.br"(%8)[^bb7] : (i32) -> ()
  ^bb1(%30: i32):  // 2 preds: ^bb3, ^bb5
    %31 = "llvm.getelementptr"(%29, %30) <{elem_type = !llvm.struct<(i32, array<4 x i8>, array<64 x i8>)>, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr, i32) -> !llvm.ptr
    %32 = "llvm.getelementptr"(%31) <{elem_type = !llvm.struct<(i32, array<4 x i8>, array<64 x i8>)>, rawConstantIndices = array<i32: 0, 0>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%5, %32) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
    %33 = "llvm.getelementptr"(%31) <{elem_type = !llvm.struct<(i32, array<4 x i8>, array<64 x i8>)>, rawConstantIndices = array<i32: 0, 2>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%8, %33) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
    "llvm.br"()[^bb8] : () -> ()
  ^bb2:  // 2 preds: ^bb4, ^bb11
    %34 = "llvm.getelementptr"(%4) <{elem_type = !llvm.array<72 x i8>, rawConstantIndices = array<i32: 0, 0>}> : (!llvm.ptr) -> !llvm.ptr
    %35 = "llvm.getelementptr"(%3) <{elem_type = !llvm.array<4 x i8>, rawConstantIndices = array<i32: 0, 0>}> : (!llvm.ptr) -> !llvm.ptr
    %36 = "llvm.call"(%35, %34) <{CConv = #llvm.cconv<ccc>, TailCallKind = #llvm.tailcallkind<none>, callee = @printf, fastmathFlags = #llvm.fastmath<none>, op_bundle_sizes = array<i32>, operandSegmentSizes = array<i32: 2, 0>, var_callee_type = !llvm.func<i32 (ptr, ...)>}> : (!llvm.ptr, !llvm.ptr) -> i32
    "llvm.intr.trap"() : () -> ()
    "llvm.unreachable"() : () -> ()
  ^bb3:  // pred: ^bb4
    %37 = "llvm.add"(%27, %6) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    "llvm.store"(%37, %26) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
    "llvm.br"(%27)[^bb1] : (i32) -> ()
  ^bb4:  // pred: ^bb7
    %38 = "llvm.icmp"(%27, %2) <{predicate = 9 : i64}> : (i32, i32) -> i1
    "llvm.cond_br"(%38)[^bb2, ^bb3] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb5:  // pred: ^bb6
    "llvm.br"(%44)[^bb1] : (i32) -> ()
  ^bb6:  // pred: ^bb7
    %39 = "llvm.getelementptr"(%29, %44) <{elem_type = !llvm.struct<(i32, array<4 x i8>, array<64 x i8>)>, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr, i32) -> !llvm.ptr
    %40 = "llvm.getelementptr"(%39) <{elem_type = !llvm.struct<(i32, array<4 x i8>, array<64 x i8>)>, rawConstantIndices = array<i32: 0, 0>}> : (!llvm.ptr) -> !llvm.ptr
    %41 = "llvm.load"(%40) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
    %42 = "llvm.icmp"(%41, %5) <{predicate = 0 : i64}> : (i32, i32) -> i1
    %43 = "llvm.add"(%44, %6) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    "llvm.cond_br"(%42, %43)[^bb5, ^bb7] <{operandSegmentSizes = array<i32: 1, 0, 1>}> : (i1, i32) -> ()
  ^bb7(%44: i32):  // 2 preds: ^bb0, ^bb6
    %45 = "llvm.icmp"(%44, %27) <{predicate = 9 : i64}> : (i32, i32) -> i1
    "llvm.cond_br"(%45)[^bb4, ^bb6] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb8:  // pred: ^bb1
    %46 = "llvm.load"(%24) <{ordering = 0 : i64}> : (!llvm.ptr) -> !llvm.ptr
    %47 = "llvm.getelementptr"(%46) <{elem_type = !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>, rawConstantIndices = array<i32: 0, 5>}> : (!llvm.ptr) -> !llvm.ptr
    %48 = "llvm.load"(%47) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
    %49 = "llvm.getelementptr"(%46) <{elem_type = !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>, rawConstantIndices = array<i32: 0, 4>}> : (!llvm.ptr) -> !llvm.ptr
    %50 = "llvm.load"(%49) <{ordering = 0 : i64}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.br"(%8)[^bb14] : (i32) -> ()
  ^bb9(%51: i32):  // 2 preds: ^bb10, ^bb12
    %52 = "llvm.getelementptr"(%50, %51) <{elem_type = !llvm.struct<(i32, array<4 x i8>, array<64 x i8>)>, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr, i32) -> !llvm.ptr
    %53 = "llvm.getelementptr"(%52) <{elem_type = !llvm.struct<(i32, array<4 x i8>, array<64 x i8>)>, rawConstantIndices = array<i32: 0, 0>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%1, %53) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
    %54 = "llvm.getelementptr"(%52) <{elem_type = !llvm.struct<(i32, array<4 x i8>, array<64 x i8>)>, rawConstantIndices = array<i32: 0, 2>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%8, %54) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
    "llvm.br"()[^bb15] : () -> ()
  ^bb10:  // pred: ^bb11
    %55 = "llvm.add"(%48, %6) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    "llvm.store"(%55, %47) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
    "llvm.br"(%48)[^bb9] : (i32) -> ()
  ^bb11:  // pred: ^bb14
    %56 = "llvm.icmp"(%48, %2) <{predicate = 9 : i64}> : (i32, i32) -> i1
    "llvm.cond_br"(%56)[^bb2, ^bb10] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb12:  // pred: ^bb13
    "llvm.br"(%62)[^bb9] : (i32) -> ()
  ^bb13:  // pred: ^bb14
    %57 = "llvm.getelementptr"(%50, %62) <{elem_type = !llvm.struct<(i32, array<4 x i8>, array<64 x i8>)>, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr, i32) -> !llvm.ptr
    %58 = "llvm.getelementptr"(%57) <{elem_type = !llvm.struct<(i32, array<4 x i8>, array<64 x i8>)>, rawConstantIndices = array<i32: 0, 0>}> : (!llvm.ptr) -> !llvm.ptr
    %59 = "llvm.load"(%58) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
    %60 = "llvm.icmp"(%59, %1) <{predicate = 0 : i64}> : (i32, i32) -> i1
    %61 = "llvm.add"(%62, %6) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    "llvm.cond_br"(%60, %61)[^bb12, ^bb14] <{operandSegmentSizes = array<i32: 1, 0, 1>}> : (i1, i32) -> ()
  ^bb14(%62: i32):  // 2 preds: ^bb8, ^bb13
    %63 = "llvm.icmp"(%62, %48) <{predicate = 9 : i64}> : (i32, i32) -> i1
    "llvm.cond_br"(%63)[^bb11, ^bb13] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb15:  // pred: ^bb9
    %64 = "builtin.unrealized_conversion_cast"(%23) : (!llvm.ptr) -> !cuda.launch_cfg<max_attrs = 3>
    %65 = "cuda.launch_ex"(%64, %arg4, %arg5, %arg6, %arg7) <{assume_kernel_attr = #cuda.assume_kernel_attr<true>, callee = @kernels::@kernel_cutlass_vote_kernel_tensorptri32gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_False_0}> : (!cuda.launch_cfg<max_attrs = 3>, !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>) -> !cuda.result
    %66 = "builtin.unrealized_conversion_cast"(%65) : (!cuda.result) -> i32
    "cuda.return_if_error"(%66) : (i32) -> ()
    "llvm.return"(%8) : (i32) -> ()
  }) {llvm.emit_c_interface} : () -> ()
  "llvm.func"() <{CConv = #llvm.cconv<ccc>, function_type = !llvm.func<i32 (struct<(ptr<1>, struct<(i32, struct<()>)>)>, struct<(ptr<1>, struct<(i32, struct<()>)>)>, struct<(ptr<1>, struct<(i32, struct<()>)>)>, struct<(ptr<1>, struct<(i32, struct<()>)>)>)>, linkage = #llvm.linkage<external>, sym_name = "_mlir_ciface_cutlass_vote_Tensorgmemo1_Tensorgmemo1_Tensorgmemo1_Tensorgmemo1_False", visibility_ = 0 : i64}> ({
  ^bb0(%arg0: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, %arg1: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, %arg2: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, %arg3: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>):
    %0 = "llvm.call"(%arg0, %arg1, %arg2, %arg3) <{CConv = #llvm.cconv<ccc>, TailCallKind = #llvm.tailcallkind<none>, callee = @cutlass_vote_Tensorgmemo1_Tensorgmemo1_Tensorgmemo1_Tensorgmemo1_False, fastmathFlags = #llvm.fastmath<none>, op_bundle_sizes = array<i32>, operandSegmentSizes = array<i32: 4, 0>}> : (!llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>) -> i32
    "llvm.return"(%0) : (i32) -> ()
  }) {llvm.emit_c_interface} : () -> ()
}) {gpu.container_module} : () -> ()
