"builtin.module"() ({
  "gpu.module"() <{sym_name = "kernels"}> ({
    "cuda.kernel"() <{arg_attrs = [], function_type = () -> (), sym_name = "kernel_cutlass_kernel_no_smem_0"}> ({
      %11 = "nvvm.read.ptx.sreg.ctaid.x"() : () -> i32
      %12 = "nvvm.read.ptx.sreg.ctaid.y"() : () -> i32
      %13 = "nvvm.read.ptx.sreg.ctaid.z"() : () -> i32
      %14 = "arith.constant"() <{value = 0 : i32}> : () -> i32
      %15 = "arith.cmpi"(%11, %14) <{predicate = 0 : i64}> : (i32, i32) -> i1
      "scf.if"(%15) ({
        "gpu.printf"() <{format = "Hello world\0A"}> : () -> ()
        "scf.yield"() : () -> ()
      }, {
      }) : (i1) -> ()
      "cuda.return"() : () -> ()
    }) {cu_attrs = {max_dynamic_shared_size_bytes = #cuda.dev_max_shared_memory_optin, non_portable_cluster_size_allowed = 1 : i32}, cute.kernel, gpu.kernel, nvvm.reqntid = array<i32: 1, 1, 1>} : () -> ()
  }) : () -> ()
  "func.func"() <{function_type = () -> i32, sym_name = "cutlass_launch_kernel2"}> ({
    %0 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    %1 = "arith.constant"() <{value = 0 : i64}> : () -> i64
    %2 = "cuda.cast"(%1) : (i64) -> !cuda.stream
    %3 = "arith.extsi"(%0) : (i32) -> i64
    %4 = "arith.constant"() <{value = 1 : i32}> : () -> i32
    %5 = "cuda.launch_cfg.create"(%4, %4, %4, %3, %4, %4, %4, %2) <{maxNumAttrs = 3 : i32}> : (i32, i32, i32, i64, i32, i32, i32, !cuda.stream) -> !cuda.launch_cfg<max_attrs = 3>
    %6 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    "cuda.launch_cfg.programmatic_stream_serialization_allowed"(%5, %6) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    %7 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    "cuda.launch_cfg.cooperative"(%5, %7) : (!cuda.launch_cfg<max_attrs = 3>, i32) -> ()
    %8 = "cuda.launch_ex"(%5) <{assume_kernel_attr = #cuda.assume_kernel_attr<true>, callee = @kernels::@kernel_cutlass_kernel_no_smem_0}> : (!cuda.launch_cfg<max_attrs = 3>) -> !cuda.result
    %9 = "cuda.cast"(%8) : (!cuda.result) -> i32
    "cuda.return_if_error"(%9) : (i32) -> ()
    %10 = "arith.constant"() <{value = 0 : i32}> : () -> i32
    "func.return"(%10) : (i32) -> ()
  }) {llvm.emit_c_interface} : () -> ()
}) {gpu.container_module} : () -> ()
