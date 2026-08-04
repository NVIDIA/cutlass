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

"""Real-instruction tcgen05 SliceK M32/N8/K128 layout probes.

This example is intentionally small and direct.  It exercises the SliceK
contracts from the write-kernel pattern with actual Blackwell instructions:

* TMA A/B paths via ``cp.async.bulk.tensor.shared::cta.global``.
* A copied via per-thread ``cp.async.shared.global``.
* Tensor MMA via ``tcgen05.mma``.
* Epilog readback via ``tcgen05.ld``.
* A TMEM staging via ``tcgen05.st``.

All variants compute one logical GEMM tile:

```text
logical M/N/K = 32 / 8 / 128
physical MMA  = 128 x {32 or 8} x 32B
```

The expanded-N variants issue one ``128x32x32B`` MMA and reduce K-stripe
partials in the epilog.  The N-group variants issue four ``128x8x32B`` MMAs
to save accumulator columns; one uses A TMEM ``.ashift`` and fixed WDM, and
one uses SMEM-A collector reuse plus per-group WDM.

Public API::

    verify("async_s32_smem")
    verify("a_tmem_core_matrix")
    verify("tma_s128_mma_s32")
    verify("tma_s32_mma_s32")
    verify("n_group_a_tmem_shift_wdm")
    verify("n_group_smem_a_reuse_wdm")

"""

from __future__ import annotations

import argparse
import sys
from functools import lru_cache
from typing import Callable

import torch


import cutlass
import cutlass.experimental.cuda as cuda
import cutlass.cute as cute
import cutlass.torch as cutlass_torch
from cutlass.cute.runtime import make_fake_compact_tensor
from cutlass.experimental import primitives as prims


_LOGICAL_M = 32
_LOGICAL_N = 8
_LOGICAL_K = 128
_MMA_M = 128
_MMA_K_BYTES = 32
_A_PACK_STRIPES = _MMA_M // _LOGICAL_M
_EXPANDED_N = _LOGICAL_N * _A_PACK_STRIPES
_THREADS = 192
_MMA_WARP = 4
_TMA_WARP = 5
_TMEM_COLS = 128
_A_TMEM_COL_OFF = 32

_A_TMEM_CORE = 0
_ASYNC_S32 = 1
_TMA_S128_MMA_S32 = 2
_TMA_S32_MMA_S32 = 3
_N_GROUP_A_TMEM_SHIFT = 4
_N_GROUP_SMEM_A_REUSE = 5

_VARIANT_BY_NAME = {
    "a_tmem_core_matrix": _A_TMEM_CORE,
    "async_s32_smem": _ASYNC_S32,
    "tma_s128_mma_s32": _TMA_S128_MMA_S32,
    "tma_s32_mma_s32": _TMA_S32_MMA_S32,
    "n_group_a_tmem_shift_wdm": _N_GROUP_A_TMEM_SHIFT,
    "n_group_smem_a_reuse_wdm": _N_GROUP_SMEM_A_REUSE,
}

_VARIANT_NAMES = tuple(_VARIANT_BY_NAME)


def _check_sm100() -> bool:
    if not torch.cuda.is_available():
        return False
    cap = torch.cuda.get_device_capability()
    return cap[0] >= 10


@cute.jit
def _needs_tma_a_s128(variant):
    return (
        variant == _A_TMEM_CORE
        or variant == _TMA_S128_MMA_S32
        or variant == _N_GROUP_A_TMEM_SHIFT
    )


@cute.jit
def _needs_async_a(variant):
    return variant == _ASYNC_S32 or variant == _N_GROUP_SMEM_A_REUSE


@cute.jit
def _needs_tma_a_s32(variant):
    return variant == _TMA_S32_MMA_S32


@cute.jit
def _uses_a_tmem(variant):
    return variant == _A_TMEM_CORE or variant == _N_GROUP_A_TMEM_SHIFT


@cute.jit
def _is_n_group(variant):
    return variant == _N_GROUP_A_TMEM_SHIFT or variant == _N_GROUP_SMEM_A_REUSE


@cute.jit
def _compact_wdm_for_slot(slot):
    mask = 0
    for lane in cutlass.range_constexpr(32):
        if cutlass.const_expr((lane & 3) != slot):
            mask = cutlass.const_expr(mask | (1 << lane))
    return cutlass.Vector.from_elements((mask, mask, mask, mask), dtype=cutlass.Int32)


