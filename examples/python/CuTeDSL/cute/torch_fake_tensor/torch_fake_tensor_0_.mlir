!memref_generic_f32_ = !cute.memref<f32, generic, "(3,4):(4,1)">
module attributes {gpu.container_module} {
  gpu.module @kernels {
  }
  func.func @cutlass_print_tensor_Tensorgenerico3441(%arg0: !memref_generic_f32_) attributes {llvm.emit_c_interface} {
    %iter = cute.get_iter(%arg0) : !memref_generic_f32_
    %iter_0 = cute.get_iter(%arg0) : !memref_generic_f32_
    %lay = cute.get_layout(%arg0) : !memref_generic_f32_
    %0 = cute.get_shape(%lay) : (!cute.layout<"(3,4):(4,1)">) -> !cute.shape<"(3,4)">
    %e0, %e1 = cute.get_leaves(%0) : !cute.shape<"(3,4)">
    %1 = cute.get_stride(%lay) : (!cute.layout<"(3,4):(4,1)">) -> !cute.stride<"(4,1)">
    %e0_1, %e1_2 = cute.get_leaves(%1) : !cute.stride<"(4,1)">
    cute.print_view(%arg0) {is_signed = false, verbose = false} : !memref_generic_f32_
    return
  }
}
