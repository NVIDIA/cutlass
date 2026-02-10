# NVIDIA Hopper SSD (State Space Decomposition) CUDA Example

## Overview

This example demonstrates the implementation of State Space Decomposition (SSD) operations on NVIDIA's Hopper GPU architecture. It showcases the use of CUTLASS library components for high-performance tensor computations that efficiently leverage Hopper's advanced hardware capabilities, including TMA (Tensor Memory Accelerator) and warp specialization.

## System Requirements
+ NVIDIA GPU with Hopper Architecture (compute capability 9.0)
+ CUDA Toolkit 12.0 or newer
+ C++17 compatible compiler

## Build the example
Follow the cutlass example building.

## Command Line Options
The example supports the following command line options:
--help: Display the usage statement
--iterations=<int>: Number of iterations for benchmarking (default: 1)
--without_verify: Skip result verification
--verbose: Print execution time per kernel
--G=<int>: Group size (default: 2)
--B=<int>: Batch size (default: 3)
--E=<int>: Expanded factor (default: 2)
--H=<int>: Number of heads (default: 2)

## Limitation
+ Only support LxDxN = 128x64x128
+ Uses bfloat16 precision for input/output tensors

## Performance
+ Utilizes TMA (Tensor Memory Accelerator) for efficient memory access
+ Implements warp-specialized kernels for optimal resource utilization
+ Limited by the SEGSUM (segment sum) computation part
+ ALU bound operation

# Copyright

Copyright (c) 2024 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

