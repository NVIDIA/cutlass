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
Warp-specialized async bulk copy round trip - raw cp.async.bulk variant.

Demonstrates the bidirectional ``cp.async.bulk`` forms without TMA descriptors:

  - Producer warp: one issuer lane loads TILE_ELEMS fp16 values from a raw
    global pointer to shared memory with ``cutlass.primitives.cp_async_bulk_shared_cluster_global``.
    Load completion is tracked through ``full_bar`` mbarriers.
  - Consumer warp: waits each full shared-memory stage, stores it back to a global
    destination with ``cutlass.primitives.cp_async_bulk_global_shared_cta``, drains the
    per-thread async bulk group, then signals ``empty_bar`` for stage reuse.
  - ``NUM_STAGES`` gives the producer room to run ahead while the consumer
    drains older stages; warmup and drain are implicit in the two warp loops.

PTX defines ``cp_async_bulk_commit_group`` and ``cp_async_bulk_wait_group`` over
bulk operations initiated by the executing thread, so the store side does not
need a CTA-wide wait.  This example uses dedicated producer and consumer warps
with full/empty mbarriers instead of explicit prologue and epilogue loops.

Key differences from ``tma/tma_pipeline_warpspec.py``:
  - Load uses a raw ``cutlass.Pointer`` instead of a TMA ``TensorMap`` descriptor.
  - Store side is also async (``cp.async.bulk``), drained by bulk-group
    commit/wait instead of an mbarrier completion signal.
  - No swizzle de-mapping needed: bulk copy does not apply a shared-memory swizzle.

To run::

    python CuTeDSL/experimental/primitives/cp_async_bulk.py                      # verify
    python CuTeDSL/experimental/primitives/cp_async_bulk.py --n 2097152          # custom N
    python CuTeDSL/experimental/primitives/cp_async_bulk.py --TILE_ELEMS 2048    # custom tile

