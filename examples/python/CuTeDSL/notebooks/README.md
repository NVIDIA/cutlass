# CuTeDSL tutorial-notebook course

A hands-on Jupyter-notebook course for the **CuTeDSL** Primitives programming model.
Each chapter is a self-contained notebook that runs end-to-end on a CUDA GPU.

## Chapters

### 1. DSL features — [`1_dsl_features/`](1_dsl_features)
| notebook | topic |
|---|---|
| `01_hello_world.ipynb` | `@cute.jit` / `@cute.kernel`; `print()` (host, trace-time) vs `cute.printf()` (device, per-thread) |
| `02_control_flow.ipynb` | meta loops vs staged loops — `range_constexpr` / `range` / `range(unroll=)`, `const_expr` branches |
| `03_diagnostics.ipynb` | compiler diagnostics — the `warnings{...}` / `remarks{...}` options |
| `04_zero_cost_abstraction.ipynb` | classes & polymorphism are trace-time Python — they compile away (PTX proof) |

### 2. Primitives — [`2_primitives/`](2_primitives)
| notebook | topic |
|---|---|
| `01_array_concepts.ipynb` | `cutlass.Array` and the GPU memory spaces |
| `02_vector_concepts.ipynb` | `cutlass.Vector` — registers vs memory |
| `03_cute_interop.ipynb` | `cute.Tensor` ↔ `cutlass.Array` interop |
| `04_tiled_gemm.ipynb` | tiled GEMM — `Array`, shared memory, passing a `Callable` as kernel metaprogramming |
| `05_tma_load.ipynb` | TMA load + `mbarrier` |
| `06_prefix_sum.ipynb` | prefix sum (warp-shuffle scan) |

### 3. Kernels — [`3_kernels/`](3_kernels)
| notebook | topic |
|---|---|
| `01_softmax.ipynb` | softmax (naive → online/flash) |
| `02_stencil_2d.ipynb` | 2D 5-point stencil (a heat-diffusion step) — naive vs shared-memory halo tiling |
| `03_blackwell_mma.ipynb` | minimal Blackwell `tcgen05` GEMM (sm_100a) |
| `04_blackwell_mma_contextvar.ipynb` | the same `tcgen05` GEMM driven by Python `contextvars` (sm_100a) |

## Related notebooks

The long-standing CuTe-layout and CUDA-runtime series — CuTe layout algebra, async
pipelines, composed layouts, CUDA graphs, autotuning, and the tour to a
state-of-the-art GEMM — live alongside this course under
[`../cute/notebooks/`](../cute/notebooks).

## Running the notebooks

Open any notebook in Jupyter on a CUDA host. A few chapters target Blackwell
(`sm_100a`) tensor cores (`3_kernels/03`, `04`) and need a B100/B200-class GPU; the
rest run on any recent CUDA GPU. The course chapters are also executed end-to-end in
CI via `nbconvert`.
