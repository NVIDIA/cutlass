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
barrier.cta.sync / barrier.cta.arrive — thread-block rendezvous at a named barrier.

Demonstrates:

  - :func:`~cutlass.primitives.barrier_cta_sync` (slot-0, no ``thread_count``) for the
    "all threads in a block" rendezvous (equivalent to ``__syncthreads()``).
  - :func:`~cutlass.primitives.barrier_cta_arrive` + :func:`~cutlass.primitives.barrier_cta_sync`
    on the same named slot for a split-phase producer/consumer hand-off
    between two warps.
  - Non-aligned forms (the unsuffixed wrappers) are safe under divergent
    control flow; the ``_aligned`` siblings exist for the all-thread-block
    (PTX CTA) converged fast path.

To run::

    python CuTeDSL/experimental/primitives/barrier_cta_sync.py
    python CuTeDSL/experimental/primitives/barrier_cta_sync.py --warps 4

"""

import cutlass
import argparse
from functools import lru_cache
from typing import Callable

import torch
import cuda.bindings.driver as cuda

import cutlass.cute as cute
from cutlass.cute.runtime import make_fake_compact_tensor, make_fake_stream
from cutlass.experimental import primitives as prims


_DEFAULT_WARPS: int = 2
_WARP_SIZE: int = 32
_OUT_ELEMS: int = 3
_PRODUCER_WARP: int = 0
_CONSUMER_WARP: int = 1


@cute.kernel
def kernel(
    out_arr: cutlass.Array,  # [_OUT_ELEMS] Int32
    WARPS: cutlass.Constexpr,
):
    """Run slot-0 all-block sync + slot-1 producer/consumer arrive/sync.

    Layout:
      - Warp 0 acts as producer: writes a value to shared memory, then
        ``arrive`` s on
        slot 1 with ``thread_count = 2 * 32`` (producer + consumer warps).
      - Warp 1 acts as consumer: waits on slot 1, then reads producer's
        value and stamps ``out[1]``.
      - All warps participate in a slot-0 all-block sync afterwards.

    The kernel verifies that the producer/consumer hand-off carries the
    expected value and that the slot-0 sync orders writes from all warps.
    """
    tidx, _, _ = cute.arch.thread_idx()
    warp_idx = tidx // _WARP_SIZE
    lane_idx = tidx % _WARP_SIZE

    # Shared-memory scratch for the producer/consumer hand-off.
    smem = cutlass.Array(cutlass.Int32, 1, space=cutlass.AddressSpace.smem, alignment=4)

    # ---------------------------------------------------------------
    # Slot-1 producer/consumer split-phase barrier (subset of warps).
    # ---------------------------------------------------------------
    if warp_idx == _PRODUCER_WARP:
        if lane_idx == 0:
            smem[0] = cutlass.Int32(0xC0DE)
        # Non-blocking signal — producer continues running after this.
        prims.barrier_cta_arrive(barrier_id=1, thread_count=2 * _WARP_SIZE)
    elif warp_idx == _CONSUMER_WARP:
        # Wait for producer to arrive.
        prims.barrier_cta_sync(barrier_id=1, thread_count=2 * _WARP_SIZE)
        # Now safe to read producer's shared-memory value.
        if lane_idx == 0:
            out_arr[1] = smem[0]

    # ---------------------------------------------------------------
    # Slot-0 all-block rendezvous — exercises the no-thread-count form.
    # Every thread in the block reaches this barrier so the aligned variant is
    # safe and slightly cheaper.  When in doubt, use the unsuffixed
    # `barrier_cta_sync` (the non-aligned form).
    # ---------------------------------------------------------------
    prims.barrier_cta_sync_aligned(barrier_id=0)

    # Stamp thread 0's view of completion.
    if tidx == 0:
        out_arr[0] = cutlass.Int32(1)
        # out_arr[2] is the "all warps passed the slot-0 sync" marker —
        # if we got here, every warp made it past slot-0.
        out_arr[2] = cutlass.Int32(WARPS)


@cute.jit
def host(out: cutlass.Array, stream, WARPS: cutlass.Constexpr):
    """Launch one thread block with ``WARPS * 32`` threads."""
    kernel(out, WARPS).launch(
        grid=(1, 1, 1),
        block=(WARPS * _WARP_SIZE, 1, 1),
        stream=stream,
    )


@lru_cache(maxsize=None)
def compile(WARPS: int = _DEFAULT_WARPS) -> Callable:
    """AOT-compile the thread-block rendezvous example."""
    # The example hard-codes warp 0 as producer and warp 1 as consumer, so
    # specializations with fewer than 2 warps cannot satisfy the slot-1
    # producer/consumer contract.  Reject them up front so direct
    # ``compile(WARPS=0)`` calls don't sneak past the CLI's choices=(2,4,8).
    if WARPS < 2:
        raise ValueError(
            f"WARPS must be >= 2 (got {WARPS}); the example uses warp 0 as "
            "producer and warp 1 as consumer."
        )
    fake_out = make_fake_compact_tensor(cutlass.Int32, (_OUT_ELEMS,), assumed_align=4)
    return cute.compile(
        host,
        fake_out,
        make_fake_stream(),
        WARPS,
        options="--enable-tvm-ffi",
    )


def run(compiled_fn: Callable) -> torch.Tensor:
    """Allocate output, run the compiled kernel, return the result."""
    if not torch.cuda.is_available():
        raise RuntimeError("CUDA GPU required")
    out = torch.zeros(_OUT_ELEMS, dtype=torch.int32, device="cuda")
    stream = cuda.CUstream(torch.cuda.current_stream().cuda_stream)
    compiled_fn(out, stream)
    torch.cuda.synchronize()
    return out


def verify(compiled_fn: Callable | None = None, WARPS: int = _DEFAULT_WARPS) -> None:
    """Run a compiled kernel and check the producer/consumer hand-off.

    The expected-value check covers ``out[0]`` (slot-0 sync completion
    marker) and ``out[1]`` (producer/consumer hand-off magic value).
    ``out[2]`` echoes the compile-time WARPS into the device side; the
    helper does not check it because the WARPS specialization baked
    into ``compiled_fn`` is not exposed by the AOT-compiled callable,
    so a caller passing a precompiled kernel cannot reliably tell
    ``verify`` which WARPS the kernel was built with.
    """
    if compiled_fn is None:
        compiled_fn = compile(WARPS=WARPS)
        print(f"Compile kernel (WARPS={WARPS}) OK", flush=True)
    out = run(compiled_fn)
    print("Run kernel OK", flush=True)

    # Checks that don't depend on the compile-time WARPS specialization.
    assert int(out[0]) == 1, f"slot-0 sync marker: expected 1, got {int(out[0])}"
    assert int(out[1]) == 0xC0DE, (
        f"producer/consumer hand-off: expected 0xC0DE, got {hex(int(out[1]))}"
    )
    print(f"verify: PASS  (out={out.tolist()})")


def main() -> None:
    """CLI entry point."""
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--warps",
        type=int,
        default=_DEFAULT_WARPS,
        choices=(2, 4, 8),
        help="Thread-block warp count (must be >= 2; producer/consumer pair uses warps 0 and 1)",
    )
    args = parser.parse_args()
    verify(WARPS=args.warps)


if __name__ == "__main__":
    main()
