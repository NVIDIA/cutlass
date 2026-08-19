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

## Phase 2 prototype

`114b_sm120_nvfp4_w4a16_cute_pipeline` starts that next phase without replacing
the phase-1 reference. It adds:

1. A four-warp `32 x 16 x 16` CuTe tiled MMA with FP32 accumulation.
2. Two shared-memory stages for A, packed B, block scales, and expanded B.
3. `cp.async` loads for FP16 A tiles, packed E2M1 B tiles, and UE4M3 scale tiles.
4. Tile-local E2M1-to-FP16 conversion and scale application while the following
   global-memory stage remains in flight.
5. Correctness checking plus a kernel-only timing loop.

For coalesced asynchronous scale loads, Phase 2 expects scales repacked as
`[K/16, N]`; this is a runtime kernel layout rather than the source GGUF layout.
It still does not allocate a full FP16 B matrix.

The next optimization steps are swizzled shared-memory layouts, explicit
LDSM copy atoms, a larger CTA tile, and warp-specialized load/decode/compute.

## Build

Configure CUTLASS for the target architecture, then build the example target:

```console
cmake -S . -B build -DCUTLASS_NVCC_ARCHS=120a -DCUTLASS_ENABLE_EXAMPLES=ON -DCUTLASS_ENABLE_TOOLS=ON -DCUTLASS_ENABLE_LIBRARY=OFF -DCUTLASS_ENABLE_PROFILER=OFF -DCUTLASS_ENABLE_TESTS=OFF
cmake --build build --target 114_sm120_nvfp4_w4a16_poc --config Release
cmake --build build --target 114b_sm120_nvfp4_w4a16_cute_pipeline --config Release
```

For an SM121 target, replace `120a` with `121a`.

## Run

```console
114_sm120_nvfp4_w4a16_poc.exe
114_sm120_nvfp4_w4a16_poc.exe --m=128 --n=128 --k=512
114b_sm120_nvfp4_w4a16_cute_pipeline.exe --m=128 --n=128 --k=512 --iterations=100
114b_sm120_nvfp4_w4a16_cute_pipeline.exe --m=8192 --n=4096 --k=4096 --iterations=20 --no-verify
```

`M`, `N`, and `K` must be multiples of 16 in this phase.

The Phase 2 executable additionally requires `M` to be a multiple of 32.
`--no-verify` skips the cubic CPU reference for large performance experiments;
the kernel launch and CUDA runtime errors are still checked.
