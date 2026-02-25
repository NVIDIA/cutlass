# Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

"""
Dataclass Example: Passing Pointers via Frozen Dataclass
=========================================================

Demonstrates passing pointers from tensor arguments in `@cute.jit` to `@cute.kernel`
using `@dataclass(frozen=True)`.

Uses fake tensors for compilation and TVM-FFI for efficient runtime dispatch.

To run:

.. code-block:: bash

    python examples/python/CuTeDSL/cute/dataclass_examples.py

"""

from dataclasses import dataclass

import cutlass
import cutlass.cute as cute
from cutlass import Int32


@dataclass(frozen=True)
class CopyParams:
    """
    Dataclass with one static attribute and two pointers from tensors.

    Attributes:
        num_threads: Threads per block (static - used for loop unrolling)
        src_ptr: Pointer to source tensor (dynamic - from mSrc.iterator)
        dst_ptr: Pointer to destination tensor (dynamic - from mDst.iterator)
    """

    num_threads: int  # static
    src_ptr: cute.Pointer  # dynamic
    dst_ptr: cute.Pointer  # dynamic


@cute.jit
def memcpy_jit(mSrc: cute.Tensor, mDst: cute.Tensor, num_threads: cutlass.Constexpr[int]):
    """Host function - extracts pointers from tensors and passes via dataclass."""
    params = CopyParams(
        num_threads=num_threads,
        src_ptr=mSrc.iterator,
        dst_ptr=mDst.iterator,
    )

    N = mSrc.shape[0]
    num_blocks = cute.ceil_div(N, num_threads)

    memcpy_kernel(params, mSrc.layout, N).launch(
        grid=[num_blocks, 1, 1],
        block=[num_threads, 1, 1],
    )


@cute.kernel
def memcpy_kernel(params: CopyParams, layout: cute.Layout, N: Int32):
    """Device kernel - receives pointers via CopyParams dataclass."""
    tidx, _, _ = cute.arch.thread_idx()
    bidx, _, _ = cute.arch.block_idx()

    idx = bidx * params.num_threads + tidx

    mSrc = cute.make_tensor(params.src_ptr, layout)
    mDst = cute.make_tensor(params.dst_ptr, layout)

    if idx < N:
        mDst[idx] = mSrc[idx]


if __name__ == "__main__":
    import torch
    from cutlass.cute.runtime import make_fake_compact_tensor

    N = 1024

    # 1. Create fake tensors for compilation (no GPU memory allocated)
    fake_src = make_fake_compact_tensor(cutlass.Float32, (N,), stride_order=(0,))
    fake_dst = make_fake_compact_tensor(cutlass.Float32, (N,), stride_order=(0,))

    # 2. Compile with --enable-tvm-ffi
    compiled_fn = cute.compile(
        memcpy_jit, fake_src, fake_dst, num_threads=128, options="--enable-tvm-ffi"
    )

    # 3. Create real torch tensors and execute
    src = torch.randn(N, device="cuda", dtype=torch.float32)
    dst = torch.zeros_like(src)

    compiled_fn(src, dst, num_threads=128)
    torch.cuda.synchronize()

    torch.testing.assert_close(dst, src)
    print("PASS")
