.. _quick_start:

Quick Start Guide
=======================

Compatibility Requirements
---------------------------------

The CUTLASS DSL 4.4 release currently supports **Linux** and **Python 3.10 - 3.14** only.

Only Linux x86_64 and aarch64 are supported. Additional platform support will be added in future releases.

CUTLASS DSL supports the same NVIDIA driver version as the corresponding `CUDA Toolkit <https://docs.nvidia.com/cuda/cuda-toolkit-release-notes/index.html>`_ 
(CUDA Toolkit 12.9 or CUDA Toolkit 13.1). Specifically, for 12.9, the driver version must be 575.51.03 or later.

Installation
-----------------------

To ensure compatibility with the examples and code on `GitHub <https://github.com/NVIDIA/cutlass/tree/main>`_,
use the `setup.sh <https://github.com/NVIDIA/cutlass/blob/main/python/CuTeDSL/setup.sh>`_ file from the corresponding commit in the repository.

.. code-block:: bash

   git clone https://github.com/NVIDIA/cutlass.git 

   # For CUDA Toolkit 12.9:
   ./cutlass/python/CuTeDSL/setup.sh --cu12

   # For CUDA Toolkit 13.1:
   ./cutlass/python/CuTeDSL/setup.sh --cu13

If you just want to try out the last known stable release of the CUTLASS DSL (may not be compatible with the latest examples and code), run:


.. code-block:: bash

   # For CUDA Toolkit 12.9:
   pip install nvidia-cutlass-dsl

   # For CUDA Toolkit 13.1:
   pip install "nvidia-cutlass-dsl[cu13]"


The ``nvidia-cutlass-dsl`` wheel includes everything needed to generate GPU kernels.

Recommended Dependencies
---------------------------------

To run examples and begin development, we recommend installing:

.. code-block:: bash

   pip install torch jupyter mypy==1.19.1

Recommended Python environment variables for jupyter notebooks
--------------------------------------------------------------

We recommend setting the following environment variable when running jupyter notebooks.

.. code-block:: bash

   export PYTHONUNBUFFERED=1
