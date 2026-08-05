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

"""
SM100 tcgen05 MMA pipeline lifecycle (Blackwell, sm_100a).

Demonstrates the complete tcgen05 MMA lifecycle from allocation through
epilogue, focusing on the API sequence and correctness constraints that are
easy to get wrong:

  1. ``tcgen05_alloc`` — allocate TMEM (**outside** ``elect_sync`` — warp-collective)
  2. ``tcgen05_relinquish_alloc_permit`` — release permit (**outside** ``elect_sync`` — warp-collective)
  3. K-loop:

     - root ``Tcgen05SmemDesc.build`` values plus byte-offset
       ``advance_start_address`` stage/K-block advances for A/B SMEM descriptors
     - ``tcgen05_mma`` — issue MMA (``scale_d=False`` on k=0, ``True`` for k>0)
     - ``tcgen05_commit(empty_bar)`` — TC signals when SMEM drained (inside ``elect_sync``)

  4. After K-loop: ``tcgen05_commit(acc_mbar)`` — signal accumulator ready
  5. Epilogue: ``tcgen05_ld`` → ``tcgen05_wait(LOAD)`` → read registers → store
  6. ``tcgen05_dealloc`` — free TMEM

Tile dimensions: M=128, N=128, K_TILE=64 per k-tile.  CTA_1 (single CTA).
Uses TMA loads for A and B, direct global stores for C in the epilogue.

Public API (mirrors ``examples/template_kernel.py``):
  - :func:`compile` — AOT factory keyed on ``NUM_STAGES``.
  - :func:`run`     — allocate A/B/C, call compiled fn, return ``(c, a, b)``.
  - :func:`verify`  — compile + run + assert vs torch reference.

Requires SM100+ (Blackwell) GPU.

To run::

    python CuTeDSL/experimental/primitives/tcgen05/1cta_mma_pipeline.py
    python CuTeDSL/experimental/primitives/tcgen05/1cta_mma_pipeline.py --NUM_STAGES 4 --num_k_tiles 8

"""

import argparse
from functools import lru_cache
from typing import Callable

import torch

from cutlass.experimental.primitives import Tcgen05InstrDesc
import cutlass
import cutlass.experimental.cuda as cuda
import cutlass.cute as cute
from cutlass.cute.runtime import make_fake_compact_tensor
from cutlass.experimental import primitives as prims


# ---------------------------------------------------------------------------
# Kernel Configurations — fixed
# ---------------------------------------------------------------------------

