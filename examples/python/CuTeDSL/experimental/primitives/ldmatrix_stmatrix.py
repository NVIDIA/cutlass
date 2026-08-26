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
Standalone ldmatrix/stmatrix register-fragment mapping examples.

Use this file when the question is per-lane row starts, register packing,
fragment count, or b8 carrier order.  Producer-specific examples show how the
same matrix instructions fit after TMA or TMEM.

Pick a mode with ``--mode`` and read that kernel's row-start and source-word
order.  ``xN`` is an instruction fragment count, not a logical layout guarantee.
Packed-b8 modes keep b8 payload in b16/i32 carrier words; they do not convert
bytes to numeric b16 values.  Matrix stores write 16B address rows, so the
examples keep instruction-specific packing next to the ``stmatrix`` call.

Public API:
  - ``compile(mode=..., NUM_TILES=..., DTYPE=...)`` returns an AOT callable.
  - ``run(compiled_fn, mode=..., NUM_TILES=..., DTYPE=...)`` allocates random
    inputs, runs the callable, and returns ``dst, src``.
  - ``verify(mode=..., NUM_TILES=..., DTYPE=...)`` checks ``dst`` against
    ``src`` or ``src.t()`` for the selected mode.

To run::

    python CuTeDSL/experimental/primitives/ldmatrix_stmatrix.py
    python CuTeDSL/experimental/primitives/ldmatrix_stmatrix.py --mode b8-stmatrix-transpose --NUM_TILES 2