@cute.jit
def _collector_for_group(group):
    if cutlass.const_expr(group == 0):
        return prims.Tcgen05MMACollectorOp.FILL
    if cutlass.const_expr(group == _A_PACK_STRIPES - 1):
        return prims.Tcgen05MMACollectorOp.LASTUSE
    return prims.Tcgen05MMACollectorOp.USE


@cute.jit
def _mma_visible_a_stripe(variant, physical_m, raw_slot):
    if cutlass.const_expr(variant == _TMA_S128_MMA_S32):
        return raw_slot ^ ((physical_m >> 3) & 3)
    return raw_slot


@cute.jit
def _async_a_compact(a_tensor, smem_a, lane_id, producer_warp):
    sw_s32b = cutlass.Swizzle.from_name("s32b")
    a_ptr = a_tensor.iterator.raw_ptr()
    for copy_i in cutlass.range_constexpr(2):
        seg = (producer_warp * 2 + copy_i) * 32 + lane_id
        physical_m = seg >> 1
        half = seg & 1
        logical_m = physical_m >> 2
        k_stripe = physical_m & 3
        k_byte = k_stripe * _MMA_K_BYTES + half * 16
        src = a_ptr + logical_m * _LOGICAL_K + k_byte
        smem_off = physical_m * _MMA_K_BYTES + half * 16
        dst = (smem_a.subview(smem_off)).data_ptr().apply_swizzle(sw_s32b)
        prims.cp_async_shared_global(
            dst,
            src,
            16,
            "cg",
        )


