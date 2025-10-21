# CUTLASS Tutorial Examples for Blackwell GEMM

This folder contains tutorial examples demonstrating how to write performant GEMM (General Matrix Multiplication) kernels using Tensor Cores on NVIDIA Blackwell GPUs.

## Overview

The examples showcase different scenarios and optimization techniques for implementing GEMM operations:

- Basic FP16 GEMM implementation
- Software Pipeline optimizations
- Tensor Core utilization
- Thread/warp/block level parallelism

## Examples

### tutorial_fp16_gemm_0.py

A basic example showing:
- FP16 GEMM implementation using Tensor Cores
- TMA (Tensor Memory Access) for efficient data loading
- SMEM (Shared Memory) layouts and access patterns
- Usage of ``cutlass.range(..., prefetch_stages=...)`` to replace boilerplate code for multi-stage software pipeline

With some minor optimization tricks
- Tiling Epilogue to avoid bursty write out and reduce register pressure
