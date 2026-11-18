# CUTLASS Operator API Profiler

The CUTLASS Operator API Profiler is a command-line driven benchmarking and verification tool for
operators exposed through the CUTLASS Operator API. Profilers are organized by
their top-level RuntimeArguments contract: GemmArguments covers dense and
block-scaled GEMM, while IndexPtrGroupedGemmArguments covers grouped GEMM.

Installing the `nvidia-cutlass-operators` wheel puts a `cutlass_profiler`
executable in the active Python environment. For a fresh virtualenv:

```bash
python -m venv .venv
source .venv/bin/activate
pip install 'nvidia-cutlass-operators[torch]'
cutlass_profiler run --operation gemm --M 1024 --N 1024 --K 512
```

PyTorch is what the profiler allocates operands and computes references with,
so install the `[torch]` extra; the core `nvidia-cutlass-operators` wheel leaves
it optional.

Every command below also runs as `python -m cutlass.profiler ...`, which is the
same entry point and is useful for pinning a specific interpreter:

```bash
python -m cutlass.profiler run --operation gemm --M 1024 --N 1024 --K 512
```

Running benchmarks requires a CUDA-capable NVIDIA GPU. The metadata-only
`inspect` mode and configuration-only `dry-run` mode do not execute kernels.

## Profiler Usage

Use `cutlass_profiler --help` for mode help and an operation-specific
command for complete runtime options, for example:

```bash
cutlass_profiler run --operation gemm --help
cutlass_profiler run --operation grouped_gemm --help
cutlass_profiler inspect --operation all --help
```

```text
CUTLASS Operator API Profiler - Benchmark CUTLASS operators

  {run,dry-run,compile,inspect}    Profiler mode.
    run                            Run end-to-end kernel profiling.
    dry-run                        Validate and print configuration without executing.
    compile                        Reserved for compile-only profiling.(not yet supported)
    inspect                        Query and print kernel metadata for inspection.

  --operation {gemm,grouped_gemm}      Operation type to profile. Inspect also accepts
                                       `all` to query every operation.

Operator Selection:
  --provider {cutedsl,...}           Operator provider. If not specified, queries all providers.

  --op_class <regex>                 Filter by OperatorMetadata.operator_class class name.
                                     The regular expression is combined with name and metadata
                                     filters.

  --operators <pattern>              Filter operators by name (fnmatch wildcards).
                                     --operators 'cutedsl.Sm100*'
                                     --operators 'cutedsl.Sm100DenseGemmUniversalOperator*'

  --target-sm <string>               Operator target, such as 100a or sm_100a.
                                     If not provided, derive target from environment.

  --heuristic <name>                 Optional Operator API heuristic that reorders
                                     matching operators best-first before profiling
                                     (e.g. --heuristic nvmatmul). Default: unset
                                     (discovery order). Combine with --limit to
                                     profile only the first N ranked operators.
                                     Requires the heuristic's optional deps when set
                                     (e.g. nvidia-matmul-heuristics>=0.1.0.27 for nvmatmul).

  --limit <int>                      Profile only the first N matching operators
                                     via get_operators(limit=N). Default: profile
                                     all matches. Without --heuristic, N is taken
                                     from discovery order.

Profiling:
  --measure-performance            Enable warmups, repeated timed iterations, and L2 cache
                                   rotation. Without this flag, run one timed iteration with
                                   no warmup or L2 rotation.

  --warmup-iterations <int>        Number of warmup iterations (default: 0, or 10 with
                                   --measure-performance).

  --profiling-iterations <int>     Number of timed iterations (default: 1, or 100 with
                                   --measure-performance).

  --workspace-count <int|auto>     Number of distinct workspaces for L2 cache rotation.
                                   Defaults to 1, or 'auto' with --measure-performance.

  --use-graphs                     Launch via CUDA graphs. Requires warmups; use
                                   --measure-performance.

  --timing-method <string>         Timing backend (default: cuda_events). Only cuda_events
                                   is currently supported.

Initialization:
  --initialization <spec>          Data distribution for input tensors (default: auto)
                                     --initialization auto
                                     --initialization uniform:min,max
                                     --initialization normal:mean,std
                                     --initialization randint:min,max
                                     --initialization constant:value
  --seed <int>                     Operand seed, reset for each problem and workspace. Used to enforce deterministic
                                   initialization.

Verification:
  --verification-mode <string>     Correctness verification against the PyTorch reference
                                   {none, cpu, cuda, auto*}. `none` skips verification,
                                   `cpu` and `cuda` pick the device the reference runs on,
                                   and `auto` verifies on the device cutlass_profiler selects.

  --atol <float>                   Absolute tolerance for verification.
                                   Default: derived per problem (see Verification tolerances).

  --rtol <float>                   Relative tolerance for verification.
                                   Default: derived per problem (see Verification tolerances).

Output:
  --output-format {yaml,json,csv}  Format for standard output and --output-file
                                   (default: yaml).

  --output-file <path>             Write the formatted results to the exact path.

  --append                         Merge results into --output-file while preserving
                                   valid YAML, JSON, or CSV; requires --output-file.

  --verbose / --no-verbose         Enable or suppress dry-run configuration output.

  --sort-results-flops-per-sec     Sort results by GFLOP/s.

  --sort-results-flops-per-byte    Sort results by arithmetic intensity. The two
                                   sort options are mutually exclusive.

Nsight Systems:
  --nsys                           Re-execute the profiler under nsys.

  --nsys-args <string>             Additional arguments forwarded to nsys; requires --nsys
                                   (e.g., "--trace cuda,nvtx --sample cpu").
```