_M_TILE: int = 128
_N_TILE: int = 128
_K_TILE: int = 64
_MMA_K: int = 16
_K_BLOCKS: int = _K_TILE // _MMA_K  # 4 MMAs per k-tile
_THREADS: int = 128
_SWZ: int = 2  # 128B XOR — required for f16
_TMEM_COLS: int = (_N_TILE // 8) * 32  # 512 cols (full TMEM for N=128)

_BYTES_A: int = _M_TILE * _K_TILE * 2
_BYTES_B: int = _N_TILE * _K_TILE * 2
_A_STAGE_OFFSET_BYTES: int = _BYTES_A
_B_STAGE_OFFSET_BYTES: int = _BYTES_B
_K_BLOCK_OFFSET_BYTES: int = _MMA_K * 2

_LBO_BYTES: int = 1 * 16
_SBO_BYTES: int = 64 * 16

_EPI_SUBTILES: int = _N_TILE // 32
_EPI_REPX: int = 32
_EPI_VEC: int = 8
assert _N_TILE % 32 == 0

_IDESC = Tcgen05InstrDesc.build(c_dtype=cutlass.Float32, n_dim=_N_TILE, m_dim=_M_TILE)


# ---------------------------------------------------------------------------
# Kernel Configurations — tunable
# ---------------------------------------------------------------------------

_DEFAULT_NUM_STAGES: int = 2  # pipeline depth (compile-time)

# ---------------------------------------------------------------------------
# Default problem sizes
# ---------------------------------------------------------------------------

_DEFAULT_NUM_K_TILES: int = 4  # runtime cutlass.Int32


# ---------------------------------------------------------------------------
# Device kernel
# ---------------------------------------------------------------------------


@cute.kernel
def kernel(
    tma_a_desc: cutlass.GridConstant[cuda.TensorMap],
    tma_b_desc: cutlass.GridConstant[cuda.TensorMap],
    c_ptr: cute.Tensor,
    num_k_tiles: cutlass.Int32,
    coord_m: cutlass.Int32,
    coord_n: cutlass.Int32,
    NUM_STAGES: cutlass.Constexpr,
):
    """tcgen05 GEMM kernel: C = A @ B^T using pipelined MMA."""
    smem_a = cutlass.Array(
        cutlass.Float16,
        NUM_STAGES * _M_TILE * _K_TILE,
        space=cutlass.AddressSpace.smem,
        alignment=128,
    )
    smem_b = cutlass.Array(
        cutlass.Float16,
        NUM_STAGES * _N_TILE * _K_TILE,
        space=cutlass.AddressSpace.smem,
        alignment=128,
    )
    smem_a_ptr = smem_a.data_ptr()
    smem_b_ptr = smem_b.data_ptr()

    mbar = cutlass.Array(
        cutlass.Int64, 2 * NUM_STAGES + 1, space=cutlass.AddressSpace.smem, alignment=8
    )
    full_bar = mbar
    empty_bar = mbar.subview(NUM_STAGES)
    acc_mbar = mbar.subview(2 * NUM_STAGES)

    tmem_addr_smem = cutlass.Array(cutlass.Int32, 1, space=cutlass.AddressSpace.smem)

    warp_idx = cute.arch.warp_idx()
    tidx, _, _ = cute.arch.thread_idx()

    if warp_idx == 0:
        if prims.elect_sync():
            for i in cutlass.range_constexpr(NUM_STAGES):
                prims.mbarrier_init(full_bar.subview(i), 1)
                prims.mbarrier_init(empty_bar.subview(i), 1)
            prims.mbarrier_init(acc_mbar, 1)
    prims.fence_mbarrier_init()
    prims.barrier_cta_sync(0)

    if warp_idx == 0:
        prims.tcgen05_alloc(tmem_addr_smem, _TMEM_COLS, group="cta_1")
        prims.tcgen05_relinquish_alloc_permit(group="cta_1")
    prims.barrier_cta_sync(0)

    tmem_addr = tmem_addr_smem.load()
    tmem_ptr = prims.make_tmem_ptr(tmem_addr, cutlass.Float32)

    a_ptr = tma_a_desc.get_ptr()
    b_ptr = tma_b_desc.get_ptr()

    # Root descriptors describe the physical layout of the whole SMEM ring.
    # Stage and K-block motion below uses byte offsets through the public API.
    desc_a_root = prims.Tcgen05SmemDesc.build(
        start_address=smem_a,
        leading_byte_offset=_LBO_BYTES,
        stride_byte_offset=_SBO_BYTES,
        layout=_SWZ,
    )
    desc_b_root = prims.Tcgen05SmemDesc.build(
        start_address=smem_b,
        leading_byte_offset=_LBO_BYTES,
        stride_byte_offset=_SBO_BYTES,
        layout=_SWZ,
    )

    # Producer (warp 0): TMA loads A and B
    if warp_idx == 0:
        for k in cutlass.range(num_k_tiles):
            s = k % NUM_STAGES
            prod_parity = cutlass.Int32(1) ^ (
                (k // cutlass.Int32(NUM_STAGES)) & cutlass.Int32(1)
            )

            while not prims.mbarrier_try_wait_parity(
                empty_bar.subview(s), prod_parity, time_limit=10_000_000
            ):
                pass

            if prims.elect_sync():
                k_coord = k * _K_TILE
                prims.mbarrier_arrive_expect_tx(
                    full_bar.subview(s),
                    tma_a_desc.global_tx_bytes() + tma_b_desc.global_tx_bytes(),
                )

                prims.cp_async_bulk_tensor_shared_cta_global(
                    smem_a_ptr + s * _M_TILE * _K_TILE,
                    a_ptr,
                    (k_coord, coord_m),
                    full_bar.subview(s),
                )
                prims.cp_async_bulk_tensor_shared_cta_global(
                    smem_b_ptr + s * _N_TILE * _K_TILE,
                    b_ptr,
                    (k_coord, coord_n),
                    full_bar.subview(s),
                )

    # Consumer (warp 1): MMA k-loop
    if warp_idx == 1:
        scale_d = cutlass.Boolean(False)

        for k in cutlass.range(num_k_tiles):
            s = k % NUM_STAGES
            cons_parity = (k // cutlass.Int32(NUM_STAGES)) & cutlass.Int32(1)

            while not prims.mbarrier_try_wait_parity(
                full_bar.subview(s), cons_parity, time_limit=10_000_000
            ):
                pass

            desc_a_base = desc_a_root.advance_start_address(
                cutlass.Int64(s * _A_STAGE_OFFSET_BYTES)
            )
            desc_b_base = desc_b_root.advance_start_address(
                cutlass.Int64(s * _B_STAGE_OFFSET_BYTES)
            )

            for kb in cutlass.range_constexpr(_K_BLOCKS):
                inc = cutlass.Int64(_K_BLOCK_OFFSET_BYTES * kb)
                if prims.elect_sync():
                    prims.tcgen05_mma(
                        prims.Tcgen05MMAKind.F16,
                        prims.CTAGroup.CTA_1,
                        tmem_ptr,
                        desc_a_base.advance_start_address(inc),
                        desc_b_base.advance_start_address(inc),
                        _IDESC,
                        scale_d,
                    )
                scale_d = cutlass.Boolean(True)

            if prims.elect_sync():
                prims.tcgen05_commit(empty_bar.subview(s), group=prims.CTAGroup.CTA_1)

        if prims.elect_sync():
            prims.tcgen05_commit(acc_mbar, group=prims.CTAGroup.CTA_1)

    prims.barrier_cta_sync(0)
    while not prims.mbarrier_try_wait_parity(acc_mbar, 0, time_limit=10_000_000):
        pass

    # Epilogue
    lane = tidx % 32
    c_dst = c_ptr.iterator.raw_ptr()

    base_col = tmem_addr & 0xFFFF
    row = warp_idx * 32 + lane
    for sub in cutlass.range_constexpr(_EPI_SUBTILES):
        col_off = sub * 32
        tmem_sub = prims.make_tmem_ptr_from_warp_row_col(
            tmem_addr, warp_idx, base_col + col_off, cutlass.Float32
        )
        c_vec = prims.tcgen05_ld(
            "32x32b",
            tmem_sub,
            num=_EPI_REPX,
        )
        prims.tcgen05_wait(prims.Tcgen05Wait.LOAD)

        for j in cutlass.range_constexpr(_EPI_REPX // _EPI_VEC):
            vec = c_vec[j * _EPI_VEC : (j + 1) * _EPI_VEC]
            lin_idx = (coord_m + row) * _N_TILE + coord_n + col_off + j * _EPI_VEC
            (c_dst + lin_idx).store(vec, alignment=16)

    prims.tcgen05_fence(prims.Tcgen05Fence.BEFORE_THREAD_SYNC)
    prims.barrier_cta_sync(0)
    if warp_idx == 0:
        prims.tcgen05_dealloc(tmem_ptr, _TMEM_COLS, group="cta_1")


# ---------------------------------------------------------------------------
# Host launcher
# ---------------------------------------------------------------------------


@cute.jit
def host(
    a: cute.Tensor,
    b: cute.Tensor,
    c: cute.Tensor,
    num_k_tiles: cutlass.Int32,
    NUM_STAGES: cutlass.Constexpr,
):
    """Build TMA descriptors and launch GEMM kernel."""
    tma_a_desc = cuda.create_tensor_map_tiled_from_view(
        a,
        box_dims=(_M_TILE, _K_TILE),
        swizzle=cuda.TensorMapSwizzle.s128b,
        stride_order=(1, 0),
    )
    tma_b_desc = cuda.create_tensor_map_tiled_from_view(
        b,
        box_dims=(_N_TILE, _K_TILE),
        swizzle=cuda.TensorMapSwizzle.s128b,
        stride_order=(1, 0),
    )
    kernel(tma_a_desc, tma_b_desc, c, num_k_tiles, 0, 0, NUM_STAGES).launch(
        grid=(1, 1, 1), block=(_THREADS, 1, 1)
    )


# ---------------------------------------------------------------------------
# Compile factory
# ---------------------------------------------------------------------------


@lru_cache(maxsize=None)
def compile(NUM_STAGES: int = _DEFAULT_NUM_STAGES) -> Callable:  # noqa: A001
    """AOT-compile :func:`host`; cache by ``NUM_STAGES``.

    ``num_k_tiles`` (and hence K) stays runtime; M and N are also symbolic.
    """
    sym_m = cute.sym_int64()
    sym_n = cute.sym_int64()
    sym_k = cute.sym_int64()
    fake_a = make_fake_compact_tensor(
        cutlass.Float16, (sym_m, sym_k), stride_order=(1, 0), assumed_align=16
    )
    fake_b = make_fake_compact_tensor(
        cutlass.Float16, (sym_n, sym_k), stride_order=(1, 0), assumed_align=16
    )
    fake_c = make_fake_compact_tensor(
        cutlass.Float32, (sym_m, sym_n), stride_order=(1, 0), assumed_align=16
    )
    fake_num_k_tiles = cutlass.Int32(0)
    return cute.compile(
        host,
        fake_a,
        fake_b,
        fake_c,
        fake_num_k_tiles,
        NUM_STAGES,
        options="--enable-tvm-ffi",
    )


# ---------------------------------------------------------------------------
# Run
# ---------------------------------------------------------------------------


def run(
    compiled_fn: Callable,
    num_k_tiles: int = _DEFAULT_NUM_K_TILES,
) -> tuple[torch.Tensor, torch.Tensor, torch.Tensor]:
    """Allocate A/B/C, call compiled_fn, return ``(c, a, b)``."""
    if not torch.cuda.is_available():
        raise RuntimeError("CUDA GPU required")
    m = _M_TILE
    n = _N_TILE
    k = num_k_tiles * _K_TILE
    a = torch.randn(m, k, dtype=torch.float16, device="cuda")
    b = torch.randn(n, k, dtype=torch.float16, device="cuda")
    c = torch.zeros(m, n, dtype=torch.float32, device="cuda")
    compiled_fn(a, b, c, num_k_tiles)
    torch.cuda.synchronize()
    return c, a, b


# ---------------------------------------------------------------------------
# Verify
# ---------------------------------------------------------------------------


def verify(
    num_k_tiles: int = _DEFAULT_NUM_K_TILES,
    NUM_STAGES: int = _DEFAULT_NUM_STAGES,
) -> None:
    """Compile, run, and assert C == A @ B^T."""
    if not torch.cuda.is_available():
        raise RuntimeError("CUDA GPU required")
    cc = torch.cuda.get_device_capability()
    if cc[0] < 10:
        print(
            f"SKIP  tcgen05_pipeline requires SM100+ (Blackwell), got sm_{cc[0]}{cc[1]}"
        )
        return

    compiled_fn = compile(NUM_STAGES=NUM_STAGES)
    print(f"Compile kernel (NUM_STAGES={NUM_STAGES}) OK", flush=True)

    c, a, b = run(compiled_fn, num_k_tiles=num_k_tiles)
    print(
        f"Run kernel (num_k_tiles={num_k_tiles}, NUM_STAGES={NUM_STAGES}) OK",
        flush=True,
    )

    c_ref = a.float() @ b.float().T
    torch.testing.assert_close(c, c_ref, atol=1e-1, rtol=1e-2)
    max_err = (c - c_ref).abs().max().item()
    print(
        f"verify (M={_M_TILE} N={_N_TILE} K={num_k_tiles * _K_TILE}, "
        f"NUM_STAGES={NUM_STAGES}): PASS  max_err={max_err:.4f}"
    )


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    p = argparse.ArgumentParser(
        description="tcgen05 MMA pipeline lifecycle (SM100+)",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    p.add_argument(
        "--num_k_tiles",
        type=int,
        default=None,
        help="number of K tiles  [runtime cutlass.Int32]",
    )
    p.add_argument(
        "--NUM_STAGES",
        type=int,
        default=_DEFAULT_NUM_STAGES,
        help="pipeline depth  [compile-time cutlass.Constexpr]",
    )
    args = p.parse_args()

    if args.num_k_tiles is not None:
        verify(num_k_tiles=args.num_k_tiles, NUM_STAGES=args.NUM_STAGES)
    else:
        verify(num_k_tiles=_DEFAULT_NUM_K_TILES, NUM_STAGES=args.NUM_STAGES)
        verify(num_k_tiles=_DEFAULT_NUM_K_TILES * 2, NUM_STAGES=args.NUM_STAGES)
