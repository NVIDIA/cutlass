# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

"""
A high-performance batched dense blockscaled GEMM (C = A*SF_A * B*SF_B) example for the NVIDIA Blackwell Geforce architecture using the experimental cute_ext API, with persistent grid scheduling and two-warp-group ping-pong.
- Matrix A is MxKxL, L is batch dimension, A can only be row-major("K")
- Matrix B is NxKxL, L is batch dimension, B can only be column-major("K")
- Matrix C is MxNxL, L is batch dimension, C can only be row-major("N")
- Matrix SFA layout is filled internally according to A shape and BlockScaledBasicChunk, which has M×ceil_div(K, sf_vec_size)×L elements respectively
- Matrix SFB layout is filled internally according to B shape and BlockScaledBasicChunk, which has N×ceil_div(K, sf_vec_size)×L elements respectively
- Source formats for matrices A and B: The only supported source format in this example is E2M1.
- Source formats for matrices SF_A and SF_B are controlled separately. With sf_vec_size=16, the supported source format is E4M3.

This GEMM kernel supports the following features:
    - Utilizes Tensor Memory Access (TMA) for efficient memory operations
    - Utilizes warp-level block-scaled MMA for matrix multiply-accumulate (MMA) operations
    - Supports persistent tile scheduling to better overlap memory load/store with MMA between tiles
    - Supports warp specialization to avoid explicit pipelining between mainloop load and MMA
    - Uses a ping-pong schedule: two math warp groups (WG0 and WG1) each independently process
      one output tile at a time, alternating execution so that while one warp group runs the
      epilogue for its current tile, the other warp group runs the MMA mainloop for the next
      tile. This overlaps epilogue and mainloop across warp groups, improving math utilization
      by hiding epilogue latency behind useful computation.

This GEMM works as follows:
1. DMA warp:
    - Load A and B matrices from global memory (GMEM) to shared memory (SMEM) using TMA operations.
    - Load scale factor A and B matrices from global memory (GMEM) to shared memory (SMEM) using TMA operations.
2. MMA warp groups (two warp groups alternate on separate tiles):
    - Load A/B from shared memory (SMEM) to registers (RMEM) using ldmatrix instruction.
    - Load scale factor A/B from shared memory (SMEM) to registers (RMEM) using universal copy.
    - Perform matrix multiply-accumulate (MMA) operations using warp-level block-scaled MMA instruction.
    - Store C matrix from registers (RMEM) to shared memory (SMEM), then to global memory (GMEM) with TMA operations.
    Note: Each MMA warp group handles both MMA and epilogue for its own tile. While one warp group
    is executing the epilogue, the other warp group is executing MMA on the next tile.

Warp-level block-scaled MMA instructions operate as follows:
- Set matrix scale factor A/B from registers
- Read matrix A/B from registers
- Perform MMA operation and store the result in Accumulator(register)

To run this example:

.. code-block:: bash

    python examples/CuTeDSL/cute_ext/blackwell/sm120_dense_block_scaled_gemm_persistent_pingpong.py     \
      --mnkl 8192,8192,8192,1 --tile_shape_mnk 128,128,128                                              \
      --a_dtype Float4E2M1FN --b_dtype Float4E2M1FN                                                     \
      --c_dtype Float16 --acc_dtype Float32                                                             \
      --sf_dtype Float8E4M3FN --sf_vec_size 16 --epi_tile 64,32

The above example command compute batched gemm with M=8192, N=8192, K=8192,
batch_count=1. The tile shape is 128x128x128 and the cluster shape is (1,1).
The input, mma accumulator and output data type are set as fp4, fp32
and fp16, respectively.

To collect performance with NCU profiler:

.. code-block:: bash

    ncu python examples/CuTeDSL/cute_ext/blackwell/sm120_dense_block_scaled_gemm_persistent_pingpong.py  \
      --mnkl 1024,1024,1024,1 --tile_shape_mnk 128,128,128                                              \
      --a_dtype Float4E2M1FN --b_dtype Float4E2M1FN                                                     \
      --c_dtype Float16 --acc_dtype Float32                                                             \
      --sf_dtype Float8E4M3FN --sf_vec_size 16 --epi_tile 64,32

Constraints:
* Supported input data types: Float4E2M1FN
* Only Float32 accumulation is supported in FP4 mma
* CTA tile shape M/N/K:
 - tile_shape_m should be divisible by 128
 - tile_shape_n should be divisible by 128
 - tile_shape_k should be divisible by 64 (sf_vec_size=16) or 128 (sf_vec_size=32)
* Cluster shape M/N must be [1, 1] for Blackwell Geforce
"""

import argparse
import os
import sys
from typing import Optional, Tuple, Type

import cuda.bindings.driver as cuda

import cutlass
import cutlass.cute as cute
from cutlass.cute import experimental as cute_ext
from cutlass.cute.experimental.math import dot_block_scaled
import cutlass.cute.testing as testing
from cutlass.utils import PersistentTileSchedulerParams, StaticPersistentTileScheduler
from cutlass.cute.runtime import from_dlpack
import cutlass.utils.hopper_helpers as sm90_utils
import cutlass.utils.blockscaled_layout as blockscaled_utils
import cutlass.utils.blackwell_helpers as sm120_utils
from cutlass.pipeline import PipelineOrder, CooperativeGroup, Agent
from cutlass.cute.experimental.core import (
    pipeline_advance_iterator,
    consumer_release,
    get_pipeline_consume_stage,
    consumer_try_wait,
    normalize_skip_wait_token,
)
from cutlass._mlir.dialects import lir as cutlass_lir_ir

if __name__ == "__main__":
    current_dir = os.path.dirname(os.path.abspath(__file__))
    sys.path.insert(0, os.path.join(current_dir, "../../../"))

from helpers import cli_helper as cli


def consumer_wait_with_token(pipe, state, token):
    """consumer_wait variant that accepts a skipWait token from consumer_try_wait.

    Mirrors the high-level pipeline API at cute.experimental.pipeline.py line
    224-228, but as a free function so we can use it on a raw pipeline + state
    pair (matching how the rest of this kernel's mainloop is written).

    When `token` is truthy at runtime, the underlying mbarrier wait is skipped
    (the producer has already committed), allowing the MMA prefetched in the
    previous iteration to overlap with the now-non-blocking wait.
    """
    skip_wait = normalize_skip_wait_token(token)
    return cutlass_lir_ir.ConsumerWaitOp(
        pipe,
        state,
        skipWait=skip_wait,
    ).outState


# /////////////////////////////////////////////////////////////////////////////
#  Helpers to parse args
# /////////////////////////////////////////////////////////////////////////////
# /////////////////////////////////////////////////////////////////////////////
#  Host setup and device kernel launch
# /////////////////////////////////////////////////////////////////////////////


