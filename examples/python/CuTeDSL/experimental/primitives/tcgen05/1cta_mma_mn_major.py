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

"""CTA_1 tcgen05 MMA with MN-major A and B operands.

This example focuses on descriptor values for operands whose contiguous
dimension in SMEM is M/N, not K.  A is a global tensor shaped ``(K, M)``
with M contiguous and is consumed with ``a_major=1``.  B is a global tensor
shaped ``(K, N)`` with N contiguous and is consumed with ``b_major=1``.

Both operands use one 128B swizzle period per TMA copy, so each compact
MN-major group has 64 FP16 elements:

* A uses ``M_BOX=64``:
  ``A_LBO_BYTES = K_TILE * M_BOX * 2`` and
  ``A_SBO_BYTES = 8 * M_BOX * 2``.
* B uses ``N_BOX=64``:
  ``B_LBO_BYTES = K_TILE * N_BOX * 2`` and
  ``B_SBO_BYTES = 8 * N_BOX * 2``.

Usage::

    python CuTeDSL/experimental/primitives/tcgen05/1cta_mma_mn_major.py
    python CuTeDSL/experimental/primitives/tcgen05/1cta_mma_mn_major.py --tile_mn 64,64
    python CuTeDSL/experimental/primitives/tcgen05/1cta_mma_mn_major.py --mnk 256,256,128

"""

from __future__ import annotations

import argparse
import sys
from functools import lru_cache
from typing import Callable

import torch


import cutlass
import cutlass.experimental.cuda as cuda
import cutlass.cute as cute
from cutlass.cute.runtime import make_fake_compact_tensor
from cutlass.experimental import primitives as prims


_DEFAULT_TILE_MN: tuple[int, int] = (128, 128)
_K_TILE: int = 64
_M_BOX: int = 64
_N_BOX: int = 64
_MMA_K: int = 16
_THREADS: int = 128

_ELEM_BYTES: int = 2
_K_BLOCKS: int = _K_TILE // _MMA_K

_A_GROUP_ELEMS: int = _K_TILE * _M_BOX
_A_LBO_BYTES: int = _K_TILE * _M_BOX * _ELEM_BYTES
_A_SBO_BYTES: int = 8 * _M_BOX * _ELEM_BYTES
_A_K_STEP_BYTES: int = _MMA_K * _M_BOX * _ELEM_BYTES

_B_GROUP_ELEMS: int = _K_TILE * _N_BOX
_B_LBO_BYTES: int = _K_TILE * _N_BOX * _ELEM_BYTES
_B_SBO_BYTES: int = 8 * _N_BOX * _ELEM_BYTES
_B_K_STEP_BYTES: int = _MMA_K * _N_BOX * _ELEM_BYTES


def _check_sm100() -> bool:
    """Return True if current GPU is SM100+."""
    if not torch.cuda.is_available():
        return False
    cap = torch.cuda.get_device_capability()
    return cap[0] >= 10


