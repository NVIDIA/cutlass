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

"""SM107 Rubin NVFP4 block-scaled GEMM, 2-CTA cluster, warp-specialized (cutlass DSL).

Tile 512x256x256 persistent work tile on a default (2, 1, 1) cluster with two
M-stacked collective M=256/N=256/K=256 CTA_2 tiles.  Each K macro-tile issues
two K=128 SM107 ``tcgen05.mma.cta_group::2.kind::mxf4nvf4.block_scale.block32``
operations per M-stack slice.  A and B are packed ``Float4E2M1FNx2`` tensors;
scale factors are ``FloatNV8E5M3FNU`` with ``sf_vec_size=32``; accumulators are
FP32 and C is BF16.  The mainloop emits raw cutlass/NVVM calls through
``prims.tcgen05_mma_block_scale`` and ``prims.Tcgen05SmemDesc.build``.

The A/B/SFA/SFB mainloop stages data in exact K=256 chunks through a six-stage
SMEM ring that fits under the SM107 opt-in shared-memory limit.  The two
M-stack slices use distinct A/SFA payloads and reuse the same B/SFB collector
path.  The cluster shape is configurable for power-of-two CTA_2 cluster shapes with
``cluster_m * cluster_n <= 16`` via ``--cluster-m`` and ``--cluster-n``; mixed
cluster launch defaults to a fallback ``(2, 1, 1)`` cluster and can be overridden
with ``--fallback-cluster-m`` and ``--fallback-cluster-n``.
A and SFA can multicast across N peers that share the same M CTA_2 pair, while
B and SFB can multicast across M CTA_2 pairs that share the same N tile.  The
epilogue drains TMEM directly to BF16 output with 256-bit no-allocate global
stores.  Sparse inputs, other scale-factor formats, and TMA-store epilogues
are out of scope.  Requires ``CUTE_DSL_ARCH=sm_107a``.

To run::

    CUTE_DSL_ARCH=sm_107a python examples/CuTeDSL/experimental/rubin/kernel/blockscaled_gemm/dense_blockscaled_gemm_persistent.py --mnkl 512,256,256,1
    CUTE_DSL_ARCH=sm_107a python examples/CuTeDSL/experimental/rubin/kernel/blockscaled_gemm/dense_blockscaled_gemm_persistent.py --mnkl 4608,15360,65536,1 --cluster-m 2 --cluster-n 4 --fallback-cluster-m 2 --fallback-cluster-n 1 --benchmark

"""

import argparse
import math
import time
from collections.abc import Callable
from functools import lru_cache

import numpy as np
import torch

import cutlass
import cutlass.cute as cute
import cutlass.experimental.cuda as cuda
import cutlass.torch as cutlass_torch
import cutlass.utils as utils
from cutlass.cute.runtime import (
    make_fake_compact_tensor,
    make_fake_stream,
)
from cutlass.experimental import primitives as prims
from pathlib import Path

import sys

if __name__ == "__main__":
    # `helpers` sits at the examples/CuTeDSL root; running this file as a
    # script only puts its own directory on sys.path.
    cutedsl_dir = str(Path(__file__).resolve().parents[4])
    if cutedsl_dir not in sys.path:
        sys.path.insert(0, cutedsl_dir)

from helpers.static_persistent_tile_scheduler import (
    PersistentTileSchedulerParams,
    StaticPersistentTileScheduler,
)


# ---------------------------------------------------------------------------
# Kernel configuration
# ---------------------------------------------------------------------------

AB_DTYPE = cutlass.Float4E2M1FN
SF_DTYPE = cutlass.FloatNV8E5M3FNU
C_DTYPE = cutlass.BFloat16
ACC_DTYPE = cutlass.Float32

SCALE_FORMAT_UE5M3 = prims.MxScaleFormat.UE5M3
SF_VEC = 32
SF_K_BLOCK = 4
SF_ATOM_MN = 128
SF_ATOM_K = SF_VEC * SF_K_BLOCK
SF_ATOM_BYTES = 512
SF_ATOM_U16 = SF_ATOM_BYTES // 2
SF_TMEM_COLS_PER_ATOM = 4

CTA_PAIR_SIZE = 2
DEFAULT_CLUSTER_M = 2
DEFAULT_CLUSTER_N = 1
DEFAULT_FALLBACK_CLUSTER_M = 2
DEFAULT_FALLBACK_CLUSTER_N = 1
COLLECTIVE_M = 256
TILE_M_PER_CTA = 128
M_STACK = 2
TILE_M = COLLECTIVE_M * M_STACK
TILE_M_PER_CTA_STACK = TILE_M_PER_CTA * M_STACK
TILE_N = 256
TILE_N_PER_CTA = 128
TILE_K = 256
ACC_TMEM_COLS = TILE_N * M_STACK
NUM_ACC_STAGE = 1
SCALE_TMEM_COL_OFFSET = ACC_TMEM_COLS * NUM_ACC_STAGE
NUM_TMEM_ALLOC_COLS = 576
NUM_TMEM_DEALLOC_COLS = NUM_TMEM_ALLOC_COLS
SM107_SMEM_BUDGET_BYTES = 334_848

EPILOG_WARPS = (0, 1, 2, 3)
EPILOG_THREADS = 32 * len(EPILOG_WARPS)
EPILOG_BARRIER_ID = 1
MMA_WARP = 4
TMA_WARP = 5
THREADS_PER_CTA = 192

MMA_K_GRANULE = 128

