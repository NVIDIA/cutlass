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

"""tcgen05.mma with A loaded into TMEM (``[a-tmem]`` PTX form) + ``.ashift`` test.

This file isolates two niche ``tcgen05.mma`` kwarg paths that share a common
A-from-TMEM staging pattern (FMHA BMM2-style):

  - **a_tmem**  — A staged into TMEM via :func:`~cutlass.primitives.tcgen05_st`, MMA
                  reads ``[a-tmem]`` (the PTX form required by ``.ashift``).
                  Verified against torch reference for the full K-loop.
  - **a_shift** — 2-MMA chain on the SAME A K-slice and SAME B K-slice.
                  MMA1 has ``a_shift=True`` (post-MMA shifts A TMEM rows down
                  by 1 within each 32-row sub-partition, last row kept).
                  MMA2 has ``enable_input_d=False`` so it OVERWRITES MMA1.
                  Final D = ``A_shifted @ B_slice`` — isolates the shift
                  effect from any accumulation.

Per-SP shift rule (not in public PTX ISA 9.1, observed on B200):
``shifted[r] = A[r+1]`` for ``r % 32 != 31``, else ``A[r]``.

Uses the FMHA BMM2 pattern (see
``examples/CuTeDSL/experimental/blackwell/kernel/attention/fmha_prefill.py``):
``prims.make_tmem_ptr`` for typed TMEM addressing, ``tmem_base + col_off``
arithmetic to advance by TMEM columns.

Tile sizes: ``M=128, N=128, K_TILE=32`` (TF32 K-granule = 8).

Public API (mirrors ``1cta_mma_basic.py``)::

    compile(ashift=False)   →  AOT-compile factory
    run(compiled_fn)        →  allocate A/B/C, call, return (c, a, b)
    verify(ashift=False)    →  compile + run + assert vs torch reference

To run::

    python CuTeDSL/experimental/primitives/tcgen05/1cta_mma_a_from_tmem.py
    python CuTeDSL/experimental/primitives/tcgen05/1cta_mma_a_from_tmem.py --ashift

"""

import argparse
import sys
from functools import lru_cache
from typing import Callable

import torch

from cutlass.experimental.primitives import Tcgen05InstrDesc

import cutlass
import cutlass.experimental.cuda as cuda
import cutlass.cute as cute
import cutlass.torch as cutlass_torch
from cutlass.cute.runtime import make_fake_compact_tensor
from cutlass.experimental import primitives as prims


_M_TILE = 128
_N_TILE = 128
_K_TILE = 32
_THREADS = 128
_SWZ = 2  # 128B XOR


def _check_sm100() -> bool:
    if not torch.cuda.is_available():
        return False
    cap = torch.cuda.get_device_capability()
    return cap[0] >= 10


def _build_smem_desc(smem, lead: int, stride: int) -> prims.Tcgen05SmemDesc:
    return prims.Tcgen05SmemDesc.build(
        start_address=smem,
        leading_byte_offset=lead * 16,
        stride_byte_offset=stride * 16,
        layout=_SWZ,
    )


# ---------------------------------------------------------------------------
# Kernel
# ---------------------------------------------------------------------------


