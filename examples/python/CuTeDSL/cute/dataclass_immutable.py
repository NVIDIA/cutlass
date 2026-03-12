# Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

"""
Dataclass Example: Passing Tensors via Frozen Dataclass
=======================================================

Demonstrates passing tensors from `@cute.jit` to `@cute.kernel`
using `@dataclass(frozen=True)`.

Uses fake tensors for compilation and TVM-FFI for efficient runtime dispatch.

To run:

.. code-block:: bash

    python examples/python/CuTeDSL/cute/dataclass_immutable.py

"""

from dataclasses import dataclass

import cutlass
import cutlass.cute as cute
from cutlass import Int32


@dataclass(frozen=True)
class CopyParams:
    """
    Dataclass with one static attribute and two tensors.

    Attributes:
        num_threads: Threads per block (static - used for loop unrolling)
        src: Source tensor (dynamic)
        dst: Destination tensor (dynamic)
    """

    num_threads: int  # static
    src: cute.Tensor  # dynamic
    dst: cute.Tensor  # dynamic


@cute.jit
def memcpy_jit(mSrc: cute.Tensor, mDst: cute.Tensor, num_threads: cutlass.Constexpr[int]):
    """Host function - passes tensors via dataclass."""
    params = CopyParams(
        num_threads=num_threads,
        src=mSrc,
        dst=mDst,
    )

    N = mSrc.shape[0]
    num_blocks = cute.ceil_div(N, num_threads)

    memcpy_kernel(params, N).launch(
        grid=[num_blocks, 1, 1],
        block=[num_threads, 1, 1],
    )


@cute.kernel
def memcpy_kernel(params: CopyParams, N: Int32):
    """Device kernel - receives tensors via CopyParams dataclass."""
    tidx, _, _ = cute.arch.thread_idx()
    bidx, _, _ = cute.arch.block_idx()

    idx = bidx * params.num_threads + tidx

    if idx < N:
        params.dst[idx] = params.src[idx]


if __name__ == "__main__":
    import torch
    from cutlass.cute.runtime import make_fake_compact_tensor

    n = cute.sym_int64()
    # 1. Create fake tensors for compilation (no GPU memory allocated)
    fake_src = make_fake_compact_tensor(cutlass.Float32, (n,), stride_order=(0,))
    fake_dst = make_fake_compact_tensor(cutlass.Float32, (n,), stride_order=(0,))

    # 2. Compile with --enable-tvm-ffi
    compiled_fn = cute.compile(
        memcpy_jit, fake_src, fake_dst, num_threads=128, options="--enable-tvm-ffi"
    )

    # 3. Create real torch tensors
    src = torch.randn(1024, device="cuda", dtype=torch.float32)
    dst = torch.zeros_like(src)

    # 4. Run compiled kernel
    compiled_fn(src, dst)

    # 5. Verify dst == src
    torch.cuda.synchronize()
    torch.testing.assert_close(dst, src)
    print("PASS")
