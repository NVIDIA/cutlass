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

"""Ragged TMA helpers for packed variable-length attention outputs.

The descriptor and coordinate transform implement a synthetic-dimension TMA
scheme. The real packed-row address is preserved while a runtime-valid row
extent is encoded in a TMA dimension, causing rows beyond the current sequence
boundary to become OOB no-ops. Absolute packed-row coordinates must remain
below ``2**30`` so the synthetic coordinates stay in the signed Int32 range.
"""

from typing import Tuple

import cutlass.cute as cute
import cutlass.experimental.cuda as cuda
from cutlass.base_dsl import dsl_user_op
from cutlass.cute.typing import Int32, Int64, Uint8


RAGGED_TMA_MAX_PACKED_ROWS = 1 << 30
_RAGGED_LARGE_N = RAGGED_TMA_MAX_PACKED_ROWS
_RAGGED_XLARGE_N = 1 << 35
_TMA_DIM_MAX = 1 << 31


@dsl_user_op
def create_packed_o_ragged_tma_descriptor(
    packed_o: cute.Tensor,
    *,
    row_box: int,
    column_box: int,
    swizzle: cuda.TensorMapSwizzle,
    loc=None,
    ip=None,
) -> cuda.TensorMap:
    """Create a rank-5 ragged TMA-store descriptor for compact ``[Q,H,D]`` O."""
    if len(packed_o.shape) != 3:
        raise ValueError(
            f"packed ragged O must be rank 3 [Q,H,D], got {packed_o.shape}"
        )

    element_bits = packed_o.element_type.width
    is_packed_fp4 = element_bits == 4
    if is_packed_fp4 and (packed_o.shape[2] % 2 != 0 or column_box % 2 != 0):
        raise ValueError("packed FP4 ragged TMA requires even D and box extents")
    descriptor_dtype = Uint8 if is_packed_fp4 else packed_o.element_type
    descriptor_columns = packed_o.shape[2] // 2 if is_packed_fp4 else packed_o.shape[2]
    descriptor_column_box = column_box // 2 if is_packed_fp4 else column_box
    head_stride_16b = Int64(packed_o.stride[1] * element_bits // 128)
    row_stride_16b = Int64(packed_o.stride[0] * element_bits // 128)
    xlarge_n_stride_16b = Int64(_RAGGED_XLARGE_N * element_bits // 128)

    return cuda.create_tensor_map_tiled(
        global_address=packed_o.iterator.toint(),
        dtype=descriptor_dtype,
        global_dims=[
            descriptor_columns,
            packed_o.shape[1],
            row_box,
            _TMA_DIM_MAX,
            _TMA_DIM_MAX,
        ],
        global_strides=[
            head_stride_16b,
            row_stride_16b,
            xlarge_n_stride_16b - row_stride_16b,
            row_stride_16b,
        ],
        box_dims=[descriptor_column_box, 1, row_box, 1, 1],
        swizzle=swizzle,
        oob_fill=cuda.TensorMapFloatOOBFill.none,
        loc=loc,
        ip=ip,
    )


def transform_packed_o_ragged_coords(
    column: Int32 | int,
    head: Int32 | int,
    row: Int32 | int,
    *,
    row_box: int,
    row_extent: Int32 | int,
) -> Tuple[Int32, Int32, Int32, Int32, Int32]:
    """Encode a tile-local valid row extent into rank-5 TMA coordinates."""
    box = Int32(row_box)
    extent = Int32(row_extent)

    is_negative = Int32(extent < Int32(0))
    extent = extent - extent * is_negative
    is_over = Int32(extent > box)
    extent = extent + (box - extent) * is_over

    extent_mod = extent % box
    distance = box - extent_mod
    dimension_offset = distance % box
    is_empty = Int32(extent == Int32(0))
    dimension_offset = dimension_offset + box * is_empty

    large_n = Int32(_RAGGED_LARGE_N)
    balance = Int32(0) - dimension_offset
    return (
        Int32(column),
        Int32(head),
        dimension_offset,
        large_n,
        Int32(row) + large_n + balance,
    )


def get_packed_o_tma_config(
    storage_columns: int,
    element_bits: int,
) -> Tuple[int, int, cuda.TensorMapSwizzle]:
    """Return ``(chunk_columns, chunk_count, swizzle)`` matching SMEM O."""
    contiguous_bits = storage_columns * element_bits
    for chunk_bits, swizzle in (
        (1024, cuda.TensorMapSwizzle.s128b),
        (512, cuda.TensorMapSwizzle.s64b),
        (256, cuda.TensorMapSwizzle.s32b),
        (128, cuda.TensorMapSwizzle.none),
    ):
        if contiguous_bits % chunk_bits == 0:
            break
    else:
        raise ValueError(
            "packed ragged O requires a D extent divisible by 16 bytes, got "
            f"{contiguous_bits} bits"
        )

    chunk_columns = chunk_bits // element_bits
    if storage_columns % chunk_columns != 0:
        raise ValueError(
            f"storage D={storage_columns} is not divisible by TMA chunk "
            f"D={chunk_columns}"
        )
    return chunk_columns, storage_columns // chunk_columns, swizzle


__all__ = [
    "RAGGED_TMA_MAX_PACKED_ROWS",
    "create_packed_o_ragged_tma_descriptor",
    "get_packed_o_tma_config",
    "transform_packed_o_ragged_coords",
]
