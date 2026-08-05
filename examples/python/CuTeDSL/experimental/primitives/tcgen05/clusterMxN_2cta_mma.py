# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
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

"""Parametric cluster GEMM — selectable cta_group::1 vs cta_group::2 MMA.

A single-source kernel covering both Blackwell ``tcgen05.mma`` modes via a
compile-time ``USE_2CTA_GROUP`` flag.  Mode-specific paths (``group=``
argument, leader-only vs every-CTA sync, mask convention, tile-axis
split) are gated by ``cutlass.const_expr`` and compile-time-eliminated,
so each compile yields a flat single-mode kernel — no runtime overhead.

Compile-time tile / shape parameters
====================================

All passed as Constexpr Python tuples and unpacked at the top of
``kernel`` and ``host``.

* ``CLUSTER_SHAPE = (CLUSTER_SX, CLUSTER_SY)`` — CTA grid per cluster.
  CTA_2 requires ``CLUSTER_SX % 2 == 0`` (PTX 9.7.16.5.1 — 2-SM groups
  are LSB-defined on ``%cluster_ctarank``).  Total ``CLUSTER_SX *
  CLUSTER_SY ≤ 16`` (HW cluster cap).

* ``CLUSTER_TILE = (M, N, K)`` — output tile (M × N) per cluster, plus
  the per-step K-loop tile.  Conventional GEMM ``MNK`` ordering.  The
  user-facing ``verify()`` / ``run()`` API splits this into a 2-tuple
  ``CLUSTER_TILE=(M, N)`` + a separate ``K_TILE`` kwarg for ergonomics;
  ``compile`` recombines them before calling the kernel.

* ``GROUP_TILE = (M, N)`` — per-2-SM-group tile (CTA_2 only).
  Implicitly defines the (GROUPS_M, GROUPS_N) split via
  ``GROUPS_M = CLUSTER_TILE[0] // GROUP_TILE[0]``,
  ``GROUPS_N = CLUSTER_TILE[1] // GROUP_TILE[1]``, with
  ``GROUPS_M * GROUPS_N == CLUSTER_SX * CLUSTER_SY / 2`` (= n_groups).
  Optional: omit for the **M-stack default** (GROUPS_M=n_groups, GROUPS_N=1).

Public API::

    verify(mnk, *,
           USE_2CTA_GROUP=True,
           CLUSTER_SHAPE=(2, 2),       # default mode-specific
           CLUSTER_TILE=(M, N),        # default mode-specific
           K_TILE=64,
           GROUP_TILE=(M, N),          # CTA_2 only; default M-stack
           tolerance=0.1)

Variant catalog (K_TILE=64, fp16; SMEM is per-CTA)::

    Variant   CLUSTER_SHAPE  CLUSTER_TILE   GROUP_TILE     SMEM   layout
    V1        (2, 1)         (256, 128)     (default)      24 KB  one group
    V2        (2, 2)         (512, 128)     (default)      24 KB  M-stack
    V3        (2, 2)         (256, 256)     (256, 128)     24 KB  N-stack
    V4        (2, 4)         (512, 256)     (256, 128)     24 KB  2x2 mixed
    V5        (2, 2)         (256, 128)     (256,  64)     20 KB  N-shrink x2
    V6        (2, 4)         (256, 256)     (256,  64)     20 KB  N-shrink x4
    C1        (1, 1)         (128, 128)     —              24 KB  CTA_1 single
    C2        (1, 2)         (128, 256)     —              24 KB  CTA_1 cluster
    C3        (2, 2)         (256, 256)     —              24 KB  CTA_1 cluster

(``default`` = M-stack: ``GROUP_TILE = (CLUSTER_TILE[0] // n_groups,
CLUSTER_TILE[1])``.)

Cluster rank decomposition
==========================

CTA_2 (2-SM group structure LSB-defined on ``%cluster_ctarank``)::

    rank       = block_idx_in_cluster()       # ∈ [0, CLUSTER_SX*CLUSTER_SY)
    group_lane = rank & 1                      # 0 = group leader, 1 = peer
    group_idx  = rank >> 1                     # ∈ [0, n_groups)
    gm_idx, gn_idx = divmod(group_idx, GROUPS_N)

CTA_1::

    rank = block_idx_in_cluster()
    cluster_x, cluster_y = rank % CLUSTER_SX, rank // CLUSTER_SX

CTA_2 critical details
======================

1. **``tcgen05_commit.multicast_mask`` is over CLUSTER ranks**, not
   local to each CTA group.  For the group leader at ``cluster_rank == 2G``,
   ``mask = 3 << (2G)`` covers cluster ranks ``2G`` and ``2G+1``.
   Literal ``mask=3`` only signals ranks 0,1 → group 1+ deadlocks
   at the next ``try_wait_parity``.

2. **TMEM Layout A epilogue**: each CTA's TMEM holds the FULL
   ``GROUP_TILE_N`` cols (both group members see the same N range).
   Epilogue col offset uses ``n_group_off``, NOT ``n_off_cta``.
   CTA_1 mode collapses this distinction (each CTA owns its own
   ``CTA_TILE_N``).

3. **TMEM alloc**: full TMEM (512 cols) is the safe default for
   any CTA_2 N.  Applying the CTA_1 formula ``(N // 8) * 32`` to
   collective ``N`` over-allocates beyond 512 →
   ``cudaErrorIllegalInstruction``.

Deferred — cross-group multicast (CTA_2)
========================================

Cluster-wide B-broadcast across multiple 2-SM groups is NOT
implemented.  Both modes here do per-CTA TMA (each CTA fetches its
own slice).  The blocker is wrapper-level: ``group=CTA_2`` bit-24
mbar masking routes ``complete_tx`` to the **issuer's** group
leader only, so cross-group receivers' mbars never get arrives.
This example keeps per-CTA TMA for that reason.  A true broadcast
composition needs a local-mbarrier multicast protocol like
``../tma/tma_multicast.py`` plus explicit operand composition.

To run::

    python CuTeDSL/experimental/primitives/tcgen05/clusterMxN_2cta_mma.py
    python CuTeDSL/experimental/primitives/tcgen05/clusterMxN_2cta_mma.py \\
            --CLUSTER_SHAPE 2,2 --CLUSTER_TILE 512,128 --mnk 1024,1024,128
    python CuTeDSL/experimental/primitives/tcgen05/clusterMxN_2cta_mma.py \\
            --no_2cta_group --CLUSTER_SHAPE 2,2 --mnk 1024,1024,128

"""

