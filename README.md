![ALT](/media/images/gemm-hierarchy-with-epilogue-no-labels.png "Complete CUDA GEMM decomposition")

# CUTLASS 2.3

_CUTLASS 2.3 - September 2020_

CUTLASS is a collection of CUDA C++ template abstractions for implementing
high-performance matrix-multiplication (GEMM) at all levels and scales within CUDA.
It incorporates strategies for hierarchical decomposition and data movement similar
to those used to implement cuBLAS.  CUTLASS decomposes these "moving parts" into
reusable, modular software components abstracted by C++ template classes.  These
thread-wide, warp-wide, block-wide, and device-wide primitives can be specialized
and tuned via custom tiling sizes, data types, and other algorithmic policy. The
resulting flexibility simplifies their use as building blocks within custom kernels
and applications.

To support a wide variety of applications, CUTLASS provides extensive support for
mixed-precision computations, providing specialized data-movement and
multiply-accumulate abstractions for half-precision floating
point (FP16), BFloat16 (BF16), Tensor Float 32 (TF32),
single-precision floating point (FP32), double-precision floating
point (FP64) types, integer data types (4b and 8b), and binary data types (1b). 

Furthermore, CUTLASS demonstrates warp-synchronous matrix multiply operations 
targeting the  programmable, high-throughput _Tensor Cores_ implemented by 
NVIDIA's Volta, Turing, and Ampere architectures.

See the [Quick Start Guide](/media/docs/quickstart.md) to get started quickly.

See the [functionality listing](media/docs/functionality.md) for the list of operations
supported at each level of the execution model hierarchy.

# What's New in CUTLASS 2.3

