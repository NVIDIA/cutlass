.. _dsl_ahead_of_time_compilation:
.. |DSL| replace:: CuTe DSL

Ahead-of-Time (AOT) Compilation
===============================

This guide demonstrates how to use |DSL|'s Ahead-of-Time (AOT) compilation features to export compiled kernels for use in production environments.

Overview
--------

|DSL| Ahead-of-Time (hereinafter referred to as AOT) compilation allows you to:

* **Compile once, enable cross-compilation**: Write kernels in Python and cross-compile them for multiple GPU architectures.
* **Remove JIT overhead**: Eliminate compilation delays in production by pre-compiling kernels.
* **Flexible integration**: Easily integrate compiled kernels into both Python and C/C++ codebases using flexible deployment options.

We provide 2 levels of AOT ABI:

1. **Low-Level CuTe ABI**: This ABI is expressed using CuTe DSL types and tensors, mirroring the original Python function.
2. **High-Level Apache TVM FFI ABI**: For interop with various frameworks (e.g., PyTorch, JAX), and offer high-level stable ABI access.

This guide will focus on the CuTe ABI AOT. For the Apache TVM FFI AOT, please refer to the section "Exporting Compiled Module" in :doc:`compile_with_tvm_ffi`.

CuTe ABI AOT Workflow
---------------------

Export Interface
~~~~~~~~~~~~~~~~

The ``export_to_c`` interface is provided by the ``JitCompiledFunction`` class. It accepts the following parameters:

* ``file_path``: The path to the directory where the header and object files will be saved.
* ``file_name``: The base name for the header and object files. The same file name will always overwrite existing files.
* ``function_prefix``: The prefix of the function symbol in the generated object file. This should be a unique identifier to avoid symbol conflicts. Users should ensure the function prefix is unique for each exported function. Defaults to the ``file_name``.

It generates the following files:

* ``{file_path}/{file_name}.h``: A C header file containing API function declarations. This header specifies the runtime function signatures in C, mirroring the original Python function interfaces.
* ``{file_path}/{file_name}.o``: A standard object file containing the compiled kernel code. You can link this object file into either a static or shared library. It includes the host entry function, fatbin data, and helper functions such as ``cuda_init`` and ``cuda_load_to_device``. Additionally, it embeds metadata for runtime loading and version verification.

Example:

.. code-block:: python

   import cutlass.cute as cute
   import cutlass.cute.cuda as cuda

   @cute.kernel
   def print_tensor_kernel(a: cute.Tensor):
       cute.printf("a: {}", a)

   @cute.jit
   def print_tensor(a: cute.Tensor, stream: cuda.CUstream):
       print_tensor_kernel(a).launch(grid=(1, 1, 1), block=(1, 1, 1), stream=stream)

   compiled_func = cute.compile(print_tensor)
   # Export compiled functions to object files and headers
   compiled_func.export_to_c(file_path="./artifacts", file_name="print_tensor_example", function_prefix="print_tensor")

Loading in Python
~~~~~~~~~~~~~~~~~

Load pre-compiled object files or shared libraries into Python for execution.

.. code-block:: python

   import cutlass.cute as cute
   import torch
   from cutlass.cute import from_dlpack
   import cutlass.cute.cuda as cuda
   
   # Load module from object file
   module = cute.runtime.load_module("./artifacts/print_tensor_example.o")
   # or
   module = cute.runtime.load_module("./artifacts/libprint_tensor_example.so")

   # Prepare data
   a = torch.arange(160, dtype=torch.float32, device="cuda").reshape(16, 10)
   a_cute = from_dlpack(a).mark_layout_dynamic()
   stream = cuda.CUstream(0)  

   # Call the function (no JIT compilation needed!)
   module.print_tensor(a_cute, stream=stream)
   
   # This will fail because 'non_existing_api' was not exported:
   # module.non_existing_api()

C++ Integration with Static Linking
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Integrate compiled kernels directly into your C++ executable during the build process. The generated header file supplies the necessary API for loading the module and invoking the function.

Example:

.. code-block:: cpp

   #include "print_tensor_example.h"
   #include <cuda_runtime.h>

   void run_print_tensor() {
       // Prepare tensor, the tensor declaration is in the header file
       print_tensor_Tensor_a_t tensor_a;
       tensor_a.data = nullptr; // GPU memory is set to nullptr.
       // Set dynamic shapes and strides
       tensor_a.dynamic_shapes[0] = 32;
       tensor_a.dynamic_shapes[1] = 16;
       tensor_a.dynamic_strides[0] = 16;
       
       // Create stream
       cudaStream_t stream;
       cudaStreamCreate(&stream);
       
       // Load module before calling the kernel
       print_tensor_Kernel_Module_t module;
       print_tensor_Kernel_Module_Load(&module);
       
       // Call the kernel; the kernel wrapper function is defined in the header file
       cute_dsl_print_tensor_wrapper(&module, &tensor_a, stream);
       
       // Cleanup
       print_tensor_Kernel_Module_Unload(&module);
       cudaStreamDestroy(stream);
   }

The ``print_tensor_example.h`` header file is generated by the ``export_to_c`` interface. It includes:

* The ``print_tensor_Kernel_Module_t`` type: Represents the kernel module.
* The ``print_tensor_Tensor_a_t`` type: A tensor-specific type that defines the ABI for a particular CuTe tensor.
* The ``cute_dsl_print_tensor_wrapper`` function: The user-facing entry point to invoke the kernel.

