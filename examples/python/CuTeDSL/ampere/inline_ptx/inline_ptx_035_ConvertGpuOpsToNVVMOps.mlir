"gpu.module"() <{sym_name = "kernels"}> ({
  "llvm.func"() <{CConv = #llvm.cconv<ccc>, arg_attrs = [{}, {}, {}, {}], function_type = !llvm.func<void (struct<(ptr<1>, struct<(i32, struct<()>)>)>, struct<(ptr<1>, struct<(i32, struct<()>)>)>, struct<(ptr<1>, struct<(i32, struct<()>)>)>, struct<(ptr<1>, struct<(i32, struct<()>)>)>)>, linkage = #llvm.linkage<external>, sym_name = "kernel_cutlass_vote_kernel_tensorptri32gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_False_0", visibility_ = 0 : i64}> ({
  ^bb0(%arg0: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, %arg1: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, %arg2: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>, %arg3: !llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>):
    %0 = "llvm.mlir.constant"() <{value = -1 : i32}> : () -> i32
    %1 = "llvm.mlir.constant"() <{value = 10 : i32}> : () -> i32
    %2 = "nvvm.read.ptx.sreg.tid.x"() <{range = #llvm.constant_range<i32, 0, 1024>}> : () -> i32
    %3 = "llvm.icmp"(%2, %1) <{predicate = 2 : i64}> : (i32, i32) -> i1
    %4 = "nvvm.vote.ballot.sync"(%0, %3) : (i32, i1) -> i32
    %5 = "llvm.inline_asm"(%3, %0) <{asm_dialect = 0 : i64, asm_string = "{\0A\09\0A            .reg .pred ps;\0A\09\0A            .reg .pred pd;\0A\09\0A            setp.ne.b32 ps, $1, 0;\0A\09\0A            vote.sync.any.pred pd, ps, $2;\0A\09\0A            selp.b32 $0, 1, 0, pd;\0A\09\0A            }", constraints = "=r,r,i", has_side_effects}> : (i1, i32) -> i1
    %6 = "llvm.inline_asm"(%3, %0) <{asm_dialect = 0 : i64, asm_string = "{\0A\09\0A            .reg .pred ps;\0A\09\0A            .reg .pred pd;\0A\09\0A            setp.ne.b32 ps, $1, 0;\0A\09\0A            vote.sync.all.pred pd, ps, $2;\0A\09\0A            selp.b32 $0, 1, 0, pd;\0A\09\0A            }", constraints = "=r,r,i", has_side_effects}> : (i1, i32) -> i1
    %7 = "llvm.inline_asm"(%3, %0) <{asm_dialect = 0 : i64, asm_string = "{\0A\09\0A            .reg .pred ps;\0A\09\0A            .reg .pred pd;\0A\09\0A            setp.ne.b32 ps, $1, 0;\0A\09\0A            vote.sync.uni.pred pd, ps, $2;\0A\09\0A            selp.b32 $0, 1, 0, pd;\0A\09\0A            }", constraints = "=r,r,i", has_side_effects}> : (i1, i32) -> i1
    %8 = "llvm.extractvalue"(%arg0) <{position = array<i64: 0>}> : (!llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>) -> !llvm.ptr<1>
    %9 = "llvm.getelementptr"(%8, %2) <{elem_type = i32, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>
    %10 = "llvm.ptrtoint"(%9) : (!llvm.ptr<1>) -> i64
    %11 = "llvm.inttoptr"(%10) : (i64) -> !llvm.ptr<1>
    "llvm.store"(%4, %11) <{alignment = 4 : i64, ordering = 0 : i64}> : (i32, !llvm.ptr<1>) -> ()
    %12 = "llvm.zext"(%5) : (i1) -> i8
    %13 = "llvm.extractvalue"(%arg1) <{position = array<i64: 0>}> : (!llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>) -> !llvm.ptr<1>
    %14 = "llvm.getelementptr"(%13, %2) <{elem_type = i8, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>
    %15 = "llvm.ptrtoint"(%14) : (!llvm.ptr<1>) -> i64
    %16 = "llvm.inttoptr"(%15) : (i64) -> !llvm.ptr<1>
    "llvm.store"(%12, %16) <{alignment = 1 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr<1>) -> ()
    %17 = "llvm.zext"(%6) : (i1) -> i8
    %18 = "llvm.extractvalue"(%arg2) <{position = array<i64: 0>}> : (!llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>) -> !llvm.ptr<1>
    %19 = "llvm.getelementptr"(%18, %2) <{elem_type = i8, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>
    %20 = "llvm.ptrtoint"(%19) : (!llvm.ptr<1>) -> i64
    %21 = "llvm.inttoptr"(%20) : (i64) -> !llvm.ptr<1>
    "llvm.store"(%17, %21) <{alignment = 1 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr<1>) -> ()
    %22 = "llvm.zext"(%7) : (i1) -> i8
    %23 = "llvm.extractvalue"(%arg3) <{position = array<i64: 0>}> : (!llvm.struct<(ptr<1>, struct<(i32, struct<()>)>)>) -> !llvm.ptr<1>
    %24 = "llvm.getelementptr"(%23, %2) <{elem_type = i8, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr<1>, i32) -> !llvm.ptr<1>
    %25 = "llvm.ptrtoint"(%24) : (!llvm.ptr<1>) -> i64
    %26 = "llvm.inttoptr"(%25) : (i64) -> !llvm.ptr<1>
    "llvm.store"(%22, %26) <{alignment = 1 : i64, ordering = 0 : i64}> : (i8, !llvm.ptr<1>) -> ()
    "llvm.return"() : () -> ()
  }) {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, gpu.kernel, nvvm.kernel, nvvm.reqntid = array<i32: 32, 1, 1>} : () -> ()
}) {compute_targets = [#cuda.compute_target<sass, conditional, [sm_90]>]} : () -> ()
