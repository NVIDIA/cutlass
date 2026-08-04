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
TMA block-tile handoff to ldmatrix/stmatrix consumers.

Use this file when the producer is TMA and the question is how a swizzled
128x64 block tile feeds matrix-instruction consumers.  The standalone
``../ldmatrix_stmatrix.py`` example owns detailed per-lane mapping notes.

Do not treat 128x64 as one matrix instruction: the tile shape selects storage
and swizzle, while each consumer still operates on 16x16 or 16x8 instruction
groups.  The b16 modes accept fp16, bf16, and i16; the b8 mode uses uint8 as a
raw byte carrier.  Here, 64-column b16 input rows use ``s128b`` and 64-column
b8 input rows use ``s64b``; output is staged in swizzled SMEM and published
with TMA store.  Pick the output TMA swizzle from the output SMEM row/page
layout; it can differ from the input TMA load swizzle.  The b8 path uses a
small register shuffle so ``stmatrix`` can publish contiguous output panels.

Public API:
  - ``compile(mode=..., DTYPE=...)`` returns an AOT callable for a runnable mode.
  - ``run(compiled_fn, mode=..., DTYPE=...)`` allocates random tensors and runs it.
  - ``verify(mode=..., DTYPE=...)`` checks ``dst`` against ``src`` or ``src.t()``.

To run::

    python CuTeDSL/experimental/primitives/tma/tma_load_to_ldmatrix.py
    python CuTeDSL/experimental/primitives/tma/tma_load_to_ldmatrix.py --mode b8-transpose

