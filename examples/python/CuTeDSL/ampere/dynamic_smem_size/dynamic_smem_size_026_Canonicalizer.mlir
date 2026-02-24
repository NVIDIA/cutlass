"builtin.module"() ({
  "llvm.func"() <{CConv = #llvm.cconv<ccc>, function_type = !llvm.func<i32 (ptr, ...)>, linkage = #llvm.linkage<external>, sym_name = "printf", visibility_ = 0 : i64}> ({
  }) : () -> ()
  "llvm.mlir.global"() <{addr_space = 0 : i32, constant, global_type = !llvm.array<4 x i8>, linkage = #llvm.linkage<internal>, sym_name = "%s\0A", value = "%s\0A\00", visibility_ = 0 : i64}> ({
  }) : () -> ()
  "llvm.mlir.global"() <{addr_space = 0 : i32, constant, global_type = !llvm.array<72 x i8>, linkage = #llvm.linkage<internal>, sym_name = "ERROR: Reached max number of attributes, unable to add more attributes.", value = "ERROR: Reached max number of attributes, unable to add more attributes.\00", visibility_ = 0 : i64}> ({
  }) : () -> ()
  "gpu.module"() <{sym_name = "kernels"}> ({
    "llvm.func"() <{CConv = #llvm.cconv<ccc>, function_type = !llvm.func<void ()>, linkage = #llvm.linkage<external>, sym_name = "kernel_cutlass_kernel_no_smem_0", visibility_ = 0 : i64}> ({
      %71 = "llvm.mlir.constant"() <{value = 0 : i32}> : () -> i32
      %72 = "nvvm.read.ptx.sreg.ctaid.x"() <{range = #llvm.constant_range<i32, 0, 2147483647>}> : () -> i32
      %73 = "llvm.icmp"(%72, %71) <{predicate = 0 : i64}> : (i32, i32) -> i1
      "llvm.cond_br"(%73)[^bb1, ^bb2] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb1:  // pred: ^bb0
      "gpu.printf"() <{format = "Hello world\0A"}> : () -> ()
      "llvm.br"()[^bb2] : () -> ()
    ^bb2:  // 2 preds: ^bb0, ^bb1
      "llvm.return"() : () -> ()
    }) {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, gpu.kernel, nvvm.kernel, nvvm.reqntid = array<i32: 1, 1, 1>} : () -> ()
  }) : () -> ()
  "llvm.func"() <{CConv = #llvm.cconv<ccc>, function_type = !llvm.func<i32 ()>, linkage = #llvm.linkage<external>, sym_name = "cutlass_launch_kernel2", visibility_ = 0 : i64}> ({
    %1 = "llvm.mlir.constant"() <{value = 2 : i32}> : () -> i32
    %2 = "llvm.mlir.constant"() <{value = 3 : i32}> : () -> i32
    %3 = "llvm.mlir.addressof"() <{global_name = @"%s\0A"}> : () -> !llvm.ptr
    %4 = "llvm.mlir.addressof"() <{global_name = @"ERROR: Reached max number of attributes, unable to add more attributes."}> : () -> !llvm.ptr
    %5 = "llvm.mlir.constant"() <{value = 6 : i32}> : () -> i32
    %6 = "llvm.mlir.constant"() <{value = 1 : i32}> : () -> i32
    %7 = "llvm.mlir.constant"() <{value = 0 : i32}> : () -> i32
    %8 = "llvm.mlir.constant"() <{value = 0 : i64}> : () -> i64
    %9 = "llvm.inttoptr"(%8) : (i64) -> !llvm.ptr
    %10 = "llvm.alloca"(%6) <{elem_type = !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>}> : (i32) -> !llvm.ptr
    %11 = "llvm.alloca"(%6) <{elem_type = !llvm.array<3 x struct<(i32, array<4 x i8>, array<64 x i8>)>>}> : (i32) -> !llvm.ptr
    %12 = "llvm.getelementptr"(%10) <{elem_type = !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>, rawConstantIndices = array<i32: 0, 4>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%11, %12) <{ordering = 0 : i64}> : (!llvm.ptr, !llvm.ptr) -> ()
    %13 = "llvm.getelementptr"(%10) <{elem_type = !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>, rawConstantIndices = array<i32: 0, 1, 0>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%6, %13) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
    %14 = "llvm.getelementptr"(%10) <{elem_type = !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>, rawConstantIndices = array<i32: 0, 1, 1>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%6, %14) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
    %15 = "llvm.getelementptr"(%10) <{elem_type = !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>, rawConstantIndices = array<i32: 0, 1, 2>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%6, %15) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
    %16 = "llvm.getelementptr"(%10) <{elem_type = !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>, rawConstantIndices = array<i32: 0, 2>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%8, %16) <{ordering = 0 : i64}> : (i64, !llvm.ptr) -> ()
    %17 = "llvm.getelementptr"(%10) <{elem_type = !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>, rawConstantIndices = array<i32: 0, 0, 0>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%6, %17) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
    %18 = "llvm.getelementptr"(%10) <{elem_type = !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>, rawConstantIndices = array<i32: 0, 0, 1>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%6, %18) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
    %19 = "llvm.getelementptr"(%10) <{elem_type = !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>, rawConstantIndices = array<i32: 0, 0, 2>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%6, %19) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
    %20 = "llvm.getelementptr"(%10) <{elem_type = !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>, rawConstantIndices = array<i32: 0, 5>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%7, %20) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
    %21 = "llvm.getelementptr"(%10) <{elem_type = !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>, rawConstantIndices = array<i32: 0, 3>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%9, %21) <{ordering = 0 : i64}> : (!llvm.ptr, !llvm.ptr) -> ()
    %22 = "llvm.alloca"(%6) <{elem_type = !llvm.array<1 x ptr>}> : (i32) -> !llvm.ptr
    %23 = "builtin.unrealized_conversion_cast"(%22) : (!llvm.ptr) -> !cuda.launch_cfg<max_attrs = 3>
    %24 = "llvm.getelementptr"(%22) <{elem_type = !llvm.array<1 x ptr>, rawConstantIndices = array<i32: 0, 0>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%10, %24) <{ordering = 0 : i64}> : (!llvm.ptr, !llvm.ptr) -> ()
    %25 = "llvm.getelementptr"(%22) <{elem_type = !llvm.array<1 x ptr>, rawConstantIndices = array<i32: 0, 0>}> : (!llvm.ptr) -> !llvm.ptr
    %26 = "llvm.load"(%25) <{ordering = 0 : i64}> : (!llvm.ptr) -> !llvm.ptr
    %27 = "llvm.getelementptr"(%26) <{elem_type = !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>, rawConstantIndices = array<i32: 0, 5>}> : (!llvm.ptr) -> !llvm.ptr
    %28 = "llvm.load"(%27) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
    %29 = "llvm.getelementptr"(%26) <{elem_type = !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>, rawConstantIndices = array<i32: 0, 4>}> : (!llvm.ptr) -> !llvm.ptr
    %30 = "llvm.load"(%29) <{ordering = 0 : i64}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.br"(%7)[^bb7] : (i32) -> ()
  ^bb1(%31: i32):  // 2 preds: ^bb3, ^bb5
    %32 = "llvm.getelementptr"(%30, %31) <{elem_type = !llvm.struct<(i32, array<4 x i8>, array<64 x i8>)>, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr, i32) -> !llvm.ptr
    %33 = "llvm.getelementptr"(%32) <{elem_type = !llvm.struct<(i32, array<4 x i8>, array<64 x i8>)>, rawConstantIndices = array<i32: 0, 0>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%5, %33) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
    %34 = "llvm.getelementptr"(%32) <{elem_type = !llvm.struct<(i32, array<4 x i8>, array<64 x i8>)>, rawConstantIndices = array<i32: 0, 2>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%7, %34) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
    "llvm.br"()[^bb8] : () -> ()
  ^bb2:  // pred: ^bb4
    %35 = "llvm.getelementptr"(%4) <{elem_type = !llvm.array<72 x i8>, rawConstantIndices = array<i32: 0, 0>}> : (!llvm.ptr) -> !llvm.ptr
    %36 = "llvm.getelementptr"(%3) <{elem_type = !llvm.array<4 x i8>, rawConstantIndices = array<i32: 0, 0>}> : (!llvm.ptr) -> !llvm.ptr
    %37 = "llvm.call"(%36, %35) <{CConv = #llvm.cconv<ccc>, TailCallKind = #llvm.tailcallkind<none>, callee = @printf, fastmathFlags = #llvm.fastmath<none>, op_bundle_sizes = array<i32>, operandSegmentSizes = array<i32: 2, 0>, var_callee_type = !llvm.func<i32 (ptr, ...)>}> : (!llvm.ptr, !llvm.ptr) -> i32
    "llvm.intr.trap"() : () -> ()
    "llvm.unreachable"() : () -> ()
  ^bb3:  // pred: ^bb4
    %38 = "llvm.add"(%28, %6) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    "llvm.store"(%38, %27) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
    "llvm.br"(%28)[^bb1] : (i32) -> ()
  ^bb4:  // pred: ^bb7
    %39 = "llvm.icmp"(%28, %2) <{predicate = 9 : i64}> : (i32, i32) -> i1
    "llvm.cond_br"(%39)[^bb2, ^bb3] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb5:  // pred: ^bb6
    "llvm.br"(%45)[^bb1] : (i32) -> ()
  ^bb6:  // pred: ^bb7
    %40 = "llvm.getelementptr"(%30, %45) <{elem_type = !llvm.struct<(i32, array<4 x i8>, array<64 x i8>)>, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr, i32) -> !llvm.ptr
    %41 = "llvm.getelementptr"(%40) <{elem_type = !llvm.struct<(i32, array<4 x i8>, array<64 x i8>)>, rawConstantIndices = array<i32: 0, 0>}> : (!llvm.ptr) -> !llvm.ptr
    %42 = "llvm.load"(%41) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
    %43 = "llvm.icmp"(%42, %5) <{predicate = 0 : i64}> : (i32, i32) -> i1
    %44 = "llvm.add"(%45, %6) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    "llvm.cond_br"(%43, %44)[^bb5, ^bb7] <{operandSegmentSizes = array<i32: 1, 0, 1>}> : (i1, i32) -> ()
  ^bb7(%45: i32):  // 2 preds: ^bb0, ^bb6
    %46 = "llvm.icmp"(%45, %28) <{predicate = 9 : i64}> : (i32, i32) -> i1
    "llvm.cond_br"(%46)[^bb4, ^bb6] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb8:  // pred: ^bb1
    %47 = "llvm.getelementptr"(%22) <{elem_type = !llvm.array<1 x ptr>, rawConstantIndices = array<i32: 0, 0>}> : (!llvm.ptr) -> !llvm.ptr
    %48 = "llvm.load"(%47) <{ordering = 0 : i64}> : (!llvm.ptr) -> !llvm.ptr
    %49 = "llvm.getelementptr"(%48) <{elem_type = !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>, rawConstantIndices = array<i32: 0, 5>}> : (!llvm.ptr) -> !llvm.ptr
    %50 = "llvm.load"(%49) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
    %51 = "llvm.getelementptr"(%48) <{elem_type = !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>, rawConstantIndices = array<i32: 0, 4>}> : (!llvm.ptr) -> !llvm.ptr
    %52 = "llvm.load"(%51) <{ordering = 0 : i64}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.br"(%7)[^bb15] : (i32) -> ()
  ^bb9(%53: i32):  // 2 preds: ^bb11, ^bb13
    %54 = "llvm.getelementptr"(%52, %53) <{elem_type = !llvm.struct<(i32, array<4 x i8>, array<64 x i8>)>, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr, i32) -> !llvm.ptr
    %55 = "llvm.getelementptr"(%54) <{elem_type = !llvm.struct<(i32, array<4 x i8>, array<64 x i8>)>, rawConstantIndices = array<i32: 0, 0>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%1, %55) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
    %56 = "llvm.getelementptr"(%54) <{elem_type = !llvm.struct<(i32, array<4 x i8>, array<64 x i8>)>, rawConstantIndices = array<i32: 0, 2>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%7, %56) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
    "llvm.br"()[^bb16] : () -> ()
  ^bb10:  // pred: ^bb12
    %57 = "llvm.getelementptr"(%4) <{elem_type = !llvm.array<72 x i8>, rawConstantIndices = array<i32: 0, 0>}> : (!llvm.ptr) -> !llvm.ptr
    %58 = "llvm.getelementptr"(%3) <{elem_type = !llvm.array<4 x i8>, rawConstantIndices = array<i32: 0, 0>}> : (!llvm.ptr) -> !llvm.ptr
    %59 = "llvm.call"(%58, %57) <{CConv = #llvm.cconv<ccc>, TailCallKind = #llvm.tailcallkind<none>, callee = @printf, fastmathFlags = #llvm.fastmath<none>, op_bundle_sizes = array<i32>, operandSegmentSizes = array<i32: 2, 0>, var_callee_type = !llvm.func<i32 (ptr, ...)>}> : (!llvm.ptr, !llvm.ptr) -> i32
    "llvm.intr.trap"() : () -> ()
    "llvm.unreachable"() : () -> ()
  ^bb11:  // pred: ^bb12
    %60 = "llvm.add"(%50, %6) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    "llvm.store"(%60, %49) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
    "llvm.br"(%50)[^bb9] : (i32) -> ()
  ^bb12:  // pred: ^bb15
    %61 = "llvm.icmp"(%50, %2) <{predicate = 9 : i64}> : (i32, i32) -> i1
    "llvm.cond_br"(%61)[^bb10, ^bb11] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb13:  // pred: ^bb14
    "llvm.br"(%67)[^bb9] : (i32) -> ()
  ^bb14:  // pred: ^bb15
    %62 = "llvm.getelementptr"(%52, %67) <{elem_type = !llvm.struct<(i32, array<4 x i8>, array<64 x i8>)>, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr, i32) -> !llvm.ptr
    %63 = "llvm.getelementptr"(%62) <{elem_type = !llvm.struct<(i32, array<4 x i8>, array<64 x i8>)>, rawConstantIndices = array<i32: 0, 0>}> : (!llvm.ptr) -> !llvm.ptr
    %64 = "llvm.load"(%63) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
    %65 = "llvm.icmp"(%64, %1) <{predicate = 0 : i64}> : (i32, i32) -> i1
    %66 = "llvm.add"(%67, %6) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    "llvm.cond_br"(%65, %66)[^bb13, ^bb15] <{operandSegmentSizes = array<i32: 1, 0, 1>}> : (i1, i32) -> ()
  ^bb15(%67: i32):  // 2 preds: ^bb8, ^bb14
    %68 = "llvm.icmp"(%67, %50) <{predicate = 9 : i64}> : (i32, i32) -> i1
    "llvm.cond_br"(%68)[^bb12, ^bb14] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb16:  // pred: ^bb9
    %69 = "cuda.launch_ex"(%23) <{assume_kernel_attr = #cuda.assume_kernel_attr<true>, callee = @kernels::@kernel_cutlass_kernel_no_smem_0}> : (!cuda.launch_cfg<max_attrs = 3>) -> !cuda.result
    %70 = "builtin.unrealized_conversion_cast"(%69) : (!cuda.result) -> i32
    "cuda.return_if_error"(%70) : (i32) -> ()
    "llvm.return"(%7) : (i32) -> ()
  }) {llvm.emit_c_interface} : () -> ()
  "llvm.func"() <{CConv = #llvm.cconv<ccc>, function_type = !llvm.func<i32 ()>, linkage = #llvm.linkage<external>, sym_name = "_mlir_ciface_cutlass_launch_kernel2", visibility_ = 0 : i64}> ({
    %0 = "llvm.call"() <{CConv = #llvm.cconv<ccc>, TailCallKind = #llvm.tailcallkind<none>, callee = @cutlass_launch_kernel2, fastmathFlags = #llvm.fastmath<none>, op_bundle_sizes = array<i32>, operandSegmentSizes = array<i32: 0, 0>}> : () -> i32
    "llvm.return"(%0) : (i32) -> ()
  }) {llvm.emit_c_interface} : () -> ()
}) {gpu.container_module} : () -> ()
