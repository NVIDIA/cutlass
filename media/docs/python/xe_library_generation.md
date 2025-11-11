<!--
Copyright (C) 2025 Intel Corporation, All rights reserved.
SPDX-License-Identifier: BSD-3-Clause

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation
and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its
contributors may be used to endorse or promote products derived from
this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
-->

# Intel SYCL*TLA Library Generation Guide

**Complete Reference for Intel Xe GPU Architecture Support**

---

## Quick Start

```bash
# Configure for BMG (Xe2)
cd build
cmake .. -GNinja -DCUTLASS_NVCC_ARCHS="" -DCUTLASS_ENABLE_SYCL=ON -DSYCL_INTEL_TARGET -DCUTLASS_LIBRARY_GENERATOR_ARCHS="20"

# Build libraries
ninja cutlass_library

---

## Architecture Support

| GPU | Arch | Compute Cap | File Ext | Arch Tag |
|-----|------|-------------|----------|----------|
| **BMG** (Xe2) | 20 | 12-50 | `.cpp` | `cutlass::arch::Xe20` |
| **PVC** (Xe-HPC) | 12 | 12-50 | `.cpp` | `cutlass::arch::Xe12` |

**Key Differences from CUDA:**
- Architecture prefix: `xe` (not `sm`)
- File extension: `.cpp` (not `.cu`)
- Compute capability: 12-50 (vs 50-120 for CUDA)

---

## Supported Kernel Types

### ✅ Homogeneous Types (A == B)

| Type | A × B → C/D | Math Inst | Tile | Align | Status |
|------|-------------|-----------|------|-------|--------|
| **FP16** | half × half → float | [8,16,16] | 256×256×32 | 8 | ✅ |
| **BF16** | bf16 × bf16 → float | [8,16,16] | 256×256×32 | 8 | ✅ |
| **FP8-E4M3** | e4m3 × e4m3 → float | [8,16,32] | 256×256×64 | 16 | ✅ |
| **FP8-E5M2** | e5m2 × e5m2 → float | [8,16,32] | 256×256×64 | 16 | ✅ |
| **INT8** | int8 × int8 → int32 | [8,16,32] | 256×256×64 | 16 | ✅ |

**Layout Combinations:** RR, RC, CR, CC (4 variants per type)

### ❌ Mixed Precision (A ≠ B)

Mixed precision infrastructure is not supported now:
- FP16 × E4M3/E5M2 → FP32
- BF16 × E4M3/E5M2 → FP32  
- FP16 × INT4 → FP32

---

## Generated Libraries

```bash
$ ls -lh build/tools/library/libcutlass*.so
-rwxrwxr-x 186K libcutlass_gemm_xe20_gemm_bf16.so    # BF16 kernels
-rwxrwxr-x 186K libcutlass_gemm_xe20_gemm_e4m3.so    # FP8 E4M3 
-rwxrwxr-x 186K libcutlass_gemm_xe20_gemm_e5m2.so    # FP8 E5M2
-rwxrwxr-x 186K libcutlass_gemm_xe20_gemm_f16.so     # FP16 kernels
-rwxrwxr-x 186K libcutlass_gemm_xe20_gemm_s8.so      # INT8 kernels
-rwxrwxr-x 186K libcutlass_gemm_xe20_gemm.so         # Generic
-rwxrwxr-x  19K libcutlass.so                        # Base library
```

### Kernel Naming Convention

```
cutlass3x_xe{arch}_{opclass}_{operation}_{dtype}_{tile}_{warp}_{layout}_align{N}
```

**Examples:**
```cpp
cutlass3x_xe20_tensorop_gemm_f16_256x256_32x0_nn_align8    // FP16, Row×Row
cutlass3x_xe20_tensorop_gemm_bf16_256x256_32x0_nt_align8   // BF16, Row×Column
cutlass3x_xe20_tensorop_gemm_e4m3_256x256_64x0_tn_align16  // E4M3, Column×Row
```

**Layout Codes:** `nn`=Row×Row, `nt`=Row×Column, `tn`=Column×Row, `tt`=Column×Column

---

## Build & Usage

### CMake Configuration

```bash
# BMG (Xe2)
cmake .. -GNinja -DCUTLASS_ENABLE_SYCL=ON -DCUTLASS_LIBRARY_GENERATOR_ARCHS="20"

# PVC (Xe-HPC)  
cmake .. -GNinja -DCUTLASS_ENABLE_SYCL=ON -DCUTLASS_LIBRARY_GENERATOR_ARCHS="12"
```

### Build Targets

```bash
ninja cutlass_library                              # All libraries
ninja cutlass_library_gemm_xe20_gemm_bf16         # BF16 only
ninja cutlass_library_gemm_xe20_gemm_f16          # FP16 only
```

### Python Generator (Direct)

```bash
cd build
python3 ../python/cutlass_library/generator.py --operations=gemm --architectures=20 --build-dir=.
```

### Python Integration Example

For Python integration via ctypes, see:
- **`examples/11_xe20_cutlass_library/`** - Complete CMake-based shared library example
- **`examples/python/cutlass_library/xe20_gemm_bf16.py`** - Python test script using ctypes

**Build and test:**
```bash
# Build the shared library
ninja xe20_cutlass_library_bf16

# Test with Python
cd examples/python/cutlass_library
python3 xe20_gemm_bf16.py
```

## Troubleshooting

### No Operations Generated
**Check:** `GenerateIntelXe()` called for arch in [12, 20] in `generator.py`

### Library Link Errors
```
undefined reference to `initialize_all_xe20_gemm_bf16_gemm_operations()`
```
**Solution:** Build and link the specific library: `-lcutlass_gemm_xe20_gemm_bf16`

## Summary

### ✅ What Works
- **5 data type libraries** (FP16, BF16, E4M3, E5M2, INT8)
- **~24 operations, 31 .cpp files** generated
- **Homogeneous type kernels** compile cleanly
- **INT32 accumulator** for INT8
- **FP8→FP16 conversion** in MMA

### ❌ Limitations  
- **Mixed precision** requires grouped GEMM
- **Regular library** only supports ElementA == ElementB
- **No INT4** in regular GEMM

### 📊 Quick Reference
| Feature | Value |
|---------|-------|
| Arch Numbers | BMG=20, PVC=12 |
| File Ext | `.cpp` |
| Arch Prefix | `xe` |
| CC Range | 12-50 |
| Total Libraries | 7 |
| Total Kernels | ~24 |
| Supported Types | FP16, BF16, E4M3, E5M2, INT8 |

## Examples and References

### Practical Examples
- **`examples/11_xe20_cutlass_library/`** - CMake-based shared library for Python integration
  - Exports `sycl_tla_gemm_xe20_bf16()` function via extern "C"
  - Builds `libxe20_cutlass_library_bf16.so` with proper CMake integration
  - Integrated into main examples build system (`ninja cutlass_examples`)

- **`examples/python/cutlass_library/xe20_gemm_bf16.py`** - Python ctypes integration
  - Complete test script using the shared library
  - Demonstrates workspace querying, execution, and benchmarking
  - Shows proper error handling and performance measurement

### Build Integration
```bash
# Build the example library
ninja xe20_cutlass_library_bf16

# Run Python test
cd examples/python/cutlass_library
python3 xe20_gemm_bf16.py
```

---
