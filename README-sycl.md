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

## Requirements
 
To build CUTLASS SYCL support you need the latest version of DPC++ compiler. You can either use a recent [nighly build](https://github.com/intel/llvm/releases)
or build the compiler from source as described in [oneAPI DPC++ guidline]((https://github.com/intel/llvm/blob/sycl/sycl/doc/GetStartedGuide.md#build-dpc-toolchain-with-support-for-nvidia-cuda)).

In either case, CUDA version >= 12.0 is required.

## Building with SYCL support
Once you have your compiler installed, you need to point the
`CMAKE_CUDA_HOST_COMPILER` flag to the clang++ provided by it.
This enables the compilation of SYCL sources without altering the current NVCC path.

```
make -G Ninja  \
  -DCUTLASS_ENABLE_CUBLAS=ON \ 
  -DCMAKE_CUDA_HOST_COMPILER=/path/to/clang++  \
  -DCMAKE_CUDA_COMPILER=/path/to/nvcc \ 
  -DCUTLASS_ENABLE_SYCL=ON \
  -DDPCPP_SYCL_TARGET=nvptx64-nvidia-cuda \
  -DDPCPP_SYCL_ARCH=sm_80
```


# Running the example

## CuTe 
Currently, you can build the CuTe Tutorial using the following command: 

```
ninja [EXAMPLE_NAME]_sycl
```

You can run it like this from your build directory

```
./examples/cute/tutorial/[EXAMPLE_NAME]_sycl
```

## CUTLASS Example
 Currently, the the example `14_amper_tf32_tensorop_gemm` has been implemented for SYCL on Nvidia Ampere architecture. You can build this from your build directory by running :
 ```
  ninja 14_ampere_tf32_tensorop_gemm_cute
 ```
 You can run it like this from your build directory
 ```
  NVIDIA_TF32_OVERRIDE=1 ./examples/14_ampere_tf32_tensorop_gemm/14_ampere_tf32_tensorop_gemm_cute
 ```

# References

[1] https://www.khronos.org/sycl/