"""

from __future__ import annotations

import argparse
from functools import lru_cache
from typing import Callable, NamedTuple

import torch

import cutlass
import cutlass.cute as cute
from cutlass.experimental import primitives as prims
from cutlass.cute.runtime import make_fake_compact_tensor, make_fake_stream
import cuda.bindings.driver as cuda


# ---------------------------------------------------------------------------
# Kernel Configurations - fixed
# ---------------------------------------------------------------------------

_WARP_SIZE: int = 32
_B16_FRAGMENT_ROWS: int = 8
_B16_FRAGMENT_COLS: int = 8
_B16_FRAGMENT_ELEMS: int = _B16_FRAGMENT_ROWS * _B16_FRAGMENT_COLS
_TILE_M: int = 16
_TILE_N: int = 16
_TILE_ELEMS: int = _TILE_M * _TILE_N
_ELEMS_PER_LANE: int = _TILE_ELEMS // _WARP_SIZE
_B8_TILE_M: int = 16
_B8_TILE_N: int = 8
_B8_TILE_ELEMS: int = _B8_TILE_M * _B8_TILE_N
_B8_ELEMS_PER_LANE: int = _B8_TILE_ELEMS // _WARP_SIZE
# The fixed logical ldmatrix.m16n16.b8 paths use the current two-word wrapper
# carrier.  Keep this separate from public xN mode selection.
_B8_M16N16_WORDS_PER_LANE: int = 2


# ---------------------------------------------------------------------------
# Kernel Configurations - tunable
# ---------------------------------------------------------------------------

_DEFAULT_NUM_TILES: int = 4
_DEFAULT_B16_DTYPE: type = cutlass.Float16
_DEFAULT_B8_DTYPE: type = cutlass.Uint8
_XN_NUM_TILES_CASES: tuple[int, ...] = (1, 2, 4)
# The b8 store-side example skips x1 so every public output row is a full 16B
# stmatrix row rather than a padded 8-column half-row.
_B8_STMATRIX_NUM_TILES_CASES: tuple[int, ...] = (2, 4)

_MODE_B16_ROUNDTRIP = "b16-roundtrip"
_MODE_B16_STMATRIX_TRANSPOSE = "b16-stmatrix-transpose"
_MODE_B16_LDMATRIX_TRANSPOSE = "b16-ldmatrix-transpose"
_MODE_B8_ROUNDTRIP = "b8-roundtrip"
_MODE_B8_STMATRIX_TRANSPOSE = "b8-stmatrix-transpose"
_MODE_B8_LDMATRIX_TRANSPOSE = "b8-ldmatrix-transpose"

_MODE_CHOICES: tuple[str, ...] = (
    _MODE_B16_ROUNDTRIP,
    _MODE_B16_STMATRIX_TRANSPOSE,
    _MODE_B16_LDMATRIX_TRANSPOSE,
    _MODE_B8_ROUNDTRIP,
    _MODE_B8_STMATRIX_TRANSPOSE,
    _MODE_B8_LDMATRIX_TRANSPOSE,
)

_B16_DTYPE_BY_NAME: dict[str, type] = {
    "fp16": cutlass.Float16,
    "bf16": cutlass.BFloat16,
}
_B8_DTYPE_BY_NAME: dict[str, type] = {
    "fp8e4m3": cutlass.Float8E4M3FN,
    "uint8": cutlass.Uint8,
}
_DTYPE_BY_NAME: dict[str, type] = {**_B16_DTYPE_BY_NAME, **_B8_DTYPE_BY_NAME}
_NAME_BY_DTYPE: dict[type, str] = {
    dtype: name for name, dtype in _DTYPE_BY_NAME.items()
}
_TORCH_DTYPE_BY_CUTLASS: dict[type, torch.dtype] = {
    cutlass.Float16: torch.float16,
    cutlass.BFloat16: torch.bfloat16,
    cutlass.Float8E4M3FN: torch.float8_e4m3fn,
    cutlass.Uint8: torch.uint8,
}


def _zip_b8_low_half(left, right):
    left_u32 = left.to(cutlass.Uint32)
    right_u32 = right.to(cutlass.Uint32)
    return (left_u32 & cutlass.Uint32(0x0000FFFF)) | (
        (right_u32 & cutlass.Uint32(0x0000FFFF)) << cutlass.Uint32(16)
    )


def _zip_b8_high_half(left, right):
    left_u32 = left.to(cutlass.Uint32)
    right_u32 = right.to(cutlass.Uint32)
    return ((left_u32 >> cutlass.Uint32(16)) & cutlass.Uint32(0x0000FFFF)) | (
        right_u32 & cutlass.Uint32(0xFFFF0000)
    )


@cute.jit
def _redistribute_b8_pair_for_stmatrix(left, right, lane):
    """Zip b8 carrier words, then group them for contiguous stmatrix rows."""

    low_word = _zip_b8_low_half(left, right)
    high_word = _zip_b8_high_half(left, right)
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
    return word0, word1


@cute.jit
def _copy_elementwise_src_to_smem(src, smem, tidx, rows, cols):
    """Copy public tensor elements into matching SMEM coordinates."""

    for i in cutlass.range_constexpr((rows * cols) // _WARP_SIZE):
        flat = tidx + i * _WARP_SIZE
        row = flat // cols
        col = flat % cols
        smem[row, col] = src[row, col]


@cute.jit
def _copy_elementwise_smem_to_dst(smem, dst, tidx, rows, cols):
    """Copy SMEM elements back to matching public tensor coordinates."""

    for i in cutlass.range_constexpr((rows * cols) // _WARP_SIZE):
        flat = tidx + i * _WARP_SIZE
        row = flat // cols
        col = flat % cols
        dst[row, col] = smem[row, col]


# ---------------------------------------------------------------------------
# Device kernels
# ---------------------------------------------------------------------------


@cute.kernel
def kernel_b16_roundtrip(
    src: cute.Tensor,
    dst: cute.Tensor,
    DTYPE: cutlass.Constexpr[type],
    NUM_TILES: cutlass.Constexpr[int],
) -> None:
    """Load shared-memory tiles with ldmatrix.xN, store back with stmatrix.xN."""

    tid, _, _ = cute.arch.thread_idx()
    smem_shape = (
        NUM_TILES * _B16_FRAGMENT_ROWS,
        _B16_FRAGMENT_COLS,
    )
    smem_in = cutlass.Array(
        DTYPE, smem_shape, space=cutlass.AddressSpace.smem, alignment=128
    )
    smem_out = cutlass.Array(
        DTYPE, smem_shape, space=cutlass.AddressSpace.smem, alignment=128
    )

    _copy_elementwise_src_to_smem(
        src, smem_in, tid, NUM_TILES * _B16_FRAGMENT_ROWS, _B16_FRAGMENT_COLS
    )

    prims.barrier_cta_sync(0)

    row_ptr = smem_in.data_ptr() + tid * _B16_FRAGMENT_COLS
    vec = prims.ldmatrix(row_ptr, NUM_TILES, prims.MMALayout.ROW)

    out_ptr = smem_out.data_ptr() + tid * _B16_FRAGMENT_COLS
    prims.stmatrix(out_ptr, vec, prims.MMALayout.ROW)

    prims.barrier_cta_sync(0)

    _copy_elementwise_smem_to_dst(
        smem_out, dst, tid, NUM_TILES * _B16_FRAGMENT_ROWS, _B16_FRAGMENT_COLS
    )


@cute.kernel
def kernel_b16_stmatrix_transpose(
    src: cute.Tensor,
    dst: cute.Tensor,
    DTYPE: cutlass.Constexpr[type],
    NUM_TILES: cutlass.Constexpr[int],
) -> None:
    """Transpose b16 xN fragments with ``ldmatrix`` + ``stmatrix.trans``."""

    tidx, _, _ = cute.arch.thread_idx()
    smem_shape = (
        NUM_TILES * _B16_FRAGMENT_ROWS,
        _B16_FRAGMENT_COLS,
    )
    smem_out_logical_cols = NUM_TILES * _B16_FRAGMENT_ROWS
    smem_out_cols = smem_out_logical_cols
    # Keep public dst coordinates, but pad the physical stmatrix pitch: x2/x4
    # 32B/64B row strides revisit bank quartets; 48B/80B strides do not.
    if cutlass.const_expr(NUM_TILES > 1):
        smem_out_cols = smem_out_cols + _B16_FRAGMENT_ROWS
    smem_out_shape = (
        _B16_FRAGMENT_COLS,
        smem_out_cols,
    )
    smem_in_row_elems = _B16_FRAGMENT_COLS
    smem_in = cutlass.Array(
        DTYPE, smem_shape, space=cutlass.AddressSpace.smem, alignment=128
    )
    smem_out = cutlass.Array(
        DTYPE, smem_out_shape, space=cutlass.AddressSpace.smem, alignment=128
    )

    _copy_elementwise_src_to_smem(
        src, smem_in, tidx, NUM_TILES * _B16_FRAGMENT_ROWS, smem_in_row_elems
    )

    prims.barrier_cta_sync(0)

    lane = tidx % _WARP_SIZE
    matrix = lane // _B16_FRAGMENT_ROWS
    row = lane % _B16_FRAGMENT_ROWS
    in_row_start = matrix * _B16_FRAGMENT_ELEMS + row * smem_in_row_elems

    regs = prims.ldmatrix(
        smem_in.data_ptr() + in_row_start,
        NUM_TILES,
        prims.MMALayout.ROW,
    )
    # Store the transposed rows directly into the public output coordinates.
    out_row_start = row * smem_out_cols + matrix * _B16_FRAGMENT_ROWS
    prims.stmatrix(
        smem_out.data_ptr() + out_row_start,
        regs,
        prims.MMALayout.COL,
    )

    prims.barrier_cta_sync(0)

    _copy_elementwise_smem_to_dst(
        smem_out, dst, tidx, _B16_FRAGMENT_COLS, smem_out_logical_cols
    )


@cute.kernel
def kernel_b16_ldmatrix_transpose(
    src: cute.Tensor,
    dst: cute.Tensor,
    DTYPE: cutlass.Constexpr[type],
    NUM_TILES: cutlass.Constexpr[int],
) -> None:
    """Transpose b16 xN fragments with ``ldmatrix.trans`` + ``stmatrix``."""

    tidx, _, _ = cute.arch.thread_idx()
    smem_shape = (
        NUM_TILES * _B16_FRAGMENT_ROWS,
        _B16_FRAGMENT_COLS,
    )
    smem_out_logical_cols = NUM_TILES * _B16_FRAGMENT_ROWS
    smem_out_cols = smem_out_logical_cols
    # Keep public dst coordinates, but pad the physical stmatrix pitch: x2/x4
    # 32B/64B row strides revisit bank quartets; 48B/80B strides do not.
    if cutlass.const_expr(NUM_TILES > 1):
        smem_out_cols = smem_out_cols + _B16_FRAGMENT_ROWS
    smem_out_shape = (
        _B16_FRAGMENT_COLS,
        smem_out_cols,
    )
    smem_in_row_elems = _B16_FRAGMENT_COLS
    smem_in = cutlass.Array(
        DTYPE, smem_shape, space=cutlass.AddressSpace.smem, alignment=128
    )
    smem_out = cutlass.Array(
        DTYPE, smem_out_shape, space=cutlass.AddressSpace.smem, alignment=128
    )

    _copy_elementwise_src_to_smem(
        src, smem_in, tidx, NUM_TILES * _B16_FRAGMENT_ROWS, smem_in_row_elems
    )

    prims.barrier_cta_sync(0)

    lane = tidx % _WARP_SIZE
    matrix = lane // _B16_FRAGMENT_ROWS
    row = lane % _B16_FRAGMENT_ROWS
    in_row_start = matrix * _B16_FRAGMENT_ELEMS + row * smem_in_row_elems

    regs = prims.ldmatrix(
        smem_in.data_ptr() + in_row_start,
        NUM_TILES,
        prims.MMALayout.COL,
    )
    # Store the transposed rows directly into the public output coordinates.
    out_row_start = row * smem_out_cols + matrix * _B16_FRAGMENT_ROWS
    prims.stmatrix(
        smem_out.data_ptr() + out_row_start,
        regs,
        prims.MMALayout.ROW,
    )

    prims.barrier_cta_sync(0)

    _copy_elementwise_smem_to_dst(
        smem_out, dst, tidx, _B16_FRAGMENT_COLS, smem_out_logical_cols
    )


@cute.kernel
def kernel_b8_roundtrip(
    src: cute.Tensor,
    dst: cute.Tensor,
    DTYPE: cutlass.Constexpr[type],
    NUM_TILES: cutlass.Constexpr[int],
) -> None:
    """Load one b8 16x16 tile and publish it with ``stmatrix``."""

    tidx, _, _ = cute.arch.thread_idx()
    smem_in = cutlass.Array(
        DTYPE,
        (_TILE_M, _TILE_N),
        space=cutlass.AddressSpace.smem,
        alignment=128,
    )
    smem_out = cutlass.Array(
        DTYPE,
        (_TILE_M, _TILE_N),
        space=cutlass.AddressSpace.smem,
        alignment=128,
    )

    _copy_elementwise_src_to_smem(src, smem_in, tidx, _TILE_M, _TILE_N)

    prims.barrier_cta_sync(0)

    lane = tidx % _WARP_SIZE
    row_start = (lane % 16) * 16
    # Two words are the wrapper carrier for one fixed 16x16 tile, not public x2.
    regs = prims.ldmatrix(
        smem_in.data_ptr() + row_start,
        _B8_M16N16_WORDS_PER_LANE,
        prims.MMALayout.COL,
        shape=prims.LoadShape.M16N16,
        src_format=prims.LoadSrcFormat.B8,
    )

    word0, word1 = _redistribute_b8_pair_for_stmatrix(regs[0], regs[1], lane)
    logical_row = ((lane // 8) % _B8_M16N16_WORDS_PER_LANE) * 8 + (lane % 8)
    row_start = logical_row * 16
    prims.stmatrix(
        smem_out.data_ptr() + row_start,
        [word0, word1],
        prims.MMALayout.COL,
        shape=prims.StoreShape.M16N8,
    )

    prims.barrier_cta_sync(0)

    _copy_elementwise_smem_to_dst(smem_out, dst, tidx, _TILE_M, _TILE_N)


@cute.kernel
def kernel_b8_stmatrix_transpose(
    src: cute.Tensor,
    dst: cute.Tensor,
    DTYPE: cutlass.Constexpr[type],
    NUM_TILES: cutlass.Constexpr[int],
) -> None:
    """Transpose b8 using ``ldmatrix.m8n8.b16`` as a packed-byte carrier."""

    tidx, _, _ = cute.arch.thread_idx()
    smem_in = cutlass.Array(
        DTYPE,
        (NUM_TILES * _B8_TILE_N, _B8_TILE_M),
        space=cutlass.AddressSpace.smem,
        alignment=128,
    )
    smem_out_logical_cols = NUM_TILES * _B8_TILE_N
    smem_out_cols = smem_out_logical_cols
    # x4's 32B row pitch repeats bank quartets for rows 0..7.  Add one 16B
    # fragment to the physical pitch; the final copy ignores padded columns.
    if cutlass.const_expr(NUM_TILES == 4):
        smem_out_cols = smem_out_cols + _B8_TILE_M
    smem_out = cutlass.Array(
        DTYPE,
        (_B8_TILE_M, smem_out_cols),
        space=cutlass.AddressSpace.smem,
        alignment=128,
    )

    _copy_elementwise_src_to_smem(
        src, smem_in, tidx, NUM_TILES * _B8_TILE_N, _B8_TILE_M
    )

    prims.barrier_cta_sync(0)

    lane = tidx % _WARP_SIZE
    load_segment = (lane // 8) % NUM_TILES
    load_row = load_segment * 8 + (lane % 8)
    regs = prims.ldmatrix(
        smem_in.data_ptr() + load_row * 16,
        NUM_TILES,
        prims.MMALayout.ROW,
    )

    # Redistribute the packed bytes so each stmatrix.x2 group uses contiguous
    # row addresses; the natural public-row interleave repeats bank quartets.
    row_start = (((lane // 8) % 2) * 8 + (lane % 8)) * smem_out_cols

    for pair in cutlass.range_constexpr(NUM_TILES // 2):
        lhs = pair * 2
        word0, word1 = _redistribute_b8_pair_for_stmatrix(
            regs[lhs], regs[lhs + 1], lane
        )
        prims.stmatrix(
            smem_out.data_ptr() + row_start + pair * _B8_TILE_M,
            [word0, word1],
            prims.MMALayout.COL,
            shape=prims.StoreShape.M16N8,
        )

    prims.barrier_cta_sync(0)

    _copy_elementwise_smem_to_dst(
        smem_out, dst, tidx, _B8_TILE_M, smem_out_logical_cols
    )


@cute.kernel
def kernel_b8_ldmatrix_transpose(
    src: cute.Tensor,
    dst: cute.Tensor,
    DTYPE: cutlass.Constexpr[type],
    NUM_TILES: cutlass.Constexpr[int],
) -> None:
    """Transpose b8 with ``ldmatrix.m16n16.trans`` and packed-byte ``stmatrix``."""

    tidx, _, _ = cute.arch.thread_idx()
    smem_in = cutlass.Array(
        DTYPE,
        (_TILE_M, _TILE_N),
        space=cutlass.AddressSpace.smem,
        alignment=128,
    )
    smem_out = cutlass.Array(
        DTYPE,
        (_TILE_M, _TILE_N),
        space=cutlass.AddressSpace.smem,
        alignment=128,
    )

    _copy_elementwise_src_to_smem(src, smem_in, tidx, _TILE_M, _TILE_N)

    prims.barrier_cta_sync(0)

    lane = tidx % _WARP_SIZE
    row_start = (lane % 16) * 16
    regs = prims.ldmatrix(
        smem_in.data_ptr() + row_start,
        _B8_M16N16_WORDS_PER_LANE,
        prims.MMALayout.COL,
        shape=prims.LoadShape.M16N16,
        src_format=prims.LoadSrcFormat.B8,
    )

    carrier_tile = (lane // 8) % 2
    carrier_row = lane % 8
    carrier_row_start = (carrier_tile * 8 + carrier_row) * 16
    prims.stmatrix(
        smem_out.data_ptr() + carrier_row_start,
        [regs[0], regs[1]],
        prims.MMALayout.ROW,
    )

    prims.barrier_cta_sync(0)

    _copy_elementwise_smem_to_dst(smem_out, dst, tidx, _TILE_M, _TILE_N)


# ---------------------------------------------------------------------------
# Host launcher
# ---------------------------------------------------------------------------


@cute.jit
def host_ldmatrix_stmatrix(
    src: cute.Tensor,
    dst: cute.Tensor,
    stream,
    KERNEL: cutlass.Constexpr[object],
    DTYPE: cutlass.Constexpr[type],
    NUM_TILES: cutlass.Constexpr[int],
) -> None:
    """Launch one warp for the selected ldmatrix/stmatrix kernel."""

    KERNEL(src, dst, DTYPE, NUM_TILES).launch(
        grid=(1, 1, 1),
        block=(_WARP_SIZE, 1, 1),
        stream=stream,
    )


# ---------------------------------------------------------------------------
# Compile factory
# ---------------------------------------------------------------------------


class _ModeConfig(NamedTuple):
    kernel_fn: Callable
    m: int
    n: int
    kernel_num_tiles: int
    public_num_tiles_cases: tuple[int, ...] | None


# xN-capable modes enumerate all public instruction counts.  The fixed
# m16n16.b8 modes keep ``public_num_tiles_cases=None`` because they cover one
# logical 16x16 tile; the two i32 carrier words per lane are the wrapper return
# shape, not a public NUM_TILES selector.
_MODE_CONFIG_BY_NAME: dict[str, _ModeConfig] = {
    _MODE_B16_ROUNDTRIP: _ModeConfig(
        kernel_fn=kernel_b16_roundtrip,
        m=_B16_FRAGMENT_ROWS,
        n=_B16_FRAGMENT_COLS,
        kernel_num_tiles=4,
        public_num_tiles_cases=_XN_NUM_TILES_CASES,
    ),
    _MODE_B16_STMATRIX_TRANSPOSE: _ModeConfig(
        kernel_fn=kernel_b16_stmatrix_transpose,
        m=_B16_FRAGMENT_ROWS,
        n=_B16_FRAGMENT_COLS,
        kernel_num_tiles=4,
        public_num_tiles_cases=_XN_NUM_TILES_CASES,
    ),
    _MODE_B16_LDMATRIX_TRANSPOSE: _ModeConfig(
        kernel_fn=kernel_b16_ldmatrix_transpose,
        m=_B16_FRAGMENT_ROWS,
        n=_B16_FRAGMENT_COLS,
        kernel_num_tiles=4,
        public_num_tiles_cases=_XN_NUM_TILES_CASES,
    ),
    _MODE_B8_ROUNDTRIP: _ModeConfig(
        kernel_fn=kernel_b8_roundtrip,
        m=_TILE_M,
        n=_TILE_N,
        kernel_num_tiles=1,
        public_num_tiles_cases=None,
    ),
    _MODE_B8_STMATRIX_TRANSPOSE: _ModeConfig(
        kernel_fn=kernel_b8_stmatrix_transpose,
        m=_B8_TILE_N,
        n=_B8_TILE_M,
        kernel_num_tiles=2,
        public_num_tiles_cases=_B8_STMATRIX_NUM_TILES_CASES,
    ),
    _MODE_B8_LDMATRIX_TRANSPOSE: _ModeConfig(
        kernel_fn=kernel_b8_ldmatrix_transpose,
        m=_TILE_M,
        n=_TILE_N,
        kernel_num_tiles=1,
        public_num_tiles_cases=None,
    ),
}


def _resolve_mode(
    mode: str,
    num_tiles: int | None,
    dtype: type | None,
) -> tuple[_ModeConfig, int, type]:
    config = _MODE_CONFIG_BY_NAME.get(mode)
    if config is None:
        valid = ", ".join(_MODE_CHOICES)
        raise ValueError(f"mode must be one of {valid}; got {mode!r}")

    if config.public_num_tiles_cases is None:
        if num_tiles is not None:
            raise ValueError(
                f"{mode} does not expose NUM_TILES; it uses a fixed 16x16 b8 "
                "m16n16/m16n8 carrier path"
            )
        resolved_num_tiles = config.kernel_num_tiles
    else:
        resolved_num_tiles = config.kernel_num_tiles if num_tiles is None else num_tiles
    if (
        config.public_num_tiles_cases is not None
        and resolved_num_tiles not in config.public_num_tiles_cases
    ):
        valid = ", ".join(str(value) for value in config.public_num_tiles_cases)
        raise ValueError(
            f"{mode} example is defined for NUM_TILES in {{{valid}}}; "
            f"got {resolved_num_tiles}"
        )

    if mode.startswith("b8-"):
        resolved_dtype = _DEFAULT_B8_DTYPE if dtype is None else dtype
        if resolved_dtype not in _B8_DTYPE_BY_NAME.values():
            valid = ", ".join(sorted(_B8_DTYPE_BY_NAME))
            raise ValueError(
                f"{mode} DTYPE must be one of {valid}; got {resolved_dtype.__name__}"
            )
        return config, resolved_num_tiles, resolved_dtype

    resolved_dtype = _DEFAULT_B16_DTYPE if dtype is None else dtype
    if resolved_dtype not in _B16_DTYPE_BY_NAME.values():
        valid = ", ".join(sorted(_B16_DTYPE_BY_NAME))
        raise ValueError(
            f"{mode} DTYPE must be one of {valid}; got {resolved_dtype.__name__}"
        )
    return config, resolved_num_tiles, resolved_dtype


@lru_cache(maxsize=None)
def compile(  # noqa: A001
    mode: str = _MODE_B16_ROUNDTRIP,
    NUM_TILES: int | None = None,
    DTYPE: type | None = None,
) -> Callable:
    """AOT-compile the selected ldmatrix/stmatrix mode."""

    config, num_tiles, dtype = _resolve_mode(mode, NUM_TILES, DTYPE)
    m = config.m if config.public_num_tiles_cases is None else config.m * num_tiles
    src_shape = (m, config.n)
    dst_shape = (config.n, m) if mode.endswith("-transpose") else src_shape
    compile_args = [
        host_ldmatrix_stmatrix,
        make_fake_compact_tensor(
            dtype, src_shape, stride_order=(1, 0), assumed_align=16
        ),
        make_fake_compact_tensor(
            dtype, dst_shape, stride_order=(1, 0), assumed_align=16
        ),
        make_fake_stream(),
        config.kernel_fn,
        dtype,
        num_tiles,
    ]
    return cute.compile(*compile_args, options="--enable-tvm-ffi")


# ---------------------------------------------------------------------------
# Run
# ---------------------------------------------------------------------------


def _make_random_src(shape: tuple[int, int], torch_dtype: torch.dtype) -> torch.Tensor:
    """Create a host-initialized source tensor in the requested public dtype."""

    if torch_dtype == torch.uint8:
        return torch.randint(
            0,
            128,
            shape,
            dtype=torch.int32,
            device="cuda",
        ).to(torch_dtype)

    values = torch.randint(
        -16,
        17,
        shape,
        dtype=torch.int32,
        device="cuda",
    ).to(torch.float32)
    return values.to(torch_dtype)


def run(
    compiled_fn: Callable,
    mode: str = _MODE_B16_ROUNDTRIP,
    NUM_TILES: int | None = None,
    DTYPE: type | None = None,
) -> tuple[torch.Tensor, torch.Tensor]:
    """Allocate host-initialized tensors, call compiled_fn, return ``dst, src``."""

    if not torch.cuda.is_available():
        raise RuntimeError("CUDA GPU required")

    config, num_tiles, dtype = _resolve_mode(mode, NUM_TILES, DTYPE)
    m = config.m if config.public_num_tiles_cases is None else config.m * num_tiles
    src_shape = (m, config.n)
    dst_shape = (config.n, m) if mode.endswith("-transpose") else src_shape
    torch_dtype = _TORCH_DTYPE_BY_CUTLASS[dtype]
    src = _make_random_src(src_shape, torch_dtype)
    dst = torch.empty(dst_shape, dtype=torch_dtype, device="cuda")
    stream = cuda.CUstream(torch.cuda.current_stream().cuda_stream)
    compiled_fn(src, dst, stream)
    torch.cuda.synchronize()
    return dst, src


# ---------------------------------------------------------------------------
# Verify
# ---------------------------------------------------------------------------


def _assert_equal(dst: torch.Tensor, expected: torch.Tensor) -> None:
    """Assert exact tensor equality, using float views for fp8 tensors."""

    if dst.dtype == torch.float8_e4m3fn:
        torch.testing.assert_close(dst.float(), expected.float(), atol=0, rtol=0)
        return
    torch.testing.assert_close(dst, expected, atol=0, rtol=0)


def verify(
    mode: str = _MODE_B16_ROUNDTRIP,
    NUM_TILES: int | None = None,
    DTYPE: type | None = None,
) -> None:
    """Compile, run, and assert the selected mode against its reference."""

    config, num_tiles, dtype = _resolve_mode(mode, NUM_TILES, DTYPE)
    public_num_tiles = None if config.public_num_tiles_cases is None else num_tiles
    num_tiles_label = "fixed" if public_num_tiles is None else str(num_tiles)
    dtype_name = _NAME_BY_DTYPE.get(dtype, dtype.__name__)
    compiled_fn = compile(mode=mode, NUM_TILES=public_num_tiles, DTYPE=dtype)
    print(
        f"Compile kernel (mode={mode}, NUM_TILES={num_tiles_label}, "
        f"DTYPE={dtype_name}) OK",
        flush=True,
    )

    dst, src = run(compiled_fn, mode=mode, NUM_TILES=public_num_tiles, DTYPE=dtype)
    print(
        f"Run kernel (mode={mode}, NUM_TILES={num_tiles_label}, DTYPE={dtype_name}) OK",
        flush=True,
    )

    expected = src.t().contiguous() if mode.endswith("-transpose") else src
    _assert_equal(dst, expected)
    print(
        f"verify (mode={mode}, NUM_TILES={num_tiles_label}, "
        f"DTYPE={dtype_name}): PASS  "
        f"shape={tuple(dst.shape)}",
        flush=True,
    )


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="ldmatrix / stmatrix matrix-fragment examples",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument(
        "--mode",
        choices=_MODE_CHOICES,
        default=_MODE_B16_ROUNDTRIP,
        help="Example mode to run.",
    )
    parser.add_argument(
        "--NUM_TILES",
        type=int,
        default=None,
        choices=[1, 2, 4],
        help="Run one NUM_TILES case; omitted runs this mode's example cases.",
    )
    parser.add_argument(
        "--dtype",
        choices=sorted([*_DTYPE_BY_NAME, "all"]),
        default=None,
        help=(
            "Matrix element dtype. Omitted uses fp16 for b16 modes and uint8 "
            "for b8 modes; 'all' runs every dtype valid for the selected mode."
        ),
    )
    args = parser.parse_args()

    config = _MODE_CONFIG_BY_NAME[args.mode]
    num_tiles_values = (
        (None,)
        if config.public_num_tiles_cases is None
        else config.public_num_tiles_cases
    )
    if args.NUM_TILES is not None:
        num_tiles_values = (args.NUM_TILES,)

    if args.mode.startswith("b8-"):
        dtype_table = _B8_DTYPE_BY_NAME
        default_dtype = _DEFAULT_B8_DTYPE
    else:
        dtype_table = _B16_DTYPE_BY_NAME
        default_dtype = _DEFAULT_B16_DTYPE

    if args.dtype is None:
        dtype_values = (default_dtype,)
    elif args.dtype == "all":
        dtype_values = tuple(dtype_table.values())
    else:
        if args.dtype not in dtype_table:
            parser.error(
                f"{args.mode} supports --dtype values: {', '.join(sorted(dtype_table))}"
            )
        dtype_values = (_DTYPE_BY_NAME[args.dtype],)

    for dtype in dtype_values:
        for num_tiles in num_tiles_values:
            verify(
                mode=args.mode,
                NUM_TILES=num_tiles,
                DTYPE=dtype,
            )