"""

from __future__ import annotations

import argparse
from functools import lru_cache
from typing import Callable

import torch

import cutlass
import cutlass.cute as cute
from cutlass.experimental import primitives as prims
import cutlass.experimental.cuda as cuda
from cutlass.cute.runtime import make_fake_compact_tensor, make_fake_stream
import cuda.bindings.driver as cuda_driver


# ---------------------------------------------------------------------------
# Kernel Configurations - fixed
# ---------------------------------------------------------------------------

_WARP_SIZE = 32
_LDMATRIX_NUM_TILES = 4
TILE_M = 128
TILE_K = 64
_FRAGMENT_M = 16
_FRAGMENT_N = 16
_TILE_ELEMS = TILE_M * TILE_K
_TILE_BYTES = _TILE_ELEMS * 2
_TRANSPOSE_PAGE_COLS = TILE_M // 2
_TRANSPOSE_PAGE_ELEMS = TILE_K * _TRANSPOSE_PAGE_COLS
_B8_TILE_BYTES = _TILE_ELEMS


# ---------------------------------------------------------------------------
# Kernel Configurations - tunable
# ---------------------------------------------------------------------------

_MODE_ROUNDTRIP = "roundtrip"
_MODE_TRANSPOSE = "transpose"
_MODE_B8_TRANSPOSE = "b8-transpose"
_MODE_CHOICES = (
    _MODE_ROUNDTRIP,
    _MODE_TRANSPOSE,
    _MODE_B8_TRANSPOSE,
)
_DEFAULT_MODE = _MODE_ROUNDTRIP
_DEFAULT_B16_DTYPE = cutlass.Float16
_B8_DTYPE = cutlass.Uint8

_B16_DTYPE_BY_NAME: dict[str, type] = {
    "fp16": cutlass.Float16,
    "bf16": cutlass.BFloat16,
    "i16": cutlass.Int16,
}
_NAME_BY_DTYPE: dict[type, str] = {
    dtype: name for name, dtype in _B16_DTYPE_BY_NAME.items()
}
_NAME_BY_DTYPE[_B8_DTYPE] = "uint8"
_TORCH_DTYPE_BY_CUTLASS: dict[type, torch.dtype] = {
    cutlass.Float16: torch.float16,
    cutlass.BFloat16: torch.bfloat16,
    cutlass.Int16: torch.int16,
    cutlass.Uint8: torch.uint8,
}


def _row_bytes_for_element_bits(row_elems: int, element_bits: int) -> int:
    """Return contiguous row bytes for ``row_elems`` logical elements."""

    if row_elems <= 0:
        raise ValueError(f"row_elems must be positive, got {row_elems}")
    if element_bits <= 0:
        raise ValueError(f"element_bits must be positive, got {element_bits}")
    row_bits = row_elems * element_bits
    if row_bits % 8 != 0:
        raise ValueError(
            f"row_elems={row_elems} * element_bits={element_bits} "
            "does not produce a whole-byte row"
        )
    return row_bits // 8


def _swizzle_for_row_bytes(row_bytes: int) -> tuple[cuda.TensorMapSwizzle, str]:
    """Map a legal row byte width to matching TMA and SMEM swizzle names.

    Only ``none``, ``s32b``, ``s64b``, and ``s128b`` exist.  In particular,
    8B and 16B rows use ``none``; there is no ``s8b`` or ``s16b`` mode.
    """

    if row_bytes == 128:
        return cuda.TensorMapSwizzle.s128b, "s128b"
    if row_bytes == 64:
        return cuda.TensorMapSwizzle.s64b, "s64b"
    if row_bytes == 32:
        return cuda.TensorMapSwizzle.s32b, "s32b"
    if row_bytes < 32:
        return cuda.TensorMapSwizzle.none, "none"
    raise ValueError(
        f"row_bytes={row_bytes} is not a single legal TMA swizzle width; "
        "split the tile into 32B, 64B, or 128B boxes"
    )


def _swizzle_for_element_bits(
    row_elems: int,
    element_bits: int,
) -> tuple[int, cuda.TensorMapSwizzle, str]:
    """Return ``(row_bytes, TensorMapSwizzle, cutlass.Swizzle name)``."""

    row_bytes = _row_bytes_for_element_bits(row_elems, element_bits)
    tma_swizzle, smem_swizzle_name = _swizzle_for_row_bytes(row_bytes)
    return row_bytes, tma_swizzle, smem_swizzle_name


# ---------------------------------------------------------------------------
# Device kernels
# ---------------------------------------------------------------------------


@cute.kernel
def kernel_roundtrip(
    tma_src_desc: cutlass.GridConstant[cuda.TensorMap],
    tma_dst_desc: cutlass.GridConstant[cuda.TensorMap],
    DTYPE: cutlass.Constexpr[type],
    SMEM_SWIZZLE: cutlass.Constexpr[str],
) -> None:
    """Load a b16 block tile via TMA and roundtrip it through matrix fragments."""

    tidx, _, _ = cute.arch.thread_idx()
    smem_in = cutlass.Array(
        dtype=DTYPE,
        shape=(_TILE_ELEMS,),
        space=cutlass.AddressSpace.smem,
        alignment=128,
    )
    smem_out = cutlass.Array(
        dtype=DTYPE,
        shape=(_TILE_ELEMS,),
        space=cutlass.AddressSpace.smem,
        alignment=128,
    )
    smem_sw = cutlass.Swizzle.from_name(SMEM_SWIZZLE)
    mbar = cutlass.Array(
        dtype=cutlass.Int64, shape=(1,), space=cutlass.AddressSpace.smem, alignment=8
    )

    if prims.elect_sync():
        prims.mbarrier_init(mbar, 1)
    prims.fence_mbarrier_init()
    prims.barrier_cta_sync(0)

    if prims.elect_sync():
        prims.mbarrier_arrive_expect_tx(mbar, tma_src_desc.global_tx_bytes())
        prims.cp_async_bulk_tensor_shared_cta_global(
            smem_in,
            tma_src_desc.get_ptr(),
            (0, 0),
            mbar,
        )

    while not prims.mbarrier_try_wait_parity(mbar, 0, time_limit=10_000_000):
        pass
    prims.barrier_cta_sync(0)

    lane = tidx % cutlass.Int32(_WARP_SIZE)
    row = (lane // cutlass.Int32(16)) * cutlass.Int32(8) + (lane % cutlass.Int32(8))
    col = ((lane // cutlass.Int32(8)) % cutlass.Int32(2)) * cutlass.Int32(8)
    smem_in_ptr = smem_in.data_ptr()
    smem_out_ptr = smem_out.data_ptr()

    for tile_m in cutlass.range_constexpr(TILE_M // _FRAGMENT_M):
        for tile_k in cutlass.range_constexpr(TILE_K // _FRAGMENT_N):
            base = cutlass.Int32(tile_m * _FRAGMENT_M * TILE_K + tile_k * _FRAGMENT_N)
            row_start = base + row * cutlass.Int32(TILE_K) + col
            src_ptr = (smem_in_ptr + row_start).apply_swizzle(smem_sw)
            regs = prims.ldmatrix(src_ptr, _LDMATRIX_NUM_TILES, prims.MMALayout.ROW)
            dst_ptr = (smem_out_ptr + row_start).apply_swizzle(smem_sw)
            prims.stmatrix(dst_ptr, regs, prims.MMALayout.ROW)

    prims.barrier_cta_sync(0)

    prims.fence_proxy(prims.Proxy.ASYNC_SHARED, space=prims.SharedSpace.shared_cta)
    if prims.elect_sync():
        prims.cp_async_bulk_tensor_global_shared_cta(
            tma_dst_desc.get_ptr(),
            smem_out,
            (0, 0),
        )
    prims.cp_async_bulk_commit_group()
    prims.cp_async_bulk_wait_group(0)


@cute.kernel
def kernel_transpose(
    tma_src_desc: cutlass.GridConstant[cuda.TensorMap],
    tma_dst_desc: cutlass.GridConstant[cuda.TensorMap],
    DTYPE: cutlass.Constexpr[type],
    SMEM_SWIZZLE: cutlass.Constexpr[str],
    OUT_SMEM_SWIZZLE: cutlass.Constexpr[str],
) -> None:
    """Load a b16 block tile via TMA and transpose it through matrix fragments."""

    tidx, _, _ = cute.arch.thread_idx()
    smem_in = cutlass.Array(
        dtype=DTYPE,
        shape=(_TILE_ELEMS,),
        space=cutlass.AddressSpace.smem,
        alignment=128,
    )
    smem_out = cutlass.Array(
        dtype=DTYPE,
        shape=(_TILE_ELEMS,),
        space=cutlass.AddressSpace.smem,
        alignment=128,
    )
    smem_sw = cutlass.Swizzle.from_name(SMEM_SWIZZLE)
    out_smem_sw = cutlass.Swizzle.from_name(OUT_SMEM_SWIZZLE)
    mbar = cutlass.Array(
        dtype=cutlass.Int64, shape=(1,), space=cutlass.AddressSpace.smem, alignment=8
    )

    if prims.elect_sync():
        prims.mbarrier_init(mbar, 1)
    prims.fence_mbarrier_init()
    prims.barrier_cta_sync(0)

    if prims.elect_sync():
        prims.mbarrier_arrive_expect_tx(mbar, tma_src_desc.global_tx_bytes())
        prims.cp_async_bulk_tensor_shared_cta_global(
            smem_in,
            tma_src_desc.get_ptr(),
            (0, 0),
            mbar,
        )

    while not prims.mbarrier_try_wait_parity(mbar, 0, time_limit=10_000_000):
        pass
    prims.barrier_cta_sync(0)

    lane = tidx % 32
    matrix = (lane // cutlass.Int32(8)) % cutlass.Int32(2)
    row = lane % cutlass.Int32(8)
    smem_in_ptr = smem_in.data_ptr()
    smem_out_ptr = smem_out.data_ptr()

    for tile_m in cutlass.range_constexpr(TILE_M // _FRAGMENT_M):
        for tile_k in cutlass.range_constexpr(TILE_K // _FRAGMENT_N):
            for half in cutlass.range_constexpr(2):
                src_base = cutlass.Int32(
                    tile_m * _FRAGMENT_M * TILE_K + tile_k * _FRAGMENT_N + half * 8
                )
                src_row_start = src_base + (
                    matrix * cutlass.Int32(8) + row
                ) * cutlass.Int32(TILE_K)
                src_ptr = (smem_in_ptr + src_row_start).apply_swizzle(smem_sw)
                regs = prims.ldmatrix(src_ptr, 2, prims.MMALayout.ROW)

                out_row = cutlass.Int32(tile_k * _FRAGMENT_N + half * 8) + row
                out_col = cutlass.Int32(tile_m * _FRAGMENT_M) + matrix * cutlass.Int32(
                    8
                )
                out_page = out_col // cutlass.Int32(_TRANSPOSE_PAGE_COLS)
                page_col = out_col - out_page * cutlass.Int32(_TRANSPOSE_PAGE_COLS)
                dst_row_start = (
                    out_page * cutlass.Int32(_TRANSPOSE_PAGE_ELEMS)
                    + out_row * cutlass.Int32(_TRANSPOSE_PAGE_COLS)
                    + page_col
                )
                out_ptr = (smem_out_ptr + dst_row_start).apply_swizzle(out_smem_sw)
                prims.stmatrix(out_ptr, regs, prims.MMALayout.COL)

    prims.barrier_cta_sync(0)

    prims.fence_proxy(prims.Proxy.ASYNC_SHARED, space=prims.SharedSpace.shared_cta)
    if prims.elect_sync():
        prims.cp_async_bulk_tensor_global_shared_cta(
            tma_dst_desc.get_ptr(),
            smem_out,
            (0, 0),
        )
        prims.cp_async_bulk_tensor_global_shared_cta(
            tma_dst_desc.get_ptr(),
            smem_out_ptr + cutlass.Int32(_TRANSPOSE_PAGE_ELEMS),
            (_TRANSPOSE_PAGE_COLS, 0),
        )
    prims.cp_async_bulk_commit_group()
    prims.cp_async_bulk_wait_group(0)


@cute.kernel
def kernel_b8_transpose(
    tma_src_desc: cutlass.GridConstant[cuda.TensorMap],
    tma_dst_desc: cutlass.GridConstant[cuda.TensorMap],
    SMEM_SWIZZLE: cutlass.Constexpr[str],
    OUT_SMEM_SWIZZLE: cutlass.Constexpr[str],
) -> None:
    """Load a b8 block tile via TMA and transpose it through matrix fragments."""

    tidx, _, _ = cute.arch.thread_idx()
    smem_in = cutlass.Array(
        dtype=cutlass.Uint8,
        shape=(_TILE_ELEMS,),
        space=cutlass.AddressSpace.smem,
        alignment=128,
    )
    smem_out = cutlass.Array(
        dtype=cutlass.Uint8,
        shape=(_TILE_ELEMS,),
        space=cutlass.AddressSpace.smem,
        alignment=128,
    )
    mbar = cutlass.Array(
        dtype=cutlass.Int64, shape=(1,), space=cutlass.AddressSpace.smem, alignment=8
    )

    if prims.elect_sync():
        prims.mbarrier_init(mbar, 1)
    prims.fence_mbarrier_init()
    prims.barrier_cta_sync(0)

    if prims.elect_sync():
        prims.mbarrier_arrive_expect_tx(mbar, tma_src_desc.global_tx_bytes())
        prims.cp_async_bulk_tensor_shared_cta_global(
            smem_in,
            tma_src_desc.get_ptr(),
            (0, 0),
            mbar,
        )

    while not prims.mbarrier_try_wait_parity(mbar, 0, time_limit=10_000_000):
        pass
    prims.barrier_cta_sync(0)

    lane = tidx % 32
    smem_in_ptr = smem_in.data_ptr()
    smem_out_ptr = smem_out.data_ptr()
    smem_sw = cutlass.Swizzle.from_name(SMEM_SWIZZLE)
    out_smem_sw = cutlass.Swizzle.from_name(OUT_SMEM_SWIZZLE)

    for tile_m in cutlass.range_constexpr(TILE_M // _FRAGMENT_M):
        for tile_k in cutlass.range_constexpr(TILE_K // _FRAGMENT_N):
            load_segment = (lane // 8) % 2
            load_row = tile_m * _FRAGMENT_M + load_segment * 8 + (lane % 8)
            load_col = tile_k * _FRAGMENT_N
            load_ptr = (smem_in_ptr + load_row * TILE_K + load_col).apply_swizzle(
                smem_sw
            )
            regs = prims.ldmatrix(load_ptr, 2, prims.MMALayout.ROW)

            regs0 = regs[0].to(cutlass.Uint32)
            regs1 = regs[1].to(cutlass.Uint32)
            low_word = (regs0 & cutlass.Uint32(0x0000FFFF)) | (
                (regs1 & cutlass.Uint32(0x0000FFFF)) << cutlass.Uint32(16)
            )
            high_word = ((regs0 >> cutlass.Uint32(16)) & cutlass.Uint32(0x0000FFFF)) | (
                regs1 & cutlass.Uint32(0xFFFF0000)
            )

            # Regroup within each 4-lane row group so stmatrix writes
            # contiguous output rows; the natural b8 row interleave repeats
            # bank quartets even when the output tile uses s128b swizzle.
            t = lane % 4
            source_pair = lane - t + (t // 2)
            low_panel = cute.arch.shuffle_sync(low_word, source_pair)
            high_panel = cute.arch.shuffle_sync(high_word, source_pair)
            low_next_panel = cute.arch.shuffle_sync(low_word, source_pair + 2)
            high_next_panel = cute.arch.shuffle_sync(high_word, source_pair + 2)
            word0 = low_panel
            word1 = low_next_panel
            if (t == 1) | (t == 3):
                word0 = high_panel
                word1 = high_next_panel

            out_row = tile_k * _FRAGMENT_N + ((lane // 8) % 2) * 8 + (lane % 8)
            out_col = tile_m * _FRAGMENT_M
            out_ptr = (smem_out_ptr + out_row * TILE_M + out_col).apply_swizzle(
                out_smem_sw
            )
            prims.stmatrix(
                out_ptr,
                [word0, word1],
                prims.MMALayout.COL,
                shape=prims.StoreShape.M16N8,
            )

    prims.barrier_cta_sync(0)

    prims.fence_proxy(prims.Proxy.ASYNC_SHARED, space=prims.SharedSpace.shared_cta)
    if prims.elect_sync():
        prims.cp_async_bulk_tensor_global_shared_cta(
            tma_dst_desc.get_ptr(),
            smem_out,
            (0, 0),
        )
    prims.cp_async_bulk_commit_group()
    prims.cp_async_bulk_wait_group(0)


# ---------------------------------------------------------------------------
# Host launcher
# ---------------------------------------------------------------------------


@cute.jit
def host(
    src: cute.Tensor,
    dst: cute.Tensor,
    stream,
    MODE: cutlass.Constexpr[str],
    DTYPE: cutlass.Constexpr[type],
    TMA_SWIZZLE: cutlass.Constexpr[cuda.TensorMapSwizzle],
    SMEM_SWIZZLE: cutlass.Constexpr[str],
    OUT_TMA_SWIZZLE: cutlass.Constexpr[cuda.TensorMapSwizzle],
    OUT_SMEM_SWIZZLE: cutlass.Constexpr[str],
) -> None:
    """Build TMA descriptors for the selected matrix-consumer mode."""

    input_stride_16b = TILE_K * (DTYPE.width // 8) // 16
    tma_src_desc = cuda.create_tensor_map_tiled(
        global_address=src.iterator.toint(),
        dtype=DTYPE,
        global_dims=[TILE_K, TILE_M],
        global_strides=[input_stride_16b],
        box_dims=[TILE_K, TILE_M],
        swizzle=TMA_SWIZZLE,
    )
    if cutlass.const_expr(MODE == _MODE_ROUNDTRIP):
        tma_dst_desc = cuda.create_tensor_map_tiled(
            global_address=dst.iterator.toint(),
            dtype=DTYPE,
            global_dims=[TILE_K, TILE_M],
            global_strides=[input_stride_16b],
            box_dims=[TILE_K, TILE_M],
            swizzle=TMA_SWIZZLE,
        )
        kernel_roundtrip(tma_src_desc, tma_dst_desc, DTYPE, SMEM_SWIZZLE).launch(
            grid=(1, 1, 1), block=(_WARP_SIZE, 1, 1), stream=stream
        )
    else:
        output_stride_16b = TILE_M * (DTYPE.width // 8) // 16
        if cutlass.const_expr(MODE == _MODE_TRANSPOSE):
            output_box_cols = _TRANSPOSE_PAGE_COLS
        else:
            output_box_cols = TILE_M
        tma_dst_desc = cuda.create_tensor_map_tiled(
            global_address=dst.iterator.toint(),
            dtype=DTYPE,
            global_dims=[TILE_M, TILE_K],
            global_strides=[output_stride_16b],
            # Match the TMA-store swizzle to smem_out's output row/page layout,
            # not necessarily to the input TMA-load descriptor.
            box_dims=[output_box_cols, TILE_K],
            swizzle=OUT_TMA_SWIZZLE,
        )
        if cutlass.const_expr(MODE == _MODE_TRANSPOSE):
            kernel_transpose(
                tma_src_desc,
                tma_dst_desc,
                DTYPE,
                SMEM_SWIZZLE,
                OUT_SMEM_SWIZZLE,
            ).launch(
                grid=(1, 1, 1),
                block=(_WARP_SIZE, 1, 1),
                stream=stream,
            )
        else:
            kernel_b8_transpose(
                tma_src_desc,
                tma_dst_desc,
                SMEM_SWIZZLE,
                OUT_SMEM_SWIZZLE,
            ).launch(grid=(1, 1, 1), block=(_WARP_SIZE, 1, 1), stream=stream)


# ---------------------------------------------------------------------------
# Compile factory
# ---------------------------------------------------------------------------


def _resolve_mode_dtype(mode: str, dtype: type | None) -> tuple[str, type]:
    """Resolve public mode and dtype into the concrete kernel payload type."""

    if mode not in _MODE_CHOICES:
        valid = ", ".join(_MODE_CHOICES)
        raise ValueError(f"mode must be one of {valid}; got {mode!r}")
    if mode == _MODE_B8_TRANSPOSE:
        if dtype is not None and dtype is not _B8_DTYPE:
            raise ValueError(
                "b8-transpose uses uint8 as a raw byte carrier; omit DTYPE or "
                "pass cutlass.Uint8"
            )
        return mode, _B8_DTYPE

    resolved_dtype = _DEFAULT_B16_DTYPE if dtype is None else dtype
    if resolved_dtype not in _B16_DTYPE_BY_NAME.values():
        valid = ", ".join(sorted(_B16_DTYPE_BY_NAME))
        raise ValueError(
            f"{mode} DTYPE must be one of {valid}; got {resolved_dtype.__name__}"
        )
    return mode, resolved_dtype


@lru_cache(maxsize=None)
def compile(  # noqa: A001
    mode: str = _DEFAULT_MODE,
    DTYPE: type | None = None,
) -> Callable:
    """AOT-compile the selected TMA -> matrix-fragment consumer mode."""

    mode, dtype = _resolve_mode_dtype(mode, DTYPE)
    src_shape = (TILE_M, TILE_K)
    dst_shape = (
        (TILE_K, TILE_M) if mode in {_MODE_TRANSPOSE, _MODE_B8_TRANSPOSE} else src_shape
    )
    fake_src = make_fake_compact_tensor(
        dtype,
        src_shape,
        stride_order=(1, 0),
        assumed_align=16,
    )
    fake_dst = make_fake_compact_tensor(
        dtype,
        dst_shape,
        stride_order=(1, 0),
        assumed_align=16,
    )
    stream = make_fake_stream()
    _, tma_swizzle, smem_swizzle_name = _swizzle_for_element_bits(TILE_K, dtype.width)
    if mode == _MODE_ROUNDTRIP:
        out_row_elems = TILE_K
    elif mode == _MODE_TRANSPOSE:
        out_row_elems = _TRANSPOSE_PAGE_COLS
    else:
        out_row_elems = TILE_M
    _, out_tma_swizzle, out_smem_swizzle = _swizzle_for_element_bits(
        out_row_elems, dtype.width
    )
    return cute.compile(
        host,
        fake_src,
        fake_dst,
        stream,
        mode,
        dtype,
        tma_swizzle,
        smem_swizzle_name,
        out_tma_swizzle,
        out_smem_swizzle,
        options="--enable-tvm-ffi",
    )


# ---------------------------------------------------------------------------
# Run
# ---------------------------------------------------------------------------


def run(
    compiled_fn: Callable,
    mode: str = _DEFAULT_MODE,
    DTYPE: type | None = None,
) -> tuple[torch.Tensor, torch.Tensor]:
    """Allocate tensors, call compiled_fn, return ``(dst, src)``."""

    if not torch.cuda.is_available():
        raise RuntimeError("CUDA GPU required")

    mode, dtype = _resolve_mode_dtype(mode, DTYPE)
    torch_dtype = _TORCH_DTYPE_BY_CUTLASS[dtype]
    src_shape = (TILE_M, TILE_K)
    dst_shape = (
        (TILE_K, TILE_M) if mode in {_MODE_TRANSPOSE, _MODE_B8_TRANSPOSE} else src_shape
    )

    src = torch.randint(
        0,
        128,
        src_shape,
        dtype=torch.int32,
        device="cuda",
    ).to(torch_dtype)
    dst = torch.empty(dst_shape, dtype=torch_dtype, device="cuda")
    stream = cuda_driver.CUstream(torch.cuda.current_stream().cuda_stream)

    compiled_fn(src, dst, stream)
    torch.cuda.synchronize()
    return dst, src


# ---------------------------------------------------------------------------
# Verify
# ---------------------------------------------------------------------------


def verify(
    mode: str = _DEFAULT_MODE,
    DTYPE: type | None = None,
) -> None:
    """Compile, run, and assert the selected TMA matrix-fragment mode."""

    mode, dtype = _resolve_mode_dtype(mode, DTYPE)
    dtype_name = _NAME_BY_DTYPE.get(dtype, dtype.__name__)
    compiled_fn = compile(mode=mode, DTYPE=dtype)
    print(
        f"Compile kernel (mode={mode}, DTYPE={dtype_name}) OK",
        flush=True,
    )

    dst, src = run(compiled_fn, mode=mode, DTYPE=dtype)
    print(f"Run kernel (mode={mode}, DTYPE={dtype_name}) OK", flush=True)

    if mode in {_MODE_TRANSPOSE, _MODE_B8_TRANSPOSE}:
        expected = src.t().contiguous()
    else:
        expected = src
    torch.testing.assert_close(dst, expected, atol=0, rtol=0)
    print(
        f"verify (mode={mode}, DTYPE={dtype_name}): PASS  expected[:8] =",
        expected.reshape(-1)[:8].tolist(),
        " dst[:8] =",
        dst.reshape(-1)[:8].tolist(),
    )


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="TMA load followed by ldmatrix/stmatrix block-tile consumers",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument(
        "--mode",
        choices=_MODE_CHOICES,
        default=_DEFAULT_MODE,
        help="Example mode to run.",
    )
    parser.add_argument(
        "--dtype",
        choices=sorted([*_B16_DTYPE_BY_NAME, "all"]),
        default="fp16",
        help="b16 payload dtype; b8-transpose always uses uint8.",
    )
    args = parser.parse_args()
    if args.mode == _MODE_B8_TRANSPOSE:
        verify(mode=args.mode)
    else:
        dtypes = (
            list(_B16_DTYPE_BY_NAME.values())
            if args.dtype == "all"
            else [_B16_DTYPE_BY_NAME[args.dtype]]
        )
        for dtype in dtypes:
            verify(mode=args.mode, DTYPE=dtype)
