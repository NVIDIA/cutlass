# SYCL CUTLASS Changelog

## [Cutlass 3.9 SYCL backend Version 0.1](https://github.com/codeplay/cutlass-fork/releases/tag/v3.9-0.1) (2025-04-30)
- Support for Intel GPU Data Center Max (1100 and 1550) 
- Support for Intel Arc B580 Battlemage 
- GEMM/StreamK/SplitK with support for bfloat16 data type
- Flash attention prefill and decode with KV cache with support for bfloat16 data type
- Support for epilogue operations:
  - Element-wise, row-wise and column-wise bias
  - ReLU, SiLU, GELU activation fns
  - Softmax
- Mixed precision GEMM (bfloat16/int8, half/int4) with dequantization support
- Dual GEMM & Grouped GEMM
