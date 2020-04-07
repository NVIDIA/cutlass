![ALT](/media/images/gemm-hierarchy-with-epilogue-no-labels.png "CUTLASS Quick Start Guide")

[README](/README.md#documentation) > **Quick Start**

# Quickstart

## Prerequisites

CUTLASS requires:
- NVIDIA CUDA Toolkit (9.2 or later required, 10.2 recommended)
- CMake 3.12+
- host compiler supporting C++11 or greater (g++ 7.3.0 or Microsoft Visual Studio 2015 recommended)
- Python 3.6+

## Initial build steps

Construct a build directory and run CMake.
```bash
$ export CUDACXX=${CUDA_INSTALL_PATH}/bin/nvcc

$ mkdir build && cd build

$ cmake .. -DCUTLASS_NVCC_ARCHS=75               # compiles for NVIDIA's Turing GPU architecture
```

## Clang

For experimental purposes, CUTLASS may be compiled with 
[clang 8.0](https://github.com/llvm/llvm-project/releases/download/llvmorg-8.0.1/clang+llvm-8.0.1-amd64-unknown-freebsd11.tar.xz) using the 
[CUDA 10.0 Toolkit](https://developer.nvidia.com/cuda-10.0-download-archive).
At this time, compiling with clang enables the CUTLASS SIMT GEMM kernels (sgemm, dgemm, hgemm, igemm)
but does not enable TensorCores.

```bash
$ mkdir build && cd build

$ cmake -DCUDA_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ ..

$ make test_unit -j
```

## Build and run the CUTLASS Profiler

From the `build/` directory created above, compile the the CUTLASS Profiler.
```bash
$ make cutlass_profiler -j12
```

Then execute the CUTLASS Profiler for a set of problem sizes.
```bash
$ ./tools/profiler/cutlass_profiler --kernels=sgemm --m=4352 --n=4096 --k=4096

=============================
  Problem ID: 1

    Provider: CUTLASS
   Operation: cutlass_simt_sgemm_128x128_nn

 Disposition: Passed
      Status: Success

   Arguments:  --m=4352 --n=4096 --k=4096 --A=f32:column --B=f32:column --C=f32:column --alpha=1 --beta=0  \
               --split_k_slices=1 --batch_count=1 --op_class=simt --accum=f32 --cta_m=128 --cta_n=128 --cta_k=8  \
               --stages=2 --warps_m=2 --warps_n=2 --warps_k=1 --inst_m=1 --inst_n=1 --inst_k=1 --min_cc=50  \
               --max_cc=1024

       Bytes: 52428800  bytes
       FLOPs: 146064539648  flops

     Runtime: 10.5424  ms
      Memory: 4.63158 GiB/s

        Math: 13854.9 GFLOP/s
```

See [documentation for the CUTLASS Profiler](profiler.md) for more details.

## Build and run CUTLASS Unit Tests

From the `build/` directory created above, simply build the target `test_unit` to compile and run
all unit tests.

```bash
$ make test_unit -j
...
...
...
[----------] Global test environment tear-down
[==========] 946 tests from 57 test cases ran. (10812 ms total)
[  PASSED  ] 946 tests.
$
```
The exact number of tests run is subject to change as we add more functionality.

No tests should fail. Unit tests automatically construct the appropriate runtime filters
to avoid executing on architectures that do not support all features under test.

The unit tests are arranged hierarchically mirroring the CUTLASS Template Library. This enables
parallelism in building and running tests as well as reducing compilation times when a specific
set of tests are desired.

For example, the following executes strictly the warp-level GEMM tests.
```bash
$ make test_unit_gemm_warp -j
...
...
[----------] 3 tests from SM75_warp_gemm_tensor_op_congruous_f16
[ RUN      ] SM75_warp_gemm_tensor_op_congruous_f16.128x128x8_32x128x8_16x8x8
[       OK ] SM75_warp_gemm_tensor_op_congruous_f16.128x128x8_32x128x8_16x8x8 (0 ms)
[ RUN      ] SM75_warp_gemm_tensor_op_congruous_f16.128x128x32_64x64x32_16x8x8
[       OK ] SM75_warp_gemm_tensor_op_congruous_f16.128x128x32_64x64x32_16x8x8 (2 ms)
[ RUN      ] SM75_warp_gemm_tensor_op_congruous_f16.128x128x32_32x32x32_16x8x8
[       OK ] SM75_warp_gemm_tensor_op_congruous_f16.128x128x32_32x32x32_16x8x8 (1 ms)
[----------] 3 tests from SM75_warp_gemm_tensor_op_congruous_f16 (3 ms total)
...
...
[----------] Global test environment tear-down
[==========] 104 tests from 32 test cases ran. (294 ms total)
[  PASSED  ] 104 tests.
[100%] Built target test_unit_gemm_warp
```

## Using CUTLASS within other applications

Applications should list [`/include`](/include) within their include paths. They must be
compiled as C++11 or greater.

**Example:** print the contents of a variable storing half-precision data.
```c++
#include <iostream>
#include <cutlass/cutlass.h>
#include <cutlass/numeric_types.h>

int main() {

  cutlass::half_t x = 2.25_hf;

  std::cout << x << std::endl;

  return 0;
}
```

## Launching a GEMM kernel in CUDA

**Example:** launch a mixed-precision GEMM targeting Volta Tensor Cores.
```c++
#include <cutlass/numeric_types.h>
#include <cutlas/gemm/device/gemm.h>
#include <cutlass/util/host_tensor.h>

int main() {

  // Define the GEMM operation
  using Gemm = cutlass::gemm::device::Gemm<
    cutlass::half_t,                           // ElementA
    cutlass::layout::ColumnMajor,              // LayoutA
    cutlass::half_t,                           // ElementB
    cutlass::layout::ColumnMajor,              // LayoutB
    cutlass::half_t,                           // ElementOutput
    cutlass::layout::ColumnMajor,              // LayoutOutput
    float,                                     // ElementAccumulator
    cutlass::arch::OpClassTensorOp,            // tag indicating Tensor Cores
    cutlass::arch::Sm70                        // tag indicating target GPU compute architecture
  >;

  Gemm gemm_op;
  cutlass::Status status;

  //
  // Define the problem size
  //
  int M = 512;
  int N = 256;
  int K = 128;

  float alpha = 1.25f;
  float beta = -1.25f;

  //
  // Allocate device memory
  //

  cutlass::HostTensor<cutlass::half_t, cutlass::layout::ColumnMajor> A({M, K});
  cutlass::HostTensor<cutlass::half_t, cutlass::layout::ColumnMajor> B({K, N});
  cutlass::HostTensor<cutlass::half_t, cutlass::layout::ColumnMajor> C({M, N});

  cutlass::half_t const *ptrA = A.device_data();
  cutlass::half_t const *ptrB = B.device_data();
  cutlass::half_t const *ptrC = C.device_data();
  cutlass::half_t       *ptrD = C.device_data();

  int lda = A.device_ref().stride(0);
  int ldb = B.device_ref().stride(0);
  int ldc = C.device_ref().stride(0);
  int ldd = D.device_ref().stride(0);
  //
  // Launch GEMM on the device
  //
 
  status = gemm_op({
    {M, N, K},
    {ptrA, lda},            // TensorRef to A device tensor
    {ptrB, ldb},            // TensorRef to B device tensor
    {ptrC, ldc},            // TensorRef to C device tensor
    {ptrD, ldd},            // TensorRef to D device tensor - may be the same as C
    {alpha, beta}           // epilogue operation arguments
  });

  if (status != cutlass::Status::kSuccess) {
    return -1;
  }

  return 0;
}
```

Note, the above could be simplified as follows using helper methods defined in `HostTensor`.
```c++
  cutlass::HostTensor<cutlass::half_t, cutlass::layout::ColumnMajor> A({M, K});
  cutlass::HostTensor<cutlass::half_t, cutlass::layout::ColumnMajor> B({K, N});
  cutlass::HostTensor<cutlass::half_t, cutlass::layout::ColumnMajor> C({M, N});

  //
  // Use the TensorRef returned by HostTensor::device_ref().
  // 

  status = gemm_op({
    {M, N, K},
    A.device_ref(),            // TensorRef to A device tensor
    B.device_ref(),            // TensorRef to B device tensor
    C.device_ref(),            // TensorRef to C device tensor
    C.device_ref(),            // TensorRef to D device tensor - may be the same as C
    {alpha, beta}              // epilogue operation arguments
  });
```

# CUTLASS Library

The [CUTLASS Library](./tools/library) defines an API for managing and executing collections of compiled
kernel instances and launching them from host code without template instantiations in client code.

The host-side launch API is designed to be analogous to BLAS implementations for convenience, though its 
kernel selection procedure is intended only to be functionally sufficient. It may not launch the 
optimal tile size for a given problem. It chooses the first available kernel whose data types, 
layouts, and alignment constraints satisfy the given problem. Kernel instances and a data structure
describing them are completely available to client applications which may choose to implement their
own selection logic.

[cuBLAS](https://developer.nvidia.com/cublas) offers the best performance and functional coverage
for dense matrix computations on NVIDIA GPUs.

The CUTLASS Library is used by the CUTLASS Profiler to manage kernel instances, and it is also used
by several SDK examples.

* [10_planar_complex](/examples/10_planar_complex/planar_complex.cu)
* [11_planar_complex_array](/examples/11_planar_complex_array/planar_complex_array.cu)

The CUTLASS Library defines enumerated types describing numeric data types, matrix and tensor
layouts, math operation classes, complex transformations, and more. 

Client applications should specify [`tools/library/include`](/tools/library/include) in their
include paths and link against libcutlas_lib.so.

The CUTLASS SDK example [10_planar_complex](/examples/10_planar_complex/CMakeLists.txt) specifies 
its dependency on the CUTLASS Library with the following CMake command.
```
target_link_libraries(
  10_planar_complex
  PRIVATE
  cutlass_lib
  cutlass_tools_util_includes
)
```

A sample kernel launch from host-side C++ is shown as follows.

```c++
#include "cutlass/library/library.h"
#include "cutlass/library/handle.h"

int main() {

  //
  // Define the problem size
  //
  int M = 512;
  int N = 256;
  int K = 128;

  float alpha = 1.25f;
  float beta = -1.25f;

  //
  // Allocate device memory
  //

  cutlass::HostTensor<float, cutlass::layout::ColumnMajor> A({M, K});
  cutlass::HostTensor<float, cutlass::layout::ColumnMajor> B({K, N});
  cutlass::HostTensor<float, cutlass::layout::ColumnMajor> C({M, N});

  float const *ptrA = A.device_data();
  float const *ptrB = B.device_data();
  float const *ptrC = C.device_data();
  float       *ptrD = C.device_data();

  int lda = A.device_ref().stride(0);
  int ldb = B.device_ref().stride(0);
  int ldc = C.device_ref().stride(0);
  int ldd = D.device_ref().stride(0);

  //
  // CUTLASS Library call to execute device GEMM
  //
  
  cutlass::library::Handle handle;

  //
  // Launch GEMM on CUDA device.
  //

  cutlass::Status status = handle.gemm(
    M,
    N,
    K,

    cutlass::library::NumericTypeID::kF32,          // data type of internal accumulation
    cutlass::library::NumericTypeID::kF32,          // data type of alpha/beta scalars

    &alpha,                                         // pointer to alpha scalar

    cutlass::library::NumericTypeID::kF32,          // data type of A matrix
    cutlass::library::LayoutTypeID::kColumnMajor,   // layout of A matrix
    ptrA,                                           // pointer to A matrix in device memory
    lda,                                            // leading dimension of A matrix

    cutlass::library::NumericTypeID::kF32,          // data type of B matrix
    cutlass::library::LayoutTypeID::kColumnMajor,   // layout of B matrix
    ptrB,                                           // pointer to B matrix in device memory
    ldb,                                            // leading dimension of B matrix

    &beta,                                          // pointer to beta scalar

    cutlass::library::NumericTypeID::kF32,          // data type of C and D matrix

    ptrC,                                           // pointer to C matrix in device memory
    ldc,                                            // leading dimension fo C matrix

    ptrD,                                           // pointer to D matrix in device memory
    ldd                                             // leading dimension of D matrix
  );
  
  if (status != cutlass::Status::kSuccess) {
    return -1;
  }

  return 0;
}
```

Kernels can be selectively included in the CUTLASS Library by specifying filter strings when
executing CMake. For example, only single-precision GEMM kernels can be instantiated as follows.

```bash
$ cmake .. -DCUTLASS_NVCC_ARCHS=75 -DCUTLASS_LIBRARY_KERNELS=sgemm
```

Compling only the kernels desired reduces compilation time.

To instantiate kernels of all tile sizes, data types, and alignment constraints, specify 
`-DCUTLASS_LIBRARY_KERNELS=all` when running `cmake`.

Several recipes are defined below for convenience. They may be combined as a comma-delimited list.

**Example.** All kernels for Volta and Turing architectures.
```bash
$ cmake .. -DCUTLASS_NVCC_ARCHS="70;75" -DCUTLASS_LIBRARY_KERNELS=all
```

**Example.** All GEMM kernels targeting Turing Tensor Cores.
```bash
$ cmake .. -DCUTLASS_NVCC_ARCHS=75 -DCUTLASS_LIBRARY_KERNELS=tensorop*gemm
```

**Example.** All GEMM kernels with single-precision accumulation.
```bash
$ cmake .. -DCUTLASS_NVCC_ARCHS="70;75" -DCUTLASS_LIBRARY_KERNELS=s*gemm
```

**Example.** All kernels which expect A and B to be column-major.
```bash
$ cmake .. -DCUTLASS_NVCC_ARCHS="70;75" -DCUTLASS_LIBRARY_KERNELS=gemm*nn
```

**Example.** All planar complex GEMM variants.
```bash
$ cmake .. -DCUTLASS_NVCC_ARCHS="70;75" -DCUTLASS_LIBRARY_KERNELS=planar_complex
```


# Copyright

Copyright (c) 2017-2020, NVIDIA CORPORATION.  All rights reserved.

```
  Redistribution and use in source and binary forms, with or without modification, are permitted
  provided that the following conditions are met:
      * Redistributions of source code must retain the above copyright notice, this list of
        conditions and the following disclaimer.
      * Redistributions in binary form must reproduce the above copyright notice, this list of
        conditions and the following disclaimer in the documentation and/or other materials
        provided with the distribution.
      * Neither the name of the NVIDIA CORPORATION nor the names of its contributors may be used
        to endorse or promote products derived from this software without specific prior written
        permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
  IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
  FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL NVIDIA CORPORATION BE LIABLE
  FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
  OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
  STRICT LIABILITY, OR TOR (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
```
