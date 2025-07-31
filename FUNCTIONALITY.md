# Changelog for CuTe DSL API changes

## [4.1.0](https://github.com/NVIDIA/cutlass/releases/tag/v4.1.0) (2025-07-16)

  * for loop
      - Python built-in ``range`` now always generates IR and executes at runtime
      - ``cutlass.range`` is advanced ``range`` with IR level unrolling and pipelining control
      - Deprecated ``cutlass.range_dynamic``, please replace with ``range`` or ``cutlass.range``
      - **Experimental** Added ``pipelining`` control for compiler generated software pipeline code
  * while/if
      - ``while``/``if`` now by default generates IR and executes at runtime unless ``cutlass.const_expr`` is specified for the predicate
      - Deprecated ``cutlass.dynamic_expr``, please remove it
  * Rename mbarrier functions to reduce ambiguity
  * Modify SyncObject API (`MbarrierArray`, `NamedBarrier`, `TmaStoreFence`) to match `std::barrier`
  * Change pipeline `create` function to take only keyword arguments, and make `barrier_storage` optional.
  * Introduce `cutlass.cute.arch.get_dyn_smem_size` api to get runtime dynamic shared memory size.
  * Various API Support for SM100 BlockScaled Gemm
    - Introduce BlockScaled MmaOps in [tcgen05/mma.py]([https://github.com/NVIDIA/cutlass/blob/main/python/CuTeDSL/cutlass/cute/nvgpu/tcgen05/mma.py]), and provide a `make_blockscaled_trivial_tiled_mma` function in [blackwell_helpers.py](https://github.com/NVIDIA/cutlass/blob/main/python/CuTeDSL/cutlass/utils/blackwell_helpers.py) to help construct a BlockScaled TiledMma.
    - Introduce S2T CopyOps in [tcgen05/copy.py](https://github.com/NVIDIA/cutlass/blob/main/python/CuTeDSL/cutlass/cute/nvgpu/tcgen05/copy.py).
    - Introduce BlockScaled layout utilities in [blockscaled_layout.py](https://github.com/NVIDIA/cutlass/blob/main/python/CuTeDSL/cutlass/utils/blockscaled_layout.py) for creating the required scale factor layouts in global memory, shared memory and tensor memory.
  * `cutlass.cute.compile` now supports compilation options. Refer to [JIT compilation options](https://docs.nvidia.com/cutlass/media/docs/pythonDSL/cute_dsl_general/dsl_jit_compilation_options.html) for more details.
  * `cutlass.cute.testing.assert_` now works for device JIT function. Specify `--enable-device-assertions` as compilation option to enable.
  * `cutlass.cute.make_tiled_copy` is now deprecated. Please use `cutlass.cute.make_tiled_copy_tv` instead.
  * Shared memory capacity query
      - Introduce `cutlass.utils.get_smem_capacity_in_bytes` for querying the shared memory capacity.
      - `<arch>_utils.SMEM_CAPACITY["<arch_str>"]` is now deprecated.

## [4.0.0](https://github.com/NVIDIA/cutlass/releases/tag/v4.0.0) (2025-06-03)

  * Fixed API mismatch in class ``cute.runtime.Pointer``: change ``element_type`` to ``dtype`` to match ``typing.Pointer``
