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
Cluster-level tile reduction through shared-cluster memory.

Each CTA owns one ``ROWS_PER_TILE x TILE_COLS`` shared-memory tile. Root
reductions map rank 0's tile with ``prims.mapa`` and contribute through
``prims.red`` or ATOMS-style float atomics; the pointer address space selects
``shared::cluster`` lowering. Half/bfloat min/max use a binary-tree fallback
that combines peer CTA tiles through ``prims.mapa`` instead of scalar REDS.

The root path uses non-relaxed ``barrier_cluster_arrive`` before rank 0 reads
the accumulator. The tree fallback uses ``barrier_cta_sync(0)`` for local SMEM
stores, then ``barrier_cluster_arrive_relaxed`` plus ``barrier_cluster_wait``
before peer reads. The example uses only ordinary SMEM stores, REDS/ATOMS, and
peer DSMEM reads, so it does not need mbarrier or async-copy fences.

Cluster reduction path:

+-------------------+--------------------------------+--------------------------------+--------------------------------+
| Dtype             | Add                            | Min                            | Max                            |
+===================+================================+================================+================================+
| ``i32``           | Root ``prims.red``              | Root ``prims.red``              | Root ``prims.red``              |
|                   | ``shared::cluster`` through    | ``shared::cluster`` through    | ``shared::cluster`` through    |
|                   | ``prims.mapa``                  | ``prims.mapa``                  | ``prims.mapa``                  |
+-------------------+--------------------------------+--------------------------------+--------------------------------+
| ``f32``           | Root ``prims.red``              | Root ``cute.arch.atomic_fmin`` | Root ``cute.arch.atomic_fmax`` |
|                   | ``shared::cluster`` through    | through ``prims.mapa``          | through ``prims.mapa``          |
|                   | ``prims.mapa``                  | (ATOMS-style)                  | (ATOMS-style)                  |
+-------------------+--------------------------------+--------------------------------+--------------------------------+
| ``f16``/``bf16``  | Root ``prims.red``              | Binary-tree peer-tile combine  | Binary-tree peer-tile combine  |
|                   | ``shared::cluster`` through    | through ``prims.mapa``          | through ``prims.mapa``          |
|                   | ``prims.mapa``                  |                                |                                |
+-------------------+--------------------------------+--------------------------------+--------------------------------+

To run::

    python CuTeDSL/experimental/primitives/reduction/cluster_smem_reduce.py
    python CuTeDSL/experimental/primitives/reduction/cluster_smem_reduce.py \
        --cluster-shape 2,2 --tile-cols 8 --dtype bf16

