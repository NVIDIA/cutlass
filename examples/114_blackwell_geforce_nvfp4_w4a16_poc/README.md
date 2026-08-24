# SM120/SM121 NVFP4 W4A16 GEMM

This example exercises the reusable CUTLASS mixed-input GEMM for Blackwell
GeForce GPUs:

```text
A: FP16 activations, row major
B: packed E2M1 values with one UE4M3 scale per 16 K elements
D: FP32, row major
Operation: D = A * B
```

The implementation is split along standard CUTLASS ownership boundaries:

- `cutlass::layout::Nvfp4W4a16Weight` defines the packed value and scale
  storage contract.
- `cutlass::gemm::collective::Sm120CpAsyncNvfp4W4a16` owns asynchronous tile
  movement, register conversion, scaling, and the MMA mainloop.
- A schedule-specific `cutlass::gemm::kernel::GemmUniversal` specialization
  owns grid mapping and composes the mainloop with a standard CUTLASS epilogue.
- `cutlass::gemm::device::Sm120Nvfp4W4a16Gemm` is a normal
  `GemmUniversalAdapter` alias and therefore exposes the standard CUTLASS 3.x
  `can_implement`, `initialize`, `run`, and `operator()` interface.

## Mainloop

The four-warp mainloop uses `64 x 128 x 64` and `16 x 128 x 64` CTA variants.
It double-buffers FP16 A, packed FP4 B, and block scales in shared memory. While
one K tile is decoded and consumed, `cp.async` transfers the following tile into
the alternate stage. E2M1 values and UE4M3 scales are converted to FP16 register
fragments immediately before FP16 Tensor Core MMA with FP32 accumulation.

No full FP16 weight matrix is written to global or shared memory, and no
separate dequantization kernel is required.

## Weight layout

Values are stored as two consecutive K elements per byte, with one contiguous
`K / 2` byte row per output column. Scales are interleaved in four-column groups:

```text
scale_offset = ((column / 4) * (K / 16) + scale_block) * 4 + column % 4
```

The group-of-four layout makes the four block-16 scale rows required by a K=64
tile one aligned 16-byte transaction.

## Constraints

- `M` is 16 or a multiple of 64. Callers may pad M and copy the valid rows.
- `N` is a multiple of 128.
- `K` is a multiple of 64.
- A, packed B, scales, and D are 16-byte aligned.
- The kernel targets SM120 and SM121.

`114_sm120_nvfp4_w4a16_poc` remains as the original scalar reference.
`114b_sm120_nvfp4_w4a16_cute_pipeline` uses the reusable device API and checks
its output against a host reference before reporting performance.

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

The reusable device example requires the constraints listed above.
`--no-verify` skips the cubic CPU reference for large performance experiments;
the kernel launch and CUDA runtime errors are still checked.

## Tests

The registered device test covers the layout bijection, invalid API contracts,
both CTA shapes, all E2M1 bit patterns, multiple N tiles, and representative
llama.cpp dimensions (`K=5120` and `K=17408`):

```console
cmake -S . -B build -DCUTLASS_NVCC_ARCHS=120a -DCUTLASS_ENABLE_TESTS=ON
cmake --build build --target cutlass_test_unit_gemm_device_sm120_nvfp4_w4a16 --config Release
build/test/unit/gemm/device/sm120_nvfp4_w4a16_gemm/cutlass_test_unit_gemm_device_sm120_nvfp4_w4a16
```
