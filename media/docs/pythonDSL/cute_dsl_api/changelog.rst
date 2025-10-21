======================================
Changelog for CuTe DSL API changes
======================================

`4.3.0 <https://github.com/NVIDIA/cutlass/releases/tree/main>`_ (2025-10-07)
==============================================================================

* Debuggability improvements:
  - Supported source location tracking for DSL APIs
  - Supported dumping PTX and SASS code
* Remove deprecated ``cutlass.<arch>_utils.SMEM_CAPACITY["<arch_str>"]`` and ``cutlass.utils.ampere_helpers``
* Support calling nested functions without capturing variables inside dynamic control flow
* Replace usage of ``cute.arch.barrier`` in examples with corresponding APIs in ``pipeline``
  - Use ``pipeline.sync`` for simple cases like synchronizing the whole CTA
  - Use ``pipeline.NamedBarrier`` to customize barriers with different participating threads and barrier id
* Added new APIs ``repeat`` and ``repeat_as_tuple``
* Added new APIs ``make_rmem_tensor`` to replace ``make_fragment`` with better naming
* Added new APIs ``make_rmem_tensor_like`` which create rmem tensor from a tensor using the same shape with compact col-major strides
* Added ``TmemAllocator`` for allocating tensor memory
* Updated ``SmemAllocator.allocate`` to support allocation of a single scalar value
* Fixed ``TensorSSA.reduce`` to support static value as initial value
* Updated docstring for following APIs to be more concise and easier to understand:
  - ``make_layout_tv``
  - ``is_static``
  - ``PipelineAsync``
  - ``SmemAllocator``
* Fixed documentation for ``pipeline``, ``utils`` and ``cute.math``


`4.2.0 <https://github.com/NVIDIA/cutlass/releases/tag/v4.2.0>`_ (2025-09-10)
==============================================================================

* Added back ``cute.make_tiled_copy`` per the request from community
* Added support for explicit and implicit broadcast in ``TensorSSA``
  - ``cutlass.cute.TensorSSA``: support ``broadcast_to`` and implicit broadcasting for binary operations.
* Supported printing ``TensorSSA`` value in ``cutlass.cute.print_tensor``
* Updated ``cute.gemm`` to support all dispatch patterns and improved checks for illegal inputs
* Introduced automatic kernel smem usage calculation for launch config.
* Introduced per op fast-math control for math ops(e.g. ``exp``, ``exp2``, ``log2``, ``log``)
* Introduced ``CopyReduceBulkTensorTileS2GOp`` in `tcgen05/copy.py <https://github.com/NVIDIA/cutlass/blob/main/python/CuTeDSL/cutlass/cute/nvgpu/tcgen05/copy.py>`_ to support TMA Reduce.


`4.1.0 <https://github.com/NVIDIA/cutlass/releases/tag/v4.1.0>`_ (2025-07-16)
==============================================================================

* for loop

  - Python built-in ``range`` now always generates codes and executes at runtime
  - ``cutlass.range`` is advanced ``range`` with kernel code level unrolling and pipelining control
  - Deprecated ``cutlass.range_dynamic``, please replace with ``range`` or ``cutlass.range``
  - **Experimental** Added ``pipelining`` control for compiler generated software pipeline code

* while/if

  - ``while``/``if`` now by default generates codes and executes at runtime unless ``cutlass.const_expr`` is specified for the predicate
  - Deprecated ``cutlass.dynamic_expr``, please remove it

* Rename mbarrier functions to reduce ambiguity
* Modify SyncObject API (``MbarrierArray``, ``NamedBarrier``, ``TmaStoreFence``) to match ``std::barrier``
* Change pipeline ``create`` function to take only keyword arguments, and make ``barrier_storage`` optional.
* Introduce ``cutlass.cute.arch.get_dyn_smem_size`` api to get runtime dynamic shared memory size.
* Various API Support for SM100 BlockScaled Gemm

  - Introduce BlockScaled MmaOps in `tcgen05/mma.py <https://github.com/NVIDIA/cutlass/blob/main/python/CuTeDSL/cutlass/cute/nvgpu/tcgen05/mma.py>`_, and provide a ``make_blockscaled_trivial_tiled_mma`` function in `blackwell_helpers.py <https://github.com/NVIDIA/cutlass/blob/main/python/CuTeDSL/cutlass/utils/blackwell_helpers.py>`_ to help construct a BlockScaled TiledMma.
  - Introduce S2T CopyOps in `tcgen05/copy.py <https://github.com/NVIDIA/cutlass/blob/main/python/CuTeDSL/cutlass/cute/nvgpu/tcgen05/copy.py>`_.
  - Introduce BlockScaled layout utilities in `blockscaled_layout.py <https://github.com/NVIDIA/cutlass/blob/main/python/CuTeDSL/cutlass/utils/blockscaled_layout.py>`_ for creating the required scale factor layouts in global memory, shared memory and tensor memory.

* ``cutlass.cute.compile`` now supports compilation options. Refer to `JIT compilation options <https://docs.nvidia.com/cutlass/latest/media/docs/pythonDSL/cute_dsl_general/dsl_jit_compilation_options.html>`_ for more details.
* ``cutlass.cute.testing.assert_`` now works for device JIT function. Specify ``--enable-device-assertions`` as compilation option to enable.
* ``cutlass.cute.make_tiled_copy`` is now deprecated. Please use ``cutlass.cute.make_tiled_copy_tv`` instead.
* Shared memory capacity query

  - Introduce ``cutlass.utils.get_smem_capacity_in_bytes`` for querying the shared memory capacity.
  - ``<arch>_utils.SMEM_CAPACITY["<arch_str>"]`` is now deprecated.

`4.0.0 <https://github.com/NVIDIA/cutlass/releases/tag/v4.0.0>`_ (2025-06-03)
==============================================================================

* Fixed API mismatch in class ``cute.runtime.Pointer``: change ``element_type`` to ``dtype`` to match ``typing.Pointer``
