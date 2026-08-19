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
scale mapping, and numerical behavior can be validated independently.

## Phase 2 prototype

`114b_sm120_nvfp4_w4a16_cute_pipeline` implements the pipelined phase without
replacing the phase-1 reference. It adds:

1. A four-warp `64 x 32 x 64` CuTe tiled MMA with FP32 accumulation, tuned for
   large prefill shapes.
2. Two shared-memory stages for A, packed B, block scales, and expanded B.
3. `cp.async` loads for FP16 A tiles, packed E2M1 B tiles, and UE4M3 scale tiles.
4. CUTLASS's K-major XOR-swizzled shared layouts and explicit LDSM copy atoms.
5. Tile-local E2M1-to-FP16 conversion with four independent block-16 scale rows
   per K tile while the following global-memory stage remains in flight.
6. Correctness checking plus a kernel-only timing loop.

For coalesced asynchronous scale loads, Phase 2 expects scales repacked as
`[K/16, N]`; this is a runtime kernel layout rather than the source GGUF layout.
It still does not allocate a full FP16 B matrix. The expanded FP16 values exist
only for the current two shared-memory stages.

SASS inspection on SM120 confirms `LDGSTS`, `LDSM`, E2M1 and UE4M3 conversion,
and FP16 `HMMA` instructions. The selected kernel uses 39 registers per thread
and 27,904 bytes of static shared memory. A possible next optimization is a
warp-specialized load/decode/compute schedule that reduces synchronization and
the shared-memory occupancy limit.

## RTX 5090 Phase 2 checkpoint

Local measurements with CUDA 13.1 on an RTX 5090, using
`M=8192, N=4096, K=4096` and kernel-only CUDA event timing:

| Phase 2 CTA tile | Kernel time | Dense-equivalent throughput |
| --- | ---: | ---: |
| Initial `32 x 16 x 16` | about 7.12 ms | about 38.6 TFLOP/s |
| Tuned `64 x 32 x 64` | 2.11-2.15 ms | 128-131 TFLOP/s |

Nsight Compute measured approximately 65% SM throughput, 67% memory/L2
throughput, and 24.75% achieved occupancy on the 8K shape. Shared memory limits
the theoretical occupancy to 25%. These numbers validate the proof-of-concept
direction; they are not yet a production claim or a comparison against a tuned
Marlin or cuBLAS baseline. The larger tile is intentionally prefill-oriented and
can be slower on small matrices with too few CTAs to fill the GPU.

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

The phase-1 executable requires `M`, `N`, and `K` to be multiples of 16.

The Phase 2 executable requires `M` and `K` to be multiples of 64 and `N` to be
a multiple of 32.
`--no-verify` skips the cubic CPU reference for large performance experiments;
the kernel launch and CUDA runtime errors are still checked.