class Sm120BlockScaledGemmKernelPingpong:
    def __init__(
        self,
        acc_dtype,
        sf_vec_size,
        tile_shape_mnk,
        epi_tile,
    ):
        self.acc_dtype = acc_dtype
        self.sf_vec_size = sf_vec_size
        self.cluster_shape_mnk = (1, 1, 1)
        self.tile_shape_mnk = tuple(tile_shape_mnk)
        self.epi_tile = tuple(epi_tile)
        self.tiled_mma = None

        self.occupancy = 1
        # Ping-pong: 2 warp groups (4 warps each = 8 math warps) + 1 DMA warp
        self.num_mma_warps = 8
        self.num_warp_groups = 2
        self.tma_load_warp_id = self.num_mma_warps  # 8
        self.num_threads_per_warp = 32
        self.num_mma_threads = self.num_mma_warps * self.num_threads_per_warp  # 256
        self.num_threads_per_wg = (
            self.num_mma_warps // self.num_warp_groups
        ) * self.num_threads_per_warp  # 128
        self.threads_per_cta = (
            self.num_mma_warps + 1
        ) * self.num_threads_per_warp  # 288
        self.smem_capacity = cutlass.memory.get_smem_capacity_in_bytes("sm_120")

        self.ab_stage = None
        self.epi_stage = None

        self.a_smem_layout_staged = None
        self.b_smem_layout_staged = None
        self.epi_smem_layout_staged = None

        self.buffer_align_bytes = 1024

        # Register budget: 256 math * 232 = 59392, leaves 6144 for 32 DMA threads = 192 each
        # (DMA warps drop to 40 via setmaxregister, so this fits 1 CTA/SM with headroom).
        # 232 (vs 224) gives ptxas room to keep the pipeline-stage offset in registers
        # instead of spilling it to stack each k-iteration; matches the DSL register ceiling.
        self.load_register_requirement = 40
        self.mma_register_requirement = 232

        # PipelineOrder depth=2: each WG has 2 stages (mainloop, epilogue), alternating.
        self.order_depth = 2
        self.order_length = self.num_warp_groups  # 2 WGs

    def _setup_attributes(self):
        mma_op = cute.nvgpu.warp.MmaMXF4NVF4Op(
            self.a_dtype,
            self.acc_dtype,
            self.sf_dtype,
        )
        atom_shape = (2, 2, 1)
        atom_layout = cute.make_layout(atom_shape)
        permutation_mnk = sm120_utils.get_permutation_mnk(
            self.tile_shape_mnk, self.sf_vec_size, False
        )
        self.tiled_mma = cute.make_tiled_mma(
            mma_op,
            atom_layout,
            permutation_mnk=permutation_mnk,
        )

        self.cta_layout_mnk = cute.make_layout(self.cluster_shape_mnk)

        # Compute the smem size of SFA/SFB
        sfa_smem_layout_per_stage = blockscaled_utils.sm120_make_smem_layout_sfa(
            self.tiled_mma,
            self.tile_shape_mnk,
            self.sf_vec_size,
            1,
        )

        sfb_smem_layout_per_stage = blockscaled_utils.sm120_make_smem_layout_sfb(
            self.tiled_mma,
            self.tile_shape_mnk,
            self.sf_vec_size,
            1,
        )

        # Compute stage before compute smem layout
        self.ab_stage, self.epi_stage = self._compute_stages(
            self.tile_shape_mnk,
            self.a_dtype,
            self.b_dtype,
            self.sf_dtype,
            sfa_smem_layout_per_stage,
            sfb_smem_layout_per_stage,
            self.epi_tile,
            self.c_dtype,
            self.smem_capacity,
            self.occupancy,
        )

        assert self.epi_stage > 0, (
            "epi_stage <= 0, no enough shared memory. This case will be skipped."
        )

        (
            self.a_smem_layout_staged,
            self.b_smem_layout_staged,
            self.sfa_smem_layout_staged,
            self.sfb_smem_layout_staged,
            self.epi_smem_layout_staged,
        ) = self._make_smem_layouts(
            self.tile_shape_mnk,
            self.epi_tile,
            self.a_dtype,
            self.a_layout,
            self.b_dtype,
            self.b_layout,
            self.ab_stage,
            self.c_dtype,
            self.c_layout,
            self.epi_stage,
            self.sf_vec_size,
            self.tiled_mma,
        )

    @cute.experimental.jit
    def __call__(
        self,
        a: cute.Tensor,
        b: cute.Tensor,
        sfa: cute.Tensor,
        sfb: cute.Tensor,
        c: cute.Tensor,
        max_active_clusters: cutlass.Constexpr,
        stream: cuda.CUstream,
    ):
        # Setup static attributes before smem/grid/tma computation
        self.a_dtype = a.element_type
        self.b_dtype = b.element_type
        self.c_dtype = c.element_type
        self.sf_dtype = sfa.element_type

        self.a_layout = cutlass.tensor_utils.LayoutEnum.from_tensor(a)
        self.b_layout = cutlass.tensor_utils.LayoutEnum.from_tensor(b)
        self.c_layout = cutlass.tensor_utils.LayoutEnum.from_tensor(c)

        if cutlass.const_expr(self.a_dtype != self.b_dtype):
            raise TypeError(f"Type mismatch: {self.a_dtype} != {self.b_dtype}")

        self._setup_attributes()

        # SF tensor layouts (tile atom shape for MMA-compatible SF layout)
        self.sfa_layout = blockscaled_utils.tile_atom_to_shape_SF(
            a.shape, self.sf_vec_size
        )
        sfa_tensor = cute.make_tensor(sfa.iterator, self.sfa_layout)
        self.sfb_layout = blockscaled_utils.tile_atom_to_shape_SF(
            b.shape, self.sf_vec_size
        )
        sfb_tensor = cute.make_tensor(sfb.iterator, self.sfb_layout)

        # Persistent grid: StaticPersistentTileScheduler.get_grid_shape(...).
        # Mirrors DSL ref dense_blockscaled_gemm_persistent_pingpong._compute_grid.
        c_shape = cute.slice_(self.tile_shape_mnk, (None, None, 0))
        gc = cute.zipped_divide(c, tiler=c_shape)
        num_ctas_mnl = gc[(0, (None, None, None))].shape
        tile_sched_params = PersistentTileSchedulerParams(
            num_ctas_mnl, self.cluster_shape_mnk
        )
        grid = StaticPersistentTileScheduler.get_grid_shape(
            tile_sched_params, max_active_clusters
        )

        self.threads_per_cta = (self.threads_per_cta + 128) // 128 * 128

        # Kernel receives raw tensors + smem layouts; cta_v_maps computed inside.
        self.kernel(
            a,
            b,
            sfa_tensor,
            sfb_tensor,
            c,
            self.tiled_mma,
            tile_sched_params,
            self.a_smem_layout_staged,
            self.b_smem_layout_staged,
            self.sfa_smem_layout_staged,
            self.sfb_smem_layout_staged,
            self.epi_smem_layout_staged,
        ).launch(
            grid=grid,
            block=[self.threads_per_cta, 1, 1],
            cluster=[1, 1, 1],
            stream=stream,
            max_number_threads=[self.threads_per_cta, 1, 1],
            min_blocks_per_mp=1,
            smem=cute.Int64(self.smem_capacity),
        )
        return

    @cute.experimental.kernel
    def kernel(
        self,
        mA: cute.Tensor,
        mB: cute.Tensor,
        mSFA: cute.Tensor,
        mSFB: cute.Tensor,
        mC_mnl: cute.Tensor,
        tiled_mma: cute.TiledMma,
        tile_sched_params: PersistentTileSchedulerParams,
        a_smem_layout_staged: cute.ComposedLayout,
        b_smem_layout_staged: cute.ComposedLayout,
        sfa_smem_layout_staged: cute.Layout,
        sfb_smem_layout_staged: cute.Layout,
        epi_smem_layout_staged: cute.ComposedLayout,
    ):
        # ///////////////////////////////////////////////////////////////////////////////
        #  Get cta/warp/thread idx
        # ///////////////////////////////////////////////////////////////////////////////
        tidx, _, _ = cute.arch.thread_idx()
        warp_idx = cute.arch.warp_idx()
        warp_idx = cute.arch.make_warp_uniform(warp_idx)
        # warp_group_idx: 0 for WG0 (math warps 0..3), 1 for WG1 (math warps 4..7).
        # DMA warp (warp_idx == tma_load_warp_id == 8) has warp_group_idx==2 (unused).
        warp_group_idx = cute.arch.make_warp_uniform(tidx // self.num_threads_per_wg)

        # ///////////////////////////////////////////////////////////////////////////////
        #  SMEM allocation via cute_ext.allocate (replaces SharedStorage/SmemAllocator)
        # ///////////////////////////////////////////////////////////////////////////////
        sA = cute_ext.allocate(
            self.a_dtype,
            cutlass.AddressSpace.smem,
            a_smem_layout_staged,
            alignment=self.buffer_align_bytes,
        )
        sB = cute_ext.allocate(
            self.b_dtype,
            cutlass.AddressSpace.smem,
            b_smem_layout_staged,
            alignment=self.buffer_align_bytes,
        )
        sSFA = cute_ext.allocate(
            self.sf_dtype,
            cutlass.AddressSpace.smem,
            sfa_smem_layout_staged,
            alignment=self.buffer_align_bytes,
        )
        sSFB = cute_ext.allocate(
            self.sf_dtype,
            cutlass.AddressSpace.smem,
            sfb_smem_layout_staged,
            alignment=self.buffer_align_bytes,
        )
        sC = cute_ext.allocate(
            self.c_dtype,
            cutlass.AddressSpace.smem,
            epi_smem_layout_staged,
            alignment=self.buffer_align_bytes,
        )

        # ///////////////////////////////////////////////////////////////////////////////
        #  Allocate SMEM storage for PipelineOrder mbarriers (4 mbarriers = 32 bytes,
        #  matching DSL math_wg_order_barrier_array_ptr: MemRange[Int64, 2*2]).
        # ///////////////////////////////////////////////////////////////////////////////
        order_mbar_buf = cute_ext.allocate(
            cutlass.Int64,
            cutlass.AddressSpace.smem,
            cute.make_layout(self.order_depth * self.order_length),
            alignment=8,
        )

        # ///////////////////////////////////////////////////////////////////////////////
        #  TMAToAsyncPipeline (replaces DSL PipelineTmaAsync)
        #  consumer_arv_count = ONE WG (128 threads) since only one WG consumes
        #  any given stage at a time (DSL semantics: pipeline.CooperativeGroup(thread,
        #  num_mma_warps // 2)).
        # ///////////////////////////////////////////////////////////////////////////////
        mainloop_pipe = cute_ext.TMAToAsyncPipeline.create(
            num_stages=self.ab_stage,
            consumer=cute_ext.OperationTypeEnum.LD_SHARED,
            consumer_arv_count=self.num_threads_per_wg,
        )

        # ///////////////////////////////////////////////////////////////////////////////
        #  PipelineOrder for inter-WG ping-pong sync.
        #  depth=2 stages * length=2 groups = 4 mbarriers.
        #  Producer is each WG's 128 math threads.
        #  defer_sync=False -> mbarrier_init_fence + agent_sync(ThreadBlock) emitted.
        # ///////////////////////////////////////////////////////////////////////////////
        math_wg_order_barrier = PipelineOrder.create(
            barrier_storage=order_mbar_buf.iterator,
            depth=self.order_depth,
            length=self.order_length,
            group_id=warp_group_idx,
            producer_group=CooperativeGroup(Agent.Thread, self.num_threads_per_wg),
            defer_sync=True,
        )

        cute.arch.mbarrier_init_fence()

        # ///////////////////////////////////////////////////////////////////////////////
        #  zipped_divide tensor decomposition (replaces local_tile)
        #  Persistent: tile coordinate comes from the scheduler each iteration.
        # ///////////////////////////////////////////////////////////////////////////////
        tiler_mk = (self.tile_shape_mnk[0], self.tile_shape_mnk[2])
        tiler_nk = (self.tile_shape_mnk[1], self.tile_shape_mnk[2])

        # zipped_divide: ((tile_m, tile_k), (rest_m, rest_k, L))
        gA = cute.zipped_divide(mA, tiler_mk)
        gB = cute.zipped_divide(mB, tiler_nk)
        gSFA = cute.zipped_divide(mSFA, tiler_mk)
        gSFB = cute.zipped_divide(mSFB, tiler_nk)

        # k_tile_cnt is invariant across tiles (we tile across M, N, L only).
        # gA layout: ((tile_m, tile_k), (rest_m, rest_k, L)); rest_k is gA.shape[1][1].
        k_tile_cnt = gA.shape[1][1]

        # Output tile decomposition for epilogue
        tiler_mn = (self.tile_shape_mnk[0], self.tile_shape_mnk[1])
        gC_mn_tiled = cute.zipped_divide(mC_mnl, tiler_mn)

        # ///////////////////////////////////////////////////////////////////////////////
        #  Partition SMEM for MMA + SF RMEM setup
        # ///////////////////////////////////////////////////////////////////////////////
        thr_mma = tiled_mma.get_slice(tidx % self.num_threads_per_wg)

        # MMA-partitioned SMEM views
        tCsA = thr_mma.partition_A(sA)
        tCsB = thr_mma.partition_B(sB)

        # RMEM fragments for A/B (allocated by make_fragment_A/B)
        tCrA = tiled_mma.make_fragment_A(tCsA[None, None, None, 0])
        tCrB = tiled_mma.make_fragment_B(tCsB[None, None, None, 0])

        # SF RMEM: use use_sf_layout_TV=True for dot_block_scaled-compatible shapes
        sf_k = self.tile_shape_mnk[2] // self.sf_vec_size
        tiled_mma_sf = cute.make_tiled_mma(tiled_mma.op, use_sf_layout_TV=True)
        sf_shape_a = tiled_mma_sf.partition_shape_A((self.tile_shape_mnk[0], sf_k))
        sf_shape_b = tiled_mma_sf.partition_shape_B((self.tile_shape_mnk[1], sf_k))
        tCrSFA = cute_ext.allocate(
            self.sf_dtype,
            cutlass.AddressSpace.rmem,
            cute.make_layout(sf_shape_a),
            alignment=32,
        )
        tCrSFB = cute_ext.allocate(
            self.sf_dtype,
            cutlass.AddressSpace.rmem,
            cute.make_layout(sf_shape_b),
            alignment=32,
        )

        # DSL SF partition (for SMEM->RMEM copy source/retile)
        tCrSFA = sm120_utils.partition_fragment_SFA(
            sSFA[None, None, 0], thr_mma, tidx % self.num_threads_per_wg
        )
        tCrSFB = sm120_utils.partition_fragment_SFB(
            sSFB[None, None, 0], thr_mma, tidx % self.num_threads_per_wg
        )

        # Accumulator (C partition for output shape)
        # Use local_tile to get gC_mnl for partition_C shape computation
        gC_mnl = cute.local_tile(
            mC_mnl,
            cute.slice_(self.tile_shape_mnk, (None, None, 0)),
            (None, None, None),
        )
        tCgC = thr_mma.partition_C(gC_mnl)
        acc_shape = tCgC.shape[:3]
        accumulators = cute.make_rmem_tensor(acc_shape, self.acc_dtype)

        # k-blocks per tile: derived from atom shape_mnk[2] and tile_k
        mma_atom_k = tiled_mma.op.shape_mnk[2]
        num_k_blocks = self.tile_shape_mnk[2] // mma_atom_k

        # ///////////////////////////////////////////////////////////////////////////////
        #  Persistent tile scheduler: maps each CTA to a stream of (m, n, l) tiles.
        # ///////////////////////////////////////////////////////////////////////////////
        tile_sched = StaticPersistentTileScheduler.create(
            tile_sched_params, cute.arch.block_idx(), cute.arch.grid_dim()
        )
        work_tile = tile_sched.initial_work_tile_info()

        # Synchronize before starting pipeline
        cute.arch.sync_threads()

        # /////////////////////////////////////////////////////////////////////////////
        #  DMA warp: TMA loads via cute_ext.tma_load (replaces DSL cpasync).
        #  Driven by the persistent scheduler -- only loads tiles assigned to this CTA.
        # /////////////////////////////////////////////////////////////////////////////
        if warp_idx >= self.tma_load_warp_id:
            cute.arch.setmaxregister_decrease(self.load_register_requirement)

            if warp_idx == self.tma_load_warp_id:
                while work_tile.is_valid_tile:
                    tile_coord_mnl = work_tile.tile_idx
                    cta_m, cta_n, cta_l = (
                        tile_coord_mnl[0],
                        tile_coord_mnl[1],
                        tile_coord_mnl[2],
                    )
                    gA_tile = gA[(None, None), (cta_m, None, cta_l)]
                    gB_tile = gB[(None, None), (cta_n, None, cta_l)]
                    gSFA_tile = gSFA[(None, None), (cta_m, None, cta_l)]
                    gSFB_tile = gSFB[(None, None), (cta_n, None, cta_l)]

                    for k_tile in range(0, k_tile_cnt, 1, unroll=1):
                        # Acquire pipeline stage
                        producer_stage_token, stage_idx = (
                            mainloop_pipe.producer_acquire_and_get_stage()
                        )
                        mbar = cute_ext.get_mbarrier(producer_stage_token)

                        # TMA load A, B, SFA, SFB into pipeline stage
                        cute_ext.tma_load(
                            gA_tile[(None, None, k_tile)],
                            sA[(None, None, stage_idx)],
                            mbar,
                            update_expect_tx=True,
                        )
                        cute_ext.tma_load(
                            gB_tile[(None, None, k_tile)],
                            sB[(None, None, stage_idx)],
                            mbar,
                            update_expect_tx=True,
                        )
                        cute_ext.tma_load(
                            gSFA_tile[(None, None, k_tile)],
                            sSFA[(None, None, stage_idx)],
                            mbar,
                            internal_type=cutlass.Int16,
                            update_expect_tx=True,
                        )
                        cute_ext.tma_load(
                            gSFB_tile[(None, None, k_tile)],
                            sSFB[(None, None, stage_idx)],
                            mbar,
                            internal_type=cutlass.Int16,
                            update_expect_tx=True,
                        )

                        mainloop_pipe.producer_commit_and_advance()

                    tile_sched.advance_to_next_work()
                    work_tile = tile_sched.get_current_work()

        # /////////////////////////////////////////////////////////////////////////////
        #  MMA warps: pipelined mainloop (RMEM A/B after explicit ldmatrix) + epilogue.
        #  Persistent: each warp processes the same stream of tiles as the DMA warp.
        # /////////////////////////////////////////////////////////////////////////////
        elif warp_idx < self.tma_load_warp_id:
            cute.arch.setmaxregister_increase(self.mma_register_requirement)

            # ldmatrix copy atoms for A/B (SMEM->RMEM via ldmatrix)
            atom_copy_ldmatrix_A = cute.make_copy_atom(
                cute.nvgpu.warp.LdMatrix8x8x16bOp(self.a_layout.is_m_major_a(), 4),
                self.a_dtype,
            )
            atom_copy_ldmatrix_B = cute.make_copy_atom(
                cute.nvgpu.warp.LdMatrix8x8x16bOp(self.b_layout.is_n_major_b(), 4),
                self.b_dtype,
            )
            smem_tiled_copy_A = cute.make_tiled_copy_A(atom_copy_ldmatrix_A, tiled_mma)
            smem_tiled_copy_B = cute.make_tiled_copy_B(atom_copy_ldmatrix_B, tiled_mma)

            thr_copy_ldmatrix_A = smem_tiled_copy_A.get_slice(
                tidx % self.num_threads_per_wg
            )
            thr_copy_ldmatrix_B = smem_tiled_copy_B.get_slice(
                tidx % self.num_threads_per_wg
            )
            tCsA_copy_view = thr_copy_ldmatrix_A.partition_S(sA)
            tCrA_copy_view = thr_copy_ldmatrix_A.retile(tCrA)
            tCsB_copy_view = thr_copy_ldmatrix_B.partition_S(sB)
            tCrB_copy_view = thr_copy_ldmatrix_B.retile(tCrB)

            # SF copy atoms (SMEM->RMEM)
            atom_copy_SF = cute.make_copy_atom(
                cute.nvgpu.CopyUniversalOp(),
                self.sf_dtype,
            )
            smem_tiled_copy_SFA = cute.make_tiled_copy(
                atom_copy_SF,
                sm120_utils.get_layoutSFA_TV(tiled_mma),
                (
                    cute.size(tiled_mma.permutation_mnk[0]),
                    cute.size(tiled_mma.permutation_mnk[2]),
                ),
            )
            smem_tiled_copy_SFB = cute.make_tiled_copy(
                atom_copy_SF,
                sm120_utils.get_layoutSFB_TV(tiled_mma),
                (
                    cute.size(tiled_mma.permutation_mnk[1]),
                    cute.size(tiled_mma.permutation_mnk[2]),
                ),
            )
            thr_copy_SFA = smem_tiled_copy_SFA.get_slice(tidx % self.num_threads_per_wg)
            thr_copy_SFB = smem_tiled_copy_SFB.get_slice(tidx % self.num_threads_per_wg)
            tCsSFA_copy_view = thr_copy_SFA.partition_S(sSFA)
            tCrSFA_copy_view = thr_copy_SFA.retile(tCrSFA)
            tCsSFB_copy_view = thr_copy_SFB.partition_S(sSFB)
            tCrSFB_copy_view = thr_copy_SFB.retile(tCrSFB)

            # Construct the MMA atom for dot_block_scaled
            mma_atom = cute.make_mma_atom(tiled_mma.op)

            # R2S copy setup (SM120-specific stmatrix atom) -- tile-invariant.
            copy_atom_r2s = sm120_utils.sm120_get_smem_store_op(
                self.c_layout,
                elem_ty_d=self.c_dtype,
                elem_ty_acc=self.acc_dtype,
            )
            copy_atom_C = cute.make_copy_atom(
                cute.nvgpu.warp.StMatrix8x8x16bOp(
                    self.c_layout.is_m_major_c(),
                    2,
                ),
                self.c_dtype,
            )
            tiled_copy_C_Atom = cute.make_tiled_copy_C_atom(copy_atom_C, tiled_mma)
            tiled_copy_r2s = cute.make_tiled_copy_S(copy_atom_r2s, tiled_copy_C_Atom)

            thr_copy_r2s = tiled_copy_r2s.get_slice(tidx % self.num_threads_per_wg)
            tRS_rAcc = tiled_copy_r2s.retile(accumulators)

            rD_shape = cute.shape(thr_copy_r2s.partition_S(sC))
            tRS_rD_layout = cute.make_layout(rD_shape[:3])
            tRS_rD = cute.make_rmem_tensor(tRS_rD_layout.shape, self.acc_dtype)

            # Two TMAStorePipeline instances, one per warp group.
            # arv_count=128 (one WG's worth of threads).
            # WG0: barrier_id=4, tma_warp_id=0 (overall warp 0 is the TMA warp).
            # WG1: barrier_id=5, tma_warp_id=4 (overall warp 4 is the TMA warp).
            # Distinct barrier IDs let the two WGs' epilogues run concurrently.
            #
            # Each WG uses half the epi_stage slots of `sC` (the other half
            # is owned by the partner WG). sC was sized for `epi_stage` total
            # slots (computed for single-WG); for ping-pong we use half each.
            # If epi_stage is 1, both WGs use slot 0 (correct only with order
            # barrier serializing epilogues).
            stages_per_wg = max(self.epi_stage // self.num_warp_groups, 1)
            sc_offset_wg0 = 0
            # If epi_stage < num_warp_groups, sC has fewer slots than WGs.
            # Both WGs then share slot 0; the order_barrier serializes
            # epilogues (WG1's epi acquire_sync also drains WG0's bulk).
            sc_offset_wg1 = (
                stages_per_wg if self.epi_stage >= self.num_warp_groups else 0
            )
            tma_store_pipe_wg0 = cute_ext.TMAStorePipeline(
                stages=stages_per_wg,
                arv_count=self.num_threads_per_wg,
                barrier_id=4,
                tma_warp_id=0,
            )
            tma_store_pipe_wg1 = cute_ext.TMAStorePipeline(
                stages=stages_per_wg,
                arv_count=self.num_threads_per_wg,
                barrier_id=5,
                tma_warp_id=self.num_mma_warps // self.num_warp_groups,  # 4
            )

            epi_tile_m = self.epi_tile[0]
            epi_tile_n = self.epi_tile[1]
            mma_tile_m = self.tile_shape_mnk[0] // cute.size(tRS_rAcc, mode=[1])
            mma_tile_n = self.tile_shape_mnk[1] // cute.size(tRS_rAcc, mode=[2])

            # ///////////////////////////////////////////////////////////////////////////
            #  Inter-WG ping-pong setup.
            #  WG1 starts one tile ahead of WG0 in the scheduler stream, and its
            #  consumer state is advanced by k_tile_cnt so it consumes the second
            #  tile's pipeline stages.
            #  The order barrier sequences the two WGs: WG0 enters mainloop first
            #  (depth=2 lets it pre-arrive one slot), WG1 waits.
            # ///////////////////////////////////////////////////////////////////////////
            math_wg_order_state = math_wg_order_barrier.state
            consumer_state = mainloop_pipe.consumer_state
            raw_pipe = mainloop_pipe.raw_pipeline

            if warp_group_idx == 1:
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()
                # Advance consumer_state by k_tile_cnt so WG1's first consumer_wait
                # is for the second tile's stages.
                for _i in cutlass.range(k_tile_cnt, unroll=1):
                    consumer_state = pipeline_advance_iterator(raw_pipe, consumer_state)

            # ///////////////////////////////////////////////////////////////////////////
            #  Persistent tile loop -- mainloop + epilogue per assigned tile.
            #  Each iteration processes ONE tile owned by this WG.
            # ///////////////////////////////////////////////////////////////////////////
            while work_tile.is_valid_tile:
                tile_coord_mnl = work_tile.tile_idx
                gC_cta_tile = gC_mn_tiled[(None, None), tile_coord_mnl]
                gC_epi = cute.flat_divide(gC_cta_tile, self.epi_tile)
                epi_rest_m = gC_epi.shape[2]
                epi_rest_n = gC_epi.shape[3]

                # Clear the accumulator at the start of each tile.
                accumulators.fill(0.0)

                # /////////////////////////////////////////////////////////////////////
                #  Ping-pong: WG0 enters mainloop first; WG1 waits.
                # /////////////////////////////////////////////////////////////////////
                math_wg_order_barrier.wait(math_wg_order_state)

                # /////////////////////////////////////////////////////////////////////////////
                #  Pipelined MAINLOOP (RMEM A/B/SFA/SFB after explicit ldmatrix copy).
                #  Schedule mirrors DSL ref dense_blockscaled_gemm_persistent_pingpong.py
                #  lines 905-1115: hoisted prologue + main loop k_tile_cnt-1 iters with
                #  next-k_block prefetch + nonblocking consumer_try_wait peek + hoisted
                #  final k_tile drain. This overlaps the SMEM->RMEM ldmatrix/SF copies
                #  for k_block_next with the MMA of k_block_idx, and overlaps the mbarrier
                #  wait for the next pipeline stage with the MMA on the current stage.
                #
                #  Uses explicit consumer_state (local var) so WG0 and WG1 can have
                #  independent state values across the if/else branches above.
                # /////////////////////////////////////////////////////////////////////////////

                # ---- Prologue: wait for first stage, load k_block=0 of A/B/SFA/SFB ----
                # Peek first to allow the wait to be a non-blocking acknowledgement
                # when the producer is already ahead (which is common after WG1's
                # state pre-advance).
                peek_ab_full = consumer_try_wait(raw_pipe, consumer_state)
                consumer_state = consumer_wait_with_token(
                    raw_pipe, consumer_state, peek_ab_full
                )
                _, stage_idx = get_pipeline_consume_stage(raw_pipe, consumer_state)

                tCsA_p = tCsA_copy_view[None, None, None, stage_idx]
                tCsB_p = tCsB_copy_view[None, None, None, stage_idx]
                tCsSFA_stage = tCsSFA_copy_view[None, None, None, stage_idx]
                tCsSFB_stage = tCsSFB_copy_view[None, None, None, stage_idx]
                tCsSFA_f = cute.filter_zeros(tCsSFA_stage)
                tCsSFB_f = cute.filter_zeros(tCsSFB_stage)
                tCrSFA_f = cute.filter_zeros(tCrSFA_copy_view)
                tCrSFB_f = cute.filter_zeros(tCrSFB_copy_view)

                cute.copy(
                    smem_tiled_copy_A,
                    tCsA_p[None, None, 0],
                    tCrA_copy_view[None, None, 0],
                )
                cute.copy(
                    smem_tiled_copy_B,
                    tCsB_p[None, None, 0],
                    tCrB_copy_view[None, None, 0],
                )
                cute.copy(
                    smem_tiled_copy_SFA,
                    tCsSFA_f[None, None, 0],
                    tCrSFA_f[None, None, 0],
                )
                cute.copy(
                    smem_tiled_copy_SFB,
                    tCsSFB_f[None, None, 0],
                    tCrSFB_f[None, None, 0],
                )

                # ---- Main k_tile loop: k_tile_cnt - 1 iters (last tile is hoisted) ----
                for k_tile in range(0, k_tile_cnt - 1, 1, unroll=1):
                    for k_block_idx in cutlass.range_constexpr(num_k_blocks):
                        k_block_next = (
                            0 if k_block_idx + 1 == num_k_blocks else k_block_idx + 1
                        )

                        if k_block_idx == num_k_blocks - 1:
                            # End of this k_tile: release current stage, advance,
                            # then peek + wait for the NEXT k_tile's stage. The
                            # nonblocking peek lets the prefetched k_block_next-1
                            # MMA below overlap with the wait when the producer
                            # is already ahead.
                            consumer_release(raw_pipe, consumer_state)
                            consumer_state = pipeline_advance_iterator(
                                raw_pipe, consumer_state
                            )

                            peek_ab_full = consumer_try_wait(raw_pipe, consumer_state)
                            consumer_state = consumer_wait_with_token(
                                raw_pipe, consumer_state, peek_ab_full
                            )
                            _, stage_idx = get_pipeline_consume_stage(
                                raw_pipe, consumer_state
                            )
                            tCsA_p = tCsA_copy_view[None, None, None, stage_idx]
                            tCsB_p = tCsB_copy_view[None, None, None, stage_idx]
                            tCsSFA_stage = tCsSFA_copy_view[None, None, None, stage_idx]
                            tCsSFB_stage = tCsSFB_copy_view[None, None, None, stage_idx]
                            tCsSFA_f = cute.filter_zeros(tCsSFA_stage)
                            tCsSFB_f = cute.filter_zeros(tCsSFB_stage)

                        # Prefetch: ldmatrix A/B + SF copy for k_block_next.
                        # When k_block_idx == num_k_blocks - 1, k_block_next == 0
                        # and the loads come from the NEXT pipeline stage we just
                        # waited for above.
                        cute.copy(
                            smem_tiled_copy_A,
                            tCsA_p[None, None, k_block_next],
                            tCrA_copy_view[None, None, k_block_next],
                        )
                        cute.copy(
                            smem_tiled_copy_B,
                            tCsB_p[None, None, k_block_next],
                            tCrB_copy_view[None, None, k_block_next],
                        )
                        cute.copy(
                            smem_tiled_copy_SFA,
                            tCsSFA_f[None, None, k_block_next],
                            tCrSFA_f[None, None, k_block_next],
                        )
                        cute.copy(
                            smem_tiled_copy_SFB,
                            tCsSFB_f[None, None, k_block_next],
                            tCrSFB_f[None, None, k_block_next],
                        )

                        # MMA for k_block_idx: consumes data prefetched in the
                        # previous iter (or from the prologue for the very first
                        # k_block).
                        dot_block_scaled(
                            mma_atom,
                            tCrA[None, None, k_block_idx],
                            tCrSFA[None, None, k_block_idx],
                            tCrB[None, None, k_block_idx],
                            tCrSFB[None, None, k_block_idx],
                            accumulators,
                        )

                # ---- Hoisted-out final k_tile: drains the pipeline, no next-tile prefetch ----
                # k_tile_cnt == 1 case: main loop above did 0 iters, so this
                # processes the only k_tile (whose stage was loaded by the prologue).
                # k_tile_cnt > 1 case: this processes the last k_tile loaded by
                # the wait at the tail of the previous main-loop iter.
                for k_block_idx in cutlass.range_constexpr(num_k_blocks):
                    k_block_next = (
                        0 if k_block_idx + 1 == num_k_blocks else k_block_idx + 1
                    )

                    if k_block_idx == num_k_blocks - 1:
                        # Release the final stage. No wait -- this was the last k_tile
                        # for this tile.
                        consumer_release(raw_pipe, consumer_state)
                        consumer_state = pipeline_advance_iterator(
                            raw_pipe, consumer_state
                        )

                    if k_block_next > 0:
                        # Still useful to prefetch within the final k_tile so the
                        # next MMA can fire in parallel.
                        cute.copy(
                            smem_tiled_copy_A,
                            tCsA_p[None, None, k_block_next],
                            tCrA_copy_view[None, None, k_block_next],
                        )
                        cute.copy(
                            smem_tiled_copy_B,
                            tCsB_p[None, None, k_block_next],
                            tCrB_copy_view[None, None, k_block_next],
                        )
                        cute.copy(
                            smem_tiled_copy_SFA,
                            tCsSFA_f[None, None, k_block_next],
                            tCrSFA_f[None, None, k_block_next],
                        )
                        cute.copy(
                            smem_tiled_copy_SFB,
                            tCsSFB_f[None, None, k_block_next],
                            tCrSFB_f[None, None, k_block_next],
                        )

                    dot_block_scaled(
                        mma_atom,
                        tCrA[None, None, k_block_idx],
                        tCrSFA[None, None, k_block_idx],
                        tCrB[None, None, k_block_idx],
                        tCrSFB[None, None, k_block_idx],
                        accumulators,
                    )

                # /////////////////////////////////////////////////////////////////////
                #  Ping-pong: signal partner WG that mainloop is done. WG1 can now
                #  begin its mainloop; this WG proceeds to the epilogue.
                # /////////////////////////////////////////////////////////////////////
                math_wg_order_state = math_wg_order_barrier.arrive(math_wg_order_state)
                math_wg_order_barrier.wait(math_wg_order_state)

                # /////////////////////////////////////////////////////////////////////
                #  Advance consumer_state by k_tile_cnt to skip the partner WG's
                #  pipeline stages (mirrors DSL ref line 1119-1121:
                #  mainloop_consumer_state = self.advance(..., k_tile_cnt)).
                #  Without this, WG0 iter 2 reads WG1's already-consumed stage
                #  instead of its own next tile's data.
                # /////////////////////////////////////////////////////////////////////
                for _i in cutlass.range(k_tile_cnt, unroll=1):
                    consumer_state = pipeline_advance_iterator(raw_pipe, consumer_state)

                # /////////////////////////////////////////////////////////////////////////////
                #  EPILOGUE
                # /////////////////////////////////////////////////////////////////////////////
                for epi_m in cutlass.range_constexpr(epi_rest_m):
                    for epi_n in cutlass.range_constexpr(epi_rest_n):
                        MmaMPerEpiM = epi_tile_m // mma_tile_m
                        MmaNPerEpiN = epi_tile_n // mma_tile_n
                        for mma_n_in_epi in cutlass.range_constexpr(MmaNPerEpiN):
                            for mma_m_in_epi in cutlass.range_constexpr(MmaMPerEpiM):
                                mma_n = (epi_n * MmaNPerEpiN) + mma_n_in_epi
                                mma_m = (epi_m * MmaMPerEpiM) + mma_m_in_epi
                                tRS_rD_slice = tRS_rD[
                                    (None, mma_m_in_epi, mma_n_in_epi)
                                ]
                                tRS_rAcc_slice = tRS_rAcc[(None, mma_m, mma_n)]
                                for elem_idx in cutlass.range_constexpr(
                                    cute.size(tRS_rD_slice)
                                ):
                                    tRS_rD_slice[elem_idx] = tRS_rAcc_slice[elem_idx]

                        # Type conversion
                        tRS_rD_out = cute.make_rmem_tensor(
                            tRS_rD_layout.shape, self.c_dtype
                        )
                        acc_vec = tRS_rD.load()
                        tRS_rD_out.store(acc_vec.to(self.c_dtype))

                        # Per-WG store pipeline + per-WG sC slot offset.
                        # Each WG does the full acquire -> R2S -> commit -> TMA -> release
                        # sequence inside its own if branch.
                        if warp_group_idx == 0:
                            tma_store_pipe_wg0.acquire_sync()
                            store_idx = tma_store_pipe_wg0.get_index() + sc_offset_wg0
                            cute_ext.partition_and_copy(
                                tiled_copy_r2s.get_slice(
                                    tidx % self.num_threads_per_wg
                                ),
                                tRS_rD_out,
                                sC[(None, None, store_idx)],
                            )
                            tma_store_pipe_wg0.commit_sync()
                            if warp_idx == tma_store_pipe_wg0.tma_warp_id:
                                cute_ext.tma_store(
                                    sC[(None, None, store_idx)],
                                    gC_epi[(None, None, epi_m, epi_n)],
                                )
                            tma_store_pipe_wg0.release_advance()
                        else:
                            tma_store_pipe_wg1.acquire_sync()
                            store_idx = tma_store_pipe_wg1.get_index() + sc_offset_wg1
                            cute_ext.partition_and_copy(
                                tiled_copy_r2s.get_slice(
                                    tidx % self.num_threads_per_wg
                                ),
                                tRS_rD_out,
                                sC[(None, None, store_idx)],
                            )
                            tma_store_pipe_wg1.commit_sync()
                            if warp_idx == tma_store_pipe_wg1.tma_warp_id:
                                cute_ext.tma_store(
                                    sC[(None, None, store_idx)],
                                    gC_epi[(None, None, epi_m, epi_n)],
                                )
                            tma_store_pipe_wg1.release_advance()

                # /////////////////////////////////////////////////////////////////////
                #  Drain this WG's in-flight bulk TMA stores BEFORE signaling the
                #  partner WG. Without this, WG0's TMA bulk store can still be
                #  reading from sC[store_idx] when WG1 begins its R2S into the
                #  same slot, producing wrong values (DSL ref mirrors this via
                #  per-tile tma_store_pipeline.producer_tail() at line 1243).
                # /////////////////////////////////////////////////////////////////////
                if warp_group_idx == 0:
                    tma_store_pipe_wg0.tail()
                else:
                    tma_store_pipe_wg1.tail()

                # /////////////////////////////////////////////////////////////////////
                #  Ping-pong: signal partner WG that epilogue is done.
                # /////////////////////////////////////////////////////////////////////
                math_wg_order_state = math_wg_order_barrier.arrive(math_wg_order_state)

                # Advance to the NEXT tile owned by THIS WG (skip the partner's tile).
                tile_sched.advance_to_next_work()
                tile_sched.advance_to_next_work()
                work_tile = tile_sched.get_current_work()

            # /////////////////////////////////////////////////////////////////////
            #  Post-loop cleanup arrive.
            #  Each in-loop tile issues 2 arrives + 2 waits per WG, paired across
            #  the two WGs (WG0 signals WG1's slots, WG1 signals WG0's slots).
            #  When both WGs process the same number of tiles, WG1 has issued
            #  one fewer "effective signal" than WG0 expected (because WG0's
            #  initial phase=1 lets it pre-consume one arrival). WG1's extra
            #  post-loop arrive rebalances the counters so a peer wait left
            #  pending across exit does not livelock the cluster. Harmless
            #  over-arrive on an unwatched barrier in cases where WG0 has
            #  already exited.
            # /////////////////////////////////////////////////////////////////////
            if warp_group_idx == 1:
                math_wg_order_state = math_wg_order_barrier.arrive(math_wg_order_state)

            # Wait for all in-flight TMA stores to complete before kernel exit.
            if warp_group_idx == 0:
                tma_store_pipe_wg0.tail()
            else:
                tma_store_pipe_wg1.tail()
        return

    @staticmethod
    def _compute_stages(
        tile_shape_mnk,
        a_dtype,
        b_dtype,
        sf_dtype,
        sfa_smem_layout,
        sfb_smem_layout,
        epi_tile,
        c_dtype,
        smem_capacity,
        occupancy,
    ):
        epi_stage_max = (tile_shape_mnk[1] // epi_tile[1]) * (
            tile_shape_mnk[0] // epi_tile[0]
        )
        epi_stage = min(epi_stage_max, 4)
        c_bytes_per_stage = cute.size(epi_tile) * c_dtype.width // 8
        epi_bytes = c_bytes_per_stage * epi_stage

        a_shape = cute.slice_(tile_shape_mnk, (None, 0, None))
        b_shape = cute.slice_(tile_shape_mnk, (0, None, None))
        ab_bytes_per_stage = (
            cute.size(a_shape) * a_dtype.width // 8
            + cute.size(b_shape) * b_dtype.width // 8
        )
        sf_bytes_per_stage = (
            cute.size(cute.filter_zeros(sfa_smem_layout).shape) * sf_dtype.width // 8
            + cute.size(cute.filter_zeros(sfb_smem_layout).shape) * sf_dtype.width // 8
        )
        mbar_helpers_bytes = 1024

        ab_stage = (
            (smem_capacity - occupancy * 1024) // occupancy
            - mbar_helpers_bytes
            - epi_bytes
        ) // (ab_bytes_per_stage + sf_bytes_per_stage)
        return ab_stage, epi_stage

    @staticmethod
    def _make_smem_layouts(
        tile_shape_mnk,
        epi_tile,
        a_dtype,
        a_layout,
        b_dtype,
        b_layout,
        ab_stage,
        c_dtype,
        c_layout,
        epi_stage,
        sf_vec_size,
        tiled_mma,
    ):
        a_smem_shape = cute.slice_(tile_shape_mnk, (None, 0, None))
        a_is_k_major = a_layout.is_k_major_a()
        b_is_k_major = b_layout.is_k_major_b()
        a_major_mode_size = tile_shape_mnk[2 if a_is_k_major else 0]

        a_smem_layout_atom = cute.nvgpu.warpgroup.make_smem_layout_atom(
            sm90_utils.get_smem_layout_atom(a_layout, a_dtype, a_major_mode_size),
            a_dtype,
        )
        a_smem_layout_staged = cute.tile_to_shape(
            a_smem_layout_atom,
            cute.append(a_smem_shape, ab_stage),
            order=(0, 1, 2) if a_is_k_major else (1, 0, 2),
        )

        b_smem_shape = cute.slice_(tile_shape_mnk, (0, None, None))
        b_major_mode_size = tile_shape_mnk[2 if b_is_k_major else 1]
        b_smem_layout_atom = cute.nvgpu.warpgroup.make_smem_layout_atom(
            sm90_utils.get_smem_layout_atom(b_layout, b_dtype, b_major_mode_size),
            b_dtype,
        )
        b_smem_layout_staged = cute.tile_to_shape(
            b_smem_layout_atom,
            cute.append(b_smem_shape, ab_stage),
            order=(0, 1, 2) if b_is_k_major else (1, 0, 2),
        )

        sfa_smem_layout_staged = blockscaled_utils.sm120_make_smem_layout_sfa(
            tiled_mma,
            tile_shape_mnk,
            sf_vec_size,
            ab_stage,
        )
        sfb_smem_layout_staged = blockscaled_utils.sm120_make_smem_layout_sfb(
            tiled_mma,
            tile_shape_mnk,
            sf_vec_size,
            ab_stage,
        )

        c_smem_shape = epi_tile
        c_major_mode_size = epi_tile[1] if c_layout.is_n_major_c() else epi_tile[0]
        c_smem_layout_atom = cute.nvgpu.warpgroup.make_smem_layout_atom(
            sm90_utils.get_smem_layout_atom(c_layout, c_dtype, c_major_mode_size),
            c_dtype,
        )
        epi_smem_layout_staged = cute.tile_to_shape(
            c_smem_layout_atom,
            cute.append(c_smem_shape, epi_stage),
            order=(1, 0, 2) if c_layout.is_m_major_c() else (0, 1, 2),
        )

        return (
            a_smem_layout_staged,
            b_smem_layout_staged,
            sfa_smem_layout_staged,
            sfb_smem_layout_staged,
            epi_smem_layout_staged,
        )

    @staticmethod
    def is_valid_tensor_alignment(
        m, n, k, l, ab_dtype, c_dtype, a_major, b_major, c_major
    ):
        def check(dtype, is_mode0_major, shape):
            major = shape[0 if is_mode0_major else 1]
            return major % (16 * 8 // dtype.width) == 0

        return (
            check(ab_dtype, a_major == "m", (m, k, l))
            and check(ab_dtype, b_major == "n", (n, k, l))
            and check(c_dtype, c_major == "m", (m, n, l))
        )

    @staticmethod
    def can_implement(
        mnkl: Tuple[int, int, int, int],
        a_dtype: Type[cutlass.Numeric],
        b_dtype: Type[cutlass.Numeric],
        c_dtype: Type[cutlass.Numeric],
        acc_dtype: Type[cutlass.Numeric],
        sf_dtype: Type[cutlass.Numeric],
        sf_vec_size: int,
        a_major: str,
        b_major: str,
        c_major: str,
        tile_shape_mnk: Tuple[int, int, int],
        cluster_shape_mn: Tuple[int, int] = (1, 1),
    ) -> Optional[str]:
        """Validate a kernel configuration against the documented constraints.

        Single source of truth for the CLI and tests; mirrors the "Constraints"
        section of the module docstring.

        :return: ``None`` if the configuration is supported, otherwise a
                 human-readable reason string.
        """
        # Input dtypes: Float4E2M1FN only.
        if a_dtype != cutlass.Float4E2M1FN or b_dtype != cutlass.Float4E2M1FN:
            return f"A/B dtype must be Float4E2M1FN, got A={a_dtype}, B={b_dtype}."
        # Float32 accumulation only.
        if acc_dtype != cutlass.Float32:
            return f"Accumulation dtype must be Float32, got {acc_dtype}."
        # Scale-factor vector size: 16 or 32 (sets the K-divisibility requirement).
        if sf_vec_size not in (16, 32):
            return f"sf_vec_size must be 16 or 32, got {sf_vec_size}."
        # sf_vec_size=16 uses an E4M3 scale-factor source format.
        if sf_vec_size == 16 and sf_dtype != cutlass.Float8E4M3FN:
            return f"sf_vec_size=16 requires sf_dtype=Float8E4M3FN, got {sf_dtype}."
        # Majors: A row-major (k), B column-major (k), C row-major (n) only.
        if a_major != "k" or b_major != "k" or c_major != "n":
            return (
                f"Only a_major='k', b_major='k', c_major='n' are supported; "
                f"got a={a_major!r}, b={b_major!r}, c={c_major!r}."
            )
        # Cluster shape must be (1, 1) for Blackwell Geforce.
        if tuple(cluster_shape_mn) != (1, 1):
            return (
                f"Cluster shape must be (1, 1) for Blackwell Geforce, "
                f"got {tuple(cluster_shape_mn)}."
            )
        # CTA tile shape: M/N divisible by 128; K divisible by 64 (sf16) or 128 (sf32).
        tm, tn, tk = tile_shape_mnk
        if tm % 128 != 0 or tn % 128 != 0:
            return f"tile_shape_m/n must be divisible by 128, got ({tm}, {tn})."
        k_div = 64 if sf_vec_size == 16 else 128
        if tk % k_div != 0:
            return (
                f"tile_shape_k must be divisible by {k_div} for "
                f"sf_vec_size={sf_vec_size}, got {tk}."
            )
        # Per-operand 16B contiguous alignment for the problem size.
        m, n, k, l = mnkl
        if not Sm120BlockScaledGemmKernelPingpong.is_valid_tensor_alignment(
            m, n, k, l, a_dtype, c_dtype, a_major, b_major, c_major
        ):
            return (
                f"Tensor alignment requirement not met for mnkl={mnkl} "
                f"(per-operand 16B contiguous alignment)."
            )
        return None


@cute.jit
def cvt_sf_MKL_to_M32x4xrm_K4xrk_L(
    sf_ref_tensor: cute.Tensor,
    sf_mma_tensor: cute.Tensor,
):
    """Convert scale factor tensor from MKL layout to MMA M(32x4xrest_m)xK(4xrest_k)xL layout."""
    sf_mma_tensor = cute.group_modes(sf_mma_tensor, 0, 3)
    sf_mma_tensor = cute.group_modes(sf_mma_tensor, 1, 3)
    for i in cutlass.range(cute.size(sf_ref_tensor)):
        mkl_coord = sf_ref_tensor.layout.get_hier_coord(i)
        sf_mma_tensor[mkl_coord] = sf_ref_tensor[mkl_coord]


def run(
    mnkl,
    a_dtype,
    b_dtype,
    sf_dtype,
    sf_vec_size,
    c_dtype,
    a_major="k",
    b_major="k",
    c_major="n",
    tile_shape_mnk=(128, 128, 128),
    epi_tile=(128, 128),
    tolerance=1e-01,
    warmup_iterations=0,
    iterations=1,
    skip_ref_check=False,
    use_cold_l2=False,
    **kwargs,
):
    return run_bs(
        mnkl=mnkl,
        a_dtype=a_dtype,
        b_dtype=b_dtype,
        sf_dtype=sf_dtype,
        sf_vec_size=sf_vec_size,
        c_dtype=c_dtype,
        acc_dtype=cutlass.Float32,
        a_major=a_major,
        b_major=b_major,
        c_major=c_major,
        tile_shape_mnk=tile_shape_mnk,
        epi_tile=epi_tile,
        tolerance=tolerance,
        warmup_iterations=warmup_iterations,
        iterations=iterations,
        skip_ref_check=skip_ref_check,
        use_cold_l2=use_cold_l2,
    )


def run_bs(
    mnkl,
    a_dtype,
    b_dtype,
    sf_dtype,
    sf_vec_size,
    c_dtype,
    acc_dtype,
    a_major,
    b_major,
    c_major,
    tile_shape_mnk,
    epi_tile,
    tolerance,
    warmup_iterations,
    iterations,
    skip_ref_check,
    use_cold_l2=False,
    **kwargs,
):
    import torch
    import cutlass.torch as cutlass_torch

    print("Running Blackwell Geforce Blockscaled Dense GEMM (ping-pong) with:")
    print("  (cute_ext.*: allocate, TMAToAsyncPipeline, tma_load, dot_block_scaled,")
    print("   partition_and_copy, TMAStorePipeline, tma_store, compile)")
    print(f"mnkl: {mnkl}")
    print(
        f"A dtype: {a_dtype}, B dtype: {b_dtype}, "
        f"A/B scale factor dtype: {sf_dtype}, C dtype: {c_dtype}, Acc dtype: {acc_dtype}"
    )
    print(f"Matrix majors - A: {a_major}, B: {b_major}, C: {c_major}")
    print(f"Tile Shape: {tile_shape_mnk}")
    print(f"Epilogue tile: {epi_tile}")
    print(f"Tolerance: {tolerance}")

    m, n, k, l = mnkl

    reason = Sm120BlockScaledGemmKernelPingpong.can_implement(
        mnkl,
        a_dtype,
        b_dtype,
        c_dtype,
        acc_dtype,
        sf_dtype,
        sf_vec_size,
        a_major,
        b_major,
        c_major,
        tile_shape_mnk,
    )
    if reason is not None:
        raise ValueError(f"Unsupported configuration: {reason}")

    a_dtype = getattr(cutlass, a_dtype) if isinstance(a_dtype, str) else a_dtype
    b_dtype = getattr(cutlass, b_dtype) if isinstance(b_dtype, str) else b_dtype
    c_dtype = getattr(cutlass, c_dtype) if isinstance(c_dtype, str) else c_dtype
    acc_dtype = getattr(cutlass, acc_dtype) if isinstance(acc_dtype, str) else acc_dtype

    m, n, k, l = mnkl
    cluster_shape_mnk = (1, 1, 1)

    if not torch.cuda.is_available():
        raise RuntimeError("GPU is required to run this example!")

    a_ref = cutlass_torch.matrix(l, m, k, a_major == "m", cutlass.Float32)
    b_ref = cutlass_torch.matrix(l, n, k, b_major == "n", cutlass.Float32)
    c_ref = cutlass_torch.matrix(l, m, n, c_major == "m", cutlass.Float32)

    a_tensor, a_torch = cutlass_torch.cute_tensor_like(
        a_ref, a_dtype, is_dynamic_layout=True, assumed_align=16
    )
    b_tensor, b_torch = cutlass_torch.cute_tensor_like(
        b_ref, b_dtype, is_dynamic_layout=True, assumed_align=16
    )
    c_tensor, c_torch = cutlass_torch.cute_tensor_like(
        c_ref, c_dtype, is_dynamic_layout=True, assumed_align=16
    )

    a_tensor.mark_compact_shape_dynamic(
        mode=1 if a_major == "k" else 0,
        stride_order=(2, 0, 1) if a_major == "k" else (2, 1, 0),
        divisibility=2 if a_dtype == cutlass.Float4E2M1FN else 1,
    )
    b_tensor.mark_compact_shape_dynamic(
        mode=1 if b_major == "k" else 0,
        stride_order=(2, 0, 1) if b_major == "k" else (2, 1, 0),
        divisibility=2 if a_dtype == cutlass.Float4E2M1FN else 1,
    )
    c_tensor.mark_compact_shape_dynamic(
        mode=1 if c_major == "n" else 0,
        stride_order=(2, 0, 1) if c_major == "n" else (2, 1, 0),
        divisibility=2 if c_dtype == cutlass.Float4E2M1FN else 1,
    )

    def create_scale_factor_tensor(l, mn, k, sf_vec_size, dtype):
        def ceil_div(a, b):
            return (a + b - 1) // b

        sf_k = ceil_div(k, sf_vec_size)
        ref_shape = (l, mn, sf_k)

        atom_m = (32, 4)
        atom_k = 4
        mma_shape = (
            l,
            ceil_div(mn, atom_m[0] * atom_m[1]),
            ceil_div(sf_k, atom_k),
            atom_m[0],
            atom_m[1],
            atom_k,
        )

        ref_permute_order = (1, 2, 0)
        mma_permute_order = (3, 4, 1, 5, 2, 0)

        ref_f32_torch_tensor_cpu = cutlass_torch.create_and_permute_torch_tensor(
            ref_shape,
            torch.float32,
            permute_order=ref_permute_order,
            init_type=cutlass_torch.TensorInitType.RANDOM,
            init_config=cutlass_torch.RandomInitConfig(
                min_val=1,
                max_val=3,
            ),
        )

        cute_f32_torch_tensor_cpu = cutlass_torch.create_and_permute_torch_tensor(
            mma_shape,
            torch.float32,
            permute_order=mma_permute_order,
            init_type=cutlass_torch.TensorInitType.RANDOM,
            init_config=cutlass_torch.RandomInitConfig(
                min_val=0,
                max_val=1,
            ),
        )

        cvt_sf_MKL_to_M32x4xrm_K4xrk_L(
            from_dlpack(ref_f32_torch_tensor_cpu),
            from_dlpack(cute_f32_torch_tensor_cpu),
        )
        cute_f32_torch_tensor = cute_f32_torch_tensor_cpu.cuda()

        ref_f32_torch_tensor_cpu = (
            ref_f32_torch_tensor_cpu.permute(2, 0, 1)
            .unsqueeze(-1)
            .expand(l, mn, sf_k, sf_vec_size)
            .reshape(l, mn, sf_k * sf_vec_size)
            .permute(*ref_permute_order)
        )
        ref_f32_torch_tensor_cpu = ref_f32_torch_tensor_cpu[:, :k, :]

        cute_tensor, torch_tensor = cutlass_torch.cute_tensor_like(
            cute_f32_torch_tensor_cpu,
            dtype,
            is_dynamic_layout=True,
            assumed_align=16,
        )

        cute_tensor = cutlass_torch.convert_cute_tensor(
            cute_f32_torch_tensor,
            cute_tensor,
            dtype,
            is_dynamic_layout=True,
        )

        return ref_f32_torch_tensor_cpu, cute_tensor, torch_tensor

    sfa_ref, sfa_tensor, sfa_torch = create_scale_factor_tensor(
        l, m, k, sf_vec_size, sf_dtype
    )
    sfb_ref, sfb_tensor, sfb_torch = create_scale_factor_tensor(
        l, n, k, sf_vec_size, sf_dtype
    )

    gemm = Sm120BlockScaledGemmKernelPingpong(
        acc_dtype,
        sf_vec_size,
        tile_shape_mnk,
        epi_tile,
    )

    hardware_info = cutlass.utils.HardwareInfo()
    max_active_clusters = hardware_info.get_max_active_clusters(
        cluster_shape_mnk[0] * cluster_shape_mnk[1]
    )

    stream = cutlass_torch.default_stream()

    compiled_gemm = cute_ext.compile(
        gemm,
        a_tensor,
        b_tensor,
        sfa_tensor,
        sfb_tensor,
        c_tensor,
        max_active_clusters,
        stream,
    )

    if not skip_ref_check:
        print("Reference checking ...")
        compiled_gemm(a_tensor, b_tensor, sfa_tensor, sfb_tensor, c_tensor, stream)
        torch.cuda.synchronize()

        # Ref check
        res_a = torch.einsum("mkl,mkl->mkl", a_ref, sfa_ref)
        res_b = torch.einsum("nkl,nkl->nkl", b_ref, sfb_ref)
        ref = torch.einsum("mkl,nkl->mnl", res_a, res_b)

        c_ref_device = c_ref.cuda()
        cute.testing.convert(
            c_tensor,
            from_dlpack(c_ref_device, assumed_align=16).mark_layout_dynamic(
                leading_dim=(1 if c_major == "n" else 0)
            ),
        )
        c_ref = c_ref_device.cpu()

        if c_dtype in (cutlass.Float32, cutlass.Float16, cutlass.BFloat16):
            torch.testing.assert_close(c_ref, ref, atol=tolerance, rtol=1e-02)
        elif c_dtype in (cutlass.Float8E5M2, cutlass.Float8E4M3FN):
            ref_f8_ = torch.empty(*(l, m, n), dtype=torch.uint8, device="cuda").permute(
                1, 2, 0
            )
            ref_f8 = from_dlpack(ref_f8_, assumed_align=16).mark_layout_dynamic(
                leading_dim=1
            )
            ref_f8.element_type = c_dtype
            ref_device = ref.permute(2, 0, 1).contiguous().permute(1, 2, 0).cuda()
            ref_tensor = from_dlpack(ref_device, assumed_align=16).mark_layout_dynamic(
                leading_dim=1
            )
            cute.testing.convert(ref_tensor, ref_f8)
            cute.testing.convert(ref_f8, ref_tensor)
            ref = ref_device.cpu()
            torch.testing.assert_close(c_ref, ref, atol=tolerance, rtol=1e-02)

    def generate_tensors():
        a_t, _ = cutlass_torch.cute_tensor_like(
            a_ref, a_dtype, is_dynamic_layout=True, assumed_align=16
        )
        b_t, _ = cutlass_torch.cute_tensor_like(
            b_ref, b_dtype, is_dynamic_layout=True, assumed_align=16
        )
        c_t, _ = cutlass_torch.cute_tensor_like(
            c_ref, c_dtype, is_dynamic_layout=True, assumed_align=16
        )
        a_t.mark_compact_shape_dynamic(
            mode=1 if a_major == "k" else 0,
            stride_order=(2, 0, 1) if a_major == "k" else (2, 1, 0),
            divisibility=2 if a_dtype == cutlass.Float4E2M1FN else 1,
        )
        b_t.mark_compact_shape_dynamic(
            mode=1 if b_major == "k" else 0,
            stride_order=(2, 0, 1) if b_major == "k" else (2, 1, 0),
            divisibility=2 if a_dtype == cutlass.Float4E2M1FN else 1,
        )
        c_t.mark_compact_shape_dynamic(
            mode=1 if c_major == "n" else 0,
            stride_order=(2, 0, 1) if c_major == "n" else (2, 1, 0),
            divisibility=2 if c_dtype == cutlass.Float4E2M1FN else 1,
        )
        _, sfa_t, _ = create_scale_factor_tensor(l, m, k, sf_vec_size, sf_dtype)
        _, sfb_t, _ = create_scale_factor_tensor(l, n, k, sf_vec_size, sf_dtype)
        return cute.testing.JitArguments(a_t, b_t, sfa_t, sfb_t, c_t, stream)

    workspace_count = 1
    if use_cold_l2:
        one_workspace_bytes = (
            a_ref.numel() * a_ref.element_size()
            + b_ref.numel() * b_ref.element_size()
            + sfa_ref.numel() * sfa_ref.element_size()
            + sfb_ref.numel() * sfb_ref.element_size()
            + c_ref.numel() * c_ref.element_size()
        )
        workspace_count = testing.get_workspace_count(
            one_workspace_bytes, warmup_iterations, iterations
        )

    exec_time = testing.benchmark(
        compiled_gemm,
        workspace_generator=generate_tensors,
        workspace_count=workspace_count,
        stream=stream,
        warmup_iterations=warmup_iterations,
        iterations=iterations,
    )

    gflop = 2 * m * n * k / 1e9
    gflops = gflop / exec_time * 1e6

    print(f"Execution time: {exec_time} microseconds per iteration")
    print(f"GFLOPS: {gflops}")

    return exec_time


def parse_arguments():
    parser = argparse.ArgumentParser(
        description="Example of MxNxKxL Blockscaled GEMM on Blackwell Geforce (ping-pong)."
    )
    cli.add_mnkl_arg(parser, default=(256, 256, 256, 1), strict_length=True)
    cli.add_dtype_args(parser, c=cutlass.Float16)
    # This kernel only builds the K/K/N layout combination.
    cli.add_major_args(parser, a=["k"], b=["k"], c=["n"])
    cli.add_benchmark_args(parser)

    parser.add_argument(
        "--tile_shape_mnk",
        type=cli.comma_separated_ints,
        choices=[(128, 128, 128), (128, 128, 256)],
        default=(128, 128, 128),
    )
    parser.add_argument(
        "--epi_tile",
        type=cli.comma_separated_ints,
        choices=[(128, 128), (64, 32)],
        default=(128, 128),
    )
    # A, B and the scale factors carry separate dtypes on this kernel.
    parser.add_argument("--a_dtype", type=cutlass.dtype, default=cutlass.Float4E2M1FN)
    parser.add_argument("--b_dtype", type=cutlass.dtype, default=cutlass.Float4E2M1FN)
    parser.add_argument("--sf_dtype", type=cutlass.dtype, default=cutlass.Float8E4M3FN)
    parser.add_argument("--sf_vec_size", type=int, choices=[16], default=16)

    return parser.parse_args()


if __name__ == "__main__":
    args = parse_arguments()
    run_bs(
        args.mnkl,
        args.a_dtype,
        args.b_dtype,
        args.sf_dtype,
        args.sf_vec_size,
        args.c_dtype,
        args.acc_dtype,
        args.a_major,
        args.b_major,
        args.c_major,
        args.tile_shape_mnk,
        args.epi_tile,
        args.tolerance,
        args.warmup_iterations,
        args.iterations,
        args.skip_ref_check,
        args.use_cold_l2,
    )
    print("PASS")
