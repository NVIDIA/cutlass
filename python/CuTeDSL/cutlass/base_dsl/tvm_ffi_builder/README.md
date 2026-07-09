# TVM FFI DSL Bridge

This folder implements a binding generator that
can be used by DSL compilers to generate functions in tvm-ffi ABI.

- Interface specification: we provide a spec namespace that allows
  developers to define the interface of the function, with possibly shape and type constraints.
- Constraint checking: we will generate MLIR functions that exposes the tvm-ffi ABI convention
  checks the overall constraints and reads all related variable fields.
- User defined calling convention: user can provide a `CallProvider` instance
  that takes `CallContext` and emit a call to internal DSL function.

## Basic Example: Mixed Parameters

```python

from cutlass.base_dsl.tvm_ffi_builder import (
  spec, attach_ffi_func, ExecutionEngine, NopProvider
)
from cutlass._mlir import ir
import tvm_ffi
import numpy as np

# Define parameters: int + tensor with symbolic shape
n = spec.Var("n", "int32")
params = [
    spec.Var("batch_size", "int32"),           # Integer parameter
    spec.Tensor("data", [n, 128], "float32"),  # Tensor with symbolic first dimension
]

# Generate function
# Function signature: process_data(batch_size: int32, data: Tensor([n, 128], float32))
with ir.Context(), ir.Location.unknown():
    module = ir.Module.create()
    attach_ffi_func(module, "process_data", params, NopProvider())

    # Execute
    engine = ExecutionEngine(module, opt_level=2, shared_libs=[])
    func = tvm_ffi.Function.__from_mlir_packed_safe_call__(
      engine.raw_lookup("__tvm_ffi_process_data")
    )

    # Call function
    data = tvm_ffi.from_dlpack(np.zeros((10, 128), dtype=np.float32))
    func(42, data)  # batch_size=42, data shape=[10, 128]
```

## Matrix Multiplication Example

```python
# Define matrix multiplication with automatic constraint validation
n = spec.Var("n", "int32")
m = spec.Var("m", "int32")
k = spec.Var("k", "int32")

with spec.DefaultConfig(device="cpu"):
  params = [
      spec.Tensor("A", [n, k], "float32"),  # A: n×k
      spec.Tensor("B", [k, m], "float32"),  # B: k×m
      spec.Tensor("C", [n, m], "float32"),  # C: n×m
  ]

# Generate function
# Function signature: matmul(A: Tensor([n, k], float32), B: Tensor([k, m], float32), C: Tensor([n, m], float32))
with ir.Context(), ir.Location.unknown():
    module = ir.Module.create()
    attach_ffi_func(module, "matmul", params, NopProvider())

    # Execute
    engine = ExecutionEngine(module, opt_level=2, shared_libs=[])
    func = tvm_ffi.Function.__from_mlir_packed_safe_call__(
      engine.raw_lookup("__tvm_ffi_matmul")
    )

    # Valid call: 2×3 × 3×4 = 2×4
    A = tvm_ffi.from_dlpack(np.zeros((2, 3), dtype=np.float32))
    B = tvm_ffi.from_dlpack(np.zeros((3, 4), dtype=np.float32))
    C = tvm_ffi.from_dlpack(np.zeros((2, 4), dtype=np.float32))
    func(A, B, C)  # ✅ Valid dimensions

    # Invalid call: dimension mismatch
    A_wrong = tvm_ffi.from_dlpack(np.zeros((2, 4), dtype=np.float32))  # Wrong: 2×4
    func(A_wrong, B, C)  # ❌ Error: A[1]=4 != B[0]=3
```
