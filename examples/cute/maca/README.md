# CuTe MACA Examples

This directory contains MACA-specific CuTe examples.

## SGEMM NT

`sgemm_1.maca` is a runnable correctness check derived from the CuTe
SGEMM NT tutorial shape. It uses MACA `mc*` runtime APIs, deterministic host
inputs, CPU reference GEMM, device launch, device-to-host copy, and max-error
reporting.

Direct MXMACA build and run:

```bash
/opt/maca-3.5.3/mxgpu_llvm/bin/mxcc -x maca -std=c++17 -O3 \
  --maca-path=/opt/maca-3.5.3 \
  -I/path/to/cutex/include \
  -I/opt/maca-3.5.3/include \
  -I/opt/maca-3.5.3/tools/cu-bridge/include \
  -I/opt/maca-3.5.3/tools/cu-bridge/include/cuda \
  examples/cute/maca/sgemm_1.maca \
  -o cute_maca_sgemm_1

./cute_maca_sgemm_1
./cute_maca_sgemm_1 256 256 16 N T 100
./cute_maca_sgemm_1 512 512 1024 N T 5000 0
```

The last argument controls the CPU reference check. Use `1` or omit it for
correctness, and use `0` for GPU timing runs that should avoid the CPU reference
GEMM.

The output follows the CUDA tutorial benchmark line and also keeps the MACA
correctness check:

```text
M = 128
N = 128
K = 8
C = A^N B^T
alpha=1.25 beta=0.5
result_check=enabled
Computing CPU reference...
max_abs_error=0 max_rel_error=0 at C(0,0): got=1.66992 ref=1.66992
CUTE_GEMM:     [   ...]GFlop/s  (...ms)
PASS
```

CMake:

```bash
cmake -S examples/cute/maca -B build-cute-maca \
  -DCMAKE_CXX_COMPILER=/opt/maca-3.5.3/mxgpu_llvm/bin/mxcc \
  -DCUTE_MACA_ROOT=/opt/maca-3.5.3
cmake --build build-cute-maca --target cute_maca_sgemm_1 -v
```
