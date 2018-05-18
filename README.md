![ALT](/media/images/gemm-hierarchy-with-epilogue-no-labels.png "Complete CUDA GEMM decomposition")

# CUTLASS 1.0

CUTLASS 1.0 is a collection of CUDA C++ template abstractions for implementing
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
multiply-accumulate abstractions for 8-bit integer, half-precision floating
point (FP16), single-precision floating point (FP32), and double-precision floating
point (FP64) types.  Furthermore, CUTLASS demonstrates CUDA's WMMA API for targeting
the programmable, high-throughput _Tensor Cores_ provided by NVIDIA's Volta architecture
and beyond.

CUTLASS 1.0 has changed substantially from our preview release described in
the [CUTLASS Parallel For All](https://devblogs.nvidia.com/parallelforall/cutlass-linear-algebra-cuda)
post. We have decomposed the structure of the GEMM computation into deeper, structured
primitives for loading data, computing predicate masks, streaming data at each level of
the GEMM hierarchy, and updating the output matrix.

CUTLASS 1.0 is described in the [Doxygen documentation](https://nvidia.github.io/cutlass)
and our talk at the [GPU Technology Conference 2018](http://on-demand.gputechconf.com/gtc/2018/presentation/s8854-cutlass-software-primitives-for-dense-linear-algebra-at-all-levels-and-scales-within-cuda.pdf).

# Performance

<p align="center"><img src=/media/images/cutlass-performance-plot.png></p>

CUTLASS primitives are very efficient.  When used to construct device-wide GEMM kernels,
they exhibit performance comparable to cuBLAS for scalar GEMM
computations. The above figure shows CUTLASS performance relative to cuBLAS
for large matrix dimensions (M=10240, N=K=4096) running on an NVIDIA Titan V GPU
when compiled with CUDA 9.2.

# Compatibility

CUTLASS requires CUDA 9 and performs best with [CUDA 9.2 Toolkit](ttps://developer.nvidia.com/cuda-toolkit) or later.

|**Operating System** | **Compiler** |
|-----------------|----------|
| Windows 10      | Microsoft Visual Studio 2015|
|                 | Microsoft Visual Studio 2017|
| Ubuntu 14.04 | GCC 4.8.2 |
| Ubuntu 16.04 | GCC 5.4.0 |


CUTLASS runs successfully on the following NVIDIA GPUs, and it is expected to be efficient on
any Maxwell-, Pascal-, or Volta-architecture NVIDIA GPU.

|**GPU**|
|---|
|NVIDIA GeForce 1080|
|NVIDIA TitanXP|
|NVIDIA Tesla P100|
|NVIDIA Tesla V100|
|NVIDIA TitanV|


# Building CUTLASS

CUTLASS is a header-only template library and does not need to be built to be used by other
projects. However, we distribute extensive unit tests and utility programs to demonstrate
CUTLASS. These instructions are for building those test programs.

CUTLASS's unit tests depend on Google Test which exists as a git submodule. You can fetch
submodules as follows.

```
$ git submodule update --init --recursive
```

CUTLASS can be build with CMake starting version 3.10. By default CUTLASS will build kernels
for CUDA architecture versions 5.0, 6.0, 6.1 and 7.0. To reduce compile time you can specify
the architectures to build CUTLASS for by changing the CMake configuration setting
`CUTLASS_NVCC_ARCHS`.

Create a build directory within the CUTLASS project, then run CMake once.

```
$ mkdir build && cd build
$ cmake ..
```

Compile the CUTLASS project by running Make. Include the -j argument to compile sources in
parallel and speed up the build process.

```
$ make -j12
...
$
```

Verify CUTLASS has been built correctly by running the unit tests from the build/ directory.

```
$ ./tools/test/unit/cutlass_unit_test
...
...
...
[----------] Global test environment tear-down
[==========] 481 tests from 24 test cases ran. (5954 ms total)
[  PASSED  ] 481 tests.
```

All tests should pass, though the exact number of tests may vary over time.


# Project Structure

CUTLASS is arranged as a header-only library with several example test programs
that demonstrate instantiating a GEMM task within a CUDA kernel. The Doxygen documentation
provides a complete list of files, classes, and template concepts defined in the CUTLASS
project. A brief summary is described below.

The CUTLASS library is defined in the cutlass/ directory and consists of CUDA C++ template
classes and other definitions for implementing efficient GPU GEMM kernels. A set of core
classes and templates define basic primitives that are then applied to compute GEMM via
templates in the cutlass/gemm directory.

```
cutlass/
    gemm/
    util/
    <core API components>
```

Several tools and test programs are also distributed with the CUTLASS library. They are
contained in the following directories.

```
tools/
    test/
        unit/
            core/
            gemm/
        perf/
    util/
        <utilities>
```

The `test/unit/` directory consist of unit tests implemented with Google Test that demonstrate
basic usage of Core API components and complete tests of the CUTLASS GEMM computations.

# Performance Profiling

The `test/perf/` directory contains a command-line utility for launching each of the GEMM kernels.
Its usage is shown below.

Program usage:

```
  cutlass_perf_test [options]

    --help
    --append=<true|false*>                            If true, appends output to existing CSV file. If false, overwrites.
    --alpha=<alpha>                                   Value for alpha to be used in GEMM experiments
    --beta=<beta>                                     Value for beta to be used in GEMM experiments
    --dist=<distribution>                             Describes the random distribution of each of the input matrix operands.
    --execution_mode=<mode>                           Specifies execution mode: profile, verify, single
    --output=<filename.csv>                           Writes summary of profiling to specified .csv file
    --iterations=<timing iterations>                  maximum number of iterations to execute when profiling
    --m=<height>[:max height[:step]]                  Height of GEMM problem (number of rows of C). May specify a range with optional step size.
    --n=<width>[:max width[:step]]                    Width of GEMM problem (number of columns of C). May specify a range with optional step size.
    --k=<depth>[:max depth[:step]]                    Size of inner dimension of A and B. May specify a range with optional step size.
    --kernels=<{s|d|h|i|wmma_}gemm_{nn,nt,tn,tt}>     Select GEMM datatype and layout to use for tests
    --peak=<bool>                                     If true, only reports peak performance per kernel after profiling specified problem space.
    --save_workspace={*never,incorrect,always}        Specifies when to save the GEMM inputs and results to the filesystem.
    --seed=<seed>                                     Random seed used by the random number generator in initializing input matrices.
    --tags=<column:tag,...>                           Inserts leading columns in output table and uniform values for each column.


  Example usage:

  # Runs one problem size for all kernels
  $ ./tools/test/perf/cutlass_perf_test --m=10240 --n=1024 --k=1024

  # Varies GEMM K dimension for SGEMM and IGEMM with column-major multiplicands
  $ ./tools/test/perf/cutlass_perf_test --m=10240 --n=4096 --k=1024:8192:128 --kernels=sgemm_nn,igemm_nn
```

# About

CUTLASS is released by NVIDIA Corporation as Open Source software under the
3-clause "New" BSD license.


# Copyright

Copyright (c) 2017-2018, NVIDIA CORPORATION.  All rights reserved.

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

