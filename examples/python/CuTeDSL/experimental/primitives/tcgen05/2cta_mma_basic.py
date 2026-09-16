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

"""Pedagogical rung-0 CTA_2 GEMM — bare protocol, no mode dispatch.

**Role in the example ladder.**  This file is the **fixed-shape
teaching reference** for the CTA_2 collective MMA protocol: a single
concrete tile (``cluster=(2,1,1)``, ``mma_tiler=(256, 256, 64)``) with
no ``USE_2CTA_GROUP`` constexpr branches, no variant catalog, and no
per-mode validators.  The duplication with ``clusterMxN_2cta_mma.py``
is intentional — every constexpr branch removed makes the underlying
protocol one step easier for a first-time reader to follow top-to-
bottom.  Read this file first; switch to ``clusterMxN_2cta_mma.py``
once you need to sweep cluster / tile shapes, vary the 2-SM-group
split, or include a CTA_1 fallback.

The parametric superset (``clusterMxN_2cta_mma.py``) reproduces this
file's behaviour exactly with ``CLUSTER_TILE=(256, 256)`` and the V1
shape pattern (``CLUSTER_SHAPE=(2,1)``, n_groups=1).

Demonstrates the two-CTA collaborative execution pattern where a pair of CTAs
in a 2×1 cluster jointly compute a 256×256 output tile:

  - ``cutlass.GridConstant[cuda.TensorMap]`` and ``desc.get_ptr()`` — new TMA descriptor API.
  - ``group="cta_2"`` for :func:`~cutlass.primitives.tcgen05_alloc` and
    ``group=CTAGroupKind.CTA_2`` for :func:`~cutlass.primitives.tcgen05_mma` —
    both CTAs collaborate on a shared TMEM
    allocation and execute MMA instructions as a single unit.
  - Per-CTA TMA loads via
    :func:`~cutlass.primitives.cp_async_bulk_tensor_shared_cluster_global` with
    ``group=CTA_2``: all ``complete_tx`` signals route to CTA 0's mbarrier
    so the leader can use a single mbarrier to track both CTAs' TMA loads.
  - :func:`~cutlass.primitives.barrier_cluster_arrive_relaxed` / :func:`~cutlass.primitives.barrier_cluster_wait`
    — cluster formation fence after mbarrier init.
  - :func:`~cutlass.primitives.tcgen05_commit` / :func:`~cutlass.primitives.tcgen05_relinquish_alloc_permit`
    — TMEM lifecycle management.

2-CTA layout
------------
::

    cluster (2, 1, 1): CTA 0 and CTA 1 in the M dimension.

    A (M, K) — each CTA loads its own 128-row slice (rows 0:128 vs 128:256).
    B (N, K) — each CTA loads its own 128-col slice (cols 0:128 vs 128:256).
    C (M, N) — 256×256 tile; leader (CTA 0) holds TMEM and writes all of C.

    tcgen05 CTA_2 MMA: CTA 0 and CTA 1 contribute A and B tiles collaboratively
    to compute the full 256×256 result in CTA 0's TMEM.

Tile sizes (naming matches ``clusterMxN_2cta_mma.py``)::

    CLUSTER_SHAPE  = (CLUSTER_SX, CLUSTER_SY) = (2, 1)   # 1 group, 2 CTAs in M
    CLUSTER_TILE_M, CLUSTER_TILE_N, K_TILE    = 256, 256, 64
    GROUP_TILE_M,   GROUP_TILE_N              = 256, 256  # n_groups=1
    CTA_TILE_M,     CTA_TILE_N                = 128, 128  # 2 CTAs split M/N
    MMA_K_GRANULE                             = 16        # one tcgen05 K-block

For naming-convention parity with ``clusterMxN_2cta_mma.py``: this file
is its ``CLUSTER_SHAPE=(2,1)``, ``CLUSTER_TILE=(256, 256)``, n_groups=1
specialisation, with every constexpr branch flattened.

See ``tutorial_gemm/fp16_gemm_1.py`` for a production version with warp
specialisation, persistent scheduling, and configurable epilogue.

To run::

    python CuTeDSL/experimental/primitives/tcgen05/2cta_mma_basic.py --mnk 256,256,64
    python CuTeDSL/experimental/primitives/tcgen05/2cta_mma_basic.py --tmem_ld_warp_start 2

"""

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

