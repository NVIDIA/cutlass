SLM Pipeline Constructors
=========================

There are several situations where the current Xe mainloops (based on prefetch and sharing A/B data out of L1) provide insufficient performance:
* A/B preprocessing is computationally expensive or requires many registers (e.g. emulated e4m3 upconversion).
* Block 2D loads are not available, because data must be gathered (e.g. GQA/MoE scenarios) or because the block 2D alignment/size requirements are not met.
  - Without block 2D loads, kernels will typically run out of tokens, and often have to use less efficient d16u32/d8u32 messages.

Before looking at the API description, let's look at a very simple single-buffered SLM-pipelined mainloop. For more background on SLM pipelines, including how to make this simple pipeline more performant, see the [gemmstone documentation](https://github.com/intel-innersource/libraries.performance.math.gemmstone/blob/more_docs/doc/algorithms/pipelines.md#slm-pipelines).

```c++
  for (int k = 0; k < K, k++) {
    // Global -> registers load
    copy(copy_a_g2r, tAgA, tArA_in);
    copy(copy_b_g2r, tBgB, tBrB_in);

    // Reorder input to output fragments, and write to SLM
    reorder(tArA_in, tArA_out);
    reorder(tBrB_in, tBrB_out);
    copy(copy_a_r2s, tArA_out, tAsA_out);
    copy(copy_b_r2s, tBrB_out, tBsB_out);

    // Barrier, with memory fence
    barrier_arrive(ScopeWorkgroup, SemanticsRelease | SemanticsWGMemory);
    barrier_wait(ScopeWorkgroup, SemanticsAcquire | SemanticsWGMemory);

    // Load SLM -> registers
    copy(copy_a_s2r, tAsA_in, tCrA_in);
    copy(copy_b_s2r, tBsB_in, tCrB_in);

    // Multiply
    gemm(tiled_mma, tCrA, tCrB, tCrC);

    // Barrier, with memory fence
    barrier_arrive(ScopeWorkgroup, SemanticsRelease | SemanticsWGMemory);
    barrier_wait(ScopeWorkgroup, SemanticsAcquire | SemanticsWGMemory);
  }
```

Looking at the snippet above, we can see that our main focus is creating proper TiledCopies: global->registers, registers->SLM, SLM->registers. To get there, there are several steps:
- (a) Partition A/B tiles between participating subgroups.
- (b) Choose global memory copy operation for A/B global loads.
- (c) Create WG-scoped TiledCopy object for global memory copies.
- (d) Choose shared memory layouts for A/B &mdash; these should match the layout required by DPAS.
- (e) Choose copy operations for SLM store, based on the SLM layout and the global load's destination layout.
- (f) Create WG-scoped TiledCopy objects for copies to and from SLM.

When A/B are regular CuTe tensors, all these steps can be automated. The kernel writer may want to override the choices for steps (a-b), but steps (c-f) are basically always automatic.

In more complicated cases, the kernel writer may want to create the global memory TiledCopy manually, or not even use TiledCopy for the global memory load. For instance, to optimize MoE, the A tile may be composed of arbitrary sets of rows gathered from the A tensor. For such cases (a-c) falls to the kernel writer, while CuTe can handle (d-f).

