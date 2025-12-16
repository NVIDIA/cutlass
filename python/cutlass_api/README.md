# CUTLASS API

**NOTE: This is an experimental/early-access version of the CUTLASS API. All APIs, names, and paths are subject to change.**

The CUTLASS API provides high-level, universal interfaces to discover, compile,
 and execute GEMMs (including grouped GEMMs and scaled GEMMs) targeting NVIDIA GPUs.
It allows GEMM kernels written in different DSLs to be integrated and discovered under
a uniform API.

```python
import cutlass_api
import torch

A, B, out = (torch.randn(128, 128, device="cuda", dtype=torch.float16) for _ in range(3))

# Create arguments for the GEMM operation
args = cutlass_api.arguments.GemmArguments(A, B, out, accumulator_type=torch.float32)

# Query for kernels that support our provided arguments on SM100
kernels = cutlass_api.get_kernels(args, cc=100)

# JIT compile and execute one of the returned kernels
kernels[0].run(args)
```

## Deep dive

To learn more about the API, follow the in-depth tutorials in the [examples directory](./examples).

## Directory structure
* [cutlass_api](./cutlass_api/): source for the CUTLASS API
* [examples](./examples/): examples of using the CUTLASS API
* [test](./test/): tests of the CUTLASS API

## Installation
There is currently no wheel for the CUTLASS API.
Install in editable mode from the `python/cutlass_api` directory of the CUTLASS repository:
```bash
# From the root of this README file

# Install required dependencies
pip install -e .

# Install required dependencies for use with torch
pip install -e ".[torch]"

# To install all dependencies to develop, run tests, etc.
pip install -e ".[dev]"
```

## Running examples and tests
[Tests](./test/) use [pytest](https://docs.pytest.org/en/stable/). An example of running a test is:
```bash
pytest test/integration/test_gemm.py
```

[Examples](./examples/) are [Jupyter notebooks](https://jupyter.org/). They can be launched via:
```bash
cd examples
jupyter notebook
```

## Requirements, compatibility, and current support
Please see [pyproject.toml](pyproject.toml) for dependencies.

**Compatibility:** CUTLASS API has the same compatibility requirements as the CUTLASS project.
See CUTLASS's [Compatibility section](https://github.com/NVIDIA/cutlass?tab=readme-ov-file#compatibility).

### Current support

* Dense GEMM: `out = A @ B`
    - Compute capabilities: 100, 103
    - Input precisions (A and B must be of same type): F16, BF16, TF32, INT8
    - Output precisions: F32, F16, BF16, INT32
    - Epilogue operations:
        - Auxiliary load of tensors equal in rank and shape of `out`
        - Auxiliary store of tensors equal in rank and shape of `out`
        - Auxiliary load of scalar
        - Tensor-tensor elementwise or tensor-scalar addition, multiplication, subtraction, division
        - Elementwise tensor exponent, relu, sigmoid, tanh

* Planned additions
    * Block-scaled GEMMs
    * Grouped GEMMs
    * Additional epilogue operations
        * Reductions
        * Row/column broadcasts
    * SM90 kernels
    * Convolutions