"""

import argparse
from functools import lru_cache
from typing import Callable

import cuda.bindings.driver as cuda
import cutlass
import cutlass.cute as cute
from cutlass._mlir import ir
from cutlass._mlir.dialects import llvm as _llvm
from cutlass._mlir_helpers.dialect_proxy import DialectAutoConvertProxy
from cutlass.cute.runtime import make_fake_compact_tensor, make_fake_stream
import torch

from cutlass.experimental import primitives as prims

llvm = DialectAutoConvertProxy(_llvm)


def _llvm_ptr_type(addrspace: int) -> ir.Type:
    get = getattr(_llvm.PointerType, "get", None)
    if get is not None:
        return get(addrspace)
    return ir.Type.parse(f"!llvm.ptr<{addrspace}>")


# ---------------------------------------------------------------------------
# Dtype map
# ---------------------------------------------------------------------------

DTYPE_MAP: dict[type, torch.dtype] = {
    cutlass.Float16: torch.float16,
}
_DEFAULT_DTYPE: type = cutlass.Float16
_CLI_DTYPES: dict[str, type] = {"fp16": cutlass.Float16}

# ---------------------------------------------------------------------------
# Kernel configuration (fixed)
# ---------------------------------------------------------------------------

_WARP_SIZE = 32
_ISSUER_LANE = 0
_PRODUCER_WARP = 0
_CONSUMER_WARP = 1
_THREADS = 2 * _WARP_SIZE

# ---------------------------------------------------------------------------
# Kernel configuration (tunable via compile / CLI)
# ---------------------------------------------------------------------------

# TILE_ELEMS must be a multiple of 8 (fp16 × 8 = 16-byte cp.async.bulk alignment).
_DEFAULT_TILE_ELEMS: int = 1024
_DEFAULT_NUM_STAGES: int = 2
_DEFAULT_NUM_CTAS: int = 108  # adjust to target GPU SM count

# ---------------------------------------------------------------------------
# Default problem size (runtime)
# ---------------------------------------------------------------------------

_DEFAULT_N: int = _DEFAULT_TILE_ELEMS * _DEFAULT_NUM_CTAS * 8  # 8 tiles / block


# ---------------------------------------------------------------------------
# Device kernel
# ---------------------------------------------------------------------------


@cute.kernel
def kernel(
    src_g: cutlass.Array,  # [N] Float16 — global source (flat 1-D)
    dst_g: cutlass.Array,  # [N] Float16 — global destination (flat 1-D)
    n_tiles: cutlass.Int32,  # tiles this thread block handles (runtime)
    TILE_ELEMS: cutlass.Constexpr,  # elements per bulk-copy tile (compile-time)
    NUM_STAGES: cutlass.Constexpr,  # pipeline depth (compile-time)
) -> None:
    """Warp-specialized bidirectional async bulk copy round trip."""
    TILE_BYTES: cutlass.Constexpr = TILE_ELEMS * 2  # fp16: 2 bytes per element

    bidx, _, _ = cute.arch.block_idx()
    cta_base = bidx * n_tiles * TILE_ELEMS

    src_base = src_g.subview(cta_base)
    dst_base = dst_g.subview(cta_base)

    # NUM_STAGES × TILE_ELEMS fp16 shared-memory buffer; 128-byte aligned for
    # bulk copy.
    smem = cutlass.Array(
        cutlass.Float16,
        NUM_STAGES * TILE_ELEMS,
        space=cutlass.AddressSpace.smem,
        alignment=128,
    )

    # full_bar[s]: global -> SMEM completion; empty_bar[s]: stage reusable.
    full_bar = cutlass.Array(
        cutlass.Int64, NUM_STAGES, space=cutlass.AddressSpace.smem, alignment=8
    )
    empty_bar = cutlass.Array(
        cutlass.Int64, NUM_STAGES, space=cutlass.AddressSpace.smem, alignment=8
    )

    tidx, _, _ = cute.arch.thread_idx()
    warp_idx = tidx // _WARP_SIZE
    lane = tidx % _WARP_SIZE
    producer = warp_idx == _PRODUCER_WARP
    consumer = warp_idx == _CONSUMER_WARP
    issuer_lane = lane == _ISSUER_LANE

    # ------------------------------------------------------------------
    # Barrier init - one producer thread updates each stage.
    # count=1: one arrive/complete_tx per phase transition.
    # ------------------------------------------------------------------
    if producer:
        if issuer_lane:
            for s in cutlass.range_constexpr(NUM_STAGES):
                prims.mbarrier_init(full_bar.subview(s), 1)
                prims.mbarrier_init(empty_bar.subview(s), 1)
    prims.fence_mbarrier_init()
    prims.barrier_cta_sync(0)

    # ------------------------------------------------------------------
    # Prime all empty slots so the producer's first wait(empty_bar, phase=0)
    # passes. Later consumer arrives make each stage reusable.
    # ------------------------------------------------------------------
    if producer:
        if issuer_lane:
            for s in cutlass.range_constexpr(NUM_STAGES):
                prims.mbarrier_arrive(empty_bar.subview(s))
    prims.barrier_cta_sync(0)

    # ------------------------------------------------------------------
    # Producer warp: wait for an empty stage, then issue raw GMEM -> SMEM.
    # ------------------------------------------------------------------
    if producer:
        for k in range(n_tiles):
            s = k % NUM_STAGES
            parity = (k // NUM_STAGES) & 1

            while not prims.mbarrier_try_wait_parity(
                empty_bar.subview(s), parity, time_limit=10_000_000
            ):
                pass

            if issuer_lane:
                prims.mbarrier_arrive_expect_tx(full_bar.subview(s), TILE_BYTES)
                smem_dst = smem.subview(s * TILE_ELEMS)
                smem_dst_cluster = llvm.addrspacecast(
                    _llvm_ptr_type(cutlass.AddressSpace.dsmem.value),
                    smem_dst.ir_value(),
                )
                prims.cp_async_bulk_shared_cluster_global(
                    smem_dst_cluster,
                    src_base.subview(k * TILE_ELEMS),
                    full_bar.subview(s),
                    TILE_BYTES,
                )

    # ------------------------------------------------------------------
    # Consumer warp: wait for a full stage, store it, then release the slot.
    # ------------------------------------------------------------------
    if consumer:
        for k in range(n_tiles):
            s = k % NUM_STAGES
            parity = (k // NUM_STAGES) & 1

            while not prims.mbarrier_try_wait_parity(
                full_bar.subview(s), parity, time_limit=10_000_000
            ):
                pass

            if issuer_lane:
                prims.cp_async_bulk_global_shared_cta(
                    dst_base.subview(k * TILE_ELEMS),
                    smem.subview(s * TILE_ELEMS),
                    TILE_BYTES,
                )
                # cp.async.bulk commit/wait groups are per-thread; the lane
                # that issues the store also drains it before releasing SMEM.
                prims.cp_async_bulk_commit_group()
                prims.cp_async_bulk_wait_group(0)
                prims.mbarrier_arrive(empty_bar.subview(s))


# ---------------------------------------------------------------------------
# Host launcher
# ---------------------------------------------------------------------------


@cute.jit
def host(
    src: cutlass.Array,
    dst: cutlass.Array,
    stream,
    TILE_ELEMS: cutlass.Constexpr,
    NUM_STAGES: cutlass.Constexpr,
    NUM_CTAS: cutlass.Constexpr,
) -> None:
    """Compute per-block tile count and launch kernel."""
    n_tiles = src.shape[0] // (TILE_ELEMS * NUM_CTAS)
    kernel(src, dst, n_tiles, TILE_ELEMS, NUM_STAGES).launch(
        grid=(NUM_CTAS, 1, 1),
        block=(_THREADS, 1, 1),
        stream=stream,
    )


# ---------------------------------------------------------------------------
# Compile factory
# ---------------------------------------------------------------------------


@lru_cache(maxsize=None)
def compile(  # noqa: A001
    TILE_ELEMS: int = _DEFAULT_TILE_ELEMS,
    NUM_STAGES: int = _DEFAULT_NUM_STAGES,
    NUM_CTAS: int = _DEFAULT_NUM_CTAS,
    dtype: type = _DEFAULT_DTYPE,
) -> Callable:
    """AOT-compile host; cache by compile-time configuration.

    N must be divisible by ``TILE_ELEMS * NUM_CTAS`` at runtime.
    TILE_ELEMS must be a multiple of 8 (16-byte alignment for fp16).
    """
    sym_n = cute.sym_int64(divisibility=TILE_ELEMS * NUM_CTAS)
    fake_src = make_fake_compact_tensor(
        dtype, (sym_n,), stride_order=(0,), assumed_align=128
    )
    fake_dst = make_fake_compact_tensor(
        dtype, (sym_n,), stride_order=(0,), assumed_align=128
    )
    return cute.compile(
        host,
        fake_src,
        fake_dst,
        make_fake_stream(),
        TILE_ELEMS,
        NUM_STAGES,
        NUM_CTAS,
        options="--enable-tvm-ffi",
    )


# ---------------------------------------------------------------------------
# Run
# ---------------------------------------------------------------------------


def run(
    compiled_fn: Callable,
    n: int = _DEFAULT_N,
    dtype: type = _DEFAULT_DTYPE,
) -> tuple[torch.Tensor, torch.Tensor]:
    """Allocate tensors, call compiled_fn, return (dst, src)."""
    torch_dtype = DTYPE_MAP[dtype]
    src = torch.arange(n, dtype=torch_dtype, device="cuda")
    dst = torch.zeros(n, dtype=torch_dtype, device="cuda")
    stream = cuda.CUstream(torch.cuda.current_stream().cuda_stream)
    compiled_fn(src, dst, stream)
    torch.cuda.synchronize()
    return dst, src


# ---------------------------------------------------------------------------
# Verify
# ---------------------------------------------------------------------------


def verify(
    n: int = _DEFAULT_N,
    TILE_ELEMS: int = _DEFAULT_TILE_ELEMS,
    NUM_STAGES: int = _DEFAULT_NUM_STAGES,
    NUM_CTAS: int = _DEFAULT_NUM_CTAS,
    dtype: type = _DEFAULT_DTYPE,
) -> None:
    """Compile, run, and assert dst == src (elementwise copy correctness)."""
    compiled_fn = compile(
        TILE_ELEMS=TILE_ELEMS,
        NUM_STAGES=NUM_STAGES,
        NUM_CTAS=NUM_CTAS,
        dtype=dtype,
    )
    print(
        f"Compile kernel (TILE_ELEMS={TILE_ELEMS}, NUM_STAGES={NUM_STAGES},"
        f" NUM_CTAS={NUM_CTAS}, dtype={dtype}) OK",
        flush=True,
    )

    dst, src = run(compiled_fn, n=n, dtype=dtype)
    print(f"Run kernel (n={n}, dtype={dtype}) OK", flush=True)

    torch.testing.assert_close(dst, src, atol=0, rtol=0)
    print(f"verify (n={n}, TILE_ELEMS={TILE_ELEMS}, NUM_STAGES={NUM_STAGES}): PASS")


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    p = argparse.ArgumentParser(
        description="Warp-specialized cp.async.bulk round trip - verify correctness",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    p.add_argument(
        "--n",
        type=int,
        default=None,
        help="total elements  [must be divisible by TILE_ELEMS × NUM_CTAS]",
    )
    p.add_argument(
        "--TILE_ELEMS",
        type=int,
        default=_DEFAULT_TILE_ELEMS,
        help="elements per bulk-copy tile  [must be multiple of 8 for fp16]",
    )
    p.add_argument("--NUM_STAGES", type=int, default=_DEFAULT_NUM_STAGES)
    p.add_argument(
        "--NUM_CTAS",
        type=int,
        default=_DEFAULT_NUM_CTAS,
        help="Thread-block count  [should match target GPU SM count]",
    )
    p.add_argument(
        "--dtype",
        type=str,
        default=None,
        choices=list(_CLI_DTYPES.keys()),
    )
    args = p.parse_args()

    dtypes = [_CLI_DTYPES[args.dtype]] if args.dtype else list(DTYPE_MAP.keys())

    for dt in dtypes:
        n = args.n if args.n is not None else args.TILE_ELEMS * args.NUM_CTAS * 8
        verify(
            n=n,
            TILE_ELEMS=args.TILE_ELEMS,
            NUM_STAGES=args.NUM_STAGES,
            NUM_CTAS=args.NUM_CTAS,
            dtype=dt,
        )
