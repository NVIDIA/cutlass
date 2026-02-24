"builtin.module"() ({
  "gpu.module"() <{sym_name = "kernels"}> ({
    "cuda.kernel"() <{arg_attrs = [], function_type = () -> (), sym_name = "kernel_cutlass_kernel_no_smem_0"}> ({
      %7 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      %8 = "nvvm.read.ptx.sreg.ctaid.x"() <{range = #llvm.constant_range<i32, 0, 2147483647>}> : () -> i32
      %9 = "arith.cmpi"(%8, %7) <{predicate = 0 : i64}> : (i32, i32) -> i1
      "scf.if"(%9) ({
        "gpu.printf"() <{format = "Hello world\0A"}> : () -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      "cuda.return"() : () -> ()
    }) {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 1, 1, 1>} : () -> ()
  }) : () -> ()
  "func.func"() <{function_type = () -> i32, sym_name = "cutlass_launch_kernel2"}> ({
    %0 = "arith.constant"() <{value = 1 : i32}> : () -> i32
    %1 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    %2 = "arith.constant"() <{value = 0 : i64}> : () -> i64
    %3 = "cuda.cast"(%2) : (i64) -> !cuda.stream
    %4 = "cuda.launch_cfg.create"(%0, %0, %0, %2, %0, %0, %0, %3) <{maxNumAttrs = 3 : i32}> : (i32, i32, i32, i64, i32, i32, i32, !cuda.stream) -> !cuda.launch_cfg<max_attrs = 3>
    "cuda.launch_cfg.programmatic_stream_serialization_allowed"(%4, %1) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    "cuda.launch_cfg.cooperative"(%4, %1) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    %5 = "cuda.launch_ex"(%4) <{assume_kernel_attr = #cuda.assume_kernel_attr<true>, callee = @kernels::@kernel_cutlass_kernel_no_smem_0}> : (!cuda.launch_cfg<max_attrs = 3>) -> !cuda.result
    %6 = "cuda.cast"(%5) : (!cuda.result) -> i32
    "cuda.return_if_error"(%6) : (i32) -> ()
    "func.return"(%1) : (i32) -> ()
  }) {llvm.emit_c_interface} : () -> ()
}) {gpu.container_module} : () -> ()
