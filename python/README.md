![ALT](/media/images/gemm-hierarchy-with-epilogue-no-labels.png "Complete CUDA GEMM decomposition")

# CUTLASS Python Interface
The CUTLASS Python interface enables one to compile and run CUTLASS operations from within Python.

```python
import cutlass
import numpy as np

plan = cutlass.op.Gemm(element=np.float16, layout=cutlass.LayoutType.RowMajor)
A, B, C, D = [np.ones((4096, 4096), dtype=np.float16) for i in range(4)]
plan.run(A, B, C, D)
```

**NOTE:** The CUTLASS Python interface is currently an experimental release. The API may change in the future.
We welcome feedback from the community.

## Overview
The CUTLASS Python interface aims to provide an ease-of-use interface for using CUTLASS via Python. Toward this goal,
the CUTLASS Python interface attempts to:

* Present high-level interfaces for operators that require only few parameters
* Select sensible default configurations for an operator given the parameters that have been specified
* Enumerate configurations for users that are known to work in a given setting
* Reduce the occurrence of C++ compile-time errors in favor of descriptive Python exceptions
* Make it easy to export CUTLASS kernels to framework extensions (e.g., PyTorch CUDA extensions)

### Non-goals
The CUTLASS Python interface does not intended to:

**Select optimal kernel configurations.**
As an ease-of-use interface, the default selections for operator parameters made by the CUTLASS Python interface may
not achieve the highest possible performance in all scenarios. Users wishing to achieve the highest performance possible
should consider profile different combinations of configuration parameters, or use a library such as [cuBLAS](https://developer.nvidia.com/cublas)
that contains heuristics for selecting kernels.

**Act as a fast container for CUTLASS kernels.**
The CUTLASS Python interface does not strive to minimize overhead in its Python functions surrounding the running of a kernel.
Those wishing to deploy a CUTLASS kernel should consider either using the C++ emitted by the Python interface directly, or using
one of the CUTLASS emitters for automatically creating a framework extension for the kernel (e.g., a PyTorch CUDA extension).

**Act as a Python-to-CUDA-kernel JIT compilation engine.**
The CUTLASS Python interface intends to enable one to use CUTLASS via Python. It can be used by frameworks for JIT compiling
Python to CUDA kernels, but does not set out to be such a framework.

### Comparison to PyCUTLASS
The CUTLASS Python interface builds atop CUTLASS's [PyCUTLASS](https://github.com/NVIDIA/cutlass/tree/v3.0.0/tools/library/scripts/pycutlass) library. PyCUTLASS enables
one to declare, compile, and run GEMMs, convolutions, and grouped GEMM operators with nearly the same configuration
space as CUTLASS's C++ interface. While this flexibility enables one to achieve the similar levels of functionality
as available in CUTLASS's C++ interface, it comes with the burden of needing to specify many configuration parameters
to operators -- similar to what one must do in specifying template parameters to operations in CUTLASS's C++ interface.

In contrast, the CUTLASS Python interface aims to provide a higher-level API for declaring, emitting, and compiling
kernels that does not require exhaustively defining template parameters.

#### Transitioning from PyCUTLASS
At present, existing PyCUTLASS functionality remains available via the CUTLASS Python interface. One can
continue to use PyCUTLASS by replacing references to the PyCUTLASS `cutlass` module with `cutlass_bindings`
and the PyCUTLASS `pycutlass` module with `cutlass.backend`.

For example, the following code using PyCUTLASS:
```python
import pycutlass
import cutlass

math_inst = pycutlass.MathInstruction(
    [1, 1, 1], cutlass.float32, cutlass.float32, cutlass.float32,
    cutlass.OpClass.Simt, pycutlass.MathOperation.multiply_add
)
```

can work with the Python interface via:
```python
import cutlass.backend as pycutlass
import cutlass_bindings

math_inst = pycutlass.MathInstruction(
    [1, 1, 1], cutlass_bindings.float32, cutlass_bindings.float32, cutlass_bindings.float32,
    cutlass_bindings.OpClass.Simt, pycutlass.MathOperation.multiply_add
)
```

**NOTE:** backwards compatibility of `cutlass.backend` with `pycutlass` will not be maintained moving forward.

## Current functionality
The CUTLASS Python interface currently supports the following operations:
* GEMMs
* GEMMs with fused elementwise epilogues (e.g., ReLU) (for pre-SM90 kernels)
* Stream K swizzling (for pre-SM90 kernels)
* Grouped GEMM (for pre-SM90 kernels)

## Getting started
We recommend using the CUTLASS Python interface via one of the Docker images located in the [docker](/python/docker) directory.

```bash
docker build -t cutlass-cuda12.1:latest -f docker/Dockerfile-cuda12.1-pytorch .
docker run --gpus all -it --rm cutlass-cuda12.1:latest
```

The CUTLASS Python interface has been tested with CUDA 11.8, 12.0, and 12.1 on Python 3.8.10 and 3.9.7.

### Optional environment variables
Prior to installing the CUTLASS Python interface, one may optionally set the following environment variables:
* `CUTLASS_PATH`: the path to the cloned CUTLASS repository
* `CUDA_INSTALL_PATH`: the path to the installation of CUDA

If these environment variables are not set, the installation process will infer them to be the following:
* `CUTLASS_PATH`: one directory level above the current directory (i.e., `$(pwd)/..`)
* `CUDA_INSTALL_PATH`: the directory holding `/bin/nvcc` for the first version of `nvcc` on `$PATH` (i.e., `which nvcc | awk -F'/bin/nvcc' '{print $1}'`)

**NOTE:** The version of `cuda-python` installed must match the CUDA version in `CUDA_INSTALL_PATH`.

### Installation
The CUTLASS Python interface can currently be installed via:
```bash
python setup.py develop --user
```
This will allow changes to the Python interface source to be reflected when using the Python interface.

We plan to add support for installing via `python setup.py install` in a future release.

## Examples
Jupyter notebook examples of using the CUTLASS Python interface are located in [examples/python](/examples/python).

To launch these notebooks from this directory, run:
```bash
jupyter-lab ../examples/python
```

## Building documentation
The CUTLASS Python interface uses [Sphinx](https://www.sphinx-doc.org/en/master/) for documentation.

Building the documentation requires additional packages. These can be installed via:
```bash
sudo apt-get install pandoc
pip install --upgrade Sphinx furo pandoc myst-parser sphinx-copybutton nbsphinx nbsphinx-link sphinx-inline-tabs
```

To build documentation, you must first have installed the CUTLASS Python interface via the
[installation instructions](#installation).

Documentation can then be built via the following commands:
```bash
sphinx-apidoc -o docs_src/source/ cutlass/ cutlass/backend*
cd docs_src
make html
mv _build/* ../docs
```

# Copyright

Copyright (c) 2023 - 2023 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
SPDX-License-Identifier: BSD-3-Clause

```
  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are met:

  1. Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer.

  2. Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.

  3. Neither the name of the copyright holder nor the names of its
  contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
  FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
  CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
```
