.. _cutlass_cuda:

CUDA Runtime
============

``cutlass.cuda`` provides host-side CUDA helpers for context setup, stream
management, memory copies, device queries, and loading or launching compiled
kernels.

These APIs are host runtime utilities. They are not jittable DSL operations and
should be used from Python host code, not from inside ``@cute.jit`` or
``@cute.kernel`` bodies.

Error-checking helpers and internal context-retain wrappers are intentionally
omitted from this page. They are used by the runtime implementation rather than
being part of the recommended ``cutlass.cuda`` user surface.

Context and Device
------------------

.. autoclass:: cutlass.cuda.DeviceInfo
   :members:
   :special-members: __init__

.. autofunction:: cutlass.cuda.initialize_cuda_context

.. autofunction:: cutlass.cuda.context_destroy

.. autofunction:: cutlass.cuda.get_device_info

.. autofunction:: cutlass.cuda.get_compute_capability_major_minor

.. autofunction:: cutlass.cuda.get_current_device

.. autofunction:: cutlass.cuda.get_device

.. autofunction:: cutlass.cuda.get_device_attribute

.. autofunction:: cutlass.cuda.get_driver_version

Streams
-------

.. autofunction:: cutlass.cuda.default_stream

.. autofunction:: cutlass.cuda.stream_create

.. autofunction:: cutlass.cuda.stream_destroy

.. autofunction:: cutlass.cuda.stream_sync

Memory
------

.. autofunction:: cutlass.cuda.allocate

.. autofunction:: cutlass.cuda.deallocate

.. autofunction:: cutlass.cuda.memcpy_h2d

.. autofunction:: cutlass.cuda.memcpy_d2h

Modules and Kernel Launch
-------------------------

.. autofunction:: cutlass.cuda.load_cubin_module

.. autofunction:: cutlass.cuda.load_cubin_module_data

.. autofunction:: cutlass.cuda.unload_cubin_module

.. autofunction:: cutlass.cuda.get_kernel_function

.. autofunction:: cutlass.cuda.load_library

.. autofunction:: cutlass.cuda.load_library_data

.. autofunction:: cutlass.cuda.load_library_from_file

.. autofunction:: cutlass.cuda.unload_library

.. autofunction:: cutlass.cuda.get_library_kernel

.. autofunction:: cutlass.cuda.get_function_from_kernel

.. autofunction:: cutlass.cuda.set_kernel_attribute

.. autofunction:: cutlass.cuda.launch_kernel