## Verification tolerances

Initialization and verification tolerance are set together, because the
tolerance that is meaningful depends on the data the kernel is given.

The default `--initialization auto` draws low-variance integers whose range is
derived from the operand and output dtypes: `{-2, -1, 0, 1, 2}` in general,
halved to `{-1, -0.5, 0, 0.5, 1}` when either the operand or the output is 8
bits or narrower, and `{-1, 0, 1}` for narrow integers. Every value is a small
power of two, so products and their sums stay exactly representable and the
kernel's accumulation order cannot change the result.

Against that data, `--atol` and `--rtol` default to values derived per problem
from the accumulator dtype and K:

| Accumulator | K | atol | rtol |
|---|---|---|---|
| integer | any | 0.0 | 0.0 |
| float | < 512 | 0.0 | 0.0 |
| float | >= 512 | 0.0 | `0.001 * (ulp / fp16_ulp) * (K / 512) ** 1.5` |

Below K = 512 the comparison is exact. Above it, accumulated rounding error
grows with the number of terms summed and with the accumulator's ULP, so rtol
grows with both. `atol` stays `0.0`: the error being modelled is proportional
to the magnitude being accumulated. Grouped GEMM uses the largest per-group K,
so the tolerance covers the group that accumulates the most terms.

Any other `--initialization` is higher variance, so the kernel and the
reference can legitimately disagree in the last bits and the derived
tolerances will be too tight. Pass `--atol`/`--rtol` explicitly with them:

```bash
cutlass_profiler run --operation gemm --M 1024 --N 1024 --K 512 \
    --initialization uniform:-1,1 --atol 1e-1 --rtol 1e-2
```

# GEMM

The profiler benchmarks GEMM operators: `out = A @ B`.

## GEMM Arguments

The complete set of GEMM-specific arguments appears as follows.

```text
  --M <int|list|range>                M dimension (required).
  --N <int|list|range>                N dimension (required).
  --K <int|list|range>                K dimension (required).
  --L <int|list|range>                L dimension / batch count for batched GEMM (default: 1).
  --A-dtype <dtype|list>              A matrix dtype (default: f16).
  --B-dtype <dtype|list>              B matrix dtype (default: f16).
  --out-dtype <dtype|list>            out matrix dtype (default: f16).
  --accum-dtype <dtype|list>          Accumulator dtype (default: f32).
  --AB-scale-dtype <dtype|list>       Shared A/B scale factor dtype. (optional)
  --AB-scale-mode <shape|list>        Shared A/B scale block shape {1x16, 1x32}. (optional)
  --AB-scale-swizzle <swizzle>        Shared A/B scale swizzle {none, 32x4x4}. (default when scaling: 32x4x4)
```