The compilation of the C++ executable requires the ``libcuda_dialect_runtime.so`` or ``libcuda_dialect_runtime_static.a`` library which is involved in ``<wheel_install_path>/lib``, along with the CUDA driver and runtime libraries, to function properly.


C++ Integration with Dynamic Loading
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Dynamically load pre-compiled object files or shared libraries at runtime. By including the ``CuteDSLRuntime.h`` header, you can load the module, look up exported functions, and invoke them.

.. code-block:: cpp

   #include "CuteDSLRuntime.h"
   #include <cuda_runtime.h>

   void run_print_tensor() {
       // Load module from shared library
       CuteDSLRT_Module_t *module = nullptr;
       CuteDSLRT_Error_t err = CuteDSLRT_Module_Load(
           &module, 
           "./artifacts/libprint_tensor_example.so"
       );
       // or
       CuteDSLRT_Error_t err = CuteDSLRT_Module_Load(
           &module, 
           "./artifacts/print_tensor_example.o"
       );
       check_error(err);
       
       // Lookup function
       CuteDSLRT_Function_t *func = nullptr;
       err = CuteDSLRT_Module_Get_Function(&func, module, "print_tensor");
       check_error(err);
       
       // Prepare arguments, matching the argument type defined in the header file
       typedef struct {
           void *data;
           int32_t dynamic_shapes[2];
           int64_t dynamic_strides[1];
       } print_tensor_Tensor_a_t;

       print_tensor_Tensor_a_t tensor_a;
       tensor_a.data = nullptr;
       tensor_a.dynamic_shapes[0] = 32;
       tensor_a.dynamic_shapes[1] = 16;
       tensor_a.dynamic_strides[0] = 16;

       // Create stream
       cudaStream_t stream;
       cudaStreamCreate(&stream);

       // Call the function; the runtime function accepts packed arguments, refer to the wrapper in the header file
       int ret;
       void* args[] = {&tensor_a, &stream, &ret};
       err = CuteDSLRT_Function_Run(func, args, 3);
       check_error(err);
       cudaStreamSynchronize(stream);
       
       // Cleanup
       CuteDSLRT_Module_Destroy(module);
       cudaStreamDestroy(stream);
   }

The ``CuteDSLRuntime.h`` header file can be found in ``<wheel_install_path>/include``. It includes:

* The ``CuteDSLRT_Error_t`` type: Indicates error status.
* The ``CuteDSLRT_Module_Load`` function: Loads the module.
* The ``CuteDSLRT_Module_Get_Function`` function: Gets a function from the loaded module. The runtime API will load the CUDA module for kernel execution.
* The ``CuteDSLRT_Function_Run`` function: Runs the function.
* The ``CuteDSLRT_Module_Destroy`` function: Destroys the module.

The compilation of the C++ executable requires the ``libcute_dsl_runtime.so`` library which is involved in ``<wheel_install_path>/lib``, along with the CUDA driver and runtime libraries, to function properly.

Supported Argument Types
------------------------

|DSL| supports the following argument types:

* ``cute.Tensor``
* ``cute.Shape`` / ``cute.Coord`` / ``cute.Tile`` / ``cute.IntTuple`` / ``cute.Stride``
* ``cuda.CUstream``
* ``cutlass.Int8`` / ``cutlass.Int16`` / ``cutlass.Int32`` / ``cutlass.Int64`` / ``cutlass.Boolean``
* ``cutlass.Uint8`` / ``cutlass.Uint16`` / ``cutlass.Uint32`` / ``cutlass.Uint64``
* ``cutlass.Float32`` / ``cutlass.TFloat32`` / ``cutlass.Float64`` / ``cutlass.Float16``

Note that:

1. ``cute.Tensor`` is a dynamic tensor type that only contains dynamic shapes and strides in its ABI representation. As a result, different compilations may produce different tensor ABIs. This is why declarations for each tensor type are included in the generated header file.
2. ``strides`` in ``cute.Tensor`` are determined by the ``use_32bit_strides`` compile argument. When ``use_32bit_strides`` is set to ``True``, the strides are 32-bit; when set to ``False``, they are 64-bit.
3. Currently, custom types are not supported for AOT compilation.

Object File Compatibility Issues
--------------------------------

The object file generated by |DSL| depends on the CUDA runtime library. Therefore, ensure that the version of the CUDA runtime/toolkit library matches the version used by |DSL|. Otherwise, ABI compatibility with the CUDA runtime cannot be guaranteed.

When using C++ static linking integration, compatibility is assured because the header and object files are generated together and guaranteed to match.

For C++ dynamic loading integration and Python loading, the binary file is loaded at runtime. To ensure compatibility, version information is embedded in the metadata of the generated binary file. At runtime, this version information is checked, and if it does not match the expected version, the binary file will be rejected.

Relation to Apache TVM FFI AOT
------------------------------

Apache TVM FFI AOT offers a comparable capability, enabling TVM functions to be compiled into binary files that can be loaded and executed at runtime.
For more information, see the section "Exporting Compiled Module" in :doc:`compile_with_tvm_ffi`.

The primary distinction is that, when TVM FFI is enabled, |DSL| generates a dedicated wrapper function on top of the underlying CuTe ABI. This wrapper adheres to the calling conventions defined by TVM FFI.
In contrast, the CuTe ABI entry function is specified directly in the generated header file, which affects how arguments must be provided.

For instance, with the TVM FFI wrapper function, users are able to pass in arguments such as ``torch.Tensor`` directly. However, when calling the CuTe ABI entry function, arguments should be provided as ``cute.Tensor`` types.