# SPDX-FileCopyrightText: Copyright (c) 2024 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# NVIDIA CORPORATION, its affiliates and licensors retain all intellectual
# property and proprietary rights in and to this material, related
# documentation and any modifications thereto. Any use, reproduction,
# disclosure or distribution of this material and related documentation
# without an express license agreement from NVIDIA CORPORATION or
# its affiliates is strictly prohibited.

# This is the fourth tutorial GEMM (4). It extends fp16_gemm_3_1.py by adding TMA prefetch.
# TMA prefetch uses cute.prefetch() to bring data into L2 cache before TMA copy needs it,
# helping to hide DRAM latency for memory-bound workloads.


import argparse
from typing import Tuple, Union

import cutlass
import cutlass.cute as cute
import cutlass.utils as utils
import cutlass.pipeline as pipeline
from cutlass.cute.nvgpu import cpasync, tcgen05
import cutlass.utils.blackwell_helpers as sm100_utils
from cutlass.cute.runtime import from_dlpack
from cutlass.pipeline import pipeline_init_arrive, pipeline_init_wait

"""
The fourth tutorial GEMM (4) demonstrates Preferred Cluster and Dynamic Cluster support in CuTeDSL.

With the introduction of NVIDIA Compute Capability 9.0, the CUDA programming model introduced
an optional hierarchy level known as Thread Block Clusters, which consist of multiple Thread Blocks.

Larger cluster shapes can achieve higher TMA multicast but may result in poor SM occupancy due
to quantization. For instance, a 2x2 cluster on an 18 SM GPU would only utilize 16 SMs, leaving
2 SMs idle.

Starting with Compute Capability 10.0, the CUDA programming model adds the ability to specify
two clusters: preferred cluster and fallback cluster. For brevity, we refer to this as
Preferred Clusters. In the previous example, users can now launch an additional 2x1 cluster to
utilize the 2 idle SMs.

Terminology
  * Static cluster: cluster shape is specified at compile time.
  * Dynamic cluster: cluster shape is specified at runtime and set by the host.
  * Preferred cluster: Kernel can be launched with two cluster shapes (preferred and fallback).

Preferred and fallback cluster shapes are subject to several constraints.
  * Preferred cluster depth (Z dimension) must be the same as that of fallback cluster.
  * Fallback cluster shape must evenly divide the preferred cluster shape.
  * Preferred cluster shape must evenly divide the kernel launch grid shape.

This example demonstrates how to use the Dynamic Clusters and Preferred Clusters features in
CuTe DSL Blackwell SM100 kernels. Users can specify preferred and fallback cluster shapes via kernel launch arguments.

To run this example:
.. code-block:: bash
    python examples/blackwell/tutorial_gemm/fp16_gemm_4.py  \
      --mnk 8192,8192,8192

Constraints for this example:
* The problem size of m and n must be divisible by the tile size m & n (256, 256)
"""

io_dtype = cutlass.Float16
acc_dtype = cutlass.Float32
use_2cta_instrs = True
fallback_cluster_shape_mnk = (2, 1, 1) if use_2cta_instrs else (1, 1, 1)
preferred_cluster_shape_mnk = (2, 4, 1) if use_2cta_instrs else (1, 1, 1)
mma_inst_shape_mnk = (256, 256, 16)
mma_tiler_mnk = (256, 256, 64)
threads_in_epilogue = 128  # epilogue threads per cta

# Pipeline stage configuration
ab_stages = 6
epi_stages = 2
acc_stages = 2
num_clc_stage = 1

# Scheduler
use_clc_dynamic_scheduler = True
scheduler_type = (
    utils.ClcDynamicPersistentTileScheduler
    if use_clc_dynamic_scheduler
    else utils.StaticPersistentTileScheduler
)
# Response size is 4B * 4 elements
num_clc_response_bytes = 16


@cute.struct
class SharedStorage:
    ab_mbar_ptr: cute.struct.MemRange[cutlass.Int64, ab_stages * 2]
    acc_mbar_ptr: cute.struct.MemRange[cutlass.Int64, acc_stages * 2]
    tmem_dealloc_mbar: cutlass.Int64
    tmem_holding_buffer: cutlass.Int32
    # Only for CLC Dynamic Scheduler
    clc_mbar_ptr: cute.struct.MemRange[cutlass.Int64, 2]
    clc_response: cute.struct.MemRange[cutlass.Int32, 4]


@cute.jit
def cluster_specific_kernel(
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
    cluster_shape_mnk: Tuple[int, int, int],
    tile_sched_params: Union[
        utils.ClcDynamicPersistentTileSchedulerParams,
        utils.PersistentTileSchedulerParams,
    ],
):
    warp_idx = cute.arch.warp_idx()
    warp_idx = cute.arch.make_warp_uniform(warp_idx)

    tidx, _, _ = cute.arch.thread_idx()
    bidx, _, _ = cute.arch.block_idx()

    cta_rank_in_cluster = cute.arch.block_idx_in_cluster()
    cta_in_cluster_coord_vmnk = cta_layout_vmnk.get_flat_coord(cta_rank_in_cluster)

    mma_tile_coord_v = bidx % cute.size(cta_layout_vmnk, mode=[0])
    is_leader_cta = mma_tile_coord_v == 0

    epilogue_warp_ids = (
        0,
        1,
        2,
        3,
    )
    mma_warp_id = 4
    tma_warp_id = 5
    # sched_warp_id only for dynamic scheduler
    sched_warp_id = 6

    epilog_sync_bar_id = 1
    tmem_alloc_sync_bar_id = 2

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

    # Allocate SMEM
    smem = cutlass.utils.SmemAllocator()
    storage = smem.allocate(SharedStorage)

    # Barrier 1 for epilogue synchronization
    epilogue_sync_barrier = pipeline.NamedBarrier(
        barrier_id=epilog_sync_bar_id,
        num_threads=threads_in_epilogue,
    )

    # Only MMA warp and epilogue warps participate in TMEM allocation synchronization
    # TMA warp does NOT participate
    tmem_alloc_barrier = pipeline.NamedBarrier(
        barrier_id=tmem_alloc_sync_bar_id,
        num_threads=32
        * len((mma_warp_id, *epilogue_warp_ids)),  # 5 warps = 160 threads
    )
    tmem = utils.TmemAllocator(
        storage.tmem_holding_buffer,
        barrier_for_retrieve=tmem_alloc_barrier,
        allocator_warp_id=epilogue_warp_ids[0],
        is_two_cta=True,
        two_cta_tmem_dealloc_mbar_ptr=storage.tmem_dealloc_mbar,
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

    # Initialize clc_pipeline (barrier) and states
    # ONLY for CLC Dynamic Scheduler
    if cutlass.const_expr(use_clc_dynamic_scheduler):
        clc_pipeline_producer_group = pipeline.CooperativeGroup(pipeline.Agent.Thread)
        cluster_size = cute.size(cluster_shape_mnk)
        num_clc_consumer_threads = 32 * len(
            (
                sched_warp_id,
                *(
                    cluster_size
                    * (
                        mma_warp_id,
                        tma_warp_id,
                        *epilogue_warp_ids,
                    )
                ),
            )
        )
        clc_pipeline_consumer_group = pipeline.CooperativeGroup(
            pipeline.Agent.Thread, num_clc_consumer_threads
        )
        clc_pipeline = pipeline.PipelineClcFetchAsync.create(
            barrier_storage=storage.clc_mbar_ptr.data_ptr(),
            num_stages=num_clc_stage,
            producer_group=clc_pipeline_producer_group,
            consumer_group=clc_pipeline_consumer_group,
            tx_count=num_clc_response_bytes,
            cta_layout_vmnk=cta_layout_vmnk,
            defer_sync=True,
        )
        # Initial clc response pointer
        clc_response_ptr = storage.clc_response.data_ptr()

        clc_consumer_state = pipeline.make_pipeline_state(
            pipeline.PipelineUserType.Consumer, num_clc_stage
        )
    else:
        clc_pipeline = None
        clc_response_ptr = None
        clc_consumer_state = None

    # Cluster arrive after barrier init
    pipeline_init_arrive(cluster_shape_mn=cluster_shape_mnk, is_relaxed=True)

    # Allocate SMEM
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

    # Partition tensors for MMA and make fragments
    # (bM, bK, RestM, RestK)
    gA = cute.local_tile(
        mA_mkl, cute.slice_(mma_tiler_mnk, (None, 0, None)), (None, None)
    )
    # (bN, bK, RestN, RestK)
    gB = cute.local_tile(
        mB_nkl, cute.slice_(mma_tiler_mnk, (0, None, None)), (None, None)
    )
    # (bM, bN, RestM, RestN)
    gC = cute.local_tile(
        mC_mnl, cute.slice_(mma_tiler_mnk, (None, None, 0)), (None, None)
    )

    thr_mma = tiled_mma.get_slice(mma_tile_coord_v)
    # (MMA, MMA_M, MMA_K, RestM, RestK)
    tCgA = thr_mma.partition_A(gA)
    # (MMA, MMA_N, MMA_K, RestN, RestK)
    tCgB = thr_mma.partition_B(gB)
    # (MMA, MMA_M, MMA_N, RestM, RestN)
    tCgC = thr_mma.partition_C(gC)

    # (MMA, MMA_M, MMA_K, STAGE)
    tCrA = tiled_mma.make_fragment_A(sA)
    # (MMA, MMA_N, MMA_K, STAGE)
    tCrB = tiled_mma.make_fragment_B(sB)

    # (MMA, MMA_M, MMA_N)
    acc_shape = tiled_mma.partition_shape_C(mma_tiler_mnk[:2])
    # (MMA, MMA_M, MMA_N, STAGE)
    tCtAcc_fake = tiled_mma.make_fragment_C(cute.append(acc_shape, acc_stages))

    # Partition tensors for TMA; This requires the tensors partitioned for MMA
    # ((atom_v, rest_v), STAGE)
    # ((atom_v, rest_v), RestM, RestK)
    tAsA, tAgA = cute.nvgpu.cpasync.tma_partition(
        tma_atom_a,
        cta_in_cluster_coord_vmnk[2],
        cute.make_layout(cute.size(cta_layout_vmnk, mode=[2])),
        cute.group_modes(sA, 0, 3),
        cute.group_modes(tCgA, 0, 3),
    )

    # ((atom_v, rest_v), STAGE)
    # ((atom_v, rest_v), RestN, RestK)
    tBsB, tBgB = cute.nvgpu.cpasync.tma_partition(
        tma_atom_b,
        cta_in_cluster_coord_vmnk[1],
        cute.make_layout(cute.size(cta_layout_vmnk, mode=[1])),
        cute.group_modes(sB, 0, 3),
        cute.group_modes(tCgB, 0, 3),
    )

    gC_epi = cute.flat_divide(tCgC[((None, None), 0, 0, None, None)], epi_tile)

    tCsC, tCgC_tma = cute.nvgpu.cpasync.tma_partition(
        tma_atom_c,
        0,
        cute.make_layout(1),
        cute.group_modes(sC, 0, 2),
        cute.group_modes(gC_epi, 0, 2),
    )

    # Cluster wait before starting work
    pipeline_init_wait(cluster_shape_mn=cluster_shape_mnk)

    # Construct the scheduler
    if cutlass.const_expr(use_clc_dynamic_scheduler):
        tile_sched = scheduler_type.create(
            tile_sched_params,
            cute.arch.block_idx(),
            cute.arch.grid_dim(),
            clc_response_ptr,
        )
    else:
        tile_sched = scheduler_type.create(
            tile_sched_params, cute.arch.block_idx(), cute.arch.grid_dim()
        )
    work_tile = tile_sched.initial_work_tile_info()

    #
    # Main loop
    #

    num_k_tiles = cute.size(gA, mode=[3])

    # TMA warp
    if warp_idx == tma_warp_id:
        #
        # Persistent tile scheduling loop
        #
        while work_tile.is_valid_tile:
            # Get tile coord from tile scheduler
            cur_tile_coord = work_tile.tile_idx
            mma_tile_coord_mnl = (
                cur_tile_coord[0] // cute.size(tiled_mma.thr_id.shape),
                cur_tile_coord[1],
                cur_tile_coord[2],
            )

            # Slice to per mma tile index
            # ((atom_v, rest_v), RestK)
            tAgA_slice = tAgA[(None, mma_tile_coord_mnl[0], None)]

            # ((atom_v, rest_v), RestK)
            tBgB_slice = tBgB[(None, mma_tile_coord_mnl[1], None)]

            for k_tile_idx in range(num_k_tiles):
                # Wait for A/B buffers to be empty before loading into them
                handle = ab_producer.acquire_and_advance()

                # Issue TMA loads
                cute.copy(
                    tma_atom_a,
                    tAgA_slice[(None, k_tile_idx)],
                    tAsA[(None, handle.index)],
                    tma_bar_ptr=handle.barrier,
                    mcast_mask=tma_mcast_mask_a,
                )
                cute.copy(
                    tma_atom_b,
                    tBgB_slice[(None, k_tile_idx)],
                    tBsB[(None, handle.index)],
                    tma_bar_ptr=handle.barrier,
                    mcast_mask=tma_mcast_mask_b,
                )

            # Advance to next tile
            if cutlass.const_expr(use_clc_dynamic_scheduler):
                clc_pipeline.consumer_wait(clc_consumer_state)
                work_tile = tile_sched.get_current_work()
                clc_pipeline.consumer_release(clc_consumer_state)
                clc_consumer_state.advance()
            else:
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()

        # This mbarrier_wait is preventing threadblocks within a set of dependent threadblocks within the cluster
        # (dependent in the context of the TMA/MMA synchronization pattern) to exit early making
        # a late tcgen05 commit_arrive illegal
        ab_producer.tail()

    # Sched warp (only for dynamic scheduler)
    if cutlass.const_expr(use_clc_dynamic_scheduler):
        is_first_cta_in_cluster = cta_rank_in_cluster == 0

        if warp_idx == sched_warp_id and is_first_cta_in_cluster:
            # Persistent tile scheduling loop
            clc_producer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.ProducerConsumer, num_clc_stage
            )
            while work_tile.is_valid_tile:
                # Advance to next tile
                clc_pipeline.producer_acquire(clc_producer_state)
                mbarrier_addr = clc_pipeline.producer_get_barrier(clc_producer_state)
                tile_sched.advance_to_next_work(mbarrier_addr)
                clc_producer_state.advance()

                clc_pipeline.consumer_wait(clc_consumer_state)
                work_tile = tile_sched.get_current_work()
                clc_pipeline.consumer_release(clc_consumer_state)
                clc_consumer_state.advance()
            clc_pipeline.producer_tail(clc_producer_state)

    # MMA warp
    if warp_idx == mma_warp_id:
        # Wait for TMEM allocation and retrieve pointer
        tmem.wait_for_alloc()
        tmem_ptr = tmem.retrieve_ptr(acc_dtype)
        # (MMA, MMA_M, MMA_N, STAGE)
        tCtAcc_base = cute.make_tensor(tmem_ptr, tCtAcc_fake.layout)

        while work_tile.is_valid_tile:
            if is_leader_cta:
                # Wait for accumulator buffer empty
                acc_empty = acc_producer.acquire_and_advance()

                # Set tensor memory buffer for current tile
                # (MMA, MMA_M, MMA_N)
                tCtAcc = tCtAcc_base[(None, None, None, acc_empty.index)]

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

            # Advance to next tile
            if cutlass.const_expr(use_clc_dynamic_scheduler):
                clc_pipeline.consumer_wait(clc_consumer_state)
                work_tile = tile_sched.get_current_work()
                clc_pipeline.consumer_release(clc_consumer_state)
                clc_consumer_state.advance()
            else:
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()

        # Wait for accumulator buffer empty
        acc_producer.tail()

    # Epilogue warps
    if warp_idx < mma_warp_id:
        # Allocate TMEM (only epilogue warp 0 actually allocates)
        num_tmem_cols = 512
        tmem.allocate(num_tmem_cols)

        # Wait for TMEM allocation and retrieve pointer
        tmem.wait_for_alloc()
        tmem_ptr = tmem.retrieve_ptr(acc_dtype)
        # (MMA, MMA_M, MMA_N, STAGE)
        tCtAcc_base = cute.make_tensor(tmem_ptr, tCtAcc_fake.layout)

        # Initialize TMA store pipeline for epilogue
        epilogue_pipeline_producer_group = pipeline.CooperativeGroup(
            pipeline.Agent.Thread,
            size=128,
        )
        epilogue_pipeline = pipeline.PipelineTmaStore.create(
            num_stages=epi_stages,
            producer_group=epilogue_pipeline_producer_group,
        )

        copy_atom_t2r = cute.make_copy_atom(
            tcgen05.Ld32x32bOp(tcgen05.Repetition.x32, tcgen05.Pack.NONE),
            cutlass.Float32,
        )

        while work_tile.is_valid_tile:
            # Get tile coord from tile scheduler
            cur_tile_coord = work_tile.tile_idx
            mma_tile_coord_mnl = (
                cur_tile_coord[0] // cute.size(tiled_mma.thr_id.shape),
                cur_tile_coord[1],
                cur_tile_coord[2],
            )

            # Wait for accumulator buffer full
            acc_full = acc_consumer.wait_and_advance()

            # Set tensor memory buffer for current tile
            # (MMA, MMA_M, MMA_N)
            tCtAcc = tCtAcc_base[(None, None, None, acc_full.index)]

            # (EPI_TILE_M, EPI_TILE_N, EPI_M, EPI_N)
            tCtAcc_epi = cute.flat_divide(
                tCtAcc[((None, None), 0, 0)],  # why 0,0 ?
                epi_tile,
            )

            mma_tile_coord_mn = cute.slice_(mma_tile_coord_mnl, (None, None, 0))
            # (EPI_TILE_M, EPI_TILE_N, EPI_M, EPI_N, RestM, RestN)
            tCgC_epi = cute.flat_divide(
                tCgC[((None, None), 0, 0, *mma_tile_coord_mn)], epi_tile
            )

            tCgC_tma_cur_tile = tCgC_tma[(None, None, None, *mma_tile_coord_mn)]

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
            tCgC_grouped = cute.group_modes(
                tCgC_tma_cur_tile, 1, cute.rank(tCgC_tma_cur_tile)
            )

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

            # Async arrive accumulator buffer empty
            with cute.arch.elect_one():
                acc_full.release()

            # Advance to next tile
            if cutlass.const_expr(use_clc_dynamic_scheduler):
                clc_pipeline.consumer_wait(clc_consumer_state)
                work_tile = tile_sched.get_current_work()
                clc_pipeline.consumer_release(clc_consumer_state)
                clc_consumer_state.advance()
            else:
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()

        # Wait for C store complete
        epilogue_pipeline.producer_tail()

        # Dealloc the tensor memory buffer
        tmem.relinquish_alloc_permit()
        tmem.free(tmem_ptr)


@cute.kernel
def kernel(
    tiled_mma: cute.TiledMma,
    tma_atom_a_preferred: cute.CopyAtom,
    mA_mkl_preferred: cute.Tensor,
    tma_atom_b_preferred: cute.CopyAtom,
    mB_nkl_preferred: cute.Tensor,
    tma_atom_a_fallback: cute.CopyAtom,
    mA_mkl_fallback: cute.Tensor,
    tma_atom_b_fallback: cute.CopyAtom,
    mB_nkl_fallback: cute.Tensor,
    tma_atom_c: cute.CopyAtom,
    mC_mnl: cute.Tensor,
    a_smem_layout: cute.ComposedLayout,
    b_smem_layout: cute.ComposedLayout,
    c_smem_layout_kind: cutlass.Constexpr,
    epi_smem_layout_staged: cute.ComposedLayout,
    epi_tile: cute.Tile,
    preferred_cta_layout_vmnk: cute.Layout,
    fallback_cta_layout_vmnk: cute.Layout,
    preferred_tile_sched_params: Union[
        utils.ClcDynamicPersistentTileSchedulerParams,
        utils.PersistentTileSchedulerParams,
    ],
    fallback_tile_sched_params: Union[
        utils.ClcDynamicPersistentTileSchedulerParams,
        utils.PersistentTileSchedulerParams,
    ],
):
    # Get cluster coord to determine if this is a preferred cluster
    cbdim_x, cbdim_y, cbdim_z = cute.arch.block_in_cluster_dim()
    is_preferred_cluster = (
        cbdim_x == preferred_cluster_shape_mnk[0]
        and cbdim_y == preferred_cluster_shape_mnk[1]
        and cbdim_z == preferred_cluster_shape_mnk[2]
    )

    # As for now, only support preferred cluster kernel via the mega-kernel approach
    if is_preferred_cluster:
        cluster_specific_kernel(
            tiled_mma,
            tma_atom_a_preferred,
            mA_mkl_preferred,
            tma_atom_b_preferred,
            mB_nkl_preferred,
            tma_atom_c,
            mC_mnl,
            a_smem_layout,
            b_smem_layout,
            c_smem_layout_kind,
            epi_smem_layout_staged,
            epi_tile,
            preferred_cta_layout_vmnk,
            preferred_cluster_shape_mnk,
            preferred_tile_sched_params,
        )
    else:
        cluster_specific_kernel(
            tiled_mma,
            tma_atom_a_fallback,
            mA_mkl_fallback,
            tma_atom_b_fallback,
            mB_nkl_fallback,
            tma_atom_c,
            mC_mnl,
            a_smem_layout,
            b_smem_layout,
            c_smem_layout_kind,
            epi_smem_layout_staged,
            epi_tile,
            fallback_cta_layout_vmnk,
            fallback_cluster_shape_mnk,
            fallback_tile_sched_params,
        )


def compute_grid(
    c: cute.Tensor,
    cta_tiler_mnk: Tuple[int, int, int],
    preferred_cluster_shape_mnk: Tuple[int, int, int],
    fallback_cluster_shape_mnk: Tuple[int, int, int],
    scheduler_type: Union[
        utils.StaticPersistentTileScheduler, utils.ClcDynamicPersistentTileScheduler
    ],
    preferred_max_active_clusters: cutlass.Constexpr,
    fallback_max_active_clusters: cutlass.Constexpr,
) -> Tuple[
    Union[
        utils.ClcDynamicPersistentTileSchedulerParams,
        utils.PersistentTileSchedulerParams,
    ],
    Tuple[int, int, int],
    Union[
        utils.ClcDynamicPersistentTileSchedulerParams,
        utils.PersistentTileSchedulerParams,
    ],
    Tuple[int, int, int],
]:
    c_shape = cute.slice_(cta_tiler_mnk, (None, None, 0))
    gc = cute.zipped_divide(c, tiler=c_shape)
    num_ctas_mn = gc[(0, (None, None))].shape

    # Compute scheduler parameters for preferred cluster
    if cutlass.const_expr(
        issubclass(scheduler_type, utils.ClcDynamicPersistentTileScheduler)
    ):
        preferred_tile_sched_params = utils.ClcDynamicPersistentTileSchedulerParams(
            (*num_ctas_mn, 1), preferred_cluster_shape_mnk
        )
        preferred_grid = utils.ClcDynamicPersistentTileScheduler.get_grid_shape(
            preferred_tile_sched_params
        )
    else:
        preferred_tile_sched_params = utils.PersistentTileSchedulerParams(
            (*num_ctas_mn, 1), preferred_cluster_shape_mnk
        )
        preferred_grid = utils.StaticPersistentTileScheduler.get_grid_shape(
            preferred_tile_sched_params, preferred_max_active_clusters
        )

    # Compute scheduler parameters for fallback cluster
    if cutlass.const_expr(
        issubclass(scheduler_type, utils.ClcDynamicPersistentTileScheduler)
    ):
        fallback_tile_sched_params = utils.ClcDynamicPersistentTileSchedulerParams(
            (*num_ctas_mn, 1), fallback_cluster_shape_mnk
        )
        fallback_grid = utils.ClcDynamicPersistentTileScheduler.get_grid_shape(
            fallback_tile_sched_params
        )
    else:
        # Need to use preferred tile sched params for static scheduler
        fallback_tile_sched_params = utils.PersistentTileSchedulerParams(
            (*num_ctas_mn, 1), preferred_cluster_shape_mnk
        )
        fallback_grid = utils.StaticPersistentTileScheduler.get_grid_shape(
            fallback_tile_sched_params, fallback_max_active_clusters
        )

    return (
        preferred_tile_sched_params,
        preferred_grid,
        fallback_tile_sched_params,
        fallback_grid,
    )


@cute.jit
def host_function(
    a: cute.Tensor,
    b: cute.Tensor,
    c: cute.Tensor,
    preferred_max_active_clusters: cutlass.Constexpr,
    fallback_max_active_clusters: cutlass.Constexpr,
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

    fallback_cta_layout_mnk = cute.make_layout(fallback_cluster_shape_mnk)
    fallback_cta_layout_vmnk = cute.tiled_divide(
        fallback_cta_layout_mnk, (tiled_mma.thr_id,)
    )

    preferred_cta_layout_mnk = cute.make_layout(preferred_cluster_shape_mnk)
    preferred_cta_layout_vmnk = cute.tiled_divide(
        preferred_cta_layout_mnk, (tiled_mma.thr_id,)
    )

    #
    # Construct TMA load atoms
    #

    op = cute.nvgpu.cpasync.CopyBulkTensorTileG2SMulticastOp(
        tcgen05.CtaGroup.TWO if use_2cta_instrs else tcgen05.CtaGroup.ONE
    )
    a_smem_layout_slice = cute.slice_(a_smem_layout, (None, None, None, 0))
    tma_atom_a_fallback, a_tma_tensor_fallback = cute.nvgpu.make_tiled_tma_atom_A(
        op,
        a,
        a_smem_layout_slice,
        mma_tiler_mnk,
        tiled_mma,
        fallback_cta_layout_vmnk.shape,
    )
    b_smem_layout_slice = cute.slice_(b_smem_layout, (None, None, None, 0))
    tma_atom_b_fallback, b_tma_tensor_fallback = cute.nvgpu.make_tiled_tma_atom_B(
        op,
        b,
        b_smem_layout_slice,
        mma_tiler_mnk,
        tiled_mma,
        fallback_cta_layout_vmnk.shape,
    )

    tma_atom_a_preferred, a_tma_tensor_preferred = cute.nvgpu.make_tiled_tma_atom_A(
        op,
        a,
        a_smem_layout_slice,
        mma_tiler_mnk,
        tiled_mma,
        preferred_cta_layout_vmnk.shape,
    )
    tma_atom_b_preferred, b_tma_tensor_preferred = cute.nvgpu.make_tiled_tma_atom_B(
        op,
        b,
        b_smem_layout_slice,
        mma_tiler_mnk,
        tiled_mma,
        preferred_cta_layout_vmnk.shape,
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

    tma_atom_c, c_tma_tensor = cute.nvgpu.cpasync.make_tiled_tma_atom(
        cute.nvgpu.cpasync.CopyBulkTensorTileS2GOp(),
        c,
        epi_smem_layout,
        epi_tile,
    )

    #
    # Launch the kernel
    #

    (
        tile_sched_params_preferred,
        grid_shape_preferred,
        tile_sched_params_fallback,
        grid_shape_fallback,
    ) = compute_grid(
        c,
        cta_tile_shape_mnk,
        preferred_cluster_shape_mnk,
        fallback_cluster_shape_mnk,
        scheduler_type,
        preferred_max_active_clusters,
        fallback_max_active_clusters,
    )

    kernel(
        tiled_mma,
        tma_atom_a_preferred,
        a_tma_tensor_preferred,
        tma_atom_b_preferred,
        b_tma_tensor_preferred,
        tma_atom_a_fallback,
        a_tma_tensor_fallback,
        tma_atom_b_fallback,
        b_tma_tensor_fallback,
        tma_atom_c,
        c_tma_tensor,
        a_smem_layout,
        b_smem_layout,
        c_smem_layout_kind,
        epi_smem_layout_staged,
        epi_tile,
        preferred_cta_layout_vmnk,
        fallback_cta_layout_vmnk,
        tile_sched_params_preferred,
        tile_sched_params_fallback,
    ).launch(
        grid=grid_shape_preferred,
        block=[224, 1, 1] if use_clc_dynamic_scheduler else [192, 1, 1],
        cluster=preferred_cluster_shape_mnk,
        fallback_cluster=fallback_cluster_shape_mnk,
    )


def run_dense_gemm(
    mnk: Tuple[int, int, int],
    tolerance: float,
):
    global torch, cutlass_torch
    import torch
    import cutlass.torch as cutlass_torch

    print("===================================================================")
    print("Running Blackwell fp16 GEMM example 4 (with MIX CGA support):")
    print(f"  mnk:                        {mnk}")
    print(f"  tolerance:                  {tolerance}")
    print(f"  Preferred cluster shape:    {preferred_cluster_shape_mnk}")
    print(f"  Fallback cluster shape:     {fallback_cluster_shape_mnk}")
    print(f"  CTA tile shape (MNK):       {mma_tiler_mnk}")
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

    preferred_max_active_clusters = utils.HardwareInfo().get_max_active_clusters(
        preferred_cluster_shape_mnk[0] * preferred_cluster_shape_mnk[1]
    )
    fallback_max_active_clusters = utils.HardwareInfo().get_max_active_clusters(
        fallback_cluster_shape_mnk[0] * fallback_cluster_shape_mnk[1]
    )

    # Entry point to the host JIT function
    host_function(
        a_memref,
        b_memref,
        c_memref,
        preferred_max_active_clusters,
        fallback_max_active_clusters,
        no_cache=True,
    )

    # Compute reference result and verify
    print("Verifying reference result...")
    ref = (torch.einsum("mk,nk->mn", a, b)).cpu()
    torch.testing.assert_close(
        c.cpu(), ref.to(cutlass_torch.dtype(io_dtype)), atol=tolerance, rtol=1e-05
    )


if __name__ == "__main__":

    def parse_comma_separated_ints(s: str):
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

    parser = argparse.ArgumentParser(
        description="Blackwell fp16 GEMM example 4 (with TMA prefetch)"
    )
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
