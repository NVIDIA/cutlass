# SYCL support for CUTLASS

This repository contains a development version of the CUTLASS repository
with experimental SYCL support enabled. The aim is to
support other SYCL-enabled devices with the minimal source code modifications by using the same CUTLASS features.
possible, facilitating maintenance.
Given that most of the backend work happens on the CUTE implementation,
the CUTLASS interface remains the same, and the SYCL support only needs 
changes at the atom and pipeline level.

SYCL[1] is a royalty-free, cross-platform abstraction layer that enables
code for heterogeneous and offload processors to be written with modern 
ISO C++, and provides API and abstractions to find devices and manage 
resources for GPUs. 

## What works

Currently, only one example works on NVIDIA SM 80.

## Building with SYCL support

To build CUTLASS SYCL support you need the latest version of DPC++ compiler, 
you can either use a recent [nighly build](https://github.com/intel/llvm/releases)
or build the compiler from source.
In either case, make sure to enable the NVIDIA plugin so you can build applications
for NVIDIA GPUs.

Once you have your compiler installed, you need to point the
`CMAKE_CUDA_HOST_COMPILER` flag to the clang++ provided by it.
This enables the compilation of SYCL sources without altering the current NVCC path.

```
make -G Ninja  \
  -DCMAKE_C_COMPILER_WORKS=1  \
  -DCMAKE_CXX_COMPILER_WORKS=1  \
  -DCUTLASS_NVCC_ARCHS=80  \
  -DCUTLASS_ENABLE_CUBLAS=ON \ 
  -DCMAKE_CUDA_HOST_COMPILER=/path/to/clang++  \
  -DCMAKE_CUDA_COMPILER=/path/to/nvcc \ 
  -DCMAKE_CUDA_FLAGS="--allow-unsupported-compiler" \
  -DCUTLASS_ENABLE_SYCL=ON 
```


# Running the example

Currently, you can build the CuTe Tutorial using the following command: 

```
ninja sgemm_nt_1_sycl
```

You can run it like this from your build directory

```
LD_LIBRARY_PATH=/path/to/sycl/install/lib ./examples/cute/tutorial/sgemm_nt_1_sycl
```

# References

[1] https://www.khronos.org/sycl/
