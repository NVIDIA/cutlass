# SPDX-FileCopyrightText: Copyright (c) 2024 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# NVIDIA CORPORATION, its affiliates and licensors retain all intellectual
# property and proprietary rights in and to this material, related
# documentation and any modifications thereto. Any use, reproduction,
# disclosure or distribution of this material and related documentation
# without an express license agreement from NVIDIA CORPORATION or
# its affiliates is strictly prohibited.

# This is the third tutorial GEMM. It further enhances the second tutorial by adding warp
# specialization for TMA, MMA, and epilogue warps.


import argparse
from typing import Tuple

import cutlass
import cutlass.cute as cute
import cutlass.utils as utils
import cutlass.pipeline as pipeline
from cutlass.cute.nvgpu import cpasync, tcgen05
import cutlass.utils.blackwell_helpers as sm100_utils
from cutlass.cute.runtime import from_dlpack

"""
The third tutorial GEMM demonstrates a simple kernel implementation in CuTeDSL.

It further enhances fp16_gemm_1.py by adding warp specialization for TMA, MMA, and epilogue warps. 
In the epilogue warp, we use TMA store instead of regular copy to store the result from registers to global memory.

This example can achieve better performance than fp16_gemm_1.py due to:
1. We use warp specialization(WS) to overlap the memory loads and MMA computations.

Core concept of WS is to specialize warps with different tasks (e.g., DMA, MMA, epilogue),
therefore, different warps in a CTA must communicate with each other.

Warp specialization's benefit comes from task parallelism between warps in the CTA.
For example, the DMA warps proceed to start loading A/B tensors for the next K-block as soon as they finish loading the current K-block.
While the MMA warps are computing the result of the current K-block. So the dram latency is hidden.
The dram latency can also be hidden by prefetch in non-WS version,
but WS version has better instruction level parallelism as different types of instructions are issued in different warps.
For example, in non-WS version, tmem allocation and TMA loads are both issued in the same warp, TMA loads only issue after tmem allocation is finished.
But in WS version, tmem allocation and TMA loads are issued in different warps, tmem allocation can be overlapped with TMA loads.

2. We use TMA store instead of regular copy to store the results from registers to global memory.

To store the results from registers to global memory using TMA actually requires two steps:
1). Write the tile from registers to shared memory
2). Write the tile from shared memory to global memory
Here we continue to use epiolgue subtiles, one reason is that it reduces the shared memory usage in the epilogue,
and another reason is that it can hide the STS latency, that is the STS of the next subtile can be overlapped with the TMA store of the current subtile.

For large mma tile size, the mainloop performance between Non-WS and WS version could be similar if there are enough ab_stages to hide the dram latency.
The performance gain of WS version mainly comes from the prologue and epilogue in this case.
That means, if k-dimension is small, then the performance of WS version will be obviously better than non-WS version.
For small mma tile size, we may also see better mainloop performance for WS version.
This is because there are ALU instructions (preparation work for MMA) for each MMA instruction, and ALU proportion is higher for small mma tile size.
In Non-WS version, warp 0 will issue the ALU operations for both TMA and MMA instruction, while in WS version, they are issued in different warps,
so less ALU instructions are issued in MMA warp, and mma instructions can be issued more efficiently.

To run this example:
.. code-block:: bash
    python examples/blackwell/tutorial_gemm/fp16_gemm_2.py  \
      --mnk 8192,8192,8192

Constraints for this example:
* The problem size of m and n must be divisible by the tile size m & n (256, 256)
"""

io_dtype = cutlass.Float16
acc_dtype = cutlass.Float32
use_2cta_instrs = True
cluster_shape_mnk = (2, 1, 1) if use_2cta_instrs else (1, 1, 1)
mma_inst_shape_mnk = (256, 256, 16)
mma_tiler_mnk = (256, 256, 64)
threads_in_epilogue = 128  # epilogue threads per cta

# Pipeline stage configuration
ab_stages = 6
epi_stages = 2
acc_stages = 1


@cute.struct
class SharedStorage:
    ab_mbar_ptr: cute.struct.MemRange[cutlass.Int64, ab_stages * 2]
    acc_mbar_ptr: cute.struct.MemRange[cutlass.Int64, acc_stages * 2]
    tmem_dealloc_mbar: cutlass.Int64
    tmem_holding_buffer: cutlass.Int32


@cute.kernel()
def kernel(
    tiled_mma: cute.TiledMma,
    tma_atom_a: cute.CopyAtom,
    mA_mkl: cute.Tensor,
    tma_atom_b: cute.CopyAtom,
    mB_nkl: cute.Tensor,
    tma_atom_c: cute.CopyAtom,
    mC_mnl: cute.Tensor,
    a_smem_layout: cute.ComposedLayout,
    b_smem_layout: cute.ComposedLayout,
    c_smem_layout_kind: cutlass.Constexpr,
    epi_smem_layout_staged: cute.ComposedLayout,
    epi_tile: cute.Tile,
    cta_layout_vmnk: cute.Layout,
):
    warp_idx = cute.arch.warp_idx()
    warp_idx = cute.arch.make_warp_uniform(warp_idx)

    tidx, _, _ = cute.arch.thread_idx()
    bidx, bidy, _ = cute.arch.block_idx()

    cta_rank_in_cluster = cute.arch.block_idx_in_cluster()
    cta_in_cluster_coord_vmnk = cta_layout_vmnk.get_flat_coord(cta_rank_in_cluster)

    mma_coord_vmnk = (
        bidx % cute.size(cta_layout_vmnk, mode=[0]),
        bidx // cute.size(cta_layout_vmnk, mode=[0]),
        bidy,
        None,
    )
    mma_coord_mnk = mma_coord_vmnk[1:]
    is_leader_cta = mma_coord_vmnk[0] == 0

    epilogue_warp_ids = (
        0,
        1,
        2,
        3,
    )
    mma_warp_id = 4
    tma_warp_id = 5

    #
    # 1. Prepare args
    #

    # Allocate SMEM
    smem = cutlass.utils.SmemAllocator()
    storage = smem.allocate(SharedStorage)
    sA = smem.allocate_tensor(
        element_type=io_dtype,
        layout=a_smem_layout.outer,
        byte_alignment=128,
        swizzle=a_smem_layout.inner,
    )
    sB = smem.allocate_tensor(
        element_type=io_dtype,
        layout=b_smem_layout.outer,
        byte_alignment=128,
        swizzle=b_smem_layout.inner,
    )
    sC = smem.allocate_tensor(
        element_type=io_dtype,
        layout=epi_smem_layout_staged.outer,
        byte_alignment=128,
        swizzle=epi_smem_layout_staged.inner,
    )

    # Prefetch tma descriptor
    if warp_idx == tma_warp_id:
        cpasync.prefetch_descriptor(tma_atom_a)
        cpasync.prefetch_descriptor(tma_atom_b)
        cpasync.prefetch_descriptor(tma_atom_c)

    # As many participants as the number of threads issuing the MMA in the same row and column
    # Substract one to not count twice the same thread
    num_mcast_participants = (
        cute.size(cta_layout_vmnk, mode=[1]) + cute.size(cta_layout_vmnk, mode=[2]) - 1
    )

    # Mcast mask initialization
    tma_mcast_mask_a = cute.nvgpu.cpasync.create_tma_multicast_mask(
        cta_layout_vmnk, cta_in_cluster_coord_vmnk, mcast_mode=2
    )
    tma_mcast_mask_b = cute.nvgpu.cpasync.create_tma_multicast_mask(
        cta_layout_vmnk, cta_in_cluster_coord_vmnk, mcast_mode=1
    )

    # Partition tensors for MMA and make fragments
    # (bM, bK, RestK)
    gA = cute.local_tile(mA_mkl, mma_tiler_mnk, mma_coord_mnk, proj=(1, None, 1))
    # (bN, bK, RestK)
    gB = cute.local_tile(mB_nkl, mma_tiler_mnk, mma_coord_mnk, proj=(None, 1, 1))
    # (bM, bN)
    gC = cute.local_tile(mC_mnl, mma_tiler_mnk, mma_coord_mnk, proj=(1, 1, None))

    thr_mma = tiled_mma.get_slice(mma_coord_vmnk[0])
    # (MMA, MMA_M, MMA_K, RestK)
    tCgA = thr_mma.partition_A(gA)
    # (MMA, MMA_N, MMA_K, RestK)
    tCgB = thr_mma.partition_B(gB)
    # (MMA, MMA_M, MMA_N)
    tCgC = thr_mma.partition_C(gC)

    # (MMA, MMA_M, MMA_K, STAGE)
    tCrA = tiled_mma.make_fragment_A(sA)
    # (MMA, MMA_N, MMA_K, STAGE)
    tCrB = tiled_mma.make_fragment_B(sB)

    # (MMA, MMA_M, MMA_N)
    acc_shape = tiled_mma.partition_shape_C(mma_tiler_mnk[:2])
    # (MMA, MMA_M, MMA_N)
    tCtAcc_fake = tiled_mma.make_fragment_C(acc_shape)

    # Barrier 1 for epilogue synchronization
    epilogue_sync_barrier = pipeline.NamedBarrier(
        barrier_id=1,
        num_threads=threads_in_epilogue,
    )

    # Only MMA warp and epilogue warps participate in TMEM allocation synchronization
    # TMA warp does NOT participate
    tmem_alloc_barrier = pipeline.NamedBarrier(
        barrier_id=2,
        num_threads=32
        * len((mma_warp_id, *epilogue_warp_ids)),  # 5 warps = 160 threads
    )
    tmem = utils.TmemAllocator(
        storage.tmem_holding_buffer,
        barrier_for_retrieve=tmem_alloc_barrier,
        allocator_warp_id=epilogue_warp_ids[0],
        is_two_cta=True if use_2cta_instrs else False,
        two_cta_tmem_dealloc_mbar_ptr=storage.tmem_dealloc_mbar,
    )

    # Partition tensors for TMA; This requires the tensors partitioned for MMA
    tAsA, tAgA = cute.nvgpu.cpasync.tma_partition(
        tma_atom_a,
        cta_in_cluster_coord_vmnk[2],
        cute.make_layout(cute.size(cta_layout_vmnk, mode=[2])),
        cute.group_modes(sA, 0, 3),
        cute.group_modes(tCgA, 0, 3),
    )

    tBsB, tBgB = cute.nvgpu.cpasync.tma_partition(
        tma_atom_b,
        cta_in_cluster_coord_vmnk[1],
        cute.make_layout(cute.size(cta_layout_vmnk, mode=[1])),
        cute.group_modes(sB, 0, 3),
        cute.group_modes(tCgB, 0, 3),
    )

    # (EPI_TILE_M, EPI_TILE_N, EPI_M, EPI_N)
    tCgC_epi = cute.flat_divide(tCgC[((None, None), 0, 0)], epi_tile)

    tCsC, tCgC_tma = cute.nvgpu.cpasync.tma_partition(
        tma_atom_c,
        0,
        cute.make_layout(1),
        cute.group_modes(sC, 0, 2),
        cute.group_modes(tCgC_epi, 0, 2),
    )

    num_tma_copy_bytes = (
        cute.size_in_bytes(io_dtype, cute.select(a_smem_layout, mode=[0, 1, 2]))
        + cute.size_in_bytes(io_dtype, cute.select(b_smem_layout, mode=[0, 1, 2]))
    ) * cute.size(cta_layout_vmnk, mode=[0])

    # Threads/warps participating in the mainloop pipeline
    mainloop_pipeline_producer_group = pipeline.CooperativeGroup(pipeline.Agent.Thread)
    mainloop_pipeline_consumer_group = pipeline.CooperativeGroup(
        pipeline.Agent.Thread, size=num_mcast_participants
    )

    ab_producer, ab_consumer = pipeline.PipelineTmaUmma.create(
        barrier_storage=storage.ab_mbar_ptr.data_ptr(),
        num_stages=ab_stages,
        producer_group=mainloop_pipeline_producer_group,
        consumer_group=mainloop_pipeline_consumer_group,
        tx_count=num_tma_copy_bytes,
        cta_layout_vmnk=cta_layout_vmnk,
    ).make_participants()

    # Threads/warps participating in the accumulator pipeline
    acc_pipeline_producer_group = pipeline.CooperativeGroup(pipeline.Agent.Thread)
    acc_pipeline_consumer_group = pipeline.CooperativeGroup(
        pipeline.Agent.Thread,
        size=cute.size(cta_layout_vmnk, mode=[0]) * len(epilogue_warp_ids),
    )

    acc_producer, acc_consumer = pipeline.PipelineUmmaAsync.create(
        barrier_storage=storage.acc_mbar_ptr.data_ptr(),
        num_stages=acc_stages,
        producer_group=acc_pipeline_producer_group,
        consumer_group=acc_pipeline_consumer_group,
        cta_layout_vmnk=cta_layout_vmnk,
    ).make_participants()

    #
    # Main loop
    #

    num_k_tiles = cute.size(gA, mode=[2])

    # TMA warp
    if warp_idx == tma_warp_id:
        for k_tile_idx in range(num_k_tiles):
            # Wait for A/B buffers to be empty before loading into them
            handle = ab_producer.acquire_and_advance()

            # Issue TMA loads
            cute.copy(
                tma_atom_a,
                tAgA[(None, k_tile_idx)],
                tAsA[(None, handle.index)],
                tma_bar_ptr=handle.barrier,
                mcast_mask=tma_mcast_mask_a,
            )
            cute.copy(
                tma_atom_b,
                tBgB[(None, k_tile_idx)],
                tBsB[(None, handle.index)],
                tma_bar_ptr=handle.barrier,
                mcast_mask=tma_mcast_mask_b,
            )

        # This mbarrier_wait is preventing threadblocks within a set of dependent threadblocks within the cluster
        # (dependent in the context of the TMA/MMA synchronization pattern) to exit early making
        # a late tcgen05 commit_arrive illegal
        ab_producer.tail()

    # MMA warp
    elif warp_idx == mma_warp_id:
        # Wait for TMEM allocation and retrieve pointer
        tmem.wait_for_alloc()
        tmem_ptr = tmem.retrieve_ptr(acc_dtype)
        tCtAcc = cute.make_tensor(tmem_ptr, tCtAcc_fake.layout)

        # Wait for an empty accumulator buffer
        if is_leader_cta:
            acc_empty = acc_producer.acquire_and_advance()

            for k_tile_idx in range(num_k_tiles):
                # Wait for TMA copies to complete
                handle = ab_consumer.wait_and_advance()

                # Execute one K-block worth of MMA instructions
                tiled_mma.set(tcgen05.Field.ACCUMULATE, k_tile_idx != 0)
                tile_crd = (None, None, None, handle.index)
                cute.gemm(tiled_mma, tCtAcc, tCrA[tile_crd], tCrB[tile_crd], tCtAcc)

                # Signal that the A/B buffers have been consumed and are ready for the next load
                handle.release()

            # Signal that the accumulator is fully computed
            acc_empty.commit()

    # Epilogue warps
    elif warp_idx < mma_warp_id:
        # Allocate TMEM (only epilogue warp 0 actually allocates)
        num_tmem_cols = 512
        tmem.allocate(num_tmem_cols)

        # Wait for TMEM allocation and retrieve pointer
        tmem.wait_for_alloc()
        tmem_ptr = tmem.retrieve_ptr(acc_dtype)
        tCtAcc = cute.make_tensor(tmem_ptr, tCtAcc_fake.layout)

        # Initialize TMA store pipeline for epilogue
        epilogue_pipeline_producer_group = pipeline.CooperativeGroup(
            pipeline.Agent.Thread,
            size=128,
        )
        epilogue_pipeline = pipeline.PipelineTmaStore.create(
            num_stages=epi_stages,
            producer_group=epilogue_pipeline_producer_group,
        )

        # Wait for the accumulator buffer to be full
        acc_consumer.wait_and_advance()

        copy_atom_t2r = cute.make_copy_atom(
            tcgen05.Ld16x256bOp(tcgen05.Repetition.x8)
            if mma_tiler_mnk[0] == 64
            else tcgen05.Ld32x32bOp(tcgen05.Repetition.x32),
            cutlass.Float32,
        )

        # (EPI_TILE_M, EPI_TILE_N, EPI_M, EPI_N)
        tCtAcc_epi = cute.flat_divide(
            tCtAcc[((None, None), 0, 0)],
            epi_tile,
        )

        # Tiled copy for TMEM -> RMEM load
        tiled_copy_t2r = tcgen05.make_tmem_copy(
            copy_atom_t2r, tCtAcc_epi[(None, None, 0, 0)]
        )
        thr_copy_t2r = tiled_copy_t2r.get_slice(tidx)
        # (T2R, T2R_M, T2R_N, EPI_M, EPI_N)
        tTR_tAcc = thr_copy_t2r.partition_S(tCtAcc_epi)
        # (T2R, T2R_M, T2R_N, EPI_M, EPI_N)
        tTR_gC = thr_copy_t2r.partition_D(tCgC_epi)
        # (T2R, T2R_M, T2R_N)
        tTR_rAcc = cute.make_rmem_tensor(
            tTR_gC[(None, None, None, 0, 0)].shape, cutlass.Float32
        )
        tTR_tAcc = cute.group_modes(tTR_tAcc, 3, cute.rank(tTR_tAcc))

        # Copy atom and tiled copy for RMEM -> SMEM load
        copy_atom_r2s = cutlass.utils.blackwell_helpers.get_smem_store_op(
            c_smem_layout_kind, cutlass.Float32, cutlass.Float32, tiled_copy_t2r
        )
        tiled_copy_r2s = cute.make_tiled_copy_D(copy_atom_r2s, tiled_copy_t2r)
        # (R2S, R2S_M, R2S_N, PIPE_D)
        thr_copy_r2s = tiled_copy_r2s.get_slice(tidx)
        tRS_sC = thr_copy_r2s.partition_D(sC)

        tRS_rAcc = tiled_copy_r2s.retile(tTR_rAcc)
        tRS_rC = cute.make_rmem_tensor(tRS_rAcc.shape, io_dtype)

        tCgC_grouped = cute.group_modes(tCgC_tma, 1, cute.rank(tCgC_tma))

        subtile_cnt = cute.size(tTR_tAcc.shape, mode=[3])

        # Epilogue tiling loop
        for subtile_idx in cutlass.range(subtile_cnt):
            # TMEM -> RMEM
            tTR_tAcc_slice = tTR_tAcc[(None, None, None, subtile_idx)]
            cute.copy(tiled_copy_t2r, tTR_tAcc_slice, tTR_rAcc)

            # RMEM -> SMEM
            c_buffer = subtile_idx % epi_stages
            tRS_sC_slice = tRS_sC[(None, None, None, c_buffer)]

            # type conversion
            tRS_rC.store(tRS_rAcc.load().to(io_dtype))

            cute.copy(tiled_copy_r2s, tRS_rC, tRS_sC_slice)

            # Memory fence and barrier to ensure shared memory stores are visible to TMA stores
            cute.arch.fence_view_async_shared()
            epilogue_sync_barrier.arrive_and_wait()
            # SMEM -> GMEM
            if warp_idx == epilogue_warp_ids[0]:
                cute.copy(
                    tma_atom_c,
                    tCsC[(None, c_buffer)],
                    tCgC_grouped[(None, subtile_idx)],
                )

                epilogue_pipeline.producer_commit()
                epilogue_pipeline.producer_acquire()
            epilogue_sync_barrier.arrive_and_wait()

        epilogue_pipeline.producer_tail()

        # Dealloc the tensor memory buffer
        tmem.relinquish_alloc_permit()
        tmem.free(tmem_ptr)


