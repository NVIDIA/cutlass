# CuTe IR — Cutlass Compiler Stack

Cute IR is an MLIR dialect for CuTe layout algebra and NVIDIA GPU kernel programming.
It is intended to be used with MLIR DL/AI compiler stacks.

## Current Dialect Stack

| Dialect | Mnemonic | Purpose |
|---------|----------|---------|
| `Cute` | `cute` | CuTe layout algebra — types, constructors, accessors, layout algebra, size/index, arithmetic, tiling/partitioning |
| `Base` (pseudo-dialect) | n/a | Lowering target boundary — `arith`, `scf`, `cf`, `ub`, `func`, `math`, `gpu`, `LLVM`, `NVVM` |

`Base` is a **pseudo-dialect** — not a dialect of its own, but a well-defined target boundary made of upstream MLIR dialects. The cute layer lowers into this boundary via `cute-to-base`, after which only upstream / LLVM lowering remains.

## Documentation

Start at [`index.rst`][docs-index] — the documentation entry
point. It links the guided *Learning CuTe with CuTe IR* chapters and
the per-dialect references
([`cute_dialect.rst`][docs-cute-dialect],
[`base_dialect.rst`][docs-base-dialect]).


[docs-index]: ../media/docs/cutlass_compiler/index.rst
[docs-cute-dialect]: ../media/docs/cutlass_compiler/cute_dialect.rst
[docs-base-dialect]: ../media/docs/cutlass_compiler/base_dialect.rst



## Tools

The project ships **three** MLIR optimizer drivers, deliberately scoped for testing isolation. They differ only in what dialects/passes they register; the underlying source files all flow into per-layer registration libraries (`MLIRCuteRegistration`, `MLIRBaseRegistration`).

| Tool | Path | Dialects | Passes | When to use |
|------|------|----------|--------|-------------|
| `cute-opt` | `cute_ir/tools/cute-opt/cute-opt` | cute + arith / scf / ub / LLVM / gpu / math / func | `cute-fold-static`, `cute-expand-ops`, `cute-to-base` + upstream cleanups (`canonicalize`, `cse`, `loop-invariant-code-motion`, `reconcile-unrealized-casts`) | Cute-layer LIT tests; manual cute pipeline runs |
| `base-opt` | `base/tools/base-opt/base-opt` | base only — `arith / cf / func / gpu / LLVM / math / NVVM / scf / ub` (**no cute**) | `base-prepare`, `one-shot-convert-to-llvm`, `attach-nvvm-target`, `emit-gpu-binary` + upstream cleanups | Base-layer LIT tests; runs that should fail loudly on cute leakage |
| `cutlass-compiler` | `tools/cutlass-compiler/cutlass-compiler` | everything (cute + base) | every pass either tool registers, plus the standard MLIR transforms | End-to-end pipelines, integration tests, debugging cross-layer IR |

`base-opt`'s strict isolation means a test file that accidentally references `!cute.layout<...>` errors at parse time with `unregistered dialect 'cute'`. This is a deliberate guardrail.

`cutlass-compiler` is the canonical user-facing tool — it can run the whole `cute → base → llvm` pipeline in a single invocation.

## Directory Structure

