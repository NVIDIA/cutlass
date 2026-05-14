# SM120 MXF4NVF4 Layout Contract

This note records the narrow CuTe DSL contract for SM120 MXF4NVF4 helper APIs.
It is based on the C++ collective path selected by Blackwell GeForce example
79a, but the Python API names remain generic SM120/MXF4NVF4 names.

## External Descriptor TMA

A/B external descriptors describe a rank-3 logical tile `(K, major, L)`.
One 128x128 packed FP4 A or B TMA transaction transfers 8192 payload bytes.
The physical ALIGN16B shared-memory destination occupies 16384 byte slots.

SFA/SFB external descriptors describe a rank-4 scale tile and transfer 1024
bytes each. A full A/B/SFA/SFB pipeline stage therefore accounts for 18432 TMA
transaction bytes.

External descriptor TMA issue paths must acquire the tensor-map descriptor
before issuing the TMA instruction.

## A/B Consumer SMEM

The production A/B consumer path is the C++ collective contract:

```text
Sw<2,4,3> o smem_ptr[4b] o (_8,_128):(_128,_1)
```

The source tensor passed to LDSM partitioning is made position independent:

```text
as_position_independent_swizzle_tensor(sA/sB)
make_tiled_copy_A/B(non-transposed LDSM_N)
partition_S(...)
retile_D(...)
cute.copy(...)
fp4_shift_A/B(...)
bundled MXF4NVF4 cute.gemm(...)
```

For this SM120 MXF4NVF4 LDSM tiled-copy path, Python CuTe's `retile_D` helper
aliases the existing `retile()` lowering and is covered by the logical A/B
consumer tests. It should not be read as a blanket statement about every copy
atom.

The B operand uses the same non-transposed SM75 `x4` LDSM form as A. Logical B
major-to-output-N mapping comes from the composed consumer SMEM layout,
`make_tiled_copy_B`, destination retile, and the post-LDSM FP4 shift.
In Python CuTe DSL the explicit `fp4_shift_A/B` hook is a validated no-op for
typed `Float4E2M1FN` LDSM copies because the typed copy already produces the
fragment encoding consumed by SM120 MXF4NVF4 MMA.

The older manual inline-LDSM scratch helpers remain compatibility-only. They
are not part of the public `__all__` surface for new kernels.

The current external-descriptor path stages A/B through the physical TMA
layout, then uses a CUTLASS-owned physical-to-consumer adapter before the
consumer copy. That adapter restores logical packed-FP4 byte order from the
16U4_ALIGN16B physical slots and writes through the SM120 consumer tensor
layout used by `as_position_independent_swizzle_tensor`. Global major offsets
belong in the tensor-map coordinates; the adapter stages one local 128-major
tile and rejects nonzero major offsets. The adapter `consumer_stage_idx`
selects the destination consumer stage; pass a sliced physical-stage view when
staging from a nonzero physical TMA stage.

Consumer helpers take warp-local lane indices. In a multi-warp CTA, pass
`threadIdx.x % 32` to A/B consumer-fragment helpers and to staging helpers.
Call the physical-to-consumer staging helper from the intended staging
warp/cohort, then synchronize before consumer warps load fragments. Use
`make_mxf4nvf4_ab_consumer_microtile_views()` or the `m_atom`/`n_atom`
arguments on the fragment/load helpers to select a local 16x8 output atom
inside the staged 128x128 CTA tile.

## Scale Bridge

The rank-4 scale physical layout is adapted into fragment-compatible scratch by
mapping logical payload order:

```text
payload_idx = scale_col * 128 + major
scratch_idx = local_major * 8 + scale_col
```

Strict runtime coverage should keep the two-K64 scale canary where A/B are
`0x22`, SFB is `1.0`, SFA columns `0..3` are `1.0`, SFA columns `4..7` are
`2.0`, and the expected accumulator value is `192.0`.

## Downstream Contract

Downstream kernels own scheduling, descriptor lifetimes, producer/consumer warp
partitioning, pipeline loops, and epilogues. They should not duplicate A/B byte
rank maps, B register permutations, inline LDSM register extraction, or scale
physical swizzle logic.
