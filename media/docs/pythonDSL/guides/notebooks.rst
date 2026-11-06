.. _notebooks:

Educational Notebooks
=====================

The CuTeDSL educational notebooks live in the `CUTLASS GitHub repository
<https://github.com/NVIDIA/cutlass/tree/main/examples/python/CuTeDSL>`__.

The self-contained Jupyter-notebook course for the CuTeDSL Primitives programming model
runs end-to-end on a CUDA GPU; the course index with one-line topic summaries is in
`notebooks/README.md <https://github.com/NVIDIA/cutlass/tree/main/examples/python/CuTeDSL/notebooks/README.md>`__.

- `Hello world <https://github.com/NVIDIA/cutlass/tree/main/examples/python/CuTeDSL/notebooks/1_dsl_features/01_hello_world.ipynb>`__ -- ``@cute.jit`` / ``@cute.kernel``; host ``print()`` vs device ``cute.printf()``
- `Control flow <https://github.com/NVIDIA/cutlass/tree/main/examples/python/CuTeDSL/notebooks/1_dsl_features/02_control_flow.ipynb>`__ -- meta loops vs staged loops, ``range_constexpr`` / ``range(unroll=)``, ``const_expr`` branches
- `Diagnostics <https://github.com/NVIDIA/cutlass/tree/main/examples/python/CuTeDSL/notebooks/1_dsl_features/03_diagnostics.ipynb>`__ -- compiler ``warnings{...}`` / ``remarks{...}`` options
- `Zero-cost abstraction <https://github.com/NVIDIA/cutlass/tree/main/examples/python/CuTeDSL/notebooks/1_dsl_features/04_zero_cost_abstraction.ipynb>`__ -- classes and polymorphism are trace-time Python
- `Array concepts <https://github.com/NVIDIA/cutlass/tree/main/examples/python/CuTeDSL/notebooks/2_primitives/01_array_concepts.ipynb>`__ -- ``cutlass.Array`` and the GPU memory spaces
- `Vector concepts <https://github.com/NVIDIA/cutlass/tree/main/examples/python/CuTeDSL/notebooks/2_primitives/02_vector_concepts.ipynb>`__ -- ``cutlass.Vector``: registers vs memory
- `CuTe interop <https://github.com/NVIDIA/cutlass/tree/main/examples/python/CuTeDSL/notebooks/2_primitives/03_cute_interop.ipynb>`__ -- ``cute.Tensor`` and ``cutlass.Array`` interop
- `Tiled GEMM <https://github.com/NVIDIA/cutlass/tree/main/examples/python/CuTeDSL/notebooks/2_primitives/04_tiled_gemm.ipynb>`__
- `TMA load <https://github.com/NVIDIA/cutlass/tree/main/examples/python/CuTeDSL/notebooks/2_primitives/05_tma_load.ipynb>`__ -- TMA load with ``mbarrier``
- `Prefix sum <https://github.com/NVIDIA/cutlass/tree/main/examples/python/CuTeDSL/notebooks/2_primitives/06_prefix_sum.ipynb>`__ -- warp-shuffle scan
- `Softmax <https://github.com/NVIDIA/cutlass/tree/main/examples/python/CuTeDSL/notebooks/3_kernels/01_softmax.ipynb>`__ -- naive to online/flash softmax
- `2D stencil <https://github.com/NVIDIA/cutlass/tree/main/examples/python/CuTeDSL/notebooks/3_kernels/02_stencil_2d.ipynb>`__ -- heat-diffusion step, naive vs shared-memory halo tiling
- `Blackwell MMA <https://github.com/NVIDIA/cutlass/tree/main/examples/python/CuTeDSL/notebooks/3_kernels/03_blackwell_mma.ipynb>`__ -- minimal ``tcgen05`` GEMM (sm_100a)
- `Blackwell MMA with context variables <https://github.com/NVIDIA/cutlass/tree/main/examples/python/CuTeDSL/notebooks/3_kernels/04_blackwell_mma_contextvar.ipynb>`__ -- the same GEMM driven by Python ``contextvars`` (sm_100a)

Related notebooks
-----------------

The long-standing CuTe-layout and CUDA-runtime series lives under
`cute/notebooks <https://github.com/NVIDIA/cutlass/tree/main/examples/python/CuTeDSL/cute/notebooks>`__:

- `Layout algebra <https://github.com/NVIDIA/cutlass/tree/main/examples/python/CuTeDSL/cute/notebooks/cute_layout_algebra.ipynb>`__
- `Composed layouts <https://github.com/NVIDIA/cutlass/tree/main/examples/python/CuTeDSL/cute/notebooks/composed_layout.ipynb>`__
- `Asynchronous pipelines <https://github.com/NVIDIA/cutlass/tree/main/examples/python/CuTeDSL/cute/notebooks/async_pipeline.ipynb>`__
- `Element-wise add <https://github.com/NVIDIA/cutlass/tree/main/examples/python/CuTeDSL/cute/notebooks/elementwise_add.ipynb>`__
- `Using CUDA graphs <https://github.com/NVIDIA/cutlass/tree/main/examples/python/CuTeDSL/cute/notebooks/cuda_graphs.ipynb>`__
- `Benchmarking and autotuning <https://github.com/NVIDIA/cutlass/tree/main/examples/python/CuTeDSL/cute/notebooks/benchmark_autotune.ipynb>`__
- `Tour to a state-of-the-art GEMM <https://github.com/NVIDIA/cutlass/tree/main/examples/python/CuTeDSL/cute/notebooks/tour_to_sol_gemm.ipynb>`__
