# CuTeDSL Compiler Diagnostics

This directory contains small CuTeDSL cases for compiler diagnostics. They
intentionally model invalid primitive synchronization protocols and ptxas
resource issues, then show the Python-facing diagnostics.

## Diagnostic levels

Diagnostics are enabled via `CUTE_DSL_COMPILER_OPT` or
`cute.compile(..., options=...)`. Warnings and remarks are opt-in and
non-fatal. Errors reported by an enabled diagnostic category are always shown
and fail compilation; there is no separate `errors{...}` option.

| Level | Enable with | Useful for | Fatal? |
|------|-------------|------------|--------|
| Info (remark) | `remarks` or `remarks{<category>}` | Performance-only findings, such as synchronization opportunities or register-spill/local-memory resource reports. | No |
| Warning | `warnings` or `warnings{<category>}` | Legal but questionable patterns that can hang, fault, or behave differently than intended. | No |
| Error | Enable the relevant category with `warnings{<category>}` or `remarks{<category>}`. | Proven defects reported by an enabled diagnostic category. | Yes |

## Diagnostic categories

A `{<category>}` selector shows only that category. The bare `warnings` or
`remarks` form shows all available categories.

| Category | Enable with | Source | Useful levels |
|----------|-------------|--------|---------------|
| `nvvm` | `warnings{nvvm}`, `remarks{nvvm}` | NVVM-level primitive protocol diagnostics for operations such as `mbarrier`, bulk copy, TMA multicast, and `tcgen05`. | Error, warning, info (remark) |
| `ptxas` (selector: `ptx`) | `remarks{ptx}` | `ptxas` resource diagnostics surfaced through the remark stream, including register spills and local-memory usage. | Info (remark) |

The `show_error.py` / `show_warning.py` / `show_remark.py` scripts each
demonstrate one diagnostic severity end to end. `show_error.py` includes both
an nvvm diagnostic error and an internal DSL error render.

For ptxas register-spill and local-memory debug helpers, run
`ptxas_spill_cases.py`. It contains compile-only cases for dynamic indexing
that forces local memory and for register pressure that triggers ptxas spill
remarks under a constrained register budget. The helper uses the console
diagnostic renderer, so remarks include source frames. Register-spill frames are
best-effort because `ptxas` reports spill totals per kernel; they mark the
reported kernel / likely pressure region rather than an exact spill instruction.

Run the Python DSL examples after installing the CuTe DSL package:

```bash
# Optional: source /path/to/your/workspace/env.sh first if your environment needs it.
  CUTE_DSL_COMPILER_OPT='warnings{nvvm}' \
  python \
  experimental/compiler_diagnostic/prims_negative_cases.py
```

Run one case by name:

```bash
# Optional: source /path/to/your/workspace/env.sh first if your environment needs it.
  CUTE_DSL_COMPILER_OPT='warnings{nvvm}' \
  python \
  experimental/compiler_diagnostic/prims_negative_cases.py \
  --case expect_tx_without_complete_tx
```

The compiler owns diagnostic formatting. The example catches expected
`CompilerDiagnosticError` failures and prints those diagnostics as-is.
Warning-only cases, such as the invalid CTA_2 TMA multicast cluster-size
pattern, are kept here as compile-only diagnostic reproducers rather than in
the runnable primitive examples.

Use `--raw` to print the raw compiler pass failure for expected compile errors:

```bash
# Optional: source /path/to/your/workspace/env.sh first if your environment needs it.
  CUTE_DSL_COMPILER_OPT='warnings{nvvm}' \
  python \
  experimental/compiler_diagnostic/prims_negative_cases.py \
  --case unguarded_count1_arrive \
  --raw
```

