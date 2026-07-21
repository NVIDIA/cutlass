# FP16 x FP16 x FP16 GEMM with Tensor Memory Accelerator (TMA) on Blackwell

High-performance general matrix multiply (GEMM) kernel for NVIDIA Blackwell GPUs (SM120a) using CUTE library and Tensor Memory Accelerator，idmatrix.

## Features
- **Tensor core**: The Blackwell RTX50 series can only use the ordinary Tensorcore，which is the regular MMA.(attention：SM120 don't have GMMA and 5th tensorcore Cluster characteristics).
- **Data Type**: FP16 (half precision) throughout
- **Tensor Memory Accelerator (TMA)**: Hardware-accelerated data movement from global to shared memory.Using cute::GMMA::Layout_K_SW128_Atom to avoid bankflict,TMA can be transferred in units of 128 bytes and full speed ahead (To use TMA, SM20a compilation optimization is required)
- **TMA Store**: Efficient result writeback using hardware accelerators.
- **Idmatrix**: Vectorized loading of share into registers.Each thread maximizes the loading of 16 bytes to tensorcore.
- **Ping-Pong Double Buffering**: Overlaps computation and data transfer for maximum pipeline utilization.The share of RTX5070,RTX5090 is only 102.4Kbyte，therefore, the design of the pipeline should not be too large,double piplines are good settings.In that case,one SM can run two blocks.Although the theoretical occupancy is still lacking in improvement, the TFLOPS were still objective.
- **Arbitrary Matrix Sizes**: Automatic padding with ceiling division support
- **Tile**: The loaded tile has been loaded fixed,TileM=128，TileN=64，TileK=64，This is the size of the Sharememory processing too.Each cudablock outputs 128x64 tile.(In cases where the matrix K is too large, there may be an impact.)
- **Comprehensive Validation**: Includes CPU verification and cuBLAS baseline comparison.

## Architecture

### Core Components
1. **SharedStorage Structure**
   - Union-based memory layout for efficient shared memory reuse
   - Separate buffers for A/B during main loop and C during epilogue
   - Barrier synchronization for TMA and MMA operations
   - Shared memory layout structure inspired by CUTLASS examples

2. **Main Kernel: Gemm_TMA**
   - Template parameters for maximum flexibility
   - Static tensor slicing to achieve 100% register allocation
   - Pipelined execution:
     - Prefetch first tile
     - PING phase: Compute tile 0 while loading tile 1
     - PONG phase: Compute tile 1 while loading tile 0
     - Epilogue: Store results using TMA

3. **Tile Sizes**
   - Block tile: 128 x 64 (M x N)
   - K tile: 64 elements
   - MMA atom: 16 x 8 x 16
   - MMA blocktile：32 x 32 x 16


### Test Configuration
- **Matrix Dimensions**: M=81,920  N=512  K=256(This is applicable when Matrix K is not too large. If K is too large, the strategy needs to be changed, such as splitk, etc.)
- **GPU**: NVIDIA RTX 5070 (Blackwell SM120a)
- **CUDA Toolkit**: 13.0
- **Others Toolkit**: The cutlass library and cmake need to be installed.

### Results
The kernel achieves **comparable performance to NVIDIA cuBLAS** through:
- Efficient utilization of Tensor Memory Accelerator
- Optimal pipelining via ping-pong buffering
- Minimal register pressure with static tensor slicing

### Validation
-  Global error check against cuBLAS across full matrix
-  Local CPU reference computation (128x128 subset)
-  Detailed element-wise comparison with statistics

## Compilation
- The project uses CMake for build configuration, specifically optimized for the NVIDIA Blackwell architecture.

### Prerequisites
-  CMake: Version 3.18 or higher
-  CUTLASS: Should be located at ./cutlass (or update CUTLASS_DIR in CMakeLists.txt)
-  NVIDIA Driver: Compatible with Blackwell (SM120a)

### Using CMake (recommended)
mkdir build && cd build
cmake ..
make 

## Build Configuration Details
-  Architecture Targeting: Specifically configured for SM 120a (Blackwell) via CMAKE_CUDA_ARCHITECTURES.
-  C++17 Standard: Mandatory for CuTe and CUTLASS 3.x compatibility.
-  NVCC Optimization Flags:
    - -O3: Maximum optimization level.
    - --expt-relaxed-constexpr: Allows constexpr on GPU-targeted functions.
    - -lineinfo: Preserves line information for precise profiling in NVIDIA Nsight Compute.

### Build Configuration Details
- Automatically links CUDA::cudart and CUDA::cublas.
- Integrates CUTLASS headers and tool utilities for reference checks.



## Output
```
root@ubuntu:~/build# ./gemm_test
------------------------------------------
[1] Testing Custom TMA GEMM Kernel...
Custom time: 0.26345 ms, Performance: 81.514 TFLOPS
------------------------------------------
[2] Testing NVIDIA cuBLAS...
cuBLAS time: 0.301203 ms, Performance: 71.2968 TFLOPS
Performance compliance rate: 114.33%
------------------------------------------
[3] Verification CPU float compute(128x128)...
------------------------------------------
[4] Precision verification and Data printing
-> Global max error accurancy (Custom vs cuBLAS): 0
-> Part max error accurancy (Custom vs CPU): 0.03125

>>> Printing the initial 15 output values (Custom vs cuBLAS vs CPU):
Index   Custom          CuBLAS          CPU             Abs Error(my-cpu)
0       -9.703125       -9.703125       -9.695312       0.007812
1       -0.751953       -0.751953       -0.753906       0.001953
2       4.773438        4.773438        4.769531        0.003906
3       7.320312        7.320312        7.320312        0.000000
4       3.916016        3.916016        3.916016        0.000000
5       1.350586        1.350586        1.350586        0.000000
6       -4.359375       -4.359375       -4.359375       0.000000
7       0.985352        0.985352        0.983887        0.001465
8       5.843750        5.843750        5.847656        0.003906
9       -9.804688       -9.804688       -9.804688       0.000000
10      -2.851562       -2.851562       -2.853516       0.001953
11      0.148926        0.148926        0.148193        0.000732
12      -2.945312       -2.945312       -2.943359       0.001953
13      1.675781        1.675781        1.676758        0.000977
14      1.170898        1.170898        1.169922        0.000977
root@ubuntu:~/build#
...
```

### Performance
- When the RTX5070 is cold-started and for the matrix size of the test, this kernel can achieve 81.514 TFLOPS with a running time of 0.2634 ms. Using cublas can reach 71.2968 TFLOPS with a running time of 0.3012 ms. The performance compliance rate is 113%. The data for each run fluctuates slightly, generally within this range. When analyzed using NCU, due to the GPU frequency being at 2.29 GHz, the performance decreases and the running time is 0.309 ms with 69.3 TFLOPS.

## Known Limitations

- Supports FP16 only (FP32 and BF16 would require separate implementations)
- Optimized for Matrix K is not too large
- Requires GPU with SM 90+

## Known Issues

- On some driver versions, a cold GPU reset may be required if the kernel previously crashed during TMA descriptor initialization.

## References

- NVIDIA CUTLASS: https://github.com/NVIDIA/cutlass
- CUTE Documentation: https://github.com/NVIDIA/cutlass/tree/main/cute
- Blackwell Architecture: https://www.nvidia.com/en-us/data-center/blackwell/
- TMA Documentation: https://docs.nvidia.com/cuda/parallel-thread-execution/index.html#tensor-memory-accelerator

## License

This implementation references and builds upon CUTLASS library patterns.
CUTLASS is licensed under BSD 3-Clause.

## Contributing

Feedback and improvements are welcome. Please report issues or suggest enhancements via GitHub issues.