CUTLASS 2.3 is a minor update to CUTLASS adding:
- GEMMs targeting structured [Sparse Tensor Cores](test/unit/gemm/device/gemm_f16n_f16n_f32t_tensor_op_f32_sparse_sm80.cu) in NVIDIA Ampere Architecture GPUs
- Fast SGEMM kernels targeting GeForce RTX 30-series CUDA Cores
- Intended to be compiled with [CUDA 11.1 Toolkit](https://developer.nvidia.com/cuda-toolkit)
- See the [CHANGELOG](CHANGELOG.md) for more details.

# What's New in CUTLASS 2.2

CUTLASS 2.2 is a significant update to CUTLASS adding:

- Coverage of [NVIDIA Ampere Architecture features](https://devblogs.nvidia.com/nvidia-ampere-architecture-in-depth/)
- Tensor Core-accelerated GEMMs targeting Tensor Float 32, BFloat16, and double-precision data types
- Deep software pipelines using asynchronous copy
- Described in [GTC 2020 Webinar (SR 21745)](https://developer.nvidia.com/gtc/2020/video/s21745)
- Intended to be compiled with [CUDA 11 Toolkit](https://developer.nvidia.com/cuda-toolkit)

# What's New in CUTLASS 2.1

CUTLASS 2.1 is a minor update to CUTLASS adding:

- [Planar complex GEMM kernels](/examples/10_planar_complex/planar_complex.cu) targeting Volta and Turing Tensor Cores
- BLAS-style API to launch kernels compiled into the [CUTLASS Library](/media/docs/quickstart.md#cutlass-library)

# What's New in CUTLASS 2.0

CUTLASS 2.0 is a substantial refactoring from the previous version, intended to offer:

- Better performance over 1.x, particularly for kernels targeting Turing Tensor Cores
- Robust and durable templates that reliably span the design space
- Encapsulated functionality that may be reusable in other contexts

**See the [CHANGELOG](CHANGELOG.md) for more details.**

# Performance

<p align="center"><img src=/media/images/cutlass-performance-plot.png></p>

CUTLASS primitives are very efficient.  When used to construct device-wide GEMM kernels,
they exhibit performance comparable to cuBLAS for scalar GEMM
computations. The above figure shows CUTLASS performance relative to cuBLAS
for large matrix dimensions on an NVIDIA GeForce 2080 Ti, an NVIDIA A100, and an NVIDIA TitanV
using CUDA 11.0 Toolkit. Tensor Core operations are implemented using CUDA's 
[mma instruction](https://docs.nvidia.com/cuda/parallel-thread-execution/index.html#warp-level-matrix-instructions-mma).

# Compatibility

CUTLASS requires a C++11 host compiler and 
performs best when built with the [CUDA 11.1 Toolkit](https://developer.nvidia.com/cuda-toolkit).
It is compatible with CUDA 9.2, CUDA 10.0, CUDA 10.1, CUDA 10.2, and CUDA 11.0.

We have tested the following environments.

|**Operating System** | **Compiler** |
|-----------------|----------|
| Windows 10      | Microsoft Visual Studio 2015|
|                 | Microsoft Visual Studio 2017|
| Ubuntu 16.04 | GCC 5.4.0 |
| Ubuntu 18.04 | GCC 7.5.0 |

Additionally, CUTLASS may be built with clang. 
See [these instructions](media/docs/quickstart.md#clang) for more details.

CUTLASS runs successfully on the following NVIDIA GPUs, and it is expected to be efficient on
any Maxwell-, Pascal-, Volta-, Turing-, or NVIDIA Ampere- architecture NVIDIA GPU.

|**GPU**|**CUDA Compute Capability**|**Minimum CUDA Toolkit**|**CUDA Toolkit Enabling Native Tensor Cores**|
|---|---|---|---|
|NVIDIA Tesla P100|6.0|9.2|  |
|NVIDIA GeForce 1080|6.1|9.2|  |
|NVIDIA TitanXP|6.1|9.2|  |
|NVIDIA Tesla V100|7.0|9.2|10.1|
|NVIDIA TitanV|7.0|9.2|10.1|
|NVIDIA GeForce RTX 2080 TI, 2080, 2070|7.5|10.0|10.2|
|NVIDIA Tesla T4|7.5|10.0|10.2|
|NVIDIA A100|8.0|11.0|11.0|
|NVIDIA GeForce 3090|8.6|11.1|11.1|

# Documentation

CUTLASS is described in the following documents and the accompanying
[Doxygen documentation](https://nvidia.github.io/cutlass).

- [Quick Start Guide](/media/docs/quickstart.md) - build and run CUTLASS
- [Functionality](/media/docs/functionality.md) - summarizes functionality available in CUTLASS
- [Efficient GEMM in CUDA](media/docs/efficient_gemm.md) - describes how GEMM kernels may be implemented efficiently in CUDA
- [GEMM API](media/docs/gemm_api.md) - describes the CUTLASS GEMM model and C++ template concepts 
- [Code Organization](media/docs/code_organization.md) - describes the organization and contents of the CUTLASS project
- [Terminology](media/docs/terminology.md) - describes terms used in the code
- [Programming Guidelines](media/docs/programming_guidelines.md) - guidelines for writing efficient modern CUDA C++
- [Fundamental types](media/docs/fundamental_types.md) - describes basic C++ classes used in CUTLASS to represent numeric quantities and arrays
- [Layouts](media/docs/layout.md) - describes layouts of matrices and tensors in memory
- [Tile Iterators](media/docs/tile_iterator_concept.md) - describes C++ concepts for iterating over tiles of matrices in memory
- [CUTLASS Profiler](media/docs/profiler.md) - command-line driven profiling application
- [CUTLASS Utilities](media/docs/utilities.md) - additional templates used to facilate rapid development

We have also described the structure of an efficient GEMM in our talk at the
[GPU Technology Conference 2018](http://on-demand.gputechconf.com/gtc/2018/presentation/s8854-cutlass-software-primitives-for-dense-linear-algebra-at-all-levels-and-scales-within-cuda.pdf).

# Building CUTLASS

CUTLASS is a header-only template library and does not need to be built to be used by other
projects. Client applications should target CUTLASS's `include/` directory in their include
paths.

CUTLASS unit tests, examples, and utilities can be build with CMake starting version 3.12. 
Make sure the `CUDACXX` environment  variable points to NVCC in the CUDA Toolkit installed
on your system.

```
$ export CUDACXX=${CUDA_INSTALL_PATH}/bin/nvcc
```

Create a build directory within the CUTLASS project, then run CMake. By default CUTLASS will build kernels
for CUDA architecture versions 5.0, 6.0, 6.1, 7.0, 7.5, 8.0, and 8.6. To reduce compile time you can specify
the architectures to build CUTLASS for by changing the CMake configuration setting
`CUTLASS_NVCC_ARCHS`.

```
$ mkdir build && cd build

$ cmake .. -DCUTLASS_NVCC_ARCHS=80               # compiles for NVIDIA's Ampere Architecture
```

From the `build/` directory, compile and run the CUTLASS unit tests by building the target `test_unit` with make.

The unit tests are organized as several binaries mirroring the top-level namespaces of CUTLASS,
and they may be executed in parallel via make's `-j` command line argument.

```
$ make test_unit -j
...
...
...
[----------] Global test environment tear-down
[==========] 946 tests from 57 test cases ran. (10812 ms total)
[  PASSED  ] 946 tests.
```

All tests should pass on supported platforms, though the exact number of tests may vary over time.


# Project Structure

CUTLASS is arranged as a header-only library along with Utilities, Tools, Examples, and unit tests. 
[Doxygen documentation](https://nvidia.github.io/cutlass) provides a complete list of files, classes, 
and template concepts defined in the CUTLASS project.

A detailed explanation of the source code organization may be found in the 
[CUTLASS documentation](media/docs/code_organization.md), but several main components are summarized below.

## CUTLASS Template Library

```
include/                     # client applications should target this directory in their build's include paths

  cutlass/                   # CUDA Templates for Linear Algebra Subroutines and Solvers - headers only

    arch/                    # direct exposure of architecture features (including instruction-level GEMMs)

    gemm/                    # code specialized for general matrix product computations

    layout/                  # layout definitions for matrices, tensors, and other mathematical objects in memory

    platform/                # CUDA-capable Standard Library components

    reduction/               # bandwidth-limited reduction kernels that do not fit the "gemm" model
    
    transform/               # code specialized for layout, type, and domain transformations

    *                        # core vocabulary types, containers, and basic numeric operations
```

### CUTLASS SDK Examples

[CUTLASS SDK examples](/examples) apply CUTLASS templates to implement basic computations.

```
examples/
  00_basic_gemm/             # launches a basic GEMM with single precision inputs and outputs

  01_cutlass_utilities/      # demonstrates CUTLASS Utilities for allocating and initializing tensors
  
  02_dump_reg_smem/          # debugging utilities for printing register and shared memory contents
  
  03_visualize_layout/       # utility for visualizing all layout functions in CUTLASS

  04_tile_iterator/          # example demonstrating an iterator over tiles in memory

  05_batched_gemm/           # example demonstrating CUTLASS's batched strided GEMM operation

  06_splitK_gemm/            # exmaple demonstrating CUTLASS's Split-K parallel reduction kernel

  07_volta_tensorop_gemm/    # example demonstrating mixed precision GEMM using Volta Tensor Cores

  08_turing_tensorop_gemm/   # example demonstrating integer GEMM using Turing Tensor Cores

  10_planar_complex/         # example demonstrating planar complex GEMM kernels

  11_planar_complex_array/   # example demonstrating planar complex kernels with batch-specific problem sizes

  12_gemm_bias_relu/         # example demonstrating GEMM fused with bias and relu

  13_fused_two_gemms/        # example demonstrating two GEMms fused in one kernel
```

### Tools
```
tools/
  library/                   # CUTLASS Instance Library - contains instantiations of all supported CUTLASS templates
    include/
      cutlass/
        library/

  profiler/                  # CUTLASS Profiler         - command-line utility for executing operations in the
                             #                            CUTLASS Library
  
  util/                      # CUTLASS Utilities        - contains numerous helper classes for
    include/                 #                            manging tensors in device memory, reference
      cutlass/               #                            implementations for GEMM, random initialization
        util/                #                            of tensors, and I/O.
```

### Test

The `test/unit/` directory consist of unit tests implemented with Google Test that demonstrate
basic usage of Core API components and complete tests of the CUTLASS GEMM computations.

Instructions for building and running the Unit tests are described in the [Quickstart guide](media/docs/quickstart.md).

# Performance Profiling

The `tools/profiler/` directory contains a command-line utility for launching each of the GEMM kernels.
It can be built as follows:

```
$ make cutlass_profiler -j16
```

By default, only one tile size is instantiated for each data type, math instruction, and layout.
To instantiate all, set the following environment variable when running CMake from an empty `build/` directory.
Beware, this results in *thousands* of kernels and long build times.
```
$ cmake .. -DCUTLASS_NVCC_ARCHS=75 -DCUTLASS_LIBRARY_KERNELS=all
...
$ make cutlass_profiler -j16
```

To compile strictly one kernel or a small set of kernels, a comma-delimited list of kernel names with 
wildcard characters may be reduce the set of kernels. The following builds exactly one kernel:

```
$ cmake .. -DCUTLASS_NVCC_ARCHS=75 -DCUTLASS_LIBRARY_KERNELS=cutlass_simt_sgemm_128x128_8x2_nn_align1
...
$ make cutlass_profiler -j16
```

Example command line for profiling SGEMM kernels is as follows:
```
$ ./tools/profiler/cutlass_profiler --kernels=sgemm --m=3456 --n=4096 --k=4096

=============================
  Problem ID: 1

        Provider: CUTLASS
   OperationKind: gemm
       Operation: cutlass_simt_sgemm_128x128_8x2_nn_align1

          Status: Success
    Verification: ON
     Disposition: Passed

          cuBLAS: Passed

       Arguments: --m=3456 --n=4096 --k=4096 --A=f32:column --B=f32:column --C=f32:column --alpha=1 --beta=0 --split_k_slices=1  \
                  --batch_count=1 --op_class=simt --accum=f32 --cta_m=128 --cta_n=128 --cta_k=8 --stages=2 --warps_m=4  \
                  --warps_n=2 --warps_k=1 --inst_m=1 --inst_n=1 --inst_k=1 --min_cc=50 --max_cc=1024

           Bytes: 180355072  bytes
           FLOPs: 115992428544  flops

         Runtime: 6.73655  ms
          Memory: 24.934 GiB/s

            Math: 17218.4 GFLOP/s
```

[Further details about the CUTLASS Profiler are described here.](media/docs/profiler.md)


# About

CUTLASS is released by NVIDIA Corporation as Open Source software under the 
[3-clause "New" BSD license](LICENSE.txt).

# Contributors

The official list of CUTLASS developers and contributors is available here: [CONTRIBUTORS](CONTRIBUTORS.md).

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