Finally, A/B data may come from a prior computation in the kernel, rather than global memory. For instance, an alternate way to implement FlashAttention is to store the $P$ matrix in SLM prior to the second matrix multiplication. (There are several benefits to this implementation, which is [used in oneDNN](https://github.com/intel-sandbox/libraries.performance.math.gpu-gemm-docs/blob/main/oneDNN%20SDPA%20Implementation.pptx).) Here steps (a-c) are unnecessary, and steps (d-f) can be handled by CuTe.

Sometimes it is useful for SLM buffers to use a larger k tile size than the TiledMMA (i.e. contain enough data for multiple TiledMMAs). In the future, it may be useful to extend the proposed APIs to handle this case.


API Description
-------------

### Global $\rightarrow$ Register TiledCopy Creation

To cover steps (a-c) &mdash; creating the global memory load &mdash; we introduce a new family of _cooperative load_ creation APIs.

```c++
TiledCopy make_coop_block_2d_copy_A(TiledMMA const& tiled_mma,
                                    Tensor const&   A);

TiledCopy make_coop_copy_A(CopyOp   const& op,
                           TiledMMA const& tiled_mma,
                           Tensor   const& A);

TiledCopy make_coop_copy_A(CopyOp   const& op,
                           Shape    const& sg_tile_shape,
                           TiledMMA const& tiled_mma,
                           Tensor   const& A);

// Similar APIs for B.
// Also include APIs which take element type + global strides inplace of the Tensor,
//   similar to other make_block_2d_copy* APIs.
```

The first API is the highest-level, automatically choosing a block 2D copy operation and subgroup tiling. The lower-level APIs allow the user to choose a copy operation (which may not be block 2D -- regular block and scattered loads should be supported to handle less-aligned A/B), and optionally the subgroup tile size. The scope of the resulting TiledCopy operations matches that of the TiledMMA.

The implementation of these routines (for block 2D at least) will be very similar to the existing `make_block_2d_prefetch` APIs, since a prefetch is essentially a cooperative load. The major differences:
* It's OK if the workgroup's A/B tiles can't be evenly divided into subgroup prefetch tiles, but for SLM copies the work division must be even.
* `make_coop_copy_A` should support non-block-2D messages. The optimal subgroup tile shape can be different depending on the copy operation -- for instance, for block loads (`XE_1D_LOAD_GLOBAL`), the tile shape should be chosen to maximize the vector size of the block loads.


### SLM Layout Creation

For step (d) &mdash; choosing a proper SLM layout for a TiledMMA &mdash; we can introduce two small helpers:

```c++
Layout make_A_slm_layout(TiledMMA const& tiled_mma);    // (m,k) -> offset
Layout make_B_slm_layout(TiledMMA const& tiled_mma);    // (n,k) -> offset
```

Since the goal of the SLM layout is to exactly match the data layout needed by each subgroup, these mostly boil down to some layout algebra with [`TiledMMA::thrfrg_{A,B}`](https://github.com/intel/sycl-tla/blob/482b40e8bed0e9204311d1569c876b4573dfb952/include/cute/atom/mma_atom.hpp#L297). We will want to arrange data in SLM so that each subgroup's data is contiguous in SLM (i.e. move ThrM/ThrN/ThrK modes to the end).


### SLM $\leftrightarrow$ Register TiledCopy Creation

Steps (e-f) can be encapsulated in a single high-level routine:

```c++
auto make_A_slm_copies(TiledMMA  const& tiled_mma,
                       TiledCopy const& global_copy)  // input TiledCopy for global A load
    -> std::tuple<TiledCopy,                          // TiledCopy for writing to SLM
                  TiledCopy>;                         // TiledCopy for reading from SLM

// Similarly for B
```

The scope of the write TiledCopy matches that of `global_copy` (i.e. the same threads participate in each), while the scope of the read TiledCopy matches that of the TiledMMA. These APIs assume that the SLM layout was created via `make_{A,B}_slm_layout`.

If a `TiledCopy` object for the global load is not available, we can take the TV layout that would have been inside of it instead:

```c++
auto make_A_slm_copies(TiledMMA const& tiled_mma,
                       Layout   const& global_load_tv_layout)  // (thr,val) -> coord within A tile
    -> std::tuple<TiledCopy, TiledCopy>;
```


#### Generic SLM $\leftrightarrow$ Register Copies

Copying data between registers (represented by `SubgroupTensor`s) and SLM buffers is a very common operation, and it will be useful to have a generic implementation. For instance, FlashAttention currently has a [set of utilities](../applications/flash_attention_v2/collective/copy_block_slm.hpp) that cover some limited cases used during cross-subgroup softmax reduction.

Accordingly, let's introduce some generic routines for copying data between registers and SLM, which can be used internally by `make_{A,B}_slm_copies`, attention fusions, and other users of SLM.

For a subgroup-scoped copy between a `SubgroupTensor` and SLM, all we need is the source and destination tensor, since each `SubgroupTensor` provides coordinates (via its `.tv_layout()`) for the data it owns.

```c++
TiledCopy make_slm_copy(SubgroupTensor const& src,
                        Tensor              & dst);

TiledCopy make_slm_copy(Tensor         const& src,
                        SubgroupTensor      & dst);
```

When multiple subgroups are involved, as in SLM pipelines, we also need to understand how the SLM tensor is partitioned between subgroups.
For this reason, we also provide overloads that take an additional layout mapping each subgroup to its starting coordinate in the SLM tensor.

```c++
TiledCopy make_slm_copy(SubgroupTensor const& src,
                        Tensor              & dst,
                        Layout         const& sg_coord_offsets);  // SG -> starting coordinate

TiledCopy make_slm_copy(Tensor         const& src,
                        SubgroupTensor      & dst,
                        Layout         const& sg_coord_offsets);
```

Here, the additional layout may be either a coordinate layout or a regular layout, in which case the coordinates are interpreted using the shape of the SLM tensor.

The major implementation work needed inside `make_slm_copy` is to choose the copy operation. For Intel GPUs, we can use the following heuristics:
1. Start with generic scattered loads/stores (`UniversalCopy`):
    * If the elements are less than 32 bits in size, data in SLM should be grouped into 32-bit elements in SLM (as long as there is enough data). This grouping may require a reorder, but this is typically preferable to 8/16-bit access.
2. If within a subgroup we have contiguous addresses (after any 32-bit grouping), use block loads/stores (`XE_1D_LDSM`/`XE_1D_STSM`) with the maximum possible vector length.


### Example Code

Let's use the proposed APIs to finish the example code from the beginning of the RFC:


```c++
template <...>
auto simple_slm_mainloop(TiledMMA tiled_mma,
                         TensorA const& A, TensorB const& B,
                         WGCoord const& wg_coord,
                         int thread_idx,
                         uint8_t *slm_storage)
{
  using ElementA = typename TiledMMA::ValTypeA;
  using ElementB = typename TiledMMA::ValTypeB;

  // Create TiledCopy operations for SLM pipeline.
  auto copy_a_g2r = make_coop_block_2d_copy_A(tiled_mma, A);
  auto copy_b_g2r = make_coop_block_2d_copy_B(tiled_mma, B);

  auto [copy_a_r2s, copy_a_s2r] = make_A_slm_copies(tiled_mma, copy_a_g2r);
  auto [copy_b_r2s, copy_b_s2r] = make_B_slm_copies(tiled_mma, copy_b_g2r);

  // Slice TiledCopy/TiledMMA (some lines removed for brevity)
  auto thr_mma = tiled_mma.get_slice(thread_idx);
  auto thr_copy_a_g2r = copy_a_g2r.get_slice(thread_idx);
     /* etc. */

  // Partition A/B into workgroup tiles as usual
  auto cA = make_identity_tensor(A.shape());
  auto cB = make_identity_tensor(B.shape());

  auto wg_tile = tiled_mma.tile_mnk();
  Tensor gA = local_tile(cA, select<0,2>(wg_tile), make_coord(get<0>(wg_coord),_));  // (BLK_M,BLK_K,k)
  Tensor gB = local_tile(cB, select<1,2>(wg_tile), make_coord(get<1>(wg_coord),_));  // (BLK_N,BLK_K,k)

  // Created shared memory buffers for A/B
  Tensor sA = make_tensor(make_smem_ptr(static_cast<ElementA const *>(slm_storage)),
                          make_A_slm_layout(tiled_mma));
  Tensor sB = make_tensor(make_smem_ptr(static_cast<ElementB const *>(slm_storage)),
                          make_B_slm_layout(tiled_mma));

  // Create partitions and register fragments for copies
  auto tAgA = thr_copy_a_g2r.partition_S(gA);
  auto tBgB = thr_copy_b_g2r.partition_S(gB);

  auto tArA_in = thr_copy_a_g2r.partition_sg_fragment_D(gA);
  auto tBrB_in = thr_copy_b_g2r.partition_sg_fragment_D(gB);

  auto tArA_out = thr_copy_a_r2s.partition_sg_fragment_S(gA);
  auto tBrB_out = thr_copy_b_r2s.partition_sg_fragment_S(gB);

  auto tAsA_out = thr_copy_a_r2s.partition_D(sA);
  auto tBsB_out = thr_copy_b_r2s.partition_D(sB);

  auto tAsA_in = thr_copy_a_s2r.partition_S(sA);
  auto tBsB_in = thr_copy_b_s2r.partition_S(sB);

  // Create register fragments for MMA.
  auto tCrA = thr_mma.partition_sg_fragment_A(gA);
  auto tCrB = thr_mma.partition_sg_fragment_B(gB);
  auto tCrC = thr_mma.partition_sg_fragment_C(make_identity_tensor(take<0,2>(wg_tile)));

  // SLM->registers copies can directly use the MMA A/B fragments,
  //  without any reorders.
  auto tCrA_in = copy_a_s2r.retile_D(tCrA);
  auto tCrB_in = copy_b_s2r.retile_D(tCrB);

  for (int k = 0; k < K, k++) {
    // Global -> registers load
    copy(copy_a_g2r, tAgA, tArA_in);
    copy(copy_b_g2r, tBgB, tBrB_in);

    // Reorder input to output fragments, and write to SLM
    reorder(tArA_in, tArA_out);
    reorder(tBrB_in, tBrB_out);
    copy(copy_a_r2s, tArA_out, tAsA_out);
    copy(copy_b_r2s, tBrB_out, tBsB_out);

    // Barrier, with memory fence
    barrier_arrive(ScopeWorkgroup, SemanticsRelease | SemanticsWGMemory);
    barrier_wait(ScopeWorkgroup, SemanticsAcquire | SemanticsWGMemory);

    // Load SLM -> registers
    copy(copy_a_s2r, tAsA_in, tCrA_in);
    copy(copy_b_s2r, tBsB_in, tCrB_in);

    // Multiply
    gemm(tiled_mma, tCrA, tCrB, tCrC);

    // Barrier, with memory fence
    barrier_arrive(ScopeWorkgroup, SemanticsRelease | SemanticsWGMemory);
    barrier_wait(ScopeWorkgroup, SemanticsAcquire | SemanticsWGMemory);
  }

  return tCrC;
}
```
