# Profiling CuTe DSL kernels with IKET

A series of Jupyter notebooks on reading **in-kernel** performance data from CuTe DSL kernels.

Kernel-level timing tells you a GEMM took 31 µs. It does not tell you that the epilogue — not the
mainloop — was the largest phase, that adding a third prefetch stage moved a stall rather than removing
it, or that a dependent launch never actually overlapped because no SM was free. IKET (In-Kernel Event
Tracing) makes each of those visible as named, timestamped, per-warp phases.

Each notebook works one case: a question you cannot answer from the outside, the instrumentation that
answers it, the command that collects it, and what the trace turned out to say.

| # | Notebook | What it shows |
|---|---|---|
| 00 | [What IKET is, and your first profile](notebooks/00_what_is_iket.ipynb) | The four pieces, and a trace you collected yourself |
| 01 | [Pipeline basics: three ranges](notebooks/01_pipeline_basics.ipynb) | Prologue / mainloop / epilogue — and which one actually dominates |
| 02 | [Prefetch stages: more is not better](notebooks/02_prefetch_stages.ipynb) | The stall that moves instead of disappearing |
| 03 | [2-CTA MMA and multicast](notebooks/03_2cta_multicast.ipynb) | An optimization with a regime, and where the crossover is |
| 04 | [Warp specialization](notebooks/04_warp_specialization.ipynb) | Roles as concurrent bands; where the win really comes from |
| 05 | [Persistent and CLC scheduling](notebooks/05_persistent_scheduling.ipynb) | What flexibility costs when load is already balanced |
| 06 | [Preferred and fallback clusters](notebooks/06_cluster_shapes.ipynb) | How much of a 148-SM GPU runs the fallback path |
| 07 | [TMA prefetch into L2](notebooks/07_tma_prefetch.ipynb) | Whether the prefetch lands early enough to matter |
| 08 | [PDL: when the profiler proves you wrong](notebooks/08_pdl.ipynb) | A hypothesis that failed, and why that was the useful result |
| 09 | [The optimization ladder](notebooks/09_optimization_ladder.ipynb) | Six steps, 1.45×, and what each one removed |
| 10 | [FMHA: a multi-role pipeline](notebooks/10_fmha_multirole.ipynb) | Softmax dominates; the matmuls are noise |
| 11 | [Profile your own kernel](notebooks/11_profile_your_own_kernel.ipynb) | The transferable method, and the traps |

The notebooks assume the IKET reference guide,
[`iket_profiling.rst`](../../../../../media/docs/pythonDSL/guides/iket_profiling.rst), for the API surface,
range-pairing models, payloads, `run-iket` options, and the JSON trace schema, and do not duplicate it.

## Running

Every notebook is committed with its outputs and reads correctly with no GPU. To run the profiling cells
you need an NVIDIA GPU of a supported architecture (SM100, SM103, SM110, SM120), Python ≥ 3.12, and

```bash
pip install nvidia-cutlass-dsl torch jupyterlab
```

`run-iket` ships as a console script inside the `nvidia-cutlass-dsl` wheel. Launch Jupyter so each
notebook runs from `notebooks/`; it loads `../tools`, `../kernels` and `../figures` relative to that.
On a machine that cannot profile, the collection cells print the command they would have run and the
notebook continues against the committed figures.

`kernels/instrumented/` holds the IKET-annotated kernels the notebooks profile, `kernels/modified/` the
restructured variant notebook 01 diffs against (see `kernels/PROVENANCE.md`), and `figures/` the
reference results, one directory per notebook.

## Reproducing the numbers

Every quoted measurement states the GPU and the problem shape it came from. The reference profiles were
collected on a single **NVIDIA B300**. Numbers on other Blackwell parts will differ; the *shapes* in the
traces — which phase dominates, which wait grows — are the transferable part.

Durations in the notebook tables are IKET warp-lifetime spans. The kernel-time chart in notebook 09 uses
each kernel's own start and end timestamps rather than CUPTI `end − start`, which runs a near-constant
~0.65 µs high.
