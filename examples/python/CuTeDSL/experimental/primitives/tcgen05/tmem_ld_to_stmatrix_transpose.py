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
TMEM epilogue conversion into stmatrix transpose stores and TMA store output.

Use this file when the kernel has f32 accumulator values in TMEM and the
question is how values returned by ``tcgen05_ld`` become 32-bit ``stmatrix``
source words.  Four epilogue warps cover the four TMEM row datapaths for a
128x64 accumulator tile.  The runnable kernel seeds TMEM from a host random f32
source with row-major ``tcgen05_st("32x32b")`` setup stores, then drains 16x16
fragments into swizzled SMEM and publishes a 64x128 transposed output tile with
TMA store.

``stmatrix`` source operands are always 32-bit register words.  The
``16x256b.x2`` TMEM load returns eight f32 values per lane: conversion to b16
leaves four source words for x4 ``stmatrix``, while conversion to fp8 leaves
two source words for x2 M16N8 ``stmatrix``.  b16 outputs cover fp16, bf16, and
i16; b8 outputs cover fp8 e4m3/e5m2.  32b output should use vector stores or
narrow first, and 4b output needs a packed sub-byte path.

This example intentionally focuses on ``MMALayout.COL`` / transposed output.
Non-transposed final output usually uses vector stores unless a downstream
matrix-fragment consumer specifically wants ``stmatrix`` ROW layout.
B16 output is staged as two 64-column ``s128b`` pages so each ``stmatrix``
group sees conflict-free 16B row addresses; b8 output uses a single 128-column
``s128b`` tile.  Both layouts are TMA-stored to the public output tensor.

Public API:
  - :func:`compile` -- AOT factory keyed on ``OUT_DTYPE``.
  - :func:`run`     -- allocate random source/output, run, return ``(dst, src)``.
  - :func:`verify`  -- compile + run + assert ``dst == src.to(OUT_DTYPE).T``.

To run::

    python CuTeDSL/experimental/primitives/tcgen05/tmem_ld_to_stmatrix_transpose.py
    python CuTeDSL/experimental/primitives/tcgen05/tmem_ld_to_stmatrix_transpose.py --out-dtype fp8_e4m3

