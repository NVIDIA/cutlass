# SM120/SM121 NVFP4 W4A16 GEMM proof of concept

This example is the correctness-first phase of a weight-only NVFP4 GEMM for
Blackwell GeForce GPUs:

```text
A: FP16, row major
B: packed E2M1 FP4, column major, one UE4M3 scale per 16 K values
C: FP32, row major
Operation: C = A * B
```

The prototype keeps the missing W4A16 path self-contained in `examples/`.
It does not change the production CUTLASS collective builders or existing
NVFP4 W4A4 kernels.

## What this phase proves

For each 16-element K step, one warp:

1. Loads an FP16 activation tile.
2. Loads packed E2M1 weight pairs and their UE4M3 block-16 scales.
3. Uses CUTLASS numeric converters to expand only the current weight tile to
   FP16 in shared memory.
4. Executes FP16 Tensor Core MMA with FP32 accumulation.
5. Repeats across K and stores an FP32 output tile.

There is no global FP16 weight workspace and no separate dequantization
kernel. The executable creates a CPU reference from the same packed weights
and fails when the GPU result is outside tolerance.

This is not yet a production CUTLASS collective. The phase-1 kernel uses a
single-warp CUDA WMMA microkernel so that the data contract, FP4 conversion,
scale mapping, and numerical behavior can be validated independently. The
next phase is to express the same loop with CuTe copy/MMA atoms, add a
multistage asynchronous pipeline, and tune larger CTA tiles.

## Build

Configure CUTLASS for the target architecture, then build the example target:

```console
cmake -S . -B build -DCUTLASS_NVCC_ARCHS=120a -DCUTLASS_ENABLE_EXAMPLES=ON -DCUTLASS_ENABLE_TOOLS=ON -DCUTLASS_ENABLE_LIBRARY=OFF -DCUTLASS_ENABLE_PROFILER=OFF -DCUTLASS_ENABLE_TESTS=OFF
cmake --build build --target 114_sm120_nvfp4_w4a16_poc --config Release
```

For an SM121 target, replace `120a` with `121a`.

## Run

```console
114_sm120_nvfp4_w4a16_poc.exe
114_sm120_nvfp4_w4a16_poc.exe --m=128 --n=128 --k=512
```

`M`, `N`, and `K` must be multiples of 16 in this phase.
