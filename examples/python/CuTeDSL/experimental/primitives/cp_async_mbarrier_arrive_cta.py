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
cp.async.mbarrier.arrive, CTA: warp-specialized cp_async_shared_global completion.

One producer warp issues ``cp_async_shared_global`` loads into shared memory,
then calls ``cp_async_mbarrier_arrive(noinc=True)`` from each participating
lane.  A separate consumer warp waits the mbarrier before reading shared
memory.  The mbarrier is initialized with one arrival per producer lane, and
each async arrive is delivered only after that lane's prior
``cp_async_shared_global`` copy retires.

This mbarrier completion path replaces the ordinary
``cp_async_commit_group`` / ``cp_async_wait_group`` path: the consumer waits on
``mbarrier_try_wait_parity_timelimit`` instead of waiting on cp.async groups.

Use this pattern when per-thread cp.async feeds a different warp or later
pipeline stage through an mbarrier, which is the typical async mbarrier style.

To run::

    python CuTeDSL/experimental/primitives/cp_async_mbarrier_arrive_cta.py

"""

import argparse
from functools import lru_cache
from typing import Callable

import torch

import cutlass
import cutlass.cute as cute
from cutlass.cute.runtime import make_fake_compact_tensor
from cutlass.experimental import primitives as prims


_LANES_PER_WARP: int = 32
_BLOCK: int = 2 * _LANES_PER_WARP
_PRODUCER_WARP: int = 0
_CONSUMER_WARP: int = 1
_VEC_BYTES: int = 16
_ELEMS_PER_THREAD: int = _VEC_BYTES // 4
_DEFAULT_N: int = _LANES_PER_WARP * _ELEMS_PER_THREAD


@cute.kernel
def kernel(src: cute.Tensor, dst: cute.Tensor):
    """Copy one thread-block tile through a producer/consumer warp mbarrier handoff."""
    tidx, _, _ = cute.arch.thread_idx()
    lane = tidx % _LANES_PER_WARP
    warp_idx = cute.arch.warp_idx()

    smem = cutlass.Array(
        cutlass.Float32, _DEFAULT_N, space=cutlass.AddressSpace.smem, alignment=128
    )
    mbar = cutlass.Array(cutlass.Int64, 1, space=cutlass.AddressSpace.smem, alignment=8)

    # With noinc=True below, each producer lane contributes one pending-count
    # decrement when its prior cp.async completes.  The initial count must
    # therefore match the number of participating producer lanes exactly.
    if tidx == 0:
        prims.mbarrier_init(mbar, _LANES_PER_WARP)
    prims.fence_mbarrier_init()
    prims.barrier_cta_sync(0)

    offset = lane * _ELEMS_PER_THREAD

    if warp_idx == _PRODUCER_WARP:
        # "cg" bypasses L1 and is valid for 16-byte cp.async copies.
        prims.cp_async_shared_global(
            smem.data_ptr() + offset,
            src.iterator.raw_ptr() + offset,
            _VEC_BYTES,
            "cg",
        )
        # No commit_group/wait_group here: this arrive ties this lane's prior
        # cp.async copy to mbar, and the consumer waits on that mbarrier.
        prims.cp_async_mbarrier_arrive(mbar, noinc=True)

    if warp_idx == _CONSUMER_WARP:
        # phase=0 waits for the first completion of a freshly initialized
        # mbarrier.  The wait has acquire ordering, so the cp.async writes are
        # visible before the consumer reads shared memory.
        while not prims.mbarrier_try_wait_parity(mbar, 0, time_limit=10_000_000):
            pass

        values = (smem.data_ptr() + offset).load(count=_ELEMS_PER_THREAD)
        (dst.iterator.raw_ptr() + offset).store(values)


@cute.jit
def host(src: cute.Tensor, dst: cute.Tensor):
    kernel(src, dst).launch(grid=(1, 1, 1), block=(_BLOCK, 1, 1))


@lru_cache(maxsize=None)
def compile() -> Callable:  # noqa: A001
    fake_src = make_fake_compact_tensor(cutlass.Float32, (_DEFAULT_N,))
    fake_dst = make_fake_compact_tensor(cutlass.Float32, (_DEFAULT_N,))
    return cute.compile(host, fake_src, fake_dst, options="--enable-tvm-ffi")


def run(compiled_fn: Callable) -> tuple[torch.Tensor, torch.Tensor]:
    if not torch.cuda.is_available():
        raise RuntimeError("CUDA GPU required")
    src = torch.arange(_DEFAULT_N, dtype=torch.float32, device="cuda")
    dst = torch.zeros_like(src)
    compiled_fn(src, dst)
    torch.cuda.synchronize()
    return dst, src


def verify() -> None:
    compiled_fn = compile()
    print("Compile cp_async_mbarrier_arrive_cta OK", flush=True)

    dst, src = run(compiled_fn)
    print("Run cp_async_mbarrier_arrive_cta OK", flush=True)

    torch.testing.assert_close(dst, src)
    print(f"verify: PASS  dst[:8] = {dst[:8].tolist()}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="CTA-local cp.async.mbarrier.arrive completion demo",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.parse_args()
    verify()
