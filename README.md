![ALT](./media/images/gemm-hierarchy-with-epilogue-no-labels.png "Complete CUDA GEMM decomposition")

# CUTLASS 3.8.0

_CUTLASS 3.8.0 - January 2025_

CUTLASS is a collection of CUDA C++ template abstractions for implementing
high-performance matrix-matrix multiplication (GEMM) and related computations at all levels 
and scales within CUDA. It incorporates strategies for hierarchical decomposition and 
data movement similar to those used to implement cuBLAS and cuDNN.  CUTLASS decomposes 
these "moving parts" into reusable, modular software components abstracted by C++ template 
classes.  Primitives for different levels of a conceptual parallelization hierarchy
can be specialized and tuned via custom tiling sizes, data types,
and other algorithmic policy. The resulting flexibility simplifies their use
as building blocks within custom kernels and applications.

To support a wide variety of applications, CUTLASS provides extensive support for
mixed-precision computations, providing specialized data-movement and
multiply-accumulate abstractions for FP64, FP32, TF32, FP16, BF16,
[FP32 emulation via tensor core instruction](./examples/27_ampere_3xtf32_fast_accurate_tensorop_gemm), 
 8b floating point types (e5m2 and e4m3),
 block scaled data types (NVIDIA NVFP4 and OCP standard MXFP4, MXFP6, MXFP8),
 narrow integer types (4 and 8b signed and unsigned integers),
 and binary 1b data types (where architectures allow for the
native support of such data types).
CUTLASS demonstrates optimal matrix multiply operations
targeting the programmable, high-throughput _Tensor Cores_ implemented by
NVIDIA's Volta, Turing, Ampere, Ada, Hopper, and Blackwell architectures.

In addition to GEMMs, CUTLASS implements high-performance convolution via
the implicit GEMM algorithm. Implicit GEMM is the formulation of a convolution
operation as a GEMM thereby taking advantage of CUTLASS's modular GEMM pipeline.
This allows CUTLASS to build convolutions by reusing highly-optimized GEMM components.

See the [Quick Start Guide](./media/docs/quickstart.md) to get started quickly.

See the [functionality docs](./media/docs/functionality.md) for a more comprehensive
list of kernel level features, data types, instructions, and minimum supported by CUTLASS on each GPU
architecture.

# What's New in CUTLASS 3.8

CUTLASS 3.8 is the first release that supports the NVIDIA Blackwell SM100 architecture.
For a background on Blackwell's new features, please consult the PTX documentation for CUDA 12.8.

* Support for new CuTe building blocks specifically for Blackwell architecture:
  - [5th generation Blackwell Tensor Core instructions (TCGen05)](./include/cute/atom/mma_traits_sm100.hpp) via CuTe MMA atoms.
  - Extensions to [Tensor Memory Accelerator](./include/cute/atom/copy_traits_sm100_tma.hpp) via CuTe Copy atoms.
  - Exposure of Blackwell's new tensor memory (note: distinct from TMA) as [`tmem`](./include/cute/pointer.hpp#L290) across CuTe as a first class data locale.
  - Exposure of [`tmem->rmem`, `rmem->tmem` and `smem->tmem data movement instructions`](./include/cute/atom/copy_traits_sm100.hpp) as copy atoms in CuTe.
  - [`make_tmem_copy()`](./include/cute/atom/copy_traits_sm100.hpp) utility method to ease creation of tiled copies for tmem copy atoms.
  - Support for [new variants of LDSM on Blackwell](./include/cute/atom/copy_traits_sm100.hpp) via CuTe Copy atoms.
