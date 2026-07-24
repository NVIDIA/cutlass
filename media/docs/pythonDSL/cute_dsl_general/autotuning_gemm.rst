.. _autotuning_gemm:

Guidance for Auto-Tuning
============================= 

Numerous GEMM kernel code examples are offered within our codebase. 
When integrating these kernels into frameworks, auto-tuning becomes essential 
for achieving optimal performance. This involves selecting the appropriate 
kernel parameters based on the inputs of real applications.
Next, we'll briefly introduce some tips on how to perform auto-tuning.

The auto-tuning process typically involves the following steps:

1. Define search space
2. Benchmark each configuration and select the kernel with the best performance
3. Enable caching to reduce the tuning cost

The search space defines the valid combinations of kernel parameters that can be used to run the kernels. 
Different inputs (shapes, data types, etc.) typically require different kernel parameters to achieve optimal performance.
The search space is related to the kernel. We take the Blackwell GEMM persistent kernel as an example. 
The search space is as follows:

- ``mma_tiler_mn``: Defines the dimensions of the matrix tile that each Matrix Multiply-Accumulate (MMA) instruction processes in a single operation. 
- ``cluster_shape_mn``: Specifies the number of CTAs along each dimension within a cluster. Refer `Parallel Thread Execution ISA documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/index.html#tensorcore-5th-generation-family-instructions>`_ for the possible mma tiler size and cluster shape for different tensor data types.
- ``use_2cta_instrs``: Whether to utilize Blackwell's 2 CTA instructions for MMA/Copy.
- ``use_tma_store``: Whether to use Tensor Memory Access (TMA) instructions to store the result back to global memory.

After defining the search space, we could traverse all parameter combinations to find the optimal kernel. 
The ``autotune_gemm`` function below demonstrates a simple exhaustive search approach - it iterates 
through configurations, compiles and benchmarks each kernel, and returns the best performing one.
Since kernel compilation incurs overhead, it's important to cache and reuse compiled kernels 
to minimize host launch latency. CuTe DSL facilitates this through its separate compilation 
and execution workflow. More details can be found in :ref:`JIT_Caching`.
As demonstrated in the ``autotune_gemm`` function 
(between the ``begin of cache the compiled GEMM kernel`` and ``end of cache the compiled GEMM kernel`` comments), 
we can use ``cute.compile()`` to compile a kernel once, cache the compiled result, and reuse the cached JIT executor for multiple kernel 
executions. We could maintain a global configuration-to-kernel dictionary (``config_kernel_dict``) to cache the compiled GEMM kernels, 
where each key (``kernel_cache_key``) uniquely identifies a kernel based on its characteristics.
Usually we could use the {dtype + kernel configs} as the cached key for GEMM compilation. For example, 

.. code-block:: python

    kernel_cache_key = f"{ab_dtype}x{c_dtype}x{acc_dtype}x{use_2cta_instrs}x{mma_tiler}x{cluster_shape_mn}x{use_tma_store}"

If the input tensor's layout is static, we should add the shape in the cached key too.
Users can customize the ``benchmark`` function to measure kernel execution time.
For stable and reliable performance measurements:

1. Run a few warmup iterations (e.g., 5-10) to stabilize GPU temperature
2. Execute multiple timed iterations (e.g., 100-1000) for statistical significance
3. Use CUDA events and synchronization for precise timing
4. Lock GPU frequencies (SM and memory frequencies) with nvidia-smi
5. Process results by removing outliers and using min/avg statistics as measurements.

This ensures reliable kernel selection through proper benchmarking.

