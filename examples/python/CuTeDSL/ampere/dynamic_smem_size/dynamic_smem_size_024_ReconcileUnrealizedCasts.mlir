"builtin.module"() ({
  "llvm.func"() <{CConv = #llvm.cconv<ccc>, function_type = !llvm.func<i32 (ptr, ...)>, linkage = #llvm.linkage<external>, sym_name = "printf", visibility_ = 0 : i64}> ({
  }) : () -> ()
  "llvm.mlir.global"() <{addr_space = 0 : i32, constant, global_type = !llvm.array<4 x i8>, linkage = #llvm.linkage<internal>, sym_name = "%s\0A", value = "%s\0A\00", visibility_ = 0 : i64}> ({
  }) : () -> ()
  "llvm.mlir.global"() <{addr_space = 0 : i32, constant, global_type = !llvm.array<72 x i8>, linkage = #llvm.linkage<internal>, sym_name = "ERROR: Reached max number of attributes, unable to add more attributes.", value = "ERROR: Reached max number of attributes, unable to add more attributes.\00", visibility_ = 0 : i64}> ({
  }) : () -> ()
  "gpu.module"() <{sym_name = "kernels"}> ({
    "llvm.func"() <{CConv = #llvm.cconv<ccc>, function_type = !llvm.func<void ()>, linkage = #llvm.linkage<external>, sym_name = "kernel_cutlass_kernel_no_smem_0", visibility_ = 0 : i64}> ({
      %86 = "llvm.mlir.constant"() <{value = 0 : i32}> : () -> i32
      %87 = "nvvm.read.ptx.sreg.ctaid.x"() <{range = #llvm.constant_range<i32, 0, 2147483647>}> : () -> i32
      %88 = "llvm.icmp"(%87, %86) <{predicate = 0 : i64}> : (i32, i32) -> i1
      "llvm.cond_br"(%88)[^bb1, ^bb2] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
    ^bb1:  // pred: ^bb0
      "gpu.printf"() <{format = "Hello world\0A"}> : () -> ()
      "llvm.br"()[^bb2] : () -> ()
    ^bb2:  // 2 preds: ^bb0, ^bb1
      "llvm.return"() : () -> ()
    }) {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, gpu.kernel, nvvm.kernel, nvvm.reqntid = array<i32: 1, 1, 1>} : () -> ()
  }) : () -> ()
  "llvm.func"() <{CConv = #llvm.cconv<ccc>, function_type = !llvm.func<i32 ()>, linkage = #llvm.linkage<external>, sym_name = "cutlass_launch_kernel2", visibility_ = 0 : i64}> ({
    %1 = "llvm.mlir.constant"() <{value = 1 : i32}> : () -> i32
    %2 = "llvm.mlir.constant"() <{value = 0 : i32}> : () -> i32
    %3 = "llvm.mlir.constant"() <{value = 0 : i64}> : () -> i64
    %4 = "llvm.inttoptr"(%3) : (i64) -> !llvm.ptr
    %5 = "llvm.mlir.constant"() <{value = 1 : i32}> : () -> i32
    %6 = "llvm.alloca"(%5) <{elem_type = !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>}> : (i32) -> !llvm.ptr
    %7 = "llvm.alloca"(%5) <{elem_type = !llvm.array<3 x struct<(i32, array<4 x i8>, array<64 x i8>)>>}> : (i32) -> !llvm.ptr
    %8 = "llvm.getelementptr"(%6) <{elem_type = !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>, rawConstantIndices = array<i32: 0, 4>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%7, %8) <{ordering = 0 : i64}> : (!llvm.ptr, !llvm.ptr) -> ()
    %9 = "llvm.getelementptr"(%6) <{elem_type = !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>, rawConstantIndices = array<i32: 0, 1, 0>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%1, %9) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
    %10 = "llvm.getelementptr"(%6) <{elem_type = !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>, rawConstantIndices = array<i32: 0, 1, 1>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%1, %10) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
    %11 = "llvm.getelementptr"(%6) <{elem_type = !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>, rawConstantIndices = array<i32: 0, 1, 2>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%1, %11) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
    %12 = "llvm.getelementptr"(%6) <{elem_type = !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>, rawConstantIndices = array<i32: 0, 2>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%3, %12) <{ordering = 0 : i64}> : (i64, !llvm.ptr) -> ()
    %13 = "llvm.getelementptr"(%6) <{elem_type = !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>, rawConstantIndices = array<i32: 0, 0, 0>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%1, %13) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
    %14 = "llvm.getelementptr"(%6) <{elem_type = !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>, rawConstantIndices = array<i32: 0, 0, 1>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%1, %14) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
    %15 = "llvm.getelementptr"(%6) <{elem_type = !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>, rawConstantIndices = array<i32: 0, 0, 2>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%1, %15) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
    %16 = "llvm.getelementptr"(%6) <{elem_type = !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>, rawConstantIndices = array<i32: 0, 5>}> : (!llvm.ptr) -> !llvm.ptr
    %17 = "llvm.mlir.constant"() <{value = 0 : i32}> : () -> i32
    "llvm.store"(%17, %16) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
    %18 = "llvm.getelementptr"(%6) <{elem_type = !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>, rawConstantIndices = array<i32: 0, 3>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%4, %18) <{ordering = 0 : i64}> : (!llvm.ptr, !llvm.ptr) -> ()
    %19 = "llvm.alloca"(%5) <{elem_type = !llvm.array<1 x ptr>}> : (i32) -> !llvm.ptr
    %20 = "builtin.unrealized_conversion_cast"(%19) : (!llvm.ptr) -> !cuda.launch_cfg<max_attrs = 3>
    %21 = "llvm.getelementptr"(%19) <{elem_type = !llvm.array<1 x ptr>, rawConstantIndices = array<i32: 0, 0>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%6, %21) <{ordering = 0 : i64}> : (!llvm.ptr, !llvm.ptr) -> ()
    %22 = "llvm.getelementptr"(%19) <{elem_type = !llvm.array<1 x ptr>, rawConstantIndices = array<i32: 0, 0>}> : (!llvm.ptr) -> !llvm.ptr
    %23 = "llvm.load"(%22) <{ordering = 0 : i64}> : (!llvm.ptr) -> !llvm.ptr
    %24 = "llvm.getelementptr"(%23) <{elem_type = !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>, rawConstantIndices = array<i32: 0, 5>}> : (!llvm.ptr) -> !llvm.ptr
    %25 = "llvm.load"(%24) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
    %26 = "llvm.getelementptr"(%23) <{elem_type = !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>, rawConstantIndices = array<i32: 0, 4>}> : (!llvm.ptr) -> !llvm.ptr
    %27 = "llvm.load"(%26) <{ordering = 0 : i64}> : (!llvm.ptr) -> !llvm.ptr
    %28 = "llvm.mlir.constant"() <{value = 6 : i32}> : () -> i32
    %29 = "llvm.mlir.constant"() <{value = 0 : i32}> : () -> i32
    "llvm.br"(%29)[^bb7] : (i32) -> ()
  ^bb1(%30: i32):  // 2 preds: ^bb3, ^bb5
    %31 = "llvm.getelementptr"(%27, %30) <{elem_type = !llvm.struct<(i32, array<4 x i8>, array<64 x i8>)>, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr, i32) -> !llvm.ptr
    %32 = "llvm.getelementptr"(%31) <{elem_type = !llvm.struct<(i32, array<4 x i8>, array<64 x i8>)>, rawConstantIndices = array<i32: 0, 0>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%28, %32) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
    %33 = "llvm.getelementptr"(%31) <{elem_type = !llvm.struct<(i32, array<4 x i8>, array<64 x i8>)>, rawConstantIndices = array<i32: 0, 2>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%2, %33) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
    "llvm.br"()[^bb8] : () -> ()
  ^bb2:  // pred: ^bb4
    %34 = "llvm.mlir.addressof"() <{global_name = @"ERROR: Reached max number of attributes, unable to add more attributes."}> : () -> !llvm.ptr
    %35 = "llvm.mlir.constant"() <{value = 0 : index}> : () -> i64
    %36 = "llvm.getelementptr"(%34, %35, %35) <{elem_type = !llvm.array<72 x i8>, rawConstantIndices = array<i32: -2147483648, -2147483648>}> : (!llvm.ptr, i64, i64) -> !llvm.ptr
    %37 = "llvm.mlir.addressof"() <{global_name = @"%s\0A"}> : () -> !llvm.ptr
    %38 = "llvm.mlir.constant"() <{value = 0 : index}> : () -> i64
    %39 = "llvm.getelementptr"(%37, %38, %38) <{elem_type = !llvm.array<4 x i8>, rawConstantIndices = array<i32: -2147483648, -2147483648>}> : (!llvm.ptr, i64, i64) -> !llvm.ptr
    %40 = "llvm.call"(%39, %36) <{CConv = #llvm.cconv<ccc>, TailCallKind = #llvm.tailcallkind<none>, callee = @printf, fastmathFlags = #llvm.fastmath<none>, op_bundle_sizes = array<i32>, operandSegmentSizes = array<i32: 2, 0>, var_callee_type = !llvm.func<i32 (ptr, ...)>}> : (!llvm.ptr, !llvm.ptr) -> i32
    "llvm.intr.trap"() : () -> ()
    "llvm.unreachable"() : () -> ()
  ^bb3:  // pred: ^bb4
    %41 = "llvm.mlir.constant"() <{value = 1 : i32}> : () -> i32
    %42 = "llvm.add"(%25, %41) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    "llvm.store"(%42, %24) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
    "llvm.br"(%25)[^bb1] : (i32) -> ()
  ^bb4:  // pred: ^bb7
    %43 = "llvm.mlir.constant"() <{value = 3 : i32}> : () -> i32
    %44 = "llvm.icmp"(%25, %43) <{predicate = 9 : i64}> : (i32, i32) -> i1
    "llvm.cond_br"(%44)[^bb2, ^bb3] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb5:  // pred: ^bb6
    "llvm.br"(%51)[^bb1] : (i32) -> ()
  ^bb6:  // pred: ^bb7
    %45 = "llvm.getelementptr"(%27, %51) <{elem_type = !llvm.struct<(i32, array<4 x i8>, array<64 x i8>)>, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr, i32) -> !llvm.ptr
    %46 = "llvm.getelementptr"(%45) <{elem_type = !llvm.struct<(i32, array<4 x i8>, array<64 x i8>)>, rawConstantIndices = array<i32: 0, 0>}> : (!llvm.ptr) -> !llvm.ptr
    %47 = "llvm.load"(%46) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
    %48 = "llvm.icmp"(%47, %28) <{predicate = 0 : i64}> : (i32, i32) -> i1
    %49 = "llvm.mlir.constant"() <{value = 1 : i32}> : () -> i32
    %50 = "llvm.add"(%51, %49) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    "llvm.cond_br"(%48, %50)[^bb5, ^bb7] <{operandSegmentSizes = array<i32: 1, 0, 1>}> : (i1, i32) -> ()
  ^bb7(%51: i32):  // 2 preds: ^bb0, ^bb6
    %52 = "llvm.icmp"(%51, %25) <{predicate = 9 : i64}> : (i32, i32) -> i1
    "llvm.cond_br"(%52)[^bb4, ^bb6] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb8:  // pred: ^bb1
    %53 = "llvm.getelementptr"(%19) <{elem_type = !llvm.array<1 x ptr>, rawConstantIndices = array<i32: 0, 0>}> : (!llvm.ptr) -> !llvm.ptr
    %54 = "llvm.load"(%53) <{ordering = 0 : i64}> : (!llvm.ptr) -> !llvm.ptr
    %55 = "llvm.getelementptr"(%54) <{elem_type = !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>, rawConstantIndices = array<i32: 0, 5>}> : (!llvm.ptr) -> !llvm.ptr
    %56 = "llvm.load"(%55) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
    %57 = "llvm.getelementptr"(%54) <{elem_type = !llvm.struct<(array<3 x i32>, array<3 x i32>, i64, ptr, ptr, i32)>, rawConstantIndices = array<i32: 0, 4>}> : (!llvm.ptr) -> !llvm.ptr
    %58 = "llvm.load"(%57) <{ordering = 0 : i64}> : (!llvm.ptr) -> !llvm.ptr
    %59 = "llvm.mlir.constant"() <{value = 2 : i32}> : () -> i32
    %60 = "llvm.mlir.constant"() <{value = 0 : i32}> : () -> i32
    "llvm.br"(%60)[^bb15] : (i32) -> ()
  ^bb9(%61: i32):  // 2 preds: ^bb11, ^bb13
    %62 = "llvm.getelementptr"(%58, %61) <{elem_type = !llvm.struct<(i32, array<4 x i8>, array<64 x i8>)>, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr, i32) -> !llvm.ptr
    %63 = "llvm.getelementptr"(%62) <{elem_type = !llvm.struct<(i32, array<4 x i8>, array<64 x i8>)>, rawConstantIndices = array<i32: 0, 0>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%59, %63) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
    %64 = "llvm.getelementptr"(%62) <{elem_type = !llvm.struct<(i32, array<4 x i8>, array<64 x i8>)>, rawConstantIndices = array<i32: 0, 2>}> : (!llvm.ptr) -> !llvm.ptr
    "llvm.store"(%2, %64) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
    "llvm.br"()[^bb16] : () -> ()
  ^bb10:  // pred: ^bb12
    %65 = "llvm.mlir.addressof"() <{global_name = @"ERROR: Reached max number of attributes, unable to add more attributes."}> : () -> !llvm.ptr
    %66 = "llvm.mlir.constant"() <{value = 0 : index}> : () -> i64
    %67 = "llvm.getelementptr"(%65, %66, %66) <{elem_type = !llvm.array<72 x i8>, rawConstantIndices = array<i32: -2147483648, -2147483648>}> : (!llvm.ptr, i64, i64) -> !llvm.ptr
    %68 = "llvm.mlir.addressof"() <{global_name = @"%s\0A"}> : () -> !llvm.ptr
    %69 = "llvm.mlir.constant"() <{value = 0 : index}> : () -> i64
    %70 = "llvm.getelementptr"(%68, %69, %69) <{elem_type = !llvm.array<4 x i8>, rawConstantIndices = array<i32: -2147483648, -2147483648>}> : (!llvm.ptr, i64, i64) -> !llvm.ptr
    %71 = "llvm.call"(%70, %67) <{CConv = #llvm.cconv<ccc>, TailCallKind = #llvm.tailcallkind<none>, callee = @printf, fastmathFlags = #llvm.fastmath<none>, op_bundle_sizes = array<i32>, operandSegmentSizes = array<i32: 2, 0>, var_callee_type = !llvm.func<i32 (ptr, ...)>}> : (!llvm.ptr, !llvm.ptr) -> i32
    "llvm.intr.trap"() : () -> ()
    "llvm.unreachable"() : () -> ()
  ^bb11:  // pred: ^bb12
    %72 = "llvm.mlir.constant"() <{value = 1 : i32}> : () -> i32
    %73 = "llvm.add"(%56, %72) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    "llvm.store"(%73, %55) <{ordering = 0 : i64}> : (i32, !llvm.ptr) -> ()
    "llvm.br"(%56)[^bb9] : (i32) -> ()
  ^bb12:  // pred: ^bb15
    %74 = "llvm.mlir.constant"() <{value = 3 : i32}> : () -> i32
    %75 = "llvm.icmp"(%56, %74) <{predicate = 9 : i64}> : (i32, i32) -> i1
    "llvm.cond_br"(%75)[^bb10, ^bb11] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb13:  // pred: ^bb14
    "llvm.br"(%82)[^bb9] : (i32) -> ()
  ^bb14:  // pred: ^bb15
    %76 = "llvm.getelementptr"(%58, %82) <{elem_type = !llvm.struct<(i32, array<4 x i8>, array<64 x i8>)>, rawConstantIndices = array<i32: -2147483648>}> : (!llvm.ptr, i32) -> !llvm.ptr
    %77 = "llvm.getelementptr"(%76) <{elem_type = !llvm.struct<(i32, array<4 x i8>, array<64 x i8>)>, rawConstantIndices = array<i32: 0, 0>}> : (!llvm.ptr) -> !llvm.ptr
    %78 = "llvm.load"(%77) <{ordering = 0 : i64}> : (!llvm.ptr) -> i32
    %79 = "llvm.icmp"(%78, %59) <{predicate = 0 : i64}> : (i32, i32) -> i1
    %80 = "llvm.mlir.constant"() <{value = 1 : i32}> : () -> i32
    %81 = "llvm.add"(%82, %80) <{overflowFlags = #llvm.overflow<none>}> : (i32, i32) -> i32
    "llvm.cond_br"(%79, %81)[^bb13, ^bb15] <{operandSegmentSizes = array<i32: 1, 0, 1>}> : (i1, i32) -> ()
  ^bb15(%82: i32):  // 2 preds: ^bb8, ^bb14
    %83 = "llvm.icmp"(%82, %56) <{predicate = 9 : i64}> : (i32, i32) -> i1
    "llvm.cond_br"(%83)[^bb12, ^bb14] <{operandSegmentSizes = array<i32: 1, 0, 0>}> : (i1) -> ()
  ^bb16:  // pred: ^bb9
    %84 = "cuda.launch_ex"(%20) <{assume_kernel_attr = #cuda.assume_kernel_attr<true>, callee = @kernels::@kernel_cutlass_kernel_no_smem_0}> : (!cuda.launch_cfg<max_attrs = 3>) -> !cuda.result
    %85 = "builtin.unrealized_conversion_cast"(%84) : (!cuda.result) -> i32
    "cuda.return_if_error"(%85) : (i32) -> ()
    "llvm.return"(%2) : (i32) -> ()
  }) {llvm.emit_c_interface} : () -> ()
  "llvm.func"() <{CConv = #llvm.cconv<ccc>, function_type = !llvm.func<i32 ()>, linkage = #llvm.linkage<external>, sym_name = "_mlir_ciface_cutlass_launch_kernel2", visibility_ = 0 : i64}> ({
    %0 = "llvm.call"() <{CConv = #llvm.cconv<ccc>, TailCallKind = #llvm.tailcallkind<none>, callee = @cutlass_launch_kernel2, fastmathFlags = #llvm.fastmath<none>, op_bundle_sizes = array<i32>, operandSegmentSizes = array<i32: 0, 0>}> : () -> i32
    "llvm.return"(%0) : (i32) -> ()
  }) {llvm.emit_c_interface} : () -> ()
}) {gpu.container_module} : () -> ()