MMA_A_B_STAGE_BYTES = TILE_M_PER_CTA * TILE_K // 2
MMA_A_STACK_STAGE_BYTES = MMA_A_B_STAGE_BYTES * M_STACK
MMA_B_STAGE_BYTES = TILE_N_PER_CTA * TILE_K // 2
SF_KBLOCKS_PER_TILE = TILE_K // SF_ATOM_K
MMA_KBLOCKS_PER_TILE = TILE_K // MMA_K_GRANULE
SFA_STAGE_BYTES = SF_ATOM_BYTES * SF_KBLOCKS_PER_TILE
SFA_STACK_STAGE_BYTES = SFA_STAGE_BYTES * M_STACK
SFB_STAGE_BYTES = SF_ATOM_BYTES * SF_KBLOCKS_PER_TILE * (TILE_N // SF_ATOM_MN)
EPI_SUBTILE_N = 64
EPI_C_STAGES = 0
EPI_C_STAGE_ELEMS = 0
EPI_C_STAGE_BYTES = 0
EPI_SUBTILES_N = TILE_N // EPI_SUBTILE_N
C_STAGE_ELEMS = 0
C_STAGE_BYTES = 0
STG256_ELEMS = 32 // (C_DTYPE.width // 8)
AB_SMEM_STAGE_BYTES = (
    MMA_A_STACK_STAGE_BYTES
    + MMA_B_STAGE_BYTES
    + SFA_STACK_STAGE_BYTES
    + SFB_STAGE_BYTES
)
NUM_AB_STAGE = (SM107_SMEM_BUDGET_BYTES - C_STAGE_BYTES) // AB_SMEM_STAGE_BYTES
if NUM_AB_STAGE < 2:
    raise ValueError(
        "SM107 SMEM budget permits fewer than two A/B/SF pipeline stages: "
        f"budget={SM107_SMEM_BUDGET_BYTES}, reserved_c={C_STAGE_BYTES}, "
        f"stage_bytes={AB_SMEM_STAGE_BYTES}"
    )
SMEM_MAJOR_BYTES = C_STAGE_BYTES + NUM_AB_STAGE * AB_SMEM_STAGE_BYTES
MMA_AB_DESC_STRIDE_BYTES = 8 * (TILE_K // 2)
MMA_AB_DESC_LAYOUT = prims.Tcgen05SmemSwizzle.SWIZZLE_128B
MMA_AB_KBLOCK_DESC_STRIDE_16B = (MMA_K_GRANULE // 2) >> 4
SFB_TMEM_COLS_PER_KBLOCK = SF_TMEM_COLS_PER_ATOM * (TILE_N // SF_ATOM_MN)
SFA_TMEM_COLS_PER_STACK_STAGE = SF_TMEM_COLS_PER_ATOM * SF_KBLOCKS_PER_TILE
SFA_TMEM_COLS_PER_STAGE = SFA_TMEM_COLS_PER_STACK_STAGE * M_STACK

_DEFAULT_MNKL: tuple[int, int, int, int] = (512, 256, 256, 1)
_DEFAULT_TOLERANCE: float = 0.0
_RANDOM_SEED = 20260709
NVFP4_PEAK_PFLOPS = 26.08


# ---------------------------------------------------------------------------
# Device kernel
# ---------------------------------------------------------------------------


@cute.jit
def _wait_mbarrier(mbar, phase) -> None:
    while not prims.mbarrier_try_wait_parity(mbar, phase, time_limit=10_000_000):
        pass


@cute.jit
def kernel_impl(
    tma_a_desc: cutlass.GridConstant[cuda.TensorMap],
    tma_b_desc: cutlass.GridConstant[cuda.TensorMap],
    tma_sfa_desc: cutlass.GridConstant[cuda.TensorMap],
    tma_sfb_desc: cutlass.GridConstant[cuda.TensorMap],
    c_tensor: cute.Tensor,
    problem_size: tuple,
    tile_sched_params: PersistentTileSchedulerParams,
    cluster_m: cutlass.Constexpr[int],
    cluster_n: cutlass.Constexpr[int],
) -> None:
    warp_idx = cute.arch.warp_idx()
    tidx, _, _ = cute.arch.thread_idx()
    cta_rank = cute.arch.block_idx_in_cluster()
    cluster_x = cta_rank % cutlass.Int32(cluster_m)
    cluster_y = cta_rank // cutlass.Int32(cluster_m)
    pair_lane = cta_rank & cutlass.Int32(1)
    pair_m = cluster_x >> cutlass.Int32(1)
    group_m_count: cutlass.Constexpr[int] = cluster_m // CTA_PAIR_SIZE
    a_sfa_selfcast: cutlass.Constexpr[bool] = cluster_n == 1
    b_sfb_selfcast: cutlass.Constexpr[bool] = group_m_count == 1
    pair_leader_rank = cluster_y * cutlass.Int32(cluster_m) + pair_m * CTA_PAIR_SIZE
    pair_mcast_mask = cutlass.Int32(3) << pair_leader_rank
    is_pair_leader = pair_lane == cutlass.Int32(0)
    a_mcast_rows: cutlass.Constexpr[int] = TILE_M_PER_CTA // cluster_n
    a_mcast_bytes: cutlass.Constexpr[int] = a_mcast_rows * TILE_K // 2
    b_mcast_rows: cutlass.Constexpr[int] = TILE_N_PER_CTA // group_m_count
    b_mcast_bytes: cutlass.Constexpr[int] = b_mcast_rows * TILE_K // 2
    # A receiver consumes shards from cluster-N peers and cluster-M pair peers.
    # The current pair is in both cohorts, so it is counted once.
    ab_empty_arrive_count: cutlass.Constexpr[int] = cluster_n + group_m_count - 1
    a_mcast_mask = cutlass.Int32(0)
    for peer_n in cutlass.range_constexpr(cluster_n):
        peer_rank = cutlass.Int32(peer_n * cluster_m) + cluster_x
        a_mcast_mask = a_mcast_mask + (cutlass.Int32(1) << peer_rank)
    b_mcast_mask = cutlass.Int32(0)
    for peer_pair_m in cutlass.range_constexpr(group_m_count):
        peer_rank = (
            cluster_y * cutlass.Int32(cluster_m)
            + cutlass.Int32(peer_pair_m * CTA_PAIR_SIZE)
            + pair_lane
        )
        b_mcast_mask = b_mcast_mask + (cutlass.Int32(1) << peer_rank)
    sfb_mcast_mask = cutlass.Int32(0)
    for peer_pair_m in cutlass.range_constexpr(group_m_count):
        peer_pair_leader = cluster_y * cutlass.Int32(cluster_m) + cutlass.Int32(
            peer_pair_m * CTA_PAIR_SIZE
        )
        sfb_mcast_mask = sfb_mcast_mask | (cutlass.Int32(3) << peer_pair_leader)
    ab_empty_mcast_mask = cutlass.Int32(0)
    for peer_n in cutlass.range_constexpr(cluster_n):
        peer_pair_leader = cutlass.Int32(peer_n * cluster_m) + pair_m * CTA_PAIR_SIZE
        ab_empty_mcast_mask = ab_empty_mcast_mask | (
            cutlass.Int32(3) << peer_pair_leader
        )
    for peer_pair_m in cutlass.range_constexpr(group_m_count):
        peer_pair_leader = cluster_y * cutlass.Int32(cluster_m) + cutlass.Int32(
            peer_pair_m * CTA_PAIR_SIZE
        )
        ab_empty_mcast_mask = ab_empty_mcast_mask | (
            cutlass.Int32(3) << peer_pair_leader
        )
    a_mcast_m_offset = cluster_y * cutlass.Int32(a_mcast_rows)
    a_mcast_smem_offset = cluster_y * cutlass.Int32(a_mcast_bytes)
    b_mcast_n_offset = pair_m * cutlass.Int32(b_mcast_rows)
    b_mcast_smem_offset = pair_m * cutlass.Int32(b_mcast_bytes)
    m, n, k, batch_count = problem_size

    ab_full_mbar = cutlass.Array(
        cutlass.Int64, NUM_AB_STAGE, space=cutlass.AddressSpace.smem, alignment=8
    )
    ab_empty_mbar = cutlass.Array(
        cutlass.Int64, NUM_AB_STAGE, space=cutlass.AddressSpace.smem, alignment=8
    )
    acc_full_mbar = cutlass.Array(
        cutlass.Int64, NUM_ACC_STAGE, space=cutlass.AddressSpace.smem, alignment=8
    )
    acc_empty_mbar = cutlass.Array(
        cutlass.Int64, NUM_ACC_STAGE, space=cutlass.AddressSpace.smem, alignment=8
    )
    tmem_ptr_i32 = cutlass.Array(
        cutlass.Int32, 1, space=cutlass.AddressSpace.smem, alignment=4
    )
    tmem_dealloc_mbar = cutlass.Array(
        cutlass.Int64, 1, space=cutlass.AddressSpace.smem, alignment=8
    )

    sA = cutlass.Array(
        cutlass.Int8,
        MMA_A_STACK_STAGE_BYTES * NUM_AB_STAGE,
        space=cutlass.AddressSpace.smem,
        alignment=1024,
    )
    sB = cutlass.Array(
        cutlass.Int8,
        MMA_B_STAGE_BYTES * NUM_AB_STAGE,
        space=cutlass.AddressSpace.smem,
        alignment=1024,
    )
    sSFA = cutlass.Array(
        cutlass.Int8,
        SFA_STACK_STAGE_BYTES * NUM_AB_STAGE,
        space=cutlass.AddressSpace.smem,
        alignment=512,
    )
    sSFB = cutlass.Array(
        cutlass.Int8,
        SFB_STAGE_BYTES * NUM_AB_STAGE,
        space=cutlass.AddressSpace.smem,
        alignment=512,
    )
    if warp_idx == 0:
        lane = tidx & 31
        if lane < NUM_AB_STAGE:
            prims.mbarrier_init(ab_full_mbar.subview(lane), 1)
            prims.mbarrier_init(ab_empty_mbar.subview(lane), ab_empty_arrive_count)
        if lane < NUM_ACC_STAGE:
            prims.mbarrier_init(acc_full_mbar.subview(lane), 1)
            prims.mbarrier_init(acc_empty_mbar.subview(lane), CTA_PAIR_SIZE)
        if lane == 0:
            # The dealloc handshake uses a warp-wide peer arrive.
            prims.mbarrier_init(tmem_dealloc_mbar, 32)

    prims.fence_mbarrier_init()
    prims.barrier_cluster_arrive_relaxed()
    prims.barrier_cluster_wait()

    if warp_idx == MMA_WARP:
        prims.tcgen05_alloc(
            tmem_ptr_i32,
            NUM_TMEM_ALLOC_COLS,
            group=prims.CTAGroup.CTA_2,
            is_exclusive=True,
        )

    prims.barrier_cta_sync(0)
    tmem_raw_addr = tmem_ptr_i32.load()
    acc_tmem_ptr = cutlass.inttoptr(tmem_raw_addr, 6, cutlass.Float32)

    num_k_tiles = cute.ceil_div(k, TILE_K)
    tma_tx_bytes_pair: cutlass.Constexpr[int] = (
        M_STACK * cluster_n * a_mcast_bytes
        + group_m_count * b_mcast_bytes
        + SFA_STACK_STAGE_BYTES
        + SFB_STAGE_BYTES
    ) * CTA_PAIR_SIZE

    tile_sched = StaticPersistentTileScheduler.create(
        tile_sched_params, cute.arch.block_idx(), cute.arch.grid_dim()
    )
    work_tile = tile_sched.initial_work_tile_info()

    if warp_idx == TMA_WARP and prims.elect_sync():
        prims.prefetch_tensormap(tma_a_desc.get_ptr())
        prims.prefetch_tensormap(tma_b_desc.get_ptr())
        prims.prefetch_tensormap(tma_sfa_desc.get_ptr())
        prims.prefetch_tensormap(tma_sfb_desc.get_ptr())

    if warp_idx == TMA_WARP:
        tma_stage = cutlass.Int32(0)
        tma_empty_phase = cutlass.Int32(1)
        while work_tile.is_valid_tile:
            tile_l = work_tile.tile_idx[2]
            tile_m_cluster = work_tile.tile_idx[0] // cutlass.Int32(cluster_m)
            tile_n_cluster = work_tile.tile_idx[1] // cutlass.Int32(cluster_n)
            coord_m_cluster = (
                tile_m_cluster * (cluster_m * TILE_M_PER_CTA_STACK) + pair_m * TILE_M
            )
            coord_n_cluster = tile_n_cluster * (cluster_n * TILE_N) + cluster_y * TILE_N
            coord_m_cta = coord_m_cluster + pair_lane * TILE_M_PER_CTA
            coord_n_cta = coord_n_cluster + pair_lane * TILE_N_PER_CTA
            coord_n_sf = coord_n_cluster // SF_ATOM_MN

            for k_tile_idx in cutlass.range(num_k_tiles, unroll=1):
                stage = tma_stage
                _wait_mbarrier(ab_empty_mbar.subview(stage), tma_empty_phase)

                coord_k = k_tile_idx * TILE_K
                coord_k_sf = k_tile_idx * SF_KBLOCKS_PER_TILE
                sfb_issuer_pair_m = k_tile_idx % cutlass.Int32(group_m_count)
                if is_pair_leader and prims.elect_sync():
                    prims.mbarrier_arrive_expect_tx(
                        ab_full_mbar.subview(stage), tma_tx_bytes_pair
                    )

                sA_stage = sA.subview(stage * MMA_A_STACK_STAGE_BYTES)
                sB_stage = sB.subview(stage * MMA_B_STAGE_BYTES)
                sSFA_stage = sSFA.subview(stage * SFA_STACK_STAGE_BYTES)
                sSFB_stage = sSFB.subview(stage * SFB_STAGE_BYTES)
                if prims.elect_sync():
                    # A/SFA: selfcast when there is one N peer; otherwise each
                    # N peer contributes one A shard and one peer multicasts SFA.
                    for m_stack in cutlass.range_constexpr(M_STACK):
                        coord_m_cta_slice = coord_m_cta + m_stack * COLLECTIVE_M
                        if cutlass.const_expr(a_sfa_selfcast):
                            prims.cp_async_bulk_tensor_shared_cluster_global(
                                sA_stage.subview(m_stack * MMA_A_B_STAGE_BYTES),
                                tma_a_desc.get_ptr(),
                                (coord_k, coord_m_cta_slice, tile_l),
                                ab_full_mbar.subview(stage),
                                [],
                                group=prims.CTAGroup.CTA_2,
                            )
                            prims.cp_async_bulk_tensor_shared_cluster_global(
                                sSFA_stage.subview(m_stack * SFA_STAGE_BYTES),
                                tma_sfa_desc.get_ptr(),
                                (
                                    0,
                                    coord_k_sf,
                                    coord_m_cta_slice // SF_ATOM_MN,
                                    tile_l,
                                ),
                                ab_full_mbar.subview(stage),
                                [],
                                group=prims.CTAGroup.CTA_2,
                            )
                        else:
                            prims.cp_async_bulk_tensor_shared_cluster_global(
                                sA_stage.subview(
                                    m_stack * MMA_A_B_STAGE_BYTES + a_mcast_smem_offset
                                ),
                                tma_a_desc.get_ptr(),
                                (coord_k, coord_m_cta_slice + a_mcast_m_offset, tile_l),
                                ab_full_mbar.subview(stage),
                                [],
                                multicast_mask=a_mcast_mask,
                                group=prims.CTAGroup.CTA_2,
                            )
                            sfa_stack_issuer_n = (
                                k_tile_idx + cutlass.Int32(m_stack)
                            ) % cutlass.Int32(cluster_n)
                            if cluster_y == sfa_stack_issuer_n:
                                prims.cp_async_bulk_tensor_shared_cluster_global(
                                    sSFA_stage.subview(m_stack * SFA_STAGE_BYTES),
                                    tma_sfa_desc.get_ptr(),
                                    (
                                        0,
                                        coord_k_sf,
                                        coord_m_cta_slice // SF_ATOM_MN,
                                        tile_l,
                                    ),
                                    ab_full_mbar.subview(stage),
                                    [],
                                    multicast_mask=a_mcast_mask,
                                    group=prims.CTAGroup.CTA_2,
                                )

                    # B: selfcast when there is one M pair; otherwise each
                    # pair contributes a B shard to all M peers in this N tile.
                    if cutlass.const_expr(b_sfb_selfcast):
                        prims.cp_async_bulk_tensor_shared_cluster_global(
                            sB_stage,
                            tma_b_desc.get_ptr(),
                            (coord_k, coord_n_cta, tile_l),
                            ab_full_mbar.subview(stage),
                            [],
                            group=prims.CTAGroup.CTA_2,
                        )
                    else:
                        prims.cp_async_bulk_tensor_shared_cluster_global(
                            sB_stage.subview(b_mcast_smem_offset),
                            tma_b_desc.get_ptr(),
                            (coord_k, coord_n_cta + b_mcast_n_offset, tile_l),
                            ab_full_mbar.subview(stage),
                            [],
                            multicast_mask=b_mcast_mask,
                            group=prims.CTAGroup.CTA_2,
                        )

                    # SFB: pair leader selfcasts to its CTA_2 pair when there is
                    # one M pair; otherwise rotate one M-pair issuer per K tile.
                    if is_pair_leader:
                        if cutlass.const_expr(b_sfb_selfcast):
                            prims.cp_async_bulk_tensor_shared_cluster_global(
                                sSFB_stage,
                                tma_sfb_desc.get_ptr(),
                                (0, coord_k_sf, coord_n_sf, tile_l),
                                ab_full_mbar.subview(stage),
                                [],
                                multicast_mask=pair_mcast_mask,
                                group=prims.CTAGroup.CTA_2,
                            )
                        else:
                            if pair_m == sfb_issuer_pair_m:
                                prims.cp_async_bulk_tensor_shared_cluster_global(
                                    sSFB_stage,
                                    tma_sfb_desc.get_ptr(),
                                    (0, coord_k_sf, coord_n_sf, tile_l),
                                    ab_full_mbar.subview(stage),
                                    [],
                                    multicast_mask=sfb_mcast_mask,
                                    group=prims.CTAGroup.CTA_2,
                                )
                tma_stage += 1
                if tma_stage == NUM_AB_STAGE:
                    tma_stage = cutlass.Int32(0)
                    tma_empty_phase = tma_empty_phase ^ 1
            tile_sched.advance_to_next_work()
            work_tile = tile_sched.get_current_work()

        # tma tail, enforce wait empty
        for _ in cutlass.range_constexpr(NUM_AB_STAGE):
            _wait_mbarrier(ab_empty_mbar.subview(tma_stage), tma_empty_phase)
            tma_stage += 1
            if tma_stage == NUM_AB_STAGE:
                tma_stage = cutlass.Int32(0)
                tma_empty_phase = tma_empty_phase ^ 1

    if warp_idx == MMA_WARP:
        mma_stage = cutlass.Int32(0)
        mma_full_phase = cutlass.Int32(0)
        acc_empty_phase = cutlass.Int32(1)
        base_col_id = tmem_raw_addr & 0xFFFF
        base_row_id = tmem_raw_addr >> 16
        sfa_col_id = base_col_id + SCALE_TMEM_COL_OFFSET
        sfb_col_id = sfa_col_id + SFA_TMEM_COLS_PER_STAGE
        sfa_tmem_addr_base = (base_row_id << 16) | sfa_col_id
        sfb_tmem_addr_base = (base_row_id << 16) | sfb_col_id
        sfa_s2t_shape, sfa_s2t_multicast = prims.S2TCopyMode.S2T_32x128b_WARPX4
        sfb_s2t_shape, sfb_s2t_multicast = prims.S2TCopyMode.S2T_32x128b_WARPX4

        desc_sfa_root = prims.Tcgen05SmemDesc.build(
            sSFA,
            leading_byte_offset=16,
            stride_byte_offset=128,
            version=0,
            base_offset=0,
            layout=0,
        )
        desc_sfb_root = prims.Tcgen05SmemDesc.build(
            sSFB,
            leading_byte_offset=16,
            stride_byte_offset=128,
            version=0,
            base_offset=0,
            layout=0,
        )
        desc_a_root = prims.Tcgen05SmemDesc.build(
            sA,
            leading_byte_offset=16,
            stride_byte_offset=MMA_AB_DESC_STRIDE_BYTES,
            version=0,
            base_offset=0,
            layout=MMA_AB_DESC_LAYOUT,
        )
        desc_b_root = prims.Tcgen05SmemDesc.build(
            sB,
            leading_byte_offset=16,
            stride_byte_offset=MMA_AB_DESC_STRIDE_BYTES,
            version=0,
            base_offset=0,
            layout=MMA_AB_DESC_LAYOUT,
        )
        idesc = prims.Tcgen05MxOmmaInstrDesc.build(
            a_dtype=AB_DTYPE,
            b_dtype=AB_DTYPE,
            scale_format=SCALE_FORMAT_UE5M3,
            a_sf_id=0,
            b_sf_id=0,
            a_sf_layout=0,
            m_dim=COLLECTIVE_M,
            n_dim=TILE_N,
            k_dim=2,
        )

        while work_tile.is_valid_tile:
            if is_pair_leader:
                _wait_mbarrier(acc_empty_mbar.subview(0), acc_empty_phase)
                acc_empty_phase = acc_empty_phase ^ 1

            for k_tile_idx in cutlass.range(num_k_tiles, unroll=1):
                stage = mma_stage
                if is_pair_leader:
                    _wait_mbarrier(ab_full_mbar.subview(stage), mma_full_phase)

                    desc_sfa_base = desc_sfa_root + stage * (SFA_STACK_STAGE_BYTES >> 4)
                    for m_stack in cutlass.range_constexpr(M_STACK):
                        desc_sfa_stack = desc_sfa_base + m_stack * (
                            SFA_STAGE_BYTES >> 4
                        )
                        sfa_tmem_stack_base = (
                            sfa_tmem_addr_base + m_stack * SFA_TMEM_COLS_PER_STACK_STAGE
                        )
                        for kblock_idx in cutlass.range_constexpr(MMA_KBLOCKS_PER_TILE):
                            sfa_tmem_ptr = cutlass.inttoptr(
                                sfa_tmem_stack_base
                                + kblock_idx * SF_TMEM_COLS_PER_ATOM,
                                6,
                                cutlass.Int32,
                            )
                            desc_sfa = desc_sfa_stack + kblock_idx * (
                                SF_ATOM_BYTES >> 4
                            )
                            if prims.elect_sync():
                                prims.tcgen05_cp(
                                    sfa_s2t_shape,
                                    sfa_tmem_ptr,
                                    desc_sfa,
                                    group=prims.CTAGroup.CTA_2,
                                    multicast=sfa_s2t_multicast,
                                )
                    desc_sfb_base = desc_sfb_root + stage * (SFB_STAGE_BYTES >> 4)
                    for kblock_idx in cutlass.range_constexpr(MMA_KBLOCKS_PER_TILE):
                        for n_atom in cutlass.range_constexpr(TILE_N // SF_ATOM_MN):
                            sfb_tmem_ptr = cutlass.inttoptr(
                                sfb_tmem_addr_base
                                + kblock_idx * SFB_TMEM_COLS_PER_KBLOCK
                                + n_atom * SF_TMEM_COLS_PER_ATOM,
                                6,
                                cutlass.Int32,
                            )
                            desc_sfb = desc_sfb_base + (
                                n_atom * SF_KBLOCKS_PER_TILE + kblock_idx
                            ) * (SF_ATOM_BYTES >> 4)
                            if prims.elect_sync():
                                prims.tcgen05_cp(
                                    sfb_s2t_shape,
                                    sfb_tmem_ptr,
                                    desc_sfb,
                                    group=prims.CTAGroup.CTA_2,
                                    multicast=sfb_s2t_multicast,
                                )

                    desc_a_stage_base = desc_a_root + stage * (
                        MMA_A_STACK_STAGE_BYTES >> 4
                    )
                    desc_b_base = desc_b_root + stage * (MMA_B_STAGE_BYTES >> 4)
                    for kblock_idx in cutlass.range_constexpr(MMA_KBLOCKS_PER_TILE):
                        desc_b = desc_b_base + (
                            kblock_idx * MMA_AB_KBLOCK_DESC_STRIDE_16B
                        )
                        sfb_mma_ptr = cutlass.inttoptr(
                            sfb_tmem_addr_base + kblock_idx * SFB_TMEM_COLS_PER_KBLOCK,
                            6,
                            cutlass.Int32,
                        )
                        if cutlass.const_expr(kblock_idx == 0):
                            enable_input_d = k_tile_idx != 0
                        else:
                            enable_input_d = True
                        for m_stack in cutlass.range_constexpr(M_STACK):
                            acc_tmem_stack_ptr = cutlass.inttoptr(
                                tmem_raw_addr + m_stack * cutlass.Int32(TILE_N),
                                6,
                                cutlass.Float32,
                            )
                            desc_a_base = desc_a_stage_base + m_stack * (
                                MMA_A_B_STAGE_BYTES >> 4
                            )
                            desc_a = desc_a_base + (
                                kblock_idx * MMA_AB_KBLOCK_DESC_STRIDE_16B
                            )
                            sfa_mma_ptr = cutlass.inttoptr(
                                sfa_tmem_addr_base
                                + m_stack * SFA_TMEM_COLS_PER_STACK_STAGE
                                + kblock_idx * SF_TMEM_COLS_PER_ATOM,
                                6,
                                cutlass.Int32,
                            )
                            # collector_op controls A; b_collector_op controls
                            # B.  M-stacking changes A/SFA per slice and reuses
                            # B/SFB across the two slices.
                            if prims.elect_sync():
                                if cutlass.const_expr(m_stack == 0):
                                    prims.tcgen05_mma_block_scale(
                                        prims.MMABlockScaleKind.MXF4NVF4,
                                        prims.CTAGroup.CTA_2,
                                        acc_tmem_stack_ptr,
                                        desc_a,
                                        desc_b,
                                        idesc,
                                        enable_input_d=enable_input_d,
                                        scale_a=sfa_mma_ptr,
                                        scale_b=sfb_mma_ptr,
                                        scale_vec_size=prims.Tcgen05MMABlockScale.BLOCK32,
                                        collector_op=prims.Tcgen05MMACollectorOp.DISCARD,
                                        b_collector_op=prims.Tcgen05MMACollectorOp.FILL,
                                    )
                                else:
                                    prims.tcgen05_mma_block_scale(
                                        prims.MMABlockScaleKind.MXF4NVF4,
                                        prims.CTAGroup.CTA_2,
                                        acc_tmem_stack_ptr,
                                        desc_a,
                                        desc_b,
                                        idesc,
                                        enable_input_d=enable_input_d,
                                        scale_a=sfa_mma_ptr,
                                        scale_b=sfb_mma_ptr,
                                        scale_vec_size=prims.Tcgen05MMABlockScale.BLOCK32,
                                        collector_op=prims.Tcgen05MMACollectorOp.DISCARD,
                                        b_collector_op=prims.Tcgen05MMACollectorOp.LASTUSE,
                                    )

                    if prims.elect_sync():
                        prims.tcgen05_commit(
                            ab_empty_mbar.subview(stage),
                            multicast_mask=ab_empty_mcast_mask,
                            group=prims.CTAGroup.CTA_2,
                        )
                mma_stage += 1
                if mma_stage == NUM_AB_STAGE:
                    mma_stage = cutlass.Int32(0)
                    mma_full_phase = mma_full_phase ^ 1

            if is_pair_leader:
                if prims.elect_sync():
                    prims.tcgen05_commit(
                        acc_full_mbar.subview(0),
                        multicast_mask=pair_mcast_mask,
                        group=prims.CTAGroup.CTA_2,
                    )

            tile_sched.advance_to_next_work()
            work_tile = tile_sched.get_current_work()

    if warp_idx < MMA_WARP:
        acc_full_phase = cutlass.Int32(0)
        while work_tile.is_valid_tile:
            tile_l = work_tile.tile_idx[2]
            tile_m_cluster = work_tile.tile_idx[0] // cutlass.Int32(cluster_m)
            tile_n_cluster = work_tile.tile_idx[1] // cutlass.Int32(cluster_n)
            coord_m_cluster = (
                tile_m_cluster * (cluster_m * TILE_M_PER_CTA_STACK) + pair_m * TILE_M
            )
            coord_n_cluster = tile_n_cluster * (cluster_n * TILE_N) + cluster_y * TILE_N
            coord_m_cta = coord_m_cluster + pair_lane * TILE_M_PER_CTA

            _wait_mbarrier(acc_full_mbar.subview(0), acc_full_phase)
            acc_full_phase = acc_full_phase ^ 1

            tmem_sp = warp_idx % cutlass.Int32(4)
            lane = tidx & cutlass.Int32(31)
            row_in_cta = tmem_sp * cutlass.Int32(32) + lane

            base_col_id = tmem_raw_addr & 0xFFFF
            base_row_id = tmem_raw_addr >> 16
            row_id_with_warp = base_row_id + tmem_sp * cutlass.Int32(32)
            gC_arr = cutlass.make_array_view(c_tensor)

            for m_stack in cutlass.range_constexpr(M_STACK):
                acc_col_id = base_col_id + m_stack * cutlass.Int32(TILE_N)
                cur_tmem_col_addr = (row_id_with_warp << 16) | acc_col_id
                coord_m_cta_slice = coord_m_cta + m_stack * COLLECTIVE_M
                row = coord_m_cta_slice + row_in_cta
                row_in_bounds = row < m

                for epi_subtile_idx in cutlass.range_constexpr(EPI_SUBTILES_N):
                    epi_col_base = epi_subtile_idx * EPI_SUBTILE_N
                    for chunk_idx in cutlass.range_constexpr(EPI_SUBTILE_N // 32):
                        subtile_col_offset = epi_col_base + chunk_idx * 32
                        tmem = cutlass.inttoptr(
                            cur_tmem_col_addr + subtile_col_offset,
                            6,
                            cutlass.Float32,
                        )
                        c_rmem_vec = prims.tcgen05_ld("32x32b", tmem, num=32)
                        prims.tcgen05_wait(prims.Tcgen05Wait.LOAD)
                        c_bf16_vec = c_rmem_vec.to(C_DTYPE)
                        for stg_idx in cutlass.range_constexpr(32 // STG256_ELEMS):
                            col = (
                                coord_n_cluster
                                + epi_col_base
                                + chunk_idx * 32
                                + stg_idx * STG256_ELEMS
                            )
                            if row_in_bounds:
                                if col + STG256_ELEMS <= n:
                                    c_linear_idx = tile_l * m * n + row * n + col
                                    vec = c_bf16_vec[
                                        stg_idx * STG256_ELEMS : (stg_idx + 1)
                                        * STG256_ELEMS
                                    ]
                                    (
                                        gC_arr.subview(c_linear_idx)
                                    ).data_ptr().nvvm_store_ext(
                                        vec, evict=prims.EvictPriority.NOALLOCATE
                                    )

            prims.tcgen05_fence(prims.Tcgen05Fence.BEFORE_THREAD_SYNC)
            prims.barrier_cta_sync(EPILOG_BARRIER_ID, thread_count=EPILOG_THREADS)
            if warp_idx == 0 and prims.elect_sync():
                leader_acc_empty_mbar = prims.mapa(
                    acc_empty_mbar.subview(0), pair_leader_rank
                )
                prims.mbarrier_arrive(leader_acc_empty_mbar, relaxed=True)

            tile_sched.advance_to_next_work()
            work_tile = tile_sched.get_current_work()

    prims.tcgen05_fence(prims.Tcgen05Fence.BEFORE_THREAD_SYNC)
    prims.barrier_cta_sync(0)
    if warp_idx == 0:
        prims.tcgen05_relinquish_alloc_permit(group=prims.CTAGroup.CTA_2)
        peer_cta_rank = cta_rank ^ 1
        peer_mbar = prims.mapa(tmem_dealloc_mbar, peer_cta_rank)
        prims.mbarrier_arrive(peer_mbar, count=1, scope=prims.MemScope.CTA)
        _wait_mbarrier(tmem_dealloc_mbar, 0)
        prims.tcgen05_dealloc(
            acc_tmem_ptr,
            NUM_TMEM_DEALLOC_COLS,
            group=prims.CTAGroup.CTA_2,
            is_exclusive=True,
        )


@cute.kernel
def kernel(
    tma_a_desc: cutlass.GridConstant[cuda.TensorMap],
    tma_b_desc: cutlass.GridConstant[cuda.TensorMap],
    tma_sfa_desc: cutlass.GridConstant[cuda.TensorMap],
    tma_sfb_desc: cutlass.GridConstant[cuda.TensorMap],
    fallback_tma_a_desc: cutlass.GridConstant[cuda.TensorMap],
    fallback_tma_b_desc: cutlass.GridConstant[cuda.TensorMap],
    fallback_tma_sfa_desc: cutlass.GridConstant[cuda.TensorMap],
    fallback_tma_sfb_desc: cutlass.GridConstant[cuda.TensorMap],
    c_tensor: cute.Tensor,
    problem_size: tuple,
    tile_sched_params: PersistentTileSchedulerParams,
    fallback_tile_sched_params: PersistentTileSchedulerParams,
    cluster_m: cutlass.Constexpr[int],
    cluster_n: cutlass.Constexpr[int],
    fallback_cluster_m: cutlass.Constexpr[int],
    fallback_cluster_n: cutlass.Constexpr[int],
) -> None:
    cbdim_x, cbdim_y, cbdim_z = cute.arch.block_in_cluster_dim()
    is_preferred_cluster = (
        cbdim_x == cluster_m and cbdim_y == cluster_n and cbdim_z == 1
    )

    if is_preferred_cluster:
        kernel_impl(
            tma_a_desc,
            tma_b_desc,
            tma_sfa_desc,
            tma_sfb_desc,
            c_tensor,
            problem_size,
            tile_sched_params,
            cluster_m,
            cluster_n,
        )
    else:
        kernel_impl(
            fallback_tma_a_desc,
            fallback_tma_b_desc,
            fallback_tma_sfa_desc,
            fallback_tma_sfb_desc,
            c_tensor,
            problem_size,
            fallback_tile_sched_params,
            fallback_cluster_m,
            fallback_cluster_n,
        )


# ---------------------------------------------------------------------------
# CPU codecs and tensor preparation
# ---------------------------------------------------------------------------

FP4_LUT = np.array(
    [0.0, 0.5, 1.0, 1.5, 2.0, 3.0, 4.0, 6.0],
    dtype=np.float32,
)
SIGNED_FP4_LUT = np.concatenate([FP4_LUT, -FP4_LUT]).astype(np.float32)

UE5M3_BIAS = 15
UE5M3_NAN_BYTE = 0xFF
UE5M3_MAX_FINITE = (2.0**16) * 1.75


def _ue5m3_decode(byte: int) -> float:
    if byte == UE5M3_NAN_BYTE:
        return float("nan")
    exp = (byte >> 3) & 0x1F
    mant = byte & 0x07
    if exp == 0:
        return (2.0 ** (1 - UE5M3_BIAS)) * (mant / 8.0)
    return (2.0 ** (exp - UE5M3_BIAS)) * (1.0 + mant / 8.0)


def _ue5m3_encode_rn(value: float) -> int:
    if math.isnan(value):
        return UE5M3_NAN_BYTE
    if value <= 0.0:
        return 0
    if value >= UE5M3_MAX_FINITE:
        return 0xFE
    best_byte = 0
    best_diff = float("inf")
    for byte in range(0xFF):
        decoded = _ue5m3_decode(byte)
        diff = abs(decoded - value)
        if diff < best_diff or (diff == best_diff and (byte & 1) == 0):
            best_diff = diff
            best_byte = byte
    return best_byte


def _quantize_fp4(x: np.ndarray) -> np.ndarray:
    flat = x.astype(np.float32, copy=False).reshape(-1)
    diff = np.abs(flat[:, None] - SIGNED_FP4_LUT[None, :])
    return np.argmin(diff, axis=1).astype(np.uint8).reshape(x.shape)


def _decode_fp4(codes: np.ndarray) -> np.ndarray:
    return SIGNED_FP4_LUT[codes.astype(np.int32)]


def _pack_k_major(codes_lmk: np.ndarray) -> np.ndarray:
    l, m, k = codes_lmk.shape
    if k % 2 != 0:
        raise ValueError("K must be even for packed FP4")
    out = np.empty((k // 2, m, l), dtype=np.uint8, order="F")
    even = np.transpose(codes_lmk[:, :, 0::2], (2, 1, 0))
    odd = np.transpose(codes_lmk[:, :, 1::2], (2, 1, 0))
    out[...] = (even & 0x0F) | ((odd & 0x0F) << 4)
    return out


def _f32_to_bf16_bits_rne(values: np.ndarray) -> np.ndarray:
    u32 = values.astype(np.float32, copy=False).view(np.uint32)
    lsb = (u32 >> 16) & 1
    rounded = u32 + 0x7FFF + lsb
    return (rounded >> 16).astype(np.uint16)


def cvt_sf_MKL_to_M32x4xrm_K4xrk_L(scale_bytes_lxk: np.ndarray) -> np.ndarray:
    """CPU equivalent of the tutorial scale-factor layout conversion helper."""
    l, mn, sf_k = scale_bytes_lxk.shape
    if mn % SF_ATOM_MN != 0:
        raise ValueError(f"scale MN={mn} must be divisible by {SF_ATOM_MN}")
    if sf_k % SF_K_BLOCK != 0:
        raise ValueError(f"scale K={sf_k} must be divisible by {SF_K_BLOCK}")

    x_atoms = mn // SF_ATOM_MN
    rest_k = sf_k // SF_K_BLOCK
    byte_storage = np.empty((SF_ATOM_BYTES, rest_k, x_atoms, l), dtype=np.uint8)
    for batch in range(l):
        for x_atom in range(x_atoms):
            for k_atom in range(rest_k):
                scale_atom = scale_bytes_lxk[
                    batch,
                    x_atom * SF_ATOM_MN : (x_atom + 1) * SF_ATOM_MN,
                    k_atom * SF_K_BLOCK : (k_atom + 1) * SF_K_BLOCK,
                ]
                for m1 in range(4):
                    for m0 in range(32):
                        byte_base = m0 * 16 + m1 * 4
                        row = m1 * 32 + m0
                        byte_storage[
                            byte_base : byte_base + SF_K_BLOCK, k_atom, x_atom, batch
                        ] = scale_atom[row, :]

    lo = byte_storage[0::2, :, :, :].astype(np.uint16)
    hi = byte_storage[1::2, :, :, :].astype(np.uint16)
    return lo | (hi << 8)


def _make_scale_factor_ref(
    l: int,  # noqa: E741
    mn: int,
    sf_k: int,
    rng: np.random.Generator | None = None,
) -> tuple[np.ndarray, np.ndarray]:
    """Create logical UE5M3 scale bytes and decoded values in ``(L, MN, SF_K)``."""
    if rng is None:
        rng = np.random.default_rng(20260701)
    scale_choices = np.array([0.5, 0.75, 1.0, 1.25, 1.5, 2.0], dtype=np.float32)
    encoded_choices = np.array(
        [_ue5m3_encode_rn(float(value)) for value in scale_choices],
        dtype=np.uint8,
    )
    decoded_choices = np.array(
        [_ue5m3_decode(int(byte)) for byte in encoded_choices],
        dtype=np.float32,
    )
    choice_idx = rng.integers(0, len(scale_choices), size=(l, mn, sf_k))
    return encoded_choices[choice_idx], decoded_choices[choice_idx]


def _make_scale_factor_cute(
    l: int,  # noqa: E741
    mn: int,
    sf_k: int,
    ref_scale_bytes: np.ndarray,
) -> np.ndarray:
    """Build the CUTE/TMA scale-factor storage used by the raw kernel."""
    if ref_scale_bytes.shape == (mn, sf_k, l):
        scale_bytes_lxk = np.transpose(ref_scale_bytes, (2, 0, 1))
    elif ref_scale_bytes.shape == (l, mn, sf_k):
        scale_bytes_lxk = ref_scale_bytes
    else:
        raise ValueError(
            "ref_scale_bytes must have shape (L, MN, SF_K) or (MN, SF_K, L)"
        )
    return cvt_sf_MKL_to_M32x4xrm_K4xrk_L(scale_bytes_lxk)


def _parse_mnkl(s: str) -> tuple[int, int, int, int]:
    """Parse an ``M,N,K,L`` CLI argument into a four-int tuple."""
    try:
        values = tuple(int(x.strip()) for x in s.split(","))
    except ValueError as exc:
        raise argparse.ArgumentTypeError(
            "Invalid format. Expected comma-separated integers."
        ) from exc
    if len(values) != 4:
        raise argparse.ArgumentTypeError("Expected exactly four MNKL values.")
    return values


def _validate_cluster_shape(cluster_m: int, cluster_n: int) -> None:
    if cluster_m not in (2, 4, 8):
        raise ValueError(f"cluster_m must be one of 2, 4, 8 (got {cluster_m})")
    if cluster_n not in (1, 2, 4, 8):
        raise ValueError(f"cluster_n must be one of 1, 2, 4, 8 (got {cluster_n})")
    if cluster_m * cluster_n > 16:
        raise ValueError(
            f"cluster_m * cluster_n must be <= 16 (got {cluster_m * cluster_n})"
        )


def _resolve_fallback_cluster_shape(
    cluster_m: int,
    cluster_n: int,
    fallback_cluster_m: int | None,
    fallback_cluster_n: int | None,
) -> tuple[int, int]:
    """Return the effective fallback shape for a mixed-cluster launch."""
    if fallback_cluster_m is None:
        fallback_cluster_m = DEFAULT_FALLBACK_CLUSTER_M
    if fallback_cluster_n is None:
        fallback_cluster_n = DEFAULT_FALLBACK_CLUSTER_N
    _validate_cluster_shape(cluster_m, cluster_n)
    _validate_cluster_shape(fallback_cluster_m, fallback_cluster_n)
    if cluster_m % fallback_cluster_m != 0 or cluster_n % fallback_cluster_n != 0:
        raise ValueError(
            "preferred cluster shape must be an integer multiple of fallback "
            f"shape (preferred=({cluster_m},{cluster_n}), "
            f"fallback=({fallback_cluster_m},{fallback_cluster_n}))"
        )
    return fallback_cluster_m, fallback_cluster_n


def _validate_mixed_mnkl(
    mnkl: tuple[int, int, int, int],
    cluster_m: int,
    cluster_n: int,
    fallback_cluster_m: int,
    fallback_cluster_n: int,
) -> None:
    """Validate problem shape for a mixed-cluster launch.

    Input operands are loaded through TensorMaps, so edge tiles can rely on TMA
    boundary handling.  The remaining host-side shape contract is the packed FP4
    and scale-factor storage atom shape plus the output vector-store alignment.
    """
    _validate_mnkl(mnkl, cluster_m, cluster_n)
    _validate_mnkl(mnkl, fallback_cluster_m, fallback_cluster_n)


def _validate_mnkl(
    mnkl: tuple[int, int, int, int],
    cluster_m: int = DEFAULT_CLUSTER_M,
    cluster_n: int = DEFAULT_CLUSTER_N,
) -> None:
    """Validate the problem shape contract required by this raw CTA_2 kernel."""
    _validate_cluster_shape(cluster_m, cluster_n)
    if len(mnkl) != 4:
        raise ValueError("MNKL must contain exactly four values")
    m, n, k, l = mnkl  # noqa: E741
    if min(m, n, k, l) <= 0:
        raise ValueError("MNKL values must be positive")
    if m % SF_ATOM_MN != 0:
        raise ValueError(f"M={m} must be divisible by {SF_ATOM_MN}")
    if n % SF_ATOM_MN != 0:
        raise ValueError(f"N={n} must be divisible by {SF_ATOM_MN}")
    if k % SF_ATOM_K != 0:
        raise ValueError(f"K={k} must be divisible by {SF_ATOM_K}")


def ceil_div(a: int, b: int) -> int:
    return (a + b - 1) // b


def _make_inputs(
    mnkl: tuple[int, int, int, int],
    *,
    zero_init: bool = False,
    cluster_m: int = DEFAULT_CLUSTER_M,
    cluster_n: int = DEFAULT_CLUSTER_N,
) -> tuple[
    torch.Tensor,
    torch.Tensor,
    torch.Tensor,
    torch.Tensor,
    torch.Tensor,
    np.ndarray | None,
]:
    """Create packed FP4 inputs, tutorial-order scale factors, and CPU gold."""
    if not torch.cuda.is_available():
        raise RuntimeError("GPU is required to run this example!")
    _validate_mnkl(mnkl, cluster_m, cluster_n)
    m, n, k, l = mnkl  # noqa: E741
    sf_k = k // SF_VEC
    sf_rest_k = sf_k // SF_K_BLOCK

    if zero_init:
        a = torch.zeros((k // 2) * m * l, dtype=torch.uint8, device="cuda").view(
            torch.float4_e2m1fn_x2
        )
        b = torch.zeros((k // 2) * n * l, dtype=torch.uint8, device="cuda").view(
            torch.float4_e2m1fn_x2
        )
        sfa = torch.zeros(
            SF_ATOM_U16 * sf_rest_k * (m // SF_ATOM_MN) * l,
            dtype=torch.uint16,
            device="cuda",
        )
        sfb = torch.zeros(
            SF_ATOM_U16 * sf_rest_k * (n // SF_ATOM_MN) * l,
            dtype=torch.uint16,
            device="cuda",
        )
        c = torch.zeros(n * m * l, dtype=torch.bfloat16, device="cuda")
        return a, b, c, sfa, sfb, None

    rng = np.random.default_rng(20260701)
    sfa_bytes, sfa_decoded = _make_scale_factor_ref(l, m, sf_k, rng)
    sfb_bytes, sfb_decoded = _make_scale_factor_ref(l, n, sf_k, rng)

    a_raw = rng.standard_normal((l, m, k)).astype(np.float32) * 0.5
    b_raw = rng.standard_normal((l, n, k)).astype(np.float32) * 0.5

    a_scale_full = np.repeat(sfa_decoded, SF_VEC, axis=2)[:, :, :k]
    b_scale_full = np.repeat(sfb_decoded, SF_VEC, axis=2)[:, :, :k]

    a_codes = _quantize_fp4(a_raw / a_scale_full)
    b_codes = _quantize_fp4(b_raw / b_scale_full)
    a_deq = _decode_fp4(a_codes) * a_scale_full
    b_deq = _decode_fp4(b_codes) * b_scale_full

    gold = np.empty((l, m, n), dtype=np.float32)
    for batch in range(l):
        gold[batch] = a_deq[batch] @ b_deq[batch].T

    a = (
        torch.from_numpy(np.ascontiguousarray(_pack_k_major(a_codes).ravel(order="F")))
        .to(device="cuda")
        .view(torch.float4_e2m1fn_x2)
    )
    b = (
        torch.from_numpy(np.ascontiguousarray(_pack_k_major(b_codes).ravel(order="F")))
        .to(device="cuda")
        .view(torch.float4_e2m1fn_x2)
    )
    sfa = torch.from_numpy(
        np.ascontiguousarray(
            _make_scale_factor_cute(l, m, sf_k, sfa_bytes).ravel(order="F")
        )
    ).to(device="cuda")
    sfb = torch.from_numpy(
        np.ascontiguousarray(
            _make_scale_factor_cute(l, n, sf_k, sfb_bytes).ravel(order="F")
        )
    ).to(device="cuda")
    c = torch.zeros(n * m * l, dtype=torch.bfloat16, device="cuda")
    return a, b, c, sfa, sfb, gold


# ---------------------------------------------------------------------------
# Host launcher and compile
# ---------------------------------------------------------------------------


@cute.jit
def gemm(
    a_ptr: cute.Pointer,
    b_ptr: cute.Pointer,
    sfa_ptr: cute.Pointer,
    sfb_ptr: cute.Pointer,
    c_ptr: cute.Pointer,
    problem_size: tuple,
    max_active_clusters: cutlass.Constexpr[int],
    fallback_max_active_clusters: cutlass.Constexpr[int],
    cluster_m: cutlass.Constexpr[int],
    cluster_n: cutlass.Constexpr[int],
    fallback_cluster_m: cutlass.Constexpr[int],
    fallback_cluster_n: cutlass.Constexpr[int],
    stream,
) -> None:
    m, n, _k, batch = problem_size

    a_layout = cute.make_layout(
        (_k, m, batch),
        stride=(1, _k, _k * m),
    )
    b_layout = cute.make_layout(
        (_k, n, batch),
        stride=(1, _k, _k * n),
    )
    sfa_layout = cute.make_layout(
        (
            SF_ATOM_U16,
            cute.ceil_div(_k, SF_ATOM_K),
            cute.ceil_div(m, SF_ATOM_MN),
            batch,
        ),
        stride=(
            1,
            SF_ATOM_U16,
            SF_ATOM_U16 * cute.ceil_div(_k, SF_ATOM_K),
            SF_ATOM_U16 * cute.ceil_div(_k, SF_ATOM_K) * cute.ceil_div(m, SF_ATOM_MN),
        ),
    )
    sfb_layout = cute.make_layout(
        (
            SF_ATOM_U16,
            cute.ceil_div(_k, SF_ATOM_K),
            cute.ceil_div(n, SF_ATOM_MN),
            batch,
        ),
        stride=(
            1,
            SF_ATOM_U16,
            SF_ATOM_U16 * cute.ceil_div(_k, SF_ATOM_K),
            SF_ATOM_U16 * cute.ceil_div(_k, SF_ATOM_K) * cute.ceil_div(n, SF_ATOM_MN),
        ),
    )
    c_layout = cute.make_layout(
        (n, m, batch),
        stride=(1, n, n * m),
    )
    fp4_a = cute.make_tensor(a_ptr, a_layout)
    fp4_b = cute.make_tensor(b_ptr, b_layout)
    sfa_tensor = cute.make_tensor(sfa_ptr, sfa_layout)
    sfb_tensor = cute.make_tensor(sfb_ptr, sfb_layout)
    c_tensor = cute.make_tensor(c_ptr, c_layout)

    tma_a_desc = cuda.create_tensor_map_tiled_from_view(
        fp4_a,
        box_dims=(TILE_K, TILE_M_PER_CTA // cluster_n, 1),
        stride_order=(0, 1, 2),
        swizzle=cuda.TensorMapSwizzle.s128b,
        l2_promotion=cuda.TensorMapL2Promotion.l2_256b,
        tma_format=cuda.TensorMapDataFormat.B4X16,
    )
    tma_b_desc = cuda.create_tensor_map_tiled_from_view(
        fp4_b,
        box_dims=(TILE_K, TILE_N_PER_CTA // (cluster_m // CTA_PAIR_SIZE), 1),
        stride_order=(0, 1, 2),
        swizzle=cuda.TensorMapSwizzle.s128b,
        l2_promotion=cuda.TensorMapL2Promotion.l2_256b,
        tma_format=cuda.TensorMapDataFormat.B4X16,
    )
    tma_sfa_desc = cuda.create_tensor_map_tiled_from_view(
        sfa_tensor,
        box_dims=(SF_ATOM_U16, SF_KBLOCKS_PER_TILE, 1, 1),
        stride_order=(0, 1, 2, 3),
        swizzle=cuda.TensorMapSwizzle.none,
        l2_promotion=cuda.TensorMapL2Promotion.l2_256b,
    )
    tma_sfb_desc = cuda.create_tensor_map_tiled_from_view(
        sfb_tensor,
        box_dims=(SF_ATOM_U16, SF_KBLOCKS_PER_TILE, TILE_N // SF_ATOM_MN, 1),
        stride_order=(0, 1, 2, 3),
        swizzle=cuda.TensorMapSwizzle.none,
        l2_promotion=cuda.TensorMapL2Promotion.l2_256b,
    )
    fallback_tma_a_desc = cuda.create_tensor_map_tiled_from_view(
        fp4_a,
        box_dims=(TILE_K, TILE_M_PER_CTA // fallback_cluster_n, 1),
        stride_order=(0, 1, 2),
        swizzle=cuda.TensorMapSwizzle.s128b,
        l2_promotion=cuda.TensorMapL2Promotion.l2_256b,
        tma_format=cuda.TensorMapDataFormat.B4X16,
    )
    fallback_tma_b_desc = cuda.create_tensor_map_tiled_from_view(
        fp4_b,
        box_dims=(
            TILE_K,
            TILE_N_PER_CTA // (fallback_cluster_m // CTA_PAIR_SIZE),
            1,
        ),
        stride_order=(0, 1, 2),
        swizzle=cuda.TensorMapSwizzle.s128b,
        l2_promotion=cuda.TensorMapL2Promotion.l2_256b,
        tma_format=cuda.TensorMapDataFormat.B4X16,
    )
    fallback_tma_sfa_desc = cuda.create_tensor_map_tiled_from_view(
        sfa_tensor,
        box_dims=(SF_ATOM_U16, SF_KBLOCKS_PER_TILE, 1, 1),
        stride_order=(0, 1, 2, 3),
        swizzle=cuda.TensorMapSwizzle.none,
        l2_promotion=cuda.TensorMapL2Promotion.l2_256b,
    )
    fallback_tma_sfb_desc = cuda.create_tensor_map_tiled_from_view(
        sfb_tensor,
        box_dims=(SF_ATOM_U16, SF_KBLOCKS_PER_TILE, TILE_N // SF_ATOM_MN, 1),
        stride_order=(0, 1, 2, 3),
        swizzle=cuda.TensorMapSwizzle.none,
        l2_promotion=cuda.TensorMapL2Promotion.l2_256b,
    )
    num_ctas_mnl = (
        cute.ceil_div(m, TILE_M_PER_CTA_STACK),
        cute.ceil_div(n, TILE_N),
        batch,
    )
    cluster_shape_mnl = (cluster_m, cluster_n, 1)
    tile_sched_params = PersistentTileSchedulerParams(
        num_ctas_mnl,
        cluster_shape_mnl,
    )
    fallback_cluster_shape_mnl = (fallback_cluster_m, fallback_cluster_n, 1)
    fallback_grid_tile_sched_params = PersistentTileSchedulerParams(
        num_ctas_mnl,
        fallback_cluster_shape_mnl,
    )
    # Static persistent mixed-cluster has two separate contracts:
    # 1. Tile coordinates are decoded in the preferred-grid coordinate system,
    #    so fallback clusters reuse the preferred scheduler params in-kernel.
    # 2. Resident launch capacity is sized from fallback occupancy. Convert
    #    fallback resident CTA capacity to preferred-cluster launch slots with
    #    floor division so the launch does not create a tail wave; keep at least
    #    one slot for tiny valid problems.
    fallback_tile_sched_params = tile_sched_params
    grid = StaticPersistentTileScheduler.get_grid_shape(
        tile_sched_params, max_active_clusters
    )
    if cutlass.const_expr(
        cluster_m != fallback_cluster_m or cluster_n != fallback_cluster_n
    ):
        fallback_grid = StaticPersistentTileScheduler.get_grid_shape(
            fallback_grid_tile_sched_params, fallback_max_active_clusters
        )
        max_fallback_ctas = fallback_grid[0] * fallback_grid[1] * fallback_grid[2]
        preferred_cluster_ctas = cluster_m * cluster_n
        grid = (
            grid[0],
            grid[1],
            cutlass.max(
                max_fallback_ctas // preferred_cluster_ctas,
                cutlass.Int32(1),
            ),
        )
    kernel(
        tma_a_desc,
        tma_b_desc,
        tma_sfa_desc,
        tma_sfb_desc,
        fallback_tma_a_desc,
        fallback_tma_b_desc,
        fallback_tma_sfa_desc,
        fallback_tma_sfb_desc,
        c_tensor,
        problem_size,
        tile_sched_params,
        fallback_tile_sched_params,
        cluster_m,
        cluster_n,
        fallback_cluster_m,
        fallback_cluster_n,
    ).launch(
        grid=grid,
        block=(THREADS_PER_CTA, 1, 1),
        cluster=(cluster_m, cluster_n, 1),
        fallback_cluster=(fallback_cluster_m, fallback_cluster_n, 1),
        min_blocks_per_mp=1,
        stream=stream,
        smem_merge_branch_allocs=True,
    )


@cute.jit
def scaled_mm(
    a: cute.Tensor,
    b: cute.Tensor,
    sfa: cute.Tensor,
    sfb: cute.Tensor,
    c: cute.Tensor,
    problem_size: tuple,
    max_active_clusters: cutlass.Constexpr[int],
    fallback_max_active_clusters: cutlass.Constexpr[int],
    cluster_m: cutlass.Constexpr[int],
    cluster_n: cutlass.Constexpr[int],
    fallback_cluster_m: cutlass.Constexpr[int],
    fallback_cluster_n: cutlass.Constexpr[int],
    stream,
) -> None:
    """Pull pointers from input cute.Tensors and call the raw-op GEMM body."""
    gemm(
        cute.recast_ptr(a.iterator, dtype=AB_DTYPE),
        cute.recast_ptr(b.iterator, dtype=AB_DTYPE),
        sfa.iterator,
        sfb.iterator,
        c.iterator,
        problem_size,
        max_active_clusters,
        fallback_max_active_clusters,
        cluster_m,
        cluster_n,
        fallback_cluster_m,
        fallback_cluster_n,
        stream,
    )


@lru_cache(maxsize=None)
def compile(
    cluster_m: int = DEFAULT_CLUSTER_M,
    cluster_n: int = DEFAULT_CLUSTER_N,
    fallback_cluster_m: int | None = None,
    fallback_cluster_n: int | None = None,
) -> Callable:  # noqa: A001
    """AOT-compile ``scaled_mm`` for the raw Rubin NVFP4 GEMM launcher."""
    torch.empty(1, device="cuda")  # ensure CUDA primary context exists
    fallback_cluster_m, fallback_cluster_n = _resolve_fallback_cluster_shape(
        cluster_m, cluster_n, fallback_cluster_m, fallback_cluster_n
    )
    max_active_clusters = utils.HardwareInfo().get_max_active_clusters(
        cluster_m * cluster_n
    )
    fallback_max_active_clusters = utils.HardwareInfo().get_max_active_clusters(
        fallback_cluster_m * fallback_cluster_n
    )
    sym_l = cute.sym_int64()
    sym_m = cute.sym_int64(divisibility=SF_ATOM_MN)
    sym_n = cute.sym_int64(divisibility=SF_ATOM_MN)
    sym_k = cute.sym_int64(divisibility=SF_ATOM_K)
    sym_a_elems = cute.sym_int64(divisibility=16)
    sym_b_elems = cute.sym_int64(divisibility=16)
    sym_sfa_elems = cute.sym_int64(divisibility=SF_ATOM_U16)
    sym_sfb_elems = cute.sym_int64(divisibility=SF_ATOM_U16)
    sym_c_elems = cute.sym_int64(divisibility=16)
    fake_a = make_fake_compact_tensor(
        cutlass.Float4E2M1FNx2,
        (sym_a_elems,),
        assumed_align=16,
    )
    fake_b = make_fake_compact_tensor(
        cutlass.Float4E2M1FNx2,
        (sym_b_elems,),
        assumed_align=16,
    )
    fake_sfa = make_fake_compact_tensor(
        cutlass.Uint16,
        (sym_sfa_elems,),
        assumed_align=32,
    )
    fake_sfb = make_fake_compact_tensor(
        cutlass.Uint16,
        (sym_sfb_elems,),
        assumed_align=32,
    )
    fake_c = make_fake_compact_tensor(
        C_DTYPE,
        (sym_c_elems,),
        assumed_align=32,
    )
    fake_stream = make_fake_stream()
    return cute.compile(
        scaled_mm,
        fake_a,
        fake_b,
        fake_sfa,
        fake_sfb,
        fake_c,
        (sym_m, sym_n, sym_k, sym_l),
        max_active_clusters,
        fallback_max_active_clusters,
        cluster_m,
        cluster_n,
        fallback_cluster_m,
        fallback_cluster_n,
        fake_stream,
        options="--enable-tvm-ffi",
    )


# ---------------------------------------------------------------------------
# Run and validation
# ---------------------------------------------------------------------------


def _print_run_config(
    mnkl: tuple[int, int, int, int],
    *,
    zero_init: bool,
    cluster_m: int,
    cluster_n: int,
    fallback_cluster_m: int,
    fallback_cluster_n: int,
) -> None:
    del mnkl
    max_active_clusters = utils.HardwareInfo().get_max_active_clusters(
        cluster_m * cluster_n
    )
    fallback_max_active_clusters = utils.HardwareInfo().get_max_active_clusters(
        fallback_cluster_m * fallback_cluster_n
    )
    print(
        f"config: tile=({TILE_M},{TILE_N},{TILE_K}) "
        f"mma_m={COLLECTIVE_M} m_stack={M_STACK} "
        f"stages={NUM_AB_STAGE} cluster=({cluster_m},{cluster_n},1) "
        f"fallback_cluster=({fallback_cluster_m},{fallback_cluster_n},1) "
        f"max_active_clusters={max_active_clusters} "
        f"fallback_max_active_clusters={fallback_max_active_clusters} "
        "tma_l2_promotion=256B "
        f"tensor_init={'zero' if zero_init else 'random'}",
        flush=True,
    )
    print(
        "smem_accounting "
        f"budget={SM107_SMEM_BUDGET_BYTES} "
        f"headroom={SM107_SMEM_BUDGET_BYTES - SMEM_MAJOR_BYTES} "
        f"major={SMEM_MAJOR_BYTES} "
        f"c_stage={C_STAGE_BYTES} "
        f"epi_subtile_n={EPI_SUBTILE_N} "
        f"epi_c_stages={EPI_C_STAGES} "
        f"epi_c_stage={EPI_C_STAGE_BYTES} "
        f"ab_stage={AB_SMEM_STAGE_BYTES}",
        flush=True,
    )


def run(
    compiled_fn: Callable,
    mnkl: tuple[int, int, int, int] = _DEFAULT_MNKL,
    *,
    zero_init: bool = False,
    cluster_m: int = DEFAULT_CLUSTER_M,
    cluster_n: int = DEFAULT_CLUSTER_N,
    fallback_cluster_m: int | None = None,
    fallback_cluster_n: int | None = None,
) -> tuple[torch.Tensor, np.ndarray | None]:
    """Allocate inputs, invoke ``compiled_fn``, and return C plus CPU gold."""
    fallback_cluster_m, fallback_cluster_n = _resolve_fallback_cluster_shape(
        cluster_m, cluster_n, fallback_cluster_m, fallback_cluster_n
    )
    _validate_mixed_mnkl(
        mnkl, cluster_m, cluster_n, fallback_cluster_m, fallback_cluster_n
    )
    _print_run_config(
        mnkl,
        zero_init=zero_init,
        cluster_m=cluster_m,
        cluster_n=cluster_n,
        fallback_cluster_m=fallback_cluster_m,
        fallback_cluster_n=fallback_cluster_n,
    )
    a, b, c, sfa, sfb, gold = _make_inputs(
        mnkl,
        zero_init=zero_init,
        cluster_m=cluster_m,
        cluster_n=cluster_n,
    )
    stream = cutlass_torch.default_stream()
    start = time.perf_counter()
    compiled_fn(
        a,
        b,
        sfa,
        sfb,
        c,
        mnkl,
        stream,
    )
    torch.cuda.synchronize()
    elapsed_ms = (time.perf_counter() - start) * 1000.0
    print(f"time_ms={elapsed_ms:.3f}", flush=True)
    return c, gold


def _dense_gemm_flops(mnkl: tuple[int, int, int, int]) -> int:
    m, n, k, l = mnkl  # noqa: E741
    return 2 * m * n * k * l


def benchmark(
    compiled_fn: Callable,
    mnkl: tuple[int, int, int, int] = _DEFAULT_MNKL,
    *,
    warmup: int = 20,
    iterations: int = 100,
    cluster_m: int = DEFAULT_CLUSTER_M,
    cluster_n: int = DEFAULT_CLUSTER_N,
    fallback_cluster_m: int | None = None,
    fallback_cluster_n: int | None = None,
) -> tuple[float, float, float]:
    """Return CUDA-event time, PFLOP/s, and percent of peak NVFP4 throughput."""
    if warmup < 0:
        raise ValueError(f"warmup must be non-negative (got {warmup})")
    if iterations <= 0:
        raise ValueError(f"iterations must be positive (got {iterations})")

    fallback_cluster_m, fallback_cluster_n = _resolve_fallback_cluster_shape(
        cluster_m, cluster_n, fallback_cluster_m, fallback_cluster_n
    )
    _validate_mixed_mnkl(
        mnkl, cluster_m, cluster_n, fallback_cluster_m, fallback_cluster_n
    )
    _print_run_config(
        mnkl,
        zero_init=True,
        cluster_m=cluster_m,
        cluster_n=cluster_n,
        fallback_cluster_m=fallback_cluster_m,
        fallback_cluster_n=fallback_cluster_n,
    )
    a, b, c, sfa, sfb, _ = _make_inputs(
        mnkl,
        zero_init=True,
        cluster_m=cluster_m,
        cluster_n=cluster_n,
    )
    stream = cutlass_torch.default_stream()

    for _ in range(warmup):
        compiled_fn(a, b, sfa, sfb, c, mnkl, stream)
    torch.cuda.synchronize()

    start = torch.cuda.Event(enable_timing=True)
    end = torch.cuda.Event(enable_timing=True)
    start.record()
    for _ in range(iterations):
        compiled_fn(a, b, sfa, sfb, c, mnkl, stream)
    end.record()
    end.synchronize()

    gpu_us = start.elapsed_time(end) * 1000.0 / iterations
    pflops = _dense_gemm_flops(mnkl) / (gpu_us * 1.0e9)
    efficiency = 100.0 * pflops / NVFP4_PEAK_PFLOPS
    return gpu_us, pflops, efficiency


def verify(
    mnkl: tuple[int, int, int, int] = _DEFAULT_MNKL,
    tolerance: float = _DEFAULT_TOLERANCE,
    *,
    cluster_m: int = DEFAULT_CLUSTER_M,
    cluster_n: int = DEFAULT_CLUSTER_N,
    fallback_cluster_m: int | None = None,
    fallback_cluster_n: int | None = None,
) -> None:
    """Compile, run, and require BF16 bit-exact output against GPU reference."""
    del tolerance
    fallback_cluster_m, fallback_cluster_n = _resolve_fallback_cluster_shape(
        cluster_m, cluster_n, fallback_cluster_m, fallback_cluster_n
    )
    _validate_mixed_mnkl(
        mnkl, cluster_m, cluster_n, fallback_cluster_m, fallback_cluster_n
    )
    compiled_fn = compile(
        cluster_m,
        cluster_n,
        fallback_cluster_m,
        fallback_cluster_n,
    )
    print(
        "Compile kernel "
        f"(mnkl={mnkl}, cluster=({cluster_m},{cluster_n},1), "
        f"fallback=({fallback_cluster_m},{fallback_cluster_n},1)) OK",
        flush=True,
    )

    _print_run_config(
        mnkl,
        zero_init=False,
        cluster_m=cluster_m,
        cluster_n=cluster_n,
        fallback_cluster_m=fallback_cluster_m,
        fallback_cluster_n=fallback_cluster_n,
    )
    start = time.perf_counter()
    m, n, k, l = mnkl  # noqa: E741
    sf_k = k // SF_VEC
    seed = _RANDOM_SEED + m * 3 + n * 5 + k * 7 + l * 11
    rng = np.random.default_rng(seed)
    torch_rng = torch.Generator(device="cuda")
    torch_rng.manual_seed(seed)
    sfa_bytes, sfa_decoded = _make_scale_factor_ref(l, m, sf_k, rng)
    sfb_bytes, sfb_decoded = _make_scale_factor_ref(l, n, sf_k, rng)
    sfa = torch.from_numpy(
        np.ascontiguousarray(
            _make_scale_factor_cute(l, m, sf_k, sfa_bytes).ravel(order="F")
        )
    ).to(device="cuda")
    sfb = torch.from_numpy(
        np.ascontiguousarray(
            _make_scale_factor_cute(l, n, sf_k, sfb_bytes).ravel(order="F")
        )
    ).to(device="cuda")
    a_bytes = torch.randint(
        0,
        256,
        ((k // 2) * m * l,),
        dtype=torch.uint8,
        device="cuda",
        generator=torch_rng,
    )
    b_bytes = torch.randint(
        0,
        256,
        ((k // 2) * n * l,),
        dtype=torch.uint8,
        device="cuda",
        generator=torch_rng,
    )
    a = a_bytes.view(torch.float4_e2m1fn_x2)
    b = b_bytes.view(torch.float4_e2m1fn_x2)
    c = torch.zeros(n * m * l, dtype=torch.bfloat16, device="cuda")
    torch.cuda.synchronize()
    print(f"inputs_ready_s={time.perf_counter() - start:.3f}", flush=True)

    stream = cutlass_torch.default_stream()
    start = time.perf_counter()
    compiled_fn(
        a,
        b,
        sfa,
        sfb,
        c,
        mnkl,
        stream,
    )
    torch.cuda.synchronize()
    print(f"kernel_ms={(time.perf_counter() - start) * 1000.0:.3f}", flush=True)
    print(
        "Run kernel "
        f"(mnkl={mnkl}, cluster=({cluster_m},{cluster_n},1), "
        f"fallback=({fallback_cluster_m},{fallback_cluster_n},1)) OK",
        flush=True,
    )

    start = time.perf_counter()
    old_allow_tf32 = torch.backends.cuda.matmul.allow_tf32
    torch.backends.cuda.matmul.allow_tf32 = False
    try:
        lut = torch.tensor(SIGNED_FP4_LUT, dtype=torch.float32, device="cuda")
        a_packed = a_bytes.view(l, m, k // 2)
        b_packed = b_bytes.view(l, n, k // 2)
        a_codes = torch.empty((l, m, k), dtype=torch.int64, device="cuda")
        b_codes = torch.empty((l, n, k), dtype=torch.int64, device="cuda")
        a_codes[:, :, 0::2] = (a_packed & 0x0F).to(torch.int64)
        a_codes[:, :, 1::2] = ((a_packed >> 4) & 0x0F).to(torch.int64)
        b_codes[:, :, 0::2] = (b_packed & 0x0F).to(torch.int64)
        b_codes[:, :, 1::2] = ((b_packed >> 4) & 0x0F).to(torch.int64)

        a_deq = lut[a_codes].view(l, m, sf_k, SF_VEC)
        b_deq = lut[b_codes].view(l, n, sf_k, SF_VEC)
        del a_codes, b_codes
        a_deq *= torch.from_numpy(np.ascontiguousarray(sfa_decoded)).to(device="cuda")[
            :, :, :, None
        ]
        b_deq *= torch.from_numpy(np.ascontiguousarray(sfb_decoded)).to(device="cuda")[
            :, :, :, None
        ]
        a_deq = a_deq.reshape(l, m, k)
        b_deq = b_deq.reshape(l, n, k)
        ref_bits = (
            torch.bmm(a_deq, b_deq.transpose(1, 2))
            .to(torch.bfloat16)
            .view(torch.uint16)
        )
    finally:
        torch.backends.cuda.matmul.allow_tf32 = old_allow_tf32

    c_bits = c.view(torch.uint16).view(l, m, n)
    mismatch = c_bits != ref_bits
    bf16_bit_mismatches = int(torch.count_nonzero(mismatch).item())
    torch.cuda.synchronize()
    print(f"gpu_reference_s={time.perf_counter() - start:.3f}", flush=True)
    print(
        f"gpu_reference_bf16_mismatches={bf16_bit_mismatches} / "
        f"{mnkl[0] * mnkl[1] * mnkl[3]}",
        flush=True,
    )
    if bf16_bit_mismatches:
        idx = torch.nonzero(mismatch, as_tuple=False)[0]
        batch = int(idx[0].item())
        row = int(idx[1].item())
        col = int(idx[2].item())
        print(
            f"BF16 mismatch at l,m,n=({batch},{row},{col}): "
            f"out_bits=0x{int(c_bits[batch, row, col].item()):04x} "
            f"ref_bits=0x{int(ref_bits[batch, row, col].item()):04x}",
            flush=True,
        )
        raise AssertionError(f"bf16_bit_mismatches={bf16_bit_mismatches}")
    print(
        f"verify (mnkl={mnkl}, cluster=({cluster_m},{cluster_n},1), "
        f"fallback=({fallback_cluster_m},{fallback_cluster_n},1)): PASS",
        flush=True,
    )


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--mnkl",
        type=_parse_mnkl,
        default=_DEFAULT_MNKL,
        help="mnkl dimensions (comma-separated)",
    )
    parser.add_argument(
        "--tolerance",
        type=float,
        default=_DEFAULT_TOLERANCE,
        help="Accepted for scaffold compatibility; validation is BF16 bit-exact.",
    )
    parser.add_argument(
        "--benchmark",
        action="store_true",
        help="Run CUDA-event timing after compilation instead of correctness verify.",
    )
    parser.add_argument(
        "--warmup",
        type=int,
        default=20,
        help="Benchmark warmup iterations.",
    )
    parser.add_argument(
        "--iterations",
        type=int,
        default=100,
        help="Benchmark timed iterations.",
    )
    parser.add_argument(
        "--cluster-m",
        type=int,
        default=DEFAULT_CLUSTER_M,
        help="CTA cluster M dimension; supported values: 2, 4, 8.",
    )
    parser.add_argument(
        "--cluster-n",
        type=int,
        default=DEFAULT_CLUSTER_N,
        help="CTA cluster N dimension; supported values: 1, 2, 4, 8.",
    )
    parser.add_argument(
        "--fallback-cluster-m",
        type=int,
        default=DEFAULT_FALLBACK_CLUSTER_M,
        help="Fallback CTA cluster M dimension for mixed-cluster launch; default: 2.",
    )
    parser.add_argument(
        "--fallback-cluster-n",
        type=int,
        default=DEFAULT_FALLBACK_CLUSTER_N,
        help="Fallback CTA cluster N dimension for mixed-cluster launch; default: 1.",
    )
    args = parser.parse_args()
    fallback_cluster_m, fallback_cluster_n = _resolve_fallback_cluster_shape(
        args.cluster_m,
        args.cluster_n,
        args.fallback_cluster_m,
        args.fallback_cluster_n,
    )

    if args.benchmark:
        compiled_fn = compile(
            args.cluster_m,
            args.cluster_n,
            fallback_cluster_m,
            fallback_cluster_n,
        )
        gpu_us, pflops, efficiency = benchmark(
            compiled_fn,
            args.mnkl,
            warmup=args.warmup,
            iterations=args.iterations,
            cluster_m=args.cluster_m,
            cluster_n=args.cluster_n,
            fallback_cluster_m=fallback_cluster_m,
            fallback_cluster_n=fallback_cluster_n,
        )
        print(
            f"benchmark (mnkl={args.mnkl}, "
            f"cluster=({args.cluster_m},{args.cluster_n},1), "
            f"fallback=({fallback_cluster_m},{fallback_cluster_n},1), "
            f"warmup={args.warmup}, iterations={args.iterations}): "
            f"gpu_us={gpu_us:.3f}, pflops={pflops:.3f}, "
            f"efficiency={efficiency:.2f}",
            flush=True,
        )
    else:
        verify(
            args.mnkl,
            args.tolerance,
            cluster_m=args.cluster_m,
            cluster_n=args.cluster_n,
            fallback_cluster_m=fallback_cluster_m,
            fallback_cluster_n=fallback_cluster_n,
        )
    print("PASS", flush=True)


if __name__ == "__main__":
    main()