"""

import argparse
from functools import lru_cache
from typing import Callable, Literal, TypeAlias, cast

import torch
import cuda.bindings.driver as cuda

import cutlass
import cutlass.cute as cute
from cutlass.cute.runtime import make_fake_compact_tensor, make_fake_stream
from cutlass.experimental import primitives as prims

_DEFAULT_CLUSTER_SHAPE: tuple[int, int] = (2, 1)
_ROWS_PER_TILE: int = 4
_DEFAULT_TILE_COLS: int = 4
_DEFAULT_REDUCE_OP: Literal["add", "max", "min"] = "add"
_WARP_SIZE: int = 32
_PARTIAL_BASE: int = 10
_TREE_STRIDES: tuple[int, ...] = (1, 2, 4, 8)
REDUCE_OPS: tuple[Literal["add", "max", "min"], ...] = ("add", "max", "min")
DTypeName: TypeAlias = Literal["f16", "bf16", "f32", "i32"]
_DEFAULT_DTYPE: DTypeName = "i32"
DTYPES: tuple[DTypeName, ...] = ("f16", "bf16", "f32", "i32")
_CUTLASS_DTYPES: dict[DTypeName, type[cutlass.Numeric]] = {
    "f16": cutlass.Float16,
    "bf16": cutlass.BFloat16,
    "f32": cutlass.Float32,
    "i32": cutlass.Int32,
}
_TORCH_DTYPES: dict[DTypeName, torch.dtype] = {
    "f16": torch.float16,
    "bf16": torch.bfloat16,
    "f32": torch.float32,
    "i32": torch.int32,
}


def _normalize_reduce_op(REDUCE_OP: str) -> Literal["add", "max", "min"]:
    if REDUCE_OP not in REDUCE_OPS:
        raise ValueError(f"REDUCE_OP must be 'add', 'max', or 'min', got {REDUCE_OP!r}")
    return cast(Literal["add", "max", "min"], REDUCE_OP)


def _normalize_dtype(DTYPE: str) -> DTypeName:
    """Return a validated dtype alias for cluster shared-memory reductions."""
    if DTYPE not in DTYPES:
        raise ValueError(f"DTYPE must be one of {DTYPES}, got {DTYPE!r}")
    return cast(DTypeName, DTYPE)


@cute.jit
def _cast_to_dtype(
    value,
    DTYPE: cutlass.Constexpr,
):
    """Cast a scalar value back to the compile-time reduction dtype."""
    if cutlass.const_expr(DTYPE == "f16"):
        return cutlass.Float16(value)
    if cutlass.const_expr(DTYPE == "bf16"):
        return cutlass.BFloat16(value)
    if cutlass.const_expr(DTYPE == "i32"):
        return cutlass.Int32(value)
    return cutlass.Float32(value)


@cute.jit
def _combine_value(
    lhs,
    rhs,
    REDUCE_OP: cutlass.Constexpr,
    DTYPE: cutlass.Constexpr,
):
    """Combine two same-dtype values with the selected reduction operation."""
    if cutlass.const_expr(REDUCE_OP == "add"):
        return _cast_to_dtype(lhs + rhs, DTYPE)
    if cutlass.const_expr(REDUCE_OP == "min"):
        return cute.math.min(lhs, rhs)
    return cute.math.max(lhs, rhs)


@cute.jit
def _identity_value(
    REDUCE_OP: cutlass.Constexpr,
    DTYPE: cutlass.Constexpr,
):
    """Return the Python literal identity for the selected op and dtype."""
    if cutlass.const_expr(REDUCE_OP == "add"):
        return 0
    if cutlass.const_expr(DTYPE == "i32"):
        if cutlass.const_expr(REDUCE_OP == "min"):
            return 2147483647
        return -2147483648
    if cutlass.const_expr(DTYPE == "f16"):
        if cutlass.const_expr(REDUCE_OP == "min"):
            return 65504.0
        return -65504.0
    if cutlass.const_expr(DTYPE == "bf16"):
        if cutlass.const_expr(REDUCE_OP == "min"):
            return 3.0e38
        return -3.0e38
    if cutlass.const_expr(REDUCE_OP == "min"):
        return 3.4028234663852886e38
    return -3.4028234663852886e38


@cute.jit
def _smem_red(
    ptr,
    value,
    REDUCE_OP: cutlass.Constexpr,
    DTYPE: cutlass.Constexpr,
) -> None:
    """Contribute one tile element through NVVM REDS or ATOMS."""
    if cutlass.const_expr(DTYPE == "f32" and REDUCE_OP == "max"):
        cute.arch.atomic_fmax(ptr, value, sem="relaxed", scope="cluster")
        return
    if cutlass.const_expr(DTYPE == "f32" and REDUCE_OP == "min"):
        cute.arch.atomic_fmin(ptr, value, sem="relaxed", scope="cluster")
        return

    if cutlass.const_expr(REDUCE_OP == "add"):
        op = prims.ReductionOp.ADD
    elif cutlass.const_expr(REDUCE_OP == "min"):
        op = prims.ReductionOp.MIN
    else:
        op = prims.ReductionOp.MAX

    if cutlass.const_expr(DTYPE == "i32"):
        red_type = prims.ReductionType.S32
    elif cutlass.const_expr(DTYPE == "f16"):
        red_type = prims.ReductionType.F16
    elif cutlass.const_expr(DTYPE == "bf16"):
        red_type = prims.ReductionType.BF16
    else:
        red_type = prims.ReductionType.F32

    prims.red(
        op,
        red_type,
        ptr,
        value,
        mem_order=prims.MemOrder.RELAXED,
        mem_scope=prims.MemScope.CLUSTER,
    )


@cute.jit
def _cluster_tree_reduce_tile(
    smem_buf,
    tile_elems: cutlass.Constexpr,
    rank: cutlass.Int32,
    cluster_ctas: cutlass.Constexpr,
    tx: cutlass.Int32,
    REDUCE_OP: cutlass.Constexpr,
    DTYPE: cutlass.Constexpr,
) -> None:
    """Reduce one shared-memory tile per CTA into rank 0 through a tree."""
    # The local tile has just been written. The cluster barrier makes every
    # CTA's shared-memory tile visible to peer CTA reads through prims.mapa.
    prims.barrier_cta_sync(0)
    prims.barrier_cluster_arrive_relaxed()
    prims.barrier_cluster_wait()

    for stride in _TREE_STRIDES:
        if cluster_ctas > stride:
            peer_rank = rank + cutlass.Int32(stride)
            # Binary tree stage:
            #   stride=1: ranks 0,2,4,... absorb 1,3,5,...
            #   stride=2: ranks 0,4,8,... absorb 2,6,10,...
            # and so on. Non-owner CTAs simply wait for the next stage.
            if (
                (rank % cutlass.Int32(2 * stride) == cutlass.Int32(0))
                & (peer_rank < cutlass.Int32(cluster_ctas))
                & (tx < tile_elems)
            ):
                peer_smem_buf = prims.mapa(smem_buf.data_ptr(), peer_rank)
                local_value = smem_buf[tx]
                peer_value = (peer_smem_buf + tx).load()
                combined = _combine_value(local_value, peer_value, REDUCE_OP, DTYPE)
                smem_buf[tx] = combined

            # Stage boundary: owner CTAs overwrite their local SMEM tile,
            # and the next stride must see those updated values.
            prims.barrier_cta_sync(0)
            prims.barrier_cluster_arrive_relaxed()
            prims.barrier_cluster_wait()


@cute.kernel
def _kernel(
    src: cute.Tensor,  # [cluster_ctas, _ROWS_PER_TILE, TILE_COLS]
    out: cute.Tensor,  # [_ROWS_PER_TILE, TILE_COLS]
    CLUSTER_SHAPE: cutlass.Constexpr,
    REDUCE_OP: cutlass.Constexpr,
    TILE_COLS: cutlass.Constexpr,
    DTYPE: cutlass.Constexpr,
) -> None:
    """Reduce one tile per CTA into one cluster-wide tile."""
    cluster_x, cluster_y = CLUSTER_SHAPE
    cluster_ctas = cluster_x * cluster_y
    tx, _, _ = cute.arch.thread_idx()
    rank = cute.arch.block_idx_in_cluster()
    tile_elems = _ROWS_PER_TILE * TILE_COLS

    smem_buf = cutlass.Array(
        src.element_type,
        _ROWS_PER_TILE * TILE_COLS,
        space=cutlass.AddressSpace.smem,
        alignment=16,
    )

    src_ptr = src.iterator.raw_ptr()
    need_smem_reduction = cutlass.const_expr(
        (DTYPE == "f16" or DTYPE == "bf16") and REDUCE_OP != "add"
    )
    # Scalar red.min/max.f16 and red.min/max.bf16 are rejected by ptxas; the
    # fallback path combines CTA-local SMEM tiles through peer reads.
    if cutlass.const_expr(not need_smem_reduction):
        if rank == 0:
            if tx < tile_elems:
                smem_buf[tx] = _cast_to_dtype(_identity_value(REDUCE_OP, DTYPE), DTYPE)

        prims.barrier_cta_sync(0)
        prims.barrier_cluster_arrive()
        prims.barrier_cluster_wait()

        if tx < tile_elems:
            root_smem_buf = prims.mapa(smem_buf.data_ptr(), cutlass.Int32(0))
            src_offset = rank * tile_elems + tx
            _smem_red(
                root_smem_buf + tx,
                (src_ptr + src_offset).load(),
                REDUCE_OP,
                DTYPE,
            )

        # relaxed cluster REDS/ATOMS are not ordered by a relaxed cluster
        # barrier. Use the non-relaxed arrive so rank 0 observes every
        # contribution before loading the root accumulator tile.
        prims.barrier_cluster_arrive()
        prims.barrier_cluster_wait()
    else:
        if tx < tile_elems:
            # Each CTA starts by publishing its private input tile into local
            # SMEM. The tree reducer treats this as the per-rank SMEM tile.
            src_offset = rank * tile_elems + tx
            smem_buf[tx] = (src_ptr + src_offset).load()

        _cluster_tree_reduce_tile(
            smem_buf, tile_elems, rank, cluster_ctas, tx, REDUCE_OP, DTYPE
        )

    if rank == 0:
        if tx < tile_elems:
            # After the final tree stage, rank 0's SMEM tile is the complete
            # cluster reduction. Preserve tile shape in the output.
            (out.iterator.raw_ptr() + tx).store(smem_buf[tx])

    # Keep the cluster alive until rank 0 has published the result. There is no
    # mbarrier init or async proxy traffic in this kernel, so no extra fence is
    # needed here.
    prims.barrier_cluster_arrive_relaxed()
    prims.barrier_cluster_wait()


@cute.jit
def _host(
    src: cute.Tensor,
    out: cute.Tensor,
    stream,
    CLUSTER_SHAPE: cutlass.Constexpr,
    REDUCE_OP: cutlass.Constexpr,
    TILE_COLS: cutlass.Constexpr,
    DTYPE: cutlass.Constexpr,
) -> None:
    """Launch one CTA cluster."""
    cluster_x, cluster_y = CLUSTER_SHAPE
    _kernel(src, out, CLUSTER_SHAPE, REDUCE_OP, TILE_COLS, DTYPE).launch(
        grid=(cluster_x, cluster_y, 1),
        block=(_WARP_SIZE, 1, 1),
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


def _normalize_tile_cols(TILE_COLS: int) -> int:
    """Return a validated tile column count."""
    TILE_COLS = int(TILE_COLS)
    if TILE_COLS not in (1, 2, 4, 8):
        raise ValueError(f"TILE_COLS must be one of 1, 2, 4, or 8, got {TILE_COLS}")
    return TILE_COLS


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


@lru_cache(maxsize=None)
def _compile_cached(
    CLUSTER_SHAPE: tuple[int, int],
    TILE_COLS: int,
    REDUCE_OP: str,
    DTYPE: DTypeName,
) -> Callable:
    """AOT-compile the cluster shared-memory reduction example."""
    cluster_ctas = CLUSTER_SHAPE[0] * CLUSTER_SHAPE[1]
    cutlass_dtype = _CUTLASS_DTYPES[DTYPE]
    fake_src = make_fake_compact_tensor(
        cutlass_dtype,
        (cluster_ctas, _ROWS_PER_TILE, TILE_COLS),
        stride_order=(2, 1, 0),
        assumed_align=16,
    )
    fake_dst = make_fake_compact_tensor(
        cutlass_dtype,
        (_ROWS_PER_TILE, TILE_COLS),
        stride_order=(1, 0),
        assumed_align=16,
    )
    return cute.compile(
        _host,
        fake_src,
        fake_dst,
        make_fake_stream(),
        CLUSTER_SHAPE,
        REDUCE_OP,
        TILE_COLS,
        DTYPE,
        options="--enable-tvm-ffi",
    )


def compile(
    CLUSTER_SHAPE: tuple[int, int] = _DEFAULT_CLUSTER_SHAPE,
    TILE_COLS: int = _DEFAULT_TILE_COLS,
    REDUCE_OP: str = _DEFAULT_REDUCE_OP,
    DTYPE: str = _DEFAULT_DTYPE,
    ITEMS_PER_LANE: int | None = None,
) -> Callable:
    """AOT-compile the cluster shared-memory reduction example."""
    if ITEMS_PER_LANE is not None:
        TILE_COLS = ITEMS_PER_LANE
    return _compile_cached(
        _normalize_cluster_shape(CLUSTER_SHAPE),
        _normalize_tile_cols(TILE_COLS),
        _normalize_reduce_op(REDUCE_OP),
        _normalize_dtype(DTYPE),
    )


def expected(
    src: torch.Tensor,
    REDUCE_OP: str = _DEFAULT_REDUCE_OP,
) -> torch.Tensor:
    """Return the torch reference for one tile reduction variant."""
    REDUCE_OP = _normalize_reduce_op(REDUCE_OP)
    if REDUCE_OP == "add":
        return src.sum(dim=0).to(src.dtype)
    if REDUCE_OP == "min":
        return src.min(dim=0).values
    return src.max(dim=0).values


def run(
    compiled_fn: Callable,
    CLUSTER_SHAPE: tuple[int, int] = _DEFAULT_CLUSTER_SHAPE,
    TILE_COLS: int = _DEFAULT_TILE_COLS,
    DTYPE: str = _DEFAULT_DTYPE,
    ITEMS_PER_LANE: int | None = None,
) -> tuple[torch.Tensor, torch.Tensor]:
    """Allocate tensors, run the kernel, and return ``(out, src)``."""
    if not torch.cuda.is_available():
        raise RuntimeError("CUDA GPU required")

    if ITEMS_PER_LANE is not None:
        TILE_COLS = ITEMS_PER_LANE
    DTYPE = _normalize_dtype(DTYPE)
    cluster_x, cluster_y = _normalize_cluster_shape(CLUSTER_SHAPE)
    TILE_COLS = _normalize_tile_cols(TILE_COLS)
    cluster_ctas = cluster_x * cluster_y
    src = torch.arange(
        cluster_ctas * _ROWS_PER_TILE * TILE_COLS,
        dtype=torch.float32,
        device="cuda",
    ).reshape(cluster_ctas, _ROWS_PER_TILE, TILE_COLS)
    src = (src % 37.0) - 18.0 + float(_PARTIAL_BASE)
    if DTYPE != "i32":
        src = src * 0.5
    torch_dtype = _TORCH_DTYPES[DTYPE]
    src = src.to(torch_dtype).contiguous()
    out = torch.full((_ROWS_PER_TILE, TILE_COLS), -1, dtype=torch_dtype, device="cuda")

    stream = cuda.CUstream(torch.cuda.current_stream().cuda_stream)
    compiled_fn(src, out, stream)
    torch.cuda.synchronize()
    return out, src


def verify(
    CLUSTER_SHAPE: tuple[int, int] = _DEFAULT_CLUSTER_SHAPE,
    TILE_COLS: int = _DEFAULT_TILE_COLS,
    REDUCE_OP: str = _DEFAULT_REDUCE_OP,
    DTYPE: str = _DEFAULT_DTYPE,
    ITEMS_PER_LANE: int | None = None,
) -> None:
    """Compile, run, and compare the cluster reduction with torch."""
    if ITEMS_PER_LANE is not None:
        TILE_COLS = ITEMS_PER_LANE
    cluster_x, cluster_y = _normalize_cluster_shape(CLUSTER_SHAPE)
    TILE_COLS = _normalize_tile_cols(TILE_COLS)
    REDUCE_OP = _normalize_reduce_op(REDUCE_OP)
    DTYPE = _normalize_dtype(DTYPE)

    compiled_fn = compile(
        CLUSTER_SHAPE=(cluster_x, cluster_y),
        TILE_COLS=TILE_COLS,
        REDUCE_OP=REDUCE_OP,
        DTYPE=DTYPE,
    )
    print(
        "Compile kernel "
        f"(cluster_shape={cluster_x}x{cluster_y}, "
        f"TILE_COLS={TILE_COLS}, "
        f"REDUCE_OP={REDUCE_OP}, "
        f"DTYPE={DTYPE}) OK",
        flush=True,
    )

    out, src = run(
        compiled_fn,
        CLUSTER_SHAPE=(cluster_x, cluster_y),
        TILE_COLS=TILE_COLS,
        DTYPE=DTYPE,
    )
    print(
        "Run kernel "
        f"(cluster_shape={cluster_x}x{cluster_y}, "
        f"TILE_COLS={TILE_COLS}, "
        f"REDUCE_OP={REDUCE_OP}, "
        f"DTYPE={DTYPE}) OK",
        flush=True,
    )

    torch.testing.assert_close(out, expected(src, REDUCE_OP=REDUCE_OP), rtol=0, atol=0)
    print(
        f"verify (cluster_shape={cluster_x}x{cluster_y}, "
        f"REDUCE_OP={REDUCE_OP}, DTYPE={DTYPE}): PASS"
    )


def main() -> None:
    """Parse CLI arguments and run verification."""
    parser = argparse.ArgumentParser(
        description="Run the cluster shared-memory DSMEM reduction example.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument(
        "--cluster-shape",
        dest="CLUSTER_SHAPE",
        type=_parse_cluster_shape,
        default=_DEFAULT_CLUSTER_SHAPE,
        help="Compile-time cluster shape tuple written as x,y",
    )
    parser.add_argument(
        "--tile-cols",
        "--items-per-lane",
        dest="TILE_COLS",
        type=int,
        default=_DEFAULT_TILE_COLS,
        choices=(1, 2, 4, 8),
        help="Compile-time tile columns reduced per CTA",
    )
    parser.add_argument(
        "--reduce-op",
        dest="REDUCE_OP",
        default=_DEFAULT_REDUCE_OP,
        choices=REDUCE_OPS,
        help="Compile-time reduction operator",
    )
    parser.add_argument(
        "--dtype",
        dest="DTYPE",
        default=_DEFAULT_DTYPE,
        choices=DTYPES,
        help="Compile-time element dtype",
    )
    args = parser.parse_args()
    verify(
        CLUSTER_SHAPE=args.CLUSTER_SHAPE,
        TILE_COLS=args.TILE_COLS,
        REDUCE_OP=args.REDUCE_OP,
        DTYPE=args.DTYPE,
    )


if __name__ == "__main__":
    main()
