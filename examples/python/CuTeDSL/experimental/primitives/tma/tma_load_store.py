# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:

# 1. Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.

# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.

# 3. Neither the name of the copyright holder nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.

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
TMA load → shared-memory byte-copy → TMA store, parametrised over TMA descriptor cases.

Extends ``tma_store.py`` to exercise every dtype path TMA cares about.
The compute is intentionally trivial — a byte-granular identity copy in
shared memory — so ordinary and compact descriptor cases are bit-exact over
random bytes. Padded sub-byte formats use a zero payload because the TMA path
expands/canonicalizes the packed global representation. The point of the
example is the **descriptor matrix**, not the shared-memory compute:

* **Same bit-width, different element type** — fp16 vs bf16.  TMA's
  ``tma_format`` tag is element-type specific; even though the storage
  bytes are identical, the descriptor cannot be reused across these
  types.

* **Cross-width identity** — uint8, fp16, bf16, fp32, int32.  Smoke
  tests that ``global_strides = K_elem * width // 128`` works for
  1 / 2 / 4-byte elements.

* **Packed narrow dtypes** — ``Float4E2M1FNx2`` (2 elements per byte,
  default ``TensorMapDataFormat.B4X16`` compact layout for this byte-wise
  identity example).

  The example matrix also covers ``Float6E3M2FNx4`` (4 elements per
  3 bytes, using ``TensorMapDataFormat.B6X16_P32``).

  The single load-bearing distinction for packed types is the way
  ``global_dims`` and the storage byte count diverge.  For an FP4 row
  of ``K`` *elements*::

      global_dims[K] = K           # element count, regardless of packing
      global_strides[0] = K * 4 // 128
                         #  ^   ^   ^^^
                         #  K   width  16 (16-byte unit) * 8 (bits/byte)
                         #     in     # = K // 32 for FP4
                         #     bits
      torch buffer:   (M, K * width // 8) uint8 storage

  This matches the existing raw-args contract on
  ``create_tensor_map_tiled``.  The host path in this example always
  launches on ``uint8`` byte buffers; the logical dtype only affects the
  descriptor format and bit-width math.

Requires SM90+ for TMA; FP4 paths require SM100+.

FP6 paths require SM100+.

To run::

    python CuTeDSL/experimental/primitives/tma/tma_load_store.py
    python CuTeDSL/experimental/primitives/tma/tma_load_store.py --src_dtype float32 --dst_dtype float32
    python CuTeDSL/experimental/primitives/tma/tma_load_store.py --src_dtype float4_e2m1fn_x2 --dst_dtype float4_e2m1fn_x2 --src_format b4x16 --dst_format b4x16
    python CuTeDSL/experimental/primitives/tma/tma_load_store.py --src_dtype float6_e3m2fn_x4 --dst_dtype float6_e3m2fn_x4 --src_format b6x16_p32 --dst_format b6x16_p32

"""

from __future__ import annotations

import argparse
from functools import lru_cache
from typing import Callable, Type

import torch


import cutlass
import cutlass.experimental.cuda as cuda
from cutlass import Numeric
import cutlass.cute as cute
from cutlass.cute.runtime import make_fake_compact_tensor
from cutlass.experimental import primitives as prims


# ---------------------------------------------------------------------------
# Tile geometry.  Element extents are fixed across all descriptor cases;
# byte counts derive from the selected TMA format's element bit width.
# ---------------------------------------------------------------------------
TILE_M = 64  # rows per thread block (element count, dtype-agnostic).  Capped at
# 64 so the largest-element case (fp32 / int32, 4 B/elem)
# fits in shared memory: 2 * 64 * 256 * 4 = 128 KB.
TILE_K = 256  # cols per thread block (element count).
# Padded sub-byte formats such as B4X16_P64 require a fixed 64B first box
# dimension and expand in shared memory, so this single-box byte-identity
# example defaults FP4 to the compact B4X16 layout.
_THREADS = 128


# ---------------------------------------------------------------------------
# Registries for CLI / tests.
# ---------------------------------------------------------------------------

_DTYPE_REGISTRY: dict[str, type] = {
    "uint8": cutlass.Uint8,
    "float16": cutlass.Float16,
    "bfloat16": cutlass.BFloat16,
    "float32": cutlass.Float32,
    "int32": cutlass.Int32,
    "float8_e4m3fn": cutlass.Float8E4M3FN,
    "float4_e2m1fn_x2": cutlass.Float4E2M1FNx2,
    "float6_e3m2fn_x4": cutlass.Float6E3M2FNx4,
}


def _default_tma_format(dtype: type) -> cuda.TensorMapDataFormat:
    """Map the example's logical dtype cases onto public TMA formats."""

    if dtype in {cutlass.Uint8, cutlass.Float8E4M3FN}:
        return cuda.TensorMapDataFormat.BYTE
    if dtype is cutlass.Float4E2M1FNx2:
        return cuda.TensorMapDataFormat.B4X16
    if dtype is cutlass.Float6E3M2FNx4:
        return cuda.TensorMapDataFormat.B6X16_P32
    return cuda.TensorMapDataFormat.DEFAULT


def _resolve_dtype(dtype_name: str) -> type:
    try:
        return _DTYPE_REGISTRY[dtype_name]
    except KeyError as exc:
        valid = ", ".join(sorted(_DTYPE_REGISTRY))
        raise ValueError(
            f"Unsupported dtype {dtype_name!r}. Expected one of: {valid}"
        ) from exc


def _resolve_format(format_name: str | None) -> cuda.TensorMapDataFormat | None:
    if format_name is None:
        return None
    try:
        return cuda.TensorMapDataFormat[format_name.upper()]
    except KeyError as exc:
        valid = ", ".join(sorted(str(fmt) for fmt in cuda.TensorMapDataFormat))
        raise ValueError(
            f"Unsupported TensorMap format {format_name!r}. Expected one of: {valid}"
        ) from exc


# ---------------------------------------------------------------------------
# Per-dtype byte geometry.
# ---------------------------------------------------------------------------


def _format_bit_width(
    dtype: Type[Numeric],
    tma_format: cuda.TensorMapDataFormat,
) -> int:
    """Return the element bit width represented by the TensorMap format."""

    if tma_format in {
        cuda.TensorMapDataFormat.B4X16,
        cuda.TensorMapDataFormat.B4X16_P64,
    }:
        return 4
    if tma_format is cuda.TensorMapDataFormat.B6X16_P32:
        return 6
    if tma_format is cuda.TensorMapDataFormat.BYTE:
        return 8
    return dtype.width


def _shared_storage_bit_width(
    dtype: Type[Numeric],
    tma_format: cuda.TensorMapDataFormat,
) -> int:
    """Return the per-element width of the TMA shared-memory layout."""
    if tma_format in {
        cuda.TensorMapDataFormat.BYTE,
        cuda.TensorMapDataFormat.B4X16_P64,
    }:
        return 8
    if tma_format is cuda.TensorMapDataFormat.B6X16_P32:
        return 8
    if tma_format is cuda.TensorMapDataFormat.B4X16:
        return 4
    return dtype.width


def _k_elements_for_format(tma_format: cuda.TensorMapDataFormat) -> int:
    """Return the TMA box K extent for this format."""
    if tma_format is cuda.TensorMapDataFormat.B4X16_P64:
        # PTX requires Box-Size[0] == 64B for B4X16_P64: 128 scalar FP4 lanes * 4 bits = 512 bits = 64 bytes.
        return 128
    if tma_format is cuda.TensorMapDataFormat.B6X16_P32:
        # PTX requires Box-Size[0] == 96B for B6X16_P32:
        # 128 scalar FP6 lanes * 6 bits = 768 bits = 96 bytes.
        return 128
    return TILE_K


def _row_bytes(element_bits: int, case_name: str, k_elem: int) -> int:
    """Byte count of one row of logical TMA elements.

    ``element_bits`` comes from the selected TensorMap format. This matters for
    packed storage dtypes such as ``Float4E2M1FNx2``: the dtype container is
    8 bits, while the ``B4X16`` TensorMap format represents 4-bit elements.
    """
    bits = element_bits * k_elem
    assert bits % 8 == 0, (
        f"{case_name}: K={k_elem} * {element_bits}-bit elements "
        f"does not divide into whole bytes — adjust TILE_K."
    )
    return bits // 8


def _tile_bytes(row_bytes: int) -> int:
    return TILE_M * row_bytes


# ---------------------------------------------------------------------------
# Device kernel — byte-granular identity copy across all dtypes.  The
# dtype-specific descriptors and byte geometry are built on the host.
# ---------------------------------------------------------------------------


@cute.kernel
def identity_kernel(
    tma_src_desc: cutlass.GridConstant[cuda.TensorMap],
    tma_dst_desc: cutlass.GridConstant[cuda.TensorMap],
    coord_m: cutlass.Int32,
    coord_k: cutlass.Int32,
    SHARED_BYTES: cutlass.Constexpr[int],
) -> None:
    smem_in = cutlass.Array(
        cutlass.Uint8, SHARED_BYTES, space=cutlass.AddressSpace.smem, alignment=128
    )
    smem_out = cutlass.Array(
        cutlass.Uint8, SHARED_BYTES, space=cutlass.AddressSpace.smem, alignment=128
    )
    full_bar = cutlass.Array(
        cutlass.Int64, 1, space=cutlass.AddressSpace.smem, alignment=8
    )

    warp_idx = cute.arch.warp_idx()
    tidx, _, _ = cute.arch.thread_idx()

    if warp_idx == 0:
        if prims.elect_sync():
            prims.mbarrier_init(full_bar, 1)
    prims.fence_mbarrier_init()
    prims.barrier_cta_sync(0)

    src_ptr = tma_src_desc.get_ptr()
    if warp_idx == 0:
        if prims.elect_sync():
            prims.mbarrier_arrive_expect_tx(full_bar, tma_src_desc.global_tx_bytes())
        if prims.elect_sync():
            prims.cp_async_bulk_tensor_shared_cta_global(
                smem_in,
                src_ptr,
                (coord_k, coord_m),
                full_bar,
            )
    while not prims.mbarrier_try_wait_parity(full_bar, 0):
        pass
    prims.barrier_cta_sync(0)

    # Byte-wise identity copy across all 128 threads.
    bytes_per_thread = SHARED_BYTES // _THREADS
    smem_in_ptr = smem_in.data_ptr()
    smem_out_ptr = smem_out.data_ptr()
    for i in cutlass.range_constexpr(bytes_per_thread):
        idx = tidx * bytes_per_thread + i
        b = (smem_in_ptr + idx).load()
        (smem_out_ptr + idx).store(b)

    prims.barrier_cta_sync(0)
    dst_ptr = tma_dst_desc.get_ptr()
    prims.fence_proxy(prims.Proxy.ASYNC_SHARED, space=prims.SharedSpace.shared_cta)
    if prims.elect_sync():
        prims.cp_async_bulk_tensor_global_shared_cta(
            dst_ptr,
            smem_out,
            (coord_k, coord_m),
        )
    prims.cp_async_bulk_commit_group()
    prims.cp_async_bulk_wait_group(0)


# ---------------------------------------------------------------------------
# Host — builds the per-dtype descriptors and launches.  ``K_elem`` and
# ``row_bytes`` flow in as Constexprs so the host computes the right
# global_dims (in elements) and global_strides (16-byte units) for the
# specific dtype.
# ---------------------------------------------------------------------------


def make_host(
    src_dtype: Type[Numeric],
    dst_dtype: Type[Numeric],
    src_format_value: int,
    dst_format_value: int,
) -> Callable:
    """Build a dtype-specialized host launcher without dtype runtime args."""

    @cute.jit
    def host(
        src: cute.Tensor,
        dst: cute.Tensor,
        SRC_K_ELEM: cutlass.Constexpr[int],
        DST_K_ELEM: cutlass.Constexpr[int],
        ROW_BYTES: cutlass.Constexpr[int],
        SHARED_BYTES: cutlass.Constexpr[int],
    ) -> None:
        """Build src / dst TMA descriptors and launch the identity kernel.

        Both ``src`` and ``dst`` flow in as ``uint8`` byte tensors (shape
        ``(M, row_bytes)``) so the example can size the descriptors
        uniformly.  The logical element interpretation lives in
        ``src_dtype`` / ``dst_dtype``; ``tma_format`` selects the consumer-
        facing transfer layout when it differs from the default for that
        dtype.
        """
        # global_strides in 16-byte units: (row_bytes) // 16.
        # Equivalent to ``k_elem * width // 128`` per the raw-API doc.
        stride_16b = ROW_BYTES // 16
        tma_src_desc = cuda.create_tensor_map_tiled(
            global_address=src.iterator.toint(),
            dtype=src_dtype,
            tma_format=cuda.TensorMapDataFormat(src_format_value),
            global_dims=[SRC_K_ELEM, src.shape[0]],
            global_strides=[stride_16b],
            box_dims=[SRC_K_ELEM, TILE_M],
            swizzle=cuda.TensorMapSwizzle.none,
        )
        tma_dst_desc = cuda.create_tensor_map_tiled(
            global_address=dst.iterator.toint(),
            dtype=dst_dtype,
            tma_format=cuda.TensorMapDataFormat(dst_format_value),
            global_dims=[DST_K_ELEM, dst.shape[0]],
            global_strides=[stride_16b],
            box_dims=[DST_K_ELEM, TILE_M],
            swizzle=cuda.TensorMapSwizzle.none,
        )
        identity_kernel(tma_src_desc, tma_dst_desc, 0, 0, SHARED_BYTES).launch(
            grid=(1, 1, 1), block=(_THREADS, 1, 1)
        )

    return host


@lru_cache(maxsize=None)
def compile_for(
    src_k_elem: int,
    dst_k_elem: int,
    row_bytes: int,
    src_dtype: Type[Numeric],
    dst_dtype: Type[Numeric],
    src_format_value: int,
    dst_format_value: int,
    shared_bytes: int,
) -> Callable:
    sym_m = cute.sym_int64()
    sym_k_byte = cute.sym_int64(divisibility=16)
    fake_src = make_fake_compact_tensor(
        cutlass.Uint8, (sym_m, sym_k_byte), stride_order=(1, 0), assumed_align=16
    )
    fake_dst = make_fake_compact_tensor(
        cutlass.Uint8, (sym_m, sym_k_byte), stride_order=(1, 0), assumed_align=16
    )
    host = make_host(src_dtype, dst_dtype, src_format_value, dst_format_value)
    return cute.compile(
        host,
        fake_src,
        fake_dst,
        src_k_elem,
        dst_k_elem,
        row_bytes,
        shared_bytes,
        options="--enable-tvm-ffi",
    )


def _run_case(
    *,
    name: str,
    src_dtype: Type[Numeric],
    dst_dtype: Type[Numeric],
    src_format: cuda.TensorMapDataFormat | None = None,
    dst_format: cuda.TensorMapDataFormat | None = None,
) -> None:
    src_format = src_format or _default_tma_format(src_dtype)
    dst_format = dst_format or _default_tma_format(dst_dtype)
    src_element_bits = _format_bit_width(src_dtype, src_format)
    dst_element_bits = _format_bit_width(dst_dtype, dst_format)

    if src_element_bits != dst_element_bits:
        raise ValueError(
            "tma_load_store only supports source/destination TensorMap formats "
            f"with the same bit width, got {src_dtype.__name__}/"
            f"{src_format.name} ({src_element_bits}) -> {dst_dtype.__name__}/"
            f"{dst_format.name} ({dst_element_bits})"
        )

    src_k_elem = _k_elements_for_format(src_format)
    dst_k_elem = _k_elements_for_format(dst_format)
    if src_k_elem != dst_k_elem:
        raise ValueError(
            "tma_load_store only supports source/destination TensorMap formats "
            f"with matching K extents, got {src_format.name} ({src_k_elem}) -> "
            f"{dst_format.name} ({dst_k_elem})"
        )
    row_bytes = _row_bytes(src_element_bits, name, src_k_elem)
    tx_bytes = _tile_bytes(row_bytes)

    src_shared_element_bits = _shared_storage_bit_width(src_dtype, src_format)
    dst_shared_element_bits = _shared_storage_bit_width(dst_dtype, dst_format)
    src_shared_row_bytes = _row_bytes(src_shared_element_bits, name, src_k_elem)
    dst_shared_row_bytes = _row_bytes(dst_shared_element_bits, name, dst_k_elem)
    if src_shared_row_bytes != dst_shared_row_bytes:
        raise ValueError(
            "tma_load_store only supports source/destination TensorMap formats "
            "with matching shared-memory storage bytes, got "
            f"{src_format.name} ({src_shared_row_bytes}) -> "
            f"{dst_format.name} ({dst_shared_row_bytes})"
        )
    shared_bytes = _tile_bytes(src_shared_row_bytes)

    compiled = compile_for(
        src_k_elem,
        dst_k_elem,
        row_bytes,
        src_dtype,
        dst_dtype,
        src_format.value,
        dst_format.value,
        shared_bytes,
    )

    # Allocate src / dst as ``uint8`` byte buffers of shape (M, row_bytes).
    # Random bytes are fine for raw-byte and compact cases. Padded sub-byte
    # formats expand into a larger shared-memory representation, so use zero
    # bytes: zeros are stable under the packed global ↔ expanded shared TMA
    # conversion and still exercise descriptor encoding plus load/store.
    if shared_bytes == tx_bytes:
        src_bytes = torch.randint(
            0, 256, (TILE_M, row_bytes), dtype=torch.uint8, device="cuda"
        )
    else:
        src_bytes = torch.zeros((TILE_M, row_bytes), dtype=torch.uint8, device="cuda")
    dst_bytes = torch.zeros_like(src_bytes)
    compiled(src_bytes, dst_bytes)
    torch.cuda.synchronize()
    torch.testing.assert_close(dst_bytes, src_bytes, atol=0, rtol=0)
    print(
        f"PASS  {name:30s}  "
        f"src={src_dtype.__name__} ({src_format.name})  "
        f"dst={dst_dtype.__name__} ({dst_format.name})  "
        f"src_k_elem={src_k_elem} dst_k_elem={dst_k_elem} "
        f"row_bytes={row_bytes} tx_bytes={tx_bytes} shared_bytes={shared_bytes}"
    )


def run(
    src_dtype: str = "float16",
    dst_dtype: str = "bfloat16",
    src_format: str | None = None,
    dst_format: str | None = None,
) -> None:
    if not torch.cuda.is_available():
        raise RuntimeError("CUDA GPU required")
    src_dtype_value = _resolve_dtype(src_dtype)
    dst_dtype_value = _resolve_dtype(dst_dtype)
    _run_case(
        name=f"{src_dtype}_to_{dst_dtype}",
        src_dtype=src_dtype_value,
        dst_dtype=dst_dtype_value,
        src_format=_resolve_format(src_format),
        dst_format=_resolve_format(dst_format),
    )
    print("\nTMA load/store case passed.")


def verify(
    src_dtype: str = "float16",
    dst_dtype: str = "bfloat16",
    src_format: str | None = None,
    dst_format: str | None = None,
) -> None:
    """Pytest-friendly alias for the parametrized TMA load/store case."""
    run(
        src_dtype=src_dtype,
        dst_dtype=dst_dtype,
        src_format=src_format,
        dst_format=dst_format,
    )


def _build_arg_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--src_dtype",
        default="float16",
        choices=sorted(_DTYPE_REGISTRY),
        help="Logical source dtype for descriptor construction.",
    )
    parser.add_argument(
        "--dst_dtype",
        default="bfloat16",
        choices=sorted(_DTYPE_REGISTRY),
        help="Logical destination dtype for descriptor construction.",
    )
    parser.add_argument(
        "--src_format",
        help="Optional TensorMapDataFormat override for the source descriptor.",
    )
    parser.add_argument(
        "--dst_format",
        help="Optional TensorMapDataFormat override for the destination descriptor.",
    )
    return parser


if __name__ == "__main__":
    args = _build_arg_parser().parse_args()
    verify(
        src_dtype=args.src_dtype,
        dst_dtype=args.dst_dtype,
        src_format=args.src_format,
        dst_format=args.dst_format,
    )
