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

"""Single-CTA block-scaled MMA with narrow A copied to TMEM by ``tcgen05_cp``.

This example isolates the ``tcgen05.mma.kind::mxf8f6f4.block_scale`` path where
operand A is supplied from TMEM instead of an SMEM descriptor.  The narrow A
payload starts in packed GMEM storage:

  - ``fp4``: two ``Float4E2M1FN`` values per byte.
  - ``fp6``: four ``Float6E3M2FN`` values per three bytes.

Each CTA TMA-loads the host-provided packed A bytes, B tile, and E8M0 scale
factor tiles into SMEM.  A's TensorMap uses the padded ``B4X16_P64`` or
``B6X16_P32`` TMA format, and the MMA warp issues UTCCP with the matching
``.b4x16_p64`` or ``.b6x16_p32`` source format to place every narrow value in
the middle of its 8-bit TMEM holder.  The kernel then issues the four K-block
block-scaled MMA operations for a normal 128x128x128 CTA tile and compares the result with a
deterministic all-ones reference.  The middle-bit holder layout is the behavior
under test:

  - FP4 UTCCP holder byte: ``00xxxx00`` (payload bits [5:2]).
  - FP6 UTCCP holder byte: ``0xxxxxx0`` (payload bits [6:1]).

The kernel intentionally stays simple: one CTA, four warps, one TMA load group
for A/B/SFA/SFB, host-generated E8M0 scale factors moved to TMEM with UTCCP, A
moved to TMEM with UTCCP in the MMA warp, no warp specialization, and one
single-stage K-block loop.

Public API::

    compile(a_dtype="fp4")   -> AOT-compile factory
    run(compiled_fn, a_dtype="fp4")
    verify(a_dtype="fp4")   -> compile + run + assert vs deterministic reference

To run::

    python CuTeDSL/experimental/primitives/tcgen05/cp_narrow_a_to_tmem_mma.py --a-dtype fp4
    python CuTeDSL/experimental/primitives/tcgen05/cp_narrow_a_to_tmem_mma.py --a-dtype fp6
    python CuTeDSL/experimental/primitives/tcgen05/cp_narrow_a_to_tmem_mma.py --a-dtype all

"""

from __future__ import annotations

import argparse
import sys
from functools import lru_cache
from typing import Callable, Literal

import torch


import cutlass
import cutlass.experimental.cuda as cuda
import cutlass.cute as cute
from cutlass.cute.runtime import make_fake_compact_tensor
from cutlass.experimental import primitives as prims


AType = Literal["fp4", "fp6"]

_M_TILE = 128
_N_TILE = 128
_K_TILE = 128
_THREADS = 128

_A_DTYPE_FP4 = 4
_A_DTYPE_FP6 = 6
_A_DTYPE_TO_ID: dict[AType, int] = {"fp4": _A_DTYPE_FP4, "fp6": _A_DTYPE_FP6}

_FP4_A_ROW_BYTES = _K_TILE // 2
_FP6_A_ROW_BYTES = _K_TILE * 3 // 4
_A_PADDED_ROW_BYTES = _K_TILE
_A_PADDED_BYTES = _M_TILE * _A_PADDED_ROW_BYTES
_A_UTCCP_KBLOCK_BYTES = 32
_A_TMEM_COLS = 32
_SF_TMEM_COLS = 4
_SF_BYTES = 512

_D_TMEM_COL = 0
_A_TMEM_COL = _N_TILE
_SFA_TMEM_COL = _A_TMEM_COL + _A_TMEM_COLS
_SFB_TMEM_COL = _SFA_TMEM_COL + _SF_TMEM_COLS
_TMEM_COLS = 256

_FP4_E2M1_ONE = 0x2
# Packed-GMEM E3M2 code that UTCCP expands into the 8-bit holder byte for 1.0.
_FP6_E3M2_ONE = 0x0C
_E8M0_ONE = 0x7F


def _check_sm100() -> bool:
    if not torch.cuda.is_available():
        return False
    cap = torch.cuda.get_device_capability()
    return cap == (10, 0)


def _normalize_a_dtype(a_dtype: str) -> AType:
    if a_dtype == "fp4" or a_dtype == "fp6":
        return a_dtype
    raise ValueError(f"a_dtype must be 'fp4' or 'fp6' (got {a_dtype!r})")


def _a_row_bytes(a_dtype: AType) -> int:
    if a_dtype == "fp4":
        return _FP4_A_ROW_BYTES
    return _FP6_A_ROW_BYTES