.. code-block:: python

    # get the best GEMM kernel for given input tensors
    def autotune_gemm(
        a: cute.Tensor,
        b: cute.Tensor,
        c: cute.Tensor,
        stream: cuda.CUstream,
        use_2cta_instrs_list: List[bool] = [True],
        use_tma_store_list: List[bool] = [True],
        mma_tiler_m_list: List[int] = [256],
        mma_tiler_n_list: List[int] = [256],
        cluster_shape_m_list: List[int] = [2],
        cluster_shape_n_list: List[int] = [1],
    ):
        best_kernel = None
        min_time = float("inf")
        # traverse the search space
        for use_2cta_instrs in use_2cta_instrs_list:
            for use_tma_store in use_tma_store_list:
                for mma_tiler_mn in product(mma_tiler_m_list, mma_tiler_n_list):
                    for cluster_shape_mn in product(cluster_shape_m_list, cluster_shape_n_list):
                        acc_dtype = cutlass.Float32
                        hardware_info = cutlass.utils.HardwareInfo()
                        max_active_clusters = hardware_info.get_max_active_clusters(
                            cluster_shape_mn[0] * cluster_shape_mn[1]
                        )
                        # instance a GEMM kernel
                        gemm = PersistentDenseGemmKernel(
                            acc_dtype,
                            use_2cta_instrs,
                            mma_tiler_mn,
                            cluster_shape_mn,
                            use_tma_store,
                        )
                        # begin of cache the compiled GEMM kernel
                        if kernel_cache_key not in config_kernel_dict:
                            # compile gemm kernel
                            compiled_gemm = cute.compile(
                                gemm,
                                a,
                                b,
                                c,
                                max_active_clusters,
                                stream,
                            )
                            config_kernel_dict[kernel_cache_key] = compiled_gemm
                        else:
                            compiled_gemm = config_kernel_dict[kernel_cache_key]
                        # end of cache the compiled GEMM kernel
                        try:
                            # define a benchmark function to measure the execution time of the compiled GEMM kernel
                            cur_time = benchmark(
                                partial(compiled_gemm, a, b, c, stream),
                            )
                        except Exception as e:
                            print(f"Execution error: {e}")
                            cur_time = float("inf")
                        if cur_time < min_time:
                            min_time = cur_time
                            best_kernel = compiled_gemm
        if best_kernel is None:
            raise ValueError("No best kernel found")
        return best_kernel

This brute-force approach ensures we could find the optimal parameters, though at the cost of trying every possibilities.
For more advanced use cases, users can explore sophisticated optimization 
techniques like search space pruning and genetic algorithms to reduce tuning overhead and discover better 
configurations more efficiently.

To further optimize tuning performance, we can utilize caching mechanisms to avoid redundant computations.
We could cache the tuning results in a input-to-kernel dictionary (e.g., ``input_kernel_dict``). 
When processing inputs with matching ``config_key`` values, the cached kernel can be reused directly without re-tuning. 
The ``config_key`` is related with the input tensor's characteristics, such as the shape, data type, etc. 
The setup of ``config_key`` is very flexible, users can customize it based on their own application.
For instance, if the data type is fixed in users' application, we could use the input tensor's shape as the key, i.e., ``(M, N, K)``. 
To further reduce tuning overhead, we could consider using a simplified key like ``config_key = (power_of_2(M), power_of_2(N), power_of_2(K))``, 
where ``M``, ``N``, and ``K`` are rounded up to the nearest power of 2. This simplification can significantly reduce the number 
of unique keys while still maintaining good performance in most cases. However, it's important to validate that this 
approximation doesn't negatively impact performance for your specific use case. 

.. code-block:: python

    config_key = (M, N, K)
    if config_key in input_kernel_dict:
        compiled_gemm = input_kernel_dict[config_key]
    else:
        compiled_gemm = autotune_gemm(...)
        input_kernel_dict[config_key] = compiled_gemm
    # launch gemm kernel
    compiled_gemm(a_tensor, b_tensor, c_tensor, stream)

By following the methods above, you can customize your own auto-tuner to find the optimal GEMM kernel configuration 
for specific matrix dimensions and data types, significantly improving computational performance for models.

Autotuning JIT kernels with CuTeDSL functions
---------------------------------------------

The manual ``autotune_gemm`` loop above demonstrates the general principle behind tuning CuTeDSL kernels. 
CuTeDSL provides a higher-level interface for this process which relies on the same underlying mechanism, 
which is the ``autotune_jit`` decorator from ``cutlass.cute.testing``. It performs the same "compile every
configuration, benchmark, keep the best" strategy but it does so automatically,
handling the search-space sweep lazily when the function is called, performing the cold-L2 benchmarking,
and caching the compiled kernel automatically for you.

We still use the persistent GEMM kernel as an example. We first need to define the ``@cute.jit`` function.
It should accept the tunable parameters as ``Constexpr`` keyword arguments.

The non-autotuned version should look like this:

.. code-block:: python

    import cutlass
    import cutlass.cute as cute
    import cutlass.cute.testing as testing
    from dense_gemm_persistent import PersistentDenseGemmKernel

    @cute.jit
    def non_autotuned_gemm(
        a, b, c, stream, M, N, K,
        use_2cta_instrs: cutlass.Constexpr = True,
        use_tma_store: cutlass.Constexpr = True,
        mma_tiler_mn: cutlass.Constexpr = (256, 256),
        cluster_shape_mn: cutlass.Constexpr = (2, 1),
        max_active_clusters: cutlass.Constexpr = 0,
    ):
        kernel = PersistentDenseGemmKernel(
            cutlass.Float32,  # acc_dtype
            use_2cta_instrs,
            mma_tiler_mn,
            cluster_shape_mn,
            use_tma_store,
        )
        kernel(a, b, c, max_active_clusters, stream)

