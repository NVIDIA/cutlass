![ALT](/media/fig-09-complete-hierarchy.png "Complete CUDA GEMM decomposition")

# Introduction

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
multiply-accumulate abstractions for 8-bit integer, half-precision floating 
point (FP16), single-precision floating point (FP32), and double-precision floating 
point (FP64) types.  Furthermore, CUTLASS demonstrates CUDA's WMMA API for targeting
the programmable, high-throughput _Tensor Cores_ provided by NVIDIA's Volta architecture 
and beyond.

For more exposition, see our Parallel Forall blog post ["CUTLASS: Fast Linear Algebra 
in CUDA C++"](https://devblogs.nvidia.com/parallelforall/cutlass-linear-algebra-cuda). 

# Performance

![ALT](/media/cutlass-performance-plot.png "Relative performance of CUTLASS and cuBLAS for large matrices")

CUTLASS primitives are very efficient.  When used to construct device-wide GEMM kernels, 
they exhibit performance comparable to cuBLAS for scalar GEMM 
computations. The above figure shows CUTLASS performance relative to cuBLAS 
for large matrix dimensions (M=10240, N=K=4096) running on an NVIDIA Tesla V100 GPU 
when compiled with CUDA 9.0. 

# Project Structure

CUTLASS is arranged as a header-only library with several example test programs
that demonstrate instantiating a GEMM task within a CUDA kernel. Comments inline
with the source explain the individual components.

The repository is organized in the following arrangement.

    cutlass/                Root of header-only source library for matrix multiply
      gemm/                 Implementation of GEMM __device__ code and supporting components
      util/                 Utility components for CUDA device-side CUDA development

A test program is provided to illustrate the use of CUTLASS. This is implemented
in the following directory.

    cutlass_test            Root of test programs depicting CUTLASS kernels
      util/                 Utilities
      gemm.cu               Simple example calling CUTLASS and CUBLAS GEMM kernels
      Makefile              Build script for test programs


# Makefile usage

There are different sample targets for different GEMM data types and
transposititions.  Be sure to specify your target architecture.

    make <sgemm|dgemm|hgemm|igemm|wgemm> sm=<60|61|70> \
      [transpose=<nn|nt|tn|tt>] [verbose=<0|1>] [keep=<0|1>]


# Program usage

 Program usage:

     <s|d|h|i|w>gemm_<nn|nt|tn|tt>
           [--help]
           [--schmoo=<#schmoo-samples> || --m=<height> --n=<width> --k=<depth>]
           [--i=<timing iterations>]
           [--device=<device-id>]
           [--alpha=<alpha> --beta=<beta>]


# About

CUTLASS is released by NVIDIA Corporation as Open Source software under the
BSD license.


# Copyright

Copyright (c) 2011-2017, NVIDIA CORPORATION.  All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are not permitted.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL NVIDIA CORPORATION BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
