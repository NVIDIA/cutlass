.. _cute_arch:

arch
====

The ``cute.arch`` module provides lightweight wrappers for NVVM Operation builders which implement CUDA built-in 
device functions such as ``thread_idx``. It integrates seamlessly with CuTe DSL types.

These wrappers enable source location tracking through the ``@dsl_user_op``
decorator. The module includes the following functionality:

- Core CUDA built-in functions such as ``thread_idx``, ``warp_idx``, ``block_dim``, ``grid_dim``, ``cluster_dim``, and related functions
- Memory barrier management functions including ``mbarrier_init``, ``mbarrier_arrive``, ``mbarrier_wait``, and associated operations  
- Low-level shared memory (SMEM) management capabilities, with ``SmemAllocator`` as the recommended interface
- Low-level tensor memory (TMEM) management capabilities, with ``TmemAllocator`` as the recommended interface

API documentation
-----------------

.. automodule:: cutlass.cute.arch
   :members:
   :undoc-members:
   :show-inheritance:
   :special-members: __init__
   :private-members:
