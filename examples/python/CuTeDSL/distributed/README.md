# CuTeDSL Distributed Examples

This directory contains distributed examples using CuTeDSL with NVSHMEM for multi-GPU communication. Currently, we do not support to use NVSHMEM for any device side copy/put/get impl, only use the host side setup and allocations.

## NVSHMEM Dependency

These examples require two components:

1. **NVSHMEM4Py** (`nvshmem4py-cu12` / `nvshmem4py-cu13`): A Python package that provides the official Python binding for NVIDIA's NVSHMEM. See the [NVSHMEM4Py Documentation](https://docs.nvidia.com/nvshmem/api/api/language_bindings/python/index.html).

2. **NVSHMEM Library** (`nvidia-nvshmem-cu12` / `nvidia-nvshmem-cu13`): The underlying native library that contains the actual NVSHMEM implementation.

### Overview

**NVSHMEM4Py** (`nvshmem4py-cu12` / `nvshmem4py-cu13`) is a Python binding library that provides a Pythonic interface to NVSHMEM functionality. In these examples, we use it primarily for:

- Allocating tensors that support peer-to-peer (P2P) communication across GPUs
- Allocating multicast (MC) tensors that can leverage `multimem` instructions for efficient collective operations

**nvidia-nvshmem** (`nvidia-nvshmem-cu12` / `nvidia-nvshmem-cu13`) is the underlying library that wraps NVSHMEM functions into dynamic libraries (`.so` files). NVSHMEM4Py dynamically loads and calls these libraries at runtime.

### Installation

For CUDA 12:
```bash
pip install nvshmem4py-cu12 nvidia-nvshmem-cu12
```

For CUDA 13:
```bash
pip install nvshmem4py-cu13 nvidia-nvshmem-cu13
```

> **Note:** `nvshmem4py` version >= 0.1.3 is recommended.

### Key APIs Used

We primarily use the following APIs from `nvshmem.core`:

| API | Description |
|-----|-------------|
| `nvshmem.core.tensor(shape, dtype)` | Allocates a symmetric tensor that supports P2P communication |
| `nvshmem.core.get_peer_tensor(tensor, pe)` | Returns a tensor handle for accessing the given tensor on a remote PE (processing element) |
| `nvshmem.core.get_multicast_tensor(tensor)` | Returns a tensor that can be accessed using `multimem` instructions for efficient multicast operations |
| `nvshmem.core.free_tensor(tensor)` | Explicitly frees the allocated symmetric memory |

### Memory Management

NVSHMEM requires **manual memory management**. Unlike PyTorch tensors that are garbage-collected automatically, NVSHMEM symmetric memory must be explicitly freed using `nvshmem.core.free_tensor()` to avoid memory leaks.

Example:
```python
import nvshmem.core

# init the environment
# refer to the torchrun_uid_init_bcast() in example

# Allocate symmetric tensor
local_tensor = nvshmem.core.tensor((M, N), dtype=torch.float32)

# Get peer tensors for P2P access
tensor_list = [nvshmem.core.get_peer_tensor(local_tensor, rank) for rank in range(world_size)]

# ... use tensors ...

# Explicitly free memory when done
for t in tensor_list:
    nvshmem.core.free_tensor(t)

# finalize the environment
# refer to the torchrun_finalize() in example

```

## Multimem Instructions

These examples demonstrate the use of NVIDIA's `multimem` PTX instructions for efficient multi-GPU collective operations. The `multimem` instructions operate on multicast (MC) addresses obtained via `nvshmem.core.get_multicast_tensor()`, enabling hardware-accelerated communication across multiple GPUs.

### Why Multimem is Fast: NVLS (NVLink SHARP)

The `multimem` instructions leverage **NVLS (NVLink SHARP)** technology to perform **in-network computation**. When multiple GPUs map the same symmetric memory region, `multimem` instructions can operate on a multicast address to perform hardware-accelerated reduction or broadcast operations directly in the NVLink/NVSwitch fabric, without requiring data to traverse to GPU memory first.

**Key benefits:**
- **In-network computation**: Reduction and broadcast operations happen in the NVSwitch hardware, not in GPU compute units
- **Reduced memory traffic**: Data is processed in-flight within the interconnect, minimizing HBM bandwidth consumption
- **Lower latency**: Single instruction replaces multiple loads/stores and arithmetic operations

### Instruction Categories

We use three types of `multimem` instructions in these examples:

#### 1. `multimem.ld_reduce` - Reduction

Reads data from a multicast address and returns the **reduced result** (e.g., sum) across all GPUs:

```
multimem.ld_reduce.sys.relaxed.global.add.v4.f32 {$0, $1, $2, $3}, [$4];
```

This instruction reads from a multicast address and performs a sum reduction (`.add`) across all GPUs that have mapped this address via NVLS.

**Accumulator Precision**: For lower-precision data types, you can specify a higher accumulator precision to improve numerical accuracy:
- **FP16 / BF16**: Can use FP32 accumulator (`.acc::f32`)
- **FP8 (E4M3 / E5M2)**: Can use FP16 accumulator (`.acc::f16`)

Example with FP16 using FP32 accumulator:
```
multimem.ld_reduce.sys.relaxed.global.add.acc::f32.v4.f16x2 {$0, $1, $2, $3}, [$4];
```

#### 2. `multimem.st` - Broadcast via Store

Stores data to a multicast address, which **broadcasts** the data to all participating GPUs:

```
multimem.st.sys.relaxed.global.v4.f32 [$1], {$2, $3, $4, $5};
```

This writes data to a multicast address, and the data becomes visible to all GPUs that have mapped this address via NVLS.

#### 3. `multimem.red` - Broadcast via Atomic Reduction

Performs an atomic reduction operation on a multicast address. This is commonly used for **signaling/synchronization** across GPUs:

```
multimem.red.release.sys.global.add.u32 [$0], 1;
```

This atomically adds a value to a multicast address. When used with synchronization patterns (e.g., spin locks), it enables efficient inter-GPU barriers where all GPUs can observe the updated value.

## Future Work

The `nvidia-nvshmem-cu12/cu13` packages include LLVM IR bitcode libraries that could potentially be integrated into CuTeDSL in the future. This would enable calling NVSHMEM functions directly from within CuTeDSL kernels, allowing for more fine-grained control over communication patterns at the kernel level.

## References

- [NVSHMEM4Py Documentation](https://docs.nvidia.com/nvshmem/api/api/language_bindings/python/index.html)
- [NVSHMEM API Reference](https://docs.nvidia.com/nvshmem/api/api/language_bindings/python/index.html)
- [multimem PTX instruction](https://docs.nvidia.com/cuda/parallel-thread-execution/index.html#data-movement-and-conversion-instructions-multimem)
