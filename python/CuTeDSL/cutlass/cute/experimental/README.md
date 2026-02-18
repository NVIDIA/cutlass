# CuTe Experimental APIs

> **Note:** APIs in this module are experimental and subject to change.
>
> This module serves as a staging area for new CuTe functionality that is still under active development. Performance, compile time, and interoperability with CuTe are works in progress. API signatures, behavior, and naming conventions may change without notice between releases.
>
> Once these APIs are stabilized, they will be migrated to the main `cute` submodules.
> 
> Users are encouraged to experiment with these APIs but should be prepared to update their code as the interfaces evolve.

## Core APIs (`core.py`)

- `elect_sync` — Elects one thread within a warp
- `get_mbarrier` — Returns the mbarrier pointer for a given stage token
- `create_pipeline` — Creates a circular buffer of synchronization primitives indexed by stage count
- `create_pipeline_with_mask` — Creates a pipeline with an arrival mask for cluster-scoped synchronization
- `pipeline_advance_iterator` — Advances a pipeline iterator to the next stage
- `producer_acquire` / `producer_commit` — Producer-side pipeline synchronization
- `consumer_wait` / `consumer_release` / `consumer_tail` — Consumer-side pipeline synchronization
- `get_pipeline_produce_stage` / `get_pipeline_consume_stage` — Gets pipeline stage tokens

## Memory APIs (`memory.py`)

- `allocate` — Allocate a buffer with given type, layout, and address space
- `tma_load` — Copy tensor from global memory to shared memory using TMA
- `tma_load_multicast` — Copy tensor from global memory to shared memory using TMA with multicast
- `tma_store` — Copy tensor from shared memory to global memory using TMA
- `copy` — Copy tensor from src to dst using a given copy atom

## Algorithm APIs (`algorithm.py`)

- `simt_auto_vec_copy` — Copies a tensor between buffers with single thread (auto-vectorized)
- `partition` — Partition a buffer into a given layout and tiler
- `partition_and_copy` — Combines partitioning and copying in a single operation

## Math APIs (`math.py`)

- `dot` — Computes a dot product of two tensors using an MMA atom
- `dot_block_scaled` — Computes a block-scaled dot product with scale factors

## Pipeline Classes (`pipeline.py`)

- `GenericPipeline` — Generic pipeline for any producer/consumer combination
- `TMAToUMMAPipeline` — Pipeline for TMA load to UMMA consumption
- `TMAToAsyncPipeline` — Pipeline for TMA load to async consumer
- `AsyncToUMMAPipeline` — Pipeline for async producer to UMMA consumption
- `UMMAtoAsyncPipeline` — Pipeline for UMMA producer to async consumer
- `TMAStorePipeline` — Pipeline for SMEM producer to TMA store consumer

## Utilities (`utils.py`)

- `get_cta_v_map_ab` — Compute CTA-V map for A/B operands
- `get_cta_v_map_c` — Compute CTA-V map for C operand
- `make_tmem_layout_acc` — Derive TMEM accumulator buffer layout from a tiled MMA
- `make_tmem_layout_a` — Derive TMEM A-operand buffer layout from a tiled MMA
- `make_t2r_rmem_layout` — Derive per-thread RMEM buffer layout for the T2R epilogue copy

