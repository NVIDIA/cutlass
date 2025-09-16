# CUTLASS SYCL - Programming Examples

> [!IMPORTANT]
> ### ⚠️ **Not for Benchmarking!** ⚠️
> 
> These examples are designed **solely for demonstrating CUTLASS-SYCL functionality** and may **NOT be optimized for performance benchmarking**.
> 

### Build Requirements

- **CUTLASS_ENABLE_SYCL=ON**: Required to enable SYCL support
- **Intel GPU Examples**: Require `SYCL_INTEL_TARGET=ON` for Intel GPU optimizations
- **NVIDIA GPU Examples**: Require `SYCL_NVIDIA_TARGET=ON` for NVIDIA GPU optimizations

### Directory Structure

```
examples/
├── 00_bmg_gemm/                     # Intel GPU examples
├── 01_bmg_gemm_with_collective_builder/
├── ...
├── 10_bmg_grouped_gemm_mixed_dtype/
├── cute/                            # CuTe tutorial examples
│   └── tutorial/                    
├── generics/                        # Device-agnostic SYCL examples
│   └── device_agnostic/
└── nv_sycl/                         # NVIDIA SYCL examples
    ├── 00_ampere_tf32_tensorop_gemm/
    └── 01_gemm_softmax/
```

## CUTLASS-SYCL Examples for Intel GPUs

The following examples are optimized for Intel GPU architectures using SYCL:

* [00_bmg_gemm](00_bmg_gemm/)
    
    Simple GEMM implementation on Intel PVC with single precision inputs and outputs

* [01_bmg_gemm_with_collective_builder](01_bmg_gemm_with_collective_builder/)

    Demonstrates the use of CollectiveBuilder to construct an Intel PVC/BMG GEMM

* [02_bmg_gemm_mixed_dtype](02_bmg_gemm_mixed_dtype/)

    Mixed Precision PVC/BMG GEMM (including support for dequantization)

* [03_bmg_gemm_streamk](03_bmg_gemm_streamk/)

    PVC/BMG GEMM kernel using Stream-K scheduler for improved load balancing

* [04_bmg_grouped_gemm](04_bmg_grouped_gemm/)

    PVC/BMG Group GEMM example demonstrating batch of GEMM operations with distinct problem sizes

* [05_bmg_gemm_with_epilogues](05_bmg_gemm_with_epilogues/)

    Various GEMM epilogue examples implemented using Epilogue Visitor Tree (EVT)

* [06_bmg_flash_attention](06_bmg_flash_attention/)

    Implementation of V2 of the Flash Attention algorithm on Intel PVC/BMG

* [07_bmg_dual_gemm](07_bmg_dual_gemm/)

    Fuses 2 GEMM operations which share an A-matrix into a single kernel on PVC/BMG

* [08_bmg_gemm_f8](08_bmg_gemm_f8/)

    Demonstrates support for 8-bit float (to 32-bit float output) GEMM on PVC/BMG

* [09_bmg_grouped_gemm_f8](09_bmg_grouped_gemm_f8/)

    FP8 Grouped GEMM operations on Intel PVC/BMG

* [10_bmg_grouped_gemm_mixed_dtype](10_bmg_grouped_gemm_mixed_dtype/)

    Mixed precision Grouped GEMM operations on Intel PVC/BMG

## Device-Agnostic SYCL Examples

These examples work across different SYCL implementations and devices:

* [generics/device_agnostic](generics/device_agnostic/)

    Generic GEMM kernel implementation that can be executed on any SYCL-compatible device

## NVIDIA SYCL Examples

SYCL implementations of traditional NVIDIA CUDA examples:

* [nv_sycl/00_ampere_tf32_tensorop_gemm](nv_sycl/00_ampere_tf32_tensorop_gemm/)

    SYCL implementation demonstrating FP32 GEMM with implicit TF32 conversion for NVIDIA Ampere architecture

* [nv_sycl/01_gemm_softmax](nv_sycl/01_gemm_softmax/)

    SYCL implementation demonstrating GEMM fused with Softmax in mixed precision using NVIDIA Tensor Cores



# CuTe - Programming Examples

Examples that do not rely on CUTLASS and directly showcase the features of CuTe are located in [cutlass/examples/cute](./cute/).

Additionally, CuTe's core layout and layout algebra have their own test cases within [cutlass/test/unit/cute/core/](../test/unit/cute/core/) that users might find useful as examples of CuTe.

# Python Interface Examples

Examples leveraging CUTLASS's [Python interface](../python/README.md) are located in [cutlass/examples/python](python/).

# Copyright

Copyright (c) 2017 - 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved. \
Copyright (C) 2025 Intel Corporation, All rights reserved.
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
