!memref_gmem_i32_ = !cute.memref<i32, gmem, "(?):(1)">
!memref_gmem_i8_ = !cute.memref<i8, gmem, "(?):(1)">
"builtin.module"() ({
  "gpu.module"() <{sym_name = "kernels"}> ({
    "cuda.kernel"() <{arg_attrs = [{}, {}, {}, {}], function_type = (!memref_gmem_i32_, !memref_gmem_i8_, !memref_gmem_i8_, !memref_gmem_i8_) -> (), sym_name = "kernel_cutlass_vote_kernel_tensorptri32gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_False_0"}> ({
    ^bb0(%arg4: !memref_gmem_i32_, %arg5: !memref_gmem_i8_, %arg6: !memref_gmem_i8_, %arg7: !memref_gmem_i8_):
      %8 = "arith.constant"() <{value = -1 : i32}> : () -> i32
      %9 = "arith.constant"() <{value = 10 : i32}> : () -> i32
      %10 = "nvvm.read.ptx.sreg.tid.x"() <{range = #llvm.constant_range<i32, 0, 1024>}> : () -> i32
      %11 = "arith.cmpi"(%10, %9) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %12 = "nvvm.vote.ballot.sync"(%8, %11) : (i32, i1) -> i32
      %13 = "arith.cmpi"(%10, %9) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %14 = "llvm.inline_asm"(%13, %8) <{asm_dialect = 0 : i64, asm_string = "{\0A\09\0A            .reg .pred ps;\0A\09\0A            .reg .pred pd;\0A\09\0A            setp.ne.b32 ps, $1, 0;\0A\09\0A            vote.sync.any.pred pd, ps, $2;\0A\09\0A            selp.b32 $0, 1, 0, pd;\0A\09\0A            }", constraints = "=r,r,i", has_side_effects}> : (i1, i32) -> i1
      %15 = "arith.cmpi"(%10, %9) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %16 = "llvm.inline_asm"(%15, %8) <{asm_dialect = 0 : i64, asm_string = "{\0A\09\0A            .reg .pred ps;\0A\09\0A            .reg .pred pd;\0A\09\0A            setp.ne.b32 ps, $1, 0;\0A\09\0A            vote.sync.all.pred pd, ps, $2;\0A\09\0A            selp.b32 $0, 1, 0, pd;\0A\09\0A            }", constraints = "=r,r,i", has_side_effects}> : (i1, i32) -> i1
      %17 = "arith.cmpi"(%10, %9) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %18 = "llvm.inline_asm"(%17, %8) <{asm_dialect = 0 : i64, asm_string = "{\0A\09\0A            .reg .pred ps;\0A\09\0A            .reg .pred pd;\0A\09\0A            setp.ne.b32 ps, $1, 0;\0A\09\0A            vote.sync.uni.pred pd, ps, $2;\0A\09\0A            selp.b32 $0, 1, 0, pd;\0A\09\0A            }", constraints = "=r,r,i", has_side_effects}> : (i1, i32) -> i1
      %19 = "cute.make_coord"(%10) : (i32) -> !cute.coord<"?">
      "cute.memref.store"(%arg4, %19, %12) : (!memref_gmem_i32_, !cute.coord<"?">, i32) -> ()
      %20 = "arith.extui"(%14) : (i1) -> i8
      %21 = "cute.make_coord"(%10) : (i32) -> !cute.coord<"?">
      "cute.memref.store"(%arg5, %21, %20) : (!memref_gmem_i8_, !cute.coord<"?">, i8) -> ()
      %22 = "arith.extui"(%16) : (i1) -> i8
      %23 = "cute.make_coord"(%10) : (i32) -> !cute.coord<"?">
      "cute.memref.store"(%arg6, %23, %22) : (!memref_gmem_i8_, !cute.coord<"?">, i8) -> ()
      %24 = "arith.extui"(%18) : (i1) -> i8
      %25 = "cute.make_coord"(%10) : (i32) -> !cute.coord<"?">
      "cute.memref.store"(%arg7, %25, %24) : (!memref_gmem_i8_, !cute.coord<"?">, i8) -> ()
      "cuda.return"() : () -> ()
    }) {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 32, 1, 1>} : () -> ()
  }) : () -> ()
  "func.func"() <{function_type = (!memref_gmem_i32_, !memref_gmem_i8_, !memref_gmem_i8_, !memref_gmem_i8_) -> i32, sym_name = "cutlass_vote_Tensorgmemo1_Tensorgmemo1_Tensorgmemo1_Tensorgmemo1_False"}> ({
  ^bb0(%arg0: !memref_gmem_i32_, %arg1: !memref_gmem_i8_, %arg2: !memref_gmem_i8_, %arg3: !memref_gmem_i8_):
    %0 = "arith.constant"() <{value = 1 : i32}> : () -> i32
    %1 = "arith.constant"() <{value = 32 : i32}> : () -> i32
    %2 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    %3 = "arith.constant"() <{value = 0 : i64}> : () -> i64
    %4 = "cuda.cast"(%3) : (i64) -> !cuda.stream
    %5 = "cuda.launch_cfg.create"(%1, %0, %0, %3, %0, %0, %0, %4) <{maxNumAttrs = 3 : i32}> : (i32, i32, i32, i64, i32, i32, i32, !cuda.stream) -> !cuda.launch_cfg<max_attrs = 3>
    "cuda.launch_cfg.programmatic_stream_serialization_allowed"(%5, %2) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    "cuda.launch_cfg.cooperative"(%5, %2) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    %6 = "cuda.launch_ex"(%5, %arg0, %arg1, %arg2, %arg3) <{assume_kernel_attr = #cuda.assume_kernel_attr<true>, callee = @kernels::@kernel_cutlass_vote_kernel_tensorptri32gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_False_0}> : (!cuda.launch_cfg<max_attrs = 3>, !memref_gmem_i32_, !memref_gmem_i8_, !memref_gmem_i8_, !memref_gmem_i8_) -> !cuda.result
    %7 = "cuda.cast"(%6) : (!cuda.result) -> i32
    "cuda.return_if_error"(%7) : (i32) -> ()
    "func.return"(%2) : (i32) -> ()
  }) {llvm.emit_c_interface} : () -> ()
}) {gpu.container_module} : () -> ()