@cute.kernel
def kernel(
    tma_a_desc: cutlass.GridConstant[cuda.TensorMap],
    tma_b_desc: cutlass.GridConstant[cuda.TensorMap],
    c_ptr: cute.Tensor,
    num_k_tiles: cutlass.Int64,
    M_TILE: cutlass.Constexpr[int],
    N_TILE: cutlass.Constexpr[int],
) -> None:
    """Compute C[M,N] = A[M,K] @ B[K,N] with A/B consumed MN-major."""
    smem_a = cutlass.Array(
        cutlass.Float16,
        M_TILE * _K_TILE,
        space=cutlass.AddressSpace.smem,
        alignment=128,
    )
    smem_b = cutlass.Array(
        cutlass.Float16,
        _K_TILE * N_TILE,
        space=cutlass.AddressSpace.smem,
        alignment=128,
    )
    full_mbar = cutlass.Array(
        cutlass.Int64, 1, space=cutlass.AddressSpace.smem, alignment=8
    )
    empty_mbar = cutlass.Array(
        cutlass.Int64, 1, space=cutlass.AddressSpace.smem, alignment=8
    )
    acc_mbar = cutlass.Array(
        cutlass.Int64, 1, space=cutlass.AddressSpace.smem, alignment=8
    )
    tmem_ptr_i32 = cutlass.Array(
        cutlass.Int32, 1, space=cutlass.AddressSpace.smem, alignment=4
    )

    warp_idx = cute.arch.warp_idx()
    tidx, _, _ = cute.arch.thread_idx()
    bidx, bidy, _ = cute.arch.block_idx()

    coord_m = bidx * M_TILE
    coord_n = bidy * N_TILE
    tmem_cols: cutlass.Constexpr[int] = (N_TILE // 8) * 32
    # ``global_tx_bytes()`` is the transaction size of a *single* TMA box, but
    # each k_tile issues one copy per compact MN-major group onto ``full_mbar``:
    # ``M_TILE // _M_BOX`` A-boxes and ``N_TILE // _N_BOX`` B-boxes.  The
    # expected-tx count must sum every box completion, otherwise the mbarrier
    # releases before all data lands and the MMA reads stale SMEM.
    tma_load_bytes = (M_TILE // _M_BOX) * tma_a_desc.global_tx_bytes() + (
        N_TILE // _N_BOX
    ) * tma_b_desc.global_tx_bytes()
    idesc = prims.Tcgen05InstrDesc.build(
        c_dtype=cutlass.Float32,
        a_dtype=cutlass.Float16,
        b_dtype=cutlass.Float16,
        n_dim=N_TILE,
        m_dim=M_TILE,
        a_major=1,
        b_major=1,
    )

    if warp_idx == 0:
        if prims.elect_sync():
            prims.mbarrier_init(full_mbar, 1)
            prims.mbarrier_init(empty_mbar, 1)
            prims.mbarrier_init(acc_mbar, 1)
    prims.fence_mbarrier_init()
    prims.barrier_cta_sync(0)

    if warp_idx == 0:
        prims.tcgen05_alloc(tmem_ptr_i32, tmem_cols, group="cta_1")
    prims.barrier_cta_sync(0)

    tmem_base_raw = tmem_ptr_i32.load()
    tmem_ptr = cutlass.inttoptr(tmem_base_raw, 6, cutlass.Float32)
    prims.tcgen05_relinquish_alloc_permit(group="cta_1")

    a_ptr = tma_a_desc.get_ptr()
    b_ptr = tma_b_desc.get_ptr()

    if warp_idx == 0:
        desc_a_root = prims.Tcgen05SmemDesc.build(
            start_address=smem_a,
            leading_byte_offset=_A_LBO_BYTES,
            stride_byte_offset=_A_SBO_BYTES,
            layout=prims.Tcgen05SmemSwizzle.SWIZZLE_128B,
        )
        desc_b_root = prims.Tcgen05SmemDesc.build(
            start_address=smem_b,
            leading_byte_offset=_B_LBO_BYTES,
            stride_byte_offset=_B_SBO_BYTES,
            layout=prims.Tcgen05SmemSwizzle.SWIZZLE_128B,
        )

        full_phase = 0
        empty_phase = 0
        for k_tile in cutlass.range(num_k_tiles):
            if prims.elect_sync():
                prims.mbarrier_arrive_expect_tx(full_mbar, tma_load_bytes)
                k_coord = k_tile * _K_TILE
                for m_group in cutlass.range_constexpr(M_TILE // _M_BOX):
                    prims.cp_async_bulk_tensor_shared_cta_global(
                        smem_a.subview(m_group * _A_GROUP_ELEMS),
                        a_ptr,
                        (coord_m + m_group * _M_BOX, k_coord),
                        full_mbar,
                    )
                for n_group in cutlass.range_constexpr(N_TILE // _N_BOX):
                    prims.cp_async_bulk_tensor_shared_cta_global(
                        smem_b.subview(n_group * _B_GROUP_ELEMS),
                        b_ptr,
                        (coord_n + n_group * _N_BOX, k_coord),
                        full_mbar,
                    )

            while not prims.mbarrier_try_wait_parity(
                full_mbar, full_phase, time_limit=10_000_000
            ):
                pass
            full_phase = full_phase ^ 1

            for kb in cutlass.range_constexpr(_K_BLOCKS):
                if prims.elect_sync():
                    prims.tcgen05_mma(
                        prims.Tcgen05MMAKind.F16,
                        prims.CTAGroup.CTA_1,
                        tmem_ptr,
                        desc_a_root.advance_start_address(_A_K_STEP_BYTES * kb),
                        desc_b_root.advance_start_address(_B_K_STEP_BYTES * kb),
                        idesc,
                        k_tile > 0 or kb > 0,
                    )

            if prims.elect_sync():
                prims.tcgen05_commit(empty_mbar, group=prims.CTAGroup.CTA_1)
            while not prims.mbarrier_try_wait_parity(
                empty_mbar, empty_phase, time_limit=10_000_000
            ):
                pass
            empty_phase = empty_phase ^ 1

        if prims.elect_sync():
            prims.tcgen05_commit(acc_mbar, group=prims.CTAGroup.CTA_1)

    prims.barrier_cta_sync(0)
    while not prims.mbarrier_try_wait_parity(acc_mbar, 0, time_limit=10_000_000):
        pass

    tmem_base = prims.TmemAddr(tmem_base_raw)
    base_col = tmem_base.col_id
    if cutlass.const_expr(M_TILE == 64):
        tmem_row = tmem_base.row_id
    else:
        tmem_row = tmem_base.row_id + warp_idx * 32
    gC = c_ptr.iterator.raw_ptr()
    n_stride = c_ptr.shape[1]
    lane = tidx % 32

    for sub in cutlass.range_constexpr(N_TILE // 32):
        col = coord_n + sub * 32
        tmem_sub = prims.TmemAddr.from_row_col(tmem_row, base_col + sub * 32).as_ptr(
            cutlass.Float32
        )
        c_tmp = prims.tcgen05_ld(
            "32x32b",
            tmem_sub,
            num=32,
        )
        prims.tcgen05_wait(prims.Tcgen05Wait.LOAD)
        if cutlass.const_expr(M_TILE == 64):
            if lane < 16:
                row = coord_m + warp_idx * 16 + lane
                (gC + row * n_stride + col).store(
                    c_tmp.to(cutlass.Float16), alignment=16
                )
        else:
            row = coord_m + tidx
            (gC + row * n_stride + col).store(c_tmp.to(cutlass.Float16), alignment=16)

    prims.tcgen05_fence(prims.Tcgen05Fence.BEFORE_THREAD_SYNC)
    prims.barrier_cta_sync(0)
    if warp_idx == 0:
        prims.tcgen05_dealloc(tmem_ptr, tmem_cols, group="cta_1")


@cute.jit
def host(
    a: cute.Tensor,
    b: cute.Tensor,
    c: cute.Tensor,
    M_TILE: cutlass.Constexpr[int],
    N_TILE: cutlass.Constexpr[int],
) -> None:
    """Build TMA descriptors and launch the MN-major A/B example."""
    tma_a = cuda.create_tensor_map_tiled(
        global_address=a.iterator.toint(),
        dtype=a.element_type,
        global_dims=[a.shape[1], a.shape[0]],
        global_strides=[a.shape[1] * _ELEM_BYTES // 16],
        box_dims=[_M_BOX, _K_TILE],
        swizzle=cuda.TensorMapSwizzle.s128b,
    )
    tma_b = cuda.create_tensor_map_tiled(
        global_address=b.iterator.toint(),
        dtype=b.element_type,
        global_dims=[b.shape[1], b.shape[0]],
        global_strides=[b.shape[1] * _ELEM_BYTES // 16],
        box_dims=[_N_BOX, _K_TILE],
        swizzle=cuda.TensorMapSwizzle.s128b,
    )

    grid_m = cute.ceil_div(a.shape[1], M_TILE)
    grid_n = cute.ceil_div(b.shape[1], N_TILE)
    num_k_tiles = a.shape[0] // _K_TILE
    kernel(tma_a, tma_b, c, num_k_tiles, M_TILE, N_TILE).launch(
        grid=(grid_m, grid_n, 1), block=(_THREADS, 1, 1)
    )


def _validate_tile_mn(tile_mn: tuple[int, int]) -> None:
    tile_m, tile_n = tile_mn
    if tile_m not in (64, 128):
        raise ValueError(f"tile M={tile_m} must be 64 or 128")
    if tile_n not in (64, 128):
        raise ValueError(f"tile N={tile_n} must be 64 or 128")
    if tile_m % _M_BOX != 0:
        raise ValueError(f"tile M={tile_m} must be divisible by M_BOX={_M_BOX}")
    if tile_n % _N_BOX != 0:
        raise ValueError(f"tile N={tile_n} must be divisible by N_BOX={_N_BOX}")


def _validate_mnk(mnk: tuple[int, int, int], tile_mn: tuple[int, int]) -> None:
    m, n, k = mnk
    tile_m, tile_n = tile_mn
    if m % tile_m != 0:
        raise ValueError(f"M={m} must be a multiple of tile M={tile_m}")
    if n % tile_n != 0:
        raise ValueError(f"N={n} must be a multiple of tile N={tile_n}")
    if k % _K_TILE != 0:
        raise ValueError(f"K={k} must be a multiple of {_K_TILE}")


@lru_cache(maxsize=None)
def compile(tile_mn: tuple[int, int] = _DEFAULT_TILE_MN) -> Callable:  # noqa: A001
    """AOT-compile the fixed CTA_1 MN-major A/B kernel."""
    _validate_tile_mn(tile_mn)
    tile_m, tile_n = tile_mn
    sym_m = cute.sym_int64(divisibility=tile_m)
    sym_n = cute.sym_int64(divisibility=tile_n)
    sym_k = cute.sym_int64(divisibility=_K_TILE)
    fake_a = make_fake_compact_tensor(
        cutlass.Float16, (sym_k, sym_m), stride_order=(1, 0), assumed_align=16
    )
    fake_b = make_fake_compact_tensor(
        cutlass.Float16, (sym_k, sym_n), stride_order=(1, 0), assumed_align=16
    )
    fake_c = make_fake_compact_tensor(
        cutlass.Float16, (sym_m, sym_n), stride_order=(1, 0), assumed_align=16
    )
    return cute.compile(
        host,
        fake_a,
        fake_b,
        fake_c,
        tile_m,
        tile_n,
        options="--enable-tvm-ffi",
    )


def _make_inputs(
    m: int, n: int, k: int
) -> tuple[torch.Tensor, torch.Tensor, torch.Tensor]:
    torch.manual_seed(42)
    a = (
        torch.empty(k, m, dtype=torch.int32)
        .random_(-2, 2)
        .to(dtype=torch.float16, device="cuda")
    )
    b = (
        torch.empty(k, n, dtype=torch.int32)
        .random_(-2, 2)
        .to(dtype=torch.float16, device="cuda")
    )
    c = torch.zeros(m, n, dtype=torch.float16, device="cuda")
    return a, b, c


def run(
    *,
    compiled_fn: Callable | None = None,
    mnk: tuple[int, int, int] = (128, 128, 128),
    tile_mn: tuple[int, int] = _DEFAULT_TILE_MN,
) -> tuple[torch.Tensor, torch.Tensor, torch.Tensor]:
    """Run the MN-major A/B example and return ``(c, a, b)``."""
    _validate_tile_mn(tile_mn)
    _validate_mnk(mnk, tile_mn)
    if compiled_fn is None:
        compiled_fn = compile(tile_mn)
    m, n, k = mnk
    a, b, c = _make_inputs(m, n, k)
    compiled_fn(a, b, c)
    torch.cuda.synchronize()
    return c, a, b


def verify(
    *,
    mnk: tuple[int, int, int] = (128, 128, 128),
    tile_mn: tuple[int, int] = _DEFAULT_TILE_MN,
) -> None:
    """Compile, run, and compare with a torch reference."""
    _validate_tile_mn(tile_mn)
    _validate_mnk(mnk, tile_mn)
    print(
        "Descriptor constants: "
        f"A(LBO={_A_LBO_BYTES}, SBO={_A_SBO_BYTES}, K_STEP={_A_K_STEP_BYTES}) "
        f"B(LBO={_B_LBO_BYTES}, SBO={_B_SBO_BYTES}, K_STEP={_B_K_STEP_BYTES})",
        flush=True,
    )
    compiled_fn = compile(tile_mn)
    print(f"Compile kernel (tile_mn={tile_mn}, mnk={mnk}) OK", flush=True)
    c, a, b = run(compiled_fn=compiled_fn, mnk=mnk, tile_mn=tile_mn)
    print(f"Run kernel (tile_mn={tile_mn}, mnk={mnk}) OK", flush=True)
    ref = torch.einsum("km,kn->mn", a.float(), b.float()).to(torch.float16)
    torch.testing.assert_close(c, ref, atol=0.1, rtol=1e-5)
    print(f"verify (tile_mn={tile_mn}, mnk={mnk}): PASS", flush=True)


def _parse_mnk(value: str) -> tuple[int, int, int]:
    parts = tuple(int(x) for x in value.split(","))
    if len(parts) != 3:
        raise argparse.ArgumentTypeError("--mnk must be M,N,K")
    return parts


def _parse_tile_mn(value: str) -> tuple[int, int]:
    parts = tuple(int(x) for x in value.split(","))
    if len(parts) != 2:
        raise argparse.ArgumentTypeError("--tile_mn must be M_TILE,N_TILE")
    return parts


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument(
        "--tile_mn",
        type=_parse_tile_mn,
        default=_DEFAULT_TILE_MN,
        help="Compile-time tile shape M_TILE,N_TILE.",
    )
    parser.add_argument(
        "--mnk",
        type=_parse_mnk,
        default=(128, 128, 128),
        help="Runtime problem size M,N,K.",
    )
    args = parser.parse_args()

    if not _check_sm100():
        print("SKIP: SM100+ (Blackwell) GPU required")
        sys.exit(0)

    verify(mnk=args.mnk, tile_mn=args.tile_mn)
