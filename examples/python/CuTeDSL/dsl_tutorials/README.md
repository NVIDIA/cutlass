# DSL Feature Examples

This directory demonstrates **CuTe DSL capabilities** beyond kernel authoring itself:
exporting compiled kernels for deployment, integrating with ML frameworks, using
foreign function interfaces, and accessing low-level DSL features like inline PTX
and shared memory allocation.

---

## Directory Structure

```
dsl/
  export/                        Exporting kernels to C shared libraries
    export_to_c.py                 Compile a kernel and export as .so/.dylib
    load_in_python.py              Load and call the exported library from Python
    run_with_dynamic_loading.cpp   C++ driver using dlopen
    run_with_dynamic_loading.sh    Build/run script for dynamic loading
    run_with_static_linking.cpp    C++ driver using static linking
    run_with_static_linking.sh     Build/run script for static linking
  ffi/                           Foreign function interface
    jit_argument.py                JIT compilation with argument passing
    tensor.cpp                     C++ tensor interop implementation
    CMakeLists.txt                 CMake build for FFI examples
  jax/                           JAX integration
    cutlass_call_basic.py          Basic CUTLASS kernel call from JAX
    cutlass_call_export.py         Export a CUTLASS kernel for JAX
    cutlass_call_sharding.py       Multi-device sharding with CUTLASS kernels
    elementwise_apply_example.py   Elementwise apply via JAX
  tvm_ffi/                       TVM FFI integration
    jit_and_use_in_torch.py        JIT compile and call from PyTorch
    jit_and_use_in_jax.py          JIT compile and call from JAX
    aot_export.py                  Ahead-of-time export
    aot_use_in_torch.py            Use AOT-exported kernel in PyTorch
    aot_use_in_jax.py              Use AOT-exported kernel in JAX
    aot_use_in_cpp_bundle.cpp      Use AOT-exported kernel in C++
    aot_use_in_cpp_bundle.sh       Build/run script for C++ AOT usage
    compile_with_fake_tensor.py    Compile using fake tensors
    compile_with_symint_arg.py     Compile with symbolic integer arguments
    ampere_gemm_with_fake_tensor.py  Ampere GEMM with fake tensor compilation
    error_reporting.py             Error reporting and diagnostics
  call_bypass_dlpack.py          Calling kernels bypassing DLPack
  call_from_jit.py               Calling conventions from JIT-compiled code
  cooperative_launch.py          Cooperative kernel launch (multi-CTA)
  dynamic_smem_size.py           Dynamic shared memory allocation
  inline_ptx.py                  Embedding inline PTX assembly
  launch_completion_and_programmatic_events.py
                                 Launch completion / programmatic events with cudaEvent_t and CUevent
  pointer.py                     Pointer manipulation in DSL
  print_latex.py                 LaTeX rendering of CuTe layouts
  programmatic_dependent_launch.py  Programmatic dependent launch (PDL)
  smem_allocator.py              Shared memory allocator usage
  torch_fake_tensor.py           PyTorch fake tensor integration
  torch_fp4.py                   PyTorch FP4 tensor support
```

---

## Subdirectory Guides

### `export/` -- Kernel Export

Shows how to compile a CuTe DSL kernel into a standalone C shared library (`.so`)
that can be loaded and called from C++ or Python without any CuTe DSL dependency
at runtime. Includes complete examples for both dynamic loading (`dlopen`) and
static linking workflows.

### `ffi/` -- Foreign Function Interface

Demonstrates how to pass arguments between Python/CuTe DSL and C++ code using
the FFI layer. Useful for integrating CuTe DSL kernels into existing C++
applications.

### `jax/` -- JAX Integration

Shows how to call CuTe DSL kernels from JAX using `cutlass_call`, including
basic invocation, kernel export for JAX, multi-device sharding, and elementwise
application patterns.

### `tvm_ffi/` -- TVM FFI Integration

Comprehensive examples for using CuTe DSL kernels through TVM's foreign function
interface. Covers both JIT and AOT (ahead-of-time) compilation workflows, with
usage examples for PyTorch, JAX, and C++. Also demonstrates fake-tensor
compilation (no GPU required at compile time) and symbolic integer arguments.

---

## Top-Level Files

The top-level Python files demonstrate individual DSL features:

- **`call_bypass_dlpack.py`** / **`call_from_jit.py`** -- Kernel calling conventions
- **`inline_ptx.py`** -- Embedding inline PTX assembly in CuTe DSL kernels
- **`launch_completion_and_programmatic_events.py`** -- Examples of 
  ``launch_completion_event`` and ``programmatic_event`` launch attributes,
  using events created via ``torch.cuda.Event(enable_timing=False)`` and
  presented as either ``cudaEvent_t`` (`cuda.bindings.runtime`) or ``CUevent`` (`cuda.bindings.driver`). The
  stream is passed as a ``cudaStream_t`` (`cuda.bindings.runtime`)
- **`programmatic_dependent_launch.py`** -- Programmatic dependent launch for
  chaining kernels with data dependencies
- **`cooperative_launch.py`** -- Cooperative launch for multi-CTA kernels
- **`dynamic_smem_size.py`** / **`smem_allocator.py`** -- Shared memory allocation
- **`torch_fake_tensor.py`** / **`torch_fp4.py`** -- PyTorch integration features
- **`pointer.py`** -- Pointer manipulation within DSL kernels
- **`print_latex.py`** -- Render CuTe layouts as LaTeX for visualization