```text
cutlass_compiler/
├── CMakeLists.txt              # Top-level CMake (aggregates base, cute_ir, tools, test)
├── LICENSE.txt                  # BSD-3-Clause release license
├── LLVM_COMMIT                  # Exact public llvm-project revision
├── cmake/                      # Shared CMake helpers (Standalone, LLVM)
├── cute_ir/                    # Cute dialect
│   ├── cmake/                  # Cute-specific CMake helpers
│   ├── include/cute_ir/        # ODS (.td) + public headers
│   ├── lib/                    # Conversion, Dialect, Registration
│   ├── tools/cute-opt/         # cute-only opt driver
│   └── test/                   # Dialect/, Conversion/, Transforms/, unittests/
├── base/                       # Lowering target boundary (pseudo-dialect)
│   ├── cmake/                  # Base-specific CMake helpers
│   ├── include/base/           # ODS (.td) + public headers
│   ├── lib/                    # Conversion/BaseToTargets, Registration
│   ├── tools/base-opt/         # base-only opt driver (no cute registered)
│   └── test/                   # Conversion/{BasePrepare,OneShotConvertToLLVM,NVVMLowering}/
├── cutegen/                    # Vendored cutegen C++ layout library (headers + tests)
├── tools/
│   ├── cutlass-compiler/       # Comprehensive opt driver (cute + base + upstream)
│   ├── cutlass-lsp-server/     # MLIR language server with cute + base registered
├── test/
│   ├── Integration/
│   │   ├── host/cpu/           # Host JIT end-to-end tests (mlir-runner)
│   │   └── nvgpu/sm50/         # NVIDIA GPU end-to-end tests (mlir-runner + CUDA)
│   ├── PipelineLit/            # Cross-layer structural pipeline LIT tests
├── scripts/
│   ├── run_integration_host.sh                 # Host JIT wrapper for `%cutlass-compiler-run-host`
│   ├── run_integration_device.sh               # Device pipeline wrapper
├── docs/                       # User + developer documentation
└── README.md                   # (this file)
```

## Build

### Standalone with public LLVM

cutlass_compiler builds against bundled LLVM/MLIR commit.

```bash
# Fetch the exact LLVM revision recorded in the release payload. This
# works from either a Git checkout or an extracted tarball.
llvm_commit=$(tr -d '[:space:]' < cutlass_compiler/LLVM_COMMIT)
git init cutlass_compiler/external/llvm-project
git -C cutlass_compiler/external/llvm-project remote add origin \
  https://github.com/llvm/llvm-project.git
git -C cutlass_compiler/external/llvm-project fetch --depth=1 origin "$llvm_commit"
git -C cutlass_compiler/external/llvm-project checkout --detach FETCH_HEAD

# Configure cutlass_compiler as a standalone project. This builds
# LLVM/MLIR from the pinned checkout in the same build tree.
cmake -S cutlass_compiler -B build-cutlass-compiler -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
  -DCUTLASS_COMPILER_USE_BUNDLED_LLVM=ON

# Build the three opt drivers.
ninja -C build-cutlass-compiler cute-opt base-opt cutlass-compiler
```

To reuse an existing LLVM/MLIR build instead of the bundled checkout, point
CMake at the LLVM build or install tree:

```bash
cmake -S cutlass_compiler -B build-cutlass-compiler -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
  -DLLVM_DIR=/path/to/llvm-build/lib/cmake/llvm \
  -DMLIR_DIR=/path/to/llvm-build/lib/cmake/mlir

ninja -C build-cutlass-compiler cute-opt base-opt cutlass-compiler
```

If you plan to run the base NVVM lowering tests, build LLVM with the `NVPTX`
target as well as `Native`. The bundled path above defaults to
`Native;NVPTX`. Enable `CUTLASS_COMPILER_BUNDLED_LLVM_ENABLE_CUDA_RUNNER=ON` only
when you need MLIR's CUDA runner runtime.

Standalone `check-cute-unittests` uses LLVM-vendored googletest from LLVM's
`third-party/unittest` source. If you reuse an existing LLVM/MLIR build instead
of `CUTLASS_COMPILER_USE_BUNDLED_LLVM=ON`, keep the pinned public LLVM checkout available or set
`CUTLASS_COMPILER_GTEST_SOURCE_DIR` to an LLVM `third-party/unittest` checkout.
Use a C++ toolchain that is ABI-compatible with the LLVM build tree.

Standalone mode prefers the embedded `cutegen/` source shipped in the release,
then falls back to a sibling `../cutegen` checkout.

## Testing

### Test suites