Supported input data types: `f16`, `bf16`, `f32`, `e4m3`, `e5m2`, `e2m1`, `i8`, `i32`.
Supported scale factor data types: `ue4m3`, `ue8m0`. `--AB-scale-dtype` and
`--AB-scale-mode` must be provided together. The optional `--AB-scale-swizzle`
defaults to `32x4x4`. The profiler applies the same dtype, mode, and swizzle to
both operands. `--AB-scale-swizzle` is scalar; all dtype, scale dtype, scale
mode, and layout options accept comma-separated values.

## Covering the problem space

Dimension arguments accept a single integer, comma-separated integers, or inclusive
ranges with the syntax `start:end:increment` or `start:end`. Quote values that
contain spaces, such as `"128, 1024"`. All combinations of M, N, K, and L values
are profiled. Dtype, layout, scale-dtype, and scale-mode lists are also expanded
as a Cartesian product. Each concrete result contains a scalar `cmd` that can
reproduce that individual test.

Sweep K from 128 to 4096 in steps of 128:
```bash
cutlass_profiler run --operation gemm --M 4096 --N 4096 --K 128:4096:128
```

Sweep both M and N:
```bash
cutlass_profiler run --operation gemm --M 512:2048:512 --N 512:2048:512 --K 1024
```

Sweep dtype, layout, and block-scale configurations:
```bash
cutlass_profiler run --operation gemm --M 2048 --N 2048 --K 1024 \
    --A-dtype e4m3,e5m2 --B-dtype e2m1,e4m3 \
    --out-dtype f16,f32 --accum-dtype f32 --layout tnt,ttt \
    --AB-scale-dtype ue8m0,ue4m3 --AB-scale-mode 1x16,1x32
```

## Examples

Profile a single problem size (all providers, f16):
```bash
cutlass_profiler run --operation gemm --M 1024 --N 1024 --K 512
```

Restrict to a specific provider:
```bash
cutlass_profiler run --operation gemm --M 1024 --N 1024 --K 512 --provider cutedsl
```

Profile FP8 GEMM:
```bash
cutlass_profiler run --operation gemm --M 2048 --N 2048 --K 1024 \
    --A-dtype e4m3 --B-dtype e4m3 --out-dtype f16 --accum-dtype f32
```

Profile an MXFP8 block-scaled GEMM. CPU verification is unavailable for scaled GEMM;
use `--verification-mode cuda` or `--verification-mode none`:
```bash
cutlass_profiler run --operation gemm --M 2048 --N 2048 --K 1024 \
    --A-dtype e4m3 --B-dtype e4m3 --out-dtype f32 --accum-dtype f32 \
    --AB-scale-dtype ue8m0 --AB-scale-mode 1x32
```

# Grouped GEMM

The grouped profiler covers contiguous-offset grouped GEMM with one varying
dimension.

## Grouped GEMM Arguments

The complete set of grouped-GEMM-specific arguments appears as follows.

```text
  --M-extents <tuple[;tuple...]>      Per-group M extents; choose exactly one extents option.
  --N-extents <tuple[;tuple...]>      Per-group N extents; choose exactly one extents option.
  --K-extents <tuple[;tuple...]>      Per-group K extents; choose exactly one extents option.
  --M <int|list|range>                Fixed M dimension; required unless M extents are selected.
  --N <int|list|range>                Fixed N dimension; required unless N extents are selected.
  --K <int|list|range>                Fixed K dimension; required unless K extents are selected.
  --A-dtype <dtype|list>              A matrix dtype (default: f16).
  --B-dtype <dtype|list>              B matrix dtype (default: f16).
  --out-dtype <dtype|list>            out matrix dtype (default: f16).
  --accum-dtype <dtype|list>          Accumulator dtype (default: f32).
  --layout <layout|list|auto>         A/B/out memory layouts (default: auto).
```

Select exactly one of `--M-extents`, `--N-extents`, or `--K-extents`. Omit the
fixed dimension for that axis and provide the other two fixed dimensions. Each
extents argument accepts semicolon-separated problem tuples whose entries are
comma-separated per-group extents. Fixed dimensions accept the same single,
comma-separated, and inclusive-range forms as GEMM dimensions.