# ---------------------------------------------------------------------------
# Configuration  (names match clusterMxN_2cta_mma.py for ladder consistency)
# ---------------------------------------------------------------------------
io_dtype = cutlass.Float16
acc_dtype = cutlass.Float32

# tcgen05.mma per-instruction K granule for fp16 = 16 elements.
MMA_K_GRANULE: int = 16

# Cluster: 2 CTAs in M, 1 in N — single 2-SM group (n_groups=1).
CLUSTER_SX, CLUSTER_SY = 2, 1

# Cluster / group / per-CTA tile dims.  n_groups=1 → cluster_tile == group_tile.
CLUSTER_TILE_M = 256
CLUSTER_TILE_N = 256
K_TILE = 64
GROUP_TILE_M = CLUSTER_TILE_M  # 256
GROUP_TILE_N = CLUSTER_TILE_N  # 256
CTA_TILE_M = GROUP_TILE_M // 2  # 128 — 2 CTAs split along M
CTA_TILE_N = GROUP_TILE_N // 2  # 128 — each CTA loads its own N-half of B
# (Layout A: TMEM still holds full GROUP_TILE_N
# in epilogue — see col offset below.)
_TMEM_LD_WARPS = 4
_DEFAULT_TMEM_LD_WARP_START = 0


def _threads_for_tmem_ld_warp_start(tmem_ld_warp_start: int) -> int:
    """Return CTA threads needed for a contiguous 4-warp TMEM-load range."""
    if tmem_ld_warp_start < 0 or tmem_ld_warp_start > 4:
        raise ValueError("tmem_ld_warp_start must be in [0, 4]")
    return (tmem_ld_warp_start + _TMEM_LD_WARPS) * 32


# ---------------------------------------------------------------------------
# CUDA kernel
# ---------------------------------------------------------------------------