Since ``cluster_shape_mn`` is a tunable parameter and it's unknown when we do the grid sweep and search the optimal configuration, 
``autotune_jit`` needs to know how to compute ``max_active_clusters`` on the host side based on the current  ``cluster_shape_mn`` value when tuning.
Therefore, to allow this function to be autotuned with ``max_active_clusters`` being a parameter, we need to define an 
auxiliary function on the host side to derive the ``max_active_clusters`` parameter from the swept ``cluster_shape_mn`` value when tuning.


.. code-block:: python

    # max_active_clusters is derived from the swept cluster_shape_mn. It is
    # computed on the host, because HardwareInfo cannot run inside @cute.jit.
    def derive_max_active_clusters(cluster_shape_mn):
        return cutlass.utils.HardwareInfo().get_max_active_clusters(
            cluster_shape_mn[0] * cluster_shape_mn[1]
        )


The search space is a dictionary mapping each tunable parameter to its candidate
values; every combination is tried. Add more candidates to a list to widen the
sweep:

.. code-block:: python

    search_space = {
        "use_2cta_instrs": [True],
        "use_tma_store": [False, True],
        "mma_tiler_mn": [(128, 128), (256, 128), (256, 256)],
        "cluster_shape_mn": [(2, 1), (2, 2)],
    }

The configurations we will search are the Cartesian product of all these lists, so there are 12 total configurations in this example.
If you have a large search space, you can prune it by removing configurations that are known to be invalid or suboptimal using ``prune_configs``.
``prune_configs`` is a predicate function whose parameters are a subset of the tunable parameters (the keys of ``params_dict`` with the same name).
It returns ``True`` to keep a configuration or ``False`` to skip it. For example, to
reject one specific configuration -- the largest tile paired with the largest
cluster -- from the sweep:

.. code-block:: python

    def prune_config(mma_tiler_mn, cluster_shape_mn):
        # only these two parameters are inspected; return False to drop this config
        return not (mma_tiler_mn == (256, 256) and cluster_shape_mn == (2, 2))

This drops 2 of the 12 configurations (``(256, 256)`` with ``(2, 2)`` for either
``use_tma_store`` value), leaving 10 to benchmark.

Then we can decorate the CuTeDSL function with ``autotune_jit`` to sweep this search space and find the best configuration.
The first call to the decorated function for a given M, N, K problem size sweeps the search space, benchmarks each configuration and caches the best compiled kernel; 
and subsequent calls whose ``update_on_change`` values (here ``M, N, K``) are unchanged reuse it without re-tuning. 

For parameters in ``param_dict``, they are removed from the decorated function's signature so when calling the decorated function you do not need to pass them, and they are automatically tuned.
And parameters in ``derived_params`` work similarly; you don't pass them and their value will be derived from the current values of the other parameters in ``param_dict`` using the function you provides, 
whose signature must match the parameters in ``param_dict`` that it depends on with the same name. So for example, ``derive_max_active_clusters`` above takes ``cluster_shape_mn`` as an argument, 
and it will use the current value of ``cluster_shape_mn`` for each configuration during the sweep to derive the value of ``max_active_clusters`` argument.
For parameters in ``update_on_change``, they are used as the key to cache compiled kernels, so when any of them changes the decorated function will re-tune and cache a new best kernel for that combination. 
When calling the decorated function, you still need to pass them as normal arguments.

.. code-block:: python

    import cutlass
    import cutlass.cute as cute
    import cutlass.cute.testing as testing
    from dense_gemm_persistent import PersistentDenseGemmKernel

    @testing.autotune_jit(
        params_dict=search_space,
        update_on_change=["M", "N", "K"],
        derived_params={"max_active_clusters": derive_max_active_clusters},
        prune_configs=prune_config,
        warmup_iterations=5,
        iterations=100,
    )
    @cute.jit
    def autotuned_gemm(
        a, b, c, stream, M, N, K,
        use_2cta_instrs: cutlass.Constexpr = True,
        use_tma_store: cutlass.Constexpr = True,
        mma_tiler_mn: cutlass.Constexpr = (256, 256),
        cluster_shape_mn: cutlass.Constexpr = (2, 1),
        max_active_clusters: cutlass.Constexpr = 0,
    ):
        kernel = PersistentDenseGemmKernel(
            cutlass.Float32,  # acc_dtype
            use_2cta_instrs,
            mma_tiler_mn,
            cluster_shape_mn,
            use_tma_store,
        )
        kernel(a, b, c, max_active_clusters, stream)

    autotuned_gemm(a, b, c, stream, M, N, K)  # first call for this (M, N, K) autotunes
    autotuned_gemm(a, b, c, stream, M, N, K)  # subsequent calls reuse the cached best kernel
    print(f"Best config for autotuned_gemm: {autotuned_gemm._best_config[(M, N, K)]}")