@cute.jit
def host_function(
    a: cute.Tensor,
    b: cute.Tensor,
    c: cute.Tensor,
):
    #
    # Construct tiled MMA
    #

    op = tcgen05.MmaF16BF16Op(
        io_dtype,
        acc_dtype,
        mma_inst_shape_mnk,
        tcgen05.CtaGroup.TWO if use_2cta_instrs else tcgen05.CtaGroup.ONE,
        tcgen05.OperandSource.SMEM,
        tcgen05.OperandMajorMode.K,
        tcgen05.OperandMajorMode.K,
    )
    tiled_mma = cute.make_tiled_mma(op)

    #
    # Construct SMEM layouts for A and B
    #

    a_smem_layout = sm100_utils.make_smem_layout_a(
        tiled_mma,
        mma_tiler_mnk,
        a.element_type,
        ab_stages,
    )
    b_smem_layout = sm100_utils.make_smem_layout_b(
        tiled_mma,
        mma_tiler_mnk,
        b.element_type,
        ab_stages,
    )

    # c_smem_layout_kind is an enum for row/column major, not a CuTe layout
    c_smem_layout_kind = utils.LayoutEnum.from_tensor(c)

    #
    # Construct the VMNK layout
    #

    cta_layout_mnk = cute.make_layout(cluster_shape_mnk)
    cta_layout_vmnk = cute.tiled_divide(cta_layout_mnk, (tiled_mma.thr_id,))

    #
    # Construct TMA load atoms
    #

    op = cute.nvgpu.cpasync.CopyBulkTensorTileG2SMulticastOp(
        tcgen05.CtaGroup.TWO if use_2cta_instrs else tcgen05.CtaGroup.ONE
    )
    a_smem_layout_slice = cute.slice_(a_smem_layout, (None, None, None, 0))
    a_tma_atom, a_tma_tensor = cute.nvgpu.make_tiled_tma_atom_A(
        op,
        a,
        a_smem_layout_slice,
        mma_tiler_mnk,
        tiled_mma,
        cta_layout_vmnk.shape,  # take the layout and extract the shape internally

    )
    b_smem_layout_slice = cute.slice_(b_smem_layout, (None, None, None, 0))
    b_tma_atom, b_tma_tensor = cute.nvgpu.make_tiled_tma_atom_B(
        op,
        b,
        b_smem_layout_slice,
        mma_tiler_mnk,
        tiled_mma,
        cta_layout_vmnk.shape,
    )

    cta_tile_shape_mnk = (
        mma_tiler_mnk[0] // cute.size(tiled_mma.thr_id),
        mma_tiler_mnk[1],
        mma_tiler_mnk[2],
    )

    epi_tile = utils.compute_epilogue_tile_shape(
        cta_tile_shape_mnk,
        use_2cta_instrs,
        c_smem_layout_kind,
        io_dtype,
    )

    epi_smem_layout_staged = cutlass.utils.blackwell_helpers.make_smem_layout_epi(
        io_dtype,
        c_smem_layout_kind,
        epi_tile,
        epi_stages,
    )
    epi_smem_layout = cute.slice_(epi_smem_layout_staged, (None, None, 0))

    c_tma_atom, c_tma_tensor = cute.nvgpu.cpasync.make_tiled_tma_atom(
        cute.nvgpu.cpasync.CopyBulkTensorTileS2GOp(),
        c,
        epi_smem_layout,
        epi_tile,
    )

    #
    # Launch the kernel
    #

    grid_shape = cute.round_up(
        (
            cute.ceil_div(
                c.layout.shape[0], mma_tiler_mnk[0] // (2 if use_2cta_instrs else 1)
            ),
            cute.ceil_div(c.layout.shape[1], mma_tiler_mnk[1]),
            1,
        ),
        cluster_shape_mnk,
    )

    kernel(
        tiled_mma,
        a_tma_atom,
        a_tma_tensor,
        b_tma_atom,
        b_tma_tensor,
        c_tma_atom,
        c_tma_tensor,
        a_smem_layout,
        b_smem_layout,
        c_smem_layout_kind,
        epi_smem_layout_staged,
        epi_tile,
        cta_layout_vmnk,
    ).launch(
        grid=grid_shape,
        block=[192, 1, 1],
        cluster=cluster_shape_mnk,
    )


