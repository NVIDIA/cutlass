# SYCL*TLA (previously referred to as cutlass-sycl) Changelog

## [SYCL*TLA 0.6](https://github.com/intel/sycl-tla/releases/tag/v0.6) (2025-11-03)
### Major Architecture Changes
- **Flash Attention Reimplementation ([#d02c58b](https://github.com/intel/sycl-tla/commit/d02c58b4))**: Complete rewrite of Flash Attention using new Xe atoms
  - Enhanced performance with optimized memory access patterns
  - Better integration with Intel Xe hardware capabilities
- **CUTLASS Library Generation ([#578](https://github.com/intel/sycl-tla/pull/578))**: Full support for CUTLASS library generation and operations
  - New Xe architecture support in library generation pipeline
  - Automated kernel instantiation and compilation support

### Enhancements
- **Python Operations Support ([#595](https://github.com/intel/sycl-tla/pull/595))**: Enhanced Python bindings with comprehensive test coverage
  - Improved Python API stability and usability
  - Enhanced test framework for Python operations
- **CuTe Subgroup Extensions**: New subgroup-scope operations for Intel Xe
  - Subgroup broadcast and reduction operations ([#9a6aa27](https://github.com/intel/sycl-tla/commit/9a6aa27c))
  - `make_subgroup_tensor` helpers for improved tensor manipulation ([#21fb89a](https://github.com/intel/sycl-tla/commit/21fb89a8))
- **Enhanced 2D Copy Operations**: Extended block 2D copy functionality
  - New `make_block_2d_copy_{C,D}` variants with subtiling support ([#48d82e8](https://github.com/intel/sycl-tla/commit/48d82e87))
  - Support for size-1 fragments in block 2D copies ([#2212f1b](https://github.com/intel/sycl-tla/commit/2212f1b9))
- **4-bit VNNI Reorders ([#593](https://github.com/intel/sycl-tla/pull/593))**: New 4-bit unit stride to VNNI reorder operations
- **Grouped GEMM with new APIs ([#574](https://github.com/intel/sycl-tla/pull/574))**: Enhanced grouped GEMM with new streamlined APIs

### Test Improvements
- **Python Test Coverage**: Comprehensive test suite improvements for Python operations
- **CI Infrastructure**: Enhanced continuous integration with PVC driver updates ([#575](https://github.com/intel/sycl-tla/pull/575))
- **Code Reorganization**: Renamed `python/cutlass` to `python/cutlass_cppgen` for clarity ([#587](https://github.com/intel/sycl-tla/pull/587))

### Bug Fixes
- **Epilogue Data Type Fixes**: 
  - Fixed trD compute type in Xe Epilogue ([#580](https://github.com/intel/sycl-tla/pull/580))
  - Resolved epilogue data type mismatches ([#563](https://github.com/intel/sycl-tla/pull/563))
- **CuTe Copy(new APIs) Improvements**: Multiple fixes for Xe copy operations ([#dec36a9](https://github.com/intel/sycl-tla/commit/dec36a9e))
- **Split Barrier Refactoring**: Improved split barrier functionality for better reliability ([#521dfcd](https://github.com/intel/sycl-tla/commit/521dfcd4))

### Notes and Known Issues
- Python Operations for FP8 and INT8 not generated for CUTLASS library in this release.
- Unit tests and benchmark tests are not yet migrated to newly re architected CuTe APIs.


## [SYCL*TLA 0.5](https://github.com/intel/cutlass-sycl/releases/tag/v0.5) (2025-09-26)
### Major Architecture Changes
- **Xe Rearchitecture ([#477](https://github.com/intel/cutlass-sycl/pull/477))**: Complete redesign of Xe CuTe atoms with new architecture
  - New MMA atoms for improved performance
  - Enhanced 2D copy atoms (loads, stores, prefetch with VNNI/transpose support)
  - New 2D copy helpers (low-level `make_block_2d_copy` and high-level `make_block_2d_copy_{A,B,C}`)
  - Generic and optimized reorder atoms for {int4, uint4, int8, uint8, e2m1, e4m3, e5m2} -> {half, bfloat16}
  - Requires IGC version [v2.18.5](https://github.com/intel/intel-graphics-compiler/releases/tag/v2.18.5) or later  

### New Features  
- **G++ Host Compiler Support ([#490](https://github.com/intel/cutlass-sycl/pull/490))**: Support for G++ 13 as host compiler
  - Migrated `syclcompat` to this repository as `cutlasscompat` for better compatibility
  - Fixed compilation issues when using G++ instead of clang++
  - Added new CI workflow for testing G++ host compiler builds
  - Enhanced build system to support `-DDPCPP_HOST_COMPILER=g++` option
- **Grouped GEMM for Mixed Dtype ([#457](https://github.com/intel/cutlass-sycl/pull/457))**: Extended grouped GEMM support to mixed precision operations
  - Added support for BF16 + S8 mixed dtype grouped GEMM
  - Added support for FP16 + U4 mixed dtype grouped GEMM
  - New examples: `10_bmg_grouped_gemm_bf16_f16_s8.cpp` and `10_bmg_grouped_gemm_f16_u4.cpp`

### Performance and Quality Improvements  
- **Flash Attention Accuracy Fix ([#489](https://github.com/intel/cutlass-sycl/pull/489))**: Resolved accuracy issues when seq_len % QK_BLK_N leaves a remainder
- **Improved Device-Side Random Uniform Filling ([#515](https://github.com/intel/cutlass-sycl/pull/515))**: Enhanced random number generation by reusing host implementation in SYCL
- **GPU Clock Timer Fix ([#511](https://github.com/intel/cutlass-sycl/pull/511))**: Resolved "Event is Already Being Recorded" error in loops
- **Compilation Warning Fixes ([#502](https://github.com/intel/cutlass-sycl/pull/502))**: Fixed warnings to enable -Werror compilation flag

### Code Quality and Refactoring
- **SYCLCompat Integration ([#514](https://github.com/intel/cutlass-sycl/pull/514))**: Imported `SYCLCompat` as `Compat` for better compatibility
- **CausalMask Refactoring ([#507](https://github.com/intel/cutlass-sycl/pull/507))**: Improved Flash Attention kernel code reuse and compiler optimization potential
- **SYCL Debug Trace Compatibility ([#518](https://github.com/intel/cutlass-sycl/pull/518))**: Enhanced debugging capabilities and trace compatibility
- **CuTe Tutorial Updates**: Added `tiled_copy_if` SYCL tutorial

### Testing and Development Infrastructure
- **Enhanced Unit Testing**: Added comprehensive unit tests for 16-bit x 8-bit grouped GEMM operations
- **Code Restructuring**: Refactored examples and codebase to focus on SYCL implementation

### Bug Fixes
- **Variable Name Bug Fix ([#491](https://github.com/intel/cutlass-sycl/pull/491))**: Fixed variable name bugs in CuTe architecture
- **2D Block Prefetch OOB Fix ([#488](https://github.com/intel/cutlass-sycl/pull/488))**: Fixed 2D block prefetch out-of-bounds issues in CuTe arch
- Various minor bug fixes and code improvements

### Notes and Known Issues
- CUTLASS APIs (Gemm/Collectives) are not updated with rearchitected Xe Cute atoms.

## [Cutlass 3.9.2 SYCL backend Version 0.3](https://github.com/codeplay/cutlass-fork/releases/tag/v3.9.2-0.3) (2025-06-30)
- Add support for GEMM FP8 (E5M2 and E4M3)
- Add example for GEMM FP8 with support for channel-wise and group-wise quantization
- Add support for Grouped GEMM FP8
- Improve performance for FP8 to FP16 conversion
- Add support for epilogue data conversion
- Add support for FP16 GEMM with FP16 accumulator
- Add support for BF16 GEMM with BF16 accumulator
- Add support for mixed dtype GEMM with support for tensor-wise, channel-wise and group-wise quantization
- Add example of mixed dtype BF16 + INT8 using channel-wise and group-wise quantization
- Add example of mixed dtype FP16 + INT8 using tensor-wise quantization
- Add example of mixed dtype FP16 + INT4 using channel-wise and group-wise quantization
- Add support for zero-point quantization in INT4 and INT8 data types
- Add support for Flash Attention prefill FP8 with and without KV cache
- Add support for Flash Attention decode FP8 with and without KV cache

## [Cutlass 3.9.2 SYCL backend Version 0.2](https://github.com/codeplay/cutlass-fork/releases/tag/v3.9.2-0.2) (2025-05-30)
- GEMM/StreamK/SplitK with support for FP16 data type
- Flash attention prefill with Paged KV cache with support for FP16 data type
- Performance improvements for flash attention prefill and decode

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