@cute.kernel
def kernel(
    tma_a_desc: cutlass.GridConstant[cuda.TensorMap],
    tma_b_desc: cutlass.GridConstant[cuda.TensorMap],
    c_ptr: cute.Tensor,
    num_k_tiles: cutlass.Int32,
    ASHIFT: cutlass.Constexpr,
) -> None:
    smem_a = cutlass.Array(
        cutlass.Float32, _M_TILE * _K_TILE, space=cutlass.AddressSpace.smem
    )
    smem_b = cutlass.Array(
        cutlass.Float32, _N_TILE * _K_TILE, space=cutlass.AddressSpace.smem
    )
    full_mbar = cutlass.Array(cutlass.Int64, 1, space=cutlass.AddressSpace.smem)
    acc_mbar = cutlass.Array(cutlass.Int64, 1, space=cutlass.AddressSpace.smem)
    tmem_ptr_i32 = cutlass.Array(cutlass.Int32, 1, space=cutlass.AddressSpace.smem)

    warp_idx = cute.arch.warp_idx()
    tidx, _, _ = cute.arch.thread_idx()
    bidx, bidy, _ = cute.arch.block_idx()

    coord_m = bidx * cutlass.Int32(_M_TILE)
    coord_n = bidy * cutlass.Int32(_N_TILE)

    # TMEM layout (columns):
    #   [0, 128)   — D accumulator (4 subtiles × 32 cols for N=128)
    #   [128, 160) — A staging region (32 fp32 cols for K=32 TF32)
    d_col_off = 0
    a_col_off = 128
    num_tmem_cols = 256

    idesc = Tcgen05InstrDesc.build(
        c_dtype=cutlass.Float32,
        a_dtype=cutlass.Float32,
        b_dtype=cutlass.Float32,
        n_dim=_N_TILE,
        m_dim=_M_TILE,
    )

    if warp_idx == 0:
        if prims.elect_sync():
            prims.mbarrier_init(full_mbar, 1)
            prims.mbarrier_init(acc_mbar, 1)
    prims.fence_mbarrier_init()
    prims.barrier_cta_sync(0)

    if warp_idx == 0:
        prims.tcgen05_alloc(tmem_ptr_i32, num_tmem_cols, group="cta_1")
    prims.barrier_cta_sync(0)

    # FMHA-canonical TMEM Array pointer (not raw inttoptr).
    tmem_base = prims.make_tmem_ptr(tmem_ptr_i32.load(), cutlass.Int8)
    prims.tcgen05_relinquish_alloc_permit(group="cta_1")

    a_ptr = tma_a_desc.get_ptr()
    b_ptr = tma_b_desc.get_ptr()
    tma_load_bytes = tma_a_desc.global_tx_bytes() + tma_b_desc.global_tx_bytes()

    lead = _K_TILE * 4 // 16
    stride = 8 * _K_TILE * 4 // 16

    # --- TMA loads A and B into SMEM ---
    if warp_idx == 0:
        if prims.elect_sync():
            prims.mbarrier_arrive_expect_tx(full_mbar, tma_load_bytes)
            prims.cp_async_bulk_tensor_shared_cta_global(
                smem_a,
                a_ptr,
                (cutlass.Int32(0), coord_m),
                full_mbar,
            )
            prims.cp_async_bulk_tensor_shared_cta_global(
                smem_b,
                b_ptr,
                (cutlass.Int32(0), coord_n),
                full_mbar,
            )

    while not prims.mbarrier_try_wait_parity(full_mbar, cutlass.Int32(0)):
        pass
    prims.barrier_cta_sync(0)

    # --- Stage A from SMEM into TMEM via tcgen05_st ---
    # Each warp stores its 32 M-rows: lane L of warp W reads row (W*32+L) of A
    # from SMEM (32 fp32 cols) and stores them as 32 TMEM cols at sp=W, row=L.
    lane = tidx % cutlass.Int32(32)
    m_row = warp_idx * cutlass.Int32(32) + lane
    a_smem_row_ptr = smem_a.data_ptr() + m_row * cutlass.Int32(_K_TILE)
    a_vec = a_smem_row_ptr.load(count=32, alignment=16)

    tmem_a_base = tmem_base.subview(a_col_off)
    prims.tcgen05_st(
        "32x32b",
        tmem_a_base,
        a_vec,
    )
    prims.tcgen05_wait(prims.Tcgen05Wait.STORE)
    prims.barrier_cta_sync(0)

    # --- MMA: D = A_tmem @ B_smem (with optional a_shift) ---
    tmem_d = tmem_base.subview(d_col_off)

    if warp_idx == 0:
        desc_b_root = _build_smem_desc(smem_b, lead, stride)
        if cutlass.const_expr(ASHIFT == 1):
            # MMA1 (.ashift): A_orig @ B_slice0, then shifts A TMEM by 1 row.
            # MMA2 (no shift, enable_input_d=False): OVERWRITES → final D =
            # A_shifted @ B_slice0.  Both MMAs target the SAME A K-slice
            # and SAME B K-slice, so the result isolates the shift.
            tmem_a_0 = tmem_base.subview(a_col_off)
            if prims.elect_sync():
                prims.tcgen05_mma(
                    prims.Tcgen05MMAKind.TF32,
                    prims.CTAGroup.CTA_1,
                    tmem_d,
                    tmem_a_0,
                    desc_b_root,
                    idesc,
                    False,
                    a_shift=True,
                )
            if prims.elect_sync():
                prims.tcgen05_mma(
                    prims.Tcgen05MMAKind.TF32,
                    prims.CTAGroup.CTA_1,
                    tmem_d,
                    tmem_a_0,
                    desc_b_root,
                    idesc,
                    False,
                    a_shift=None,
                )
        else:
            # a_tmem: full K-loop, one MMA per K-granule, no shift.
            nkb = _K_TILE // 8  # TF32 K-granule = 8
            k_step_bytes: cutlass.Constexpr[int] = 8 * 4
            for kb in cutlass.range_constexpr(nkb):
                tmem_a_kb = tmem_base.subview((a_col_off + kb * 8))
                if prims.elect_sync():
                    desc_b = desc_b_root.advance_start_address(k_step_bytes * kb)
                    prims.tcgen05_mma(
                        prims.Tcgen05MMAKind.TF32,
                        prims.CTAGroup.CTA_1,
                        tmem_d,
                        tmem_a_kb,
                        desc_b,
                        idesc,
                        kb > 0,
                        a_shift=None,
                    )

        if prims.elect_sync():
            prims.tcgen05_commit(acc_mbar, group=prims.CTAGroup.CTA_1)

    # --- Epilogue: all 4 warps read D from TMEM ---
    prims.barrier_cta_sync(0)
    while not prims.mbarrier_try_wait_parity(acc_mbar, 0):
        pass

    tmem_base_raw = tmem_ptr_i32.load()
    base_col_raw = tmem_base_raw & cutlass.Int32(0xFFFF)
    base_row_raw = tmem_base_raw >> cutlass.Int32(16)
    warp_row = base_row_raw + warp_idx * cutlass.Int32(32)
    d_addr = (warp_row << cutlass.Int32(16)) | (base_col_raw + cutlass.Int32(d_col_off))

    gC = c_ptr.iterator.raw_ptr()
    n_stride = c_ptr.shape[1]
    subtile_cnt = _N_TILE // 32

    for sub in cutlass.range_constexpr(subtile_cnt):
        tmem_sub = cutlass.inttoptr(
            d_addr + cutlass.Int32(sub * 32), 6, cutlass.Float32
        )
        c_vec = prims.tcgen05_ld(
            "32x32b",
            tmem_sub,
            num=32,
        )
        prims.tcgen05_wait(prims.Tcgen05Wait.LOAD)
        row = coord_m + tidx
        col = coord_n + cutlass.Int32(sub * 32)
        (gC + row * n_stride + col).store(c_vec, alignment=16)

    prims.tcgen05_fence(prims.Tcgen05Fence.BEFORE_THREAD_SYNC)
    prims.barrier_cta_sync(0)
    if warp_idx == 0:
        prims.tcgen05_dealloc(
            tmem_base,
            num_tmem_cols,
            group="cta_1",
        )


