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
Cluster-level reduction of TMEM accumulator tiles.

Each CTA in a cluster owns a private TMEM tile that stands in for an MMA
accumulator result. The example stages deterministic ``Float32`` tile values
through CTA shared memory, copies them to TMEM with ``tcgen05_cp`` (UTCCP),
drains TMEM with a compile-time ``TMEM_LAYOUT`` variant, then publishes the
drained tile in shared memory. CTA 0 maps peer CTA shared-memory tiles with
``prims.mapa`` and reduces corresponding tile elements across the cluster into
one output tile.

The output tile follows the fragment order produced by the selected TMEM load
layout, not a row-major identity view of the original SMEM seed. That keeps the
layout differences visible while still validating the same tile-level cluster
reduction for every variant.

TMEM itself is private to the owning CTA, so the cross-CTA boundary is the
shared-memory tile after the TMEM drain. That mirrors an MMA epilogue that
drains ``tcgen05.mma`` accumulators from TMEM before any DSMEM exchange.
The initialization block is deliberately compact: values first live in SMEM,
then one elected thread issues a UTCCP SMEM-to-TMEM copy. A real MMA can replace
that block and keep the same TMEM-drain plus cluster-reduction tail.

This is the same handoff used by split-K style GEMM algorithms. Each CTA can
compute a partial GEMM output tile for a different K partition, keep that
partial accumulator tile in TMEM, drain it to shared memory, and then reduce
the peer CTA tiles through distributed shared memory into one final output
tile. The example uses synthetic ``Float32`` values instead of MMA so the code
focuses on the reusable epilogue pattern: TMEM accumulator tile -> SMEM tile
-> DSMEM cluster reduction -> final GEMM tile.

This file is intentionally ``Float32``-only. It demonstrates TMEM lifecycle,
layout-specific TMEM drains, and the DSMEM handoff after the drain. The
multi-dtype REDS/ATOMS root-accumulator variants are demonstrated in
``cluster_smem_reduce.py``. A root-atomic cluster reduction may be simpler than
the peer-read combine used here, but this example keeps the CTA0 peer-read path
so the TMEM-to-SMEM layout mapping stays explicit.

Cluster TMEM reduction path:

+---------+---------------------------+---------------------------+---------------------------+
| Dtype   | Add                       | Min                       | Max                       |
+=========+===========================+===========================+===========================+
| ``f32`` | CTA 0 maps every peer     | CTA 0 maps every peer     | CTA 0 maps every peer     |
|         | drained TMEM tile with    | drained TMEM tile with    | drained TMEM tile with    |
|         | ``prims.mapa`` and adds    | ``prims.mapa`` and applies | ``prims.mapa`` and applies |
|         | in ``f32``.               | ``cutlass.min`` in        | ``cutlass.max`` in        |
|         |                           | ``f32``.                  | ``f32``.                  |
+---------+---------------------------+---------------------------+---------------------------+

To run::

    python CuTeDSL/experimental/primitives/reduction/cluster_tmem_reduce.py
    python CuTeDSL/experimental/primitives/reduction/cluster_tmem_reduce.py \
        --cluster-shape 2,2 --tmem-layout 16x128b

