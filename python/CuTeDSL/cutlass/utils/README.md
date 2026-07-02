# Utilities for Kernel Authoring

> **Experimental Notice**: The utilities in this folder are experimental and subject to breaking changes. APIs may evolve as we refine the design based on user feedback and new hardware features.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Block-Level Copy Utilities](#block-level-copy-utilities-blockpy)
  - [Block Copy Overview](#block-copy-overview)
  - [`block_copy`](#block_copy)
  - [TMA Copy](#tma-copy)
  - [Compiler-Driven TMA Multicast IR rewriting](#compiler-driven-tma-multicast-ir-rewriting)
  - [S2T Copy (SMEM to TMEM)](#s2t-copy-smem-to-tmem)
- [TmaInfo Container](#tmainfo-container)
- [Tensor Memory Allocator](#tensor-memory-allocator-tmem_allocatorpy)
  - [TMEM Allocator Overview](#tmem-allocator-overview)
  - [`TmemAllocator`](#tmemallocator)
  - [`TmemBufferPool`](#tmembufferpool)
  - [Utility Functions](#utility-functions)
- [Other Utilities](#other-utilities)
- [When to Use What](#when-to-use-what)
- [Examples](#examples)
- [Troubleshooting](#troubleshooting)
- [Limitations](#limitations)

---

## Overview

This folder provides high-level building blocks that simplify common patterns in GPU kernel development with CuTe DSL. These utilities handle boilerplate code for you, letting you focus on your kernel's core logic.

**Key utilities include:**

| Utility | File | Purpose |
|---------|------|---------|
| Block-level copy | [`block.py`](./block.py) | Simplified tile copies (TMA, S2T) without manual partitioning |
| TMEM allocator | [`tmem_allocator.py`](./tmem_allocator.py) | Tensor memory management for Blackwell GPUs |
| Static tile scheduler | [`static_persistent_tile_scheduler.py`](./static_persistent_tile_scheduler.py) | Persistent kernel scheduling with static work distribution |
| Dynamic tile scheduler | [`dynamic_persistent_tile_scheduler.py`](./dynamic_persistent_tile_scheduler.py) | Persistent kernel scheduling with dynamic work stealing |
| Grouped GEMM helpers | [`grouped_gemm_tile_scheduler_helper.py`](./grouped_gemm_tile_scheduler_helper.py), [`tensormap_manager.py`](./tensormap_manager.py) | Utilities for batched/grouped GEMM kernels |

---

## Prerequisites

### Hardware Requirements

- **Hopper GPUs (SM90)**: TMA-based `block_copy` operations
- **Blackwell GPUs (SM100+)**: Full support including TMEM allocation and S2T copies

### Software Requirements

```python
import cutlass
import cutlass.cute as cute
from cutlass import utils, pipeline
from cutlass.cute.nvgpu import cpasync, tcgen05
```

---

## Quick Start

Here's a minimal example showing how to use `block_copy` for TMA loads in a GEMM mainloop:

```python
import cutlass
import cutlass.cute as cute
from cutlass import utils

# Inside your kernel function...

# 1. Create TMA atoms for A and B operands (configured during kernel setup)
# tma_atom_a, tma_atom_b = ...  # Your TMA copy atoms

# 2. Get your tiles from global and shared memory
# gA, sA = ...  # Global and shared memory tensors for A
# gB, sB = ...  # Global and shared memory tensors for B

# 3. Load tiles using block_copy (much simpler than manual partitioning!)
for k_tile_idx in range(num_k_tiles):
    # Acquire pipeline stage
    pipeline_state = mainloop_pipeline.producer_acquire(producer_state)

    # TMA load A tile: group_modes makes the first mode represent the TMATile
    utils.block_copy(
        tma_atom_a,
        cute.group_modes(gA[(None, None, k_tile_idx)], 0, 2),
        cute.group_modes(sA[(None, None, producer_state.index)], 0, 2),
        tma_bar_ptr=pipeline_state.barrier,
    )

    # TMA load B tile
    utils.block_copy(
        tma_atom_b,
        cute.group_modes(gB[(None, None, k_tile_idx)], 0, 2),
        cute.group_modes(sB[(None, None, producer_state.index)], 0, 2),
        tma_bar_ptr=pipeline_state.barrier,
    )

    mainloop_pipeline.producer_commit(producer_state)
    producer_state.advance()
```

For complete working examples, see the [Examples](#examples) section.

---

## Block-Level Copy Utilities (`block.py`)

### Block Copy Overview

The block API provides a simplified interface for tile-level copy operations. Instead of manually:
1. Computing CTA coordinates
2. Calling partitioning functions
3. Handling copy masks
4. Invoking `cute.copy`

You can use `block_copy` to perform all of this in a single call.

**Benefits:**
- Works directly on tile-shaped layouts (e.g., `(TILE_M, TILE_K)` for A, `(TILE_N, TILE_K)` for B)
- Integrates with TMA pipelines and cluster multicast on Hopper/Blackwell
- Handles compiler-driven IR rewriting for TMA multicast automatically

### `block_copy`

```python
def block_copy(
    tiled_copy: TiledCopy,
    src: Tensor,
    dst: Tensor,
    *,
    tma_bar_ptr=None,      # Required for TMA loads (G2S)
    tma_multicast=None,    # Optional: enables compiler-driven multicast
    **kwargs,
) -> None
```

#### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `tiled_copy` | `TiledCopy` | Yes | The copy atom configured for your use case |
| `src` | `Tensor` | Yes | Source tensor (must have TMATile as first mode for TMA) |
| `dst` | `Tensor` | Yes | Destination tensor (must have TMATile as first mode for TMA) |
| `tma_bar_ptr` | `Pointer` | For G2S | TMA barrier pointer (required for global-to-shared loads) |
| `tma_multicast` | `dict` | No | Configuration for compiler-driven TMA multicast |

#### What `block_copy` Handles For You

**For TMA copies:**
- Calls `tma_partition()` with default CTA coordinates
- Applies `filter_zeros()` to remove layout padding
- Determines copy direction from the copy op type
- Passes through `tma_multicast` and `tma_bar_ptr` arguments

**For S2T copies:**
- Filters zeros from source and destination tensors
- Gets thread copy slice (using thread 0)
- Partitions source and destination
- Creates SMEM descriptor tensor automatically

#### Supported Copy Kinds

| Copy Kind | Copy Op | Description |
|-----------|---------|-------------|
| TMA G2S | `CopyBulkTensorTileG2SOp` | Global to shared memory via TMA |
| TMA G2S Multicast | `CopyBulkTensorTileG2SMulticastOp` | G2S with cluster multicast |
| TMA S2G | TMA store ops | Shared to global memory via TMA |
| S2T | `tcgen05.Cp*Op` | Shared memory to tensor memory (Blackwell) |

### TMA Copy

For TMA-based copies, tensors must have their **first mode representing the TMATile**. Use `group_modes` to prepare your tensors:

```python
# Given a rank-2 tile tensor with layout (TILE_M, TILE_N)
src_grouped = cute.group_modes(src_tile, 0, 2)  # Now has layout (TMATile,)
dst_grouped = cute.group_modes(dst_tile, 0, 2)  # Now has layout (TMATile,)

# TMA load (Global → Shared) - requires barrier pointer
utils.block_copy(
    tma_atom,
    src_grouped,
    dst_grouped,
    tma_bar_ptr=barrier_ptr,  # Required!
)

# TMA store (Shared → Global) - no barrier needed
utils.block_copy(
    tma_atom_store,
    smem_grouped,
    gmem_grouped,
)
```

### Compiler-Driven TMA Multicast IR rewriting

For kernels using 2D clusters (multiple CTAs cooperating), you can enable **compiler-driven TMA multicast** to broadcast data efficiently across the cluster. The compiler automatically:
- Updates the CopyOp to its multicast version
- Calculates the multicast mask
- Partitions tensors considering multicast effects

#### `tma_multicast` Configuration

| Key | Type | Required | Description |
|-----|------|----------|-------------|
| `cluster_shape` | `tuple[int, int]` | Yes | 2D cluster shape `(cluster_m, cluster_n)` |
| `multicast_dim` | `"M"` or `"N"` | Yes | Which dimension to multicast along |
| `use_2cta_mma_inst` | `bool` | No | Use 2CTA MMA instructions (default: `False`) |

**Multicast dimension explained:**
- `"M"`: CTAs along the M dimension share this data (use for **A operand** in GEMM, which has shape `(M, K)`)
- `"N"`: CTAs along the N dimension share this data (use for **B operand** in GEMM, which has shape `(N, K)`)

#### Example: TMA Multicast with 2x1 Cluster

```python
cluster_shape_m, cluster_shape_n = 2, 1

# tma_atom_a is obtained from TMA descriptor setup (e.g., tma_info.atom)
# group_modes(tensor, 0, 2) collapses modes [0,1] into a single TMATile mode
# This transforms shape (TILE_M, TILE_K) into (TMATile,)

# Load A with multicast along M dimension
# A has shape (M, K), so CTAs along M share the same A tile
utils.block_copy(
    tma_atom_a,
    cute.group_modes(gA[(None, None, k_tile_idx)], 0, 2),  # Slice then group
    cute.group_modes(sA[(None, None, stage_idx)], 0, 2),
    tma_multicast={
        "cluster_shape": (cluster_shape_m, cluster_shape_n),
        "multicast_dim": "M",  # A operand uses M dimension
        "use_2cta_mma_inst": True,
    },
    tma_bar_ptr=barrier_ptr,
)

# Load B with multicast along N dimension
# B has shape (N, K), so CTAs along N share the same B tile
utils.block_copy(
    tma_atom_b,
    cute.group_modes(gB[(None, None, k_tile_idx)], 0, 2),
    cute.group_modes(sB[(None, None, stage_idx)], 0, 2),
    tma_multicast={
        "cluster_shape": (cluster_shape_m, cluster_shape_n),
        "multicast_dim": "N",  # B operand uses N dimension
        "use_2cta_mma_inst": True,
    },
    tma_bar_ptr=barrier_ptr,
)
```

> **Important**: When using `tma_multicast`, you still need to configure the pipeline's arrive count correctly to account for the reduced number of TMA producers.

### S2T Copy (SMEM to TMEM)

On Blackwell GPUs, you can copy data from shared memory to tensor memory (TMEM) using S2T copy atoms:

```python
# S2T copy (SMEM to TMEM) - Blackwell only
# Note: Unlike TMA copies, S2T does NOT require group_modes

# Create S2T copy atom with appropriate operation and CTA group
copy_atom_s2t = cute.make_copy_atom(
    tcgen05.Cp4x32x128bOp(tcgen05.CtaGroup.ONE),  # CtaGroup.TWO for 2-CTA MMA
    sf_dtype,
)

# Copy directly without group_modes
utils.block_copy(copy_atom_s2t, smem_tensor, tmem_tensor)
```

The function automatically handles filtering, partitioning, and SMEM descriptor creation.

---

## TmaInfo Container

The `TmaInfo` class is a container that bundles a TMA Copy Atom with its associated SMEM layout and TMA tensor. It is returned by the TMA atom creation functions:

- `make_tiled_tma_atom()` - General-purpose TMA atom creation
- `make_tiled_tma_atom_A()` - TMA atom for A operand (MK projections) in tcgen05 MMAs
- `make_tiled_tma_atom_B()` - TMA atom for B operand (NK projections) in tcgen05 MMAs

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `atom` | `CopyAtom` | The TMA Copy Atom for use with copy operations |
| `tma_tensor` | `Tensor` | TMA tensor that maps logical GMEM coordinates to TMA-consumable coordinates |
| `smem_layout` | `Layout` | The SMEM layout used to construct the TMA descriptor can be either staged or non-staged |

### Backward Compatibility

`TmaInfo` supports tuple unpacking for backward compatibility with code that expects a `(atom, tma_tensor)` tuple:

```python
# Legacy style: tuple unpacking
atom, tma_tensor = make_tiled_tma_atom(op, gmem_tensor, smem_layout, cta_tiler)

# New style: access via container (recommended)
tma_info = make_tiled_tma_atom(op, gmem_tensor, smem_layout_staged, cta_tiler)
atom = tma_info.atom
tma_tensor = tma_info.tma_tensor
smem_layout_staged = tma_info.smem_layout  # Only available via container
```

### Usage Example

```python
from cutlass.cute.nvgpu import cpasync

# Create TMA atom using make_tiled_tma_atom
tma_info = cpasync.make_tiled_tma_atom(
    cpasync.CopyBulkTensorTileG2SOp(),
    gmem_tensor,
    smem_layout_staged,
    cta_tiler,
)

# Access the Copy Atom for use with block_copy
utils.block_copy(
    tma_info.atom,
    cute.group_modes(gA[(None, None, k_tile_idx)], 0, 2),
    cute.group_modes(sA[(None, None, stage_idx)], 0, 2),
    tma_bar_ptr=barrier_ptr,
)

# Access the SMEM layout if needed (e.g., for verification or debugging)
print(f"SMEM layout: {tma_info.smem_layout}")
```

---

## Tensor Memory Allocator (`tmem_allocator.py`)

### TMEM Allocator Overview

Blackwell GPUs (SM100+) introduce **Tensor Memory (TMEM)**, a specialized memory for accumulator storage in matrix operations. The TMEM allocator utilities help you:

1. **Allocate** TMEM columns from the allocator warp
2. **Synchronize** across warps before using the allocated memory
3. **Sub-allocate** regions for different tensors without manual offset calculations
4. **Deallocate** TMEM when done (with 2-CTA synchronization support)

### `TmemAllocator`

The main class for managing TMEM allocation and deallocation.

#### Constructor

```python
TmemAllocator(
    alloc_result_dst_smem_ptr: cute.Pointer,  # SMEM location to store allocated address
    barrier_for_retrieve: pipeline.NamedBarrier,  # Barrier for synchronization
    allocator_warp_id: int = 0,  # Which warp performs allocation
    is_two_cta: bool = False,  # Enable 2-CTA coordination
    num_allocated_columns: int = 0,  # Initial allocation count
    two_cta_tmem_dealloc_mbar_ptr: cute.Pointer = None,  # Required if is_two_cta=True
    arch: str = "sm_100",  # Target architecture
)
```

#### Basic Usage Pattern

```python
from cutlass import utils, pipeline

# 1. Setup: allocate SMEM for holding the TMEM address
smem = cutlass.utils.SmemAllocator()
storage = smem.allocate(SharedStorage)  # SharedStorage has tmem_holding_buf field

# 2. Create barrier for synchronization
tmem_alloc_barrier = pipeline.NamedBarrier(
    barrier_id=1,
    num_threads=threads_per_cta,
)

# 3. Create allocator
tmem = utils.TmemAllocator(
    storage.tmem_holding_buf.ptr,
    barrier_for_retrieve=tmem_alloc_barrier,
)

# 4. Allocate TMEM columns (must be power of 2, multiple of 32)
num_tmem_cols = 512
tmem.allocate(num_tmem_cols)

# 5. Wait for allocation to complete
tmem.wait_for_alloc()

# 6. Retrieve pointer (all warps can call this)
tmem_ptr = tmem.retrieve_ptr(dtype=cutlass.Float32)

# 7. Create tensor with the pointer
tCtAcc = cute.make_tensor(tmem_ptr, acc_layout)

# ... use tCtAcc in your kernel ...

# 8. Deallocate when done
tmem.free(tmem_ptr)
```

#### Key Methods

| Method | Description |
|--------|-------------|
| `allocate(num_columns)` | Allocate TMEM columns (called by allocator warp) |
| `wait_for_alloc()` | Synchronize all warps after allocation |
| `retrieve_ptr(dtype)` | Get pointer to allocated TMEM |
| `reserve(num_columns)` | Allocate and return a `TmemBufferPool` for sub-allocation |
| `relinquish_alloc_permit()` | Signal that no more allocations will be made |
| `free(tmem_ptr, num_columns)` | Deallocate TMEM |

#### Allocation Constraints

- Number of columns must be a **power of 2** (32, 64, 128, 256, 512, ...)
- Number of columns must be a **multiple of 32**
- Maximum depends on architecture (typically 512 for SM100)

### `TmemBufferPool`

For kernels that need multiple TMEM tensors (e.g., accumulator + scale factors), `TmemBufferPool` simplifies sub-allocation from a reserved TMEM region.

#### Usage

```python
# Reserve a large TMEM region and get a pool for sub-allocation
tmem_total_size = 512  # Total columns needed
tmem_pool = tmem_allocator.reserve(tmem_total_size)

# Sub-allocate tensors - no manual offset calculations needed!
tCtAcc = tmem_pool.allocate_tensor(acc_layout, cutlass.Float32)
tCtSFA = tmem_pool.allocate_tensor(scale_a_layout, sf_dtype)
tCtSFB = tmem_pool.allocate_tensor(scale_b_layout, sf_dtype)

# Or get just a pointer if you need custom tensor creation
sfb_ptr = tmem_pool.allocate(scale_b_layout, sf_dtype)
tCtSFB = cute.make_tensor(sfb_ptr, scale_b_layout)
```

#### Properties

| Property | Description |
|----------|-------------|
| `base_ptr` | Base pointer of the pool |
| `total_cols` | Total columns in the pool |
| `current_offset` | Current allocation offset |
| `remaining_cols` | Columns still available |

### Utility Functions

#### `get_num_tmem_alloc_cols`

Calculate the total TMEM columns needed for given tensors:

```python
from cutlass.utils.tmem_allocator import get_num_tmem_alloc_cols

# Calculate required columns (rounded to power of 2)
num_cols = get_num_tmem_alloc_cols(
    [tCtAcc, tCtSFA, tCtSFB],
    rounding=True,
    arch="sm_100",
)
```

#### `compute_tmem_cols_from_layout`

Compute TMEM columns required for a layout (without creating a tensor):

```python
from cutlass.utils.tmem_allocator import compute_tmem_cols_from_layout

num_cols = compute_tmem_cols_from_layout(acc_layout, cutlass.Float32)
```

---

## Other Utilities

| File | Description |
|------|-------------|
| [`static_persistent_tile_scheduler.py`](./static_persistent_tile_scheduler.py) | Static work distribution for persistent kernels |
| [`dynamic_persistent_tile_scheduler.py`](./dynamic_persistent_tile_scheduler.py) | Dynamic work stealing for load-balanced scheduling |
| [`grouped_gemm_tile_scheduler_helper.py`](./grouped_gemm_tile_scheduler_helper.py) | Helpers for grouped/batched GEMM |
| [`tensormap_manager.py`](./tensormap_manager.py) | TMA descriptor management for grouped GEMM |
| [`smem_allocator.py`](./smem_allocator.py) | Shared memory allocation utilities |
| [`blackwell_helpers.py`](./blackwell_helpers.py) | Blackwell-specific helper functions |
| [`hopper_helpers.py`](./hopper_helpers.py) | Hopper-specific helper functions |

---

## When to Use What

### Block Copy Decision Matrix

| Your Situation | Recommendation |
|----------------|----------------|
| Standard tile-level TMA load/store | Use `block_copy` - handles partitioning automatically |
| TMA with cluster multicast | Use `block_copy` + `tma_multicast` - compiler handles mask calculation |
| SMEM to TMEM copy on Blackwell | Use `block_copy` with S2T atom - handles partitioning and SMEM desc creation automatically |
| Custom CTA layouts (non-default coordinates) | Use `cute.copy` directly |
| Non-trivial CTA coordinates needed | Use `cute.copy` directly |
| Non-TMA, non-S2T copy operations | Use `cute.copy` directly |

### TMEM Allocation Decision Matrix

| Your Situation | Recommendation |
|----------------|----------------|
| Single TMEM tensor needed | Use `TmemAllocator` directly |
| Multiple TMEM tensors from same region | Use `TmemAllocator.reserve()` → `TmemBufferPool` |
| 2-CTA MMA with shared TMEM | Use `TmemAllocator` with `is_two_cta=True` |
| Need to calculate TMEM size upfront | Use `get_num_tmem_alloc_cols()` |

---

## Examples

The `examples/block_api/` directory contains complete working examples:

### Basic Examples

| Example | Description | Key Concepts |
|---------|-------------|--------------|
| [`blackwell/tutorial_gemm/fp16_gemm_0.py`](../examples/block_api/blackwell/tutorial_gemm/fp16_gemm_0.py) | Simple GEMM mainloop | `block_copy`, `TmemAllocator` |
| [`hopper/elementwise_apply_tma.py`](../examples/hopper/elementwise_apply_tma.py) | TMA for elementwise ops | Basic `block_copy` usage |

### Intermediate Examples

| Example | Description | Key Concepts |
|---------|-------------|--------------|
| [`blackwell/tutorial_gemm/fp16_gemm_1.py`](../examples/block_api/blackwell/tutorial_gemm/fp16_gemm_1.py) | GEMM with TMA multicast | `tma_multicast`, 2-CTA MMA |
| [`blackwell/tutorial_gemm/fp16_gemm_2.py`](../examples/block_api/blackwell/tutorial_gemm/fp16_gemm_2.py) | Full pipeline + epilogue | Advanced pipeline integration |

### Advanced Examples

| Example | Description | Key Concepts |
|---------|-------------|--------------|
| [`blackwell/tutorial_gemm/nvfp4_gemm_0.py`](../examples/blackwell/tutorial_gemm/nvfp4_gemm_0.py) | NVFP4 block-scaled GEMM | S2T copy, scale factors |
| [`blackwell/dense_gemm_persistent.py`](../examples/blackwell/dense_gemm_persistent.py) | Persistent GEMM | Full production pattern |
| [`hopper/dense_gemm_persistent.py`](../examples/hopper/dense_gemm_persistent.py) | Hopper persistent GEMM | WGMMA with pipelines |

### Comparing Block API vs. Manual Implementation

Each tutorial GEMM example has a non-block-API counterpart with the same filename under `examples/blackwell/tutorial_gemm/`:

```text
examples/block_api/blackwell/tutorial_gemm/fp16_gemm_0.py  ←→  examples/blackwell/tutorial_gemm/fp16_gemm_0.py
examples/block_api/blackwell/tutorial_gemm/fp16_gemm_1.py  ←→  examples/blackwell/tutorial_gemm/fp16_gemm_1.py
examples/block_api/blackwell/tutorial_gemm/fp16_gemm_2.py  ←→  examples/blackwell/tutorial_gemm/fp16_gemm_2.py
```

Comparing these pairs shows how the block API simplifies implementation.

---

## Troubleshooting

### `block_copy`-Specific Errors

#### `ValueError: "Argument tma_bar_ptr is required."`

- **When**: TMA load (G2S) called without barrier pointer
- **Fix**: Pass `tma_bar_ptr=barrier_ptr` for all TMA load operations

```python
utils.block_copy(tma_atom, src, dst, tma_bar_ptr=barrier_ptr)
```

#### `ValueError: "block_copy with tma_multicast expects CopyBulkTensorTileG2SOp for compiler-driven multicast"`

- **When**: Using `tma_multicast` with a non-G2S copy operation (e.g., TMA store)
- **Fix**: Only use `tma_multicast` with TMA load operations; the compiler will upgrade to multicast automatically

#### `NotImplementedError: "Copy op {name} is not supported yet."`

- **When**: Using an unsupported copy operation type
- **Fix**: Currently only `TmaCopyOp` and `_S2TCopyBase` are supported; use `cute.copy` directly for other types

### Other Common Errors

#### `AssertionError: "num_columns must be multiple of 32 and power of two..."`

**Cause**: Invalid TMEM allocation size.

**Solution**: TMEM columns must be:
- Greater than 0
- A multiple of 32
- A power of 2 (32, 64, 128, 256, 512, ...)
- Not exceeding maximum capacity (typically 512)

#### `AssertionError: "Cannot allocate N columns, only M remaining"`

**Cause**: `TmemBufferPool` doesn't have enough space.

**Solution**: Either:
1. Reserve a larger TMEM region initially
2. Use `get_num_tmem_alloc_cols()` to calculate the required size upfront

#### Pipeline arrive count mismatch with TMA multicast

**Cause**: When using `tma_multicast`, the number of TMA producers changes.

**Solution**: Manually adjust your pipeline's arrive count. The compiler handles the copy operation but not the pipeline configuration:
```python
num_mcast_ctas_a = cluster_shape_m  # Multicast along M
num_mcast_ctas_b = cluster_shape_n  # Multicast along N
num_tma_producer = num_mcast_ctas_a + num_mcast_ctas_b - 1
```

---

## Limitations

### `block_copy` Limitations

- **Supported copy kinds**: Only TMA-based copies and S2T copies are currently supported
- **Tensor layout requirement**: For TMA copies, `src` and `dst` must have TMATile as the first mode; call `group_modes(tensor, 0, 2)` on rank-2 tiles
- **Block-level pattern**: Assumes standard block-level usage; custom CTA layouts may require direct `cute.copy` calls

### `TmemAllocator` Limitations

- **Blackwell only**: TMEM is only available on Blackwell (SM100+) GPUs
- **Allocation constraints**: Column count must be power of 2 and multiple of 32
- **Single allocator warp**: Only one warp (default: warp 0) performs allocations
- **Manual pipeline coordination**: For 2-CTA mode, you must provide the deallocation mbarrier

### General Limitations

- All utilities in this folder are **experimental** and may have breaking changes
- Some features are architecture-specific (check hardware requirements)
- These utilities are designed for common patterns; edge cases may require lower-level APIs
