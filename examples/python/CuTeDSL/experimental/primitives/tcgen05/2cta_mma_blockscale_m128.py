# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

"""CTA_2 NVFP4 block-scaled MMA, collective M=128 / 2x2 accumulator mapping.

This direct CUTLASS primitives/tcgen05 example covers the CTA_2 block-scaled shape
that the tutorial GEMMs do not: collective M=128, so each CTA owns
64 M rows. It focuses on the 2x2 accumulator data mapping and
scale-factor placement: B data is N-split across CTAs, SFB stays full
per CTA, and SFA starts from one 128-row collective-M scale atom. Each
CTA packs only the 64-row SFA sub-atom for its local M-half with per-thread copies,
then UTCCP copies that packed SMEM image to TMEM. SFB uses TMA into an
N=256 SMEM image, then the MMA warp issues the
``S2T_64x128b_WARPX2_01_23`` UTCCP variant to populate the 2x2 SFB TMEM
layout directly. The epilogue only direct-stores FP16 C.

Usage::

    python CuTeDSL/experimental/primitives/tcgen05/2cta_mma_blockscale_m128.py --mnk 128,256,256

"""

from __future__ import annotations

import argparse
from collections.abc import Callable
from functools import lru_cache

import cuda.bindings.driver as cuda_driver

import torch


import cutlass
import cutlass.experimental.cuda as cuda
import cutlass.cute as cute
import cutlass.utils as utils
import cutlass.torch as cutlass_torch
from cutlass.cute.runtime import from_dlpack, make_ptr
from cutlass.experimental import primitives as prims


# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

# Data types.
a_dtype = cutlass.Float4E2M1FN
b_dtype = cutlass.Float4E2M1FN
sf_dtype = cutlass.Float8E4M3FN
torch_sf_dtype = torch.float8_e4m3fn
c_dtype = cutlass.Float16

# NVFP4 block-scaling atom geometry.
num_m0_per_sf_atom = 32
num_m1_per_sf_atom = 4
num_k_per_sf_atom = 4
sf_vec_size = 16
num_elts_atom_sf_e8 = num_m0_per_sf_atom * num_m1_per_sf_atom * num_k_per_sf_atom  # 512
num_elts_atom_sf_u16 = num_elts_atom_sf_e8 // 2  # 256
num_tmem_cols_per_sf_atom = 4

# Kernel resource configuration.
SMEM_CAPACITY = utils.get_smem_capacity_in_bytes("sm_100")
NUM_MBAR_BYTES = 1024
NUM_TMEM_ALLOC_COLS = 512

# tcgen05.mma.block_scale per-instruction K granule for NVFP4 = 64 elements.
MMA_K_GRANULE: int = 64
K_TILE = 256

# Cluster: 2 CTAs in M, 1 in N — single 2-SM group.
CLUSTER_SX, CLUSTER_SY = 2, 1

# Cluster / group / per-CTA tile dims.
CLUSTER_TILE_M = 128
CLUSTER_TILE_N = 256
GROUP_TILE_M = CLUSTER_TILE_M
GROUP_TILE_N = CLUSTER_TILE_N
CTA_TILE_M = GROUP_TILE_M // CLUSTER_SX  # 64 — 2 CTAs split M
CTA_TILE_N = GROUP_TILE_N // CLUSTER_SX  # 128 — B data is N-split across the pair

# MMA tile config: cluster total. mma_inst is also cluster total because
# tcgen05_mma.cta_group::2 covers the cluster's MN per instruction.
mma_tiler_mnk = (GROUP_TILE_M, GROUP_TILE_N, K_TILE)
mma_inst_mnk = (GROUP_TILE_M, GROUP_TILE_N, MMA_K_GRANULE)

# Warp specialization: 9 warps per CTA.
# (4 epilog + MMA + TMA-AB + SFA async copy + sync + TMA-SFB).
epilog_warp_id = (0, 1, 2, 3)
mma_warp_id = 4
tma_warp_id = 5  # A + B TMA
async_sfa_warp_id = 6
sync_warp_id = 7
tma_sfb_warp_id = 8  # SFB TMA
_THREADS = 288  # block=(288, 1, 1) — 9 warps per CTA

DEFAULT_MNK = (GROUP_TILE_M, GROUP_TILE_N, K_TILE)


# ---------------------------------------------------------------------------
# Host function
# ---------------------------------------------------------------------------


