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
TMA tensormap replacement - patch a mutable descriptor before TMA load.

This is a minimal practice example for the descriptor lifecycle needed by
grouped kernels. CUTLASS creates a normal tensor-map descriptor from the input
tensor. The device kernel copies that descriptor into a mutable 128-byte global
workspace, then replaces two descriptor fields in that workspace:

* ``global_address``: move the descriptor base to a later row of A;
* ``global_dim[1]``: shrink the descriptor M dimension to the active row count.

After a tensormap proxy release/acquire pair, the same kernel uses the patched
descriptor pointer in ``cp_async_bulk_tensor_shared_cta_global``.

Public API (mirrors ``examples/template_kernel.py``):
  - :func:`compile` - AOT factory for the fixed descriptor-replacement shape.
  - :func:`run`     - allocate tensors, call compiled fn, return output/reference.
  - :func:`verify`  - compile + run + assert vs reference.

To run::

    python CuTeDSL/experimental/primitives/tma/tma_tensormap_replace.py

"""

import argparse
from functools import lru_cache
from typing import Callable

import cutlass
import cutlass.experimental.cuda as cuda
import cutlass.cute as cute
import torch
from cutlass.cute.runtime import make_fake_compact_tensor
from cutlass.experimental import primitives as prims


TENSOR_MAP_BYTES = 128
TENSOR_MAP_QWORDS = TENSOR_MAP_BYTES // 8

# Mimic MoE grouped GEMM use case
# A group is identified as starting at offset=17 with 12 valid rows
# It will still load the fixed box, expecting OOB zero-fill for the last 4 rows
ROW_OFFSET = 17
ACTIVE_ROWS = 12
TENSOR_SHAPE = (128, 64)
BOX_DIMS = (16, 32)

CTA_SIZE = 32
COLS_TO_SHOW = 4


@cute.jit
def _copy_tensormap_to_workspace(src_desc_ptr, dst_desc_ptr) -> None:
    src_words = cutlass.Pointer(src_desc_ptr, dtype=cutlass.Int64)
    for i in cutlass.range_constexpr(TENSOR_MAP_QWORDS):
        (dst_desc_ptr + i).store((src_words + i).load())


@cute.jit
def _replace_tensormap_global_address(desc_ptr, new_address: cutlass.Int64) -> None:
    prims.tensormap_replace(
        prims.TensormapField.GLOBAL_ADDRESS,
        desc_ptr,
        new_value=cutlass.Int64(new_address),
    )


@cute.jit
def _replace_tensormap_global_dim(
    desc_ptr, DIM: cutlass.Constexpr[int], new_dim: cutlass.Int32
) -> None:
    prims.tensormap_replace(
        prims.TensormapField.GLOBAL_DIM,
        desc_ptr,
        new_value=cutlass.Int32(new_dim),
        ord=DIM,
    )


@cute.jit
def _fence_tensormap_release() -> None:
    prims.fence_proxy_release(
        prims.MemScope.GPU,
        from_proxy=prims.Proxy.GENERIC,
        to_proxy=prims.Proxy.TENSORMAP,
    )


@cute.jit
def _fence_tensormap_acquire(desc_ptr) -> None:
    prims.fence_proxy_acquire(
        prims.MemScope.GPU,
        desc_ptr,
        TENSOR_MAP_BYTES,
        from_proxy=prims.Proxy.GENERIC,
        to_proxy=prims.Proxy.TENSORMAP,
    )


@cute.kernel
def tma_desc_replace_kernel(
    matrix_a: cute.Tensor,
    tma_desc_a: cutlass.GridConstant[cuda.TensorMap],
    BOX_DIMS: cutlass.Constexpr[tuple[int, int]],
    out_arr: cutlass.Array,
    desc_words: cute.Tensor,
    row_offset: cutlass.Int32,
    active_rows: cutlass.Int32,
) -> None:
    tidx, _, _ = cute.arch.thread_idx()

    box_size = BOX_DIMS[1] * BOX_DIMS[0]
    smem_tile = cutlass.Array(
        cutlass.Float16,
        box_size,
        space=cutlass.AddressSpace.smem,
        alignment=128,
    )
    mbar = cutlass.Array(cutlass.Int64, 1, space=cutlass.AddressSpace.smem, alignment=8)

    if prims.elect_sync():
        prims.mbarrier_init(mbar, 1)

    prims.fence_mbarrier_init()
    prims.barrier_cta_sync(0)

    desc_gmem_ptr = desc_words.iterator.raw_ptr()
    desc_tma_ptr = desc_gmem_ptr.tospace(cutlass.AddressSpace.generic)

    if prims.elect_sync():
        _copy_tensormap_to_workspace(tma_desc_a.get_ptr(), desc_gmem_ptr)
        row_base_ptr = matrix_a.iterator.raw_ptr() + row_offset * matrix_a.shape[1]
        # with this update, we can use group-local tensor coords
        _replace_tensormap_global_address(
            desc_gmem_ptr, row_base_ptr.toint(cutlass.Int64)
        )
        # with this update, TMA can do OOB zero-fill for rows outside of active rows
        _replace_tensormap_global_dim(desc_gmem_ptr, 1, active_rows)
        _fence_tensormap_release()
        _fence_tensormap_acquire(desc_tma_ptr)

        prims.mbarrier_arrive_expect_tx(mbar, tma_desc_a.global_tx_bytes())
        prims.cp_async_bulk_tensor_shared_cta_global(
            smem_tile,
            desc_tma_ptr,
            (0, 0),
            mbar,
        )

    while not prims.mbarrier_try_wait_parity(mbar, 0):
        pass

    # write all rows to verify OOB zero-fill
    # each thread writes one row
    if tidx < BOX_DIMS[0]:
        out_row = out_arr[tidx, :]
        col_start = tidx * BOX_DIMS[1]
        col_end = col_start + COLS_TO_SHOW
        # CUTLASS vector slices are start:count, not Python start:end; spell the
        # dynamic [col_start, col_end) range as a constant-count copy.
        for col in cutlass.range_constexpr(COLS_TO_SHOW):
            out_row[col] = smem_tile[col_end - COLS_TO_SHOW + col]


@cute.jit
def host(
    matrix_a: cute.Tensor,
    BOX_DIMS: cutlass.Constexpr[tuple[int, int]],
    output: cutlass.Array,
    desc_words: cute.Tensor,
    row_offset: cutlass.Int32,
    active_rows: cutlass.Int32,
) -> None:
    tma_desc_a = cuda.create_tensor_map_tiled_from_view(
        matrix_a,
        box_dims=BOX_DIMS,
        stride_order=(1, 0),
        swizzle=cuda.TensorMapSwizzle.none,
    )
    tma_desc_replace_kernel(
        matrix_a,
        tma_desc_a,
        BOX_DIMS,
        output,
        desc_words,
        row_offset,
        active_rows,
    ).launch(grid=(1, 1, 1), block=(CTA_SIZE, 1, 1))


@lru_cache(maxsize=None)
def compile() -> Callable:  # noqa: A001
    """AOT-compile the descriptor-replacement host path."""
    fake_matrix = make_fake_compact_tensor(
        cutlass.Float16,
        TENSOR_SHAPE,
        stride_order=(1, 0),
        assumed_align=16,
    )
    fake_output = make_fake_compact_tensor(
        cutlass.Float16,
        (BOX_DIMS[0], COLS_TO_SHOW),
        stride_order=(1, 0),
        assumed_align=16,
    )
    fake_desc_words = make_fake_compact_tensor(
        cutlass.Int64,
        (TENSOR_MAP_QWORDS,),
        assumed_align=TENSOR_MAP_BYTES,
    )
    return cute.compile(
        host,
        fake_matrix,
        BOX_DIMS,
        fake_output,
        fake_desc_words,
        cutlass.Int32(0),
        cutlass.Int32(0),
        options="--enable-tvm-ffi",
    )


def run(
    compiled_fn: Callable | None = None,
    row_offset: int = ROW_OFFSET,
    active_rows: int = ACTIVE_ROWS,
) -> tuple[torch.Tensor, torch.Tensor]:
    """Allocate inputs, run the kernel, and return ``(output, expected)``."""
    if not torch.cuda.is_available():
        raise RuntimeError("This tutorial requires a CUDA GPU")
    if active_rows < 0 or active_rows > BOX_DIMS[0]:
        raise ValueError(f"active_rows must be in [0, {BOX_DIMS[0]}]")
    if row_offset < 0 or row_offset + BOX_DIMS[0] > TENSOR_SHAPE[0]:
        raise ValueError(
            f"row_offset must keep the {BOX_DIMS[0]}-row box within {TENSOR_SHAPE}"
        )

    cutlass.cuda.initialize_cuda_context()
    compiled_fn = compiled_fn or compile()

    # Source tensor in which m[i, j] = i * 100 + j
    matrix_a = torch.arange(TENSOR_SHAPE[0], device="cuda", dtype=torch.float16).view(
        TENSOR_SHAPE[0], 1
    ) * 100 + torch.arange(TENSOR_SHAPE[1], device="cuda", dtype=torch.float16).view(
        1, TENSOR_SHAPE[1]
    )
    # The output tensor takes one element per ACTIVE_ROW
    output = torch.empty(
        (BOX_DIMS[0], COLS_TO_SHOW), dtype=torch.float16, device="cuda"
    )
    # The TMA descriptor in GEMM that the kernel will patch
    desc_buffer = torch.empty(
        (TENSOR_MAP_QWORDS + (TENSOR_MAP_BYTES // 8),),
        dtype=torch.int64,
        device="cuda",
    )
    byte_offset = (
        TENSOR_MAP_BYTES - (desc_buffer.data_ptr() % TENSOR_MAP_BYTES)
    ) % TENSOR_MAP_BYTES
    element_offset = byte_offset // 8
    desc_words = desc_buffer[element_offset : element_offset + TENSOR_MAP_QWORDS]

    compiled_fn(matrix_a, output, desc_words, row_offset, active_rows)
    torch.cuda.synchronize()

    expected = matrix_a[
        row_offset : row_offset + BOX_DIMS[0], :COLS_TO_SHOW
    ].contiguous()
    expected[active_rows:, :] = 0
    return output, expected


def verify(row_offset: int = ROW_OFFSET, active_rows: int = ACTIVE_ROWS) -> None:
    """Compile, run, and assert the patched TMA descriptor result."""
    compiled_fn = compile()
    print("Compile tma_tensormap_replace OK", flush=True)
    output, expected = run(
        compiled_fn,
        row_offset=row_offset,
        active_rows=active_rows,
    )

    print(
        f"TMA box_dims={BOX_DIMS}, starting offset={row_offset}, "
        f"active/valid rows={active_rows} (remaining rows should be zero-filled)"
    )

    # print one line per row
    print("\nOutput:")
    for i in range(BOX_DIMS[0]):
        print(f"[{', '.join(str(x) for x in output[i, :].cpu().tolist())}, ...]")

    print("\nExpected:")
    for i in range(BOX_DIMS[0]):
        print(f"[{', '.join(str(x) for x in expected[i, :].cpu().tolist())}, ...]")

    torch.testing.assert_close(output, expected, atol=0, rtol=0)
    print("\nPASS")


def main() -> None:
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument("--row_offset", type=int, default=ROW_OFFSET)
    parser.add_argument("--active_rows", type=int, default=ACTIVE_ROWS)
    args = parser.parse_args()
    verify(row_offset=args.row_offset, active_rows=args.active_rows)


if __name__ == "__main__":
    main()