from __future__ import annotations

import argparse
from functools import lru_cache
from typing import Callable, Tuple

import torch

import cutlass
import cutlass.experimental.cuda as cuda
import cutlass.cute as cute
import cutlass.torch as cutlass_torch
from cutlass.cute.runtime import make_fake_compact_tensor
from cutlass.experimental import primitives as prims

io_dtype = cutlass.Float16

# tcgen05.mma per-instruction K granule for fp16 = 16 elements.
MMA_K_GRANULE: cutlass.Constexpr[int] = 16

# Allowed (GROUPS_M, GROUPS_N) tuples for CTA_2 mode: GROUPS_M*GROUPS_N = n_groups, n_groups ∈
# {1,2,4,8} (cluster size = 2 * n_groups <= 16).
_ALLOWED_GROUPS_MN = {
    (1, 1),
    (1, 2),
    (2, 1),
    (1, 4),
    (2, 2),
    (4, 1),
    (1, 8),
    (2, 4),
    (4, 2),
    (8, 1),
}

_DEFAULT_K_TILE: int = 64
_DEFAULT_MNK: Tuple[int, int, int] = (512, 128, 128)

# Hard invariant tied to ``block=(128, 1, 1)`` and the 4-warp SHAPE_32X32B
# epilogue (``row = tidx + m_off_cta``, tidx ∈ [0, 128)).  Each CTA writes
# exactly 128 M-rows; ``M_PER_CTA`` must equal this.  Touching the launch
# block shape means revisiting :func:`_validate` and the epilogue.
_M_PER_CTA_REQUIRED: int = 128


# ---------------------------------------------------------------------------
# Kernels
# ---------------------------------------------------------------------------