The CLI accepts the same data dtype names listed for GEMM. Available dtype
combinations and offset axes depend on the selected operator; the current SM100
contiguous-offset operator supports M offsets. Dtype and layout lists are
expanded as a Cartesian product for every grouped problem size.

`total_bytes`, and the `bandwidth_gb_per_sec` and `flop_per_byte` derived
from it, count only the A, B, and out operands. The offsets buffer is
per-group index metadata rather than GEMM traffic, so it is excluded from
the roofline.

```bash
cutlass_profiler run --operation grouped_gemm \
    --M-extents '64,128,64;128,128,128' --N 512 --K 128 \
    --A-dtype f16 --B-dtype f16 --out-dtype f16 --accum-dtype f32 --layout tnt \
    --verification-mode none
```

Batched GEMM:
```bash
cutlass_profiler run --operation gemm --M 256 --N 256 --K 128 --L 16
```

Dry-run to check configuration without executing:
```bash
cutlass_profiler dry-run --operation gemm --M 1024 --N 1024 --K 512
```

Filter to specific operators:
```bash
cutlass_profiler run --operation gemm --M 1024 --N 1024 --K 512 \
    --operators 'cutedsl.Sm100DenseGemmUniversalOperator*'
```

Filter by operator implementation class using a regular expression:
```bash
cutlass_profiler run --operation gemm --M 1024 --N 1024 --K 512 \
    --op_class '^Sm100(DenseGemmUniversal|PersistentDenseGemmEFC)$'
```

`--op_class` matches `OperatorMetadata.operator_class.__name__` and composes
with `--operators` and reflected metadata options such as `--design`.

Filter to SM100 design metadata:
```bash
cutlass_profiler run --operation gemm --M 1024 --N 1024 --K 512 --design sm100
```

Filter to specific design metadata fields:
```bash
cutlass_profiler run --operation gemm --M 1024 --N 1024 --K 512 --design sm100 \
    --design.tile_shape 128x128x64 --design.use_tma_store
```

The `--design` argument selects a design metadata class such as `sm100`.
Individual design fields use the `--design.<field_name>` syntax and preserve
Python field names, including underscores. Nested metadata fields use additional
dots, for example `--design.nested.stages`.

Reorder matching operators with a heuristic (still profiles all matches):
```bash
cutlass_profiler run --operation gemm --M 1024 --N 1024 --K 512 --heuristic nvmatmul
```

Profile only the top-ranked operators from a heuristic:
```bash
cutlass_profiler run --operation gemm --M 1024 --N 1024 --K 512 --heuristic nvmatmul --limit 5
```

Profile under Nsight Systems:
```bash
cutlass_profiler run --operation gemm --M 2048 --N 2048 --K 1024 --nsys
```

## Example Output

### YAML (default)

The default standard output is a YAML multi-document stream. Each completed
result is printed immediately as a mapping introduced by `---`. Each record
includes the problem and operator identity, a directly reproducible `cmd`,
the problem spec (`M`/`N`/`K`/... and dtypes), correctness information
(`status`, `verified`, `max_abs_error`, `max_rel_error`, and wall-clock time
for benchmarking, verification, and result preparation in
`test_elapsed_ms`), and finally performance metrics (`operator_runtime_ms`,
`total_bytes`, `tflop_per_sec`, ...). JSON, CSV, and sorted YAML output are
buffered until all results are available so their document structure or
requested order is preserved.

```bash
cutlass_profiler run --operation gemm --M 1024 --N 1024 --K 512
```

```yaml
---
problem_id: 1
provider: cutedsl
operation_kind: gemm
operator_name: cutedsl.Sm100DenseGemmUniversalOperator_...
cmd: cutlass_profiler run --operation gemm --M 1024 --N 1024 --K 512
M: 1024
N: 1024
K: 512
layout: tnt
a_dtype: f16
b_dtype: f16
out_dtype: f16
L: 1
status: Success
verified: true
max_abs_error: 1.23000e-04
max_rel_error: 5.67000e-05
test_elapsed_ms: 42.31
operator_runtime_ms: 0.01367
total_bytes: 3932160
tflop_per_sec: 78.88
flop_per_byte: 171.8
flop_count: 1.07374e+09
bandwidth_gb_per_sec: 2.80230e+02
bandwidth_gib_per_sec: 2.60980e+02
```