@cute.jit
def _load_a_s128_chunk_from_smem(smem_a, physical_m):
    raw_slot = physical_m & 3
    logical_m = physical_m >> 2
    i32_row = logical_m * (_LOGICAL_K // 4) + raw_slot * (_MMA_K_BYTES // 4)
    smem_i32 = cutlass.inttoptr(smem_a.data_ptr().toint(), 3, cutlass.Int32)
    swizzle_i32 = ((i32_row >> 5) & 7) << 2
    lo = (smem_i32 + (i32_row ^ swizzle_i32)).load(count=4, alignment=16)
    hi = (smem_i32 + ((i32_row + 4) ^ swizzle_i32)).load(count=4, alignment=16)
    return cutlass.Vector.from_elements(
        (lo[0], lo[1], lo[2], lo[3], hi[0], hi[1], hi[2], hi[3]),
        dtype=cutlass.Int32,
    )


@cute.jit
def _stage_compact_a_to_tmem(smem_a, tmem_raw, warp_idx, lane_id):
    physical_m = warp_idx * 32 + lane_id
    a_vec = _load_a_s128_chunk_from_smem(smem_a, physical_m)
    a_tmem_addr = tmem_raw + _A_TMEM_COL_OFF + ((warp_idx * 32) << 16)
    a_tmem_ptr = cutlass.inttoptr(a_tmem_addr, 6, cutlass.Int32)
    prims.tcgen05_st("32x32b", a_tmem_ptr, a_vec)


@cute.jit
def _build_a_s32_desc(smem_a):
    return prims.Tcgen05SmemDesc.build(
        start_address=smem_a,
        leading_byte_offset=16,
        stride_byte_offset=256,
        layout=prims.Tcgen05SmemSwizzle.SWIZZLE_32B,
    )


@cute.jit
def _build_b_expanded_desc(smem_b):
    return prims.Tcgen05SmemDesc.build(
        start_address=smem_b,
        leading_byte_offset=16,
        stride_byte_offset=32,
        layout=prims.Tcgen05SmemSwizzle.SWIZZLE_128B,
    )


@cute.jit
def _build_b_n_group_desc(smem_b):
    return prims.Tcgen05SmemDesc.build(
        start_address=smem_b,
        leading_byte_offset=16,
        stride_byte_offset=1024,
        layout=prims.Tcgen05SmemSwizzle.SWIZZLE_128B,
    )


@cute.jit
def _reduce_four_lanes(v):
    v = v + cute.arch.shuffle_sync_down(v, 2, mask_and_clamp=7171)
    v = v + cute.arch.shuffle_sync_down(v, 1, mask_and_clamp=7171)
    return v


@cute.kernel
def kernel(
    tma_a_s128: cutlass.GridConstant[cuda.TensorMap],
    tma_a_s32: cutlass.GridConstant[cuda.TensorMap],
    tma_b_s128: cutlass.GridConstant[cuda.TensorMap],
    a_tensor: cute.Tensor,
    c_tensor: cute.Tensor,
    VARIANT: cutlass.Constexpr[int],
) -> None:
    smem_a = cutlass.Array(
        cutlass.Int8,
        _LOGICAL_M * _LOGICAL_K,
        space=cutlass.AddressSpace.smem,
        alignment=128,
    )
    smem_b = cutlass.Array(
        cutlass.Int8,
        _LOGICAL_N * _LOGICAL_K,
        space=cutlass.AddressSpace.smem,
        alignment=128,
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
    warp_idx = cute.arch.make_warp_uniform(warp_idx)
    tidx, _, _ = cute.arch.thread_idx()
    lane_id = tidx & cutlass.Int32(31)

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
    d_tmem = cutlass.inttoptr(tmem_raw, 6, cutlass.Float32)
    prims.tcgen05_relinquish_alloc_permit(group="cta_1")

    if cutlass.const_expr(_needs_async_a(VARIANT)):
        if warp_idx < 4:
            _async_a_compact(a_tensor, smem_a, lane_id, warp_idx)
        prims.cp_async_commit_group()
        prims.cp_async_wait_group(0)

    if warp_idx == _TMA_WARP:
        if prims.elect_sync():
            tma_bytes = tma_b_s128.global_tx_bytes()
            if cutlass.const_expr(_needs_tma_a_s128(VARIANT)):
                tma_bytes = tma_bytes + tma_a_s128.global_tx_bytes()
            if cutlass.const_expr(_needs_tma_a_s32(VARIANT)):
                tma_bytes = tma_bytes + tma_a_s32.global_tx_bytes()
            prims.mbarrier_arrive_expect_tx(full_mbar, tma_bytes)
            prims.cp_async_bulk_tensor_shared_cta_global(
                smem_b,
                tma_b_s128.get_ptr(),
                (cutlass.Int32(0), cutlass.Int32(0)),
                full_mbar,
            )
            if cutlass.const_expr(_needs_tma_a_s128(VARIANT)):
                prims.cp_async_bulk_tensor_shared_cta_global(
                    smem_a,
                    tma_a_s128.get_ptr(),
                    (cutlass.Int32(0), cutlass.Int32(0)),
                    full_mbar,
                )
            if cutlass.const_expr(_needs_tma_a_s32(VARIANT)):
                prims.cp_async_bulk_tensor_shared_cta_global(
                    smem_a,
                    tma_a_s32.get_ptr(),
                    (cutlass.Int32(0), cutlass.Int32(0), cutlass.Int32(0)),
                    full_mbar,
                )

    while not prims.mbarrier_try_wait_parity(full_mbar, cutlass.Int32(0)):
        pass
    prims.barrier_cta_sync(0)

    if cutlass.const_expr(_uses_a_tmem(VARIANT)):
        if warp_idx < 4:
            _stage_compact_a_to_tmem(smem_a, tmem_raw, warp_idx, lane_id)
        prims.tcgen05_wait(prims.Tcgen05Wait.STORE)
        prims.barrier_cta_sync(0)

    if warp_idx == _MMA_WARP:
        desc_b_expanded = _build_b_expanded_desc(smem_b)
        desc_b_n_group = _build_b_n_group_desc(smem_b)
        desc_a_s32 = _build_a_s32_desc(smem_a)
        idesc_expanded = prims.Tcgen05InstrDesc.build(
            c_dtype=cutlass.Float32,
            a_dtype=cutlass.Float8E4M3FN,
            b_dtype=cutlass.Float8E4M3FN,
            n_dim=_EXPANDED_N,
            m_dim=_MMA_M,
        )
        idesc_n_group = prims.Tcgen05InstrDesc.build(
            c_dtype=cutlass.Float32,
            a_dtype=cutlass.Float8E4M3FN,
            b_dtype=cutlass.Float8E4M3FN,
            n_dim=_LOGICAL_N,
            m_dim=_MMA_M,
        )

        if cutlass.const_expr(_is_n_group(VARIANT)):
            for group in cutlass.range_constexpr(_A_PACK_STRIPES):
                desc_b = desc_b_n_group.advance_start_address(group * _MMA_K_BYTES)
                if cutlass.const_expr(VARIANT == _N_GROUP_A_TMEM_SHIFT):
                    a_tmem = cutlass.inttoptr(
                        tmem_raw + _A_TMEM_COL_OFF, 6, cutlass.Int32
                    )
                    wdm = _compact_wdm_for_slot(0)
                    if prims.elect_sync():
                        prims.tcgen05_mma(
                            prims.Tcgen05MMAKind.F8F6F4,
                            prims.CTAGroup.CTA_1,
                            d_tmem,
                            a_tmem,
                            desc_b,
                            idesc_n_group,
                            group != 0,
                            write_disable_mask=wdm,
                            a_shift=(group != _A_PACK_STRIPES - 1),
                        )
                else:
                    wdm = _compact_wdm_for_slot(group)
                    collector = _collector_for_group(group)
                    if prims.elect_sync():
                        prims.tcgen05_mma(
                            prims.Tcgen05MMAKind.F8F6F4,
                            prims.CTAGroup.CTA_1,
                            d_tmem,
                            desc_a_s32,
                            desc_b,
                            idesc_n_group,
                            False,
                            write_disable_mask=wdm,
                            collector_op=collector,
                        )
        else:
            if cutlass.const_expr(VARIANT == _A_TMEM_CORE):
                a_operand = cutlass.inttoptr(
                    tmem_raw + _A_TMEM_COL_OFF, 6, cutlass.Int32
                )
            else:
                a_operand = desc_a_s32
            if prims.elect_sync():
                prims.tcgen05_mma(
                    prims.Tcgen05MMAKind.F8F6F4,
                    prims.CTAGroup.CTA_1,
                    d_tmem,
                    a_operand,
                    desc_b_expanded,
                    idesc_expanded,
                    False,
                )

        if prims.elect_sync():
            prims.tcgen05_commit(acc_mbar, group=prims.CTAGroup.CTA_1)

    prims.barrier_cta_sync(0)
    while not prims.mbarrier_try_wait_parity(acc_mbar, cutlass.Int32(0)):
        pass

    if warp_idx < 4:
        base_col = tmem_raw & cutlass.Int32(0xFFFF)
        base_row = tmem_raw >> cutlass.Int32(16)
        tmem_row = base_row + warp_idx * cutlass.Int32(32)
        tmem_addr = (tmem_row << cutlass.Int32(16)) | base_col
        gC = c_tensor.iterator.raw_ptr()
        physical_m = warp_idx * cutlass.Int32(32) + lane_id
        raw_slot = physical_m & cutlass.Int32(3)
        logical_m = physical_m >> cutlass.Int32(2)

        if cutlass.const_expr(VARIANT == _N_GROUP_A_TMEM_SHIFT):
            c_vec = prims.tcgen05_ld(
                "32x32b",
                cutlass.inttoptr(tmem_addr, 6, cutlass.Float32),
                num=_LOGICAL_N,
            )
            prims.tcgen05_wait(prims.Tcgen05Wait.LOAD)
            if raw_slot == 0:
                for n in cutlass.range_constexpr(_LOGICAL_N):
                    (gC + logical_m * _LOGICAL_N + n).store(c_vec[n])
        elif cutlass.const_expr(VARIANT == _N_GROUP_SMEM_A_REUSE):
            c_vec = prims.tcgen05_ld(
                "32x32b",
                cutlass.inttoptr(tmem_addr, 6, cutlass.Float32),
                num=_LOGICAL_N,
            )
            prims.tcgen05_wait(prims.Tcgen05Wait.LOAD)
            for n in cutlass.range_constexpr(_LOGICAL_N):
                v = _reduce_four_lanes(c_vec[n])
                if raw_slot == 0:
                    (gC + logical_m * _LOGICAL_N + n).store(v)
        else:
            c_vec = prims.tcgen05_ld(
                "32x32b",
                cutlass.inttoptr(tmem_addr, 6, cutlass.Float32),
                num=_EXPANDED_N,
            )
            prims.tcgen05_wait(prims.Tcgen05Wait.LOAD)
            visible_k = _mma_visible_a_stripe(VARIANT, physical_m, raw_slot)
            for n in cutlass.range_constexpr(_LOGICAL_N):
                v = c_vec[visible_k * _LOGICAL_N + n]
                v = _reduce_four_lanes(v)
                if raw_slot == 0:
                    (gC + logical_m * _LOGICAL_N + n).store(v)

    prims.tcgen05_fence(prims.Tcgen05Fence.BEFORE_THREAD_SYNC)
    prims.barrier_cta_sync(0)
    if warp_idx == 0:
        prims.tcgen05_dealloc(d_tmem, _TMEM_COLS, group="cta_1")


@cute.jit
def host(
    a: cute.Tensor,
    b: cute.Tensor,
    c: cute.Tensor,
    VARIANT: cutlass.Constexpr[int],
) -> None:
    a_s32_view = cute.make_tensor(
        a.iterator,
        cute.make_layout(
            (_MMA_K_BYTES, _A_PACK_STRIPES, _LOGICAL_M),
            stride=(1, _MMA_K_BYTES, _LOGICAL_K),
        ),
    )
    tma_a_s128 = cuda.create_tensor_map_tiled(
        global_address=a.iterator.toint(),
        dtype=a.element_type,
        global_dims=[a.shape[1], a.shape[0]],
        global_strides=[a.shape[1] // 16],
        box_dims=[_LOGICAL_K, _LOGICAL_M],
        swizzle=cuda.TensorMapSwizzle.s128b,
    )
    tma_a_s32 = cuda.create_tensor_map_tiled_from_view(
        a_s32_view,
        box_dims=(_MMA_K_BYTES, _A_PACK_STRIPES, _LOGICAL_M),
        stride_order=(0, 1, 2),
        swizzle=cuda.TensorMapSwizzle.s32b,
    )
    tma_b_s128 = cuda.create_tensor_map_tiled(
        global_address=b.iterator.toint(),
        dtype=b.element_type,
        global_dims=[b.shape[1], b.shape[0]],
        global_strides=[b.shape[1] // 16],
        box_dims=[_LOGICAL_K, _LOGICAL_N],
        swizzle=cuda.TensorMapSwizzle.s128b,
    )
    kernel(tma_a_s128, tma_a_s32, tma_b_s128, a, c, VARIANT).launch(
        grid=(1, 1, 1),
        block=(_THREADS, 1, 1),
    )


def _variant_id(variant: str) -> int:
    try:
        return _VARIANT_BY_NAME[variant]
    except KeyError as exc:
        valid = ", ".join(_VARIANT_NAMES)
        raise ValueError(f"unknown SliceK variant {variant!r}; valid: {valid}") from exc


@lru_cache(maxsize=None)
def compile(variant: str = "async_s32_smem") -> Callable:  # noqa: A001
    variant_id = _variant_id(variant)
    fake_a = make_fake_compact_tensor(
        cutlass.Float8E4M3FN,
        (_LOGICAL_M, _LOGICAL_K),
        stride_order=(1, 0),
        assumed_align=16,
    )
    fake_b = make_fake_compact_tensor(
        cutlass.Float8E4M3FN,
        (_LOGICAL_N, _LOGICAL_K),
        stride_order=(1, 0),
        assumed_align=16,
    )
    fake_c = make_fake_compact_tensor(
        cutlass.Float32,
        (_LOGICAL_M, _LOGICAL_N),
        stride_order=(1, 0),
        assumed_align=16,
    )
    return cute.compile(
        host,
        fake_a,
        fake_b,
        fake_c,
        variant_id,
        options="--enable-tvm-ffi",
    )


def _make_inputs() -> tuple[torch.Tensor, torch.Tensor, torch.Tensor]:
    torch_a_dtype = cutlass_torch.dtype(cutlass.Float8E4M3FN)
    a_base = torch.arange(
        _LOGICAL_M * _LOGICAL_K,
        dtype=torch.float16,
        device="cuda",
    ).reshape(_LOGICAL_M, _LOGICAL_K)
    b_base = torch.arange(
        _LOGICAL_N * _LOGICAL_K,
        dtype=torch.float16,
        device="cuda",
    ).reshape(_LOGICAL_N, _LOGICAL_K)
    a = ((a_base % 7) - 3).to(torch_a_dtype)
    b = (((b_base * 3) % 11) - 5).to(torch_a_dtype)
    c = torch.zeros(_LOGICAL_M, _LOGICAL_N, dtype=torch.float32, device="cuda")
    return a, b, c


def run(
    *,
    compiled_fn: Callable | None = None,
    variant: str = "async_s32_smem",
) -> tuple[torch.Tensor, torch.Tensor, torch.Tensor]:
    if compiled_fn is None:
        compiled_fn = compile(variant)
    a, b, c = _make_inputs()
    compiled_fn(a, b, c)
    torch.cuda.synchronize()
    return c, a, b


def verify(variant: str = "async_s32_smem") -> None:
    compiled_fn = compile(variant)
    print(f"Compile SliceK real-instruction variant {variant!r} OK", flush=True)
    c, a, b = run(compiled_fn=compiled_fn, variant=variant)
    print(f"Run SliceK real-instruction variant {variant!r} OK", flush=True)
    ref = torch.einsum("mk,nk->mn", a.float(), b.float())
    torch.testing.assert_close(c, ref, atol=0.75, rtol=1e-5)
    print(f"verify ({variant}): PASS", flush=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument(
        "variant",
        nargs="?",
        default="async_s32_smem",
        choices=_VARIANT_NAMES,
        help="SliceK real-instruction variant to run.",
    )
    args = parser.parse_args()
    if not _check_sm100():
        print("SKIP: SM100+ (Blackwell) GPU required")
        sys.exit(0)
    verify(args.variant)
