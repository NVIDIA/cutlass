# Introduction

This example shows fusing two back-to-back GEMMs/Convolutions into one kernel. 

<p align="center"><img src=/media/images/13_example_fusion.png></p>

When running two unfused GEMM/Conv operations, each operation loads one input 
activation matrix, one weight matrix (or filter matrix) from the memory and then 
stores the result activation matrix back to the memory.

When the two GEMM/Conv operations are fused together, the mainloops of the two
GEMMs/Convs run back to back in a single kernel. The output accumulator of the
1st GEMM/Conv will be stored in the register file and reused as the activation
input of the 2nd GEMM/Conv. This saves a round trip to memory for the activation
matrix.


This example computes the following:
- 1st GEMM/Conv: D0 = relu(alpha0 .\* A0 \*\* B0)
- 2nd GEMM/Conv: D1 = relu(alpha1 .\* D0 \*\* B1 + beta1 .\* C1)

In the above equation, operator \*\* can be matrix multiplication or convolution operation.

# Implementation Details

In order to run two GEMM/Convs in a single kernel, the example requires the same number of
threadblocks are used across 2 GEMMs/Convs. This also ensures the same threadblock tile M across
2 GEMMs/Convs.

In order to reuse the output accumulator (stored in register-file) of the 1st GEMM as the 
input activation, the example enforces the following two constraints:

- thread_block_tile_N = problem_N 

<p align="center"><img src=/media/images/13_example_block_resident_fusion.png></p>

This constraint ensures that each threadblock loads the entire weight/filter matrix in
addition to its own input activation tile. Therefore the input activation tile of the
2nd GEMM/Conv only depends on the output activation tile of the 1st GEMM/Conv, and the
operation can be fully block-resident.

- warp_tile_N = thread_block_tile_N 

<p align="center"><img src=/media/images/13_example_rf_resident_fusion.png></p>

This constraint ensures that each warp loads the entire weight/filter kBlock in
addition to its own input activation tile. Therefore the input activation warp tile of the
2nd GEMM/Conv only depends on the output warp accumulator of the 1st GEMM/Conv in the
register file, and the operation can be fully register-file-resident.

When applying the above constraint to convolutions, it is required that the 2nd Convolution
kernel doesn't have halos such that data used by each threadblock doesn't depend on any other
threadblock. Typically this requires the 2nd Convolution uses 1x1 filter without any paddings.

# Copyright

Copyright (c) 2017-2021, NVIDIA CORPORATION.  All rights reserved.

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
  STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
```

