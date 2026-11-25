.. _quick_start:

Quick Start Guide
=======================

Compatibility Requirements
---------------------------------

CUTLASS DSL 4.9 supports **Linux** (x86_64 and aarch64) and
**Windows** (x86_64 and ARM64).

Supported Python versions are **3.10 - 3.14t**, excluding Python 3.10
on Windows ARM64.

The free-threaded build of Python 3.14 (``python3.14t``) is supported on an
experimental basis; see :ref:`dsl_threading` for what works and what does not.

CUTLASS DSL supports the same NVIDIA driver version as the corresponding `CUDA Toolkit <https://docs.nvidia.com/cuda/cuda-toolkit-release-notes/index.html>`_ 
(CUDA Toolkit 12.9 or CUDA Toolkit 13.4). Specifically, for 12.9, the driver version must be 575.51.03 or later.

Installation
-----------------------

To ensure compatibility with the examples and code on `GitHub <https://github.com/NVIDIA/cutlass/tree/main>`_,
use the `setup.sh <https://github.com/NVIDIA/cutlass/blob/main/python/CuTeDSL/setup.sh>`_ file from the corresponding commit in the repository.

.. code-block:: bash

   git clone https://github.com/NVIDIA/cutlass.git 

   # For CUDA Toolkit 12.9:
   ./cutlass/python/CuTeDSL/setup.sh --cu12

   # For CUDA Toolkit 13.x:
   ./cutlass/python/CuTeDSL/setup.sh --cu13

If you just want to try out the last known stable release of the CUTLASS DSL (may not be compatible with the latest examples and code), run:


.. code-block:: bash

   # For CUDA Toolkit 12.9:
   pip install nvidia-cutlass-dsl

   # For CUDA Toolkit 13.x:
   pip install "nvidia-cutlass-dsl[cu13]"

.. note::

   Windows on ARM does not support CUDA 12. Use the ``cu13`` extra
   in the command above to install the CUDA 13 libraries, which
   are not installed by default.


The ``nvidia-cutlass-dsl`` package and its CUDA libraries provide everything
needed to generate GPU kernels.
IKET profiling tools, including the ``run-iket`` command, are optional and
available on Linux x86_64 and aarch64 only. Install
``nvidia-cutlass-dsl[tools]`` (or ``nvidia-cutlass-dsl[cu13,tools]`` for CUDA 13)
to add the matching ``nvidia-cutlass-dsl-tools`` wheel. Device-side IKET
annotations remain available in the default DSL installation.

On Windows, omit the ``tools`` extra.

To install a preview release, install from `pypi.nvidia.com <https://pypi.nvidia.com>`_:

.. code-block:: bash

   # For CUDA Toolkit 12.9:
   pip install --pre nvidia-cutlass-dsl --extra-index-url https://pypi.nvidia.com

   # For CUDA Toolkit 13.x:
   pip install --pre "nvidia-cutlass-dsl[cu13]" --extra-index-url https://pypi.nvidia.com

Recommended Dependencies
---------------------------------

To run examples and begin development, we recommend installing:

.. code-block:: bash

   pip install torch jupyter mypy==1.19.1

.. note::

   To install PyTorch on Windows on ARM, follow the
   `official installation instructions <https://pytorch.org/get-started/additional-platforms/>`_.

Recommended Python environment variables for jupyter notebooks
--------------------------------------------------------------

We recommend setting the following environment variable when running jupyter notebooks.

.. code-block:: bash

   export PYTHONUNBUFFERED=1