* Support for new CUTLASS building blocks specifically for Blackwell architecture:
  - Various narrow precision [FP4, FP6, and FP8](./include/cutlass/exmy_base.h) formats as well as their [block-scaled variants NVFP4, MXFP4, MXFP6, and MXFP8](./include/cutlass/float_subbyte.h)
  - [Pipelines that implement Blackwell specific synchronization](./include/cutlass/pipeline/sm100_pipeline.hpp).
  - [Cluster launch control API supporting preferred and fallback cluster shapes](./include/cutlass/cluster_launch.hpp).
  - Data types including NVFP4, MXFP4, MXFP6, and MXFP8 and all their supported element and scale factor types.
  - Tile schedulers using [Blackwell's Cluster Launch Control (CLC) feature](./media/docs/blackwell_cluster_launch_control.md) to implement dynamic persistence scheduling for [GEMMs](./include/cutlass/gemm/kernel/sm100_tile_scheduler.hpp), and [stream-K](./include/cutlass/gemm/kernel/sm100_tile_scheduler_stream_k.hpp).
  - Extensions to testbeds and reference check code for unit tests and CUTLASS profiler.
* Full support for Blackwell kernels in CUTLASS 3.x API:
  - [Blackwell specific kernel layers](./include/cutlass/gemm/kernel/sm100_gemm_tma_warpspecialized.hpp) that
    + Implement a new warp-specialization recipe tuned specifically for Blackwell.
    + Leverage all the new features such as CLC based tile scheduling, preferred cluster, and TMEM based double buffering of accumulators.
    + Support stream-K load balancing for all kernel types everywhere via composable scheduler support.
  - Blackwell collective mainloops that target the TCGen05 MMA instructions (both SS and TS) for
    * [Non-block scaled data types without support for pointer array and grouped GEMM with TMA](./include/cutlass/gemm/collective/sm100_mma_warpspecialized.hpp)
    * [Non-block scaled data types with support for pointer array and grouped GEMM with TMA](./include/cutlass/gemm/collective/sm100_mma_array_warpspecialized.hpp)
    * [Block scaled data types without support for pointer array and grouped GEMM with TMA](./include/cutlass/gemm/collective/sm100_blockscaled_mma_warpspecialized.hpp)
    * [Block scaled data types with support for pointer array and grouped GEMM with TMA](./include/cutlass/gemm/collective/sm100_blockscaled_mma_array_warpspecialized.hpp)
  - Blackwell [collective mainloop for convolution kernels](./include/cutlass/conv/collective/sm100_implicit_gemm_umma_warpspecialized.hpp) supporting non-block scaled data types for fprop, dgrad, and wgrad.
  - New [GEMM](./include/cutlass/gemm/dispatch_policy.hpp), [convolution](./include/cutlass/conv/dispatch_policy.hpp), and [epilogue](./include/cutlass/epilogue/dispatch_policy.hpp) dispatch policies for collectives, kernel layers, and builders.
  - [Blackwell epilogue that supports loading accumulators from `tmem`](./include/cutlass/epilogue/collective/sm100_epilogue_tma_warpspecialized.hpp) and [full set of EVT fusions]().
* CUTLASS library and profiler integration for block scaled data types for kernel emission, profiling, and verification.
  - Support for preferred and fallback cluster shapes via profiler command line arguments parsing to set dynamic cluster shapes.
  - Support for dynamic datatypes by parsing profiler via profiler command line arguments parsing to set dynamic datatype setting in TCGen05 MMA instruction descriptors.
* Set of examples that demonstrate the usage of the 3.x API for targeting Blackwell
  - [Basic FP16 and FP8 GEMMs with minimal changes from Hopper examples](./examples/70_blackwell_gemm/), demonstrating ease of migration for off the shelf kernels using the 3.x collective builder API.
  - GEMM with [opt-in collective builder schedules showcasing available recipes](./examples/71_blackwell_gemm_with_collective_builder/71_blackwell_gemm_with_collective_builder.cu) for Blackwell.
  - Block scaled data type GEMMs targeting Blackwell's native block scaled Tensor Cores:
    + [NVFP4 inputs with BF16 output](./examples/72_blackwell_narrow_precision_gemm/72a_blackwell_nvfp4_bf16_gemm.cu)
    + [NVFP4 inputs with NVFP4 output](./examples/72_blackwell_narrow_precision_gemm/72b_blackwell_nvfp4_nvfp4_gemm.cu)
    + [Mixed MXFP8 and MXFP6 inputs with BF16 output](./examples/72_blackwell_narrow_precision_gemm/72c_blackwell_mixed_mxfp8_bf16_gemm.cu)
  - GEMM example demonstrating [Blackwell's new preferred cluster support via dynamic cluster shapes](./examples/73_blackwell_gemm_preferred_cluster/blackwell_gemm_preferred_cluster.cu) for increased occupancy.
  - [GEMM with CLC based StreamK scheduler for load balancing](./examples/74_blackwell_gemm_streamk/blackwell_gemm_streamk.cu).
  - Grouped GEMM for [vanilla FP8 data inputs](./examples/75_blackwell_grouped_gemm/75_blackwell_grouped_gemm.cu) and [NVFP4 block scaled inputs](./examples/75_blackwell_grouped_gemm/75_blackwell_grouped_gemm_block_scaled.cu).
  - Convolution kernels for [fprop](./examples/76_blackwell_conv/76_blackwell_conv_fprop.cu), [dgrad](./examples/76_blackwell_conv/76_blackwell_conv_dgrad.cu), and [wgrad](./examples/76_blackwell_conv/76_blackwell_conv_wgrad.cu).
  - [Fused multi-head attention fprop kernel](./examples/77_blackwell_fmha/77_blackwell_fmha.cu) supporting fp16/bf16/fp8 data types across head dims of 32,64, and 128.
* Documentation updates:
  - [Quickstart - instantiating a Blackwell block-scaled GEMM](./media/docs/quickstart.md#instantiating-a-blackwell-gemm-kernel).
  - Detailed [Blackwell block-scaled GEMM functionality documentation](./media/docs/narrow_and_mixed_precision_gemms.md)
  - A new [functionality documentation](./media/docs/functionality.md) specifically for 3.x API comprehensively documenting all supported kernel types, data types, kernel features, minimum CUDA tookit support etc for 3.x supported architectures.
  - Updates to [compatibility](./README.md#compatibility) section regarding supported compilers, operating systems, CUDA Toolkits, Hardware Architectures, and [Target Architecture](./README.md#Target-Architecture).

Note: CUTLASS 3.x builds are known to be broken on Windows platforms for all CUDA toolkits.
CUTLASS team is working on a fix.

**See the [CHANGELOG](CHANGELOG.md) for details of all past releases and updates.**

# Performance

CUTLASS primitives are very efficient.  When used to construct device-wide GEMM kernels,
they exhibit nearly optimal utilization of peak theoretical throughput. The figure below
shows CUTLASS 3.8's performance as a % of theoretical peak utilization 
on various input and output data types when run on NVIDIA Blackwell SM100 architecture GPU.

<p align="center"><img src=media/images/cutlass-3.8-blackwell-gemm-peak-performance.svg></p>

The two figures below show the continual CUTLASS performance improvements 
on an [NVIDIA H100](https://www.nvidia.com/en-us/data-center/h100/) (NVIDIA Hopper architecture) since
CUTLASS 3.1.
CUTLASS 3.5.1 was compiled with the [CUDA 12.5u1 Toolkit](https://developer.nvidia.com/cuda-downloads). 
Tensor Core operations are implemented using CUDA's 
[mma](https://docs.nvidia.com/cuda/parallel-thread-execution/index.html#warp-level-matrix-instructions-mma) and
[wgmma](https://docs.nvidia.com/cuda/parallel-thread-execution/index.html#asynchronous-warpgroup-level-matrix-instructions) instructions.

<p align="center"><img src=media/images/cutlass-3.5.1-gemm-peak-performance.png></p>
<p align="center"><img src=media/images/cutlass-3.5.1-gemm-peak-performance-fp8.png></p>

# CuTe

CUTLASS 3.0 introduced a new core library, CuTe, to describe and manipulate tensors of threads and data.
CuTe is a collection of C++ CUDA template abstractions for
defining and operating on hierarchically multidimensional layouts of threads and data.
CuTe provides `Layout` and `Tensor` objects that compactly package the type,
shape, memory space, and layout of data, while performing the complicated indexing for the user.
This lets programmers focus on the logical descriptions of their algorithms while
CuTe does the mechanical bookkeeping for them. With these tools, we can quickly design,
implement, and modify all dense linear algebra operations.

The core abstractions of CuTe are hierarchically multidimensional layouts
which can be composed with data arrays to represent tensors.
The representation of layouts is powerful enough to represent nearly
everything we need to implement efficient dense linear algebra.
Layouts can also be combined and manipulated via functional composition, on which we build a large set of common operations such as tiling and partitioning.

CUTLASS 3.0 and beyond adopts CuTe throughout the GEMM hierarchy in its templates.
This greatly simplifies the design and improves code composability and readability.
More documentation specific to CuTe can be found in its
[dedicated documentation directory](./media/docs/cute/00_quickstart.md).

# Compatibility

Minimum requirements:

- Architecture: Volta (compute capability 7.0)
- Compiler: Must support at least C++17
- CUDA Toolkit version: 11.4

CUTLASS requires a C++17 host compiler and 
performs best when built with the [**CUDA 12.8 Toolkit**](https://developer.nvidia.com/cuda-downloads).
It is also compatible with CUDA 11.4, CUDA 11.5, CUDA 11.6, CUDA 11.7, CUDA 11.8, and all other CUDA 12.x versions.

## Operating Systems

We have tested the following environments.

|**Operating System** | **Compiler** |
|-----------------|----------|
| Ubuntu 18.04 | GCC 7.5.0  |
| Ubuntu 20.04 | GCC 10.3.0 |
| Ubuntu 22.04 | GCC 11.2.0 |

Note: GCC 8.5.0 has known regressions regarding fold expressions and overloaded operators. Using GCC 7.5.0 or (preferred) GCC >= 9 is recommended.

Note: CUTLASS 3.x builds are known to be broken on Windows platforms for all CUDA toolkits.
CUTLASS team is working on a fix.

## Hardware

CUTLASS runs successfully on the following NVIDIA GPUs, and it is expected to be efficient on Volta, Turing, Ampere, Ada, and Hopper architecture based NVIDIA GPUs.

|**GPU**|**CUDA Compute Capability**|**Minimum CUDA Toolkit Required by CUTLASS-3**|
|---|---|---|
|NVIDIA V100 Tensor Core GPU            |7.0|11.4|
|NVIDIA TitanV                          |7.0|11.4|
|NVIDIA GeForce RTX 20x0 series         |7.5|11.4|
|NVIDIA T4                              |7.5|11.4|
|NVIDIA A100 Tensor Core GPU            |8.0|11.4|
|NVIDIA A10                             |8.6|11.4|
|NVIDIA GeForce RTX 30x0 series         |8.6|11.4|
|NVIDIA GeForce RTX 40x0 series         |8.9|11.8|
|NVIDIA L40                             |8.9|11.8|
|NVIDIA H100 Tensor Core GPU            |9.0|11.8|
|NVIDIA H200 Tensor Core GPU            |9.0|11.8|
|NVIDIA B200 Tensor Core GPU            |10.0|12.8|

## Target Architecture

In general, PTX code generated for one target architecture can be run on future architectures
(i.e., it is forward compatible).
However, CUDA 12.0 introduced the concept of "architecture-accelerated features" whose
PTX does not have forward compatibility guarantees.
Several Hopper and Blackwell PTX instructions fall under this category of
architecture-accelerated features, and thus require a `sm_90a` or `sm100a` target architecture
(note the "a" appended). For more details on this and other architecture-accelerated instructions,
please refer to the [CUDA Documentation](https://docs.nvidia.com/cuda/cuda-c-programming-guide/index.html#feature-availability).

The target architecture information is passed on to CUTLASS via the cmake flag
`CUTLASS_NVCC_ARCHS`. In order to maximize performance on Hopper GH100,
users are required to build CUTLASS with `90a` as the target architecture.
If a user accidentally builds a kernel which uses SM90a features
(e.g. Hopper Tensor Core Instructions), using the SM90 target
(note the lack of "a"), with either CUDA Toolkit 12 or 11.8,
the kernel is expected to fail with a runtime error.

```
cmake .. -DCUTLASS_NVCC_ARCHS="90a"
```
Or 

```
cmake .. -DCUTLASS_NVCC_ARCHS="100a" 
```

Note: The NVIDIA Blackwell SM100 architecture used in the datacenter 
products has a different compute capability than the one underpinning 
NVIDIA Blackwell GeForce RTX 50 series GPUs. As a result, kernels 
compiled for Blackwell SM100 architecture with arch conditional features 
(using `sm100a`) are not compatible with RTX 50 series GPUs. 

Please refer to the [functionality documentation](./media/docs/functionality.md)
for details on which kernels require which target architectures.

# Documentation

CUTLASS is described in the following documents and the accompanying
[Doxygen documentation](https://nvidia.github.io/cutlass).

- [Quick Start Guide](./media/docs/quickstart.md) - basics of building and running CUTLASS
- [Functionality](./media/docs/functionality.md) - summarizes functionality available in CUTLASS
- [Efficient GEMM in CUDA](./media/docs/efficient_gemm.md) - describes how GEMM kernels may be implemented efficiently in CUDA
- [CUTLASS 3.x Design](./media/docs/cutlass_3x_design.md) - describes the CUTLASS 3.x design, its benefits, and how CuTe enables us to write much more composable components
- [GEMM API 3.x](./media/docs/gemm_api_3x.md) - describes the CUTLASS 3.x GEMM model and C++ template concepts
- [GEMM API 2.x](./media/docs/gemm_api.md) - describes the CUTLASS 2.x GEMM model and C++ template concepts
- [Implicit GEMM Convolution](./media/docs/implicit_gemm_convolution.md) - describes 2-D and 3-D convolution in CUTLASS
- [Code Organization](./media/docs/code_organization.md) - describes the organization and contents of the CUTLASS project
- [Terminology](./media/docs/terminology.md) - describes terms used in the code
- [Programming Guidelines](./media/docs/programming_guidelines.md) - guidelines for writing efficient modern CUDA C++
- [Fundamental types](./media/docs/fundamental_types.md) - describes basic C++ classes used in CUTLASS to represent numeric quantities and arrays
- [Layouts](./media/docs/layout.md) - describes layouts of matrices and tensors in memory
- [Tile Iterators](./media/docs/tile_iterator_concept.md) - describes C++ concepts for iterating over tiles of matrices in memory
- [CUTLASS Profiler](./media/docs/profiler.md) - command-line driven profiling application
- [CUTLASS Utilities](./media/docs/utilities.md) - additional templates used to facilitate rapid development
- [Dependent kernel launch](./media/docs/dependent_kernel_launch.md) - describes a new feature in Hopper which allows overlapping dependent 
kernels in the same stream, and how it is used in CUTLASS.

# Resources
We have also described the structure of an efficient GEMM in our talk at the
[GPU Technology Conference 2018](http://on-demand.gputechconf.com/gtc/2018/presentation/s8854-cutlass-software-primitives-for-dense-linear-algebra-at-all-levels-and-scales-within-cuda.pdf).

- [CUTLASS: Software Primitives for Dense Linear Algebra at All Levels and Scales within CUDA](https://www.nvidia.com/en-us/on-demand/session/gtcsiliconvalley2018-s8854/)
- [Developing CUDA Kernels to Push Tensor Cores to the Absolute Limit on NVIDIA A100](https://www.nvidia.com/en-us/on-demand/session/gtcsj20-s21745/)
- [Accelerating Convolution with Tensor Cores in CUTLASS](https://www.nvidia.com/en-us/on-demand/session/gtcspring21-s31883/)
- [Accelerating Backward Data Gradient by Increasing Tensor Core Utilization in CUTLASS](https://www.nvidia.com/en-us/on-demand/session/gtcspring22-s41996/)
- [CUTLASS: Python API, Enhancements, and NVIDIA Hopper](https://www.nvidia.com/en-us/on-demand/session/gtcfall22-a41131/)

# Building CUTLASS

CUTLASS is a header-only template library and does not need to be built to be used by other
projects. Client applications should target CUTLASS's `include/` directory in their include
paths.

CUTLASS unit tests, examples, and utilities can be build with CMake.
The minimum version of CMake is given in the [Quickstart guide](./media/docs/quickstart.md).
Make sure the `CUDACXX` environment  variable points to NVCC in the CUDA Toolkit installed
on your system.

```bash
$ export CUDACXX=${CUDA_INSTALL_PATH}/bin/nvcc
```

Create a build directory within the CUTLASS project, then run CMake. By default CUTLASS will build kernels
for CUDA architecture versions 5.0, 6.0, 6.1, 7.0, 7.5, 8.0, 8.6, 8.9, and 9.0.
To reduce compile time you can specify
the architectures to build CUTLASS for by changing the CMake configuration setting
`CUTLASS_NVCC_ARCHS`.

```bash
$ mkdir build && cd build

$ cmake .. -DCUTLASS_NVCC_ARCHS=80               # compiles for NVIDIA's Ampere Architecture
```

From the `build/` directory, compile and run the CUTLASS unit tests by building the target `test_unit` with make.

The unit tests are organized as several binaries mirroring the top-level namespaces of CUTLASS,
and they may be executed in parallel via make's `-j` command line argument.

```bash
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
[CUTLASS documentation](./media/docs/code_organization.md), but several main components are summarized below.

## CUTLASS Template Library

```
include/                     # client applications should target this directory in their build's include paths

  cutlass/                   # CUDA Templates for Linear Algebra Subroutines and Solvers - headers only

    arch/                    # direct exposure of architecture features (including instruction-level GEMMs)

    conv/                    # code specialized for convolution

    epilogue/                # code specialized for the epilogue of gemm/convolution

    gemm/                    # code specialized for general matrix product computations

    layout/                  # layout definitions for matrices, tensors, and other mathematical objects in memory

    platform/                # CUDA-capable Standard Library components

    reduction/               # bandwidth-limited reduction kernels that do not fit the "gemm" model

    thread/                  # simt code that can be performed within a CUDA thread
    
    transform/               # code specialized for layout, type, and domain transformations

    *                        # core vocabulary types, containers, and basic numeric operations

  cute/                      # CuTe Layout, layout algebra, MMA/Copy atoms, tiled MMA/Copy

    algorithm/               # Definitions of core operations such as copy, gemm, and operations on cute::tuples

    arch/                    # Bare bones PTX wrapper structs for copy and math instructions

    atom/                    # Meta-information either link to or built from arch/ operators

      mma_atom.hpp           # cute::Mma_Atom and cute::TiledMma

      copy_atom.hpp          # cute::Copy_Atom and cute::TiledCopy

      *sm*.hpp               # Arch specific meta-information for copy and math operations

    *                        # Core library types such as Shape, Stride, Layout, Tensor, and associated operations

```

### CUTLASS SDK Examples

[CUTLASS SDK examples](./examples) apply CUTLASS templates to implement basic computations.

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

Instructions for building and running the Unit tests are described in the [Quickstart guide](./media/docs/quickstart.md).

# Performance Profiling

The `tools/profiler/` directory contains a command-line utility for launching each of the GEMM kernels.
It can be built as follows:

```bash
$ make cutlass_profiler -j16
```
## Building all GEMM and Convolution kernels (_long_ build times)

By default, only one tile size is instantiated for each data type, math instruction, and layout.
To instantiate all, set the following environment variable when running CMake from an empty `build/` directory.
Beware, this results in *tens of thousands* of kernels and long build times. 
This would also result in a large binary size and on some platforms linker to fail on building the library.
Therefore, it's highly recommended to generate only a subset of kernels as demonstrated in the sub-section below.
```bash
$ cmake .. -DCUTLASS_NVCC_ARCHS=90a -DCUTLASS_LIBRARY_KERNELS=all
...
$ make cutlass_profiler -j16
```

## Building a subset of GEMM and Convolution kernels (_reduced_ build times)

To compile strictly one kernel or a small set of kernels, a comma-delimited list of kernel names with 
wildcard characters may be used to reduce the set of kernels. The following examples show building exactly one
or a subset of kernels for NVIDIA Ampere and Turing architecture:

### Building a subset Tensor Core GEMM kernels

To compile a subset of Tensor Core GEMM kernels with FP32 accumulation and FP16 input targeting NVIDIA Ampere and Turing architecture, 
use the below cmake command line:
```bash
$ cmake .. -DCUTLASS_NVCC_ARCHS='75;80' -DCUTLASS_LIBRARY_KERNELS=cutlass_tensorop_s*gemm_f16_*_nt_align8
...
$ make cutlass_profiler -j16
```

Example command line for profiling a subset of Tensor Core GEMM kernels is as follows:
```bash
./tools/profiler/cutlass_profiler --kernels=cutlass_tensorop_s*gemm_f16_*_nt_align8 --m=3456 --n=4096 --k=4096

...
=============================
  Problem ID: 1

        Provider: CUTLASS
   OperationKind: gemm
       Operation: cutlass_tensorop_s1688gemm_f16_256x128_32x2_nt_align8

          Status: Success
    Verification: ON
     Disposition: Passed

reference_device: Passed
          cuBLAS: Passed

       Arguments: --gemm_kind=universal --m=3456 --n=4096 --k=4096 --A=f16:column --B=f16:row --C=f32:column --alpha=1  \
                  --beta=0 --split_k_slices=1 --batch_count=1 --op_class=tensorop --accum=f32 --cta_m=256 --cta_n=128  \
                  --cta_k=32 --stages=2 --warps_m=4 --warps_n=2 --warps_k=1 --inst_m=16 --inst_n=8 --inst_k=8 --min_cc=75  \
                  --max_cc=1024

           Bytes: 118489088  bytes
           FLOPs: 115992428544  flops

         Runtime: 1.55948  ms
          Memory: 70.7616 GiB/s

            Math: 74378.8 GFLOP/s



=============================
...
```

### Building one CUDA Core GEMM kernel

To compile one SGEMM kernel targeting NVIDIA Ampere and Turing architecture, use the below cmake command line:
```bash
$ cmake .. -DCUTLASS_NVCC_ARCHS='75;80' -DCUTLASS_LIBRARY_KERNELS=cutlass_simt_sgemm_128x128_8x2_nn_align1
...
$ make cutlass_profiler -j16
```

Example command line for profiling single SGEMM CUDA kernel is as follows:
```bash
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

=============================
```

### Building a subset of Tensor Core Convolution kernels

To compile a subset of Tensor core convolution kernels implementing forward propagation (fprop) with FP32 accumulation 
and FP16 input targeting NVIDIA Ampere and Turing architecture, use the below cmake command line:
```bash
$ cmake .. -DCUTLASS_NVCC_ARCHS='75;80' -DCUTLASS_LIBRARY_KERNELS=cutlass_tensorop_s*fprop_optimized_f16
...
$ make cutlass_profiler -j16
```

Example command line for profiling a subset of Tensor Core convolution kernels is as follows:

```bash
$ ./tools/profiler/cutlass_profiler --kernels=cutlass_tensorop_s*fprop_optimized_f16 --n=8 --h=224 --w=224 --c=128 --k=128 --r=3 --s=3

...
=============================
  Problem ID: 1

        Provider: CUTLASS
   OperationKind: conv2d
       Operation: cutlass_tensorop_s16816fprop_optimized_f16_128x128_32x5_nhwc

          Status: Success
    Verification: ON
     Disposition: Passed

reference_device: Passed

       Arguments: --conv_kind=fprop --n=8 --h=224 --w=224 --c=128 --k=128 --r=3 --s=3 --p=224 --q=224 --pad_h=1 --pad_w=1  \
                  --stride_h=1 --stride_w=1 --dilation_h=1 --dilation_w=1 --Activation=f16:nhwc --Filter=f16:nhwc --Output=f32:nhwc  \
                  --conv_mode=cross --iterator_algorithm=optimized --alpha=1 --beta=0 --split_k_mode=serial --split_k_slices=1  \
                  --eq_gemm_provider=none --op_class=tensorop --accum=f32 --cta_m=128 --cta_n=128 --cta_k=32 --stages=5  \
                  --warps_m=2 --warps_n=2 --warps_k=1 --inst_m=16 --inst_n=8 --inst_k=16 --min_cc=80 --max_cc=1024

           Bytes: 1130659840  bytes
           FLOPs: 118482796544  flops

         Runtime: 0.711496  ms
          Memory: 1479.99 GiB/s

            Math: 166526 GFLOP/s

=============================
...
```


### Building one Convolution CUDA kernel

To compile and run one CUDA Core convolution kernel implementing forward propagation (fprop) with F32 accumulation 
and FP32 input targeting NVIDIA Ampere and Turing architecture, use the below cmake command line:
```bash
$ cmake .. -DCUTLASS_NVCC_ARCHS='75;80' -DCUTLASS_LIBRARY_KERNELS=cutlass_simt_sfprop_optimized_128x128_8x2_nhwc
...
$ make cutlass_profiler -j16
```

Example command line for profiling one CUDA Core convolution kernel:

```bash
$ ./tools/profiler/cutlass_profiler --kernels=cutlass_simt_sfprop_optimized_128x128_8x2_nhwc --n=8 --h=224 --w=224 --c=128 --k=128 --r=3 --s=3


=============================
  Problem ID: 1

        Provider: CUTLASS
   OperationKind: conv2d
       Operation: cutlass_simt_sfprop_optimized_128x128_8x2_nhwc

          Status: Success
    Verification: ON
     Disposition: Passed

reference_device: Passed

       Arguments: --conv_kind=fprop --n=8 --h=224 --w=224 --c=128 --k=128 --r=3 --s=3 --p=224 --q=224 --pad_h=1 --pad_w=1  \
                  --stride_h=1 --stride_w=1 --dilation_h=1 --dilation_w=1 --Activation=f32:nhwc --Filter=f32:nhwc --Output=f32:nhwc  \
                  --conv_mode=cross --iterator_algorithm=optimized --alpha=1 --beta=0 --split_k_mode=serial --split_k_slices=1  \
                  --eq_gemm_provider=none --op_class=simt --accum=f32 --cta_m=128 --cta_n=128 --cta_k=8 --stages=2 --warps_m=4  \
                  --warps_n=2 --warps_k=1 --inst_m=1 --inst_n=1 --inst_k=1 --min_cc=50 --max_cc=1024

           Bytes: 2055798784  bytes
           FLOPs: 118482796544  flops

         Runtime: 7.34266  ms
          Memory: 260.752 GiB/s

            Math: 16136.2 GFLOP/s


=============================

```

## More Details on Compiling CUTLASS Kernels and CUTLASS Profiler
- Please follow the links for more CMake examples on selectively compiling CUTLASS kernels:
  - [GEMM CMake Examples](./media/docs/quickstart.md#gemm-cmake-examples) 
  - [Implicit GEMM convolution CMake Examples](./media/docs/quickstart.md#convolution-cmake-examples)
- [Further details about the CUTLASS Profiler are described here.](./media/docs/profiler.md)


# About

CUTLASS is released by NVIDIA Corporation as Open Source software under the 
[3-clause "New" BSD license](LICENSE.txt).

# Contributors

The official list of CUTLASS developers and contributors is available here: [CONTRIBUTORS](CONTRIBUTORS.md).

# Copyright

Copyright (c) 2017 - 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
SPDX-License-Identifier: BSD-3-Clause

```
  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are met:

  1. Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer.

  2. Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.

  3. Neither the name of the copyright holder nor the names of its
  contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
  FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
  CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
```
