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
bar.warp.sync — Warp-lane rendezvous barrier.

Demonstrates:

  - :func:`~cutlass.primitives.bar_warp_sync` with ``cute.arch.FULL_MASK`` — all 32 lanes
    rendezvous before a shared-memory read-after-write.
  - :func:`~cutlass.primitives.bar_warp_sync` with a partial mask ``0x0000FFFF`` —
    only lanes 0–15 participate; lanes 16–31 never call it and are not
    listed in the mask.

Two kernels, each with a dedicated ``compile_*()``, ``run_()``, and
``verify_*()`` following the canonical CUTLASS DSL kernel template.

To run::

    python CuTeDSL/experimental/primitives/bar_warp_sync.py               # both kernels
    python CuTeDSL/experimental/primitives/bar_warp_sync.py --kernel 1    # full-mask shared-memory sync
    python CuTeDSL/experimental/primitives/bar_warp_sync.py --kernel 2    # partial-mask subset

"""

import argparse
from functools import lru_cache
from typing import Callable

import torch
import cuda.bindings.driver as cuda

import cutlass
import cutlass.cute as cute
from cutlass.cute.runtime import make_fake_compact_tensor, make_fake_stream
from cutlass.experimental import primitives as prims


# ---------------------------------------------------------------------------
# Shared constants
# ---------------------------------------------------------------------------

_WARP_SIZE: int = 32  # threads per block for both kernels
_FULL_MASK: int = 0xFFFFFFFF


# =============================================================================
# Kernel 1 — Full-mask shared-memory read-after-write
#
# One elected thread (lane 0) writes a sentinel value into shared memory.
# All 32 lanes then call bar_warp_sync(FULL_MASK) to guarantee visibility
# before every lane reads back the sentinel.
# =============================================================================


@cute.kernel
def full_mask_kernel(
    dst_arr: cutlass.Array,  # [WARP_SIZE]  Int32 — each lane writes its read-back
    sentinel: cutlass.Int32,  # value written by lane 0 into shared memory
    WARP_SIZE_C: cutlass.Constexpr,
):
    """Write a sentinel into shared memory, sync all 32 lanes, then read it back.

    Lane 0 writes *sentinel* to ``smem[0]``.  All lanes synchronize via
    ``bar.warp.sync`` before reading; every lane stores the read value into
    ``dst_arr[lane]``.

    :param dst_arr: Per-lane output — each element should equal *sentinel*.
    :type dst_arr: cutlass.Array
    :param sentinel: Value written by lane 0.
    :type sentinel: cutlass.Int32
    :param WARP_SIZE_C: Compile-time warp size.
    :type WARP_SIZE_C: cutlass.Constexpr
    """
    tidx, _, _ = cute.arch.thread_idx()

    # Allocate a one-element shared-memory slot.
    smem = cutlass.Array(cutlass.Int32, (1,), space=cutlass.AddressSpace.smem)

    # Lane 0 writes the sentinel; other lanes skip.
    if tidx == 0:
        smem[0] = sentinel

    # ------------------------------------------------------------------
    # bar.warp.sync — all 32 lanes rendezvous here before the read.
    # Without this barrier, lanes > 0 may read smem[0] before lane 0
    # has written it (data race).
    # mask = FULL_MASK: all 32 lanes are named and all must arrive.
    # ------------------------------------------------------------------
    prims.bar_warp_sync(cute.arch.FULL_MASK)

    # All lanes read the value written by lane 0.
    dst_arr[tidx] = smem[0]


@cute.jit
def full_mask_host(
    dst: cutlass.Array,
    stream,
    sentinel: cutlass.Int32,
    WARP_SIZE_C: cutlass.Constexpr,
):
    """Launch :func:`full_mask_kernel` over one warp."""
    full_mask_kernel(dst, sentinel, WARP_SIZE_C).launch(
        grid=(1, 1, 1), block=(_WARP_SIZE, 1, 1), stream=stream
    )


@lru_cache(maxsize=None)
def compile_full_mask(WARP_SIZE_C: int = _WARP_SIZE) -> Callable:
    """AOT-compile the full-mask barrier kernel.

    :param WARP_SIZE_C: Warp size baked at compile time (default 32).
    :type WARP_SIZE_C: int
    :return: Compiled callable; runtime signature ``(dst, stream, sentinel)``.
    :rtype: Callable
    """
    fake_dst = make_fake_compact_tensor(cutlass.Int32, (WARP_SIZE_C,), assumed_align=4)
    return cute.compile(
        full_mask_host,
        fake_dst,
        make_fake_stream(),
        0,  # sentinel — symbolic runtime arg
        WARP_SIZE_C,  # WARP_SIZE_C — baked as Constexpr
        options="--enable-tvm-ffi",
    )


def run_full_mask(
    fn: Callable,
    sentinel: int = 42,
) -> torch.Tensor:
    """Allocate tensor, call ``fn``, and return ``dst``.

    :param fn: Compiled callable from :func:`compile_full_mask`.
    :type fn: Callable
    :param sentinel: Value written by lane 0 into shared memory.
    :type sentinel: int
    :return: Output tensor — all 32 elements should equal *sentinel*.
    :rtype: torch.Tensor
    """
    dst = torch.zeros(_WARP_SIZE, dtype=torch.int32, device="cuda")
    stream = cuda.CUstream(torch.cuda.current_stream().cuda_stream)
    fn(dst, stream, sentinel)
    torch.cuda.synchronize()
    return dst


def verify_full_mask() -> None:
    """Compile, run (two sentinel values), and assert every lane read correctly.

    Demonstrates runtime parameterisation: the same compiled binary handles
    ``sentinel=42`` and ``sentinel=99`` without recompilation.

    :raises AssertionError: If any lane received the wrong value.
    """
    fn = compile_full_mask()
    print("Compile kernel (full_mask) OK", flush=True)

    for sentinel in (42, 99):
        dst = run_full_mask(fn, sentinel=sentinel)
        print(f"Run kernel (full_mask, sentinel={sentinel}) OK", flush=True)
        expected = torch.full((_WARP_SIZE,), sentinel, dtype=torch.int32, device="cuda")
        torch.testing.assert_close(dst, expected, atol=0, rtol=0)
        print(
            f"verify (full_mask, sentinel={sentinel}, "
            f"all lanes got {dst[0].item()}): PASS"
        )


# =============================================================================
# Kernel 2 — Partial mask: only lanes 0–15 synchronize
#
# The thread block launches 32 threads but the kernel logically divides them
# into two independent groups (lanes 0–15 and lanes 16–31). Each group writes to its
# own shared-memory slot, then uses a partial-mask bar_warp_sync that names
# only that group.  This demonstrates that partial-mask barriers are safe as
# long as the named lanes all execute the instruction in a non-divergent region.
# =============================================================================

_LOW_MASK: int = 0x0000FFFF  # lanes 0–15
_HIGH_MASK: int = 0xFFFF0000  # lanes 16–31


@cute.kernel
def partial_mask_kernel(
    dst_arr: cutlass.Array,  # [WARP_SIZE]  Int32
    low_val: cutlass.Int32,  # sentinel written by lane 0  into smem[0]
    high_val: cutlass.Int32,  # sentinel written by lane 16 into smem[1]
    WARP_SIZE_C: cutlass.Constexpr,
):
    """Split the warp into two groups and sync each with a partial mask.

    Lanes 0–15 form the "low" group (mask ``0x0000FFFF``); lanes 16–31 form
    the "high" group (mask ``0xFFFF0000``).  Each group writes a different
    sentinel to shared memory, rendezvouses among themselves, then reads it back.

    :param dst_arr: Per-lane output — lanes 0–15 get *low_val*; lanes 16–31 get
        *high_val*.
    :type dst_arr: cutlass.Array
    :param low_val: Value written by lane 0 (low group sentinel).
    :type low_val: cutlass.Int32
    :param high_val: Value written by lane 16 (high group sentinel).
    :type high_val: cutlass.Int32
    :param WARP_SIZE_C: Compile-time warp size.
    :type WARP_SIZE_C: cutlass.Constexpr
    """
    tidx, _, _ = cute.arch.thread_idx()

    # Shared memory: slot 0 for the low group, slot 1 for the high group.
    smem = cutlass.Array(cutlass.Int32, (2,), space=cutlass.AddressSpace.smem)

    # Low group write (lane 0 only)
    if tidx == 0:
        smem[0] = low_val

    # High group write (lane 16 only)
    if tidx == 16:
        smem[1] = high_val

    # ------------------------------------------------------------------
    # bar.warp.sync with partial masks.
    # The two groups synchronize independently and in parallel.
    # - mask=0x0000FFFF names lanes 0–15; these 16 lanes rendezvous here.
    # - mask=0xFFFF0000 names lanes 16–31; these 16 lanes rendezvous here.
    # Lanes not in a given mask do NOT participate and are not stalled.
    # Both calls happen on all 32 lanes but with different masks, so each
    # lane participates in exactly one rendezvous.
    # ------------------------------------------------------------------
    if tidx < 16:
        prims.bar_warp_sync(_LOW_MASK)
    else:
        prims.bar_warp_sync(_HIGH_MASK)

    # Read back from the slot that matches this lane's group.
    if tidx < 16:
        dst_arr[tidx] = smem[0]
    else:
        dst_arr[tidx] = smem[1]


@cute.jit
def partial_mask_host(
    dst: cutlass.Array,
    stream,
    low_val: cutlass.Int32,
    high_val: cutlass.Int32,
    WARP_SIZE_C: cutlass.Constexpr,
):
    """Launch :func:`partial_mask_kernel` over one warp."""
    partial_mask_kernel(dst, low_val, high_val, WARP_SIZE_C).launch(
        grid=(1, 1, 1), block=(_WARP_SIZE, 1, 1), stream=stream
    )


@lru_cache(maxsize=None)
def compile_partial_mask(WARP_SIZE_C: int = _WARP_SIZE) -> Callable:
    """AOT-compile the partial-mask barrier kernel.

    :param WARP_SIZE_C: Warp size baked at compile time (default 32).
    :type WARP_SIZE_C: int
    :return: Compiled callable; runtime signature
        ``(dst, stream, low_val, high_val)``.
    :rtype: Callable
    """
    fake_dst = make_fake_compact_tensor(cutlass.Int32, (WARP_SIZE_C,), assumed_align=4)
    return cute.compile(
        partial_mask_host,
        fake_dst,
        make_fake_stream(),
        0,  # low_val  — symbolic runtime arg
        0,  # high_val — symbolic runtime arg
        WARP_SIZE_C,  # WARP_SIZE_C — baked as Constexpr
        options="--enable-tvm-ffi",
    )


def run_partial_mask(
    fn: Callable,
    low_val: int = 10,
    high_val: int = 20,
) -> torch.Tensor:
    """Allocate tensor, call ``fn``, and return ``dst``.

    :param fn: Compiled callable from :func:`compile_partial_mask`.
    :type fn: Callable
    :param low_val: Sentinel for lanes 0–15.
    :type low_val: int
    :param high_val: Sentinel for lanes 16–31.
    :type high_val: int
    :return: Output tensor — first 16 elements equal *low_val*; last 16 equal
        *high_val*.
    :rtype: torch.Tensor
    """
    dst = torch.zeros(_WARP_SIZE, dtype=torch.int32, device="cuda")
    stream = cuda.CUstream(torch.cuda.current_stream().cuda_stream)
    fn(dst, stream, low_val, high_val)
    torch.cuda.synchronize()
    return dst


def verify_partial_mask() -> None:
    """Compile, run (two value-pair variants), and assert per-group correctness.

    :raises AssertionError: If any lane received the wrong sentinel value.
    """
    fn = compile_partial_mask()
    print("Compile kernel (partial_mask) OK", flush=True)

    for low_val, high_val in ((10, 20), (100, 200)):
        dst = run_partial_mask(fn, low_val=low_val, high_val=high_val)
        print(
            f"Run kernel (partial_mask, low_val={low_val}, high_val={high_val}) OK",
            flush=True,
        )
        expected = torch.cat(
            [
                torch.full((16,), low_val, dtype=torch.int32),
                torch.full((16,), high_val, dtype=torch.int32),
            ]
        ).to("cuda")
        torch.testing.assert_close(dst, expected, atol=0, rtol=0)
        print(
            f"verify (partial_mask, lane0={dst[0].item()}, "
            f"lane16={dst[16].item()}): PASS"
        )


# =============================================================================
# Top-level verify
# =============================================================================


def verify(kernel: str = "all") -> None:
    """Run the selected kernel verification(s).

    :param kernel: ``"1"`` for full-mask, ``"2"`` for partial-mask,
        ``"all"`` for both.
    :type kernel: str
    :raises ValueError: If ``kernel`` is not in ``{"1", "2", "all"}``.
    :raises RuntimeError: If CUDA is unavailable.
    """
    if not torch.cuda.is_available():
        raise RuntimeError("CUDA device required")

    run_map = {
        "1": verify_full_mask,
        "2": verify_partial_mask,
    }
    if kernel not in run_map and kernel != "all":
        raise ValueError(
            f"kernel must be one of {list(run_map) + ['all']}, got {kernel!r}"
        )

    for k, fn in run_map.items():
        if kernel != "all" and k != kernel:
            continue
        fn()


# =============================================================================
# Entry point
# =============================================================================

if __name__ == "__main__":
    p = argparse.ArgumentParser(
        description="bar.warp.sync — warp-lane rendezvous barrier examples",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    p.add_argument(
        "--kernel",
        type=str,
        default="all",
        choices=["1", "2", "all"],
        help=(
            "kernel to run: "
            "1=full_mask    [FULL_MASK shared-memory read-after-write, sm_70+], "
            "2=partial_mask [0x0000FFFF / 0xFFFF0000 sub-warp groups, sm_70+], "
            "all=run both kernels"
        ),
    )
    args = p.parse_args()
    verify(args.kernel)