# ---------------------------------------------------------------------------
# Host
# ---------------------------------------------------------------------------


@cute.jit
def host(
    a: cute.Tensor,
    b: cute.Tensor,
    c: cute.Tensor,
    num_k_tiles: cutlass.Int32,
    ASHIFT: cutlass.Constexpr,
) -> None:
    # No swizzle for A so the per-row register load can use simple stride.
    tma_a = cuda.create_tensor_map_tiled(
        global_address=a.iterator.toint(),
        dtype=cutlass.Float32,
        global_dims=[a.shape[1], a.shape[0]],
        global_strides=[a.shape[1] * 4 // 16],
        box_dims=[_K_TILE, _M_TILE],
        swizzle=cuda.TensorMapSwizzle.none,
    )
    tma_b = cuda.create_tensor_map_tiled(
        global_address=b.iterator.toint(),
        dtype=cutlass.Float32,
        global_dims=[b.shape[1], b.shape[0]],
        global_strides=[b.shape[1] * 4 // 16],
        box_dims=[_K_TILE, _N_TILE],
        swizzle=cuda.TensorMapSwizzle.s128b,
    )
    grid_m = cute.ceil_div(a.shape[0], _M_TILE)
    grid_n = cute.ceil_div(b.shape[0], _N_TILE)
    kernel(tma_a, tma_b, c, num_k_tiles, ASHIFT).launch(
        grid=(grid_m, grid_n, 1),
        block=(_THREADS, 1, 1),
    )


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------


@lru_cache(maxsize=None)
def compile(ashift: bool = False) -> Callable:  # noqa: A001
    fake_a = make_fake_compact_tensor(
        cutlass.Float32, (_M_TILE, _K_TILE), stride_order=(1, 0), assumed_align=16
    )
    fake_b = make_fake_compact_tensor(
        cutlass.Float32, (_N_TILE, _K_TILE), stride_order=(1, 0), assumed_align=16
    )
    fake_c = make_fake_compact_tensor(
        cutlass.Float32, (_M_TILE, _N_TILE), stride_order=(1, 0), assumed_align=16
    )
    return cute.compile(
        host,
        fake_a,
        fake_b,
        fake_c,
        1,  # num_k_tiles (single tile for these tests)
        1 if ashift else 0,
        options="--enable-tvm-ffi",
    )


def run(compiled_fn: Callable):
    """Allocate A/B/C, call ``compiled_fn``, return ``(c, a, b)``."""
    torch.manual_seed(42)
    a = (
        torch.empty(_M_TILE, _K_TILE, dtype=torch.int32)
        .random_(-2, 2)
        .to(dtype=cutlass_torch.dtype(cutlass.Float32), device="cuda")
    )
    b = (
        torch.empty(_N_TILE, _K_TILE, dtype=torch.int32)
        .random_(-2, 2)
        .to(dtype=cutlass_torch.dtype(cutlass.Float32), device="cuda")
    )
    c = torch.zeros(
        _M_TILE, _N_TILE, dtype=cutlass_torch.dtype(cutlass.Float32), device="cuda"
    )
    compiled_fn(a, b, c, 1)
    torch.cuda.synchronize()
    return c, a, b


def _reference(a: torch.Tensor, b: torch.Tensor, ashift: bool) -> torch.Tensor:
    if ashift:
        # .ashift shifts A rows down by 1 within each 32-row TMEM SP; the
        # last row of each SP is preserved. Both MMAs use the same B[:, 0:8]
        # K-slice; MMA2 has enable_input_d=False so final D = A_shifted @ B[:, 0:8].
        af = a.float()
        a_shifted = af.clone()
        a_shifted[:-1] = af[1:]
        a_shifted[31::32] = af[31::32]
        b_slice = b[:, 0:8].float()
        ref = torch.einsum("mk,nk->mn", a_shifted[:, 0:8], b_slice)
        return ref.to(a.dtype)
    return torch.einsum("mk,nk->mn", a.float(), b.float()).to(a.dtype)


def verify(ashift: bool = False) -> None:
    label = "a_shift" if ashift else "a_tmem"
    compiled_fn = compile(ashift=ashift)
    print(
        f"Compile kernel ({label}, M={_M_TILE}, N={_N_TILE}, K={_K_TILE}) OK",
        flush=True,
    )
    c, a, b = run(compiled_fn)
    print(f"Run kernel ({label}) OK", flush=True)
    ref = _reference(a, b, ashift)
    torch.testing.assert_close(c, ref, atol=0.1, rtol=1e-5)
    print(f"verify ({label}): PASS", flush=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument(
        "--ashift",
        action="store_true",
        help="Run the .ashift 2-MMA chain (default: a_tmem K-loop).",
    )
    args = parser.parse_args()
    if not _check_sm100():
        print("SKIP: SM100+ (Blackwell) GPU required")
        sys.exit(0)
    verify(ashift=args.ashift)