Every reported value carries six significant digits, except `total_bytes`,
which stays an exact integer.

`max_abs_error`, `max_rel_error`, `bandwidth_gb_per_sec`,
`bandwidth_gib_per_sec`, and `flop_count` are always written in scientific
notation, because they span many orders of magnitude between runs and a fixed
exponent form stays comparable at a glance. The remaining floats use
scientific notation only when their magnitude calls for it.

The values stay YAML and JSON numbers and reload as floats; only their
rendering changes. JSON renders them in whichever form the `json` module
picks, so a JSON record may spell the same value as `0.00108357` where YAML
spells it `1.08357e-03`.

`flop_count` is consequently reported to six significant digits rather than
exactly (`1.07374e+09` for 1073741824, a relative error around 1e-6). When
you need the exact count it is `2 * M * N * K * L` from the same record.

Metric names distinguish counts from rates: `flop_count` is the number of
floating-point operations performed, `flop_per_byte` is arithmetic intensity,
and `tflop_per_sec` is throughput. Every format reports throughput in the same
TFLOP/s unit.

### YAML, JSON, and CSV

`--output-format` selects the machine-readable format for both standard output
and `--output-file`. When `--output-file` is provided without `--append`, the
file contains exactly the same payload as standard output and uses the path
verbatim; no operation name or extension is added.

`--append` keeps the destination valid for its selected format. YAML retains one
explicit document per result, JSON promotes single-result mappings to a sequence
as records accumulate, and CSV retains one header and appends only data rows.
The destination must already contain output written with the same format.

CSV includes `Command`, `OperatorRuntime`, and `TestElapsed` columns, and
names its metric columns for their units: `FlopCount`, `Flop/Byte`, `GB/s`,
and `TFLOP/s`. Scaled GEMM records in every format also include
`AB_scale_dtype`, `AB_scale_mode`, and `AB_scale_swizzle`.

```bash
# Print JSON and write the identical payload to report.json.
cutlass_profiler run --operation gemm --M 1024 --N 1024 --K 512 \
    --output-format json --output-file report.json

# Merge another run into the same valid JSON result sequence.
cutlass_profiler run --operation gemm --M 2048 --N 1024 --K 512 \
    --output-format json --output-file report.json --append

# CSV can still be redirected when no output file is needed.
cutlass_profiler run --operation gemm --M 512:2048:512 --N 1024 --K 256 \
    --output-format csv > report.csv
```

## Architecture

```text
cutlass/profiler/
├── __main__.py        CLI entry point, argparse, nsys integration
├── cli.py             Dtype maps, parsing helpers, common CLI args
├── timing.py          CUDA event timing, CUDA graphs, L2 cache rotation
├── analysis.py        PerfMetrics, bandwidth, verification
├── formatters.py      YAML, JSON, and CSV formatting helpers
├── profiling_results.py  Typed operation-independent results
└── operations/
    ├── base.py        OperationProfiler ABC, operator selection
    ├── desc.py        Typed operation problem descriptions
    ├── operand_factory.py  Runtime dense/scaled tensor allocation
    ├── gemm.py        GemmArguments profiler (dense and scaled)
    └── grouped_gemm.py  M/N/K-offset IndexPtrGroupedGemmArguments profiler
```

The profiler uses an operation-based architecture. Each operation type (GEMM, grouped GEMM, etc.)
implements the `OperationProfiler` interface:
- `name()` - value accepted by `--operation`
- `add_arguments()` - register operation-specific CLI args
- `profile()` - run profiling, return results
- `print_config()` - display configuration

The root package exposes the profiler entry point and extension APIs. Register a
custom operation profiler before invoking `main()`:

```python
from cutlass.profiler import OperationProfiler, main, register_operation


@register_operation
class MyProfiler(OperationProfiler):
    ...


main()
```

Custom design metadata can likewise be registered before parser construction:

```python
from cutlass.profiler import register_design

register_design("my_design", MyDesignMetadata, required_modules)
```

# Copyright

Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
SPDX-License-Identifier: BSD-3-Clause

```text
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
```