"""

from __future__ import annotations

import argparse
from functools import lru_cache
from typing import Callable

import torch

from cutlass.experimental import primitives as prims
import cutlass
import cutlass.experimental.cuda as cuda
import cutlass.cute as cute
from cutlass.cute.runtime import make_fake_compact_tensor, make_fake_stream
import cuda.bindings.driver as cuda_driver


_WARP_SIZE = 32
_TMEM_WARPS = 4
_THREADS = _TMEM_WARPS * _WARP_SIZE
_TMEM_ROWS_PER_WARP = 32
_TILE_M = 128
_TILE_N = 64
_OUT_TILE_M = _TILE_N
_OUT_TILE_N = _TILE_M
_SUBTILE_M = 16
_SUBTILE_N = 16
_TILE_ELEMS = _TILE_M * _TILE_N
_TMEM_COLS = _TILE_N
_B16_OUT_PAGE_COLS = _OUT_TILE_N // 2
_B16_OUT_PAGE_ELEMS = _OUT_TILE_M * _B16_OUT_PAGE_COLS
_B16_SWIZZLE = "s128b"
_B8_SWIZZLE = "s128b"
_DEFAULT_OUT_DTYPE = cutlass.Float16

_B16_DTYPE_BY_NAME: dict[str, type] = {
    "fp16": cutlass.Float16,
    "bf16": cutlass.BFloat16,
    "i16": cutlass.Int16,
}
_B8_DTYPE_BY_NAME: dict[str, type] = {
    "fp8_e4m3": cutlass.Float8E4M3FN,
    "fp8_e5m2": cutlass.Float8E5M2,
}
_DTYPE_BY_NAME: dict[str, type] = {**_B16_DTYPE_BY_NAME, **_B8_DTYPE_BY_NAME}
_NAME_BY_DTYPE: dict[type, str] = {
    dtype: name for name, dtype in _DTYPE_BY_NAME.items()
}
_TORCH_DTYPE_BY_CUTLASS: dict[type, torch.dtype] = {
    cutlass.Float16: torch.float16,
    cutlass.BFloat16: torch.bfloat16,
    cutlass.Int16: torch.int16,
    cutlass.Float8E4M3FN: torch.float8_e4m3fn,
    cutlass.Float8E5M2: torch.float8_e5m2,
}


def _is_supported_b8_dtype(dtype: type) -> bool:
    return dtype in _B8_DTYPE_BY_NAME.values()


@cute.kernel
def kernel(
    src: cute.Tensor,
    tma_dst_desc: cutlass.GridConstant[cuda.TensorMap],
    OUT_DTYPE: cutlass.Constexpr[type],
) -> None:
    """Drain a f32 TMEM fragment, convert it, and store with transposed ``stmatrix``."""

    tidx, _, _ = cute.arch.thread_idx()
    warp_idx = cute.arch.warp_idx()
    tmem_addr_smem = cutlass.Array(cutlass.Int32, 1, space=cutlass.AddressSpace.smem)
    smem_out = cutlass.Array(
        OUT_DTYPE, _TILE_ELEMS, space=cutlass.AddressSpace.smem, alignment=128
    )

    if warp_idx == 0:
        prims.tcgen05_alloc(tmem_addr_smem, _TMEM_COLS, group="cta_1")
    prims.barrier_cta_sync(0)

    tmem_raw = tmem_addr_smem.load()
    tmem_base_col = tmem_raw & cutlass.Int32(0xFFFF)
    tmem_base_row = tmem_raw >> cutlass.Int32(16)
    prims.tcgen05_relinquish_alloc_permit(group="cta_1")

    lane = tidx & cutlass.Int32(31)
    src_ptr = src.iterator.raw_ptr()
    source_row = warp_idx * cutlass.Int32(_TMEM_ROWS_PER_WARP) + lane

    # Seed a realistic f32 accumulator image in TMEM.  This setup path is
    # intentionally row-major and simple; the example's teaching target is the
    # later tcgen05_ld -> stmatrix transpose drain.
    src_f32 = (src_ptr + source_row * cutlass.Int32(_TILE_N)).load(count=_TILE_N)
    tmem_addr = (
        (tmem_base_row + warp_idx * cutlass.Int32(_TMEM_ROWS_PER_WARP))
        << cutlass.Int32(16)
    ) | tmem_base_col
    tmem_ptr = cutlass.inttoptr(tmem_addr, 6, cutlass.Float32)
    prims.tcgen05_st("32x32b", tmem_ptr, src_f32)
    prims.tcgen05_wait(prims.Tcgen05Wait.STORE)

    for local_tile_m in cutlass.range_constexpr(_TMEM_ROWS_PER_WARP // _SUBTILE_M):
        for tile_n in cutlass.range_constexpr(_TILE_N // _SUBTILE_N):
            tmem_row = (
                tmem_base_row
                + warp_idx * cutlass.Int32(_TMEM_ROWS_PER_WARP)
                + cutlass.Int32(local_tile_m * _SUBTILE_M)
            )
            tmem_col = tmem_base_col + cutlass.Int32(tile_n * _SUBTILE_N)
            tmem_addr = (tmem_row << cutlass.Int32(16)) | tmem_col
            tmem_ptr = cutlass.inttoptr(tmem_addr, 6, cutlass.Float32)

            acc_f32 = prims.tcgen05_ld("16x256b", tmem_ptr, num=2)
            prims.tcgen05_wait(prims.Tcgen05Wait.LOAD)

            stmatrix_src = acc_f32.to(OUT_DTYPE).bitcast(cutlass.Int32)
            tile_m = warp_idx * cutlass.Int32(2) + cutlass.Int32(local_tile_m)
            if cutlass.const_expr(OUT_DTYPE.width == 8):
                smem_sw = cutlass.Swizzle.from_name(_B8_SWIZZLE)
                address_row = lane % cutlass.Int32(8)
                addr_segment = (lane // cutlass.Int32(8)) % cutlass.Int32(2)
                row_start = (
                    cutlass.Int32(tile_n * _SUBTILE_N) + addr_segment * 8 + address_row
                ) * cutlass.Int32(_OUT_TILE_N) + cutlass.Int32(tile_m * _SUBTILE_M)
                out_ptr = (smem_out.data_ptr() + row_start).apply_swizzle(smem_sw)
                prims.stmatrix(
                    out_ptr,
                    [stmatrix_src[0], stmatrix_src[1]],
                    prims.MMALayout.COL,
                    shape=prims.StoreShape.M16N8,
                )
            else:
                smem_sw = cutlass.Swizzle.from_name(_B16_SWIZZLE)
                store_row = lane % cutlass.Int32(_SUBTILE_M)
                store_col = (lane // cutlass.Int32(_SUBTILE_M)) * cutlass.Int32(8)
                out_row = cutlass.Int32(tile_n * _SUBTILE_N) + store_row
                out_col = cutlass.Int32(tile_m * _SUBTILE_M) + store_col
                out_page = out_col // cutlass.Int32(_B16_OUT_PAGE_COLS)
                page_col = out_col - out_page * cutlass.Int32(_B16_OUT_PAGE_COLS)
                dst_row_start = (
                    out_page * cutlass.Int32(_B16_OUT_PAGE_ELEMS)
                    + out_row * cutlass.Int32(_B16_OUT_PAGE_COLS)
                    + page_col
                )
                out_ptr = (smem_out.data_ptr() + dst_row_start).apply_swizzle(smem_sw)

                # The [0, 2, 1, 3] order is the b16 transpose convention for
                # TL/TR/BL/BR 8x8 fragments inside each 16x16 output subtile.
                prims.stmatrix(
                    out_ptr,
                    [
                        stmatrix_src[0],
                        stmatrix_src[2],
                        stmatrix_src[1],
                        stmatrix_src[3],
                    ],
                    prims.MMALayout.COL,
                )
    prims.barrier_cta_sync(0)

    smem_out_ptr = smem_out.data_ptr()
    prims.fence_proxy(prims.Proxy.ASYNC_SHARED, space=prims.SharedSpace.shared_cta)
    if warp_idx == 0:
        if prims.elect_sync():
            dst_ptr = tma_dst_desc.get_ptr()
            if cutlass.const_expr(OUT_DTYPE.width == 8):
                prims.cp_async_bulk_tensor_global_shared_cta(
                    dst_ptr,
                    smem_out,
                    (0, 0),
                )
            else:
                prims.cp_async_bulk_tensor_global_shared_cta(
                    dst_ptr,
                    smem_out,
                    (0, 0),
                )
                prims.cp_async_bulk_tensor_global_shared_cta(
                    dst_ptr,
                    smem_out_ptr + cutlass.Int32(_B16_OUT_PAGE_ELEMS),
                    (_B16_OUT_PAGE_COLS, 0),
                )
        prims.cp_async_bulk_commit_group()
        prims.cp_async_bulk_wait_group(0)
    prims.barrier_cta_sync(0)

    prims.tcgen05_fence(prims.Tcgen05Fence.BEFORE_THREAD_SYNC)
    prims.barrier_cta_sync(0)
    if warp_idx == 0:
        tmem_alloc_ptr = cutlass.inttoptr(tmem_raw, 6, cutlass.Float32)
        prims.tcgen05_dealloc(tmem_alloc_ptr, _TMEM_COLS, group="cta_1")


@cute.jit
def host(
    src: cute.Tensor,
    dst: cute.Tensor,
    stream,
    OUT_DTYPE: cutlass.Constexpr[type],
) -> None:
    """Launch four epilogue warps for the dtype-specialized example."""

    row_stride_16b = _OUT_TILE_N * (OUT_DTYPE.width // 8) // 16
    if cutlass.const_expr(OUT_DTYPE.width == 8):
        tma_dst_desc = cuda.create_tensor_map_tiled(
            global_address=dst.iterator.toint(),
            dtype=OUT_DTYPE,
            global_dims=[_OUT_TILE_N, _OUT_TILE_M],
            global_strides=[row_stride_16b],
            box_dims=[_OUT_TILE_N, _OUT_TILE_M],
            swizzle=cuda.TensorMapSwizzle.s128b,
        )
    else:
        tma_dst_desc = cuda.create_tensor_map_tiled(
            global_address=dst.iterator.toint(),
            dtype=OUT_DTYPE,
            global_dims=[_OUT_TILE_N, _OUT_TILE_M],
            global_strides=[row_stride_16b],
            box_dims=[_B16_OUT_PAGE_COLS, _OUT_TILE_M],
            swizzle=cuda.TensorMapSwizzle.s128b,
        )

    kernel(src, tma_dst_desc, OUT_DTYPE).launch(
        grid=(1, 1, 1), block=(_THREADS, 1, 1), stream=stream
    )


def _dtype_name(dtype: type) -> str:
    return _NAME_BY_DTYPE.get(dtype, getattr(dtype, "__name__", repr(dtype)))


def _doc_summary() -> str:
    return next(
        (line.strip() for line in (__doc__ or "").splitlines() if line.strip()), ""
    )


@lru_cache(maxsize=None)
def compile(OUT_DTYPE: type = _DEFAULT_OUT_DTYPE) -> Callable:  # noqa: A001
    """AOT-compile the TMEM -> converted output -> transposed stmatrix example."""

    if OUT_DTYPE not in _DTYPE_BY_NAME.values():
        width = getattr(OUT_DTYPE, "width", None)
        if width == 32:
            reason = "32-bit outputs are not direct stmatrix outputs; use vector stores or narrow first"
        elif width == 8:
            reason = (
                "8-bit outputs are supported here for fp8_e4m3/fp8_e5m2; "
                "other b8 payload types need their own conversion policy"
            )
        elif width == 4:
            reason = "4-bit outputs require a packed sub-byte store path, not default stmatrix.m8n8"
        else:
            reason = "unsupported output width for this example"
        supported = ", ".join(sorted(_DTYPE_BY_NAME))
        raise ValueError(
            f"OUT_DTYPE must be one of {supported}; got {_dtype_name(OUT_DTYPE)}: {reason}"
        )
    fake_src = make_fake_compact_tensor(
        cutlass.Float32,
        (_TILE_M, _TILE_N),
        stride_order=(1, 0),
        assumed_align=16,
    )
    fake_dst = make_fake_compact_tensor(
        OUT_DTYPE, (_OUT_TILE_M, _OUT_TILE_N), stride_order=(1, 0), assumed_align=16
    )
    return cute.compile(
        host,
        fake_src,
        fake_dst,
        make_fake_stream(),
        OUT_DTYPE,
        options="--enable-tvm-ffi",
    )


def run(OUT_DTYPE: type = _DEFAULT_OUT_DTYPE) -> tuple[torch.Tensor, torch.Tensor]:
    """Allocate random f32 source/output, run, and return ``(dst, src)``."""

    if not torch.cuda.is_available():
        raise RuntimeError("CUDA GPU required")

    compiled = compile(OUT_DTYPE=OUT_DTYPE)
    src = torch.randint(
        -4,
        5,
        (_TILE_M, _TILE_N),
        dtype=torch.int32,
        device="cuda",
    ).to(torch.float32)
    dst = torch.empty(
        (_OUT_TILE_M, _OUT_TILE_N),
        dtype=_TORCH_DTYPE_BY_CUTLASS[OUT_DTYPE],
        device="cuda",
    )
    stream = cuda_driver.CUstream(torch.cuda.current_stream().cuda_stream)
    compiled(src, dst, stream)
    torch.cuda.synchronize()
    return dst, src


def verify(OUT_DTYPE: type = _DEFAULT_OUT_DTYPE) -> None:
    """Compile, run, and assert the converted transposed tile."""

    dst, src = run(OUT_DTYPE=OUT_DTYPE)
    expected = src.to(_TORCH_DTYPE_BY_CUTLASS[OUT_DTYPE]).t().contiguous()
    if _is_supported_b8_dtype(OUT_DTYPE):
        torch.testing.assert_close(
            dst.to(torch.float32), expected.to(torch.float32), atol=0, rtol=0
        )
    else:
        torch.testing.assert_close(dst, expected, atol=0, rtol=0)
    print(
        f"verify ({_dtype_name(OUT_DTYPE)}): PASS  "
        f"dst[:8] = {dst.reshape(-1)[:8].tolist()}",
        flush=True,
    )


def _resolve_out_dtype(name: str) -> type:
    try:
        return _DTYPE_BY_NAME[name]
    except KeyError as exc:
        valid = ", ".join(sorted([*_DTYPE_BY_NAME, "all"]))
        raise ValueError(f"Unsupported --out-dtype {name!r}; expected {valid}") from exc


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description=_doc_summary(),
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument(
        "--out-dtype",
        choices=sorted([*_DTYPE_BY_NAME, "all"]),
        default="all",
        help="Output dtype case to run.",
    )
    args = parser.parse_args()

    if args.out_dtype == "all":
        for dtype in _DTYPE_BY_NAME.values():
            verify(OUT_DTYPE=dtype)
    else:
        verify(OUT_DTYPE=_resolve_out_dtype(args.out_dtype))
