.. _cutlass_cuda:

CUDA (Jittable)
===============

``cutlass.experimental.cuda`` provides CUDA descriptor helpers that can be used
from CUTLASS Python JIT code. The current public surface focuses on TensorMap
creation and metadata for TMA-based kernels.

TensorMap
---------

.. autoclass:: cutlass.experimental.cuda.TensorMap
   :members:
   :special-members: __init__

Descriptor Builders
-------------------

.. autofunction:: cutlass.experimental.cuda.create_tensor_map_tiled

.. autofunction:: cutlass.experimental.cuda.create_tensor_map_tiled_from_view

TensorMap Enums
---------------

.. autoclass:: cutlass.experimental.cuda.TensorMapDataFormat
   :members:

.. autoclass:: cutlass.experimental.cuda.TensorMapFloatOOBFill
   :members:

.. autoclass:: cutlass.experimental.cuda.TensorMapInterleave
   :members:

.. autoclass:: cutlass.experimental.cuda.TensorMapL2Promotion
   :members:

.. autoclass:: cutlass.experimental.cuda.TensorMapSwizzle
   :members:
