# Copyright (c) 2024 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:

# 1. Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.

# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.

# 3. Neither the name of the copyright holder nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.

# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# This is the second tutorial GEMM. It builds on the first tutorial by adding 2CTA MMA
# instructions with a 2x1 cluster.


import argparse
from typing import Tuple

import cutlass
import cutlass.cute as cute
import cutlass.utils as utils
import cutlass.pipeline as pipeline
from cutlass.cute.nvgpu import cpasync, tcgen05, OperandMajorMode
import cutlass.utils.blackwell_helpers as sm100_utils
from cutlass.cute.runtime import from_dlpack

"""
The second tutorial GEMM demonstrating a simple kernel implementation in CuTeDSL

With large tile sizes, it can as well achieve very high performance on 8kx8kx8k problem sizes.
Compared with fp16_gemm_0.py, this example adds 2CTA MMA & TMA multicast supports.
For fp16_gemm_0.py running at relative high SM frequency, the dram latency will be a potential performance issue.
This example can achieve better performance than fp16_gemm_0.py due to:

1. The 2CTA MMA can reduce B tensor smem size which allows larger ab stages to hide dram latency.

For both 1CTA & 2CTA, one stage of A tensor smem size is 128x64xsizeof(float16)=16KB
Situation for B is different.
For 1CTA, one stage of B tensor smem size is 256x64xsizeof(float16)=32KB,
while for 2CTA, we can only take half size, i.e. 16KB.
So, the maxmimum AB stage for 1CTA is 227 // (16 + 32) = 4, while for 2CTA is 227 // (16 + 16) = 7.
The latency hiding capability is 512 * (4 - 1) = 1.5K cycles for 1CTA, while 512 * (7 - 1) = 3K cycles for 2CTA.

2. The L2 traffic is reduced due to the TMA multicast.

For a (m, n) cluster shape, the L2 traffic for one tile is 16KB / n + 32KB / m.

16KB / 1 + 32KB / 2 = 24KB for 2x1 cluster shape
16KB / 4 + 32KB / 4 = 12KB for 4x4 cluster shape

If no TMA multicast enabled, the L2 traffic for one tile is less than 16KB + 32KB = 48KB, which depends on hardware optimization.

The first one can provide large latency hiding capability while the second one can reduce the data ready time.
These two factors should be considered for latency/memory throughput bound cases.


To run this example:
.. code-block:: bash

    python examples/cute/blackwell/tutorial/tutorial_gemm/fp16_gemm_1.py  \
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
threads_per_cta = 128

# Pipeline stage configuration
ab_stages = 7
acc_stage = 1


@cute.struct
class SharedStorage:
    ab_mbar_ptr: cute.struct.MemRange[cutlass.Int64, ab_stages * 2]
    acc_mbar_ptr: cute.struct.MemRange[cutlass.Int64, acc_stage * 2]
    tmem_dealloc_mbar: cutlass.Int64
    tmem_holding_buf: cutlass.Int32


@cute.kernel()
def kernel(
    tiled_mma: cute.TiledMma,
    tma_a: cpasync.TmaInfo,
    tma_b: cpasync.TmaInfo,
    mC_mnl: cute.Tensor,
    cta_layout_vmnk: cute.Layout,
):
    cute.experimental.iket.range_push("prologue")
    # Extract tma_tensor from TmaInfo
    mA_mkl = tma_a.tma_tensor
    mB_nkl = tma_b.tma_tensor

    # Current thread/warp/block coordinates
    tidx, _, _ = cute.arch.thread_idx()
    warp_idx = cute.arch.warp_idx()
    warp_idx = cute.arch.make_warp_uniform(warp_idx)
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

    #
    # 1. Prepare args
    #

    # Allocate SMEM
    smem = cutlass.utils.SmemAllocator()
    storage = smem.allocate(SharedStorage)
    sA = smem.allocate_tensor(
        element_type=io_dtype,
        layout=tma_a.smem_layout.outer,
        byte_alignment=128,
        swizzle=tma_a.smem_layout.inner,
    )
    sB = smem.allocate_tensor(
        element_type=io_dtype,
        layout=tma_b.smem_layout.outer,
        byte_alignment=128,
        swizzle=tma_b.smem_layout.inner,
    )

    # Prefetch tma descriptor
    if warp_idx == 0:
        cpasync.prefetch_descriptor(tma_a.atom)
        cpasync.prefetch_descriptor(tma_b.atom)

    # Pipeline configuration
    num_tma_copy_bytes = (
        cute.size_in_bytes(io_dtype, cute.select(tma_a.smem_layout, mode=[0, 1, 2]))
        + cute.size_in_bytes(io_dtype, cute.select(tma_b.smem_layout, mode=[0, 1, 2]))
    ) * cute.size(cta_layout_vmnk, mode=[0])
    num_mcast_ctas_a = cute.size(cta_layout_vmnk.shape[2])
    num_mcast_ctas_b = cute.size(cta_layout_vmnk.shape[1])
    num_tma_producer = num_mcast_ctas_a + num_mcast_ctas_b - 1
    ab_producer, ab_consumer = pipeline.PipelineTmaUmma.create(
        num_stages=ab_stages,
        producer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread),
        consumer_group=pipeline.CooperativeGroup(
            pipeline.Agent.Thread, num_tma_producer
        ),
        tx_count=num_tma_copy_bytes,
        barrier_storage=storage.ab_mbar_ptr.data_ptr(),
        cta_layout_vmnk=cta_layout_vmnk,
    ).make_participants()
    acc_producer, acc_consumer = pipeline.PipelineUmmaAsync.create(
        num_stages=acc_stage,
        producer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread),
        consumer_group=pipeline.CooperativeGroup(
            pipeline.Agent.ThreadBlock,
            cute.size(cta_layout_vmnk, mode=[0]),
        ),
        barrier_storage=storage.acc_mbar_ptr.data_ptr(),
        cta_layout_vmnk=cta_layout_vmnk,
    ).make_participants()

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
    tCtAcc = tiled_mma.make_fragment_C(acc_shape)

    # Partition tensors for TMA; This requires the tensors partitioned for MMA
    tAsA, tAgA = cute.nvgpu.cpasync.tma_partition(
        tma_a.atom,
        cta_in_cluster_coord_vmnk[2],
        cute.make_layout(cute.size(cta_layout_vmnk, mode=[2])),
        cute.group_modes(sA, 0, 3),
        cute.group_modes(tCgA, 0, 3),
    )
    tBsB, tBgB = cute.nvgpu.cpasync.tma_partition(
        tma_b.atom,
        cta_in_cluster_coord_vmnk[1],
        cute.make_layout(cute.size(cta_layout_vmnk, mode=[1])),
        cute.group_modes(sB, 0, 3),
        cute.group_modes(tCgB, 0, 3),
    )
    tma_mcast_mask_a = cute.nvgpu.cpasync.create_tma_multicast_mask(
        cta_layout_vmnk, cta_in_cluster_coord_vmnk, mcast_mode=2
    )
    tma_mcast_mask_b = cute.nvgpu.cpasync.create_tma_multicast_mask(
        cta_layout_vmnk, cta_in_cluster_coord_vmnk, mcast_mode=1
    )

    # Allocate TMEM and swap the pointer in tCtAcc
    tmem_alloc_barrier = pipeline.NamedBarrier(
        barrier_id=1,
        num_threads=threads_per_cta,
    )
    tmem = utils.TmemAllocator(
        storage.tmem_holding_buf.ptr,
        barrier_for_retrieve=tmem_alloc_barrier,
        is_two_cta=cute.size(cta_layout_vmnk, mode=[0]) > 1,
        two_cta_tmem_dealloc_mbar_ptr=storage.tmem_dealloc_mbar.ptr,
    )
    num_tmem_cols = 512
    tmem.allocate(num_tmem_cols)

    # CTA-wide sync before retrieving the pointer to the start of the allocated TMEM
    # Only warp 0 does the allocation so we need to sync before retrieving the TMEM start address
    tmem.wait_for_alloc()
    tmem_ptr = tmem.retrieve_ptr(acc_dtype)
    # Swap the pointer in tCtAcc
    tCtAcc = cute.make_tensor(tmem_ptr, tCtAcc.layout)

    subtile_cnt = 1 if mma_tiler_mnk[0] == 64 else 4
    # (EpiTile)
    epi_tiler = (
        (cute.size(tCtAcc, mode=[0, 0]), cute.size(tCtAcc, mode=[0, 1]) // subtile_cnt),
    )
    # (EpiTile, NumTiles)
    tCtAcc_epi = cute.zipped_divide(tCtAcc, epi_tiler)
    # (EpiTile, NumTiles)
    gC_epi = cute.zipped_divide(tCgC, epi_tiler)

    # Every thread loads 64 x fp32
    tmem_atom = cute.make_copy_atom(
        tcgen05.Ld16x256bOp(tcgen05.Repetition.x8)
        if mma_tiler_mnk[0] == 64
        else tcgen05.Ld32x32bOp(tcgen05.Repetition.x64),
        cutlass.Float32,
    )

    tmem_tiled_copy = tcgen05.make_tmem_copy(tmem_atom, tCtAcc_epi[None, 0])
    tmem_thr_copy = tmem_tiled_copy.get_slice(tidx)

    # (TmemCpy,NumTmemCpy,NumTiles)
    tCtC = tmem_thr_copy.partition_S(tCtAcc_epi)
    # (TmemCpy,NumTmemCpy,NumTiles)
    tCgC = tmem_thr_copy.partition_D(gC_epi)

    # (TmemCpy,NumTmemCpy)
    tCrAcc = cute.make_rmem_tensor(tCgC[None, None, 0].shape, acc_dtype)
    # (TmemCpy,NumTmemCpy)
    tCrC = cute.make_rmem_tensor(tCgC[None, None, 0].shape, io_dtype)
    cute.experimental.iket.range_pop()

    #
    # 2. Main loop
    #
    cute.experimental.iket.range_push("mainloop")
    is_leader_cta = mma_coord_vmnk[0] == 0
    num_k_tiles = cute.size(gA, mode=[2])
    prefetch_stages = ab_stages - 2
    if warp_idx == 0:
        # Wait for a empty accumulator buffer
        if is_leader_cta:
            acc_producer.acquire()
        cute.experimental.iket.range_push("prefetch")
        for k_tile in cutlass.range(prefetch_stages):
            cute.experimental.iket.range_push("prefetch_iter")
            # Wait for an empty A/B pipeline stage.
            cute.experimental.iket.range_push("prod_acquire")
            ab_empty = ab_producer.acquire_and_advance()
            cute.experimental.iket.range_pop()

            # Issue TMA loads.
            cute.experimental.iket.range_push("tma_issue")
            cute.copy(
                tma_a.atom,
                tAgA[(None, ab_empty.count)],
                tAsA[(None, ab_empty.index)],
                tma_bar_ptr=ab_empty.barrier,
                mcast_mask=tma_mcast_mask_a,
            )
            cute.copy(
                tma_b.atom,
                tBgB[(None, ab_empty.count)],
                tBsB[(None, ab_empty.index)],
                tma_bar_ptr=ab_empty.barrier,
                mcast_mask=tma_mcast_mask_b,
            )
            cute.experimental.iket.range_pop()
            cute.experimental.iket.range_pop()
        cute.experimental.iket.range_pop()

        for k_tile in cutlass.range(num_k_tiles):
            cute.experimental.iket.range_push("k_tile_iter")
            # Wait for an empty A/B pipeline stage.
            if k_tile + prefetch_stages < num_k_tiles:
                cute.experimental.iket.range_push("prod_acquire")
                ab_empty = ab_producer.acquire_and_advance()
                cute.experimental.iket.range_pop()

                # Issue TMA loads.
                cute.experimental.iket.range_push("tma_issue")
                cute.copy(
                    tma_a.atom,
                    tAgA[(None, ab_empty.count)],
                    tAsA[(None, ab_empty.index)],
                    tma_bar_ptr=ab_empty.barrier,
                    mcast_mask=tma_mcast_mask_a,
                )
                cute.copy(
                    tma_b.atom,
                    tBgB[(None, ab_empty.count)],
                    tBsB[(None, ab_empty.index)],
                    tma_bar_ptr=ab_empty.barrier,
                    mcast_mask=tma_mcast_mask_b,
                )
                cute.experimental.iket.range_pop()

            if is_leader_cta:
                # Wait for TMA copies to complete.
                cute.experimental.iket.range_push("cons_wait")
                ab_full = ab_consumer.wait_and_advance()
                cute.experimental.iket.range_pop()

                # Execute one K-block worth of MMA instructions.
                cute.experimental.iket.range_push("mma_issue")
                tiled_mma.set(tcgen05.Field.ACCUMULATE, k_tile != 0)
                tile_crd = (None, None, None, ab_full.index)
                cute.gemm(tiled_mma, tCtAcc, tCrA[tile_crd], tCrB[tile_crd], tCtAcc)
                cute.experimental.iket.range_pop()

                cute.experimental.iket.range_push("cons_release")
                ab_full.release()
                cute.experimental.iket.range_pop()
            cute.experimental.iket.range_pop()

        # Signal that the accumulator is fully computed
        if is_leader_cta:
            acc_producer.commit()
            acc_producer.advance()
    cute.experimental.iket.range_pop()

    #
    # 3. Epilogue
    cute.experimental.iket.range_push("epilogue")
    #

    #  Release TMEM allocation lock
    tmem.relinquish_alloc_permit()

    # Wait for the accumulator buffer to be full
    cute.experimental.iket.range_push("acc_wait")
    acc_full = acc_consumer.wait_and_advance()
    cute.experimental.iket.range_pop()


    # TMEM -> RMEM -> GEMM
    # Sub-tiling for better instruction-level parallelism
    for i in cutlass.range(cute.size(tCtC, mode=[2])):
        cute.experimental.iket.range_push("epi_subtile")
        cute.copy(tmem_tiled_copy, tCtC[None, None, i], tCrAcc)
        tCrC.store(tCrAcc.load().to(io_dtype))
        cute.autovec_copy(tCrC, tCgC[None, None, i])
        cute.experimental.iket.range_pop()

    cute.experimental.iket.range_push("acc_release")
    acc_full.release()
    cute.experimental.iket.range_pop()

    # Ensure used buffers are properly synchronized before producer exit.
    # This could avoid the invalid dsmem access due to early leading CTA exit.
    if warp_idx == 0:
        ab_producer.tail()
        if is_leader_cta:
            acc_producer.tail()

    # Deallocate TMEM
    pipeline.sync(barrier_id=1)
    tmem.free(tmem_ptr)
    cute.experimental.iket.range_pop()


@cute.jit
def host_function(
    a: cute.Tensor,
    b: cute.Tensor,
    c: cute.Tensor,
):
    # Construct tiled MMA
    op = tcgen05.MmaF16BF16Op(
        io_dtype,
        acc_dtype,
        mma_inst_shape_mnk,
        tcgen05.CtaGroup.TWO if use_2cta_instrs else tcgen05.CtaGroup.ONE,
        tcgen05.OperandSource.SMEM,
        OperandMajorMode.K,
        OperandMajorMode.K,
    )
    tiled_mma = cute.make_tiled_mma(op)

    # Construct SMEM layouts for A and B
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

    # Construct the VMNK layout
    cta_layout_mnk = cute.make_layout(cluster_shape_mnk)
    cta_layout_vmnk = cute.tiled_divide(cta_layout_mnk, (tiled_mma.thr_id,))

    # Construct TMA load atoms
    op = cute.nvgpu.cpasync.CopyBulkTensorTileG2SMulticastOp(
        tcgen05.CtaGroup.TWO if use_2cta_instrs else tcgen05.CtaGroup.ONE
    )
    tma_a = cute.nvgpu.make_tiled_tma_atom_A(
        op, a, a_smem_layout, mma_tiler_mnk, tiled_mma, cta_layout_vmnk.shape
    )
    tma_b = cute.nvgpu.make_tiled_tma_atom_B(
        op, b, b_smem_layout, mma_tiler_mnk, tiled_mma, cta_layout_vmnk.shape
    )

    grid_shape = cute.round_up(
        cute.ceil_div(
            (*c.layout.shape, 1),
            (mma_tiler_mnk[0] // (2 if use_2cta_instrs else 1), *mma_tiler_mnk[1:]),
        ),
        cluster_shape_mnk,
    )

    # Pretty prints kernel attributes useful for debugging
    # print(f"a               = {cute.pretty_str(a)}")
    # print(f"b               = {cute.pretty_str(b)}")
    # print(f"c               = {cute.pretty_str(c)}")
    # print(f"tiled_mma       = {cute.pretty_str(tiled_mma)}")
    # print(f"a_smem_layout   = {cute.pretty_str(a_smem_layout)}")
    # print(f"b_smem_layout   = {cute.pretty_str(b_smem_layout)}")
    # print(f"cta_layout_mnk  = {cute.pretty_str(cta_layout_mnk)}")
    # print(f"cta_layout_vmnk = {cute.pretty_str(cta_layout_vmnk)}")
    # print(f"a_tma_atom   = {cute.pretty_str(tma_a.atom)}")
    # print(f"b_tma_atom   = {cute.pretty_str(tma_b.atom)}")
    # print(f"a_tma_tensor    = {cute.pretty_str(tma_a.tma_tensor)}")
    # print(f"b_tma_tensor    = {cute.pretty_str(tma_b.tma_tensor)}")
    # cute.printf("grid_shape = {}", grid_shape)

    # Launch the kernel
    kernel(tiled_mma, tma_a, tma_b, c, cta_layout_vmnk).launch(
        grid=grid_shape,
        block=[threads_per_cta, 1, 1],
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
    print("Running Blackwell fp16 GEMM example 1 with:")
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
    a_tensor = (
        from_dlpack(a, assumed_align=32)
        .mark_layout_dynamic(leading_dim=1)
        .mark_compact_shape_dynamic(mode=1, divisibility=k)
    )
    b_tensor = (
        from_dlpack(b, assumed_align=32)
        .mark_layout_dynamic(leading_dim=1)
        .mark_compact_shape_dynamic(mode=1, divisibility=k)
    )
    c_tensor = (
        from_dlpack(c, assumed_align=32)
        .mark_layout_dynamic(leading_dim=1)
        .mark_compact_shape_dynamic(mode=1, divisibility=n)
    )

    # Entry point to the host JIT function
    host_function(
        a_tensor,
        b_tensor,
        c_tensor,
        no_cache=True,
    )

    # Compute reference result and verify
    ref = (torch.einsum("mk,nk->mn", a.to(torch.float32), b.to(torch.float32))).cpu()
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

    parser = argparse.ArgumentParser(description="Blackwell fp16 GEMM example 1")
    parser.add_argument(
        "--mnk",
        type=parse_comma_separated_ints,
        default=[8192, 8192, 8192],
        help="MNK dimensions (comma-separated)",
    )
    parser.add_argument(
        "--tolerance", type=float, default=1e-01, help="Tolerance for validation"
    )
    args = parser.parse_args()
    if len(args.mnk) != 3:
        parser.error("--mnk must contain exactly 3 values")
    if args.mnk[0] % mma_tiler_mnk[0] != 0 or args.mnk[1] % mma_tiler_mnk[1] != 0:
        parser.error("m n must be divisible by mma_tiler_mn")

    run_dense_gemm(
        args.mnk,
        args.tolerance,
    )
    print("PASS")
