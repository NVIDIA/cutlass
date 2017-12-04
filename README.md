# Introduction

CUTLASS is a CUDA C++ template library for implementing matrix-multiply
procedures that may be instantiated in CUDA device kernels. CUTLASS applies
object-oriented and generic programming techniques to maximize flexibility of
the resulting code and facilitate composition with caller-supplied functionality.
CUDA C++ templates are used to specify policy decisions such as block sizes,
data types of input and accumulator operands, and element-wise operations applied
to the results of matrix multiply.

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
           [--schmoo || --m=<height> --n=<width> --k=<depth>]
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
