!memref_gmem_i32_ = !cute.memref<i32, gmem, "(?):(1)">
!memref_gmem_i8_ = !cute.memref<i8, gmem, "(?):(1)">
"builtin.module"() ({
  "gpu.module"() <{sym_name = "kernels"}> ({
    "cuda.kernel"() <{arg_attrs = [{}, {}, {}, {}], function_type = (!memref_gmem_i32_, !memref_gmem_i8_, !memref_gmem_i8_, !memref_gmem_i8_) -> (), sym_name = "kernel_cutlass_vote_kernel_tensorptri32gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_False_0"}> ({
    ^bb0(%arg4: !memref_gmem_i32_, %arg5: !memref_gmem_i8_, %arg6: !memref_gmem_i8_, %arg7: !memref_gmem_i8_):
      %31 = "cute.get_iter"(%arg4) : (!memref_gmem_i32_) -> !cute.ptr<i32, gmem>
      %32 = "cute.get_iter"(%arg5) : (!memref_gmem_i8_) -> !cute.ptr<i8, gmem>
      %33 = "cute.get_iter"(%arg6) : (!memref_gmem_i8_) -> !cute.ptr<i8, gmem>
      %34 = "cute.get_iter"(%arg7) : (!memref_gmem_i8_) -> !cute.ptr<i8, gmem>
      %35 = "cute.get_iter"(%arg4) : (!memref_gmem_i32_) -> !cute.ptr<i32, gmem>
      %36 = "cute.get_iter"(%arg5) : (!memref_gmem_i8_) -> !cute.ptr<i8, gmem>
      %37 = "cute.get_iter"(%arg6) : (!memref_gmem_i8_) -> !cute.ptr<i8, gmem>
      %38 = "cute.get_iter"(%arg7) : (!memref_gmem_i8_) -> !cute.ptr<i8, gmem>
      %39 = "cute.get_layout"(%arg4) : (!memref_gmem_i32_) -> !cute.layout<"(?):(1)">
      %40 = "cute.get_layout"(%arg5) : (!memref_gmem_i8_) -> !cute.layout<"(?):(1)">
      %41 = "cute.get_layout"(%arg6) : (!memref_gmem_i8_) -> !cute.layout<"(?):(1)">
      %42 = "cute.get_layout"(%arg7) : (!memref_gmem_i8_) -> !cute.layout<"(?):(1)">
      %43 = "cute.get_layout"(%arg4) : (!memref_gmem_i32_) -> !cute.layout<"(?):(1)">
      %44 = "cute.get_layout"(%arg5) : (!memref_gmem_i8_) -> !cute.layout<"(?):(1)">
      %45 = "cute.get_layout"(%arg6) : (!memref_gmem_i8_) -> !cute.layout<"(?):(1)">
      %46 = "cute.get_layout"(%arg7) : (!memref_gmem_i8_) -> !cute.layout<"(?):(1)">
      %47 = "nvvm.read.ptx.sreg.tid.x"() : () -> i32
      %48 = "nvvm.read.ptx.sreg.tid.y"() : () -> i32
      %49 = "nvvm.read.ptx.sreg.tid.z"() : () -> i32
      %50 = "arith.constant"() <{value = 10 : i32}> : () -> i32
      %51 = "arith.cmpi"(%47, %50) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %52 = "arith.constant"() <{value = -1 : i32}> : () -> i32
      %53 = "nvvm.vote.ballot.sync"(%52, %51) : (i32, i1) -> i32
      %54 = "arith.cmpi"(%47, %50) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %55 = "arith.constant"() <{value = -1 : i32}> : () -> i32
      %56 = "llvm.inline_asm"(%54, %55) <{asm_dialect = 0 : i64, asm_string = "{\0A\09\0A            .reg .pred ps;\0A\09\0A            .reg .pred pd;\0A\09\0A            setp.ne.b32 ps, $1, 0;\0A\09\0A            vote.sync.any.pred pd, ps, $2;\0A\09\0A            selp.b32 $0, 1, 0, pd;\0A\09\0A            }", constraints = "=r,r,i", has_side_effects}> : (i1, i32) -> i1
      %57 = "arith.cmpi"(%47, %50) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %58 = "arith.constant"() <{value = -1 : i32}> : () -> i32
      %59 = "llvm.inline_asm"(%57, %58) <{asm_dialect = 0 : i64, asm_string = "{\0A\09\0A            .reg .pred ps;\0A\09\0A            .reg .pred pd;\0A\09\0A            setp.ne.b32 ps, $1, 0;\0A\09\0A            vote.sync.all.pred pd, ps, $2;\0A\09\0A            selp.b32 $0, 1, 0, pd;\0A\09\0A            }", constraints = "=r,r,i", has_side_effects}> : (i1, i32) -> i1
      %60 = "arith.cmpi"(%47, %50) <{predicate = 2 : i64}> : (i32, i32) -> i1
      %61 = "arith.constant"() <{value = -1 : i32}> : () -> i32
      %62 = "llvm.inline_asm"(%60, %61) <{asm_dialect = 0 : i64, asm_string = "{\0A\09\0A            .reg .pred ps;\0A\09\0A            .reg .pred pd;\0A\09\0A            setp.ne.b32 ps, $1, 0;\0A\09\0A            vote.sync.uni.pred pd, ps, $2;\0A\09\0A            selp.b32 $0, 1, 0, pd;\0A\09\0A            }", constraints = "=r,r,i", has_side_effects}> : (i1, i32) -> i1
      %63 = "cute.make_coord"(%47) : (i32) -> !cute.coord<"?">
      "cute.memref.store"(%arg4, %63, %53) : (!memref_gmem_i32_, !cute.coord<"?">, i32) -> ()
      %64 = "arith.extui"(%56) : (i1) -> i8
      %65 = "cute.make_coord"(%47) : (i32) -> !cute.coord<"?">
      "cute.memref.store"(%arg5, %65, %64) : (!memref_gmem_i8_, !cute.coord<"?">, i8) -> ()
      %66 = "arith.extui"(%59) : (i1) -> i8
      %67 = "cute.make_coord"(%47) : (i32) -> !cute.coord<"?">
      "cute.memref.store"(%arg6, %67, %66) : (!memref_gmem_i8_, !cute.coord<"?">, i8) -> ()
      %68 = "arith.extui"(%62) : (i1) -> i8
      %69 = "cute.make_coord"(%47) : (i32) -> !cute.coord<"?">
      "cute.memref.store"(%arg7, %69, %68) : (!memref_gmem_i8_, !cute.coord<"?">, i8) -> ()
      "cuda.return"() : () -> ()
    }) {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 32, 1, 1>} : () -> ()
  }) : () -> ()
  "func.func"() <{function_type = (!memref_gmem_i32_, !memref_gmem_i8_, !memref_gmem_i8_, !memref_gmem_i8_) -> i32, sym_name = "cutlass_vote_Tensorgmemo1_Tensorgmemo1_Tensorgmemo1_Tensorgmemo1_False"}> ({
  ^bb0(%arg0: !memref_gmem_i32_, %arg1: !memref_gmem_i8_, %arg2: !memref_gmem_i8_, %arg3: !memref_gmem_i8_):
    %0 = "cute.get_iter"(%arg0) : (!memref_gmem_i32_) -> !cute.ptr<i32, gmem>
    %1 = "cute.get_iter"(%arg1) : (!memref_gmem_i8_) -> !cute.ptr<i8, gmem>
    %2 = "cute.get_iter"(%arg2) : (!memref_gmem_i8_) -> !cute.ptr<i8, gmem>
    %3 = "cute.get_iter"(%arg3) : (!memref_gmem_i8_) -> !cute.ptr<i8, gmem>
    %4 = "cute.get_iter"(%arg0) : (!memref_gmem_i32_) -> !cute.ptr<i32, gmem>
    %5 = "cute.get_iter"(%arg1) : (!memref_gmem_i8_) -> !cute.ptr<i8, gmem>
    %6 = "cute.get_iter"(%arg2) : (!memref_gmem_i8_) -> !cute.ptr<i8, gmem>
    %7 = "cute.get_iter"(%arg3) : (!memref_gmem_i8_) -> !cute.ptr<i8, gmem>
    %8 = "cute.get_layout"(%arg0) : (!memref_gmem_i32_) -> !cute.layout<"(?):(1)">
    %9 = "cute.get_layout"(%arg1) : (!memref_gmem_i8_) -> !cute.layout<"(?):(1)">
    %10 = "cute.get_layout"(%arg2) : (!memref_gmem_i8_) -> !cute.layout<"(?):(1)">
    %11 = "cute.get_layout"(%arg3) : (!memref_gmem_i8_) -> !cute.layout<"(?):(1)">
    %12 = "cute.make_int_tuple"() : () -> !cute.int_tuple<"32">
    %13 = "cute.size"(%12) <{mode = array<i32: 0>}> : (!cute.int_tuple<"32">) -> !cute.int_tuple<"32">
    %14 = "cute.get_leaves"(%13) : (!cute.int_tuple<"32">) -> !cute.int_tuple<"32">
    %15 = "cute.get_layout"(%arg0) : (!memref_gmem_i32_) -> !cute.layout<"(?):(1)">
    %16 = "cute.get_layout"(%arg1) : (!memref_gmem_i8_) -> !cute.layout<"(?):(1)">
    %17 = "cute.get_layout"(%arg2) : (!memref_gmem_i8_) -> !cute.layout<"(?):(1)">
    %18 = "cute.get_layout"(%arg3) : (!memref_gmem_i8_) -> !cute.layout<"(?):(1)">
    %19 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    %20 = "arith.constant"() <{value = 0 : i64}> : () -> i64
    %21 = "cuda.cast"(%20) : (i64) -> !cuda.stream
    %22 = "arith.extsi"(%19) : (i32) -> i64
    %23 = "arith.constant"() <{value = 32 : i32}> : () -> i32
    %24 = "arith.constant"() <{value = 1 : i32}> : () -> i32
    %25 = "cuda.launch_cfg.create"(%23, %24, %24, %22, %24, %24, %24, %21) <{maxNumAttrs = 3 : i32}> : (i32, i32, i32, i64, i32, i32, i32, !cuda.stream) -> !cuda.launch_cfg<max_attrs = 3>
    %26 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    "cuda.launch_cfg.programmatic_stream_serialization_allowed"(%25, %26) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    %27 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    "cuda.launch_cfg.cooperative"(%25, %27) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    %28 = "cuda.launch_ex"(%25, %arg0, %arg1, %arg2, %arg3) <{assume_kernel_attr = #cuda.assume_kernel_attr<true>, callee = @kernels::@kernel_cutlass_vote_kernel_tensorptri32gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_tensorptri8gmemo1_False_0}> : (!cuda.launch_cfg<max_attrs = 3>, !memref_gmem_i32_, !memref_gmem_i8_, !memref_gmem_i8_, !memref_gmem_i8_) -> !cuda.result
    %29 = "cuda.cast"(%28) : (!cuda.result) -> i32
    "cuda.return_if_error"(%29) : (i32) -> ()
    %30 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    "func.return"(%30) : (i32) -> ()
  }) {llvm.emit_c_interface} : () -> ()
}) {gpu.container_module} : () -> ()