Autotuning JIT kernels with classes
-----------------------------------

Many CuTe DSL kernels are written as classes: the tunable configuration is passed
to the constructor, and a ``@cute.jit`` ``__call__`` method takes only the dynamic
runtime arguments (which is the structure of ``PersistentDenseGemmKernel`` used
above). ``autotune_jit`` can decorate such a class directly, without writing an
adapter. It turns the class into a *partial* class: the tunable constructor
parameters are removed (which are auto-tuned), so you can use the decorated class like a
normal class -- you just do not pass the tunable parameters when instantiating.

Take a small elementwise-add kernel as an example, where ``elementwise_add`` is a
``@cute.jit`` function implementing the vectorized addition operation:

.. code-block:: python

    @testing.autotune_jit(
        params_dict={"COPY_BITS": [32, 64, 128], "THREADS_M": [4, 8]},
        update_on_change=["M", "N"],
        warmup_iterations=10,
        iterations=50,
    )
    class ElementwiseAddKernel:
        def __init__(self, COPY_BITS=128, THREADS_M=4):
            self.COPY_BITS = COPY_BITS
            self.THREADS_M = THREADS_M

        @cute.jit
        def __call__(self, mA, mB, mC, M, N):
            elementwise_add(
                mA, mB, mC, M, N,
                copy_bits=self.COPY_BITS,
                threads_m=self.THREADS_M,
            )

    autotuned_add = ElementwiseAddKernel()   # instantiate (no tunable params)
    autotuned_add(a, b, c, M, N)             # first call for this (M, N) autotunes
    autotuned_add(a, b, c, M, N)             # subsequent calls reuse the cached best kernel
    print(f"Best config for autotuned_add: {autotuned_add._best_config[(M, N)]}")


- ``params_dict`` takes the tuneable parameters that are passed to the class constructor (``COPY_BITS``,
  ``THREADS_M``). These are constexprs used to instantiate the kernel, and are baked in at compile time.
  When you create an instance of the decorated class, you do not need to pass these parameters; they will be auto-tuned.
  These tuneable parameters are removed from the decorated class's constructor signature.
  For non-tuneable parameters, user should still pass them when creating the instance as usual.
  And ``derived_params`` and ``prune_configs`` work the same way as in the function case.
- ``update_on_change`` names the ``__call__`` arguments to key the cache on
  (``M``, ``N``). When any of these change, the decorated class will re-tune and cache a new best kernel for that combination.
- Because the tunable parameters are separated into the constructor, the ``@cute.jit`` ``__call__`` takes only the dynamic arguments. 
  Therefore, unlike the decorated CuTeDSL function where it takes both the dynamic and tunable parameters in the signature,
  the separation here is clearer: the constructor parameters define the kernel configuration used to compile the kernel.
  Then, ``__call__`` takes the dynamic arguments that may change per execution.


Choosing one configuration for many shapes
-------------------------------------------

The JIT path tunes each problem size on its first call. When you instead need a single configuration baked into an ahead-of-time (AOT) build, 
or you simply don't want to compile kernels too often when input shapes change frequently, you can use ``autotune_suite`` to find one that performs well
across the shapes your application sees. ``autotune_suite`` allows you to grid-search the same space over a list of representative problem sizes.
For each case it builds fresh inputs with ``make_arguments``, compiles and benchmarks every
configuration (cycling through cold-L2 workspaces), and returns per-case timings plus a ranked list of recommended configurations.

You may then pick a configuration that you think is best and compile it ahead of time for use with all shapes.

Note: autotune_suite expects a non-autotuned CuTeDSL function or class that is not decorated by ``@testing.autotune_jit``.

