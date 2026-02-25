"gpu.module"() <{sym_name = "kernels"}> ({
  "llvm.mlir.global"() <{addr_space = 0 : i32, constant, global_type = !llvm.array<13 x i8>, linkage = #llvm.linkage<internal>, sym_name = "printfFormat_0", value = "Hello world\0A\00", visibility_ = 0 : i64}> ({
  }) : () -> ()
  "llvm.func"() <{CConv = #llvm.cconv<ccc>, function_type = !llvm.func<i32 (ptr, ptr)>, linkage = #llvm.linkage<external>, sym_name = "vprintf", visibility_ = 0 : i64}> ({
  }) : () -> ()
  "llvm.func"() <{CConv = #llvm.cconv<ccc>, function_type = !llvm.func<void ()>, linkage = #llvm.linkage<external>, sym_name = "kernel_cutlass_kernel_no_smem_0", visibility_ = 0 : i64}> ({
    %0 = "llvm.mlir.constant"() <{value = 0 : i32}> : () -> i32
    %1 = "nvvm.read.ptx.sreg.ctaid.x"() <{range = #llvm.constant_range<i32, 0, 2147483647>}> : () -> i32
    %2 = "llvm.icmp"(%1, %0) <{predicate = 0 : i64}> : (i32, i32) -> i1
    "llvm.cond_br"(%2)[^bb1, ^bb2] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb1:  // pred: ^bb0
    %3 = "llvm.mlir.addressof"() <{global_name = @printfFormat_0}> : () -> !llvm.ptr
    %4 = "llvm.getelementptr"(%3) <{elem_type = !llvm.array<13 x i8>, rawConstantIndices = array<i32: 0, 0>}> : (!llvm.ptr) -> !llvm.ptr
    %5 = "llvm.mlir.constant"() <{value = 1 : index}> : () -> i64
    %6 = "llvm.alloca"(%5) <{elem_type = !llvm.struct<()>}> : (i64) -> !llvm.ptr
    %7 = "llvm.call"(%4, %6) <{CConv = #llvm.cconv<ccc>, TailCallKind = #llvm.tailcallkind<none>, callee = @vprintf, fastmathFlags = #llvm.fastmath<none>, op_bundle_sizes = array<i32>, operandSegmentSizes = array<i32: 2, 0>}> : (!llvm.ptr, !llvm.ptr) -> i32
    "llvm.br"()[^bb2] : () -> ()
  ^bb2:  // 2 preds: ^bb0, ^bb1
    "llvm.return"() : () -> ()
  }) {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, gpu.kernel, nvvm.kernel, nvvm.reqntid = array<i32: 1, 1, 1>} : () -> ()
}) {compute_targets = [#cuda.compute_target<sass, conditional, [sm_90]>]} : () -> ()
