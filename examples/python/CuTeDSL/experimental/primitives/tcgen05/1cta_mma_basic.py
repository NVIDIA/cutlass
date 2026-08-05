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
Focused ``cutlass.primitives.tcgen05_mma`` correctness tests — dense MMA kwargs (single CTA).

The example uses one parameterized CTA_1 kernel.  Operand dtype,
``MMA_SHAPE``, and niche ``tcgen05.mma`` kwargs are compile-time parameters;
runtime M/N/K stays symbolic and is supplied through ``verify(..., mnk=...)``.

Usage::

    python CuTeDSL/experimental/primitives/tcgen05/1cta_mma_basic.py
    python CuTeDSL/experimental/primitives/tcgen05/1cta_mma_basic.py --ab_dtype fp8_e4m3
    python CuTeDSL/experimental/primitives/tcgen05/1cta_mma_basic.py --mma_shape 128,64,64 --mnk 256,128,64
    python CuTeDSL/experimental/primitives/tcgen05/1cta_mma_basic.py --tmem_ld_warp_start 2

"""

from __future__ import annotations

import argparse
import sys
from functools import lru_cache
from typing import Callable

import torch

from cutlass.experimental.primitives import Tcgen05InstrDesc

import cutlass
import cutlass.experimental.cuda as cuda
import cutlass.cute as cute
import cutlass.torch as cutlass_torch
from cutlass.cute.runtime import make_fake_compact_tensor
from cutlass.experimental import primitives as prims


_TMEM_LD_WARPS = 4
_DEFAULT_TMEM_LD_WARP_START = 0


def _threads_for_tmem_ld_warp_start(tmem_ld_warp_start: int) -> int:
    """Return CTA threads needed for a contiguous 4-warp TMEM-load range."""
    if tmem_ld_warp_start < 0 or tmem_ld_warp_start > 4:
        raise ValueError("tmem_ld_warp_start must be in [0, 4]")
    return (tmem_ld_warp_start + _TMEM_LD_WARPS) * 32


def _validate_tmem_ld_warp_start(
    tmem_ld_warp_start: int,
    MMA_SHAPE: tuple[int, int, int],
) -> None:
    """Validate the shifted TMEM-load variant supported by this example."""
    _threads_for_tmem_ld_warp_start(tmem_ld_warp_start)
    if tmem_ld_warp_start and MMA_SHAPE[0] != 128:
        raise ValueError("nonzero tmem_ld_warp_start requires MMA_SHAPE M=128")


_DTYPE_BY_NAME = {
    "f16": cutlass.Float16,
    "bf16": cutlass.BFloat16,
    "tf32": cutlass.Float32,
    "fp8_e4m3": cutlass.Float8E4M3FN,
    "fp8_e5m2": cutlass.Float8E5M2,
}


def _check_sm100() -> bool:
    """Return True if current GPU is SM100+."""
    if not torch.cuda.is_available():
        return False
    cap = torch.cuda.get_device_capability()
    return cap[0] >= 10


def _stride_dim(k_tile: int, elem_bytes: int) -> int:
    """Stride dim offset in 16B units for K-major SMEM."""
    return 8 * k_tile * elem_bytes // 16


def _is_fp8_dtype(dtype: type) -> bool:
    """Return True for supported FP8 tcgen05 input dtypes."""
    return dtype is cutlass.Float8E4M3FN or dtype is cutlass.Float8E5M2


def _default_output_dtype(input_dtype: type) -> type:
    """Return the natural C tensor dtype for an input dtype."""
    if _is_fp8_dtype(input_dtype):
        return cutlass.Float16
    return input_dtype


def _acc_dtype(input_dtype: type) -> type:
    """Return the accumulator dtype for the dense tcgen05 instruction."""
    if _is_fp8_dtype(input_dtype):
        return cutlass.Float16
    return cutlass.Float32


def _mma_kind(input_dtype: type) -> prims.Tcgen05MMAKind:
    """Return tcgen05 MMA kind from the instruction input dtype family."""
    if input_dtype is cutlass.Float32:
        return prims.Tcgen05MMAKind.TF32
    if _is_fp8_dtype(input_dtype):
        return prims.Tcgen05MMAKind.F8F6F4
    return prims.Tcgen05MMAKind.F16


def _mma_k_granule(input_dtype: type) -> int:
    """Return the K granule for one tcgen05.mma instruction."""
    if input_dtype is cutlass.Float32:
        return 8
    if _is_fp8_dtype(input_dtype):
        return 32
    return 16


def _swizzle_for_row_bytes(row_bytes: int) -> cuda.TensorMapSwizzle:
    """Return the canonical swizzle for a K-major row width."""
    if row_bytes == 128:
        return cuda.TensorMapSwizzle.s128b
    if row_bytes == 64:
        return cuda.TensorMapSwizzle.s64b
    raise ValueError(f"Unsupported K-major row byte length: {row_bytes}")


def _desc_lead_for_row_bytes(row_bytes: int) -> int:
    """Return descriptor leading-dimension offset in 16B units."""
    if row_bytes == 64:
        return 0
    if row_bytes == 128:
        return row_bytes // 16
    raise ValueError(f"Unsupported K-major row byte length: {row_bytes}")


@cute.kernel
def kernel(
    tma_a_desc: cutlass.GridConstant[cuda.TensorMap],
    tma_b_desc: cutlass.GridConstant[cuda.TensorMap],
    c_ptr: cute.Tensor,
    num_k_tiles: cutlass.Int64,
    MMA_SHAPE: cutlass.Constexpr,
    COLLECTOR: cutlass.Constexpr[int],
    SCALE_D: cutlass.Constexpr[int],
    WDMASK: cutlass.Constexpr[int],
    TMEM_LD_WARP_START: cutlass.Constexpr[int],
) -> None:
    """Unified CTA_1 tcgen05.mma correctness kernel."""
    MMA_M, MMA_N, MMA_K = MMA_SHAPE
    AB_DTYPE: cutlass.Constexpr = tma_a_desc.dtype
    D_DTYPE: cutlass.Constexpr = c_ptr.element_type
    ACC_DTYPE: cutlass.Constexpr = _acc_dtype(AB_DTYPE)
    MMA_KIND: cutlass.Constexpr = _mma_kind(AB_DTYPE)
    ELEM_BYTES: cutlass.Constexpr[int] = AB_DTYPE.width // 8
    K_GRANULE: cutlass.Constexpr[int] = _mma_k_granule(AB_DTYPE)
    SMEM_SWIZZLE: cutlass.Constexpr = tma_a_desc.swizzle.to(prims.Tcgen05SmemSwizzle)
    DESC_LEAD: cutlass.Constexpr[int] = _desc_lead_for_row_bytes(MMA_K * ELEM_BYTES)
    PACKED_ACC: cutlass.Constexpr[bool] = ACC_DTYPE is cutlass.Float16

    smem_a = cutlass.Array(
        AB_DTYPE, MMA_M * MMA_K, space=cutlass.AddressSpace.smem, alignment=128
    )
    smem_b = cutlass.Array(
        AB_DTYPE, MMA_N * MMA_K, space=cutlass.AddressSpace.smem, alignment=128
    )
    full_mbar = cutlass.Array(
        cutlass.Int64, 1, space=cutlass.AddressSpace.smem, alignment=8
    )
    acc_mbar = cutlass.Array(
        cutlass.Int64, 1, space=cutlass.AddressSpace.smem, alignment=8
    )
    empty_bar = cutlass.Array(
        cutlass.Int64, 1, space=cutlass.AddressSpace.smem, alignment=8
    )
    tmem_ptr_i32 = cutlass.Array(
        cutlass.Int32, 1, space=cutlass.AddressSpace.smem, alignment=4
    )

    warp_idx = cute.arch.warp_idx()
    tidx, _, _ = cute.arch.thread_idx()
    bidx, bidy, _ = cute.arch.block_idx()
    TMEM_LD_WARP_END: cutlass.Constexpr[int] = TMEM_LD_WARP_START + _TMEM_LD_WARPS
    is_tmem_ld_warp = (warp_idx >= TMEM_LD_WARP_START) & (warp_idx < TMEM_LD_WARP_END)
    tmem_sp = warp_idx % cutlass.Int32(4)

    coord_m = bidx * MMA_M
    coord_n = bidy * MMA_N

    num_tmem_cols: cutlass.Constexpr[int] = (MMA_N // 8) * 32
    idesc = Tcgen05InstrDesc.build(
        c_dtype=ACC_DTYPE,
        a_dtype=AB_DTYPE,
        b_dtype=AB_DTYPE,
        n_dim=MMA_N,
        m_dim=MMA_M,
    )

    if warp_idx == 0:
        if prims.elect_sync():
            prims.mbarrier_init(full_mbar, 1)
            prims.mbarrier_init(acc_mbar, 1)
            prims.mbarrier_init(empty_bar, 1)
    prims.fence_mbarrier_init()
    prims.barrier_cta_sync(0)

    if warp_idx == 0:
        prims.tcgen05_alloc(tmem_ptr_i32, num_tmem_cols, group="cta_1")
    prims.barrier_cta_sync(0)

    tmem_base_raw = tmem_ptr_i32.load()
    if cutlass.const_expr(PACKED_ACC):
        tmem_ptr = prims.make_tmem_ptr(tmem_base_raw, cutlass.Int8)
    else:
        tmem_ptr = cutlass.inttoptr(tmem_base_raw, 6, cutlass.Float32)
    prims.tcgen05_relinquish_alloc_permit(group="cta_1")

    a_ptr = tma_a_desc.get_ptr()
    b_ptr = tma_b_desc.get_ptr()
    tma_load_bytes = tma_a_desc.global_tx_bytes() + tma_b_desc.global_tx_bytes()

    desc_stride: cutlass.Constexpr[int] = _stride_dim(MMA_K, ELEM_BYTES)
    desc_step_bytes: cutlass.Constexpr[int] = K_GRANULE * ELEM_BYTES

    if cutlass.const_expr(WDMASK == 1):
        wd_vec = cutlass.Vector.from_elements(
            (
                0x0000000F,
                0x00000000,
                0x00000007,
                0x00000000,
            ),
            dtype=cutlass.Int32,
        )
        zero_vec = cutlass.Vector.from_elements(
            tuple(0 for _ in range(32)),
            dtype=cutlass.Int32,
        )
        if is_tmem_ld_warp:
            seed_base = prims.TmemAddr(tmem_base_raw)
            seed_col = seed_base.col_id
            seed_row = seed_base.row_id + tmem_sp * cutlass.Int32(32)
            for sub in cutlass.range_constexpr(MMA_N // 32):
                seed_ptr = prims.TmemAddr.from_row_col(
                    seed_row, seed_col + sub * 32
                ).as_ptr(cutlass.Int32)
                prims.tcgen05_st(
                    "32x32b",
                    seed_ptr,
                    zero_vec,
                )
            prims.tcgen05_wait(prims.Tcgen05Wait.STORE)
        prims.barrier_cta_sync(0)
    else:
        wd_vec = None

    if warp_idx == 0:
        desc_a_root = prims.Tcgen05SmemDesc.build(
            start_address=smem_a,
            leading_byte_offset=DESC_LEAD * 16,
            stride_byte_offset=desc_stride * 16,
            layout=SMEM_SWIZZLE,
        )
        desc_b_root = prims.Tcgen05SmemDesc.build(
            start_address=smem_b,
            leading_byte_offset=DESC_LEAD * 16,
            stride_byte_offset=desc_stride * 16,
            layout=SMEM_SWIZZLE,
        )
        empty_phase = 0
        full_phase = 0
        for k in cutlass.range(num_k_tiles):
            if prims.elect_sync():
                prims.mbarrier_arrive_expect_tx(full_mbar, tma_load_bytes)
                k_coord = k * MMA_K
                prims.cp_async_bulk_tensor_shared_cta_global(
                    smem_a,
                    a_ptr,
                    (k_coord, coord_m),
                    full_mbar,
                )
                prims.cp_async_bulk_tensor_shared_cta_global(
                    smem_b,
                    b_ptr,
                    (k_coord, coord_n),
                    full_mbar,
                )

            while not prims.mbarrier_try_wait_parity(
                full_mbar, full_phase, time_limit=10_000_000
            ):
                pass
            full_phase = full_phase ^ 1

            scale_d = k > 0
            if cutlass.const_expr(COLLECTOR == 2):
                if prims.elect_sync():
                    prims.tcgen05_mma(
                        MMA_KIND,
                        prims.CTAGroup.CTA_1,
                        tmem_ptr,
                        desc_a_root,
                        desc_b_root,
                        idesc,
                        False,
                        collector_op=prims.Tcgen05MMACollectorOp.FILL,
                    )
                    prims.tcgen05_commit(empty_bar, group=prims.CTAGroup.CTA_1)
                while not prims.mbarrier_try_wait_parity(
                    empty_bar, empty_phase, time_limit=10_000_000
                ):
                    pass
                empty_phase = empty_phase ^ 1
                if prims.elect_sync():
                    zeros = cutlass.Vector.from_elements(
                        tuple(AB_DTYPE(0.0) for _ in range(16)),
                        dtype=AB_DTYPE,
                    )
                    smem_a.data_ptr().store(zeros, alignment=16)
                prims.fence_proxy(
                    prims.Proxy.ASYNC_SHARED,
                    space=prims.SharedSpace.shared_cta,
                )
                if prims.elect_sync():
                    prims.tcgen05_mma(
                        MMA_KIND,
                        prims.CTAGroup.CTA_1,
                        tmem_ptr,
                        desc_a_root,
                        desc_b_root,
                        idesc,
                        True,
                        collector_op=prims.Tcgen05MMACollectorOp.LASTUSE,
                    )
            else:
                num_k_blocks: cutlass.Constexpr[int] = MMA_K // K_GRANULE
                for kb in cutlass.range_constexpr(num_k_blocks):
                    scale_input = (
                        SCALE_D if cutlass.const_expr(SCALE_D > 0 and kb != 0) else None
                    )
                    desc_offset_bytes: cutlass.Constexpr[int] = desc_step_bytes * kb
                    if prims.elect_sync():
                        prims.tcgen05_mma(
                            MMA_KIND,
                            prims.CTAGroup.CTA_1,
                            tmem_ptr,
                            desc_a_root.advance_start_address(desc_offset_bytes),
                            desc_b_root.advance_start_address(desc_offset_bytes),
                            idesc,
                            scale_d if kb == 0 else True,
                            scale_input_d=scale_input,
                            write_disable_mask=wd_vec,
                        )

        if prims.elect_sync():
            prims.tcgen05_commit(acc_mbar, group=prims.CTAGroup.CTA_1)

    prims.barrier_cta_sync(0)
    while not prims.mbarrier_try_wait_parity(acc_mbar, 0, time_limit=10_000_000):
        pass

    if is_tmem_ld_warp:
        tmem_base = prims.TmemAddr(tmem_base_raw)
        base_col = tmem_base.col_id
        if cutlass.const_expr(MMA_M == 64):
            tmem_row = tmem_base.row_id
        else:
            tmem_row = tmem_base.row_id + tmem_sp * cutlass.Int32(32)

        gC = c_ptr.iterator.raw_ptr()
        n_stride = c_ptr.shape[1]
        lane = tidx % 32

        for sub in cutlass.range_constexpr(MMA_N // 32):
            col = coord_n + sub * 32
            if cutlass.const_expr(PACKED_ACC):
                tmem_sub = prims.TmemAddr.from_row_col(
                    tmem_row, base_col + sub * 32
                ).as_ptr(cutlass.Float16)
                c_vec = prims.tcgen05_ld(
                    "32x32b",
                    tmem_sub,
                    num=16,
                    pack=True,
                )
            else:
                tmem_sub = prims.TmemAddr.from_row_col(
                    tmem_row, base_col + sub * 32
                ).as_ptr(cutlass.Float32)
                c_tmp = prims.tcgen05_ld(
                    "32x32b",
                    tmem_sub,
                    num=32,
                )
                if cutlass.const_expr(D_DTYPE is cutlass.Float32):
                    c_vec = c_tmp
                else:
                    c_vec = c_tmp.to(D_DTYPE)
            prims.tcgen05_wait(prims.Tcgen05Wait.LOAD)

            if cutlass.const_expr(MMA_M == 64):
                if lane < 16:
                    row = coord_m + warp_idx * 16 + lane
                    (gC + row * n_stride + col).store(c_vec, alignment=16)
            else:
                row = coord_m + tmem_sp * cutlass.Int32(32) + lane
                (gC + row * n_stride + col).store(c_vec, alignment=16)

    prims.tcgen05_fence(prims.Tcgen05Fence.BEFORE_THREAD_SYNC)
    prims.barrier_cta_sync(0)
    if warp_idx == 0:
        prims.tcgen05_dealloc(tmem_ptr, num_tmem_cols, group="cta_1")


@cute.jit
def host(
    a: cute.Tensor,
    b: cute.Tensor,
    c: cute.Tensor,
    MMA_SHAPE: cutlass.Constexpr,
    COLLECTOR: cutlass.Constexpr[int],
    SCALE_D: cutlass.Constexpr[int],
    WDMASK: cutlass.Constexpr[int],
    TMEM_LD_WARP_START: cutlass.Constexpr[int],
    THREADS: cutlass.Constexpr[int],
) -> None:
    """Build TMA descriptors and launch the unified kernel."""
    MMA_M, MMA_N, MMA_K = MMA_SHAPE

    ELEM_BYTES: cutlass.Constexpr[int] = a.element_type.width // 8
    row_bytes: cutlass.Constexpr[int] = MMA_K * ELEM_BYTES
    TMA_SWIZZLE: cutlass.Constexpr[cuda.TensorMapSwizzle] = _swizzle_for_row_bytes(
        row_bytes
    )

    if cutlass.const_expr(b.element_type is not a.element_type):
        raise ValueError("A and B tensors must have the same element type")

    tma_a = cuda.create_tensor_map_tiled(
        global_address=a.iterator.toint(),
        dtype=a.element_type,
        global_dims=[a.shape[1], a.shape[0]],
        global_strides=[a.shape[1] * ELEM_BYTES // 16],
        box_dims=[MMA_K, MMA_M],
        swizzle=TMA_SWIZZLE,
    )
    tma_b = cuda.create_tensor_map_tiled(
        global_address=b.iterator.toint(),
        dtype=b.element_type,
        global_dims=[b.shape[1], b.shape[0]],
        global_strides=[b.shape[1] * ELEM_BYTES // 16],
        box_dims=[MMA_K, MMA_N],
        swizzle=TMA_SWIZZLE,
    )
    grid_m = cute.ceil_div(a.shape[0], MMA_M)
    grid_n = cute.ceil_div(b.shape[0], MMA_N)
    num_k_tiles = a.shape[1] // MMA_K
    kernel(
        tma_a,
        tma_b,
        c,
        num_k_tiles,
        MMA_SHAPE,
        COLLECTOR,
        SCALE_D,
        WDMASK,
        TMEM_LD_WARP_START,
    ).launch(grid=(grid_m, grid_n, 1), block=(THREADS, 1, 1))


def _validate_mnk(mnk: tuple[int, int, int], MMA_SHAPE: tuple[int, int, int]) -> None:
    m, n, k = mnk
    mma_m, mma_n, mma_k = MMA_SHAPE
    if m % mma_m != 0:
        raise ValueError(f"M={m} must be a multiple of MMA_SHAPE M={mma_m}")
    if n % mma_n != 0:
        raise ValueError(f"N={n} must be a multiple of MMA_SHAPE N={mma_n}")
    if k % mma_k != 0:
        raise ValueError(f"K={k} must be a multiple of MMA_SHAPE K={mma_k}")


@lru_cache(maxsize=None)
def compile(  # noqa: A001
    *,
    AB_DTYPE: type = cutlass.Float16,
    D_DTYPE: type | None = None,
    MMA_SHAPE: tuple[int, int, int] = (128, 128, 64),
    COLLECTOR: int = 0,
    SCALE_D: int = 0,
    WDMASK: int = 0,
    tmem_ld_warp_start: int = _DEFAULT_TMEM_LD_WARP_START,
) -> Callable:
    """AOT-compile one structural tcgen05 MMA variant.

    Runtime problem size is intentionally not part of this cache key: M, N,
    and K are symbolic fake-tensor dimensions. The host computes
    ``num_k_tiles`` from the runtime K dimension. Reuse one compiled function
    for any runtime ``mnk`` that is a multiple of ``MMA_SHAPE``.

    :param AB_DTYPE: Input tensor dtype for A and B. Supported variants are
        ``cutlass.Float16``, ``cutlass.BFloat16``, ``cutlass.Float32`` for TF32, and
        ``cutlass.Float8E4M3FN`` / ``cutlass.Float8E5M2``.
    :type AB_DTYPE: type
    :param D_DTYPE: Output tensor dtype for D/C. Defaults to ``AB_DTYPE``
        except FP8 inputs, which default to ``cutlass.Float16``.
    :type D_DTYPE: type, optional
    :param MMA_SHAPE: Compile-time MMA tile shape ``(M, N, K)``. This
        controls CTA tile shape, descriptor construction, TMEM footprint, and
        the number of K-granule MMAs per runtime K tile.
    :type MMA_SHAPE: tuple[int, int, int]
    :param COLLECTOR: Set to ``2`` to exercise the A-operand collector
        ``FILL`` + ``LASTUSE`` chain; ``0`` uses the normal K-loop path.
    :type COLLECTOR: int
    :param SCALE_D: Optional ``scale_input_d`` value for accumulation MMAs.
    :type SCALE_D: int
    :param WDMASK: Set to ``1`` to exercise ``write_disable_mask``.
    :type WDMASK: int
    :param tmem_ld_warp_start: First contiguous TMEM-load warp. Nonzero
        values are supported for ``MMA_SHAPE`` M=128 and use ``warp_idx % 4``
        to map TMEM rows.
    :type tmem_ld_warp_start: int
    :returns: Compiled callable accepting runtime A, B, and D tensors.
    :rtype: Callable
    """
    _validate_tmem_ld_warp_start(tmem_ld_warp_start, MMA_SHAPE)
    D_DTYPE = _default_output_dtype(AB_DTYPE) if D_DTYPE is None else D_DTYPE
    MMA_M, MMA_N, MMA_K = MMA_SHAPE
    threads = _threads_for_tmem_ld_warp_start(tmem_ld_warp_start)
    sym_m = cute.sym_int64(divisibility=MMA_M)
    sym_n = cute.sym_int64(divisibility=MMA_N)
    sym_k = cute.sym_int64(divisibility=MMA_K)
    fake_a = make_fake_compact_tensor(
        AB_DTYPE, (sym_m, sym_k), stride_order=(1, 0), assumed_align=16
    )
    fake_b = make_fake_compact_tensor(
        AB_DTYPE, (sym_n, sym_k), stride_order=(1, 0), assumed_align=16
    )
    fake_c = make_fake_compact_tensor(
        D_DTYPE, (sym_m, sym_n), stride_order=(1, 0), assumed_align=16
    )
    return cute.compile(
        host,
        fake_a,
        fake_b,
        fake_c,
        MMA_SHAPE,
        COLLECTOR,
        SCALE_D,
        WDMASK,
        tmem_ld_warp_start,
        threads,
        options="--enable-tvm-ffi",
    )


def _make_inputs(
    m: int,
    n: int,
    k: int,
    input_dtype: type,
    output_dtype: type,
) -> tuple[torch.Tensor, torch.Tensor, torch.Tensor]:
    torch.manual_seed(42)
    torch_input_dtype = cutlass_torch.dtype(input_dtype)
    torch_output_dtype = cutlass_torch.dtype(output_dtype)
    if _is_fp8_dtype(input_dtype):
        a = torch.randn(m, k, dtype=torch.float16, device="cuda").to(torch_input_dtype)
        b = torch.randn(n, k, dtype=torch.float16, device="cuda").to(torch_input_dtype)
    else:
        a = (
            torch.empty(m, k, dtype=torch.int32)
            .random_(-2, 2)
            .to(dtype=torch_input_dtype, device="cuda")
        )
        b = (
            torch.empty(n, k, dtype=torch.int32)
            .random_(-2, 2)
            .to(dtype=torch_input_dtype, device="cuda")
        )
    c = torch.zeros(m, n, dtype=torch_output_dtype, device="cuda")
    return a, b, c


def run(
    *,
    compiled_fn: Callable | None = None,
    AB_DTYPE: type = cutlass.Float16,
    D_DTYPE: type | None = None,
    MMA_SHAPE: tuple[int, int, int] = (128, 128, 64),
    COLLECTOR: int = 0,
    SCALE_D: int = 0,
    WDMASK: int = 0,
    mnk: tuple[int, int, int] | None = None,
    tmem_ld_warp_start: int = _DEFAULT_TMEM_LD_WARP_START,
) -> tuple[torch.Tensor, torch.Tensor, torch.Tensor]:
    """Allocate A/B/D, run one structural variant, and return ``(d, a, b)``.

    ``AB_DTYPE``, ``D_DTYPE``, ``MMA_SHAPE``, ``COLLECTOR``, ``SCALE_D``, and
    ``WDMASK`` have the same meaning as in :func:`compile`. Pass
    ``compiled_fn`` to reuse an already compiled variant; otherwise ``run``
    compiles the requested variant before launching it.

    :param compiled_fn: Optional callable returned by :func:`compile` for the
        same structural parameters.
    :type compiled_fn: Callable, optional
    :param AB_DTYPE: Same as :func:`compile`.
    :type AB_DTYPE: type
    :param D_DTYPE: Same as :func:`compile`.
    :type D_DTYPE: type, optional
    :param MMA_SHAPE: Same as :func:`compile`.
    :type MMA_SHAPE: tuple[int, int, int]
    :param COLLECTOR: Same as :func:`compile`.
    :type COLLECTOR: int
    :param SCALE_D: Same as :func:`compile`.
    :type SCALE_D: int
    :param WDMASK: Same as :func:`compile`.
    :type WDMASK: int
    :param mnk: Runtime problem shape ``(M, N, K)``. Defaults to
        ``MMA_SHAPE`` and must be divisible by it.
    :type mnk: tuple[int, int, int], optional
    :param tmem_ld_warp_start: Same as :func:`compile`.
    :type tmem_ld_warp_start: int
    :returns: Tuple ``(d, a, b)`` containing the output tensor and the inputs
        used for verification.
    :rtype: tuple[torch.Tensor, torch.Tensor, torch.Tensor]
    """
    D_DTYPE = _default_output_dtype(AB_DTYPE) if D_DTYPE is None else D_DTYPE
    mnk = MMA_SHAPE if mnk is None else mnk
    _validate_mnk(mnk, MMA_SHAPE)
    _validate_tmem_ld_warp_start(tmem_ld_warp_start, MMA_SHAPE)
    if compiled_fn is None:
        compiled_fn = compile(
            AB_DTYPE=AB_DTYPE,
            D_DTYPE=D_DTYPE,
            MMA_SHAPE=MMA_SHAPE,
            COLLECTOR=COLLECTOR,
            SCALE_D=SCALE_D,
            WDMASK=WDMASK,
            tmem_ld_warp_start=tmem_ld_warp_start,
        )
    m, n, k = mnk
    a, b, c = _make_inputs(m, n, k, AB_DTYPE, D_DTYPE)
    compiled_fn(a, b, c)
    torch.cuda.synchronize()
    return c, a, b


def _reference(
    a: torch.Tensor,
    b: torch.Tensor,
    *,
    AB_DTYPE: type,
    D_DTYPE: type,
    COLLECTOR: int = 0,
    SCALE_D: int = 0,
    WDMASK: int = 0,
) -> torch.Tensor:
    """Compute torch reference, applying niche-variant math adjustments."""
    output_dtype = cutlass_torch.dtype(D_DTYPE)
    if COLLECTOR == 2:
        mma_k = _mma_k_granule(AB_DTYPE)
        ab = torch.einsum("mk,nk->mn", a[:, 0:mma_k].float(), b[:, 0:mma_k].float())
        ref = 2.0 * ab
        ref[0, :] = ab[0, :]
        return ref.to(output_dtype)

    ref_fp32 = torch.einsum("mk,nk->mn", a.float(), b.float())
    if SCALE_D > 0:
        m, k = a.shape
        n = b.shape[0]
        mma_k = _mma_k_granule(AB_DTYPE)
        total_mmas = k // mma_k
        af = a.float().reshape(m, total_mmas, mma_k)
        bf = b.float().reshape(n, total_mmas, mma_k)
        partials = torch.einsum("mtk,ntk->tmn", af, bf)
        weights = (
            2.0
            ** -(
                SCALE_D
                * torch.arange(
                    total_mmas - 1, -1, -1, dtype=torch.float32, device=a.device
                )
            )
        ).view(-1, 1, 1)
        ref_fp32 = (partials * weights).sum(dim=0)
    if WDMASK == 1:
        ref_fp32[0:4, :] = 0.0
        ref_fp32[64:67, :] = 0.0
    return ref_fp32.to(output_dtype)


def _tolerance(AB_DTYPE: type) -> tuple[float, float]:
    if AB_DTYPE is cutlass.BFloat16:
        return 0.5, 1e-5
    if _is_fp8_dtype(AB_DTYPE):
        return 0.25, 0.1
    return 0.1, 1e-5


def verify(
    *,
    AB_DTYPE: type = cutlass.Float16,
    D_DTYPE: type | None = None,
    MMA_SHAPE: tuple[int, int, int] = (128, 128, 64),
    COLLECTOR: int = 0,
    SCALE_D: int = 0,
    WDMASK: int = 0,
    mnk: tuple[int, int, int] | None = None,
    tmem_ld_warp_start: int = _DEFAULT_TMEM_LD_WARP_START,
) -> None:
    """Compile, run, and assert D is close to the torch reference.

    ``AB_DTYPE``, ``D_DTYPE``, ``MMA_SHAPE``, ``COLLECTOR``, ``SCALE_D``, and
    ``WDMASK`` have the same meaning as in :func:`compile`. ``mnk`` is runtime
    problem size and may vary across calls as long as it is a multiple of
    ``MMA_SHAPE``.

    :param AB_DTYPE: Same as :func:`compile`.
    :type AB_DTYPE: type
    :param D_DTYPE: Same as :func:`compile`.
    :type D_DTYPE: type, optional
    :param MMA_SHAPE: Same as :func:`compile`.
    :type MMA_SHAPE: tuple[int, int, int]
    :param COLLECTOR: Same as :func:`compile`.
    :type COLLECTOR: int
    :param SCALE_D: Same as :func:`compile`.
    :type SCALE_D: int
    :param WDMASK: Same as :func:`compile`.
    :type WDMASK: int
    :param mnk: Runtime problem shape ``(M, N, K)``. Defaults to
        ``MMA_SHAPE`` and must be divisible by it.
    :type mnk: tuple[int, int, int], optional
    :param tmem_ld_warp_start: Same as :func:`compile`.
    :type tmem_ld_warp_start: int
    """
    D_DTYPE = _default_output_dtype(AB_DTYPE) if D_DTYPE is None else D_DTYPE
    run_mnk = MMA_SHAPE if mnk is None else mnk
    _validate_mnk(run_mnk, MMA_SHAPE)
    _validate_tmem_ld_warp_start(tmem_ld_warp_start, MMA_SHAPE)
    compiled_fn = compile(
        AB_DTYPE=AB_DTYPE,
        D_DTYPE=D_DTYPE,
        MMA_SHAPE=MMA_SHAPE,
        COLLECTOR=COLLECTOR,
        SCALE_D=SCALE_D,
        WDMASK=WDMASK,
        tmem_ld_warp_start=tmem_ld_warp_start,
    )
    print(
        "Compile kernel "
        f"(MMA_SHAPE={MMA_SHAPE}, mnk={run_mnk}, "
        f"tmem_ld_warp_start={tmem_ld_warp_start}) OK",
        flush=True,
    )
    c, a, b = run(
        compiled_fn=compiled_fn,
        AB_DTYPE=AB_DTYPE,
        D_DTYPE=D_DTYPE,
        MMA_SHAPE=MMA_SHAPE,
        COLLECTOR=COLLECTOR,
        SCALE_D=SCALE_D,
        WDMASK=WDMASK,
        mnk=run_mnk,
        tmem_ld_warp_start=tmem_ld_warp_start,
    )
    print(
        "Run kernel "
        f"(MMA_SHAPE={MMA_SHAPE}, mnk={run_mnk}, "
        f"tmem_ld_warp_start={tmem_ld_warp_start}) OK",
        flush=True,
    )
    ref = _reference(
        a,
        b,
        AB_DTYPE=AB_DTYPE,
        D_DTYPE=D_DTYPE,
        COLLECTOR=COLLECTOR,
        SCALE_D=SCALE_D,
        WDMASK=WDMASK,
    )
    atol, rtol = _tolerance(AB_DTYPE)
    torch.testing.assert_close(c, ref, atol=atol, rtol=rtol)
    print(
        "verify "
        f"(MMA_SHAPE={MMA_SHAPE}, mnk={run_mnk}, "
        f"tmem_ld_warp_start={tmem_ld_warp_start}): PASS",
        flush=True,
    )


def _parse_mnk(value: str) -> tuple[int, int, int]:
    parts = tuple(int(x) for x in value.split(","))
    if len(parts) != 3:
        raise argparse.ArgumentTypeError("--mnk must be M,N,K")
    return parts


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="tcgen05_mma correctness test: single-CTA structural variant",
    )
    parser.add_argument(
        "--ab_dtype",
        choices=tuple(_DTYPE_BY_NAME),
        default="f16",
        help="A/B operand dtype name.",
    )
    parser.add_argument(
        "--d_dtype",
        choices=tuple(_DTYPE_BY_NAME),
        default=None,
        help="D/C output dtype name (default: natural output dtype for A/B).",
    )
    parser.add_argument(
        "--mma_shape",
        type=_parse_mnk,
        default=(128, 128, 64),
        help="Compile-time MMA_SHAPE as M,N,K.",
    )
    parser.add_argument(
        "--mnk",
        type=_parse_mnk,
        default=None,
        help="Optional runtime problem size M,N,K.",
    )
    parser.add_argument(
        "--collector",
        type=int,
        default=0,
        help="Set to 2 to exercise collector FILL + LASTUSE.",
    )
    parser.add_argument(
        "--scale_d",
        type=int,
        default=0,
        help="Optional scale_input_d value for accumulation MMAs.",
    )
    parser.add_argument(
        "--wdmask",
        action="store_true",
        help="Exercise write_disable_mask.",
    )
    parser.add_argument(
        "--tmem_ld_warp_start",
        type=int,
        default=_DEFAULT_TMEM_LD_WARP_START,
        choices=range(0, 5),
        help=(
            "First contiguous TMEM-load warp. Nonzero values require "
            "MMA_SHAPE M=128 and use warp_idx %% 4 for TMEM/SP rows."
        ),
    )
    args = parser.parse_args()

    if not _check_sm100():
        print("SKIP: SM100+ (Blackwell) GPU required")
        sys.exit(0)

    verify(
        AB_DTYPE=_DTYPE_BY_NAME[args.ab_dtype],
        D_DTYPE=None if args.d_dtype is None else _DTYPE_BY_NAME[args.d_dtype],
        MMA_SHAPE=args.mma_shape,
        COLLECTOR=args.collector,
        SCALE_D=args.scale_d,
        WDMASK=1 if args.wdmask else 0,
        mnk=args.mnk,
        tmem_ld_warp_start=args.tmem_ld_warp_start,
    )
