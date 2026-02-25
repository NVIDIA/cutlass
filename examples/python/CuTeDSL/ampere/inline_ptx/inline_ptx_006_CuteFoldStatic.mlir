!memref_gmem_i32_ = !cute.memref<i32, gmem, "(?):(1)">
!memref_gmem_i8_ = !cute.memref<i8, gmem, "(?):(1)">
"builtin.module"() ({
  "gpu.module"() <{sym_name = "kernels"}> ({
    "cuda.kernel"() <{arg_attrs = [{}, {}, {}, {}], function_type = (!memref_gmem_i32_, !memref_gmem_i8_, !memref_gmem_i8_, !memref_gmem_i8_) -> (), sym_name = "kernel_cutlass_vote_kernel_tensorptri32gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_False_0"}> ({
    ^bb0(%arg4: !memref_gmem_i32_, %arg5: !memref_gmem_i8_, %arg6: !memref_gmem_i8_, %arg7: !memref_gmem_i8_):
      %12 = "nvvm.read.ptx.sreg.tid.x"() : () -> i32
      %13 = "arith.constant"() <{value = 10 : i32}> : () -> i32
      %14 = "arith.cmpi"(%12, %13) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %15 = "arith.constant"() <{value = -1 : i32}> : () -> i32
      %16 = "nvvm.vote.ballot.sync"(%15, %14) : (i32, i1) -> i32
      %17 = "arith.cmpi"(%12, %13) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %18 = "arith.constant"() <{value = -1 : i32}> : () -> i32
      %19 = "llvm.inline_asm"(%17, %18) <{asm_dialect = 0 : i64, asm_string = "{\0A\09\0A            .reg .pred ps;\0A\09\0A            .reg .pred pd;\0A\09\0A            setp.ne.b32 ps, $1, 0;\0A\09\0A            vote.sync.any.pred pd, ps, $2;\0A\09\0A            selp.b32 $0, 1, 0, pd;\0A\09\0A            }", constraints = "=r,r,i", has_side_effects}> : (i1, i32) -> i1
      %20 = "arith.cmpi"(%12, %13) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %21 = "arith.constant"() <{value = -1 : i32}> : () -> i32
      %22 = "llvm.inline_asm"(%20, %21) <{asm_dialect = 0 : i64, asm_string = "{\0A\09\0A            .reg .pred ps;\0A\09\0A            .reg .pred pd;\0A\09\0A            setp.ne.b32 ps, $1, 0;\0A\09\0A            vote.sync.all.pred pd, ps, $2;\0A\09\0A            selp.b32 $0, 1, 0, pd;\0A\09\0A            }", constraints = "=r,r,i", has_side_effects}> : (i1, i32) -> i1
      %23 = "arith.cmpi"(%12, %13) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %24 = "arith.constant"() <{value = -1 : i32}> : () -> i32
      %25 = "llvm.inline_asm"(%23, %24) <{asm_dialect = 0 : i64, asm_string = "{\0A\09\0A            .reg .pred ps;\0A\09\0A            .reg .pred pd;\0A\09\0A            setp.ne.b32 ps, $1, 0;\0A\09\0A            vote.sync.uni.pred pd, ps, $2;\0A\09\0A            selp.b32 $0, 1, 0, pd;\0A\09\0A            }", constraints = "=r,r,i", has_side_effects}> : (i1, i32) -> i1
      %26 = "cute.make_coord"(%12) : (i32) -> !cute.coord<"?">
      "cute.memref.store"(%arg4, %26, %16) : (!memref_gmem_i32_, !cute.coord<"?">, i32) -> ()
      %27 = "arith.extui"(%19) : (i1) -> i8
      %28 = "cute.make_coord"(%12) : (i32) -> !cute.coord<"?">
      "cute.memref.store"(%arg5, %28, %27) : (!memref_gmem_i8_, !cute.coord<"?">, i8) -> ()
      %29 = "arith.extui"(%22) : (i1) -> i8
      %30 = "cute.make_coord"(%12) : (i32) -> !cute.coord<"?">
      "cute.memref.store"(%arg6, %30, %29) : (!memref_gmem_i8_, !cute.coord<"?">, i8) -> ()
      %31 = "arith.extui"(%25) : (i1) -> i8
      %32 = "cute.make_coord"(%12) : (i32) -> !cute.coord<"?">
      "cute.memref.store"(%arg7, %32, %31) : (!memref_gmem_i8_, !cute.coord<"?">, i8) -> ()
      "cuda.return"() : () -> ()
    }) {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 32, 1, 1>} : () -> ()
  }) : () -> ()
  "func.func"() <{function_type = (!memref_gmem_i32_, !memref_gmem_i8_, !memref_gmem_i8_, !memref_gmem_i8_) -> i32, sym_name = "cutlass_vote_Tensorgmemo1_Tensorgmemo1_Tensorgmemo1_Tensorgmemo1_False"}> ({
  ^bb0(%arg0: !memref_gmem_i32_, %arg1: !memref_gmem_i8_, %arg2: !memref_gmem_i8_, %arg3: !memref_gmem_i8_):
    %0 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    %1 = "arith.constant"() <{value = 0 : i64}> : () -> i64
    %2 = "cuda.cast"(%1) : (i64) -> !cuda.stream
    %3 = "arith.extsi"(%0) : (i32) -> i64
    %4 = "arith.constant"() <{value = 32 : i32}> : () -> i32
    %5 = "arith.constant"() <{value = 1 : i32}> : () -> i32
    %6 = "cuda.launch_cfg.create"(%4, %5, %5, %3, %5, %5, %5, %2) <{maxNumAttrs = 3 : i32}> : (i32, i32, i32, i64, i32, i32, i32, !cuda.stream) -> !cuda.launch_cfg<max_attrs = 3>
    %7 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    "cuda.launch_cfg.programmatic_stream_serialization_allowed"(%6, %7) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    %8 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    "cuda.launch_cfg.cooperative"(%6, %8) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    %9 = "cuda.launch_ex"(%6, %arg0, %arg1, %arg2, %arg3) <{assume_kernel_attr = #cuda.assume_kernel_attr<true>, callee = @kernels::@kernel_cutlass_vote_kernel_tensorptri32gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_False_0}> : (!cuda.launch_cfg<max_attrs = 3>, !memref_gmem_i32_, !memref_gmem_i8_, !memref_gmem_i8_, !memref_gmem_i8_) -> !cuda.result
    %10 = "cuda.cast"(%9) : (!cuda.result) -> i32
    "cuda.return_if_error"(%10) : (i32) -> ()
    %11 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    "func.return"(%11) : (i32) -> ()
  }) {llvm.emit_c_interface} : () -> ()
}) {gpu.container_module} : () -> ()