@cute.kernel
def kernel(
    tma_a_desc: cutlass.GridConstant[cuda.TensorMap],  # A descriptor: (M, K) fp16
    tma_b_desc: cutlass.GridConstant[cuda.TensorMap],  # B descriptor: (N, K) fp16
    mC_mn: cute.Tensor,  # C output: (M, N) fp16 (row-major)
    k: cutlass.Int32,
    TMEM_LD_WARP_START: cutlass.Constexpr[int],
) -> None:
    """2-CTA GEMM kernel: TMA load → CTA_2 tcgen05 MMA → epilogue.

    Warp 0 in both CTAs handles TMA loads and MMA.  Four contiguous TMEM-load
    warps starting at ``TMEM_LD_WARP_START`` drain TMEM to global C.
    """
    warp_idx = cute.arch.warp_idx()
    tidx, _, _ = cute.arch.thread_idx()
    bidx, bidy, _ = cute.arch.block_idx()  # CTA block index (accounts for cluster)

    # ---- Cluster rank / 2-SM-group decomposition (n_groups=1) ----------
    # Cluster has 2 CTAs along X; with one 2-SM group, group_lane == cluster_rank.
    cluster_rank = cute.arch.block_idx_in_cluster()
    group_lane = cluster_rank  # 0 = group leader, 1 = peer
    is_group_leader = group_lane == 0

    # ---- Global tile coordinates -----------------------------------------
    # Both CTAs work on the same cluster super-tile; each owns a 128-row M-half
    # of A and a 128-col N-half of B.  TMEM Layout A: both CTAs see the FULL
    # GROUP_TILE_N during the epilogue (see col offset below).
    super_m = bidx // CLUSTER_SX
    super_n = bidy
    m_group_off = super_m * CLUSTER_TILE_M  # n_groups=1, so this is also m_off
    n_group_off = super_n * CLUSTER_TILE_N
    m_off_cta = m_group_off + group_lane * CTA_TILE_M
    n_off_cta = n_group_off + group_lane * CTA_TILE_N

    # ---- SMEM allocations ------------------------------------------------
    ab_full_mbar = cutlass.Array(cutlass.Int64, 1, space=cutlass.AddressSpace.smem)
    ab_empty_mbar = cutlass.Array(cutlass.Int64, 1, space=cutlass.AddressSpace.smem)
    acc_done_mbar = cutlass.Array(cutlass.Int64, 1, space=cutlass.AddressSpace.smem)
    tmem_ptr_i32 = cutlass.Array(cutlass.Int32, 1, space=cutlass.AddressSpace.smem)

    sA_elems = CTA_TILE_M * K_TILE  # 128 × 64
    sB_elems = CTA_TILE_N * K_TILE  # 128 × 64
    smem_a = cutlass.Array(
        cutlass.Float16, sA_elems, space=cutlass.AddressSpace.smem, alignment=128
    )
    smem_b = cutlass.Array(
        cutlass.Float16, sB_elems, space=cutlass.AddressSpace.smem, alignment=128
    )

    # ---- Mbarrier init (warp 0 of each CTA initialises its own mbar) -----
    # The leader's mbar is used for both CTAs' TMA completions (group=CTA_2
    # routes all complete_tx signals to CTA 0's SMEM via bit-24 masking).
    if warp_idx == 0:
        if prims.elect_sync():
            prims.mbarrier_init(ab_full_mbar, 1)
            prims.mbarrier_init(ab_empty_mbar, 1)
            prims.mbarrier_init(acc_done_mbar, 1)  # both CTAs init their own

    prims.fence_mbarrier_init()
    prims.barrier_cluster_arrive_relaxed()  # cluster formation: all CTAs fence mbar init

    # ---- TMEM allocation (warp 0, CTA_2 group — both CTAs allocate together)
    NUM_TMEM_COLS = 512
    if warp_idx == 0:
        prims.tcgen05_alloc(tmem_ptr_i32, NUM_TMEM_COLS, group="cta_2")

    # Complete cluster formation *and* ensure tmem_ptr_i32 is visible.
    prims.barrier_cluster_wait()
    prims.barrier_cta_sync(0)
    tmem_ptr = cutlass.inttoptr(tmem_ptr_i32.load(), 6, cutlass.Float32)

    # Relinquish early so other clusters can allocate TMEM.
    if warp_idx == 0:
        prims.tcgen05_relinquish_alloc_permit(group="cta_2")

    # Group leader's txcount covers both CTAs' A and B loads (group=CTA_2 routes
    # complete_tx from both CTAs to the leader's ab_full_mbar).
    group_leader_txcount = (
        tma_a_desc.global_tx_bytes() + tma_b_desc.global_tx_bytes()
    ) * 2  # 2 CTAs per 2-SM group

    # No data multicast here — each CTA loads a different tile slice.  Omit
    # ``multicast_mask`` entirely on the per-CTA-unicast TMA calls below: any
    # non-None mask (including a self-targeting ``1 << cluster_rank``) makes
    # ptxas select multicast routing for the generated load
    # (PTX ISA §9.7.16.5: ``.multicast::cluster``), which adds routing
    # overhead without any sharing benefit.  Omit the kwarg so the load stays
    # per-CTA unicast.

    # Instruction descriptor for 2-CTA m256n256k16 MMA.
    # n_dim and m_dim describe the *full collective* GROUP_TILE, not per-CTA.
    idesc = prims.Tcgen05InstrDesc.build(
        c_dtype=cutlass.Float32,
        n_dim=GROUP_TILE_N,  # 256 // 8 = 32
        m_dim=GROUP_TILE_M,  # 256 // 16 = 16
    )

    # ---- Main K-loop (warp 0 only) --------------------------------------
    num_k_tiles = cute.ceil_div(k, K_TILE)
    k_block_offset_bytes: cutlass.Constexpr[int] = MMA_K_GRANULE * 2
    tma_empty_phase = 1  # init sets parity=1; first wait passes immediately
    tma_full_phase = 0

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
            # Canonical scale_d: derive from the outer k-tile index as an
            # ArithValue (False on k=0 → clear acc; True after → accumulate).
            scale_d_first = k_tile_idx > cutlass.Int32(0)
            # Wait for SMEM to be free (immediately satisfied on first iteration).
            while not prims.mbarrier_try_wait_parity(ab_empty_mbar, tma_empty_phase):
                pass
            tma_empty_phase = tma_empty_phase ^ 1

            coord_k = k_tile_idx * K_TILE

            # Group leader sets txcount to cover both CTAs' A + B completions.
            if is_group_leader:
                if prims.elect_sync():
                    prims.mbarrier_arrive_expect_tx(ab_full_mbar, group_leader_txcount)

            # Each CTA loads its own A and B slice.
            # group=CTA_2: the primitive wrapper routes mbar pointer to CTA 0's SMEM.
            if prims.elect_sync():
                prims.cp_async_bulk_tensor_shared_cluster_global(
                    smem_a,
                    tma_a_desc.get_ptr(),
                    (coord_k, m_off_cta),  # TMA column-major: K innermost
                    ab_full_mbar,
                    [],
                    # multicast_mask intentionally omitted — see note above.
                    group=prims.CTAGroup.CTA_2,
                )
            if prims.elect_sync():
                prims.cp_async_bulk_tensor_shared_cluster_global(
                    smem_b,
                    tma_b_desc.get_ptr(),
                    (coord_k, n_off_cta),  # TMA column-major: K innermost
                    ab_full_mbar,
                    [],
                    # multicast_mask intentionally omitted — see note above.
                    group=prims.CTAGroup.CTA_2,
                )

            # Group leader waits for all TMA completions (both CTAs' A and B).
            if is_group_leader:
                while not prims.mbarrier_try_wait_parity(ab_full_mbar, tma_full_phase):
                    pass
                tma_full_phase = tma_full_phase ^ 1

                num_k_blocks = K_TILE // MMA_K_GRANULE
                for k_block_idx in cutlass.range_constexpr(num_k_blocks):
                    offset_bytes: cutlass.Constexpr[int] = (
                        k_block_offset_bytes * k_block_idx
                    )
                    desc_a = desc_a_root.advance_start_address(offset_bytes)
                    desc_b = desc_b_root.advance_start_address(offset_bytes)
                    if prims.elect_sync():
                        prims.tcgen05_mma(
                            prims.Tcgen05MMAKind.F16,
                            prims.CTAGroup.CTA_2,
                            tmem_ptr,
                            desc_a,
                            desc_b,
                            idesc,
                            scale_d_first if k_block_idx == 0 else True,
                        )

                # Signal A/B buffers consumed; ready for next load.
                # mask=3 broadcasts to both group members (cluster ranks 0+1).
                # Single-group cluster: leader is at cluster_rank=0, so
                # ``mask=3`` and ``mask=3 << cluster_rank`` are equivalent.
                # See ``clusterMxN_2cta_mma.py`` for the multi-group shifted form.
                if prims.elect_sync():
                    prims.tcgen05_commit(
                        ab_empty_mbar, multicast_mask=3, group=prims.CTAGroup.CTA_2
                    )

        # Signal accumulator fully computed.
        if is_group_leader:
            if prims.elect_sync():
                prims.tcgen05_commit(
                    acc_done_mbar, multicast_mask=3, group=prims.CTAGroup.CTA_2
                )

    # ---- Epilogue: selected warps wait for acc, read TMEM, write C --------
    prims.barrier_cta_sync(0)
    while not prims.mbarrier_try_wait_parity(acc_done_mbar, 0):
        pass

    TMEM_LD_WARP_END: cutlass.Constexpr[int] = TMEM_LD_WARP_START + _TMEM_LD_WARPS
    is_tmem_ld_warp = (warp_idx >= TMEM_LD_WARP_START) & (warp_idx < TMEM_LD_WARP_END)

    if is_tmem_ld_warp:
        # Each CTA reads TMEM and writes its own M-rows of C.
        # m_off_cta differs per CTA (CTA 0: rows 0-127, CTA 1: rows 128-255).
        tmem_raw_addr = tmem_ptr_i32.load()
        base_col_id = tmem_raw_addr & 0xFFFF
        base_row_id = tmem_raw_addr >> 16

        # SHAPE_32X32B access is bound to the issuing warp's physical
        # sub-partition, not to the logical TMEM-load rank.  For a shifted
        # TMEM-load range such as warps 2..5, the SP order is 2,3,0,1.
        tmem_sp = warp_idx % cutlass.Int32(4)
        lane = tidx & cutlass.Int32(31)
        row_in_cta = tmem_sp * cutlass.Int32(32) + lane
        row_id_with_warp = base_row_id + tmem_sp * cutlass.Int32(32)
        cur_tmem_col_addr = (row_id_with_warp << 16) | base_col_id

        gC_ptr = mC_mn.iterator.raw_ptr()
        vsize = 256 // mC_mn.dtype.width
        # TMEM Layout A: both CTAs see the FULL GROUP_TILE_N range.
        subtile_cnt = GROUP_TILE_N // 32
        t2r_inst_repx = 32  # elements per tcgen05_ld call

        for subtile_idx in cutlass.range_constexpr(subtile_cnt):
            subtile_col_offset = subtile_idx * 32
            subtile_tmem_addr = cur_tmem_col_addr + subtile_col_offset
            tmem = cutlass.inttoptr(subtile_tmem_addr, 6, cutlass.Float32)
            c_rmem_vec = prims.tcgen05_ld("32x32b", tmem, num=t2r_inst_repx)
            prims.tcgen05_wait(prims.Tcgen05Wait.LOAD)

            # CTA_2 Layout A: TMEM holds full GROUP_TILE_N cols, write at
            # n_group_off (NOT n_off_cta — that's the per-CTA TMA load offset).
            row = row_in_cta + m_off_cta
            col = n_group_off + subtile_col_offset
            for j in cutlass.range_constexpr(t2r_inst_repx // vsize):
                vec_f32 = c_rmem_vec[j * vsize : (j + 1) * vsize]
                vec_f16 = vec_f32.to(cutlass.Float16)
                linear_idx = row * mC_mn.shape[1] + col + j * vsize
                (gC_ptr + linear_idx).store(vec_f16, alignment=16)

    # Deallocate TMEM before exit.
    prims.tcgen05_fence(prims.Tcgen05Fence.BEFORE_THREAD_SYNC)
    prims.barrier_cta_sync(0)
    if warp_idx == 0:
        prims.tcgen05_dealloc(tmem_ptr, NUM_TMEM_COLS, group="cta_2")


# ---------------------------------------------------------------------------
# Host function
# ---------------------------------------------------------------------------


@cute.jit
def host(
    a: cute.Tensor,
    b: cute.Tensor,
    c: cute.Tensor,
    mnk: Tuple[int, int, int],
    TMEM_LD_WARP_START: cutlass.Constexpr[int],
    THREADS: cutlass.Constexpr[int],
) -> None:
    # A: (M, K) row-major.  TMA col-major: K innermost.  Box: K_TILE × CTA_TILE_M.
    tma_a_desc = cuda.create_tensor_map_tiled(
        global_address=a.iterator.toint(),
        dtype=cutlass.Float16,
        global_dims=[a.shape[1], a.shape[0]],  # [K, M]
        global_strides=[a.shape[1] * 2 // 16],  # row stride in 16-B units
        box_dims=[K_TILE, CTA_TILE_M],
        swizzle=cuda.TensorMapSwizzle.s128b,
    )
    # B: (N, K) row-major.  TMA col-major: K innermost.  Box: K_TILE × CTA_TILE_N.
    tma_b_desc = cuda.create_tensor_map_tiled(
        global_address=b.iterator.toint(),
        dtype=cutlass.Float16,
        global_dims=[b.shape[1], b.shape[0]],  # [K, N]
        global_strides=[b.shape[1] * 2 // 16],
        box_dims=[K_TILE, CTA_TILE_N],
        swizzle=cuda.TensorMapSwizzle.s128b,
    )

    # Grid: ceil(M / CLUSTER_TILE_M) × ceil(N / CLUSTER_TILE_N), each cluster
    # covers a CLUSTER_TILE_M × CLUSTER_TILE_N output tile.  Multiply M-grid by
    # CLUSTER_SX to round up to a whole-cluster boundary.
    grid_m = cute.ceil_div(mnk[0], CLUSTER_TILE_M)
    grid_n = cute.ceil_div(mnk[1], CLUSTER_TILE_N)
    kernel(tma_a_desc, tma_b_desc, c, mnk[2], TMEM_LD_WARP_START).launch(
        grid=(grid_m * CLUSTER_SX, grid_n * CLUSTER_SY, 1),
        block=(THREADS, 1, 1),
        cluster=(CLUSTER_SX, CLUSTER_SY, 1),
    )


# ---------------------------------------------------------------------------
# Compile and run
# ---------------------------------------------------------------------------


@lru_cache(maxsize=None)
def compile(
    k: int,
    tmem_ld_warp_start: int = _DEFAULT_TMEM_LD_WARP_START,
) -> Callable:
    threads = _threads_for_tmem_ld_warp_start(tmem_ld_warp_start)
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
    return cute.compile(
        host,
        fake_a,
        fake_b,
        fake_c,
        (sym_m, sym_n, k),
        tmem_ld_warp_start,
        threads,
        options="--enable-tvm-ffi",
    )


def run(
    mnk: Tuple[int, int, int],
    tolerance: float = 0.1,
    tmem_ld_warp_start: int = _DEFAULT_TMEM_LD_WARP_START,
) -> None:
    if not torch.cuda.is_available():
        raise RuntimeError("CUDA GPU required")

    m, n, k = mnk
    if m % CLUSTER_TILE_M or n % CLUSTER_TILE_N:
        raise ValueError(
            f"M must be a multiple of CLUSTER_TILE_M={CLUSTER_TILE_M}, "
            f"N must be a multiple of CLUSTER_TILE_N={CLUSTER_TILE_N}"
        )

    _threads_for_tmem_ld_warp_start(tmem_ld_warp_start)

    print(f"Running 2-CTA fp16 GEMM  mnk={mnk} tmem_ld_warp_start={tmem_ld_warp_start}")
    compiled = compile(k, tmem_ld_warp_start)

    torch.manual_seed(42)
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

    compiled(a, b, c, (m, n, k))

    ref = torch.einsum("mk,nk->mn", a.float(), b.float()).to(a.dtype)
    torch.testing.assert_close(c, ref, atol=tolerance, rtol=1e-5)
    print("PASS")


def verify(
    mnk: Tuple[int, int, int] = (256, 256, 64),
    tolerance: float = 0.1,
    tmem_ld_warp_start: int = _DEFAULT_TMEM_LD_WARP_START,
) -> None:
    """Pytest-friendly alias for the fixed-shape CTA_2 GEMM example."""
    run(
        mnk=mnk,
        tolerance=tolerance,
        tmem_ld_warp_start=tmem_ld_warp_start,
    )


if __name__ == "__main__":

    def parse_mnk(s: str) -> Tuple[int, int, int]:
        parts = [int(x) for x in s.split(",")]
        if len(parts) != 3:
            raise argparse.ArgumentTypeError("Expected M,N,K")
        return tuple(parts)

    parser = argparse.ArgumentParser(
        description="2-CTA fp16 GEMM: TMA load + 2-CTA tcgen05 MMA"
    )
    parser.add_argument("--mnk", type=parse_mnk, default=(256, 256, 64))
    parser.add_argument("--tolerance", type=float, default=0.1)
    parser.add_argument(
        "--tmem_ld_warp_start",
        type=int,
        default=_DEFAULT_TMEM_LD_WARP_START,
        choices=range(0, 5),
        help=(
            "First contiguous TMEM-load warp. The example uses warp_idx %% 4 "
            "for TMEM/SP rows, so shifted ranges like 2..5 are valid."
        ),
    )
    args = parser.parse_args()
    verify(args.mnk, args.tolerance, args.tmem_ld_warp_start)
