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
Cluster multicast GEMM example.

To run::

    python CuTeDSL/experimental/primitives/tcgen05/mcast_clusterMxN_2cta_mma.py
    python CuTeDSL/experimental/primitives/tcgen05/mcast_clusterMxN_2cta_mma.py --mnk 512,512,128 --CLUSTER_SHAPE 2,2

"""

from __future__ import annotations

import argparse
from functools import lru_cache
from math import lcm
from typing import Callable, Tuple

import torch

import cutlass
import cutlass.cute as cute
import cutlass.experimental.cuda as cuda
import cutlass.torch as cutlass_torch
from cutlass.cute.runtime import make_fake_compact_tensor
from cutlass.experimental import primitives as prims


# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

io_dtype = cutlass.Float16

MMA_K_GRANULE: cutlass.Constexpr[int] = 16
_DEFAULT_K_TILE: int = 64
_DEFAULT_MNK: Tuple[int, int, int] = (512, 512, 128)
_MIN_CTA_TILE_M: int = 128
_MIN_CTA_TILE_N: int = 128
_MAX_DENSE_M_DIM: int = 496
_MAX_DENSE_N_DIM: int = 504
_MAX_TMA_BOX_DIM: int = 256


# ---------------------------------------------------------------------------
# Device kernel
# ---------------------------------------------------------------------------


@cute.kernel
def kernel(
    tma_a_desc: cutlass.GridConstant[cuda.TensorMap],
    tma_b_desc: cutlass.GridConstant[cuda.TensorMap],
    mC_mn: cute.Tensor,
    k: cutlass.Int32,
    CLUSTER_SHAPE: cutlass.Constexpr,
    CLUSTER_TILE: cutlass.Constexpr,
    GROUP_TILE: cutlass.Constexpr,
) -> None:
    """CTA_2 MxN GEMM with same-lane A/B TMA multicast cohorts."""
    CLUSTER_SX, CLUSTER_SY = CLUSTER_SHAPE
    CLUSTER_TILE_M, CLUSTER_TILE_N, K_TILE = CLUSTER_TILE
    GROUP_TILE_M, GROUP_TILE_N = GROUP_TILE
    CTA_TILE_M: cutlass.Constexpr[int] = GROUP_TILE_M // 2
    CTA_TILE_N: cutlass.Constexpr[int] = GROUP_TILE_N // 2
    GROUPS_M: cutlass.Constexpr[int] = CLUSTER_SX // 2
    GROUPS_N: cutlass.Constexpr[int] = CLUSTER_SY

    warp_idx = cute.arch.warp_idx()
    tidx, _, _ = cute.arch.thread_idx()
    bidx, bidy, _ = cute.arch.block_idx()
    cluster_rank = cute.arch.block_idx_in_cluster()

    cta_m_rank = cluster_rank % cutlass.Int32(CLUSTER_SX)
    cta_n_rank = cluster_rank // cutlass.Int32(CLUSTER_SX)
    pair_m_base = cta_m_rank & cutlass.Int32(-2)
    group_lane = cta_m_rank & cutlass.Int32(1)
    group_m_idx = pair_m_base >> cutlass.Int32(1)
    group_n_idx = cta_n_rank
    pair_leader_rank = cta_n_rank * cutlass.Int32(CLUSTER_SX) + pair_m_base
    is_group_leader = cluster_rank == pair_leader_rank
    pair_mcast_mask = cutlass.Int32(3) << pair_leader_rank

    super_m = bidx // cutlass.Int32(CLUSTER_SX)
    super_n = bidy // cutlass.Int32(CLUSTER_SY)
    m_group_off = super_m * CLUSTER_TILE_M + group_m_idx * GROUP_TILE_M
    n_group_off = super_n * CLUSTER_TILE_N + group_n_idx * GROUP_TILE_N
    m_off_cta = m_group_off + group_lane * CTA_TILE_M
    n_off_cta = n_group_off + group_lane * CTA_TILE_N

    ab_full_mbar = cutlass.Array(cutlass.Int64, 1, space=cutlass.AddressSpace.smem)
    ab_empty_mbar = cutlass.Array(cutlass.Int64, 1, space=cutlass.AddressSpace.smem)
    acc_done_mbar = cutlass.Array(cutlass.Int64, 1, space=cutlass.AddressSpace.smem)
    tmem_ptr_i32 = cutlass.Array(cutlass.Int32, 1, space=cutlass.AddressSpace.smem)

    A_MCAST_ROWS: cutlass.Constexpr[int] = CTA_TILE_M // GROUPS_N
    B_MCAST_ROWS: cutlass.Constexpr[int] = CTA_TILE_N // GROUPS_M
    A_MCAST_ELEMS: cutlass.Constexpr[int] = A_MCAST_ROWS * K_TILE
    B_MCAST_ELEMS: cutlass.Constexpr[int] = B_MCAST_ROWS * K_TILE

    sA_elems: cutlass.Constexpr[int] = CTA_TILE_M * K_TILE
    sB_elems: cutlass.Constexpr[int] = CTA_TILE_N * K_TILE
    ab_empty_arrive_count: cutlass.Constexpr[int] = GROUPS_M + GROUPS_N - 1
    smem_a = cutlass.Array(
        cutlass.Float16, sA_elems, space=cutlass.AddressSpace.smem, alignment=128
    )
    smem_b = cutlass.Array(
        cutlass.Float16, sB_elems, space=cutlass.AddressSpace.smem, alignment=128
    )

    if warp_idx == 0:
        if prims.elect_sync():
            prims.mbarrier_init(ab_full_mbar, 1)
            prims.mbarrier_init(ab_empty_mbar, ab_empty_arrive_count)
            prims.mbarrier_init(acc_done_mbar, 1)
    prims.fence_mbarrier_init()
    prims.barrier_cluster_arrive_relaxed()

    # Dense CTA_2 tcgen05 allocates a 512-column TMEM block.  The instruction
    # descriptor's n_dim selects the active columns for this pair tile.
    NUM_TMEM_COLS: cutlass.Constexpr[int] = 512
    if warp_idx == 0:
        prims.tcgen05_alloc(tmem_ptr_i32, NUM_TMEM_COLS, group="cta_2")

    prims.barrier_cluster_wait()
    prims.barrier_cta_sync(0)
    tmem_ptr = cutlass.inttoptr(tmem_ptr_i32.load(), 6, cutlass.Float32)
    if warp_idx == 0:
        prims.tcgen05_relinquish_alloc_permit(group="cta_2")

    pair_leader_txcount = 2 * (
        GROUPS_N * tma_a_desc.global_tx_bytes()
        + GROUPS_M * tma_b_desc.global_tx_bytes()
    )

    a_mcast_mask = cutlass.Int32(0)
    for peer_n in cutlass.range_constexpr(GROUPS_N):
        peer_rank = cutlass.Int32(peer_n * CLUSTER_SX) + cta_m_rank
        a_mcast_mask = a_mcast_mask + (cutlass.Int32(1) << peer_rank)

    b_mcast_mask = cutlass.Int32(0)
    for peer_pair_m in cutlass.range_constexpr(GROUPS_M):
        peer_rank = (
            cta_n_rank * cutlass.Int32(CLUSTER_SX)
            + cutlass.Int32(peer_pair_m * 2)
            + group_lane
        )
        b_mcast_mask = b_mcast_mask + (cutlass.Int32(1) << peer_rank)

    ab_empty_mcast_mask = cutlass.Int32(0)
    for peer_n in cutlass.range_constexpr(GROUPS_N):
        peer_pair_leader = cutlass.Int32(peer_n * CLUSTER_SX) + pair_m_base
        ab_empty_mcast_mask = ab_empty_mcast_mask | (
            cutlass.Int32(3) << peer_pair_leader
        )
    for peer_pair_m in cutlass.range_constexpr(GROUPS_M):
        peer_pair_leader = cta_n_rank * cutlass.Int32(CLUSTER_SX) + cutlass.Int32(
            peer_pair_m * 2
        )
        ab_empty_mcast_mask = ab_empty_mcast_mask | (
            cutlass.Int32(3) << peer_pair_leader
        )

    a_mcast_m_offset = cta_n_rank * cutlass.Int32(A_MCAST_ROWS)
    a_mcast_smem_offset = cta_n_rank * cutlass.Int32(A_MCAST_ELEMS)
    b_mcast_pair_idx = pair_m_base >> cutlass.Int32(1)
    b_mcast_n_offset = b_mcast_pair_idx * cutlass.Int32(B_MCAST_ROWS)
    b_mcast_smem_offset = b_mcast_pair_idx * cutlass.Int32(B_MCAST_ELEMS)

    idesc = prims.Tcgen05InstrDesc.build(
        c_dtype=cutlass.Float32, n_dim=GROUP_TILE_N, m_dim=GROUP_TILE_M
    )

    num_k_tiles = cute.ceil_div(k, K_TILE)
    k_block_offset_bytes: cutlass.Constexpr[int] = MMA_K_GRANULE * 2
    tma_empty_phase = cutlass.Int32(1)
    tma_full_phase = cutlass.Int32(0)

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
            while not prims.mbarrier_try_wait_parity(
                ab_empty_mbar, tma_empty_phase, time_limit=10_000_000
            ):
                pass
            tma_empty_phase = tma_empty_phase ^ cutlass.Int32(1)

            coord_k = k_tile_idx * K_TILE
            scale_d_first = k_tile_idx > cutlass.Int32(0)

            if is_group_leader:
                if prims.elect_sync():
                    prims.mbarrier_arrive_expect_tx(ab_full_mbar, pair_leader_txcount)

            if prims.elect_sync():
                prims.cp_async_bulk_tensor_shared_cluster_global(
                    smem_a.subview(a_mcast_smem_offset),
                    tma_a_desc.get_ptr(),
                    (coord_k, m_off_cta + a_mcast_m_offset),
                    ab_full_mbar,
                    [],
                    multicast_mask=a_mcast_mask,
                    group=prims.CTAGroup.CTA_2,
                )
            if prims.elect_sync():
                prims.cp_async_bulk_tensor_shared_cluster_global(
                    smem_b.subview(b_mcast_smem_offset),
                    tma_b_desc.get_ptr(),
                    (coord_k, n_off_cta + b_mcast_n_offset),
                    ab_full_mbar,
                    [],
                    multicast_mask=b_mcast_mask,
                    group=prims.CTAGroup.CTA_2,
                )

            if is_group_leader:
                while not prims.mbarrier_try_wait_parity(
                    ab_full_mbar, tma_full_phase, time_limit=10_000_000
                ):
                    pass

                num_k_blocks: cutlass.Constexpr[int] = K_TILE // MMA_K_GRANULE
                for k_block_idx in cutlass.range_constexpr(num_k_blocks):
                    offset_bytes: cutlass.Constexpr[int] = (
                        k_block_offset_bytes * k_block_idx
                    )
                    if prims.elect_sync():
                        prims.tcgen05_mma(
                            prims.Tcgen05MMAKind.F16,
                            prims.CTAGroup.CTA_2,
                            tmem_ptr,
                            desc_a_root.advance_start_address(offset_bytes),
                            desc_b_root.advance_start_address(offset_bytes),
                            idesc,
                            scale_d_first if k_block_idx == 0 else True,
                        )

                if prims.elect_sync():
                    prims.tcgen05_commit(
                        ab_empty_mbar,
                        multicast_mask=ab_empty_mcast_mask,
                        group=prims.CTAGroup.CTA_2,
                    )
            tma_full_phase = tma_full_phase ^ cutlass.Int32(1)

        if is_group_leader:
            if prims.elect_sync():
                prims.tcgen05_commit(
                    acc_done_mbar,
                    multicast_mask=pair_mcast_mask,
                    group=prims.CTAGroup.CTA_2,
                )

    # One-shot output tile: acc_done is sufficient here. Persistent CTA_2
    # reuse of the CTA_2 MMA accumulator needs a separate acc_empty peer-drain
    # barrier before the pair leader MMA warp starts the next work tile.
    prims.barrier_cta_sync(0)
    while not prims.mbarrier_try_wait_parity(
        acc_done_mbar, cutlass.Int32(0), time_limit=10_000_000
    ):
        pass

    tmem_raw_addr = tmem_ptr_i32.load()
    base_col_id = tmem_raw_addr & cutlass.Int32(0xFFFF)
    base_row_id = tmem_raw_addr >> cutlass.Int32(16)

    gC_ptr = mC_mn.iterator.raw_ptr()
    vsize: cutlass.Constexpr[int] = 256 // 16
    subtile_cnt: cutlass.Constexpr[int] = GROUP_TILE_N // 32
    t2r_inst_repx: cutlass.Constexpr[int] = 32
    m_chunk_cnt: cutlass.Constexpr[int] = (CTA_TILE_M + 127) // 128

    for m_chunk in cutlass.range_constexpr(m_chunk_cnt):
        row_base: cutlass.Constexpr[int] = m_chunk * 128
        row_id_with_warp = (
            base_row_id + cutlass.Int32(row_base) + warp_idx * cutlass.Int32(32)
        )
        cur_tmem_col_addr = (row_id_with_warp << cutlass.Int32(16)) | base_col_id

        for subtile_idx in cutlass.range_constexpr(subtile_cnt):
            subtile_col_offset = subtile_idx * 32
            subtile_tmem_addr = cur_tmem_col_addr + cutlass.Int32(subtile_col_offset)
            tmem = cutlass.inttoptr(subtile_tmem_addr, 6, cutlass.Float32)
            c_rmem_vec = prims.tcgen05_ld("32x32b", tmem, num=t2r_inst_repx)
            prims.tcgen05_wait(prims.Tcgen05Wait.LOAD)

            row_in_tile = cutlass.Int32(row_base) + tidx
            if row_in_tile < cutlass.Int32(CTA_TILE_M):
                row = row_in_tile + m_off_cta
                col = n_group_off + cutlass.Int32(subtile_col_offset)
                for j in cutlass.range_constexpr(t2r_inst_repx // vsize):
                    vec_f32 = c_rmem_vec[j * vsize : (j + 1) * vsize]
                    vec_f16 = vec_f32.to(cutlass.Float16)
                    linear_idx = row * mC_mn.shape[1] + col + j * vsize
                    (gC_ptr + linear_idx).store(vec_f16, alignment=16)

    prims.tcgen05_fence(prims.Tcgen05Fence.BEFORE_THREAD_SYNC)
    prims.barrier_cta_sync(0)
    if warp_idx == 0:
        prims.tcgen05_dealloc(tmem_ptr, NUM_TMEM_COLS, group="cta_2")


# ---------------------------------------------------------------------------
# Host launcher
# ---------------------------------------------------------------------------


@cute.jit
def host(
    a: cute.Tensor,
    b: cute.Tensor,
    c: cute.Tensor,
    mnk: Tuple[int, int, int],
    CLUSTER_SHAPE: cutlass.Constexpr,
    CLUSTER_TILE: cutlass.Constexpr,
    GROUP_TILE: cutlass.Constexpr,
) -> None:
    """Build TMA descriptors and launch the CTA_2 multicast kernel."""
    CLUSTER_SX, CLUSTER_SY = CLUSTER_SHAPE
    CLUSTER_TILE_M, CLUSTER_TILE_N, K_TILE = CLUSTER_TILE
    GROUP_TILE_M, GROUP_TILE_N = GROUP_TILE
    CTA_TILE_M: cutlass.Constexpr[int] = GROUP_TILE_M // 2
    CTA_TILE_N: cutlass.Constexpr[int] = GROUP_TILE_N // 2
    A_MCAST_ROWS: cutlass.Constexpr[int] = CTA_TILE_M // CLUSTER_SY
    B_MCAST_ROWS: cutlass.Constexpr[int] = CTA_TILE_N // (CLUSTER_SX // 2)

    tma_a_desc = cuda.create_tensor_map_tiled(
        global_address=a.iterator.toint(),
        dtype=cutlass.Float16,
        global_dims=[a.shape[1], a.shape[0]],
        global_strides=[a.shape[1] * 2 // 16],
        box_dims=[K_TILE, A_MCAST_ROWS],
        swizzle=cuda.TensorMapSwizzle.s128b,
    )
    tma_b_desc = cuda.create_tensor_map_tiled(
        global_address=b.iterator.toint(),
        dtype=cutlass.Float16,
        global_dims=[b.shape[1], b.shape[0]],
        global_strides=[b.shape[1] * 2 // 16],
        box_dims=[K_TILE, B_MCAST_ROWS],
        swizzle=cuda.TensorMapSwizzle.s128b,
    )

    grid_x_super = cute.ceil_div(mnk[0], CLUSTER_TILE_M)
    grid_y_super = cute.ceil_div(mnk[1], CLUSTER_TILE_N)
    kernel(
        tma_a_desc,
        tma_b_desc,
        c,
        mnk[2],
        CLUSTER_SHAPE,
        CLUSTER_TILE,
        GROUP_TILE,
    ).launch(
        grid=(grid_x_super * CLUSTER_SX, grid_y_super * CLUSTER_SY, 1),
        block=(128, 1, 1),
        cluster=(CLUSTER_SX, CLUSTER_SY, 1),
    )


# ---------------------------------------------------------------------------
# Compile factory
# ---------------------------------------------------------------------------


@lru_cache(maxsize=None)
def compile(
    k: int = _DEFAULT_MNK[2],
    CLUSTER_SHAPE: Tuple[int, int] | None = None,
    CLUSTER_TILE: Tuple[int, int] | None = None,
    K_TILE: int = _DEFAULT_K_TILE,
    GROUP_TILE: Tuple[int, int] | None = None,
) -> Callable:
    """AOT-compile keyed on cluster topology.  M and N remain symbolic."""
    cluster_shape, cluster_tile_mn, group_tile = _resolve(
        CLUSTER_SHAPE, CLUSTER_TILE, GROUP_TILE
    )
    _validate(cluster_shape, cluster_tile_mn, K_TILE, group_tile)

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
        cluster_shape,
        cluster_tile,
        group_tile,
        options="--enable-tvm-ffi",
    )


def _resolve(
    CLUSTER_SHAPE: Tuple[int, int] | None,
    CLUSTER_TILE: Tuple[int, int] | None,
    GROUP_TILE: Tuple[int, int] | None,
) -> Tuple[Tuple[int, int], Tuple[int, int], Tuple[int, int]]:
    """Fill defaults and derive the 2D group split for CTA_2 mode."""
    if CLUSTER_SHAPE is None:
        CLUSTER_SHAPE = (2, 2)
    cluster_sx, cluster_sy = CLUSTER_SHAPE
    groups_m = max(1, cluster_sx // 2)
    groups_n = max(1, cluster_sy)
    if GROUP_TILE is None:
        cta_tile_m = _round_up(_MIN_CTA_TILE_M, lcm(16, groups_n))
        cta_tile_n = _round_up(_MIN_CTA_TILE_N, lcm(32, groups_m))
        GROUP_TILE = (2 * cta_tile_m, 2 * cta_tile_n)
    group_tile_m, group_tile_n = GROUP_TILE
    if CLUSTER_TILE is None:
        CLUSTER_TILE = (group_tile_m * groups_m, group_tile_n * groups_n)
    return tuple(CLUSTER_SHAPE), tuple(CLUSTER_TILE), tuple(GROUP_TILE)


def _round_up(value: int, multiple: int) -> int:
    """Return ``value`` rounded up to the next ``multiple``."""
    return ((value + multiple - 1) // multiple) * multiple


def _is_power_of_two(value: int) -> bool:
    """Return whether ``value`` is a positive power of two."""
    return value > 0 and value & (value - 1) == 0


def _validate(
    CLUSTER_SHAPE: Tuple[int, int],
    CLUSTER_TILE_MN: Tuple[int, int],
    K_TILE: int,
    GROUP_TILE: Tuple[int, int],
) -> None:
    """Validate static CTA_2 launch, group split, and tile invariants."""
    cluster_sx, cluster_sy = CLUSTER_SHAPE
    cluster_size = cluster_sx * cluster_sy
    if cluster_sx <= 0 or cluster_sy <= 0:
        raise ValueError(f"CLUSTER_SHAPE values must be positive; got {CLUSTER_SHAPE}")
    if cluster_size > 16:
        raise ValueError(
            f"cluster_size CLUSTER_SX*CLUSTER_SY={cluster_size} must be <= 16"
        )
    if not _is_power_of_two(cluster_size):
        raise ValueError(
            f"cluster_size CLUSTER_SX*CLUSTER_SY={cluster_size} must be a power of two"
        )
    if cluster_size % 2 != 0:
        raise ValueError(f"CTA_2 requires an even cluster_size; got {cluster_size}")
    if cluster_sx % 2 != 0:
        raise ValueError(
            f"CTA_2 pair ranks use the rank LSB, so CLUSTER_SX must be even; got {CLUSTER_SHAPE}"
        )

    cluster_tile_m, cluster_tile_n = CLUSTER_TILE_MN
    group_tile_m, group_tile_n = GROUP_TILE
    if group_tile_m % 2 != 0:
        raise ValueError(f"GROUP_TILE[0]={group_tile_m} must be divisible by 2")
    if group_tile_n % 2 != 0:
        raise ValueError(f"GROUP_TILE[1]={group_tile_n} must be divisible by 2")
    cta_tile_m = group_tile_m // 2
    cta_tile_n = group_tile_n // 2
    if cta_tile_m < _MIN_CTA_TILE_M:
        raise ValueError(f"CTA_TILE_M={cta_tile_m} must be at least {_MIN_CTA_TILE_M}")
    if group_tile_m > _MAX_DENSE_M_DIM:
        raise ValueError(
            f"GROUP_TILE[0]={group_tile_m} must be <= dense tcgen05 m_dim max {_MAX_DENSE_M_DIM}"
        )
    if cta_tile_m % 16 != 0:
        raise ValueError(f"CTA_TILE_M={cta_tile_m} must be a multiple of 16")
    if group_tile_n > _MAX_DENSE_N_DIM:
        raise ValueError(
            f"GROUP_TILE[1]={group_tile_n} must be <= dense tcgen05 n_dim max {_MAX_DENSE_N_DIM}"
        )
    if cta_tile_n % 32 != 0:
        raise ValueError(f"CTA_TILE_N={cta_tile_n} must be a multiple of 32")
    if cluster_tile_m % group_tile_m != 0:
        raise ValueError(
            f"CLUSTER_TILE[0]={cluster_tile_m} must be divisible by GROUP_TILE[0]={group_tile_m}"
        )
    if cluster_tile_n % group_tile_n != 0:
        raise ValueError(
            f"CLUSTER_TILE[1]={cluster_tile_n} must be divisible by GROUP_TILE[1]={group_tile_n}"
        )
    groups_m = cluster_tile_m // group_tile_m
    groups_n = cluster_tile_n // group_tile_n
    n_groups = cluster_size // 2
    if groups_m * groups_n != n_groups:
        raise ValueError(
            f"GROUPS_M*GROUPS_N={groups_m * groups_n} must equal "
            f"cluster_size/2={n_groups}; got CLUSTER_TILE={CLUSTER_TILE_MN}, "
            f"GROUP_TILE={GROUP_TILE}"
        )
    if groups_m != cluster_sx // 2 or groups_n != cluster_sy:
        raise ValueError(
            f"Physical CTA_2 MxN mapping requires GROUPS_M=CLUSTER_SX/2 and "
            f"GROUPS_N=CLUSTER_SY; got GROUPS_M={groups_m}, GROUPS_N={groups_n}, "
            f"CLUSTER_SHAPE={CLUSTER_SHAPE}"
        )
    if cta_tile_m % cluster_sy != 0:
        raise ValueError(
            f"CTA_TILE_M={cta_tile_m} must be divisible by CLUSTER_SY={cluster_sy} "
            "so A multicast shards assemble a complete lane-local tile"
        )
    if cta_tile_n % (cluster_sx // 2) != 0:
        raise ValueError(
            f"CTA_TILE_N={cta_tile_n} must be divisible by CLUSTER_SX/2={cluster_sx // 2} "
            "so B multicast shards assemble a complete lane-local tile"
        )
    a_mcast_rows = cta_tile_m // cluster_sy
    b_mcast_rows = cta_tile_n // (cluster_sx // 2)
    if a_mcast_rows > _MAX_TMA_BOX_DIM:
        raise ValueError(
            f"A multicast shard rows={a_mcast_rows} must be <= TMA box dim max {_MAX_TMA_BOX_DIM}"
        )
    if b_mcast_rows > _MAX_TMA_BOX_DIM:
        raise ValueError(
            f"B multicast shard rows={b_mcast_rows} must be <= TMA box dim max {_MAX_TMA_BOX_DIM}"
        )
    if K_TILE % MMA_K_GRANULE != 0:
        raise ValueError(
            f"K_TILE={K_TILE} must be a multiple of MMA_K_GRANULE={MMA_K_GRANULE}"
        )
    if K_TILE > _MAX_TMA_BOX_DIM:
        raise ValueError(
            f"K_TILE={K_TILE} must be <= TMA box dim max {_MAX_TMA_BOX_DIM}"
        )


# ---------------------------------------------------------------------------
# Run
# ---------------------------------------------------------------------------


def run(
    compiled_fn: Callable,
    mnk: Tuple[int, int, int] = _DEFAULT_MNK,
    *,
    CLUSTER_SHAPE: Tuple[int, int] | None = None,
    CLUSTER_TILE: Tuple[int, int] | None = None,
    K_TILE: int = _DEFAULT_K_TILE,
    GROUP_TILE: Tuple[int, int] | None = None,
    seed: int = 42,
) -> tuple[torch.Tensor, torch.Tensor]:
    """Allocate tensors, run the kernel, and return ``(output, reference)``."""
    if not torch.cuda.is_available():
        raise RuntimeError("CUDA GPU required")

    cluster_shape, cluster_tile_mn, group_tile = _resolve(
        CLUSTER_SHAPE, CLUSTER_TILE, GROUP_TILE
    )
    _validate(cluster_shape, cluster_tile_mn, K_TILE, group_tile)
    m, n, k = mnk
    if m % cluster_tile_mn[0] != 0:
        raise ValueError(
            f"M={m} must be a multiple of CLUSTER_TILE_M={cluster_tile_mn[0]}"
        )
    if n % cluster_tile_mn[1] != 0:
        raise ValueError(
            f"N={n} must be a multiple of CLUSTER_TILE_N={cluster_tile_mn[1]}"
        )
    if k % K_TILE != 0:
        raise ValueError(f"K={k} must be a multiple of K_TILE={K_TILE}")

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


# ---------------------------------------------------------------------------
# Verify
# ---------------------------------------------------------------------------


def verify(
    mnk: Tuple[int, int, int] = _DEFAULT_MNK,
    *,
    CLUSTER_SHAPE: Tuple[int, int] | None = None,
    CLUSTER_TILE: Tuple[int, int] | None = None,
    K_TILE: int = _DEFAULT_K_TILE,
    GROUP_TILE: Tuple[int, int] | None = None,
    tolerance: float = 0.1,
) -> None:
    """Compile, run, and compare against torch matmul."""
    compiled_fn = compile(
        k=mnk[2],
        CLUSTER_SHAPE=CLUSTER_SHAPE,
        CLUSTER_TILE=CLUSTER_TILE,
        K_TILE=K_TILE,
        GROUP_TILE=GROUP_TILE,
    )
    c, ref = run(
        compiled_fn,
        mnk,
        CLUSTER_SHAPE=CLUSTER_SHAPE,
        CLUSTER_TILE=CLUSTER_TILE,
        K_TILE=K_TILE,
        GROUP_TILE=GROUP_TILE,
    )
    torch.testing.assert_close(c, ref, atol=tolerance, rtol=1e-5)
    print("PASS")


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument(
        "--mnk", type=str, default=",".join(str(x) for x in _DEFAULT_MNK)
    )
    parser.add_argument("--CLUSTER_SHAPE", type=str, default=None)
    parser.add_argument("--CLUSTER_TILE", type=str, default=None)
    parser.add_argument("--K_TILE", type=int, default=_DEFAULT_K_TILE)
    parser.add_argument("--GROUP_TILE", type=str, default=None)
    parser.add_argument("--tolerance", type=float, default=0.1)
    args = parser.parse_args()

    mnk = tuple(int(x) for x in args.mnk.split(","))
    cluster_shape = (
        tuple(int(x) for x in args.CLUSTER_SHAPE.split(","))
        if args.CLUSTER_SHAPE
        else None
    )
    cluster_tile = (
        tuple(int(x) for x in args.CLUSTER_TILE.split(","))
        if args.CLUSTER_TILE
        else None
    )
    group_tile = (
        tuple(int(x) for x in args.GROUP_TILE.split(",")) if args.GROUP_TILE else None
    )
    verify(
        mnk,
        CLUSTER_SHAPE=cluster_shape,
        CLUSTER_TILE=cluster_tile,
        K_TILE=args.K_TILE,
        GROUP_TILE=group_tile,
        tolerance=args.tolerance,
    )