def run_dense_gemm(
    mnk: Tuple[int, int, int],
    tolerance: float,
):
    global torch, cutlass_torch
    import torch
    import cutlass.torch as cutlass_torch

    print("===================================================================")
    print("Running Blackwell fp16 GEMM example 2 with:")
    print(f"  mnk:       {mnk}")
    print(f"  tolerance: {tolerance}")
    print("===================================================================")
    print()

    m, n, k = mnk
    torch.manual_seed(1111)

    # Make K-major tensors (torch tensors are row-major)
    def make_tensors(mn, k, dtype):
        shape = (mn, k)
        return (
            torch.empty(*shape, dtype=torch.int32)
            .random_(-2, 2)
            .to(device="cuda", dtype=dtype)
        )

    a = make_tensors(m, k, cutlass_torch.dtype(io_dtype))
    b = make_tensors(n, k, cutlass_torch.dtype(io_dtype))
    c = make_tensors(m, n, cutlass_torch.dtype(io_dtype))
    a_memref = from_dlpack(a).mark_layout_dynamic()
    b_memref = from_dlpack(b).mark_layout_dynamic()
    c_memref = from_dlpack(c).mark_layout_dynamic()

    # Entry point to the host JIT function
    host_function(
        a_memref,
        b_memref,
        c_memref,
        no_cache=True,
    )

    # Compute reference result and verify
    ref = (torch.einsum("mk,nk->mn", a, b)).cpu()
    torch.testing.assert_close(
        c.cpu(), ref.to(cutlass_torch.dtype(io_dtype)), atol=tolerance, rtol=1e-05
    )


if __name__ == "__main__":

    def parse_comma_separated_ints(s: str) -> list[int]:
        try:
            return [int(x.strip()) for x in s.split(",")]
        except ValueError:
            raise argparse.ArgumentTypeError(
                "Invalid format. Expected comma-separated integers."
            )

    from cuda.bindings import driver as cu_driver

    cu_driver.cuInit(0)
    err, device_count = cu_driver.cuDeviceGetCount()
    if err != cu_driver.CUresult.CUDA_SUCCESS or device_count < 1:
        raise RuntimeError("A GPU is required to run this example")

    parser = argparse.ArgumentParser(description="Blackwell fp16 GEMM example 2")
    parser.add_argument(
        "--mnk",
        type=parse_comma_separated_ints,
        default=(8192, 8192, 8192),
        help="MNK dimensions (comma-separated)",
    )
    parser.add_argument(
        "--tolerance", type=float, default=1e-01, help="Tolerance for validation"
    )
    args = parser.parse_args()
    if len(args.mnk) != 3:
        parser.error("--mnk must contain exactly 3 values")

    run_dense_gemm(
        args.mnk,
        args.tolerance,
    )
    print("PASS")