.. code-block:: python

    import torch
    import cuda.bindings.driver as cuda
    from cutlass import cute
    from cutlass.cute.testing import autotune_suite

    torch_stream = torch.cuda.Stream()
    stream = cuda.CUstream(torch_stream.cuda_stream)

    def make_arguments(M, N, K):
        # Batched GEMM with a hardcoded batch size L = 1.
        #   A: (M, K, L) M-major, B: (N, K, L) K-major, C: (M, N, L) M-major
        L = 1
        a = torch.randn(L, K, M, dtype=torch.float16, device="cuda").permute(2, 1, 0)
        b = torch.randn(L, N, K, dtype=torch.float16, device="cuda").permute(1, 2, 0)
        c = torch.zeros(L, N, M, dtype=torch.float16, device="cuda").permute(2, 1, 0)
        return a, b, c, stream, M, N, K

    with torch.cuda.stream(torch_stream):
        reports, recommended = testing.autotune_suite(
            non_autotuned_gemm,
            make_arguments,
            cases=[
                (2048, 2048, 4096),  # representative (M, N, K) problem sizes
                (4096, 4096, 2048),
            ],
            params_dict=search_space,
            prune_configs=prune_config,
            derived_params={"max_active_clusters": derive_max_active_clusters},
            accept_percentile=50,  # keep each case's fastest half of the configs
            print_summary=True,
            stream=stream,
        )

    # recommended is ranked by how many cases accepted each config within the
    # percentile you've given; here we just pick the top one and compile it ahead of time.
    best_config = recommended[0]["config"]
    args = make_arguments(2048, 2048, 4096)
    compiled_gemm = cute.compile(non_autotuned_gemm, *args, **best_config)
    compiled_gemm(*args)

``reports`` holds one timing table per case (each configuration's measured time, fastest first) so user can use this to decide what's their favorite configuration, 
and ``recommended`` ranks configurations by how many cases accepted them within each input case's top ``accept_percentile`` configurations

The heuristic behind this is simple. You don't want a configuration that is the fastest for one case but slow for others, and a configuration that is consistently good
among all these representative cases is more likely to be the preferred choice in general (even if it's never the best for any of those cases). It will return the top 5
most widely accepted configurations like this:

.. code-block:: text

    recommended configs:
        {'cluster_shape_mn': (2, 1), 'max_active_clusters': 76, 'mma_tiler_mn': (128, 128), 'use_2cta_instrs': True, 'use_tma_store': True}: accepted in 2/2 cases
        {'cluster_shape_mn': (2, 1), 'max_active_clusters': 76, 'mma_tiler_mn': (256, 256), 'use_2cta_instrs': True, 'use_tma_store': True}: accepted in 2/2 cases
        {'cluster_shape_mn': (2, 2), 'max_active_clusters': 36, 'mma_tiler_mn': (256, 128), 'use_2cta_instrs': True, 'use_tma_store': True}: accepted in 1/2 cases
        {'cluster_shape_mn': (2, 1), 'max_active_clusters': 76, 'mma_tiler_mn': (256, 128), 'use_2cta_instrs': True, 'use_tma_store': True}: accepted in 1/2 cases
        {'cluster_shape_mn': (2, 2), 'max_active_clusters': 36, 'mma_tiler_mn': (256, 128), 'use_2cta_instrs': True, 'use_tma_store': False}: accepted in 1/2 cases

Note: about ``workspace_count``, this is the parameter that is crucial to ensure the benchmarking is accurate in terms of memory bandwidth.
This means ``autotune_suite`` will allocate a workspace of size ``workspace_count`` copies of input arguments using ``make_arguments`` you pass, 
and it will cycle through these workspaces ``warmup_iterations`` + ``iterations`` times.
To let the benchmark correctly reflect the achieved memory bandwidth, we would like to make sure our kernel is reading from HBM instead of L2 cache during the benchmarking. 
Therefore, we need to make sure the workspace is large enough so that its size exceeds the L2 cache size, so when we finish one lap around the workspace ring buffer and get back to
the first workspace, the data is no longer in L2 cache and we are reading from HBM again.

For example, suppose our input tensors use 2MB of memory, and the L2 cache size is 10MB. If we set ``workspace_count`` to 6, then the total workspace size is 12MB, 
which **exceeds** the L2 cache size. In this case, when we are at iteration 7, the L2 cache would hold the 5 copies of inputs from workspace 2 to 6, and 
iteration 7 uses workspace 1, which is no longer in L2 cache and is read from HBM. 
In addition, a total workspace size equal to the L2 cache size is not sufficient, because in this case ``workspace_count`` is 5, which means at the 6th iteration we are back to workspace 1,
but it is still in L2 cache because L2 cache is large enough to hold all 5 copies of the input tensors. Therefore, we would be reading from L2 cache instead of HBM, which is not what we want.
The rule of thumb is that we need ``(workspace_count - 1) * size_of_input_data >= L2_cache_size`` to guarantee that when we finish one round and get back to the first workspace, its data is no longer in L2 cache.

In conclusion, you should always set ``workspace_count`` to a proper value that ensures that the current benchmark run always reads from HBM due to its input being evicted from L2 cache, 
or just set it to a large enough value that is guaranteed to **exceed** the L2 cache size.