@cute.kernel
def kernel(
    tma_a_desc: cutlass.GridConstant[cuda.TensorMap],
    tma_b_desc: cutlass.GridConstant[cuda.TensorMap],
    mC_mn: cute.Tensor,
    k: cutlass.Int32,
    USE_2CTA_GROUP: cutlass.Constexpr[int],
    CLUSTER_SHAPE: cutlass.Constexpr,  # (CLUSTER_SX, CLUSTER_SY)
    CLUSTER_TILE: cutlass.Constexpr,  # (M, N, K) tile per cluster
    GROUP_TILE: cutlass.Constexpr,  # (M, N) per 2-SM group; CTA_2 only
) -> None:
    """Single-source CTA_1 / CTA_2 cluster GEMM.

    Branches on ``USE_2CTA_GROUP`` (constexpr) at every point where
    cta_group::1 and cta_group::2 paths diverge.  The branches reduce
    to compile-time elimination, so each compile produces a single
    flat kernel for one mode — no runtime overhead.

    Compile-time tile / shape parameters
    ------------------------------------

    All three are passed as Constexpr Python tuples and unpacked at the
    top of the kernel.  Same per-compile cache key shape across modes.

    * ``CLUSTER_SHAPE = (CLUSTER_SX, CLUSTER_SY)`` — actual CTA grid
      launched per cluster.  CTA_2 requires ``CLUSTER_SX % 2 == 0``
      (PTX 9.7.16.5.1: 2-SM groups are LSB-defined on
      ``%cluster_ctarank``, so each group must straddle two
      consecutive ranks along X).
    * ``CLUSTER_TILE = (M, N, K)`` — output tile per cluster, plus the
      K-loop tile (per-step granularity).  Conventional GEMM ``MNK``
      ordering.  Total cluster output covers ``M × N``; each K-loop
      iteration fetches a ``K`` slice of A and B.
    * ``GROUP_TILE = (M, N)`` — per-2-SM-group tile (CTA_2 only).  In
      CTA_1 mode this argument is ignored.  Encodes the tile-axis split
      for groups: ``GROUPS_M = CLUSTER_TILE[0] // GROUP_TILE[0]``,
      ``GROUPS_N = CLUSTER_TILE[1] // GROUP_TILE[1]``, with
      ``GROUPS_M * GROUPS_N == CLUSTER_SX * CLUSTER_SY / 2`` (= n_groups).
    """

    # ---- Unpack constexpr tuples ---------------------------------------
    CLUSTER_SX, CLUSTER_SY = CLUSTER_SHAPE
    CLUSTER_TILE_M, CLUSTER_TILE_N, K_TILE = CLUSTER_TILE
    GROUP_TILE_M, GROUP_TILE_N = GROUP_TILE  # CTA_2 only; ignored for CTA_1

    # ---- Per-CTA tile sizes (mode-dependent) ---------------------------
    if cutlass.const_expr(USE_2CTA_GROUP):
        CTA_TILE_M: cutlass.Constexpr[int] = GROUP_TILE_M // 2
        CTA_TILE_N: cutlass.Constexpr[int] = GROUP_TILE_N // 2
        # GROUPS_M, GROUPS_N derived from cluster tile / per-group tile (host-validated
        # to match GROUPS_M * GROUPS_N == n_groups = CLUSTER_SX * CLUSTER_SY / 2).
        GROUPS_N: cutlass.Constexpr[int] = CLUSTER_TILE_N // GROUP_TILE_N
        # Full TMEM (512 cols) — safe over-alloc for any CTA_2 N.
        NUM_TMEM_COLS: cutlass.Constexpr[int] = 512
    else:
        CTA_TILE_M: cutlass.Constexpr[int] = CLUSTER_TILE_M // CLUSTER_SX
        CTA_TILE_N: cutlass.Constexpr[int] = CLUSTER_TILE_N // CLUSTER_SY
        # CTA_1 formula: (N_TILE // 8) * 32.
        NUM_TMEM_COLS: cutlass.Constexpr[int] = (CTA_TILE_N // 8) * 32

    sA_elems: cutlass.Constexpr[int] = CTA_TILE_M * K_TILE
    sB_elems: cutlass.Constexpr[int] = CTA_TILE_N * K_TILE
    per_cta_txcount = tma_a_desc.global_tx_bytes() + tma_b_desc.global_tx_bytes()

    warp_idx = cute.arch.warp_idx()
    tidx, _, _ = cute.arch.thread_idx()
    bidx, bidy, _ = cute.arch.block_idx()

    # ---- Cluster rank / tile coords (mode-dependent) -------------------
    cluster_rank = cute.arch.block_idx_in_cluster()
    super_m = bidx // cutlass.Int32(CLUSTER_SX)
    super_n = bidy // cutlass.Int32(CLUSTER_SY)

    if cutlass.const_expr(USE_2CTA_GROUP):
        # 2-SM group structure: rank & 1 = within-group; rank >> 1 = group_idx.
        group_lane = cluster_rank & cutlass.Int32(1)
        group_idx = cluster_rank >> cutlass.Int32(1)
        gm_idx = group_idx // cutlass.Int32(GROUPS_N)
        gn_idx = group_idx % cutlass.Int32(GROUPS_N)
        is_group_leader = group_lane == cutlass.Int32(0)
        m_group_off = super_m * cutlass.Int32(CLUSTER_TILE_M) + gm_idx * cutlass.Int32(
            GROUP_TILE_M
        )
        n_group_off = super_n * cutlass.Int32(CLUSTER_TILE_N) + gn_idx * cutlass.Int32(
            GROUP_TILE_N
        )
        m_off_cta = m_group_off + group_lane * cutlass.Int32(CTA_TILE_M)
        n_off_cta = n_group_off + group_lane * cutlass.Int32(CTA_TILE_N)
    else:
        cluster_x = cluster_rank % cutlass.Int32(CLUSTER_SX)
        cluster_y = cluster_rank // cutlass.Int32(CLUSTER_SX)
        m_off_cta = super_m * cutlass.Int32(CLUSTER_TILE_M) + cluster_x * cutlass.Int32(
            CTA_TILE_M
        )
        n_off_cta = super_n * cutlass.Int32(CLUSTER_TILE_N) + cluster_y * cutlass.Int32(
            CTA_TILE_N
        )

    # ---- SMEM allocations (mode-independent) ---------------------------
    smem_a = cutlass.Array(
        cutlass.Float16, sA_elems, space=cutlass.AddressSpace.smem, alignment=128
    )
    smem_b = cutlass.Array(
        cutlass.Float16, sB_elems, space=cutlass.AddressSpace.smem, alignment=128
    )

    ab_full_mbar = cutlass.Array(
        cutlass.Int64, 1, space=cutlass.AddressSpace.smem, alignment=8
    )
    ab_empty_mbar = cutlass.Array(
        cutlass.Int64, 1, space=cutlass.AddressSpace.smem, alignment=8
    )
    acc_done_mbar = cutlass.Array(
        cutlass.Int64, 1, space=cutlass.AddressSpace.smem, alignment=8
    )
    tmem_ptr_i32 = cutlass.Array(
        cutlass.Int32, 1, space=cutlass.AddressSpace.smem, alignment=4
    )

    if warp_idx == 0:
        if prims.elect_sync():
            prims.mbarrier_init(ab_full_mbar, 1)
            prims.mbarrier_init(ab_empty_mbar, 1)
            prims.mbarrier_init(acc_done_mbar, 1)

    prims.fence_mbarrier_init()
    prims.barrier_cluster_arrive_relaxed()

    # ---- TMEM alloc / relinquish (group differs) -----------------------
    if cutlass.const_expr(USE_2CTA_GROUP):
        _GROUP = prims.CTAGroup.CTA_2
        _GROUP_LITERAL = "cta_2"
    else:
        _GROUP = prims.CTAGroup.CTA_1
        _GROUP_LITERAL = "cta_1"

    if warp_idx == 0:
        prims.tcgen05_alloc(tmem_ptr_i32, NUM_TMEM_COLS, group=_GROUP_LITERAL)

    prims.barrier_cluster_wait()
    prims.barrier_cta_sync(0)
    tmem_ptr = cutlass.inttoptr(tmem_ptr_i32.load(), 6, cutlass.Float32)

    if warp_idx == 0:
        prims.tcgen05_relinquish_alloc_permit(group=_GROUP_LITERAL)

    a_mcast_mask = cutlass.Int32(1) << cluster_rank
    b_mcast_mask = cutlass.Int32(1) << cluster_rank

    # idesc — collective per-group shape (CTA_2) or per-CTA (CTA_1).
    if cutlass.const_expr(USE_2CTA_GROUP):
        idesc = prims.Tcgen05InstrDesc.build(
            c_dtype=cutlass.Float32, n_dim=GROUP_TILE_N, m_dim=GROUP_TILE_M
        )
    else:
        idesc = prims.Tcgen05InstrDesc.build(
            c_dtype=cutlass.Float32, n_dim=CTA_TILE_N, m_dim=CTA_TILE_M
        )

    num_k_tiles = cute.ceil_div(k, K_TILE)
    k_block_offset_bytes: cutlass.Constexpr[int] = MMA_K_GRANULE * 2
    tma_empty_phase = cutlass.Int32(1)
    tma_full_phase = cutlass.Int32(0)
    group_leader_txcount = 2 * per_cta_txcount

    if warp_idx == 0:
        desc_a_root = prims.Tcgen05SmemDesc.build(
            start_address=smem_a,
            leading_byte_offset=16,
            stride_byte_offset=8 * K_TILE * 2,
            layout=prims.Tcgen05SmemSwizzle.SWIZZLE_128B,
        )
        desc_b_root = prims.Tcgen05SmemDesc.build(
            start_address=smem_b,
            leading_byte_offset=16,
            stride_byte_offset=8 * K_TILE * 2,
            layout=prims.Tcgen05SmemSwizzle.SWIZZLE_128B,
        )
        for k_tile_idx in range(num_k_tiles):
            scale_d_first = k_tile_idx > cutlass.Int32(0)

            while not prims.mbarrier_try_wait_parity(
                ab_empty_mbar, tma_empty_phase, time_limit=10_000_000
            ):
                pass
            tma_empty_phase = tma_empty_phase ^ cutlass.Int32(1)

            coord_k = k_tile_idx * K_TILE

            # arrive_expect_tx: leader-only (CTA_2 — bit-24 routes both CTAs'
            # complete_tx to leader's mbar) vs every-CTA (CTA_1 — own mbar).
            if cutlass.const_expr(USE_2CTA_GROUP):
                if is_group_leader:
                    if prims.elect_sync():
                        prims.mbarrier_arrive_expect_tx(
                            ab_full_mbar, group_leader_txcount
                        )
            else:
                if prims.elect_sync():
                    prims.mbarrier_arrive_expect_tx(ab_full_mbar, per_cta_txcount)

            # TMA loads.  group=_GROUP: CTA_2 enables wrapper bit-24 routing
            # (one mbar for both CTAs' complete_tx); CTA_1 leaves the mbar
            # pointer untouched so complete_tx fires on each CTA's own mbar.
            if prims.elect_sync():
                prims.cp_async_bulk_tensor_shared_cluster_global(
                    smem_a,
                    tma_a_desc.get_ptr(),
                    (coord_k, m_off_cta),
                    ab_full_mbar,
                    [],
                    multicast_mask=a_mcast_mask,
                    group=_GROUP,
                )
            if prims.elect_sync():
                prims.cp_async_bulk_tensor_shared_cluster_global(
                    smem_b,
                    tma_b_desc.get_ptr(),
                    (coord_k, n_off_cta),
                    ab_full_mbar,
                    [],
                    multicast_mask=b_mcast_mask,
                    group=_GROUP,
                )

            # Wait full_mbar: leader-only (CTA_2) vs every-CTA (CTA_1).
            if cutlass.const_expr(USE_2CTA_GROUP):
                if is_group_leader:
                    while not prims.mbarrier_try_wait_parity(
                        ab_full_mbar, tma_full_phase, time_limit=10_000_000
                    ):
                        pass
            else:
                while not prims.mbarrier_try_wait_parity(
                    ab_full_mbar, tma_full_phase, time_limit=10_000_000
                ):
                    pass
            tma_full_phase = tma_full_phase ^ cutlass.Int32(1)

            # MMA: leader-only (CTA_2) vs every-CTA (CTA_1).
            issue_mma = is_group_leader if USE_2CTA_GROUP else True
            if issue_mma:
                num_k_blocks: cutlass.Constexpr[int] = K_TILE // MMA_K_GRANULE
                for k_block_idx in cutlass.range_constexpr(num_k_blocks):
                    offset_bytes: cutlass.Constexpr[int] = (
                        k_block_offset_bytes * k_block_idx
                    )
                    desc_a = desc_a_root.advance_start_address(offset_bytes)
                    desc_b = desc_b_root.advance_start_address(offset_bytes)
                    if prims.elect_sync():
                        prims.tcgen05_mma(
                            prims.Tcgen05MMAKind.F16,
                            _GROUP,
                            tmem_ptr,
                            desc_a,
                            desc_b,
                            idesc,
                            scale_d_first if k_block_idx == 0 else True,
                        )

                # Per-iter commit.  CTA_2 broadcasts to both group members
                # via mask = 3 << cluster_rank (mask is over CLUSTER ranks
                # — multi-group clusters need this shift; literal 3 only
                # works for single-group clusters).
                if cutlass.const_expr(USE_2CTA_GROUP):
                    if prims.elect_sync():
                        prims.tcgen05_commit(
                            ab_empty_mbar,
                            multicast_mask=cutlass.Int32(3) << cluster_rank,
                            group=prims.CTAGroup.CTA_2,
                        )
                else:
                    if prims.elect_sync():
                        prims.tcgen05_commit(ab_empty_mbar, group=prims.CTAGroup.CTA_1)

        # Post-K-loop accumulator-ready signal.
        issue_mma_final = is_group_leader if USE_2CTA_GROUP else True
        if issue_mma_final:
            if cutlass.const_expr(USE_2CTA_GROUP):
                if prims.elect_sync():
                    prims.tcgen05_commit(
                        acc_done_mbar,
                        multicast_mask=cutlass.Int32(3) << cluster_rank,
                        group=prims.CTAGroup.CTA_2,
                    )
            else:
                if prims.elect_sync():
                    prims.tcgen05_commit(acc_done_mbar, group=prims.CTAGroup.CTA_1)

    # ---- Epilogue ------------------------------------------------------
    prims.barrier_cta_sync(0)
    while not prims.mbarrier_try_wait_parity(
        acc_done_mbar, cutlass.Int32(0), time_limit=10_000_000
    ):
        pass

    tmem_raw_addr = tmem_ptr_i32.load()
    base_col_id = tmem_raw_addr & cutlass.Int32(0xFFFF)
    base_row_id = tmem_raw_addr >> cutlass.Int32(16)
    row_id_with_warp = base_row_id + warp_idx * cutlass.Int32(32)
    cur_tmem_col_addr = (row_id_with_warp << cutlass.Int32(16)) | base_col_id

    gC_ptr = mC_mn.iterator.raw_ptr()
    vsize: cutlass.Constexpr[int] = 256 // 16

    # Subtile count: collective GROUP_TILE_N for CTA_2 (TMEM Layout A holds
    # the full group-N range), per-CTA CTA_TILE_N for CTA_1.
    if cutlass.const_expr(USE_2CTA_GROUP):
        subtile_cnt: cutlass.Constexpr[int] = GROUP_TILE_N // 32
    else:
        subtile_cnt: cutlass.Constexpr[int] = CTA_TILE_N // 32
    t2r_inst_repx: cutlass.Constexpr[int] = 32

    for subtile_idx in cutlass.range_constexpr(subtile_cnt):
        subtile_col_offset = subtile_idx * 32
        subtile_tmem_addr = cur_tmem_col_addr + cutlass.Int32(subtile_col_offset)
        tmem = cutlass.inttoptr(subtile_tmem_addr, 6, cutlass.Float32)
        c_rmem_vec = prims.tcgen05_ld("32x32b", tmem, num=t2r_inst_repx)
        prims.tcgen05_wait(prims.Tcgen05Wait.LOAD)

        row = tidx + m_off_cta
        # CTA_2 Layout A: TMEM holds full GROUP_TILE_N cols, write at
        # n_group_off (NOT n_off_cta).  CTA_1: each CTA owns its own
        # CTA_TILE_N range, write at n_off_cta.
        if cutlass.const_expr(USE_2CTA_GROUP):
            col = n_group_off + cutlass.Int32(subtile_col_offset)
        else:
            col = n_off_cta + cutlass.Int32(subtile_col_offset)
        for j in cutlass.range_constexpr(t2r_inst_repx // vsize):
            vec_f32 = c_rmem_vec[j * vsize : (j + 1) * vsize]
            vec_f16 = vec_f32.to(cutlass.Float16)
            linear_idx = row * mC_mn.shape[1] + col + j * vsize
            (gC_ptr + linear_idx).store(vec_f16, alignment=16)

    prims.tcgen05_fence(prims.Tcgen05Fence.BEFORE_THREAD_SYNC)
    prims.barrier_cta_sync(0)
    if warp_idx == 0:
        prims.tcgen05_dealloc(tmem_ptr, NUM_TMEM_COLS, group=_GROUP_LITERAL)


@cute.jit
def host(
    a: cute.Tensor,
    b: cute.Tensor,
    c: cute.Tensor,
    mnk: Tuple[int, int, int],
    USE_2CTA_GROUP: cutlass.Constexpr[int],
    CLUSTER_SHAPE: cutlass.Constexpr,
    CLUSTER_TILE: cutlass.Constexpr,
    GROUP_TILE: cutlass.Constexpr,
) -> None:
    """Build TMA descriptors and launch the unified kernel."""
    CLUSTER_SX, CLUSTER_SY = CLUSTER_SHAPE
    CLUSTER_TILE_M, CLUSTER_TILE_N, K_TILE = CLUSTER_TILE
    GROUP_TILE_M, GROUP_TILE_N = GROUP_TILE

    # Per-CTA tile dimensions: depend on mode but resolved at compile time.
    CTA_TILE_M: cutlass.Constexpr[int] = (
        GROUP_TILE_M // 2 if USE_2CTA_GROUP else CLUSTER_TILE_M // CLUSTER_SX
    )
    CTA_TILE_N: cutlass.Constexpr[int] = (
        GROUP_TILE_N // 2 if USE_2CTA_GROUP else CLUSTER_TILE_N // CLUSTER_SY
    )

    tma_a_desc = cuda.create_tensor_map_tiled(
        global_address=a.iterator.toint(),
        dtype=cutlass.Float16,
        global_dims=[a.shape[1], a.shape[0]],
        global_strides=[a.shape[1] * 2 // 16],
        box_dims=[K_TILE, CTA_TILE_M],
        swizzle=cuda.TensorMapSwizzle.s128b,
    )
    tma_b_desc = cuda.create_tensor_map_tiled(
        global_address=b.iterator.toint(),
        dtype=cutlass.Float16,
        global_dims=[b.shape[1], b.shape[0]],
        global_strides=[b.shape[1] * 2 // 16],
        box_dims=[K_TILE, CTA_TILE_N],
        swizzle=cuda.TensorMapSwizzle.s128b,
    )

    grid_x_super = cute.ceil_div(mnk[0], CLUSTER_TILE_M)
    grid_y_super = cute.ceil_div(mnk[1], CLUSTER_TILE_N)
    grid_x_total = grid_x_super * CLUSTER_SX
    grid_y_total = grid_y_super * CLUSTER_SY

    kernel(
        tma_a_desc,
        tma_b_desc,
        c,
        mnk[2],
        USE_2CTA_GROUP,
        CLUSTER_SHAPE,
        CLUSTER_TILE,
        GROUP_TILE,
    ).launch(
        grid=(grid_x_total, grid_y_total, 1),
        block=(128, 1, 1),
        cluster=(CLUSTER_SX, CLUSTER_SY, 1),
    )


@lru_cache(maxsize=None)
def compile(
    k: int = _DEFAULT_MNK[2],
    USE_2CTA_GROUP: bool = True,
    CLUSTER_SHAPE: Tuple[int, int] | None = None,
    CLUSTER_TILE: Tuple[int, int] | None = None,
    K_TILE: int = _DEFAULT_K_TILE,
    GROUP_TILE: Tuple[int, int] | None = None,
) -> Callable:
    """AOT-compile keyed on the full constexpr tuple.  M, N stay symbolic."""
    cluster_shape, cluster_tile_mn, group_tile = _resolve(
        USE_2CTA_GROUP, CLUSTER_SHAPE, CLUSTER_TILE, GROUP_TILE
    )
    _validate(USE_2CTA_GROUP, cluster_shape, cluster_tile_mn, K_TILE, group_tile)

    sym_m = cute.sym_int64()
    sym_n = cute.sym_int64()
    fake_a = make_fake_compact_tensor(
        io_dtype, (sym_m, k), stride_order=(1, 0), assumed_align=16
    )
    fake_b = make_fake_compact_tensor(
        io_dtype, (sym_n, k), stride_order=(1, 0), assumed_align=16
    )
    fake_c = make_fake_compact_tensor(
        io_dtype, (sym_m, sym_n), stride_order=(1, 0), assumed_align=16
    )
    cluster_tile = (cluster_tile_mn[0], cluster_tile_mn[1], K_TILE)
    return cute.compile(
        host,
        fake_a,
        fake_b,
        fake_c,
        (sym_m, sym_n, k),
        int(USE_2CTA_GROUP),
        cluster_shape,
        cluster_tile,
        group_tile,
        options="--enable-tvm-ffi",
    )


def _resolve(
    USE_2CTA_GROUP: bool,
    CLUSTER_SHAPE: Tuple[int, int] | None,
    CLUSTER_TILE: Tuple[int, int] | None,
    GROUP_TILE: Tuple[int, int] | None,
) -> Tuple[Tuple[int, int], Tuple[int, int], Tuple[int, int]]:
    """Return ``(CLUSTER_SHAPE, CLUSTER_TILE_MN, GROUP_TILE)`` with defaults
    filled.

    For CTA_2 mode, ``CLUSTER_SHAPE[0]`` must be even — 2-SM groups are
    LSB-defined on ``%cluster_ctarank``, so each group must straddle two
    consecutive ranks along the X axis.  ``n_groups = CLUSTER_SX *
    CLUSTER_SY / 2``; the ``GROUP_TILE`` and ``CLUSTER_TILE`` together
    imply the (GROUPS_M, GROUPS_N) split via ``GROUPS_M = M / M_per_group`` and ``GROUPS_N = N
    / N_per_group``, with ``GROUPS_M * GROUPS_N == n_groups``.

    ``GROUP_TILE`` is unused in CTA_1 mode (each CTA owns
    ``CLUSTER_TILE / CLUSTER_SHAPE``).
    """
    if USE_2CTA_GROUP:
        if CLUSTER_SHAPE is None:
            CLUSTER_SHAPE = (2, 2)
        CLUSTER_SX, CLUSTER_SY = CLUSTER_SHAPE
        if CLUSTER_SX % 2 != 0:
            raise ValueError(
                f"USE_2CTA_GROUP=True requires CLUSTER_SHAPE[0] (CLUSTER_SX) "
                f"to be even (LSB-defined 2-SM groups along X); got {CLUSTER_SHAPE}"
            )
        n_groups = (CLUSTER_SX * CLUSTER_SY) // 2

        # Default-fill GROUP_TILE / CLUSTER_TILE.  ``CLUSTER_SHAPE`` fixes
        # ``n_groups`` but leaves the (GROUPS_M, GROUPS_N) split — *how* the groups
        # distribute across M vs N — undetermined.  Convention: when
        # ``GROUP_TILE`` is omitted, default to **M-stack** (GROUPS_M=n_groups,
        # GROUPS_N=1); the user must spell GROUP_TILE out for N-stack or 2D
        # splits.  Same convention is used to default-fill CLUSTER_TILE
        # from GROUP_TILE.
        if CLUSTER_TILE is None and GROUP_TILE is None:
            GROUP_TILE = (256, 128)
            CLUSTER_TILE = (GROUP_TILE[0] * n_groups, GROUP_TILE[1])
        elif CLUSTER_TILE is None:
            CLUSTER_TILE = (GROUP_TILE[0] * n_groups, GROUP_TILE[1])
        elif GROUP_TILE is None:
            # Derive GROUP_TILE from CLUSTER_TILE (M-stack default split).
            if CLUSTER_TILE[0] % n_groups != 0:
                raise ValueError(
                    f"Cannot derive GROUP_TILE from CLUSTER_TILE={CLUSTER_TILE} "
                    f"with n_groups={n_groups}: M-stack default requires "
                    f"CLUSTER_TILE[0] % n_groups == 0.  Pass GROUP_TILE "
                    f"explicitly for non-M-stack splits."
                )
            GROUP_TILE = (CLUSTER_TILE[0] // n_groups, CLUSTER_TILE[1])

        # Derive (GROUPS_M, GROUPS_N) from CLUSTER_TILE / GROUP_TILE and validate.
        if CLUSTER_TILE[0] % GROUP_TILE[0] != 0:
            raise ValueError(
                f"CLUSTER_TILE[0]={CLUSTER_TILE[0]} not divisible by "
                f"GROUP_TILE[0]={GROUP_TILE[0]}"
            )
        if CLUSTER_TILE[1] % GROUP_TILE[1] != 0:
            raise ValueError(
                f"CLUSTER_TILE[1]={CLUSTER_TILE[1]} not divisible by "
                f"GROUP_TILE[1]={GROUP_TILE[1]}"
            )
        GROUPS_M = CLUSTER_TILE[0] // GROUP_TILE[0]
        GROUPS_N = CLUSTER_TILE[1] // GROUP_TILE[1]
        if GROUPS_M * GROUPS_N != n_groups:
            raise ValueError(
                f"Derived (GROUPS_M, GROUPS_N) = ({GROUPS_M}, {GROUPS_N}); GROUPS_M*GROUPS_N={GROUPS_M * GROUPS_N} must "
                f"equal n_groups={n_groups} (= CLUSTER_SX * CLUSTER_SY / 2)"
            )
        if (GROUPS_M, GROUPS_N) not in _ALLOWED_GROUPS_MN:
            raise ValueError(
                f"(GROUPS_M, GROUPS_N)=({GROUPS_M}, {GROUPS_N}) not in allowed set {sorted(_ALLOWED_GROUPS_MN)}"
            )
    else:
        if CLUSTER_SHAPE is None:
            CLUSTER_SHAPE = (1, 1)
        CLUSTER_SX, CLUSTER_SY = CLUSTER_SHAPE
        if GROUP_TILE is not None:
            raise ValueError("GROUP_TILE is a CTA_2-only kwarg (USE_2CTA_GROUP=False)")
        # CTA_1 placeholder — kernel ignores GROUP_TILE in this mode.
        GROUP_TILE = (1, 1)
        if CLUSTER_TILE is None:
            CLUSTER_TILE = (128 * CLUSTER_SX, 128 * CLUSTER_SY)

    return tuple(CLUSTER_SHAPE), tuple(CLUSTER_TILE), tuple(GROUP_TILE)


def _validate(
    USE_2CTA_GROUP: bool,
    CLUSTER_SHAPE: Tuple[int, int],
    CLUSTER_TILE_MN: Tuple[int, int],
    K_TILE: int,
    GROUP_TILE: Tuple[int, int],
) -> None:
    CLUSTER_SX, CLUSTER_SY = CLUSTER_SHAPE
    CLUSTER_TILE_M, CLUSTER_TILE_N = CLUSTER_TILE_MN
    if CLUSTER_SX * CLUSTER_SY > 16:
        raise ValueError(
            f"cluster_size CLUSTER_SX*CLUSTER_SY={CLUSTER_SX * CLUSTER_SY} "
            f"exceeds hardware max 16"
        )
    required_group_tile_m = 2 * _M_PER_CTA_REQUIRED  # CTA_2 splits 2 CTAs along M
    if USE_2CTA_GROUP:
        GROUP_TILE_M, GROUP_TILE_N = GROUP_TILE
        if GROUP_TILE_M != required_group_tile_m:
            raise ValueError(
                f"GROUP_TILE[0]={GROUP_TILE_M} must equal {required_group_tile_m} "
                f"(kernel block=(128,1,1) requires "
                f"M_PER_CTA={_M_PER_CTA_REQUIRED}; CTA_2 splits 2 CTAs along M)"
            )
        if GROUP_TILE_N % 32 != 0:
            raise ValueError(
                f"GROUP_TILE[1]={GROUP_TILE_N} must be a multiple of 32 "
                f"(SHAPE_32X32B epilogue granule)"
            )
    else:
        if CLUSTER_TILE_M % CLUSTER_SX != 0:
            raise ValueError(
                f"CLUSTER_TILE[0]={CLUSTER_TILE_M} must be divisible by "
                f"CLUSTER_SX={CLUSTER_SX}"
            )
        cta_tile_m = CLUSTER_TILE_M // CLUSTER_SX
        if cta_tile_m != _M_PER_CTA_REQUIRED:
            raise ValueError(
                f"CTA_TILE_M=CLUSTER_TILE[0]/CLUSTER_SX={cta_tile_m} must "
                f"equal {_M_PER_CTA_REQUIRED} (kernel block=(128,1,1) "
                f"requires this exact M_PER_CTA)"
            )
        if CLUSTER_TILE_N % CLUSTER_SY != 0:
            raise ValueError(
                f"CLUSTER_TILE[1]={CLUSTER_TILE_N} must be divisible by "
                f"CLUSTER_SY={CLUSTER_SY}"
            )
        if (CLUSTER_TILE_N // CLUSTER_SY) % 32 != 0:
            raise ValueError(
                f"CTA_TILE_N={CLUSTER_TILE_N // CLUSTER_SY} must be a multiple of 32"
            )
    if K_TILE % MMA_K_GRANULE != 0:
        raise ValueError(
            f"K_TILE={K_TILE} must be a multiple of MMA_K_GRANULE={MMA_K_GRANULE}"
        )


def run(
    compiled_fn: Callable,
    mnk: Tuple[int, int, int] = _DEFAULT_MNK,
    *,
    USE_2CTA_GROUP: bool = True,
    CLUSTER_SHAPE: Tuple[int, int] | None = None,
    CLUSTER_TILE: Tuple[int, int] | None = None,
    K_TILE: int = _DEFAULT_K_TILE,
    GROUP_TILE: Tuple[int, int] | None = None,
    seed: int = 42,
) -> tuple[torch.Tensor, torch.Tensor]:
    """Allocate tensors, call ``compiled_fn``, and return ``(output, reference)``.

    The compile-time topology kwargs are repeated here only to validate the
    runtime problem shape and to print the same launch summary as ``verify``.
    """
    if not torch.cuda.is_available():
        raise RuntimeError("CUDA GPU required")

    cluster_shape, cluster_tile_mn, group_tile = _resolve(
        USE_2CTA_GROUP, CLUSTER_SHAPE, CLUSTER_TILE, GROUP_TILE
    )
    _validate(USE_2CTA_GROUP, cluster_shape, cluster_tile_mn, K_TILE, group_tile)
    m, n, k = mnk
    CLUSTER_TILE_M, CLUSTER_TILE_N = cluster_tile_mn
    if m % CLUSTER_TILE_M != 0:
        raise ValueError(
            f"M={m} must be a multiple of CLUSTER_TILE[0]={CLUSTER_TILE_M}"
        )
    if n % CLUSTER_TILE_N != 0:
        raise ValueError(
            f"N={n} must be a multiple of CLUSTER_TILE[1]={CLUSTER_TILE_N}"
        )
    if k % K_TILE != 0:
        raise ValueError(f"K={k} must be a multiple of K_TILE={K_TILE}")

    mode = "CTA_2" if USE_2CTA_GROUP else "CTA_1"
    tag_extra = f"  GROUP_TILE={group_tile}" if USE_2CTA_GROUP else ""
    print(
        f"Running clusterMxN_2cta_mma  mnk={mnk}  mode={mode}  "
        f"CLUSTER_SHAPE={cluster_shape}  CLUSTER_TILE={cluster_tile_mn}  "
        f"K_TILE={K_TILE}{tag_extra}",
        flush=True,
    )

    torch.manual_seed(seed)
    a = (
        torch.empty(m, k, dtype=torch.int32)
        .random_(-2, 2)
        .to(dtype=cutlass_torch.dtype(io_dtype), device="cuda")
    )
    b = (
        torch.empty(n, k, dtype=torch.int32)
        .random_(-2, 2)
        .to(dtype=cutlass_torch.dtype(io_dtype), device="cuda")
    )
    c = torch.zeros(m, n, dtype=cutlass_torch.dtype(io_dtype), device="cuda")

    compiled_fn(a, b, c, (m, n, k))
    torch.cuda.synchronize()

    ref = torch.einsum("mk,nk->mn", a.float(), b.float()).to(a.dtype)
    return c, ref


def verify(
    mnk: Tuple[int, int, int] = _DEFAULT_MNK,
    *,
    USE_2CTA_GROUP: bool = True,
    CLUSTER_SHAPE: Tuple[int, int] | None = None,
    CLUSTER_TILE: Tuple[int, int] | None = None,
    K_TILE: int = _DEFAULT_K_TILE,
    GROUP_TILE: Tuple[int, int] | None = None,
    tolerance: float = 0.1,
) -> None:
    """Compile, run, and assert the clustered MMA result."""
    m, n, k = mnk
    compiled_fn = compile(
        k=k,
        USE_2CTA_GROUP=USE_2CTA_GROUP,
        CLUSTER_SHAPE=CLUSTER_SHAPE,
        CLUSTER_TILE=CLUSTER_TILE,
        K_TILE=K_TILE,
        GROUP_TILE=GROUP_TILE,
    )
    print(
        f"Compile kernel (mnk={mnk}, USE_2CTA_GROUP={USE_2CTA_GROUP}, "
        f"K_TILE={K_TILE}) OK",
        flush=True,
    )

    c, ref = run(
        compiled_fn,
        mnk,
        USE_2CTA_GROUP=USE_2CTA_GROUP,
        CLUSTER_SHAPE=CLUSTER_SHAPE,
        CLUSTER_TILE=CLUSTER_TILE,
        K_TILE=K_TILE,
        GROUP_TILE=GROUP_TILE,
    )
    print(f"Run kernel (m={m}, n={n}, k={k}) OK", flush=True)

    torch.testing.assert_close(c, ref, atol=tolerance, rtol=1e-5)
    print("PASS")


# ---------------------------------------------------------------------------
# Variant catalog
# ---------------------------------------------------------------------------

VARIANTS = {
    # CTA_2 variants — (GROUPS_M, GROUPS_N) derived from CLUSTER_TILE / GROUP_TILE:
    # GROUPS_M = CLUSTER_TILE_M // GROUP_TILE_M, GROUPS_N = CLUSTER_TILE_N // GROUP_TILE_N;
    # GROUPS_M * GROUPS_N == n_groups.  When GROUP_TILE is omitted, _resolve() defaults
    # to M-stack (GROUPS_M = n_groups, GROUPS_N = 1).
    "V1": dict(
        USE_2CTA_GROUP=True,
        CLUSTER_SHAPE=(2, 1),
        CLUSTER_TILE=(256, 128),
        # GROUP_TILE defaults to (256, 128) under M-stack (n_groups=1).
    ),
    "V2": dict(
        USE_2CTA_GROUP=True,
        CLUSTER_SHAPE=(2, 2),
        CLUSTER_TILE=(512, 128),
        # M-stack default: GROUP_TILE = (512//2, 128) = (256, 128).
    ),
    "V3": dict(
        USE_2CTA_GROUP=True,
        CLUSTER_SHAPE=(2, 2),
        CLUSTER_TILE=(256, 256),
        GROUP_TILE=(256, 128),  # explicit N-stack split (GROUPS_M=1, GROUPS_N=2)
    ),
    "V4": dict(
        USE_2CTA_GROUP=True,
        CLUSTER_SHAPE=(2, 4),
        CLUSTER_TILE=(512, 256),
        GROUP_TILE=(256, 128),  # 2x2 mixed split (GROUPS_M=2, GROUPS_N=2)
    ),
    "V5": dict(
        USE_2CTA_GROUP=True,
        CLUSTER_SHAPE=(2, 2),
        CLUSTER_TILE=(256, 128),
        GROUP_TILE=(256, 64),  # explicit N-shrink split (GROUPS_M=1, GROUPS_N=2)
    ),
    "V6": dict(
        USE_2CTA_GROUP=True,
        CLUSTER_SHAPE=(2, 4),
        CLUSTER_TILE=(256, 256),
        GROUP_TILE=(256, 64),  # explicit N-stack ×4 split (GROUPS_M=1, GROUPS_N=4)
    ),
    # CTA_1 variants — arbitrary cluster shape, each CTA does its own MMA.
    # GROUP_TILE is unused.
    "C1": dict(USE_2CTA_GROUP=False, CLUSTER_SHAPE=(1, 1), CLUSTER_TILE=(128, 128)),
    "C2": dict(USE_2CTA_GROUP=False, CLUSTER_SHAPE=(1, 2), CLUSTER_TILE=(128, 256)),
    "C3": dict(USE_2CTA_GROUP=False, CLUSTER_SHAPE=(2, 2), CLUSTER_TILE=(256, 256)),
}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument(
        "--mnk",
        type=str,
        default=",".join(str(x) for x in _DEFAULT_MNK),
        help=f"Comma-separated M,N,K (default: {_DEFAULT_MNK}).",
    )
    parser.add_argument(
        "--no_2cta_group",
        dest="USE_2CTA_GROUP",
        action="store_false",
        default=True,
        help="Use cta_group::1 (each CTA independent); default cta_group::2.",
    )
    parser.add_argument(
        "--CLUSTER_SHAPE",
        type=str,
        default=None,
        help="Comma-separated CX,CY (e.g. '2,2'); default depends on mode.",
    )
    parser.add_argument(
        "--CLUSTER_TILE",
        type=str,
        default=None,
        help="Comma-separated M,N for CLUSTER_TILE; default mode-specific.",
    )
    parser.add_argument("--K_TILE", type=int, default=_DEFAULT_K_TILE)
    parser.add_argument(
        "--GROUP_TILE",
        type=str,
        default=None,
        help="Comma-separated M,N for GROUP_TILE (CTA_2 only); default mode-specific.",
    )
    parser.add_argument("--tolerance", type=float, default=0.1)
    args = parser.parse_args()

    mnk = tuple(int(x) for x in args.mnk.split(","))
    CLUSTER_SHAPE = (
        tuple(int(x) for x in args.CLUSTER_SHAPE.split(","))
        if args.CLUSTER_SHAPE
        else None
    )
    CLUSTER_TILE = (
        tuple(int(x) for x in args.CLUSTER_TILE.split(","))
        if args.CLUSTER_TILE
        else None
    )
    GROUP_TILE = (
        tuple(int(x) for x in args.GROUP_TILE.split(",")) if args.GROUP_TILE else None
    )
    verify(
        mnk,
        USE_2CTA_GROUP=args.USE_2CTA_GROUP,
        CLUSTER_SHAPE=CLUSTER_SHAPE,
        CLUSTER_TILE=CLUSTER_TILE,
        K_TILE=args.K_TILE,
        GROUP_TILE=GROUP_TILE,
        tolerance=args.tolerance,
    )