@cute.kernel
def kernel(
    tma_a_desc: cutlass.GridConstant[cuda.TensorMap],
    tma_b_desc: cutlass.GridConstant[cuda.TensorMap],
    tma_sfa_desc: cutlass.GridConstant[cuda.TensorMap],
    tma_sfb_desc: cutlass.GridConstant[cuda.TensorMap],
    c_ptr: cute.Tensor,
    A_DTYPE_ID: cutlass.Constexpr[int],
) -> None:
    """Run one 128x128x128 ``mxf8f6f4.block_scale`` tile."""
    if cutlass.const_expr(A_DTYPE_ID == _A_DTYPE_FP4):
        a_dtype: cutlass.Constexpr = cutlass.Float4E2M1FN
        a_src_format: cutlass.Constexpr = prims.Tcgen05CpSrcFormat.B4X16_P64
    else:
        a_dtype: cutlass.Constexpr = cutlass.Float6E3M2FN
        a_src_format: cutlass.Constexpr = prims.Tcgen05CpSrcFormat.B6X16_P32

    smem_a = cutlass.Array(
        cutlass.Int8,
        _A_PADDED_BYTES,
        space=cutlass.AddressSpace.smem,
        alignment=128,
    )
    smem_b = cutlass.Array(
        cutlass.Float8E4M3FN,
        _N_TILE * _K_TILE,
        space=cutlass.AddressSpace.smem,
        alignment=128,
    )
    smem_sfa = cutlass.Array(
        cutlass.Int8, _SF_BYTES, space=cutlass.AddressSpace.smem, alignment=128
    )
    smem_sfb = cutlass.Array(
        cutlass.Int8, _SF_BYTES, space=cutlass.AddressSpace.smem, alignment=128
    )
    full_mbar = cutlass.Array(
        cutlass.Int64, 1, space=cutlass.AddressSpace.smem, alignment=8
    )
    acc_mbar = cutlass.Array(
        cutlass.Int64, 1, space=cutlass.AddressSpace.smem, alignment=8
    )
    tmem_ptr_i32 = cutlass.Array(
        cutlass.Int32, 1, space=cutlass.AddressSpace.smem, alignment=4
    )

    warp_idx = cute.arch.warp_idx()
    tidx, _, _ = cute.arch.thread_idx()
    lane = tidx % cutlass.Int32(32)

    b_smem_swizzle: cutlass.Constexpr = tma_b_desc.swizzle.to(prims.Tcgen05SmemSwizzle)

    idesc = prims.Tcgen05MxInstrDesc.build(
        a_dtype=a_dtype,
        b_dtype=cutlass.Float8E4M3FN,
        scale_format=1,
        n_dim=_N_TILE,
        m_dim=_M_TILE,
    )

    if warp_idx == 0:
        if prims.elect_sync():
            prims.mbarrier_init(full_mbar, 1)
            prims.mbarrier_init(acc_mbar, 1)
    prims.fence_mbarrier_init()
    prims.barrier_cta_sync(0)

    if warp_idx == 0:
        prims.tcgen05_alloc(tmem_ptr_i32, _TMEM_COLS, group="cta_1")
    prims.barrier_cta_sync(0)

    tmem_raw = tmem_ptr_i32.load()
    prims.tcgen05_relinquish_alloc_permit(group="cta_1")

    # Single-stage GMEM -> SMEM TMA load group. A's TensorMap expands compact
    # GMEM FP4/FP6 into padded 16-byte chunks in SMEM for UTCCP decompression.
    if warp_idx == 0:
        if prims.elect_sync():
            tma_bytes = (
                tma_a_desc.global_tx_bytes()
                + tma_b_desc.global_tx_bytes()
                + tma_sfa_desc.global_tx_bytes()
                + tma_sfb_desc.global_tx_bytes()
            )
            prims.mbarrier_arrive_expect_tx(full_mbar, tma_bytes)
            prims.cp_async_bulk_tensor_shared_cta_global(
                smem_a,
                tma_a_desc.get_ptr(),
                (cutlass.Int32(0), cutlass.Int32(0)),
                full_mbar,
            )
            prims.cp_async_bulk_tensor_shared_cta_global(
                smem_b,
                tma_b_desc.get_ptr(),
                (cutlass.Int32(0), cutlass.Int32(0)),
                full_mbar,
            )
            prims.cp_async_bulk_tensor_shared_cta_global(
                smem_sfa,
                tma_sfa_desc.get_ptr(),
                (
                    cutlass.Int32(0),
                    cutlass.Int32(0),
                    cutlass.Int32(0),
                    cutlass.Int32(0),
                ),
                full_mbar,
            )
            prims.cp_async_bulk_tensor_shared_cta_global(
                smem_sfb,
                tma_sfb_desc.get_ptr(),
                (
                    cutlass.Int32(0),
                    cutlass.Int32(0),
                    cutlass.Int32(0),
                    cutlass.Int32(0),
                ),
                full_mbar,
            )

    while not prims.mbarrier_try_wait_parity(
        full_mbar, cutlass.Int32(0), time_limit=10_000_000
    ):
        pass
    prims.barrier_cta_sync(0)

    base_col = tmem_raw & cutlass.Int32(0xFFFF)
    base_row = tmem_raw >> cutlass.Int32(16)
    warp_row = base_row + warp_idx * cutlass.Int32(32)
    m_row = warp_idx * cutlass.Int32(32) + lane

    if warp_idx == 0:
        a_s2t_shape, a_s2t_multicast = prims.S2TCopyMode.S2T_128x256b
        sf_s2t_shape, sf_s2t_multicast = prims.S2TCopyMode.S2T_32x128b_WARPX4
        desc_a = prims.Tcgen05SmemDesc.build(
            smem_a,
            leading_byte_offset=16,
            stride_byte_offset=8 * _A_PADDED_ROW_BYTES,
            layout=0,
        )
        desc_sfa = prims.Tcgen05SmemDesc.build(
            smem_sfa,
            leading_byte_offset=16,
            stride_byte_offset=128,
            layout=0,
        )
        desc_sfb = prims.Tcgen05SmemDesc.build(
            smem_sfb,
            leading_byte_offset=16,
            stride_byte_offset=128,
            layout=0,
        )
        desc_b = prims.Tcgen05SmemDesc.build(
            smem_b,
            leading_byte_offset=16,
            stride_byte_offset=8 * _K_TILE,
            layout=b_smem_swizzle,
        )
        d_tmem = cutlass.inttoptr(
            (base_row << cutlass.Int32(16)) | (base_col + cutlass.Int32(_D_TMEM_COL)),
            6,
            cutlass.Float32,
        )
        sfa_tmem = cutlass.inttoptr(
            (base_row << cutlass.Int32(16)) | (base_col + cutlass.Int32(_SFA_TMEM_COL)),
            6,
            cutlass.Int32,
        )
        sfb_tmem = cutlass.inttoptr(
            (base_row << cutlass.Int32(16)) | (base_col + cutlass.Int32(_SFB_TMEM_COL)),
            6,
            cutlass.Int32,
        )
        if prims.elect_sync():
            for kblock in cutlass.range_constexpr(4):
                a_tmem_k = cutlass.inttoptr(
                    (base_row << cutlass.Int32(16))
                    | (base_col + cutlass.Int32(_A_TMEM_COL + kblock * 8)),
                    6,
                    cutlass.Int32,
                )
                desc_a_k = desc_a.advance_start_address(kblock * _A_UTCCP_KBLOCK_BYTES)
                prims.tcgen05_cp(
                    a_s2t_shape,
                    a_tmem_k,
                    desc_a_k,
                    multicast=a_s2t_multicast,
                    src_format=a_src_format,
                )
            prims.tcgen05_cp(
                sf_s2t_shape,
                sfa_tmem,
                desc_sfa,
                multicast=sf_s2t_multicast,
            )
            prims.tcgen05_cp(
                sf_s2t_shape,
                sfb_tmem,
                desc_sfb,
                multicast=sf_s2t_multicast,
            )
        if prims.elect_sync():
            for kblock in cutlass.range_constexpr(4):
                idesc_k = idesc.set_sf_ids(a_sf_id=kblock, b_sf_id=kblock)
                a_tmem_k = cutlass.inttoptr(
                    (base_row << cutlass.Int32(16))
                    | (base_col + cutlass.Int32(_A_TMEM_COL + kblock * 8)),
                    6,
                    cutlass.Int32,
                )
                desc_b_k = desc_b.advance_start_address(kblock * 32)
                prims.tcgen05_mma_block_scale(
                    prims.MMABlockScaleKind.MXF8F6F4,
                    prims.CTAGroup.CTA_1,
                    d_tmem,
                    a_tmem_k,
                    desc_b_k,
                    idesc_k,
                    kblock > 0,
                    sfa_tmem,
                    sfb_tmem,
                )
        if prims.elect_sync():
            prims.tcgen05_commit(acc_mbar, group=prims.CTAGroup.CTA_1)

    prims.barrier_cta_sync(0)
    while not prims.mbarrier_try_wait_parity(
        acc_mbar, cutlass.Int32(0), time_limit=10_000_000
    ):
        pass

    for sub in cutlass.range_constexpr(_N_TILE // 32):
        c_tmem = cutlass.inttoptr(
            (warp_row << cutlass.Int32(16))
            | (base_col + cutlass.Int32(_D_TMEM_COL + sub * 32)),
            6,
            cutlass.Float32,
        )
        c_vec = prims.tcgen05_ld(prims.Tcgen05LdStShape.SHAPE_32X32B, c_tmem, num=32)
        prims.tcgen05_wait("load")
        (
            c_ptr.iterator.raw_ptr() + m_row * c_ptr.shape[1] + cutlass.Int32(sub * 32)
        ).store(c_vec, alignment=16)

    prims.tcgen05_fence(prims.Tcgen05Fence.BEFORE_THREAD_SYNC)
    prims.barrier_cta_sync(0)
    if warp_idx == 0:
        prims.tcgen05_dealloc(
            cutlass.inttoptr(tmem_raw, 6, cutlass.Int8),
            _TMEM_COLS,
            group="cta_1",
        )


@cute.jit
def host(
    a_packed: cute.Tensor,
    b: cute.Tensor,
    sfa: cute.Tensor,
    sfb: cute.Tensor,
    c: cute.Tensor,
    A_DTYPE_ID: cutlass.Constexpr[int],
) -> None:
    if cutlass.const_expr(A_DTYPE_ID == _A_DTYPE_FP4):
        a_row_bytes: cutlass.Constexpr[int] = _FP4_A_ROW_BYTES
        a_tma_dtype: cutlass.Constexpr = cutlass.Float4E2M1FN
    else:
        a_row_bytes: cutlass.Constexpr[int] = _FP6_A_ROW_BYTES
        a_tma_dtype: cutlass.Constexpr = cutlass.Float6E3M2FN

    tma_a = cuda.create_tensor_map_tiled(
        a_packed.iterator.toint(),
        a_tma_dtype,
        global_dims=[_K_TILE, a_packed.shape[0]],
        global_strides=[a_row_bytes // 16],
        box_dims=[_K_TILE, _M_TILE],
        swizzle=cuda.TensorMapSwizzle.none,
    )
    tma_b = cuda.create_tensor_map_tiled(
        b.iterator.toint(),
        b.element_type,
        global_dims=[b.shape[1], b.shape[0]],
        global_strides=[b.shape[1] // 16],
        box_dims=[_K_TILE, _N_TILE],
        swizzle=cuda.TensorMapSwizzle.s128b,
    )
    sfa_tma_order = cute.make_tensor(
        sfa.iterator,
        cute.select(sfa.layout, mode=[3, 2, 1, 0]),
    )
    sfb_tma_order = cute.make_tensor(
        sfb.iterator,
        cute.select(sfb.layout, mode=[3, 2, 1, 0]),
    )
    sfa_u16 = cute.recast_tensor(sfa_tma_order, cutlass.Uint16)
    sfb_u16 = cute.recast_tensor(sfb_tma_order, cutlass.Uint16)
    tma_sfa = cuda.create_tensor_map_tiled_from_view(
        sfa_u16,
        box_dims=(_SF_BYTES // 2, 1, 1, 1),
        stride_order=(0, 1, 2, 3),
        swizzle=cuda.TensorMapSwizzle.none,
    )
    tma_sfb = cuda.create_tensor_map_tiled_from_view(
        sfb_u16,
        box_dims=(_SF_BYTES // 2, 1, 1, 1),
        stride_order=(0, 1, 2, 3),
        swizzle=cuda.TensorMapSwizzle.none,
    )
    kernel(tma_a, tma_b, tma_sfa, tma_sfb, c, A_DTYPE_ID).launch(
        grid=(1, 1, 1),
        block=(_THREADS, 1, 1),
    )


@lru_cache(maxsize=None)
def compile(a_dtype: str = "fp4") -> Callable:  # noqa: A001
    a_kind = _normalize_a_dtype(a_dtype)
    fake_a = make_fake_compact_tensor(
        cutlass.Uint8,
        (_M_TILE, _a_row_bytes(a_kind)),
        stride_order=(1, 0),
        assumed_align=16,
    )
    fake_b = make_fake_compact_tensor(
        cutlass.Float8E4M3FN,
        (_N_TILE, _K_TILE),
        stride_order=(1, 0),
        assumed_align=16,
    )
    fake_sfa = make_fake_compact_tensor(
        cutlass.Uint8,
        (1, 1, 1, _SF_BYTES),
        stride_order=(3, 2, 1, 0),
        assumed_align=16,
    )
    fake_sfb = make_fake_compact_tensor(
        cutlass.Uint8,
        (1, 1, 1, _SF_BYTES),
        stride_order=(3, 2, 1, 0),
        assumed_align=16,
    )
    fake_c = make_fake_compact_tensor(
        cutlass.Float32,
        (_M_TILE, _N_TILE),
        stride_order=(1, 0),
        assumed_align=16,
    )
    return cute.compile(
        host,
        fake_a,
        fake_b,
        fake_sfa,
        fake_sfb,
        fake_c,
        _A_DTYPE_TO_ID[a_kind],
        options="--enable-tvm-ffi",
    )


def _pack_four_fp6_codes(code: int) -> tuple[int, int, int]:
    packed = code | (code << 6) | (code << 12) | (code << 18)
    return tuple((packed >> (8 * i)) & 0xFF for i in range(3))


def _make_packed_a(a_dtype: AType) -> torch.Tensor:
    if a_dtype == "fp4":
        packed_pair = _FP4_E2M1_ONE | (_FP4_E2M1_ONE << 4)
        return torch.full(
            (_M_TILE, _FP4_A_ROW_BYTES),
            packed_pair,
            dtype=torch.uint8,
            device="cuda",
        )

    fp6_group = _pack_four_fp6_codes(_FP6_E3M2_ONE)
    row = torch.tensor(
        fp6_group * (_K_TILE // 4),
        dtype=torch.uint8,
        device="cuda",
    )
    return row.unsqueeze(0).repeat(_M_TILE, 1).contiguous()


def run(compiled_fn: Callable, a_dtype: str = "fp4"):
    """Allocate packed A, B, scales, and C; return ``(c, a, b, sfa, sfb)``."""
    if not torch.cuda.is_available():
        raise RuntimeError("CUDA GPU required")
    a_kind = _normalize_a_dtype(a_dtype)
    a = _make_packed_a(a_kind)
    b = torch.ones(
        (_N_TILE, _K_TILE),
        dtype=torch.float32,
        device="cuda",
    ).to(torch.float8_e4m3fn)
    sfa = torch.full(
        (1, 1, 1, _SF_BYTES),
        _E8M0_ONE,
        dtype=torch.uint8,
        device="cuda",
    )
    sfb = torch.full_like(sfa, _E8M0_ONE)
    c = torch.zeros((_M_TILE, _N_TILE), dtype=torch.float32, device="cuda")
    compiled_fn(a, b, sfa, sfb, c)
    torch.cuda.synchronize()
    return c, a, b, sfa, sfb


def _reference() -> torch.Tensor:
    return torch.full((_M_TILE, _N_TILE), float(_K_TILE), device="cuda")


def verify(a_dtype: str = "fp4") -> None:
    a_kind = _normalize_a_dtype(a_dtype)
    compiled_fn = compile(a_kind)
    print(
        f"Compile kernel (a_dtype={a_kind}, M={_M_TILE}, N={_N_TILE}, K={_K_TILE}) OK",
        flush=True,
    )
    c, *_ = run(compiled_fn, a_kind)
    print(f"Run kernel (a_dtype={a_kind}) OK", flush=True)
    torch.testing.assert_close(c, _reference(), atol=0.1, rtol=1e-5)
    print(f"verify (a_dtype={a_kind}): PASS", flush=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument(
        "--a-dtype",
        choices=("fp4", "fp6", "all"),
        default="fp4",
        help="Narrow A dtype variant to verify.",
    )
    args = parser.parse_args()
    if not _check_sm100():
        print("SKIP: SM100+ (Blackwell) GPU required")
        sys.exit(0)
    if args.a_dtype == "all":
        verify("fp4")
        verify("fp6")
    else:
        verify(args.a_dtype)