| Target | What runs | Source |
|--------|-----------|--------|
| `check-cute` | All cute LIT tests (dialect tests, conversion tests, `cute-opt` regression suite) | `cute_ir/test/` |
| `check-cute-unittests` | C++ gtest unit tests for cute types/attrs | `cute_ir/test/unittests/` |
| `check-base` | All base LIT tests (`BasePrepare`, `OneShotConvertToLLVM`) using `base-opt` | `base/test/` |
| `check-cutlass-integration` | End-to-end integration tests. `host/cpu/` JIT-executes lowered IR via `mlir-runner` (host script: `scripts/run_integration_host.sh`). `nvgpu/sm50/` launches the lowered kernel on GPU silicon (device script: `scripts/run_integration_device.sh`) — gated on the `cutlass_compiler_device` lit feature; tests carry `REQUIRES: cutlass_compiler_device` and skip when no GPU is visible. | `test/Integration/{host,nvgpu}/` |
| `check-cutlass-pipelinelit` | Cross-layer structural pipeline LIT tests — runs the full cutlass_compiler pipeline (cute → base → LLVM → NVVM target / binary) via `cutlass-compiler` and asserts on the IR shape. Distinct from `check-cutlass-integration`, which JIT-executes via `mlir-runner`. | `test/PipelineLit/` |
| `check-cutlass-all` | Aggregate target — depends on every suite above (`check-base`, `check-cute`, `check-cute-unittests`, `check-cutlass-integration`, `check-cutlass-pipelinelit`). | n/a |
### Running the suites

```bash
BUILD_DIR=build-cutlass-compiler

# Layer-scoped suites
ninja -C "$BUILD_DIR" check-cute
ninja -C "$BUILD_DIR" check-cute-unittests
ninja -C "$BUILD_DIR" check-base

# End-to-end (cute kernel → JIT-executed printf output)
ninja -C "$BUILD_DIR" check-cutlass-integration

# Cross-layer structural pipeline (cute → base → LLVM → NVVM)
ninja -C "$BUILD_DIR" check-cutlass-pipelinelit

# Everything in one shot
ninja -C "$BUILD_DIR" check-cutlass-all
```

### Running individual LIT files

Always pass the **build-tree** path (not the source path). The commands below
use the bundled LLVM layout; when reusing an external LLVM build, invoke its
`llvm-lit` binary instead:

```bash
BUILD_DIR=build-cutlass-compiler

# Single test file
"$BUILD_DIR/llvm-project/bin/llvm-lit" -sv \
  --filter='Dialect/Cute/Types/layout.mlir' "$BUILD_DIR/cute_ir/test"

# Subdirectory
"$BUILD_DIR/llvm-project/bin/llvm-lit" -sv \
  --filter='Conversion/OneShotConvertToLLVM/' "$BUILD_DIR/base/test"
```

### Inspecting IR

```bash
BUILD_DIR=build-cutlass-compiler

# Parse and re-print a file (checks parse/print round-trip)
"$BUILD_DIR/cute_ir/tools/cute-opt/cute-opt" path/to/test.mlir

# Print in generic form (useful for debugging attribute storage)
"$BUILD_DIR/cute_ir/tools/cute-opt/cute-opt" \
  -mlir-print-op-generic path/to/test.mlir

# Pipe a one-liner directly
echo 'module { func.func @t(%a: !cute.layout<"(2,3):(1,2)">) { return } }' \
  | "$BUILD_DIR/cute_ir/tools/cute-opt/cute-opt" -

# Run the full host pipeline + JIT-execute
"$BUILD_DIR/tools/cutlass-compiler/cutlass-compiler" \
    -cute-fold-static -cute-expand-ops -cute-to-base \
    -base-prepare -one-shot-convert-to-llvm \
    path/to/test.mlir \
  | "$BUILD_DIR/llvm-project/bin/mlir-runner" \
      -e main -entry-point-result=void
```
