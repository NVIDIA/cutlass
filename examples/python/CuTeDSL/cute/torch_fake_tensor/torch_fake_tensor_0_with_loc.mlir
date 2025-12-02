

!memref_generic_f32_ = !cute.memref<f32, generic, "(3,4):(4,1)">
#loc1 = loc(unknown)
module attributes {gpu.container_module} {
  gpu.module @kernels {
  } loc(#loc8)
  func.func @cutlass_print_tensor_Tensorgenerico3441(%arg0: !memref_generic_f32_ loc(unknown)) attributes {llvm.emit_c_interface} {
    %iter = cute.get_iter(%arg0) : !memref_generic_f32_ loc(#loc9)
    %iter_0 = cute.get_iter(%arg0) : !memref_generic_f32_ loc(#loc10)
    %lay = cute.get_layout(%arg0) : !memref_generic_f32_ loc(#loc11)
    %0 = cute.get_shape(%lay) : (!cute.layout<"(3,4):(4,1)">) -> !cute.shape<"(3,4)"> loc(#loc12)
    %e0, %e1 = cute.get_leaves(%0) : !cute.shape<"(3,4)"> loc(#loc12)
    %1 = cute.get_stride(%lay) : (!cute.layout<"(3,4):(4,1)">) -> !cute.stride<"(4,1)"> loc(#loc13)
    %e0_1, %e1_2 = cute.get_leaves(%1) : !cute.stride<"(4,1)"> loc(#loc13)
    cute.print_view(%arg0) {is_signed = false, verbose = false} : !memref_generic_f32_ loc(#loc14)
    return loc(#loc8)
  } loc(#loc8)
} loc(#loc8)
#loc = loc("/home/jayce.su/notes/dsl/cutlass_with_notes/examples/python/CuTeDSL/cute/torch_fake_tensor.py":78:22)
#loc2 = loc("/usr/local/lib/python3.12/dist-packages/nvidia_cutlass_dsl/python_packages/cutlass/base_dsl/dsl.py":656:19)
#loc3 = loc("/usr/local/lib/python3.12/dist-packages/nvidia_cutlass_dsl/python_packages/cutlass/cute/runtime.py":358:15)
#loc4 = loc("/usr/local/lib/python3.12/dist-packages/nvidia_cutlass_dsl/python_packages/cutlass/cute/tensor.py":156:66)
#loc5 = loc("/usr/local/lib/python3.12/dist-packages/nvidia_cutlass_dsl/python_packages/cutlass/cute/core.py":800:29)
#loc6 = loc("/usr/local/lib/python3.12/dist-packages/nvidia_cutlass_dsl/python_packages/cutlass/cute/core.py":800:54)
#loc7 = loc("/home/jayce.su/notes/dsl/cutlass_with_notes/examples/python/CuTeDSL/cute/torch_fake_tensor.py":69:4)
#loc8 = loc("compiled_fn = cute.compile(print_tensor, from_dlpack(fake_tensor))"(#loc))
#loc9 = loc("fop_args = list(fop.regions[0].blocks[0].arguments)"(#loc2))
#loc10 = loc("return CoreTensor(values[0].value, self._dtype)"(#loc3))
#loc11 = loc("return f\22tensor<{pretty_str(self.iterator)} o {pretty_str(self.layout)}>\22"(#loc4))
#loc12 = loc("return f\22{pretty_str(self.shape)}:{pretty_str(self.stride)}\22"(#loc5))
#loc13 = loc("return f\22{pretty_str(self.shape)}:{pretty_str(self.stride)}\22"(#loc6))
#loc14 = loc("cute.print_tensor(t)"(#loc7))

