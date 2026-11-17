.. _rubin_support:

Rubin Feature Support
=====================

CUTLASS exposes Rubin hardware features through four programming models:

- **C++**: the CUTLASS C++ templates and CuTe.
- **Primitives**: ``cutlass.experimental.primitives``, thin Python wrappers
  over the instructions; one call per instruction, every operand explicit.
- **CuTe DSL**: ``cutlass.cute`` atoms, ``cute.arch`` and ``cute.math``.
- **CuTe DSL extensions**: the ``cute_ext`` kernel-authoring layer built on
  the CuTe DSL.

The three Python programming models are interoperable and can be mixed in one
kernel. If you would like a feature to be added to a specific programming
model, please reach out to us.

This page records, per feature and per model, the release in which the
feature became available together with an example. Only features that have
shipped in at least one programming model are listed.

Legend
------

.. list-table::
   :header-rows: 1
   :widths: 20 80

   * - Value
     - Meaning
   * - 4.8, 4.9
     - The release in which both the API and an example shipped for that
       model.
   * - Use Primitives
     - Not exposed in that programming model; use the Primitives API, which
       can be mixed into the same kernel.
   * - Not applicable
     - Cannot be exposed in that programming model because the compiler
       makes the decision.
   * - Not available
     - Not exposed in that programming model yet.

Support matrix
--------------

.. list-table::
   :header-rows: 1
   :widths: 44 14 14 14 14

   * - Feature
     - C++
     - Primitives
     - CuTe DSL
     - CuTe DSL extensions
   * - B-operand collector reuse: keep a B tile resident in the Tensor Core
       across consecutive ``tcgen05.mma`` instructions so shared memory is
       read once per tile
     - 4.8
     - 4.8
     - 4.8
     - 4.8
   * - Tensor memory of 288 KB per SM (256 KB on Blackwell)
     - 4.8
     - 4.8
     - 4.8
     - 4.8
   * - Shared memory of 328 KB per SM (228 KB on Blackwell)
     - 4.8
     - 4.8
     - 4.8
     - 4.8
   * - Mixed-precision block-scaled MMA (FP8 with FP4 or FP6 operands) at
       K=64 per instruction, twice the K of the Blackwell instruction
     - 4.8
     - 4.8
     - 4.8
     - 4.8
   * - UE5M3 scale factors for NVFP4, and block-32 scaling for E4M3 and E5M3
       scale factors
     - 4.8
     - 4.8
     - 4.8
     - 4.8
   * - Dense NVFP4 MMA at K=128 per instruction
     - 4.8
     - 4.8
     - 4.8
     - 4.8
   * - 2:4 structured sparsity for FP4 MMA: true 2:4 metadata instead of the
       Blackwell pairwise expansion
     - Not available
     - 4.8
     - 4.9
     - 4.9
   * - Packed base-2 exponential on FP16x2 and BF16x2 registers
     - Not available
     - 4.8
     - Use Primitives
     - Use Primitives
   * - Mixed-format packed arithmetic for softmax: multiply, add and FMA
       between FP32 and FP16x2 / BF16x2 operands, with packed conversions
     - Not available
     - 4.8
     - Use Primitives
     - Use Primitives
   * - Densely packed FP6 MMA at K=64 per instruction
     - Not available
     - 4.9
     - 4.8
     - Not available
   * - Shared-memory ring buffers: a descriptor mode that carries the address
       of the next buffer so a K loop wraps without re-encoding descriptors
     - Not available
     - 4.9
     - Not applicable
     - Not applicable
   * - Releasing the A operand stage early: a ``tcgen05.commit`` variant that
       fires when A has been read, before the MMA completes
     - Not available
     - 4.9
     - Not available
     - 4.9
   * - TMA loads with validity reporting: consumers synchronize on per-tile
       data arrival instead of an mbarrier round trip
     - 4.9
     - 4.9
     - 4.9
     - 4.9