"""

import argparse
from functools import lru_cache
from typing import Callable, Literal, cast

import torch
import cuda.bindings.driver as cuda

import cutlass
import cutlass.cute as cute
from cutlass.cute.runtime import make_fake_compact_tensor, make_fake_stream
from cutlass.experimental import primitives as prims

_DEFAULT_CLUSTER_SHAPE: tuple[int, int] = (2, 1)
_DEFAULT_TMEM_LAYOUT: Literal["32x32b", "16x64b", "16x128b", "16x256b"] = "32x32b"
_DEFAULT_REDUCE_OP: Literal["add", "max", "min"] = "add"
_WARP_SIZE: int = 32
_WARPS_PER_CTA: int = 4
_THREADS: int = _WARP_SIZE * _WARPS_PER_CTA
_MAX_LAYOUT_REGS: int = 4
_TILE_ROWS: int = 32
_S2T_ROWS: int = 128
_N_TMEM_COLS: int = 32
REDUCE_OPS: tuple[Literal["add", "max", "min"], ...] = ("add", "max", "min")


def _normalize_reduce_op(REDUCE_OP: str) -> Literal["add", "max", "min"]:
    if REDUCE_OP not in REDUCE_OPS:
        raise ValueError(f"REDUCE_OP must be 'add', 'max', or 'min', got {REDUCE_OP!r}")
    return cast(Literal["add", "max", "min"], REDUCE_OP)


TMEM_LAYOUTS = ("32x32b", "16x64b", "16x128b", "16x256b")


def _layout_regs(TMEM_LAYOUT: str) -> int:
    """Return the number of ``Float32`` registers produced per lane."""
    TMEM_LAYOUT = _normalize_tmem_layout(TMEM_LAYOUT)
    if TMEM_LAYOUT == "16x128b":
        return 2
    if TMEM_LAYOUT == "16x256b":
        return 4
    return 1


def _layout_rows(TMEM_LAYOUT: str) -> int:
    """Return the number of TMEM rows touched by one load instruction."""
    TMEM_LAYOUT = _normalize_tmem_layout(TMEM_LAYOUT)
    if TMEM_LAYOUT == "32x32b":
        return 32
    return 16


def _output_rows(TMEM_LAYOUT: str) -> int:
    """Return the logical row count produced by the populated TMEM data."""
    TMEM_LAYOUT = _normalize_tmem_layout(TMEM_LAYOUT)
    if TMEM_LAYOUT == "16x256b":
        return _TILE_ROWS // 2
    return _TILE_ROWS


def _cluster_reduce_identity(REDUCE_OP: cutlass.Constexpr) -> cutlass.Float32:
    """Return the identity value for one cluster tile-element reduction."""
    if cutlass.const_expr(REDUCE_OP == "add"):
        return cutlass.Float32(0.0)
    if cutlass.const_expr(REDUCE_OP == "min"):
        return cutlass.Float32(float("inf"))
    return cutlass.Float32(-float("inf"))


def _cluster_reduce_combine(
    total: cutlass.Float32,
    value: cutlass.Float32,
    REDUCE_OP: cutlass.Constexpr,
) -> cutlass.Float32:
    """Combine one peer tile value into an elementwise cluster reduction."""
    if cutlass.const_expr(REDUCE_OP == "add"):
        return total + value
    if cutlass.const_expr(REDUCE_OP == "min"):
        return cute.math.min(total, value)
    return cute.math.max(total, value)


@cute.kernel
def _kernel(
    src: cute.Tensor,  # [cluster_ctas, _S2T_ROWS, _MAX_LAYOUT_REGS] Float32
    out: cute.Tensor,  # [logical tile rows, active layout regs] Float32
    CLUSTER_SHAPE: cutlass.Constexpr,
    TMEM_LAYOUT: cutlass.Constexpr,
    REDUCE_OP: cutlass.Constexpr,
) -> None:
    """Reduce one TMEM tile per CTA into one cluster-wide tile."""
    cluster_x, cluster_y = CLUSTER_SHAPE
    cluster_ctas = cluster_x * cluster_y
    tx, _, _ = cute.arch.thread_idx()
    warp_idx = tx // _WARP_SIZE
    lane_idx = tx % _WARP_SIZE
    rank = cute.arch.block_idx_in_cluster()

    tmem_addr_smem = cutlass.Array(
        cutlass.Int32,
        1,
        space=cutlass.AddressSpace.smem,
    )
    smem_values = cutlass.Array(
        cutlass.Float32,
        _S2T_ROWS * _MAX_LAYOUT_REGS,
        space=cutlass.AddressSpace.smem,
        alignment=16,
    )
    smem_buf = cutlass.Array(
        cutlass.Float32,
        _S2T_ROWS * _MAX_LAYOUT_REGS,
        space=cutlass.AddressSpace.smem,
        alignment=16,
    )

    src_ptr = src.iterator.raw_ptr()
    for row_group in cutlass.range_constexpr(_S2T_ROWS // _WARP_SIZE):
        row = row_group * _WARP_SIZE + lane_idx
        for value_idx in cutlass.range_constexpr(_MAX_LAYOUT_REGS):
            # Seed deterministic per-CTA accumulator values in SMEM. In a real
            # epilogue, this block would be replaced by tcgen05.mma producing
            # the same logical tile in TMEM.
            src_offset = (
                rank * _S2T_ROWS * _MAX_LAYOUT_REGS + row * _MAX_LAYOUT_REGS + value_idx
            )
            value = (src_ptr + src_offset).load()
            smem_values[row * _MAX_LAYOUT_REGS + value_idx] = value

    prims.barrier_cta_sync(0)
    prims.fence_proxy(prims.Proxy.ASYNC_SHARED, space=prims.SharedSpace.shared_cta)

    # Allocate a CTA-private TMEM tile and copy the SMEM seed tile into it with
    # UTCCP. Only one elected thread issues the asynchronous copy instruction.
    if warp_idx == 0:
        prims.tcgen05_alloc(tmem_addr_smem, _N_TMEM_COLS, group=prims.CTAGroup.CTA_1)
        prims.tcgen05_relinquish_alloc_permit(group=prims.CTAGroup.CTA_1)
    prims.barrier_cta_sync(0)
    tmem_addr = tmem_addr_smem.load()
    tmem_ptr = cutlass.inttoptr(tmem_addr, 6, cutlass.Float32)
    tmem_base = prims.TmemAddr(tmem_addr)

    s2t_desc = prims.Tcgen05SmemDesc.build(
        start_address=smem_values,
        leading_byte_offset=16,
        stride_byte_offset=128,
        layout=prims.Tcgen05SmemSwizzle.NONE,
    )
    s2t_shape, s2t_multicast = prims.S2TCopyMode.S2T_128x128b
    if warp_idx == 0:
        if prims.elect_sync():
            prims.tcgen05_cp(
                s2t_shape,
                tmem_ptr,
                s2t_desc,
                group=prims.CTAGroup.CTA_1,
                multicast=s2t_multicast,
            )
    prims.tcgen05_wait(prims.Tcgen05Wait.STORE)

    rows_per_load = _layout_rows(TMEM_LAYOUT)
    regs_per_row = _layout_regs(TMEM_LAYOUT)

    # Drain the CTA-private TMEM tile into SMEM. The UTCCP producer
    # warp owns this copied tile, so the same warp walks the rows in chunks
    # matching the selected TMEM load layout.
    if warp_idx == 0:
        for row_block in cutlass.range_constexpr(_TILE_ROWS // rows_per_load):
            row = row_block * rows_per_load + lane_idx
            tile_ptr = prims.TmemAddr.from_row_col(
                tmem_base.row_id + row_block * rows_per_load,
                tmem_base.col_id,
            ).as_ptr(cutlass.Float32)
            loaded = prims.tcgen05_ld(TMEM_LAYOUT, tile_ptr, num=1)
            prims.tcgen05_wait(prims.Tcgen05Wait.LOAD)
            row_offset = row * _MAX_LAYOUT_REGS
            if lane_idx < rows_per_load:
                if cutlass.const_expr(TMEM_LAYOUT == "16x256b"):
                    if (lane_idx & cutlass.Int32(3)) < cutlass.Int32(2):
                        for value_idx in cutlass.range_constexpr(regs_per_row):
                            smem_buf[row_offset + value_idx] = loaded[value_idx]
                elif cutlass.const_expr(regs_per_row == 1):
                    smem_buf[row_offset:1] = loaded
                else:
                    for value_idx in cutlass.range_constexpr(regs_per_row):
                        smem_buf[row_offset + value_idx] = loaded[value_idx]

    prims.barrier_cta_sync(0)
    prims.barrier_cluster_arrive_relaxed()
    prims.barrier_cluster_wait()

    if rank == 0:
        if tx < _output_rows(TMEM_LAYOUT):
            if cutlass.const_expr(TMEM_LAYOUT == "16x256b"):
                logical_row = tx
                row_block = logical_row // 8
                useful_lane = logical_row % 8
                lane_group = useful_lane // 2
                lane_in_group = useful_lane % 2
                row = row_block * 16 + lane_group * 4 + lane_in_group
            else:
                row = tx
            row_offset = row * _MAX_LAYOUT_REGS
            # Only the active register columns for this TMEM layout are
            # published. The backing SMEM tile still uses _MAX_LAYOUT_REGS so
            # all layout variants share the same SMEM backing storage.
            if cutlass.const_expr(TMEM_LAYOUT == "16x256b"):
                out_row_offset = tx * 4
                active_regs = 4
            elif cutlass.const_expr(TMEM_LAYOUT == "16x128b"):
                out_row_offset = row * 2
                active_regs = 2
            else:
                out_row_offset = row
                active_regs = 1
            for value_idx in cutlass.range_constexpr(active_regs):
                total = _cluster_reduce_identity(REDUCE_OP)
                for peer_rank in cutlass.range_constexpr(cluster_ctas):
                    # TMEM cannot be read directly across CTA ranks; each peer
                    # exposes its drained tile through DSMEM via prims.mapa.
                    peer_smem_buf = prims.mapa(smem_buf.data_ptr(), peer_rank)
                    peer_value = (peer_smem_buf + row_offset + value_idx).load()
                    total = _cluster_reduce_combine(total, peer_value, REDUCE_OP)
                (out.iterator.raw_ptr() + out_row_offset + value_idx).store(total)

    prims.barrier_cluster_arrive_relaxed()
    prims.barrier_cluster_wait()

    # Deallocation is ordered after the cluster has consumed every drained
    # SMEM tile.
    prims.tcgen05_fence(prims.Tcgen05Fence.BEFORE_THREAD_SYNC)
    prims.barrier_cta_sync(0)
    if warp_idx == 0:
        prims.tcgen05_dealloc(tmem_ptr, _N_TMEM_COLS, group=prims.CTAGroup.CTA_1)


@cute.jit
def _host(
    src: cute.Tensor,
    out: cute.Tensor,
    stream,
    CLUSTER_SHAPE: cutlass.Constexpr,
    TMEM_LAYOUT: cutlass.Constexpr,
    REDUCE_OP: cutlass.Constexpr,
) -> None:
    """Launch one CTA cluster."""
    cluster_x, cluster_y = CLUSTER_SHAPE
    _kernel(src, out, CLUSTER_SHAPE, TMEM_LAYOUT, REDUCE_OP).launch(
        grid=(cluster_x, cluster_y, 1),
        block=(_THREADS, 1, 1),
        cluster=(cluster_x, cluster_y, 1),
        stream=stream,
    )


def _normalize_cluster_shape(CLUSTER_SHAPE: tuple[int, int]) -> tuple[int, int]:
    """Return a validated ``(cluster_x, cluster_y)`` tuple."""
    if len(CLUSTER_SHAPE) != 2:
        raise ValueError(f"CLUSTER_SHAPE must have two dimensions, got {CLUSTER_SHAPE}")
    cluster_x, cluster_y = (int(CLUSTER_SHAPE[0]), int(CLUSTER_SHAPE[1]))
    cluster_ctas = cluster_x * cluster_y
    if cluster_x < 1 or cluster_y < 1 or cluster_ctas < 2:
        raise ValueError(
            f"cluster must contain at least 2 CTAs (got {cluster_x}x{cluster_y})"
        )
    if cluster_ctas > 16:
        raise ValueError(
            f"cluster must contain at most 16 CTAs (got {cluster_x}x{cluster_y})"
        )
    return cluster_x, cluster_y


def _normalize_tmem_layout(
    TMEM_LAYOUT: str,
) -> Literal["32x32b", "16x64b", "16x128b", "16x256b"]:
    """Return a validated TMEM load/store layout variant."""
    if TMEM_LAYOUT not in TMEM_LAYOUTS:
        raise ValueError(
            f"TMEM_LAYOUT must be one of {TMEM_LAYOUTS}, got {TMEM_LAYOUT!r}"
        )
    return TMEM_LAYOUT


@lru_cache(maxsize=None)
def compile(
    CLUSTER_SHAPE: tuple[int, int] = _DEFAULT_CLUSTER_SHAPE,
    TMEM_LAYOUT: str = _DEFAULT_TMEM_LAYOUT,
    REDUCE_OP: str = _DEFAULT_REDUCE_OP,
) -> Callable:
    """AOT-compile the cluster TMEM reduction example."""
    CLUSTER_SHAPE = _normalize_cluster_shape(CLUSTER_SHAPE)
    TMEM_LAYOUT = _normalize_tmem_layout(TMEM_LAYOUT)
    REDUCE_OP = _normalize_reduce_op(REDUCE_OP)

    cluster_ctas = CLUSTER_SHAPE[0] * CLUSTER_SHAPE[1]
    fake_src = make_fake_compact_tensor(
        cutlass.Float32,
        (cluster_ctas, _S2T_ROWS, _MAX_LAYOUT_REGS),
        stride_order=(2, 1, 0),
        assumed_align=16,
    )
    fake_out = make_fake_compact_tensor(
        cutlass.Float32,
        (_output_rows(TMEM_LAYOUT), _layout_regs(TMEM_LAYOUT)),
        stride_order=(1, 0),
        assumed_align=16,
    )
    return cute.compile(
        _host,
        fake_src,
        fake_out,
        make_fake_stream(),
        CLUSTER_SHAPE,
        TMEM_LAYOUT,
        REDUCE_OP,
        options="--enable-tvm-ffi",
    )


def _utccp_layout_view(src: torch.Tensor, TMEM_LAYOUT: str) -> torch.Tensor:
    """Return ``src`` in the fragment order produced by UTCCP + tcgen05_ld."""
    active_regs = _layout_regs(TMEM_LAYOUT)
    output_rows = _output_rows(TMEM_LAYOUT)
    view = src.new_zeros((src.shape[0], output_rows, active_regs))

    if TMEM_LAYOUT == "32x32b":
        view[:, :, 0] = src[:, :_TILE_ROWS, 0]
        return view

    for row in range(output_rows):
        if TMEM_LAYOUT == "16x256b":
            row_block = row // 8
            useful_lane = row % 8
            lane = (useful_lane // 2) * 4 + useful_lane % 2
        else:
            row_block = row // 16
            lane = row % 16
        lane_group = lane // 4
        lane_in_group = lane % 4

        if TMEM_LAYOUT == "16x64b":
            src_row = row_block * 16 + lane_group + (lane_in_group % 2) * 8
            src_col = lane_in_group // 2
            view[:, row, 0] = src[:, src_row, src_col]
        elif TMEM_LAYOUT == "16x128b":
            src_col = lane_in_group
            for value_idx in range(active_regs):
                src_row = row_block * 16 + lane_group + value_idx * 8
                view[:, row, value_idx] = src[:, src_row, src_col]
        else:
            # The 128b UTCCP source populates half of each 16x256b fragment.
            # Treat that as a compact half-height logical tile rather than a
            # full tile with garbage or padding rows.
            src_col_base = lane_in_group * 2
            for value_idx in range(active_regs):
                src_row = row_block * 16 + lane_group + (value_idx // 2) * 8
                src_col = src_col_base + value_idx % 2
                view[:, row, value_idx] = src[:, src_row, src_col]

    return view


def expected(
    src: torch.Tensor,
    TMEM_LAYOUT: str = _DEFAULT_TMEM_LAYOUT,
    REDUCE_OP: str = _DEFAULT_REDUCE_OP,
) -> torch.Tensor:
    """Return the torch reference for one TMEM layout and reduction variant."""
    TMEM_LAYOUT = _normalize_tmem_layout(TMEM_LAYOUT)
    REDUCE_OP = _normalize_reduce_op(REDUCE_OP)
    active = _utccp_layout_view(src, TMEM_LAYOUT)
    if REDUCE_OP == "add":
        return active.sum(dim=0)
    if REDUCE_OP == "min":
        return active.min(dim=0).values
    return active.max(dim=0).values


def run(
    compiled_fn: Callable,
    CLUSTER_SHAPE: tuple[int, int] = _DEFAULT_CLUSTER_SHAPE,
    TMEM_LAYOUT: str = _DEFAULT_TMEM_LAYOUT,
) -> tuple[torch.Tensor, torch.Tensor]:
    """Allocate tensors, run the kernel, and return ``(out, src)``."""
    if not torch.cuda.is_available():
        raise RuntimeError("CUDA GPU required")

    CLUSTER_SHAPE = _normalize_cluster_shape(CLUSTER_SHAPE)
    TMEM_LAYOUT = _normalize_tmem_layout(TMEM_LAYOUT)
    cluster_ctas = CLUSTER_SHAPE[0] * CLUSTER_SHAPE[1]
    src = torch.arange(
        1,
        cluster_ctas * _S2T_ROWS * _MAX_LAYOUT_REGS + 1,
        dtype=torch.float32,
        device="cuda",
    ).reshape(cluster_ctas, _S2T_ROWS, _MAX_LAYOUT_REGS)
    out = torch.empty(
        (_output_rows(TMEM_LAYOUT), _layout_regs(TMEM_LAYOUT)),
        dtype=torch.float32,
        device="cuda",
    )

    stream = cuda.CUstream(torch.cuda.current_stream().cuda_stream)
    compiled_fn(src, out, stream)
    torch.cuda.synchronize()
    return out, src


def verify(
    CLUSTER_SHAPE: tuple[int, int] = _DEFAULT_CLUSTER_SHAPE,
    TMEM_LAYOUT: str = _DEFAULT_TMEM_LAYOUT,
    REDUCE_OP: str = _DEFAULT_REDUCE_OP,
) -> None:
    """Compile, run, and compare the cluster TMEM reduction with torch."""
    CLUSTER_SHAPE = _normalize_cluster_shape(CLUSTER_SHAPE)
    TMEM_LAYOUT = _normalize_tmem_layout(TMEM_LAYOUT)
    REDUCE_OP = _normalize_reduce_op(REDUCE_OP)
    compiled_fn = compile(
        CLUSTER_SHAPE=CLUSTER_SHAPE,
        TMEM_LAYOUT=TMEM_LAYOUT,
        REDUCE_OP=REDUCE_OP,
    )
    print(
        "Compile kernel "
        f"(CLUSTER_SHAPE={CLUSTER_SHAPE}, TMEM_LAYOUT={TMEM_LAYOUT}, "
        f"REDUCE_OP={REDUCE_OP}) OK",
        flush=True,
    )

    out, src = run(compiled_fn, CLUSTER_SHAPE=CLUSTER_SHAPE, TMEM_LAYOUT=TMEM_LAYOUT)
    print(
        "Run kernel "
        f"(CLUSTER_SHAPE={CLUSTER_SHAPE}, TMEM_LAYOUT={TMEM_LAYOUT}, "
        f"REDUCE_OP={REDUCE_OP}) OK",
        flush=True,
    )

    if out.dtype == torch.float32 and REDUCE_OP == "add":
        rtol, atol = 1e-6, 1e-6
    else:
        rtol, atol = 0, 0
    torch.testing.assert_close(
        out,
        expected(src, TMEM_LAYOUT=TMEM_LAYOUT, REDUCE_OP=REDUCE_OP),
        rtol=rtol,
        atol=atol,
    )
    print(
        "verify "
        f"(CLUSTER_SHAPE={CLUSTER_SHAPE}, TMEM_LAYOUT={TMEM_LAYOUT}, "
        f"REDUCE_OP={REDUCE_OP}): PASS"
    )


def _parse_cluster_shape(value: str) -> tuple[int, int]:
    """Parse ``x,y`` CLI input into a validated cluster-shape tuple."""
    parts = value.split(",")
    if len(parts) != 2:
        raise argparse.ArgumentTypeError(
            f"cluster shape must be formatted as x,y, got {value!r}"
        )
    try:
        shape = int(parts[0]), int(parts[1])
    except ValueError as exc:
        raise argparse.ArgumentTypeError(
            f"cluster shape must contain integers, got {value!r}"
        ) from exc
    try:
        return _normalize_cluster_shape(shape)
    except ValueError as exc:
        raise argparse.ArgumentTypeError(str(exc)) from exc


def main() -> None:
    """Parse CLI arguments and run verification."""
    parser = argparse.ArgumentParser(
        description="Run the cluster TMEM-to-DSMEM reduction example.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument(
        "--cluster-shape",
        type=_parse_cluster_shape,
        default=_DEFAULT_CLUSTER_SHAPE,
        help="Compile-time cluster shape tuple written as x,y",
    )
    parser.add_argument(
        "--tmem-layout",
        dest="TMEM_LAYOUT",
        default=_DEFAULT_TMEM_LAYOUT,
        choices=TMEM_LAYOUTS,
        help="Compile-time TMEM load layout",
    )
    parser.add_argument(
        "--reduce-op",
        dest="REDUCE_OP",
        default=_DEFAULT_REDUCE_OP,
        choices=REDUCE_OPS,
        help="Compile-time reduction operator",
    )
    args = parser.parse_args()
    verify(
        CLUSTER_SHAPE=args.cluster_shape,
        TMEM_LAYOUT=args.TMEM_LAYOUT,
        REDUCE_OP=args.REDUCE_OP,
    )


if __name__ == "__main__":
    main()
