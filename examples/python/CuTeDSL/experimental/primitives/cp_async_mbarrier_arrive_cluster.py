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
cp.async.mbarrier.arrive, cluster: warp-specialized local completion fan-in.

``cp_async_mbarrier_arrive`` is local to one thread block (PTX CTA).  In this
warp-specialized cluster pattern, a producer warp in each block issues
``cp_async_shared_global`` and arrives on a local mbarrier.  A separate
completion-forwarder warp waits that local mbarrier, then one elected lane
arrives on block 0's leader barrier with the ``shared::cluster`` pointer
returned by ``mapa``.  A separate consumer warp waits the leader barrier,
consumes the staged shared-memory tile, and releases empty barriers back to
both blocks.  This minimal example uses a two-block cluster, so the leader
barrier count is two forwarded completions.

Use this pattern when per-block ``cp_async_shared_global`` loads must fan in
to a leader block's barrier before a later cluster-level consumer.  The file
does not issue MMA; it reads peer shared memory directly to verify the
synchronization pattern.

To run::

    python CuTeDSL/experimental/primitives/cp_async_mbarrier_arrive_cluster.py

"""

import argparse
from functools import lru_cache
from typing import Callable

import torch

import cutlass
import cutlass.cute as cute
from cutlass.cute.runtime import make_fake_compact_tensor
from cutlass.experimental import primitives as prims


_CLUSTER_SIZE: int = 2
_BLOCK: int = 96
_PRODUCER_WARP: int = 0
_FORWARDER_WARP: int = 1
_CONSUMER_WARP: int = 2
_VEC_BYTES: int = 16
_ELEMS_PER_THREAD: int = _VEC_BYTES // 4
_TILE_ELEMS_PER_CTA: int = 32 * _ELEMS_PER_THREAD
_OUT_ELEMS_PER_CTA: int = 4
_OUT_ELEMS: int = _CLUSTER_SIZE * _OUT_ELEMS_PER_CTA


@cute.kernel
def kernel(src: cute.Tensor, dst_arr: cutlass.Array):
    """Warp-specialized cluster producer, forwarder, and consumer mbarrier handoff."""
    tidx, _, _ = cute.arch.thread_idx()
    lane = tidx % 32
    warp_idx = cute.arch.warp_idx()
    cta_rank = cute.arch.block_idx_in_cluster()

    smem = cutlass.Array(
        cutlass.Float32,
        _TILE_ELEMS_PER_CTA,
        space=cutlass.AddressSpace.smem,
        alignment=128,
    )
    local_mbar = cutlass.Array(
        cutlass.Int64, 1, space=cutlass.AddressSpace.smem, alignment=8
    )
    leader_mbar = cutlass.Array(
        cutlass.Int64, 1, space=cutlass.AddressSpace.smem, alignment=8
    )
    empty_mbar = cutlass.Array(
        cutlass.Int64, 1, space=cutlass.AddressSpace.smem, alignment=8
    )

    if tidx == 0:
        prims.mbarrier_init(local_mbar, 32)
        prims.mbarrier_init(empty_mbar, 1)
        if cta_rank == 0:
            prims.mbarrier_init(leader_mbar, _CLUSTER_SIZE)

    prims.fence_mbarrier_init()
    prims.barrier_cluster_arrive_relaxed()
    prims.barrier_cluster_wait()

    if warp_idx == _PRODUCER_WARP:
        cta_base = cta_rank * _TILE_ELEMS_PER_CTA
        offset = lane * _ELEMS_PER_THREAD
        prims.cp_async_shared_global(
            smem.data_ptr() + offset,
            src.iterator.raw_ptr() + cta_base + offset,
            _VEC_BYTES,
            "cg",
        )
        prims.cp_async_mbarrier_arrive(local_mbar, noinc=True)

    if warp_idx == _FORWARDER_WARP:
        while not prims.mbarrier_try_wait_parity(local_mbar, 0, time_limit=10_000_000):
            pass

        if prims.elect_sync():
            leader_ptr = prims.mapa(leader_mbar, 0)
            prims.mbarrier_arrive(leader_ptr, scope=prims.MemScope.CLUSTER)

    if warp_idx == _CONSUMER_WARP:
        if cta_rank == 0:
            while not prims.mbarrier_try_wait_parity(
                leader_mbar, 0, time_limit=10_000_000
            ):
                pass

            # Real kernels use this leader-side wait to gate a cluster-level
            # consumer, such as tcgen05 MMA over both CTAs' shared-memory tiles.
            # This minimal example reads peer shared memory directly so the forwarder
            # protocol stays isolated and its result is easy to verify.
            if lane < _OUT_ELEMS_PER_CTA:
                peer_smem = prims.mapa(smem.data_ptr(), 1)
                dst_arr[lane] = smem[lane]
                dst_arr[_OUT_ELEMS_PER_CTA + lane] = peer_smem[lane]

            # Real consumers may have all lanes reading shared memory. Keep
            # those reads ordered before the elected lane releases the empty
            # barriers.
            prims.bar_warp_sync(cute.arch.FULL_MASK)

            if prims.elect_sync():
                prims.mbarrier_arrive(empty_mbar)
                peer_empty_mbar = prims.mapa(empty_mbar, 1)
                prims.mbarrier_arrive(peer_empty_mbar, scope=prims.MemScope.CLUSTER)

        while not prims.mbarrier_try_wait_parity(empty_mbar, 0, time_limit=10_000_000):
            pass


@cute.jit
def host(src: cute.Tensor, dst: cutlass.Array):
    kernel(src, dst).launch(
        grid=(_CLUSTER_SIZE, 1, 1),
        block=(_BLOCK, 1, 1),
        cluster=(_CLUSTER_SIZE, 1, 1),
    )


@lru_cache(maxsize=None)
def compile() -> Callable:  # noqa: A001
    fake_src = make_fake_compact_tensor(
        cutlass.Float32,
        (_CLUSTER_SIZE * _TILE_ELEMS_PER_CTA,),
    )
    fake_dst = make_fake_compact_tensor(cutlass.Float32, (_OUT_ELEMS,))
    return cute.compile(host, fake_src, fake_dst, options="--enable-tvm-ffi")


def run(compiled_fn: Callable) -> tuple[torch.Tensor, torch.Tensor]:
    if not torch.cuda.is_available():
        raise RuntimeError("CUDA GPU required")
    src = torch.arange(
        _CLUSTER_SIZE * _TILE_ELEMS_PER_CTA,
        dtype=torch.float32,
        device="cuda",
    )
    dst = torch.full((_OUT_ELEMS,), -1, dtype=torch.float32, device="cuda")
    compiled_fn(src, dst)
    torch.cuda.synchronize()
    return dst, src


def verify() -> None:
    compiled_fn = compile()
    print("Compile cp_async_mbarrier_arrive_cluster OK", flush=True)

    dst, src = run(compiled_fn)
    print("Run cp_async_mbarrier_arrive_cluster OK", flush=True)

    expected = torch.cat(
        [
            src[:_OUT_ELEMS_PER_CTA],
            src[_TILE_ELEMS_PER_CTA : _TILE_ELEMS_PER_CTA + _OUT_ELEMS_PER_CTA],
        ]
    )
    torch.testing.assert_close(dst, expected)
    print(f"verify: PASS  dst = {dst.tolist()}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Cluster cp.async.mbarrier.arrive completion fan-in demo",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.parse_args()
    verify()
