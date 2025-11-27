![ALT](/media/images/gemm-hierarchy-with-epilogue-no-labels.png "Complete Intel Xe GEMM decomposition")

# Python packages associated with SYCL*TLA (with CUTLASS compatibility)

This directory contains Python packages that are associated with SYCL*TLA (Intel Xe CUTLASS backend):

* `cutlass_cppgen`: the SYCL*TLA Python interface, which enables one to compile and run CUTLASS kernels on Intel GPUs from within Python. Note that this was previously named `cutlass`, but was renamed to disambiguate with the CuTe Python DSL.
* `cutlass_library`: utilities used for enumerating and emitting C++ code for CUTLASS kernels targeting Intel Xe architecture

## SYCL*TLA Python Interface

The SYCL*TLA Python interface enables one to compile and run CUTLASS operations on Intel GPUs from within Python.

```python
import cutlass_cppgen as cutlass
import numpy as np

plan = cutlass.op.Gemm(element=np.float16, layout=cutlass.LayoutType.RowMajor)
A, B, C, D = [np.ones((1024, 1024), dtype=np.float16) for i in range(4)]
plan.run(A, B, C, D)
```

### Overview

The SYCL*TLA Python interface prioritizes ease of use for Intel GPU development.
It has the following features that support this goal.

* It presents high-level interfaces for operators targeting Intel Xe architecture, that require only few parameters.
* It selects sensible default configurations for an operator given the parameters that have been specified.
* It enumerates configurations for users that are known to work on Intel GPUs in a given setting.
* It favors emitting descriptive Python run-time exceptions instead of C++ compile-time errors, where possible.
* It simplifies exporting CUTLASS kernels for Intel GPUs to framework extensions (e.g., PyTorch XPU extensions).

#### Non-goals
The SYCL*TLA Python interface does not intend to:

1. select optimal kernel configurations,
2. act as a fast container for CUTLASS kernels, or
3. act as a Python-to-SYCL-kernel just-in-time (JIT) compilation engine.

Regarding selection of optimal kernel configurations,
the interface favors ease-of-use over maximum configurability.
Thus, its default selections for operator parameters may
not achieve the highest possible performance in all scenarios. Users wishing to achieve the highest performance possible should either

Regarding acting as a fast container for CUTLASS kernels:
the interface does not strive to minimize overhead in its Python functions surrounding the running of a kernel.
Those wishing to deploy a CUTLASS kernel should either

* use the C++ emitted by the Python interface directly, or
* use one of the CUTLASS emitters for automatically creating a framework extension for the kernel (e.g., a PyTorch XPU extension).

Regarding acting as a Python-to-SYCL-kernel JIT compilation engine:
the interface enables use of CUTLASS on Intel GPUs in Python code.
It can be used by frameworks for JIT compiling
Python to SYCL kernels, but does not set out to be such a framework.

#### Comparison to PyCUTLASS

The CUTLASS Python interface builds atop CUTLASS's [PyCUTLASS](https://github.com/NVIDIA/cutlass/tree/v3.0.0/tools/library/scripts/pycutlass) library. PyCUTLASS enables
one to declare, compile, and run GEMMs, convolutions, and grouped GEMM operators with nearly the same configuration
space as CUTLASS's C++ interface. While this flexibility enables one to achieve the similar levels of functionality
as available in CUTLASS's C++ interface, it comes with the burden of needing to specify many configuration parameters
to operators -- similar to what one must do in specifying template parameters to operations in CUTLASS's C++ interface.

In contrast, the CUTLASS Python interface aims to provide a higher-level API for declaring, emitting, and compiling
kernels that does not require exhaustively defining template parameters.

### Current functionality with python interface
The SYCL*TLA Python interface currently supports the following operations on Intel GPUs:
* GEMMs with Intel Xe DPAS (Dot Product Accumulate Systolic) operations
* GEMMs with fused elementwise epilogues (e.g., ReLU, GELU)


### Getting started
We recommend using the SYCL*TLA Python interface with an Intel oneAPI environment and Intel GPU drivers:

```bash
# Install Intel oneAPI toolkit and GPU drivers
# Refer to Intel's documentation for your specific system
```

#### Prerequisites

Before installing the SYCL*TLA Python interface, ensure you have the following:

**System Requirements:**
* Intel GPU (Intel Arc, Intel Data Center GPU Max series, or compatible Intel Xe architecture)
* Intel GPU drivers (latest recommended)
* Intel oneAPI DPC++ compiler
* Python 3.12 (recommended)

**Required packages:**
* `dpctl`: Intel's Data Parallel Control library for Python
* `torch` with Intel XPU support (if using PyTorch integration)

The SYCL*TLA Python interface has been tested with Intel oneAPI 2024.2+ and Python 3.12 on Intel Xe GPUs.

#### Environment setup

Set up the required environment variables:

```bash
# Source Intel oneAPI environment
source /opt/intel/oneapi/setvars.sh

# Set SYCL environment variables
export CUTLASS_USE_SYCL=1
export ONEAPI_DEVICE_SELECTOR=level_zero:gpu

# Verify Intel GPU is detected
sycl-ls
```

#### Optional environment variables

Prior to installing the SYCL*TLA Python interface, one may optionally set the following environment variables:

* `CUTLASS_PATH`: the path to the cloned SYCL*TLA repository
* `ONEAPI_ROOT`: the path to the Intel oneAPI installation (typically `/opt/intel/oneapi`)

If these environment variables are not set, the installation process will infer them to be the following:

* `CUTLASS_PATH`: either one directory level above the current directory (i.e., `$(pwd)/..`) if installed locally or in the `source` directory of the location in which `cutlass_library` was installed
* `ONEAPI_ROOT`: the default Intel oneAPI installation path

#### Installation

Stable releases of the SYCL*TLA Python interface are available via the `sycl-tla` PyPI package.
```bash
pip install sycl-tla
```

You will also need to install the required dependencies:

```bash
# Install dpctl (Intel Data Parallel Control library)
pip install dpctl 

# Install dpctl for Pytorch 2.9 
pip install dpctl intel-cmplr-lib-rt==2025.2.1

# Install Intel PyTorch XPU support (optional, for PyTorch integration)
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/test/xpu
```

The SYCL*TLA Python interface can also be installed from source by navigating to the root of the SYCL*TLA directory and performing
```bash
pip install .
```

If you would like to be able to make changes to the SYCL*TLA Python interface and have them reflected when using the interface, perform:
```bash
pip install -e .
```

To test that your installation was successful, you can run:
```python
import cutlass_cppgen as cutlass
import numpy as np

plan = cutlass.op.Gemm(element=np.float16, layout=cutlass.LayoutType.RowMajor)
A, B, C, D = [np.ones((128, 128), dtype=np.float16) for i in range(4)]
plan.run(A, B, C, D)
```

### Deep learning framework XPU extensions
The SYCL*TLA Python interface provides utilities for exporting a CUTLASS kernel to deep learning framework Intel XPU extensions. Currently, PyTorch XPU extensions can be exported, but a similar pattern could be applied for other frameworks as well.

Currently, the following operations can be exported to a PyTorch XPU extension:
* GEMM for Intel Xe


## SYCL*TLA library package (with CUTLASS compatibility)

[cutlass_library](/python/cutlass_library) contains utilities for enumerating and emitting CUTLASS C++ kernels for Intel Xe architecture.
It is used by the SYCL*TLA CMake system to construct a library of kernels that can be profiled using the CUTLASS profiler on Intel GPUs.

To install the `cutlass_library` package, run
```bash
python setup_library.py develop --user
```

Alternatively, `cutlass_library` will automatically be installed if you install the SYCL*TLA Python interface package.

You can also use the [generator.py](/python/cutlass_library/generator.py) script directly without installing the module.

# Copyright

Copyright (c) 2023 - 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
Copyright (c) 2024 - 2025 Intel Corporation. All rights reserved.
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