@cute.jit
def gemm(
    a_tensor: cute.Tensor,
    b_tensor: cute.Tensor,
    sfa_tensor: cute.Tensor,
    sfb_tensor: cute.Tensor,
    c_tensor: cute.Tensor,
    problem_size: tuple,
    stream: cuda_driver.CUstream,
) -> None:
    """Host-side JIT: build TMA descriptors and launch the 2CTA kernel.

    Args:
        a_tensor: Weight (K, M), FP4 E2M1 (Int8 in TVM-FFI flow, packed 2 per byte).
        b_tensor: Activation (K, N), FP4 E2M1 (Int8 in TVM-FFI flow, packed 2 per byte).
        sfa_tensor: A scale factors (512, K//64, M//128), E4M3.
        sfb_tensor: B scale factors (512, K//64, N//128), E4M3.
        c_tensor: Row-major FP16 output, logical shape (M, N).
        problem_size: (M, N, K).
        stream: CUDA stream.
    """
    # Recast the byte-backed tensors to packed FP4 for TMA descriptor creation.
    fp4_a_ptr = cute.make_ptr(
        a_dtype, a_tensor.iterator.raw_ptr(), mem_space=cutlass.AddressSpace.gmem
    )
    a_tensor = cute.make_tensor(fp4_a_ptr, a_tensor.layout)
    fp4_b_ptr = cute.make_ptr(
        b_dtype, b_tensor.iterator.raw_ptr(), mem_space=cutlass.AddressSpace.gmem
    )
    b_tensor = cute.make_tensor(fp4_b_ptr, b_tensor.layout)
    sfa_ptr = sfa_tensor.iterator.raw_ptr()  # raw pointer for SFA copy arithmetic

    # A/B use TMA. SFA takes the per-thread copy path to repack the local 64-row M-half;
    # SFB uses full collective-N=256 TMA even though B data is N-split.
    tma_a_desc = cuda.create_tensor_map_tiled_from_view(
        a_tensor,
        box_dims=(K_TILE, CTA_TILE_M),
        stride_order=(0, 1),
        swizzle=cuda.TensorMapSwizzle.s128b,
        tma_format=cuda.TensorMapDataFormat.B4X16,
    )
    tma_b_desc = cuda.create_tensor_map_tiled_from_view(
        b_tensor,
        box_dims=(K_TILE, CTA_TILE_N),
        stride_order=(0, 1),
        swizzle=cuda.TensorMapSwizzle.s128b,
        tma_format=cuda.TensorMapDataFormat.B4X16,
    )
    # SF atom counts use cluster-total M/N, not per-CTA M/N.
    sf_atom_mn = num_m0_per_sf_atom * num_m1_per_sf_atom  # 128
    sf_atom_k = num_k_per_sf_atom * sf_vec_size  # 64
    rest_k_sf_per_ktile = max(1, mma_tiler_mnk[2] // sf_atom_k)
    rest_m_sf_per_ktile = max(1, mma_tiler_mnk[0] // sf_atom_mn)
    rest_n_sf_per_ktile = max(1, mma_tiler_mnk[1] // sf_atom_mn)
    rest_k_sf_total = cute.ceil_div(problem_size[2], sf_atom_k)
    rest_n_sf_total = cute.ceil_div(problem_size[1], sf_atom_mn)

    # SFB arrives in the same CUTE 6D scale-factor tensor layout as the NVFP4
    # tutorial examples. Reinterpret its storage as the flat atom-major u16
    # view used by TMA: (256 u16 per atom, total rest_n, total rest_k).  The
    # N-before-K view makes the two N=128 atoms for one K block adjacent in
    # SMEM, which is the 1024B source image consumed by 64x128b UTCCP.
    sfb_flat_layout_u16 = cute.make_layout(
        (num_elts_atom_sf_u16, rest_n_sf_total, rest_k_sf_total),
        stride=(
            1,
            num_elts_atom_sf_u16 * rest_k_sf_total,
            num_elts_atom_sf_u16,
        ),
    )
    sfb_tensor_u16 = cute.make_tensor(
        cute.recast_ptr(sfb_tensor.iterator, dtype=cutlass.Uint16),
        sfb_flat_layout_u16,
    )
    tma_sfb_desc = cuda.create_tensor_map_tiled_from_view(
        sfb_tensor_u16,
        box_dims=(num_elts_atom_sf_u16, rest_n_sf_per_ktile, rest_k_sf_per_ktile),
        stride_order=(0, 1, 2),
        swizzle=cuda.TensorMapSwizzle.none,
    )

    num_bytes_a_smem_per_cta = CTA_TILE_M * K_TILE * a_dtype.width // 8
    num_bytes_b_smem_per_cta = CTA_TILE_N * K_TILE * b_dtype.width // 8
    # SFA lane packing for UTCCP:
    # A full NVFP4 scale-factor atom is lane-local 32m x (4k x 4m),
    # so each lane owns 16 B. That 16 B lane slot is the 128b in
    # S2T_32x128b_WARPX4. In this CTA_2 collective-M=128 shape, each CTA
    # owns only half of the m dimension in the atom:
    #   CTA 0: m1={0,1} -> lane-local 4k x 2m = 8 B
    #   CTA 1: m1={2,3} -> lane-local 4k x 2m = 8 B
    # Copying one local half alone would leave half of the UTCCP lane slot
    # empty. Instead, each CTA packs two adjacent 4k scale slices along K into
    # one 16 B lane slot:
    #
    #   SMEM pair p, lane i, 16 B slot
    #   +----------------------+----------------------+
    #   | r_k = 2p            | r_k = 2p+1          |
    #   | 4k x 2m local half  | 4k x 2m local half  |
    #   | low 8 B             | high 8 B            |
    #   +----------------------+----------------------+
    #
    # The packed slot has shape 32m x ((4k x 2m) x 2 r_k positions), filling
    # the same 512 B footprint as one normal 32m x (4k x 4m) atom image.
    num_bytes_sfa = (
        num_elts_atom_sf_e8
        * rest_k_sf_per_ktile
        * rest_m_sf_per_ktile
        * sf_dtype.width
        // 8
        // 2  # two 4k x 2m slices share each lane's 16 B UTCCP slot
    )
    # Fixed cluster-N=256 SFB SMEM layout: every CTA TMA-loads both 128-N
    # scale atoms. This intentionally differs from B data, which is N-split.
    num_bytes_sfb = (
        num_elts_atom_sf_e8
        * rest_k_sf_per_ktile
        * rest_n_sf_per_ktile
        * sf_dtype.width
        // 8
    )
    per_stage_bytes = (
        num_bytes_a_smem_per_cta
        + num_bytes_b_smem_per_cta
        + num_bytes_sfa
        + num_bytes_sfb
    )
    num_ab_stage = (SMEM_CAPACITY - NUM_MBAR_BYTES) // per_stage_bytes
    num_ab_stage = max(num_ab_stage, 2)

    total_smem = NUM_MBAR_BYTES + num_ab_stage * per_stage_bytes
    assert total_smem <= SMEM_CAPACITY, (
        f"SMEM overflow: {total_smem}B > capacity {SMEM_CAPACITY}B"
        f" (num_ab_stage={num_ab_stage})"
    )

    # ACC TMEM for the 2x2 accumulator mapping. Each CTA represents a logical
    # 64M x cluster_n C tile, but N is folded into two N-half row stripes:
    # rows 0..63 cover the low N half, and rows 64..127 cover the high N half.
    # So ACC consumes 128 TMEM rows x (cluster_n / 2) physical TMEM columns.
    acc_tmem_cols = CLUSTER_TILE_N // CLUSTER_SX

    # Scale-factor TMEM columns are determined by what each transfer writes.
    # SFA counts packed UTCCP images, not standalone 4k scale slices: two local
    # 8 B/lane halves along K fill one 16 B/lane image, and that image writes
    # one 4-column SFA TMEM record:
    #   [r_k=2p 4k x 2m][r_k=2p+1 4k x 2m]
    # Hence per-stage SFA TMEM columns are 4 * (rest_k * rest_m / 2).
    sfa_tmem_cols = (
        rest_k_sf_per_ktile * rest_m_sf_per_ktile // 2
    ) * num_tmem_cols_per_sf_atom
    # SFB uses the N=256 2x2 UTCCP form. One 64x128b.warpx2::01_23 copy reads
    # two adjacent 128-N SFB atoms for one K-SF block (1024B) and writes a
    # 128-row x 4-column TMEM image. The four columns cover the N=256
    # scale-factor groups consumed by one 64-wide MMA K block.
    sfb_tmem_cols_per_atom = num_tmem_cols_per_sf_atom
    sfb_tmem_cols_per_stage = rest_k_sf_per_ktile * sfb_tmem_cols_per_atom
    # SFB TMEM is staged across num_ab_stage to avoid overwriting SFB TMEM for
    # one K tile while the MMA is still reading it.
    sfb_tmem_cols = sfb_tmem_cols_per_stage * num_ab_stage
    tmem_needed = acc_tmem_cols + sfa_tmem_cols + sfb_tmem_cols
    assert tmem_needed <= NUM_TMEM_ALLOC_COLS, (
        f"TMEM overflow: need {tmem_needed} cols > {NUM_TMEM_ALLOC_COLS}"
    )

    # mbar budget
    #   per-stage: ab_full, ab_empty, a_local, sfb_smem_full (= 4 mbars/stage)
    #   global: acc_full, tmem_dealloc (= 2 mbars)
    mbar_count = num_ab_stage * 4 + 2
    mbar_bytes_used = 8 * mbar_count + 4
    assert mbar_bytes_used <= NUM_MBAR_BYTES, (
        f"mbar overflow: {mbar_bytes_used}B > reserved {NUM_MBAR_BYTES}B"
    )

    grid = (
        CLUSTER_SX * cute.ceil_div(problem_size[0], GROUP_TILE_M),
        CLUSTER_SY * cute.ceil_div(problem_size[1], CLUSTER_TILE_N),
        1,
    )

    kernel(
        tma_a_desc,
        tma_b_desc,
        tma_sfb_desc,
        c_tensor,
        sfa_ptr,
        problem_size,
        mma_tiler_mnk,
        mma_inst_mnk,
        num_bytes_a_smem_per_cta,
        num_bytes_b_smem_per_cta,
        num_bytes_sfa,
        num_bytes_sfb,
        num_ab_stage,
        rest_k_sf_per_ktile,
        rest_m_sf_per_ktile,
        rest_n_sf_per_ktile,
    ).launch(
        grid=grid,
        block=[_THREADS, 1, 1],
        cluster=(CLUSTER_SX, CLUSTER_SY, 1),
        min_blocks_per_mp=1,
        stream=stream,
    )
    return


# ---------------------------------------------------------------------------
# CUDA kernel
# ---------------------------------------------------------------------------


@cute.jit
def wait_if_peek_failed(peek_ready, mbar_ptr: cutlass.Pointer, phase_bit) -> None:
    """Block on ``mbar_ptr`` only when the carried TRY peek missed."""
    if not peek_ready:
        while not prims.mbarrier_try_wait_parity(
            mbar_ptr, phase_bit, time_limit=10_000_000
        ):
            pass


@cute.jit
def peek_next_k_tile_mbarrier(
    mbar_ptr: cutlass.Pointer,
    phase_bit,
    k_tile_idx,
    k_tile_cnt,
    num_stages: cutlass.Constexpr[int],
):
    """TRY-peek the next K-tile stage/phase; last iteration returns ready."""
    peek_ready = cutlass.Boolean(1)
    if k_tile_idx + 1 < k_tile_cnt:
        next_stage = (k_tile_idx + 1) % num_stages
        next_phase = phase_bit
        if next_stage == 0:
            next_phase = phase_bit ^ 1
        peek_ready = prims.mbarrier_wait_parity(
            mbar_ptr.subview(next_stage),
            next_phase,
            prims.MBarrierWait.TRY,
        )
    return peek_ready


@cute.kernel
def kernel(
    tma_a_desc: cutlass.GridConstant[cuda.TensorMap],
    tma_b_desc: cutlass.GridConstant[cuda.TensorMap],
    tma_sfb_desc: cutlass.GridConstant[cuda.TensorMap],
    c_tensor: cute.Tensor,
    sfa_ptr: cutlass.Pointer,
    problem_size: tuple,
    mma_tiler_mnk: cutlass.Constexpr[tuple[int, int, int]],
    mma_inst_mnk: cutlass.Constexpr[tuple[int, int, int]],
    num_bytes_a_smem_per_cta: cutlass.Constexpr[int],
    num_bytes_b_smem_per_cta: cutlass.Constexpr[int],
    num_bytes_sfa: cutlass.Constexpr[int],
    num_bytes_sfb: cutlass.Constexpr[int],
    num_ab_stage: cutlass.Constexpr[int],
    rest_k_sf_per_ktile: cutlass.Constexpr[int],
    rest_m_sf_per_ktile: cutlass.Constexpr[int],
    rest_n_sf_per_ktile: cutlass.Constexpr[int],
) -> None:
    """2CTA NVFP4×NVFP4 kernel — collective-M=128 2x2 datapath.

    Warp layout (9 warps x 32 = 288 threads):
      0..3 : epilog (m_stripe, n_stripe ∈ {0,1})
      4    : MMA + S2T (leader-only body; both CTAs cooperatively alloc)
      5    : TMA loads (A, B)
      6    : SFA per-CTA M-half gather
      7    : Sync relay (a_local → leader's ab_full[stage])
      8    : SFB TMA load
    """
    warp_idx = cute.arch.warp_idx()
    tidx, _, _ = cute.arch.thread_idx()
    bidx, bidy, _ = cute.arch.block_idx()
    m, n, k = problem_size

    # Cluster decomposition. cta_rank ∈ {0, 1} (CLUSTER_SX=2, CLUSTER_SY=1).
    cta_rank = cute.arch.block_idx_in_cluster()
    is_leader_cta = cta_rank == 0

    # Tile coords — cluster idx along x = bidx // CLUSTER_SX.
    tile_coord_m = bidx // CLUSTER_SX
    tile_coord_n = bidy

    tile_m: cutlass.Constexpr[int] = mma_tiler_mnk[0]  # cluster M
    cluster_tile_n: cutlass.Constexpr[int] = mma_tiler_mnk[1]  # cluster N
    tile_n_per_cta: cutlass.Constexpr[int] = cluster_tile_n // CLUSTER_SX
    cluster_tile_k: cutlass.Constexpr[int] = mma_tiler_mnk[2]
    tile_m_per_cta: cutlass.Constexpr[int] = tile_m // CLUSTER_SX  # 64
    # SFB TMEM is ring-buffered by stage. For N=256, one 64x128b.warpx2::01_23
    # UTCCP writes four TMEM columns per 64-wide MMA K block.
    sfb_tmem_cols_per_atom: cutlass.Constexpr[int] = num_tmem_cols_per_sf_atom
    sfb_tmem_cols_per_stage: cutlass.Constexpr[int] = (
        rest_k_sf_per_ktile * sfb_tmem_cols_per_atom
    )

    # ---------------------------------------------------------------------
    # SMEM allocations. Mbarriers come first, then num_ab_stage-deep ring
    # buffers for A, B, SFA, and SFB.
    # ---------------------------------------------------------------------
    ab_full_mbar_ptr = cutlass.Array(
        cutlass.Int64, num_ab_stage, space=cutlass.AddressSpace.smem, alignment=8
    )
    ab_empty_mbar_ptr = cutlass.Array(
        cutlass.Int64, num_ab_stage, space=cutlass.AddressSpace.smem, alignment=8
    )
    acc_full_mbar_ptr = cutlass.Array(
        cutlass.Int64, 1, space=cutlass.AddressSpace.smem, alignment=8
    )
    a_local_mbar_ptr = cutlass.Array(
        cutlass.Int64, num_ab_stage, space=cutlass.AddressSpace.smem, alignment=8
    )
    # SFB uses a separate TMA mbarrier. The MMA warp waits for SFB in SMEM,
    # issues UTCCP to TMEM, then the normal ab_empty commit releases the
    # shared stage after both UTCCP and MMA have drained it.
    sfb_smem_full_mbar_ptr = cutlass.Array(
        cutlass.Int64, num_ab_stage, space=cutlass.AddressSpace.smem, alignment=8
    )
    tmem_dealloc_mbar_ptr = cutlass.Array(
        cutlass.Int64, 1, space=cutlass.AddressSpace.smem, alignment=8
    )
    tmem_ptr_i32 = cutlass.Array(
        cutlass.Int32, 1, space=cutlass.AddressSpace.smem, alignment=4
    )

    sA = cutlass.Array(
        cutlass.Int8,
        num_bytes_a_smem_per_cta * num_ab_stage,
        space=cutlass.AddressSpace.smem,
        alignment=1024,
    )
    sB = cutlass.Array(
        cutlass.Int8,
        num_bytes_b_smem_per_cta * num_ab_stage,
        space=cutlass.AddressSpace.smem,
        alignment=1024,
    )
    sSFA = cutlass.Array(
        cutlass.Int8,
        num_bytes_sfa * num_ab_stage,
        space=cutlass.AddressSpace.smem,
        alignment=512,
    )
    sSFB = cutlass.Array(
        cutlass.Int8,
        num_bytes_sfb * num_ab_stage,
        space=cutlass.AddressSpace.smem,
        alignment=512,
    )

    # TX-byte budget.
    # ab_full: cooperative cta_group::2 TMA for A + B (SFA via per-thread copy;
    # SFB to its own sfb_smem_full mbar). In cta_group::2 mode the leader
    # mbar tracks TX bytes for both CTAs in the M-pair.
    num_tma_load_bytes_ab = (
        tma_a_desc.global_tx_bytes() + tma_b_desc.global_tx_bytes()
    ) * CLUSTER_SX
    # sfb_smem_full: SFB TMA uses cta_group::CTA_1 (per-CTA, not cooperative)
    # so each CTA's local mbar tracks exactly its own SFB bytes. The leader
    # MMA warp waits on its local SFB before issuing CTA_2 UTCCP.
    num_tma_load_bytes_sfb = tma_sfb_desc.global_tx_bytes()

    k_tile_cnt = cute.ceil_div(k, cluster_tile_k)

    # Sync barrier IDs (within-CTA HW barriers).
    tmem_bar_id = 1
    tmem_bar_threads = 32 * len((mma_warp_id, *epilog_warp_id))
    epilog_dealloc_bar_id = 3  # 4 epilog warps for TMEM dealloc handshake

    # Lane-parallel mbarrier init keeps setup cheap. The local barrier orders
    # per-CTA initialization before the cluster barrier exposes cross-CTA mbars.
    if warp_idx < 5:
        lane_id_init = tidx % 32
        # Warp 0: ab_full. Count = 1 (TMA expect_tx) + 2 (sync-relay arrives,
        # one per CTA in the M-pair) = 3 per stage.
        if warp_idx == 0:
            for i in range((num_ab_stage + 31) // 32):
                idx = i * 32 + lane_id_init
                if idx < num_ab_stage:
                    prims.mbarrier_init(ab_full_mbar_ptr.subview(idx), 3)
        # Warp 1: ab_empty.
        if warp_idx == 1:
            for i in range((num_ab_stage + 31) // 32):
                idx = i * 32 + lane_id_init
                if idx < num_ab_stage:
                    prims.mbarrier_init(ab_empty_mbar_ptr.subview(idx), 1)
        # Warp 2: a_local (32 SFA-copy lanes arrive once per K-tile).
        if warp_idx == 2:
            for i in range((num_ab_stage + 31) // 32):
                idx = i * 32 + lane_id_init
                if idx < num_ab_stage:
                    prims.mbarrier_init(a_local_mbar_ptr.subview(idx), 32)
        # Warp 3: sfb_smem_full. Fixed-N example: one TMA completion.
        if warp_idx == 3:
            for i in range((num_ab_stage + 31) // 32):
                idx = i * 32 + lane_id_init
                if idx < num_ab_stage:
                    prims.mbarrier_init(sfb_smem_full_mbar_ptr.subview(idx), 1)
        # Warp 4: globals (acc_full, tmem_dealloc). Single thread.
        if warp_idx == 4:
            if prims.elect_sync():
                prims.mbarrier_init(acc_full_mbar_ptr, 1)
                prims.mbarrier_init(tmem_dealloc_mbar_ptr, 32)
    prims.fence_mbarrier_init()
    prims.barrier_cta_sync(0)
    prims.barrier_cluster_arrive_relaxed()
    prims.barrier_cluster_wait()

    ab_mbar_empty_phase_bit = 1
    ab_mbar_full_phase_bit = 0
    # Tile coordinates in GMEM (cluster total).
    coord_m_cluster = tile_coord_m * tile_m
    coord_n_cluster = tile_coord_n * cluster_tile_n
    coord_m_per_cta = coord_m_cluster + cta_rank * tile_m_per_cta
    coord_n_per_cta = coord_n_cluster + cta_rank * tile_n_per_cta
    # SF atom coords (cluster M / cluster N — atoms shared across M-pair).
    coord_m_sf = coord_m_cluster // (num_m0_per_sf_atom * num_m1_per_sf_atom)
    coord_n_sf = coord_n_cluster // (num_m0_per_sf_atom * num_m1_per_sf_atom)

    # Warp 5: CTA_2 TMA loads each CTA's local A/B half; the leader mbar counts
    # the pair's TX-byte completions.
    if warp_idx == tma_warp_id:
        # Peek next stage at loop tail; block only if that TRY missed.
        peek_ab_empty = prims.mbarrier_wait_parity(
            ab_empty_mbar_ptr, ab_mbar_empty_phase_bit, prims.MBarrierWait.TRY
        )
        for k_tile_idx in cutlass.range(k_tile_cnt, unroll=1):
            stage = k_tile_idx % num_ab_stage
            if stage == 0 and k_tile_idx != 0:
                ab_mbar_empty_phase_bit = ab_mbar_empty_phase_bit ^ 1
            wait_if_peek_failed(
                peek_ab_empty, ab_empty_mbar_ptr.subview(stage), ab_mbar_empty_phase_bit
            )

            if is_leader_cta and prims.elect_sync():
                prims.mbarrier_arrive_expect_tx(
                    ab_full_mbar_ptr.subview(stage), num_tma_load_bytes_ab
                )

            coord_k = k_tile_idx * cluster_tile_k
            sA_staged = sA.subview(num_bytes_a_smem_per_cta * stage)
            sB_staged = sB.subview(num_bytes_b_smem_per_cta * stage)

            if prims.elect_sync():
                prims.cp_async_bulk_tensor_shared_cluster_global(
                    sA_staged,
                    tma_a_desc.get_ptr(),
                    (coord_k, coord_m_per_cta),
                    ab_full_mbar_ptr.subview(stage),
                    [],
                    group=prims.CTAGroup.CTA_2,
                )
                prims.cp_async_bulk_tensor_shared_cluster_global(
                    sB_staged,
                    tma_b_desc.get_ptr(),
                    (coord_k, coord_n_per_cta),
                    ab_full_mbar_ptr.subview(stage),
                    [],
                    group=prims.CTAGroup.CTA_2,
                )

            peek_ab_empty = peek_next_k_tile_mbarrier(
                ab_empty_mbar_ptr,
                ab_mbar_empty_phase_bit,
                k_tile_idx,
                k_tile_cnt,
                num_ab_stage,
            )

    # Warp 6: per-CTA M-half SFA gather with per-thread copies, packed into the
    # first or second 8-byte half of each lane's 16-byte SMEM slot.
    #   GMEM offset = base + r_k*512 + lane*16 + cta_rank*8
    #   SMEM offset = stage*atom_size + r_k*512 + lane*16 + 0  (PACKED)
    if warp_idx == async_sfa_warp_id:
        lane = tidx % 32
        gmem_in_atom_off = cta_rank * 8
        rest_k_sf_total = cute.ceil_div(k, num_k_per_sf_atom * sf_vec_size)
        gmem_l_m_base = sfa_ptr + coord_m_sf * rest_k_sf_total * 512

        async_sfa_empty_phase_bit = 1
        peek_ab_empty_sfa = prims.mbarrier_wait_parity(
            ab_empty_mbar_ptr, async_sfa_empty_phase_bit, prims.MBarrierWait.TRY
        )
        for k_tile_idx in cutlass.range(k_tile_cnt, unroll=1):
            stage = k_tile_idx % num_ab_stage
            if stage == 0 and k_tile_idx != 0:
                async_sfa_empty_phase_bit = async_sfa_empty_phase_bit ^ 1
            wait_if_peek_failed(
                peek_ab_empty_sfa,
                ab_empty_mbar_ptr.subview(stage),
                async_sfa_empty_phase_bit,
            )

            sSFA_staged = sSFA.subview(num_bytes_sfa * stage)
            coord_k_sf = k_tile_idx * rest_k_sf_per_ktile
            gmem_ktile_base = gmem_l_m_base + coord_k_sf * 512

            for r_k in cutlass.range_constexpr(rest_k_sf_per_ktile):
                pair_idx = r_k // 2
                atom_in_pair = r_k % 2
                smem_off = pair_idx * 512 + lane * 16 + atom_in_pair * 8
                gmem_off = r_k * num_elts_atom_sf_e8 + lane * 16 + gmem_in_atom_off
                prims.cp_async_shared_global(
                    sSFA_staged.subview(smem_off),
                    gmem_ktile_base + gmem_off,
                    size=8,
                    modifier="ca",
                )
            prims.cp_async_mbarrier_arrive(a_local_mbar_ptr.subview(stage), noinc=True)

            peek_ab_empty_sfa = peek_next_k_tile_mbarrier(
                ab_empty_mbar_ptr,
                async_sfa_empty_phase_bit,
                k_tile_idx,
                k_tile_cnt,
                num_ab_stage,
            )

    # Warp 8: fixed cluster-N=256 TMA-SFB, parallel with A/B TMA.
    if warp_idx == tma_sfb_warp_id:
        sfb_phase_bit = ab_mbar_empty_phase_bit

        peek_ab_empty_sfb = prims.mbarrier_wait_parity(
            ab_empty_mbar_ptr, sfb_phase_bit, prims.MBarrierWait.TRY
        )
        for k_tile_idx in cutlass.range(k_tile_cnt, unroll=1):
            stage = k_tile_idx % num_ab_stage
            if stage == 0 and k_tile_idx != 0:
                sfb_phase_bit = sfb_phase_bit ^ 1
            wait_if_peek_failed(
                peek_ab_empty_sfb, ab_empty_mbar_ptr.subview(stage), sfb_phase_bit
            )

            sSFB_staged = sSFB.subview(num_bytes_sfb * stage)
            coord_k_sf = k_tile_idx * rest_k_sf_per_ktile

            if prims.elect_sync():
                prims.mbarrier_arrive_expect_tx(
                    sfb_smem_full_mbar_ptr.subview(stage),
                    num_tma_load_bytes_sfb,
                )
                prims.cp_async_bulk_tensor_shared_cluster_global(
                    sSFB_staged,
                    tma_sfb_desc.get_ptr(),
                    (0, coord_n_sf, coord_k_sf),
                    sfb_smem_full_mbar_ptr.subview(stage),
                    [],
                    group=prims.CTAGroup.CTA_1,
                )

            peek_ab_empty_sfb = peek_next_k_tile_mbarrier(
                ab_empty_mbar_ptr,
                sfb_phase_bit,
                k_tile_idx,
                k_tile_cnt,
                num_ab_stage,
            )

    # Warp 7: wait local SFA-copy completion, then
    # cross-CTA arrive on the leader's ab_full[stage]. SFB has its own
    # TMA -> UTCCP path in the MMA warp and does not participate here.
    if warp_idx == sync_warp_id:
        for k_tile_idx in cutlass.range(k_tile_cnt, unroll=1):
            stage = k_tile_idx % num_ab_stage
            phase_local = (k_tile_idx // num_ab_stage) & 1
            while not prims.mbarrier_try_wait_parity(
                a_local_mbar_ptr.subview(stage), phase_local, time_limit=10_000_000
            ):
                pass
            if prims.elect_sync():
                leader_ab_full = prims.mapa(ab_full_mbar_ptr.subview(stage), 0)
                prims.mbarrier_arrive(leader_ab_full, count=1, scope=prims.MemScope.CTA)

    # Warp 4: TMEM alloc, S2T copy, tcgen05.mma.block_scale (CTA_2).
    # Both CTAs cooperatively allocate; only the leader does the MMA body.
    if warp_idx == mma_warp_id:
        prims.tcgen05_alloc(
            tmem_ptr_i32, NUM_TMEM_ALLOC_COLS, group=prims.CTAGroup.CTA_2
        )
        # Intra-pair barrier: MMA + 4 epilog warps.
        prims.barrier_cta_sync(tmem_bar_id, thread_count=tmem_bar_threads)

        if is_leader_cta:
            tmem_raw_addr = tmem_ptr_i32.load()
            acc_tmem_ptr = cutlass.inttoptr(tmem_raw_addr, 6, cutlass.Float32)

            # The descriptor has no CTA-group bit. CTA_2 is selected by the
            # tcgen05_mma_block_scale(..., CTA_2, ...) call below, so pass the
            # logical collective M/N here. For this example m_dim=128 means
            # collective M=128 because the MMA issue uses CTA_2; it is not a
            # "default 2CTA" property of Tcgen05MxOmmaInstrDesc.build itself.
            # The block-scaled descriptor builder encodes M >> 7 and N >> 3.
            idesc = prims.Tcgen05MxOmmaInstrDesc.build(
                a_dtype=cutlass.Float4E2M1FN,
                b_dtype=cutlass.Float4E2M1FN,
                scale_format=0,
                n_dim=mma_tiler_mnk[1],
                m_dim=mma_tiler_mnk[0],
            )
            sfa_s2t_shape, sfa_s2t_multicast = prims.S2TCopyMode.S2T_32x128b_WARPX4
            sfb_s2t_shape, sfb_s2t_multicast = (
                prims.S2TCopyMode.S2T_64x128b_WARPX2_01_23
            )

            base_col_id = tmem_raw_addr & 0xFFFF
            base_row_id = tmem_raw_addr >> 16
            # ACC uses physical 64 columns per CTA. The 2x2 mapping folds
            # cluster-N=256 onto rows 0..63 and 64..127, so SFA starts after
            # the physical per-CTA accumulator column span, not after cluster-N.
            sfa_col_id = base_col_id + (mma_tiler_mnk[1] // CLUSTER_SX)
            sfb_col_id = sfa_col_id + (
                rest_k_sf_per_ktile * rest_m_sf_per_ktile * num_tmem_cols_per_sf_atom
            )
            sfa_tmem_addr_base = (base_row_id << 16) | sfa_col_id
            sfb_tmem_addr_base = (base_row_id << 16) | sfb_col_id
            # SFA UTCCP transfer: each packed pair reads 32 lanes x 16 B from
            # SMEM (= 32 in 16-B desc units) and writes one 4-column TMEM
            # record.
            num_smem_inc_per_sf_pair = num_elts_atom_sf_e8 >> 4  # = 32
            num_pairs_per_ktile = (rest_m_sf_per_ktile * rest_k_sf_per_ktile) // 2
            num_kblocks = cute.ceil_div(mma_tiler_mnk[2], mma_inst_mnk[2])

            # Each CTA reads SFA from its local TMEM at the same column offset;
            # the CTA_2 M=128 descriptor selects the local 64-row M-half.
            sfa_tmem_col_offset = 0
            sfa_mma_tmem_addr_base = sfa_tmem_addr_base + sfa_tmem_col_offset
            sfb_smem_full_phase_bit = ab_mbar_full_phase_bit

            # Hoist Tcgen05SmemDesc.build outside the K-tile loop.
            # Constant bit-packed fields (leading/stride/version/layout)
            # built once; per-stage descs become 64-bit AddOffsetOp.
            desc_a_s2t_at_base = prims.Tcgen05SmemDesc.build(
                sSFA,
                leading_byte_offset=16,
                stride_byte_offset=128,
                base_offset=0,
                layout=0,
            )
            desc_b_s2t_at_base = prims.Tcgen05SmemDesc.build(
                sSFB,
                leading_byte_offset=16,
                stride_byte_offset=128,
                base_offset=0,
                layout=0,
            )
            desc_a_mma_at_base = prims.Tcgen05SmemDesc.build(
                sA,
                leading_byte_offset=16,
                stride_byte_offset=1024,
                base_offset=0,
                layout=2,
            )
            desc_b_mma_at_base = prims.Tcgen05SmemDesc.build(
                sB,
                leading_byte_offset=16,
                stride_byte_offset=1024,
                base_offset=0,
                layout=2,
            )
            sfa_stage_off_16b = num_bytes_sfa >> 4
            sfb_stage_off_16b = num_bytes_sfb >> 4
            a_stage_off_16b = num_bytes_a_smem_per_cta >> 4
            b_stage_off_16b = num_bytes_b_smem_per_cta >> 4

            peek_ab_full = prims.mbarrier_wait_parity(
                ab_full_mbar_ptr, ab_mbar_full_phase_bit, prims.MBarrierWait.TRY
            )
            peek_sfb_smem_full = prims.mbarrier_wait_parity(
                sfb_smem_full_mbar_ptr,
                sfb_smem_full_phase_bit,
                prims.MBarrierWait.TRY,
            )
            for k_tile_idx in cutlass.range(k_tile_cnt, unroll=1):
                stage = k_tile_idx % num_ab_stage
                if stage == 0 and k_tile_idx != 0:
                    ab_mbar_full_phase_bit = ab_mbar_full_phase_bit ^ 1
                wait_if_peek_failed(
                    peek_ab_full,
                    ab_full_mbar_ptr.subview(stage),
                    ab_mbar_full_phase_bit,
                )

                desc_a_nvvm_s2t_base = desc_a_s2t_at_base + stage * sfa_stage_off_16b
                desc_b_nvvm_s2t_base = desc_b_s2t_at_base + stage * sfb_stage_off_16b
                desc_a_nvvm_mma_base = desc_a_mma_at_base + stage * a_stage_off_16b
                desc_b_nvvm_mma_base = desc_b_mma_at_base + stage * b_stage_off_16b

                for pair_idx in cutlass.range(num_pairs_per_ktile, unroll_full=True):
                    sfa_tmem_addr_s2t = (
                        sfa_tmem_addr_base + pair_idx * num_tmem_cols_per_sf_atom
                    )
                    sfa_tmem_ptr_s2t = cutlass.inttoptr(
                        sfa_tmem_addr_s2t, 6, cutlass.Int32
                    )
                    increment_s2t = num_smem_inc_per_sf_pair * pair_idx
                    desc_a_nvvm_s2t = desc_a_nvvm_s2t_base + increment_s2t
                    if prims.elect_sync():
                        prims.tcgen05_cp(
                            sfa_s2t_shape,
                            sfa_tmem_ptr_s2t,
                            desc_a_nvvm_s2t,
                            group=prims.CTAGroup.CTA_2,
                            multicast=sfa_s2t_multicast,
                        )

                if stage == 0 and k_tile_idx != 0:
                    sfb_smem_full_phase_bit = sfb_smem_full_phase_bit ^ 1
                wait_if_peek_failed(
                    peek_sfb_smem_full,
                    sfb_smem_full_mbar_ptr.subview(stage),
                    sfb_smem_full_phase_bit,
                )

                sfb_mma_tmem_addr_base = (
                    sfb_tmem_addr_base + stage * sfb_tmem_cols_per_stage
                )

                # Peek next iter's ab_full + sfb_smem_full BEFORE the
                # scale-copy + MMA chains so try_wait latency hides under
                # tcgen05 issue work + final tcgen05_commit.
                peek_ab_full = peek_next_k_tile_mbarrier(
                    ab_full_mbar_ptr,
                    ab_mbar_full_phase_bit,
                    k_tile_idx,
                    k_tile_cnt,
                    num_ab_stage,
                )
                peek_sfb_smem_full = peek_next_k_tile_mbarrier(
                    sfb_smem_full_mbar_ptr,
                    sfb_smem_full_phase_bit,
                    k_tile_idx,
                    k_tile_cnt,
                    num_ab_stage,
                )

                for kblock_idx in cutlass.range(num_kblocks, unroll_full=True):
                    sfb_tmem_addr_s2t = sfb_mma_tmem_addr_base + (
                        kblock_idx * sfb_tmem_cols_per_atom
                    )
                    sfb_tmem_ptr_s2t = cutlass.inttoptr(
                        sfb_tmem_addr_s2t, 6, cutlass.Int32
                    )
                    sfb_smem_inc = (
                        (num_elts_atom_sf_e8 * rest_n_sf_per_ktile) >> 4
                    ) * kblock_idx
                    desc_b_nvvm_s2t = desc_b_nvvm_s2t_base + sfb_smem_inc
                    if prims.elect_sync():
                        prims.tcgen05_cp(
                            sfb_s2t_shape,
                            sfb_tmem_ptr_s2t,
                            desc_b_nvvm_s2t,
                            group=prims.CTAGroup.CTA_2,
                            multicast=sfb_s2t_multicast,
                        )

                for kblock_idx in cutlass.range(num_kblocks, unroll_full=True):
                    enable_input_d = (k_tile_idx != 0) | (kblock_idx != 0)
                    sfa_tmem_addr_mma = sfa_mma_tmem_addr_base + (kblock_idx * 2)
                    sfb_tmem_addr_mma = sfb_mma_tmem_addr_base + (
                        kblock_idx * sfb_tmem_cols_per_atom
                    )
                    sfa_tmem_ptr_mma = cutlass.inttoptr(
                        sfa_tmem_addr_mma, 6, cutlass.Int32
                    )
                    sfb_tmem_ptr_mma = cutlass.inttoptr(
                        sfb_tmem_addr_mma, 6, cutlass.Int32
                    )
                    increment_mma = (
                        (mma_inst_mnk[2] * b_dtype.width // 8) >> 4
                    ) * kblock_idx
                    desc_a_nvvm_mma = desc_a_nvvm_mma_base + increment_mma
                    desc_b_nvvm_mma = desc_b_nvvm_mma_base + increment_mma
                    if prims.elect_sync():
                        prims.tcgen05_mma_block_scale(
                            prims.MMABlockScaleKind.MXF4NVF4,
                            prims.CTAGroup.CTA_2,
                            acc_tmem_ptr,
                            desc_a_nvvm_mma,
                            desc_b_nvvm_mma,
                            idesc,
                            enable_input_d=enable_input_d,
                            scale_a=sfa_tmem_ptr_mma,
                            scale_b=sfb_tmem_ptr_mma,
                            scale_vec_size=prims.Tcgen05MMABlockScale.BLOCK16,
                        )

                if prims.elect_sync():
                    prims.tcgen05_commit(
                        ab_empty_mbar_ptr.subview(stage),
                        multicast_mask=3,
                        group=prims.CTAGroup.CTA_2,
                    )

            # Signal accumulator ready (broadcast to both CTAs' acc_full).
            if prims.elect_sync():
                prims.tcgen05_commit(
                    acc_full_mbar_ptr,
                    multicast_mask=3,
                    group=prims.CTAGroup.CTA_2,
                )

    # Epilog warps (warps 0..3): collective-M=128 2x2 partition.
    # Each CTA's TMEM holds (M-half × cluster_n) in 4 quadrants:
    #   warp 0: rows  0..31  → (M_local 0..31,  N 0..cluster_n/2 - 1)
    #   warp 1: rows 32..63  → (M_local 32..63, N 0..cluster_n/2 - 1)
    #   warp 2: rows 64..95  → (M_local 0..31,  N cluster_n/2..cluster_n - 1)
    #   warp 3: rows 96..127 → (M_local 32..63, N cluster_n/2..cluster_n - 1)
    #
    # Per-CTA epilog writes row-major FP16 C directly to GMEM. There is no
    # output quantization, SFC generation, C SMEM staging, or TMA store in this
    # teaching example; the epilogue exists to make the M/N warp mapping
    # explicit.
    if warp_idx < mma_warp_id:
        prims.barrier_cta_sync(tmem_bar_id, thread_count=tmem_bar_threads)

        tmem_raw_addr = tmem_ptr_i32.load()
        acc_tmem_ptr = cutlass.inttoptr(tmem_raw_addr, 6, cutlass.Float32)
        base_col_id = tmem_raw_addr & 0xFFFF
        base_row_id = tmem_raw_addr >> 16
        # Physical TMEM row stripe for this epilogue warp.
        row_id_with_warp_offset = base_row_id + warp_idx * 32

        # Direct row-major C store for this warp's M/N quadrant.
        m_stripe_idx = warp_idx % 2
        n_stripe_idx = warp_idx // 2
        warp_tmem_cols: cutlass.Constexpr[int] = cluster_tile_n // 2
        tmem_load_subtile_n: cutlass.Constexpr[int] = 16
        subtile_cnt_per_warp: cutlass.Constexpr[int] = (
            warp_tmem_cols // tmem_load_subtile_n
        )

        lane_id = tidx % 32
        row = coord_m_cluster + cta_rank * tile_m_per_cta + m_stripe_idx * 32 + lane_id
        warp_n_base_global = coord_n_cluster + n_stripe_idx * warp_tmem_cols
        c_gmem = c_tensor.iterator.raw_ptr()

        while not prims.mbarrier_try_wait_parity(
            acc_full_mbar_ptr, 0, time_limit=10_000_000
        ):
            pass

        for sub_in_warp in cutlass.range_constexpr(subtile_cnt_per_warp):
            sub_n_base_global = warp_n_base_global + sub_in_warp * tmem_load_subtile_n
            tmem_ptr_epi = cutlass.inttoptr(
                ((row_id_with_warp_offset << 16) | base_col_id)
                + sub_in_warp * tmem_load_subtile_n,
                mem_space=6,
                dtype=cutlass.Float32,
            )
            data = prims.tcgen05_ld(
                prims.Tcgen05LdStShape.SHAPE_32X32B,
                tmem_ptr_epi,
                num=tmem_load_subtile_n,
            )
            prims.tcgen05_wait(kind=prims.Tcgen05Wait.LOAD)

            c_vec = data.to(cutlass.Float16)
            c_idx = row * n + sub_n_base_global
            if row < m and sub_n_base_global + tmem_load_subtile_n <= n:
                (c_gmem + c_idx).store(c_vec, alignment=16)

        # TMEM dealloc handshake — M-pair only, not cluster-wide.
        prims.barrier_cta_sync(
            epilog_dealloc_bar_id,
            thread_count=32 * len(epilog_warp_id),
        )
        if warp_idx == 0:
            prims.tcgen05_relinquish_alloc_permit(group=prims.CTAGroup.CTA_2)
            peer_cta_rank = cta_rank ^ 1
            peer_mbar = prims.mapa(tmem_dealloc_mbar_ptr, peer_cta_rank)
            prims.mbarrier_arrive(peer_mbar, count=1, scope=prims.MemScope.CTA)
            while not prims.mbarrier_try_wait_parity(
                tmem_dealloc_mbar_ptr, 0, time_limit=10_000_000
            ):
                pass
            prims.tcgen05_dealloc(
                acc_tmem_ptr,
                NUM_TMEM_ALLOC_COLS,
                group=prims.CTAGroup.CTA_2,
            )

    return


@cute.jit
def cvt_sf_MK_to_M32x4xrm_K4xrk(
    sf_ref_ptr: cute.Pointer,
    sf_mma_ptr: cute.Pointer,
    mn: int,
    sf_k: int,
    mma_shape: tuple,
) -> None:
    """Convert reference SF layout to the CUTE NVFP4 scale-factor layout."""
    mma_permute_order = (2, 3, 0, 4, 1)
    permuted_shape = tuple(mma_shape[i] for i in mma_permute_order)
    cute_layout = cute.make_ordered_layout(permuted_shape, order=(2, 1, 4, 0, 3))

    sf_ref_tensor = cute.make_tensor(
        sf_ref_ptr, cute.make_layout((mn, sf_k), stride=(sf_k, 1))
    )
    sf_mma_tensor = cute.make_tensor(sf_mma_ptr, cute_layout)

    sf_mma_tensor = cute.group_modes(sf_mma_tensor, 0, 3)
    sf_mma_tensor = cute.group_modes(sf_mma_tensor, 1, 3)
    for i in cutlass.range(cute.size(sf_ref_tensor)):
        mkl_coord = sf_ref_tensor.layout.get_hier_coord(i)
        sf_mma_tensor[mkl_coord] = sf_ref_tensor[mkl_coord]


def create_ref_scale_factor_tensor(dim: int, sf_k: int) -> torch.Tensor:
    """Create reference scale factors in logical (dim, K / sf_vec_size) order."""
    ref_shape = (dim, sf_k)
    ref_f8_int = torch.randint(1, 3, ref_shape, dtype=torch.int8)
    return ref_f8_int.to(dtype=torch_sf_dtype)


def create_cute_scale_factor_tensor(
    dim: int,
    sf_k: int,
    sf_ref: torch.Tensor,
) -> torch.Tensor:
    """Build the atom-major CUTE NVFP4 scale-factor tensor."""
    atom_m = (num_m0_per_sf_atom, num_m1_per_sf_atom)
    atom_k = num_k_per_sf_atom
    mma_shape = (
        (dim + atom_m[0] * atom_m[1] - 1) // (atom_m[0] * atom_m[1]),
        (sf_k + atom_k - 1) // atom_k,
        atom_m[0],
        atom_m[1],
        atom_k,
    )
    mma_permute_order = (2, 3, 0, 4, 1)
    rand_int = torch.randint(0, 2, mma_shape, dtype=torch.int8)
    sf_cute = rand_int.to(dtype=torch_sf_dtype).permute(*mma_permute_order)
    cvt_sf_MK_to_M32x4xrm_K4xrk(
        make_ptr(
            sf_dtype,
            sf_ref.data_ptr(),
            cutlass.AddressSpace.gmem,
            assumed_align=32,
        ),
        make_ptr(
            sf_dtype,
            sf_cute.data_ptr(),
            cutlass.AddressSpace.gmem,
            assumed_align=32,
        ),
        dim,
        sf_k,
        mma_shape,
    )
    return sf_cute.cuda()


@lru_cache(maxsize=None)
def _compile() -> Callable:
    """JIT-compile the kernel with symbolic shapes (TVM-FFI)."""
    from cutlass.cute.runtime import make_fake_compact_tensor, make_fake_stream

    cutlass.cuda.initialize_cuda_context()

    sym = cute.sym_int32
    dk = lambda: sym(divisibility=K_TILE)  # noqa: E731
    d128 = lambda: sym(divisibility=128)  # noqa: E731
    d16 = lambda: sym(divisibility=16)  # noqa: E731
    d1 = lambda: sym(divisibility=1)  # noqa: E731
    fake_a = make_fake_compact_tensor(cutlass.Int8, (dk(), d16()))
    fake_b = make_fake_compact_tensor(cutlass.Int8, (dk(), d1()))
    fake_sfa = make_fake_compact_tensor(sf_dtype, (d128(), d1(), d1()))
    fake_sfb = make_fake_compact_tensor(sf_dtype, (d128(), d1(), d1()))
    fake_c = make_fake_compact_tensor(c_dtype, (d16(), d1()), stride_order=(1, 0))
    fake_problem_size = (d16(), d1(), dk())
    fake_stream = make_fake_stream()

    return cute.compile(
        gemm,
        fake_a,
        fake_b,
        fake_sfa,
        fake_sfb,
        fake_c,
        fake_problem_size,
        fake_stream,
        options="--enable-tvm-ffi",
    )


def compile() -> Callable:  # noqa: A001
    return _compile()


def create_tensors(m: int, n: int, k: int):
    """Create A/B/SFA/SFB tensors with the same layouts as NVFP4 tutorials."""
    torch.manual_seed(1111)

    if m % GROUP_TILE_M != 0:
        raise ValueError(f"m ({m}) must be divisible by {GROUP_TILE_M}")
    if n != GROUP_TILE_N:
        raise ValueError(f"n ({n}) must equal {GROUP_TILE_N}")
    if k % K_TILE != 0:
        raise ValueError(f"k ({k}) must be divisible by {K_TILE}")
    if k % 2 != 0:
        raise ValueError(f"k ({k}) must be even for packed FP4")

    a_f32 = torch.randint(-2, 3, (m, k), dtype=torch.float32, device="cuda").permute(
        1, 0
    )
    _, a_torch = cutlass_torch.cute_tensor_like(
        a_f32, a_dtype, is_dynamic_layout=True, assumed_align=16
    )
    b_f32 = torch.randint(-2, 3, (n, k), dtype=torch.float32, device="cuda").permute(
        1, 0
    )
    _, b_torch = cutlass_torch.cute_tensor_like(
        b_f32, b_dtype, is_dynamic_layout=True, assumed_align=16
    )
    c_torch = torch.zeros((m, n), dtype=cutlass_torch.dtype(c_dtype), device="cuda")

    sf_k = k // sf_vec_size
    sfa_ref = create_ref_scale_factor_tensor(m, sf_k)
    sfb_ref = create_ref_scale_factor_tensor(n, sf_k)
    sfa_torch = create_cute_scale_factor_tensor(m, sf_k, sfa_ref)
    sfb_torch = create_cute_scale_factor_tensor(n, sf_k, sfb_ref)
    rest_k_sf = sf_k // num_k_per_sf_atom
    rest_m_sf = m // (num_m0_per_sf_atom * num_m1_per_sf_atom)
    rest_n_sf = n // (num_m0_per_sf_atom * num_m1_per_sf_atom)
    # The tutorial-style SF tensors have atom-major physical storage.
    # Bind flat views to this direct CUTLASS primitives test so the kernel can use simple
    # pointer arithmetic for SFA async copies and a TMA descriptor that keeps the two
    # N=128 SFB atoms for one K block adjacent in SMEM.
    sfa_kernel = torch.as_strided(
        sfa_torch,
        (num_elts_atom_sf_e8, rest_k_sf, rest_m_sf),
        (1, num_elts_atom_sf_e8, num_elts_atom_sf_e8 * rest_k_sf),
    )
    sfb_kernel = torch.as_strided(
        sfb_torch,
        (num_elts_atom_sf_e8, rest_n_sf, rest_k_sf),
        (1, num_elts_atom_sf_e8 * rest_k_sf, num_elts_atom_sf_e8),
    )

    def _ffi(t, leading_dim: int, assumed_align: int = 16):
        return from_dlpack(
            t, assumed_align=assumed_align, enable_tvm_ffi=True
        ).mark_layout_dynamic(leading_dim=leading_dim)

    a_tensor = _ffi(a_torch.view(torch.int8), leading_dim=0)
    b_tensor = _ffi(b_torch.view(torch.int8), leading_dim=0)
    c_tensor = _ffi(c_torch, leading_dim=1)
    sfa_tensor = _ffi(sfa_kernel, leading_dim=0, assumed_align=32)
    sfb_tensor = _ffi(sfb_kernel, leading_dim=0, assumed_align=32)

    return (
        a_tensor,
        b_tensor,
        sfa_tensor,
        sfb_tensor,
        c_tensor,
        a_f32,
        b_f32,
        c_torch,
        sfa_ref,
        sfb_ref,
    )


def compute_ref(
    a_f32,
    b_f32,
    sfa_ref,
    sfb_ref,
    m,
    n,
    k,
):
    """Reference GEMM for the example's host tensor layouts.

    Shapes:
      - a_f32: (K, M)
      - b_f32: (K, N)
      - sfa_ref: (M, K / sf_vec_size)
      - sfb_ref: (N, K / sf_vec_size)
      - return: row-major C, shape (M, N)
    """
    sfa_expand = (
        sfa_ref.cuda().to(torch.float32).repeat_interleave(sf_vec_size, dim=1)[:m, :k]
    )
    sfb_expand = (
        sfb_ref.cuda().to(torch.float32).repeat_interleave(sf_vec_size, dim=1)[:n, :k]
    )
    a_scaled = a_f32 * sfa_expand.permute(1, 0)
    b_scaled = b_f32 * sfb_expand.permute(1, 0)
    return torch.mm(a_scaled.permute(1, 0), b_scaled).to(torch.float16)


def run(
    mnk: tuple[int, int, int] = DEFAULT_MNK,
    tolerance: float = 0.5,
) -> bool:
    m, n, k = mnk
    if m % GROUP_TILE_M != 0:
        raise ValueError(f"m ({m}) must be divisible by {GROUP_TILE_M} (cluster M)")
    if n != GROUP_TILE_N:
        raise ValueError(
            f"this simple direct-store example expects n={GROUP_TILE_N}, got {n}"
        )
    if k % K_TILE != 0:
        raise ValueError(f"k ({k}) must be divisible by {K_TILE}")

    print("=" * 60)
    print("NVFP4xNVFP4 — 2CTA collective M=128 (2x2 accumulator mapping)")
    print(f"  Problem (M,N,K): {mnk}")
    print(
        "  Tile (cluster M, per-CTA N, cluster N, K): "
        f"({GROUP_TILE_M}, {CTA_TILE_N}, {GROUP_TILE_N}, {K_TILE})"
    )
    print(f"  Cluster: ({CLUSTER_SX}, {CLUSTER_SY}, 1) — collective-M=128 M-pair")
    print("=" * 60)

    if not torch.cuda.is_available():
        raise RuntimeError("GPU is required!")

    (
        a_tensor,
        b_tensor,
        sfa_tensor,
        sfb_tensor,
        c_tensor,
        a_f32,
        b_f32,
        c_torch,
        sfa_ref,
        sfb_ref,
    ) = create_tensors(m, n, k)

    current_stream = cutlass_torch.default_stream()
    compiled_gemm = compile()

    compiled_gemm(
        a_tensor,
        b_tensor,
        sfa_tensor,
        sfb_tensor,
        c_tensor,
        (m, n, k),
        current_stream,
    )
    torch.cuda.synchronize()
    print("Kernel executed successfully!")

    print("Computing FP32 reference...")
    c_ref = compute_ref(
        a_f32,
        b_f32,
        sfa_ref,
        sfb_ref,
        m,
        n,
        k,
    )

    torch.testing.assert_close(c_torch, c_ref, atol=tolerance, rtol=1e-02)
    print(f"torch.testing.assert_close: PASS (atol={tolerance}, rtol=1e-02)")
    return True


def verify(
    mnk: tuple[int, int, int] = DEFAULT_MNK,
    tolerance: float = 0.5,
) -> None:
    run(mnk=mnk, tolerance=tolerance)


if __name__ == "__main__":

    def _csv(s):
        try:
            return tuple(int(x.strip()) for x in s.split(","))
        except ValueError:
            raise argparse.ArgumentTypeError("Expected comma-separated ints")

    parser = argparse.ArgumentParser(
        description="2CTA NVFP4×NVFP4 — collective M=128 / 2x2 accumulator mapping"
    )
    parser.add_argument("--mnk", type=_csv, default=DEFAULT_MNK)
    parser.add_argument("--tolerance", type=float, default=0.5)
    args = parser.parse_args()

    if len(args.mnk) != 3:
        parser.error("--mnk must contain exactly 3 values")
    passed = run(args.mnk, args.tolerance)
    print("DONE")
    if not passed:
        import sys

        sys.exit(1)
