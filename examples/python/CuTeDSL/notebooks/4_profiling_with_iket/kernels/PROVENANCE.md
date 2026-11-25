# Kernel provenance

Every kernel here derives from an unmodified example in this repository: the tutorial GEMMs in
[`cute/blackwell/tutorial/tutorial_gemm/`](../../../cute/blackwell/tutorial/tutorial_gemm) and
[`cute/blackwell/kernel/attention/fmha/fmha.py`](../../../cute/blackwell/kernel/attention/fmha/fmha.py).
Those originals are not copied here; the notebooks diff against them in place.

## `modified/` — restructured, derived

These change kernel *structure* so a phase becomes observable. They are derived works and are **not**
upstream CUTLASS examples — do not report bugs in them against the originals.

| File | Derived from | Change |
|---|---|---|
| `fp16_gemm_0x.py` | `fp16_gemm_0.py` | The implicit `cutlass.range(..., prefetch_stages=N)` prefetch is hoisted into an explicit prefetch loop followed by a plain mainloop, so the prefetch phase can be wrapped in its own IKET range and the stage count swept. Used by notebooks 01 and 02. |

`instrumented/fp16_gemm_1x_iket_detailed.py` applies the matching restructure to `fp16_gemm_1.py`, so
notebook 03 compares like with like against `0x`.

## `instrumented/` — IKET-annotated

Each is its `modified/` or upstream counterpart plus `cutlass.cute.experimental.iket` calls. No
kernel logic differs from the file it annotates; the diff is instrumentation only, and the notebooks
render that diff inline.

Naming:

| Suffix | Meaning |
|---|---|
| `_iket` | Coarse: a small number of top-level phase ranges |
| `_iket_detailed` | Per-iteration ranges around every phase, wait, and async op |
| `_marks` | Async issues (`tma_issue`, `mma_issue`, `cons_release`) as `iket.mark`s with an iteration payload; ranges kept only for true waits and phases. **The recommended style** — cheaper, and less likely to overflow the trace buffer |
| `_ps_N` | Prefetch-stage sweep variant with N prefetch stages |
